# 07 — Transacciones y concurrencia

Este taller es **opcional**, como todo el bloque `06-talleres/`, y depende de
[`06` — Modularizar](06-modularizar.md), que a su vez depende de [`04`](04-el-contrato.md); la prueba de
sobreventa la dejó escrita y desactivada [`05`](05-sqlite-miente.md), y la sección 🖥️ usa el frontend
de [`02`](02-los-errores-escondidos.md). Provoca con carga concurrente los tres defectos de
transacción del legado —el proveedor de pago lento que agota el pool y tumba el catálogo, la
sobreventa y el doble cobro— y los corrige **sin partir el monolito**. Termina cuando `lab.py storm`
muestra el catálogo sano, el stock exacto y un solo cobro por pedido, y `hurl/v1` y las dos suites
hermanas están en verde.

> Ejercita [`03/01` — Transacciones locales y límites de consistencia](../03-datos-ejecucion-y-operacion/01-transacciones-locales-y-limites-de-consistencia.md),
> [`03/02` — Concurrencia, locking e idempotencia](../03-datos-ejecucion-y-operacion/02-concurrencia-locking-e-idempotencia.md)
> y [`04/05` — Fallos parciales, retries y falsas transacciones](../04-monolito-distribuido/05-fallos-parciales-retries-y-falsas-transacciones.md).
> Las reglas del bloque están en §11 y §12 de la [guía de estilo](../prompts/guia-de-estilo-y-convenciones.md).
>
> **Vigencia:** 2026-09-29. Salidas corridas ese día en macOS con Docker Desktop, JDK 25.0.4, `hurl`
> 8.0.1 y Node 24.21.0. Las cifras de tiempo son una reproducción local, un solo nodo, sin red real:
> sirven para comparar antes y después, no como rendimiento.

