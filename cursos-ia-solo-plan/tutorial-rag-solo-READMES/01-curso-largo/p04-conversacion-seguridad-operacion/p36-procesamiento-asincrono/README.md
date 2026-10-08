# P36 — Procesamiento asíncrono y colas

**Guía de proyecto · ~3 h**

## Qué construyes

Subir cien documentos no bloquea consultas. Colas, workers, reintentos.

## Contenidos

- IngestionQueue: tarea asíncrona
- IngestionWorker: procesa por lotes
- Estados: pending, processing, completed, failed
- Retry logic: reintentos con backoff exponencial
- Endpoint: `/api/documents/status/{id}`

## Criterio de finalización

Subes muchos documentos. Sistema retorna inmediatamente. Consultas funcionan mientras ingesta corre. Status endpoint muestra progreso.

## Después de esta guía

Pasás a P37. Ahora seguridad: permisos en el retrieval.
