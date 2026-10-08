# 02 — MQ e integración asíncrona clásica

> El mundo de mensajería que ya existía antes de Kafka y que sigue sosteniendo la banca: colas
> transaccionales, request-reply, transacciones XA de dos fases, y por qué el sector se está
> moviendo a outbox sin poder apagar lo anterior.
> Asume leído [`02-eventos/02` — Brokers comparados](../02-eventos/02-brokers-comparados.md).
>
> **Vigencia:** 2026-09-18.

---

## 1. 🎯 El problema

Tu servicio nuevo tiene que ordenar una transferencia al core. El core no tiene API: tiene una cola
de IBM MQ donde se deja un mensaje de formato fijo y otra cola donde llega la respuesta, minutos
después, sin garantía de orden respecto a otras peticiones tuyas.

```text
Tu mundo:              El suyo:
  REST, JSON             cola de entrada, cola de respuesta
  respuesta inmediata    respuesta diferida, correlacionada por un identificador
  errores HTTP           código de retorno en la posición 47 del mensaje
  reintento trivial      reintentar puede duplicar un asiento contable
```

No puedes cambiar su lado. Todo el capítulo es cómo se diseña el tuyo para convivir con eso.

> **Regla:** en banca, la mensajería clásica no es una alternativa a considerar: es una restricción
> heredada. Lo que se evalúa es si sabes operar dentro de ella.

---

## 2. 📮 Colas transaccionales

**Qué es.** Colas punto a punto con entrega garantizada y persistencia, diseñadas para que un mensaje
no se pierda **nunca**, ni con caída del broker ni del consumidor.

Las propiedades que las definen y que Kafka no tiene:

```text
Persistencia por mensaje → cada mensaje se escribe a disco antes de confirmar la puesta
Entrega garantizada      → el broker reintenta hasta el acuse, con cuenta de intentos
Cola de reintentos y DLQ → nativas, con umbral configurable por cola
Participación en XA      → la puesta o la toma pueden ser parte de una transacción distribuida
Prioridades y caducidad  → por mensaje, sin construir nada
```

- **El modelo es punto a punto**: un mensaje, un consumidor. No hay pub/sub natural ni releer el
  pasado. Si dos sistemas necesitan el mismo dato, se publica dos veces o se usa un tema.
- **El formato suele ser posicional**, no JSON: campos de longitud fija en posiciones acordadas. Un
  cambio de formato es un proyecto coordinado entre dos equipos y a veces entre dos organizaciones.

**Cuándo sí.** Cuando ya está: integrarse con el core, con la red de medios de pago, con sistemas de
otra entidad.

**Cuándo no.** Sistema nuevo entre servicios propios: ahí Kafka o incluso una tabla con un poller
resuelven mejor y con menos operación.

> **Veredicto:** MQ es excelente en lo que hace —entrega fiable punto a punto con garantías
> transaccionales— y no da lo que Kafka da: releer, varios consumidores independientes y escala de
> lectura. No compiten: resuelven problemas distintos.

---

## 3. ↔️ Request-reply asíncrono

**Qué es.** El patrón dominante en la integración con el core: mandas una petición por una cola y la
respuesta llega por otra, sin bloquear.

```text
Tu servicio ──[petición, correlationId=X]──► cola.peticiones ──► CORE
Tu servicio ◄─[respuesta, correlationId=X]── cola.respuestas ◄── CORE
```

- **El `correlationId` es la pieza central**: es lo que permite casar la respuesta con la petición,
  porque llegan desordenadas y puede haber miles en vuelo.
- **La cola de respuesta puede ser exclusiva o compartida.** Si es compartida entre instancias, la
  respuesta puede llegar a una instancia distinta de la que envió: **el estado de la petición no
  puede vivir en memoria**, tiene que estar en la base de datos.
- **Hay que gestionar el timeout tú.** Si la respuesta nunca llega, alguien tiene que decidir qué
  pasa con esa petición, y "esperar indefinidamente" no es una opción.

