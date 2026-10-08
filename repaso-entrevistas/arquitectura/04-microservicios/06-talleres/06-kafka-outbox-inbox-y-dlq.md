# 06 — Kafka: outbox, inbox, idempotencia y DLQ

Este taller es **opcional** y depende de [`05` — Resiliencia en tres plataformas](05-resiliencia-en-tres-plataformas.md):
parte de su sistema. Hasta aquí todos los servicios se hablaban preguntando; ahora `orders` empieza a
**contar lo que pasó** —`OrderPlaced`, `OrderPaid`, `OrderCancelled`— en un topic de Kafka, y dos
servicios reaccionan: `inventory` (Go) suma unidades vendidas y `payments` (Python) anula pagos
pendientes de pedidos cancelados. Con eso se provocan los tres fallos clásicos de la mensajería: la
entrega duplicada que **cuenta dos veces**, el evento que **se pierde** por publicar fuera de la
transacción y el mensaje **venenoso** que atasca a un consumidor. Termina con la suite `v1` en verde,
las tres provocaciones con su salida y los contadores cuadrando con los pedidos.

> Ejercita [`02/06` — Mensajería y eventos](../02-comunicacion/06-mensajeria-y-eventos.md),
> [`03/04` — Outbox, inbox e idempotencia](../03-datos-y-consistencia/04-outbox-inbox-e-idempotencia.md) y
> [`03/05` — Evolución de esquema y migraciones](../03-datos-y-consistencia/05-evolucion-de-esquema-y-migraciones.md).
>
> **Vigencia:** 2026-09-29. Versiones verificadas ese día en Docker Hub, `proxy.golang.org`, PyPI y el BOM de
> Spring Boot 4.1.1; salidas corridas ese día en un Apple M1 Pro con Docker Desktop.

