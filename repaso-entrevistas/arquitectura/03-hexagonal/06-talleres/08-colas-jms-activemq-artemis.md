# 08 — Colas con JMS y ActiveMQ Artemis

Este taller es **opcional** y depende de `06/01` (contrato y entorno) y de `06/03` (el sabor Java,
que es el que se extiende). Añade una segunda puerta de entrada al mismo caso de uso que sirve
`POST /api/v1/orders`: una cola. Un sistema externo deja un `OrderRequested` en `orders.inbound`
y recibe la respuesta en `orders.reply`, correlacionada. Termina cuando el consumidor responde a
los seis escenarios del contrato asíncrono, sobrevive a una caída entre el commit y el ACK sin
crear un segundo pedido, aparta un mensaje envenenado en la DLQ y comparte la cola con otra
instancia.

> **Vigencia:** 2026-09-27. Imagen y versiones verificadas ese día en Docker Hub y en el BOM de
> Spring Boot 4.1.1.

**Salto rápido:** [1](#1--qué-enseña-este-taller) · [2](#2--prerrequisitos-y-versiones) · [3](#3-️-mapa-de-carpetas) · [4](#4--el-contrato-asyncapi-3) · [5](#5--el-consumidor-como-adaptador-de-entrada) · [6](#6--dos-transacciones-en-orden-commit-y-después-ack) · [7](#7--provocaciones) · [8](#8--evidencia) · [9](#9--errores-provocados-a-propósito) · [10](#10--teardown) · [Preguntas](#-preguntas) · [Ejercicios](#-ejercicios)

## 1. 🎯 Qué enseña este taller

Los cinco sabores tienen una sola puerta: HTTP. El capítulo
[03/02](../03-adaptadores-de-entrada/02-mensajeria-consumidores-y-comandos.md) decía que
un consumidor de mensajes es *otro adaptador de entrada del mismo puerto*; este taller lo hace
cierto con código y con un broker de verdad:

```text
sistema externo ──STOMP/JMS──► orders.inbound ──► OrderRequestedListener ──► CreateOrder ──► PostgreSQL
                                                        │  (adaptador)       (el mismo de HTTP)
                 ◄──────────── orders.reply ◄───────────┘  respuesta con JMSCorrelationID
                               DLQ ◄── mensaje ilegible tras 10 entregas fallidas
```

Cuatro cosas que HTTP no obliga a pensar y una cola sí:

- **ACK y commit no son lo mismo.** El pedido se confirma en PostgreSQL; el mensaje se confirma en
  el broker. Son dos transacciones locales, y el orden importa: primero la base, después el ACK.
  Entre las dos hay una ventana, y el taller la provoca con una caída real.
- **Un rechazo de negocio no es un fallo.** `INSUFFICIENT_INVENTORY` se *responde* y el mensaje se
  confirma; solo un mensaje ilegible o un fallo técnico se reintenta. Confundir las dos cosas
  llena la DLQ de rechazos legítimos (§9).
- **La deduplicación es del núcleo, no del broker.** Redelivery significa "puede que ya lo hayas
  hecho": el `operationId` del mensaje es la `Idempotency-Key`, y el caso de uso ya sabía qué
  hacer con ella.
- **La identidad la da el broker, no el mensaje.** El emisor se autenticó en Artemis; el mensaje
  dice *a nombre de quién* se crea el pedido, y el adaptador construye el `Actor` con el usuario
  real, nunca con un rol que venga en el cuerpo.

El precio: 236 líneas de adaptador, 63 de configuración, un broker más en el compose y un contrato
nuevo (`asyncapi.yaml`). La ganancia: `domain/` y `application/` no cambian ni una línea.

## 2. 🧰 Prerrequisitos y versiones

| Herramienta | Versión fijada | Para qué |
|---|---|---|
| `apache/artemis` | `2.57.0-alpine` (Docker Hub) | el broker; JMS en 61616, STOMP en 61613, consola en 8161 |
| `spring-boot-starter-artemis` | la del BOM de Boot 4.1.1 (cliente Artemis `2.53.0`, Jakarta Messaging `3.1`) | `@JmsListener`, `JmsTemplate`, `JmsTransactionManager` |
| `lab.py` | Python 3.11+, solo `socket` | habla STOMP 1.2 a mano: no hay cliente JMS en Python y no se añaden dependencias |

El proyecto Artemis se mudó de `apache/activemq-artemis` a `apache/artemis` en Docker Hub; la imagen
vieja se quedó en 2.44.0 y no avisa. Es el mismo patrón que `qossmic/deptrac` en `06/07`.

```text
python3 06-talleres/laboratorio/scripts/lab.py up --jms
python3 06-talleres/laboratorio/scripts/lab.py seed
python3 06-talleres/laboratorio/scripts/lab.py java
```

- `up --jms` levanta el entorno común más el perfil `jms` del compose (`hex-artemis`), y espera su
  *healthcheck* (la consola en 8161 responde cuando el broker acepta conexiones). Sin `--jms` el
  broker no arranca y el backend Java funciona igual: el listener reintenta conectar en segundo
  plano.
- `java` es el mismo backend del taller 03 con el listener dentro; `--port 8091` levanta una
  segunda instancia para los consumidores competidores.

```text
python3 06-talleres/laboratorio/scripts/lab.py jms send [--email E] [--line SKU:N ...] [--operation ID] [--count N] [--chaos crash-after-commit] [--poison] [--no-wait]
python3 06-talleres/laboratorio/scripts/lab.py jms dlq [--purge]
```

- `jms send` abre un socket STOMP contra `localhost:61613` con el usuario `hex`, se suscribe a
  `orders.reply` con `ack:client-individual`, envía un `OrderRequested` a `orders.inbound`
  (cabeceras `correlation-id`, `reply-to`, `destination-type:ANYCAST`) y espera la respuesta cuyo
  `correlation-id` coincida; confirma cada respuesta leída con un frame `ACK`. `--operation` fija
  el `operationId` (la clave de idempotencia); `--count N` envía N con sufijo; `--chaos` añade
  la cabecera `hexChaos`; `--poison` manda un cuerpo que no es JSON; `--no-wait` no espera.
- `jms dlq` corre `artemis queue stat --queueName DLQ` dentro del contenedor (cuántos mensajes hay
  y cuántos llegaron); `--purge` la vacía antes.

## 3. 🗂️ Mapa de carpetas

```text
laboratorio/
├── contrato/asyncapi.yaml                          el contrato asíncrono (canales, operaciones, mensajes, esquemas)
├── contrato/docker-compose.yml                     + servicio artemis (perfil jms)
├── scripts/lab.py                                  + up --jms · java --port · jms send · jms dlq (cliente STOMP de 60 líneas)
└── java/src/main/java/hex/orders/
    ├── infrastructure/inbound/jms/                 NUEVO
    │   ├── OrderRequestedListener.java             el adaptador: Message → comando → CreateOrder → OrderReply
    │   └── JmsMessages.java                        OrderRequested y OrderReply (la forma pública del canal)
    ├── infrastructure/config/JmsConfiguration.java NUEVO: fábrica del listener con JmsTransactionManager, JmsTemplate
    ├── infrastructure/config/HexProperties.java    + record Jms(inbound, reply, concurrency)
    ├── infrastructure/inbound/http/IdempotencyKeys.java   public: la misma huella para HTTP y para la cola
    └── resources/application.yaml                  + spring.artemis.* y hex.jms.*
```

`domain/` y `application/` no aparecen en el mapa porque no se tocaron. `ArchitectureTest` sigue
vigilando: `inbound.jms` puede importar `application` y `domain`, y no `outbound`.

## 4. 📜 El contrato: AsyncAPI 3

`contrato/asyncapi.yaml` es a las colas lo que `openapi.yaml` a HTTP: canales (`orders.inbound`,
`orders.reply`, `DLQ`), operaciones (`receiveOrderRequested` con su `reply`, `sendOrderReply`),
mensajes con cabeceras y esquemas, y ejemplos. Tres decisiones del contrato:

- `OrderRequested` **equivale** a `POST /api/v1/orders` con `Idempotency-Key = operationId`. Mismo
  `Money` como texto, mismos códigos de rechazo (`INSUFFICIENT_INVENTORY`, `PRODUCT_NOT_FOUND`…)
  que `problem+json`; se añade `UNKNOWN_CUSTOMER`, que HTTP no necesita porque allí el actor viene
  del token.
- La respuesta lleva `JMSCorrelationID` igual al de la petición, o al `JMSMessageID` si no traía.
  Un emisor que no correlaciona no puede saber qué respuesta es suya.
- Un rechazo de negocio es una **respuesta**; la DLQ es solo para lo ilegible.

## 5. 🔌 El consumidor como adaptador de entrada

```java
@JmsListener(destination = "${hex.jms.inbound}")
public void onOrderRequested(Message message) throws JMSException {
    String body = bodyOf(message);                                  // TextMessage o BytesMessage
    OrderRequested request = json.readValue(body, OrderRequested.class);   // ilegible → excepción → redelivery
    OrderReply reply = handle(request);                             // ACCEPTED o REJECTED, nunca excepción
    jms.convertAndSend(replyQueue, json.writeValueAsString(reply), m -> { m.setJMSCorrelationID(correlation); return m; });
}
```

- Recibe el `Message` crudo y no `@Payload String`: un cliente STOMP que mande `content-length`
  entrega un `BytesMessage`, uno JMS un `TextMessage`, y un mensaje STOMP no siempre trae
  `JMSMessageID`. El borde asume lo mínimo del emisor (§9).
- `handle` construye el `Actor` con `Users.findByEmail` (un puerto de aplicación: un adaptador de
  entrada puede usarlos) y llama a `createOrder.execute(new CreateOrder.Command(actor, operationId,
  IdempotencyKeys.hash(request.canonical()), lines))`. Es **exactamente** la llamada de
  `OrderController.create`: mismo comando, misma huella canónica, misma clave.
- Los rechazos de negocio (`NotFound`, `InsufficientInventory`, `IdempotencyKeyReused`) se
  capturan **aquí** y se convierten en `OrderReply.rejected(code, message)`. Es el `ProblemHandler`
  del canal de mensajes: el núcleo lanza las mismas excepciones y cada borde las traduce a su forma.
- `JMSReplyTo` se usa solo si es una `Queue`: un `reply-to` de STOMP llega como destino de tipo
  *topic*, y enviar a `orders.reply` como topic falla con `does not support MULTICAST routing` (§9).

## 6. 🔁 Dos transacciones, en orden: commit y después ACK

```java
factory.setTransactionManager(new JmsTransactionManager(connectionFactory));  // sesión transaccionada por mensaje
factory.setSessionTransacted(true);                                            // ACK = commit de la sesión, al volver
```

- La **transacción de PostgreSQL** la abre y cierra el caso de uso, por el puerto `UnitOfWork`,
  como siempre. El adaptador no le impone ninguna.
- La **transacción JMS** la abre el contenedor del listener antes de entregar el mensaje y la
  confirma cuando el método vuelve sin excepción: ese commit es el ACK del mensaje **y** el envío
  de la respuesta (el `JmsTemplate` participa en la sesión ligada al hilo). Si el método lanza,
  rollback: el mensaje vuelve a la cola con `JMSXDeliveryCount + 1`, y tras 10 entregas Artemis lo
  mueve a `DLQ` (valores por defecto del broker).
- El `JmsTransactionManager` **no es un `@Bean`**: convivir con el de JPA haría ambigua la inyección
  de `PlatformTransactionManager` en `OrdersConfiguration`. Se construye dentro de la fábrica.

No es XA. La secuencia es: commit de la base → (ventana) → commit de la sesión. Si el proceso cae en
la ventana, el pedido existe, la respuesta no salió y el mensaje vuelve. Lo que absorbe eso es la
idempotencia: la segunda entrega encuentra la clave, devuelve el mismo pedido con `replayed=true` y
esta vez el ACK y la respuesta sí salen. **Al menos una vez** en el broker, **efecto una sola vez**
en la base, y una respuesta que puede llegar dos veces (por eso lleva `replayed`).

## 7. 🧨 Provocaciones

### Caída entre commit y ACK

```text
python3 06-talleres/laboratorio/scripts/lab.py jms send --operation ext-crash-0001 --line SKU-002:3 --chaos crash-after-commit
```

- La cabecera `hexChaos=crash-after-commit` hace que el listener ejecute `Runtime.halt(137)`
  justo después de que `handle` volvió (la base confirmó) y antes de volver al contenedor (la sesión
  no confirmó). Solo en la primera entrega (`JMSXDeliveryCount <= 1`): un mensaje que matara a cada
  consumidor que lo recibe sería un mensaje envenenado, no una caída transitoria (§9).

Lo que se ve, literal (2026-09-27):

```text
→ orders.inbound  operationId=ext-crash-0001  correlation=corr-ext-crash-0001
sin respuesta en 8.0s para: ext-crash-0001
--- backend vivo? ---
(sin respuesta: la JVM murió)
--- base tras la caída ---
2                       ← pedidos: el de ext-crash-0001 existe
ext-crash-0001          ← la clave se guardó con él
97                      ← SKU-002: 100 - 3
--- broker tras la caída ---
|orders.inbound    |orders.inbound    |   0    |   1   |   29   |    0     |   9    |    0    |ANYCAST| false  |
```

`MESSAGE COUNT 1`: el mensaje sigue en la cola, sin ACK. Se reinicia `lab.py java`:

```text
INFO jms: OrderRequested received (delivery #3, correlation corr-ext-crash-0001)
INFO jms: replied ACCEPTED for operation ext-crash-0001
← orders.reply    ACCEPTED orderId=14c0b733-e994-40d0-81e6-9dbadca6f8e5 total=29.70 replayed=True
2                       ← pedidos: siguen siendo dos
97                      ← el stock no se descontó otra vez
```

(Es `delivery #3` y no `#2` porque la primera versión del caos se disparaba en cada entrega y mató
también al segundo arranque: §9.)

### Mensaje envenenado

```text
python3 06-talleres/laboratorio/scripts/lab.py jms send --poison --operation ext-demo-0007
python3 06-talleres/laboratorio/scripts/lab.py jms dlq
```

```text
INFO jms: OrderRequested received (delivery #1, correlation corr-ext-demo-0007)
WARN jms: listener failed, the broker will redeliver: tools.jackson.core.exc.StreamReadException: Unexpected character ('n' (code 110))
... (diez veces, delivery #1 … #10) ...
|DLQ |DLQ    |   0    |   1   |   19   |    0     |   0    |    0    |ANYCAST| false  |
```

Diez entregas en menos de un segundo (`redelivery-delay` por defecto es 0) y a la DLQ. El
`ErrorHandler` de la fábrica escribe una línea por intento; sin él Spring vuelca la traza entera
cada vez. `redelivery-delay` y `max-delivery-attempts` se fijan en las *address settings* del
broker (ejercicio 5).

### Consumidores competidores

```text
python3 06-talleres/laboratorio/scripts/lab.py java --port 8091      # en otra terminal
python3 06-talleres/laboratorio/scripts/lab.py jms send --operation ext-comp --count 6 --line SKU-002:1
```

```text
|orders.inbound    |orders.inbound    |   2    |   0   |   31   |    0     |   12   |    0    |ANYCAST| false  |
← orders.reply    ACCEPTED ... (seis respuestas)
--- instancia :8081 ---   3
--- instancia :8091 ---   3
```

`CONSUMER COUNT 2`: la cola es anycast y el broker reparte. Y con caos en una de las dos:

```text
--- :8081 ---
INFO jms: OrderRequested received (delivery #1, correlation corr-ext-comp-crash)
ERROR jms: CHAOS crash-after-commit — halting the JVM before the JMS ACK
--- :8091 ---
INFO jms: OrderRequested received (delivery #2, correlation corr-ext-comp-crash)
INFO jms: replied ACCEPTED for operation ext-comp-crash
← orders.reply    ACCEPTED orderId=f306c623-c444-43bc-b2a0-24e3328835fa total=19.80 replayed=True
```

La re-entrega fue a **la otra instancia**, que no había visto el mensaje y aun así respondió
`replayed=True`: la deduplicación vive en la base, no en la memoria de un consumidor.

## 8. 🧪 Evidencia

Los seis escenarios del contrato, en una corrida, 2026-09-27:

```text
=== 1. aceptado ===
← orders.reply    ACCEPTED orderId=e5590096-53d2-414c-87e4-8e0a7b30a95a total=99.80 replayed=False
=== 2. repetido (misma operación) ===
← orders.reply    ACCEPTED orderId=e5590096-53d2-414c-87e4-8e0a7b30a95a total=99.80 replayed=True
=== 3. misma clave, otro cuerpo ===
← orders.reply    REJECTED code=IDEMPOTENCY_KEY_REUSED message=Idempotency-Key reused with a different payload
=== 4. sin stock ===
← orders.reply    REJECTED code=INSUFFICIENT_INVENTORY message=SKU-004: requested 1, available 0
=== 5. SKU inexistente ===
← orders.reply    REJECTED code=PRODUCT_NOT_FOUND message=SKU-999
=== 6. cliente desconocido ===
← orders.reply    REJECTED code=UNKNOWN_CUSTOMER message=nadie@hex.local
--- base ---
1                       ← un solo pedido
ext-demo-0001|201       ← una sola clave
SKU-001|18
```

Inventario (el código se generó de una vez; quien lo haga en un commit obtendrá este
`git diff --stat`):

```text
$ wc -l inbound/jms/*.java config/JmsConfiguration.java contrato/asyncapi.yaml
      42 JmsMessages.java
     131 OrderRequestedListener.java
      63 JmsConfiguration.java
     164 asyncapi.yaml
$ git diff --stat -- src/main/java/hex/orders/domain src/main/java/hex/orders/application
                        (vacío)
```

Además: `HexProperties` (+1 record), `IdempotencyKeys` (`public`), `application.yaml` (+9 líneas),
`pom.xml` (+1 dependencia), `docker-compose.yml` (+1 servicio), `lab.py` (+3 órdenes). Las pruebas
del taller 03 siguen en verde, con ArchUnit incluido:

```text
[INFO] Tests run: 12, Failures: 0, Errors: 0, Skipped: 0
[INFO] BUILD SUCCESS
```

Y la suite HTTP de `06/01`, con el listener conectado al broker, 7/7 (85 peticiones, 4123 ms): la
segunda puerta no cambió la primera.

**Cinco plataformas:** no aplica. Es un taller de integración, solo Java (guía §10.3).

## 9. 🩺 Errores provocados a propósito

Cuatro reales, en el orden en que aparecieron. Los tres primeros son los que cualquier primer
consumidor JMS encuentra.

### El listener dentro de la transacción de JPA: rechazos que acaban en la DLQ

La primera versión ponía el `JpaTransactionManager` en la fábrica del listener (la receta más
repetida: "así el ACK espera al commit"). Los aceptados funcionaban; los rechazos, no:

```text
INFO jms: OrderRequested received (delivery #1, correlation corr-ext-demo-0001)
INFO jms: replied REJECTED for operation ext-demo-0001
WARN Setup of JMS message listener invoker failed for destination 'orders.inbound' - trying to recover.
     Cause: Transaction silently rolled back because it has been marked as rollback-only
INFO jms: OrderRequested received (delivery #2, correlation corr-ext-demo-0001)
... hasta delivery #10 y la DLQ; y cinco segundos de backoff entre intentos
```

`IdempotencyKeyReused` se lanza dentro de `unitOfWork.run(...)`; con la transacción externa ya
abierta, ese `run` **participa** en ella y la excepción la marca *rollback-only*. El listener
captura, responde `REJECTED`, y al volver el contenedor intenta confirmar una transacción que ya
no se puede confirmar. Corrección: `JmsTransactionManager` en el contenedor y la transacción de la
base donde siempre estuvo, en el caso de uso (§6). Lección: **la transacción del caso de uso es
suya**; un adaptador que la envuelve cambia la semántica de sus excepciones.

### `@Payload String` y `jms_messageId`: el mensaje que no era como se esperaba

```text
Caused by: org.springframework.messaging.MessageHandlingException: Missing header 'jms_messageId'
           for method parameter type [class java.lang.String], failedMessage=... [payload=byte[114], ...]
```

El mensaje de STOMP llegó como `BytesMessage` (traía `content-length`) y sin `JMSMessageID`. Todo
mensaje fue a la DLQ. Corrección: recibir `jakarta.jms.Message`, leer texto o bytes, y tratar
cada cabecera como opcional (§5). Lección: la forma de un mensaje la fija el **emisor**; el
adaptador asume lo mínimo.

### `reply-to` de STOMP llega como topic

```text
Caused by: jakarta.jms.InvalidDestinationException: Destination orders.reply exists, but does not support MULTICAST routing
```

Y como el envío de la respuesta va dentro de la sesión transaccionada, cada intento revirtió y
el pedido nunca se confirmó: cero pedidos, stock intacto, diez entregas y DLQ. Es una prueba
involuntaria de atomicidad. Corrección: usar `JMSReplyTo` solo si es una `Queue`. Lección: un
nombre de destino no dice si es cola o tópico; en Artemis eso es el *routing type*.

### El mensaje que mataba a cada consumidor

La primera versión del caos se disparaba en cada entrega. Tras reiniciar, la re-entrega (`delivery
#2`) volvió a traer `hexChaos` y mató también a la segunda instancia. Corrección:
`JMSXDeliveryCount <= 1`. Lección: una caída transitoria y un mensaje envenenado se parecen desde
fuera; lo que los distingue es si el **siguiente** intento tiene una oportunidad.

## 10. 🧹 Teardown

`Ctrl+C` en cada terminal de `lab.py java` (el contenedor del listener cierra la sesión: lo que
no se confirmó vuelve a la cola). `lab.py down` apaga todo, incluido `hex-artemis` con sus colas
(el broker no persiste entre sesiones: `-v`). Entre dos provocaciones, `lab.py jms dlq --purge`.

## ⚠️ Errores frecuentes

- "El handler del broker es el caso de uso." Es un adaptador: traduce, autentica, responde. Si
  crea el pedido con SQL propio, HTTP y la cola divergen en la primera regla que cambie.
- "ACK y commit son lo mismo." Son dos confirmaciones en dos sistemas; sin XA hay una ventana, y la
  respuesta a esa ventana es idempotencia, no esperanza.
- "Un rechazo se relanza para que el broker reintente." Reintentar un `INSUFFICIENT_INVENTORY` no
  crea stock: se responde y se confirma.
- "La DLQ es un error." Es una cuarentena: el mensaje ilegible deja de bloquear la cola y alguien lo
  mira después.
- "Con dos consumidores hay que sincronizarlos." La cola reparte; lo que hay que asegurar es que
  cualquiera de los dos deduplique, y eso vive en la base.

## ✅ Veredicto

La segunda puerta costó 236 líneas de adaptador y ninguna del núcleo, y la suite HTTP no se enteró.
Lo que el taller enseña no está en `@JmsListener`, sino en el orden de dos commits, en qué se
responde y qué se reintenta, y en que la deduplicación estaba hecha desde el taller 03 porque la
`Idempotency-Key` ya era del caso de uso. Los cuatro errores reales son los de la primera semana
con un broker: la transacción equivocada, el mensaje con otra forma, el destino con otro tipo y el
caos que no distingue reintento de veneno.

## 📚 Referencias

- [Spring Boot: JMS](https://docs.spring.io/spring-boot/reference/messaging/jms.html) · [Spring Framework: `@JmsListener`](https://docs.spring.io/spring-framework/reference/integration/jms/annotated.html) · [recepción de mensajes y transacciones](https://docs.spring.io/spring-framework/reference/integration/jms/receiving.html)
- [Artemis: mensajes no entregados y DLQ](https://artemis.apache.org/components/artemis/documentation/latest/undelivered-messages.html) · [address settings](https://artemis.apache.org/components/artemis/documentation/latest/address-settings.html) · [STOMP](https://artemis.apache.org/components/artemis/documentation/latest/stomp.html) · [gestión y CLI](https://artemis.apache.org/components/artemis/documentation/latest/management.html) · [imagen Docker](https://artemis.apache.org/components/artemis/documentation/latest/docker.html)
- [AsyncAPI 3.0.0](https://www.asyncapi.com/docs/reference/specification/v3.0.0) · [Jakarta Messaging 3.1](https://jakarta.ee/specifications/messaging/3.1/jakarta-messaging-spec-3.1)

## 🧠 Preguntas

1. 🟢 ¿Por qué el consumidor JMS llama a `CreateOrder` y no a `JpaOrders`?
2. 🟢 ¿Qué es `operationId` para el caso de uso y por qué un mensaje repetido no crea un segundo pedido?
3. 🟢 ¿De dónde sale el `Actor` en el consumidor y qué del mensaje NO se usa para construirlo?
4. 🟢 ¿Qué se responde y qué se reintenta? Da un ejemplo de cada uno.
5. 🟢 ¿Qué es la DLQ en Artemis y cuándo llega ahí un mensaje con la configuración por defecto?
6. 🟡 Describe el orden exacto de commit de la base, envío de la respuesta y ACK en este taller, y dónde está la ventana.
7. 🟡 ¿Por qué el `JmsTransactionManager` no es un `@Bean`?
8. 🟡 ¿Por qué `replayed` va en la respuesta? ¿Quién lo necesita?
9. 🟡 Con dos instancias, la re-entrega fue a la otra y aun así respondió `replayed=True`. ¿Dónde vive la deduplicación y qué pasaría si viviera en memoria?
10. 🟡 ¿Por qué el listener recibe `jakarta.jms.Message` y no `@Payload String`?
11. 🟠 Explica el error del `JpaTransactionManager` en el contenedor: por qué un rechazo de negocio acabó en `Transaction silently rolled back` y diez re-entregas.
12. 🟠 ¿Qué pierde y qué gana este diseño frente a XA (una transacción distribuida entre PostgreSQL y Artemis)? ¿Cuándo elegirías XA?
13. 🟠 El emisor STOMP y el listener JMS discreparon en tres cosas (tipo de cuerpo, `JMSMessageID`, tipo del `reply-to`). ¿Qué dice eso sobre dónde va la tolerancia en un borde de mensajes, y qué debería fijar el contrato AsyncAPI?
14. 🟠 Compara este adaptador con `OrderController`: qué comparten, qué traduce cada uno distinto y por qué `IdempotencyKeys.hash` tiene que ser el mismo en los dos.

## 🧪 Ejercicios

1. 🟢 Envía un `OrderRequested` con `--email ops@hex.local`. ¿Se crea el pedido a nombre del operador?
   Explica por qué el consumidor no comprueba el rol y qué regla del núcleo sí aplica igual.
2. 🟢 Vuelve a poner `factory.setTransactionManager(transactionManager)` con el de JPA, corre el
   escenario 3 (misma clave, otro cuerpo) y pega las diez líneas de `delivery #`. Restaura.
3. 🟡 Añade a `lab.py jms send` la opción `--content-length` que vuelva a mandar la cabecera, y
   comprueba que el listener sigue respondiendo (llega como `BytesMessage`). Explica qué habría
   pasado con la primera versión del listener.
4. 🟡 Escribe una prueba del adaptador sin broker: construye `OrderRequestedListener` con un
   `CreateOrder` de fakes (los del `CreateOrderTest`), un `JmsTemplate` de Mockito y un
   `ActiveMQTextMessage` en memoria, y comprueba que un `INSUFFICIENT_INVENTORY` produce un
   `OrderReply` `REJECTED` y **no** lanza. Explica qué anillo cubre.
5. 🟠 Configura en el broker `max-delivery-attempts=3` y `redelivery-delay=500` para `orders.inbound`
   (address settings; la imagen admite un `broker.xml` propio montado en `etc-override/`), repite
   el mensaje envenenado y pega `jms dlq` con los tiempos del log. Explica por qué un `delay` de 0
   es peligroso en producción.
6. 🟠 Cambia `hex.jms.concurrency` a `3` en una sola instancia y envía `--count 9`. ¿Cuántos hilos
   aparecen en el log? ¿Sigue siendo correcto el reparto si dos mensajes traen el mismo
   `operationId` y llegan a la vez? Argumenta con la clave única de `idempotency_keys`.
7. 🔴 Sustituye la respuesta por cola por un `OrderAccepted` en la outbox del taller 03: el listener
   solo crea el pedido y deja el hecho; el `DeliverPendingPublications` publica la respuesta en
   `orders.reply`. Explica qué garantía cambia (la respuesta ya no sale con el ACK) y qué pasa con
   `JMSCorrelationID`.
8. 🔥 Implementa el mismo consumidor en NestJS (`06/04`) con un cliente STOMP o AMQP contra el
   mismo broker y el mismo `asyncapi.yaml`, y haz que `lab.py jms send` reciba respuestas de
   cualquiera de los dos. ¿Qué parte del contrato descubriste que estaba implícita en Java?

---

**Siguiente:** [09 — Tópicos con Kafka](09-topicos-kafka.md), o cualquier otra integración.
