"""numba sobre el suavizado: el costo de compilar, el caché en disco, prange y lo que no compila."""

import os
import time
from decimal import Decimal

import numpy as np
from numba import njit, prange
from numba.core.errors import NumbaError


@njit(cache=True)
def ema(x, alpha):
    out = np.empty_like(x)
    s = x[0]
    for i in range(x.shape[0]):
        s = alpha * x[i] + (1 - alpha) * s
        out[i] = s
    return out


@njit(parallel=True, cache=True)
def ema_many(series, alpha):
    out = np.empty_like(series)
    for k in prange(series.shape[0]):          # cada serie es independiente: esas sí se reparten
        s = series[k, 0]
        for i in range(series.shape[1]):
            s = alpha * series[k, i] + (1 - alpha) * s
            out[k, i] = s
    return out


def ms(fn):
    start = time.perf_counter(); fn(); return (time.perf_counter() - start) * 1000


N, ALPHA = 2_000_000, 0.1
x = np.sin(np.arange(N) / 1000) * 100 + 500
print(f"primera llamada (compila o lee el caché): {ms(lambda: ema(x, ALPHA)):7.1f} ms")
print(f"segunda llamada:                         {min(ms(lambda: ema(x, ALPHA)) for _ in range(3)):7.1f} ms")

series = np.tile(x, (8, 1))
ema_many(series, ALPHA)
one_by_one = min(ms(lambda: [ema(s, ALPHA) for s in series]) for _ in range(3))
parallel = min(ms(lambda: ema_many(series, ALPHA)) for _ in range(3))
print(f"8 series · una tras otra {one_by_one:6.1f} ms · prange en {os.cpu_count()} núcleos {parallel:6.1f} ms ({one_by_one / parallel:.1f}×)")


@njit
def total_with_generator(amounts):
    return sum(a for a in amounts)               # Python válido; numba no compila generadores aquí


@njit
def total_exact(amounts):
    total = Decimal(0)                           # un objeto de Python que numba no conoce
    for a in amounts:
        total += Decimal(a)
    return total


for fn in (total_with_generator, total_exact):
    try:
        fn(np.array([1.0, 2.0]))
    except NumbaError as error:
        reason = next(l for l in str(error).splitlines()[1:] if l.strip())
        print(f"{fn.__name__} no compila: {reason.strip()[:80]}")
