# 04 — Índices, transacciones y consistencia

> Lo que decide si una colección de MongoDB aguanta producción: los índices que la leen —el que
> indexa cada elemento de una lista, el compuesto cuyo orden de campos decide si hay que ordenar en
> memoria, y la consulta que no lee ningún documento—, y las garantías de un conjunto de réplicas:
> una escritura que **falla por tiempo de espera y aun así queda aplicada**, una lectura del
> secundario que devuelve el estado de antes, y dos transacciones sobre el mismo pedido que no se
> esperan: una aborta al instante. **Asume leído:** [`02`](02-mongodb-consulta-y-agregacion.md), el
> `explain` y la atomicidad por documento, y
> [`04/02`](../04-transacciones-y-concurrencia/02-aislamiento-y-sus-fenomenos.md), los niveles de
> aislamiento. **Vigencia:** 27 de septiembre de 2026.

---

## Salto rápido

- [1. El problema](#1--el-problema) · [2. El índice multikey](#2--el-índice-multikey) · [3. Índices
  compuestos y la regla ESR](#3--índices-compuestos-y-la-regla-esr)
- [4. El conjunto de réplicas y writeConcern](#4--el-conjunto-de-réplicas-y-writeconcern) · [5. Leer
  del secundario y readConcern](#5--leer-del-secundario-y-readconcern)
- [6. Transacciones multidocumento](#6--transacciones-multidocumento) · [7. Estándar, motor y
  convención](#7--estándar-motor-y-convención) · [Preguntas](#-preguntas)

---

## 1. 🎯 El problema

Un pedido pasa a `ENVIADO` y el panel de operaciones, que lee de un secundario «para no cargar el
primario», sigue diciendo `PAGADO`. El equipo decide escribir con `w: "majority"`, para que la
escritura espere a la réplica. La siguiente vez que un secundario va lento, la escritura devuelve un
error de tiempo de espera; el servicio lo reintenta, pensando que no se hizo, y **el cambio ya
estaba hecho**. Mientras tanto, en el servicio de pagos, alguien ha envuelto cada operación en una
transacción, y la latencia se ha duplicado.

En PostgreSQL, las garantías de lectura y escritura de un servidor están en el bloque 04 y se
eligen con el nivel de aislamiento y `synchronous_commit`. En MongoDB se eligen **por operación**,
con tres controles que se confunden entre sí: `writeConcern`, `readConcern` y `readPreference`. Y
las transacciones multidocumento existen, pero solo en un conjunto de réplicas, y cuestan.

Antes de eso, los índices, que son lo primero que falla cuando una colección crece: el que indexa
las listas, y el compuesto cuyo orden de campos cambia mil veces el trabajo.

> **📝 Contexto.** Los índices de §2 y §3 se corrieron contra `bd-lab-mongo`, con los pedidos de
> `01`. **Las transacciones y la consistencia necesitan un conjunto de réplicas**, y `bd-lab-mongo`
> es un servidor suelto: rechaza cualquier transacción, como se ve en §6. Para §4–§6 se montó un
> **conjunto desechable de tres nodos** con la misma imagen, `mongo:8.0.20`, en una red propia
> —`bd-lab-prueba-mongo1` a `3`—, sin autenticación por ser un laboratorio local, y se borró al
> terminar. El retraso de un secundario se provocó con `db.fsyncLock()`, que le impide aplicar
> escrituras. `PED-00042` se cambió varias veces y se devolvió a `PAGADO`. **Longitud:** unas 480
> líneas; capítulo normal que pasa el disparador de 400, con 143 líneas de sesión.

---

## 2. 🧱 El índice multikey

**Qué es:** un índice sobre un campo que contiene una lista. MongoDB lo crea como **multikey** sin
que se pida, y según su documentación mete una entrada por cada valor distinto de la lista, todas
apuntando al mismo documento. Los pedidos que llevan `PRD-00017`, antes y después del índice, con
una función que resume el plan como la de [`l04`](../13-laboratorio/l04-redis-y-mongodb.md) §5:

```text
tienda> const plan = (c) => { const e = c.explain("executionStats"); const etapas = []; for (let s = e.queryPlanner.winningPlan; s; s = s.inputStage) etapas.push(s.stage + (s.isMultiKey ? " multikey" : "")); return {etapas: etapas.join(" <- "), claves: e.executionStats.totalKeysExamined, docs: e.executionStats.totalDocsExamined, devueltos: e.executionStats.nReturned, ms: e.executionStats.executionTimeMillis} }

tienda> plan(db.pedidos.find({"lineas.producto": "PRD-00017"}))
{ etapas: 'COLLSCAN', claves: 0, docs: 99999, devueltos: 2589, ms: 74 }
tienda> db.pedidos.createIndex({"lineas.producto": 1})
lineas.producto_1
tienda> plan(db.pedidos.find({"lineas.producto": "PRD-00017"}))
{
  etapas: 'FETCH <- IXSCAN multikey',
  claves: 2589,
  docs: 2589,
  devueltos: 2589,
  ms: 3
}
```

- **Sin índice, 99 999 documentos para devolver 2 589**, en 74 ms. Con él, 2 589 claves y 2 589
  documentos, en 3 ms: el trabajo justo.
- **`IXSCAN multikey`**: el plan dice que el índice es de los que tienen varias entradas por
  documento. Es lo que permite buscar dentro de las líneas sin desplegarlas con `$unwind`.

**Quién lo manda:** **motor**. **Cuánto:** una entrada por elemento: el índice ocupó 3,28 MB, tres
veces el de `_id` —1,03 MB en la sesión, 1,27 tras un *checkpoint*—, porque indexa las 349 999
líneas y no los 99 999 pedidos. Y cada `$push` a la lista es una escritura más en el índice.
**Cuándo sí:** búsquedas frecuentes por un valor de dentro de una lista. **Cuándo no:** listas
largas que crecen mucho, donde el índice crece con ellas.

> **Veredicto:** el índice multikey hace que buscar dentro de una lista cueste lo que buscar un
> campo; se paga con una entrada por elemento.

---

## 3. 🧱 Índices compuestos y la regla ESR

**Qué es:** un índice sobre varios campos, como el de
[`03/03`](../03-el-motor-por-dentro/03-compuestos-parciales-y-de-cobertura.md) en PostgreSQL. Lo que
se decide es el **orden**, y la documentación de MongoDB lo resume en la regla **ESR**: primero los
campos de **igualdad**, después los de **orden** (*sort*) y al final los de **rango**. Los diez
pedidos pagados de 5 000 o más, del más reciente al más viejo, con dos índices que tienen los mismos
campos en distinto orden:

```text
tienda> db.pedidos.createIndex({estado: 1, total: 1, creado_en: -1}, {name: "ers"})
ers
tienda> db.pedidos.createIndex({estado: 1, creado_en: -1, total: 1}, {name: "esr"})
esr
tienda> const q = {estado: "PAGADO", total: {$gte: Decimal128("5000")}}

tienda> plan(db.pedidos.find(q).sort({creado_en: -1}).limit(10).hint("ers"))
{
  etapas: 'FETCH <- SORT <- IXSCAN',
  claves: 11859,
  docs: 10,
  devueltos: 10,
  ms: 10
}
tienda> plan(db.pedidos.find(q).sort({creado_en: -1}).limit(10).hint("esr"))
{
  etapas: 'LIMIT <- FETCH <- IXSCAN',
  claves: 16,
  docs: 10,
  devueltos: 10,
  ms: 1
}
tienda> plan(db.pedidos.find({estado: "PAGADO"}, {_id: 0, estado: 1, creado_en: 1}).sort({creado_en: -1}).limit(10).hint("esr"))
{
  etapas: 'LIMIT <- PROJECTION_COVERED <- IXSCAN',
  claves: 10,
  docs: 0,
  devueltos: 10,
  ms: 0
}
tienda> db.pedidos.stats().indexSizes
{
  _id_: 1028096,
  'lineas.producto_1': 3280896,
  ers: 2899968,
  esr: 2617344
}
```

- **Con el rango antes que el orden (`ers`), 11 859 claves y un `SORT` en memoria**: el índice
  encuentra todos los pagados de 5 000 o más, pero no los tiene ordenados por fecha, así que los lee
  todos, los ordena y se queda con diez.
- **Con el orden antes que el rango (`esr`), 16 claves y ningún `SORT`**: recorre los pagados ya
  ordenados por fecha, descarta los de menos de 5 000 al paso y para en el décimo. `hint` fuerza
  cada índice para compararlos.
- **La consulta cubierta no lee ningún documento**: pide solo `estado` y `creado_en`, que están en
  el índice, y quita el `_id` con `_id: 0`. `PROJECTION_COVERED` y cero documentos: es el
  *index-only scan* de PostgreSQL.

**Quién lo manda:** **motor**; la regla es **convención** de la documentación, con un matiz que ella
misma da: si el rango es **muy selectivo**, conviene ponerlo antes del orden, porque deja muy pocas
claves que ordenar. Aquí el rango dejaba 11 859. **Cuánto:** cada índice compuesto ocupa lo suyo
—2,6 y 2,9 MB— y se escribe en cada inserción. **Cuándo sí:** consultas frecuentes con igualdad,
orden y rango sobre los mismos campos. **Cuándo no:** un índice por cada consulta posible.

> **Veredicto:** en un índice compuesto, el orden de los campos decide si se ordena en memoria; ESR
> evita el `SORT`, y un rango muy selectivo puede ir antes.

**Teardown de §2 y §3:** `db.pedidos.dropIndexes()`, que deja solo el de `_id`.

---

## 4. 🧱 El conjunto de réplicas y writeConcern

**Qué es un conjunto de réplicas**: varios `mongod` con los mismos datos, de los que uno es el
**primario**, que acepta las escrituras, y los demás **secundarios**, que las copian de forma
asíncrona. Si el primario cae, los demás eligen otro. Es lo que MongoDB necesita para las
transacciones y para elegir garantías de lectura y escritura. El desechable de este capítulo:

```bash
docker network create bd-lab-prueba-rs
docker run -d --name bd-lab-prueba-mongo1 --hostname bd-lab-prueba-mongo1 --network bd-lab-prueba-rs \
  mongo:8.0.20 mongod --replSet rs0 --bind_ip_all
docker exec bd-lab-prueba-mongo1 mongosh --quiet --eval 'rs.initiate({_id: "rs0", members: [
  {_id: 0, host: "bd-lab-prueba-mongo1:27017"}, {_id: 1, host: "bd-lab-prueba-mongo2:27017"},
  {_id: 2, host: "bd-lab-prueba-mongo3:27017"}]}).ok'
```

- `docker run` se repite para `mongo2` y `mongo3`; `--replSet rs0` dice a cada `mongod` a qué
  conjunto pertenece, y `--bind_ip_all` que escuche en la red de Docker y no solo en `localhost`.
- `rs.initiate` da de alta los tres miembros; a los pocos segundos, uno es primario. Los pedidos se
  cargaron con `mongoimport` por la entrada estándar, y la consola se abrió con la cadena de
  conexión del conjunto, que es lo que pone `rs0 [primary]` en el prompt.

**Qué es `writeConcern`**: cuántos miembros tienen que confirmar una escritura antes de que MongoDB
responda. `w: 1`, solo el primario; `w: "majority"`, la mayoría. La documentación dice que el valor
por defecto es `majority`. Con los dos secundarios bloqueados con `db.fsyncLock()`, para que no
apliquen nada:

```text
rs0 [primary] tienda> db.pedidos.updateOne({_id: "PED-00042"}, {$set: {estado: "ENTREGADO"}}, {writeConcern: {w: "majority", wtimeout: 3000}})
Uncaught:
MongoWriteConcernError[WriteConcernFailed]: waiting for replication timed out
Additional information: {
  wtimeout: true,
  writeConcern: { w: 'majority', wtimeout: 3000, provenance: 'clientSupplied' }
}
Result: {
  n: 1,
  electionId: ObjectId('7fffffff0000000000000001'),
  opTime: { ts: Timestamp({ t: 1790519853, i: 2 }), t: 1 },
  nModified: 1,
  writeConcernError: {
    code: 64,
    codeName: 'WriteConcernFailed',
    errmsg: 'waiting for replication timed out',
    errInfo: {
      wtimeout: true,
      writeConcern: { w: 'majority', wtimeout: 3000, provenance: 'clientSupplied' }
    }
  },
  ok: 1,
  '$clusterTime': {
    clusterTime: Timestamp({ t: 1790519853, i: 2 }),
    signature: {
      hash: Binary.createFromBase64('AAAAAAAAAAAAAAAAAAAAAAAAAAA=', 0),
      keyId: 0
    }
  },
  operationTime: Timestamp({ t: 1790519853, i: 2 })
}
```

- **El error dice que la replicación no llegó a tiempo**, y en el resultado **`n` y `nModified`
  valen 1**: el primario sí hizo el cambio. La documentación lo confirma: vencido el `wtimeout`,
  MongoDB **no deshace** las modificaciones ya hechas. Al desbloquear los secundarios, los dos
  tenían `ENTREGADO`.
- **Reintentar a ciegas es el error**: si el cambio no es idempotente —un `$inc`, un `$push`—, el
  reintento lo aplica dos veces. Sin `wtimeout`, dice la documentación, la escritura habría esperado
  indefinidamente.

Y lo que cuesta cada nivel, con mil actualizaciones seguidas de `PED-00042` y el conjunto sano, en
dos corridas:

| Cada actualización | Mil seguidas | Por operación |
|---|---|---|
| `w: 1` | 980 y 1 003 ms | 1,0 ms |
| `w: "majority"` | 1 723 y 1 754 ms | 1,7 ms |
| En su propia transacción, con `withTransaction` | 2 339 y 2 288 ms | 2,3 ms |

**Quién lo manda:** **motor**. **Cuánto:** en **tiempo**, esperar a la mayoría es un 75 % más aquí,
con los tres nodos en la misma máquina; con red de verdad, es la latencia hasta el segundo nodo más
cercano. En **riesgo**, `w: 1` puede perder una escritura confirmada si el primario cae antes de
replicarla. **Cuándo sí:** `majority`, el valor por defecto, para todo lo que importe. **Cuándo
no:** `w: 1` para datos que se pueden perder, como métricas.

> **Veredicto:** `writeConcern` dice cuántos nodos confirman antes de responder; si vence el tiempo
> de espera, la escritura ya está hecha y el error solo dice que no sabe si llegará a la mayoría.

---

## 5. 🩺 Leer del secundario y readConcern

**Qué es `readPreference`**: de qué miembro se lee —primario, secundario, el más cercano—. **Qué es
`readConcern`**: qué garantía tiene lo leído —lo último del nodo (`local`) o lo que ya confirmó la
mayoría (`majority`)—. Con los dos secundarios bloqueados, la secuencia completa:

```text
rs0 [primary] tienda> db.pedidos.updateOne({_id: "PED-00042"}, {$set: {estado: "ENVIADO"}}, {writeConcern: {w: 1}})
{
  acknowledged: true,
  insertedId: null,
  matchedCount: 1,
  modifiedCount: 1,
  upsertedCount: 0
}
rs0 [primary] tienda> db.pedidos.findOne({_id: "PED-00042"}, {estado: 1})
{ _id: 'PED-00042', estado: 'ENVIADO' }
rs0 [primary] tienda> db.pedidos.find({_id: "PED-00042"}, {estado: 1}).readPref("secondary")
[ { _id: 'PED-00042', estado: 'PAGADO' } ]
rs0 [primary] tienda> db.pedidos.find({_id: "PED-00042"}, {estado: 1}).readConcern("majority")
[ { _id: 'PED-00042', estado: 'PAGADO' } ]
```

Y tras desbloquear los secundarios con `db.fsyncUnlock()`, que aplicaron lo pendiente —incluido el
`ENTREGADO` de §4—, y devolver el pedido a su estado:

```text
rs0 [primary] tienda> db.pedidos.find({_id: "PED-00042"}, {estado: 1}).readPref("secondary")
[ { _id: 'PED-00042', estado: 'ENTREGADO' } ]
rs0 [primary] tienda> db.pedidos.updateOne({_id: "PED-00042"}, {$set: {estado: "PAGADO"}})
{
  acknowledged: true,
  insertedId: null,
  matchedCount: 1,
  modifiedCount: 1,
  upsertedCount: 0
}
rs0 [primary] tienda> db.pedidos.find({_id: "PED-00042"}, {estado: 1}).readConcern("majority")
[ { _id: 'PED-00042', estado: 'PAGADO' } ]
```

- **El primario dice `ENVIADO`; el secundario, `PAGADO`**: la documentación avisa de que cualquier
  modo distinto de `primary` puede devolver datos viejos, porque la réplica es asíncrona. Es el
  panel del §1.
- **`readConcern("majority")` también devolvió `PAGADO`, y leyendo del primario**: el primario tenía
  `ENVIADO`, pero ningún otro nodo lo había confirmado, así que para la mayoría el pedido seguía
  `PAGADO`. La documentación garantiza que lo leído con `majority` no se deshará aunque el primario
  caiga, y por eso no enseña lo que podría deshacerse.
- **Al desbloquear, todo converge**: el secundario ve el último valor, y con el pedido otra vez en
  `PAGADO`, la mayoría lo confirma.

**Quién lo manda:** **motor**. **Cuánto:** leer del secundario descarga el primario a cambio de
datos viejos; `majority` da datos que no se deshacen a cambio de no ver lo más reciente. **Cuándo
sí:** secundario para informes que toleran minutos de retraso. **Cuándo no:** para leer justo
después de escribir en la misma operación de usuario, que necesita el primario o una sesión con
consistencia causal.

> **Veredicto:** `readPreference` dice de dónde se lee, `readConcern` qué garantía tiene lo leído;
> un secundario puede ir por detrás, y `majority` puede ir por detrás incluso leyendo del primario.

---

## 6. 🧱 Transacciones multidocumento

**Qué es:** agrupar operaciones sobre varios documentos, de una o varias colecciones, en una
unidad de todo o nada, como una transacción de PostgreSQL. La documentación dice que una operación
sobre un documento ya es atómica, y que por eso, con un buen diseño, las transacciones
multidocumento no suelen hacer falta. Cuando hacen falta, solo funcionan en un conjunto de réplicas:

```text
tienda> const s = db.getMongo().startSession()

tienda> s.startTransaction()

tienda> s.getDatabase("tienda").pedidos.updateOne({_id: "PED-00042"}, {$set: {estado: "ENVIADO"}})
Uncaught MongoServerError[IllegalOperation]: Transaction numbers are only allowed on a replica set member or mongos
tienda> s.abortTransaction()

```

- Es `bd-lab-mongo`, el servidor suelto del entorno. La misma transacción, en el conjunto de
  réplicas, funciona.

Y dos transacciones sobre el mismo pedido, en dos terminales a la vez:

```text
-- sesión A                                            -- sesión B
rs0 [primary] tienda> const sa = db.getMongo().startSession(); sa.startTransaction(); const pa = sa.getDatabase("tienda").pedidos

                                                       rs0 [primary] tienda> const sb = db.getMongo().startSession(); sb.startTransaction(); const pb = sb.getDatabase("tienda").pedidos

rs0 [primary] tienda> pa.updateOne({_id: "PED-00042"}, {$set: {estado: "ENVIADO"}})
{
  acknowledged: true,
  insertedId: null,
  matchedCount: 1,
  modifiedCount: 1,
  upsertedCount: 0
}
                                                       rs0 [primary] tienda> pb.updateOne({_id: "PED-00042"}, {$set: {estado: "ANULADO"}})
                                                       Uncaught MongoServerError[WriteConflict]: Caused by :: Write conflict during plan execution and yielding is disabled. :: Please retry your operation or multi-document transaction.
rs0 [primary] tienda> sa.commitTransaction()

                                                       rs0 [primary] tienda> sb.abortTransaction()

rs0 [primary] tienda> db.pedidos.updateOne({_id: "PED-00042"}, {$set: {estado: "PAGADO"}}).modifiedCount
1
```

- **B no espera: falla al instante con `WriteConflict`**, en 0,02 s. En PostgreSQL, el `UPDATE` de B
  se quedaría bloqueado hasta que A confirmara, como en
  [`04/04`](../04-transacciones-y-concurrencia/04-bloqueos-e-interbloqueos.md) §3; en MongoDB, el
  conflicto aborta la operación y **el reintento es trabajo del cliente**.
- **`withTransaction` es la forma de hacerlo**: según la documentación, esa API reintenta sola ante
  los errores marcados como transitorios, que es la etiqueta de este conflicto. Fue la usada en la
  medición de §4: 2,3 ms por operación frente a 1,7 sin transacción.
- La última orden devolvió `PED-00042` a `PAGADO`.

**Quién lo manda:** **motor**. **Cuánto:** en **tiempo**, un 35 % más por operación que la escritura
con `majority` en la medición de §4; y la documentación limita una transacción a menos de un minuto
por defecto, pasado el cual se aborta. **Cuándo sí:** cambios que tienen que cuadrar entre varios
documentos —el país del cliente y sus pedidos de `03` §4—. **Cuándo no:** como costumbre para cada
escritura: si hace falta en cada operación, el documento está mal cortado.

> **Veredicto:** MongoDB tiene transacciones de verdad, en un conjunto de réplicas y con reintento a
> cargo del cliente; se usan cuando varios documentos tienen que cambiar juntos, no como sustituto
> del diseño.

**Teardown del capítulo:** `docker rm -f` de los tres contenedores y `docker network rm` de su red.

---

## 7. 📜 Estándar, motor y convención

> **📜 Estándar o motor.** Los índices, `writeConcern`, `readConcern` y `readPreference` son de
> MongoDB. Lo que se compara con ISO/IEC 9075 son las transacciones, y la comparación útil es con lo
> que hace PostgreSQL.

| Afirmación | Estándar | PostgreSQL 18 | MongoDB 8.0 |
|---|---|---|---|
| Se puede indexar dentro de una lista | — | Con GIN sobre `jsonb` o arrays | Sí, multikey, sin pedirlo |
| El orden de un índice compuesto decide si se ordena en memoria | — | Sí | Sí: 11 859 claves y `SORT` frente a 16 |
| Una consulta puede no leer la tabla | — | *Index-only scan* | `PROJECTION_COVERED`, cero documentos |
| Una escritura espera a las réplicas antes de responder | — | Solo con réplica síncrona configurada | Con `w: "majority"`, el valor por defecto |
| Un error por tiempo de espera deshace la escritura | — | — | No: `n: 1` con `WriteConcernFailed` |
| Leer de una réplica puede dar datos viejos | — | Sí, en réplicas asíncronas | Sí: `PAGADO` en el secundario |
| Hay transacciones sobre varios registros | Sí | Sí, en cualquier servidor | Solo en un conjunto de réplicas o `mongos` |
| Dos escrituras sobre lo mismo en transacción esperan | Según el aislamiento | La segunda espera el bloqueo | La segunda aborta al instante con `WriteConflict` |

**Convención, la que más se repite.** *«Con `w: "majority"`, si da error, no se escribió»* — se
escribió en el primario, y solo falta saber si llegará a la mayoría. La otra, igual de extendida:
*«MongoDB no tiene transacciones»*; las tiene desde hace años, en conjunto de réplicas, con un coste
que la sesión midió.

---

## ⚠️ Errores frecuentes

| Se dice | Lo preciso |
|---|---|
| "Un índice sobre una lista hay que declararlo especial" | MongoDB lo hace multikey solo, con una entrada por elemento |
| "Los campos de un índice compuesto, en cualquier orden" | Con el rango antes que el orden, 11 859 claves y `SORT` en memoria; con ESR, 16 |
| "Si `w: majority` falla, la escritura no se hizo" | Se hizo en el primario; vencido el `wtimeout`, MongoDB no deshace nada |
| "Leer del secundario es gratis" | Puede devolver el estado anterior: `PAGADO` con el primario en `ENVIADO` |
| "`readConcern: majority` da lo último" | Da lo que confirmó la mayoría, que puede ir por detrás incluso en el primario |
| "Las transacciones funcionan en cualquier MongoDB" | En un servidor suelto fallan; hace falta un conjunto de réplicas |
| "Dos transacciones sobre el mismo documento se esperan" | La segunda aborta con `WriteConflict`; el reintento es del cliente o de `withTransaction` |

---

## 📚 Para profundizar

- **Documentación** — MongoDB 8.0, «Multikey Indexes»: una entrada por elemento.
  <https://www.mongodb.com/docs/v8.0/core/indexes/index-types/index-multikey/>
- **Documentación** — MongoDB 8.0, «The ESR (Equality, Sort, Range) Guideline»: y cuándo ERS.
  <https://www.mongodb.com/docs/v8.0/tutorial/equality-sort-range-guideline/>
- **Documentación** — MongoDB 8.0, «Write Concern»: el valor por defecto y el `wtimeout` que no
  deshace. <https://www.mongodb.com/docs/v8.0/reference/write-concern/>
- **Documentación** — MongoDB 8.0, «Read Concern "majority"».
  <https://www.mongodb.com/docs/v8.0/reference/read-concern-majority/>
- **Documentación** — MongoDB 8.0, «Read Preference»: los modos y los datos viejos.
  <https://www.mongodb.com/docs/v8.0/core/read-preference/>
- **Documentación** — MongoDB 8.0, «Transactions»: la atomicidad por documento y cuándo hacen falta.
  <https://www.mongodb.com/docs/v8.0/core/transactions/>
- **Documentación** — MongoDB 8.0, «Production Considerations»: el límite de un minuto.
  <https://www.mongodb.com/docs/v8.0/core/transactions-production-consideration/>

---

## 🧠 Preguntas

1. ¿Qué es un índice multikey, y cuándo lo crea MongoDB? 🟢
2. ¿Qué dice la regla ESR? 🟢
3. ¿Qué es una consulta cubierta, y qué etapa la delata en el plan? 🟢
4. ¿Qué es `writeConcern`, y cuál es su valor por defecto? 🟢
5. Distingue `readPreference` de `readConcern`. ¿Lo fija el estándar o es cosa del motor? 🟡
6. Distingue `w: 1` de `w: "majority"`: qué garantiza cada uno y cuánto costó. 🟡
7. ¿Qué dice el estándar SQL sobre transacciones que MongoDB solo ofrece en un conjunto de réplicas?
   ¿Y qué hace PostgreSQL? 🟡
8. ¿Por qué el índice multikey de `lineas.producto` ocupa tres veces lo que el de `_id`? 🟡
9. Distingue lo que hace PostgreSQL y lo que hace MongoDB cuando dos transacciones escriben el mismo
   registro a la vez. 🟡
10. ¿Por qué el índice `ers` leyó 11 859 claves y el `esr` 16, con los mismos campos? 🟠
11. ¿Cuándo conviene poner el rango antes que el orden, según la propia documentación? 🟠
12. La escritura con `w: "majority"` devolvió error por tiempo de espera. ¿Se hizo? ¿Qué pasa si el
    servicio la reintenta? 🟠
13. ¿Por qué `readConcern("majority")` devolvió `PAGADO` leyendo del primario, que tenía `ENVIADO`?
    🟠
14. ¿Qué cuesta una transacción frente a una escritura suelta con `majority`, con lo medido, y
    cuándo merece la pena? 🟠
15. ¿Por qué en una transacción de MongoDB el reintento es trabajo del cliente, y qué API lo hace
    por ti? 🟠
16. Diseña los índices de `tienda.pedidos` para «los pedidos pendientes de un cliente, del más
    reciente al más antiguo» y «los pedidos que llevan un producto», y di qué consulta sería
    cubierta. 🔴
17. Diagnostica: el panel de operaciones, que lee de los secundarios, enseña a veces pedidos en un
    estado que ya cambió, y un servicio que reintenta las escrituras que dan error de replicación
    duplica movimientos. Da la causa de cada síntoma y la corrección. 🔴
18. Diseña cómo cambiarías el país de un cliente y el de todos sus pedidos en MongoDB para que
    ningún lector vea un estado a medias, y di qué pasa si el cambio choca con otra escritura. 🔴

---

**Anterior:** [`03`](03-incrustar-frente-a-referenciar.md) — incrustar frente a referenciar ·
**Siguiente:** [`05`](05-documental-relacional-o-jsonb.md) — documental, relacional o `jsonb` ·
**Relacionado:** [`03/03`](../03-el-motor-por-dentro/03-compuestos-parciales-y-de-cobertura.md) —
compuestos y de cobertura en PostgreSQL ·
[`04/02`](../04-transacciones-y-concurrencia/02-aislamiento-y-sus-fenomenos.md) — los niveles de
aislamiento.
