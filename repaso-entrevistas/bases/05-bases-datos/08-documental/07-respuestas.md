# 07 — Respuestas

> Solucionario del bloque: el enunciado copiado literalmente de su capítulo y la respuesta en tres
> capas.
>
> **Cómo se usa.** Responde primero en voz alta, con el cronómetro. La capa ⏱️ es lo que dices en
> los primeros treinta segundos; la 🗣️ es lo que añades cuando te dicen "cuéntame más"; la 🔬 es el
> matiz que casi nadie trae, y es donde vive la distinción entre **lo que manda el estándar, lo que
> hace cada motor y lo que es pura convención**.
>
> **Vigencia:** 27 de septiembre de 2026.

---

## Salto rápido

- [Capítulo 01 — El modelo documental](#capítulo-01--el-modelo-documental)
- [Capítulo 02 — MongoDB: consulta y agregación](#capítulo-02--mongodb-consulta-y-agregación)
- [Capítulo 03 — Incrustar frente a referenciar](#capítulo-03--incrustar-frente-a-referenciar)
- [Capítulo 04 — Índices, transacciones y
  consistencia](#capítulo-04--índices-transacciones-y-consistencia)
- [Capítulo 05 — Documental, relacional o jsonb](#capítulo-05--documental-relacional-o-jsonb)
- [Simulación de entrevista](#simulación-de-entrevista)

---

## Capítulo 01 — El modelo documental

Las 17 preguntas de [`01`](01-el-modelo-documental.md).

**01 → 1.** ¿Qué es un documento en MongoDB, y qué es BSON? 🟢

⏱️ **30 segundos** — Un registro con estructura —campos, listas y subdocumentos— que el motor guarda
y lee como una unidad. BSON es el formato binario en que lo guarda: JSON con más tipos, como
`Decimal128` y fechas.

🗣️ **2 minutos** — `PED-00042` es un documento de 379 bytes con sus tres líneas dentro. Sin BSON, el
total viajaría como coma flotante y la fecha como texto, las dos trampas del bloque 10.

🔬 **El detalle** — **Motor**: BSON es de MongoDB. `bsonsize` da el tamaño en `mongosh`; la
`Object.bsonsize` de los tutoriales antiguos era del *shell* anterior.

---

**01 → 2.** ¿Qué es una colección, y qué papel tiene el `_id`? 🟢

⏱️ **30 segundos** — Una colección agrupa documentos, como una tabla agrupa filas, pero sin esquema
que el motor compruebe. El `_id` es la clave primaria de cada documento, única y con índice
automático.

🗣️ **2 minutos** — Leer `PED-00042` por su `_id` fue un `EXPRESS_IXSCAN` que examinó un documento.
En la tienda, el `_id` es el código canónico, `PED-00042`, así que el pedido se busca por lo que el
negocio ya conoce.

🔬 **El detalle** — **Motor**. Si no se da `_id`, MongoDB genera un `ObjectId`, que lleva la marca de
tiempo de creación dentro.

---

**01 → 3.** ¿Qué hace `$sum` con un valor que no es número? 🟢

⏱️ **30 segundos** — Lo ignora, sin error ni aviso. Lo dice la primera línea de su documentación.

🗣️ **2 minutos** — Con el total de `PED-99999` guardado como texto, la suma de los anulados bajó
5 971,28 y siguió contando 5 960 pedidos. El informe queda mal y nadie se entera.

🔬 **El detalle** — **Motor**. En PostgreSQL no llega a pasar: el tipo de la columna rechaza el
valor al escribirlo.

---

**01 → 4.** Distingue documento y fila: dónde viven las partes de una entidad en cada modelo. 🟡

⏱️ **30 segundos** — En relacional, las partes viven en otras tablas con una clave foránea, y se
reúnen con un `JOIN` al leer. En un documento, viven dentro, como listas y subdocumentos.

🗣️ **2 minutos** — El pedido con sus líneas es un documento en MongoDB y dos tablas en PostgreSQL:
`pedidos` y `pedido_lineas`, más `productos` para el código. Uno se lee de un sitio; el otro se
reúne de tres.

🔬 **El detalle** — **Estándar** la fila y la clave foránea, en ISO/IEC 9075; **motor** el documento.
La consecuencia práctica es la localidad: el documento lee junto lo que el `JOIN` reúne.

---

**01 → 5.** Distingue el tamaño de un documento sin comprimir y en disco, y di por qué difieren. 🟡

⏱️ **30 segundos** — Sin comprimir, los pedidos ocupan 42 MB de BSON; en disco, 10,5 MB, porque
WiredTiger comprime los bloques con snappy por defecto.

🗣️ **2 minutos** — Sin comprimir ocupan más que en PostgreSQL —31 MB—, porque cada documento repite
los nombres de sus campos. En disco ocupan menos, por la compresión. En memoria vuelven a ser BSON
sin comprimir.

🔬 **El detalle** — **Motor**. PostgreSQL solo comprime valores grandes, con TOAST; las filas
pequeñas no.

---

**01 → 6.** ¿Existe un estándar del modelo documental como ISO/IEC 9075? ¿Qué parte de JSON sí está
en el estándar SQL? 🟡

⏱️ **30 segundos** — No hay estándar del modelo documental. El estándar SQL sí tiene una parte para
JSON, SQL/JSON: un modelo de datos, un lenguaje de rutas y funciones de consulta como `JSON_TABLE`.

🗣️ **2 minutos** — PostgreSQL dice en su documentación que implementa ese modelo, y marca qué partes
son extensiones suyas. MongoDB no sigue ninguna norma: su lenguaje es propio.

🔬 **El detalle** — **Estándar** SQL/JSON, sin haber verificado la cláusula exacta; **motor** todo lo
de MongoDB. Es materia de `05`.

---

**01 → 7.** ¿Quién comprueba el tipo de un campo en PostgreSQL y quién en MongoDB sin validación? 🟡

⏱️ **30 segundos** — En PostgreSQL, la base, con el tipo de la columna. En MongoDB sin validación,
nadie salvo el código de cada servicio que escribe.

🗣️ **2 minutos** — PostgreSQL rechazó `'cinco mil'` para `total` con un error de sintaxis del tipo
`numeric`. MongoDB aceptó el total como texto con `modifiedCount: 1`.

🔬 **El detalle** — MongoDB tiene validación con `$jsonSchema`, pero hay que declararla. «NoSQL no
significa sin esquema: significa que el esquema no lo valida el motor».

---

**01 → 8.** ¿Qué distingue a Couchbase, a CouchDB y a Firestore de MongoDB, cada uno en una frase? 🟡

⏱️ **30 segundos** — Couchbase consulta con SQL++, antes N1QL. CouchDB se define por la replicación
entre copias y los conflictos. Firestore, por la escucha en tiempo real y el cobro por documento
leído.

🗣️ **2 minutos** — Couchbase rompe el mito de que documental es sin SQL. CouchDB resuelve el caso
sin conexión, con PouchDB en el navegador. Firestore hace que la factura dependa de cuántos
documentos lee cada pantalla.

🔬 **El detalle** — **Motor** los tres, según su documentación. Ninguno está en el entorno del
corpus.

---

**01 → 9.** Un compañero dice que el documento es más rápido que el `JOIN`. Matiza con lo medido. 🟠

⏱️ **30 segundos** — Con los datos en memoria, los dos van por debajo del milisegundo: 0,115 ms el
`JOIN` de PostgreSQL, un documento por índice en MongoDB. El documento gana en localidad y en
escribir el agregado de una vez, no en velocidad.

🗣️ **2 minutos** — PostgreSQL leyó 17 páginas con cinco búsquedas por índice; MongoDB, un documento.
La diferencia pesa con datos fríos en disco o con escrituras frecuentes del agregado entero.

🔬 **El detalle** — Y el documento pierde en cuanto la pregunta es sobre sus partes: el top de
productos tardó 214 ms en MongoDB frente a 81 en PostgreSQL.

---

**01 → 10.** ¿Por qué la suma de los anulados bajó 5 971,28 sin ningún error, y cómo lo habrías
detectado? 🟠

⏱️ **30 segundos** — Porque el total de `PED-99999` quedó como texto y `$sum` ignora lo que no es
número. Lo habría detectado con `{total: {$type: "string"}}`, o cuadrando el informe con la fuente.

🗣️ **2 minutos** — El recuento seguía en 5 960, así que solo cuadrando importes se ve. La defensa de
verdad es no dejar entrar el dato: validación en la colección o en la capa de escritura.

🔬 **El detalle** — **Motor** el comportamiento de `$sum`. Es el caso que explica por qué el esquema
flexible necesita validación.

---

**01 → 11.** ¿Por qué el esquema flexible es a la vez una ventaja y un riesgo? Da un ejemplo de cada
uno en la tienda. 🟠

⏱️ **30 segundos** — Ventaja: se añade un campo sin migración, como el `cliente_pais` de `03`.
Riesgo: entra cualquier cosa, como el total en texto que la suma ignoró.

🗣️ **2 minutos** — La flexibilidad sirve para atributos que varían de verdad entre documentos. Sin
validación, cada servicio escribe su versión del esquema y la base no lo nota.

🔬 **El detalle** — En PostgreSQL, añadir una columna que admite nulos es inmediato, así que la
ventaja real no es la migración: es la variedad de formas.

---

**01 → 12.** ¿Por qué el cobro por documento leído de Firestore cambia el diseño del esquema? 🟠

⏱️ **30 segundos** — Porque cada documento leído se cobra: una pantalla que lee cien documentos
cuesta cien veces más que una que lee uno, así que el esquema se desnormaliza para leer menos.

🗣️ **2 minutos** — La documentación cobra documentos leídos, escritos y borrados, y entradas de
índice leídas. El diseño busca que cada pantalla lea el mínimo, aunque duplique datos.

🔬 **El detalle** — **Motor y modelo de negocio**. Es un caso donde la factura, y no el rendimiento,
decide el esquema.

---

**01 → 13.** ¿Por qué CouchDB trata el conflicto como un estado normal, y qué obliga eso a hacer a
la aplicación? 🟠

⏱️ **30 segundos** — Porque replica copias que se editan por separado, incluso sin conexión, y dos
ediciones del mismo documento son esperables. Elige un ganador determinista y guarda los demás en
`_conflicts`; la aplicación decide cómo fusionarlos.

🗣️ **2 minutos** — El ganador es el mismo en todas las copias, pero no es «el bueno»: es el que dice
el algoritmo. La aplicación tiene que leer los conflictos y resolverlos.

🔬 **El detalle** — **Motor**, según su documentación. Es el precio del caso *offline-first*.

---

**01 → 14.** ¿Qué cuesta en espacio repetir el nombre de cada campo en cada documento, y qué lo
compensa en disco? 🟠

⏱️ **30 segundos** — Sin comprimir, los pedidos ocupan 42 MB frente a 31 de PostgreSQL, en parte por
repetir los nombres. La compresión de WiredTiger lo compensa en disco: 10,5 MB.

🗣️ **2 minutos** — En memoria, al leerlo, vuelve a ser BSON sin comprimir, así que la caché del
servidor sí paga los nombres repetidos. Nombres de campo cortos reducen el coste.

🔬 **El detalle** — **Motor**. PostgreSQL guarda los nombres una vez, en el catálogo.

---

**01 → 15.** Diseña cómo evitarías que un servicio guarde totales como texto en `tienda.pedidos`, y
dónde lo comprobarías. 🔴

⏱️ **30 segundos** — Con validación en la colección, un `$jsonSchema` que exija `total` de tipo
decimal, para que la base rechace la escritura. Y en la capa de acceso del servicio, un tipo que no
admita texto.

🗣️ **2 minutos** — La validación de la colección es la única que protege de todos los servicios a la
vez. Antes de activarla, una búsqueda con `$type` encuentra los documentos que ya no cumplen.

🔬 **El detalle** — El detalle de la validación y su coste es de `05`. Validar solo en el código deja
fuera al siguiente servicio que escriba.

---

**01 → 16.** Diagnostica: el informe mensual de ventas sacado de MongoDB da un 0,3 % menos que el de
contabilidad, sin errores en ningún registro. Da tres hipótesis en orden de probabilidad y la
consulta que harías para cada una. 🔴

⏱️ **30 segundos** — Primera, totales guardados con otro tipo que `$sum` ignora: se buscan con
`$type` y el tipo `string`. Segunda, importes guardados como coma flotante y sumados con error:
`$type` con `double`. Tercera, documentos que no entraron en el filtro por un estado o una fecha mal
escritos.

🗣️ **2 minutos** — Para la tercera, contar por estado y por mes y comparar con la fuente. Un 0,3 %
con cero errores es la firma de datos que la agregación descarta en silencio.

🔬 **El detalle** — La primera es la que se vio con `PED-99999`. Todas se cierran con validación en
la escritura.

---

**01 → 17.** Defiende si la ficha del pedido de la tienda justifica pasar a MongoDB, con los números
del capítulo y lo que se perdería. 🔴

⏱️ **30 segundos** — No por velocidad: la ficha tarda 0,115 ms en PostgreSQL. Se ganaría localidad y
escribir el pedido de una vez; se perdería el tipado que rechazó el total en texto, y las consultas
sobre las líneas, que tardaron el triple.

🗣️ **2 minutos** — Si el resto de la aplicación sigue siendo relacional, dos motores es más
operación y datos que cuadrar. `jsonb` en PostgreSQL da la ficha como documento sin salir de la
base, que es la tercera vía de `05`.

🔬 **El detalle** — La respuesta cambia si el pedido tuviera atributos muy variables o si la escala
de escritura no cupiera en una instancia; con los números de la tienda, no.

---

## Capítulo 02 — MongoDB: consulta y agregación

Las 17 preguntas de [`02`](02-mongodb-consulta-y-agregacion.md).

**02 → 1.** ¿Qué son el filtro y la proyección de `find`, y a qué partes de un `SELECT` equivalen? 🟢

⏱️ **30 segundos** — El filtro es un documento con las condiciones, el `WHERE`; la proyección dice
qué campos devolver, la lista del `SELECT`.

🗣️ **2 minutos** — El `find` de los pedidos de `CLI-00311` con proyección de estado, total y fecha
es un `SELECT` de esas tres columnas con su `WHERE`. `sort` y `limit` son el `ORDER BY` y el
`LIMIT`.

🔬 **El detalle** — **Motor**. Varias condiciones en el filtro se combinan con «y», salvo sobre
listas, donde está la trampa de `$elemMatch`.

---

**02 → 2.** ¿Qué hace `$unwind`? 🟢

⏱️ **30 segundos** — Despliega una lista: convierte cada documento en tantos como elementos tenga la
lista, uno por elemento.

🗣️ **2 minutos** — De 99 999 pedidos salieron 349 999 documentos, uno por línea, las mismas filas
que `pedido_lineas`. Es el paso previo para agrupar por algo que está dentro de la lista.

🔬 **El detalle** — **Motor**. Es el precio de incrustar: para contar las partes, hay que sacarlas.

---

**02 → 3.** ¿Qué hace `$elemMatch`? 🟢

⏱️ **30 segundos** — Exige que un mismo elemento de la lista cumpla todas las condiciones.

🗣️ **2 minutos** — Con `$elemMatch`, los pedidos con una línea de `PRD-00017` de cinco o más
unidades fueron 599, como en PostgreSQL. Sin él, 1 028.

🔬 **El detalle** — **Motor**, según su documentación. Con una sola condición sobre la lista no hace
falta.

---

**02 → 4.** ¿Cuándo sale el `_id` en el resultado de una consulta? 🟢

⏱️ **30 segundos** — Siempre, salvo que la proyección diga `_id: 0`.

🗣️ **2 minutos** — Por eso las proyecciones del capítulo devuelven el `_id` aunque no se pida.

🔬 **El detalle** — **Motor**. Es la única excepción a «solo los campos que pides».

---

**02 → 5.** Distingue el operador posicional `$` del filtrado `$[l]` con `arrayFilters`. ¿Lo fija el
estándar o es cosa del motor? 🟡

⏱️ **30 segundos** — `$` cambia el primer elemento que encajó en el filtro de la consulta. `$[l]`
con `arrayFilters` cambia todos los elementos que cumplan el filtro con nombre `l`.

🗣️ **2 minutos** — Los dos subieron o bajaron la cantidad de `PRD-00872` en `PED-00042`. Si un
pedido tuviera dos líneas del mismo producto, `$` tocaría una y `$[l]` las dos.

🔬 **El detalle** — **Motor**. Existe también `$[]`, que toca todos los elementos sin filtro.

---

**02 → 6.** Distingue la atomicidad de un `updateOne` en MongoDB de la de una transacción en
PostgreSQL. 🟡

⏱️ **30 segundos** — `updateOne` es atómico sobre un documento, y nada más. Una transacción de
PostgreSQL es atómica sobre todas las filas y tablas que toque.

🗣️ **2 minutos** — Cambiar una línea y el total del mismo pedido es atómico en los dos, porque en
MongoDB son el mismo documento. Cambiar dos documentos a la vez necesita una transacción de MongoDB,
que es de `04`.

🔬 **El detalle** — **Motor**; la documentación dice que una operación sobre un solo documento es
atómica.

---

**02 → 7.** Distingue `$lookup` de un `JOIN` de PostgreSQL: cómo se ejecuta cada uno. 🟡

⏱️ **30 segundos** — `$lookup` busca, para cada documento que llega, sus coincidencias en la otra
colección: una búsqueda por documento. El `JOIN` lo planifica el motor, que puede elegir un *hash
join* que lee cada tabla una vez.

🗣️ **2 minutos** — Para las ventas por país: 472 ms con `$lookup`, 24 910 búsquedas por `_id`; 28 ms
con el *hash join* de PostgreSQL, con un `Seq Scan` sobre `clientes`.

🔬 **El detalle** — **Motor** los dos. No hay planificador que elija la forma de unir en `$lookup`.

---

**02 → 8.** ¿El lenguaje de consulta de MongoDB sigue algún estándar como ISO/IEC 9075? ¿Y el límite
de 100 MB por etapa, lo fija alguna norma? 🟡

⏱️ **30 segundos** — No: el lenguaje es propio. Y los 100 MB por etapa son del motor, no de ninguna
norma.

🗣️ **2 minutos** — Desde la 6.0, `allowDiskUseByDefault` decide si una etapa que pasa de 100 MB
escribe a disco. PostgreSQL tiene su propio límite, `work_mem`.

🔬 **El detalle** — **Motor** los dos límites; ninguno está en el estándar SQL.

---

**02 → 9.** ¿Por qué `{"lineas.producto": "PRD-00017", "lineas.cantidad": {$gte: 5}}` contó 1 028
pedidos y no 599? 🟠

⏱️ **30 segundos** — Porque cada condición se cumplió con cualquier línea, por separado: un pedido
con `PRD-00017` en una línea y cinco unidades en otra cuenta.

🗣️ **2 minutos** — Sobran 429 pedidos. `$elemMatch` exige la misma línea y da 599, como el `JOIN` de
PostgreSQL con la fila de `pedido_lineas`.

🔬 **El detalle** — **Motor**. Es el error más caro de traducir un `WHERE` a MongoDB, porque no da
error.

---

**02 → 10.** ¿Por qué el total de `PED-00042` no cambió al subir la cantidad de una línea, y cómo lo
harías en la misma operación? 🟠

⏱️ **30 segundos** — Porque el documento no sabe que el total depende de las líneas. Se hace con un
segundo `$inc` sobre `total` en el mismo `updateOne`.

🗣️ **2 minutos** — `{$inc: {"lineas.$.cantidad": 1, total: Decimal128("27.03")}}` llevó el total a
3 213,26 con la línea en 6; la orden inversa lo devolvió a 3 186,23.

🔬 **El detalle** — Es la columna desnormalizada `pedidos.total` de PostgreSQL con otro mecanismo:
aquí van juntas porque son el mismo documento.

---

**02 → 11.** ¿Por qué el top de productos tardó 214 ms en MongoDB y 81 en PostgreSQL con el mismo
resultado? 🟠

⏱️ **30 segundos** — Porque las líneas están dentro de los pedidos, y MongoDB tuvo que abrir los 99
999 pedidos y desplegarlos en 349 999 documentos antes de agrupar. PostgreSQL leyó `pedido_lineas`,
que ya es una fila por línea.

🗣️ **2 minutos** — En tres corridas, de 212 a 272 ms frente a 80 y 81. El resultado fue idéntico,
unidad a unidad.

🔬 **El detalle** — Es el precio de incrustar: lo que está dentro se consulta peor por su cuenta.

---

**02 → 12.** ¿Por qué el `$lookup` a clientes tardó 472 ms y el `JOIN` 28? ¿Qué pasaría si
`foreignField` no tuviera índice? 🟠

⏱️ **30 segundos** — Porque `$lookup` hizo una búsqueda por cada uno de los 24 910 pedidos pagados,
y PostgreSQL un *hash join* que lee cada tabla una vez. Sin índice en `foreignField`, cada búsqueda
recorrería la colección de clientes entera.

🗣️ **2 minutos** — En tres corridas, de 459 a 498 ms frente a 27. El `_id` de `clientes` está
indexado por defecto; con otro campo sin índice, serían 24 910 recorridos de 50 000 documentos.

🔬 **El detalle** — La salida de `03` fue copiar el país en el pedido: 38 ms sin `$lookup`.

---

**02 → 13.** ¿Por qué comparar `total` con `Decimal128("5000")` funciona y con `"5000"` no
encontraría nada? 🟠

⏱️ **30 segundos** — Porque los operadores de comparación de MongoDB solo comparan cuando el tipo
del campo coincide con el del valor: es el *type bracketing* de su documentación. Con un texto, solo
compararía contra totales guardados como texto.

🗣️ **2 minutos** — Con `Decimal128("5000")`, 24 901 pedidos, lo mismo que PostgreSQL; con `"5000"`,
corrido, 0. Todos los tipos numéricos cuentan como equivalentes entre sí, así que un entero también
serviría.

🔬 **El detalle** — **Motor**. En PostgreSQL, `'5000'` se convertiría a `numeric` porque la columna
tiene tipo.

---

**02 → 14.** Escribe el *pipeline* que da, para `CLI-00311`, el número de pedidos por estado y el
importe de cada estado, ordenado por importe. 🔴

⏱️ **30 segundos** — Filtrar por cliente, agrupar por estado sumando pedidos e importe, y ordenar:

```js
[{$match: {cliente: "CLI-00311"}},
 {$group: {_id: "$estado", pedidos: {$sum: 1}, importe: {$sum: "$total"}}},
 {$sort: {importe: -1}}]
```

🗣️ **2 minutos** — Corrido sobre los pedidos hasta `PED-99999`: cuatro `ENTREGADO` por 22 805,81, y
un `ANULADO`, un `PAGADO` y un `ENVIADO`. El `$match` va primero para que el resto trabaje sobre
siete documentos y no sobre 99 999.

🔬 **El detalle** — Con un índice en `cliente`, el `$match` no recorrería la colección; sin él, es un
`COLLSCAN` como en `l04`.

---

**02 → 15.** Escribe la actualización que suma una unidad a la línea de `PRD-00872` de `PED-00042` y
suma a la vez su precio al total, en una sola orden. 🔴

⏱️ **30 segundos** — Un `updateOne` con dos `$inc`, el de la línea con el operador posicional y el
del total:

```js
db.pedidos.updateOne({_id: "PED-00042", "lineas.producto": "PRD-00872"},
                     {$inc: {"lineas.$.cantidad": 1, total: Decimal128("27.03")}})
```

🗣️ **2 minutos** — Corrida: la línea pasó a 6 y el total a 3 213,26, en una operación atómica. La
inversa, con `-1` y `-27.03`, lo devolvió a su estado.

🔬 **El detalle** — El precio va escrito porque se leyó antes de la línea. Con una actualización por
*pipeline*, se podría calcular dentro de la orden.

---

**02 → 16.** Diagnostica: un informe de MongoDB de «pedidos con PRD-00017 en cantidad de cinco o
más» da un 70 % más que el de PostgreSQL. Da la causa y la corrección, y cómo comprobarías que ya
cuadran. 🔴

⏱️ **30 segundos** — Las dos condiciones sobre `lineas` sin `$elemMatch` se cumplen en líneas
distintas. La corrección es `$elemMatch`. Se comprueba contando en los dos motores: 599 y 599.

🗣️ **2 minutos** — 1 028 frente a 599 es un 72 % más, exactamente el síntoma. Para cuadrar a futuro,
una prueba que compare los dos recuentos sobre los mismos datos.

🔬 **El detalle** — **Motor**. Lo delata que no haya ningún error: el informe es sintácticamente
correcto.

---

**02 → 17.** El panel de ventas por país, escrito con `$lookup`, tarda medio segundo y se pide cien
veces por minuto. Da tres formas de arreglarlo con lo que cuesta cada una. 🔴

⏱️ **30 segundos** — Copiar el país en cada pedido, la referencia extendida: 38 ms, pagando una
escritura por pedido cuando el cliente cambia. Precalcular el panel cada minuto en una colección de
resumen. O guardar el resultado en caché con caducidad corta.

🗣️ **2 minutos** — La copia se hizo una vez en 3,5 s con `$merge`. El resumen cuesta un proceso
programado y un minuto de retraso. La caché, el riesgo de dato viejo de `07/04`.

🔬 **El detalle** — Si el panel es de informe, también cabe sacarlo de PostgreSQL, donde el `JOIN`
tardó 28 ms.

---

## Capítulo 03 — Incrustar frente a referenciar

Las 16 preguntas de [`03`](03-incrustar-frente-a-referenciar.md).

**03 → 1.** ¿Qué es incrustar y qué es referenciar, en una frase cada uno? 🟢

⏱️ **30 segundos** — Incrustar es poner la parte dentro del documento de su entidad; referenciar es
guardarla en otra colección y apuntarla por su `_id`.

🗣️ **2 minutos** — Las líneas están incrustadas en el pedido; el cliente está referenciado desde el
pedido con `cliente: "CLI-26446"`.

🔬 **El detalle** — **Convención**: el motor admite las dos formas.

---

**03 → 2.** ¿Cuál es el tamaño máximo de un documento en MongoDB? 🟢

⏱️ **30 segundos** — 16 mebibytes: 16 777 216 bytes.

🗣️ **2 minutos** — Un documento de 16 777 266 bytes se rechazó con `object to insert too large`.

🔬 **El detalle** — **Motor**; la documentación dice que existe para que un documento no use
demasiada memoria ni ancho de banda.

---

**03 → 3.** ¿Qué es el patrón *bucket*? 🟢

⏱️ **30 segundos** — Agrupar una serie larga de elementos pequeños en documentos que contienen
muchos, por un criterio natural como la hora.

🗣️ **2 minutos** — Los 409 998 eventos pasaron a 24 002 cubos de una hora, con la hora como `_id`.

🔬 **El detalle** — **Convención**, recogida por MongoDB; las colecciones de series temporales lo
aplican solas.

---

**03 → 4.** Distingue la referencia extendida de una referencia simple. ¿Qué parte es del motor y
qué parte es convención? 🟡

⏱️ **30 segundos** — La simple guarda solo el `_id` del otro documento. La extendida guarda además
una copia de los campos que se leen a menudo, para no ir a buscarlos.

🗣️ **2 minutos** — El pedido guardaba `cliente`; con la extendida, también `cliente_pais`, y el
panel por país pasó de 472 a 38 ms.

🔬 **El detalle** — **Convención**. El precio es mantener las copias cuando el original cambia.

---

**03 → 5.** Distingue el patrón *bucket* del patrón *outlier*: qué problema resuelve cada uno. 🟡

⏱️ **30 segundos** — El *bucket* agrupa muchos elementos pequeños en pocos documentos. El *outlier*
aísla los pocos documentos que se salen de la forma común, para que no paguen los demás.

🗣️ **2 minutos** — El *bucket* sirvió para los eventos por hora. El *outlier* serviría para un
mayorista con doscientos mil pedidos entre clientes de veinte; en la tienda no hace falta.

🔬 **El detalle** — **Convención** los dos, según la guía de patrones de MongoDB.

---

**03 → 6.** ¿El límite de 16 MiB es del estándar, del formato BSON o del motor? ¿Tiene PostgreSQL
uno parecido? 🟡

⏱️ **30 segundos** — Es del motor: lo fija MongoDB para un documento BSON. PostgreSQL tiene un
máximo de 1 GB por campo.

🗣️ **2 minutos** — No hay estándar que lo fije. En PostgreSQL, los valores grandes se guardan fuera
de la fila con TOAST.

🔬 **El detalle** — **Motor** los dos límites, según su documentación.

---

**03 → 7.** ¿Por qué las líneas se incrustan en el pedido y los pedidos no se incrustan en el
cliente? 🟡

⏱️ **30 segundos** — Porque las líneas se leen siempre con el pedido y tienen tope —de 3,5 de media
a 6 como mucho—. Los pedidos crecen con cada compra y cada uno se consulta solo.

🗣️ **2 minutos** — El cliente con más pedidos tiene 52 y nada lo detiene. Es una lista sin límite,
que la documentación pone como antipatrón.

🔬 **El detalle** — El tope se mide en los datos, no se supone.

---

**03 → 8.** ¿Por qué el `$push` de 200 bytes falló si los anteriores funcionaban? 🟠

⏱️ **30 segundos** — Porque el documento ya estaba cien bytes por debajo del límite, y 200 más lo
pasaban: `Resulting document after update is larger than 16777216`.

🗣️ **2 minutos** — Es como falla una lista sin límite: con un `$push` idéntico a los anteriores, sin
aviso previo y sin cambio de código.

🔬 **El detalle** — **Motor**. Mucho antes de fallar, un documento grande ya es caro de leer y de
reescribir.

---

**03 → 9.** ¿Qué cuesta la referencia extendida del país del cliente, y cuándo no la usarías? 🟠

⏱️ **30 segundos** — Cuesta espacio y una escritura en cada pedido cuando el cliente cambia de país:
siete para `CLI-00311`. No la usaría para campos que cambian a menudo, como un saldo.

🗣️ **2 minutos** — La copia inicial costó 3,5 s con `$merge`. Sin transacción, un lector puede ver
el cliente cambiado y los pedidos no, o al revés.

🔬 **El detalle** — La guía de MongoDB lo resume: la copia compensa si el dato cambia poco.

---

**03 → 10.** ¿Por qué el *bucket* redujo el índice de 8,99 MB a 0,37, y qué se paga a cambio? 🟠

⏱️ **30 segundos** — Porque hay 24 002 documentos en vez de 409 998, y la hora es el `_id`, así que
sobra el índice por fecha. Se paga en traer el cubo entero para leer un evento, y en reescribirlo en
cada `$push`.

🗣️ **2 minutos** — Leer una hora pasó de examinar 18 documentos a uno. En disco, de 10,2 MB a 8,3.

🔬 **El detalle** — Un cubo necesita un tope, con un contador como `n`, para no volver al problema de
los 16 MiB.

---

**03 → 11.** ¿Por qué la tienda no necesita el patrón *outlier*, y qué dato lo decide? 🟠

⏱️ **30 segundos** — Porque el cliente más activo tiene 52 pedidos y la mediana es 20: no hay cola
larga. Lo decide la distribución, con un percentil en la mano.

🗣️ **2 minutos** — Media 20, mediana 20, p99 31, máximo 52. El patrón hace falta cuando el máximo
está a miles de veces de la mediana.

🔬 **El detalle** — Y aun así, los pedidos no se incrustan en el cliente, porque crecen sin tope.

---

**03 → 12.** ¿Por qué hay que forzar un *checkpoint* antes de leer `storageSize` tras una carga, y
cómo se hace? 🟠

⏱️ **30 segundos** — Porque WiredTiger no refleja lo escrito en `storageSize` hasta el siguiente
*checkpoint*; justo después de importar, la cifra no es real. Se fuerza con
`db.adminCommand({fsync: 1})`.

🗣️ **2 minutos** — Medido sin forzarlo, dio cifras sin sentido; forzándolo, 8,3 MB los cubos y 10,2
los eventos sueltos.

🔬 **El detalle** — Tras un ciclo de escritura, `storageSize` subió a 10,5 MB y se quedó ahí; no se
comprobó por qué, y la comparación se hizo con colecciones recién cargadas.

---

**03 → 13.** Cambiar el país de `CLI-00311` tocó siete pedidos y su documento de cliente. ¿Qué puede
ver un lector entre las dos escrituras, y cómo lo evitarías? 🟠

⏱️ **30 segundos** — Puede ver el cliente con el país nuevo y sus pedidos con el viejo, o al revés,
porque son dos colecciones y cada escritura es atómica solo en su documento. Lo evitaría con una
transacción multidocumento.

🗣️ **2 minutos** — La transacción tiene coste, y la documentación dice que no sustituye a un buen
diseño. Si el informe admite un momento de desfase, se acepta y se documenta.

🔬 **El detalle** — Las transacciones y su coste son de `04`.

---

**03 → 14.** Diseña el documento de producto para guardar sus valoraciones, sabiendo que un producto
popular puede tener cientos de miles: qué incrustas, qué referencias y qué patrón usas. 🔴

⏱️ **30 segundos** — En el producto, la media y el número de valoraciones, y las diez más recientes.
Las valoraciones enteras, en su propia colección, referenciando el producto, o en cubos por
producto y mes.

🗣️ **2 minutos** — Cientos de miles de valoraciones dentro del producto chocarían con los 16 MiB. Lo
incrustado es un subconjunto con tope, que es lo que la documentación recomienda frente a la lista
sin límite.

🔬 **El detalle** — La media y el recuento son valores calculados que se actualizan con cada
valoración, con un `$inc` atómico.

---

**03 → 15.** Diagnostica: un servicio que añade el historial de estados de cada pedido dentro del
documento empieza a fallar con `Resulting document after update is larger than 16777216` en unos
pocos pedidos. Da la causa, cómo encontrarías los afectados y el rediseño. 🔴

⏱️ **30 segundos** — Una lista sin tope que ya llegó a 16 MiB en esos pedidos. Los encuentro con
`$bsonSize` en una agregación, ordenando por tamaño. El rediseño: el historial en su colección o en
cubos, con solo los últimos estados en el pedido.

🗣️ **2 minutos** — Si solo fallan unos pocos, son *outliers*: pedidos con un historial anómalo, que
merece mirar por qué. El resto seguirá creciendo hasta el mismo muro.

🔬 **El detalle** — **Motor** el límite. El fallo no avisa antes: el `$push` de ayer funcionó.

---

**03 → 16.** Decide, para cada relación de la tienda —pedido y pagos, cliente y direcciones,
producto y precio histórico—, si incrustar o referenciar, con el dato que necesitarías medir para
cada una. 🔴

⏱️ **30 segundos** — Pagos, incrustados en el pedido, si el número de pagos por pedido tiene un tope
pequeño. Direcciones, incrustadas en el cliente, si son pocas. Precio histórico, referenciado o en
cubos, porque crece sin tope.

🗣️ **2 minutos** — Para cada una mediría el máximo y el p99 por padre, si se lee siempre con él y si
se consulta sola. Los pagos, además, se buscan por referencia del proveedor, lo que pide un índice
sobre el campo incrustado.

🔬 **El detalle** — Es el método de `07/06` aplicado a documental: primero cómo se lee y cuánto
crece, después el esquema.

---

## Capítulo 04 — Índices, transacciones y consistencia

Las 18 preguntas de [`04`](04-indices-transacciones-y-consistencia.md).

**04 → 1.** ¿Qué es un índice multikey, y cuándo lo crea MongoDB? 🟢

⏱️ **30 segundos** — Un índice sobre un campo que contiene una lista, con una entrada por cada valor
distinto de la lista. MongoDB lo crea como multikey solo, al indexar un campo que tiene listas.

🗣️ **2 minutos** — El de `lineas.producto` pasó los pedidos con `PRD-00017` de un `COLLSCAN` de 74
ms a un `IXSCAN multikey` de 3 ms, con 2 589 claves para 2 589 pedidos.

🔬 **El detalle** — **Motor**, según su documentación: cada entrada apunta al mismo documento, así
que un documento puede tener varias.

---

**04 → 2.** ¿Qué dice la regla ESR? 🟢

⏱️ **30 segundos** — Que en un índice compuesto van primero los campos de igualdad, después los de
orden y al final los de rango.

🗣️ **2 minutos** — Así el índice entrega los documentos ya ordenados y no hace falta un `SORT` en
memoria: 16 claves frente a 11 859 con el rango antes que el orden.

🔬 **El detalle** — **Convención** de la documentación, con su excepción: si el rango es muy
selectivo, puede ir antes del orden.

---

**04 → 3.** ¿Qué es una consulta cubierta, y qué etapa la delata en el plan? 🟢

⏱️ **30 segundos** — Una consulta que se responde solo con el índice, sin leer documentos. La delata
`PROJECTION_COVERED`, con cero documentos examinados.

🗣️ **2 minutos** — Pedir solo `estado` y `creado_en`, que estaban en el índice `esr`, y quitar el
`_id` con `_id: 0`: diez claves y cero documentos.

🔬 **El detalle** — Es el *index-only scan* de PostgreSQL. Si la proyección pide el `_id` y no está
en el índice, deja de ser cubierta.

---

**04 → 4.** ¿Qué es `writeConcern`, y cuál es su valor por defecto? 🟢

⏱️ **30 segundos** — Cuántos miembros del conjunto de réplicas confirman una escritura antes de que
MongoDB responda. Por defecto, `majority`.

🗣️ **2 minutos** — `w: 1` responde cuando escribe el primario; `w: "majority"`, cuando la mayoría la
tiene. Con `wtimeout`, deja de esperar pasado ese tiempo.

🔬 **El detalle** — **Motor**, según su documentación. Sin `wtimeout` y con la mayoría inalcanzable,
la escritura espera indefinidamente.

---

**04 → 5.** Distingue `readPreference` de `readConcern`. ¿Lo fija el estándar o es cosa del motor? 🟡

⏱️ **30 segundos** — `readPreference` dice de qué miembro se lee: primario, secundario, el más
cercano. `readConcern` dice qué garantía tiene lo leído: lo último del nodo o lo que confirmó la
mayoría.

🗣️ **2 minutos** — Con los secundarios bloqueados, `readPref("secondary")` devolvió `PAGADO` porque
ese nodo iba atrasado; `readConcern("majority")` también, leyendo del primario, porque la mayoría no
tenía el cambio.

🔬 **El detalle** — **Motor** los dos. Se combinan: una lectura puede ser del secundario y con
`majority` a la vez.

---

**04 → 6.** Distingue `w: 1` de `w: "majority"`: qué garantiza cada uno y cuánto costó. 🟡

⏱️ **30 segundos** — `w: 1` garantiza que lo escribió el primario; `w: "majority"`, que lo tiene la
mayoría y no se perderá si cae el primario. Mil actualizaciones: 980 ms frente a 1 723.

🗣️ **2 minutos** — Un 75 % más con los tres nodos en la misma máquina. Con red de verdad, la
diferencia es la latencia hasta el segundo nodo.

🔬 **El detalle** — Con `w: 1`, una escritura confirmada puede perderse si el primario cae antes de
replicarla.

---

**04 → 7.** ¿Qué dice el estándar SQL sobre transacciones que MongoDB solo ofrece en un conjunto de
réplicas? ¿Y qué hace PostgreSQL? 🟡

⏱️ **30 segundos** — El estándar define la transacción como unidad de todo o nada sobre cualquier
número de filas. PostgreSQL la ofrece en cualquier servidor; MongoDB, solo en un conjunto de
réplicas o en `mongos`.

🗣️ **2 minutos** — En el servidor suelto del entorno, la transacción falló con el error de que los
números de transacción solo se permiten en un miembro de un conjunto de réplicas o en `mongos`.

🔬 **El detalle** — **Estándar** la transacción; **motor** la restricción de MongoDB, que la apoya en
el registro de operaciones de la réplica.

---

**04 → 8.** ¿Por qué el índice multikey de `lineas.producto` ocupa tres veces lo que el de `_id`? 🟡

⏱️ **30 segundos** — Porque tiene una entrada por línea, 349 999, y el de `_id` una por pedido, 99
999.

🗣️ **2 minutos** — 3,28 MB frente a 1,03 en la sesión y 1,27 tras un *checkpoint*. Cada `$push` a
`lineas` escribe también en él.

🔬 **El detalle** — **Motor**. El índice crece con la lista, no con los documentos.

---

**04 → 9.** Distingue lo que hace PostgreSQL y lo que hace MongoDB cuando dos transacciones escriben
el mismo registro a la vez. 🟡

⏱️ **30 segundos** — En PostgreSQL, la segunda espera el bloqueo de fila hasta que la primera
confirme. En MongoDB, la segunda falla al instante con `WriteConflict`.

🗣️ **2 minutos** — La sesión B falló en 0,02 s mientras A seguía abierta. El reintento es trabajo
del cliente, o de `withTransaction`.

🔬 **El detalle** — **Motor** los dos. En PostgreSQL con `REPEATABLE READ`, la segunda también acaba
fallando al confirmar la primera, con un error de serialización.

---

**04 → 10.** ¿Por qué el índice `ers` leyó 11 859 claves y el `esr` 16, con los mismos campos? 🟠

⏱️ **30 segundos** — Porque con el rango antes que el orden, el índice encuentra los pagados de 5
000 o más pero no los tiene ordenados por fecha: los lee todos y los ordena. Con el orden antes, los
recorre ordenados y para en el décimo.

🗣️ **2 minutos** — `ers` dio `FETCH <- SORT <- IXSCAN` en 10 ms; `esr`, `LIMIT <- FETCH <- IXSCAN`
en 1 ms. `hint` forzó cada índice para compararlos.

🔬 **El detalle** — Es la regla ESR medida. El `SORT` en memoria además tiene límite de memoria.

---

**04 → 11.** ¿Cuándo conviene poner el rango antes que el orden, según la propia documentación? 🟠

⏱️ **30 segundos** — Cuando el rango es muy selectivo: deja tan pocas claves que ordenarlas en
memoria cuesta menos que recorrer el orden descartando.

🗣️ **2 minutos** — Aquí el rango dejaba 11 859 claves, así que ESR ganó. Con un rango que dejara
diez, ERS no pagaría casi nada por el `SORT`.

🔬 **El detalle** — **Convención** de la documentación: ESR por defecto, ERS si el rango es muy
selectivo.

---

**04 → 12.** La escritura con `w: "majority"` devolvió error por tiempo de espera. ¿Se hizo? ¿Qué
pasa si el servicio la reintenta? 🟠

⏱️ **30 segundos** — Sí: el resultado dijo `n: 1` y `nModified: 1`, y al desbloquear los secundarios
todos tenían el cambio. Si se reintenta una operación no idempotente, se aplica dos veces.

🗣️ **2 minutos** — La documentación dice que vencido el `wtimeout` no se deshacen las modificaciones
hechas. Un `$set` repetido da lo mismo; un `$inc` o un `$push`, no.

🔬 **El detalle** — La corrección es hacer la escritura idempotente —con un identificador de
operación— o comprobar el estado antes de reintentar.

---

**04 → 13.** ¿Por qué `readConcern("majority")` devolvió `PAGADO` leyendo del primario, que tenía
`ENVIADO`? 🟠

⏱️ **30 segundos** — Porque `majority` devuelve lo que ha confirmado la mayoría, y con los
secundarios bloqueados solo el primario tenía `ENVIADO`.

🗣️ **2 minutos** — Es lo que garantiza: lo leído no se deshará aunque caiga el primario. Por eso no
enseña lo que aún podría deshacerse.

🔬 **El detalle** — **Motor**, según su documentación. Al desbloquear y confirmar la mayoría, la
misma lectura dio el valor nuevo.

---

**04 → 14.** ¿Qué cuesta una transacción frente a una escritura suelta con `majority`, con lo
medido, y cuándo merece la pena? 🟠

⏱️ **30 segundos** — 2,3 ms por operación frente a 1,7: un 35 % más. Merece la pena cuando varios
documentos tienen que cambiar juntos.

🗣️ **2 minutos** — Mil actualizaciones: 2 339 y 2 288 ms en transacción, 1 723 y 1 754 sin ella. Una
transacción dura por defecto menos de un minuto; después se aborta.

🔬 **El detalle** — La documentación dice que no sustituye a un buen diseño: si hace falta en cada
operación, el documento está mal cortado.

---

**04 → 15.** ¿Por qué en una transacción de MongoDB el reintento es trabajo del cliente, y qué API
lo hace por ti? 🟠

⏱️ **30 segundos** — Porque ante un conflicto MongoDB aborta en vez de esperar, y marca el error
como transitorio. `withTransaction` reintenta sola ante esos errores.

🗣️ **2 minutos** — El `WriteConflict` de la sesión B pedía reintentar la operación o la transacción.
La API de bajo nivel, con `startTransaction` y `commitTransaction`, no reintenta.

🔬 **El detalle** — **Motor y driver**; la documentación llama API de *callback* a la que reintenta.

---

**04 → 16.** Diseña los índices de `tienda.pedidos` para «los pedidos pendientes de un cliente, del
más reciente al más antiguo» y «los pedidos que llevan un producto», y di qué consulta sería
cubierta. 🔴

⏱️ **30 segundos** — `{cliente: 1, estado: 1, creado_en: -1}` para el primero, con las dos
igualdades delante y el orden detrás; y `{"lineas.producto": 1}`, multikey, para el segundo.

🗣️ **2 minutos** — La primera sería cubierta si solo devuelve campos del índice —estado y fecha— con
`_id: 0`. La segunda, con el índice simple, lee cada documento; según la documentación, un índice
multikey solo cubre si es compuesto, la consulta no devuelve la lista y no usa `$elemMatch`.

🔬 **El detalle** — Un índice parcial solo con los `PENDIENTE` sería más pequeño, al estilo del
índice disperso de `07/06`.

---

**04 → 17.** Diagnostica: el panel de operaciones, que lee de los secundarios, enseña a veces
pedidos en un estado que ya cambió, y un servicio que reintenta las escrituras que dan error de
replicación duplica movimientos. Da la causa de cada síntoma y la corrección. 🔴

⏱️ **30 segundos** — El panel lee de secundarios que van por detrás: la documentación avisa de que
pueden dar datos viejos. El servicio reintenta escrituras que ya se hicieron, porque un error de
`writeConcern` no deshace nada.

🗣️ **2 minutos** — Para el panel, aceptar el retraso o leer del primario lo que tenga que ser
fresco. Para el servicio, escrituras idempotentes con un identificador de operación, o comprobar
antes de reintentar.

🔬 **El detalle** — Las dos cosas se vieron en la sesión: `PAGADO` en el secundario, y `n: 1` con
`WriteConcernFailed`.

---

**04 → 18.** Diseña cómo cambiarías el país de un cliente y el de todos sus pedidos en MongoDB para
que ningún lector vea un estado a medias, y di qué pasa si el cambio choca con otra escritura. 🔴

⏱️ **30 segundos** — En una transacción con `withTransaction`: actualizar el cliente y hacer
`updateMany` sobre sus pedidos, con `readConcern` y `writeConcern` `majority`. Si choca, la
transacción aborta con `WriteConflict` y `withTransaction` la reintenta.

🗣️ **2 minutos** — Hace falta un conjunto de réplicas. Los lectores que lean con `majority` verán o
todo el cambio o nada. Con muchos pedidos, la transacción debe durar menos de un minuto.

🔬 **El detalle** — La alternativa es aceptar el desfase y documentarlo, si el país solo alimenta
informes.

---

## Capítulo 05 — Documental, relacional o jsonb

Las 17 preguntas de [`05`](05-documental-relacional-o-jsonb.md).

**05 → 1.** ¿Qué es un validador `$jsonSchema` en MongoDB? 🟢

⏱️ **30 segundos** — Una regla asociada a la colección que MongoDB comprueba en cada inserción y
actualización, escrita en JSON Schema.

🗣️ **2 minutos** — Rechazó el total en texto y el estado `DEVUELTO` con el motivo exacto. Se activa
con `collMod` y se quita igual.

🔬 **El detalle** — **Motor**; sigue el borrador 4 de JSON Schema, con extensiones y omisiones
propias.

---

**05 → 2.** ¿Qué hace el operador `@>` sobre un `jsonb`? 🟢

⏱️ **30 segundos** — Comprueba la contención: si el documento contiene el fragmento dado.

🗣️ **2 minutos** — `carga @> '{"importe": 3186.23}'` encontró 8 eventos entre 4,1 millones; con un
índice GIN, en 0,103 ms.

🔬 **El detalle** — **Motor**: `@>` es de PostgreSQL. La clase `jsonb_path_ops` lo admite.

---

**05 → 3.** ¿Qué significa que un servicio sea «compatible con la API de MongoDB»? 🟢

⏱️ **30 segundos** — Que habla el protocolo de MongoDB, así que los drivers y las herramientas se
conectan. No que ejecute todo lo que ejecuta MongoDB.

🗣️ **2 minutos** — DocumentDB declara compatibilidad con 4.0, 5.0 y 8.0 y publica sus diferencias;
Cosmos DB, el protocolo, con transacciones solo en una colección.

🔬 **El detalle** — **Cada servicio** define su compatibilidad; se comprueba contra su lista.

---

**05 → 4.** Distingue `validationLevel` `strict` de `moderate`, y `validationAction` `error` de
`warn`. 🟡

⏱️ **30 segundos** — `strict` valida todas las escrituras; `moderate` deja actualizar sin validar
los documentos que ya no cumplían. `error` rechaza; `warn` deja pasar y lo anota en el registro.

🗣️ **2 minutos** — `moderate` sirve para activar la validación en una colección con datos viejos sin
romper sus actualizaciones. `warn` sirve para medir cuánto se rechazaría antes de rechazar.

🔬 **El detalle** — **Motor**; los valores por defecto son `strict` y `error`.

---

**05 → 5.** Distingue `json` de `jsonb` en PostgreSQL, y di cuál se indexa con GIN. 🟡

⏱️ **30 segundos** — `json` guarda una copia exacta del texto, que se vuelve a analizar en cada
consulta; `jsonb`, un formato binario descompuesto, algo más lento de escribir y mucho más rápido de
procesar. El que se indexa es `jsonb`.

🗣️ **2 minutos** — `json` conserva espacios, orden de claves y claves repetidas; `jsonb`, no. Para
consultar por contenido, siempre `jsonb`.

🔬 **El detalle** — **Motor**, según la documentación de PostgreSQL.

---

**05 → 6.** Distingue la clase de operadores GIN por defecto de `jsonb_path_ops`. 🟡

⏱️ **30 segundos** — La de por defecto admite también los operadores de existencia de clave;
`jsonb_path_ops` admite `@>`, `@?` y `@@`, pero no la existencia de clave, y ocupa menos.

🗣️ **2 minutos** — El índice con `jsonb_path_ops` ocupó 60 MB para una tabla de 641, y sirvió para
el `@>`.

🔬 **El detalle** — **Motor**, según la documentación de PostgreSQL 18.

---

**05 → 7.** ¿Qué parte de validar un documento es del estándar SQL, y qué parte es de cada motor? 🟡

⏱️ **30 segundos** — El `CHECK` y el modelo SQL/JSON son del estándar; `jsonb`, `jsonb_typeof` y el
GIN son de PostgreSQL, y `$jsonSchema` es de MongoDB.

🗣️ **2 minutos** — En PostgreSQL, un `CHECK` sobre el JSON rechazó el importe en texto. En MongoDB,
un validador de colección.

🔬 **El detalle** — No he verificado la cláusula exacta de SQL/JSON; PostgreSQL dice que implementa
su modelo.

---

**05 → 8.** ¿Qué garantías tiene `eventos_pedido.carga` en PostgreSQL que no tendría la misma carga
en una colección de MongoDB? 🟡

⏱️ **30 segundos** — Está en una fila con una clave foránea a `pedidos`, dentro de las mismas
transacciones que el resto de la tienda, en cualquier servidor.

🗣️ **2 minutos** — En MongoDB no hay claves foráneas entre colecciones, y las transacciones exigen
un conjunto de réplicas.

🔬 **El detalle** — La validación sí existe en los dos; la integridad referencial, solo en
PostgreSQL.

---

**05 → 9.** ¿Por qué hay que buscar los documentos que no cumplen antes de activar un validador en
modo `strict`? 🟠

⏱️ **30 segundos** — Porque con `strict`, cualquier actualización de un documento que no cumpla
fallará, aunque el cambio no tenga nada que ver con la regla.

🗣️ **2 minutos** — `$nor` con `$jsonSchema` los cuenta: dio cero. Si hay alguno, se corrige antes o
se activa con `moderate`.

🔬 **El detalle** — Es el escenario de la pregunta 17: actualizaciones de documentos viejos que
empiezan a fallar.

---

**05 → 10.** ¿Por qué el `@>` bajó de 557 ms a 0,103 con el índice, y qué cuesta ese índice? 🟠

⏱️ **30 segundos** — Sin índice leyó las 4,1 millones de filas; con el GIN, fue directo a las 8.
Cuesta 60 MB y una escritura en cada inserción.

🗣️ **2 minutos** — El índice se construyó en 1,9 s. El plan pasó de `Seq Scan` a `Bitmap Index Scan`
con seis páginas.

🔬 **El detalle** — Un GIN es más caro de mantener que un B-tree; con muchas escrituras se nota.

---

**05 → 11.** ¿Cuándo pondrías un dato en `jsonb` y cuándo en columnas, con la frase de la
documentación de PostgreSQL? 🟠

⏱️ **30 segundos** — En `jsonb`, la parte de forma variable que se lee entera; en columnas, lo que
se consulta, se une y se valida siempre igual. La documentación pide que cada documento sea un dato
que no se modifique por partes.

🗣️ **2 minutos** — La carga del evento es un buen `jsonb`; el estado del pedido, que se filtra y se
une, va en columna.

🔬 **El detalle** — Un `jsonb` grande se reescribe entero al cambiar un campo.

---

**05 → 12.** ¿Por qué un código que funciona contra MongoDB puede fallar en Cosmos DB for MongoDB?
Da dos ejemplos de la documentación. 🟠

⏱️ **30 segundos** — Porque Cosmos DB habla el protocolo, pero no ejecuta todo. Su página de la
versión 4.2 dice que las transacciones multidocumento solo funcionan dentro de una colección sin
fragmentar, y que `collMod` no se admite.

🗣️ **2 minutos** — Una transacción entre pedidos y clientes, o un validador puesto con `collMod`,
funcionan en MongoDB y fallan allí.

🔬 **El detalle** — Las pruebas de integración tienen que correr contra el servicio real.

---

**05 → 13.** ¿Por qué dos motores en una misma aplicación cuestan más que la suma de sus licencias?
🟠

⏱️ **30 segundos** — Porque son dos respaldos, dos monitorizaciones, dos modelos de consistencia y
datos que cuadrar entre ellos, sin transacción común.

🗣️ **2 minutos** — Lo que se escribe en los dos puede desfasarse, como el ranking de Redis de
`07/02`. Y el equipo tiene que saber operar los dos.

🔬 **El detalle** — Por eso `jsonb` gana cuando la aplicación ya vive en PostgreSQL.

---

**05 → 14.** Diseña cómo guardarías los atributos variables por categoría de los productos de la
tienda —el audio con potencia, el libro con páginas— en PostgreSQL, con su índice y su validación. 🔴

⏱️ **30 segundos** — Una columna `jsonb` de atributos en `productos`, un índice GIN con
`jsonb_path_ops` para buscar por contenido, y un `CHECK` por categoría: si es `audio`, que tenga la
potencia y sea número.

🗣️ **2 minutos** — Lo común —nombre, precio, categoría— sigue en columnas. Los atributos que se
filtran mucho pueden tener un índice de expresión propio.

🔬 **El detalle** — El esquema del corpus no tiene esa columna; sería un cambio con su migración, que
es materia del bloque 06.

---

**05 → 15.** Te proponen migrar a Amazon DocumentDB una aplicación que usa transacciones entre
colecciones y `$elemMatch` dentro de `$all`. Da el plan de comprobación antes de decidir. 🔴

⏱️ **30 segundos** — Revisar la página de diferencias funcionales de DocumentDB contra las
operaciones del código, empezando por esas dos, y correr las pruebas de integración contra un
clúster de DocumentDB.

🗣️ **2 minutos** — `$elemMatch` dentro de `$all` figura como no admitido en esa página. Para las
transacciones, comprobar qué dice la documentación de la versión elegida. Si algo falla, reescribir
o descartar.

🔬 **El detalle** — La compatibilidad se declara por versión; se revisa en cada cambio de versión.

---

**05 → 16.** Defiende ante un equipo si los eventos de pedido deberían ir a MongoDB o quedarse en
`eventos_pedido.carga`, con los números del bloque. 🔴

⏱️ **30 segundos** — Quedarse: con GIN, la búsqueda por contenido tardó 0,103 ms; el `CHECK` valida;
y el evento está en la misma transacción que el pedido. Moverlos añade un motor sin ganar velocidad.

🗣️ **2 minutos** — Los eventos se leen con su pedido y en informes: el *bucket* de MongoDB ahorraría
índice, pero PostgreSQL puede particionar por fecha. Solo con un volumen que no cupiera en una
instancia cambiaría la respuesta.

🔬 **El detalle** — Es la regla del bloque: relacional por defecto, `jsonb` para la parte variable.

---

**05 → 17.** Diagnostica: tras activar un validador en una colección con años de datos, empiezan a
fallar actualizaciones de documentos antiguos que nadie ha tocado en meses. Da la causa y dos formas
de salir. 🔴

⏱️ **30 segundos** — Con `strict`, toda actualización de un documento que no cumpla la regla falla,
aunque cambie otro campo. Salidas: corregir los documentos viejos, o pasar a `moderate` mientras se
corrigen.

🗣️ **2 minutos** — Se encuentran con `$nor` y `$jsonSchema`. `warn` también sirve para medir sin
rechazar.

🔬 **El detalle** — Lo correcto era buscarlos antes de activar la regla.

---

## Simulación de entrevista

Las 26 preguntas `S#` y los cuatro escenarios de [`06`](06-simulacion-de-entrevista.md). Los
escenarios no se responden de memoria: se defienden en voz alta, y la capa 🔬 es la que dice qué se
está evaluando de verdad.

**06 → S1.** ¿Qué gana y qué pierde el pedido de la tienda como documento, con lo medido? 🟡

⏱️ **30 segundos** — Gana localidad y escritura atómica del agregado: un documento de 379 bytes.
Pierde las consultas sobre las líneas —el top de productos, 214 ms frente a 81— y el tipado que la
base comprueba.

🗣️ **2 minutos** — En velocidad de lectura, empate: 0,115 ms el `JOIN`. El total en texto entró sin
error hasta que se puso validación.

🔬 **El detalle** — La ganancia no es de milisegundos, es de forma.

---

**06 → S2.** «MongoDB no tiene esquema». ¿Qué parte es cierta y qué se vio al guardar un total como
texto? 🟠

⏱️ **30 segundos** — Es cierto que la base no comprueba un esquema salvo que se le pida. El total en
texto entró y `$sum` lo ignoró: la suma bajó 5 971,28 sin error.

🗣️ **2 minutos** — Con `$jsonSchema`, el mismo cambio se rechazó. El esquema existe siempre: en la
base o en el código.

🔬 **El detalle** — «NoSQL no significa sin esquema: significa que no lo valida el motor».

---

**06 → S3.** ¿Por qué el documento ocupa más sin comprimir y menos en disco que las filas? 🟡

⏱️ **30 segundos** — Sin comprimir repite los nombres de campo en cada documento: 42 MB frente a 31.
En disco, WiredTiger comprime con snappy: 10,5 MB.

🗣️ **2 minutos** — En memoria vuelve a ser BSON sin comprimir. PostgreSQL solo comprime valores
grandes.

🔬 **El detalle** — **Motor** los dos comportamientos.

---

**06 → S4.** Couchbase, CouchDB y Firestore: lo único que distingue a cada uno de MongoDB. 🟢

⏱️ **30 segundos** — Couchbase, SQL++; CouchDB, replicación y conflictos; Firestore, tiempo real y
cobro por documento leído.

🗣️ **2 minutos** — Cada uno cambia el diseño: el lenguaje, la resolución de conflictos o la factura.

🔬 **El detalle** — Según su documentación; ninguno está en el entorno.

---

**06 → S5.** Explica la trampa de dos condiciones sobre una lista y cómo la evita `$elemMatch`. 🟠

⏱️ **30 segundos** — Sin `$elemMatch`, cada condición se cumple con cualquier elemento, por
separado: 1 028 pedidos en vez de 599. `$elemMatch` exige el mismo elemento.

🗣️ **2 minutos** — PostgreSQL confirmó 599 con el `JOIN` sobre la fila de `pedido_lineas`.

🔬 **El detalle** — No da error: el informe simplemente da de más.

---

**06 → S6.** ¿Por qué el top de productos fue tres veces más lento en MongoDB con el mismo
resultado? 🟠

⏱️ **30 segundos** — Porque las líneas están dentro de los pedidos y hubo que desplegar 349 999 con
`$unwind`; PostgreSQL leyó `pedido_lineas`, que ya es una fila por línea.

🗣️ **2 minutos** — De 212 a 272 ms frente a 80 y 81, en tres corridas.

🔬 **El detalle** — Es el precio de incrustar.

---

**06 → S7.** `$lookup` frente a un `JOIN`: cómo se ejecuta cada uno y cuánto costó. 🟡

⏱️ **30 segundos** — `$lookup` busca por cada documento; el `JOIN` lo planifica el motor, aquí con
un *hash join*. 472 ms frente a 28.

🗣️ **2 minutos** — 24 910 búsquedas por `_id` en un caso; una lectura de cada tabla en el otro.

🔬 **El detalle** — Con la referencia extendida, el mismo panel tardó 38 ms.

---

**06 → S8.** ¿Por qué cambiar una línea del pedido no actualiza su total, y cómo se hace en la misma
orden? 🟡

⏱️ **30 segundos** — Porque el documento no sabe que el total depende de las líneas. Con dos `$inc`
en el mismo `updateOne`.

🗣️ **2 minutos** — La línea a 6 y el total a 3 213,26, en una orden atómica, y la inversa lo
devolvió.

🔬 **El detalle** — Es la columna desnormalizada de siempre.

---

**06 → S9.** ¿Qué preguntas deciden si una parte se incrusta o se referencia? Aplícalas a las líneas
y a los pedidos de un cliente. 🟠

⏱️ **30 segundos** — Si se lee siempre con su padre, cuánto crece y si se consulta sola. Las líneas:
se leen juntas, máximo 6, no solas: se incrustan. Los pedidos: crecen sin tope y se consultan solos:
se referencian.

🗣️ **2 minutos** — El tope se mide: media de 3,5 líneas y máximo 6; media de 20 pedidos por cliente
y máximo 52, y sigue.

🔬 **El detalle** — **Convención** de modelado.

---

**06 → S10.** ¿Cómo se llega al límite de 16 MiB, y por qué no avisa? 🟠

⏱️ **30 segundos** — Con una lista sin tope: un día, un `$push` normal falla porque el documento ya
no cabe.

🗣️ **2 minutos** — Un documento cien bytes por debajo entró, y un `$push` de 200 bytes falló con
`Resulting document after update is larger than 16777216`.

🔬 **El detalle** — **Motor** el límite; el diseño es el que lo evita.

---

**06 → S11.** La referencia extendida: qué es, cuánto ahorró y qué cuesta. 🟡

⏱️ **30 segundos** — Copiar en el documento los campos del referenciado que se leen siempre. El
panel por país bajó de 472 a 38 ms. Cuesta actualizar las copias cuando el original cambia.

🗣️ **2 minutos** — Cambiar el país de `CLI-00311` tocó siete pedidos, sin transacción común con el
cliente.

🔬 **El detalle** — Vale para campos que cambian poco.

---

**06 → S12.** El patrón *bucket* con los eventos de la tienda: qué cambió y qué se paga. 🟡

⏱️ **30 segundos** — De 409 998 documentos a 24 002 cubos por hora, y de 8,99 MB de índices a 0,37.
Se paga en reescribir el cubo en cada `$push`.

🗣️ **2 minutos** — Leer una hora pasó de 18 documentos a uno.

🔬 **El detalle** — Las colecciones de series temporales lo aplican solas.

---

**06 → S13.** ¿Por qué la tienda no necesita el patrón *outlier*? 🟠

⏱️ **30 segundos** — Porque el cliente más activo tiene 52 pedidos y la mediana es 20: no hay cola
larga.

🗣️ **2 minutos** — El patrón sirve cuando unos pocos documentos son miles de veces mayores.

🔬 **El detalle** — Se decide con un percentil en la mano.

---

**06 → S14.** ¿Qué es un índice multikey y cuánto ocupó el de las líneas? 🟢

⏱️ **30 segundos** — Un índice con una entrada por elemento de una lista. El de las líneas, 3,28 MB,
tres veces el de `_id`.

🗣️ **2 minutos** — Pasó la búsqueda por producto de 74 a 3 ms.

🔬 **El detalle** — MongoDB lo crea multikey sin pedirlo.

---

**06 → S15.** La regla ESR, con las 11 859 y las 16 claves de la sesión, y cuándo conviene romperla.
🟠

⏱️ **30 segundos** — Igualdad, orden, rango: con el orden antes que el rango, 16 claves y ningún
`SORT`; al revés, 11 859 y `SORT` en memoria. Se rompe cuando el rango es muy selectivo.

🗣️ **2 minutos** — Lo dice la propia documentación: ESR para evitar el orden en memoria, ERS si el
rango deja muy pocas claves.

🔬 **El detalle** — **Convención** medida.

---

**06 → S16.** Una escritura con `w: "majority"` devolvió error por tiempo de espera. ¿Se hizo? ¿Qué
pasa si se reintenta? 🔴

⏱️ **30 segundos** — Se hizo: `n: 1` y `nModified: 1`, y al desbloquear los secundarios estaba en
todos. Reintentar una operación no idempotente la duplica.

🗣️ **2 minutos** — La documentación dice que el `wtimeout` no deshace nada. La corrección:
escrituras idempotentes o comprobar antes de reintentar.

🔬 **El detalle** — Es el error más caro del bloque, porque parece prudente.

---

**06 → S17.** ¿Por qué `readConcern("majority")` devolvió el valor viejo leyendo del primario? 🟠

⏱️ **30 segundos** — Porque la mayoría aún no tenía el cambio: solo el primario lo había aplicado.

🗣️ **2 minutos** — Garantiza no leer lo que podría deshacerse si cae el primario.

🔬 **El detalle** — **Motor**, según su documentación.

---

**06 → S18.** Dos transacciones sobre el mismo pedido en MongoDB y en PostgreSQL: qué hace cada
motor. 🟡

⏱️ **30 segundos** — En MongoDB, la segunda falla al instante con `WriteConflict`; en PostgreSQL,
espera el bloqueo de fila.

🗣️ **2 minutos** — En MongoDB el reintento es del cliente o de `withTransaction`.

🔬 **El detalle** — **Motor** los dos.

---

**06 → S19.** ¿Qué cuesta una transacción en MongoDB, medido, y cuándo merece la pena? 🟠

⏱️ **30 segundos** — 2,3 ms por operación frente a 1,7 con `majority` y 1,0 con `w: 1`. Merece la
pena cuando varios documentos tienen que cambiar juntos.

🗣️ **2 minutos** — Solo en conjunto de réplicas, y con menos de un minuto de duración por defecto.

🔬 **El detalle** — No sustituye al diseño, dice la documentación.

---

**06 → S20.** ¿Cómo valida MongoDB el esquema, y qué hay que hacer antes de activarlo? 🟡

⏱️ **30 segundos** — Con un validador `$jsonSchema` en la colección. Antes, buscar con `$nor` los
documentos que no cumplen.

🗣️ **2 minutos** — Rechazó el total en texto y el estado inventado. `moderate` y `warn` sirven para
activarlo con datos viejos.

🔬 **El detalle** — Borrador 4 de JSON Schema, con diferencias.

---

**06 → S21.** `jsonb` en PostgreSQL como tercera vía: qué se midió con el índice GIN y el `CHECK`. 🟡

⏱️ **30 segundos** — El `@>` sobre `carga` bajó de 557 ms a 0,103 con un GIN de 60 MB. El `CHECK`
validó 4,1 millones de filas en 0,74 s y rechazó el importe en texto.

🗣️ **2 minutos** — Todo dentro de PostgreSQL, con clave foránea y transacciones.

🔬 **El detalle** — `jsonb_path_ops`: sin operadores de existencia de clave, índice más pequeño.

---

**06 → S22.** ¿Cuándo relacional, cuándo `jsonb` y cuándo documental? 🔴

⏱️ **30 segundos** — Relacional por defecto; `jsonb` para la parte variable de un dato relacional;
documental cuando el agregado entero es la unidad y la escala lo pide.

🗣️ **2 minutos** — Si hay informes sobre las partes, gana el modelo con planificador. Dos motores
son dos cosas que operar.

🔬 **El detalle** — La pregunta es cómo se lee y quién más lo consulta, no si tiene forma de JSON.

---

**06 → S23.** «Si el dato es JSON, va en una base documental». Corrígelo. 🟡

⏱️ **30 segundos** — Casi todo es JSON cuando viaja por una API. Lo que decide es cómo se lee; para
la parte variable, `jsonb` basta.

🗣️ **2 minutos** — La carga de los eventos es JSON y vive bien en PostgreSQL, con índice y
validación.

🔬 **El detalle** — **Convención** equivocada.

---

**06 → S24.** «En MongoDB no hay joins ni transacciones». ¿Qué parte es cierta? 🟠

⏱️ **30 segundos** — Ninguna del todo: hay `$lookup`, que es un bucle de búsquedas, y transacciones
en conjunto de réplicas.

🗣️ **2 minutos** — Lo cierto es que no hay un *join* planificado, y que la transacción cuesta y
exige réplicas.

🔬 **El detalle** — Las dos se midieron en el bloque.

---

**06 → S25.** «DocumentDB es MongoDB gestionado por AWS». ¿Qué habría que comprobar antes de
creerlo? 🟠

⏱️ **30 segundos** — Su página de diferencias funcionales contra las operaciones que usa el código,
empezando por las poco comunes, como `$elemMatch` dentro de `$all`.

🗣️ **2 minutos** — Y las pruebas de integración contra DocumentDB, no contra un MongoDB local.

🔬 **El detalle** — Declara compatibilidad por versión: 4.0, 5.0 y 8.0.

---

**06 → S26.** «Con `w: majority` nunca se pierde una escritura ni se duplica». Refútalo. 🔴

⏱️ **30 segundos** — No se pierde lo que confirmó la mayoría, pero un error por tiempo de espera
deja la escritura hecha, y reintentarla la duplica.

🗣️ **2 minutos** — `n: 1` con `WriteConcernFailed` en la sesión. Hace falta idempotencia.

🔬 **El detalle** — `majority` protege de perder, no de repetir.

---

**06 → E1.** Escenario 1 — El informe que no cuadra

⏱️ **30 segundos** — El 0,3 % de menos: totales guardados como texto que `$sum` ignora; se confirma
con `$type`. El 70 % de más: dos condiciones sobre `lineas` sin `$elemMatch`; se confirma contando
con y sin él, 1 028 y 599.

🗣️ **2 minutos** — Corregir los documentos con el tipo equivocado y activar un validador
`$jsonSchema` tras comprobar con `$nor` que todos cumplen. Reescribir la consulta con `$elemMatch`.
Y una prueba que compare los recuentos de los dos motores sobre los mismos datos.

🔬 **El detalle** — Lo que se evalúa es reconocer que ninguno de los dos da error, y que la causa
está en los datos y en la consulta, no en el motor.

---

**06 → E2.** Escenario 2 — El historial que ya no cabe

⏱️ **30 segundos** — Fallan los pedidos cuyo historial llegó a 16 MiB; se encuentran con `$bsonSize`
en una agregación. El rediseño: el historial en cubos por pedido y periodo, o en su colección, con
los últimos estados en el pedido.

🗣️ **2 minutos** — La migración se hace en dos fases: escribir en los dos sitios, copiar lo viejo y
cambiar las lecturas. Para el panel de la última hora, un *bucket* por hora con la hora como `_id`
lee un documento.

🔬 **El detalle** — Se evalúa ver que el fallo de unos pocos anuncia el de todos: la lista no tenía
tope.

---

**06 → E3.** Escenario 3 — Consistencia en el panel de operaciones

⏱️ **30 segundos** — El panel lee de secundarios atrasados; el reintento duplica porque el error de
`writeConcern` no deshace la escritura.

🗣️ **2 minutos** — Panel: secundario si admite retraso. Pantalla tras un cambio: primario o sesión
con consistencia causal. Reintentos idempotentes con un identificador de operación. Transacción solo
si varios documentos tienen que cambiar juntos.

🔬 **El detalle** — Se evalúa separar `readPreference`, `readConcern` y `writeConcern`, y saber que
un tiempo de espera no es un fallo de la escritura.

---

**06 → E4.** Escenario 4 — «Pasemos a MongoDB, que es más rápido»

⏱️ **30 segundos** — Esto no lo resuelve cambiar de base: el panel por país tardó 28 ms con el
`JOIN` de PostgreSQL frente a 472 con `$lookup`, y la ficha con atributos variables cabe en `jsonb`
con índice GIN.

🗣️ **2 minutos** — En PostgreSQL: un índice para el panel si hace falta, `jsonb` con GIN y `CHECK`
para los atributos. Una base documental tendría sentido si el agregado entero fuera la unidad y la
escala no cupiera. La migración perdería tipos, claves foráneas y transacciones en cualquier
servidor.

🔬 **El detalle** — Se evalúa medir antes de migrar y no aceptar «más rápido» sin número.
