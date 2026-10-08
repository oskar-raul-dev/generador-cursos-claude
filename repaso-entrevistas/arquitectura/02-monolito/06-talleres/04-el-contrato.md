# 04 — El contrato

Este taller es **opcional**, como todo el bloque `06-talleres/`, y depende de
[`03` — Caracterización](03-caracterizacion.md), que depende a su vez de [`01`](01-heredar-el-legado.md);
la sección 🖥️ usa el frontend de [`02`](02-los-errores-escondidos.md) y también es opcional. Escribe
el contrato de `mono-legacy` **desde lo observado** —`openapi.yaml` y una suite `hurl/v1`—, corrige
en un único manejador los errores que los talleres 02 y 03 dejaron congelados, y rompe a sabiendas a
los dos clientes que dependían de ellos: la caracterización y el frontend. Termina cuando `hurl/v1`
está en verde, Prism no encuentra ninguna respuesta que el contrato no declare, y las suites de los
laboratorios hermanos fallan solo en lo que este curso reserva para el taller 07.

> Ejercita [`02/02` — API pública del módulo y encapsulación interna](../02-modularidad-y-limites-internos/02-api-publica-del-modulo-y-encapsulacion-interna.md)
> y [`04/04` — Contratos frágiles y despliegues coordinados](../04-monolito-distribuido/04-contratos-fragiles-y-despliegues-coordinados.md).
> Las reglas del bloque están en §11 y §12 de la [guía de estilo](../prompts/guia-de-estilo-y-convenciones.md).
>
> **Vigencia:** 2026-09-29. Versiones verificadas ese día en Maven Central y Docker Hub; salidas
> corridas ese día en macOS con Docker Desktop, JDK 25.0.4, `hurl` 8.0.1 y Node 24.21.0.

