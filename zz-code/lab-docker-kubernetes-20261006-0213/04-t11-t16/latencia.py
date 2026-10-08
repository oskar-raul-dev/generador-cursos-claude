"""Latencia del aviso: hora de publicación en inventory contra hora de la orden en replenish, por eventId."""
import json, subprocess, statistics, sys
K = ["kubectl", "--context", "kind-lab", "-n", "apps", "logs", "--tail=-1", "--since=" + sys.argv[1]]
pub, got = {}, {}
from datetime import datetime
def ts(s): return datetime.fromisoformat(s.replace("Z", "+00:00")).timestamp()
for line in subprocess.run(K + ["deploy/inventory"], capture_output=True, text=True).stdout.splitlines():
    d = json.loads(line)
    if "evento " in d.get("msg", "") and "aviso de" in d["msg"]:
        pub[d["msg"].split("evento ")[1].split(" ")[0]] = ts(d["time"])
for line in subprocess.run(K + ["deploy/replenish"], capture_output=True, text=True).stdout.splitlines():
    d = json.loads(line)
    if d.get("msg") == "orden creada por evento":
        got.setdefault(d["eventId"], ts(d["time"]))
ms = sorted((got[e] - pub[e]) * 1000 for e in pub if e in got)
print(f"{len(ms)} avisos · mediana {statistics.median(ms):.1f} ms · p90 {ms[int(len(ms)*0.9)-1]:.1f} ms · máx {ms[-1]:.1f} ms")
