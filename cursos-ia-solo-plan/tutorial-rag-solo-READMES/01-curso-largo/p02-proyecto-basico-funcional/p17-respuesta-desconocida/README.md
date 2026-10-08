# P17 — Manejo de la respuesta desconocida

**Guía de proyecto · ~2 h**

## Qué construyes

Abstención: cuando el corpus no tiene la respuesta, el sistema dice "no sé" en lugar de inventar.

## Contenidos

- Prompt con grounding: instrucción explícita de abstenerse
- Detección de abstención en la respuesta
- Criterio: distancia promedio de fragmentos, longitud de respuesta
- Manejo: bandera de confianza

## Criterio de finalización

La pregunta "¿cuál es la política de licencia de maternidad?" (que no existe en el corpus) produce abstención desde aquí hasta el final del curso. Es tu prueba de regresión permanente.

## Después de esta guía

Pasás a P18 con un RAG que responde, cita y se abstiene. El MVP es funcional.
