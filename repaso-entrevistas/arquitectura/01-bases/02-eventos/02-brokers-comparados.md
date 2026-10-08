# 02 — Brokers comparados

> Kafka, RabbitMQ, SQS/SNS e IBM MQ: qué modelo de datos tiene cada uno, qué puedes y qué
> no puedes hacer con él, y el criterio para elegir. El objetivo no es saber configurarlos,
> es saber **por qué la elección cambia el diseño**.
> Asume leído [`01` — Fundamentos de EDA](01-fundamentos-eda.md).
>
> **Vigencia:** 2026-09-18.

---

## 1. 🎯 El problema

*"¿Kafka o RabbitMQ?"* es la pregunta, y la respuesta mala es una lista de features. La
buena empieza por la diferencia estructural, que cabe en cuatro líneas:

```text
Cola      → el mensaje se CONSUME y desaparece. Un trabajo, un trabajador.
            El broker lleva la cuenta de qué se entregó.

Log       → el mensaje se LEE y se queda. Muchos lectores, cada uno con su posición.
            El consumidor lleva la cuenta de por dónde va.
```

De esa diferencia sale todo lo demás: si puedes releer el pasado, si puedes añadir un
consumidor nuevo que procese lo viejo, cuántos consumidores caben, y si el orden se
garantiza o no.

> **Regla de entrevista:** RabbitMQ y SQS son colas; Kafka es un log. No es "uno es más
> moderno": son estructuras de datos distintas con consecuencias distintas.

---

## 2. 🗂️ Kafka: el log particionado

**Qué es.** Un log de solo-anexado, dividido en **particiones**, replicado entre *brokers*
y retenido por tiempo o por tamaño. El consumidor guarda su **offset**: dónde se quedó.

```text
topic inv-events
 ├ partición 0: [e0][e1][e2][e3]...      ← orden garantizado AQUÍ dentro
 ├ partición 1: [e0][e1][e2]...
 └ partición 2: [e0][e1][e2][e3][e4]...

grupo "facturacion"  → offset propio   ┐
grupo "analitica"    → offset propio   ┘ leen lo mismo, sin estorbarse
```

- **La partición es la unidad de orden y de paralelismo.** El orden solo existe dentro de
  una partición, y el reparto lo decide la clave del mensaje.
- **El grupo de consumidores es la unidad de reparto.** Cada partición se asigna a un solo
  consumidor del grupo; por eso **el paralelismo máximo es el número de particiones**.
- **Leer no borra.** Otro grupo lee lo mismo desde el principio sin que el primero se
  entere. Es lo que hace posible añadir un consumidor nuevo que procese el histórico.
- **La retención es por tiempo o tamaño**, no por consumo. Con `compact` conservas el
  último valor por clave indefinidamente, que es lo que sostiene la transferencia de estado.

**Cuándo sí.** Volumen alto, varios consumidores independientes del mismo flujo,
necesidad de releer o de reconstruir un estado, *streaming* y proyecciones.

**Cuándo no.** Cuando necesitas enrutamiento complejo por contenido, prioridades por
mensaje, o reintento individual con retardo por mensaje: Kafka no tiene nada de eso de
forma nativa y emularlo duele. Tampoco cuando tienes cinco mensajes por segundo y un solo
consumidor: es una infraestructura cara de operar para eso.

> 💰 **Costo.** Kafka en producción no es una dependencia, es un sistema distribuido: ZooKeeper
> o KRaft, particiones que hay que dimensionar de antemano, rebalanceos que paran el
> consumo, y un equipo que sepa diagnosticarlo a las tres de la mañana.

> **Veredicto:** Kafka se elige por **releer y por escalar lecturas independientes**, no
> por velocidad. Si solo necesitas repartir trabajo entre trabajadores, es un cañón.

---

## 3. 🐰 RabbitMQ: el enrutador

**Qué es.** Un broker de colas con un mecanismo de enrutamiento delante: el productor
publica en un **exchange**, y este decide en qué colas cae según el tipo y la clave.

