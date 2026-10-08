# 04 — TypeScript y NestJS

Este taller es **opcional** y depende solo de `06/01`. Sigue la estructura del taller 03 (Java) y
cambia únicamente dónde empuja el ecosistema: tipos que desaparecen al ejecutar, un contenedor
que necesita tokens para enlazar interfaces, una transacción que hay que compartir entre
adaptadores sin pasarla por parámetro, y promesas que necesitan dueño. Termina cuando la suite de
`06/01` pasa con el catálogo en PostgreSQL y con el catálogo en MongoDB.

> **Vigencia:** 2026-09-27. Versiones verificadas ese día en el registro de npm.

**Salto rápido:** [1](#1--qué-enseña-este-sabor) · [2](#2--prerrequisitos-y-versiones) · [3](#3-️-mapa-de-carpetas) · [4](#4--parte-1-el-núcleo-y-sus-bordes) · [5](#5--parte-2-cancelación-outbox-y-notifier) · [6](#6--parte-3-el-catálogo-a-mongodb) · [7](#7--pruebas-por-anillos) · [8](#8--errores-provocados-a-propósito) · [9](#9--cinco-plataformas) · [10](#10--teardown) · [Preguntas](#-preguntas) · [Ejercicios](#-ejercicios)

## 1. 🎯 Qué enseña este sabor

NestJS empuja hacia un diseño concreto: un `@Injectable() OrdersService` que recibe el
`PrismaService`, un DTO decorado que llega hasta la base, un `@Module` por "feature" que se
confunde con una frontera de negocio, y un `interface` inyectado que compila y explota al arrancar
porque en runtime la interfaz no existe. Este taller construye el mismo sistema que el 03 con Nest
en el borde y TypeScript ordinario en el centro:

```text
HTTP ─► @Controller ─► CreateOrder (clase sin decoradores) ─► Products / Inventory / Orders (interfaces)
                              │                                       ▲ enlazadas por Symbol
                       UnitOfWork (interfaz)              PrismaProducts · MongoProducts · PrismaInventory · PrismaOrders
                              │                                       │
                    prisma.$transaction(tx => als.run(tx, work))      prisma.db  ← la tx en curso, o el cliente
```

Cuatro decisiones que lo distinguen del diseño que Nest sugiere:

- **Los puertos son interfaces y los casos de uso clases sin decoradores.** Como una interfaz no
  existe en runtime, el composition root (`app.module.ts`) enlaza cada puerto con un `Symbol` y
  construye cada caso de uso con `useFactory`. Es el único módulo Nest del proyecto.
- **La transacción se comparte por contexto, no por parámetro.** `PrismaService.transaction`
  abre una transacción interactiva y la guarda en un `AsyncLocalStorage`; cada adaptador consulta
  `prisma.db`, que es la transacción en curso o el cliente raíz. El caso de uso no ve `tx`.
- **La validación es runtime y vive en el borde.** `class-validator` sobre los DTO, con un
  `ValidationPipe` global cuyo `exceptionFactory` produce un error propio; el núcleo recibe
  comandos con tipos propios que ya se comprobaron.
- **Toda promesa tiene dueño.** El dispatcher de la outbox es un `setInterval` que arranca en
  `onModuleInit`, se para en `onModuleDestroy` y no solapa rondas; Prisma, Mongo y Redis cierran
  con `enableShutdownHooks`.

El precio: 55 archivos donde el diseño "de starter" tendría veinte, y un `app.module.ts` de 120
líneas que hay que leer entero. La ganancia se ve en la parte 3: mover el catálogo a MongoDB es un
archivo de 62 líneas y una `useFactory` que ya existía.

## 2. 🧰 Prerrequisitos y versiones

| Herramienta | Versión fijada | Para qué |
|---|---|---|
| Node.js | 24 LTS | runtime |
| `@nestjs/core`, `common`, `platform-express` | `12.1.0` | contenedor, HTTP |
| `typescript` | `6.0.3` | la baseline del corpus |
| `prisma`, `@prisma/client`, `@prisma/adapter-pg`, `pg` | `7.10.0` / `8.23.0` | PostgreSQL con *driver adapter* |
| `mongodb` | `7.6.0` | catálogo en la parte 3, driver oficial |
| `redis` | `6.2.1` | revocación de tokens |
| `jose` | `6.2.12` | JWT HS256, emitir y verificar |
| `bcryptjs` | `3.0.3` | verificar los hashes `$2y$` de la semilla |
| `class-validator`, `class-transformer` | `0.15.1` / `0.5.1` | validación de forma en el borde |
| `vitest` | `5.0.2` | pruebas de dominio y aplicación |
| `dependency-cruiser` | `18.4.0` | la regla de dependencias como prueba |

Prisma 7 introspecciona el esquema compartido de `06/01` (`prisma db pull`) y genera un cliente
tipado en `src/infrastructure/outbound/postgres/generated/`, que **no** se versiona: `npm run
build` lo regenera. La URL de la base vive en `prisma.config.ts` (para la CLI) y en la
configuración (para el runtime), no en el `schema.prisma`.

```text
python3 06-talleres/laboratorio/scripts/lab.py nestjs
python3 06-talleres/laboratorio/scripts/lab.py nestjs --catalog mongo
python3 06-talleres/laboratorio/scripts/lab.py nestjs --test
```

- `nestjs` instala dependencias la primera vez, corre `npm run build` (`prisma generate` + `tsc`)
  y `npm start` (`node dist/main.js`) con `HEX_CATALOG` en el entorno del proceso. El backend
  queda en `http://localhost:8082` hasta `Ctrl+C`.
- `--catalog mongo` es la parte 3: mismo `dist/`, otra variable de entorno.
- `--test` corre `vitest` (dominio y caso de uso) y `depcruise` (dependencias). No necesita Docker.

No se usa `nest start` ni `ts-node`: Nest depende de `emitDecoratorMetadata` para inyectar por
tipo, y los transpiladores rápidos (esbuild, tsx) no lo emiten. `tsc` sí. Es un detalle del
ecosistema que decide la forma de arrancar.

## 3. 🗂️ Mapa de carpetas

```text
laboratorio/nestjs/
├── package.json · tsconfig.json · vitest.config.ts · .dependency-cruiser.cjs
├── prisma.config.ts · prisma/schema.prisma      introspección del esquema compartido
└── src/
    ├── main.ts                                  bootstrap: ValidationPipe, CORS, shutdown hooks, puerto 8082
    ├── domain/                                  money, product, order-line, order, payment, domain-event, errors
    ├── application/
    │   ├── actor.ts · page.ts · errors.ts
    │   ├── ports.ts                             TODAS las interfaces de salida, en un archivo
    │   └── usecases/                            login, logout, list-products, get-product, create-product,
    │                                            create-order, get-order, list-orders, authorize-payment,
    │                                            cancel-order, list-notifications, deliver-pending-publications
    └── infrastructure/
        ├── config/                              tokens.ts (los Symbol), config.ts (env), app.module.ts (composition root)
        ├── inbound/http/                        controllers, dto.ts, auth.guard.ts, actor.decorator.ts,
        │                                        problem.filter.ts, idempotency.ts
        ├── outbound/postgres/                   prisma.service.ts (cliente + tx actual), prisma-unit-of-work.ts,
        │                                        prisma-*.ts (un adaptador por puerto), table-notifier.ts, cursors.ts,
        │                                        generated/ (no versionado)
        ├── outbound/mongo/                      mongo-products.ts                      (parte 3)
        ├── outbound/redis/ · security/ · payment/
        └── outbound/notification/               outbox-dispatcher.ts                  (parte 2)
```

`domain/` y `application/` no importan `@nestjs`, `@prisma`, `mongodb`, `redis`, `jose` ni
`class-validator`. `.dependency-cruiser.cjs` lo convierte en una prueba.

## 4. 🧱 Parte 1: el núcleo y sus bordes

### El dominio, sin `double` y sin decoradores

`Money` guarda **centavos enteros**: `Money.of("49.90")` es `4990`, y `amountAsText()` devuelve
`"49.90"`. No hay `decimal.js` porque no hace falta: multiplicar y sumar enteros es exacto, y el
contrato serializa texto. `Order` es una clase con constructor privado, `place` y `reconstitute`,
y la máquina de estados en `applyPayment` y `cancel`:

```typescript
cancel(now: Date, eventId: string): boolean {
  if (this._status === "CANCELLED") return false;
  if (!this.isCancellable()) throw new OrderNotCancellable(this._status);
  this._status = "CANCELLED";
  this.events.push(new OrderCancelled(eventId, this.id, this.customerId, now));
  return true;
}
```

El `eventId` lo pasa el caso de uso desde el puerto `IdGenerator`: en el dominio no hay
`crypto.randomUUID()` porque un id es una dependencia, y en pruebas se quiere predecible.

### Los puertos son interfaces; el composition root los vuelve tokens

`application/ports.ts` declara `Products`, `Inventory`, `Orders`, `UnitOfWork`… como interfaces.
TypeScript las borra al compilar, así que Nest no puede inyectarlas por tipo. `config/tokens.ts`
declara un `Symbol` por puerto y `app.module.ts` hace el enlace:

```typescript
{ provide: ORDERS, useExisting: PrismaOrders },
{
  provide: PRODUCTS,
  useFactory: (cfg: HexConfig, prisma: PrismaProducts, mongo: MongoProducts): Products =>
    cfg.catalog === "mongo" ? mongo : prisma,
  inject: [CONFIG, PrismaProducts, MongoProducts],
},
{
  provide: CreateOrder,
  useFactory: (p: Products, i: Inventory, o: Orders, k: IdempotencyStore, ids: IdGenerator, c: Clock, u: UnitOfWork) =>
    new CreateOrder(p, i, o, k, ids, c, u),
  inject: [PRODUCTS, INVENTORY, ORDERS, IDEMPOTENCY_STORE, ID_GENERATOR, CLOCK, UNIT_OF_WORK],
},
```

Los casos de uso se registran con su propia clase como token (`provide: CreateOrder`) y se
construyen con `new`: no llevan `@Injectable()` ni saben que existe un contenedor. Los
controllers los piden con `@Inject(CreateOrder)`. Es el capítulo
[05/03](../05-plataformas-y-practica/03-node-y-typescript.md) en código: el token resuelve
composición; no convierte a `PrismaProducts` en buen puerto.

### La transacción compartida sin pasar `tx`

El problema que Prisma plantea: `$transaction(async tx => …)` da un cliente transaccional `tx`
que hay que usar en cada consulta de la unidad; si un repositorio usa el cliente raíz dentro de
la transacción, esa escritura no revierte. La solución obvia —que el caso de uso pase `tx` a cada
puerto— filtra Prisma al núcleo. La de este taller:

```typescript
@Injectable()
export class PrismaService implements OnModuleDestroy {
  readonly client: PrismaClient;
  private readonly current = new AsyncLocalStorage<Prisma.TransactionClient>();

  get db(): Prisma.TransactionClient {
    return this.current.getStore() ?? this.client;
  }

  transaction<T>(work: () => Promise<T>): Promise<T> {
    if (this.current.getStore()) return work();
    return this.client.$transaction((tx) => this.current.run(tx, work));
  }
}
```

`PrismaUnitOfWork.run` llama a `transaction`; cada adaptador consulta `this.prisma.db`. El
contexto viaja por la cadena de `await` y llega a todos los adaptadores que el caso de uso toque
dentro de `run`. El capítulo 05/03 advierte contra `AsyncLocalStorage` como fuente de actor o
autorización; aquí se usa **solo** para la transacción, y el comentario del archivo lo dice.

`AuthorizePayment` tiene, como en Java, dos unidades de trabajo con la llamada al proveedor entre
ambas y fuera de cualquier transacción.

### El borde: guard, pipe, filtro

- `AuthGuard` (registrado como `APP_GUARD`) verifica el JWT con `jose` (`jwtVerify`, HS256),
  consulta la revocación por `jti` en Redis y deja en la petición un `Actor` de aplicación.
  Distingue `UNAUTHENTICATED` de `TOKEN_REVOKED` lanzando un error propio con el código; el filtro
  lo traduce. Las rutas públicas llevan `@Public()`.
- `ValidationPipe` global con `whitelist` y `transform`, y un `exceptionFactory` que convierte
  los `ValidationError` de `class-validator` en un `ValidationFailed` propio con `field` y
  `message` por campo. `{ "lines": [] }` falla por `@ArrayMinSize(1)`; `"35"` como importe falla
  por el `@Matches` de `MoneyDto`.
- `ProblemFilter` (`APP_FILTER`, `@Catch()`) es el traductor central: cada error de dominio,
  aplicación o borde a `problem+json` con el `code` del contrato, y un `500` genérico con la
  causa en el registro para lo demás. Un id que no es UUID se convierte en `ValidationFailed`
  con un `ParseUUIDPipe` cuya `exceptionFactory` es nuestra, para que no salga el `400` de Nest.

`OrdersController.create` aplica las decisiones del contrato con `@Res({ passthrough: true })`:
`201` + `Location` al crear, `200` + `Idempotent-Replay` al repetir, y devuelve el cuerpo como
siempre.

### Las salidas

`PrismaInventory.reserve` descuenta con `updateMany({ where: { sku, available: { gte: q } },
data: { available: { decrement: q } } })` y lanza `InsufficientInventory` si `count` es `0`; la
transacción revierte las líneas anteriores. `PrismaOrders` crea el pedido con sus líneas en una
sola operación (`order_lines: { create: [...] }`) y reconstruye el agregado con `include` y el
último pago. `PrismaIdempotencyStore` escribe y lee `response_body` **como objeto**: Prisma
mapea `jsonb` a JSON, y el problema de "jsonb normaliza el texto" del taller 03 no puede
ocurrir aquí. `JoseTokenIssuer` emite `sub`, `email`, `role`, `jti`, `exp`; el secreto es el de
§11.

## 5. 🔁 Parte 2: cancelación, outbox y Notifier

`CancelOrder`, `DeliverPendingPublications` y `ListNotifications` son traducciones literales de
las de Java. Lo que cambia es el disparador:

```typescript
onModuleInit(): void {
  this.timer = setInterval(() => void this.poll(), this.config.outboxPollMs);
}
onModuleDestroy(): void {
  if (this.timer) clearInterval(this.timer);
}
private async poll(): Promise<void> {
  if (this.running) return;          // no solapar rondas
  this.running = true;
  try { await this.deliver.execute(50); }
  catch (e) { this.log.warn(...); }   // la siguiente ronda reintenta
  finally { this.running = false; }
}
```

Es "toda promesa tiene dueño" del capítulo 05/03 en treinta líneas: el intervalo se crea y se
destruye con el módulo (`app.enableShutdownHooks()` en `main.ts` hace que `onModuleDestroy` se
ejecute con `SIGINT`), y `void this.poll()` es explícito: la promesa no se espera, y se dice.
`TableNotifier` deduplica por `eventId` con `count` antes de insertar.

**Evidencia.** Inventario de la parte (el código se generó de una vez; quien lo haga en commits
tendrá el `git diff --stat` con estos nombres):

```text
-- parte 2: 9 archivos, 231 líneas
application/usecases/cancel-order.ts · deliver-pending-publications.ts · list-notifications.ts
domain/domain-event.ts
infrastructure/inbound/http/notifications.controller.ts
infrastructure/outbound/notification/outbox-dispatcher.ts
infrastructure/outbound/postgres/prisma-notifications.ts · prisma-pending-publications.ts · table-notifier.ts
```

Más un método en `Order`, uno en `OrdersController`, seis providers en `app.module.ts` y el
`OutboxDispatcher` registrado. `PrismaInventory`, `PrismaOrders`, `ProblemFilter` y `AuthGuard`
no se tocaron.

Salida literal de la suite completa, catálogo en PostgreSQL, 2026-09-27 — **a la primera**, sin
ninguna corrección entre el `tsc` en verde y el `7/7`:

```text
$ hurl --test --jobs 1 --variable base_url=http://localhost:8082 hurl/v1/01-health.hurl hurl/v1/02-auth.hurl hurl/v1/03-products.hurl hurl/v1/04-orders.hurl hurl/v1/05-payment.hurl hurl/v1.1/06-cancel.hurl hurl/v1.1/07-notifications.hurl
Success hurl/v1/01-health.hurl (1 request(s) in 2 ms)
Success hurl/v1/02-auth.hurl (9 request(s) in 184 ms)
Success hurl/v1/03-products.hurl (12 request(s) in 194 ms)
Success hurl/v1/04-orders.hurl (20 request(s) in 233 ms)
Success hurl/v1/05-payment.hurl (14 request(s) in 149 ms)
Success hurl/v1.1/06-cancel.hurl (19 request(s) in 230 ms)
Success hurl/v1.1/07-notifications.hurl (10 request(s) in 2209 ms)
--------------------------------------------------------------------------------
Executed files:    7
Executed requests: 85 (26.5/s)
Succeeded files:   7 (100.0%)
Failed files:      0 (0.0%)
Duration:          3211 ms (0h:0m:3s:211ms)
```

💡 Que pasara a la primera no es mérito de NestJS: es que el contrato, la suite, el esquema y
las lecciones del taller 03 (guardar el pedido antes de reservar; leer `jsonb` como JSON;
distinguir revocado de no autenticado en el borde) ya estaban pagadas. El segundo sabor cuesta
la mitad que el primero, y eso también es una medida de la arquitectura.

## 6. 🔀 Parte 3: el catálogo a MongoDB

Un archivo: `outbound/mongo/mongo-products.ts`, con el driver oficial (`MongoClient`), la
colección `products` con la forma de `seed/products.json`, la misma paginación por cursor que
`PrismaProducts`, y `onModuleInit`/`onModuleDestroy` para conectar y cerrar. La `useFactory` de
`PRODUCTS` ya elegía por `cfg.catalog`. Nada más.

```text
python3 06-talleres/laboratorio/scripts/lab.py seed --mongo
python3 06-talleres/laboratorio/scripts/lab.py nestjs --catalog mongo
python3 06-talleres/laboratorio/scripts/lab.py suite --base-url http://localhost:8082
```

```text
hex-orders-nestjs listening on :8082 (catalog=mongo)
Success hurl/v1/01-health.hurl (1 request(s) in 1 ms)
Success hurl/v1/02-auth.hurl (9 request(s) in 180 ms)
Success hurl/v1/03-products.hurl (12 request(s) in 189 ms)
Success hurl/v1/04-orders.hurl (20 request(s) in 220 ms)
Success hurl/v1/05-payment.hurl (14 request(s) in 168 ms)
Success hurl/v1.1/06-cancel.hurl (19 request(s) in 219 ms)
Success hurl/v1.1/07-notifications.hurl (10 request(s) in 2197 ms)
--------------------------------------------------------------------------------
Executed files:    7
Executed requests: 85 (26.7/s)
Succeeded files:   7 (100.0%)
Failed files:      0 (0.0%)
Duration:          3181 ms (0h:0m:3s:181ms)
```

La contraprueba, idéntica a la del taller 03: los productos que la suite da de alta están en
Mongo, no en la tabla `products`, y el inventario sigue en PostgreSQL.

```text
$ docker exec hex-mongo mongosh --quiet hex_catalog --eval 'db.products.find({sku:{$in:["SKU-006","SKU-101"]}},{_id:0,sku:1,name:1}).toArray()'
[ { name: 'Laptop stand', sku: 'SKU-006' }, { name: 'Cancel test item', sku: 'SKU-101' } ]
$ docker exec hex-postgres psql -U hex -d hex_orders -Atc "select count(*) from products where sku in ('SKU-006','SKU-101')"
0
$ docker exec hex-postgres psql -U hex -d hex_orders -Atc "select sku, available from inventory where sku in ('SKU-006','SKU-101') order by sku"
SKU-006|10
SKU-101|6
```

Inventario de la parte: `62` líneas en un archivo; en `domain/`, `application/` e `inbound/`,
cero.

📝 `MongoProducts` no participa de la transacción de Prisma: `CreateProduct` guarda el catálogo en
Mongo y el inventario en PostgreSQL dentro de `unitOfWork.run`, y si el `INSERT` del inventario
falla, el documento de Mongo se queda. Es la consistencia entre dos almacenes del capítulo 02/05:
la unidad de trabajo cubre solo los recursos locales. El taller lo acepta para un alta de catálogo
y lo declara; el ejercicio 6 pide resolverlo.

## 7. 🧪 Pruebas por anillos

- `src/domain/order.test.ts` (vitest): la máquina de estados, `Money` sin coma flotante.
- `src/application/usecases/create-order.test.ts`: el caso de uso con fakes fieles a los puertos
  y un `SnapshotUnitOfWork` que restaura los fakes si el trabajo lanza; la última prueba afirma que
  tras un `InsufficientInventory` no queda pedido, ni reserva, ni clave.
- `.dependency-cruiser.cjs`: tres reglas, las mismas que ArchUnit en Java.

```text
$ npx vitest run --reporter=verbose
 ✓ src/domain/order.test.ts > Order > rejects an order without lines 1ms
 ✓ src/domain/order.test.ts > Order > is CONFIRMED when placed and totals its lines without floating point 0ms
 ✓ src/domain/order.test.ts > Order > authorized → PAID, and PAID is neither payable nor cancellable 0ms
 ✓ src/domain/order.test.ts > Order > rejected stays payable; pending does not but is cancellable 0ms
 ✓ src/domain/order.test.ts > Order > cancel is idempotent and emits the fact once 1ms
 ✓ src/application/usecases/create-order.test.ts > CreateOrder > reserves stock and remembers the key 1ms
 ✓ src/application/usecases/create-order.test.ts > CreateOrder > same key, same body: replays without reserving again 0ms
 ✓ src/application/usecases/create-order.test.ts > CreateOrder > same key, different body: rejected 0ms
 ✓ src/application/usecases/create-order.test.ts > CreateOrder > insufficient inventory leaves nothing behind (the unit of work reverts) 0ms
 Test Files  2 passed (2)
      Tests  9 passed (9)
$ npx depcruise src --config .dependency-cruiser.cjs
✔ no dependency violations found (67 modules, 166 dependencies cruised)
```

Vitest corre `domain/` y `application/` sin `emitDecoratorMetadata` porque ahí no hay
decoradores; es la razón práctica de que el núcleo no importe Nest. Lo que no hay, y se declara:
pruebas del adaptador Prisma contra PostgreSQL; la suite `hurl` cubre ese anillo de extremo a
extremo.

## 8. 🩺 Errores provocados a propósito

Dos fallos reales de la construcción, ambos en compilación, ninguno en la suite.

### `prisma db pull` reescribió el generador

```text
src/infrastructure/outbound/postgres/prisma.service.ts(6,43): error TS2307: Cannot find module './generated/client.js' or its corresponding type declarations.
src/infrastructure/outbound/postgres/prisma-inventory.ts(18,30): error TS7006: Parameter 'r' implicitly has an 'any' type.
```

El `schema.prisma` se había escrito con `output = "../src/infrastructure/outbound/postgres/generated"`,
pero `prisma db pull` **reescribe el archivo entero**, incluido el bloque `generator`, y lo dejó
en `output = "./generated"` (relativo a `prisma/`). El cliente se generó en `prisma/generated/`,
los `import` no lo encontraron y una cascada de `any` implícitos siguió al primer error.
Corrección: fijar el bloque `generator` después de la introspección y regenerar. Lección: una
herramienta que "sincroniza" desde la base es dueña del archivo que toca; lo que uno añade a mano
hay que volver a comprobarlo después de cada `pull`.

### `_id` en `replaceOne`: el driver de Mongo sabe más que tú de tu documento

```text
src/infrastructure/outbound/mongo/mongo-products.ts(54,9): error TS2353: Object literal may only specify known properties, and '_id' does not exist in type 'WithoutId<ProductDoc>'.
```

`replaceOne` recibe el documento de reemplazo **sin** `_id` (el tipo `WithoutId<T>`), porque el
`_id` no se puede reemplazar. Corrección: `updateOne` con `$set` y `upsert: true`, que es además
lo que el `save` del puerto significa. Lección: un tipo de driver que rechaza el código suele
estar describiendo una regla de la base, no un capricho.

Comparado con el taller 03 —cinco fallos, tres de ellos en la suite— aquí la suite pasó a la
primera. La diferencia no es el lenguaje: es que las decisiones que en Java se aprendieron con
un `500` (orden pedido→reserva, `jsonb`, revocación) ya estaban tomadas.

## 9. 🧰 Cinco plataformas

| Plataforma | Qué da hecho | Qué te deja a ti | Trampa frecuente |
|---|---|---|---|
| Java · Spring Boot | contenedor por tipo, `TransactionTemplate`, JPA, resource server | casos de uso sin anotaciones, `UnitOfWork`, dos modelos, ArchUnit | `@Transactional` y *self-invocation*; devolver la `@Entity` |
| **Node/TS · NestJS** | contenedor por token, pipes, guards, filtros, `$transaction` interactiva | tokens para interfaces borradas, `AsyncLocalStorage` solo para la transacción, `useFactory` para casos de uso sin decoradores, promesas con dueño, `tsc` por `emitDecoratorMetadata` | inyectar una `interface`; pasar `tx` a los puertos; `publish()` sin `await`; un DTO decorado como comando |
| Go · `net/http` | `sql.Tx`, `context`, `httptest` | composición manual en `main`, interfaces junto al consumidor | `db` dentro de `tx`; paquete `interfaces` |
| Python · FastAPI | `Depends`, Pydantic, SQLAlchemy | `Protocol` como puerto, sesión controlada | `HTTPException` desde el dominio |
| PHP · Laravel | service container, Eloquent, form requests | que el modelo Eloquent no sea el dominio | *active record* como agregado y DTO |

## 10. 🧹 Teardown

`Ctrl+C` en la terminal de `lab.py nestjs`: `enableShutdownHooks` cierra Prisma, Mongo, Redis y
el intervalo de la outbox. El entorno se apaga con `lab.py down`. `dist/`, `node_modules/` y el
cliente generado están en `.gitignore`.

## ⚠️ Errores frecuentes

- "Con `@Injectable()` en el caso de uso, Nest lo construye solo." Sí, y entonces el caso de uso
  importa `@nestjs/common` y `depcruise` lo rechaza; con `useFactory` no hace falta.
- "Un `interface` se puede inyectar." Compila y falla al arrancar: "Nest can't resolve
  dependencies". Hace falta un token.
- "`AsyncLocalStorage` ya resuelve el actor también." Puede, y esconde una entrada de la
  política; aquí se limita a la transacción y el actor va por parámetro.
- "`prisma db pull` solo toca los modelos." Reescribe el archivo entero.
- "Prisma 7 se conecta con la URL del `schema.prisma`." Ya no: la URL va en `prisma.config.ts` y,
  en runtime, en el adaptador del driver.
- "`tsx` o `nest start` da igual." Con inyección por tipo hace falta `emitDecoratorMetadata`, que
  esbuild no emite.

## ✅ Veredicto

Nest en el borde (guard, pipe, filtro, módulo), TypeScript ordinario en el centro, y la frontera
verificada por `depcruise` y una suite que pasa dos veces. Lo específico de este ecosistema —tokens,
transacción por contexto, promesas con dueño, `tsc`— cabe en cuatro archivos de infraestructura.
Que el segundo sabor pasara a la primera es la mejor evidencia de que el contrato y el esquema
compartidos hacen su trabajo.

## 📚 Referencias

- [NestJS: custom providers y tokens](https://docs.nestjs.com/fundamentals/custom-providers) · [guards](https://docs.nestjs.com/guards) · [exception filters](https://docs.nestjs.com/exception-filters) · [validación](https://docs.nestjs.com/techniques/validation) · [ciclo de vida de módulos](https://docs.nestjs.com/fundamentals/lifecycle-events)
- [Prisma 7: driver adapters](https://www.prisma.io/docs/orm/v7/core-concepts/supported-databases/database-drivers) · [transacciones](https://www.prisma.io/docs/orm/fundamentals/transactions) · [introspección](https://www.prisma.io/docs/orm/v7/prisma-schema/introspection) · [`prisma.config.ts`](https://www.prisma.io/docs/orm/v7/reference/prisma-config-reference)
- [Node.js: `AsyncLocalStorage`](https://nodejs.org/api/async_context.html)
- [jose: `SignJWT`](https://github.com/panva/jose/blob/main/docs/jwt/sign/classes/SignJWT.md)
- [class-validator](https://github.com/typestack/class-validator/blob/develop/README.md)
- [dependency-cruiser: reglas](https://github.com/sverweij/dependency-cruiser/blob/main/doc/rules-reference.md)

## 🧠 Preguntas

1. 🟢 ¿Por qué los puertos necesitan un `Symbol` en NestJS y no en Spring?
2. 🟢 ¿Qué hace `useFactory` en `app.module.ts` y por qué los casos de uso no llevan `@Injectable()`?
3. 🟢 ¿Qué es `prisma.db` y qué devuelve dentro y fuera de una transacción?
4. 🟢 ¿Por qué `Money` guarda centavos enteros en lugar de usar `decimal.js`?
5. 🟢 ¿Por qué el proyecto se arranca con `tsc` + `node` y no con `nest start` o `tsx`?
6. 🟡 ¿Qué problema resuelve `AsyncLocalStorage` en `PrismaService` y qué problema NO debe resolver?
7. 🟡 ¿Cómo distingue el borde `TOKEN_REVOKED` de `UNAUTHENTICATED`, y dónde se decide cada cosa?
8. 🟡 ¿Por qué `ValidationPipe` lleva un `exceptionFactory` propio en vez de dejar el `400` de Nest?
9. 🟡 ¿Qué hace que el `OutboxDispatcher` sea "una promesa con dueño"? Nombra los tres mecanismos.
10. 🟡 El problema de "jsonb normaliza el texto" del taller 03 no aparece aquí. ¿Por qué?
11. 🟠 `CreateProduct` con el catálogo en Mongo guarda en dos almacenes dentro de `unitOfWork.run`. ¿Qué garantiza la unidad de trabajo y qué no?
12. 🟠 `prisma db pull` dejó el cliente generado en el sitio equivocado. ¿Qué regla del bloque se aplicó al diagnosticarlo y qué habría pasado sin `tsc --noEmit` antes de arrancar?
13. 🟠 La suite pasó a la primera. Da tres razones concretas, y explica por qué ninguna es "NestJS es mejor que Spring".
14. 🟠 Un compañero propone un `@Module` por agregado (`OrdersModule`, `ProductsModule`) "para que sea más hexagonal". ¿Qué le respondes?

## 🧪 Ejercicios

1. 🟢 Cambia `{ provide: ORDERS, useExisting: PrismaOrders }` por inyectar `Orders` (la interfaz)
   en `GetOrder` con `@Inject(Orders)`. Compila y arranca. Pega el error de Nest y explica por qué
   `tsc` no lo detectó.
2. 🟢 Añade `@Injectable()` a `CreateOrder` y corre `lab.py nestjs --test`. Pega la violación de
   `depcruise` y explica qué regla la produjo.
3. 🟡 En `PrismaInventory.reserve`, sustituye `this.prisma.db` por `this.prisma.client` solo en
   el `create` de la reserva. Corre `04-orders.hurl` y explica qué queda en `inventory_reservations`
   tras un `409` y por qué la suite no lo detecta.
4. 🟡 Escribe la prueba de `AuthorizePayment` con fakes: autorizado, rechazado y pendiente por
   importe, y la repetición idempotente. Explica qué doble de `PaymentGateway` usas y por qué no
   el `DeterministicPaymentGateway` real.
5. 🟠 Cambia `outboxPollMs` a `5000`, corre `07-notifications.hurl` y mide. Luego mata el proceso
   con `SIGINT` en medio de una ronda y comprueba en el registro que `onModuleDestroy` se ejecutó
   y que la fila de outbox quedó pendiente, no perdida.
6. 🟠 Resuelve la escritura en dos almacenes de `CreateProduct` con catálogo en Mongo: ordena las
   operaciones para que un fallo deje el sistema recuperable, o introduce una compensación.
   Argumenta cuál, y qué dice el capítulo 02/05 al respecto.
7. 🔴 Sustituye `AsyncLocalStorage` por un `UnitOfWork` que devuelva un "contexto de transacción"
   opaco que los adaptadores acepten como parámetro opcional, sin que el núcleo importe Prisma.
   Compara ambos diseños: qué se hace explícito, qué se vuelve ceremonia.
8. 🔥 Escribe una prueba de contrato del puerto `Orders` que corra contra `PrismaOrders` (con el
   entorno de `06/01` arriba) y contra `InMemoryOrders` (sin nada), con la misma batería. Decide
   cómo distinguir en `vitest` las pruebas que necesitan Docker de las que no.

---

**Siguiente:** [05 — Go](05-caso-go.md), o cualquier otro sabor.
