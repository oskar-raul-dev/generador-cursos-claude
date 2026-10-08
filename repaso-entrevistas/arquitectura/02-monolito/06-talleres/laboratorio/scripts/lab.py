#!/usr/bin/env python3
"""lab.py — orquestador del bloque 06 · Talleres (corpus de monolito).

Python 3.11+ y solo biblioteca estándar: funciona igual en macOS, Linux y Windows. Cada orden se
explica en el taller que la introduce; `python3 lab.py -h` lista todas.

Nombres, puertos y credenciales: §12 de la guía de estilo.
"""
import argparse
import json
import os
import shutil
import subprocess
import sys
import threading
import time
import uuid
from concurrent.futures import ThreadPoolExecutor
import urllib.error
import urllib.request
from pathlib import Path

LAB = Path(__file__).resolve().parent.parent          # 06-talleres/laboratorio (estado del último taller)
CONTRACT = LAB / "contrato"
COMPOSE = ["docker", "compose", "-f", str(CONTRACT / "docker-compose.yml")]
TOXIPROXY = "http://localhost:38474"
PSP_URL = "http://localhost:38085"
LEGACY_URL = "http://localhost:38081"
JAVA_HOME_HINT = Path.home() / ".sdkman/candidates/java/25.0.4-tem"
USERS = {"ana": ("ana@mono.local", "ana-12345"), "ops": ("ops@mono.local", "ops-12345")}


def use_state(state):
    """Trabaja sobre laboratorio/estados/NN/: el código tal como quedó al terminar el taller NN."""
    global LAB, CONTRACT, COMPOSE
    root = LAB / "estados" / state
    if not root.is_dir():
        sys.exit(f"no existe el estado {state}")
    LAB, CONTRACT = root, root / "contrato"
    COMPOSE = ["docker", "compose", "-f", str(CONTRACT / "docker-compose.yml")]
    print(f"[estado {state}: {LAB}]", flush=True)


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


def psql(sql=None, sql_file=None, quiet=False):
    """Ejecuta SQL dentro de mono-postgres con el usuario del legado."""
    cmd = ["docker", "exec", "-i", "-e", "PGPASSWORD=mono-lab-pass", "-e", "PGOPTIONS=-c client_min_messages=warning",
           "mono-postgres", "psql", "-v", "ON_ERROR_STOP=1", "-U", "mono_legacy", "-d", "mono_legacy"]
    # la semilla se lee del estado elegido (--estado) y entra por stdin: el /seed montado en el
    # contenedor es el del compose que se levantó, que puede ser de otro estado (taller 07)
    stdin = (CONTRACT / "seed" / sql_file).read_text() if sql_file else None
    cmd += ["-q", "-f", "-"] if sql_file else ["-c", sql]
    if quiet:
        return subprocess.run(cmd, capture_output=True, text=True, input=stdin)
    return run(cmd, check=False, input=stdin, text=True)


def login(who):
    """Token de ana (cliente) u ops (operador). El legado responde 200 también si falla."""
    email, password = USERS[who]
    status, _, body, _ = http("POST", f"{LEGACY_URL}/api/v1/auth/login", {"email": email, "password": password})
    if status != 200 or not isinstance(body, dict) or "accessToken" not in body:
        sys.exit(f"login de {who} falló: {status} {body}")
    return body["accessToken"]


def java_env():
    env = dict(os.environ)
    if JAVA_HOME_HINT.exists():
        env["JAVA_HOME"] = str(JAVA_HOME_HINT)
        env["PATH"] = str(JAVA_HOME_HINT / "bin") + os.pathsep + env["PATH"]
    return env


def show(status, hdrs, body, elapsed):
    ctype = hdrs.get("Content-Type", "-")
    print(f"HTTP {status} · {ctype} · {elapsed * 1000:.0f} ms")
    if isinstance(body, dict) and isinstance(body.get("trace"), str):
        frames = body["trace"].splitlines()        # la traza de Java viaja en el cuerpo: se recorta al mostrarla
        body = {**body, "trace": frames[:4] + [f"… ({len(frames) - 4} líneas más de traza)"]}
    if isinstance(body, (dict, list)):
        text = json.dumps(body, indent=2, ensure_ascii=False)
    else:
        text = str(body)
    lines = text.splitlines()
    print("\n".join(lines[:60]) + (f"\n… ({len(lines) - 60} líneas más)" if len(lines) > 60 else ""))


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


