# 01 — El monolito y su contrato

Este taller es **opcional**, como todo el bloque `06-talleres/`, y es el primero: no depende de
ningún otro y todos los demás dependen de él. Levanta `ms-monolith` —una tienda en Spring Boot
sobre una sola base PostgreSQL, escrita como se escribe un monolito típico y no como uno
ejemplar—, fija su contrato en un `openapi.yaml` y una suite `hurl` que será la invariante de toda la
serie, y provoca el primer fallo que suele esgrimirse para partirlo: **el proveedor de pago se pone
lento y cae el catálogo, que no tenía nada que ver**. Termina cuando la suite está en verde contra el monolito,
falla donde debe contra el mock, y la provocación se reproduce con la salida pegada.

> Ejercita [`01/01` — Qué es un microservicio](../01-fundamentos-y-descomposicion/01-que-es-un-microservicio.md),
> [`01/05` — El servicio por dentro](../01-fundamentos-y-descomposicion/05-el-servicio-por-dentro.md) y
> [`02/07` — Contratos y versionado](../02-comunicacion/07-contratos-y-versionado.md). Las reglas del
> bloque están en §13 y §14 de la [guía de estilo](../prompts/guia-de-estilo-y-convenciones.md).
>
> **Vigencia:** 2026-09-29. Imágenes y versiones verificadas ese día en Docker Hub, GitHub Releases y
> Maven Central; salidas corridas ese día en macOS con Docker Desktop.

