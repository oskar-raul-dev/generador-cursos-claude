"""¿Cuánto cuesta el free-threading cuando NO usas hilos?"""
import statistics, sys, time
from carga import reconcile_chunk

rows=[]
with open("data/ventas-2026-Q1.csv", encoding="utf-8") as f:
    next(f)
    for i, line in enumerate(f):
        if i >= 400_000: break
        rows.append(tuple(line.rstrip("\n").split(",")))

def bench(fn, reps=7):
    fn(); xs=[]
    for _ in range(reps):
        t0=time.perf_counter(); fn(); xs.append(time.perf_counter()-t0)
    xs.sort(); return statistics.median(xs)

gil = sys._is_gil_enabled() if hasattr(sys,"_is_gil_enabled") else True
t = bench(lambda: reconcile_chunk(rows))
print(f"{'GIL activo' if gil else 'sin GIL':>12}: un solo hilo, 400.000 filas -> {t:.3f} s")
