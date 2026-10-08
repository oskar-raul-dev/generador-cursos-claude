"""El mismo DB-API contra sqlite3 y psycopg: marcadores, tipos devueltos y lo que hace el 'with'."""

import datetime as dt
import os
import sqlite3
import time

import psycopg

ROWS = [("Suba", "2026-09-03", 450_000), ("Suba", "2026-09-17", 1_250_000), ("Centro", "2026-09-05", 800_000)]
DSN = os.environ.get("AUREA_PG", "host=pg dbname=postgres user=postgres password=aurea-local")


def load_and_query(conn, mark: str):
    cur = conn.cursor()
    cur.execute("CREATE TABLE abono (sede TEXT, fecha DATE, valor NUMERIC(12, 0))")
    cur.executemany(f"INSERT INTO abono VALUES ({mark}, {mark}, {mark})", ROWS)
    cur.execute(f"SELECT fecha, valor FROM abono WHERE sede = {mark} ORDER BY fecha", ("Suba",))
    names = [c[0] for c in cur.description]
    rows = cur.fetchall()
    return names, [(r[0], type(r[0]).__name__, r[1], type(r[1]).__name__) for r in rows]


print("paramstyle:", "sqlite3 =", sqlite3.paramstyle, "· psycopg =", psycopg.paramstyle)

with sqlite3.connect(":memory:") as lite:
    print("sqlite3:", load_and_query(lite, "?"))
print("sqlite3 después del with:", lite.execute("SELECT count(*) FROM abono").fetchone())

for _ in range(30):                                   # el contenedor de Postgres tarda en aceptar conexiones
    try:
        psycopg.connect(DSN).close()
        break
    except psycopg.OperationalError:
        time.sleep(1)

with psycopg.connect(DSN) as pg:
    print("psycopg:", load_and_query(pg, "%s"))
print("psycopg después del with: closed =", pg.closed)
