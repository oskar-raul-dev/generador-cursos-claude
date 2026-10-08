# 05 — SQLite miente

Este taller es **opcional**, como todo el bloque `06-talleres/`, y depende de
[`01` — Heredar el legado](01-heredar-el-legado.md); en la cadena del laboratorio parte del estado que
dejó [`04` — El contrato](04-el-contrato.md), cuya suite `hurl/v1` tiene que seguir en verde. Corre las
pruebas del legado contra SQLite y contra PostgreSQL a la vez, encuentra lo que SQLite escondía, pasa
el dinero de `double` a decimal y termina con las pruebas contra la misma base que en ejecución, en un
contenedor desechable. Termina cuando `lab.py test` corre contra PostgreSQL, `hurl/v1` sigue en verde y
puedes explicar por qué una prueba verde contra otra base **no era evidencia**.

> Ejercita [`03/01` — Transacciones locales y límites de consistencia](../03-datos-ejecucion-y-operacion/01-transacciones-locales-y-limites-de-consistencia.md)
> y [`03/07` — Estrategia de pruebas y evidencia de modularidad](../03-datos-ejecucion-y-operacion/07-estrategia-de-pruebas-y-evidencia-de-modularidad.md).
> Las reglas del bloque están en §11 y §12 de la [guía de estilo](../prompts/guia-de-estilo-y-convenciones.md).
>
> **Vigencia:** 2026-09-29. Versiones verificadas ese día en Maven Central; salidas corridas ese día
> en macOS con Docker Desktop y JDK 25.0.4.

