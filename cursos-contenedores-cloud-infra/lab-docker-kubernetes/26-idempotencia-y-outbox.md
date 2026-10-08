# 🔁 Fase 26 — Idempotencia y outbox: dos motos, un inhalador, y el evento que se escribe con el dato

> **Curso:** Laboratorio de contenedores y Kubernetes local · Fase 26 de 27 · Parte IV — El lab de patrones distribuidos · **densa** ⭐
> **Perfil:** el cluster `lab`, con los valores de `minimo` · **Observabilidad encendida:** ninguna (las trazas, apagadas para las ráfagas: sección 13)
> **Motor de referencia:** Docker · 🦭 diverge en un comando: el `kill -9` desde el nodo es `podman exec` con Podman
> **Servicios que toca:** `inventory` (claves, outbox y su publicador) y `replenish` (consumidor idempotente, claves) · **Paso de generación:** G13 · Idempotencia y outbox
> **Depende de:** [Fase 25](25-la-coreografia.md) · **Habilita:** [Fase 27](27-el-veredicto-y-el-proyecto-final.md)
> **Incidentes que reserva:** ninguno · **Medición:** ninguna (la rotura de la sección 8)
> **Apéndices de apoyo:** [a01](a01-el-laboratorio.md), [a03](a03-contratos-y-prompts-de-generacion.md), [a04](a04-kubectl-y-k9s.md), [a05](a05-diccionarios.md)
> **Fecha de verificación ejecutada:** 05/10/2026 · macOS arm64
> **Objetivo:** provocar el mensaje que llega dos veces y la escritura dual en el momento exacto en que un proceso muere, y cerrarlos con claves de idempotencia, un consumidor que recuerda lo que procesó y un outbox publicado por un *sidecar* nativo.

---

## 🧭 1. Dónde estamos

La [Fase 25](25-la-coreografia.md) dejó de perder avisos: NATS JetStream los guarda hasta que `replenish` confirma. Y dejó
escrita la factura: **al menos una vez es a veces dos**. Si `replenish` crea la orden y muere antes del `ack`, el
mensaje vuelve. Dejó abierta otra puerta, la de enfrente: `inventory` confirma la venta y **después** publica. Si muere
entre las dos cosas, la venta existe y el aviso no, con cualquier bus.

La historia ya tiene nombre para la primera. Es lo de noviembre de 2021 que Wilson no deja olvidar (historia §1.10): una
regente de Chapinero escribió *"¿quién tiene?"* en el grupo, contestaron dos droguerías, y al mismo cliente le llegaron
**dos motos con el mismo inhalador**. El cliente pagó uno; el otro volvió en la moto, bajo la lluvia, y nadie supo a qué
droguería se le descontó. Wilson lo dijo en la reunión de esta fase sin levantar la voz:

> *"Yo no necesito que el sistema no se equivoque. Necesito que si me pregunta dos veces lo mismo, no me mande dos motos."*

Es exactamente la definición de **idempotencia**, dicha por el coordinador de domicilios. La segunda puerta, la de la
venta sin aviso, también tiene antecedente: el aviso de traslados de 2020 escribe el `.txt` **después** del commit
(historia §1.9), y sus dos últimos parches —la tabla de archivos procesados y el `.ok`— la dejaron abierta. Esta fase
cierra las dos, y las provoca primero.

---

## 🎯 2. Objetivos de esta fase

1. Provocar con `kill -9` y G12 la orden repetida (el `ack` que no llegó) y la venta sin aviso (la escritura dual), y
   contarlas cruzando las dos bases.
2. Generar G13: claves de idempotencia en la venta, el préstamo y la orden; un consumidor idempotente en `replenish`; y el
   outbox de `inventory`, con su publicador como *sidecar* nativo.
3. Repetir las roturas con G13 y probar cada defensa por separado, de forma determinista.
4. Cerrar la rotura de la [Fase 24](24-la-saga-orquestada.md): que la saga, ante un timeout, pregunte con la misma clave en
   vez de dejar motos huérfanas.
5. Escribir una compensación que se pueda repetir sin daño, y entender por qué hacía falta.

---

## 🚫 3. Qué NO entra todavía

- **Event sourcing y CQRS.** Son patrones de arquitectura de datos, no de infraestructura, y quedan fuera del curso.
- **La entrega "exactamente una vez"** como propiedad del bus. Lo que se construye aquí es su efecto: al menos una vez,
  más un consumidor que no repite.
- **Capturar los cambios del log de la base** (CDC) como alternativa al sondeo del outbox: se nombra en el veredicto y no
  se instala.
- **El veredicto del curso** → [Fase 27](27-el-veredicto-y-el-proyecto-final.md).

---

## 🧨 4. El problema, en el laboratorio

Las tres roturas se provocan con G12 desplegado (los dos servicios en `:g12`), el bus en NATS y las trazas apagadas. La
herramienta es una ráfaga: 16 clientes vendiendo durante 10 s en una droguería con el umbral por encima de la existencia,
de modo que **cada venta pide reposición**, y un `kill -9` a los 4 s. Al final, el script cruza las dos bases: ventas
confirmadas en la de `inventory` contra órdenes creadas por evento en la de `replenish`.

El `kill -9` se manda desde el nodo, porque desde adentro del contenedor el kernel no le entrega `SIGKILL` al proceso 1
(comprobado: `kubectl exec deploy/replenish -- kill -9 1` no hizo nada) y un `kubectl delete` deja apagarse con cortesía
([Fase 24](24-la-saga-orquestada.md)):

```bash
docker exec <nodo> pkill -9 -f "dist/main"                       # replenish
docker exec <nodo> pkill -9 -f inventory-0.0.1-SNAPSHOT.jar      # inventory
```

### 4.1 Las dos motos

`kill -9` a `replenish` en medio de la ráfaga, tres corridas:

```text
== corrida 1
respuestas al cliente: {201: 991}
ventas confirmadas en la base: 991 · órdenes: 992 · eventos distintos: 991 · ventas sin orden: 0 · órdenes repetidas: 1
== corrida 2
ventas confirmadas en la base: 1279 · órdenes: 1279 · eventos distintos: 1279 · ventas sin orden: 0 · órdenes repetidas: 0
== corrida 3
ventas confirmadas en la base: 1344 · órdenes: 1345 · eventos distintos: 1344 · ventas sin orden: 0 · órdenes repetidas: 1
```

