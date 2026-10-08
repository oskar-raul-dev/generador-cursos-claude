"""Genera las derivaciones a aliados del primer trimestre de 2026.

Uso:  python generar_derivaciones.py
Produce data/derivaciones-2026-Q1.csv con semilla fija.
"""

import random
from datetime import date, timedelta
from pathlib import Path

SPECIALTIES = ["periodoncia", "implantologia", "endodoncia", "cirugia"]
BRANCHES = ["Centro", "Chapinero", "Suba", "Kennedy", "Usaquen",
            "Engativa", "Fontibon", "Restrepo", "Soacha", "Zipaquira"]
VALUES = [450000, 800000, 1200000, 1800000, 2400000, 3200000, 4800000]


def main() -> None:
    random.seed(2026)
    Path("data").mkdir(exist_ok=True)
    partners = [f"P{n:03d}" for n in range(1, 24)]

    rows = []
    start = date(2026, 1, 1)
    for _ in range(1400):
        partner = random.choice(partners)
        day = start + timedelta(days=random.randint(0, 89))
        rows.append(
            f"{partner},{random.choice(BRANCHES)},{day.isoformat()},"
            f"{random.choice(SPECIALTIES)},{random.choice(VALUES)}"
        )

    target = Path("data") / "derivaciones-2026-Q1.csv"
    target.write_text(
        "aliado,sede,fecha,especialidad,valor_tratamiento\n" + "\n".join(rows) + "\n",
        encoding="utf-8",
    )
    print(f"{target}: {len(rows)} derivaciones")


if __name__ == "__main__":
    main()
