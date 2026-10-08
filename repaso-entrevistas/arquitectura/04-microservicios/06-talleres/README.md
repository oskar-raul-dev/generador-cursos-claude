# 06 — Talleres

> El sistema de ejemplo del corpus llevado **de un monolito a servicios**, en tu máquina, provocando a
> propósito los fallos que los capítulos describen. Java, Go y Python conviviendo; Envoy, Kafka,
> OpenTelemetry y PostgreSQL de verdad; y en cada taller, un recorrido por código que no escribiste.
> **Todo el bloque es opcional**: los cinco bloques teóricos se sostienen sin él.
>
> **Vigencia:** 2026-09-29. Cada taller fue escrito **y corrido** ese día; sus salidas son literales.

---

## Qué es esto, y qué no

```text
Los bloques 01–05   → qué patrón es, qué cuesta y qué te da cada plataforma.
Este bloque         → cómo se siente cuando la frontera es la red: el timeout que libera la conexión,
                      la saga que nadie sabe en qué estado está, la traza que se corta en Kafka.
```

No enseña frameworks —cada taller dice qué le dio hecho cada plataforma y qué tuvo que escribir—, y no
es un proyecto de referencia: es un laboratorio que se rompe a propósito. Cada taller tiene la misma
forma: qué enseña y su precio, prerrequisitos, **recorrido de la base de código**, las partes y las
provocaciones con su salida, **errores reales al correrlo**, la tabla de las tres plataformas, teardown,
14 o 15 preguntas y 8 ejercicios, con un reparto de dificultad propio de cada taller.

---

## Orden de lectura

| Taller | Qué pasa en el sistema | La provocación |
|---|---|---|
| [`01` — El monolito y su contrato](01-el-monolito-y-su-contrato.md) | El punto de partida: contrato, suite `v1`, `lab.py` | El PSP lento agota el pool y tumba el catálogo |
| [`02` — Strangler fig con Envoy](02-strangler-fig-con-envoy.md) | Envoy delante; `inventory` sale a Go | La base compartida y la migración que rompe al monolito |
| [`03` — HTTP entre servicios](03-http-entre-servicios.md) | `payments` sale a Python; timeout, reintento, idempotencia | El reintento que cobra dos veces |
| [`04` — gRPC](04-grpc.md) | `inventory` por gRPC; `orders` sale del monolito | El deadline que el servidor ignora |
| [`05` — Resiliencia en tres plataformas](05-resiliencia-en-tres-plataformas.md) | Breaker, bulkhead y límite de tasa en Java, Go y Python | La multiplicación de reintentos y la readiness que depende de otros |
| [`06` — Kafka: outbox, inbox, idempotencia y DLQ](06-kafka-outbox-inbox-y-dlq.md) | Los hechos del pedido en Kafka | La entrega que cuenta dos veces, el evento perdido, el mensaje venenoso |
| [`07` — Observabilidad de extremo a extremo](07-observabilidad-de-extremo-a-extremo.md) | OpenTelemetry en los tres runtimes, collector y Jaeger | La traza que se corta en Kafka con un `traceparent` equivocado |
| [`08` — Saga coreografiada](08-saga-coreografiada.md) | Contrato `v2` con `202`; la saga sin dueño | "¿En qué estado está este pedido?" y el ciclo de eventos |
| [`09` — Saga orquestada](09-saga-orquestada.md) | La misma saga con dueño; tres cambios de negocio | La compensación que no llega (la autopsia de `03/03` §9) |
| [`10` — Contratos entre servicios y testing](10-contratos-y-testing.md) | Pactos entre Java, Go y Python; Testcontainers | El cambio en `payments` que la suite no ve |
| [`11` — Consultas entre servicios y tiempo real](11-consultas-y-tiempo-real.md) | Composición contra read model; SSE | El read model que cuenta dos veces al reconstruirse |
| [`12` — Respuestas](12-respuestas.md) | El solucionario del bloque, en tres capas | — |

**244 enunciados con respuesta**: 156 preguntas y 88 ejercicios, copiados literalmente en `12`.

---

## Dependencias y rutas

```text
01 ─► 02 ─► 03 ─► 04 ─► 05 ─► 06 ─► 07 ─► 08 ─► 09
                  │            │            │
                  └──────┬─────┘            │
                         ▼                  ▼
                   10 (03+04+06)      11 (06+08)
```

- **La ruta completa** es la del diagrama: cada taller parte del sistema del anterior.
- **La ruta corta, para la semana de la entrevista**: `01 → 06 → 08 → 09`. Funciona porque el código de
  cada taller está congelado en `laboratorio/estados/NN/` (abajo): se lee el taller y se corre su estado
  con `lab.py --estado NN`. El precio es que correrás código cuya construcción no viste —el breaker de
  `05`, las trazas de `07`— y tendrás que orientarte en él, que es también un entrenamiento.
- `10` y `11` son opcionales **dentro** del bloque: cada uno declara sus prerrequisitos.

---

## El sistema, al final

