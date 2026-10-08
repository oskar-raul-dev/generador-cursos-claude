#!/usr/bin/env python3
"""Orquestador del laboratorio del bloque 06 · Talleres.

Es el "shell con esteroides" común a macOS, Linux y Windows: solo biblioteca estándar, sin
dependencias. Cada taller lo invoca como `python3 06-talleres/laboratorio/scripts/lab.py <orden>`
y explica cada orden en el texto. Los nombres y puertos son los de §11 de la guía.

Órdenes:
  check                      comprueba docker, docker compose y hurl
  up [--mock]                levanta el entorno común (y el mock del contrato si se pide)
  down                       apaga y borra los contenedores; los datos no sobreviven a propósito
  ps | logs [servicio]       estado y registros del compose
  seed [--mongo] [--kafka]   recarga la semilla en PostgreSQL (y el catálogo en MongoDB; y recrea el tópico orders.events, con el backend parado)
  mock                       arranca solo el mock del contrato (Prism) en el puerto 14010
  health --base-url URL      pide /health y muestra la respuesta
  suite --base-url URL [--only v1|v1.1] [--file archivo.hurl] [--verbose]
                             corre la suite de contrato hurl contra un backend
  front [--mock] [--base-url URL] [--test | --build]
                             frontend (06/02): servidor de desarrollo contra un backend o en modo mock
  java [--catalog postgres|mongo] [--test] [--port N] [--events table|kafka] [--payment deterministic|grpc]
                             sabor Java (06/03): arranca el backend en :8081 (o en --port), o corre sus pruebas
  nestjs [--catalog postgres|mongo] [--test]
                             sabor NestJS (06/04): arranca el backend en :8082, o corre pruebas y regla de dependencias
  go [--catalog postgres|mongo] [--test]
                             sabor Go (06/05): arranca el backend en :8083, o corre go vet y go test
  python [--catalog postgres|mongo] [--test]
                             sabor FastAPI (06/06): arranca el backend en :8084, o corre pytest e import-linter
  php [--catalog postgres|mongo] [--test]
                             sabor Laravel (06/07): arranca el backend en :8085 y el worker de la outbox, o corre phpunit y deptrac
  up --jms                   además del entorno común, el broker Artemis del taller 08 (hex-artemis)
  up --kafka                 además del entorno común, el Kafka del taller 09 (hex-kafka)
  java --events kafka [--unkeyed] [--chaos crash-before-offset-commit]
                             taller 09: la outbox publica en orders.events y los consumidores Kafka trabajan
  kafka topic | groups       taller 09: describe orders.events / muestra los grupos y su lag
  kafka tail [--max N]       taller 09: lee el tópico desde el principio mostrando clave y partición
  kafka rebuild              taller 09: borra la proyección y reajusta el grupo hex-orders-summary al offset 0 (backend parado)
  payments-grpc [--test]     taller 10: arranca el proveedor de pagos gRPC en :19090 (fallos por HTTP en :19091), o corre sus pruebas
  java --payment grpc        taller 10: el backend usa payments-grpc en vez de la regla determinista en proceso
  grpc fault none|latency|unavailable [--latency-ms N]
                             taller 10: inyecta un fallo en el proveedor (latencia fija o UNAVAILABLE) o lo quita
  batch sample --out F [--lines N] [--corrupt-at N] [--crash-at N]
                             taller 11: genera un CSV stock (sku,delta,reason) con una línea corrupta y/o un marcador de caída
  batch run --job stockAdjustment|dailyClose [--file F] [--date D] [--chaos]
                             taller 11: ejecuta el job con el mismo jar del backend (sin HTTP) y termina; mismos parámetros = reinicio
  batch status ID            taller 11: GET /api/v1/batches/ID en el backend (:8081) como ops
  batch recover              taller 11: marca FAILED las ejecuciones que quedaron STARTED por una caída (para poder reiniciarlas)
  jms send [--email E] [--line SKU:N ...] [--operation ID] [--count N] [--chaos crash-after-commit] [--poison] [--no-wait]
                             taller 08: envía OrderRequested por STOMP a orders.inbound y espera la respuesta en orders.reply
  jms dlq [--purge]          taller 08: cuántos mensajes hay en la DLQ del broker (y vaciarla)
"""
from __future__ import annotations

import argparse
import json
import os
import shutil
import socket
import subprocess
import sys
import time
import urllib.error
import urllib.request
from pathlib import Path

LAB = Path(__file__).resolve().parent.parent        # 06-talleres/laboratorio
CONTRACT = LAB / "contrato"
COMPOSE = CONTRACT / "docker-compose.yml"
HURL = CONTRACT / "hurl"

