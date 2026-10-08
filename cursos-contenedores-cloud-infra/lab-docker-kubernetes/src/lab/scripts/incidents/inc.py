"""Lleva el laboratorio al estado roto de un incidente del cuaderno, o lo repara.

Uso (desde src/lab/, a través del Taskfile):
    task inc:break -- 05
    task inc:fix -- 05

Cada incidente es el cambio mínimo que lo provoca, aplicado sobre el cluster que ya corre: `minimo` por
defecto, o el que pase el Taskfile (task inc:break PROFILE=lab -- 12; con CLUSTER=lab si en ese cluster
corren los valores de otro perfil). Los de las Fases 16 y 19 son siempre del cluster lab. Reparar es volver al estado del repositorio, no al que se recuerda: hasta la Fase 12, aplicando
los manifiestos; desde la 13, con el chart (task deploy FORCE=true, que le devuelve a Helm los campos
que el incidente cambió a mano). La forma canónica de llegar al estado roto sigue siendo el tag
inc/<ID>/<slug>-roto (cuaderno, "Tres formas de llegar al sistema roto").
Solo biblioteca estándar.
"""
import os
import subprocess
import sys
from pathlib import Path

LAB = Path(__file__).resolve().parents[2]
# El contexto lo pone el Taskfile según PROFILE; quien ya solo tiene el cluster lab, rompe ahí.
CONTEXT = os.environ.get("INC_CONTEXT", "kind-minimo")
CLUSTER = CONTEXT.removeprefix("kind-")
VALUES = os.environ.get("INC_VALUES", CLUSTER)
# Los incidentes de la Fase 16 son del perfil lab (tres nodos, metrics-server).
LAB_CONTEXT = "kind-lab"
MANIFESTS = LAB / "deploy" / "manifests"


def pricing_namespace() -> str:
    """pricing vive en default en la Fase 08 y en apps desde la Fase 09: se busca donde esté."""
    out = subprocess.run(["kubectl", "--context", CONTEXT, "get", "deployment", "-A", "-l",
                          "app.kubernetes.io/name=pricing", "-o", "jsonpath={.items[0].metadata.namespace}"],
                         capture_output=True, text=True).stdout.strip()
    return out or "default"


SECRETS = LAB / ".secrets"


def helm_release() -> bool:
    """¿El sistema está instalado con el chart (Fase 13)?"""
    out = subprocess.run(["helm", "--kube-context", CONTEXT, "-n", "apps", "status", "lab"],
                         capture_output=True, text=True)
    return out.returncode == 0


def restore(manifests: Path) -> None:
    """Vuelve al estado del repositorio: el chart si hay release; si no, los manifiestos."""
    if helm_release():
        cmd = ["task", "deploy", f"CLUSTER={CLUSTER}", "FORCE=true", "--", VALUES]
        print("$", " ".join(cmd), flush=True)
        subprocess.run(cmd, check=True, cwd=LAB)
    else:
        kubectl("-n", pricing_namespace(), "apply", "-f", str(manifests))


def apply_from(cmd: list[str]) -> None:
    """Corre un comando que imprime YAML y lo aplica con kubectl, sin shell (vale igual en Windows)."""
    yaml = subprocess.run(cmd, capture_output=True, text=True, check=True).stdout
    subprocess.run(["kubectl", "--context", CONTEXT, "apply", "-f", "-"], input=yaml, text=True, check=True)


def kubectl(*args: str) -> None:
    cmd = ["kubectl", "--context", CONTEXT, *args]
    print("$", " ".join(cmd), flush=True)
    subprocess.run(cmd, check=True)


# ── Los incidentes de certificados (Fase 19), en el cluster lab ─────────────────────────────────────
TLS = SECRETS / "tls"


def lab(*args: str) -> None:
    cmd = ["kubectl", "--context", LAB_CONTEXT, *args]
    print("$", " ".join(cmd), flush=True)
    subprocess.run(cmd, check=True)


