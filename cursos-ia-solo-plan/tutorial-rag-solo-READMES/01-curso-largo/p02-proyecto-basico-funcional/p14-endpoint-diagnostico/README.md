# P14 — Endpoint de diagnóstico

**Guía de proyecto · ~2 h**

## Qué construyes

Un endpoint que muestra **exactamente** qué recuperó el sistema. Antes de que intervenga el LLM.

## Contenidos

- GET /api/search/diagnostics?query=...
- Respuesta: lista de fragmentos recuperados
- Para cada: texto, fuente, distancia, metadatos
- Número de tokens que ocuparía
- Formato JSON legible

## Criterio de finalización

Preguntas una pregunta. Sin LLM. Ves exactamente qué recuperó, de dónde viene, con qué distancia. Este endpoint es tu herramienta de debug permanente.

## Después de esta guía

Pasás a P15 con claridad total sobre qué entra al LLM.

## Nota crítica

Saltear P14 es el error más caro de toda esta parte. Sin inspección en retrieval, todo diagnóstico posterior es adivinanza.
