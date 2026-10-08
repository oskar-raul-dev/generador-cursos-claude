# 08 — Saga coreografiada

Este taller es **opcional** y depende de [`07` — Observabilidad de extremo a extremo](07-observabilidad-de-extremo-a-extremo.md):
parte de su sistema. Hasta aquí, dar de alta un pedido reservaba el stock **en el mismo acto** por
gRPC, y el cliente recibía `201` o `409`. Ahora nace el contrato `v2`: el alta responde `202 Accepted`
con el pedido en `PENDING`, y una **saga sin dueño** decide después. `inventory` (Go) reserva al ver
`OrderPlaced`, `payments` (Python) cobra al ver `InventoryReserved`, `inventory` libera al ver
`PaymentRejected`, y `orders` (Java) va moviendo el estado con lo que oye. `v1` sigue funcionando y
anuncia su retirada con `Deprecation` y `Sunset`. Las provocaciones son las que predice la teoría: un
pedido del que **nadie sabe en qué estado está**, y un **ciclo de eventos** que ningún servicio ve
entero. Termina con las suites `v1` y `v2` en verde y las tres ramas de la saga con su salida.

> Ejercita [`03/03` — Saga](../03-datos-y-consistencia/03-saga.md) §1–§3 y §6–§7, y
> [`02/07` — Contratos y versionado](../02-comunicacion/07-contratos-y-versionado.md).
>
> **Vigencia:** 2026-09-29. Versiones verificadas ese día en PyPI y en el BOM de Spring Boot 4.1.1;
> normas en rfc-editor.org; salidas corridas ese día en un Apple M1 Pro con Docker Desktop.

