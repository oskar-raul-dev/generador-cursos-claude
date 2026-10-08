# 📡 Fase 25 — La coreografía, y los mensajes que se pierden: nadie manda, y alguien tiene que confirmar

> **Curso:** Laboratorio de contenedores y Kubernetes local · Fase 25 de 27 · Parte IV — El lab de patrones distribuidos · **densa**
> **Perfil:** el cluster `lab`, con los valores de `minimo` · **Observabilidad encendida:** trazas (Tempo)
> **Motor de referencia:** Docker · 🦭 no diverge en esta fase: el bus vive en el cluster
> **Servicios que toca:** `inventory` (publica) y `replenish` (consume) · **Paso de generación:** G12 · Coreografía
> **Depende de:** [Fase 24](24-la-saga-orquestada.md) · **Habilita:** [Fase 26](26-idempotencia-y-outbox.md)
> **Incidentes que reserva:** ninguno · **Medición:** ninguna (la rotura de la sección 8)
> **Apéndices de apoyo:** [a01](a01-el-laboratorio.md), [a03](a03-contratos-y-prompts-de-generacion.md), [a04](a04-kubectl-y-k9s.md), [a05](a05-diccionarios.md)
> **Fecha de verificación ejecutada:** 04/10/2026 · macOS arm64
> **Objetivo:** pasar el aviso de reposición de la venta a un evento, perder uno a propósito con Valkey pub/sub, dejar de perderlos con NATS JetStream, y decidir con lo medido en esta fase y en la anterior cuándo conviene orquestar y cuándo coreografiar.

---

## 🧭 1. Dónde estamos

La [Fase 24](24-la-saga-orquestada.md) puso a `inventory` a coordinar el préstamo: él decide cada paso, él sabe en qué
va cada préstamo, él compensa. Esta fase hace lo contrario con el otro flujo que cruza servicios, el aviso de
reposición: nadie coordina. `inventory` dice *"el stock bajó"* a quien quiera oírlo, y `replenish` decide qué hacer con
eso.

Ese aviso tiene deuda. Desde la [Fase 16](16-escalado-y-rollout.md), la venta le hace un `POST` a `replenish` en un hilo
aparte, sin esperar respuesta: la venta no falla si `replenish` no contesta, y el resultado va al log. La pregunta que
quedó escrita en el código era *"¿y si el aviso se pierde?"*.

En La Vecina esa pregunta tiene nombre y apellido. Cuando una moto no sale, Wilson llama a las dos guardias, la de la
Braqui y la del Núcleo, y las dos le contestan que su parte funcionó (historia §1.11). Luz Marina lo resumió en la
reunión de esta parte:

> *"El aviso a la Braqui no falla. Se pierde. Si fallara, alguien se enteraría."*

El antecedente es el `.txt` de 2020: el archivo leído a medio subir, y el `.ok` que llega antes que su archivo
(historia §1.9). En los dos casos el script cree que leyó todo, lo marca como procesado, y los traslados de las últimas
líneas no existen para nadie. Nadie confirma la lectura, y nadie mide la pérdida. Esta fase empieza por ahí: perdiendo un
aviso delante de todos.

---

## 🎯 2. Objetivos de esta fase

1. Generar G12: el aviso de la venta como el evento `lab.inventory.stock-low`, con `inventory` publicando y `replenish`
   consumiendo, detrás de un interruptor de bus.
2. Perder un aviso con Valkey pub/sub y verlo en los logs, sin que ninguna venta falle.
3. Pasar el mismo flujo a NATS JetStream, con un consumidor durable y confirmación explícita, y comprobar que no se
   pierde nada con `replenish` reiniciado o apagado un minuto.
4. Leer el estado del bus (`/jsz`) y explicar `num_pending` y `num_ack_pending`.
5. Decidir con números cuándo orquestar ([Fase 24](24-la-saga-orquestada.md)) y cuándo coreografiar (esta fase).

---

## 🚫 3. Qué NO entra todavía

- **El mensaje que llega dos veces, y la escritura dual** (la venta confirmada y el evento perdido) →
  [Fase 26](26-idempotencia-y-outbox.md). Aquí se ven, y se dejan abiertos a propósito.
- **El préstamo por coreografía**: la comparación se hace entre el préstamo orquestado y el aviso coreografiado; el
  ejercicio 23 escribe el préstamo por eventos.
- **Un NATS de tres miembros**, con quórum y failover → el apéndice [a15](a15-statefulset-de-varios-miembros.md).
- **Propagar la traza por el bus** (sección 6): queda como ejercicio.
- Kafka: fuera del alcance del curso.

---

## 🧨 4. El problema, en el laboratorio

### 4.1 Abre rompiendo

G12 ya está generado (sección 5.2) y el bus de esta prueba es **Valkey**, con su pub/sub: `inventory` publica cada aviso
en el canal `lab.inventory.stock-low`, y `replenish` está suscrito.

```bash
task bus:on -- valkey
```

Treinta ventas, una por segundo, en una droguería con el umbral por encima de la existencia: cada venta pide
reposición. A los cinco segundos, el proceso de `replenish` se reinicia, como se reinicia un proceso cualquiera, dentro
de su mismo pod:

```text
+ 5.0s $ kubectl --context kind-lab -n apps exec deploy/replenish -- kill 1
ventas: 30 · respuestas: {201: 30}
órdenes nuevas: 29 · eventos distintos: 29 · repetidos: 0
avisos publicados, por suscriptores: {'1': 29, '0': 1}
04:36:15.908 aviso de SALE-027208 para SKU-0002 en DRO-021 (quedan 493): evento f5be30ff-9a37-4f8b-bafe-98633e2a1376 a 0 suscriptores (Valkey)
```

Treinta ventas, todas con su `201`. Veintinueve órdenes. El aviso de la venta `SALE-027208` se publicó en el segundo
en que `replenish` estaba volviendo a arrancar, y llegó **a cero suscriptores**. No está en Valkey, no está en
`replenish`, no está en ningún reintento. **No existió nunca.** El único rastro es una línea de log de quien lo publicó,
que nadie lee.

### 4.2 Lo mismo, sin bus

La comparación honesta no es contra un bus perfecto: es contra lo que había. Con el bus apagado, el aviso vuelve a ser
el `POST` de G5, y la misma prueba da esto:

