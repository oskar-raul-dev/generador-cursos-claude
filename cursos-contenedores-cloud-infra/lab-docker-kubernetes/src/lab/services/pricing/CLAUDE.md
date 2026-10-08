# pricing

El precio vigente de un producto en una droguería, en pesos colombianos. Es el **piloto** del
laboratorio: cada patrón nuevo se construye primero aquí. Sale del `PriceService` de Contingencia
(`../../legacy/contingencia/`).

## Stack

- Go (la versión de `a01`). Un módulo `lab/pricing`: `main.go` (HTTP) y `store.go` (el almacén y las
  migraciones). Dependencias: `modernc.org/sqlite` (G1), `pgx` (G3) y, solo en las pruebas, `testcontainers-go`.
- Imagen: `lab/pricing`. Escucha en `PORT` (8080 por defecto). Multi-stage desde la Fase 04:
  binario estático (`CGO_ENABLED=0`) sobre distroless, sin shell, como el usuario 65532. Cualquier
  dependencia que necesite cgo rompe esa base: en G1, SQLite tiene que ser un driver en Go puro.

## Comandos

```bash
task build -- pricing                 # construye la imagen con el motor activo
task compose:up                       # el sistema en compose
task conformance -- G1                # la suite (G3 no cambia la interfaz), contra compose
task conformance TARGET=cluster -- G1 # y contra el cluster
task test:pricing                     # las pruebas del almacén contra SQLite
task test:pricing DB=postgres         # y contra Postgres, con Testcontainers (necesita el socket del motor)
```

## Convenciones

- Identificadores en inglés, comentarios en español con tildes.
- Desde G7, una línea JSON por evento a stdout (`time`, `level`, `service`, `msg`); la de cada petición,
  con `method`, `uri`, `path`, `status`, `duration_ms` y `request_id` (de `X-Request-Id`).
- Lo que no está en el paso actual responde 404 con `{"error":"not_found"}`.
- El contrato manda: `../../contracts/openapi/pricing.yaml`. Se cambia el contrato y la suite antes
  que el código.

## El contrato, paso a paso

| Paso | Qué | Estado |
|---|---|---|
| G0 | `/health/live`, `/health/ready` triviales; `GET /prices/{sku}` con precio fijo | ✅ hecho |
| G1 | almacén propio (SQLite con `modernc.org/sqlite`, en `DATA_DIR`), `GET /prices`, `PUT /prices/{sku}`, tope regulado (`REGULATED_CAP_ENABLED` y `REGULATED_CAP_FILE`) | ✅ hecho |
| G3 | Postgres por `DATABASE_URL` (`pgx`; sin ella, el SQLite de G1), `pricing migrate` para el `Job`, y las pruebas del almacén contra los dos motores (`task test:pricing [DB=postgres]`, B-12). Conocido: `price` es `INTEGER` y un precio de más de 2.147.483.647 da 500 en Postgres | ✅ hecho |
| G4 | readiness real: `/health/ready` responde 503 `{"status":"not_ready"}` si la base no contesta en un segundo (`PingContext`); la liveness sigue sin consultar nada | ✅ hecho |
| G5 | apagado limpio ante `SIGTERM`: `signal.NotifyContext` y `srv.Shutdown` con 20 s; sale con 0 | ✅ hecho |
| G6 | `/metrics` con `prometheus/client_golang` (versión en `go.mod`): el histograma `http_server_requests_seconds` (method, uri, status) en un middleware que lee `r.Pattern` después del mux; lo que no tiene ruta, `uri="/**"`. `METRICS_URI=raw` etiqueta con la ruta cruda: es el antipatrón de la Fase 17 y existe solo para medirlo | ✅ hecho |
| G7 | logs JSON con `log/slog` y `slog.SetDefault` (los `log.Printf` también salen en JSON); el `request_id` de `X-Request-Id` o uno nuevo | ✅ hecho |
| G8 | un segundo listener con TLS mutuo en el 8443 (`tls.go`): exige certificado de cliente de la CA del laboratorio; el certificado del servidor se relee cuando cert-manager lo renueva. Variables `TLS_CERT_FILE`, `TLS_KEY_FILE`, `TLS_CLIENT_CA_FILE`; sin ellas, no hay 8443 | ✅ hecho |
| G10 | gRPC en el 9090 (`grpc.go`, código generado en `pricingv1/` con `task proto`) con el mismo mTLS; `grpc_server_requests_total`; `GRPC_MAX_CONNECTION_AGE` opcional (edad máxima por conexión); trazas con OpenTelemetry (`otel.go`, `otelhttp`, `otelgrpc`) y `trace_id` en la línea `request` | ✅ hecho |

**No agregues nada de un paso pendiente**, aunque sea fácil: una capacidad antes de su fase invalida
el paso.
