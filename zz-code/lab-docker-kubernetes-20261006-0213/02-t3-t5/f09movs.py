import subprocess, json, time
NGX="nginxinc/nginx-unprivileged@sha256:ed04ec1ff34502c339ee5c3ae3f855442398edc1d05591e2b98981dcbbd20b1e"
I="http://inventory:8080/stock/DRO-007/SKU-0003"
def k(*a): return subprocess.run(["kubectl","-n","apps",*a],capture_output=True,text=True).stdout
pass
steps=[("POST COUNT 30",["-H","Content-Type: application/json","-d",json.dumps({"type":"COUNT","quantity":30,"reference":"conteo-lunes"}),I+"/movements"]),
("POST RESTOCK 6",["-H","Content-Type: application/json","-d",json.dumps({"type":"RESTOCK","quantity":6,"reference":"RO-0002"}),I+"/movements"]),
("POST ADJUSTMENT -2 TRANSFER_LOST",["-H","Content-Type: application/json","-d",json.dumps({"type":"ADJUSTMENT","quantity":-2,"reasonCode":"TRANSFER_LOST","reference":"traslados_20261003_0308.txt"}),I+"/movements"]),
("POST COUNT 31",["-H","Content-Type: application/json","-d",json.dumps({"type":"COUNT","quantity":31,"reference":"conteo-martes"}),I+"/movements"]),
("GET",[I]),
("PATCH quantity",["-X","PATCH","-H","Content-Type: application/merge-patch+json","-d",json.dumps({"quantity":50}),I])]
for n,(label,args) in enumerate(steps):
    name=f"movs{n}"
    k("run",name,"--restart=Never","--image="+NGX,"--","curl","-s",*args)
    k("wait","--for=jsonpath={.status.phase}=Succeeded","pod/"+name,"--timeout=60s")
    print("$",label); print(k("logs",name).strip()); k("delete","pod",name)
