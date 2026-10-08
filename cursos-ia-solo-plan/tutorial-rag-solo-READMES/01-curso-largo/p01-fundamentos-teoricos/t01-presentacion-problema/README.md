# T01 — Presentación del problema y arquitectura objetivo

**Guía teórica · ~2 h**

## Qué aprenderás

La arquitectura completa de un sistema RAG de punta a punta. No es un sistema: es dos pipelines distintos con ciclos de vida separados. El de ingestión corre una sola vez cuando cargas documentos. El de consulta corre en cada pregunta.

## Contenidos

- El problema que RAG resuelve: LLM locales que alucinan sin contexto
- Arquitectura de dos pipelines: ingestión vs consulta
- Componentes clave: documentos, fragmentos, embeddings, vector store, recuperación, generación
- Los siete puntos de fallo donde un sistema puede romperse
- Diferencia entre "meter todo en el prompt" y "seleccionar previamente"

## Criterio de finalización

Dibujás la arquitectura final de memoria, con las dos rutas separadas (ingestión y consulta) y marcás los siete puntos de fallo, sin mirar el documento.

## Después de esta guía

Avanzás a T02 con la estructura clara. Las próximas 11 guías profundizan en cada pieza de esta arquitectura.
