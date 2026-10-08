# 07 — Simulación de entrevista: Fundamentos y modelo mental

Practica sin abrir el solucionario. Para una sesión de 45 minutos, elige seis preguntas de S1–S25, dos de «las que descolocan» y dos escenarios; rota la selección en la sesión siguiente. Las 35 preguntas forman el banco completo.

## 🎤 Ronda transversal

S1. 🟢 ¿Cómo explicarías un monolito que ejecuta ocho réplicas?

S2. 🟢 ¿Puede un módulo pertenecer a un monolito y tener dueño propio?

S3. 🟢 ¿Qué distingue estructura interna de topología?

S4. 🟢 ¿Qué significa unidad de datos en `CreateOrder`?

S5. 🟡 ¿Por qué contar repositorios no clasifica la arquitectura?

S6. 🟡 ¿Cómo reconocerías cohesión en `inventory`?

S7. 🟡 ¿Qué precio tiene una llamada local?

S8. 🟡 ¿Qué precio añade una llamada remota?

S9. 🟡 ¿Cómo medirías acoplamiento de cambio?

S10. 🟡 ¿Qué evidencia necesitarías para llamar big ball of mud a un monolito?

S11. 🟡 ¿Cuándo una duplicación pequeña puede ser razonable?

S12. 🟡 ¿Qué no compra una base física por capacidad?

S13. 🟡 ¿Qué preguntarías ante una petición de microservicios?

S14. 🟡 ¿Cómo diferencias autonomía de aislamiento?

S15. 🟡 ¿Puede un sistema modular fallar por una dependencia externa?

S16. 🟡 ¿Qué deberías conservar al modularizar?

S17. 🟡 ¿Cómo cambia tu recomendación con un dominio volátil?

S18. 🟡 ¿Qué datos organizativos pedirías antes de distribuir?

S19. 🟡 ¿Cómo justificas una fecha de revisión?

S20. 🟡 ¿Qué métrica de escalado puede engañar?

S21. 🟡 ¿Por qué elegir entre capas y *clean architecture* no responde dónde termina `orders`?

S22. 🟡 ¿Qué ganarías y qué pagarías con un Domain Model en `inventory` y Transaction Scripts en los listados?

S23. 🟡 ¿Cómo explicarías que un sistema hexagonal puede desplegarse como un monolito o como varios servicios?

S24. 🟡 ¿Qué evidencia de cambio te diría que el estilo interno de un módulo ya no le sirve?

S25. 🟡 ¿Qué regla automatizada pedirías antes de aceptar que un equipo «ya usa clean architecture»?

## 🌀 Las que descolocan

S26. 🟠 ¿Un monolito con plugins sigue siendo monolito?

S27. 🟠 ¿Eliminar todas las dependencias mejoraría el sistema?

S28. 🟠 ¿Puedes recomendar no cambiar la arquitectura?

S29. 🟠 ¿Una transacción entre módulos demuestra que el límite es malo?

S30. 🟠 ¿La arquitectura más fácil de explicar siempre es la mejor?

## 🧪 Escenarios

Los casos son ejercicios hipotéticos. Declara los supuestos que adoptes; no inventes mediciones. Cada ficha fija la garantía y el trade-off que debes discutir.

### E1 — Escenario obligatorio 1: startup de seis personas

**Evidencia disponible:** Dominio y carga inciertos; se quiere lanzar compra con `orders`, `inventory`, `payments` y `notifications`.

**Supuestos faltantes:** Picos, plazo de pago, experiencia de guardia y ritmo de cambio.

**Unidad de cambio:** Producto y equipo inicial.

**Garantía prioritaria:** Pedido trazable y reserva válida.

**Trade-off:** Rapidez de aprendizaje frente a aislamiento operativo.

**Primera acción reversible a proponer:** Un experimento acotado que valide el primer flujo sin fijar contratos remotos internos.

