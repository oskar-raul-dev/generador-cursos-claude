# P34 — Memoria de conversación

**Guía de proyecto · ~2.5 h**

## Qué construyes

Tres tipos de memoria: historial (turno a turno), resumen (condensado), conocimiento documental. No los mezclas en el mismo prompt.

## Contenidos

- ConversationMemory interface
- FullHistory: todos los turnos
- SummaryMemory: condensado a medida que crece
- DocumentMemory: fragmentos recuperados
- Configuración: cuánto historial guardar

## Criterio de finalización

Conversación larga se maneja sin explota el prompt. Resumen es coherente. Documentos recuperados siguen siendo relevantes.

## Después de esta guía

Pasás a P35. Ahora el corpus puede cambiar sin perder lo nuevo.
