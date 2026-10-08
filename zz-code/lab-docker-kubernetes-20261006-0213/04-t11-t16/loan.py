"""Pide un préstamo por la puerta y espera su estado final; imprime el préstamo y el tiempo."""
import json, sys, time, urllib.request
API = "http://api.localhost:8080/inventory"
def call(method, path, body=None):
    data = json.dumps(body).encode() if body else None
    req = urllib.request.Request(API + path, data=data, method=method, headers={"Content-Type": "application/json"})
    with urllib.request.urlopen(req, timeout=10) as r:
        return json.load(r)
sku, origin, dest, qty = sys.argv[1], sys.argv[2], sys.argv[3], int(sys.argv[4])
wait = float(sys.argv[5]) if len(sys.argv) > 5 else 30
t0 = time.time()
loan = call("POST", "/loans", {"sku": sku, "originStore": origin, "destinationStore": dest, "quantity": qty})
lid = loan["id"]
while time.time() - t0 < wait:
    loan = call("GET", f"/loans/{lid}")
    if loan["status"] in ("COMPLETED", "COMPENSATED", "BACKORDERED"):
        break
    time.sleep(0.1)
print(json.dumps(loan, indent=2, ensure_ascii=False))
print(f"# {lid}: {loan['status']} a los {(time.time() - t0) * 1000:.0f} ms")