def cmd_up(_):
    """Levanta el entorno común (PostgreSQL y Toxiproxy) y espera a que esté sano."""
    run(COMPOSE + ["up", "-d", "--wait"])


def cmd_down(_):
    """Apaga el entorno y borra sus volúmenes: nada sobrevive entre talleres."""
    run(COMPOSE + ["down", "-v", "--remove-orphans"])


def cmd_seed(_):
    """Vacía las tablas del legado, carga la semilla, vacía el registro del PSP y quita los tóxicos."""
    probe = psql("SELECT to_regclass('public.products') IS NOT NULL", quiet=True)
    if "t" not in probe.stdout.split():
        sys.exit("las tablas no existen todavía: las crea el legado al arrancar (ddl-auto hasta el taller 08, "
                 "Flyway desde el 09). "
                 "Arranca `lab.py legacy` una vez y repite `lab.py seed`.")
    r = psql(sql_file="seed.sql")
    if r.returncode != 0:
        sys.exit(r.returncode)
    status, _, _, _ = http("POST", f"{PSP_URL}/admin/reset", {})
    print(f"psp-simulator reset: {status or 'no está corriendo'}")
    toxics_clear()
    faults_clear()                                     # taller 08: ninguna restricción inyectada sobrevive
    print("semilla cargada")


def cmd_legacy(args):
    """Compila y arranca mono-legacy en primer plano (Ctrl+C para pararlo)."""
    project = LAB / "legacy"
    env = java_env()
    run(["mvn", "-q", "-DskipTests", "package"], cwd=project, env=env)
    jar = next((project / "target").glob("mono-legacy-*.jar"))
    extra = [f"--server.port={args.port}"]
    if args.daily_close_ms:
        extra.append(f"--legacy.daily-close.every-ms={args.daily_close_ms}")
    if args.inventory_mode:
        extra.append(f"--legacy.inventory.mode={args.inventory_mode}")          # taller 10
    if args.inventory_step:
        # taller 09: cada paso es una versión de la aplicación y trae sus migraciones
        folders = {"expand": ["migration"], "switch": ["migration", "switch"],
                   "contract": ["migration", "switch"], "done": ["migration", "switch", "contract"]}
        step = "contract" if args.inventory_step == "done" else args.inventory_step
        extra.append(f"--legacy.inventory.step={step}")
        extra.append("--spring.flyway.locations=" + ",".join(f"classpath:db/{f}" for f in folders[args.inventory_step]))
    for setting in args.set or []:
        extra.append(f"--{setting}")                  # taller 09: cualquier propiedad, clave=valor
    if args.sql:
        extra.append("--logging.level.org.hibernate.SQL=debug")     # taller 05: cada sentencia, DDL incluido
    run(["java", "-jar", str(jar), *extra], cwd=project, env=env, check=False)


def cmd_inventory(args):
    """Taller 10: compila y arranca mono-inventory en primer plano (--rename: la versión que renombra la columna)."""
    project = LAB / "inventory"
    env = java_env()
    run(["mvn", "-q", "-DskipTests", "package"], cwd=project, env=env)
    jar = next((project / "target").glob("mono-inventory-*.jar"))
    extra = []
    if args.rename:
        extra += ["--mono.inventory.stock-column=on_hand",
                  "--spring.flyway.locations=classpath:db/inventory,classpath:db/inventory-rename"]
    run(["java", "-jar", str(jar), *extra], cwd=project, env=env, check=False)


def cmd_proxy(args):
    """Taller 10: latencia (--latency ms), corte (--down) o nada (--off) en un proxy de Toxiproxy."""
    http("DELETE", f"{TOXIPROXY}/proxies/{args.name}/toxics/{args.name}_latency")
    http("POST", f"{TOXIPROXY}/proxies/{args.name}", {"enabled": not args.down})
    if args.latency:
        http("POST", f"{TOXIPROXY}/proxies/{args.name}/toxics", {
            "name": f"{args.name}_latency", "type": "latency", "stream": "downstream",
            "attributes": {"latency": args.latency, "jitter": 0}})
    state = "cortado" if args.down else (f"+{args.latency} ms en cada respuesta" if args.latency else "sin tóxicos")
    print(f"{args.name}: {state}")


