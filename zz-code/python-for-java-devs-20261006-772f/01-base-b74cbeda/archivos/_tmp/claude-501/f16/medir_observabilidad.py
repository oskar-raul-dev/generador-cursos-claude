"""Cuánto cuesta ver lo que pasa: latencia y volumen de registro."""
import io, json, logging, os, statistics, sys, time
from pathlib import Path

import structlog
from fastapi.testclient import TestClient
import httpx

import app as A

REPS = 300
PARAMS = {"branch": "centro", "day": "2026-10-15"}

def bench_http(base, reps=REPS):
    with httpx.Client(base_url=base) as c:
        for _ in range(30): c.get("/availability", params=PARAMS)
        xs=[]
        for _ in range(reps):
            t0=time.perf_counter(); c.get("/availability", params=PARAMS); xs.append((time.perf_counter()-t0)*1000)
    xs.sort(); return statistics.median(xs), xs[int(len(xs)*0.95)-1]

# --- costo del registro, aislado del HTTP ---
print("=== costo por evento de registro (10.000 eventos) ===")
destino = Path("bench.log")

def medir_logger(nombre, emitir, reps=10_000):
    destino.unlink(missing_ok=True)
    emitir()  # calentar
    t0=time.perf_counter()
    for i in range(reps): emitir(i)
    dt=(time.perf_counter()-t0)
    tam = destino.stat().st_size if destino.exists() else 0
    print(f"{nombre:<44}{dt/reps*1e6:8.1f} µs/evento   {tam/reps:7.0f} B/evento")

# 1. sin registro
medir_logger("sin registro", lambda i=0: None)

# 2. logging estándar a archivo
std = logging.getLogger("plano"); std.setLevel(logging.INFO)
h = logging.FileHandler(destino, mode="w"); h.setFormatter(logging.Formatter("%(asctime)s %(levelname)s %(message)s"))
std.addHandler(h)
medir_logger("logging estándar, texto", lambda i=0: std.info("reserva creada branch=%s slot=%s", "centro", i))

# 3. structlog JSON
for hh in list(std.handlers): std.removeHandler(hh)
destino.unlink(missing_ok=True)
f = destino.open("w")
structlog.configure(
    processors=[structlog.processors.add_log_level, structlog.processors.TimeStamper(fmt="iso"),
                structlog.processors.JSONRenderer()],
    logger_factory=structlog.WriteLoggerFactory(file=f),
)
log = structlog.get_logger()
medir_logger("structlog JSON", lambda i=0: log.info("reserva_creada", branch="centro", slot=i, patient="1019283746"))
f.close()
