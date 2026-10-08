# 🪶 db04 — SQLite a fondo

> Python para desarrolladores Java senior · **Carta** · Track `db` — Hablarle a cada sistema de
> datos desde Python · sección 4 de 15
> Se lee suelta: no hace falta ninguna otra sección de la carta.
> Versiones verificadas contra PyPI el 05/10/2026 · Código probado el 05/10/2026 con Python 3.14.7,
> en contenedor: las salidas son las de esa corrida.

---

## 🎯 1. Qué problema resuelve

SQLite viene con Python, no necesita servidor y guarda una base entera en un archivo. En Áurea es la base natural de todo
lo pequeño: la cola local del agente que corre en cada sede, el caché de la herramienta de Patricia, la base de pruebas, el
inventario de exportes de la noche. Este perfil la conoce de nombre y probablemente la considera un juguete para pruebas.

No lo es: es la base de datos más desplegada del mundo, y con la configuración correcta atiende sin problema una carga de
lectura mucho mayor que la de Áurea. Pero tiene **tres comportamientos por defecto** que sorprenden a quien llega de
Postgres, y que en Python se heredan sin aviso: los **tipos son sugerencias**, las **claves foráneas están apagadas**, y
**solo una conexión puede escribir a la vez**. Los tres tienen solución con una línea; hay que saber que existen.

---

## 🧠 2. El modelo

| Comportamiento por defecto | Qué significa | La línea que lo cambia |
|---|---|---|
| Afinidad de tipos | Una columna `INTEGER` acepta `'abc'`: el tipo es una preferencia | `CREATE TABLE … STRICT` |
| Claves foráneas apagadas | `REFERENCES` se acepta y no se verifica | `PRAGMA foreign_keys = ON`, **en cada conexión** |
| Diario de *rollback* | Un escritor bloquea a los lectores al confirmar | `PRAGMA journal_mode = WAL` (persiste en el archivo) |
| Un solo escritor | La segunda escritura espera o falla con `database is locked` | `timeout=` al conectar; diseño con un escritor |
| Transacciones del módulo `sqlite3` | Modo heredado, anterior al DB-API estricto | `autocommit=False` (Python 3.12+) |

### Tu instinto de Java dice… y esta vez se equivoca

En Java, H2 o Derby en memoria son la base de pruebas, y se comportan casi como la de producción. El instinto usa SQLite igual:
como Postgres de bolsillo. Las pruebas pasan con SQLite y fallan en Postgres —o al revés, pasan cosas en producción que la
prueba nunca vio— porque SQLite aceptó un texto en una columna numérica y una fila huérfana que Postgres habría rechazado.
Para pruebas de una aplicación Postgres, Postgres en un contenedor (`qa`).

---

## 💻 3. El ejemplo que corre

Sin dependencias. `sqlite_trampas.py`:

```python
"""Las tres trampas de SQLite por defecto, y la línea que corrige cada una."""

import sqlite3
import threading
import time

# ------------------------------------------------- 1. los tipos son sugerencias
db = sqlite3.connect(":memory:", autocommit=False)
db.execute("CREATE TABLE abono_flexible (valor INTEGER)")
db.execute("INSERT INTO abono_flexible VALUES ('mil pesos')")
print("INTEGER acepta texto:", db.execute("SELECT valor, typeof(valor) FROM abono_flexible").fetchone())
db.execute("CREATE TABLE abono_estricto (valor INTEGER) STRICT")
try:
    db.execute("INSERT INTO abono_estricto VALUES ('mil pesos')")
except sqlite3.IntegrityError as e:
    print("STRICT lo rechaza:", e)

# ------------------------------------------------- 2. las claves foráneas, apagadas
db.execute("CREATE TABLE sede (codigo TEXT PRIMARY KEY)")
db.execute("CREATE TABLE cita (sede TEXT REFERENCES sede(codigo))")
db.commit()                                                            # el DDL también es transaccional
db.execute("INSERT INTO cita VALUES ('CHIA')")                         # no existe esa sede
print("fila huérfana aceptada:", db.execute("SELECT count(*) FROM cita").fetchone()[0])
db.rollback()
db.autocommit = True                                                   # PRAGMA no corre dentro de una transacción
db.execute("PRAGMA foreign_keys = ON")
try:
    db.execute("INSERT INTO cita VALUES ('CHIA')")
except sqlite3.IntegrityError as e:
    print("con foreign_keys = ON:", e)

# ------------------------------------------------- 3. un solo escritor
PATH = "agenda.db"
setup = sqlite3.connect(PATH, autocommit=True)
setup.execute("PRAGMA journal_mode = WAL")
setup.execute("CREATE TABLE IF NOT EXISTS turno (n INTEGER)")
setup.close()


def long_writer():
    w = sqlite3.connect(PATH, autocommit=False)
    w.execute("INSERT INTO turno VALUES (1)")                          # toma el bloqueo de escritura
    time.sleep(1.5)
    w.commit()
    w.close()


threading.Thread(target=long_writer).start()
time.sleep(0.2)
reader = sqlite3.connect(PATH)
print("en WAL, el lector no espera:", reader.execute("SELECT count(*) FROM turno").fetchone()[0], "filas")
second = sqlite3.connect(PATH, timeout=0.5, autocommit=True)
start = time.perf_counter()
try:
    second.execute("INSERT INTO turno VALUES (2)")
except sqlite3.OperationalError as e:
    print(f"segundo escritor: {e} tras {time.perf_counter() - start:.1f} s")
```

