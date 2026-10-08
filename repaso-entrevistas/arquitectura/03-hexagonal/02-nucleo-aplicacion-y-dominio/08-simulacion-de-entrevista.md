# 08 — Simulación de entrevista: Núcleo, aplicación y dominio

Esta simulación mezcla invariantes, orquestación, puertos, transacciones, errores y eventos. No basta con ubicar clases: debes declarar qué debe ser atómico y qué ocurre cuando un efecto externo queda incierto.

> **Vigencia:** 2026-09-27.

## 🎯 Cómo usarla

- Separa forma, autorización, coordinación e invariante.
- Nombra la unidad de consistencia y el dueño de cada contrato.
- Ante fallos distribuidos, responde con estados honestos e idempotencia.

## 🧠 Preguntas transversales

- S1. 🟢 ¿Qué decisión pertenece al dominio y cuál al caso de uso al crear un pedido?
- S2. 🟢 ¿Qué datos debería aceptar un puerto de entrada?
- S3. 🟢 ¿Qué expresa un puerto de salida bien diseñado?
- S4. 🟢 ¿Dónde debe comenzar y terminar una transacción local?
- S5. 🟢 ¿Qué diferencia hay entre error de negocio y error técnico?
- S6. 🟢 ¿Qué es un evento de dominio?
- S7. 🟢 ¿Cuándo una regla debe vivir en un value object?
- S8. 🟡 ¿Cómo evitas que un caso de uso se convierta en otro monolito?
- S9. 🟡 ¿Qué diferencia hay entre autorización contextual y una invariante?
- S10. 🟡 ¿Cuándo separas puertos de lectura y escritura?
- S11. 🟡 ¿Cómo diseñas idempotencia sin mencionar HTTP o Kafka?
- S12. 🟡 ¿Qué ocurre si cada repositorio abre y confirma su propia transacción?
- S13. 🟡 ¿Cuándo prefieres un resultado explícito a una excepción?
- S14. 🟡 ¿Dónde se traduce una constraint única de base?
- S15. 🟡 ¿Cuándo publicas una reacción a un evento de dominio?
- S16. 🟡 ¿Cómo pruebas una invariante sin arrancar infraestructura?
- S17. 🟠 Un comando válido en forma viola una regla de crédito. ¿Dónde se rechaza?
- S18. 🟠 Un puerto devuelve `null`, lanza timeout y a veces un error del SDK. ¿Qué corriges?
- S19. 🟠 Dos agregados deben cambiar juntos, pero viven en bases distintas. ¿Qué cuestionas?
- S20. 🟠 Un evento contiene el agregado completo para cualquier consumidor futuro. ¿Qué riesgo ves?

## 🌀 Las que descolocan

- S21. 🟡 ¿Puede el dominio llamar directamente a un reloj?
- S22. 🟡 ¿Un caso de uso puede devolver una entidad de dominio?
- S23. 🟠 ¿Una validación duplicada en borde y dominio es siempre un defecto?
- S24. 🟠 ¿Qué haces si una transacción declarativa exige anotar el caso de uso?
- S25. 🟠 ¿Cuándo una llamada directa es mejor que un evento de dominio?

## 🎭 Escenarios

### Escenario 1 — Evento perdido

- **Fuerza:** Cerrar la ventana entre commit local y publicación.
- **Trade-off:** Más estado operativo frente a entrega durable.
- **Prioridad senior:** Outbox atómica, dispatcher observable e idempotencia.

- S26. 🟠 La transacción guarda el pedido, pero el evento se pierde antes de publicarse. ¿Cómo rediseñas?

### Escenario 2 — Pago incierto

- **Fuerza:** Representar la incertidumbre de una llamada remota.
- **Trade-off:** Latencia del flujo frente a no cobrar o reservar dos veces.
- **Prioridad senior:** Estado pendiente, clave estable, consulta y compensación.

- S27. 🟠 Un pago queda en timeout después de reservar inventario. ¿Qué estado modelas?

### Escenario 3 — Idempotencia multicanal

- **Fuerza:** Unificar una intención que llega por drivers distintos.
- **Trade-off:** Contrato interno adicional frente a duplicados dañinos.
- **Prioridad senior:** Identidad de operación propia persistida con el efecto.

- S28. 🟠 HTTP y mensajería envían la misma operación con claves distintas. ¿Dónde unificas?

### Escenario 4 — Errores atravesando anillos

- **Fuerza:** Conservar semántica sin filtrar detalles.
- **Trade-off:** Tipos explícitos frente a manejo genérico más corto.
- **Prioridad senior:** Traducir una vez por frontera y mantener la causa interna.

- S29. 🟠 El dominio lanza `SQLException` y el controller la convierte en 400. ¿Qué fronteras fallaron?

### Escenario 5 — Reacciones incompatibles

- **Fuerza:** Distinguir hecho de mecanismo y garantía.
- **Trade-off:** Acoplamiento temporal frente a operación asíncrona.
- **Prioridad senior:** Separar handlers por consistencia y ownership.

- S30. 🟠 Dos handlers del mismo evento requieren garantías incompatibles. ¿Qué cambias?

## 🧭 Navegación

[← Eventos de dominio y efectos secundarios](07-eventos-de-dominio-y-efectos-secundarios.md) · [Respuestas →](09-respuestas.md)

