# 06 — Mensajería y eventos

> Cómo se integran dos servicios por mensajes sin inventarse garantías que no existen: comando contra
> evento, lo que el broker te da y lo que no, consumidor idempotente, DLQ y lag. Asume leído
> [`01`](01-estilos-de-comunicacion.md). La teoría de EDA, event sourcing y la comparativa profunda
> de brokers son del bloque
> [`02-eventos`](../../01-bases/02-eventos/) del corpus de arquitectura: aquí
> se integra y se implementa.
>
> **Vigencia:** 2026-09-29.

---

## 1. 🎯 El problema

`orders` confirma un pedido y quiere que `inventory` reserve. Pone una cola en medio y el problema
del acoplamiento temporal desaparece. Pero aparecen otros cuatro que nadie mencionó en la reunión:

```text
El mensaje llegó dos veces          → se reservó dos veces
El mensaje llegó desordenado        → se liberó antes de reservar
El consumidor falla siempre con ese → bloquea la cola, o la llena de basura
Nadie consumió el mensaje           → el pedido quedó a medias y no hay error en ningún log
```

Los cuatro tienen la misma raíz: **la mensajería cambia el modo de fallo, no lo elimina**. En
síncrono, el fallo te lo cuentan en la cara y se ve en el log del que llamó. En asíncrono, el fallo es
silencioso y aparece como "falta algo", horas después y en otro sitio.

Este capítulo va de esos cuatro problemas y de lo que hay que construir para que no sean incidentes.

---

## 2. 🧱 Comando contra evento

**Qué es.** La distinción que más rinde de todo el bloque, y la que ordena el resto de decisiones.

```text
Comando  ReserveInventory   destinatario conocido, se espera un efecto
                            si nadie lo consume, el flujo está roto
Evento   OrderPlaced        un hecho ya ocurrido, sin destinatario
                            si nadie lo consume, no pasa nada
```

**Cómo va.** El comando va a una **cola**: un destinatario, y la acumulación es visible si nadie
consume. El evento va a un **topic**: varios consumidores independientes, cada uno con su propio
avance, y añadir uno nuevo no toca al emisor.

La consecuencia de diseño: `orders` no debería publicar `ReserveInventory`. Debería publicar
`OrderPlaced` y dejar que `inventory` decida que eso significa reservar. Si mañana el negocio
cambia y hay que reservar solo para ciertos clientes, esa regla vive en `inventory`, que es su
dueño, y `orders` no se entera.

**Cuánto.** El evento cuesta que nadie tenga el estado global del flujo: para saber por qué no se
reservó hay que ir a mirar al consumidor. El comando cuesta acoplamiento: el emisor sabe quién tiene
que actuar.

**Cuándo sí y cuándo no.** Comando cuando de verdad hay un destinatario y una orden —normalmente en
una saga orquestada
([`03-datos-y-consistencia/03`](../03-datos-y-consistencia/03-saga.md))—. Evento para todo lo demás.

> **Veredicto:** si sabes quién tiene que reaccionar y qué tiene que hacer, es un comando aunque lo
> publiques en un topic. Ponerle nombre de evento a un comando no desacopla nada: solo esconde el
> acoplamiento y empeora el diagnóstico.

---

## 3. 🧱 Lo que el broker te da, y lo que no

**Qué es.** Las garantías reales, que casi nunca coinciden con las que la gente cree tener.

| Lo que la gente cree | Lo que hay de verdad |
|---|---|
| "Entrega exactamente una vez" | **Al-menos-una-vez**. Habrá duplicados: es un hecho de diseño, no un fallo |
| "Los eventos llegan en orden" | En orden **dentro de la unidad de particionado**. Entre particiones, no hay orden |
| "Si falla, el broker lo reintenta y ya" | Reintenta, sí; y si el fallo es determinista, reintentará para siempre |
| "El mensaje está a salvo cuando lo publico" | Solo si se confirmó la escritura con la durabilidad que hayas configurado |

**Cómo va.** El *exactly-once* de extremo a extremo no existe porque el consumidor y su efecto están
en sistemas distintos: entre procesar y confirmar siempre hay una ventana. Lo que sí existe es
**al-menos-una-vez más un consumidor idempotente**, que es funcionalmente equivalente y es lo que se
construye.