# Rutas de la semilla dentro de los contenedores (montadas en el compose como /seed)
SEED_SQL = "/seed/seed.sql"
SEED_MONGO = "/seed/products.json"


def sh(cmd: list[str], check: bool = True, capture: bool = False,
       cwd: Path | None = None, env: dict[str, str] | None = None) -> subprocess.CompletedProcess:
    """Ejecuta un comando mostrándolo antes, para que el texto del taller y la terminal coincidan."""
    print("$", " ".join(cmd), flush=True)
    return subprocess.run(cmd, check=check, text=True, capture_output=capture, cwd=cwd, env=env)


def compose(*args: str, profiles: tuple[str, ...] = ()) -> list[str]:
    cmd = ["docker", "compose", "-f", str(COMPOSE)]
    for p in profiles:
        cmd += ["--profile", p]
    return cmd + list(args)


def require(tool: str) -> None:
    if shutil.which(tool) is None:
        sys.exit(f"falta `{tool}` en el PATH; instálalo antes de seguir")


# ---------------------------------------------------------------- taller 09: Kafka con los scripts del broker (helpers)

KAFKA_BIN = "/opt/kafka/bin"
KAFKA_TOPIC, SUMMARY_GROUP = "orders.events", "hex-orders-summary"


def kafka(script: str, *args: str) -> list[str]:
    # los scripts kafka-*.sh dentro del contenedor, contra el listener interno (9092)
    return ["docker", "exec", "hex-kafka", f"{KAFKA_BIN}/{script}", "--bootstrap-server", "localhost:9092", *args]



# ---------------------------------------------------------------- órdenes

def cmd_check(_: argparse.Namespace) -> None:
    for tool in ("docker", "hurl"):
        path = shutil.which(tool)
        print(f"{tool:8} {'OK  ' + path if path else 'FALTA'}")
    if shutil.which("docker"):
        sh(["docker", "--version"])
        sh(["docker", "compose", "version"])
    if shutil.which("hurl"):
        sh(["hurl", "--version"])
    print(f"compose  {COMPOSE}")
    print(f"suite    {HURL}")


def cmd_up(args: argparse.Namespace) -> None:
    require("docker")
    profiles = tuple(p for p, on in (("mock", args.mock), ("jms", args.jms), ("kafka", args.kafka)) if on)
    # --wait espera a que todos los healthcheck estén en verde antes de devolver el control
    sh(compose("up", "-d", "--wait", profiles=profiles))
    print("\nPostgreSQL  localhost:15432  hex_orders / hex / hex-lab-pass")
    print("MongoDB     localhost:17017  hex_catalog")
    print("Redis       localhost:16379")
    print("Swagger UI  http://localhost:18080")
    if args.mock:
        print("Mock        http://localhost:14010")
    if args.jms:
        print("Artemis     tcp://localhost:61616 (JMS) · localhost:61613 (STOMP) · http://localhost:8161 (consola, hex / hex-lab-pass)")
    if args.kafka:
        print("Kafka       localhost:19092 (tópico orders.events, 3 particiones; lo crea el backend)")


def cmd_down(_: argparse.Namespace) -> None:
    require("docker")
    # todos los perfiles incluidos para que el mock y el broker también caigan; -v borra volúmenes anónimos
    sh(compose("down", "-v", profiles=("mock", "jms", "kafka")))


def cmd_ps(_: argparse.Namespace) -> None:
    require("docker")
    sh(compose("ps", profiles=("mock",)))


def cmd_logs(args: argparse.Namespace) -> None:
    require("docker")
    extra = [args.service] if args.service else []
    sh(compose("logs", "--tail", "100", *extra, profiles=("mock",)), check=False)


