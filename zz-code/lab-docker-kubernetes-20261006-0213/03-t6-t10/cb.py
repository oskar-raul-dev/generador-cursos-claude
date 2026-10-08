"""Cada 2 s: cuántas peticiones lleva el caos y el estado del circuito de catalog en inventory."""
import json, subprocess, time, urllib.request, sys
pf = subprocess.Popen(["kubectl","--context","kind-lab","-n","apps","port-forward","svc/chaos","18089:8080"],stdout=subprocess.DEVNULL,stderr=subprocess.DEVNULL)
pi = subprocess.Popen(["kubectl","--context","kind-lab","-n","apps","port-forward","svc/inventory","18090:8080"],stdout=subprocess.DEVNULL,stderr=subprocess.DEVNULL)
time.sleep(3); t0=time.time(); last=None
try:
    while time.time()-t0 < float(sys.argv[1]):
        c = json.load(urllib.request.urlopen("http://127.0.0.1:18089/chaos"))["counts"]["received"]
        m = urllib.request.urlopen("http://127.0.0.1:18090/metrics").read().decode()
        st = [l.split('state="')[1].split('"')[0] for l in m.splitlines() if l.startswith('resilience4j_circuitbreaker_state{name="catalog"') and l.endswith(" 1.0")]
        print(f"{time.time()-t0:5.0f} s  catalog recibió {c - (last or c):3d}  circuito {st[0] if st else '?'}", flush=True); last=c
        time.sleep(2)
finally:
    pf.terminate(); pi.terminate()
