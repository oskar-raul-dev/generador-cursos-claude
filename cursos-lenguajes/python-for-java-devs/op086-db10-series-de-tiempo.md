# ⏱️ db10 — Series de tiempo: TimescaleDB e InfluxDB

> Python para desarrolladores Java senior · **Carta** · Track `db` — Hablarle a cada sistema de
> datos desde Python · sección 10 de 15
> Se lee suelta: no hace falta ninguna otra sección de la carta.
> Versiones verificadas contra PyPI el 05/10/2026 · Código probado el 05/10/2026 con Python 3.14.7,
> en contenedor: las salidas son las de esa corrida.

---

## 🎯 1. Qué problema resuelve

El agente que corre en cada sede mide cada minuto cuánto tarda la agenda en responder y cuántos pacientes hay en sala de
espera. Son diez sedes, 1 440 minutos al día: más de cinco millones de puntos al año. Nadie va a mirar un punto suelto; lo que
se mira son promedios por hora o por día, comparaciones con la semana anterior, y solo los últimos meses con detalle.

Esa forma de uso —escribir siempre al final, leer por ventanas de tiempo, resumir lo viejo y borrarlo— es la de una base de
series de tiempo, y tiene dos familias: **TimescaleDB**, una extensión de Postgres (se habla con `psycopg`, en SQL, junto a las
demás tablas), e **InfluxDB**, un motor propio (se habla con su cliente, en la versión 3 con SQL y resultados en Apache Arrow).
Lo que las dos convierten en primitivas —y en Postgres a secas habría que programar— son **las ventanas**, **la retención** y
**el resumen de lo viejo** (*downsampling*).

---

## 🧠 2. El modelo

| Lo que se necesita | TimescaleDB 2.30 (Postgres 18) | InfluxDB 3 Core | Postgres a secas |
|---|---|---|---|
| Tabla de mediciones | `create_hypertable` | Se crea al escribir (*line protocol*) | Tabla particionada a mano |
| Promedio por día | `time_bucket('1 day', momento)` | `date_bin(INTERVAL '1 day', time)` | `date_trunc`, sin intervalos arbitrarios |
| Borrar lo viejo | `add_retention_policy` | Retención de la base | Un trabajo programado |
| Resumir lo viejo | Agregados continuos | Procesos o consultas programadas | Vistas materializadas y su refresco |
| Desde Python | `psycopg` (`db01`) | `influxdb3-python` 0.21.0 | `psycopg` |
| *Join* con las sedes y los planes | **Sí**, es Postgres | No | Sí |

La fila de abajo es la que suele decidir: si las mediciones se cruzan con datos de negocio, TimescaleDB los tiene en la misma
base.

### Tu instinto de Java dice… y esta vez se equivoca

Este perfil probablemente ya tiene métricas en Prometheus (`ob03`) y el instinto es mandar todo ahí. Prometheus es para métricas
operativas de corto plazo, con su propio lenguaje y retención; los minutos de espera por sede son **datos de negocio** que
Patricia va a querer cruzar con la agenda dentro de un año. Van a una base.

---

## 💻 3. El ejemplo que corre

```bash
uv add "psycopg[binary]" influxdb3-python
```

`espera.py` escribe la misma semana de mediciones en las dos bases y pide lo mismo: el promedio diario de espera en Suba.

```python
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
```

```bash
docker run -d --name aurea-tsdb -e POSTGRES_PASSWORD=aurea-local -p 5432:5432 timescale/timescaledb:2.30.1-pg18
docker run -d --name aurea-influx -p 8181:8181 influxdb:3.12.0-core \
    influxdb3 serve --node-id aurea --object-store memory --without-auth
AUREA_TSDB="host=localhost dbname=postgres user=postgres password=aurea-local" \
AUREA_INFLUX=http://localhost:8181 python3 espera.py
```

Salida (Python 3.14.7, 05/10/2026):

```text
mediciones: 100800
TimescaleDB: carga 0.2 s · 7 particiones de un día
  Suba por día: [('2026-09-28', Decimal('8.84')), ('2026-09-29', Decimal('9.05')), ('2026-09-30', Decimal('9.03'))]
InfluxDB 3: carga 11.0 s
  devuelve: pyarrow.Table
  Suba por día: [('2026-09-28', 8.84), ('2026-09-29', 9.05), ('2026-09-30', 9.03)]
```

Las dos bases dan los mismos promedios diarios —TimescaleDB como `Decimal`, porque la columna es `numeric`; InfluxDB como `float`—,
y TimescaleDB partió la semana en siete particiones de un día. Los tiempos de carga **no son una comparación de motores** y no
deben leerse así: los 0,2 s de TimescaleDB son un `COPY`, el camino más rápido de Postgres; los 11 s de InfluxDB son, en su mayor
parte, el cliente construyendo cien mil objetos `Point` en Python. Escribir el *line protocol* directamente, o un `DataFrame`, es
el ejercicio 7 y cambia la cifra.

**Detalles con intención**

- **`create_hypertable`** convierte la tabla en una tabla particionada por tiempo, con una partición (*chunk*) por día. Borrar lo
  viejo es soltar particiones enteras, no un `DELETE` de millones de filas: es lo que hace `add_retention_policy`.
- **`COPY`** de `psycopg` es la forma de cargar volumen en cualquier Postgres; en TimescaleDB, también.
- **InfluxDB 3 devuelve una tabla de Apache Arrow** (`pyarrow.Table`), que pasa a pandas o Polars sin copiar. `to_pylist()` la
  convierte a diccionarios para el ejemplo.
