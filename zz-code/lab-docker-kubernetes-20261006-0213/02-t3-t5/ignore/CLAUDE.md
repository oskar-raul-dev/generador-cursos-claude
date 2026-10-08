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
task conformance -- G0                # la suite del paso; tiene que pasar
```

## Convenciones

- Identificadores en inglés, comentarios en español con tildes.
- Una línea de texto por petición a stdout (método, ruta, estado). JSON recién en G7.
- El log por petición es un middleware de una línea en `src/main.ts`.
- El contrato manda: `../../contracts/openapi/replenish.yaml`. Se cambia el contrato y la suite antes
  que el código.

## El contrato, paso a paso

| Paso | Qué | Estado |
|---|---|---|
| G0 | `/health/live`, `/health/ready` triviales; `GET /replenishment-orders` con lista fija | ✅ hecho |
| G1 | almacén propio (SQLite), `POST /replenishment-orders` (con `replacesOrderId`), `GET /replenishment-orders/{id}`, `POST /replenishment-orders/{id}/cancel` (solo en `PENDING`, con `reasonCode`), `GET /reason-codes` (tabla sembrada) | pendiente (Fase 09) |
| G3 | Postgres por `DATABASE_URL`, migraciones como `Job` | pendiente (Fase 12) |
| G4 | readiness real | pendiente (Fase 15) |
| G5 | recibe el aviso de la venta sin que nadie espere su respuesta; apagado limpio | pendiente (Fase 16) |
| G6 · G7 | `/metrics` · logs JSON | pendiente (Fases 17 y 18) |
| G10 | trazas con OpenTelemetry | pendiente (Fase 23) |
| G11 · G12 · G13 | la cancelación como compensación (código `SAGA_COMPENSATION`) · consumidor de eventos · idempotencia y outbox | pendiente (Fases 24–26) |

**No agregues nada de un paso pendiente**, aunque sea fácil o el framework lo traiga de serie: una
capacidad antes de su fase invalida el paso.
nota 1
nota 2
nota 3
nota sin ignore 1
nota sin ignore 2
nota sin ignore 3
