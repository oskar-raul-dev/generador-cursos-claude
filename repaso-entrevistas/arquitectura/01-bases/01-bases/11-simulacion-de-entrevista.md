# 11 — Simulación de entrevista

> El examen del bloque. Cuarenta preguntas `S#` transversales que cruzan capítulos, más
> seis escenarios de diseño completos. Se contesta **en voz alta y cronometrado**: saber
> algo y saber decirlo bajo presión son dos habilidades distintas, y la entrevista mide
> la segunda.
> Asume leídos los capítulos [`01`](01-fundamentos-del-arquitecto.md) a
> [`10`](10-alta-disponibilidad-y-escalado.md).
>
> **Vigencia:** 2026-09-18.

---

## 1. 🎯 Cómo se usa este documento

```text
1. Cronómetro a 2 minutos por pregunta S#.
2. Se contesta EN VOZ ALTA, de pie si puedes. Grábate.
3. Solo después vas a `12-respuestas.md`.
4. Lo que no supiste decir en 2 minutos, aunque lo supieras, cuenta como fallo.
```

> **Regla:** el objetivo no es acertar. Es detectar **qué sabes pero no puedes
> articular**, que es lo que se pierde en una entrevista real.

Los escenarios de diseño se trabajan distinto: 15 minutos, con papel, dibujando. Su
solución **sí** está desarrollada en [`12`](12-respuestas.md), porque son ejemplos
resueltos y no autochequeo de memoria.

---

## 2. 🧠 Preguntas transversales

### Bloque A — Decisión y criterio

**S1.** Te dan un sistema y 45 minutos. ¿Cuáles son tus primeras tres preguntas, en
orden? 🟠

**S2.** ¿Cuál es la diferencia entre una decisión de arquitectura y una de diseño? 🟡

**S3.** Ordena de más caro a más barato de revertir: elegir Kafka, elegir hexagonal,
elegir Postgres, elegir microservicios. Justifica el primero y el último. 🟠

**S4.** ¿Qué preguntas antes de responder "monolito o microservicios"? 🟠

**S5.** Tu propuesta técnica es mejor y el equipo la rechaza. ¿Qué haces? 🔴

**S6.** ¿Cómo justificas ante negocio una inversión que no añade funcionalidad? 🔴

**S7.** Te piden que estimes una migración que no has hecho nunca. ¿Cómo la abordas? 🔴

### Bloque B — Fronteras y modelo

**S8.** "¿Cómo dividirías este sistema en microservicios?" Da el método, no la lista. 🟠

**S9.** ¿Por qué el contexto acotado y no la capacidad técnica define la frontera? 🟠

**S10.** ¿Qué relación hay entre la ley de Conway y tu corte de servicios? 🟠

**S11.** Un servicio abarca dos contextos acotados. ¿Qué síntomas verás? 🟠

**S12.** ¿Cuándo hexagonal no se justifica? 🟠

**S13.** ¿Qué es un monolito distribuido y cómo lo reconoces en un sistema real? 🟠

**S14.** Te piden un modelo canónico de "cliente" para toda la empresa. Responde. 🔴

### Bloque C — Datos y consistencia

**S15.** ¿Qué significa que dos servicios sean "eventualmente consistentes" para el
    usuario final? 🟠

**S16.** ¿Por qué "base de datos por servicio" y qué pierdes con ello? 🟠

**S17.** ¿Cómo mantienes consistencia entre dos agregados sin transacción distribuida? 🟠

**S18.** ¿Qué es el outbox transaccional y qué problema exacto resuelve? 🟠

**S19.** ¿Por qué *exactly-once* no existe y qué se hace en su lugar? 🟠

**S20.** Tras un incidente aparecen cobros duplicados. ¿Qué faltaba? 🔴

### Bloque D — Fallo y operación

**S21.** ¿Por qué un servicio lento es peor que uno caído? 🟡

**S22.** ¿A quién protege un circuit breaker y de qué? 🟠

**S23.** Reintentas en tres capas con tres intentos. ¿Cuántas peticiones salen y qué
    provoca? 🟠

**S24.** ¿Por qué el jitter no es opcional? 🟠

**S25.** ¿Qué diferencia hay entre liveness y readiness, y qué pasa si los confundes? 🟠

**S26.** ¿Qué es el presupuesto de error y cómo cambia una discusión de prioridades? 🟠

**S27.** ¿Cuál es la pregunta que desmonta la mayoría de los planes de recuperación? 🟡

**S28.** Escalas a 50 instancias y el sistema empeora. Tres hipótesis ordenadas. 🔴

### Bloque E — Java y Spring en clave de arquitectura

**S29.** ¿Qué patrón implementa `@Transactional` y qué dos consecuencias tiene? 🟠

