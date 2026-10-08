# Bloque 13 — Laboratorio

> Todo lo anterior, corriendo en Docker, en local, sin nube y sin coste: el entorno y los datos,
> índices medidos, aislamiento y bloqueos en vivo, respaldo y restauración, Redis y MongoDB, y los
> otros modelos. Al terminarlo tienes los cinco motores del corpus levantados con la tienda cargada,
> y has provocado a propósito los errores que en producción llegan sin avisar.
> **Vigencia:** 27 de septiembre de 2026.

---

## 📖 Orden de lectura

`l00` primero: levanta el entorno y carga los datos que usan todos los demás. El resto, cuando
llegues al bloque que practica; `l05` es opcional.

| # | Documento | Preguntas | Qué cubre |
|---|---|---|---|
| `l00` | [El entorno y los datos](l00-el-entorno-y-los-datos.md) | 15 + 6 ejercicios | Los cinco motores, la tienda cargada en PostgreSQL y las mismas filas en MySQL, MariaDB y SQLite; los cinco errores de un entorno así |
| `l01` | [`EXPLAIN` e índices medidos](l01-explain-e-indices-medidos.md) | 15 + 6 ejercicios | El mismo `SELECT` antes y después de su índice, y los tres casos de «el índice no se usa» que [`03/06`](../03-el-motor-por-dentro/06-cuando-el-indice-no-se-usa.md) explica sin sesión |
| `l02` | [Aislamiento y bloqueos en vivo](l02-aislamiento-y-bloqueos-en-vivo.md) | 15 + 6 ejercicios | Dos y tres terminales: la lectura que cambia, quién bloquea a quién, `lock_timeout`, el `40001` y el interbloqueo, y la transacción olvidada |
| `l03` | [Respaldo y restauración](l03-respaldo-y-restauracion.md) | 15 + 6 ejercicios | `pg_dump` y `pg_basebackup` cronometrados, y la recuperación a un instante que deshace un borrado de 273 126 filas |
| `l04` | [Redis y MongoDB](l04-redis-y-mongodb.md) | 15 + 6 ejercicios | La estampida de una caché provocada con 50 peticiones y corregida con un candado; una colección cargada desde PostgreSQL, con su `explain` y su agregación |
| `l05` | [Los otros modelos](l05-los-otros-modelos.md) | 15 + 6 ejercicios | Una sesión mínima con Cassandra, Neo4j, TimescaleDB, pgvector y Qdrant, y OpenSearch, cada una con un error provocado y su teardown. Opcional |
| `06` | [Simulación de entrevista](06-simulacion-de-entrevista.md) | 24 `S#` + 4 escenarios | Las preguntas de los seis labs mezcladas, con cronómetro, y cuatro escenarios |
| `07` | [Respuestas](07-respuestas.md) | 118 | Las respuestas de las preguntas y de la simulación, con el enunciado literal y en tres capas |

**90 preguntas** en los seis labs y **28 más** en la simulación, todas con respuesta en
[`07`](07-respuestas.md). Cada lab lleva además **seis ejercicios** graduados 🟢🟡🟠🔴 y uno 🔥
fuera de conteo; los ejercicios no tienen solucionario, porque se comprueban corriéndolos.

> **📝 Longitud y entorno.** Los seis labs quedan entre 419 y 550 líneas; `l00` y `l01` están
> declarados densos. El `compose` principal y el de los otros modelos viven en
> [`entorno/`](entorno/), con las versiones fijadas en §4 del documento de dominio. El teardown de
> cada recurso se escribe junto a él, no al final de la serie.

---

## 🧩 Qué asume leído

`l00` asume instalados Docker y los clientes `psql`, `mysql` y `sqlite3`; todos los demás, el
entorno que levanta `l00`. De lectura, cada lab dice lo suyo en su encabezado: `l01`
[`03/05`](../03-el-motor-por-dentro/05-explain-y-explain-analyze.md), para leer un plan; `l02`
[`04/02`](../04-transacciones-y-concurrencia/02-aislamiento-y-sus-fenomenos.md) y
[`04/04`](../04-transacciones-y-concurrencia/04-bloqueos-e-interbloqueos.md); y `l04`
[`10/07`](../10-interfaz-con-los-lenguajes/07-clientes-de-redis-y-mongodb.md), los clientes de los
dos motores. `l03` y `l05` no piden lectura previa: se entienden solos y los capítulos que los usan
—[`06/02`](../06-operacion/02-respaldos-y-recuperacion.md) y el bloque
[`09`](../09-otros-modelos/README.md)— van después.

---

## 🔑 Dueños de concepto de este bloque

| Concepto | Dueño |
|---|---|
| Levantar el entorno, cargar la tienda y verificarla | `l00` |
| La restauración cronometrada y el PITR de práctica | `l03` |

El resto de los conceptos que se practican aquí son de su capítulo teórico; el lab los corre y
enlaza. El esquema, los volúmenes y las versiones son de
[`../prompts/dominio-entorno-y-datos-fijos.md`](../prompts/dominio-entorno-y-datos-fijos.md).

---

## 🧭 Si el calendario aprieta

**`l00` y `l02`.** Sin `l00` no se corre nada del corpus; y `l02` es el que más enseña en menos
tiempo, porque provocar un interbloqueo con dos terminales fija el bloque 04 mejor que releerlo.

---

**Anterior:** [`12`](../12-diseno/README.md) · **Volver:** [README del corpus](../README.md).
