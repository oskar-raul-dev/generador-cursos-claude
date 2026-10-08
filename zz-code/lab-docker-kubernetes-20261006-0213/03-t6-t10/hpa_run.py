"""Carga constante con k6 contra un servicio y, cada 5 s, el HPA (CPU, réplicas deseadas) y las réplicas
listas. Imprime cuándo el HPA pidió la primera réplica nueva y cuándo estuvo lista."""
import json, subprocess, sys, time
svc, url, rate, seconds = sys.argv[1], sys.argv[2], sys.argv[3], int(sys.argv[4])
k = ["kubectl", "--context", "kind-lab", "-n", "apps"]
k6 = subprocess.Popen(["k6", "run", "--quiet", "--summary-trend-stats", "med,p(95),max", "-e", f"URL={url}", "-e", f"RATE={rate}",
                       "-e", f"DURATION={seconds}s", sys.argv[5]], stdout=subprocess.PIPE, stderr=subprocess.STDOUT, text=True)
start = time.time(); first_desired = first_ready = None
while k6.poll() is None:
    hpa = json.loads(subprocess.run(k + ["get", "hpa", svc, "-o", "json"], capture_output=True, text=True).stdout)
    dep = json.loads(subprocess.run(k + ["get", "deploy", svc, "-o", "json"], capture_output=True, text=True).stdout)
    cur = hpa.get("status", {}).get("currentMetrics") or [{}]
    cpu = cur[0].get("resource", {}).get("current", {}).get("averageUtilization", "?")
    desired = hpa["status"].get("desiredReplicas", 0); ready = dep["status"].get("readyReplicas", 0)
    t = time.time() - start
    if first_desired is None and desired > 1: first_desired = t
    if first_ready is None and ready > 1: first_ready = t
    print(f"{t:5.0f} s · cpu {cpu}% · deseadas {desired} · listas {ready}", flush=True)
    time.sleep(5)
out = k6.stdout.read()
print("\n".join(l for l in out.splitlines() if "http_req" in l))
print(f"primera réplica pedida a los {first_desired and round(first_desired)} s; lista a los {first_ready and round(first_ready)} s")
