import subprocess, time, json
def k(*a): return subprocess.run(["kubectl","--context","kind-minimo",*a],capture_output=True,text=True).stdout.strip()
res=[]
for i in range(5):
    old=k("get","pods","-l","app.kubernetes.io/name=pricing","-o","jsonpath={.items[0].metadata.name}")
    t=time.monotonic(); k("delete","pod",old,"--wait=false")
    while True:
        out=k("get","pods","-l","app.kubernetes.io/name=pricing","-o","jsonpath={range .items[*]}{.metadata.name} {.status.phase} {.status.containerStatuses[0].ready}{'\\n'}{end}")
        new=[l for l in out.splitlines() if l and not l.startswith(old) and l.endswith("Running true")]
        if new: break
        time.sleep(0.1)
    res.append(round(time.monotonic()-t,2)); print(i+1, old, "->", new[0].split()[0], res[-1], "s", flush=True)
    time.sleep(5)
print("tiempos", res)
