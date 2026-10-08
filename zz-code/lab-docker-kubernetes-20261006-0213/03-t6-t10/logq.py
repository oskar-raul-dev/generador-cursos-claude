"""LogQL por el proxy de fuentes de datos de Grafana: logq.py '<consulta>' [minutos] → líneas."""
import json, sys, time, urllib.parse, urllib.request
q = sys.argv[1]; mins = int(sys.argv[2]) if len(sys.argv) > 2 else 15
now = time.time_ns()
params = {"query": q, "start": now - mins * 60 * 10**9, "end": now, "limit": 5000, "direction": "forward"}
req = urllib.request.Request("http://127.0.0.1:8080/api/datasources/proxy/uid/loki/loki/api/v1/query_range?" + urllib.parse.urlencode(params),
                             headers={"Host": "grafana.localhost"})
data = json.load(urllib.request.urlopen(req, timeout=60))["data"]
if data["resultType"] == "streams":
    for st in data["result"]:
        for ts, line in st["values"]:
            print(json.dumps(st["stream"], sort_keys=True)[:140], line[:300])
else:
    for r in data["result"]:
        print(r["metric"], r["values"][-1] if "values" in r else r.get("value"))