```text
aviso por HTTP (G5), sin bus
+ 5.0s $ kubectl --context kind-lab -n apps exec deploy/replenish -- kill 1
ventas: 30 · respuestas: {201: 30}
órdenes nuevas: 28 · …
2 avisos perdidos
  aviso a replenish perdido para SKU-0002 en DRO-021: I/O error on POST request for "http://replenish.apps.svc.cluster.local:8080/replenishment-orders": …
```

Dos perdidos de treinta. El `POST` sin espera y el pub/sub de Valkey tienen la misma garantía: **a lo sumo una vez**.
Funcionan cuando el otro está, y cuando no está, el mensaje se va. La diferencia con la historia de La Vecina es que
aquí, por lo menos, queda una línea que lo dice.

> 🩻 **Esto sí funciona igual.** Un aviso que se manda sin confirmación se pierde igual en un `.txt`, en un `POST` sin
> respuesta o en un canal de pub/sub. El medio cambia; la garantía, no.

---

## 🧩 5. Los eventos, entre `inventory` y `replenish`

### 5.1 Coreografía: nadie manda

En la saga de la [Fase 24](24-la-saga-orquestada.md), `inventory` sabe el dibujo entero: reserva, después despacha, después cobra. En una
**coreografía**, cada servicio reacciona a lo que pasa: `inventory` publica un **evento** —un hecho en pasado, *"el
stock bajó"*— y no sabe quién lo escucha; `replenish` lo escucha y decide crear una orden. Si mañana otro servicio
quiere saber que el stock bajó (un tablero, un aviso al proveedor), se suscribe, y `inventory` no cambia una línea.

Lo que se gana es **desacople**: `inventory` ya no conoce la dirección de `replenish`, ni espera que esté vivo. Lo que se
pierde es **un lugar donde mirar**: en la saga, `GET /loans/{id}` dice en qué va el préstamo; en la coreografía, para
saber si la venta `SALE-027208` terminó en una orden hay que preguntarle a `replenish`, y si dice que no tiene nada, no
hay a quién más preguntar.

### 5.2 G12: el evento en el contrato

OpenAPI describe peticiones, no mensajes. El evento va en el contrato de `inventory` con una extensión, `x-lab-events`,
con su canal y su esquema:

```yaml
# contracts/openapi/inventory.yaml (G12)
x-lab-events:
  - channel: lab.inventory.stock-low
    x-lab-paso: G12
    summary: Una venta dejó la existencia de un producto por debajo del umbral en una droguería.
    payload: {$ref: '#/components/schemas/StockLowEvent'}
```

```json
{"eventId":"98f5b56a-3d61-46ed-ad91-52121028dc5f","type":"stock.low","saleId":"SALE-027171","store":"DRO-021",
 "sku":"SKU-0002","quantity":9,"occurredAt":"2026-10-05T04:34:…Z"}
```

