# 06 — Modularizar

Este taller es **opcional**, como todo el bloque `06-talleres/`, y depende de
[`04` — El contrato](04-el-contrato.md): su suite `hurl/v1` es la red que permite mover el código sin
cambiar la API. Parte del estado que dejó [`05` — SQLite miente](05-sqlite-miente.md), cuyas pruebas
contra PostgreSQL protegen la cancelación. Reorganiza `mono-legacy` de paquetes por capa a paquetes
por capacidad, rompe el ciclo `OrderService` ↔ `InventoryService`, saca del *trigger* y del
controlador la lógica de cancelar y lo **demuestra** con Spring Modulith y ArchUnit. Termina cuando
las dos pruebas arquitectónicas y `hurl/v1` están en verde, la topología sigue siendo un solo proceso
y puedes explicar qué dependencia existe entre cada par de módulos y por qué.

> Ejercita [`01/06` — Estilos de estructura interna](../01-fundamentos-y-modelo-mental/06-estilos-de-estructura-interna.md),
> [`02/01` — Módulos alrededor de capacidades de negocio](../02-modularidad-y-limites-internos/01-modulos-alrededor-de-capacidades-de-negocio.md),
> [`02/02` — API pública del módulo](../02-modularidad-y-limites-internos/02-api-publica-del-modulo-y-encapsulacion-interna.md),
> [`02/03` — Dirección de dependencias y ciclos](../02-modularidad-y-limites-internos/03-direccion-de-dependencias-y-ciclos-entre-modulos.md)
> y [`02/06` — Código compartido y controles arquitectónicos](../02-modularidad-y-limites-internos/06-codigo-compartido-shared-kernel-y-controles-arquitectonicos.md).
> Las reglas del bloque están en §11 y §12 de la [guía de estilo](../prompts/guia-de-estilo-y-convenciones.md).
>
> **Vigencia:** 2026-09-29. Versiones verificadas ese día en Maven Central; salidas corridas ese día
> en macOS con Docker Desktop y JDK 25.0.4.