def cmd_psp(args):
    """Arranca psp-simulator en primer plano."""
    run([sys.executable, str(LAB / "psp-simulator" / "psp_simulator.py"), "--port", str(args.port)], check=False)


def toxics_clear():
    status, _, body, _ = http("GET", f"{TOXIPROXY}/proxies")
    if status != 200:
        return
    for name, proxy in body.items():
        if not proxy.get("enabled", True):
            http("POST", f"{TOXIPROXY}/proxies/{name}", {"enabled": True})      # taller 10: proxies cortados
        for toxic in proxy.get("toxics", []):
            http("DELETE", f"{TOXIPROXY}/proxies/{name}/toxics/{toxic['name']}")


def cmd_psp_slow(args):
    """Mete (o quita) latencia en las respuestas del PSP, a través del proxy `psp` de Toxiproxy."""
    http("DELETE", f"{TOXIPROXY}/proxies/psp/toxics/psp_latency")
    if args.off:
        print("psp: sin latencia añadida")
        return
    status, _, _, _ = http("POST", f"{TOXIPROXY}/proxies/psp/toxics", {
        "name": "psp_latency", "type": "latency", "stream": "downstream",
        "attributes": {"latency": args.latency, "jitter": 0}})
    print(f"psp: +{args.latency} ms en cada respuesta ({status})")


def cmd_api(args):
    """Una petición al legado como `ana` (cliente), `ops` (operador) o `nadie`; imprime estado y cuerpo."""
    token = args.token or (None if args.as_ == "nadie" else login(args.as_))
    headers = {"Authorization": f"Bearer {token}"} if token else {}
    if args.key:
        headers["Idempotency-Key"] = args.key            # taller 07: crear y pagar la exigen
    body = json.loads(args.body) if args.body else None
    show(*http(args.method.upper(), f"http://localhost:{args.port}{args.path}", body, headers))


def cmd_token(args):
    """Taller 08: imprime un token de acceso, para reusarlo con `api --token` en otra instancia."""
    print(login(args.as_))


def cmd_sql(args):
    """Ejecuta una consulta en mono_legacy (arqueología: quién escribe qué)."""
    psql(args.query)


def cmd_test(_):
    """Pruebas del legado; desde el taller 05, contra PostgreSQL en Testcontainers (necesita Docker)."""
    print("$ mvn test   (se muestran solo el resumen y los fallos)", flush=True)
    proc = subprocess.Popen(["mvn", "test"], cwd=LAB / "legacy", env=java_env(),
                            stdout=subprocess.PIPE, stderr=subprocess.STDOUT, text=True)
    keep = ("Tests run:", "FAIL", "expected:", "BUILD", "Running dev.")
    for line in proc.stdout:
        if any(k in line for k in keep):
            print(line.rstrip().replace("[INFO] ", "").replace("[ERROR] ", ""), flush=True)
    sys.exit(proc.wait())


def cmd_suite(args):
    """Corre una colección hurl contra el legado (por defecto, hurl/v1 desde el taller 04). Siembra antes."""
    if not args.no_seed:
        cmd_seed(args)
    folder = CONTRACT / "hurl" / args.dir
    files = sorted(p.name for p in folder.glob("*.hurl"))
    if not files:
        sys.exit(f"no hay archivos .hurl en contrato/hurl/{args.dir}")
    # se corre desde la carpeta de la suite para que la salida muestre nombres cortos
    extra = ["--continue-on-error"] if args.all_errors else []
    rc = run(["hurl", "--test", "--jobs", "1", *extra, "--variable", f"base_url={args.base_url}", *files],
             cwd=folder, check=False).returncode
    sys.exit(rc)


