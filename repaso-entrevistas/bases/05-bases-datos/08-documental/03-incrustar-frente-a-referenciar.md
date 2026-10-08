# 03 — Incrustar frente a referenciar

> La decisión que define un esquema documental: qué va dentro de un documento y qué va en otro
> documento con una referencia. Con los datos reales de la tienda —cuántas líneas tiene un pedido,
> cuántos pedidos un cliente, cuántos eventos una hora— y con los tres patrones que resuelven los
> casos difíciles: la **referencia extendida**, que convierte un `$lookup` de 472 ms en un `$group`
> de 38; el ***bucket***, que agrupa 409 998 eventos en 24 002 documentos y reduce el índice a la
> vigésima parte; y el ***outlier***, que esta tienda no necesita, y se dice por qué. Antes, el
> límite de 16 MiB provocado, con el `$push` de un día normal que falla. **Asume leído:**
> [`02`](02-mongodb-consulta-y-agregacion.md), el `$lookup` y el `$unwind`. **Vigencia:** 27 de
> septiembre de 2026.

---

## Salto rápido

- [1. El problema](#1--el-problema) · [2. Incrustar o referenciar](#2--incrustar-o-referenciar)
- [3. El límite de 16 MiB](#3--el-límite-de-16-mib) · [4. La referencia
  extendida](#4--la-referencia-extendida)
- [5. El patrón bucket](#5--el-patrón-bucket) · [6. El patrón outlier](#6--el-patrón-outlier)
- [7. Estándar, motor y convención](#7--estándar-motor-y-convención) · [Errores
  frecuentes](#️-errores-frecuentes) · [Preguntas](#-preguntas)

---

## 1. 🎯 El problema

El primer esquema documental de un equipo que viene de SQL suele caer en uno de dos extremos. O
**una colección por tabla**, con referencias por todas partes, y cada lectura se convierte en un
`$lookup`: el panel de ventas por país de [`02`](02-mongodb-consulta-y-agregacion.md) §6, 472 ms
frente a 28 en PostgreSQL. O **todo dentro de todo**: los pedidos dentro del cliente, los eventos
dentro del pedido, el historial dentro del producto. Esa segunda forma funciona el primer mes, y un
día un `$push` rutinario falla porque el documento ya no cabe.

En relacional la pregunta no existe: la normalización de
[`01/04`](../01-fundamentos-y-modelo-relacional/04-normalizacion-y-desnormalizacion.md) dice dónde
va cada cosa, y el `JOIN` lo reúne al leer. En un documental **hay que decidirlo**, entidad por
entidad, con dos datos en la mano: **cómo se lee** y **cuánto crece**. Este capítulo toma esos dos
datos de la tienda real y los aplica.

> **📝 Contexto.** Todo está corrido contra `bd-lab-mongo`, `mongo:8.0.20`, con las colecciones de
> `01` y los eventos de pedido cargados desde PostgreSQL de dos formas en `tienda.eventos`, una
> detrás de otra. Los tamaños de colección se midieron **tras forzar un *checkpoint*** con
> `db.adminCommand({fsync: 1})`: nada más importar, `storageSize` aún no refleja lo escrito. La
> referencia extendida de §4 dejó el campo `cliente_pais` en los pedidos, que se borra con la
> colección al terminar. **Longitud:** unas 400 líneas; capítulo normal.

---

## 2. 🧭 Incrustar o referenciar

**Qué es cada uno:** **incrustar** es poner la parte dentro del documento de la entidad, como las
líneas dentro del pedido; **referenciar** es guardar la parte en su propia colección y apuntarla por
su `_id`, como el pedido guarda `cliente: "CLI-26446"`. Las preguntas que deciden, con los datos de
la tienda medidos en PostgreSQL:

| Relación | ¿Se lee junta? | ¿Cuánto crece? | ¿Se cambia o consulta sola? | Decisión |
|---|---|---|---|---|
| Pedido → líneas | Siempre, en la ficha | Media 3,5, máximo 6 | No | **Incrustar** |
| Pedido → eventos del pedido | A menudo | Media 4,1, máximo 6 | No | **Incrustar** |
| Cliente → pedidos | Solo los recientes | Media 20, máximo 52, y sigue | Sí: cada pedido vive solo | **Referenciar** |
| Pedido → país del cliente | En los informes por país | Un campo | Rara vez: un cliente se muda poco | **Referencia extendida**, §4 |
| Tienda → todos los eventos | Por hora, en el panel | 409 998 y creciendo | Nunca se cambian | ***Bucket***, §5 |

- **La pregunta del crecimiento es la que más falla**, porque hoy todas las listas son cortas. El
  cliente con más pedidos tiene 52, pero cada compra añade uno y nada lo detiene: es una lista sin
  límite, y la documentación de MongoDB la pone como antipatrón.
- **«Se lee junta» no basta**: el cliente se lee con sus pedidos recientes, no con todos. Lo que se
  incrusta es lo que se lee **siempre** con su padre y tiene un tope natural.

**Quién lo manda:** **convención**, recogida en la guía de modelado de MongoDB; el motor no impide
ninguna de las dos formas. **Cuánto:** incrustar paga en tamaño de documento y en reescribirlo
entero; referenciar paga un `$lookup` o una segunda lectura. **Cuándo sí:** incrustar lo acotado y
leído junto. **Cuándo no:** incrustar lo que crece sin tope o se consulta por su cuenta.

> **Veredicto:** se incrusta lo que se lee siempre con su padre y tiene tope; se referencia lo que
> vive solo o crece sin límite. El tope se mide en los datos, no se supone.

---

## 3. 🩺 El límite de 16 MiB

La documentación fija el tamaño máximo de un documento BSON en **16 mebibytes**: 16 777 216 bytes.
Tres escrituras contra ese límite, en `tienda.eventos`:

```text
tienda> db.eventos.insertOne({_id: "2025-02-21T03", eventos: ["x".repeat(16 * 1024 * 1024)]})
Uncaught MongoServerError: object to insert too large. size in bytes: 16777266, max size: 16777216
tienda> db.eventos.insertOne({_id: "2025-02-21T03", eventos: ["x".repeat(16 * 1024 * 1024 - 100)]})
{ acknowledged: true, insertedId: '2025-02-21T03' }
tienda> db.eventos.updateOne({_id: "2025-02-21T03"}, {$push: {eventos: "x".repeat(200)}})
Uncaught MongoServerError: Resulting document after update is larger than 16777216
tienda> db.eventos.drop()
true
```

- **El primero lo rechaza el servidor** por 50 bytes: la cadena mide exactamente 16 MiB y la
  estructura del documento añade el resto.
- **El segundo entra**, cien bytes por debajo del límite.
- **El tercero es el que ocurre en producción**: un `$push` de 200 bytes, idéntico a los miles
  anteriores, falla porque el documento ya no puede crecer. No hay aviso previo: el día antes
  funcionaba, y el código no cambió.
- Un documento de 17 MiB no llega al servidor: `mongosh` falla al construirlo, con un `RangeError`
  del propio cliente.

**Quién lo manda:** **motor**; la documentación dice que el límite existe para que un solo documento
no use demasiada memoria ni ancho de banda. **Cuánto:** un documento cerca del límite ya es caro de
leer y de reescribir entero mucho antes de fallar. **Cuándo sí:** documentos que se quedan muy lejos
del límite por diseño. **Cuándo no:** cualquier lista que crezca con el tiempo sin un tope.

> **Veredicto:** el límite de 16 MiB no se alcanza de golpe: se alcanza con el `$push` número un
> millón, idéntico a los anteriores; una lista sin tope es un fallo aplazado.

---

## 4. 🧱 La referencia extendida

**Qué es:** guardar en el documento que referencia **una copia de los campos del referenciado que
se leen a menudo**, para no tener que ir a buscarlos. La documentación lo trata como duplicar datos
a propósito: se gana en lectura y se paga en mantener las copias. Aquí, el país del cliente copiado
en cada pedido, y el mismo panel de `02` §6 sin `$lookup`:

```text
tienda> let t = Date.now(); db.pedidos.aggregate([{$lookup: {from: "clientes", localField: "cliente", foreignField: "_id", as: "c"}}, {$set: {cliente_pais: {$first: "$c.pais"}}}, {$unset: "c"}, {$merge: {into: "pedidos", whenMatched: "merge"}}]); Date.now() - t
3530
tienda> db.pedidos.findOne({_id: "PED-00042"}, {cliente: 1, cliente_pais: 1})
{ _id: 'PED-00042', cliente: 'CLI-26446', cliente_pais: 'CL' }
tienda> t = Date.now(); db.pedidos.aggregate([{$match: {estado: "PAGADO"}}, {$group: {_id: "$cliente_pais", pedidos: {$sum: 1}, importe: {$sum: "$total"}}}, {$sort: {importe: -1}}, {$limit: 3}]).toArray().concat([{ms: Date.now() - t}])
[
  { _id: 'CL', pedidos: 3693, importe: Decimal128('18744475.38') },
  { _id: 'CO', pedidos: 3560, importe: Decimal128('18589979.24') },
  { _id: 'AR', pedidos: 3602, importe: Decimal128('18476971.08') },
  { ms: 38 }
]
tienda> db.pedidos.updateMany({cliente: "CLI-00311"}, {$set: {cliente_pais: "PT"}})
{
  acknowledged: true,
  insertedId: null,
  matchedCount: 7,
  modifiedCount: 7,
  upsertedCount: 0
}
tienda> db.pedidos.updateMany({cliente: "CLI-00311"}, {$set: {cliente_pais: "ES"}})
{
  acknowledged: true,
  insertedId: null,
  matchedCount: 7,
  modifiedCount: 7,
  upsertedCount: 0
}
```

- **La copia se hizo una vez**, con el mismo `$lookup` y un `$merge` que escribe el resultado sobre
  la propia colección: 3,5 s para los 99 999 pedidos.
- **El panel, sin `$lookup`, en 38 ms** en vez de 472, con el mismo resultado al céntimo. Es un
  `$group` sobre un campo del documento, como el `GROUP BY` de `l04` §6.
- **El precio llega cuando el cliente cambia**: si `CLI-00311` se muda, hay que actualizar el país
  en sus pedidos —7 en esta colección— además de en `clientes`. Son dos colecciones, y sin una
  transacción, un lector puede ver una cambiada y la otra no. La segunda orden devolvió el país a
  `ES`.

**Quién lo manda:** **convención**, respaldada por la guía de MongoDB. **Cuánto:** espacio por la
copia y una escritura en cada documento que la lleva cuando el original cambia. **Cuándo sí:**
campos que se leen en cada consulta y cambian poco —el país, el nombre—. **Cuándo no:** campos que
cambian a menudo —el saldo, el estado—, donde mantener las copias cuesta más que el `$lookup`.

> **Veredicto:** la referencia extendida copia lo que se lee siempre y cambia poco; convierte un
> `$lookup` en un campo, y cada cambio del original en varias escrituras.

---

## 5. 🧱 El patrón bucket

**Qué es:** agrupar una serie larga de elementos pequeños —lecturas, eventos— en documentos que
contienen muchos, por un criterio natural como la hora. La documentación lo define como separar
series largas en objetos distintos, agrupados alrededor de una entidad central. Los 409 998 eventos
de los primeros cien mil pedidos, primero uno por documento, con un índice por fecha:

```text
tienda> db.eventos.createIndex({ocurrido_en: 1})
ocurrido_en_1
tienda> db.adminCommand({fsync: 1}).ok
1
tienda> [db.eventos.stats().count, db.eventos.stats().storageSize, db.eventos.stats().totalIndexSize]
[ 409998, 10248192, 8986624 ]
tienda> const hora = {ocurrido_en: {$gte: ISODate("2025-02-21T03:00:00Z"), $lt: ISODate("2025-02-21T04:00:00Z")}}

tienda> db.eventos.countDocuments(hora)
18
tienda> db.eventos.find(hora).explain("executionStats").executionStats.totalDocsExamined
18
tienda> db.eventos.drop()
true
```

Y los mismos eventos en cubos de una hora, con la hora como `_id`:

```text
tienda> db.adminCommand({fsync: 1}).ok
1
tienda> [db.eventos.stats().count, db.eventos.stats().storageSize, db.eventos.stats().totalIndexSize]
[ 24002, 8339456, 372736 ]
tienda> db.eventos.findOne({_id: "2025-02-21T03"}, {n: 1, "eventos.pedido": 1, "eventos.tipo": 1})
{
  _id: '2025-02-21T03',
  n: 18,
  eventos: [
    { pedido: 'PED-56837', tipo: 'PREPARADO' },
    { pedido: 'PED-30499', tipo: 'CREADO' },
    { pedido: 'PED-65098', tipo: 'VALIDADO' },
    { pedido: 'PED-95828', tipo: 'ENTREGADO' },
    { pedido: 'PED-46945', tipo: 'ENVIADO' },
    { pedido: 'PED-14857', tipo: 'PAGADO' },
    { pedido: 'PED-25083', tipo: 'ENVIADO' },
    { pedido: 'PED-28142', tipo: 'PREPARADO' },
    { pedido: 'PED-40108', tipo: 'PREPARADO' },
    { pedido: 'PED-89392', tipo: 'ENTREGADO' },
    { pedido: 'PED-56837', tipo: 'ENVIADO' },
    { pedido: 'PED-30499', tipo: 'VALIDADO' },
    { pedido: 'PED-65098', tipo: 'PAGADO' },
    { pedido: 'PED-00042', tipo: 'VALIDADO' },
    { pedido: 'PED-95828', tipo: 'CREADO' },
    { pedido: 'PED-46945', tipo: 'ENTREGADO' },
    { pedido: 'PED-14857', tipo: 'PREPARADO' },
    { pedido: 'PED-25083', tipo: 'ENTREGADO' }
  ]
}
tienda> db.eventos.find({_id: "2025-02-21T03"}).explain("executionStats").executionStats.totalDocsExamined
1
tienda> db.eventos.updateOne({_id: "2025-02-21T03"}, {$push: {eventos: {pedido: "PED-00042", tipo: "REVISADO", ocurrido_en: ISODate("2025-02-21T03:59:00Z")}}, $inc: {n: 1}}, {upsert: true})
{
  acknowledged: true,
  insertedId: null,
  matchedCount: 1,
  modifiedCount: 1,
  upsertedCount: 0
}
tienda> db.eventos.updateOne({_id: "2025-02-21T03"}, {$pull: {eventos: {tipo: "REVISADO"}}, $inc: {n: -1}})
{
  acknowledged: true,
  insertedId: null,
  matchedCount: 1,
  modifiedCount: 1,
  upsertedCount: 0
}
```

- **De 409 998 documentos a 24 002**, y de 8,99 MB de índices a 0,37: sin un documento por evento,
  sobra el índice por fecha, porque la hora ya es el `_id`. En disco, de 10,2 MB a 8,3.
- **La hora se lee de un documento en vez de dieciocho**. El evento `VALIDADO` de `PED-00042` está
  en ese cubo, el decimocuarto.
- **Añadir un evento es un `$push` con `upsert`**: si el cubo de esa hora no existe, lo crea. El
  contador `n` permite partir el cubo si una hora se llena. El evento de prueba se retiró con
  `$pull`.
- Tras ese ciclo de escritura, `storageSize` pasó a 10,5 MB y se quedó ahí; no se comprobó por qué,
  y la comparación de arriba es con las dos colecciones recién cargadas.

**Quién lo manda:** **convención**; la documentación añade que las colecciones de series temporales
de MongoDB aplican este patrón solas, que es materia del bloque 09. **Cuánto:** leer un evento
suelto obliga a traer su cubo entero, y el cubo se reescribe en cada `$push`. **Cuándo sí:** series
largas de elementos pequeños que se leen por tramos. **Cuándo no:** elementos que se consultan uno a
uno por su propio identificador.

> **Veredicto:** el *bucket* cambia muchos documentos pequeños por pocos medianos; se ahorra índice
> y lecturas por tramo, y se paga reescribir el cubo en cada escritura.

---

## 6. 🧱 El patrón outlier

**Qué es:** cuando casi todos los documentos tienen una forma y unos pocos se salen —una lista cien
veces más larga—, se trata a esos pocos aparte, con una marca y documentos de desbordamiento, para
que las consultas comunes no paguen por ellos. La documentación lo define así: aislar los documentos
que no tienen la forma esperada del resto de la colección.

¿Lo necesita la tienda? Si los pedidos de cada cliente se incrustaran en el cliente, el tamaño lo
decidiría la distribución real:

```text
tienda=# SELECT round(avg(n), 1) AS media, percentile_disc(0.5) WITHIN GROUP (ORDER BY n) AS mediana, percentile_disc(0.99) WITHIN GROUP (ORDER BY n) AS p99, max(n) AS maximo FROM (SELECT cliente_id, count(*) AS n FROM pedidos GROUP BY cliente_id) t;
 media | mediana | p99 | maximo
-------+---------+-----+--------
  20.0 |      20 |  31 |     52
(1 fila)
```

- **No hay cola larga**: el cliente más activo, `CLI-00311`, tiene 52 pedidos, dos veces y media la
  mediana. Con la semilla de la tienda, ningún cliente es un *outlier* en el sentido del patrón.
- **El caso real sería un mayorista** con doscientos mil pedidos junto a clientes de veinte: ese
  documento sería miles de veces más grande que el resto. El patrón lo marcaría —`desborde: true`—,
  guardaría en él los pedidos recientes y movería el resto a documentos aparte, y solo las consultas
  sobre ese cliente pagarían la segunda lectura.
- **Y aun sin cola larga, los pedidos no se incrustan en el cliente**, por la otra razón de §2: la
  lista crece con cada compra y cada pedido se consulta solo.

**Quién lo manda:** **convención**. **Cuánto:** lógica de aplicación para dos formas de documento, y
una segunda lectura para los casos aislados. **Cuándo sí:** distribuciones con unos pocos casos
órdenes de magnitud mayores que la mediana. **Cuándo no:** distribuciones como la de la tienda,
donde el máximo está cerca de la media.

> **Veredicto:** el *outlier* se decide con un percentil en la mano: si el máximo está a pocas veces
> de la mediana, no hace falta; si está a miles, protege a todos los demás de un solo documento.

**Teardown del capítulo:** `db.eventos.drop()`. El campo `cliente_pais` se queda en `tienda.pedidos`
hasta que la colección se borre al final de la tanda.

---

## 7. 📜 Estándar, motor y convención

> **📜 Estándar o motor.** Qué se incrusta y qué se referencia es **convención** de modelado; lo que
> lo limita es del **motor**. La columna de PostgreSQL dice qué hace la normalización de `01/04` con
> el mismo problema.

| Afirmación | Estándar | PostgreSQL 18 | MongoDB 8.0 |
|---|---|---|---|
| Dónde va cada parte lo decide el diseñador | No: la normalización lo deduce | La forma normal da la respuesta | Sí, entidad por entidad |
| Hay un tamaño máximo por registro | — | 1 GB por campo | 16 MiB por documento: el `$push` falló pasado el límite |
| Una copia de un dato ajeno se mantiene sola | — | No se copia: se une al leer | No: `updateMany` en cada documento que la lleva |
| Un informe sobre un dato de otra entidad es barato | `JOIN` | 28 ms con *hash join* | 38 ms con la copia; 472 con `$lookup` |
| Agrupar una serie reduce los índices | — | Con particionado, por tramos | Con cubos: de 8,99 MB a 0,37 |
| Las series temporales se agrupan solas | — | Con extensiones, bloque 09 | Sí, en las colecciones de series temporales |

**Convención, la que más se repite.** *«En MongoDB se incrusta todo, que para eso es documental»* —
se incrusta lo acotado y leído junto. Lo que crece con el tiempo acaba en el límite de 16 MiB, y lo
que se consulta solo acaba en un `$unwind` de todos los documentos.

---

## ⚠️ Errores frecuentes

| Se dice | Lo preciso |
|---|---|
| "En documental se incrusta todo" | Se incrusta lo que se lee siempre con su padre y tiene tope; lo demás se referencia |
| "Hoy la lista es corta, así que se incrusta" | Si crece con cada compra, es una lista sin límite; el fallo llega con un `$push` normal |
| "Pasar de 16 MiB da un aviso antes" | El documento de 16 MiB menos cien bytes entró, y el `$push` siguiente falló sin aviso previo |
| "Copiar el país del cliente en el pedido es desnormalizar mal" | Es la referencia extendida: 38 ms frente a 472, pagando un `updateMany` cuando el cliente cambia |
| "El *bucket* ahorra espacio en los datos" | Ahorra sobre todo índice —de 8,99 a 0,37 MB— y lecturas por tramo; el dato es casi el mismo |
| "Hay que aplicar el patrón *outlier* por si acaso" | Con el máximo a dos veces y media la mediana, como en la tienda, sobra |
| "`storageSize` da el tamaño nada más importar" | Hasta el siguiente *checkpoint* no refleja lo escrito; se forzó con `fsync` |

---

## 📚 Para profundizar

- **Documentación** — MongoDB 8.0, «Best Practices for Data Modeling in MongoDB»: incrustar o
  referenciar. <https://www.mongodb.com/docs/v8.0/data-modeling/best-practices/>
- **Documentación** — MongoDB 8.0, «Avoid Unbounded Arrays»: el antipatrón y los 16 MB.
  <https://www.mongodb.com/docs/v8.0/data-modeling/design-antipatterns/unbounded-arrays/>
- **Documentación** — MongoDB 8.0, «Handle Duplicate Data»: la copia deliberada y su coste.
  <https://www.mongodb.com/docs/v8.0/data-modeling/handle-duplicate-data/>
- **Documentación** — MongoDB 8.0, «Group Data with the Bucket Pattern».
  <https://www.mongodb.com/docs/v8.0/data-modeling/design-patterns/group-data/bucket-pattern/>
- **Documentación** — MongoDB 8.0, «Group Data with the Outlier Pattern».
  <https://www.mongodb.com/docs/v8.0/data-modeling/design-patterns/group-data/outlier-pattern/>
- **Documentación** — MongoDB 8.0, «MongoDB Limits and Thresholds»: los 16 mebibytes.
  <https://www.mongodb.com/docs/v8.0/reference/limits/>

---

## 🧠 Preguntas

1. ¿Qué es incrustar y qué es referenciar, en una frase cada uno? 🟢
2. ¿Cuál es el tamaño máximo de un documento en MongoDB? 🟢
3. ¿Qué es el patrón *bucket*? 🟢
4. Distingue la referencia extendida de una referencia simple. ¿Qué parte es del motor y qué parte
   es convención? 🟡
5. Distingue el patrón *bucket* del patrón *outlier*: qué problema resuelve cada uno. 🟡
6. ¿El límite de 16 MiB es del estándar, del formato BSON o del motor? ¿Tiene PostgreSQL uno
   parecido? 🟡
7. ¿Por qué las líneas se incrustan en el pedido y los pedidos no se incrustan en el cliente? 🟡
8. ¿Por qué el `$push` de 200 bytes falló si los anteriores funcionaban? 🟠
9. ¿Qué cuesta la referencia extendida del país del cliente, y cuándo no la usarías? 🟠
10. ¿Por qué el *bucket* redujo el índice de 8,99 MB a 0,37, y qué se paga a cambio? 🟠
11. ¿Por qué la tienda no necesita el patrón *outlier*, y qué dato lo decide? 🟠
12. ¿Por qué hay que forzar un *checkpoint* antes de leer `storageSize` tras una carga, y cómo se
    hace? 🟠
13. Cambiar el país de `CLI-00311` tocó siete pedidos y su documento de cliente. ¿Qué puede ver un
    lector entre las dos escrituras, y cómo lo evitarías? 🟠
14. Diseña el documento de producto para guardar sus valoraciones, sabiendo que un producto popular
    puede tener cientos de miles: qué incrustas, qué referencias y qué patrón usas. 🔴
15. Diagnostica: un servicio que añade el historial de estados de cada pedido dentro del documento
    empieza a fallar con `Resulting document after update is larger than 16777216` en unos pocos
    pedidos. Da la causa, cómo encontrarías los afectados y el rediseño. 🔴
16. Decide, para cada relación de la tienda —pedido y pagos, cliente y direcciones, producto y
    precio histórico—, si incrustar o referenciar, con el dato que necesitarías medir para cada una.
    🔴

---

**Anterior:** [`02`](02-mongodb-consulta-y-agregacion.md) — consulta y agregación · **Siguiente:**
[`04`](04-indices-transacciones-y-consistencia.md) — índices, transacciones y consistencia ·
**Relacionado:**
[`01/04`](../01-fundamentos-y-modelo-relacional/04-normalizacion-y-desnormalizacion.md) — la
normalización, que en relacional contesta esta pregunta por ti ·
[`07/06`](../07-clave-valor/06-dynamodb-diseno-desde-el-acceso.md) §2 — el método de diseñar desde
el acceso.
