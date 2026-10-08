"""Cuatro tareas de Python puro: secuencial, hilos, procesos y subintérpretes, con y sin GIL."""

import os
import sys
import time
from concurrent.futures import InterpreterPoolExecutor, ProcessPoolExecutor, ThreadPoolExecutor


def work(seed):
    """Suavizado de una serie pseudoaleatoria generada en el momento: CPU pura, sin E/S ni NumPy."""
    s, x = 0.0, seed
    for _ in range(2_000_000):
        x = (x * 1103515245 + 12345) % 2**31
        s = 0.1 * x + 0.9 * s
    return s


def run(label, executor_cls=None):
    seeds = [1, 2, 3, 4]
    start = time.perf_counter()
    if executor_cls is None:
        results = [work(s) for s in seeds]
    else:
        with executor_cls(max_workers=4) as pool:
            results = list(pool.map(work, seeds))
    elapsed = time.perf_counter() - start
    return label, elapsed, results


if __name__ == "__main__":
    build = "sin GIL (3.14t)" if not sys._is_gil_enabled() else "con GIL"
    rows = [run("secuencial"), run("hilos", ThreadPoolExecutor), run("procesos", ProcessPoolExecutor),
            run("subintérpretes", InterpreterPoolExecutor)]
    base = rows[0][1]
    assert all(r[2] == rows[0][2] for r in rows)
    print(f"Python {sys.version.split()[0]} {build}, {os.cpu_count()} núcleos")
    for label, elapsed, _ in rows:
        print(f"  {label:<15} {elapsed:5.2f} s · {base / elapsed:4.2f}×")