El orden se garantiza dentro de la partición o de la cola ordenada, y la clave de particionado es una
decisión de diseño: si todo lo de `ORD-00042` va a la misma partición, los eventos de ese pedido
llegan ordenados entre sí, aunque no respecto a otros pedidos. Eso casi siempre es suficiente, y el
coste de querer más es perder paralelismo.

> **⚠️ Advertencia:** cuando alguien diga "usamos exactly-once", la pregunta correcta no es si mienten
> —a veces su plataforma sí lo da dentro de sus fronteras— sino **dónde termina esa garantía**. En
> cuanto el efecto sale del sistema del broker —una base de datos, una llamada a un tercero—, vuelves
> a al-menos-una-vez.

---

## 4. 🧱 El consumidor idempotente

**Qué es.** Un consumidor que, si procesa el mismo mensaje dos veces, produce el mismo resultado que
si lo hubiera procesado una.

**Cómo va.** Tres formas, de menor a mayor coste:

| Forma | Cómo | Cuándo aplica |
|---|---|---|
| **Operación naturalmente idempotente** | "Poner el estado a `PAID`" en vez de "sumar 1" | Cuando la operación se puede expresar como un estado final |
| **Clave única en la base de datos** | Insertar con clave `(order_id, type)`; el duplicado falla | Cuando lo que se crea tiene identidad propia |
| **Tabla de mensajes procesados** | Registrar el identificador del mensaje al procesarlo, en la misma transacción | El caso general: funciona siempre |

La tercera es el **inbox**, y su detalle —qué columnas, qué retención, qué pasa si el efecto no es
transaccional— se desarrolla en
[`03-datos-y-consistencia/04`](../03-datos-y-consistencia/04-outbox-inbox-e-idempotencia.md). Lo que importa aquí es la regla de
entrada: **la deduplicación y el efecto tienen que ocurrir en la misma transacción**. Si se registran
por separado, hay una ventana donde el efecto se aplicó y la marca no se escribió.

**Cuánto.** Cuesta una tabla, un índice y una política de retención. Y cuesta pensar la clave: si es
el identificador del mensaje, un reenvío manual con identificador nuevo se procesa otra vez; si es una
clave de negocio, eso no pasa.

**Cuándo sí.** Siempre. No hay consumidor que no lo necesite.

> **Veredicto:** al-menos-una-vez más idempotencia es el único diseño que aguanta. Y se dice así en
> una entrevista: "asumo duplicados y hago el consumidor idempotente" puntúa mucho más que "configuro
> exactly-once".

---

## 5. 🧱 Reintentos, DLQ y el mensaje envenenado

**Qué es.** Qué se hace con un mensaje que falla, y cómo se evita que bloquee a todos los demás.

**Cómo va.** El camino completo de un mensaje que falla:

```text
mensaje ──► consumidor ──falla──► reintento inmediato (1-2 veces)
                                     │ sigue fallando
                                     ▼
                              cola de reintento con espera (segundos, minutos)
                                     │ agota intentos
                                     ▼
                              DLQ ──► alerta ──► decisión humana ──► reproceso o descarte
```

- **El reintento inmediato** solo vale para fallos transitorios: un timeout, una conexión perdida.
- **La cola de reintento con espera** evita el bucle rápido: si la base de datos está caída, insistir
  cada milisegundo no ayuda a nadie.
- **La DLQ** es el final del camino automático. Lo importante: **una DLQ sin alerta es un agujero
  negro**. El mensaje deja de bloquear y nadie se entera de que se perdió el efecto.

El **mensaje envenenado** es el que falla siempre por su contenido —un campo imposible, un dato que
rompe una invariante—. Sin DLQ, ese mensaje se reintenta para siempre y, en una cola ordenada,
bloquea todo lo que viene detrás. Es el fallo que convierte un dato malo en una caída del flujo.

**Cuánto.** La DLQ cuesta una cola más, una alerta, un panel y un procedimiento de reproceso. Se paga
la primera vez que hay que reinyectar doscientos mensajes sin reprocesar los que ya se aplicaron.

