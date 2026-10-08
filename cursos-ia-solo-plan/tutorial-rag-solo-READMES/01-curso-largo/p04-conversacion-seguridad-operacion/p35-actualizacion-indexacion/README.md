# P35 — Actualización e indexación incremental

**Guía de proyecto · ~2.5 h**

## Qué construyes

Detecta documentos nuevos, modificados y eliminados sin reindexar todo.

## Contenidos

- ChangeDetector: compara versión local vs almacenado
- Ingestión incremental: solo lo nuevo
- Borrado: marca como deleted, no elimina
- Tests: tres escenarios de cambio

## Criterio de finalización

Subes documento nuevo. Sistema detecta que es nuevo. Indexa solo ese. Documentos existentes no se reindezan.

## Después de esta guía

Pasás a P36. Ahora manejo asíncrono de ingesta.
