"""Medición de la sección 6: la misma cuenta en bucle, en comprehension y vectorizada.

    uv run python bench_vectorized.py --filas 1000 100000 5000000

Usa el arnés de la Fase 02 —mediana, p95 y pico de memoria con `tracemalloc`—, que tiene
que estar junto a este archivo.

⚠️ **Los tamaños por encima de la pauta real son el dato de Áurea repetido en bloque.** La
red tiene ~49.000 filas de pauta; lo que se mide a 100.000 y a 5.000.000 es **el motor, no
el negocio**. Repetir el bloque no cambia el reparto por canal —la cuenta da lo mismo— y sí
da el tamaño que hace falta para encontrar el umbral. Inventar tres años más de historia de
una empresa que no los tiene habría sido la otra opción, y es peor: mentir sobre el dominio
para ganar una fila de tabla.
"""

from __future__ import annotations

import argparse
from pathlib import Path

from acquisition import (
    arrays_from_rows,
    cost_per_acquisition_comprehension,
    cost_per_acquisition_loop,
    cost_per_acquisition_vectorized,
    read_acquisitions,
    read_spend_rows,
)

try:
    from bench import environment, measure
except ModuleNotFoundError:
    raise SystemExit(
        "Falta `bench.py`, el arnés del curso. Es el mismo de la Fase 02: cópialo junto a "
        "este archivo con `cp ../02-secuencias-perezosas/bench.py .`"
    ) from None


def render_table(results: list[dict]) -> str:
    """La tabla de esta sección, con tres decimales de milisegundo.

    El `render` del arnés imprime milisegundos enteros, que es lo correcto para la Fase 02
    —donde lo que se mide tarda segundos— y aquí dejaría una columna de ceros: a mil filas
    las tres versiones están por debajo del milisegundo. Se extiende el formato, **no el
    arnés**: `measure` sigue siendo el mismo y los números siguen siendo comparables con los
    del resto del curso.
    """
    lines = [f"{'opción':<16}{'mediana':>12}{'p95':>12}{'pico':>11}"]
    for result in results:
        lines.append(
            f"{result['etiqueta']:<16}{result['mediana_ms']:>9.3f} ms"
            f"{result['p95_ms']:>9.3f} ms{result['pico_mb']:>8.2f} MB")
    return "\n".join(lines)


def tile_rows(rows: list[dict[str, str]], size: int) -> list[dict[str, str]]:
    """Repite las filas reales hasta llegar al tamaño pedido, y recorta.

    ⚠️ Lo que repite son **referencias al mismo diccionario**, no copias. Por eso la
    columna de memoria de la tabla mide lo que asigna el cálculo, no lo que ocupa tener los
    datos: tener cinco millones de filas de verdad en memoria cuesta gigas, y ese costo es
    el tema de `ds02`, no de esta sección.
    """
    if size <= len(rows):
        return rows[:size]
    repeats = size // len(rows) + 1
    return (rows * repeats)[:size]


def main() -> None:
    parser = argparse.ArgumentParser(description="Bucle contra vectorizado, por tamaño.")
    parser.add_argument("--datos", type=Path, default=Path("data"))
    parser.add_argument("--filas", type=int, nargs="+",
                        default=[1_000, 100_000, 5_000_000])
    parser.add_argument("--repeticiones", type=int, default=5)
    parser.add_argument("--sin-comprehension", action="store_true",
                        help="Sáltate la comprehension, que a tamaños grandes domina el reloj.")
    args = parser.parse_args()

    base_rows = read_spend_rows(args.datos / "pauta.csv")
    acquisitions = read_acquisitions(args.datos / "leads.csv", args.datos / "etapas.csv")
    print(f"Entorno: {environment()}")
    print(f"Pauta real: {len(base_rows):,} filas · "
          f"adquisiciones por canal: {acquisitions}\n")

    for size in args.filas:
        rows = tile_rows(base_rows, size)
        # Las columnas se construyen desde las MISMAS filas, no desde otra lectura del CSV:
        # si cada versión partiera de datos distintos, la comparación no diría nada.
        spend = arrays_from_rows(rows)

        repetitions = args.repeticiones if size <= 1_000_000 else max(3, args.repeticiones // 2)
        # Los `rows=rows` de las lambdas no son adorno: sin ellos, cada lambda cerraría sobre
        # la variable del bucle y no sobre su valor, y `ruff` lo marca (B023). Aquí daría igual
        # porque `measure` las llama en el acto, pero el día que alguien guarde la lista de
        # lambdas para correrlas después, las cuatro medirían el último tamaño.
        results = [
            measure("bucle",
                    lambda rows=rows: cost_per_acquisition_loop(rows, acquisitions),
                    repetitions),
            # Las dos filas vectorizadas son la parte honesta de esta tabla. La primera
            # asume que los datos YA están en columnas; la segunda paga la conversión desde
            # la lista de diccionarios, que es de donde salen de verdad cuando vienen de un
            # CSV. Publicar solo la primera sería comparar una función contra un programa.
            measure("vectorizado",
                    lambda spend=spend: cost_per_acquisition_vectorized(spend, acquisitions),
                    repetitions),
            measure("vectorizado+conv",
                    lambda rows=rows: cost_per_acquisition_vectorized(
                        arrays_from_rows(rows), acquisitions),
                    repetitions),
        ]
        if not args.sin_comprehension:
            results.insert(1, measure(
                "comprehension",
                lambda rows=rows: cost_per_acquisition_comprehension(rows, acquisitions),
                repetitions))

        # La comprobación que vuelve honesta a la tabla: si las tres no coinciden, los
        # tiempos no son comparables y el número de arriba no significa nada.
        assert_same_answer(rows, spend, acquisitions)

        print(f"--- {size:,} filas · {repetitions} repeticiones ---")
        print(render_table(results))
        print()


def assert_same_answer(rows, spend, acquisitions) -> None:
    loop = cost_per_acquisition_loop(rows, acquisitions)
    vector = cost_per_acquisition_vectorized(spend, acquisitions)
    for channel, value in loop.items():
        # Tolerancia relativa de una parte en mil millones: el bucle acumula en `int` de
        # Python y el vectorizado en `float64`, así que exigir igualdad exacta sería exigir
        # que dos aritméticas distintas dieran lo mismo, que es otra lección y no esta.
        assert abs(value - vector[channel]) <= abs(value) * 1e-9, channel


if __name__ == "__main__":
    main()
