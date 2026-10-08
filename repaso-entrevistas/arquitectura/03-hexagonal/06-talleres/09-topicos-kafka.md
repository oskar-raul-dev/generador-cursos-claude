# 09 — Tópicos con Kafka

Este taller es **opcional** y depende de `06/01` (contrato y entorno) y de `06/03` (el sabor Java,
que es el que se extiende). Saca la outbox del taller 03 a un log: `OrderCreated` y
`OrderCancelled` se publican en `orders.events`, particionado por `orderId`, y dos consumidores en
grupos distintos hacen con ellos cosas distintas: uno alimenta la tabla `notifications` de siempre
(la suite HTTP no se entera) y otro mantiene una proyección `orders_summary` que un endpoint nuevo,
`GET /api/v1/reports/orders-summary`, expone. Termina cuando la suite de `06/01` sigue en verde con
el transporte en Kafka, el archivo `taller-09/08-reports.hurl` pasa, y las tres provocaciones
(caída antes del commit de offset, productor sin clave, reconstrucción desde el offset 0) hacen lo
que el capítulo [04/03](../04-adaptadores-de-salida-y-operacion/03-publicacion-de-eventos-y-outbox.md)
prometía.

> **Vigencia:** 2026-09-27. Imagen y versiones verificadas ese día en Docker Hub y en el BOM de
> Spring Boot 4.1.1.

