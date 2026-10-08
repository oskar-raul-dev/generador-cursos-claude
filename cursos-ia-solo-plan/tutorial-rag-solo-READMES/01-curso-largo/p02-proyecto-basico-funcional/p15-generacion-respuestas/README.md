# P15 — Generación de respuestas

**Guía de proyecto · ~2.5 h**

## Qué construyes

Integración del LLM. Tomas los fragmentos recuperados, construyes un prompt y llamas a `gemma3:4b` para generar respuesta.

## Contenidos

- ResponseGenerator: orquestación
- Construcción del prompt: instrucciones + contexto + pregunta
- Llamada a ChatClient de Spring AI
- Parseo de la respuesta
- Endpoint de query: `/api/query`

## Criterio de finalización

Una pregunta sobre el corpus recupera evidencia y genera respuesta. El texto de la respuesta es coherente y basado en los fragmentos.

## Después de esta guía

Pasás a P16. Ahora las respuestas tienen que incluir citas.
