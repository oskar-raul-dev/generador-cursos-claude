# 07 — PHP y Laravel

Este taller es **opcional** y depende solo de `06/01`. Es el último sabor y el que más cuesta
arriba tiene el framework: Laravel trae un ORM activo (Eloquent) que quiere ser entidad, DTO y
fila a la vez, un contenedor que resuelve casi todo por magia, fachadas estáticas en cada esquina
y un manejador de errores pensado para una aplicación web con sesiones. Este taller construye el
mismo sistema que el 03 con Laravel en el borde y PHP ordinario en el centro, y termina cuando la
suite de `06/01` pasa con el catálogo en PostgreSQL y con el catálogo en MongoDB.

> **Vigencia:** 2026-09-27. Versiones verificadas ese día en Packagist y PECL; PHP 8.4.25.

**Salto rápido:** [1](#1--qué-enseña-este-sabor) · [2](#2--prerrequisitos-y-versiones) · [3](#3-️-mapa-de-carpetas) · [4](#4--parte-1-el-núcleo-y-sus-bordes) · [5](#5--parte-2-cancelación-outbox-y-notifier) · [6](#6--parte-3-el-catálogo-a-mongodb) · [7](#7--pruebas-por-anillos) · [8](#8--errores-provocados-a-propósito) · [9](#9--cinco-plataformas) · [10](#10--teardown) · [Preguntas](#-preguntas) · [Ejercicios](#-ejercicios)

## 1. 🎯 Qué enseña este sabor

Laravel empuja hacia un diseño concreto: `class Order extends Model`, `Order::find($id)` desde el
controlador, `DB::transaction` envolviendo la lógica en el propio controlador, `abort(404)` donde
haga falta. Este taller pone la frontera en otro sitio:

```text
HTTP ─► Laravel (FormRequest, middleware) ─► CreateOrder (final readonly) ─► Products / Inventory / Orders (interfaces)
                                                   │                               ▲ `implements`: contrato nominal
                                     UnitOfWork::run($work)            PgProducts · MongoProducts · PgInventory · PgOrders
                                                   │
                            ConnectionInterface::transaction()      todos los adaptadores reciben LA MISMA conexión
```

- **`src/` es el núcleo y `app/` es la infraestructura.** `Hex\Domain` y `Hex\Application` viven
  en `src/`, sin una sola línea de Laravel; `app/` (el directorio que Laravel considera "la
  aplicación") contiene solo adaptadores: controladores, Form Requests, middleware, persistencia,
  el provider. Es la inversión del tutorial, y `deptrac` la vigila.
- **Los puertos son interfaces y los adaptadores `implements`.** Contrato nominal: PHP comprueba al
  cargar la clase que `PgOrders` tiene todos los métodos de `Orders`. Es lo contrario del
  `Protocol` de Python, y por eso aquí no hace falta un type checker para eso.
- **El service container es el composition root**, con un `singleton` por puerto en
  `HexServiceProvider`. Los casos de uso son `final readonly class` con los puertos en el
  constructor: el contenedor los resuelve solo (autowiring por interfaz) y los inyecta en los
  controladores. Nadie los registra a mano.
- **`transaction()` de la conexión es la unidad de trabajo.** Todos los adaptadores de PostgreSQL
  reciben la misma `ConnectionInterface`, así que comparten la transacción sin `ContextVar` ni
  `AsyncLocalStorage`: en PHP una petición es un proceso, y la conexión es su contexto.
- **Sin Eloquent.** Query Builder crudo (`select`, `insert`, `update` con SQL a mano) sobre el
  esquema compartido. Un modelo Eloquent es *active record*: fila con métodos, y con la misma
  regla que el bloque [05](../05-plataformas-y-practica/01-que-cambia-entre-plataformas.md) da al
  ORM de las otras cuatro plataformas: en el adaptador cuando el modelo de persistencia lo
  merece; aquí no. El bloque 05 no tiene capítulo de PHP: este taller hace de capítulo.
- **La outbox la entrega otro proceso.** PHP no tiene un hilo de fondo dentro del servidor HTTP:
  `php artisan outbox:work` es un comando artisan con bucle propio, como `queue:work`.

El precio: 123 archivos PHP (76 en `src/` de puro núcleo) donde el tutorial tendría diez; y un
`.env`, un `bootstrap/app.php` y un `config/` que hay que domar. La ganancia: la parte 3 es un
archivo de 71 líneas y una línea del provider, y la parte 2 no toca `app/Http` salvo un
controlador.

## 2. 🧰 Prerrequisitos y versiones

| Herramienta | Versión fijada | Para qué |
|---|---|---|
| PHP | `8.4.25` (`^8.4`), con `pdo_pgsql`, `bcmath`, `pcntl`, `openssl` | el lenguaje; `private(set)`, `readonly`, enums |
| `ext-mongodb` | `2.5.3` (PECL) | la parte 3; `mongodb/mongodb` no funciona sin la extensión |
| Composer | `2.10.3` | dependencias y autoload PSR-4 |
| `laravel/framework` | `13.33.0` | el framework; Laravel 13 exige PHP ≥ 8.3 |
| `mongodb/mongodb` | `2.4.2` | catálogo en la parte 3 (la librería oficial, no `laravel-mongodb`) |
| `predis/predis` | `3.6.1` | Redis en PHP puro, sin `ext-redis` |
| `firebase/php-jwt` | `7.2.0` | JWT HS256 (el repositorio se mudó a `googleapis/php-jwt`; el paquete conserva el nombre) |
| `phpunit/phpunit` / `deptrac/deptrac` | `12.5.36` / `4.7.2` | pruebas y regla de dependencias |

Todo va fijado en `composer.json` y congelado en `composer.lock`. bcrypt no necesita paquete:
`password_verify` entiende los `$2y$` de la semilla.

```text
pecl install mongodb-2.5.3
```

- `pecl` compila la extensión contra el PHP activo y la deja en `extension_dir`. Con el PHP de
  Homebrew (`php@8.4`), `extension_dir` apunta a `/opt/homebrew/lib/php/pecl/<api>` y **ese
  directorio puede no existir todavía**: `pecl` compila bien y falla al copiar (`failed to mkdir`).
  Se crea con `mkdir -p` y se repite. PECL añade `extension="mongodb.so"` al principio de
  `php.ini`; la convención de Homebrew es un archivo en `conf.d/ext-mongodb.ini`.
- Se comprueba con `php -m | grep mongodb`.

```text
python3 06-talleres/laboratorio/scripts/lab.py php
python3 06-talleres/laboratorio/scripts/lab.py php --catalog mongo
python3 06-talleres/laboratorio/scripts/lab.py php --test
```

- `php` corre `composer install` si falta `vendor/`, crea `.env` desde `.env.example` (y
  `key:generate`) si falta, arranca `php artisan outbox:work` en segundo plano y
  `php artisan serve --port 8085` en primer plano. `Ctrl+C` para el servidor; el orquestador
  termina el worker.
- `--catalog mongo` es la parte 3: `HEX_CATALOG=mongo` en el entorno del proceso. Una variable
  de entorno del proceso **gana** a la del `.env` (Dotenv no sobrescribe lo que ya existe).
- `--test` corre `phpunit --testdox` (dominio y caso de uso, sin arrancar Laravel) y
  `deptrac analyse`. No necesita Docker.

## 3. 🗂️ Mapa de carpetas

```text
laboratorio/php/
├── composer.json · composer.lock             versiones fijas; PSR-4: Hex\Domain → src/Domain, Hex\Application → src/Application, App → app/
├── .env.example                              la configuración del laboratorio (§11); lab.py la copia a .env
├── deptrac.yaml · phpunit.xml
├── bootstrap/app.php                         arranque: rutas con `using`, alias hex.auth, dontReport + render → problem+json
├── bootstrap/providers.php                   [HexServiceProvider::class]
├── config/hex.php · config/cors.php          lo propio del taller; el resto del config/ es el del esqueleto
├── routes/api.php                            las rutas del contrato bajo api/v1
├── src/                                      EL NÚCLEO: cero `use Illuminate\...`
│   ├── Domain/                               Money, Product, Order, OrderLine, Payment, OrderStatus, PaymentStatus, Event/, Error/
│   └── Application/                          Actor, Role, Page, PageRequest, Error/, Port/ (16 interfaces + 4 value objects), UseCase/
├── app/                                      LA INFRAESTRUCTURA
│   ├── Providers/HexServiceProvider.php      composition root: un singleton por puerto
│   ├── Http/                                 Middleware/Authenticate, Requests/ (Form Requests), Rules/StrictInteger,
│   │                                         Problems/ (traductor + excepciones del borde), Controllers/, Query, Responses, Auth/
│   ├── Persistence/                          DbUnitOfWork, Cursors, Postgres/ (un adaptador por puerto + Rows), Mongo/MongoProducts
│   ├── Redis/ · Security/ · Payment/ · Support/
│   └── Console/Commands/OutboxWork.php       el worker de la outbox (parte 2)
└── tests/Unit/                               MoneyTest, OrderTest, CreateOrderTest (PHPUnit puro, sin TestCase de Laravel)
```

Del esqueleto `laravel/laravel` 13 se quitaron los ejemplos (`routes/web.php`, `app/Models/User.php`,
las pruebas de ejemplo, `AGENTS.md`/`CLAUDE.md`) y las dependencias que no se usan (tinker, pail,
faker). `resources/`, `database/migrations/` y `public/` quedan como vienen: no molestan y el
esquema es el de `06/01`, no una migración.

## 4. 🧱 Parte 1: el núcleo y sus bordes

### El dominio son clases ordinarias, con PHP 8.4

```php
final class Order
{
    private function __construct(
        public readonly string $id,
        public readonly string $customerId,
        public readonly array $lines,
        public readonly Money $total,
        public readonly DateTimeImmutable $createdAt,
        public private(set) OrderStatus $status,   // se lee desde fuera, solo cambia desde dentro
        public private(set) ?Payment $payment,
        public readonly int $version,
    ) {}
```

`Money`, `Product`, `OrderLine` y `Payment` son `final readonly class`; los estados son `enum`
(`OrderStatus`, `PaymentStatus::orderStatus()` decide la transición); `Order` es mutable donde
debe (`status`, `payment`) con visibilidad asimétrica: un `$order->status = …` desde un
controlador no compila. Nada extiende `Model`.

### Los puertos son interfaces y el contenedor los resuelve

```php
interface Inventory
{
    public function availableFor(array $skus): array;
    public function initialize(string $sku, int $quantity): void;
    public function reserve(string $orderId, array $lines): void;
    public function release(string $orderId): void;
}
```

`PgInventory implements Inventory`: si le falta un método, PHP falla al cargar la clase, antes de
la primera petición. En `HexServiceProvider`, `$this->app->singleton(Inventory::class,
PgInventory::class)` y ya está: `CreateOrder` declara `Inventory $inventory` en su constructor y
el contenedor lo construye. Un `bind` por puerto, ningún `bind` por caso de uso.

### La transacción es la conexión

```php
final readonly class DbUnitOfWork implements UnitOfWork
{
    public function __construct(private ConnectionInterface $db) {}

    public function run(Closure $work): mixed
    {
        return $this->db->transaction($work);
    }
}
```

El provider registra `ConnectionInterface` como singleton (`$app->make('db')->connection()`).
`PgOrders`, `PgInventory` y `PgIdempotencyStore` reciben esa misma instancia; `transaction()` abre
`BEGIN` sobre ella, y `$work()` corre dentro. Si `$work` lanza, Laravel hace `ROLLBACK` y relanza.
Anidado, usa `SAVEPOINT`. No hay contexto implícito que propagar: el proceso entero es la
petición.

### El borde: Form Requests estrictos, middleware, un traductor

- `Authenticate` (middleware, alias `hex.auth`) verifica el bearer con `TokenVerifier` (interfaz
  del borde, implementada por `JwtTokens`), consulta la revocación y deja un `Actor` en
  `$request->attributes`. Los controladores lo leen con `Authenticate::context($request)`. Ningún
  controlador ve un token.
- Los Form Requests validan **antes** de entrar al método del controlador: `LoginRequest`,
  `CreateProductRequest`, `CreateOrderRequest`. La regla `integer` de Laravel acepta `"10"`;
  `StrictInteger` (`is_int`) no. `unitPrice.amount` exige el patrón de dos decimales: `"35"`
  cae con `400`.
- `Problems::render` es el traductor único, registrado en `bootstrap/app.php` con
  `$exceptions->render(...)`: cada error propio → `problem+json` con el código del contrato;
  `ValidationException` (Form Requests) → `400 VALIDATION_FAILED` con `lines[0].quantity`, no el
  `422` con `errors: {campo: […]}` de Laravel (§8). Y `$exceptions->dontReport([...])` para que
  un `404` esperado no acabe en el log como `ERROR` (§8).
- Las rutas se registran con `withRouting(using: …)`, no con `api:`. El grupo `api` de Laravel
  trae `throttle:api`, y con `api:` el framework define el limitador a 60 peticiones por minuto:
  la suite hace 85 en cinco segundos.

### Las salidas: Query Builder crudo

`app/Persistence/Postgres/` tiene un adaptador por puerto con el mismo SQL que los otros
sabores: `select`, `insert`, `update` (devuelve filas afectadas: `reserve` mira que sea 1),
`statement`. Tres trampas de `pdo_pgsql` y Laravel resueltas en `Rows`:

- `numeric` llega como texto (`"49.90"`) y se pasa por `bcadd($v, '0', 2)`: dos decimales sin
  float.
- Laravel formatea un `DateTime` enlazado con `Y-m-d H:i:s`: **sin microsegundos ni zona**. Las
  fechas se enlazan como texto (`Rows::bindTime`) y se castean en el SQL.
- PDO no enlaza arrays: `IN (?, ?, ?)` con un marcador por SKU, y no se mezclan marcadores con
  nombre y posicionales en la misma consulta.

## 5. 🔁 Parte 2: cancelación, outbox y Notifier

`CancelOrder`, `DeliverPendingPublications` y `ListNotifications` son traducciones literales. Lo
específico de PHP es el disparador:

```php
final class OutboxWork extends Command
{
    protected $signature = 'outbox:work {--interval=500} {--once}';

    public function handle(DeliverPendingPublications $deliver): int
    {
        pcntl_async_signals(true);
        foreach ([SIGINT, SIGTERM] as $signal) {
            pcntl_signal($signal, fn () => $this->stopping = true);
        }
        do {
            try {
                $delivered = $deliver->execute(50);
            } catch (Throwable $e) {
                $this->error('outbox: delivery round failed: '.$e->getMessage());   // la siguiente ronda reintenta
            }
            usleep($interval);
        } while (! $this->stopping);
```

Un servidor PHP no tiene "lifespan": cada petición es un proceso corto y muere. El trabajo
periódico es **otro proceso** con su propia conexión y su propia unidad de trabajo, y `lab.py`
lo arranca y lo para. Es el modelo de `queue:work` y del scheduler de Laravel, y la razón por la
que en PHP la outbox casi siempre acaba en un comando. `TableNotifier` deduplica con
`ON CONFLICT (id) DO NOTHING`.

**Evidencia.** Inventario de la parte (el código se generó de una vez):

```text
-- parte 2: 10 archivos, 372 líneas
src/Application/UseCase/CancelOrder.php · ListNotifications.php · DeliverPendingPublications.php
src/Domain/Event/DomainEvent.php · OrderCancelled.php
app/Persistence/Postgres/PgPendingPublications.php · PgNotifications.php · TableNotifier.php
app/Console/Commands/OutboxWork.php · app/Http/Controllers/NotificationController.php
```

Más `cancel`/`pullEvents` en `Order`, dos rutas en `routes/api.php`, tres `singleton` en el
provider y dos procesos en `lab.py php`.

Salida literal de la suite completa, catálogo en PostgreSQL, 2026-09-27 (la corrida final, con
`dontReport` puesto):

```text
$ hurl --test --jobs 1 --variable base_url=http://localhost:8085 hurl/v1/01-health.hurl hurl/v1/02-auth.hurl hurl/v1/03-products.hurl hurl/v1/04-orders.hurl hurl/v1/05-payment.hurl hurl/v1.1/06-cancel.hurl hurl/v1.1/07-notifications.hurl
Success hurl/v1/01-health.hurl (1 request(s) in 153 ms)
Success hurl/v1/02-auth.hurl (9 request(s) in 293 ms)
Success hurl/v1/03-products.hurl (12 request(s) in 295 ms)
Success hurl/v1/04-orders.hurl (20 request(s) in 456 ms)
Success hurl/v1/05-payment.hurl (14 request(s) in 394 ms)
Success hurl/v1.1/06-cancel.hurl (19 request(s) in 500 ms)
Success hurl/v1.1/07-notifications.hurl (10 request(s) in 2337 ms)
--------------------------------------------------------------------------------
Executed files:    7
Executed requests: 85 (19.1/s)
Succeeded files:   7 (100.0%)
Failed files:      0 (0.0%)
Duration:          4441 ms (0h:0m:4s:441ms)
```

Y el worker, en su terminal: `outbox: delivered 1 event(s)` y `outbox: delivered 2 event(s)`,
las dos rondas que la suite espera. Es el sabor más lento de los cinco (18–19 peticiones/s
frente a 28 de FastAPI): `artisan serve` es el servidor embebido de PHP, un proceso que arranca
el framework entero en cada petición. Es el precio del modelo, no un defecto del taller.

## 6. 🔀 Parte 3: el catálogo a MongoDB

Un archivo: `app/Persistence/Mongo/MongoProducts.php`, con `MongoDB\Client` de la librería
oficial (`mongodb/mongodb`), `typeMap` a arrays y la misma paginación por cursor. Y una línea
en el provider:

```php
$this->app->singleton(Products::class, fn () => config('hex.catalog') === 'mongo'
    ? new MongoProducts(config('hex.mongo_url'))
    : new PgProducts($this->app->make(ConnectionInterface::class)));
```

No se usa `mongodb/laravel-mongodb`: ese paquete es Eloquent para Mongo, y Eloquent es
exactamente lo que este sabor deja fuera del núcleo. Mongo solo se abre si se va a usar.

```text
python3 06-talleres/laboratorio/scripts/lab.py seed --mongo
python3 06-talleres/laboratorio/scripts/lab.py php --catalog mongo
python3 06-talleres/laboratorio/scripts/lab.py suite --base-url http://localhost:8085
```

```text
Success hurl/v1/01-health.hurl (1 request(s) in 5 ms)
Success hurl/v1/02-auth.hurl (9 request(s) in 315 ms)
Success hurl/v1/03-products.hurl (12 request(s) in 463 ms)
Success hurl/v1/04-orders.hurl (20 request(s) in 575 ms)
Success hurl/v1/05-payment.hurl (14 request(s) in 432 ms)
Success hurl/v1.1/06-cancel.hurl (19 request(s) in 490 ms)
Success hurl/v1.1/07-notifications.hurl (10 request(s) in 2337 ms)
--------------------------------------------------------------------------------
Executed files:    7
Executed requests: 85 (18.4/s)
Succeeded files:   7 (100.0%)
Failed files:      0 (0.0%)
Duration:          4628 ms (0h:0m:4s:628ms)
```

La contraprueba, idéntica a la de los otros sabores:

```text
$ docker exec hex-mongo mongosh --quiet hex_catalog --eval 'db.products.find({sku:{$in:["SKU-006","SKU-101"]}},{_id:0,sku:1,name:1}).toArray()'
[ { name: 'Laptop stand', sku: 'SKU-006' }, { name: 'Cancel test item', sku: 'SKU-101' } ]
$ docker exec hex-postgres psql -U hex -d hex_orders -Atc "select count(*) from products where sku in ('SKU-006','SKU-101')"
0
$ docker exec hex-postgres psql -U hex -d hex_orders -Atc "select sku, available from inventory where sku in ('SKU-006','SKU-101') order by sku"
SKU-006|10
SKU-101|6
```

Inventario de la parte: `71` líneas en un archivo y tres en el provider; en `src/` y en
`app/Http`, cero.

## 7. 🧪 Pruebas por anillos

- `tests/Unit/MoneyTest.php` y `OrderTest.php`: `PHPUnit\Framework\TestCase` a secas, sin el
  `TestCase` de Laravel, sin `.env`, sin base. El dominio se prueba como cualquier clase PHP.
- `tests/Unit/CreateOrderTest.php`: fakes que `implements` los puertos y un `SnapshotUnitOfWork`
  que restaura los arrays si `$work` lanza.
- `deptrac analyse`: seis capas (`Domain`, `Application`, `Http`, `Adapters`, `Composition`,
  `Framework`) y un `ruleset` que dice quién puede importar a quién.

```text
$ vendor/bin/phpunit --testdox
............                                                      12 / 12 (100%)
OK (12 tests, 27 assertions)
$ vendor/bin/deptrac analyse --no-progress
  Violations           0
  Skipped violations   0
  Uncovered            0
  Allowed              307
  Warnings             0
  Errors               0
```

Lo que no hay, y se declara: pruebas HTTP con el `TestCase` de Laravel sobre los Form Requests y
el traductor (ejercicio 3), pruebas del adaptador contra PostgreSQL (la suite las cubre) y un
analizador de tipos (PHPStan: ejercicio 1).

## 8. 🩺 Errores provocados a propósito

Dos reales y uno provocado. Los reales vienen de las herramientas y del framework, no del
código, y por eso valen: son los que aparecen el primer día en un proyecto PHP de verdad.

### `deptrac` no sabe leer PHP 8.4 (real)

Primera corrida de `vendor/bin/deptrac analyse` con `qossmic/deptrac` 2.0.4, la última versión
de ese paquete:

```text
PhpParser\Lexer->getNextToken('private(set)', Array, Array)
  thrown in .../vendor/qossmic/deptrac/vendor/nikic/php-parser/lib/PhpParser/Lexer.php on line 313
```

`qossmic/deptrac` está congelado en 2.0.4 y embebe `nikic/php-parser` 4.19, anterior a PHP 8.4:
no reconoce la visibilidad asimétrica `private(set)`. El proyecto se mudó a `deptrac/deptrac`
(4.7.2 el día del taller), que sí la lee. Corrección: cambiar el paquete, mismo `deptrac.yaml`.
Lección: en PHP las herramientas de análisis parsean el lenguaje por su cuenta; **un rasgo nuevo
del lenguaje puede dejar ciega a una herramienta que "funciona"**, y un paquete que no se
actualiza no avisa de que se ha mudado.

### Laravel reporta los rechazos de negocio como `ERROR` (real)

Con la suite en verde, el log del servidor tenía 24 líneas `local.ERROR` como estas:

```text
local.ERROR: invalid credentials {"exception":"[object] (Hex\\Application\\Error\\InvalidCredentials ...
local.ERROR: order not found: 00000000-0000-4000-8000-000000000000 ...
local.ERROR: actor lacks the required capability ...
local.ERROR: TOKEN_REVOKED ...
```

El manejador de Laravel **reporta** (registra) toda excepción antes de **traducirla**; son dos
fases. Un `401` esperado no es un error del sistema, pero para el log lo era. Corrección:
`$exceptions->dontReport([DomainError::class, ApplicationError::class, Unauthenticated::class, …])`
en `bootstrap/app.php`. Tras eso, la misma suite en verde deja el log a cero `ERROR`. Lección:
un rechazo con nombre propio necesita decirle al framework dos cosas, cómo se responde y que no
es una alarma; la mayoría de frameworks solo preguntan la primera.

### Sin traducir `ValidationException` (provocado)

Se quita la rama de `ValidationException` en `Problems::render` (devuelve `null`: "que lo
resuelva Laravel") y se corre `02-auth.hurl`:

```text
error: Assert status code
37 | HTTP 400
   |      ^^^ actual value is <302>
```

```text
$ curl -i -X POST :8085/api/v1/auth/login -H 'Content-Type: application/json' -d '{ "email": "not-an-email" }'
HTTP/1.1 302 Found
Location: http://localhost:8085
$ curl -i ... -H 'Accept: application/json' ...
HTTP/1.1 422 Unprocessable Content
{"message":"The email field format is invalid. (and 1 more error)","errors":{"email":["The email field format is invalid."],"password":["The password field is required."]}}
```

Sin `Accept: application/json`, Laravel asume un formulario web y **redirige** al referer; con
él, responde `422` con su propia forma. Ninguna de las dos es el contrato (`400`,
`errors[{field, message}]`). Lección: el comportamiento por defecto del framework para la
validación está pensado para Blade y sesiones; una API con contrato lo sustituye entero, no lo
ajusta. Revertido; la suite volvió a 7/7.

## 9. 🧰 Cinco plataformas

| Plataforma | Qué da hecho | Qué te deja a ti | Trampa frecuente |
|---|---|---|---|
| Java · Spring Boot | contenedor, `TransactionTemplate`, JPA, resource server | casos de uso sin anotaciones, `UnitOfWork`, dos modelos, ArchUnit | `@Transactional` y *self-invocation* |
| Node/TS · NestJS | contenedor por token, pipes, guards, `$transaction` | tokens para interfaces, `AsyncLocalStorage` solo para la tx | inyectar una `interface` |
| Go · `net/http` | `ServeMux`, `context`, `pgx.Tx`, `errors.As` | la tx en el `ctx` con `Q(ctx)`, `main` como composition root | `db` en vez de `tx` |
| Python · FastAPI | `Depends`, Pydantic, SQLAlchemy Core, `lifespan`, threadpool | `Protocol` + type checker, `dataclass`, `ContextVar` solo para la tx | Pydantic como dominio; `async def` con driver síncrono |
| **PHP · Laravel** | contenedor con autowiring por interfaz, Form Requests, `transaction()`, comandos artisan, `HandleCors` | `src/` sin Laravel y `app/` como infraestructura, un `singleton` por puerto, `dontReport` + `render` para el contrato, un proceso aparte para la outbox, `deptrac` | Eloquent como dominio; fachadas (`DB::`, `Order::find`) desde el núcleo; el `422`/`302` por defecto de la validación; el grupo `api` con throttle; `DateTime` enlazado sin microsegundos |

## 10. 🧹 Teardown

`Ctrl+C` en la terminal de `lab.py php`: `artisan serve` muere y el orquestador manda `SIGTERM`
al worker, que sale al terminar la ronda en curso (`pcntl_signal`). El entorno se apaga con
`lab.py down`. `vendor/` y `.env` están en `.gitignore`; `composer install` y `lab.py php` los
recrean. La extensión `mongodb` se retira con `pecl uninstall mongodb` y borrando
`conf.d/ext-mongodb.ini`.

## ⚠️ Errores frecuentes

- "En Laravel el dominio son los modelos." Un modelo Eloquent es una fila con métodos: sabe de
  su tabla, sus relaciones y su conexión. `Order` no extiende `Model` y no lo necesita.
- "`DB::transaction` en el controlador." Es poner el límite transaccional en el borde; el caso de
  uso decide qué va junto, y lo pide por el puerto `UnitOfWork`.
- "Con `implements` ya está garantizado." Garantiza la firma, no el comportamiento: `deptrac` y
  la suite hacen el resto.
- "Un `404` es una excepción, se registra." Se responde; se reporta solo lo inesperado.
  `dontReport` es parte del diseño del borde, no un ajuste de logging.
- "El worker va en el servidor." En PHP no hay servidor con hilos: es otro proceso, con su
  arranque, su conexión y su parada.

## ✅ Veredicto

Laravel en el borde, PHP ordinario en el centro, y la frontera vigilada por `deptrac` y una
suite que pasa dos veces. Lo específico de PHP —la conexión como contexto transaccional, el
contenedor que resuelve por interfaz, la outbox como comando, el manejador que reporta antes de
traducir— cabe en `app/`. Los dos errores reales no estaban en el código: uno en una herramienta
que se quedó atrás del lenguaje y otro en un valor por defecto del framework que nadie lee hasta
que mira el log. Ambos son la lección que vale el taller.

## 📚 Referencias

- [Laravel 13: service container](https://laravel.com/framework/docs/13.x/container) · [providers](https://laravel.com/framework/docs/13.x/providers) · [ciclo de la petición](https://laravel.com/framework/docs/13.x/lifecycle) · [enrutado](https://laravel.com/framework/docs/13.x/routing) · [middleware](https://laravel.com/framework/docs/13.x/middleware) · [validación](https://laravel.com/framework/docs/13.x/validation) · [manejo de errores](https://laravel.com/framework/docs/13.x/errors) · [base de datos y transacciones](https://laravel.com/framework/docs/13.x/database) · [notas de la versión](https://laravel.com/framework/docs/13.x/releases)
- [PHP: visibilidad (asimétrica)](https://www.php.net/manual/en/language.oop5.visibility.php) · [enumeraciones](https://www.php.net/manual/en/language.types.enumerations.php) · [interfaces](https://www.php.net/manual/en/language.oop5.interfaces.php) · [`password_verify`](https://www.php.net/manual/en/function.password-verify.php) · [`pcntl_async_signals`](https://www.php.net/manual/en/function.pcntl-async-signals.php) · [PDO](https://www.php.net/manual/en/book.pdo.php)
- [MongoDB PHP Library](https://www.mongodb.com/docs/php-library/current/) · [predis](https://github.com/predis/predis) · [php-jwt](https://github.com/googleapis/php-jwt)
- [deptrac](https://deptrac.github.io/deptrac/) · [repositorio `deptrac/deptrac`](https://github.com/deptrac/deptrac)

## 🧠 Preguntas

1. 🟢 ¿Por qué `src/` contiene el núcleo y `app/` la infraestructura, cuando Laravel espera lo contrario?
2. 🟢 ¿Qué comprueba `implements` en PHP y cuándo, comparado con un `Protocol` de Python?
3. 🟢 ¿Cómo llega un `CreateOrder` al controlador sin que nadie lo registre en el provider?
4. 🟢 ¿Por qué `Order` no extiende `Model`?
5. 🟢 ¿Qué hace `public private(set)` en `Order` y qué problema evita?
6. 🟡 ¿Cómo comparten `PgOrders` y `PgInventory` la transacción sin `ContextVar` ni `AsyncLocalStorage`?
7. 🟡 ¿Por qué la outbox es un comando artisan y no un hilo o un `lifespan`?
8. 🟡 ¿Qué son "reportar" y "traducir" en el manejador de excepciones de Laravel, y por qué el taller necesita `dontReport`?
9. 🟡 ¿Por qué `StrictInteger` existe si la regla `integer` ya está?
10. 🟡 ¿Qué pierde un `DateTimeImmutable` enlazado directamente en una consulta de Laravel, y cómo lo evita `Rows::bindTime`?
11. 🟠 El error de `deptrac`: ¿por qué una herramienta que "funciona" deja de funcionar al usar `private(set)`, y qué dice eso de las herramientas de análisis en PHP?
12. 🟠 Sin `Accept: application/json`, una validación fallida devuelve `302`. Explica por qué el framework hace eso y por qué un traductor central es la respuesta y no `$request->expectsJson()`.
13. 🟠 Compara el contexto transaccional de los cinco sabores: `ContextVar`, `AsyncLocalStorage`, `ctx`, `TransactionTemplate` y "la conexión de la petición" en PHP. ¿Qué modelo de ejecución lo hace posible en PHP y qué pasa con PHP-FPM, Octane o un worker de larga vida?
14. 🟠 Un compañero propone `mongodb/laravel-mongodb` para la parte 3 "porque ya tenemos Eloquent". ¿Qué cambiaría en el núcleo y por qué el taller elige la librería oficial?

## 🧪 Ejercicios

1. 🟢 Añade `phpstan/phpstan` al grupo `dev`, corre `vendor/bin/phpstan analyse src app --level 6` y
   arregla lo que encuentre. Después borra `list` de `PgOrders` y comprueba que PHP mismo lo
   detecta al cargar la clase (y en qué momento).
2. 🟢 Quita `$exceptions->dontReport([...])` de `bootstrap/app.php`, corre `02-auth.hurl` y cuenta
   las líneas `local.ERROR`. Vuelve a ponerlo.
3. 🟡 Escribe una prueba con el `TestCase` de Laravel (`Tests\TestCase` + `$this->postJson`) que
   sustituya `CreateOrder` por un fake con `$this->app->instance(CreateOrder::class, …)`: sin
   cabecera → `400 IDEMPOTENCY_KEY_REQUIRED`; `{ "lines": [] }` → `400 VALIDATION_FAILED` con
   `field` `lines`. Explica qué anillo cubre y qué hay que configurar para que no toque PostgreSQL.
4. 🟡 Quita `new StrictInteger` de `CreateProductRequest` y envía `"stock": "10"`. Explica qué pasó,
   dónde se convirtió el texto en entero y por qué el contrato prefiere rechazarlo.
5. 🟠 En `PgInventory::reserve`, sustituye `$this->db` del `INSERT` de la reserva por una conexión
   nueva: `DB::connectUsing('extra', config('database.connections.pgsql'))` (o `DB::purge` +
   `DB::connection`). Corre `04-orders.hurl` y compara con el error provocado del taller 05 (Go).
6. 🟠 Convierte `OutboxWork` en una tarea del scheduler
   (`Schedule::command('outbox:work --once')->everySecond()`) y corre `php artisan schedule:work`.
   Explica qué gana, qué pierde y por qué `--once` es obligatorio ahí.
7. 🔴 Sustituye `PgOrders` por una implementación con Eloquent (`OrderRow extends Model` con
   `HasMany` a `OrderLineRow`) que devuelva el mismo `Order` del dominio, manteniendo
   `DbUnitOfWork`. Mide cuántos archivos cambian y argumenta si el ORM compensa en este sistema.
8. 🔥 Corre el sabor bajo Laravel Octane (Swoole o FrankenPHP) en vez de `artisan serve`. Explica
   qué deja de ser cierto de "una petición es un proceso" (singletons, la conexión, el `Actor` en
   los atributos), qué se rompería en este taller y cómo lo resolverías.

---

**Siguiente:** [08 — Colas con JMS y ActiveMQ Artemis](08-colas-jms-activemq-artemis.md), primera
de las integraciones en Java (08–11).
