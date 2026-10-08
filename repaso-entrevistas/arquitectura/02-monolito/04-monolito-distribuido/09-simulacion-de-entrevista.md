# 09 — Simulación de entrevista: Monolito distribuido

Practica sin abrir el solucionario. Para una sesión de 45 minutos, elige seis preguntas de S1–S25, dos de «las que descolocan» y dos escenarios; rota la selección en la sesión siguiente. Las 35 preguntas forman el banco completo.

## 🎤 Ronda transversal

S1. 🟢 ¿Qué evidencia combina un diagnóstico de monolito distribuido?

S2. 🟢 ¿Qué es acoplamiento temporal?

S3. 🟢 ¿Qué indica un timeout remoto?

S4. 🟢 ¿Qué significa compatibilidad entre releases?

S5. 🟡 ¿Cómo aproximas disponibilidad de una cadena?

S6. 🟡 ¿Cómo repartes un timeout budget?

S7. 🟡 ¿Qué es una tormenta de retries?

S8. 🟡 ¿Cuándo una API resulta chatty?

S9. 🟡 ¿Qué añade una proyección local?

S10. 🟡 ¿Por qué permisos importan al recuperar ownership?

S11. 🟡 ¿Qué protege un contrato de consumidor?

S12. 🟡 ¿Qué riesgo añade un nuevo valor de estado?

S13. 🟡 ¿Qué conecta outbox e inbox?

S14. 🟡 ¿Qué diferencia saga y rollback local?

S15. 🟡 ¿Qué métrica demuestra menor lockstep?

S16. 🟡 ¿Cuándo fusionarías componentes?

S17. 🟡 ¿Cómo comparas DTO Java y validación Node en contratos?

S18. 🟡 ¿Qué comparten Go y Python ante un timeout?

S19. 🟡 ¿Qué criterio prioriza una remediación?

S20. 🟡 ¿Qué debes conservar durante coexistencia de rutas?

S21. 🟡 ¿Cómo distinguirías, en una entrevista, un sistema con broker que desacopla de uno que solo cambió el transporte?

S22. 🟡 ¿Qué relación hay entre un servicio por entidad y una cadena síncrona larga?

S23. 🟡 ¿Qué preguntarías sobre la librería `commons` antes de diagnosticar un monolito distribuido?

S24. 🟡 ¿Cuándo el retraso de un consumidor es un problema de negocio y cuándo no?

S25. 🟡 ¿Cómo afecta la estructura de equipos a la remediación de un monolito distribuido?

## 🌀 Las que descolocan

S26. 🟠 ¿Los eventos eliminan cualquier cadena temporal?

S27. 🟠 ¿Versionar una URL vuelve independiente al proveedor?

S28. 🟠 ¿Dos bases eliminan escrituras cruzadas?

S29. 🟠 ¿2PC resuelve por defecto el pago externo?

S30. 🟠 ¿Menos servicios siempre significa menos acoplamiento?

## 🧪 Escenarios

Los casos son ejercicios hipotéticos. Declara los supuestos que adoptes; no inventes mediciones. Cada ficha fija la garantía y el trade-off que debes discutir.

### E1 — Escenario obligatorio 6: cinco servicios y release train

**Evidencia disponible:** `orders`, `inventory`, `payments`, `notifications` y una pasarela de composición forman una cadena síncrona; liberan juntos cada semana.

**Supuestos faltantes:** Si el tren es obligatorio, cambios que lo causan y SLO completo.

**Unidad de cambio:** Despliegue, runtime y equipos.

**Garantía prioritaria:** Compra completada o pendiente bajo contrato claro.

**Trade-off:** Compatibilidad o asincronía frente a coordinación y latencia.

**Primera acción reversible a proponer:** Un inventario de versiones y traza representativa del flujo.

**Prioridad senior que se evalúa:** Diagnosticar por evidencias combinadas y escoger una costura.

S31. 🟠 En E1, ¿cómo sostienes o rechazas el diagnóstico y eliges el primer cambio?

