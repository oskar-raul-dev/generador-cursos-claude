# 07 — Simulación de entrevista: Modularidad y límites internos

Practica sin abrir el solucionario. Para una sesión de 45 minutos, elige seis preguntas de S1–S20, dos de «las que descolocan» y dos escenarios; rota la selección en la sesión siguiente. Las 30 preguntas forman el banco completo.

## 🎤 Ronda transversal

S1. 🟢 ¿Qué diferencia una capacidad de una capa técnica?

S2. 🟢 ¿Qué hace pública una API de módulo?

S3. 🟢 ¿Qué significa poseer una tabla?

S4. 🟢 ¿Qué sería un shared kernel pequeño?

S5. 🟡 ¿Cómo rompes un ciclo `orders`–`inventory`?

S6. 🟡 ¿Cuándo una llamada directa es suficiente?

S7. 🟡 ¿Qué diferencia comando de evento?

S8. 🟡 ¿Cómo evitar que una fachada crezca sin límite?

S9. 🟡 ¿Qué riesgo tiene exportar el cliente SQL común?

S10. 🟡 ¿Cuándo aceptarías un join de lectura?

S11. 🟡 ¿Cómo probarías un límite interno?

S12. 🟡 ¿Qué problema causa common sin dueño?

S13. 🟡 ¿Cómo se conectan APIs sin un contenedor DI?

S14. 🟡 ¿Qué criterio usa una excepción de importación?

S15. 🟡 ¿Qué cambia si el evento interno corre síncronamente?

S16. 🟡 ¿Qué pasa con un evento emitido solo en memoria antes de una caída?

S17. 🟡 ¿Cómo comparas visibilidad Java e internal de Go?

S18. 🟡 ¿Cómo comparas tipos TypeScript y anotaciones Python como límite?

S19. 🟡 ¿Qué debe devolver `ReserveInventory`?

S20. 🟡 ¿Cómo revisas si una frontera sigue siendo útil?

## 🌀 Las que descolocan

S21. 🟠 ¿Un módulo necesita su propia base para ser real?

S22. 🟠 ¿Todo ciclo debe eliminarse añadiendo un mediador?

S23. 🟠 ¿Duplicar un DTO siempre viola DRY?

S24. 🟠 ¿Un test arquitectónico verde certifica módulos correctos?

S25. 🟠 ¿Puedes conservar una dependencia bidireccional temporal?

## 🧪 Escenarios

Los casos son ejercicios hipotéticos. Declara los supuestos que adoptes; no inventes mediciones. Cada ficha fija la garantía y el trade-off que debes discutir.

### E1 — Escenario obligatorio 2: cambio pequeño entre capas y dominios

**Evidencia disponible:** Una regla toca controller, service y repository de `orders` e `inventory`.

**Supuestos faltantes:** Motivo de cada edición, defectos y frecuencia de repetición.

**Unidad de cambio:** Cambio vertical de negocio.

**Garantía prioritaria:** Comportamiento de reserva conservado.

**Trade-off:** Adaptación transitoria frente a menor dispersión.

**Primera acción reversible a proponer:** Una costura verificable para una sola operación.

**Prioridad senior que se evalúa:** Distinguir capas legítimas de propagación accidental.

S26. 🟠 En E1, ¿qué cambio harías antes de reorganizar todos los paquetes?

### E2 — Escenario obligatorio 3: módulos que escriben tablas ajenas

**Evidencia disponible:** `orders` actualiza stock y `notifications` modifica el estado del pedido.

**Supuestos faltantes:** Writers ocultos, invariantes y dueños capaces de operarlos.

**Unidad de cambio:** Datos y autoridad por capacidad.

**Garantía prioritaria:** Solo el dueño valida la escritura.

**Trade-off:** APIs y migración de consumidores frente a accesos directos.

**Primera acción reversible a proponer:** Un inventario y una migración acotada que mantenga servicio.

**Prioridad senior que se evalúa:** Recuperar ownership antes de separación física.

S27. 🟠 En E2, ¿cómo recuperas autoridad sin mover las tablas?

### E3 — Biblioteca common dominante

**Evidencia disponible:** Una actualización de common obliga a cambiar los cuatro módulos.

**Supuestos faltantes:** Qué tipos son estables y qué reglas tienen motivos distintos.

**Unidad de cambio:** Código y coordinación.

**Garantía prioritaria:** Semántica de importes e identidades preservada.

**Trade-off:** Duplicación controlada frente a gobierno compartido.

**Primera acción reversible a proponer:** Una clasificación o sustitución de un único consumidor.

**Prioridad senior que se evalúa:** Compartir por significado estable.

S28. 🟠 En E3, ¿cómo decides si conservar la biblioteca común?

### E4 — Ciclo escondido en un bus

**Evidencia disponible:** Las reglas de imports pasan, pero `inventory` espera un callback de `orders` para reservar.

**Supuestos faltantes:** Orden de ejecución, errores y transacción.

**Unidad de cambio:** Runtime y dirección de decisiones.

**Garantía prioritaria:** Reserva decidida por autoridad identificable.

**Trade-off:** Flujo explícito frente a flexibilidad del bus.

**Primera acción reversible a proponer:** Una traza o prueba de secuencia antes de cambiar mecanismo.

**Prioridad senior que se evalúa:** No confundir desacoplamiento estático y temporal.

S29. 🟠 En E4, ¿cómo localizarías el ciclo que aún aparece en producción?

### E5 — Reporting transversal

**Evidencia disponible:** Un reporte necesita pedidos, pagos y reservas y hoy usa joins de solo lectura.

**Supuestos faltantes:** Frescura, volumen, horario y exposición permitida.

**Unidad de cambio:** Contrato de lectura.

**Garantía prioritaria:** Lectura adecuada sin transferir escritura.

**Trade-off:** Consulta eficiente frente a acoplamiento de schema y carga.

**Primera acción reversible a proponer:** Una medición y contrato de lectura acotado.

**Prioridad senior que se evalúa:** Elegir el mecanismo proporcional al reporte.

S30. 🟠 En E5, ¿qué acceso de reporting permitirías?

## 📏 Criterio de evaluación

Evalúa cada respuesta de 0 a 2 en cuatro dimensiones: evidencia separada de inferencia, garantía explícita, alternativa con coste y recuperación o revisión. Un 0 indica omisión; 1, mención sin aplicación; 2, decisión aplicada al caso. La suma orienta la práctica, no certifica seniority. Una contradicción de la garantía exige repetir el caso aunque el total sea alto.

## 📚 Preparación y contraste

Las definiciones y fuentes están en la [ruta del bloque](README.md). Contrasta después con el [solucionario](08-respuestas.md); una alternativa que conserve garantías y explique costes también puede ser válida.

---

[Índice del bloque](README.md) · [Índice general](../README.md)

**Anterior:** [06 — Código compartido, *shared kernel* y controles arquitectónicos](06-codigo-compartido-shared-kernel-y-controles-arquitectonicos.md).

**Siguiente:** [08 — Respuestas: Modularidad y límites internos](08-respuestas.md).
