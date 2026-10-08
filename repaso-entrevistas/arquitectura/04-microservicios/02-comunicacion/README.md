# 02 — Comunicación

> Cómo se hablan los servicios: el mapa de estilos, HTTP y gRPC comparados a fondo, tiempo real,
> mensajería y contratos. Junto con [`05-plataformas`](../05-plataformas/), es el bloque que más se
> pregunta en entrevista.
>
> **Vigencia:** 2026-09-29.

---

## Orden de lectura

| Documento | Qué fija |
|---|---|
| [`01` — Estilos de comunicación](01-estilos-de-comunicacion.md) | Los dos ejes y el acoplamiento temporal |
| [`02` — HTTP entre servicios](02-http-entre-servicios.md) | El cliente como decisión de arquitectura |
| [`03` — gRPC](03-grpc.md) | Contrato compilado, deadlines y el problema del balanceo |
| [`04` — HTTP contra gRPC](04-http-contra-grpc.md) | **La comparativa**, dimensión por dimensión |
| [`05` — Tiempo real](05-tiempo-real-websockets-y-sse.md) | SSE, WebSocket, webhooks y el estado de la conexión |
| [`06` — Mensajería y eventos](06-mensajeria-y-eventos.md) | Comando contra evento, garantías reales, DLQ y lag |
| [`07` — Contratos y versionado](07-contratos-y-versionado.md) | Compatibilidad, expand/contract y pactos |
| [`08` — Simulación de entrevista](08-simulacion-de-entrevista.md) | 34 preguntas transversales y 5 escenarios |
| [`09` — Respuestas](09-respuestas.md) | El solucionario del bloque, en tres capas |

**176 preguntas de capítulo** más las transversales, todas con respuesta en `09`.

**Talleres, opcionales,** que ejercitan este bloque en local: `01` → [`06/03`](../06-talleres/03-http-entre-servicios.md) · `02` → [`06/03`](../06-talleres/03-http-entre-servicios.md) · `03` → [`06/04`](../06-talleres/04-grpc.md) · `04` → [`06/04`](../06-talleres/04-grpc.md) · `05` → [`06/11`](../06-talleres/11-consultas-y-tiempo-real.md) · `06` → [`06/06`](../06-talleres/06-kafka-outbox-inbox-y-dlq.md) · `07` → [`06/01`](../06-talleres/01-el-monolito-y-su-contrato.md), [`06/04`](../06-talleres/04-grpc.md), [`06/08`](../06-talleres/08-saga-coreografiada.md), [`06/10`](../06-talleres/10-contratos-y-testing.md).

---

## El mapa mental

```text
Primero el EJE, después el protocolo
  síncrono / asíncrono  ·  uno-a-uno / uno-a-muchos
                    │
  ┌─────────────────┼──────────────────┬───────────────────┐
  HTTP            gRPC            SSE / WebSocket      cola / topic
  (02)            (03, 04)        (05)                 (06)
                    │
             y todos necesitan CONTRATO versionado (07)
```

---

## Qué NO está aquí

- **La semántica de HTTP** —métodos, códigos, idempotencia según el RFC—: es de
  [`bases/04-apis-protocolos`](../../../bases/04-apis-protocolos/), opcional. Aquí se resume lo que
  hace falta entre servicios.
- **La teoría de EDA, event sourcing y la comparativa profunda de brokers**: del bloque
  [`02-eventos`](../../01-bases/02-eventos/) del corpus de arquitectura.
- **Saga, outbox e idempotencia implementados**: bloque
  [`03-datos-y-consistencia`](../03-datos-y-consistencia/).
- **Descubrimiento, gateway y resiliencia**: bloque
  [`04-operacion-y-resiliencia`](../04-operacion-y-resiliencia/).

---

**Anterior:** [`01-fundamentos-y-descomposicion`](../01-fundamentos-y-descomposicion/) ·
**Siguiente:** [`03-datos-y-consistencia`](../03-datos-y-consistencia/) · **Índice:**
[`README.md`](../README.md)
