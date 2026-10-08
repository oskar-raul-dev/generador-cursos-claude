# 🦆 db05 — DuckDB

> Python para desarrolladores Java senior · **Carta** · Track `db` — Hablarle a cada sistema de
> datos desde Python · sección 5 de 15
> Se lee suelta: no hace falta ninguna otra sección de la carta.
> Versiones verificadas contra PyPI el 05/10/2026 · Código probado el 05/10/2026 con Python 3.14.7,
> en contenedor: las salidas son las de esa corrida.

---

## 🎯 1. Qué problema resuelve

Patricia pide los abonos de los últimos tres años, por sede y por mes. Los datos están en los exportes nocturnos: un
archivo por noche y por sede, en CSV los más viejos y en Parquet desde el año pasado. Cargar todo eso a Postgres para hacer
una consulta es una tarde de trabajo; leerlo con un bucle de Python, otra.

DuckDB es una base de datos analítica que corre **dentro del proceso de Python**, como SQLite, pero diseñada para lo
contrario: no para muchas escrituras pequeñas, sino para consultas que recorren millones de filas. Y tiene una propiedad que
cambia el flujo de trabajo: **consulta archivos directamente**. `SELECT … FROM 'exportes/*.parquet'` lee todos los Parquet de
la carpeta, sin cargar nada antes. Es la respuesta a la pregunta de Patricia en una línea de SQL.

---

## 🧠 2. El modelo

| | SQLite (`db04`) | DuckDB 1.5.6 | Postgres |
|---|---|---|---|
| Dónde corre | En el proceso | En el proceso | Servidor aparte |
| Para qué está hecho | Muchas transacciones pequeñas (OLTP) | Consultas que recorren muchas filas (OLAP) | Las dos, con un servidor |
| Almacenamiento | Por filas | **Por columnas**, vectorizado | Por filas |
| Lee archivos directamente | No | **CSV, Parquet, JSON, Excel**, locales o en S3 | Con extensiones |
| Concurrencia | Un escritor, muchos lectores | **Un proceso** con el archivo abierto para escribir | Muchos |

La regla de la fila "para qué está hecho" es la sección entera: DuckDB no reemplaza a Postgres como base de la aplicación;
reemplaza al *script* de pandas, a la hoja de Excel gigante y a la carga a Postgres solo para consultar.

### Tu instinto de Java dice… y esta vez se equivoca

En Java, consultar archivos con SQL es Spark, Drill o Presto: un clúster, o al menos una JVM grande y una configuración. El
instinto supone que leer tres años de exportes con SQL requiere esa infraestructura. DuckDB lo hace en el portátil, con un
`pip install` y sin servidor.

---

## 💻 3. El ejemplo que corre

```bash
uv add duckdb
```

`abonos.py`:

```python
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
```

```bash
python3 abonos.py
```

Salida (Python 3.14.7, 05/10/2026) (los milisegundos son de la máquina que corre; estos, de un contenedor en un portátil):

```text
abonos.csv        27.1 MB
abonos.parquet     6.2 MB
consulta sobre abonos.csv        118 ms
consulta sobre abonos.parquet     18 ms
  Suba       2026-03  Decimal('3377879908')
  Restrepo   2026-03  Decimal('3374611485')
  Centro     2026-08  Decimal('3373695850')
segundo proceso: _duckdb.IOException: IO Error: Could not set lock on file "/w/aurea.duckdb": Conflicting lock is held in /usr/
```

Un millón de abonos, y la misma consulta sobre los dos formatos: el Parquet ocupa 4,4 veces menos y responde 6,5 veces más
rápido (18 ms contra 118). Los montos llegan como `Decimal`. Y el segundo proceso que intenta abrir `aurea.duckdb` mientras el
primero lo tiene abierto falla con un bloqueo, que es el límite de diseño de la sección.

**Detalles con intención**

- **`FROM 'abonos.parquet'`** es una tabla: DuckDB reconoce la extensión y lee el archivo. Con comodines
  (`'exportes/*/*.parquet'`) lee una carpeta entera, y con `hive_partitioning` entiende rutas como `sede=Suba/mes=09/`.
- **Parquet guarda tipos y columnas**: la consulta lee solo `sede`, `fecha` y `valor`, y salta bloques enteros por las
  estadísticas de `fecha`. El CSV hay que leerlo y convertirlo entero cada vez.
- **`DECIMAL(12, 0)` llega a Python como `Decimal`**, igual que el `NUMERIC` de Postgres (`db01`).
- **`GROUP BY ALL`** agrupa por todas las columnas que no son agregados: una comodidad de DuckDB que Postgres no tiene.

---

## ⚠️ 4. Lo que se rompe

