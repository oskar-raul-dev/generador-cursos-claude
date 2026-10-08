# 03 — Garantías, orden e idempotencia

> Lo que el broker promete y lo que no, por qué *exactly-once* no existe fuera de él, cómo
> se consigue que el efecto ocurra una sola vez, y qué hacer cuando el orden no se puede
> garantizar. **Es el capítulo más preguntado del bloque.**
> Asume leído [`02` — Brokers comparados](02-brokers-comparados.md).
>
> **Vigencia:** 2026-09-18.

---

## 1. 🎯 El problema

Tu consumidor recibe `PagoConfirmado` y carga la cuenta. El proceso muere justo después de
cargar y justo antes de confirmar el mensaje. El broker, que no recibió acuse, lo entrega
otra vez. **Has cobrado dos veces.**

Y no hay forma de evitarlo desde el broker, porque el problema no está ahí:

```text
El emisor no puede distinguir
   "no llegó"     de   "llegó y se perdió el acuse"

Ante esa duda solo hay dos opciones:
   no reintentar  → puedes perder
   reintentar     → puedes duplicar
```

No hay tercera. Todo este capítulo es cómo se vive con esa verdad.

> **Regla importante:** un fallo de entrega no significa que la operación no ocurrió.
> Significa que **no sabes** si ocurrió, y esas dos cosas se tratan distinto.

---

## 2. 📬 Las tres garantías de entrega

**Qué es.** Lo que el transporte promete sobre cuántas veces llega un mensaje.

```text
at-most-once   → 0 o 1 vez. Puede perderse. No reintentas.
at-least-once  → 1 o N veces. Puede duplicarse. Reintentas.
exactly-once   → 1 vez exacta. No existe de extremo a extremo.
```

**Cómo se elige at-most-once**, que casi nadie sabe que es una elección: confirmas el
mensaje **antes** de procesarlo. Si el proceso muere, el mensaje ya está confirmado y se
pierde. Sirve para métricas, telemetría y datos desechables donde perder uno de cada mil no
cambia nada.

**Cómo se elige at-least-once**: confirmas **después** de procesar. Si mueres entre medias,
el mensaje reaparece. Es lo que usas en el 99 % de los casos.

**Cuándo sí at-most-once.** Métricas, logs, posiciones de un cursor, cualquier dato donde
el siguiente mensaje corrige al anterior.

**Cuándo no.** Cualquier cosa que mueva dinero, estado de negocio o que alguien audite.

> **Veredicto:** el orden del acuse respecto del proceso **es** la garantía. No es
> configuración del broker: es una línea de tu código, y saberlo señalar es la respuesta
> completa.

---

## 3. 🚫 Por qué exactly-once no existe

**Qué es.** La garantía que todo el mundo quiere y que ningún sistema distribuido puede dar
de extremo a extremo, por el argumento de §1: la ambigüedad del acuse perdido es
irreducible.

**Lo que Kafka llama "exactly-once semantics" y por qué es cierto a medias.** Kafka ofrece
un productor transaccional y un ciclo consumir-procesar-producir atómico. Es real y
funciona, **dentro de Kafka**: leer de un topic, transformar y escribir en otro puede ser
atómico porque el offset y el mensaje de salida viven en el mismo sistema.

```text
Kafka → Kafka          ✅ exactly-once real: offset y salida en el mismo commit
Kafka → tu base de datos  ❌ dos sistemas, dos commits, ventana entre ambos
Kafka → API de terceros   ❌ ni siquiera hay commit que coordinar
```

- En cuanto el efecto **sale** del broker, vuelves a at-least-once.
- Y casi todos los efectos que importan salen: escribir en tu base de datos, llamar a una
  pasarela, mandar un correo.

**Lo que sí existe: *effectively-once*.** El mensaje llega varias veces y **el efecto
observable ocurre una sola**. Es at-least-once más idempotencia en el consumidor, y es la
respuesta correcta a la pregunta.

> ⚠️ **Advertencia.** Decir "uso exactly-once" sin el matiz es de las respuestas que más
> rápido te descalifican. Di **"at-least-once más idempotencia en el consumidor"** y habrás
> contestado entero.