> **💡 Truco:** el procedimiento de reproceso se escribe **antes** de necesitarlo, y se prueba una vez.
> El día del incidente, la pregunta "¿cómo reinyecto esto sin duplicar efectos?" tiene una única
> respuesta válida: "porque el consumidor es idempotente, puedo reinyectar sin más".

---

## 6. 🩺 El lag del consumidor

**Qué es.** Cuántos mensajes hay publicados que ese consumidor todavía no ha procesado. Es **la**
métrica de un sistema asíncrono.

**Cómo va.** El lag traduce a lenguaje de producto: un lag de 50 000 mensajes con un consumo de 500
por segundo son cien segundos de retraso, y eso significa que el usuario lleva cien segundos viendo
su pedido "en proceso".

| Síntoma | Causa típica | Qué mirar |
|---|---|---|
| Lag que crece linealmente | El consumidor no da abasto | Tiempo por mensaje, y si hay una dependencia lenta |
| Lag en picos que se recupera | Tráfico irregular; está bien | Que el pico se drene antes del siguiente |
| Lag en una sola partición | Clave de particionado desequilibrada | Distribución de claves: un cliente enorme lo explica casi siempre |
| Lag que no baja aunque haya capacidad | Consumidor atascado en un mensaje | Reintentos del mismo identificador: mensaje envenenado |

**Cuánto.** Vigilarlo no cuesta nada; no vigilarlo cuesta enterarte por el cliente.

> **🩺 Diagnóstico:** ante "no se procesó mi pedido", el orden es: ¿se publicó el evento? → ¿está en el
> topic? → ¿cuánto lag tiene el consumidor? → ¿hay algo en la DLQ con ese identificador? Cuatro
> preguntas que se contestan en dos minutos si tienes los paneles, y en dos horas si no.

---

## 7. 🧰 En las cuatro plataformas

| Plataforma | Qué te da hecho | Lo que te deja a ti |
|---|---|---|
| **Java** | Integración madura con los brokers principales: consumo declarativo, reintentos y DLQ configurables, contenedores de escucha con control de concurrencia | La idempotencia siempre; y entender qué hace por ti el marco con la confirmación, porque de ahí sale si pierdes o duplicas |
| **Node/TS** | Clientes maduros de los brokers, y librerías de colas sobre Redis muy usadas para trabajo en segundo plano, con reintentos y DLQ incluidos | El procesamiento pesado no puede ir en el bucle principal; y el apagado ordenado del consumidor, que se olvida |
| **Go** | Clientes sólidos y un ecosistema de enrutado de mensajes con reintentos, DLQ y middlewares | El cableado: confirmación, reintento, deduplicación. Se ve todo, y hay que escribirlo |
| **Python** | Colas de tareas con años de rodaje —reintentos, planificación, resultados— además de los clientes de broker | Que el modelo de procesos y la idempotencia convivan; y no mezclar cliente bloqueante en código asíncrono |

El consumidor idempotente en Java, con la marca y el efecto en la misma transacción:

```java
@Transactional                                   // marca y efecto, o ninguno de los dos
public void onOrderPlaced(OrderPlaced event, String messageId) {
    if (processed.exists(messageId)) return;     // ya aplicado: salir en silencio
    processed.record(messageId);                 // dentro de la MISMA transacción
    inventory.reserve(event.orderId(), event.lines());
}
```

- Si el registro estuviera fuera de la transacción, habría una ventana donde la reserva se aplicó y
  la marca no: el reintento duplicaría el efecto.
- `return` en silencio es correcto y deliberado: un duplicado **no es un error**, es lo esperado.
  Registrarlo como error llena el log de ruido y esconde los fallos de verdad.

Lo mismo en Python, donde lo interesante es el orden de la confirmación:

```python
def on_order_placed(message):
    with transaction():                       # una sola transacción para marca y efecto
        if processed.exists(message.id):
            message.ack()                     # ya aplicado: confirmar y seguir
            return
        processed.record(message.id)
        inventory.reserve(message.order_id, message.lines)
    message.ack()                             # confirmar DESPUÉS del commit, nunca antes
```

