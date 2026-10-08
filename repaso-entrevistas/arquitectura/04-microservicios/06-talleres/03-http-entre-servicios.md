# 03 — HTTP entre servicios

Este taller es **opcional** y depende de [`02` — Strangler fig con Envoy](02-strangler-fig-con-envoy.md):
parte de su sistema (Envoy delante, `inventory` en Go). Extrae `payments` a Python y, al hacerlo,
corrige por fin el defecto del [taller 01](01-el-monolito-y-su-contrato.md): la llamada al cobro sale
de la transacción. Después provoca lo que se rompe cuando una llamada HTTP entre servicios se
reintenta —**un pedido cobrado tres veces**—, lo arregla propagando la `Idempotency-Key`, descubre que
la idempotencia también puede congelar un resultado incierto, y pone un circuit breaker básico en
Java. Termina cuando la suite `v1` está en verde a través de Envoy con los dos servicios extraídos, y
las provocaciones tienen su salida pegada.

> Ejercita [`02/01` — Estilos de comunicación](../02-comunicacion/01-estilos-de-comunicacion.md),
> [`02/02` — HTTP entre servicios](../02-comunicacion/02-http-entre-servicios.md) y
> [`04/03` — Resiliencia en la práctica](../04-operacion-y-resiliencia/03-resiliencia-en-la-practica.md)
> §2–§4.
>
> **Vigencia:** 2026-09-29. Versiones verificadas ese día en PyPI y Maven Central; salidas corridas ese
> día en macOS con Docker Desktop.

