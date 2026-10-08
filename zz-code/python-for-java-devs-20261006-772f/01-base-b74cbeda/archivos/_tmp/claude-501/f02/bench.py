"""El arnés de medición del curso. Biblioteca estándar, y nada más.

Tres responsabilidades y ninguna más: cronometrar con reloj monótono y
repeticiones, medir el pico de memoria, y declarar el entorno.

Uso:
    from bench import measure, environment
    print(environment())
    print(measure("tubería perezosa", lambda: report(path)))
"""

import platform
import statistics
import sys
import time
import tracemalloc
from collections.abc import Callable
from typing import Any


def environment() -> str:
    """Sin esto, un número no es reproducible y por lo tanto no es un número."""
    return (
        f"{platform.python_implementation()} {platform.python_version()} · "
        f"{platform.system()} {platform.release()} · {platform.machine()}"
    )


def measure(label: str, work: Callable[[], Any], repetitions: int = 5) -> dict[str, Any]:
    """Ejecuta `work` varias veces y devuelve tiempos y pico de memoria.

    Se reportan mediana y percentil 95, nunca el promedio solo: el promedio
    esconde la cola, que es justo lo que importa cuando algo se degrada.
    El pico de memoria se mide en una corrida aparte, porque tracemalloc
    distorsiona el tiempo.
    """
    timings: list[float] = []
    for _ in range(repetitions):
        started = time.perf_counter()
        work()
        timings.append((time.perf_counter() - started) * 1000)
    timings.sort()

    tracemalloc.start()
    work()
    _, peak = tracemalloc.get_traced_memory()
    tracemalloc.stop()

    return {
        "etiqueta": label,
        "mediana_ms": statistics.median(timings),
        "p95_ms": timings[max(0, int(len(timings) * 0.95) - 1)],
        "pico_mb": peak / 1e6,
        "repeticiones": repetitions,
    }


def render(results: list[dict[str, Any]]) -> str:
    """La tabla, lista para pegar en el documento de la fase."""
    lines = [f"Entorno: {environment()}", ""]
    lines.append(f"{'opción':<28}{'mediana':>12}{'p95':>12}{'pico':>12}")
    for result in results:
        lines.append(
            f"{result['etiqueta']:<28}{result['mediana_ms']:>10.0f} ms"
            f"{result['p95_ms']:>10.0f} ms{result['pico_mb']:>9.1f} MB"
        )
    return "\n".join(lines)


if __name__ == "__main__":
    print(environment(), file=sys.stderr)
