# P10 — Generación de embeddings

**Guía de proyecto · ~2.5 h**

## Qué construyes

Llamadas a Ollama para generar embeddings de cada fragment. Procesamiento por lotes para velocidad. Medición de tiempo.

## Contenidos

- EmbeddingService: interfaz para generación
- OllamaEmbeddingService: implementación con ollama.embed
- Batch processing: agrupar requests
- Error handling: embedding fallido no tumba la ingestión
- Métrica: tiempo total de indexación

## Criterio de finalización

Indexás el corpus completo. Sabés cuánto tardó. Las métricas de tiempo se registran.

## Después de esta guía

Pasás a P11 con embeddings generados. Ahora los guardás en pgvector.