def cmd_contract(args):
    """Taller 04: corre hurl/v1 a través de Prism, que valida cada respuesta contra openapi.yaml."""
    run(COMPOSE + ["--profile", "contract", "up", "-d", "prism"])
    for _ in range(60):
        if http("GET", "http://localhost:34010/health")[0] == 200:
            break
        time.sleep(1)
    else:
        sys.exit("prism no respondió en :34010")
    args.base_url, args.all_errors = "http://localhost:34010", False
    try:
        cmd_suite(args)
    except SystemExit as e:
        rc = e.code
    else:
        rc = 0
    logs = subprocess.run(["docker", "logs", "mono-prism"], capture_output=True, text=True)
    # las violaciones de la petición son a propósito (la suite manda cuerpos inválidos); las de la
    # respuesta son las que importan: el legado dice algo que el contrato no declara
    bad = [l for l in (logs.stdout + logs.stderr).splitlines() if "Violation: response" in l]
    print(f"violaciones de respuesta según prism: {len(bad)}")
    for line in bad:
        print("  " + line.split("Violation: ", 1)[1])
    run(COMPOSE + ["--profile", "contract", "rm", "-sf", "prism"])
    sys.exit(rc or (1 if bad else 0))


# ------------------------------------------------------------------ taller 07: carga concurrente

def stock_of(sku):
    # taller 09: el stock vive en inventory si la tabla existe
    table = "inventory" if "t" in psql("SELECT to_regclass('inventory') IS NOT NULL", quiet=True).stdout.split() else "products"
    out = psql(f"SELECT stock FROM {table} WHERE sku = '{sku}'", quiet=True).stdout.split()
    return next((x for x in out if x.lstrip("-").isdigit()), "?")


def storm_orders(args):
    """N clientes compran a la vez una unidad del mismo SKU; cuenta los confirmados y lee el stock."""
    auth = {"Authorization": f"Bearer {login('ana')}"}
    ports = [int(p) for p in args.ports.split(",")]
    print(f"stock de {args.sku} antes: {stock_of(args.sku)}")
    start = threading.Barrier(args.n)

    def buy(i):
        start.wait()                                   # todos salen a la vez
        headers = {**auth, "Idempotency-Key": f"storm-order-{uuid.uuid4()}"}
        port = ports[i % len(ports)]                   # taller 09: repartidos entre instancias
        return http("POST", f"http://localhost:{port}/api/v1/orders", {"lines": [{"sku": args.sku, "quantity": 1}]},
                    headers)[0]

    with ThreadPoolExecutor(args.n) as pool:
        codes = list(pool.map(buy, range(args.n)))
    summary = {c: codes.count(c) for c in sorted(set(codes))}
    print(f"{args.n} pedidos concurrentes de 1 × {args.sku}: " + ", ".join(f"HTTP {c} × {n}" for c, n in summary.items()))
    print(f"stock de {args.sku} después: {stock_of(args.sku)}")


def storm_payments(args):
    """Crea N pedidos baratos, los paga a la vez y, mientras, sondea el catálogo cada 200 ms."""
    auth = {"Authorization": f"Bearer {login('ana')}"}
    ids = []
    for _ in range(args.n):
        status, _, body, _ = http("POST", f"{LEGACY_URL}/api/v1/orders", {"lines": [{"sku": "SKU-002", "quantity": 1}]},
                                  {**auth, "Idempotency-Key": f"storm-setup-{uuid.uuid4()}"})
        if status not in (200, 201):
            sys.exit(f"no se pudo crear el pedido: {status} {body}")
        ids.append(body["id"])
    done = threading.Event()
    probes = []

    def probe():                                       # un cliente que solo mira el catálogo
        while not done.is_set():
            status, _, _, elapsed = http("GET", f"{LEGACY_URL}/api/v1/products", headers=auth, timeout=10)
            probes.append((status, elapsed))
            time.sleep(0.2)

    def pay(order_id):
        headers = {**auth, "Idempotency-Key": f"storm-pay-{uuid.uuid4()}"}
        status, _, body, elapsed = http("POST", f"{LEGACY_URL}/api/v1/orders/{order_id}/payment", None, headers, timeout=30)
        return status, (body or {}).get("orderStatus") if isinstance(body, dict) else None, elapsed

    watcher = threading.Thread(target=probe)
    watcher.start()
    t0 = time.monotonic()
    with ThreadPoolExecutor(args.n) as pool:
        results = list(pool.map(pay, ids))
    done.set()
    watcher.join()
    by = {}
    for status, order_status, _ in results:
        by[(status, order_status)] = by.get((status, order_status), 0) + 1
    print(f"{args.n} pagos concurrentes en {time.monotonic() - t0:.1f} s: " +
          ", ".join(f"HTTP {s} {o or ''} × {n}".replace("  ", " ") for (s, o), n in sorted(by.items(), key=str)))
    ok = [e for s, e in probes if s == 200]
    bad = [s for s, _ in probes if s != 200]
    print(f"catálogo durante los pagos: {len(probes)} lecturas, {len(ok)} con 200, {len(bad)} fallidas {sorted(set(bad)) or ''}"
          f"; la más lenta, {max(e for _, e in probes) * 1000:.0f} ms")


