"""El consolidado mensual de las diez sedes, escrito cuatro veces.

Una fila por sede y mes con cinco cifras: gasto de pauta, leads, planes aceptados, valor
contratado y **cobrado de verdad**. Cuatro fuentes con granularidades distintas y un
`join` que hay que hacer sí o sí —las cuotas no saben en qué sede se firmó el plan—.

    from consolidation import consolidate_loop, consolidate_pandas
    from consolidation import consolidate_polars, consolidate_duckdb

Las cuatro devuelven **exactamente la misma lista de tuplas**, ordenada, y hay una prueba
que lo comprueba. Sin esa igualdad la tabla de la sección 6 compararía cuatro programas
distintos, que es la forma más común de mentir con un benchmark.

Cada implementación vive en una función de un solo bloque, sin auxiliares compartidas, a
propósito: la sección 6 cuenta **líneas de código efectivas** por motor, y repartir una de
ellas en tres funciones le regalaría el número.
"""

from __future__ import annotations

import csv
from collections import Counter, defaultdict
from pathlib import Path

# Una fila del consolidado. Se usa tupla y no `dataclass` porque el resultado se compara
# entre cuatro motores y se ordena: una tupla ya sabe hacer las dos cosas.
Row = tuple[str, str, int, int, int, int, int]

COLUMNS = ("sede", "mes", "gasto_cop", "leads", "planes",
           "valor_contratado_cop", "cobrado_cop")


def consolidate_loop(data: Path) -> list[Row]:
    """Biblioteca estándar: `csv`, diccionarios y un `for` por archivo.

    Es el competidor de verdad de esta sección, no un hombre de paja: cualquiera de los
    dieciocho capítulos del camino base lo habría escrito así, y hasta cierto tamaño **es
    la respuesta correcta**. Cero dependencias, cero arranque, y se lee de corrido.
    """
    spend: defaultdict[tuple[str, str], int] = defaultdict(int)
    leads: Counter[tuple[str, str]] = Counter()
    plans: Counter[tuple[str, str]] = Counter()
    value: defaultdict[tuple[str, str], int] = defaultdict(int)
    collected: defaultdict[tuple[str, str], int] = defaultdict(int)
    branch_of_plan: dict[str, str] = {}

    with (data / "pauta.csv").open(encoding="utf-8", newline="") as file:
        for row in csv.DictReader(file):
            spend[(row["sede"], row["fecha"][:7])] += int(row["costo_cop"])

    with (data / "leads.csv").open(encoding="utf-8", newline="") as file:
        for row in csv.DictReader(file):
            leads[(row["sede"], row["creado"][:7])] += 1

    with (data / "planes_de_tratamiento.csv").open(encoding="utf-8", newline="") as file:
        for row in csv.DictReader(file):
            key = (row["sede"], row["fecha_aceptacion"][:7])
            plans[key] += 1
            value[key] += int(row["valor_total_cop"])
            branch_of_plan[row["plan_id"]] = row["sede"]

    with (data / "cuotas.csv").open(encoding="utf-8", newline="") as file:
        for row in csv.DictReader(file):
            # La cuota se cuenta en el mes en que **se pagó**, no en el que se programó: es
            # caja, no devengo. Las impagadas no tienen mes y no entran en ninguna fila.
            if row["fecha_pago"]:
                collected[(branch_of_plan[row["plan_id"]], row["fecha_pago"][:7])] += int(
                    row["valor_cop"])

    keys = set(spend) | set(leads) | set(plans) | set(collected)
    return sorted((branch, month, spend[(branch, month)], leads[(branch, month)],
                   plans[(branch, month)], value[(branch, month)],
                   collected[(branch, month)])
                  for branch, month in keys)


