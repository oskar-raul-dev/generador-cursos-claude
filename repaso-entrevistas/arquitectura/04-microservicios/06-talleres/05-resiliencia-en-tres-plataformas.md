# 05 — Resiliencia en tres plataformas

Este taller es **opcional** y depende de [`04` — gRPC](04-grpc.md): parte del sistema con `orders`,
`inventory` y `payments` fuera del monolito. Es el único del bloque que implementa **lo mismo en las tres
plataformas** a propósito: bulkhead en Java, límite de tasa y de concurrencia en Go, circuit breaker en
Python, cada uno donde tiene sentido. Después provoca las dos formas más comunes de que la resiliencia
empeore las cosas —reintentos en dos capas que se multiplican y una readiness que convierte la caída de
una dependencia en la caída propia— y encuentra de paso tres comportamientos de Envoy y de Resilience4j
que no dicen los ejemplos. Termina con la suite `v1` en verde y cada provocación con su salida.

> Ejercita [`04/03` — Resiliencia en la práctica](../04-operacion-y-resiliencia/03-resiliencia-en-la-practica.md)
> y [`04/01` — Descubrimiento y enrutamiento](../04-operacion-y-resiliencia/01-descubrimiento-y-enrutamiento.md),
> y vuelve sobre los health checks de [`01/05`](../01-fundamentos-y-descomposicion/05-el-servicio-por-dentro.md).
>
> **Vigencia:** 2026-09-29. Versiones verificadas ese día en PyPI, Maven Central y `proxy.golang.org`;
> salidas corridas ese día en un Apple M1 Pro con Docker Desktop.

