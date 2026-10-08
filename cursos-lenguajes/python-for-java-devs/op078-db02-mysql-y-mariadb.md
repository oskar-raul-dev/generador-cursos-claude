# 🐬 db02 — MySQL y MariaDB

> Python para desarrolladores Java senior · **Carta** · Track `db` — Hablarle a cada sistema de
> datos desde Python · sección 2 de 15
> Se lee suelta: no hace falta ninguna otra sección de la carta.
> Versiones verificadas contra PyPI el 05/10/2026 · Código probado el 05/10/2026 con Python 3.14.7,
> en contenedor: las salidas son las de esa corrida.

---

## 🎯 1. Qué problema resuelve

Odontovía, el sistema de gestión de Áurea, guarda doce años de datos en MySQL, en el equipo debajo del mesón de cada sede.
Todo lo que Áurea quiera saber de su propia operación —agendas, abonos, planes de tratamiento— empieza por leer esa base
desde Python, sin romperla y sin malinterpretar lo que devuelve.

MySQL y MariaDB (su bifurcación, compatible en lo básico) se hablan desde Python con tres *drivers*: **`mysqlclient`** (en C,
el más rápido, necesita las bibliotecas de MySQL para compilarse), **`PyMySQL`** (Python puro, se instala en cualquier lado)
y **`asyncmy`** (asíncrono). La conexión es lo fácil. Lo difícil son tres comportamientos que sorprenden a quien llega de
Postgres, y que en una base de doce años casi seguro están: **`utf8` que no es UTF-8**, **comparaciones que ignoran tildes**,
y un **modo no estricto** que trunca datos en silencio.

---

## 🧠 2. El modelo

| *Driver* | Versión | Implementación | Instalar |
|---|---|---|---|
| `mysqlclient` | 2.3.0 | C, sobre `libmysqlclient` | Necesita `pkg-config` y las cabeceras de MySQL o MariaDB si no hay rueda para la plataforma |
| `PyMySQL` | 1.2.3 | Python puro | `uv add pymysql`, en cualquier lado |
| `asyncmy` | 0.2.15 | Cython, asíncrono | Para código con `asyncio` |

Los tres usan `paramstyle = "format"`: el marcador es `%s` (`db01`).

| La trampa | En MySQL/MariaDB | En Postgres |
|---|---|---|
| Juego de caracteres `utf8` | Es **`utf8mb3`**: hasta 3 bytes, sin emojis ni algunos caracteres | UTF-8 completo |
| Colación por defecto | **Insensible a tildes y mayúsculas** (`_ai_ci`): `'Muñoz' = 'munoz'` | Sensible: hace falta `unaccent` o `ILIKE` |
| Dato que no cabe | En modo estricto, error; **sin él, se trunca con un aviso** | Siempre error |

### Tu instinto de Java dice… y esta vez se equivoca

Con JDBC y MySQL, el instinto pone `characterEncoding=UTF-8` en la URL y da el tema por cerrado. En el *driver* de Python el
equivalente es `charset="utf8mb4"`, y ni el uno ni el otro arreglan una **tabla** creada hace años con `CHARACTER SET utf8`:
la conexión puede hablar UTF-8 completo y la columna seguir sin poder guardar un emoji.

---

## 💻 3. El ejemplo que corre

```bash
uv add pymysql
```

`trampas.py` corre las tres trampas contra MySQL 9.7 y MariaDB 12.3:

```python
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
```

```bash
docker run -d --name aurea-mysql -e MYSQL_ROOT_PASSWORD=aurea-local -p 3306:3306 mysql:9.7.2
AUREA_MYSQL=127.0.0.1 python3 trampas.py
```

Salida (Python 3.14.7, 05/10/2026):

```text
--- MySQL 9.7.2 · colación utf8mb4_0900_ai_ci
    modo estricto: True
    utf8     emoji: error 1366
    utf8mb4  emoji: guardado
    'Muñoz' = 'munoz': True
    sin modo estricto se guardó: ZIPAQ · aviso: Data truncated for column 'codigo' at row 1
--- MariaDB 12.3.3-MariaDB-ubu2404 · colación utf8mb4_uca1400_ai_ci
    modo estricto: True
    utf8     emoji: error 1366
    utf8mb4  emoji: guardado
    'Muñoz' = 'munoz': True
    sin modo estricto se guardó: ZIPAQ · aviso: Data truncated for column 'codigo' at row 1
```

Las tres trampas, en los dos motores. La tabla con `CHARACTER SET utf8` rechaza el emoji aunque la conexión sea `utf8mb4`.
`'Muñoz' = 'munoz'` es verdadero, lo que es cómodo para buscar pacientes —exactamente lo que en `tx08` costó una función— y
peligroso para una restricción `UNIQUE`, que considera iguales a los dos. Y sin modo estricto, `ZIPAQUIRA` se guarda como
`ZIPAQ` con un aviso que nadie lee: el *driver* no lanza nada.

**Detalles con intención**

- **`charset="utf8mb4"` en la conexión** es obligatorio, y no basta: la tabla y la columna tienen su propio juego de
  caracteres. En una base heredada se revisa con `information_schema.COLUMNS`.
- **`SHOW WARNINGS`** es la única forma de ver el truncamiento; `PyMySQL` no convierte avisos en excepciones. En una base
  heredada, el `sql_mode` del servidor se revisa antes de escribir nada.
