"""El suavizado en Python y en cuatro pasos de Cython: tiempo, exactitud y cuánto Python queda en el cálculo."""

import array
import math
import re
import subprocess
import time

subprocess.run(["cythonize", "-q", "-i", "-3", "-a", "ema_v0.pyx", "ema_v1.pyx", "ema_v2.pyx", "ema_v3.pyx"],
               check=True, capture_output=True)
import ema_v0, ema_v1, ema_v2, ema_v3  # noqa: E401  — compilados recién


def ema_python(x, alpha):
    out, s = [0.0] * len(x), x[0]
    for i, v in enumerate(x):
        s = alpha * v + (1 - alpha) * s
        out[i] = s
    return out


N, ALPHA = 2_000_000, 0.1
x = array.array("d", (math.sin(i / 1000) * 100 + 500 for i in range(N)))
reference = ema_python(x, ALPHA)
for name, fn in (("Python", ema_python), ("Cython paso 0", ema_v0.ema), ("Cython paso 1", ema_v1.ema),
                 ("Cython paso 2", ema_v2.ema), ("Cython paso 3", ema_v3.ema)):
    times = []
    for _ in range(3):
        start = time.perf_counter(); fn(x, ALPHA); times.append(time.perf_counter() - start)
    best = min(times)
    diff = max(abs(a - b) for a, b in zip(fn(x, ALPHA), reference))
    module = name.replace("Cython paso ", "ema_v")
    note = ""
    if module != "Python":
        html = open(f"{module}.html", encoding="utf-8").read()
        score = re.search(r'score-(\d+)"[^\n]*s = alpha', html).group(1)
        note = f" · interacciones con Python en la línea del cálculo: {score}"
    print(f"{name:<14} {best * 1000:7.1f} ms · diferencia máx. {diff:.1e}{note}")