**DuckDB como base de la aplicación.** Un servicio web con varios procesos que escriben en el mismo archivo de DuckDB choca
con el bloqueo de la última línea. DuckDB es para el proceso que analiza, no para la base que atiende.

**El CSV de cada noche con columnas que cambian.** DuckDB infiere los tipos del CSV leyendo una muestra; un exporte con una
columna nueva, o con `N/A` donde antes había números, cambia la inferencia y la consulta falla o, peor, convierte a texto. Para
datos que se consultan seguido, se convierten una vez a Parquet con el esquema declarado.

**La memoria.** DuckDB usa por defecto el 80 % de la memoria del sistema y derrama a disco cuando no alcanza. En un servidor
compartido, se limita con `SET memory_limit`.

**Las versiones del archivo.** El formato del archivo `.duckdb` cambió entre versiones mayores; un archivo creado con una versión
nueva puede no abrir con una vieja. Para intercambiar, Parquet; el `.duckdb` es local.

---

## ⚖️ 5. Cuándo NO usarlo

**Como base transaccional.** Para eso, Postgres o SQLite.

**Para consultas sobre datos que ya están en Postgres y caben.** Postgres con un índice responde; mover los datos a DuckDB tiene
sentido cuando el volumen o los archivos lo piden.

**Con datos que no caben en un disco.** DuckDB escala en una máquina; para petabytes, un motor distribuido.

---

## 🧪 6. Ejercicios (10)

**🟢 Fácil (1–3)**

1. Corre `abonos.py`. **Criterio:** los dos tamaños, los dos tiempos y la razón entre ellos en tu máquina.
2. Consulta `DESCRIBE SELECT * FROM 'abonos.csv'`. **Criterio:** los tipos que infirió, y si coinciden con los de la tabla.
3. Agrega `EXPLAIN ANALYZE` a la consulta sobre Parquet. **Criterio:** identificas cuántas filas leyó y si usó el filtro de fecha.

**🟡 Intermedio (4–6)**

4. Escribe los abonos particionados por sede y mes (`PARTITION_BY`) y consulta solo Suba. **Criterio:** el tiempo baja, y dices
   por qué.
5. Pasa el resultado a Polars con `.pl()` o a una lista de diccionarios. **Criterio:** los montos siguen siendo exactos.
6. Consulta directamente una tabla de Postgres con la extensión `postgres` de DuckDB. **Criterio:** una consulta que junta un
   Parquet con una tabla de Postgres.

**🟠 Difícil (7–9)**

7. Mide la misma agregación en DuckDB, en pandas y en Postgres con los datos cargados. **Criterio:** la tabla de tiempos, con la
   carga incluida y sin incluir.
8. Lee los exportes de un *bucket* S3 (o MinIO, `db13`) con la extensión `httpfs`. **Criterio:** la consulta corre sin descargar
   los archivos antes.
9. Provoca el cambio de inferencia: un CSV con `N/A` en `valor` a partir de la fila 50 000. **Criterio:** describes qué hizo
   DuckDB y cómo lo evitas con `columns=`.

**🔴 Muy difícil (10)**

10. Diseña el análisis histórico de Áurea sobre los exportes. **Criterio:** una página. *Rúbrica:* (a) formato y partición de los
    exportes; (b) quién consulta y con qué (Patricia no escribe SQL); (c) cuándo se convierte de CSV a Parquet; (d) qué no se
    hace en DuckDB.

---

## 📚 7. Referencias

**Documentación oficial**

- DuckDB, API de Python: https://duckdb.org/docs/stable/clients/python/overview
- DuckDB, leer Parquet: https://duckdb.org/docs/stable/data/parquet/overview
- DuckDB, concurrencia: https://duckdb.org/docs/stable/connect/concurrency

**Orden de lectura sugerido:** la página de concurrencia (corta, y es la que dice para qué no sirve); después la de Parquet.

---

## 🚀 8. Cierre

DuckDB es la base analítica que corre dentro de Python y consulta archivos directamente: CSV, Parquet, carpetas enteras. Con
Parquet es mucho más rápida que con CSV, y para todo lo que es "consultar los exportes" reemplaza a la carga y al *script*. No
es la base de la aplicación: un solo proceso escribe su archivo.

**La señal de que quedó bien:** *"Patricia pidió tres años de abonos por sede y mes, y la respuesta fue una consulta sobre la
carpeta de exportes."*

> 🏷️ **Cierra la sección con su tag**, cuando los ejercicios que elegiste estén hechos:
>
> ```bash
> git tag -a op-db-fase-05 -m "op db05 cerrada: DuckDB sobre CSV y Parquet, y el proceso único"
> ```
>
> Los commits llevan su prefijo (`op db05: …`) y los de ejercicio su número
> (`op db05 ej07: …`).
