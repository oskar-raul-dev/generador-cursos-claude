"""Genera el archivo de citas del primer trimestre de 2026 de toda la red.

Uso:  python generar_citas.py
Produce data/citas-2026-Q1.csv, unas 500.000 filas, con semilla fija.
Es el archivo grande del curso: las fases 02, 06, 14, 15 y 16 lo usan.
"""

import random
from datetime import date, timedelta
from pathlib import Path

BRANCHES = ["Centro", "Chapinero", "Suba", "Kennedy", "Usaquen",
            "Engativa", "Fontibon", "Restrepo", "Soacha", "Zipaquira"]
STATUSES = ["asistio", "no_show", "cancelada", "reprogramada"]
WEIGHTS = [76, 19, 3, 2]          # el 19% de inasistencia es dato del dominio
CODES = ["D8010", "D8020", "D2740", "D7140", "D1110", "D8670"]


def main() -> None:
    random.seed(2026)
    Path("data").mkdir(exist_ok=True)
    target = Path("data") / "citas-2026-Q1.csv"

    start = date(2026, 1, 1)
    with target.open("w", encoding="utf-8", newline="\n") as file:
        file.write("documento,sede,fecha,hora,estado,codigo,valor\n")
        rows = 0
        for day_offset in range(90):
            day = start + timedelta(days=day_offset)
            if day.weekday() == 6:          # domingo no se atiende
                continue
            for branch in BRANCHES:
                for _ in range(random.randint(550, 700)):
                    document = random.randint(10_000_000, 1_299_999_999)
                    hour = random.randint(7, 18)
                    minute = random.choice((0, 20, 40))
                    status = random.choices(STATUSES, WEIGHTS)[0]
                    code = random.choice(CODES)
                    value = random.choice((75000, 95000, 120000, 180000, 210000, 890000))
                    file.write(f"{document},{branch},{day.isoformat()},"
                               f"{hour:02d}:{minute:02d},{status},{code},{value}\n")
                    rows += 1
    size_mb = target.stat().st_size / 1e6
    print(f"{target}: {rows:,} filas · {size_mb:.1f} MB")


if __name__ == "__main__":
    main()