La pareja de la tercera, en el log de `replenish` (antes y después del reinicio):

```text
{"time":"2026-10-05T05:00:10.863Z",…,"msg":"orden creada por evento","orderId":"RO-4221","eventId":"745d8e1f-…","saleId":"SALE-031312","delivery":1}
{"time":"2026-10-05T05:00:40.853Z",…,"msg":"orden creada por evento","orderId":"RO-5030","eventId":"745d8e1f-…","saleId":"SALE-031312","delivery":2}
```

La misma venta, el mismo evento, dos órdenes, la segunda **30 segundos después**: el `ack_wait` del consumidor. El proceso
creó la orden RO-4221 y murió antes de confirmar; JetStream esperó, no vio el ack, y le entregó el mensaje al proceso
nuevo, que hizo lo único que sabía: crear una orden. Dos motos con el mismo inhalador.

### 4.2 La venta que nadie avisó

`kill -9` a `inventory`, tres corridas. Las dos primeras salieron limpias (376 de 376, 364 de 364). La tercera:

```text
respuestas al cliente: {201: 386, 503: 7068}
ventas confirmadas en la base: 387 · órdenes: 386 · eventos distintos: 386 · ventas sin orden: 1 · órdenes repetidas: 0
```

**387 ventas en la base y 386 respuestas `201`**: una venta se confirmó y el cliente nunca supo, porque el proceso murió
antes de contestar. Y esa misma venta no tiene orden: murió también antes de publicar. Es la **escritura dual**: dos
escrituras en dos sistemas distintos —la venta en Postgres, el evento en NATS— sin nada que las haga atómicas. La
ventana es de pocos milisegundos, y por eso apareció una vez en tres corridas. En La Vecina, con 11.000 domicilios por día
(historia §7), una ventana de milisegundos no es rara: es el lunes.

### 4.3 El cliente que reintenta

La tercera rotura no necesita matar nada. El cliente pide un préstamo, la red tarda, y lo pide otra vez. Con G12 y la
cabecera `Idempotency-Key`, que G12 ignora:

```text
$ for i in 1 2; do curl -s -X POST …/inventory/loans -H 'Idempotency-Key: chapinero-salbutamol-0001' -d '{…}'; done
LOAN-000057 STARTED
LOAN-000058 STARTED
últimas dos órdenes DRO-003→DRO-007: [('RO-5033', 'PENDING'), ('RO-5034', 'PENDING')]
```

Dos préstamos, dos motos. Es el mismo episodio de noviembre de 2021 con otro mensajero: allá fueron dos droguerías que
contestaron el mismo *"¿quién tiene?"*; aquí, un cliente que preguntó dos veces.

### 4.4 Los dos parches que no alcanzaron

El script de la Braqui ya intentó resolver las dos cosas, y su historia es la autopsia de la sección 9: una tabla de
archivos procesados, que usa como clave **el nombre del archivo**, y el `.txt` escrito **después** del commit. Las dos
ideas eran correctas. Las dos tenían la clave equivocada o el orden equivocado.

> 🩻 **Esto sí funciona igual.** Una restricción `UNIQUE` y una transacción local hacen lo mismo que siempre. La fase no
> trae ninguna herramienta nueva para la base: trae la decisión de **qué** es único y **qué** se confirma junto.

---

## 🧩 5. Idempotencia y outbox, en `inventory` y `replenish`

### 5.1 Idempotente: hacerlo dos veces es hacerlo una

Una operación es **idempotente** si aplicarla dos veces deja el sistema igual que aplicarla una. `PUT /prices/{sku}`
lo es por naturaleza: poner el precio en 15.000 dos veces deja 15.000. `POST /sales` no: dos ventas son dos unidades
menos. Para que lo sea hace falta una **clave**: un identificador que quien pide elige **una vez por operación de
negocio**, no por intento, y que el servidor recuerda. Si llega una petición con una clave que ya conoce, devuelve lo que
ya hizo.

Dos detalles definen si funciona. **La clave es del hecho, no del sobre**: la tabla de la Braqui recordaba el nombre del
archivo, y un lote reintentado traía los mismos traslados en otro archivo. Y **la clave con otro cuerpo es un error**:
si alguien manda la misma clave con otra cantidad, no es un reintento, y el servidor no debe adivinar.

### 5.2 G13: la misma clave, la misma respuesta

