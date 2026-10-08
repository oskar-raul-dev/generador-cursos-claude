# 🔌 db01 — El panorama y el DB-API 2.0

> Python para desarrolladores Java senior · **Carta** · Track `db` — Hablarle a cada sistema de
> datos desde Python · sección 1 de 15
> Se lee suelta: no hace falta ninguna otra sección de la carta.
> Versiones verificadas contra PyPI el 05/10/2026 · Código probado el 05/10/2026 con Python 3.14.7,
> en contenedor: las salidas son las de esa corrida.

---

## 🎯 1. Qué problema resuelve

Este track es práctico a propósito: no enseña bases de datos, enseña **a hablarle desde Python a cada una**. Qué se
instala, cómo se abre la conexión, cómo se ve una consulta, qué tipos de Python devuelve, y cuál es la trampa que ese
sistema le tiene reservada a quien llega de Postgres. Las catorce secciones siguientes son un sistema cada una; esta es
la base que comparten todas las relacionales.

En Java, esa base es JDBC: una interfaz, un *driver* por motor, y `PreparedStatement` con `?` en todos lados. En Python
la base equivalente es el **DB-API 2.0** (PEP 249), y la diferencia con JDBC es la que más confunde al llegar: **no es
una biblioteca, es una convención**. No hay un paquete `dbapi` que importar; cada *driver* —`sqlite3`, `psycopg`,
`PyMySQL`, `oracledb`— implementa la misma forma (`connect`, `cursor`, `execute`, `fetchall`, `commit`) a su manera, con
detalles que no coinciden. El más visible: cada uno elige su propio marcador de parámetros.

---

## 🧠 2. El modelo

| JDBC | DB-API 2.0 | La diferencia |
|---|---|---|
| `DriverManager.getConnection(url)` | `driver.connect(...)` | Cada *driver* recibe sus propios argumentos; no hay URL común |
| `PreparedStatement` con `?` | `cursor.execute(sql, parámetros)` | **El marcador depende del *driver*** (`paramstyle`) |
| `ResultSet` | `cursor.fetchone()`, `fetchall()`, iterar el cursor | Filas como tuplas (o lo que configure el *driver*) |
| `ResultSetMetaData` | `cursor.description` | Siete campos por columna; casi siempre basta el nombre |
| `conn.setAutoCommit(false)` | Transacción implícita abierta por defecto | Hay que llamar a `commit()`; si no, se pierde al cerrar |
| `try-with-resources` | `with conn:` | **Cada *driver* decide qué hace el `with`**: confirmar, cerrar o las dos |

Los cinco `paramstyle` que permite la PEP 249, y quién usa cuál:

| `paramstyle` | Marcador | *Drivers* |
|---|---|---|
| `qmark` | `?` | `sqlite3`, `pyodbc` |
| `numeric` | `:1` | `oracledb` (también acepta `named`) |
| `named` | `:sede` | `sqlite3`, `oracledb` |
| `format` | `%s` | `PyMySQL`, `mysqlclient` |
| `pyformat` | `%(sede)s` y `%s` | `psycopg`, `pymssql` |

### Esto sí funciona igual

La regla de oro de JDBC sobrevive intacta: **los valores van como parámetros, nunca dentro del texto del SQL**. Cambia el
dibujo del marcador; la razón —que el *driver* separe el dato de la sintaxis— es la misma, y la inyección SQL se evita
exactamente igual.

---

## 💻 3. El ejemplo que corre

El mismo código contra SQLite (en memoria) y contra PostgreSQL 18, para ver qué cambia de un *driver* a otro.

```bash
uv add "psycopg[binary]"
```

`dbapi.py`:

```python
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
```

```bash
docker run -d --name aurea-pg -e POSTGRES_PASSWORD=aurea-local -p 5432:5432 postgres:18.6
AUREA_PG="host=localhost dbname=postgres user=postgres password=aurea-local" python3 dbapi.py
```

Salida (Python 3.14.7, 05/10/2026):

```text
paramstyle: sqlite3 = qmark · psycopg = pyformat
sqlite3: (['fecha', 'valor'], [('2026-09-03', 'str', 450000, 'int'), ('2026-09-17', 'str', 1250000, 'int')])
sqlite3 después del with: (3,)
psycopg: (['fecha', 'valor'], [(datetime.date(2026, 9, 3), 'date', Decimal('450000'), 'Decimal'), (datetime.date(2026, 9, 17), 'date', Decimal('1250000'), 'Decimal')])
psycopg después del with: closed = True
```

La misma tabla, la misma consulta y dos resultados distintos. SQLite devuelve la fecha como `str` y el valor como `int`,
porque guarda lo que le dan con tipos dinámicos (`db04`). PostgreSQL devuelve `datetime.date` y `Decimal`, porque la
columna es `DATE` y `NUMERIC`, y `psycopg` traduce cada tipo de Postgres a su equivalente exacto de Python. Y el `with`
hace cosas distintas: en `sqlite3` confirma la transacción y **deja la conexión abierta** (la consulta posterior funciona);
en `psycopg` confirma **y cierra**.

**Detalles con intención**

- **El marcador va en una variable (`mark`)** solo para el ejemplo. En código real se escribe el del *driver* y no se
  abstrae: una capa que traduce marcadores entre *drivers* es un ORM a medio hacer (`SQLAlchemy` ya existe).
- **`Decimal('450000')`** es la razón por la que `NUMERIC` es el tipo correcto para plata: sin `float` en ningún paso, del
  disco a Python.
- **El bucle de espera** es para el contenedor recién arrancado; en producción, el *pool* de conexiones reintenta.
- **`executemany`** en `psycopg` 3 usa el modo *pipeline* de Postgres y es rápido; en `sqlite3`, es un bucle en C. En los dos,
  mucho mejor que `execute` en un bucle de Python.

