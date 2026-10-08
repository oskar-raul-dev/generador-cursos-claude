# 09 — Saga orquestada, comparación y autopsia

Este taller es **opcional** y depende de [`08` — Saga coreografiada](08-saga-coreografiada.md): parte
de su sistema. Es la misma saga —reservar, cobrar, liberar si el cobro falla— con **dueño**: `orders`
guarda en una tabla en qué paso está cada pedido, desde cuándo y con qué plazo, y manda los comandos
`ReserveInventory`, `AuthorizePayment` y `ReleaseInventory`. La suite `v2` sigue en verde contra las dos
versiones. Después viene lo que las separa: el pago incierto de `666.00`, que aquí se resuelve solo; la
autopsia de [`03/03` §9](../03-datos-y-consistencia/03-saga.md#9--autopsia-la-saga-que-dejó-el-stock-bloqueado)
reproducida —una saga sin plazo, una reserva que caduca, un orquestador que muere a mitad—; y tres
cambios de negocio aplicados a las dos sagas, medidos con `git diff --stat`. **El número de servicios que
cambia es la evidencia.**

> Ejercita [`03/03` — Saga](../03-datos-y-consistencia/03-saga.md) completo.
>
> **Vigencia:** 2026-09-29. Sin versiones nuevas: las de `06/08`. Salidas corridas ese día en un Apple M1
> Pro con Docker Desktop.

**Salto rápido:** [1](#1--qué-enseña-este-taller) · [2](#2--prerrequisitos-y-versiones) · [3](#3-️-mapa-de-carpetas) · [4](#4--recorrido-de-la-base-de-código) · [5](#5--la-misma-saga-con-dueño) · [6](#6--el-pago-incierto-con-dueño) · [7](#7--autopsia-la-compensación-que-no-llega) · [8](#8--cierre-tres-cambios-de-negocio) · [9](#9--errores-reales-al-correrlo) · [10](#10--en-tres-plataformas) · [11](#11--teardown) · [Preguntas](#-preguntas) · [Ejercicios](#-ejercicios)

---

## 1. 🎯 Qué enseña este taller

```text
POST /api/v2/orders → tx { pedido PENDING + fila en order_sagas (RESERVE_INVENTORY, plazo 20 s) } → 202

orders, cada 200 ms: reclamar pasos vencidos (lease 30 s) → ejecutar FUERA de la transacción → anotar
  RESERVE_INVENTORY ──ok──► AUTHORIZE_PAYMENT ──AUTHORIZED──► COMMIT_INVENTORY ──► DONE        PAID
       │ sin stock               │ REJECTED ──────────────────► RELEASE_INVENTORY ──► DONE     PAYMENT_REJECTED
       ▼                         │ payments caído y plazo vencido ─► RELEASE_INVENTORY ► DONE   CANCELLED
     DONE  CANCELLED             │ PENDING: otra vez, con LA MISMA clave; plazo vencido ─► ESCALATED
                                 └─ el cobro es el pivote: después, solo se reintenta
inventory: una retención sin confirmar caduca (10 min) y vuelve al stock
```

Cuatro ideas:

- **Orquestar es tener estado y tiempo, no mensajería.** Los comandos viajan por las interfaces que ya
  existían (gRPC a `inventory`, HTTP con clave idempotente a `payments`). Lo nuevo es una tabla que dice en
  qué paso está cada saga, cuántas veces se intentó y cuándo vence, y un proceso que la recorre.
- **Un resultado incierto se reintenta, no se compensa a ciegas.** El cobro de `666.00` que en `08` dejaba
  cuatro respuestas distintas aquí se resuelve en 3 s: el orquestador vuelve a preguntar con la misma
  clave y el proveedor devuelve lo que pasó.
- **Todo estado intermedio necesita una salida por tiempo, y las salidas tienen que casar.** Sin plazo, la
  saga reintenta para siempre; con caducidad de la reserva pero sin plazo, el cliente paga un stock que ya
  no está. El plazo de la saga tiene que vencer antes que la reserva.
- **Cada estilo gana una prueba distinta.** Un paso en medio (antifraude) toca un servicio con orquestador
  y tres con coreografía; un consumidor al final (fidelidad) no toca a nadie en ninguna de las dos, porque
  el orquestador ya publica sus hechos al terminar.

El precio, en las cinco monedas: **latencia** (≈ 0,8–0,9 s hasta `PAID`, un sondeo de 200 ms por paso; la
coreografía de `08` tardaba ≈ 0,3–0,5 s), **consistencia** (la misma eventual, pero con un sitio que la
cuenta), **operación** (una tabla que vigilar —sagas `ESCALATED`, pasos con muchos intentos— y un
planificador que no puede pararse), **dinero** (ninguno nuevo) y **esfuerzo** (238 líneas de Java y 55 de Go
sobre el taller 08; `payments` no cambia).

## 2. 🧰 Prerrequisitos y versiones

Las mismas de [`06/08` §2](08-saga-coreografiada.md#2--prerrequisitos-y-versiones). Se arranca igual:

```text
python3 laboratorio/scripts/lab.py up
python3 laboratorio/scripts/lab.py seed --kafka                                   # con los consumidores PARADOS
python3 laboratorio/scripts/lab.py psp                                            # terminal 1
python3 laboratorio/scripts/lab.py inventory [--hold-ttl 10m]                     # terminal 2
python3 laboratorio/scripts/lab.py payments                                       # terminal 3
python3 laboratorio/scripts/lab.py monolith --inventory remote --payments remote  # terminal 4
python3 laboratorio/scripts/lab.py orders [--saga orchestration|choreography] [--saga-deadline 20]  # terminal 5
```

- `seed` crea en `ms_orders` las tablas `order_sagas` y `order_saga_log`.
- `orders --saga` elige quién lleva la saga `v2`: `orchestration` (por defecto desde este taller) o
  `choreography` (la de `06/08`, que sigue en el código). `--saga-deadline` fija el plazo de cada paso en
  segundos; `0` es "sin plazo", la provocación de §7.
- `inventory --hold-ttl` fija cuánto vive una retención sin confirmar antes de volver al stock: 10 minutos
  por defecto; `0` la desactiva.
- `saga-status` imprime ahora, si la saga es orquestada, la fila de `order_sagas` y el registro de
  transiciones.

> **📝 Contexto:** el código tal como queda al terminar este taller está congelado en
> `laboratorio/estados/09/`, y las rutas con número de línea se refieren a esa copia. Si ya existen
> talleres posteriores, añade `--estado 09` a cada orden de `lab.py`.

## 3. 🗂️ Mapa de carpetas

```text
laboratorio/estados/09/                            (lab.py --estado 09)
├── contrato/seed/orders/schema.sql                + order_sagas, order_saga_log
├── orders/.../saga/
│   ├── SagaStore.java                             la tabla: empezar, reclamar con lease, avanzar, reintentar
│   ├── Orchestrator.java                          los pasos, los plazos y las compensaciones
│   └── SagaListener.java                          la coreografía de 06/08, activa con --saga choreography
├── orders/.../service/OrderService.java           createV2: la fila de la saga en la transacción del pedido
├── inventory/internal/store/store.go              + ExpireHolds
├── inventory/cmd/inventory/main.go                + -hold-ttl y el barrido
└── tools/cierre-09/                               los tres cambios de §8, como parches
    ├── 1-antifraude-orquestacion.patch
    ├── 1-antifraude-coreografia.patch
    └── 2-fidelidad.patch
```

## 4. 🔎 Recorrido de la base de código

Rutas relativas a `laboratorio/estados/09/`.

**¿Dónde nace la saga?** `orders/.../service/OrderService.java`, línea 108: `sagas.start(...)` inserta la
fila de `order_sagas` en la misma transacción que el pedido. La tabla hace de outbox del orquestador: si
el pedido existe, su saga también. La línea 106 es un `saveAndFlush`, y la razón está en §9.

**¿Quién recorre la tabla?** `orders/.../saga/Orchestrator.java`, `tick` (línea 55), cada 200 ms. Reclama
pasos vencidos con `SagaStore.claim` (`SagaStore.java`, línea 36): un `UPDATE … WHERE order_id IN (SELECT …
FOR UPDATE SKIP LOCKED)` (línea 42) que los aplaza 30 s —el *lease*— antes de soltar la transacción. La
llamada remota va fuera; si el proceso muere a mitad, el *lease* vence y otro lo retoma.

**¿Dónde están las decisiones?** En el `switch` de `run`: `RESERVE_INVENTORY` (línea 72),
`AUTHORIZE_PAYMENT` (línea 84) con la clave `saga-<orderId>` (línea 86), `COMMIT_INVENTORY` (línea 107) y
`RELEASE_INVENTORY` (línea 116). Los plazos se consultan en `d.expired()`: un `PENDING` vencido se escala
(línea 97) y **no** se compensa; un `PaymentsUnavailable` vencido sí (línea 103), porque ahí es seguro que no
se cobró. Si al vender no queda nada retenido, también se escala (línea 110).

**¿Cómo se espera?** `SagaStore.retryLater` (línea 62): 250 ms × 2ⁿ, con tope de 5 s (línea 63).

**¿Y la segunda capa?** `inventory/internal/store/store.go`, `ExpireHolds` (línea 271): devuelve al stock las
retenciones `HELD` más viejas que el TTL. La lanza `expireHolds` en `cmd/inventory/main.go` (línea 122).

## 5. 🧱 La misma saga, con dueño

```text
python3 laboratorio/scripts/lab.py buy --v2 --sku SKU-002
python3 laboratorio/scripts/lab.py buy --v2 --sku SKU-004
python3 laboratorio/scripts/lab.py buy --v2 --sku SKU-005
```

2026-09-29, con el orquestador:

```text
order v2 202 PENDING  232 ms  trace=7c517bb01a3d40dd8f98d2469939ad56
  +    0 ms  PENDING   (874c3555-c4a9-424c-b8aa-49d3cd46a8ba)
  +  586 ms  CONFIRMED
  +  929 ms  PAID
order v2 202 PENDING  26 ms  trace=0da277d0220145968f8f301781f8bc78
  +    0 ms  PENDING   (6900d095-9ba9-4734-9e80-2243ae39bcbd)
  +  255 ms  CANCELLED
order v2 202 PENDING  26 ms  trace=63d22c4fe1354baa859ecb553acdeeb3
  +    0 ms  PENDING   (a394bae8-4269-4cf3-92f3-c81106779a4b)
  +  146 ms  CONFIRMED
  +  351 ms  PAYMENT_REJECTED
```

- El cliente ve exactamente lo mismo que en `08`: el contrato `v2` no sabe quién lleva la saga.
- La rama feliz tarda más que en la coreografía (929 ms frente a 277): cada paso espera a la siguiente
  vuelta del planificador. Con un sondeo más corto, o despertando al orquestador al terminar cada paso,
  baja; es un parámetro, no una propiedad del estilo.

La suite `v2`, contra las dos sagas con el mismo código, y la `v1`:

```text
--- orders --saga choreography · suite v2
Executed requests: 25 (7.5/s)
Succeeded files:   4 (100.0%)
--- orders (orchestration) · suite v2
Executed requests: 25 (8.7/s)
Succeeded files:   4 (100.0%)
--- orders (orchestration) · suite v1
Executed requests: 46 (14.5/s)
Succeeded files:   6 (100.0%)
```

Y el stock después de la suite `v2` sobre una semilla limpia, con las sagas en su tabla:

```text
SKU-001|20|-
SKU-002|97|COMMITTED 2, HELD 1
SKU-003|5|-
SKU-004|0|-
SKU-005|3|RELEASED 1
CANCELLED|DONE|1
PAID|DONE|1
PAYMENT_REJECTED|DONE|1
```

- `SKU-001` y `SKU-005` vuelven a su valor inicial tras la compensación; `SKU-002` refleja los dos
  vendidos y la retención del pedido `v1` que `04-v1-deprecated` crea y no paga. Las tres sagas, `DONE`.

> **Veredicto:** en el camino feliz, coreografía y orquestación son indistinguibles para el cliente. La
> diferencia está en lo que se puede preguntar al sistema y en quién decide cuando algo no llega.

## 6. 🧱 El pago incierto, con dueño

```text
python3 laboratorio/scripts/lab.py buy --v2 --sku SKU-003 --qty 3 --wait 20
python3 laboratorio/scripts/lab.py saga-status 508398bc-8041-402d-a933-35a8415571b0
```

2026-09-29:

```text
order v2 202 PENDING  106 ms  trace=41f060585eef4239a385901121b621b6
  +    0 ms  PENDING   (508398bc-8041-402d-a933-35a8415571b0)
  +   69 ms  CONFIRMED
  + 2957 ms  PAID
orders     PAID   (GET /api/v2/orders/508398bc…)
inventory  SKU-003×3 COMMITTED
payments   AUTHORIZED psp-f2bad417
psp        psp-f2bad417 666.00
saga       DONE · intento 0 · en el paso desde hace 0 s · plazo 20 s
16:47:15.246  RESERVE_INVENTORY saga started
16:47:15.269  AUTHORIZE_PAYMENT reserved
16:47:17.523  AUTHORIZE_PAYMENT retry in 500 ms: payment PENDING, will ask again with the same key
16:47:18.182  COMMIT_INVENTORY  payment authorized psp-f2bad417
16:47:18.413  DONE              committed 1 lines
```

- El primer `AuthorizePayment` volvió `PENDING` a los 2 s (el PSP tarda 3). El orquestador no compensó:
  el cobro pudo ocurrir. Volvió a preguntar con la misma clave, `payments` volvió a preguntar al PSP, y el
  PSP devolvió el cobro que **sí** había hecho. Cuatro partes de acuerdo en 3 s.
- Es el mismo importe que en [`08` §7](08-saga-coreografiada.md#7--provocación-en-qué-estado-está-este-pedido)
  dejó el pedido en `CONFIRMED` para siempre, con el dinero cobrado.
- El registro de transiciones es la respuesta a "¿en qué estado está y desde cuándo?", y la auditoría que
  en banca se pide por norma. Las horas de esa tabla salen en UTC; las de `buy`, en local.
- La línea `plazo 20 s` en un paso `DONE` era un defecto cosmético de esa corrida: ya no se pone plazo a un
  paso final.

> **Veredicto:** la prueba 3 del cierre —un fallo que exige decidir— la gana la orquestación sin
> discusión. Decidir necesita a alguien que recuerde qué se preguntó, cuándo, y cuánto se puede esperar.

## 7. 🧨 Autopsia: la compensación que no llega

La autopsia de [`03/03` §9](../03-datos-y-consistencia/03-saga.md#9--autopsia-la-saga-que-dejó-el-stock-bloqueado),
reproducida en tres corridas.

**1 · Sin plazo, con `payments` caído y reservas que caducan a 30 s.**

```text
python3 laboratorio/scripts/lab.py inventory --hold-ttl 30s
python3 laboratorio/scripts/lab.py orders --saga-deadline 0
```

```text
order v2 202 PENDING  290 ms  trace=51f39a7672c943cc8be393c2cba9c352
  +    0 ms  PENDING   (9b51ae8c-0eea-4f34-aba7-6ef74f00acee)
  +  665 ms  CONFIRMED
--- 45 s después
orders     CONFIRMED   (GET /api/v2/orders/9b51ae8c…)
inventory  SKU-002×2 RELEASED
saga       AUTHORIZE_PAYMENT · intento 11 · en el paso desde hace 45 s · plazo ninguno · payments unavailable: circuit breaker open
16:48:31.714  AUTHORIZE_PAYMENT retry in 500 ms: payments unavailable: I/O error on POST request for "http://localhost:28184/payments": HTTP/1.1 header parser received no bytes
16:48:32.619  AUTHORIZE_PAYMENT retry in 1000 ms: payments unavailable: circuit breaker open
…
16:49:13.008  AUTHORIZE_PAYMENT retry in 5000 ms: payments unavailable: circuit breaker open
2026/09/29 11:49:03 hold expired: order=9b51ae8c SKU-002×2 back to stock
--- payments vuelve
16:49:28.851  COMMIT_INVENTORY  payment authorized psp-c7ea1526
16:49:29.123  ESCALATED         nothing to commit: the reservation expired before payment
WARN … saga 9b51ae8c ESCALATED: nothing to commit: the reservation expired before payment (order PAID)
```

- Sin plazo, la saga no termina nunca por sí misma: once intentos en 45 s, y seguiría. Es la causa de la
  autopsia: "el diseño contemplaba el camino feliz y el fallo explícito, pero no el silencio".
- La caducidad de `inventory` devolvió el stock a los 33 s. Cuando `payments` volvió, el cobro salió
  (`psp-c7ea1526`) sobre un stock que ya no estaba retenido. El orquestador lo detecta (`Commit` vendió 0
  líneas) y **escala**: pedido `PAID`, saga `ESCALATED`. Es el peor resultado posible, y por eso tiene que
  llegar a una persona.

**2 · Con plazo de 20 s (el valor por defecto), mismo fallo.**

```text
order v2 202 PENDING  225 ms  trace=97f41c70bee94a499f4eb9f0ffbab494
  +    0 ms  PENDING   (c20df8ee-2b2e-439b-9558-da90dabc829c)
  +  531 ms  CONFIRMED
  +20507 ms  CANCELLED
inventory  SKU-002×2 RELEASED
16:51:18.730  AUTHORIZE_PAYMENT retry in 5000 ms: payments unavailable: circuit breaker open
16:51:23.932  RELEASE_INVENTORY payments unavailable until deadline
16:51:24.160  DONE              released
```

- Al vencer el plazo, el orquestador compensa. Es correcto **porque** el fallo era `PaymentsUnavailable`
  —no se llegó a cobrar—; con un `PENDING`, habría escalado en vez de liberar.
- La compensación llegó a los 20 s, antes de la caducidad de 30: la segunda capa no tuvo que actuar.

**3 · El orquestador muere en mitad de un cobro incierto.**

```text
python3 laboratorio/scripts/lab.py buy --v2 --sku SKU-003 --qty 3 --wait 1 ; kill -9 <orders>
```

La primera vez, con `inventory` todavía en `--hold-ttl 30s` de la corrida 1:

```text
--- 8 s después de matar orders
orders     503   (GET /api/v2/orders/c908d5b5…)
inventory  SKU-003×3 HELD
payments   PENDING -
psp        psp-1fc3447d 666.00
saga       AUTHORIZE_PAYMENT · intento 1 · en el paso desde hace 9 s · plazo 11 s
--- orders reiniciado
inventory  SKU-003×3 RELEASED
16:52:42.467  AUTHORIZE_PAYMENT reserved
16:53:13.976  COMMIT_INVENTORY  payment authorized psp-1fc3447d
16:53:14.641  ESCALATED         nothing to commit: the reservation expired before payment
```

La segunda, con la caducidad por defecto (10 min):

```text
orders     PAID   (GET /api/v2/orders/be817fd1…)
inventory  SKU-003×3 COMMITTED
payments   AUTHORIZED psp-b465df4d
psp        psp-b465df4d 666.00
16:54:38.992  RESERVE_INVENTORY saga started
16:54:39.161  AUTHORIZE_PAYMENT reserved
16:55:09.777  COMMIT_INVENTORY  payment authorized psp-b465df4d
16:55:10.433  DONE              committed 1 lines
```

- Con `orders` muerto, su API no responde; la saga, sí: está en una tabla. Al reiniciar, el *lease* de 30 s
  del intento interrumpido venció, otro intento volvió a preguntar con la misma clave y la saga cerró en
  `PAID`.
- En la primera corrida la saga se retomó a los 31 s y la reserva había caducado a los 30: otra vez
  `ESCALATED` con el pedido pagado.

> **Veredicto:** la corrección de la autopsia son dos capas —plazo por saga y caducidad por reserva—, y
> el taller añade la condición que las hace funcionar juntas: **el plazo del paso más el *lease* del
> orquestador tienen que ser menores que la caducidad de la reserva**. Si no, la segunda capa deshace lo
> que la primera todavía iba a hacer bien.

## 8. 🧱 Cierre: tres cambios de negocio

Tres cambios aplicados a las dos sagas en ramas de una copia del laboratorio. Los parches están en
`laboratorio/tools/cierre-09/` y se aplican sobre una copia con `patch -p1`. `fraud` y `loyalty` son
*stubs* en Python sin base propia; no forman parte del sistema del bloque.

```text
cd copia-del-laboratorio && patch -p1 < tools/cierre-09/1-antifraude-orquestacion.patch
python3 scripts/lab.py fraud --mode http | --mode kafka
python3 scripts/lab.py loyalty --saga orchestration | choreography
```

- `patch -p1` aplica el parche quitando el primer componente de las rutas (`a/`, `b/`).
- `fraud --mode http` atiende `POST /checks` en `:28086` (para el orquestador); `--mode kafka` consume
  `inventory.reservations` y publica en `fraud.results` (para la coreografía). La regla: una línea de más
  de 5 unidades es sospechosa.
- `loyalty` escucha `OrderPaid` en `orders.events` (orquestación) o `PaymentAuthorized` en
  `payments.results` (coreografía), e imprime un punto por cada 10,00.

**Prueba 1 · Un paso en medio: "antes de cobrar, control antifraude".**

```text
=== orquestación
 contrato/seed/orders/schema.sql                    |  2 +-
 fraud/.gitignore                                   |  1 +
 fraud/fraud.py                                     | 89 ++++++++++++++++++++++
 fraud/pyproject.toml                               | 12 +++
 .../dev/ms/orders/config/OrdersProperties.java     |  3 +-
 .../main/java/dev/ms/orders/saga/FraudClient.java  | 27 +++++++
 .../main/java/dev/ms/orders/saga/Orchestrator.java | 16 +++-
 orders/src/main/resources/application.yaml         |  2 +
 scripts/lab.py                                     | 10 +++
 9 files changed, 158 insertions(+), 4 deletions(-)
=== coreografía
 fraud/.gitignore                                   |  1 +
 fraud/fraud.py                                     | 89 ++++++++++++++++++++++
 fraud/pyproject.toml                               | 12 +++
 inventory/internal/consumer/consumer.go            |  2 +-
 inventory/internal/consumer/saga.go                |  3 +-
 .../main/java/dev/ms/orders/saga/SagaListener.java |  3 +-
 payments/app/consumer.py                           | 10 +--
 scripts/lab.py                                     | 13 +++-
 8 files changed, 124 insertions(+), 9 deletions(-)
```

- Orquestación: cambia **un** servicio, `orders` (un paso `CHECK_FRAUD` en la máquina y su cliente).
  Coreografía: cambian **tres**, `inventory` (libera también ante `FraudCheckFailed`), `payments` (cobra al
  ver `FraudCheckPassed` en vez de `InventoryReserved`) y `orders` (cancela ante `FraudCheckFailed`), y hay
  un topic nuevo.
- La coreografía tiene menos líneas. La cuenta que importa no son las líneas: son los equipos que tienen
  que coordinar un despliegue, y el orden del flujo, que en la coreografía no está escrito en ningún sitio.

Las dos, corridas con un pedido de 2 unidades y otro de 6, 2026-09-29:

```text
--- orquestación
  +  715 ms  PAID
  +  379 ms  CANCELLED
17:02:55.171  CHECK_FRAUD       reserved
17:02:55.393  RELEASE_INVENTORY fraud check failed: a line with 6 units (max 5)
17:02:55.614  DONE              released
--- coreografía
  +  488 ms  PAID
  +  315 ms  CANCELLED
inventory  SKU-002×6 RELEASED
InventoryReserved order=319f741d → FraudCheckPassed
InventoryReserved order=99b3e946 → FraudCheckFailed
```

**Prueba 2 · Un consumidor al final: "al pagar, suma puntos".**

```text
 loyalty/.gitignore     |  1 +
 loyalty/loyalty.py     | 40 ++++++++++++++++++++++++++++++++++++++++
 loyalty/pyproject.toml | 12 ++++++++++++
 scripts/lab.py         | 12 ++++++++++++
 4 files changed, 65 insertions(+)
```

- **Cero** servicios cambian, en las dos sagas. En la coreografía era de esperar: `loyalty` se suscribe a
  `PaymentAuthorized`. En la orquestación, porque el orquestador **ya publica** `OrderPaid` al terminar
  (desde `06/06`): `loyalty` se suscribe a ese hecho y `orders` no se entera. Es el sistema mixto que la
  teoría recomienda, y resultó ser el que ya había.

```text
--- orquestación: OrderPaid en orders.events
OrderPaid order=508398bc → +66 points
OrderPaid order=c908d5b5 → +66 points
…
OrderPaid order=41078ec5 → +14 points
--- coreografía: PaymentAuthorized en payments.results
PaymentAuthorized order=0221faf7 → +9 points
```

- El `+14` es el pedido nuevo (149,70). Las líneas anteriores son **toda la historia** del topic: un grupo
  nuevo empieza desde el principio (`auto_offset_reset="earliest"`) y dio puntos por pedidos de hace una
  hora. Ver §9.
- En la corrida coreografiada, el pedido pasó de `PENDING` a `PAID` sin pasar por `CONFIRMED`:
  `PaymentAuthorized` llegó a `orders` antes que `InventoryReserved`. La tabla de transiciones de
  [`08`](08-saga-coreografiada.md#4--recorrido-de-la-base-de-código) lo absorbió, que es para lo que estaba.

**Prueba 3 · Un fallo que exige decidir: el `666.00`.** Es §6 contra
[`08` §7](08-saga-coreografiada.md#7--provocación-en-qué-estado-está-este-pedido): la orquestación
reintenta con la misma clave y cierra en 3 s; la coreografía se queda con el dinero cobrado y el stock
retenido, sin nadie que tenga el temporizador.

| Prueba | Coreografía | Orquestación | Gana |
|---|---|---|---|
| 1 · Paso en medio | 3 servicios y un topic nuevo | 1 servicio | orquestación |
| 2 · Consumidor al final | 0 servicios | 0 servicios, porque el orquestador ya publica hechos | coreografía, o empate si el orquestador publica |
| 3 · Fallo que exige decidir | atascada; cuatro respuestas | resuelta en 3 s; una tabla lo cuenta | orquestación |

> **Veredicto:** "Orquesto la secuencia que el negocio considera una transacción, porque ahí necesito un
> dueño del estado y del tiempo, y coreografío las reacciones a sus resultados, porque ahí quiero sumar
> consumidores sin tocar a nadie. En la práctica casi siempre es mixto: el orquestador publica eventos de
> dominio al terminar."

## 9. 🩺 Errores reales al correrlo

### La fila de la saga no encontraba su pedido: JPA escribe al final, JDBC al momento

```text
ERROR: insert or update on table "order_sagas" violates foreign key constraint "order_sagas_order_id_fkey"
  Detail: Key (order_id)=(ace12f18-7ba5-400a-b181-bc1db083aff2) is not present in table "orders".
```

Las tres altas de la primera corrida respondieron `500`. `orders.save(...)` de JPA no inserta: deja el
pedido en el contexto de persistencia hasta el *flush*, que ocurre al confirmar. La fila de la saga va por
`JdbcClient`, que escribe en el acto, y su clave foránea buscó un pedido que aún no estaba en la base. En
`06/06` no pasaba porque `outbox_events` no tiene clave foránea. **Corrección:** `saveAndFlush`.
**Lección:** mezclar JPA y JDBC en una transacción es mezclar dos relojes de escritura; el orden de las
sentencias en el código no es el orden en la base.

### El *stub* antifraude leía cuerpos vacíos

```text
json.decoder.JSONDecodeError: Expecting value: line 1 column 1 (char 0)
```

El mismo tropiezo de [`06/01` §8](01-el-monolito-y-su-contrato.md#8--errores-reales-al-correrlo): el cliente
HTTP del JDK manda el cuerpo *chunked*, sin `Content-Length`, y el servidor de la biblioteca estándar de
Python no lo lee solo. La saga reintentó `CHECK_FRAUD` cinco veces antes de la corrección.
**Corrección:** leer *chunked* en el *stub*, como hace el simulador del PSP. **Lección:** cada servidor
nuevo escrito a mano vuelve a pagar la misma lección; por eso existen los *chassis*.

### Un consumidor nuevo reprocesó la historia, y el PSP volvió a cobrar

```text
InventoryReserved order=e27634b4 → FraudCheckPassed
InventoryReserved order=5b293201 → FraudCheckPassed
InventoryReserved 51167e5a order=5b293201 → AUTHORIZED PaymentAuthorized
5b293201 19.80 psp-053db19c
```

`fraud`, con un grupo nuevo y `auto_offset_reset="earliest"`, leyó `inventory.reservations` desde el
principio y publicó `FraudCheckPassed` para pedidos de corridas anteriores; `payments` los cobró. El PSP no
reconoció la clave porque la siembra lo había reiniciado. `loyalty` hizo lo mismo con los puntos.
**Corrección** (no aplicada en los *stubs*, que se quedan como evidencia): un consumidor nuevo que
**produce efectos** empieza por el final (`latest`) o con un reajuste de offsets decidido a mano.
**Lección:** "suscribir un consumidor sin tocar a nadie" tiene letra pequeña; en un topic con historia,
un consumidor nuevo es una migración, y las claves idempotentes de los proveedores caducan.

### La caducidad de la reserva y el *lease* del orquestador, sin coordinar

Está en §7, corrida 3: la saga se retomó a los 31 s y la reserva había caducado a los 30. **Corrección:**
ninguna en el código; es una regla de configuración —plazo del paso + *lease* < caducidad—, y el valor por
defecto la cumple (20 + 30 s frente a 10 min). **Lección:** dos mecanismos de seguridad con temporizadores
independientes pueden anularse; sus valores se diseñan juntos.

## 10. 🧰 En tres plataformas

| Plataforma | Qué te da hecho | Lo que te deja a ti |
|---|---|---|
| **Java** | `@Scheduled`, `TransactionTemplate`, `JdbcClient` y `SKIP LOCKED` en PostgreSQL: con eso se escribe un orquestador en ≈ 200 líneas; Spring State Machine, Axon o el SDK de Temporal si se quiere un motor | La tabla, el *lease*, los plazos, qué se compensa y qué se escala; no mezclar JPA y JDBC sin *flush* |
| **Go** | `pgx` con `SKIP LOCKED` y un `time.Ticker`; el SDK de Temporal para Go es de los más usados | Lo mismo, sin marco; aquí solo cambió `inventory` (la caducidad) |
| **Python** | `asyncio` y `psycopg` bastan para un orquestador pequeño; el SDK de Temporal para Python existe | En este taller, nada: `payments` no cambió. El orquestador no toca a los participantes, solo los llama |

La fila de Node/TS está en [`03/03` §8](../03-datos-y-consistencia/03-saga.md#8--en-las-cuatro-plataformas).

> **🧰 Plataforma:** Temporal, en una línea: la misma saga en Temporal es una función de flujo con tres actividades y
> sus compensaciones; la tabla, el *lease*, los reintentos y los plazos de este taller son lo que Temporal
> da hecho, a cambio de un clúster más que operar y un modelo de programación (el flujo tiene que ser
> determinista) que hay que aprender.

## 11. 🧹 Teardown

```text
Ctrl+C en las terminales de psp, inventory, payments, monolith y orders
python3 laboratorio/scripts/lab.py down
```

- `down` borra las tablas del orquestador con el resto de la base. Si aplicaste un parche del cierre, se
  aplicó sobre una copia: el laboratorio no cambia. El [taller 10](10-contratos-y-testing.md) empieza con `up` y `seed --kafka`.

## ⚠️ Errores frecuentes

| Se dice | Lo preciso |
|---|---|
| "La orquestación necesita un bus de comandos" | Necesita estado persistido y plazos; los comandos pueden ir por las interfaces que ya existen |
| "El orquestador centraliza el dominio" | Centraliza el orden y las compensaciones; las reglas de cada paso siguen en su servicio |
| "Si el pago no responde, se compensa" | Si es seguro que no se cobró; con un resultado incierto se vuelve a preguntar con la misma clave y, al final, se escala |
| "Con caducidad de reservas ya no hace falta plazo en la saga" | Sin plazo, la caducidad libera stock que el pago luego consume: el cliente paga lo que ya no está |
| "El orquestador es un punto único de fallo" | Si su estado está en una tabla, muere y se retoma; lo que no puede pararse es el planificador |
| "Añadir un consumidor no afecta a nadie" | Si empieza por el principio del topic, reprocesa la historia con todos sus efectos |

## 📚 Para profundizar

- **Libro** — Chris Richardson, *Microservices Patterns*, Manning, 2018, cap. 4, §4.2.2, "Orchestration-based
  sagas", y §4.3, "Handling the lack of isolation".
- **Libro** — Sam Newman, *Building Microservices*, 2.ª ed., O'Reilly, 2021, cap. 6, "Workflow" (sagas,
  orquestación y coreografía).
- **Documentación** — [Temporal: workflows](https://docs.temporal.io/workflows) ·
  [qué resuelve Temporal](https://docs.temporal.io/evaluate/understanding-temporal) ·
  [Kafka: `auto.offset.reset`](https://kafka.apache.org/documentation/#consumerconfigs_auto.offset.reset).
- **Fuente primaria** — [microservices.io: *Saga*](https://microservices.io/patterns/data/saga.html).

## 🧠 Preguntas

1. ¿Qué guarda `order_sagas` que en la coreografía no existía? 🟢
2. ¿Por qué el orquestador reclama los pasos con un *lease* en vez de mantener la fila bloqueada durante la llamada? 🟢
3. ¿Qué paso de la saga es el pivote, y qué cambia después de él? 🟢
4. ¿Por qué `v2` no notó el cambio de coreografía a orquestación? 🟢
5. ¿Por qué el orquestador compensa cuando `payments` no responde, pero escala cuando responde `PENDING`? 🟡
6. ¿Cómo resolvió el orquestador el pago de `666.00` que en la coreografía se quedaba atascado? 🟡
7. ¿Qué pasó cuando `orders` murió en mitad del cobro, y por qué la saga no se perdió? 🟡
8. ¿Por qué la fila de la saga violaba la clave foránea, si el pedido se guardaba antes en el código? 🟡
9. Sin plazo en la saga y con caducidad en la reserva, el cliente pagó un stock que ya no estaba retenido. Explica la secuencia y la regla que lo evita. 🟠
10. El antifraude tocó un servicio con orquestador y tres con coreografía. ¿Por qué, y por qué la coreografía tuvo menos líneas? 🟠
11. La fidelidad no tocó ningún servicio en ninguna de las dos sagas. ¿Qué dice eso de "orquestación contra coreografía"? 🟠
12. Un consumidor nuevo reprocesó la historia y un pedido viejo se volvió a cobrar. ¿Qué falló y qué política pondrías para consumidores nuevos? 🔴
13. En una entrevista de banca te preguntan "¿coreografía u orquestación para el alta de un préstamo?". Responde con los criterios de este taller. 🔴
14. El orquestador acaba de escalar una saga con el pedido `PAID` y la reserva caducada. Diseña qué ve la persona que la recibe y qué opciones tiene. 🔴

## 🧪 Ejercicios

1. 🟢 Corre las tres ramas con el orquestador y pega `saga-status` de cada una. Señala en el registro de
   transiciones el paso pivote.
2. 🟢 **Orientación en código ajeno.** Encuentra, con ruta y línea, dónde decide el orquestador que un paso
   ha vencido y dónde se calcula cuándo toca el siguiente intento.
3. 🟡 Haz que el orquestador despierte en cuanto una saga avanza, en vez de esperar al siguiente sondeo, y
   mide cuánto baja el tiempo hasta `PAID`.
4. 🟡 Añade a `saga-status` (o a un `GET /api/v2/orders/{orderId}/saga` solo para operadores) el
   registro de transiciones, y decide qué no debe ver el cliente.
5. 🟠 Implementa un contrato intermedio entre `v1` y `v2`: reserva síncrona por gRPC en el alta (`201`/`409` como en
   `v1`) y solo el pago asíncrono. Compara el tamaño de la máquina de estados con la de este taller.
6. 🔴 Añade una bandeja de sagas escaladas: una consulta, una alerta cuando haya alguna de más de 5 minutos,
   y dos acciones manuales (reintentar el paso, marcar como resuelta con un motivo).
7. 🔴 Aplica el parche `1-antifraude-orquestacion.patch` sobre una copia y haz que el antifraude corra **en
   paralelo** con la reserva, no después. ¿Qué cambia en la máquina, y qué compensación nueva aparece?
8. 🔥 Escribe la misma saga como un flujo de Temporal (en el lenguaje que prefieras) sin levantarlo: tres
   actividades, compensaciones y plazos. Señala qué líneas de `Orchestrator.java` y de `SagaStore.java`
   desaparecen.

---

**Anterior:** [`08` — Saga coreografiada](08-saga-coreografiada.md). **Siguiente:** [`10` — Contratos entre servicios y
testing](10-contratos-y-testing.md). **Relacionado:** [`03/03` — Saga](../03-datos-y-consistencia/03-saga.md).