**S30.** ¿Por qué `@Transactional` no funciona en una llamada interna? 🟠

**S31.** ¿Qué es el problema N+1, cómo lo detectas y cómo lo arreglas bien? 🟠

**S32.** ¿Qué es OSIV, cómo viene en Spring Boot y qué harías con él? 🟠

**S33.** Nombra tres patrones GoF que no usarías hoy y justifica cada uno. 🟠

**S34.** ¿Por qué Spring Data JDBC modela agregados mejor que JPA? 🔴

**S35.** ¿Cómo verificas por test que nadie rompió la frontera del dominio? 🟠

### Bloque F — Las que descolocan

**S36.** "¿Qué opinas de la arquitectura hexagonal? Yo creo que es sobreingeniería."
    (El entrevistador te contradice a propósito.) 🔴

**S37.** ¿Cuál es la peor decisión de arquitectura que has tomado y qué aprendiste? 🔴

**S38.** ¿Qué harías en tus primeros 30 días como Tech Lead de un sistema que no
    conoces? 🔴

**S39.** ¿Cómo sabes que una arquitectura está funcionando? Da métricas concretas. 🔴

**S40.** Si tuvieras que eliminar una sola cosa de la arquitectura actual de tu último
    proyecto, ¿cuál y por qué? 🔴

---

## 3. 🏗️ Escenarios de diseño

Quince minutos cada uno, con papel. Cada escenario está elegido para **forzar una
frontera distinta**, y la solución desarrollada está en [`12`](12-respuestas.md).

### E1 — El que NO debe separarse

> Una aseguradora tiene un monolito de emisión de pólizas: cotización, suscripción,
> emisión y cobro de la primera cuota, todo en una transacción. 12 desarrolladores, un
> despliegue quincenal sin incidencias, 200 pólizas al día. El CTO nuevo quiere
> microservicios. Diseña tu respuesta.

**Fuerza:** saber decir que no, con números, sin sonar conservador.

### E2 — Consistencia distribuida inevitable

> Reserva de vuelo: asiento, equipaje y cobro viven en tres servicios con bases de datos
> distintas. Si el cobro falla, el asiento debe liberarse. No hay transacción
> distribuida. Diseña el flujo, incluidos los fallos parciales.

**Fuerza:** saga, compensación, idempotencia y qué ve el usuario mientras tanto.

### E3 — Lectura masiva

> Catálogo de un banco: 5.000 productos que cambian dos veces al día, consultados 40.000
> veces por segundo en el pico, desde app móvil y web. Latencia objetivo: 50 ms p99.
> Diseña.

**Fuerza:** caché, invalidación, CQRS, CDN y por qué la BD no es el problema.

### E4 — Escritura con picos

> Plataforma de pagos: 200 transacciones por segundo de media, 8.000 en el pico del día
> de cobro de nóminas, que dura 20 minutos. Cada transacción debe quedar registrada sin
> pérdida. Diseña.

**Fuerza:** encolar frente a escalar, durabilidad, backpressure y el límite del pool de
conexiones.

### E5 — Integración con un tercero poco fiable

> El scoring crediticio lo da un proveedor externo con SLA de 99 % —siete horas de caída
> al mes— y latencia p99 de 4 segundos. Tu proceso de originación no puede detenerse.
> Diseña la integración.

**Fuerza:** timeout, breaker, degradación con decisión de negocio, cola de revisión y
capa anticorrupción.

### E6 — Migración de un monolito existente

> Core bancario: monolito Java 8 de 800.000 líneas, base Oracle con 1.200 tablas y
> lógica en procedimientos almacenados, 6 equipos, despliegue mensual con ventana de
> 4 horas, cero tolerancia a pérdida de datos. Diseña la modernización de los próximos
> 18 meses.

**Fuerza:** Strangler Fig, capa anticorrupción, expand/contract, orden de corte y cómo se
mide el avance.

---

## 4. 🎤 Las tres frases que hay que tener listas

No son trucos: son las que resumen todo el bloque y sirven de ancla cuando te quedas en
blanco.

> **Sobre elegir:** *"Yo iría por A; a cambio pago B, y B lo acoto con C. Si me equivoco,
> salir cuesta D."*

> **Sobre separar:** *"No separo un sistema, separo el módulo que duele, y mido antes y
> después."*

> **Sobre la complejidad:** *"El monolito modular es la respuesta correcta más veces de
> las que se admite, y separar se paga en latencia, consistencia, operación y dinero."*

---

**Anterior:** [`10` — Alta disponibilidad y escalado](10-alta-disponibilidad-y-escalado.md) ·
**Siguiente:** [`12` — Respuestas](12-respuestas.md) ·
**Relacionado:** [`README` — índice del bloque](README.md)
