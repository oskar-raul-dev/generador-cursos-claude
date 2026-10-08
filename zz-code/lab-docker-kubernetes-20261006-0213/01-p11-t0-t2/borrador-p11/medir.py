#!/usr/bin/env python3
"""P11: memoria por namespace (workingSet de los contenedores) y por nodo, en el contexto actual."""
import json, subprocess, sys, collections, datetime
etiqueta = sys.argv[1] if len(sys.argv) > 1 else ""
nodes = json.loads(subprocess.check_output(["kubectl", "get", "nodes", "-o", "json"]))["items"]
por_ns, total_nodos = collections.Counter(), 0
for n in nodes:
    name = n["metadata"]["name"]
    s = json.loads(subprocess.check_output(["kubectl", "get", "--raw", f"/api/v1/nodes/{name}/proxy/stats/summary"]))
    total_nodos += s["node"]["memory"]["workingSetBytes"]
    for p in s["pods"]:
        por_ns[p["podRef"]["namespace"]] += sum(c.get("memory", {}).get("workingSetBytes", 0) for c in p.get("containers", []))
mib = lambda b: b / 1048576
print(f"# {etiqueta} · {datetime.datetime.now():%Y-%m-%d %H:%M} · nodos={len(nodes)}")
for ns, b in sorted(por_ns.items()):
    print(f"{ns:22} {mib(b):8.1f} MiB")
print(f"{'TOTAL pods':22} {mib(sum(por_ns.values())):8.1f} MiB")
print(f"{'TOTAL nodos (ws)':22} {mib(total_nodos):8.1f} MiB")
