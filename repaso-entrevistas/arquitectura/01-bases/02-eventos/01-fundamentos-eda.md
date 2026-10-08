# 01 — Fundamentos de EDA

> Qué compra de verdad una arquitectura dirigida por eventos, qué es un evento y qué no lo
> es, y las tres formas de colaborar por eventos que se confunden entre sí. Es el capítulo
> que fija el vocabulario del bloque entero.
> Asume leído [`01-bases/08` — Comunicación e integración](../01-bases/08-comunicacion-e-integracion.md).
>
> **Vigencia:** 2026-09-18.

---

## 1. 🎯 El problema

`Pedidos` confirma un pedido. Ahora hay que descontar inventario, generar la factura,
mandar el correo, avisar a logística y actualizar el panel de analítica. La versión
síncrona es esta:

```java
pedido.confirmar();
inventario.descontar(pedido);      // si falla, ¿se cancela el pedido?
facturacion.emitir(pedido);        // si está caído, ¿no se pueden tomar pedidos?
correo.enviar(pedido);             // ¿de verdad el usuario espera a que salga el correo?
logistica.notificar(pedido);       // cinco dependencias para confirmar un pedido
analitica.registrar(pedido);
```

- Cada línea es una dependencia **temporal**: si una está caída, no se confirman pedidos.
- Cada línea nueva obliga a **tocar `Pedidos`**, que no tiene nada que ver con facturar.
- La disponibilidad de confirmar un pedido es el producto de las seis.

EDA le da la vuelta: `Pedidos` publica **que algo pasó** y se desentiende de quién lo
escucha.

> **Regla:** en una llamada, el emisor sabe a quién llama y qué quiere que haga. En un
> evento, el emisor solo sabe **qué pasó**. Esa ignorancia es toda la ganancia.

---

## 2. 📢 Qué es un evento

**Qué es.** Un hecho del pasado, inmutable, con nombre de negocio y en pasado:
`PedidoConfirmado`, `PagoRechazado`, `LimiteDeCreditoSuperado`. Ya ocurrió: nadie puede
rechazarlo ni deshacerlo, solo reaccionar.

**La distinción que se pregunta primero**, porque ordena todo lo demás:

| | Comando | Evento | Consulta |
|---|---|---|---|
| Nombre | Imperativo: `ConfirmarPedido` | Pasado: `PedidoConfirmado` | Interrogativo |
| Destinatario | Uno, conocido | Cualquiera, desconocido | Uno, conocido |
| Puede rechazarse | Sí | No, ya pasó | — |
| Acoplamiento | El emisor conoce al receptor | Ninguno | El emisor conoce al receptor |

- Mandar `EnviarCorreoDeConfirmacion` por un broker **no es EDA**: es una llamada RPC con
  una cola en medio. Sigue habiendo acoplamiento, solo que ahora es asíncrono.
- La prueba: si añadir un consumidor nuevo te obliga a cambiar el mensaje, era un comando.

**Cuándo sí.** Cuando el emisor no necesita saber qué pasa después, y cuando el número de
interesados puede crecer sin que él se entere.

**Cuándo no.** Cuando el emisor necesita el resultado para responder, o cuando hay
exactamente un destinatario y siempre será uno. Ahí un comando explícito es más honesto y
mucho más fácil de depurar.

> **Veredicto:** el nombre en pasado no es cosmética. Es lo que te obliga a modelar hechos
> en vez de órdenes, y es lo que impide que el emisor vuelva a acoplarse sin darse cuenta.

---

## 3. 🧱 Evento de dominio y evento de integración

**Qué es.** Dos cosas distintas con el mismo nombre coloquial, y confundirlas es el error
más caro del bloque.

```text
Evento de dominio      → interno al contexto. Habla tu lenguaje ubicuo.
                         Cambiarlo no rompe a nadie de fuera. Viaja en memoria.

Evento de integración  → contrato público entre contextos. Versionado.
                         Cambiarlo rompe a consumidores que no controlas. Viaja por broker.
```

