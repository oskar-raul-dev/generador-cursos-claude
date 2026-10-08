"""DuckDB: generar un millón de abonos, consultarlos en CSV y en Parquet, y el bloqueo del archivo."""

import os
import subprocess
import sys
import time

import duckdb

SEDES = ["Centro", "Chapinero", "Suba", "Kennedy", "Usaquén", "Engativá", "Fontibón", "Restrepo", "Soacha", "Zipaquirá"]

con = duckdb.connect()                                   # en memoria
con.execute(f"""
    CREATE TABLE abono AS
    SELECT (list_value({', '.join(repr(s) for s in SEDES)}))[1 + (i % 10)] AS sede,
           DATE '2023-10-01' + CAST(i % 1095 AS INTEGER) AS fecha,
           CAST(50000 + (i * 7919) % 2000000 AS DECIMAL(12, 0)) AS valor
    FROM range(1000000) t(i)
""")
con.execute("COPY abono TO 'abonos.csv' (HEADER)")
con.execute("COPY abono TO 'abonos.parquet' (FORMAT parquet)")
for f in ("abonos.csv", "abonos.parquet"):
    print(f"{f:<15} {os.path.getsize(f) / 1e6:6.1f} MB")

QUERY = """
    SELECT sede, date_trunc('month', fecha) AS mes, sum(valor) AS total
    FROM '{f}' WHERE fecha >= DATE '2026-01-01'
    GROUP BY ALL ORDER BY total DESC LIMIT 3
"""


def best_of_three(sql: str) -> float:
    times = []
    for _ in range(3):
        start = time.perf_counter()
        con.sql(sql).fetchall()
        times.append(time.perf_counter() - start)
    return min(times)


for f in ("abonos.csv", "abonos.parquet"):
    print(f"consulta sobre {f:<15} {best_of_three(QUERY.format(f=f)) * 1000:5.0f} ms")

rows = con.sql(QUERY.format(f="abonos.parquet")).fetchall()
for sede, mes, total in rows:
    print(f"  {sede:<10} {mes:%Y-%m}  {total!r}")

# El archivo de base de DuckDB: un solo proceso lo abre para escribir.
writer = duckdb.connect("aurea.duckdb")
other = subprocess.run([sys.executable, "-c", "import duckdb; duckdb.connect('aurea.duckdb')"],
                       capture_output=True, text=True)
print("segundo proceso:", other.stderr.strip().splitlines()[-1][:110])
