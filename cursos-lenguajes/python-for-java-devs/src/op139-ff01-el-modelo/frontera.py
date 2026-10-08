"""Dónde está la frontera con C: qué ya es nativo, cuánto cuesta el bucle, y quién suelta el GIL."""

import hashlib
import pathlib
import sys
import threading
import time

import numpy as np

# 1) Lo que ya es C sin que nadie lo dijera
core = pathlib.Path(np.__file__).parent
print("numpy: archivos .py", len(list(core.rglob("*.py"))), "· extensiones .so", len(list(core.rglob("*.so"))))
print("el corazón de numpy:", pathlib.Path(np._core._multiarray_umath.__file__).name)
import json.decoder
print("json usa su acelerador en C:", json.decoder.scanstring.__module__)

# 2) El mismo cálculo a los dos lados de la frontera
values = [i * 0.001 for i in range(5_000_000)]
array = np.array(values)
def best(fn, n=3):
    times = []
    for _ in range(n):
        start = time.perf_counter(); fn(); times.append(time.perf_counter() - start)
    return min(times) * 1000
def loop():
    total = 0.0
    for v in values:
        total += v * v
    return total
print(f"suma de cuadrados, 5M · bucle {best(loop):6.1f} ms · sum() {best(lambda: sum(v * v for v in values)):6.1f} ms"
      f" · numpy {best(lambda: float(array @ array)):5.1f} ms")

# 3) El GIL: quién lo suelta
def pure(): 
    x = 0
    for i in range(3_000_000):
        x += i
blob = b"x" * 64_000_000
def native():
    hashlib.sha256(blob).digest()
def speedup(work, threads=4):
    start = time.perf_counter()
    for _ in range(threads):
        work()
    sequential = time.perf_counter() - start
    start = time.perf_counter()
    pool = [threading.Thread(target=work) for _ in range(threads)]
    for t in pool: t.start()
    for t in pool: t.join()
    return sequential / (time.perf_counter() - start)
print(f"GIL activo: {sys._is_gil_enabled()} · 4 hilos, Python puro: {speedup(pure):.2f}× · 4 hilos, sha256 en C: {speedup(native):.2f}×")