**Salto rápido:** [1](#1--qué-enseña-este-taller) · [2](#2--prerrequisitos-y-versiones) · [3](#3-️-mapa-de-carpetas) · [4](#4--el-núcleo-cambia-y-se-declara) · [5](#5--la-outbox-publica-el-tópico-reparte) · [6](#6--dos-consumidores-dos-grupos-dos-efectos) · [7](#7--provocaciones) · [8](#8--evidencia) · [9](#9--errores-provocados-a-propósito) · [10](#10--teardown) · [Preguntas](#-preguntas) · [Ejercicios](#-ejercicios)

## 1. 🎯 Qué enseña este taller

```text
CreateOrder / CancelOrder ──► outbox (misma transacción) ──► OutboxDispatcher ──► KafkaEventPublisher ──► orders.events (3 particiones, clave = orderId)
                                                                                                                │
                                                     grupo hex-notifications ◄──────────────────────────────────┤  NotifyCustomer → notifications (la tabla del taller 03)
                                                     grupo hex-orders-summary ◄─────────────────────────────────┘  ProjectOrdersSummary → orders_summary → GET /reports/orders-summary
```

Cinco cosas que una cola no obliga a pensar y un log sí:

- **El orden es por clave, no por tópico.** Todos los hechos de un pedido van a la misma
  partición porque la clave es el `orderId`; entre pedidos no hay orden. Sin clave, un
  `OrderCancelled` puede adelantar a su `OrderCreated`, y el taller lo hace visible.
- **Un tópico no se consume: lo consume cada grupo.** `hex-notifications` y
  `hex-orders-summary` reciben los mismos hechos y avanzan sus propios offsets. Añadir un tercer
  consumidor no toca a los dos primeros.
- **El offset se confirma después del efecto.** Aplicar y confirmar son dos pasos; entre los dos
  hay una ventana, igual que entre commit y ACK en el taller 08. La respuesta vuelve a ser la
  misma: deduplicación por `eventId`, en la base.
- **Una proyección es una función del log.** `orders_summary` se puede borrar y reconstruir
  desde el offset 0, siempre que cada hecho traiga lo que la proyección necesita. El taller
  descubrió que `OrderCancelled` no traía el importe, y lo corrigió (§9).
- **La outbox no garantiza *exactly once*.** Garantiza que el hecho sale si el pedido se
  confirmó, y que sale *al menos* una vez. Lo demás es del consumidor.

El precio: el núcleo cambia y se declara (`OrderCreated` nace con el pedido; `OrderCancelled`
lleva el total; `CreateOrder` deja el hecho en la outbox), 157 líneas de puertos y casos de uso
nuevos, 405 de infraestructura, dos tablas y un endpoint. La ganancia: el `Notifier` del taller 03
no se tocó y la suite HTTP tampoco lo notó.

## 2. 🧰 Prerrequisitos y versiones

| Herramienta | Versión fijada | Para qué |
|---|---|---|
| `apache/kafka` | `4.3.1` (Docker Hub) | el broker, en KRaft (un nodo, broker y controlador; sin ZooKeeper); trae los scripts `kafka-*.sh` |
| `spring-boot-starter-kafka` | la del BOM de Boot 4.1.1 (`spring-kafka` 4.1.1, `kafka-clients` 4.2.1) | `KafkaTemplate`, `@KafkaListener`, `KafkaAdmin` |
| `lab.py` | Python 3.11+, `docker exec` | tópico, grupos, `tail` y `rebuild` con los scripts del broker; nada que instalar en el host |

Se eligió la imagen JVM y no `apache/kafka-native` porque los scripts de administración (describir
el tópico, ver el *lag*, reajustar offsets) viven en ella; la nativa arranca antes y no los trae.

```text
python3 06-talleres/laboratorio/scripts/lab.py up --kafka
python3 06-talleres/laboratorio/scripts/lab.py seed --kafka
python3 06-talleres/laboratorio/scripts/lab.py java --events kafka
```

- `up --kafka` levanta el entorno común más el perfil `kafka` (`hex-kafka`), y espera a que
  `kafka-broker-api-versions.sh` responda. El broker tiene **dos listeners**: `9092` para lo que
  corre dentro del contenedor (los scripts) y `19092` para el host (el backend); cada uno anuncia
  la dirección que su cliente puede alcanzar (§9).
- `seed --kafka` recarga la semilla en PostgreSQL **y recrea el tópico** `orders.events` con sus
  tres particiones, vacío. El log guarda la historia de todas las semillas anteriores; si la base
  vuelve a cero y el log no, una proyección reconstruida cuenta pedidos que ya no existen (§9). Con
  el backend parado, que lo recrearía él.
- `java --events kafka` arranca el mismo backend con `hex.events.transport=kafka`: el dispatcher
  publica en vez de entregar a la tabla, y los dos consumidores arrancan. Sin `--events`, todo
  sigue como en el taller 03 y el backend ni intenta conectar a Kafka. `--unkeyed` y `--chaos`
  son las provocaciones de §7.

```text
python3 06-talleres/laboratorio/scripts/lab.py kafka topic
python3 06-talleres/laboratorio/scripts/lab.py kafka groups
python3 06-talleres/laboratorio/scripts/lab.py kafka tail [--max N]
python3 06-talleres/laboratorio/scripts/lab.py kafka rebuild
```

- `kafka topic` es `kafka-topics.sh --describe`: particiones, líder y réplicas.
- `kafka groups` es `kafka-consumer-groups.sh --all-groups --describe`: por grupo y partición,
  el offset confirmado, el fin del log, el *lag* y qué consumidor la tiene asignada.
- `kafka tail` es `kafka-console-consumer.sh --from-beginning --max-messages N` con clave y
  partición en cada línea: lo que hay en el log, tal cual.
- `kafka rebuild` vacía `orders_summary` y `applied_events` y reajusta el grupo
  `hex-orders-summary` al offset 0 (`--reset-offsets --to-earliest --execute`). Solo con el
  grupo inactivo: el backend parado.

## 3. 🗂️ Mapa de carpetas

```text
laboratorio/
├── contrato/docker-compose.yml                     + servicio kafka (perfil kafka)
├── contrato/openapi.yaml                           + GET /api/v1/reports/orders-summary (tag reports, x-suite taller-09)
├── contrato/hurl/taller-09/08-reports.hurl         la prueba del taller; fuera de la suite v1/v1.1 (solo Java)
├── contrato/seed/schema.sql                        + orders_summary, applied_events
├── scripts/lab.py                                  + up --kafka · seed --kafka · java --events/--unkeyed/--chaos · kafka topic/groups/tail/rebuild
└── java/src/main/java/hex/orders/
    ├── domain/DomainEvent.java                     + OrderCreated; OrderCancelled lleva el total    ← núcleo, declarado
    ├── domain/Order.java                           place() emite OrderCreated                       ← núcleo, declarado
    ├── application/port/out/                       + EventPublisher, AppliedEvents, OrdersSummary
    ├── application/usecase/                        + PublishPendingEvents, NotifyCustomer, ProjectOrdersSummary, GetOrdersSummary
    │                                               CreateOrder deja el hecho en la outbox; DeliverPendingPublications usa NotifyCustomer
    ├── infrastructure/messaging/EventJson.java     la forma del hecho fuera del proceso (outbox y tópico)
    ├── infrastructure/outbound/kafka/              KafkaEventPublisher (clave = orderId)
    ├── infrastructure/inbound/kafka/               OrdersEventsConsumers (dos @KafkaListener, dos grupos, ack manual)
    ├── infrastructure/outbound/postgres/           + JpaOrdersSummary, JpaAppliedEvents y sus entidades
    ├── infrastructure/inbound/http/ReportsController.java
    ├── infrastructure/config/KafkaConfiguration.java   el NewTopic con sus 3 particiones
    └── infrastructure/outbound/notification/OutboxDispatcher.java   elige publicar o entregar según hex.events.transport
```

## 4. 🧱 El núcleo cambia, y se declara

Los talleres de sabor prometían `git diff --stat -- domain application` vacío. Este no puede, y
lo dice:

```java
// domain/DomainEvent.java
record OrderCreated(UUID eventId, UUID orderId, UUID customerId, Money total, Instant occurredAt) implements DomainEvent { ... }
record OrderCancelled(UUID eventId, UUID orderId, UUID customerId, Money total, Instant occurredAt) implements DomainEvent { ... }

// domain/Order.java, en place()
order.events.add(new DomainEvent.OrderCreated(UUID.randomUUID(), id, customerId, total, now));

// application/usecase/CreateOrder.java, dentro de la unidad de trabajo
order.pullEvents().forEach(pending::add);
```

- `OrderCreated` existe porque una proyección lo necesita: hasta ahora el único hecho era la
  cancelación. Nace en `Order.place`, con el total, y `CreateOrder` lo deja en la outbox en la
  misma transacción que el pedido: ni antes (podría salir un hecho sin pedido) ni después (podría
  haber pedido sin hecho).
- `OrderCancelled` gana el total por la lección de §9: un hecho que obliga a la proyección a leer
  la base no sirve para reconstruirla.
- `NotifyCustomer` separa la *política* de notificación (qué hechos se comunican: solo la
  cancelación; a quién: al dueño) del *transporte*. La usan el dispatcher de tabla del taller 03 y
  el consumidor de Kafka; ninguno decide.

`DomainEvent` es `sealed`: añadir un tipo obliga al compilador a revisar cada `switch`
(`EventJson`, `NotifyCustomer`, `JpaOrdersSummary`). Es la forma barata de que un hecho nuevo no
se olvide en un consumidor.

## 5. 🔁 La outbox publica; el tópico reparte

```java
@Override
public void publish(DomainEvent event) {
    String key = keyed ? event.orderId().toString() : null;
    kafka.send(topic, key, EventJson.record(event)).get();   // síncrono: markPublished solo tras acks=all
}
```

- `PublishPendingEvents` es la política: lote de la outbox → `publish` → `markPublished`, en una
  unidad de trabajo que solo toca la outbox. Si el proceso cae entre `publish` y `markPublished`,
  la siguiente ronda publica el mismo `eventId` otra vez: **al menos una vez**, y los consumidores
  lo saben.
- `send(...).get()` espera la confirmación del broker (`acks=all`; con un broker, la suya). Sin
  el `get`, `markPublished` correría antes de saber si el registro llegó.
- La clave decide la partición (`hash(key) % 3`), y la partición decide el orden. `EventJson`
  fija la forma del registro (`eventId`, `type`, `occurredAt`, `payload`) y es la misma que la
  columna `jsonb` de la outbox: un solo contrato del hecho, dentro y fuera.
- `KafkaConfiguration` declara el tópico con `TopicBuilder` y `KafkaAdmin` lo crea al arrancar.
  El número de particiones es una decisión de contrato: fija el paralelismo máximo y no se
  cambia sin reubicar claves.

## 6. 🔀 Dos consumidores, dos grupos, dos efectos

```java
@KafkaListener(topics = "${hex.kafka.topic}", groupId = "hex-orders-summary")
public void summary(ConsumerRecord<String, String> record, Acknowledgment ack) {
    DomainEvent event = EventJson.fromRecord(record.value());
    boolean applied = project.execute(event);        // markApplied + apply, una transacción
    ack.acknowledge();                               // el offset avanza solo si el efecto está en la base
}
```

- `spring.kafka.listener.ack-mode=manual_immediate` y `enable-auto-commit=false`: el offset se
  confirma cuando el listener lo dice, y lo dice después del caso de uso. Con el *auto commit* por
  defecto, el offset avanzaría cada cinco segundos aunque el efecto hubiera fallado.
- `ProjectOrdersSummary.execute` hace `markApplied(projection, eventId)` (un `INSERT ... ON
  CONFLICT DO NOTHING` que devuelve si escribió) y `apply` en la misma transacción. Una re-entrega
  encuentra el `eventId` y no aplica. Es la misma tabla de deduplicación para cualquier proyección
  futura.
- `hex-notifications` llama a `NotifyCustomer`, que llama al `Notifier` del taller 03
  (`TableNotifier`, que ya deduplicaba por `eventId`). Por eso `07-notifications.hurl` pasa sin
  cambios: la notificación sigue apareciendo en la misma tabla, solo que ahora viaja por el log.
- Los consumidores son `@ConditionalOnProperty(hex.events.transport=kafka)`: con `table`, no
  existen, y el backend no abre ninguna conexión a Kafka.

`auto-offset-reset=earliest`: un grupo que nunca confirmó offsets empieza por el principio del
log. Es lo que hace posible reconstruir una proyección con un grupo nuevo, y también lo que hace
que un consumidor nuevo en producción reprocese la historia entera si nadie pensó en ello.

## 7. 🧨 Provocaciones

### Caída después de aplicar y antes del commit de offset

```text
python3 06-talleres/laboratorio/scripts/lab.py java --events kafka --chaos crash-before-offset-commit
```

- `hex.kafka.chaos=crash-before-offset-commit`: el consumidor de la proyección ejecuta
  `Runtime.halt(137)` después de que `project.execute` devolvió `true` (el efecto está
  confirmado) y antes de `ack.acknowledge()`. Solo si el hecho se aplicó *ahora*: en la
  re-entrega no vuelve a caer.

Se crea un pedido por HTTP y, literal (2026-09-27):

```text
INFO kafka[summary] p1 o7 ORDER_CREATED 8d33e892-06ed-41d4-b5e0-90965978515a → applied
ERROR kafka[summary] CHAOS crash-before-offset-commit — halting the JVM before ack()
--- base tras la caída ---
orders_summary|1                                       ← applied_events tiene el hecho
11111111-1111-4111-8111-111111111111|1|222.00          ← la proyección lo aplicó
--- offsets tras la caída ---
hex-orders-summary 1 7 8 1                             ← partición 1: confirmado 7, fin 8, LAG 1
```

Se reinicia sin caos. Durante **45 segundos** no pasa nada: el consumidor muerto no se despidió
del grupo y el broker espera `session.timeout.ms` antes de dar sus particiones a otro (§9).
Después:

```text
22:48:35.539 hex-orders-summary: partitions assigned: [orders.events-0, orders.events-1, orders.events-2]
22:48:35.593 kafka[summary] p1 o7 ORDER_CREATED 8d33e892-06ed-41d4-b5e0-90965978515a → already applied, skipped
11111111-1111-4111-8111-111111111111|1|0|222.00        ← sigue siendo un pedido, no dos
hex-orders-summary 1 8 8 0                             ← LAG 0
```

### Productor sin clave

```text
python3 06-talleres/laboratorio/scripts/lab.py seed --kafka
python3 06-talleres/laboratorio/scripts/lab.py java --events kafka --unkeyed
```

- `--unkeyed` pone `hex.kafka.keyed=false` **y** `partitioner.class=RoundRobinPartitioner`. Con
  clave nula, el particionador por defecto de Kafka 4 es *sticky*: manda una ráfaga entera a la
  misma partición y el desorden no se ve; el *round robin* reparte registro a registro, que es el
  peor caso y el que hay que mirar (§9).

Tres pedidos creados y cancelados en seguida:

```text
p1  key=null  ORDER_CREATED   5020d000
p1  key=null  ORDER_CANCELLED 9b9a31cb
p0  key=null  ORDER_CANCELLED 5020d000        ← la cancelación del 5020d000 está en OTRA partición que su creación
p0  key=null  ORDER_CREATED   e39163b0
p2  key=null  ORDER_CREATED   9b9a31cb
p2  key=null  ORDER_CANCELLED e39163b0
```

Los dos hechos de cada pedido quedaron en particiones distintas. Esta vez el consumidor los
aplicó en el orden bueno (la proyección dio `3|3|0.00`) porque el `poll` devolvió las tres
particiones casi a la vez; con un consumidor por partición, o con una partición atrasada, la
cancelación se aplica antes que la creación y el resumen pasa por un importe negativo. Con clave
no es cuestión de suerte: es el contrato del log.

### Reconstruir la proyección desde el offset 0

```text
python3 06-talleres/laboratorio/scripts/lab.py kafka rebuild        # backend parado
python3 06-talleres/laboratorio/scripts/lab.py java --events kafka
```

```text
3|3|0.00                                               ← antes
GROUP              TOPIC           PARTITION  NEW-OFFSET
hex-orders-summary orders.events   1          0
hex-orders-summary orders.events   0          0
hex-orders-summary orders.events   2          0
0                                                      ← filas en orders_summary tras el rebuild
aplicados tras reconstruir: 6
3|3|0.00                                               ← después: idéntico
```

Seis hechos reaplicados, la misma fila. `hex-notifications` no se reajustó y no reprocesó nada:
cada grupo tiene sus offsets.

### Dos instancias: *rebalance*

```text
python3 06-talleres/laboratorio/scripts/lab.py java --events kafka --port 8091     # en otra terminal
python3 06-talleres/laboratorio/scripts/lab.py kafka groups
```

```text
hex-notifications   p0 off=8 lag=0 consumer-hex-notifications-1-6efeba3e
hex-notifications   p1 off=8 lag=0 consumer-hex-notifications-1-6efeba3e
hex-notifications   p2 off=4 lag=0 consumer-hex-notifications-1-adca163b
hex-orders-summary  p0 off=8 lag=0 consumer-hex-orders-summary-2-04b3df2b
hex-orders-summary  p1 off=8 lag=0 consumer-hex-orders-summary-2-04b3df2b
hex-orders-summary  p2 off=4 lag=0 consumer-hex-orders-summary-2-a9057c45
```

Tres particiones, dos consumidores por grupo: dos y una. Una tercera instancia recibiría una; una
cuarta, ninguna. El paralelismo máximo es el número de particiones.

## 8. 🧪 Evidencia

Con `hex.events.transport=kafka`, la suite HTTP de `06/01` (las notificaciones ahora viajan por
el tópico) y el archivo del taller, 2026-09-27:

```text
Executed requests: 85 (20.7/s)
Succeeded files:   7 (100.0%)
Duration:          4097 ms (0h:0m:4s:97ms)
Success taller-09/08-reports.hurl (12 request(s) in 1825 ms)
```

El tópico, tal como lo creó el backend:

```text
Topic: orders.events	TopicId: QuOv1XwuSiOTRcViRlHe5w	PartitionCount: 3	ReplicationFactor: 1	Configs: min.insync.replicas=1
	Topic: orders.events	Partition: 0	Leader: 1	Replicas: 1	Isr: 1
	Topic: orders.events	Partition: 1	Leader: 1	Replicas: 1	Isr: 1
	Topic: orders.events	Partition: 2	Leader: 1	Replicas: 1	Isr: 1
```

Inventario (el código se generó de una vez; quien lo haga en un commit obtendrá este
`git diff --stat`):

```text
$ git diff --stat -- src/main/java/hex/orders/domain src/main/java/hex/orders/application
 domain/DomainEvent.java                      | +OrderCreated, OrderCancelled(+total)
 domain/Order.java                            | place() emite OrderCreated
 application/usecase/CreateOrder.java         | +PendingPublications, pullEvents → pending
 application/usecase/DeliverPendingPublications.java | usa NotifyCustomer
 application/port/out/{EventPublisher,AppliedEvents,OrdersSummary}.java   (nuevos)
 application/usecase/{NotifyCustomer,PublishPendingEvents,ProjectOrdersSummary,GetOrdersSummary}.java  (nuevos, 157 líneas en total con los puertos)
$ wc -l inbound/kafka/*.java outbound/kafka/*.java messaging/*.java
      62 OrdersEventsConsumers.java
      42 KafkaEventPublisher.java
      59 EventJson.java
```

Y las pruebas del taller 03, con una más en `OrderTest` (`placeEmitsOrderCreatedWithTheTotal`) y
la de `CreateOrderTest` que ahora comprueba la outbox:

```text
[INFO] Tests run: 13, Failures: 0, Errors: 0, Skipped: 0
[INFO] BUILD SUCCESS
```

**Cinco plataformas:** no aplica. Es un taller de integración, solo Java (guía §10.3).

## 9. 🩺 Errores provocados a propósito

Seis reales. Dos de herramienta, dos de infraestructura, dos de diseño; los dos últimos son los que
valen el taller.

### `spring-kafka` sin el starter: no hay `KafkaTemplate`

```text
Parameter 0 of constructor in hex.orders.infrastructure.outbound.kafka.KafkaEventPublisher required a bean of type
'org.springframework.kafka.core.KafkaTemplate' that could not be found.
```

Con Boot 3 bastaba `spring-kafka` en el classpath. Boot 4 partió la autoconfiguración en módulos
por tecnología: la de Kafka vive en `spring-boot-kafka`, que trae `spring-boot-starter-kafka`.
Compila, arranca y no hay bean. Corrección: el starter. Lección: en Boot 4, "está en el classpath"
ya no significa "está configurado".

### Un solo listener: los scripts del broker no alcanzan la dirección anunciada

```text
WARN [AdminClient clientId=adminclient-1] Connection to node 1 (localhost/127.0.0.1:19092) could not be established.
Error while executing topic command : Timed out waiting for a node assignment.
```

`kafka-topics.sh` dentro del contenedor conectaba a `localhost:9092`, recibía la metadata y en
ella el broker se anunciaba como `localhost:19092`, el puerto del host, que dentro del contenedor
no existe. Un broker no responde por donde le hablan: responde con la dirección que **anuncia**.
Corrección: dos listeners, `PLAINTEXT://:9092` anunciado como `localhost:9092` (dentro) y
`HOST://:19092` anunciado como `localhost:19092` (fuera). Lección: `advertised.listeners` es la
mitad de cada problema de conexión a Kafka.

### hurl no suma

```text
error: Parsing literal
62 | jsonpath "$...ordersCancelled" nth 0 == {{cancelled_before}} + 1
```

La primera versión del archivo capturaba los contadores y esperaba `+ 1`. hurl no evalúa
aritmética. Corrección: el archivo exige `lab.py seed` antes y afirma valores absolutos (`1`,
`"49.90"`, luego `1`/`1`/`"0.00"`). Lección: una prueba de proyección necesita un estado de
partida conocido; con la semilla lo tiene.

### Sin clave, el particionador *sticky* esconde el desorden

La primera provocación sin clave mandó los seis registros a `p0`: Kafka 4 agrupa los registros
con clave nula en la misma partición hasta cerrar el lote. "No se rompió" no era "está bien":
era que la ráfaga cabía en un lote. Corrección: `RoundRobinPartitioner` cuando `--unkeyed`, para
mirar el peor caso. Lección: la ausencia de un fallo en una prueba corta no es una garantía; la
garantía está en la clave.

### La proyección reconstruida contaba pedidos que ya no existían

```text
3|3|0.00               ← antes del rebuild
13|7|4095.40           ← después: diez pedidos más, y un importe imposible
```

Dos causas. El tópico guardaba los hechos de **todas** las semillas anteriores (cada `lab.py
seed` vaciaba PostgreSQL, ninguna vaciaba el log): la proyección reconstruida era fiel al log, y el
log ya no coincidía con la base. Y `OrderCancelled` no traía el importe: la primera
`JpaOrdersSummary` leía `orders` para descontarlo, y esos pedidos ya no estaban, así que el
`open_amount` solo subía. Corrección: `seed --kafka` recrea el tópico junto con la base, y
`OrderCancelled` lleva el total, como `OrderCreated`. Lección: **una proyección es una función del
log**; si necesita leer otra cosa para aplicarse, no es reconstruible, y si el log y la base tienen
historias distintas, la proyección cree al log.

### El consumidor muerto retiene sus particiones 45 segundos

Tras el `halt`, el consumidor nuevo arrancó y no recibió nada hasta que el broker dio por perdido
al anterior: `session.timeout.ms` (45 s por defecto). Un `halt` no envía `LeaveGroup`. No es un
error que corregir, es un plazo que conocer: en producción se ajusta (`session.timeout.ms`,
`heartbeat.interval.ms`) y se mide en el *lag*.

## 10. 🧹 Teardown

`Ctrl+C` en cada terminal de `lab.py java` (un cierre limpio envía `LeaveGroup` y el *rebalance*
es inmediato). `lab.py down` apaga todo, incluido `hex-kafka` con su log (`-v`: nada sobrevive).
Entre experimentos, `seed --kafka` deja base y log en el mismo punto.

## ⚠️ Errores frecuentes

- "La outbox garantiza *exactly once*." Garantiza que el hecho sale si el pedido se confirmó, y
  al menos una vez. El "una sola vez" lo pone el consumidor con `applied_events`.
- "Un tópico es una cola con otro nombre." Una cola entrega cada mensaje a un consumidor y lo
  olvida; un tópico lo guarda y cada grupo lo lee a su ritmo, tantas veces como quiera.
- "El orden está garantizado." Solo por partición, y solo si la clave es la misma. Sin clave, no
  hay promesa.
- "Auto commit es más simple." Es confirmar offsets que quizá no se aplicaron. Manual e inmediato
  tras el efecto, o at-least-once no es cierto.
- "La proyección se corrige con un `UPDATE`." Se corrige borrándola y reconstruyéndola; si eso no
  es posible, el hecho no lleva lo que la proyección necesita.

## ✅ Veredicto

Sacar la outbox a un log costó dos hechos nuevos en el dominio, cuatro casos de uso pequeños y
163 líneas entre productor, consumidores y formato; el `Notifier` del taller 03 siguió en su sitio
y la suite HTTP no cambió. Lo que el taller enseña no está en `@KafkaListener`: está en que el
orden es por clave, en que el offset se confirma después del efecto, y en que una proyección
solo es reconstruible si el log lo cuenta todo. Los seis errores reales van del starter que
falta a la proyección que contaba fantasmas; los dos últimos son de diseño, y son los que un
entrevistador quiere oír.

## 📚 Referencias

- [Kafka: semántica de entrega (at-most, at-least, exactly once)](https://kafka.apache.org/documentation/#semantics) · [`session.timeout.ms`](https://kafka.apache.org/documentation/#consumerconfigs_session.timeout.ms) · [quickstart (KRaft)](https://kafka.apache.org/quickstart/)
- [Spring Boot: Kafka](https://docs.spring.io/spring-boot/reference/messaging/kafka.html) · [Spring for Apache Kafka: `@KafkaListener`](https://docs.spring.io/spring-kafka/reference/kafka/receiving-messages/listener-annotation.html) · [contenedor y `AckMode`](https://docs.spring.io/spring-kafka/reference/kafka/receiving-messages/message-listener-container.html) · [envío](https://docs.spring.io/spring-kafka/reference/kafka/sending-messages.html) · [tópicos con `KafkaAdmin`](https://docs.spring.io/spring-kafka/reference/kafka/configuring-topics.html) · [*rebalance listeners*](https://docs.spring.io/spring-kafka/reference/kafka/receiving-messages/rebalance-listeners.html)

## 🧠 Preguntas

1. 🟢 ¿Por qué `OrderCreated` nace en `Order.place` y no lo construye `CreateOrder` después de guardar?
2. 🟢 ¿Qué garantiza la outbox en este taller y qué no?
3. 🟢 ¿Por qué hay dos grupos de consumidores y no uno que haga las dos cosas?
4. 🟢 ¿Qué decide la partición de un registro y qué consecuencia tiene para el orden?
5. 🟢 ¿En qué momento exacto se confirma el offset en `OrdersEventsConsumers` y por qué ahí?
6. 🟡 Describe la ventana entre "aplicado" y "offset confirmado" y qué la absorbe. Compárala con la ventana commit/ACK del taller 08.
7. 🟡 ¿Por qué `applied_events` tiene la proyección como parte de la clave?
8. 🟡 Tras el `halt`, el consumidor nuevo tardó 45 segundos en recibir la partición. ¿Por qué, y qué dos parámetros lo gobiernan?
9. 🟡 ¿Por qué `PublishPendingEvents` espera con `.get()` la confirmación del broker antes de `markPublished`?
10. 🟡 ¿Qué hace `auto-offset-reset=earliest` y qué riesgo tiene en producción?
11. 🟠 La reconstrucción dio `13|7|4095.40`. Explica las dos causas y por qué la corrección fue cambiar el hecho (`OrderCancelled` con total) y no la proyección.
12. 🟠 Sin clave, la primera prueba no mostró desorden y la segunda (round robin) sí separó los hechos de un pedido. ¿Qué dice eso de las pruebas de propiedades de orden, y cuál es la única garantía real?
13. 🟠 `hex-notifications` reutiliza `TableNotifier` sin cambios y la suite HTTP sigue en verde. ¿Qué frontera hizo eso posible y qué habría pasado si el `Notifier` hubiera sido "escribir en la tabla desde el dispatcher"?
14. 🟠 El núcleo cambió (`OrderCreated`, total en `OrderCancelled`, `CreateOrder` → outbox). Argumenta que esos cambios son del dominio y no una filtración de Kafka hacia dentro.

## 🧪 Ejercicios

1. 🟢 Arranca sin `--events kafka` (transporte `table`) con `hex-kafka` arriba y corre la suite.
   Comprueba con `kafka groups` que ningún grupo existe y explica qué hace `@ConditionalOnProperty`
   en los consumidores y en `KafkaConfiguration`.
2. 🟢 Cambia `spring.kafka.listener.ack-mode` a `batch` y `enable-auto-commit` a `true`, repite la
   provocación `crash-before-offset-commit` y pega los offsets tras la caída. Explica qué se perdió.
3. 🟡 Añade un tercer consumidor en un grupo `hex-audit` que escriba cada hecho en un archivo
   `audit.log` (un `Notifier` distinto). Comprueba que los otros dos grupos no se enteran y que
   `kafka groups` lo muestra desde el offset 0.
4. 🟡 Escribe una prueba de `ProjectOrdersSummary` con fakes de `AppliedEvents` y `OrdersSummary`:
   el mismo `OrderCreated` dos veces aplica una; `OrderCreated` + `OrderCancelled` del mismo pedido
   deja `openAmount` en `0.00`. Explica qué anillo cubre.
5. 🟠 Baja `session.timeout.ms` a 10 s y `heartbeat.interval.ms` a 3 s en el consumidor, repite el
   `halt` y mide cuánto tarda el *rebalance*. Explica qué se paga por bajarlos demasiado.
6. 🟠 Configura `hex.kafka.partitions=1`, recrea el tópico y repite la provocación sin clave. ¿Hay
   desorden posible? ¿Qué se pierde? Relaciónalo con el *rebalance* de dos instancias.
7. 🔴 Sustituye la deduplicación por `applied_events` por el productor idempotente y transacciones
   de Kafka (`enable.idempotence`, `transactional.id`, `read_committed`). Explica qué cubre eso
   (duplicados del productor) y qué no (una re-entrega tras caída del consumidor con efecto en
   PostgreSQL), y por qué la tabla sigue haciendo falta.
8. 🔥 Haz que `orders_summary` viva en MongoDB (`hex_catalog.orders_summary`) detrás del mismo
   puerto `OrdersSummary`, con `applied_events` en la misma colección (un documento por cliente con
   la lista de `eventId` aplicados). ¿Qué garantía transaccional cambia respecto a PostgreSQL y cómo
   la recuperas con una escritura condicional?

---

**Siguiente:** [10 — gRPC](10-grpc.md), o cualquier otra integración.
