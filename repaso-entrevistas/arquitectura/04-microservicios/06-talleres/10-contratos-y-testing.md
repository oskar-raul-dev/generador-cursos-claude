# 10 — Contratos entre servicios y testing

Este taller es **opcional dentro del bloque** y necesita [`03`](03-http-entre-servicios.md),
[`04`](04-grpc.md) y [`06`](06-kafka-outbox-inbox-y-dlq.md); aquí se corre sobre el sistema de
[`09`](09-saga-orquestada.md). Hasta ahora, la única red era la suite `hurl`: el contrato público, de
extremo a extremo, contra todo el sistema levantado. Aquí se añaden las capas que faltan de la pirámide
de [`04/07`](../04-operacion-y-resiliencia/07-testing-de-microservicios.md): **contratos de consumidor**
entre Java, Go y Python —sobre HTTP y sobre eventos—, pruebas de **componente** con Testcontainers y
unitarias. La provocación es doble: un cambio en `payments` que la suite no ve y el contrato del
consumidor sí; y su gemelo en eventos, que la suite no puede ver por construcción.

> Ejercita [`02/07` — Contratos y versionado](../02-comunicacion/07-contratos-y-versionado.md) §6 y
> [`04/07` — Testing de microservicios](../04-operacion-y-resiliencia/07-testing-de-microservicios.md).
>
> **Vigencia:** 2026-09-29. Versiones verificadas ese día en Maven Central, PyPI y `proxy.golang.org`;
> salidas corridas ese día en un Apple M1 Pro con Docker Desktop.

