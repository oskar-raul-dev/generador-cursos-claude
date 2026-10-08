# replenish

Las órdenes de reposición, incluido el préstamo entre droguerías (una reposición cuyo origen es otra
droguería). Sale de la Braqui (`../../legacy/braqui/`), pero no lee tablas de nadie.

## Stack

- Node (la versión de `a01`) con NestJS 12, en módulos ESM. Sin pruebas propias: la prueba es la suite.
- Imagen: `lab/replenish`. Escucha en `PORT` (8080 por defecto). Multi-stage desde la Fase 04:
  compila TypeScript en una etapa, instala solo las dependencias de producción en otra, y corre como
  el usuario `node`.

## Comandos

```bash
task build -- replenish               # construye la imagen con el motor activo
task compose:up                       # el sistema en compose
task conformance -- G1                # la suite del paso; tiene que pasar
```

## Convenciones

- Identificadores en inglés, comentarios en español con tildes.
- Desde G7, una línea JSON por evento a stdout (`time`, `level`, `service`, `msg`); la de cada petición,
  con `method`, `uri`, `path`, `status`, `duration_ms` y `request_id` (de `X-Request-Id`).
- El log por petición es un middleware de una línea en `src/main.ts`.
- El contrato manda: `../../contracts/openapi/replenish.yaml`. Se cambia el contrato y la suite antes
  que el código.

## El contrato, paso a paso

| Paso | Qué | Estado |
|---|---|---|
| G0 | `/health/live`, `/health/ready` triviales; `GET /replenishment-orders` con lista fija | ✅ hecho |
| G1 | almacén propio (SQLite), en `DATA_DIR`, `POST /replenishment-orders` (con `replacesOrderId`), `GET /replenishment-orders/{id}`, `POST /replenishment-orders/{id}/cancel` (solo en `PENDING`, con `reasonCode`), `GET /reason-codes` (tabla sembrada) | ✅ hecho |
| G3 | Postgres por `DATABASE_URL` (paquete `pg`; sin ella, el `node:sqlite` de G1), detrás de `Store.all` y `Store.one`; `node dist/migrate.js` para el `Job` | ✅ hecho |
| G4 | readiness real: `/health/ready` hace `select 1` con un segundo de límite y responde 503 `{"status":"not_ready"}` si la base no contesta; el pool de `pg` espera 2 s por una conexión, y atiende su evento `error` (sin él, una conexión cortada por la base mata el proceso) | ✅ hecho |
| G5 | recibe el aviso de la venta (el mismo `POST /replenishment-orders` de G1, que ahora llama `inventory` sin esperar); apagado limpio con `enableShutdownHooks` | ✅ hecho |
| G6 | `/metrics` con `@prometheus-io/client` (la heredera oficial de `prom-client`, deprecado en 2026), en `src/metrics.ts`: el middleware `measure` toma `req.route.path` al terminar y lo escribe como el contrato (`/replenishment-orders/{id}`); lo que no tiene ruta, `uri="/**"`; más las métricas por defecto del proceso y del event loop | ✅ hecho |
| G7 | `JsonLogger` propio (`src/logger.ts`) pasado a `NestFactory.create`, también para el arranque; `logRequests` escribe la línea de cada petición | ✅ hecho |
| G10 | `@opentelemetry/auto-instrumentations-node` con `--import`, limitado con `OTEL_NODE_ENABLED_INSTRUMENTATIONS` | ✅ hecho |
| G11 | la cancelación como compensación de la saga del préstamo: el código `SAGA_COMPENSATION` sembrado en `reason_codes`; la operación es la de G1, sin cambios | ✅ hecho |
| G12 | `src/events.ts`: con `EVENT_BUS=valkey`, `SUBSCRIBE` a `lab.inventory.stock-low` (`iovalkey`); con `nats`, el consumidor durable `replenish-stock-low` del stream `LAB_EVENTS` (`@nats-io/jetstream`), ack explícito después de crear la orden, `ack_wait` de 30 s; la orden guarda `source_event_id` (columna nueva, `sourceEventId` en el contrato); sin idempotencia | ✅ hecho |
| G13 | consumidor idempotente: `processed_events` (por `eventId`) y la orden en la misma transacción (`Store.transaction`), el `ack` después del commit; `Idempotency-Key` en `POST /replenishment-orders` (columna `idempotency_key`, índice único parcial; 422 con otro cuerpo) y `GET /replenishment-orders?idempotencyKey=`; la cancelación idempotente (una orden ya `CANCELLED` se devuelve con 200) | ✅ hecho |

**No agregues nada de un paso pendiente**, aunque sea fácil o el framework lo traiga de serie: una
capacidad antes de su fase invalida el paso.