**Salto rápido:** [1](#1--qué-enseña-este-taller) · [2](#2--prerrequisitos-y-versiones) · [3](#3-️-mapa-de-carpetas) · [4](#4--recorrido-de-la-base-de-código) · [5](#5--la-saga-en-tres-ramas) · [6](#6--v1-sigue-y-anuncia-su-retirada) · [7](#7--provocación-en-qué-estado-está-este-pedido) · [8](#8--provocación-el-ciclo) · [9](#9--errores-reales-al-correrlo) · [10](#10--en-tres-plataformas) · [11](#11--teardown) · [Preguntas](#-preguntas) · [Ejercicios](#-ejercicios)

---

## 1. 🎯 Qué enseña este taller

```text
cliente ── POST /api/v2/orders ──► orders: tx { pedido PENDING + outbox(OrderPlaced) } ──► 202 PENDING
                                     │
                           orders.placed
                                     ▼
                  inventory: tx { inbox + retener + outbox(InventoryReserved | …Failed) }
                                     │
                        inventory.reservations ──────────────────────────► orders: PENDING → CONFIRMED | CANCELLED
                                     ▼
                  payments: inbox? → PSP (clave saga-<orderId>) → tx { inbox + pago + outbox(Payment…) }
                                     │
                           payments.results ─────────────────────────────► orders: → PAID | PAYMENT_REJECTED
                                     ▼
                  inventory: PaymentAuthorized → vender · PaymentRejected → liberar + outbox(InventoryReleased)
cliente ── GET /api/v2/orders/{id} (hasta un estado final) ──► orders
```

Cuatro ideas:

- **La consistencia eventual se filtra al contrato.** Si la reserva es asíncrona, `orders` no sabe al
  responder si habrá stock. Esconderlo —esperar a la saga antes de contestar— es reinventar el 2PC con
  peor cara; decirlo es un `202` y un estado `PENDING` que el cliente consulta.
- **En una coreografía nadie manda.** Cada servicio reacciona a un hecho y publica otro, y cada uno
  necesita las piezas de `06/06`: outbox para publicar, inbox para consumir, DLQ para lo imposible. La
  lógica de la saga está repartida en tres archivos de tres lenguajes; ninguno la contiene entera.
- **"¿En qué estado está este pedido?" no tiene dónde contestarse.** El estado de `orders` es una
  proyección de hechos ajenos. Si un hecho no llega, cada servicio da su versión y nadie tiene un plazo
  que venza.
- **Los ciclos no se ven en ningún archivo.** Una regla local razonable —"si liberaron el stock,
  reintenta la compra"— cierra un bucle que solo existe en el sistema completo.

El precio, en las cinco monedas: **latencia** (el cliente ve `PAID` a los ≈ 280 ms, dos rondas de
outbox después; antes lo sabía en la respuesta), **consistencia** (los cuatro participantes discrepan
mientras la saga corre, y para siempre si se atasca), **operación** (tres topics más con su DLQ, tres
grupos consumidores, tres publicadores), **dinero** (lo de Kafka ya se pagó en `06/06`; lo nuevo son
horas de diagnóstico) y **esfuerzo** (264 líneas de Java, 335 de Go —con la retención reescrita para
trabajar dentro de una transacción ajena— y 118 de Python sobre el taller 07).

## 2. 🧰 Prerrequisitos y versiones

| Herramienta | Versión fijada | Para qué |
|---|---|---|
| Todo lo de `06/07` | la de `06/07` §2 | el sistema completo, con trazas |
| `spring-kafka` | la del BOM de Boot 4.1.1 | `@KafkaListener`, `DefaultErrorHandler`, `DeadLetterPublishingRecoverer` en `orders` |
| `cramjam` | `2.13.0` | que `aiokafka` lea lo que `franz-go` comprime con snappy (§9) |

```text
python3 laboratorio/scripts/lab.py up
python3 laboratorio/scripts/lab.py seed --kafka                                   # con los consumidores PARADOS
python3 laboratorio/scripts/lab.py psp                                            # terminal 1
python3 laboratorio/scripts/lab.py inventory                                      # terminal 2
python3 laboratorio/scripts/lab.py payments                                       # terminal 3
python3 laboratorio/scripts/lab.py monolith --inventory remote --payments remote  # terminal 4
python3 laboratorio/scripts/lab.py orders                                         # terminal 5
```

- `seed --kafka` crea ahora también `orders.placed`, `inventory.reservations` y `payments.results` (3
  particiones cada uno) con su `.dlq`, y borra además el grupo `orders`, que ahora consume.
- `seed` recrea `outbox_events` y `processed_messages` en las tres bases: los tres servicios publican y
  consumen.
- Envoy enruta `/api/v2/orders` a `orders`.

Las órdenes nuevas:

```text
python3 laboratorio/scripts/lab.py suite --base-url http://localhost:28080 --dir v2
python3 laboratorio/scripts/lab.py buy --v2 [--sku SKU-002] [--qty 1] [--wait 10]
python3 laboratorio/scripts/lab.py saga-status ORDER_ID
python3 laboratorio/scripts/lab.py orders --saga-retry-on-release
```

- `suite --dir v2` corre `contrato/hurl/v2`: la rama feliz, la de sin stock, la de pago rechazado y los
  encabezados de obsolescencia de `v1`.
- `buy --v2` da de alta por `v2` y consulta el pedido cada 50 ms hasta un estado final (o hasta
  `--wait` segundos), imprimiendo cada cambio con su tiempo: es lo que ve el cliente.
- `saga-status` pregunta por un pedido a las cuatro partes —`orders` por su API, las retenciones de
  `inventory` y los pagos de `payments` en sus bases, y el registro de cobros del PSP— y lo imprime en
  cuatro líneas.
- `orders --saga-retry-on-release` activa la provocación del ciclo (§8).

> **📝 Contexto:** el código tal como queda al terminar este taller está congelado en
> `laboratorio/estados/08/`, y las rutas con número de línea se refieren a esa copia. Si ya existen
> talleres posteriores, añade `--estado 08` a cada orden de `lab.py`.

## 3. 🗂️ Mapa de carpetas

```text
laboratorio/estados/08/                            (lab.py --estado 08)
├── contrato/
│   ├── openapi.yaml                               2.0.0: /api/v2/orders (x-suite v2, x-taller 08); v1 de orders `deprecated`
│   ├── hurl/v2/                                   01-happy-path · 02-out-of-stock · 03-payment-rejected · 04-v1-deprecated
│   └── seed/                                      orders: PENDING, topic en el outbox, inbox · inventory y payments: + outbox_events
├── orders/.../
│   ├── web/OrderControllerV2.java                 202 + Location
│   ├── web/V1Deprecation.java                     Deprecation, Sunset, Link en /api/v1/orders
│   ├── service/OrderService.java                  createV2: PENDING + OrderPlaced en la misma transacción
│   └── saga/SagaListener.java · KafkaErrorConfig.java   la proyección del estado; reintentos y DLQ
├── inventory/internal/
│   ├── consumer/saga.go                           OrderPlaced → retener; PaymentRejected → liberar; PaymentAuthorized → vender
│   ├── store/store.go                             HoldTx, ReleaseTx, CommitTx, SagaStep
│   └── outbox/outbox.go                           el publicador de inventory
└── payments/app/
    ├── consumer.py                                authorize(): InventoryReserved → PSP → Payment…
    └── outbox.py                                  el publicador de payments
```

## 4. 🔎 Recorrido de la base de código

Rutas relativas a `laboratorio/estados/08/`.

**¿Dónde empieza la saga?** `orders/.../service/OrderService.java`, `createV2` (línea 83): guarda el pedido
en `PENDING` (línea 97) y registra `OrderPlaced` en `orders.placed` en la misma transacción (línea 98). La
respuesta que se guarda para la idempotencia es un `202` (línea 100). El controlador pone el `202` y el
`Location` en `web/OrderControllerV2.java`, líneas 34 y 36.

**¿Quién reserva?** `inventory/internal/consumer/saga.go`: `react` (línea 51) decide qué hace inventory con
cada hecho. `OrderPlaced` (línea 53) retiene con `store.HoldTx` y publica `InventoryReserved` copiando el
`total` del pedido (línea 64), que no es suyo. Todo pasa dentro de `store.SagaStep`
(`internal/store/store.go`, línea 233): inbox, efecto y hechos nuevos en una transacción.

**¿Quién cobra?** `payments/app/consumer.py`, `authorize` (línea 102): mira el inbox **antes** de llamar
(línea 113), llama al PSP fuera de toda transacción con la clave `saga-<orderId>` (línea 119) y registra
inbox, pago y hecho juntos (línea 131). Si el PSP no contesta a tiempo, no publica nada (línea 126).

**¿Quién sabe el estado?** Nadie; `orders` lo proyecta. `orders/.../saga/SagaListener.java`: un
`@KafkaListener` sobre los dos topics de resultados (línea 47), con inbox (línea 55) y una tabla de
transiciones (líneas 68–80) aplicada por `move` (línea 88), que ignora lo que llega fuera de orden. La
provocación del ciclo es `retry` (línea 111).

**¿Y los mensajes imposibles?** En Java, configuración: `saga/KafkaErrorConfig.java`, tres intentos con
200 ms (línea 21) y después `<topic>.dlq` (línea 20). En Go y Python, escrito a mano como en `06/06`.

## 5. 🧱 La saga en tres ramas

```text
python3 laboratorio/scripts/lab.py buy --v2 --sku SKU-002
python3 laboratorio/scripts/lab.py buy --v2 --sku SKU-004
python3 laboratorio/scripts/lab.py buy --v2 --sku SKU-005
```

- `SKU-002` tiene stock y cuesta 9,90: la rama feliz. `SKU-004` no tiene stock. `SKU-005` cuesta 1499,00
  y el PSP rechaza por encima de 1000,00.

2026-09-29:

```text
order v2 202 PENDING  28 ms  trace=692395149c4f41bf8ddf99c4de8701d3
  +    0 ms  PENDING   (52d44134-bf00-47c0-8787-14ea41e4818c)
  +  123 ms  CONFIRMED
  +  277 ms  PAID
order v2 202 PENDING  22 ms  trace=4c7166d4e9b747e089dae76bf7d2db35
  +    0 ms  PENDING   (67fb3d0c-c429-451d-9ede-6742b827055b)
  +  399 ms  CANCELLED
order v2 202 PENDING  24 ms  trace=52e0264a2a7b45819b47fd9841f02184
  +    0 ms  PENDING   (957d339f-1571-4a5f-9044-fdf0240aa153)
  +  271 ms  CONFIRMED
  +  451 ms  PAYMENT_REJECTED
orders     PAYMENT_REJECTED   (GET /api/v2/orders/957d339f…)
inventory  SKU-005×1 RELEASED
payments   REJECTED psp-d0f531e2
psp        sin cobro registrado
```

- El alta responde en 22–28 ms: ya no espera al inventario. El resultado llega entre 280 y 450 ms después,
  a golpe de rondas de outbox (una cada 200 ms en cada uno de los tres publicadores).
- El pedido sin stock era un `409` en `v1`; en `v2` es un `202` que termina `CANCELLED`. El cliente
  tiene que manejar el "no" **después**.
- En el rechazo, las cuatro partes coinciden: la compensación (liberar) cerró la saga.

La saga feliz entera, en la traza (sin los spans de base de datos):

```text
traza 692395149c4f41bf8ddf99c4de8701d3  ·  55 spans  ·  envoy, inventory, monolith, orders, payments
       0.0 ms     26.0 ms  envoy     server   ingress  http=202
       3.2 ms     24.0 ms    orders    server   POST /api/v2/orders  http=202
      70.9 ms     12.3 ms      orders    producer orders.placed publish  partition=1 offset=0
      83.4 ms      4.0 ms        inventory consumer orders.placed process  partition=1 offset=0 event=OrderPlaced verdict=InventoryReserved
     126.0 ms      4.3 ms          inventory producer inventory.reservations publish  event=InventoryReserved
     131.5 ms     14.3 ms            payments  consumer orders.events process  partition=1 offset=0 event=InventoryReserved
     133.7 ms      6.1 ms              payments  client   POST  http=201
     269.6 ms      7.3 ms              payments  producer payments.results publish  event=PaymentAuthorized
     277.7 ms      4.8 ms                inventory consumer payments.results process  partition=1 offset=0 event=PaymentAuthorized verdict=committed 1 lines
     279.5 ms     19.2 ms                orders    consumer payments.results process  partition=1 offset=0
     500.3 ms      9.8 ms                  orders    producer orders.events publish  partition=1 offset=0
     510.9 ms      2.0 ms                    inventory consumer orders.events process  partition=1 offset=0 event=OrderPaid verdict=applied
     511.3 ms      0.0 ms                    payments  consumer orders.events process  partition=1 offset=0 event=OrderPaid
     132.1 ms      9.0 ms            orders    consumer inventory.reservations process  partition=1 offset=0
```

- Los tres outboxes guardan el `traceparent` del mensaje que provocó cada hecho (`06/07`), así que la
  saga entera es una traza de 55 spans. Es la única vista completa que existe, y solo **a posteriori**:
  no se puede preguntar a una traza "¿en qué estado estás?".
- El árbol es la coreografía: nadie llama a nadie; cada nivel es un servicio reaccionando a un hecho.
- El span de `payments` dice `orders.events process` aunque lee `inventory.reservations`: el nombre
  salía de una constante. Corregido después de esa corrida (usa el topic del mensaje).

Las suites, contra Envoy, 2026-09-29:

```text
--- v1
Executed requests: 46 (14.6/s)
Succeeded files:   6 (100.0%)
--- v2
Executed requests: 22 (12.1/s)
Succeeded files:   4 (100.0%)
```

- `v1` sigue en verde **sin cambiar una línea**: los encabezados nuevos no rompen a un cliente que no los
  mira. La suite `v2` espera el estado final con `[Options] retry: 50` y `retry-interval: 200ms`: hasta
  10 s.

> **Veredicto:** la coreografía funciona, y rápido. Lo que cambió no es el rendimiento: es que el
> cliente ya no recibe una respuesta, recibe una promesa, y cada servicio necesita el kit completo de
> mensajería (outbox, inbox, DLQ) para cumplirla.

## 6. 🧱 `v1` sigue, y anuncia su retirada

**Qué es.** `v1` no cambia de comportamiento: sigue reservando por gRPC. Pero cada respuesta de
`/api/v1/orders` dice que está obsoleta, desde cuándo, cuándo dejará de existir y qué la sustituye.

```text
HTTP/1.1 201 Created
deprecation: @1790640000
sunset: Wed, 31 Mar 2027 00:00:00 GMT
link: </api/v2/orders>; rel="successor-version"
location: /api/v1/orders/57ecba78-f0ca-46ca-ac23-36ca06514910
```

- `Deprecation` (RFC 9745) es una fecha de Structured Fields: `@` y segundos desde 1970.
  `@1790640000` es el 2026-09-29 a las 00:00 UTC. Puede estar en el pasado (ya es obsoleto) o en el
  futuro (lo será).
- `Sunset` (RFC 8594) es un HTTP-date: el momento en que el recurso dejará de responder.
- `Link` con `rel="successor-version"` dice adónde migrar.
- En el `openapi.yaml`, las operaciones de `/api/v1/orders` llevan `deprecated: true`; el catálogo
  (`/api/v1/products`) no, porque no tiene sustituto.

> **Veredicto:** versionar en la ruta es la opción visible de [`02/07` §4](../02-comunicacion/07-contratos-y-versionado.md#4-️-cómo-se-versiona-de-verdad),
> y su coste es el que ese capítulo avisa: dos implementaciones vivas durante meses. Los encabezados
> convierten el "algún día lo quitaremos" en una fecha que un cliente puede leer y vigilar.

## 7. 🧨 Provocación: ¿en qué estado está este pedido?

```text
python3 laboratorio/scripts/lab.py buy --v2 --sku SKU-003 --qty 3 --wait 15
python3 laboratorio/scripts/lab.py saga-status 15b15be5-08f7-4384-b83e-4129c7e28166
```

- Tres monitores a 222,00 son 666,00: el importe con el que el PSP **cobra** pero contesta a los 3 s, y
  `payments` corta a los 2.

2026-09-29, y cinco minutos después:

```text
order v2 202 PENDING  18 ms  trace=b5f9c6185c334ce4acb8cc113a24396f
  +    0 ms  PENDING   (15b15be5-08f7-4384-b83e-4129c7e28166)
  +  126 ms  CONFIRMED
  sin estado final tras 15 s: sigue en CONFIRMED
WARNING [trace=b5f9c618] psp did not answer for 15b15be5 (saga-15b15be5-08f7-4384-b83e-4129c7e28166): ReadTimeout → PENDING, no fact published
--- 11:25:03
orders     CONFIRMED   (GET /api/v2/orders/15b15be5…)
inventory  SKU-003×3 HELD
payments   PENDING -
psp        psp-510f4741 666.00
--- 11:30:00
orders     CONFIRMED   (GET /api/v2/orders/15b15be5…)
inventory  SKU-003×3 HELD
payments   PENDING -
psp        psp-510f4741 666.00
```

- Cuatro respuestas, y ninguna es "la" respuesta. `orders` cree que el pedido espera el cobro;
  `inventory` retiene tres unidades que nadie más puede vender; `payments` no sabe si cobró; y el
  proveedor **cobró**. El cliente pagó y no tiene pedido.
- No hay error en ningún log salvo un `WARNING` en `payments`. Ningún proceso tiene un temporizador que
  venza, porque ninguno es dueño de la saga: cada uno terminó su parte.
- Para contestar a "¿en qué estado está?" hubo que escribir `saga-status`, que consulta **cuatro**
  sistemas y deja la reconciliación a quien lee. Es lo que [`03/03` §3](../03-datos-y-consistencia/03-saga.md#3--coreografía)
  llama "no hay un sitio donde mirar", convertido en un comando.

> **Veredicto:** en una coreografía, el estado de la saga no existe como dato: es una conclusión que se
> saca juntando las proyecciones de todos. Un plazo con dueño —"si en 30 s no hay resultado de pago,
> vuelve a preguntar o compensa"— necesita a alguien que lleve la cuenta, y eso es un orquestador (el
> [taller 09](09-saga-orquestada.md)).

## 8. 🧨 Provocación: el ciclo

```text
python3 laboratorio/scripts/lab.py orders --saga-retry-on-release
python3 laboratorio/scripts/lab.py buy --v2 --sku SKU-005 --wait 20
```

- `--saga-retry-on-release` activa en `orders` una regla que alguien podría proponer en una revisión con
  buena intención: "si `inventory` liberó el stock tras un rechazo, reintentamos la compra".

2026-09-29:

```text
order v2 202 PENDING  279 ms  trace=83a02e8a148249dfbd6dd76b835fd067
  +    0 ms  PENDING   (bbd64ab5-358d-4477-b094-f3d5be3a70b1)
  + 1045 ms  CONFIRMED
  + 1321 ms  PENDING
  + 1697 ms  CONFIRMED
  + 1990 ms  PENDING
…
  +19470 ms  CONFIRMED
  +19794 ms  PENDING
  sin estado final tras 20 s: sigue en PENDING
```

```text
OrderPlaced ─► inventory retiene ─► InventoryReserved ─► payments: el PSP rechaza ─► PaymentRejected
     ▲                                                                                     │
     └── orders: "liberaron, reintento" ◄── InventoryReleased ◄── inventory libera ◄───────┘
```

- Cada paso es correcto leído en su archivo. El ciclo solo existe en el sistema completo.
- El PSP no cobra de más: la clave `saga-<orderId>` es la misma en cada vuelta y responde la repetición
  guardada. La idempotencia contiene el daño en el dinero; no en todo lo demás.

El ciclo se cortó a los tres minutos, reiniciando `orders` sin el flag. El recuento:

```text
orders     CONFIRMED   (GET /api/v2/orders/bbd64ab5…)
inventory  SKU-005×1 RELEASED, SKU-005×1 RELEASED, SKU-005×1 RELEASED, …
payments   REJECTED psp-e02095d6
psp        sin cobro registrado
--- líneas de log de ese pedido
inventory, OrderPlaced:                 148
inventory, PaymentRejected:             148
orders, "OrderPlaced again":            147
orders, PaymentRejected aplicado:       1
payments.results.dlq:0:147
traza 83a02e8a148249dfbd6dd76b835fd067  ·  9509 spans  ·  148.0 s  ·  envoy, inventory, monolith, orders, payments
  … 9506 spans más sin imprimir (--max-lines); profundidad máxima 1188
```

- 148 vueltas: 148 retenciones y liberaciones del mismo `SKU-005`, con su bloqueo de fila cada vez; el
  primer `OrderPlaced` y 147 reintentos.
- Estado final **contradictorio**: `orders` dice `CONFIRMED` y `payments` dice `REJECTED`. 147
  `PaymentRejected` acabaron en la DLQ: el ciclo destapó un defecto de `orders` que una sola vuelta no
  enseña (§9).
- La única señal de alarma natural es la traza: **una sola** traza de 9 509 spans, 148 s y 1 188 niveles.
  Una alerta por trazas de más de N spans o de más de N s detecta ciclos de forma genérica.
- Tras la corrección de §9, el mismo ciclo sí refleja cada rechazo, y el cliente lo ve así:
  `+883 ms CONFIRMED`, `+951 ms PAYMENT_REJECTED`… y se detiene ahí, creyendo que es final, cuando la
  regla del ciclo lo reabrirá. Un estado "final" que no lo es rompe el contrato `v2`.

> **Veredicto:** la defensa contra ciclos en una coreografía es de disciplina, no de código: un
> `causationId` en cada hecho (los de `inventory` y `payments` ya lo llevan) para reconstruir la cadena,
> un límite de intentos por pedido, y la regla de que un estado final no se reabre. Cuando las reglas
> "si pasa X, haz Y" empiezan a encadenarse, la saga está pidiendo dueño.

## 9. 🩺 Errores reales al correrlo

### `payments` murió al leer el primer hecho de `inventory`: snappy

```text
2026-09-29 11:21:30,620 ERROR [trace=-] consumer died: UnsupportedCodecError('Libraries for snappy compression codec not found')
```

`franz-go` comprime los lotes con snappy por defecto; el productor de Java, no. `aiokafka` sabe leer
snappy solo si tiene `cramjam` instalado. El consumidor de `payments` murió en el primer
`InventoryReserved`, y las dos sagas en curso se quedaron en `CONFIRMED` sin más ruido que esa línea
—la que añadió el *done callback* de `06/06` §9—. **Corrección:** `cramjam==2.13.0` en `payments`. Al
reiniciar, el consumidor retomó desde el último offset confirmado y las dos sagas terminaron solas.
**Lección:** la compresión la elige el productor y la sufre el consumidor; en un sistema con clientes de
Kafka en tres lenguajes, los códecs son parte del contrato del topic.

### El ciclo destapó un `INSERT` que no era idempotente

```text
WARN … org.hibernate.orm.jdbc.error : ERROR: duplicate key value violates unique constraint "payments_operation_id_key"
payments.results.dlq:0:147
```

`orders` registraba cada `PaymentRejected` insertando un pago con su `operationId`. En la primera vuelta,
bien; en la segunda, el mismo `operationId` (`saga-<orderId>`, la clave idempotente hacia el PSP) violaba
la unicidad, el manejador de errores reintentaba tres veces y apartaba el mensaje a la DLQ. `orders` dejó
de enterarse de los rechazos. **Corrección:** registrar el pago **por** `operationId` —actualizarlo si ya
existe—; con ella, el mismo ciclo no manda nada más a la DLQ y `orders` refleja cada rechazo.
**Lección:** el inbox deduplica por `eventId`, pero dos hechos **distintos** pueden describir la misma
operación; el efecto tiene que ser idempotente por la clave del negocio, no solo por la del mensaje.

### Corrección antes de correr: una retención liberada contaba como reserva

La retención de `v1` era idempotente por referencia: si existía cualquier fila con ese `orderId`, devolvía
"ya retenido". En la saga, un segundo `OrderPlaced` del mismo pedido (el ciclo) habría encontrado filas
**liberadas** y publicado `InventoryReserved` sin retener nada. **Corrección:** solo cuentan las filas
retenidas o vendidas (`status <> 'RELEASED'`). **Lección:** "idempotente" depende de qué se considera la
misma operación; al reutilizar un método en otro flujo, esa definición se revisa.

### Las herramientas no estaban hechas para un ciclo

```text
RecursionError: maximum recursion depth exceeded
```

`lab.py trace` recorría el árbol con recursión y reventó con la traza de 1 188 niveles; y el recuento
con `kafka-console-consumer.sh --timeout-ms 3000` no terminaba, porque el topic no dejaba de crecer y el
plazo cuenta desde el último mensaje. **Corrección:** recorrido iterativo con tope de líneas
(`--max-lines`) y recuentos por offsets (`kafka groups`, `kafka-get-offsets.sh`). **Lección:** las
herramientas de diagnóstico también tienen que sobrevivir al incidente que diagnostican.

## 10. 🧰 En tres plataformas

| Plataforma | Qué te da hecho | Lo que te deja a ti |
|---|---|---|
| **Java** | `@KafkaListener` con grupo y commit por mensaje (`ack-mode: record`); `DefaultErrorHandler` con `FixedBackOff` y `DeadLetterPublishingRecoverer`: reintentos y DLQ en una clase de configuración | La tabla de transiciones y qué hacer con lo que llega fuera de orden; el inbox; que el efecto sea idempotente por la clave del negocio. Axon o Eventuate Tram dan sagas "de fábrica", con su modelo |
| **Go** | `franz-go` y `pgx`, y nada más | Todo: el despacho por tipo de hecho, la transacción que junta inbox, efecto y outbox, el publicador, los reintentos y la DLQ; ≈ 330 líneas visibles |
| **Python** | `aiokafka` para consumir y producir; `httpx` asíncrono para el PSP | El orden entre la llamada externa y la transacción (fuera de ella, con clave idempotente); el publicador como tarea del proceso; los códecs (`cramjam`) |

La fila de Node/TS —`kafkajs` y la misma disciplina de outbox e inbox— está en
[`03/03` §8](../03-datos-y-consistencia/03-saga.md#8--en-las-cuatro-plataformas).

## 11. 🧹 Teardown

```text
Ctrl+C en las terminales de psp, inventory, payments, monolith y orders
python3 laboratorio/scripts/lab.py down
```

- `down` borra también los topics de la saga y sus DLQ. El [taller 09](09-saga-orquestada.md) empieza con `up` y `seed --kafka`.

## ⚠️ Errores frecuentes

| Se dice | Lo preciso |
|---|---|
| "Con eventos, el cliente recibe la misma respuesta, solo que más desacoplada" | Recibe un `202` y un estado intermedio; la consistencia eventual forma parte del contrato |
| "`orders` sabe en qué estado está el pedido" | `orders` tiene una proyección de lo que otros publicaron; si un hecho no llega, la proyección se queda quieta y nadie avisa |
| "La coreografía no tiene punto único de fallo" | Tampoco tiene punto único de verdad ni de plazos: nadie vence un temporizador |
| "Añadir un paso es suscribir otro consumidor" | Y comprobar que ninguna combinación de reglas cierra un ciclo, cosa que no se ve en ningún archivo |
| "El inbox hace idempotente al consumidor" | Por `eventId`; dos hechos distintos pueden describir la misma operación |
| "Versionar es poner `/v2`" | Es mantener dos implementaciones con fecha de retirada, y decírselo al cliente (`Deprecation`, `Sunset`) |

## 📚 Para profundizar

- **Libro** — Chris Richardson, *Microservices Patterns*, Manning, 2018, cap. 4, "Managing transactions
  with sagas" (§4.2.1, coreografía; §4.3, la falta de aislamiento).
- **Documentación** — [Spring for Apache Kafka: manejo de errores y DLQ](https://docs.spring.io/spring-kafka/reference/kafka/annotation-error-handling.html) ·
  [`aiokafka`: soporte de snappy](https://aiokafka.readthedocs.io/en/stable/index.html#optional-snappy-install) ·
  [Hurl: reintentos](https://hurl.dev/docs/request.html).
- **Artículo** — Hector Garcia-Molina y Kenneth Salem, "Sagas", *Proceedings of the 1987 ACM SIGMOD
  International Conference on Management of Data*, 1987.
- **Fuente primaria** — [microservices.io: *Saga*](https://microservices.io/patterns/data/saga.html).
- **Especificación** — [RFC 9745, *The Deprecation HTTP Response Header Field*](https://www.rfc-editor.org/rfc/rfc9745.html) ·
  [RFC 8594, *The Sunset HTTP Header Field*](https://www.rfc-editor.org/rfc/rfc8594.html).

## 🧠 Preguntas

1. ¿Por qué el contrato `v2` responde `202` y no `201`? 🟢
2. ¿Qué publica cada participante de la saga, y en qué topic? 🟢
3. ¿Qué dicen los encabezados `Deprecation` y `Sunset`, y en qué formato va cada uno? 🟢
4. ¿Por qué `v1` sigue en verde sin cambiar la suite? 🟢
5. ¿Por qué `payments` mira el inbox antes de llamar al PSP y lo escribe después? 🟡
6. ¿Por qué `orders` acepta pasar a `PAID` desde `PENDING`, si el orden natural es `PENDING` → `CONFIRMED` → `PAID`? 🟡
7. ¿Por qué el pedido de 666,00 no sale nunca de `CONFIRMED`, y qué ve cada participante? 🟡
8. `InventoryReserved` lleva el total del pedido. ¿Por qué, y qué problema tiene? 🟠
9. ¿Cómo detectarías un ciclo de eventos en producción sin saber de antemano dónde está? 🟠
10. El ciclo terminó con `orders` en `CONFIRMED` y `payments` en `REJECTED`. ¿Por qué, y qué lección general deja? 🟠
11. ¿Por qué el consumidor de Python murió con el primer hecho de `inventory` y no con los de `orders`? 🟠
12. Un cliente de `v2` dejó de consultar al ver `PAYMENT_REJECTED`, y el pedido acabó pagado. ¿Cómo es posible, y qué debe garantizar el contrato? 🔴
13. En una entrevista te piden elegir entre esperar a la saga antes de responder (`201`/`409` como siempre) y el `202`. Defiende una y di cuándo cambiarías de opinión. 🔴
14. Diseña lo mínimo que habría que añadir a esta coreografía para que el pedido de 666,00 no se quede atascado, sin introducir un orquestador. ¿Qué te dice lo que te salió? 🔴

## 🧪 Ejercicios

1. 🟢 Corre las tres ramas con `buy --v2` y, para cada pedido, `saga-status`. Pega las salidas y marca en
   qué momento coinciden las cuatro partes.
2. 🟢 **Orientación en código ajeno.** Sigue un `PaymentRejected` desde que se escribe hasta que el stock
   vuelve: da, con ruta y línea, cada punto en que se escribe en una base o en un topic.
3. 🟡 Haz que `payments` consuma `orders.placed` y guarde el importe de cada pedido, y quita el `total` de
   `InventoryReserved`. ¿Qué ganas y qué nuevo acoplamiento aparece?
4. 🟠 Añade un límite de reintentos a la regla del ciclo (`--saga-retry-on-release`): como mucho tres
   `OrderPlaced` por pedido, contados con los hechos que ya existen. ¿Dónde guardas la cuenta?
5. 🟠 Haz que un estado final no se reabra: `PAID`, `PAYMENT_REJECTED` y `CANCELLED` ignoran todo hecho
   posterior. Vuelve a correr el ciclo y comprueba qué ve el cliente.
6. 🟠 Añade un consumidor `shipping` que prepare el envío al ver `PaymentAuthorized`, sin tocar ningún otro
   servicio. ¿Qué te costó, y qué no ves ahora del flujo completo?
7. 🔴 Escribe una comprobación periódica que encuentre pedidos `CONFIRMED` de más de 60 s y los compare con
   `payments` y con el PSP. ¿Qué haces con los que encuentres, y quién es dueño de esa decisión?
8. 🔥 Configura `inventory` para que produzca sin compresión (`kgo.ProducerBatchCompression`), quita
   `cramjam` de `payments` y demuestra que todo funciona. Luego elige un códec para todo el sistema y
   justifícalo.

---

**Anterior:** [`07` — Observabilidad de extremo a extremo](07-observabilidad-de-extremo-a-extremo.md). **Siguiente:**
[`09` — Saga orquestada, comparación y autopsia](09-saga-orquestada.md). **Relacionado:**
[`03/03` — Saga](../03-datos-y-consistencia/03-saga.md).
