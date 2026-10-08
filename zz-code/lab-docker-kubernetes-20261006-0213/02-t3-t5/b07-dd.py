import json, subprocess, time, os, statistics
S=os.path.expanduser("~/Library/Group Containers/group.com.docker/settings-store.json")
PROBE="postgres@sha256:5a5a84b19854a9ffaa54082c166ff4ec27473a361e496e5ea167f298f2da9722"
def sh(c): return subprocess.run(c,capture_output=True,text=True)
def vm():
    raw=sh(["docker","run","--rm","--entrypoint","cat",PROBE,"/proc/meminfo"]).stdout
    kb={l.split(":")[0]:int(l.split()[1]) for l in raw.splitlines()}
    return (kb["MemTotal"]-kb["MemAvailable"])//1024
def setk(on):
    d=json.load(open(S)); d["KubernetesEnabled"]=on; json.dump(d,open(S,"w"),indent=2)
res={"on":[],"off":[]}
for mode in ["off","on","off","on","off","on"]:
    sh(["docker","desktop","stop"]); setk(mode=="on")
    t=time.monotonic(); sh(["docker","desktop","start"])
    while sh(["docker","info"]).returncode!=0: time.sleep(1)
    engine=time.monotonic()-t
    if mode=="off":
        # Deshabilitar no apaga el cluster (sigue Ready), y reset-cluster con Kubernetes habilitado lo
        # recrea: se borra recién con Kubernetes deshabilitado y el motor arriba.
        sh(["docker","desktop","kubernetes","reset-cluster"])
    if mode=="on":
        while "running" not in sh(["docker","desktop","kubernetes","status"]).stdout: time.sleep(2)
        while sh(["kubectl","--context","docker-desktop","wait","--for=condition=Ready","nodes","--all","--timeout=5s"]).returncode!=0: time.sleep(2)
    ready=time.monotonic()-t
    time.sleep(60); used=vm()
    res[mode].append({"engine_s":round(engine,1),"ready_s":round(ready,1),"vm_used_mib":used})
    print(mode,res[mode][-1],flush=True)
json.dump(res,open("/Users/oskar/Developer/Learning/courses-ia-generated/cursos-contenedores-cloud-infra/lab-docker-kubernetes/src/lab/bench/b07/results/docker-desktop-kubernetes-2026-10-03-c.json","w"),indent=2)
sh(["docker","desktop","kubernetes","reset-cluster"]); sh(["docker","desktop","stop"]); setk(False); sh(["docker","desktop","start"])
