"""La misma función en Rust (PyO3), C++ (pybind11) y C++ (nanobind), llamada desde Python y medida."""

import time

import numpy as np
import ema_nb
import ema_pb
import ema_rs


def ema_python(x, alpha):
    out, s = [], x[0]
    for v in x:
        s = alpha * v + (1 - alpha) * s
        out.append(s)
    return np.array(out)


N, ALPHA = 2_000_000, 0.1
x = np.sin(np.arange(N) / 1000) * 100 + 500
reference = ema_python(x.tolist(), ALPHA)
one = x[:1]
for name, module in (("PyO3", ema_rs), ("pybind11", ema_pb), ("nanobind", ema_nb)):
    times = []
    for _ in range(5):
        start = time.perf_counter(); result = module.ema(x, ALPHA); times.append(time.perf_counter() - start)
    start = time.perf_counter()
    for _ in range(100_000):
        module.ema(one, ALPHA)
    per_call = (time.perf_counter() - start) * 10                         # µs por llamada
    print(f"{name:<9} {min(times) * 1000:4.1f} ms · llamada con un elemento {per_call:4.2f} µs"
          f" · diferencia con Python {np.abs(result - reference).max():.1e}")
