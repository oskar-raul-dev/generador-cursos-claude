# 01 — Heredar el legado

Este taller es **opcional**, como todo el bloque `06-talleres/`, y es el primero: no depende de
ningún otro y todos los demás dependen de él. Levanta `mono-legacy` —una tienda en Spring Boot que
funciona, pero que se escribió sin organización: sin README útil, sin contrato, con los errores
escondidos en un `200`— y te pide lo que te pedirán el primer día en un equipo nuevo: **en una hora,
saber qué hace, dónde y con qué datos**. Termina cuando el mapa de rutas y tablas está reconstruido y
contrastado con tráfico real, y cuando has visto una compra «normal» responder `200` sin crear nada.

> Ejercita [`01/01` — Qué es una arquitectura monolítica](../01-fundamentos-y-modelo-mental/01-que-es-una-arquitectura-monolitica.md),
> [`01/03` — Monolito tradicional, modular y *big ball of mud*](../01-fundamentos-y-modelo-mental/03-monolito-tradicional-modular-y-big-ball-of-mud.md) y
> [`05/03` — Recuperar modularidad en un monolito legado](../05-decision-evolucion-y-practica/03-recuperar-modularidad-en-un-monolito-legado.md).
> Las reglas del bloque están en §11 y §12 de la [guía de estilo](../prompts/guia-de-estilo-y-convenciones.md).
>
> **Vigencia:** 2026-09-29. Imágenes y versiones verificadas ese día en Docker Hub, GitHub Releases y
> Maven Central; salidas corridas ese día en macOS con Docker Desktop.

