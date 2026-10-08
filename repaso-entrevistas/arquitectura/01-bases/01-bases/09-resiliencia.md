# 09 — Resiliencia

> Cómo se diseña un sistema para que el fallo de una parte no sea el fallo del todo.
> Timeout, reintento con jitter, circuit breaker, bulkhead, degradación y backpressure —
> y la sección que más rinde: **los antipatrones**, porque casi todos los ha cometido
> quien te entrevista.
> Asume leído [`08` — Comunicación e integración](08-comunicacion-e-integracion.md).
>
> **Vigencia:** 2026-09-18.

---

## 1. 🎯 El problema

Un servicio de catálogo se pone lento: responde en 30 segundos en vez de 50 ms. No está
caído, solo lento. Y en quince minutos **toda la plataforma está caída**.

La cadena, que conviene saber narrar entera porque es la mejor respuesta a "cuéntame un
incidente":

```text
1. Catálogo tarda 30 s (no falla: tarda)
2. Los hilos de pedidos se quedan esperando  → el pool se agota
3. Pedidos deja de responder a TODO, no solo a lo que usaba catálogo
4. El balanceador marca pedidos como no sano y lo saca
5. La carga va a las instancias restantes, que se agotan igual
6. Efecto dominó: cae la plataforma por un servicio secundario que nunca se cayó
```

> **Regla importante:** en distribuido, **la lentitud es peor que la caída**. Un servicio
> caído falla rápido y lo gestionas; un servicio lento consume tus recursos hasta
> agotarlos.

Todo este capítulo existe para romper esa cadena en el paso 1 o el 2.

---

## 2. ⏲️ Timeout

**Qué es.** El tiempo máximo que esperas. Es **la primera línea de defensa** y la que
casi nadie configura, porque los valores por defecto de muchos clientes HTTP son
"infinito".

**Los dos que hay que distinguir**, porque se pregunta:

```text
connect timeout → cuánto esperas a establecer la conexión   (bajo: 1–2 s)
read timeout    → cuánto esperas la respuesta completa       (según el caso de uso)
```

**Cómo se elige el valor.** No a ojo: **desde el p99 del servicio llamado**, más margen.
Si el p99 es 200 ms, un timeout de 1 s es razonable; uno de 30 s significa que aceptas
tener un hilo bloqueado 30 segundos.

> ⚠️ **Advertencia.** La regla que más se incumple: **tu timeout debe ser menor que el de
> quien te llama**. Si el cliente espera 2 s y tú esperas 5 s a tu dependencia, cuando
> respondas ya nadie escucha: has consumido recursos para producir una respuesta que se
> descarta.

> **Veredicto:** sin timeout, ningún otro patrón de este capítulo funciona. El circuit
> breaker no puede abrirse si la llamada nunca termina.

---

## 3. 🔁 Reintento con backoff exponencial y jitter

**Qué es.** Volver a intentar, esperando cada vez más, **con un componente aleatorio**.

```text
Sin backoff:   1s, 1s, 1s, 1s          → machacas al que ya está mal
Con backoff:   1s, 2s, 4s, 8s          → le das margen a recuperarse
Con jitter:    0.7s, 2.3s, 3.1s, 9.4s  → además, no llegan todos a la vez
```

**Por qué el jitter no es opcional.** Si mil clientes fallan en el mismo instante y todos
reintentan a 1 s, 2 s y 4 s, produces tres picos sincronizados de mil peticiones contra
un servicio que se estaba recuperando. Es el **thundering herd**, y sin jitter el
reintento **empeora** la caída en vez de mitigarla.

**Lo que hay que fijar siempre:** un número máximo de intentos y un presupuesto total. Un
reintento infinito no es resiliencia, es una negación de servicio que te haces a ti mismo.