**Los tres estados que hay que modelar**, y omitir el tercero es el error clásico:

```text
ENVIADA       → petición puesta en la cola, sin respuesta todavía
RESPONDIDA    → llegó respuesta, con su resultado
SIN RESPUESTA → venció el plazo. NO significa que no se ejecutó: significa que no lo sabes.
```

> ⚠️ **Advertencia.** El tercer estado es el que define el diseño. Una petición sin respuesta puede
> haberse ejecutado, así que **no se puede reintentar a ciegas**: hay que consultar el estado en el
> core, o dejarlo a la conciliación. Es exactamente la ambigüedad del acuse perdido de
> [`02-eventos/03`](../02-eventos/03-garantias-orden-e-idempotencia.md), en su forma bancaria.

> **Veredicto:** el request-reply asíncrono obliga a modelar la petición como una **entidad con
> estado**, no como una llamada. Quien lo trata como una llamada acaba con estado en memoria y
> peticiones perdidas al reiniciar.

---

## 4. ⚖️ XA: qué resolvía y qué costaba

**Qué es.** Transacciones distribuidas de dos fases: un coordinador asegura que la escritura en base
de datos y la puesta del mensaje en la cola ocurren las dos o ninguna.

```text
FASE 1 — preparar:  el coordinador pregunta a todos: "¿puedes confirmar?"
                    Cada participante reserva y responde sí. Y QUEDA BLOQUEADO.
FASE 2 — confirmar: si todos dijeron sí, el coordinador ordena confirmar.
                    Si alguno dijo no, ordena deshacer.
```

**Lo que resolvía**, y era real: el problema de la doble escritura de
[`02-eventos/06`](../02-eventos/06-outbox-y-cdc.md), por la vía de coordinar. En 1995 era la única
forma disponible, y por eso está en el corazón de los sistemas bancarios.

**Lo que costaba:**

- **Bloqueo durante toda la transacción distribuida.** Los recursos quedan retenidos entre la fase 1
  y la 2, así que el throughput cae con la contención.
- **El coordinador es un punto único de fallo.** Si muere entre las dos fases, los participantes
  quedan **en duda**: han prometido confirmar y no saben si deben. Ese estado requiere intervención
  manual, y es el terreno donde nadie quiere estar.
- **Casi nada moderno lo soporta.** Ni Kafka, ni las APIs de terceros, ni la mayoría de bases NoSQL.

> **Veredicto:** XA no era una mala idea, era la única idea disponible. El sector se movió a **outbox
> más idempotencia** porque da garantías equivalentes sin coordinador, sin bloqueo y funcionando con
> cualquier transporte. Saber contar esa transición es lo que se evalúa.

---

## 5. 🔄 De XA a outbox, sin apagar XA

**Qué es.** La estrategia real, porque no se puede quitar XA de un sistema que lleva veinte años
usándolo.

```text
Lo nuevo → outbox: escribes el estado y el mensaje en la misma transacción LOCAL,
           y un relay lo pone en la cola. Sin coordinador.
Lo viejo → sigue con XA donde ya estaba, hasta que ese componente se retire.
Ambos    → conviven, y el consumidor debe ser idempotente en los dos casos.
```

- **El outbox funciona igual con MQ que con Kafka**: la tabla es la misma, y el relay pone el mensaje
  en la cola en vez de publicarlo en un topic.
- **El consumidor tiene que ser idempotente de todos modos**, porque el relay puede poner dos veces.
  Con MQ eso se resuelve con el `MessageId` o con una clave de negocio, y una tabla de inbox.
- **La ventaja adicional en banca**: el outbox deja rastro en tu base de datos de qué se ordenó y
  cuándo, que es exactamente lo que la conciliación de [`08`](08-idempotencia-y-conciliacion.md)
  necesita.

