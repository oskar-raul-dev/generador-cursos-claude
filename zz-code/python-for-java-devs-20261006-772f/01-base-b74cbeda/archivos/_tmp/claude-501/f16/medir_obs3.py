"""Costo por evento y volumen. Cada caso escribe su propio archivo."""
import logging, time
from pathlib import Path
import structlog

REPS = 20_000

def medir(nombre, emitir, path=None, cerrar=None):
    emitir(0)
    t0 = time.perf_counter()
    for i in range(REPS): emitir(i)
    dt = time.perf_counter() - t0
    if cerrar: cerrar()
    tam = path.stat().st_size if path and path.exists() else 0
    por_evento = tam / (REPS + 1) if tam else 0
    print(f"{nombre:<40}{dt/REPS*1e6:8.2f} µs/evento{por_evento:9.0f} B/evento"
          f"{por_evento*3_900_000/1e9:9.2f} GB/mes*")

medir("sin registro", lambda i: None)

p1 = Path("plano.log"); p1.unlink(missing_ok=True)
std = logging.getLogger("plano"); std.setLevel(logging.INFO)
h = logging.FileHandler(p1, mode="w")
h.setFormatter(logging.Formatter("%(asctime)s %(levelname)s %(message)s"))
std.addHandler(h)
medir("logging estándar, texto", lambda i: std.info("reserva creada branch=%s slot=%s", "centro", i),
      p1, cerrar=lambda: h.flush())
std.removeHandler(h); h.close()

p2 = Path("estructurado.log"); p2.unlink(missing_ok=True)
f = p2.open("w")
structlog.configure(
    processors=[structlog.processors.add_log_level,
                structlog.processors.TimeStamper(fmt="iso"),
                structlog.processors.JSONRenderer()],
    logger_factory=structlog.WriteLoggerFactory(file=f))
log = structlog.get_logger()
medir("structlog JSON con contexto", lambda i: log.info("reserva_creada", branch="centro",
      slot=i, patient="1019283746", actor="yuli", request_id="r-0001"), p2, cerrar=lambda: f.flush())
f.close()

std2 = logging.getLogger("apagado"); std2.setLevel(logging.INFO)
medir("logging.debug con DEBUG apagado", lambda i: std2.debug("detalle %s", i))
print("\n* proyectado al volumen de Áurea: 3.900 citas/mes × 1.000 eventos por cita")
