"""Las cuatro formas, sobre las dos cargas. Corre con python3.14 y con python3.14t."""
import concurrent.futures as cf
import os
import statistics
import sys
import time
from pathlib import Path

from carga import io_chunk, reconcile_chunk

WORKERS = 4
ROWS = 300_000          # subconjunto para que cada corrida dure segundos, no minutos


def load_rows(n: int) -> list[tuple[str, str, str]]:
    rows = []
    with open("data/ventas-2026-Q1.csv", encoding="utf-8") as f:
        next(f)
        for i, line in enumerate(f):
            if i >= n:
                break
            document, code, amount = line.rstrip("\n").split(",")
            rows.append((document, code, amount))
    return rows


def chunks(rows, n):
    size = len(rows) // n
    return [rows[i * size:(i + 1) * size if i < n - 1 else None] for i in range(n)]


def bench(fn, reps=3):
    fn()
    xs = []
    for _ in range(reps):
        t0 = time.perf_counter()
        fn()
        xs.append(time.perf_counter() - t0)
    xs.sort()
    return statistics.median(xs)


def main() -> None:
    gil = sys._is_gil_enabled() if hasattr(sys, "_is_gil_enabled") else True
    print(f"=== {sys.version.split()[0]} · GIL {'activo' if gil else 'DESACTIVADO'} "
          f"· {os.cpu_count()} núcleos · {WORKERS} trabajadores ===")

    rows = load_rows(ROWS)
    parts = chunks(rows, WORKERS)

    def cpu_secuencial():
        return [reconcile_chunk(p) for p in parts]

    def cpu_hilos():
        with cf.ThreadPoolExecutor(WORKERS) as ex:
            return list(ex.map(reconcile_chunk, parts))

    def cpu_procesos():
        with cf.ProcessPoolExecutor(WORKERS) as ex:
            return list(ex.map(reconcile_chunk, parts))

    io_parts = [25] * WORKERS      # 25 esperas de 10 ms por trabajador

    def io_secuencial():
        return [io_chunk(p) for p in io_parts]

    def io_hilos():
        with cf.ThreadPoolExecutor(WORKERS) as ex:
            return list(ex.map(io_chunk, io_parts))

    def io_procesos():
        with cf.ProcessPoolExecutor(WORKERS) as ex:
            return list(ex.map(io_chunk, io_parts))

    print(f"\n{'CPU (conciliar 300.000 filas)':<34}{'mediana':>12}{'aceleración':>14}")
    base = bench(cpu_secuencial)
    print(f"{'secuencial':<34}{base:>10.2f} s{'1.00×':>14}")
    for name, fn in [("hilos", cpu_hilos), ("procesos", cpu_procesos)]:
        t = bench(fn)
        print(f"{name:<34}{t:>10.2f} s{base/t:>13.2f}×")

    print(f"\n{'E/S (100 esperas de 10 ms)':<34}{'mediana':>12}{'aceleración':>14}")
    base_io = bench(io_secuencial)
    print(f"{'secuencial':<34}{base_io:>10.2f} s{'1.00×':>14}")
    for name, fn in [("hilos", io_hilos), ("procesos", io_procesos)]:
        t = bench(fn)
        print(f"{name:<34}{t:>10.2f} s{base_io/t:>13.2f}×")


if __name__ == "__main__":
    main()
