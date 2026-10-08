"""La segunda medición de la sección 6: el tiempo que de verdad espera Marcela.

    uv run --with pandas==3.0.5 --with polars==1.44.2 --with duckdb==1.5.5 \\
           python bench_punta_a_punta.py --datos data

`bench_engines.py` mide la consulta con el motor ya cargado, que es lo correcto para
comparar motores. Esto mide otra cosa: **lanzar el proceso, importar la dependencia,
consultar y salir**, que es lo que cuesta el informe mensual de Áurea en la vida real,
donde nadie tiene un intérprete caliente esperando.

Las dos mediciones son correctas y responden a preguntas distintas. Publicar solo la
primera sería el error que la Fase 17 del camino base cometió y documentó.

⚠️ **Cada motor se mide en un entorno donde solo está instalada su dependencia**, con
`--motor`. No es purismo: DuckDB carga pandas **durante la consulta** si pandas está
instalado —su mecanismo de sustitución de nombres lo busca— y eso le agrega 350 ms de
arranque que no son suyos. Medir los cuatro en el mismo entorno le carga a DuckDB el
precio de una dependencia que no usa. El efecto está medido y se publica.
"""

from __future__ import annotations

import argparse
import statistics
import subprocess
import sys
import time
from pathlib import Path

# El motor, el módulo que hay que importar y si lee Parquet. Se invoca por línea de
# comandos y no por `import`, porque el punto entero es medir el arranque.
END_TO_END = {
    "bucle": ("consolidate_loop", False),
    "pandas": ("consolidate_pandas", False),
    "polars (lazy)": ("consolidate_polars", False),
    "duckdb (parquet)": ("consolidate_duckdb_parquet", True),
}


def measure_process(function: str, directory: Path, repetitions: int) -> float:
    """Mediana del tiempo de pared de un proceso nuevo que responde la pregunta y sale."""
    code = (f"from pathlib import Path\n"
            f"from consolidation import {function}\n"
            f"rows = {function}(Path({str(directory)!r}))\n"
            f"assert rows\n")
    timings = []
    for _ in range(repetitions):
        started = time.perf_counter()
        subprocess.run([sys.executable, "-c", code], check=True, capture_output=True,
                       cwd=Path(__file__).parent)
        timings.append((time.perf_counter() - started) * 1000)
    return statistics.median(timings)


def main() -> None:
    parser = argparse.ArgumentParser(description="Punta a punta: proceso, import y consulta.")
    parser.add_argument("--datos", type=Path, default=Path("data"))
    parser.add_argument("--repeticiones", type=int, default=5)
    parser.add_argument("--tamanos", nargs="+",
                        default=["mes", "trimestre", "ano", "e1"])
    parser.add_argument("--motor", choices=sorted(END_TO_END),
                        help="Mide solo este. Es como se toma la tabla honesta: cada motor "
                             "en un entorno donde SOLO está instalada su dependencia.")
    args = parser.parse_args()

    engines = {args.motor: END_TO_END[args.motor]} if args.motor else END_TO_END
    print(f"{'motor':<18}" + "".join(f"{size:>12}" for size in args.tamanos))
    for engine, (function, parquet) in engines.items():
        cells = []
        for size in args.tamanos:
            directory = args.datos.resolve() / size
            if parquet:
                directory = directory / "parquet"
            cells.append(measure_process(function, directory, args.repeticiones))
        print(f"{engine:<18}" + "".join(f"{value:>9.0f} ms" for value in cells))


if __name__ == "__main__":
    main()
