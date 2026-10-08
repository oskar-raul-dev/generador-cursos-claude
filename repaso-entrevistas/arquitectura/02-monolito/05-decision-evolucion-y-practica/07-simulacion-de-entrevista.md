# 07 — Simulación de entrevista: Decisión, evolución y práctica

Practica sin abrir el solucionario. Para una sesión de 45 minutos, elige seis preguntas de S1–S20, dos de «las que descolocan» y dos escenarios; rota la selección en la sesión siguiente. Las 30 preguntas forman el banco completo.

## 🎤 Ronda transversal

S1. 🟢 ¿Qué debe encabezar una recomendación de arquitectura?

S2. 🟢 ¿Qué primera mejora harías ante un dominio todavía cambiante?

S3. 🟢 ¿Qué hace útil un roadmap evolutivo?

S4. 🟢 ¿Qué conserva una decisión reversible?

S5. 🟡 ¿Cómo decides entre optimizar y extraer?

S6. 🟡 ¿Qué preguntas a quien promete releases independientes?

S7. 🟡 ¿Cómo eliges una costura del legado?

S8. 🟡 ¿Qué protege una matriz sin puntuación?

S9. 🟡 ¿Qué coste organizativo incluyes al extraer?

S10. 🟡 ¿Qué debe probar un ensayo de rollback?

S11. 🟡 ¿Cómo evitas una reescritura paralela interminable?

S12. 🟡 ¿Qué señal permite detener modularización?

S13. 🟡 ¿Qué dices si el entrevistador pide elegir sin cifras?

S14. 🟡 ¿Qué indica una mejora de lead time con más incidentes?

S15. 🟡 ¿Cómo traduces una exigencia de aislamiento a diseño?

S16. 🟡 ¿Qué debe medir el dueño de `payments`?

S17. 🟡 ¿Cómo cambia el diseño al pasar a otro lenguaje?

S18. 🟡 ¿Qué aporta un experimento de cohorte?

S19. 🟡 ¿Cómo gestionas una dependencia compartida inevitable?

S20. 🟡 ¿Qué aporta la fecha de revisión a un ADR?

## 🌀 Las que descolocan

S21. 🟠 ¿Cambiar de topología puede empeorar calidad interna?

S22. 🟠 ¿Cancelar una extracción desperdicia todo el trabajo?

S23. 🟠 ¿Puedes garantizar rollback después de cualquier migración?

S24. 🟠 ¿La arquitectura puede resolver una disputa de autoridad por sí sola?

S25. 🟠 ¿El diseño final debe ser completamente conocido al empezar?

## 🧪 Escenarios

Los casos son ejercicios hipotéticos. Declara los supuestos que adoptes; no inventes mediciones. Cada ficha fija la garantía y el trade-off que debes discutir.

### E1 — Escenario obligatorio 10: extracción de `payments`

**Evidencia disponible:** `payments` pide releases propios; hay historial y claves en la base del monolito y consumidores locales.

**Supuestos faltantes:** Writers ocultos, captura sin huecos, soporte remoto, guardia y retorno de datos.

**Unidad de cambio:** Contrato, escritura y despliegue de `payments`.

**Garantía prioritaria:** Autoridad única y ninguna operación confirmada perdida.

**Trade-off:** Autonomía de releases frente a red, reconciliación y migración.

**Primera acción reversible a proponer:** Una fachada y prueba en sombra sin cobros reales duplicados.

**Prioridad senior que se evalúa:** Ordenar migración, diferenciar rollback antes/después y declarar cancelación.

S26. 🟠 En E1, ¿cómo ordenarías la extracción y cuándo la cancelarías?

### E2 — Una matriz con un veto

**Evidencia disponible:** La opción distribuida puntúa bien, pero negocio exige confirmación conjunta de pedido y reserva.

**Supuestos faltantes:** Si la invariante admite espera o compensación y dónde están los recursos.

**Unidad de cambio:** Datos y consistencia.

**Garantía prioritaria:** Commit conjunto cuando el requisito sea no negociable.

**Trade-off:** Autonomía operativa frente a coordinación transaccional.

**Primera acción reversible a proponer:** Una aclaración verificable del requisito y ensayo local.

**Prioridad senior que se evalúa:** No promediar una garantía incumplida.

S27. 🟠 En E2, ¿qué restricción gobierna la decisión pese a los puntos de la matriz?

### E3 — Entrega próxima en legado

**Evidencia disponible:** Cancelar una reserva provoca regresiones y hay una mejora comercial urgente.

**Supuestos faltantes:** Cobertura actual, rutas de escritura y comportamiento repetido.

**Unidad de cambio:** Costura de cambio vertical.

**Garantía prioritaria:** Cancelación correcta sin perder nuevas entregas.

**Trade-off:** Adaptador transitorio frente a reestructuración total.

**Primera acción reversible a proponer:** Una caracterización y sustitución de alcance pequeño.

**Prioridad senior que se evalúa:** Conservar producción y entregar evidencia incremental.

S28. 🟠 En E3, ¿qué entregarías durante la primera semana?

### E4 — Equipo sobrecargado

**Evidencia disponible:** El equipo de pagos espera plataforma para cada release y ya atiende demasiadas alertas.

**Supuestos faltantes:** Causas de espera, alertas accionables y cobertura de guardia.

**Unidad de cambio:** Equipos y operación.

**Garantía prioritaria:** Recuperación sostenible con dueño definido.

**Trade-off:** Autoservicio y apoyo temporal frente a centralización.

**Primera acción reversible a proponer:** Un ensayo de release y recuperación acotado.

**Prioridad senior que se evalúa:** Medir carga real antes de asignar otra frontera.

S29. 🟠 En E4, ¿cómo probarías autonomía sin aumentar carga de guardia?

### E5 — Entrevista con información incompleta

**Evidencia disponible:** Solo se pide comercio con compra, reserva, pago y avisos; no se entregan cifras de pico.

**Supuestos faltantes:** Latencia, consistencia, demanda, aislamiento y equipo.

**Unidad de cambio:** Decisión del sistema completo.

**Garantía prioritaria:** Flujo trazable con garantías explícitas.

**Trade-off:** Rapidez de propuesta frente a incertidumbre asumida.

**Primera acción reversible a proponer:** Un supuesto contrastable y el primer experimento.

**Prioridad senior que se evalúa:** Conducir requisitos, fallo y roadmap sin inventar certeza.

S30. 🟠 En E5, ¿cómo cerrarías tu propuesta con la información disponible?

## 📏 Criterio de evaluación

Evalúa cada respuesta de 0 a 2 en cuatro dimensiones: evidencia separada de inferencia, garantía explícita, alternativa con coste y recuperación o revisión. Un 0 indica omisión; 1, mención sin aplicación; 2, decisión aplicada al caso. La suma orienta la práctica, no certifica seniority. Una contradicción de la garantía exige repetir el caso aunque el total sea alto.

## 📚 Preparación y contraste

Las definiciones y fuentes están en la [ruta del bloque](README.md). Contrasta después con el [solucionario](08-respuestas.md); una alternativa que conserve garantías y explique costes también puede ser válida.

---

[Índice del bloque](README.md) · [Índice general](../README.md)

**Anterior:** [06 — Caso completo de system design y estrategia evolutiva](06-caso-completo-de-system-design-y-estrategia-evolutiva.md).

**Siguiente:** [08 — Respuestas: Decisión, evolución y práctica](08-respuestas.md).