def cmd_seed(args: argparse.Namespace) -> None:
    require("docker")
    # -v ON_ERROR_STOP=1: si algo falla, psql termina con error en vez de seguir a medias
    sh(["docker", "exec", "hex-postgres", "psql", "-v", "ON_ERROR_STOP=1", "-q",
        "-U", "hex", "-d", "hex_orders", "-f", SEED_SQL])
    # taller 11: las tablas BATCH_* (si faltan) y su vaciado: cada semilla es también un JobRepository nuevo
    sh(["docker", "exec", "hex-postgres", "psql", "-v", "ON_ERROR_STOP=1", "-q", "-U", "hex", "-d", "hex_orders",
        "-c", "SET client_min_messages = warning",          # sin los NOTICE de "ya existe" y del TRUNCATE en cascada
        "-f", "/seed/schema-batch.sql",
        "-c", "TRUNCATE batch_job_instance CASCADE; ALTER SEQUENCE batch_job_instance_seq RESTART; "
              "ALTER SEQUENCE batch_job_execution_seq RESTART; ALTER SEQUENCE batch_step_execution_seq RESTART"])   # ids desde 1
    print("PostgreSQL: semilla recargada")
    if args.mongo:
        # --drop vacía la colección antes de importar; --jsonArray porque el archivo es una lista
        sh(["docker", "exec", "hex-mongo", "mongoimport", "--quiet",
            "--db", "hex_catalog", "--collection", "products",
            "--drop", "--jsonArray", "--file", SEED_MONGO])
        print("MongoDB: catálogo recargado")
    if args.kafka:
        # el tópico guarda la historia de TODAS las semillas anteriores; si la base vuelve a cero y el
        # log no, una proyección reconstruida cuenta pedidos que ya no existen. Se borra y se recrea
        # con sus tres particiones (el backend tiene que estar parado: lo recrearía él al arrancar)
        sh(kafka("kafka-topics.sh", "--delete", "--topic", KAFKA_TOPIC), check=False)
        time.sleep(2)
        sh(kafka("kafka-topics.sh", "--create", "--topic", KAFKA_TOPIC, "--partitions", "3", "--replication-factor", "1"))
        print("Kafka: tópico orders.events recreado, vacío")


def cmd_mock(_: argparse.Namespace) -> None:
    require("docker")
    sh(compose("up", "-d", "--wait", "mock", profiles=("mock",)))
    print("Mock del contrato en http://localhost:14010")


def cmd_health(args: argparse.Namespace) -> None:
    url = args.base_url.rstrip("/") + "/health"
    try:
        with urllib.request.urlopen(url, timeout=5) as r:
            print(r.status, json.loads(r.read().decode()))
    except urllib.error.URLError as exc:
        sys.exit(f"{url}: {exc}")


def suite_files(only: str | None, single: str | None) -> list[Path]:
    if single:
        return [Path(single)]
    folders = ["v1", "v1.1"] if only is None else [only]
    files: list[Path] = []
    for folder in folders:
        files += sorted((HURL / folder).glob("*.hurl"))
    return files


def cmd_suite(args: argparse.Namespace) -> None:
    require("hurl")
    files = suite_files(args.only, args.file)
    if not files:
        sys.exit("no hay archivos .hurl que correr")
    # --test: modo prueba (resumen por archivo, sin volcar cuerpos); --variable: la URL base es lo
    # único que cambia entre sabores; --jobs 1: en orden, porque los archivos consumen stock
    cmd = ["hurl", "--test", "--jobs", "1", "--variable", f"base_url={args.base_url.rstrip('/')}"]
    if args.verbose:
        cmd.append("--verbose")
    cmd += [str(f) for f in files]
    result = sh(cmd, check=False)
    sys.exit(result.returncode)


def cmd_front(args: argparse.Namespace) -> None:
    require("npm")
    frontend = LAB / "frontend"
    npm = shutil.which("npm")  # en Windows resuelve npm.cmd; por eso no se escribe "npm" a secas
    assert npm is not None
    if not (frontend / "node_modules").exists():
        sh([npm, "install", "--no-fund", "--no-audit"], cwd=frontend)
    if args.test:
        sh([npm, "test"], cwd=frontend); return
    if args.build:
        sh([npm, "run", "build"], cwd=frontend); return
    env = dict(os.environ)
    if args.base_url:
        env["VITE_API_BASE_URL"] = args.base_url   # la única configuración del cliente
    script = "dev:mock" if args.mock else "dev"
    sh([npm, "run", script], cwd=frontend, env=env)


def cmd_java(args: argparse.Namespace) -> None:
    require("mvn")
    project = LAB / "java"
    mvn = shutil.which("mvn")
    assert mvn is not None
    if args.test:
        sh([mvn, "-q", "test"], cwd=project); return
    # el catálogo se elige aquí, desde fuera: el código no cambia entre postgres y mongo.
    # --port levanta una segunda instancia (taller 08: consumidores competidores) sin tocar nada.
    arguments = (f"--hex.catalog={args.catalog} --server.port={args.port} --hex.events.transport={args.events}"
                 f" --hex.payment.provider={args.payment}")
    if args.unkeyed:
        # taller 09: productor sin clave, a propósito. Con clave nula el particionador por defecto de
        # Kafka es "sticky" (una ráfaga entera a la misma partición) y el desorden no se ve; el
        # RoundRobin reparte registro a registro, que es el peor caso y el que el taller quiere mirar.
        arguments += (" --hex.kafka.keyed=false"
                      " --spring.kafka.producer.properties.partitioner.class=org.apache.kafka.clients.producer.RoundRobinPartitioner")
    if args.chaos:
        arguments += f" --hex.kafka.chaos={args.chaos}"   # taller 09: caída tras aplicar y antes del commit de offset
    sh([mvn, "-q", "spring-boot:run", f"-Dspring-boot.run.arguments={arguments}"], cwd=project)