```text
productor → exchange (topic) ──"pedido.confirmado"──► cola facturacion
                             ├─"pedido.*"───────────► cola analitica
                             └─"*.rechazado"────────► cola alertas
```

- **Cuatro tipos de exchange**: `direct` (clave exacta), `topic` (patrón con comodines),
  `fanout` (a todas) y `headers` (por cabeceras). Es enrutamiento **declarativo**, sin
  escribir código.
- **El mensaje se consume y desaparece**, con acuse explícito (`ack`). Si el consumidor
  muere sin confirmar, el mensaje vuelve a la cola.
- **Tiene lo que a Kafka le falta**: prioridades, TTL por mensaje, colas de retardo con
  exchanges de dead-letter, reintento individual.

**Cuándo sí.** Reparto de trabajo, enrutamiento por contenido, prioridades, flujos
request-reply, y cuando el volumen es moderado y quieres algo operable por un equipo
normal.

**Cuándo no.** Cuando necesitas releer el histórico —una vez consumido, no está—, o cuando
el volumen es muy alto y sostenido: acumular millones de mensajes en una cola degrada el
broker, porque las colas están pensadas para vaciarse.

> **Veredicto:** RabbitMQ es la opción correcta más veces de las que se admite, y se
> descarta por moda. Si tu caso es "repartir trabajo con enrutamiento", Kafka te sobra.

---

## 4. ☁️ SQS y SNS: las piezas gestionadas

**Qué es.** Dos servicios separados que se combinan, y esa separación es lo que se
pregunta:

```text
SNS → pub/sub. Un tópico, muchos suscriptores. NO almacena: si nadie escucha, se pierde.
SQS → cola. Un consumidor por mensaje. SÍ almacena, con reintento y DLQ.

Patrón canónico: SNS ──fan-out──► varias colas SQS, una por consumidor
```

- **`fanout` de SNS a SQS** es cómo se hace pub/sub durable en AWS: SNS reparte, y cada
  cola SQS da durabilidad y reintento a su consumidor.
- **`visibility timeout`** es el mecanismo central de SQS: al recibir un mensaje se oculta
  durante N segundos; si el consumidor no lo borra en ese plazo, reaparece. Por eso el
  timeout debe ser mayor que el tiempo de proceso, o **el mismo mensaje se procesa dos
  veces en paralelo**.
- **Dos sabores de cola**: `standard` (at-least-once, sin orden, escala sin límite
  práctico) y `FIFO` (orden y deduplicación dentro de un grupo, con throughput acotado).

**Cuándo sí.** Ya estás en AWS, el volumen es moderado, y quieres cero operación. Es
donde SQS gana a todo lo demás: no hay nada que administrar.

**Cuándo no.** Cuando necesitas releer, *streaming*, o un throughput por clave que FIFO no
da. Y cuando el vendor lock-in importa.

> ⚠️ **Advertencia.** SNS sin SQS detrás **pierde mensajes** si el suscriptor está caído.
> Es el error de diseño más común en AWS y no da error: simplemente el consumidor no se
> entera de lo que pasó mientras estuvo fuera.

> **Veredicto:** SQS y SNS son piezas, no un broker. La decisión no es "SQS o Kafka", es
> "¿necesito releer y proyectar, o solo entregar?".

---

## 5. 🏛️ IBM MQ: el que hay en el banco

**Qué es.** Colas transaccionales, punto a punto, con décadas en producción. No se elige
hoy para un sistema nuevo, **pero en banca se hereda** y hay que saber operarlo.

**Lo que aporta y casi nadie más tiene**: participación en **transacciones XA de dos
fases**, de modo que poner un mensaje en la cola y escribir en la base de datos pueden ser
atómicos de verdad. Es la razón por la que sigue vivo en core bancario.

