# Bloque 09 — Otros modelos no SQL

> Por qué «NoSQL» no dice nada útil de un motor, qué dice de verdad el teorema CAP, y los modelos
> que quedan: wide-column, grafo, series temporales, búsqueda de texto y vectorial. Al terminarlo
> sabes decir en qué forma de acceso gana cada uno, cuánto se paga por él, y cuándo lo resuelve
> PostgreSQL con una extensión.
> **Vigencia:** 27 de septiembre de 2026.

---

## 📖 Orden de lectura

`01` primero: da CAP y el criterio de elección que usan los demás. Después, en cualquier orden;
`06` asume leído `05`.

| # | Documento | Preguntas | Qué cubre |
|---|---|---|---|
| `01` | [Más allá de las tablas](01-mas-alla-de-las-tablas.md) | 19 | CAP con dos sesiones opuestas —MongoDB deja de escribir, Cassandra sigue—, la tabla comparada de las siete fichas y el criterio de elección |
| `02` | [Columnar y wide-column](02-columnar-y-wide-column.md) | 17 | Cassandra desde su clave: partición y *clustering*, una tabla por consulta, el `INSERT` que pisa, la transacción ligera y el `DELETE` que escribe |
| `03` | [Grafo](03-grafo.md) | 18 | Neo4j frente a PostgreSQL: la profundidad fija que gana el `JOIN`, la variable que gana el grafo, y el supernodo |
| `04` | [Series temporales](04-series-temporales.md) | 18 | TimescaleDB: hipertabla, compresión, agregados continuos y retención, frente a la tabla normal con índice |
| `05` | [Búsqueda de texto](05-busqueda-de-texto.md) | 18 | `LIKE`, texto completo de PostgreSQL y OpenSearch: tildes, singular y plural, erratas, relevancia y el refresco de un segundo |
| `06` | [Vectorial y embeddings](06-vectorial-y-embeddings.md) | 17 | Embeddings y búsqueda por parecido con pgvector y Qdrant; HNSW aproximado y el filtro que vacía el resultado |
| `07` | [Simulación de entrevista](07-simulacion-de-entrevista.md) | 26 `S#` + 4 escenarios | Las preguntas del bloque mezcladas, con cronómetro, y cuatro escenarios |
| `08` | [Respuestas](08-respuestas.md) | 137 | Todas las respuestas del bloque, con el enunciado literal y en tres capas |

**107 preguntas** en los seis capítulos y **30 más** en la simulación, todas con respuesta en
[`08`](08-respuestas.md).

> **📝 Longitud y entorno.** Los seis quedan entre 414 y 545 líneas; `03`, `04` y `06` están
> declarados densos. Los motores de este bloque viven en un `compose` aparte,
> `docker-compose.otros.yml`, y se levantan solo para estos capítulos y el laboratorio
> [`l05`](../13-laboratorio/l05-los-otros-modelos.md). El modelo de embeddings local no separa
> significados en español: `06` lo publica como lección —la calidad es del modelo, no del motor— y
> mide el índice también con vectores aleatorios.

---

## 🧩 Qué asume leído

[`07/01`](../07-clave-valor/01-el-modelo-clave-valor.md) y
[`08/01`](../08-documental/01-el-modelo-documental.md), las dos primeras fichas de modelo, y
[`07/06`](../07-clave-valor/06-dynamodb-diseno-desde-el-acceso.md), el diseño desde el acceso que
`02` aplica a Cassandra.

---

## 🔑 Dueños de concepto de este bloque

| Concepto | Dueño |
|---|---|
| **CAP, lo justo para elegir motor** | `09/01` — lo usa `12/01` |
| Wide-column: partición, *clustering* y consistencia ajustable | `09/02` |
| Grafo: recorridos y supernodos | `09/03` |
| Series temporales: hipertabla, compresión y retención | `09/04` |
| Búsqueda de texto: analizador, índice invertido y relevancia | `09/05` |
| Embeddings y búsqueda vectorial aproximada | `09/06` |

---

## 🧭 Si el calendario aprieta

**`01` y `05`.** CAP y el criterio de elección aparecen en cualquier entrevista de arquitectura de
datos, y `01` los da con dos sesiones en vez de con un triángulo. La búsqueda de texto es el caso
más frecuente en que alguien propone un motor aparte, y `05` dice con números cuándo hace falta.

---

**Anterior:** [`08`](../08-documental/README.md) · **Siguiente bloque:**
[`10 — Interfaz con los lenguajes`](../10-interfaz-con-los-lenguajes/README.md) · **Volver:**
[README del corpus](../README.md).