def cmd_nestjs(args: argparse.Namespace) -> None:
    require("npm")
    project = LAB / "nestjs"
    npm = shutil.which("npm")
    assert npm is not None
    if not (project / "node_modules").exists():
        sh([npm, "install", "--no-fund", "--no-audit"], cwd=project)
    if args.test:
        sh([npm, "test"], cwd=project)
        sh([npm, "run", "arch"], cwd=project); return
    sh([npm, "run", "build"], cwd=project)          # genera el cliente Prisma y compila con tsc
    env = dict(os.environ, HEX_CATALOG=args.catalog)  # el catálogo se elige desde fuera del código
    sh([npm, "start"], cwd=project, env=env)


def cmd_go(args: argparse.Namespace) -> None:
    require("go")
    project = LAB / "go"
    go = shutil.which("go")
    assert go is not None
    if args.test:
        sh([go, "vet", "./..."], cwd=project)
        sh([go, "test", "./..."], cwd=project); return
    env = dict(os.environ, HEX_CATALOG=args.catalog)  # el catálogo se elige desde fuera del código
    sh([go, "run", "./cmd/server"], cwd=project, env=env)


def cmd_python(args: argparse.Namespace) -> None:
    require("uv")
    project = LAB / "python"
    uv = shutil.which("uv")
    assert uv is not None
    sh([uv, "sync", "--python", "3.14"], cwd=project)     # crea .venv con la versión fijada e instala lo del lock
    if args.test:
        sh([uv, "run", "pytest", "-q"], cwd=project)
        sh([uv, "run", "lint-imports"], cwd=project); return
    env = dict(os.environ, HEX_CATALOG=args.catalog)     # el catálogo se elige desde fuera del código
    sh([uv, "run", "python", "-m", "hexorders.main"], cwd=project, env=env)


def cmd_php(args: argparse.Namespace) -> None:
    require("php"); require("composer")
    project = LAB / "php"
    php, composer = shutil.which("php"), shutil.which("composer")
    assert php is not None and composer is not None
    if not (project / "vendor").exists():
        sh([composer, "install", "--no-interaction"], cwd=project)
    if not (project / ".env").exists():                     # .env.example es la configuración del laboratorio
        shutil.copy(project / ".env.example", project / ".env")
        sh([php, "artisan", "key:generate", "--no-interaction"], cwd=project)
    if args.test:
        sh([str(project / "vendor" / "bin" / "phpunit"), "--testdox"], cwd=project)
        sh([str(project / "vendor" / "bin" / "deptrac"), "analyse", "--no-progress"], cwd=project); return
    env = dict(os.environ, HEX_CATALOG=args.catalog)     # el catálogo se elige desde fuera del código
    # PHP no tiene hilos de fondo en el servidor HTTP: el worker de la outbox es un segundo proceso.
    print("$", "php artisan outbox:work  (en segundo plano)", flush=True)
    worker = subprocess.Popen([php, "artisan", "outbox:work"], cwd=project, env=env)
    try:
        sh([php, "artisan", "serve", "--host", "0.0.0.0", "--port", "8085"], cwd=project, env=env)
    finally:
        worker.terminate(); worker.wait(timeout=10)


# ---------------------------------------------------------------- taller 08: STOMP a mano

STOMP_HOST, STOMP_PORT = "localhost", 61613
BROKER_USER, BROKER_PASS = "hex", "hex-lab-pass"


