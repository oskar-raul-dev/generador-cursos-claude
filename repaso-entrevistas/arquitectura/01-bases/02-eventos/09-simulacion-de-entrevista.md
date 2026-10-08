# 09 — Simulación de entrevista

> El examen del bloque. Treinta y seis preguntas `S#` transversales que cruzan capítulos,
> más cinco escenarios de diseño. Se contesta **en voz alta y cronometrado**: saber algo y
> saber decirlo bajo presión son dos habilidades distintas.
> Asume leídos los capítulos [`01`](01-fundamentos-eda.md) a
> [`08`](08-proyecciones-y-streaming.md).
>
> **Vigencia:** 2026-09-18.

---

## 1. 🎯 Cómo se usa este documento

```text
1. Cronómetro a 2 minutos por pregunta S#.
2. Se contesta EN VOZ ALTA. Grábate.
3. Solo después vas a `10-respuestas.md`.
4. Lo que no supiste decir en 2 minutos, aunque lo supieras, cuenta como fallo.
```

Los escenarios se trabajan distinto: 15 minutos, con papel, dibujando el flujo de eventos y
marcando **dónde puede fallar**. Su solución está desarrollada en
[`10`](10-respuestas.md).

---

## 2. 🧠 Preguntas transversales

### Bloque A — Vocabulario y fronteras

**S1.** ¿Qué diferencia a un comando de un evento, y por qué importa? 🟡

**S2.** ¿Qué es un evento de integración y en qué se diferencia del de dominio? 🟡

**S3.** ¿Por qué mandar comandos por Kafka no convierte tu sistema en EDA? 🟠

**S4.** Un sistema publica sus entidades JPA como eventos. ¿Qué diagnosticas? 🟠

**S5.** ¿Qué gana y qué pierde una arquitectura dirigida por eventos? 🟠

**S6.** ¿Cuándo NO usarías eventos, teniendo broker disponible? 🟠

### Bloque B — Transporte

**S7.** ¿Cuál es la diferencia estructural entre una cola y un log? 🟢

**S8.** ¿Qué limita el paralelismo de un grupo de consumidores? 🟡

**S9.** ¿Por qué SNS sin SQS detrás pierde mensajes? 🟡

**S10.** ¿Cuándo eliges RabbitMQ sobre Kafka? 🟠

**S11.** Necesitas que un consumidor nuevo procese seis meses de histórico.
¿Qué exige eso del transporte? 🟠

**S12.** ¿Cuándo no usarías ningún broker? 🟠

### Bloque C — Garantías

**S13.** ¿Por qué *exactly-once* no existe de extremo a extremo? 🟠

**S14.** ¿Qué es *effectively-once* y cómo se consigue? 🟡

**S15.** ¿Qué línea de tu código decide la garantía de entrega? 🟠

**S16.** Nombra las cuatro formas de conseguir idempotencia, de mejor a peor. 🟡

**S17.** ¿Por qué la deduplicación debe ser atómica con el efecto? 🟠

**S18.** ¿Cómo se consigue orden y qué cuesta? 🟠

**S19.** ¿Cómo diseñas un consumidor que no necesite orden? 🟠

### Bloque D — Fallos

**S20.** ¿Qué es un mensaje envenenado y por qué es peor en Kafka? 🟠

**S21.** ¿Cómo distingues un fallo transitorio de uno permanente, y qué haces
con cada uno? 🟠

**S22.** ¿Qué cuatro cosas necesita una DLQ para no ser un vertedero? 🟡

**S23.** ¿Qué precio oculto tienen los retry topics de Kafka? 🟠

**S24.** El lag sube en una sola partición. ¿Qué diagnosticas? 🔴

### Bloque E — Consistencia

**S25.** ¿Qué es el problema de la doble escritura? 🟡

**S26.** ¿Qué garantiza el outbox y qué **no** garantiza? 🟠

**S27.** ¿Por qué CDC sobre tablas de negocio es un antipatrón para integrar? 🟠

**S28.** ¿Qué es una saga y por qué no se usa 2PC? 🟡

