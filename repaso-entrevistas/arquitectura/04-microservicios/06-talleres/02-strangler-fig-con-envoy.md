# 02 — Strangler fig con Envoy

Este taller es **opcional** y depende de [`01` — El monolito y su contrato](01-el-monolito-y-su-contrato.md):
usa su contrato, su suite y su monolito. Pone Envoy delante como único punto de entrada, prepara el
monolito con *branch by abstraction* (rama por abstracción), prueba el atajo de extraer `inventory`
**compartiendo la base** —y lo ve romper el monolito sin que nadie toque su código—, y hace la
extracción buena: `inventory` en Go con su propia base, sus datos migrados y una capa anticorrupción
en el monolito. Termina cuando la suite `v1` está en verde **a través de Envoy** con el inventario
remoto, y la primera llamada remota tiene un timeout que se ha visto funcionar y fallar.

> Ejercita [`01/02` — Descomposición y fronteras](../01-fundamentos-y-descomposicion/02-descomposicion-y-fronteras.md),
> [`01/03` — El camino desde el monolito](../01-fundamentos-y-descomposicion/03-el-camino-desde-el-monolito.md),
> [`01/04` — El monolito distribuido](../01-fundamentos-y-descomposicion/04-el-monolito-distribuido.md),
> [`03/01` — Base de datos por servicio](../03-datos-y-consistencia/01-base-de-datos-por-servicio.md) y
> [`04/02` — API gateway y BFF](../04-operacion-y-resiliencia/02-api-gateway-y-bff.md).
>
> **Vigencia:** 2026-09-29. Versiones verificadas ese día en Docker Hub y en `proxy.golang.org`;
> salidas corridas ese día en macOS con Docker Desktop.