**Salto rápido:** [1](#1--qué-enseña-este-taller) · [2](#2--prerrequisitos-y-versiones) · [3](#3-️-mapa-de-carpetas) · [4](#4--recorrido-de-la-base-de-código) · [5](#5--qué-ve-la-suite-y-qué-no) · [6](#6--el-contrato-http-orders-consume-payments) · [7](#7--el-contrato-de-eventos-inventory-consume-orderpaid) · [8](#8--provocación-el-cambio-que-la-suite-no-ve) · [9](#9--provocación-el-evento-que-cambia-de-forma) · [10](#10--testcontainers-y-la-pirámide-medida) · [11](#11--errores-reales-al-correrlo) · [12](#12--en-tres-plataformas) · [13](#13--teardown) · [Preguntas](#-preguntas) · [Ejercicios](#-ejercicios)

---

## 1. 🎯 Qué enseña este taller

```text
                                  qué necesita levantado          cuánto tarda (medido)
e2e      hurl v1 + v2             6 contenedores + 5 procesos     3,1 s + 2,0 s  (y ≈ 1–2 min de arranque)
contrato orders → payments        payments vivo (proveedor)       1,1 s consumidor · 0,9 s verificación
         inventory → orders       nada                            0,3 s consumidor · 2,6 s verificación
componente inbox de inventory     Docker (Testcontainers)         ≈ 4–6 s, casi todo arranque del contenedor
unitaria Go y Java                nada                            milisegundos
```

Cuatro ideas:

- **La suite de extremo a extremo solo ve el contrato público.** Todo lo que pasa entre servicios —la API
  interna de `payments`, los eventos de Kafka, los casos concurrentes— le es invisible, y ahí es donde se
  rompen las cosas entre equipos.
- **Un contrato de consumidor dice lo que el consumidor lee, y nada más.** `orders` escribe qué espera de
  `payments`; `payments` lo verifica en **su** pipeline, contra su código real. Si el pacto declara más de
  lo que se usa, falla por cambios que no rompen a nadie.
- **Los eventos también tienen consumidores con expectativas.** `inventory` declara qué campos de
  `OrderPaid` lee y `orders` comprueba que el cuerpo que construye los cumple, sin Kafka.
- **Testcontainers cambia el precio de la prueba de componente.** El inbox se prueba contra el mismo
  PostgreSQL del laboratorio en unos segundos, sin entorno compartido.

El precio, en las cinco monedas: **latencia** (ninguna en producción; 13 s de pruebas por cambio frente a
un entorno entero), **consistencia** (ninguna nueva), **operación** (los pactos viven en `contrato/pacts` y
alguien tiene que mantener el orden "consumidor escribe, proveedor verifica"; en una empresa, un *Pact
Broker*), **dinero** (ninguno en el laboratorio) y **esfuerzo** (180 líneas de pruebas en Java, 181 en Go y
61 en Python, más un pequeño refactor en `OrderEvents` para poder construir el evento sin base).

## 2. 🧰 Prerrequisitos y versiones

| Herramienta | Versión fijada | Para qué |
|---|---|---|
| Todo lo de `06/09` | la de `06/09` §2 | el sistema, para la suite y para verificar `payments` |
| `spring-boot-starter-test` | la del BOM de Boot 4.1.1 | JUnit, AssertJ y los dobles de Servlet |
| `au.com.dius.pact.consumer:junit5` · `…provider:junit5` | `4.7.5` | `orders` como consumidor (HTTP) y como proveedor (mensajes) |
| `pact-python` | `3.4.1` (grupo `dev` de `payments`) | `payments` como proveedor |
| `github.com/testcontainers/testcontainers-go` (+ `modules/postgres`) | `v0.44.0` | prueba de componente del inbox |

Nada se instala en el sistema: son dependencias de cada proyecto. `pact-go` sí exigiría instalar una
biblioteca nativa en `/usr/local/lib` (su `pact-go install`); por eso el pacto de Go se escribe a mano
(§7).

```text
python3 laboratorio/scripts/lab.py test [all|inventory|orders|payments]
```

- `test` corre, en este orden, `go test ./...` en `inventory`, `mvn test` en `orders` y la verificación de
  pactos de `payments`. Primero los consumidores, que **escriben** pactos en `contrato/pacts`; después los
  proveedores, que los **verifican**.
- La verificación de `payments` necesita `payments` en marcha (`lab.py payments`, con `up` y `psp`), porque
  Pact le reproduce las peticiones de verdad. Las demás pruebas no necesitan nada levantado salvo Docker.

> **📝 Contexto:** el código tal como queda al terminar este taller está congelado en
> `laboratorio/estados/10/`, y las rutas con número de línea se refieren a esa copia. Si ya existen
> talleres posteriores, añade `--estado 10` a cada orden de `lab.py`.

## 3. 🗂️ Mapa de carpetas

```text
laboratorio/estados/10/                            (lab.py --estado 10)
├── contrato/pacts/
│   ├── orders-payments.json                       lo escribe orders (Java); lo verifica payments (Python)
│   └── inventory-orders.json                      lo escribe inventory (Go); lo verifica orders (Java)
├── orders/src/test/java/dev/ms/orders/
│   ├── contracts/PaymentsContractTest.java        orders, consumidor HTTP
│   ├── contracts/OrderEventsContractTest.java     orders, proveedor de OrderPaid
│   └── web/V1DeprecationTest.java                 unitaria
├── inventory/internal/
│   ├── consumer/contract_test.go                  inventory, consumidor de OrderPaid
│   ├── consumer/saga_test.go                      unitarias
│   └── store/store_test.go                        componente, Testcontainers
└── payments/tests/verify_pacts.py                 payments, proveedor HTTP
```

## 4. 🔎 Recorrido de la base de código

Rutas relativas a `laboratorio/estados/10/`.

**¿Qué declara `orders` de `payments`?**
`orders/src/test/java/dev/ms/orders/contracts/PaymentsContractTest.java`: dos interacciones (`@Pact`,
líneas 33 y 52), cada una con su estado de proveedor (`given`, líneas 36 y 55). En la del pago autorizado,
la respuesta se describe por su **forma**: `status` con un patrón (línea 47) y `reference` como texto
cualquiera (línea 48). En la del pago en curso, solo el código `409` (línea 66). Los tests ejecutan el
cliente real, `RemotePayments`, contra el simulador de Pact (líneas 73 y 81), sin reintentos (línea 88).

**¿Dónde se escriben los pactos?** `orders/pom.xml`, línea 120: `pact.rootDir` apunta a `contrato/pacts`, al
lado del `openapi.yaml` y del `.proto`. En Go, `inventory/internal/consumer/contract_test.go` lo escribe a
mano (línea 64), con las reglas de coincidencia en la línea 48.

**¿Cómo verifica `orders` lo que promete?** `OrderEventsContractTest.java`: `@Provider("orders")` y
`@PactFolder` (líneas 25–26) cargan solo los pactos en los que `orders` es proveedor; `@PactVerifyProvider`
(línea 46) devuelve el cuerpo que construye `OrderEvents.payload` (línea 51), el mismo método que usa el
outbox (`OrderEvents.java`, línea 68).

**¿Cómo verifica `payments`?** `payments/tests/verify_pacts.py`: se queda con los pactos cuyo proveedor es
`payments` (línea 44) y registra los estados de proveedor (línea 48), que escriben en su base: borrar la
clave del pago autorizado (línea 24) o insertar un pago `IN_PROGRESS` (línea 30).

**¿Y Testcontainers?** `inventory/internal/store/store_test.go`: `postgres.Run` con la imagen del
laboratorio (línea 53) y `CleanupContainer` (línea 56), que lo tira al terminar la prueba.

## 5. 🧱 Qué ve la suite, y qué no

La suite `hurl` es el contrato **público**: entra por Envoy y comprueba lo que un cliente ve. Es
imprescindible y tiene un punto ciego del tamaño del sistema interno:

| Lo ve | No lo ve |
|---|---|
| `POST /api/v1/orders/{id}/payment` responde `200` con `payment.reference` | La forma de `POST /payments` de `payments`, que solo usa `orders` |
| El pedido pagado reduce el stock | Que `OrderPaid` lleve `lines`: la suite no lee Kafka |
| Las tres ramas de la saga `v2` | Un pago repetido **mientras** el primero sigue en curso: la suite es secuencial |
| Que Envoy exija JWT | Qué pasa si `payments` tarda más que el timeout de `orders` |

- Todo lo de la columna derecha lo rompe un equipo al cambiar **su** servicio, y lo sufre otro equipo en
  producción. Los contratos de consumidor están para eso.

## 6. 🧱 El contrato HTTP: `orders` consume `payments`

**El consumidor.** `orders` declara dos interacciones y las ejecuta con su cliente real contra el
simulador de Pact:

```java
builder.usingLegacyDsl()
    .given("the PSP authorizes payments")
    .uponReceiving("a payment below the PSP limit")
        .method("POST").path("/payments")
        .headers(Map.of("Idempotency-Key", "pact-authorize-0001", "Content-Type", "application/json"))
        .body(new PactDslJsonBody().stringValue("orderId", ORDER.toString()).stringValue("amount", "19.80")…)
    .willRespondWith()
        .status(201)
        .body(new PactDslJsonBody()
            .stringMatcher("status", "AUTHORIZED|REJECTED|PENDING", "AUTHORIZED")
            .stringType("reference", "psp-1a2b3c4d"))
```

- `given` es el **estado de proveedor**: lo que `payments` tiene que preparar antes de reproducir la
  petición. El consumidor lo nombra; el proveedor lo implementa.
- `stringMatcher` y `stringType` describen la forma: `payments` puede devolver cualquier referencia y
  campos de más (`id`, `amount`…) sin romper el pacto, porque `orders` no los lee.
- La segunda interacción declara el pago repetido mientras el primero sigue en curso: `409`, y nada más.

```text
Tests run: 2, Failures: 0, Errors: 0, Skipped: 0, Time elapsed: 1.116 s -- in dev.ms.orders.contracts.PaymentsContractTest
```

**El proveedor.** `payments` reproduce el pacto contra su servicio en marcha, 2026-09-29:

```text
Verifying a pact between orders and payments

  a repeated payment while the first attempt is still running (0s loading, 26ms verification)
     Given a payment with key pact-in-progress-0001 is in progress
    returns a response which
      has status code 409 (OK)
      has a matching body (OK)

  a payment below the PSP limit (0s loading, 23ms verification)
     Given the PSP authorizes payments
    returns a response which
      has status code 201 (OK)
      includes headers
        "Content-Type" with value "application/json; charset=UTF-8" (OK)
      has a matching body (OK)

OK: payments cumple los pactos de sus consumidores
```

- Los estados se preparan escribiendo en la base de `payments`: el del pago autorizado **borra** la clave
  (si existiera, `payments` contestaría la repetición guardada, `200`, y el pacto pide `201`); el del pago
  en curso inserta una fila `IN_PROGRESS`.
- La primera verificación falló, y el fallo era del pacto, no de `payments` (§11).

> **Veredicto:** el pacto convierte "¿mi cambio rompe a alguien?" en una prueba de un segundo en el
> pipeline del **proveedor**. El coste es organizativo: `payments` acepta que su build falle por las
> expectativas de `orders`.

## 7. 🧱 El contrato de eventos: `inventory` consume `OrderPaid`

**El consumidor, en Go y a mano.** `pact-go` necesita instalar una biblioteca nativa en el sistema. El
pacto de mensajes es un JSON con una especificación pública (Pact v3), así que el test de Go hace las dos
cosas que haría el DSL:

```go
var ev event
if err := json.Unmarshal([]byte(orderPaidExample), &ev); err != nil { … }   // mi decodificador real
got := items(ev)                                                             // y mi transformación real
…
"matchingRules": map[string]any{"body": map[string]any{
    "$.eventId":           match(map[string]any{"match": "regex", "regex": uuidRegex}),
    "$.type":              match(map[string]any{"match": "regex", "regex": "^OrderPaid$"}),
    "$.orderId":           match(map[string]any{"match": "regex", "regex": uuidRegex}),
    "$.lines":             match(map[string]any{"match": "type", "min": 1}),
    "$.lines[*].sku":      match(map[string]any{"match": "type"}),
    "$.lines[*].quantity": match(map[string]any{"match": "integer"}),
}},
```

- El ejemplo pasa por el **mismo** `json.Unmarshal` y la misma `items()` que un mensaje real: si el pacto
  describe algo que `inventory` no sabe leer, falla aquí, en el consumidor.
- Las reglas son exactamente los cuatro campos que `inventory` lee. `total`, `customerId` y `occurredAt`
  no aparecen: `orders` puede cambiarlos sin romper a `inventory`.

**El proveedor.** `orders` construye el cuerpo con el método que usa el outbox y Pact lo compara:

```text
Verifying a pact between inventory and orders
    generates a message which
      has a matching body (OK)
      has matching metadata (OK)
Tests run: 1, Failures: 0, Errors: 0, Skipped: 0
```

- Sin Kafka ni base de datos: `OrderEvents.payload` es un método estático, extraído del outbox para esto.
  Un contrato de eventos que exigiera el broker sería una prueba de integración con otro nombre.

## 8. 🧨 Provocación: el cambio que la suite no ve

Alguien en `payments` decide que "pago en curso" es más bien un `423 Locked` que un `409 Conflict`:

```text
115c115
<                 return problem(409, "Payment in progress", "PAYMENT_IN_PROGRESS", request)
---
>                 return problem(423, "Payment in progress", "PAYMENT_IN_PROGRESS", request)
```

2026-09-29, con el sistema completo:

```text
--- suite v1
Succeeded files:   6 (100.0%)
--- suite v2
Succeeded files:   4 (100.0%)
--- pact verify
Failures:

1) Verifying a pact between orders and payments Given a payment with key pact-in-progress-0001 is in progress - a repeated payment while the first attempt is still running
    1.1) has status code 409
           expected 409 but was 423

There were 1 pact failures
```

- Las dos suites, en verde: ninguna repite un pago mientras el primero está en vuelo.
- El pacto falla en el pipeline de `payments`, antes de desplegar, y dice a quién rompe y en qué
  interacción.
- ¿Qué habría pasado en producción? `RemotePayments` traduce el `409` a `PENDING`; un `423` no lo reconoce:
  en `v1`, el doble clic del cliente acabaría en un `500`; en el orquestador, en una excepción inesperada que
  se reintenta sin mirar el plazo.

## 9. 🧨 Provocación: el evento que cambia de forma

Alguien en `orders` renombra `lines` a `items` en el evento —el ejercicio 4 de `06/06`, hecho a
propósito—:

```text
77c77
<         payload.put("lines", o.getLines().stream().map(l -> Map.of("sku", l.getSku(), "quantity", l.getQuantity())).toList());
---
>         payload.put("items", o.getLines().stream().map(l -> Map.of("sku", l.getSku(), "quantity", l.getQuantity())).toList());
```

```text
1) an OrderPaid event: generates a message which has a matching body
    1.1) body: $ Actual map is missing the following keys: lines
--- orders reconstruido con el cambio; la suite y lo que ve inventory
Succeeded files:   6 (100.0%)
{"items":{}}
2026/09/29 12:24:11 p1 o3 OrderPaid b0b20d8f → applied [trace=7102e86d]
2026/09/29 12:24:13 p2 o4 OrderPaid 2c6c39a9 → applied [trace=198b1b88]
```

- La verificación del proveedor falla con el campo exacto que falta.
- Con el cambio desplegado, la suite pasa 6/6 —no lee Kafka—, e `inventory` registra cada `OrderPaid` como
  `applied`: el lector tolerante (`06/06` E4) lee `lines` vacío y suma cero. `GET /sales` queda en `{}`
  después de una suite que pagó tres unidades. **Falla en silencio.**

> **Veredicto:** en eventos, el contrato de consumidor no es un lujo: es la **única** prueba que mira el
> mensaje. La suite de extremo a extremo no puede verlo, y el consumidor tolerante esconde la ruptura.

## 10. 🧱 Testcontainers y la pirámide, medida

La prueba de idempotencia de [`04/07` §7](../04-operacion-y-resiliencia/07-testing-de-microservicios.md#7--en-las-cuatro-plataformas),
en Go y contra PostgreSQL de verdad:

```go
pg, err := postgres.Run(ctx, "postgres:17.11-alpine",
    postgres.WithDatabase("ms_inventory"), postgres.WithUsername("ms_inventory"), postgres.WithPassword("test"),
    postgres.BasicWaitStrategies())
testcontainers.CleanupContainer(t, pg)
```

- `postgres.Run` arranca un contenedor efímero con la **misma** imagen que el laboratorio y espera a que
  acepte conexiones (`BasicWaitStrategies`).
- `CleanupContainer` lo registra para tirarlo al terminar la prueba, pase o falle.
- Después, `Migrate` aplica el esquema del servicio: la prueba usa el mismo DDL que producción.

```text
=== RUN   TestApplySaleCountsEachEventOnce
--- PASS: TestApplySaleCountsEachEventOnce (4.12s)
=== RUN   TestApplySaleWithoutInboxCountsTwice
--- PASS: TestApplySaleWithoutInboxCountsTwice (1.55s)
```

- La primera tarda más: incluye la puesta en marcha de Testcontainers en el proceso de pruebas.
- La segunda es la provocación de `06/06` convertida en prueba: sin inbox, la re-entrega cuenta dos veces.
  Una prueba que **demuestra** el fallo protege la corrección mejor que un comentario.

Todo junto, con `lab.py test`, 2026-09-29:

```text
$ go test -count=1 ./...
ok  	ms.dev/inventory/internal/consumer	0.344s
ok  	ms.dev/inventory/internal/store	3.840s
--- inventory: OK en 4.9 s
$ mvn -q test
--- orders: OK en 7.5 s
$ uv run --python 3.14 --group dev python tests/verify_pacts.py
OK: payments cumple los pactos de sus consumidores
--- payments: OK en 0.9 s
```

Y la cima, con todo levantado:

```text
Executed requests: 46 (14.9/s)
Succeeded files:   6 (100.0%)
Duration:          3078 ms (0h:0m:3s:78ms)
Executed requests: 23 (11.4/s)
Succeeded files:   4 (100.0%)
Duration:          2017 ms (0h:0m:2s:17ms)
```

- Las suites tardan 5 s, pero necesitan seis contenedores y cinco procesos arriba, y cada proceso Java
  tarda 7–10 s en arrancar. El coste de la cima no es su duración: es el entorno.
- `mvn -q test` gasta la mayor parte de sus 7,5 s en arrancar Maven y compilar; las pruebas en sí suman
  ≈ 3,9 s.

> **Veredicto:** la pirámide de `04/07`, con números del laboratorio: 13 s cubren unidades, contratos en los
> dos sentidos y el componente con base real; el extremo a extremo queda para lo que solo él ve —que el
> flujo completo funciona— y se paga con un entorno.

## 11. 🩺 Errores reales al correrlo

### Pact 4.7 exige firmas V4

```text
UnsupportedOperation Method authorizes does not conform required method signature 'public au.com.dius.pact.core.model.V4Pact xxx(PactBuilder builder)'
```

Los ejemplos de Pact que circulan devuelven `RequestResponsePact` desde un `PactDslWithProvider`. La 4.7
escribe pactos V4 por defecto y exige `V4Pact xxx(PactBuilder)`. **Corrección:**
`builder.usingLegacyDsl()…toPact(V4Pact.class)`, que conserva el DSL clásico. **Lección:** en herramientas de
contrato, la versión de la **especificación** es parte de la dependencia; consumidor y proveedor tienen que
entender la misma (`pact-python` 3 lee V4).

### El simulador esperaba un `charset` que el cliente no manda

```text
header - Expected header 'Content-Type' to have value 'application/json; charset=UTF-8' but was 'application/json'
```

Con un cuerpo JSON, Pact supone `application/json; charset=UTF-8`; el cliente del JDK manda
`application/json`. **Corrección:** declarar el `Content-Type` exacto que envía `orders`. **Lección:** el
pacto describe lo que el consumidor **hace**, no lo que el marco supone.

### El pacto exigía más de lo que `orders` lee

```text
1.1) has a matching body
       expected a body of 'application/json;charset=utf-8' but the actual content type was 'application/problem+json'
```

La primera versión del `409` declaraba un cuerpo JSON con `code`. `payments` responde
`application/problem+json`, y la verificación lo marcó como ruptura, aunque `orders` **solo mira el
código**. **Corrección:** la interacción declara el `409` y nada más. **Lección:** es la regla de `02/07`
§6 vista fallar: un pacto que declara de más acaba bloqueando cambios que no rompen a nadie, y el equipo
proveedor deja de confiar en él.

### El proveedor no reconocía el estado que pedía el consumidor

```text
ERROR au.com.dius.pact.provider.junit5.PactVerificationStateChangeExtension -- Provider state change callback failed
```

El pacto de `inventory` pide el estado "an order has been paid". Para un mensaje construido en memoria no
hay nada que preparar, pero Pact exige un `@State` con ese nombre. **Corrección:** el método vacío.
**Lección:** el nombre del estado es parte del contrato; un proveedor que no lo conoce no lo cumple.

## 12. 🧰 En tres plataformas

| Plataforma | Qué te da hecho | Lo que te deja a ti |
|---|---|---|
| **Java** | Pact JVM para consumidor y proveedor, HTTP y mensajes, con JUnit 5; `spring-boot-starter-test` con dobles de Servlet; Testcontainers integrado en Boot (`@ServiceConnection`) | Elegir la versión de especificación; extraer lo que se verifica (`OrderEvents.payload`) para no necesitar Kafka |
| **Go** | `testing` y `httptest` en la biblioteca estándar; `testcontainers-go` con módulos por base | Pact sin `pact-go` (que pide una biblioteca nativa y cgo): el pacto a mano, o instalarla en la imagen de CI |
| **Python** | `pact-python` 3 (sobre el núcleo en Rust) con estados de proveedor como funciones; `testcontainers` para Python; `pytest` | Que la verificación del proveedor necesite el servicio en marcha, con su base y su PSP |

La fila de Node/TS —Pact nativo y el aviso de que los tipos no validan en ejecución— está en
[`04/07` §7](../04-operacion-y-resiliencia/07-testing-de-microservicios.md#7--en-las-cuatro-plataformas).

## 13. 🧹 Teardown

```text
Ctrl+C en las terminales de psp, inventory, payments, monolith y orders
python3 laboratorio/scripts/lab.py down
```

- Los contenedores de Testcontainers se tiran solos al terminar cada prueba. Los pactos se quedan en
  `contrato/pacts`: son parte del contrato, como el `openapi.yaml`. El [taller 11](11-consultas-y-tiempo-real.md) empieza con `up` y
  `seed --kafka`.

## ⚠️ Errores frecuentes

| Se dice | Lo preciso |
|---|---|
| "La suite de extremo a extremo nos cubre" | Cubre el contrato público; la API interna, los eventos y la concurrencia le son invisibles |
| "El pacto describe la API del proveedor" | Describe lo que **un** consumidor lee; la API puede tener mucho más |
| "Si el pacto es estricto, mejor" | Un pacto que declara de más falla por cambios que no rompen a nadie, y deja de usarse |
| "Los eventos no necesitan contrato, el consumidor es tolerante" | El consumidor tolerante es justo el que falla en silencio cuando un campo desaparece |
| "Testcontainers es para pruebas de integración lentas" | Es para pruebas de componente con la base real; segundos, no minutos |
| "Contrato y esquema son lo mismo" | El esquema dice qué puede enviarse; el contrato de consumidor, qué se usa de verdad |

## 📚 Para profundizar

- **Libro** — Sam Newman, *Building Microservices*, 2.ª ed., O'Reilly, 2021, cap. 9, "Testing": por qué
  los contratos dirigidos por el consumidor sustituyen a buena parte de las pruebas de extremo a extremo.
- **Documentación** — [Pact](https://docs.pact.io/) ·
  [JVM, consumidor JUnit 5](https://docs.pact.io/implementation_guides/jvm/consumer/junit5) ·
  [JVM, proveedor JUnit 5](https://docs.pact.io/implementation_guides/jvm/provider/junit5) ·
  [Python](https://docs.pact.io/implementation_guides/python) ·
  [reglas de coincidencia](https://docs.pact.io/getting_started/matching) ·
  [estados de proveedor](https://docs.pact.io/getting_started/provider_states).
- **Documentación** — [Testcontainers para Go: PostgreSQL](https://golang.testcontainers.org/modules/postgres/).
- **Artículo** — Ian Robinson, ["Consumer-Driven Contracts: A Service Evolution Pattern"](https://martinfowler.com/articles/consumerDrivenContracts.html), martinfowler.com, 2006.
- **Artículo** — Ham Vocke, ["The Practical Test Pyramid"](https://martinfowler.com/articles/practical-test-pyramid.html), martinfowler.com, 2018.
- **Especificación** — [Pact v3 (mensajes)](https://github.com/pact-foundation/pact-specification/tree/version-3) ·
  [instalación de `pact-go`](https://github.com/pact-foundation/pact-go#installation).

## 🧠 Preguntas

1. ¿Qué ve la suite `hurl` y qué no puede ver por construcción? 🟢
2. ¿Qué es un estado de proveedor y quién lo implementa? 🟢
3. ¿Por qué el pacto de `orders` describe `reference` como "texto cualquiera" y no con un valor? 🟢
4. ¿En qué orden se corren consumidores y proveedores, y por qué? 🟢
5. ¿Por qué el cambio `409` → `423` no lo detectó ninguna suite? 🟡
6. ¿Qué habría pasado en producción con el `423`, en `v1` y en el orquestador? 🟡
7. ¿Por qué falló la primera verificación de `payments`, si `payments` no tenía ningún defecto? 🟡
8. ¿Por qué el pacto de eventos se escribió a mano en Go, y qué se pierde? 🟠
9. Renombrar `lines` a `items` pasó la suite y dejó `sales` vacío. ¿Por qué falló en silencio y quién lo detectó? 🟠
10. ¿Por qué `OrderEvents.payload` es un método estático separado, y qué dice eso de cómo se diseña para probar? 🟠
11. ¿Qué aporta Testcontainers en la prueba del inbox que no aporte una base en memoria o un doble? 🟠
12. La pirámide medida da 13 s para todo menos el extremo a extremo. ¿Por qué no basta y qué prueba de extremo a extremo conservarías? 🟠
13. En una empresa con 30 servicios, ¿cómo organizarías los pactos (dónde viven, quién los publica, qué bloquea un despliegue)? 🔴
14. Un equipo proveedor se queja: "vuestros pactos nos rompen el build cada semana". Diagnostica tres causas probables y qué harías con cada una. 🔴

## 🧪 Ejercicios

1. 🟢 Corre `lab.py test` y pega la salida. Luego borra `contrato/pacts/inventory-orders.json` y córrelo solo
   para `orders`: ¿qué pasa y por qué?
2. 🟢 **Orientación en código ajeno.** Encuentra, con ruta y línea, dónde decide `RemotePayments` que un `409`
   significa `PENDING`, y relaciónalo con la interacción del pacto que lo protege.
3. 🟢 Añade al pacto de `orders` la interacción del pago rechazado (`REJECTED`, importe de más de 1000,00) con
   su estado de proveedor, y verifícala.
4. 🟡 Escribe el contrato de `payments` como consumidor de `OrderCancelled` (lo que lee su consumidor de Kafka)
   y verifícalo en `orders`.
5. 🟠 Escribe en Java una prueba de componente de `SagaStore` con Testcontainers (`@ServiceConnection`):
   reclamar con *lease* desde dos hilos y comprobar que cada saga la coge uno solo.
6. 🟠 Sustituye `contrato/pacts` por un Pact Broker en Docker y haz que `payments` compruebe `can-i-deploy`
   antes de desplegar. ¿Qué pregunta nueva responde?
7. 🔴 Escribe una prueba que reproduzca la concurrencia que la suite no ve: dos `POST
   /api/v1/orders/{id}/payment` simultáneos con la misma clave y el PSP lento. ¿En qué capa de la pirámide
   la pones, y por qué?
8. 🔥 Instala `pact-go` en una imagen de CI (no en tu máquina), reescribe `contract_test.go` con su DSL de
   mensajes y compara el pacto generado con el escrito a mano.

---

**Anterior:** [`09` — Saga orquestada, comparación y autopsia](09-saga-orquestada.md). **Siguiente:**
[`11` — Consultas entre servicios y tiempo real](11-consultas-y-tiempo-real.md). **Relacionado:**
[`04/07` — Testing de microservicios](../04-operacion-y-resiliencia/07-testing-de-microservicios.md).