**S29.** ¿Cuándo orquestación y cuándo coreografía? 🟠

**S30.** ¿Por qué toda reserva de una saga necesita TTL? 🟠

**S31.** ¿Qué es el pivote de una saga y cómo ordena los pasos? 🟠

### Bloque F — Las que descolocan

**S32.** "Nosotros hacemos event sourcing porque publicamos eventos." Corrige sin
quedar como el listo. 🔴

**S33.** Te piden event sourcing para todo un sistema nuevo. ¿Qué respondes? 🔴

**S34.** ¿Cuál es el peor incidente que has visto en un sistema por eventos, y
qué faltaba? 🔴

**S35.** Si tuvieras que quitar una pieza de una arquitectura por eventos
típica, ¿cuál y por qué? 🔴

**S36.** ¿Cómo le explicas a negocio que la factura tarda 30 segundos en
aparecer? 🔴

---

## 3. 🏗️ Escenarios de diseño

Quince minutos cada uno, con papel. Cada escenario fuerza un problema distinto, y la
solución desarrollada está en [`10`](10-respuestas.md).

### E1 — El que NO necesita broker

> Un ERP interno de una empresa de 200 empleados procesa 300 órdenes de compra al día.
> Cuando se aprueba una orden hay que notificar a contabilidad y actualizar un panel. El
> equipo —cuatro personas— quiere montar Kafka. Diseña tu respuesta.

**Fuerza:** saber decir que no, con números, y proponer lo aburrido que funciona.

### E2 — Doble escritura en producción

> Un servicio de pedidos confirma en su base de datos y publica a Kafka en el mismo método.
> Una vez por semana, facturación no recibe un evento y hay un pedido sin factura. Nadie
> sabe cuántos se han perdido. Diagnostica y diseña la solución completa.

**Fuerza:** outbox, el modo de fallo silencioso, y cómo se recupera lo ya perdido.

### E3 — Consistencia entre servicios

> Reserva de vuelo: asiento, equipaje y cobro en tres servicios con bases de datos
> distintas. Si el cobro falla, hay que liberar lo reservado. El usuario espera en la
> pantalla. Diseña el flujo completo, incluidos los fallos parciales y lo que ve el usuario.

**Fuerza:** saga, compensación, pivote, TTL e idempotencia, todo junto.

### E4 — Reprocesar sin romper

> Hay un bug en la proyección de "estado del pedido": lleva tres semanas marcando mal los
> pedidos parcialmente enviados. Hay 40 millones de eventos en el topic, retención de 30
> días, y la proyección alimenta la app móvil de 2 millones de usuarios. Diseña la
> corrección.

**Fuerza:** reconstrucción en paralelo, verificación, cambio atómico y el límite de la
retención.

### E5 — Migración de síncrono a eventos

> Un monolito de e-commerce confirma pedidos llamando síncronamente a inventario,
> facturación, envíos, notificaciones y analítica. La confirmación tarda 4 segundos y falla
> el 2 % de las veces porque alguna dependencia está caída. No se puede parar el negocio.
> Diseña la migración.

**Fuerza:** qué se desacopla primero, qué sigue siendo síncrono, y cómo convives con las
dos formas a la vez.

---

## 4. 🎤 Las tres frases que hay que tener listas

> **Sobre garantías:** *"at-least-once más idempotencia en el consumidor. Exactly-once no
> existe en cuanto el efecto sale del broker."*

> **Sobre consistencia:** *"outbox para no perder el evento, inbox o clave de idempotencia
> para no duplicarlo. Eso es lo que sustituyó a XA."*

> **Sobre el precio:** *"EDA no simplifica el sistema, lo reparte: cambias acoplamiento por
> consistencia eventual y por peor depurabilidad."*

---

**Anterior:** [`08` — Proyecciones y streaming](08-proyecciones-y-streaming.md) ·
**Siguiente:** [`10` — Respuestas](10-respuestas.md) ·
**Relacionado:** [`README` — índice del bloque](README.md)
