"""El mismo bucle de Python puro, cinco rondas: para ver el arranque y el calentamiento del JIT."""

import platform
import sys
import time


def royalties(n: int) -> int:
    total = 0
    for i in range(n):
        sales = 100_000_000 + (i * 7919) % 50_000_000
        total += (sales * 450 + 5_000) // 10_000
    return total


print(platform.python_implementation(), sys.version.split()[0])
for round_ in range(1, 6):
    start = time.perf_counter()
    result = royalties(2_000_000)
    print(f"  ronda {round_}: {time.perf_counter() - start:.3f} s  ({result})")