---

## ⚠️ 4. Lo que se rompe

**El `with` que no cierra.** Quien viene de `try-with-resources` supone que el `with` de `sqlite3` cierra la conexión, y no lo
hace: maneja la transacción. Un programa que abre conexiones de SQLite en un bucle con `with` acumula conexiones abiertas. Se
cierra explícitamente o con `contextlib.closing`.

**Olvidar el `commit()`.** Sin `with` y sin `commit()`, los `INSERT` se pierden al cerrar, sin error. El DB-API abre una
transacción implícita y espera que alguien la confirme; JDBC, con *autocommit* por defecto, acostumbró a lo contrario.

**El f-string con el valor adentro.** `cur.execute(f"... WHERE sede = '{sede}'")` funciona, y es inyección SQL (`tx01`,
`se07`). El marcador del ejemplo está en un f-string, pero el **valor** va como parámetro.

**Comparar fechas de SQLite como fechas.** Llegan como `str`: `'2026-09-17' > '2026-09-05'` funciona por suerte del formato
ISO; con otro formato, no. `sqlite3` puede convertirlas (`detect_types`), y sus adaptadores por defecto están en desuso desde
Python 3.12; se registran los propios.

---

## ⚖️ 5. Cuándo NO usar el DB-API directo

**Con un modelo de dominio grande.** Si hay cuarenta tablas con relaciones, escribir el SQL y mapear tuplas a mano es el
trabajo que hace un ORM (SQLAlchemy), y el camino base lo cubre.

**Para cambiar de motor "sin tocar el código".** El DB-API no lo promete: los marcadores, los tipos y el SQL de cada motor
cambian. Si la portabilidad importa, la capa es SQLAlchemy Core, no el DB-API.

**Con `asyncio`.** El DB-API es síncrono. Para código asíncrono, `psycopg` tiene `AsyncConnection` y los demás tienen sus
variantes (`asyncmy`, `aiosqlite`), con otra forma.

---

## 🧪 6. Ejercicios (10)

**🟢 Fácil (1–3)**

1. Imprime `cursor.description` completo para las dos conexiones. **Criterio:** explicas qué trae cada uno de los siete campos
   en cada *driver*.
2. Cambia el `INSERT` de `psycopg` al estilo `%(sede)s` con diccionarios. **Criterio:** el mismo resultado.
3. Quita el `with` de `sqlite3` y no llames a `commit()`; reabre la base (en un archivo, no en memoria). **Criterio:** los datos
   no están, y dices por qué.

**🟡 Intermedio (4–6)**

4. Registra adaptadores y convertidores de `date` en `sqlite3` con `detect_types`. **Criterio:** la fecha llega como
   `datetime.date` y no hay avisos de desuso.
5. Usa `psycopg.rows.dict_row` como `row_factory`. **Criterio:** las filas llegan como diccionarios.
6. Escribe una función que reciba cualquier conexión DB-API y su `paramstyle`, y arme el `INSERT` con el marcador correcto.
   **Criterio:** funciona con `sqlite3` y `psycopg`, y opinas si vale la pena.

**🟠 Difícil (7–9)**

7. Mide `executemany` contra `execute` en bucle, con 10 000 filas, en los dos *drivers*. **Criterio:** la tabla de tiempos.
8. Usa `psycopg_pool.ConnectionPool` con cinco hilos que insertan a la vez. **Criterio:** las 5 000 filas llegan, y el *pool*
   nunca abre más de cinco conexiones.
9. Provoca un error en mitad de una transacción en `psycopg` y continúa usando la conexión. **Criterio:** el error exacto
   (`InFailedSqlTransaction`) y cómo se recupera.

**🔴 Muy difícil (10)**

10. Escribe la "tabla de traducción" de JDBC a DB-API para tu equipo. **Criterio:** una página. *Rúbrica:* (a) las diez
    operaciones más comunes, en las dos columnas; (b) las cinco diferencias que más errores causan; (c) qué *driver* de Python
    corresponde a cada *driver* JDBC que usan; (d) cuándo pasar a SQLAlchemy.

---

## 📚 7. Referencias

**Documentación oficial**

- PEP 249, el DB-API 2.0: https://peps.python.org/pep-0249/
- `sqlite3`: https://docs.python.org/3/library/sqlite3.html
- `psycopg` 3: https://www.psycopg.org/psycopg3/docs/
- `psycopg`, adaptación de tipos: https://www.psycopg.org/psycopg3/docs/basic/adapt.html

**Orden de lectura sugerido:** la PEP 249 (es corta y es el contrato); después la página de adaptación de tipos de `psycopg`.

---

## 🚀 8. Cierre

El DB-API 2.0 es una convención, no una biblioteca: cada *driver* implementa `connect`, `cursor`, `execute` y `commit` a su
manera, con su propio marcador de parámetros, sus propios tipos devueltos y su propio `with`. La regla de JDBC sigue intacta
—el valor va como parámetro— y la transacción se confirma explícitamente.

**La señal de que quedó bien:** *"Pasamos un script de SQLite a Postgres y lo único que cambiamos fue el marcador; los
`Decimal` llegaron solos."*

> 🏷️ **Cierra la sección con su tag**, cuando los ejercicios que elegiste estén hechos:
>
> ```bash
> git tag -a op-db-fase-01 -m "op db01 cerrada: el DB-API como convención, marcadores, tipos y el with"
> ```
>
> Los commits llevan su prefijo (`op db01: …`) y los de ejercicio su número
> (`op db01 ej07: …`).
