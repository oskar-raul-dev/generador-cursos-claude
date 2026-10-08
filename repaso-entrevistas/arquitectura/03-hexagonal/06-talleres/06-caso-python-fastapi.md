# 06 — Python y FastAPI

Este taller es **opcional** y depende solo de `06/01`. Sigue la estructura del taller 03 y cambia
lo que Python cambia: contratos estructurales (`Protocol`) que nadie comprueba en runtime, un
framework cuya inyección (`Depends`) es cómoda y tentadora, un ORM que quiere ser el dominio, y
una ejecución asíncrona que no vuelve asíncrono a un driver que no lo es. Termina cuando la suite
de `06/01` pasa con el catálogo en PostgreSQL y con el catálogo en MongoDB.

> **Vigencia:** 2026-09-27. Versiones verificadas ese día en PyPI; Python 3.14.7.

**Salto rápido:** [1](#1--qué-enseña-este-sabor) · [2](#2--prerrequisitos-y-versiones) · [3](#3-️-mapa-de-carpetas) · [4](#4--parte-1-el-núcleo-y-sus-bordes) · [5](#5--parte-2-cancelación-outbox-y-notifier) · [6](#6--parte-3-el-catálogo-a-mongodb) · [7](#7--pruebas-por-anillos) · [8](#8--errores-provocados-a-propósito) · [9](#9--cinco-plataformas) · [10](#10--teardown) · [Preguntas](#-preguntas) · [Ejercicios](#-ejercicios)

## 1. 🎯 Qué enseña este sabor

FastAPI empuja hacia un diseño concreto: un modelo Pydantic que es a la vez DTO, entidad y fila;
una `Session` global de SQLAlchemy; `Depends` en todas partes, incluida la lógica de negocio; y
`HTTPException` lanzada desde la regla de crédito. Este taller construye el mismo sistema que el
03 con FastAPI en el borde y Python ordinario en el centro:

```text
HTTP ─► FastAPI (def, threadpool) ─► CreateOrder (dataclass) ─► Products / Inventory / Orders (Protocol)
                                            │                          ▲ satisfechos por tener los métodos
                                     UnitOfWork.run(work)      PgProducts · MongoProducts · PgInventory · PgOrders
                                            │
                              Db.run: engine.begin() + ContextVar        Db.rows / Db.exec ← la conexión de la tx, o una propia
```

- **Los puertos son `typing.Protocol`.** Contratos estructurales: `PgOrders` satisface `Orders` por
  tener `find`, `save` y `list`, sin heredar de nada. Un type checker lo comprueba; el intérprete
  no. Lo que no encaja se descubre en la prueba, no al arrancar.
- **Los casos de uso son `dataclass(frozen=True)`** con los puertos como campos. Sin `Depends`, sin
  FastAPI, sin Pydantic: `main.py` los construye con `CreateOrder(products, inventory, …)`.
- **La transacción es un `ContextVar`.** `Db.run` abre `engine.begin()` y deja la conexión en el
  contexto; `Db.rows`/`Db.exec` la usan si existe. Es el equivalente Python del
  `AsyncLocalStorage` de NestJS, y como allí, solo para la transacción.
- **Los endpoints son `def`, no `async def`.** El driver (`psycopg` en modo síncrono) bloquea;
  FastAPI ejecuta los `def` en un threadpool. Un `async def` con ese driver bloquearía el bucle de
  eventos con cada consulta (capítulo [05/05](../05-plataformas-y-practica/05-python.md)).
- **Pydantic en modo estricto, solo en el borde.** `"35"` no se convierte en `35`; los DTO
  descartan campos desconocidos; el núcleo recibe `Money`, no `MoneyDto`.

El precio: 29 archivos donde el "tutorial de FastAPI" tendría cinco, y `Protocol` que no protege de
nada en runtime. La ganancia: la parte 3 es un archivo de 51 líneas, y ninguna prueba del núcleo
importa FastAPI.

## 2. 🧰 Prerrequisitos y versiones

| Herramienta | Versión fijada | Para qué |
|---|---|---|
| Python | `3.14.7` (`requires-python >= 3.14`) | la baseline del corpus |
| `uv` | `0.11.14` | entorno, dependencias, ejecución |
| `fastapi` / `uvicorn` | `0.141.1` / `0.54.0` | HTTP |
| `pydantic` | `2.13.5` | DTO estrictos del borde |
| `sqlalchemy` / `psycopg[binary]` | `2.1.1` / `3.3.6` | PostgreSQL, Core sin ORM |
| `pymongo` | `4.18.2` | catálogo en la parte 3 |
| `redis` | `8.1.0` | revocación de tokens |
| `pyjwt` / `bcrypt` | `2.15.0` / `5.0.0` | JWT HS256, contraseñas de la semilla |
| `pytest` / `import-linter` | `9.1.1` / `2.15` | pruebas y regla de dependencias |

Todo va con `==` en `pyproject.toml`; `uv sync --python 3.14` crea `.venv` con esa versión (la
descarga si no está) e instala el `uv.lock`.

```text
python3 06-talleres/laboratorio/scripts/lab.py python
python3 06-talleres/laboratorio/scripts/lab.py python --catalog mongo
python3 06-talleres/laboratorio/scripts/lab.py python --test
```

- `python` corre `uv sync --python 3.14` y `uv run python -m hexorders.main` con `HEX_CATALOG` en
  el entorno. El backend queda en `http://localhost:8084` hasta `Ctrl+C`.
- `--catalog mongo` es la parte 3: mismo código, otra variable.
- `--test` corre `pytest` (dominio y caso de uso) y `lint-imports` (dependencias). No necesita
  Docker.

`lab.py` es el Python de la máquina (3.11+); el proyecto corre en el 3.14 de su propio `.venv`.
Son dos intérpretes distintos a propósito: el orquestador no impone versión, el taller sí.

## 3. 🗂️ Mapa de carpetas

```text
laboratorio/python/
├── pyproject.toml                          dependencias fijas, pytest, contratos de import-linter
├── uv.lock
├── src/hexorders/
│   ├── main.py                             composition root + uvicorn; lifespan como dueño del cierre
│   ├── domain/                             money, product, order (+ OrderLine, Payment), events, errors
│   ├── application/
│   │   ├── actor.py · page.py · errors.py
│   │   ├── ports.py                        TODOS los Protocol de salida
│   │   └── usecases/                       auth, products, orders, payments, cancel, notifications
│   └── infrastructure/
│       ├── config.py
│       ├── inbound/http/                   app.py (create_app + rutas), auth.py (Authenticator como dependencia),
│       │                                   schemas.py (Pydantic estricto), problems.py (handlers → problem+json)
│       └── outbound/
│           ├── postgres/                   db.py (engine + ContextVar + run), adapters.py (un adaptador por puerto), cursors.py
│           ├── mongo/products.py           (parte 3)
│           ├── redis/ · security/ · payment/
│           └── notification/dispatcher.py  (parte 2)
└── tests/                                  test_order.py, test_create_order.py
```

`import-linter` prohíbe que `domain` y `application` importen `fastapi`, `pydantic`, `sqlalchemy`,
`psycopg`, `pymongo`, `redis`, `jwt`, `bcrypt` o `infrastructure`, y que `inbound` importe `outbound`.

## 4. 🧱 Parte 1: el núcleo y sus bordes

### El dominio son clases ordinarias

`Money`, `Product`, `OrderLine` y `Payment` son `dataclass(frozen=True, slots=True)`; `Order` es
una clase con `__slots__`, dos fábricas de clase y la máquina de estados:

```python
def apply_payment(self, result: Payment) -> None:
    """PENDING no es un rechazo: el pedido queda a la espera y no vuelve a ser pagable."""
    if not self.is_payable():
        raise OrderNotPayable(self._status)
    self._payment = result
    self._status = {"AUTHORIZED": "PAID", "REJECTED": "PAYMENT_REJECTED", "PENDING": "PAYMENT_PENDING"}[result.status]
```

Nada de Pydantic aquí: un modelo Pydantic valida y coerciona **datos de fuera**; un agregado
protege invariantes **de dentro**. Compartir la clase mezcla ambas cosas, que es exactamente la
trampa de 05/05.

### Los puertos son `Protocol`

```python
class Inventory(Protocol):
    def available_for(self, skus: list[str]) -> dict[str, int]: ...
    def initialize(self, sku: str, quantity: int) -> None: ...
    def reserve(self, order_id: str, lines: list[OrderLine]) -> None: ...
    def release(self, order_id: str) -> None: ...
```

`PgInventory` no hereda de `Inventory`; lo satisface. Un type checker (mypy, pyright) lo verifica;
en runtime no hay ninguna comprobación, y por eso los fakes de `test_create_order.py` tampoco
heredan de nada: prueban que el caso de uso funciona con *cualquier* cosa que tenga esos métodos.
Es duck typing con contrato escrito.

### Los casos de uso son `dataclass` y la transacción un `ContextVar`

```python
@dataclass(frozen=True, slots=True)
class CreateOrder:
    products: Products
    inventory: Inventory
    orders: Orders
    idempotency: IdempotencyStore
    ids: IdGenerator
    clock: Clock
    unit_of_work: UnitOfWork

    def execute(self, command: CreateOrderCommand) -> CreateOrderResult:
        def work() -> CreateOrderResult:
            # … idempotencia, catálogo, Order.place, orders.save, inventory.reserve, idempotency.save
        return self.unit_of_work.run(work)
```

`Db.run(work)` abre `with self.engine.begin() as conn`, hace `_current.set(conn)` y llama a
`work()`; `Db.rows` y `Db.exec` consultan `_current.get()` y usan esa conexión si existe, o abren
una propia y corta si no. El `ContextVar` sobrevive al threadpool de FastAPI porque el caso de uso
entero corre en el mismo hilo. `AuthorizePayment` tiene, como en los otros sabores, dos `run` con
el proveedor en medio.

### El borde: `Depends` solo aquí, Pydantic estricto, handlers de error

- `Authenticator` es una clase con `__call__(self, request)`: una dependencia de FastAPI con
  estado (el verificador y la revocación). `Auth = Annotated[AuthContext, Depends(authenticate)]`
  y `Who = Annotated[Actor, Depends(actor_of)]` son los alias que las rutas usan. `Depends` no
  aparece en `application/`.
- `schemas.py`: `class Strict(BaseModel): model_config = ConfigDict(strict=True, extra="ignore")`.
  `CreateOrderRequest.lines` tiene `min_length=1`; `MoneyDto.amount` un patrón de dos decimales;
  `stock: int = Field(ge=0)` rechaza `"10"` como texto. `unit_price` se declara con
  `alias="unitPrice"` porque el contrato es camelCase y el código es snake_case.
- `problems.py` registra un `exception_handler` por error propio y traduce
  `RequestValidationError` a `400 VALIDATION_FAILED` con `field`/`message` (FastAPI daría `422`
  por defecto). Un `order_id: UUID` en la ruta que no es UUID cae en ese mismo handler.
- `create_app(deps)` recibe los casos de uso ya construidos; no importa ningún adaptador de
  salida. Es el `buildApp(deps)` que el capítulo 05/03 pedía para Node, en Python.

### Las salidas: SQLAlchemy Core, sin ORM

`adapters.py` tiene un adaptador por puerto con SQL a mano y `text()`: `PgInventory.reserve`
descuenta con `UPDATE … WHERE available >= :q` y mira `rowcount`; los importes van como texto
(`::text`, `CAST(:p AS numeric)`) y se convierten con `Decimal(...).quantize(Decimal("0.01"))`;
los `jsonb` con `json.dumps` al escribir y `_json()` al leer, que acepta el `dict` que `psycopg`
ya devuelve. No hay `Session`, ni modelos declarativos, ni `relationship`: el capítulo 05/05
reserva el ORM para cuando hay un modelo de persistencia con vida propia; aquí no lo hay.

`JwtTokens` implementa el puerto `TokenIssuer` y la interfaz `TokenVerifier` del borde con PyJWT
(`algorithms=["HS256"]`, `require: ["sub", "jti", "exp"]`); `BcryptHasher.matches` verifica los
`$2y$` de la semilla.

## 5. 🔁 Parte 2: cancelación, outbox y Notifier

`CancelOrder`, `DeliverPendingPublications` y `ListNotifications` son traducciones literales de
las de los otros sabores. El disparador es un hilo:

```python
class OutboxDispatcher:
    def __init__(self, deliver, poll_ms):
        self._stop = threading.Event()
        self._thread = threading.Thread(target=self._loop, name="outbox-dispatcher", daemon=True)

    def _loop(self):
        while not self._stop.wait(self._interval):
            try:
                delivered = self._deliver.execute(50)
            except Exception:
                log.exception("outbox: delivery round failed")  # la siguiente ronda reintenta
```

`main.py` lo arranca en el `lifespan` de la app y lo para en el mismo `lifespan` al cerrar, antes
de cerrar Mongo, Redis y el engine. `Event.wait(interval)` es a la vez la espera y la señal de
parada: sin `sleep`, sin bucle que compruebe un flag. Un hilo secuencial no solapa rondas por
construcción. `TableNotifier` deduplica con `ON CONFLICT (id) DO NOTHING`.

**Evidencia.** Inventario de la parte (el código se generó de una vez):

```text
-- parte 2: 4 archivos nuevos, 131 líneas, más tres clases en outbound/postgres/adapters.py
application/usecases/cancel.py · notifications.py · domain/events.py
infrastructure/outbound/notification/dispatcher.py
adapters.py: PgPendingPublications, PgNotifications, TableNotifier
```

Más `cancel`/`pull_events` en `Order`, dos rutas en `app.py` y el `lifespan` en `main.py`.

Salida literal de la suite completa, catálogo en PostgreSQL, 2026-09-27 (tras el error de §8):

```text
$ hurl --test --jobs 1 --variable base_url=http://localhost:8084 hurl/v1/01-health.hurl hurl/v1/02-auth.hurl hurl/v1/03-products.hurl hurl/v1/04-orders.hurl hurl/v1/05-payment.hurl hurl/v1.1/06-cancel.hurl hurl/v1.1/07-notifications.hurl
Success hurl/v1/01-health.hurl (1 request(s) in 1 ms)
Success hurl/v1/02-auth.hurl (9 request(s) in 141 ms)
Success hurl/v1/03-products.hurl (12 request(s) in 167 ms)
Success hurl/v1/04-orders.hurl (20 request(s) in 199 ms)
Success hurl/v1/05-payment.hurl (14 request(s) in 130 ms)
Success hurl/v1.1/06-cancel.hurl (19 request(s) in 199 ms)
Success hurl/v1.1/07-notifications.hurl (10 request(s) in 2188 ms)
--------------------------------------------------------------------------------
Executed files:    7
Executed requests: 85 (28.0/s)
Succeeded files:   7 (100.0%)
Failed files:      0 (0.0%)
Duration:          3032 ms (0h:0m:3s:32ms)
```

## 6. 🔀 Parte 3: el catálogo a MongoDB

Un archivo: `outbound/mongo/products.py`, con `pymongo` y la misma paginación por cursor. En
`main.py`, `products: Products = PgProducts(db)` y, si `cfg.catalog == "mongo"`, `products =
MongoProducts(cfg.mongo_url)`: la variable está anotada con el `Protocol`, y ambas clases lo
satisfacen sin declararlo. Mongo solo se abre si se va a usar.

```text
python3 06-talleres/laboratorio/scripts/lab.py seed --mongo
python3 06-talleres/laboratorio/scripts/lab.py python --catalog mongo
python3 06-talleres/laboratorio/scripts/lab.py suite --base-url http://localhost:8084
```

```text
INFO hexorders hex-orders-python listening on :8084 (catalog=mongo)
Success hurl/v1/01-health.hurl (1 request(s) in 1 ms)
Success hurl/v1/02-auth.hurl (9 request(s) in 147 ms)
Success hurl/v1/03-products.hurl (12 request(s) in 157 ms)
Success hurl/v1/04-orders.hurl (20 request(s) in 214 ms)
Success hurl/v1/05-payment.hurl (14 request(s) in 158 ms)
Success hurl/v1.1/06-cancel.hurl (19 request(s) in 200 ms)
Success hurl/v1.1/07-notifications.hurl (10 request(s) in 2187 ms)
--------------------------------------------------------------------------------
Executed files:    7
Executed requests: 85 (27.7/s)
Succeeded files:   7 (100.0%)
Failed files:      0 (0.0%)
Duration:          3070 ms (0h:0m:3s:70ms)
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

Inventario de la parte: `51` líneas en un archivo y cuatro en `main.py`; en `domain/`,
`application/` e `inbound/`, cero.

## 7. 🧪 Pruebas por anillos

- `tests/test_order.py`: la máquina de estados con `pytest.raises`; `Money` sin coma flotante.
- `tests/test_create_order.py`: fakes que **no heredan de nada** (satisfacen los `Protocol` por
  tener los métodos) y un `SnapshotUnitOfWork` que copia los `dict` y los restaura si `work`
  lanza.
- `lint-imports`: los tres contratos de `pyproject.toml`.

```text
$ uv run pytest -q
.........                                                                [100%]
9 passed in 0.05s
$ uv run lint-imports
Analyzed 68 files, 182 dependencies.
domain depends on nothing outside KEPT
application does not know infrastructure KEPT
inbound does not touch outbound KEPT
Contracts: 3 kept, 0 broken.
```

Lo que no hay, y se declara: pruebas del adaptador `postgres` contra una base real (la suite las
cubre), `TestClient` sobre `create_app` con dobles (ejercicio 3) y un type checker en el `--test`
(ejercicio 1: es la única forma de que un `Protocol` roto se vea antes de la prueba).

## 8. 🩺 Errores provocados a propósito

Un fallo real de la construcción, y de los buenos: la suite entera en `400` con el backend
"funcionando".

### `from __future__ import annotations` y las dependencias locales de FastAPI

Primera corrida, seis archivos de siete en rojo con el mismo síntoma:

```text
error: Assert status code
44 | HTTP 401
   |      ^^^ actual value is <400>
```

```text
$ curl -s http://localhost:8084/api/v1/products
{"type":"about:blank","title":"Validation failed","status":400,"instance":"/api/v1/products",
 "code":"VALIDATION_FAILED","errors":[{"field":"_","message":"Field required"}]}
```

Un `400` por un campo llamado `_`, con o sin token. `_` era el nombre del parámetro
`_: Who` en `list_products`, y `Who` es `Annotated[Actor, Depends(actor_of)]`, **una variable local
de `create_app`**. Con `from __future__ import annotations` (PEP 563) las anotaciones son strings
que se evalúan más tarde con los `globals` del módulo; `Who` no está ahí, FastAPI no puede
resolverlo, y trata `_` como un parámetro de query obligatorio. Corrección: quitar el import
diferido de `app.py` (y solo de ese archivo: en los demás no molesta). Lección: un mecanismo del
lenguaje pensado para tipos (anotaciones perezosas) interactúa con un framework que **lee las
anotaciones en runtime** para decidir qué inyectar. Es la versión Python del `emitDecoratorMetadata`
de NestJS: el framework depende de metadatos que el toolchain puede quitar.

Después de esa corrección, la suite pasó entera, con los dos catálogos, sin más cambios.

## 9. 🧰 Cinco plataformas

| Plataforma | Qué da hecho | Qué te deja a ti | Trampa frecuente |
|---|---|---|---|
| Java · Spring Boot | contenedor, `TransactionTemplate`, JPA, resource server | casos de uso sin anotaciones, `UnitOfWork`, dos modelos, ArchUnit | `@Transactional` y *self-invocation* |
| Node/TS · NestJS | contenedor por token, pipes, guards, `$transaction` | tokens para interfaces, `AsyncLocalStorage` solo para la tx | inyectar una `interface` |
| Go · `net/http` | `ServeMux`, `context`, `pgx.Tx`, `errors.As` | la tx en el `ctx` con `Q(ctx)`, `main` como composition root | `db` en vez de `tx` |
| **Python · FastAPI** | `Depends`, Pydantic, SQLAlchemy Core, `lifespan`, threadpool para `def` | `Protocol` como puerto (y un type checker que lo verifique), `dataclass` para casos de uso, `ContextVar` solo para la tx, Pydantic estricto solo en el borde, `def` con driver síncrono, `import-linter` | Pydantic como dominio; `Session` global; `HTTPException` desde el dominio; `async def` con driver bloqueante; `from __future__ import annotations` donde FastAPI lee anotaciones |
| PHP · Laravel | service container, Eloquent, form requests | que el modelo Eloquent no sea el dominio | *active record* como agregado y DTO |

## 10. 🧹 Teardown

`Ctrl+C` en la terminal de `lab.py python`: uvicorn cierra, el `lifespan` para el hilo de la
outbox (`Event.set()` + `join`), cierra Mongo, Redis y hace `engine.dispose()`. El entorno se apaga
con `lab.py down`. `.venv/` está en `.gitignore`; `uv sync` lo recrea.

## ⚠️ Errores frecuentes

- "Pydantic ya es un modelo de dominio." Valida y coerciona datos de fuera; no protege invariantes
  ni transiciones. `Order` no es un `BaseModel` y no lo necesita.
- "`Protocol` garantiza el contrato." Solo para el type checker. Sin mypy/pyright en el `--test`, un
  adaptador al que le falta un método falla en la primera petición que lo use.
- "`async def` va más rápido." Con `psycopg` síncrono bloquea el bucle de eventos en cada consulta.
  O driver async con `AsyncSession`, o `def` en el threadpool; mezclar es lo peor de ambos.
- "`Depends` en el caso de uso es más limpio." Es acoplar la política a FastAPI; `import-linter`
  lo rechaza.
- "Las anotaciones diferidas son inofensivas." Para tipos, sí; para un framework que las lee en
  runtime, no.

## ✅ Veredicto

FastAPI en el borde, Python ordinario en el centro, y la frontera verificada por `import-linter` y
una suite que pasa dos veces. Lo específico de Python —`Protocol` sin garantía en runtime,
`ContextVar` para la transacción, `def` contra un driver síncrono, Pydantic estricto solo donde
entran datos— cabe en cuatro archivos de infraestructura. El único error real fue una
interacción entre el lenguaje y el framework, y es la lección que vale el taller.

## 📚 Referencias

- [FastAPI: dependencias](https://fastapi.tiangolo.com/tutorial/dependencies/) · [manejo de errores](https://fastapi.tiangolo.com/tutorial/handling-errors/) · [lifespan](https://fastapi.tiangolo.com/advanced/events/) · [concurrencia y `async`](https://fastapi.tiangolo.com/async/)
- [Pydantic: modo estricto](https://pydantic.dev/docs/validation/latest/concepts/strict_mode/)
- [SQLAlchemy 2.1: conexiones y transacciones (Core)](https://docs.sqlalchemy.org/en/21/core/connections.html)
- [Python: `contextvars`](https://docs.python.org/3/library/contextvars.html) · [`typing.Protocol`](https://docs.python.org/3/library/typing.html#typing.Protocol) · [`threading.Event`](https://docs.python.org/3/library/threading.html#event-objects) · [PEP 563: anotaciones diferidas](https://peps.python.org/pep-0563/)
- [PyJWT: uso](https://pyjwt.readthedocs.io/en/stable/usage.html) · [PyMongo](https://www.mongodb.com/docs/languages/python/pymongo-driver/current/)
- [import-linter: tipos de contrato](https://import-linter.readthedocs.io/en/stable/contract_types/)
- [uv: proyectos](https://docs.astral.sh/uv/concepts/projects/)

## 🧠 Preguntas

1. 🟢 ¿Qué comprueba un `Protocol` y cuándo?
2. 🟢 ¿Por qué los casos de uso son `dataclass(frozen=True)` y no clases con `Depends`?
3. 🟢 ¿Por qué los endpoints son `def` y no `async def`?
4. 🟢 ¿Qué hace `ConfigDict(strict=True, extra="ignore")` y por qué solo en el borde?
5. 🟢 ¿Dónde vive `Depends` en este proyecto y dónde está prohibido?
6. 🟡 ¿Cómo comparte `Db.run` la transacción con los adaptadores sin pasar una sesión?
7. 🟡 ¿Por qué el `ContextVar` funciona aunque FastAPI ejecute los `def` en un threadpool?
8. 🟡 ¿Por qué `problems.py` convierte `RequestValidationError` en `400` y no deja el `422` de FastAPI?
9. 🟡 ¿Qué hace `Event.wait(interval)` en el dispatcher que un `sleep` en bucle no hace?
10. 🟡 ¿Por qué no hay `Session` ni modelos declarativos de SQLAlchemy en este sabor?
11. 🟠 El error de §8: ¿por qué `from __future__ import annotations` rompió las dependencias y no las rutas sin dependencias?
12. 🟠 Sin type checker, ¿cómo se descubriría un `PgOrders` al que le falta `list`? Propón dónde poner el type checker y por qué ahí.
13. 🟠 Compara `ContextVar` (Python), `AsyncLocalStorage` (Node) y `ctx` explícito (Go) para la transacción: qué hace visible cada uno y qué esconde.
14. 🟠 Un compañero quiere `async def` en todas las rutas "porque FastAPI es async". Con `psycopg` síncrono, ¿qué pasaría bajo carga, y qué dos caminos correctos hay?

## 🧪 Ejercicios

1. 🟢 Añade `mypy` (o `pyright`) al grupo `dev`, corre `uv run mypy src` y arregla lo que
   encuentre. Después borra el método `list` de `PgOrders` y comprueba que el type checker lo ve
   y `pytest` no.
2. 🟢 Vuelve a poner `from __future__ import annotations` en `app.py`, arranca y corre
   `02-auth.hurl`. Pega el `400` con `"field": "_"` y quítalo otra vez.
3. 🟡 Escribe una prueba con `TestClient` sobre `create_app(deps)` con dobles: sin cabecera →
   `400 IDEMPOTENCY_KEY_REQUIRED`; `{ "lines": [] }` → `400 VALIDATION_FAILED` con `field`
   `lines`. Explica qué anillo cubre.
4. 🟡 Cambia `stock: int` por `stock: int = Field(ge=0)` sin `strict` (quita `strict=True` de
   `Strict`) y envía `"stock": "10"`. Explica qué pasó y por qué el contrato prefiere rechazarlo.
5. 🟠 En `PgInventory.reserve`, sustituye `self.db.exec` del `INSERT` de la reserva por un
   `with self.db.engine.begin() as c: c.execute(...)` (una conexión propia). Corre `04-orders.hurl`.
   Compara con el error provocado del taller 05 (Go).
6. 🟠 Convierte el dispatcher en una tarea `asyncio` dentro del `lifespan` (`asyncio.create_task`)
   que llame al caso de uso con `asyncio.to_thread`. Explica qué gana, qué pierde y por qué
   `to_thread` es obligatorio con este driver.
7. 🔴 Sustituye `Db.rows`/`Db.exec` por una `Session` de SQLAlchemy ORM con un modelo declarativo
   `OrderRow` distinto de `Order`, manteniendo `Db.run` como unidad de trabajo. Mide cuántos
   archivos cambian y argumenta si el ORM compensa en este sistema.
8. 🔥 Implementa el catálogo con `motor`/`pymongo` async y una ruta `async def` para
   `GET /products`, dejando el resto síncrono. Explica qué problema de consistencia de hilos
   aparece con el `ContextVar` de la transacción y cómo lo resolverías.

---

**Siguiente:** [07 — PHP y Laravel](07-caso-php-laravel.md), o cualquier otro sabor.
