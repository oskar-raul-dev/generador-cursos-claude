# Prompt G0 · pricing (prototipo de P11)

Genera el servicio `pricing` en Go, en `services/pricing/`, cumpliendo SOLO el paso G0 del contrato.

Stack: Go (la versión de a01), solo biblioteca estándar, sin dependencias externas. Un módulo
`lab/pricing`, un `main.go` y un `go.mod`.

Interfaz de plataforma:
- Escucha en el puerto de la variable `PORT`, 8080 por defecto.
- `GET /health/live` → 200 `{"status":"live"}`. Nunca consulta dependencias.
- `GET /health/ready` → 200 `{"status":"ready"}`. Trivial en G0.
- Logs a stdout, texto libre, una línea por petición: método, ruta, estado.

Dominio G0, un solo endpoint con JSON fijo:
- `GET /prices/{sku}?store={storeId}` → 200
  `{"sku":"<sku>","store":"<storeId o DRO-001>","price":12900,"currency":"COP","source":"g0-fixed"}`.
- Cualquier otra ruta → 404 `{"error":"not_found"}`.

Lo que el servicio NO debe tener todavía: base de datos, llamadas a otros servicios, `/metrics`,
logs JSON, manejo de SIGTERM, gRPC, configuración por archivo. Si lo agregas, el paso está mal.

Dockerfile: multi-stage, `FROM golang:<versión> AS build` y la etapa final en
`gcr.io/distroless/static-debian13:nonroot`, ambas por digest con el tag en un comentario;
binario estático (`CGO_ENABLED=0`); comentarios en español.

Validación: `hurl --test contracts/conformance/pricing.g0.hurl --variable base_url=http://pricing:8080`.