**Salto rápido:** [1](#1--qué-enseña-este-taller) · [2](#2--prerrequisitos-y-versiones) · [3](#3-️-mapa-de-carpetas) · [4](#4--recorrido-de-la-base-de-código) · [5](#5--provocación-el-proveedor-lento-tumba-el-catálogo) · [6](#6--el-proveedor-fuera-de-la-transacción) · [7](#7--provocación-la-conexión-que-no-se-suelta) · [8](#8--provocación-veinte-compradores-cinco-monitores) · [9](#9--bloquear-la-fila-que-se-va-a-restar) · [10](#10--provocación-el-doble-clic) · [11](#11--idempotency-key) · [12](#12--el-resultado-incierto-es-un-estado) · [13](#13-️-en-el-frontend) · [14](#14--evidencia) · [15](#15--errores-reales-al-correrlo) · [16](#16--plataformas) · [17](#17--teardown) · [Preguntas](#-preguntas) · [Ejercicios](#-ejercicios)

---

## 1. 🎯 Qué enseña este taller

Los tres defectos tienen la misma raíz: **qué se hace dentro de una transacción y qué ve cada
transacción de las otras**.

```text
pagar (antes)                               pagar (después)
┌── transacción ─────────────────────┐       ┌─ tx 1 ─────────────────────┐
│ leer pedido                        │       │ reclamar Idempotency-Key   │
│ llamar al banco ····· 1,5 s ······ │       │ bloquear pedido → PENDING  │
│ guardar pago, cambiar estado       │       └────────────────────────────┘
└────────────────────────────────────┘       llamar al banco (sin tx, sin conexión)
conexión retenida todo el tiempo              ┌─ tx 2 ─────────────────────┐
                                              │ guardar resultado y respuesta│
                                              └────────────────────────────┘
```

Tres ideas:

- **Una transacción larga es una conexión retenida.** Con cinco conexiones en el pool, cinco pagos
  esperando al banco dejan sin base de datos a todo lo demás, incluido el catálogo, que no tiene nada
  que ver con pagos. Sacar la llamada de la transacción no basta si algo más retiene la conexión.
- **Leer, restar y escribir no es atómico.** Dos transacciones que leen el mismo stock y restan
  venden la misma unidad dos veces. La base ofrece el remedio —bloquear la fila al leerla—, pero hay
  que pedirlo.
- **Un reintento es la misma operación, no otra.** Sin una clave que lo diga, el servidor no puede
  distinguir un doble clic de dos compras. `Idempotency-Key` convierte la repetición en una respuesta
  guardada, y el resultado incierto del banco (`666.00`) en un estado consultable, no en un error.

El precio: una tabla nueva, dos bloqueos, tres transacciones donde había una y un estado intermedio
(`PAYMENT_PENDING` mientras se espera al banco). Lo que compra es que la carga concurrente deje de
cambiar el resultado.

## 2. 🧰 Prerrequisitos y versiones

Lo de los talleres anteriores; nada nuevo que instalar. Toxiproxy, que está delante del
`psp-simulator` desde el taller 01, pone la latencia (`lab.py psp-slow`), y la carga la genera
`lab.py storm` con hilos de Python, solo biblioteca estándar.

| Orden nueva | Qué hace |
|---|---|
| `lab.py storm payments --n 20` | crea 20 pedidos baratos, los paga a la vez y, mientras, lee el catálogo cada 200 ms |
| `lab.py storm orders --n 20 --sku SKU-003` | 20 clientes compran a la vez una unidad del mismo SKU; lee el stock antes y después |
| `lab.py storm double-pay [--same-key]` | un pedido y dos pagos a la vez (el doble clic); cuenta los cobros que registró el proveedor |
| `lab.py psp-charges` | los cobros del proveedor, lo que vería el cliente en su extracto |
| `lab.py api ... --key K` | la petición con `Idempotency-Key: K` |

## 3. 🗂️ Mapa de carpetas

```text
06-talleres/laboratorio/
├── contrato/
│   ├── hurl/v1/09-idempotency.hurl   nuevo: lo que el contrato exigía desde el 04
│   ├── openapi.yaml                  Idempotency-Key ya se cumple; descripción al día
│   └── seed/seed.sql                 vacía también idempotency_keys
├── legacy/src/main/java/dev/mono/legacy/
│   ├── idempotency/                  nuevo módulo: Idempotency (API) · internal/ tabla idempotency_keys
│   ├── payments/internal/PaymentService.java   tres pasos, dos transacciones cortas
│   ├── orders/OrderService.java      startPayment (bloqueo + PAYMENT_PENDING); reserva en orden de SKU
│   ├── orders/internal/OrderRepository.java    findForUpdateById, EntityGraph para las líneas
│   └── inventory/internal/ProductRepository.java  findForUpdate (SELECT ... FOR UPDATE)
├── legacy/src/main/resources/application.yaml  open-in-view: false
├── legacy/src/test/.../OrderServiceTest.java   la prueba de sobreventa vuelve a correr
├── frontend/src/api.ts               una Idempotency-Key por clic
├── scripts/lab.py                    storm, psp-charges, api --key; seed lee la semilla del estado elegido
└── estados/07/
```

## 4. 🔎 Recorrido de la base de código

Las rutas citan `laboratorio/estados/07/legacy/src/main/`.

| Pregunta | Dónde está la respuesta |
|---|---|
| ¿Cuántas conexiones tiene el pool y cuánto espera una petición por una? | `resources/application.yaml:17`–`18`: cinco y 2000 ms |
| ¿Dónde se abre ahora cada transacción del pago? | `java/dev/mono/legacy/payments/internal/PaymentService.java:48` (reclamar y validar) y `:71` (guardar el resultado); entre las dos, `:69` llama al banco |
| ¿Qué impide que dos pagos del mismo pedido lo vean `CONFIRMED` a la vez? | `java/dev/mono/legacy/orders/OrderService.java:119`: `findForUpdateById` bloquea la fila, y la línea 124 la deja en `PAYMENT_PENDING` |
| ¿Qué impide vender dos veces la misma unidad? | `java/dev/mono/legacy/inventory/internal/ProductRepository.java:15`: `@Lock(PESSIMISTIC_WRITE)` sobre la lectura del producto |
| ¿Por qué no hay interbloqueos entre pedidos con varias líneas? | `OrderService.java:53`: las filas se bloquean en orden de SKU |
| ¿Dónde se decide si una clave es nueva, repetida o reutilizada? | `java/dev/mono/legacy/idempotency/Idempotency.java:53`, con el `INSERT ... ON CONFLICT DO NOTHING` de `idempotency/internal/IdempotencyRepository.java:17` |
| ¿Por qué el controlador ya no puede leer las líneas de un pedido fuera del servicio? | `resources/application.yaml:22`, `open-in-view: false` (sección 7) |

## 5. 🧨 Provocación: el proveedor lento tumba el catálogo

Con el legado del estado 06, el proveedor tardando 1,5 s más en cada respuesta y veinte pagos a la vez:

```bash
python3 laboratorio/scripts/lab.py --estado 06 legacy --daily-close-ms 600000    # en otra terminal
python3 laboratorio/scripts/lab.py --estado 06 seed
python3 laboratorio/scripts/lab.py psp-slow --latency 1500
python3 laboratorio/scripts/lab.py storm payments --n 20
python3 laboratorio/scripts/lab.py psp-slow --off
```

- `--estado 06 seed` carga la semilla de ese estado, que no conoce la tabla de idempotencia de este.
- `psp-slow --latency 1500` añade un tóxico de latencia en el proxy `psp` de Toxiproxy: cada respuesta
  del banco llega 1,5 s tarde, por debajo del timeout de 2 s del legado.
- `storm payments --n 20` crea 20 pedidos de un cable, los paga en 20 hilos a la vez y, mientras,
  pide `GET /api/v1/products` cada 200 ms como un cliente que solo mira el catálogo.
- `psp-slow --off` quita el tóxico. Es el *teardown* de esta sección.

```text
psp: +1500 ms en cada respuesta (200)
20 pagos concurrentes en 3.3 s: HTTP 200 PAID × 10, HTTP 500 × 10
catálogo durante los pagos: 3 lecturas, 2 con 200, 1 fallidas [500]; la más lenta, 2028 ms
psp: sin latencia añadida
```

Y en el log del legado, 33 veces:

```text
HikariPool-1 - Connection is not available, request timed out after 2005ms (total=5, active=5, idle=0, waiting=5)
```

Cinco pagos tienen las cinco conexiones mientras esperan al banco; los demás esperan una conexión 2 s
y fallan. El catálogo, que no toca pagos, también: su consulta necesita una conexión como cualquier
otra. Con diez pagos no pasaba (sección 15): es la aritmética del pool, no un umbral mágico.

## 6. 🔁 El proveedor fuera de la transacción

`PaymentService.pay` deja de ser un único método `@Transactional` y pasa a tres pasos:

```java
// 1. reclamar la clave, validar y registrar el intento (transacción corta)
Object claimed = tx.execute(status -> { ... orders.startPayment(orderId, actor, operator); ... });
// 2. preguntar al proveedor, fuera de cualquier transacción
String result = authorize(p);
// 3. registrar el resultado (otra transacción corta)
return tx.execute(status -> { ... orders.recordPaymentOutcome(orderId, orderStatus); ... });
```

- `tx` es un `TransactionTemplate`: la transacción empieza y termina en el bloque, sin anotaciones ni
  proxies que decidan por ti dónde acaba.
- `orders.startPayment` bloquea la fila del pedido y lo deja en `PAYMENT_PENDING` **antes** de llamar
  al banco. Sin ese estado intermedio, al sacar la llamada de la transacción se abre una ventana: dos
  intentos podrían validar el mismo pedido `CONFIRMED` antes de que ninguno escriba.
- Si el banco no contesta, el paso 3 deja `PAYMENT_PENDING`: el resultado incierto es un estado
  (sección 12).

La misma tormenta, con este cambio:

```text
20 pagos concurrentes en 3.3 s: HTTP 200 PAID × 10, HTTP 500 × 10
catálogo durante los pagos: 3 lecturas, 2 con 200, 1 fallidas [500]; la más lenta, 2043 ms
```

**Igual que antes.** La llamada ya no está en ninguna transacción, y el pool se sigue agotando.

## 7. 🧨 Provocación: la conexión que no se suelta

La sospecha es *Open Session in View* (OSIV), que Spring Boot activa por defecto: abre la sesión de
JPA al empezar la petición y la cierra al terminar, para que un controlador pueda leer relaciones
perezosas. La sesión conserva la conexión que obtuvo su primera consulta hasta que se cierra. El paso
1 la obtiene; el banco tarda 1,5 s; la conexión sigue retenida.

Para comprobarlo sin tocar el código, el mismo jar con la propiedad en la línea de órdenes:

```bash
java -jar laboratorio/legacy/target/mono-legacy-0.9.3.jar --legacy.daily-close.every-ms=600000 --spring.jpa.open-in-view=false
```

- `--spring.jpa.open-in-view=false` sobrescribe la propiedad solo para ese arranque. Es la única vez
  que el taller arranca el legado sin `lab.py`, para aislar una sola variable.

```text
20 pagos concurrentes en 1.7 s: HTTP 200 PAID × 20
catálogo durante los pagos: 8 lecturas, 8 con 200, 0 fallidas ; la más lenta, 29 ms
```

Confirmado. Pero la misma instancia contra `hurl/v1`:

```text
error: Assert status code
   --> 04-orders.hurl:119:6
    |      ^^^ actual value is <500>
Failure 04-orders.hurl (12 request(s) in 215 ms)
...
Failure 07-notifications.hurl (7 request(s) in 193 ms)
Success 08-reports.hurl (5 request(s) in 174 ms)
```

```text
org.hibernate.LazyInitializationException: Cannot lazily initialize collection of role 'dev.mono.legacy.orders.internal.Order.lines' with key '4b715ce9-dc02-433c-81d3-cd08ac986319' (no session)
```

OSIV escondía que `OrderView.from` lee `lines` en el controlador, fuera de cualquier transacción. La
corrección no es volver a activarlo, sino cargar lo que se va a pintar dentro del servicio:

```java
@EntityGraph(attributePaths = "lines")
Optional<Order> findWithLinesById(UUID id);
```

- `@EntityGraph` hace que la consulta traiga las líneas con un `JOIN` en la misma sentencia; se aplica
  a la lectura de un pedido y a los dos listados.
- La caché del cierre diario sigue cargando pedidos **sin** líneas: su `500` a ratos es del taller 08,
  y este taller no lo arregla de paso.

Con `open-in-view: false` en `application.yaml` y las consultas con sus líneas, `hurl/v1` vuelve a
verde y la tormenta queda así:

```text
20 pagos concurrentes en 1.7 s: HTTP 200 PAID × 20
catálogo durante los pagos: 8 lecturas, 8 con 200, 0 fallidas ; la más lenta, 27 ms
```

## 8. 🧨 Provocación: veinte compradores, cinco monitores

Contra el legado del estado 06:

```bash
python3 laboratorio/scripts/lab.py --estado 06 seed
python3 laboratorio/scripts/lab.py storm orders --n 20 --sku SKU-003
```

- `storm orders` lanza 20 hilos que esperan en una barrera y compran a la vez una unidad de `SKU-003`
  (stock 5 en la semilla); cada uno con su propia `Idempotency-Key`.

```text
stock de SKU-003 antes: 5
20 pedidos concurrentes de 1 × SKU-003: HTTP 201 × 20
stock de SKU-003 después: 0
```

Veinte pedidos confirmados, cinco monitores. La prueba que el taller 05 dejó desactivada, ahora sin el
`@Disabled`:

```text
Tests run: 5, Failures: 1, Errors: 0, Skipped: 0, Time elapsed: 5.885 s <<< FAILURE! -- in dev.mono.legacy.OrderServiceTest
dev.mono.legacy.OrderServiceTest.concurrentOrdersNeverOversell -- Time elapsed: 0.048 s <<< FAILURE!
org.opentest4j.AssertionFailedError: pedidos confirmados ==> expected: <5> but was: <20>
```

## 9. 🧱 Bloquear la fila que se va a restar

```java
@Lock(LockModeType.PESSIMISTIC_WRITE)
@Query("select p from Product p where p.sku = :sku")
Optional<Product> findForUpdate(String sku);
```

- `PESSIMISTIC_WRITE` hace que la lectura bloquee la fila hasta el final de la transacción: el segundo
  comprador espera a que el primero confirme y entonces lee el stock que dejó.
- `InventoryService.reserve` usa esta lectura; el resto —comprobar, restar, guardar— no cambia.
- `OrderService.create` reserva las líneas **en orden de SKU**: dos pedidos con las mismas líneas en
  distinto orden bloquearían las filas al revés y cada uno esperaría al otro.

Con `--sql`, la sentencia que emite Hibernate para PostgreSQL:

```text
select p1_0.sku,p1_0.name,p1_0.price,p1_0.stock from products p1_0 where p1_0.sku=? for no key update of p1_0
```

`FOR NO KEY UPDATE` es el bloqueo de fila que no impide a otras transacciones comprobar claves
foráneas contra ella; basta para serializar a los compradores. La misma tormenta:

```text
stock de SKU-003 antes: 5
20 pedidos concurrentes de 1 × SKU-003: HTTP 201 × 5, HTTP 409 × 15
stock de SKU-003 después: 0
```

Cinco confirmados, quince `409 INSUFFICIENT_INVENTORY`, stock exacto. Y la prueba:

```text
Tests run: 5, Failures: 0, Errors: 0, Skipped: 0, Time elapsed: 6.486 s -- in dev.mono.legacy.OrderServiceTest
```

La alternativa optimista —una columna `@Version` y reintentar el conflicto— es mejor cuando los
choques son raros. Aquí son la norma (la última unidad de un producto popular), y el bloqueo
pesimista convierte el choque en una espera corta en lugar de un reintento.

## 10. 🧨 Provocación: el doble clic

Contra el legado del estado 06, un pedido y dos pagos simultáneos:

```bash
python3 laboratorio/scripts/lab.py --estado 06 seed
python3 laboratorio/scripts/lab.py storm double-pay
```

- `double-pay` crea un pedido de un teclado (49.90), lanza dos pagos a la vez y lee en el
  `psp-simulator` los cobros registrados para ese pedido.

```text
pago: HTTP 200 orderStatus=PAID
pago: HTTP 200 orderStatus=PAID
cobros del proveedor para el pedido b0da6c11: 2
  psp-a2b8cda1 49.90 key=None
  psp-606aea60 49.90 key=None
```

**Dos cobros** por un pedido: los dos pagos leyeron `CONFIRMED`, los dos llamaron al banco. El cliente
ve un pedido pagado y dos cargos en su extracto. Tras la sección 6, el bloqueo del pedido y el estado
`PAYMENT_PENDING` ya lo impiden:

```text
pago: HTTP 200 orderStatus=PAID
pago: HTTP 409 orderStatus=None
cobros del proveedor para el pedido 199cb4d3: 1
  psp-5b235613 49.90 key=None
```

Un cobro. Pero el segundo clic recibe un `409` que dice «el pedido no se puede pagar», y el cliente no
sabe si pagó. Y si el primer pago hubiera fallado por la red **después** de cobrar, un reintento
honesto no tendría forma de decir «soy el mismo intento».

## 11. 🧱 `Idempotency-Key`

El contrato la exige desde el taller 04 con `x-enforced-from: "06/07"`; aquí se cumple. Es un módulo
nuevo, `idempotency`, del que dependen `orders` y `payments`:

```java
@Transactional(propagation = Propagation.MANDATORY)
public Claim claim(UUID actor, String key, String fingerprint) {
    ...
    if (records.insertIfAbsent(id, actor, key, fingerprint, Instant.now()) == 1) {
        return new Fresh();
    }
    IdempotencyRecord existing = records.findById(id).orElseThrow();
    if (!existing.getFingerprint().equals(fingerprint)) {
        throw new LegacyException(ErrorCode.IDEMPOTENCY_KEY_REUSED, null);
    }
    if (existing.getResponseStatus() == null) {
        return new InProgress();
    }
    return new Replay(new Stored(existing.getResponseStatus(), existing.getResponseBody(), null, true));
}
```

- `MANDATORY` exige que ya haya una transacción: reclamar la clave y ejecutar el comando se confirman
  o se deshacen juntos.
- `insertIfAbsent` es un `INSERT ... ON CONFLICT (id) DO NOTHING`. Si otra petición con la misma clave
  está en curso, PostgreSQL hace **esperar** a esta hasta que aquella confirme o deshaga, y entonces
  inserta o no. No hay ventana entre «comprobar» e «insertar».
- `fingerprint` es método, ruta y cuerpo. La misma clave con otro cuerpo es un error del cliente
  (`422`), no una repetición.
- `Replay` devuelve la respuesta guardada con `200` e `Idempotent-Replay: true`; `InProgress` en un
  pago es el pedido en `PAYMENT_PENDING`, y responde `409`.

Para crear un pedido, todo ocurre en una transacción (`Idempotency.execute`). Para pagar, la clave se
reclama en la transacción 1, viaja al banco en la cabecera `Idempotency-Key` y la respuesta se guarda
en la transacción 2. Los controladores declaran la cabecera antes del cuerpo, para que su ausencia se
diga primero: `400 IDEMPOTENCY_KEY_REQUIRED`.

El doble clic con la misma clave:

```bash
python3 laboratorio/scripts/lab.py storm double-pay --same-key
```

```text
pago: HTTP 200 orderStatus=PAID
pago: HTTP 409 orderStatus=None
cobros del proveedor para el pedido b02eee85: 1
  psp-285492b8 49.90 key=double-click-36bda420-e27c-4f61-9729-440a600666fb
```

Los dos llegan a la vez: el segundo espera a que el primero confirme la transacción 1 y encuentra la
clave reclamada y sin respuesta, porque el banco todavía no contestó; responde `409`. Una repetición
**después** de la respuesta recibe la respuesta guardada, que es lo que afirma
`hurl/v1/09-idempotency.hurl`:

```text
# Repetir el pago con la misma clave: la misma respuesta, sin segundo cobro.
POST {{base_url}}/api/v1/orders/{{order_id}}/payment
Authorization: Bearer {{ana_token}}
Idempotency-Key: suite-09-pay-0001
HTTP 200
[Asserts]
header "Idempotent-Replay" == "true"
jsonpath "$.orderStatus" == "PAID"
```

## 12. 🔁 El resultado incierto es un estado

Tres monitores suman `666.00`: el banco cobra, pero responde en 3 s, y el legado espera 2.

```bash
python3 laboratorio/scripts/lab.py api POST /api/v1/orders '{"lines":[{"sku":"SKU-003","quantity":3}]}' --key uncertain-order-0001
python3 laboratorio/scripts/lab.py api POST /api/v1/orders/<id>/payment --key uncertain-pay-0001    # dos veces
python3 laboratorio/scripts/lab.py psp-charges
```

- `--key` añade la cabecera `Idempotency-Key`; `<id>` es el `id` que devolvió la primera orden.
- `psp-charges` lista los cobros que el banco registró.

```text
HTTP 200 · application/json · 2032 ms
  "orderStatus": "PAYMENT_PENDING",
    "status": "PENDING",
    "reference": null
HTTP 200 · application/json · 4 ms
  "orderStatus": "PAYMENT_PENDING",
    "status": "PENDING",
    "reference": null
1 cobros
  psp-929df5c9 pedido 0b6a5aca 666.00 key=uncertain-pay-0001
```

El primer intento esperó al timeout y dejó `PAYMENT_PENDING`: **no** «rechazado», porque el cobro pudo
ocurrir, y de hecho ocurrió. El segundo, con la misma clave, es una repetición: 4 ms, la misma
respuesta, ningún cobro nuevo. El banco tiene un cargo y sabe con qué clave; el legado, que no sabe el
resultado, lo dice. Resolver el `PENDING` preguntándole al banco con la misma clave es el ejercicio 7.

## 13. 🖥️ En el frontend

Sección opcional. El cliente del taller 04 no manda la clave:

```text
1. comprar SKU-002 (hay stock)
  la interfaz muestra: ❌ Idempotency-Key required (400 IDEMPOTENCY_KEY_REQUIRED)
2. comprar SKU-004 (sin stock)
  la interfaz muestra: ❌ Idempotency-Key required (400 IDEMPOTENCY_KEY_REQUIRED)
```

El contrato lo avisaba desde el 04 y el cliente no lo cumplía, porque el servidor no lo exigía. La
corrección en `api.ts` genera **una clave por intención de compra**, no por petición:

```ts
export const createOrder = (sku: string, quantity: number, key: string = crypto.randomUUID()) =>
  call<Order>("POST", "/api/v1/orders", { lines: [{ sku, quantity }] }, key);
```

- `crypto.randomUUID()` genera la clave en el navegador (y en Node); el parámetro permite reusarla si
  el mismo clic se reintenta.

`smoke.ts` gana el paso 5, el mismo clic reintentado:

```text
1. comprar SKU-002 (hay stock)
  la interfaz muestra: ✅ Pedido creado: 9b3d84d9-2723-4166-9158-1d48d6bb6981 (CONFIRMED)
...
5. comprar SKU-001 y reintentar con la misma clave
  la interfaz muestra: ✅ Pedido creado: 7001b8ad-1cd1-4b15-9061-6ab1876b2214 (CONFIRMED) | ✅ Pedido creado: 7001b8ad-1cd1-4b15-9061-6ab1876b2214 (CONFIRMED)
```

El mismo pedido dos veces. Una clave nueva en cada reintento anularía la protección: sería un pedido
nuevo por reintento.

## 14. 🧪 Evidencia

```bash
python3 laboratorio/scripts/lab.py test
python3 laboratorio/scripts/lab.py suite
python3 laboratorio/scripts/lab.py suite --dir hex
python3 laboratorio/scripts/lab.py suite --dir ms
python3 laboratorio/scripts/lab.py contract
```

```text
Running dev.mono.legacy.OrderServiceTest
Tests run: 5, Failures: 0, Errors: 0, Skipped: 0, Time elapsed: 6.582 s -- in dev.mono.legacy.OrderServiceTest
...
Tests run: 8, Failures: 0, Errors: 0, Skipped: 0
BUILD SUCCESS
```

`Skipped: 0`: la deuda que el taller 05 dejó con fecha está pagada. Las tres suites:

```text
Success 09-idempotency.hurl (13 request(s) in 121 ms)
Executed requests: 98 (19.1/s)
Succeeded files:   9 (100.0%)
```

```text
Executed files:    7
Executed requests: 84 (17.7/s)
Succeeded files:   7 (100.0%)
```

```text
Executed files:    6
Executed requests: 44 (15.6/s)
Succeeded files:   6 (100.0%)
```

`hurl/v1`, y las copias de los laboratorios hexagonal (7 archivos) y de microservicios (6), las tres
en verde: lo que el taller 04 dejó pendiente por la idempotencia queda cerrado. Y Prism, sobre la
suite entera: `violaciones de respuesta según prism: 0`. Las tres tormentas, con el código de este
taller:

```text
20 pagos concurrentes en 1.9 s: HTTP 200 PAID × 20
catálogo durante los pagos: 8 lecturas, 8 con 200, 0 fallidas ; la más lenta, 118 ms
```

```text
20 pedidos concurrentes de 1 × SKU-003: HTTP 201 × 5, HTTP 409 × 15
stock de SKU-003 después: 0
```

```text
pago: HTTP 409 orderStatus=None
pago: HTTP 200 orderStatus=PAID
cobros del proveedor para el pedido e34ff1df: 1
```

```bash
git diff --no-index --stat -M50% laboratorio/estados/06 laboratorio/estados/07
```

```text
 .../07/contrato/hurl/v1/09-idempotency.hurl        | 114 +++++++++++++++++++++
 estados/{06 => 07}/contrato/openapi.yaml           |   9 +-
 estados/{06 => 07}/contrato/seed/seed.sql          |   5 +-
 estados/{06 => 07}/frontend/scripts/smoke.ts       |   4 +
 estados/{06 => 07}/frontend/src/api.ts             |   9 +-
 .../dev/mono/legacy/idempotency/Idempotency.java   |  88 ++++++++++++++++
 ...
 .../legacy/payments/internal/PaymentService.java   | 104 ++++++++++++-------
 ...
 .../legacy/src/main/resources/application.yaml     |   3 +
 .../java/dev/mono/legacy/OrderServiceTest.java     |   3 +-
 25 files changed, 459 insertions(+), 75 deletions(-)
```

## 15. 🩺 Errores reales al correrlo

### Sacar la llamada de la transacción no soltó la conexión

**Síntoma.** Con el proveedor fuera de la transacción, la tormenta de pagos dio exactamente el mismo
resultado que antes (sección 6).

**Causa.** *Open Session in View*: la sesión de JPA vive toda la petición y conserva la conexión que
obtuvo su primera consulta. La transacción terminaba; la conexión, no.

**Lección.** Una transacción corta en el código no garantiza una conexión corta en el pool. Hay que
mirar quién abre y cierra la sesión, no solo las anotaciones. Apagar OSIV destapó un segundo defecto,
las lecturas perezosas desde el controlador, que es el precio de haberlo tenido encendido.

### La semilla no conocía la tabla nueva

**Síntoma.** La segunda corrida de `hurl/v1` falló en seis archivos con `200` donde esperaba `201`:

```text
error: Assert status code
   --> 04-orders.hurl:72:6
    |      ^^^ actual value is <200>
```

**Causa.** `seed.sql` vaciaba las tablas del legado, pero no `idempotency_keys`. Las claves de la
corrida anterior sobrevivieron, y la suite —que usa claves fijas, como `suite-04-order-0001`— recibió
repeticiones de respuestas viejas. `hurl/v1` y `hurl/hex` comparten además esas claves, porque `v1`
salió de `hex`.

**Lección.** Una tabla nueva es también un cambio en todo lo que prepara datos: semillas, limpiezas de
prueba, *scripts* de soporte. Se añadió al `TRUNCATE`. En producción la pregunta equivalente es
cuánto tiempo se guardan las claves (los contratos hermanos dicen 24 h; aquí aún no caducan).

### Diez pagos no agotaban el pool

**Síntoma.** El primer intento de la sección 5, con `--n 10`, terminó con los diez pagos en `PAID` y el
catálogo en 1526 ms, sin errores.

**Causa.** Cinco conexiones y 1,5 s por pago: diez pagos son dos tandas, y la segunda espera 1,5 s por
una conexión, menos que el `connection-timeout` de 2 s. Con veinte, la tercera tanda espera 3 s y
falla.

**Lección.** El agotamiento del pool no es gradual: todo funciona, cada vez más lento, hasta que la
espera cruza el timeout, y entonces falla todo lo que usa la base. Por eso la provocación necesita una
carga calculada, y por eso un monitor de latencia avisa antes que uno de errores.

## 16. 🧰 Plataformas

Los talleres son solo Java (§6 de la guía). OSIV es propio de Spring con JPA; el problema general
—una conexión retenida durante una espera externa— existe en cualquier plataforma con pool, y el
contraste de mecanismos de transacción, bloqueo e idempotencia está en
[`03/01`](../03-datos-ejecucion-y-operacion/01-transacciones-locales-y-limites-de-consistencia.md) y
[`03/02`](../03-datos-ejecucion-y-operacion/02-concurrencia-locking-e-idempotencia.md).

## 17. 🧹 Teardown

```bash
python3 laboratorio/scripts/lab.py psp-slow --off
python3 laboratorio/scripts/lab.py down
```

- `psp-slow --off` quita el tóxico, si quedó puesto; `lab.py seed` también los quita.
- `down` apaga PostgreSQL y Toxiproxy y borra sus volúmenes. El legado, el `psp-simulator` y el
  frontend se paran con Ctrl+C.

## ⚠️ Errores frecuentes

- «Si la llamada externa está fuera del `@Transactional`, la conexión está libre». No con OSIV
  encendido: la sesión la retiene hasta el final de la petición.
- «Más conexiones en el pool lo arreglan». Mueven el umbral; con suficientes pagos lentos se agotan
  igual, y la base sufre más conexiones abiertas.
- «`@Transactional` evita la sobreventa». Una transacción no bloquea lo que lee; hace falta un
  bloqueo, una versión o una actualización condicional.
- «La idempotencia es comprobar si la clave existe antes de ejecutar». Entre comprobar e insertar hay
  una ventana; el `INSERT ... ON CONFLICT` la cierra.
- «Una clave nueva en cada reintento». Entonces no es un reintento: es otra operación.
- «Un timeout del banco es un rechazo». Es un resultado desconocido; tratarlo como rechazo invita a
  cobrar dos veces.

## 📚 Referencias

- [PostgreSQL 17: Explicit Locking (bloqueos de fila)](https://www.postgresql.org/docs/17/explicit-locking.html)
- [PostgreSQL 17: INSERT, cláusula `ON CONFLICT`](https://www.postgresql.org/docs/17/sql-insert.html)
- [IETF: The Idempotency-Key HTTP Header Field (borrador)](https://datatracker.ietf.org/doc/draft-ietf-httpapi-idempotency-key-header/)
- [Spring Framework: Programmatic Transaction Management (`TransactionTemplate`)](https://docs.spring.io/spring-framework/reference/data-access/transaction/programmatic.html)
- [Spring Boot: Common Application Properties (`spring.jpa.open-in-view`)](https://docs.spring.io/spring-boot/appendix/application-properties/index.html)
- [HikariCP](https://github.com/brettwooldridge/HikariCP)
- [Toxiproxy](https://github.com/Shopify/toxiproxy)

## 🧠 Preguntas

1. ¿Por qué cinco pagos lentos dejan sin servicio al catálogo, que no toca pagos? 🟢
2. ¿Qué es *Open Session in View* y por qué retuvo la conexión con el proveedor ya fuera de la transacción? 🟢
3. ¿Qué hace `PESSIMISTIC_WRITE` y qué sentencia generó Hibernate? 🟢
4. ¿Qué distingue una repetición con la misma clave de una clave reutilizada con otro cuerpo? 🟢
5. ¿Por qué `startPayment` deja el pedido en `PAYMENT_PENDING` antes de llamar al banco? 🟡
6. ¿Por qué se reservan las líneas en orden de SKU y no en el del pedido? 🟡
7. ¿Qué cierra el `INSERT ... ON CONFLICT DO NOTHING` que no cerraría un `SELECT` seguido de un `INSERT`? 🟡
8. ¿Por qué `666.00` termina en `PAYMENT_PENDING` y no en `PAYMENT_REJECTED`? 🟡
9. ¿Cuándo preferirías una versión optimista (`@Version`) al bloqueo pesimista para el stock? 🟡
10. Apagar OSIV rompió cuatro archivos de la suite. ¿Por qué eso es una buena noticia? 🟠
11. El doble clic con la misma clave dio `200` y `409`, no `200` y `200`. ¿Es correcto? ¿Qué harías para que el segundo esperara la respuesta? 🟠
12. El banco cobró el pedido de `666.00` y el legado dice `PENDING`. ¿Cómo lo resolverías y quién debería hacerlo? 🟠
13. ¿Qué parte de todo esto cambiaría si `payments` estuviera en otro proceso? 🔴

## 🧪 Ejercicios

1. 🟢 **Orientación en código ajeno.** ¿En qué archivo y línea se llama al banco, y cuántas
   transacciones hay abiertas en ese momento? Responde con rutas de `laboratorio/estados/07/`.
2. 🟢 Repite la tormenta de pagos de la sección 5 con `--n 10`, `--n 15` y `--n 20` contra el estado
   06. Explica con la aritmética del pool dónde empieza a fallar.
3. 🟡 Cambia el bloqueo pesimista por `@Version` en `Product` y reintenta el conflicto. Corre la
   tormenta de pedidos y compara resultados y tiempos.
4. 🟡 **Orientación en código ajeno.** Sigue un pago desde `PaymentController` hasta la base y lista
   cada sentencia SQL con `lab.py legacy --sql`. ¿Cuántas conexiones usa y durante cuánto tiempo?
5. 🟡 Provoca un interbloqueo: quita el orden por SKU y lanza a la vez pedidos
   `[SKU-001, SKU-002]` y `[SKU-002, SKU-001]`. Pega lo que dice PostgreSQL y el legado.
6. 🟠 Haz que las claves de idempotencia caduquen a las 24 h, como en los contratos hermanos. ¿Qué
   pasa con una repetición que llega a las 25 h, y es aceptable?
7. 🟠 Escribe una tarea que resuelva los pagos `PENDING`: pregunta al banco con la misma clave y
   actualiza el pedido. ¿Qué garantiza que no cobra dos veces?
8. 🔥 Sustituye el bloqueo por una actualización condicional
   (`update ... set stock = stock - :q where sku = :sku and stock >= :q`). ¿Qué ganas y qué dato
   pierdes para el mensaje de error?

---

**Anterior:** [`06` — Modularizar](06-modularizar.md). **Siguiente:**
[`08` — Eventos, jobs y dos instancias](08-eventos-jobs-y-dos-instancias.md).
