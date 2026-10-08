"""Cassandra desde Python: la tabla diseñada para una consulta, y las consultas que no acepta."""

import datetime as dt
import os
import time

from cassandra import ConsistencyLevel, InvalidRequest
from cassandra.cluster import Cluster, NoHostAvailable
from cassandra.query import SimpleStatement

for _ in range(120):                                        # Cassandra tarda en arrancar
    try:
        cluster = Cluster([os.environ.get("AUREA_CASSANDRA", "cassandra")])
        session = cluster.connect()
        break
    except NoHostAvailable:
        time.sleep(2)
print("servidor:", session.execute("SELECT release_version FROM system.local").one().release_version)

session.execute("""CREATE KEYSPACE IF NOT EXISTS mensajeria
                   WITH replication = {'class': 'SimpleStrategy', 'replication_factor': 1}""")
session.set_keyspace("mensajeria")
session.execute("""CREATE TABLE IF NOT EXISTS evento_por_sede_dia (
                       sede text, dia date, momento timestamp, mensaje uuid, estado text,
                       PRIMARY KEY ((sede, dia), momento, mensaje)
                   ) WITH CLUSTERING ORDER BY (momento DESC, mensaje ASC)""")

insert = session.prepare("INSERT INTO evento_por_sede_dia (sede, dia, momento, mensaje, estado) "
                         "VALUES (?, ?, ?, uuid(), ?)")
insert.consistency_level = ConsistencyLevel.LOCAL_QUORUM
day = dt.date(2026, 10, 5)
for i in range(300):
    moment = dt.datetime(2026, 10, 5, 7, tzinfo=dt.UTC) + dt.timedelta(minutes=2 * i)
    session.execute(insert, ("Suba", day, moment, ["enviado", "entregado", "leído"][i % 3]))

# La consulta para la que se diseñó la tabla: toda la clave de partición, orden de la tabla.
rows = session.execute("SELECT momento, estado FROM evento_por_sede_dia WHERE sede = %s AND dia = %s LIMIT 3",
                       ("Suba", day))
print("últimos tres de Suba hoy:", [(r.momento.strftime("%H:%M"), r.estado) for r in rows])

# Paginación: el driver trae de a 100 filas y pide más al iterar.
paged = SimpleStatement("SELECT estado FROM evento_por_sede_dia WHERE sede = %s AND dia = %s", fetch_size=100)
result = session.execute(paged, ("Suba", day))
print("primera página:", len(result.current_rows), "filas · total al iterar:", sum(1 for _ in result))

# Las consultas de Postgres que Cassandra no acepta.
for cql in ("SELECT * FROM evento_por_sede_dia WHERE estado = 'leído'",
            "SELECT * FROM evento_por_sede_dia WHERE sede = 'Suba' AND dia = '2026-10-05' ORDER BY estado"):
    try:
        session.execute(cql)
    except InvalidRequest as e:
        print("rechazada:", str(e).split("message=")[-1][:110])
cluster.shutdown()
