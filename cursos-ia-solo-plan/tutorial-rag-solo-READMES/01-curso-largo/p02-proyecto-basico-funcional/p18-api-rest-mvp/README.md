# P18 — API REST del MVP

**Guía de proyecto · ~3 h**

## Qué construyes

REST API completa que expone todas las funcionalidades. Contrato OpenAPI. Un cliente externo puede usar el sistema.

## Contenidos

- Endpoints: /api/documents/upload, /api/query, /api/sources, /api/health
- OpenAPI 3.0 spec generada automáticamente
- DTOs: request y response
- Error handling: códigos HTTP apropiados
- Swagger UI para exploración

## Criterio de finalización

`GET /api/query?question=...` retorna una respuesta válida. OpenAPI describe todos los endpoints. Un cliente HTTP externo puede operar el sistema.

## Después de esta guía

Pasás a P19. Ahora hay que probar que todo funciona junto.