**Salto rápido:** [1](#1--qué-enseña-este-taller) · [2](#2--prerrequisitos-y-versiones) · [3](#3-️-mapa-de-carpetas) · [4](#4--recorrido-de-la-base-de-código) · [5](#5--la-misma-base-en-un-contenedor) · [6](#6--provocación-la-misma-prueba-dos-bases) · [7](#7--el-dinero-pasa-a-decimal) · [8](#8--fuera-sqlite) · [9](#9--provocación-el-alter-que-nadie-revisó) · [10](#10--evidencia) · [11](#11--errores-reales-al-correrlo) · [12](#12--plataformas) · [13](#13--teardown) · [Preguntas](#-preguntas) · [Ejercicios](#-ejercicios)

---

## 1. 🎯 Qué enseña este taller

El legado prueba contra SQLite «porque no hace falta levantar nada». Sus dos pruebas pasan. La
pregunta de este taller es qué demostraban.

```text
                    OrderServiceTest (las mismas pruebas)
                    ├─► SQLite en un archivo     lo que había: un escritor a la vez, tipos laxos
                    └─► PostgreSQL en Testcontainers   lo que corre: concurrencia real, numeric, FK
```

Tres ideas:

- **Una prueba prueba el sistema contra el que corre.** Si la base de la prueba serializa las
  escrituras, la prueba de concurrencia no puede fallar; si no tiene decimales, la prueba de dinero
  no puede pasar. El color de la prueba depende de la base tanto como del código.
- **El dinero no cabe en un `double`.** No es un problema de SQLite: `3 × 9.90` da
  `29.700000000000003` en cualquier base. El contrato del taller 04 lo escondía al formatear; aquí se
  arregla el tipo.
- **Cambiar un tipo en una entidad cambia la base.** Con `ddl-auto: update`, Hibernate 7 altera la
  columna al arrancar y redondea los datos que había, sin que nadie lo revise. Es el anticipo del
  taller 09.

El precio: las pruebas necesitan Docker y tardan unos segundos más en arrancar. Lo que compra es que
una prueba en verde vuelve a significar algo.

## 2. 🧰 Prerrequisitos y versiones

Lo del [taller 01](01-heredar-el-legado.md#2--prerrequisitos-y-versiones). `lab.py test` necesita ahora
Docker, porque cada ejecución arranca un PostgreSQL propio. Verificado el 2026-09-29:

| Pieza | Versión | Cómo se comprobó |
|---|---|---|
| Testcontainers (`testcontainers-postgresql`, `testcontainers-junit-jupiter`) | `2.0.5`, gestionada por Boot 4.1.1 y última publicada | `spring-boot-dependencies-4.1.1.pom` y `maven-metadata.xml` de Maven Central |
| `spring-boot-testcontainers` | la de Boot 4.1.1 | `mvn dependency:list` |
| Imagen de las pruebas | `postgres:17.11-alpine`, la del compose | la misma cadena en `PostgresTestConfig` |

En Testcontainers 2 los módulos cambiaron de nombre (`testcontainers-postgresql`, antes `postgresql`)
y la clase de PostgreSQL vive en `org.testcontainers.postgresql`, sin parámetro de tipo.

## 3. 🗂️ Mapa de carpetas

```text
06-talleres/laboratorio/
├── legacy/
│   ├── pom.xml                   − sqlite-jdbc y hibernate-community-dialects; + Testcontainers
│   ├── src/main/java/dev/mono/legacy/
│   │   ├── entity/               Product, Order, OrderLine y Payment: BigDecimal (12,2)
│   │   ├── service/              OrderService, PaymentService y ReportService calculan en decimal
│   │   └── dto/Money.java        recibe BigDecimal; ya no redondea, solo normaliza la escala
│   └── src/test/
│       ├── java/dev/mono/legacy/PostgresTestConfig.java   nuevo: el contenedor y su conexión
│       ├── java/dev/mono/legacy/OrderServiceTest.java     de 2 a 6 pruebas; una, pendiente del 07
│       └── resources/application-test.yaml                ya no es SQLite
├── scripts/lab.py                test muestra el resumen; legacy acepta --sql
└── estados/05/                   el laboratorio al cerrar este taller
```

## 4. 🔎 Recorrido de la base de código

Las rutas citan `laboratorio/estados/05/`.

| Pregunta | Dónde está la respuesta |
|---|---|
| ¿Contra qué base corren las pruebas? | `legacy/src/test/java/dev/mono/legacy/OrderServiceTest.java:36`–`37`: perfil `test` e `@Import(PostgresTestConfig.class)` |
| ¿Quién decide la URL de esa base? | `legacy/src/test/java/dev/mono/legacy/PostgresTestConfig.java:12`: `@ServiceConnection` la toma del contenedor, no de `application.yaml` |
| ¿Dónde se define que el dinero tiene dos cifras? | `@Column(precision = 12, scale = 2)` en `legacy/src/main/java/dev/mono/legacy/entity/Order.java:22`, `Product.java:14`, `Payment.java:23` y `OrderLine.java:24` |
| ¿Dónde se compara con el límite del banco? | `legacy/src/main/java/dev/mono/legacy/service/PaymentService.java:49`, con `compareTo`, nunca con `equals` |
| ¿Qué prueba queda pendiente y de quién? | `OrderServiceTest.java:107`: `@Disabled`, la sobreventa, del taller 07 |
| ¿Sigue el trigger fuera del código Java? | sí: `legacy/src/main/java/dev/mono/legacy/config/SchemaFixer.java:25` lo crea si la URL es de PostgreSQL. Ahora, además, en las pruebas |

## 5. 🧱 La misma base, en un contenedor

```java
@TestConfiguration(proxyBeanMethods = false)
public class PostgresTestConfig {
    @Bean
    @ServiceConnection
    PostgreSQLContainer postgres() {
        return new PostgreSQLContainer("postgres:17.11-alpine");
    }
}
```

- `@TestConfiguration` declara beans solo para las pruebas que la importan.
- El `PostgreSQLContainer` arranca la imagen exacta del compose con un usuario y una base aleatorios, y
  se destruye al terminar la JVM de las pruebas.
- `@ServiceConnection` hace que Spring Boot construya el `DataSource` con la URL, el usuario y la
  contraseña del contenedor, en lugar de los de `application.yaml`. No hay puertos que fijar ni
  propiedades que sincronizar.
- `proxyBeanMethods = false` evita el proxy de CGLIB sobre la clase: los métodos `@Bean` no se llaman
  entre sí, así que no hace falta.

El perfil de pruebas solo dice `ddl-auto: create-drop`: el esquema nace y muere con cada contexto,
como antes con SQLite. Lo que cambia es todo lo demás: el motor, los tipos, las claves foráneas, el
*trigger* y la concurrencia.

## 6. 🧨 Provocación: la misma prueba, dos bases

Durante la transición, `OrderServiceTest` es abstracta y tiene dos subclases de una línea: una con el
perfil SQLite de siempre y otra con PostgreSQL. A las dos pruebas que el legado traía se añaden las que
un equipo escribiría si desconfiara de la base:

```java
// el total que se cobra es exacto: 3 × 9.90 son 29.70, ni un poco más
@Test
void totalIsExact() {
    var order = orders.create(ANA, List.of(new CreateOrderRequest.Line("SKU-002", 3)));
    var stored = orderRepository.findById(order.getId()).orElseThrow();
    assertEquals(29.70, stored.getTotal());
}

// veinte clientes compran a la vez el último monitor (hay 5): se venden 5, ni uno más
@Test
void concurrentOrdersNeverOversell() throws Exception { ... }
```

- `totalIsExact` lee el pedido de la base y compara el total **exacto**, sin tolerancia.
- `concurrentOrdersNeverOversell` lanza veinte hilos que esperan en un `CountDownLatch` y compran a
  la vez un `SKU-003` con stock 5; cuenta los pedidos confirmados y el stock final.

```bash
python3 laboratorio/scripts/lab.py test
```

- `test` corre `mvn test` en `legacy/` y muestra solo el resumen y los fallos. Desde este taller
  necesita Docker.

La salida, recortada a las líneas de resumen y de fallo de cada clase:

```text
[ERROR] Tests run: 4, Failures: 1, Errors: 0, Skipped: 0, Time elapsed: 3.466 s <<< FAILURE! -- in dev.mono.legacy.OrderServiceSqliteTest
[ERROR] dev.mono.legacy.OrderServiceSqliteTest.totalIsExact -- Time elapsed: 0.358 s <<< FAILURE!
org.opentest4j.AssertionFailedError: expected: <29.7> but was: <29.700000000000003>
[ERROR] Tests run: 4, Failures: 2, Errors: 0, Skipped: 0, Time elapsed: 2.667 s <<< FAILURE! -- in dev.mono.legacy.OrderServicePostgresTest
[ERROR] dev.mono.legacy.OrderServicePostgresTest.totalIsExact -- Time elapsed: 0.073 s <<< FAILURE!
org.opentest4j.AssertionFailedError: expected: <29.7> but was: <29.700000000000003>
[ERROR] dev.mono.legacy.OrderServicePostgresTest.concurrentOrdersNeverOversell -- Time elapsed: 0.070 s <<< FAILURE!
org.opentest4j.AssertionFailedError: pedidos confirmados ==> expected: <5> but was: <20>
[ERROR] Tests run: 8, Failures: 3, Errors: 0, Skipped: 0
```

Dos hallazgos distintos:

- **El `double` falla en las dos bases.** No es una mentira de SQLite: es el tipo. El total que se
  guarda y se cobra es `29.700000000000003`. El contrato del taller 04 lo mostraba como `"29.70"`, y
  la base lo tenía mal.
- **La sobreventa solo existe en PostgreSQL.** Contra SQLite la prueba está en verde: se venden 5. Contra
  PostgreSQL se venden **20** con 5 unidades. SQLite no lo evita con un bloqueo por fila: admite un solo
  escritor a la vez y el pool de las pruebas tiene una conexión, así que los veinte hilos pasan en
  fila. La prueba verde no demostraba que el legado no vendiera de más; demostraba que SQLite no deja
  intentarlo.

El segundo hallazgo es el defecto de «leer, restar, escribir» de `InventoryService.take`, y su dueño
es el taller 07. Este taller lo deja **escrito y señalado**, no arreglado.

## 7. 🧱 El dinero pasa a decimal

Las cuatro columnas de dinero pasan a `BigDecimal` con precisión y escala declaradas:

```java
@Column(precision = 12, scale = 2)          // taller 05: decimal con dos cifras, nunca double
private BigDecimal total;
```

- `precision = 12, scale = 2` genera `numeric(12,2)` en PostgreSQL: hasta diez cifras enteras y dos
  decimales, guardados exactamente.
- El cálculo en `OrderService` suma con `add` y `multiply`; `PaymentService` compara con
  `compareTo(new BigDecimal("1000.00"))`, porque `equals` en `BigDecimal` distingue `1000.0` de
  `1000.00`.
- `Money.of` ya no redondea: `setScale(2, RoundingMode.UNNECESSARY)` solo normaliza la escala y
  lanzaría una excepción si un valor tuviera más de dos decimales, que ahora sería un error.

La prueba cambia de tipo con el dominio: `assertEquals(new BigDecimal("29.70"), stored.getTotal())`.
Las mismas dos bases, con el mismo recorte:

```text
[ERROR] Tests run: 4, Failures: 2, Errors: 0, Skipped: 0, Time elapsed: 3.581 s <<< FAILURE! -- in dev.mono.legacy.OrderServiceSqliteTest
[ERROR] dev.mono.legacy.OrderServiceSqliteTest.totalIsExact -- Time elapsed: 0.407 s <<< FAILURE!
org.opentest4j.AssertionFailedError: expected: <29.70> but was: <29.7>
[ERROR] dev.mono.legacy.OrderServiceSqliteTest.createOrderTakesStock -- Time elapsed: 0.012 s <<< FAILURE!
org.opentest4j.AssertionFailedError: expected: <99.80> but was: <99.8>
[ERROR] Tests run: 4, Failures: 1, Errors: 0, Skipped: 0, Time elapsed: 2.639 s <<< FAILURE! -- in dev.mono.legacy.OrderServicePostgresTest
[ERROR] dev.mono.legacy.OrderServicePostgresTest.concurrentOrdersNeverOversell -- Time elapsed: 0.041 s <<< FAILURE!
org.opentest4j.AssertionFailedError: pedidos confirmados ==> expected: <5> but was: <20>
[ERROR] Tests run: 8, Failures: 3, Errors: 0, Skipped: 0
```

En PostgreSQL, `totalIsExact` pasa a verde: es la misma prueba, en rojo antes de la corrección y en
verde después. En SQLite pasa lo contrario de lo que se esperaría: **ahora falla una prueba que antes
pasaba**. SQLite no tiene tipo decimal; guarda `29.70` como número real y lo devuelve como `29.7`, con
otra escala. Incluso `createOrderTakesStock` cae, porque el precio `49.90` vuelve de SQLite como `49.9`
y `49.9 × 2` es `99.8`. Con SQLite, un dominio con dinero exacto no se puede probar.

## 8. 🔀 Fuera SQLite

Con esa evidencia, SQLite sale: se borran las dos subclases y el perfil `postgres`, `OrderServiceTest`
vuelve a ser concreta con `@Import(PostgresTestConfig.class)`, `application-test.yaml` deja de
apuntar a un archivo y el `pom.xml` pierde `sqlite-jdbc` y el dialecto comunitario. Dos cambios más en
las pruebas:

- **`cancelReturnsStock`, nueva.** Con SQLite no se podía escribir: el stock de un pedido cancelado lo
  devuelve un *trigger* de PostgreSQL que `SchemaFixer` no creaba fuera de PostgreSQL. El taller 06
  moverá esa lógica a Java, y esta prueba es la que dirá si la mudanza conservó el comportamiento.
- **`concurrentOrdersNeverOversell`, `@Disabled` con motivo.** Está en rojo por un defecto real cuyo
  dueño es el taller 07. Se deja escrita y desactivada con el motivo en la anotación, en lugar de
  borrarla o de arreglar el stock aquí.

```bash
python3 laboratorio/scripts/lab.py test
```

```text
$ mvn test   (se muestran solo el resumen y los fallos)
Running dev.mono.legacy.OrderServiceTest
[WARNING] Tests run: 5, Failures: 0, Errors: 0, Skipped: 1, Time elapsed: 4.993 s -- in dev.mono.legacy.OrderServiceTest
Tests run: 5, Failures: 0, Errors: 0, Skipped: 1
BUILD SUCCESS
```

Cinco pruebas, una saltada a propósito y visible en cada corrida. Un `Skipped: 1` que nadie mira es
una deuda escondida; uno con el taller dueño en el motivo es una deuda con fecha.

## 9. 🧨 Provocación: el `ALTER` que nadie revisó

La base de desarrollo tiene sus columnas de dinero en `double precision`: las creó el legado del taller
04. Para verlo desde el principio, una base limpia con el legado de ese estado, un pedido de tres
cables y la fila tal cual quedó:

```bash
python3 laboratorio/scripts/lab.py down && python3 laboratorio/scripts/lab.py up
python3 laboratorio/scripts/lab.py --estado 04 legacy --daily-close-ms 600000    # en otra terminal
python3 laboratorio/scripts/lab.py seed
python3 laboratorio/scripts/lab.py api POST /api/v1/orders '{"lines":[{"sku":"SKU-002","quantity":3}]}'
python3 laboratorio/scripts/lab.py sql "SELECT total, total::text AS exact FROM orders"
```

- `down` y `up` recrean PostgreSQL sin volúmenes: la base está vacía y el legado del estado 04 crea
  las tablas con sus tipos.
- `api POST` crea el pedido como `ana`; `sql` lee la columna tal cual y convertida a texto.

```text
       total        |       exact        
--------------------+--------------------
 29.700000000000003 | 29.700000000000003
(1 row)
```

La API respondió `"amount": "29.70"`; la base guarda otra cosa. Ahora se para ese legado y se arranca
el de este taller, con el registro de SQL:

```bash
python3 laboratorio/scripts/lab.py legacy --daily-close-ms 600000 --sql    # en otra terminal, tras parar el anterior
```

- `--sql` pasa `--logging.level.org.hibernate.SQL=debug`: Hibernate registra cada sentencia, DDL
  incluido.

```text
alter table if exists order_lines alter column unit_price set data type numeric(12,2)
alter table if exists orders alter column total set data type numeric(12,2)
alter table if exists payments alter column amount set data type numeric(12,2)
alter table if exists products alter column price set data type numeric(12,2)
```

```text
 total | exact 
-------+-------
 29.70 | 29.70
(1 row)
```

Hibernate comparó las entidades con el catálogo, vio tipos distintos y los cambió al arrancar.
PostgreSQL convirtió cada valor a `numeric(12,2)` redondeando: el `29.700000000000003` es ahora
`29.70`. Aquí el redondeo es inocuo; pero nadie lo revisó, nadie lo aprobó y no hay forma de
deshacerlo, y en una tabla grande ese `ALTER` reescribe la tabla entera con un bloqueo exclusivo
mientras la aplicación arranca. Es el pecado de `ddl-auto: update`, y su dueño es el taller 09.

## 10. 🧪 Evidencia

`hurl/v1`, la invariante, sigue en verde con el dinero decimal:

```bash
python3 laboratorio/scripts/lab.py suite
```

```text
Success 01-health.hurl (1 request(s) in 3 ms)
Success 02-auth.hurl (9 request(s) in 556 ms)
Success 03-products.hurl (12 request(s) in 264 ms)
Success 04-orders.hurl (18 request(s) in 310 ms)
Success 05-payment.hurl (12 request(s) in 2205 ms)
Success 06-cancel.hurl (19 request(s) in 266 ms)
Success 07-notifications.hurl (9 request(s) in 1714 ms)
Success 08-reports.hurl (5 request(s) in 186 ms)
--------------------------------------------------------------------------------
Executed files:    8
Executed requests: 85 (15.4/s)
Succeeded files:   8 (100.0%)
Failed files:      0 (0.0%)
Duration:          5517 ms (0h:0m:5s:517ms)
```

El contrato no cambió: `amount` ya era texto con dos cifras. Es exactamente lo que el taller 04 quería
comprar: cambiar el tipo por dentro sin que ningún cliente lo note.

```bash
git diff --no-index --stat laboratorio/estados/04/legacy/src laboratorio/estados/05/legacy/src
```

- Compara solo `src/`: fuera quedan el `pom.xml` (11 líneas añadidas y 6 quitadas) y la carpeta
  `target/` que deja `lab.py --estado 04 legacy` dentro del estado, ignorada por git.

```text
 .../mono/legacy/controller/ProductController.java  |  3 +-
 .../src/main/java/dev/mono/legacy/dto/Money.java   |  8 +-
 .../main/java/dev/mono/legacy/dto/OrderView.java   |  3 +-
 .../main/java/dev/mono/legacy/entity/Order.java    |  8 +-
 .../java/dev/mono/legacy/entity/OrderLine.java     | 10 ++-
 .../main/java/dev/mono/legacy/entity/Payment.java  |  8 +-
 .../main/java/dev/mono/legacy/entity/Product.java  |  9 ++-
 .../java/dev/mono/legacy/service/OrderService.java |  5 +-
 .../dev/mono/legacy/service/PaymentService.java    |  6 +-
 .../dev/mono/legacy/service/ReportService.java     | 11 ++-
 .../java/dev/mono/legacy/OrderServiceTest.java     | 85 ++++++++++++++++++++--
 .../java/dev/mono/legacy/PostgresTestConfig.java   | 16 ++++
 .../src/test/resources/application-test.yaml       | 13 +---
 13 files changed, 144 insertions(+), 41 deletions(-)
```

## 11. 🩺 Errores reales al correrlo

### `ddl-auto: update` sí cambió el tipo

**Síntoma.** El plan del taller suponía que `update` no altera columnas existentes y que habría que
recrear la base para ver `numeric`. Tras arrancar el legado con `BigDecimal`, `information_schema`
ya decía `numeric(12,2)`.

**Causa.** Hibernate 7.4.5 compara el tipo de cada columna con el de la entidad y emite `ALTER COLUMN
... SET DATA TYPE` cuando difieren (sección 9). La suposición se escribió de memoria y no se había
comprobado con esta versión.

**Lección.** Lo que hace la herramienta de esquema depende de su versión, y hay que verlo con el
registro de SQL, no recordarlo. El cambio convirtió un pecado conocido —el esquema implícito— en uno
peor: migraciones de datos que corren solas al arrancar.

### SQLite pierde la escala también al leer

**Síntoma.** Con dinero decimal, `createOrderTakesStock` cayó en SQLite con `expected: <99.80> but
was: <99.8>`, aunque el total se calcula en memoria.

**Causa.** El total sale de multiplicar el precio **leído de la base**, y SQLite devuelve `49.90` como
`49.9`: su afinidad `NUMERIC` guarda un real, no un decimal con escala.

**Lección.** No bastaba con comparar con `compareTo` en la prueba: el valor con otra escala viajaría
igual al proveedor de pago o a un informe. La base de las pruebas tiene que poder representar el
dominio.

### Lo que la corrida exploratoria encontró además

Antes de escribir las pruebas del taller se corrieron cinco experimentos contra las dos bases. Son el
ejercicio 4; estas son las líneas literales de la corrida, primero contra SQLite (los cinco en verde):

```text
E3 created_at stored as: 1790716718851 / java 2026-09-29T21:18:38.851026Z
E3 reloaded equals? false
E5 findById sku-003 present? false
E5 LIKE MONITOR count=1
[INFO] Tests run: 5, Failures: 0, Errors: 0, Skipped: 0, Time elapsed: 3.729 s -- in dev.mono.legacy.exp.SqliteExp
```

y contra PostgreSQL:

```text
E3 created_at stored as: 2026-09-29 16:18:42.024156-05 / java 2026-09-29T21:18:42.024156Z
E3 reloaded equals? true
E5 findById sku-003 present? false
E5 LIKE MONITOR count=0
[ERROR] Tests run: 5, Failures: 1, Errors: 2, Skipped: 0, Time elapsed: 2.970 s <<< FAILURE! -- in dev.mono.legacy.exp.PgExp
Caused by: org.postgresql.util.PSQLException: ERROR: value too long for type character varying(255)
Caused by: org.postgresql.util.PSQLException: ERROR: insert or update on table "orders" violates foreign key constraint "fksjfs85qf6vmcurlx43cnc16gy"
```

SQLite guarda un `Instant` como milisegundos (pierde los microsegundos), hace `LIKE` sin distinguir
mayúsculas, acepta 300 caracteres en un `varchar(255)` y un pedido de un cliente que no existe (no
aplica claves foráneas salvo que se active `PRAGMA foreign_keys`). Ninguna de esas diferencias rompía
una prueba del legado, porque ninguna prueba del legado las tocaba.

## 12. 🧰 Plataformas

Los talleres son solo Java (§6 de la guía). Testcontainers tiene equivalentes en Node, Go y Python con
la misma idea, y cada plataforma tiene su tipo decimal (`BigDecimal`, `decimal.Decimal`, bibliotecas en
Node y Go, donde el lenguaje no lo trae). El contraste de estrategias de prueba por plataforma está en
[`03/07`](../03-datos-ejecucion-y-operacion/07-estrategia-de-pruebas-y-evidencia-de-modularidad.md).

## 13. 🧹 Teardown

```bash
python3 laboratorio/scripts/lab.py down
```

- Apaga PostgreSQL y Toxiproxy y borra sus volúmenes. Los contenedores de las pruebas no hace falta
  apagarlos: Testcontainers los destruye al terminar cada ejecución (lo vigila su contenedor
  auxiliar, Ryuk). El legado y el `psp-simulator` se paran con Ctrl+C.

## ⚠️ Errores frecuentes

- «SQLite en memoria es suficiente para probar la capa de datos». Prueba otra base: sin concurrencia
  real, sin decimales y sin claves foráneas por defecto.
- «La prueba de concurrencia pasa, así que no hay sobreventa». Pasa si la base serializa; hay que
  correrla donde la concurrencia existe.
- «Con `BigDecimal` basta». Hace falta la escala declarada en la columna y comparar con `compareTo`;
  `equals` distingue `99.8` de `99.80`.
- «El contrato mostraba `29.70`, así que el dato estaba bien». El contrato formateaba; la base guardaba
  `29.700000000000003`.
- «Una prueba en rojo se borra o se arregla en el mismo cambio». Si su causa tiene otro dueño, se deja
  escrita, desactivada y con el motivo; borrarla pierde la evidencia.
- «`ddl-auto: update` solo añade columnas». Hibernate 7 también cambia tipos y, con ellos, los datos.

## 📚 Referencias

- [Testcontainers: módulo de PostgreSQL](https://java.testcontainers.org/modules/databases/postgres/)
- [Spring Boot: Testcontainers y `@ServiceConnection`](https://docs.spring.io/spring-boot/reference/testing/testcontainers.html)
- [SQLite: Datatypes In SQLite (afinidad de tipos)](https://www.sqlite.org/datatype3.html)
- [SQLite: Foreign Key Support](https://www.sqlite.org/foreignkeys.html)
- [PostgreSQL 17: Numeric Types](https://www.postgresql.org/docs/17/datatype-numeric.html)
- [PostgreSQL 17: ALTER TABLE](https://www.postgresql.org/docs/17/sql-altertable.html)

## 🧠 Preguntas

1. ¿Qué hace `@ServiceConnection` y qué evita configurar a mano? 🟢
2. ¿Por qué `3 × 9.90` no da `29.70` con `double`, y por qué no es un problema de la base? 🟢
3. ¿Por qué la prueba de sobreventa pasaba contra SQLite? 🟢
4. ¿Qué significan `precision = 12` y `scale = 2`? 🟢
5. ¿Por qué se compara con el límite del banco con `compareTo` y no con `equals`? 🟡
6. `totalIsExact` pasó a verde en PostgreSQL y a rojo en SQLite con el mismo cambio. ¿Qué dice eso de SQLite? 🟡
7. ¿Por qué `concurrentOrdersNeverOversell` queda `@Disabled` en lugar de borrada o arreglada? 🟡
8. ¿Por qué `cancelReturnsStock` no se podía escribir antes de este taller? 🟡
9. El contrato del taller 04 ya mostraba `"29.70"`. ¿Qué arregla este taller que el contrato no arreglaba? 🟡
10. ¿Qué hizo Hibernate al arrancar sobre una base con columnas `double precision`, y qué riesgo tiene? 🟠
11. Tu equipo dice que Testcontainers hace las pruebas lentas y quiere volver a H2 «en modo PostgreSQL». ¿Qué respondes? 🟠
12. Una prueba de integración pasa en tu máquina y falla en CI con la misma imagen. ¿Qué sospechas y cómo lo investigas? 🟠
13. ¿Qué otras diferencias entre la base de prueba y la de producción pueden quedar aunque sea la misma imagen? 🔴

## 🧪 Ejercicios

1. 🟢 **Orientación en código ajeno.** ¿En qué archivo y línea se decide la URL de la base de las
   pruebas, y por qué no es la de `application.yaml`? Responde con rutas de `laboratorio/estados/05/`.
2. 🟢 Quita el `@Disabled` de `concurrentOrdersNeverOversell`, corre `lab.py test` tres veces y anota
   cuántos pedidos se confirman en cada corrida. ¿Es siempre 20? ¿Por qué?
3. 🟡 Escribe `productPriceKeepsScale`: crea un producto a `35.00` por la API y compruébalo en la base
   con `lab.py sql`. Explica qué habría devuelto SQLite.
4. 🟡 Escribe los cinco experimentos de la sección 11 como pruebas de una clase abstracta con dos
   subclases, una por base. ¿Cuáles pasan en SQLite y fallan en PostgreSQL, y cuáles al revés?
5. 🟡 **Orientación en código ajeno.** Encuentra todos los sitios donde el legado convierte dinero a
   texto. ¿Por qué `PaymentService` usa `setScale(2)` sin modo de redondeo y `Money` usa
   `RoundingMode.UNNECESSARY`?
6. 🟠 Provoca un `ALTER` que falle: con el legado del estado 04, crea un producto con un precio de
   `12345678901.50` y arranca el de este taller. ¿Qué pasa con el arranque y qué harías en producción?
7. 🟠 Haz que las pruebas reutilicen un único contenedor para todas las clases de prueba y mide la
   diferencia de tiempo. ¿Qué aislamiento pierdes y cómo lo compensas?
8. 🔥 Activa `PRAGMA foreign_keys = ON` en SQLite y repite la corrida exploratoria. ¿Cuántas
   diferencias quedan, y alcanzan para defender SQLite como base de prueba?

---

**Anterior:** [`04` — El contrato](04-el-contrato.md). **Siguiente:** [`06` — Modularizar](06-modularizar.md).
