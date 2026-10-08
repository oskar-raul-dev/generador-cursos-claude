"""Medición de la sección 6: lo que cuesta producir el mismo tablero de cuatro formas.

    uv run --with matplotlib==3.11.2 python bench_render.py --opcion matplotlib
    uv run --with plotly==7.0.0 python bench_render.py --opcion plotly
    uv run --with altair==6.2.2 python bench_render.py --opcion altair
    uv run python bench_render.py --opcion tabla

**Cada opción se mide en un entorno donde solo está instalada su dependencia**, por lo que
descubrió `ds03`: una biblioteca puede importar otra si la encuentra, y entonces la tabla le
cobra a una el arranque de la otra.

Lo que se mide es de punta a punta —proceso, import, render y salida—, porque el tablero de
Marcela se genera una vez al mes desde un proceso frío, no dentro de un servidor caliente.

⚠️ **Esta medición no dice cuál se entiende mejor.** Eso lo mide el protocolo de la sección
6.2, que necesita cinco personas y está en `⏳`.
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

from dashboard import RENDERERS

EXTENSION = {"tabla": ".txt", "matplotlib": ".png", "plotly": ".html", "altair": ".html"}


def peak_rss_mb() -> float:
    raw = resource.getrusage(resource.RUSAGE_SELF).ru_maxrss
    return raw / 1e6 if sys.platform == "darwin" else raw / 1e3


def effective_lines(option: str) -> int:
    """Líneas de código efectivas del renderizador: sin blancos, comentarios ni docstring."""
    source = inspect.getsource(RENDERERS[option])
    tree = ast.parse(source).body[0]
    body = tree.body[1:] if ast.get_docstring(tree) else tree.body
    lines = source.splitlines()[body[0].lineno - tree.lineno:]
    return sum(1 for line in lines if line.strip() and not line.strip().startswith("#"))


def run_one(option: str, target: Path, repetitions: int) -> dict:
    renderer = RENDERERS[option]
    timings = []
    for _ in range(repetitions):
        started = time.perf_counter()
        if option == "tabla":
            target.write_text(renderer(), encoding="utf-8")
        else:
            renderer(target=target)
        timings.append((time.perf_counter() - started) * 1000)
    timings.sort()
    return {
        "opcion": option,
        "mediana_ms": statistics.median(timings),
        "p95_ms": timings[max(0, int(len(timings) * 0.95) - 1)],
        "pico_rss_mb": peak_rss_mb(),
        "salida_kb": target.stat().st_size / 1024,
        "lineas": effective_lines(option),
    }


def cold_start_ms(option: str, repetitions: int = 5) -> float:
    """Proceso nuevo que importa lo que necesita, dibuja y sale."""
    code = (f"from pathlib import Path\nfrom dashboard import RENDERERS\n"
            f"r = RENDERERS[{option!r}]\n"
            + (f"Path('salida/frio{EXTENSION[option]}').write_text(r(), encoding='utf-8')\n"
               if option == "tabla"
               else f"r(target=Path('salida/frio{EXTENSION[option]}'))\n"))
    timings = []
    for _ in range(repetitions):
        started = time.perf_counter()
        subprocess.run([sys.executable, "-c", code], check=True, capture_output=True,
                       cwd=Path(__file__).parent)
        timings.append((time.perf_counter() - started) * 1000)
    return statistics.median(timings)


def main() -> None:
    parser = argparse.ArgumentParser(description="Cuatro formas del mismo tablero.")
    parser.add_argument("--opcion", choices=sorted(RENDERERS), required=True)
    parser.add_argument("--salida", type=Path, default=Path("salida"))
    parser.add_argument("--repeticiones", type=int, default=5)
    args = parser.parse_args()

    args.salida.mkdir(parents=True, exist_ok=True)
    target = args.salida / f"{args.opcion}{EXTENSION[args.opcion]}"

    result = run_one(args.opcion, target, args.repeticiones)
    result["frio_ms"] = cold_start_ms(args.opcion)
    print(json.dumps(result, ensure_ascii=False))
    print(f"{result['opcion']:<12} render {result['mediana_ms']:>8.1f} ms · "
          f"frío {result['frio_ms']:>8.1f} ms · RSS {result['pico_rss_mb']:>6.0f} MB · "
          f"salida {result['salida_kb']:>8.1f} KB · {result['lineas']:>2} líneas",
          file=sys.stderr)


if __name__ == "__main__":
    main()