def consolidate_pandas(data: Path) -> list[Row]:
    """pandas, en el orden que dejó `ds02`: agregar cada fuente antes de unirlas."""
    import pandas as pd

    spend = (pd.read_csv(data / "pauta.csv", usecols=["fecha", "sede", "costo_cop"])
             .assign(mes=lambda frame: frame["fecha"].str.slice(0, 7))
             .groupby(["sede", "mes"], observed=True)["costo_cop"].sum()
             .rename("gasto_cop"))
    leads = (pd.read_csv(data / "leads.csv", usecols=["creado", "sede"])
             .assign(mes=lambda frame: frame["creado"].str.slice(0, 7))
             .groupby(["sede", "mes"], observed=True).size().rename("leads"))
    plans_raw = pd.read_csv(
        data / "planes_de_tratamiento.csv",
        usecols=["plan_id", "sede", "fecha_aceptacion", "valor_total_cop"])
    plans = (plans_raw.assign(mes=lambda frame: frame["fecha_aceptacion"].str.slice(0, 7))
             .groupby(["sede", "mes"], observed=True)
             .agg(planes=("plan_id", "size"),
                  valor_contratado_cop=("valor_total_cop", "sum")))
    paid = pd.read_csv(data / "cuotas.csv", usecols=["plan_id", "valor_cop", "fecha_pago"])
    paid = paid[paid["fecha_pago"].notna()]
    collected = (paid.merge(plans_raw[["plan_id", "sede"]], on="plan_id",
                            how="left", validate="m:1")
                 .assign(mes=lambda frame: frame["fecha_pago"].str.slice(0, 7))
                 .groupby(["sede", "mes"], observed=True)["valor_cop"].sum()
                 .rename("cobrado_cop"))

    table = pd.concat([spend, leads, plans, collected], axis=1).fillna(0).astype("int64")
    table = table.reset_index().sort_values(["sede", "mes"])
    return [tuple(row) for row in table[list(COLUMNS)].itertuples(index=False, name=None)]


def consolidate_polars(data: Path) -> list[Row]:
    """Polars en modo perezoso: `scan_csv` describe el plan y `collect` lo ejecuta.

    Nada se lee hasta el `collect` final. El optimizador ve la consulta entera —las cuatro
    fuentes, las proyecciones y los joins— antes de tocar el disco, y eso es lo que le
    permite no leer las columnas que nadie usa.
    """
    import polars as pl

    spend = (pl.scan_csv(data / "pauta.csv")
             .select(sede=pl.col("sede"), mes=pl.col("fecha").str.slice(0, 7),
                     costo=pl.col("costo_cop"))
             .group_by("sede", "mes").agg(gasto_cop=pl.col("costo").sum()))
    leads = (pl.scan_csv(data / "leads.csv")
             .select(sede=pl.col("sede"), mes=pl.col("creado").str.slice(0, 7))
             .group_by("sede", "mes").agg(leads=pl.len()))
    plans_raw = pl.scan_csv(data / "planes_de_tratamiento.csv")
    plans = (plans_raw
             .select(sede=pl.col("sede"), mes=pl.col("fecha_aceptacion").str.slice(0, 7),
                     valor=pl.col("valor_total_cop"))
             .group_by("sede", "mes").agg(planes=pl.len(),
                                          valor_contratado_cop=pl.col("valor").sum()))
    collected = (pl.scan_csv(data / "cuotas.csv")
                 .filter(pl.col("fecha_pago").is_not_null())
                 .join(plans_raw.select("plan_id", "sede"), on="plan_id", how="left")
                 .select(sede=pl.col("sede"), mes=pl.col("fecha_pago").str.slice(0, 7),
                         valor=pl.col("valor_cop"))
                 .group_by("sede", "mes").agg(cobrado_cop=pl.col("valor").sum()))

    table = spend
    for other in (leads, plans, collected):
        table = table.join(other, on=["sede", "mes"], how="full", coalesce=True)

    # `fill_null` sobre `pl.Int64` no alcanza: `pl.len()` devuelve `UInt32`, así que la
    # columna de leads se quedaba con `null` en los meses sin leads y el resultado dejaba de
    # coincidir con los otros tres motores. Se castea primero y se rellena después.
    counters = [name for name in COLUMNS[2:]]
    result = (table.with_columns(pl.col(counters).cast(pl.Int64).fill_null(0))
              .select(COLUMNS).sort("sede", "mes").collect())
    return [tuple(row) for row in result.iter_rows()]