### E2 — Escenario obligatorio 7: base compartida y autoridad disputada

**Evidencia disponible:** Dos equipos modifican las tablas de autorizaciones y bloquean cambios de schema mutuamente.

**Supuestos faltantes:** Dueño de la invariante, scripts activos y capacidad de guardia.

**Unidad de cambio:** Datos y decisión organizativa.

**Garantía prioritaria:** Un propietario valida cada cambio monetario.

**Trade-off:** Migración de consumidores frente a escritura directa.

**Primera acción reversible a proponer:** Una matriz de accesos y un comando controlado.

**Prioridad senior que se evalúa:** Resolver autoridad antes de multiplicar bases.

S32. 🟠 En E2, ¿cómo resolverías el ownership disputado?

### E3 — Escenario obligatorio 8: timeout después de autorizar

**Evidencia disponible:** El proveedor registra autorización, pero `payments` recibe timeout y el cliente pulsa otra vez.

**Supuestos faltantes:** Consulta por clave, retención idempotente y duración de la reserva.

**Unidad de cambio:** Efecto externo e identidad de intención.

**Garantía prioritaria:** No autorizar dos veces la misma intención y conservar trazabilidad.

**Trade-off:** Pendiente visible y reconciliación frente a respuesta inmediata.

**Primera acción reversible a proponer:** Una consulta por identidad sin nuevo efecto.

**Prioridad senior que se evalúa:** Separar incertidumbre de rechazo.

S33. 🟠 En E3, ¿qué ve el usuario y cómo evitas otro cobro?

### E4 — Escenario obligatorio 9: fusionar para recuperar una transacción

**Evidencia disponible:** Dos servicios propios de pedido y reserva cambian siempre juntos, pertenecen al mismo equipo y pagan fallos de red sin aislamiento útil medido.

**Supuestos faltantes:** Recursos de datos, coste de runtime conjunto y camino de retorno.

**Unidad de cambio:** Despliegue y transacción.

**Garantía prioritaria:** Pedido y reserva se confirman juntos si participan en el mismo recurso.

**Trade-off:** Menos operación y red frente a radio de fallo común.

**Primera acción reversible a proponer:** Una fachada y ensayo acotado de implementación local.

**Prioridad senior que se evalúa:** Defender la fusión por garantías y coste, no por ideología.

S34. 🟠 En E4, ¿cómo ejecutarías la fusión sin perder garantías?

### E5 — Retirada incompatible de un evento

**Evidencia disponible:** `payments` quiere quitar `authorizationId` y quedan consumidores viejos y mensajes históricos.

**Supuestos faltantes:** Versiones soportadas, retención de replay y telemetría por consumidor.

**Unidad de cambio:** Contrato entre releases.

**Garantía prioritaria:** Lectores vigentes interpretan correctamente la autorización.

**Trade-off:** Soporte temporal de campos frente a libertad de release.

**Primera acción reversible a proponer:** Una prueba de versiones mixtas con payloads históricos.

**Prioridad senior que se evalúa:** Distinguir formato válido de semántica compatible.

S35. 🟠 En E5, ¿qué harías antes de retirar el campo antiguo?

## 📏 Criterio de evaluación

Evalúa cada respuesta de 0 a 2 en cuatro dimensiones: evidencia separada de inferencia, garantía explícita, alternativa con coste y recuperación o revisión. Un 0 indica omisión; 1, mención sin aplicación; 2, decisión aplicada al caso. La suma orienta la práctica, no certifica seniority. Una contradicción de la garantía exige repetir el caso aunque el total sea alto.

## 📚 Preparación y contraste

Las definiciones y fuentes están en la [ruta del bloque](README.md). Contrasta después con el [solucionario](10-respuestas.md); una alternativa que conserve garantías y explique costes también puede ser válida.

---

[Índice del bloque](README.md) · [Índice general](../README.md)

**Anterior:** [08 — Desmontar un monolito distribuido](08-desmontar-un-monolito-distribuido.md).

**Siguiente:** [10 — Respuestas: Monolito distribuido](10-respuestas.md).
