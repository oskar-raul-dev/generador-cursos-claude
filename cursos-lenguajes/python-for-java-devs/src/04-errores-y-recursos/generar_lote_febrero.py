"""Genera el lote de febrero con sus errores sembrados.

Uso:  python generar_lote_febrero.py
Produce data/lote-2026-02.csv con 6.001 filas y 106 problemas repartidos en
siete clases: 105 que se ven fila por fila y uno que solo se ve mirando el lote.
"""

import random
from pathlib import Path

BRANCHES = ["Centro", "Chapinero", "Suba", "Kennedy", "Usaquen",
            "Engativa", "Fontibon", "Restrepo", "Soacha", "Zipaquira"]
CODES = ["D8010", "D8020", "D2740", "D7140", "D1110", "D8670"]
VALUES = [75000, 95000, 120000, 180000, 210000, 890000]


def main() -> None:
    random.seed(2026)
    Path("data").mkdir(exist_ok=True)
    rows = []

    for n in range(6000):
        document = str(random.randint(10_000_000, 1_299_999_999))
        branch = random.choice(BRANCHES)
        day = random.randint(1, 28)
        code = random.choice(CODES)
        value = str(random.choice(VALUES))

        # Los problemas sembrados: siete clases, quince casos de cada una
        # repartidos por todo el archivo. El documento vacío y el no numérico
        # fallan por la misma regla, así que esa clase suma treinta.
        if n % 400 == 7:
            document = document[:-1] + "X"          # documento no numérico
        elif n % 400 == 53:
            branch = branch + "p"                    # sede que no existe
        elif n % 400 == 101:
            value = ""                               # valor vacío
        elif n % 400 == 157:
            value = "-" + value                      # valor negativo
        elif n % 400 == 211:
            day = 30                                 # 30 de febrero: fecha imposible
        elif n % 400 == 269:
            code = "D9999"                           # código fuera del manual tarifario
        elif n % 400 == 331:
            document = ""                            # documento vacío

        rows.append(f"{document},Paciente {n},{branch},2026-02-{day:02d},{code},{value}")

    # Y un problema que NO se ve fila por fila: un procedimiento duplicado
    # —mismo paciente, mismo código, mismo día— que la aseguradora rechaza entero.
    rows.append(rows[1500])

    target = Path("data") / "lote-2026-02.csv"
    target.write_text(
        "documento,paciente,sede,fecha,codigo,valor\n" + "\n".join(rows) + "\n",
        encoding="utf-8",
    )
    print(f"{target}: {len(rows)} filas")


if __name__ == "__main__":
    main()
