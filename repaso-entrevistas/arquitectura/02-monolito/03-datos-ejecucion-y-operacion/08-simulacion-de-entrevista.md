# 08 — Simulación de entrevista: Datos, ejecución y operación

Practica sin abrir el solucionario. Para una sesión de 45 minutos, elige seis preguntas de S1–S20, dos de «las que descolocan» y dos escenarios; rota la selección en la sesión siguiente. Las 30 preguntas forman el banco completo.

## 🎤 Ronda transversal

S1. 🟢 ¿Dónde comienza una garantía transaccional?

S2. 🟢 ¿Qué controla una restricción única de operación?

S3. 🟢 ¿Qué diferencia evento en memoria de trabajo durable?

S4. 🟢 ¿Qué debe medir un SLO de compra?

S5. 🟡 ¿Cómo detectas lost update en stock?

S6. 🟡 ¿Cuándo eliges bloqueo pesimista?

S7. 🟡 ¿Qué debe hacer un retry tras conflicto optimista?

S8. 🟡 ¿Cómo limitas una cola interna?

S9. 🟡 ¿Qué implica afirmar entrega at-least-once?

S10. 🟡 ¿Qué perfilas antes de escalar CPU?

S11. 🟡 ¿Cómo afecta una caché a la garantía de lectura?

S12. 🟡 ¿Qué riesgo tiene aumentar el pool de conexiones?

S13. 🟡 ¿Qué significa rollback de código?

S14. 🟡 ¿Cómo probarías una migración compatible?

S15. 🟡 ¿Qué aporta correlación entre logs y trazas?

S16. 🟡 ¿Qué limita un bulkhead dentro del monolito?

S17. 🟡 ¿Cómo compararías transacción declarativa Java y sql.Tx de Go?

S18. 🟡 ¿Qué comparten tareas async de Python y Promises de Node?

S19. 🟡 ¿Qué prueba complementa un mock de repositorio?

S20. 🟡 ¿Qué diferencia readiness de proceso vivo?

## 🌀 Las que descolocan

S21. 🟠 ¿Una prueba end-to-end verde demuestra modularidad?

S22. 🟠 ¿Restaurar un backup siempre deshace una compra?

S23. 🟠 ¿Un job exactamente una vez es una afirmación suficiente?

S24. 🟠 ¿Una transacción más grande siempre es más segura?

S25. 🟠 ¿Un canary sin errores permite contraer el schema?

## 🧪 Escenarios

Los casos son ejercicios hipotéticos. Declara los supuestos que adoptes; no inventes mediciones. Cada ficha fija la garantía y el trade-off que debes discutir.

### E1 — Escenario obligatorio 4: réplicas, sesiones y jobs

**Evidencia disponible:** Al pasar de una a cuatro réplicas se pierden sesiones y se envían dos avisos por job.

**Supuestos faltantes:** Dónde vive estado, cómo se reclama trabajo y si el canal deduplica.

**Unidad de cambio:** Runtime compartido y efectos.

**Garantía prioritaria:** Sesión utilizable y efecto controlado ante repetición.

**Trade-off:** Coordinación durable frente a simplicidad en memoria.

**Primera acción reversible a proponer:** Pruebas aisladas de cambio de réplica y concurrencia.

**Prioridad senior que se evalúa:** No atribuir a escalado una garantía de ejecución única.

S26. 🟠 En E1, ¿qué verificas al añadir réplicas y qué corriges primero?

### E2 — Escenario obligatorio 5: schema incompatible durante rolling deployment

**Evidencia disponible:** Una columna desaparece mientras siguen activas réplicas que la leen.

**Supuestos faltantes:** Datos ya transformados, versión compatible disponible y writers activos.

**Unidad de cambio:** Despliegue y representación de datos.

**Garantía prioritaria:** No perder datos confirmados al recuperar servicio.

**Trade-off:** Pasos de compatibilidad frente a rapidez de retirada.

**Primera acción reversible a proponer:** Una contención que no destruya más datos.

**Prioridad senior que se evalúa:** Separar rollback de binario y reparación del schema.

S27. 🟠 En E2, ¿cómo contienes la migración que rompe réplicas antiguas?

### E3 — Última unidad disponible

**Evidencia disponible:** Dos `CreateOrder` compiten por un SKU con una unidad.

**Supuestos faltantes:** Aislamiento, SQL usado y comportamiento del retry.

**Unidad de cambio:** Transacción de reserva.

**Garantía prioritaria:** Como máximo una reserva válida de esa unidad.

**Trade-off:** Bloqueo o conflicto frente a throughput.

**Primera acción reversible a proponer:** Un ensayo concurrente reproducible en entorno de prueba.

**Prioridad senior que se evalúa:** Proteger la invariante en el recurso compartido.

S28. 🟠 En E3, ¿qué haces con el último stock en competencia?

### E4 — Avisos pendientes durante campaña

**Evidencia disponible:** La edad de `notifications` aumenta y compra empieza a esperar recursos.

**Supuestos faltantes:** Tasas de entrada y salida, límites y promesa de entrega.

**Unidad de cambio:** Pools y trabajo durable.

**Garantía prioritaria:** Compra disponible y aviso recuperable.

**Trade-off:** Capacidad reservada y retraso visible frente a uso máximo de recursos.

**Primera acción reversible a proponer:** Una medición y límite acotado por flujo.

**Prioridad senior que se evalúa:** Contener saturación sin borrar trabajo comprometido.

S29. 🟠 En E4, ¿cómo proteges compra cuando crece la cola de avisos?

### E5 — CPU libre y p99 alto

**Evidencia disponible:** Las réplicas usan poca CPU; el pool de DB permanece lleno.

**Supuestos faltantes:** Queries, locks, distribución de SKU y límites de conexiones.

**Unidad de cambio:** Recurso que limita runtime.

**Garantía prioritaria:** Latencia y corrección bajo carga.

**Trade-off:** Medición y optimización dirigida frente a escalado preventivo.

**Primera acción reversible a proponer:** Un perfil bajo carga representativa.

**Prioridad senior que se evalúa:** No confundir espera con falta de CPU.

S30. 🟠 En E5, ¿cómo decides el siguiente ensayo de rendimiento?

## 📏 Criterio de evaluación

Evalúa cada respuesta de 0 a 2 en cuatro dimensiones: evidencia separada de inferencia, garantía explícita, alternativa con coste y recuperación o revisión. Un 0 indica omisión; 1, mención sin aplicación; 2, decisión aplicada al caso. La suma orienta la práctica, no certifica seniority. Una contradicción de la garantía exige repetir el caso aunque el total sea alto.

## 📚 Preparación y contraste

Las definiciones y fuentes están en la [ruta del bloque](README.md). Contrasta después con el [solucionario](09-respuestas.md); una alternativa que conserve garantías y explique costes también puede ser válida.

---

[Índice del bloque](README.md) · [Índice general](../README.md)

**Anterior:** [07 — Estrategia de pruebas y evidencia de modularidad](07-estrategia-de-pruebas-y-evidencia-de-modularidad.md).

**Siguiente:** [09 — Respuestas: Datos, ejecución y operación](09-respuestas.md).
