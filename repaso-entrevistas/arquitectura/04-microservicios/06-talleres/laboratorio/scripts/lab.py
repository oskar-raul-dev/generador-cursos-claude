#!/usr/bin/env python3
"""lab.py — orquestador del bloque 06 · Talleres (corpus de microservicios).

Python 3.11+ y solo biblioteca estándar: funciona igual en macOS, Linux y Windows. Cada orden se
explica en el taller que la introduce; `python3 lab.py -h` lista todas.

Nombres, puertos y credenciales: §14 de la guía de estilo.
"""
import argparse
import concurrent.futures as futures
import json
import os
import shutil
import subprocess
import sys
import threading
import time
import urllib.error
import urllib.parse
import urllib.request
import uuid
from pathlib import Path

LAB = Path(__file__).resolve().parent.parent          # 06-talleres/laboratorio (estado del último taller)
CONTRACT = LAB / "contrato"
COMPOSE = ["docker", "compose", "-f", str(CONTRACT / "docker-compose.yml")]


def use_state(state):
    """Trabaja sobre laboratorio/estados/NN/: el código tal como quedó al terminar el taller NN."""
    global LAB, CONTRACT, COMPOSE
    root = LAB / "estados" / state
    if not root.is_dir():
        sys.exit(f"no existe el estado {state}: {', '.join(sorted(p.name for p in (LAB / 'estados').iterdir()))}")
    LAB, CONTRACT = root, root / "contrato"
    COMPOSE = ["docker", "compose", "-f", str(CONTRACT / "docker-compose.yml")]
    print(f"[estado {state}: {LAB}]", flush=True)
TOXIPROXY = "http://localhost:28474"
PSP_URL = "http://localhost:28085"
MONOLITH_URL = "http://localhost:28081"
JAVA_HOME_HINT = Path.home() / ".sdkman/candidates/java/25.0.4-tem"
# taller 07: el agente de OpenTelemetry para Java. Vive fuera de los estados congelados (no se copia)
OTEL_AGENT_VERSION = "2.31.1"
OTEL_AGENT = LAB / "tools" / "otel" / f"opentelemetry-javaagent-{OTEL_AGENT_VERSION}.jar"
JAEGER_URL = "http://localhost:26686"


# ------------------------------------------------------------------ utilidades

def run(cmd, check=True, **kw):
    print("$ " + " ".join(str(c) for c in cmd), flush=True)
    return subprocess.run(cmd, check=check, **kw)


def http(method, url, body=None, headers=None, timeout=30):
    """Petición HTTP mínima. Devuelve (status, headers, cuerpo_json_o_texto, segundos)."""
    data = json.dumps(body).encode() if body is not None else None
    req = urllib.request.Request(url, data=data, method=method, headers=headers or {})
    if data is not None:
        req.add_header("Content-Type", "application/json")
    t0 = time.monotonic()
    try:
        with urllib.request.urlopen(req, timeout=timeout) as res:
            raw, status, hdrs = res.read(), res.status, dict(res.headers)
    except urllib.error.HTTPError as e:
        raw, status, hdrs = e.read(), e.code, dict(e.headers)
    except (urllib.error.URLError, TimeoutError, ConnectionError) as e:
        return 0, {}, str(e), time.monotonic() - t0
    elapsed = time.monotonic() - t0
    try:
        return status, hdrs, json.loads(raw) if raw else None, elapsed
    except ValueError:
        return status, hdrs, raw.decode(errors="replace"), elapsed


def psql(database, user, sql_file=None, sql=None):
    """Ejecuta SQL dentro de ms-postgres con el usuario dueño de la base."""
    cmd = ["docker", "exec", "-i", "-e", "PGPASSWORD=ms-lab-pass", "-e", "PGOPTIONS=-c client_min_messages=warning", "ms-postgres",
           "psql", "-v", "ON_ERROR_STOP=1", "-q", "-U", user, "-d", database]
    if sql_file:
        cmd += ["-f", f"/seed/{sql_file}"]
    else:
        cmd += ["-c", sql]
    return run(cmd)


def login(base, email="ana@ms.local", password="ana-12345"):
    status, _, body, _ = http("POST", f"{base}/api/v1/auth/login", {"email": email, "password": password})
    if status != 200:
        sys.exit(f"login falló contra {base}: {status} {body}")
    return body["accessToken"]


def tracing_on():
    """Desde el taller 07 el compose trae el collector: los servicios exportan trazas."""
    return "otel-collector:" in (CONTRACT / "docker-compose.yml").read_text()


def otel_java(service, env):
    """Argumentos de JVM y variables para arrancar un servicio Java con el agente (taller 07)."""
    if not tracing_on():
        return []
    if not OTEL_AGENT.exists():
        # una dependencia más, descargada por Maven como las demás: nada se instala en el sistema
        run(["mvn", "-q", "dependency:copy",
             f"-Dartifact=io.opentelemetry.javaagent:opentelemetry-javaagent:{OTEL_AGENT_VERSION}",
             f"-DoutputDirectory={OTEL_AGENT.parent}"], env=env)
    env.update({
        "OTEL_SERVICE_NAME": service,
        "OTEL_EXPORTER_OTLP_ENDPOINT": "http://localhost:24318",   # el collector, OTLP/HTTP
        "OTEL_METRICS_EXPORTER": "none",                           # este taller mira trazas y logs
        "OTEL_LOGS_EXPORTER": "none",                              # los logs salen por consola, con trace_id
    })
    return [f"-javaagent:{OTEL_AGENT}"]


def java_env():
    env = dict(os.environ)
    if JAVA_HOME_HINT.exists():
        env["JAVA_HOME"] = str(JAVA_HOME_HINT)
        env["PATH"] = str(JAVA_HOME_HINT / "bin") + os.pathsep + env["PATH"]
    return env


# ------------------------------------------------------------------ órdenes

def cmd_check(_):
    """Comprueba que las herramientas del laboratorio están instaladas, sin instalar nada."""
    ok = True
    for tool, args in [("docker", ["--version"]), ("hurl", ["--version"]), ("mvn", ["-v"])]:
        path = shutil.which(tool)
        line = subprocess.run([tool, *args], capture_output=True, text=True, env=java_env()).stdout.splitlines()[0] if path else "NO ENCONTRADO"
        print(f"{tool:8} {line}")
        ok &= bool(path)
    java = JAVA_HOME_HINT / "bin" / "java"
    print(f"{'java':8} {subprocess.run([str(java), '-version'], capture_output=True, text=True).stderr.splitlines()[0] if java.exists() else 'JDK 25 no encontrado en ' + str(JAVA_HOME_HINT)}")
    print(f"{'python':8} {sys.version.split()[0]}")
    sys.exit(0 if ok else 1)


