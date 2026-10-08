# P06 — Modelo documental interno

**Guía de proyecto · ~2 h**

## Qué construyes

Las entidades de dominio: Document, Chunk, Embedding. Con metadatos que permiten trazabilidad sin cambios posteriores.

## Contenidos

- Document: id, source, version, uploadedAt, metadata
- Chunk: id, documentId, text, position, startChar, endChar
- Embedding: id, chunkId, vector, model
- Relations entre entities
- Índices para búsqueda rápida

## Criterio de finalización

El modelo soporta recuperar de un documento → sección → párrafo → afirmación concreta. Cambios posteriores solo agregan metadatos, nunca alteran la trazabilidad.

## Después de esta guía

Pasás a P07 con la base de datos lista. Lectura de archivos sabe dónde guardar qué.