def storm_double_pay(args):
    """Un pedido, dos pagos a la vez (el doble clic); cuenta los cobros que registró el proveedor."""
    auth = {"Authorization": f"Bearer {login('ana')}"}
    status, _, order, _ = http("POST", f"{LEGACY_URL}/api/v1/orders", {"lines": [{"sku": "SKU-001", "quantity": 1}]},
                               {**auth, "Idempotency-Key": f"storm-double-{uuid.uuid4()}"})
    if status not in (200, 201):
        sys.exit(f"no se pudo crear el pedido: {status} {order}")
    key = f"double-click-{uuid.uuid4()}" if args.same_key else None
    start = threading.Barrier(2)

    def pay(_):
        start.wait()
        headers = {**auth, "Idempotency-Key": key or f"double-{uuid.uuid4()}"}
        s, h, b, _ = http("POST", f"{LEGACY_URL}/api/v1/orders/{order['id']}/payment", None, headers, timeout=30)
        return s, h.get("Idempotent-Replay"), (b or {}).get("orderStatus") if isinstance(b, dict) else b

    with ThreadPoolExecutor(2) as pool:
        for s, replay, order_status in pool.map(pay, range(2)):
            print(f"pago: HTTP {s} orderStatus={order_status}" + (f" Idempotent-Replay={replay}" if replay else ""))
    _, _, charges, _ = http("GET", f"{PSP_URL}/payments")
    mine = [c for c in charges["items"] if c["orderId"] == order["id"]]
    print(f"cobros del proveedor para el pedido {order['id'][:8]}: {len(mine)}")
    for c in mine:
        print(f"  {c['reference']} {c['amount']} key={c['idempotencyKey']}")


def cmd_bench(args):
    """Taller 10: latencia de N pedidos seguidos de un cable (reproducción local, un nodo, sin red real)."""
    auth = {"Authorization": f"Bearer {login('ana')}"}
    times = []
    for _ in range(args.n):
        status, _, _, elapsed = http("POST", f"http://localhost:{args.port}/api/v1/orders",
                                     {"lines": [{"sku": "SKU-002", "quantity": 1}]},
                                     {**auth, "Idempotency-Key": f"bench-{uuid.uuid4()}"})
        if status != 201:
            sys.exit(f"pedido fallido: HTTP {status}")
        times.append(elapsed * 1000)
    times.sort()
    print(f"{args.n} pedidos: mediana {times[len(times) // 2]:.0f} ms, p95 {times[int(len(times) * 0.95) - 1]:.0f} ms, "
          f"máximo {times[-1]:.0f} ms")


def cmd_psp_charges(_):
    """Taller 07: los cobros que registró el proveedor (lo que vería el cliente en su extracto)."""
    status, _, body, _ = http("GET", f"{PSP_URL}/payments")
    if status != 200:
        sys.exit(f"psp-simulator no responde: {status}")
    print(f"{len(body['items'])} cobros")
    for c in body["items"]:
        print(f"  {c['reference']} pedido {c['orderId'][:8]} {c['amount']} key={c['idempotencyKey']}")


# ------------------------------------------------------------------ taller 08: fallos y dos instancias