def cmd_up(args):
    """Levanta el entorno común (PostgreSQL y Toxiproxy) y espera a que esté sano."""
    cmd = COMPOSE + (["--profile", "mock"] if args.mock else []) + ["up", "-d", "--wait"]
    run(cmd)


def cmd_down(_):
    """Apaga el entorno y borra sus volúmenes: nada sobrevive entre talleres."""
    run(COMPOSE + ["--profile", "mock", "down", "-v", "--remove-orphans"])


def cmd_seed(args):
    """Recrea el esquema y la semilla de cada base, vacía el registro del PSP y quita los tóxicos."""
    psql("ms_monolith", "ms_monolith", "monolith/schema.sql")
    psql("ms_monolith", "ms_monolith", "monolith/seed.sql")
    if (CONTRACT / "seed" / "inventory").is_dir():          # desde el taller 02
        psql("ms_inventory", "ms_inventory", "inventory/schema.sql")
        psql("ms_inventory", "ms_inventory", "inventory/seed.sql")
    if (CONTRACT / "seed" / "payments").is_dir():           # desde el taller 03
        psql("ms_payments", "ms_payments", "payments/schema.sql")
    if (CONTRACT / "seed" / "orders").is_dir():             # desde el taller 04
        psql("ms_orders", "ms_orders", "orders/schema.sql")
    if getattr(args, "kafka", False):                       # taller 06: solo con los consumidores PARADOS
        recreate_topics()
    status, _, _, _ = http("POST", f"{PSP_URL}/admin/reset", {})
    print(f"psp-simulator reset: {status or 'no está corriendo'}")
    toxics_clear()
    print("semilla cargada")


def cmd_suite(args):
    """Corre la colección hurl contra una URL base (por defecto, el monolito). Siembra antes."""
    if not args.no_seed:
        cmd_seed(args)
    files = sorted((CONTRACT / "hurl" / args.dir).glob("*.hurl"))
    rc = run(["hurl", "--test", "--jobs", "1", "--variable", f"base_url={args.base_url}", *map(str, files)], check=False).returncode
    sys.exit(rc)


def cmd_mock(args):
    """Levanta solo el mock del contrato (Prism) en :24010."""
    run(COMPOSE + ["--profile", "mock", "up", "-d", "--wait", "mock"])


def cmd_monolith(args):
    """Compila y arranca ms-monolith en primer plano (Ctrl+C para pararlo)."""
    project = LAB / "monolith"
    env = java_env()
    run(["mvn", "-q", "-DskipTests", "package"], cwd=project, env=env)
    extra = [f"--spring.datasource.hikari.maximum-pool-size={args.pool}"] if args.pool else []
    extra += [f"--ms.inventory.mode={args.inventory}", f"--ms.payments.mode={args.payments}"]
    if args.no_payment_key:
        extra += ["--ms.payments.propagate-key=false"]
    if args.inventory_timeout is not None:
        extra += [f"--ms.inventory.read-timeout-ms={args.inventory_timeout}"]
    agent = otel_java("monolith", env)
    run(["java", *agent, "-jar", "target/ms-monolith-1.0.0.jar", f"--server.port={args.port}", *extra], cwd=project, env=env, check=False)


INVENTORY_DB = {
    "own": "postgres://ms_inventory:ms-lab-pass@localhost:25432/ms_inventory",
    # el atajo del taller 02: el servicio nuevo contra la base del monolito, con el usuario del monolito
    "shared": "postgres://ms_monolith:ms-lab-pass@localhost:25432/ms_monolith",
}


def cmd_inventory(args):
    """Compila y arranca el servicio inventory (Go) en primer plano, contra su base o la compartida."""
    project = LAB / "inventory"
    run(["go", "build", "-o", "bin/inventory", "./cmd/inventory"], cwd=project)
    extra = ["-detach-deadline"] if args.detach_deadline else []
    if "kafka:" in (CONTRACT / "docker-compose.yml").read_text():   # taller 06: consumidor de orders.events
        extra += ["-kafka", "localhost:29092", f"-inbox={str(not args.no_inbox).lower()}", "-chaos", args.chaos]
    if args.rps:
        extra += ["-rps", str(args.rps), "-burst", str(args.burst)]
    if args.max_inflight:
        extra += ["-max-inflight", str(args.max_inflight)]
    if tracing_on():                                                 # taller 07
        extra += ["-otlp", "localhost:24317", f"-trace-kafka={str(not args.no_trace_kafka).lower()}"]
    if args.hold_ttl:                                                # taller 09
        extra += ["-hold-ttl", args.hold_ttl]
    run([str(project / "bin" / "inventory"), "-addr", f":{args.port}", "-db", INVENTORY_DB[args.db], *extra], check=False)


def cmd_migrate_inventory(_):
    """Copia inventario y reservas de ms_monolith a ms_inventory (taller 02). Sobrescribe el destino."""
    run(["docker", "exec", "-i", "-e", "PGOPTIONS=-c client_min_messages=warning", "ms-postgres",
         "psql", "-v", "ON_ERROR_STOP=1", "-U", "ms_admin", "-d", "ms_inventory",
         "-f", "/seed/inventory/migrate-from-monolith.sql"])


def cmd_orders(args):
    """Compila (con los stubs gRPC generados del .proto) y arranca el servicio orders en primer plano."""
    project = LAB / "orders"
    env = java_env()
    run(["mvn", "-q", "-DskipTests", "package"], cwd=project, env=env)
    extra = [] if args.propagate_key else ["--ms.payments.propagate-key=false"]
    if args.events_mode:
        extra += [f"--ms.events.mode={args.events_mode}"]
    if args.events_chaos:
        extra += [f"--ms.events.chaos={args.events_chaos}"]
    if args.deadline is not None:
        extra += [f"--ms.inventory.deadline-ms={args.deadline}"]
    if args.threads:
        extra += [f"--server.tomcat.threads.max={args.threads}"]
    if args.readiness_includes_payments:
        extra += ["--management.endpoint.health.group.readiness.include=readinessState,db,payments"]
    if args.breaker_min_calls:
        extra += [f"--ms.payments.breaker.minimum-calls={args.breaker_min_calls}"]
    if args.bulkhead is not None:
        extra += [f"--ms.payments.bulkhead.max-concurrent={args.bulkhead}"]
    if args.no_trace_outbox:
        extra += ["--ms.events.propagate-trace=false"]
    if args.saga_retry_on_release:
        extra += ["--ms.saga.retry-on-release=true"]
    if args.saga:
        extra += [f"--ms.saga.mode={args.saga}"]
    if args.overview_no_inbox:
        extra += ["--ms.overview.inbox=false"]
    if args.saga_deadline is not None:
        extra += [f"--ms.saga.step-deadline-seconds={args.saga_deadline}"]
    agent = otel_java("orders", env)
    run(["java", *agent, "-jar", "target/ms-orders-1.0.0.jar", f"--server.port={args.port}", *extra], cwd=project, env=env, check=False)


