# 08 — Simulación de entrevista: Adaptadores de salida y operación

Esta simulación exige hablar de garantías reales: persistencia, llamadas remotas, outbox, composición, resiliencia, pruebas y migración. La respuesta fuerte distingue una frontera limpia de una operación confiable.

> **Vigencia:** 2026-09-27.

## 🎯 Cómo usarla

- Nombra contrato, mapeo, lifecycle y observabilidad de cada salida.
- Distingue commit local, entrega y efecto remoto.
- Propón migraciones verticales con evidencia y criterio de parada.

## 🧠 Preguntas transversales

- S1. 🟢 ¿Qué debe traducir un adaptador de persistencia?
- S2. 🟢 ¿Qué expresa un cliente externo detrás de un puerto?
- S3. 🟢 ¿Qué problema resuelve una outbox?
- S4. 🟢 ¿Qué pertenece al composition root?
- S5. 🟢 ¿Dónde se aplican timeout y retry técnicos?
- S6. 🟢 ¿Qué prueba necesita un adaptador JPA o SQL?
- S7. 🟢 ¿Qué es una prueba de contrato para un puerto?
- S8. 🟡 ¿Cuándo separar modelo de dominio y modelo ORM?
- S9. 🟡 ¿Cómo tratas un timeout de pago?
- S10. 🟡 ¿Por qué un fallback no debe inventar éxito?
- S11. 🟡 ¿Cómo ordenas eventos publicados por outbox?
- S12. 🟡 ¿Qué lifecycle merece un cliente HTTP?
- S13. 🟡 ¿Qué observabilidad agregas a un puerto externo?
- S14. 🟡 ¿Qué detecta un test arquitectónico y qué no?
- S15. 🟡 ¿Cómo migras un acceso directo a base sin reescribir todo?
- S16. 🟡 ¿Dónde traduces un error gRPC o HTTP externo?
- S17. 🟠 La consulta necesita joins optimizados y no reconstruye un agregado. ¿Rompe hexagonal?
- S18. 🟠 Un retry de infraestructura duplica un cobro. ¿Qué faltó?
- S19. 🟠 El dispatcher publica dos veces el mismo evento. ¿Es un bug de outbox?
- S20. 🟠 Un contenedor resuelve una dependencia con scope incorrecto. ¿Qué prueba lo detecta?

## 🌀 Las que descolocan

- S21. 🟡 ¿Debes crear un puerto para logs?
- S22. 🟡 ¿Una configuración tipada pertenece al dominio?
- S23. 🟠 ¿Qué haces si un contract test obliga a todos los adapters a copiar una limitación antigua?
- S24. 🟠 ¿Cuándo no usarías circuit breaker?
- S25. 🟠 ¿Cómo pruebas una migración gradual además de contar clases nuevas?

## 🎭 Escenarios

### Escenario 1 — Contrato de pagos cambiante

- **Fuerza:** Contener cambios de forma y semántica del proveedor.
- **Trade-off:** Mapeo propio frente a velocidad de adoptar el SDK.
- **Prioridad senior:** Puerto por capacidad, errores propios y contract tests.

- S26. 🟠 El proveedor de pagos cambia códigos, payload y semántica de timeout. ¿Dónde absorbes el cambio?

### Escenario 2 — Commit sin publicación

- **Fuerza:** Cerrar una ventana de doble escritura.
- **Trade-off:** Operar outbox frente a perder eventos.
- **Prioridad senior:** Registro atómico, dispatcher reanudable e idempotencia.

- S27. 🟠 La base confirma el pedido y el proceso cae antes de publicar el evento. ¿Cómo recuperas?

### Escenario 3 — Monolito mezclado

- **Fuerza:** Introducir una costura sin big bang.
- **Trade-off:** Duplicación temporal frente a riesgo de migración.
- **Prioridad senior:** Caracterización y extracción vertical por flujo.

- S28. 🟠 Migras un monolito donde controllers, SQL y reglas están mezclados. ¿Cuál es el primer corte?

### Escenario 4 — Lazy loading invisible

- **Fuerza:** Probar el límite real del ORM.
- **Trade-off:** Más integración frente a mocks rápidos.
- **Prioridad senior:** Test con motor real y mapeo fuera del dominio.

- S29. 🟠 Producción falla por lazy loading y todas las pruebas usan mocks. ¿Qué añades?

### Escenario 5 — Reintentos multiplicados

- **Fuerza:** Coordinar resiliencia entre capas.
- **Trade-off:** Disponibilidad aparente frente a tormenta y latencia.
- **Prioridad senior:** Presupuesto global, deadline y ownership único.

- S30. 🟠 Gateway, SDK y adapter hacen cada uno tres reintentos. ¿Qué corriges?

## 🧭 Navegación

[← Evolución y migración desde un monolito](07-evolucion-y-migracion-desde-un-monolito.md) · [Respuestas →](09-respuestas.md)