**Salto rápido:** [1](#1--qué-enseña-este-taller) · [2](#2--prerrequisitos-y-versiones) · [3](#3-️-mapa-de-carpetas) · [4](#4--recorrido-de-la-base-de-código) · [5](#5--el-contrato-antes-que-el-código) · [6](#6--el-monolito-en-verde) · [7](#7--provocación-el-proveedor-lento-tumba-el-catálogo) · [8](#8--errores-reales-al-correrlo) · [9](#9--en-tres-plataformas) · [10](#10--teardown) · [Preguntas](#-preguntas) · [Ejercicios](#-ejercicios)

---

## 1. 🎯 Qué enseña este taller

Antes de sacar un solo servicio de un monolito hay que poder demostrar que **el cliente no se
entera** de que lo estás sacando. Eso no se demuestra con un diagrama: se demuestra con una suite que
habla con el sistema solo por su contrato y que sigue en verde cuando cambias todo lo de detrás.

```text
         hurl/v1 ──► http://localhost:28081 ──► ms-monolith ──► ms_monolith (PostgreSQL)
      (la invariante)   (06/01: el monolito)          │
                        (06/02 en adelante: Envoy)    └──► Toxiproxy :28185 ──► psp-simulator :28085
                                                            (latencia a demanda)    (el tercero lento)
```

Tres ideas, una por parte:

- **El contrato va primero.** `openapi.yaml` y la suite `hurl/v1` fijan lo que el cliente ve: rutas,
  códigos, `problem+json`, idempotencia. La suite corre contra el monolito y contra un mock, y **en
  el mock falla donde debe**: un mock valida la forma, no las reglas.
- **El monolito tiene defectos a propósito.** Un `JOIN` que cruza catálogo e inventario, una
  notificación escrita en la misma transacción que la cancelación y, sobre todo, **la llamada al
  proveedor de pago dentro de la transacción de base de datos**. No son descuidos del taller: son lo
  que encontrarás en el primer monolito que heredes, y el material de los talleres 02 a 09.
- **El dolor se mide antes de proponer nada.** Con el proveedor a 1,5 s, veinte pagos a la vez
  agotan un pool de cinco conexiones y el catálogo devuelve `500`. Agrandar el pool parece
  arreglarlo, y no lo arregla: mueve el límite.

El precio de este taller es honesto: un monolito de ~1 200 líneas de Java que nadie escribiría así a
propósito en un proyecto nuevo, y una suite de 46 peticiones que hay que mantener. Lo que compra es
que cada extracción de los talleres siguientes tiene un criterio de terminado que no es una opinión.

## 2. 🧰 Prerrequisitos y versiones

| Herramienta | Versión fijada | Para qué |
|---|---|---|
| Docker (Desktop o Engine) con Compose v2 | la del sistema | PostgreSQL, Toxiproxy y el mock |
| `postgres` | `17.11-alpine` | un servidor, una base por servicio (`ms_monolith` en este taller) |
| `ghcr.io/shopify/toxiproxy` | `2.12.0` | latencia y cortes delante de cada dependencia remota |
| `stoplight/prism` | `5.15.10` | mock generado del `openapi.yaml` |
| JDK | `25` (Temurin) | el monolito |
| Spring Boot | `4.1.1` | el monolito (Spring Framework 7.0.9 por el BOM) |
| Maven | `3.9.x` | compilar el monolito |
| `hurl` | `8.0.1` | la suite de contrato |
| Python | `3.11+`, solo biblioteca estándar | `lab.py` y `psp-simulator` |

📝 `lab.py` busca el JDK 25 en `~/.sdkman/candidates/java/25.0.4-tem` y, si lo encuentra, lo usa sin
cambiar el JDK por defecto de la máquina. Si tu JDK 25 está en otro sitio, exporta `JAVA_HOME` antes.

```text
python3 laboratorio/scripts/lab.py check
python3 laboratorio/scripts/lab.py up
python3 laboratorio/scripts/lab.py seed
```

- `check` lista las herramientas y sus versiones **sin instalar nada**; sale con error si falta
  alguna. Es lo primero que se corre en una máquina nueva.
- `up` ejecuta `docker compose up -d --wait` sobre `contrato/docker-compose.yml`: arranca
  `ms-postgres` (en el puerto `25432` del host) y `ms-toxiproxy` (API en `28474`, proxy `psp` en
  `28185`), y no devuelve el control hasta que los dos están sanos. La primera vez, PostgreSQL ejecuta
  `seed/init-databases.sql`, que crea las cuatro bases y sus cuatro usuarios.
- `seed` recrea el esquema de `ms_monolith` y carga la semilla (usuarios, cinco productos, stock),
  vacía el registro de cobros del `psp-simulator` si está corriendo y quita cualquier tóxico de
  Toxiproxy. **Se corre antes de cada suite**: la suite crea pedidos y consume stock.

Los servicios no van en el compose: corren en el host, cada uno en su terminal, para poder pararlos,
matarlos y recompilarlos sin reconstruir imágenes.

> **📝 Contexto:** el laboratorio es acumulativo: los talleres siguientes modifican este mismo
> monolito (el 02, por ejemplo, le quita los `JOIN` que se estudian aquí). El código tal como queda al
> terminar este taller está congelado en `laboratorio/estados/01/`, y todas las rutas con número de
> línea de este documento se refieren a esa copia. Si ya existen talleres posteriores, añade
> `--estado 01` a cada orden de `lab.py` (`lab.py --estado 01 up`, `lab.py --estado 01 monolith`…).

```text
python3 laboratorio/scripts/lab.py psp          # terminal 1
python3 laboratorio/scripts/lab.py monolith     # terminal 2
```

- `psp` arranca `psp-simulator` en `:28085`. Imprime una línea por petición con su
  `Idempotency-Key`: es la evidencia de cuántas veces se cobró.
- `monolith` compila con `mvn -q -DskipTests package` y arranca el jar en `:28081`. Admite
  `--port` y `--pool N`, que sobrescribe el tamaño del pool de conexiones (§7).

## 3. 🗂️ Mapa de carpetas

```text
06-talleres/laboratorio/estados/01/        (lab.py --estado 01)
├── contrato/
│   ├── docker-compose.yml            ms-postgres · ms-toxiproxy · ms-mock (perfil mock)
│   ├── openapi.yaml                  el contrato v1, con x-suite en cada operación
│   ├── hurl/v1/                      01-health … 06-cancel: la invariante de la serie
│   ├── toxiproxy/proxies.json        el proxy `psp`: :28185 → host.docker.internal:28085
│   └── seed/
│       ├── init-databases.sql        cuatro bases, cuatro usuarios, sin CONNECT para PUBLIC
│       └── monolith/                 schema.sql · seed.sql
├── psp-simulator/psp_simulator.py    el proveedor de pago, con la regla determinista
└── monolith/                         ms-monolith: Spring Boot 4.1, por capas técnicas
    └── src/main/java/dev/ms/monolith/
        ├── web/                      controladores, ApiErrors (problem+json)
        ├── service/                  AuthService, CatalogService, OrderService, PaymentService, PspClient…
        ├── repository/               Spring Data JPA; ProductRepository con los JOIN
        ├── entity/                   Order, OrderLine, Product, InventoryItem, Reservation, Payment…
        └── config/                   SecurityConfig (JWT HS256), MsProperties
```

`lab.py` vive en `laboratorio/scripts/` y es común a todos los estados.

El monolito está organizado **por capas técnicas** (`web`, `service`, `repository`, `entity`), no por
módulos de negocio. Es la forma más común de encontrarlo, y la que más cuesta partir: el código de
inventario está repartido entre tres carpetas y nada impide que `OrderService` toque sus tablas.

## 4. 🔎 Recorrido de la base de código

Antes de cambiar nada, una lectura dirigida. Es la habilidad que entrena todo el bloque: orientarse en
código que no escribiste. Cinco preguntas, cada una con su respuesta en una ruta concreta; las rutas son
relativas a `laboratorio/estados/01/monolith/`.

**¿Dónde arranca y qué configura?** `MonolithApplication.java` es un `@SpringBootApplication` con
`@ConfigurationPropertiesScan`; todo lo propio se lee de `src/main/resources/application.yaml` bajo el
prefijo `ms` (`MsProperties`). Las líneas que importan para este taller:

```yaml
spring:
  datasource:
    hikari:
      maximum-pool-size: 5          # pequeño, como tantos monolitos que nunca lo tocaron
      connection-timeout: 2000      # quien no consigue conexión en 2 s recibe un error
ms:
  psp:
    base-url: http://localhost:28185   # a través de Toxiproxy (proxy `psp`), no directo a :28085
    read-timeout-ms: 2000               # el importe 666.00 tarda 3 s: aquí se vuelve "resultado incierto"
```

- `maximum-pool-size: 5`: como mucho cinco peticiones pueden estar usando la base a la vez. El valor
  por defecto de HikariCP es diez; cinco hace visible el problema con menos carga.
- `connection-timeout: 2000`: una petición que espera una conexión más de 2 s recibe
  `SQLTransientConnectionException`. El defecto de HikariCP son 30 s, que esconden el mismo problema
  detrás de treinta segundos de espera.
- `base-url` apunta al **proxy**, no al simulador: así Toxiproxy puede meter latencia sin tocar ni el
  monolito ni el simulador.

**¿Dónde se llama al proveedor, y dentro de qué?** `service/PaymentService.java`, línea 39 y
siguientes:

```java
@Transactional
public Result pay(Actor actor, UUID orderId, String idempotencyKey) {
    ...
    var order = OrderService.visible(actor, orders.findForUpdate(orderId).orElseThrow(Errors.OrderNotFound::new));
    ...
    var result = psp.authorize(order.getId(), order.getTotalAmount(), idempotencyKey);   // línea 50
```

- `@Transactional` abre la transacción —y toma una conexión del pool— al entrar en `pay`.
- `findForUpdate` bloquea la fila del pedido (`SELECT … FOR UPDATE`): pagar y cancelar a la vez no
  pueden pisarse.
- `psp.authorize` es una llamada HTTP a un tercero **con la conexión y el bloqueo todavía tomados**.
  Mientras el proveedor piensa, la base no trabaja, pero la conexión no vuelve al pool.

**¿Tiene timeout esa llamada?** Sí: `service/PspClient.java`, línea 32, `factory.setReadTimeout(...)`
con el valor de `read-timeout-ms`. Es el detalle que hace interesante el taller: **alguien puso el
timeout**, y aun así el sistema cae. El timeout acota cuánto espera una petición; no acota cuántas
peticiones esperan a la vez reteniendo un recurso que otros necesitan.

**¿Dónde se cruzan módulos?** `repository/ProductRepository.java`, líneas 20, 26 y 34: el catálogo y
el alta de pedidos leen `products JOIN inventory` en una sola consulta, y la del alta añade
`FOR UPDATE OF i`. Hoy es cómodo; en el [taller 02](02-strangler-fig-con-envoy.md), cuando `inventory` viva en otra base, esa consulta
es lo primero que se rompe.

**¿Qué más pasa en una transacción?** `service/OrderService.java`, línea 107: la cancelación escribe
la notificación en la misma transacción que el cambio de estado. Mientras todo sea una base, eso es
atomicidad gratis; el [taller 06](06-kafka-outbox-inbox-y-dlq.md) muestra qué pasa cuando el aviso es un mensaje a otro sistema.

## 5. 🧱 El contrato antes que el código

**Qué es.** Un `openapi.yaml` (OpenAPI 3.1) con ocho operaciones —salud, login, catálogo, pedidos,
pago, cancelación, notificaciones— y una colección `hurl` que lo ejercita con los datos de la
semilla. Cada operación lleva `x-suite: v1`: la suite `v2` nace en el [taller 08](08-saga-coreografiada.md).

Cuatro convenciones del contrato, heredadas del caso de estudio y explicadas una vez:

| Convención | Ejemplo | Por qué |
|---|---|---|
| Dinero como texto decimal | `{ "amount": "49.90", "currency": "USD" }` | un `double` no representa `0.10`; el cliente no tiene que adivinar la precisión |
| Errores en `application/problem+json` | `{ "status": 409, "code": "INSUFFICIENT_INVENTORY", … }` | RFC 9457 más un `code` estable: el cliente decide por el código, no por el texto |
| `Idempotency-Key` al crear y al pagar | misma clave y mismo cuerpo → `200` con `Idempotent-Replay: true` | el reintento de un cliente no crea dos pedidos ni cobra dos veces |
| Otro cliente → `404`, no `403` | `GET /api/v1/orders/{id}` de otro cliente | no se revela que el pedido existe |

La suite es **la invariante de la serie**: seis archivos, 46 peticiones, que afirman estado, no solo
formato (el stock baja 2 al crear, vuelve al rechazar el pago, se queda al quedar el pago incierto).

```text
python3 laboratorio/scripts/lab.py suite
python3 laboratorio/scripts/lab.py suite --base-url http://localhost:24010 --no-seed
```

- `suite` siembra y luego ejecuta `hurl --test --jobs 1 --variable base_url=<url>` sobre los seis
  archivos de `contrato/hurl/v1/`, en orden. `--jobs 1` porque los archivos comparten estado: `04`
  deja el stock que `05` no mira, y en paralelo se pisarían.
- `--base-url` cambia el destino y es **lo único** que cambia entre el monolito, el mock y, desde el
  [taller 02](02-strangler-fig-con-envoy.md), Envoy.
- `--no-seed` omite la siembra: contra el mock no hay base que sembrar.

**Contra el mock.** `lab.py mock` levanta `ms-mock` (Prism en `:24010`), que responde con los
ejemplos del contrato. Salida literal, 2026-09-29:

```text
Success 01-health.hurl (1 request(s) in 9 ms)
error: Assert status code
15 | HTTP 401
   |      ^^^ actual value is <200>
Failure 02-auth.hurl (2 request(s) in 30 ms)
error: Assert failure
12 | jsonpath "$.items" count == 5
Failure 03-products.hurl (2 request(s) in 26 ms)
Failure 04-orders.hurl (2 request(s) in 65 ms)
error: Assert status code
13 | HTTP 201
   |      ^^^ actual value is <200>
Failure 05-payment.hurl (2 request(s) in 42 ms)
Failure 06-cancel.hurl (2 request(s) in 8 ms)
Executed files:    6
Succeeded files:   1 (16.7%)
```

- `02-auth` falla en la contraseña equivocada: el mock devuelve `200` con el ejemplo del token. No
  comprueba credenciales, porque eso es una regla.
- `03-products` falla al contar cinco productos: el ejemplo del contrato tiene uno. El mock no tiene
  semilla, porque eso es estado.
- `04` y `05` fallan al crear: de las dos respuestas `2xx` que declara la operación, Prism devuelve la
  menor (`200`, la de la repetición idempotente) y no `201`. Un mock elige un ejemplo; no sabe si es
  la primera vez que ve esa clave.

Que el mock falle así **es correcto**, y es lo que hay que saber decir: un mock verifica que cliente y
contrato hablan el mismo idioma, y no puede verificar que el sistema cumple las reglas. Para eso está
la suite contra el sistema real, y para lo que queda entre los dos, los contratos dirigidos por el
consumidor del [taller 10](10-contratos-y-testing.md).

> **Veredicto:** el contrato y la suite cuestan una tarde y se amortizan en la primera extracción. Sin
> ellos, "el cliente no se entera" es una promesa; con ellos, es un comando que termina en verde.

## 6. 🧱 El monolito en verde

**Cómo va.** Con `ms-postgres`, `ms-toxiproxy`, el simulador y el monolito arriba, la suite contra
`:28081`. Salida literal, 2026-09-29:

```text
Success …/hurl/v1/01-health.hurl (1 request(s) in 3 ms)
Success …/hurl/v1/02-auth.hurl (5 request(s) in 161 ms)
Success …/hurl/v1/03-products.hurl (4 request(s) in 96 ms)
Success …/hurl/v1/04-orders.hurl (16 request(s) in 229 ms)
Success …/hurl/v1/05-payment.hurl (12 request(s) in 2191 ms)
Success …/hurl/v1/06-cancel.hurl (8 request(s) in 162 ms)
--------------------------------------------------------------------------------
Executed files:    6
Executed requests: 46 (16.1/s)
Succeeded files:   6 (100.0%)
Failed files:      0 (0.0%)
Duration:          2850 ms (0h:0m:2s:850ms)
```

- Los 2 191 ms de `05-payment` son casi todos de una sola petición: el pago de `666.00`, que espera
  los 2 s del timeout de lectura antes de quedar `PAYMENT_PENDING`. El simulador cobró —el cargo está
  en su registro— y respondió a los 3 s, cuando el monolito ya no escuchaba. Eso es un **resultado
  incierto**, y por eso el pedido no pasa a rechazado: la reserva se queda (`stock == 2`) y el
  contrato lo afirma.
- La repetición del pago con la misma clave la resuelve el monolito con su tabla
  `idempotency_keys`: devuelve la respuesta guardada **sin llamar al proveedor**. La clave viaja
  además al proveedor como `Idempotency-Key`, que es la segunda red: si el monolito cayera después de
  cobrar y antes de guardar, el reintento con la misma clave no cobraría dos veces (taller 03).

> **💡 Truco:** el monolito no trae endpoint de administración para resetear datos. Todo lo que la
> suite necesita saber de partida lo pone `lab.py seed`, y por eso la suite puede afirmar valores
> absolutos (`stock == 18`) en vez de diferencias, que `hurl` no sabe calcular.

## 7. 🧨 Provocación: el proveedor lento tumba el catálogo

**El síntoma**, tal como lo vería el equipo de guardia: el proveedor de pago anuncia degradación, y
a los dos minutos **el catálogo empieza a devolver `500`**. El catálogo no llama al proveedor.

```text
python3 laboratorio/scripts/lab.py psp-slow --latency 1500
python3 laboratorio/scripts/lab.py storm --orders 20
```

- `psp-slow --latency 1500` añade un tóxico `latency` de 1 500 ms en el sentido `downstream` del
  proxy `psp` de Toxiproxy: cada respuesta del simulador llega 1,5 s tarde. Es menos que el timeout de
  lectura (2 s): **ninguna llamada expira**. `--off` lo quita; `lab.py toxics` lo muestra.
- `storm --orders 20` crea veinte pedidos de un cable (`SKU-002`, 9,90 USD, autorizable), los paga
  **a la vez** desde veinte hilos y, mientras tanto, sondea `GET /api/v1/products` cada 250 ms.

Salida literal, 2026-09-29, con el pool de cinco conexiones:

```text
psp: +1500 ms en cada respuesta (200)
psp        [::]:28185         → host.docker.internal:28085   tóxicos: latency({'latency': 1500, 'jitter': 0})
20 pedidos creados; pagando todos a la vez y sondeando el catálogo…

pagos (20 en 3.4 s):
  200 PAID                     × 10   p50 3.10 s   máx 3.11 s
  500 INTERNAL_ERROR           × 10   p50 2.03 s   máx 2.04 s

catálogo durante la tormenta (GET /api/v1/products):
  00:40:09  200  0.01 s
  00:40:11  500  2.03 s
  00:40:12  200  0.56 s
```

Y en el log del monolito, la causa:

```text
WARN … HikariPool-1 - Connection is not available, request timed out after 2003ms (total=5, active=5, idle=0, waiting=10)
```

**La cadena:**

```text
psp +1,5 s
   │
   ▼
cada pago retiene su conexión 1,5 s dentro de @Transactional (PaymentService.pay)
   │  5 conexiones, 20 pagos: 5 dentro, 15 esperando
   ▼
el que espera más de 2 s (connection-timeout) → 500
   │
   ▼
GET /products necesita una conexión como cualquiera → espera 2,03 s → 500
```

- Diez pagos salen `PAID` en dos tandas de cinco (1,5 s + 1,5 s ≈ 3,1 s). Los otros diez agotan los
  2 s de `connection-timeout` esperando conexión y reciben `500` **sin haber llegado al proveedor**.
- El catálogo no comparte código con el pago, pero **comparte el pool**. Un recurso compartido
  convierte la lentitud de una dependencia en la caída de una funcionalidad que no la usa: es el
  bulkhead que falta, de [`04/03`](../04-operacion-y-resiliencia/03-resiliencia-en-la-practica.md).

**El control.** La misma tormenta sin tóxico: veinte `PAID` en 0,3 s, el catálogo en 10 ms.

```text
pagos (20 en 0.3 s):
  200 PAID                     × 20   p50 0.07 s   máx 0.10 s
```

**La corrección falsa.** Lo primero que se propone en la sala es agrandar el pool.

```text
python3 laboratorio/scripts/lab.py monolith --pool 20
python3 laboratorio/scripts/lab.py storm --orders 20      # y luego --orders 60
```

- `--pool 20` arranca el monolito con `--spring.datasource.hikari.maximum-pool-size=20`, sin tocar
  el código.

```text
pagos (20 en 2.0 s):
  200 PAID                     × 20   p50 1.70 s   máx 1.72 s
catálogo durante la tormenta (GET /api/v1/products):
  00:40:54  200  0.02 s
  00:40:56  200  1.44 s

pagos (60 en 3.4 s):
  200 PAID                     × 40   p50 3.07 s   máx 3.12 s
  500 INTERNAL_ERROR           × 20   p50 2.04 s   máx 2.08 s
catálogo durante la tormenta (GET /api/v1/products):
  00:41:00  500  2.02 s
```

- Con veinte pedidos, todo `200`… y el catálogo tardó **1,44 s** esperando conexión: el síntoma sigue
  ahí, por debajo del umbral.
- Con sesenta, la misma caída. El límite se movió de cinco a veinte; la causa —retener una conexión
  mientras se espera a un tercero— sigue intacta. Y el pool no crece gratis: el servidor PostgreSQL
  tiene un máximo de conexiones que comparten todos los servicios, y cuatro servicios con pools de
  cincuenta ya no caben.

**La corrección de verdad** no se aplica en este taller, porque es de diseño y cambia el sistema: la
llamada al proveedor sale de la transacción. Se registra la intención de pago, se hace commit, se
llama sin conexión tomada y se registra el resultado en otra transacción. Es lo que hace el
[taller 03](03-http-entre-servicios.md) al extraer `payments`, y allí se ve lo que hay que saber decir:
**esta corrección no necesita la extracción**, se puede hacer dentro del monolito. El incidente es un
buen argumento para separar recursos, no por sí solo para partir el sistema.

> **Veredicto:** un timeout acota cuánto espera una petición, no cuántas esperan a la vez reteniendo
> un recurso compartido. Una llamada remota dentro de una transacción es un préstamo de conexión a un
> tercero que no controlas.

## 8. 🩺 Errores reales al correrlo

Dos, los dos de integración, los dos silenciosos hasta la primera petición.

### `RestClient.Builder` no existe en Boot 4 sin su starter

```text
***************************
APPLICATION FAILED TO START
***************************

Description:

Parameter 0 of constructor in dev.ms.monolith.service.PspClient required a bean of type 'org.springframework.web.client.RestClient$Builder' that could not be found.
```

Con Spring Boot 3, `spring-boot-starter-web` traía la autoconfiguración de `RestClient`. Boot 4 la
partió en módulos por tecnología: `spring-boot-starter-webmvc` sirve HTTP, pero el cliente vive en
`spring-boot-starter-restclient`. Compila —la clase `RestClient` está en `spring-web`— y falla al
arrancar. **Corrección:** el starter en el `pom.xml`. **Lección:** en Boot 4, "la clase está en el
classpath" ya no significa "está configurada"; es la misma trampa que el
[curso hexagonal](../../03-hexagonal/06-talleres/) encontró con Kafka.

### El simulador leía un cuerpo vacío: `Transfer-Encoding: chunked`

```text
00:39:34 POST /payments key=suite-v1-pay-0001 → 400
org.springframework.web.client.HttpClientErrorException$BadRequest: 400 Bad Request: "{"error": "orderId and amount (decimal string) are required"}"
```

El `RestClient` del monolito usa el cliente HTTP del JDK, que envía el cuerpo en trozos
(`Transfer-Encoding: chunked`) sin `Content-Length`. La primera versión del simulador solo miraba
`Content-Length`, leía cero bytes y respondía `400`; el monolito lo convertía en `500`. HTTP/1.1
admite las dos formas de delimitar un cuerpo
([RFC 9112 §7.1](https://www.rfc-editor.org/rfc/rfc9112.html#section-7-1)), y un servidor tiene que
aceptar las dos. **Corrección:** el simulador lee `chunked`. **Lección:** cuando dos componentes no se
entienden, la pregunta es qué dice el protocolo, no cuál de los dos "tiene razón"; y un `400` de un
tercero no debería convertirse en un `500` genérico del tuyo —el [taller 03](03-http-entre-servicios.md)
empieza a clasificar los errores del destino por lo que significan—.

## 9. 🧰 En tres plataformas

El defecto de este taller no es de Spring: es de cualquier código que retiene un recurso finito
mientras espera a la red. Lo que cambia es **qué recurso se agota y cuánto tarda en notarse**.

| Plataforma | Qué te da hecho | Lo que te deja a ti |
|---|---|---|
| **Java** | HikariCP con pool acotado (10 por defecto) y `connectionTimeout` de 30 s; `@Transactional` toma la conexión al entrar | Que la transacción no abarque una llamada remota: la anotación no avisa, y 30 s de espera por defecto esconden el problema |
| **Go** | `database/sql` con pool integrado, **sin límite** de conexiones abiertas por defecto (`SetMaxOpenConns(0)`) | Poner el límite; si no, el servicio no se queda sin conexiones: se las quita a los demás hasta agotar el `max_connections` del servidor |
| **Python** | SQLAlchemy con `QueuePool` (5 más 10 de desborde) y `pool_timeout` de 30 s; en asíncrono, el mismo pool con `asyncpg` | Lo mismo que en Java, más no mezclar un cliente HTTP bloqueante dentro de una sesión asíncrona |

La fila de Node/TS —`pg` con `Pool` de diez conexiones por defecto— está en
[`04/03`](../04-operacion-y-resiliencia/03-resiliencia-en-la-practica.md): este bloque corre en Java, Go
y Python (§13.1 de la guía).

## 10. 🧹 Teardown

```text
Ctrl+C en las terminales de `lab.py psp` y `lab.py monolith`
python3 laboratorio/scripts/lab.py down
```

- `Ctrl+C` detiene el simulador (pierde su registro de cobros, que vive en memoria) y el monolito
  (apagado ordenado de Spring Boot).
- `down` ejecuta `docker compose down -v --remove-orphans` con el perfil `mock` incluido: borra los
  contenedores **y sus volúmenes**. Nada sobrevive: el [taller 02](02-strangler-fig-con-envoy.md) empieza con `up` y `seed`.

## ⚠️ Errores frecuentes

| Se dice | Lo preciso |
|---|---|
| "La llamada tiene timeout, así que no puede colgar el servicio" | El timeout acota cada llamada; si retiene una conexión mientras espera, veinte llamadas dentro del timeout agotan el pool igual |
| "Subimos el pool y listo" | Mueve el límite y reparte el problema: el servidor de base de datos tiene un máximo que comparten todos los servicios |
| "El mock pasa la suite, el contrato está bien" | El mock valida forma; las reglas (stock, credenciales, idempotencia) solo las valida el sistema real |
| "El catálogo cayó, hay un bug en el catálogo" | Cayó porque comparte un recurso con el pago; la causa está en otra funcionalidad, y ahí hay que buscarla |
| "Si el proveedor no responde, el pago falló" | No se sabe: el simulador cobró y respondió tarde. Un resultado incierto se registra como pendiente, nunca como rechazo |
| "Un monolito por capas es fácil de partir" | Es el más difícil: el código de un módulo está repartido en todas las capas y nada impide los cruces |

## 📚 Para profundizar

- **Libro** — Sam Newman, *Monolith to Microservices*, O'Reilly, 2019, cap. 3, "Splitting the
  Monolith": por qué se empieza por el contrato y el enrutamiento antes que por el código.
- **Libro** — Chris Richardson, *Microservices Patterns*, Manning, 2018, cap. 13, "Refactoring to
  microservices".
- **Documentación** — [Spring Boot: REST clients](https://docs.spring.io/spring-boot/reference/io/rest-client.html)
  · [Spring Boot: bases de datos SQL y pool](https://docs.spring.io/spring-boot/reference/data/sql.html)
  · [Spring Framework: `@Transactional`](https://docs.spring.io/spring-framework/reference/data-access/transaction/declarative/annotations.html).
- **Documentación** — [HikariCP: About Pool Sizing](https://github.com/brettwooldridge/HikariCP/wiki/About-Pool-Sizing).
- **Documentación** — [Toxiproxy](https://github.com/Shopify/toxiproxy) · [Prism](https://docs.stoplight.io/docs/prism/674b27b261c3c-prism-overview)
  · [hurl: aserciones](https://hurl.dev/docs/asserting-response.html).
- **Especificación** — [RFC 9457, Problem Details for HTTP APIs](https://www.rfc-editor.org/rfc/rfc9457.html).

## 🧠 Preguntas

1. ¿Qué tres cosas fija el contrato de este taller además de las rutas? 🟢
2. ¿Por qué la suite se corre con `--jobs 1` y después de `lab.py seed`? 🟢
3. ¿Qué hace el tóxico `latency` de Toxiproxy y por qué `base-url` apunta al proxy y no al simulador? 🟢
4. ¿Qué significa `PAYMENT_PENDING` y por qué el pedido no pasa a rechazado? 🟡
5. La suite falla contra el mock en `02-auth` y en `03-products`. ¿Por qué eso es correcto? 🟡
6. ¿Qué diferencia hay entre el timeout de lectura del `PspClient` y el `connection-timeout` del pool, y cuál de los dos disparó los `500`? 🟡
7. ¿Por qué cae el catálogo si no llama al proveedor de pago? 🟡
8. ¿Qué te da Go por defecto en el pool de `database/sql` y en qué cambia el síntoma respecto de Java? 🟡
9. Con el pool en 20, veinte pagos salen bien. ¿Qué dato de esa corrida dice que el problema sigue ahí? 🟠
10. Propón dos correcciones al defecto de `PaymentService.pay` y di qué cuesta cada una. 🟠
11. El monolito respondía `500` cuando el simulador devolvía `400`. ¿Qué debería responder y por qué? 🟠
12. ¿Qué parte de este monolito extraerías primero, y qué argumento de este taller usarías para defenderlo? 🟠
13. Dibuja la cadena de fallo de §7 y marca dónde pondrías un bulkhead, un timeout y un circuit breaker. 🔴
14. En producción ves `HikariPool-1 - Connection is not available … (total=10, active=10, idle=0, waiting=40)`. Da tres hipótesis en orden de probabilidad y qué mirarías para cada una. 🔴

## 🧪 Ejercicios

1. 🟢 Corre `lab.py storm --orders 20` con `psp-slow --latency 500` y luego con `--latency 3000`.
   Pega las dos salidas y explica por qué con 3 000 ms los pagos que llegan al proveedor terminan
   `PAYMENT_PENDING` y no `PAID`.
2. 🟢 **Orientación en código ajeno.** Encuentra, con ruta y línea, dónde se decide que un pedido de
   otro cliente responde `404` en vez de `403`, y dónde se traduce el error a `problem+json`.
3. 🟢 Añade a `05-payment.hurl` una aserción sobre `GET /api/v1/orders/{{pending_id}}` que compruebe
   que el pago incierto queda registrado con `payment.status == "PENDING"`. Córrela y pega la salida.
4. 🟡 Consulta `/actuator/metrics/hikaricp.connections.pending` durante una tormenta y describe cómo
   se ve el agotamiento del pool en esa métrica.
5. 🟠 Baja `connection-timeout` a 250 ms y repite la tormenta. ¿Qué mejora para el catálogo, qué
   empeora para los pagos y por qué no es la corrección?
6. 🟠 Mueve la llamada al proveedor fuera de la transacción en `PaymentService` (registrar intento →
   commit → llamar → registrar resultado) y repite la tormenta. Pega la salida y explica qué ventana de
   inconsistencia has abierto a cambio.
7. 🔴 Cambia `ProductRepository.findAllWithStock` para que no haga `JOIN` con `inventory` y el stock
   salga de otra consulta. Corre la suite. ¿Qué te dice el esfuerzo de este cambio sobre el taller 02?
8. 🔥 Escribe `lab.py storm` en otra plataforma que no sea Python y compara cómo expresa cada una la
   concurrencia de veinte peticiones con un sondeo en paralelo.

---

**Anterior:** [README del bloque](README.md). **Siguiente:**
[`02` — Strangler fig con Envoy](02-strangler-fig-con-envoy.md). **Relacionado:**
[`01/03` — El camino desde el monolito](../01-fundamentos-y-descomposicion/03-el-camino-desde-el-monolito.md).
