# 04 — Colas, DLQ y reintentos

> Qué haces con el mensaje que no se puede procesar. Reintento con retardo, mensaje
> envenenado, cola de mensajes muertos y el proceso humano que la acompaña — porque una DLQ
> sin proceso es un vertedero.
> Asume leído [`03` — Garantías, orden e idempotencia](03-garantias-orden-e-idempotencia.md).
>
> **Vigencia:** 2026-09-18.

---

## 1. 🎯 El problema

Un mensaje llega mal formado. El consumidor lanza excepción, no confirma, y el broker lo
vuelve a entregar. El consumidor lanza excepción otra vez. Y otra.

```text
mensaje malo → excepción → sin ack → reentrega → excepción → sin ack → reentrega → ∞
```

Tres cosas están pasando a la vez, y conviene separarlas porque tienen soluciones
distintas:

- **El mensaje nunca va a funcionar.** Reintentarlo mil veces no lo arregla.
- **Está bloqueando la partición o la cola.** En Kafka, con orden por clave, el consumidor
  no puede avanzar: los mensajes buenos detrás esperan a uno que nunca pasará.
- **Está consumiendo tu presupuesto de reintentos** y llenando los logs, así que tapa los
  fallos reales.

> **Regla:** antes de decidir qué haces con un fallo, decide **de qué tipo es**. Un fallo
> transitorio y uno permanente se parecen en el log y no se parecen en nada más.

---

## 2. 🔀 Los dos tipos de fallo

**Qué es.** La clasificación que ordena todo el capítulo, y lo primero que hay que decir
cuando preguntan por reintentos.

| | Transitorio | Permanente |
|---|---|---|
| Ejemplo | Timeout, 503, deadlock, conexión caída | JSON inválido, campo obligatorio ausente, referencia a algo que no existe |
| ¿Reintentar ayuda? | ✅ Sí, es exactamente para esto | ❌ Nunca. Fallará igual dentro de una hora |
| Destino | Reintento con retardo | DLQ directa, sin gastar reintentos |
| Quién lo arregla | El tiempo | Una persona, o un despliegue |

- **La regla práctica:** si el fallo es una excepción de validación o de deserialización,
  es permanente. Si es de red, de tiempo o de recurso ocupado, es transitorio.
- En Spring Kafka esto se declara: las excepciones no reintentables se listan y van directas
  a la DLQ.

**Cuándo sí distinguirlos.** Siempre. Es lo que evita gastar seis reintentos en un mensaje
que no tiene arreglo.

**Cuándo no.** Si no puedes clasificar con confianza, trata el fallo como transitorio con
un tope bajo. Es el error menos caro de los dos.

> **Veredicto:** reintentar un fallo permanente no es resiliencia, es ruido caro. Y
> mandar a la DLQ un fallo transitorio es perder trabajo que se habría recuperado solo.

---

## 3. ⏳ Reintento con retardo

**Qué es.** Volver a intentar más tarde, sin bloquear el consumo mientras tanto. Y aquí
está la diferencia entre hacerlo bien y hacerlo mal:

```text
MAL:  Thread.sleep(5000) dentro del consumidor
      → bloqueas el hilo, el consumidor no hace nada más, y en Kafka
        el broker puede expulsarte del grupo por no responder al heartbeat.

BIEN: devolver el mensaje al transporte con un retardo, y seguir consumiendo.
```

**Cómo se implementa en cada broker**, porque la respuesta cambia:

- **RabbitMQ**: cola con TTL cuyo dead-letter-exchange apunta a la cola original. El
  mensaje "duerme" en una cola de retardo y vuelve solo. Es el mecanismo más limpio de los
  tres.
- **SQS**: `visibility timeout` extendido, o `DelaySeconds` al reencolar.
- **Kafka**: no tiene retardo nativo. El patrón es **topics de reintento escalonados**:
  `pedidos.retry.5s`, `pedidos.retry.1m`, `pedidos.retry.10m`, y finalmente `pedidos.dlt`.
  Spring Kafka lo genera con `@RetryableTopic`.

