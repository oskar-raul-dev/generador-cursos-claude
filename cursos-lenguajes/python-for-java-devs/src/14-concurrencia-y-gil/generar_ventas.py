"""Genera el archivo de ventas del trimestre para conciliar.

Uso:  python generar_ventas.py
Produce data/ventas-2026-Q1.csv, 1.200.000 filas, ~27 MB.
"""

import random
from pathlib import Path

CODES = ["D8010", "D8020", "D2740", "D7140", "D1110", "D8670"]
VALUES = [75000, 95000, 120000, 180000, 210000, 890000]


def main() -> None:
    rng = random.Random(2026)
    Path("data").mkdir(exist_ok=True)
    target = Path("data") / "ventas-2026-Q1.csv"
    with target.open("w", encoding="utf-8") as file:
        file.write("documento,codigo,valor\n")
        for _ in range(1_200_000):
            file.write(f"{rng.randint(10_000_000, 1_299_999_999)},"
                       f"{rng.choice(CODES)},{rng.choice(VALUES)}\n")
    print(f"{target}: 1.200.000 filas · {target.stat().st_size / 1e6:.1f} MB")


if __name__ == "__main__":
    main()
