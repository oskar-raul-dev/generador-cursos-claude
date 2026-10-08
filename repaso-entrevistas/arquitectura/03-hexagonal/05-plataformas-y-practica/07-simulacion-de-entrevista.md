# 07 — Simulación de entrevista: Plataformas y práctica

Esta simulación comprueba si puedes conservar la misma regla arquitectónica con mecanismos distintos. Compara Java, Node/TypeScript, Go y Python sin convertir preferencias en evidencia.

> **Vigencia:** 2026-09-27.

## 🎯 Cómo usarla

- Distingue lenguaje, framework y decisión arquitectónica.
- Explica la semántica real de tipos, scopes y transacciones.
- Ajusta plantilla y profundidad al riesgo del servicio.

## 🧠 Preguntas transversales

- S1. 🟢 ¿Qué regla permanece igual entre Java, Node/TS, Go y Python?
- S2. 🟢 ¿Qué aporta Spring y qué debes seguir decidiendo?
- S3. 🟢 ¿Qué riesgo añade TypeScript al recibir JSON?
- S4. 🟢 ¿Qué ventaja tienen las interfaces implícitas de Go?
- S5. 🟢 ¿Qué diferencia hay entre un `Protocol` de Python y validación runtime?
- S6. 🟢 ¿Dónde se fija la baseline de versiones del corpus?
- S7. 🟢 ¿Qué debe contener una plantilla de servicio mínima?
- S8. 🟡 ¿Cómo eliges entre DI automática y wiring explícito?
- S9. 🟡 ¿Qué diferencia transaccional debes explicar entre las cuatro plataformas?
- S10. 🟡 ¿Cómo evitas que `context.Context` contamine el dominio en Go?
- S11. 🟡 ¿Cómo evitas scope global accidental en Node/NestJS?
- S12. 🟡 ¿Qué prueba de Spring no reemplaza una prueba de dominio?
- S13. 🟡 ¿Qué coste tiene usar modelos Pydantic como dominio en Python?
- S14. 🟡 ¿Cómo manejas errores como valores en Go sin perder causa?
- S15. 🟡 ¿Cuándo elegirías una arquitectura más profunda para el mismo servicio?
- S16. 🟡 ¿Qué métrica te dice que una plantilla está sobrecargada?
- S17. 🟠 Java usa interfaces para cada clase y Go no usa ninguna. ¿Cuál es más hexagonal?
- S18. 🟠 NestJS inyecta Prisma directamente en el caso de uso. ¿Qué argumento das?
- S19. 🟠 Un método `@Transactional` se llama desde el mismo bean. ¿Qué verificas?
- S20. 🟠 Una coroutine de Python usa una sesión sync compartida. ¿Qué riesgo señalas?

## 🌀 Las que descolocan

- S21. 🟡 ¿Debe una plantilla imponer outbox a todos los servicios?
- S22. 🟡 ¿Cuándo usarías una clase abstracta en vez de interfaz o protocolo?
- S23. 🟠 ¿Cómo comparas ergonomía sin convertirla en una guerra de lenguajes?
- S24. 🟠 ¿Qué haces cuando el generador produce código que nadie entiende?
- S25. 🟠 ¿La validación runtime debe repetirse en cada plataforma?

## 🎭 Escenarios

### Escenario 1 — Template sobredimensionado

- **Fuerza:** Ajustar profundidad a un servicio trivial.
- **Trade-off:** Consistencia organizacional frente a coste cognitivo.
- **Prioridad senior:** Mínimo seguro y capacidades opcionales.

- S26. 🟠 Un CRUD pequeño generado trae repositorio genérico, outbox, broker y doce mappers. ¿Qué quitas?

### Escenario 2 — Elección con regulación

- **Fuerza:** Ponderar equipo, enforcement y operación.
- **Trade-off:** Ecosistema conocido frente a alternativas más ligeras.
- **Prioridad senior:** Elegir por riesgo total, no por moda.

- S27. 🟠 Debes elegir plataforma para un equipo Java con alta regulación y dominio complejo. ¿Qué priorizas?

### Escenario 3 — Proxy transaccional

- **Fuerza:** Verificar semántica real del framework.
- **Trade-off:** Comodidad declarativa frente a comportamiento invisible.
- **Prioridad senior:** Demarcación clara y prueba de integración.

- S28. 🟠 En Spring, una transacción no inicia por self-invocation. ¿Cómo corriges sin mover la regla al framework?

### Escenario 4 — Tipos sin runtime

- **Fuerza:** Separar compilación y confianza en datos externos.
- **Trade-off:** Velocidad de desarrollo frente a validación explícita.
- **Prioridad senior:** Schema en borde e invariantes en dominio.

- S29. 🟠 TypeScript compila, pero un payload inválido produce `undefined` dentro del dominio. ¿Qué frontera faltó?

### Escenario 5 — Ceremonia asimétrica

- **Fuerza:** Aplicar la misma regla con mecanismos idiomáticos.
- **Trade-off:** Uniformidad visual frente a claridad local.
- **Prioridad senior:** Contratos selectivos y composición visible.

- S30. 🟠 En Go hay veinte interfaces de un método y en Python todo usa globals. ¿Cómo equilibras?

## 🧭 Navegación

[← Matriz de decisión y plantilla de servicio](06-matriz-de-decision-y-plantilla-de-servicio.md) · [Respuestas →](08-respuestas.md)

