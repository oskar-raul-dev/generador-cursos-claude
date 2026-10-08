"""Consulta instantánea a Prometheus por la puerta: promq.py '<expr>' → una línea por serie."""
import json, sys, urllib.parse, urllib.request
q = sys.argv[1]
req = urllib.request.Request("http://127.0.0.1:8080/api/v1/query?" + urllib.parse.urlencode({"query": q}),
                             headers={"Host": "prometheus.localhost"})
data = json.load(urllib.request.urlopen(req, timeout=30))["data"]["result"]
for r in data:
    labels = ",".join(f"{k}={v}" for k, v in sorted(r["metric"].items()) if k != "__name__")
    print(f"{r['value'][1]:>14}  {labels}")
