# P09 — Primera estrategia de chunking

**Guía de proyecto · ~2.5 h**

## Qué construyes

Chunker configurable: tamaño de fragmento y overlap como parámetros en application.yml.

## Contenidos

- ChunkingStrategy interface
- FixedSizeChunker: implementación por tamaño fijo
- Solapamiento (overlap) configurable
- Preservación de metadatos en cada chunk
- Tests variando parámetros

## Criterio de finalización

Cambias `chunk.size` y `chunk.overlap` en application.yml. Recompilación no necesaria. Ves el efecto en los fragmentos generados.

## Después de esta guía

Pasás a P10 con chunks listos. Ahora los conviertes en vectores.
