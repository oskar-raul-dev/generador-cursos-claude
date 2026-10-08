"""¿El intérprete paraleliza de verdad? Carga de Python puro, sin extensiones C."""
import concurrent.futures as cf, statistics, sys, time

def spin(n: int) -> int:
    """Aritmética pura de Python: sin hashlib, sin Decimal, sin objetos nuevos."""
    total = 0
    for i in range(n):
        total += i * i % 7
    return total

N = 4_000_000
W = 4

def bench(fn, reps=3):
    fn(); xs=[]
    for _ in range(reps):
        t0=time.perf_counter(); fn(); xs.append(time.perf_counter()-t0)
    xs.sort(); return statistics.median(xs)

gil = sys._is_gil_enabled() if hasattr(sys,"_is_gil_enabled") else True
seq = bench(lambda: [spin(N) for _ in range(W)])
def hilos():
    with cf.ThreadPoolExecutor(W) as ex: return list(ex.map(spin, [N]*W))
thr = bench(hilos)
print(f"GIL {'activo' if gil else 'DESACTIVADO'}: secuencial {seq:.2f}s · hilos {thr:.2f}s · {seq/thr:.2f}×")