**Salto rápido:** [1](#1--qué-enseña-este-taller) · [2](#2--prerrequisitos-y-versiones) · [3](#3-️-mapa-de-carpetas) · [4](#4--recorrido-de-la-base-de-código) · [5](#5--el-outbox-en-orders) · [6](#6--los-consumidores-offset-después-del-efecto) · [7](#7--provocación-la-entrega-duplicada-que-cuenta-dos-veces) · [8](#8--provocación-el-evento-que-se-pierde) · [9](#9--provocación-el-mensaje-venenoso) · [10](#10--errores-reales-al-correrlo) · [11](#11--en-tres-plataformas) · [12](#12--teardown) · [Preguntas](#-preguntas) · [Ejercicios](#-ejercicios)

---

## 1. 🎯 Qué enseña este taller

```text
orders (Java)
  tx { cambio del pedido + INSERT outbox_events }      ← el hecho sale si y solo si el cambio se confirmó
  OutboxPublisher (cada 200 ms): SELECT … FOR UPDATE SKIP LOCKED → send(key = orderId).get() → published_at
        │
        ▼
  orders.events (3 particiones, clave orderId)          orders.events.dlq (lo que no se puede leer)
        │                                     │
  grupo inventory (Go, franz-go)        grupo payments (Python, aiokafka)
  OrderPaid → sales += unidades         OrderCancelled → pagos PENDING a VOIDED
  tx { inbox + efecto } → commit offset tx { inbox + efecto } → commit offset
```

Cuatro ideas:

- **El outbox resuelve la doble escritura.** Guardar el pedido y publicar son dos sistemas; escribir el
  hecho en una tabla de la misma base, en la misma transacción, y publicarlo después, hace que el hecho
  salga **si y solo si** el cambio se confirmó ([`03/04`](../03-datos-y-consistencia/04-outbox-inbox-e-idempotencia.md)).
- **Al menos una vez es la promesa.** El offset se confirma **después** del efecto: si el consumidor muere
  entre los dos, el mensaje se re-entrega. Sin inbox, una unidad vendida cuenta dos veces; con inbox, se
  detecta y se salta.
- **Publicar después del commit pierde eventos.** Con el proceso muerto entre el commit y el envío, el
  pedido existe, el cliente recibió un error, y el hecho no está ni estará nunca en el topic.
- **Un mensaje que no se puede leer no se reintenta para siempre.** Se aparta a una DLQ con el motivo y el
  consumidor sigue.

El precio, en las cinco monedas: **latencia** (el hecho sale hasta 200 ms después del commit),
**consistencia** (eventual por definición: los contadores van por detrás de los pedidos; al menos una vez
obliga a idempotencia aguas abajo), **operación** (un broker, dos grupos que vigilar por su *lag*, una DLQ que
alguien tiene que mirar), **dinero** (un clúster de Kafka en producción no es barato) y **esfuerzo** (163
líneas de Java, 182 de Go y 121 de Python sobre el taller 05).

## 2. 🧰 Prerrequisitos y versiones

| Herramienta | Versión fijada | Para qué |
|---|---|---|
| Todo lo de `06/05` | la de `06/05` §2 | el sistema completo |
| `apache/kafka` | `4.3.1` | KRaft, un nodo; la imagen JVM trae los scripts `kafka-*.sh` |
| `spring-boot-starter-kafka` | la del BOM de Boot 4.1.1 | `KafkaTemplate` del publicador |
| `github.com/twmb/franz-go` | `v1.22.1` | consumidor Go, puro Go (sin cgo) |
| `aiokafka` | `0.14.0` | consumidor Python nativo de `asyncio` |

```text
python3 laboratorio/scripts/lab.py up
python3 laboratorio/scripts/lab.py seed --kafka          # con los consumidores PARADOS
```

- `up` levanta ahora `ms-kafka`, con dos listeners: `9092` para los scripts de dentro del contenedor y
  `29092` para los servicios del host. Cada cliente recibe la dirección que el broker **anuncia** para su
  listener.
- `seed --kafka` hace lo de siempre y además borra y recrea `orders.events` (3 particiones) y
  `orders.events.dlq` (1), y borra los grupos `inventory` y `payments`. **Solo con los consumidores parados**
  (§10). `seed` a secas —el que usa `suite`— no toca Kafka.

Los servicios arrancan como en `06/05`; `inventory` y `payments` se conectan a Kafka solos cuando el compose
trae `kafka`. Las órdenes nuevas:

```text
python3 laboratorio/scripts/lab.py kafka topics | groups | tail [--topic T] | poison
python3 laboratorio/scripts/lab.py inventory [--no-inbox] [--chaos crash-after-effect]
python3 laboratorio/scripts/lab.py orders [--events-mode direct] [--events-chaos crash-before-publish]
```

- `kafka groups` es `kafka-consumer-groups.sh --describe --all-groups`: por grupo y partición, el offset
  confirmado, el final del log y el *lag*.
- `kafka tail` lee un topic desde el principio con clave, partición, offset y encabezados.
- `kafka poison` escribe en `orders.events` un mensaje que no es JSON, con clave `poison-0001`.
- `inventory --no-inbox` desactiva la deduplicación; `--chaos crash-after-effect` mata el proceso después
  de aplicar un efecto y **antes** de confirmar su offset.
- `orders --events-mode direct` publica tras el commit en vez de usar el outbox, y
  `--events-chaos crash-before-publish` mata la JVM entre el commit y el envío.

> **📝 Contexto:** el código tal como queda al terminar este taller está congelado en
> `laboratorio/estados/06/`, y las rutas con número de línea se refieren a esa copia. Si ya existen
> talleres posteriores, añade `--estado 06` a cada orden de `lab.py`.

## 3. 🗂️ Mapa de carpetas

```text
laboratorio/estados/06/                            (lab.py --estado 06)
├── contrato/
│   ├── docker-compose.yml                         + ms-kafka
│   └── seed/                                      orders: + outbox_events · inventory: + sales, processed_messages
│                                                  payments: + processed_messages, estado VOIDED
├── orders/.../events/
│   ├── OrderEvents.java                           el hecho, en la transacción del cambio (o, en modo direct, tras ella)
│   └── OutboxPublisher.java                       el que lo lleva a Kafka
├── inventory/internal/consumer/consumer.go        OrderPaid → sales; inbox; DLQ; caos
└── payments/app/consumer.py                       OrderCancelled → VOIDED; inbox; DLQ
```

## 4. 🔎 Recorrido de la base de código

Rutas relativas a `laboratorio/estados/06/`.

**¿Dónde nace el hecho?** `orders/.../service/OrderService.java`, línea 70: `events.placed(order)`,
**dentro** del `tx.execute` que guarda el pedido. En `orders/.../events/OrderEvents.java`, la línea 62
inserta en `outbox_events` con la conexión de esa transacción. La línea 57 es la alternativa mala: en modo
`direct`, registra un `afterCommit` que publica después, y la 69 es el caos que mata la JVM justo ahí.

**¿Cómo sale del outbox?** `orders/.../events/OutboxPublisher.java`: `FOR UPDATE SKIP LOCKED` (línea 43)
para que dos instancias no publiquen la misma fila, y `send(...).get()` (línea 48) para no marcar como
publicado lo que el broker no confirmó.

**¿Cuándo se confirma el offset?** `inventory/internal/consumer/consumer.go`: `kgo.DisableAutoCommit()`
(línea 44) y `CommitRecords` después de `handle` (línea 59). En `payments/app/consumer.py`,
`enable_auto_commit=False` (línea 23) y `await consumer.commit()` después de `handle` (línea 32).

**¿Dónde está el inbox?** El mismo `INSERT … ON CONFLICT DO NOTHING` en los dos:
`inventory/internal/store/store.go`, línea 162, y `payments/app/consumer.py`, línea 63, en la misma
transacción que el efecto. Si no inserta ninguna fila, el evento ya se aplicó.

**¿Y el venenoso?** `consumer.go`, línea 70, y `consumer.py`, línea 48: al topic `orders.events.dlq`, con
encabezados `error` y `consumer`, y se confirma el offset para seguir.

## 5. 🧱 El outbox en `orders`

**Qué es.** Una tabla `outbox_events` en `ms_orders` y un publicador. El hecho se escribe con el cambio,
en la misma transacción; el publicador lo lee, lo envía y lo marca.

```java
var order = orders.save(new Order(orderId, actor.id(), actor.email(), orderLines));
events.placed(order);                          // INSERT INTO outbox_events … en la MISMA transacción
```

```java
kafka.send(topic, e.aggregateId().toString(), e.payload()).get();   // clave = orderId; espera al broker
jdbc.sql("UPDATE outbox_events SET published_at = clock_timestamp() WHERE id = ?").params(e.id()).update();
```

- La clave es el `orderId`: los tres hechos de un pedido van a la misma partición y se leen en orden.
- Si el publicador muere entre el `send` y la marca, la siguiente ronda lo reenvía: el mismo `eventId`
  llega dos veces. El outbox garantiza "al menos una vez", no "una sola vez".
- El evento lleva `eventId`, `type`, `version`, `orderId`, `customerId`, `total` y `lines`: todo lo que un
  consumidor necesita para actuar sin llamar a `orders`.

La suite y los consumidores, 2026-09-29 (tras la corrección de §10):

```text
Executed requests: 46 (11.6/s)
Succeeded files:   6 (100.0%)
--- inventory
2026/09/29 10:29:11 p2 o1 OrderPaid 2b742659 → applied
2026/09/29 10:29:13 p2 o4 OrderPaid 653561fe → applied
--- payments
2026-09-29 10:29:13,645 INFO OrderCancelled 7f014686 order=fe1fa16b → 0 pending payment(s) voided
{"items":{"SKU-002":3}}
inventory       orders.events   0          2               2               0
inventory       orders.events   1          2               2               0
inventory       orders.events   2          5               5               0
payments        orders.events   0          2               2               0
…
```

- La suite paga 2 + 1 unidades de `SKU-002`: `sales` dice 3. Nueve hechos en el topic, *lag* 0 en los dos
  grupos. La suite no cambió: los eventos son efectos laterales que el contrato `v1` no ve.

> **Veredicto:** el outbox cuesta una tabla, un proceso y hasta 200 ms de retraso, y compra que el hecho y
> el cambio no puedan divergir. La alternativa sin tabla es CDC (Debezium leyendo el log de la base), que
> cambia la tabla por una pieza de infraestructura más.

## 6. 🧱 Los consumidores: offset después del efecto

**Qué es.** Cada grupo lee el topic a su ritmo y confirma su offset **cuando** el efecto está en su base.

```go
for _, r := range fetches.Records() {
    handle(ctx, cl, st, opt, r)                  // inbox + efecto, en una transacción
    if err := cl.CommitRecords(ctx, r); err != nil { … }   // el offset, DESPUÉS
}
```

```python
async for msg in consumer:
    await handle(pool, producer, msg)            # inbox + efecto, en una transacción
    await consumer.commit()                      # el offset, DESPUÉS
```

- Con el autocommit por defecto, el offset avanzaría por tiempo aunque el efecto hubiera fallado:
  mensajes perdidos sin ruido.
- El inbox es una tabla por consumidor (`processed_messages`) y una fila por `eventId`, **en la misma
  transacción** que el efecto. Fuera de ella, habría otra vez dos escrituras sin atomicidad.
- `inventory` elige un efecto que **no** es idempotente por naturaleza —sumar unidades— a propósito: es
  donde se ve el duplicado. El de `payments` sí lo es (`PENDING` → `VOIDED` solo una vez), y aun así pasa
  por el inbox: la idempotencia por estado se rompe en cuanto el efecto cambia.

## 7. 🧨 Provocación: la entrega duplicada que cuenta dos veces

```text
python3 laboratorio/scripts/lab.py inventory --no-inbox --chaos crash-after-effect
```

Un pedido de 2 × `SKU-001`, pagado. 2026-09-29:

```text
2026/09/29 10:29:41 p1 o3 OrderPaid 661f0c79 → applied
2026/09/29 10:29:41 CHAOS crash-after-effect: sale applied, exiting BEFORE committing offset 3
--- offsets tras la caída
inventory       orders.events   1          3               4               1
sales SKU-001 en la base|2
reiniciado sin caos 10:29:46; esperando la re-entrega…
2026/09/29 10:30:25 p1 o3 OrderPaid 661f0c79 → applied
sales: {"items":{"SKU-001":4,"SKU-002":3}}
unidades de SKU-001 pagadas según orders|2
```

```text
efecto aplicado (sales +2) ──► proceso muere ──► offset 3 sin confirmar (lag 1)
reinicio ──► el grupo retoma desde el último offset confirmado ──► el mismo evento otra vez ──► sales +2
```

- Cuatro unidades vendidas según `inventory`, dos según `orders`. Nadie mintió: el consumidor aplicó
  **dos entregas** del mismo hecho.
- La re-entrega tardó 39 s. El consumidor muerto no se despidió del grupo, y el broker espera
  `session.timeout.ms` (45 s por defecto) antes de dar sus particiones a otro. No es un error: es un plazo
  que se vigila en el *lag*.

**Con inbox**, mismo experimento con un pedido de 1 unidad:

```text
sales antes: {"items":{"SKU-001":4,"SKU-002":3}}
2026/09/29 10:30:45 p2 o6 OrderPaid e87ffcac → applied
2026/09/29 10:30:45 CHAOS crash-after-effect: sale applied, exiting BEFORE committing offset 6
2026/09/29 10:31:30 p2 o6 OrderPaid e87ffcac → already applied, skipped
sales después: {"items":{"SKU-001":5,"SKU-002":3}}
```

- La re-entrega llegó igual; el inbox encontró el `eventId` y la suma subió **1**, no 2. "Exactamente una
  vez" no existe de extremo a extremo: existe "al menos una vez" más un consumidor idempotente.

> **Veredicto:** confirmar el offset después del efecto es lo correcto, y trae duplicados de regalo. El
> inbox —una fila por evento en la misma transacción que el efecto— es la forma barata y general de
> absorberlos.

## 8. 🧨 Provocación: el evento que se pierde

```text
python3 laboratorio/scripts/lab.py orders --events-mode direct --events-chaos crash-before-publish
```

- Modo `direct`: el hecho se publica en un `afterCommit`, que es la forma "natural" de hacerlo sin outbox.
  El caos mata la JVM justo entre el commit y el envío.

Un alta de pedido, 2026-09-29:

```text
ERROR … CHAOS crash-before-publish: OrderPlaced for order 833dbca2-75cc-492c-baac-5a52fdfeb2fa committed, halting before send
833dbca2-75cc-492c-baac-5a52fdfeb2fa|CONFIRMED
eventos de ese pedido en el topic:
0
tras reiniciar orders (con outbox): 0 eventos
POST /api/v1/orders → 503 907ms upstream=…:28082 attempts=1 UC upstream_reset_before_response_started{connection_termination}
```

- El pedido existe y tiene stock reservado; el cliente recibió un `503` y creerá que no se creó; y el hecho
  no está en el topic **ni lo estará**: nada lo recuerda. Con el outbox, el mismo corte deja la fila en
  `outbox_events` y el publicador la envía al volver.
- Envoy no reintentó: la política segura de `06/05` solo reintenta lo que no llegó, y esta petición sí llegó.

> **Veredicto:** publicar después del commit es la doble escritura con otro orden. Invertir el orden
> tampoco sirve (se anunciaría un pedido que quizá no se guarda). Lo que la resuelve es que el hecho viva
> en la base del cambio hasta que se publique.

## 9. 🧨 Provocación: el mensaje venenoso

```text
python3 laboratorio/scripts/lab.py kafka poison
python3 laboratorio/scripts/lab.py kafka tail --topic orders.events.dlq
```

2026-09-29:

```text
--- inventory
2026/09/29 10:32:58 p1 o4 key=poison-0001 → DLQ (unreadable)
--- payments
2026-09-29 10:32:58,036 WARNING p1 o4 key=b'poison-0001' → DLQ (JSONDecodeError)
--- orders.events.dlq
Partition:0	Offset:0	error:Expecting property name enclosed in double quotes: line 1 column 2 (char 1),consumer:payments	poison-0001	{esto no es json
Partition:0	Offset:1	error:unreadable event,consumer:inventory	poison-0001	{esto no es json
inventory 1 5 5 0
payments 1 5 5 0
```

- Los dos grupos apartaron el mensaje y siguieron: *lag* 0. Sin DLQ, un consumidor que falla al leer y no
  confirma el offset se queda atascado en ese mensaje para siempre —y la partición entera con él—.
- Hay **dos** copias en la DLQ: una por grupo. Una DLQ compartida necesita el encabezado `consumer` para
  saber quién la apartó y a quién hay que devolvérsela tras la corrección.
- `payments` distingue el venenoso (no se reintenta) del transitorio (una base que no responde: hasta tres
  intentos con espera antes de rendirse).

> **Veredicto:** la DLQ convierte un mensaje imposible en un asunto de operación en vez de un consumidor
> parado. Su precio es que alguien la mire: una DLQ que nadie vacía es un cementerio de efectos perdidos.

## 10. 🩺 Errores reales al correrlo

### `UNKNOWN_TOPIC_ID`: recrear el topic con los consumidores vivos

```text
2026/09/29 10:28:10 fetch orders.events/2: UNKNOWN_TOPIC_ID: This server does not host this topic ID.
```

La primera versión de `lab.py seed` recreaba los topics en cada siembra, y `lab.py suite` siembra antes de
correr. Con los consumidores ya conectados, el topic se borró y se creó otro con el mismo nombre y **otro
ID**: `franz-go` siguió pidiendo el viejo sin recuperarse, y el consumidor de `payments` murió **sin dejar
rastro**. **Corrección:** `seed` no toca Kafka; `seed --kafka` recrea topics y grupos y se usa con los
consumidores parados; y la tarea del consumidor Python registra si muere. **Lección:** en Kafka 4 un topic
tiene identidad propia (ID), no solo nombre; y un consumidor que muere en una tarea de fondo es el fallo
más silencioso del taller.

### El cliente HTTP del JDK pedía HTTP/2 en claro en cada petición

```text
WARNING:  Unsupported upgrade request.
WARNING:  No supported WebSocket library detected. …
```

`uvicorn` avisaba en cada pago: el cliente del JDK que usa `orders` envía `Upgrade: h2c` por defecto.
Funcionaba —se quedaba en HTTP/1.1— pero ensuciaba el log. **Corrección:**
`HttpClient.Version.HTTP_1_1` en los clientes de `orders` hacia `payments`. **Lección:** un aviso por
petición es ruido que tapa los avisos que importan; se corrige en el origen.

## 11. 🧰 En tres plataformas

| Plataforma | Qué te da hecho | Lo que te deja a ti |
|---|---|---|
| **Java** | `spring-boot-starter-kafka` con `KafkaTemplate`; `@Scheduled` y `TransactionSynchronization` para el publicador; `@KafkaListener` con `AckMode.MANUAL` si consume | La tabla del outbox, el `SKIP LOCKED`, esperar la confirmación antes de marcar; el outbox "de fábrica" solo existe en frameworks como Spring Modulith o Axon |
| **Go** | `franz-go`: grupos, `DisableAutoCommit`, `CommitRecords`, productor síncrono para la DLQ | El inbox, el bucle, la DLQ y qué hacer con cada error; todo visible en ≈ 100 líneas |
| **Python** | `aiokafka`: consumidor y productor asíncronos, `enable_auto_commit=False` | Correr el consumidor como tarea del proceso web (y enterarse si muere), el inbox y los reintentos; con varios workers, cada uno es un miembro del grupo |

La fila de Node/TS —`kafkajs` con `autoCommit: false`— está en
[`02/06`](../02-comunicacion/06-mensajeria-y-eventos.md).

## 12. 🧹 Teardown

```text
Ctrl+C en las terminales de psp, inventory, payments, monolith y orders
python3 laboratorio/scripts/lab.py down
```

- `down` borra también `ms-kafka` y su log: nada sobrevive. El [taller 07](07-observabilidad-de-extremo-a-extremo.md) empieza con `up` y `seed --kafka`.

## ⚠️ Errores frecuentes

| Se dice | Lo preciso |
|---|---|
| "Con Kafka tenemos exactly once" | Entre productor y broker, con transacciones de Kafka; de extremo a extremo con efectos en una base, no: al menos una vez más un consumidor idempotente |
| "El outbox garantiza que el evento se entrega una vez" | Garantiza que sale si el cambio se confirmó, al menos una vez |
| "Publico después del commit y listo" | Si el proceso muere entre medias, el evento se pierde y nada lo recuerda |
| "El autocommit es más simple" | Confirma offsets de efectos que quizá no se aplicaron |
| "Si el efecto es idempotente, sobra el inbox" | Hasta que el efecto cambia; el inbox es la garantía que no depende de la forma del efecto |
| "La DLQ resuelve los mensajes malos" | Los aparta; alguien tiene que mirarlos, corregir y reinyectar |

## 📚 Para profundizar

- **Libro** — Chris Richardson, *Microservices Patterns*, Manning, 2018, cap. 3, §3.3.7, "Transactional
  messaging" (outbox, polling publisher, transaction log tailing).
- **Libro** — Martin Kleppmann, *Designing Data-Intensive Applications*, O'Reilly, 2017, cap. 11, "Stream
  Processing".
- **Documentación** — [Kafka: semántica de entrega](https://kafka.apache.org/documentation/#semantics) ·
  [`session.timeout.ms`](https://kafka.apache.org/documentation/#consumerconfigs_session.timeout.ms) ·
  [Spring for Apache Kafka: envío](https://docs.spring.io/spring-kafka/reference/kafka/sending-messages.html).
- **Documentación** — [`franz-go` (`kgo`)](https://pkg.go.dev/github.com/twmb/franz-go/pkg/kgo) ·
  [`aiokafka`: consumidor](https://aiokafka.readthedocs.io/en/stable/consumer.html) ·
  [PostgreSQL 17: `FOR UPDATE … SKIP LOCKED`](https://www.postgresql.org/docs/17/sql-select.html#SQL-FOR-UPDATE-SHARE).
- **Fuente primaria** — [microservices.io: *Transactional outbox*](https://microservices.io/patterns/data/transactional-outbox.html)
  · [*Idempotent consumer*](https://microservices.io/patterns/communication-style/idempotent-consumer.html).

## 🧠 Preguntas

1. ¿Qué garantiza el outbox y qué no? 🟢
2. ¿Por qué la clave de los mensajes es el `orderId`? 🟢
3. ¿Qué hace `FOR UPDATE SKIP LOCKED` en el publicador? 🟢
4. ¿Qué es el inbox y dónde se escribe? 🟢
5. ¿Por qué el offset se confirma después del efecto y no antes? 🟡
6. ¿Por qué la re-entrega tardó 39 s? ¿Es un error? 🟡
7. ¿Por qué hay dos copias del venenoso en la DLQ? 🟡
8. ¿Qué te da Go con `franz-go` para consumir con commit manual, y qué escribes tú? 🟡
9. Con el modo `direct` y la caída, el cliente recibió `503` y el pedido existe. ¿Qué ve cada parte y qué haría falta para recuperarlo? 🟠
10. `payments` anula pagos por estado, que ya es idempotente. ¿Por qué pasa también por el inbox? 🟠
11. ¿Qué pasaría con `sales` si reconstruyes el consumidor desde el offset 0, con y sin inbox? 🟠
12. ¿Por qué recrear un topic con los consumidores vivos rompió a los dos, y qué cambiaste en el laboratorio? 🔴
13. Dibuja el recorrido de un `OrderPaid` desde el `UPDATE` del pedido hasta la suma en `sales`, y marca los tres puntos donde puede duplicarse o perderse. 🔴
14. En producción, un contador alimentado por eventos va por encima de lo que dice la base de origen. Da tres hipótesis en orden de probabilidad y qué mirarías para cada una. 🔴

## 🧪 Ejercicios

1. 🟢 Crea tres pedidos, págalos y comprueba con `kafka tail` que los hechos de cada pedido están en una
   sola partición y en orden. Pega la salida.
2. 🟢 **Orientación en código ajeno.** Encuentra, con ruta y línea, dónde decide `payments` que un error es
   transitorio y lo reintenta, y dónde decide que es venenoso y lo aparta.
3. 🟡 Mata `orders` con `kill -9` justo después de un pago (en modo `outbox`) y demuestra que el `OrderPaid`
   sale al reiniciar. ¿Puede salir dos veces? ¿Cómo lo verías?
4. 🟡 Añade al evento un campo nuevo (`channel`) y comprueba que los dos consumidores lo ignoran sin romperse.
   Luego renombra `lines` a `items`: ¿qué hace cada consumidor y por qué uno de los dos falla en silencio?
5. 🟠 Reajusta el grupo `inventory` al offset 0 (`kafka-consumer-groups.sh --reset-offsets --to-earliest`),
   vacía `sales` y reinicia el consumidor con inbox. ¿Qué pasa y qué tendrías que vaciar además?
6. 🟠 Escribe una orden `lab.py kafka replay-dlq` que reinyecte en `orders.events` los mensajes de la DLQ de un
   consumidor concreto. ¿Qué riesgo tiene reinyectar para todos?
7. 🔴 Sustituye el publicador por CDC con Debezium leyendo `outbox_events` del WAL de PostgreSQL. ¿Qué
   desaparece del código de `orders` y qué aparece en la operación?
8. 🔥 Arranca dos instancias de `inventory` y observa el reparto de particiones con `kafka groups`. Mata una y
   cronometra el *rebalance*.

---

**Anterior:** [`05` — Resiliencia en tres plataformas](05-resiliencia-en-tres-plataformas.md). **Siguiente:**
[`07` — Observabilidad de extremo a extremo](07-observabilidad-de-extremo-a-extremo.md). **Relacionado:**
[`03/04` — Outbox, inbox e idempotencia](../03-datos-y-consistencia/04-outbox-inbox-e-idempotencia.md).