**Salto rápido:** [1](#1--qué-enseña-este-taller) · [2](#2--prerrequisitos-y-versiones) · [3](#3-️-mapa-de-carpetas) · [4](#4--recorrido-de-la-base-de-código) · [5](#5--el-contrato-desde-lo-observado) · [6](#6--un-solo-traductor-de-errores-y-dto-en-el-borde) · [7](#7--lo-que-no-cabe) · [8](#8--provocación-la-caracterización-en-rojo) · [9](#9--la-suite-v1-y-el-contrato-validado) · [10](#10--las-suites-hermanas) · [11](#11-️-en-el-frontend) · [12](#12--evidencia) · [13](#13--errores-reales-al-correrlo) · [14](#14--plataformas) · [15](#15--teardown) · [Preguntas](#-preguntas) · [Ejercicios](#-ejercicios)

---

## 1. 🎯 Qué enseña este taller

Los laboratorios hexagonal y de microservicios empiezan con un `openapi.yaml`. Este no: el contrato
de `mono-legacy` hay que **reconstruirlo** desde el código, el tráfico y la caracterización, y
decidir en cada fila si se conserva lo que el legado hace o se cambia a propósito.

```text
hurl/legacy (03)  ──► lo que HAY: 200 + {"error"}, 500 + traza, entidades, double
      │  se lee fila a fila
      ▼
openapi.yaml (04) ──► lo que SE PROMETE: códigos reales, problem+json, DTO, dinero como texto
      │  se comprueba con
      ├─► hurl/v1          la suite propia, invariante de los talleres 05–10
      ├─► lab.py contract  Prism valida cada respuesta contra openapi.yaml
      └─► hurl/hex, hurl/ms  copias de las suites hermanas: el punto de enganche de la ruta completa
```

Tres ideas:

- **El contrato se escribe desde lo observado, no desde el ideal.** Cada operación sale de una ruta
  que existe; cada cambio respecto del legado es una decisión con nombre (sección 5). Un contrato que
  promete lo que el sistema no hace es otra documentación que miente.
- **Los errores se traducen en un solo sitio.** Mientras cada controlador convierta excepciones a su
  manera, el contrato de errores es la suma de accidentes. Un manejador global lo vuelve una
  decisión.
- **Romper a un cliente puede ser correcto, si es a sabiendas.** El cambio rompe `hurl/legacy` y el
  frontend; lo que lo distingue de una regresión es que se anuncia, se mide y llega con la migración
  del cliente en el mismo cambio.

El precio: 877 líneas de contrato, un paquete `dto` con trece tipos y dos clientes que migrar. Lo
que compra es que, desde aquí, cambiar el interior del legado —los talleres 05 a 10— deja de ser
cambiar su API.

## 2. 🧰 Prerrequisitos y versiones

Lo del [taller 01](01-heredar-el-legado.md#2--prerrequisitos-y-versiones) y `hurl` 8.0.1 del
[taller 03](03-caracterizacion.md#2--prerrequisitos-y-versiones). Novedades, verificadas el
2026-09-29:

| Pieza | Versión | Cómo se comprobó |
|---|---|---|
| `spring-boot-starter-validation` | gestionada por Boot 4.1.1: Hibernate Validator `9.1.3.Final`, Jakarta Validation `3.1.1` | `mvn dependency:list` sobre el `pom.xml` |
| Prism | imagen `stoplight/prism:5.15.10`, la misma que usa el laboratorio de microservicios | `docker images`; en Apple Silicon corre emulada (`linux/amd64`) |

## 3. 🗂️ Mapa de carpetas

```text
06-talleres/laboratorio/
├── contrato/
│   ├── openapi.yaml              nuevo: el contrato, escrito desde lo observado
│   ├── docker-compose.yml        + servicio prism (perfil contract, :34010)
│   └── hurl/
│       ├── legacy/               sin cambios: deja de pasar, a la vista (sección 8)
│       ├── v1/                   nuevo: la suite del contrato, 8 archivos y 85 peticiones
│       ├── hex/                  nuevo: copia de la suite v1 + v1.1 del laboratorio hexagonal
│       └── ms/                   nuevo: copia de la suite v1 del laboratorio de microservicios
├── legacy/src/main/java/dev/mono/legacy/
│   ├── controller/ApiErrorHandler.java   nuevo: el único traductor de errores
│   ├── dto/                      nuevo: lo que la API publica, en lugar de las entidades
│   ├── util/ErrorCode.java       nuevo: los códigos estables del contrato
│   └── util/Json.java            borrado: era la "API de errores" del legado
├── frontend/src/                 api.ts, view.ts y App.tsx migrados al contrato
├── scripts/lab.py                + contract; suite corre hurl/v1 por defecto y acepta --all-errors
└── estados/04/                   el laboratorio al cerrar este taller
```

## 4. 🔎 Recorrido de la base de código

Antes de escribir el contrato, las preguntas que hay que poder contestar con ruta y línea. Las rutas
citan `laboratorio/estados/04/`.

| Pregunta | Dónde está la respuesta |
|---|---|
| ¿Dónde se convierte una excepción en respuesta HTTP? | `legacy/src/main/java/dev/mono/legacy/controller/ApiErrorHandler.java:30`, y solo ahí; antes, un `catch` por método de cada controlador |
| ¿Qué pasa con un fallo que nadie esperaba? | la misma clase, línea 67: la traza va al log (línea 70) y al cliente, `INTERNAL_ERROR` sin detalle |
| ¿Quién responde 401 y 403, que no pasan por los controladores? | `legacy/src/main/java/dev/mono/legacy/config/SecurityConfig.java:66` y `:74`, en el filtro de seguridad |
| ¿Cómo distingue un token revocado de uno ausente? | `SecurityConfig.java:94`: busca en la causa la `JwtValidationException` con el código `token_revoked` |
| ¿Dónde se decide que el pedido de otro cliente «no existe»? | `legacy/src/main/java/dev/mono/legacy/controller/OrderController.java:41`, `visible()` |
| ¿Sigue el dinero en `double`? | sí: `dto/Money.java:10` lo formatea a dos cifras al salir; el taller 05 cambia el tipo |
| ¿Dónde vive todavía la regla «un pedido pagado no se cancela»? | `OrderController.java:76`, en el controlador; el taller 06 la mueve |

## 5. 🧱 El contrato desde lo observado

El contrato se escribió leyendo `hurl/legacy` archivo por archivo y decidiendo, fila por fila, qué
se conserva. Una muestra de las decisiones:

| Lo que hacía el legado (03) | Lo que dice `openapi.yaml` (04) | Por qué |
|---|---|---|
| `200` con `{"error": "Not enough stock for SKU-004"}` | `409` `INSUFFICIENT_INVENTORY`, `detail` con la cantidad y `errors[].field = lines[1].quantity` | el estado dice qué pasó; el `code`, qué hacer; el campo, dónde |
| `500` con `NullPointerException` para `SKU-999` | `404` `PRODUCT_NOT_FOUND` | no era un fallo del servidor: el cliente pidió algo que no existe |
| login: «User not found» o «Wrong password» | `401` `INVALID_CREDENTIALS`, idéntico en los dos casos | no revelar qué correos existen |
| login devuelve `user` con `passwordHash` | `accessToken`, `tokenType`, `expiresIn` y nada más | lo que se serializa se publica |
| `GET /products` devuelve una lista | página `{ items, nextCursor }` con `limit` y cursor opaco | un catálogo crece; cambiar de lista a página después rompe a todos |
| `"price": 49.9` y `"total": 29.700000000000003` | `{ "amount": "49.90", "currency": "USD" }` | el dinero no viaja como flotante |
| alta de un SKU existente: lo pisa | `409` `PRODUCT_ALREADY_EXISTS` | pisar el catálogo por un reintento es pérdida de datos |
| un pedido `PAYMENT_REJECTED` no se puede volver a pagar | sí se puede, con otra clave | así lo dicen los dos contratos hermanos |
| sin token: `200` `{"error":"Not logged in"}` | `401` `UNAUTHENTICATED`; revocado: `401` `TOKEN_REVOKED` | el cliente distingue «entra» de «vuelve a entrar» |

El fragmento que gobierna a todos los errores es el esquema `Problem`:

```yaml
Problem:
  description: RFC 9457 más `code`, un identificador estable para máquinas, y `errors` opcional.
  type: object
  required: [title, status, code]
  properties:
    type: { type: string, format: uri, default: about:blank }
    title: { type: string }
    status: { type: integer }
    detail: { type: string }
    instance: { type: string }
    code:
      type: string
      enum: [VALIDATION_FAILED, INVALID_CREDENTIALS, UNAUTHENTICATED, TOKEN_REVOKED, FORBIDDEN, ...]
```

- `title`, `status`, `detail` e `instance` son los campos de RFC 9457; `type` ausente equivale a
  `about:blank`.
- `code` es la extensión propia: el cliente decide por él, porque `title` y `detail` son texto
  humano y pueden cambiar sin romper el contrato.
- La enumeración cierra el conjunto: un código nuevo es un cambio de contrato, no un detalle de
  implementación. El legado añade uno que los hermanos no tienen, `BATCH_NOT_FOUND`.

## 6. 🔀 Un solo traductor de errores y DTO en el borde

Dos cambios en el legado sostienen el contrato, y los dos son de borde: ninguna regla de negocio se
mueve (eso es del taller 06).

**El manejador global.** Los servicios siguen lanzando `LegacyException`, ahora con un `ErrorCode`;
los controladores ya no la atrapan. La traduce una sola clase:

```java
@ExceptionHandler(LegacyException.class)
ResponseEntity<ProblemDetail> business(LegacyException e, HttpServletRequest req) {
    var problem = problem(e.code(), e.getMessage(), req);
    if (!e.errors().isEmpty()) {
        problem.setProperty("errors", e.errors());
    }
    return respond(problem);
}

@ExceptionHandler(Exception.class)
ResponseEntity<ProblemDetail> unexpected(Exception e, HttpServletRequest req) {
    // la causa, entera, al log; al cliente, un código y nada de clases, SQL ni trazas
    log.error("unexpected error on {} {}", req.getMethod(), req.getRequestURI(), e);
    return respond(problem(ErrorCode.INTERNAL_ERROR, null, req));
}
```

- `@ExceptionHandler` registra el método para esa clase de excepción en cualquier controlador;
  `@RestControllerAdvice`, en la clase, lo hace global.
- `ProblemDetail` es el tipo de Spring para RFC 9457; `setProperty` añade `code` y `errors` como
  campos de primer nivel, y `respond` fija `application/problem+json`.
- El segundo método es la red: cualquier excepción que no sea de negocio termina en `500` sin
  traza. Por eso `application.yaml` pasa `include-stacktrace` e `include-message` a `never`.

Un `401` o un `403` no llegan a los controladores: los decide el filtro de seguridad, así que
`SecurityConfig` escribe su propio `problem+json` con el mismo formato. Es la segunda y última
excepción a «un solo sitio», y está al lado de la configuración que la produce.

**DTO en lugar de entidades.** Cada respuesta es un `record` del paquete `dto`, construido desde la
entidad con un método `from`:

```java
public record OrderView(UUID id, UUID customerId, String status, List<Line> lines, Money total,
                        PaymentView payment, Instant createdAt) { ... }
```

- El `record` enumera lo que se publica: ni `passwordHash`, ni el proxy de Hibernate, ni las
  colecciones perezosas; `customerId` en lugar del cliente entero.
- `Money.of(double, currency)` formatea a dos cifras al salir. El legado sigue calculando en
  `double`: el contrato **esconde** el `29.700000000000003`, no lo arregla. El arreglo es del taller
  05, y el contrato no tendrá que cambiar cuando llegue.

La validación de forma usa Bean Validation sobre los DTO de entrada (`@NotEmpty`, `@Pattern`,
`@Min`) y la anotación `@Valid` en el parámetro del controlador; un fallo produce
`MethodArgumentNotValidException`, que el manejador convierte en `400` con `errors[].field`.

## 7. 🔀 Lo que no cabe

La guía pide que, al cerrar este taller, las suites `v1` de los laboratorios hexagonal y de
microservicios pasen contra `mono-legacy`. Se copiaron el 2026-09-29 a `contrato/hurl/hex` y
`contrato/hurl/ms`, con su origen y la fecha en la cabecera de cada archivo. Al copiarlas aparecieron
tres cosas que no caben, y ninguna se fuerza:

| Qué | Decisión |
|---|---|
| Los usuarios semilla de las suites son `@hex.local` y `@ms.local`, y la suite afirma el `customerId` `11111111-…` | **se sustituye el dominio** al copiar (`@mono.local`), declarado en la cabecera. Añadir usuarios a la semilla no sirve: dos correos no pueden compartir el mismo `id` |
| Microservicios libera el stock cuando el pago se rechaza, y deja a un `customer` leer sus notificaciones; hexagonal mantiene la reserva del pedido rechazado (se puede volver a pagar o cancelar) y responde `403` a un `customer` en `/notifications` | los dos contratos se contradicen. El monolito sigue al hexagonal, que la guía declara superconjunto; los dos bloques de `ms` se **comentan** con la marca `NO CABE (06/04 §7)`, sin borrarlos |
| Las dos suites exigen `Idempotency-Key` (400 sin ella, repetición con `Idempotent-Replay`, `422` con otro cuerpo) | la idempotencia es un pecado cuyo dueño es el taller 07 (`prompt-base.md` §9). El contrato la declara obligatoria con `x-enforced-from: "06/07"`; el legado la acepta y la ignora hasta entonces. `hurl/v1` envía la cabecera y no afirma nada sobre ella; `hurl/hex` y `hurl/ms` fallan **solo** ahí (sección 10) |

La tercera fila es la más incómoda: durante tres talleres el contrato promete algo que la
implementación no cumple. Se acepta porque está escrito —en el contrato, en la suite y aquí— y
porque la alternativa, arreglar la idempotencia ahora «por comodidad», rompe la regla 6 del plan: el
legado no se embellece fuera del taller dueño de cada pecado.

## 8. 🧨 Provocación: la caracterización en rojo

Con el legado de este taller arrancado, la suite que el taller 03 dejó en verde:

```bash
python3 laboratorio/scripts/lab.py legacy --daily-close-ms 600000    # en otra terminal
python3 laboratorio/scripts/lab.py suite --dir legacy
```

- `suite --dir legacy` siembra y corre `contrato/hurl/legacy`. Desde este taller, sin `--dir`,
  `suite` corre `hurl/v1`.

```text
Success 01-health.hurl (1 request(s) in 1 ms)
error: Assert failure
  --> 02-auth.hurl:12:0
   |
   | POST {{base_url}}/api/v1/auth/login
   | ...
12 | jsonpath "$.user.email" == "ana@mono.local"
   |   actual:   none
   |   expected: string <ana@mono.local>
   |
...
Failure 02-auth.hurl (1 request(s) in 77 ms)
Failure 03-products.hurl (3 request(s) in 162 ms)
Failure 04-orders.hurl (2 request(s) in 90 ms)
Failure 05-payment.hurl (2 request(s) in 86 ms)
Failure 06-cancel.hurl (3 request(s) in 164 ms)
Failure 07-reports.hurl (3 request(s) in 159 ms)
--------------------------------------------------------------------------------
Executed files:    7
Executed requests: 15 (20.1/s)
Succeeded files:   1 (14.3%)
Failed files:      6 (85.7%)
Duration:          747 ms (0h:0m:0s:747ms)
```

Seis de siete archivos en rojo, y es el resultado **esperado**: la primera aserción que cae es la que
congelaba el objeto `user` con su hash, el primer defecto que el contrato elimina. La caracterización
cumplió su función —ningún cambio visible pasó sin que alguien lo mirara— y desde aquí se jubila:
`hurl/v1` la reemplaza como invariante. No se borra: queda en `contrato/hurl/legacy` como registro de
lo que fue la API, útil para el ejercicio de migración de clientes.

## 9. 🧪 La suite v1 y el contrato validado

### Antes: el legado del taller 03 contra el contrato nuevo

`lab.py contract` corre `hurl/v1` a través de Prism en modo *proxy*: Prism reenvía cada petición al
legado y valida la respuesta contra `openapi.yaml`. Contra el legado del estado 03 —el que acaba de
caracterizarse—:

```bash
python3 laboratorio/scripts/lab.py --estado 03 legacy --daily-close-ms 600000    # en otra terminal
python3 laboratorio/scripts/lab.py contract
```

- `--estado 03` arranca el legado tal como quedó en el taller 03.
- `contract` levanta el servicio `prism` del perfil `contract` en `:34010`, corre `hurl/v1` contra él,
  cuenta en los logs de Prism las líneas `Violation: response` y apaga Prism. Las violaciones de
  **petición** se ignoran: la suite manda cuerpos inválidos a propósito.

```text
Failure 02-auth.hurl (1 request(s) in 431 ms)
Failure 03-products.hurl (3 request(s) in 269 ms)
...
violaciones de respuesta según prism: 22
  response.body Response body must be object
  response.body Response body must have required property 'id'
  response.body Response body must have required property 'customerId'
  ...
  response.body.lines.0.unitPrice Response body property lines.0.unitPrice must be object
  response.body.total Response body property total must be object
  response Unable to match the returned status code with those defined in the document: 201,400,401,403,409
  ...
  response.body Response body must have required property 'items'
```

Veintidós respuestas que el contrato no admite, en solo 19 peticiones (`hurl` detiene cada archivo
en su primer fallo). Es el tamaño de la distancia entre lo observado y lo prometido.

### Después: el legado de este taller

```bash
python3 laboratorio/scripts/lab.py legacy --daily-close-ms 600000    # en otra terminal, tras parar el anterior
python3 laboratorio/scripts/lab.py suite
python3 laboratorio/scripts/lab.py contract
```

```text
Success 01-health.hurl (1 request(s) in 2 ms)
Success 02-auth.hurl (9 request(s) in 168 ms)
Success 03-products.hurl (12 request(s) in 202 ms)
Success 04-orders.hurl (18 request(s) in 308 ms)
Success 05-payment.hurl (12 request(s) in 2186 ms)
Success 06-cancel.hurl (19 request(s) in 271 ms)
Success 07-notifications.hurl (9 request(s) in 1698 ms)
Success 08-reports.hurl (5 request(s) in 181 ms)
--------------------------------------------------------------------------------
Executed files:    8
Executed requests: 85 (15.5/s)
Succeeded files:   8 (100.0%)
Failed files:      0 (0.0%)
Duration:          5467 ms (0h:0m:5s:467ms)
```

Y a través de Prism, la misma suite en verde y la última línea que importa:

```text
Executed requests: 85 (15.1/s)
Succeeded files:   8 (100.0%)
violaciones de respuesta según prism: 0
```

`hurl/v1` salió de la suite del laboratorio hexagonal: mismos usuarios con el dominio `@mono.local`,
sin las aserciones de idempotencia (sección 7), con `08-reports.hurl` para las dos rutas que solo
tiene el legado y con un pedido de tres cables que afirma `"29.70"` donde `hurl/legacy` afirmaba
`29.700000000000003`. Desde aquí es la invariante: **tiene que seguir en verde después de cada
taller**, que es lo que permite reorganizar el interior sin tocar a nadie.

## 10. 🧪 Las suites hermanas

```bash
python3 laboratorio/scripts/lab.py suite --dir hex
python3 laboratorio/scripts/lab.py suite --dir ms
```

- `--dir hex` y `--dir ms` corren las copias. Cada corrida siembra antes, porque las dos suites
  suponen la semilla limpia.

```text
Success 01-health.hurl (1 request(s) in 2 ms)
Success 02-auth.hurl (9 request(s) in 167 ms)
Success 03-products.hurl (12 request(s) in 197 ms)
error: Assert status code
   --> 04-orders.hurl:25:6
    |
    | POST {{base_url}}/api/v1/orders
    | ...
 25 | HTTP 400
    |      ^^^ actual value is <201>
    |

Failure 04-orders.hurl (3 request(s) in 170 ms)
error: Assert status code
   --> 05-payment.hurl:26:6
    |
    | POST {{base_url}}/api/v1/orders/{{cheap_id}}/payment
    | ...
 26 | HTTP 400
    |      ^^^ actual value is <200>
    |

Failure 05-payment.hurl (3 request(s) in 98 ms)
Success 06-cancel.hurl (19 request(s) in 250 ms)
Success 07-notifications.hurl (9 request(s) in 1704 ms)
--------------------------------------------------------------------------------
Executed files:    7
Executed requests: 56 (21.6/s)
Succeeded files:   5 (71.4%)
```

La suite hexagonal cae exactamente en las dos peticiones sin `Idempotency-Key`: el legado crea el
pedido (`201`) y cobra (`200`) donde el contrato pide `400`. La de microservicios, igual, en
`04-orders.hurl` y `05-payment.hurl`, y pasa `01`, `02`, `03` y `06`. Con `--all-errors`
(`hurl --continue-on-error`) se ve el resto de cada archivo, y todas las aserciones que fallan son
consecuencia de la misma ausencia: el stock que baja dos veces porque el reintento creó otro pedido,
el `operationId` que no es la clave, el `422` que no llega. El taller 07 las pone en verde; hasta
entonces, este es el resultado esperado y declarado.

## 11. 🖥️ En el frontend

Sección opcional. El cliente React del taller 02 aprendió la API del legado mirando respuestas: lista
de productos, `price` numérico y el `message` de los errores. `smoke.ts` gana un paso 0, «cargar el
catálogo», porque es lo primero que pinta la interfaz. Contra el legado de este taller, sin migrar:

```bash
python3 laboratorio/scripts/lab.py front-smoke
```

```text
0. cargar el catálogo
  la interfaz muestra: 💥 TypeError: (intermediate value).slice is not a function
1. comprar SKU-002 (hay stock)
  la interfaz muestra: ✅ Pedido creado: 4201be4f-b2a7-413f-90ff-730b6f24e31a (CONFIRMED)
2. comprar SKU-004 (sin stock)
  la interfaz muestra: ❌ Error 409: 
3. comprar SKU-999 (no existe)
  la interfaz muestra: ❌ Error 404: 
4. ver un pedido que no existe
  la interfaz muestra: ❌ Error 404: 
```

El catálogo ya no es una lista, así que la interfaz no pinta nada; y los errores, por fin con su
código correcto, llegan **sin texto**: el cliente buscaba `message`, que `problem+json` no tiene. El
contrato arregló el servidor y rompió al cliente, que es lo que la ficha de este taller anunciaba.

La migración va en el mismo cambio: `api.ts` lee `items`, trata el dinero como `Money` y construye el
error desde `detail`, `title` y `code`; `view.ts` muestra el importe como texto, sin pasarlo por un
número.

```text
0. cargar el catálogo
  la interfaz muestra: SKU-001 · Mechanical keyboard · $49.90 · stock 20 | SKU-002 · USB-C cable · $9.90 · stock 100
1. comprar SKU-002 (hay stock)
  la interfaz muestra: ✅ Pedido creado: e36c7f8f-61a3-4731-8463-0e712a732820 (CONFIRMED)
2. comprar SKU-004 (sin stock)
  la interfaz muestra: ❌ SKU-004: requested 1, available 0 (409 INSUFFICIENT_INVENTORY)
3. comprar SKU-999 (no existe)
  la interfaz muestra: ❌ SKU-999 (404 PRODUCT_NOT_FOUND)
4. ver un pedido que no existe
  la interfaz muestra: ❌ Order not found (404 ORDER_NOT_FOUND)
```

Aquí se migró a la vez porque el frontend vive en el mismo repositorio. Con un cliente externo el
plan sería otro: publicar el contrato, mantener la API vieja con fecha de retirada y dejar que el
cliente migre a su ritmo. Es lo que desarrolla
[`04/04`](../04-monolito-distribuido/04-contratos-fragiles-y-despliegues-coordinados.md), y lo que
hace el laboratorio de microservicios con su `/api/v2`.

## 12. 🧪 Evidencia

```bash
git diff --no-index --stat laboratorio/estados/03 laboratorio/estados/04
```

- Compara el laboratorio al cerrar el taller 03 con el de este; las líneas de `hurl/hex`, `hurl/ms` y
  `hurl/v1` se omiten aquí.

```text
 /dev/null => estados/04/contrato/openapi.yaml      | 877 +++++++++++++++++++++
 estados/{03 => 04}/frontend/src/App.tsx            |   6 +-
 estados/{03 => 04}/frontend/src/api.ts             |  30 +-
 estados/{03 => 04}/frontend/src/view.ts            |  12 +-
 estados/{03 => 04}/legacy/pom.xml                  |   5 +
 .../dev/mono/legacy/config/SecurityConfig.java     |  44 +-
 .../mono/legacy/controller/ApiErrorHandler.java    |  86 ++
 .../dev/mono/legacy/controller/AuthController.java |  20 +-
 .../legacy/controller/NotificationController.java  |  16 +-
 .../mono/legacy/controller/OrderController.java    |  69 +-
 .../mono/legacy/controller/ProductController.java  |  34 +-
 .../mono/legacy/controller/ReportController.java   |  16 +-
 .../main/java/dev/mono/legacy/dto/BatchView.java   |  18 +
 ...
 .../java/dev/mono/legacy/service/AuthService.java  |  20 +-
 .../dev/mono/legacy/service/InventoryService.java  |   7 +-
 .../java/dev/mono/legacy/service/OrderService.java |  29 +-
 .../dev/mono/legacy/service/PaymentService.java    |  18 +-
 .../dev/mono/legacy/service/ProductService.java    |  10 +-
 .../dev/mono/legacy/service/ReportService.java     |  18 +-
 .../main/java/dev/mono/legacy/util/ErrorCode.java  |  33 +
 .../dev/mono/legacy/util/Json.java => /dev/null    |  12 -
 .../java/dev/mono/legacy/util/LegacyException.java |  23 +-
 .../legacy/src/main/resources/application.yaml     |   4 +-
 .../java/dev/mono/legacy/OrderServiceTest.java     |   6 +-
 59 files changed, 3264 insertions(+), 165 deletions(-)
```

Los servicios cambian poco —un código en cada `throw`— y ninguna entidad cambia. Todo lo demás es
borde: controladores, DTO, seguridad y el contrato. Y el `500` que no depende del contrato sigue ahí:
con el cierre diario a 5 s, `lab.py lazy` devuelve ahora

```text
HTTP 500 · application/problem+json · 7 ms
{
  "instance": "/api/v1/orders/ebd8c6e3-ae94-451c-aa7c-a40c004a7f79",
  "status": 500,
  "title": "Internal error",
  "code": "INTERNAL_ERROR"
}
```

sin traza en el cuerpo y con la `LazyInitializationException` entera en el log. El contrato cambió la
forma del fallo, no su causa: la caché del cierre diario es del taller 08.

## 13. 🩺 Errores reales al correrlo

### El contrato no declaraba el 400 de un id mal formado

**Síntoma.** La primera corrida a través de Prism, con `hurl/v1` en verde, dio una violación:

```text
[PROXY] ℹ  info      The upstream call to /api/v1/orders/not-a-uuid has returned 400
[VALIDATOR] ⚠  warning   Violation: response Unable to match the returned status code with those defined in the document: 200,401,404
```

**Causa.** `openapi.yaml` se escribió partiendo del contrato hexagonal, cuyo `getOrder` no declara
`400`, mientras la suite (la misma del hexagonal) afirma que `not-a-uuid` responde `400`. La suite y
el contrato se contradecían y ninguno de los dos lo notaba.

**Lección.** Una suite en verde prueba el comportamiento; no prueba que el contrato lo describa.
Validar las respuestas contra el documento encontró la diferencia en la primera corrida. Se añadió
`400` a `getOrder` y a `cancelOrder`.

### Los dos contratos hermanos se contradicen

**Síntoma.** Al leer las dos suites para copiarlas, dos bloques de `ms` afirman lo contrario que
`hex` (sección 7).

**Causa.** Cada laboratorio fijó su regla en su propia tanda; el de microservicios libera la reserva
del pedido rechazado porque su saga lo hace, y el hexagonal no.

**Lección.** «La unión de dos contratos» solo existe si no se contradicen. Se eligió uno, se dejó
constancia en la copia y se declaró aquí; forzar las dos reglas a la vez habría producido un legado
que no respeta ninguna.

### `type` no aparece en el cuerpo

**Síntoma.** Las respuestas de error no traen `"type": "about:blank"`.

**Causa.** Spring omite `type` cuando vale `about:blank`, el valor por defecto de RFC 9457.

**Lección.** Es correcto según la norma —un `type` ausente equivale a `about:blank`— y el contrato lo
declara con `default`. Un cliente que exija el campo presente está leyendo más de lo que el contrato
promete.

## 14. 🧰 Plataformas

Los talleres son solo Java (§6 de la guía). El contrato, en cambio, es neutral: `openapi.yaml`,
`hurl/v1` y la validación con Prism sirven igual para cualquier reescritura del legado. El contraste
de cómo cada plataforma produce `problem+json` y valida la entrada está en
[`02/02`](../02-modularidad-y-limites-internos/02-api-publica-del-modulo-y-encapsulacion-interna.md) y
[`04/04`](../04-monolito-distribuido/04-contratos-fragiles-y-despliegues-coordinados.md).

## 15. 🧹 Teardown

```bash
python3 laboratorio/scripts/lab.py down
```

- Apaga PostgreSQL y Toxiproxy y borra sus volúmenes. Prism ya lo apagó `lab.py contract` al
  terminar. El legado, el `psp-simulator` y, si lo arrancaste, el frontend se paran con Ctrl+C en sus
  terminales.

## ⚠️ Errores frecuentes

- «El contrato se escribe como debería ser la API». Se escribe desde lo que es, y cada diferencia es
  una decisión; si no, promete lo que el sistema no hace.
- «Un `@ControllerAdvice` resuelve todos los errores». Los `401` y `403` no pasan por los
  controladores: los produce el filtro de seguridad, y hay que darles el mismo formato allí.
- «Con DTO el problema del dinero está resuelto». El DTO formatea al salir; el cálculo sigue en
  `double` hasta el taller 05.
- «Romper `hurl/legacy` es una regresión». Es el cambio anunciado; la regresión sería romper `hurl/v1`.
- «Si una suite hermana falla, el legado está mal». Puede que la suite y el contrato hermano se
  contradigan entre sí, o que la falla sea de un taller posterior; hay que leer qué aserción cae.
- «Si el contrato dice `required`, el servidor ya lo cumple». `x-enforced-from` existe porque aquí no
  es verdad durante tres talleres; un contrato por delante de la implementación tiene que decirlo.

## 📚 Referencias

- [RFC 9457: Problem Details for HTTP APIs](https://www.rfc-editor.org/rfc/rfc9457.html)
- [OpenAPI Specification 3.1.0](https://spec.openapis.org/oas/v3.1.0)
- [Spring Framework: Error Responses (`ProblemDetail`)](https://docs.spring.io/spring-framework/reference/web/webmvc/mvc-ann-rest-exceptions.html)
- [Spring Boot: Validation](https://docs.spring.io/spring-boot/reference/io/validation.html)
- [Prism: Validation Proxy](https://github.com/stoplightio/prism/blob/main/docs/guides/03-validation-proxy.md)
- [Hurl: manual (`--continue-on-error`)](https://hurl.dev/docs/manual.html)

## 🧠 Preguntas

1. ¿Qué diferencia hay entre `hurl/legacy` y `hurl/v1`, y cuál es la invariante desde este taller? 🟢
2. ¿Qué campos de un `problem+json` vienen de RFC 9457 y para qué sirve `code`? 🟢
3. ¿Por qué `401` y `403` no los produce `ApiErrorHandler`? 🟢
4. ¿Qué publica un DTO que no publicaba la entidad, y qué deja de publicar? 🟢
5. ¿Por qué el login responde igual a un correo inexistente que a una contraseña equivocada? 🟡
6. El contrato muestra `"29.70"` y el legado sigue calculando en `double`. ¿Qué arregló el taller y qué no? 🟡
7. ¿Qué encontró Prism que `hurl/v1` en verde no encontraba? 🟡
8. ¿Por qué se sustituyó el dominio de los correos al copiar las suites en lugar de añadir usuarios a la semilla? 🟡
9. ¿Qué significa `x-enforced-from: "06/07"` y qué riesgo acepta el equipo al escribirlo? 🟡
10. ¿Por qué un `SKU-999` pasa de `500` a `404` y no a `400`? 🟡
11. El frontend dejó de mostrar errores con el contrato nuevo. ¿Es una regresión? 🟠
12. Los contratos hexagonal y de microservicios se contradicen en el pedido rechazado. ¿Cómo decidiste y qué harías si un cliente real dependiera de la otra regla? 🟠
13. Un cliente externo que no puedes migrar lee `{"error"}` en un `200`. ¿Cómo publicas este contrato sin romperlo? 🟠
14. ¿Qué parte del contrato cambiarías si mañana los pedidos se extrajeran a otro proceso, y qué parte no debería cambiar? 🔴

## 🧪 Ejercicios

1. 🟢 **Orientación en código ajeno.** ¿En qué archivo y línea se decide que un token revocado
   responde `TOKEN_REVOKED` y no `UNAUTHENTICATED`? Responde con rutas de `laboratorio/estados/04/`.
2. 🟢 Corre `lab.py suite --dir legacy` y cuenta cuántas aserciones de `hurl/legacy` dependían de un
   defecto marcado como «defecto congelado». ¿Cuántas cayeron por un cambio no anunciado?
3. 🟡 Quita `400` de `getOrder` en `openapi.yaml`, corre `lab.py contract` y pega la violación.
   Devuélvelo y explica por qué la suite no lo detecta sola.
4. 🟡 **Orientación en código ajeno.** Encuentra dónde se construye `errors[].field` para el stock
   insuficiente. ¿Por qué ese dato no lo puede producir `InventoryService`?
5. 🟡 Haz que `ApiErrorHandler` devuelva la traza en `detail` cuando el perfil activo sea `dev`.
   Argumenta por qué es peor idea de lo que parece.
6. 🟠 Añade `Deprecation` y `Sunset` a las respuestas de una ruta y escribe el plan de retirada de la
   API vieja para un cliente externo que lee `{"error"}`: fechas, métricas y qué haces el día del
   corte.
7. 🟠 Lleva a `hurl/v1` un escenario de paginación de pedidos: tres pedidos, `limit=2`, y comprueba
   que la segunda página empieza en el tercero. ¿Qué pasa con un cursor por desplazamiento si entre
   las dos lecturas llega un pedido nuevo?
8. 🔥 Genera un cliente TypeScript desde `openapi.yaml` y sustituye `api.ts`. Compara lo que ganas en
   tipos con lo que pierdes en control del manejo de errores.

---

**Anterior:** [`03` — Caracterización](03-caracterizacion.md). **Siguiente:**
[`05` — SQLite miente](05-sqlite-miente.md).