**Salto rápido:** [1](#1--qué-enseña-este-taller) · [2](#2--prerrequisitos-y-versiones) · [3](#3-️-mapa-de-carpetas) · [4](#4--recorrido-de-la-base-de-código) · [5](#5--parte-1-payments-fuera-y-la-llamada-fuera-de-la-transacción) · [6](#6--parte-2-el-reintento-que-cobra-tres-veces) · [7](#7--parte-3-pending-no-es-una-respuesta-final) · [8](#8--parte-4-un-circuit-breaker-básico) · [9](#9--errores-reales-al-correrlo) · [10](#10--en-tres-plataformas) · [11](#11--teardown) · [Preguntas](#-preguntas) · [Ejercicios](#-ejercicios)

---

## 1. 🎯 Qué enseña este taller

```text
cliente ──► Envoy ──► ms-monolith ──► Toxiproxy :28184 ──► payments (Python) :28084 ──► Toxiproxy :28185 ──► psp-simulator
                           │  timeout 2,5 s · 3 intentos con backoff y jitter         timeout 2 s
                           │  circuit breaker DENTRO del reintento                    registra la intención ANTES de llamar
                           │  Idempotency-Key del cliente → payments → proveedor      PENDING se vuelve a preguntar
                           └── tx corta · llamada sin conexión · tx corta
```

Cuatro ideas, una por parte:

- **La llamada remota fuera de la transacción.** El defecto de `06/01` no se arregla extrayendo un
  servicio: se arregla **partiendo el flujo** en transacción corta, llamada sin conexión tomada y
  transacción corta. La tormenta de `06/01` se repite y el catálogo ya no cae.
- **Un reintento sin clave es otro cobro.** Con `payments` respondiendo tarde, el monolito reintenta
  un `POST` que sí llegó. Sin propagar la `Idempotency-Key`, cada intento es una operación nueva:
  **tres cobros de 49,90 para un pedido que el cliente ve pendiente**. Con la clave, uno.
- **`PENDING` no es una respuesta final.** La idempotencia guarda respuestas para repetirlas; si guarda
  un "no sé", lo repite para siempre. La repetición con la misma clave tiene que **volver a preguntar**.
- **El circuit breaker protege al que llama, y lo hace de forma sorprendente.** Con `payments` caído,
  el tercer pago falla en 11 ms sin llamar. Y un breaker que se abrió por una prueba de latencia
  rechazó después un pago que no tenía nada que ver: la ventana es global al destino.

El precio, en las cinco monedas: **latencia** (un salto más por pago; hasta 8 s en el peor caso de
tres intentos con timeout), **consistencia** (entre la primera y la segunda transacción el pedido no
está bloqueado; un pago puede quedar pendiente y resolverse después), **operación** (un proceso
Python, su base y su proxy), **dinero** (una instancia más) y **esfuerzo** (≈ 130 líneas de Python y
≈ 260 de Java, de las que la mitad son decisiones sobre qué hacer con cada tipo de fallo).

## 2. 🧰 Prerrequisitos y versiones

| Herramienta | Versión fijada | Para qué |
|---|---|---|
| Todo lo de `06/02` | la de `06/02` §2 | Envoy, `inventory`, monolito, PSP, PostgreSQL, Toxiproxy |
| Python | `3.14.7` (a través de `uv`) | el servicio `payments` |
| `uv` | el del sistema (0.11.x al escribir) | entorno y dependencias de `payments` |
| `fastapi` · `uvicorn` | `0.141.1` · `0.54.0` | HTTP asíncrono |
| `httpx` | `0.28.1` | cliente asíncrono hacia el proveedor, con timeout |
| `psycopg[binary]` · `psycopg-pool` | `3.3.6` · `3.3.3` | PostgreSQL con pool asíncrono |
| `resilience4j-circuitbreaker` · `resilience4j-retry` | `2.4.0` | reintento y breaker en el monolito, sin AOP |

```text
python3 laboratorio/scripts/lab.py up
python3 laboratorio/scripts/lab.py seed
python3 laboratorio/scripts/lab.py psp                                          # terminal 1
python3 laboratorio/scripts/lab.py inventory                                    # terminal 2
python3 laboratorio/scripts/lab.py payments                                     # terminal 3
python3 laboratorio/scripts/lab.py monolith --inventory remote --payments remote   # terminal 4
```

- `up` publica ahora el tercer proxy de Toxiproxy, `payments` (`28184` → `host.docker.internal:28084`).
- `seed` añade `ms_payments` (tabla `payments`, vacía).
- `payments` ejecuta `uv sync --quiet --python 3.14` y arranca `uvicorn app.main:app` en `:28084`.
  `--python 3.14` elige el intérprete; `uv` lo busca en el sistema (aquí, el de Homebrew).
- `monolith --payments remote` activa `RemotePayments`; `--no-payment-key` deja de propagar la
  `Idempotency-Key` a `payments`, que es la provocación de §6.

> **📝 Contexto:** el código tal como queda al terminar este taller está congelado en
> `laboratorio/estados/03/`, y las rutas con número de línea se refieren a esa copia. Si ya existen
> talleres posteriores, añade `--estado 03` a cada orden de `lab.py`.

## 3. 🗂️ Mapa de carpetas

```text
laboratorio/estados/03/                       (lab.py --estado 03)
├── contrato/
│   ├── openapi.yaml                          + PAYMENTS_UNAVAILABLE; la repetición de un PENDING, documentada
│   ├── toxiproxy/proxies.json                + proxy `payments`
│   └── seed/payments/schema.sql              payments(id, order_id, operation_id UNIQUE, amount, status, reference)
├── payments/                                 el servicio extraído, Python
│   ├── pyproject.toml                        dependencias fijadas con ==
│   └── app/main.py                           POST /payments · GET /payments · GET /health
└── monolith/src/main/java/dev/ms/monolith/
    ├── payments/                             Payments (la costura) · LocalPayments · RemotePayments
    └── service/PaymentService.java           tx corta → cobro → tx corta; resolvePending
```

## 4. 🔎 Recorrido de la base de código

Rutas relativas a `laboratorio/estados/03/`.

**¿Dónde se parte el flujo del pago?** `monolith/.../service/PaymentService.java`: la primera
transacción lee el importe (líneas 51–55), la línea 57 cobra **sin transacción abierta**, y la
segunda transacción aplica el resultado. El inventario se toca después del commit, fuera de toda
transacción, porque `consume` y `release` son idempotentes.

**¿Qué se reintenta y qué no?** `monolith/.../payments/RemotePayments.java`, línea 58:
`retryExceptions(ResourceAccessException.class, HttpServerErrorException.class)`. Se reintenta el
timeout, la conexión fallida y el `5xx`; un `4xx` no, porque no va a cambiar. La línea 67 hace que un
`4xx` tampoco cuente como fallo para el breaker: es nuestro error, no su caída.

**¿En qué orden van reintento y breaker?** Línea 81:
`Retry.decorateSupplier(retry, CircuitBreaker.decorateSupplier(breaker, call))`. El breaker está
**dentro**: cada intento cuenta, y cuando está abierto lanza `CallNotPermittedException`, que no está en
la lista de reintentables. El orden está escrito en el código, no en el orden de dos anotaciones.

**¿Qué significa cada fallo?** El `catch` de la línea 86: un timeout devuelve `PENDING` (pudo
cobrar); una conexión rechazada o el breaker abierto lanzan `PaymentsUnavailable` (seguro que no
cobró, `503`, el pedido sigue pagable).

**¿Qué hace `payments` con la clave?** `payments/app/main.py`, línea 79: sin `Idempotency-Key`,
inventa una (`gen-…`) y el intento es nuevo; con ella, busca la operación. La línea 89 distingue una
respuesta firme (se repite) de un `PENDING` (se vuelve a preguntar). La intención se inserta y se
confirma **antes** de llamar al proveedor (líneas 97–108).

## 5. 🔀 Parte 1: `payments` fuera, y la llamada fuera de la transacción

**Qué es.** El mismo patrón que `inventory`: una costura `Payments` con `LocalPayments` (el proveedor
llamado directamente, como siempre) y `RemotePayments` (el servicio). Lo que cambia de verdad es
`PaymentService.pay`:

```java
BigDecimal amount = tx.execute(s -> {                       // 1. transacción corta
    var order = OrderService.visible(actor, orders.findForUpdate(orderId).orElseThrow(...));
    if (!"CONFIRMED".equals(order.getStatus())) throw new Errors.OrderNotPayable(order.getStatus());
    return order.getTotalAmount();
});
var result = gateway.authorize(orderId, amount, idempotencyKey);   // 2. sin conexión tomada
var response = tx.execute(s -> { ... });                    // 3. transacción corta: aplicar y guardar
```

- El `@Transactional` que abarcaba la llamada desapareció. Cada transacción dura milisegundos, por
  lento que esté el proveedor.
- El precio: entre 1 y 3 el pedido no está bloqueado. El paso 3 vuelve a comprobar el estado en vez
  de suponerlo; una cancelación que se cuele entre medias deja un cobro sobre un pedido cancelado,
  que es lo que una saga gestiona (talleres 08 y 09).

**La tormenta de `06/01`, otra vez**: PSP a +1,5 s, veinte pagos a la vez, el mismo pool de 5
conexiones. Salida literal, 2026-09-29:

```text
psp: +1500 ms en cada respuesta (200)
20 pedidos creados; pagando todos a la vez y sondeando el catálogo…

pagos (20 en 1.9 s):
  200 PAID                     × 20   p50 1.63 s   máx 1.65 s

catálogo durante la tormenta (GET /api/v1/products):
  01:13:43  200  0.02 s
  01:13:43  200  0.02 s
  …
  01:13:44  200  0.07 s

catálogo: 7/7 respuestas 200
```

- En `06/01`: 10 `PAID`, 10 `500` y el catálogo cayendo. Ahora: 20 `PAID` en 1,9 s y el catálogo a
  20 ms. Ni el pool ni el proveedor cambiaron: cambió **quién espera con qué recurso tomado**.

La suite a través de Envoy, con `inventory` y `payments` extraídos, 2026-09-29:

```text
Success 01-health.hurl (1 request(s) in 6 ms)
Success 02-auth.hurl (5 request(s) in 370 ms)
Success 03-products.hurl (4 request(s) in 214 ms)
Success 04-orders.hurl (16 request(s) in 423 ms)
Success 05-payment.hurl (12 request(s) in 2336 ms)
Success 06-cancel.hurl (8 request(s) in 198 ms)
Executed requests: 46 (12.9/s)
Succeeded files:   6 (100.0%)
```

Y el cambio en el monolito respecto del taller 02:

```text
$ git diff --no-index --stat estados/02/monolith/src monolith/src
 config/MsProperties.java             |   7 ++-
 entity/Payment.java                  |   1 +
 payments/LocalPayments.java          |  27 ++++++++++
 payments/Payments.java               |  20 +++++++
 payments/RemotePayments.java         | 100 ++++++++++++++++++++++++++++++++++
 repository/IdempotencyRepository.java |   5 ++
 repository/PaymentRepository.java    |   1 +
 service/Errors.java                  |   3 ++
 service/Idempotency.java             |   5 ++
 service/PaymentService.java          | 105 ++++++++++++++++++++++++------------
 web/ApiErrors.java                   |   6 +++
 resources/application.yaml           |  15 ++++++
 12 files changed, 259 insertions(+), 36 deletions(-)
```

- `OrderService` no aparece: la costura del cobro no toca el alta de pedidos. `PaymentService` sí,
  entero, porque su problema no era de acceso a datos sino de flujo.

> **Veredicto:** extraer `payments` separó los recursos, pero lo que arregló la cascada de `06/01` fue
> sacar la llamada de la transacción, y eso se podía hacer dentro del monolito. Extraer compra
> despliegue y equipo independientes; no compra por sí solo que el flujo sea correcto.

## 6. 🧨 Parte 2: el reintento que cobra tres veces

**El síntoma**: un cliente se queja de tres cargos en su tarjeta por una sola compra, y el pedido
dice "pago pendiente".

```text
python3 laboratorio/scripts/lab.py monolith --inventory remote --payments remote --no-payment-key
python3 laboratorio/scripts/lab.py slow payments --latency 3000
```

- `--no-payment-key` hace que `RemotePayments` no envíe la `Idempotency-Key` a `payments`.
- `slow payments --latency 3000` retrasa 3 s cada **respuesta** de `payments`; el monolito espera
  2,5 s. `payments` procesa, cobra y responde; la respuesta llega tarde; el monolito reintenta.

Un pedido, un pago, 2026-09-29:

```text
{"orderId":"c2262c56-…","orderStatus":"PAYMENT_PENDING","payment":{"status":"PENDING","operationId":"t03-pay-0001","reference":null}}
→ 200 en 8.037399s
--- monolito
WARN … payments: retry 1 after 103 ms (ResourceAccessException)
WARN … payments: retry 2 after 348 ms (ResourceAccessException)
--- payments
gen-7b88900f-3866-46f2-9ca2-1b3942e637fe AUTHORIZED psp-2f28138a
gen-643edbd0-1a14-455a-a43e-e6b4b518e560 AUTHORIZED psp-530221ee
gen-370010af-07ee-4156-954e-dea2b41a065d AUTHORIZED psp-f83580b5
--- psp-simulator (cobros registrados)
psp-2f28138a c2262c56 49.90 gen-7b88900f-…
psp-530221ee c2262c56 49.90 gen-643edbd0-…
psp-f83580b5 c2262c56 49.90 gen-370010af-…
3 cobros
```

**La cadena:**

```text
intento 1 ──► payments cobra (gen-7b88…) ──► respuesta tarda 3 s ──► el monolito expira a 2,5 s
intento 2 ──► payments NO reconoce la operación (sin clave) ──► cobra otra vez (gen-643e…)
intento 3 ──► y otra (gen-3700…)
el monolito agota los intentos por timeout ──► PAYMENT_PENDING
```

- Los tres intentos llegaron, y los tres cobraron. El reintento es correcto —un timeout no dice que
  la operación fallara—; lo que falta es que el reintento **sea la misma operación**.
- Fíjate en el backoff con jitter: 103 ms y 348 ms, no 200 y 400 fijos. Con cien clientes reintentando
  a la vez, el jitter es lo que evita que lleguen todos en el mismo milisegundo.

**Con la clave** (el monolito sin `--no-payment-key`), misma prueba:

```text
→ 200 en 8.107801s
--- monolito
WARN … payments: retry 1 after 174 ms (ResourceAccessException)
WARN … payments: retry 2 after 314 ms (ResourceAccessException)
--- payments
t03-pay-0002 AUTHORIZED psp-97d0096e
--- psp-simulator (cobros registrados)
psp-97d0096e e52d3323 49.90 t03-pay-0002
1 cobros
```

- Los mismos tres intentos, **un** cobro. La clave viaja de extremo a extremo: el cliente la elige,
  el monolito la reenvía a `payments`, `payments` la usa como `operation_id` único y la reenvía al
  proveedor, que también deduplica por ella.

> **Veredicto:** reintentar un `POST` sin clave de idempotencia es cobrar varias veces con buena
> intención. La clave no es un encabezado más: es la identidad de la operación, y tiene que llegar
> hasta el último sistema que tiene efectos.

## 7. 🧱 Parte 3: `PENDING` no es una respuesta final

La salida anterior tenía un problema que no se veía: el pago **sí** se autorizó —`payments` lo dice—,
pero el cliente lo ve pendiente. Cuando el cliente reintenta con su clave, la primera versión de este
taller devolvía otra vez `PAYMENT_PENDING`: la tabla de idempotencia del monolito había guardado el
"no sé" y lo repetía para siempre. Es un error real de diseño (§9), y `payments` tenía el mismo con sus
`PENDING`.

**La regla**: una respuesta firme se repite; un `PENDING` se vuelve a preguntar **con la misma clave**.

```java
if (replay.isPresent()) {
    var stored = json.readValue(replay.get().body(), Views.PaymentResponse.class);
    if (!"PAYMENT_PENDING".equals(stored.orderStatus())) return new Result(..., true);   // firme: se repite
    return resolvePending(actor, orderId, idempotencyKey, replay.get());               // incierto: se pregunta
}
```

- `resolvePending` llama otra vez a `Payments` con la misma clave. Si la respuesta ya es firme, pasa el
  pedido a `PAID` o `PAYMENT_REJECTED`, actualiza el pago y **sustituye** la respuesta guardada; si
  sigue `PENDING`, devuelve la de antes.
- En `payments` (`main.py`, línea 89) es lo mismo: un `PENDING` guardado no se repite, se vuelve a
  preguntar al proveedor con la misma clave, que él reconoce.

**La prueba**, 2026-09-29. Escenario A: `payments` lento, el cliente reintenta cuando ya no lo está.

```text
=== A. payments lento (+3 s) y reintento del cliente
{"orderId":"679ee402-…","orderStatus":"PAYMENT_PENDING","payment":{"status":"PENDING",…}}  → 200 en 8.329163s
HTTP/1.1 200 OK
idempotent-replay: true
{"orderId":"679ee402-…","orderStatus":"PAID","payment":{"status":"AUTHORIZED","operationId":"t03-pay-0003","reference":"psp-8524dc1d"}}
```

Escenario B: el importe `666.00`, que el proveedor cobra y responde a los 3 s.

```text
=== B tras 11 s
{"orderId":"4d82283d-…","orderStatus":"PAYMENT_PENDING","payment":{"status":"PENDING",…}}  → 200 en 2.072959s
{"orderId":"4d82283d-…","orderStatus":"PAID","payment":{"status":"AUTHORIZED","operationId":"t03-pay-0004","reference":"psp-b4af98df"}}  → 200 en 0.065160s
--- cobros en el proveedor
psp-8524dc1d 49.90 t03-pay-0003
psp-b4af98df 666.00 t03-pay-0004
2 cobros
   sku   | qty |  status
---------+-----+-----------
 SKU-001 |   1 | COMMITTED
 SKU-003 |   3 | COMMITTED
```

- Un cobro por pedido, los dos pedidos `PAID` y las dos retenciones consumidas. El resultado incierto
  de `06/01` —que allí se quedaba incierto para siempre— ahora se resuelve cuando el cliente reintenta.
- Lo que falta, y el taller lo deja dicho: si el cliente **no** reintenta, nadie pregunta. Eso es trabajo
  de un proceso de conciliación o de un orquestador con plazo ([taller 09](09-saga-orquestada.md)).

> **Veredicto:** la idempotencia guarda respuestas para no repetir efectos. Una respuesta que dice
> "no sé" no es un efecto, y guardarla como definitiva convierte la duda en permanente.

## 8. 🧱 Parte 4: un circuit breaker básico

**Qué es.** Un contador de fallos por destino que, pasado un umbral, deja de llamar durante un tiempo
y falla en milisegundos. Aquí: ventana de 10 llamadas, mínimo 4, umbral del 50 %, abierto 10 s, dos
llamadas de prueba en semiabierto (`application.yaml`, `ms.payments.breaker`).

**La provocación**: `payments` apagado, tres pagos seguidos. 2026-09-29:

```text
pago 1 → 503 en 0.720923s
pago 2 → 503 en 0.132396s
pago 3 → 503 en 0.010906s
WARN … payments: retry 1 after 102 ms (ResourceAccessException)
WARN … payments: retry 2 after 578 ms (ResourceAccessException)
WARN … payments unavailable: I/O error on POST request …
WARN … payments: circuit breaker State transition from CLOSED to OPEN
WARN … payments: retry 1 after 110 ms (ResourceAccessException)
WARN … payments unavailable: circuit breaker open
WARN … payments unavailable: circuit breaker open
--- el pedido sigue pagable (CONFIRMED)
CONFIRMED None
pago 3 otra vez, con payments arriba → 200 en 0.058958s
PAID
```

- **Pago 1**: tres intentos con backoff (102 y 578 ms), conexión rechazada en los tres: `503` en
  0,72 s. **Pago 2**: el primer intento suma el cuarto fallo, el breaker se abre y el reintento ya no
  se permite: 0,13 s. **Pago 3**: el breaker no deja llamar: 11 ms.
- `503 PAYMENTS_UNAVAILABLE` significa que es **seguro** que no se cobró (no se conectó o no se llamó),
  y por eso el pedido sigue `CONFIRMED` y el reintento con la misma clave, con `payments` de vuelta, lo
  deja `PAID`. Un timeout, en cambio, habría sido `PENDING`.
- El breaker pasa a `HALF_OPEN` en la primera llamada después de los 10 s (Resilience4j no transita
  solo por defecto) y a `CLOSED` tras dos llamadas buenas:

```text
WARN … payments: circuit breaker State transition from CLOSED to OPEN
WARN … payments: circuit breaker State transition from OPEN to HALF_OPEN
WARN … payments: circuit breaker State transition from HALF_OPEN to CLOSED
```

**Lo que sorprendió** (§9): el escenario B de §7 falló la primera vez con `503` en 15 ms. El breaker se
había abierto **durante el escenario A** —tres timeouts y un éxito son cuatro llamadas con un 75 % de
fallos— y rechazó un pago del `666.00` que no tenía nada que ver. La ventana del breaker es por
destino, no por pedido ni por cliente: una prueba de latencia abre el circuito para todos.

> **Veredicto:** el breaker convierte una dependencia caída en un error de milisegundos y quita carga a
> quien intenta recuperarse. Lo paga con falsos positivos —cierra el paso a todo el tráfico del destino
> por lo que le pasó a una parte— y con umbrales que hay que calibrar con tráfico real, no con tres
> peticiones.

## 9. 🩺 Errores reales al correrlo

### `.python-version` rompió `uv` a través de pyenv

```text
pyenv: version `3.14' is not installed (set by …/payments/.python-version)
pyenv: uv: command not found
```

El archivo `.python-version` lo leen **uv y pyenv**. En esta máquina `uv` se instaló a través de pyenv,
así que su *shim* obedeció al archivo, buscó un Python 3.14 de pyenv que no existe, y ni siquiera
encontró `uv`. **Corrección:** sin `.python-version`; el intérprete lo elige `uv sync --python 3.14`
(`requires-python = ">=3.14"` en el `pyproject.toml` lo exige). **Lección:** un archivo de
configuración "de una herramienta" puede tener más lectores de los que crees.

### La idempotencia congelaba el resultado incierto

Descrito en §7. La primera versión guardaba el `PAYMENT_PENDING` en `idempotency_keys` y lo repetía;
`payments` hacía lo mismo con sus filas `PENDING`. El reintento del cliente, que es justo lo que
resolvería la duda, no la resolvía nunca. **Corrección:** una respuesta incierta no se repite, se vuelve
a preguntar con la misma clave. **Lección:** cada capa de idempotencia tiene que distinguir "ya hecho"
de "no sé si hecho".

### El breaker abierto por una prueba anterior rechazó un pago ajeno

Descrito en §8. No se corrigió, porque es el comportamiento del patrón; se documenta. **Lección:** al
leer un `503` rápido, lo primero es el estado del breaker (y sus transiciones en el log), no el
destino.

## 10. 🧰 En tres plataformas

| Plataforma | Qué te da hecho | Lo que te deja a ti |
|---|---|---|
| **Java** | `RestClient` con timeout por fábrica; Resilience4j con `Retry` e `IntervalFunction.ofExponentialRandomBackoff`, y `CircuitBreaker` con eventos de transición | Decidir qué excepción significa "no cobró" y cuál "no sé", y el orden de los decoradores; con anotaciones, además, el proxy y la autoinvocación |
| **Go** | `http.Client` con `Timeout` y `context.WithTimeout`; el breaker es `sony/gobreaker`, una struct | El reintento con backoff y jitter, a mano o con una librería mínima; propagar el `context` y la clave en cada salto |
| **Python** | `httpx.AsyncClient` con `Timeout` (5 s por defecto si no se da uno); `tenacity` para reintentos; para el breaker, `pybreaker` es síncrono (su `call_async` es de Tornado) y con `asyncio` se usa `purgatory` ([taller 05](05-resiliencia-en-tres-plataformas.md)) | Que el reintento y el breaker convivan con `asyncio`, y el estado del breaker por proceso: con varios workers de uvicorn, cada uno decide solo |

La fila de Node/TS —`opossum` para el breaker y `AbortSignal.timeout()` para el plazo— está en
[`04/03`](../04-operacion-y-resiliencia/03-resiliencia-en-la-practica.md).

## 11. 🧹 Teardown

```text
Ctrl+C en las terminales de psp, inventory, payments y monolith
python3 laboratorio/scripts/lab.py down
```

- `down` borra los contenedores y los volúmenes, incluida `ms_payments`. El entorno de `uv`
  (`payments/.venv/`) se queda: no es estado del sistema, es su dependencia instalada.

## ⚠️ Errores frecuentes

| Se dice | Lo preciso |
|---|---|
| "Extrajimos `payments` y se arregló la cascada" | La arregló sacar la llamada de la transacción; eso se podía hacer en el monolito |
| "Si la llamada expiró, falló; se reintenta y listo" | Expirar es "no sé"; sin una clave que identifique la operación, el reintento repite el efecto |
| "La idempotencia se resuelve guardando la respuesta" | Hay que distinguir respuesta firme de respuesta incierta; guardar un `PENDING` como definitivo lo congela |
| "El circuit breaker evita la caída del servicio caído" | Protege al que llama y le quita carga al caído; no arregla nada, y cierra el paso a todo el tráfico del destino |
| "Se reintenta todo error" | Un `4xx` no cambia al repetirlo; se reintentan timeouts, fallos de conexión y `5xx`, con backoff y jitter |
| "Tres intentos no hacen daño" | Multiplican la carga sobre un destino que ya va mal, y el tiempo del cliente: aquí, 8 s en el peor caso |

## 📚 Para profundizar

- **Libro** — Michael T. Nygard, *Release It!*, 2.ª ed., Pragmatic Bookshelf, 2018, cap. 5, "Stability
  Patterns" (timeouts, circuit breaker, bulkheads).
- **Libro** — Chris Richardson, *Microservices Patterns*, Manning, 2018, cap. 3, §3.2.3, "Handling
  partial failure using the Circuit breaker pattern".
- **Documentación** — [Resilience4j: CircuitBreaker](https://resilience4j.readme.io/docs/circuitbreaker)
  · [Retry](https://resilience4j.readme.io/docs/retry)
  · [Spring Boot: REST clients](https://docs.spring.io/spring-boot/reference/io/rest-client.html).
- **Documentación** — [FastAPI: concurrencia y `async`](https://fastapi.tiangolo.com/async/)
  · [httpx: timeouts](https://www.python-httpx.org/advanced/timeouts/)
  · [psycopg: connection pools](https://www.psycopg.org/psycopg3/docs/advanced/pool.html)
  · [uv: versiones de Python](https://docs.astral.sh/uv/concepts/python-versions/).
- **Fuente primaria** — [microservices.io: *Circuit Breaker*](https://microservices.io/patterns/reliability/circuit-breaker.html).
- **Especificación** — [IETF, *The Idempotency-Key HTTP Header Field* (borrador)](https://datatracker.ietf.org/doc/draft-ietf-httpapi-idempotency-key-header/).
- **Material de referencia** — [Amazon Builders' Library, *Timeouts, retries and backoff with jitter*](https://builder.aws.com/content/3EumjoZascWd1oZiEgL8ORlv3qE/timeouts-retries-and-backoff-with-jitter).

## 🧠 Preguntas

1. ¿En qué tres pasos se partió `PaymentService.pay` y qué se ganó con ello? 🟢
2. ¿Qué excepciones reintenta `RemotePayments` y por qué no un `4xx`? 🟢
3. ¿Qué hace `payments` cuando le llega una petición sin `Idempotency-Key`? 🟢
4. ¿Qué diferencia hay entre `503 PAYMENTS_UNAVAILABLE` y `PAYMENT_PENDING` para el cliente? 🟡
5. ¿Por qué `payments` registra la intención y hace commit antes de llamar al proveedor? 🟡
6. Explica los tiempos 0,72 s, 0,13 s y 0,011 s de los tres pagos con `payments` apagado. 🟡
7. ¿Por qué el breaker va dentro del reintento y no fuera? 🟡
8. ¿Qué te da Python asíncrono para `payments` y qué pasa con el estado de un breaker si arrancas varios workers? 🟡
9. La tormenta de `06/01` ya no tumba el catálogo. ¿Qué cambió exactamente, y qué no hizo falta cambiar? 🟠
10. ¿Por qué guardar un `PENDING` en la tabla de idempotencia es un error, y qué hace ahora una repetición con la misma clave? 🟠
11. El breaker se abrió por una prueba de latencia y rechazó un pago ajeno. ¿Es un fallo del breaker? ¿Qué ajustarías? 🟠
12. Tres intentos de 2,5 s más backoff son hasta 8 s. ¿Cómo encaja eso con el timeout de 10 s de Envoy y con lo que espera el cliente? 🟠
13. Dibuja el recorrido de la `Idempotency-Key` desde el cliente hasta el proveedor y marca dónde se deduplica en cada salto. 🔴
14. En producción, un cliente reporta dos cargos por un pedido que figura `PAYMENT_PENDING`. Da tres hipótesis en orden de probabilidad y qué mirarías para cada una. 🔴

## 🧪 Ejercicios

1. 🟢 Repite la provocación de §6 con `--latency 2000` en vez de 3000. ¿Cuántos cobros hay y por qué?
   Pega la salida.
2. 🟢 **Orientación en código ajeno.** Encuentra, con ruta y línea, dónde decide `payments` que una
   petición con una clave ya vista y estado `IN_PROGRESS` responde `409`, y qué hace el monolito con
   ese `409`.
3. 🟡 Cambia el orden de los decoradores en `RemotePayments` (el reintento dentro del breaker) y repite
   la prueba de §8. Pega los tiempos y las transiciones y explica la diferencia.
4. 🟡 Arranca `payments` con dos workers de uvicorn (`--workers 2`) y añade un contador de peticiones en
   memoria. ¿Qué te dice el resultado sobre cualquier estado en memoria del servicio, breaker incluido?
5. 🟠 Añade al monolito un proceso de conciliación que, cada 30 s, busque pagos `PENDING` con más de un
   minuto y pregunte a `payments` por su `operation_id`. Demuestra que resuelve un pago pendiente sin
   que el cliente reintente.
6. 🟠 Configura el breaker por **tasa de llamadas lentas** (`slowCallDurationThreshold`,
   `slowCallRateThreshold`) en vez de por errores y provoca que se abra con `slow payments`. ¿Qué gana y
   qué arriesga respecto de abrir solo por errores?
7. 🔴 Sustituye `LocalPayments` por la llamada directa al proveedor **dentro** de una transacción, como
   en `06/01`, con el breaker delante. Repite la tormenta con el proveedor lento. ¿Salva el breaker al
   catálogo? Argumenta con la salida.
8. 🔥 Escribe el cliente de `payments` en Go con `sony/gobreaker` y un reintento con jitter propio, y
   compáralo en líneas y en decisiones con `RemotePayments`.

---

**Anterior:** [`02` — Strangler fig con Envoy](02-strangler-fig-con-envoy.md). **Siguiente:**
[`04` — gRPC](04-grpc.md). **Relacionado:** [`02/02` — HTTP entre servicios](../02-comunicacion/02-http-entre-servicios.md).