- **`autocommit=True`** es para el ejemplo; para escribir en Odontovía, transacciones explícitas, y mejor todavía, no escribir
  en Odontovía (lo hace su proveedor).

---

## ⚠️ 4. Lo que se rompe

**`mysqlclient` que no instala.** En una máquina sin rueda precompilada para su plataforma, `pip install mysqlclient` falla
pidiendo `pkg-config` y `mysql_config`. La salida rápida es `PyMySQL`; la definitiva, instalar `default-libmysqlclient-dev` (o
el de MariaDB) en la imagen.

**La restricción `UNIQUE` que choca por una tilde.** Con colación `_ai_ci`, insertar `Peña` cuando ya existe `Pena` falla por
clave duplicada. Si los dos son pacientes distintos, la columna necesita una colación binaria o sensible (`_as_cs`).

**Leer `DATETIME` como si tuviera zona horaria.** `DATETIME` de MySQL no guarda zona: llega como `datetime` ingenuo. Si
Odontovía guardó la hora de Bogotá, hay que saberlo y declararlo (`zoneinfo`) al leer.

**Consultas largas sobre la base de una sede.** El equipo debajo del mesón atiende la agenda en vivo. Una consulta de análisis
sin índice bloquea o vuelve lenta la recepción. Las lecturas pesadas van contra una copia o en la noche.

---

## ⚖️ 5. Cuándo NO usarlo

**`mysqlclient` en un contenedor mínimo sin necesidad.** Si la carga no es intensa, `PyMySQL` evita compilar y las
bibliotecas del sistema.

**MySQL para un sistema nuevo en Áurea.** Se lee porque Odontovía está ahí; para algo nuevo, el camino base usa Postgres, y la
lista de trampas de arriba es parte de la razón.

**Escribir directamente en la base de Odontovía.** El proveedor no lo soporta, y una escritura mal hecha rompe el sistema que
atiende pacientes. Se lee; se escribe por las vías del proveedor.

---

## 🧪 6. Ejercicios (10)

**🟢 Fácil (1–3)**

1. Lista las columnas con `utf8mb3` de una base con `information_schema.COLUMNS`. **Criterio:** la consulta y su resultado.
2. Inserta `Pena` y `Peña` en una columna `UNIQUE` con la colación por defecto. **Criterio:** el error exacto.
3. Repite la trampa 3 con el modo estricto activado. **Criterio:** el error que lanza `PyMySQL` y su código.

**🟡 Intermedio (4–6)**

4. Convierte la tabla `nota` de `utf8` a `utf8mb4` con `ALTER TABLE … CONVERT TO`. **Criterio:** el emoji se guarda después.
5. Cambia la columna `UNIQUE` a una colación sensible a tildes. **Criterio:** `Pena` y `Peña` conviven.
6. Lee un `DATETIME` y conviértelo a `datetime` con zona de Bogotá. **Criterio:** una prueba con una hora de prueba.

**🟠 Difícil (7–9)**

7. Mide `PyMySQL` contra `mysqlclient` leyendo 200 000 filas. **Criterio:** la tabla de tiempos, con las versiones.
8. Escribe la misma lectura con `asyncmy`. **Criterio:** diez consultas concurrentes y el tiempo total.
9. Escribe un "inspector" de base heredada: `sql_mode`, juegos de caracteres y colaciones de cada tabla. **Criterio:** un
   reporte que marca lo riesgoso.

**🔴 Muy difícil (10)**

10. Diseña la extracción nocturna de las bases de Odontovía de las diez sedes. **Criterio:** una página. *Rúbrica:* (a) cómo se
    lee sin afectar la recepción; (b) cómo se tratan juegos de caracteres, colaciones y zonas horarias; (c) qué pasa si una sede
    no responde; (d) dónde quedan los datos y en qué tipos.

---

## 📚 7. Referencias

**Documentación oficial**

- `PyMySQL`: https://pymysql.readthedocs.io/en/latest/
- `mysqlclient`: https://github.com/PyMySQL/mysqlclient
- MySQL, `utf8mb3` y `utf8mb4`: https://dev.mysql.com/doc/refman/9.4/en/charset-unicode-sets.html
- MySQL, el modo SQL: https://dev.mysql.com/doc/refman/9.4/en/sql-mode.html

**Orden de lectura sugerido:** la página de juegos de caracteres Unicode de MySQL; después la del modo SQL.

---

## 🚀 8. Cierre

A MySQL y MariaDB se les habla desde Python con `PyMySQL` (que instala en cualquier lado) o `mysqlclient` (más rápido, con
dependencias del sistema), con el marcador `%s`. Lo que hay que saber antes de leer una base heredada son tres trampas:
`utf8` es `utf8mb3`, la colación ignora tildes, y sin modo estricto los datos se truncan en silencio.

**La señal de que quedó bien:** *"Leímos Odontovía de las diez sedes una noche, y los emojis de las notas, las tildes de los
apellidos y las horas de las citas llegaron como eran."*

> 🏷️ **Cierra la sección con su tag**, cuando los ejercicios que elegiste estén hechos:
>
> ```bash
> git tag -a op-db-fase-02 -m "op db02 cerrada: PyMySQL y las tres trampas de MySQL y MariaDB"
> ```
>
> Los commits llevan su prefijo (`op db02: …`) y los de ejercicio su número
> (`op db02 ej07: …`).
