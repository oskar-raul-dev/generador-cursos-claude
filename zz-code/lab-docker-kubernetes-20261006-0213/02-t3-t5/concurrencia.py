"""Veinte reposiciones de 1 unidad a la vez contra inventory, por la puerta; después, la existencia."""
import concurrent.futures, json, urllib.request
A = "http://api.localhost:8080/inventory/stock/DRO-009/SKU-0002"
def get():
    with urllib.request.urlopen(A) as r:
        return json.load(r)["quantity"]
def restock(i):
    req = urllib.request.Request(A + "/movements", method="POST", headers={"Content-Type": "application/json"},
                                 data=json.dumps({"type": "RESTOCK", "quantity": 1, "reference": f"RO-95{i:02d}"}).encode())
    with urllib.request.urlopen(req) as r:
        return r.status
req = urllib.request.Request(A + "/movements", method="POST", headers={"Content-Type": "application/json"},
                             data=json.dumps({"type": "COUNT", "quantity": 0, "reference": "conteo-inicial"}).encode())
urllib.request.urlopen(req)
print("antes:", get())
with concurrent.futures.ThreadPoolExecutor(20) as pool:
    codes = list(pool.map(restock, range(20)))
print("respuestas:", {c: codes.count(c) for c in set(codes)})
print("después:", get(), "(se esperaban 20)")
