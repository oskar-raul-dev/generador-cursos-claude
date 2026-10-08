# 03 — Datos y consistencia

> Lo que pasa cuando cada servicio es dueño de sus datos: consultas que ya no caben en un `JOIN`,
> sagas en vez de transacciones, outbox e idempotencia, y migraciones sin parar el negocio. Implementa
> lo que el corpus de arquitectura razona.
>
> **Vigencia:** 2026-09-29.

---

## Orden de lectura

| Documento | Qué fija |
|---|---|
| [`01` — Base de datos por servicio](01-base-de-datos-por-servicio.md) | La regla, sus excepciones y los escalones de separación |
| [`02` — Consultas entre servicios](02-consultas-entre-servicios.md) | Composición, proyección y réplica de referencia |
| [`03` — Saga](03-saga.md) | Coreografía, orquestación, compensaciones y anomalías |
| [`04` — Outbox, inbox e idempotencia](04-outbox-inbox-e-idempotencia.md) | La doble escritura y sus tres soluciones |
| [`05` — Evolución de esquema](05-evolucion-de-esquema-y-migraciones.md) | Expand/contract, backfill y vuelta atrás |
| [`06` — Simulación de entrevista](06-simulacion-de-entrevista.md) | 33 preguntas transversales y 5 escenarios |
| [`07` — Respuestas](07-respuestas.md) | El solucionario del bloque, en tres capas |

**128 preguntas de capítulo** más las transversales, todas con respuesta en `07`.

**Talleres, opcionales,** que ejercitan este bloque en local: `01` → [`06/02`](../06-talleres/02-strangler-fig-con-envoy.md) · `02` → [`06/11`](../06-talleres/11-consultas-y-tiempo-real.md) · `03` → [`06/08`](../06-talleres/08-saga-coreografiada.md), [`06/09`](../06-talleres/09-saga-orquestada.md) · `04` → [`06/06`](../06-talleres/06-kafka-outbox-inbox-y-dlq.md) · `05` → [`06/06`](../06-talleres/06-kafka-outbox-inbox-y-dlq.md).

---

## El mapa mental

```text
cada servicio, dueño de sus datos (01)
        │
        ├─ ¿y las consultas?      → componer · proyectar · replicar referencia (02)
        │
        ├─ ¿y las transacciones?  → saga: compensable · pivote · reintentable (03)
        │
        ├─ ¿y publicar el evento? → outbox + consumidor idempotente (04)
        │
        └─ ¿y cambiar el esquema? → expand/contract, compatible con el código vivo (05)
```

---

## Qué NO está aquí

- **CAP, PACELC, niveles de aislamiento, sharding y CQRS como teoría**: del bloque
  [`03-datos`](../../01-bases/03-datos/) del corpus de arquitectura.
- **Event sourcing**: de
  [`02-eventos/07`](../../01-bases/02-eventos/07-event-sourcing.md). Aquí se
  menciona y se enlaza.
- **Cómo viajan los mensajes** —brokers, colas, DLQ—: bloque
  [`02-comunicacion`](../02-comunicacion/).
- **Cómo se despliegan las migraciones en el pipeline**: `04-operacion-y-resiliencia/06`.

---

**Anterior:** [`02-comunicacion`](../02-comunicacion/) · **Siguiente:**
[`04-operacion-y-resiliencia`](../04-operacion-y-resiliencia/) · **Índice:**
[`README.md`](../README.md)