**Salto rápido:** [1](#1--qué-enseña-este-taller) · [2](#2--prerrequisitos-y-versiones) · [3](#3-️-mapa-de-carpetas) · [4](#4--recorrido-de-la-base-de-código) · [5](#5--go-la-resiliencia-de-quien-recibe) · [6](#6--java-un-bulkhead-hacia-payments) · [7](#7--python-un-circuit-breaker-asíncrono-hacia-el-proveedor) · [8](#8--provocación-reintentos-en-dos-capas) · [9](#9--provocación-la-readiness-que-mira-a-otro) · [10](#10--hallazgos-al-correrlo) · [11](#11--en-tres-plataformas) · [12](#12--teardown) · [Preguntas](#-preguntas) · [Ejercicios](#-ejercicios)

---

## 1. 🎯 Qué enseña este taller

```text
cliente ──► Envoy ── reintenta SOLO lo que no llegó (connect-failure, refused-stream)
              │    └ chequeo activo: /actuator/health/readiness de orders (umbral de pánico 0)
              ▼
            orders (Java) ── Bulkhead(4) → Retry(3, jitter) → CircuitBreaker → payments
              │                                                        │
              │ gRPC                                        purgatory: breaker hacia el PSP
              ▼                                             (abierto → 503 PSP_UNAVAILABLE)
            inventory (Go) ── límite de tasa (token bucket) + máximo en vuelo → RESOURCE_EXHAUSTED
```

Cada plataforma recibe el patrón que le toca por su posición, no por reparto:

- **Go (`inventory`) es servidor**: no llama a nadie. Su resiliencia es la de quien recibe: **rechazar
  pronto** lo que no cabe, antes de tocar la base. Con límites, 380 de 400 peticiones se rechazan en
  ≈ 4 ms; sin ellos, las 400 llegan a PostgreSQL.
- **Java (`orders`) llama a un tercero lento**: un **bulkhead** limita cuántos pagos están en curso a la
  vez. Con 16 hilos y 30 pagos lentos, sin bulkhead una lectura cualquiera espera 1,94 s por un hilo; con
  él, 26 pagos se rechazan en 0,16 s y la lectura no pasa de 0,22 s.
- **Python (`payments`) llama al proveedor**: un **circuit breaker** asíncrono. Tras tres timeouts
  seguidos, deja de llamar y responde `503 PSP_UNAVAILABLE` en milisegundos: seguro, porque no llamó.
- **Las dos provocaciones**: Envoy y `orders` reintentando a la vez convierten un pago en
  **9 llamadas** a un servicio caído; y una readiness que incluye a `payments` hace que la lista de
  pedidos, que no paga nada, devuelva `503`.

El precio, en las cinco monedas: **latencia** (poca; rechazar es más rápido que esperar), **consistencia**
(ninguna nueva: cada rechazo está diseñado para ser seguro de repetir), **operación** (umbrales que hay
que calibrar con tráfico real y vigilar), **dinero** (nada en infraestructura) y **esfuerzo** (78 líneas de
Java, 67 de Go y 34 de Python sobre el taller 04; la mitad de las horas se fueron en entender por qué los
números salían como salían).

## 2. 🧰 Prerrequisitos y versiones

| Herramienta | Versión fijada | Para qué |
|---|---|---|
| Todo lo de `06/04` | la de `06/04` §2 | el sistema completo |
| `resilience4j-bulkhead` | `2.4.0` | bulkhead de semáforo en `orders` |
| `spring-boot-starter-actuator` | la del BOM de Boot 4.1.1 | liveness y readiness de `orders` |
| `golang.org/x/time` | `v0.16.0` | `rate.Limiter` (token bucket) en `inventory` |
| `purgatory` | `3.0.1` (última publicación: noviembre de 2024) | circuit breaker nativo de `asyncio` en `payments` |

📝 En Python la elección no es obvia. `pybreaker` 1.4.1 (septiembre de 2025) es el breaker más usado, pero
su `call_async` depende de **Tornado** (`gen.coroutine`), no de `asyncio`. `purgatory` es nativo de
`asyncio` y permite guardar el estado en Redis, pero no publica desde noviembre de 2024: se usa sabiéndolo.

```text
python3 laboratorio/scripts/lab.py orders [--threads N] [--bulkhead N] [--breaker-min-calls N] [--readiness-includes-payments]
python3 laboratorio/scripts/lab.py inventory [--rps R --burst B] [--max-inflight N]
python3 laboratorio/scripts/lab.py bench --flood 400 --concurrency 32
python3 laboratorio/scripts/lab.py storm --orders 30 --base-url http://localhost:28080 --probe /api/v1/orders
python3 laboratorio/scripts/lab.py envoy-retries 5xx | safe
```

- `orders --threads` fija `server.tomcat.threads.max` (200 por defecto): con pocos hilos se ve el
  agotamiento. `--bulkhead 1000` equivale a no tener bulkhead. `--readiness-includes-payments` mete el
  indicador de `payments` en el grupo de readiness: la provocación de §9.
- `inventory --rps/--burst` activa el límite de tasa del servidor gRPC, y `--max-inflight`, el de
  peticiones en curso.
- `bench --flood N --concurrency C` lanza N retenciones gRPC con C a la vez y cuenta los códigos.
- `storm --probe` elige qué ruta sondear mientras paga en paralelo; aquí, la lista de pedidos, que
  atiende `orders` y no paga nada.
- `envoy-retries` reescribe la `retry_policy` de la ruta de `orders` y reinicia Envoy: `5xx` es la
  provocación; `safe`, la configuración del laboratorio.

> **📝 Contexto:** el código tal como queda al terminar este taller está congelado en
> `laboratorio/estados/05/`, y las rutas con número de línea se refieren a esa copia. Si ya existen
> talleres posteriores, añade `--estado 05` a cada orden de `lab.py`.

## 3. 🗂️ Mapa de carpetas

```text
laboratorio/estados/05/                          (lab.py --estado 05)
├── contrato/envoy/envoy.yaml                    retry_policy segura; health_checks; umbral de pánico 0
├── inventory/internal/grpcapi/limits.go         token bucket + semáforo, como interceptor gRPC
├── orders/
│   ├── .../payments/RemotePayments.java         Bulkhead → Retry → CircuitBreaker
│   ├── .../health/PaymentsHealthIndicator.java  el estado de payments, fuera de la readiness
│   └── src/main/resources/application.yaml      grupos de liveness y readiness
└── payments/app/main.py                         purgatory alrededor de la llamada al PSP
```

## 4. 🔎 Recorrido de la base de código

Rutas relativas a `laboratorio/estados/05/`.

**¿En qué orden se envuelve la llamada a `payments`?** `orders/.../payments/RemotePayments.java`, línea 92:
`Bulkhead.decorateSupplier(bulkhead, Retry.decorateSupplier(retry, CircuitBreaker.decorateSupplier(...)))`.
El bulkhead va **fuera**: limita los pagos en curso contando sus reintentos. La línea 78 le quita la
cola (`maxWaitDuration(Duration.ZERO)`): el que no cabe falla ya. La línea 64 decide qué se reintenta.

**¿Qué hace `inventory` con lo que no cabe?** `inventory/internal/grpcapi/limits.go`: la línea 38 pide un
token con `Allow()` (sin esperar: `Wait` encolaría) y la 46 es el `default` del `select` sobre el
semáforo, que rechaza en vez de esperar. Es un interceptor: se aplica a todas las RPC sin tocarlas.

**¿Dónde está el breaker de `payments`?** `payments/app/main.py`: la fábrica en la línea 41 (umbral de
fallos **seguidos**, no porcentaje), el `async with` en la 121 y el `except OpenedState` en la 127, que
borra la intención recién registrada y responde `503 PSP_UNAVAILABLE`.

**¿Qué decide si `orders` recibe tráfico?** `orders/src/main/resources/application.yaml`, línea 39:
`include: readinessState,db`. Y en Envoy (`contrato/envoy/envoy.yaml`), el chequeo activo de la línea 111,
con `no_traffic_interval` en la 114 y `healthy_panic_threshold` a 0 en la 122 (sus porqués, en §10).

## 5. 🧱 Go: la resiliencia de quien recibe

**Qué es.** Un servidor que acepta todo lo que le llega se degrada para todos a la vez. Rechazar pronto
lo que excede su capacidad —con un código que diga "reintenta más tarde"— protege a los que sí entraron.
Es *load shedding* (descarte de carga), y en gRPC se dice `RESOURCE_EXHAUSTED`.

```go
if l.limiter != nil && !l.limiter.Allow() { // sin esperar: Allow, no Wait
    return nil, status.Error(codes.ResourceExhausted, "rate limit exceeded")
}
select {
case l.inflight <- struct{}{}:
    defer func() { <-l.inflight }()
default: // lleno: no se encola
    return nil, status.Error(codes.ResourceExhausted, "too many requests in flight")
}
```

- `rate.Limiter` es un *token bucket*: `--rps 200` repone 200 fichas por segundo y `--burst 20` permite
  una ráfaga de 20.
- El semáforo es un canal con capacidad: si está lleno, `default` rechaza. Es un bulkhead del lado del
  servidor.

**400 retenciones, 32 a la vez**, 2026-09-29:

```text
=== con --max-inflight 8 y --rps 200
400 retenciones (Hold), 32 a la vez, en 0.06 s
  OK                   ×  20   p50    9.90 ms   máx   25.70 ms
  RESOURCE_EXHAUSTED   × 380   p50    4.15 ms   máx    8.33 ms
=== sin límites
400 retenciones (Hold), 32 a la vez, en 0.36 s
  FAILED_PRECONDITION  × 300   p50   19.07 ms   máx  186.19 ms
  OK                   × 100   p50   42.03 ms   máx  149.73 ms
```

- Con límites, la ráfaga de 20 entra y el resto se rechaza en ≈ 4 ms **sin tocar la base**: la inundación
  dura 0,06 s y a nadie le cuesta nada.
- Sin límites, las 400 llegan a PostgreSQL: la mediana sube a 19–42 ms y la cola a 186 ms. Las 100 que
  caben agotan el stock de `SKU-002` y las demás mueren por `FAILED_PRECONDITION`, pero **después** de haber
  pedido la fila bloqueada.
- Los umbrales de la corrida son deliberadamente bajos para verlos; en producción se fijan con la
  capacidad medida del servicio.

> **Veredicto:** en Go esto son unas setenta líneas sin librería de resiliencia: un `rate.Limiter` y un canal.
> Lo que cuesta no es escribirlo, es elegir los números y que el cliente trate `RESOURCE_EXHAUSTED` como
> "espera y reintenta", no como un error.

## 6. 🧱 Java: un bulkhead hacia `payments`

**Qué es.** Un límite de llamadas simultáneas a una dependencia, para que su lentitud no se lleve los
recursos que necesita el resto del servicio ([`04/03`](../04-operacion-y-resiliencia/03-resiliencia-en-la-practica.md)).
Aquí: como mucho 4 pagos en curso; el quinto se rechaza al instante con `503 PAYMENTS_UNAVAILABLE`, que
es seguro porque no se llamó.

**30 pagos a la vez con `payments` a +2 s y `orders` con 16 hilos**, sondeando la lista de pedidos.
2026-09-29:

```text
=== 16 hilos, SIN bulkhead
pagos (30 en 4.6 s):
  200 PAID                     × 30   p50 2.29 s   máx 4.37 s
sonda durante la tormenta (GET /api/v1/orders):
  01:47:31  200  0.18 s
  01:47:33  200  1.94 s
  01:47:33  200  0.06 s
  …
=== 16 hilos, bulkhead de 4
pagos (30 en 2.4 s):
  200 PAID                     ×  4   p50 2.21 s   máx 2.21 s
  503 PAYMENTS_UNAVAILABLE     × 26   p50 0.16 s   máx 0.19 s
sonda durante la tormenta (GET /api/v1/orders):
  01:47:51  200  0.22 s
  01:47:52  200  0.06 s
  …
```

- Sin bulkhead, los 30 pagos compiten por 16 hilos: algunos esperan dos rondas (4,37 s) y una lectura que
  no paga nada tarda 1,94 s en conseguir hilo. Con 200 hilos no se habría visto… hasta tener 300 pagos.
- Con el bulkhead, 26 pagos fallan rápido y **reintentables**, y la lectura no nota nada. Es el mismo
  intercambio que el pool de `06/01` resuelto al revés: se limita a propósito lo que puede acaparar.
- El diff del paso lo muestra: el bulkhead son 15 líneas en `RemotePayments`.

> **Veredicto:** el bulkhead convierte la lentitud de una dependencia en rechazos rápidos y acotados, a
> cambio de rechazar trabajo que quizá habría salido. El número (4) se deriva de cuánto tarda la
> dependencia y cuántos hilos se le quieren prestar, no se elige a ojo.

## 7. 🧱 Python: un circuit breaker asíncrono hacia el proveedor

**Qué es.** `payments` deja de llamar al PSP cuando ha fallado tres veces **seguidas**, durante 10 s.
`purgatory` cuenta fallos consecutivos (no porcentajes) y lanza `OpenedState` al entrar en el contexto:

```python
async with await request.app.state.breakers.get_breaker("psp"):
    res = await request.app.state.psp.post("/payments", ...)
    res.raise_for_status()
```

- Un timeout o un error de transporte dentro del contexto cuentan como fallo.
- Con el breaker abierto no se llama: la intención recién registrada se borra y la respuesta es
  `503 PSP_UNAVAILABLE`, que `orders` traduce a `PaymentsUnavailable`.

**Cinco pagos seguidos con el PSP a +2,5 s** (más que los 2 s de `payments`), 2026-09-29, primera versión:

```text
PAYMENT_PENDING ← pago 1: 200 en 2.137827s
PAYMENT_PENDING ← pago 2: 200 en 2.052148s
PAYMENT_PENDING ← pago 3: 200 en 2.051264s
PAYMENTS_UNAVAILABLE ← pago 4: 503 en 0.790608s
PAYMENTS_UNAVAILABLE ← pago 5: 503 en 0.018447s
--- payments
… psp breaker open: not calling for 43fafe9d-… (t05-psp-pay-4)
… psp breaker open: not calling for 43fafe9d-… (t05-psp-pay-4)
… psp breaker open: not calling for 43fafe9d-… (t05-psp-pay-4)
```

- Tres timeouts, tres `PENDING` y el breaker se abre. El pago 4 tardó 0,79 s y `payments` registra **tres**
  rechazos del mismo pago: `orders` **reintentó** una negativa explícita. Esos tres `503` abrieron además
  el breaker de `orders`, y el pago 5 falló en 18 ms sin llegar a `payments`.

Dos breakers en serie, y el de arriba reaccionando a la decisión del de abajo como si fuera una caída. La
corrección está en `orders` (línea 64): no se reintenta un `503` que dice `PSP_UNAVAILABLE`. Misma prueba:

```text
pago 1: 200 en 2.122 s PAYMENT_PENDING
pago 2: 200 en 2.042 s PAYMENT_PENDING
pago 3: 200 en 2.040 s PAYMENT_PENDING
pago 4: 503 en 0.028 s PAYMENTS_UNAVAILABLE
pago 5: 503 en 0.019 s PAYMENTS_UNAVAILABLE
--- payments
… psp breaker open: not calling for f3039dcb-… (t05-psp2-pay-4)
… psp breaker open: not calling for 3b51fc9c-… (t05-psp2-pay-5)
```

- Una llamada por pago, 28 y 19 ms, y el breaker de `orders` sigue cerrado: `payments` está sano; el que
  no responde es el PSP.

> **Veredicto:** un breaker asíncrono en Python existe, pero no en la librería que todos citan, y su estado
> vive en el proceso. Y cuando hay breakers en varias capas, cada una tiene que distinguir "mi dependencia
> se cae" de "mi dependencia me dice que la suya se cae", o se abren en cadena.

## 8. 🧨 Provocación: reintentos en dos capas

**El síntoma**: un servicio caído recibe mucha más carga de la que generan los clientes, justo cuando
intenta volver.

```text
python3 laboratorio/scripts/lab.py envoy-retries 5xx          # Envoy reintenta 5xx, hasta 2 veces
python3 laboratorio/scripts/lab.py orders --breaker-min-calls 100
```

- Con `payments` apagado, un pago devuelve `503` desde `orders`; Envoy, con `retry_on: 5xx`, lo reintenta.
- `--breaker-min-calls 100` intenta que el breaker de `orders` no se abra, para ver la multiplicación
  limpia (§10 cuenta por qué solo funciona una vez).

Un pago, 2026-09-29:

```text
pago → 503 en 1.913752s
POST /api/v1/orders/5c3e6110-…/payment → 503 1912ms upstream=…:28082 attempts=3 URX via_upstream
reintentos de orders: 6
peticiones que llegaron a orders y fallaron: 3
```

```text
cliente ──1──► Envoy ──3 intentos──► orders ──3 llamadas cada uno──► payments
                                         = 9 llamadas a un servicio caído por UN pago
```

- `attempts=3` y `URX` (*upstream retry limit exceeded*) en Envoy; 3 peticiones en `orders`, cada una con
  su llamada y 2 reintentos: **9**. Con tres capas que reintentan tres veces serían 27.
- Además, Envoy reintentó un `POST` de pago. Es seguro **aquí** porque la `Idempotency-Key` viaja de
  extremo a extremo; sin ella, sería el doble cobro de `06/03` multiplicado por tres.

**La corrección**: reintentar en una sola capa. Envoy solo reintenta lo que **no llegó** al servicio.

```text
python3 laboratorio/scripts/lab.py envoy-retries safe         # connect-failure, refused-stream; 1 reintento
```

```text
pago → 503 en 0.676912s
POST /api/v1/orders/ef72aa88-…/payment → 503 675ms upstream=…:28082 attempts=1 - via_upstream
… payments: retry 1 after 124 ms (ResourceAccessException)
… payments: retry 2 after 462 ms (ResourceAccessException)
```

- Un intento en Envoy, tres llamadas en `orders`. La capa que reintenta es la que sabe qué es seguro
  reintentar: `orders` conoce la clave y el significado de cada error; Envoy no.

> **Veredicto:** los reintentos se multiplican entre capas. Se decide **una** capa que reintenta —la que
> entiende la operación— y las demás solo reintentan lo que con certeza no llegó.

## 9. 🧨 Provocación: la readiness que mira a otro

**El síntoma**: `payments` se cae y, a los pocos segundos, **todo** `orders` devuelve `503`: también la
lista de pedidos, que no paga nada.

```text
python3 laboratorio/scripts/lab.py orders --readiness-includes-payments      # con payments apagado
```

2026-09-29:

```text
=== readiness con payments (payments caído)
liveness:  {"status":"UP"}
readiness: {"status":"DOWN"}
orders::192.168.65.254:28082::health_flags::/failed_active_hc
{"code":"SERVICE_UNAVAILABLE","detail":"UH","instance":"/api/v1/orders","status":503,"title":"Service unavailable","type":"about:blank"}
  → 503
```

- `orders` está vivo y su base funciona. Pero su readiness depende de `payments`, Envoy lo saca del
  balanceo (`/failed_active_hc`) y responde él mismo: `UH`, *no healthy upstream*. La caída de una
  dependencia se ha convertido en la caída del servicio entero.

**Con la readiness correcta** (`include: readinessState,db`), mismo escenario:

```text
=== readiness solo con lo propio (payments caído)
readiness: {"status":"UP"}
orders::192.168.65.254:28082::health_flags::healthy
GET /api/v1/orders → 200
POST /api/v1/orders → pedido 87fafb32-beb9-4d96-ac3e-13829330c804
{"…","status":503,"title":"Payments unavailable","code":"PAYMENTS_UNAVAILABLE"}  → 503
{"groups":["liveness","readiness"],"status":"DOWN"}
```

- Consultar y crear pedidos sigue funcionando; solo pagar falla, rápido y con un código que dice que es
  seguro repetir. `/actuator/health` en conjunto sigue diciendo `DOWN` —incluye el indicador de `payments`—,
  y eso está bien: es para quien diagnostica, no para el balanceador.

```text
liveness   ¿el proceso vive?                → si no, reiniciarlo
readiness  ¿puedo atender MI trabajo ahora?  → si no, sacarme del balanceo
           mi base sí · mis dependencias no: para eso están el timeout, el breaker y el 503
```

> **Veredicto:** la readiness responde por lo propio. Meter una dependencia en ella traslada su caída a
> todos los que dependen de ti, que es exactamente la cascada que el resto de los patrones intentan evitar.

## 10. 🩺 Hallazgos al correrlo

Ningún error de compilación. Tres comportamientos que hubo que entender antes de poder medir nada, y un
error de la herramienta de medición.

### Envoy no volvía a comprobar la salud durante un minuto

```text
cluster.orders.health_check.attempt: 1
cluster.orders.health_check.network_failure: 1
cluster.orders.lb_healthy_panic: 27
orders::192.168.65.254:28082::health_flags::/failed_active_hc
```

El primer chequeo ocurrió al arrancar Envoy, antes de que `orders` escuchara; falló, y el siguiente no llegó
hasta un minuto después. Mientras un clúster no ha tenido tráfico, Envoy usa `no_traffic_interval`, que por
defecto vale **60 s**, en vez de `interval`. **Corrección:** `no_traffic_interval: 2s`. **Lección:** una
instancia puede figurar como caída mucho después de haberse recuperado, y el valor por defecto que lo explica
no está en ningún ejemplo.

### …y aun así la suite pasaba: modo pánico

Con la única instancia marcada como fallida, las 27 peticiones de la suite se enrutaron igual
(`lb_healthy_panic: 27`). Cuando el porcentaje de instancias sanas baja del umbral de pánico (50 % por
defecto), Envoy **ignora** la salud y reparte entre todas. Es una protección razonable —mejor intentar que
devolver `503` a todo—, pero oculta exactamente la provocación de §9. **Corrección para el laboratorio:**
`healthy_panic_threshold: { value: 0 }`, que hace que una instancia no lista deje de recibir tráfico como
un pod que no pasa su readiness. **Lección:** el comportamiento del balanceador cuando **todo** está mal es
una decisión de diseño, y hay que conocer la que tomó por ti.

### `minimumNumberOfCalls` no puede superar la ventana

Con `--breaker-min-calls 100`, el breaker de `orders` se abrió a la décima llamada fallida. En Resilience4j,
si `minimumNumberOfCalls` es mayor que `slidingWindowSize` (10 aquí), el mínimo efectivo es la ventana.
**Lección:** los parámetros del breaker se leen juntos; desactivarlo "subiendo el mínimo" no funciona si no
se sube también la ventana.

### La inundación medía mal: un error de la herramienta

La primera versión de `bench --flood` hacía `Hold` y `Release` y contaba el par como fallo si el `Release`
era rechazado: salía "1 OK de 400" y, peor, dejaba retenciones huérfanas. **Corrección:** una muestra, una
llamada (`Hold`); la semilla limpia después. **Lección:** antes de interpretar un número raro, se desconfía
del instrumento.

## 11. 🧰 En tres plataformas

| Plataforma | Qué te da hecho | Lo que te deja a ti |
|---|---|---|
| **Java** | Resilience4j: `Bulkhead`, `Retry` con `IntervalFunction`, `CircuitBreaker`, componibles como decoradores; Actuator con grupos de liveness y readiness | El orden de los decoradores, qué se reintenta y qué cuenta como fallo, y los parámetros leídos juntos (`minimumNumberOfCalls` y la ventana) |
| **Go** | `golang.org/x/time/rate` y los canales; interceptores gRPC para aplicarlo a todo | Todo lo demás: el semáforo, el código de error, y un breaker cliente (`sony/gobreaker`, v2.4.0) si hace falta |
| **Python** | `purgatory` para `asyncio` (con estado en Redis opcional); `tenacity` para reintentos | Elegir librería sabiendo que la más citada (`pybreaker`) no es de `asyncio`, y que el estado es por proceso con varios workers |

La fila de Node/TS —`opossum` con `AbortSignal.timeout()`— está en
[`04/03`](../04-operacion-y-resiliencia/03-resiliencia-en-la-practica.md).

## 12. 🧹 Teardown

```text
Ctrl+C en las terminales de psp, inventory, payments, monolith y orders
python3 laboratorio/scripts/lab.py envoy-retries safe       # si quedó en 5xx
python3 laboratorio/scripts/lab.py down
```

- `envoy-retries safe` devuelve `envoy.yaml` a la configuración del laboratorio: la orden reescribe el
  archivo, no solo el contenedor.

## ⚠️ Errores frecuentes

| Se dice | Lo preciso |
|---|---|
| "Más reintentos, más resiliencia" | Los reintentos se multiplican entre capas: 3 × 3 = 9 llamadas a un servicio caído por un pago |
| "La readiness comprueba las dependencias" | Comprueba lo propio; una dependencia caída se gestiona con timeout, breaker y un `503`, no sacándote del balanceo |
| "El balanceador deja de mandar tráfico a las instancias caídas" | No si están **todas** caídas: Envoy entra en modo pánico y reparte entre todas |
| "El bulkhead evita la caída" | Convierte la espera en rechazos rápidos; rechaza trabajo que quizá habría salido |
| "En Python se usa `pybreaker`" | Su `call_async` es de Tornado; para `asyncio` hay que elegir otra librería o escribirlo |
| "Si el de abajo tiene breaker, el de arriba no necesita" | Necesita distinguir la negativa del breaker de abajo de una caída, o se abren en cadena |

## 📚 Para profundizar

- **Libro** — Michael T. Nygard, *Release It!*, 2.ª ed., Pragmatic Bookshelf, 2018, cap. 5, "Stability
  Patterns" (bulkheads, circuit breaker, shed load).
- **Libro** — Betsy Beyer y otros, *Site Reliability Engineering*, O'Reilly, 2016, cap. 21, "Handling
  Overload" y cap. 22, "Addressing Cascading Failures".
- **Documentación** — [Resilience4j: Bulkhead](https://resilience4j.readme.io/docs/bulkhead) ·
  [Spring Boot: endpoints de Actuator y probes](https://docs.spring.io/spring-boot/reference/actuator/endpoints.html)
  · [`golang.org/x/time/rate`](https://pkg.go.dev/golang.org/x/time/rate) · [`purgatory` en PyPI](https://pypi.org/project/purgatory/).
- **Documentación** — Envoy v1.39.1: [health checking](https://www.envoyproxy.io/docs/envoy/v1.39.1/intro/arch_overview/upstream/health_checking)
  · [umbral de pánico](https://www.envoyproxy.io/docs/envoy/v1.39.1/intro/arch_overview/upstream/load_balancing/panic_threshold)
  · [router y `retry_on`](https://www.envoyproxy.io/docs/envoy/v1.39.1/configuration/http/http_filters/router_filter).
- **Especificación** — [Kubernetes: liveness, readiness y startup probes](https://kubernetes.io/docs/concepts/workloads/pods/probes/).
- **Material de referencia** — [Google SRE Book, *Handling Overload*](https://sre.google/sre-book/handling-overload/).

## 🧠 Preguntas

1. ¿Por qué a `inventory` le toca limitar y rechazar, y no un circuit breaker? 🟢
2. ¿Qué diferencia hay entre `Allow()` y `Wait()` en un `rate.Limiter`, y por qué se usa `Allow()`? 🟢
3. ¿Qué significa `RESOURCE_EXHAUSTED` y qué debe hacer el cliente con él? 🟢
4. ¿Qué diferencia hay entre liveness y readiness? 🟡
5. ¿Por qué el bulkhead de `orders` va por fuera del reintento? 🟡
6. ¿Por qué la lista de pedidos tardó 1,94 s sin bulkhead, si no llama a `payments`? 🟡
7. ¿Qué hace el modo pánico de Envoy y por qué ocultaba la provocación de la readiness? 🟡
8. ¿Qué te da Python para un circuit breaker asíncrono, y qué pasa con su estado si arrancas varios workers? 🟡
9. Explica por qué un pago con `payments` caído generó 9 llamadas, y cuántas serían con tres capas. 🟡
10. ¿Por qué Envoy puede reintentar el `POST` de un pago sin cobrar dos veces, y por qué aun así no debería? 🟠
11. El breaker de `orders` se abrió por los `503` del breaker de `payments`. ¿Es un error? ¿Qué cambiaste? 🟠
12. ¿Cómo eliges el número del bulkhead (4) y el umbral del breaker (3 seguidos) para producción? 🟠
13. Dibuja la cadena de protección de un pago —de Envoy al PSP— con cada mecanismo, dónde está y qué devuelve cuando actúa. 🔴
14. En producción, una dependencia se cae y a los treinta segundos todo tu servicio devuelve `503` desde el gateway. Da tres hipótesis en orden de probabilidad y qué mirarías para cada una. 🔴

## 🧪 Ejercicios

1. 🟢 Repite §5 con `--max-inflight 32` y sin límite de tasa. ¿Cuántas se rechazan ahora y por qué? Pega la
   salida.
2. 🟢 **Orientación en código ajeno.** Encuentra, con ruta y línea, dónde decide `orders` que un `503` de
   `payments` no se reintenta, y dónde decide que no cuenta como caída para su breaker (si es que lo decide).
3. 🟡 Cambia `maxWaitDuration` del bulkhead a 500 ms y repite §6. ¿Qué gana y qué pierde la sonda y qué los
   pagos?
4. 🟡 Arranca `payments` con dos workers de uvicorn y repite §7. ¿Cuántos timeouts hacen falta ahora para
   que "el breaker" se abra? Explícalo con el estado por proceso.
5. 🟡 Configura el breaker de `orders` con ventana por tiempo (`TIME_BASED`, 10 s) y repite §8 con el breaker
   activo. ¿Cuántas llamadas llegan a `payments`?
6. 🟠 Haz que `orders` trate `RESOURCE_EXHAUSTED` de `inventory` como "reintenta en N ms" (un reintento con
   backoff) y no como `INVENTORY_UNAVAILABLE`. Demuéstralo con `inventory --rps 5`.
7. 🔴 Diseña la readiness de `orders` para el día en que la base de `orders` esté sana pero el pool de
   conexiones agotado. ¿Qué debe decir, y qué pasa si todas las instancias dicen lo mismo a la vez?
8. 🔥 Mueve el breaker de `payments` a Envoy (*outlier detection* en el clúster) y compara qué ve cada capa y
   qué código recibe el cliente.

---

**Anterior:** [`04` — gRPC](04-grpc.md). **Siguiente:**
[`06` — Kafka: outbox, inbox, idempotencia y DLQ](06-kafka-outbox-inbox-y-dlq.md). **Relacionado:**
[`04/03` — Resiliencia en la práctica](../04-operacion-y-resiliencia/03-resiliencia-en-la-practica.md).