**Salto rápido:** [1](#1--qué-enseña-este-taller) · [2](#2--prerrequisitos-y-versiones) · [3](#3-️-mapa-de-carpetas) · [4](#4--recorrido-de-la-base-de-código) · [5](#5--levantar-el-legado) · [6](#6--arqueología-de-rutas) · [7](#7--la-regla-de-pago-vive-en-un-if) · [8](#8--quién-escribe-cada-tabla) · [9](#9--provocación-200-y-el-pedido-no-existe) · [10](#10--evidencia-el-mapa-reconstruido) · [11](#11--errores-reales-al-construirlo) · [12](#12--plataformas) · [13](#13--teardown) · [Preguntas](#-preguntas) · [Ejercicios](#-ejercicios)

---

## 1. 🎯 Qué enseña este taller

El perfil senior suele tener una dificultad concreta: **tomar una base de código que no escribió y
orientarse rápido**. No se resuelve leyendo todo; se resuelve con un orden de lectura y con
evidencia. Este taller entrena ese orden sobre un legado hecho feo a propósito.

```text
lab.py api ──► http://localhost:38081 ──► mono-legacy ──► mono_legacy (PostgreSQL :35432)
 (tu tráfico)        (sin contrato)          │                 └─ trigger orders_restore_stock
                                             └──► Toxiproxy :38185 ──► psp-simulator :38085
                                                                          (el banco)
```

Tres ideas, una por parte:

- **Las rutas se reconstruyen desde tres fuentes que se contradicen.** El código dice qué rutas
  existen; el tráfico dice qué responden de verdad; la base dice qué dejaron escrito. Ninguna basta
  sola, y el mapa solo vale cuando las tres coinciden.
- **Las reglas no están donde se espera.** La regla de pago vive en un `if` de un servicio; la de
  cancelación, en un controlador; y la devolución del stock, en un *trigger* de PostgreSQL que ningún
  archivo Java menciona.
- **Un `200` no significa éxito.** El legado responde `200` también cuando no hizo nada. Es el primer
  síntoma de que no tiene contrato, y el material de los talleres 02 a 04.

El precio es honesto: un legado de unas 1 100 líneas de Java que nadie escribiría así a propósito, y
una hora de arqueología antes de cambiar una línea. Lo que compra es que, desde aquí, cada taller
modifica un sistema que ya conoces por evidencia, no por intuición.

## 2. 🧰 Prerrequisitos y versiones

| Herramienta | Versión fijada | Para qué |
|---|---|---|
| Docker (Desktop o Engine) con Compose v2 | `29.8.0` | PostgreSQL y Toxiproxy |
| `postgres` | `17.11-alpine` | la base del legado, `mono_legacy` |
| `ghcr.io/shopify/toxiproxy` | `2.12.0` | latencia y cortes delante del proveedor de pago |
| JDK | `25.0.4` (Temurin) | compilar y correr `mono-legacy` |
| Spring Boot | `4.1.1` | el framework del legado |
| `org.xerial:sqlite-jdbc` | `3.53.2.1` (gestionado por Boot 4.1.1) | las pruebas que el legado ya traía |
| `org.hibernate.orm:hibernate-community-dialects` | `7.4.5.Final` | el dialecto de SQLite para esas pruebas |
| Maven | `3.9.10` | construir |
| `hurl` | `8.0.1` | la suite de caracterización (desde el taller 03) |
| Python | `3.13.4` | `lab.py` y `psp-simulator`, solo biblioteca estándar |

```bash
python3 laboratorio/scripts/lab.py check
```

- `check` comprueba que Docker, `hurl`, Maven y el JDK 25 estén instalados; no instala nada.

```text
docker   Docker version 29.8.0, build 88096ef
hurl     hurl 8.0.1 (x86_64-apple-darwin25.0) libcurl/8.7.1 (SecureTransport) LibreSSL/3.3.6 zlib/1.2.12 nghttp2/1.68.1
mvn      Apache Maven 3.9.10 (5f519b97e944483d878815739f519b2eade0a91d)
java     openjdk version "25.0.4" 2026-07-21 LTS
python   3.13.4
```

Nombres, puertos y credenciales son los de §12 de la guía: prefijo `mono-`, puertos `3xxxx`,
`mono-legacy` en `38081`, `mono-postgres` en `35432` y el proxy del PSP en `38185`. Los usuarios
semilla son `ana@mono.local` / `ana-12345` (cliente) y `ops@mono.local` / `ops-12345` (operador).

## 3. 🗂️ Mapa de carpetas

```text
06-talleres/laboratorio/
├── contrato/
│   ├── docker-compose.yml     PostgreSQL y Toxiproxy (proyecto mono-lab)
│   ├── seed/seed.sql          vacía las tablas y carga usuarios y productos
│   └── toxiproxy/proxies.json el proxy psp: :38185 → host:38085
├── legacy/                    mono-legacy, Java 25 + Spring Boot 4.1.1
│   └── src/main/java/dev/mono/legacy/
│       ├── controller/        seis controladores; devuelven Object
│       ├── service/           reglas, pago, cierre diario
│       ├── repository/        interfaces JPA
│       ├── entity/            las mismas clases van a la base y al JSON
│       ├── config/            seguridad, cliente del PSP, SchemaFixer
│       └── util/              LegacyException, caché en memoria, tokens revocados
├── psp-simulator/             el banco: Python sin dependencias
├── scripts/lab.py             la orquestación del bloque
└── estados/01/                el laboratorio tal como queda al cerrar este taller
```

El legado está **organizado por capa técnica**, no por capacidad: `orders`, `inventory`, `payments`
y `notifications` están repartidas por todas las carpetas. Es a propósito, y es el material del
taller 06.

## 4. 🔎 Recorrido de la base de código

Antes de levantar nada, cuatro preguntas con su respuesta en el código. Las rutas citan
`laboratorio/estados/01/`, que no cambia aunque los talleres siguientes modifiquen el legado.

| Pregunta | Dónde está la respuesta |
|---|---|
| ¿Por dónde entra una compra? | `legacy/src/main/java/dev/mono/legacy/controller/OrderController.java:40`, que llama a `OrderService.create` |
| ¿Dónde se abre la transacción? | `service/OrderService.java` en `create` y `cancel`; `service/PaymentService.java:33` en `pay`, **y la llamada al banco está dentro** (`:52`) |
| ¿Qué configuración pisa a cuál? | `legacy/src/main/resources/application.yaml`: `ddl-auto: update` crea el esquema; `allow-circular-references: true` deja arrancar un ciclo de beans; los secretos están en claro (`:17`, `:27`) |
| ¿Qué corre sin que nadie lo pida? | `service/DailyCloseJob.java:32`: un `@Scheduled` cada 30 s que escribe `batch_runs` y rellena una caché de pedidos (`:40`) |

La regla para orientarse en un legado es de fuera hacia dentro y siguiendo los datos: entradas
(controladores y tareas programadas), transacciones, escrituras, configuración. Leer primero las
entidades o los repositorios da vocabulario, pero no dice qué pasa.

## 5. 🧱 Levantar el legado

```bash
python3 laboratorio/scripts/lab.py up
python3 laboratorio/scripts/lab.py psp          # en otra terminal
python3 laboratorio/scripts/lab.py legacy       # en otra terminal
python3 laboratorio/scripts/lab.py seed
```

- `up` levanta PostgreSQL y Toxiproxy con `docker compose` y espera a que estén sanos (`--wait`).
- `psp` arranca el simulador del banco en `:38085`, en primer plano: ahí verás cada cobro.
- `legacy` compila con Maven (`-DskipTests package`) y arranca el JAR en `:38081`, en primer plano.
- `seed` vacía las tablas, carga la semilla, vacía el registro del PSP y quita los tóxicos. **Exige que
  el legado haya arrancado una vez**: las tablas no están en ningún script, las crea Hibernate con
  `ddl-auto: update` al arrancar. Si no, `seed` lo dice y se detiene.

```text
 Container mono-toxiproxy Healthy
 Container mono-postgres Healthy
```

```text
HikariPool-1 - Start completed.
Tomcat started on port 38081 (http) with context path '/'
Started LegacyApplication in 3.007 seconds (process running for 3.271)
```

```text
psp-simulator reset: 200
semilla cargada
```

## 6. 🔁 Arqueología de rutas

**Primera fuente: el código.** Las rutas son las anotaciones de los controladores:

```bash
cd laboratorio/estados/01/legacy/src/main/java/dev/mono/legacy
grep -rnE '@(Get|Post|Request)Mapping' .
```

- `cd` entra en el paquete raíz del legado congelado, para que las rutas salgan cortas.
- `grep -rnE` busca de forma recursiva (`-r`), con número de línea (`-n`) y con expresión regular
  extendida (`-E`); el patrón encuentra las tres anotaciones de mapeo de Spring.

```text
controller/ProductController.java:11:@RequestMapping("/api/v1/products")
controller/ProductController.java:19:    @GetMapping
controller/ProductController.java:24:    @GetMapping("/{sku}")
controller/ProductController.java:33:    @PostMapping
controller/AuthController.java:13:@RequestMapping("/api/v1/auth")
controller/AuthController.java:21:    @PostMapping("/login")
controller/AuthController.java:30:    @PostMapping("/logout")
controller/HealthController.java:10:    @GetMapping("/health")
controller/OrderController.java:17:@RequestMapping("/api/v1/orders")
controller/OrderController.java:35:    @GetMapping
controller/OrderController.java:40:    @PostMapping
controller/OrderController.java:50:    @GetMapping("/{id}")
controller/OrderController.java:59:    @PostMapping("/{id}/payment")
controller/OrderController.java:68:    @PostMapping("/{id}/cancel")
controller/NotificationController.java:19:    @GetMapping("/api/v1/notifications")
controller/ReportController.java:11:@RequestMapping("/api/v1")
controller/ReportController.java:21:    @GetMapping("/reports/orders-summary")
controller/ReportController.java:29:    @GetMapping("/batches/{id}")
```

Catorce
operaciones, todas bajo `/api/v1` salvo `/health`, aunque no exista ningún `v1` documentado. Todos los
métodos devuelven `Object`: la firma no dice qué forma tiene la respuesta.

**Segunda fuente: el tráfico.** `lab.py api` hace una petición como `ana`, `ops` o `nadie` e imprime
estado, tipo de contenido y cuerpo:

```bash
python3 laboratorio/scripts/lab.py api POST /api/v1/auth/login '{"email":"ana@mono.local","password":"ana-12345"}' --as nadie
```

- `api MÉTODO RUTA [CUERPO]` construye la petición; `--as nadie` la envía sin token (el login no
  necesita uno). Con `--as ana` o `--as ops`, `lab.py` inicia sesión antes y añade el `Bearer`.

```text
HTTP 200 · application/json · 399 ms
{
  "accessToken": "eyJhbGciOiJIUzI1NiJ9.eyJzdWIiOiIxMTExMTExMS0xMTExLTQxMTEtODExMS0xMTExMTExMTExMTEiLCJyb2xlIjoiY3VzdG9tZXIiLCJleHAiOjE3OTA3MTQ3NjEsImlhdCI6MTc5MDcxMzg2MSwianRpIjoiNDM4OWYwYTYtMGMzMC00ODk5LTg0N2UtYmNlMDQxODU0MTQxIiwiZW1haWwiOiJhbmFAbW9uby5sb2NhbCJ9.DSb-giTkJzBz0bErbldmQcbx2usl_v5IwTJZ2UBdPHQ",
  "tokenType": "Bearer",
  "expiresIn": 900,
  "user": {
    "email": "ana@mono.local",
    "id": "11111111-1111-4111-8111-111111111111",
    "passwordHash": "$2y$10$Rdmvw5b4tBFmQ7.1vLA/p.Mg5xRLfiL2itgsZuNtaAZGv2IJxsQf6",
    "role": "customer"
  }
}
```

El login devuelve el hash de la contraseña: `AuthService` mete la entidad `User` en la respuesta
«para que el front no tenga que pedirla otra vez», y la entidad se serializa entera. El mismo
recorrido con credenciales malas y sin token:

```text
HTTP 200 · application/json · 95 ms
{
  "error": "Wrong password"
}
HTTP 200 · application/json · 21 ms
{
  "error": "User not found"
}
HTTP 200 · application/json;charset=ISO-8859-1 · 15 ms
{
  "error": "Not logged in"
}
```

Tres errores, tres `200`, tres mensajes libres, y dos de ellos revelan si un correo existe. El
tercero lo produce `config/SecurityConfig.java`: el *entry point* de seguridad escribe
`{"error":"Not logged in"}` con estado `200` «porque el frontend mira el campo `error`».

**Tercera fuente: la base.** Una compra y su huella:

```bash
python3 laboratorio/scripts/lab.py api POST /api/v1/orders '{"lines":[{"sku":"SKU-001","quantity":2},{"sku":"SKU-002","quantity":1}]}'
```

- Crea un pedido como `ana` con dos líneas; el legado reserva stock de las dos en la misma
  transacción.

```text
HTTP 200 · application/json · 74 ms
{
  "createdAt": "2026-09-29T20:31:08.409318Z",
  "currency": "USD",
  "customer": {
    "email": "ana@mono.local",
    "id": "11111111-1111-4111-8111-111111111111",
    "passwordHash": "$2y$10$Rdmvw5b4tBFmQ7.1vLA/p.Mg5xRLfiL2itgsZuNtaAZGv2IJxsQf6",
    "role": "customer"
  },
  "id": "1f2dc00a-c59f-4d3b-a57d-10fd2fba3eeb",
  "lines": [
    {
      "id": 1,
      "productName": "Mechanical keyboard",
      "quantity": 2,
      "sku": "SKU-001",
      "unitPrice": 49.9
    },
    {
      "id": 2,
      "productName": "USB-C cable",
      "quantity": 1,
      "sku": "SKU-002",
      "unitPrice": 9.9
    }
  ],
  "payments": [],
  "status": "CONFIRMED",
  "total": 109.7
}
```

Cuatro hallazgos sin leer una línea más de código: el dinero viaja como número (`49.9`, no
`"49.90"`); el cliente embebido vuelve a traer el hash; los identificadores de línea son internos
(`"id": 1`); y el pedido nace `CONFIRMED`, reservado y sin pagar. Otro pedido, de tres cables, deja
ver lo que costará el `double`:

```bash
python3 laboratorio/scripts/lab.py api POST /api/v1/orders '{"lines":[{"sku":"SKU-002","quantity":3}]}' | grep -E 'HTTP|"total"'
```

- El mismo `POST` con tres unidades de `SKU-002` (9.90 cada una); `grep -E` deja solo la línea de
  estado y la del total.

```text
HTTP 200 · application/json · 15 ms
  "total": 29.700000000000003
```

## 7. 🔁 La regla de pago vive en un `if`

No hay documentación de cuándo se rechaza un pago. La búsqueda empieza en el servicio de pago:

```bash
grep -nE '1000|psp\.post|@Transactional|RestClientException' laboratorio/estados/01/legacy/src/main/java/dev/mono/legacy/service/PaymentService.java
```

- `-n` da el número de línea; el patrón busca el umbral, la llamada al banco, la transacción y la
  excepción que se atrapa.

```text
12:import org.springframework.web.client.RestClientException;
33:    @Transactional
46:        if (o.getTotal() > 1000) {
52:                Map<String, Object> res = psp.post().uri("/payments")
60:            } catch (RestClientException timeout) {          // cualquier fallo del banco cuenta como "pendiente"
```

Tres reglas de negocio aparecen en dieciocho líneas, sin nombre ni prueba:

- **Más de 1000 se rechaza sin preguntar al banco** (`:46`). El banco aplica la misma regla, pero el
  legado la duplicó «para no llamarlo». Si el banco cambia su límite, nadie se entera.
- **Todo fallo del banco es un pago pendiente** (`:60`). Un timeout con el cobro hecho y un banco
  caído sin cobro terminan en el mismo estado, `PAYMENT_PENDING`. El ejercicio 🔥 lo demuestra.
- **La llamada al banco va dentro de la transacción** (`:33` y `:52`): mientras el banco tarda, la
  conexión a la base queda ocupada. Es el pecado del taller 07; aquí solo se señala.

La regla de 666.00 no está en el legado: el banco tarda 3 s con ese importe y el legado espera 2 s
(`legacy.psp.timeout-ms` en `application.yaml`). El resultado incierto es un efecto de dos números
que viven en dos sistemas distintos.

## 8. 🧱 Quién escribe cada tabla

```bash
cd laboratorio/estados/01/legacy/src/main/java/dev/mono/legacy
grep -rnE '\.save\(|setStock|setStatus\("CANCELLED' .
```

- Busca, desde el paquete raíz, las escrituras explícitas: los `save` de los repositorios, los
  cambios de stock y la cancelación.

```text
entity/Product.java:22:    public void setStock(int stock) { this.stock = stock; }
controller/ProductController.java:38:        return products.save(product);
service/DailyCloseJob.java:45:        runs.save(run);
service/ProductService.java:27:        return products.save(p);     // si el SKU ya existe, lo pisa
service/PaymentService.java:66:        payments.save(p);
service/InventoryService.java:29:        p.setStock(p.getStock() - quantity);
service/InventoryService.java:30:        return products.save(p);
service/OrderService.java:67:        return orders.save(order);
service/OrderService.java:89:        o.setStatus("CANCELLED");
service/OrderService.java:96:        notifications.save(n);
```

El `grep` encuentra lo que alguien escribió; no encuentra lo que la base hace sola. Hay dos escritores
invisibles:

- **Hibernate por *dirty checking*.** `PaymentService` cambia `o.setStatus(...)` (`:49`, `:59`,
  `:63`) y nunca llama a `save` sobre el pedido: dentro de la transacción, el cambio se escribe al
  confirmar.
- **Un *trigger* de PostgreSQL.** Nadie en Java devuelve el stock al cancelar. La pregunta correcta
  no es al código, sino al catálogo de la base:

```bash
python3 laboratorio/scripts/lab.py sql "select tgname from pg_trigger where not tgisinternal"
```

- `sql` ejecuta la consulta en `mono-postgres` con el usuario del legado; `pg_trigger` lista los
  *triggers*, y `not tgisinternal` excluye los que PostgreSQL crea para las claves foráneas.

```text
        tgname        
----------------------
 orders_restore_stock
(1 row)
```

Lo crea `config/SchemaFixer.java:28` al arrancar, leyendo `db/triggers.sql`, y solo si la URL es de
PostgreSQL (`:25`): en las pruebas con SQLite no existe.

## 9. 🧨 Provocación: `200` y el pedido no existe

Una compra de dos productos, uno de ellos sin stock:

```bash
python3 laboratorio/scripts/lab.py seed
python3 laboratorio/scripts/lab.py api POST /api/v1/orders '{"lines":[{"sku":"SKU-001","quantity":1},{"sku":"SKU-004","quantity":1}]}'
python3 laboratorio/scripts/lab.py api GET /api/v1/orders
python3 laboratorio/scripts/lab.py sql "select sku, stock from products where sku in ('SKU-001','SKU-004') order by sku"
```

- `seed` deja la base en su estado conocido; `SKU-004` tiene stock `0`.
- El `POST` compra una unidad de cada uno; el `GET` lista los pedidos de `ana`; la consulta mira el
  stock de los dos productos.

```text
HTTP 200 · application/json · 11 ms
{
  "error": "Not enough stock for SKU-004"
}
HTTP 200 · application/json · 6 ms
[]
   sku   | stock 
---------+-------
 SKU-001 |    20
 SKU-004 |     0
(2 rows)
```

El cliente recibió `200`. Si mira el código de estado, como hace cualquier cliente HTTP razonable,
cree que compró. No hay pedido y el stock de `SKU-001` no se movió: `LegacyException` es una
`RuntimeException` lanzada dentro de `@Transactional`, así que la reserva de la primera línea se
deshizo. La base hizo lo correcto; el contrato mintió. Nada lo dice salvo un campo `error` que el
cliente tiene que saber buscar.

## 10. 🧪 Evidencia: el mapa reconstruido

Lo que sale de las tres fuentes, contrastado petición a petición:

| Ruta | Quién | Respuesta de éxito | Error típico | Escribe |
|---|---|---|---|---|
| `GET /health` | nadie | `{"status":"UP"}` | — | — |
| `POST /api/v1/auth/login` | nadie | token + `user` con `passwordHash` | `200 {"error":"Wrong password"}` o `"User not found"` | — |
| `POST /api/v1/auth/logout` | token | `{"ok":true}`; revoca en memoria | — | — |
| `GET /api/v1/products` | token | lista de entidades `Product` | `200 {"error":"Not logged in"}` | — |
| `GET /api/v1/products/{sku}` | token | entidad `Product` | `200 {"error":"Product … does not exist"}` | — |
| `POST /api/v1/products` | operador | entidad guardada; **pisa** un SKU existente | `200 {"error":"Only operators can do this"}` | `products` |
| `GET /api/v1/orders` | token | lista de entidades `Order` | — | — |
| `POST /api/v1/orders` | token | entidad `Order` con cliente embebido | `200 {"error"}`; SKU inexistente: `500` con traza | `orders`, `order_lines`, `products` |
| `GET /api/v1/orders/{id}` | token | entidad `Order`, a veces desde la caché | `200 {"error":"Order not found"}` | — |
| `POST /api/v1/orders/{id}/payment` | token | `orderId`, `orderStatus`, entidad `Payment` | `200 {"error":"Order can not be paid"}` | `payments`, `orders` |
| `POST /api/v1/orders/{id}/cancel` | token | entidad `Order` cancelada | `200 {"error":"Paid orders can not be cancelled"}` | `orders`, `notifications`; el trigger, `products` |
| `GET /api/v1/notifications` | operador | lista de entidades `Notification` | `200 {"error":"Only operators…"}` | — |
| `GET /api/v1/reports/orders-summary` | operador | `items` por cliente, calculado en cada petición | — | — |
| `GET /api/v1/batches/{id}` | operador | fila de `batch_runs` | `200 {"error":"Batch not found"}` | — |

Y las escrituras que no vienen de ninguna ruta: `DailyCloseJob` escribe `batch_runs` cada 30 s en
**cada** instancia; el *trigger* escribe `products` al cancelar. Este mapa es el insumo del taller 03,
que lo convierte en una suite ejecutable.

## 11. 🩺 Errores reales al construirlo

El legado se generó con un asistente y se corrió antes de publicarlo. Tres errores aparecieron, y los
tres son típicos de un legado real.

### El ciclo de beans no arrancaba con inyección por constructor

**Síntoma.** Las pruebas no cargaban el contexto: `BeanCurrentlyInCreationException: Error creating
bean with name 'orderService': Requested bean is currently in creation: Is there an unresolvable
circular reference or an asynchronous initialization dependency?`

**Causa.** `OrderService` necesita `InventoryService` y viceversa. Con
`allow-circular-references: true`, Spring resuelve un ciclo solo si uno de los dos ya está
instanciado cuando el otro lo pide; con inyección por constructor en `OrderService`, eso nunca pasa.

**Lección.** El legado «lo arregló» con `@Autowired` sobre campos en los dos servicios. El comentario
que lo acompaña —«el ciclo con InventoryService solo arranca así»— es la pista que un recién llegado
debería tomar en serio: el diseño tiene un ciclo que el framework tolera a regañadientes. El taller
06 lo rompe.

### `server.error.include-stacktrace` ya no hace nada en Boot 4

**Síntoma.** Con la propiedad en `always`, el `500` salía sin campo `trace`.

**Causa.** Boot 4.0 movió la propiedad a `spring.web.error.include-stacktrace`; la antigua figura como
deprecada en los metadatos, con su reemplazo, y no surte efecto.

**Lección.** Una propiedad que no hace nada no avisa al arrancar. Los metadatos de configuración del
JAR (`META-INF/spring-configuration-metadata.json`) dicen el nombre vigente y la fecha del cambio.

### El timeout del banco no era una `ResourceAccessException`

**Síntoma.** El pago de 666.00 respondía `500` a los 2 s en lugar de dejar el pedido pendiente.

**Causa.** Con `SimpleClientHttpRequestFactory`, el tiempo de espera se agotó mientras se leía la
respuesta, y `RestClient` lo envolvió en una `RestClientException` genérica («Error while extracting
response…»), no en `ResourceAccessException`.

**Lección.** El legado pasó a atrapar `RestClientException`, y desde entonces **cualquier** fallo del
banco es «pendiente», incluido un banco caído que no cobró nada. Arreglar un síntoma ensanchando un
`catch` es cómo nacen las reglas de negocio accidentales.

## 12. 🧰 Plataformas

Los talleres son solo Java (§6 de la guía): el dolor de heredar un sistema sin documentación no
depende del lenguaje. El contraste entre plataformas —cómo cada una expresa módulos, visibilidad y
dependencias— está en [`01/06` — Estilos de estructura interna](../01-fundamentos-y-modelo-mental/06-estilos-de-estructura-interna.md)
y en [`02/02` — API pública del módulo](../02-modularidad-y-limites-internos/02-api-publica-del-modulo-y-encapsulacion-interna.md).
Lo que sí es portable es el orden de la arqueología: entradas, transacciones, escrituras,
configuración, y las tres fuentes contrastadas.

## 13. 🧹 Teardown

```bash
python3 laboratorio/scripts/lab.py down
```

- `down` apaga los contenedores y borra sus volúmenes (`-v`): el siguiente taller parte de una base
  vacía. `mono-legacy` y `psp-simulator` se paran con Ctrl+C en sus terminales.

## ⚠️ Errores frecuentes

- «Leo todas las clases y luego entiendo». En un legado se entiende siguiendo una petición y sus
  escrituras; leer todo sin orden da vocabulario, no comportamiento.
- «Si responde `200`, funcionó». Este legado responde `200` a casi todo; el éxito se comprueba en la
  base.
- «El `grep` de `save` dice quién escribe». Faltan el *dirty checking* de Hibernate y lo que hace la
  base sola: *triggers*, valores por defecto, tareas programadas.
- «Documentar el legado es escribir un README». Sin tráfico ni base que lo contrasten, el README
  describe lo que el autor cree, no lo que el sistema hace.
- «Veo secretos en `application.yaml`, los arreglo ahora». Se señalan y se registran; moverlos a un
  gestor de secretos es trabajo de plataforma, y hacerlo a mitad de una arqueología mezcla dos
  cambios.

## 📚 Referencias

- [Legacy Seam, Martin Fowler](https://martinfowler.com/bliki/LegacySeam.html)
- [Spring Boot: Common Application Properties — Web (`spring.web.error.*`)](https://docs.spring.io/spring-boot/appendix/application-properties/index.html#appendix.application-properties.web)
- [PostgreSQL 17: `pg_trigger`](https://www.postgresql.org/docs/17/catalog-pg-trigger.html)
- [Spring Framework: `RestClient`](https://docs.spring.io/spring-framework/reference/integration/rest-clients.html#rest-restclient)

## 🧠 Preguntas

1. ¿Qué tres fuentes usaste para reconstruir las rutas del legado y qué aporta cada una? 🟢
2. ¿Por qué `lab.py seed` exige que el legado haya arrancado antes? 🟢
3. ¿Dónde vive la regla «más de 1000 se rechaza» y por qué es un problema aunque funcione? 🟢
4. ¿Qué hace el *trigger* `orders_restore_stock` y por qué no aparece en el código Java? 🟢
5. El pedido con `SKU-004` respondió `200`. ¿Qué pasó en la base y por qué el cliente no lo sabe? 🟡
6. ¿Por qué el `SKU-001` de ese mismo pedido conservó su stock? 🟡
7. ¿Qué te dice `allow-circular-references: true` sobre el diseño antes de abrir un solo servicio? 🟡
8. ¿Qué diferencia hay entre «quién llama a `save`» y «quién escribe la tabla» en este legado? 🟡
9. Los secretos están en `application.yaml`. ¿Por qué el taller los señala y no los arregla? 🟡
10. Tienes una hora para orientarte en este código. ¿En qué orden lo recorres y por qué ese orden? 🟠
11. El login distingue «User not found» de «Wrong password». ¿Qué riesgo introduce y qué debería responder? 🟠
12. ¿Qué pecados del legado se detectan leyendo solo `application.yaml`? 🟠
13. Tu jefe pide «documentar el legado» en una semana. ¿Qué entregarías y qué evidencia de que es correcto? 🔴

## 🧪 Ejercicios

1. 🟢 **Orientación en código ajeno.** ¿En qué archivo y línea se abre la transacción que envuelve la
   llamada al banco, y en qué línea se hace la llamada? Responde con rutas de `laboratorio/estados/01/`.
2. 🟢 Crea un pedido de un `SKU-001`, págalo y cancélalo con `lab.py api`. Pega las tres respuestas y
   el stock de `SKU-001` antes y después con `lab.py sql`.
3. 🟡 Con una consulta al catálogo de PostgreSQL, lista las funciones que no creó Hibernate. Pega la
   salida y di qué archivo del legado las crea.
4. 🟡 **Orientación en código ajeno.** ¿Qué archivo y línea deciden que un pedido pagado no se puede
   cancelar? ¿Por qué esa regla está ahí y no en `OrderService.cancel`, y qué riesgo tiene?
5. 🟡 Da de alta `SKU-006` como `ops` con `POST /api/v1/products` y repite el `POST` con otro precio.
   Pega las dos respuestas y explica qué pasó con el primer precio.
6. 🟠 Paga un pedido de tres `SKU-003` (666.00) y compara la respuesta del legado con
   `GET http://localhost:38085/payments`. ¿Se cobró? ¿Qué sabe el legado y qué no?
7. 🟠 Construye la tabla «tabla → escritores» del legado incluyendo el *dirty checking*, el *trigger*
   y el cierre diario, cada escritor con su ruta y línea.
8. 🔥 Para el `psp-simulator` y paga un pedido barato. Pega la respuesta y la línea de log del legado,
   y explica por qué el estado resultante es indistinguible del caso 666.00 aunque no haya cobro.

---

**Siguiente:** [`02` — Los errores escondidos](02-los-errores-escondidos.md). **Relacionado:**
[`05/03` — Recuperar modularidad en un monolito legado](../05-decision-evolucion-y-practica/03-recuperar-modularidad-en-un-monolito-legado.md).
