# 08 — Eventos, jobs y dos instancias

Este taller es **opcional**, como todo el bloque `06-talleres/`, y depende de
[`07` — Transacciones y concurrencia](07-transacciones-y-concurrencia.md), que depende de
[`06` — Modularizar](06-modularizar.md). Desarma los dos últimos pecados de runtime del legado: la
notificación escrita en la misma transacción que la cancelación, y el estado que vive en la memoria de
cada instancia —la caché de pedidos, el cierre diario programado y, descubierto al correrlo, la lista
de tokens revocados—. Termina con dos instancias del legado detrás de la misma base, `hurl/v1` en
verde contra las dos, un solo cierre diario por periodo y ninguna notificación perdida, duplicada o
fantasma.

> Ejercita [`02/05` — Comunicación interna: llamadas, comandos y eventos](../02-modularidad-y-limites-internos/05-comunicacion-interna-llamadas-comandos-y-eventos.md),
> [`03/03` — Eventos internos, jobs y procesamiento asíncrono](../03-datos-ejecucion-y-operacion/03-eventos-internos-jobs-y-procesamiento-asincrono.md)
> y [`03/04` — Rendimiento, caché y escalado](../03-datos-ejecucion-y-operacion/04-rendimiento-cache-y-escalado.md).
> Las reglas del bloque están en §11 y §12 de la [guía de estilo](../prompts/guia-de-estilo-y-convenciones.md).
>
> **Vigencia:** 2026-09-29. Salidas corridas ese día en macOS con Docker Desktop, JDK 25.0.4 y `hurl`
> 8.0.1. Las dos instancias son dos procesos locales, no dos máquinas (§11.4 de la guía).