**Salto rápido:** [1](#1--qué-enseña-este-taller) · [2](#2--prerrequisitos-y-versiones) · [3](#3-️-mapa-de-carpetas) · [4](#4--recorrido-de-la-base-de-código) · [5](#5--provocación-la-prueba-arquitectónica-en-verde-sobre-capas) · [6](#6--de-capas-a-capacidades) · [7](#7--provocación-el-import-prohibido) · [8](#8--dentro-del-módulo-archunit) · [9](#9--provocación-la-regla-en-dos-sitios) · [10](#10--evidencia) · [11](#11--errores-reales-al-correrlo) · [12](#12--plataformas) · [13](#13--teardown) · [Preguntas](#-preguntas) · [Ejercicios](#-ejercicios)

---

## 1. 🎯 Qué enseña este taller

`mono-legacy` está organizado por capa técnica: `controller`, `service`, `repository`, `entity`,
`dto`, `util`, `config`. Cambiar la cancelación toca cuatro de esas carpetas y un *trigger* de la
base. El taller lo reorganiza por **capacidad** —`orders`, `inventory`, `payments`, `notifications`,
más `auth`, `reports` y un núcleo compartido— sin partir el proceso.

```text
antes (capas)                          después (capacidades)
controller ─► service ─► repository    orders ──► inventory, auth, notifications
     │           │  ▲          │       payments ─► orders        (implementa PaymentLookup)
     └──► dto ───┘  │          ▼       reports ──► orders
                util ────► entity      todos ────► shared
OrderService ⇄ InventoryService        sin ciclos, verificado en cada `mvn test`
(dentro de "service": invisible)
```

Tres ideas:

- **Una prueba arquitectónica solo vale si los módulos son los correctos.** Sobre paquetes por capa,
  Spring Modulith pasa en verde: sus «módulos» son las capas y el ciclo queda dentro de una de ellas.
  El verde no dice nada hasta que los módulos son capacidades.
- **Un módulo es una API pequeña y un interior escondido.** La raíz de cada paquete es lo que otros
  pueden usar; `internal` y `web` no. Las entidades JPA son interiores: entre módulos viajan
  identificadores y *snapshots*, no `@ManyToOne` hacia la tabla de otro.
- **Una regla vive en un solo sitio.** Cancelar estaba repartido entre el controlador (no se cancela
  un pagado), el servicio (el estado) y un *trigger* (el stock). Moverla a su módulo exige quitar la
  copia anterior en el mismo cambio, o la regla se ejecuta dos veces.

El precio: 75 archivos tocados, 39 de ellos movimientos que conservan al menos la mitad del contenido, un puerto nuevo para romper el ciclo y dos
claves foráneas que las bases nuevas ya no tienen (sección 11). Lo que compra es que la próxima
pregunta —¿se puede sacar `inventory` a otro proceso?— se responde leyendo un grafo verificado y no
buscando `import` a mano.

## 2. 🧰 Prerrequisitos y versiones

Lo de los talleres [01](01-heredar-el-legado.md#2--prerrequisitos-y-versiones) y
[05](05-sqlite-miente.md#2--prerrequisitos-y-versiones) (las pruebas necesitan Docker). Verificado el
2026-09-29:

| Pieza | Versión | Cómo se comprobó |
|---|---|---|
| Spring Modulith (`spring-modulith-bom`) | `2.1.1`, última GA (`2.2.0-M2` es un *milestone*) | `maven-metadata.xml` de Maven Central; su `spring-modulith-core` declara `spring-boot-autoconfigure` `4.1.1` |
| ArchUnit | `1.4.2`, la que trae Modulith 2.1.1 (la última publicada es `1.5.1`) | `mvn dependency:list` |

Se usa la ArchUnit que trae Modulith, sin declarar otra: dos versiones de ArchUnit en el mismo
*classpath* se resolverían por cercanía en el árbol de Maven, y no es una decisión que merezca este
taller. `spring-modulith-api` (solo anotaciones) va en el código; `spring-modulith-starter-test`, en
las pruebas.

## 3. 🗂️ Mapa de carpetas

```text
06-talleres/laboratorio/legacy/src/main/java/dev/mono/legacy/
├── LegacyApplication.java
├── shared/          ErrorCode, LegacyException, Money, Page · web/ApiErrorHandler, HealthController
├── auth/            Customers (API) · internal/ usuarios, tokens, SecurityConfig · web/ login y logout
├── inventory/       InventoryService, ReservedStock (API) · internal/ Product, SchemaFixer · web/ catálogo
├── notifications/   Notifications (API) · internal/ Notification, NotificationQueries · web/
├── orders/          OrderService, OrderSnapshot, PaymentLookup (API) · internal/ Order, OrderCache · web/
├── payments/        (sin API propia) · internal/ PaymentService, PaymentLookupAdapter · web/ PaymentController
└── reports/         (sin API propia) · internal/ ReportService, DailyCloseJob, BatchRun · web/
    cada módulo: package-info.java con @ApplicationModule(allowedDependencies = ...)

legacy/src/main/resources/db/     triggers.sql → drop-legacy-trigger.sql
legacy/src/test/java/dev/mono/legacy/
├── ModularityTest.java           nuevo: Spring Modulith verify() e imprime el grafo
├── ArchitectureTest.java         nuevo: dos reglas ArchUnit dentro de los módulos
└── OrderServiceTest.java         solo cambian los import
```

## 4. 🔎 Recorrido de la base de código

Antes de mover nada, lo que hay que contestar sobre el estado 05. Después, dónde quedó cada respuesta
en `laboratorio/estados/06/`.

| Pregunta | Antes (estado 05) | Después (estado 06) |
|---|---|---|
| ¿Por qué `OrderService` y `InventoryService` se inyectan por campo? | ciclo de beans: `InventoryService.isReserved` usaba `OrderService`, y nadie llamaba a `isReserved` | no hay ciclo: `inventory/InventoryService.java` no conoce pedidos; `allow-circular-references` fuera de `application.yaml` |
| ¿Quién devuelve el stock al cancelar? | el *trigger* `orders_restore_stock`, que creaba `config/SchemaFixer.java` | `orders/OrderService.java:130` llama a `inventory/InventoryService.java:36`; `db/drop-legacy-trigger.sql:3` retira el *trigger* |
| ¿Dónde vive «un pagado no se cancela»? | `controller/OrderController.java`, antes de llamar al servicio | `orders/OrderService.java:124`, junto al cambio de estado |
| ¿Qué módulos puede usar `orders`? | cualquiera: no había módulos | `orders/package-info.java:4`: `inventory`, `auth`, `notifications`, `shared` |
| ¿Cómo muestra un pedido su último pago sin depender de `payments`? | `Order.payments`, un `@OneToMany` hacia la entidad de pagos | puerto `orders/PaymentLookup.java`, implementado en `payments/internal/PaymentLookupAdapter.java:11` |
| ¿Cómo referencia un pedido a su cliente? | `@ManyToOne User customer` | `orders/internal/Order.java:19`, `UUID customerId`, la misma columna |

## 5. 🧨 Provocación: la prueba arquitectónica en verde sobre capas

`ModularityTest` pide a Spring Modulith el grafo de módulos y lo verifica:

```java
static final ApplicationModules MODULES = ApplicationModules.of(LegacyApplication.class);

@Test
void modulesAreVerified() {
    MODULES.forEach(m -> System.out.println("módulo " + m.getIdentifier() + " → " + dependencies(m)));
    MODULES.verify();
}
```

- `ApplicationModules.of` analiza el *bytecode* a partir del paquete de la clase principal: cada
  subpaquete directo es un módulo; su raíz, la API; sus subpaquetes, internos.
- `verify()` falla si hay ciclos entre módulos, si un módulo usa un tipo interno de otro o si depende
  de uno que su `allowedDependencies` no permite.
- `dependencies(m)` imprime las dependencias directas de cada módulo, calculadas del código.

La misma prueba, copiada sobre el legado del estado 05 (paquetes por capa):

```text
módulo entity → []
módulo repository → [entity]
módulo util → [entity]
módulo config → [util]
módulo dto → [entity, util]
módulo service → [dto, entity, repository, util]
módulo controller → [dto, entity, repository, service, util]
[INFO] Tests run: 1, Failures: 0, Errors: 0, Skipped: 0, Time elapsed: 1.023 s -- in dev.mono.legacy.ModularityTest
```

**En verde.** Siete «módulos» que son capas, un grafo acíclico perfecto y el ciclo de beans del
legado escondido dentro de `service`, donde ninguna regla entre módulos lo ve. Es el error que
[`02/06`](../02-modularidad-y-limites-internos/06-codigo-compartido-shared-kernel-y-controles-arquitectonicos.md)
avisa: una herramienta de modularidad verifica las fronteras que le das. Si las fronteras son
técnicas, verifica que las capas no se llamen al revés, y nada sobre las capacidades.

## 6. 🔀 De capas a capacidades

La reorganización se hizo en dos pasos. Primero, **mover sin cambiar comportamiento**: cada clase a
su módulo, con el *trigger* todavía en la base, y `hurl/v1` en verde antes de seguir. Después, las
decisiones que exigían los límites.

| Decisión | Por qué |
|---|---|
| `InventoryService.isReserved` se borra | nadie lo llamaba y era la única razón del ciclo con `OrderService` |
| `Order.customer` (`@ManyToOne User`) pasa a `UUID customerId`; el correo se pide a `auth.Customers` | una entidad de `orders` no navega a la tabla de `auth`; misma columna, sin cambio de esquema |
| `Payment.order` pasa a `UUID orderId`; `Order.payments` desaparece | la relación JPA en los dos sentidos era un ciclo `orders` ⇄ `payments` a nivel de entidades |
| El pedido pide su último pago por `orders.PaymentLookup`, que implementa `payments` | inversión de dependencia: `orders` declara lo que necesita, `payments` lo provee y la flecha va de `payments` a `orders` |
| `POST /orders/{id}/payment` pasa de `OrderController` a `payments/web/PaymentController` | misma ruta del contrato, otro dueño; si se quedaba en `orders`, `orders` dependería de `payments` |
| `payments` ya no cambia el estado del pedido; se lo pide a `OrderService.recordPaymentOutcome` | el dueño del pedido es quien escribe el pedido |
| `DailyCloseJob` pasa a `reports` y le pide a `orders` que caliente su caché | la caché es de `orders`; el registro del cierre, de `reports` |
| `shared` reúne errores, dinero y paginación, con `allowedDependencies = {}` | núcleo compartido explícito: todos dependen de él y él de nadie |

Cada `package-info.java` declara lo permitido:

```java
@ApplicationModule(allowedDependencies = {"inventory", "auth", "notifications", "shared"})
package dev.mono.legacy.orders;
```

- `allowedDependencies` enumera los módulos que `orders` puede usar, y solo por su API. Sin la
  anotación, Modulith permitiría cualquier dependencia sin ciclos; con ella, una dependencia nueva
  exige cambiar esta línea, que es donde se revisa.

Los contratos de cada API son pequeños a propósito: `inventory` expone `reserve` y `release` con un
`record` `ReservedStock`, no la entidad `Product`; `orders` expone `OrderSnapshot`, no `Order`.

## 7. 🧨 Provocación: el import prohibido

Un compañero necesita marcar el pedido como pagado «rápido» y le inyecta a `PaymentService` el
repositorio de pedidos:

```text
4a5
> import dev.mono.legacy.orders.internal.OrderRepository;
25a27
>     private final OrderRepository orderTable;     // "atajo": marcar el pedido sin pasar por orders
```

```bash
python3 laboratorio/scripts/lab.py test
```

```text
[ERROR] Tests run: 1, Failures: 0, Errors: 1, Skipped: 0, Time elapsed: 1.027 s <<< FAILURE! -- in dev.mono.legacy.ModularityTest
org.springframework.modulith.core.Violations: 
- Module 'payments' depends on non-exposed type dev.mono.legacy.orders.internal.OrderRepository within module 'orders'!
- Module 'payments' depends on non-exposed type dev.mono.legacy.orders.internal.OrderRepository within module 'orders'!
- Module 'payments' depends on non-exposed type dev.mono.legacy.orders.internal.OrderRepository within module 'orders'!
```

La misma violación tres veces, una por cada referencia que Modulith encuentra en el *bytecode*
(el `import` no existe en el *bytecode*; el campo y el constructor, sí). El código compila y la
aplicación arrancaría; lo que falla es la prueba, que es el único sitio donde el límite existe.

Y otro, que quiere el stock en el informe y usa la API pública de `inventory` desde `reports`:

```text
org.springframework.modulith.core.Violations: - Module 'reports' depends on module 'inventory' via dev.mono.legacy.reports.internal.ReportService -> dev.mono.legacy.inventory.InventoryService. Allowed targets: orders, shared.
```

Aquí no hay tipo interno: `InventoryService` es API. Falla porque `reports` no declaró esa
dependencia. Quizá sea legítima; la prueba obliga a decidirlo cambiando `allowedDependencies`, a la
vista de quien revise el cambio. Los dos cambios se revierten y la prueba vuelve a verde.

## 8. 🧱 Dentro del módulo: ArchUnit

Modulith vigila las dependencias **entre** módulos. Lo de dentro lo vigila ArchUnit, con dos reglas:

```java
@Test
void webLayerDoesNotTouchRepositories() {
    noClasses().that().resideInAPackage("..web..")
        .should().dependOnClassesThat().areAssignableTo(Repository.class)
        .because("un controlador habla con la API de su módulo, no con sus tablas")
        .check(CLASSES);
}
```

- `CLASSES` importa el *bytecode* de `dev.mono.legacy` sin las clases de prueba.
- `noClasses().that().resideInAPackage("..web..")` selecciona los controladores y sus DTO de todos
  los módulos; `..` es cualquier prefijo.
- `areAssignableTo(Repository.class)` cubre cualquier repositorio de Spring Data.
- La segunda regla, `entitiesAreInternal`, exige que toda clase `@Entity` viva en un paquete
  `..internal..`.

La primera corrida, recién reorganizado:

```text
Architecture Violation [Priority: MEDIUM] - Rule 'no classes that reside in a package '..web..' should depend on classes that are assignable to org.springframework.data.repository.Repository, because un controlador habla con la API de su módulo, no con sus tablas' was violated (7 times):
Constructor <dev.mono.legacy.notifications.web.NotificationController.<init>(dev.mono.legacy.notifications.internal.NotificationRepository)> has parameter of type <dev.mono.legacy.notifications.internal.NotificationRepository> in (NotificationController.java:0)
Constructor <dev.mono.legacy.reports.web.ReportController.<init>(dev.mono.legacy.reports.internal.ReportService, dev.mono.legacy.reports.internal.BatchRunRepository)> has parameter of type <dev.mono.legacy.reports.internal.BatchRunRepository> in (ReportController.java:0)
...
Method <dev.mono.legacy.reports.web.ReportController.batch(org.springframework.security.oauth2.jwt.Jwt, java.lang.Long)> calls method <dev.mono.legacy.reports.internal.BatchRunRepository.findById(java.lang.Object)> in (ReportController.java:35)
```

Dos controladores heredados del legado leían tablas directamente. Modulith no lo ve —es el mismo
módulo— y no es un problema de límites, sino de forma. Se corrige con `NotificationQueries` y
`ReportService.batch`, y las dos reglas pasan.

## 9. 🧨 Provocación: la regla en dos sitios

Con los módulos en su sitio, la cancelación se muda: la regla «un pagado no se cancela» del
controlador a `OrderService.cancel`, y la devolución del stock del *trigger* a
`InventoryService.release`, que `cancel` llama por cada línea. El *trigger* se deja, todavía, en la
base. La prueba que el taller 05 escribió para este momento es `cancelReturnsStock`:

```text
Running dev.mono.legacy.OrderServiceTest
Tests run: 5, Failures: 1, Errors: 0, Skipped: 1, Time elapsed: 5.835 s <<< FAILURE! -- in dev.mono.legacy.OrderServiceTest
dev.mono.legacy.OrderServiceTest.cancelReturnsStock -- Time elapsed: 0.065 s <<< FAILURE!
org.opentest4j.AssertionFailedError: expected: <20> but was: <22>
```

Veinte menos dos más dos más dos: el *trigger* devolvió las dos unidades al cambiar el estado, y Java
las devolvió otra vez. Mover una regla sin retirar la copia anterior no la mueve: la duplica. La
corrección es que `SchemaFixer`, que antes **creaba** el *trigger*, ahora lo **retira**:

```sql
DROP TRIGGER IF EXISTS orders_restore_stock ON orders;
DROP FUNCTION IF EXISTS restore_stock_on_cancel();
```

- `IF EXISTS` hace el script idempotente: una base nueva nunca tuvo el *trigger* y el arranque no
  falla.
- Se borra también la función: sin *trigger* que la llame es código muerto en la base.

```text
Running dev.mono.legacy.OrderServiceTest
[WARNING] Tests run: 5, Failures: 0, Errors: 0, Skipped: 1, Time elapsed: 5.106 s -- in dev.mono.legacy.OrderServiceTest
```

Y en la base de desarrollo, tras arrancar el legado:

```bash
python3 laboratorio/scripts/lab.py sql "SELECT count(*) AS triggers FROM pg_trigger WHERE tgname = 'orders_restore_stock'"
```

```text
 triggers 
----------
        0
(1 row)
```

La sección 11 cuenta por qué el primer intento de esta mudanza **no** puso la prueba en rojo, y es
el hallazgo más interesante del taller.

## 10. 🧪 Evidencia

Las tres pruebas del legado, `hurl/v1` y el grafo que Modulith calcula del código:

```bash
python3 laboratorio/scripts/lab.py test
python3 laboratorio/scripts/lab.py suite
```

```text
$ mvn test   (se muestran solo el resumen y los fallos)
Running dev.mono.legacy.ModularityTest
Tests run: 1, Failures: 0, Errors: 0, Skipped: 0, Time elapsed: 1.036 s -- in dev.mono.legacy.ModularityTest
Running dev.mono.legacy.OrderServiceTest
[WARNING] Tests run: 5, Failures: 0, Errors: 0, Skipped: 1, Time elapsed: 5.106 s -- in dev.mono.legacy.OrderServiceTest
Running dev.mono.legacy.ArchitectureTest
Tests run: 2, Failures: 0, Errors: 0, Skipped: 0, Time elapsed: 0.286 s -- in dev.mono.legacy.ArchitectureTest
Tests run: 8, Failures: 0, Errors: 0, Skipped: 1
BUILD SUCCESS
```

```text
Success 01-health.hurl (1 request(s) in 3 ms)
Success 02-auth.hurl (9 request(s) in 385 ms)
Success 03-products.hurl (12 request(s) in 262 ms)
Success 04-orders.hurl (18 request(s) in 306 ms)
Success 05-payment.hurl (12 request(s) in 2211 ms)
Success 06-cancel.hurl (19 request(s) in 290 ms)
Success 07-notifications.hurl (9 request(s) in 1705 ms)
Success 08-reports.hurl (5 request(s) in 191 ms)
--------------------------------------------------------------------------------
Executed files:    8
Executed requests: 85 (15.8/s)
Succeeded files:   8 (100.0%)
Failed files:      0 (0.0%)
Duration:          5365 ms (0h:0m:5s:365ms)
```

```text
módulo shared → []
módulo auth → [shared]
módulo inventory → [shared]
módulo notifications → [shared]
módulo orders → [auth, inventory, notifications, shared]
módulo payments → [orders, shared]
módulo reports → [orders, shared]
```

Es el grafo del diagrama de la sección 1, pero calculado, no dibujado: si mañana alguien añade una
flecha, esta salida cambia y `verify()` decide si está permitida. `hurl/v1` no cambió ni una línea:
la reorganización entera es invisible para los clientes.

```bash
git diff --no-index --stat -M50% laboratorio/estados/05/legacy/src laboratorio/estados/06/legacy/src
```

- `-M50%` detecta como movimiento un archivo que conserva al menos la mitad de su contenido; así el
  resumen distingue lo movido de lo reescrito.

```text
 .../main/java/dev/mono/legacy/auth/Customers.java  |  21 +++
 .../mono/legacy/auth/internal}/AuthService.java    |  11 +-
 .../mono/legacy/auth/internal}/RevokedTokens.java  |   2 +-
 ...
 .../java/dev/mono/legacy/orders/OrderService.java  | 147 +++++++++++++++++++++
 .../java/dev/mono/legacy/orders/OrderSnapshot.java |   9 ++
 .../java/dev/mono/legacy/orders/PaymentLookup.java |  12 ++
 .../dev/mono/legacy/orders/internal}/Order.java    |  17 +--
 ...
 .../legacy/service/OrderService.java => /dev/null  | 107 ---------------
 .../service/PaymentService.java => /dev/null       |  71 ----------
 ...
 .../main/resources/db/triggers.sql => /dev/null    |  19 ---
 .../java/dev/mono/legacy/ArchitectureTest.java     |  35 +++++
 .../test/java/dev/mono/legacy/ModularityTest.java  |  26 ++++
 .../java/dev/mono/legacy/OrderServiceTest.java     |  16 +--
 75 files changed, 726 insertions(+), 509 deletions(-)
```

De los 75 archivos, 39 son movimientos (la mayoría solo cambia `package` e `import`); los que cambian
de verdad son las API nuevas (`OrderService` de `orders`, `InventoryService`, `Customers`,
`Notifications`, `PaymentLookup`) y las dos entidades que dejaron de apuntar a otro módulo.

## 11. 🩺 Errores reales al correrlo

### La regla duplicada que la prueba no veía

**Síntoma.** El primer intento de mudar la devolución del stock dejó el *trigger* en la base, a
propósito, para provocar la duplicación. `cancelReturnsStock` siguió en **verde**.

**Causa.** `release` era leer-sumar-escribir: cargaba el producto, sumaba en Java y Hibernate escribía
el valor absoluto. Con `--sql`, el orden de las sentencias de la cancelación:

```text
insert into notifications (created_at,order_id,recipient,type,id) values (?,?,?,?,?)
update orders set created_at=?,currency=?,customer_id=?,status=?,total=? where id=?
update products set name=?,price=?,stock=? where sku=?
```

El `update orders` dispara el *trigger*, que suma 2 (18 → 20); inmediatamente después Hibernate
escribe `stock=?` con el 20 que calculó en Java desde el 18 que había leído, y **pisa** la suma del
*trigger*. La duplicación existía, y otro defecto —escribir un valor absoluto calculado a partir de una
lectura vieja— la tapaba.

**Lección.** `release` pasó a un incremento en la base
(`update Product p set p.stock = p.stock + :quantity`), que no pisa lo que otro escribió; con él la
prueba dio `22` y la duplicación quedó a la vista. Dos defectos que se cancelan no son un sistema
correcto: basta con arreglar uno para que aparezca el otro. El mismo patrón de leer-restar-escribir
sigue en `reserve`, y es el de la sobreventa del taller 07.

### Las claves foráneas que las bases nuevas ya no tienen

**Síntoma.** Tras cambiar `@ManyToOne` por identificadores, la base de desarrollo y una recién creada
tienen esquemas distintos:

```text
    tabla    |           conname           |                      def                       
-------------+-----------------------------+------------------------------------------------
 order_lines | fk1smc0s578t2oih21yn9hw6usr | FOREIGN KEY (order_id) REFERENCES orders(id)
 orders      | fksjfs85qf6vmcurlx43cnc16gy | FOREIGN KEY (customer_id) REFERENCES users(id)
 payments    | fk81gagumt0r8y3rmudcgpbk42l | FOREIGN KEY (order_id) REFERENCES orders(id)
(3 rows)
```

en la base que ya existía, y en una nueva (`lab.py down`, `up` y arrancar el legado):

```text
    tabla    |           conname           |                     def                      
-------------+-----------------------------+----------------------------------------------
 order_lines | fk1smc0s578t2oih21yn9hw6usr | FOREIGN KEY (order_id) REFERENCES orders(id)
(1 row)
```

**Causa.** Hibernate crea claves foráneas solo para asociaciones. Sin `@ManyToOne` no hay
asociación, y `ddl-auto: update` no crea la clave en una base nueva ni la borra en una existente.

**Lección.** Quitar una clave foránea entre módulos puede ser una decisión correcta —cada módulo dueño
de sus tablas, como en [`02/04`](../02-modularidad-y-limites-internos/04-propiedad-de-datos-en-una-base-compartida.md)—
o un error, porque se pierde una garantía de integridad que la base daba gratis. Aquí no la tomó
nadie: la tomó el ORM, y distinta en cada base. Se deja declarada y se decide con una migración en el
taller 09, que es el dueño del esquema.

## 12. 🧰 Plataformas

Los talleres son solo Java (§6 de la guía). Spring Modulith y ArchUnit son de la JVM; el contraste
de mecanismos para hacer cumplir módulos en Node/TypeScript, Go y Python —visibilidad del lenguaje,
`internal/` de Go, reglas de *linters* e importaciones— está en
[`02/06`](../02-modularidad-y-limites-internos/06-codigo-compartido-shared-kernel-y-controles-arquitectonicos.md).

## 13. 🧹 Teardown

```bash
python3 laboratorio/scripts/lab.py down
```

- Apaga PostgreSQL y Toxiproxy y borra sus volúmenes. Los contenedores de las pruebas los destruye
  Testcontainers al terminar. El legado y el `psp-simulator` se paran con Ctrl+C.

## ⚠️ Errores frecuentes

- «Una prueba arquitectónica en verde demuestra modularidad». Demuestra que las fronteras que le diste
  se respetan; sobre capas, pasa en verde con el ciclo dentro.
- «Una carpeta por dominio ya es un módulo». Sin API declarada ni prueba que lo haga cumplir, una
  carpeta es una etiqueta: el `import` al `internal` de otro compila igual.
- «Las entidades se comparten entre módulos, total están en la misma base». Una relación JPA hacia la
  tabla de otro módulo es una dependencia de datos invisible en el grafo de paquetes.
- «Mover la lógica del *trigger* a Java es copiarla». Es copiarla y retirarla en el mismo cambio; si
  no, se ejecuta dos veces.
- «Para romper un ciclo se fusionan los dos módulos». A veces; aquí bastó borrar código muerto e
  invertir una dependencia con un puerto.
- «Modularizar es el paso previo obligatorio a microservicios». Es valioso por sí mismo: cambios más
  locales y reglas verificables dentro del mismo despliegue.

## 📚 Referencias

- [Spring Modulith: Fundamentals](https://docs.spring.io/spring-modulith/reference/fundamentals.html)
- [Spring Modulith: Verifying Application Module Structure](https://docs.spring.io/spring-modulith/reference/verification.html)
- [ArchUnit User Guide](https://www.archunit.org/userguide/html/000_Index.html)
- [Spring Data JPA: Modifying Queries](https://docs.spring.io/spring-data/jpa/reference/jpa/query-methods.html#jpa.modifying-queries)

## 🧠 Preguntas

1. ¿Qué considera Spring Modulith un módulo, su API y su interior? 🟢
2. ¿Por qué `ModularityTest` pasaba en verde sobre los paquetes por capa? 🟢
3. ¿Qué causaba el ciclo `OrderService` ↔ `InventoryService` y cómo se rompió? 🟢
4. ¿Qué vigila ArchUnit en este taller que Modulith no vigila? 🟢
5. ¿Por qué `Order.customer` pasó de `@ManyToOne User` a `UUID customerId`? 🟡
6. ¿Cómo muestra `GET /orders/{id}` el último pago sin que `orders` dependa de `payments`? 🟡
7. ¿Por qué `POST /orders/{id}/payment` cambió de controlador sin cambiar de ruta? 🟡
8. ¿Qué diferencia hay entre violar `allowedDependencies` y usar un tipo interno de otro módulo? 🟡
9. ¿Por qué la primera mudanza del *trigger* no puso `cancelReturnsStock` en rojo? 🟡
10. ¿Qué garantía se perdió al quitar las asociaciones JPA entre módulos, y quién tomó esa decisión? 🟠
11. Un compañero propone `allowedDependencies = {}` vacío para todos los módulos «para que nadie dependa de nadie». ¿Qué pasa? 🟠
12. `shared` crece cada semana. ¿Qué señales te dicen que está dejando de ser un núcleo compartido? 🟠
13. Con este grafo, ¿qué módulo sacarías primero a otro proceso, cuál nunca, y qué evidencia te falta para decidirlo? 🔴

## 🧪 Ejercicios

1. 🟢 **Orientación en código ajeno.** ¿En qué archivo y línea se decide que la devolución del stock
   ya no es del *trigger*? Responde con rutas de `laboratorio/estados/06/`.
2. 🟢 Aplica el atajo de la sección 7 (el `OrderRepository` en `PaymentService`), corre `lab.py test`
   y pega la violación. Revierte.
3. 🟡 Haz que `orders` llame a `payments` —por ejemplo, un `PaymentService` inyectado en
   `OrderController`— y lee lo que dice `verify()`. ¿Es la misma violación que la del ejercicio 2?
4. 🟡 **Orientación en código ajeno.** Sigue una cancelación desde `OrderController` hasta la base y
   lista cada módulo que toca, en orden, con archivo y línea. ¿Cuántas transacciones abre?
5. 🟡 Añade a `ArchitectureTest` una regla: ninguna clase fuera de `..web..` depende de clases de
   `..web..`. ¿Pasa? Si no, ¿qué dependencia encontró y es un error?
6. 🟠 Genera con `Documenter` de Spring Modulith el diagrama de módulos y compáralo con el de la
   sección 1. ¿Qué muestra que el dibujo a mano no mostraba?
7. 🟠 Separa `products` (catálogo) de `inventory` (stock) como dos módulos sin cambiar la tabla.
   ¿Qué API necesita cada uno y qué te impide hacerlo del todo sin el taller 09?
8. 🔥 Escribe una prueba con `@ApplicationModuleTest` que arranque solo `inventory` y compruebe
   `reserve` y `release`. ¿Qué dependencias tuviste que simular y qué te dice eso de su API?

---

**Anterior:** [`05` — SQLite miente](05-sqlite-miente.md). **Siguiente:**
[`07` — Transacciones y concurrencia](07-transacciones-y-concurrencia.md).
