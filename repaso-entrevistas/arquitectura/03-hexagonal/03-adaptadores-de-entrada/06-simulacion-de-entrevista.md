# 06 — Simulación de entrevista: Adaptadores de entrada

Esta simulación cambia el driver sin cambiar la política. Debes justificar qué se valida en el borde, qué contexto es confiable y cómo se presentan fallos sin convertir el transporte en el caso de uso.

> **Vigencia:** 2026-09-27.

## 🎯 Cómo usarla

- Di qué datos quedan en el adaptador y cuáles cruzan normalizados.
- Explica ACK, checkpoint, identidad y autorización con su garantía real.
- Conserva una semántica interna común sin uniformar protocolos.

## 🧠 Preguntas transversales

- S1. 🟢 ¿Qué responsabilidad comparten HTTP, un consumidor y una CLI?
- S2. 🟢 ¿Qué debe quedarse fuera del comando al entrar por HTTP?
- S3. 🟢 ¿Cuándo debe confirmarse un mensaje?
- S4. 🟢 ¿Qué diferencia hay entre autenticación y autorización?
- S5. 🟢 ¿Qué distingue un request DTO de un response DTO?
- S6. 🟢 ¿Qué hace un job antes de invocar el caso de uso?
- S7. 🟢 ¿Por qué un offset no debe usarse como identidad de negocio?
- S8. 🟡 ¿Dónde limitas el tamaño de una página solicitada por HTTP?
- S9. 🟡 ¿Cómo clasificas un error de consumidor como transitorio o permanente?
- S10. 🟡 ¿Qué protege una clave de idempotencia en varias entradas?
- S11. 🟡 ¿Por qué un lock de job no sustituye idempotencia?
- S12. 🟡 ¿Dónde vive una regla como “solo el dueño puede cancelar un pedido”?
- S13. 🟡 ¿Cómo presentas el mismo rechazo en HTTP y mensajería?
- S14. 🟡 ¿Cuándo un mapper manual supera a uno generado?
- S15. 🟡 ¿Cómo reanudas un batch sin omitir ni duplicar daño?
- S16. 🟡 ¿Qué observabilidad pertenece al adaptador de entrada?
- S17. 🟠 Un controller y un consumer validan la misma invariante de forma distinta. ¿Qué extraes?
- S18. 🟠 Un job nocturno procesa todo en una transacción de diez horas. ¿Qué cambias?
- S19. 🟠 El actor llega en un header que el cliente puede falsificar. ¿Qué falla?
- S20. 🟠 Una respuesta serializa una relación nueva del ORM sin querer. ¿Qué prevención aplicas?

## 🌀 Las que descolocan

- S21. 🟡 ¿Puede un adapter llamar dos casos de uso para una sola petición?
- S22. 🟡 ¿Debe la DLQ reprocesarse automáticamente?
- S23. 🟠 ¿Un `dry-run` que hace rollback local es seguro?
- S24. 🟠 ¿Dónde colocas rate limiting?
- S25. 🟠 ¿Cuándo compartirías un comando entre HTTP y mensajería?

## 🎭 Escenarios

### Escenario 1 — Consumidor contaminado por el broker

- **Fuerza:** Separar mecánica de entrega y decisión de negocio.
- **Trade-off:** Refactor gradual frente a riesgo de cambiar comportamiento oculto.
- **Prioridad senior:** Caracterizar, traducir a comando propio y mover reglas al caso.

- S26. 🟠 El consumidor usa topic, partición y offset para decidir descuentos. ¿Cómo lo corriges?

### Escenario 2 — Tres drivers, una intención

- **Fuerza:** Reutilizar política sin uniformar protocolos.
- **Trade-off:** Contrato común frente a necesidades de entrada distintas.
- **Prioridad senior:** Compartir intención e idempotencia; separar representación.

- S27. 🟠 La misma operación entra por HTTP, CLI y un scheduler. ¿Qué compartes?

### Escenario 3 — Actor desactualizado

- **Fuerza:** Combinar identidad verificada y autorización contextual.
- **Trade-off:** Menos consultas frente a permisos correctos.
- **Prioridad senior:** Validar recurso y estado con una política explícita.

- S28. 🟠 Un JWT contiene `role=admin`, pero el usuario perdió acceso al pedido. ¿Qué verificas?

### Escenario 4 — Batch interrumpido

- **Fuerza:** Garantizar reanudación segura.
- **Trade-off:** Throughput frente a unidades pequeñas y durables.
- **Prioridad senior:** Checkpoint posterior al efecto e idempotencia.

- S29. 🟠 Un batch cae después del efecto y antes del checkpoint. ¿Cómo reanuda?

### Escenario 5 — Versionado de salida

- **Fuerza:** Evitar que presentación dicte el modelo interno.
- **Trade-off:** Duplicación temporal frente a compatibilidad.
- **Prioridad senior:** DTO por versión y resultado de aplicación estable.

- S30. 🟠 Dos versiones HTTP necesitan campos de respuesta incompatibles. ¿Cambias el dominio?

## 🧭 Navegación

[← DTO, mapeo y presentación de errores](05-dto-mapeo-y-presentacion-de-errores.md) · [Respuestas →](07-respuestas.md)