def certs(*args: str) -> None:
    """certs.py con el Python del entorno virtual de scripts/tls (necesita cryptography)."""
    venv = LAB / "scripts" / "tls" / (".venv/Scripts/python.exe" if sys.platform == "win32" else ".venv/bin/python")
    subprocess.run([str(venv), str(LAB / "scripts" / "tls" / "certs.py"), *args], check=True)


def gateway_secret(cert: str, key: str) -> None:
    """Pone a mano el Secret de la puerta, sin validar el par (kubectl create secret tls sí lo valida),
    después de quitarle el Certificate a cert-manager para que no lo vuelva a escribir."""
    import base64
    b64 = lambda name: base64.b64encode((TLS / name).read_bytes()).decode()
    lab("-n", "gateway", "delete", "certificate", "lab-tls", "--ignore-not-found")
    yaml = ("apiVersion: v1\nkind: Secret\nmetadata: {name: lab-tls, namespace: gateway}\n"
            f"type: kubernetes.io/tls\ndata:\n  tls.crt: {b64(cert)}\n  tls.key: {b64(key)}\n")
    subprocess.run(["kubectl", "--context", LAB_CONTEXT, "apply", "-f", "-"], input=yaml, text=True, check=True)


def apply_lab_from(cmd: list[str], namespace: str) -> None:
    """Como apply_from, contra el cluster lab y en un namespace: el manifiesto de un release de Helm no lo
    escribe, y sin -n todo iría a parar a default."""
    yaml = subprocess.run(cmd, capture_output=True, text=True, check=True).stdout
    subprocess.run(["kubectl", "--context", LAB_CONTEXT, "-n", namespace, "apply", "-f", "-"], input=yaml, text=True,
                   check=True)


def certs_back() -> None:
    """Vuelve a cert-manager: el Certificate de la puerta (y el emisor) como dice el repositorio."""
    subprocess.run(["task", "platform:certs", "--", "lab"], check=True, cwd=LAB)