```bash
python3 sqlite_trampas.py
```

Salida (Python 3.14.7, 05/10/2026):

```text
INTEGER acepta texto: ('mil pesos', 'text')
STRICT lo rechaza: cannot store TEXT value in INTEGER column abono_estricto.valor
fila huérfana aceptada: 1
con foreign_keys = ON: FOREIGN KEY constraint failed
en WAL, el lector no espera: 0 filas
segundo escritor: database is locked tras 0.6 s
```

Las tres trampas y sus correcciones. `'mil pesos'` se guardó en una columna `INTEGER` como texto hasta que la tabla fue
`STRICT`. La cita de una sede que no existe entró hasta encender las claves foráneas. Y mientras un escritor tiene la
transacción abierta, el lector en modo WAL lee el estado confirmado sin esperar, pero un segundo escritor espera su `timeout`
y falla con `database is locked`.

**Detalles con intención**

- **`autocommit=False`** (Python 3.12+) hace que `sqlite3` se comporte como pide el DB-API (`db01`): una transacción abierta
  siempre, confirmada con `commit()`. El valor por defecto sigue siendo el modo heredado, por compatibilidad.
- **El `commit()` después de los `CREATE TABLE`** no es decorativo: en SQLite, como en Postgres, el DDL es transaccional, y el
  `rollback()` de la fila huérfana se habría llevado también las tablas. La primera versión de este ejemplo no lo tenía y
  falló con `no such table: cita`. (En MySQL y Oracle, en cambio, el DDL confirma solo.)
- **`PRAGMA foreign_keys` es por conexión** y no se guarda en el archivo: cada conexión que abra la base lo tiene que encender.
  En un proyecto, va en la función que crea las conexiones.
- **`PRAGMA journal_mode = WAL` sí se guarda** en el archivo: se pone una vez. El costo es un par de archivos más (`-wal`,
  `-shm`) junto a la base, que hay que copiar juntos en un respaldo.
- **El `timeout` es el tiempo que una escritura espera** el bloqueo antes de fallar. Con 5 segundos (el valor por defecto), una
  escritura que choca con otra casi siempre termina pasando; con un proceso que escribe sin parar, nunca.

---

## ⚠️ 4. Lo que se rompe

**La base en una carpeta de red.** SQLite depende de los bloqueos de archivo del sistema operativo, y las carpetas
compartidas por red (SMB, NFS) los implementan mal. Una base de SQLite en la carpeta compartida de la sede se corrompe con dos
computadores escribiendo. Es la advertencia más repetida de la documentación de SQLite.

**Copiar el archivo con la base abierta.** Un `cp agenda.db respaldo.db` mientras alguien escribe, en modo WAL, copia una base
sin las últimas transacciones o inconsistente. El respaldo correcto es `conn.backup()` de `sqlite3`, o `VACUUM INTO`.