El paso se generó con los prompts de G13 de [a03](a03-contratos-y-prompts-de-generacion.md#-los-prompts-de-g13). En las
dos bases, la clave es una columna con un **índice único parcial**:

```sql
-- schema-postgresql.sql de inventory (G13)
ALTER TABLE sales ADD COLUMN IF NOT EXISTS idempotency_key TEXT;
CREATE UNIQUE INDEX IF NOT EXISTS sales_idempotency_key ON sales (idempotency_key) WHERE idempotency_key IS NOT NULL;
```

Parcial, porque las ventas de antes de G13 no tienen clave y no pueden chocar entre ellas. Con la clave, lo primero que
hace la venta es buscar lo ya hecho: si existe con el mismo cuerpo, la devuelve sin preguntarle nada a `catalog` ni a
`pricing` y sin descontar. Si dos peticiones con la misma clave llegan a la vez, las dos pasan esa búsqueda, y la que
llega segunda choca con el índice al insertar: su transacción se deshace entera (el descuento incluido) y devuelve la
venta de la primera. **El índice es el que decide; la búsqueda solo ahorra trabajo.**

La suite de G13 usa claves nuevas en cada corrida (`{{newUuid}}` de Hurl) y pasó al primer intento:

```text
$ task conformance TARGET=cluster PROFILE=lab -- G13
Success /suite/inventory.g13.hurl (15 request(s) in 1247 ms)
```

Comprueba la venta dos veces (una sola unidad menos), la misma clave con otra cantidad (422), el préstamo dos veces (un
solo préstamo) y la orden de `replenish` dos veces (una sola orden, que `GET /replenishment-orders?idempotencyKey=`
encuentra).

### 5.3 El consumidor que recuerda

La clave de un evento ya existía desde la [Fase 25](25-la-coreografia.md): el `eventId`. `replenish` ahora lo anota en una tabla,
`processed_events`, **en la misma transacción** que la orden:

```typescript
// replenish/src/events.ts (G13): primero se anota el evento; si ya estaba, es una entrega repetida.
const created = await this.store.transaction(async (one) => {
  const fresh = await one<{ event_id: string }>(
    `INSERT INTO processed_events (event_id, processed_at) VALUES (?, ?)
     ON CONFLICT (event_id) DO NOTHING RETURNING event_id`, event.eventId, new Date().toISOString());
  if (!fresh) return undefined;
  const row = await one<OrderRow>(`INSERT INTO replenishment_orders … RETURNING *`, …);
  await one('UPDATE processed_events SET order_id = ? WHERE event_id = ?', orderId(row!.seq), event.eventId);
  return row;
});
```

El `ack` sigue después del commit. Si el proceso muere entre los dos, el evento vuelve, encuentra su fila en
`processed_events`, y no crea otra moto. Es la tabla de archivos procesados de la Braqui, con la clave correcta.

### 5.4 El outbox: el evento se escribe con la venta

Para la escritura dual no alcanza con una clave: el problema no es que el aviso llegue dos veces, sino que no llegue. La
salida es **no hacer dos escrituras en dos sistemas**. La venta escribe el evento en una tabla de su propia base, el
**outbox**, en la misma transacción que la venta:

```java
// SalesController.java (G13): con NATS, el evento entra al outbox en esta misma transacción: la venta y su aviso
// se confirman juntos o no se confirman. Lo publica el sidecar.
if (eventId != null && events.outbox()) {
    events.enqueue(jdbc, eventId, EventBus.stockLow(eventId, saleId, store, sku, level.reorderThreshold()));
}
```

Si el proceso muere antes del commit, no hay venta ni evento. Si muere después, hay las dos cosas, y el evento espera en
la tabla a que alguien lo publique. **`inventory` ya no le habla a NATS**: su cliente salió del `pom.xml`.

### 5.5 El publicador, como *sidecar* nativo

Alguien tiene que leer el outbox y publicar. Es un proceso aparte, `outbox-relay`, escrito en Go (unas 140 líneas, en
`services/inventory/relay/`), que cada medio segundo toma hasta cien eventos sin publicar, los manda a JetStream y les
pone `published_at`:

```sql
SELECT id, subject, payload FROM outbox WHERE published_at IS NULL
ORDER BY created_at LIMIT 100 FOR UPDATE SKIP LOCKED
```

`FOR UPDATE SKIP LOCKED` bloquea las filas que toma y salta las que otro ya tomó: con dos réplicas de `inventory` hay dos
publicadores, y no se pisan. Cada evento sale con la cabecera **`Nats-Msg-Id`** igual a su `eventId`: si el publicador
muere después de publicar y antes de anotarlo, lo publica otra vez, y JetStream descarta la copia porque ya vio ese id
dentro de su ventana de deduplicación (120 s en el stream del laboratorio, el valor por defecto).

¿Dónde corre? En el pod de `inventory`, como **contenedor *sidecar* nativo**: un `initContainer` con `restartPolicy:
Always`. Kubernetes lo arranca antes que la aplicación, lo mantiene vivo mientras el pod viva (y lo reinicia si muere),
y lo apaga después del contenedor principal. Es el sitio natural para un proceso que le sirve a uno solo y comparte su
ciclo de vida. Y no hace falta otra imagen: el Dockerfile de `inventory` compila el binario de Go en una etapa propia y lo
copia a `/app/outbox-relay`; el *sidecar* es la misma imagen con otro comando.

```yaml
# charts/platform/charts/inventory/templates/deployment.yaml (G13), con el bus en NATS
initContainers:
  - name: outbox-relay
    image: lab/inventory:g13
    restartPolicy: Always                 # esto lo vuelve sidecar nativo
    command: ["/app/outbox-relay"]
    env:
      - name: DATABASE_URL                # la base de inventory: el outbox es suyo
        valueFrom: {secretKeyRef: {name: inventory-db, key: DATABASE_URL}}
      - {name: NATS_URL, value: "nats://nats.data.svc.cluster.local:4222"}
    resources: {requests: {cpu: 10m, memory: 16Mi}, limits: {memory: 64Mi}}
```

```text
$ kubectl -n apps get pods | grep inventory
inventory-99845747d-mtmxd     2/2     Running     0               7s
$ kubectl -n apps logs deploy/inventory -c outbox-relay
{"component":"outbox-relay","interval_ms":500,"level":"INFO","msg":"publicando el outbox en LAB_EVENTS",…}
```

Los contenedores *sidecar* nativos son estables desde Kubernetes 1.33; el nodo del laboratorio es 1.36
([a01](a01-el-laboratorio.md)), así que no hace falta ninguna compuerta. Antes de esa versión, el *sidecar* era un
contenedor más del pod, sin orden de arranque ni de apagado, y un `Job` con un *sidecar* así no terminaba nunca.

### 5.6 La saga, que deja de dejar huérfanas

La rotura de la [Fase 24](24-la-saga-orquestada.md) era que un timeout en el despacho se trataba como una falla: la saga
compensaba, y `replenish` creaba la orden un segundo después. Con una clave, el timeout cambia de significado. El
`DISPATCH` manda `Idempotency-Key` igual al id del préstamo; ante un timeout (un "no sé"), **pregunta otra vez con la misma
clave** hasta tres veces, y si `replenish` ya la había creado, le devuelve la misma orden. Solo un error que `replenish`
contestó (un 503) es una falla. Y si al final hay que compensar sin número de orden, la busca por la clave:

```java
// LoanSaga.java (G13): la orden por la clave del préstamo. Si no hay ninguna, el DISPATCH de verdad no ocurrió.
List<?> found = sales.replenish().get().uri("/replenishment-orders?idempotencyKey={key}", loan.loanId())
        .retrieve().body(List.class);
```

**Prueba de fuego.** `task conformance TARGET=cluster PROFILE=lab -- G13` pasa, y siguen pasando G5, G7, G11 y G12. Y
las dos defensas, provocadas a mano (sección 8).

**El patrón a memorizar.** Lo que se puede repetir lleva una clave del hecho; lo que se tiene que avisar se escribe con
el dato; y lo que deshace también tiene que poder repetirse.

---

## 🔁 6. Los otros tres: donde no es mecánico

**`replenish`** necesitó lo que `inventory` ya tenía: transacciones de varias consultas. Su `Store` hablaba con el pool
de `pg` consulta por consulta; G13 le suma un `transaction(...)` que toma una conexión para todas (con SQLite, `BEGIN` y
`COMMIT` sobre la única). Sin eso, el registro del evento y la orden quedarían en dos transacciones, y la ventana que se
quería cerrar seguiría abierta entre ellas.

**El publicador en Go** es la tercera vez que el curso escribe Go (después de `pricing` y del generador de caos), y por la
misma razón: un binario estático de unos pocos MB que arranca al instante, que es lo que un *sidecar* tiene que ser. En
Java habría sido una segunda JVM en el mismo pod, con su propio arranque de segundos.

**`pricing`, `catalog` y `storefront`** no cambian. El `storefront` podría mandar una clave en cada venta (el botón que
alguien aprieta dos veces es el reintento más común del mundo), y es el ejercicio 13.

---

## 🪞 7. Tu instinto de compose dice… y las apuestas

Tu instinto, en su mejor versión: *"si lo guardé y avisé, quedó hecho"*. En un solo proceso que nunca muere entre dos
líneas, es cierto. Las cuatro apuestas se escribieron antes de la primera ráfaga, el 04/10/2026 a las 23:54.

> 🪞 **Apuesta 1.** Con G12, un `kill -9` a la JVM de `inventory` durante una ráfaga deja al menos una venta confirmada sin
> su orden.
> **Resultado:** ganada a la tercera corrida (387 ventas, 386 órdenes); las dos primeras salieron limpias.

> 🪞 **Apuesta 2.** Con G12, un `kill -9` a `replenish` durante una ráfaga deja al menos una orden repetida.
> **Resultado:** ganada: una repetida en dos de tres corridas (RO-4221 y RO-5030, sección 4.1).

> 🪞 **Apuesta 3.** Con G13, las dos pruebas dejan cero ventas sin orden y cero órdenes repetidas.
> **Resultado:** ganada en seis corridas válidas (tres a cada servicio). Pero ningún `kill -9` cayó esta vez en la ventana
> del `ack`, así que "cero" no probaba nada por sí solo: las dos defensas se probaron aparte, en la sección 8.

> 🪞 **Apuesta 4.** Con G13, *Sogamoso con lluvia* sobre 20 préstamos deja cero órdenes huérfanas.
> **Resultado:** ganada, **con un arreglo en medio**: tres préstamos se quedaron más de diez minutos compensando contra un
> 409 (sección 8). Arreglado, cero huérfanas.

---

## 📏 8. La rotura, y lo que costó cerrarla

### 8.1 Antes y después

Las mismas pruebas con G12 y con G13. Una fila por corrida válida; la ráfaga es de 16 clientes durante 10 s, con el
`kill -9` a los 4 s.

| Prueba | G12 | G13 |
|---|---|---|
| `kill -9` a `replenish` (órdenes repetidas) | 1 · 0 · 1 | 0 · 0 · 0 |
| `kill -9` a `inventory` (ventas sin orden) | 0 · 0 · 1 | 0 · 0 · 0 |
| el mismo préstamo pedido dos veces con clave | 2 préstamos, 2 órdenes | 1 préstamo, 1 orden (la suite) |
| *Sogamoso con lluvia*, 20 préstamos (huérfanas) | 8 (F24) | 0 |

Con G13, en la segunda corrida contra `inventory` hubo **402 ventas en la base y 400 respuestas `201`**: dos ventas que el
cliente no supo que se hicieron, como en la sección 4.2. Las dos tienen su orden, porque su evento quedó en el outbox con
ellas.

### 8.2 Las dos defensas, a propósito

Como ningún `kill -9` cayó en la ventana con G13, cada defensa se provocó a mano, en la base de `inventory`:

```text
-- 1. el mismo evento, otra vez, con otro id de outbox (la segunda entrega que JetStream no puede reconocer):
INSERT INTO outbox (id, subject, payload, created_at) SELECT 'copia-' || id, … RETURNING id
 copia-4cf7c785-907f-4d04-99d0-4479c0dad578
-- 2. un evento ya publicado, marcado como pendiente (el relay murió antes de anotarlo):
UPDATE outbox SET published_at = NULL WHERE id = … RETURNING id
 cda67b7a-29de-4ece-bf9a-8214aa244cf4
```

```text
{"component":"outbox-relay","eventId":"cda67b7a-…","msg":"evento ya publicado; JetStream descartó la copia",…}
{"component":"outbox-relay","count":2,"msg":"eventos publicados",…}
{"service":"replenish","msg":"evento repetido: ya tiene su orden","eventId":"4cf7c785-…","saleId":"SALE-037515","delivery":1}
```

La primera copia la frenó JetStream, por el `Nats-Msg-Id`. La segunda llegó a `replenish` como un mensaje nuevo (con
`delivery: 1`: para el bus no era repetido) y la frenó `processed_events`. **Hacen falta las dos**: la del bus solo ve su
ventana de 120 s y sus propios ids; la del consumidor ve el hecho.

### 8.3 La compensación que no terminaba

La apuesta 4 encontró la última rotura de la Parte IV. Con *Sogamoso con lluvia*, tres préstamos se quedaron en
`COMPENSATING` más de diez minutos, con el barrido reintentando cada 30 s:

```text
05:45:23 DISPATCH UNDO FAILED replenish: 409 Conflict: "{"error":"conflict","message":"la orden está en CANCELLED, no en PENDING"}"
05:45:53 DISPATCH UNDO FAILED replenish: 409 Conflict: "{… la orden está en CANCELLED, no en PENDING"}"
05:46:23 DISPATCH UNDO FAILED replenish: 409 Conflict: "{… la orden está en CANCELLED, no en PENDING"}"
```

La cancelación **sí había llegado**, en un intento cuya respuesta se perdió en el caos. Cada reintento recibía 409, porque
la orden ya no estaba en `PENDING`, y la saga lo leía como una falla. Uno de esos préstamos acumuló 39 pasos en su
registro. **La compensación no era idempotente**, y una compensación se reintenta siempre. El arreglo fue de una línea en
`replenish` y un párrafo en el contrato: cancelar una orden ya `CANCELLED` la devuelve con 200; 409 queda solo para una
orden que salió. Con eso (y la lluvia parada), los tres terminaron en menos de seis minutos. El prompt de G13 de
[a03](a03-contratos-y-prompts-de-generacion.md#-los-prompts-de-g13) lo pide ahora; la primera versión no lo pedía.

**Lo que costó:** una columna y un índice en tres tablas, una tabla de eventos procesados, la tabla del outbox, un
`Store.transaction` en Node, unas 140 líneas de Go, un contenedor de 16 MiB más en cada pod de `inventory`, y el medio
segundo que el evento espera en el outbox antes de salir. Lo que **no** costó: la venta sigue siendo una sola transacción
local, igual de rápida.

---

## ⚰️ 9. Autopsia: los dos parches de 2020

**La decisión, con su mejor argumento.** En el primer año del aviso de traslados, dos sustos se arreglaron con dos
parches (historia §1.9): una tabla en la base de la Braqui con los nombres de archivo ya procesados, para que un reproceso
no duplicara traslados; y el lote del Siga, que confirma los traslados en la base y después escribe el `.txt`. Los dos
eran razonables, y el segundo ni siquiera parecía una decisión: era el orden natural del código.

**Por qué era razonable.** La tabla de procesados es exactamente el consumidor idempotente de la sección 5.3. Y escribir
el archivo después del commit evita el error contrario —avisar un traslado que la base después deshace—.

**Qué pasó después.** Cada parche tenía un detalle equivocado. La tabla usa como clave **el nombre del archivo**, y un
lote del Siga que falla a la mitad se reintenta con otro minuto en el nombre y los mismos traslados adentro: la tabla no
lo reconoce, y los traslados se duplican. El archivo después del commit es **la escritura dual**: si el proceso muere
entre los dos pasos, el traslado existe en el Siga y en ningún archivo. En el laboratorio, la versión de La Rebotica de
cada error se midió con números: una orden repetida en dos de tres corridas con la clave del sobre (G12 no tenía clave
de hecho), y una venta sin aviso en una de tres con la escritura después del commit.

**Cuánto cuesta salir.** No es tirar los parches: es moverles la clave y el orden. La clave pasa del nombre del archivo
al **id del traslado** (el `eventId`), y el archivo se reemplaza por una tabla en la misma base y la misma transacción que
el traslado (el outbox), con alguien que la publique después.

**Qué pregunta lo habría cambiado.** Para el primero: *"¿qué es lo que no se puede repetir, el archivo o el traslado?"*.
Para el segundo: *"¿qué pasa si el proceso muere entre esta línea y la siguiente?"*. Es la pregunta que esta fase le hace
a cada par de escrituras.

**Antes y después, con números:** con la clave del sobre y el aviso después del commit (G12), 2 órdenes repetidas en 3
corridas y 1 venta sin aviso en otras 3; con la clave del hecho y el outbox (G13), 0 y 0 en seis.

---

## 📖 10. Traducción

| En el monolito o en compose | En el laboratorio | Lo que cambia |
|---|---|---|
| una transacción que guarda el dato y su aviso en la misma base | el outbox y su publicador | el aviso sale después, en otro proceso, con medio segundo de demora |
| una restricción `UNIQUE` sobre lo que no se puede repetir | `idempotency_key` y `processed_events` | la clave la elige quien pide, una por operación |
| un proceso de fondo que lee una tabla de pendientes | el *sidecar* nativo `outbox-relay` | vive y muere con el pod, arranca antes y se apaga después |
| reintentar "por si acaso" | reintentar con la misma clave | solo es seguro si el otro lado recuerda la clave |

Y al revés: un outbox con un solo consumidor que lee la tabla directamente es una cola en la base; el bus agrega a los
demás interesados. Las filas de la nube, en [a05](a05-diccionarios.md#️-local--nube).

🌩️ En la nube, varios buses gestionados deduplican por un id del mensaje dentro de una ventana, como JetStream. 🚧 Lo que
ninguno te da: la clave de idempotencia de tu API, el consumidor que recuerda más allá de la ventana, y el outbox.

---

## 🩺 11. Incidentes de esta fase

La fase no reserva incidentes. Sus roturas son de diseño y no las ve `kubectl`: todos los pods están `Running` y todas
las respuestas son `201`. Vuelven en los ejercicios 15 a 20.

---

## ⚖️ 12. Veredicto honesto: cuándo NO usar esto

**Si no hay dos escrituras en dos sistemas, no hay outbox que poner.** Un servicio que guarda en su base y no avisa a
nadie no tiene escritura dual. El outbox es un costo fijo —una tabla, un publicador por pod, medio segundo de demora—
que solo se paga donde existe la segunda escritura.

**La clave de idempotencia no es gratis para quien llama.** Hay que generarla, guardarla mientras se reintenta, y no
reutilizarla para otra cosa (la suite lo castiga con 422). Para una lectura, o para un `PUT` que ya es idempotente, sobra.

**Sondear la tabla cada medio segundo** es lo más simple que funciona, y tiene techo: con miles de eventos por segundo,
el sondeo se queda corto y la tabla crece. Las alternativas —que la base avise (`LISTEN`/`NOTIFY` en Postgres) o leer
los cambios directamente del log de la base (CDC)— cambian la demora y la carga por más piezas.

**Los repetidos que ya existen no se arreglan con una restricción.** La base del laboratorio quedó con doce parejas de
órdenes repetidas (las de las Fases 25 y 26) que G13 no toca: hay que buscarlas y cancelarlas a mano. Y por eso el
consumidor idempotente se hizo con una tabla nueva y no con un índice único sobre `source_event_id`: el índice no se
habría podido crear sobre esos datos.

**La pregunta del curso, para esta fase:** el contenedor te dio un proceso que guarda y publica. El orquestador te dio un
*sidecar* nativo que arranca antes, vive con el pod y se apaga después, y que ninguna versión anterior de Kubernetes daba
así. **Te tocó a ti** decidir qué es único, qué se confirma junto, y que deshacer también se pueda repetir.

---

## ⚠️ 13. Errores comunes y diagnóstico

**Con las trazas encendidas, una ráfaga tumba el cluster.** Síntoma: `catalog` en `CrashLoopBackOff` por la sonda de vida,
y `kubectl top pods -A --sort-by=cpu` con Tempo arriba (6.578m en el laboratorio). Causa: unas 13.000 peticiones en 10 s
son decenas de miles de spans. Salida: `task obs:off FORCE=true -- traces`; si el *upgrade* tampoco alcanza a terminar
(`Progress deadline exceeded`, y `--rollback-on-failure` vuelve a encender las trazas), primero `kubectl -n observability
scale deploy/tempo --replicas=0`.

**`task obs:off -- traces FORCE=true` no hace lo que dice.** Lo que va después de `--` es argumento de la tarea: `FORCE`
va antes (`task obs:off FORCE=true -- traces`).

**Un préstamo en `COMPENSATING` con `409 … la orden está en CANCELLED`.** Es `replenish` anterior al arreglo de la
sección 8.3: la cancelación no es idempotente. Comprobación: `kubectl -n apps get deploy replenish -o
jsonpath='{..image}'` y la línea `if (row.status === 'CANCELLED') return toOrder(row);` en el controlador.

**El outbox crece y nadie publica.** `SELECT count(*) FROM outbox WHERE published_at IS NULL` sube: mira el log del
*sidecar* (`kubectl -n apps logs deploy/inventory -c outbox-relay`); si dice `sin NATS` o no hay *sidecar*
(`READY 1/1`), el bus no está en NATS (`task bus:on -- nats`).

**La suite de G13 falla con la venta repetida en otro id.** La clave cambió entre las dos peticiones: `{{newUuid}}` genera
un valor nuevo **cada vez que se usa**; la suite la guarda una vez en una variable de `[Options]`.

---

## 📋 14. Checklist de validación

```text
[ ] task conformance TARGET=cluster PROFILE=lab -- G13, y siguen pasando G5, G7, G11 y G12
[ ] el pod de inventory en 2/2, y el log de outbox-relay dice que publica en LAB_EVENTS
[ ] una venta con la misma Idempotency-Key dos veces: una sola venta y una sola unidad menos
[ ] un evento copiado en el outbox con otro id: "evento repetido: ya tiene su orden" en replenish
[ ] un evento marcado como pendiente: "JetStream descartó la copia" en el sidecar
[ ] Sogamoso con lluvia sobre 20 préstamos: cero órdenes huérfanas y ninguna clave repetida
```

---

## 🧪 15. Ejercicios (24)

Un tercio es provocar el momento exacto en que algo muere, y contar después. La idempotencia no se ve: se cuenta.

## 🟢 Fácil — repetir sin repetir (1–7)

### 🟢 Ejercicio 1 — La venta, dos veces
Haz la misma venta dos veces con la misma `Idempotency-Key`.

**Criterio:** el mismo `id` en las dos respuestas, y la existencia con una sola unidad menos.

<details><summary>Solución</summary>

`curl -X POST …/inventory/sales -H 'Idempotency-Key: mi-venta-1' -d '{…}'` dos veces. La segunda respuesta no trae
`replenishmentRequested`: ese dato no se guarda, y la venta repetida devuelve lo guardado.
</details>

### 🟢 Ejercicio 2 — La misma clave, otra venta
Con la clave del ejercicio 1, pide otra cantidad.

**Criterio:** 422 con `la clave … ya se usó con otra venta`, y la existencia igual.

<details><summary>Solución</summary>

La clave identifica una operación; con otro cuerpo, el servidor no puede saber cuál de las dos quisiste. El 422 es para
quien llama: reutilizó una clave.
</details>

### 🟢 Ejercicio 3 — El *sidecar*, por dentro
Encuentra el *sidecar* del pod de `inventory` y lee su log.

**Criterio:** `outbox-relay true` en el estado de los `initContainers`, y una línea `eventos publicados` después de una
venta que pide reposición.

<details><summary>Solución</summary>

`kubectl -n apps get pod -l app.kubernetes.io/name=inventory,app.kubernetes.io/component=backend -o
jsonpath='{.items[0].spec.initContainers[*].name} {.items[0].status.initContainerStatuses[*].started}'` y `kubectl -n apps
logs deploy/inventory -c outbox-relay`.
</details>

### 🟢 Ejercicio 4 — El outbox, en la base
Haz una venta que pida reposición y mira su evento en la tabla `outbox`.

**Criterio:** la fila con el `eventId`, y `published_at` puesto menos de un segundo después de `created_at`.

<details><summary>Solución</summary>

`kubectl -n data exec postgres-0 -- psql -U inventory -d inventory -c "SELECT id, created_at, published_at FROM outbox
ORDER BY created_at DESC LIMIT 1"`. La diferencia es la demora del outbox: hasta medio segundo de sondeo, más la
publicación.
</details>

### 🟢 Ejercicio 5 — Las dos defensas
Reproduce la sección 8.2.

**Criterio:** `JetStream descartó la copia` en el *sidecar* y `evento repetido` en `replenish`.

<details><summary>Solución</summary>

El `UPDATE` que marca un evento como pendiente tiene que caer dentro de la ventana de 120 s desde que se publicó; si es
más viejo, JetStream lo acepta y lo frena `processed_events` (y ves `evento repetido` en vez de `descartó la copia`).
</details>

### 🟢 Ejercicio 6 — La orden por su clave
Crea una orden en `replenish` con una clave y búscala por la clave.

**Criterio:** `GET /replenishment-orders?idempotencyKey=<clave>` devuelve una lista con esa orden; con otra clave, una
lista vacía.

<details><summary>Solución</summary>

Es lo que usa la saga para compensar un despacho del que no supo el resultado: una pregunta que se puede hacer sin
haber recibido nunca el número de la orden.
</details>

### 🟢 Ejercicio 7 — El préstamo, dos veces
Repite la sección 4.3 con G13.

**Criterio:** el mismo `LOAN-…` en las dos respuestas, y una sola orden en `replenish` con esa clave.

<details><summary>Solución</summary>

La segunda petición encuentra el préstamo por su clave y lo devuelve (202) sin arrancar otra saga. La orden lleva como
clave el id del préstamo, no la clave del cliente: son dos operaciones distintas, con dos claves.
</details>

## 🟡 Intermedio — llevar el patrón a otro sitio (8–14)

### 🟡 Ejercicio 8 — La carrera de la clave
Manda la misma venta con la misma clave desde 10 clientes a la vez.

**Criterio:** diez respuestas `201` con el mismo `id` y una sola unidad menos; en el log, alguna petición que resolvió la
carrera con el índice.

<details><summary>Solución</summary>

Las diez pasan la búsqueda inicial casi a la vez; la primera inserta, las demás chocan con el índice único
(`DuplicateKeyException`), se deshacen enteras y devuelven la primera. Con Postgres, el `FOR UPDATE` de la existencia
las pone en fila antes.
</details>

### 🟡 Ejercicio 9 — El *sidecar* que muere
Mata el proceso del publicador (`docker exec <nodo> pkill -9 -f outbox-relay`) durante una ráfaga corta.

**Criterio:** el pod sigue `Running` con `RESTARTS` del *sidecar* en 1, ninguna venta falla, y al final todas las ventas
tienen su orden.

<details><summary>Solución</summary>

Mientras el *sidecar* está caído, los eventos se acumulan en el outbox; al volver, los publica. La venta no depende de él:
esa es la diferencia con publicar desde la venta.
</details>

### 🟡 Ejercicio 10 — Dos réplicas, dos publicadores
Escala `inventory` a dos réplicas y haz una ráfaga.

**Criterio:** ninguna orden repetida, y eventos publicados por los dos *sidecars*.

<details><summary>Solución</summary>

`FOR UPDATE SKIP LOCKED` reparte las filas entre los dos. Sin `SKIP LOCKED`, el segundo esperaría al primero; sin `FOR
UPDATE`, los dos publicarían lo mismo (y lo frenaría el `Nats-Msg-Id`). Después, `task deploy FORCE=true` para
devolverle las réplicas a Helm.
</details>

### 🟡 Ejercicio 11 — El outbox sin bus
Apaga NATS (`task bus:off -- nats`) y haz una venta que pida reposición.

**Criterio:** la orden llega por el `POST` de G5, y el outbox no recibe nada nuevo.

<details><summary>Solución</summary>

Sin `EVENT_BUS`, `inventory` vuelve al aviso por HTTP y el *sidecar* no existe. El outbox solo se usa con NATS: con Valkey,
G13 sigue publicando directo, porque Valkey es el bus frágil de la [Fase 25](25-la-coreografia.md).
</details>

### 🟡 Ejercicio 12 — Cuánto espera un evento
Mide la demora del outbox: `published_at - created_at` en cien eventos.

**Criterio:** mediana y máximo, y cómo cambian con `RELAY_INTERVAL_MS` en 100 y en 2000.

<details><summary>Solución</summary>

Con un sondeo de 500 ms, la demora es de 0 a 500 ms más la publicación. Bajarla carga más la base con consultas vacías;
subirla demora el aviso. Es la perilla que `LISTEN`/`NOTIFY` o el CDC cambian por otra cosa.
</details>

### 🟡 Ejercicio 13 — El botón de la página
Haz que el `storefront` mande una `Idempotency-Key` nueva en cada venta, y la misma si el usuario aprieta dos veces
antes de recibir respuesta.

**Criterio:** dos clics rápidos, una venta.

<details><summary>Solución</summary>

Una clave por intención de compra (`crypto.randomUUID()` al cargar el producto, renovada después de una respuesta), no
por clic. La ruta de `inventory` en la puerta tiene que autorizar la cabecera `Idempotency-Key` en CORS (G5 solo autorizó
`Content-Type`).
</details>

### 🟡 Ejercicio 14 — La compensación, dos veces
Cancela dos veces la misma orden con `SAGA_COMPENSATION`.

**Criterio:** dos respuestas 200 con la orden en `CANCELLED`.

<details><summary>Solución</summary>

Es el arreglo de la sección 8.3. Una orden despachada, en cambio, sigue dando 409: deshacer una moto que salió no es
repetir una cancelación.
</details>

## 🟠 Difícil — diagnosticar (15–20)

### 🟠 Ejercicio 15 — Las parejas que quedaron
Encuentra todas las órdenes repetidas que dejaron las Fases 25 y 26 y cancélalas, dejando la primera de cada pareja.

**Criterio:** la consulta que las encuentra y, después, cero eventos con dos órdenes vivas.

**Rúbrica:** se agrupa por `source_event_id` y se cancela la de mayor `seq` con un código de razón propio (agrégalo a la
tabla, no lo inventes en el código). Explica por qué no se pudo resolver con un índice único: los datos ya lo violaban.

### 🟠 Ejercicio 16 — La venta sin respuesta
Con G13, provoca una venta confirmada sin respuesta al cliente (sección 8.1) y encuéntrala.

**Criterio:** el `saleId` de una venta que está en la base y que el cliente no recibió, con su orden en `replenish`.

**Rúbrica:** el cliente no sabe si vendió; si reintenta **sin** clave, vende dos veces; **con** clave, recibe la venta que
ya existía. Es la razón por la que la clave tiene que estar del lado del cliente.

### 🟠 Ejercicio 17 — La ventana de JetStream
Marca como pendiente un evento publicado hace más de dos minutos, y predice antes qué defensa lo va a frenar.

**Criterio:** `evento repetido` en `replenish` y ninguna línea `descartó la copia` en el *sidecar*.

**Rúbrica:** fuera de la ventana de 120 s, JetStream no recuerda el id y acepta el mensaje. Si `replenish` no tuviera
`processed_events`, sería una moto más. La deduplicación del bus es una optimización; la del consumidor, la garantía.

### 🟠 Ejercicio 18 — La venta y el aviso, separados otra vez
Mueve el `enqueue` del outbox fuera de la transacción de la venta, y repite la ráfaga con `kill -9` a `inventory` hasta
que aparezca una venta sin orden.

**Criterio:** una venta sin orden, con el outbox fuera de la transacción.

**Rúbrica:** con el outbox fuera de la transacción vuelve la escritura dual, ahora entre dos escrituras a la misma base:
el problema no era NATS, era confirmar por separado. Vuelve a ponerlo adentro.

### 🟠 Ejercicio 19 — ¿Reintentar o compensar?
Con *Sogamoso con lluvia*, cuenta cuántos préstamos completó G13 gracias a los reintentos con clave, y cuántos compensó.

**Criterio:** la tabla G11 contra G13: completos, compensados y huérfanas.

**Rúbrica:** en el laboratorio, 10 completos con G11 y 14 con G13 sobre 20; las diferencias son despachos que tardaron y
que el reintento encontró hechos. Explica por qué reintentar solo es seguro con la clave.

### 🟠 Ejercicio 20 — El 409 que sí es para siempre
Marca a mano como `DISPATCHED` la orden de un préstamo que va a compensar, y mira qué hace la saga.

**Criterio:** el préstamo en `COMPENSATING`, con un `DISPATCH UNDO FAILED` por 409 cada 30 s.

**Rúbrica:** este 409 no se arregla con idempotencia: la moto salió. La saga tiene que distinguir "ya lo hice" (200) de
"ya no se puede" (409), y para el segundo, otra salida: un estado que pida a una persona.

## 🔴 Muy difícil — medir y diseñar (21–24)

### 🔴 Ejercicio 21 — La tabla de la sección 8, con más corridas
Corre cada fila de la tabla de la sección 8.1 diez veces con G12 y diez con G13.

**Criterio:** la tabla con conteos por corrida y el total.

**Rúbrica:** con G12, la frecuencia de cada rotura (cuántas corridas de diez la muestran); con G13, cero. Si G13 muestra
algo distinto de cero, es un hallazgo, y se publica.

### 🔴 Ejercicio 22 — `LISTEN`/`NOTIFY` contra el sondeo
Haz que el *sidecar* espere un `NOTIFY` de la base en vez de sondear cada 500 ms, sin perder el sondeo como respaldo.

**Criterio:** la demora del ejercicio 12, antes y después.

**Rúbrica:** la venta hace `NOTIFY` en su transacción (se entrega al confirmar); el *sidecar* escucha con una conexión
propia. Un `NOTIFY` perdido (el *sidecar* reconectándose) no puede perder el evento: el sondeo lo encuentra igual.

### 🔴 Ejercicio 23 — El aviso de traslados, con outbox
Diseña el aviso de traslados de Contingencia con un outbox en su Postgres y un publicador, en lugar del `.txt`.

**Criterio:** el diseño en una página, con las tablas y el flujo, y qué parche de 2020 reemplaza cada pieza.

**Rúbrica:** el outbox en la transacción del lote reemplaza al archivo después del commit; el id del traslado reemplaza al
nombre del archivo; el stream reemplaza a la carpeta compartida; el consumidor idempotente reemplaza a la tabla de
procesados; y el `.ok` desaparece, porque un mensaje confirmado está entero.

### 🔴 Ejercicio 24 — La recomendación para Wilson
En una página: ¿cuándo deja de mandar dos motos el sistema de La Vecina?

**Criterio:** una página con la tabla de la sección 8.1 como evidencia.

**Rúbrica:** las dos motos de 2021 eran dos droguerías contestando el mismo pedido (dos productores); las de esta fase,
una entrega repetida (un consumidor). Las dos se cierran con una clave del hecho —el pedido del cliente— que todos
reconocen. Lo que sigue sin resolverse (una moto que salió no se cancela) también va.

---

## 📚 16. Referencias

**Documentación oficial** (las versiones de [a01](a01-el-laboratorio.md))

- Kubernetes, *Sidecar Containers*: https://kubernetes.io/docs/concepts/workloads/pods/sidecar-containers/ (el
  `initContainer` con `restartPolicy: Always`, su orden de arranque y de apagado).
- NATS, *Streams* (la ventana de duplicados y `Nats-Msg-Id`): https://docs.nats.io/nats-concepts/jetstream/streams
- PostgreSQL, *SELECT* (`FOR UPDATE SKIP LOCKED`): https://www.postgresql.org/docs/current/sql-select.html
- Hurl, *Templates* (`newUuid`): https://hurl.dev/docs/templates.html

**Patrones, especificaciones y artículos**

- Chris Richardson, *Transactional outbox*: https://microservices.io/patterns/data/transactional-outbox.html, e
  *Idempotent consumer*: https://microservices.io/patterns/communication-style/idempotent-consumer.html. Y su libro,
  *Microservices Patterns*, Manning, 2018, capítulo 3.
- IETF, *The Idempotency-Key HTTP Header Field* (borrador del grupo `httpapi`):
  https://datatracker.ietf.org/doc/draft-ietf-httpapi-idempotency-key-header/ — es un borrador, no un estándar: el
  nombre de la cabecera ya es de uso común, y la semántica de esta fase sigue la del borrador.
- Brandur Leach, *Designing robust and predictable APIs with idempotency* (Stripe): https://stripe.com/blog/idempotency
  — la clave del lado del cliente, explicada por quien la popularizó.
- Sam Newman, *Building Microservices*, 2.ª edición, O'Reilly, 2021, capítulo 6 (sagas, y por qué las compensaciones
  tienen que poder repetirse).

**Orden de lectura sugerido:** antes, el artículo de Stripe; durante, *Transactional outbox* con la sección 5.4 delante;
después, *Sidecar Containers*, para ver qué más cabe en ese patrón.

> ⚠️ Las URL y los contenidos cambian; el borrador de la IETF, más que el resto.

---

## 🏁 17. Resultado de la fase

```text
EL ESTADO AL CERRAR LA FASE 26 (cluster lab, valores de minimo, bus en NATS, trazas apagadas)

  apps          inventory:g13 (claves en sales y loans, outbox, el DISPATCH con clave) con el sidecar nativo
                outbox-relay (la misma imagen, /app/outbox-relay); replenish:g13 (processed_events, claves,
                cancelación idempotente); los demás en :g10, storefront :g5
  data          postgres-0, nats-0 (LAB_EVENTS, ventana de duplicados de 120 s)
  chart 0.26.0  el initContainer outbox-relay con restartPolicy: Always, con el bus en NATS
  contratos     IdempotencyKey en inventory.yaml (sales, loans); Idempotency-Key, idempotencyKey y la
                cancelación idempotente en replenish.yaml; inventory.g13.hurl
```

> **La señal de que quedó bien:** *"Sé qué es único en cada operación y quién elige la clave; escribo el aviso con el
> dato; y si me piden lo mismo dos veces —una venta, un evento o una compensación— lo hago una."*

> 🏷️ **No cierres la fase sin el tag.** Con el checklist en verde, las suites pasando y `git status` limpio:
>
> ```bash
> git tag -a fase-26-idempotencia-y-outbox -m "F26 cerrada: G13, Idempotency-Key en ventas, préstamos y órdenes; consumidor idempotente por eventId; outbox en la transacción de la venta con su publicador en Go como sidecar nativo y Nats-Msg-Id; la saga reintenta con clave y busca por clave al compensar; la cancelación idempotente"
> ```
>
> Commits con prefijo `f26:`.

---

## 📌 Pendientes sugeridos

- **F27:** el veredicto de la Parte IV en una rama del árbol: qué de todo esto necesita La Vecina sola, y qué la segunda
  cadena.
- **`a15`:** el stream en tres miembros, y si la deduplicación sobrevive a la caída del líder.
- **`a16`:** el aviso de traslados con outbox (ejercicio 23), como "lo que se le haría" al patrimonio.
- **Las doce parejas de órdenes repetidas** que quedaron en la base del laboratorio (ejercicio 15): el laboratorio no las
  limpia, a propósito.