> ⚠️ **Advertencia.** **Solo se reintenta lo idempotente.** Reintentar un `POST` de pago
> sin clave de idempotencia cobra dos veces. Es el enlace directo con
> [`08` §7](08-comunicacion-e-integracion.md#7--idempotencia): la idempotencia no es un
> detalle de la mensajería, es el permiso para reintentar.

> **Veredicto:** el reintento es el patrón que más daño hace mal implementado. Sin backoff machacas, sin
> jitter sincronizas, sin límite te niegas el servicio a ti mismo, y sin idempotencia
> duplicas.

---
## 4. 🔌 Circuit breaker

**Qué es.** Un interruptor que **deja de llamar** a una dependencia que está fallando, y
falla rápido en su lugar. Deja de gastar hilos y de castigar a quien está caído.

**Los tres estados**, que son pregunta garantizada:

```text
CERRADO (closed)      → pasa todo. Cuenta fallos.
   ↓ supera el umbral
ABIERTO (open)        → no pasa nada. Falla inmediato. Espera un tiempo.
   ↓ pasado el tiempo
SEMIABIERTO (half-open)→ deja pasar unas pocas. ¿Van bien? → CERRADO. ¿Fallan? → ABIERTO.
```

- El estado **semiabierto** es el que da la respuesta completa: sin él, el interruptor no
  sabría cuándo volver, o volvería de golpe con toda la carga.
- El umbral moderno no es "5 fallos seguidos" sino **porcentaje de fallos sobre una
  ventana** (deslizante por conteo o por tiempo), que es como lo hace Resilience4j.

**Cuándo sí.** Dependencias remotas que pueden degradarse, sobre todo si son de terceros.

**Cuándo no.** Dependencias sin las que no puedes operar de ninguna forma: abrir el
interruptor contra tu única base de datos solo convierte una caída en otra caída, más
rápida. Ahí lo que quieres es timeout y bulkhead.

> ⚠️ **Advertencia.** El antipatrón: poner el circuit breaker **protegiendo a quien no
> debía**. Se protege al **llamante** de que el llamado le consuma los recursos. Si lo
> pones para "no sobrecargar al de abajo", lo que necesitas es rate limiting.

> **Veredicto:** es el patrón más nombrado y el peor entendido de la lista. Si sabes decir a quién
> protege y cuándo no aporta, ya estás por delante de la mayoría.

---
## 5. 🧱 Bulkhead

**Qué es.** Del casco de un barco: compartimentos estancos. Aísla recursos por
dependencia, de modo que agotar uno no agote el resto.

Concretamente: **un pool de hilos o un semáforo por dependencia**. Si catálogo se lleva
sus 10 hilos, le quedan los 40 de las demás. La cadena del §1 se rompe en el paso 2.

**Dónde aparece a otra escala.** El mismo principio, en niveles distintos:

```text
Hilos        → un pool por dependencia
Instancias   → separar el tráfico crítico del no crítico
Celdas       → clientes repartidos en celdas aisladas (cell-based)
```

> **Veredicto:** bulkhead es lo que convierte un fallo total en un fallo parcial. Es el
> patrón que más se olvida y el que ataca directamente el efecto dominó.

---

## 6. 🪂 Degradación elegante

**Qué es.** Responder peor en vez de no responder. Requiere decidir **de antemano** qué
es prescindible.

```text
Recomendaciones caídas   → muestra los más vendidos (caché estático)
Servicio de fotos caído  → imagen de marcador de posición
Scoring de riesgo caído  → regla conservadora local, o cola para revisión manual
Saldo en tiempo real     → NO degrada: aquí se falla explícito
```

- La última línea importa: **no todo debe degradar**. En banca, dar un dato financiero
  desactualizado sin avisar es peor que dar un error.
- La decisión de qué degrada es **de negocio**, no técnica. Llevarla a negocio y volver
  con la lista es la respuesta de arquitecto.

> **Veredicto:** la degradación es la única parte de este capítulo que no puedes decidir solo. Llevar la
> lista a negocio y volver con ella firmada **es** la respuesta de arquitecto.

---
## 7. 🚦 Rate limiting y backpressure

**Rate limiting** es protección **hacia fuera**: limitas cuántas peticiones aceptas, para
no caer. Los dos algoritmos que conviene nombrar:

- **Token bucket**: admite ráfagas hasta el tamaño del cubo. Es el que quieres casi
  siempre.
- **Leaky bucket**: alisa la salida a tasa constante, sin ráfagas.

**Backpressure** es protección **hacia atrás**: el consumidor le dice al productor que
vaya más despacio. Es lo que `Flow`/Reactive Streams formaliza en Java, y lo que hace un
consumidor de Kafka cuando deja de pedir más registros.

> 🧠 **Modelo mental.** Rate limiting rechaza lo que sobra; backpressure pide que no lo
> manden. El primero protege un servicio; el segundo protege una tubería.

> **Veredicto:** el rate limiting lo pones tú solo; el backpressure exige que el protocolo y el
> productor cooperen. Por eso con HTTP clásico solo tienes la mitad.

---
## 8. 🩺 Cómo se detecta que falta resiliencia

El ángulo de diagnóstico, que es lo que distingue al que lo ha vivido:

| Síntoma | Qué falta probablemente |
|---|---|
| Un servicio lento tumba a otros | Timeout y bulkhead |
| Picos sincronizados tras una caída | Jitter en el reintento |
| La caída se recupera sola y vuelve a caer | Reintento sin límite, o semiabierto mal calibrado |
| Duplicados tras un incidente | Reintento sobre operación no idempotente |
| El pool de hilos agotado sin tráfico alto | Timeout infinito en alguna dependencia |
| Un incidente en un cliente afecta a todos | Falta aislamiento por celda o por tenant |

---

## 9. 🪦 Antipatrones

La sección que más rinde en entrevista, porque son errores reales:

- **Reintentar lo no idempotente.** Duplicas cobros. El enlace con idempotencia es
  obligatorio.
- **Reintentar en cada capa.** Tres capas con tres reintentos son **27 peticiones** por
  una del usuario. El efecto multiplicador convierte un problema pequeño en una caída.
  La regla: **se reintenta en un solo nivel**, normalmente el más cercano al fallo.
- **Timeout mayor que el de quien te llama.** Trabajas para nadie.
- **Circuit breaker protegiendo a quien no debía.** Ver §4.
- **Reintento infinito.** Autodenegación de servicio.
- **Fallback que oculta el error.** Devolver lista vacía cuando el servicio falla
  convierte un incidente visible en datos incorrectos silenciosos. Si degradas, **el
  fallback se registra y se mide**.
- **Health check que solo dice "el proceso vive".** Si el endpoint de salud no comprueba
  las dependencias críticas, el balanceador manda tráfico a una instancia inútil. Y el
  error inverso: un health check que comprueba dependencias externas y saca de servicio
  toda tu flota porque un tercero se cayó.

> 💡 **Truco.** Nombrar el **efecto multiplicador del reintento en capas** con el número
> —"tres por tres por tres son veintisiete"— es de las cosas que más rápido te sitúan
> como alguien que ha operado sistemas, no solo diseñado.

---

## 10. 🧭 Cómo se elige: en qué orden se aplica

Estos patrones no son alternativas entre sí, son capas — y el orden importa, porque cada
uno depende del anterior:

```text
1. Timeout      → PRIMERO Y SIEMPRE. Sin él nada de lo demás funciona:
                  el breaker no puede abrirse si la llamada nunca termina.
2. Bulkhead     → aísla el daño. Es lo que convierte un fallo total en uno parcial.
3. Reintento    → solo si la operación es idempotente. Con backoff, jitter y tope.
4. Breaker      → solo si hay algo que hacer con el fallo: degradar, encolar o avisar.
                  Contra tu única base de datos no aporta nada.
5. Degradación  → la decide negocio, no tú. Y nunca sobre cifras financieras.
```

Y la pregunta que ordena la conversación entera cuando te piden "hazlo resiliente":

> **Regla de entrevista:** *"¿qué quieres que pase cuando esta dependencia no responda?"*.
> Si la respuesta es "que falle", te sobran patrones y te falta un timeout. Si es "que
> siga", la conversación ya es de negocio y no de arquitectura.

---

## ⚠️ Errores frecuentes

| Se dice | Lo preciso |
|---|---|
| "Reintento y ya" | Sin backoff machacas; sin jitter sincronizas; sin idempotencia duplicas |
| "El circuit breaker protege al servicio caído" | Protege al **llamante** de agotar sus recursos |
| "Un servicio caído es lo peor" | Lo peor es uno lento: consume tus hilos sin fallar |
| "Timeout de 30 s por si acaso" | Es un hilo bloqueado 30 s; se calcula desde el p99 |
| "El fallback devuelve vacío" | Oculta el incidente; si degradas, se registra y se mide |
| "Health check = el proceso responde" | Debe cubrir dependencias críticas, y solo las críticas |

---

## 📚 Para profundizar

- **Libro** — Michael Nygard, *Release It!*, 2ª ed. (Pragmatic Bookshelf, 2018).
  Capítulos 4 y 5: *Stability Antipatterns* y *Stability Patterns*. **Es el libro de este
  capítulo**; circuit breaker y bulkhead se popularizan aquí.
- **Libro** — Sam Newman, *Building Microservices*, 2ª ed. (O'Reilly, 2021). Capítulo 12:
  resiliencia aplicada a microservicios.
- **Libro** — Betsy Beyer et al., *Site Reliability Engineering* (O'Reilly, 2016).
  Capítulos 21–22: gestión de sobrecarga y fallos en cascada, con el análisis del
  thundering herd.
- Martin Fowler — [CircuitBreaker](https://martinfowler.com/bliki/CircuitBreaker.html):
  la explicación canónica con los tres estados.
- [Amazon Builders' Library — Timeouts, retries, and backoff with jitter](https://aws.amazon.com/builders-library/timeouts-retries-and-backoff-with-jitter/):
  el artículo con los números de por qué el jitter importa.
- [Resilience4j — Getting started](https://resilience4j.readme.io/docs/getting-started):
  la implementación en Java, con circuit breaker, bulkhead, retry y rate limiter.
- **Tutorial** — Baeldung, «Guide to Resilience4j»:
  el aterrizaje en Spring Boot, con configuración por dependencia.
- **Video** — GOTO Conferences, charlas de Michael Nygard sobre estabilidad en
  producción. Búscalas por título.

---

## 🧠 Preguntas

Sin respuestas aquí. Todas, con enunciado literal y respuesta en tres capas, en
[`12` — Respuestas](12-respuestas.md).

1. ¿Cuáles son los tres estados de un circuit breaker? 🟢
2. ¿Qué es el bulkhead y de dónde viene el nombre? 🟢
3. ¿Qué diferencia hay entre connect timeout y read timeout? 🟢
4. ¿Por qué un servicio lento es peor que uno caído? 🟡
5. ¿Para qué sirve el estado semiabierto? 🟡
6. ¿Qué es el thundering herd? 🟡
7. ¿Qué requisito debe cumplir una operación para poder reintentarse? 🟡
8. ¿Qué diferencia hay entre rate limiting y backpressure? 🟡
9. ¿Qué diferencia hay entre token bucket y leaky bucket? 🟡
10. ¿Por qué el jitter no es opcional en un reintento? 🟠
11. ¿A quién protege un circuit breaker? 🟠
12. ¿Cómo se calcula el valor de un timeout? 🟠
13. ¿Por qué tu timeout debe ser menor que el de quien te llama? 🟠
14. Reintentar en tres capas con tres intentos: ¿cuántas peticiones salen? 🟠
15. ¿Cuándo NO debe degradar un servicio? 🟠
16. ¿Qué problema tiene un fallback que devuelve lista vacía? 🟠
17. ¿Qué debe y qué no debe comprobar un health check? 🟠
18. ¿Cuándo un circuit breaker no aporta nada? 🟠
19. Narra la cadena completa por la que un servicio secundario lento tumba una
    plataforma, y di dónde la cortarías. 🔴
20. Tras cada incidente el sistema se recupera y vuelve a caer en ciclos. ¿Qué
    diagnosticas? 🔴
21. Diseña la resiliencia de una llamada a un scoring externo poco fiable:
    timeout, reintento, breaker, fallback, con valores concretos. 🔴
22. Tras un incidente aparecen cobros duplicados. Reconstruye qué pasó y qué
    faltaba. 🔴

---

**Anterior:** [`08` — Comunicación e integración](08-comunicacion-e-integracion.md) ·
**Siguiente:** [`10` — Alta disponibilidad y escalado](10-alta-disponibilidad-y-escalado.md) ·
**Relacionado:** [`02-eventos/04` — Colas, DLQ y reintentos](../02-eventos/04-colas-dlq-y-reintentos.md)
