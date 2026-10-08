# 06 — DynamoDB: diseño desde el acceso

> El método que se pregunta de verdad en una entrevista sobre DynamoDB, aplicado de principio a fin
> a la tienda: primero las preguntas, después las claves. Cinco pasos, una tabla única con tres
> índices, y cada patrón de acceso respondido con una sola consulta de media unidad. Por el camino,
> el primer diseño de clave falla contra los datos reales —DynamoDB rechaza un lote entero y, en
> otra escritura, pisa una línea de pedido sin avisar—, y se ve lo que cuesta una pregunta que no
> estaba en la lista. **Este capítulo es el dueño del método**; `09/02` lo reutiliza con Cassandra.
> **Asume leído:** [`05`](05-dynamodb-modelo-y-claves.md), las claves, los índices y la capacidad.
> **Vigencia:** 27 de septiembre de 2026.

---

## Salto rápido

- [1. El problema](#1--el-problema) · [2. El método en cinco pasos](#2--el-método-en-cinco-pasos)
- [3. Pasos 1 y 2: entidades y patrones](#3--pasos-1-y-2-entidades-y-patrones) · [4. Paso 3: la
  clave que pisa](#4--paso-3-la-clave-que-pisa)
- [5. Paso 4: la tabla única y sus índices](#5--paso-4-la-tabla-única-y-sus-índices) · [6. Paso 5:
  cada patrón, con su orden](#6--paso-5-cada-patrón-con-su-orden)
- [7. Lo que se paga](#7-️-lo-que-se-paga) · [8. Cómo se elige](#8--cómo-se-elige) · [9. Estándar,
  motor y convención](#9--estándar-motor-y-convención) · [Preguntas](#-preguntas)

---

## 1. 🎯 El problema

La tabla de [`05`](05-dynamodb-modelo-y-claves.md) respondía bien a «los pedidos de este cliente»,
y a nada más. Pedir `PED-00042` sin saber que era de `CLI-26446` no tenía orden posible, contar los
`PAGADO` costaba leer la tabla entera, y cada pregunta nueva pedía un índice nuevo que se paga en
cada escritura. El equipo diseñó la tabla como se diseña en PostgreSQL —primero los datos, después
ya veremos qué se pregunta— y en DynamoDB ese orden no funciona.

La documentación de AWS lo dice sin rodeos: en una base relacional se puede crear un modelo
normalizado **sin pensar en los patrones de acceso** y extenderlo cuando lleguen preguntas nuevas;
en DynamoDB no se empieza a diseñar hasta saber qué preguntas tiene que responder. La consecuencia
es un método distinto, y este capítulo lo aplica entero a la tienda: pedidos, líneas, clientes y
productos, en una tabla, con cuatro preguntas que se responden cada una con **una consulta de 0,5
unidades**.

> **📝 Contexto.** Todo está corrido contra DynamoDB Local 3.3.1, con la CLI de `05` y la misma
> abreviatura: `aws` es la orden `run` del servicio `aws` del `compose`. Los datos son los pedidos
> de `CLI-00311` y `PED-00042` con sus 178 líneas, sacados de PostgreSQL: **231 elementos**. Las
> frecuencias de la tabla de patrones son **supuestos del caso**, no mediciones: sirven para
> decidir, que es su papel en el método. Lo que DynamoDB Local no reproduce es lo de `05` §6. La
> tabla se borra al parar el contenedor. **Longitud:** unas 490 líneas; capítulo denso, declarado en
> §4.6 de la guía de estilo.

---

## 2. 🧭 El método en cinco pasos

| Paso | Qué se hace | Qué sale |
|---|---|---|
| **1. Entidades** | Listar las cosas del dominio y cómo se relacionan: uno a muchos, muchos a muchos | Un diagrama como el de un esquema relacional |
| **2. Patrones de acceso** | Escribir **cada pregunta** que hará la aplicación, con lo que recibe, lo que devuelve y cuántas veces por segundo | Una tabla de patrones; es el documento de diseño |
| **3. Claves** | Elegir la clave de partición y la de orden para que el patrón más frecuente sea una `query` | La clave primaria, comprobada contra datos reales |
| **4. Índices** | Un índice por cada patrón que la clave de la tabla no responde | Los índices globales, dispersos cuando se pueda |
| **5. Comprobar** | Correr una orden por patrón y mirar la capacidad | La prueba de que ningún patrón necesita un `scan` |

- **El paso 2 es el que manda.** En relacional, la pregunta llega después y el planificador se las
  arregla; aquí, una pregunta que no está en la tabla de patrones es un `scan` o un índice nuevo.
- **El paso 5 no es opcional.** Un diseño de claves se equivoca de maneras que solo aparecen con los
  datos reales, y §4 es un ejemplo.

**Quién lo manda:** **convención**, respaldada por la documentación de AWS, que recomienda conocer
las preguntas antes de diseñar y usar el menor número de tablas posible. **Cuánto:** el trabajo se
mueve al principio: antes de escribir una línea de código hay que saber qué se va a preguntar.
**Cuándo sí:** con patrones de acceso conocidos y estables. **Cuándo no:** con un producto que aún
está descubriendo qué pregunta, que es el caso de §8.

> **Veredicto:** en DynamoDB se diseña desde las preguntas hacia la tabla; si no puedes escribir la
> lista de patrones, no estás listo para elegir la clave.

---

## 3. 🧱 Pasos 1 y 2: entidades y patrones

**Paso 1.** Las entidades son las del dominio: un **cliente** tiene muchos **pedidos**; un pedido
tiene muchas **líneas**; cada línea es de un **producto**, y un producto aparece en muchos pedidos.
Es la relación muchos a muchos de `pedido_lineas`, la tabla de PostgreSQL con clave compuesta.

**Paso 2.** Los patrones de acceso de la tienda, con frecuencias supuestas para una campaña:

| # | Patrón | Recibe | Devuelve | Frecuencia |
|---|---|---|---|---|
| P1 | La ficha de un pedido, con sus líneas | El código, `PED-00042` | El pedido y sus líneas | 2 000/s |
| P2 | Los pedidos recientes de un cliente | `CLI-00311` | Sus pedidos, del más nuevo al más viejo, paginados | 500/s |
| P3 | Los pedidos que llevan un producto | `PRD-00005` | Los pedidos y la línea | 20/s, para atención al cliente |
| P4 | Los pedidos pendientes de un cliente | `CLI-00311` | Solo los `PENDIENTE` | 300/s, en el pago |

- **P1 recibe el código, no el cliente**: es la pregunta que la tabla de `05` no sabía responder, y
  por eso el pedido tiene que poder encontrarse por su código.
- **P3 recorre la relación al revés**: de producto a pedidos. En relacional es un `JOIN`; aquí
  necesita un índice que tenga el producto como clave.
- **Lo que no está en la lista no se diseña**: «el total vendido por categoría» o «los pedidos de
  más de mil euros» no aparecen, y el diseño no los responderá sin un `scan`. Se decide sabiendo.

> **Veredicto:** la tabla de patrones es el documento de diseño de una tabla de DynamoDB: si una
> pregunta no está en ella, el diseño no la responde.

---

## 4. 🩺 Paso 3: la clave que pisa

**La primera idea para las líneas** parece natural: partición `PEDIDO#PED-00042`, y orden
`PRODUCTO#PRD-01395`, para que P3 salga de invertir la clave. Antes de fijarla, el paso 5 manda
comprobarla contra los datos:

```text
tienda=# SELECT count(*) AS pedidos_con_producto_repetido FROM (SELECT pedido_id, producto_id FROM pedido_lineas GROUP BY 1,2 HAVING count(*) > 1) t;
 pedidos_con_producto_repetido
-------------------------------
                          6855
(1 fila)
```

**6 855 pedidos tienen el mismo producto en dos líneas**, y con esa clave, las dos líneas serían
el mismo elemento. En la muestra está `PED-388526`, con `PRD-00014` en sus líneas 3 y 4. Se cargó
así de todas formas, para ver qué hace DynamoDB. El lote de 25 elementos que contenía las dos:

```text
$ aws dynamodb batch-write-item --request-items file:///datos/dynamodb/producto/lote-03

aws: [ERROR]: An error occurred (ValidationException) when calling the BatchWriteItem operation: Provided list of item keys contains duplicates
```

- **DynamoDB rechazó el lote entero**, no solo el duplicado: la tabla quedó con 206 elementos en vez
  de 231. Los otros veintitrés elementos del lote se perdieron con los dos culpables.

Si las dos líneas llegan en escrituras distintas, el resultado es peor, porque no hay error:

```text
$ aws dynamodb put-item --table-name tienda --item '{"PK":{"S":"PEDIDO#PED-388526"},"SK":{"S":"PRODUCTO#PRD-00014"},"producto":{"S":"PRD-00014"},"cantidad":{"N":"4"},"precio_unit":{"N":"848.54"}}' --return-values ALL_OLD

$ aws dynamodb put-item --table-name tienda --item '{"PK":{"S":"PEDIDO#PED-388526"},"SK":{"S":"PRODUCTO#PRD-00014"},"producto":{"S":"PRD-00014"},"cantidad":{"N":"2"},"precio_unit":{"N":"848.54"}}' --return-values ALL_OLD
{
    "Attributes": {
        "SK": {
            "S": "PRODUCTO#PRD-00014"
        },
        "PK": {
            "S": "PEDIDO#PED-388526"
        },
        "producto": {
            "S": "PRD-00014"
        },
        "cantidad": {
            "N": "4"
        },
        "precio_unit": {
            "N": "848.54"
        }
    }
}

$ aws dynamodb query --table-name tienda --key-condition-expression "PK = :p AND begins_with(SK, :s)" --expression-attribute-values '{":p":{"S":"PEDIDO#PED-388526"},":s":{"S":"PRODUCTO#PRD-00014"}}' --query 'Items[].[SK.S, cantidad.N]' --output text
PRODUCTO#PRD-00014	2
```

- **`put-item` sustituye el elemento entero si la clave existe**, sin error. `ALL_OLD` devolvió lo
  que había: la línea de 4 unidades, que ya no existe. El pedido perdió cuatro unidades de
  `PRD-00014` y nadie se enteró.
- **La defensa es una condición**: la misma escritura con la condición `attribute_not_exists(PK)`
  respondió `ConditionalCheckFailedException` en vez de pisar.

**La clave corregida**: la línea va con orden `LINEA#01`, `LINEA#02`…, que es única por
construcción —es la clave compuesta de `pedido_lineas`—, y el producto pasa a un atributo con su
propio índice. La tabla se borró y se cargó de nuevo: 231 elementos, sin lotes rechazados.

**Quién lo manda:** **motor**: `put-item` es un reemplazo, y la unicidad es la de la clave, sin más.
**Cuánto:** en **riesgo de pérdida** silenciosa, el peor tipo. **Cuándo sí:** claves de orden que
sean únicas por construcción, y escrituras condicionales siempre que crear no deba pisar. **Cuándo
no:** una clave elegida por intuición, sin mirar los datos.

> **Veredicto:** en DynamoDB la clave primaria es la única restricción de unicidad que hay, y
> escribir sobre ella reemplaza sin preguntar; compruébala contra los datos reales y escribe con
> condición.

---

## 5. 🧱 Paso 4: la tabla única y sus índices

**Qué es una tabla única** (*single-table design*): todos los tipos de elemento en la misma tabla,
con claves **genéricas** —`PK` y `SK`— cuyo contenido depende del tipo. Así, los elementos que se
leen juntos comparten partición y salen en una sola `query`. La colección del pedido `PED-00042`:

| `PK` | `SK` | Tipo | Otros atributos |
|---|---|---|---|
| `PEDIDO#PED-00042` | `LINEA#01` | Línea | `producto` `PRD-01395`, `cantidad`, `precio_unit` |
| `PEDIDO#PED-00042` | `LINEA#02` | Línea | `producto` `PRD-00872`, … |
| `PEDIDO#PED-00042` | `LINEA#03` | Línea | `producto` `PRD-03623`, … |
| `PEDIDO#PED-00042` | `PEDIDO` | Pedido | `estado`, `total`, `creado`, `GSI1PK` `CLIENTE#CLI-26446`, `GSI1SK` |

```bash
aws dynamodb create-table --table-name tienda \
  --attribute-definitions AttributeName=PK,AttributeType=S AttributeName=SK,AttributeType=S \
    AttributeName=GSI1PK,AttributeType=S AttributeName=GSI1SK,AttributeType=S \
    AttributeName=producto,AttributeType=S AttributeName=pendiente_de,AttributeType=S \
  --key-schema AttributeName=PK,KeyType=HASH AttributeName=SK,KeyType=RANGE \
  --global-secondary-indexes \
    'IndexName=gsi1,KeySchema=[{AttributeName=GSI1PK,KeyType=HASH},{AttributeName=GSI1SK,KeyType=RANGE}],Projection={ProjectionType=ALL}' \
    'IndexName=por-producto,KeySchema=[{AttributeName=producto,KeyType=HASH},{AttributeName=PK,KeyType=RANGE}],Projection={ProjectionType=KEYS_ONLY}' \
    'IndexName=pendientes,KeySchema=[{AttributeName=pendiente_de,KeyType=HASH},{AttributeName=GSI1SK,KeyType=RANGE}],Projection={ProjectionType=ALL}' \
  --billing-mode PAY_PER_REQUEST --query 'TableDescription.GlobalSecondaryIndexes[].[IndexName, IndexStatus]' --output text
```

```text
por-producto	ACTIVE
gsi1	ACTIVE
pendientes	ACTIVE
```

Los tres índices, cada uno con su técnica:

- **`gsi1`, la sobrecarga de claves**: sus atributos se llaman `GSI1PK` y `GSI1SK`, sin significado
  propio, porque cada tipo de elemento los rellena con lo que le sirve. El pedido pone
  `CLIENTE#CLI-26446` y su fecha con el código: es P2. Otro tipo de elemento podría usar el mismo
  índice para otra pregunta, sin crear un índice más.
- **`por-producto`, la relación al revés**: la partición es el producto y el orden, la `PK` del
  pedido. Recorre el muchos a muchos desde el otro lado, que es la idea de los **índices
  invertidos** que recomienda la documentación; aquí la clave es un atributo y no la `SK`, porque la
  `SK` de la línea es su número. Proyecta solo claves, porque P3 es poco frecuente y cada atributo
  proyectado se paga en cada escritura.
- **`pendientes`, el índice disperso**: su clave, `pendiente_de`, **solo existe en los pedidos
  `PENDIENTE`**; al pagarse, el atributo se borra y el pedido sale del índice. Un elemento sin la
  clave del índice no entra en él, así que el índice solo contiene lo que P4 busca.

Los elementos, como en `05`, salen de una consulta a PostgreSQL que escribe el pedido y sus líneas
en el formato de DynamoDB, y el mismo bucle de `batch-write-item` los carga de 25 en 25. El atributo
`pendiente_de` solo se añade cuando el estado es `PENDIENTE`.

**Quién lo manda:** **motor** los índices; **convención** la tabla única y los nombres genéricos.
**Cuánto:** cada índice global cobra su escritura, como en `05` §5; los nombres genéricos hacen la
tabla ilegible sin la tabla de patrones al lado. **Cuándo sí:** entidades que se leen juntas.
**Cuándo no:** datos con patrones muy distintos o series temporales de mucho volumen, que la
documentación pone como excepción.

> **Veredicto:** la tabla única junta en una partición lo que se lee junto; los índices
> sobrecargados, invertidos y dispersos responden el resto sin multiplicar tablas.

---

## 6. 🩺 Paso 5: cada patrón, con su orden

```text
$ aws dynamodb query --table-name tienda --key-condition-expression "PK = :p" \
    --expression-attribute-values '{":p":{"S":"PEDIDO#PED-00042"}}' --return-consumed-capacity TOTAL \
    --query '[Items[].[SK.S, estado.S || producto.S], ConsumedCapacity.CapacityUnits]' --output text
0.5
LINEA#01	PRD-01395
LINEA#02	PRD-00872
LINEA#03	PRD-03623
PEDIDO	PAGADO

$ aws dynamodb query --table-name tienda --index-name gsi1 --key-condition-expression "GSI1PK = :c" \
    --expression-attribute-values '{":c":{"S":"CLIENTE#CLI-00311"}}' --no-scan-index-forward --limit 3 \
    --return-consumed-capacity TOTAL --query '[Items[].[codigo.S, estado.S, creado.S], ConsumedCapacity.CapacityUnits]' --output text
0.5
PED-418201	PAGADO	2025-09-02T21:36:23Z
PED-991372	ENTREGADO	2025-08-25T11:38:12Z
PED-352201	PENDIENTE	2025-07-07T11:33:41Z

$ aws dynamodb query --table-name tienda --index-name por-producto --key-condition-expression "producto = :p" \
    --expression-attribute-values '{":p":{"S":"PRD-00005"}}' --return-consumed-capacity TOTAL \
    --query '[Items[].[PK.S, SK.S], ConsumedCapacity.CapacityUnits]' --output text
0.5
PEDIDO#PED-388526	LINEA#05
PEDIDO#PED-809038	LINEA#05

$ aws dynamodb query --table-name tienda --index-name pendientes --key-condition-expression "pendiente_de = :c" \
    --expression-attribute-values '{":c":{"S":"CLIENTE#CLI-00311"}}' --return-consumed-capacity TOTAL \
    --query '[Items[].codigo.S, ConsumedCapacity.CapacityUnits]' --output text
0.5
PED-388526	PED-717934	PED-188067	PED-827003	PED-877851	PED-352201

$ aws dynamodb describe-table --table-name tienda --query 'Table.{elementos: ItemCount, indices: GlobalSecondaryIndexes[].[IndexName, ItemCount]}'
{
    "elementos": 231,
    "indices": [
        [
            "por-producto",
            178
        ],
        [
            "gsi1",
            53
        ],
        [
            "pendientes",
            6
        ]
    ]
}
```

- **P1: el pedido y sus tres líneas en una `query`**, por el código y sin saber el cliente. El
  elemento `PEDIDO` sale el último porque `L` va antes que `P`: el orden de la clave es texto.
- **P2: los tres pedidos más recientes de `CLI-00311`**, los mismos que dio la tabla de `05` §3,
  ahora desde `gsi1`.
- **P3: los dos pedidos que llevan `PRD-00005`**, con la línea en que aparece. Como la proyección es
  solo de claves, la ficha de cada uno se lee después con P1.
- **P4: los seis pendientes de `CLI-00311`**, de un índice que solo tiene seis elementos en total:
  `describe-table` lo confirma. `gsi1` tiene 53, porque las líneas no llevan `GSI1PK` y tampoco
  entran: también es disperso, por tipo de elemento.
- **Las cuatro costaron 0,5 unidades.** Ninguna necesitó un `scan` ni un filtro, que es la prueba de
  que el diseño responde su tabla de patrones.

> **Veredicto:** un diseño está terminado cuando cada fila de la tabla de patrones tiene su orden y
> ninguna de esas órdenes es un `scan`.

---

## 7. ⚖️ Lo que se paga

**Escribir varios elementos a la vez**: crear un pedido son varios elementos —el pedido y sus
líneas—, y `TransactWriteItems` los escribe como una sola operación de todo o nada, hasta 100
acciones según la documentación. Aquí, intentando crear otra vez `PED-00042`, con la condición de
que no exista, junto con una línea nueva:

```text
$ aws dynamodb transact-write-items --transact-items file:///datos/dynamodb/transaccion.json

aws: [ERROR]: An error occurred (TransactionCanceledException) when calling the TransactWriteItems operation: Transaction cancelled, please refer cancellation reasons for specific reasons [ConditionalCheckFailed, None]

Additional error details:
CancellationReasons: <complex value>
Use "--cli-error-format json" or another error format to see the full details.

$ aws dynamodb query --table-name tienda --key-condition-expression "PK = :p" --expression-attribute-values '{":p":{"S":"PEDIDO#PED-00042"}}' --query 'Items[].SK.S' --output text
LINEA#01	LINEA#02	LINEA#03	PEDIDO
```

- **La condición de la primera acción falló y la transacción entera se canceló**: la lista de
  motivos dice `ConditionalCheckFailed` para el pedido y `None` para la línea, y `LINEA#04` no se
  escribió.
- **Cuesta el doble, y también si se cancela**: según la documentación, DynamoDB hace dos lecturas o
  escrituras de cada elemento, una para preparar y otra para confirmar, y esa capacidad se consume
  aunque la transacción no salga. No se observa en local, que tampoco lanza los conflictos entre
  transacciones concurrentes.

**Una pregunta que no estaba en la lista**: «los pedidos por estado». No hay índice para ella, así
que o se paga un `scan` como en `05` §4, o se crea un índice nuevo, que DynamoDB rellena con los
elementos existentes:

```text
$ aws dynamodb update-table --table-name tienda --attribute-definitions AttributeName=estado,AttributeType=S \
    --global-secondary-index-updates '[{"Create":{"IndexName":"por-estado","KeySchema":[{"AttributeName":"estado","KeyType":"HASH"}],"Projection":{"ProjectionType":"KEYS_ONLY"}}}]' \
    --query 'TableDescription.GlobalSecondaryIndexes[?IndexName==`por-estado`].[IndexName, IndexStatus]' --output text
por-estado	CREATING
$ aws dynamodb describe-table --table-name tienda --query 'Table.GlobalSecondaryIndexes[?IndexName==`por-estado`].[IndexName, IndexStatus, ItemCount]' --output text
por-estado	ACTIVE	53
```

- **`CREATING` es el relleno**: el índice lee la tabla entera y copia cada elemento que tenga la
  clave. En local tardó menos de dos segundos con 231 elementos; en AWS, la documentación describe
  una fase de relleno que consume capacidad y, con una clave mal repartida, puede estrangular las
  escrituras de la tabla mientras dura. El índice se borró a continuación.

La cuenta completa del diseño: **duplicación** —el código del pedido está en `PK`, en `codigo` y en
`GSI1SK`—; **consistencia eventual** en los tres índices; **cada pregunta nueva es un índice nuevo
con relleno**, o un `scan`; y una tabla que no se entiende sin su tabla de patrones. En PostgreSQL,
la misma pregunta nueva es un `CREATE INDEX CONCURRENTLY`, y las viejas no se tocan.

> **Veredicto:** la tabla única hace barato lo previsto y caro lo imprevisto; se elige sabiendo que
> cada pregunta nueva se paga en una migración.

---

## 8. 🧭 Cómo se elige

**Tabla única o varias tablas.** La documentación de AWS recomienda el menor número de tablas, con
dos excepciones: series temporales de mucho volumen y datos con patrones de acceso muy distintos. En
la tienda, pedidos y líneas van juntos porque P1 los lee juntos; un registro de eventos con millones
de escrituras diarias iría en su tabla, con su propia clave y su caducidad.

**DynamoDB o PostgreSQL**, que es la pregunta de verdad:

| Si… | Entonces |
|---|---|
| Los patrones de acceso están escritos, son pocos y no cambian cada mes | DynamoDB los hace constantes a cualquier escala |
| Las preguntas se descubren sobre la marcha, o hay informes y agregaciones | PostgreSQL: el planificador responde lo que no estaba previsto |
| El volumen cabe en una instancia de PostgreSQL con réplicas | PostgreSQL, y un motor menos que operar |
| Hace falta escribir en muchas regiones, o picos que ninguna instancia aguanta | DynamoDB, pagando el método de este capítulo |

> **Veredicto:** DynamoDB se elige por la escala y la operación que te ahorra, y se paga con un
> esquema que solo responde las preguntas que escribiste antes; si no las tienes escritas, empieza
> por PostgreSQL.

---

## 9. 📜 Estándar, motor y convención

> **📜 Estándar o motor.** Nada de este capítulo está en ISO/IEC 9075. El modelo de claves es de
> DynamoDB, y el método —tabla única, sobrecarga de claves, índices dispersos— es **convención**,
> recogida en la documentación de AWS como recomendación, no como regla del motor.

| Afirmación | Estándar | PostgreSQL 18 | DynamoDB |
|---|---|---|---|
| El esquema se diseña antes de conocer las preguntas | Es lo habitual en relacional | Sí: se normaliza y se indexa después | No: primero los patrones de acceso |
| Una clave repetida da error | `PRIMARY KEY` y `UNIQUE` | Sí, `23505` | No: `put-item` reemplaza; hace falta una condición |
| Hay restricciones de unicidad aparte de la clave | Sí, `UNIQUE` | Sí | No |
| Leer un objeto con sus partes es una sola operación | — | Un `JOIN` | Una `query`, si comparten partición |
| Escribir varias filas es atómico | Sí, la transacción | Sí | Con `TransactWriteItems`, hasta 100 acciones y a doble coste |
| Una pregunta nueva sale sin tocar el esquema | Sí | Sí; con índice, más rápida | No: índice nuevo con relleno, o `scan` |

**Convención, la que más se repite.** *«En DynamoDB hay que meter todo en una sola tabla»* — la
documentación recomienda pocas tablas, y ella misma exceptúa las series temporales grandes y los
datos con patrones muy distintos. La regla no es «una tabla»: es «lo que se lee junto, en la misma
partición».

---

## ⚠️ Errores frecuentes

| Se dice | Lo preciso |
|---|---|
| "Diseño las tablas y luego vemos qué consultamos" | En DynamoDB, una pregunta sin diseñar es un `scan` o un índice nuevo con relleno |
| "Si la clave se repite, DynamoDB da error" | `put-item` reemplaza en silencio; en un lote, el lote entero se rechaza |
| "Con `PRODUCTO#` como orden, las líneas son únicas" | 6 855 pedidos repiten producto; la clave hay que comprobarla contra los datos |
| "Tabla única significa una tabla para todo" | Las series temporales grandes y los patrones muy distintos van aparte, dice la documentación |
| "Un índice disperso es un índice con pocos datos" | Es uno cuya clave solo tienen algunos elementos: el que no la tiene no entra |
| "Una transacción cancelada no cuesta nada" | Cada elemento se cobra dos veces, salga o no; y hay un máximo de 100 acciones |
| "Añadir un índice es instantáneo" | Pasa por un relleno que lee la tabla entera y consume capacidad |

---

## 📚 Para profundizar

- **Documentación** — Amazon DynamoDB, «NoSQL design for DynamoDB»: por qué primero los patrones de
  acceso y pocas tablas.
  <https://docs.aws.amazon.com/amazondynamodb/latest/developerguide/bp-general-nosql-design.html>
- **Documentación** — Amazon DynamoDB, «Data modeling for DynamoDB tables»: tabla única frente a
  varias. <https://docs.aws.amazon.com/amazondynamodb/latest/developerguide/data-modeling.html>
- **Documentación** — Amazon DynamoDB, «Take advantage of sparse indexes».
  <https://docs.aws.amazon.com/amazondynamodb/latest/developerguide/bp-indexes-general-sparse-indexes.html>
- **Documentación** — Amazon DynamoDB, «Best practices for modeling relational data in DynamoDB».
  <https://docs.aws.amazon.com/amazondynamodb/latest/developerguide/bp-relational-modeling.html>
- **Documentación** — Amazon DynamoDB, «Amazon DynamoDB Transactions: How it works»: las 100
  acciones y el coste.
  <https://docs.aws.amazon.com/amazondynamodb/latest/developerguide/transaction-apis.html>
- **Documentación** — Amazon DynamoDB, «Managing Global Secondary Indexes»: el relleno de un índice
  nuevo. <https://docs.aws.amazon.com/amazondynamodb/latest/developerguide/GSI.OnlineOps.html>

---

## 🧠 Preguntas

1. ¿Cuáles son los cinco pasos del diseño desde el acceso? 🟢
2. ¿Qué es una tabla de patrones de acceso, y qué columnas lleva? 🟢
3. ¿Qué es un índice disperso? 🟢
4. Distingue el orden de diseño en PostgreSQL y en DynamoDB. 🟡
5. Distingue lo que hace `put-item` con una clave que ya existe de lo que hace un `INSERT` en
   PostgreSQL. ¿Lo decide el estándar o cada motor? 🟡
6. Distingue sobrecarga de claves, índice invertido e índice disperso, con el índice de la tienda
   que usa cada uno. 🟡
7. Tabla única frente a varias tablas: qué recomienda la documentación y qué exceptúa. 🟡
8. ¿Garantiza DynamoDB la unicidad de algún atributo aparte de la clave primaria, como un `UNIQUE`
   de SQL? 🟡
9. ¿Por qué el primer diseño de las líneas, con `PRODUCTO#` como clave de orden, estaba mal, y cómo
   lo descubriste antes de producción? 🟠
10. ¿Por qué `batch-write-item` rechazó 25 elementos por dos claves repetidas, y por qué es peor lo
    que hace `put-item`? 🟠
11. ¿Por qué el índice `pendientes` tiene 6 elementos y la tabla 231? ¿Qué pasa con un pedido cuando
    se paga? 🟠
12. ¿Por qué P1 responde con el pedido y sus líneas en una sola consulta, y qué tiene que ver la
    partición con eso? 🟠
13. ¿Qué cuesta una transacción en DynamoDB frente a escribir los elementos sueltos, y qué ganas? 🟠
14. Te piden «los pedidos por estado», que no estaba en la tabla de patrones. Da las dos salidas y
    lo que cuesta cada una. 🟠
15. Diseña la tabla de patrones y las claves para añadir los pagos a la tabla `tienda`: un pedido
    tiene cero o más pagos, y se consultan por pedido y por referencia del proveedor. 🔴
16. Diagnostica: tras migrar a DynamoDB, algunos pedidos aparecen con menos unidades de las que
    compró el cliente, sin ningún error en los registros. Da la causa más probable y la corrección.
    🔴
17. Defiende ante un equipo si la tienda debería estar en DynamoDB o en PostgreSQL, con tres
    argumentos por cada lado y la pregunta que harías para decidir. 🔴
18. Diseña la consulta y la clave para «los últimos diez pedidos de la tienda entera», a 1 000
    pedidos nuevos por segundo, sin crear una partición caliente. 🔴

---

**Anterior:** [`05`](05-dynamodb-modelo-y-claves.md) — DynamoDB: el modelo y las claves ·
**Siguiente:** [`07`](07-simulacion-de-entrevista.md) — la simulación del bloque · **Relacionado:**
[`01/05`](../01-fundamentos-y-modelo-relacional/05-del-modelo-er-al-esquema.md) — el camino
contrario, del modelo al esquema · [`05`](05-dynamodb-modelo-y-claves.md) §6 — la partición
caliente.