FAULTS = {
    # la escritura de notificaciones falla (cualquier fila nueva viola la restricción)
    "notifications": ["ALTER TABLE notifications ADD CONSTRAINT lab_fault CHECK (false) NOT VALID"],
    # la cancelación falla AL CONFIRMAR: un trigger diferido rechaza el COMMIT si un pedido pasó a
    # CANCELLED. Todo lo anterior al COMMIT —incluido publicar un evento— ya ocurrió.
    "orders": ["CREATE OR REPLACE FUNCTION lab_fault_fn() RETURNS trigger AS $$ BEGIN "
               "RAISE EXCEPTION 'lab_fault: commit rejected'; END $$ LANGUAGE plpgsql",
               "CREATE CONSTRAINT TRIGGER lab_fault AFTER UPDATE ON orders DEFERRABLE INITIALLY DEFERRED "
               "FOR EACH ROW WHEN (NEW.status = 'CANCELLED') EXECUTE FUNCTION lab_fault_fn()"],
}
FAULTS_OFF = {
    "notifications": ["ALTER TABLE IF EXISTS notifications DROP CONSTRAINT IF EXISTS lab_fault"],
    "orders": ["DROP TRIGGER IF EXISTS lab_fault ON orders", "DROP FUNCTION IF EXISTS lab_fault_fn()"],
}


def faults_clear():
    for statements in FAULTS_OFF.values():
        for sql in statements:
            psql(sql, quiet=True)


def cmd_fault(args):
    """Taller 08: hace fallar las escrituras de notifications o el COMMIT de una cancelación (--off lo quita)."""
    for sql in FAULTS_OFF[args.table]:
        psql(sql, quiet=True)
    if args.off:
        print(f"{args.table}: sin fallo inyectado")
        return
    for sql in FAULTS[args.table]:
        r = psql(sql, quiet=True)
        if r.returncode != 0:
            sys.exit(f"{args.table}: {r.stderr.strip()}")
    print(f"{args.table}: fallo inyectado")


def cmd_cancel_probe(args):
    """Taller 08: crea un pedido, lo cancela y cuenta en la base su estado y sus notificaciones."""
    base = f"http://localhost:{args.port}"
    auth = {"Authorization": f"Bearer {login('ana')}"}
    status, _, order, _ = http("POST", f"{base}/api/v1/orders", {"lines": [{"sku": "SKU-002", "quantity": 1}]},
                               {**auth, "Idempotency-Key": f"probe-{uuid.uuid4()}"})
    if status not in (200, 201):
        sys.exit(f"no se pudo crear el pedido: {status} {order}")
    oid = order["id"]
    status, _, body, _ = http("POST", f"{base}/api/v1/orders/{oid}/cancel", None, auth)
    detail = body.get("status") if isinstance(body, dict) and "status" in body and status == 200 else (body or {}).get("code")
    print(f"cancelar {oid[:8]}: HTTP {status} {detail}")
    time.sleep(args.wait)
    row = psql(f"SELECT o.status, (SELECT count(*) FROM notifications n WHERE n.order_id = o.id) "
               f"FROM orders o WHERE o.id = '{oid}'", quiet=True).stdout.split("\n")[2].split("|")
    print(f"en la base, {args.wait} s después: pedido {row[0].strip()}, notificaciones {row[1].strip()}")


def cmd_storm(args):
    """Taller 07: carga concurrente contra el legado (orders, payments o double-pay)."""
    {"orders": storm_orders, "payments": storm_payments, "double-pay": storm_double_pay}[args.kind](args)


def npm(*args, **kw):
    npm_bin = shutil.which("npm") or sys.exit("npm no encontrado (Node 24 LTS)")
    return run([npm_bin, *args], cwd=LAB / "frontend", **kw)


def cmd_frontend(_):
    """Taller 02: instala (la primera vez) y arranca el frontend React en :35173 (Ctrl+C para pararlo)."""
    if not (LAB / "frontend" / "node_modules").is_dir():
        npm("ci", "--no-fund", "--no-audit")
    npm("run", "dev", check=False)


def cmd_front_smoke(_):
    """Taller 02: recorre en Node los caminos de la interfaz con el mismo cliente y los mismos textos."""
    if not (LAB / "frontend" / "node_modules").is_dir():
        npm("ci", "--no-fund", "--no-audit")
    rc = npm("run", "--silent", "smoke", check=False).returncode
    sys.exit(rc)


def cmd_trace(_):
    """Taller 02: provoca el 500 con la traza de Java (un SKU que no existe)."""
    token = login("ana")
    show(*http("POST", f"{LEGACY_URL}/api/v1/orders", {"lines": [{"sku": "SKU-999", "quantity": 1}]},
               {"Authorization": f"Bearer {token}"}))


