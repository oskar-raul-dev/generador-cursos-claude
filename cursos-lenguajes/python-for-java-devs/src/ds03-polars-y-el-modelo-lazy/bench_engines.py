"""Medición de la sección 6: la misma consolidación en cinco motores y cuatro tamaños.

    uv run --with pandas==3.0.5 --with polars==1.44.2 --with duckdb==1.5.5 \\
           python bench_engines.py --datos data

Antes hay que preparar los tamaños:

    uv run --with duckdb==1.5.5 python preparar_tamanos.py --salida data

Cada par motor×tamaño corre **en su propio proceso**, por la misma razón que en `ds02`: el
pico de memoria se mide con `ru_maxrss` del sistema operativo —`tracemalloc` no ve lo que
asignan pandas, Polars ni DuckDB— y esa marca de agua nunca baja. El proceso padre no
importa ninguno de los tres, así que la fila «solo importar» de cada motor es su línea base
honesta: **lo que cuesta la dependencia antes de leer un solo dato**.
"""

from __future__ import annotations

import argparse
import ast
import inspect
import json
import resource
import statistics
import subprocess
import sys
import time
from pathlib import Path

from consolidation import ENGINES, _duckdb_query

SIZES = ("mes", "e1", "e4", "e16")
ALL_SIZES = ("mes", "trimestre", "ano", "e1", "e4", "e16")

# Lo que hay que importar para que cada motor exista, y nada más. Sirve para la línea base
# de memoria: sin ella, el pico de cada motor incluiría el precio de estar cargado y las
# columnas no serían comparables entre sí.
IMPORTS = {
    "bucle": (),
    "pandas": ("pandas",),
    "polars (lazy)": ("polars",),
    "duckdb (csv)": ("duckdb",),
    "duckdb (parquet)": ("duckdb",),
}


# Qué funciones cuenta la columna de líneas de cada motor. Las dos variantes de DuckDB
# delegan su SQL en la misma auxiliar, y esa auxiliar es código que alguien mantiene.
FUNCTIONS_OF = {
    engine: ((function, _duckdb_query) if "duckdb" in engine else (function,))
    for engine, function in ENGINES.items()
}


def peak_rss_mb() -> float:
    """Pico de memoria residente, en MB. macOS reporta bytes y Linux kilobytes."""
    raw = resource.getrusage(resource.RUSAGE_SELF).ru_maxrss
    return raw / 1e6 if sys.platform == "darwin" else raw / 1e3


def effective_lines(engine: str) -> int:
    """Líneas de código efectivas del motor: sin blancos, sin comentarios y sin docstring.

    La sección 6 publica esta columna junto al tiempo porque **el tamaño del código es un
    costo real** —alguien lo mantiene— y porque sin ella la comparación premiaría al motor
    más rápido aunque costara tres veces más código. Contar líneas crudas habría premiado
    al que menos comenta, que es justo el incentivo contrario al de este curso.

    Las dos variantes de DuckDB suman la auxiliar donde vive el SQL. La primera versión de
    esta función no lo hacía y les daba **una y dos líneas**: un número halagador y falso,
    porque la consulta que alguien tiene que mantener son veintitantas líneas de SQL que
    estaban ahí igual. Contar solo lo que se ve es la forma más fácil de mentir en esta
    columna.
    """
    return sum(_lines_of(function) for function in FUNCTIONS_OF[engine])


def _lines_of(function) -> int:
    source = inspect.getsource(function)
    tree = ast.parse(source).body[0]
    body = tree.body[1:] if ast.get_docstring(tree) else tree.body
    if not body:
        return 0
    lines = source.splitlines()[body[0].lineno - tree.lineno:]
    return sum(1 for line in lines
               if line.strip() and not line.strip().startswith("#"))


def run_one(engine: str, data: Path, size: str, repetitions: int) -> dict:
    """Corre un motor sobre un tamaño, en este proceso, y devuelve sus números."""
    directory = data / size
    if "parquet" in engine:
        directory = directory / "parquet"

    function = ENGINES[engine]
    timings = []
    for _ in range(repetitions):
        started = time.perf_counter()
        rows = function(directory)
        timings.append((time.perf_counter() - started) * 1000)
    timings.sort()

    return {
        "motor": engine, "tamano": size,
        "mediana_ms": statistics.median(timings),
        "p95_ms": timings[max(0, int(len(timings) * 0.95) - 1)],
        "pico_rss_mb": peak_rss_mb(),
        "filas": len(rows),
        "lineas": effective_lines(engine),
    }


def run_baseline(engine: str) -> dict:
    """Lo que pesa el motor **antes** de leer nada: importarlo y parar."""
    for module in IMPORTS[engine]:
        __import__(module)
    return {"motor": engine, "tamano": "—", "mediana_ms": 0.0, "p95_ms": 0.0,
            "pico_rss_mb": peak_rss_mb(), "filas": 0,
            "lineas": effective_lines(engine)}


def main() -> None:
    parser = argparse.ArgumentParser(description="Cinco motores, cuatro tamaños.")
    parser.add_argument("--datos", type=Path, default=Path("data"))
    parser.add_argument("--repeticiones", type=int, default=5)
    parser.add_argument("--motor", choices=sorted(ENGINES))
    parser.add_argument("--tamano", choices=[*ALL_SIZES, "linea-base"])
    args = parser.parse_args()

    if args.motor and args.tamano:
        result = (run_baseline(args.motor) if args.tamano == "linea-base"
                  else run_one(args.motor, args.datos, args.tamano, args.repeticiones))
        print(json.dumps(result))
        return

    results = []
    for engine in ENGINES:
        for size in ("linea-base", *SIZES):
            # A dieciséis veces la escala, el bucle de Python tarda lo suyo y no hace falta
            # repetirlo cinco veces para saberlo: la dispersión de las corridas anteriores
            # ya dice que el reloj es estable. Se baja a dos y **se declara**.
            repetitions = 2 if size == "e16" and engine == "bucle" else args.repeticiones
            completed = subprocess.run(
                [sys.executable, __file__, "--motor", engine, "--tamano", size,
                 "--datos", str(args.datos), "--repeticiones", str(repetitions)],
                check=True, capture_output=True, text=True)
            results.append(json.loads(completed.stdout))

    print(f"{'motor':<18}{'líneas':>8}{'importar':>11}"
          + "".join(f"{size:>12}" for size in SIZES))
    for engine in ENGINES:
        rows = {result["tamano"]: result for result in results
                if result["motor"] == engine}
        line = f"{engine:<18}{rows['—']['lineas']:>8}{rows['—']['pico_rss_mb']:>8.0f} MB"
        line += "".join(f"{rows[size]['mediana_ms']:>9.1f} ms" for size in SIZES)
        print(line)

    print(f"\n{'motor':<18}" + "".join(f"{'RSS ' + size:>12}" for size in SIZES))
    for engine in ENGINES:
        rows = {result["tamano"]: result for result in results
                if result["motor"] == engine}
        print(f"{engine:<18}"
              + "".join(f"{rows[size]['pico_rss_mb']:>9.0f} MB" for size in SIZES))

    print()
    for size in SIZES:
        sample = next(r for r in results if r["tamano"] == size)
        print(f"{size}: {sample['filas']} filas de salida")


if __name__ == "__main__":
    main()