> **Veredicto:** exactly-once no es una casilla que marcar, es una propiedad que construyes
> en el consumidor. El broker te da la mitad; la otra mitad es tuya.

---

## 4. 🔑 Idempotencia: las cuatro formas

**Qué es.** Que procesar N veces tenga el mismo efecto que procesar una. **Es el permiso
para reintentar**, y sin ella nada de lo que hay en
[`01-bases/09`](../01-bases/09-resiliencia.md) se puede aplicar.

Las cuatro formas, de más elegante a más mecánica:

**1. Reformular la operación.** La mejor y la que nadie propone primero.

```text
"sumar 100 al saldo"      → NO idempotente
"fijar el saldo en 1100"  → idempotente, pero introduce carrera entre concurrentes
"registrar el movimiento 7f3a con importe 100" → idempotente Y concurrente
```

- La tercera es cómo funciona la contabilidad real: **el asiento es el hecho, el saldo es
  el resultado**. Reintentar inserta el mismo id, viola la restricción única y no hace nada.

**2. Clave de idempotencia.** El emisor genera un identificador por **intención**; el
receptor guarda clave → resultado y ante una repetición devuelve el resultado guardado.

- Que la genere el emisor es lo esencial: solo él sabe si "cobrar 100" es un intento nuevo
  o un reintento.
- Es el estándar de las APIs de pago, con la cabecera `Idempotency-Key`.

**3. Deduplicación por identificador de mensaje.** Una tabla de ids procesados con TTL.
Funciona y es lo que más se implementa, pero es la que más cuidado requiere: ver §5.

**4. Comprobación de estado.** *"Si el pedido ya está `ENVIADO`, no hagas nada."* Barata y
suficiente cuando la operación es una transición de estado, y frágil cuando hay varios
caminos al mismo estado.

**Cuándo sí.** Siempre en un consumidor de eventos. No es opcional.

**Cuándo no.** Nunca "no". Lo que sí varía es **cuál** de las cuatro: si puedes reformular,
reformula; si no, clave de idempotencia; si tampoco, deduplicación.

> **Veredicto:** la pregunta de entrevista no es "¿qué es idempotencia?" sino "¿cómo la
> implementarías aquí?". Tener las cuatro formas ordenadas es lo que distingue la respuesta.

---

## 5. ⚛️ La deduplicación debe ser atómica con el efecto

**Qué es.** El detalle que casi nadie menciona y que convierte una deduplicación correcta
en una fuente de errores silenciosos.

```text
MAL:  marcar id como procesado  (commit)
      ... el proceso muere aquí ...
      escribir el resultado     (nunca ocurre)
      → el efecto no ocurrió y el mensaje está marcado. Perdido para siempre.

MAL:  escribir el resultado     (commit)
      ... el proceso muere aquí ...
      marcar id como procesado  (nunca ocurre)
      → al reintentar, se procesa dos veces.

BIEN: escribir el resultado Y marcar el id EN LA MISMA TRANSACCIÓN
```

- Con una base de datos relacional es directo: inserta la fila de dedupe y el efecto en la
  misma `@Transactional`, y deja que la restricción única haga el trabajo.
- **Si el efecto es externo** —una llamada a un tercero, un correo— no hay transacción
  posible, y entonces el patrón se invierte: registrar la intención, llamar, registrar el
  resultado, y un proceso de conciliación para los casos que quedaron ambiguos.

> 🩺 **Diagnóstico.** Ante duplicados en producción, lo primero que miro es si la marca de
> "procesado" y el efecto comparten transacción. Es la causa más frecuente y la que menos
> se sospecha, porque el código *parece* correcto.

> **Veredicto:** deduplicar en una transacción distinta del efecto no es deduplicar: es
> mover el problema de "procesa dos veces" a "no procesa ninguna", que es peor porque no
> deja rastro.

---

## 6. 🔢 Orden: lo que se puede y lo que no

**Qué es.** El orden global no existe en un sistema distribuido con varias particiones. Lo
que existe es **orden por clave**.

**Cómo se consigue.** Envías todos los eventos de una entidad a la misma partición usando
su identificador como clave: `key = pedidoId`. Dentro de esa partición, el orden está
garantizado.

**Lo que eso cuesta:**

