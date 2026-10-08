"""Mediciones del laboratorio: B-00 (la memoria de cada perfil, por pieza y por motor), B-04 (el
costo de empaquetar cada runtime), B-05 (los dos motores), B-07 (los clusters locales), B-12 (las
pruebas contra SQLite frente a las pruebas contra Postgres) y B-16 (réplicas por runtime para la misma
tasa, y memoria por réplica) y B-23 (el reparto de las llamadas gRPC entre las réplicas de pricing).

Uso (desde src/lab/, a través del Taskfile, que pasa el motor activo):
    task measure -- B-00 --profile minimo --runs 3
    task measure -- B-04 --runs 5 --startup-runs 10 [--service pricing]
    task measure -- B-05 --runs 5      (con el motor que se mide como motor activo, y el otro apagado)
    task measure -- B-07 --tool kind --runs 3     (kind, k3d o minikube; con el motor activo)
    task measure -- B-12 --runs 5     (con Docker: Testcontainers usa su socket)
    task measure -- B-16 --runs 3 --rate 400   (en el cluster lab, con task deploy CLUSTER=lab -- medicion)
    task measure -- B-23 --runs 3 --rate 20    (en el cluster lab, con los valores de minimo y mTLS)

B-04, por servicio: el tamaño de la imagen descomprimida (dive) y lo que viaja (el archivo de
`save`); el build en frío (sin caché de capas, con las imágenes base ya descargadas); el build con
caché después de cambiar una línea del código; y el tiempo desde `run` hasta la primera respuesta
200 de su endpoint de G0, sondeando desde el host por un puerto alto en 127.0.0.1.

B-05, con el motor activo y el otro apagado: la huella en el host (macOS: `footprint`) de la
máquina virtual del motor y de sus procesos, recién arrancado y después de trabajar, cada vez tras
SETTLE segundos de reposo; la creación del cluster `minimo` (de `kind create` a nodo listo); y el
build en frío de `pricing` y de `inventory`.

B-07, por herramienta y con el motor activo: el tiempo desde el comando que crea el cluster de un
nodo hasta que el nodo está listo, y la memoria usada de la máquina virtual antes de crearlo y con el
cluster en reposo (SETTLE segundos); al final, una vez, si crea un cluster de tres nodos y cuánto
tarda. El Kubernetes de Docker Desktop no se enciende desde la CLI: se mide a mano (Fase 07).

B-12, con la suite de pricing (services/pricing/main_test.go): el tiempo de pared de
`task test:pricing` contra SQLite y contra Postgres (Testcontainers arranca uno por corrida), y qué
pruebas pasan en cada motor. Una corrida previa sin medir calienta la caché de módulos y de compilación.

B-16, en el cluster lab con el perfil medicion y sin autoescalado: por servicio y por número de réplicas
(1, 2 y 3), una tasa constante de lecturas por la puerta con k6 (bench/b16/rate.js) durante 30 s, después
de 10 s de calentamiento que no se cuentan; la mediana y el p95 de la latencia, las peticiones fallidas, y
la memoria de cada réplica al final (kubectl top). Escala con kubectl scale: al terminar, task deploy
FORCE=true le devuelve las réplicas al chart.

B-00:

Cada corrida crea el cluster desde cero, mide en tres momentos y lo borra:
  cluster  el cluster recién creado, sin nada encima
  base     más el controlador de Gateway con un Gateway vacío y metrics-server
  todo     más los datos (Postgres, Valkey, NATS), la observabilidad completa y cert-manager
En cada momento espera a que todo esté listo y deja reposar SETTLE segundos antes de medir.
Con --profile legacy mide el patrimonio en compose, y con --profile servicios los cinco servicios del
paso vigente (listos cuando su suite pasa): la VM antes de levantarlo y con las cuatro piezas
en reposo, y la memoria de cada contenedor. Las imágenes tienen que estar construidas (task legacy:up).
Los crudos quedan en bench/b00/results/ y el resumen (mediana, mínimo y máximo) sale por pantalla.
Solo biblioteca estándar.
"""
import argparse
import datetime
import json
import os
import statistics
import subprocess
import sys
import tempfile
import time
import urllib.request
from pathlib import Path

LAB = Path(__file__).resolve().parents[2]
B00 = LAB / "bench" / "b00"
B04 = LAB / "bench" / "b04"
METRICS_SERVER = "https://github.com/kubernetes-sigs/metrics-server/releases/download/v0.9.0/components.yaml"
CHARTS = [  # (release, chart, versión, namespace, valores)
    ("eg", "oci://docker.io/envoyproxy/gateway-helm", "v1.9.2", "gateway", []),
    ("cert-manager", "oci://quay.io/jetstack/charts/cert-manager", "v1.21.2", "cert-manager", ["--set", "crds.enabled=true"]),
    ("trust-manager", "oci://quay.io/jetstack/charts/trust-manager", "v0.25.0", "cert-manager", []),
]


def sh(cmd: list[str], timeout: int = 900, env: dict | None = None) -> str:
    print("  $", " ".join(cmd), flush=True)
    done = subprocess.run(cmd, capture_output=True, text=True, timeout=timeout, env=env)
    if done.returncode != 0:
        raise RuntimeError(f"falló: {' '.join(cmd)}\n{done.stderr.strip()}")
    return done.stdout


