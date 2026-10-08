"""Ráfaga de ventas que piden reposición, con un comando a los T s; después cruza las dos bases:
ventas confirmadas en inventory contra órdenes creadas por evento en replenish."""
import json, subprocess, sys, threading, time, urllib.request
A = "http://api.localhost:8080"
K = ["kubectl", "--context", "kind-lab", "-n", "data", "exec", "postgres-0", "--", "psql", "-At", "-U"]
def q(db, sql):
    return subprocess.run(K + [db, "-d", db, "-c", sql], capture_output=True, text=True).stdout.strip()
def call(method, path, body, ctype="application/json"):
    req = urllib.request.Request(A + path, data=json.dumps(body).encode(), method=method, headers={"Content-Type": ctype})
    try:
        with urllib.request.urlopen(req, timeout=10) as r:
            return r.status
    except urllib.error.HTTPError as e:
        return e.code
    except Exception:
        return "sin respuesta"
threads, secs, at, cmd = int(sys.argv[1]), float(sys.argv[2]), float(sys.argv[3]), sys.argv[4]
store, sku = "DRO-021", "SKU-0002"
call("POST", f"/inventory/stock/{store}/{sku}/movements", {"type": "COUNT", "quantity": 100000, "reference": "conteo-f26"})
call("PATCH", f"/inventory/stock/{store}/{sku}", {"reorderThreshold": 1000000}, "application/merge-patch+json")
sale0 = int(q("inventory", "SELECT COALESCE(max(id),0) FROM sales"))
seq0 = int(q("replenish", "SELECT COALESCE(max(seq),0) FROM replenishment_orders"))
codes = {}; lock = threading.Lock(); t0 = time.time()
def worker():
    while time.time() - t0 < secs:
        c = call("POST", "/inventory/sales", {"store": store, "sku": sku, "quantity": 1})
        with lock:
            codes[c] = codes.get(c, 0) + 1
ts = [threading.Thread(target=worker) for _ in range(threads)]
[t.start() for t in ts]
time.sleep(at); print(f"+{time.time()-t0:.1f}s $ {cmd}", flush=True); subprocess.run(cmd, shell=True)
[t.join() for t in ts]
print("respuestas al cliente:", codes)
time.sleep(float(sys.argv[5]) if len(sys.argv) > 5 else 40)
sales = int(q("inventory", f"SELECT count(*) FROM sales WHERE id > {sale0} AND store = '{store}'"))
orders = int(q("replenish", f"SELECT count(*) FROM replenishment_orders WHERE seq > {seq0} AND destination_store = '{store}'"))
events = int(q("replenish", f"SELECT count(DISTINCT source_event_id) FROM replenishment_orders WHERE seq > {seq0} AND destination_store = '{store}'"))
print(f"ventas confirmadas en la base: {sales} · órdenes: {orders} · eventos distintos: {events} · "
      f"ventas sin orden: {sales - events} · órdenes repetidas: {orders - events}")
