import sys, time, subprocess, json, statistics
sys.path.insert(0,"scripts/measure"); import measure
def vm(): return measure.LegacyRun("docker").vm_memory()["used_mib"]
def sh(c): print("$"," ".join(c),flush=True); return subprocess.run(c,capture_output=True,text=True,check=True).stdout
sh(["k3d","cluster","create","b07","--wait"]); print(sh(["kubectl","--context","k3d-b07","get","pods","-A"])); sh(["k3d","cluster","delete","b07"])
res=[]
for i in range(3):
    time.sleep(10); b=vm(); t=time.monotonic()
    sh(["k3d","cluster","create","b07","--wait","--k3s-arg","--disable=traefik@server:0"])
    sh(["kubectl","--context","k3d-b07","wait","--for=condition=Ready","nodes","--all","--timeout=300s"])
    ready=round(time.monotonic()-t,1); time.sleep(60); a=vm()
    if i==0: print(sh(["kubectl","--context","k3d-b07","get","pods","-A"]))
    sh(["k3d","cluster","delete","b07"]); res.append({"ready_s":ready,"cluster_mib":a-b}); print(res[-1],flush=True)
print("mediana", statistics.median([r["cluster_mib"] for r in res]), [r["cluster_mib"] for r in res], [r["ready_s"] for r in res])
json.dump(res,open("bench/b07/results/docker-k3d-sin-traefik-2026-10-03.json","w"),indent=2)
