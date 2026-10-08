"""Para cada pod de un servicio en apps: segundos desde que se crea hasta que está Ready (condiciones del pod)."""
import json, subprocess, sys
from datetime import datetime
ctx = sys.argv[1]
pods = json.loads(subprocess.run(["kubectl", "--context", ctx, "-n", "apps", "get", "pods", "-l", "app.kubernetes.io/component in (backend,frontend)", "-o", "json"], capture_output=True, text=True, check=True).stdout)["items"]
ts = lambda s: datetime.fromisoformat(s.replace("Z", "+00:00"))
for p in sorted(pods, key=lambda p: p["metadata"]["labels"]["app.kubernetes.io/name"]):
    if p["metadata"].get("deletionTimestamp"): continue
    c = {x["type"]: x for x in p["status"].get("conditions", [])}
    if c.get("Ready", {}).get("status") != "True": print(p["metadata"]["name"], "no listo"); continue
    created = ts(p["metadata"]["creationTimestamp"]); started = ts(p["status"]["startTime"])
    ready = ts(c["Ready"]["lastTransitionTime"])
    print(f'{p["metadata"]["labels"]["app.kubernetes.io/name"]:11} {(ready - created).total_seconds():5.0f} s')