def buf(*args):
    return run(["docker", "run", "--rm", "-v", f"{LAB}:/lab", "-w", "/lab/contrato/proto", "bufbuild/buf:1.73.0", *args],
               check=False).returncode


def cmd_buf(args):
    """buf en Docker sobre contrato/proto: lint, generate (stubs de Go) o breaking contra el último estado."""
    if args.action != "breaking":
        sys.exit(buf(args.action))
    base = LAB / "estados" if (LAB / "estados").is_dir() else LAB.parent
    states = sorted(p.name for p in base.iterdir() if (p / "contrato" / "proto").is_dir()) if base.is_dir() else []
    if not states:
        sys.exit("no hay ningún estado congelado con contrato/proto contra el que comparar")
    against = f"/lab/estados/{states[-1]}/contrato/proto"
    print(f"comparando contrato/proto con estados/{states[-1]}/contrato/proto")
    sys.exit(buf("breaking", "--against", against))


def cmd_envoy_retries(args):
    """Cambia qué reintenta Envoy en la ruta de orders y lo reinicia (taller 05)."""
    p = CONTRACT / "envoy" / "envoy.yaml"
    policy = {"safe": 'retry_on: "connect-failure,refused-stream", num_retries: 1',
              "5xx": 'retry_on: "5xx", num_retries: 2'}[args.mode]
    text = p.read_text()
    import re
    text = re.sub(r'retry_policy: \{ retry_on: "[^"]*", num_retries: \d+ \}', "retry_policy: { " + policy + " }", text)
    p.write_text(text)
    run(["docker", "restart", "ms-envoy"])
    print(f"Envoy reintenta en /api/v1/orders: {policy}")


