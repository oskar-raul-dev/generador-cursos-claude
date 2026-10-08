"""El arnés del duelo: mismas condiciones para los dos."""
import asyncio, os, re, signal, statistics, subprocess, sys, time
from pathlib import Path
import httpx

JAVA = os.path.expanduser("~/.sdkman/candidates/java/21.0.8-zulu/bin/java")
JAR = "agenda-java/target/agenda-0.17.0.jar"
PY = ".venv/bin/python"
URL_PATH = "/availability?branch=centro&day=2026-10-15"


def rss_mb(pid: int) -> float:
    out = subprocess.run(["ps", "-o", "rss=", "-p", str(pid)], capture_output=True, text=True)
    return int(out.stdout.strip() or 0) / 1024


def arranque_en_frio(cmd, puerto, reps=5):
    """Desde lanzar el proceso hasta la primera respuesta correcta."""
    tiempos, memorias = [], []
    for _ in range(reps):
        t0 = time.perf_counter()
        p = subprocess.Popen(cmd, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
        while True:
            try:
                r = httpx.get(f"http://127.0.0.1:{puerto}{URL_PATH}", timeout=0.4)
                if r.status_code == 200:
                    break
            except Exception:
                pass
            if time.perf_counter() - t0 > 60:
                raise RuntimeError("no arrancó")
        tiempos.append(time.perf_counter() - t0)
        time.sleep(2)
        memorias.append(rss_mb(p.pid))
        p.send_signal(signal.SIGTERM); p.wait(timeout=20)
        time.sleep(1)
    tiempos.sort()
    return statistics.median(tiempos), statistics.median(memorias)


async def carga(puerto, concurrencia=32, duracion=10.0):
    """Carga sostenida: cuántas peticiones por segundo y con qué latencia."""
    limites = httpx.Limits(max_connections=concurrencia * 2, max_keepalive_connections=concurrencia * 2)
    latencias, hechas = [], 0
    fin = time.perf_counter() + duracion
    async with httpx.AsyncClient(base_url=f"http://127.0.0.1:{puerto}", limits=limites,
                                 timeout=10.0) as c:
        async def trabajador():
            nonlocal hechas
            while time.perf_counter() < fin:
                t0 = time.perf_counter()
                r = await c.get(URL_PATH)
                if r.status_code == 200:
                    latencias.append((time.perf_counter() - t0) * 1000); hechas += 1
        # calentamiento
        for _ in range(200): await c.get(URL_PATH)
        inicio = time.perf_counter(); fin = inicio + duracion
        latencias.clear(); hechas = 0
        await asyncio.gather(*[trabajador() for _ in range(concurrencia)])
        real = time.perf_counter() - inicio
    latencias.sort()
    return {"rps": hechas / real,
            "p50": statistics.median(latencias),
            "p95": latencias[int(len(latencias) * 0.95) - 1],
            "p99": latencias[int(len(latencias) * 0.99) - 1]}


def medir(nombre, cmd, puerto):
    print(f"\n### {nombre} ###")
    frio, mem = arranque_en_frio(cmd, puerto)
    print(f"arranque en frío (mediana de 5): {frio*1000:8.0f} ms · RSS {mem:6.0f} MB")
    p = subprocess.Popen(cmd, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
    for _ in range(200):
        try:
            if httpx.get(f"http://127.0.0.1:{puerto}{URL_PATH}", timeout=0.5).status_code == 200: break
        except Exception: time.sleep(0.1)
    r = asyncio.run(carga(puerto))
    mem_carga = rss_mb(p.pid)
    print(f"carga (32 conc., 10 s):  {r['rps']:8.0f} req/s · p50 {r['p50']:5.1f} ms · "
          f"p95 {r['p95']:5.1f} ms · p99 {r['p99']:5.1f} ms · RSS {mem_carga:.0f} MB")
    p.send_signal(signal.SIGTERM); p.wait(timeout=20)
    return {"frio_ms": frio*1000, "rss_reposo": mem, "rss_carga": mem_carga, **r}


if __name__ == "__main__":
    sb = medir("Spring Boot 3.5.16 · Java 21", [JAVA, "-jar", JAR], 8124)
    fa = medir("FastAPI 0.141.1 · uvicorn · CPython 3.14.5",
               [PY, "-m", "uvicorn", "app:app", "--port", "8125", "--log-level", "error"], 8125)
    print("\n=== resumen ===")
    print(f"{'':<28}{'Spring Boot 3':>16}{'FastAPI':>16}")
    for k, etiqueta, fmt in [("frio_ms","arranque en frío","{:.0f} ms"), ("rss_reposo","RSS en reposo","{:.0f} MB"),
                             ("rss_carga","RSS bajo carga","{:.0f} MB"), ("rps","peticiones/s","{:.0f}"),
                             ("p50","latencia p50","{:.1f} ms"), ("p95","latencia p95","{:.1f} ms"),
                             ("p99","latencia p99","{:.1f} ms")]:
        print(f"{etiqueta:<28}{fmt.format(sb[k]):>16}{fmt.format(fa[k]):>16}")
