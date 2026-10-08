# 10 — gRPC

Este taller es **opcional** y depende de `06/01` (contrato y entorno) y de `06/03` (el sabor Java,
que es el que se extiende). Sustituye el `PaymentGateway` determinista, que vivía en proceso, por un
proveedor de pagos real al otro lado de la red: `payments-grpc`, un servidor Java pequeño con el
mismo comportamiento de §11 más latencia y caídas inyectables. `AuthorizePayment` no cambia una
línea. Termina cuando la suite de `06/01` pasa con el proveedor por la red, la prueba del adaptador
corre contra un servidor en proceso, y las dos provocaciones (latencia mayor que el plazo,
proveedor caído) dejan el pedido **pendiente**, nunca rechazado ni con un 500.

> **Vigencia:** 2026-09-28. Versiones verificadas ese día en Maven Central y en el BOM de Spring
> Boot 4.1.1.

**Salto rápido:** [1](#1--qué-enseña-este-taller) · [2](#2--prerrequisitos-y-versiones) · [3](#3-️-mapa-de-carpetas) · [4](#4--el-contrato-paymentsproto) · [5](#5--el-servidor-payments-grpc) · [6](#6--el-cliente-detrás-del-mismo-puerto) · [7](#7--provocaciones) · [8](#8--evidencia) · [9](#9--errores-provocados-a-propósito) · [10](#10--teardown) · [Preguntas](#-preguntas) · [Ejercicios](#-ejercicios)

## 1. 🎯 Qué enseña este taller

```text
AuthorizePayment ──► PaymentGateway (puerto) ──► GrpcPaymentGateway ──deadline 2 s, metadata idempotency-key──► payments-grpc :19090
                                    │                    │                                                             │
                     DeterministicPaymentGateway         └── UNAVAILABLE / DEADLINE_EXCEEDED → PENDING              regla de §11 + fallos (POST /faults :19091)
                     (los talleres 03–09)                    INVALID_ARGUMENT / INTERNAL → excepción (500)
```

Cuatro cosas que un stub en proceso no obliga a pensar y una llamada remota sí:

- **El `.proto` es el contrato**, no el código generado. Vive en `contrato/proto/` junto a
  `openapi.yaml` y `asyncapi.yaml`; servidor y cliente lo compilan en cada build y ninguno
  versiona los stubs.
- **Dinero sin `double`.** `Money { string amount; string currency; }`: el mismo texto decimal que
  el contrato HTTP. `49.90` como `double` ya no es `49.90`.
- **Un timeout no significa que no hubo cobro.** `DEADLINE_EXCEEDED` y `UNAVAILABLE` son "no sé":
  el adaptador los traduce a `PENDING`, el pedido queda `PAYMENT_PENDING` y la misma clave decidirá
  después. Traducirlos a `REJECTED` cobraría dos veces a alguien; dejarlos subir como excepción
  daría un 500 por algo que no es un error del sistema.
- **Plazo siempre, por llamada, y clave en metadata.** Sin `deadline`, un proveedor colgado
  bloquea el hilo para siempre; con `idempotency-key` en la cabecera, un reintento es "la misma
  operación" para el proveedor, que responde lo mismo sin volver a decidir.

El precio: 208 líneas entre contrato, adaptador, configuración y prueba, más un servidor de 220
líneas en su propio proyecto. La ganancia: el caso de uso, el dominio y el resto del sistema no
saben que existe gRPC; ArchUnit sigue en verde.

## 2. 🧰 Prerrequisitos y versiones

| Herramienta | Versión fijada | Para qué |
|---|---|---|
| `spring-boot-starter-grpc-server` / `-client` | las del BOM de Boot 4.1.1 (Spring gRPC `1.1.1`, grpc-java `1.83.1`, protobuf-java `4.35.1`) | servidor Netty autoconfigurado; `GrpcChannelFactory` en el cliente |
| `protobuf-maven-plugin` (`io.github.ascopes`) | `5.1.8` (BOM de Boot) | descarga `protoc` y `protoc-gen-grpc-java` y genera los stubs en cada build; sin instalar nada |
| `grpc-inprocess` | `1.83.1` (BOM) | el servidor en proceso de la prueba del adaptador |

Los starters de Spring gRPC ya no viven en `org.springframework.grpc` (ahí quedaron en 1.0.3):
Boot 4 los absorbió como `spring-boot-starter-grpc-*` y los gestiona su BOM. Es el mismo patrón
de módulo que Kafka en `06/09`.

```text
python3 06-talleres/laboratorio/scripts/lab.py up
python3 06-talleres/laboratorio/scripts/lab.py seed
python3 06-talleres/laboratorio/scripts/lab.py payments-grpc          # terminal A
python3 06-talleres/laboratorio/scripts/lab.py java --payment grpc    # terminal B
```

- `payments-grpc` corre `mvn spring-boot:run` en `laboratorio/payments-grpc/`: el plugin compila
  `../contrato/proto/payments.proto`, y el servidor escucha gRPC en `19090` y un HTTP mínimo de
  fallos en `19091`. `--test` corre sus pruebas.
- `java --payment grpc` arranca el backend con `hex.payment.provider=grpc`: el bean
  `PaymentGateway` pasa a ser el cliente. Sin `--payment`, es el determinista de siempre y el
  backend no abre ningún canal.

```text
python3 06-talleres/laboratorio/scripts/lab.py grpc fault latency --latency-ms 3000
python3 06-talleres/laboratorio/scripts/lab.py grpc fault unavailable
python3 06-talleres/laboratorio/scripts/lab.py grpc fault none
```

- `grpc fault` hace `POST /faults` al servidor con `{mode, latencyMs}`; el fallo aplica a todas
  las llamadas siguientes hasta que se quite. `latency` duerme antes de responder (y si el cliente
  ya se rindió, no responde a nadie); `unavailable` responde `UNAVAILABLE` en cada llamada.

## 3. 🗂️ Mapa de carpetas

```text
laboratorio/
├── contrato/proto/payments.proto                    el contrato: PaymentService.Authorize, Money como texto
├── payments-grpc/                                   NUEVO: el proveedor, un proyecto Boot aparte
│   ├── pom.xml                                      starter-grpc-server + webmvc; protobuf-maven-plugin sobre ../contrato/proto
│   └── src/main/java/hex/payments/
│       ├── PaymentsApplication.java
│       ├── PaymentService.java                      la regla de §11, idempotencia por operation_id, respeto al deadline
│       └── Faults.java                              POST/GET /faults: latencia o UNAVAILABLE inyectables
├── scripts/lab.py                                   + payments-grpc · java --payment grpc · grpc fault
└── java/
    ├── pom.xml                                      + starter-grpc-client, grpc-inprocess (test), protobuf-maven-plugin
    ├── src/main/resources/application.yaml          + spring.grpc.client.channel.payments.target, hex.payment.*
    └── src/main/java/hex/orders/infrastructure/
        ├── outbound/payment/grpc/GrpcPaymentGateway.java   el adaptador: deadline, metadata, traducción de códigos
        ├── outbound/payment/DeterministicPaymentGateway.java   ahora @ConditionalOnProperty(provider=deterministic)
        └── config/PaymentsGrpcConfiguration.java           el bean PaymentGateway cuando provider=grpc
```

`domain/` y `application/` no aparecen: no se tocaron. `AuthorizePayment` sigue llamando a
`gateway.authorize(operationId, total)` fuera de la transacción, como en el taller 03.

## 4. 📜 El contrato: `payments.proto`

```proto
service PaymentService {
  rpc Authorize(AuthorizeRequest) returns (AuthorizeResponse);
}
message Money { string amount = 1; string currency = 2; }        // "49.90", nunca double
message AuthorizeRequest { string operation_id = 1; Money amount = 2; }
message AuthorizeResponse {
  enum Status { STATUS_UNSPECIFIED = 0; AUTHORIZED = 1; REJECTED = 2; }
  Status status = 1; string reference = 2;
}
```

- No hay `PENDING` en la respuesta: un resultado incierto **no es una respuesta**, es un error
  gRPC (`UNAVAILABLE`, `DEADLINE_EXCEEDED`) y lo traduce el cliente. Si el proveedor pudiera
  responder "no sé", el cliente tendría que tratar dos formas de "no sé".
- `STATUS_UNSPECIFIED = 0` es la convención de proto3: el valor por defecto de un enum nunca debe
  significar algo. El cliente lo trata como error del proveedor.
- La clave de idempotencia viaja también en el cuerpo (`operation_id`) porque el proveedor la
  necesita para decidir; en metadata (`idempotency-key`) porque un intermediario (proxy,
  observabilidad, *rate limit*) la lee sin abrir el mensaje.

## 5. 🔌 El servidor: `payments-grpc`

`PaymentService extends PaymentServiceGrpc.PaymentServiceImplBase`, registrado por Boot como
`@Service`. Tres cosas que un proveedor real tiene y un stub no:

- **Idempotencia por `operation_id`**: la primera decisión se guarda; la misma clave responde lo
  mismo sin volver a decidir ("replaying previous answer").
- **Respeto al plazo del cliente**: tras dormir la latencia inyectada, si `Context.current()` ya
  está cancelado, no responde. El cliente ya se fue; responder sería trabajar para nadie.
- **Fallos inyectables** desde fuera, por HTTP, sin recompilar.

Y la regla de §11: `> 1000.00` → `REJECTED`; `== 666.00` → `UNAVAILABLE` ("provider did not
answer"); resto → `AUTHORIZED` con `gw-<operationId>`. Por eso la suite de `06/01`, que espera
`PENDING` para `666.00`, pasa por la red igual que en proceso.

## 6. 🔁 El cliente, detrás del mismo puerto

```java
AuthorizeResponse response = stub
    .withInterceptors(MetadataUtils.newAttachHeadersInterceptor(metadata))   // idempotency-key
    .withDeadlineAfter(deadlineMs, TimeUnit.MILLISECONDS)                    // plazo nuevo en cada llamada
    .authorize(request);
...
} catch (StatusRuntimeException e) {
    if (code == UNAVAILABLE || code == DEADLINE_EXCEEDED) return new Payment(PENDING, operationId, null);
    throw new IllegalStateException("payments provider failed: " + e.getStatus(), e);
}
```

- `withDeadlineAfter` en **cada llamada**, no en el stub al construirlo: un stub con
  `withDeadline(absoluto)` caduca para siempre a los dos segundos de arrancar. Es el error más
  común con gRPC y por eso el comentario está en el código.
- `UNAVAILABLE` y `DEADLINE_EXCEEDED` → `PENDING`. `INVALID_ARGUMENT`, `INTERNAL`, `UNKNOWN` →
  excepción → `500`: eso sí es un error del sistema (un contrato roto), no una incertidumbre.
- `PaymentsGrpcConfiguration` crea el bean solo con `hex.payment.provider=grpc`, y el
  determinista solo con `deterministic` (`matchIfMissing`): un solo `PaymentGateway`, siempre.
- El canal lo abre `GrpcChannelFactory.createChannel("payments")` y la dirección la pone
  `spring.grpc.client.channel.payments.target=static://localhost:19090`. La clave exacta importa
  (§9).

## 7. 🧨 Provocaciones

### Latencia mayor que el plazo

```text
python3 06-talleres/laboratorio/scripts/lab.py grpc fault latency --latency-ms 3000
```

El proveedor tarda 3 s; el cliente espera 2. Literal (2026-09-28):

```text
fault: {"mode":"latency","latencyMs":3000}
2.17s → orderStatus=PAYMENT_PENDING payment=PENDING code=None
WARN authorize lat-pay-0001: the client gave up before we answered                  ← servidor, al segundo 3
WARN payments: DEADLINE_EXCEEDED for operation lat-pay-0001 → PENDING (CallOptions deadline exceeded after 1.999963417s ...)
```

La respuesta HTTP tardó lo que el plazo, no lo que el proveedor; el pedido quedó pendiente; el
servidor, al despertar, vio el contexto cancelado y no respondió. Ni `REJECTED` ni `500`.

### Proveedor caído

```text
python3 06-talleres/laboratorio/scripts/lab.py grpc fault unavailable
```

```text
fault: {"mode":"unavailable","latencyMs":3000}
0.14s → orderStatus=PAYMENT_PENDING payment=PENDING code=None
WARN payments: UNAVAILABLE for operation unav-pay-0001 → PENDING (payments provider is down (injected))
```

Y después, con el proveedor recuperado (`grpc fault none`):

```text
$ POST /orders/{id}/payment  Idempotency-Key: unav-pay-0002
{"status":409,"title":"Order not payable","code":"ORDER_NOT_PAYABLE","detail":"order is PAYMENT_PENDING"}
$ POST /orders/{id}/payment  Idempotency-Key: unav-pay-0001
HTTP/1.1 200
Idempotent-Replay: true
```

Un pedido pendiente no se vuelve a cobrar por HTTP con otra clave (`409`): la máquina de estados
del taller 03 lo impide. Con la misma clave, la respuesta guardada. Resolver un `PAYMENT_PENDING`
es otro caso de uso (consultar al proveedor por `operation_id`): el ejercicio 6.

### El proveedor que no responde al primer intento: la idempotencia del proveedor

Con el proveedor real, el `UNAVAILABLE` del importe `666.00` ocurre **antes** de que el servidor
guarde una decisión; un `DEADLINE_EXCEEDED` por latencia, después de dormir pero sin responder.
En ninguno de los dos el servidor recuerda nada, y por eso el cliente no puede saber si cobró: es
exactamente la incertidumbre que `PENDING` representa. Si el proveedor hubiera decidido y la
respuesta se hubiera perdido en la red, la misma `operation_id` recuperaría esa decisión
("replaying previous answer"). El ejercicio 3 lo fuerza.

## 8. 🧪 Evidencia

La suite HTTP de `06/01` con `hex.payment.provider=grpc`, 2026-09-28:

```text
Success v1/01-health.hurl (1 request(s) in 2 ms)
Success v1/02-auth.hurl (9 request(s) in 542 ms)
Success v1/03-products.hurl (12 request(s) in 316 ms)
Success v1/04-orders.hurl (20 request(s) in 355 ms)
Success v1/05-payment.hurl (14 request(s) in 457 ms)
Success v1.1/06-cancel.hurl (19 request(s) in 312 ms)
Success v1.1/07-notifications.hurl (10 request(s) in 2302 ms)
Executed requests: 85 (19.8/s)
Succeeded files:   7 (100.0%)
Duration:          4295 ms (0h:0m:4s:295ms)
```

Y lo que el proveedor vio pasar, en su terminal:

```text
INFO authorize suite-05-pay-expensive 1499.00 USD (fault=none)
INFO authorize suite-05-pay-expensive-retry 1499.00 USD (fault=none)
INFO authorize suite-05-pay-uncertain 666.00 USD (fault=none)
INFO authorize suite-06-pay-paid 10.00 USD (fault=none)
WARN payments: UNAVAILABLE for operation suite-05-pay-uncertain → PENDING (provider did not answer)     ← cliente
```

La prueba del adaptador contra un servidor en proceso (cuatro casos: dinero como texto y
`AUTHORIZED`; `UNAVAILABLE` → `PENDING`; `DEADLINE_EXCEEDED` → `PENDING`; `INVALID_ARGUMENT` →
excepción), con el resto de las pruebas del sabor:

```text
[INFO] Tests run: 17, Failures: 0, Errors: 0, Skipped: 0
[INFO] BUILD SUCCESS
```

Inventario (el código se generó de una vez; quien lo haga en un commit obtendrá este
`git diff --stat`):

```text
$ git diff --stat -- src/main/java/hex/orders/domain src/main/java/hex/orders/application
                        (vacío)
$ wc -l contrato/proto/payments.proto outbound/payment/grpc/GrpcPaymentGateway.java config/PaymentsGrpcConfiguration.java test/.../GrpcPaymentGatewayTest.java
      40 payments.proto
      66 GrpcPaymentGateway.java
      20 PaymentsGrpcConfiguration.java
      82 GrpcPaymentGatewayTest.java
$ wc -l payments-grpc/pom.xml payments-grpc/src/main/resources/application.yaml payments-grpc/src/main/java/hex/payments/*.java
     220 total
```

Además: `DeterministicPaymentGateway` (+1 anotación), `HexProperties` (+1 record),
`application.yaml` (+9 líneas), `pom.xml` (+2 dependencias, +1 plugin), `lab.py` (+3 órdenes).

**Cinco plataformas:** no aplica. Es un taller de integración, solo Java (guía §10.3).

## 9. 🩺 Errores provocados a propósito

Dos reales, los dos de configuración, y los dos con el mismo síntoma engañoso.

### `channels` y `address`: dos claves renombradas que se ignoran en silencio

```text
WARN [Channel<1>: (payments)] Failed to resolve name. status=Status{code=UNAVAILABLE, description=Unable to resolve host payments, ...}
WARN payments: UNAVAILABLE for operation suite-05-pay-cheap → PENDING (Unable to resolve host payments)
```

La primera versión escribía `spring.grpc.client.channels.payments.address`, la forma de Spring
gRPC 0.x. Boot 4 la ignoró (no existe), `createChannel("payments")` no encontró ningún canal con
ese nombre y tomó `payments` como **host**. Corregir `channels` → `channel` no bastó: el campo se
llama `target`, no `address`. Los metadatos del módulo (`spring-configuration-metadata.json` en
`spring-boot-grpc-client`) y un `javap` de `GrpcClientProperties$Channel` lo zanjaron. Lección: una
propiedad de configuración que no existe no falla; y en gRPC "no encontrado" se parece a "caído".

### La degradación fue correcta aunque la causa fuera absurda

Con el canal apuntando a un host inexistente, la suite dio `Failure` en `05-payment` y
`06-cancel`... y **cero** errores 500: cada cobro devolvió `PENDING` y el pedido quedó
`PAYMENT_PENDING`. El adaptador trató "no puedo hablar con el proveedor" como lo que es, una
incertidumbre, y el sistema siguió sirviendo el resto. Lección: la traducción de códigos que el
taller enseña no es para el día en que el proveedor cae; es para cualquier día en que algo entre
los dos no funcione, incluida una clave mal escrita en el `yaml`.

## 10. 🧹 Teardown

`Ctrl+C` en las terminales de `lab.py java` y `lab.py payments-grpc`; el servidor cierra el canal
y cancela las llamadas en curso. `lab.py down` apaga el entorno. `payments-grpc/target/` (con los
stubs generados) está en `.gitignore`; el `.proto` es lo único que se versiona.

## ⚠️ Errores frecuentes

- "Timeout significa que no hubo cobro." Significa que no hubo *respuesta*. El cobro pudo
  ocurrir; solo la misma clave lo puede decir.
- "El deadline se pone una vez en el stub." Un `withDeadline` absoluto en el stub caduca para
  siempre; el plazo se calcula en cada llamada.
- "`double` para el importe, que es lo natural en protobuf." `49.90` no es representable; el
  contrato manda texto decimal, como en HTTP.
- "El `.proto` se genera del código." El `.proto` es el contrato y el código se genera de él, en
  cada build, sin versionar los stubs.
- "`UNAVAILABLE` se reintenta en bucle en el adaptador." Un reintento inmediato contra un proveedor
  caído lo hunde más; el pedido queda pendiente y otro proceso, con espera, lo resuelve.

## ✅ Veredicto

Sustituir el proveedor en proceso por uno remoto costó 66 líneas de adaptador y ninguna del
núcleo. Lo que el taller enseña no está en el stub, sino en tres decisiones del adaptador: un
plazo en cada llamada, la clave de idempotencia en la cabecera, y que `UNAVAILABLE` y
`DEADLINE_EXCEEDED` son "no sé", no "no". Los dos errores reales fueron claves de configuración
renombradas en silencio; que el sistema degradara a `PENDING` en vez de a `500` mientras tanto es
la mejor prueba de que la traducción de códigos estaba en el sitio correcto.

## 📚 Referencias

- [gRPC: deadlines](https://grpc.io/docs/guides/deadlines/) · [códigos de estado](https://grpc.io/docs/guides/status-codes/) · [manejo de errores](https://grpc.io/docs/guides/error/) · [metadata](https://grpc.io/docs/guides/metadata/) · [Java: basics](https://grpc.io/docs/languages/java/basics/)
- [Protocol Buffers: guía de proto3](https://protobuf.dev/programming-guides/proto3/) · [`google.rpc.Status`](https://github.com/googleapis/googleapis/blob/master/google/rpc/status.proto) · [AIP-193: errores](https://google.aip.dev/193)
- [Spring gRPC: referencia](https://docs.spring.io/spring-grpc/reference/index.html) · [servidor](https://docs.spring.io/spring-grpc/reference/server.html) · [cliente](https://docs.spring.io/spring-grpc/reference/client.html)
- [protobuf-maven-plugin (ascopes)](https://ascopes.github.io/protobuf-maven-plugin/)

## 🧠 Preguntas

1. 🟢 ¿Por qué `AuthorizePayment` no cambió al sustituir el proveedor en proceso por uno remoto?
2. 🟢 ¿Por qué `Money` en el `.proto` es texto y no `double`?
3. 🟢 ¿Qué códigos gRPC se traducen a `PENDING`, cuáles a excepción, y por qué esa línea y no otra?
4. 🟢 ¿Por qué la respuesta del proveedor no tiene un estado `PENDING`?
5. 🟢 ¿Qué hace `STATUS_UNSPECIFIED = 0` en el enum y cómo lo trata el cliente?
6. 🟡 ¿Por qué el deadline se pone con `withDeadlineAfter` en cada llamada y no una vez al crear el stub?
7. 🟡 La latencia de 3 s con plazo de 2 s devolvió `PENDING` en 2,17 s y el servidor dijo "the client gave up". ¿Qué hizo cada lado y qué habría pasado sin `Context.current().isCancelled()`?
8. 🟡 ¿Para qué viaja la clave de idempotencia en metadata si ya va en el cuerpo?
9. 🟡 ¿Por qué el `.proto` vive en `contrato/` y los stubs no se versionan?
10. 🟡 Un pedido `PAYMENT_PENDING` respondió `409` a un nuevo intento de pago. ¿Es correcto? ¿Quién lo resuelve y cómo?
11. 🟠 El canal apuntó a un host inexistente y la suite falló en dos archivos pero sin ningún 500. Explica por qué eso es una degradación correcta y qué habría sido incorrecto.
12. 🟠 Compara el `PaymentGateway` con un cliente HTTP al mismo proveedor: qué cambia en la traducción de errores (`problem+json` vs `Status`), en los plazos y en la idempotencia.
13. 🟠 `payments-grpc` guarda las decisiones en un `ConcurrentHashMap`. ¿Qué garantía da y cuál no? ¿Qué necesitaría un proveedor real para que "misma clave, misma respuesta" sobreviva a su propio reinicio?
14. 🟠 Dos claves de `yaml` renombradas se ignoraron en silencio y produjeron un síntoma de red. ¿Cómo se detecta esto antes de arrancar, y qué papel juegan los metadatos de configuración y `@ConfigurationProperties` tipadas?

## 🧪 Ejercicios

1. 🟢 Baja `hex.payment.deadline-ms` a `500` y corre la suite con el proveedor gRPC sin fallos.
   ¿Sigue en verde? Sube la latencia inyectada a `600` y repite. Explica qué mide cada resultado.
2. 🟢 Escribe en `payments.proto` un campo `double amount_value = 3` en `Money`, regenera y manda
   `49.90`. Imprime lo que llega al servidor y explica por qué el contrato lo prohíbe.
3. 🟡 Fuerza la idempotencia del proveedor: con `grpc fault none`, llama dos veces a `Authorize`
   con la misma `operation_id` desde una prueba contra `payments-grpc` real (un `ManagedChannel`
   a `localhost:19090`) y comprueba en el log "replaying previous answer". Explica qué diferencia
   hay entre esta prueba y la del servidor en proceso.
4. 🟡 Añade un `ClientInterceptor` que propague un `deadline` **entrante** (de una petición gRPC
   de entrada, ejercicio 8) al proveedor sin ampliarlo: `min(plazo propio, plazo restante)`.
   Explica por qué "nunca ampliar" y qué pasa si el plazo restante ya es cero.
5. 🟠 Sustituye la traducción a `PENDING` por tres reintentos inmediatos ante `UNAVAILABLE`
   (`withRetry` o un bucle). Corre `grpc fault unavailable` y mide cuántas llamadas recibe el
   proveedor por cada pago. Argumenta cuándo reintentar en el adaptador es correcto y cuándo es
   una tormenta.
6. 🟠 Implementa `ResolvePendingPayment`: un caso de uso que, para un pedido `PAYMENT_PENDING`,
   consulta al proveedor por `operation_id` (añade `rpc Lookup` al `.proto`) y aplica la decisión
   si existe. Explica qué transición nueva necesita `Order` y por qué el `operation_id` es la única
   llave posible.
7. 🔴 Sustituye `Status.UNAVAILABLE.withDescription(...)` en el servidor por un error rico con
   `google.rpc.Status` y `ErrorInfo` (razón `PROVIDER_DOWN`, dominio `payments.hex`), y haz que el
   cliente lo lea con `StatusProto.fromThrowable`. Explica qué gana el cliente frente a un texto
   en `description` y cómo se mapearía a `problem+json` si el error tuviera que salir por HTTP.
8. 🔥 Entrada gRPC: expón `OrderService.CreateOrder` en el backend Java (starter de servidor)
   sobre el mismo `CreateOrder` que sirven HTTP y la cola, con el actor sacado de metadata
   `authorization: Bearer <jwt>` (el mismo `JwtDecoder`), la clave de idempotencia en metadata,
   y `google.rpc.Status` con `ErrorInfo.reason = INSUFFICIENT_INVENTORY` donde HTTP daría
   `problem+json`. Propaga el deadline entrante al proveedor de pagos (ejercicio 4). ¿Qué parte de
   `ProblemHandler` tuviste que duplicar y qué parte pudiste compartir?

---

**Siguiente:** [11 — Lotes con Spring Batch](11-lotes-spring-batch.md), la última integración.
