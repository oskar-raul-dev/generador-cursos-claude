# 07 — Mensajería, eventos e integración

> **Objetivo:** elegir entre SQS, SNS, EventBridge y Kinesis sabiendo qué garantiza
> cada uno, y responder bien la pregunta que siempre cae: por qué necesitas idempotencia igual.
> **Se asume leído:** [`02`](02-computo-contenedores-y-balanceo.md) — Lambda y ECS como
> consumidores.
> **Se conecta con:** [`12`](12-orquestacion-y-cicd.md) (cuándo la respuesta es una
> State Machine y no una cola) y [`L03`](l03-backend-serverless-lambda-api-y-eventos.md).
> **Vigencia:** 6 de septiembre de 2026 (documentación oficial de AWS verificada en esa fecha).

**Salto rápido:** [Por qué desacoplar](#1--por-qué-desacoplar) · [SQS — Simple Queue Service](#2--sqs--simple-queue-service) · [Standard Queue](#3--standard-queue) · [FIFO Queue](#4--fifo-queue) · [Visibility Timeout](#5--visibility-timeout) · [Long Polling](#6--long-polling) · [Dead-Letter Queue — DLQ](#7--dead-letter-queue--dlq) · [Idempotencia](#8--idempotencia) · [SNS — Simple Notification Service](#9--sns--simple-notification-service) · [SNS + SQS — fan-out durable](#10--sns--sqs--fan-out-durable) · [EventBridge](#11--eventbridge) · [Kinesis — Data Streams y Firehose](#12--kinesis--data-streams-y-firehose) · [Event pattern](#13--event-pattern) · [Event-driven vs queue-driven](#14--event-driven-vs-queue-driven) · [Retry y poison messages](#15--retry-y-poison-messages) · [Ordering](#16--ordering) · [Backpressure](#17--backpressure) · [Preguntas rápidas](#-preguntas-rápidas) · [Referencias oficiales](#-referencias-oficiales)

---

## 1. 🧭 Por qué desacoplar

Arquitectura síncrona:

```text
Order API → Payment API → Email API → Inventory API
```

Si cada llamada es obligatoria para responder, aumentan:

- latencia;
- acoplamiento temporal;
- cascadas de fallos;
- complejidad de retries.

Arquitectura asíncrona:

```text
Order API
   │
   ▼
 Queue/Event
   │
   ├── Payment Worker
   ├── Email Worker
   └── Inventory Worker
```

No todo debe ser asíncrono; usa el modelo según la semántica del negocio.

---

## 2. 🧱 SQS — Simple Queue Service

Queue administrada.

Modelo:

```text
Producer
   │
   ▼
  SQS
   │
   ▼
Consumer
```

Beneficios:

- desacoplamiento;
- buffering;
- absorber picos;
- retries;
- consumers independientes del producer.

---

## 3. 🧱 Standard Queue

Asociación mental:

- throughput muy alto;
- entrega **at-least-once**;
- ordering best-effort.

Por eso consumer debe diseñarse para duplicados/reintentos.

---

## 4. 🧱 FIFO Queue

Asociación mental:

- orden estricto dentro del modelo FIFO/message group;
- deduplicación soportada;
- semántica orientada a exactly-once processing en el contexto documentado por SQS FIFO.

No extrapoles “FIFO = jamás tengo que pensar en idempotencia”. En sistemas distribuidos, efectos externos y fallos parciales todavía justifican diseño idempotente.

---

## 5. 🧱 Visibility Timeout

Cuando un consumer recibe un mensaje, SQS lo oculta temporalmente de otros consumers.

```text
Receive
  │
  ├── procesar OK → DeleteMessage
  │
  └── no delete / timeout → mensaje vuelve a ser visible
```

El mecanismo existe porque SQS no puede distinguir un consumer lento de un consumer
muerto: si el proceso se cae a mitad, nadie va a llamar a `DeleteMessage`, y el mensaje
tiene que volver a la cola solo. El visibility timeout es cuánto está dispuesto a esperar
antes de dar por muerto al consumer.

Ahí está el filo del ajuste, y se corta por los dos lados. Si lo pones **corto**, un
consumer que simplemente tardó más de la cuenta ve reaparecer su mensaje mientras aún lo
está procesando, y otro worker lo toma: dos procesamientos simultáneos del mismo mensaje,
que es el peor caso posible porque además compiten. Si lo pones **largo**, un consumer
que se cayó de verdad deja el mensaje congelado todo ese tiempo antes de que nadie lo
reintente.

> 🧠 **Modelo mental.** El visibility timeout no es "cuánto tarda el mensaje en
> procesarse": es cuánto tiempo le das al consumer antes de asumir que murió. Se calcula
> desde el peor caso de duración, no desde el promedio.

La regla operativa que usan los labs de este curso es dejarlo en varias veces el timeout
de la función —[`L03` §9](l03-backend-serverless-lambda-api-y-eventos.md#9--sqs-dlq-y-el-timeout-de-visibilidad)
lo fija en seis veces—, y para trabajos de duración impredecible, extenderlo en caliente
desde el propio consumer mientras sigue vivo.

---

## 6. 🧱 Long Polling

Con el comportamiento por defecto, `ReceiveMessage` responde de inmediato aunque no haya
nada: un worker en bucle acaba haciendo miles de llamadas vacías por minuto. Se pagan
todas —SQS cobra por request, tenga mensajes o no— y encima añaden latencia, porque el
mensaje que llega justo después de una respuesta vacía espera al siguiente sondeo.

El **long polling** hace que la llamada se quede esperando hasta 20 segundos a que
aparezca algo, y vuelva en cuanto aparece.

Beneficios:

- menos empty receives;
- menor costo/ruido;
- mejor eficiencia.

Es decir: menos requests facturadas **y** menor latencia a la vez, lo que lo convierte en
una de las pocas opciones de este temario sin contrapartida real. Se activa fijando
`ReceiveMessageWaitTimeSeconds` en la cola, y no hay casi ningún motivo para dejarlo en
cero.

---

## 7. 🧱 Dead-Letter Queue — DLQ

Un mensaje que la aplicación no puede procesar —un JSON malformado, un identificador que
ya no existe— falla, vuelve a ser visible, y otro consumer lo toma y falla igual. Sin
nada que lo detenga, ese mensaje gira para siempre, quemando invocaciones y ensuciando
las métricas de error. Es lo que se llama un **poison message**, y la DLQ es el freno.

Tras repetidos fallos de procesamiento, una redrive policy puede mover mensajes a una DLQ.

```text
Main Queue
   │ repeated failures
   ▼
  DLQ
```

La DLQ sirve para:

- investigar poison messages;
- alertar;
- corregir y redrive/reprocesar de forma controlada.

Lo que la hace útil es que el mensaje se conserva íntegro con su historial: puedes leer
exactamente qué entrada rompió el consumer, en vez de deducirlo de un log. Y lo que la
hace obligatoria es el orden de las operaciones: **primero se arregla la causa, después
se reenvía**. Un redrive antes del arreglo devuelve los mensajes al mismo camino que los
mató y vuelven a la DLQ tras gastar otro ciclo completo de reintentos.

No la uses como cementerio que nadie monitorea. Una DLQ sin alarma es un incidente que
está ocurriendo y nadie ha visto: por eso "DLQ con mensajes" es una de las cuatro alarmas
que [`L04` §5](l04-observabilidad-y-destruccion-verificada.md#5--las-alarmas-que-importan)
considera imprescindibles.

---

## 8. 🧭 Idempotencia

Operación idempotente:

> Repetir la misma solicitud no produce efectos adicionales incorrectos.

Ejemplo de pago:

```text
message paymentId=123
```

Consumer procesa dos veces por retry.

Malo:

```text
charge() dos veces
```

Mejor:

```text
idempotency store
paymentId=123 ya procesado → no repetir efecto
```

DynamoDB con conditional writes puede servir como pieza de este patrón.

---

## 9. 🧱 SNS — Simple Notification Service

Pub/Sub administrado.

```text
             ┌── SQS A
Publisher → SNS
             ├── SQS B
             ├── Lambda
             └── otro subscriber compatible
```

Concepto:

```text
SNS = topic / fan-out
SQS = queue / buffering / pull-consumer model
```

---

## 10. 🧱 SNS + SQS — fan-out durable

Patrón muy común:

```text
                SNS Topic
             /      |      \
            ▼       ▼       ▼
          SQS A   SQS B   SQS C
            │       │       │
         worker   worker   worker
```

Ventaja:

- cada dominio tiene su propia cola;
- cada consumer avanza a su ritmo;
- un consumer caído no bloquea a los demás;
- el topic distribuye, las queues amortiguan.

---

## 11. 🧱 EventBridge

Event bus/routing administrado para eventos.

Modelo:

```text
Event producers
      │
      ▼
 EventBridge Bus
      │ rules/patterns
 ┌────┼─────────┐
 ▼    ▼         ▼
Lambda SQS  Step Functions/targets
```

Diferencia mental frente a SNS:

- SNS: pub/sub topic y fan-out directo;
- EventBridge: event bus con matching/routing por contenido y fuerte integración con eventos AWS/SaaS/custom.

No son sustitutos perfectos; ambos pueden coexistir.

---

## 12. 🧱 Kinesis — Data Streams y Firehose

Hasta aquí SQS/SNS/EventBridge resuelven colas, pub/sub y event routing. **Kinesis** resuelve un problema distinto: streaming de datos en orden, con múltiples consumidores leyendo el mismo flujo de forma independiente y en paralelo.

### Kinesis Data Streams

```text
Producers
   │ put record
   ▼
Stream
├── Shard 1 (partition key range A)
├── Shard 2 (partition key range B)
└── Shard 3 (partition key range C)
   │
   ├── Consumer A (analytics)
   ├── Consumer B (fraud detection)
   └── Consumer C (archiving)
```

Conceptos:

- **shard**: unidad de capacidad/paralelismo; cada shard mantiene orden por partition key;
- **partition key**: determina a qué shard va cada record;
- retención configurable, mayor que la de una queue estándar;
- múltiples consumers pueden leer el mismo stream de forma independiente, sin "consumir" el registro como hace SQS.

### Kinesis Data Firehose

Entrega streaming de datos hacia destinos (S3, OpenSearch, Redshift, endpoints HTTP, entre otros) con buffering/transformación administrados, sin operar consumers propios para ese caso de carga.

```text
Stream/source
   │
   ▼
Firehose
   │ buffer + transform opcional
   ▼
S3 / OpenSearch / Redshift / HTTP endpoint
```

### SQS vs SNS vs EventBridge vs Kinesis

| Necesidad | SQS | SNS | EventBridge | Kinesis Data Streams |
|---|---:|---:|---:|---:|
| Modelo | Queue (pull) | Pub/Sub (push) | Event bus (routing) | Stream ordenado |
| Varios consumers leen el mismo dato de forma independiente | no | sí (fan-out) | sí (routing por regla) | sí (replay dentro de la retención) |
| Orden garantizado | solo FIFO | no | no | sí, por shard/partition key |
| Retención/replay de datos ya leídos | no | no | no | sí, dentro de la ventana de retención |
| Caso típico | trabajo asíncrono desacoplado | notificar a varios sistemas | routing de eventos de negocio/SaaS | analítica en tiempo real, clickstream/logs/IoT |

Regla de entrevista:

```text
"Necesito que varios consumidores lean el mismo stream de eventos, en orden, con posibilidad de reprocesar" → Kinesis
"Necesito desacoplar un productor de un trabajo async"                                                     → SQS
"Necesito notificar a varios sistemas cuando pasa algo"                                                    → SNS/EventBridge
```

No digas "Kinesis es lo mismo que SQS pero más rápido". Mejor:

> Kinesis es un stream ordenado con retención y múltiples lectores independientes; SQS es una queue donde cada mensaje se entrega a un consumer lógico y desaparece al confirmarse.

---

## 13. 🧱 Event pattern

Una rule puede filtrar eventos por contenido.

Ejemplo conceptual:

```json
{
  "source": ["com.mycompany.orders"],
  "detail-type": ["OrderCreated"]
}
```

Solo eventos que coincidan se enrutan al target de esa rule.

---

## 14. ⚖ Event-driven vs queue-driven

### Queue-driven

Consumer pregunta por trabajo pendiente.

```text
SQS → worker
```

Excelente para controlar backlog y procesamiento asíncrono.

### Event-driven bus/topic

Publisher emite hecho ocurrido:

```text
OrderCreated
```

Múltiples consumidores reaccionan.

La diferencia que importa no es el servicio, es **quién conoce a quién**. En el modelo de
cola, el productor sabe exactamente qué trabajo está encargando y a qué cola: hay un
destinatario y un contrato. En el modelo de eventos, el productor anuncia que algo pasó y
no sabe —ni le importa— quién escucha; añadir un cuarto consumidor no toca ni una línea
del productor.

Esa libertad se paga en dos monedas. La primera es de diagnóstico: con una cola sabes
quién debía procesar el mensaje y puedes mirar su backlog, mientras que con un bus, "esto
no ocurrió" exige averiguar primero quién tenía que reaccionar. La segunda es de
contrato: el evento se convierte en una API pública de la que dependen consumidores que
no controlas, así que cambiarle un campo es un cambio incompatible aunque no lo parezca.

La regla para elegir cabe en una frase: **si el productor necesita que algo concreto
ocurra, es una cola; si el productor solo informa de un hecho, es un evento**. Una
arquitectura madura frecuentemente combina ambos —el bus enruta el hecho, y cada
consumidor lo amortigua en su propia cola—, que es exactamente el patrón de §10.

---

## 15. 🩺 Retry y poison messages

Diseña siempre:

- retry policy;
- backoff;
- idempotencia;
- DLQ;
- alertas;
- maximum receive attempts;
- observabilidad del backlog.

No implementes retry infinito inmediato:

```text
failure → retry → failure → retry → ...
```

Puede amplificar incidentes.

---

## 16. 🧱 Ordering

Pregunta:

> “Necesito que todos los eventos del sistema estén globalmente ordenados.”

Desconfía de ese requisito. Normalmente basta orden por aggregate/entity/group:

```text
orderId=123 events ordered
```

La razón para desconfiar es que el orden global y el paralelismo son incompatibles: si
todo tiene que procesarse en secuencia estricta, tu sistema tiene exactamente un
consumer, y el throughput de todo el conjunto es el de esa única máquina. Nadie quiere
eso; lo que casi siempre quieren decir es que los eventos *de un mismo pedido* no pueden
adelantarse entre sí, y eso es una restricción mucho más barata.

FIFO message groups permiten exactamente esa distinción: el orden se garantiza dentro de
cada `MessageGroupId` y los grupos avanzan en paralelo entre sí. Con `orderId` como
grupo, tienes tantos consumidores en paralelo como pedidos activos y orden perfecto
dentro de cada uno.

> ⚠️ El reverso: dentro de un grupo, un mensaje atascado bloquea a todos los que van
> detrás en ese grupo, porque entregarlos sería romper el orden que pediste. Elegir un
> `MessageGroupId` demasiado grueso —`tenantId` en vez de `orderId`— convierte un poison
> message en una parada de todo el cliente.

---

## 17. 🩺 Backpressure

SQS crea un buffer entre producción y consumo.

```text
Producer 5000/s
Consumer 3000/s

Queue backlog ↑
```

Puedes:

- escalar consumers;
- degradar/limitar producer;
- investigar downstream;
- usar queue depth/age como señal de autoscaling.

La cola no elimina el problema de capacidad; lo hace observable y desacoplado. Y esa es
justamente la trampa: como el sistema no se cae, un desbalance permanente puede pasar
semanas sin que nadie lo note, hasta que alguien pregunta por qué los correos llegan con
seis horas de retraso.

Por eso la métrica que se vigila no es la profundidad de la cola sino la **antigüedad del
mensaje más viejo**. El backlog te dice cuánto trabajo hay pendiente, que sube y baja con
los picos y no significa nada por sí solo; la antigüedad te dice cuánto lleva esperando
el peor caso, que es lo que sufre el usuario y lo único que distingue un pico sano de un
consumer que no da abasto. Es también la señal correcta para escalar workers, como
recoge [`08` §16](08-observabilidad-auditoria-gobierno.md#16--cloudwatch--autoscaling).

---

## 🧠 Preguntas rápidas

1. ¿SQS vs SNS?
2. ¿Por qué se combina un topic SNS con varias colas SQS?
3. ¿Standard vs FIFO?
4. ¿Qué es visibility timeout?
5. ¿Por qué un mensaje puede reprocesarse?
6. ¿Qué hace una DLQ?
7. ¿Qué significa idempotencia?
8. ¿EventBridge vs SNS?
9. ¿Qué es backpressure?
10. ¿Cómo escalarías workers según backlog?
11. ¿Qué diferencia a Kinesis Data Streams de SQS?
12. ¿Qué problema resuelve Firehose que Data Streams no resuelve directamente?
13. ¿Por qué varios consumers pueden leer el mismo Kinesis stream sin "competir" por el mensaje?

---

## 📚 Referencias oficiales

- SQS: https://docs.aws.amazon.com/AWSSimpleQueueService/latest/SQSDeveloperGuide/welcome.html
- SQS Standard: https://docs.aws.amazon.com/AWSSimpleQueueService/latest/SQSDeveloperGuide/standard-queues.html
- SQS FIFO: https://docs.aws.amazon.com/AWSSimpleQueueService/latest/SQSDeveloperGuide/sqs-fifo-queues.html
- Visibility timeout: https://docs.aws.amazon.com/AWSSimpleQueueService/latest/SQSDeveloperGuide/sqs-visibility-timeout.html
- DLQ: https://docs.aws.amazon.com/AWSSimpleQueueService/latest/SQSDeveloperGuide/sqs-dead-letter-queues.html
- SNS: https://docs.aws.amazon.com/sns/latest/dg/welcome.html
- EventBridge: https://docs.aws.amazon.com/eventbridge/latest/userguide/eb-what-is.html
- Kinesis Data Streams: https://docs.aws.amazon.com/streams/latest/dev/introduction.html
- Kinesis Data Firehose: https://docs.aws.amazon.com/firehose/latest/dev/what-is-this-service.html
- Short polling frente a long polling: https://docs.aws.amazon.com/AWSSimpleQueueService/latest/SQSDeveloperGuide/sqs-short-and-long-polling.html
- FIFO y procesamiento exactly-once: https://docs.aws.amazon.com/AWSSimpleQueueService/latest/SQSDeveloperGuide/FIFO-queues-exactly-once-processing.html
- Reglas de EventBridge: https://docs.aws.amazon.com/eventbridge/latest/userguide/eb-rules.html
- Event patterns de EventBridge: https://docs.aws.amazon.com/eventbridge/latest/userguide/eb-event-patterns.html
- Event source mappings de Lambda: https://docs.aws.amazon.com/lambda/latest/dg/invocation-eventsourcemapping.html
- Escenarios comunes de SNS (fan-out): https://docs.aws.amazon.com/sns/latest/dg/sns-sqs-as-subscriber.html
