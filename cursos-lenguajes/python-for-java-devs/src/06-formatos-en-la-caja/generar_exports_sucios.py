"""Genera los exports del cierre de mes de las diez sedes, cada uno con su suciedad.

Uso:  python generar_exports_sucios.py
Produce data/cierre/ con seis formatos distintos, como llegan de verdad.
"""

import csv
import random
from pathlib import Path

BRANCHES = ["Centro", "Chapinero", "Suba", "Kennedy", "Usaquen",
            "Engativa", "Fontibon", "Restrepo", "Soacha", "Zipaquira"]
CODES = {"D8010": 180000, "D8020": 95000, "D2740": 890000,
         "D7140": 210000, "D1110": 75000, "D8670": 120000}
DESCRIPTIONS = {
    "D8010": "Control de ortodoncia, arco superior",
    "D8020": "Cambio de ligaduras",
    "D2740": "Corona en zirconio, cara vestibular, tono A2",
    "D7140": "Exodoncia simple",
    "D1110": "Profilaxis",
    "D8670": 'Retenedor fijo 3x3, "tipo Hawley"',
}
FIRST = ["Ana María", "Carlos Efrén", "Luz Dary", "Jhon Fredy", "Diana Marcela",
         "Óscar Iván", "Yenny Paola", "Wílmer Andrés", "Sandra Milena", "José Ángel"]
LAST = ["Robledo", "Neira", "Peña", "Chaparro", "Ocampo", "Guzmán", "Rojas",
        "Buitrago", "Cárdenas", "Quintero", "Mahecha", "Bermúdez"]

FIELDS = ["documento", "paciente", "sede", "fecha", "codigo", "descripcion", "valor"]


def rows_for(branch, count, rng):
    for _ in range(count):
        code = rng.choice(list(CODES))
        yield {
            "documento": str(rng.randint(10_000_000, 1_299_999_999)),
            # La coma dentro del nombre: esto es lo que rompe el script de la Fase 01.
            "paciente": f"{rng.choice(LAST)}, {rng.choice(FIRST)}",
            "sede": branch,
            "fecha": f"2026-03-{rng.randint(1, 31):02d}",
            "codigo": code,
            "descripcion": DESCRIPTIONS[code],
            "valor": str(CODES[code]),
        }


def main() -> None:
    rng = random.Random(2026)
    out = Path("data/cierre")
    out.mkdir(parents=True, exist_ok=True)

    for index, branch in enumerate(BRANCHES):
        rows = list(rows_for(branch, rng.randint(550, 700), rng))
        path = out / f"{branch.lower()}.csv"

        if index < 6:
            # Las seis sedes con Odontovía: latin-1, separado por punto y coma.
            with path.open("w", encoding="latin-1", newline="") as file:
                writer = csv.DictWriter(file, FIELDS, delimiter=";")
                writer.writeheader()
                writer.writerows(rows)
        elif index == 6:
            # La que exporta desde Excel: UTF-8 con BOM.
            with path.open("w", encoding="utf-8-sig", newline="") as file:
                writer = csv.DictWriter(file, FIELDS)
                writer.writeheader()
                writer.writerows(rows)
        elif index == 7:
            # El otro software: las columnas en otro orden.
            order = ["fecha", "sede", "documento", "valor", "codigo", "paciente", "descripcion"]
            with path.open("w", encoding="utf-8", newline="") as file:
                writer = csv.DictWriter(file, order)
                writer.writeheader()
                writer.writerows(rows)
        elif index == 8:
            # El Google Sheet: notas dentro de la celda de valor.
            for row in rows[::37]:
                row["valor"] = f"{row['valor']} (pendiente confirmar)"
            with path.open("w", encoding="utf-8", newline="") as file:
                writer = csv.DictWriter(file, FIELDS)
                writer.writeheader()
                writer.writerows(rows)
        else:
            # Zipaquirá: el cuaderno transcrito, con separador de miles y tabuladores.
            for row in rows:
                row["valor"] = f"{int(row['valor']):,}".replace(",", ".")
            with path.open("w", encoding="utf-8", newline="") as file:
                writer = csv.DictWriter(file, FIELDS, delimiter="\t")
                writer.writeheader()
                writer.writerows(rows)

        print(f"{path}: {len(rows)} filas")


if __name__ == "__main__":
    main()