**Lo que cuesta.** XA es lento, bloquea recursos, y su recuperación ante fallo es el
territorio donde nadie quiere estar. Por eso el mundo se movió a outbox más idempotencia,
que da garantías parecidas sin coordinador distribuido.

**Cuándo sí.** Está ahí y hay que integrarse. Se ve en
[`05-banca/02`](../05-banca/).

**Cuándo no.** Sistema nuevo, aunque sea en banca: hoy se resuelve con outbox.

> **Veredicto:** MQ es la respuesta correcta a una pregunta que ya casi nadie hace. Saber
> por qué existía —XA— y por qué se dejó de usar vale más que saber configurarlo.

---

## 6. ⚖️ La comparación que se pregunta

| | Kafka | RabbitMQ | SQS + SNS | IBM MQ |
|---|---|---|---|---|
| Estructura | Log particionado | Colas con exchange | Colas + tópico | Colas |
| Releer el pasado | ✅ | ❌ | ❌ | ❌ |
| Varios consumidores del mismo flujo | ✅ grupos | ✅ vía exchange | ✅ vía SNS→SQS | ❌ |
| Enrutamiento por contenido | ❌ | ✅ | Parcial | ❌ |
| Orden | Por partición | Por cola | Solo FIFO | Por cola |
| Prioridades y TTL por mensaje | ❌ | ✅ | ❌ | ✅ |
| Transacción XA | ❌ | ❌ | ❌ | ✅ |
| Operación | Alta | Media | Ninguna | Alta |

---

## 7. 🧭 Cómo se elige

```text
¿Necesitas releer el histórico, o que un consumidor nuevo procese lo viejo?
    → Kafka. Es lo único de la lista que lo da. Todo lo demás es secundario.

¿Necesitas enrutar por contenido, priorizar o reintentar con retardo por mensaje?
    → RabbitMQ. Kafka no lo tiene y emularlo es peor que cambiar de broker.

¿Estás en AWS, el volumen es moderado y no quieres operar nada?
    → SNS → SQS. Y nunca SNS solo.

¿Es un core bancario que ya tiene colas y transacciones XA?
    → MQ, y se integra con capa anticorrupción. No se sustituye por gusto.

¿Cinco mensajes por segundo y un consumidor?
    → La tabla de la base de datos que ya tienes, con un poller. En serio.
```

> **Regla de entrevista:** la última línea es la que más puntúa. Proponer una tabla con un
> `estado` y un proceso que la recorre, cuando el volumen lo permite, demuestra que sabes
> lo que cuesta un broker.

---

## ⚠️ Errores frecuentes

| Se dice | Lo preciso |
|---|---|
| "Kafka es una cola" | Es un log: leer no borra, y el consumidor lleva su propio offset |
| "Kafka es más rápido" | Es más **escalable en lectura y releíble**; latencia por mensaje no es su ventaja |
| "Con SNS ya tengo pub/sub durable" | SNS no almacena: sin SQS detrás, un suscriptor caído pierde mensajes |
| "Añado consumidores para ir más rápido" | El techo es el número de particiones; el resto queda ocioso |
| "Pongo más particiones y listo" | Cambia el reparto por clave y no se puede reducir después |
| "SQS garantiza orden" | Solo las colas FIFO, y con throughput acotado |
| "RabbitMQ está obsoleto" | Es la opción correcta para repartir trabajo con enrutamiento |

---

## 📚 Para profundizar