class Run:
    def __init__(self, engine: str, profile: str):
        self.engine, self.profile, self.ctx = engine, profile, f"kind-{profile}"
        self.env = {**os.environ, "KIND_EXPERIMENTAL_PROVIDER": engine}

    def kubectl(self, *args: str, timeout: int = 900) -> str:
        return sh(["kubectl", "--context", self.ctx, *args], timeout=timeout)

    def helm(self, release, chart, version, namespace, extra):
        sh(["helm", "install", release, chart, "--version", version, "-n", namespace, "--create-namespace",
            "--kube-context", self.ctx, "--wait", "--timeout", "10m", *extra])

    def wait_all_ready(self, timeout: int = 900) -> None:
        """Espera a que todos los pods estén Running y listos, o hayan terminado bien."""
        deadline = time.monotonic() + timeout
        while time.monotonic() < deadline:
            pods = json.loads(self.kubectl("get", "pods", "-A", "-o", "json"))["items"]
            pending = [p["metadata"]["name"] for p in pods
                       if p["status"].get("phase") != "Succeeded"
                       and not all(c.get("ready") for c in p["status"].get("containerStatuses", [{}]))]
            if not pending:
                return
            time.sleep(5)
        raise RuntimeError(f"pods sin estar listos tras {timeout} s: {pending}")

    def vm_memory(self) -> dict:
        """La memoria de la máquina virtual del motor, vista desde el nodo (comparte su /proc/meminfo)."""
        raw = sh([self.engine, "exec", f"{self.profile}-control-plane", "cat", "/proc/meminfo"])
        kb = {line.split(":")[0]: int(line.split()[1]) for line in raw.splitlines()}
        return {"total_mib": kb["MemTotal"] // 1024,
                "used_mib": (kb["MemTotal"] - kb["MemAvailable"]) // 1024}

    def pods_memory(self) -> dict:
        """Working set de los contenedores, sumado por namespace, desde el kubelet de cada nodo."""
        per_ns: dict[str, float] = {}
        for node in json.loads(self.kubectl("get", "nodes", "-o", "json"))["items"]:
            name = node["metadata"]["name"]
            summary = json.loads(self.kubectl("get", "--raw", f"/api/v1/nodes/{name}/proxy/stats/summary"))
            for pod in summary["pods"]:
                ns = pod["podRef"]["namespace"]
                ws = sum(c.get("memory", {}).get("workingSetBytes", 0) for c in pod.get("containers", []))
                per_ns[ns] = per_ns.get(ns, 0) + ws / 2**20
        return {ns: round(v, 1) for ns, v in sorted(per_ns.items())}

    def snapshot(self, settle: int) -> dict:
        self.wait_all_ready()
        time.sleep(settle)  # reposo: la memoria de arranque no es la de trabajo
        pods = self.pods_memory()
        return {"vm": self.vm_memory(), "pods_total_mib": round(sum(pods.values()), 1), "pods_by_ns": pods}

    def measure(self, settle: int) -> dict:
        result = {"engine": self.engine, "profile": self.profile,
                  "date": datetime.datetime.now().isoformat(timespec="seconds")}
        start = time.monotonic()
        sh(["kind", "create", "cluster", "--config", str(LAB / "kind" / f"cluster-{self.profile}.yaml")], env=self.env)
        self.kubectl("wait", "--for=condition=Ready", "nodes", "--all", "--timeout=300s")
        result["create_seconds"] = round(time.monotonic() - start, 1)
        try:
            result["cluster"] = self.snapshot(settle)
            self.helm(*CHARTS[0])
            self.kubectl("apply", "-f", str(B00 / "gateway.yaml"))
            self.kubectl("apply", "-f", METRICS_SERVER)
            # El kubelet de kind no firma con IP SAN: sin este flag, metrics-server no arranca (incidente 17).
            self.kubectl("-n", "kube-system", "patch", "deploy", "metrics-server", "--type=json", "-p",
                         '[{"op":"add","path":"/spec/template/spec/containers/0/args/-","value":"--kubelet-insecure-tls"}]')
            self.kubectl("-n", "gateway", "wait", "--for=condition=Programmed", "gateway/lab", "--timeout=300s")
            result["base"] = self.snapshot(settle)
            self.kubectl("apply", "-f", str(B00 / "data.yaml"), "-f", str(B00 / "observability.yaml"))
            for chart in CHARTS[1:]:
                self.helm(*chart)
            result["todo"] = self.snapshot(settle)
        finally:
            sh(["kind", "delete", "cluster", "--name", self.profile], env=self.env)
        return result


class LegacyRun:
    """Compose sin cluster: el patrimonio (perfil legacy) o los cinco servicios (perfil servicios).
    No hay nodo, así que la VM se lee desde un contenedor cualquiera."""
    PROBE = "postgres@sha256:5a5a84b19854a9ffaa54082c166ff4ec27473a361e496e5ea167f298f2da9722"

    def __init__(self, engine: str, profile: str = "legacy"):
        self.engine, self.profile = engine, profile
        base = [engine, "compose", "-f", str(LAB / "compose" / "compose.yaml")]
        self.compose = base + ["--profile", "legacy"] if profile == "legacy" else base
        # Un perfil activo también levanta los servicios sin perfil: se nombran los que se miden.
        self.services = (["contingencia-db", "contingencia", "portal", "braqui", "braqui-traslados"]
                         if profile == "legacy" else ["pricing", "inventory", "catalog", "replenish", "storefront"])

    def vm_memory(self) -> dict:
        raw = sh([self.engine, "run", "--rm", "--entrypoint", "cat", self.PROBE, "/proc/meminfo"])
        kb = {line.split(":")[0]: int(line.split()[1]) for line in raw.splitlines()}
        return {"total_mib": kb["MemTotal"] // 1024, "used_mib": (kb["MemTotal"] - kb["MemAvailable"]) // 1024}

    def deployed(self) -> bool:
        if self.profile == "servicios":
            # Listos cuando la suite del paso pasa contra ellos.
            done = subprocess.run(self.compose + ["--profile", "conformance", "run", "--rm", "conformance"],
                                  capture_output=True, text=True)
            return done.returncode == 0
        # GlassFish escribe su log en la salida de error del contenedor.
        logs = subprocess.run([self.engine, "logs", "lab-contingencia-1"], capture_output=True, text=True)
        return "contingencia was successfully deployed" in logs.stdout + logs.stderr

    def measure(self, settle: int) -> dict:
        sh(self.compose + ["down", "-v"])
        result = {"engine": self.engine, "profile": self.profile,
                  "date": datetime.datetime.now().isoformat(timespec="seconds"), "before": self.vm_memory()}
        start = time.monotonic()
        sh(self.compose + ["up", "-d", "--no-build"] + self.services)
        while not self.deployed():
            if time.monotonic() - start > 600:
                raise RuntimeError(f"{self.profile}: no quedó listo en 10 minutos")
            time.sleep(5)
        result["ready_seconds"] = round(time.monotonic() - start, 1)
        time.sleep(settle)
        result["after"] = self.vm_memory()
        stats = sh([self.engine, "stats", "--no-stream", "--format", "{{.Name}}|{{.MemUsage}}"])
        result["containers_mib"] = {}
        for line in stats.splitlines():
            name, usage = line.split("|")
            if name.startswith("lab-"):
                value = usage.split("/")[0].strip()
                number = float(value.rstrip("KMGiBkmb"))
                factor = {"GiB": 1024, "GB": 1000, "MiB": 1, "MB": 1, "KiB": 1 / 1024, "kB": 1 / 1000}
                unit = value[len(value.rstrip("KMGiBkmb")):]
                result["containers_mib"][name] = round(number * factor.get(unit, 1), 1)
        sh(self.compose + ["down", "-v"])
        return result


class B04Run:
    """El costo de empaquetar cada runtime. Un servicio por vez, con el motor activo."""
    # El archivo que se toca para el build con caché, y la ruta de G0 que cuenta como "primer 200".
    SERVICES = {
        "pricing": ("main.go", "/prices/SKU-0003?store=DRO-007"),
        "inventory": ("src/main/java/co/coodrosan/lab/inventory/StockController.java", "/stock/DRO-007/SKU-0003"),
        "catalog": ("routes/api.php", "/products"),
        "replenish": ("src/replenishment-orders.controller.ts", "/replenishment-orders"),
        "storefront": ("src/App.tsx", "/"),
    }
    PORT = 18404  # alto y en 127.0.0.1: no choca con nada del laboratorio
    # nginxinc/nginx-unprivileged:1.30.5-alpine, el que va delante de catalog
    NGINX = "nginxinc/nginx-unprivileged@sha256:ed04ec1ff34502c339ee5c3ae3f855442398edc1d05591e2b98981dcbbd20b1e"

    def __init__(self, engine: str, service: str, path: str | None = None):
        self.engine, self.service = engine, service
        # La ruta del primer 200: la de G0 por defecto. Desde G1 la de G0 puede dar 404 sin datos (pricing sin
        # precios en su SQLite): entonces se mide contra /health/live con --path.
        self.path = path or self.SERVICES[service][1]
        # Con tag explícito: `docker save lab/<svc>` sin tag exporta todos los tags del repositorio, y el tamaño
        # que viaja sale inflado en cuanto hay más de uno (los g-tags, los de un apéndice).
        self.image = f"{'docker.io/' if engine == 'podman' else ''}lab/{service}:latest"
        self.dir = LAB / "services" / service

    def build(self, no_cache: bool) -> float:
        cmd = [self.engine, "build", "-q", "-t", self.image, str(self.dir)]
        if no_cache:
            cmd.insert(2, "--no-cache")
        start = time.monotonic()
        sh(cmd, timeout=1800)
        return round(time.monotonic() - start, 2)

    def warm_build(self) -> float:
        """Cambia una línea del código (un comentario al final), construye, y deja el archivo como estaba.
        El comentario lleva un número distinto cada vez: con el mismo texto, desde la segunda corrida el
        motor encontraría esa capa ya construida y la medición sería de la caché, no del build."""
        source = self.dir / self.SERVICES[self.service][0]
        original = source.read_text(encoding="utf-8")
        try:
            source.write_text(original + f"\n// cambio de medición B-04 {time.time_ns()}\n", encoding="utf-8")
            return self.build(no_cache=False)
        finally:
            source.write_text(original, encoding="utf-8")
            self.build(no_cache=False)  # la imagen vuelve a corresponder al código

    def sizes(self) -> dict:
        with tempfile.TemporaryDirectory() as tmp:
            archive = Path(tmp) / "image.tar"
            sh([self.engine, "save", "-o", str(archive), self.image])
            saved = archive.stat().st_size
            report = Path(tmp) / "dive.json"
            source = "podman" if self.engine == "podman" else "docker"
            sh(["dive", self.image, "--source", source, "--json", str(report)], timeout=600)
            unpacked = json.loads(report.read_text())["image"]["sizeBytes"]
        return {"unpacked_mb": round(unpacked / 1e6, 1), "saved_mb": round(saved / 1e6, 1)}

    def first_200(self) -> float:
        """Segundos desde `run` hasta la primera respuesta 200 de la ruta de G0."""
        url = f"http://127.0.0.1:{self.PORT}{self.path}"
        names = [f"b04-{self.service}"]
        start = time.monotonic()
        sh([self.engine, "run", "-d", "--rm", "--name", names[0], "--label", "curso=lab-docker-kubernetes",
            "-p", f"127.0.0.1:{self.PORT}:8080", self.image])
        if self.service == "catalog":
            # El nginx comparte la red de FPM, como en compose y como en el pod.
            names.append("b04-catalog-nginx")
            sh([self.engine, "run", "-d", "--rm", "--name", names[1], "--label", "curso=lab-docker-kubernetes",
                "--network", f"container:{names[0]}",
                "-v", f"{self.dir / 'nginx.conf'}:/etc/nginx/conf.d/default.conf:ro", self.NGINX])
        try:
            while time.monotonic() - start < 120:
                try:
                    with urllib.request.urlopen(url, timeout=2) as response:
                        if response.status == 200:
                            return round(time.monotonic() - start, 3)
                except OSError:
                    pass
                time.sleep(0.02)
            raise RuntimeError(f"{self.service}: sin 200 en 120 s")
        finally:
            for name in reversed(names):
                subprocess.run([self.engine, "rm", "-f", name], capture_output=True)

    def measure(self, runs: int, startup_runs: int) -> dict:
        result = {"engine": self.engine, "service": self.service,
                  "date": datetime.datetime.now().isoformat(timespec="seconds")}
        result["cold_s"] = [self.build(no_cache=True) for _ in range(runs)]
        result["warm_s"] = [self.warm_build() for _ in range(runs)]
        result["sizes"] = self.sizes()
        result["first_200_s"] = [self.first_200() for _ in range(startup_runs)]
        return result


def summarize_b04(results: list[dict]) -> None:
    def stat(values, fmt="{:.2f}"):
        return f"{fmt.format(statistics.median(values))} ({fmt.format(min(values))}–{fmt.format(max(values))})"
    print(f"\nB-04 · {results[0]['engine']} · mediana (mínimo–máximo)")
    print(f"  {'servicio':11} {'descomprimida':>13} {'viaja':>8}   {'build en frío (s)':22} {'con caché (s)':20} primer 200 (s)")
    for r in results:
        print(f"  {r['service']:11} {r['sizes']['unpacked_mb']:10.1f} MB {r['sizes']['saved_mb']:5.1f} MB   "
              f"{stat(r['cold_s'], '{:.1f}'):22} {stat(r['warm_s'], '{:.1f}'):20} {stat(r['first_200_s'])}")



class B05Run:
    """Los dos motores. Reinicia el motor activo para medir su reposo desde cero."""
    # Los procesos de cada motor en el host de macOS: la máquina virtual primero.
    HOST_PROCESSES = {
        "docker": ("com.apple.Virtualization.VirtualMachine", ["Docker.app", "com.docker."]),
        "podman": ("krunkit", ["gvproxy", "podman"]),
    }

    def __init__(self, engine: str):
        self.engine = engine
        self.env = {**os.environ, "KIND_EXPERIMENTAL_PROVIDER": engine}

    def host_footprint(self) -> dict | None:
        """MB de memoria física que el host le dedica al motor (phys_footprint). Solo macOS."""
        if sys.platform != "darwin":
            return None
        vm_name, others = self.HOST_PROCESSES[self.engine]
        listing = subprocess.run(["ps", "-axo", "pid=,command="], capture_output=True, text=True).stdout
        vm, rest = 0.0, 0.0
        for line in listing.splitlines():
            pid, _, command = line.strip().partition(" ")
            is_vm = vm_name in command
            if not is_vm and not any(o in command for o in others):
                continue
            out = subprocess.run(["footprint", "-p", pid], capture_output=True, text=True).stdout
            for row in out.splitlines():
                if "phys_footprint:" in row:
                    value, unit = row.split(":")[1].split()[:2]
                    mb = float(value) * {"KB": 1 / 1024, "MB": 1, "GB": 1024}.get(unit, 1)
                    if is_vm:
                        vm += mb
                    else:
                        rest += mb
        return {"vm_mb": round(vm), "rest_mb": round(rest)}

    def host_samples(self, n: int = 5, every: int = 10) -> list:
        """Cinco lecturas de la huella, separadas por diez segundos: nunca un número solo."""
        samples = []
        for i in range(n):
            if i:
                time.sleep(every)
            samples.append(self.host_footprint())
        return samples

    def restart_engine(self) -> None:
        if self.engine == "docker":
            sh(["docker", "desktop", "stop"], timeout=300)
            sh(["docker", "desktop", "start"], timeout=300)
        else:
            sh(["podman", "machine", "stop"], timeout=300)
            sh(["podman", "machine", "start"], timeout=300)
        sh([self.engine, "info", "--format", "{{.ID}}" if self.engine == "docker" else "{{.Host.Arch}}"])

    def create_cluster(self) -> float:
        start = time.monotonic()
        sh(["kind", "create", "cluster", "--config", str(LAB / "kind" / "cluster-minimo.yaml")], env=self.env)
        sh(["kubectl", "--context", "kind-minimo", "wait", "--for=condition=Ready", "nodes", "--all",
            "--timeout=300s"])
        elapsed = round(time.monotonic() - start, 1)
        sh(["kind", "delete", "cluster", "--name", "minimo"], env=self.env)
        return elapsed

    def cold_build(self, service: str) -> float:
        image = f"{'docker.io/' if self.engine == 'podman' else ''}lab/{service}"
        start = time.monotonic()
        sh([self.engine, "build", "--no-cache", "-q", "-t", image, str(LAB / "services" / service)], timeout=1800)
        return round(time.monotonic() - start, 1)

    def measure(self, runs: int, settle: int) -> dict:
        result = {"engine": self.engine, "date": datetime.datetime.now().isoformat(timespec="seconds")}
        # Las imágenes base y la del nodo, presentes antes de medir: se mide el motor, no la red.
        for service in ("pricing", "inventory"):
            self.cold_build(service)
        self.create_cluster()
        self.restart_engine()
        time.sleep(settle)
        result["idle_fresh"] = self.host_samples()
        result["cluster_s"] = [self.create_cluster() for _ in range(runs)]
        result["build_pricing_s"] = [self.cold_build("pricing") for _ in range(runs)]
        result["build_inventory_s"] = [self.cold_build("inventory") for _ in range(runs)]
        time.sleep(settle)
        result["idle_after_work"] = self.host_samples()
        return result


def summarize_b05(result: dict) -> None:
    def stat(values):
        return f"{statistics.median(values):.1f} ({min(values):.1f}–{max(values):.1f})"
    print(f"\nB-05 · {result['engine']} · mediana (mínimo–máximo)")
    print(f"  cluster minimo (s)        {stat(result['cluster_s'])}")
    print(f"  build en frío pricing (s) {stat(result['build_pricing_s'])}")
    print(f"  build en frío inventory   {stat(result['build_inventory_s'])}")
    for key, label in (("idle_fresh", "recién arrancado"), ("idle_after_work", "después de trabajar")):
        samples = [x for x in result[key] if x]
        if samples:
            print(f"  host, {label:19} VM {stat([x['vm_mb'] for x in samples])} MB · "
                  f"resto {stat([x['rest_mb'] for x in samples])} MB")



class B07Run:
    """Los clusters locales: kind, k3d y minikube sobre el motor activo."""
    NAME = "b07"
    # kindest/node:v1.36.4, el nodo del curso (a01)
    KIND_NODE = "kindest/node@sha256:099e049362a1526b2db71494e1947aae99bd16290d7c895f2b7ea312e3cbfaed"

    def __init__(self, engine: str, tool: str):
        self.engine, self.tool = engine, tool
        self.env = {**os.environ, "KIND_EXPERIMENTAL_PROVIDER": engine}
        if engine == "podman" and tool == "k3d":
            # k3d habla la API de Docker: con Podman, por el socket compatible de su máquina.
            sock = sh(["podman", "machine", "inspect", "--format", "{{.ConnectionInfo.PodmanSocket.Path}}"]).strip()
            self.env["DOCKER_HOST"] = f"unix://{sock}"
        self.context = {"kind": f"kind-{self.NAME}", "k3d": f"k3d-{self.NAME}", "minikube": self.NAME}[tool]

    def vm_used(self) -> int:
        return LegacyRun(self.engine).vm_memory()["used_mib"]

    def create(self, nodes: int) -> None:
        if self.tool == "kind":
            config = "kind: Cluster\napiVersion: kind.x-k8s.io/v1alpha4\nnodes:\n" + \
                     "".join(f"  - role: {'control-plane' if i == 0 else 'worker'}\n    image: {self.KIND_NODE}\n"
                             for i in range(nodes))
            path = Path(tempfile.gettempdir()) / "b07-kind.yaml"
            path.write_text(config)
            cmd = ["kind", "create", "cluster", "--name", self.NAME, "--config", str(path)]
        elif self.tool == "k3d":
            cmd = ["k3d", "cluster", "create", self.NAME, "--agents", str(nodes - 1), "--wait", "--timeout", "300s"]
        else:
            cmd = ["minikube", "start", "-p", self.NAME, f"--driver={self.engine}", f"--nodes={nodes}"]
        sh(cmd, env=self.env, timeout=900)
        sh(["kubectl", "--context", self.context, "wait", "--for=condition=Ready", "nodes", "--all",
            "--timeout=300s"])

    def delete(self) -> None:
        cmd = {"kind": ["kind", "delete", "cluster", "--name", self.NAME],
               "k3d": ["k3d", "cluster", "delete", self.NAME],
               "minikube": ["minikube", "delete", "-p", self.NAME]}[self.tool]
        sh(cmd, env=self.env, timeout=600)

    def measure(self, runs: int, settle: int) -> dict:
        result = {"engine": self.engine, "tool": self.tool,
                  "date": datetime.datetime.now().isoformat(timespec="seconds"), "runs": []}
        # Una creación sin medir: las imágenes de cada herramienta, ya descargadas.
        self.create(1)
        result["server_version"] = json.loads(sh(["kubectl", "--context", self.context, "version", "-o", "json"]))[
            "serverVersion"]["gitVersion"]
        self.delete()
        for _ in range(runs):
            time.sleep(10)
            before = self.vm_used()
            start = time.monotonic()
            self.create(1)
            ready = round(time.monotonic() - start, 1)
            time.sleep(settle)
            after = self.vm_used()
            self.delete()
            result["runs"].append({"ready_s": ready, "vm_before_mib": before, "vm_after_mib": after,
                                   "cluster_mib": after - before})
        start = time.monotonic()
        try:
            self.create(3)
            result["three_nodes_s"] = round(time.monotonic() - start, 1)
        except RuntimeError as error:
            result["three_nodes_error"] = str(error)[-400:]
        finally:
            subprocess.run({"kind": ["kind", "delete", "cluster", "--name", self.NAME],
                            "k3d": ["k3d", "cluster", "delete", self.NAME],
                            "minikube": ["minikube", "delete", "-p", self.NAME]}[self.tool],
                           env=self.env, capture_output=True)
        return result


class B12Run:
    """La suite de pricing contra SQLite y contra Postgres, con la misma tarea que usa el lector."""

    def __init__(self, engine: str):
        self.engine = engine

    def run(self, db: str) -> dict:
        start = time.monotonic()
        proc = subprocess.run(["task", "test:pricing", f"DB={db}"], cwd=LAB, capture_output=True, text=True)
        wall = round(time.monotonic() - start, 2)
        out = proc.stdout + proc.stderr
        passed = sorted({line.split()[2] for line in out.splitlines() if line.startswith("--- PASS")})
        failed = sorted({line.split()[2] for line in out.splitlines() if line.startswith("--- FAIL")})
        # El tiempo que informa `go test` para el paquete ("ok  lab/pricing 0.080s"): el binario de
        # pruebas solo, incluido el arranque del motor en TestMain, sin el contenedor ni la compilación.
        pkg = [line.split()[-1] for line in out.splitlines() if line.startswith(("ok", "FAIL\t")) and "lab/pricing" in line]
        go_s = float(pkg[-1].rstrip("s")) if pkg else None
        return {"wall_s": wall, "go_test_s": go_s, "passed": passed, "failed": failed}

    def measure(self, runs: int) -> dict:
        result = {"engine": self.engine, "date": datetime.datetime.now().isoformat(timespec="seconds"),
                  "sqlite": [], "postgres": []}
        self.run("sqlite")
        self.run("postgres")  # descarga la imagen de Ryuk y calienta la caché; no se cuenta
        for _ in range(runs):
            for db in ("sqlite", "postgres"):
                result[db].append(self.run(db))
        return result


def summarize_b12(r: dict) -> None:
    def stat(values):
        return f"{statistics.median(values):.2f} ({min(values):.2f}–{max(values):.2f})"
    print(f"\nB-12 · {r['engine']} · {len(r['sqlite'])} corridas por motor")
    for db in ("sqlite", "postgres"):
        runs = r[db]
        print(f"  {db:9} tarea (s) {stat([x['wall_s'] for x in runs])}"
              f"   go test (s) {stat([x['go_test_s'] for x in runs])}"
              f"   pasan {len(runs[-1]['passed'])} · fallan {runs[-1]['failed'] or 'ninguna'}")
    for key, label in (("wall_s", "la tarea"), ("go_test_s", "go test")):
        ratio = statistics.median([x[key] for x in r["postgres"]]) / statistics.median([x[key] for x in r["sqlite"]])
        print(f"  Postgres / SQLite, {label}: {ratio:.1f}x")


def summarize_b07(r: dict) -> None:
    def stat(values):
        return f"{statistics.median(values):.0f} ({min(values):.0f}–{max(values):.0f})"
    runs = r["runs"]
    print(f"\nB-07 · {r['tool']} sobre {r['engine']} · Kubernetes {r['server_version']} · {len(runs)} corridas")
    print(f"  un nodo listo (s)             {stat([x['ready_s'] for x in runs])}")
    print(f"  memoria del cluster (MiB)     {stat([x['cluster_mib'] for x in runs])}")
    print(f"  tres nodos                    {r.get('three_nodes_s', r.get('three_nodes_error', '?'))}")


def summarize_legacy(results: list[dict]) -> None:
    def stat(values):
        return f"{statistics.median(values):7.0f}  ({min(values):.0f}–{max(values):.0f})"
    print(f"\nB-00 · {results[0]['engine']} · perfil {results[0]['profile']} · {len(results)} corridas")
    print(f"  hasta quedar listo (s)            {stat([r['ready_seconds'] for r in results])}")
    print(f"  VM usada antes (MiB)              {stat([r['before']['used_mib'] for r in results])}")
    print(f"  VM usada después (MiB)            {stat([r['after']['used_mib'] for r in results])}")
    print(f"  diferencia (MiB)                  {stat([r['after']['used_mib'] - r['before']['used_mib'] for r in results])}")
    for name in results[0]["containers_mib"]:
        print(f"    {name:28} {stat([r['containers_mib'].get(name, 0) for r in results])}")


def summarize(results: list[dict]) -> None:
    def stat(values):
        return f"{statistics.median(values):7.0f}  ({min(values):.0f}–{max(values):.0f})"
    print(f"\nB-00 · {results[0]['engine']} · perfil {results[0]['profile']} · {len(results)} corridas")
    print(f"  creación del cluster (s)  {stat([r['create_seconds'] for r in results])}")
    print(f"  VM total (MiB)            {results[0]['cluster']['vm']['total_mib']:7d}")
    for stage in ("cluster", "base", "todo"):
        print(f"  {stage:8} VM usada (MiB)   {stat([r[stage]['vm']['used_mib'] for r in results])}"
              f"   pods (MiB) {stat([r[stage]['pods_total_mib'] for r in results])}")
    print("  todo, por namespace (MiB):")
    for ns in results[0]["todo"]["pods_by_ns"]:
        print(f"    {ns:20} {stat([r['todo']['pods_by_ns'].get(ns, 0) for r in results])}")


class B16Run:
    """B-16: réplicas y memoria por runtime para la misma tasa de lecturas."""

    URLS = {
        "pricing": "http://api.localhost:8080/pricing/prices?store=DRO-007",
        "inventory": "http://api.localhost:8080/inventory/stock/DRO-010/SKU-0001",
        "catalog": "http://api.localhost:8080/catalog/products",
        "replenish": "http://api.localhost:8080/replenish/replenishment-orders",
    }

    def __init__(self, rate: int, replicas: list[int]):
        self.rate, self.replicas = rate, replicas
        self.k = ["kubectl", "--context", "kind-lab", "-n", "apps"]

    def k6(self, url: str, seconds: int) -> dict:
        with tempfile.TemporaryDirectory() as tmp:
            summary = Path(tmp) / "summary.json"
            subprocess.run(["k6", "run", "--quiet", "--summary-export", str(summary), "-e", f"URL={url}",
                            "-e", f"RATE={self.rate}", "-e", f"DURATION={seconds}s", str(LAB / "bench" / "b16" / "rate.js")],
                           capture_output=True, text=True, timeout=seconds + 120)
            m = json.loads(summary.read_text())["metrics"]
        return {"p95_ms": m["http_req_duration"]["p(95)"], "med_ms": m["http_req_duration"]["med"],
                "failed": m["http_req_failed"]["value"], "rate": m["http_reqs"]["rate"]}

    def memory(self, service: str) -> list[float]:
        out = sh(self.k + ["top", "pods", "-l", f"app.kubernetes.io/name={service},app.kubernetes.io/component=backend",
                           "--containers", "--no-headers"])
        # catalog son dos contenedores: se suma por pod. La columna es MiB ("203Mi").
        per_pod: dict[str, float] = {}
        for line in out.splitlines():
            pod, _, _, mem = line.split()[:4]
            per_pod[pod] = per_pod.get(pod, 0) + float(mem.rstrip("Mi"))
        return sorted(per_pod.values())

    def measure(self, runs: int) -> dict:
        # inventory lee una existencia que tiene que existir.
        urllib.request.urlopen(urllib.request.Request(
            "http://api.localhost:8080/inventory/stock/DRO-010/SKU-0001/movements", method="POST",
            data=json.dumps({"type": "COUNT", "quantity": 50, "reference": "b16"}).encode(),
            headers={"Content-Type": "application/json"}), timeout=10)
        result = {"date": datetime.datetime.now().isoformat(timespec="seconds"), "rate": self.rate, "services": {}}
        for service, url in self.URLS.items():
            result["services"][service] = {}
            for n in self.replicas:
                print(f"── B-16 · {service} · {n} réplica(s) · {self.rate}/s", flush=True)
                sh(self.k + ["scale", f"deployment/{service}", f"--replicas={n}"])
                sh(self.k + ["rollout", "status", f"deployment/{service}", "--timeout=300s"])
                time.sleep(15)
                self.k6(url, 10)  # calentamiento: no se cuenta
                samples = [self.k6(url, 30) for _ in range(runs)]
                mem = self.memory(service)
                result["services"][service][str(n)] = {"runs": samples, "memory_mib": mem}
                print("   " + " · ".join(f"p95 {r['p95_ms']:.0f} ms, fallidas {r['failed']:.2%}" for r in samples)
                      + f" · memoria por réplica {mem}", flush=True)
            sh(self.k + ["scale", f"deployment/{service}", f"--replicas={min(self.replicas)}"])
        return result


def summarize_b16(r: dict) -> None:
    print(f"\nB-16 · {r['rate']} peticiones/s · mediana (mínimo–máximo) del p95, en ms")
    for service, by_n in r["services"].items():
        for n, data in by_n.items():
            p95 = [x["p95_ms"] for x in data["runs"]]
            failed = max(x["failed"] for x in data["runs"])
            print(f"  {service:10} {n} réplica(s): p95 {statistics.median(p95):.0f} ({min(p95):.0f}–{max(p95):.0f})"
                  f" · fallidas hasta {failed:.2%} · memoria por réplica {data['memory_mib']} MiB")


class B23Run:
    """B-23: cómo se reparten las llamadas gRPC de inventory entre las réplicas de pricing, con el Service normal
    (balancing=service) y con el headless y round_robin (balancing=client); con --modes, también con las conexiones
    cortadas a los 10 s por pricing ("service+age", "client+age"), y sin gRPC ("http": el 8443, HTTP/2 con mTLS; "http1": el 8080, HTTP/1.1). Por corrida: inventory reiniciado (una
    conexión nueva), 5 s de calentamiento, y 30 s de ventas; las llamadas de cada réplica salen de su contador
    grpc_server_requests_total, leído desde un pod de replenish (las NetworkPolicy dejan entrar desde la cadena)."""

    def __init__(self, rate: int, pricing_replicas: int, modes: tuple[str, ...] = ("service", "client")):
        self.rate, self.n, self.modes, self.http = rate, pricing_replicas, modes, False
        self.k = ["kubectl", "--context", "kind-lab", "-n", "apps"]

    def set_mode(self, mode: str) -> None:
        """mode es "service" o "client", con "+age" para que pricing corte las conexiones a los 10 s."""
        state_path = LAB / ".observability.json"
        state = json.loads(state_path.read_text()) if state_path.exists() else {}
        balancing, _, age = mode.partition("+")
        grpc = state.setdefault("global", {}).setdefault("grpc", {})
        # "http": sin gRPC, el precio por el 8443 (HTTPS con mTLS, que negocia HTTP/2), por el Service normal.
        # "http1": sin gRPC y sin mTLS, por el 8080 en texto plano (HTTP/1.1). Solo para medir: mtls se devuelve.
        self.http = balancing in ("http", "http1")
        grpc["enabled"] = not self.http
        grpc["balancing"] = "service" if self.http else balancing
        grpc["maxConnectionAge"] = "10s" if age else ""
        if balancing == "http1":
            state["global"]["mtls"] = {"enabled": False}
        else:
            state["global"].pop("mtls", None)
        state_path.write_text(json.dumps(state, indent=2) + "\n")
        sh(["task", "deploy", "CLUSTER=lab", "FORCE=true", "--", "minimo"], timeout=1200)
        sh(self.k + ["scale", "deployment/pricing", f"--replicas={self.n}"])
        sh(self.k + ["rollout", "status", "deployment/pricing", "--timeout=300s"])

    def counts(self) -> dict[str, float]:
        pods = json.loads(sh(self.k + ["get", "pods", "-l", "app.kubernetes.io/name=pricing,app.kubernetes.io/component=backend",
                                       "-o", "json"]))["items"]
        ips = {p["metadata"]["name"]: p["status"].get("podIP") for p in pods if p["status"].get("phase") == "Running"}
        # Las llamadas de precio: las gRPC de GetPrice, o (modo http) las HTTP a /prices/{sku}.
        prefix, part = (("http_server_requests_seconds_count", 'uri="/prices/{sku}"') if self.http
                        else ("grpc_server_requests_total", "GetPrice"))
        script = ("const ips=" + json.dumps(ips) + ";Promise.all(Object.entries(ips).map(([n,ip])=>fetch('http://'+ip+':8080/metrics')"
                  ".then(r=>r.text()).then(t=>[n,t.split('\\n').filter(l=>l.startsWith(" + json.dumps(prefix) + ")&&l.includes("
                  + json.dumps(part) + "))"
                  ".reduce((a,l)=>a+Number(l.split(' ').pop()),0)]))).then(r=>console.log(JSON.stringify(Object.fromEntries(r))))")
        return json.loads(sh(self.k + ["exec", "deploy/replenish", "--", "node", "-e", script]))

    def run_once(self) -> dict:
        sh(self.k + ["rollout", "restart", "deployment/inventory"])
        sh(self.k + ["rollout", "status", "deployment/inventory", "--timeout=300s"])
        time.sleep(10)
        subprocess.run(["k6", "run", "--quiet", "-e", f"RATE={self.rate}", "-e", "DURATION=5s",
                        str(LAB / "bench" / "b23" / "ventas.js")], capture_output=True, timeout=120)
        before = self.counts()
        with tempfile.TemporaryDirectory() as tmp:
            summary = Path(tmp) / "summary.json"
            subprocess.run(["k6", "run", "--quiet", "--summary-export", str(summary), "-e", f"RATE={self.rate}",
                            "-e", "DURATION=30s", str(LAB / "bench" / "b23" / "ventas.js")], capture_output=True, timeout=300)
            m = json.loads(summary.read_text())["metrics"]
        after = self.counts()
        calls = {pod: after.get(pod, 0) - before.get(pod, 0) for pod in after}
        total = sum(calls.values()) or 1
        return {"calls": calls, "share": sorted((round(v / total, 3) for v in calls.values()), reverse=True),
                "med_ms": m["http_req_duration"]["med"], "p95_ms": m["http_req_duration"]["p(95)"],
                "failed": m["http_req_failed"]["value"]}

    def measure(self, runs: int) -> dict:
        result = {"date": datetime.datetime.now().isoformat(timespec="seconds"), "rate": self.rate,
                  "pricing_replicas": self.n, "modes": {}}
        for mode in self.modes:
            print(f"── B-23 · balancing={mode} · {self.n} réplicas de pricing · {self.rate} ventas/s", flush=True)
            self.set_mode(mode)
            result["modes"][mode] = []
            for i in range(runs):
                r = self.run_once()
                result["modes"][mode].append(r)
                print(f"   corrida {i + 1}: reparto {r['share']} · mediana {r['med_ms']:.1f} ms · p95 {r['p95_ms']:.1f} ms"
                      f" · fallidas {r['failed']:.2%}", flush=True)
        return result


    def scale_once(self) -> dict:
        """La réplica nueva: dos réplicas de pricing, 60 s de ventas, y una tercera a los 20 s. Devuelve lo que
        recibió cada réplica en esos 60 s, y cuál era la nueva."""
        sh(self.k + ["scale", "deployment/pricing", "--replicas=2"])
        sh(self.k + ["rollout", "status", "deployment/pricing", "--timeout=300s"])
        time.sleep(20)  # que termine de irse la tercera, si la había
        sh(self.k + ["rollout", "restart", "deployment/inventory"])
        sh(self.k + ["rollout", "status", "deployment/inventory", "--timeout=300s"])
        time.sleep(10)
        subprocess.run(["k6", "run", "--quiet", "-e", f"RATE={self.rate}", "-e", "DURATION=5s",
                        str(LAB / "bench" / "b23" / "ventas.js")], capture_output=True, timeout=120)
        before = self.counts()
        k6 = subprocess.Popen(["k6", "run", "--quiet", "-e", f"RATE={self.rate}", "-e", "DURATION=60s",
                               str(LAB / "bench" / "b23" / "ventas.js")], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
        time.sleep(20)
        sh(self.k + ["scale", "deployment/pricing", "--replicas=3"])
        sh(self.k + ["rollout", "status", "deployment/pricing", "--timeout=120s"])
        k6.wait(timeout=300)
        after = self.counts()
        calls = {pod: after.get(pod, 0) - before.get(pod, 0) for pod in after}
        new = [pod for pod in after if pod not in before]
        return {"calls": calls, "new": new, "new_calls": sum(calls[p] for p in new), "total": sum(calls.values())}

    def scale(self, modes: tuple[str, ...]) -> dict:
        result = {"date": datetime.datetime.now().isoformat(timespec="seconds"), "rate": self.rate, "scale": {}}
        for mode in modes:
            print(f"── B-23 · la réplica nueva · balancing={mode} · 2 → 3 réplicas a los 20 s de 60", flush=True)
            self.set_mode(mode)
            r = self.scale_once()
            result["scale"][mode] = r
            print(f"   la nueva recibió {r['new_calls']:.0f} de {r['total']:.0f} llamadas · {r['calls']}", flush=True)
        return result


def summarize_b23(r: dict) -> None:
    if "scale" in r:
        print(f"\nB-23 · la réplica nueva · {r['rate']} ventas/s · 2 → 3 réplicas a los 20 s de 60")
        for mode, x in r["scale"].items():
            print(f"  {mode:10} la nueva: {x['new_calls']:.0f} de {x['total']:.0f} ({x['new_calls'] / (x['total'] or 1):.0%})")
        return
    print(f"\nB-23 · {r['pricing_replicas']} réplicas de pricing · {r['rate']} ventas/s · la réplica que más recibió")
    for mode, runs in r.get("modes", {}).items():
        top = [x["share"][0] for x in runs]
        print(f"  {mode:8} la más cargada: {statistics.median(top):.0%} ({min(top):.0%}–{max(top):.0%}) · "
              f"repartos {[x['share'] for x in runs]}")


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("id", choices=["B-00", "B-04", "B-05", "B-07", "B-12", "B-16", "B-23"], help="la medición")
    parser.add_argument("--engine", default="docker", choices=["docker", "podman"])
    parser.add_argument("--profile", default="minimo", choices=["minimo", "lab", "legacy", "servicios"])
    parser.add_argument("--runs", type=int, default=3)
    parser.add_argument("--settle", type=int, default=60, help="segundos de reposo antes de medir")
    parser.add_argument("--startup-runs", type=int, default=10, help="B-04: arranques por servicio")
    parser.add_argument("--service", choices=list(B04Run.SERVICES), help="B-04: un solo servicio")
    parser.add_argument("--path", help="B-04: la ruta del primer 200 (por defecto, la de G0)")
    parser.add_argument("--tool", choices=["kind", "k3d", "minikube"], help="B-07: la herramienta")
    parser.add_argument("--rate", type=int, default=400, help="B-16: peticiones por segundo")
    parser.add_argument("--modes", default="service,client", help="B-23: los modos de balanceo, separados por comas")
    parser.add_argument("--scale", action="store_true", help="B-23: la réplica nueva, en lugar del reparto")
    args = parser.parse_args()

    if args.id == "B-23":
        out = LAB / "bench" / "b23" / "results"
        out.mkdir(parents=True, exist_ok=True)
        run = B23Run(args.rate, 3, tuple(args.modes.split(",")))
        result = run.scale(run.modes) if args.scale else run.measure(args.runs)
        path = out / f"{args.engine}-{args.rate}-{result['date'].replace(':', '')}.json"
        path.write_text(json.dumps(result, indent=2, ensure_ascii=False))
        summarize_b23(result)
        return 0

    if args.id == "B-16":
        out = LAB / "bench" / "b16" / "results"
        out.mkdir(parents=True, exist_ok=True)
        result = B16Run(args.rate, [1, 2, 3]).measure(args.runs)
        path = out / f"{args.engine}-{args.rate}-{result['date'].replace(':', '')}.json"
        path.write_text(json.dumps(result, indent=2, ensure_ascii=False))
        summarize_b16(result)
        return 0

    if args.id == "B-12":
        out = LAB / "bench" / "b12" / "results"
        out.mkdir(parents=True, exist_ok=True)
        result = B12Run(args.engine).measure(args.runs)
        path = out / f"{args.engine}-{result['date'].replace(':', '')}.json"
        path.write_text(json.dumps(result, indent=2, ensure_ascii=False))
        summarize_b12(result)
        return 0

    if args.id == "B-07":
        out = LAB / "bench" / "b07" / "results"
        out.mkdir(parents=True, exist_ok=True)
        result = B07Run(args.engine, args.tool or "kind").measure(args.runs, args.settle)
        path = out / f"{args.engine}-{result['tool']}-{result['date'].replace(':', '')}.json"
        path.write_text(json.dumps(result, indent=2, ensure_ascii=False))
        summarize_b07(result)
        return 0

    if args.id == "B-05":
        out = LAB / "bench" / "b05" / "results"
        out.mkdir(parents=True, exist_ok=True)
        result = B05Run(args.engine).measure(args.runs, args.settle)
        path = out / f"{args.engine}-{result['date'].replace(':', '')}.json"
        path.write_text(json.dumps(result, indent=2, ensure_ascii=False))
        summarize_b05(result)
        return 0

    if args.id == "B-04":
        out = B04 / "results"
        out.mkdir(parents=True, exist_ok=True)
        results = []
        for service in [args.service] if args.service else list(B04Run.SERVICES):
            print(f"── B-04 · {args.engine} · {service}", flush=True)
            result = B04Run(args.engine, service, args.path).measure(args.runs, args.startup_runs)
            path = out / f"{args.engine}-{service}-{result['date'].replace(':', '')}.json"
            path.write_text(json.dumps(result, indent=2, ensure_ascii=False))
            results.append(result)
        summarize_b04(results)
        return 0

    out = B00 / "results"
    out.mkdir(exist_ok=True)
    results = []
    for n in range(1, args.runs + 1):
        print(f"── Corrida {n}/{args.runs} · {args.engine} · {args.profile}", flush=True)
        runner = (LegacyRun(args.engine, args.profile) if args.profile in ("legacy", "servicios")
                  else Run(args.engine, args.profile))
        result = runner.measure(args.settle)
        path = out / f"{args.engine}-{args.profile}-{result['date'].replace(':', '')}.json"
        path.write_text(json.dumps(result, indent=2, ensure_ascii=False))
        results.append(result)
    summarize_legacy(results) if args.profile in ("legacy", "servicios") else summarize(results)
    return 0


if __name__ == "__main__":
    sys.exit(main())
