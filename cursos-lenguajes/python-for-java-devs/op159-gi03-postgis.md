# 🐘 gi03 — PostGIS desde Python

> Python para desarrolladores Java senior · **Carta** · Track `gi` — Geoespacial ·
> sección 3 de 7
> Se lee suelta: no hace falta ninguna otra sección de la carta. Conviene haber leído la
> [Fase 11](11-persistencia.md) (psycopg y el pool) y [`gi01`](op157-gi01-el-modelo.md) (CRS).
> Versiones verificadas contra PyPI el 07/10/2026 · Código probado el 07/10/2026 con Python 3.14.7,
> en contenedor: las salidas son las de esa corrida.

---

## 🎯 1. Qué problema resuelve

*"Los pacientes a menos de 5 km de cada sede"* es la consulta con la que empieza cualquier análisis de cobertura, y con doscientos mil domicilios ya no es trabajo
para un `GeoDataFrame` en memoria: es trabajo para la base de datos, donde están los datos y donde puede haber un índice. **PostGIS** es la extensión espacial de
PostgreSQL —la misma GEOS y la misma PROJ de gi01, ahora dentro del motor—, y desde Python se le habla con el mismo `psycopg` del camino base.

Lo que PostGIS agrega es un tipo, `geometry` (y su primo `geography`), un catálogo de sistemas de referencia (`spatial_ref_sys`), cientos de funciones `ST_*`, y
el índice **GiST**, que es un R-tree sobre la caja que envuelve cada geometría. El problema no es aprender las funciones; es que **la misma consulta escrita de cuatro
maneras devuelve tres respuestas distintas y tarda de 0,3 a 3 segundos**, y solo el plan de ejecución dice cuál usó el índice.

La sección carga doscientos mil domicilios **sintéticos** en un PostGIS en contenedor, escribe la consulta de las cuatro maneras y mide cada una. Ningún dato es
de un paciente real.

---

## 🧠 2. El modelo

```mermaid
flowchart TB
    Q["¿a menos de 5 km?"] --> T{"tipo de la columna"}
    T -->|"geometry(Point, 4326)"| G["unidades = grados<br/>ST_DWithin(…, 5000) = 5000 grados"]
    T -->|"::geography"| GG["unidades = metros sobre el elipsoide<br/>índice GiST sobre la expresión"]
    T -->|"ST_Transform(…, 9377)"| P["unidades = metros en el plano<br/>índice GiST sobre la expresión"]
    GG --> I{"¿la función usa el índice?"}
    P --> I
    I -->|"ST_DWithin"| Y["Index Scan"]
    I -->|"ST_Distance(…) < 5000"| N["Seq Scan: calcula 2 millones de distancias"]
```

| Para qué | `geometry` | `geography` |
|---|---|---|
| Unidades | Las del SRID (grados en 4326, metros en 9377) | Siempre metros |
| Cálculo | Plano cartesiano | Sobre el elipsoide |
| Funciones | Todas (cientos) | Un subconjunto: distancia, área, `DWithin`, `Intersects`, `Buffer` |
| Costo | Barato | Más caro por operación |
| Cuándo | Datos de un país, proyectados a su CRS local | Datos de todo el planeta, o cuando nadie quiere pensar en proyecciones |

### Diccionario

```text
Java                                         Python
Hibernate Spatial · @Column(columnDefinition) ⇄  GeoAlchemy2 · Column(Geometry("POINT", srid=4326))
JTS Geometry en la entidad                    ⇄  shapely, con geoalchemy2.shape.to_shape
JDBC + PGgeometry (postgis-jdbc)              ⇄  psycopg + shapely.wkb.loads(hex=True)
```

---

## 💻 3. El ejemplo que corre

`compose.yaml`:

```yaml
services:
  db:
    image: postgis/postgis:18-3.6     # solo se publica para amd64: en Mac con Apple Silicon corre emulada
    environment:
      POSTGRES_PASSWORD: postgres
    ports:
      - "5432:5432"
```

```bash
docker compose up -d
uv add "psycopg[binary]==3.3.6" shapely==2.1.2 pyproj==3.8.0
```

`vecindad.py`:

```python
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
```

```bash
uv run vecindad.py
```

Salida (Python 3.14.7, 07/10/2026) (PostGIS emulado en amd64 sobre un Mac ARM: los milisegundos sirven para comparar entre sí, no como cifra absoluta):

```text
PostGIS 3.6.4
¿conoce EPSG:9377? no
1 geometry en grados, 5000      Seq Scan       1650 ms · Centro 200000 · total 2000000
2 geography sin índice          Seq Scan       2885 ms · Centro  14622 · total  123550
3 geography con índice          Index Scan      313 ms · Centro  14622 · total  123550
4 geometry en 9377 con índice   Index Scan      310 ms · Centro  14634 · total  123694

más cercana: 1→Usaquén (2876 m), 2→Suba (11034 m), 3→Soacha (7086 m), 4→Suba (9289 m), 5→Suba (8674 m)
tipo recibido: str · 0101000020E6100000… → POINT (-74.084 4.741)
```

