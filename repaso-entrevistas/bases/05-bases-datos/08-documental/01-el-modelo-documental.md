# 01 — El modelo documental

> Qué es un documento, qué resuelve mejor que tres tablas unidas por un `JOIN` y qué deja de
> garantizar, medido con el mismo pedido en MongoDB y en PostgreSQL: un documento de 379 bytes
> frente a diecisiete páginas de tres tablas, y un total guardado como texto que la base acepta y la
> suma ignora sin avisar. Cierra con la ficha del modelo y el mapa de motores documentales, cada uno
> por lo único que hace distinto. **Asume leído:**
> [`10/07`](../10-interfaz-con-los-lenguajes/07-clientes-de-redis-y-mongodb.md), el cliente de
> MongoDB, y [`l04`](../13-laboratorio/l04-redis-y-mongodb.md) §4–§6, donde los pedidos ya se
> cargaron, se indexaron y se agregaron. **Vigencia:** 27 de septiembre de 2026.

---

## Salto rápido

- [1. El problema](#1--el-problema) · [2. Qué es un documento](#2--qué-es-un-documento)
- [3. El mismo pedido, en relacional](#3-️-el-mismo-pedido-en-relacional) · [4. Esquema flexible, y
  sin validar](#4--esquema-flexible-y-sin-validar)
- [5. La ficha del modelo](#5--la-ficha-del-modelo) · [6. El mapa de
  motores](#6-️-el-mapa-de-motores)
- [7. Estándar, motor y convención](#7--estándar-motor-y-convención) · [Errores
  frecuentes](#️-errores-frecuentes) · [Preguntas](#-preguntas)

---

## 1. 🎯 El problema

La ficha de `PED-00042` en la web enseña el pedido con sus tres líneas. En PostgreSQL, eso son
tres tablas —`pedidos`, `pedido_lineas` y `productos`—, dos `JOIN`, cinco búsquedas por índice y
diecisiete páginas leídas. El código que la pinta, en cambio, no piensa en tablas: piensa en **un
pedido**, con su estado, su total y sus líneas dentro, que se crea entero, se cambia entero y se lee
entero.

La promesa de una base documental es guardar las cosas **con la forma con que se usan**: el pedido
como un documento, con las líneas dentro. Una lectura, una escritura, ningún `JOIN`. Y una segunda
promesa, que es la que más se repite: **el esquema es flexible**, así que añadir un campo no pide
migración.

Las dos son ciertas y las dos tienen letra pequeña. Este capítulo las mide con el mismo pedido en
los dos motores, y termina con una sesión que conviene recordar: un total guardado como texto que
MongoDB aceptó sin quejarse y que la suma de los pedidos anulados se saltó en silencio.

> **📝 Contexto.** Todo está corrido contra `bd-lab-mongo`, con `mongo:8.0.20` (§4.1 del documento
> de dominio dice por qué esa versión), y contra `bd-lab-postgres`. Las colecciones `pedidos`,
> `clientes` y `productos` se cargaron desde PostgreSQL con `mongoimport`, como en `l04` §4: los
> 99 999 pedidos hasta `PED-99999` con sus líneas dentro, y los clientes y productos enteros.
> `PED-99999` se cambió a propósito en §4 y se devolvió a su valor exacto. **El mapa de §6 no tiene
> sesiones**: Couchbase, CouchDB y Firestore no están en el entorno, y lo que se dice de cada uno
> sale de su documentación oficial. **Longitud:** unas 380 líneas; capítulo normal.

---

## 2. 🧱 Qué es un documento

**Qué es:** un documento es un registro con estructura —campos, valores, listas y subdocumentos—
que el motor guarda y lee **como una unidad**. En MongoDB se guarda en **BSON**, una forma binaria
de JSON con más tipos: `Decimal128` para el dinero exacto, `ISODate` para las fechas. Los documentos
se agrupan en **colecciones**, el equivalente de una tabla, y cada uno tiene un `_id` único, que es
su clave primaria.

```text
tienda> db.pedidos.findOne({_id: "PED-00042"})
{
  _id: 'PED-00042',
  cliente: 'CLI-26446',
  estado: 'PAGADO',
  total: Decimal128('3186.23'),
  creado_en: ISODate('2025-02-21T03:08:09.349Z'),
  lineas: [
    {
      linea: 1,
      producto: 'PRD-01395',
      cantidad: 1,
      precio_unit: Decimal128('102.83')
    },
    {
      linea: 2,
      producto: 'PRD-00872',
      cantidad: 5,
      precio_unit: Decimal128('27.03')
    },
    {
      linea: 3,
      producto: 'PRD-03623',
      cantidad: 3,
      precio_unit: Decimal128('982.75')
    }
  ]
}
tienda> bsonsize(db.pedidos.findOne({_id: "PED-00042"}))
379
tienda> db.pedidos.find({_id: "PED-00042"}).explain("executionStats").executionStats.executionStages.stage
EXPRESS_IXSCAN
tienda> db.pedidos.find({_id: "PED-00042"}).explain("executionStats").executionStats.totalDocsExamined
1
```

- **Las líneas viven dentro del pedido**, como una lista de subdocumentos. Es lo que en relacional
  sería otra tabla con una clave foránea; aquí es un campo.
- **379 bytes el pedido entero**, líneas incluidas. `bsonsize` es la función de `mongosh`; la de los
  tutoriales antiguos, `Object.bsonsize`, era del *shell* anterior y hoy falla con un aviso que lo
  dice.
- **`EXPRESS_IXSCAN` y un documento examinado**: la búsqueda por `_id` va directa al índice que toda
  colección trae sobre él y lee un solo documento, el que trae todo.

**Quién lo manda:** **motor**. BSON, las colecciones y el `_id` son de MongoDB; ninguna norma
define el modelo documental. **Cuánto:** en **espacio**, el nombre de cada campo se repite en cada
documento, porque no hay un esquema aparte que los guarde una vez. **Cuándo sí:** entidades que se
leen y se escriben enteras, con sus partes dentro. **Cuándo no:** partes que se consultan por su
cuenta a menudo —«todas las líneas de `PRD-00017`»—, que es la materia de
[`02`](02-mongodb-consulta-y-agregacion.md) y [`03`](03-incrustar-frente-a-referenciar.md).

> **Veredicto:** un documento guarda una entidad con la forma con que la usa el código; se lee y se
> escribe de una vez, y lo que está dentro no se consulta tan barato como lo que está suelto.

---

## 3. ⚖️ El mismo pedido, en relacional

El mismo pedido en PostgreSQL, con sus líneas y el código de cada producto:

```text
tienda=# EXPLAIN (ANALYZE, BUFFERS) SELECT p.codigo, p.estado, p.total, l.linea, pr.codigo AS producto, l.cantidad, l.precio_unit FROM pedidos p JOIN pedido_lineas l ON l.pedido_id = p.id JOIN productos pr ON pr.id = l.producto_id WHERE p.codigo = 'PED-00042';
                                                                     QUERY PLAN
----------------------------------------------------------------------------------------------------------------------------------------------------
 Nested Loop  (cost=1.14..8.05 rows=4 width=47) (actual time=0.043..0.057 rows=3.00 loops=1)
   Buffers: shared hit=17
   ->  Nested Loop  (cost=0.85..6.85 rows=4 width=45) (actual time=0.032..0.033 rows=3.00 loops=1)
         Buffers: shared hit=8
         ->  Index Scan using pedidos_codigo_key on pedidos p  (cost=0.42..2.64 rows=1 width=33) (actual time=0.024..0.024 rows=1.00 loops=1)
               Index Cond: (codigo = 'PED-00042'::text)
               Index Searches: 1
               Buffers: shared hit=4
         ->  Index Scan using pedido_lineas_pkey on pedido_lineas l  (cost=0.43..4.17 rows=4 width=28) (actual time=0.007..0.007 rows=3.00 loops=1)
               Index Cond: (pedido_id = p.id)
               Index Searches: 1
               Buffers: shared hit=4
   ->  Index Scan using productos_pkey on productos pr  (cost=0.28..0.30 rows=1 width=18) (actual time=0.006..0.006 rows=1.00 loops=3)
         Index Cond: (id = l.producto_id)
         Index Searches: 3
         Buffers: shared hit=9
 Planning:
   Buffers: shared hit=302
 Planning Time: 0.595 ms
 Execution Time: 0.115 ms
(20 filas)
```

- **Diecisiete páginas y cinco búsquedas por índice**: el pedido por su código, sus líneas por la
  clave compuesta y el código de cada uno de los tres productos. Es el `Nested Loop` de
  [`03/05`](../03-el-motor-por-dentro/05-explain-y-explain-analyze.md), en 0,115 ms.
- **Los dos son rápidos**: 0,115 ms aquí, un documento por índice allí. Con los datos en memoria, un
  pedido no justifica cambiar de motor por velocidad. Lo que cambia es la **localidad**: MongoDB lee
  todo de un sitio; PostgreSQL lo reúne de tres tablas en cada lectura.

Y en espacio, con los mismos 99 999 pedidos y sus líneas:

| | PostgreSQL | MongoDB |
|---|---|---|
| Datos sin comprimir | 31 MB —`pedidos` y `pedido_lineas`, la décima parte de cada tabla— | 42 MB de BSON |
| En disco | Los mismos 31 MB | 10,5 MB: WiredTiger comprime con snappy por defecto |
| Índices | Los de las dos tablas | 1,2 MB, solo el de `_id` |

- **Sin comprimir, el documento ocupa más**, porque cada campo repite su nombre en cada pedido. **En
  disco ocupa menos**, porque el motor de almacenamiento de MongoDB comprime los bloques, cosa que
  PostgreSQL no hace con las filas pequeñas. En memoria, al leerlo, vuelve a ser BSON sin comprimir.

**Quién lo manda:** **motor**, los dos. **Cuánto:** PostgreSQL paga el `JOIN` en cada lectura;
MongoDB paga la repetición de nombres y, sobre todo, lo que se ve en
[`03`](03-incrustar-frente-a-referenciar.md): el día que una parte necesita vivir por su cuenta.
**Cuándo sí:** el documento, cuando la entidad se usa entera. **Cuándo no:** cuando las partes se
cruzan con otras entidades a menudo.

> **Veredicto:** leer un pedido por su clave es rápido en los dos motores; el documento gana en
> localidad y en escribir el agregado de una vez, no en milisegundos.

---

## 4. 🩺 Esquema flexible, y sin validar

**Qué es:** en MongoDB, una colección no tiene un esquema que el motor compruebe salvo que se lo
pidas. Cada documento puede traer los campos que quiera, con los tipos que quiera. Es lo que permite
añadir un campo sin migración, y lo que permite esto:

```text
tienda> db.pedidos.aggregate([{$match: {estado: "ANULADO"}}, {$group: {_id: null, pedidos: {$sum: 1}, importe: {$sum: "$total"}}}])
[ { _id: null, pedidos: 5960, importe: Decimal128('30986780.66') } ]
tienda> db.pedidos.updateOne({_id: "PED-99999"}, {$set: {total: "5971.28"}})
{
  acknowledged: true,
  insertedId: null,
  matchedCount: 1,
  modifiedCount: 1,
  upsertedCount: 0
}
tienda> db.pedidos.aggregate([{$match: {estado: "ANULADO"}}, {$group: {_id: null, pedidos: {$sum: 1}, importe: {$sum: "$total"}}}])
[ { _id: null, pedidos: 5960, importe: Decimal128('30980809.38') } ]
tienda> db.pedidos.find({total: {$type: "string"}}, {total: 1})
[ { _id: 'PED-99999', total: '5971.28' } ]
```

- **El importe de los anulados, el mismo que el `GROUP BY` de `l04` §6**, hasta que alguien guarda
  el total de `PED-99999` como texto. **MongoDB lo acepta**: `modifiedCount: 1`.
- **La suma baja 5 971,28 y sigue contando 5 960 pedidos.** La documentación de `$sum` lo dice en su
  primera línea: ignora los valores que no son números. No hay error, no hay aviso: el informe
  simplemente está mal.
- **`$type` los encuentra**, si sabes que tienes que buscarlos. El total se devolvió después a
  `Decimal128("5971.28")` y la suma volvió a 30 986 780,66.

En PostgreSQL, el mismo cambio no llega a la tabla:

```text
tienda=# BEGIN;
BEGIN
tienda=*# UPDATE pedidos SET total = 'cinco mil' WHERE codigo = 'PED-99999';
ERROR:  invalid input syntax for type numeric: "cinco mil"
LÍNEA 1: UPDATE pedidos SET total = 'cinco mil' WHERE codigo = 'PED-9...
                                    ^
tienda=!# ROLLBACK;
ROLLBACK
```

- La columna es `numeric(12,2)`, y el tipo rechaza lo que no lo es. El mensaje sale en inglés porque
  lo escribe el servidor; `LÍNEA 1` lo traduce el `psql` del corpus.

**Quién lo manda:** **motor**. En SQL, el tipo de la columna es del **estándar**; en MongoDB, la
validación existe —el `$jsonSchema` de [`05`](05-documental-relacional-o-jsonb.md) §2— pero hay
que declararla. **Cuánto:** en **riesgo**: datos con la forma equivocada que nadie detecta hasta que
un informe no cuadra. **Cuándo sí:** atributos que de verdad varían entre documentos, con validación
en la escritura. **Cuándo no:** como excusa para no pensar el esquema.

> **🧠 Modelo mental.** «Sin esquema» no existe: **el esquema está en algún sitio**. En PostgreSQL,
> en la tabla, y la base lo hace cumplir. En MongoDB sin validación, en el código de cada servicio
> que escribe, y lo hace cumplir cada uno a su manera, o nadie.

> **Veredicto:** el esquema flexible quita la migración y quita la red: un campo con el tipo
> equivocado entra, y la agregación lo salta sin avisar.

---

## 5. 🧭 La ficha del modelo

| Punto | Documental |
|---|---|
| **Qué resuelve mejor que SQL** | La entidad que se lee y se escribe entera —un pedido con sus líneas, un perfil con sus preferencias— en una operación y sin `JOIN`, y atributos que varían entre documentos |
| **Dónde falla SQL, y por qué** | El agregado se reparte en varias tablas y se reúne con un `JOIN` en cada lectura; y un atributo que solo tienen algunos objetos obliga a columnas casi vacías o a tablas aparte |
| **Producto principal y stack** | MongoDB, con `mongosh` y el lenguaje de consulta de MongoDB; drivers oficiales en Java, Python, Node y Go ([`10/07`](../10-interfaz-con-los-lenguajes/07-clientes-de-redis-y-mongodb.md)); `bd-lab-mongo`, `mongo:8.0.20` |
| **El caso** | La ficha del pedido → abajo, con números |

**El caso, con números.** La ficha de un pedido se pide 2 000 veces por segundo en campaña, y cada
pedido tiene de una a seis líneas. **Por qué SQL se complica ahí**: cada ficha son tres tablas y
diecisiete páginas; con la caché caliente son 0,115 ms, pero el `JOIN` se hace en cada lectura, y
escribir un pedido son varias filas en dos tablas dentro de una transacción. **Cómo lo resuelve el
modelo**: el pedido es un documento de unos 400 bytes que se lee por su `_id` y se escribe de una
vez; cambiar una línea es un `updateOne` atómico sobre ese documento. **Qué se paga a cambio**: las
líneas ya no se consultan solas con la misma facilidad —el ranking de productos necesita desplegar
cada pedido—; el esquema lo valida tu código salvo que declares uno; y si el documento crece sin
tope, choca con los 16 MiB por documento que fija la documentación, que es el problema de `03`.

---

## 6. ⚖️ El mapa de motores

MongoDB es el que se aprende en este bloque, porque es el que se pregunta. Los demás motores
documentales entran por lo único que hacen distinto, que es lo que merece la pena saber de cada uno:

| Motor | Lo que lo distingue, según su documentación | Lo que cambia en el diseño |
|---|---|---|
| **MongoDB** | Documentos BSON, consultas por cualquier campo con índices secundarios, y el *pipeline* de agregación | Es la referencia de este bloque |
| **Couchbase** | **SQL++**, antes llamado N1QL: consultas con sintaxis SQL sobre documentos JSON, con rutas anidadas | «Documental» no significa «sin SQL» |
| **CouchDB** | **Replicación entre copias** de una base, que pueden estar lejos o desconectadas; en conflicto, elige un ganador determinista y guarda los demás en `_conflicts` | Los conflictos son parte del modelo: la aplicación los resuelve. PouchDB lleva la replicación al navegador sin conexión |
| **Firestore** | **Escucha en tiempo real** con `onSnapshot()`, y **cobra por documento leído**, escrito y borrado, y por entrada de índice leída | El esquema se diseña para leer pocos documentos: la factura depende de eso |
| **PostgreSQL `jsonb`** | Documentos dentro de una tabla relacional, con índices y SQL | La tercera vía; tiene capítulo propio en `05` |

- **Couchbase rompe el mito de que documental es sin SQL**: su lenguaje de consulta se llama SQL++ y
  su documentación lo presenta con `SELECT`, `WHERE` y rutas como `geo.lat` dentro del documento.
- **CouchDB es el caso *offline-first*** que MongoDB no cubre: dos copias que se editan por
  separado y se sincronizan después. El precio es que el conflicto no es una excepción, es un
  estado normal del documento.
- **Firestore cambia el diseño por la factura**: con cobro por documento leído, una pantalla que lee
  cien documentos cuesta cien veces más que una que lee uno, y el modelo se desnormaliza para leer
  menos.

> **Veredicto:** los motores documentales comparten el documento y se separan en todo lo demás: el
> lenguaje, la replicación y el modelo de cobro deciden más que la palabra «documental».

---

## 7. 📜 Estándar, motor y convención

> **📜 Estándar o motor.** No hay estándar del modelo documental comparable a ISO/IEC 9075. El
> estándar SQL sí tiene una parte para JSON —SQL/JSON: un modelo de datos, un lenguaje de rutas y
> funciones como `JSON_TABLE`—, que PostgreSQL implementa según su documentación; no he verificado
> la cláusula, y es materia de `05`.

| Afirmación | Estándar | PostgreSQL 18 | MongoDB 8.0 |
|---|---|---|---|
| Una entidad con sus partes se lee en una operación | — | Con `JOIN`: 17 páginas, 0,115 ms | Un documento por `_id`: `EXPRESS_IXSCAN` |
| El tipo de un campo lo comprueba la base | Sí, el tipo de la columna | Sí: rechazó `'cinco mil'` | No, salvo validación declarada |
| Una suma sobre valores de tipo mezclado avisa | — | No llega a haber tipos mezclados | No: `$sum` ignora lo que no es número |
| Añadir un campo exige cambiar el esquema | Sí, `ALTER TABLE` | Sí, aunque añadir una columna nullable es inmediato | No |
| El dinero se guarda exacto | `DECIMAL` | `numeric` | `Decimal128`, si se carga como tal |
| Los datos se comprimen en disco por defecto | — | Solo los valores grandes, con TOAST | Sí: snappy en colecciones, prefijos en índices |

**Convención, la que más se repite.** *«MongoDB no tiene esquema»* — tiene el que escriba cada
servicio, sin que la base lo compruebe. «NoSQL no significa sin esquema»: significa que el esquema
no lo valida el motor, así que lo valida tu código o no lo valida nadie, como enseñó la suma de los
anulados.

---

## ⚠️ Errores frecuentes

| Se dice | Lo preciso |
|---|---|
| "MongoDB no tiene esquema" | Tiene el que imponga cada servicio; la base no lo comprueba salvo validación declarada |
| "Un documento es más rápido de leer que un `JOIN`" | Con datos en memoria los dos van por debajo del milisegundo; el documento gana en localidad y en escritura atómica |
| "Si el tipo está mal, MongoDB dará error" | Aceptó un total como texto, y `$sum` lo ignoró sin avisar |
| "El documento ocupa menos que las filas" | Sin comprimir ocupa más, porque repite los nombres; en disco, menos, por la compresión |
| "Documental significa sin SQL" | Couchbase consulta documentos con SQL++, y PostgreSQL guarda documentos en `jsonb` |
| "`Object.bsonsize` da el tamaño del documento" | Era del *shell* antiguo; en `mongosh` es `bsonsize` |
| "Todos los documentales se parecen" | CouchDB se define por la replicación y los conflictos; Firestore, por el tiempo real y el cobro por lectura |

---

## 📚 Para profundizar

- **Documentación** — MongoDB 8.0, «Documents»: el documento, el `_id` y los límites.
  <https://www.mongodb.com/docs/v8.0/core/document/>
- **Documentación** — MongoDB 8.0, «BSON Types»: `Decimal128`, `Date` y los demás.
  <https://www.mongodb.com/docs/v8.0/reference/bson-types/>
- **Documentación** — MongoDB 8.0, «$sum»: la suma que ignora lo que no es número.
  <https://www.mongodb.com/docs/v8.0/reference/operator/aggregation/sum/>
- **Documentación** — MongoDB 8.0, «WiredTiger Storage Engine»: la compresión por defecto.
  <https://www.mongodb.com/docs/v8.0/core/wiredtiger/>
- **Documentación** — Couchbase Server 8.0, «SQL++ for Query Reference».
  <https://docs.couchbase.com/server/8.0/n1ql/n1ql-language-reference/index.html>
- **Documentación** — Apache CouchDB, «Replication and conflict model».
  <https://docs.couchdb.org/en/stable/replication/conflicts.html>
- **Documentación** — Firebase, «Get realtime updates with Cloud Firestore».
  <https://firebase.google.com/docs/firestore/query-data/listen>
- **Documentación** — Firebase, «Understand Cloud Firestore billing».
  <https://firebase.google.com/docs/firestore/pricing>

---

## 🧠 Preguntas

1. ¿Qué es un documento en MongoDB, y qué es BSON? 🟢
2. ¿Qué es una colección, y qué papel tiene el `_id`? 🟢
3. ¿Qué hace `$sum` con un valor que no es número? 🟢
4. Distingue documento y fila: dónde viven las partes de una entidad en cada modelo. 🟡
5. Distingue el tamaño de un documento sin comprimir y en disco, y di por qué difieren. 🟡
6. ¿Existe un estándar del modelo documental como ISO/IEC 9075? ¿Qué parte de JSON sí está en el
   estándar SQL? 🟡
7. ¿Quién comprueba el tipo de un campo en PostgreSQL y quién en MongoDB sin validación? 🟡
8. ¿Qué distingue a Couchbase, a CouchDB y a Firestore de MongoDB, cada uno en una frase? 🟡
9. Un compañero dice que el documento es más rápido que el `JOIN`. Matiza con lo medido. 🟠
10. ¿Por qué la suma de los anulados bajó 5 971,28 sin ningún error, y cómo lo habrías detectado? 🟠
11. ¿Por qué el esquema flexible es a la vez una ventaja y un riesgo? Da un ejemplo de cada uno en
    la tienda. 🟠
12. ¿Por qué el cobro por documento leído de Firestore cambia el diseño del esquema? 🟠
13. ¿Por qué CouchDB trata el conflicto como un estado normal, y qué obliga eso a hacer a la
    aplicación? 🟠
14. ¿Qué cuesta en espacio repetir el nombre de cada campo en cada documento, y qué lo compensa en
    disco? 🟠
15. Diseña cómo evitarías que un servicio guarde totales como texto en `tienda.pedidos`, y dónde lo
    comprobarías. 🔴
16. Diagnostica: el informe mensual de ventas sacado de MongoDB da un 0,3 % menos que el de
    contabilidad, sin errores en ningún registro. Da tres hipótesis en orden de probabilidad y la
    consulta que harías para cada una. 🔴
17. Defiende si la ficha del pedido de la tienda justifica pasar a MongoDB, con los números del
    capítulo y lo que se perdería. 🔴

---

**Anterior:** [README del bloque](README.md) · **Siguiente:**
[`02`](02-mongodb-consulta-y-agregacion.md) — consulta y agregación · **Relacionado:**
[`l04`](../13-laboratorio/l04-redis-y-mongodb.md) §6 — la agregación frente al `GROUP BY`, en un lab
· [`07/01`](../07-clave-valor/01-el-modelo-clave-valor.md) §5 — la ficha del modelo clave-valor,
para comparar.
