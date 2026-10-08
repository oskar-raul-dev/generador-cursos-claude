"""La memoria (working set) de cada contenedor de un namespace, leída en el nodo con crictl."""
import json, subprocess, sys
node, ns = sys.argv[1], sys.argv[2]
stats = json.loads(subprocess.run(["docker", "exec", node, "crictl", "stats", "--label", f"io.kubernetes.pod.namespace={ns}", "-o", "json"], capture_output=True, text=True, check=True).stdout)
ps = json.loads(subprocess.run(["docker", "exec", node, "crictl", "ps", "--label", f"io.kubernetes.pod.namespace={ns}", "-o", "json"], capture_output=True, text=True, check=True).stdout)
names = {c["id"]: (c["labels"].get("io.kubernetes.pod.name", "?"), c["metadata"]["name"]) for c in ps["containers"]}
rows = []
for s in stats["stats"]:
    cid = s["attributes"]["id"]; pod, cname = names.get(cid, ("?", s["attributes"]["metadata"]["name"]))
    if "memory" not in s: continue  # un contenedor terminado (los Job) no tiene memoria
    ws = int(s["memory"]["workingSetBytes"]["value"]) / 2**20
    rows.append((pod, cname, ws))
for pod, cname, ws in sorted(rows):
    print(f"{pod:40} {cname:12} {ws:7.1f} MiB")
