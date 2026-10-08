# Bloque 02 — SQL

> Por qué el orden en que escribes un `SELECT` no es el orden en que se evalúa, qué hace cada clase
> de join y qué pasa con los nulos dentro de uno, cuándo una subconsulta es mejor que un join y
> cuándo peor, y qué de lo que escribes es SQL y qué es un dialecto que no funcionará en el motor de
> al lado. Al terminarlo sabes escribir, en cuatro motores, lo que te pida la pizarra.
> **Vigencia:** 27 de septiembre de 2026.

---

## 📖 Orden de lectura

Acumulativo dentro del bloque. `08` cierra el eje del corpus —qué manda el estándar y qué hace tu
motor— y por eso va al final: resume los siete anteriores.

| # | Documento | Preguntas | Qué cubre |
|---|---|---|---|
| `01` | [Familias del lenguaje y tipos](01-familias-del-lenguaje-y-tipos.md) | 16 | DDL, DML, DCL y TCL, y la confirmación implícita del DDL; `numeric` frente a `float`, `timestamptz`, texto, `uuid`, arrays y `jsonb` |
| `02` | [`SELECT` y el orden lógico](02-select-y-el-orden-logico.md) | 18 | Proyección, filtros, orden, `LIMIT`/`OFFSET`, y el orden lógico de evaluación, que no es el de escritura |
| `03` | [Joins](03-joins.md) | 20 | Interno, externo, cruzado y reflexivo; semi-join y anti-join; qué pasa con los nulos |
| `04` | [Agregación y subconsultas](04-agregacion-y-subconsultas.md) | 20 | `GROUP BY`, `HAVING`, la columna no agrupada; correlacionadas o no; `EXISTS` frente a `IN` frente a `JOIN` |
| `05` | [CTE y recursión](05-cte-y-recursion.md) | 16 | `WITH`, materialización, y CTE recursivas para jerarquías y series |
| `06` | [Funciones de ventana](06-funciones-de-ventana.md) | 21 | `ROW_NUMBER`, `RANK`, `LAG`/`LEAD`, particiones y marcos, y el marco por defecto, que agrupa los empates |
| `07` | [Escritura, `UPSERT` y vistas](07-escritura-upsert-y-vistas.md) | 17 | Operadores de conjunto, `ON CONFLICT`, `MERGE`, `RETURNING`, vistas y vistas materializadas |
| `08` | [Dialectos](08-dialectos.md) | 20 | Qué es portable entre los cuatro motores, y por qué lo estándar no es lo portable |
| `09` | [Simulación de entrevista](09-simulacion-de-entrevista.md) | 28 `S#` + 4 escenarios | Las preguntas del bloque mezcladas, con cronómetro, y cuatro escenarios |
| `10` | [Respuestas](10-respuestas.md) | 180 | Todas las respuestas del bloque, con el enunciado literal y en tres capas |

**148 preguntas** en los ocho capítulos y **32 más** en la simulación, todas con respuesta en
[`10`](10-respuestas.md).

> **📝 Longitud.** Los ocho quedan entre 403 y 550 líneas, en la banda ancha de los capítulos
> densos: cada uno contrasta el mismo comportamiento en **cuatro motores**, y eso multiplica las
> sesiones. `07` está en el techo. `03` y `04` volvieron a correr sus sesiones de `psql` en español
> el 27 de septiembre de 2026, con los tiempos de la prosa ajustados a esa corrida.

---

## 🧩 Qué asume leído

El bloque [`01`](../01-fundamentos-y-modelo-relacional/README.md) entero. Aquí se usan «clave
candidata», «dependencia funcional» y «lógica de tres valores» sin volver a definirlos.

---

## 🔑 Dueños de concepto de este bloque

| Concepto | Dueño |
|---|---|
| Los tipos y sus trampas: dinero, fecha con zona, texto, JSON | `02/01` |
| El orden lógico de evaluación de un `SELECT` | `02/02` |
| Los joins, y los nulos dentro de ellos | `02/03` |
| `EXISTS` frente a `IN` frente a `JOIN` | `02/04` |
| CTE y recursión | `02/05` |
| Funciones de ventana y sus marcos | `02/06` |
| Operadores de conjunto, `ON CONFLICT` y `MERGE` | `02/07` |
| **Dialecto: qué es portable y qué no** | `02/08` — lo usa todo el corpus |

Qué columna elegir para cada fecha y cada importe, con sus casos medidos, es de
[`12/03`](../12-diseno/03-fechas-zonas-y-dinero.md); la paginación por clave frente a `OFFSET`, de
[`12/06`](../12-diseno/06-paginacion-y-busqueda-de-texto.md).

---

## 🧭 Si el calendario aprieta

**`03` y `06`.** Los joins con nulos y las funciones de ventana son las dos pizarras de SQL que más
se piden en una entrevista de backend: «los clientes sin pedidos» y «el último pedido de cada
cliente». `02` se lee en veinte minutos y explica la mitad de los errores de `WHERE` frente a
`HAVING`.

---

**Anterior:** [`01`](../01-fundamentos-y-modelo-relacional/README.md) · **Siguiente bloque:**
[`03 — El motor por dentro`](../03-el-motor-por-dentro/README.md) · **Volver:** [README del
corpus](../README.md).