**Por qué importa.** Si publicas tus eventos de dominio tal cual al broker, tu modelo
interno se convierte en API pública y **ya no puedes refactorizarlo**: cada cambio de un
campo privado rompe a tres equipos. El agregado deja de ser tuyo.

**Cómo se resuelve.** Se traduce en la frontera: el evento de dominio dispara un
publicador que emite un evento de integración **más estable y con menos detalle**.

```java
// Dominio: rico, interno, cambia cuando quiera
record PedidoConfirmado(PedidoId id, List<LineaPedido> lineas, Money total, Instant momento) {}

// Integración: mínimo, estable, versionado
record PedidoConfirmadoV1(String pedidoId, String clienteId, String total, String moneda) {}
```

- El de integración usa **tipos primitivos y strings**, no tus objetos de valor: el
  consumidor no tiene tus clases.
- Lleva **lo mínimo que el consumidor necesita**. Cada campo que publicas es un campo que
  no puedes quitar.
- El sufijo de versión en el nombre o en el esquema es lo que te permite evolucionar.

**Cuándo sí.** Siempre que el evento cruce una frontera de contexto acotado.

**Cuándo no.** Dentro del mismo módulo no hace falta traducir: ahí el evento de dominio
basta y traducir es ceremonia.

> ⚠️ **Advertencia.** Es el error que más se ve en sistemas reales y el que más tarde se
> descubre: todo va bien hasta que necesitas renombrar un campo y resulta que cuatro
> equipos dependen de él.

> **Veredicto:** publicar el evento de dominio al broker es cómodo el primer día y caro
> para siempre. La traducción cuesta una clase y compra tu libertad de refactorizar.

---

## 4. 🤝 Las tres formas de colaborar por eventos

**Qué es.** Fowler distingue tres patrones que la gente mete en el mismo saco, y saber
separarlos es de las respuestas que más rinden.

**1. Notificación por evento (event notification).** El evento dice *qué pasó* y poco
más; quien lo recibe llama de vuelta si necesita datos.

```text
Pedidos ──PedidoConfirmado{id}──► Facturación ──GET /pedidos/{id}──► Pedidos
```

- Ventaja: el evento es mínimo y estable.
- Precio: vuelve el acoplamiento temporal en la llamada de vuelta, y pierdes el beneficio
  principal. Además, **el flujo real deja de verse en ningún sitio**.

**2. Transferencia de estado por evento (event-carried state transfer).** El evento lleva
los datos que el consumidor necesita, y este mantiene una copia local.

```text
Pedidos ──PedidoConfirmado{id, cliente, líneas, total}──► Facturación (guarda su copia)
```

- Ventaja: desacoplamiento real. Facturación funciona con `Pedidos` caído.
- Precio: duplicación de datos, consistencia eventual, y eventos más grandes y más
  frágiles al cambio.

**3. Event sourcing.** El log de eventos **es** la fuente de verdad, no una notificación.
Se ve en [`07`](07-event-sourcing.md) y es otra cosa: los dos anteriores son formas de
integrar, este es una forma de persistir.

**Cuándo sí cada uno.** Notificación cuando los datos son grandes o sensibles y el
consumidor los necesita pocas veces. Transferencia de estado cuando el consumidor los
necesita siempre y quieres que sobreviva a la caída del emisor.

**Cuándo no.** Transferencia de estado con datos que cambian mucho más rápido de lo que se
consumen: acabas replicando un flujo entero para leerlo una vez al día.

> 🧠 **Modelo mental.** La pregunta que separa las dos primeras es *"¿el consumidor puede
> hacer su trabajo con el emisor caído?"*. Si la respuesta tiene que ser sí, el evento
> lleva los datos. Si no, basta con notificar.

> **Veredicto:** la mayoría de los sistemas que dicen "somos event-driven" hacen
> notificación por evento y siguen acoplados, porque cada consumidor llama de vuelta.
> Detectarlo en voz alta es una respuesta de nivel arquitecto.

