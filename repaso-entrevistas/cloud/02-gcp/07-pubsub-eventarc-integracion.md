# 07 — Pub/Sub, Cloud Tasks, Eventarc e integración

> **Objetivo:** elegir con criterio entre Pub/Sub, Cloud Tasks, Eventarc y Workflows, y saber qué
> garantiza de verdad la entrega de un mensaje.
> **Se asume leído:** [`02` — cómputo, contenedores y balanceo](02-computo-contenedores-y-balanceo.md).
> **Se toca sobre todo con:** [`04` — Firestore, Bigtable y NoSQL](04-firestore-bigtable-nosql.md) y
> [`12` — orquestación y CI/CD](12-orquestacion-y-cicd.md).
> **Dónde se practica:** [`L06` — datos y eventos](l06-datos-y-eventos-firestore-pubsub-y-eventarc.md),
> con push subscription autenticada, reintentos y un mensaje envenenado que acaba en el dead-letter.
> **Vigencia:** 6 de septiembre de 2026.

## 1. 🧭 Panorama de mensajería en GCP

```text
Pub/Sub   → servicio unificado de mensajería: cola punto-a-punto y pub/sub fan-out
Cloud Tasks → colas de tareas HTTP controladas por el productor
Eventarc  → event routing entre fuentes y destinos de GCP
```

```text
Pub/Sub vs Cloud Tasks vs Eventarc
Queue/Pub-Sub unificado vs Task queue vs Event routing
```

| | Pub/Sub | Cloud Tasks | Eventarc |
|---|---|---|---|
| Modelo | Topic con uno o varios subscribers (fan-out) | Cola de llamadas HTTP puntuales | Bus de routing de eventos entre fuentes y destinos |
| Quién controla el ritmo | El subscriber (pull) o el push endpoint | El productor, con control fino de rate/concurrencia | El evento origen dispara el destino |
| Caso típico | Desacoplar productor de uno o varios consumidores independientes | Programar/diferir llamadas HTTP controladas (ej. reintentos de un webhook saliente) | Reaccionar a un evento de GCP (objeto subido a Storage, entrada de Audit Log) con un destino serverless |

---

# Parte I — Pub/Sub

## 2. 🧱 Qué es Pub/Sub

Pub/Sub es el servicio **unificado** de mensajería de GCP: cubre tanto el
rol de **cola punto-a-punto** como el de **pub/sub fan-out** dentro del
mismo servicio, a diferencia de modelos que separan ambos roles en dos
servicios distintos.

```text
             Topic
          ┌───┼────┐
          ▼   ▼    ▼
        Sub  Sub  Sub
```

## 3. 🧱 Topic, Publisher, Subscriber, Subscription

- **Topic**: el canal al que se publican mensajes.
- **Publisher**: quien publica mensajes en un topic.
- **Subscriber**: quien consume mensajes desde una subscription.
- **Subscription**: la cola lógica asociada a un topic desde la cual un
  subscriber consume. Un topic puede tener múltiples subscriptions
  independientes (eso es el fan-out).

### Push vs Pull subscription

| | Push | Pull |
|---|---|---|
| Quién inicia la entrega | Pub/Sub llama a un endpoint HTTP | El subscriber solicita mensajes activamente |
| Uso típico | Endpoints serverless (Cloud Run, Cloud Functions) | Workers que controlan su propio ritmo de consumo |

```text
Push subscription vs Pull subscription
```

## 4. 🧱 Entrega: at-least-once y exactly-once

Por defecto, Pub/Sub garantiza **at-least-once delivery**: un mensaje
puede entregarse más de una vez.

```text
At-least-once vs Exactly-once delivery
```

> No respondas que "Pub/Sub garantiza exactly-once por defecto". Es una
> sobregeneralización frecuente e incorrecta. La entrega **exactly-once**
> existe como una **feature explícita** que debe habilitarse, y aplica
> bajo condiciones específicas (dentro de una misma región, con ciertos
> límites de uso) — no es el comportamiento por defecto del servicio.

## 5. 🧱 Ordering keys

Una **ordering key** garantiza orden **dentro de los mensajes que
comparten esa clave**, no un orden global de todo el topic.

```text
Ordering key
```

```text
Mensajes con ordering_key = "order-123"  → entregados en orden entre sí
Mensajes con ordering_key = "order-456"  → entregados en orden entre sí, sin relación de orden con order-123
```

## 6. 🧱 Deduplication

Pub/Sub puede deduplicar mensajes dentro de una ventana, relevante en
combinación con exactly-once delivery y con publishers que reintentan
publicaciones.

## 7. 🧱 Acknowledgement deadline

Ventana de tiempo durante la cual un subscriber debe confirmar
(`ack`) un mensaje entregado antes de que Pub/Sub lo considere no
procesado y vuelva a entregarlo — equivalente conceptual a un visibility
timeout.

```text
Mensaje entregado
      │
   ack deadline
      │
  ¿ack recibido a tiempo?
   /            \
 Sí              No
confirmado    se reentrega
```

## 8. 🧱 Retries y Dead-letter topics

