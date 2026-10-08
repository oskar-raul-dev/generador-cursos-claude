"""Leer a los aliados: SQL Server con pyodbc y pymssql, Oracle con oracledb thin, y sus trampas."""

import os
import time
from decimal import Decimal

import oracledb
import pymssql

MSSQL = dict(server=os.environ.get("AUREA_MSSQL", "mssql"), user="sa", password="Aurea-Local-2026!")
ORACLE = dict(user="system", password="aurea-local", dsn=os.environ.get("AUREA_ORACLE", "oracle/FREEPDB1"))


def retry(connect):
    for _ in range(180):                          # los dos tardan en arrancar la primera vez
        try:
            return connect()
        except Exception:
            time.sleep(1)
    raise SystemExit("no respondió")


# ------------------------------------------------- SQL Server: el driver del sistema operativo
try:
    import pyodbc
    print("pyodbc, drivers ODBC instalados:", pyodbc.drivers())
except ImportError as e:
    print("pyodbc no importa:", e)

with retry(lambda: pymssql.connect(**MSSQL)) as conn, conn.cursor() as cur:
    cur.execute("SELECT SERVERPROPERTY('ProductVersion')")
    print("pymssql conectado a SQL Server", cur.fetchone()[0])     # sql_variant: llega como bytes
    cur.execute("CREATE TABLE #nota (v VARCHAR(50), nv NVARCHAR(50))")
    cur.execute("INSERT INTO #nota VALUES (%s, %s)", ("Quedó feliz 😁", "Quedó feliz 😁"))
    cur.execute("SELECT v, nv FROM #nota")
    print("  VARCHAR / NVARCHAR:", cur.fetchone())

# ------------------------------------------------- Oracle: thin, sin Instant Client
with retry(lambda: oracledb.connect(**ORACLE)) as conn, conn.cursor() as cur:
    print("oracledb modo thin:", conn.thin, "· Oracle", conn.version)
    cur.execute("CREATE TABLE abono (sede VARCHAR2(20), nota VARCHAR2(50), valor NUMBER(12, 2))")
    cur.execute("INSERT INTO abono VALUES (:sede, :nota, :valor)", sede="Suba", nota="", valor=Decimal("1250000.10"))
    cur.execute("SELECT count(*) FROM abono WHERE nota = ''")
    print("  filas con nota = '':", cur.fetchone()[0])
    cur.execute("SELECT count(*) FROM abono WHERE nota IS NULL")
    print("  filas con nota IS NULL:", cur.fetchone()[0])
    cur.execute("SELECT valor FROM abono")
    value = cur.fetchone()[0]
    print("  NUMBER(12,2) llega como:", repr(value), type(value).__name__)
    oracledb.defaults.fetch_decimals = True               # vale para los cursores que se creen después
    with conn.cursor() as cur2:
        cur2.execute("SELECT valor FROM abono")
        print("  con fetch_decimals:", repr(cur2.fetchone()[0]))
    cur.execute("DROP TABLE abono")