Cada evento lleva un `eventId` único, y la orden que crea en `replenish` lo guarda en `sourceEventId`. Todavía no se usa
para nada; en la [Fase 26](26-idempotencia-y-outbox.md) es la pieza que importa. El paso se generó con los prompts de G12
de [a03](a03-contratos-y-prompts-de-generacion.md#-los-prompts-de-g12), y compiló al primer intento salvo por un
`import` (sección 13). La primera venta con el bus encendido:

```text
aviso de SALE-027171 para SKU-0002 en DRO-021 (quedan 8): evento 98f5b56a-3d61-46ed-ad91-52121028dc5f a 1 suscriptores (Valkey)
{'id': 'RO-0077', 'sku': 'SKU-0002', 'destinationStore': 'DRO-021', 'quantity': 9, 'status': 'PENDING', …,
 'sourceEventId': '98f5b56a-3d61-46ed-ad91-52121028dc5f'}
```

El código de `inventory` cambia poco: el mismo hilo virtual del aviso de G5, y adentro, en vez del `POST`, una línea.

```java
// SalesController.java (G12): con un bus encendido, el aviso es un evento.
if (events.enabled()) {
    try {
        log.info("aviso de {} para {} en {} (quedan {}): {}", done.sale().id(), sku, store, done.left(),
                events.publishStockLow(done.sale().id(), store, sku, done.threshold()));
    } catch (Exception e) {
        log.warn("aviso perdido para {} en {}: el bus no contestó ({})", sku, store, e.getMessage());
    }
    return;
}
```

### 5.3 Un evento no es una orden

El nombre del evento importa más de lo que parece. `lab.inventory.stock-low` dice **lo que pasó** (*el stock bajó*),
no **lo que hay que hacer** (*crea una orden*). Si el mensaje fuera `replenish.create-order`, sería un **comando**:
`inventory` seguiría decidiendo por `replenish`, solo que por otro cable, y el desacople sería de mentira. Con un hecho
en pasado, la decisión queda donde está el conocimiento: `replenish` sabe si ya hay una orden abierta para ese producto,
si el centro de distribución tiene, o si conviene esperar a la próxima ruta. `inventory` no tiene por qué saberlo.

Eso cambia también **qué lleva el evento**. Un comando lleva lo que el receptor necesita para obedecer; un hecho lleva
lo que pasó, con lo mínimo para entenderlo sin preguntar: la venta que lo causó, la droguería, el producto y cuánto
reponer según el umbral. Si `replenish` necesitara algo más —el nombre del producto, el precio—, lo pediría a quien es
dueño de ese dato, no se lo pondría `inventory` "por si acaso". Un evento gordo ata a quien publica con todo lo que sus
consumidores van a querer mañana.

Y el `eventId` no es decoración: es lo que permite decir que dos mensajes son **el mismo hecho** y no dos hechos
iguales. Dos ventas de una unidad del mismo producto en el mismo segundo producen dos eventos con todo igual menos el
`eventId`. Un mensaje entregado dos veces produce dos copias con el mismo. La diferencia entre las dos situaciones es
justamente la que la sección 8 deja abierta.

### 5.4 El bus, en el cluster

Valkey y NATS viven en `data`, junto a Postgres, con manifiestos escritos a mano en `platform/data/` y la imagen
oficial de cada uno por digest ([a01](a01-el-laboratorio.md)). El chart no los instala: los usa. `task bus:on` aplica el
manifiesto, enciende el interruptor y redespliega:

```bash
task bus:on -- valkey      # o nats
task bus:off -- valkey     # el aviso vuelve a ser un POST
```

Encender el bus cambia tres cosas en el chart: las variables `EVENT_BUS` y la dirección del bus en `inventory` y
`replenish`; y la `NetworkPolicy` de salida de la cadena, que desde la [Fase 20](20-seguridad-del-pod-y-de-la-red.md) solo
dejaba ir a Postgres y a Tempo. Sin esa regla, el cliente del bus no llega y el aviso se pierde por la red, que es la
peor forma de perderlo: en silencio y en todas las ventas. En reposo, Valkey ocupa 10 MiB y NATS 12 MiB.

### 5.5 Valkey pub/sub: a lo sumo una vez, y a todos

El pub/sub de Valkey tiene dos reglas, y la sección 4 vio la primera: **un mensaje llega a quien esté suscrito en ese
instante**, sin guardarse en ninguna parte. La segunda la vio la primera apuesta (sección 7): **llega a todos los
suscriptores**. Con dos réplicas de `replenish`, cada aviso crea dos órdenes. Durante un `kubectl rollout restart`, que
con `maxSurge: 1` levanta el pod nuevo antes de bajar el viejo, eso pasó sin que nadie lo pidiera:

```text
+ 5.0s $ kubectl --context kind-lab -n apps rollout restart deploy/replenish
ventas: 30 · respuestas: {201: 30}
órdenes nuevas: 40 · eventos distintos: 30 · repetidos: 10
avisos publicados, por suscriptores: {'1': 21, '2': 10}
```

Diez avisos llegaron a dos suscriptores, y cada uno creó su orden: diez motos de más. Pub/sub es un **canal de
difusión** (*publish-subscribe channel* en el vocabulario de Hohpe y Woolf): sirve para que muchos se enteren de lo
mismo, no para repartir trabajo entre réplicas.

### 5.6 NATS JetStream: guardar hasta que alguien confirme

**JetStream** es la capa de persistencia de NATS. Agrega dos piezas que el pub/sub no tiene:

- Un **stream**, `LAB_EVENTS`, que guarda en disco todo lo publicado en `lab.>` durante un día. Publicar ya no es
  gritar: es escribir, y el servidor contesta con un número de secuencia cuando el mensaje quedó guardado.
- Un **consumidor durable**, `replenish-stock-low`, que recuerda hasta dónde leyó aunque `replenish` no esté conectado,
  con **confirmación explícita**: el servidor considera entregado un mensaje cuando `replenish` hace `ack`, y si el ack
  no llega en 30 s (`ack_wait`), lo entrega otra vez.

```typescript
// replenish/src/events.ts (G12): crear la orden, y después confirmar.
for await (const m of this.messages!) {
  try {
    await this.handle(m.json<StockLowEvent>(), m.info.deliveryCount);
    m.ack(); // después de crear la orden: si el proceso muere antes, el evento vuelve
  } catch (e) {
    logLine('WARN', 'evento sin procesar; vuelve más tarde', { error: (e as Error).message });
    m.nak(5000);
  }
}
```

Las dos réplicas de `replenish` comparten el mismo consumidor durable, y el servidor **reparte** los mensajes entre
ellas en vez de copiarlos. Es una **cola de trabajo** sobre un stream: lo contrario de la difusión de Valkey.

```bash
task bus:off -- valkey
task bus:on -- nats
```

```text
{"msg":"stream LAB_EVENTS creado"}
{"msg":"consumiendo lab.inventory.stock-low de LAB_EVENTS (durable replenish-stock-low)"}
```

La misma prueba de la sección 4, ahora con NATS:

```text
+ 5.0s $ kubectl --context kind-lab -n apps exec deploy/replenish -- kill 1
ventas: 30 · respuestas: {201: 30}
órdenes nuevas: 30 · eventos distintos: 30 · repetidos: 0
```

Y la del rollout, la que con Valkey duplicó diez: treinta órdenes, treinta eventos distintos.

### 5.7 El consumidor que no está

Lo que el stream compra de verdad se ve con `replenish` apagado un minuto entero. El monitoreo de NATS (el puerto 8222)
contesta JSON, y el par que importa es `num_pending` (mensajes que el consumidor todavía no recibió) y `num_ack_pending`
(recibidos y sin confirmar):

```bash
kubectl -n data exec nats-0 -- wget -qO- "http://127.0.0.1:8222/jsz?consumers=true"
```

```text
10 ventas con replenish en cero; en el stream, pendientes y sin confirmar: (10, 0)
+60s, pendientes: (10, 0); replenish vuelve
pendientes en cero 0.1 s después de que replenish quedó listo
```

Diez avisos esperaron sesenta segundos guardados en el disco de `nats-0`, y en cuanto `replenish` volvió, se procesaron
los diez. Es lo que al script de la Braqui le faltó siempre: alguien que diga *"esto todavía no lo leyó nadie"*.

**Prueba de fuego.** Con el bus encendido, `task conformance TARGET=cluster PROFILE=lab -- G12` pasa (la orden más
reciente de `DRO-025` tiene `sourceEventId`), y siguen pasando G5, G7 y G11.

**El patrón a memorizar.** Un evento no se da por entregado cuando sale, sino cuando el que lo recibe confirma que hizo
su trabajo; y la confirmación va **después** del trabajo, no antes.

---

## 🔁 6. Los otros tres: donde no es mecánico

**`replenish`** es el que más cambia: pasa de recibir peticiones a consumir mensajes, y eso le da un ciclo de vida
nuevo. El consumidor arranca con la aplicación (`onApplicationBootstrap`), **antes** de que la readiness lo marque listo:
por eso, en la sección 5.7, los diez pendientes se procesaron 0,1 s después de que el pod quedó listo, y probablemente
antes. Un consumidor no espera a que el `Service` le mande tráfico; lo va a buscar. Y al apagarse cierra el consumo y
vacía la conexión (`drain`) para no dejar mensajes a medias.

**La traza se corta en el bus.** Una venta con el aviso por NATS tiene 12 spans en Tempo, de `inventory`, `catalog` y
`pricing`, y ninguno de `replenish`: el `traceparent` viaja en las cabeceras HTTP y nadie lo puso en el mensaje. El
agente de Java sí instrumenta el cliente de NATS, y dejó ver otra cosa:

```text
    28.5 ms      2.4 ms  inventory  PRODUCER $JS.API.STREAM.INFO.LAB_EVENTS publish
```

`inventory` pregunta por el stream **en cada publicación**: el prompt decía "asegurar el stream" y el código lo asegura
siempre. Son 2,4 ms y un viaje por venta que no hacen falta; G13 lo corrige al reescribir la publicación.

**`pricing` y `catalog`** no participan: el aviso es entre `inventory` y `replenish`. Y la segunda cadena
([Fase 14](14-helm-en-operacion.md)) comparte el mismo bus en `data`: el stream es uno, y el ejercicio 21 pregunta qué
pasa con dos cadenas publicando en `lab.>`.

---

## 🪞 7. Tu instinto de compose dice… y las apuestas

Tu instinto, en su mejor versión: *"si lo publiqué, alguien lo recibió"*. Un `PUBLISH` que no da error se parece mucho a
un `POST` que contesta 201. Las tres apuestas se escribieron antes de encender el bus.

> 🪞 **Apuesta 1, Valkey** (04/10/2026, 23:33). Con `replenish` reiniciándose con `kubectl rollout restart` durante 30
> ventas, se pierde al menos un aviso, `inventory` lo registra "a 0 suscriptores" y ninguna venta falla.
> **Resultado:** perdida, de la manera más útil. No se perdió ninguno: durante el rollout hubo **dos** pods suscritos, y
> se crearon **diez órdenes de más** (sección 5.5). La pérdida apareció con el proceso reiniciado dentro del mismo pod,
> sin solapamiento: 29 de 30 (sección 4.1).

> 🪞 **Apuesta 2, NATS** (misma hora). La misma prueba deja exactamente 30 órdenes, sin pérdidas y sin duplicados.
> **Resultado:** ganada: 30 de 30, con 30 eventos distintos, en el rollout y con el proceso reiniciado.

> 🪞 **Apuesta 3, NATS** (misma hora). Con `replenish` apagado 60 s, los avisos esperan en el stream y al volver todas las
> órdenes aparecen en menos de 5 s.
> **Resultado:** ganada: 10 pendientes durante 60 s, en cero 0,1 s después de que el pod quedó listo.

La primera es la que enseña: el riesgo de pub/sub en un cluster no es solo perder, es **duplicar**, porque un rollout
normal pone dos consumidores donde había uno. Y ninguna de las tres miró lo que la [Fase 26](26-idempotencia-y-outbox.md) va a mirar: qué pasa cuando
el consumidor muere entre crear la orden y confirmar.

---

## 📏 8. La rotura: el mensaje que no existió nunca

La fase no mide: rompe, y compara las tres formas del mismo aviso con el mismo reinicio.

**El cambio exacto:** `kubectl -n apps exec deploy/replenish -- kill 1` a los cinco segundos de 30 ventas que piden
reposición, una por segundo. **El síntoma**, en cada caso:

| El aviso por… | Ventas | Órdenes | Perdidos | Repetidos | Cómo se entera alguien |
|---|---|---|---|---|---|
| `POST` sin esperar (G5) | 30 | 28 | 2 | 0 | una línea `aviso a replenish perdido … I/O error` |
| Valkey pub/sub | 30 | 29 | 1 | 0 | una línea `a 0 suscriptores` |
| Valkey pub/sub, con un rollout | 30 | 40 | 0 | **10** | nadie: cada orden parece legítima |
| NATS JetStream | 30 | 30 | 0 | 0 | — |

Una corrida por fila: esto no es una medición con dispersión, es una rotura reproducida. La cantidad exacta de perdidos
depende del segundo en que cae el reinicio; que haya pérdidas con las dos primeras, y que no las haya con la última, no.

**Lo que costó salir:** el bus. Un servidor más en `data` (12 MiB), un stream, un consumidor durable, y cambiar el
consumidor de `replenish` de "me llaman" a "voy a buscar y confirmo". Lo que **no** costó: tocar la venta, que sigue
igual de rápida y sigue sin depender de que `replenish` esté vivo.

> ⚠️ **"Al menos una vez" es "a veces dos".** JetStream entrega de nuevo todo mensaje sin ack. Si `replenish` crea la
> orden y muere antes del `ack`, el mensaje vuelve y crea otra. En esta fase no apareció; la
> [Fase 26](26-idempotencia-y-outbox.md) lo provoca. Y queda abierta otra puerta: `inventory` confirma la venta y
> **después** publica. Si muere entre las dos cosas, la venta existe y el aviso no, con cualquier bus.

---

## ⚰️ 9. Autopsia: el aviso que no espera respuesta

**La decisión, con su mejor argumento.** En la [Fase 16](16-escalado-y-rollout.md), G5 mandó el aviso a `replenish` en
un hilo aparte, sin esperarlo: una venta no puede fallar porque el servicio de reposición esté lento o caído. Es el
argumento correcto, y la venta lo cumple: 30 de 30 con `201` en las cuatro filas de la sección 8.

**Por qué era razonable.** Desacoplar el tiempo de respuesta de la venta del de `replenish` es exactamente lo que pide
un mostrador. Y el aviso, al principio, no parecía crítico: si se pierde uno, la próxima venta pide otra reposición.

**Qué pasó después, con número.** "No esperar" se volvió "no saber": 2 de 30 avisos perdidos con un solo reinicio de
`replenish`, y la próxima venta no siempre llega (un producto que se vende poco puede quedarse días bajo el umbral sin
orden). Lo mismo que el aviso por archivo de 2020, con otro medio.

**Cuánto cuesta salir.** No esperar sigue estando bien; lo que faltaba era que **alguien guardara el aviso hasta que
lo confirmaran**. Ese alguien es el stream: un proceso de 12 MiB y unas 210 líneas entre `EventBus.java` y `events.ts`.

**Qué pregunta lo habría cambiado.** No *"¿espero o no espero la respuesta?"*, sino *"¿quién sabe que este aviso
todavía no lo procesó nadie?"*. Con el `POST` sin esperar, nadie. Con el stream, `num_pending`.

**Antes y después, con números:** el mismo reinicio. Con el `POST`: 28 órdenes de 30. Con NATS: 30 de 30, y diez avisos
que esperaron un minuto a que `replenish` volviera.

---

## 📖 10. Traducción

| En el monolito o en compose | En el laboratorio | Lo que cambia |
|---|---|---|
| una llamada HTTP sin esperar | un evento en un canal de pub/sub (Valkey) | nadie conoce la dirección de nadie; la garantía sigue siendo "a lo sumo una vez" |
| una cola en la base o un archivo en una carpeta | un stream con consumidor durable (NATS JetStream) | el bus guarda lo pendiente y lo reparte entre réplicas |
| "el último que lo lea lo marca" | `ack` explícito después del trabajo | lo no confirmado vuelve: al menos una vez, a veces dos |
| el lote que revisa si quedó algo | `num_pending` en `/jsz` | lo pendiente es un número que se puede alarmar |

Y al revés: un stream con un solo consumidor y sin réplicas es una cola en una base de datos, con mejor herramienta. Las
filas de la nube están en [a05](a05-diccionarios.md#️-local--nube).

🌩️ En la nube, el bus es un servicio gestionado, replicado en varias zonas, que no pierde lo que confirmó. 🚧 Lo que no
te da: que tu consumidor aguante el mensaje repetido, y que tu publicador no pierda el evento entre su commit y el bus.

---

## 🩺 11. Incidentes de esta fase

La fase no reserva incidentes. El mensaje perdido es su rotura y es de diseño: `kubectl` no lo ve, porque todos los
pods están `Ready` y todas las respuestas son `201`. Vuelve en los ejercicios 15 a 20.

---

## ⚖️ 12. Veredicto honesto: cuándo NO usar esto, y orquestación contra coreografía

**Si el aviso se puede perder sin daño, no pongas un stream.** Un evento para refrescar una pantalla o invalidar una
caché vive bien con pub/sub o con un `POST` sin esperar: perder uno de 30 no le cuesta nada a nadie. JetStream compra la
entrega a cambio de un servidor con disco, un consumidor que confirma, y la obligación de aguantar repetidos.

**Un bus es un sistema más.** Hay que desplegarlo, abrirle la red, vigilar su disco y su `num_pending`, y decidir qué
pasa cuando se llena (el stream de La Rebotica guarda un día y 512 MB). Con dos servicios que se hablan poco, un `POST`
con reintento y una tabla de pendientes en la base de quien avisa es menos infraestructura para la misma garantía.

**La coreografía no tiene un lugar donde mirar.** Esa es la pérdida más grande, y es la que hace el veredicto:

| | Orquestación (el préstamo, [Fase 24](24-la-saga-orquestada.md)) | Coreografía (el aviso, esta fase) |
|---|---|---|
| ¿En qué va? | `GET /loans/{id}`: el estado y cada paso | hay que preguntarle a cada servicio; si no tiene nada, no hay a quién más |
| Un vecino caído | la saga compensa en 355 ms | el bus guarda; 10 avisos esperaron 60 s y no se perdió ninguno |
| Un vecino lento | 8 órdenes huérfanas en 20 préstamos | `inventory` ni se entera: no espera a nadie |
| Agregar un interesado | cambiar el orquestador | suscribirse, sin tocar a `inventory` |
| La traza | una sola, con la saga entera (60 ms) | se corta en el bus |

**Orquesta** cuando el flujo tiene pasos que deshacer y alguien necesita saber en qué va cada uno: el préstamo, con su
cobro y su moto. **Coreografía** cuando es un hecho que a otros les sirve saber y nadie necesita esperar: el stock que
bajó. La mayoría de los sistemas tienen los dos, y La Vecina también: la saga del préstamo puede publicar *"préstamo
completo"* como evento para quien le interese.

**La pregunta del curso, para esta fase:** el contenedor te dio un proceso que publica y otro que consume. El orquestador
te dio un `StatefulSet` con disco para el stream, y una `NetworkPolicy` que, si no la abres, pierde todos los avisos en
silencio. **Te tocó a ti** elegir la garantía de entrega, confirmar después del trabajo, y aceptar que ahora un aviso
puede llegar dos veces.

---

## ⚠️ 13. Errores comunes y diagnóstico

**`replenish` no compila: `Cannot use namespace 'Valkey' as a type` y `This expression is not constructable`.** El
`import Valkey from 'iovalkey'` no funciona con la resolución de módulos de Node del proyecto; `iovalkey` exporta la
clase con nombre: `import { Valkey } from 'iovalkey'`.

**Con el bus encendido, ninguna orden nueva y nada en el log de `replenish`.** Si el log de `inventory` dice `aviso
perdido … el bus no contestó`, la `NetworkPolicy` de salida no tiene el bus: el chart lo agrega con `global.bus.*`, que
escribe `task bus:on`; un `task deploy` con un `.observability.json` viejo lo pierde. Comprobación: `kubectl -n apps get
networkpolicy allow-egress -o yaml | grep -A3 nats`.

**Órdenes repetidas con Valkey.** Hay dos réplicas de `replenish` (o un rollout en curso), y pub/sub entrega a todas
(sección 5.5). Con Valkey, una réplica; o NATS con un consumidor durable compartido.

**`num_pending` crece y no baja.** `replenish` no está consumiendo: mira si su log dice `consumiendo lab.inventory.stock-low`.
Si crece `num_ack_pending`, sí recibe pero no confirma: cada mensaje va a volver a los 30 s.

**La suite de G12 falla con `Filter error`.** Hurl 8 no acepta `!= null` dentro de un filtro de jsonpath; la suite usa
el filtro `last`.

---

## 📋 14. Checklist de validación

```text
[ ] task bus:on -- valkey; una venta bajo el umbral deja una orden con sourceEventId
[ ] con kill 1 en replenish durante 30 ventas, ves un aviso "a 0 suscriptores" en el log de inventory
[ ] task bus:off -- valkey y task bus:on -- nats; el log de replenish dice que consume de LAB_EVENTS
[ ] con kill 1 o con rollout restart, 30 ventas dejan 30 órdenes
[ ] con replenish en cero réplicas, num_pending crece en /jsz y baja a cero cuando vuelve
[ ] task conformance TARGET=cluster PROFILE=lab -- G12, y siguen pasando G5, G7 y G11
```

---

## 🧪 15. Ejercicios (24)

La mitad es contar órdenes, avisos y pendientes: un mensaje perdido no se ve, se cuenta.

## 🟢 Fácil — encender, publicar y contar (1–7)

### 🟢 Ejercicio 1 — El primer evento
Con `task bus:on -- valkey`, haz una venta que deje la existencia bajo el umbral y encuentra la orden que creó.

**Criterio:** una orden en `replenish` con `sourceEventId` igual al `eventId` de la línea `aviso de …` de `inventory`.

<details><summary>Solución</summary>

`kubectl -n apps logs deploy/inventory | grep "aviso de" | tail -1` da el `eventId`; `GET
/replenish/replenishment-orders` muestra la orden. Si el umbral no está por encima de la existencia, no hay aviso: fíjalo
con un `PATCH` antes.
</details>

### 🟢 Ejercicio 2 — Cuántos escuchan
Con Valkey, publica una venta con `replenish` en una réplica y otra con dos réplicas.

**Criterio:** el log de `inventory` dice `a 1 suscriptores` y `a 2 suscriptores`, y la segunda venta deja dos órdenes.

<details><summary>Solución</summary>

`kubectl -n apps scale deploy/replenish --replicas=2` (después, `task deploy FORCE=true` para devolverle a Helm las
réplicas). Pub/sub entrega a cada suscriptor: dos réplicas, dos órdenes.
</details>

### 🟢 Ejercicio 3 — El aviso perdido
Reproduce la sección 4.1 con Valkey.

**Criterio:** 30 ventas con `201`, menos de 30 órdenes, y una línea `a 0 suscriptores` por cada una que falta.

<details><summary>Solución</summary>

El reinicio tiene que ser del proceso, no del pod: `kubectl -n apps exec deploy/replenish -- kill 1`. Si cae entre dos
ventas, puede no perderse ninguna: repítelo, o haz más de una venta por segundo.
</details>

### 🟢 Ejercicio 4 — El stream, por dentro
Con NATS encendido, lee el stream y el consumidor en `/jsz`.

**Criterio:** el stream `LAB_EVENTS` con sus mensajes (`messages`) y el consumidor `replenish-stock-low` con
`num_pending` en 0.

<details><summary>Solución</summary>

`kubectl -n data exec nats-0 -- wget -qO- "http://127.0.0.1:8222/jsz?consumers=true"`. `messages` cuenta lo guardado
(un día), no lo pendiente: un mensaje confirmado sigue en el stream hasta que vence.
</details>

### 🟢 Ejercicio 5 — Un minuto sin `replenish`
Repite la sección 5.7.

**Criterio:** `num_pending` igual al número de ventas mientras `replenish` está en cero, y en cero al volver.

<details><summary>Solución</summary>

`kubectl -n apps scale deploy/replenish --replicas=0`, las ventas, `/jsz`, y `--replicas=1`. Cuidado: `kubectl scale`
deja a `kubectl` como dueño de `replicas`; el próximo `task deploy` necesita `FORCE=true`.
</details>

### 🟢 Ejercicio 6 — El rollout que duplica
Con Valkey y una réplica, haz 30 ventas a una por segundo y un `kubectl rollout restart deploy/replenish` en medio.

**Criterio:** más órdenes que ventas, y avisos `a 2 suscriptores` en el log de `inventory`.

<details><summary>Solución</summary>

El rollout de la [Fase 16](16-escalado-y-rollout.md) levanta el pod nuevo (`maxSurge: 1`) y espera a que esté listo antes
de bajar el viejo (`maxUnavailable: 0`), y el viejo además espera su `preStop`: varios segundos con dos suscriptores.
</details>

### 🟢 Ejercicio 7 — La red del bus
Con NATS encendido, mira la `NetworkPolicy` de salida de la cadena.

**Criterio:** una regla hacia `app.kubernetes.io/name: nats` en `data`, puerto 4222; y ninguna hacia Valkey.

<details><summary>Solución</summary>

`kubectl -n apps get networkpolicy allow-egress -o yaml`. La regla la pone el chart solo para el bus encendido: lo que no
se usa, cerrado ([Fase 20](20-seguridad-del-pod-y-de-la-red.md)).
</details>

## 🟡 Intermedio — llevar el patrón a otro sitio (8–14)

### 🟡 Ejercicio 8 — Sin la regla de red
Quita del chart la regla de salida hacia NATS, despliega y haz una venta bajo el umbral.

**Criterio:** la venta en `201`, ninguna orden nueva, y en el log de `inventory` un `aviso perdido … el bus no contestó`.

<details><summary>Solución</summary>

Con la `NetworkPolicy`, la conexión no se rechaza: espera hasta el plazo del cliente (como en la [Fase 22](22-resiliencia-y-caos.md)).
Esa espera cae en el hilo del aviso, no en la venta. Vuelve a poner la regla.
</details>

### 🟡 Ejercicio 9 — `nak` y la entrega que vuelve
Haz que el manejador de `replenish` falle para un producto (por ejemplo, `SKU-0007`) y mira cómo vuelve el mensaje.

**Criterio:** el log de `replenish` con `evento sin procesar; vuelve más tarde` cada 5 s, y `num_ack_pending` en 1.

<details><summary>Solución</summary>

Un `throw` en `handle` para ese SKU. El `nak(5000)` pide que lo entreguen en 5 s, para siempre: un mensaje que nunca se
puede procesar (*mensaje venenoso*) se repite sin fin. El ejercicio 17 le pone límite.
</details>

### 🟡 Ejercicio 10 — Un segundo interesado
Escribe un consumidor nuevo (en el lenguaje que quieras, como un `Deployment` aparte) que cuente los avisos por droguería.

**Criterio:** el contador ve todos los avisos y `replenish` también, sin tocar `inventory`.

<details><summary>Solución</summary>

Un consumidor durable **distinto** (otro `durable_name`) sobre el mismo sujeto: cada consumidor durable recibe todo. Si
usas el mismo nombre, se reparten los mensajes con `replenish` y los dos ven la mitad.
</details>

### 🟡 Ejercicio 11 — `ack` antes del trabajo
Mueve el `m.ack()` antes de `handle` y repite la caída del proceso con muchas ventas.

**Criterio:** algún aviso confirmado y sin orden.

**Pista de solución:** confirmar antes de trabajar es "a lo sumo una vez" con más pasos. Para verlo hace falta que el
proceso muera entre el ack y el `INSERT`: con ventas seguidas y varios reinicios, aparece. Vuelve a ponerlo después.

### 🟡 Ejercicio 12 — El stream que se llena
Baja `max_file_store` del stream a algo mínimo y publica avisos con `replenish` apagado.

**Criterio:** el comportamiento cuando el stream llega al límite, en el log de `inventory`.

<details><summary>Solución</summary>

El límite del servidor está en `platform/data/nats/nats.yaml`; el del stream, en su configuración (`max_bytes`). Con la
política por defecto, el stream descarta los mensajes viejos para hacer lugar: no rechaza la publicación, pierde por el
otro lado. Saber qué descarta tu bus cuando se llena es parte de elegirlo.
</details>

### 🟡 Ejercicio 13 — La línea que nadie lee
Agrega a `inventory` una métrica `lab_notices_lost_total` que cuente los avisos publicados a cero suscriptores o que el bus
no aceptó.

**Criterio:** con la prueba de la sección 4.1, la métrica en 1 (o en lo que se haya perdido).

<details><summary>Solución</summary>

Un `Counter` de Micrometer, como `lab.sales` (G6). Es la diferencia entre "queda una línea de log" y "alguien se entera":
una métrica se alarma.
</details>

### 🟡 Ejercicio 14 — Valkey en compose
Corre el aviso con Valkey en compose, en vez del cluster.

**Criterio:** una venta en compose deja su orden con `sourceEventId`.

<details><summary>Solución</summary>

Un servicio `valkey` con la misma imagen por digest, y `EVENT_BUS` y `VALKEY_URL` en `inventory` y `replenish`. En compose
se ve igual de claro el canal de difusión: dos réplicas de `replenish` (`--scale replenish=2`), dos órdenes.
</details>

## 🟠 Difícil — diagnosticar (15–20)

### 🟠 Ejercicio 15 — ¿Cuál se perdió?
Después de la prueba de la sección 4.1, encuentra qué venta no tiene orden **sin** leer el log de `inventory`.

**Criterio:** el `saleId` de la venta sin orden.

**Rúbrica:** hay que cruzar las ventas de `inventory` con las órdenes de `replenish` por `saleId`, que el evento lleva y la
orden **no guarda** (guarda `sourceEventId`). Propón qué agregar al contrato para que el cruce sea directo, y di por qué
en la coreografía ese cruce siempre lo hace alguien de afuera.

### 🟠 Ejercicio 16 — Diez órdenes de más
Con las órdenes repetidas del ejercicio 6, encuentra cuáles son repetidas y cuáles legítimas.

**Criterio:** la lista de pares de órdenes con el mismo `sourceEventId`.

**Rúbrica:** el `sourceEventId` es lo único que las distingue; sin él, dos órdenes de 9 unidades para la misma droguería
en el mismo segundo podrían ser dos ventas. Es el argumento de la [Fase 26](26-idempotencia-y-outbox.md): la clave ya
está, falta usarla.

### 🟠 Ejercicio 17 — El mensaje venenoso
Con el fallo del ejercicio 9, limita las entregas a 5 (`max_deliver`) y decide qué pasa con el mensaje después.

**Criterio:** el mensaje deja de entregarse después de 5 intentos, y queda un rastro de él.

**Rúbrica:** `max_deliver` en el consumidor; al agotarse, NATS publica un aviso en `$JS.EVENT.ADVISORY.CONSUMER.MAX_DELIVERIES…`.
Sin alguien que lo lea, es otro mensaje perdido. Propón la "cola de mensajes muertos" del laboratorio.

### 🟠 Ejercicio 18 — La traza, a través del bus
Propaga el `traceparent` en las cabeceras del mensaje de NATS y continúalo en `replenish`.

**Criterio:** una venta con aviso por NATS en Tempo con spans de `replenish` en la misma traza.

**Rúbrica:** en `inventory`, inyectar el contexto en los `Headers` del mensaje con el propagador de OpenTelemetry; en
`replenish`, extraerlo y abrir el span del manejador como hijo. La traza deja de cortarse, y además muestra cuánto esperó
el mensaje en el stream.

### 🟠 Ejercicio 19 — El consumidor que no confirma
Haz que `replenish` tarde 40 s en procesar un mensaje (más que `ack_wait`) y explica lo que ves.

**Criterio:** dos órdenes para el mismo evento, la segunda con `delivery: 2` en el log.

**Rúbrica:** el servidor no sabe si el consumidor está trabajando o muerto: a los 30 s sin ack, entrega otra vez. Las
salidas son subir `ack_wait`, avisar que se sigue trabajando (`working()`), o que procesar dos veces no haga daño (Fase
26).

### 🟠 Ejercicio 20 — Dos cadenas en el mismo stream
Con la segunda cadena ([Fase 14](14-helm-en-operacion.md)) desplegada con el bus encendido, haz una venta en cada una.

**Criterio:** qué `replenish` creó cada orden.

**Rúbrica:** las dos cadenas publican en el mismo sujeto y comparten el consumidor durable: el `replenish` de una cadena
puede crear órdenes de la otra. Propón el arreglo (un sujeto o un stream por cadena) y relaciónalo con el aislamiento de
la [Fase 20](20-seguridad-del-pod-y-de-la-red.md): la red no separa lo que el bus junta.

## 🔴 Muy difícil — medir y diseñar (21–24)

### 🔴 Ejercicio 21 — La tabla de la sección 8, con dispersión
Corre la prueba de la sección 8 cinco veces por fila.

**Criterio:** la tabla con mediana y rango de perdidos y repetidos por fila.

**Rúbrica:** el número de perdidos depende del segundo en que cae el reinicio; la conclusión (los dos primeros pierden,
NATS no) tiene que sobrevivir a las cinco corridas, o hay que decir que no sobrevivió.

### 🔴 Ejercicio 22 — Un `POST` con reintento contra un stream
Haz que el aviso por HTTP de G5 se guarde en una tabla de pendientes de `inventory` y se reintente cada 10 s hasta que
`replenish` conteste. Compáralo con NATS en la prueba de la sección 8.

**Criterio:** 30 de 30 con el reintento, y una tabla de costo: líneas de código, piezas nuevas, memoria.

**Rúbrica:** es un outbox casero (lo que formaliza la [Fase 26](26-idempotencia-y-outbox.md)), y gana en piezas: ningún servidor nuevo. Pierde en lo que
el stream da gratis: varios consumidores, repartir entre réplicas, ver lo pendiente sin consultar una base ajena.

### 🔴 Ejercicio 23 — El préstamo, por coreografía
Escribe el préstamo de la [Fase 24](24-la-saga-orquestada.md) como coreografía: `inventory` publica `loan.reserved`, `replenish` crea la orden y
publica `loan.dispatched`, e `inventory` cobra.

**Criterio:** un préstamo que termina con la misma existencia y la misma orden que con la saga, y un préstamo compensado
cuando el cobro falla.

**Rúbrica:** la compensación también es un evento (`loan.charge-failed`), y cada servicio la escucha. Responde, con el
código delante: ¿dónde se ve en qué va el préstamo? Es la fila 1 de la tabla de la sección 12.

### 🔴 Ejercicio 24 — La recomendación para Luz Marina
En una página: ¿el aviso de traslados a la Braqui debe pasar a un bus, y cuál?

**Criterio:** una página con la tabla de la sección 8 y la de la sección 12 como evidencia.

**Rúbrica:** el aviso es coreografía (un hecho que otro usa), no orquestación; la garantía necesaria es "al menos una
vez", que pub/sub no da; el costo de un stream; y la factura que la [Fase 26](26-idempotencia-y-outbox.md) cobra. La respuesta a *"si fallara, alguien
se enteraría"*: con el stream, alguien se entera; con el pub/sub, tampoco.

---

## 📚 16. Referencias

**Documentación oficial** (las versiones de [a01](a01-el-laboratorio.md))

- NATS, *JetStream*: https://docs.nats.io/nats-concepts/jetstream (streams, retención, persistencia).
- NATS, *Consumers*: https://docs.nats.io/nats-concepts/jetstream/consumers (durables, `ack_policy`, `ack_wait`,
  `max_deliver`).
- NATS, *Monitoring*: https://docs.nats.io/running-a-nats-service/nats_admin/monitoring (el 8222 y `/jsz`).
- NATS, cliente de JavaScript: https://github.com/nats-io/nats.js (los paquetes `@nats-io/*` de la versión 3).
- Valkey, *Pub/Sub*: https://valkey.io/topics/pubsub/ (la semántica "a lo sumo una vez", dicha por el propio proyecto).
- `iovalkey`: https://github.com/valkey-io/iovalkey

**Patrones, artículos y libros**

- Gregor Hohpe y Bobby Woolf, *Enterprise Integration Patterns*, Addison-Wesley, 2003: *Publish-Subscribe Channel*
  (https://www.enterpriseintegrationpatterns.com/patterns/messaging/PublishSubscribeChannel.html) y *Guaranteed Delivery*
  (https://www.enterpriseintegrationpatterns.com/patterns/messaging/GuaranteedMessaging.html). Veinte años y siguen siendo
  el vocabulario.
- Martin Fowler, *What do you mean by "Event-Driven"?*: https://martinfowler.com/articles/201701-event-driven.html
  (cuatro cosas distintas que se llaman igual).
- Chris Richardson, *Microservices Patterns*, Manning, 2018, capítulos 3 y 4 (mensajería, y sagas por coreografía).
- Sam Newman, *Building Microservices*, 2.ª edición, O'Reilly, 2021, capítulo 4 (*Microservice Communication Styles*).

**Orden de lectura sugerido:** antes, el artículo de Fowler; durante, los dos patrones de Hohpe con la sección 8
delante; después, *Consumers* de NATS, para la [Fase 26](26-idempotencia-y-outbox.md).

> ⚠️ Las URL y los contenidos cambian.

---

## 🏁 17. Resultado de la fase

```text
EL ESTADO AL CERRAR LA FASE 25 (cluster lab, valores de minimo)

  apps          inventory:g12 (EventBus: Valkey o NATS por EVENT_BUS), replenish:g12 (events.ts, el
                consumidor durable replenish-stock-low); los demás en :g10, storefront :g5
  data          nats-0 (JetStream, stream LAB_EVENTS en su PVC) junto a postgres-0; Valkey, apagado
  chart 0.25.0  global.bus.{valkey,nats}: EVENT_BUS, la dirección del bus y la regla de salida de la red
  tareas        task bus:on -- valkey|nats, task bus:off -- valkey|nats
  contratos     x-lab-events en inventory.yaml (StockLowEvent); sourceEventId en replenish.yaml; inventory.g12.hurl
```

> **La señal de que quedó bien:** *"Sé qué garantía de entrega tiene cada aviso, la confirmo después del trabajo, sé
> dónde mirar lo que nadie procesó, y espero que algo llegue dos veces."*

> 🏷️ **No cierres la fase sin el tag.** Con el checklist en verde, las suites pasando y `git status` limpio:
>
> ```bash
> git tag -a fase-25-la-coreografia -m "F25 cerrada: G12, el aviso de la venta como evento; Valkey pub/sub pierde el aviso sin suscriptor y duplica con dos; NATS JetStream con consumidor durable y ack explícito, sin pérdidas; orquestación contra coreografía, con lo medido en F24 y F25"
> ```
>
> Commits con prefijo `f25:`.

---

## 📌 Pendientes sugeridos

- **F26:** el mensaje que vuelve (ack perdido) y la escritura dual de `inventory` (venta confirmada, evento sin publicar);
  el `eventId` como clave de idempotencia; y la publicación que asegura el stream una sola vez (sección 6).
- **`a15`:** el mismo stream en tres miembros, y qué pasa con lo confirmado cuando cae uno.
- **`a01`:** las versiones del bus y su memoria en reposo (Valkey 10 MiB, NATS 12 MiB).
- **El traslado de la Braqui** (`a16`): cuál sería su stream, si el patrimonio se modernizara.
