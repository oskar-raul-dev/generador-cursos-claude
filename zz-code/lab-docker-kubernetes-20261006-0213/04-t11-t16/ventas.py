"""N ventas que dejan la existencia bajo el umbral, a una por segundo; a los T s corre un comando (el reinicio).
Al final cuenta las órdenes nuevas de replenish para esa droguería y cuántas tienen sourceEventId distinto."""
import json, subprocess, sys, time, urllib.request
A = "http://api.localhost:8080"
def call(method, path, body=None, ctype="application/json"):
    data = json.dumps(body).encode() if body is not None else None
    req = urllib.request.Request(A + path, data=data, method=method, headers={"Content-Type": ctype})
    try:
        with urllib.request.urlopen(req, timeout=10) as r:
            return r.status, json.load(r)
    except urllib.error.HTTPError as e:
        return e.code, json.load(e)
n, at, cmd, wait = int(sys.argv[1]), float(sys.argv[2]), sys.argv[3], float(sys.argv[4]) if len(sys.argv) > 4 else 15
store, sku = "DRO-021", "SKU-0002"
call("POST", f"/inventory/stock/{store}/{sku}/movements", {"type": "COUNT", "quantity": 500, "reference": "conteo-f25"})
call("PATCH", f"/inventory/stock/{store}/{sku}", {"reorderThreshold": 1000}, "application/merge-patch+json")
before = {o["id"] for o in call("GET", "/replenish/replenishment-orders")[1]}
t0 = time.time(); fired = False; statuses = []
for i in range(n):
    if not fired and time.time() - t0 >= at and cmd != "-":
        print(f"+{time.time()-t0:4.1f}s $ {cmd}", flush=True); subprocess.Popen(cmd, shell=True); fired = True
    st, _ = call("POST", "/inventory/sales", {"store": store, "sku": sku, "quantity": 1})
    statuses.append(st)
    time.sleep(max(0, (i + 1) - (time.time() - t0)))
print(f"ventas: {len(statuses)} · respuestas: { {s: statuses.count(s) for s in set(statuses)} }")
time.sleep(wait)
orders = [o for o in call("GET", "/replenish/replenishment-orders")[1] if o["id"] not in before and o["destinationStore"] == store]
events = [o["sourceEventId"] for o in orders]
print(f"órdenes nuevas: {len(orders)} · eventos distintos: {len(set(events))} · repetidos: {len(events) - len(set(events))}")