> 💡 **Truco.** Cuando te pregunten por XA en una entrevista de banca, la respuesta completa tiene
> tres partes: qué resolvía, qué costaba, y **qué haces tú hoy en un componente nuevo** — que es
> outbox más idempotencia. Quedarse en la crítica sin dar la alternativa es media respuesta.

> **Veredicto:** XA no se migra, se deja de usar. Lo nuevo nace con outbox y consumidor
> idempotente; lo viejo se queda con su coordinador hasta que el componente se retire. Convivir
> cuesta dos modelos mentales en el mismo sistema, y sigue siendo más barato que un corte total
> que nadie te va a aprobar.

---

## 6. 🩺 Operar la integración

**Qué es.** Lo que hay que vigilar, porque una integración por colas falla de formas silenciosas.

| Métrica | Qué indica | Cuándo alerta |
|---|---|---|
| Profundidad de la cola de peticiones | El core no consume | Crece y no baja |
| Profundidad de la de respuestas | Tú no consumes | Ídem |
| Peticiones en estado `ENVIADA` antiguas | Respuestas que no llegan | Antigüedad supera el plazo |
| Mensajes en DLQ | Formato inválido o fallo permanente | Cualquier ráfaga |
| Transacciones en duda | Un XA colgado | Siempre. Requiere intervención. |

- **La métrica que importa es la antigüedad**, no el número: mil peticiones respondiéndose rápido es
  tráfico; una de hace veinte minutos es un incidente. Es el mismo criterio que el lag del outbox.
- **La ventana batch cambia el umbral.** Durante el cierre, la profundidad de la cola crece por
  diseño porque el core no consume. Alertar con el mismo umbral de día produce ruido y entrena al
  equipo a ignorar las alertas.

> 🩺 **Diagnóstico.** "El core no responde": mira primero la profundidad de la cola de peticiones. Si
> crece, el core no consume y tus mensajes están a salvo. Si está vacía y no hay respuestas, el
> problema está en tu lado o en la cola de respuesta.

---

## 7. 🧭 Cómo se elige

```text
¿Es una integración nueva con el core o con otra entidad?
    → Casi nunca eliges: usas lo que ellos exponen. Pregunta qué hay y diseña alrededor.

¿Estás construyendo algo entre TUS servicios?
    ¿Necesitas releer o varios consumidores? → Kafka
    ¿Reparto de trabajo con enrutamiento?    → RabbitMQ
    ¿Poco volumen, un consumidor?            → tabla con poller. En serio.
    MQ solo si ya está y hay razón para reutilizarlo.

¿Cómo garantizo que el mensaje y el cambio de estado ocurren juntos?
    ¿Componente nuevo?  → OUTBOX. Sin coordinador, sin bloqueo.
    ¿Ya usa XA y funciona? → déjalo. Migrar XA que funciona no es prioridad.

En request-reply, modela SIEMPRE los tres estados:
    ENVIADA · RESPONDIDA · SIN RESPUESTA
    Y el tercero NO se reintenta a ciegas: se consulta o se concilia.
```

---

## ⚠️ Errores frecuentes

| Se dice | Lo preciso |
|---|---|
| "MQ es como Kafka pero antiguo" | Es una cola punto a punto: no relee, no tiene varios consumidores independientes |
| "Guardamos el estado de la petición en memoria" | La respuesta puede llegar a otra instancia, o reiniciar y perderse |
| "Si no llega respuesta, reintentamos" | Puede haberse ejecutado: hay que consultar o conciliar |
| "XA es malo" | Era la única opción disponible; hoy se usa outbox, pero no se apaga lo que funciona |
| "Alertamos por profundidad de cola" | Por **antigüedad**, y con umbral distinto durante la ventana batch |
| "Cambiamos el formato del mensaje" | Es posicional y coordinado entre organizaciones: es un proyecto |
| "El outbox es para Kafka" | Funciona igual con MQ: la tabla es la misma, cambia el relay |

---

## 📚 Para profundizar