class Stomp:
    """Cliente STOMP 1.2 mínimo, solo con `socket`: CONNECT, SEND, SUBSCRIBE y leer frames.
    Artemis habla STOMP en 61613 con los mismos usuarios que JMS; los mensajes que manda un cliente
    STOMP los recibe un @JmsListener como TextMessage con sus cabeceras como propiedades."""

    def __init__(self) -> None:
        self.sock = socket.create_connection((STOMP_HOST, STOMP_PORT), timeout=10)
        self.buffer = b""
        self.send_frame("CONNECT", {"accept-version": "1.2", "host": "/", "login": BROKER_USER, "passcode": BROKER_PASS})
        command, _, _ = self.read_frame()
        if command != "CONNECTED":
            sys.exit(f"STOMP: el broker no aceptó la conexión ({command})")

    def send_frame(self, command: str, headers: dict[str, str], body: str = "") -> None:
        # sin content-length: Artemis entrega el cuerpo como TextMessage (con él sería BytesMessage)
        data = body.encode()
        head = "\n".join([command] + [f"{k}:{v}" for k, v in headers.items()])
        self.sock.sendall(head.encode() + b"\n\n" + data + b"\0")

    def read_frame(self) -> tuple[str, dict[str, str], str]:
        while b"\0" not in self.buffer:                      # un frame termina en NUL
            chunk = self.sock.recv(65536)
            if not chunk:
                sys.exit("STOMP: el broker cerró la conexión")
            self.buffer += chunk
        raw, _, self.buffer = self.buffer.partition(b"\0")
        raw = raw.lstrip(b"\n")                                # latidos entre frames
        head, _, body = raw.partition(b"\n\n")
        lines = head.decode().split("\n")
        headers = dict(line.split(":", 1) for line in lines[1:] if ":" in line)
        return lines[0], headers, body.decode()

    def send(self, destination: str, body: str, headers: dict[str, str]) -> None:
        # destination-type ANYCAST: una cola (un consumidor por mensaje), no un tópico
        self.send_frame("SEND", {"destination": destination, "destination-type": "ANYCAST",
                                 "content-type": "application/json", **headers}, body)

    def subscribe(self, destination: str) -> None:
        # ack client-individual: cada mensaje se confirma con un frame ACK propio cuando ya se leyó;
        # lo que no se confirma vuelve a entregarse a la siguiente suscripción
        self.send_frame("SUBSCRIBE", {"id": "0", "destination": destination, "subscription-type": "ANYCAST", "ack": "client-individual"})

    def ack(self, headers: dict[str, str]) -> None:
        self.send_frame("ACK", {"id": headers["ack"]})

    def close(self) -> None:
        self.send_frame("DISCONNECT", {})
        self.sock.close()


def cmd_jms_send(args: argparse.Namespace) -> None:
    import json
    lines = [{"sku": sku, "quantity": int(qty)} for sku, qty in (l.split(":") for l in args.line)]
    stomp = Stomp()
    if not args.no_wait:
        stomp.subscribe("orders.reply")
    pending: dict[str, str] = {}
    for i in range(args.count):
        operation = args.operation if args.count == 1 else f"{args.operation}-{i + 1:03d}"
        correlation = f"corr-{operation}"
        body = "{not json" if args.poison else json.dumps({"operationId": operation, "customerEmail": args.email, "lines": lines})
        headers = {"correlation-id": correlation, "reply-to": "orders.reply"}
        if args.chaos:
            headers["hexChaos"] = args.chaos                  # llega al listener como propiedad del mensaje
        stomp.send("orders.inbound", body, headers)
        print(f"→ orders.inbound  operationId={operation}  correlation={correlation}" + ("  [POISON]" if args.poison else ""))
        pending[correlation] = operation
    if args.no_wait or args.poison:
        stomp.close(); return
    # Espera la respuesta de CADA envío por su correlation-id; lo que no sea nuestro se descarta.
    stomp.sock.settimeout(args.timeout)
    try:
        while pending:
            command, headers, body = stomp.read_frame()
            if command != "MESSAGE":
                continue
            stomp.ack(headers)                                    # leído: que el broker no lo vuelva a entregar
            correlation = headers.get("correlation-id", "")
            if correlation in pending:
                del pending[correlation]
                reply = json.loads(body)
                print(f"← orders.reply    {reply['status']:<9}" + (f"orderId={reply['orderId']} total={reply['total']['amount']} replayed={reply['replayed']}"
                      if reply["status"] == "ACCEPTED" else f"code={reply['code']} message={reply.get('message')}"))
    except socket.timeout:
        print(f"sin respuesta en {args.timeout}s para: {', '.join(pending.values())}")
    finally:
        stomp.close()


def cmd_jms_dlq(args: argparse.Namespace) -> None:
    require("docker")
    artemis = ["docker", "exec", "hex-artemis", "/var/lib/artemis-instance/bin/artemis"]
    auth = ["--user", BROKER_USER, "--password", BROKER_PASS, "--url", "tcp://localhost:61616"]
    if args.purge:
        # vacía la DLQ (los mensajes apartados se pierden: es lo que se quiere entre dos provocaciones)
        sh(artemis + ["queue", "purge", "--name", "DLQ"] + auth)
    # la CLI del broker dentro del contenedor: cuántos mensajes hay en la DLQ y cuántos llegaron a ella
    sh(artemis + ["queue", "stat", "--queueName", "DLQ"] + auth)