def consolidate_duckdb(data: Path) -> list[Row]:
    """DuckDB: la misma pregunta, en el SQL que llevas once años escribiendo.

    Lee los CSV directamente —no hace falta cargarlos en ninguna tabla— y el plan lo arma
    el motor. Es la opción con el modelo mental más corto para este lector, y por eso su
    número importa más que su elegancia.
    """
    return _duckdb_query(data, "read_csv", ".csv")


def _duckdb_query(data: Path, reader: str, suffix: str) -> list[Row]:
    """El SQL compartido por las dos variantes de DuckDB.

    Es la única función auxiliar compartida del módulo, y existe porque las dos variantes
    **tienen que ejecutar exactamente la misma consulta**: si el Parquet ganara por llevar
    un SQL distinto, la comparación no diría nada sobre el formato.
    """
    import duckdb

    query = f"""
        WITH spend AS (
            SELECT sede, strftime(fecha, '%Y-%m') AS mes, sum(costo_cop) AS gasto_cop
            FROM {reader}($pauta) GROUP BY 1, 2),
        leads AS (
            SELECT sede, strftime(creado, '%Y-%m') AS mes, count(*) AS leads
            FROM {reader}($leads) GROUP BY 1, 2),
        plans AS (
            SELECT sede, strftime(fecha_aceptacion, '%Y-%m') AS mes, count(*) AS planes,
                   sum(valor_total_cop) AS valor_contratado_cop
            FROM {reader}($planes) GROUP BY 1, 2),
        collected AS (
            SELECT p.sede, strftime(c.fecha_pago, '%Y-%m') AS mes,
                   sum(c.valor_cop) AS cobrado_cop
            FROM {reader}($cuotas) c JOIN {reader}($planes) p USING (plan_id)
            WHERE c.fecha_pago IS NOT NULL GROUP BY 1, 2)
        SELECT sede, mes,
               coalesce(gasto_cop, 0)::BIGINT, coalesce(leads, 0)::BIGINT,
               coalesce(planes, 0)::BIGINT, coalesce(valor_contratado_cop, 0)::BIGINT,
               coalesce(cobrado_cop, 0)::BIGINT
        FROM spend FULL JOIN leads USING (sede, mes)
                   FULL JOIN plans USING (sede, mes)
                   FULL JOIN collected USING (sede, mes)
        ORDER BY sede, mes
    """
    parameters = {"pauta": str(data / f"pauta{suffix}"),
                  "leads": str(data / f"leads{suffix}"),
                  "planes": str(data / f"planes_de_tratamiento{suffix}"),
                  "cuotas": str(data / f"cuotas{suffix}")}
    return duckdb.connect().execute(query, parameters).fetchall()


def write_parquet(data: Path, target: Path) -> None:
    """Convierte los cuatro CSV a Parquet, con DuckDB y sin cargar nada en memoria.

    Se mide aparte, en la sección 6, porque es un costo que se paga **una vez** y que la
    comparación de motores esconde si se mete dentro. Quien convierte una vez y consulta
    cien veces no está en la misma situación que quien hace las dos cosas cada mañana.
    """
    import duckdb

    target.mkdir(parents=True, exist_ok=True)
    connection = duckdb.connect()
    for name in ("pauta", "leads", "planes_de_tratamiento", "cuotas"):
        connection.execute(
            f"COPY (SELECT * FROM read_csv('{data / name}.csv')) "
            f"TO '{target / name}.parquet' (FORMAT parquet, COMPRESSION zstd)")


def consolidate_duckdb_parquet(data: Path) -> list[Row]:
    """La misma consulta de DuckDB, sobre Parquet en vez de CSV.

    Es la única diferencia: el SQL es idéntico. Lo que cambia es que Parquet trae el
    esquema escrito, guarda cada columna por separado y anota estadísticas por bloque, así
    que el motor puede **no leer** lo que no necesita. La sección 6 dice cuánto vale eso.
    """
    return _duckdb_query(data, "read_parquet", ".parquet")


ENGINES = {
    "bucle": consolidate_loop,
    "pandas": consolidate_pandas,
    "polars (lazy)": consolidate_polars,
    "duckdb (csv)": consolidate_duckdb,
    "duckdb (parquet)": consolidate_duckdb_parquet,
}
