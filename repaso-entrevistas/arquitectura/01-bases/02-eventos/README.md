# 02 — Eventos

> Segundo bloque de [`arquitectura/01-bases`](../README.md). Todo lo que pasa cuando los
> servicios dejan de llamarse y empiezan a publicar: brokers, garantías de entrega,
> idempotencia, fallos, saga, outbox, event sourcing y proyecciones.
>
> **Vigencia:** 2026-09-18. · **Guía editorial:** [`prompts/guia-de-estilo-y-convenciones.md`](../prompts/guia-de-estilo-y-convenciones.md)

---

## Qué es esto

El bloque que responde a la pregunta que abre casi toda entrevista de microservicios:
*"¿y cómo mantienes la consistencia entre servicios?"*.

Asume leído [`01-bases`](../01-bases/), y en particular
[`08` — Comunicación e integración](../01-bases/08-comunicacion-e-integracion.md), que
introduce el acoplamiento temporal y la idempotencia. Aquí se profundiza; no se repite.

---

## Orden de lectura

| # | Documento | Qué cubre |
|---|---|---|
| `01` | [Fundamentos de EDA](01-fundamentos-eda.md) | Evento contra comando, dominio contra integración, las tres formas de colaborar |
| `02` | [Brokers comparados](02-brokers-comparados.md) | Kafka, RabbitMQ, SQS/SNS, IBM MQ: cola contra log |
| `03` | [Garantías, orden e idempotencia](03-garantias-orden-e-idempotencia.md) | **El más preguntado.** at-least-once, exactly-once, las cuatro formas de idempotencia |
| `04` | [Colas, DLQ y reintentos](04-colas-dlq-y-reintentos.md) | Fallo transitorio contra permanente, mensaje envenenado, DLQ con proceso |
| `05` | [Saga](05-saga.md) | Coreografía contra orquestación, compensación, pivote, aislamiento |
| `06` | [Outbox y CDC](06-outbox-y-cdc.md) | La doble escritura y el patrón que más entrevistas resuelve |
| `07` | [Event sourcing](07-event-sourcing.md) | Qué compra, qué cuesta, y por qué el veredicto es "casi nunca" |
| `08` | [Proyecciones y streaming](08-proyecciones-y-streaming.md) | Vistas de lectura, reconstrucción, tiempo de evento, Lambda y Kappa |
| `09` | [Simulación de entrevista](09-simulacion-de-entrevista.md) | 36 preguntas `S#` + 5 escenarios de diseño |
| `10` | [Respuestas](10-respuestas.md) | Solucionario completo, en tres capas |

**Si el calendario aprieta**, el orden de prioridad es: `03`, `06`, `05`, `01`. Esos cuatro
cubren lo que de verdad se pregunta.

---

## Mapa mental del bloque

```text
            ¿Qué publico?                  → 01  (evento vs comando, dominio vs integración)
                   │
            ¿Por dónde viaja?              → 02  (cola vs log)
                   │
            ¿Qué me garantiza?             → 03  (at-least-once + idempotencia)
                   │
        ┌──────────┼──────────┐
        ▼          ▼          ▼
   ¿Y si falla? ¿Y la      ¿Y si el estado
      04       consistencia?   ES el log?
             05 saga · 06 outbox   07 event sourcing
                   │                     │
                   └──────────┬──────────┘
                              ▼
                      ¿Y cómo consulto?   → 08 (proyecciones)
```

---

## Qué NO está aquí

- **CQRS en profundidad, CAP, transacciones y caché** → [`03-datos`](../03-datos/). Aquí se
  usa CQRS como consecuencia de `07`; allí se estudia como patrón de datos.
- **Timeout, circuit breaker y bulkhead** → [`01-bases/09`](../01-bases/09-resiliencia.md).
  Este bloque los da por sabidos.
- **IBM MQ, batch y conciliación bancaria** → [`05-banca`](../05-banca/).
- **Saga, outbox e inbox implementados en Java · Node/TS · Go · Python** →
  [`arquitectura/04-microservicios/03-datos-y-consistencia`](../../04-microservicios/03-datos-y-consistencia/README.md),
  y corridos en local en sus [talleres](../../04-microservicios/06-talleres/README.md).
- **Laboratorio.** Este corpus es teoría y evaluación; no hay labs.