**Salto rápido:** [1](#1--qué-enseña-este-taller) · [2](#2--prerrequisitos-y-versiones) · [3](#3-️-mapa-de-carpetas) · [4](#4--recorrido-de-la-base-de-código) · [5](#5--parte-1-envoy-delante-el-100--al-monolito) · [6](#6--parte-2-la-costura-branch-by-abstraction) · [7](#7--parte-3-el-atajo-de-la-base-compartida) · [8](#8--parte-4-base-propia-migración-y-capa-anticorrupción) · [9](#9--el-primer-timeout) · [10](#10--errores-reales-al-correrlo) · [11](#11--en-tres-plataformas) · [12](#12--teardown) · [Preguntas](#-preguntas) · [Ejercicios](#-ejercicios)

---

## 1. 🎯 Qué enseña este taller

```text
                    antes (06/01)                                   después (06/02)

cliente ──► ms-monolith :28081                cliente ──► Envoy :28080 ──► ms-monolith :28081
               │                                          (JWT, 401/503/504      │ Inventory (interfaz)
               └── ms_monolith                             en problem+json)      │  └ RemoteInventory (ACL)
                   (catalog + inventory +                                        │       │ timeout 800 ms
                    orders + payments)                                           │       ▼
                                                                                 │  Toxiproxy :28183
                                                                                 │       ▼
                                                                                 │  inventory (Go) :28083 ──► ms_inventory
                                                                                 └── ms_monolith (sin inventario vivo)
```

Cuatro ideas, una por parte:

- **Primero la fachada, después la extracción.** Envoy delante con el 100 % del tráfico hacia el
  monolito no cambia nada visible, y precisamente por eso se hace primero: cuando haya algo que
  desviar, la ruta ya existe. Y el borde valida el token, así que lo que no está autenticado no llega
  a ningún servicio.
- **La costura antes que el servicio.** *Branch by abstraction*: el monolito deja de tocar las tablas
  de inventario y habla con una interfaz. Mientras detrás esté la implementación de siempre, la
  suite sigue en verde; cambiar de implementación es cambiar una propiedad.
- **El atajo que sale caro.** Extraer el servicio y dejarlo en la base del monolito parece ahorrar la
  migración. Dura exactamente hasta que el servicio nuevo migra "su" esquema: el monolito cae con
  `column … does not exist` sin que nadie haya cambiado su código. Es el monolito distribuido de
  [`01/04`](../01-fundamentos-y-descomposicion/04-el-monolito-distribuido.md), reproducido.
- **La primera llamada remota nace con timeout, y el timeout no es gratis.** Con el inventario
  a 3 s, el monolito responde `503` en 0,8 s… y deja una retención huérfana en el inventario, porque
  un timeout no es un "no". La corrección es una compensación idempotente.

El precio, en las cinco monedas: **latencia** (cada pedido y cada consulta de catálogo suman un
salto de red), **consistencia** (el pedido y la reserva ya no comparten transacción: hay una
compensación donde antes había un `ROLLBACK`), **operación** (un proceso, una base y un proxy más),
**dinero** (poco en local, una instancia y una base más en producción) y **esfuerzo** (≈ 360 líneas de
Go, ≈ 110 de Java nuevas en el paso final, y un día de trabajo cuidadoso para la migración de datos).

## 2. 🧰 Prerrequisitos y versiones

| Herramienta | Versión fijada | Para qué |
|---|---|---|
| Todo lo de `06/01` | la de `06/01` §2 | contrato, suite, monolito, PSP, PostgreSQL, Toxiproxy |
| `envoyproxy/envoy` | `v1.39.1` | el api-gateway, solo configuración |
| Go | `1.27.1` | el servicio `inventory` |
| `github.com/jackc/pgx/v5` | `v5.11.0` | driver y pool de PostgreSQL para Go; única dependencia directa |

```text
python3 laboratorio/scripts/lab.py up
python3 laboratorio/scripts/lab.py seed
python3 laboratorio/scripts/lab.py psp                                # terminal 1
python3 laboratorio/scripts/lab.py monolith                           # terminal 2 (modo local)
```

- `up` levanta ahora también `ms-envoy` (API en `28080`, consola de administración en `29901`) y
  publica el segundo proxy de Toxiproxy, `inventory` (`28183` → `host.docker.internal:28083`).
- `seed` siembra ahora dos bases: `ms_monolith`, como en `06/01`, y `ms_inventory` con su propio
  esquema (`inventory`, `holds`) y el mismo stock.
- `monolith` arranca por defecto en modo `local` (`--inventory local`): el inventario de siempre,
  detrás de la interfaz nueva.

Las órdenes nuevas de este taller:

```text
python3 laboratorio/scripts/lab.py inventory [--db own|shared] [--port 28083]
python3 laboratorio/scripts/lab.py migrate-inventory
python3 laboratorio/scripts/lab.py monolith --inventory remote [--inventory-timeout MS]
python3 laboratorio/scripts/lab.py slow inventory --latency 3000 | --off
```

- `inventory` compila con `go build -o bin/inventory ./cmd/inventory` y arranca el binario.
  `--db own` (por defecto) lo conecta a `ms_inventory` con el usuario `ms_inventory`; `--db shared`, a
  `ms_monolith` con el usuario del monolito: es el atajo de la parte 3.
- `migrate-inventory` copia inventario y reservas de `ms_monolith` a `ms_inventory` con `dblink`,
  como superusuario, porque ningún usuario de servicio puede conectarse a la base de otro.
  **Sobrescribe** el destino.
- `monolith --inventory remote` arranca el monolito con `ms.inventory.mode=remote`;
  `--inventory-timeout 0` le quita el timeout de lectura hacia el inventario (§9).
- `slow inventory` hace con el proxy `inventory` lo mismo que `psp-slow` con el del proveedor.

> **📝 Contexto:** el código tal como queda al terminar este taller está congelado en
> `laboratorio/estados/02/`, y las rutas con número de línea de este documento se refieren a esa copia.
> Si ya existen talleres posteriores, añade `--estado 02` a cada orden de `lab.py`; para ver el punto
> de partida, `--estado 01`.

## 3. 🗂️ Mapa de carpetas

```text
laboratorio/estados/02/                     (lab.py --estado 02)
├── contrato/
│   ├── docker-compose.yml                  + ms-envoy; + puerto 28183 en ms-toxiproxy
│   ├── envoy/envoy.yaml                    ruta única al monolito, jwt_authn, local_reply_config
│   ├── openapi.yaml                        + INVENTORY_UNAVAILABLE, SERVICE_UNAVAILABLE, GATEWAY_TIMEOUT
│   ├── toxiproxy/proxies.json              + proxy `inventory`
│   └── seed/
│       ├── monolith/schema.sql             inventory_reservations ya sin FK a orders (§6)
│       └── inventory/                      schema.sql · seed.sql · migrate-from-monolith.sql
├── inventory/                              el servicio extraído, Go
│   ├── cmd/inventory/main.go               pool, migración al arrancar, servidor, apagado ordenado
│   └── internal/
│       ├── store/                          migrate.go (el esquema, y el RENAME que rompe) · store.go
│       └── api/api.go                      GET /stock · POST /holds · /holds/{ref}/release|commit
└── monolith/src/main/java/dev/ms/monolith/
    ├── inventory/                          Inventory (la costura) · LocalInventory · RemoteInventory (ACL)
    └── service/                            CatalogService y OrderService hablan con Inventory
```

## 4. 🔎 Recorrido de la base de código

Rutas relativas a `laboratorio/estados/02/`.

**¿Quién decide qué inventario se usa?** Nadie en el código de negocio. `inventory/LocalInventory.java`
lleva `@ConditionalOnProperty(name = "ms.inventory.mode", havingValue = "local", matchIfMissing = true)`
(línea 21) y `inventory/RemoteInventory.java` el mismo con `havingValue = "remote"` (línea 26): Spring
crea una u otra, y `CatalogService` y `OrderService` reciben un `Inventory` sin saber cuál.

**¿Dónde vive la traducción entre los dos modelos?** En `RemoteInventory.java` y solo ahí: los
`record` privados (`StockItem`, `HoldRequest`, `OutOfStock`) son la forma de las respuestas del
servicio, y `translate` (línea 79) convierte un `OUT_OF_STOCK` con su lista de faltantes en el
`InsufficientInventory` con índice de línea que promete el contrato.

**¿Dónde nace el timeout?** `RemoteInventory.java`, línea 45: `factory.setReadTimeout(...)` con
`ms.inventory.read-timeout-ms` (800 ms en `application.yaml`). Un `0` lo desactiva: es la palanca de §9.

**¿Qué hace Envoy con cada petición?** `contrato/envoy/envoy.yaml`: la ruta única `prefix: "/"`
(línea 56) al clúster `monolith`; el filtro `jwt_authn` con la clave HS256 del monolito como JWK
simétrica, `forward_payload_header: x-jwt-payload` (línea 71) y la regla que exige token en `/api/`
salvo el login (línea 76); `local_reply_config` (línea 20) para que lo que responde el propio Envoy
cumpla el contrato; y `dns_lookup_family: V4_ONLY` (línea 86), que tiene su historia en §10.

**¿Qué hace `inventory` al arrancar?** `inventory/internal/store/migrate.go`: crea sus tablas si no
existen y, si encuentra la columna vieja `available`, la renombra a `on_hand` (línea 21). En su base
es lo correcto; en la del monolito, es la parte 3.

## 5. 🔀 Parte 1: Envoy delante, el 100 % al monolito

**Qué es.** El *strangler fig* (higuera estranguladora) empieza por la fachada: un proxy que recibe
todo y, de momento, lo manda todo al monolito. Cada extracción posterior añade una ruta más específica
encima de la general, y el cliente no se entera
([`01/03`](../01-fundamentos-y-descomposicion/03-el-camino-desde-el-monolito.md)).

**Cómo va.** La ruta es una línea; lo interesante es lo que se hace **en** el borde:

```yaml
- name: envoy.filters.http.jwt_authn
  typed_config:
    providers:
      ms_monolith:
        local_jwks:
          inline_string: '{"keys":[{"kty":"oct","alg":"HS256","k":"bXMtbGFiLWRldi1zZWNyZXQtY2hhbmdlLW1lLTAxMjM0NTY3ODk"}]}'
        forward: true
        forward_payload_header: x-jwt-payload
    rules:
      - match: { prefix: "/health" }
      - match: { path: "/api/v1/auth/login" }
      - match: { prefix: "/api/" }
        requires: { provider_name: ms_monolith }
```

- `local_jwks` con una clave `oct` (simétrica): es el mismo secreto HS256 con el que firma el
  monolito, en base64url. En producción sería un JWKS de claves públicas servido por el emisor; con
  HS256, el gateway **puede firmar tokens** además de verificarlos, y eso se dice.
- `forward: true` deja el `Authorization` en la petición: el monolito sigue verificándolo (defensa en
  profundidad) y `forward_payload_header` añade el contenido ya verificado en `x-jwt-payload`, para
  los servicios que decidan confiar en el borde (lo usa `orders` desde el [taller 04](04-grpc.md)).
- Las reglas se evalúan en orden: salud y login pasan sin token; todo lo demás bajo `/api/` lo exige.

**La suite a través de Envoy** cambia solo la URL base:

```text
python3 laboratorio/scripts/lab.py suite --base-url http://localhost:28080
```

La primera vez no pasó (dos errores reales, §10). Tras corregirlos, 2026-09-29:

```text
Success 01-health.hurl (1 request(s) in 4 ms)
Success 02-auth.hurl (5 request(s) in 163 ms)
Success 03-products.hurl (4 request(s) in 106 ms)
Success 04-orders.hurl (16 request(s) in 263 ms)
Success 05-payment.hurl (12 request(s) in 2192 ms)
Success 06-cancel.hurl (8 request(s) in 179 ms)
Executed requests: 46 (15.8/s)
Succeeded files:   6 (100.0%)
```

Y el access log dice quién respondió cada cosa: `upstream=-` es el propio Envoy.

```text
05:53:27 POST /api/v1/auth/login → 200 96ms upstream=192.168.65.254:28081 via_upstream
05:53:28 GET /api/v1/orders → 401 0ms upstream=- jwt_authn_access_denied{Jwt_is_missing}
05:53:28 GET /api/v1/orders → 401 0ms upstream=- jwt_authn_access_denied{Jwt_verification_fails}
05:53:28 GET /api/v1/orders → 200 13ms upstream=192.168.65.254:28081 via_upstream
```

> **Veredicto:** la fachada cuesta un contenedor y cien líneas de YAML, y compra el sitio donde
> ocurrirá cada extracción. Validar el token en el borde quita trabajo a los servicios, pero obliga al
> borde a hablar el idioma de errores del contrato: un `401` en texto plano rompe al cliente igual que
> un bug.

## 6. 🧱 Parte 2: la costura (branch by abstraction)

**Qué es.** Antes de sacar nada, el monolito deja de tocar el inventario directamente y pasa a
hablar con una interfaz; la implementación de siempre se muda detrás de ella sin cambiar su
comportamiento. Después, otra implementación puede sustituirla cambiando una propiedad
([Fowler, *Branch By Abstraction*](https://martinfowler.com/bliki/BranchByAbstraction.html)).

```java
public interface Inventory {
    record Line(String sku, int quantity) {}
    Map<String, Integer> stockOf(Collection<String> skus);
    void reserve(UUID orderId, List<Line> lines);   // todo o nada; InsufficientInventory con el índice
    void release(UUID orderId);                     // idempotente
    void consume(UUID orderId);                     // idempotente
}
```

- La interfaz está escrita en el idioma **del monolito** (disponible, reserva por pedido), no en el
  del futuro servicio: es la frontera que el resto del código ve.
- `release` y `consume` son idempotentes a propósito: cuando la implementación sea remota, se van a
  reintentar y a llamar como compensación.

Tres cambios que la costura obligó a hacer, y que son el trabajo real de esta parte:

- **Fuera los `JOIN`.** `ProductRepository` perdió sus tres consultas `products JOIN inventory`;
  `CatalogService` lee productos y pide el stock a `Inventory`. `CatalogService` perdió además su
  `@Transactional` de clase: si el stock viene de la red, la llamada no debe retener una conexión
  (lección de `06/01`).
- **La reserva sale de la transacción del pedido.** `OrderService.create` reserva primero y guarda el
  pedido después, en una transacción corta; si el guardado falla, compensa con `release`. Con una sola
  base no hacía falta; con dos, no hay otra forma.
- **Se corta la FK que cruzaba la frontera.** `inventory_reservations.order_id` apuntaba a `orders`.
  Con la reserva antes que el pedido, esa FK falla siempre; y cuando las reservas vivan en otra base,
  no podrá existir. Se quita del esquema.

La suite, contra el monolito en modo `local`, 2026-09-29: 6/6 archivos, 46 peticiones. Y el cambio,
medido entre dos instantáneas del código:

```text
$ git diff --no-index --stat s0/src s1/src
 config/TxConfig.java                   | 13 +++
 inventory/Inventory.java               | 26 ++++++
 inventory/LocalInventory.java          | 69 ++++++++++++++++
 repository/InventoryRepository.java    | 11 +++
 repository/ProductRepository.java      | 40 +---------
 service/CatalogService.java            | 23 ++++--
 service/OrderService.java              | 92 ++++++++++------------
 service/PaymentService.java            | 11 +--
 resources/application.yaml             |  2 +
 9 files changed, 184 insertions(+), 103 deletions(-)
```

- `OrderService` es el que más cambia, y no por la interfaz: por el orden reserva → pedido y la
  compensación. Es el primer síntoma de que partir datos cambia el flujo, no solo el acceso.

> **Veredicto:** la costura cuesta ≈ 180 líneas y ningún cambio visible, y es lo que hace barata la
> parte 4. Saltársela para "ir más rápido" es lo que lleva al atajo de la parte 3.

## 7. 🧨 Parte 3: el atajo de la base compartida

**El síntoma.** Un equipo extrae `inventory` a Go y, para no migrar datos todavía, lo conecta a la
base del monolito. El servicio arranca, responde bien, y a los pocos segundos **el catálogo y el alta
de pedidos del monolito devuelven `500`**. Nadie tocó el monolito.

```text
python3 laboratorio/scripts/lab.py inventory --db shared
```

- `--db shared` conecta el servicio a `ms_monolith` con el usuario del monolito. Al arrancar, aplica
  su migración, que incluye `ALTER TABLE inventory RENAME COLUMN available TO on_hand`.

Salida literal, 2026-09-29, con el monolito corriendo en modo `local`:

```text
--- antes
  Column   |  Type   | Collation | Nullable | Default
-----------+---------+-----------+----------+---------
 sku       | text    |           | not null |
 available | integer |           | not null |
2026/09/29 00:56:45 schema applied on localhost/ms_monolith
2026/09/29 00:56:45 inventory listening on :28083
--- después
 Column  |  Type   | Collation | Nullable | Default
---------+---------+-----------+----------+---------
 sku     | text    |           | not null |
 on_hand | integer |           | not null |

Success 01-health.hurl (1 request(s) in 10 ms)
Success 02-auth.hurl (5 request(s) in 177 ms)
Failure 03-products.hurl (2 request(s) in 100 ms)
Failure 04-orders.hurl (2 request(s) in 111 ms)
Failure 05-payment.hurl (2 request(s) in 100 ms)
Failure 06-cancel.hurl (2 request(s) in 92 ms)
```

```text
WARN … ERROR: column ii1_0.available does not exist
```

Y el servicio nuevo, mientras tanto, perfecto:

```text
$ curl "localhost:28083/stock?sku=SKU-001&sku=SKU-004"
{"items":[{"sku":"SKU-001","onHand":20},{"sku":"SKU-004","onHand":0}]}
```

**La cadena y la causa:**

```text
inventory arranca contra ms_monolith
   │ su migración renombra una columna "suya"
   ▼
LocalInventory (monolito) lee inventory.available
   │ la columna ya no existe
   ▼
catálogo y alta de pedidos → 500, sin un solo cambio de código en el monolito
```

- Los dos equipos hicieron lo correcto **para su propio código**. El error es de diseño: dos procesos
  con la misma tabla ya no pueden desplegarse por separado, que es la definición de monolito
  distribuido. La base compartida "solo mientras migramos" dura lo que tarda alguien en migrar un
  esquema que cree suyo.
- La corrección no es "coordinar mejor las migraciones": es que la tabla tenga **un solo dueño**. Se
  deshace con `lab.py seed`, que recrea el esquema del monolito.

> **Veredicto:** compartir la base al extraer ahorra la migración de datos y la paga con el
> despliegue independiente, que era el motivo de extraer. Si el servicio no puede tener su base
> todavía, todavía no es un servicio.

## 8. 🔀 Parte 4: base propia, migración y capa anticorrupción

**Qué es.** `inventory` con su base (`ms_inventory`, con usuario propio que no puede leer la del
monolito), los datos copiados, y el monolito usando `RemoteInventory` detrás de la misma interfaz.

**La migración, con datos vivos.** Se crea un pedido en modo `local` (dos teclados reservados), se
migra, se cambia a `remote` y se cancela ese pedido: si la reserva migró bien, el stock vuelve.

```text
python3 laboratorio/scripts/lab.py migrate-inventory
python3 laboratorio/scripts/lab.py inventory                          # --db own
python3 laboratorio/scripts/lab.py monolith --inventory remote
```

- `migrate-inventory` ejecuta `seed/inventory/migrate-from-monolith.sql`: `TRUNCATE` del destino,
  `INSERT … SELECT … FROM dblink(...)` de `inventory` (renombrando `available` a `on_hand`) y de
  `inventory_reservations` (mapeando `RESERVED` → `HELD`), y un recuento final.

Salida literal, 2026-09-29:

```text
pedido vivo: 159a65f0-ac76-4d1c-ab69-2a8a4e0e5d20
--- migración
INSERT 0 5
INSERT 0 1
 skus | units | holds
------+-------+-------
    5 |   126 |     1
--- stock de SKU-001 por Envoy (viene de inventory)
{"sku":"SKU-001","name":"Mechanical keyboard","unitPrice":{"amount":"49.90","currency":"USD"},"stock":18}
--- cancelar el pedido creado ANTES de la migración
159a65f0-ac76-4d1c-ab69-2a8a4e0e5d20 CANCELLED
{"sku":"SKU-001","name":"Mechanical keyboard","unitPrice":{"amount":"49.90","currency":"USD"},"stock":20}
              reference               |   sku   | qty |  status
--------------------------------------+---------+-----+----------
 159a65f0-ac76-4d1c-ab69-2a8a4e0e5d20 | SKU-001 |   2 | RELEASED
```

- 126 unidades = 128 de la semilla − 2 reservadas: la reserva viva viajó como retención, con el id
  del pedido como referencia. La cancelación, ya por la red, la liberó.
- La verificación que vale no es el recuento: es **operar** un dato migrado por el camino nuevo.

**La capa anticorrupción.** `inventory` habla su idioma —stock en mano, retenciones, `OUT_OF_STOCK`
con faltantes— y el monolito el suyo. La traducción está en un solo sitio:

```java
.onStatus(s -> s.value() == HttpStatus.CONFLICT.value(), (req, res) -> {
    var oos = new JsonMapper().readValue(res.getBody(), OutOfStock.class);
    throw translate(oos, lines);          // OUT_OF_STOCK + shortages → InsufficientInventory(lines[i])
})
```

- El servicio no sabe qué es una "línea de pedido"; el contrato del monolito promete
  `lines[1].quantity`. `translate` busca el índice. Si mañana `inventory` cambia su formato de error,
  cambia esta clase y nada más.

**La suite a través de Envoy, con el inventario en Go**, 2026-09-29:

```text
Success 01-health.hurl (1 request(s) in 7 ms)
Success 02-auth.hurl (5 request(s) in 366 ms)
Success 03-products.hurl (4 request(s) in 190 ms)
Success 04-orders.hurl (16 request(s) in 441 ms)
Success 05-payment.hurl (12 request(s) in 2264 ms)
Success 06-cancel.hurl (8 request(s) in 197 ms)
Executed requests: 46 (13.2/s)
Succeeded files:   6 (100.0%)
Duration:          3474 ms (0h:0m:3s:474ms)
```

**El cambio de la costura a la extracción**, entre instantáneas:

```text
$ git diff --no-index --stat s1/src s2/src
 config/MsProperties.java           |  3 +-
 inventory/RemoteInventory.java     | 95 ++++++++++++++++++++++++
 service/Errors.java                |  3 ++
 web/ApiErrors.java                 |  6 +++
 resources/application.yaml         |  3 ++
 5 files changed, 109 insertions(+), 1 deletion(-)
```

- Ni `CatalogService` ni `OrderService` aparecen: la extracción fue **añadir** una implementación, un
  error nuevo (`INVENTORY_UNAVAILABLE`) y su traducción. Eso es lo que compró la parte 2. (La
  compensación de §9 se añadió después y toca `OrderService`: es la excepción que confirma la regla,
  porque no es acceso a datos sino flujo.)

> **Veredicto:** con la costura hecha, extraer es añadir. Sin la costura, extraer es reescribir el
> monolito por el camino, y es el motivo más común de que un strangler se quede a medias.

## 9. 🧨 El primer timeout

**Con timeout (800 ms), el inventario a +3 s:**

```text
python3 laboratorio/scripts/lab.py slow inventory --latency 3000
```

```text
{"instance":"/api/v1/orders","status":503,"title":"Inventory unavailable","code":"INVENTORY_UNAVAILABLE"}
→ 503 en 0.829440s
--- inventory, 4 s después
              reference               |   sku   | qty | status
--------------------------------------+---------+-----+--------
 9f234601-440d-4762-85ba-73aba3a18979 | SKU-001 |   1 | HELD
 on_hand
---------
      19
 pedidos
---------
       0
```

- El cliente recibió un error rápido y claro. **Y el inventario retuvo una unidad para un pedido que no
  existe**: el tóxico retrasa la *respuesta*, la petición llegó y se procesó. Un timeout sobre una
  escritura remota es un resultado incierto, igual que el `666.00` del proveedor en `06/01`.

**La corrección**: si la reserva no responde, compensar con `release` por la misma referencia
(`OrderService.java`, líneas 61–69), que es idempotente. Misma prueba tras el cambio:

```text
→ 503 en 1.706450s
--- inventory, 4 s después
              reference               |   sku   | qty |  status
--------------------------------------+---------+-----+----------
 6bb349e5-3fc2-4851-9395-1a544e94c7f6 | SKU-001 |   1 | RELEASED
 on_hand
---------
      20
```

- El precio es visible: 1,7 s en vez de 0,8 (dos llamadas que expiran). Y la compensación no es
  infalible: si el `release` llegara **antes** que la retención, la retención quedaría huérfana. La
  red de seguridad de verdad es que las retenciones caduquen, que es la autopsia del [taller 09](09-saga-orquestada.md).

**Sin timeout** (`monolith --inventory remote --inventory-timeout 0`):

```text
POST /orders → 201 en 3.166135s
GET /products → 200 en 3.033201s
GET /products con +12 s → 504 en 10.005427s
{"code":"GATEWAY_TIMEOUT","detail":"UT","instance":"/api/v1/products","status":504,"title":"Gateway timeout","type":"about:blank"}
```

- La latencia del inventario **es** la latencia de todo lo que lo llama, catálogo incluido.
- A 12 s, el timeout que manda es el de la ruta de Envoy (10 s): el cliente recibe un `504` y el
  monolito **sigue esperando** al inventario, trabajando para una respuesta que nadie leerá. Sin
  timeout propio, el plazo lo pone el componente más lejano, y no avisa a los de en medio.

> **Veredicto:** el timeout en la primera llamada remota no es opcional, y viene con su
> obligación: decidir qué significa "no sé" para esa operación. Para una lectura, un error; para una
> escritura, una compensación idempotente y, al final, una caducidad.

## 10. 🩺 Errores reales al correrlo

Cuatro, en el orden en que aparecieron.

### Envoy no alcanzaba el monolito: `host.docker.internal` resolvió a IPv6

```text
POST /api/v1/auth/login → 503 UF 0ms cluster=monolith
monolith::[fdc4:f303:9324::254]:28081::cx_connect_fail::6
```

`host.docker.internal` tiene dirección IPv4 e IPv6 dentro del contenedor; la familia DNS por defecto
de un clúster `STRICT_DNS` de Envoy prefiere la v6 cuando existe, y el monolito no era alcanzable por
ahí. `UF` (*upstream connection failure*) en el access log y `cx_connect_fail` en `/clusters` lo
dicen sin ambigüedad. **Corrección:** `dns_lookup_family: V4_ONLY` en el clúster
([`Cluster.dns_lookup_family`](https://www.envoyproxy.io/docs/envoy/v1.39.1/api-v3/config/cluster/v3/cluster.proto#envoy-v3-api-field-config-cluster-v3-cluster-dns-lookup-family)).
**Lección:** ante un `503` del gateway, lo primero es la consola de administración (`/clusters`), no
los logs del servicio: el servicio ni se enteró.

### El `401` de Envoy no era el del contrato

```text
HTTP/1.1 401 Unauthorized
content-type: text/plain

Jwt is missing
```

La suite lo cazó en `02-auth.hurl`: `HTTP response is not a valid JSON`. El filtro JWT responde en
texto plano; el contrato promete `problem+json` con `code: UNAUTHENTICATED`. **Corrección:**
`local_reply_config` con un *mapper* por código, que reescribe solo las respuestas generadas por el
propio Envoy ([local reply](https://www.envoyproxy.io/docs/envoy/v1.39.1/configuration/http/http_conn_man/local_reply)).
**Lección:** mover una responsabilidad al gateway mueve también su contrato de errores.

### La retención huérfana tras el timeout

Descrita en §9. **Lección:** "falló por timeout" y "no ocurrió" son afirmaciones distintas. Toda
escritura remota con timeout necesita decidir qué hace con el "no sé".

### El `504` de Envoy también salía en texto plano

```text
upstream request timeout
GET /products con +12 s → 504 en 10.005427s
```

Mismo problema que el `401`, con otro código: el primer *mapper* solo cubría `401` y `503`.
**Corrección:** un *mapper* para `504` con `code: GATEWAY_TIMEOUT`. **Lección:** los errores del
gateway se enumeran todos o aparecen de uno en uno en producción.

## 11. 🧰 En tres plataformas

| Plataforma | Qué te da hecho | Lo que te deja a ti |
|---|---|---|
| **Java** | La costura casi gratis: interfaz + dos implementaciones + `@ConditionalOnProperty`; `RestClient` con `setReadTimeout` | Que las implementaciones sean intercambiables de verdad (misma semántica de errores e idempotencia), y la traducción de la ACL |
| **Go** | `net/http` con rutas por método y comodín (`POST /holds/{reference}/release`) sin router externo; `pgxpool` con límite por defecto `max(4, núcleos)` | La migración, el apagado ordenado y la idempotencia, escritos a mano y visibles: ≈ 360 líneas para cuatro rutas |
| **Python** | La misma costura con un `Protocol` y dos clases; `httpx` con `timeout=` por petición | Que el timeout se ponga siempre: en `httpx` hay un valor por defecto de 5 s, en `requests` no hay ninguno |

La fila de Node/TS —`fetch` sin timeout propio por petición (el de undici, por defecto, es de 300 s) y `AbortSignal.timeout()` para ponerlo— está en
[`02/02`](../02-comunicacion/02-http-entre-servicios.md).

## 12. 🧹 Teardown

```text
Ctrl+C en las terminales de psp, monolith e inventory
python3 laboratorio/scripts/lab.py down
```

- `down` borra también `ms-envoy` y los volúmenes: las dos bases se recrean desde cero en el taller
  03. `lab.py seed` ya siembra `ms_inventory`, así que el taller 03 arranca con el inventario remoto
  sin repetir la migración.

## ⚠️ Errores frecuentes

| Se dice | Lo preciso |
|---|---|
| "Primero compartimos la base y luego migramos los datos" | Mientras la base sea compartida, los dos no se despliegan por separado; el primer cambio de esquema lo demuestra |
| "El strangler empieza extrayendo un servicio" | Empieza por la fachada y la costura; la extracción es el tercer paso y, bien preparada, el más corto |
| "El gateway valida el token, los servicios ya no tienen que hacerlo" | Pueden confiar en el borde si la red interna está cerrada; defensa en profundidad es seguir verificando, y con HS256 el borde además puede firmar |
| "Con timeout, un fallo remoto es un fallo" | Es un "no sé": la operación pudo ocurrir. En escrituras hace falta compensar o reconciliar |
| "Sin timeout no pasa nada, ya corta el gateway" | Corta la respuesta al cliente, no el trabajo de dentro: el servicio intermedio sigue esperando para nadie |
| "La capa anticorrupción es una clase de DTO" | Es traducir modelo y semántica —errores, estados, identificadores— en un solo sitio para que ninguno contamine al otro |

## 📚 Para profundizar

- **Libro** — Sam Newman, *Monolith to Microservices*, O'Reilly, 2019, cap. 3 ("Splitting the
  Monolith": strangler fig, branch by abstraction) y cap. 4 ("Decomposing the Database").
- **Libro** — Eric Evans, *Domain-Driven Design*, Addison-Wesley, 2003, cap. 14, la capa
  anticorrupción.
- **Documentación** — Envoy v1.39.1: [JWT authentication](https://www.envoyproxy.io/docs/envoy/v1.39.1/configuration/http/http_filters/jwt_authn_filter)
  · [local reply](https://www.envoyproxy.io/docs/envoy/v1.39.1/configuration/http/http_conn_man/local_reply)
  · [access log](https://www.envoyproxy.io/docs/envoy/v1.39.1/configuration/observability/access_log/usage).
- **Documentación** — [`pgxpool`](https://pkg.go.dev/github.com/jackc/pgx/v5/pgxpool) · [`net/http.ServeMux`](https://pkg.go.dev/net/http#ServeMux)
  · [PostgreSQL 17: `dblink`](https://www.postgresql.org/docs/17/dblink.html).
- **Fuente primaria** — [Fowler, *Strangler Fig Application*](https://martinfowler.com/bliki/StranglerFigApplication.html)
  · [Fowler, *Branch By Abstraction*](https://martinfowler.com/bliki/BranchByAbstraction.html)
  · [microservices.io: *Anti-corruption layer*](https://microservices.io/patterns/refactoring/anti-corruption-layer.html).

## 🧠 Preguntas

1. ¿Por qué se pone Envoy delante antes de extraer nada, si al principio no cambia ninguna ruta? 🟢
2. ¿Qué hace `forward_payload_header` y quién puede usar ese encabezado? 🟢
3. ¿Qué es *branch by abstraction* y qué papel juega `ms.inventory.mode`? 🟢
4. ¿Por qué `release` y `consume` tienen que ser idempotentes? 🟢
5. ¿Por qué hubo que quitar la FK de `inventory_reservations.order_id` a `orders`? 🟡
6. ¿Qué diferencia hay entre el `401` que devolvía Envoy y el del monolito, y por qué importa al cliente? 🟡
7. En la parte 3, ¿quién cometió el error: el equipo del monolito o el de inventory? 🟡
8. ¿Qué te da Go para escribir `inventory` sin router ni framework, y qué te obliga a escribir a mano? 🟡
9. ¿Por qué la migración se verifica operando un dato migrado y no solo contando filas? 🟡
10. El timeout de 800 ms devolvió `503` en 0,8 s y dejó una retención huérfana. Explica por qué y qué cuesta la corrección. 🟠
11. Sin timeout propio, ¿quién corta la espera y qué queda trabajando? 🟠
12. ¿Extraerías `catalog` en este sistema? Argumenta con lo que costó `inventory`. 🟠
13. Dibuja el flujo de `POST /api/v1/orders` en modo `remote`, con la transacción, la llamada, la compensación y los tres resultados posibles de la reserva. 🔴
14. En producción, tras desplegar un servicio extraído, otro servicio empieza a fallar con `column … does not exist`. Da la causa probable, cómo la confirmas y qué cambiarías en el proceso para que no vuelva a pasar. 🔴
15. Tu equipo va a extraer `payments` siguiendo el camino de este taller. Escribe los pasos en orden —fachada, costura, datos, primera llamada remota— y, para cada uno, la prueba que te dice que puedes pasar al siguiente. 🔴

## 🧪 Ejercicios

1. 🟢 Añade a `envoy.yaml` un *mapper* para `403` con `code: FORBIDDEN` y demuestra con `curl` que
   solo afecta a respuestas del propio Envoy y no a un `403` del monolito.
2. 🟢 **Orientación en código ajeno.** Encuentra, con ruta y línea, dónde decide el servicio
   `inventory` que una retención repetida no vuelve a descontar stock, y qué código HTTP devuelve en
   ese caso.
3. 🟡 Corre `lab.py inventory --db shared` con el monolito en modo `remote` en vez de `local`. ¿Se
   rompe algo? ¿Por qué eso no convierte la base compartida en una buena idea?
4. 🟡 Mide con `storm` (del taller 01) cuánto añade el salto de red al alta de pedidos: pedidos en
   modo `local` frente a `remote`, con la cifra etiquetada como reproducción local.
5. 🟠 Da a `catalog` el mismo tratamiento hasta la parte 2 (interfaz y dos implementaciones, sin
   servicio). ¿Qué consultas del monolito cruzan hoy el catálogo y qué te dice eso sobre su frontera?
6. 🔴 Haz que las retenciones de `inventory` caduquen: columna `expires_at` y un proceso que libere las
   vencidas cada 30 s. Repite la prueba de la retención huérfana sin la compensación del monolito y
   pega la salida.
7. 🔴 Añade a Envoy una ruta que mande el 10 % de `GET /api/v1/products` a una segunda instancia del
   monolito (`--port 28091`) y demuestra el reparto con el access log. ¿Qué tendría que ser verdad
   para hacer esto con el alta de pedidos?
8. 🔥 Sustituye `RemoteInventory` por un cliente generado a partir de un `openapi.yaml` de `inventory`
   escrito por ti. ¿Dónde queda ahora la capa anticorrupción?

---

**Anterior:** [`01` — El monolito y su contrato](01-el-monolito-y-su-contrato.md). **Siguiente:**
[`03` — HTTP entre servicios](03-http-entre-servicios.md). **Relacionado:**
[`03/01` — Base de datos por servicio](../03-datos-y-consistencia/01-base-de-datos-por-servicio.md).
