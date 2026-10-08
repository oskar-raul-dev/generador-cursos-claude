# 📄 or06 — Sin ORM

> Python para desarrolladores Java senior · **Carta** · Track `or` — ORMs y acceso a datos desde
> Python · sección 6 de 8
> Se lee suelta: no hace falta ninguna otra sección de la carta.
> Versiones verificadas contra PyPI el 05/10/2026 · Código probado el 05/10/2026 con Python 3.14.7,
> en contenedor: las salidas son las de esa corrida.

---

## 🎯 1. Qué problema resuelve

El reporte de cartera de Áurea tiene doce consultas, y ninguna es un CRUD: son agregados, ventanas, `CTE`, comparaciones con el mes
anterior. Escritas con un ORM, quedan como expresiones de Python que nadie puede pegar en la consola de la base para revisarlas; escritas
como cadenas dentro del código, quedan mezcladas con el Python y sin resaltado de sintaxis. Patricia sabe leer SQL básico, y el contador
quiere ver exactamente qué se suma.

La salida es el extremo del eje de `or01` que más se subestima: **SQL escrito por una persona, en archivos `.sql` versionados**, y una
biblioteca pequeña que lo convierte en funciones de Python. **`aiosql`** y **PugSQL** hacen eso; **`sqlglot`** analiza y traduce SQL entre
motores; **PyPika** construye SQL cuando las condiciones varían (`or01`); **`dataset`** y **`records`** son envoltorios mínimos para
scripts. Esta sección arma el reporte con `aiosql` y usa `sqlglot` para lo que el SQL a mano no da solo: portabilidad y análisis.

---

## 🧠 2. El modelo

| Herramienta | Versión | Qué hace | Para qué |
|---|---|---|---|
| `aiosql` | 15.0 | Lee un `.sql` con consultas nombradas y genera funciones | **SQL en archivos, llamado como Python**, síncrono o asíncrono |
| PugSQL | 0.3.7 | Lo mismo, sobre SQLAlchemy | La misma idea, otra API |
| `sqlglot` | 30.21.0 | Analiza SQL: traduce entre dialectos, extrae tablas y columnas, formatea | Portabilidad, revisión y pruebas sobre el SQL |
| PyPika | 0.51.1 | Construye SQL con objetos | Consultas con condiciones que cambian |
| `dataset` | 2.0.0 | Tablas como listas de diccionarios | Scripts rápidos de carga |
| `records` | 0.6.0 💤 | SQL que devuelve filas cómodas | Scripts; sin versiones desde 2024 |

### Tu instinto de Java dice… y esta vez se equivoca

En Java existe este estilo —MyBatis con sus *mappers* XML, jOOQ con SQL tipado— y es una elección consciente contra JPA. El instinto lo asocia a
mucha configuración. En Python, `aiosql` es un archivo `.sql` con comentarios `-- name:` y dos líneas de Python; no hay XML ni generación de
código previa.

---

## 💻 3. El ejemplo que corre

```bash
uv add aiosql sqlglot
```

`cartera.sql` —el SQL vive aquí, versionado, revisable por quien sepa SQL—:

```sql
-- name: crear_tablas#
CREATE TABLE plan (id INTEGER PRIMARY KEY, codigo TEXT, sede TEXT);
CREATE TABLE fase (id INTEGER PRIMARY KEY, plan_id INTEGER REFERENCES plan(id), valor INTEGER, estado TEXT);

-- name: nuevo_plan(codigo, sede)<!
INSERT INTO plan (codigo, sede) VALUES (:codigo, :sede) RETURNING id;

-- name: nueva_fase(plan_id, valor, estado)!
INSERT INTO fase (plan_id, valor, estado) VALUES (:plan_id, :valor, :estado);

-- name: saldos_por_sede(sede, n)
-- Los planes de una sede con más saldo pendiente.
SELECT p.codigo, SUM(f.valor) AS saldo
FROM plan AS p JOIN fase AS f ON f.plan_id = p.id
WHERE p.sede = :sede AND f.estado = 'pendiente'
GROUP BY p.codigo
ORDER BY saldo DESC
LIMIT :n;
```

`reporte.py`:

