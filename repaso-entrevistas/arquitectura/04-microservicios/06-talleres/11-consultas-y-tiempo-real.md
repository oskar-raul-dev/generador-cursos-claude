# 11 — Consultas entre servicios y tiempo real

Este taller es **opcional dentro del bloque** y necesita [`06`](06-kafka-outbox-inbox-y-dlq.md) y
[`08`](08-saga-coreografiada.md); aquí se corre sobre el sistema de [`10`](10-contratos-y-testing.md). Una
pantalla que todo sistema tiene —"mis pedidos, con su estado de pago y lo que llevo pagado"— se construye
de las dos maneras de [`03/02`](../03-datos-y-consistencia/02-consultas-entre-servicios.md): **componiendo**
en el momento (`orders` más una llamada a `payments`) y leyendo un **read model** que un proyector alimenta
con eventos. Las dos responden lo mismo en el camino feliz; se separan cuando `payments` cae, cuando el
read model solo sabe lo que se publica y, en la provocación, cuando se reprocesa desde el offset 0 sin
idempotencia. Termina con el seguimiento de un pedido por **SSE**, un corte real del gateway y la
reanudación con `Last-Event-ID`.

> Ejercita [`03/02` — Consultas entre servicios](../03-datos-y-consistencia/02-consultas-entre-servicios.md) y
> [`02/05` — Tiempo real: WebSockets, SSE y los demás](../02-comunicacion/05-tiempo-real-websockets-y-sse.md).
>
> **Vigencia:** 2026-09-29. Sin versiones nuevas: las de `06/10`. Salidas corridas ese día en un Apple M1
> Pro con Docker Desktop.

