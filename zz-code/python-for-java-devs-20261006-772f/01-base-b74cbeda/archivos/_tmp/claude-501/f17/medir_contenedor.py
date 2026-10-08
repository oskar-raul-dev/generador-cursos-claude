"""Arranque en frío del contenedor: desde docker run hasta la primera respuesta."""
import statistics, subprocess, time
import httpx

def arranque(imagen, puerto_interno, puerto, extra=(), reps=5):
    ts = []
    for _ in range(reps):
        subprocess.run(["docker", "rm", "-f", "duelo"], capture_output=True)
        t0 = time.perf_counter()
        subprocess.run(["docker", "run", "-d", "--rm", "--name", "duelo",
                        "-p", f"{puerto}:{puerto_interno}", *extra, imagen],
                       capture_output=True, check=True)
        while True:
            try:
                if httpx.get(f"http://127.0.0.1:{puerto}/availability?branch=centro&day=2026-10-15",
                             timeout=0.3).status_code == 200:
                    break
            except Exception:
                pass
            if time.perf_counter() - t0 > 120:
                raise RuntimeError(f"{imagen} no arrancó")
        ts.append(time.perf_counter() - t0)
        subprocess.run(["docker", "rm", "-f", "duelo"], capture_output=True)
        time.sleep(1)
    ts.sort()
    return statistics.median(ts) * 1000

for nombre, imagen, interno in [("FastAPI en contenedor", "aurea-fastapi", 8000),
                                ("Spring Boot en contenedor", "aurea-spring", 8124)]:
    ms = arranque(imagen, interno, 8130)
    print(f"{nombre:<30}{ms:8.0f} ms (mediana de 5)")
