# 05 — DynamoDB: el modelo y las claves

> DynamoDB es clave-valor en disco, gestionado por AWS, y todo en él se decide con dos claves: la de
> **partición**, que reparte los datos entre máquinas, y la de **orden**, que los ordena dentro de
> cada partición. Este capítulo carga los pedidos de la tienda en DynamoDB Local y enseña, con la
> capacidad consumida que devuelve cada orden, qué se puede preguntar barato, qué se puede preguntar
> caro y qué no se puede preguntar: el filtro que devuelve 9 elementos y cobra 52, el `scan` que lee
> la tabla entera y el índice global que no admite lectura fuerte. **Asume leído:**
> [`01`](01-el-modelo-clave-valor.md), el modelo clave-valor y su ficha. **Vigencia:** 27 de
> septiembre de 2026.

---

## Salto rápido

- [1. El problema](#1--el-problema) · [2. La tabla y sus dos
  claves](#2--la-tabla-y-sus-dos-claves)
- [3. Query: una partición, en orden](#3--query-una-partición-en-orden) · [4. Lo que no es
  clave](#4--lo-que-no-es-clave)
- [5. Índices: local y global](#5--índices-local-y-global) · [6. Capacidad y partición
  caliente](#6--capacidad-y-partición-caliente)
- [7. Estándar, motor y convención](#7--estándar-motor-y-convención) · [Errores
  frecuentes](#️-errores-frecuentes) · [Preguntas](#-preguntas)

---

## 1. 🎯 El problema

Un equipo pasa los pedidos a DynamoDB porque le prometen milisegundos a cualquier escala y ninguna
base que administrar. La primera semana va bien: la pantalla «mis pedidos» lee los de un cliente en
un instante. La segunda, alguien pide un panel con **cuántos pedidos están `PAGADO`**, y el
desarrollador escribe lo que escribiría en SQL. Con 242 pedidos de prueba, DynamoDB responde bien y
dice lo que cobró:

```text
"Count": 57,
"ScannedCount": 242,
"CapacityUnits": 8.5
```

Leyó los 242 para devolver 57. Con un millón de pedidos serían unas treinta y cinco mil unidades de
capacidad por cada vez que alguien abre el panel, y la cuenta de AWS lo cobra. Nada falló: la
tabla simplemente no estaba hecha para esa pregunta.

A la pregunta de [`01`](01-el-modelo-clave-valor.md), «dame esta clave», DynamoDB añade «dame, en
orden, un tramo de esta partición», y los índices alguna más. **Todo lo demás se paga leyendo la
tabla entera.**

> **📝 Contexto.** Todo está corrido contra **DynamoDB Local 3.3.1** (`bd-lab-dynamodb`), con la CLI
> `amazon/aws-cli:2.37.4`, los dos con el perfil `dynamodb` del `compose`. En las sesiones, `aws`
> abrevia `docker compose -f 13-laboratorio/entorno/docker-compose.yml run --rm -q aws`, que es la
> misma orden con el contenedor delante. **DynamoDB Local no reproduce tres cosas**, según su
> documentación: ignora la capacidad aprovisionada, no particiona la tabla, y sus lecturas
> eventuales parecen fuertes porque todo va en la misma máquina. Por eso la estrangulación y la
> partición caliente de §6 se explican por mecanismo y con las cifras de AWS, **sin sesión**. Lo que
> sí calcula es la capacidad consumida, y esas cifras son las de las sesiones. `PED-00042` se cambió
> de estado en §5 y se devolvió a `PAGADO`. **Longitud:** unas 540 líneas; capítulo
> normal que pasa el disparador de 500, podado en prosa: 168 líneas de sesión, por debajo de las 180
> del denso.

---

## 2. 🧱 La tabla y sus dos claves

**Qué es:** una tabla de DynamoDB es un conjunto de **elementos** (*items*), cada uno con atributos,
y lo único obligatorio es la **clave primaria**. Puede ser simple —solo clave de partición— o
compuesta, con clave de **partición** y clave de **orden**. La de pedidos es compuesta:

- **Partición: `cliente`.** DynamoDB aplica una función hash al valor y con ella decide en qué
  partición física vive el elemento. Todos los pedidos de `CLI-00311` viven juntos.
- **Orden: `fecha_pedido`.** Dentro de la partición, los elementos se guardan ordenados por ella.
  Su valor junta la marca de tiempo UTC y el código —`2025-02-21T03:08:09Z#PED-00042`—: la fecha da
  el orden y el código hace única la clave aunque dos pedidos coincidan en el segundo.

```bash
aws dynamodb create-table --table-name pedidos \
  --attribute-definitions AttributeName=cliente,AttributeType=S AttributeName=fecha_pedido,AttributeType=S \
                          AttributeName=total,AttributeType=N AttributeName=estado,AttributeType=S \
  --key-schema AttributeName=cliente,KeyType=HASH AttributeName=fecha_pedido,KeyType=RANGE \
  --local-secondary-indexes 'IndexName=por-total,KeySchema=[{AttributeName=cliente,KeyType=HASH},{AttributeName=total,KeyType=RANGE}],Projection={ProjectionType=ALL}' \
  --global-secondary-indexes 'IndexName=por-estado,KeySchema=[{AttributeName=estado,KeyType=HASH},{AttributeName=fecha_pedido,KeyType=RANGE}],Projection={ProjectionType=KEYS_ONLY}' \
  --billing-mode PAY_PER_REQUEST --query 'TableDescription.{estado:TableStatus,claves:KeySchema}'
```

- `--attribute-definitions` declara **solo los atributos que son clave** de la tabla o de algún
  índice, con su tipo: `S` cadena, `N` número. Los demás no se declaran: cada elemento trae los que
  quiera.
- `--key-schema` dice cuál es cada clave: `HASH` es la de partición y `RANGE` la de orden. Los dos
  índices, `por-total` y `por-estado`, son la materia de §5.
- `--billing-mode PAY_PER_REQUEST` es el modo **bajo demanda**: se paga por petición, sin reservar
  capacidad. `--query` filtra la respuesta en la CLI para enseñar solo el estado y las claves.

```text
{
    "estado": "ACTIVE",
    "claves": [
        {
            "AttributeName": "cliente",
            "KeyType": "HASH"
        },
        {
            "AttributeName": "fecha_pedido",
            "KeyType": "RANGE"
        }
    ]
}
```

Los datos salen de PostgreSQL: los pedidos de los diez clientes `CLI-0031_` y `PED-00042`, **242
elementos**, con sus líneas dentro como lista de mapas. Una consulta escribe cada elemento en el
formato de DynamoDB y los agrupa de 25 en 25, que es lo máximo que admite una escritura por lotes:

```sql
SELECT json_build_object('pedidos', json_agg(json_build_object('PutRequest', json_build_object('Item', item))))
  FROM (SELECT (row_number() OVER (ORDER BY p.id) - 1) / 25 AS lote,
               json_build_object(
                 'cliente',      json_build_object('S', c.codigo),
                 'fecha_pedido', json_build_object('S', to_char(p.creado_en AT TIME ZONE 'UTC',
                                                   'YYYY-MM-DD"T"HH24:MI:SS"Z"') || '#' || p.codigo),
                 'codigo',       json_build_object('S', p.codigo),
                 'estado',       json_build_object('S', p.estado),
                 'total',        json_build_object('N', p.total::text),
                 'lineas',       json_build_object('L', (SELECT json_agg(json_build_object('M', json_build_object(
                                     'producto',    json_build_object('S', pr.codigo),
                                     'cantidad',    json_build_object('N', l.cantidad::text),
                                     'precio_unit', json_build_object('N', l.precio_unit::text)))
                                   ORDER BY l.linea)
                                   FROM pedido_lineas l JOIN productos pr ON pr.id = l.producto_id
                                  WHERE l.pedido_id = p.id))) AS item
          FROM pedidos p JOIN clientes c ON c.id = p.cliente_id
         WHERE c.codigo LIKE 'CLI-0031_' OR p.codigo = 'PED-00042') AS t
 GROUP BY lote ORDER BY lote;
```

```bash
psql -h 127.0.0.1 -U postgres -d tienda -At -f lotes-dynamodb.sql \
  | split -l 1 -d -a 2 - 13-laboratorio/entorno/datos/dynamodb/lote-
for f in 13-laboratorio/entorno/datos/dynamodb/lote-*; do
  aws dynamodb batch-write-item --request-items "file:///datos/dynamodb/$(basename $f)" \
    --query 'length(UnprocessedItems)'
done
```

- **Cada valor lleva su tipo**: `{"S": "CLI-00311"}`, `{"N": "3186.23"}`, y `L` y `M` para lista y
  mapa. El número viaja como texto y DynamoDB lo guarda como decimal exacto, así que `total` no
  pierde céntimos.
- `split -l 1` deja cada lote en su fichero, que la CLI lee desde `/datos`. Los diez respondieron
  `0` elementos sin procesar, y un `scan` con `--select COUNT` contó **242**.

Leer un elemento pide **la clave entera**. Con solo la de partición, el error; con las dos, el
pedido:

```text
$ aws dynamodb get-item --table-name pedidos --key '{"cliente":{"S":"CLI-26446"}}'

aws: [ERROR]: An error occurred (ValidationException) when calling the GetItem operation: The number of conditions on the keys is invalid

$ aws dynamodb get-item --table-name pedidos \
    --key '{"cliente":{"S":"CLI-26446"},"fecha_pedido":{"S":"2025-02-21T03:08:09Z#PED-00042"}}' \
    --projection-expression "codigo, estado, #t" --expression-attribute-names '{"#t":"total"}'
{
    "Item": {
        "codigo": {
            "S": "PED-00042"
        },
        "estado": {
            "S": "PAGADO"
        },
        "total": {
            "N": "3186.23"
        }
    }
}
```

- `CLI-26446` es el cliente de `PED-00042`, sacado de PostgreSQL. **Sin él, DynamoDB no puede
  encontrar el pedido**: no hay forma de pedir «el pedido `PED-00042`» si no sabes de quién es. Esa
  pregunta necesita otro índice, y es de `06`.
- `#t` sustituye a `total` porque `TOTAL` es palabra reservada de DynamoDB; el nombre real va en
  `--expression-attribute-names`.

**Quién lo manda:** **motor**. **Cuánto:** la clave es irreversible —cambiarla es otra tabla y
copiar—, y un elemento ocupa como mucho 400 KB (§6). **Cuándo sí:** preguntas siempre por «lo de
este cliente». **Cuándo no:** si aún no sabes qué preguntarás.

> **Veredicto:** en DynamoDB la clave de partición decide dónde vive el dato y la de orden cómo se
> recorre; elegirlas es elegir las preguntas que serán baratas, antes de tener un solo dato.

---

## 3. 🧱 Query: una partición, en orden

**Qué es:** `query` lee **una sola partición** y, dentro de ella, un tramo de la clave de orden: un
valor exacto, un rango, o un prefijo. Los tres pedidos más recientes de 2025 de `CLI-00311`, primero
con lectura eventual y después fuerte:

```text
$ aws dynamodb query --table-name pedidos \
    --key-condition-expression "cliente = :c AND begins_with(fecha_pedido, :a)" \
    --expression-attribute-values '{":c":{"S":"CLI-00311"},":a":{"S":"2025"}}' \
    --no-scan-index-forward --limit 3 --return-consumed-capacity TOTAL \
    --query '{codigos: Items[].codigo.S, capacidad: ConsumedCapacity.CapacityUnits, sigue_en: LastEvaluatedKey.fecha_pedido.S}'
{
    "codigos": [
        "PED-418201",
        "PED-991372",
        "PED-352201"
    ],
    "capacidad": 0.5,
    "sigue_en": "2025-07-07T11:33:41Z#PED-352201"
}
$ aws dynamodb query … --consistent-read …
{
    "codigos": [
        "PED-418201",
        "PED-991372",
        "PED-352201"
    ],
    "capacidad": 1.0,
    "sigue_en": "2025-07-07T11:33:41Z#PED-352201"
}
```

- **`begins_with(fecha_pedido, :a)` sobre la clave de orden** es lo que hace de «2025» una pregunta
  barata: los elementos ya están ordenados por esa clave, así que el tramo es contiguo. Por eso la
  fecha va delante en `fecha_pedido`.
- `--no-scan-index-forward` recorre al revés, del más reciente al más antiguo, y `--limit 3` para
  tras tres elementos. **`LastEvaluatedKey` es por dónde seguir**: la paginación de DynamoDB, que
  la segunda orden repite con `--exclusive-start-key`. Una respuesta nunca pasa de 1 MB.
- **La lectura fuerte costó el doble**: 1,0 unidades frente a 0,5. Es la regla de la documentación:
  una unidad de lectura da una lectura fuerte de hasta 4 KB por segundo, o dos eventuales. La
  segunda orden es la primera con `--consistent-read`; los puntos suspensivos sustituyen a las
  opciones repetidas.

**Qué es cada consistencia**: la **eventual** puede no ver una escritura de hace un instante; la
**fuerte** ve todo lo confirmado antes de la petición. En local devuelven lo mismo; en AWS, la
eventual es la opción por defecto.

**Quién lo manda:** **motor**. **Cuánto:** lo leído, por bloques de 4 KB; la fuerte, el doble.
**Cuándo sí:** «los de esta partición, en este orden». **Cuándo no:** lo que no empiece por un valor
exacto de la clave de partición.

> **Veredicto:** `query` es barato porque lee un tramo contiguo de una sola partición; la lectura
> fuerte se paga doble, así que se pide solo cuando leer lo recién escrito importa.

---

## 4. 🩺 Lo que no es clave

La pregunta del §1 —los pedidos `PAGADO`— tiene tres respuestas en esta tabla, y las tres se
corrieron:

```text
$ aws dynamodb query --table-name pedidos --key-condition-expression "estado = :e" \
    --expression-attribute-values '{":e":{"S":"PAGADO"}}'

aws: [ERROR]: An error occurred (ValidationException) when calling the Query operation: Query condition missed key schema element

$ aws dynamodb query --table-name pedidos --key-condition-expression "cliente = :c" \
    --filter-expression "estado = :e" \
    --expression-attribute-values '{":c":{"S":"CLI-00311"},":e":{"S":"PAGADO"}}' \
    --select COUNT --return-consumed-capacity TOTAL
{
    "Count": 9,
    "ScannedCount": 52,
    "ConsumedCapacity": {
        "TableName": "pedidos",
        "CapacityUnits": 2.0
    }
}

$ aws dynamodb scan --table-name pedidos --filter-expression "estado = :e" \
    --expression-attribute-values '{":e":{"S":"PAGADO"}}' --select COUNT --return-consumed-capacity TOTAL
{
    "Count": 57,
    "ScannedCount": 242,
    "ConsumedCapacity": {
        "TableName": "pedidos",
        "CapacityUnits": 8.5
    }
}
```

- **`estado` no es clave, y `query` no lo acepta**: el error dice que falta un elemento del esquema
  de clave. No hay un «`WHERE estado = …`» que DynamoDB resuelva solo.
- **El filtro se aplica después de leer, y se paga lo leído**: de los 52 pedidos de `CLI-00311`,
  nueve están `PAGADO`, y la capacidad es la de los 52. `Count` es lo devuelto; `ScannedCount`, lo
  leído y cobrado.
- **`scan` lee la tabla entera**, partición por partición: 242 elementos para devolver 57, 8,5
  unidades. Con un millón de pedidos, el mismo `scan` son unidades por millares, y en local ni
  siquiera se reparte en paralelo: la documentación dice que DynamoDB Local hace los `scan` en
  serie.

**Quién lo manda:** **motor**. **Cuánto:** en **dinero** y en **tiempo**. **Cuándo sí:** filtrar una
partición pequeña; un `scan` en una migración. **Cuándo no:** en el camino de una petición de
usuario.

> **Veredicto:** en DynamoDB, filtrar no ahorra lectura; o la pregunta cabe en una clave, o la
> tabla se lee entera y se paga entera.

---

## 5. 🧱 Índices: local y global

La salida para preguntar por otra cosa es un **índice secundario**: una copia de los elementos
organizada por otra clave. Hay dos, y son muy distintos:

| | Índice local (LSI) | Índice global (GSI) |
|---|---|---|
| Clave de partición | **La misma** que la tabla | Cualquier atributo |
| Clave de orden | Otra | Cualquier atributo |
| Cuándo se crea | Al crear la tabla | Cuando quieras |
| Lectura fuerte | Sí | **No**: siempre eventual |
| Cuántos por tabla | Hasta 5 | Hasta 20, por defecto |
| Límite propio | 10 GB por valor de la clave de partición | Su propia capacidad |

Las cifras son las de la documentación de AWS. En la tabla de pedidos hay uno de cada:

```text
$ aws dynamodb query --table-name pedidos --index-name por-total --key-condition-expression "cliente = :c" \
    --expression-attribute-values '{":c":{"S":"CLI-00311"}}' --no-scan-index-forward --limit 3 \
    --consistent-read --query 'Items[].[codigo.S, total.N]' --output text
PED-717934	14222.43
PED-925005	13679.27
PED-457687	10731.94

$ aws dynamodb query --table-name pedidos --index-name por-estado --key-condition-expression "estado = :e" \
    --expression-attribute-values '{":e":{"S":"PAGADO"}}' --select COUNT --return-consumed-capacity TOTAL
{
    "Count": 57,
    "ScannedCount": 57,
    "ConsumedCapacity": {
        "TableName": "pedidos",
        "CapacityUnits": 0.5
    }
}

$ aws dynamodb query --table-name pedidos --index-name por-estado --key-condition-expression "estado = :e" \
    --expression-attribute-values '{":e":{"S":"PAGADO"}}' --select COUNT --consistent-read

aws: [ERROR]: An error occurred (ValidationException) when calling the Query operation: Consistent reads are not supported on global secondary indexes
```

- **`por-total` ordena los pedidos de cada cliente por importe**: los tres más caros de `CLI-00311`,
  con lectura fuerte, que un índice local admite.
- **`por-estado` responde la pregunta del §1 por 0,5 unidades**, frente a 8,5 del `scan`: lee solo
  los 57 que busca. Su proyección es `KEYS_ONLY` —guarda las claves y nada más—, así que para ver el
  total de cada uno habría que leer la tabla elemento a elemento. Proyectar más atributos cuesta
  espacio y escritura.
- **La lectura fuerte en un índice global da error**: la documentación dice que se actualizan de
  forma asíncrona. Tras escribir un pedido, puede tardar en aparecer en `por-estado`.

El precio de los índices se ve al escribir. Cambiar el estado de `PED-00042`, pidiendo la capacidad
desglosada:

```text
$ aws dynamodb update-item --table-name pedidos \
    --key '{"cliente":{"S":"CLI-26446"},"fecha_pedido":{"S":"2025-02-21T03:08:09Z#PED-00042"}}' \
    --update-expression "SET estado = :e" --expression-attribute-values '{":e":{"S":"ENVIADO"}}' \
    --return-consumed-capacity INDEXES
{
    "ConsumedCapacity": {
        "TableName": "pedidos",
        "CapacityUnits": 4.0,
        "Table": {
            "CapacityUnits": 1.0
        },
        "LocalSecondaryIndexes": {
            "por-total": {
                "CapacityUnits": 1.0
            }
        },
        "GlobalSecondaryIndexes": {
            "por-estado": {
                "CapacityUnits": 2.0
            }
        }
    }
}
```

- **Una escritura, cuatro unidades**: una en la tabla, una en el índice local —que proyecta el
  elemento entero— y dos en el global, porque `estado` es su clave: la entrada vieja se borra y se
  inserta otra. La misma orden con `PAGADO` lo devolvió a su estado, y costó lo mismo.

**Quién lo manda:** **motor**. **Cuánto:** cada índice multiplica la escritura y ocupa su espacio.
**Cuándo sí:** preguntas frecuentes que la clave no responde. **Cuándo no:** preguntas raras, que
salen más baratas con un `scan` de vez en cuando.

> **Veredicto:** un índice global es una pregunta más que pagas en cada escritura; el local es más
> barato y admite lectura fuerte, pero solo cambia el orden dentro de la misma partición y hay que
> declararlo el día que nace la tabla.

---

## 6. 🧱 Capacidad y partición caliente

**Qué es la capacidad:** DynamoDB mide el trabajo en unidades. Según su documentación, **una unidad
de lectura** (RCU) es una lectura fuerte por segundo de hasta 4 KB, o dos eventuales; **una unidad
de escritura** (WCU) es una escritura por segundo de hasta 1 KB. En modo **aprovisionado** reservas
unidades por segundo y pagas la reserva; en modo **bajo demanda**, como la tabla de este capítulo,
pagas cada petición.

**Qué es la partición caliente:** la tabla se reparte en particiones físicas por el hash de la clave
de partición, y **cada partición da como mucho 3 000 unidades de lectura y 1 000 de escritura por
segundo**, dice la documentación de AWS. Si una clave de partición recibe más, esas peticiones se
**estrangulan** (*throttling*) aunque la tabla entera tenga capacidad de sobra. Dos ejemplos en esta
tabla:

- **La partición de `cliente`** reparte bien: miles de clientes, cada uno con pocos pedidos. Solo
  un cliente gigante —un mayorista con millones de pedidos— se acercaría al límite.
- **El índice `por-estado` tiene cinco valores de partición**. Todo pedido nuevo entra `PENDIENTE`,
  así que con 1 000 pedidos por segundo, **todas** las escrituras del índice van a la misma
  partición y chocan con el techo de 1 000 unidades. Es la partición caliente de manual, y la puso
  un índice, no la tabla.

> **📝 Contexto.** Nada de esta sección se observa en DynamoDB Local, que ignora la capacidad y no
> particiona: lo dice su documentación. En AWS se vería con las métricas de estrangulación de
> CloudWatch y con los errores `ProvisionedThroughputExceededException` en la aplicación. La
> documentación añade que la **capacidad adaptativa** sube la capacidad de las particiones más
> activas y separa en particiones distintas los elementos más pedidos, **siempre que el tráfico no
> pase del máximo de la partición**: suaviza los picos, no levanta el techo.

El otro límite sí se provoca en local: **400 KB por elemento**. Un pedido con un atributo de
409 600 caracteres:

```text
$ aws dynamodb put-item --table-name pedidos --item file:///datos/dynamodb/grande.json

aws: [ERROR]: An error occurred (ValidationException) when calling the PutItem operation: Item size has exceeded the maximum allowed size
```

- El fichero, generado aparte y borrado después, pesaba 409 709 bytes. Un pedido con sus líneas
  dentro nunca se acerca, pero un historial de eventos que crece dentro del mismo elemento sí: el
  límite obliga a partirlo en varios elementos, que es lo que `06` hace con la clave de orden.

**Quién lo manda:** **motor**, y la factura. **Cuánto:** unidades redondeadas por bloques de 4 KB y
1 KB. **Cuándo sí:** claves con muchos valores y tráfico repartido. **Cuándo no:** claves con pocos
valores —un estado, la fecha del día—.

> **Veredicto:** en DynamoDB la escala es la del valor más popular de la clave de partición, no la
> de la tabla; una clave con cinco valores es una tabla de cinco particiones.

---

## 7. 📜 Estándar, motor y convención

> **📜 Estándar o motor.** DynamoDB es su propia especificación, y su API no se parece a ISO/IEC
> 9075. Tiene PartiQL, un lenguaje con sintaxis parecida a SQL, y su documentación avisa de que un
> `SELECT` sin igualdad sobre la clave de partición puede acabar en un `scan` de la tabla entera:
> `WHERE estado = 'PAGADO'` devolvió los mismos 57 pedidos.

| Afirmación | Estándar | PostgreSQL 18 | DynamoDB |
|---|---|---|---|
| Se puede preguntar por cualquier columna | SQL, 9075-2 | Sí; con índice o sin él, el plan lo decide el motor | No: solo por clave o índice; lo demás es `scan` |
| Filtrar reduce el trabajo | — | Con un índice, sí | No: se paga lo leído, 52 para devolver 9 |
| Un índice secundario ve la escritura al instante | — | Sí, en la misma transacción | El local sí; el global, de forma eventual |
| La lectura fuerte es la opción por defecto | — | Todas lo son, en el nivel de aislamiento elegido | No: la eventual, a mitad de precio |
| Hay un tamaño máximo de fila | — | 1 GB por campo, con TOAST | 400 KB por elemento |
| El rendimiento depende de cómo se repartan los valores | — | Poco, con un B-tree | Mucho: 1 000 escrituras por segundo por partición |
| Un número decimal se guarda exacto | `DECIMAL` | `numeric` | `N`, decimal exacto enviado como texto |

**Convención, la que más se repite.** *«DynamoDB escala infinitamente»* — escala repartiendo por la
clave de partición, y solo tanto como esa clave esté repartida. Una clave con pocos valores, o un
índice global sobre un estado, pone un techo de mil escrituras por segundo a una tabla que podría
dar millones.

---

## ⚠️ Errores frecuentes

| Se dice | Lo preciso |
|---|---|
| "Pongo un filtro y DynamoDB lee menos" | Se lee y se cobra lo mismo; el filtro solo recorta lo que vuelve: 52 leídos para 9 devueltos |
| "Con el código del pedido lo encuentro" | Sin la clave de partición no hay `get-item`; buscar por otro atributo necesita un índice |
| "El índice global es como el de SQL" | Es una copia asíncrona, sin lectura fuerte, que cuesta escritura extra: dos unidades al cambiar su clave |
| "Añado un índice local cuando lo necesite" | Se declara al crear la tabla; después ya no |
| "Bajo demanda no hay partición caliente" | El techo de 3 000 y 1 000 unidades es por partición, en los dos modos |
| "DynamoDB Local sirve para probar el rendimiento" | Ignora la capacidad y no particiona; sirve para la API y el modelo, no para la escala |
| "La lectura fuerte y la eventual cuestan lo mismo" | La fuerte, el doble: 1,0 unidades frente a 0,5 en la misma consulta |

---

## 📚 Para profundizar

- **Documentación** — Amazon DynamoDB, «Best practices for designing and using partition keys
  effectively»: el techo por partición y la capacidad adaptativa.
  <https://docs.aws.amazon.com/amazondynamodb/latest/developerguide/bp-partition-key-design.html>
- **Documentación** — Amazon DynamoDB, «DynamoDB read consistency».
  <https://docs.aws.amazon.com/amazondynamodb/latest/developerguide/HowItWorks.ReadConsistency.html>
- **Documentación** — Amazon DynamoDB, «Local secondary indexes».
  <https://docs.aws.amazon.com/amazondynamodb/latest/developerguide/LSI.html>
- **Documentación** — Amazon DynamoDB, «Using Global Secondary Indexes in DynamoDB».
  <https://docs.aws.amazon.com/amazondynamodb/latest/developerguide/GSI.html>
- **Documentación** — Amazon DynamoDB, «DynamoDB provisioned capacity mode»: qué es una unidad.
  <https://docs.aws.amazon.com/amazondynamodb/latest/developerguide/provisioned-capacity-mode.html>
- **Documentación** — Amazon DynamoDB, «Constraints in Amazon DynamoDB»: los 400 KB y los tipos.
  <https://docs.aws.amazon.com/amazondynamodb/latest/developerguide/Constraints.html>
- **Documentación** — Amazon DynamoDB, «DynamoDB local usage notes»: lo que no reproduce.
  <https://docs.aws.amazon.com/amazondynamodb/latest/developerguide/DynamoDBLocal.UsageNotes.html>
- **Documentación** — Amazon DynamoDB, «Burst and adaptive capacity»: lo que la capacidad adaptativa
  hace y lo que no.
  <https://docs.aws.amazon.com/amazondynamodb/latest/developerguide/burst-adaptive-capacity.html>

---

## 🧠 Preguntas

1. ¿Qué son la clave de partición y la clave de orden de una tabla de DynamoDB? 🟢
2. ¿Qué es una unidad de lectura y una de escritura en DynamoDB? 🟢
3. ¿Qué devuelve `LastEvaluatedKey` en una `query`, y para qué sirve? 🟢
4. ¿Qué diferencia hay entre `Count` y `ScannedCount`? 🟢
5. Distingue `query` de `scan`: qué lee cada una y qué cuesta. ¿Lo fija el estándar o es cosa del
   motor? 🟡
6. Distingue índice secundario local de global: clave, consistencia y cuándo se crean. 🟡
7. Distingue lectura eventual de lectura fuerte, con su precio medido. 🟡
8. ¿Hay en DynamoDB un lenguaje estándar para preguntar por cualquier atributo, como en SQL? ¿Qué
   hace PartiQL con una consulta sin clave? 🟡
9. ¿Qué garantiza PostgreSQL sobre un índice secundario que DynamoDB no garantiza sobre un índice
   global? 🟡
10. ¿Por qué `fecha_pedido` lleva la fecha delante y el código detrás? 🟠
11. ¿Por qué el filtro sobre `estado` cobró 2,0 unidades para devolver nueve pedidos? 🟠
12. ¿Por qué cambiar el estado de un pedido costó cuatro unidades de escritura, y de dónde sale cada
    una? 🟠
13. ¿Por qué el índice `por-estado` produce una partición caliente aunque la tabla reparta bien? 🟠
14. ¿Qué no puedes probar con DynamoDB Local, y qué sí? 🟠
15. ¿Por qué no se puede leer `PED-00042` sin saber que es de `CLI-26446`, y qué harías para
    poder? 🟠
16. Diseña la clave de una tabla de DynamoDB para los eventos de pedido, con un millón de eventos
    diarios y consultas por pedido y por intervalo de tiempo, y di qué índice añadirías para «los
    eventos de hoy». 🔴
17. Diagnostica: la tabla de pedidos está bajo demanda, con capacidad de sobra según la consola, y
    la aplicación recibe errores de estrangulación cada vez que entra una oleada de pedidos
    nuevos. Da la causa más probable y cómo la confirmarías. 🔴
18. Te piden en DynamoDB el panel «cuántos pedidos hay en cada estado», actualizado al minuto. Da
    tres diseños con lo que cuesta cada uno, y di cuál montarías. 🔴

---

**Anterior:** [`04`](04-cache-invalidacion-y-estampida.md) — caché, invalidación y estampida ·
**Siguiente:** [`06`](06-dynamodb-diseno-desde-el-acceso.md) — el diseño desde el acceso ·
**Relacionado:** [`01`](01-el-modelo-clave-valor.md) §5 — la ficha del modelo clave-valor ·
[`03/02`](../03-el-motor-por-dentro/02-familias-de-indices.md) — el índice de PostgreSQL, que ve la
escritura en la misma transacción.