**Salto rápido:** [1](#1--qué-enseña-este-taller) · [2](#2--prerrequisitos-y-versiones) · [3](#3-️-mapa-de-carpetas) · [4](#4--recorrido-de-la-base-de-código) · [5](#5--la-misma-vista-dos-fuentes) · [6](#6--cuando-payments-cae) · [7](#7--provocación-reprocesar-sin-idempotencia) · [8](#8--el-seguimiento-por-sse) · [9](#9--errores-reales-al-correrlo) · [10](#10--en-tres-plataformas) · [11](#11--teardown) · [Preguntas](#-preguntas) · [Ejercicios](#-ejercicios)

---

## 1. 🎯 Qué enseña este taller

```text
GET /api/v2/orders/overview?source=composition
    orders (su base) ──► payments GET /payments?orderId=…&orderId=…   (una llamada, timeout 800 ms)
                          └─ si no responde: pedidos sí, pagos UNKNOWN, degraded: true

GET /api/v2/orders/overview?source=projection
    order_overview + customer_overview ◄── OverviewProjector ◄── orders.events (grupo orders-overview)
                                             inbox (processed_messages) · se reconstruye desde el offset 0

GET /api/v2/orders/{id}/events   (text/event-stream)
    snapshot → step (id = order_saga_log.id) … → end        Last-Event-ID: reanuda · ": ping" cada 15 s
```

Cuatro ideas:

- **Componer es preguntar al dueño en el momento.** El dato está fresco y no hay estado nuevo, a cambio de
  la latencia de la llamada y de decidir qué se enseña cuando el otro no contesta.
- **Un read model es rápido y siempre responde, pero solo sabe lo que se publica.** Lo que el dueño no
  anuncia como hecho —aquí, un pago rechazado o incierto— no existe para la proyección.
- **Reconstruir un read model es parte del diseño, y la idempotencia decide si se puede.** Las filas que se
  escriben "fijando un estado" aguantan un reproceso; los totales que suman, no.
- **Una conexión abierta choca con todo lo que está pensado para peticiones.** El gateway la cortó a los
  10 s; la reanudación por `id` convirtió el corte en un hueco de un segundo.

El precio, en las cinco monedas: **latencia** (composición ≈ 13–35 ms en caliente, 800 ms si `payments` va
lento; proyección ≈ 2 ms siempre), **consistencia** (la proyección va por detrás y se equivoca por omisión),
**operación** (un proyector y su *lag* que vigilar, un procedimiento de reconstrucción, conexiones abiertas
en `orders`), **dinero** (ninguno nuevo) y **esfuerzo** (239 líneas de Java en `orders` y 8 de Python en
`payments` sobre el taller 10).

## 2. 🧰 Prerrequisitos y versiones

Las mismas de [`06/10` §2](10-contratos-y-testing.md#2--prerrequisitos-y-versiones). Se arranca como en
`06/09`, y las órdenes nuevas son:

```text
python3 laboratorio/scripts/lab.py overview [--items]
python3 laboratorio/scripts/lab.py follow ORDER_ID [--reconnects 5]
python3 laboratorio/scripts/lab.py overview-replay [--truncate]          # con orders PARADO
python3 laboratorio/scripts/lab.py orders --overview-no-inbox
```

- `overview` pide la vista de `ana@ms.local` por las dos fuentes y las imprime una debajo de otra, con el
  `Server-Timing` de cada una; `--items` añade los pedidos.
- `follow` es un cliente SSE como el `EventSource` del navegador: imprime cada evento con su tiempo y, si el
  flujo termina sin `end`, reconecta con `Last-Event-ID`.
- `overview-replay` reajusta el grupo `orders-overview` al principio de `orders.events`
  (`kafka-consumer-groups.sh --reset-offsets --to-earliest --execute`); solo funciona con el grupo vacío,
  es decir, con `orders` parado. `--truncate` vacía además la proyección y su inbox: la reconstrucción
  correcta.
- `orders --overview-no-inbox` arranca el proyector sin deduplicar: la provocación.

> **📝 Contexto:** el código tal como queda al terminar este taller está congelado en
> `laboratorio/estados/11/`, y las rutas con número de línea se refieren a esa copia. Si ya existen
> talleres posteriores, añade `--estado 11` a cada orden de `lab.py`.

## 3. 🗂️ Mapa de carpetas

```text
laboratorio/estados/11/                            (lab.py --estado 11)
├── contrato/
│   ├── openapi.yaml                               + /api/v2/orders/overview, /api/v2/orders/{orderId}/events (x-taller 11)
│   ├── hurl/v2/05-overview-and-follow.hurl        las dos fuentes y el SSE de una saga terminada
│   ├── envoy/envoy.yaml                           + ruta de /events sin timeout de respuesta
│   └── seed/orders/schema.sql                     + order_overview, customer_overview
├── orders/.../overview/OverviewProjector.java     el proyector del read model
├── orders/.../web/OverviewController.java         la vista, por composición o por proyección
├── orders/.../web/OrderEventStream.java           el seguimiento por SSE
└── payments/app/main.py                           GET /payments?orderId=… (por lote)
```

## 4. 🔎 Recorrido de la base de código

Rutas relativas a `laboratorio/estados/11/`.

**¿Cómo compone `orders`?** `orders/.../web/OverviewController.java`: el endpoint (línea 48) llama a
`compose` o a `project`. La composición pide a `payments` todos los pedidos en **una** llamada, con un
`orderId` por pedido en la consulta (línea 67); si falla, marca `degraded` (línea 72) y sigue. El timeout
es suyo (línea 44), y `Server-Timing` sale en la línea 55. En `payments/app/main.py`, línea 98, el filtro
`order_id = ANY(%s)` atiende el lote.

**¿Cómo se mantiene el read model?** `orders/.../overview/OverviewProjector.java`: un `@KafkaListener` con su
propio grupo (línea 36) y el inbox, salvo en la provocación (línea 43). `OrderPlaced` inserta si no existe
(líneas 48–50), `OrderPaid` fija `PAID` y **suma** al resumen del cliente (líneas 54–60), `OrderCancelled`
fija `CANCELLED` (línea 63).

**¿De dónde salen los hechos de las sagas orquestadas?** Del orquestador, que desde este taller publica
`OrderPlaced` al registrar el pedido `v2` (`service/OrderService.java`, línea 109) y `OrderCancelled` al
cancelar (`saga/Orchestrator.java`, línea 134). Sin ellos, la proyección no vería esos pedidos.

**¿Cómo es el SSE?** `orders/.../web/OrderEventStream.java`: el endpoint (línea 40) crea un `SseEmitter` sin
plazo propio (línea 44) y manda un `snapshot` sin `id` (línea 46). Un planificador cada 200 ms (línea 56) lee
del registro de la saga lo posterior al último `id` enviado (línea 63), manda un latido cada 15 s (línea 61)
y cierra con `end` (línea 71). En `contrato/envoy/envoy.yaml`, línea 81, la ruta propia de `/events`.

## 5. 🧱 La misma vista, dos fuentes

Tras la suite `v1` y tres altas `v2`, 2026-09-29:

```text
composition  9 pedidos · pagados 3 · 39.60 USD   (composition;dur=35.4)
    d100bfcd  PAYMENT_REJECTED  pago REJECTED   1499.00
    9502e827  CANCELLED         pago None       59.00
    f86a291c  PAID              pago AUTHORIZED 9.90
    1a9a315b  PAID              pago AUTHORIZED 9.90
    1548ab97  CANCELLED         pago None       49.90
    a2c7b24c  PAYMENT_PENDING   pago PENDING    666.00
    542bd41f  PAYMENT_REJECTED  pago REJECTED   1499.00
    14961bb3  PAID              pago AUTHORIZED 19.80
    ca115004  CONFIRMED         pago None       109.70
projection   9 pedidos · pagados 3 · 39.60 USD   (projection;dur=2.0)
    d100bfcd  PLACED            pago None       1499.00
    9502e827  CANCELLED         pago None       59.00
    f86a291c  PAID              pago AUTHORIZED 9.90
    1a9a315b  PAID              pago AUTHORIZED 9.90
    1548ab97  CANCELLED         pago None       49.90
    a2c7b24c  PLACED            pago None       666.00
    542bd41f  PLACED            pago None       1499.00
    14961bb3  PAID              pago AUTHORIZED 19.80
    ca115004  PLACED            pago None       109.70
```

- Coinciden en lo que se publica: pedidos, pagados, cancelados y el total pagado.
- Difieren en lo que no se publica. `orders` no emite un hecho para "pago rechazado" ni para "pago incierto"
  (`PAYMENT_REJECTED`, `PAYMENT_PENDING`), así que la proyección los deja en `PLACED`. La composición los
  ve porque pregunta a `payments`, que es el dueño del estado del pago.
- La proyección habla el idioma de los **hechos** (`PLACED`, `PAID`, `CANCELLED`), no el de la tabla de
  `orders` (`CONFIRMED`, `PENDING`). Es una decisión de diseño: un read model no debería depender del
  esquema interno de quien publica.
- 35 ms frente a 2 ms: la composición paga su llamada; la proyección, una consulta local.

> **Veredicto:** la pregunta no es cuál es más rápida, sino **quién es dueño de cada dato y si lo publica**.
> Para el estado del pago, el dueño es `payments`, y mientras no publique sus cambios, solo la composición
> dice la verdad.

## 6. 🧱 Cuando `payments` cae

```text
--- payments parado
composition  11 pedidos · pagados 0 · 0.00 USD   (composition;dur=34.9)  DEGRADED
projection   11 pedidos · pagados 3 · 39.60 USD   (projection;dur=2.4)
--- otra vez, con --items
composition  11 pedidos · pagados 0 · 0.00 USD   (composition;dur=12.7)  DEGRADED
    e7a83bbe  CANCELLED         pago UNKNOWN    9.90
    6a218f06  CANCELLED         pago UNKNOWN    9.90
    d100bfcd  PAYMENT_REJECTED  pago UNKNOWN    1499.00
…
--- payments con 1500 ms de latencia (lab.py slow payments)
composition  11 pedidos · pagados 0 · 0.00 USD   (composition;dur=816.9)  DEGRADED
projection   11 pedidos · pagados 3 · 39.60 USD   (projection;dur=1.6)
--- payments de vuelta
composition  11 pedidos · pagados 3 · 39.60 USD   (composition;dur=17.4)
projection   11 pedidos · pagados 3 · 39.60 USD   (projection;dur=1.6)
```

- Parado, la composición degrada deprisa (la conexión se rechaza); lento, espera su timeout de 800 ms y
  degrada igual. En los dos casos responde `200` con los pedidos y los pagos `UNKNOWN`: la decisión de
  `03/02` §2, "qué se enseña si uno falla", escrita en el código.
- `pagados 0 · 0.00` con `DEGRADED` es honesto pero engañoso si la pantalla no enseña el aviso. La
  interfaz tiene que distinguir "no has pagado nada" de "ahora no lo sé".
- La proyección no se entera: no llama a nadie.

## 7. 🧨 Provocación: reprocesar sin idempotencia

El read model se reconstruye leyendo `orders.events` desde el principio. Con `orders` parado:

```text
python3 laboratorio/scripts/lab.py overview-replay
python3 laboratorio/scripts/lab.py orders --overview-no-inbox
```

2026-09-29:

```text
GROUP           TOPIC           PARTITION  NEW-OFFSET
orders-overview orders.events   1          0
orders-overview orders.events   0          0
orders-overview orders.events   2          0
composition  11 pedidos · pagados 3 · 39.60 USD   (composition;dur=259.3)
projection   11 pedidos · pagados 6 · 79.20 USD   (projection;dur=3.4)
```

- 18 hechos reprocesados. Las filas por pedido siguen bien: `OrderPlaced` inserta solo si no existe y los
  demás **fijan** un estado. El resumen, que **suma**, contó cada `OrderPaid` dos veces: 6 pedidos pagados
  y 79,20 USD donde hay 3 y 39,60.
- El `259.3` de la composición es la primera petición tras arrancar `orders` (cliente HTTP y JIT en frío),
  no un efecto del reproceso.

La reconstrucción correcta vacía la proyección **y** su inbox, y reprocesa con inbox:

```text
python3 laboratorio/scripts/lab.py overview-replay --truncate
python3 laboratorio/scripts/lab.py orders
```

```text
composition  11 pedidos · pagados 3 · 39.60 USD   (composition;dur=224.2)
projection   11 pedidos · pagados 3 · 39.60 USD   (projection;dur=2.8)
--- y un segundo reproceso, con inbox y SIN vaciar
projection   11 pedidos · pagados 3 · 39.60 USD   (projection;dur=3.7)
overview p2 o5 OrderPaid a0f426bf order=f86a291c → already applied, skipped
overview p2 o6 OrderPlaced dec47743 order=d100bfcd → already applied, skipped
```

- Con inbox y sin vaciar, el reproceso no hace nada: todo consta como aplicado. Es la otra cara de
  [`06/06` pregunta 11](06-kafka-outbox-inbox-y-dlq.md#-preguntas): el inbox protege de duplicados y, por
  eso mismo, hay que vaciarlo junto con la proyección para reconstruir.

> **Veredicto:** un read model sin procedimiento de reconstrucción probado no es un read model, es una
> caché que nadie sabe rellenar. La reconstrucción es proyección + inbox + reajuste de offsets, en ese
> orden y con el consumidor parado, y se prueba **antes** de necesitarla.

## 8. 🧱 El seguimiento por SSE

Una saga ya terminada: el flujo repite su historia y cierra.

```text
+   0.0 s  conexión 1
+   0.0 s  snapshot id=-     {"status":"PAID"}
+   0.1 s  step     id=1     {"step":"RESERVE_INVENTORY","orderStatus":"PAID","outcome":"saga started"}
+   0.1 s  step     id=2     {"step":"AUTHORIZE_PAYMENT","orderStatus":"PAID","outcome":"reserved"}
+   0.1 s  step     id=3     {"step":"COMMIT_INVENTORY","orderStatus":"PAID","outcome":"payment authorized psp-f1eb7dd9"}
+   0.1 s  step     id=4     {"step":"DONE","orderStatus":"PAID","outcome":"committed 1 lines"}
+   0.1 s  end      id=4     {"orderStatus":"PAID"}
```

- `snapshot` no lleva `id`: no mueve el punto de reanudación. Cada `step` lleva el `id` de su fila en
  `order_saga_log`, creciente y estable: es lo que hace posible reanudar.
- `end` existe porque un `EventSource` reconecta solo cuando el servidor cierra; sin un aviso explícito, el
  navegador volvería a pedir el flujo para siempre.

Una saga larga —`payments` parado, plazo de 20 s— a través de Envoy:

```text
+   0.4 s  step     id=13    {"step":"AUTHORIZE_PAYMENT", … "retry in 500 ms: payments unavailable: …"}
…
+   8.8 s  step     id=17    {"step":"AUTHORIZE_PAYMENT", … "retry in 5000 ms: payments unavailable: circuit breaker open"}
+  10.0 s  el flujo terminó sin 'end'
+  11.0 s  conexión 2 (Last-Event-ID: 17)
+  11.0 s  snapshot id=17    {"status":"CONFIRMED"}
+  14.8 s  step     id=18    {"step":"AUTHORIZE_PAYMENT", … "retry in 5000 ms: payments unavailable: circuit breaker open"}
+  20.0 s  step     id=19    {"step":"RELEASE_INVENTORY","orderStatus":"CANCELLED","outcome":"payments unavailable until deadline"}
+  20.2 s  step     id=20    {"step":"DONE","orderStatus":"CANCELLED","outcome":"released"}
+  20.2 s  end      id=20    {"orderStatus":"CANCELLED"}
17:37:24 GET /api/v2/orders/6a218f06-…/events → 200 10002ms upstream=192.168.65.254:28082 attempts=1 UT response_timeout
```

- Envoy cortó el flujo a los 10 s: el timeout de la ruta de `orders` está pensado para peticiones y se
  aplica a la respuesta entera (`UT response_timeout`).
- El cliente volvió con `Last-Event-ID: 17` y el servidor siguió en el 18: ni un evento perdido, ni uno
  repetido. La reanudación de SSE convirtió el corte en un hueco de un segundo. (En esa corrida, `follow`
  imprimía en el `snapshot` el último `id` recibido, no el suyo; ya imprime `-`.)

Con la corrección de §9 —ruta propia sin timeout de respuesta y latido—, otra saga larga (plazo de 40 s):

```text
+   0.0 s  conexión 1
+   0.0 s  snapshot id=-     {"status":"PENDING"}
…
+  15.0 s  step     id=28    {"step":"AUTHORIZE_PAYMENT", … "retry in 5000 ms: payments unavailable: circuit breaker open"}
+  16.6 s  (comentario: ping)
…
+  33.1 s  (comentario: ping)
+  41.9 s  step     id=33    {"step":"RELEASE_INVENTORY","orderStatus":"CANCELLED","outcome":"payments unavailable until deadline"}
+  42.1 s  step     id=34    {"step":"DONE","orderStatus":"CANCELLED","outcome":"released"}
+  42.1 s  end      id=-     {"orderStatus":"CANCELLED"}
```

- Una sola conexión de 42 s. El latido (`: ping`) es un comentario SSE: el cliente lo ignora, pero un proxy
  ve tráfico y no cierra por inactividad.

> **Veredicto:** SSE da la reanudación hecha si los eventos tienen un `id` estable, y el registro de la saga
> ya lo tenía. Lo que no da es un camino preparado para conexiones largas: cada proxy entre el cliente y el
> servicio necesita su excepción y su latido.

## 9. 🩺 Errores reales al correrlo

### Envoy cortaba el flujo a los 10 s

```text
17:37:24 GET /api/v2/orders/6a218f06-…/events → 200 10002ms upstream=192.168.65.254:28082 attempts=1 UT response_timeout
```

Visto en §8. **Corrección:** una ruta para `^/api/v2/orders/[^/]+/events$`, **antes** de la general de
`/api/v2/orders`, con `timeout: 0s` (sin timeout de respuesta) e `idle_timeout: 60s`; y en el servidor, un
comentario `: ping` cada 15 s. **Lección:** `02/05` §6 lo avisa —"una conexión abierta convierte a tu
servicio en algo con estado"—, y el primer sitio donde se nota es el gateway, configurado para peticiones
cortas.

### `ActorResolver` no era accesible fuera de `web`

```text
dev.ms.orders.web.ActorResolver is not public in dev.ms.orders.web; cannot be accessed from outside package
```

Los dos controladores nuevos empezaron en un paquete `overview`. **Corrección:** viven en `web`, junto a los
demás controladores; en `overview` queda el proyector. **Lección:** la visibilidad de paquete es una
frontera; saltarla haciendo `public` lo que no lo era la habría borrado sin decidirlo.

### El filtro de `jsonpath` de hurl devolvía un valor, no una lista

```text
jsonpath "$.items[?(@.orderId == '{{order_id}}')].paymentStatus" nth 0 == "AUTHORIZED"
   |                                                                  ^^^^^ invalid filter input type
   |                                                                           actual:   string
   |                                                                           expected: list
```

Con un solo elemento que cumple el filtro, hurl entrega el valor directamente. **Corrección:** comparar sin
`nth 0`. **Lección:** menor, pero típica: las herramientas de aserción tienen su propia semántica de
`jsonpath`, y conviene probar la aserción contra una respuesta real antes de darla por buena.

## 10. 🧰 En tres plataformas

| Plataforma | Qué te da hecho | Lo que te deja a ti |
|---|---|---|
| **Java** | `SseEmitter` en Spring MVC (o `Flux<ServerSentEvent>` en WebFlux); `@KafkaListener` para el proyector; `RestClient` con timeout para componer | Quién tiene la conexión y cómo se reparte con varias instancias; el latido; qué se degrada al componer |
| **Go** | `http.Flusher` en la biblioteca estándar: SSE en ≈ 20 líneas; `errgroup` para componer en paralelo con un contexto que corta | Todo el protocolo SSE a mano (formato, `id`, reintento); la reconstrucción del proyector |
| **Python** | `StreamingResponse` en FastAPI (o `sse-starlette`); `asyncio.gather` con `wait_for` para componer | Que cada conexión abierta ocupa una tarea y, detrás de un proxy, un descriptor; el mismo latido |

La fila de Node/TS está en [`02/05` §7](../02-comunicacion/05-tiempo-real-websockets-y-sse.md#7--en-las-cuatro-plataformas)
y en [`03/02` §6](../03-datos-y-consistencia/02-consultas-entre-servicios.md#6--en-las-cuatro-plataformas).

## 11. 🧹 Teardown

```text
Ctrl+C en las terminales de psp, inventory, payments, monolith y orders
python3 laboratorio/scripts/lab.py down
```

- `down` se lleva la proyección y el log con el resto. Es el último taller del bloque; el cierre está en el
  [`README`](README.md).

## ⚠️ Errores frecuentes

| Se dice | Lo preciso |
|---|---|
| "El read model es la misma información, más rápida" | Es lo que se publicó, con retraso; lo que el dueño no anuncia no está |
| "Si falla un servicio, la composición falla" | Falla si no se decide qué enseñar; con degradación explícita, responde con un aviso |
| "Reconstruir la proyección es reprocesar el topic" | Es vaciar proyección e inbox, reajustar offsets con el consumidor parado y reprocesar con deduplicación |
| "Las filas se pueden reprocesar, así que la proyección es idempotente" | Las que fijan estados sí; las que suman, no |
| "SSE necesita una librería" | Es HTTP con un formato de texto; lo que necesita es que cada proxy lo trate como una conexión larga |
| "Con reconexión automática no se pierde nada" | Solo si los eventos tienen un `id` estable y el servidor sabe seguir desde él |

## 📚 Para profundizar

- **Libro** — Chris Richardson, *Microservices Patterns*, Manning, 2018, cap. 7, "Implementing queries in a
  microservice architecture" (composición de API y CQRS).
- **Documentación** — [Spring MVC: respuestas asíncronas y `SseEmitter`](https://docs.spring.io/spring-framework/reference/web/webmvc/mvc-ann-async.html) ·
  [Envoy 1.39: timeouts](https://www.envoyproxy.io/docs/envoy/v1.39.1/faq/configuration/timeouts).
- **Fuente primaria** — [microservices.io: *API composition*](https://microservices.io/patterns/data/api-composition.html) ·
  [*CQRS*](https://microservices.io/patterns/data/cqrs.html).
- **Especificación** — [WHATWG HTML: Server-sent events](https://html.spec.whatwg.org/multipage/server-sent-events.html)
  (formato, `id`, `Last-Event-ID`, reconexión) ·
  [W3C Server Timing](https://www.w3.org/TR/server-timing/).

## 🧠 Preguntas

1. ¿Qué hace cada fuente de la vista, y cuánto tardó cada una en el taller? 🟢
2. ¿Por qué la composición pide todos los pedidos en una llamada y no uno a uno? 🟢
3. ¿Qué es un evento `snapshot` sin `id` y por qué se manda así? 🟢
4. ¿Para qué sirve el evento `end`? 🟢
5. ¿Por qué la proyección deja en `PLACED` los pedidos con pago rechazado? 🟢
6. ¿Qué devuelve la composición con `payments` caído, y por qué `200` y no `503`? 🟡
7. ¿Por qué el reproceso sin inbox duplicó el total pagado pero no los estados de los pedidos? 🟡
8. ¿Por qué Envoy cortaba el flujo SSE, y qué dos cambios lo resolvieron? 🟡
9. ¿Cuál es el procedimiento completo para reconstruir el read model, y por qué en ese orden? 🟠
10. El orquestador empezó a publicar `OrderPlaced` y `OrderCancelled` en este taller. ¿Por qué hacía falta, y qué dice eso de quién decide qué se publica? 🟠
11. ¿Qué pasa con las conexiones SSE cuando se despliega una versión nueva de `orders`, y cómo lo amortigua el diseño? 🟠
12. ¿Cuándo elegirías composición y cuándo read model para esta pantalla, con los números del taller? 🟠
13. Con tres instancias de `orders` detrás de Envoy, el cliente conecta el SSE a una y el orquestador avanza la saga en otra. ¿Funciona el diseño del taller? ¿Qué cambiarías si no? 🔴
14. Producto quiere que "mis pedidos" muestre también el estado del pago en tiempo real, sin la latencia de la composición. Diseña qué publica `payments`, qué consume el proyector y qué garantías das. 🔴

## 🧪 Ejercicios

1. 🟢 Corre `overview --items` tras la suite `v1` y marca, pedido a pedido, en qué difieren las dos fuentes y
   por qué.
2. 🟢 **Orientación en código ajeno.** Encuentra, con ruta y línea, dónde decide la composición cuánto espera
   a `payments` y dónde marca la respuesta como degradada.
3. 🟡 Haz que `payments` publique `PaymentVoided` cuando anula un pago (`06/06`), que el proyector lo aplique,
   y comprueba que la proyección refleja la cancelación de un pago pendiente.
4. 🟡 Añade a la vista un campo `asOf` con la marca del último hecho aplicado por el proyector, y enséñalo en
   la respuesta de la proyección. ¿Qué le dice al cliente?
5. 🟠 Implementa `GET /api/v2/orders/overview?source=projection&minVersion=N`: si el proyector aún no ha
   aplicado el hecho N, espera hasta 2 s o responde con la composición. ¿Qué problema resuelve?
6. 🟠 Sustituye el sondeo del registro por `LISTEN`/`NOTIFY` de PostgreSQL para empujar los eventos SSE sin
   esperar al planificador. Mide la diferencia.
7. 🔴 Levanta dos instancias de `orders` detrás de Envoy y reproduce la pregunta 13. Resuélvelo con un
   *backplane* (un topic con las transiciones) y justifica la elección frente a enrutar por pedido.
8. 🔥 Reescribe el endpoint SSE en Go con `http.Flusher`, como servicio aparte que solo lee el registro de la
   saga, y ponlo detrás de Envoy: la "capa de conexiones aparte" de `02/05` §6.

---

**Anterior:** [`10` — Contratos entre servicios y testing](10-contratos-y-testing.md). **Siguiente:**
[`12` — Respuestas](12-respuestas.md). **Relacionado:**
[`03/02` — Consultas entre servicios](../03-datos-y-consistencia/02-consultas-entre-servicios.md) ·
[`02/05` — Tiempo real](../02-comunicacion/05-tiempo-real-websockets-y-sse.md).