- **`sede` es un *tag*** en InfluxDB: una columna indexada por la que se filtra. `minutos` es un *field*: el valor medido. Elegir
  mal entre los dos es el error de modelado clásico de Influx.
- **`--without-auth`** es solo para el contenedor local del ejemplo. En cualquier otro lado, InfluxDB 3 se usa con *token*. Aun sin
  autenticación, el cliente necesita un *token* no vacío: con `token=""` manda un encabezado `Authorization: Token ` incompleto y el
  servidor responde `400 Authorization header was malformed`, que fue el primer error de este ejemplo.

---

## ⚠️ 4. Lo que se rompe

**Una serie por paciente.** En InfluxDB, cada combinación distinta de *tags* es una serie. Usar la cédula o el identificador de
cita como *tag* crea millones de series (la "cardinalidad alta") y degrada el motor. Lo que identifica a una persona no es un *tag*;
y, en Áurea, tampoco se mide por persona.

**Los montos en `float`.** InfluxDB guarda los *fields* numéricos como `float` o entero. Para minutos de espera está bien; para plata,
no (`tx04`). La plata va a Postgres.

**La zona horaria de las ventanas.** `time_bucket('1 day', …)` y `date_bin` cortan los días en UTC por defecto. El "día" de Bogotá
empieza a las 05:00 UTC, y un promedio diario en UTC mezcla dos días de agenda. `time_bucket` acepta zona horaria; en Influx se
desplaza el origen.

**Las versiones de InfluxDB.** La 1.x usa InfluxQL, la 2.x Flux y el cliente `influxdb-client`, la 3.x SQL y `influxdb3-python`. Los
tutoriales mezclan las tres, y el código de uno no corre en otro.

---

## ⚖️ 5. Cuándo NO usarlo

**Para el volumen de Áurea, InfluxDB.** Cinco millones de puntos al año los atiende Postgres —y con TimescaleDB, con las primitivas
de tiempo— sin operar un motor más.

**Para métricas operativas del sistema.** Las de los procesos (latencia, errores) van a la observabilidad (`ob03`), no a la base del
negocio.

**Si nadie va a resumir ni borrar.** Si los datos son pocos y se guardan para siempre, una tabla normal con un índice por fecha alcanza.

---

## 🧪 6. Ejercicios (10)

**🟢 Fácil (1–3)**

1. Corre el ejemplo. **Criterio:** los dos tiempos de carga, y si los promedios de Suba coinciden entre las dos bases.
2. Haz el promedio diario con la zona de Bogotá en TimescaleDB (`time_bucket` con `timezone`). **Criterio:** los días cortan a
   medianoche de Bogotá.
3. Consulta `timescaledb_information.jobs`. **Criterio:** encuentras la política de retención.

**🟡 Intermedio (4–6)**

4. Crea un agregado continuo por hora y consúltalo. **Criterio:** la consulta usa el agregado y es más rápida que sobre la tabla.
5. Activa la compresión de las particiones de más de tres días. **Criterio:** el tamaño de la tabla antes y después.
6. Convierte el resultado de InfluxDB a Polars sin pasar por listas. **Criterio:** un `DataFrame` con tipos de fecha correctos.

**🟠 Difícil (7–9)**

7. Carga la semana en InfluxDB escribiendo el *line protocol* como texto, y como `DataFrame`, en vez de objetos `Point`. **Criterio:** los tres tiempos de carga, y cuánto de los 11 s era el cliente.
8. Cruza en TimescaleDB la espera promedio con la cantidad de citas de la agenda por hora. **Criterio:** una consulta con `JOIN`, y
   explicas por qué en InfluxDB no se puede igual.
9. Provoca la cardinalidad alta: un *tag* con 100 000 valores distintos. **Criterio:** describes el efecto en la escritura y la consulta.

**🔴 Muy difícil (10)**

10. Decide dónde guarda Áurea las mediciones de las sedes. **Criterio:** una página. *Rúbrica:* (a) volumen real por año; (b) qué
    consultas y con qué cruces; (c) retención y resumen; (d) lo que cuesta operar cada opción.

---

## 📚 7. Referencias

**Documentación oficial**

- TimescaleDB (hoy de Tiger Data), hipertablas: https://www.tigerdata.com/docs/learn/hypertables/understand-hypertables
- TimescaleDB, `time_bucket`: https://www.tigerdata.com/docs/reference/timescaledb/hyperfunctions/time-series-utilities/time_bucket
- InfluxDB 3 Core: https://docs.influxdata.com/influxdb3/core/
- `influxdb3-python`: https://github.com/InfluxCommunity/influxdb3-python

**Orden de lectura sugerido:** la página de hipertablas de TimescaleDB; después la de InfluxDB 3 Core sobre el modelo de *tags* y
*fields*.

---

## 🚀 8. Cierre

Las series de tiempo se escriben al final, se leen por ventanas y se resumen y borran con los años. TimescaleDB hace eso dentro de
Postgres —con `psycopg`, en SQL y con *joins*—; InfluxDB lo hace en un motor propio que devuelve Arrow. Las dos cortan los días en UTC
si no se les dice otra cosa, y ninguna es lugar para la plata.

**La señal de que quedó bien:** *"Patricia compara la espera de Suba con la del año pasado, por día de Bogotá, y lo más viejo de tres
meses ya está resumido."*

> 🏷️ **Cierra la sección con su tag**, cuando los ejercicios que elegiste estén hechos:
>
> ```bash
> git tag -a op-db-fase-10 -m "op db10 cerrada: hipertablas, ventanas y retención, y el mismo dato en InfluxDB 3"
> ```
>
> Los commits llevan su prefijo (`op db10: …`) y los de ejercicio su número
> (`op db10 ej07: …`).