def cmd_lazy(args):
    """Taller 02: crea un pedido, espera al cierre diario y lo pide otra vez (LazyInitializationException)."""
    token = login("ana")
    auth = {"Authorization": f"Bearer {token}"}
    status, _, order, _ = http("POST", f"{LEGACY_URL}/api/v1/orders", {"lines": [{"sku": "SKU-002", "quantity": 1}]},
                               {**auth, "Idempotency-Key": f"lazy-{uuid.uuid4()}"})   # la clave, desde el taller 07
    if status not in (200, 201) or not isinstance(order, dict) or "id" not in order:   # 201 desde el taller 04
        sys.exit(f"no se pudo crear el pedido: {status} {order}")
    oid = order["id"]
    print(f"pedido {oid} creado; GET antes del cierre diario:")
    s, h, b, e = http("GET", f"{LEGACY_URL}/api/v1/orders/{oid}", headers=auth)
    print(f"HTTP {s} · {h.get('Content-Type', '-')} · status={b.get('status') if isinstance(b, dict) else '?'}")
    print(f"esperando al cierre diario (hasta {args.wait} s: busca una fila nueva en batch_runs)…", flush=True)
    before = psql("SELECT coalesce(max(id), 0) FROM batch_runs", quiet=True).stdout.split()
    last = next((x for x in before if x.isdigit()), "0")
    deadline = time.monotonic() + args.wait
    while time.monotonic() < deadline:
        now = psql("SELECT coalesce(max(id), 0) FROM batch_runs", quiet=True).stdout.split()
        if next((x for x in now if x.isdigit()), "0") != last:
            break
        time.sleep(1)
    else:
        sys.exit("el cierre diario no corrió en el tiempo de espera")
    print("GET después del cierre diario:")
    show(*http("GET", f"{LEGACY_URL}/api/v1/orders/{oid}", headers=auth))


