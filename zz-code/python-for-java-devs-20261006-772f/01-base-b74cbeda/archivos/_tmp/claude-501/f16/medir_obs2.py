"""Costo por evento de registro, con el archivo cerrado antes de medir tamaño."""
import logging, statistics, time
from pathlib import Path
import structlog

REPS = 20_000
destino = Path("bench.log")

def medir(nombre, emitir, cerrar=None):
    destino.unlink(missing_ok=True)
    emitir(0)
    t0 = time.perf_counter()
    for i in range(REPS): emitir(i)
    dt = time.perf_counter() - t0
    if cerrar: cerrar()
    tam = destino.stat().st_size if destino.exists() else 0
    print(f"{nombre:<40}{dt/REPS*1e6:8.2f} µs/evento{tam/REPS:9.0f} B/evento{tam/1e6:9.1f} MB total")

medir("sin registro", lambda i: None)

std = logging.getLogger("plano"); std.setLevel(logging.INFO)
h = logging.FileHandler(destino, mode="w")
h.setFormatter(logging.Formatter("%(asctime)s %(levelname)s %(message)s"))
std.addHandler(h)
medir("logging estándar, texto", lambda i: std.info("reserva creada branch=%s slot=%s", "centro", i),
      cerrar=lambda: h.flush())
std.removeHandler(h); h.close()

destino.unlink(missing_ok=True)
f = destino.open("w")
structlog.configure(
    processors=[structlog.processors.add_log_level,
                structlog.processors.TimeStamper(fmt="iso"),
                structlog.processors.JSONRenderer()],
    logger_factory=structlog.WriteLoggerFactory(file=f))
log = structlog.get_logger()
medir("structlog JSON con contexto", lambda i: log.info("reserva_creada", branch="centro",
      slot=i, patient="1019283746", actor="yuli", request_id="r-0001"), cerrar=lambda: f.flush())
f.close()

# nivel DEBUG apagado: el costo de la llamada que no emite
std2 = logging.getLogger("apagado"); std2.setLevel(logging.INFO)
medir("logging.debug con DEBUG apagado", lambda i: std2.debug("detalle %s", i))