- **Libro** — Gregor Hohpe y Bobby Woolf, *Enterprise Integration Patterns* (Addison-Wesley, 2003).
  Capítulos 4 a 7, y en especial *Request-Reply*, *Correlation Identifier* y *Return Address*. **Es
  el libro de este capítulo**, y está escrito exactamente para este mundo.
- **Libro** — Chris Richardson, *Microservices Patterns* (Manning, 2018). Capítulo 3: por qué el
  outbox sustituyó a las transacciones distribuidas, con el argumento completo.
- **Libro** — Sam Newman, *Building Microservices*, 2ª ed. (O'Reilly, 2021). Capítulo 6: los
  problemas de 2PC y las alternativas.
- [microservices.io — Transactional outbox](https://microservices.io/patterns/data/transactional-outbox.html):
  la ficha del patrón que sustituye a XA, aplicable igual con colas.
- [Spring for Apache Kafka — Error handling and retries](https://docs.spring.io/spring-kafka/reference/kafka/annotation-error-handling.html):
  los mecanismos de reintento y DLQ, cuyo equivalente en MQ es nativo.
- [RabbitMQ — Dead Letter Exchanges](https://www.rabbitmq.com/docs/dlx): el mecanismo de DLQ
  explicado, conceptualmente equivalente al de MQ.
- **Documentación** — IBM, *IBM MQ*: colas, canales, cola de reintentos y participación en XA. Se
  cita por título; el sitio de IBM bloquea la verificación automática de enlaces (§10.1 de la guía).
- **Video** — GOTO Conferences, charlas de Gregor Hohpe sobre integración empresarial. Búscalas por
  título.

---

## 🧠 Preguntas

Sin respuestas aquí. Todas, con enunciado literal y respuesta en tres capas, en
[`10` — Respuestas](10-respuestas.md).

1. ¿Qué caracteriza a una cola transaccional? 🟢
2. ¿Qué es el request-reply asíncrono? 🟢
3. ¿Qué es el `correlationId` y para qué sirve? 🟢
4. ¿Qué son las dos fases de XA? 🟢
5. ¿Qué tres estados tiene una petición en request-reply? 🟢
6. ¿Qué da MQ que Kafka no da? 🟡
7. ¿Qué da Kafka que MQ no da? 🟡
8. ¿Por qué el estado de la petición no puede vivir en memoria? 🟡
9. ¿Qué significa que una transacción XA quede "en duda"? 🟡
10. ¿Por qué el formato posicional hace que cambiarlo sea un proyecto? 🟡
11. ¿Funciona el outbox con MQ? 🟡
12. ¿Qué métrica importa en una cola: profundidad o antigüedad? 🟠
13. ¿Por qué "sin respuesta" no se reintenta a ciegas? 🟠
14. ¿Qué costaba XA, en tres puntos? 🟠
15. ¿Por qué el sector se movió a outbox sin apagar XA? 🟠
16. ¿Por qué la alerta de cola necesita un umbral distinto durante la ventana? 🟠
17. ¿Qué pasa si la cola de respuesta es compartida entre instancias? 🟠
18. ¿Cómo se hace idempotente un consumidor de MQ? 🟠
19. ¿Qué ventaja adicional da el outbox en banca, más allá de la atomicidad? 🟠
20. ¿Cuándo NO usarías MQ para algo nuevo? 🟠
21. Diseña la ordenación de una transferencia contra un core que solo expone
    colas MQ, con respuesta diferida de hasta 5 minutos. 🔴
22. "El core no responde." Describe cómo investigas y qué te dice cada hallazgo. 🔴
23. Te piden migrar de XA a outbox en un componente que mueve dinero y lleva
    12 años funcionando. ¿Lo haces? Justifica. 🔴

---

**Anterior:** [`01` — Core bancario y legado](01-core-bancario-y-legado.md) ·
**Siguiente:** [`03` — Batch y Spring Batch](03-batch-y-spring-batch.md) ·
**Relacionado:** [`02-eventos/06` — Outbox y CDC](../02-eventos/06-outbox-y-cdc.md)