- **Partición caliente.** Una clave con mucho tráfico —un cliente que concentra el 30 % de
  los eventos, o una clave de baja cardinalidad como el país— satura a un consumidor
  mientras los demás están ociosos.
- **Techo de paralelismo.** Ya está en [`02` §2](02-brokers-comparados.md#2-️-kafka-el-log-particionado):
  el paralelismo máximo es el número de particiones.
- **Rigidez.** Cambiar el número de particiones cambia la asignación clave→partición para
  los mensajes futuros, y el orden se rompe en la transición.

**Cuándo sí.** Cuando la secuencia importa de verdad: transiciones de estado de una misma
entidad, movimientos de una misma cuenta.

**Cuándo no.** Cuando puedes diseñar el consumidor para no necesitarlo — que es casi
siempre, y es la respuesta que más puntúa. Ver §7.

> **Veredicto:** el orden es una restricción que se paga en paralelismo. Antes de exigirlo,
> pregúntate si el consumidor no podría tolerarlo, porque tolerarlo sale mucho más barato.

---

## 7. 🛡️ Consumidores que no necesitan orden

**Qué es.** El diseño que hace irrelevante el problema anterior, y la respuesta fuerte a
*"¿cómo garantizas el orden?"*.

**1. Versión o marca de tiempo en el evento.** El consumidor guarda la versión del último
estado aplicado por entidad y **descarta lo más viejo**.

```java
// El evento llega desordenado; la versión decide si aplica
if (evento.version() <= proyeccion.version()) return;   // llegó tarde: se ignora
proyeccion.aplicar(evento);
```

- Es idempotente **y** tolerante al desorden a la vez, con un solo campo.
- Requiere que el productor lleve una versión monótona por entidad, que casi siempre ya
  existe (el número de versión del agregado).

**2. Operaciones conmutativas.** Eventos que dan el mismo resultado en cualquier orden:
incrementos, uniones de conjuntos. Funciona en contadores y poco más.

**3. Reconciliación periódica.** Aceptas el desorden y un proceso corrige después. En banca
es lo normal: **la consistencia la garantiza la conciliación, no el transporte**.

**Cuándo sí.** Proyecciones, cachés, vistas de lectura, cualquier consumidor cuyo trabajo
sea reflejar un estado.

**Cuándo no.** Cuando el consumidor ejecuta efectos irreversibles que dependen del orden —
enviar el correo de "pedido enviado" antes que el de "pedido confirmado" queda mal y no se
arregla con una versión.

> **Veredicto:** la mejor solución al problema del orden es no tenerlo. Un consumidor con
> versión es más simple, escala mejor y sobrevive a un cambio de particiones.

---

## 8. 🧭 Cómo se elige

```text
¿El dato es desechable y el siguiente mensaje corrige al anterior?
    → at-most-once: confirma antes de procesar. Es una decisión, no un descuido.

En todo lo demás → at-least-once, y el consumidor idempotente. ¿Cómo?
    ¿Puedes reformular la operación como un hecho con id?   → hazlo. Es la mejor.
    ¿Es una API y el cliente puede generar un id?            → clave de idempotencia
    ¿Ninguna de las dos?                                     → dedupe por id de mensaje
       → y ENTONCES: ¿la marca va en la misma transacción que el efecto? Si no, vuelve.

¿Necesitas orden?
    ¿De verdad, o el consumidor podría tolerarlo con una versión? → versión, casi siempre
    ¿De verdad de verdad?  → clave de partición por entidad, y asume el techo de paralelismo
```

---

## ⚠️ Errores frecuentes

| Se dice | Lo preciso |
|---|---|
| "Uso exactly-once" | No existe fuera del broker; es at-least-once + idempotencia |
| "Kafka garantiza exactly-once" | Solo Kafka→Kafka; en cuanto el efecto sale, vuelve at-least-once |
| "Kafka garantiza el orden" | Dentro de una partición, nunca globalmente |
| "Dedupe con una tabla de ids" | Y en la **misma transacción** que el efecto, o falla silenciosamente |
| "Un fallo de entrega significa que no llegó" | Significa que **no sabes** si llegó |
| "Reintento y ya" | Solo si la operación es idempotente; si no, duplicas |
| "Pongo la clave de partición al azar para repartir" | Entonces renunciaste al orden; dilo explícitamente |

---

## 📚 Para profundizar

- **Libro** — Martin Kleppmann, *Designing Data-Intensive Applications* (O'Reilly, 2017).
  Capítulos 8 y 9: los problemas de los sistemas distribuidos y el límite teórico del
  exactly-once. **Es el libro de este capítulo.**
- **Libro** — Neha Narkhede, Gwen Shapira y Todd Palino, *Kafka: The Definitive Guide*,
  2ª ed. (O'Reilly, 2021). Capítulo 8: entrega, transacciones y qué significa exactamente
  el exactly-once de Kafka.
- **Libro** — Adam Bellemare, *Building Event-Driven Microservices* (O'Reilly, 2020).
  Capítulo 12: consumidores idempotentes y tolerancia al desorden.
- [Apache Kafka — Message Delivery Semantics](https://kafka.apache.org/documentation/#semantics):
  la explicación del propio proyecto, incluido el alcance real de sus transacciones.
- [Apache Kafka — Consumer Position](https://kafka.apache.org/documentation/#design_consumerposition):
  por qué el offset lo lleva el consumidor y qué implica para la entrega.
- [Amazon SQS — Visibility timeout](https://docs.aws.amazon.com/AWSSimpleQueueService/latest/SQSDeveloperGuide/sqs-visibility-timeout.html):
  el mecanismo concreto por el que SQS produce duplicados.
- **Video** — GOTO Conferences, charlas de Martin Kleppmann sobre garantías de entrega y
  exactly-once. Búscalas por título.

---

## 🧠 Preguntas

Sin respuestas aquí. Todas, con enunciado literal y respuesta en tres capas, en
[`10` — Respuestas](10-respuestas.md).

1. ¿Qué tres garantías de entrega existen? 🟢
2. ¿Qué significa *effectively-once*? 🟢
3. Nombra las cuatro formas de conseguir idempotencia. 🟢
4. ¿En qué unidad garantiza Kafka el orden? 🟢
5. ¿Qué línea de tu código decide si la entrega es at-most-once o at-least-once? 🟡
6. ¿Por qué el emisor no puede distinguir "no llegó" de "se perdió el acuse"? 🟡
7. ¿En qué caso el exactly-once de Kafka sí es real? 🟡
8. ¿Quién genera la clave de idempotencia y por qué? 🟡
9. ¿Qué es una partición caliente y qué la causa? 🟡
10. ¿Cuándo at-most-once es una elección correcta? 🟡
11. ¿Por qué "un fallo de entrega" no significa que la operación no ocurrió? 🟠
12. ¿Por qué la marca de deduplicación debe ir en la misma transacción que el
    efecto? 🟠
13. ¿Qué pasa si marcas primero y el proceso muere antes de escribir? 🟠
14. ¿Cómo diseñas un consumidor que tolere el desorden? 🟠
15. Reformula "sumar 100 al saldo" para que sea idempotente **y** soporte
    concurrencia. 🟠
16. ¿Qué cuesta exigir orden por clave? 🟠
17. ¿Qué haces con la idempotencia cuando el efecto es una llamada externa y no
    hay transacción? 🟠
18. ¿Por qué "pongo la clave al azar para repartir mejor" es una decisión y no
    un detalle? 🟠
19. Tu consumidor procesa duplicados en producción. Da tres hipótesis en orden
    de probabilidad. 🔴
20. Diseña el consumidor idempotente de `PagoConfirmado` que carga una cuenta:
    tablas, transacción y qué pasa en cada punto de fallo. 🔴
21. Un consumidor nuevo reprocesa seis meses de eventos y dispara correos a
    clientes. Reconstruye qué faltó en el diseño. 🔴
22. Te piden "garantía de orden total de todos los eventos del sistema".
    Responde: qué cuesta, qué alternativa propones y cómo lo argumentas. 🔴

---

**Anterior:** [`02` — Brokers comparados](02-brokers-comparados.md) ·
**Siguiente:** [`04` — Colas, DLQ y reintentos](04-colas-dlq-y-reintentos.md) ·
**Relacionado:** [`06` — Outbox y CDC](06-outbox-y-cdc.md)
