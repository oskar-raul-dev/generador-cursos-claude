# 02 — MongoDB: consulta y agregación

> Cómo se pregunta y cómo se escribe en MongoDB, con las dos cosas que más sorprenden a quien viene
> de SQL: una condición sobre una lista que cuenta 1 028 pedidos donde hay 599, y un *pipeline* de
> agregación que da exactamente el mismo resultado que su `GROUP BY`, tres veces más despacio, y el
> mismo con `$lookup`, diecisiete veces más despacio. Lectura con operadores y proyección, escritura
> dentro de una lista, y el *pipeline* etapa a etapa. **Asume leído:**
> [`01`](01-el-modelo-documental.md), el documento, y
> [`l04`](../13-laboratorio/l04-redis-y-mongodb.md) §5–§6, donde `explain` y el `$group` por estado
> ya se compararon con PostgreSQL. **Vigencia:** 27 de septiembre de 2026.

---

## Salto rápido

- [1. El problema](#1--el-problema) · [2. Leer: filtros, operadores y
  proyección](#2--leer-filtros-operadores-y-proyección)
- [3. La trampa de las listas](#3--la-trampa-de-las-listas) · [4. Escribir dentro del
  documento](#4--escribir-dentro-del-documento)
- [5. El pipeline de agregación](#5--el-pipeline-de-agregación) · [6. $lookup, el JOIN que no es un
  JOIN](#6--lookup-el-join-que-no-es-un-join)
- [7. Estándar, motor y convención](#7--estándar-motor-y-convención) · [Errores
  frecuentes](#️-errores-frecuentes) · [Preguntas](#-preguntas)

---

## 1. 🎯 El problema

Un equipo mueve a MongoDB los informes de la tienda. El primero pide los pedidos que llevan
`PRD-00017` con al menos cinco unidades, y la consulta que escriben —la que saldría de traducir el
`WHERE` palabra por palabra— devuelve **1 028**. PostgreSQL, sobre los mismos pedidos, dice **599**.
Ninguno de los dos da error.

El segundo informe, los productos más vendidos, sale igual en los dos motores, céntimo a céntimo.
Pero tarda 214 ms en MongoDB y 81 en PostgreSQL, y el tercero, que une los pedidos con los países de
sus clientes, 472 frente a 28.

El lenguaje de consulta de MongoDB es completo y el *pipeline* de agregación responde casi cualquier
pregunta. Este capítulo enseña las dos cosas y, con ellas, **dónde se equivoca quien lo lee como si
fuera SQL** y **cuánto cuesta preguntar lo que el documento no tiene dentro**.

> **📝 Contexto.** Todo está corrido contra `bd-lab-mongo`, `mongo:8.0.20`, con las colecciones de
> `01` —99 999 pedidos, 50 000 clientes, 5 000 productos—, y las mismas consultas en PostgreSQL
> acotadas a los mismos pedidos con `id <= 99999`. Los tiempos de MongoDB los mide `mongosh` con
> `Date.now()` alrededor de la orden; los de PostgreSQL, `\timing`. Cada medida se repitió tres
> veces y se dice el rango. `PED-00042` se cambió en §4 y se devolvió a su estado. **Longitud:**
> unas 400 líneas; capítulo normal.

---

## 2. 🧱 Leer: filtros, operadores y proyección

**Qué es:** `find` recibe un **filtro**, que es un documento con las condiciones, y opcionalmente
una **proyección**, que dice qué campos devolver. Las condiciones usan **operadores** que empiezan
por `$`: `$in`, `$gte`, `$type`… Varias condiciones en el mismo filtro se combinan con «y».

```text
tienda> db.pedidos.countDocuments({estado: {$in: ["PAGADO", "ENVIADO"]}, total: {$gte: Decimal128("5000")}})
24901
tienda> db.pedidos.find({cliente: "CLI-00311"}, {estado: 1, total: 1, creado_en: 1}).sort({creado_en: -1}).limit(3)
[
  {
    _id: 'PED-62576',
    estado: 'ENTREGADO',
    total: Decimal128('2848.28'),
    creado_en: ISODate('2025-06-07T09:15:32.360Z')
  },
  {
    _id: 'PED-01719',
    estado: 'ENTREGADO',
    total: Decimal128('9948.26'),
    creado_en: ISODate('2025-05-04T05:19:36.271Z')
  },
  {
    _id: 'PED-09054',
    estado: 'ENTREGADO',
    total: Decimal128('4958.95'),
    creado_en: ISODate('2024-11-12T13:44:16.017Z')
  }
]
```

- **24 901 pedidos pagados o enviados de 5 000 o más**, el mismo número que da PostgreSQL con el
  `IN` y el `>=` equivalentes. `Decimal128("5000")` compara como número exacto, porque el total se
  cargó como `Decimal128`; comparado con un texto, no encontraría nada.
- **La proyección `{estado: 1, total: 1, creado_en: 1}`** es el `SELECT estado, total, creado_en`.
  El `_id` sale siempre, salvo que se pida `_id: 0`. `sort` y `limit` son el `ORDER BY` y el
  `LIMIT`.
- **`cliente` no tiene índice**, así que las dos consultas recorren la colección entera: es el
  `COLLSCAN` de [`l04`](../13-laboratorio/l04-redis-y-mongodb.md) §5, que se arregla igual que allí.

**Quién lo manda:** **motor**: el lenguaje de consulta es de MongoDB. **Cuánto:** lo mismo que en
SQL: sin índice, se lee todo. **Cuándo sí:** consultas sobre campos del propio documento. **Cuándo
no:** condiciones sobre varios elementos de una lista sin pensar en cómo se combinan, que es la
sección siguiente.

> **Veredicto:** el filtro de `find` es un `WHERE` escrito como documento; mientras las condiciones
> sean sobre campos simples, se traduce palabra por palabra.

---

## 3. 🩺 La trampa de las listas

La consulta del §1, escrita de las dos formas, y la misma pregunta en PostgreSQL:

```text
tienda> db.pedidos.countDocuments({"lineas.producto": "PRD-00017", "lineas.cantidad": {$gte: 5}})
1028
tienda> db.pedidos.countDocuments({lineas: {$elemMatch: {producto: "PRD-00017", cantidad: {$gte: 5}}}})
599
```

```text
tienda=# SELECT count(DISTINCT l.pedido_id) FROM pedido_lineas l JOIN productos pr ON pr.id = l.producto_id WHERE l.pedido_id <= 99999 AND pr.codigo = 'PRD-00017' AND l.cantidad >= 5;
 count
-------
   599
(1 fila)
```

- **Sin `$elemMatch`, cada condición se cumple con cualquier elemento de la lista, por separado**.
  Un pedido con una línea de `PRD-00017` de una unidad y otra línea de otro producto con seis
  cuenta, porque «alguna línea es de `PRD-00017`» y «alguna línea tiene cinco o más» son verdad,
  cada una con una línea distinta. Sobran 429 pedidos.
- **`$elemMatch` exige que un mismo elemento cumpla todas las condiciones**, que es lo que dice su
  documentación y lo que hace el `JOIN` de PostgreSQL con la fila de `pedido_lineas`: 599 en los
  dos.
- **La notación con punto**, `"lineas.producto"`, entra en los subdocumentos de la lista. Con una
  sola condición no hay trampa; con dos sobre la misma lista, sí.

**Quién lo manda:** **motor**. **Cuánto:** en **riesgo**: un informe que da de más sin ningún error.
**Cuándo sí:** `$elemMatch` siempre que haya dos o más condiciones sobre los elementos de una misma
lista. **Cuándo no:** con una sola condición, donde la notación con punto basta.

> **Veredicto:** dos condiciones sobre una lista, sin `$elemMatch`, pueden cumplirse en elementos
> distintos; es el error más caro de traducir un `WHERE` a MongoDB.

---

## 4. 🧱 Escribir dentro del documento

**Qué es:** `updateOne` cambia **un documento** con operadores de actualización —`$set`, `$inc`,
`$push`…—, y lo hace de forma **atómica**: nadie ve el documento a medias. Para tocar un elemento
concreto de una lista hay dos formas, y aquí van las dos, subiendo y bajando una unidad de
`PRD-00872` en `PED-00042`:

```text
tienda> db.pedidos.updateOne({_id: "PED-00042"}, {$inc: {"lineas.$[l].cantidad": 1}}, {arrayFilters: [{"l.producto": "PRD-00872"}]})
{
  acknowledged: true,
  insertedId: null,
  matchedCount: 1,
  modifiedCount: 1,
  upsertedCount: 0
}
tienda> db.pedidos.findOne({_id: "PED-00042"}, {total: 1, "lineas.producto": 1, "lineas.cantidad": 1})
{
  _id: 'PED-00042',
  total: Decimal128('3186.23'),
  lineas: [
    { producto: 'PRD-01395', cantidad: 1 },
    { producto: 'PRD-00872', cantidad: 6 },
    { producto: 'PRD-03623', cantidad: 3 }
  ]
}
tienda> db.pedidos.updateOne({_id: "PED-00042", "lineas.producto": "PRD-00872"}, {$inc: {"lineas.$.cantidad": -1}})
{
  acknowledged: true,
  insertedId: null,
  matchedCount: 1,
  modifiedCount: 1,
  upsertedCount: 0
}
tienda> db.pedidos.findOne({_id: "PED-00042"}, {"lineas.producto": 1, "lineas.cantidad": 1})
{
  _id: 'PED-00042',
  lineas: [
    { producto: 'PRD-01395', cantidad: 1 },
    { producto: 'PRD-00872', cantidad: 5 },
    { producto: 'PRD-03623', cantidad: 3 }
  ]
}
```

- **`$[l]` con `arrayFilters`** cambia los elementos que cumplan el filtro con nombre `l`: todas las
  líneas de `PRD-00872`, si hubiera varias. **`$`, el operador posicional**, cambia el primer
  elemento que encajó en el filtro de la consulta.
- **El total no cambió**: sigue en 3186.23 con una unidad más. El documento no sabe que `total` se
  calcula con las líneas; mantenerlo es trabajo del mismo `updateOne`, con un segundo `$inc` sobre
  `total`. Es el mismo problema que la columna desnormalizada `pedidos.total` de PostgreSQL, con una
  diferencia: allí el cambio de línea y el del total van en la misma transacción aunque sean dos
  tablas; aquí van en la misma orden porque son el mismo documento.
- La segunda orden devolvió la cantidad a 5: `PED-00042` quedó como estaba.

**Quién lo manda:** **motor**. La atomicidad es **por documento**; entre varios documentos hace
falta una transacción, que es de `04`. **Cuánto:** reescribir un documento cuesta en proporción a
su tamaño, y un documento grande que se cambia a menudo es caro. **Cuándo sí:** cambios del
agregado entero en una operación. **Cuándo no:** cuando el cambio toca a la vez varios documentos
que tienen que cuadrar entre sí.

> **Veredicto:** una actualización sobre un documento es atómica y puede tocar cualquier parte de
> él; lo que no hace es recalcular por ti los campos que dependen de otros.

---

## 5. 🧱 El pipeline de agregación

**Qué es:** una lista de **etapas** que los documentos atraviesan en orden, cada una transformando
lo que le llega: `$match` filtra, `$unwind` despliega una lista en un documento por elemento,
`$group` agrupa, `$sort` y `$limit` ordenan y cortan. `l04` §6 ya comparó un `$group` por estado con
su `GROUP BY`; este cruza al terreno donde el documento no ayuda: **las líneas de todos los
pedidos**.

```text
tienda> let t = Date.now(); db.pedidos.aggregate([{$unwind: "$lineas"}, {$group: {_id: "$lineas.producto", unidades: {$sum: "$lineas.cantidad"}}}, {$sort: {unidades: -1}}, {$limit: 5}]).toArray().concat([{ms: Date.now() - t}])
[
  { _id: 'PRD-00017', unidades: 16050 },
  { _id: 'PRD-00025', unidades: 4609 },
  { _id: 'PRD-00027', unidades: 4596 },
  { _id: 'PRD-00015', unidades: 4581 },
  { _id: 'PRD-00047', unidades: 4574 },
  { ms: 214 }
]
```

```text
tienda=# SELECT pr.codigo, sum(l.cantidad) AS unidades FROM pedido_lineas l JOIN productos pr ON pr.id = l.producto_id WHERE l.pedido_id <= 99999 GROUP BY pr.codigo ORDER BY unidades DESC LIMIT 5;
  codigo   | unidades
-----------+----------
 PRD-00017 |    16050
 PRD-00025 |     4609
 PRD-00027 |     4596
 PRD-00015 |     4581
 PRD-00047 |     4574
(5 filas)

Duración: 81,403 ms
```

- **El mismo resultado, unidad a unidad.** `PRD-00017` es el más vendido también en los primeros
  cien mil pedidos.
- **`$unwind` multiplica los documentos**: de 99 999 pedidos salen 349 999, uno por línea —las
  mismas filas que tiene `pedido_lineas` para esos pedidos—, y sobre ellos trabaja `$group`. Es el
  precio de tener las líneas dentro del pedido: para contarlas por producto, hay que sacarlas
  primero.
- **214 ms en MongoDB y 81 en PostgreSQL**; en tres corridas, de 212 a 272 frente a 80 y 81.
  PostgreSQL lee `pedido_lineas`, que ya es una fila por línea; MongoDB tiene que abrir cada pedido
  y desplegarlo.

**Quién lo manda:** **motor**. **Cuánto:** en **tiempo** y en **memoria**: según la documentación,
cada etapa tiene un límite de 100 MB, y desde la 6.0 escribe a disco lo que lo pase si
`allowDiskUseByDefault` está activo. **Cuándo sí:** agregaciones sobre los campos del documento, o
sobre sus listas cuando el volumen es moderado. **Cuándo no:** informes pesados que cruzan las
partes de todos los documentos, que en un sistema de informes o en SQL salen más baratos.

> **Veredicto:** el *pipeline* responde lo mismo que el `GROUP BY`; cuando la pregunta es sobre lo
> que está dentro de los documentos, paga por desplegarlos.

---

## 6. 🧱 $lookup, el JOIN que no es un JOIN

**Qué es:** `$lookup` trae, para cada documento que le llega, los documentos de otra colección cuyo
campo coincide con uno suyo: una igualdad entre `localField` y `foreignField`, dice la
documentación. Las ventas de los pedidos pagados por país del cliente:

```text
tienda> t = Date.now(); db.pedidos.aggregate([{$match: {estado: "PAGADO"}}, {$lookup: {from: "clientes", localField: "cliente", foreignField: "_id", as: "c"}}, {$unwind: "$c"}, {$group: {_id: "$c.pais", pedidos: {$sum: 1}, importe: {$sum: "$total"}}}, {$sort: {importe: -1}}, {$limit: 3}]).toArray().concat([{ms: Date.now() - t}])
[
  { _id: 'CL', pedidos: 3693, importe: Decimal128('18744475.38') },
  { _id: 'CO', pedidos: 3560, importe: Decimal128('18589979.24') },
  { _id: 'AR', pedidos: 3602, importe: Decimal128('18476971.08') },
  { ms: 472 }
]
```

```text
tienda=# SELECT c.pais, count(*) AS pedidos, sum(p.total) AS importe FROM pedidos p JOIN clientes c ON c.id = p.cliente_id WHERE p.id <= 99999 AND p.estado = 'PAGADO' GROUP BY c.pais ORDER BY importe DESC LIMIT 3;
 pais | pedidos |   importe
------+---------+-------------
 CL   |    3693 | 18744475.38
 CO   |    3560 | 18589979.24
 AR   |    3602 | 18476971.08
(3 filas)

Duración: 28,466 ms
```

- **Iguales al céntimo**, gracias a `Decimal128`.
- **472 ms frente a 28**; en tres corridas, de 459 a 498 frente a 27. Para cada uno de los 24 910
  pedidos pagados, `$lookup` busca su cliente por `_id`: una búsqueda por índice por documento. El
  planificador de PostgreSQL, con las dos tablas enteras delante, elige un *hash join*, que lee cada
  tabla una vez.
- **El `_id` de `clientes` está indexado por defecto**; si `foreignField` fuera un campo sin índice,
  cada uno de esos 24 910 documentos recorrería la colección de clientes entera.

**Quién lo manda:** **motor**. **Cuánto:** una búsqueda en la otra colección por cada documento que
llega a la etapa, y memoria para lo que traiga. **Cuándo sí:** uniones ocasionales, sobre pocos
documentos y con `foreignField` indexado. **Cuándo no:** como forma habitual de leer: si dos
colecciones se unen en cada petición, el modelo pedía otra cosa, y `03` dice qué.

> **Veredicto:** `$lookup` existe y funciona, pero es un bucle de búsquedas y no un *join*
> planificado; si lo necesitas en cada lectura, el documento está mal cortado.

---

## 7. 📜 Estándar, motor y convención

> **📜 Estándar o motor.** El lenguaje de consulta y el *pipeline* son de MongoDB; ISO/IEC 9075 no
> aplica. La tabla dice qué pieza de SQL hace el mismo trabajo.

| Afirmación | Estándar | PostgreSQL 18 | MongoDB 8.0 |
|---|---|---|---|
| Dos condiciones sobre una parte se cumplen en la misma parte | Sí, sobre la misma fila | Sí: 599 | Solo con `$elemMatch`; sin él, 1 028 |
| Cambiar una parte y el total es atómico | Sí, la transacción | Sí, aunque sean dos tablas | Sí, si están en el mismo documento |
| Un valor derivado se mantiene solo | — | No: `pedidos.total` se mantiene a mano | No: el total no cambió al cambiar la línea |
| Contar las partes de todas las entidades es barato | — | Sí: 81 ms sobre `pedido_lineas` | Hay que desplegarlas: 214 ms con `$unwind` |
| Unir dos colecciones o tablas | `JOIN` | *Hash join*: 28 ms | `$lookup`, una búsqueda por documento: 472 ms |
| Una agregación grande puede usar disco | — | Sí, con `work_mem` como límite | Sí, pasados 100 MB por etapa |

**Convención, la que más se repite.** *«En MongoDB no hay joins»* — hay `$lookup`, y funciona; lo
que no hay es un planificador que elija cómo unir, así que cada unión es un bucle de búsquedas. La
convención útil es otra: **si unes en cada lectura, corta el documento de otra forma**.

---

## ⚠️ Errores frecuentes

| Se dice | Lo preciso |
|---|---|
| "Dos condiciones sobre `lineas` filtran las líneas que cumplen las dos" | Sin `$elemMatch`, cada una puede cumplirse en una línea distinta: 1 028 frente a 599 |
| "Al cambiar la línea, el total se actualiza" | El documento no recalcula nada; el total hay que cambiarlo en la misma orden |
| "`$lookup` es un `JOIN` como el de SQL" | Es una búsqueda por cada documento que llega: 472 ms frente a los 28 del *hash join* |
| "El *pipeline* es más rápido porque no hay tablas" | Con las líneas dentro de los pedidos, contar por producto obligó a desplegarlas: 214 frente a 81 ms |
| "El `_id` no sale si no lo pido" | Sale siempre, salvo `_id: 0` en la proyección |
| "`$` y `$[]` son lo mismo" | `$` toca el primer elemento que encajó en la consulta; `$[l]` con `arrayFilters`, todos los que cumplan el filtro |
| "La atomicidad de MongoDB cubre cualquier operación" | Cubre un documento; varios necesitan una transacción |

---

## 📚 Para profundizar

- **Documentación** — MongoDB 8.0, «$elemMatch (query predicate operator)»: un mismo elemento, todas
  las condiciones. <https://www.mongodb.com/docs/v8.0/reference/operator/query/elemmatch/>
- **Documentación** — MongoDB 8.0, «$[<identifier>]»: el operador posicional con filtro.
  <https://www.mongodb.com/docs/v8.0/reference/operator/update/positional-filtered/>
- **Documentación** — MongoDB 8.0, «Aggregation Pipeline».
  <https://www.mongodb.com/docs/v8.0/core/aggregation-pipeline/>
- **Documentación** — MongoDB 8.0, «$unwind (aggregation stage)».
  <https://www.mongodb.com/docs/v8.0/reference/operator/aggregation/unwind/>
- **Documentación** — MongoDB 8.0, «$lookup (aggregation stage)»: la igualdad entre campos.
  <https://www.mongodb.com/docs/v8.0/reference/operator/aggregation/lookup/>
- **Documentación** — MongoDB 8.0, «Aggregation Pipeline Limits»: los 100 MB por etapa.
  <https://www.mongodb.com/docs/v8.0/core/aggregation-pipeline-limits/>

---

## 🧠 Preguntas

1. ¿Qué son el filtro y la proyección de `find`, y a qué partes de un `SELECT` equivalen? 🟢
2. ¿Qué hace `$unwind`? 🟢
3. ¿Qué hace `$elemMatch`? 🟢
4. ¿Cuándo sale el `_id` en el resultado de una consulta? 🟢
5. Distingue el operador posicional `$` del filtrado `$[l]` con `arrayFilters`. ¿Lo fija el estándar
   o es cosa del motor? 🟡
6. Distingue la atomicidad de un `updateOne` en MongoDB de la de una transacción en PostgreSQL. 🟡
7. Distingue `$lookup` de un `JOIN` de PostgreSQL: cómo se ejecuta cada uno. 🟡
8. ¿El lenguaje de consulta de MongoDB sigue algún estándar como ISO/IEC 9075? ¿Y el límite de 100
   MB por etapa, lo fija alguna norma? 🟡
9. ¿Por qué `{"lineas.producto": "PRD-00017", "lineas.cantidad": {$gte: 5}}` contó 1 028 pedidos y
   no 599? 🟠
10. ¿Por qué el total de `PED-00042` no cambió al subir la cantidad de una línea, y cómo lo harías
    en la misma operación? 🟠
11. ¿Por qué el top de productos tardó 214 ms en MongoDB y 81 en PostgreSQL con el mismo resultado?
    🟠
12. ¿Por qué el `$lookup` a clientes tardó 472 ms y el `JOIN` 28? ¿Qué pasaría si `foreignField` no
    tuviera índice? 🟠
13. ¿Por qué comparar `total` con `Decimal128("5000")` funciona y con `"5000"` no encontraría nada?
    🟠
14. Escribe el *pipeline* que da, para `CLI-00311`, el número de pedidos por estado y el importe de
    cada estado, ordenado por importe. 🔴
15. Escribe la actualización que suma una unidad a la línea de `PRD-00872` de `PED-00042` y suma a
    la vez su precio al total, en una sola orden. 🔴
16. Diagnostica: un informe de MongoDB de «pedidos con PRD-00017 en cantidad de cinco o más» da un
    70 % más que el de PostgreSQL. Da la causa y la corrección, y cómo comprobarías que ya cuadran.
    🔴
17. El panel de ventas por país, escrito con `$lookup`, tarda medio segundo y se pide cien veces por
    minuto. Da tres formas de arreglarlo con lo que cuesta cada una. 🔴

---

**Anterior:** [`01`](01-el-modelo-documental.md) — el modelo documental · **Siguiente:**
[`03`](03-incrustar-frente-a-referenciar.md) — incrustar frente a referenciar · **Relacionado:**
[`l04`](../13-laboratorio/l04-redis-y-mongodb.md) §5 — `explain` y el índice ·
[`03/05`](../03-el-motor-por-dentro/05-explain-y-explain-analyze.md) — el *hash join* y el *nested
loop* de PostgreSQL.
