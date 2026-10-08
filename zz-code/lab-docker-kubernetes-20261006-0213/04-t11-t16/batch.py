"""Pide N préstamos y sigue sus estados hasta que todos terminan; imprime cada cambio con su segundo."""
import json, sys, time, urllib.request
API = "http://api.localhost:8080/inventory"
def call(method, path, body=None):
    data = json.dumps(body).encode() if body else None
    req = urllib.request.Request(API + path, data=data, method=method, headers={"Content-Type": "application/json"})
    with urllib.request.urlopen(req, timeout=10) as r:
        return json.load(r)
n, origin, dest, limit = int(sys.argv[1]), sys.argv[2], sys.argv[3], float(sys.argv[4])
t0 = time.time()
ids = [call("POST", "/loans", {"sku": "SKU-0003", "originStore": origin, "destinationStore": dest, "quantity": 1})["id"] for _ in range(n)]
last = {}
while time.time() - t0 < limit:
    for i in ids:
        try:
            d = call("GET", f"/loans/{i}")
        except Exception:
            continue
        key = (d["status"], len(d["steps"]))
        if last.get(i) != key:
            last[i] = key
            print(f"+{time.time()-t0:5.1f}s {i} {d['status']:<12} " + "; ".join(f"{s['step']} {s['action']} {s['outcome']}" for s in d["steps"]), flush=True)
    if all(v[0] in ("COMPLETED", "COMPENSATED", "BACKORDERED") for v in last.values()) and len(last) == n:
        break
    time.sleep(1)
print(f"# {n} préstamos: " + ", ".join(f"{i} {last[i][0]}" for i in ids))
