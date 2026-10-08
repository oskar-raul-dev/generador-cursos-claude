# 13 — Mensajería y eventos

> **Objetivo:** elegir entre los cuatro servicios de mensajería de Azure a partir del problema —comando,
> evento discreto o stream—, conocer a fondo Service Bus, que es el que usa `inv-api`, y diseñar un
> consumidor que sobreviva a la entrega at-least-once.
> **Se asume leído:** [`09`](09-identidad-entra-id-y-managed-identities.md) y
> [`10`](10-autorizacion-rbac-policy-y-gobierno.md), para autenticar productores y consumidores con
> managed identity y roles de datos.
> **Se toca más con:** [`04`](04-computo-y-contenedores.md), donde Container Apps escala por mensajes
> pendientes, [`08`](08-cosmos-db.md), cuyo change feed es la base del outbox, y el [`14`](14-observabilidad-monitor-log-analytics-app-insights.md)
> (observabilidad), que mide la cola y la DLQ.
> **Se practica en:** [`L07`](l07-datos-y-eventos-cosmos-db-y-service-bus.md) (namespace Standard, topic `inv-events`, subscription `inv-projector`, un
> mensaje envenenado en la DLQ y roles de datos por identidad). Event Grid tiene un drill gratuito en
> [`L00` §9](l00-idea-lab-practico.md#9--ampliaciones-opcionales); Event Hubs se sustituye
> por Kafka en local. Ver [`L00` §7.2](l00-idea-lab-practico.md#72-el-índice).
> **Vigencia:** 28 de septiembre de 2026.

**Salto rápido:** [El problema](#1--el-problema-comandos-eventos-y-streams) ·
[Storage Queues](#2--storage-queues) · [Service Bus](#3--service-bus-el-broker-empresarial) ·
[Recibir y liquidar](#4--recibir-y-liquidar-peek-lock-y-la-dlq) · [Duplicados, sesiones y transacciones](#5--duplicados-sesiones-y-transacciones) ·
[Service Bus en el laboratorio](#6--service-bus-en-el-laboratorio) · [Event Grid](#7--event-grid) ·
[Event Hubs](#8--event-hubs) · [⚖ La matriz](#9--la-matriz-de-decisión) ·
[At-least-once](#10--at-least-once-idempotencia-y-outbox) · [Preguntas](#-preguntas-rápidas)

---

## 1. 🧭 El problema: comandos, eventos y streams

Antes de nombrar un servicio, hay que saber qué tipo de mensaje se mueve:

| Tipo | Qué es | Ejemplo en el banco | Qué exige |
|---|---|---|---|
| **Comando** | Una orden a un destinatario concreto, que tiene que ejecutarse una vez | "Registra este movimiento de inventario" | Entrega fiable, reintentos, DLQ, orden a veces |
| **Evento discreto** | Aviso de que algo pasó; el emisor no sabe quién escucha | "Se creó un blob", "un secreto va a expirar" | Reparto a muchos, push, filtros |
| **Stream** | Una secuencia continua y ordenada de eventos que se relee | Telemetría de cajeros, clics, logs | Alto volumen, particiones, retención, replay |

Azure tiene un servicio para cada caso y uno mínimo:

```text
Comandos y mensajes de negocio   → Service Bus
Eventos discretos (reacción)     → Event Grid
Streams de alto volumen          → Event Hubs
Cola simple y barata             → Storage Queues
```

La pregunta de entrevista no es "¿qué es Service Bus?", sino "¿por qué Service Bus y no Event Grid aquí?".
La respuesta sale de esta tabla.

---

## 2. 🧱 Storage Queues

La cola mínima, parte de una storage account ([`06`](06-almacenamiento-storage-accounts.md)):

- mensajes de hasta **64 KB** (48 KB si se codifican en Base64); para algo mayor, el patrón es guardar el
  payload en un blob y encolar la referencia;
- **visibility timeout**: al leer un mensaje, desaparece durante un tiempo (30 segundos por defecto,
  hasta 7 días) y, si el consumidor no lo borra, vuelve a aparecer. Es entrega **at-least-once**;
- **sin DLQ automática**: el consumidor mira el `DequeueCount` y mueve él mismo los mensajes venenosos a
  otra cola;
- **sin orden garantizado**, sin duplicate detection, sin sesiones, sin transacciones, sin
  publish/subscribe;
- capacidad enorme (la de la storage account) y precio de almacenamiento.

**Cuándo bastan:** trabajo en segundo plano simple, un único consumidor lógico, mensajes pequeños y
tolerancia a un orden aproximado. Cuando aparece cualquiera de las palabras DLQ, orden, duplicados,
topics o transacciones, la respuesta es Service Bus.

---

## 3. 🧱 Service Bus: el broker empresarial

**Service Bus** es un broker de mensajes con AMQP 1.0, pensado para mensajes de negocio. Se organiza en
un **namespace** que contiene:

- **queues**: punto a punto; cada mensaje lo procesa **un** consumidor de los que compiten;
- **topics** con **subscriptions**: publish/subscribe; cada subscription recibe **su copia** del mensaje
  y se comporta como una cola propia. Las subscriptions pueden tener **filtros** (SQL sobre las
  propiedades o de correlación) para recibir solo lo que les interesa.

Tres tiers:

| | Basic | Standard | Premium |
|---|---|---|---|
| Topics y subscriptions | ❌ solo queues | ✅ | ✅ |
| Sesiones, duplicate detection, transacciones | ❌ | ✅ | ✅ |
| Tamaño de mensaje | 256 KB | 256 KB | Hasta 100 MB (AMQP) |
| Recursos | Compartidos | Compartidos, con throttling | **Dedicados** (messaging units) |
| Private endpoints | ❌ | ❌ | ✅ |

El laboratorio usa **Standard** (decisión D6): tiene topics y todo lo que se pregunta, y cuesta poco.
Premium es la respuesta de producción en banca cuando hacen falta aislamiento, private endpoints o
latencia predecible.

> 💰 **Costo.** En `eastus2`, un namespace **Standard** cobra **$0.013441/h** —unos $10 al mes— con 13
> millones de operaciones al mes incluidas, exista tráfico o no; el siguiente tramo cuesta $0.80 por
> millón. Una **messaging unit Premium** cuesta **$0.9275/h**, unos $677 al mes, y nunca se crea en el
> laboratorio. Basic cobra solo por operación ($0.05 por millón) pero no tiene topics.

---

## 4. 🧱 Recibir y liquidar: peek-lock y la DLQ

Hay dos modos de recepción, y la elección es una decisión de fiabilidad:

- **receive-and-delete**: el broker da el mensaje por consumido en cuanto lo envía. Si el consumidor
  muere antes de procesarlo, **el mensaje se pierde**. Es entrega **at-most-once**;
- **peek-lock** (el modo por defecto): el broker **bloquea** el mensaje para ese consumidor durante el
  *lock duration* y espera una **liquidación** (*settlement*):
  - `complete`: procesado; se borra;
  - `abandon`: falló, que vuelva a la cola ya;
  - `dead-letter`: no tiene arreglo; a la DLQ con un motivo;
  - `defer`: apartarlo para leerlo más tarde por su número de secuencia.

  Si el lock expira sin liquidación, el mensaje vuelve a estar disponible. Es entrega **at-least-once**.

Los números que se preguntan:

- el **lock duration** es de **1 minuto** por defecto y como máximo **5 minutos**; para procesos más
  largos, el cliente **renueva el lock** (el SDK lo hace solo con la renovación automática);
- cada vez que un mensaje se abandona o su lock expira, sube su **delivery count**; al superar
  **`MaxDeliveryCount`** (10 por defecto) se mueve a la DLQ con el motivo `MaxDeliveryCountExceeded`;
- la **dead-letter queue** es una subcola que **existe en cada queue y en cada subscription** sin
  crearla: `<queue>/$deadletterqueue` o `<topic>/Subscriptions/<sub>/$deadletterqueue`. **No limpia
  sola**: los mensajes se quedan hasta que alguien los lee y los completa;
- los mensajes **expirados** por TTL solo van a la DLQ si se habilita el dead-lettering por expiración;
  si no, se descartan.

> ⚠️ **Un lock perdido no es un error de tu código.** Si el procesamiento dura más que el lock, otro
> consumidor recibe el mismo mensaje mientras el primero sigue trabajando, y el `complete` del primero
> falla con `MessageLockLostException`. Se evita con un lock duration mayor que el tiempo normal de
> proceso y con la renovación automática, y se tolera con un consumidor idempotente (§10).

> 🩺 **Diagnóstico.** Mensajes en la DLQ con `MaxDeliveryCountExceeded` y ninguna excepción en los logs
> suelen significar que el consumidor **no liquida**: cierra el receptor antes del `complete` o nunca lo
> llama. El mensaje vuelve una y otra vez hasta agotar el delivery count.

---

## 5. 🧱 Duplicados, sesiones y transacciones

**Duplicate detection** (Standard y Premium): el broker descarta un mensaje cuyo `MessageId` ya vio
dentro de una ventana (**10 minutos por defecto**, configurable hasta 7 días). Protege contra el
**productor** que reintenta un envío del que no recibió confirmación. **No** protege contra la
redelivery al consumidor tras un lock expirado: ese es el mismo mensaje entregado dos veces, no dos
mensajes.

> Nunca respondas: "activamos duplicate detection, así que el consumidor no ve duplicados". Mejor:
> "duplicate detection deduplica los envíos repetidos del productor por `MessageId` dentro de una
> ventana; la entrega al consumidor sigue siendo at-least-once, así que el consumidor tiene que ser
> idempotente".

**Sesiones**: los mensajes con el mismo `SessionId` se entregan **en orden y a un único consumidor a la
vez**. Es la forma de tener **FIFO por clave** (todos los movimientos de un mismo producto en orden) sin
renunciar al paralelismo entre claves. Una entidad con sesiones exige `SessionId` en todos sus mensajes.

**Mensajes programados**: se envían con una fecha de encolado futura (`ScheduledEnqueueTime`) y no son
visibles hasta entonces.

**Transacciones**: agrupan operaciones sobre una misma entidad (recibir y completar un mensaje y enviar
otro) de forma atómica, hasta 100 mensajes por transacción. No abarcan una base de datos: para eso está
el outbox (§10).

> Nunca respondas: "Service Bus garantiza exactly-once". Mejor: "Service Bus da at-least-once con
> peek-lock y at-most-once con receive-and-delete; con sesiones, transacciones y duplicate detection se
> acerca a *exactly-once processing*, pero la propia documentación advierte que un fallo de transacción
> provoca redelivery. El exactly-once de verdad es un consumidor idempotente".

---

## 6. 🧱 Service Bus en el laboratorio

```bash
az servicebus namespace create \
  --name inv-lab-sb-472913 \
  --resource-group inv-lab-rg \
  --location eastus2 \
  --sku Standard \
  --disable-local-auth true \
  --tags project=inv-lab env=lab

az servicebus topic create \
  --name inv-events \
  --namespace-name inv-lab-sb-472913 \
  --resource-group inv-lab-rg \
  --enable-duplicate-detection true

az servicebus topic subscription create \
  --name inv-projector \
  --topic-name inv-events \
  --namespace-name inv-lab-sb-472913 \
  --resource-group inv-lab-rg \
  --max-delivery-count 5 \
  --lock-duration PT1M \
  --enable-dead-lettering-on-message-expiration true
```

- `--sku Standard` elige el tier con topics al menor costo fijo.
- `--disable-local-auth true` **deshabilita las claves SAS** del namespace: solo se entra con Entra ID.
  Es la versión Service Bus del `--allow-shared-key-access false` de Storage ([`06` §8](06-almacenamiento-storage-accounts.md#8--acceso-claves-sas-y-entra-id)) y cierra
  la puerta a las connection strings con clave.
- `--enable-duplicate-detection true` activa la deduplicación por `MessageId` con la ventana por defecto
  de 10 minutos. Solo se puede decidir al crear la entidad.
- `--max-delivery-count 5` baja de 10 a 5 los intentos antes de la DLQ, para que [`L07`](l07-datos-y-eventos-cosmos-db-y-service-bus.md) vea el mensaje
  envenenado llegar a ella sin esperar diez reintentos.
- `--lock-duration PT1M` fija el lock en un minuto, en formato de duración ISO 8601.
- `--enable-dead-lettering-on-message-expiration true` manda a la DLQ los mensajes que expiran en vez de
  descartarlos en silencio.

Los permisos, con roles de datos por identidad: `inv-api-id` recibe `Azure Service Bus Data Sender`
**sobre el topic** y `inv-projector-id` recibe `Azure Service Bus Data Receiver` **sobre la
subscription**. Ninguno de los dos puede hacer lo del otro.

El consumidor en Java, con el SDK actual (`com.azure:azure-messaging-servicebus`):

```java
// Procesa la subscription con la managed identity; liquida a mano para decidir entre complete y dead-letter
ServiceBusProcessorClient processor = new ServiceBusClientBuilder()
        .fullyQualifiedNamespace("inv-lab-sb-472913.servicebus.windows.net")
        .credential(credential)
        .processor()
        .topicName("inv-events")
        .subscriptionName("inv-projector")
        .disableAutoComplete()
        .processMessage(context -> {
            try {
                projector.apply(context.getMessage());   // idempotente por MessageId (§10)
                context.complete();
            } catch (InvalidEventException e) {
                context.deadLetter();                    // no tiene arreglo: a la DLQ
            }
        })
        .processError(error -> log.warn("Service Bus: {}", error.getException().getMessage()))
        .buildProcessorClient();
```

- `fullyQualifiedNamespace(...).credential(credential)` autentica con la managed identity: no hay
  connection string en ningún lado.
- `disableAutoComplete()` desactiva la liquidación automática para que el código elija. Sin él, el SDK
  completa si el handler no lanza excepción y abandona si la lanza.
- `context.deadLetter()` manda a la DLQ un mensaje que nunca podrá procesarse (un payload inválido), en
  vez de dejar que agote los reintentos. Cualquier otra excepción no capturada hace que el SDK abandone
  el mensaje y se reintente.

> 📝 **Contexto.** El **30 de septiembre de 2026** Microsoft retira el soporte de las librerías antiguas
> de Service Bus —en Java, `com.microsoft.azure.servicebus`— y del protocolo SBMP. Siguen funcionando,
> pero sin actualizaciones ni soporte. Código Java con `com.microsoft.azure.servicebus` en una revisión
> es deuda que hay que migrar a `com.azure:azure-messaging-servicebus`.

---

## 7. 🧱 Event Grid

**El problema:** quieres reaccionar cada vez que se sube un blob, se crea un recurso o un secreto está
por expirar, sin sondear nada.

**Event Grid** es un servicio de **enrutamiento de eventos por push**:

- **fuentes**: los **system topics** los publican servicios de Azure (Storage, Key Vault, Resource
  Groups…); los **custom topics** los publica tu aplicación;
- **event subscriptions**: dicen a qué **handler** va cada evento (webhook, Function, Service Bus, Event
  Hubs, Storage Queue) con **filtros** por tipo de evento y por prefijo o sufijo del `subject`;
- **esquemas**: el propio de Event Grid o **CloudEvents 1.0**, el estándar de la CNCF, preferible para
  portabilidad.

Cuatro comportamientos que se preguntan:

- **validación del webhook**: antes de entregar nada, Event Grid exige que el endpoint pruebe que acepta
  eventos. Con el esquema de Event Grid envía un `SubscriptionValidationEvent` con un `validationCode`
  que el endpoint devuelve; con CloudEvents usa un `OPTIONS` con la cabecera `WebHook-Request-Origin`, y
  el endpoint responde con `WebHook-Allowed-Origin`. Evita que alguien use Event Grid para inundar una
  URL ajena;
- **entrega at-least-once, sin orden**: un evento puede llegar dos veces y fuera de orden;
- **reintentos**: si el handler no responde con 200–204 en 30 segundos, Event Grid reintenta con
  backoff exponencial hasta **30 intentos** o **24 horas** (1.440 minutos), lo que llegue antes. Los
  `400`, `413` y, en webhooks, `401` y `403` no se reintentan;
- **dead-letter a un blob**: desactivado por defecto; si no se configura un contenedor de Storage, el
  evento que agota los reintentos **se descarta**.

Los **namespaces** de Event Grid añaden un broker **MQTT** para dispositivos y la entrega **pull**, en
la que el consumidor pide los eventos en vez de recibirlos.

> Nunca respondas: "Event Grid garantiza el orden". Mejor: "Event Grid entrega at-least-once y sin orden
> garantizado; si necesito orden por clave, el evento dispara un mensaje a Service Bus con sesiones o
> uso Event Hubs con particiones".

> 💰 **Costo.** Event Grid cobra por operación: las primeras 100.000 al mes son gratuitas y después
> cuesta **$0.60 por millón** en `eastus2`. Un system topic no cobra por existir; por eso el drill de
> [`L00`](l00-idea-lab-practico.md) §9 es gratuito.

---

## 8. 🧱 Event Hubs

**El problema:** diez mil cajeros envían telemetría cada segundo y tres sistemas distintos tienen que
leerla, cada uno a su ritmo, y uno de ellos quiere releer el último día tras un despliegue fallido.

**Event Hubs** es una plataforma de **streaming** con el modelo de un log distribuido, como Kafka:

- un **event hub** se divide en **particiones**; los eventos con la misma partition key van a la misma
  partición y **mantienen su orden dentro de ella**;
- los **consumer groups** son vistas independientes del stream: cada sistema lee con su propio grupo y
  su propio ritmo;
- el consumidor guarda su posición con **checkpoints** (el SDK los guarda en un contenedor de Blob
  Storage); tras un reinicio, sigue desde el último;
- los eventos **no se borran al leerlos**: se conservan durante la **retención** y se pueden **releer**;
- **Capture** vuelca el stream a Blob Storage o Data Lake en Avro o Parquet, sin código;
- expone un **endpoint compatible con Kafka** (desde Standard): un productor o consumidor Kafka se
  conecta cambiando la configuración, sin reescribir el código.

| Límite | Basic | Standard | Premium |
|---|---|---|---|
| Retención máxima | 1 día | 7 días | 90 días |
| Consumer groups por event hub | 1 | 20 | 100 |
| Particiones por event hub | 32 | 32 | 100 |
| Capture | ❌ | Se paga por hora | Incluido |

> Nunca respondas: "Event Hubs es una cola". Mejor: "Event Hubs es un log particionado: los eventos no
> se borran al leerlos, cada consumer group mantiene su posición y se puede releer dentro de la
> retención. No hay DLQ, ni lock, ni liquidación por mensaje: la fiabilidad del consumidor son sus
> checkpoints".

> 💰 **Costo.** En `eastus2`, una throughput unit **Standard** cuesta **$0.03/h** —unos $22 al mes—
> más **$0.028 por millón** de eventos de entrada; Capture suma **$0.10/h**. El laboratorio no crea
> Event Hubs: lo que enseña, particiones, consumer groups y offsets, se practica con Kafka en un
> contenedor local, que es el mismo modelo.

---

## 9. ⚖ La matriz de decisión

| Criterio | Storage Queues | Service Bus | Event Grid | Event Hubs |
|---|---|---|---|---|
| Modelo | Cola | Cola y pub/sub | Enrutamiento de eventos | Log particionado |
| Entrega | Pull | Pull (con long polling) | **Push** (y pull en namespaces) | Pull |
| Garantía | At-least-once | At-least-once / at-most-once | At-least-once | At-least-once, por checkpoint |
| Orden | ❌ | FIFO por sesión | ❌ | Por partición |
| DLQ | ❌ (a mano) | ✅ por entidad | Blob, si se configura | ❌ |
| Relectura | ❌ | ❌ | ❌ | ✅ dentro de la retención |
| Mensaje máximo | 64 KB | 256 KB / 100 MB | 1 MB | 1 MB (Standard) |
| Caso típico | Trabajo en segundo plano simple | Comandos y mensajes de negocio | Reaccionar a cambios | Telemetría, streams, integración Kafka |

Y las combinaciones, que son lo habitual en producción: Event Grid avisa de un blob nuevo y lo
**encola en Service Bus** para procesarlo con reintentos y DLQ; Event Hubs recibe la telemetría y una
Function **publica en Service Bus** solo los eventos que exigen una acción.

---

## 10. 🧱 At-least-once, idempotencia y outbox

Todos los servicios del capítulo entregan **al menos una vez**. Eso tiene dos consecuencias de diseño
que se preguntan siempre:

**1. El consumidor tiene que ser idempotente.** Procesar el mismo mensaje dos veces debe dejar el mismo
estado que procesarlo una. Las técnicas:

- guardar el `MessageId` (o un id de negocio) de cada mensaje procesado en la **misma transacción** que
  el efecto, y descartar el que ya está;
- operaciones naturalmente idempotentes: "fijar el stock a 40" en vez de "restar 5", o un `upsert` con
  un id determinista (en Cosmos DB, el id del documento derivado del id del evento, [`08`](08-cosmos-db.md)).

**2. El productor no puede escribir en la base y publicar el mensaje "a la vez".** Si `inv-api` guarda
el movimiento y luego publica en Service Bus, un fallo entre los dos pasos deja un movimiento sin
evento, o un evento sin movimiento si se hace al revés. No hay transacción distribuida entre Cosmos DB y
Service Bus. La solución es el patrón **transactional outbox**:

```text
inv-api ──► Cosmos DB: [movimiento + evento "pendiente"] en la MISMA escritura transaccional
                 │
                 └── change feed ──► relay ──► Service Bus (inv-events) ──► inv-projector
                                     (reintenta hasta publicar; puede publicar dos veces
                                      → el consumidor es idempotente)
```

- el evento se guarda **junto con el dato**, en la misma partición y la misma transacción (en Cosmos DB,
  un *transactional batch* dentro de la misma partition key);
- un proceso aparte lee los eventos pendientes —en Cosmos DB, con el **change feed**— y los publica;
- si el relay publica y falla antes de marcar el evento como enviado, lo publicará otra vez: por eso el
  outbox y el consumidor idempotente van siempre juntos.

> Nunca respondas: "guardamos en la base y después publicamos el evento". Mejor: "usamos un outbox: el
> evento se escribe en la misma transacción que el dato y un relay lo publica desde el change feed; la
> publicación es at-least-once y el consumidor deduplica por id".

---

## ⚠️ Errores frecuentes

| Se dice | La versión precisa |
|---|---|
| "Service Bus garantiza exactly-once" | At-least-once con peek-lock; el exactly-once es un consumidor idempotente |
| "Duplicate detection hace idempotente al consumidor" | Deduplica envíos del productor por `MessageId`; la redelivery sigue ocurriendo |
| "Event Hubs es una cola" | Es un log particionado con retención y relectura; no hay liquidación por mensaje |
| "Event Grid garantiza orden" | At-least-once y sin orden |
| "La DLQ hay que crearla" | Existe en cada queue y subscription; lo que no hace es vaciarse sola |
| "Los mensajes expirados van a la DLQ" | Solo si se habilita el dead-lettering por expiración |
| "Receive-and-delete es más rápido y ya está" | Es at-most-once: un fallo del consumidor pierde el mensaje |
| "Si Event Grid no puede entregar, lo guarda" | Sin dead-letter configurado, lo descarta tras 24 h o 30 intentos |
| "Guardo en la base y luego publico" | Sin outbox, un fallo entre los dos pasos rompe la consistencia |

---

## 🧠 Preguntas rápidas

1. ¿Qué diferencia hay entre un comando, un evento discreto y un stream, y qué servicio de Azure corresponde a cada uno?
2. ¿Cuándo bastan Storage Queues y qué te obliga a pasar a Service Bus?
3. ¿Qué te da un topic con subscriptions que no te da una queue?
4. ¿Qué diferencia hay entre peek-lock y receive-and-delete en garantías de entrega?
5. ¿Qué pasa cuando expira el lock de un mensaje y cuándo llega el mensaje a la DLQ?
6. Tienes mensajes en la DLQ con `MaxDeliveryCountExceeded` y ninguna excepción en los logs. ¿Qué sospechas?
7. ¿Qué protege duplicate detection y qué no protege?
8. ¿Cómo consigues orden por producto en Service Bus sin procesar todo en serie?
9. ¿Por qué el laboratorio crea el namespace con `--disable-local-auth true`?
10. ¿Cómo valida Event Grid un webhook antes de entregarle eventos y por qué lo hace?
11. ¿Qué pasa con un evento de Event Grid cuyo handler está caído durante dos días?
12. ¿Qué es un consumer group en Event Hubs y qué papel tienen los checkpoints?
13. ¿Qué servicio elegirías para telemetría de diez mil cajeros que tres sistemas leen a su ritmo, y por qué no Service Bus?
14. ¿Por qué un consumidor de Service Bus tiene que ser idempotente y cómo lo haces?
15. ¿Qué problema resuelve el patrón outbox y cómo lo implementas con Cosmos DB y Service Bus?

---

## 📚 Referencias oficiales

- Elegir entre servicios de mensajería de Azure: https://learn.microsoft.com/en-us/azure/service-bus-messaging/compare-messaging-services
- Storage Queues frente a Service Bus queues: https://learn.microsoft.com/en-us/azure/service-bus-messaging/service-bus-azure-and-service-bus-queues-compared-contrasted
- ¿Qué es Azure Queue Storage?: https://learn.microsoft.com/en-us/azure/storage/queues/storage-queues-introduction
- Queues, topics y subscriptions: https://learn.microsoft.com/en-us/azure/service-bus-messaging/service-bus-queues-topics-subscriptions
- Cuotas y límites de Service Bus: https://learn.microsoft.com/en-us/azure/service-bus-messaging/service-bus-quotas
- Transferencias, locks y liquidación: https://learn.microsoft.com/en-us/azure/service-bus-messaging/message-transfers-locks-settlement
- Dead-letter queues: https://learn.microsoft.com/en-us/azure/service-bus-messaging/service-bus-dead-letter-queues
- Duplicate detection: https://learn.microsoft.com/en-us/azure/service-bus-messaging/duplicate-detection
- Sesiones: https://learn.microsoft.com/en-us/azure/service-bus-messaging/message-sessions
- Transacciones: https://learn.microsoft.com/en-us/azure/service-bus-messaging/service-bus-transactions
- Autenticar con managed identities en Service Bus: https://learn.microsoft.com/en-us/azure/service-bus-messaging/service-bus-managed-service-identity
- Deshabilitar la autenticación local en Service Bus: https://learn.microsoft.com/en-us/azure/service-bus-messaging/disable-local-authentication
- ¿Qué es Event Grid?: https://learn.microsoft.com/en-us/azure/event-grid/overview
- Entrega y reintentos de Event Grid: https://learn.microsoft.com/en-us/azure/event-grid/delivery-and-retry
- Validación de endpoints con CloudEvents: https://learn.microsoft.com/en-us/azure/event-grid/end-point-validation-cloud-events-schema
- Entrega a webhooks y validación con el esquema de Event Grid: https://learn.microsoft.com/en-us/azure/event-grid/end-point-validation-event-grid-events-schema
- ¿Qué es Event Hubs?: https://learn.microsoft.com/en-us/azure/event-hubs/event-hubs-about
- Características de Event Hubs (particiones, consumer groups, checkpoints): https://learn.microsoft.com/en-us/azure/event-hubs/event-hubs-features
- Cuotas de Event Hubs: https://learn.microsoft.com/en-us/azure/event-hubs/event-hubs-quotas
- Event Hubs para Apache Kafka: https://learn.microsoft.com/en-us/azure/event-hubs/azure-event-hubs-apache-kafka-overview
- Patrón transactional outbox con Cosmos DB: https://learn.microsoft.com/en-us/azure/architecture/databases/guide/transactional-out-box-cosmos
- `az servicebus`: https://learn.microsoft.com/en-us/cli/azure/servicebus
- Precios de Service Bus: https://azure.microsoft.com/en-us/pricing/details/service-bus/
- Precios de Event Grid: https://azure.microsoft.com/en-us/pricing/details/event-grid/
- Precios de Event Hubs: https://azure.microsoft.com/en-us/pricing/details/event-hubs/
