# P12 — Pipeline de ingestión completo

**Guía de proyecto · ~2.5 h**

## Qué construyes

Integración de todas las piezas anteriores en un flujo end-to-end: lectura → normalización → chunking → embedding → almacenamiento.

## Contenidos

- IngestionService: orquestación
- Flujo: Document → Chunks → Embeddings → DB
- Error handling: parte falla, se registra, sigue la siguiente
- Endpoint de ingesta: carga un archivo, retorna estado
- Verificación: documento se vuelve consultable

## Criterio de finalización

Subes un documento nuevo. Tras ejecutarse el pipeline completo, el documento es consultable. No hay intervención manual.

## Después de esta guía

Terminás la fase de ingestión. Pasás a P13 con los documentos ya en la base de datos. Ahora implementás consulta.
