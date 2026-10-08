"""Una invocación por factura contra una por lote, sobre las 200 facturas del mes."""
import statistics, subprocess, sys, time
from pathlib import Path

PY = sys.executable
FIRMADOR = "firmador_simulado.py"
# Se excluyen los NIT que cuelgan y los que fallan: se miden aparte en la fase.
files = []
for p in sorted(Path("facturas").glob("fac-*.xml")):
    nit = "".join(c for c in p.read_text() if c.isdigit())[:9]
    if not nit.endswith(("7", "3")):
        files.append(p)
print(f"facturas medibles: {len(files)}")

def one_by_one(paths):
    for p in paths:
        subprocess.run([PY, FIRMADOR, "--entrada", str(p), "--salida", str(p.with_suffix(".f.xml"))],
                       capture_output=True, timeout=30)

def one_batch(paths):
    subprocess.run([PY, FIRMADOR, "--lote", *[str(p) for p in paths]],
                   capture_output=True, timeout=300)

def bench(fn, paths, reps=3):
    xs=[]
    for _ in range(reps):
        t0=time.perf_counter(); fn(paths); xs.append(time.perf_counter()-t0)
    xs.sort(); return statistics.median(xs)

# Costo puro de crear un proceso, sin trabajo adentro
xs=[]
for _ in range(30):
    t0=time.perf_counter(); subprocess.run([PY, "-c", "pass"], capture_output=True); xs.append((time.perf_counter()-t0)*1000)
xs.sort()
print(f"crear un proceso de Python (sin trabajo): mediana {statistics.median(xs):.0f} ms")

for n in (10, 50, len(files)):
    sub = files[:n]
    a, b = bench(one_by_one, sub), bench(one_batch, sub)
    print(f"n={n:>3}  una por factura {a*1000:8.0f} ms   una por lote {b*1000:8.0f} ms   "
          f"sobrecosto {(a-b)*1000:7.0f} ms ({(a/b):.1f}×)")
