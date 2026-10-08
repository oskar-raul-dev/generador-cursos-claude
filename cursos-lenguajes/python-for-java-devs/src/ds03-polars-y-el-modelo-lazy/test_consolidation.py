"""Pruebas del consolidado mensual. Sin red y sin servicios.

    uv run --with pandas==3.0.5 --with polars==1.44.2 --with duckdb==1.5.5 \\
           --with pytest pytest test_consolidation.py

La primera prueba es la que sostiene toda la sección 6: **los cinco motores devuelven
exactamente la misma lista de tuplas**. Una tabla de benchmark sin esta prueba no compara
motores, compara programas.
"""

from __future__ import annotations

import subprocess
import sys
from pathlib import Path

import pytest

from consolidation import (
    COLUMNS,
    ENGINES,
    consolidate_duckdb,
    consolidate_duckdb_parquet,
    consolidate_loop,
    write_parquet,
)
from preparar_tamanos import GENERATOR, slice_months

HERE = Path(__file__).parent


@pytest.fixture(scope="module")
def data(tmp_path_factory) -> Path:
    out = tmp_path_factory.mktemp("embudo")
    subprocess.run([sys.executable, str(GENERATOR), "--salida", str(out)],
                   check=True, capture_output=True)
    write_parquet(out, out / "parquet")
    return out


# --- La igualdad que hace legítima la medición -------------------------------------

def test_los_cinco_motores_dan_la_misma_tabla(data: Path):
    reference = consolidate_loop(data)
    assert reference, "el consolidado no puede salir vacío"
    for name, engine in ENGINES.items():
        source = data / "parquet" if "parquet" in name else data
        assert engine(source) == reference, name


def test_la_tabla_tiene_las_siete_columnas(data: Path):
    assert len(COLUMNS) == 7
    assert all(len(row) == 7 for row in consolidate_loop(data))


def test_el_mismo_sql_sobre_csv_y_sobre_parquet(data: Path):
    """El formato no puede cambiar el resultado. Si lo cambiara, la comparación de la
    sección 6 estaría midiendo dos consultas distintas y llamándolo formato."""
    assert consolidate_duckdb(data) == consolidate_duckdb_parquet(data / "parquet")


# --- Que la cuenta sea la cuenta ----------------------------------------------------

def test_el_total_cobrado_coincide_con_la_suma_directa(data: Path):
    import csv

    with (data / "cuotas.csv").open(encoding="utf-8", newline="") as file:
        paid = sum(int(row["valor_cop"]) for row in csv.DictReader(file)
                   if row["fecha_pago"])
    assert sum(row[6] for row in consolidate_loop(data)) == paid


def test_la_cuota_se_cuenta_en_el_mes_en_que_se_pago(data: Path):
    """Es caja, no devengo, y la diferencia son varios meses en un plan de veinticuatro.

    Se comprueba comparando el total cobrado de un mes con el de las cuotas **programadas**
    para ese mes: si coincidieran, el generador no tendría pagos tardíos y esta distinción
    sería decorativa.
    """
    import csv

    with (data / "cuotas.csv").open(encoding="utf-8", newline="") as file:
        rows = list(csv.DictReader(file))
    month = "2025-06"
    by_payment = sum(int(row["valor_cop"]) for row in rows
                     if row["fecha_pago"].startswith(month))
    by_schedule = sum(int(row["valor_cop"]) for row in rows
                      if row["fecha_programada"].startswith(month))
    assert by_payment != by_schedule

    table = {(row[0], row[1]): row[6] for row in consolidate_loop(data)}
    assert sum(value for (_, mes), value in table.items() if mes == month) == by_payment


def test_ninguna_fila_queda_sin_sede(data: Path):
    for row in consolidate_loop(data):
        assert row[0] and row[1]


# --- El recorte por meses -----------------------------------------------------------

def test_el_recorte_de_un_mes_es_coherente(data: Path, tmp_path: Path):
    """Cada cuota del recorte tiene su plan dentro del recorte. Sin eso, el `join` de la
    consulta se quedaría sin sede para algunas filas y la medición estaría midiendo un
    error de preparación de datos en vez de un motor."""
    import csv

    target = tmp_path / "mes"
    slice_months(data, target, ("2026-03",))

    with (target / "planes_de_tratamiento.csv").open(encoding="utf-8") as file:
        known = {row["plan_id"] for row in csv.DictReader(file)}
    with (target / "cuotas.csv").open(encoding="utf-8") as file:
        assert all(row["plan_id"] in known for row in csv.DictReader(file))

    write_parquet(target, target / "parquet")
    assert consolidate_loop(target) == consolidate_duckdb_parquet(target / "parquet")


def test_el_recorte_deja_solo_el_mes_pedido(data: Path, tmp_path: Path):
    import csv

    target = tmp_path / "marzo"
    slice_months(data, target, ("2026-03",))
    with (target / "leads.csv").open(encoding="utf-8") as file:
        assert all(row["creado"].startswith("2026-03") for row in csv.DictReader(file))


# --- Parquet ------------------------------------------------------------------------

def test_parquet_pesa_mucho_menos_que_el_csv(data: Path):
    csv_bytes = sum(path.stat().st_size for path in data.glob("*.csv"))
    parquet_bytes = sum(path.stat().st_size
                        for path in (data / "parquet").glob("*.parquet"))
    assert parquet_bytes * 10 < csv_bytes


def test_parquet_solo_convierte_las_cuatro_tablas_del_informe(data: Path):
    """Convertirlo todo sería más cómodo y mediría otra cosa: el informe usa cuatro."""
    assert {path.stem for path in (data / "parquet").glob("*.parquet")} == {
        "pauta", "leads", "planes_de_tratamiento", "cuotas"}


# --- La columna de líneas de código --------------------------------------------------

def test_las_lineas_de_duckdb_incluyen_su_sql(data: Path):
    """La primera versión de `effective_lines` contaba solo la función visible y le daba a
    DuckDB una línea. El SQL vive en una auxiliar y es código que alguien mantiene."""
    from bench_engines import effective_lines

    assert effective_lines("duckdb (parquet)") > 20
    assert all(effective_lines(engine) > 20 for engine in ENGINES)