```python
"""El reporte desde SQL en archivos (aiosql) y el mismo SQL analizado y traducido (sqlglot)."""

import random
import sqlite3

import aiosql
import sqlglot
from sqlglot import exp

queries = aiosql.from_path("cartera.sql", "sqlite3")
conn = sqlite3.connect(":memory:")
queries.crear_tablas(conn)

random.seed(2)
for i in range(60):
    plan_id = queries.nuevo_plan(conn, codigo=f"PL-{i:03d}", sede=random.choice(["Suba", "Centro", "Kennedy"]))
    for _ in range(4):
        queries.nueva_fase(conn, plan_id=plan_id, valor=random.randrange(200_000, 3_000_000, 50_000),
                           estado=random.choice(["pagada", "pendiente"]))
conn.commit()

print("funciones generadas:", [q for q in queries.available_queries if not q.endswith("_cursor")][:4])
print("los tres con más saldo:", list(queries.saldos_por_sede(conn, sede="Suba", n=3)))   # aiosql 15: un generador

sql = queries.saldos_por_sede.sql
tree = sqlglot.parse_one(sql.replace(":sede", "'Suba'").replace(":n", "3"), read="sqlite")
print("tablas que toca:", sorted({t.name for t in tree.find_all(exp.Table)}))
for dialect in ("postgres", "tsql"):
    print(f"en {dialect}:", sqlglot.transpile(tree.sql("sqlite"), read="sqlite", write=dialect)[0])
```

```bash
python3 reporte.py
```

Salida (Python 3.14.7, 05/10/2026):

```text
funciones generadas: ['crear_tablas', 'nueva_fase', 'nuevo_plan', 'saldos_por_sede']
los tres con más saldo: [('PL-033', 6350000), ('PL-024', 5400000), ('PL-051', 4750000)]
tablas que toca: ['fase', 'plan']
en postgres: SELECT p.codigo, SUM(f.valor) AS saldo FROM plan AS p JOIN fase AS f ON f.plan_id = p.id WHERE p.sede = 'Suba' AND f.estado = 'pendiente' GROUP BY p.codigo ORDER BY saldo DESC NULLS LAST LIMIT 3
en tsql: SELECT TOP 3 p.codigo, SUM(f.valor) AS saldo FROM plan AS p JOIN fase AS f ON f.plan_id = p.id WHERE p.sede = 'Suba' AND f.estado = 'pendiente' GROUP BY p.codigo ORDER BY saldo DESC
```

Cada consulta del archivo es una función de Python, y el reporte da los mismos tres planes que el resto del track. La traducción de `sqlglot`
tiene un detalle que vale la sección entera: al pasar a Postgres agregó **`NULLS LAST`**. En SQLite, un orden descendente deja los nulos al final; en
Postgres, al principio. `sqlglot` no tradujo solo la sintaxis, conservó el significado. En T-SQL, el `LIMIT` se volvió `TOP 3`.

**Detalles con intención**

- **La lista de parámetros en el nombre** (`nueva_fase(plan_id, valor, estado)`) es obligatoria desde `aiosql` 15: sin ella, el archivo no carga y
  falla con `SQLParseException: missing mandatory parameter list`, que fue el primer error de este ejemplo. Los tutoriales anteriores no la
  llevan.
- **Los sufijos de los nombres** dicen qué devuelve cada consulta en `aiosql`: `#` es un *script* sin parámetros, `!` una sentencia que no
  devuelve filas, `<!` una que devuelve lo del `RETURNING`, y sin sufijo, una lista de filas.
- **Los parámetros `:sede` y `:n`** los pasa `aiosql` al *driver* como parámetros, no pegados al texto. El SQL del archivo es el que se manda.
- **`sqlglot` entiende el SQL** como árbol (`tx04`): puede listar las tablas que toca una consulta —útil para saber qué reportes se rompen al
  cambiar una tabla— y traducirla a otro motor.
- **`aiosql` 15 devuelve un generador** en las consultas de selección, no una lista: se envuelve en `list()` si se va a recorrer dos veces o
  imprimir.
- **El reemplazo de `:sede` por un literal** es solo para que `sqlglot` analice; la consulta que se ejecuta sigue usando parámetros.

---

## ⚠️ 4. Lo que se rompe

**El SQL en archivos sin pruebas.** Un cambio de columna rompe la consulta y nadie lo sabe hasta que corre el reporte. Cada consulta del `.sql`
tiene una prueba que la ejecuta contra una base de prueba (`qa`); con `aiosql`, es llamar a la función.