def cmd_kafka_topic(_: argparse.Namespace) -> None:
    require("docker")
    sh(kafka("kafka-topics.sh", "--describe", "--topic", KAFKA_TOPIC), check=False)


def cmd_kafka_groups(_: argparse.Namespace) -> None:
    require("docker")
    # --all-groups --describe: por grupo, partición, offset actual, fin del log y lag; y qué consumidor la tiene
    sh(kafka("kafka-consumer-groups.sh", "--all-groups", "--describe"), check=False)


def cmd_kafka_tail(args: argparse.Namespace) -> None:
    require("docker")
    # el consumidor de consola: desde el principio, N mensajes, con clave y partición en cada línea
    sh(kafka("kafka-console-consumer.sh", "--topic", KAFKA_TOPIC, "--from-beginning",
             "--max-messages", str(args.max), "--timeout-ms", "5000",
             "--property", "print.key=true", "--property", "print.partition=true", "--property", "key.separator= | "),
       check=False)


def cmd_kafka_rebuild(_: argparse.Namespace) -> None:
    require("docker")
    # 1. la proyección se vacía (y su registro de eventos aplicados, o los saltaría todos)
    sh(["docker", "exec", "hex-postgres", "psql", "-v", "ON_ERROR_STOP=1", "-q", "-U", "hex", "-d", "hex_orders",
        "-c", "TRUNCATE orders_summary; DELETE FROM applied_events WHERE projection = 'orders_summary';"])
    # 2. el grupo vuelve al offset 0 de cada partición. Solo se puede con el grupo inactivo: el backend parado
    sh(kafka("kafka-consumer-groups.sh", "--group", SUMMARY_GROUP, "--topic", KAFKA_TOPIC,
             "--reset-offsets", "--to-earliest", "--execute"))
    print("proyección vacía y grupo en el offset 0: al arrancar `lab.py java --events kafka` se reconstruye")


# ---------------------------------------------------------------- taller 10: el proveedor gRPC

def cmd_payments_grpc(args: argparse.Namespace) -> None:
    require("mvn")
    project = LAB / "payments-grpc"
    mvn = shutil.which("mvn")
    assert mvn is not None
    if args.test:
        sh([mvn, "-q", "test"], cwd=project); return
    # el .proto se compila en cada build (protobuf-maven-plugin descarga protoc); el servidor queda en :19090
    sh([mvn, "-q", "spring-boot:run"], cwd=project)


def cmd_grpc_fault(args: argparse.Namespace) -> None:
    # el servidor expone POST /faults en :19091; el fallo aplica a TODAS las llamadas hasta que se quite
    body = json.dumps({"mode": args.mode, "latencyMs": args.latency_ms}).encode()
    req = urllib.request.Request("http://localhost:19091/faults", data=body, method="POST",
                                 headers={"Content-Type": "application/json"})
    try:
        with urllib.request.urlopen(req, timeout=5) as resp:
            print("fault:", resp.read().decode())
    except urllib.error.URLError as e:
        sys.exit(f"payments-grpc no responde en :19091 ({e}); arráncalo con `lab.py payments-grpc`")


# ---------------------------------------------------------------- taller 11: lotes

SKUS = ["SKU-001", "SKU-002", "SKU-003", "SKU-004", "SKU-005"]


def cmd_batch_sample(args: argparse.Namespace) -> None:
    import random
    random.seed(args.lines)                                 # el mismo archivo cada vez, para poder comparar corridas
    out = Path(args.out).resolve()
    out.parent.mkdir(parents=True, exist_ok=True)
    lines = ["sku,delta,reason"]
    for i in range(1, args.lines + 1):
        sku, delta, reason = random.choice(SKUS), random.choice([1, 2, 3, 5, 10, -1, -2]), "supplier-receipt"
        if i == args.corrupt_at:
            sku, delta, reason = "SKU-???", "diez", "typo"     # ni el sku ni el delta valen: a cuarentena
        if i == args.crash_at:
            reason = "CRASH"                                # con --chaos, la JVM muere al procesar esta línea
        lines.append(f"{sku},{delta},{reason}")
    out.write_text("\n".join(lines) + "\n", encoding="utf-8")
    print(f"{out}: {args.lines} líneas" + (f", corrupta la {args.corrupt_at}" if args.corrupt_at else "")
          + (f", marcador de caída en la {args.crash_at}" if args.crash_at else ""))


