"""Pide el tope de SKU-0003 cada 200 ms hasta que valga el esperado; imprime cuánto tardó y qué vio."""
import json, sys, time, urllib.request
expected, limit = int(sys.argv[1]), float(sys.argv[2])
url = "http://api.localhost:8080/pricing/prices/SKU-0003?store=DRO-007"
start = time.time(); seen = {}
while time.time() - start < limit:
    try:
        cap = json.load(urllib.request.urlopen(url, timeout=1)).get("regulatedCap")
    except Exception as e:
        cap = type(e).__name__
    seen[str(cap)] = seen.get(str(cap), 0) + 1
    if cap == expected:
        print(f"tope {expected} a los {time.time() - start:.1f} s; respuestas vistas: {seen}"); sys.exit(0)
    time.sleep(0.2)
print(f"no llegó a {expected} en {limit} s; respuestas vistas: {seen}"); sys.exit(1)
