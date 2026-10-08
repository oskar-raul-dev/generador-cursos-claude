# 09 — Migraciones de esquema

Este taller es **opcional**, como todo el bloque `06-talleres/`, y depende de
[`06` — Modularizar](06-modularizar.md), que decidió que el stock es de `inventory`; en la cadena del
laboratorio parte del estado que dejó [`08` — Eventos, jobs y dos instancias](08-eventos-jobs-y-dos-instancias.md),
cuyas dos instancias usa. Sustituye `ddl-auto: update` por migraciones de Flyway sobre una base que ya
existe, hace converger las bases viejas con las nuevas y separa el stock de `products` en su propia
tabla `inventory` con *expand/contract*, **con dos instancias de versiones distintas vivas en cada
paso**. Termina cuando `hurl/v1` ha pasado contra las dos instancias en los siete pasos y puedes decir
en qué momento deja de ser posible volver atrás.

> Ejercita [`02/04` — Propiedad de datos en una base compartida](../02-modularidad-y-limites-internos/04-propiedad-de-datos-en-una-base-compartida.md)
> y [`03/05` — Despliegues, migraciones de esquema y rollback](../03-datos-ejecucion-y-operacion/05-despliegues-migraciones-de-esquema-y-rollback.md).
> Las reglas del bloque están en §11 y §12 de la [guía de estilo](../prompts/guia-de-estilo-y-convenciones.md).
>
> **Vigencia:** 2026-09-29. Versiones verificadas ese día en Maven Central; salidas corridas ese día
> en macOS con Docker Desktop, JDK 25.0.4 y `hurl` 8.0.1.