def cmd_batch_run(args: argparse.Namespace) -> None:
    require("mvn")
    project = LAB / "java"
    mvn = shutil.which("mvn")
    assert mvn is not None
    # El mismo proyecto que sirve HTTP, arrancado como CLI: sin servidor web, con el job habilitado y
    # nombrado. Los argumentos sin `--` son parámetros del job (identifican el JobInstance).
    arguments = ["--spring.main.web-application-type=none", "--spring.batch.job.enabled=true",
                 f"--spring.batch.job.name={args.job}", "--hex.events.transport=table",
                 "--spring.jms.listener.auto-startup=false",          # un lote no consume la cola del taller 08
                 "--logging.level.root=warn",
                 "--logging.level.hex.orders=info", "--logging.level.org.springframework.batch=info"]
    if args.chaos:
        arguments.append("--hex.batch.chaos=crash-on-marker")
    if args.job == "stockAdjustment":
        if not args.file:
            sys.exit("stockAdjustment necesita --file")
        arguments.append(f"file={Path(args.file).resolve()}")
    else:
        arguments.append(f"date={args.date or time.strftime('%Y-%m-%d')}")
    result = sh([mvn, "-q", "spring-boot:run", "-Dspring-boot.run.arguments=" + " ".join(arguments)], cwd=project, check=False)
    print(f"batch: el proceso terminó con código {result.returncode}")


def cmd_batch_recover(_: argparse.Namespace) -> None:
    require("docker")
    # Una JVM que muere no cierra su JobExecution: queda STARTED y el JobRepository cree que sigue
    # corriendo (el lease). Antes de reiniciar hay que declararla fallida; Batch 6 lo hace con
    # JobOperator.recover, y un operador lo ha hecho siempre así, sobre la tabla.
    sh(["docker", "exec", "hex-postgres", "psql", "-v", "ON_ERROR_STOP=1", "-U", "hex", "-d", "hex_orders", "-c",
        "UPDATE batch_step_execution SET status = 'FAILED', exit_code = 'FAILED', end_time = now() WHERE status = 'STARTED'; "
        "UPDATE batch_job_execution SET status = 'FAILED', exit_code = 'FAILED', end_time = now() WHERE status = 'STARTED';"])


def cmd_batch_status(args: argparse.Namespace) -> None:
    login = urllib.request.Request("http://localhost:8081/api/v1/auth/login", method="POST",
                                   data=json.dumps({"email": "ops@hex.local", "password": "ops-12345"}).encode(),
                                   headers={"Content-Type": "application/json"})
    try:
        with urllib.request.urlopen(login, timeout=5) as resp:
            token = json.load(resp)["accessToken"]
        req = urllib.request.Request(f"http://localhost:8081/api/v1/batches/{args.id}", headers={"Authorization": f"Bearer {token}"})
        with urllib.request.urlopen(req, timeout=5) as resp:
            print(json.dumps(json.load(resp), indent=2, ensure_ascii=False))
    except urllib.error.HTTPError as e:
        print(e.code, e.read().decode())
    except urllib.error.URLError as e:
        sys.exit(f"el backend no responde en :8081 ({e}); arráncalo con `lab.py java`")


# ---------------------------------------------------------------- CLI