Lo que dicen los números:

- **PostGIS 3.6.4 no trae EPSG:9377** en `spatial_ref_sys`, el CRS oficial de Colombia desde 2020. La primera corrida falló con `Cannot find SRID (9377) in
  spatial_ref_sys` al crear el índice; el código ahora lo registra con la definición de PROJ (`pyproj.CRS(9377)`). Es una migración más del esquema, no un detalle
  de instalación.
- **La consulta 1 cuenta los 200.000 domicilios para cada sede**: sobre `geometry` en 4326, `ST_DWithin(…, 5000)` significa *5.000 grados*, y todo el planeta está
  a menos de 5.000 grados. Sin error, y con un total de dos millones de filas.
- **La 2 da la respuesta correcta y no usa índice**: `ST_Distance(…) < 5000` calcula la distancia de los dos millones de pares y después filtra. 2,8 segundos.
- **La 3 da la misma respuesta nueve veces más rápido** (313 ms): `ST_DWithin` sí sabe usar el índice, porque primero descarta por caja envolvente y solo calcula la
  distancia exacta de los candidatos. El índice está sobre la **expresión** `(geom::geography)`; un índice sobre `geom` a secas no le serviría.
- **La 4, en el plano 9377, difiere en 144 domicilios de 123.550 (0,1 %)**: la proyección deforma un poco las distancias lejos de su meridiano central. Para cobertura
  de sedes da igual; para un linde de catastro, no.
- **`<->` es el operador de vecino más cercano**: con `ORDER BY … <-> … LIMIT 1` dentro de un `LATERAL`, PostGIS recorre el índice en orden de cercanía. Sobre
  `geometry` 4326 ordena por grados, que en Bogotá coincide con el orden en metros (gi02), y la distancia se reporta en metros con `geography`.
- **psycopg devuelve la geometría como texto hexadecimal** (EWKB: `0101000020E6100000…`, donde `E6100000` es el SRID 4326 en *little endian*). `shapely.wkb.loads`
  la convierte en un `Point`.

**Detalles con intención**

- **`setseed(0.7)` antes de `random()`**: la nube es la misma en cada corrida, y las cuentas se pueden comparar.
- **`ANALYZE home` después de crear los índices**: sin estadísticas de la expresión, el planificador puede no elegirlos.
- **`EXPLAIN` antes de medir**: el tiempo dice cuánto; el plan dice por qué. La función `run` imprime los dos.
- **`autocommit=True`**: el ejemplo es DDL y consultas sueltas; en una aplicación, las transacciones las maneja el pool de la Fase 11.

---

## ⚠️ 4. Lo que se rompe

**`ST_Distance(…) < x` en el `WHERE`.** Es la forma natural de escribirlo y nunca usa el índice. La regla: para "a menos de", **`ST_DWithin`**; para "el más
cercano", **`ORDER BY <-> LIMIT`**; `ST_Distance` solo en el `SELECT`, para mostrar el número.

**El índice sobre la columna y la consulta sobre la expresión.** `CREATE INDEX … USING gist (geom)` no sirve para `ST_DWithin(geom::geography, …)` ni para
`ST_Transform(geom, 9377)`. O el índice va sobre la misma expresión, o se agrega una columna generada en el CRS en que se consulta
(`geom_m geometry(Point, 9377) GENERATED ALWAYS AS (ST_Transform(geom, 9377)) STORED`).

**El SRID que el catálogo no tiene.** Un `ST_Transform` a un SRID que no está en `spatial_ref_sys` falla en tiempo de ejecución, no al crear la tabla. Si el sistema
usa un CRS nacional, el registro va en la migración inicial y se prueba en CI.

**`geometry` sin SRID.** Una columna `geometry` sin tipo ni SRID acepta puntos en cualquier sistema, mezclados. `geometry(Point, 4326)` hace que el motor rechace la
inserción con otro SRID: es la restricción que gi01 pedía, ahora en el esquema.

---

## ⚖️ 5. Cuándo NO usarla

**Cuando los datos caben en memoria y la consulta es de una sola vez.** Dos mil puntos se unen en geopandas en milisegundos (gi02); levantar PostGIS, migrar el
esquema y registrar SRID es costo fijo que una exploración no paga.

**Cuando el análisis es de columnas, no de transacciones.** DuckDB con su extensión `spatial` lee GeoParquet directamente y hace los mismos joins sin servidor; para
un reporte mensual sobre archivos, gana en operación. PostGIS gana cuando los datos **se actualizan** y varias aplicaciones los consultan.

