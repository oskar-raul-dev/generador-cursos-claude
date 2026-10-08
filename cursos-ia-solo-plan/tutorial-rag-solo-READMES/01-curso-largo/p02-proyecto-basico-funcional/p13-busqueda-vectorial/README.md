# P13 — Búsqueda vectorial básica

**Guía de proyecto · ~2 h**

## Qué construyes

Recuperación por similitud coseno. Dada una pregunta, la conviertes en embedding y recuperas los k fragmentos más cercanos.

## Contenidos

- QueryEmbedder: convierte pregunta en vector
- VectorSearcher: similitud coseno con pgvector
- Top-K configurable
- Resultado: lista de fragmentos ordenados por distancia

## Criterio de finalización

Recuperás fragmentos relevantes para las preguntas de P05. Los fragmentos tienen distancia baja; los irrelevantes tienen distancia alta.

## Después de esta guía

Pasás a P14. Pero **no saltees P14**: es el punto de inspección más crucial del curso entero.
