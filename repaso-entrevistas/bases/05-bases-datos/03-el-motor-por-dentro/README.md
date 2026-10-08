# Bloque 03 — El motor por dentro: índices y planes

> Dónde vive de verdad una fila, qué estructura acelera qué consulta y cuál no, por qué el orden de
> las columnas de un índice compuesto decide si se usa, cómo se lee un plan de arriba abajo, y las
> seis razones por las que tu índice no se usa aunque exista. Al terminarlo sabes diagnosticar una
> consulta lenta con `EXPLAIN ANALYZE` y proponer el índice, o decir por qué no hace falta.
> **Vigencia:** 27 de septiembre de 2026.

---

## 📖 Orden de lectura

Estrictamente acumulativo: `05` no se entiende sin `04`, y `06` es la síntesis de los cinco
anteriores.

| # | Documento | Preguntas | Qué cubre |
|---|---|---|---|
| `01` | [Cómo se almacena una tabla](01-como-se-almacena-una-tabla.md) | 17 | Páginas, filas, heap, valores grandes fuera de línea (TOAST), el índice agrupado de InnoDB frente al heap de PostgreSQL |
| `02` | [Familias de índices](02-familias-de-indices.md) | 15 | B-tree, hash, GIN, GiST y BRIN: para qué sirve cada uno y qué consulta acelera |
| `03` | [Compuestos, parciales y de cobertura](03-compuestos-parciales-y-de-cobertura.md) | 16 | Por qué el orden de las columnas decide si se usa; índices parciales, funcionales e *index-only scan* |
| `04` | [Estadísticas y el planificador](04-estadisticas-y-el-planificador.md) | 19 | Selectividad, cardinalidad, histogramas, `ANALYZE`, y por qué el planificador se equivoca |
| `05` | [`EXPLAIN` y `EXPLAIN ANALYZE`](05-explain-y-explain-analyze.md) | 22 | Cómo se lee un plan, coste estimado frente a real, y los nodos que hay que reconocer |
| `06` | [Cuándo el índice no se usa](06-cuando-el-indice-no-se-usa.md) | 20 | Las seis razones; lo que cuesta un índice en escritura, en registros de WAL; particionado |
| `07` | [Simulación de entrevista](07-simulacion-de-entrevista.md) | 24 `S#` + 4 escenarios | Las preguntas del bloque mezcladas, con cronómetro, y cuatro escenarios |
| `08` | [Respuestas](08-respuestas.md) | 137 | Todas las respuestas del bloque, con el enunciado literal y en tres capas |

**109 preguntas** en los seis capítulos y **28 más** en la simulación, todas con respuesta en
[`08`](08-respuestas.md).

> **📝 Longitud y evidencia.** Es el bloque más denso del corpus: los seis capítulos están **en el
> techo de 550 líneas**, porque cada uno demuestra el comportamiento del motor con planes pegados
> enteros. `05` es el único que dejó fuera tres planes completos para caber, conservando sus
> números en prosa y diciéndolo; `06` reutiliza las mediciones de `01`–`05` y remite a
> [`l01`](../13-laboratorio/l01-explain-e-indices-medidos.md) los tres casos que no tienen plan
> pegado. **Los planes del bloque se volvieron a correr el 27 de septiembre de 2026** y coinciden en
> forma y filas reales con los pegados; las estimaciones cambian con cada muestra de `ANALYZE`, como
> explica §4.3.1 del documento de dominio.

---

## 🧩 Qué asume leído

Los bloques [`01`](../01-fundamentos-y-modelo-relacional/README.md) y
[`02`](../02-sql/README.md). Aquí se escriben consultas sin volver a explicarlas: lo que se explica
es **qué hace el motor con ellas**.

---

## 🔑 Dueños de concepto de este bloque

| Concepto | Dueño |
|---|---|
| Página, fila, heap y almacenamiento fuera de línea | `03/01` |
| Qué familia de índice sirve para qué | `03/02` |
| Orden de columnas, índice parcial y de cobertura | `03/03` |
| Estadísticas, selectividad y por qué el planificador se equivoca | `03/04` |
| **Lectura de `EXPLAIN` y `EXPLAIN ANALYZE`** | `03/05` — lo usa todo el corpus |
| Las seis razones por las que un índice no se usa | `03/06` |

---

## ⚠️ La regla de escritura de este bloque

El esquema llega con once índices, los que crean `PRIMARY KEY` y `UNIQUE`, y ninguno más. Por eso:

> **Todo índice que un capítulo cree, lo crea dentro de `BEGIN … ROLLBACK`.** PostgreSQL tiene DDL
> transaccional, así que un `CREATE INDEX` no concurrente desaparece al deshacer. Un capítulo que
> deje un índice detrás cambia los planes de todos los demás capítulos del corpus.

La comprobación, al cerrar cualquier edición de este bloque:

```bash
PGPASSWORD=postgres psql -h 127.0.0.1 -U postgres -d tienda -tAc \
  "SELECT count(*) FROM pg_indexes WHERE schemaname='public';"   # tiene que dar 11
```

- **`-tAc`** junta tres opciones de `psql`: `-t` quita cabecera y pie, `-A` quita la alineación y
  `-c` ejecuta la consulta y sale. La salida es el número solo.
- **`pg_indexes`** es la vista del catálogo con un índice por fila; `schemaname='public'` deja fuera
  los del sistema.

---

## 🧭 Si el calendario aprieta

**`05` y `06`.** Leer un plan y explicar por qué un índice no se usa son las dos preguntas de
rendimiento que llegan en casi cualquier entrevista de backend, y `06` las responde en el orden en
que conviene descartarlas. `03` es el siguiente: el orden de las columnas de un compuesto es la
repregunta habitual.

---

**Anterior:** [`02`](../02-sql/README.md) · **Siguiente bloque:** [`04 — Transacciones y
concurrencia`](../04-transacciones-y-concurrencia/README.md) · **Volver:** [README del
corpus](../README.md).
