# T04 — Arquitectura de dos pipelines

**Guía teórica · ~2 h**

## Qué aprenderás

Por qué los pipelines de ingestión y consulta son completamente separados. Cómo esa separación determina todas las decisiones de diseño que siguen.

## Contenidos

- Pipeline de ingestión: lectura, fragmentación, embedding, almacenamiento
- Pipeline de consulta: conversión de pregunta, recuperación, generación
- Ciclos de vida distintos: ingestión corre una sola vez
- Error arquitectónico: reindexar en cada consulta

## Criterio de finalización

Explicás por qué reindexar en cada consulta es un error de arquitectura, no solo de rendimiento. Tu argumento va más allá de "cuesta tiempo".

## Después de esta guía

Pasás a T05 con la separación de pipelines clara. Todo lo que sigue asume que entendés esa distinción fundamental.
