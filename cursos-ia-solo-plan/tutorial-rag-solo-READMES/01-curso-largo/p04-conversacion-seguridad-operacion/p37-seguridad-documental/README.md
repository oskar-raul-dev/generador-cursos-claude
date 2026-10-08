# P37 — Seguridad documental

**Guía de proyecto · ~2.5 h**

## Qué construyes

Control de acceso basado en permisos. El filtro va en el retrieval, nunca en el prompt.

## Contenidos

- Document permissions: ACL
- Documento marca documentos como restricted
- Retrieval: filtra por permisos del usuario
- Tests: usuario sin permiso no ve documento

## Criterio de finalización

Usuario sin permiso pregunta algo. Sistema recupera solo documentos que puede ver. Filtr es en SQL, no en LLM.

## Después de esta guía

Pasás a P38. Ahora defensa contra prompt injection.
