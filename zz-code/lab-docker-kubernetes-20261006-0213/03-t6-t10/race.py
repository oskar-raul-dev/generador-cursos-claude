"""Veinte reposiciones de 1 unidad a la vez por la puerta, sobre una existencia contada en 0."""
import json, sys, urllib.request, concurrent.futures, collections
base = "http://api.localhost:8080/inventory"; store, sku = "DRO-030", sys.argv[1]
def post(body):
    req = urllib.request.Request(f"{base}/stock/{store}/{sku}/movements", data=json.dumps(body).encode(), headers={"Content-Type": "application/json"}, method="POST")
    try: return urllib.request.urlopen(req, timeout=10).status
    except urllib.error.HTTPError as e: return e.code
post({"type": "COUNT", "quantity": 0, "reference": "carrera-f16"})
with concurrent.futures.ThreadPoolExecutor(20) as pool:
    codes = collections.Counter(pool.map(lambda _: post({"type": "RESTOCK", "quantity": 1, "reference": "carrera-f16"}), range(20)))
q = json.load(urllib.request.urlopen(f"{base}/stock/{store}/{sku}"))["quantity"]
print(f"respuestas: {dict(codes)}; después: {q} (se esperaban 20)")
