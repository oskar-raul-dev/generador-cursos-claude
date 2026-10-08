# P19 — Pruebas del flujo básico

**Guía de proyecto · ~2.5 h**

## Qué construyes

Tests de integración del flujo completo. Testcontainers para PostgreSQL. Prueba real del pipeline sin mocks.

## Contenidos

- IntegrationTest: flujo completo ingestión + query
- Testcontainers para PostgreSQL
- @SpringBootTest con contexto real
- Verificaciones: documento cargado, consultable, respuesta correcta
- Coverage de las preguntas de P05

## Criterio de finalización

`mvn test` corre sin mocks. Suite cubre ingestión, retrieval y generación. Todas las preguntas de P05 tienen un test.

## Después de esta guía

Pasás a P20. El sistema está completamente desarrollado. Falta empaquetarlo.
