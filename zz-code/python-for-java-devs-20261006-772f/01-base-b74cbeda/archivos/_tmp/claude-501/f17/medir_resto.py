"""Arranque en frío, memoria y tamaño del artefacto, para los dos."""
import os, signal, statistics, subprocess, time
import httpx

JAVA = os.path.expanduser("~/.sdkman/candidates/java/21.0.8-zulu/bin/java")
PATH_Q = "/availability?branch=centro&day=2026-10-15"

def rss_total_mb(pid):
    """RSS del proceso y de todos sus hijos (uvicorn con workers son varios)."""
    out = subprocess.run(["ps", "-eo", "pid,ppid,rss"], capture_output=True, text=True).stdout
    filas = [l.split() for l in out.strip().splitlines()[1:]]
    hijos = {pid}
    for _ in range(3):
        hijos |= {int(f[0]) for f in filas if int(f[1]) in hijos}
    return sum(int(f[2]) for f in filas if int(f[0]) in hijos) / 1024

def arranque(cmd, puerto, reps=5):
    ts, mems = [], []
    for _ in range(reps):
        t0 = time.perf_counter()
        p = subprocess.Popen(cmd, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL,
                             start_new_session=True)
        while True:
            try:
                if httpx.get(f"http://127.0.0.1:{puerto}{PATH_Q}", timeout=0.3).status_code == 200:
                    break
            except Exception: pass
            if time.perf_counter()-t0 > 90: raise RuntimeError("no arrancó")
        ts.append(time.perf_counter()-t0)
        time.sleep(3); mems.append(rss_total_mb(p.pid))
        os.killpg(os.getpgid(p.pid), signal.SIGTERM); p.wait(timeout=25); time.sleep(2)
    ts.sort()
    return statistics.median(ts)*1000, statistics.median(mems)

casos = [
    ("Spring Boot 3.5.16 (Java 21)", [JAVA, "-jar", "agenda-java/target/agenda-0.17.0.jar"], 8124),
    ("uvicorn, 1 trabajador", [".venv/bin/python","-m","uvicorn","app:app","--port","8125","--log-level","error"], 8125),
    ("uvicorn, 4 trabajadores", [".venv/bin/python","-m","uvicorn","app:app","--port","8125","--workers","4","--log-level","error"], 8125),
]
for nombre, cmd, puerto in casos:
    ms, mb = arranque(cmd, puerto)
    print(f"{nombre:<34}arranque {ms:7.0f} ms · RSS {mb:6.0f} MB")