**Confiar en la traducción de `sqlglot` sin probar.** Traduce la sintaxis; no garantiza que las funciones tengan la misma semántica en los dos
motores (redondeos, fechas, comparación de cadenas). La consulta traducida se prueba en el motor de destino.

**Consultas con condiciones opcionales.** "Filtrar por sede solo si se pidió" en un `.sql` fijo lleva a trucos (`:sede IS NULL OR p.sede = :sede`)
que confunden al optimizador. Para eso, un constructor (PyPika, SQLAlchemy Core).

**`records` en un proyecto nuevo.** Lleva desde 2024 sin versiones (💤). Para un script, `dataset` o el *driver* directo.

---

## ⚖️ 5. Cuándo NO usarlo

**Para el CRUD de muchas entidades con relaciones.** Escribir a mano el `INSERT` y el `UPDATE` de cuarenta tablas es el trabajo del ORM.

**Si nadie en el equipo lee SQL con soltura.** Su ventaja es que el SQL se lee y se revisa; sin quien lo lea, es solo texto.

**Para consultas que se arman según muchas condiciones.** Un constructor de consultas.

---

## 🧪 6. Ejercicios (10)

**🟢 Fácil (1–3)**

1. Corre el ejemplo. **Criterio:** el resultado coincide con el de `or01`, y explicas cada sufijo de `cartera.sql`.
2. Agrega una consulta `saldo_total_de_sede` con un solo valor de resultado (sufijo `$`). **Criterio:** devuelve un número, no una lista.
3. Formatea la consulta con `sqlglot.transpile(..., pretty=True)`. **Criterio:** la salida legible.

**🟡 Intermedio (4–6)**

4. Escribe las pruebas de cada consulta del `.sql` con `pytest`. **Criterio:** cambiar el nombre de una columna en el esquema hace fallar la prueba.
5. Usa `aiosql` con `aiosqlite` (o `asyncpg`) y la versión asíncrona de las funciones. **Criterio:** el mismo resultado con `await`.
6. Usa `sqlglot` para encontrar todas las consultas del `.sql` que tocan la tabla `fase`. **Criterio:** la lista, sin leerlas a mano.

**🟠 Difícil (7–9)**

7. Traduce la consulta a Postgres y córrela contra Postgres (`db01`). **Criterio:** el mismo resultado, o la diferencia y por qué.
8. Agrega una consulta con una ventana (`RANK() OVER (PARTITION BY sede ...)`) y tradúcela a T-SQL. **Criterio:** la traducción y si cambió algo.
9. Escribe la misma capa con PugSQL. **Criterio:** las diferencias de API con `aiosql`.

**🔴 Muy difícil (10)**

10. Propón pasar los reportes de Áurea a SQL en archivos. **Criterio:** una página. *Rúbrica:* (a) qué consultas se mudan y cuáles se quedan en el ORM;
    (b) cómo se prueban; (c) quién puede revisar el SQL; (d) qué hace `sqlglot` en el CI.

---

## 📚 7. Referencias

**Documentación oficial**

- `aiosql`: https://nackjicholson.github.io/aiosql/
- `sqlglot`: https://sqlglot.com/sqlglot.html
- PugSQL: https://pugsql.org/
- PyPika: https://pypika.readthedocs.io/en/latest/

**Orden de lectura sugerido:** la página de definición de consultas de `aiosql` (los sufijos); después la documentación de `sqlglot`.

---

## 🚀 8. Cierre

El SQL escrito por una persona, en archivos `.sql` versionados, se llama desde Python como funciones con `aiosql`, se revisa en la consola de la base
y lo lee quien sepa SQL. `sqlglot` lo analiza y lo traduce entre motores; PyPika cubre las consultas que cambian según condiciones. El ORM queda para
el CRUD.

**La señal de que quedó bien:** *"El contador pidió ver cómo se calcula el saldo, y le mandamos el archivo `.sql`, no un pedazo de Python."*

> 🏷️ **Cierra la sección con su tag**, cuando los ejercicios que elegiste estén hechos:
>
> ```bash
> git tag -a op-or-fase-06 -m "op or06 cerrada: SQL en archivos con aiosql, analizado y traducido con sqlglot"
> ```
>
> Los commits llevan su prefijo (`op or06: …`) y los de ejercicio su número
> (`op or06 ej07: …`).
