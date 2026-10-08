"""La misma semana de mediciones en TimescaleDB y en InfluxDB 3, y el promedio diario en las dos."""

import datetime as dt
import os
import random
import time

import psycopg
from influxdb_client_3 import InfluxDBClient3, Point

SEDES = ["Centro", "Chapinero", "Suba", "Kennedy", "Usaquén", "Engativá", "Fontibón", "Restrepo", "Soacha", "Zipaquirá"]
START = dt.datetime(2026, 9, 28, tzinfo=dt.UTC)
random.seed(11)
rows = [(START + dt.timedelta(minutes=m), sede, round(random.uniform(0, 12) + (3 if sede == "Suba" else 0), 1))
        for m in range(7 * 1440) for sede in SEDES]
print("mediciones:", len(rows))

# ------------------------------------------------- TimescaleDB: Postgres con primitivas de tiempo
pg_dsn = os.environ.get("AUREA_TSDB", "host=tsdb dbname=postgres user=postgres password=aurea-local")
for _ in range(60):
    try:
        pg = psycopg.connect(pg_dsn, autocommit=True)
        break
    except psycopg.OperationalError:
        time.sleep(1)
pg.execute("CREATE EXTENSION IF NOT EXISTS timescaledb")
pg.execute("DROP TABLE IF EXISTS espera")
pg.execute("CREATE TABLE espera (momento timestamptz NOT NULL, sede text NOT NULL, minutos numeric(4,1))")
pg.execute("SELECT create_hypertable('espera', by_range('momento', INTERVAL '1 day'))")
start = time.perf_counter()
with pg.cursor().copy("COPY espera (momento, sede, minutos) FROM STDIN") as copy:
    for row in rows:
        copy.write_row(row)
print(f"TimescaleDB: carga {time.perf_counter() - start:.1f} s ·",
      pg.execute("SELECT count(*) FROM timescaledb_information.chunks WHERE hypertable_name = 'espera'").fetchone()[0],
      "particiones de un día")
pg.execute("SELECT add_retention_policy('espera', INTERVAL '90 days')")
daily_ts = pg.execute("""SELECT time_bucket('1 day', momento) AS dia, round(avg(minutos), 2)
                         FROM espera WHERE sede = %s GROUP BY dia ORDER BY dia LIMIT 3""", ("Suba",)).fetchall()
print("  Suba por día:", [(d.date().isoformat(), v) for d, v in daily_ts])

# ------------------------------------------------- InfluxDB 3: motor propio, SQL y Arrow
influx = InfluxDBClient3(host=os.environ.get("AUREA_INFLUX", "http://influx:8181"), database="sedes",
                         token="local")                       # el servidor sin auth lo ignora, pero no acepta uno vacío
for _ in range(60):
    try:
        influx.query("SELECT 1", language="sql")
        break
    except Exception:
        time.sleep(1)
start = time.perf_counter()
batch = [Point("espera").tag("sede", sede).field("minutos", value).time(moment) for moment, sede, value in rows]
for i in range(0, len(batch), 10_000):
    influx.write(record=batch[i:i + 10_000])
print(f"InfluxDB 3: carga {time.perf_counter() - start:.1f} s")
table = influx.query("""SELECT date_bin(INTERVAL '1 day', time) AS dia, round(avg(minutos), 2) AS promedio
                        FROM espera WHERE sede = 'Suba' GROUP BY dia ORDER BY dia LIMIT 3""", language="sql")
print("  devuelve:", type(table).__module__.split(".")[0] + "." + type(table).__name__)
print("  Suba por día:", [(r["dia"].date().isoformat(), r["promedio"]) for r in table.to_pylist()])
