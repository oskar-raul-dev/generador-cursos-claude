# 01 — Contrato OpenAPI y suite de contrato

Este taller es **opcional**, como todo el bloque 06, y es el **prerrequisito de todos los demás**:
fija el contrato HTTP del caso de estudio, el entorno común y la suite que decide cuándo un backend
está terminado. No hay ninguna línea de Java, Go o PHP aquí. Lo que se aprende es a diseñar la API
antes de que exista, y a convertir ese diseño en un criterio de aceptación que un comando puede
comprobar.

> **Vigencia:** 2026-09-27. Versiones verificadas ese día contra Docker Hub, Homebrew y GitHub.

**Salto rápido:** [1](#1--el-problema) · [2](#2--prerrequisitos-y-versiones) · [3](#3-️-mapa-de-carpetas) · [4](#4--el-contrato-antes-que-el-código) · [5](#5--el-entorno) · [6](#6--la-suite-de-contrato) · [7](#7--correr-la-suite-contra-el-mock) · [8](#8--errores-provocados-a-propósito) · [9](#9--teardown) · [Preguntas](#-preguntas) · [Ejercicios](#-ejercicios)

## 1. 🎯 El problema

Cinco equipos van a implementar el mismo sistema en cinco lenguajes. Si cada uno "documenta la API
al final, a partir del código", habrá cinco APIs parecidas: una devuelve `200` al crear, otra
`201`; una rechaza el stock insuficiente con `400`, otra con `409`; una serializa el dinero como
`49.9` y otra como `"49.90"`. El frontend tendría que conocer cinco dialectos, y la pregunta central
del bloque —¿son intercambiables los cinco núcleos?— no tendría respuesta.

En términos del corpus: el contrato HTTP es la forma externa del [puerto de
entrada](../02-nucleo-aplicacion-y-dominio/03-puertos-de-entrada.md), y el frontend y la suite son
*driving adapters*. Si el contrato se fija primero, los cinco adaptadores HTTP traducen el mismo
lenguaje al mismo puerto, y la suite es la evidencia de que lo hacen. Si se fija después, cada
adaptador dicta su propio contrato y la frontera queda al revés.

```text
contrato (openapi.yaml) ─► suite hurl ─► backend A (:8081)   verde
                                     ─► backend B (:8082)   verde
                                     ─► mock (:14010)       rojo donde hay reglas de negocio
```

El precio: un documento YAML de unas 600 líneas que hay que mantener, y una suite que exige
disciplina en la semilla. La ganancia: un criterio de terminado que no se discute.

## 2. 🧰 Prerrequisitos y versiones

| Herramienta | Versión fijada | Para qué |
|---|---|---|
| Docker Desktop / Engine | 29.x con Compose v5 | contenedores del entorno |
| `hurl` | 8.0.1 | suite de contrato |
| Python | 3.11 o superior | `lab.py`, sin dependencias |
| `postgres` | `17.11-alpine` | pedidos, inventario, pagos, outbox |
| `mongo` | `8.0.20` | catálogo desde la parte 3 de cada sabor |
| `redis` | `7.4.11-alpine` | revocación de tokens |
| `swaggerapi/swagger-ui` | `v5.33.0` | leer el contrato |
| `stoplight/prism` | `5.15.10` | mock generado del contrato |

📝 `mongo:8.0.20` y no una `8.0.x` más reciente: las imágenes `8.0.21` en adelante rechazan el
núcleo `7.0.12` que trae Docker Desktop 4.92. Si `docker info --format '{{.KernelVersion}}'` muestra
`7.0.14` o superior, se puede subir; hasta entonces, no.

`hurl` se instala con el gestor de paquetes del sistema (`brew install hurl` en macOS; hay binarios
para Linux y Windows en su página de releases). Todo lo demás lo trae Docker.

```text
python3 06-talleres/laboratorio/scripts/lab.py check
```

- `check` comprueba que `docker`, `docker compose` y `hurl` están en el `PATH` e imprime sus
  versiones y las rutas del compose y de la suite. Es lo primero que se corre en cualquier taller.

## 3. 🗂️ Mapa de carpetas

```text
06-talleres/laboratorio/
├── contrato/
│   ├── openapi.yaml            el contrato: 3.1.0, rutas v1 y v1.1
│   ├── docker-compose.yml      hex-postgres · hex-mongo · hex-redis · hex-swagger · hex-mock
│   ├── seed/
│   │   ├── schema.sql          esquema común de hex_orders (lo ejecuta la imagen al crear la base)
│   │   ├── seed.sql            semilla idempotente: TRUNCATE + INSERT
│   │   └── products.json       catálogo para MongoDB (parte 3 de cada sabor)
│   └── hurl/
│       ├── v1/                 01-health · 02-auth · 03-products · 04-orders · 05-payment
│       └── v1.1/               06-cancel · 07-notifications
└── scripts/
    └── lab.py                  up · down · ps · logs · seed · mock · health · suite
```

Los talleres de sabor añaden `java/`, `nestjs/`, `go/`, `python/` y `php/` al lado; los de
integración añaden `payments-grpc/`, `asyncapi.yaml` y `proto/`. Nada de eso existe todavía.

## 4. 📐 El contrato antes que el código

El archivo es `laboratorio/contrato/openapi.yaml`. Se lee cómodo en Swagger UI
(`http://localhost:18080` cuando el entorno está arriba); aquí van las decisiones, no el YAML
entero. Cada una es una pregunta de entrevista de diseño de API.

### Recursos, verbos y estados

| Operación | Ruta | Actor | Efecto |
|---|---|---|---|
| `login` | `POST /api/v1/auth/login` | público | token de 15 min |
| `logout` | `POST /api/v1/auth/logout` | cualquiera | revoca ese token |
| `listProducts` / `getProduct` | `GET /api/v1/products[/{sku}]` | cualquiera | catálogo con stock |
| `createProduct` | `POST /api/v1/products` | `operator` | alta |
| `createOrder` | `POST /api/v1/orders` | cualquiera | reserva atómica; nace `CONFIRMED` |
| `getOrder` / `listOrders` | `GET /api/v1/orders[/{orderId}]` | dueño u `operator` | lectura |
| `authorizePayment` | `POST /api/v1/orders/{orderId}/payment` | dueño u `operator` | `PAID`, `PAYMENT_REJECTED` o `PAYMENT_PENDING` |
| `cancelOrder` (v1.1) | `POST /api/v1/orders/{orderId}/cancel` | dueño u `operator` | `CANCELLED`, libera reserva, notifica |
| `listNotifications` (v1.1) | `GET /api/v1/notifications` | `operator` | lo que entregó el `Notifier` |

Dos decisiones que suelen discutirse:

- **`/payment` y `/cancel` son sub-recursos con `POST`, no `PATCH /orders/{id}` con
  `{"status": "CANCELLED"}`.** Un cambio de estado es una intención con reglas propias (quién puede,
  desde qué estado, qué efectos secundarios), y una intención se nombra. `PATCH` del estado obliga al
  cliente a conocer la máquina de estados y al servidor a adivinar la intención a partir del
  destino. Es la misma razón por la que el [puerto de
  entrada](../02-nucleo-aplicacion-y-dominio/03-puertos-de-entrada.md) se llama `CancelOrder` y no
  `UpdateOrder`.
- **El pedido de otro cliente responde `404`, no `403`.** `403` confirma que el recurso existe;
  `404` no revela nada. El contrato lo declara en `getOrder` y el capítulo de
  [DTO y errores](../03-adaptadores-de-entrada/05-dto-mapeo-y-presentacion-de-errores.md) lo
  discute como decisión del borde.

La máquina de estados del pedido, que el contrato expone en `OrderStatus`:

```text
            createOrder                authorizePayment
   ·  ─────────────────►  CONFIRMED  ──────────────────►  PAID
                              │  │                          (no se cancela)
                              │  └────► PAYMENT_REJECTED ──┐
                              │  └────► PAYMENT_PENDING  ──┤ cancelOrder
                              └──────────────────────────────┴──►  CANCELLED
```

`PAYMENT_REJECTED` vuelve a ser pagable con otra clave; `PAYMENT_PENDING` no, porque primero habría
que consultar al proveedor. Esa asimetría es la lección del capítulo de [clientes
externos](../04-adaptadores-de-salida-y-operacion/02-clientes-http-grpc-y-servicios-externos.md):
"no sé si cobró" nunca se convierte en "rechazado".

### Errores: `application/problem+json` con un `code` propio

Todos los errores usan RFC 9457 —`type`, `title`, `status`, `detail`, `instance`— más dos campos
propios: `code`, un identificador estable para máquinas, y `errors`, la lista de campos cuando el
problema es de forma. El frontend y la suite deciden por `code`, nunca por `title` ni por `detail`,
que son texto para humanos y pueden cambiar.

| `code` | HTTP | Cuándo |
|---|---|---|
| `VALIDATION_FAILED` | 400 | forma: campo ausente, tipo incorrecto, `lines` vacío, id que no es UUID |
| `IDEMPOTENCY_KEY_REQUIRED` | 400 | falta la cabecera en una operación que la exige |
| `INVALID_CREDENTIALS` | 401 | login fallido; mismo cuerpo exista o no el correo |
| `UNAUTHENTICATED` / `TOKEN_REVOKED` | 401 | sin token válido / token revocado por `logout` |
| `FORBIDDEN` | 403 | el actor no tiene la capacidad (un `customer` dando de alta productos) |
| `PRODUCT_NOT_FOUND` / `ORDER_NOT_FOUND` | 404 | no existe, o no es tuyo |
| `PRODUCT_ALREADY_EXISTS` | 409 | conflicto de identidad |
| `INSUFFICIENT_INVENTORY` | 409 | conflicto de estado: el negocio dice que no |
| `ORDER_NOT_PAYABLE` / `ORDER_NOT_CANCELLABLE` | 409 | la máquina de estados dice que no |
| `IDEMPOTENCY_KEY_REUSED` | 422 | la misma clave con otro cuerpo |
| `INTERNAL_ERROR` | 500 | fallo técnico; mensaje genérico y correlación |

`400` es "no entiendo la petición"; `409` es "la entiendo y el estado actual no lo permite"; `422`
queda para el único caso en que la petición está bien formada pero es contradictoria con una
anterior. Un `catch` global que convierte todo en `400` borra esa semántica, que es de lo que vive
el [reparto de validación](../02-nucleo-aplicacion-y-dominio/06-validacion-errores-y-resultados.md).

### Idempotencia: `Idempotency-Key` en lo que crea o cobra

`createOrder` y `authorizePayment` exigen la cabecera. La semántica sigue el borrador de la IETF
para esa cabecera: la misma clave con el mismo cuerpo devuelve la respuesta original con
`Idempotent-Replay: true`; la misma clave con otro cuerpo, `422`. La clave tiene alcance por actor
y se conserva 24 horas. En el pago, además, la clave viaja al proveedor como identidad de la
operación y **nunca se regenera** en un reintento: es lo que impide cobrar dos veces cuando la
respuesta se perdió.

Lo que el contrato no dice, a propósito: dónde se guarda la clave. Eso es del adaptador de salida
(`idempotency_keys` en PostgreSQL en los cinco sabores), y el capítulo de [HTTP como
adaptador](../03-adaptadores-de-entrada/01-http-como-adaptador-de-entrada.md) explica por qué no
basta comprobarla en memoria del controller.

### Paginación por cursor opaco

`listProducts`, `listOrders` y `listNotifications` reciben `cursor` y `limit` y devuelven `items`
y `nextCursor` (`null` en la última página). El cursor es opaco: el cliente lo devuelve tal cual y
no lo interpreta. Se prefiere a `offset` porque una lista que cambia entre páginas —pedidos que se
crean, productos que se dan de alta— salta o repite filas con `offset`, y porque el cursor no
obliga al servidor a contar. El servidor acota `limit` a 100 aunque el cliente pida más.

### Dinero como texto decimal

```json
{ "amount": "49.90", "currency": "USD" }
```

`amount` es un `string` con dos cifras, con patrón en el esquema. Un número JSON se convierte en
`double` en JavaScript, PHP y Go sin que nadie lo pida, y `0.1 + 0.2` deja de ser `0.3`. Con texto,
cada backend lo lee con su tipo decimal (`BigDecimal`, `decimal.Decimal`, `shopspring/decimal`,
`brick/money`) y el contrato no depende de la aritmética de nadie. Es el mismo argumento que el
capítulo de clientes externos hace para el proveedor de pagos.

### Dos actores, dos capacidades

`customer` crea, paga, cancela y ve lo suyo. `operator` administra el catálogo y ve todo. El JWT
lleva `sub`, `role`, `jti` y `exp`; el borde lo verifica y construye un `Actor`; la regla "solo el
dueño o un `operator`" vive en el caso de uso, no en el filtro HTTP, como manda
[autenticación y contexto de actor](../03-adaptadores-de-entrada/04-autenticacion-autorizacion-y-contexto-de-actor.md).
La revocación por `jti` con TTL igual al tiempo restante es lo que hace que `logout` sea una
operación real y no un `204` decorativo: aparece el puerto `TokenRevocationStore`.

### Qué no dice el contrato

No dice cómo se reserva el inventario, en qué tabla, con qué aislamiento, ni si el catálogo está
en PostgreSQL o en MongoDB. No dice si el `Notifier` escribe una fila o publica en Kafka. Todo eso
es del otro lado del hexágono. Que la parte 3 de cada sabor mueva el catálogo a MongoDB **sin que
este archivo cambie** es la prueba de que el contrato está en el sitio correcto.

## 5. 🧱 El entorno

### El compose, servicio por servicio

`laboratorio/contrato/docker-compose.yml` levanta cinco contenedores con el prefijo `hex-`. Los
nombres, puertos y credenciales son los de §11 de la guía; se copian, no se eligen.

| Servicio | Contenedor | Host → contenedor | Por qué ese puerto |
|---|---|---|---|
| `postgres` | `hex-postgres` | `15432 → 5432` | el laboratorio de bases de datos ya usa `5432` |
| `mongo` | `hex-mongo` | `17017 → 27017` | ídem con `27017` |
| `redis` | `hex-redis` | `16379 → 6379` | ídem con `6379` |
| `swagger-ui` | `hex-swagger` | `18080 → 8080` | lectura del contrato |
| `mock` | `hex-mock` | `14010 → 4010` | solo con el perfil `mock` |

Tres decisiones del archivo que conviene leer en el YAML:

- **`docker-entrypoint-initdb.d`** en `postgres`: la imagen ejecuta `01-schema.sql` y
  `02-seed.sql` **solo la primera vez que crea la base**. Por eso `lab.py seed` existe aparte: para
  recargar la semilla sin recrear el contenedor.
- **Sin volúmenes con nombre**: `down` borra los datos. Es deliberado; el entorno es desechable y
  la semilla es la fuente de verdad.
- **`healthcheck` en los cinco**, incluido el mock. Sin él, `up --wait` devuelve el control cuando
  el contenedor *arranca*, no cuando *escucha*, y la primera petición recibe "connection reset". Se
  reproduce en §8.

### Levantar, sembrar, mirar

```text
python3 06-talleres/laboratorio/scripts/lab.py up
python3 06-talleres/laboratorio/scripts/lab.py seed --mongo
python3 06-talleres/laboratorio/scripts/lab.py ps
```

- `up` ejecuta `docker compose up -d --wait`: `-d` en segundo plano, `--wait` bloquea hasta que
  todos los `healthcheck` pasan. Descarga las imágenes la primera vez; después tarda unos segundos.
  Al terminar imprime dónde quedó cada cosa.
- `seed` ejecuta `psql -v ON_ERROR_STOP=1 -q -U hex -d hex_orders -f /seed/seed.sql` **dentro** de
  `hex-postgres`: `-v ON_ERROR_STOP=1` hace que el primer error detenga el script en vez de seguir
  a medias; `-q` silencia el eco de cada sentencia. La semilla hace `TRUNCATE … RESTART IDENTITY
  CASCADE` y vuelve a insertar, así que se puede correr las veces que haga falta.
- `--mongo` añade `mongoimport --db hex_catalog --collection products --drop --jsonArray --file
  /seed/products.json`: `--drop` vacía la colección antes, `--jsonArray` porque el archivo es una
  lista y no un documento por línea. Hasta la parte 3 de un sabor nadie lee esa colección; se
  carga igual para que el entorno esté completo.
- `ps` es `docker compose ps` con el perfil `mock` incluido, para ver también el mock si está
  arriba.

Lo que dejó la semilla, comprobado el 2026-09-27:

```text
$ docker exec hex-postgres psql -U hex -d hex_orders -Atc "select count(*) from products"
5
$ docker exec hex-mongo mongosh --quiet hex_catalog --eval 'db.products.countDocuments()'
5
```

- `-Atc`: `-A` sin alineación, `-t` sin cabecera, `-c` ejecuta la consulta y sale. Es la forma de
  usar `psql` en un script sin que el formato de tabla estorbe.
- `mongosh --quiet … --eval`: evalúa la expresión y sale, sin el banner de bienvenida.

### La semilla y por qué está donde está

`schema.sql` es **común a los cinco sabores**, y eso es una decisión declarada, no un descuido.
En un sistema real, el esquema lo poseería el adaptador de persistencia de cada servicio, con sus
migraciones. Aquí, cinco backends comparten datos y suite, y cinco esquemas distintos harían
imposible cambiar de sabor con un `--base-url`. El precio es que ningún sabor puede "mejorar" el
esquema por su cuenta; la ganancia es que el esquema deja de ser una variable del experimento.

Dos detalles del esquema son arquitectura:

- `products` (catálogo) e `inventory` (existencias) son tablas separadas **sin clave foránea entre
  ellas**. La parte 3 de cada sabor se lleva el catálogo a MongoDB; una FK lo haría imposible. La
  frontera del cambio interno está dibujada en el esquema desde el día uno.
- `order_lines` guarda `product_name` y `unit_price`: la foto del catálogo en el momento de la
  venta. Un pedido de hace un mes no cambia de precio porque hoy se actualizó el catálogo.

Los valores de la semilla no son casuales: `SKU-004` tiene stock `0` para provocar
`INSUFFICIENT_INVENTORY`; `SKU-005` cuesta `1499.00` para que el pago se rechace; `SKU-003` cuesta
`222.00` para que tres unidades sumen `666.00`, el importe con el que el `PaymentGateway`
determinista "no responde". Las contraseñas están como bcrypt de coste 10; los cinco backends las
verifican con la biblioteca bcrypt de su ecosistema, y ninguno guarda texto plano.

## 6. 🧪 La suite de contrato

### Por qué `hurl`

`hurl` es un archivo de texto con peticiones HTTP y aserciones, ejecutado por `curl`. No hay
runtime de JavaScript, ni colección exportada de una herramienta gráfica, ni SDK: se lee entero en
un `diff`, se versiona al lado del contrato y corre igual en las tres plataformas. Para una suite
que cinco backends tienen que pasar, esa neutralidad importa más que cualquier comodidad.

Anatomía de una entrada, de `04-orders.hurl`:

```text
POST {{base_url}}/api/v1/orders
Authorization: Bearer {{ana_token}}
Idempotency-Key: suite-04-order-0001
Content-Type: application/json
{ "lines": [ { "sku": "SKU-001", "quantity": 2 }, { "sku": "SKU-002", "quantity": 1 } ] }
HTTP 201
[Captures]
order_id: jsonpath "$.id"
[Asserts]
header "Location" matches "/api/v1/orders/[0-9a-f-]{36}$"
jsonpath "$.status" == "CONFIRMED"
jsonpath "$.total.amount" == "109.70"
```

- La petición: método, URL con la variable `base_url`, cabeceras y cuerpo.
- `HTTP 201`: el código esperado; si no coincide, la entrada falla ahí.
- `[Captures]`: guarda `$.id` en `order_id` para las entradas siguientes del mismo archivo.
- `[Asserts]`: cada línea es una aserción independiente; el informe dice cuál falló y con qué
  valor real.

### Cómo está organizada

| Archivo | Qué comprueba |
|---|---|
| `v1/01-health` | el proceso responde |
| `v1/02-auth` | login, credenciales inválidas, validación de forma, `logout` que revoca |
| `v1/03-products` | catálogo, paginación por cursor, alta solo `operator`, conflicto, dinero mal formado |
| `v1/04-orders` | clave obligatoria, forma, SKU inexistente, reserva atómica que falla completa, reserva que descuenta stock, repetición idempotente, clave reutilizada, visibilidad por actor |
| `v1/05-payment` | autorizado, repetición, conflicto de estado, rechazado y reintentable, pendiente y no reintentable |
| `v1.1/06-cancel` | cancelar libera stock, es idempotente, no se paga lo cancelado, no se cancela lo pagado, sí lo rechazado |
| `v1.1/07-notifications` | la cancelación produce exactamente una notificación, entregada de forma asíncrona; un `customer` no las lee |

Tres reglas de diseño de la suite que se pagan en cada archivo:

- **Cada archivo hace su propio login.** `hurl` no comparte capturas entre archivos, y eso es una
  virtud: cada archivo se puede correr solo con `--file`.
- **Los archivos que tocan stock usan SKU distintos o crean el suyo.** `06-cancel` da de alta
  `SKU-101` con 7 unidades y hace sus cuentas sobre él; así no depende de lo que `04` y `05`
  reservaron. `04` sí asume la semilla recién cargada (`SKU-001` en 20): **`seed` antes de cada
  corrida**.
- **Lo asíncrono se espera con `retry`, no con `sleep`.** `07-notifications` reintenta la lectura
  hasta 20 veces cada 500 ms (`[Options] retry: 20`, `retry-interval: 500ms`) hasta que las
  aserciones pasan, porque el `Notifier` corre después del commit en un dispatcher aparte. Y para
  comprobar que la segunda cancelación **no** produce una segunda notificación, espera 1,5 s
  (`delay`) y vuelve a contar: la ausencia de algo asíncrono solo se afirma después de darle tiempo.

### Cómo se corre

```text
python3 06-talleres/laboratorio/scripts/lab.py suite --base-url http://localhost:8081
python3 06-talleres/laboratorio/scripts/lab.py suite --base-url http://localhost:8081 --only v1
python3 06-talleres/laboratorio/scripts/lab.py suite --base-url http://localhost:8081 --file 06-talleres/laboratorio/contrato/hurl/v1/02-auth.hurl
```

- `suite` construye `hurl --test --jobs 1 --variable base_url=… <archivos>`: `--test` da el informe
  por archivo sin volcar cuerpos; `--jobs 1` corre los archivos en orden, porque consumen stock;
  `--variable` inyecta la URL base, que es **lo único que cambia entre sabores**.
- `--only v1` corre solo la parte 1; `--only v1.1`, solo la 2 (que asume `v1` pasada, porque usa
  `createProduct` y `authorizePayment`).
- `--file` corre un archivo suelto; `--verbose` añade `--verbose` de `hurl`, que imprime cada
  petición y respuesta.
- El código de salida es el de `hurl`: `0` si todo pasó. Es lo que un CI comprobaría.

## 7. 🔁 Correr la suite contra el mock

Todavía no hay backend. Hay algo mejor para este taller: un mock generado **del contrato**, que
responde con los ejemplos del YAML y valida que las peticiones cumplan los esquemas. Sirve para dos
cosas: comprobar que el contrato es coherente (Prism se niega a cargar un YAML inválido) y ver con
precisión **qué parte de la suite es contrato y qué parte es negocio**.

```text
python3 06-talleres/laboratorio/scripts/lab.py mock
python3 06-talleres/laboratorio/scripts/lab.py health --base-url http://localhost:14010
python3 06-talleres/laboratorio/scripts/lab.py suite --base-url http://localhost:14010
```

- `mock` levanta solo el servicio `mock` (perfil `mock` del compose) y espera su `healthcheck`.
- `health` pide `/health` con `urllib` y muestra código y cuerpo; contra el mock devuelve el
  ejemplo del contrato: `200 {'status': 'UP'}`.
- `suite` es la misma orden de siempre con otra URL base.

Salida literal del 2026-09-27, con las rutas acortadas:

```text
$ hurl --test --jobs 1 --variable base_url=http://localhost:14010 hurl/v1/01-health.hurl hurl/v1/02-auth.hurl hurl/v1/03-products.hurl hurl/v1/04-orders.hurl hurl/v1/05-payment.hurl hurl/v1.1/06-cancel.hurl hurl/v1.1/07-notifications.hurl
Success hurl/v1/01-health.hurl (1 request(s) in 8 ms)
error: Assert status code
  --> hurl/v1/02-auth.hurl:19:6
   |
   | POST {{base_url}}/api/v1/auth/login
   | ...
19 | HTTP 401
   |      ^^^ actual value is <200>
   |

Failure hurl/v1/02-auth.hurl (2 request(s) in 30 ms)
error: Assert failure
   --> hurl/v1/03-products.hurl:22:0
    |
    | GET {{base_url}}/api/v1/products
    | ...
 22 | jsonpath "$.items" count >= 5
    |   actual:   integer <2>
    |   expected: greater or equal than integer <5>
    |

Failure hurl/v1/03-products.hurl (3 request(s) in 46 ms)
error: Assert status code
   --> hurl/v1/04-orders.hurl:22:6
    |
    | POST {{base_url}}/api/v1/orders
    | ...
 22 | HTTP 400
    |      ^^^ actual value is <422>
    |

Failure hurl/v1/04-orders.hurl (3 request(s) in 39 ms)
error: Assert status code
   --> hurl/v1/05-payment.hurl:16:6
    |
    | POST {{base_url}}/api/v1/orders
    | ...
 16 | HTTP 201
    |      ^^^ actual value is <200>
    |

Failure hurl/v1/05-payment.hurl (2 request(s) in 22 ms)
error: Assert status code
   --> hurl/v1.1/06-cancel.hurl:32:6
    |
    | POST {{base_url}}/api/v1/orders
    | ...
 32 | HTTP 201
    |      ^^^ actual value is <200>
    |

Failure hurl/v1.1/06-cancel.hurl (4 request(s) in 23 ms)
error: Assert status code
  --> hurl/v1.1/07-notifications.hurl:23:6
   |
   | POST {{base_url}}/api/v1/orders
   | ...
23 | HTTP 201
   |      ^^^ actual value is <200>
   |

Failure hurl/v1.1/07-notifications.hurl (3 request(s) in 10 ms)
--------------------------------------------------------------------------------
Executed files:    7
Executed requests: 18 (95.2/s)
Succeeded files:   1 (14.3%)
Failed files:      6 (85.7%)
Duration:          189 ms (0h:0m:0s:189ms)
```

Uno de siete. Y es el resultado correcto. Fallo por fallo:

- **`02-auth:19`, contraseña incorrecta → esperado `401`, real `200`.** El mock no sabe qué
  contraseña es válida: devuelve el ejemplo de la primera respuesta. Regla de negocio.
- **`03-products:22`, cinco productos → llegaron dos.** El ejemplo de `ProductPage` tiene dos
  ítems. El mock no tiene semilla. Dato.
- **`04-orders:22`, `lines: []` → esperado `400`, real `422`.** Este es el más interesante: Prism
  **sí** validó el cuerpo contra `CreateOrderRequest` (`minItems: 1`) y lo rechazó. Al hacerlo,
  buscó en el contrato una respuesta `422` para esa operación y usó su ejemplo, que es el de
  `IDEMPOTENCY_KEY_REUSED`. El código que devuelve el mock es el de la herramienta, no el que el
  contrato promete para ese caso. Es la diferencia entre "el YAML es válido" y "el backend cumple
  el contrato".
- **`05`, `06`, `07`, crear pedido → esperado `201`, real `200`.** `createOrder` declara dos
  respuestas 2xx: `201` al crear y `200` al repetir con la misma clave. Prism elige la 2xx más
  baja. Un backend real distingue por la clave; el mock no tiene memoria. La alternativa —no
  documentar la repetición como `200`— sería peor: dejaría fuera del contrato justo lo que la
  idempotencia promete.

Lo que sí pasó, y es lo que el mock está para comprobar: `01-health` completo, los dos `login`
de cada archivo (la forma del `TokenResponse`), y todas las peticiones anteriores a cada primer
fallo. Y hay una forma de ir más lejos sin backend: pedirle al mock una respuesta concreta con la
cabecera `Prefer`, que es como se verifica la **forma** de cada error.

```text
$ curl -s -i -X POST http://localhost:14010/api/v1/orders \
    -H 'Authorization: Bearer x' -H 'Idempotency-Key: demo-0001' \
    -H 'Content-Type: application/json' -H 'Prefer: code=409' \
    -d '{"lines":[{"sku":"SKU-004","quantity":1}]}'
HTTP/1.1 409 Conflict
Content-type: application/problem+json
{"type":"about:blank","title":"Insufficient inventory","status":409,"code":"INSUFFICIENT_INVENTORY","detail":"SKU-004: requested 1, available 0","instance":"/api/v1/orders","errors":[{"field":"lines[0].quantity","message":"requested 1, available 0"}]}
```

- `curl -s -i`: `-s` sin barra de progreso, `-i` imprime también las cabeceras de la respuesta.
- `-X POST`, `-H`, `-d`: método, cabeceras y cuerpo. `Authorization` va con cualquier valor porque
  Prism solo comprueba que el esquema de seguridad esté presente, no que el token sea válido.
- `Prefer: code=409` le pide al mock la respuesta documentada con ese código. Lo que vuelve es el
  ejemplo del contrato con el `Content-Type` correcto: eso es lo que el frontend del taller 02 va a
  programar contra, antes de que exista un backend que lo produzca.

Y sin `Authorization`, Prism responde `401` con el ejemplo de `Unauthenticated`: el esquema de
seguridad del contrato también se aplica en el mock.

💡 El resumen que conviene llevarse: la suite tiene aserciones de **contrato** (códigos, formas,
cabeceras, `Content-Type`) y aserciones de **negocio** (qué contraseña vale, cuánto stock queda, qué
pedido se puede cancelar). El mock pasa las primeras y no puede pasar las segundas. Cuando el
taller 03 haga pasar las siete, cada línea que hoy está en rojo será una regla de negocio que el
núcleo implementó.

## 8. 🩺 Errores provocados a propósito

### El mock arranca y muere: multiproceso

La primera versión del compose lanzaba Prism sin `-m false`. `up --mock` informó `Container
hex-mock Healthy` y, un segundo después, el contenedor estaba `Exited (1)`:

```text
$ docker ps -a --format '{{.Names}}\t{{.Status}}' | grep hex-mock
hex-mock	Exited (1) 11 seconds ago
$ docker logs hex-mock 2>&1 | tail -3
TypeError: Cannot read properties of undefined (reading 'isPrimary')
    at createMultiProcessPrism (/usr/src/prism/packages/cli/dist/util/createServer.js:29:32)
    at runPrismAndSetupWatcher (/usr/src/prism/packages/cli/dist/util/runner.js:8:12)
```

- `docker ps -a`: `-a` incluye los contenedores parados; sin ella, un contenedor muerto
  simplemente no aparece y el diagnóstico empieza mal.
- `docker logs … | tail -3`: las últimas líneas del registro del contenedor, donde está la traza.

`createMultiProcessPrism` es el modo por defecto de Prism 5.15 en Docker, y en esta imagen falla al
crear el proceso primario. `-m false` lo deja en un solo proceso, que para un mock de laboratorio
es lo que hace falta. Se probó con `-m false`, `--multiprocess=false` y `--no-multiprocess`; las
tres formas arrancan. El compose lleva la primera y el comentario dice por qué.

### `--wait` sin `healthcheck`: "Healthy" no es "escucha"

Con el mock ya arrancando, la primera corrida de la suite fue esta:

```text
error: HTTP connection
  --> hurl/v1/01-health.hurl:2:5
   |
 2 | GET {{base_url}}/health
   |     ^^^^^^^^^^^^^^^^^^^ (56) Recv failure: Connection reset by peer
```

`up --wait` había devuelto el control: para Compose, un servicio sin `healthcheck` está "healthy"
en cuanto el proceso arranca. Prism tarda unos segundos en cargar el contrato y empezar a escuchar,
y `hurl` llegó antes. Un segundo intento, diez segundos después, pasó. La corrección es el
`healthcheck` del servicio `mock` en el compose (`wget -qO- http://127.0.0.1:4010/health`); con él,
`--wait` espera de verdad y la primera petición encuentra el puerto abierto. Es la misma lección
que los backends aprenderán con sus propios `/health`: "arrancado" y "listo" son dos estados.

## 9. 🧹 Teardown

```text
python3 06-talleres/laboratorio/scripts/lab.py down
```

- `down` ejecuta `docker compose --profile mock down -v`: baja los cinco servicios, incluido el
  mock aunque esté arriba, y `-v` borra los volúmenes anónimos. No queda nada; el siguiente taller
  vuelve a empezar con `up` y `seed`.

Si se quiere conservar Swagger UI abierto mientras se lee el contrato, `docker compose -f
06-talleres/laboratorio/contrato/docker-compose.yml stop postgres mongo redis mock` apaga solo el
resto; pero al cerrar el taller se corre `down`.

## ⚠️ Errores frecuentes

- "El mock ya prueba la API." Prueba la forma; el negocio lo prueba un backend. Uno de siete
  archivos en verde es el máximo que un mock puede dar con esta suite.
- "Un `200` al repetir la creación es un contrato ambiguo." Es la semántica documentada de
  `Idempotency-Key`; lo ambiguo sería devolver `201` dos veces por el mismo pedido.
- "`422` para todo lo que no sea sintaxis." Aquí `422` es solo la clave reutilizada; el stock, el
  estado y la identidad son `409`. Mezclarlos deja al cliente sin saber si reintentar.
- "La suite puede correr en paralelo para ir más rápido." Los archivos consumen stock de la misma
  semilla; `--jobs 1` es una decisión, no un descuido.
- "El esquema compartido es un antipatrón." En producción, sí: cada servicio posee su esquema.
  Aquí es una constante del experimento, y se declara como tal.
- "Con `--wait` ya está listo." Solo si hay `healthcheck`. Sin él, "arrancado" es todo lo que
  Compose sabe.

## ✅ Veredicto

Escribe el contrato primero, con la semántica de errores, idempotencia y dinero decidida, y
convierte cada decisión en una aserción que un comando compruebe. El mock te dice si el contrato es
coherente; la suite le dice a cada backend si es intercambiable. Lo que cuesta —un YAML largo, una
semilla disciplinada, `seed` antes de cada corrida— es el precio de que "terminado" signifique lo
mismo en cinco lenguajes.

## 📚 Referencias

- [OpenAPI Specification 3.1.0](https://spec.openapis.org/oas/v3.1.0.html)
- [RFC 9457: Problem Details for HTTP APIs](https://www.rfc-editor.org/rfc/rfc9457.html)
- [RFC 9110: HTTP Semantics](https://www.rfc-editor.org/rfc/rfc9110.html)
- [IETF: The Idempotency-Key HTTP Header Field (borrador)](https://datatracker.ietf.org/doc/draft-ietf-httpapi-idempotency-key-header/)
- [hurl: formato del archivo](https://hurl.dev/docs/hurl-file.html) · [aserciones](https://hurl.dev/docs/asserting-response.html) · [opciones de entrada: retry y delay](https://hurl.dev/docs/entry.html)
- [Prism: mocking](https://github.com/stoplightio/prism/blob/main/docs/guides/01-mocking.md) · [validación de peticiones](https://github.com/stoplightio/prism/blob/main/docs/guides/02-request-validation.md) · [cabecera Prefer](https://docs.stoplight.io/docs/prism/83dbbd75532cf-modifying-responses-with-prefer-headers)
- [Swagger UI: instalación con Docker](https://github.com/swagger-api/swagger-ui/blob/main/docs/usage/installation.md)
- [Docker Compose: `up --wait`](https://docs.docker.com/reference/cli/docker/compose/up/) · [`healthcheck`](https://docs.docker.com/reference/compose-file/services/#healthcheck)
- [Imagen oficial de PostgreSQL: scripts de inicialización](https://hub.docker.com/_/postgres) · [`mongoimport`](https://www.mongodb.com/docs/database-tools/mongoimport/)
- [Python: `argparse`](https://docs.python.org/3/library/argparse.html) · [`subprocess`](https://docs.python.org/3/library/subprocess.html)

## 🧠 Preguntas

1. 🟢 ¿Por qué el contrato se escribe antes que cualquier backend en este bloque?
2. 🟢 ¿Qué relación hay entre el `openapi.yaml` y el puerto de entrada del núcleo?
3. 🟢 ¿Qué campos añade este contrato a RFC 9457 y para qué sirve cada uno?
4. 🟢 ¿Por qué el pedido de otro cliente responde `404` y no `403`?
5. 🟢 ¿Por qué `amount` es un `string` y no un número JSON?
6. 🟡 ¿Qué diferencia semántica separa `400`, `409` y `422` en este contrato?
7. 🟡 ¿Qué promete `Idempotency-Key` en `createOrder` y qué pasa si la misma clave llega con otro cuerpo?
8. 🟡 ¿Por qué `/payment` y `/cancel` son `POST` a un sub-recurso y no `PATCH` del estado?
9. 🟡 ¿Por qué `products` e `inventory` son tablas separadas sin clave foránea?
10. 🟡 ¿Qué aserciones de la suite puede pasar el mock y cuáles no puede pasar nunca?
11. 🟠 El mock devolvió `422` a un cuerpo con `lines: []` cuando el contrato promete `400`. ¿Qué está midiendo cada código?
12. 🟠 `up --wait` devolvió el control y la primera petición recibió "connection reset". ¿Qué faltaba y qué lección general deja?
13. 🟠 Un compañero propone que la suite corra los siete archivos en paralelo. ¿Qué rompería y cómo lo rediseñarías para permitirlo?
14. 🟠 ¿Qué cambiaría en el contrato si el catálogo se mudara a MongoDB? Defiende la respuesta.

## 🧪 Ejercicios

1. 🟢 Abre Swagger UI, localiza `authorizePayment` y explica, sin mirar este documento, por qué
   `PAYMENT_PENDING` no vuelve a ser pagable con otra clave.
2. 🟢 Con `Prefer: code=…`, pide al mock cada una de las respuestas de error de `createOrder` y
   comprueba que todas llegan con `Content-Type: application/problem+json` y un `code` del enum.
3. 🟡 Añade a `03-products.hurl` una entrada que pida `limit=1000` y afirme que llegan como mucho
   100 ítems. Decide qué código esperar y justifícalo en un comentario del archivo.
4. 🟡 Corre `seed` y luego la suite dos veces seguidas contra el mock sin volver a sembrar. Explica
   qué archivo fallaría distinto contra un backend real y por qué contra el mock no cambia nada.
5. 🟠 Diseña la entrada de `hurl` que probaría que dos peticiones **concurrentes** de `createOrder`
   con la misma clave crean un solo pedido. Explica por qué `hurl` no puede ejecutarla y qué
   herramienta usarías.
6. 🟠 Quita el `healthcheck` del servicio `mock`, corre `up --mock` seguido de `suite` y documenta el
   fallo con su salida literal. Vuelve a ponerlo.
7. 🔴 Escribe la versión `v2` de `createOrder` en la que `lines` acepta `quantity` decimal para
   productos a granel. Define qué cambia en `Money`, en `OrderLine`, en la suite y **qué no cambia**
   en el núcleo, y argumenta si merece una ruta nueva o una cabecera de versión.
8. 🔥 Sustituye Prism por un mock hecho a mano en Python con `http.server` que respete la
   semántica de `Idempotency-Key` (memoria por clave). Mide cuántos archivos más de la suite pasan y
   cuáles siguen sin poder pasar.

---

**Siguiente:** [02 — Frontend mínimo en React](02-frontend-minimo-react.md) (opcional) o
directamente el sabor que quieras, empezando por [03 — Java y Spring Boot](03-caso-java-spring-boot.md).
