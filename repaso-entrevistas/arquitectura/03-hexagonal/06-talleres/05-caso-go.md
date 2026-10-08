# 05 — Go

Este taller es **opcional** y depende solo de `06/01`. Sigue la estructura del taller 03 y cambia
lo que Go cambia: no hay contenedor ni decoradores, la transacción viaja en el `context`, las
interfaces se satisfacen sin declararlo, los errores son valores que se clasifican con
`errors.As`, y el cierre ordenado es responsabilidad de `main`. Termina cuando la suite de `06/01`
pasa con el catálogo en PostgreSQL y con el catálogo en MongoDB.

> **Vigencia:** 2026-09-27. Versiones verificadas ese día en proxy.golang.org.

**Salto rápido:** [1](#1--qué-enseña-este-sabor) · [2](#2--prerrequisitos-y-versiones) · [3](#3-️-mapa-de-carpetas) · [4](#4--parte-1-el-núcleo-y-sus-bordes) · [5](#5--parte-2-cancelación-outbox-y-notifier) · [6](#6--parte-3-el-catálogo-a-mongodb) · [7](#7--pruebas-por-anillos) · [8](#8--errores-provocados-a-propósito) · [9](#9--cinco-plataformas) · [10](#10--teardown) · [Preguntas](#-preguntas) · [Ejercicios](#-ejercicios)

## 1. 🎯 Qué enseña este sabor

Go no empuja hacia un framework; empuja hacia la ceremonia contraria: un paquete `handlers` que
abre SQL, un `services` que devuelve `sql.ErrNoRows` al cliente, y —cuando alguien "hace
hexagonal"— una interfaz por struct y un paquete `interfaces` que nadie consume. Este taller
construye el mismo sistema que el 03 con la biblioteca estándar en el borde, `pgx` detrás de un
puerto, y cuatro decisiones que son las del capítulo [05/04](../05-plataformas-y-practica/04-go.md):

```text
HTTP ─► net/http (ServeMux 1.22+) ─► application.CreateOrder (struct con campos-puerto)
                                           │                    ▲
                                    UnitOfWork.Run(ctx, fn)     postgres.Products / Inventory / Orders … (satisfacen la interfaz sin declararlo)
                                           │
                             postgres.DB: la tx viaja en ctx; Q(ctx) devuelve tx o pool
```

- **Las interfaces viven junto al consumidor** (`application/ports.go`) y son pequeñas. Los
  adaptadores no dicen `implements`; el compilador comprueba en `main` que encajan.
- **La transacción es un `context`.** `DB.Run(ctx, fn)` abre `pgx.Tx`, lo guarda en el contexto y
  llama a `fn(ctx)`; cada adaptador hace `db.Q(ctx)` y recibe la transacción si la hay, el pool si
  no. El caso de uso no ve `tx`, y ningún adaptador puede usar `db` "por error" dentro de una
  transacción… salvo que lo haga a propósito (§8).
- **Los errores son valores.** El dominio devuelve `domain.InsufficientInventory{…}`; el borde hace
  `errors.As` y elige el `409`. Sin excepciones, sin jerarquías: un `switch` de veinte líneas es
  el traductor central.
- **`main` es el composition root y el dueño del cierre.** Abre el pool, Redis y Mongo, construye
  los structs, arranca el servidor y el dispatcher con un `context` cancelable, y apaga en orden
  con `signal.NotifyContext`.

El precio: 39 archivos y `if err != nil` en cada línea que toca I/O; ningún contenedor que
ensamble por ti. La ganancia se ve en la parte 3 —un archivo— y en que el grafo entero cabe en
`main.go` y se lee de arriba abajo.

## 2. 🧰 Prerrequisitos y versiones

| Herramienta | Versión fijada | Para qué |
|---|---|---|
| Go | `1.27.1` (`go.mod`: `go 1.27`) | toolchain; el router con métodos exige ≥ 1.22 |
| `github.com/jackc/pgx/v5` | `v5.11.0` | PostgreSQL, pool y transacciones |
| `go.mongodb.org/mongo-driver/v2` | `v2.9.1` | catálogo en la parte 3 |
| `github.com/redis/go-redis/v9` | `v9.22.0` | revocación de tokens |
| `github.com/golang-jwt/jwt/v5` | `v5.3.1` | JWT HS256 |
| `golang.org/x/crypto` | `v0.57.0` | bcrypt |

No hay router de terceros, ni librería de validación, ni de inyección, ni de UUID: `net/http`
enruta por método y patrón desde Go 1.22, la validación es código, la composición es `main`, y un
UUID v4 son dieciséis bytes de `crypto/rand`.

```text
python3 06-talleres/laboratorio/scripts/lab.py go
python3 06-talleres/laboratorio/scripts/lab.py go --catalog mongo
python3 06-talleres/laboratorio/scripts/lab.py go --test
```

- `go` corre `go run ./cmd/server` en `laboratorio/go/` con `HEX_CATALOG` en el entorno del
  proceso. El backend queda en `http://localhost:8083` hasta `Ctrl+C`.
- `--catalog mongo` es la parte 3: mismo binario, otra variable de entorno.
- `--test` corre `go vet ./...` y `go test ./...`: dominio, caso de uso y la regla de dependencias.

## 3. 🗂️ Mapa de carpetas

```text
laboratorio/go/
├── go.mod · go.sum
├── cmd/server/main.go                         composition root: recursos, grafo, servidor, cierre
└── internal/                                  nadie fuera del módulo puede importar esto
    ├── domain/                                money, product, order, event, errors
    ├── application/
    │   ├── actor.go · page.go · errors.go
    │   ├── ports.go                           TODAS las interfaces de salida, junto a quien las consume
    │   └── auth.go · products.go · orders.go · payments.go · cancel.go · notifications.go   (casos de uso)
    ├── infrastructure/
    │   ├── config/config.go
    │   ├── inbound/httpin/                    server.go (mux), auth.go (middleware), dto.go, handlers.go,
    │   │                                      problem.go (errors.As → problem+json), idempotency.go
    │   └── outbound/
    │       ├── postgres/                      db.go (pool + tx en ctx + UnitOfWork), users, products, inventory,
    │       │                                  orders, payments, idempotency, outbox, notifications (+ TableNotifier), cursors
    │       ├── mongocatalog/products.go       (parte 3)
    │       ├── redisstore/ · security/ · payment/
    │       └── notification/dispatcher.go     (parte 2)
    └── arch/arch_test.go                      la regla de dependencias con go/parser
```

`domain/` importa solo la biblioteca estándar; `application/` importa `domain` y la biblioteca
estándar. `arch_test.go` lo comprueba leyendo los `import` de cada archivo.

## 4. 🧱 Parte 1: el núcleo y sus bordes

### El dominio con campos privados y errores como valores

`Order` tiene campos sin exportar y getters; el estado solo cambia por `ApplyPayment` y `Cancel`,
que devuelven errores tipados en vez de lanzarlos:

```go
func (o *Order) Cancel(now time.Time, eventID string) (bool, error) {
    if o.status == StatusCancelled {
        return false, nil
    }
    if !o.IsCancellable() {
        return false, OrderNotCancellable{Status: o.status}
    }
    o.status = StatusCancelled
    o.events = append(o.events, OrderCancelled{ID: eventID, Order: o.id, Customer: o.customerID, Occurred: now})
    return true, nil
}
```

`Money` es `int64` de centavos; `ParseMoney("49.90")` y `Text()` son la única conversión. Los
identificadores son `string`: un UUID en el dominio sería una dependencia (no hay `uuid` en la
biblioteca estándar) y el dominio no la necesita para decidir nada.

### Los casos de uso son structs con campos-puerto

```go
type CreateOrder struct {
    Products    Products
    Inventory   Inventory
    Orders      Orders
    Idempotency IdempotencyStore
    IDs         IDGenerator
    Clock       Clock
    UnitOfWork  UnitOfWork
}

func (uc CreateOrder) Execute(ctx context.Context, cmd CreateOrderCommand) (CreateOrderResult, error) {
    var result CreateOrderResult
    err := uc.UnitOfWork.Run(ctx, func(ctx context.Context) error {
        // … idempotencia, catálogo, PlaceOrder, Orders.Save, Inventory.Reserve, Idempotency.Save
    })
    return result, err
}
```

Sin constructor, sin contenedor: `main` escribe `application.CreateOrder{Products: products, …}`
y el compilador exige que cada campo sea del tipo de la interfaz. El `ctx` que recibe la función
es el que lleva la transacción; el que recibe `Execute` es el de la petición (cancelación,
deadline). `AuthorizePayment` usa dos `Run` con la llamada al proveedor entre ambos, fuera de
cualquier transacción, como en los otros sabores.

### La transacción viaja en el `context`

```go
func (d *DB) Q(ctx context.Context) Querier {
    if tx, ok := ctx.Value(txKey{}).(pgx.Tx); ok {
        return tx
    }
    return d.Pool
}

func (d *DB) Run(ctx context.Context, fn func(ctx context.Context) error) error {
    if _, ok := ctx.Value(txKey{}).(pgx.Tx); ok {
        return fn(ctx) // ya hay una: se reutiliza
    }
    tx, err := d.Pool.Begin(ctx)
    if err != nil {
        return err
    }
    defer func() { _ = tx.Rollback(ctx) }() // tras Commit devuelve ErrTxClosed: inofensivo
    if err := fn(context.WithValue(ctx, txKey{}, tx)); err != nil {
        return err
    }
    return tx.Commit(ctx)
}
```

`*DB` es el pool y a la vez el adaptador de `UnitOfWork`. Es la versión explícita de lo que
NestJS hacía con `AsyncLocalStorage`: el contexto va por parámetro y se ve en cada firma. Y es la
respuesta a la trampa de 05/04 —"ejecutar una query con `db` en vez de `tx`"—: los adaptadores
no eligen; llaman a `Q(ctx)`. El error de Commit no lo oculta el `Rollback` diferido porque se
devuelve antes.

### El borde: `ServeMux`, middleware y `errors.As`

- `server.go` registra patrones con método (`"POST /api/v1/orders/{orderId}/payment"`) y envuelve el
  mux con `cors` y `authenticate`. Sin router de terceros.
- `authenticate` verifica el JWT (`golang-jwt`, HS256, `WithValidMethods`), consulta la revocación
  por `jti` en Redis y deja un `application.Actor` en el contexto. Las rutas públicas son una
  función de tres líneas (`isPublic`), no un decorador.
- `dto.go` valida a mano: `loginRequest.validate()` devuelve `validationFailed{[]fieldError}`;
  `createOrderRequest.validate()` acumula errores por línea. Los enteros opcionales son `*int`
  para distinguir "falta" de "cero".
- `problem.go` es el traductor central: un `switch` con `errors.As` y `errors.Is` por cada error
  propio, y un `default` que registra la causa y responde `500` genérico.

```go
case errors.As(err, &insufficient):
    writeProblem(w, r, problem{Status: 409, Title: "Insufficient inventory", Code: "INSUFFICIENT_INVENTORY", Detail: err.Error(),
        Errors: []fieldError{{Field: "lines[" + itoa(insufficient.LineIndex) + "].quantity",
            Message: "requested " + itoa(insufficient.Requested) + ", available " + itoa(insufficient.Available)}}})
```

### Las salidas: SQL a mano, sin ORM

`postgres.Inventory.Reserve` descuenta con `UPDATE … WHERE sku = $1 AND available >= $2` y mira
`RowsAffected()`; `postgres.Orders` hace un `UPDATE` y, si no tocó filas, `INSERT` del pedido y
sus líneas; los importes van como texto (`unit_price::text`, `$4::numeric`) y los UUID como
`$1::uuid`. `jsonb` se escribe y lee con `encoding/json`: el problema del taller 03 no puede
ocurrir. `security.JWT` implementa a la vez el puerto `TokenIssuer` (para `Login`) y la interfaz
`TokenVerifier` del borde: un solo tipo, dos contratos, ninguno lo declara.

## 5. 🔁 Parte 2: cancelación, outbox y Notifier

`CancelOrder`, `DeliverPendingPublications` y `ListNotifications` son traducciones literales. Lo
que Go cambia es el disparador:

```go
func (d Dispatcher) Run(ctx context.Context) {
    ticker := time.NewTicker(d.Interval)
    defer ticker.Stop()
    for {
        select {
        case <-ctx.Done():
            return
        case <-ticker.C:
            delivered, err := d.Deliver.Execute(ctx, 50)
            // …
        }
    }
}
```

`main` la arranca con `go dispatcher.Run(ctx)` y la para cancelando el contexto que
`signal.NotifyContext` cierra con `Ctrl+C`. Es la trampa de 02/07 ("lanzar una goroutine y
perder el error") resuelta por construcción: la goroutine tiene un contexto, un `select` y un
registro por ronda. `TableNotifier` deduplica con `ON CONFLICT (id) DO NOTHING`: la clave primaria
es la garantía, y es atómica entre dos dispatchers.

**Evidencia.** Inventario de la parte (el código se generó de una vez):

```text
-- parte 2: 6 archivos, 294 líneas
application/cancel.go · application/notifications.go · domain/event.go
infrastructure/outbound/notification/dispatcher.go
infrastructure/outbound/postgres/outbox.go · postgres/notifications.go (con TableNotifier)
```

Más `Cancel`/`PullEvents` en `Order`, un handler y una ruta en `httpin`, y cinco líneas en `main`.

Salida literal de la suite completa, catálogo en PostgreSQL, 2026-09-27, **a la primera**:

```text
$ hurl --test --jobs 1 --variable base_url=http://localhost:8083 hurl/v1/01-health.hurl hurl/v1/02-auth.hurl hurl/v1/03-products.hurl hurl/v1/04-orders.hurl hurl/v1/05-payment.hurl hurl/v1.1/06-cancel.hurl hurl/v1.1/07-notifications.hurl
Success hurl/v1/01-health.hurl (1 request(s) in 1 ms)
Success hurl/v1/02-auth.hurl (9 request(s) in 142 ms)
Success hurl/v1/03-products.hurl (12 request(s) in 149 ms)
Success hurl/v1/04-orders.hurl (20 request(s) in 167 ms)
Success hurl/v1/05-payment.hurl (14 request(s) in 104 ms)
Success hurl/v1.1/06-cancel.hurl (19 request(s) in 159 ms)
Success hurl/v1.1/07-notifications.hurl (10 request(s) in 2156 ms)
--------------------------------------------------------------------------------
Executed files:    7
Executed requests: 85 (29.4/s)
Succeeded files:   7 (100.0%)
Failed files:      0 (0.0%)
Duration:          2888 ms (0h:0m:2s:888ms)
```

## 6. 🔀 Parte 3: el catálogo a MongoDB

Un paquete: `outbound/mongocatalog`, con el driver oficial v2, un `document` con etiquetas `bson`
(la forma de `seed/products.json`), la misma paginación por cursor, `Open` que hace `Ping` y
`Close` que desconecta. Y en `main`:

```go
var products application.Products = postgres.Products{DB: db}
if cfg.Catalog == "mongo" {
    mongoProducts, err := mongocatalog.Open(ctx, cfg.MongoURL)
    // …
    defer mongoProducts.Close(context.Background())
    products = mongoProducts
}
```

La variable es de tipo interfaz; las dos implementaciones encajan sin declararlo. Mongo solo se
abre si se va a usar: en modo `postgres` el binario no toca el puerto `17017`.

```text
python3 06-talleres/laboratorio/scripts/lab.py seed --mongo
python3 06-talleres/laboratorio/scripts/lab.py go --catalog mongo
python3 06-talleres/laboratorio/scripts/lab.py suite --base-url http://localhost:8083
```

```text
INFO hex-orders-go listening port=8083 catalog=mongo
Success hurl/v1/01-health.hurl (1 request(s) in 0 ms)
Success hurl/v1/02-auth.hurl (9 request(s) in 136 ms)
Success hurl/v1/03-products.hurl (12 request(s) in 141 ms)
Success hurl/v1/04-orders.hurl (20 request(s) in 169 ms)
Success hurl/v1/05-payment.hurl (14 request(s) in 110 ms)
Success hurl/v1.1/06-cancel.hurl (19 request(s) in 176 ms)
Success hurl/v1.1/07-notifications.hurl (10 request(s) in 2224 ms)
--------------------------------------------------------------------------------
Executed files:    7
Executed requests: 85 (28.7/s)
Succeeded files:   7 (100.0%)
Failed files:      0 (0.0%)
Duration:          2964 ms (0h:0m:2s:964ms)
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

Inventario de la parte: `108` líneas en un archivo y siete en `main`; en `domain/`,
`application/` e `inbound/`, cero.

## 7. 🧪 Pruebas por anillos

- `domain/order_test.go`: la máquina de estados con `errors.Is`/`errors.As` sobre los errores
  tipados; `Money` sin coma flotante.
- `application/create_order_test.go`: fakes fieles a los puertos y un `snapshotUnitOfWork` que
  clona los mapas (`maps.Clone`) y los restaura si `fn` devuelve error.
- `arch/arch_test.go`: recorre `domain/`, `application/` e `inbound/` con `go/parser` en modo
  `ImportsOnly` y falla si algún archivo importa un prefijo prohibido. Treinta líneas, sin
  dependencias: el ArchUnit de Go.

```text
$ go test ./... -v
--- PASS: TestCreateOrderReservesAndRemembersKey (0.00s)
--- PASS: TestCreateOrderReplaysSameKeySameBody (0.00s)
--- PASS: TestCreateOrderRejectsSameKeyDifferentBody (0.00s)
--- PASS: TestInsufficientInventoryLeavesNothingBehind (0.00s)
ok  	hexorders/internal/application	0.860s
--- PASS: TestDependencyRule (0.00s)
ok  	hexorders/internal/arch	0.314s
--- PASS: TestPlaceOrderRejectsEmpty (0.00s)
--- PASS: TestPlaceOrderTotalsWithoutFloats (0.00s)
--- PASS: TestPaidIsNeitherPayableNorCancellable (0.00s)
--- PASS: TestRejectedStaysPayablePendingDoesNot (0.00s)
--- PASS: TestCancelIsIdempotentAndEmitsOnce (0.00s)
ok  	hexorders/internal/domain	0.593s
```

`go vet ./...` no dijo nada. Lo que no hay, y se declara: pruebas del adaptador `postgres` con
una base real (la suite las cubre de extremo a extremo) y `httptest` sobre los handlers con dobles
(ejercicio 5).

## 8. 🩺 Errores provocados a propósito

La construcción no produjo ningún fallo: `go vet`, `go build`, `go test` y la suite pasaron a la
primera, con el catálogo en PostgreSQL y en MongoDB. Por eso el error de esta parte se provocó a
mano, y es el que el capítulo 05/04 nombra como trampa: **`db` dentro de una operación con `tx`**.

Se cambió una línea de `postgres.Inventory.Reserve`: el `INSERT` de la reserva pasó a usar
`i.DB.Pool.Exec` en vez de `q.Exec` (el `Querier` de `Q(ctx)`), es decir, el pool y no la
transacción. Se compiló y se corrió solo `04-orders.hurl`:

```text
error: Assert status code
 63 | HTTP 409
    |      ^^^ actual value is <500>
Failure hurl/v1/04-orders.hurl (7 request(s) in 155 ms)
```

```text
ERROR unexpected error method=POST path=/api/v1/orders err="ERROR: insert or update on table
\"inventory_reservations\" violates foreign key constraint \"inventory_reservations_order_id_fkey\" (SQLSTATE 23503)"
```

Lo que pasó, en orden: el pedido se insertó dentro de la transacción; el descuento de `SKU-001`
también; el `INSERT` de la reserva salió por otra conexión del pool, en la que el pedido **no
existe** porque la transacción no ha confirmado; la FK lo rechazó; el caso de uso devolvió el
error; la transacción revirtió pedido y descuento. Resultado: `500` en lugar del `409` esperado,
y ninguna fila huérfana… **gracias a la FK**. Sin esa FK, la reserva se habría guardado fuera de
la transacción y habría sobrevivido al `409` como una fila `RESERVED` sin pedido.

Dos lecciones: `Q(ctx)` existe para que este error sea imposible por descuido (hay que escribir
`Pool` a propósito para provocarlo); y una restricción de la base es una red que atrapa lo que el
código no vio, aunque lo convierta en `500`. Revertido después de la captura.

## 9. 🧰 Cinco plataformas

| Plataforma | Qué da hecho | Qué te deja a ti | Trampa frecuente |
|---|---|---|---|
| Java · Spring Boot | contenedor, `TransactionTemplate`, JPA, resource server | casos de uso sin anotaciones, `UnitOfWork`, dos modelos, ArchUnit | `@Transactional` y *self-invocation* |
| Node/TS · NestJS | contenedor por token, pipes, guards, `$transaction` | tokens para interfaces, `AsyncLocalStorage` solo para la tx, `useFactory` | inyectar una `interface`; pasar `tx` a los puertos |
| **Go · `net/http`** | `ServeMux` con métodos, `context`, `pgx.Tx`, `errors.As`, `go test`, `go vet` | interfaces junto al consumidor, la tx en el `ctx` con `Q(ctx)`, validación a mano, `main` como composition root y dueño del cierre, `go/parser` como regla | `db` en vez de `tx` (aquí `Pool` en vez de `Q(ctx)`); paquete `interfaces`; goroutine sin contexto; `defer Rollback` que oculta el error de `Commit` |
| Python · FastAPI | `Depends`, Pydantic, SQLAlchemy | `Protocol` como puerto, sesión controlada | `HTTPException` desde el dominio |
| PHP · Laravel | service container, Eloquent, form requests | que el modelo Eloquent no sea el dominio | *active record* como agregado y DTO |

## 10. 🧹 Teardown

`Ctrl+C` en la terminal de `lab.py go`: `signal.NotifyContext` cancela el contexto, el dispatcher
sale de su `select`, `server.Shutdown` espera las peticiones en curso (5 s máximo) y los `defer`
de `main` cierran Mongo, Redis y el pool, en orden inverso a como se abrieron. El entorno se apaga
con `lab.py down`.

## ⚠️ Errores frecuentes

- "Cada struct necesita su interfaz." Solo la necesita un consumidor con una capacidad
  sustituible; aquí las interfaces están donde se consumen y ningún adaptador declara nada.
- "Pasar `ctx` a todo es ruido." Es el mecanismo por el que la transacción, la cancelación y el
  deadline llegan a donde deben sin variables globales. El dominio no lo recibe: no hace I/O.
- "`defer tx.Rollback()` resuelve todos los finales." Solo si el error de `Commit` se devuelve
  antes; si no, un commit fallido parece un éxito.
- "Devolver cualquier `error` ya desacopla." `sql.ErrNoRows` o un error de `pgx` en el handler
  siguen siendo infraestructura; los adaptadores devuelven `nil, nil` para "no existe" y el caso
  de uso decide `NotFound`.
- "Un paquete `internal` garantiza hexagonal." Impide importar desde fuera del módulo, no que
  `domain` importe `pgx`; para eso está `arch_test.go`.

## ✅ Veredicto

Biblioteca estándar en el borde, Go ordinario en el centro, y la frontera verificada por un test
de treinta líneas y una suite que pasa dos veces. Lo que en otros sabores era un contenedor o un
contexto asíncrono, aquí es un `struct` en `main` y un `ctx` en cada firma: más líneas, ninguna
magia. Que no hubiera un solo error real es la prueba de que el contrato y el esquema hacen el
trabajo pesado; el error provocado es la prueba de que `Q(ctx)` y la FK hacen el resto.

## 📚 Referencias

- [Go 1.22: routing enhancements (`ServeMux` con métodos y patrones)](https://go.dev/blog/routing-enhancements) · [`net/http`](https://pkg.go.dev/net/http)
- [`context`](https://pkg.go.dev/context) · [Contexts and structs](https://go.dev/blog/context-and-structs) · [`os/signal`](https://pkg.go.dev/os/signal)
- [`errors`: `Is` y `As`](https://pkg.go.dev/errors) · [Effective Go](https://go.dev/doc/effective_go)
- [pgx v5](https://pkg.go.dev/github.com/jackc/pgx/v5) · [`pgxpool`](https://pkg.go.dev/github.com/jackc/pgx/v5/pgxpool)
- [MongoDB Go Driver v2](https://pkg.go.dev/go.mongodb.org/mongo-driver/v2/mongo) · [go-redis v9](https://pkg.go.dev/github.com/redis/go-redis/v9)
- [golang-jwt v5](https://pkg.go.dev/github.com/golang-jwt/jwt/v5) · [`x/crypto/bcrypt`](https://pkg.go.dev/golang.org/x/crypto/bcrypt)
- [`go/parser`](https://pkg.go.dev/go/parser)

## 🧠 Preguntas

1. 🟢 ¿Dónde están declaradas las interfaces de los puertos y por qué ahí?
2. 🟢 ¿Cómo comprueba el compilador que `postgres.Orders` satisface `application.Orders` si nadie lo declara?
3. 🟢 ¿Qué devuelve `DB.Q(ctx)` dentro y fuera de `DB.Run`?
4. 🟢 ¿Por qué los identificadores del dominio son `string` y no un tipo UUID?
5. 🟢 ¿Qué hace `arch_test.go` y qué no puede detectar?
6. 🟡 ¿Por qué `Run` reutiliza la transacción si ya hay una en el contexto?
7. 🟡 ¿Por qué el `defer tx.Rollback(ctx)` de `Run` no oculta un error de `Commit`?
8. 🟡 ¿Qué gana y qué pierde la validación a mano de `dto.go` frente a `class-validator` o Bean Validation?
9. 🟡 ¿Por qué `security.JWT` implementa dos interfaces de dos paquetes distintos sin declararlo, y qué dice eso del diseño?
10. 🟡 ¿Cómo evita el `Dispatcher` "lanzar una goroutine y perder el error"?
11. 🟠 El error provocado dio `500` y no una fila huérfana. ¿Qué lo impidió, y qué habría pasado sin la FK?
12. 🟠 ¿Por qué el `ctx` de la petición y el `ctx` de la transacción son el mismo objeto en la mayoría de las llamadas, y cuándo no lo son?
13. 🟠 En modo `postgres` el binario no abre Mongo; en NestJS y Java sí se conectaba siempre. ¿Cuál es mejor y por qué?
14. 🟠 Un compañero quiere un paquete `internal/interfaces` "para no duplicar". ¿Qué le respondes con este código delante?

## 🧪 Ejercicios

1. 🟢 Haz que `domain/order.go` importe `github.com/google/uuid` (solo el import) y corre `lab.py go
   --test`. Pega el fallo de `TestDependencyRule`.
2. 🟢 Cambia `Q(ctx)` por `i.DB.Pool` en el `UPDATE` de `Reserve` (no en el `INSERT`) y corre
   `04-orders.hurl`. Explica por qué esta vez **sí** queda un descuento huérfano y la suite lo
   detecta por el stock.
3. 🟡 Escribe una prueba con `httptest` para `POST /api/v1/orders` usando un `Deps` con dobles del
   caso de uso: sin cabecera → `400 IDEMPOTENCY_KEY_REQUIRED`; con cuerpo `{ "lines": [] }` → `400
   VALIDATION_FAILED`. Explica qué anillo cubre y qué no.
4. 🟡 Quita `jwt.WithValidMethods([]string{"HS256"})` del verificador y explica qué ataque
   permite un token firmado con `alg: none` o con otro algoritmo. Vuelve a ponerlo.
5. 🟠 Escribe una prueba de contrato del puerto `Orders` con `testing` y una etiqueta de build
   (`//go:build integration`) que corra contra `postgres.Orders` con el entorno arriba y contra el
   fake sin nada. Decide cómo `lab.py go --test` la activa.
6. 🟠 Sustituye el `select` del `Dispatcher` por un `time.AfterFunc` recursivo. Compara el manejo
   de cancelación y de solapamiento de rondas, y argumenta cuál es más fácil de razonar.
7. 🔴 Implementa un `middleware` de deadline (`context.WithTimeout` de 2 s por petición) y
   comprueba con el proveedor determinista modificado (un `time.Sleep` de 3 s en `Authorize`) qué
   error ve el cliente, qué queda en la base y por qué `AuthorizePayment` con dos transacciones
   deja el sistema consistente aunque la petición se cancele entre ambas.
8. 🔥 Elimina `internal/` (mueve los paquetes un nivel arriba) y comprueba que todo compila igual.
   Explica qué protegía `internal/` y qué no, y por qué `arch_test.go` sigue siendo necesario.

---

**Siguiente:** [06 — Python y FastAPI](06-caso-python-fastapi.md), o cualquier otro sabor.
