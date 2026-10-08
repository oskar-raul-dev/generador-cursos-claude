import subprocess, time
NGX="nginxinc/nginx-unprivileged@sha256:ed04ec1ff34502c339ee5c3ae3f855442398edc1d05591e2b98981dcbbd20b1e"
def k(*a): return subprocess.run(["kubectl","-n","apps",*a],capture_output=True,text=True)
print(k("rollout","restart","deploy/inventory").stdout.strip())
print(k("rollout","status","deploy/inventory","--timeout=90s").stdout.strip())
k("run","race","--restart=Never","--image="+NGX,"--","curl","-sS","http://inventory:8080/health/live")
time.sleep(4); print("$ curl -sS http://inventory:8080/health/live   (apenas terminó el rollout)"); print(k("logs","race").stdout.strip()); k("delete","pod","race")
