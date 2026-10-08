"""Genera las 200 facturas XML del mes, para el firmador.

Uso:  python generar_facturas.py
"""

import random
from pathlib import Path


def main() -> None:
    random.seed(2026)
    folder = Path("facturas")
    folder.mkdir(exist_ok=True)
    for number in range(200):
        nit = str(random.randint(100_000_000, 999_999_999))
        value = random.randint(50_000, 900_000)
        (folder / f"fac-{number:04d}.xml").write_text(
            f"<factura><nit>{nit}</nit><valor>{value}</valor></factura>\n",
            encoding="utf-8",
        )
    print(f"200 facturas en {folder}/")


if __name__ == "__main__":
    main()
