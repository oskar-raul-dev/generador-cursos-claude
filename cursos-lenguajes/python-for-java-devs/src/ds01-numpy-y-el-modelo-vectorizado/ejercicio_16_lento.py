"""Ejercicio 16 — el costo por adquisición "vectorizado" que tarda una eternidad.

    uv run --with numpy==2.5.3 python ejercicio_16_lento.py --filas 2000000

Este script calcula lo mismo que `acquisition.py` y, sobre las mismas filas, da el mismo
resultado. Usa NumPy en todas partes. Y a dos millones de filas tarda **trece veces más
que el bucle** de la sección 5.2.

Tu trabajo: encontrar **las dos líneas** que lo arruinan y cuantificar cada una por
separado, con el arnés. No hay pistas en los comentarios, y es a propósito.
"""

from __future__ import annotations

import argparse
import time
from pathlib import Path

import numpy as np

from acquisition import read_acquisitions, read_spend_rows


def cost_per_acquisition_slow(rows: list[dict[str, str]],
                              acquisitions: dict[str, int]) -> dict[str, float]:
    channels = sorted({row["canal"] for row in rows})
    result: dict[str, float] = {}

    for channel in channels:
        if not acquisitions.get(channel):
            continue
        total = np.float64(0)
        for row in rows:
            value = np.array(int(row["costo_cop"])).astype(np.float64)
            if row["canal"] == channel:
                total += value
        result[channel] = float(total) / acquisitions[channel]

    return result


def main() -> None:
    parser = argparse.ArgumentParser(description="El lento del ejercicio 16.")
    parser.add_argument("--datos", type=Path, default=Path("data"))
    parser.add_argument("--filas", type=int, default=2_000_000)
    args = parser.parse_args()

    rows = read_spend_rows(args.datos / "pauta.csv")
    rows = (rows * (args.filas // len(rows) + 1))[:args.filas]
    acquisitions = read_acquisitions(args.datos / "leads.csv", args.datos / "etapas.csv")

    started = time.perf_counter()
    result = cost_per_acquisition_slow(rows, acquisitions)
    elapsed = (time.perf_counter() - started) * 1000

    for channel, value in sorted(result.items(), key=lambda item: -item[1]):
        print(f"{channel:12s} {value:>15,.0f} COP")
    print(f"\n{len(rows):,} filas · {elapsed:,.0f} ms")


if __name__ == "__main__":
    main()