```text
cliente ─► Envoy (JWT, rutas, reintento seguro, SSE, trazas) ─┬─► monolith (Java): catálogo, clientes, v1 heredado
                                                               └─► orders (Java): pedidos v1 y v2, orquestador,
                                                                     read model, SSE
        orders ─gRPC─► inventory (Go) ── PostgreSQL ms_inventory
        orders ─HTTP─► payments (Python) ─HTTP─► psp-simulator
        orders.events · orders.placed · inventory.reservations · payments.results   (Kafka, outbox e inbox en los tres)
        todos ─OTLP─► collector (tail sampling) ─► Jaeger
```

- Tres servicios en tres lenguajes, cada uno con su base: `ms_orders`, `ms_inventory`, `ms_payments` (y
  `ms_monolith`), en un solo PostgreSQL con un usuario dueño por base.
- Los nombres, puertos y versiones fijados por cada taller están en §14 de la
  [guía de estilo](../prompts/guia-de-estilo-y-convenciones.md#14--nombres-fijos-del-laboratorio).

---

## El laboratorio

```text
python3 laboratorio/scripts/lab.py check
python3 laboratorio/scripts/lab.py up
python3 laboratorio/scripts/lab.py seed --kafka
python3 laboratorio/scripts/lab.py suite --base-url http://localhost:28080 --dir v2
python3 laboratorio/scripts/lab.py down
```

- `check` comprueba, sin instalar nada, que tienes Docker, `hurl`, Maven y el JDK 25; Go 1.27 y `uv` (con
  Python 3.14) se necesitan desde `02` y `03`.
- `up` levanta la infraestructura en Docker (PostgreSQL, Toxiproxy, Envoy, Kafka, el collector y Jaeger);
  los servicios corren en tu máquina, cada uno en su terminal, para poder pararlos, matarlos y
  recompilarlos. Cada taller dice cómo arrancarlos.
- `seed --kafka` recrea bases, topics y grupos; **con los consumidores parados**.
- `suite` corre la colección `hurl` del contrato contra una URL base. `lab.py -h` lista todas las órdenes;
  cada una se explica en el taller que la introduce.
- `down` borra contenedores y volúmenes: nada sobrevive entre talleres.

**Estados congelados.** `laboratorio/` es el sistema del **último** taller. El de cada taller está copiado
en `laboratorio/estados/NN/`, y `lab.py --estado NN <orden>` trabaja sobre esa copia. Las rutas con
número de línea de cada recorrido se refieren a su estado.

```text
laboratorio/
├── contrato/      openapi.yaml · hurl/v1 · hurl/v2 · proto/ · pacts/ · envoy/ · otel/ · docker-compose.yml · seed/
├── scripts/       lab.py — Python 3, solo biblioteca estándar
├── monolith/      Java                     orders/     Java (desde 04)
├── inventory/     Go (desde 02)            payments/   Python (desde 03)
├── psp-simulator/ el proveedor de pago externo, Python sin dependencias
├── tools/         bench/ (04–05) · otel/ (el agente de Java, descargado) · cierre-09/ (los parches del cierre)
└── estados/01 … 11
```

**Qué cuesta tenerlo arriba.** Seis contenedores y cinco procesos (dos JVM entre ellos); el primer
arranque descarga imágenes y dependencias. Nada genera cargos: todo es local.

---

## Recorrer código ajeno

El segundo objetivo del bloque: tomar una base de código que no escribiste y orientarte rápido, como en
un trabajo nuevo o en una prueba técnica en vivo. Cada taller trae:

- una sección **🔎 Recorrido de la base de código** con las preguntas que te harías el primer día
  ("¿dónde nace el hecho?", "¿quién decide que un paso ha vencido?") y su respuesta con ruta y línea;
- un ejercicio 🟢 de **orientación en código ajeno**, que se responde con ruta y línea sin leer la
  solución;
- y la tabla de las tres plataformas, que dice qué parte del código es tuya y cuál te dio el marco.

---

## Qué NO está aquí

- **La teoría de cada patrón**: en los bloques [`01`](../01-fundamentos-y-descomposicion/) a
  [`05`](../05-plataformas/), que cada taller enlaza en su segundo párrafo.
- **Node/TS**: su contraste de runtime ya está en los capítulos, y una cuarta cadena de herramientas no
  enseña una idea nueva. Cada tabla de plataformas remite a la fila de Node del capítulo, y el caso
  completo en NestJS está en el
  [taller `04` del curso hexagonal](../../03-hexagonal/06-talleres/04-caso-typescript-nestjs.md).
- **Kubernetes y la nube**: el laboratorio es local a propósito. Despliegue, *service mesh* y nube están en
  [`04-operacion-y-resiliencia`](../04-operacion-y-resiliencia/) y en
  [`cloud/01-aws`](../../../cloud/01-aws/) · [`cloud/02-gcp`](../../../cloud/02-gcp/) ·
  [`cloud/03-azure`](../../../cloud/03-azure/).
- **Seguridad más allá del JWT en el borde**: mTLS, gestión de secretos y autorización fina se nombran
  donde tocan, sin laboratorio.

---

**Anterior:** [`05-plataformas`](../05-plataformas/) · **Siguiente:**
[`01` — El monolito y su contrato](01-el-monolito-y-su-contrato.md) · **Índice:** [`README.md`](../README.md)
