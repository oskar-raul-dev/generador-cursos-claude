# 03 — Java y Spring Boot

Este taller es **opcional** y depende solo de `06/01`. Es el **patrón de los sabores**: los talleres
04 a 07 siguen su misma estructura y cambian únicamente dónde empuja cada framework. Implementa las
tres partes del caso de estudio con Spring Boot 4.1 y Java 25, y termina cuando la suite `hurl` de
`06/01` pasa dos veces: con el catálogo en PostgreSQL y con el catálogo en MongoDB.

> **Vigencia:** 2026-09-27. Versiones verificadas ese día en Maven Central y SDKMAN.

**Salto rápido:** [1](#1--qué-enseña-este-sabor) · [2](#2--prerrequisitos-y-versiones) · [3](#3-️-mapa-de-carpetas) · [4](#4--parte-1-el-núcleo-y-sus-bordes) · [5](#5--parte-2-cancelación-outbox-y-notifier) · [6](#6--parte-3-el-catálogo-a-mongodb) · [7](#7--pruebas-por-anillos) · [8](#8--errores-provocados-a-propósito) · [9](#9--cinco-plataformas) · [10](#10--teardown) · [Preguntas](#-preguntas) · [Ejercicios](#-ejercicios)

## 1. 🎯 Qué enseña este sabor

Spring Boot empuja hacia un diseño concreto sin que nadie lo decida: un `@Service` que recibe un
`JpaRepository`, una `@Entity` que hace de modelo de dominio, un `@Transactional` sobre el método
que "hace todo" y un `@RestController` que devuelve la entidad porque Jackson ya sabe serializarla.
Funciona, y en tres meses cada regla de negocio depende de un proxy, una sesión y un mapeo.

Este taller construye el mismo sistema con Spring en el borde y Java ordinario en el centro:

```text
HTTP ─► @RestController ─► CreateOrder (clase Java) ─► Products / Inventory / Orders (puertos)
                                  │                            ▲
                          UnitOfWork (puerto)          JpaProducts · MongoProducts · JpaInventory · JpaOrders
                                  │
                       TransactionTemplate (adaptador)
```

Tres decisiones que lo distinguen del diseño que Spring sugiere:

- **Los casos de uso son clases sin anotaciones**, construidas en una `@Configuration`. Spring no
  los escanea; el composition root los ensambla con sus puertos.
- **El límite transaccional es un puerto (`UnitOfWork`)**, no `@Transactional`. El adaptador es un
  `TransactionTemplate`. No hay proxy, y por tanto no hay *self-invocation* que se lo salte.
- **`Order` y `OrderEntity` son dos clases.** El adaptador JPA traduce; el dominio no conoce
  `jakarta.persistence`. Una regla de ArchUnit lo hace fallar en el build si alguien lo cambia.

El precio: 103 archivos Java donde el diseño "de starter" tendría treinta, un mapper por
agregado y una configuración explícita de beans. La ganancia se mide en la parte 3: mover el
catálogo a MongoDB toca tres archivos nuevos y una línea.

## 2. 🧰 Prerrequisitos y versiones

| Herramienta | Versión fijada | Cómo |
|---|---|---|
| JDK | Temurin `25.0.4` | `sdk install java 25.0.4-tem` (SDKMAN) o el instalador de Adoptium |
| Maven | `3.9.10` | el de la máquina de referencia; cualquier 3.9.x sirve |
| Spring Boot | `4.1.1` | `spring-boot-starter-parent` en el `pom.xml` |
| ArchUnit | `1.5.1` | `archunit-junit5` |
| PostgreSQL, MongoDB, Redis | los de `06/01` | `lab.py up` |

Los *starters* de Boot 4 cambiaron de nombre respecto a 3.x: el de MVC es
`spring-boot-starter-webmvc` (el viejo `-web` sigue existiendo como alias). Se usan los nombres
nuevos.

```text
sdk use java 25.0.4-tem
python3 06-talleres/laboratorio/scripts/lab.py java
python3 06-talleres/laboratorio/scripts/lab.py java --catalog mongo
python3 06-talleres/laboratorio/scripts/lab.py java --test
```

- `sdk use` activa el JDK 25 **en esta terminal**; no cambia el JDK por defecto de la máquina. Si
  no se usa SDKMAN, basta con que `JAVA_HOME` apunte a un JDK 25.
- `java` corre `mvn -q spring-boot:run -Dspring-boot.run.arguments=--hex.catalog=postgres` en
  `laboratorio/java/`: `-q` silencia el registro de Maven; el argumento fija el catálogo desde
  fuera del código. El backend queda en `http://localhost:8081` hasta `Ctrl+C`.
- `--catalog mongo` es la parte 3: mismo jar, otra selección de adaptador.
- `--test` corre `mvn -q test`: ArchUnit, dominio y caso de uso. No necesita el entorno.

## 3. 🗂️ Mapa de carpetas

```text
laboratorio/java/
├── pom.xml
├── src/main/resources/application.yaml        puertos, credenciales y hex.catalog
├── src/main/java/hex/orders/
│   ├── HexOrdersApplication.java              @SpringBootApplication + @EnableScheduling
│   ├── domain/                                Money, Product, OrderLine, Order, Payment, DomainEvent, errores
│   ├── application/
│   │   ├── Actor · Page · PageRequest
│   │   ├── error/                             NotFound, AccessDenied, InvalidCredentials, IdempotencyKeyReused…
│   │   ├── port/out/                          Products, Inventory, Orders, Payments, PaymentGateway, IdempotencyStore,
│   │   │                                      PendingPublications, Notifier, Notifications, Users, PasswordHasher,
│   │   │                                      TokenIssuer, TokenRevocationStore, UnitOfWork, IdGenerator
│   │   └── usecase/                           Login, Logout, ListProducts, GetProduct, CreateProduct, CreateOrder,
│   │                                          GetOrder, ListOrders, AuthorizePayment, CancelOrder, ListNotifications,
│   │                                          DeliverPendingPublications
│   └── infrastructure/
│       ├── inbound/http/                      controllers, ApiDtos, ActorResolver, ProblemHandler, IdempotencyKeys
│       │   └── security/                      RevocationValidator, entry point y handler en problem+json
│       ├── outbound/postgres/                 entidades JPA, repositorios Spring Data, adaptadores Jpa*, TableNotifier
│       ├── outbound/mongo/                    ProductDocument, MongoProducts            (parte 3)
│       ├── outbound/redis/                    RedisTokenRevocationStore
│       ├── outbound/security/                 JwtTokenIssuer, BcryptPasswordHasher
│       ├── outbound/payment/                  DeterministicPaymentGateway
│       ├── outbound/notification/             OutboxDispatcher (@Scheduled)             (parte 2)
│       └── config/                            HexProperties, OrdersConfiguration, SecurityConfiguration
└── src/test/java/hex/orders/                  ArchitectureTest, OrderTest, CreateOrderTest
```

La regla de dependencias, en un `grep`: nada en `domain/` ni en `application/` importa
`org.springframework`, `jakarta.persistence` ni `hex.orders.infrastructure`. `ArchitectureTest` es
ese `grep` convertido en prueba.

## 4. 🧱 Parte 1: el núcleo y sus bordes

### El dominio decide; no persiste ni serializa

`Order` es una clase final con constructor privado, dos fábricas (`place` para crear,
`reconstitute` para volver de la base) y los métodos que cambian estado:

```java
public void applyPayment(Payment result) {
    if (!isPayable()) {
        throw new OrderNotPayable(status);
    }
    this.payment = result;
    this.status = switch (result.status()) {
        case AUTHORIZED -> OrderStatus.PAID;
        case REJECTED -> OrderStatus.PAYMENT_REJECTED;
        case PENDING -> OrderStatus.PAYMENT_PENDING;
    };
}
```

La máquina de estados del contrato está entera en `isPayable()`, `isCancellable()`,
`applyPayment` y `cancel`. `Money` es un `record` sobre `BigDecimal` con escala 2 y sin `double`
en ninguna parte; `amountAsText()` es lo que el contrato serializa. Ningún tipo del dominio tiene
anotaciones: `OrderTest` los prueba con JUnit y nada más.

### Los casos de uso coordinan; la unidad de trabajo delimita

`CreateOrder` es la pieza que más enseña. Recibe sus puertos por constructor y hace todo dentro de
`unitOfWork.run(...)`:

```java
return unitOfWork.run(() -> {
    var stored = idempotency.find(actorId, command.idempotencyKey());
    if (stored.isPresent()) { /* misma clave: replay o 422 */ }

    List<OrderLine> lines = new ArrayList<>();
    for (var line : command.lines()) {
        var product = products.find(line.sku()).orElseThrow(() -> NotFound.product(line.sku()));
        lines.add(new OrderLine(product.sku(), product.name(), line.quantity(), product.unitPrice()));
    }
    var order = Order.place(ids.next(), actorId, lines, clock.instant());
    orders.save(order);                            // primero el pedido: las reservas lo referencian
    inventory.reserve(order.id(), lines);          // lanza InsufficientInventory → rollback de todo
    idempotency.save(actorId, command.idempotencyKey(), command.requestHash(), 201, order.id().toString());
    return new Result(order, false);
});
```

Dos cosas que no se ven en el código y son el diseño:

- **La atomicidad no está en `reserve`.** `JpaInventory.reserve` descuenta línea a línea con un
  `UPDATE … WHERE available >= :quantity` y lanza al primer `0`. Lo que revierte las líneas ya
  descontadas —y el pedido, y la clave— es la transacción que `UnitOfWork` abrió. Si se quita
  `unitOfWork.run`, el código compila igual y deja reservas huérfanas. `CreateOrderTest` lo prueba
  con un doble de `UnitOfWork` que restaura los fakes al fallar.
- **`UnitOfWork` es un puerto** (`<T> T run(Supplier<T>)`). El adaptador es un
  `TransactionTemplate` construido en `OrdersConfiguration`. No hay `@Transactional` en el
  proyecto: el capítulo [05/02](../05-plataformas-y-practica/02-java-y-spring-boot.md) explica
  qué se evita (proxy, *self-invocation*, propagación invisible).

`AuthorizePayment` muestra el caso contrario: **dos** unidades de trabajo, con la llamada al
proveedor entre ambas y fuera de cualquier transacción. Una transacción abierta mientras se espera
a un tercero bloquea filas por un tiempo que no controlamos
([02/05](../02-nucleo-aplicacion-y-dominio/05-transacciones-y-limites-de-consistencia.md)).

### El borde HTTP traduce y no decide

`OrderController` convierte DTO en comando, resultado en DTO, y aplica las decisiones que son del
contrato: `201` + `Location` al crear, `200` + `Idempotent-Replay` al repetir. `ProblemHandler`
(`@RestControllerAdvice`) es el único sitio que conoce códigos HTTP: cada error de dominio o
aplicación se traduce una vez a un `ProblemDetail` con el `code` del contrato.

```java
@ExceptionHandler(InsufficientInventory.class)
ResponseEntity<ProblemDetail> insufficientInventory(InsufficientInventory e, HttpServletRequest req) {
    var problem = problem(HttpStatus.CONFLICT, "Insufficient inventory", "INSUFFICIENT_INVENTORY", e.getMessage(), req);
    problem.setProperty("errors", List.of(Map.of(
        "field", "lines[" + e.lineIndex() + "].quantity",
        "message", "requested " + e.requested() + ", available " + e.available())));
    return respond(problem);
}
```

`ActorResolver` construye el `Actor` desde el JWT ya verificado (`sub`, `email`, `role`). La
autorización contextual —"solo el dueño o un operator ve este pedido"— **no está en
`SecurityConfiguration`**: está en `Actor.canSee(order)`, que `GetOrder` aplica antes de
responder `404`. `SecurityConfiguration` solo decide qué rutas exigen token. Es el reparto de
[03/04](../03-adaptadores-de-entrada/04-autenticacion-autorizacion-y-contexto-de-actor.md).

### Las salidas: JPA con dos modelos, Redis, JWT

- `JpaOrders` traduce `Order` ↔ `OrderEntity`. Al leer, reconstruye un agregado completo: líneas
  con `FetchType.EAGER` (no hay sesión fuera del caso de uso: `open-in-view: false`) y el último
  pago desde `payments`. Nada de proxies que vayan a la base más tarde.
- `JpaIdempotencyStore` guarda la clave **en la misma transacción** que el pedido: un reintento
  tras una caída encuentra clave y pedido, o ninguno.
- `RedisTokenRevocationStore` guarda `hex:revoked:<jti>` con TTL igual al tiempo restante del
  token. `RevocationValidator` lo consulta en cada petición y `Logout` es una operación real.
- `JwtTokenIssuer` emite HS256 con el mismo secreto que verifica el resource server; el secreto
  tiene 39 bytes porque Nimbus exige al menos 32 para HS256 (el de §11 se alargó por esto).
- `DeterministicPaymentGateway` es la regla de §11: mayor de `1000.00` rechaza, `666.00` queda
  pendiente, el resto autoriza. Devuelve `PENDING` para lo incierto y nunca `REJECTED`.

### El composition root

`OrdersConfiguration` construye cada caso de uso con sus puertos. Es el único lugar que conoce a la
vez `CreateOrder` y `JpaOrders`. Y contiene la línea de la parte 3 antes de que la parte 3 exista:

```java
@Bean
Products products(HexProperties properties, JpaProducts jpa, MongoProducts mongo) {
    return "mongo".equals(properties.catalog()) ? mongo : jpa;
}
```

La suite `v1` (los cinco archivos de `hurl/v1/`) pasa al terminar esta parte; la salida completa
está en §5 porque el código de este taller se construyó de una vez y la suite se corrió entera.

## 5. 🔁 Parte 2: cancelación, outbox y Notifier

`CancelOrder` carga el pedido, deja que el agregado decida (`order.cancel(now)` devuelve `false`
si ya estaba cancelado, lanza `OrderNotCancellable` si está pagado), libera la reserva, guarda y
deja el hecho en la outbox, **todo en la misma unidad de trabajo**:

```java
boolean changed = order.cancel(clock.instant());
if (changed) {
    inventory.release(order.id());
    orders.save(order);
    order.pullEvents().forEach(pending::add);
}
```

La entrega es otra política, en otro caso de uso: `DeliverPendingPublications` toma un lote de la
outbox, resuelve el destinatario (`Users.findById(customerId).email`), llama al `Notifier` y marca
publicado. Quien lo dispara es `OutboxDispatcher`, un `@Scheduled(fixedDelay = 500)` en
infraestructura que no sabe qué es un evento. `TableNotifier` "entrega" escribiendo en
`notifications`, con el `id` del evento como clave: una segunda entrega del mismo hecho no crea una
segunda fila. Es la garantía de "al menos una vez, efecto una sola vez" de
[04/03](../04-adaptadores-de-salida-y-operacion/03-publicacion-de-eventos-y-outbox.md) en
cincuenta líneas.

**Evidencia.** El código se generó de una vez, así que no hay dos commits que comparar; lo que sí
se puede medir es qué archivos pertenecen a esta parte, y cuáles no se tocaron:

```text
$ find main -name '*.java' | grep -E 'CancelOrder|ListNotifications|DeliverPending|Notifier|Notifications|PendingPublications|NotificationController|OutboxDispatcher|TableNotifier|JpaPendingPublications|JpaNotifications|OutboxEntity|NotificationEntity|OutboxRepository|NotificationRepository|DomainEvent|OrderNotCancellable' | xargs wc -l | tail -1
     516 total      (17 archivos nuevos)
```

Lo que cambió de la parte 1: `Order` ganó `cancel` y `pullEvents`, `OrderController` ganó un
método, `OrdersConfiguration` tres `@Bean`, `HexOrdersApplication` la anotación
`@EnableScheduling`. `Products`, `Inventory`, `JpaInventory`, `JpaOrders`, `ProblemHandler` y
`SecurityConfiguration` no se editaron. Quien haga el taller en tres commits obtendrá el
`git diff --stat` con esos mismos nombres.

Salida literal de la suite completa, catálogo en PostgreSQL, 2026-09-27:

```text
$ hurl --test --jobs 1 --variable base_url=http://localhost:8081 hurl/v1/01-health.hurl hurl/v1/02-auth.hurl hurl/v1/03-products.hurl hurl/v1/04-orders.hurl hurl/v1/05-payment.hurl hurl/v1.1/06-cancel.hurl hurl/v1.1/07-notifications.hurl
Success hurl/v1/01-health.hurl (1 request(s) in 3 ms)
Success hurl/v1/02-auth.hurl (9 request(s) in 218 ms)
Success hurl/v1/03-products.hurl (12 request(s) in 232 ms)
Success hurl/v1/04-orders.hurl (20 request(s) in 289 ms)
Success hurl/v1/05-payment.hurl (14 request(s) in 188 ms)
Success hurl/v1.1/06-cancel.hurl (19 request(s) in 306 ms)
Success hurl/v1.1/07-notifications.hurl (10 request(s) in 2249 ms)
--------------------------------------------------------------------------------
Executed files:    7
Executed requests: 85 (24.3/s)
Succeeded files:   7 (100.0%)
Failed files:      0 (0.0%)
Duration:          3497 ms (0h:0m:3s:497ms)
```

Los 2,2 s de `07-notifications` son la espera del `retry` de `hurl` hasta que el dispatcher
entrega: la notificación aparece después del commit, no en la respuesta del `cancel`.

## 6. 🔀 Parte 3: el catálogo a MongoDB

Tres archivos nuevos en `outbound/mongo/`: `ProductDocument` (la forma de `seed/products.json`,
con `unitPrice.amount` como texto), `ProductDocumentRepository` y `MongoProducts`, que implementa
`Products` con la misma paginación por cursor que `JpaProducts`. Y la selección en el composition
root, que ya existía. Nada más.

```text
python3 06-talleres/laboratorio/scripts/lab.py seed --mongo
python3 06-talleres/laboratorio/scripts/lab.py java --catalog mongo
python3 06-talleres/laboratorio/scripts/lab.py suite --base-url http://localhost:8081
```

- `seed --mongo` carga el catálogo en `hex_catalog.products` además de la semilla de PostgreSQL
  (el inventario sigue allí).
- `java --catalog mongo` arranca el mismo jar con `--hex.catalog=mongo`.

```text
Success hurl/v1/01-health.hurl (1 request(s) in 2 ms)
Success hurl/v1/02-auth.hurl (9 request(s) in 700 ms)
Success hurl/v1/03-products.hurl (12 request(s) in 344 ms)
Success hurl/v1/04-orders.hurl (20 request(s) in 423 ms)
Success hurl/v1/05-payment.hurl (14 request(s) in 269 ms)
Success hurl/v1.1/06-cancel.hurl (19 request(s) in 370 ms)
Success hurl/v1.1/07-notifications.hurl (10 request(s) in 2268 ms)
--------------------------------------------------------------------------------
Executed files:    7
Executed requests: 85 (19.4/s)
Succeeded files:   7 (100.0%)
Failed files:      0 (0.0%)
Duration:          4384 ms (0h:0m:4s:384ms)
```

Y la prueba de que el catálogo se leyó y escribió en Mongo mientras el inventario siguió en
PostgreSQL: la suite da de alta `SKU-006` y `SKU-101`.

```text
$ docker exec hex-mongo mongosh --quiet hex_catalog --eval 'db.products.find({sku:{$in:["SKU-006","SKU-101"]}},{_id:0,sku:1,name:1}).toArray()'
[
  { sku: 'SKU-006', name: 'Laptop stand' },
  { sku: 'SKU-101', name: 'Cancel test item' }
]
$ docker exec hex-postgres psql -U hex -d hex_orders -Atc "select count(*) from products where sku in ('SKU-006','SKU-101')"
0
$ docker exec hex-postgres psql -U hex -d hex_orders -Atc "select sku, available from inventory where sku in ('SKU-006','SKU-101') order by sku"
SKU-006|10
SKU-101|6
```

- `mongosh --eval … .toArray()`: consulta y sale; `{_id:0, sku:1, name:1}` proyecta solo lo que
  interesa.
- Las dos consultas de `psql` son la contraprueba: ni un producto nuevo en la tabla `products`,
  y el inventario con sus movimientos (`SKU-101` quedó en 6 tras reservar, liberar y pagar).

Inventario de la parte: `113` líneas en tres archivos de `outbound/mongo/`; en `domain/`,
`application/` e `inbound/`, cero. Ese cero es el taller entero.

📝 La composición "producto + stock" (`ListProducts`, `GetProduct`) ya ocurría en aplicación desde
la parte 1: leía dos puertos y unía por `sku`. Por eso la parte 3 no la tocó. Si el catálogo y el
inventario hubieran sido un `JOIN` en un adaptador, la parte 3 habría empezado por reescribir la
lectura.

## 7. 🧪 Pruebas por anillos

Tres pruebas, una por anillo, sin Spring y sin base:

- `ArchitectureTest` (ArchUnit): `domain` no depende de `application`, `infrastructure`, Spring,
  JPA, Hibernate ni Mongo; `application` no depende de `infrastructure` ni de Spring;
  `inbound` no depende de `outbound`. Si alguien pone `@Entity` en `Order`, el build falla.
- `OrderTest`: la máquina de estados, con `Order.place` y `applyPayment`; cancelar dos veces
  emite el hecho una vez.
- `CreateOrderTest`: el caso de uso con fakes en memoria fieles a los puertos y un
  `SnapshotUnitOfWork` que restaura los fakes si el trabajo lanza. La prueba
  `insufficientInventoryLeavesNothingBehind` afirma que tras un `409` no queda pedido, ni
  reserva, ni clave: es la prueba de la unidad de trabajo, no del inventario.

```text
$ mvn test
[INFO] Tests run: 4, Failures: 0, Errors: 0, Skipped: 0, Time elapsed: 0.054 s -- in hex.orders.application.usecase.CreateOrderTest
[INFO] Tests run: 5, Failures: 0, Errors: 0, Skipped: 0, Time elapsed: 0.006 s -- in hex.orders.domain.OrderTest
[INFO] Tests run: 3, Failures: 0, Errors: 0, Skipped: 0, Time elapsed: 0.729 s -- in hex.orders.ArchitectureTest
```

Lo que **no** hay, y se declara: una prueba de `JpaOrders` contra PostgreSQL con Testcontainers.
La suite `hurl` cubre ese anillo de extremo a extremo; una prueba de contrato del puerto `Orders`
sobre base real es el ejercicio 6.

## 8. 🩺 Errores provocados a propósito

Cinco fallos reales de la construcción, en el orden en que aparecieron. Cada uno es una lección
que un sabor bien redactado tendría que inventar; aquí no hizo falta.

### Dos beans del mismo tipo: el `CorsConfigurationSource`

```text
Error creating bean with name 'api' … No qualifying bean of type
'org.springframework.web.cors.CorsConfigurationSource' available: expected single matching bean
but found 2: corsConfigurationSource,mvcHandlerMappingIntrospector
```

Spring MVC registra su propio `CorsConfigurationSource`; declarar otro como `@Bean` e inyectarlo
por tipo deja la resolución ambigua y el contexto no arranca. Corrección: construirlo como método
privado y pasarlo a mano en la cadena de filtros. Lección: un contenedor resuelve por tipo, y el
framework ya tiene tipos registrados que no ves.

### La reserva antes que el pedido: la FK dice que no

```text
ERROR: insert or update on table "inventory_reservations" violates foreign key constraint
"inventory_reservations_order_id_fkey"
```

La primera versión de `CreateOrder` reservaba antes de guardar el pedido, y
`inventory_reservations.order_id` referencia `orders.id`. La suite respondió con cinco archivos en
`500`. Corrección: `orders.save(order)` antes de `inventory.reserve(...)`. Y la reflexión que
vale más que la corrección: el orden de las llamadas **no** es lo que garantiza que un `409` deje
el sistema limpio; lo garantiza la unidad de trabajo. `CreateOrderTest` quedó escrito para probar
exactamente eso.

### `TOKEN_REVOKED` que llega como `UNAUTHENTICATED`

```text
63 | jsonpath "$.code" == "TOKEN_REVOKED"
   |   actual:   string <UNAUTHENTICATED>
```

`RevocationValidator` devolvía un `OAuth2Error` con código `token_revoked`, y el entry point lo
buscaba en la excepción recibida. Pero el proveedor JWT de Spring envuelve **todo** fallo de
validación en un `InvalidBearerTokenException` con código genérico `invalid_token`; el código
original solo sobrevive en la causa, una `JwtValidationException` con la lista de errores.
Corrección: recorrer la cadena de causas y buscar ahí. Lección: la traducción de errores del
framework también es una frontera, y hay que leer qué conserva y qué pierde.

### `jsonb` no guarda tu texto

```text
$ docker exec hex-postgres psql -U hex -d hex_orders -Atc "select response_body::text from idempotency_keys limit 1"
{"ref": "268944ee-4029-4903-b6d2-1d66e55242ac"}
```

El adaptador guardaba `{"ref":"…"}` y lo leía por posición (`indexOf("\"ref\":\"")`). PostgreSQL
`jsonb` normaliza el documento y lo devuelve con un espacio tras los dos puntos: la lectura por
posición falla, la repetición idempotente devuelve `400` y el destinatario de la notificación sale
`unknown`. Corrección: leer por patrón (`"ref"\s*:\s*"…"`) o con un parser JSON. Lección: un tipo
de columna es un contrato con semántica propia, no un `text` con otro nombre.

### La propiedad que Boot 4 renombró: el backend habló con otro Mongo

```text
Command execution failed on MongoDB server with error 13 (Unauthorized):
'Command find requires authentication' on server localhost:27017
```

`application.yaml` decía `spring.data.mongodb.uri` con el puerto `17017`. Spring Boot 4 renombró
la propiedad a `spring.mongodb.uri` (y `spring.data.redis.*` a `spring.redis.*`); el nombre viejo de
Mongo se ignoró en silencio y el cliente cayó al puerto por defecto, `27017`, donde escucha el
Mongo del laboratorio de bases de datos, que exige autenticación. La suite lo dijo con seis
archivos en `500`. Corrección: los nombres nuevos, verificados en los metadatos del jar
(`spring-boot-mongodb-4.1.1.jar`). Lección doble: las versiones se fijan y se leen sus notas de
migración; y un puerto no estándar en el laboratorio no es una manía: es lo que hizo visible el
error.

## 9. 🧰 Cinco plataformas

| Plataforma | Qué da hecho | Qué te deja a ti | Trampa frecuente |
|---|---|---|---|
| **Java · Spring Boot** | contenedor, `TransactionTemplate`, JPA, resource server JWT, validación de DTO, `ProblemDetail` | casos de uso sin anotaciones, `UnitOfWork` como puerto, dos modelos (dominio y entidad), ArchUnit | `@Transactional` sobre el caso de uso y una *self-invocation* que lo salta; devolver la `@Entity`; dos beans del mismo tipo |
| Node/TS · NestJS | módulos y providers, pipes de validación | tokens para interfaces borradas, transacción compartida en Prisma, promesas con dueño | inyectar una `interface` sin token; `publish()` sin `await` |
| Go · `net/http` | `sql.Tx`, `context`, `httptest` | composición manual en `main`, interfaces junto al consumidor, errores como valores | usar `db` dentro de una operación con `tx`; paquete `interfaces` global |
| Python · FastAPI | `Depends`, Pydantic, SQLAlchemy | `Protocol` como puerto, `Depends` solo en el borde, sesión controlada | `HTTPException` desde el dominio; `Session` global |
| PHP · Laravel | service container, Eloquent, form requests, `DB::transaction` | que el modelo Eloquent no sea el dominio; el container como composition root | el modelo *active record* haciendo de agregado y de DTO |

Las cuatro filas que no son Java se desarrollan en sus talleres; aquí están para que la
comparación se lea desde el primer sabor.

## 10. 🧹 Teardown

`Ctrl+C` en la terminal de `lab.py java` para el backend. El entorno se apaga con
`python3 06-talleres/laboratorio/scripts/lab.py down`. `target/` es de Maven y no se versiona.

## ⚠️ Errores frecuentes

- "Los casos de uso van con `@Service` y `@Transactional`." Compila y funciona; el límite
  transaccional pasa a depender de un proxy y de quién llama a quién.
- "Con `UnitOfWork` da igual el orden de las llamadas." Da igual para la consistencia final, no
  para las restricciones de la base: la FK obligó a guardar el pedido antes de reservar.
- "Spring Data `JpaRepository` es el puerto." Es el detalle: `Orders` tiene tres métodos con
  nombres de negocio; `OrderRepository` tiene los que Spring Data necesita.
- "El `401` es del framework y no se puede matizar." Se puede, leyendo la causa; hay que saber
  qué envuelve el proveedor.
- "Las propiedades viejas siguen funcionando." Algunas sí (Redis), otras se ignoran en silencio
  (Mongo). Se leen las notas de migración de la versión que se fija.

## ✅ Veredicto

Spring en el borde, Java en el centro, y la frontera verificada por ArchUnit y por una suite que
pasa dos veces. Lo que costó —composición explícita, un puerto para la transacción, dos modelos—
es lo que hizo que la parte 3 fueran tres archivos y una línea. Los cinco errores reales enseñan
más que el código que funcionó a la primera.

## 📚 Referencias

- [Spring Boot 4.0: guía de migración](https://github.com/spring-projects/spring-boot/wiki/Spring-Boot-4.0-Migration-Guide) · [propiedades de configuración](https://docs.spring.io/spring-boot/appendix/application-properties/index.html)
- [Spring Security: resource server JWT](https://docs.spring.io/spring-security/reference/servlet/oauth2/resource-server/jwt.html) · [decodificar con clave simétrica](https://docs.spring.io/spring-security/reference/servlet/oauth2/resource-server/jwt.html#oauth2resourceserver-jwt-decoder-secret-key)
- [Spring Framework: transacciones programáticas (`TransactionTemplate`)](https://docs.spring.io/spring-framework/reference/data-access/transaction/programmatic.html)
- [Spring Framework: `ProblemDetail` y errores REST](https://docs.spring.io/spring-framework/reference/web/webmvc/mvc-ann-rest-exceptions.html)
- [Spring Data JPA: métodos de consulta y `@Modifying`](https://docs.spring.io/spring-data/jpa/reference/jpa/query-methods.html)
- [Spring Boot: SQL](https://docs.spring.io/spring-boot/reference/data/sql.html) · [NoSQL (MongoDB, Redis)](https://docs.spring.io/spring-boot/reference/data/nosql.html) · [tareas programadas](https://docs.spring.io/spring-boot/reference/features/task-execution-and-scheduling.html) · [plugin de Maven: `run`](https://docs.spring.io/spring-boot/maven-plugin/run.html)
- [PostgreSQL 17: tipos JSON](https://www.postgresql.org/docs/17/datatype-json.html)
- [ArchUnit: guía de usuario](https://www.archunit.org/userguide/html/000_Index.html)
- [SDKMAN: uso](https://sdkman.io/usage/)

## 🧠 Preguntas

1. 🟢 ¿Por qué los casos de uso no llevan `@Service` ni `@Transactional`?
2. 🟢 ¿Qué es `UnitOfWork` y cuál es su adaptador?
3. 🟢 ¿Por qué `Order` y `OrderEntity` son dos clases?
4. 🟢 ¿Dónde vive la regla "solo el dueño o un operator ve el pedido" y por qué no en `SecurityConfiguration`?
5. 🟢 ¿Qué comprueba `ArchitectureTest` que un `grep` no comprobaría?
6. 🟡 ¿Por qué `AuthorizePayment` usa dos unidades de trabajo y no una?
7. 🟡 ¿Qué garantiza que un `409 INSUFFICIENT_INVENTORY` no deje reservas huérfanas, y qué prueba lo demuestra?
8. 🟡 ¿Por qué `JpaOrders` carga las líneas con `EAGER` y qué relación tiene con `open-in-view: false`?
9. 🟡 ¿Qué hace `TableNotifier` para que "al menos una vez" no se convierta en "dos filas"?
10. 🟡 ¿Qué tuvo que cambiar y qué no para llevar el catálogo a MongoDB?
11. 🟠 El `TOKEN_REVOKED` llegaba como `UNAUTHENTICATED`. ¿Qué frontera del framework lo causó y cómo se resolvió sin tocar el caso de uso?
12. 🟠 El backend habló con el Mongo equivocado y la suite lo detectó. ¿Qué dos decisiones del bloque hicieron posible detectarlo?
13. 🟠 `jsonb` devolvió `{"ref": "…"}` con espacio y rompió la repetición idempotente. ¿Qué tipo de acoplamiento había y cómo lo evitarías desde el diseño?
14. 🟠 Un compañero propone quitar `UnitOfWork` y poner `@Transactional` en los controllers "para simplificar". Defiende o refuta con lo que este taller mostró.

## 🧪 Ejercicios

1. 🟢 Pon `@Entity` en `Order` (solo la anotación) y corre `lab.py java --test`. Pega la salida de
   ArchUnit y explica qué regla falló.
2. 🟢 Cambia `poll-ms` de la outbox a `5000` y corre solo `07-notifications.hurl`. Explica por qué
   pasa igual y qué cambió en la duración.
3. 🟡 Añade `@Transactional` a `CreateOrder.execute` y quita `unitOfWork.run`. Corre la suite. ¿Pasa?
   Explica por qué sí, y qué habrías perdido aunque pase (pista: `AuthorizePayment`).
4. 🟡 Provoca la carrera de la última unidad: dos `POST /orders` concurrentes por el último
   `SKU-005` (stock 3 → pide 3 dos veces). Explica por qué el `UPDATE … WHERE available >= :q`
   hace que uno gane y otro reciba `409`, sin `SELECT FOR UPDATE`.
5. 🟠 Sustituye la lectura por patrón de `JpaIdempotencyStore` por un `Map<String, String>` mapeado
   con `@JdbcTypeCode(SqlTypes.JSON)`. Explica qué gana y qué cuesta frente al `String`.
6. 🟠 Escribe una prueba de contrato del puerto `Orders` con Testcontainers (PostgreSQL 17.11):
   guardar, recargar y comprobar que `status`, `version` y las líneas sobreviven. Decide si la
   misma prueba debe correr también contra el fake de `CreateOrderTest`, y por qué.
7. 🔴 Implementa `GET /api/v1/orders/{id}/payment` (consulta al proveedor para un pedido
   `PAYMENT_PENDING`) sin tocar `domain/`. Define el puerto nuevo, el adaptador determinista y el
   cambio en `AuthorizePayment` o en un caso de uso nuevo. Argumenta cuál.
8. 🔥 Convierte `hex.catalog` en una decisión por petición: un header `X-Catalog: mongo` que el
   composition root traduce a un `Products` distinto. Explica por qué es una mala idea aunque
   funcione, y qué lección hexagonal contradice.

---

**Siguiente:** [04 — TypeScript y NestJS](04-caso-typescript-nestjs.md), o cualquier otro sabor.
