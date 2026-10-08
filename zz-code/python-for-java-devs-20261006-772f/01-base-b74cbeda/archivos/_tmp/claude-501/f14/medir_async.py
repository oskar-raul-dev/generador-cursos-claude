"""asyncio contra hilos contra secuencial, en la carga de E/S."""
import asyncio, concurrent.futures as cf, statistics, sys, time

W, PER = 4, 25          # 4 trabajadores, 25 esperas de 10 ms cada uno

def io_chunk(n):
    for _ in range(n): time.sleep(0.01)
    return n

async def io_chunk_async(n):
    for _ in range(n): await asyncio.sleep(0.01)
    return n

async def con_taskgroup():
    async with asyncio.TaskGroup() as tg:
        tareas = [tg.create_task(io_chunk_async(PER)) for _ in range(W)]
    return [t.result() for t in tareas]

async def mal_asyncio():
    """El error: bloquear el bucle con time.sleep dentro de una corrutina."""
    async def bloqueante(n):
        for _ in range(n): time.sleep(0.01)   # ← bloquea a TODOS
        return n
    async with asyncio.TaskGroup() as tg:
        [tg.create_task(bloqueante(PER)) for _ in range(W)]

def bench(fn, reps=3):
    fn(); xs=[]
    for _ in range(reps):
        t0=time.perf_counter(); fn(); xs.append(time.perf_counter()-t0)
    xs.sort(); return statistics.median(xs)

gil = sys._is_gil_enabled() if hasattr(sys,"_is_gil_enabled") else True
print(f"=== {sys.version.split()[0]} · GIL {'activo' if gil else 'DESACTIVADO'} ===")
base = bench(lambda: [io_chunk(PER) for _ in range(W)])
print(f"{'secuencial':<38}{base:>8.2f} s{'1.00×':>12}")
def hilos():
    with cf.ThreadPoolExecutor(W) as ex: return list(ex.map(io_chunk, [PER]*W))
t=bench(hilos); print(f"{'hilos':<38}{t:>8.2f} s{base/t:>11.2f}×")
t=bench(lambda: asyncio.run(con_taskgroup())); print(f"{'asyncio con TaskGroup':<38}{t:>8.2f} s{base/t:>11.2f}×")
t=bench(lambda: asyncio.run(mal_asyncio())); print(f"{'asyncio con time.sleep adentro (mal)':<38}{t:>8.2f} s{base/t:>11.2f}×")
