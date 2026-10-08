# 07 — Observabilidad de extremo a extremo

Este taller es **opcional** y depende de [`06` — Kafka: outbox, inbox, idempotencia y DLQ](06-kafka-outbox-inbox-y-dlq.md):
parte de su sistema. Hasta aquí, para saber qué le pasó a un pedido había que leer cinco logs y
adivinar qué línea iba con cuál. Ahora cada servicio emite **trazas** con OpenTelemetry —Java con el
agente, Go y Python con su SDK— hacia un collector, y un Jaeger las guarda. Una traza cruza Envoy, HTTP,
gRPC y Kafka en tres runtimes, y cada línea de log lleva su `trace_id`. La provocación es la que
predice [`04/04`](../04-operacion-y-resiliencia/04-observabilidad-y-trazas.md#4--dónde-se-pierde-el-contexto):
**la traza se corta en Kafka**; el matiz es que el mensaje sí lleva `traceparent`, pero el equivocado.
Termina con la suite `v1` en verde, la traza completa en texto y la corrección en el productor y en
los dos consumidores.

> Ejercita [`04/04` — Observabilidad y trazas](../04-operacion-y-resiliencia/04-observabilidad-y-trazas.md).
>
> **Vigencia:** 2026-09-29. Versiones verificadas ese día en Maven Central, Docker Hub, `proxy.golang.org`
> y PyPI; salidas corridas ese día en un Apple M1 Pro con Docker Desktop.

**Salto rápido:** [1](#1--qué-enseña-este-taller) · [2](#2--prerrequisitos-y-versiones) · [3](#3-️-mapa-de-carpetas) · [4](#4--recorrido-de-la-base-de-código) · [5](#5--una-traza-que-cruza-tres-runtimes) · [6](#6--logs-con-trace_id) · [7](#7--provocación-la-traza-se-corta-en-kafka) · [8](#8--provocación-media-corrección) · [9](#9--errores-reales-al-correrlo) · [10](#10--en-tres-plataformas) · [11](#11--teardown) · [Preguntas](#-preguntas) · [Ejercicios](#-ejercicios)

---

## 1. 🎯 Qué enseña este taller

```text
lab.py buy ── traceparent ──► Envoy ──► orders (Java, agente) ──► monolith (Java, agente) ──► inventory HTTP (Go)
                                          │  gRPC ──► inventory (Go, otelgrpc)
                                          │  HTTP ──► payments (Python, instrumentors) ──► psp (sin instrumentar)
                                          │  tx { … + outbox_events(trace_context) }
                                          ▼
                              OutboxPublisher ── traceparent en los encabezados ──► orders.events
                                                                                      ├─► inventory (extrae a mano)
                                                                                      └─► payments (extrae a mano)
todos ── OTLP ──► ms-otel-collector (tail sampling) ──► ms-jaeger ◄── lab.py trace
```

Cuatro ideas:

- **Una traza es un árbol de spans unidos por un contexto que viaja.** Por HTTP y gRPC viaja solo si
  cliente y servidor están instrumentados; el formato común es W3C Trace Context (`traceparent`), y es
  lo que permite que Java, Go y Python compongan una sola traza.
- **Qué te da hecho cada plataforma es muy distinto.** El agente de Java instrumenta HTTP, gRPC, JDBC,
  Hibernate, Kafka y `@Scheduled` sin una línea de código. En Go se escribe el SDK, los interceptores y el
  adaptador de encabezados de Kafka. Python queda en medio: un "instrumentor" por biblioteca.
- **La traza se corta donde el trabajo cambia de hilo y de transacción.** El publicador del outbox corre
  en otro hilo, más tarde; el agente pone en el mensaje el contexto que **encuentra**, que es el de la ronda
  del planificador. La corrección guarda el contexto de la petición **en la fila** del outbox.
- **No todo lo que se traza merece guardarse.** El sondeo del outbox genera cinco trazas por segundo que
  no dicen nada. El collector decide con la traza completa qué se queda.

El precio, en las cinco monedas: **latencia** (exportar va en lotes y en segundo plano; el agente alarga
el arranque de `orders` de 5,1 a 6,3 s en esta máquina), **consistencia** (lo que ves depende del
muestreo: el collector retiene cada traza 5 s antes de decidir), **operación** (un collector y un backend
más que vigilar, y una política de muestreo que mantener), **dinero** (en producción los backends de
trazas cobran por volumen: el muestreo es una decisión de coste) y **esfuerzo** (≈ 50 líneas de Java,
todas por el outbox; 104 de Go; 66 de Python).

## 2. 🧰 Prerrequisitos y versiones

| Herramienta | Versión fijada | Para qué |
|---|---|---|
| Todo lo de `06/06` | la de `06/06` §2 | el sistema completo |
| `opentelemetry-javaagent` | `2.31.1` | instrumentación de `orders` y del monolito sin código; se descarga con Maven |
| `io.opentelemetry:opentelemetry-api` | la del BOM de Boot 4.1.1 (`1.62.0`) | la API que usa el outbox; la implementa el agente |
| `go.opentelemetry.io/otel` (+ `sdk`, `otlptracegrpc`) | `v1.46.0` | SDK y exportador de `inventory` |
| `otelgrpc` · `otelhttp` | `v0.71.0` | servidor gRPC y HTTP de `inventory` |
| `opentelemetry-sdk` · `opentelemetry-exporter-otlp-proto-grpc` | `1.45.0` | SDK y exportador de `payments` |
| `opentelemetry-instrumentation-fastapi` · `-httpx` · `-psycopg` | `0.66b0` | servidor, cliente del PSP y base de `payments` |
| `otel/opentelemetry-collector-contrib` | `0.161.0` | el collector, con `tail_sampling` (§9) |
| `jaegertracing/jaeger` | `2.21.0` | backend todo en uno, en memoria |

```text
python3 laboratorio/scripts/lab.py up
python3 laboratorio/scripts/lab.py seed --kafka                                   # con los consumidores PARADOS
python3 laboratorio/scripts/lab.py psp                                            # terminal 1
python3 laboratorio/scripts/lab.py inventory                                      # terminal 2
python3 laboratorio/scripts/lab.py payments                                       # terminal 3
python3 laboratorio/scripts/lab.py monolith --inventory remote --payments remote  # terminal 4
python3 laboratorio/scripts/lab.py orders                                         # terminal 5
```

- `up` levanta ahora `ms-otel-collector` (OTLP/gRPC en `24317`, OTLP/HTTP en `24318`) y `ms-jaeger` (interfaz
  y API en `26686`). Envoy manda sus spans al collector por la red de Compose.
- `monolith` y `orders` arrancan con `-javaagent` cuando el compose trae el collector. La primera vez,
  `lab.py` descarga el agente con `mvn dependency:copy` a `laboratorio/tools/otel/`; no se instala nada
  en el sistema ni se versiona el `.jar`.
- `inventory` recibe `-otlp localhost:24317` y `payments` la variable `PAYMENTS_OTLP`; sin ellas, el SDK
  queda en *no-op* y el servicio funciona igual.

Las órdenes nuevas:

```text
python3 laboratorio/scripts/lab.py buy [--sku SKU-002] [--qty 1] [--then pay|cancel|nothing]
python3 laboratorio/scripts/lab.py trace [TRACE_ID] [--service envoy] [--operation OP] [--list]
python3 laboratorio/scripts/lab.py orders --no-trace-outbox
python3 laboratorio/scripts/lab.py inventory --no-trace-kafka
python3 laboratorio/scripts/lab.py payments --no-trace-kafka
```

- `buy` crea un pedido por Envoy y lo paga (o lo cancela). Cada petición lleva un `traceparent` que
  inventa `lab.py`, y Envoy **continúa** esa traza: el id se conoce antes de buscarlo.
- `trace ID` imprime una traza como árbol, desde la API v3 de Jaeger: desfase desde el inicio, duración,
  servicio, tipo de span, operación y atributos útiles (código HTTP, estado gRPC, partición, offset).
  Sin id, la última del servicio; con `--list`, la lista.
- `--no-trace-outbox` no guarda el contexto en la fila del outbox; `--no-trace-kafka` hace que el
  consumidor no lea el `traceparent` del mensaje. Son las dos mitades de la provocación.

> **📝 Contexto:** el código tal como queda al terminar este taller está congelado en
> `laboratorio/estados/07/`, y las rutas con número de línea se refieren a esa copia. Si ya existen
> talleres posteriores, añade `--estado 07` a cada orden de `lab.py`.

## 3. 🗂️ Mapa de carpetas

```text
laboratorio/estados/07/                            (lab.py --estado 07)
├── contrato/
│   ├── docker-compose.yml                         + ms-otel-collector, ms-jaeger
│   ├── otel/collector.yaml                        receptor OTLP, tail_sampling, exportador a Jaeger
│   ├── envoy/envoy.yaml                           + tracing (OpenTelemetry) y trace= en el access log
│   └── seed/orders/schema.sql                     outbox_events: + trace_context
├── orders/.../events/
│   ├── OrderEvents.java                           guarda el traceparent de la petición en la fila
│   └── OutboxPublisher.java                       envía DENTRO de ese contexto
├── inventory/internal/telemetry/telemetry.go      SDK, exportador, propagador y adaptador de encabezados de Kafka
├── inventory/internal/consumer/consumer.go        extrae el contexto y abre el span de consumidor
├── payments/app/telemetry.py                      SDK, instrumentors y trace_id en el log
└── payments/app/consumer.py                       extrae el contexto y abre el span de consumidor
```

## 4. 🔎 Recorrido de la base de código

Rutas relativas a `laboratorio/estados/07/`.

**¿Dónde se instrumenta Java?** En ningún archivo: `lab.py` arranca la JVM con `-javaagent` y cuatro
variables (`OTEL_SERVICE_NAME`, `OTEL_EXPORTER_OTLP_ENDPOINT` y los exportadores de métricas y logs
apagados). Lo único escrito a mano es el patrón de log: `orders/src/main/resources/application.yaml`,
línea 82, imprime `trace_id` y `span_id`, que el agente deja en el MDC.

**¿Dónde se pierde el contexto y cómo se recupera?** `orders/.../events/OrderEvents.java`: la línea 66
inserta en `outbox_events` el resultado de `currentTraceparent()` (línea 73), que **inyecta** el contexto
actual en un mapa con el propagador W3C (línea 78) mientras la petición sigue en curso. En
`OutboxPublisher.java`, `parentOf` (línea 70) lo **extrae** de la fila (línea 75), y la línea 60 hace el
envío dentro de ese contexto con `makeCurrent()`.

**¿Dónde se instrumenta Go?** `inventory/internal/telemetry/telemetry.go`: exportador OTLP/gRPC (línea 24),
lotes en segundo plano (línea 34) y propagador W3C (línea 39). En `cmd/inventory/main.go`,
`otelgrpc.NewServerHandler()` (línea 82) y `otelhttp.NewHandler` (línea 95). El adaptador de encabezados de
Kafka empieza en `telemetry.go`, línea 47, y lo usa `consumer.go` en la línea 77 para extraer el contexto
antes de abrir el span de consumidor (línea 80).

**¿Y Python?** `payments/app/telemetry.py`: `BatchSpanProcessor` (línea 28) y los instrumentors de `httpx`
y `psycopg` (líneas 30–31), que se activan **antes** de crear el pool y el cliente. El de FastAPI va en
`app/main.py`, línea 64. El consumidor extrae en `app/consumer.py`, línea 46, y abre su span en la 47.

**¿Quién decide qué se guarda?** `contrato/otel/collector.yaml`: el procesador `tail_sampling` (línea 15)
con dos políticas, "entró por el gateway" (línea 23) y "pasó por Kafka" (línea 29).

## 5. 🧱 Una traza que cruza tres runtimes

```text
python3 laboratorio/scripts/lab.py buy
python3 laboratorio/scripts/lab.py trace d8019b2a4b5b4c199aa588532365cdaa
```

- `trace` espera 3 s antes de preguntar (`--wait`): el collector retiene la traza para decidir y los SDK
  exportan en lotes.

El alta de un pedido, 2026-09-29, con el sistema ya caliente:

```text
order    201 CONFIRMED  28 ms  trace=d8019b2a4b5b4c199aa588532365cdaa
payment  200 None  30 ms  trace=af6d97eb1f8c41f987b7f9c3c4d2fcb1
traza d8019b2a4b5b4c199aa588532365cdaa  ·  25 spans  ·  envoy, inventory, monolith, orders, payments
  (padre fa899eef… ausente: el span del cliente, que no exporta a ningún collector)
       0.0 ms     25.6 ms  envoy     server   ingress  http=201
       1.2 ms     24.5 ms    orders    server   POST /api/v1/orders  http=201
       2.2 ms      0.5 ms      orders    client   SELECT ms_orders.idempotency_keys
       2.7 ms      0.3 ms      orders    internal Transaction.commit
       3.3 ms     10.7 ms      orders    client   GET  http=200
       4.1 ms      9.5 ms        monolith  server   GET /api/v1/products  http=200
       5.4 ms      3.2 ms          monolith  internal ProductRepository.findAll
       5.8 ms      2.0 ms            monolith  internal SELECT dev.ms.monolith.entity.Product
       6.3 ms      1.1 ms              monolith  client   SELECT ms_monolith.products
       7.9 ms      0.7 ms            monolith  internal Transaction.commit
       8.8 ms      3.6 ms          monolith  client   GET  http=200
      10.2 ms      1.3 ms            inventory server   GET /stock  http=200
      14.5 ms      6.3 ms      orders    client   ms.inventory.v1.InventoryService/Hold  grpc=0
      16.1 ms      4.1 ms        inventory server   ms.inventory.v1.InventoryService/Hold
      21.0 ms      1.1 ms      orders    internal OrderRepository.save
      21.2 ms      0.9 ms        orders    internal Session.merge dev.ms.orders.entity.Order
      21.3 ms      0.4 ms          orders    client   SELECT ms_orders
      22.4 ms      0.3 ms      orders    client   INSERT ms_orders.outbox_events
      22.9 ms      0.3 ms      orders    client   INSERT ms_orders.idempotency_keys
      23.2 ms      2.0 ms      orders    internal Transaction.commit
      23.5 ms      0.4 ms        orders    client   INSERT ms_orders.orders
      24.1 ms      0.5 ms        orders    client   INSERT ms_orders.order_lines
     134.6 ms     11.3 ms      orders    producer orders.events publish  partition=0 offset=13
     145.8 ms      0.0 ms        inventory consumer orders.events process  partition=0 offset=13 event=OrderPlaced
     146.6 ms      0.0 ms        payments  consumer orders.events process  partition=0 offset=13 event=OrderPlaced
```

- Cinco servicios, tres runtimes y tres transportes en un árbol. El catálogo va `orders` → monolito →
  `inventory` por HTTP; la retención, `orders` → `inventory` por gRPC; el hecho, `orders` → Kafka → los dos
  consumidores.
- El productor empieza 110 ms **después** de que el cliente recibiera su `201`: es el sondeo del outbox,
  visible por primera vez. En cinco pagos seguidos, ese retraso fue de 7, 28, 111, 132 y 208 ms, coherente
  con una ronda cada 200 ms.
- `inventory` no tiene spans de base de datos: nadie instrumentó `pgx` (ejercicio 3). En Java aparecen
  solos, incluidos los de Hibernate.
- Los clientes HTTP de Java y Go nombran su span solo con el método (`GET`): no conocen la plantilla de la
  ruta; el servidor sí (`GET /api/v1/products`).
- El `None` del pago es un defecto de `lab.py` en esa corrida (el pago responde `orderStatus`, no
  `status`); ya imprime `PAID`.

Y el pago, sin los spans de base de datos (`grep -v` sobre la misma salida):

```text
traza af6d97eb1f8c41f987b7f9c3c4d2fcb1  ·  35 spans  ·  envoy, inventory, orders, payments
       0.0 ms     28.3 ms  envoy     server   ingress  http=200
       1.6 ms     26.8 ms    orders    server   POST /api/v1/orders/{orderId}/payment  http=200
       5.4 ms     10.9 ms      orders    client   POST  http=201
       8.0 ms      7.8 ms        payments  server   POST /payments  http=201
      10.5 ms      3.3 ms          payments  client   POST  http=201
      24.1 ms      3.8 ms      orders    client   ms.inventory.v1.InventoryService/Commit  grpc=0
      25.6 ms      1.6 ms        inventory server   ms.inventory.v1.InventoryService/Commit
     119.7 ms      8.4 ms      orders    producer orders.events publish  partition=0 offset=14
     128.2 ms      2.4 ms        inventory consumer orders.events process  partition=0 offset=14 event=OrderPaid verdict=applied
     128.9 ms      0.0 ms        payments  consumer orders.events process  partition=0 offset=14 event=OrderPaid
```

- El `POST` de `payments` al PSP tiene span de **cliente** y ningún span de servidor debajo: el PSP es de
  otro, y no exporta nada. De un tercero solo se ve cuánto tardó en contestar.
- El `OrderPaid` llega a los dos grupos; `inventory` lo aplica (`verdict=applied`) y `payments` lo ignora.

**Lo que la traza enseña sin buscarlo.** La primera petición tras arrancar, 2026-09-29:

```text
     228.4 ms    381.7 ms      orders    client   ms.inventory.v1.InventoryService/Hold  grpc=0
     577.1 ms     12.3 ms        inventory server   ms.inventory.v1.InventoryService/Hold
    1064.2 ms    404.6 ms      orders    producer orders.events publish  partition=2 offset=0
```

- El servidor tardó 12 ms; el cliente, 382. La diferencia es de antes de que el servidor viera la
  petición: la conexión HTTP/2 que el canal gRPC abre en la primera llamada.
- El primer envío a Kafka tardó 405 ms frente a los 8–11 ms de después: el productor pide los metadatos
  del topic en el primer `send`.
- Es el "calentamiento" que un log con la duración total esconde, y el motivo de las sondas de arranque
  y del *warm-up* antes de recibir tráfico.

> **Veredicto:** una traza responde "dónde se fue el tiempo" sin conjeturas, entre runtimes. Lo que no
> se instrumentó —`pgx`, el PSP— queda como un hueco con nombre: se sabe qué no se ve.

## 6. 🧱 Logs con `trace_id`

**Qué es.** Cada línea de log lleva el id de la traza en curso: del log se salta a la traza, y de la
traza a los logs. En Java lo pone el agente en el MDC; en Go y Python, el código.

Un pago y una cancelación, buscados por los 8 primeros caracteres de su traza en los logs de `orders`,
`payments`, `inventory` y el monolito, y en el access log de Envoy, 2026-09-29:

```text
=== 445607d8
2026-09-29 10:59:16,363 INFO [trace=445607d8] HTTP Request: POST http://localhost:28185/payments "HTTP/1.0 201 Created"
2026-09-29 10:59:16,365 INFO [trace=445607d8] payment 53205749-9c18-4abb-9416-ce76dea2a0ad order=59fd632e-1d8f-495e-9a86-48e90a75d975 key=buy-pay-59fd632e-1d8f-495e-9a86-48e90a75d975 → AUTHORIZED
2026/09/29 10:59:16 p1 o9 OrderPaid 22341412 → applied [trace=445607d8]
15:59:16 POST /api/v1/orders/59fd632e-1d8f-495e-9a86-48e90a75d975/payment → 200 26ms upstream=192.168.65.254:28082 attempts=1 - via_upstream trace=445607d8175c49e4a098b892fe1eba8a
=== 0c2ac916
2026-09-29 10:59:16,238 INFO [trace=0c2ac916] OrderCancelled 23aaae0d order=314476a7 → 0 pending payment(s) voided
15:59:16 POST /api/v1/orders/314476a7-6f2d-4e55-a0b3-9faf17fb4a36/cancel → 200 12ms upstream=192.168.65.254:28082 attempts=1 - via_upstream trace=0c2ac9160b1b45b4900dc1a9d3c5dedc
```

- El consumidor de Go escribe su línea **con el trace de la petición HTTP** que originó el evento, en otro
  proceso y después de pasar por Kafka; lo mismo el de Python con la cancelación.
- `orders` no aparece: en el camino feliz no escribe nada. Aparece en cuanto algo falla.
- Envoy registra en UTC (`15:59:16`); los servicios, en hora local (`10:59:16`). El `trace_id` no tiene
  zona horaria: es la clave de unión que no depende de relojes.
- Los logs de Go y Python recortan el id a 8 caracteres para leer mejor en el taller; en producción va
  entero (ejercicio 4).

Un pago con `payments` parado:

```text
payment  503 503  564 ms  trace=ff01591c947c4cc69ef5d47b93f8eb37
traza ff01591c947c4cc69ef5d47b93f8eb37  ·  12 spans  ·  envoy, orders
       0.0 ms    561.5 ms  envoy     server   ingress  http=503 ERROR
       0.9 ms    560.3 ms    orders    server   POST /api/v1/orders/{orderId}/payment  http=503 error=503 ERROR
       5.2 ms      3.7 ms      orders    client   POST  error=java.io.IOException ERROR
     116.3 ms      3.2 ms      orders    client   POST  error=java.io.IOException ERROR
     536.7 ms      8.9 ms      orders    client   POST  error=java.io.IOException ERROR
WARN … [trace=ff01591c947c4cc69ef5d47b93f8eb37 span=87ec38ba0fa60b7a] dev.ms.orders.payments.RemotePayments    : payments: retry 1 after 102 ms (ResourceAccessException)
WARN … [trace=ff01591c947c4cc69ef5d47b93f8eb37 span=87ec38ba0fa60b7a] dev.ms.orders.payments.RemotePayments    : payments: retry 2 after 407 ms (ResourceAccessException)
WARN … [trace=ff01591c947c4cc69ef5d47b93f8eb37 span=87ec38ba0fa60b7a] dev.ms.orders.web.ApiErrors              : POST /api/v1/orders/5e3fc430-103e-4ff3-8f62-dc7f1ff290bb/payment: payments unavailable: I/O error on POST request for "
```

- Los tres intentos del reintento de `06/03` son tres spans de cliente, separados por la espera con
  *backoff* (102 y 407 ms). En el log son tres líneas; en la traza, además, se ve cuánto pesó cada
  espera en los 560 ms que vio el cliente.
- El `503 503` es otro defecto de `lab.py` en esa corrida: imprimía `status` antes que `code`; ya imprime
  `PAYMENTS_UNAVAILABLE`.

> **Veredicto:** con el `trace_id` en cada línea, los logs dejan de ser cinco ficheros y pasan a ser una
> consulta. Sin él, correlacionar es comparar horas —en dos zonas horarias— y esperar que no haya dos
> pedidos en el mismo segundo.

## 7. 🧨 Provocación: la traza se corta en Kafka

```text
python3 laboratorio/scripts/lab.py orders --no-trace-outbox
python3 laboratorio/scripts/lab.py inventory --no-trace-kafka
python3 laboratorio/scripts/lab.py payments --no-trace-kafka
```

- Es el código que escribe cualquiera que no haya pensado en el outbox: el agente instrumenta Kafka en
  Java, así que "ya está", y los consumidores procesan el mensaje sin mirar sus encabezados.

Un pago, 2026-09-29:

```text
payment  200 PAID  41 ms  trace=3bb6be58e8a446a6921f874da80eeb5a
traza 3bb6be58e8a446a6921f874da80eeb5a  ·  33 spans  ·  envoy, inventory, orders, payments
       0.0 ms     35.4 ms  envoy     server   ingress
…
      31.0 ms      3.9 ms      orders    client   ms.inventory.v1.InventoryService/Commit  grpc=0
      32.7 ms      1.3 ms        inventory server   ms.inventory.v1.InventoryService/Commit
2026/09/29 10:55:07 p2 o3 OrderPaid 5b3c51b3 → applied [trace=32d73260]
```

- La traza termina en `Commit`: ni productor ni consumidores. El `OrderPaid` se aplicó, pero en **otra**
  traza (`32d73260`).

¿Dónde está lo que falta? En tres trazas distintas:

```text
traza 32d732605bdf6d2e36173c501610a17e  ·  1 spans  ·  inventory
       0.0 ms      2.6 ms  inventory consumer orders.events process  partition=2 offset=3 event=OrderPaid verdict=applied
traza ff5e67f6ed4b31e8d31c394338789656  ·  5 spans  ·  orders
       0.0 ms     10.8 ms  orders    internal OutboxPublisher.publish
       0.5 ms      0.5 ms    orders    client   SELECT ms_orders.outbox_events
       1.1 ms      7.8 ms    orders    producer orders.events publish  partition=2 offset=2
       9.0 ms      0.7 ms    orders    client   UPDATE ms_orders.outbox_events
       9.9 ms      0.8 ms    orders    internal Transaction.commit
Partition:2	Offset:1	traceparent:00-99a4b2a9c2744d0d976d07afd0ef1f48-d7cef948030bdcfa-01	47c1dad1-…	{"eventId":"84a85b58-…","type":"OrderPaid",…
Partition:2	Offset:2	traceparent:00-ff5e67f6ed4b31e8d31c394338789656-fd23dacde2456320-03	8089632b-…	{"eventId":"229e4570-…","type":"OrderPlaced",…
Partition:2	Offset:3	traceparent:00-f2ab22c7eba7cde2b9507e0554c0df7a-c337c719408f2b49-03	8089632b-…	{"eventId":"5b3c51b3-…","type":"OrderPaid",…
```

- El consumidor de Go abrió una traza de un solo span: sin extraer el contexto, cada mensaje es una raíz.
- El productor está en la traza de una **ronda del planificador** (`OutboxPublisher.publish`), no en la de
  la petición.
- `kafka tail` lo confirma: el mensaje **sí lleva** `traceparent`. El del offset 3 es `f2ab22c7…`, la
  ronda que lo publicó; el del offset 1, de la corrida anterior con la corrección puesta, es `99a4b2a9…`,
  el pago que lo originó. El agente inyecta el contexto que **encuentra** en el hilo que envía.
- El último campo del `traceparent` son las banderas: `01` (muestreada) en el que genera `lab.py`, `03`
  (muestreada y con id aleatorio, nivel 2 de W3C Trace Context) en el del agente.

**La corrección** tiene dos mitades. En el productor, el contexto se guarda en la fila mientras la
petición está en curso y se restaura al enviar:

```java
// OrderEvents: dentro de la transacción de la petición
GlobalOpenTelemetry.getPropagators().getTextMapPropagator().inject(Context.current(), carrier, Map::put);
jdbc.sql("INSERT INTO outbox_events (id, aggregate_id, type, payload, trace_context) VALUES (?, ?, ?, ?, ?)")…

// OutboxPublisher: en la ronda del planificador, más tarde y en otro hilo
try (var scope = parentOf(e).makeCurrent()) {        // el contexto de la fila, no el de la ronda
    kafka.send(topic, e.aggregateId().toString(), e.payload()).get();
}
```

- `inject` escribe el contexto actual en un mapa con el mismo formato que viaja por HTTP; se guarda solo
  `traceparent`.
- `makeCurrent()` convierte ese contexto en el actual durante el envío; el agente crea el span de
  productor como hijo de la petición y escribe **ese** `traceparent` en el mensaje. El `try` lo deshace al
  salir.

En los consumidores, leer el encabezado y abrir el span como hijo:

```go
ctx = otel.GetTextMapPropagator().Extract(ctx, telemetry.Headers{R: r})
ctx, span := tracer.Start(ctx, Topic+" process", trace.WithSpanKind(trace.SpanKindConsumer), …)
```

```python
parent = propagate.extract({k: v.decode() for k, v in (msg.headers or [])})
with tracer.start_as_current_span(f"{TOPIC} process", context=parent, kind=trace.SpanKind.CONSUMER, …):
```

- `Extract` lee `traceparent` del mensaje con el adaptador `Headers`; si no hay, devuelve el contexto sin
  cambios y el span sale raíz.
- El `ctx` que devuelve `tracer.Start` es el que se pasa a la base: todo lo que cuelgue de él queda en la
  traza de la petición.

Con las dos mitades, el resultado es el de §5: productor y consumidores dentro de la traza del pago.

> **Veredicto:** [`04/04`](../04-operacion-y-resiliencia/04-observabilidad-y-trazas.md#4--dónde-se-pierde-el-contexto)
> dice que la traza se corta porque el mensaje no lleva encabezados. Con un agente, el caso real es más
> traicionero: el mensaje lleva un `traceparent` válido y **equivocado**. El outbox separa el envío de la
> petición en tiempo y en hilo; el contexto tiene que viajar con el hecho, en la misma fila.

## 8. 🧨 Provocación: media corrección

¿Basta con una de las dos mitades? Se probó cada una por separado.

**Solo los consumidores** (`orders --no-trace-outbox`, consumidores sin flag):

```text
traza c6d8a7f7958350dea812345b09a5e2c0  ·  11 spans  ·  inventory, orders, payments
       0.0 ms     30.6 ms  orders    internal OutboxPublisher.publish
       0.3 ms      5.6 ms    orders    client   SELECT ms_orders.outbox_events
       6.1 ms     12.2 ms    orders    producer orders.events publish  partition=2 offset=4
      19.0 ms      0.1 ms      inventory consumer orders.events process  partition=2 offset=4
      19.6 ms      0.0 ms      payments  consumer orders.events process  partition=2 offset=4
      18.4 ms      1.1 ms    orders    client   UPDATE ms_orders.outbox_events
      19.6 ms      8.8 ms    orders    producer orders.events publish  partition=2 offset=5
      28.5 ms      3.7 ms      inventory consumer orders.events process  partition=2 offset=5 event=OrderPaid verdict=applied
      28.9 ms      0.0 ms      payments  consumer orders.events process  partition=2 offset=5
      28.6 ms      0.8 ms    orders    client   UPDATE ms_orders.outbox_events
      29.4 ms      1.1 ms    orders    internal Transaction.commit
```

- Los consumidores se enganchan… a la ronda del planificador. Y esa ronda publicó **dos** hechos —el
  `OrderPlaced` y el `OrderPaid` del mismo pedido, que el sondeo encontró juntos—, así que la traza mezcla
  dos peticiones distintas. Con carga, mezclaría pedidos distintos. Es peor que una traza cortada: es una
  traza que miente.

**Solo el productor** (consumidores con `--no-trace-kafka`):

```text
payment  200 PAID  131 ms  trace=046e53ac77624baabb6e1b014b27e09a
     122.6 ms      6.1 ms      orders    client   ms.inventory.v1.InventoryService/Commit  grpc=0
     125.1 ms      2.4 ms        inventory server   ms.inventory.v1.InventoryService/Commit
     557.2 ms      8.6 ms      orders    producer orders.events publish  partition=2 offset=7
2026/09/29 10:57:22 p2 o7 OrderPaid 0065e15a → applied [trace=15f14a22]
```

- El productor ya está en la traza del pago, y el mensaje lleva el `traceparent` correcto; pero el
  consumidor no lo lee y aplica el evento en su propia traza (`15f14a22`).

> **Veredicto:** propagar el contexto es un contrato de dos lados, como cualquier encabezado. En HTTP lo
> firman las bibliotecas instrumentadas; en Kafka, con un outbox en medio, lo firma tu código en los dos
> extremos.

## 9. 🩺 Errores reales al correrlo

### El sondeo del outbox llenaba Jaeger: cinco trazas por segundo

```text
10:49:27  42fb16f56da011c31f42d39d5a1c3d03    3 spans  orders    OutboxPublisher.publish
10:49:26  d76fb99efef25d66c871c3588b2c3ced    3 spans  orders    OutboxPublisher.publish
10:49:26  ca4cf2866a501c01f9cd9ab03058205a    3 spans  orders    OutboxPublisher.publish
…
```

Sin tráfico, `orders` ya exportaba: el agente traza cada ejecución de `@Scheduled` —una cada 200 ms, con su
`SELECT` y su commit— y cada chequeo de salud de Envoy, uno cada 2 s. **Primer intento:** apagar la
instrumentación del planificador (`OTEL_INSTRUMENTATION_SPRING_SCHEDULING_ENABLED=false`). Empeoró: sin
span padre, el `SELECT` y el `Transaction.commit` de cada ronda salieron como **dos** trazas raíz.

```text
10:50:20  15ecf140f4d9be0d9834a96aa08a3174    1 spans  orders    SELECT ms_orders.outbox_events
10:50:20  06e1046ff1636a1f0e5480260eacdd14    1 spans  orders    Transaction.commit
```

**Corrección:** muestreo por cola en el collector (`tail_sampling`), que decide con la traza completa. Se
guarda la traza si tiene un span de Envoy (tráfico de clientes) o uno de productor o consumidor de Kafka
(una ronda que sí publicó). Las rondas vacías y los chequeos de salud se descartan. **Lección:** el ruido
no se quita apagando instrumentación a ciegas —lo que cuelga de un span apagado se vuelve raíz—, se decide
en un solo sitio con toda la información.

### La primera política perdía justo las trazas de los clientes

```text
payment  200 PAID  134 ms  trace=34ce7aa4ab694d23854a8c2f4d4d846d
la traza 34ce7aa4ab694d23854a8c2f4d4d846d no está en Jaeger
```

La primera versión guardaba las trazas cuya **raíz** no fuera una ronda ni un chequeo
(`IsRootSpan() and name != …`). Pero `lab.py buy` manda su propio `traceparent`, y Envoy lo continúa: su
span tiene padre, y en esa traza **no hay raíz**. Con la corrección de §7 puesta se salvaba por el span de
productor; en la provocación, sin él, la traza entera se descartaba. **Corrección:** decidir por lo que
la traza contiene, no por su raíz. **Lección:** un cliente, un socio o un gateway anterior pueden abrir la
traza por ti; "el primer span que veo" no es "la raíz".

### La etiqueta `0.162.0` de la imagen contrib no existía

```text
Image otel/opentelemetry-collector-contrib:0.162.0 Error failed to resolve reference "docker.io/otel/opentelemetry-collector-contrib:0.162.0": docker.io/otel/opentelemetry-collector-contrib:0.162.0: not found
```

La distribución "core" `0.162.0` estaba publicada; la "contrib", solo con sufijo por arquitectura
(`0.162.0-arm64`, `0.162.0-amd64`…), sin el manifiesto común. **Corrección:** `0.161.0`, que sí lo tiene.
**Lección:** "está en Docker Hub" no es "se puede usar en todas las máquinas del equipo"; se comprueba la
etiqueta exacta.

### El exportador `otlp` avisaba al arrancar, y la API de Jaeger no estaba donde se esperaba

```text
warn	builders/builders.go:40	"otlp" alias is deprecated; use "otlp_grpc" instead
/api/services → 404
/api/v3/services → 200
```

En la `0.16x` del collector, el exportador `otlp` pasó a llamarse `otlp_grpc`; y Jaeger 2.21 ya no sirve
la API interna de su interfaz en `/api/…`. **Corrección:** `otlp_grpc/jaeger` en el collector, y `lab.py
trace` sobre la API v3, que es la documentada y devuelve OTLP en JSON. **Lección:** en herramientas que
cambian cada mes, se usa la interfaz que el proyecto documenta como estable, no la que usa su propia
interfaz web.

### La suite falló en stock por arrancar el monolito sin `--inventory remote`

```text
 31 | jsonpath "$.stock" == 18
    |   actual:   integer <20>
```

No era el trazado: el monolito leía el stock de sus tablas locales mientras `orders` retenía en
`inventory`. **Corrección:** el arranque de `06/04`, que sigue vigente. **Lección:** la forma de arrancar
es parte del estado del sistema; por eso §2 la repite entera.

## 10. 🧰 En tres plataformas

| Plataforma | Qué te da hecho | Lo que te deja a ti |
|---|---|---|
| **Java** | El agente (`-javaagent`): servidor y clientes HTTP, gRPC, JDBC, Hibernate, Kafka, `@Scheduled`; `trace_id` en el MDC; configuración por variables `OTEL_*` | Propagar el contexto donde el trabajo cambia de hilo **y** de momento (el outbox); decidir qué ruido se descarta; el patrón de log |
| **Go** | `otelhttp` y `otelgrpc` como envoltorios; el SDK con exportador OTLP y propagador W3C | Todo el arranque del SDK; el adaptador de encabezados de Kafka (o `kotel`); los spans de base de datos (`otelpgx` o un `QueryTracer`); el `trace_id` en cada línea de log; pasar `ctx` a todo |
| **Python** | Un instrumentor por biblioteca (FastAPI, httpx, psycopg, aiokafka…), una línea cada uno; o `opentelemetry-instrument` sin tocar código | Activarlos **antes** de crear clientes y pools; el filtro de logging; el consumidor si no usa el instrumentor; con varios workers, un SDK por proceso |

La fila de Node/TS —instrumentación automática y `AsyncLocalStorage`, que pierde el contexto al publicar
en un broker— está en
[`04/04` §6](../04-operacion-y-resiliencia/04-observabilidad-y-trazas.md#6--en-las-cuatro-plataformas).

## 11. 🧹 Teardown

```text
Ctrl+C en las terminales de psp, inventory, payments, monolith y orders
python3 laboratorio/scripts/lab.py down
```

- `down` borra también `ms-otel-collector` y `ms-jaeger`; las trazas vivían en memoria y desaparecen con
  él. El agente descargado se queda en `laboratorio/tools/otel/` para la próxima vez. El [taller 08](08-saga-coreografiada.md)
  empieza con `up` y `seed --kafka`.

## ⚠️ Errores frecuentes

| Se dice | Lo preciso |
|---|---|
| "Con el agente de Java ya tengo trazas de extremo a extremo" | Las tienes donde el contexto viaja en el mismo hilo; en un outbox, un pool o un planificador, el agente propaga el contexto que encuentra, que puede ser el equivocado |
| "La traza se corta en Kafka porque el mensaje no lleva `traceparent`" | A veces lo lleva y es de otra traza; una traza cortada se ve, una traza mezclada engaña |
| "Basta con propagar en el productor" | El consumidor tiene que extraerlo y abrir su span como hijo; es un contrato de dos lados |
| "El collector es opcional, mando directo al backend" | Funciona, y ata tres servicios al backend; el collector es donde se muestrea, se filtra y se cambia de destino sin redesplegar |
| "Para quitar ruido, apago instrumentaciones" | Lo que colgaba del span apagado se vuelve raíz y hay más trazas; el ruido se decide con muestreo |
| "Con logs y un buen grep no necesito trazas" | El grep encuentra líneas; la traza dice qué esperó a qué y cuánto |

## 📚 Para profundizar

- **Libro** — Ted Young y Austin Parker, *Learning OpenTelemetry*, O'Reilly, 2024, cap. 5,
  "Instrumenting Applications", y cap. 8, "Designing Your Telemetry Pipeline".
- **Libro** — Charity Majors, Liz Fong-Jones y George Miranda, *Observability Engineering*, O'Reilly, 2022,
  cap. 7, "Instrumentation with OpenTelemetry", y cap. 17, "Cheap and Accurate Enough: Sampling".
- **Documentación** — [Agente de Java de OpenTelemetry](https://opentelemetry.io/docs/zero-code/java/agent/) ·
  [desactivar instrumentaciones](https://opentelemetry.io/docs/zero-code/java/agent/disable/) ·
  [Go: primeros pasos](https://opentelemetry.io/docs/languages/go/getting-started/) ·
  [`otelgrpc`](https://pkg.go.dev/go.opentelemetry.io/contrib/instrumentation/google.golang.org/grpc/otelgrpc) ·
  [Python: instrumentación](https://opentelemetry.io/docs/languages/python/instrumentation/).
- **Documentación** — [Propagadores](https://opentelemetry.io/docs/specs/otel/context/api-propagators/) ·
  [convenciones semánticas de Kafka](https://opentelemetry.io/docs/specs/semconv/messaging/kafka/) ·
  [muestreo](https://opentelemetry.io/docs/concepts/sampling/) ·
  [el collector](https://opentelemetry.io/docs/collector/) ·
  [`tail_sampling`](https://github.com/open-telemetry/opentelemetry-collector-contrib/tree/main/processor/tailsamplingprocessor).
- **Documentación** — [Envoy 1.39: trazado con OpenTelemetry](https://www.envoyproxy.io/docs/envoy/v1.39.1/api-v3/config/trace/v3/opentelemetry.proto) ·
  [Jaeger 2.21: APIs](https://www.jaegertracing.io/docs/2.21/architecture/apis/).
- **Especificación** — [W3C Trace Context](https://www.w3.org/TR/trace-context/) (`traceparent`, `tracestate`).

## 🧠 Preguntas

1. ¿Qué es un span y qué es una traza? Pon un ejemplo de este taller. 🟢
2. ¿Qué es `traceparent` y qué lleva cada uno de sus cuatro campos? 🟢
3. ¿Qué instrumentó el agente de Java sin tocar código, y qué hubo que escribir igualmente? 🟢
4. ¿Para qué sirve el collector si los servicios podrían mandar directo a Jaeger? 🟡
5. ¿Por qué la traza se cortaba en Kafka si el mensaje sí llevaba `traceparent`? 🟡
6. ¿Por qué no basta con corregir solo el productor, ni solo los consumidores? 🟡
7. ¿Qué te dice la traza de un pago con `payments` caído que no te diga su log? 🟡
8. ¿Por qué apagar la instrumentación de `@Scheduled` empeoró el ruido en vez de quitarlo? 🟡
9. Muestreo por cabeza y por cola: ¿cuál usa el laboratorio, por qué, y qué cuesta? 🟠
10. ¿Por qué la primera política de muestreo perdía justo las trazas de los clientes que mandaban su propio `traceparent`? 🟠
11. En la primera petición, `Hold` tardó 382 ms en el cliente y 12 ms en el servidor. ¿Dónde se fue la diferencia, y cómo lo confirmarías? 🟠
12. ¿Por qué no hay span de servidor del PSP en la traza del pago, y qué harías si el problema estuviera ahí? 🟠
13. Un cliente dice "mi pago de ayer a las 10:14 tardó 8 s". Describe paso a paso cómo lo investigas con lo que montó este taller, y qué te falta. 🔴
14. Diseña la observabilidad del outbox en producción —trazas, métricas y alertas— sabiendo que el sondeo hace cinco rondas por segundo en cada instancia. 🔴
15. En producción, desde el último despliegue de `orders`, las trazas de los pagos terminan en el `Commit` de `inventory` y los consumidores de `OrderPaid` aparecen en trazas sueltas. Da tres hipótesis en orden de probabilidad y qué mirarías para cada una. 🔴

## 🧪 Ejercicios

1. 🟢 Lanza `lab.py buy --then cancel`, abre la traza de la cancelación en la interfaz de Jaeger
   (`http://localhost:26686`) y en `lab.py trace`, y encuentra su `trace_id` en los logs de `payments` y de
   Envoy. Pega las cuatro salidas.
2. 🟢 **Orientación en código ajeno.** Encuentra, con ruta y línea, dónde se fija el nombre del servicio
   (`service.name`) en cada una de las tres plataformas, y dónde se elige el propagador W3C.
3. 🟡 Añade spans de base de datos a `inventory` (con `otelpgx` o con un `pgx.QueryTracer` propio) y compara
   la traza de `Hold` antes y después.
4. 🟡 Cambia los logs de `payments` a JSON con `trace_id` y `span_id` completos. ¿Por qué el taller los
   recorta a 8 caracteres y por qué en producción no se hace?
5. 🟡 Añade una tercera política de muestreo que guarde toda traza con error o de más de 1 s, y demuéstrala
   con `payments` parado y con un pago de `666.00`.
6. 🟠 Sustituye el adaptador `Headers` de Go por el plugin `kotel` de `franz-go`. ¿Qué dejas de escribir y
   qué ganas (el envío a la DLQ, por ejemplo)?
7. 🔴 Activa las métricas del agente en `orders` (quita `OTEL_METRICS_EXPORTER=none`), llévalas al collector
   y a un backend de métricas, y define el SLI "pago confirmado en menos de 1 s" con su SLO.
8. 🔥 Mete 300 ms de latencia en el proxy gRPC de `inventory` (`lab.py slow inventory-grpc --latency 300`) y
   usa solo trazas para demostrar dónde está el tiempo, comparando el span de cliente con el de servidor.

---

**Anterior:** [`06` — Kafka: outbox, inbox, idempotencia y DLQ](06-kafka-outbox-inbox-y-dlq.md). **Siguiente:**
[`08` — Saga coreografiada](08-saga-coreografiada.md). **Relacionado:**
[`04/04` — Observabilidad y trazas](../04-operacion-y-resiliencia/04-observabilidad-y-trazas.md).
