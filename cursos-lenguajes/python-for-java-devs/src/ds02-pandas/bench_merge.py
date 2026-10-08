"""Medición de la sección 6: el mismo informe, unido y agregado en tres órdenes distintos.

    uv run --with pandas==3.0.5 python bench_merge.py --datos data

Cada variante corre **en su propio proceso**, y esa es la decisión metodológica de esta
medición. `tracemalloc` —el arnés de la Fase 02— solo ve lo que asigna el asignador de
Python, y pandas 3.0 guarda las cadenas en búferes de Arrow que viven fuera de él: medir
con `tracemalloc` aquí daría un número bonito y falso. Lo que se reporta es el **pico de RSS
del proceso**, que es lo que ve el sistema operativo y lo que se llena cuando el informe de
Marcela se queda sin memoria en la máquina virtual de dos núcleos.

El arnés no se reemplaza: se amplía. `measure` sigue dando el tiempo; el pico lo da
`resource.getrusage` del hijo.
"""

from __future__ import annotations

import argparse
import json
import resource
import statistics
import subprocess
import sys
import time
from pathlib import Path

from collections_report import (
    collected_lean,
    collected_naive,
    collected_vectorized,
    frame_memory_mb,
    read_installments,
    read_plans,
)

VARIANTS = {
    "unir+apply": (collected_naive, False),
    "unir+mascara": (collected_vectorized, False),
    "agregar+unir": (collected_lean, True),
}


def peak_rss_mb() -> float:
    """Pico de memoria residente del proceso, en MB.

    `ru_maxrss` es una marca de agua alta: nunca baja. Por eso hace falta un proceso por
    variante — dentro del mismo proceso, la segunda mediría el pico de la primera.
    En macOS viene en bytes y en Linux en kilobytes, y esa diferencia ha arruinado más de
    una tabla de benchmarks publicada.
    """
    raw = resource.getrusage(resource.RUSAGE_SELF).ru_maxrss
    return raw / 1e6 if sys.platform == "darwin" else raw / 1e3


def run_one(name: str, data: Path, repetitions: int) -> dict:
    """Corre una variante en este proceso y devuelve sus números."""
    if name == "solo importar":
        # La línea base de memoria. Sin esta fila, las otras tres parecen gastar cien megas
        # y en realidad gastan lo que gastan MENOS esto: importar pandas ya cuesta, y quien
        # publique la columna de RSS sin descontarlo está contando el intérprete dos veces.
        return {"etiqueta": name, "mediana_ms": 0.0, "p95_ms": 0.0,
                "pico_rss_mb": peak_rss_mb(), "entrada_mb": 0.0,
                "filas_entrada": 0, "filas_salida": 0, "repeticiones": 0}

    function, lean = VARIANTS[name]
    plans = read_plans(data / "planes_de_tratamiento.csv", lean=lean)
    installments = read_installments(data / "cuotas.csv", lean=lean)

    timings = []
    for _ in range(repetitions):
        started = time.perf_counter()
        result = function(plans, installments)
        timings.append((time.perf_counter() - started) * 1000)
    timings.sort()

    return {
        "etiqueta": name,
        "mediana_ms": statistics.median(timings),
        "p95_ms": timings[max(0, int(len(timings) * 0.95) - 1)],
        "pico_rss_mb": peak_rss_mb(),
        "entrada_mb": frame_memory_mb(plans) + frame_memory_mb(installments),
        "filas_entrada": len(installments),
        "filas_salida": len(result),
        "repeticiones": repetitions,
    }


def main() -> None:
    parser = argparse.ArgumentParser(description="Tres órdenes de unir y agregar.")
    parser.add_argument("--datos", type=Path, default=Path("data"))
    parser.add_argument("--repeticiones", type=int, default=5)
    parser.add_argument("--variante", choices=[*sorted(VARIANTS), "solo importar"],
                        help="Corre solo esta, en este proceso, y escupe JSON. Es como se "
                             "invoca a sí mismo: no está pensado para escribirse a mano.")
    args = parser.parse_args()

    if args.variante:
        print(json.dumps(run_one(args.variante, args.datos, args.repeticiones)))
        return

    # El proceso padre no importa pandas hasta aquí, así que su propio RSS no contamina
    # nada: lo único que hace es lanzar tres hijos y leer su JSON.
    results = []
    for name in ("solo importar", *VARIANTS):
        completed = subprocess.run(
            [sys.executable, __file__, "--variante", name,
             "--datos", str(args.datos), "--repeticiones", str(args.repeticiones)],
            check=True, capture_output=True, text=True)
        results.append(json.loads(completed.stdout))

    header = f"{'variante':<16}{'mediana':>12}{'p95':>12}{'pico RSS':>12}{'entrada':>12}"
    print(header)
    for result in results:
        print(f"{result['etiqueta']:<16}{result['mediana_ms']:>9.1f} ms"
              f"{result['p95_ms']:>9.1f} ms{result['pico_rss_mb']:>9.1f} MB"
              f"{result['entrada_mb']:>9.1f} MB")
    baseline = results[0]["pico_rss_mb"]
    print(f"\nLa fila «solo importar» es la línea base: {baseline:.1f} MB los gasta pandas "
          f"por existir, y hay que descontarlos de las otras tres.")
    print(f"{results[1]['filas_entrada']:,} cuotas de entrada · "
          f"{results[1]['filas_salida']} filas de salida · "
          f"{results[1]['repeticiones']} repeticiones por variante")


if __name__ == "__main__":
    main()
