"""Las tres trampas de MySQL y MariaDB para quien viene de Postgres, contra los dos motores."""

import os
import time

import pymysql

SERVERS = {"MySQL": os.environ.get("AUREA_MYSQL", "mysql"), "MariaDB": os.environ.get("AUREA_MARIA", "maria")}


def connect(host: str):
    for _ in range(90):                              # los dos tardan en arrancar la primera vez
        try:
            return pymysql.connect(host=host, user="root", password="aurea-local", charset="utf8mb4",
                                   autocommit=True)
        except pymysql.err.OperationalError:
            time.sleep(1)
    raise SystemExit(f"{host} no respondió")


for engine, host in SERVERS.items():
    with connect(host) as conn, conn.cursor() as cur:
        cur.execute("SELECT VERSION(), @@collation_server, @@sql_mode")
        version, collation, mode = cur.fetchone()
        print(f"--- {engine} {version} · colación {collation}")
        print("    modo estricto:", "STRICT_TRANS_TABLES" in mode)
        cur.execute("CREATE DATABASE IF NOT EXISTS aurea")
        cur.execute("USE aurea")

        # 1. utf8 que no es UTF-8
        for charset in ("utf8", "utf8mb4"):
            cur.execute("DROP TABLE IF EXISTS nota")
            cur.execute(f"CREATE TABLE nota (texto VARCHAR(50)) CHARACTER SET {charset}")
            try:
                cur.execute("INSERT INTO nota VALUES (%s)", ("Quedó feliz 😁",))
                print(f"    {charset:<8} emoji: guardado")
            except pymysql.err.DataError as e:
                print(f"    {charset:<8} emoji: error {e.args[0]}")

        # 2. la colación que ignora tildes
        cur.execute("SELECT %s = %s", ("Muñoz", "munoz"))
        print("    'Muñoz' = 'munoz':", bool(cur.fetchone()[0]))

        # 3. el modo no estricto que trunca
        cur.execute("CREATE TABLE IF NOT EXISTS sede (codigo VARCHAR(5))")
        cur.execute("SET SESSION sql_mode = ''")
        cur.execute("INSERT INTO sede VALUES (%s)", ("ZIPAQUIRA",))
        cur.execute("SHOW WARNINGS")
        warning = cur.fetchone()
        cur.execute("SELECT codigo FROM sede")
        print("    sin modo estricto se guardó:", cur.fetchone()[0], "· aviso:", warning[2] if warning else None)