# Cada incidente: (qué hace break, qué hace fix). Los cambios son los del cuaderno, "a mano".
INCIDENTS = {
    # 05 · El pod espera una imagen que el cluster nunca vio: un tag que nadie cargó en el nodo.
    "05": (
        lambda: kubectl("-n", pricing_namespace(), "set", "image", "deployment/pricing",
                        "pricing=lab/pricing:recien-construida"),
        lambda: restore(MANIFESTS / "pricing"),
    ),
    # 06 · El Service existe y nadie le contesta: una label de más en el selector.
    "06": (
        lambda: kubectl("-n", pricing_namespace(), "patch", "service", "pricing", "--type=merge", "-p",
                        '{"spec":{"selector":{"app.kubernetes.io/component":"api"}}}'),
        # apply no quita una label que agregó un patch: se borra el Service y se vuelve a crear.
        lambda: (kubectl("-n", pricing_namespace(), "delete", "service", "pricing"),
                 restore(MANIFESTS / "pricing")),
    ),
    # 07 · inventory no encuentra a catalog: inventory aplicado sin namespace, cae en default.
    "07": (
        lambda: kubectl("apply", "-n", "default", "-f", str(LAB / "deploy" / "incidents" / "07-inventory-sin-namespace.yaml")),
        lambda: kubectl("delete", "-n", "default", "-f", str(LAB / "deploy" / "incidents" / "07-inventory-sin-namespace.yaml")),
    ),
    # 08 · El navegador recibe 404 y ningún pod se entera: la ruta de pricing cuelga de un Gateway en
    # su propio namespace (el parentRef sin `namespace:`), que no existe.
    "08": (
        lambda: kubectl("-n", "apps", "patch", "httproute", "pricing", "--type=json", "-p",
                        '[{"op":"remove","path":"/spec/parentRefs/0/namespace"}]'),
        lambda: restore(MANIFESTS / "pricing" / "httproute.yaml"),
    ),
    # 09 · Cambié la configuración y el servicio sigue igual: la circular nueva en el ConfigMap de los
    # topes; pricing la leyó al arrancar. Reparar es reiniciar (task deploy devuelve la tabla del repo).
    "09": (
        lambda: kubectl("apply", "-f", str(LAB / "deploy" / "incidents" / "09-circular-de-precios.yaml")),
        lambda: (kubectl("-n", "apps", "rollout", "restart", "deployment/pricing"),
                 kubectl("-n", "apps", "rollout", "status", "deployment/pricing", "--timeout=120s")),
    ),
    # 10 · El pod no llega ni a arrancar: el Secret del portal no existe (una máquina nueva, sin
    # .secrets/), y el pod del portal se recrea. Reparar es crearlo: el kubelet reintenta solo.
    "10": (
        lambda: (kubectl("-n", "legacy", "delete", "secret", "portal-contingencia"),
                 kubectl("-n", "legacy", "delete", "pod", "-l", "app.kubernetes.io/name=portal")),
        lambda: kubectl("-n", "legacy", "create", "secret", "generic", "portal-contingencia",
                        f"--from-env-file={SECRETS / 'portal-contingencia.env'}"),
    ),
    # 11 · Postgres se queda esperando para siempre: un StatefulSet copiado de la nube, con una
    # StorageClass que kind no tiene. Reparar es borrarlo con su PVC (task inc:fix no lo corrige: lo quita).
    "11": (
        lambda: kubectl("apply", "-f", str(LAB / "deploy" / "incidents" / "11-postgres-reportes.yaml")),
        lambda: (kubectl("delete", "-f", str(LAB / "deploy" / "incidents" / "11-postgres-reportes.yaml")),
                 kubectl("-n", "data", "delete", "pvc", "data-postgres-reportes-0", "--ignore-not-found")),
    ),
    # 12 · inventory muere sin decir nada: alguien "aprovechó la memoria" con las opciones de la JVM, y
    # la JVM toca todo el heap al arrancar, por encima del límite del contenedor.
    "12": (
        lambda: kubectl("-n", "apps", "set", "env", "deployment/inventory",
                        "JAVA_TOOL_OPTIONS=-XX:MaxRAMPercentage=95 -XX:InitialRAMPercentage=95 -XX:+AlwaysPreTouch"),
        # Helm no es dueño de esa variable (el chart no la pone): hay que quitarla a mano antes de volver.
        lambda: (kubectl("-n", "apps", "set", "env", "deployment/inventory", "JAVA_TOOL_OPTIONS-"),
                 restore(MANIFESTS / "inventory")),
    ),
    # 13 · El servicio corre y nunca recibe tráfico: la contraseña de la base de replenish cambió en el
    # Secret, y el pod nuevo ya no entra. Se borra el pod, como si el nodo se hubiera reiniciado.
    "13": (
        lambda: (apply_from(["kubectl", "-n", "apps", "create", "secret", "generic", "replenish-db",
                             "--from-literal=DATABASE_URL=postgres://replenish:clave-vieja@postgres.data.svc.cluster.local:5432/replenish",
                             "--dry-run=client", "-o", "yaml"]),
                 kubectl("-n", "apps", "delete", "pod", "-l", "app.kubernetes.io/name=replenish,app.kubernetes.io/component=backend")),
        lambda: (apply_from([sys.executable, str(LAB / "scripts" / "data" / "credentials.py")]),
                 kubectl("-n", "apps", "delete", "pod", "-l", "app.kubernetes.io/name=replenish,app.kubernetes.io/component=backend")),
    ),
    # 14 · Kubernetes reinicia un pod que estaba bien: la liveness de catalog con un segundo de paciencia y
    # una sola oportunidad. Se ve con carga: k6 run deploy/incidents/14-carga-catalog.js
    "14": (
        lambda: kubectl("-n", "apps", "patch", "deployment", "catalog", "--type=json", "-p",
                        '[{"op":"replace","path":"/spec/template/spec/containers/1/livenessProbe/timeoutSeconds","value":1},'
                        '{"op":"replace","path":"/spec/template/spec/containers/1/livenessProbe/failureThreshold","value":1}]'),
        lambda: restore(MANIFESTS / "catalog"),
    ),
    # 15 · La réplica nueva no encuentra dónde vivir: Postgres pide la memoria del servidor de Oracle. En
    # apps no pasa (la cuota lo rechaza antes, Fase 15); en data no hay cuota, y el pod queda Pending.
    "15": (
        lambda: kubectl("-n", "data", "patch", "statefulset", "postgres", "--type=json", "-p",
                        '[{"op":"replace","path":"/spec/template/spec/containers/0/resources",'
                        '"value":{"requests":{"cpu":"500m","memory":"4Gi"},"limits":{"memory":"4Gi"}}}]'),
        # La plantilla buena no basta: el StatefulSet no reemplaza solo un pod que nunca estuvo listo.
        lambda: (kubectl("apply", "-f", str(LAB / "platform" / "data" / "postgres" / "statefulset.yaml")),
                 kubectl("-n", "data", "delete", "pod", "postgres-0")),
    ),
    # 16 · El despliegue se quedó a la mitad: la versión nueva de inventory trae una DATABASE_URL que no sirve,
    # su readiness nunca dice que sí, y el rollout espera hasta su plazo (progressDeadlineSeconds).
    "16": (
        lambda: subprocess.run(["kubectl", "--context", LAB_CONTEXT, "-n", "apps", "set", "env", "deployment/inventory",
                                "DATABASE_URL=postgres://inventory:clave-equivocada@postgres.data.svc.cluster.local:5432/inventory"],
                               check=True),
        lambda: (subprocess.run(["kubectl", "--context", LAB_CONTEXT, "-n", "apps", "set", "env", "deployment/inventory",
                                 "DATABASE_URL-"], check=True),
                 subprocess.run(["task", "deploy", "FORCE=true", "--", "lab"], check=True, cwd=LAB)),
    ),
    # 17 · El autoescalador no ve nada: metrics-server con su manifiesto tal cual, sin --kubelet-insecure-tls.
    "17": (
        lambda: subprocess.run(["kubectl", "--context", LAB_CONTEXT, "apply", "-f",
                                str(LAB / "platform" / "metrics-server" / "components.yaml")], check=True),
        lambda: subprocess.run(["task", "platform:metrics", "--", "lab"], check=True, cwd=LAB),
    ),
    # 18 · Ayer funcionaba y hoy el navegador no entra: alguien puso a mano un certificado de dos minutos
    # (o de un año, hace un año). Mientras vale, todo anda; se ve roto a los dos minutos.
    "18": (
        lambda: (certs("leaf", "corto", "--dns", "api.localhost,storefront.localhost", "--days", "0.0014"),
                 gateway_secret("corto.crt", "corto.key")),
        certs_back,
    ),
    # 19 · El cliente no confía en quien firmó: la puerta con un certificado de otra CA, que nadie instaló.
    "19": (
        lambda: (certs("ca", "--name", "otra"),
                 certs("leaf", "ajeno", "--dns", "api.localhost,storefront.localhost", "--ca", "otra"),
                 gateway_secret("ajeno.crt", "ajeno.key")),
        certs_back,
    ),
    # 20 · El certificado es válido, pero no para este nombre: solo para api.localhost.
    "20": (
        lambda: (certs("leaf", "solo-api", "--dns", "api.localhost"), gateway_secret("solo-api.crt", "solo-api.key")),
        certs_back,
    ),
    # 21 · El Gateway rechaza su propio certificado: el certificado bueno con la clave de otro.
    "21": (
        lambda: (certs("leaf", "solo-api", "--dns", "api.localhost"), certs("leaf", "gateway", "--dns",
                 "api.localhost,storefront.localhost,grafana.localhost,prometheus.localhost"),
                 gateway_secret("gateway.crt", "solo-api.key")),
        certs_back,
    ),
    # 22 · cert-manager no emite nada: el emisor perdió el Secret de la CA (alguien limpió cert-manager), y
    # el certificado de pricing, que se renueva, no vuelve. pricing se reinicia y no tiene qué montar.
    "22": (
        lambda: (lab("-n", "cert-manager", "delete", "secret", "lab-ca"),
                 lab("-n", "apps", "delete", "secret", "pricing-tls"),
                 lab("-n", "apps", "rollout", "restart", "deployment/pricing")),
        certs_back,
    ),
    # 23 · pricing rechaza a inventory con mTLS: el bundle de inventory quedó sin su certificado de cliente.
    "23": (
        lambda: lab("-n", "apps", "set", "env", "deployment/inventory",
                    "SPRING_SSL_BUNDLE_PEM_PRICING_KEYSTORE_CERTIFICATE-", "SPRING_SSL_BUNDLE_PEM_PRICING_KEYSTORE_PRIVATEKEY-"),
        lambda: subprocess.run(["task", "deploy", "CLUSTER=lab", "FORCE=true", "--", "minimo"], check=True, cwd=LAB),
    ),
    # 24 · El cluster no puede traer imágenes del registry propio: pricing desde lab-registry, y los nodos sin
    # la CA. Arreglarlo en el cluster no arregla el host: son tres sitios (el cuaderno).
    "24": (
        lambda: (subprocess.run(["task", "registry:up"], check=True, cwd=LAB),
                 subprocess.run(["task", "registry:push", "--", "pricing"], check=True, cwd=LAB),
                 subprocess.run(["task", "registry:untrust", "--", "lab"], check=True, cwd=LAB),
                 lab("-n", "apps", "set", "image", "deployment/pricing", "pricing=lab-registry:5000/lab/pricing:g8")),
        lambda: (subprocess.run(["task", "registry:trust", "--", "lab"], check=True, cwd=LAB),
                 lab("-n", "apps", "delete", "pod", "-l", "app.kubernetes.io/name=pricing,app.kubernetes.io/component=backend")),
    ),
    # 25 · Endurecí el pod y dejó de arrancar: runAsNonRoot en Postgres, sin decir con qué usuario. La imagen
    # oficial arranca como root y baja de privilegios sola; el kubelet no la deja ni empezar.
    "25": (
        lambda: (lab("-n", "data", "patch", "statefulset", "postgres", "--type=json", "-p",
                     '[{"op":"replace","path":"/spec/template/spec/securityContext","value":{"runAsNonRoot":true}}]'),
                 lab("-n", "data", "delete", "pod", "postgres-0")),
        lambda: (lab("apply", "-f", str(LAB / "platform" / "data" / "postgres" / "statefulset.yaml")),
                 lab("-n", "data", "delete", "pod", "postgres-0")),
    ),
    # 26 · Cerré la red y se rompió todo, hasta lo permitido: la política del DNS no está. Reparar con task deploy
    # no sirve (el hook de migraciones corre antes y no resuelve nombres): se vuelve a aplicar el release tal cual.
    "26": (
        lambda: lab("-n", "apps", "delete", "networkpolicy", "allow-dns"),
        lambda: apply_lab_from(["helm", "--kube-context", LAB_CONTEXT, "-n", "apps", "get", "manifest", "lab"], "apps"),
    ),
}


def main(argv: list[str]) -> int:
    if len(argv) != 2 or argv[0] not in ("break", "fix") or argv[1] not in INCIDENTS:
        print(f"Uso: inc.py break|fix <ID>. IDs con tarea: {', '.join(sorted(INCIDENTS))}")
        return 2
    action, incident = argv
    INCIDENTS[incident][0 if action == "break" else 1]()
    print(f"Incidente {incident}: {'roto' if action == 'break' else 'reparado'}.")
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
