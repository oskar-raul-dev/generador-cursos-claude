"""Prepara los cuatro tamaños de la medición de la sección 6.

    uv run --with duckdb==1.5.5 python preparar_tamanos.py --salida data

Produce cuatro directorios, y solo el primero y el segundo son Áurea de verdad:

| directorio | qué es | declarado |
|---|---|---|
| `mes/`  | marzo de 2026, recortado del conjunto real | real |
| `trimestre/` | el primer trimestre de 2026 | real |
| `ano/`  | los doce meses hasta el corte | real |
| `e1/`   | la historia completa: 2024-01 a 2026-03 | real |
| `e4/`   | el mismo generador a `--escala 4` | **sintético** |
| `e16/`  | el mismo generador a `--escala 16` | **sintético** |

La escala no infla la pauta —que es una tabla pequeña por naturaleza, una fila por día,
campaña y sede— sino el embudo: leads, toques, etapas, planes y cuotas. Es la forma
realista de crecer: una red con cuatro veces más pacientes no compra cuatro veces más
filas de reporte de pauta, compra el mismo reporte con más presupuesto.

Cada directorio lleva además su copia en Parquet, porque la sección compara **formato** y
no solo motor.
"""

from __future__ import annotations

import argparse
import csv
import subprocess
import sys
from pathlib import Path

from consolidation import write_parquet

GENERATOR = Path(__file__).parent.parent / "ds01-numpy-y-el-modelo-vectorizado" / \
    "generar_embudo.py"

# Qué columna manda la fecha en cada archivo. `cuotas.csv` se recorta por la fecha
# **programada** y no por la de pago: una cuota de marzo que se pagó en abril sigue siendo
# de marzo, y sacarla del recorte cambiaría la pregunta.
DATE_COLUMN = {
    "pauta.csv": "fecha",
    "leads.csv": "creado",
    "toques.csv": "fecha_hora",
    "etapas.csv": "fecha_hora",
    "planes_de_tratamiento.csv": "fecha_aceptacion",
    "cuotas.csv": "fecha_programada",
}


def generate(scale: int, target: Path) -> None:
    subprocess.run([sys.executable, str(GENERATOR), "--salida", str(target),
                    "--escala", str(scale)], check=True, capture_output=True)


def slice_months(source: Path, target: Path, months: tuple[str, ...]) -> None:
    """Recorta cada CSV a los meses pedidos, conservando el encabezado.

    Se hace con el `csv` de la Fase 06 y no con ninguno de los cuatro motores que la
    sección compara: preparar los datos con uno de los competidores sería empezar la
    medición ya inclinada.
    """
    target.mkdir(parents=True, exist_ok=True)
    for name, column in DATE_COLUMN.items():
        with (source / name).open(encoding="utf-8", newline="") as origin:
            reader = csv.DictReader(origin)
            kept = [row for row in reader if row[column][:7] in months]
            header = reader.fieldnames or []
        with (target / name).open("w", encoding="utf-8", newline="\n") as file:
            file.write(",".join(header) + "\n")
            for row in kept:
                file.write(",".join(row[field] for field in header) + "\n")

    # Los planes del mes no cubren a todas las cuotas del mes, así que el `join` de la
    # consulta se quedaría sin sede para algunas. Se recortan las cuotas a los planes que
    # sí están: un recorte incoherente mediría un error, no un motor.
    with (target / "planes_de_tratamiento.csv").open(encoding="utf-8", newline="") as file:
        known = {row["plan_id"] for row in csv.DictReader(file)}
    with (target / "cuotas.csv").open(encoding="utf-8", newline="") as file:
        reader = csv.DictReader(file)
        header = reader.fieldnames or []
        kept = [row for row in reader if row["plan_id"] in known]
    with (target / "cuotas.csv").open("w", encoding="utf-8", newline="\n") as file:
        file.write(",".join(header) + "\n")
        for row in kept:
            file.write(",".join(row[field] for field in header) + "\n")

    for name in ("aliados.csv", "remisiones.csv", "manifiesto.json"):
        (target / name).write_bytes((source / name).read_bytes())


def count_rows(directory: Path) -> int:
    return sum(sum(1 for _ in path.open(encoding="utf-8")) - 1
               for path in sorted(directory.glob("*.csv")))


def main() -> None:
    parser = argparse.ArgumentParser(description="Los cuatro tamaños de la sección 6.")
    parser.add_argument("--salida", type=Path, default=Path("data"))
    args = parser.parse_args()

    generate(1, args.salida / "e1")
    slice_months(args.salida / "e1", args.salida / "mes", ("2026-03",))
    slice_months(args.salida / "e1", args.salida / "trimestre",
                 ("2026-01", "2026-02", "2026-03"))
    # Los doce meses hasta el corte: es el consolidado anual que Marcela lleva al comité de
    # franquicia, y el tamaño donde el umbral de la sección 6 se decide.
    year = tuple(f"2025-{month:02d}" for month in range(4, 13)) + \
        ("2026-01", "2026-02", "2026-03")
    slice_months(args.salida / "e1", args.salida / "ano", year)
    for scale in (4, 16):
        generate(scale, args.salida / f"e{scale}")

    for name in ("mes", "trimestre", "ano", "e1", "e4", "e16"):
        directory = args.salida / name
        write_parquet(directory, directory / "parquet")
        csv_mb = sum(path.stat().st_size for path in directory.glob("*.csv")) / 1e6
        parquet_mb = sum(path.stat().st_size
                         for path in (directory / "parquet").glob("*.parquet")) / 1e6
        print(f"{name:>5}: {count_rows(directory):>10,} filas · "
              f"CSV {csv_mb:>7.1f} MB · Parquet {parquet_mb:>6.1f} MB "
              f"({csv_mb / parquet_mb:.1f}× más chico)")


if __name__ == "__main__":
    main()