**Salto rápido:** [1](#1--qué-enseña-este-taller) · [2](#2--prerrequisitos-y-versiones) · [3](#3-️-mapa-de-carpetas) · [4](#4--recorrido-de-la-base-de-código) · [5](#5--provocación-todas-las-migraciones-de-golpe) · [6](#6--la-línea-base) · [7](#7--converger-las-bases-viejas) · [8](#8--expandcontract-en-siete-pasos) · [9](#9--el-punto-sin-retorno) · [10](#10--evidencia) · [11](#11--errores-reales-al-correrlo) · [12](#12--plataformas) · [13](#13--teardown) · [Preguntas](#-preguntas) · [Ejercicios](#-ejercicios)

---

## 1. 🎯 Qué enseña este taller

Hasta aquí el esquema de `mono-legacy` era un efecto secundario: lo que Hibernate dedujera de las
entidades al arrancar, más dos componentes que ejecutaban SQL por su cuenta (`SchemaFixer`,
`LeaseSchema`). El taller 05 vio a Hibernate cambiar un tipo de columna sin avisar; el 06, dos bases
con claves foráneas distintas. Este taller convierte el esquema en código versionado y lo cambia sin
parar el servicio.

```text
                expand                              switch                       contract
schema   V1 base ─ V2 converger ─ V3 inventory ─── V4 re-sincronizar ─────────────── V5 borrar products.stock
app      estado 08 ─┐                                                             (sin vuelta atrás)
                    └ expand: lee products, escribe las dos
                             └ switch: lee inventory, escribe las dos
                                      └ contract: lee y escribe inventory
cada versión convive con la anterior; cada migración es compatible con las dos versiones vivas
```

Tres ideas:

- **Una base que existe no se crea: se reconoce.** Flyway no puede ejecutar la migración inicial
  sobre una base con tablas; la marca como aplicada (*baseline*) y empieza en la siguiente. Lo que las
  bases viejas tengan de más hay que hacerlo converger con una migración explícita.
- **Durante un despliegue conviven dos versiones.** Una migración que la versión nueva necesita no
  puede romper a la vieja. Por eso el cambio se parte: primero se añade (*expand*), después se usa
  (*switch*) y al final se retira lo viejo (*contract*).
- **El *rollback* es de la aplicación, no del esquema.** Mientras la versión anterior siga funcionando
  sobre el esquema nuevo, volver atrás es desplegar el jar anterior. El último paso, el que borra, es
  el único sin vuelta atrás, y por eso va solo.

El precio: cinco migraciones, tres versiones de la aplicación para un cambio que «era una columna», y
un periodo en que el stock se escribe en dos sitios. Lo que compra es no parar el servicio y poder
volver atrás en seis de los siete pasos.

## 2. 🧰 Prerrequisitos y versiones

Lo de los talleres anteriores. Verificado el 2026-09-29:

| Pieza | Versión | Cómo se comprobó |
|---|---|---|
| `spring-boot-starter-flyway` | la de Boot 4.1.1 | `maven-metadata.xml` y el `pom` 4.1.1 en Maven Central |
| Flyway (`flyway-core`, `flyway-database-postgresql`) | `12.4.0`, gestionada por Boot 4.1.1 (la última publicada es `13.8.1`) | `spring-boot-dependencies-4.1.1.pom`; el arranque informa `PostgreSQL 17.11` |

Se usa la versión que gestiona Boot, con el mismo criterio que Testcontainers y Spring Modulith:
mezclar una versión más nueva exige comprobar que la autoconfiguración de Boot la entiende, y no es el
tema del taller. Desde PostgreSQL, Flyway necesita el módulo `flyway-database-postgresql`.

Órdenes nuevas o ampliadas de `lab.py`:

| Orden | Qué hace |
|---|---|
| `lab.py legacy --inventory-step expand\|switch\|contract\|done` | arranca la versión de ese paso: fija `legacy.inventory.step` y las carpetas de migraciones de Flyway |
| `lab.py legacy --set clave=valor` | cualquier propiedad de Spring para ese arranque |
| `lab.py storm orders --ports 38081,38083` | reparte la tormenta de pedidos entre instancias |

## 3. 🗂️ Mapa de carpetas

```text
06-talleres/laboratorio/
├── contrato/seed/seed.sql        vale para cualquier paso: products.stock si existe, inventory si existe
├── legacy/src/main/resources/
│   ├── application.yaml          ddl-auto: validate; flyway con baseline; legacy.inventory.step
│   └── db/
│       ├── migration/            V1 baseline · V2 converger · V3 expand (inventory)
│       ├── switch/               V4 re-sincronizar inventory
│       └── contract/             V5 borrar products.stock
├── legacy/src/main/java/dev/mono/legacy/inventory/internal/
│   ├── StockStore.java           nuevo: dónde se lee y escribe el stock en cada paso
│   ├── Product.java              sin stock
│   └── SchemaFixer.java          borrado (su DROP pasó a V2); también reports/internal/LeaseSchema.java
├── legacy/src/test/resources/application-test.yaml   las pruebas usan las mismas migraciones
└── estados/09/
```

## 4. 🔎 Recorrido de la base de código

Las rutas citan `laboratorio/estados/09/legacy/src/main/`.

| Pregunta | Dónde está la respuesta |
|---|---|
| ¿Quién crea hoy el esquema? | Flyway con `resources/db/**`; Hibernate solo lo valida (`resources/application.yaml:24`) |
| ¿Qué pasa con una base que ya tenía tablas? | `application.yaml:27`–`28`: se marca en V1 (*baseline*) y se sigue desde V2 |
| ¿Qué migraciones ve cada versión? | `application.yaml:30` en la final; cada paso añade una carpeta (`lab.py legacy --inventory-step`) |
| ¿En qué paso está esta versión y qué lee? | `resources/application.yaml:42` y `java/dev/mono/legacy/inventory/internal/StockStore.java:25` |
| ¿Por qué se bloquean las dos filas mientras se escriben las dos tablas? | `StockStore.java:37`–`40`: siempre `products` y después `inventory` (sección 11) |
| ¿Dónde quedó el `DROP` del *trigger* que hacía `SchemaFixer`? | `resources/db/migration/V2__converge_legacy_databases.sql` |

## 5. 🧨 Provocación: todas las migraciones de golpe

El despliegue que se escribe primero: la versión nueva trae sus migraciones, se arranca y Flyway las
aplica todas. En una base que viene del taller 08 —con la instancia de esa versión todavía viva en
`:38081`— se arranca la nueva en `:38083`:

```bash
python3 laboratorio/scripts/lab.py --estado 08 legacy --daily-close-ms 600000                      # terminal 1
python3 laboratorio/scripts/lab.py legacy --port 38083 --daily-close-ms 600000 --inventory-step done   # terminal 2
```

- `--estado 08` arranca la versión anterior tal como quedó; es la que sigue sirviendo mientras se
  despliega la nueva.
- `--inventory-step done` es la versión final con **todas** sus migraciones, incluida la que borra la
  columna.

```text
o.f.core.internal.command.DbBaseline     : Successfully baselined schema with version: 1
o.f.core.internal.command.DbMigrate      : Migrating schema "public" to version "2 - converge legacy databases"
o.f.core.internal.command.DbMigrate      : Migrating schema "public" to version "3 - expand inventory"
o.f.core.internal.command.DbMigrate      : Migrating schema "public" to version "4 - resync inventory"
o.f.core.internal.command.DbMigrate      : Migrating schema "public" to version "5 - drop products stock"
o.f.core.internal.command.DbMigrate      : Successfully applied 4 migrations to schema "public", now at version v5 (execution time 00:00.029s)
```

`hurl/v1` contra cada instancia (sin sembrar entre medias):

```text
Success 01-health.hurl (1 request(s) in 4 ms)
Failure 02-auth.hurl (6 request(s) in 426 ms)
Failure 03-products.hurl (3 request(s) in 167 ms)
...
Failure 09-idempotency.hurl (2 request(s) in 87 ms)
Succeeded files:   1 (11.1%)
```

```text
Success 09-idempotency.hurl (13 request(s) in 159 ms)
Succeeded files:   9 (100.0%)
```

La versión nueva, perfecta; la vieja, rota en ocho de nueve archivos, con `column p1_0.stock does not
exist` en el log. Durante un despliegue gradual, la mitad del tráfico falla hasta que termina. La
migración era correcta; lo incorrecto era aplicarla toda mientras la versión anterior seguía viva.

## 6. 🧱 La línea base

`V1__baseline.sql` es el esquema que el legado del estado 08 dejaba en una base **nueva**, volcado con
`pg_dump --schema-only` y limpiado. En una base nueva, Flyway lo ejecuta. En una que ya existe, no
puede:

```bash
python3 laboratorio/scripts/lab.py legacy --port 38083 --inventory-step expand --set spring.flyway.baseline-on-migrate=false
```

- `--set` pasa una propiedad a este arranque; aquí, desactivar la línea base para ver qué pasa sin ella.

```text
Found non-empty schema(s) "public" but no schema history table. Use baseline() or set baselineOnMigrate to true to initialize the schema history table.
```

La aplicación no arranca. Con `baseline-on-migrate: true` y `baseline-version: 1`, Flyway crea su
tabla `flyway_schema_history`, anota V1 como aplicada **sin ejecutarla** y sigue:

```text
 version |        description        |   type   
---------+---------------------------+----------
 1       | << Flyway Baseline >>     | BASELINE
 2       | converge legacy databases | SQL
 3       | expand inventory          | SQL
(3 rows)
```

La línea base es una afirmación: «esta base ya es V1». Si no lo es —si le faltan tablas o le sobran
restricciones—, Flyway no lo comprueba. Eso lo hace V2.

## 7. 🔀 Converger las bases viejas

Una base que pasó por los talleres 01 a 08 no es igual que una nueva del estado 08: conserva las
claves foráneas que Hibernate creó para los `@ManyToOne` antes del taller 06. Antes de migrar, en la
base de desarrollo:

```text
-------------+-----------------------------
 order_lines | fk1smc0s578t2oih21yn9hw6usr
 orders      | fksjfs85qf6vmcurlx43cnc16gy
 payments    | fk81gagumt0r8y3rmudcgpbk42l
(3 rows)
```

`V2__converge_legacy_databases.sql` toma la decisión que el taller 06 dejó pendiente:

```sql
ALTER TABLE orders DROP CONSTRAINT IF EXISTS fksjfs85qf6vmcurlx43cnc16gy;     -- orders.customer_id → users
ALTER TABLE payments DROP CONSTRAINT IF EXISTS fk81gagumt0r8y3rmudcgpbk42l;   -- payments.order_id → orders
DROP TRIGGER IF EXISTS orders_restore_stock ON orders;                        -- lo retiraba SchemaFixer
DROP FUNCTION IF EXISTS restore_stock_on_cancel();
```

- Las dos claves que cruzan módulos se retiran: cada módulo es dueño de sus tablas y la integridad
  entre módulos la garantiza la aplicación
  ([`02/04`](../02-modularidad-y-limites-internos/04-propiedad-de-datos-en-una-base-compartida.md)).
  La de `order_lines → orders`, dentro de `orders`, se queda.
- `IF EXISTS` hace la migración inocua en una base nueva: el mismo script lleva a las dos al mismo
  sitio.
- El `DROP` del *trigger* era lo que hacía `SchemaFixer` en cada arranque; pasa a ejecutarse una vez,
  con registro.

Después de V2 y V3, las claves foráneas de la base de desarrollo son las de una nueva, más la de la
tabla nueva:

```text
-------------+-----------------------------
 order_lines | fk1smc0s578t2oih21yn9hw6usr
 inventory   | inventory_sku_fkey
(2 rows)
```

## 8. 🔁 Expand/contract en siete pasos

El stock sale de `products` hacia `inventory` (la tabla que el taller 06 anticipó). La aplicación
elige dónde leer y escribir según `legacy.inventory.step`, y cada paso es una versión que se despliega
**con la anterior todavía viva**:

| Paso | Instancia A (`:38081`) | Instancia B (`:38083`) | Migración que entra |
|---|---|---|---|
| 1 | estado 08 (lee y escribe `products.stock`) | `expand` | V2, V3: `inventory` creada y rellenada |
| 2 | `expand` | `expand` | — |
| 3 | `expand` | `switch` (lee `inventory`, escribe las dos) | V4: re-sincronizar |
| 4 | `switch` | `switch` | — |
| 5 | `switch` | `contract` (solo `inventory`) | — |
| 6 | `contract` | `contract` | — |
| 7 | `contract` | `done` | V5: borrar `products.stock` |

```bash
python3 laboratorio/scripts/lab.py legacy --inventory-step expand --daily-close-ms 600000
python3 laboratorio/scripts/lab.py legacy --port 38083 --inventory-step switch --daily-close-ms 600000
python3 laboratorio/scripts/lab.py suite --base-url http://localhost:38081
python3 laboratorio/scripts/lab.py suite --base-url http://localhost:38083
```

- `--inventory-step` fija el paso y las carpetas de Flyway: `expand` ve `db/migration`; `switch` y
  `contract` añaden `db/switch`; `done` añade `db/contract`. Así la migración que borra no puede
  llegar con una versión que todavía convive con otra que lee la columna.
- Cada fila de la tabla es un par de arranques como estos y las dos suites.

En los siete pasos, y en el *rollback* de la sección siguiente, las dos suites terminaron con
`Succeeded files:   9 (100.0%)`: 16 corridas de `hurl/v1`, ninguna en rojo. Es la evidencia que pedía
la ficha: el contrato se mantiene en cada paso, con dos versiones mezcladas.

**La deriva del paso 1.** Mientras vive la versión del estado 08, solo ella escribe `products.stock`:
`inventory` se queda atrás. Tras una corrida de la suite contra A:

```text
   sku   | products_stock | inventory_stock 
---------+----------------+-----------------
 SKU-001 |             18 |              20
 SKU-002 |             94 |             100
 SKU-003 |              2 |               5
 SKU-005 |              2 |               3
(4 rows)
```

No es un problema todavía: `expand` lee de `products`, que es la verdad. Lo sería si alguien leyera
`inventory` antes de corregirlo. Por eso V4 va en la carpeta de `switch`, la primera versión que lee
`inventory`, y solo se despliega cuando ya no queda ninguna instancia del estado 08. Contando filas
sin `inventory` (creadas por la versión vieja) y stocks distintos, antes y después de V4:

```text
                     2 |              4
Migrating schema "public" to version "4 - resync inventory"
Successfully applied 1 migration to schema "public", now at version v4 (execution time 00:00.012s)
                     0 |              0
```

**La concurrencia entre versiones.** En los pasos en que conviven dos versiones que escriben las dos
tablas, las dos bloquean las dos filas, siempre en el mismo orden (`products` y después `inventory`).
La tormenta de pedidos repartida entre `expand` y `switch`:

```bash
python3 laboratorio/scripts/lab.py storm orders --n 20 --ports 38081,38083
```

```text
stock de SKU-003 antes: 5
20 pedidos concurrentes de 1 × SKU-003: HTTP 201 × 5, HTTP 409 × 15
stock de SKU-003 después: 0
```

La sección 11 cuenta qué pasó con una versión que bloqueaba solo la tabla que leía.

## 9. 🧨 El punto sin retorno

**Hasta el paso 6, volver atrás es desplegar el jar anterior.** En el paso 3, con el esquema en V4, B
vuelve a `expand` y las dos suites siguen en verde: `expand` escribe las dos tablas, así que no pierde
nada, y Flyway arranca aunque V4 no esté entre las migraciones de esa versión.

**Después de V5, no.** Con la columna borrada, una versión `switch` arranca igual. En su log:

```text
o.f.core.internal.command.DbMigrate      : Schema "public" has a version (5) that is newer than the latest available migration (4) !
o.f.core.internal.command.DbMigrate      : Schema "public" is up to date. No migration necessary.
```

Flyway **tolera** un esquema más nuevo que la versión: avisa y arranca. Hibernate valida, porque
`Product` ya no mapea `stock`. Y el primer pedido:

```text
HTTP 500 · application/problem+json · 151 ms
  "code": "INTERNAL_ERROR"
column "stock" does not exist
```

La tolerancia que permitía volver atrás en el paso 3 es la que deja arrancar aquí una versión
incompatible. Por eso V5 va sola, al final, cuando todas las instancias llevan un paso completo en
`contract` y nadie planea volver a `switch`. Si hiciera falta, el camino no es un `DOWN` que recree la
columna vacía: es otra migración hacia delante que la recrea y la rellena desde `inventory`.

## 10. 🧪 Evidencia

Una base nueva recibe las cinco migraciones al primer arranque:

```text
Migrating schema "public" to version "1 - baseline"
Migrating schema "public" to version "2 - converge legacy databases"
Migrating schema "public" to version "3 - expand inventory"
Migrating schema "public" to version "4 - resync inventory"
Migrating schema "public" to version "5 - drop products stock"
Successfully applied 5 migrations to schema "public", now at version v5 (execution time 00:00.052s)
```

Y sobre ella, con la versión final:

```bash
python3 laboratorio/scripts/lab.py test
python3 laboratorio/scripts/lab.py suite
python3 laboratorio/scripts/lab.py storm orders --n 20
```

```text
Tests run: 8, Failures: 0, Errors: 0, Skipped: 0
BUILD SUCCESS
```

```text
Executed files:    9
Executed requests: 99 (15.4/s)
Succeeded files:   9 (100.0%)
Failed files:      0 (0.0%)
Duration:          6413 ms (0h:0m:6s:413ms)
```

```text
stock de SKU-003 antes: 5
20 pedidos concurrentes de 1 × SKU-003: HTTP 201 × 5, HTTP 409 × 15
stock de SKU-003 después: 0
```

`hurl/hex` (7 de 7), `hurl/ms` (6 de 6) y `lab.py contract` (0 violaciones) siguen en verde. Las
pruebas del legado ya no crean su esquema con `create-drop`: lo crean con las mismas cinco migraciones,
y Hibernate lo valida. El esquema de prueba es, por primera vez, el de producción (la pregunta 13 del
taller 05).

```bash
git diff --no-index --stat -M50% laboratorio/estados/08/legacy/src laboratorio/estados/09/legacy/src
```

```text
 .../mono/legacy/inventory/InventoryService.java    |  30 ++---
 .../mono/legacy/inventory/internal/Product.java    |   6 +-
 ...
 .../mono/legacy/inventory/internal/StockStore.java |  75 +++++++++++
 ...
 .../main/resources/db/migration/V1__baseline.sql   | 149 +++++++++++++++++++++
 .../db/migration/V2__converge_legacy_databases.sql |   9 ++
 .../db/migration/V3__expand_inventory.sql          |  14 ++
 .../resources/db/switch/V4__resync_inventory.sql   |   8 ++
 .../java/dev/mono/legacy/OrderServiceTest.java     |  19 ++-
 .../src/test/resources/application-test.yaml       |   8 +-
 18 files changed, 320 insertions(+), 107 deletions(-)
```

## 11. 🩺 Errores reales al correrlo

### Bloquear solo la tabla que se lee: interbloqueos entre versiones

**Síntoma.** La primera idea de `StockStore` bloqueaba solo la tabla de la que cada versión lee:
`products` en `expand`, `inventory` en `switch`. Con las dos versiones vivas y la tormenta repartida:

```text
20 pedidos concurrentes de 1 × SKU-003: HTTP 201 × 4, HTTP 500 × 16
stock de SKU-003 después: 1
...
20 pedidos concurrentes de 1 × SKU-003: HTTP 201 × 1, HTTP 500 × 19
stock de SKU-003 después: 4
:38081 deadlock=32 timeout=35 check=0
:38083 deadlock=32 timeout=27 check=0
deadlock detected
  Detail: Process 115 waits for ExclusiveLock on tuple (0,6) of relation 16425 of database 16384; blocked by process 97.
```

**Causa.** `expand` bloqueaba `products` y después escribía `inventory`; `switch`, al revés. Dos
transacciones con los recursos en orden opuesto se esperan mutuamente; PostgreSQL detecta el ciclo y
aborta una, y mientras tanto las conexiones retenidas agotan el pool. Lo que se esperaba —vender de
más— no ocurrió; ocurrió algo peor para el cliente: casi todo en `500`.

**Lección.** Mientras dos versiones escriben las mismas filas, la exclusión mutua tiene que ser
común a las dos: las dos bloquean las dos filas y en el mismo orden (`StockStore.java:37`–`40`). Es la
regla del taller 07 —ordenar los recursos antes de bloquearlos— aplicada entre versiones, no solo entre
pedidos.

### La suite borraba la deriva antes de que V4 la corrigiera

**Síntoma.** En la primera corrida, antes de V4 no había ninguna fila distinta que corregir.

**Causa.** `lab.py suite` siembra antes de correr, y la semilla escribe las dos tablas iguales. Al
pasar a `expand` y correr la suite, la deriva del paso 1 desaparecía.

**Lección.** En producción nadie siembra: la deriva se queda hasta que algo la corrige. Se repitió el
recorrido midiendo la deriva **sin** sembrar entre el paso 1 y V4, que es la secuencia que muestra la
sección 8.

### Flyway tolera versiones más nuevas, en los dos sentidos

**Síntoma.** El *rollback* de B a `expand` con el esquema en V4 arrancó sin error, aunque V4 no está
entre sus migraciones.

**Causa.** Por defecto, Flyway trata las migraciones aplicadas que no conoce como «futuras» y solo
avisa (sección 9).

**Lección.** Es la condición del *rollback* de aplicación, y también la razón por la que una versión
incompatible con el esquema arranca sin quejarse. La compatibilidad entre versión y esquema no la
comprueba Flyway: la garantiza el orden de los pasos, y se comprueba con la suite contra las dos
instancias.

## 12. 🧰 Plataformas

Los talleres son solo Java (§6 de la guía). *Expand/contract* y la línea base son independientes de
la herramienta; el contraste de migradores por plataforma (Flyway y Liquibase, Prisma y TypeORM,
`golang-migrate`, Alembic) está en
[`03/05`](../03-datos-ejecucion-y-operacion/05-despliegues-migraciones-de-esquema-y-rollback.md).

## 13. 🧹 Teardown

```bash
python3 laboratorio/scripts/lab.py down
```

- Apaga PostgreSQL y Toxiproxy y borra sus volúmenes, `flyway_schema_history` incluida: el próximo
  arranque es una base nueva y recibirá las cinco migraciones. Las dos instancias del legado y el
  `psp-simulator` se paran con Ctrl+C.

## ⚠️ Errores frecuentes

- «La migración está bien, así que el despliegue está bien». Una migración correcta aplicada con la
  versión anterior viva la rompe (sección 5).
- «El *rollback* se hace con migraciones `DOWN`». Borrar lo que otra versión ya escribió pierde datos;
  el *rollback* seguro es de aplicación, sobre un esquema compatible con las dos.
- «*Baseline* comprueba que la base es V1». Solo lo anota; lo que difiere hay que hacerlo converger.
- «Con Flyway, `ddl-auto` puede quedarse en `update` por si acaso». Entonces hay dos autores del
  esquema; `validate` deja uno.
- «*Expand/contract* es para bases enormes». Es para cualquier cambio con dos versiones vivas a la vez,
  aunque la tabla tenga cinco filas.
- «Mientras se escribe en dos sitios basta con escribir bien». También hay que bloquear igual en las
  dos versiones, o se interbloquean.

## 📚 Referencias

- [Spring Boot: Database Initialization (Flyway)](https://docs.spring.io/spring-boot/how-to/data-initialization.html)
- [Flyway: Baseline On Migrate](https://documentation.red-gate.com/flyway/reference/configuration/flyway-namespace/flyway-baseline-on-migrate-setting)
- [Flyway: Locations](https://documentation.red-gate.com/flyway/reference/configuration/flyway-namespace/flyway-locations-setting)
- [ParallelChange (expand/contract), Martin Fowler](https://martinfowler.com/bliki/ParallelChange.html)
- [PostgreSQL 17: Explicit Locking (interbloqueos)](https://www.postgresql.org/docs/17/explicit-locking.html)

## 🧠 Preguntas

1. ¿Qué hace `baseline-on-migrate` y qué no comprueba? 🟢
2. ¿Por qué `ddl-auto` pasa a `validate` y no se quita sin más? 🟢
3. ¿Qué hace cada una de las tres fases de *expand/contract* en este taller? 🟢
4. ¿Por qué V5 vive en otra carpeta y no en `db/migration`? 🟢
5. ¿Por qué falló la versión del estado 08 cuando la nueva aplicó todas sus migraciones? 🟡
6. ¿Por qué hay que retirar en una migración las claves foráneas que una base nueva ya no tiene? 🟡
7. ¿Qué es la deriva del paso 1 y por qué V4 se aplica justo con `switch`? 🟡
8. ¿Qué garantiza que se pueda volver de `switch` a `expand` sin tocar el esquema? 🟡
9. ¿Por qué la variante que bloqueaba solo la tabla que leía se interbloqueaba? 🟡
10. Flyway avisa pero arranca con un esquema más nuevo. ¿Es un defecto o una ventaja? 🟠
11. Te piden hacer este cambio «en un solo despliegue, que es solo una columna». ¿Qué respondes y qué evidencia muestras? 🟠
12. Después de V5 descubres un error en `contract` y necesitas volver a `switch`. ¿Qué haces? 🟠
13. ¿Qué cambiaría si `inventory` estuviera en otra base, de otro proceso? 🔴

## 🧪 Ejercicios

1. 🟢 **Orientación en código ajeno.** ¿En qué archivo y línea decide una versión si lee el stock de
   `products` o de `inventory`? Responde con rutas de `laboratorio/estados/09/`.
2. 🟢 Arranca la versión nueva sobre una base del estado 08 sin línea base y pega el error. Después,
   con línea base, pega `flyway_schema_history`.
3. 🟡 Repite la provocación de la sección 5 y mide cuánto tiempo pasa entre el arranque de B y el
   primer `500` de A. ¿Qué te dice eso de un despliegue gradual con diez instancias?
4. 🟡 **Orientación en código ajeno.** Encuentra todo el código que sabe que existe `products.stock` en
   el estado 09. ¿Qué habría que borrar después de V5?
5. 🟡 Añade una columna `reserved` a `inventory` con *expand/contract*, sin parar las dos instancias.
   Escribe las migraciones y la tabla de pasos.
6. 🟠 Escribe la migración hacia delante que recuperaría `products.stock` después de V5 (sección 9) y
   pruébala con una versión `switch`.
7. 🟠 Sustituye la escritura doble en la aplicación por un *trigger* temporal de sincronización.
   ¿Qué ganas en los pasos mixtos y qué pierdes frente al taller 06, que sacó la lógica de los
   *triggers*?
8. 🔥 Mide cuánto tarda V3 con un millón de productos y decide si la copia debe ir en la migración o en
   un proceso aparte por lotes.

---

**Anterior:** [`08` — Eventos, jobs y dos instancias](08-eventos-jobs-y-dos-instancias.md).
**Siguiente:** [`10` — El monolito distribuido provocado](10-el-monolito-distribuido-provocado.md).