**Muchos procesos escribiendo.** Diez trabajadores de una cola escribiendo en el mismo SQLite se turnan, y con suficiente carga
los `database is locked` aparecen aunque haya `timeout`. Se diseña con un solo escritor (los demás le mandan los datos) o se
usa Postgres.

**Los tipos de fecha.** SQLite no tiene tipo de fecha: guarda texto, número o real, y `sqlite3` dejó en desuso sus adaptadores
por defecto en Python 3.12. Se registran adaptadores propios o se guarda texto ISO 8601 a propósito (`db01`).

---

## ⚖️ 5. Cuándo NO usarlo

**Con varios procesos que escriben a la vez, todo el tiempo.** Es el límite de diseño de SQLite, no un error de configuración.

**Como base de pruebas de una aplicación Postgres.** Por los tipos, las claves foráneas y el SQL que cambia.

**Cuando varios computadores comparten la base por red.** Para eso existe un servidor de base de datos.

---

## 🧪 6. Ejercicios (10)

**🟢 Fácil (1–3)**

1. Inserta `'12'` (texto) en `abono_flexible` y consulta `typeof`. **Criterio:** reportas qué tipo quedó y por qué (afinidad).
2. Cierra la conexión, ábrela de nuevo e intenta la fila huérfana. **Criterio:** se acepta otra vez, y explicas por qué.
3. Consulta `PRAGMA journal_mode` en una base nueva y en `agenda.db`. **Criterio:** los dos valores.

**🟡 Intermedio (4–6)**

4. Escribe una función `connect(path)` de la casa que encienda claves foráneas, ponga WAL y un `timeout`. **Criterio:** una prueba
   demuestra cada una.
5. Haz un respaldo en caliente con `conn.backup()` mientras un hilo escribe. **Criterio:** el respaldo abre y tiene una cantidad
   de filas consistente.
6. Repite el punto 3 del ejemplo sin WAL. **Criterio:** describes si el lector espera y cuándo.

**🟠 Difícil (7–9)**

7. Mide cuántas escrituras por segundo soporta SQLite con una transacción por fila y con lotes de 1 000. **Criterio:** la tabla de
   tiempos.
8. Diseña el escritor único: cinco hilos productores mandan filas a una cola y un hilo las escribe en lotes. **Criterio:** cero
   `database is locked` con 50 000 filas.
9. Migra una tabla existente a `STRICT` (crear, copiar, renombrar) y encuentra las filas que no cumplen. **Criterio:** la lista de
   filas problemáticas antes de migrar.

**🔴 Muy difícil (10)**

10. Decide qué guarda Áurea en SQLite y qué no. **Criterio:** una página. *Rúbrica:* (a) cada uso (agente de sede, cachés,
    pruebas, inventario) con su decisión; (b) quién escribe y cuántos procesos; (c) cómo se respalda; (d) la señal que haría
    pasar a Postgres.

---

## 📚 7. Referencias

**Documentación oficial**

- `sqlite3`: https://docs.python.org/3/library/sqlite3.html
- SQLite, tablas `STRICT`: https://www.sqlite.org/stricttables.html
- SQLite, WAL: https://www.sqlite.org/wal.html
- SQLite, cuándo usarlo: https://www.sqlite.org/whentouse.html

**Orden de lectura sugerido:** "Appropriate Uses For SQLite" (cuándo usarlo), que es honesto sobre sus límites; después la página
de WAL.

---

## 🚀 8. Cierre

SQLite es una base de datos seria con tres valores por defecto que hay que cambiar: tablas `STRICT`, `PRAGMA foreign_keys = ON`
en cada conexión, y WAL en el archivo. Su límite real es el escritor único, y se diseña alrededor de él o se elige otra base.

**La señal de que quedó bien:** *"El agente de cada sede guarda su cola en SQLite desde hace meses, y nunca vimos un `database
is locked`."*

> 🏷️ **Cierra la sección con su tag**, cuando los ejercicios que elegiste estén hechos:
>
> ```bash
> git tag -a op-db-fase-04 -m "op db04 cerrada: STRICT, foreign_keys, WAL y el escritor único"
> ```
>
> Los commits llevan su prefijo (`op db04: …`) y los de ejercicio su número
> (`op db04 ej07: …`).
