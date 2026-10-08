# Bloque 08 — No relacional: documental

> Qué es un documento, qué resuelve mejor que tres tablas unidas por un `JOIN` y qué deja de
> garantizar, con MongoDB como motor y `jsonb` de PostgreSQL como tercera vía. Al terminarlo sabes
> decidir qué va dentro de un documento y qué va en otro, y defender cuándo un dato con forma de
> documento no necesita una base documental.
> **Vigencia:** 27 de septiembre de 2026.

---

## 📖 Orden de lectura

En orden: `03` usa la agregación de `02`, y `05` es la decisión con la que cierra el bloque.

| # | Documento | Preguntas | Qué cubre |
|---|---|---|---|
| `01` | [El modelo documental](01-el-modelo-documental.md) | 17 | El mismo pedido como documento de 379 bytes y como tres tablas; el total en texto que MongoDB acepta y la suma ignora; la ficha del modelo |
| `02` | [MongoDB: consulta y agregación](02-mongodb-consulta-y-agregacion.md) | 17 | Consulta con operadores, escritura dentro de listas, y el *pipeline* etapa a etapa frente a su `GROUP BY` y su `JOIN` |
| `03` | [Incrustar frente a referenciar](03-incrustar-frente-a-referenciar.md) | 16 | La decisión que define un esquema documental, con los datos reales de la tienda y tres patrones: referencia extendida, *bucket* y *outlier* |
| `04` | [Índices, transacciones y consistencia](04-indices-transacciones-y-consistencia.md) | 18 | Índices multiclave y compuestos, la consulta cubierta; *write concern* y *read concern* en un conjunto de réplicas, y las transacciones que abortan |
| `05` | [Documental, relacional o `jsonb`](05-documental-relacional-o-jsonb.md) | 17 | Validación de esquema en MongoDB, `jsonb` con índice GIN y `CHECK`, relacional puro, y los servicios «compatibles con MongoDB» |
| `06` | [Simulación de entrevista](06-simulacion-de-entrevista.md) | 26 `S#` + 4 escenarios | Las preguntas del bloque mezcladas, con cronómetro, y cuatro escenarios |
| `07` | [Respuestas](07-respuestas.md) | 115 | Todas las respuestas del bloque, con el enunciado literal y en tres capas |

**85 preguntas** en los cinco capítulos y **30 más** en la simulación, todas con respuesta en
[`07`](07-respuestas.md).

> **📝 Longitud y entorno.** Los cinco quedan entre 381 y 483 líneas. MongoDB corre en la versión
> `8.0.20`, la más reciente de la rama 8.0 que arranca en el núcleo de Docker Desktop del entorno;
> el porqué está en §4.1 del documento de dominio. El conjunto de réplicas de `04` es desechable y
> se levanta en ese capítulo.

---

## 🧩 Qué asume leído

[`10/07`](../10-interfaz-con-los-lenguajes/07-clientes-de-redis-y-mongodb.md), el cliente de
MongoDB en los cuatro lenguajes, y el laboratorio [`l04`](../13-laboratorio/l04-redis-y-mongodb.md),
donde la colección de pedidos se carga desde PostgreSQL. Para `05`, los índices GIN de
[`03/02`](../03-el-motor-por-dentro/02-familias-de-indices.md).

---

## 🔑 Dueños de concepto de este bloque

| Concepto | Dueño |
|---|---|
| El modelo documental y su ficha | `08/01` |
| Consulta y *pipeline* de agregación de MongoDB | `08/02` |
| Incrustar o referenciar, y sus patrones | `08/03` |
| Índices, *write concern*, *read concern* y transacciones en MongoDB | `08/04` |
| Documental, relacional o `jsonb` | `08/05` |

---

## 🧭 Si el calendario aprieta

**`03` y `05`.** «¿Lo incrustarías o lo referenciarías?» es la pregunta de MongoDB por excelencia, y
`05` contesta la que llega después en una entrevista de arquitectura: «¿y por qué no `jsonb` en el
PostgreSQL que ya tienes?».

---

**Anterior:** [`07`](../07-clave-valor/README.md) · **Siguiente bloque:** [`09 — Otros
modelos`](../09-otros-modelos/README.md) · **Volver:** [README del corpus](../README.md).
