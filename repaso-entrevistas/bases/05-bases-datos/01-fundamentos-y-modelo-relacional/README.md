# Bloque 01 — Fundamentos y modelo relacional

> Por qué una tabla no es un fichero, qué es exactamente una clave y cuántas clases hay, cómo se
> traduce cada operador del álgebra a SQL, hasta dónde normalizar y cuándo desnormalizar a
> propósito, y por qué `NULL` rompe cosas que parecían seguras. Al terminarlo sabes defender un
> esquema de la tienda tabla a tabla y explicar por qué un `NOT IN` devolvió cero filas.
> **Vigencia:** 27 de septiembre de 2026.

---

## 📖 Orden de lectura

**Acumulativo**: cada capítulo usa el vocabulario del anterior. En orden la primera vez.

| # | Documento | Preguntas | Qué cubre |
|---|---|---|---|
| `01` | [Qué resuelve un DBMS](01-que-resuelve-un-dbms.md) | 18 | Concurrencia, integridad, recuperación y consulta declarativa frente a archivos; por qué una tabla no es un fichero |
| `02` | [El modelo relacional y sus claves](02-el-modelo-relacional-y-sus-claves.md) | 20 | Relación, tupla, atributo, dominio; clave primaria, candidata, alternativa, foránea y compuesta; natural frente a sustituta |
| `03` | [Álgebra relacional](03-algebra-relacional.md) | 18 | Selección, proyección, producto, joins, unión, diferencia, intersección y división, y la traducción de cada operador a SQL |
| `04` | [Normalización y desnormalización](04-normalizacion-y-desnormalizacion.md) | 17 | Dependencias funcionales, anomalías, de 1FN a 3FN con BCNF como cierre; cuándo desnormalizar a propósito y cómo documentarlo |
| `05` | [Del modelo ER al esquema](05-del-modelo-er-al-esquema.md) | 20 | Cardinalidades, N:M, entidades débiles; `NOT NULL`, `UNIQUE`, `CHECK` y `FOREIGN KEY` con sus acciones |
| `06` | [Nulos y lógica de tres valores](06-nulos-y-logica-de-tres-valores.md) | 23 | Por qué `NULL = NULL` es desconocido, y qué rompe en `WHERE`, `IN`, `NOT IN`, agregados y `UNIQUE` |
| `07` | [Simulación de entrevista](07-simulacion-de-entrevista.md) | 28 `S#` + 4 escenarios | Las preguntas del bloque mezcladas, con cronómetro, y cuatro escenarios para defender en voz alta |
| `08` | [Respuestas](08-respuestas.md) | 148 | Todas las respuestas del bloque, con el enunciado literal y en tres capas |

**116 preguntas** en los seis capítulos y **32 más** en la simulación, todas con respuesta en
[`08`](08-respuestas.md).

> **📝 Longitud.** Los seis capítulos quedan entre 351 y 406 líneas: por encima de la banda
> objetivo y por debajo del techo de 550, porque se podó prosa y no sesiones. `01`, `03`, `05` y
> `06` volvieron a correr sus sesiones de `psql` en español el 27 de septiembre de 2026, y lo dicen
> en su §1.

---

## 🧩 Qué asume leído

Nada. Es el primer bloque del corpus, y el que introduce la tienda: sus seis tablas y los
identificadores que aparecen de aquí al final —`CLI-00311`, con 52 pedidos; `CLI-00007`, sin
ninguno; `PED-00042`, el pedido de ejemplo; `PED-99999`, anulado y sin pagos—. El esquema llega
**sin un solo índice** más allá de los que crean `PRIMARY KEY` y `UNIQUE`, para que el bloque 03
pueda enseñar el antes y el después. Todo está en
[`../prompts/dominio-entorno-y-datos-fijos.md`](../prompts/dominio-entorno-y-datos-fijos.md).

---

## 🔑 Dueños de concepto de este bloque

| Concepto | Dueño |
|---|---|
| Qué garantiza un DBMS que un fichero no | `01/01` |
| Claves, y natural frente a sustituta en teoría | `01/02` |
| Los operadores del álgebra y su traducción a SQL | `01/03` |
| Las formas normales, y cuándo se rompen a propósito | `01/04` |
| Restricciones declaradas y acciones de las claves foráneas | `01/05` |
| **Nulos y lógica de tres valores** | `01/06` — lo usa todo el corpus |

`01/06` es el que más se cita desde fuera: lo usan los joins, la agregación, el mapeo de tipos y el
diseño de claves. La elección práctica de clave, con sus costes medidos, es de
[`12/02`](../12-diseno/02-identidad-y-claves.md).

---

## 🧭 Si el calendario aprieta

**`06` y `02`.** Los nulos aparecen en casi cualquier pregunta de SQL con trampa —el `NOT IN` que
devuelve cero filas es un clásico de entrevista—, y las claves son el vocabulario que da por sabido
todo lo demás. `04` se puede leer después: la normalización se pregunta, pero rara vez con
profundidad.

---

**Siguiente bloque:** [`02 — SQL`](../02-sql/README.md) · **Volver:** [README del
corpus](../README.md).