**Salto rápido:** [1](#1--qué-enseña-este-taller) · [2](#2--prerrequisitos-y-versiones) · [3](#3-️-mapa-de-carpetas) · [4](#4--recorrido-de-la-base-de-código) · [5](#5--provocación-sin-notificaciones-no-se-cancela) · [6](#6--provocación-la-notificación-fantasma) · [7](#7--provocación-la-notificación-perdida) · [8](#8--outbox-local) · [9](#9--provocación-dos-instancias) · [10](#10--lo-que-no-puede-vivir-en-memoria) · [11](#11--evidencia) · [12](#12--errores-reales-al-correrlo) · [13](#13--plataformas) · [14](#14--teardown) · [Preguntas](#-preguntas) · [Ejercicios](#-ejercicios)

---

## 1. 🎯 Qué enseña este taller

Dos preguntas que parecen distintas y tienen la misma respuesta.

```text
¿Cuándo existe un efecto?                 ¿Dónde vive un estado?
cancelar ──► notificar                     instancia A: caché, job, tokens revocados
   │            │                          instancia B: caché, job, tokens revocados
   └── ¿misma transacción? ¿antes o         └── ¿quién tiene razón cuando no coinciden?
       después del COMMIT?
                    ▼                                         ▼
       outbox: el hecho se guarda con        la base: una fila, un lease, un registro
       la cancelación y se entrega después   que todas las instancias ven
```

Tres ideas:

- **Un efecto secundario tiene tres momentos posibles, y dos están mal.** Dentro de la transacción
  acopla la cancelación a las notificaciones; antes del `COMMIT` produce notificaciones de
  cancelaciones que no ocurrieron; después del `COMMIT`, sin nada más, se pierde si falla. Guardar el
  hecho en la misma transacción y entregarlo después (*outbox*) es el que queda.
- **Escalar horizontalmente multiplica el estado en memoria.** Una caché, un `@Scheduled` y un `Set`
  de tokens funcionan con una instancia; con dos, cada uno es una versión distinta de la verdad.
- **Se arregla sin distribuir.** Dos procesos del mismo monolito sobre la misma base comparten una
  sola fuente de verdad: la base. No hace falta un *broker*, un Redis ni un coordinador.

El precio: tres tablas nuevas (`outbox_events`, `job_leases`, `revoked_tokens`), una consulta más por
petición autenticada y notificaciones que llegan medio segundo tarde. Lo que compra es poder poner
una segunda instancia sin que cambie el comportamiento.

## 2. 🧰 Prerrequisitos y versiones

Lo de los talleres anteriores; nada nuevo que instalar. Órdenes nuevas de `lab.py`:

| Orden | Qué hace |
|---|---|
| `lab.py fault notifications [--off]` | añade a `notifications` una restricción `CHECK (false) NOT VALID`: toda fila nueva falla |
| `lab.py fault orders [--off]` | crea un *constraint trigger* diferido que rechaza el `COMMIT` de una cancelación |
| `lab.py cancel-probe [--port] [--wait]` | crea un pedido, lo cancela y, tras `--wait` segundos, cuenta en la base su estado y sus notificaciones |
| `lab.py legacy --port 38083` | la segunda instancia del legado |
| `lab.py api ... --port 38083 --token T` | la petición a otra instancia, con un token dado |
| `lab.py token` | imprime un token de `ana` para reusarlo |

`lab.py seed` quita también los fallos inyectados.

## 3. 🗂️ Mapa de carpetas

```text
06-talleres/laboratorio/
├── contrato/seed/seed.sql        vacía también outbox_events, revoked_tokens y job_leases
├── legacy/src/main/java/dev/mono/legacy/
│   ├── orders/OrderCancelled.java               nuevo: el hecho que publica orders
│   ├── orders/internal/OutboxEvent.java         nuevo: tabla outbox_events
│   ├── orders/internal/OutboxDispatcher.java    nuevo: entrega cada 500 ms, SKIP LOCKED
│   ├── orders/internal/OrderCache.java          borrado
│   ├── notifications/internal/OrderCancelledListener.java   nuevo: escucha OrderCancelled
│   ├── reports/internal/JobLeases.java          nuevo: el lease del cierre diario
│   └── auth/internal/RevokedToken*.java         nuevo: revocaciones en la base
├── scripts/lab.py                fault, cancel-probe, token, api --port/--token
└── estados/08/
```

## 4. 🔎 Recorrido de la base de código

Las rutas citan `laboratorio/estados/08/legacy/src/main/java/dev/mono/legacy/`.

| Pregunta | Dónde está la respuesta |
|---|---|
| ¿En qué transacción se guarda el hecho «pedido cancelado»? | en la de la cancelación: `orders/OrderService.java:148`–`154` escribe la fila de `outbox_events` |
| ¿Quién lo entrega y cuándo? | `orders/internal/OutboxDispatcher.java:33`, cada 500 ms; bloquea un evento (`:46`), lo publica (`:52`) y lo marca (`:53`) en una transacción |
| ¿Por qué dos despachadores no entregan el mismo evento? | `orders/internal/OutboxRepository.java:15`: `FOR UPDATE SKIP LOCKED` |
| ¿Qué evita una notificación duplicada si un evento llega dos veces? | `notifications/Notifications.java:21`: el `eventId` es el id de la notificación |
| ¿Quién depende de quién ahora? | `notifications/package-info.java:3` permite `orders`; `orders/package-info.java:4` ya no nombra `notifications` |
| ¿Qué impide que el cierre diario corra en las dos instancias? | `reports/internal/DailyCloseJob.java:39`, con el `INSERT ... ON CONFLICT ... WHERE` de `reports/internal/JobLeases.java:21`–`22` |
| ¿Dónde se comprueba si un token está revocado? | `auth/internal/RevokedTokens.java:22`, contra la tabla `revoked_tokens` |

## 5. 🧨 Provocación: sin notificaciones no se cancela

Con el legado del estado 07, las notificaciones caídas y una cancelación:

```bash
python3 laboratorio/scripts/lab.py legacy --daily-close-ms 600000    # en otra terminal (estado 07)
python3 laboratorio/scripts/lab.py seed
python3 laboratorio/scripts/lab.py fault notifications
python3 laboratorio/scripts/lab.py cancel-probe
python3 laboratorio/scripts/lab.py fault notifications --off
```

- `fault notifications` añade `CHECK (false) NOT VALID` a la tabla: `NOT VALID` no revisa las filas que
  ya hay, pero toda fila nueva falla. Simula un módulo de notificaciones caído sin tocar el código.
- `cancel-probe` crea un pedido, lo cancela y a los 2 s mira la base.
- `--off` quita la restricción; es el *teardown* de la provocación.

```text
cancelar 690acad4: HTTP 500 INTERNAL_ERROR
en la base, 2.0 s después: pedido CONFIRMED, notificaciones 0
```

La cancelación y la notificación comparten transacción: si la notificación no se puede escribir, el
cliente no puede cancelar. Es atómico —nunca hay una sin la otra— y es el acoplamiento de runtime de
[`02/05`](../02-modularidad-y-limites-internos/05-comunicacion-interna-llamadas-comandos-y-eventos.md):
una capacidad secundaria tumba a la principal.

## 6. 🧨 Provocación: la notificación fantasma

La corrección que se escribe primero: que `orders` publique un evento y `notifications` lo escuche en
otro hilo, «para que la notificación no tumbe la cancelación».

```java
@Async
@EventListener
@Transactional
public void on(OrderCancelled event) {
    notifications.orderCancelled(event.orderId(), event.recipient());
}
```

- `OrderCancelled` es un `record` de la API de `orders`; `orders` ya no importa `notifications` y la
  dependencia se invierte: `notifications` → `orders`.
- `@EventListener` recibe el evento en cuanto se publica; `@Async` lo ejecuta en otro hilo, con su
  propia transacción.

Con las notificaciones caídas, la cancelación ya funciona:

```text
cancelar cec9c512: HTTP 200 CANCELLED
en la base, 2.0 s después: pedido CANCELLED, notificaciones 0
```

y la notificación se pierde en silencio: el error queda en el log del hilo `task-1`. Peor es lo que
pasa cuando lo que falla es la cancelación **al confirmar**:

```bash
python3 laboratorio/scripts/lab.py fault orders
python3 laboratorio/scripts/lab.py cancel-probe
python3 laboratorio/scripts/lab.py fault orders --off
```

- `fault orders` crea una función que lanza una excepción y un `CONSTRAINT TRIGGER ... DEFERRABLE
  INITIALLY DEFERRED` que la llama cuando un pedido pasa a `CANCELLED`. Un *trigger* diferido se
  ejecuta en el `COMMIT`: todo lo anterior —incluido publicar el evento— ya ocurrió. Simula un fallo al
  confirmar (un conflicto de serialización, una conexión cortada).

```text
cancelar 906d5108: HTTP 500 INTERNAL_ERROR
en la base, 2.0 s después: pedido CONFIRMED, notificaciones 1
```

El pedido **no** está cancelado y el cliente tiene una notificación que dice que sí. El oyente
asíncrono corrió en cuanto se publicó el evento, antes de saber si la cancelación iba a confirmar.

## 7. 🧨 Provocación: la notificación perdida

Segundo intento: entregar el evento **después** del `COMMIT`.

```java
@TransactionalEventListener
@Transactional(propagation = Propagation.REQUIRES_NEW)
public void on(OrderCancelled event) { ... }
```

- `@TransactionalEventListener` retiene el evento hasta la fase indicada de la transacción que lo
  publicó; por defecto, `AFTER_COMMIT`. Si la transacción se deshace, no se entrega.
- `REQUIRES_NEW` hace falta porque la transacción de la cancelación ya terminó: la escritura necesita
  la suya.

El fantasma desaparece:

```text
cancelar 2869345b: HTTP 500 INTERNAL_ERROR
en la base, 2.0 s después: pedido CONFIRMED, notificaciones 0
```

Pero con las notificaciones caídas:

```text
cancelar c544f128: HTTP 200 CANCELLED
en la base, 2.0 s después: pedido CANCELLED, notificaciones 0
```

```text
ERROR ... o.s.t.s.TransactionSynchronizationUtils  : TransactionSynchronization.afterCompletion threw exception
```

Spring registra la excepción del oyente y la descarta: la cancelación ya confirmó y el cliente recibió
`200`. La notificación no existe y nada la va a reintentar. Entre el `COMMIT` y el oyente no hay nada
durable: si falla la escritura, o si el proceso muere en ese instante, el hecho se pierde.

## 8. 🔁 Outbox local

La salida es no tener nada «entre» el `COMMIT` y la entrega: el hecho se guarda **en la misma
transacción** que la cancelación, en una tabla de `orders`, y otro proceso lo entrega después.

```java
// taller 08: el hecho se guarda en la outbox, en esta misma transacción; lo entrega el despachador
var event = new OrderCancelled(UUID.randomUUID(), o.getId(), customers.emailOf(o.getCustomerId()), Instant.now());
OutboxEvent row = new OutboxEvent();
row.setId(event.eventId());
row.setType("OrderCancelled");
row.setPayload(json.writeValueAsString(event));
row.setOccurredAt(event.occurredAt());
outbox.save(row);
```

- Si la cancelación se deshace, la fila tampoco existe: no hay fantasma posible.
- El `eventId` es el `id` de la fila y, al entregarlo, el de la notificación.

El despachador, cada 500 ms, en una transacción por evento:

```sql
SELECT * FROM outbox_events WHERE published_at IS NULL
ORDER BY occurred_at LIMIT 1 FOR UPDATE SKIP LOCKED
```

- `FOR UPDATE` bloquea la fila elegida; `SKIP LOCKED` hace que otra transacción que busque lo mismo
  salte las filas bloqueadas en lugar de esperar. Dos despachadores toman eventos distintos.
- Tras bloquearla, publica el evento a los oyentes **dentro de la misma transacción** (un
  `@EventListener` normal en `notifications`) y marca `published_at`. Notificación y marca se confirman
  juntas.
- Si el oyente falla, todo se deshace: la fila sigue pendiente, se anota el intento en `attempts` y
  `last_error`, y se reintenta en la siguiente pasada.
- Aquí la notificación y la marca de entregado se confirman juntas, así que un evento no se entrega
  dos veces. Si el oyente escribiera en otro sistema (un correo, un *broker*), sí podría: por eso
  `Notifications.orderCancelled` ignora un `eventId` que ya existe, y el consumidor es idempotente.

Las dos provocaciones otra vez. El fallo al confirmar:

```text
cancelar 06754395: HTTP 500 INTERNAL_ERROR
en la base, 2.0 s después: pedido CONFIRMED, notificaciones 0
```

Las notificaciones caídas, y la *outbox* a los 3 s:

```text
cancelar ba0669fb: HTTP 200 CANCELLED
en la base, 3.0 s después: pedido CANCELLED, notificaciones 0
      type      | attempts | delivered |                          last_error                          
----------------+----------+-----------+--------------------------------------------------------------
 OrderCancelled |        6 | f         | could not execute statement [ERROR: new row for relation "no
(1 row)
```

Seis intentos en tres segundos, pendiente. Tras `fault notifications --off`, por pedido (columnas:
pedido, estado, eventos en la *outbox*, intentos del último y notificaciones):

```text
----------+-----------+---------+----------+----------------
 06754395 | CONFIRMED |       0 |          |              0
 ba0669fb | CANCELLED |       1 |        6 |              1
(2 rows)
```

El pedido cuya cancelación falló no tiene evento ni notificación; el que se canceló con las
notificaciones caídas tiene su notificación, entregada en cuanto volvieron. Es entrega *al menos una
vez* con deduplicación: el comportamiento que `hurl/v1/07-notifications.hurl` ya esperaba con su
`retry`.

Spring Modulith trae esto hecho —el *Event Publication Registry*, con `@ApplicationModuleListener`—.
Aquí se escribió a mano para ver cada pieza; en un proyecto real, usar el registro de Modulith es
razonable.

## 9. 🧨 Provocación: dos instancias

Ahora el legado en dos procesos, los dos con el cierre diario cada 3 s:

```bash
python3 laboratorio/scripts/lab.py legacy --daily-close-ms 3000                  # terminal 1
python3 laboratorio/scripts/lab.py legacy --port 38083 --daily-close-ms 3000     # terminal 2
python3 laboratorio/scripts/lab.py seed
python3 laboratorio/scripts/lab.py sql "SELECT id, host, to_char(started_at, 'HH24:MI:SS.MS') AS started, orders_read FROM batch_runs ORDER BY id"
```

- `--port 38083` arranca la segunda instancia en otro puerto, contra la misma base. Para distinguir las
  filas, `DailyCloseJob` escribe ahora `host:puerto` (antes solo el nombre de la máquina, el mismo para
  las dos; sección 12).

```text
  1 | MacBookPro.lan:38081 | 22:06:06.229 |           0
  2 | MacBookPro.lan:38083 | 22:06:07.155 |           0
  3 | MacBookPro.lan:38081 | 22:06:09.231 |           0
  4 | MacBookPro.lan:38083 | 22:06:10.163 |           0
  5 | MacBookPro.lan:38081 | 22:06:12.241 |           0
```

Dos «cierres diarios» por periodo. Aquí solo duplica una fila de registro; con un job que cobra, envía
correos o genera un fichero para el banco, duplica el efecto.

**La caché.** Con `:38083` sin cierre diario (`--daily-close-ms 600000`), un pedido creado y pedido a
las dos después de que `:38081` llenara su caché:

```text
pedido 3b7b169d-1816-4e76-9401-809b3b736e8d
GET en :38081
HTTP 500 · application/problem+json · 9 ms
  "status": 500,
GET en :38083
HTTP 200 · application/json · 135 ms
  "status": "CONFIRMED",
```

La misma petición, dos respuestas: la `LazyInitializationException` del taller 02 solo existe en la
instancia que tiene caché. Detrás de un balanceador, sería un `500` a ratos. Arreglar solo el síntoma
—que la caché cargue las líneas— destapa el defecto de fondo. El pedido cancelado en `:38083`:

```text
cancelar en :38083
HTTP 200 · application/json · 193 ms
  "status": "CANCELLED",
GET en :38081
HTTP 200 · application/json · 6 ms
  "status": "CONFIRMED",
GET en :38083
HTTP 200 · application/json · 9 ms
  "status": "CANCELLED",
```

`:38081` responde rápido y mal: su caché dice `CONFIRMED` hasta el próximo cierre diario.

**Los tokens revocados**, descubierto al correr este taller. Un logout en una instancia y el mismo
token en las dos:

```bash
python3 laboratorio/scripts/lab.py token
python3 laboratorio/scripts/lab.py api POST /api/v1/auth/logout --token <token>
python3 laboratorio/scripts/lab.py api GET /api/v1/products --token <token> --port 38083
```

- `token` imprime un token de `ana`; `--token` lo usa en lugar de hacer login; `--port` elige la
  instancia.

```text
logout en :38081
HTTP 204 · - · 15 ms
GET /products con el mismo token en :38081
HTTP 401 · application/problem+json;charset=ISO-8859-1 · 17 ms
  "code": "TOKEN_REVOKED",
GET /products con el mismo token en :38083
HTTP 200 · application/json · 33 ms
```

Un usuario que cerró sesión sigue dentro en la mitad de las peticiones. `RevokedTokens` era un `Set`
en memoria «porque es rápido»; no estaba en la lista de pecados del legado, y aparece exactamente
donde este taller mira.

## 10. 🧱 Lo que no puede vivir en memoria

Tres correcciones, las tres llevando el estado a la base que ya comparten:

| Estado | Antes | Después |
|---|---|---|
| Caché de pedidos | `OrderCache`, un `ConcurrentHashMap` por instancia, llenado por el cierre diario | borrada: un pedido se lee por clave primaria con sus líneas, en milisegundos |
| Cierre diario | `@Scheduled` en cada instancia | antes de trabajar, `JobLeases.tryAcquire`: solo corre quien tiene el *lease* |
| Tokens revocados | `Set<String>` en memoria | tabla `revoked_tokens` (`jti`, `expires_at`), consultada al validar el token |

El *lease* es una fila por job:

```sql
INSERT INTO job_leases (name, owner, lease_until)
VALUES (?, ?, now() + make_interval(secs => ? / 1000.0))
ON CONFLICT (name) DO UPDATE SET owner = EXCLUDED.owner, lease_until = EXCLUDED.lease_until
WHERE job_leases.lease_until < now() OR job_leases.owner = EXCLUDED.owner
```

- La primera vez, el `INSERT` crea la fila y la instancia gana.
- Después, `ON CONFLICT ... DO UPDATE ... WHERE` solo actualiza si el *lease* venció o ya era de esta
  instancia; si no, no toca nada y el `UPDATE` afecta cero filas: no se trabaja.
- El *lease* dura un periodo. Si la instancia que lo tiene muere, vence y la otra lo toma en su
  siguiente pasada.
- La tabla la crea `LeaseSchema` con `CREATE TABLE IF NOT EXISTS`, porque no es una entidad: otro
  trozo de esquema implícito para el taller 09.

Las mismas comprobaciones, con las dos instancias con el cierre cada 3 s:

```text
  1 | MacBookPro.lan:38081 | 22:08:36.519 |           0
  2 | MacBookPro.lan:38081 | 22:08:39.524 |           0
  3 | MacBookPro.lan:38081 | 22:08:42.519 |           0
  4 | MacBookPro.lan:38081 | 22:08:45.523 |           0
```

```text
pedido 70ea9212; cancelar en :38083
HTTP 200 · application/json · 186 ms
GET en :38081
HTTP 200 · application/json · 21 ms
  "status": "CANCELLED",
GET en :38083
HTTP 200 · application/json · 12 ms
  "status": "CANCELLED",
```

```text
logout en :38081
HTTP 204 · - · 22 ms
GET /products con el mismo token en :38081
HTTP 401 · application/problem+json;charset=UTF-8 · 19 ms
  "code": "TOKEN_REVOKED",
GET /products con el mismo token en :38083
HTTP 401 · application/problem+json;charset=UTF-8 · 19 ms
  "code": "TOKEN_REVOKED",
```

Y el relevo del *lease*: se para `:38081` a las 22:09:03 y el cierre sigue en `:38083` en cuanto vence
(consulta de las últimas cinco filas, la más reciente primero):

```text
 12 | MacBookPro.lan:38083 | 22:09:10.537
 11 | MacBookPro.lan:38083 | 22:09:07.546
 10 | MacBookPro.lan:38081 | 22:09:03.519
  9 | MacBookPro.lan:38081 | 22:09:00.517
  8 | MacBookPro.lan:38081 | 22:08:57.519
```

Por último, la *outbox* con dos despachadores: veinte cancelaciones repartidas entre las dos
instancias, diez en cada una, a la vez.

Columnas: pedidos cancelados, eventos entregados, notificaciones y pedidos distintos notificados.

```text
------------+------------+----------------+---------------------
         20 |         20 |             20 |                  20
(1 row)

entregas registradas por :38081: 19
entregas registradas por :38083: 1
```

Las dos instancias entregaron —19 y 1, según quién llegó antes a cada evento— y ningún evento se
entregó dos veces.

## 11. 🧪 Evidencia

```bash
python3 laboratorio/scripts/lab.py test
python3 laboratorio/scripts/lab.py suite --base-url http://localhost:38081
python3 laboratorio/scripts/lab.py suite --base-url http://localhost:38083
```

- `--base-url` corre `hurl/v1` contra una instancia concreta; las dos tienen el cierre diario cada 3 s.

```text
Tests run: 8, Failures: 0, Errors: 0, Skipped: 0
BUILD SUCCESS
```

```text
Success 07-notifications.hurl (10 request(s) in 2253 ms)
Success 08-reports.hurl (5 request(s) in 190 ms)
Success 09-idempotency.hurl (13 request(s) in 152 ms)
Executed requests: 99 (16.9/s)
Succeeded files:   9 (100.0%)
```

```text
Success 07-notifications.hurl (10 request(s) in 2270 ms)
Success 08-reports.hurl (5 request(s) in 192 ms)
Success 09-idempotency.hurl (13 request(s) in 139 ms)
Executed requests: 99 (16.7/s)
Succeeded files:   9 (100.0%)
```

`07-notifications.hurl` hace ahora 10 peticiones: una lectura se repite, porque la notificación llega
medio segundo tarde. Y la suite pasa con el cierre diario cada 3 s, cuando el taller 03 tuvo que
imponer 600000 ms como precondición: sin caché, el `500` a ratos ya no existe. `lab.py lazy`, la
provocación del taller 02, lo confirma:

```text
GET después del cierre diario:
HTTP 200 · application/json · 7 ms
```

`hurl/hex` (7 de 7), `hurl/ms` (6 de 6) y `lab.py contract` (0 violaciones) siguen en verde. El grafo de
módulos refleja la inversión:

```text
módulo notifications → [orders, shared]
módulo orders → [auth, idempotency, inventory, shared]
```

```bash
git diff --no-index --stat -M50% laboratorio/estados/07 laboratorio/estados/08
```

```text
 estados/{07 => 08}/contrato/seed/seed.sql          |  6 +-
 .../mono/legacy/auth/internal/RevokedToken.java    | 28 +++++++++
 ...
 .../orders/internal/OrderCache.java => /dev/null   | 21 -------
 .../legacy/orders/internal/OutboxDispatcher.java   | 67 ++++++++++++++++++++++
 .../mono/legacy/orders/internal/OutboxEvent.java   | 38 ++++++++++++
 ...
 .../mono/legacy/reports/internal/JobLeases.java    | 25 ++++++++
 .../mono/legacy/reports/internal/LeaseSchema.java  | 23 ++++++++
 21 files changed, 314 insertions(+), 65 deletions(-)
```

## 12. 🩺 Errores reales al correrlo

### La primera provocación de rollback no provocaba nada

**Síntoma.** El primer `fault orders` era una restricción `CHECK (status <> 'CANCELLED') NOT VALID`. Con
el oyente asíncrono, la cancelación falló y **no** apareció ninguna notificación fantasma.

**Causa.** La restricción se comprobaba en el `flush`, y el primer `flush` lo dispara
`InventoryService.release` (su `@Modifying(flushAutomatically = true)`) **antes** de publicar el evento.
La cancelación fallaba antes de publicar nada.

**Lección.** El momento del fallo decide qué efectos quedan. Se cambió a un *constraint trigger*
diferido, que falla en el `COMMIT`: el caso real (un conflicto de serialización, una conexión cortada)
ocurre después de todo el código de la transacción, no en medio.

### Dos instancias, el mismo `host`

**Síntoma.** Las filas de `batch_runs` no decían qué instancia las escribió: `host` era el nombre de la
máquina, igual para las dos.

**Causa.** El legado nunca había corrido en dos procesos en la misma máquina.

**Lección.** Antes de diagnosticar un problema de varias instancias hay que poder distinguirlas en los
datos y en los logs. `DailyCloseJob` escribe ahora `host:puerto`.

### `charset=ISO-8859-1` en los `401`

**Síntoma.** Comparando las respuestas de las dos instancias: `application/problem+json;charset=ISO-8859-1`
en el `401` que escribe el filtro de seguridad.

**Causa.** `setContentType` sin codificación y `getWriter()` usan el valor por defecto del contenedor
de servlets. Viene del taller 04 y no se había visto porque el cuerpo es ASCII.

**Lección.** Con un `detail` con tildes, el cliente habría leído basura. Se añadió
`setCharacterEncoding("UTF-8")`.

## 13. 🧰 Plataformas

Los talleres son solo Java (§6 de la guía). *Outbox*, *lease* en la base y estado compartido fuera de
la memoria del proceso son independientes de la plataforma; el contraste de mecanismos —*workers* y
colas en Node, `goroutine` con *leases* en Go, Celery en Python— está en
[`03/03`](../03-datos-ejecucion-y-operacion/03-eventos-internos-jobs-y-procesamiento-asincrono.md).

## 14. 🧹 Teardown

```bash
python3 laboratorio/scripts/lab.py fault notifications --off
python3 laboratorio/scripts/lab.py fault orders --off
python3 laboratorio/scripts/lab.py down
```

- Los dos `--off` quitan los fallos inyectados, si quedó alguno (`seed` también lo hace).
- `down` apaga PostgreSQL y Toxiproxy y borra sus volúmenes. Las dos instancias del legado y el
  `psp-simulator` se paran con Ctrl+C en sus terminales.

## ⚠️ Errores frecuentes

- «Publicar un evento desacopla». Desacopla el código; si el oyente corre antes del `COMMIT`, acopla
  los efectos a una transacción que puede deshacerse.
- «`AFTER_COMMIT` resuelve la consistencia». Evita el fantasma y pierde el evento si el oyente falla o
  el proceso muere; no hay nada durable entre el `COMMIT` y la entrega.
- «La *outbox* necesita un *broker*». La necesita quien entrega a otro sistema. Dentro de un monolito,
  el despachador puede entregar a oyentes locales en la misma base.
- «Una caché en memoria es inofensiva hasta que hay mucha carga». Es incorrecta en cuanto hay dos
  instancias, con cualquier carga.
- «`@Scheduled` con dos instancias se arregla con una sola instancia para jobs». Funciona hasta que esa
  instancia se cae; un *lease* en la base da exclusión y relevo.
- «El estado de seguridad es configuración». Una revocación es un dato; si vive en memoria, cada
  instancia tiene su propia lista de usuarios desconectados.

## 📚 Referencias

- [Spring Framework: Transaction-bound Events (`@TransactionalEventListener`)](https://docs.spring.io/spring-framework/reference/data-access/transaction/event.html)
- [Spring Modulith: Working with Application Events (Event Publication Registry)](https://docs.spring.io/spring-modulith/reference/events.html)
- [Pattern: Transactional outbox, Chris Richardson](https://microservices.io/patterns/data/transactional-outbox.html)
- [PostgreSQL 17: SELECT, cláusula de bloqueo (`SKIP LOCKED`)](https://www.postgresql.org/docs/17/sql-select.html#SQL-FOR-UPDATE-SHARE)
- [PostgreSQL 17: CREATE TRIGGER (`CONSTRAINT TRIGGER`, `DEFERRABLE`)](https://www.postgresql.org/docs/17/sql-createtrigger.html)
- [Spring Framework: Task Execution and Scheduling](https://docs.spring.io/spring-framework/reference/integration/scheduling.html)

## 🧠 Preguntas

1. ¿Qué garantizaba escribir la notificación en la misma transacción que la cancelación, y qué costaba? 🟢
2. ¿Por qué el oyente `@Async @EventListener` produjo una notificación de un pedido no cancelado? 🟢
3. ¿Qué hace `SKIP LOCKED` y qué pasaría con dos despachadores sin él? 🟢
4. ¿Por qué con dos instancias el mismo `GET` respondía `500` en una y `200` en la otra? 🟢
5. ¿Por qué `AFTER_COMMIT` evita el fantasma pero pierde la notificación? 🟡
6. ¿Por qué la *outbox* guarda el evento en la tabla de `orders` y no en la de `notifications`? 🟡
7. ¿Qué papel cumple el `eventId` como id de la notificación? 🟡
8. ¿Por qué hizo falta un *constraint trigger* diferido para provocar el fallo al confirmar? 🟡
9. Arreglar la `LazyInitializationException` de la caché destapó otro defecto. ¿Cuál, y por qué era peor? 🟡
10. ¿Qué pasa con el cierre diario si la instancia que tiene el *lease* se cuelga sin morir? 🟠
11. Consultar `revoked_tokens` en cada petición cuesta una consulta. ¿Cómo lo abaratarías sin volver al problema de dos instancias? 🟠
12. Un compañero propone Redis para la caché, los tokens y los *leases*. ¿Qué ganas, qué pagas y qué harías primero? 🟠
13. Si `notifications` pasara a ser otro proceso, ¿qué parte de la *outbox* cambiaría y cuál no? 🔴

## 🧪 Ejercicios

1. 🟢 **Orientación en código ajeno.** ¿En qué archivo y línea se decide que un evento de la *outbox*
   está entregado, y en qué transacción? Responde con rutas de `laboratorio/estados/08/`.
2. 🟢 Repite la provocación de la sección 6 con el oyente asíncrono y cuenta cuántas notificaciones
   fantasma hay tras cinco cancelaciones fallidas.
3. 🟡 Con las notificaciones caídas, cancela tres pedidos y mira `attempts` en `outbox_events` cada
   segundo. ¿Qué pasa con los eventos que vienen detrás del primero, y cómo lo evitarías?
4. 🟡 **Orientación en código ajeno.** Encuentra todas las tablas que el legado crea sin entidad ni
   migración. ¿Qué pasaría con cada una en una base nueva?
5. 🟡 Mata con `kill -9` la instancia que tiene el *lease* justo después de que empiece el cierre
   diario. ¿Cuánto tarda la otra en tomarlo y qué queda en `batch_runs`?
6. 🟠 Borra las filas de `revoked_tokens` vencidas con un job que use el mismo *lease*. ¿Qué pasa si
   el borrado corre en las dos instancias?
7. 🟠 Sustituye la *outbox* escrita a mano por el *Event Publication Registry* de Spring Modulith.
   Compara las tablas, los reintentos y lo que pierdes de control.
8. 🔥 Mide la latencia de `GET /api/v1/orders/{id}` con y sin la caché, con `lab.py` y cien lecturas.
   ¿Justificaba la caché su existencia? Di de dónde sale la cifra y qué no mide.

---

**Anterior:** [`07` — Transacciones y concurrencia](07-transacciones-y-concurrencia.md). **Siguiente:**
[`09` — Migraciones de esquema](09-migraciones-de-esquema.md).
