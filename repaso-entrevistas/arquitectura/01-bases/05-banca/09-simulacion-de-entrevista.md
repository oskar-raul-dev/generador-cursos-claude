# 09 — Simulación de entrevista

> El examen del bloque, y el más cercano a una entrevista real de backend en banca: treinta y dos preguntas `S#`
> transversales y seis escenarios. Se contesta **en voz alta y cronometrado**.
> Asume leídos los capítulos [`01`](01-core-bancario-y-legado.md) a
> [`08`](08-idempotencia-y-conciliacion.md).
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

Los escenarios se trabajan con papel, 15 minutos, dibujando **qué pasa durante la ventana batch y
dónde se detecta un descuadre**. Su solución está en [`10`](10-respuestas.md).

---

## 2. 🧠 Preguntas transversales

### Bloque A — El core y su realidad

**S1.** ¿Qué es un core bancario y por qué no se toca? 🟡

**S2.** ¿Qué es la ventana batch y qué pasa si no termina? 🟡

**S3.** ¿Qué diferencia hay entre saldo contable, disponible y en tránsito? 🟡

**S4.** ¿Qué tres fechas distingue una operación bancaria? 🟡

**S5.** ¿Cómo se moderniza un core sin sustituirlo? 🟠

**S6.** ¿Cómo resolvió la banca la consistencia eventual antes de que existiera
el término? 🟠

### Bloque B — Integración

**S7.** ¿Qué da MQ que Kafka no da, y al revés? 🟡

**S8.** ¿Por qué el estado de una petición request-reply no puede vivir en
memoria? 🟠

**S9.** ¿Qué costaba XA y qué se usa hoy en su lugar? 🟠

**S10.** ¿Qué tres estados tiene una petición asíncrona y por qué el tercero
define el diseño? 🟠

**S11.** ¿Qué cuatro cosas traduce una capa anticorrupción? 🟡

**S12.** ¿Cuáles son las dos señales de que una ACL funciona? 🟠

### Bloque C — Batch

**S13.** ¿Qué diferencia hay entre retry, skip y restart? 🟡

**S14.** ¿Por qué un proceso batch se diseña asumiendo que se va a caer? 🟠

**S15.** ¿Por qué usar `now()` en vez del parámetro de fecha rompe el
reproceso? 🟠

**S16.** ¿Qué trampa tiene paralelizar con multi-hilo? 🟠

**S17.** ¿Qué es un `Step` de cuadre y por qué es obligatorio? 🟡

### Bloque D — Formatos y normativa

**S18.** ¿Qué es ISO 20022 y qué aporta frente a MT? 🟡

**S19.** ¿Qué diferencia hay entre `pain` y `pacs`? 🟢

**S20.** ¿Qué es el truncamiento y por qué hace cara la migración? 🟠

**S21.** ¿Qué diferencia hay entre autorización y liquidación de tarjeta? 🟡

**S22.** ¿Qué son AISP, PISP y ASPSP? 🟢

**S23.** ¿Por qué el consentimiento no es un booleano? 🟠

**S24.** ¿Por qué los pagos instantáneos rompen el modelo de ventana batch? 🟠

### Bloque E — Integridad

**S25.** ¿Qué es la partida doble y qué invariante permite comprobar? 🟡

**S26.** ¿Por qué no se modifica un movimiento erróneo? 🟠

**S27.** ¿De dónde sale la clave de idempotencia en un pago? 🟡

**S28.** ¿Qué haces ante un timeout sin respuesta del core? 🟠

**S29.** ¿Por qué el corte temporal es crítico en una conciliación? 🟠

### Bloque F — Las que descolocan

**S30.** "Vamos a migrar el core a microservicios." Responde. 🔴

**S31.** ¿Cuál es el peor incidente que has visto en un sistema financiero y
qué faltaba? 🔴

**S32.** ¿Cómo le explicas a un desarrollador que viene de producto por qué
aquí nada se borra? 🔴

---

## 3. 🏗️ Escenarios de diseño

### E1 — La app móvil contra un core que cierra

> Banca móvil, 2 millones de usuarios, pico de 4.000 consultas de saldo por segundo. El core cobra
> por transacción, cierra de 23:00 a 03:00 para el batch, y su API tiene un p99 de 800 ms. Diseña la
> consulta de saldo y el comportamiento durante la ventana.

**Fuerza:** proyección de lectura, saldo disponible contra contable, modo degradado explícito, y el
argumento económico de la caché.

### E2 — La transferencia que no se sabe si se hizo

> Tu servicio ordena transferencias al core por MQ, con respuesta diferida de hasta 5 minutos. Ayer
> hubo un incidente de red y 340 peticiones quedaron sin respuesta. Nadie sabe cuáles se ejecutaron.
> Diseña el sistema para que esto sea un caso previsto y describe cómo resuelves las 340.

**Fuerza:** los tres estados, idempotencia con clave de negocio, conciliación, y no reintentar a
ciegas.

### E3 — El cierre que no cabe

> El proceso de devengo de intereses tarda 2 horas sobre 8 millones de cuentas y la ventana es de 4.
> Con el crecimiento previsto, en seis meses tardará 5. No se puede ampliar la ventana. Diseña.

**Fuerza:** medir antes de paralelizar, particionado, reinicio, cuadre, y saber que el cuello no
suele ser la CPU.

### E4 — Open Banking sobre un legado

> Un banco mediano debe exponer APIs de Open Banking según Berlin Group. El core cierra 4 horas cada
> noche, cobra por transacción, y su API tiene un p99 de 800 ms. La normativa exige disponibilidad
> comparable a los canales propios y publica las métricas. Diseña.

**Fuerza:** consentimiento como entidad, proyección de lectura, cuotas por TPP, modo degradado, y
reconocer que la disponibilidad es una obligación.

### E5 — El descuadre

> Contabilidad reporta que durante tres días hubo una diferencia de entre 3 y 11 operaciones diarias
> entre tu sistema de pagos y el core. Nadie sabe desde cuándo pasa. Diseña la investigación, la
> corrección y lo que habría que haber tenido.

**Fuerza:** conciliación, corte temporal, contra-asiento, pista de auditoría y separación de deberes.

### E6 — El cierre que NO hay que volver tiempo real

> Un director de tecnología llega de una fintech y plantea eliminar el cierre contable nocturno:
> que cada movimiento se contabilice en el momento, con eventos, y que el saldo contable se calcule
> en continuo. El argumento es que el batch es legado y que "en tiempo real no hay ventana que se
> caiga". Contabilidad y el área regulatoria están en la reunión. Responde.

**Fuerza:** distinguir la limitación técnica de la obligación contable, y saber que el corte temporal
no es un defecto del batch sino su razón de ser.

---

## 4. 🎤 Las tres frases que hay que tener listas

> **Sobre el core:** *"no se sustituye, se rodea. Las lecturas primero, con proyección propia; las
> escrituras siguen ordenándose contra él."*

> **Sobre la integridad:** *"en banca la consistencia no la garantiza el transporte, la garantiza la
> conciliación. Todo lo demás reduce la frecuencia de los descuadres."*

> **Sobre el dato:** *"aquí no se borra ni se modifica: se emite un contra-asiento. El libro es la
> evidencia, y la evidencia no se edita."*

---

**Anterior:** [`08` — Idempotencia y conciliación](08-idempotencia-y-conciliacion.md) ·
**Siguiente:** [`10` — Respuestas](10-respuestas.md) ·
**Relacionado:** [`README` — índice del bloque](README.md)