**Prioridad senior que se evalúa:** Defender una topología proporcional con señal de revisión.

S31. 🟠 En E1, ¿qué construirías primero y qué te haría revisar la topología?

### E2 — Veinte procesos iguales

**Evidencia disponible:** El operador muestra veinte instancias con el mismo artefacto.

**Supuestos faltantes:** Política de sesiones, jobs y releases.

**Unidad de cambio:** Runtime frente a despliegue.

**Garantía prioritaria:** Continuidad del flujo al cambiar de réplica.

**Trade-off:** Capacidad horizontal frente a coordinación de estado.

**Primera acción reversible a proponer:** Una inspección o prueba sin modificar topología.

**Prioridad senior que se evalúa:** Nombrar unidades antes de recomendar.

S32. 🟠 En E2, ¿qué unidades nombras antes de juzgar los veinte procesos?

### E3 — Código antiguo, cambios predecibles

**Evidencia disponible:** El producto lleva años y entrega cambios de stock sin incidentes recientes.

**Supuestos faltantes:** Cobertura de recuperación y soporte efectivo de dependencias.

**Unidad de cambio:** Cambio y operación.

**Garantía prioritaria:** Conducta de reserva preservada.

**Trade-off:** Coste de modernización frente a riesgo confirmado.

**Primera acción reversible a proponer:** Una medición o caracterización que contraste el riesgo.

**Prioridad senior que se evalúa:** No usar antigüedad como diagnóstico.

S33. 🟠 En E3, ¿qué evidencia permitiría mantener el código antiguo?

### E4 — Dos validadores parecidos

**Evidencia disponible:** `orders` y `notifications` contienen validadores de dirección con campos similares.

**Supuestos faltantes:** Si representan entrega física o canal de contacto y quién decide reglas.

**Unidad de cambio:** Código y significado del dato.

**Garantía prioritaria:** Validación correcta para cada propósito.

**Trade-off:** Duplicación pequeña frente a modelo común coordinado.

**Primera acción reversible a proponer:** Una comparación de razones de cambio antes de unificar.

**Prioridad senior que se evalúa:** Priorizar semántica sobre DRY mecánico.

S34. 🟠 En E4, ¿cómo valoras mantener la validación duplicada?

### E5 — Un repositorio, cuatro artefactos

**Evidencia disponible:** Un pipeline compila cuatro ejecutables de comercio en el mismo repositorio.

**Supuestos faltantes:** Compatibilidad de versiones, propiedad de tablas y libertad de release.

**Unidad de cambio:** Código frente a despliegue.

**Garantía prioritaria:** Cambios compatibles con consumidores vigentes.

**Trade-off:** Build compartido frente a coordinación obligatoria.

**Primera acción reversible a proponer:** Un ensayo de versiones mixtas o inventario de releases.

**Prioridad senior que se evalúa:** Evitar clasificar por número de repositorios.

S35. 🟠 En E5, ¿qué concluyes del build compartido?

## 📏 Criterio de evaluación

Evalúa cada respuesta de 0 a 2 en cuatro dimensiones: evidencia separada de inferencia, garantía explícita, alternativa con coste y recuperación o revisión. Un 0 indica omisión; 1, mención sin aplicación; 2, decisión aplicada al caso. La suma orienta la práctica, no certifica seniority. Una contradicción de la garantía exige repetir el caso aunque el total sea alto.

## 📚 Preparación y contraste

Las definiciones y fuentes están en la [ruta del bloque](README.md). Contrasta después con el [solucionario](08-respuestas.md); una alternativa que conserve garantías y explique costes también puede ser válida.

---

[Índice del bloque](README.md) · [Índice general](../README.md)

**Anterior:** [06 — Estilos de estructura interna: capas, clean, onion y vertical slice](06-estilos-de-estructura-interna.md).

**Siguiente:** [08 — Respuestas: Fundamentos y modelo mental](08-respuestas.md).
