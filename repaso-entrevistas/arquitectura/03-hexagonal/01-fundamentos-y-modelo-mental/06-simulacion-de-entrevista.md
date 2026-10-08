# 06 — Simulación de entrevista: Fundamentos y modelo mental

Esta simulación comprueba si puedes razonar sobre límites sin refugiarte en nombres de carpetas. Responde primero en 30 segundos; después añade evidencia, coste y una alternativa proporcional.

> **Vigencia:** 2026-09-27.

## 🎯 Cómo usarla

- Nombra la política y el detalle antes de proponer clases.
- Dibuja la dirección de dependencias y distingue el flujo de runtime.
- Cierra cada respuesta con el coste de la frontera o de no crearla.

## 🧠 Preguntas transversales

- S1. 🟢 ¿Qué cambio intenta proteger primero una arquitectura hexagonal?
- S2. 🟢 ¿Cómo distingues política de detalle en una revisión de código?
- S3. 🟢 ¿Qué evidencia mínima muestra que el núcleo no depende de HTTP?
- S4. 🟢 ¿Quién debe definir un puerto de salida?
- S5. 🟢 ¿Por qué el flujo de ejecución y la dirección de dependencias pueden apuntar distinto?
- S6. 🟢 ¿Qué coste aparece al separar request, command y modelo de dominio?
- S7. 🟢 ¿Qué hace que un adaptador sea una frontera y no solo un wrapper?
- S8. 🟡 ¿Cómo decides si una interfaz nueva compensa?
- S9. 🟡 ¿Qué revisarías si todos los paquetes tienen carpetas `domain`, `application` e `infrastructure`?
- S10. 🟡 ¿Cuándo un tipo compartido entre núcleo e infraestructura es aceptable?
- S11. 🟡 ¿Qué diferencia hay entre aislar una dependencia y eliminarla?
- S12. 🟡 ¿Cómo sabes si un puerto está diseñado desde el negocio?
- S13. 🟡 ¿Qué papel cumple el composition root en la regla de dependencias?
- S14. 🟡 ¿Qué prueba aporta más evidencia que un mock por cada clase?
- S15. 🟡 ¿Cómo comparas Hexagonal, Clean y Onion sin discutir etiquetas?
- S16. 🟡 ¿Cuándo un módulo compilable aporta más que una convención?
- S17. 🟠 Un equipo cambia de ORM sin tocar dominio, pero cada regla exige editar tres controllers. ¿Está bien protegido?
- S18. 🟠 El núcleo importa una librería de fechas. ¿Es siempre una violación?
- S19. 🟠 Una abstracción reduce líneas, pero hace más difícil localizar una regla. ¿La conservas?
- S20. 🟠 ¿Cómo presentarías una excepción temporal a la regla de dependencias?

## 🌀 Las que descolocan

- S21. 🟡 ¿Puede una función concreta ser un puerto sin interfaz nominal?
- S22. 🟡 ¿Eliminar un mapper puede mejorar la arquitectura?
- S23. 🟠 ¿Un dominio con anotaciones de framework deja de ser dominio automáticamente?
- S24. 🟠 ¿Por qué un repositorio en memoria puede dar falsa confianza?
- S25. 🟠 ¿Qué responderías si te piden aplicar hexagonal a todo el portafolio?

## 🎭 Escenarios

### Escenario 1 — Endpoint acoplado

- **Fuerza:** Separar política, HTTP y persistencia sin reescribir el servicio.
- **Trade-off:** Velocidad de extracción frente a protección inmediata de la regla.
- **Prioridad senior:** Crear una costura pequeña, cubrir comportamiento y migrar por riesgo.

- S26. 🟠 Un endpoint devuelve directamente una entidad JPA y una regla vive en el controller. ¿Qué corriges primero?

### Escenario 2 — CRUD sobrearquitecturado

- **Fuerza:** Distinguir complejidad esencial de ceremonia preventiva.
- **Trade-off:** Uniformidad de plantilla frente a coste cognitivo.
- **Prioridad senior:** Eliminar abstracciones sin perder modularidad ni pruebas.

- S27. 🟠 Un CRUD interno estable tiene doce interfaces y seis mappers. ¿Qué simplificas?

### Escenario 3 — Puerto espejo

- **Fuerza:** Recuperar un contrato propio ante un proveedor volátil.
- **Trade-off:** Mapeo adicional frente a radio de cambio externo.
- **Prioridad senior:** Nombrar la capacidad y traducir estados y errores una sola vez.

- S28. 🟠 El proveedor cambia su SDK, pero el puerto copia exactamente sus tipos. ¿Qué concluyes?

### Escenario 4 — Política escondida en datos

- **Fuerza:** Hacer visible una regla que hoy ejecuta la base.
- **Trade-off:** Garantía de integridad frente a testabilidad y ownership.
- **Prioridad senior:** Caracterizar antes de mover y conservar defensas necesarias.

- S29. 🟠 Las reglas críticas están en triggers de base y el dominio parece limpio. ¿Qué riesgo explicas?

### Escenario 5 — DI sin inversión

- **Fuerza:** Separar mecanismo de inyección y diseño de dependencias.
- **Trade-off:** Conveniencia del contenedor frente a contratos contaminados.
- **Prioridad senior:** Mantener el mecanismo y corregir quién define cada contrato.

- S30. 🟠 El contenedor inyecta todo y no hay `new`, pero el caso de uso recibe SDKs y DTO externos. ¿Es hexagonal?

## 🧭 Navegación

[← Cuándo no usarla y antipatrones](05-cuando-no-usarla-y-antipatrones.md) · [Respuestas →](07-respuestas.md)

