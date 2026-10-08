"""Un servicio con una fuga lenta y un punto caliente, que se deja observar sin reiniciarlo."""

import os
import signal
import time
import tracemalloc

_cache: dict[str, bytes] = {}     # la fuga: se agrega y nunca se quita
_baseline = None


def remember_availability(request_id: str) -> None:
    _cache[request_id] = bytes(2048)          # 2 KB nuevos por petición, para siempre


def compute_slots() -> int:
    total = 0
    for minute in range(200_000):               # el punto caliente
        total += minute % 40
    return total


def on_sigusr1(signum, frame) -> None:
    """kill -USR1 <pid>: la primera foto es la base; las siguientes muestran qué creció."""
    global _baseline
    snapshot = tracemalloc.take_snapshot()
    if _baseline is None:
        _baseline = snapshot
        print("foto base tomada", flush=True)
        return
    for stat in snapshot.compare_to(_baseline, "lineno")[:2]:
        print("creció:", stat, flush=True)


if __name__ == "__main__":
    if not tracemalloc.is_tracing():
        tracemalloc.start()                     # o PYTHONTRACEMALLOC=1 al arrancar
    signal.signal(signal.SIGUSR1, on_sigusr1)
    print("pid", os.getpid(), flush=True)
    n = 0
    while True:
        n += 1
        remember_availability(f"req-{n}")
        compute_slots()
        time.sleep(0.001)