**Cuando la base de la empresa no es PostgreSQL.** MySQL, SQL Server y Oracle tienen tipos espaciales; menos funciones, pero sin un segundo motor que operar. Si
Odontovía vive en MySQL, la primera pregunta es si `ST_Distance_Sphere` de MySQL alcanza.

---

## 🧪 6. Ejercicios (10)

**🟢 Fácil (1–3)**

1. Levanta el `compose.yaml` y corre el ejemplo. **Criterio:** las cuatro consultas con su plan, y la explicación de por qué la 1 cuenta 200.000 por sede.
2. Corre `EXPLAIN ANALYZE` de las consultas 2 y 3 en `psql`. **Criterio:** el nodo que usa el índice y el número de filas que descarta el filtro de caja.
3. Agrega la columna generada `geom_m` en 9377 con su índice y reescribe la consulta 4 contra ella. **Criterio:** mismo resultado, `Index Scan` sobre el índice nuevo.

**🟡 Intermedio (4–6)**

4. Calcula, para cada sede, el porcentaje de domicilios que tienen **otra** sede más cerca. **Criterio:** una consulta con `LATERAL` y `<->`, y los diez
   porcentajes.
5. Lee las diez sedes con GeoAlchemy2 (`geoalchemy2.Geometry` en un modelo de SQLAlchemy) y conviértelas a `shapely` con `to_shape`. **Criterio:** los diez puntos,
   iguales a los del diccionario `SEDES`.
6. Exporta los domicilios a 5 km del Centro como GeoJSON con `ST_AsGeoJSON` y léelos con geopandas. **Criterio:** el mismo conteo de la consulta 3 y el CRS
   declarado.

**🟠 Difícil (7–9)**

7. Sube la tabla a dos millones de domicilios y repite las cuatro consultas. **Criterio:** la tabla de tiempos, y si la razón entre 2 y 3 crece o se mantiene.
8. Escribe la migración inicial de un esquema espacial (Alembic o SQL puro) que registre EPSG:9377 si falta. **Criterio:** es idempotente y una prueba en
   contenedor confirma que `ST_Transform(…, 9377)` funciona después de aplicarla.
9. Compara contra DuckDB con la extensión `spatial` la consulta 3 sobre los mismos 200.000 puntos exportados a Parquet. **Criterio:** los dos tiempos y que los
   conteos coinciden.

**🔴 Muy difícil (10)**

10. Diseña el almacenamiento espacial de un sistema con datos de domicilio sensibles. **Criterio:** una página con el DDL. *Rúbrica:* (a) `geometry` o `geography`,
    y en qué SRID; (b) los índices y las consultas que los usan; (c) qué columna ve quién (permisos sobre la coordenada exacta frente a la distancia ya calculada);
    (d) cómo se prueba que una consulta nueva usa el índice antes de llegar a producción.

---

## 📚 7. Referencias

**Documentación oficial**

- PostGIS, el manual: https://postgis.net/docs/manual-3.6/
- `ST_DWithin`: https://postgis.net/docs/ST_DWithin.html
- El operador `<->` (vecino más cercano): https://postgis.net/docs/geometry_distance_knn.html
- `spatial_ref_sys` y cómo agregar un SRID: https://postgis.net/docs/manual-3.6/using_postgis_dbmanagement.html#spatial_ref_sys_table
- GeoAlchemy2: https://geoalchemy-2.readthedocs.io/en/latest/

**Taller**

- *Introduction to PostGIS*, el taller oficial (índices espaciales, geography, vecino más cercano): https://postgis.net/workshops/postgis-intro/

**Orden de lectura sugerido:** los capítulos de índices espaciales, `geography` y vecino más cercano del taller oficial; después la página de `ST_DWithin`.

---

## 🚀 8. Cierre

En PostGIS la misma pregunta se escribe de cuatro maneras: una devuelve todo, una es correcta y lenta, y dos son correctas y rápidas porque usan un índice construido
sobre la misma expresión que la consulta. `ST_DWithin` para "a menos de", `<->` para "el más cercano", `EXPLAIN` antes de medir, y el SRID nacional registrado en la
migración inicial porque el catálogo no lo trae.

**La señal de que quedó bien:** *"Cada consulta espacial de mi sistema tiene su `EXPLAIN` con `Index Scan` en una prueba, y la columna declara tipo y SRID."*

> 🏷️ **Cierra la sección con su tag**, cuando los ejercicios que elegiste estén hechos:
>
> ```bash
> git tag -a op-gi-fase-03 -m "op gi03 cerrada: vecindad en PostGIS con ST_DWithin, índice sobre la expresión y EPSG:9377 registrado"
> ```
>
> Los commits llevan su prefijo (`op gi03: …`) y los de ejercicio su número
> (`op gi03 ej07: …`).