def main() -> None:
    parser = argparse.ArgumentParser(prog="lab.py", description=__doc__,
                                     formatter_class=argparse.RawDescriptionHelpFormatter)
    sub = parser.add_subparsers(dest="cmd", required=True)

    sub.add_parser("check").set_defaults(fn=cmd_check)
    p = sub.add_parser("up"); p.add_argument("--mock", action="store_true"); p.add_argument("--jms", action="store_true"); p.add_argument("--kafka", action="store_true"); p.set_defaults(fn=cmd_up)
    sub.add_parser("down").set_defaults(fn=cmd_down)
    sub.add_parser("ps").set_defaults(fn=cmd_ps)
    p = sub.add_parser("logs"); p.add_argument("service", nargs="?"); p.set_defaults(fn=cmd_logs)
    p = sub.add_parser("seed"); p.add_argument("--mongo", action="store_true"); p.add_argument("--kafka", action="store_true"); p.set_defaults(fn=cmd_seed)
    sub.add_parser("mock").set_defaults(fn=cmd_mock)
    p = sub.add_parser("health"); p.add_argument("--base-url", required=True); p.set_defaults(fn=cmd_health)
    p = sub.add_parser("suite")
    p.add_argument("--base-url", required=True)
    p.add_argument("--only", choices=["v1", "v1.1"])
    p.add_argument("--file")
    p.add_argument("--verbose", action="store_true")
    p.set_defaults(fn=cmd_suite)
    p = sub.add_parser("front")
    p.add_argument("--mock", action="store_true")
    p.add_argument("--base-url")
    p.add_argument("--test", action="store_true")
    p.add_argument("--build", action="store_true")
    p.set_defaults(fn=cmd_front)
    p = sub.add_parser("java")
    p.add_argument("--catalog", choices=["postgres", "mongo"], default="postgres")
    p.add_argument("--test", action="store_true")
    p.add_argument("--port", type=int, default=8081)
    p.add_argument("--events", choices=["table", "kafka"], default="table")
    p.add_argument("--unkeyed", action="store_true")
    p.add_argument("--chaos", choices=["crash-before-offset-commit"])
    p.add_argument("--payment", choices=["deterministic", "grpc"], default="deterministic")
    p.set_defaults(fn=cmd_java)
    p = sub.add_parser("payments-grpc"); p.add_argument("--test", action="store_true"); p.set_defaults(fn=cmd_payments_grpc)
    p = sub.add_parser("grpc").add_subparsers(dest="grpc_cmd", required=True).add_parser("fault")
    p.add_argument("mode", choices=["none", "latency", "unavailable"])
    p.add_argument("--latency-ms", type=int, default=3000)
    p.set_defaults(fn=cmd_grpc_fault)
    p = sub.add_parser("nestjs")
    p.add_argument("--catalog", choices=["postgres", "mongo"], default="postgres")
    p.add_argument("--test", action="store_true")
    p.set_defaults(fn=cmd_nestjs)
    p = sub.add_parser("go")
    p.add_argument("--catalog", choices=["postgres", "mongo"], default="postgres")
    p.add_argument("--test", action="store_true")
    p.set_defaults(fn=cmd_go)
    p = sub.add_parser("python")
    p.add_argument("--catalog", choices=["postgres", "mongo"], default="postgres")
    p.add_argument("--test", action="store_true")
    p.set_defaults(fn=cmd_python)
    p = sub.add_parser("php")
    p.add_argument("--catalog", choices=["postgres", "mongo"], default="postgres")
    p.add_argument("--test", action="store_true")
    p.set_defaults(fn=cmd_php)

    jms = sub.add_parser("jms").add_subparsers(dest="jms_cmd", required=True)
    p = jms.add_parser("send")
    p.add_argument("--email", default="ana@hex.local")
    p.add_argument("--line", action="append", default=None, help="SKU:cantidad; repetible")
    p.add_argument("--operation", default=None, help="operationId (clave de idempotencia); por defecto uno nuevo")
    p.add_argument("--count", type=int, default=1)
    p.add_argument("--chaos", choices=["crash-after-commit"])
    p.add_argument("--poison", action="store_true", help="cuerpo ilegible: provoca redelivery y DLQ")
    p.add_argument("--no-wait", action="store_true")
    p.add_argument("--timeout", type=float, default=15.0)
    p.set_defaults(fn=cmd_jms_send)
    p = jms.add_parser("dlq"); p.add_argument("--purge", action="store_true"); p.set_defaults(fn=cmd_jms_dlq)

    kf = sub.add_parser("kafka").add_subparsers(dest="kafka_cmd", required=True)
    kf.add_parser("topic").set_defaults(fn=cmd_kafka_topic)
    kf.add_parser("groups").set_defaults(fn=cmd_kafka_groups)
    p = kf.add_parser("tail"); p.add_argument("--max", type=int, default=20); p.set_defaults(fn=cmd_kafka_tail)
    kf.add_parser("rebuild").set_defaults(fn=cmd_kafka_rebuild)

    bt = sub.add_parser("batch").add_subparsers(dest="batch_cmd", required=True)
    p = bt.add_parser("sample"); p.add_argument("--out", required=True); p.add_argument("--lines", type=int, default=1000)
    p.add_argument("--corrupt-at", type=int, default=0); p.add_argument("--crash-at", type=int, default=0); p.set_defaults(fn=cmd_batch_sample)
    p = bt.add_parser("run"); p.add_argument("--job", choices=["stockAdjustment", "dailyClose"], required=True)
    p.add_argument("--file"); p.add_argument("--date"); p.add_argument("--chaos", action="store_true"); p.set_defaults(fn=cmd_batch_run)
    p = bt.add_parser("status"); p.add_argument("id", type=int); p.set_defaults(fn=cmd_batch_status)
    bt.add_parser("recover").set_defaults(fn=cmd_batch_recover)

    args = parser.parse_args()
    if getattr(args, "jms_cmd", None) == "send":
        args.line = args.line or ["SKU-001:2"]
        args.operation = args.operation or f"ext-{int(time.time())}"
    if getattr(args, "file", None):
        args.file = str(Path(args.file).resolve())   # antes del chdir: la ruta puede ser relativa al cwd del usuario
    os.chdir(LAB)
    args.fn(args)


if __name__ == "__main__":
    main()
