"""PostGIS desde Python: los pacientes a menos de 5 km de cada sede, cuatro maneras, con su plan y su tiempo."""

import os
import time
import warnings

import psycopg
from pyproj import CRS
from shapely import wkb

DSN = os.environ.get("DATABASE_URL", "postgresql://postgres:postgres@localhost:5432/postgres")

SEDES = {
    "Centro": (4.6040, -74.0660), "Chapinero": (4.6486, -74.0628), "Suba": (4.7410, -74.0840),
    "Kennedy": (4.6280, -74.1530), "Usaquén": (4.6950, -74.0310), "Engativá": (4.7070, -74.1100),
    "Fontibón": (4.6780, -74.1410), "Restrepo": (4.5880, -74.1030), "Soacha": (4.5790, -74.2170),
    "Zipaquirá": (5.0220, -73.9950),
}

SCHEMA = """
CREATE EXTENSION IF NOT EXISTS postgis;
DROP TABLE IF EXISTS home, sede;
CREATE TABLE sede (name text PRIMARY KEY, geom geometry(Point, 4326) NOT NULL);
CREATE TABLE home (id int PRIMARY KEY, geom geometry(Point, 4326) NOT NULL);
-- 200.000 domicilios sintéticos alrededor de Bogotá; setseed hace que la nube sea siempre la misma
SELECT setseed(0.7);
INSERT INTO home
SELECT i, ST_SetSRID(ST_MakePoint(-74.09 + (random() - 0.5) * 0.25, 4.66 + (random() - 0.5) * 0.35), 4326)
FROM generate_series(1, 200000) AS i;
"""

QUERIES = {
    "1 geometry en grados, 5000": """
        SELECT s.name, count(*) FROM sede s JOIN home h ON ST_DWithin(h.geom, s.geom, 5000) GROUP BY s.name""",
    "2 geography sin índice": """
        SELECT s.name, count(*) FROM sede s JOIN home h ON ST_Distance(h.geom::geography, s.geom::geography) < 5000
        GROUP BY s.name""",
    "3 geography con índice": """
        SELECT s.name, count(*) FROM sede s JOIN home h ON ST_DWithin(h.geom::geography, s.geom::geography, 5000)
        GROUP BY s.name""",
    "4 geometry en 9377 con índice": """
        SELECT s.name, count(*) FROM sede s
        JOIN home h ON ST_DWithin(ST_Transform(h.geom, 9377), ST_Transform(s.geom, 9377), 5000) GROUP BY s.name""",
}


def connect():
    for _ in range(60):                                   # el contenedor tarda en aceptar conexiones
        try:
            return psycopg.connect(DSN, autocommit=True)
        except psycopg.OperationalError:
            time.sleep(1)
    raise SystemExit("PostGIS no respondió en 60 s")


def run(cur, label, sql):
    plan = "\n".join(row[0] for row in cur.execute("EXPLAIN " + sql))
    node = "Index Scan" if "Index Scan" in plan else "Seq Scan"
    start = time.perf_counter()
    rows = dict(cur.execute(sql).fetchall())
    ms = (time.perf_counter() - start) * 1000
    print(f"{label:<31} {node:<10} {ms:8.0f} ms · Centro {rows.get('Centro', 0):>6} · total {sum(rows.values()):>7}")


with connect() as conn, conn.cursor() as cur:
    cur.execute(SCHEMA)
    cur.executemany("INSERT INTO sede VALUES (%s, ST_SetSRID(ST_MakePoint(%s, %s), 4326))",
                    [(name, lon, lat) for name, (lat, lon) in SEDES.items()])
    print("PostGIS", cur.execute("SELECT postgis_lib_version()").fetchone()[0])
    known = cur.execute("SELECT count(*) FROM spatial_ref_sys WHERE srid = 9377").fetchone()[0]
    print("¿conoce EPSG:9377?", "sí" if known else "no")
    if not known:                                     # se registra con la definición que trae PROJ
        crs = CRS(9377)
        with warnings.catch_warnings():               # PROJ avisa que proj4 pierde detalle; PostGIS usa primero
            warnings.simplefilter("ignore")           # la autoridad EPSG y el WKT, y proj4text queda de respaldo
            proj4 = crs.to_proj4()
        cur.execute("INSERT INTO spatial_ref_sys (srid, auth_name, auth_srid, srtext, proj4text) VALUES (9377, 'EPSG', 9377, %s, %s)",
                    (crs.to_wkt("WKT1_GDAL"), proj4))

    for label in ("1 geometry en grados, 5000", "2 geography sin índice"):
        run(cur, label, QUERIES[label])
    # Los índices GiST se crean sobre la expresión que la consulta usa, no sobre la columna a secas
    cur.execute("CREATE INDEX home_geog ON home USING gist ((geom::geography))")
    cur.execute("CREATE INDEX home_ctm12 ON home USING gist (ST_Transform(geom, 9377))")
    cur.execute("ANALYZE home")
    for label in ("3 geography con índice", "4 geometry en 9377 con índice"):
        run(cur, label, QUERIES[label])

    # Vecino más cercano con el operador <->: la sede de cada uno de cinco domicilios, por índice
    cur.execute("CREATE INDEX sede_geom ON sede USING gist (geom)")
    nearest = cur.execute("""
        SELECT h.id, s.name, round(ST_Distance(h.geom::geography, s.geom::geography))::int
        FROM home h CROSS JOIN LATERAL (SELECT name, geom FROM sede ORDER BY sede.geom <-> h.geom LIMIT 1) s
        WHERE h.id <= 5 ORDER BY h.id""").fetchall()
    print("\nmás cercana:", ", ".join(f"{i}→{name} ({m} m)" for i, name, m in nearest))

    # La geometría llega como EWKB en hexadecimal; shapely la convierte
    raw = cur.execute("SELECT geom FROM sede WHERE name = 'Suba'").fetchone()[0]
    point = wkb.loads(raw, hex=True)
    print(f"tipo recibido: {type(raw).__name__} · {raw[:18]}… → {point.wkt}")