Si un subscriber falla en procesar un mensaje repetidamente, Pub/Sub
puede reintentar según una política configurada y, tras superar un número
máximo de intentos, enviar el mensaje a un **dead-letter topic** para
investigación y recuperación controlada, en lugar de reintentar
indefinidamente.

```text
Dead-letter topic
```

## 9. 🧱 Retention e idempotencia

- **Retention**: cuánto tiempo Pub/Sub conserva un mensaje no confirmado
  (y, opcionalmente, mensajes ya confirmados) antes de descartarlo.
- **Idempotencia**: dado que la entrega es at-least-once por defecto, el
  consumer debe diseñarse para que procesar el mismo mensaje más de una
  vez no produzca efectos incorrectos adicionales.

```text
Idempotent Consumer
```

---

# Parte II — Cloud Tasks

## 10. 🧱 Cloud Tasks

**Cloud Tasks** administra colas de **tareas HTTP** con control de rate y
concurrencia, y reintentos configurables por el productor.

```text
App
  │  encola una tarea con payload y destino HTTP
  ▼
Cloud Tasks
  │  invoca el endpoint respetando rate/concurrencia configurados
  ▼
Endpoint HTTP (ej. Cloud Run)
```

### Diferencia de propósito frente a Pub/Sub

Cloud Tasks orquesta llamadas HTTP puntuales **controladas por el
productor** (qué endpoint, con qué rate, cuándo reintentar); Pub/Sub es
fan-out **desacoplado** entre productores y consumidores, donde el
productor no necesita saber quién ni cuántos consumen.

---

# Parte III — Eventarc

## 11. 🧱 Eventarc

**Eventarc** enruta eventos desde fuentes de GCP (Cloud Storage, Cloud
Audit Logs, Pub/Sub) hacia destinos (Cloud Run, Cloud Functions,
Workflows), mediante **triggers**.

```text
Cloud Storage (object finalized)
        │
        ▼
    Eventarc trigger
        │
        ▼
   Cloud Run / Cloud Functions / Workflows
```

Es el mecanismo central de **event-driven architecture** con integración
nativa a servicios de GCP, sin que el destino necesite conocer los
detalles de la fuente del evento (formato uniforme tipo CloudEvents).

---

# Parte IV — Procesamiento asíncrono

## 12. 🧭 Patrón de referencia

```text
POST /orders
      │
      ▼
Spring Boot (Cloud Run)
      │
      ▼
   Pub/Sub
      │
      ▼
Payment Worker (Cloud Run job)
```

## 13. 🧭 Conceptos que conviene nombrar en una respuesta de arquitectura

- **Desacoplamiento**: el productor no espera a que el consumidor termine
  de procesar.
- **Buffering**: el topic/cola absorbe picos de tráfico que el consumidor
  no podría procesar sincrónicamente.
- **Backpressure**: cuando el consumidor no da abasto, el backlog crece;
  la respuesta es escalar consumers o limitar el productor, no ignorar la
  señal.
- **Retries**: reintentos automáticos ante fallos transitorios del
  consumer.
- **Dead-letter topics**: destino para mensajes que agotan sus reintentos.
- **Idempotencia**: obligatoria dado at-least-once por defecto.
- **Escalado de consumers**: Cloud Run escala instancias de un worker
  según concurrencia configurada y, en el caso de subscriptions pull,
  según el backlog pendiente.
- **Respuesta HTTP `202 Accepted`**: el endpoint síncrono confirma que
  aceptó el trabajo, no que ya terminó de procesarlo.

---

## 🧠 Preguntas rápidas

1. ¿Qué diferencia a Pub/Sub de un servicio que separa colas punto-a-punto de pub/sub fan-out?
2. ¿Push subscription y pull subscription entregan mensajes de la misma forma?
3. ¿Pub/Sub garantiza exactly-once delivery por defecto?
4. ¿Una ordering key garantiza orden global de todo el topic?
5. ¿Qué es el acknowledgement deadline?
6. ¿Qué hace un dead-letter topic?
7. ¿Por qué un consumer de Pub/Sub debe ser idempotente?
8. ¿Qué diferencia de propósito hay entre Cloud Tasks y Pub/Sub?
9. ¿Qué hace un trigger de Eventarc?
10. ¿Qué significa backpressure en un flujo de procesamiento asíncrono?
11. ¿Por qué un endpoint síncrono respondería `202 Accepted` en lugar de esperar a que termine el procesamiento?

---

## 📚 Referencias oficiales

- Pub/Sub overview: https://cloud.google.com/pubsub/docs/overview
- Subscriber overview (push/pull): https://cloud.google.com/pubsub/docs/subscriber
- Exactly-once delivery: https://cloud.google.com/pubsub/docs/exactly-once-delivery
- Ordering keys: https://cloud.google.com/pubsub/docs/ordering
- Dead-letter topics: https://cloud.google.com/pubsub/docs/handling-failures
- Message retention: https://cloud.google.com/pubsub/docs/subscription-message-retention
- Cloud Tasks overview: https://cloud.google.com/tasks/docs/dual-overview
- Eventarc overview: https://cloud.google.com/eventarc/docs/overview
- Eventarc triggers: https://cloud.google.com/eventarc/docs/creating-triggers