**Lo que hay que fijar siempre**, y es lo mismo que en [`01-bases/09`](../01-bases/09-resiliencia.md):
backoff exponencial, **jitter**, y un tope de intentos. Un reintento infinito no es
resiliencia, es una negación de servicio que te haces a ti mismo.

**Cuándo sí.** Fallos transitorios, siempre que la operación sea idempotente.

**Cuándo no.** Fallos permanentes, y operaciones no idempotentes sin clave de idempotencia:
ahí reintentar duplica.

> ⚠️ **Advertencia.** Los topics de reintento de Kafka **rompen el orden**: un mensaje que
> se desvía a `retry.1m` vuelve un minuto después, detrás de los que llegaron mientras
> tanto. Si tu consumidor dependía del orden por clave, ya no puedes dar esa garantía. Es
> el precio oculto del patrón y hay que decirlo.

> **Veredicto:** el reintento con retardo compra tiempo a costa de orden. Si necesitas
> ambos, la salida es parar el consumo de esa partición, no desviar el mensaje.

---

## 4. ☠️ El mensaje envenenado

**Qué es.** El mensaje que falla siempre y bloquea todo lo que viene detrás. Es el caso
específico de un fallo permanente en un transporte que garantiza orden.

**Por qué es peor en Kafka que en una cola.** En SQS o RabbitMQ, un mensaje problemático se
reentrega mientras los demás siguen procesándose en paralelo. En Kafka, si el consumidor no
avanza el offset, **la partición entera se detiene**: el lag crece, los mensajes buenos
esperan, y una entidad puede bloquear a miles.

**Las tres salidas, con su precio:**

```text
1. Saltarlo (skip)      → avanzas el offset y lo mandas a la DLQ.
                          Precio: ese trabajo no se hizo. Alguien tiene que saberlo.
2. Parar el consumo     → alertas y un humano decide.
                          Precio: el lag crece. Correcto cuando saltarlo es inaceptable.
3. Desviar a retry/DLT  → sigues consumiendo, el mensaje se aparta.
                          Precio: pierdes el orden por clave (§3).
```

- La opción 1 es la habitual y la correcta **si y solo si** la DLQ tiene un proceso detrás.
- La opción 2 es la correcta en dominios donde perder un mensaje es inaceptable: pagos,
  contabilidad, regulatorio.
- Elegir entre ellas **es una decisión de negocio**, igual que la degradación de
  [`01-bases/09`](../01-bases/09-resiliencia.md).

**Cuándo sí saltar.** Proyecciones, cachés, analítica: si un evento se pierde, la vista se
reconstruye.

**Cuándo no.** Movimientos de dinero. Ahí se para y se avisa.

> 🩺 **Diagnóstico.** Un lag que crece en **una sola partición** mientras las demás van bien
> es la firma del mensaje envenenado. Si el lag crece en todas por igual, es capacidad.

> **Veredicto:** el mensaje envenenado no es un problema de infraestructura, es una
> pregunta de negocio disfrazada: *"¿prefieres perder este mensaje o parar la cola?"*.

---

## 5. 🗃️ La cola de mensajes muertos

**Qué es.** El destino de lo que no se pudo procesar tras agotar los reintentos. En SQS y
RabbitMQ es una cola aparte; en Kafka es un topic, normalmente `<topic>.dlt`.

**Lo que tiene que llevar cada mensaje para que la DLQ sirva de algo:**

```text
El mensaje original, intacto        → para poder reprocesarlo tal cual
La excepción y su stack trace       → para saber por qué falló
El topic/cola y el offset originales→ para localizarlo en el flujo
El número de intentos               → para distinguir "falló una vez" de "falló seis"
La marca de tiempo del último fallo → para medir antigüedad
El correlation ID                   → para atarlo a la traza distribuida
```

- Sin la excepción, la DLQ es una caja de mensajes de la que nadie sabe qué hacer.
- Sin el mensaje original intacto, no puedes reprocesar: es el error más común al
  implementarla.

**El proceso, que es la mitad que casi nadie construye:**

1. **Alerta por tasa**, no por mensaje. Un mensaje en la DLQ es normal; cien en una hora es
   un incidente.