---

## 5. ⚖️ Qué se gana y qué se paga

**Lo que se gana**, y conviene decirlo en este orden porque es el de importancia real:

```text
Desacoplamiento temporal → el consumidor puede estar caído sin romper al productor
Desacoplamiento estructural → añadir un consumidor no toca al productor
Absorción de picos       → la cola amortigua; el consumidor va a su ritmo
Auditoría natural        → el log de eventos es la historia de lo que pasó
```

**Lo que se paga**, y esto es lo que la mayoría no dice en una entrevista:

- **La consistencia deja de ser inmediata.** El usuario confirma el pedido y la factura no
  existe todavía. Eso hay que decidirlo con negocio y mostrarlo en la interfaz.
- **El flujo deja de estar en ningún sitio.** No hay una función que lo describa: está
  repartido entre productores y consumidores. Sin trazas distribuidas, depurar es
  arqueología.
- **La entrega es at-least-once**, así que **todo consumidor debe ser idempotente**. Esto
  no es opcional y se desarrolla en [`03`](03-garantias-orden-e-idempotencia.md).
- **Aparecen problemas nuevos**: orden, duplicados, mensajes envenenados, lag, esquemas que
  evolucionan y consumidores viejos que siguen vivos.
- **Operar un broker cuesta.** Kafka en producción no es una dependencia más: es un
  sistema distribuido con su propio equipo, su propia guardia y su propia factura.

> 💰 **Costo.** El precio de EDA se paga en **consistencia y en depurabilidad**, no en
> latencia de infraestructura. Quien responde "es más rápido" no lo ha operado.

> **Veredicto:** EDA no simplifica el sistema, lo **reparte**. Cambias un problema de
> acoplamiento por un problema de observabilidad y consistencia, y esa es exactamente la
> frase que hay que decir cuando te pregunten por sus ventajas.

---

## 6. 🧭 Cómo se elige

```text
¿El emisor necesita el resultado para responder a su usuario?
    → Síncrono. No es un evento, por mucho que lo mandes por un broker.

¿Hay un destinatario conocido y siempre será uno?
    → Comando por cola. Es asíncrono pero NO es EDA: sigue acoplado estructuralmente.

¿Hay varios interesados, o los habrá y no quieres enterarte?
    → Evento, pub/sub.
    ¿El consumidor debe funcionar con el emisor caído? → lleva los datos (state transfer)
    ¿Los datos son grandes, sensibles o poco usados? → notifica y que consulte

¿El evento cruza una frontera de contexto?
    → Tradúcelo a evento de integración. Nunca publiques el de dominio tal cual.
```

> **Regla de entrevista:** antes de proponer Kafka, di qué pasa con el usuario mientras el
> consumidor todavía no procesó. Si no tienes respuesta a eso, no tienes un diseño: tienes
> un broker.

---

## ⚠️ Errores frecuentes

| Se dice | Lo preciso |
|---|---|
| "Somos event-driven, usamos Kafka" | El broker no hace EDA; mandar comandos por Kafka sigue siendo RPC acoplado |
| "Los eventos son más rápidos" | Son más **resilientes** y desacoplan en el tiempo; la latencia extremo a extremo sube |
| "Publico mis eventos de dominio" | Eso convierte tu modelo interno en API pública y congela tu refactor |
| "El evento lleva todo por si acaso" | Cada campo publicado es un campo que ya no puedes quitar |
| "Con eventos no hay acoplamiento" | Lo hay: el **esquema** es el contrato, y romperlo rompe a todos |
| "El consumidor procesa una vez" | At-least-once: procesará de más, y debe ser idempotente |
| "EDA simplifica el sistema" | Lo reparte: cambias acoplamiento por consistencia eventual y peor depurabilidad |

---

## 📚 Para profundizar