def cmd_lock_stock(args):
    """Bloquea la fila de un SKU en ms_inventory durante N segundos (provocación del taller 04)."""
    sql = f"BEGIN; SELECT sku FROM inventory WHERE sku = '{args.sku}' FOR UPDATE; SELECT pg_sleep({args.seconds}); COMMIT;"
    cmd = ["docker", "exec", "-e", "PGPASSWORD=ms-lab-pass", "ms-postgres", "psql", "-q", "-U", "ms_inventory",
           "-d", "ms_inventory", "-c", sql]
    print(f"$ {' '.join(cmd[:10])} … FOR UPDATE; pg_sleep({args.seconds})")
    subprocess.Popen(cmd, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
    time.sleep(0.5)                                          # que el bloqueo esté tomado antes de volver
    print(f"{args.sku} bloqueado {args.seconds} s")


def cmd_bench(args):
    """Mide la misma reserva por HTTP y por gRPC contra inventory (taller 04). Reproducción local."""
    project = LAB / "tools" / "bench"
    run(["uv", "sync", "--quiet", "--python", "3.14"], cwd=project)
    extra = ["--flood", str(args.flood), "--concurrency", str(args.concurrency)] if args.flood else []
    run(["uv", "run", "--python", "3.14", "python", "bench.py", "--n", str(args.n), *extra], cwd=project, check=False)


def cmd_payments(args):
    """Instala dependencias con uv (Python 3.14) y arranca el servicio payments en primer plano."""
    project = LAB / "payments"
    run(["uv", "sync", "--quiet", "--python", "3.14"], cwd=project)
    env = dict(os.environ)
    if "kafka:" in (CONTRACT / "docker-compose.yml").read_text():   # taller 06: consumidor de orders.events
        env["PAYMENTS_KAFKA"] = "localhost:29092"
    if tracing_on():                                                 # taller 07
        env["PAYMENTS_OTLP"] = "localhost:24317"
        env["PAYMENTS_TRACE_KAFKA"] = "0" if args.no_trace_kafka else "1"
    run(["uv", "run", "--python", "3.14", "uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", str(args.port),
         "--log-level", "warning"], cwd=project, env=env, check=False)


def cmd_test(args):
    """Pruebas del taller 10 por servicio: unitarias, de contrato y de componente (Testcontainers).

    El orden importa: primero los consumidores, que ESCRIBEN los pactos en contrato/pacts; después los
    proveedores, que los VERIFICAN. payments se verifica contra el servicio en marcha (lab.py payments).
    """
    order = ["inventory", "orders", "payments"] if args.service == "all" else [args.service]
    for service in order:
        t0 = time.monotonic()
        if service == "inventory":        # unitarias, pacto de OrderPaid (consumidor) y Testcontainers
            rc = run(["go", "test", "-count=1", "./..."], cwd=LAB / "inventory", check=False).returncode
        elif service == "orders":         # unitarias, pacto con payments (consumidor), OrderPaid (proveedor)
            rc = run(["mvn", "-q", "test"], cwd=LAB / "orders", env=java_env(), check=False).returncode
        else:                             # payments como proveedor de orders, contra el servicio vivo
            rc = run(["uv", "run", "--python", "3.14", "--group", "dev", "python", "tests/verify_pacts.py"],
                     cwd=LAB / "payments", check=False).returncode
        print(f"--- {service}: {'OK' if rc == 0 else 'FALLA'} en {time.monotonic() - t0:.1f} s", flush=True)
        if rc != 0:
            sys.exit(rc)


def cmd_psp(args):
    """Arranca psp-simulator en primer plano."""
    run([sys.executable, str(LAB / "psp-simulator" / "psp_simulator.py"), "--port", str(args.port)], check=False)


def toxics_clear():
    status, _, body, _ = http("GET", f"{TOXIPROXY}/proxies")
    if status != 200:
        return
    for name, proxy in body.items():
        for toxic in proxy.get("toxics", []):
            http("DELETE", f"{TOXIPROXY}/proxies/{name}/toxics/{toxic['name']}")


def slow(proxy, latency, off):
    http("DELETE", f"{TOXIPROXY}/proxies/{proxy}/toxics/{proxy}_latency")
    if off:
        print(f"{proxy}: sin latencia añadida")
        return
    status, _, body, _ = http("POST", f"{TOXIPROXY}/proxies/{proxy}/toxics", {
        "name": f"{proxy}_latency", "type": "latency", "stream": "downstream",
        "attributes": {"latency": latency, "jitter": 0}})
    print(f"{proxy}: +{latency} ms en cada respuesta ({status})")


TOPICS = {"orders.events": 3, "orders.events.dlq": 1,
          # taller 08: los tres topics de la saga coreografiada, cada uno con su DLQ
          "orders.placed": 3, "orders.placed.dlq": 1, "inventory.reservations": 3,
          "inventory.reservations.dlq": 1, "payments.results": 3, "payments.results.dlq": 1}
KAFKA_SH = ["docker", "exec", "ms-kafka"]


def kafka_sh(script, *args, check=True, quiet=False):
    cmd = KAFKA_SH + [f"/opt/kafka/bin/{script}", "--bootstrap-server", "localhost:9092", *args]
    if quiet:
        return subprocess.run(cmd, check=check, capture_output=True, text=True)
    return run(cmd, check=check)


def recreate_topics():
    """Borra y recrea los topics del bloque: el log guarda la historia de TODAS las semillas anteriores,
    y una base resembrada con un log viejo no cuadra (lección del curso hexagonal)."""
    for topic, partitions in TOPICS.items():
        kafka_sh("kafka-topics.sh", "--delete", "--if-exists", "--topic", topic, check=False, quiet=True)
    time.sleep(1)
    for topic, partitions in TOPICS.items():
        for _ in range(10):
            r = kafka_sh("kafka-topics.sh", "--create", "--if-not-exists", "--topic", topic,
                         "--partitions", str(partitions), "--replication-factor", "1", check=False, quiet=True)
            if r.returncode == 0:
                break
            time.sleep(1)                                    # el borrado es asíncrono
    for group in ("inventory", "payments", "orders"):
        kafka_sh("kafka-consumer-groups.sh", "--delete", "--group", group, check=False, quiet=True)
    print(f"topics recreados: {', '.join(f'{t} ({p})' for t, p in TOPICS.items())}")


def cmd_kafka(args):
    """Kafka del bloque (taller 06): topics, grupos con su lag, o leer un topic de principio a fin."""
    if args.action == "topics":
        kafka_sh("kafka-topics.sh", "--describe", "--topic", "orders.events")
    elif args.action == "groups":
        kafka_sh("kafka-consumer-groups.sh", "--describe", "--all-groups", check=False)
    elif args.action == "tail":
        kafka_sh("kafka-console-consumer.sh", "--topic", args.topic, "--from-beginning", "--timeout-ms", "3000",
                 "--formatter-property", "print.key=true", "--formatter-property", "print.partition=true",
                 "--formatter-property", "print.offset=true", "--formatter-property", "print.headers=true",
                 check=False)
    elif args.action == "poison":
        # un mensaje que no es JSON, con clave, directo al topic: el consumidor tiene que sobrevivirlo
        cmd = KAFKA_SH + ["bash", "-c", "echo 'poison-0001:{esto no es json' | /opt/kafka/bin/kafka-console-producer.sh "
                          "--bootstrap-server localhost:9092 --topic orders.events --reader-property parse.key=true --reader-property key.separator=:"]
        run(cmd)


def cmd_psp_slow(args):
    """Mete (o quita) latencia en las respuestas del PSP, a través del proxy `psp` de Toxiproxy."""
    slow("psp", args.latency, args.off)


def cmd_slow(args):
    """Mete (o quita) latencia en las respuestas de una dependencia, a través de su proxy de Toxiproxy."""
    slow(args.proxy, args.latency, args.off)


def cmd_toxics(_):
    """Muestra los proxies de Toxiproxy y sus tóxicos activos."""
    status, _, body, _ = http("GET", f"{TOXIPROXY}/proxies")
    if status != 200:
        sys.exit("Toxiproxy no responde en :28474 (¿lab.py up?)")
    for name, p in body.items():
        tox = ", ".join(f"{t['type']}({t['attributes']})" for t in p.get("toxics", [])) or "ninguno"
        print(f"{name:10} {p['listen']:18} → {p['upstream']:28} tóxicos: {tox}")


def cmd_storm(args):
    """Crea N pedidos y los paga a la vez, mientras sondea el catálogo cada 250 ms.

    Es la provocación del taller 01: con el PSP lento, cada pago retiene una conexión del pool
    mientras espera, y el catálogo —que no paga nada— se queda sin conexión.
    """
    base = args.base_url
    token = login(base)
    auth = {"Authorization": f"Bearer {token}"}
    order_ids = []
    for _ in range(args.orders):
        status, _, body, _ = http("POST", f"{base}/api/v1/orders", {"lines": [{"sku": "SKU-002", "quantity": 1}]},
                                  {**auth, "Idempotency-Key": f"storm-{uuid.uuid4()}"})
        if status != 201:
            sys.exit(f"no se pudo crear el pedido: {status} {body}")
        order_ids.append(body["id"])
    print(f"{len(order_ids)} pedidos creados; pagando todos a la vez y sondeando el catálogo…")

    stop = threading.Event()
    probes = []

    def probe():
        while not stop.is_set():
            status, _, _, secs = http("GET", f"{base}{args.probe}", headers=auth, timeout=10)
            probes.append((time.strftime("%H:%M:%S"), status, secs))
            time.sleep(0.25)

    prober = threading.Thread(target=probe)
    prober.start()
    t0 = time.monotonic()
    with futures.ThreadPoolExecutor(max_workers=len(order_ids)) as pool:
        results = list(pool.map(lambda oid: http(
            "POST", f"{base}/api/v1/orders/{oid}/payment", None,
            {**auth, "Idempotency-Key": f"storm-pay-{oid}"}, timeout=60), order_ids))
    stop.set()
    prober.join()
    elapsed = time.monotonic() - t0

    by_status = {}
    for status, _, body, secs in results:
        key = f"{status} {body.get('orderStatus') or body.get('code') if isinstance(body, dict) else ''}".strip()
        by_status.setdefault(key, []).append(secs)
    print(f"\npagos ({len(results)} en {elapsed:.1f} s):")
    for key, secs in sorted(by_status.items()):
        print(f"  {key:28} ×{len(secs):3}   p50 {sorted(secs)[len(secs)//2]:.2f} s   máx {max(secs):.2f} s")
    print(f"\nsonda durante la tormenta (GET {args.probe}):")
    for ts, status, secs in probes:
        print(f"  {ts}  {status}  {secs:.2f} s")
    fails = sum(1 for _, s, _ in probes if s != 200)
    print(f"\nsonda: {len(probes) - fails}/{len(probes)} respuestas 200")


def otlp_value(v):
    """Un valor de atributo OTLP/JSON ({"stringValue": …}, {"intValue": "200"}…) como texto."""
    return next(iter(v.values()), "") if v else ""


def jaeger_traces(path):
    """Consulta la API v3 de Jaeger (respuestas en formato OTLP/JSON) y agrupa los spans por traza."""
    status, _, body, _ = http("GET", f"{JAEGER_URL}{path}")
    if status == 404:
        return {}
    if status != 200:
        sys.exit(f"Jaeger no responde en {JAEGER_URL} ({status}): ¿lab.py up?")
    traces = {}
    for rs in body["result"]["resourceSpans"]:
        service = {a["key"]: otlp_value(a["value"]) for a in rs["resource"]["attributes"]}["service.name"]
        for ss in rs.get("scopeSpans", []):
            for sp in ss.get("spans", []):
                sp["service"] = service
                sp["attrs"] = {a["key"]: otlp_value(a["value"]) for a in sp.get("attributes", [])}
                traces.setdefault(sp["traceId"], []).append(sp)
    return traces


KINDS = {1: "internal", 2: "server", 3: "client", 4: "producer", 5: "consumer"}
SHOWN = {"http.response.status_code": "http", "http.status_code": "http", "rpc.grpc.status_code": "grpc", "error.type": "error",
         "messaging.destination.partition.id": "partition", "messaging.kafka.offset": "offset",
         "messaging.kafka.message.offset": "offset", "ms.event.type": "event", "ms.event.verdict": "verdict"}


def print_trace(trace_id, spans, max_lines=80):
    """Imprime una traza como árbol: desfase desde el inicio, duración, servicio, tipo de span,
    operación y lo que dice cada span de sí mismo (código HTTP, estado gRPC, partición, offset).
    Recorrido iterativo y con tope de líneas: una saga en ciclo produce trazas de miles de niveles."""
    by_id = {sp["spanId"]: sp for sp in spans}
    children, roots = {}, []
    for sp in sorted(spans, key=lambda x: int(x["startTimeUnixNano"])):
        parent = sp.get("parentSpanId")
        if parent in by_id:
            children.setdefault(parent, []).append(sp)
        else:
            roots.append((sp, parent))
    t0 = min(int(sp["startTimeUnixNano"]) for sp in spans)
    t1 = max(int(sp["endTimeUnixNano"]) for sp in spans)
    print(f"traza {trace_id}  ·  {len(spans)} spans  ·  {(t1 - t0) / 1e9:.1f} s  ·  "
          f"{', '.join(sorted({sp['service'] for sp in spans}))}")
    printed, deepest = 0, 0
    for root, parent in roots:
        if parent and printed < max_lines:
            # normalmente, el span del cliente (lab.py), que no exporta a ningún collector
            print(f"  (padre {parent[:8]}… ausente en la traza)")
        stack = [(root, 0)]
        while stack:
            sp, depth = stack.pop()
            deepest = max(deepest, depth)
            if printed < max_lines:
                start, end = int(sp["startTimeUnixNano"]), int(sp["endTimeUnixNano"])
                extra = " ".join(f"{label}={sp['attrs'][k]}" for k, label in SHOWN.items() if k in sp["attrs"])
                if sp.get("status", {}).get("code") == 2:
                    extra += " ERROR"
                print(f"  {(start - t0) / 1e6:8.1f} ms {(end - start) / 1e6:8.1f} ms  {'  ' * min(depth, 30)}"
                      f"{sp['service']:<9} {KINDS.get(sp.get('kind'), '?'):<8} {sp['name']}  {extra}".rstrip())
                printed += 1
            stack.extend((c, depth + 1) for c in reversed(children.get(sp["spanId"], [])))
    if printed < len(spans):
        print(f"  … {len(spans) - printed} spans más sin imprimir (--max-lines); profundidad máxima {deepest}")


def cmd_buy(args):
    """Crea un pedido por Envoy y lo paga (o lo cancela), cada petición con su propio traceparent (taller 07).

    El cliente puede abrir la traza: Envoy continúa el traceparent que recibe en vez de crear uno. Así el
    id se conoce ANTES de preguntar a Jaeger, que es lo que hace un equipo de soporte con un error real.
    """
    base = "http://localhost:28080"
    auth = {"Authorization": f"Bearer {login(base)}"}

    def call(label, method, path, body=None, key=None):
        trace_id = uuid.uuid4().hex
        headers = {**auth, "traceparent": f"00-{trace_id}-{uuid.uuid4().hex[:16]}-01"}
        if key:
            headers["Idempotency-Key"] = key
        status, _, res, secs = http(method, f"{base}{path}", body, headers)
        state = (res.get("code") or res.get("status") or res.get("orderStatus")) if isinstance(res, dict) else res
        print(f"{label:8} {status} {state}  {secs * 1000:.0f} ms  trace={trace_id}")
        return res

    if args.v2:
        # taller 08: 202 + PENDING, y el cliente consulta hasta un estado final. Lo que ve es la saga.
        order = call("order v2", "POST", "/api/v2/orders", {"lines": [{"sku": args.sku, "quantity": args.qty}]}, f"buy-{uuid.uuid4()}")
        if not isinstance(order, dict) or "id" not in order:
            sys.exit(1)
        t0, seen = time.monotonic(), order["status"]
        print(f"  +{0:5.0f} ms  {seen}   ({order['id']})")
        while seen not in ("PAID", "PAYMENT_REJECTED", "CANCELLED") and time.monotonic() - t0 < args.wait:
            time.sleep(0.05)
            _, _, now, _ = http("GET", f"{base}/api/v2/orders/{order['id']}", headers=auth)
            if isinstance(now, dict) and now.get("status") != seen:
                seen = now["status"]
                print(f"  +{(time.monotonic() - t0) * 1000:5.0f} ms  {seen}")
        if seen not in ("PAID", "PAYMENT_REJECTED", "CANCELLED"):
            print(f"  sin estado final tras {args.wait:.0f} s: sigue en {seen}")
        return
    order = call("order", "POST", "/api/v1/orders", {"lines": [{"sku": args.sku, "quantity": args.qty}]}, f"buy-{uuid.uuid4()}")
    if not isinstance(order, dict) or "id" not in order:
        sys.exit(1)
    if args.then == "pay":
        call("payment", "POST", f"/api/v1/orders/{order['id']}/payment", key=f"buy-pay-{order['id']}")
    elif args.then == "cancel":
        call("cancel", "POST", f"/api/v1/orders/{order['id']}/cancel")


def query(database, user, sql):
    """Una consulta de solo lectura dentro de ms-postgres; devuelve las filas como texto (sin imprimir la orden)."""
    cmd = ["docker", "exec", "-e", "PGPASSWORD=ms-lab-pass", "ms-postgres", "psql", "-At", "-F", " ", "-U", user, "-d", database, "-c", sql]
    return subprocess.run(cmd, capture_output=True, text=True).stdout.strip() or "(nada)"


def cmd_saga_status(args):
    """Pregunta por un pedido a cada parte de la saga (taller 08): orders, inventory, payments y el PSP.

    En una saga coreografiada no hay un sitio donde preguntar "¿en qué estado está?": hay cuatro
    respuestas parciales, y reconciliarlas es trabajo de quien pregunta.
    """
    oid = args.order_id
    base = "http://localhost:28080"
    auth = {"Authorization": f"Bearer {login(base, 'ops@ms.local', 'ops-12345')}"}
    status, _, body, _ = http("GET", f"{base}/api/v2/orders/{oid}", headers=auth)
    print(f"orders     {body.get('status') if status == 200 else status}   (GET /api/v2/orders/{oid[:8]}…)")
    print("inventory  " + query("ms_inventory", "ms_inventory",
                                f"SELECT string_agg(sku || '×' || qty || ' ' || status, ', ') FROM holds WHERE reference = '{oid}'"))
    print("payments   " + query("ms_payments", "ms_payments",
                                f"SELECT string_agg(status || ' ' || coalesce(reference, '-'), ', ') FROM payments WHERE order_id = '{oid}'"))
    _, _, charges, _ = http("GET", f"{PSP_URL}/payments")
    mine = [c for c in (charges or {}).get("items", []) if c.get("orderId") == oid] if isinstance(charges, dict) else []
    print(f"psp        {', '.join(c['reference'] + ' ' + c['amount'] for c in mine) or 'sin cobro registrado'}")
    # taller 09: con orquestador, UNA fila responde "en qué paso, desde cuándo, cuántos intentos"
    saga = query("ms_orders", "ms_orders", f"""SELECT step || ' · intento ' || attempts || ' · en el paso desde hace '
        || round(extract(epoch FROM clock_timestamp() - step_started_at)) || ' s · plazo '
        || coalesce(round(extract(epoch FROM deadline_at - clock_timestamp())) || ' s', 'ninguno')
        || coalesce(' · ' || last_error, '') FROM order_sagas WHERE order_id = '{oid}'""")
    if saga != "(nada)":
        print(f"saga       {saga}")
        print(query("ms_orders", "ms_orders", f"""SELECT string_agg(to_char(at, 'HH24:MI:SS.MS') || '  ' || rpad(step, 18) || outcome,
            E'\n' ORDER BY id) FROM order_saga_log WHERE order_id = '{oid}'"""))


def cmd_overview(args):
    """"Mis pedidos con su estado de pago" (taller 11), por composición y por read model, lado a lado."""
    base = "http://localhost:28080"
    auth = {"Authorization": f"Bearer {login(base)}"}
    for source in ("composition", "projection"):
        status, hdrs, body, _ = http("GET", f"{base}/api/v2/orders/overview?source={source}", headers=auth)
        if status != 200:
            print(f"{source:<12} {status} {body}")
            continue
        timing = next((v for k, v in hdrs.items() if k.lower() == "server-timing"), "")
        flag = "  DEGRADED" if body["degraded"] else ""
        print(f"{source:<12} {len(body['items'])} pedidos · pagados {body['paidOrders']} · {body['paidAmount']} USD"
              f"   ({timing}){flag}")
        if args.items:
            for it in body["items"]:
                print(f"    {it['orderId'][:8]}  {it['status']:<17} pago {str(it['paymentStatus']):<10} {it['total']}")


def cmd_overview_replay(args):
    """Reprocesa el read model desde el offset 0 (taller 11). Con orders PARADO: el grupo tiene que estar vacío."""
    kafka_sh("kafka-consumer-groups.sh", "--group", "orders-overview", "--topic", "orders.events",
             "--reset-offsets", "--to-earliest", "--execute")
    if args.truncate:          # reconstruir de verdad: proyección e inbox, juntos (06/06, pregunta 11)
        psql("ms_orders", "ms_orders", sql="TRUNCATE order_overview, customer_overview; "
             "DELETE FROM processed_messages WHERE consumer = 'orders-overview'")
    print("orders-overview volverá a leer orders.events desde el principio al arrancar orders")


def cmd_follow(args):
    """Sigue un pedido por SSE (taller 11), como un EventSource: si el flujo se corta, reconecta con Last-Event-ID."""
    base = "http://localhost:28080"
    token = login(base)
    last_id, t0 = None, time.monotonic()
    for attempt in range(1, args.reconnects + 2):
        headers = {"Authorization": f"Bearer {token}", "Accept": "text/event-stream"}
        if last_id:
            headers["Last-Event-ID"] = last_id
        req = urllib.request.Request(f"{base}/api/v2/orders/{args.order_id}/events", headers=headers)
        print(f"+{time.monotonic() - t0:6.1f} s  conexión {attempt}" + (f" (Last-Event-ID: {last_id})" if last_id else ""))
        event, data, ev_id = None, None, None
        try:
            with urllib.request.urlopen(req, timeout=60) as res:
                for raw in res:
                    line = raw.decode().rstrip("\r\n")
                    if line.startswith(":"):
                        print(f"+{time.monotonic() - t0:6.1f} s  (comentario: {line[1:].strip()})")
                    elif line.startswith("id:"):
                        last_id = ev_id = line[3:].strip()
                    elif line.startswith("event:"):
                        event = line[6:].strip()
                    elif line.startswith("data:"):
                        data = line[5:].strip()
                    elif line == "" and event:
                        print(f"+{time.monotonic() - t0:6.1f} s  {event:<8} id={ev_id or '-':<5} {data}")
                        if event == "end":
                            return
                        event, data, ev_id = None, None, None
        except (urllib.error.URLError, TimeoutError, ConnectionError) as e:
            print(f"+{time.monotonic() - t0:6.1f} s  corte: {e}")
        print(f"+{time.monotonic() - t0:6.1f} s  el flujo terminó sin 'end'")
        time.sleep(1)                               # EventSource espera ≈ 3 s por defecto; aquí, 1
    sys.exit("demasiadas reconexiones")


def cmd_trace(args):
    """Trazas desde Jaeger, en texto (taller 07): una por su id, o las últimas de un servicio."""
    time.sleep(args.wait)                         # los spans llegan en lotes: unos segundos de margen
    if args.trace_id:
        traces = jaeger_traces(f"/api/v3/traces/{args.trace_id}")
        if not traces:
            sys.exit(f"la traza {args.trace_id} no está en Jaeger")
        for tid, spans in traces.items():
            print_trace(tid, spans, args.max_lines)
        return
    now = time.time()
    fmt = lambda t: time.strftime("%Y-%m-%dT%H:%M:%SZ", time.gmtime(t))
    q = (f"/api/v3/traces?query.service_name={args.service}&query.search_depth={args.limit}"
         f"&query.start_time_min={fmt(now - 3600)}&query.start_time_max={fmt(now + 60)}")
    if args.operation:
        q += "&query.operation_name=" + urllib.parse.quote(args.operation)
    traces = jaeger_traces(q)
    if not traces:
        sys.exit(f"sin trazas de {args.service} en la última hora")
    first = lambda tid: min(traces[tid], key=lambda sp: int(sp["startTimeUnixNano"]))
    ordered = sorted(traces, key=lambda tid: int(first(tid)["startTimeUnixNano"]), reverse=True)
    if args.list:
        for tid in ordered:
            root = first(tid)
            when = time.strftime("%H:%M:%S", time.localtime(int(root["startTimeUnixNano"]) / 1e9))
            print(f"{when}  {tid}  {len(traces[tid]):3} spans  {root['service']:<9} {root['name']}")
        return
    print_trace(ordered[0], traces[ordered[0]], args.max_lines)


# ------------------------------------------------------------------ CLI

def main():
    p = argparse.ArgumentParser(prog="lab.py", description=__doc__.splitlines()[0])
    p.add_argument("--estado", metavar="NN", help="usar laboratorio/estados/NN (el final del taller NN) en vez del último")
    sub = p.add_subparsers(dest="cmd", required=True)
    sub.add_parser("check", help=cmd_check.__doc__).set_defaults(fn=cmd_check)
    up = sub.add_parser("up", help=cmd_up.__doc__)
    up.add_argument("--mock", action="store_true", help="también el mock del contrato")
    up.set_defaults(fn=cmd_up)
    sub.add_parser("down", help=cmd_down.__doc__).set_defaults(fn=cmd_down)
    sd = sub.add_parser("seed", help=cmd_seed.__doc__)
    sd.add_argument("--kafka", action="store_true",
                    help="taller 06: recrear también los topics y borrar los grupos (con los consumidores parados)")
    sd.set_defaults(fn=cmd_seed)
    s = sub.add_parser("suite", help=cmd_suite.__doc__)
    s.add_argument("--base-url", default=MONOLITH_URL)
    s.add_argument("--dir", default="v1", help="carpeta de hurl/ (v1, v2…)")
    s.add_argument("--no-seed", action="store_true", help="no resembrar antes (contra el mock, por ejemplo)")
    s.set_defaults(fn=cmd_suite)
    sub.add_parser("mock", help=cmd_mock.__doc__).set_defaults(fn=cmd_mock)
    m = sub.add_parser("monolith", help=cmd_monolith.__doc__)
    m.add_argument("--port", type=int, default=28081)
    m.add_argument("--pool", type=int, help="tamaño del pool de conexiones (por defecto, el de application.yaml: 5)")
    m.add_argument("--inventory", choices=["local", "remote"], default="local",
                   help="local: tablas de ms_monolith · remote: el servicio inventory (taller 02)")
    m.add_argument("--inventory-timeout", type=int, help="timeout de lectura hacia inventory en ms (0 = sin timeout)")
    m.add_argument("--payments", choices=["local", "remote"], default="local",
                   help="local: el monolito llama al PSP · remote: el servicio payments (taller 03)")
    m.add_argument("--no-payment-key", action="store_true",
                   help="no propagar la Idempotency-Key a payments (provocación del taller 03)")
    m.set_defaults(fn=cmd_monolith)
    ts = sub.add_parser("test", help=cmd_test.__doc__.splitlines()[0])
    ts.add_argument("service", nargs="?", default="all", choices=["all", "inventory", "orders", "payments"])
    ts.set_defaults(fn=cmd_test)
    ps = sub.add_parser("psp", help=cmd_psp.__doc__)
    ps.add_argument("--port", type=int, default=28085)
    ps.set_defaults(fn=cmd_psp)
    slow = sub.add_parser("psp-slow", help=cmd_psp_slow.__doc__)
    slow.add_argument("--latency", type=int, default=1500, help="milisegundos por respuesta (1500 por defecto)")
    slow.add_argument("--off", action="store_true", help="quitar la latencia")
    slow.set_defaults(fn=cmd_psp_slow)
    sub.add_parser("toxics", help=cmd_toxics.__doc__).set_defaults(fn=cmd_toxics)
    sl = sub.add_parser("slow", help=cmd_slow.__doc__)
    sl.add_argument("proxy", choices=["psp", "inventory", "payments", "inventory-grpc"])
    sl.add_argument("--latency", type=int, default=1500)
    sl.add_argument("--off", action="store_true")
    sl.set_defaults(fn=cmd_slow)
    inv = sub.add_parser("inventory", help=cmd_inventory.__doc__)
    inv.add_argument("--db", choices=["own", "shared"], default="own",
                     help="own: ms_inventory · shared: la base del monolito (el atajo que se rompe)")
    inv.add_argument("--port", type=int, default=28083)
    inv.add_argument("--detach-deadline", action="store_true",
                     help="provocación del taller 04: el servidor gRPC ignora el deadline del cliente")
    inv.add_argument("--rps", type=float, help="taller 05: límite de tasa gRPC (peticiones/s)")
    inv.add_argument("--burst", type=int, default=20)
    inv.add_argument("--max-inflight", type=int, help="taller 05: peticiones gRPC en curso a la vez")
    inv.add_argument("--no-inbox", action="store_true", help="taller 06 (provocación): sin deduplicación de eventos")
    inv.add_argument("--chaos", default="none", choices=["none", "crash-after-effect"], help="taller 06")
    inv.add_argument("--hold-ttl", help="taller 09: caducidad de una retención sin confirmar (10m por defecto; 0 = nunca)")
    inv.add_argument("--no-trace-kafka", action="store_true",
                     help="taller 07 (provocación): no continuar la traza que llega en el mensaje")
    inv.set_defaults(fn=cmd_inventory)
    sub.add_parser("migrate-inventory", help=cmd_migrate_inventory.__doc__).set_defaults(fn=cmd_migrate_inventory)
    od = sub.add_parser("orders", help=cmd_orders.__doc__)
    od.add_argument("--port", type=int, default=28082)
    od.add_argument("--no-payment-key", dest="propagate_key", action="store_false")
    od.add_argument("--deadline", type=int, help="deadline gRPC hacia inventory en ms (800 por defecto)")
    od.add_argument("--threads", type=int, help="taller 05: hilos de Tomcat (200 por defecto)")
    od.add_argument("--events-mode", choices=["outbox", "direct"], help="taller 06: outbox (por defecto) o publicar tras el commit")
    od.add_argument("--events-chaos", choices=["none", "crash-before-publish"], help="taller 06")
    od.add_argument("--readiness-includes-payments", action="store_true",
                    help="taller 05 (provocación): la readiness de orders depende de payments")
    od.add_argument("--breaker-min-calls", type=int, help="taller 05: mínimo de llamadas para que el breaker decida")
    od.add_argument("--bulkhead", type=int, help="taller 05: pagos en curso a la vez (4 por defecto; 1000 ≈ sin bulkhead)")
    od.add_argument("--overview-no-inbox", action="store_true",
                    help="taller 11 (provocación): el proyector del read model sin deduplicar")
    od.add_argument("--saga", choices=["orchestration", "choreography"],
                    help="taller 09: quién lleva la saga v2 (orchestration por defecto; choreography = la de 06/08)")
    od.add_argument("--saga-deadline", type=int, help="taller 09: plazo de cada paso del orquestador en s (20; 0 = sin plazo)")
    od.add_argument("--saga-retry-on-release", action="store_true",
                    help="taller 08 (provocación): al liberarse el stock tras un rechazo, orders reintenta la compra")
    od.add_argument("--no-trace-outbox", action="store_true",
                    help="taller 07 (provocación): no guardar el contexto de la traza en la fila del outbox")
    od.set_defaults(fn=cmd_orders)
    bf = sub.add_parser("buf", help=cmd_buf.__doc__)
    bf.add_argument("action", choices=["lint", "generate", "breaking"])
    bf.set_defaults(fn=cmd_buf)
    kf = sub.add_parser("kafka", help=cmd_kafka.__doc__)
    kf.add_argument("action", choices=["topics", "groups", "tail", "poison"])
    kf.add_argument("--topic", default="orders.events")
    kf.set_defaults(fn=cmd_kafka)
    er = sub.add_parser("envoy-retries", help=cmd_envoy_retries.__doc__)
    er.add_argument("mode", choices=["safe", "5xx"])
    er.set_defaults(fn=cmd_envoy_retries)
    lk = sub.add_parser("lock-stock", help=cmd_lock_stock.__doc__)
    lk.add_argument("sku")
    lk.add_argument("--seconds", type=int, default=5)
    lk.set_defaults(fn=cmd_lock_stock)
    bn = sub.add_parser("bench", help=cmd_bench.__doc__)
    bn.add_argument("--n", type=int, default=300)
    bn.add_argument("--flood", type=int, help="taller 05: N retenciones gRPC concurrentes en vez de la medición")
    bn.add_argument("--concurrency", type=int, default=32)
    bn.set_defaults(fn=cmd_bench)
    pay = sub.add_parser("payments", help=cmd_payments.__doc__)
    pay.add_argument("--port", type=int, default=28084)
    pay.add_argument("--no-trace-kafka", action="store_true",
                     help="taller 07 (provocación): no continuar la traza que llega en el mensaje")
    pay.set_defaults(fn=cmd_payments)
    st = sub.add_parser("storm", help=cmd_storm.__doc__.splitlines()[0])
    st.add_argument("--orders", type=int, default=20)
    st.add_argument("--base-url", default=MONOLITH_URL)
    st.add_argument("--probe", default="/api/v1/products", help="ruta que se sondea durante la tormenta")
    st.set_defaults(fn=cmd_storm)
    by = sub.add_parser("buy", help=cmd_buy.__doc__.splitlines()[0])
    by.add_argument("--sku", default="SKU-002")
    by.add_argument("--qty", type=int, default=1)
    by.add_argument("--then", choices=["pay", "cancel", "nothing"], default="pay")
    by.add_argument("--v2", action="store_true", help="taller 08: alta por el contrato v2 y seguir la saga hasta un estado final")
    by.add_argument("--wait", type=float, default=10.0, help="con --v2, segundos máximos de espera")
    by.set_defaults(fn=cmd_buy)
    ov = sub.add_parser("overview", help=cmd_overview.__doc__)
    ov.add_argument("--items", action="store_true", help="también los pedidos, uno por línea")
    ov.set_defaults(fn=cmd_overview)
    orp = sub.add_parser("overview-replay", help=cmd_overview_replay.__doc__)
    orp.add_argument("--truncate", action="store_true", help="vaciar antes la proyección y su inbox (la reconstrucción correcta)")
    orp.set_defaults(fn=cmd_overview_replay)
    fl = sub.add_parser("follow", help=cmd_follow.__doc__)
    fl.add_argument("order_id")
    fl.add_argument("--reconnects", type=int, default=5)
    fl.set_defaults(fn=cmd_follow)
    ss = sub.add_parser("saga-status", help=cmd_saga_status.__doc__.splitlines()[0])
    ss.add_argument("order_id")
    ss.set_defaults(fn=cmd_saga_status)
    tr = sub.add_parser("trace", help=cmd_trace.__doc__)
    tr.add_argument("trace_id", nargs="?", help="id de la traza (32 hex); sin él, la última del servicio")
    tr.add_argument("--service", default="envoy")
    tr.add_argument("--operation", help="nombre exacto de la operación raíz, como lo muestra --list")
    tr.add_argument("--limit", type=int, default=20)
    tr.add_argument("--list", action="store_true", help="listar las trazas en vez de imprimir la última")
    tr.add_argument("--wait", type=float, default=3.0, help="segundos de espera antes de consultar")
    tr.add_argument("--max-lines", type=int, default=80, help="spans que se imprimen como mucho (80)")
    tr.set_defaults(fn=cmd_trace)
    args = p.parse_args()
    if args.estado:
        use_state(args.estado)
    args.fn(args)


if __name__ == "__main__":
    main()