2. **Un panel** donde se vea qué hay, agrupado por tipo de excepción.
3. **Una forma de reprocesar** un mensaje o un lote, tras arreglar la causa.
4. **Una política de caducidad**: qué pasa con lo que lleva tres meses ahí.

**Cuándo sí.** Siempre que haya reintentos. Son inseparables.

**Cuándo no.** Nunca "no", pero **una DLQ sin alerta ni panel es peor que no tenerla**:
crea la ilusión de que los fallos están controlados mientras se acumulan sin que nadie mire.

> **Veredicto:** la DLQ es infraestructura trivial y proceso difícil. En entrevista, decir
> *"y quién la mira, y cómo se reprocesa"* vale más que saber configurarla.

---

## 6. 🔁 Reprocesar desde la DLQ

**Qué es.** Volver a meter el mensaje en el flujo después de arreglar la causa. Suena
trivial y tiene tres trampas.

- **El mundo cambió.** Un `PedidoConfirmado` de hace tres días se reprocesa hoy: si el
  consumidor usa la fecha actual en vez de la del evento, calcula mal. Los eventos llevan
  su propia marca de tiempo **y el consumidor la usa**.
- **El orden ya está roto.** El mensaje reprocesado llega después de otros más nuevos de la
  misma entidad. Si el consumidor no tolera el desorden ([`03` §7](03-garantias-orden-e-idempotencia.md#7-️-consumidores-que-no-necesitan-orden)),
  reprocesar puede dejar un estado peor que no hacerlo.
- **La idempotencia importa más que nunca.** Reprocesar es, por definición, procesar de
  nuevo. Si el consumidor no es idempotente, el reproceso duplica.

**Cuándo sí.** Cuando la causa era un bug ya corregido o una dependencia que ya volvió.

**Cuándo no.** Cuando el mensaje era estructuralmente inválido y nunca debió existir: ahí
se descarta y se documenta, y se arregla al productor.

> **Veredicto:** un reproceso es una operación de negocio, no un botón de infraestructura.
> Se decide, se registra y se comunica a quien vea el efecto.

---

## 7. 🧭 Cómo se elige

```text
Llega un fallo. ¿De qué tipo es?
  Validación, deserialización, dato imposible  → PERMANENTE → DLQ directa, sin reintentos
  Timeout, 503, deadlock, conexión             → TRANSITORIO → reintento con retardo

¿Cómo implemento el retardo?
  RabbitMQ → cola TTL + dead-letter-exchange de vuelta
  SQS      → visibility timeout / DelaySeconds
  Kafka    → topics de reintento escalonados... Y ASUMO que pierdo el orden por clave

¿El consumidor necesita orden y no puedo perderlo?
  → No desvío: PARO el consumo de esa partición y alerto. El lag es el precio.

¿Qué pasa con lo que llega a la DLQ?
  → Alerta por tasa + panel + forma de reprocesar + política de caducidad.
    Si no tengo las cuatro, no tengo DLQ: tengo un vertedero.
```

---

## ⚠️ Errores frecuentes

| Se dice | Lo preciso |
|---|---|
| "Reintento todo N veces" | Un fallo permanente fallará igual; va directo a la DLQ |
| "`Thread.sleep` para el retardo" | Bloqueas el hilo y Kafka puede expulsarte del grupo |
| "Los retry topics resuelven el envenenado" | Y rompen el orden por clave; hay que declararlo |
| "Tenemos DLQ" | Sin alerta por tasa, panel y reproceso, es un vertedero |
| "Reprocesar es volver a enviarlo" | El mundo cambió, el orden ya está roto y hace falta idempotencia |
| "El lag sube, escalamos consumidores" | Si sube en **una** partición, es mensaje envenenado y escalar no ayuda |
| "La DLQ guarda el error" | Debe guardar el mensaje **original intacto** además del error |

---

## 📚 Para profundizar

- **Libro** — Gregor Hohpe y Bobby Woolf, *Enterprise Integration Patterns*
  (Addison-Wesley, 2003). Capítulo 7: *Dead Letter Channel*, *Invalid Message Channel* y
  *Guaranteed Delivery*. Los nombres del capítulo salen de aquí.
- **Libro** — Adam Bellemare, *Building Event-Driven Microservices* (O'Reilly, 2020).
  Capítulo 12: gestión de fallos en el consumidor, con el caso del mensaje envenenado.
- **Libro** — Michael Nygard, *Release It!*, 2ª ed. (Pragmatic Bookshelf, 2018). Capítulo
  5: por qué el reintento sin tope es un antipatrón de estabilidad.
- [Spring for Apache Kafka — Error handling and retries](https://docs.spring.io/spring-kafka/reference/kafka/annotation-error-handling.html):
  `@RetryableTopic`, excepciones no reintentables y el `DeadLetterPublishingRecoverer`.
- [RabbitMQ — Dead Letter Exchanges](https://www.rabbitmq.com/docs/dlx): el mecanismo con
  el que se construyen tanto la DLQ como las colas de retardo.
- [Amazon SQS — Visibility timeout](https://docs.aws.amazon.com/AWSSimpleQueueService/latest/SQSDeveloperGuide/sqs-visibility-timeout.html):
  cómo se extiende y cómo se usa para retardar.
- **Video** — Spring I/O y Devoxx, charlas sobre manejo de errores en Spring Kafka.
  Búscalas por título.

---

## 🧠 Preguntas

Sin respuestas aquí. Todas, con enunciado literal y respuesta en tres capas, en
[`10` — Respuestas](10-respuestas.md).

1. ¿Qué es una cola de mensajes muertos? 🟢
2. ¿Qué es un mensaje envenenado? 🟢
3. ¿Cuáles son los dos tipos de fallo y qué se hace con cada uno? 🟢
4. Nombra cuatro cosas que debe llevar un mensaje en la DLQ. 🟢
5. ¿Por qué `Thread.sleep` no sirve para retardar un reintento? 🟡
6. ¿Cómo se implementa un retardo en RabbitMQ? 🟡
7. ¿Cómo se implementa un retardo en Kafka, que no lo tiene nativo? 🟡
8. ¿Por qué un mensaje envenenado es peor en Kafka que en SQS? 🟡
9. ¿Qué cuatro cosas necesita una DLQ para no ser un vertedero? 🟡
10. ¿Por qué una DLQ sin alerta es peor que no tenerla? 🟠
11. ¿Cómo clasificas un fallo como transitorio o permanente? 🟠
12. ¿Qué precio oculto tienen los topics de reintento de Kafka? 🟠
13. ¿Cuáles son las tres salidas ante un mensaje envenenado y qué cuesta cada
    una? 🟠
14. ¿Cuándo saltar un mensaje es inaceptable y qué haces en su lugar? 🟠
15. ¿Por qué reprocesar desde la DLQ puede dejar un estado peor? 🟠
16. ¿Qué tiene que usar el consumidor para que un reproceso tardío no calcule
    mal? 🟠
17. ¿Sobre qué se alerta en una DLQ: sobre cada mensaje o sobre la tasa? 🟠
18. ¿Qué mensaje se descarta en vez de reprocesarse? 🟠
19. El lag crece en una sola partición y las demás van bien. ¿Qué diagnosticas
    y cómo lo confirmas? 🔴
20. Diseña la estrategia de fallos de un consumidor de pagos: clasificación,
    reintentos, DLQ y qué se para. Justifica cada decisión. 🔴
21. Hay 4.000 mensajes en la DLQ tras un incidente de 3 horas. Describe el
    procedimiento completo de recuperación. 🔴
22. Tu consumidor necesita orden por cliente Y tolerancia a fallos transitorios.
    ¿Cómo lo resuelves sin renunciar a ninguno de los dos? 🔴

---

**Anterior:** [`03` — Garantías, orden e idempotencia](03-garantias-orden-e-idempotencia.md) ·
**Siguiente:** [`05` — Saga](05-saga.md) ·
**Relacionado:** [`01-bases/09` — Resiliencia](../01-bases/09-resiliencia.md)