- **Libro** — Gregor Hohpe y Bobby Woolf, *Enterprise Integration Patterns*
  (Addison-Wesley, 2003). Capítulos 4 a 7. **Es el libro de este bloque**: los nombres que
  usa la industria —canal, enrutador, traductor de mensajes, dead letter— salen de aquí.
- **Libro** — Adam Bellemare, *Building Event-Driven Microservices* (O'Reilly, 2020).
  Capítulos 2 y 3: eventos como contrato, y el modelo de datos de un ecosistema por
  eventos.
- **Libro** — Martin Kleppmann, *Designing Data-Intensive Applications* (O'Reilly, 2017).
  Capítulo 11: flujos de eventos, y la distinción entre notificación y transferencia de
  estado con todas sus consecuencias.
- Martin Fowler — [What do you mean by "Event-Driven"?](https://martinfowler.com/articles/201701-event-driven.html):
  la fuente primaria de los tres patrones de colaboración de §4.
- Martin Fowler — [Domain Event](https://martinfowler.com/eaaDev/DomainEvent.html): la
  ficha del patrón, con la distinción frente al evento de integración.
- [microservices.io — Domain event](https://microservices.io/patterns/data/domain-event.html):
  el patrón con sus fuerzas y sus contras enfrentados.
- **Video** — GOTO Conferences, charlas de Gregor Hohpe sobre integración y de Martin
  Kleppmann sobre flujos de eventos. Búscalas por título.

---

## 🧠 Preguntas

Sin respuestas aquí. Todas, con enunciado literal y respuesta en tres capas, en
[`10` — Respuestas](10-respuestas.md).

1. ¿Qué es un evento y cómo se nombra? 🟢
2. ¿Qué diferencia a un comando de un evento? 🟢
3. Nombra las tres formas de colaborar por eventos de Fowler. 🟢
4. ¿Qué cuatro cosas gana una arquitectura dirigida por eventos? 🟢
5. ¿Qué diferencia hay entre evento de dominio y evento de integración? 🟡
6. ¿Por qué mandar un comando por Kafka no es EDA? 🟡
7. ¿Qué es event-carried state transfer y qué problema resuelve? 🟡
8. ¿Qué tipos llevan los campos de un evento de integración y por qué? 🟡
9. ¿Por qué el nombre del evento va en pasado? 🟡
10. ¿Qué pierde una arquitectura por eventos respecto de una síncrona? 🟡
11. ¿Cómo detectas que un "evento" era en realidad un comando disfrazado? 🟠
12. ¿Qué pasa si publicas tus eventos de dominio directamente al broker? 🟠
13. ¿Cuándo la notificación por evento es mejor que llevar los datos? 🟠
14. ¿Cuál es el precio concreto de event-carried state transfer? 🟠
15. ¿Por qué "con eventos no hay acoplamiento" es falso? 🟠
16. ¿Qué pregunta decide si el evento lleva datos o solo notifica? 🟠
17. ¿Por qué depurar un sistema por eventos es más difícil, y qué lo mitiga? 🟠
18. Un sistema dice ser event-driven pero cada consumidor llama de vuelta al
    productor. ¿Qué diagnosticas? 🟠
19. ¿Qué le dices a negocio cuando la factura tarda 30 segundos en aparecer? 🟠
20. Rediseña el ejemplo síncrono de la sección 1 con eventos: qué publica
    `Pedidos`, qué consume cada servicio y qué falla si uno se cae. 🔴
21. Tienes que añadir un sexto consumidor a un flujo de eventos existente sin
    tocar al productor. ¿Qué tiene que ser cierto ya para poder hacerlo? 🔴
22. Diseña el contrato de `PedidoConfirmado` como evento de integración: qué
    campos lleva, cuáles no, y cómo lo versionas. 🔴

---

**Siguiente:** [`02` — Brokers comparados](02-brokers-comparados.md) ·
**Relacionado:** [`01-bases/08` — Comunicación](../01-bases/08-comunicacion-e-integracion.md)
