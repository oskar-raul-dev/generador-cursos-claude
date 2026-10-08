# Bloque 07 — No relacional: clave-valor

> Qué es un almacén clave-valor, qué resuelve mejor que una tabla y qué deja de poder hacer, con
> Redis en memoria y DynamoDB en disco. Al terminarlo sabes explicar dónde falla de verdad SQL
> frente a Redis —no en la lectura por clave, sino en el contador caliente—, montar una caché sin
> carreras, y diseñar una tabla de DynamoDB desde sus patrones de acceso.
> **Vigencia:** 27 de septiembre de 2026.

---

## 📖 Orden de lectura

`01` a `04` son Redis, en orden; `05` y `06` son DynamoDB, y `06` es el método que reutiliza
[`09/02`](../09-otros-modelos/02-columnar-y-wide-column.md) con Cassandra.

| # | Documento | Preguntas | Qué cubre |
|---|---|---|---|
| `01` | [El modelo clave-valor](01-el-modelo-clave-valor.md) | 17 | Qué resuelve y qué pierde, contra PostgreSQL: la lectura por clave que empata y el contador caliente, 4 373 escrituras por segundo frente a 121 080; la ficha del modelo |
| `02` | [Redis: estructuras y caducidad](02-redis-estructuras-y-ttl.md) | 18 | Las seis estructuras, cada una con su trabajo en la tienda; la caducidad que eliges y el desalojo que elige el servidor |
| `03` | [Atomicidad, scripts y durabilidad](03-atomicidad-scripts-y-durabilidad.md) | 18 | *Pipeline*, `MULTI`, `WATCH` y Lua, que se parecen y garantizan cosas distintas; RDB y AOF con el proceso matado a mitad de escritura |
| `04` | [Caché, invalidación y estampida](04-cache-invalidacion-y-estampida.md) | 17 | Los cuatro patrones de caché y la carrera de *cache-aside* provocada; la estampida y sus mitigaciones; limitación de tasa y colas |
| `05` | [DynamoDB: el modelo y las claves](05-dynamodb-modelo-y-claves.md) | 18 | Partición y orden, lecturas fuertes y eventuales, el filtro que cobra lo que lee, el `scan` y los índices secundarios, con la capacidad consumida |
| `06` | [DynamoDB: diseño desde el acceso](06-dynamodb-diseno-desde-el-acceso.md) | 18 | Los cinco pasos de una tabla única con tres índices, el diseño de clave que falla contra los datos reales y lo que cuesta una pregunta nueva |
| `07` | [Simulación de entrevista](07-simulacion-de-entrevista.md) | 26 `S#` + 4 escenarios | Las preguntas del bloque mezcladas, con cronómetro, y cuatro escenarios |
| `08` | [Respuestas](08-respuestas.md) | 136 | Todas las respuestas del bloque, con el enunciado literal y en tres capas |

**106 preguntas** en los seis capítulos y **30 más** en la simulación, todas con respuesta en
[`08`](08-respuestas.md).

> **📝 Longitud y entorno.** Los seis quedan entre 432 y 543 líneas; `02` y `06` están declarados
> densos. DynamoDB corre en local con `amazon/dynamodb-local`, que calcula la capacidad consumida
> pero **no reproduce** particiones, límites de capacidad ni consistencia eventual: `05` lo declara
> y explica la partición caliente con las cifras de la documentación de AWS.

---

## 🧩 Qué asume leído

[`10/07`](../10-interfaz-con-los-lenguajes/07-clientes-de-redis-y-mongodb.md), donde los cuatro
lenguajes ya hablan con Redis, y
[`04/04`](../04-transacciones-y-concurrencia/04-bloqueos-e-interbloqueos.md), el bloqueo de fila que
explica el contador caliente.

---

## 🔑 Dueños de concepto de este bloque

| Concepto | Dueño |
|---|---|
| El modelo clave-valor y su ficha | `07/01` |
| Estructuras de Redis, caducidad y desalojo | `07/02` |
| Atomicidad en Redis y persistencia RDB/AOF | `07/03` |
| Patrones de caché, invalidación y estampida | `07/04` |
| DynamoDB: claves, capacidad e índices | `07/05` |
| **Modelado desde el patrón de acceso** | `07/06` — lo reutiliza `09/02` |

---

## 🧭 Si el calendario aprieta

**`04` y `06`.** La caché con su invalidación es la pregunta de Redis que más se hace en una
entrevista de backend, y la carrera de *cache-aside* es la repregunta. Si el puesto pide AWS, `06`
es el diseño desde el acceso que se evalúa en cualquier pizarra de DynamoDB; `05` es su requisito.

---

**Anterior:** [`06`](../06-operacion/README.md) · **Siguiente bloque:**
[`08 — Documental`](../08-documental/README.md) · **Volver:** [README del corpus](../README.md).