- **Libro** — Neha Narkhede, Gwen Shapira y Todd Palino, *Kafka: The Definitive Guide*,
  2ª ed. (O'Reilly, 2021). Capítulos 1 a 4: el modelo de particiones, productores y grupos
  de consumidores. **Es el libro de este capítulo.**
- **Libro** — Gregor Hohpe y Bobby Woolf, *Enterprise Integration Patterns*
  (Addison-Wesley, 2003). Capítulo 4: canal punto a punto contra canal publish-subscribe,
  que es la distinción de §1 con veinte años de antigüedad.
- **Libro** — Martin Kleppmann, *Designing Data-Intensive Applications* (O'Reilly, 2017).
  Capítulo 11, sección "Partitioned Logs": por qué un log es distinto de una cola.
- [Apache Kafka — Documentation](https://kafka.apache.org/documentation/): la referencia,
  y en particular la sección de diseño sobre la posición del consumidor.
- [RabbitMQ — AMQP 0-9-1 Model Explained](https://www.rabbitmq.com/tutorials/amqp-concepts):
  exchanges, bindings y tipos de enrutamiento en una página.
- [Amazon SQS — Visibility timeout](https://docs.aws.amazon.com/AWSSimpleQueueService/latest/SQSDeveloperGuide/sqs-visibility-timeout.html):
  el mecanismo que explica los duplicados de SQS.
- [Amazon SQS — FIFO queues](https://docs.aws.amazon.com/AWSSimpleQueueService/latest/SQSDeveloperGuide/sqs-fifo-queues.html):
  qué garantiza exactamente y a qué throughput.
- **Video** — Confluent y GOTO Conferences, charlas de Gwen Shapira sobre el modelo de
  particiones de Kafka. Búscalas por título.

---

## 🧠 Preguntas

Sin respuestas aquí. Todas, con enunciado literal y respuesta en tres capas, en
[`10` — Respuestas](10-respuestas.md).

1. ¿Cuál es la diferencia estructural entre una cola y un log? 🟢
2. ¿Qué es una partición en Kafka y para qué sirve? 🟢
3. ¿Qué es un grupo de consumidores? 🟢
4. ¿Qué cuatro tipos de exchange tiene RabbitMQ? 🟢
5. ¿Qué hace SNS y qué hace SQS? 🟢
6. ¿Por qué en Kafka leer no borra el mensaje? 🟡
7. ¿Qué es el offset y quién lo guarda? 🟡
8. ¿Qué es el visibility timeout de SQS y qué pasa si es muy corto? 🟡
9. ¿Por qué SNS sin SQS detrás pierde mensajes? 🟡
10. ¿Qué diferencia hay entre una cola standard y una FIFO en SQS? 🟡
11. ¿Qué aporta IBM MQ que ningún otro de la lista da? 🟡
12. ¿Qué es la compactación de log y para qué se usa? 🟡
13. ¿Qué limita el paralelismo de un grupo de consumidores en Kafka? 🟠
14. ¿Cuándo RabbitMQ es mejor elección que Kafka? 🟠
15. ¿Por qué no se pueden reducir las particiones de un topic? 🟠
16. ¿Por qué acumular millones de mensajes en RabbitMQ degrada el broker? 🟠
17. ¿Por qué el mundo dejó XA y se fue a outbox más idempotencia? 🟠
18. ¿Cuándo NO usarías ningún broker? 🟠
19. Necesitas prioridades y reintento con retardo por mensaje. ¿Qué broker y
    por qué el otro no sirve? 🟠
20. Un consumidor nuevo tiene que procesar los últimos seis meses de eventos.
    ¿Qué broker lo permite y qué hace falta haber configurado? 🟠
21. Diseña el transporte para: pedidos confirmados que consumen facturación,
    inventario y analítica, con analítica reprocesando el histórico cada mes.
    Elige broker y justifica. 🔴
22. En AWS, tus consumidores procesan mensajes duplicados en paralelo.
    Reconstruye qué pasó y cómo lo arreglas. 🔴
23. Te piden migrar de RabbitMQ a Kafka "porque escala más". ¿Qué preguntas
    antes y en qué casos dirías que no? 🔴

---

**Anterior:** [`01` — Fundamentos de EDA](01-fundamentos-eda.md) ·
**Siguiente:** [`03` — Garantías, orden e idempotencia](03-garantias-orden-e-idempotencia.md) ·
**Relacionado:** [`01-bases/08` — Comunicación e integración](../01-bases/08-comunicacion-e-integracion.md)