- Confirmar antes del commit es el error clásico: si el proceso muere en medio, el mensaje está
  confirmado y el efecto no se aplicó. **Se pierde**, y no hay forma de enterarse.
- Confirmar después significa aceptar duplicados si el proceso muere justo ahí — que es exactamente
  lo que la idempotencia está cubriendo. Ese es el intercambio, y es el correcto.

> **🧰 Plataforma:** el marco puede confirmar por ti antes o después del trabajo, y eso decide si tu
> sistema pierde mensajes o los duplica. Es la configuración que más conviene conocer de tu
> plataforma, y la que menos gente sabe de memoria.

---

## 8. ⚖️ Los brokers, en una tabla y sin entrar

Comparación corta a propósito: el desarrollo está en
[`02-eventos/02`](../../01-bases/02-eventos/02-brokers-comparados.md), que es
su dueño y no se duplica aquí.

| Familia | Modelo | Encaja bien cuando |
|---|---|---|
| **Log distribuido** (Kafka y compatibles) | Registro por particiones, consumidores con su propio avance, retención por tiempo | Quieres releer, tener varios consumidores independientes y orden por clave |
| **Cola de mensajes** (AMQP y similares) | Enrutado flexible, confirmación por mensaje, el mensaje se va al confirmarse | Quieres enrutado por reglas y trabajo distribuido entre consumidores |
| **Cola gestionada de nube** | Operada por el proveedor, DLQ integrada, escalado transparente | No quieres operar un broker y el modelo de cola te basta |

Lo que decide en la práctica casi nunca es el modelo: es **si quieres operarlo tú**, y si necesitas
releer el historial. Con esas dos preguntas se resuelve la mayoría de las conversaciones.

---

## ⚠️ Errores frecuentes

| Se dice | Lo preciso |
|---|---|
| "Con Kafka tenemos exactly-once" | Dentro de sus fronteras, con configuración específica. En cuanto el efecto sale al exterior, vuelves a al-menos-una-vez |
| "Los eventos garantizan el orden" | Solo dentro de la partición o de la cola ordenada. Entre particiones no hay orden, y eso es una decisión de clave |
| "Si falla, el broker reintenta y ya" | Si el fallo es determinista, reintenta para siempre. Sin DLQ, ese mensaje bloquea o envenena el flujo |
| "Publicamos un evento por cada cambio de estado de la entidad" | Eso publica tu modelo interno. Los eventos son hechos de negocio, y si no, acabas con un contrato acoplado a tus tablas |
| "La DLQ ya recoge los fallos" | Una DLQ sin alerta es un agujero negro: los mensajes dejan de molestar y nadie se entera de que el efecto no ocurrió |
| "Confirmamos al recibir para no bloquear" | Confirmar antes de aplicar el efecto es perder mensajes. Se confirma después, y los duplicados los cubre la idempotencia |
| "El consumidor es idempotente porque comprueba si ya existe" | Solo si la comprobación y el efecto van en la misma transacción. Si no, hay una ventana donde se duplica |

---

## 📚 Para profundizar

1. **Libro** — Gregor Hohpe y Bobby Woolf, *Enterprise Integration Patterns*, Addison-Wesley, 2003.
   Capítulos 4 y 5: canales, mensajes y garantías. **Todo el vocabulario de este capítulo sale de
   aquí, y sigue vigente veinte años después.**
2. **Libro** — Chris Richardson, *Microservices Patterns*, Manning, 2018. Capítulo 3, sección de
   mensajería, y capítulo 5 para el consumidor idempotente.
3. **Libro** — Martin Kleppmann, *Designing Data-Intensive Applications*, O'Reilly, 2017. Capítulo 11,
   "Stream Processing": la mejor explicación de por qué exactly-once no es lo que parece.