def main():
    parser = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    parser.add_argument("--estado", help="usar laboratorio/estados/NN en lugar del último estado")
    sub = parser.add_subparsers(dest="cmd", required=True)
    sub.add_parser("check", help=cmd_check.__doc__).set_defaults(fn=cmd_check)
    sub.add_parser("up", help=cmd_up.__doc__).set_defaults(fn=cmd_up)
    sub.add_parser("down", help=cmd_down.__doc__).set_defaults(fn=cmd_down)
    sub.add_parser("seed", help=cmd_seed.__doc__).set_defaults(fn=cmd_seed)
    lg = sub.add_parser("legacy", help=cmd_legacy.__doc__)
    lg.add_argument("--port", type=int, default=38081)
    lg.add_argument("--daily-close-ms", type=int, help="cada cuánto corre el cierre diario (por defecto, 30000)")
    lg.add_argument("--sql", action="store_true", help="registrar cada sentencia SQL que envía Hibernate")
    lg.add_argument("--set", action="append", metavar="CLAVE=VALOR", help="propiedad de Spring para este arranque")
    lg.add_argument("--inventory-mode", choices=["local", "remote-naive", "remote"],
                    help="taller 10: dónde vive el stock (por defecto, local)")
    lg.add_argument("--inventory-step", choices=["expand", "switch", "contract", "done"],
                    help="taller 09: paso de la migración products → inventory (por defecto, done)")
    lg.set_defaults(fn=cmd_legacy)
    iv = sub.add_parser("inventory", help=cmd_inventory.__doc__)
    iv.add_argument("--rename", action="store_true", help="la versión que renombra inventory.stock a on_hand")
    iv.set_defaults(fn=cmd_inventory)
    px = sub.add_parser("proxy", help=cmd_proxy.__doc__)
    px.add_argument("name", choices=["psp", "inventory"])
    px.add_argument("--latency", type=int)
    px.add_argument("--down", action="store_true")
    px.add_argument("--off", action="store_true")
    px.set_defaults(fn=cmd_proxy)
    ps = sub.add_parser("psp", help=cmd_psp.__doc__)
    ps.add_argument("--port", type=int, default=38085)
    ps.set_defaults(fn=cmd_psp)
    sl = sub.add_parser("psp-slow", help=cmd_psp_slow.__doc__)
    sl.add_argument("--latency", type=int, default=1500, help="milisegundos añadidos a cada respuesta")
    sl.add_argument("--off", action="store_true")
    sl.set_defaults(fn=cmd_psp_slow)
    ap = sub.add_parser("api", help=cmd_api.__doc__)
    ap.add_argument("method")
    ap.add_argument("path")
    ap.add_argument("body", nargs="?")
    ap.add_argument("--as", dest="as_", choices=["ana", "ops", "nadie"], default="ana")
    ap.add_argument("--key", help="Idempotency-Key de la petición (taller 07)")
    ap.add_argument("--port", type=int, default=38081, help="instancia del legado (taller 08: 38083 es la segunda)")
    ap.add_argument("--token", help="usar este token en lugar de hacer login (taller 08)")
    ap.set_defaults(fn=cmd_api)
    tk = sub.add_parser("token", help=cmd_token.__doc__)
    tk.add_argument("--as", dest="as_", choices=["ana", "ops"], default="ana")
    tk.set_defaults(fn=cmd_token)
    sq = sub.add_parser("sql", help=cmd_sql.__doc__)
    sq.add_argument("query")
    sq.set_defaults(fn=cmd_sql)
    sub.add_parser("test", help=cmd_test.__doc__).set_defaults(fn=cmd_test)
    su = sub.add_parser("suite", help=cmd_suite.__doc__)
    su.add_argument("--dir", default="v1", help="legacy (taller 03), v1 (desde el 04), hex o ms (copias, 04)")
    su.add_argument("--all-errors", action="store_true", help="no parar un archivo en el primer fallo")
    su.add_argument("--base-url", default=LEGACY_URL)
    su.add_argument("--no-seed", action="store_true")
    su.set_defaults(fn=cmd_suite)
    st = sub.add_parser("storm", help=cmd_storm.__doc__)
    st.add_argument("kind", choices=["orders", "payments", "double-pay"])
    st.add_argument("--n", type=int, default=20, help="peticiones concurrentes")
    st.add_argument("--sku", default="SKU-003")
    st.add_argument("--same-key", action="store_true", help="double-pay: los dos pagos con la misma clave")
    st.add_argument("--ports", default="38081", help="orders: instancias entre las que repartir, p. ej. 38081,38083")
    st.set_defaults(fn=cmd_storm)
    sub.add_parser("psp-charges", help=cmd_psp_charges.__doc__).set_defaults(fn=cmd_psp_charges)
    bn = sub.add_parser("bench", help=cmd_bench.__doc__)
    bn.add_argument("--n", type=int, default=50)
    bn.add_argument("--port", type=int, default=38081)
    bn.set_defaults(fn=cmd_bench)
    fa = sub.add_parser("fault", help=cmd_fault.__doc__)
    fa.add_argument("table", choices=sorted(FAULTS))
    fa.add_argument("--off", action="store_true")
    fa.set_defaults(fn=cmd_fault)
    cp = sub.add_parser("cancel-probe", help=cmd_cancel_probe.__doc__)
    cp.add_argument("--port", type=int, default=38081)
    cp.add_argument("--wait", type=float, default=2.0, help="segundos antes de mirar la base")
    cp.set_defaults(fn=cmd_cancel_probe)
    ct = sub.add_parser("contract", help=cmd_contract.__doc__)
    ct.add_argument("--dir", default="v1")
    ct.add_argument("--no-seed", action="store_true")
    ct.set_defaults(fn=cmd_contract)
    sub.add_parser("frontend", help=cmd_frontend.__doc__).set_defaults(fn=cmd_frontend)
    sub.add_parser("front-smoke", help=cmd_front_smoke.__doc__).set_defaults(fn=cmd_front_smoke)
    sub.add_parser("trace", help=cmd_trace.__doc__).set_defaults(fn=cmd_trace)
    lz = sub.add_parser("lazy", help=cmd_lazy.__doc__)
    lz.add_argument("--wait", type=int, default=40)
    lz.set_defaults(fn=cmd_lazy)
    args = parser.parse_args()
    if args.estado:
        use_state(args.estado)
    args.fn(args)


if __name__ == "__main__":
    main()