4. **Fuente primaria** — Chris Richardson, «Pattern: Idempotent Consumer»:
   [microservices.io/patterns/communication-style/idempotent-consumer.html](https://microservices.io/patterns/communication-style/idempotent-consumer.html).
5. **Fuente primaria** — Chris Richardson, «Pattern: Messaging»:
   [microservices.io/patterns/communication-style/messaging.html](https://microservices.io/patterns/communication-style/messaging.html).
6. **Documentación** — Apache Kafka, sección de diseño, para particiones, orden y garantías:
   [kafka.apache.org/documentation/#design](https://kafka.apache.org/documentation/#design).
7. **Documentación** — RabbitMQ, conceptos de AMQP, para el modelo de enrutado y confirmación:
   [rabbitmq.com/tutorials/amqp-concepts](https://www.rabbitmq.com/tutorials/amqp-concepts).
8. **Charla** — GOTO Conferences, «Exactly-Once Semantics: The Whole Story». Es la charla que mejor
   desmonta la expectativa sin caer en el purismo.

---

## 🧠 Preguntas

1. ¿Qué diferencia hay entre una cola y un topic? 🟢
2. ¿Qué garantía de entrega ofrece un broker en la práctica? 🟢
3. ¿Qué es un consumidor idempotente y cuáles son sus tres formas? 🟢
4. ¿Qué es la DLQ y qué le falta si no tiene alerta? 🟢
5. ¿Qué es el lag de un consumidor y en qué se traduce para el usuario? 🟢
6. ¿Qué es un mensaje envenenado? 🟢
7. ¿Por qué un duplicado no debe registrarse como error? 🟢
8. ¿Por qué el orden solo se garantiza dentro de la partición? 🟡
9. ¿Por qué la marca de procesado y el efecto tienen que ir en la misma transacción? 🟡
10. ¿Qué pasa si se confirma el mensaje antes de aplicar el efecto? ¿Y después? 🟡
11. ¿Por qué publicar un evento por cada cambio de estado de la entidad es mala idea? 🟡
12. Diferencia entre reintento inmediato y cola de reintento con espera. 🟡
13. ¿Qué te da cada plataforma para consumir mensajes, y qué te deja a ti en las cuatro? 🟡
14. El lag crece en una sola partición. Diagnostica y propón dos soluciones. 🟠
15. ¿Cómo eliges la clave de particionado de `orders.placed`? 🟠
16. Diseña el procedimiento de reproceso desde la DLQ, incluyendo cómo evitas duplicar efectos. 🟠
17. `orders` quiere que `inventory` reserve. ¿Comando o evento? Justifica y di qué cambia dentro
    de `inventory`. 🟠
18. Un consumidor tiene que llamar a un tercero no idempotente. ¿Cómo lo haces seguro? 🟠
19. ¿Qué métricas y alertas pones en un flujo asíncrono para enterarte antes que el cliente? 🟠
20. Te dicen "usamos exactly-once". ¿Qué preguntas? 🟠
21. ¿Cómo depuras "el pedido se confirmó pero no se reservó" en un flujo asíncrono? 🟠
22. ¿Qué configuración de tu plataforma decide si pierdes o duplicas mensajes? 🟠
23. Diseña el contrato del evento `OrderPlaced`: campos, versionado, clave de particionado y
    qué NO va dentro. 🔴
24. Diseña el consumidor de `inventory` completo: consumo, idempotencia, reintentos, DLQ,
    observabilidad y apagado ordenado. 🔴
25. Diagnostica: el lag es cero, no hay nada en la DLQ, y aun así faltan reservas de algunos
    pedidos. Da tres hipótesis ordenadas. 🔴
26. Un equipo propone sustituir todas las llamadas síncronas por eventos y quitar las colas de
    reintento "porque el broker ya reintenta". Responde. 🔴

---

**Anterior:** [`05` — Tiempo real: WebSockets, SSE y los demás](05-tiempo-real-websockets-y-sse.md) ·
**Siguiente:** [`07` — Contratos y versionado](07-contratos-y-versionado.md) · **Relacionado:**
[`03-datos-y-consistencia`](../03-datos-y-consistencia/) ·
[`02-eventos`](../../01-bases/02-eventos/)

**Taller, opcional:** [`06/06` — Kafka: outbox, inbox, idempotencia y DLQ](../06-talleres/06-kafka-outbox-inbox-y-dlq.md).
