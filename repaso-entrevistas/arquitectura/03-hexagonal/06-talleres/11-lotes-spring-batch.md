# 11 — Lotes con Spring Batch

Este taller es **opcional** y depende de `06/01` (contrato y entorno) y de `06/03` (el sabor Java,
que es el que se extiende). Añade la cuarta puerta de entrada al núcleo: un lote. El proveedor deja
un `stock-YYYY-MM-DD.csv` con ajustes de existencias y el job `stockAdjustment` lo aplica por
chunks, llamando a un caso de uso nuevo, `AdjustStock`, fila a fila; un segundo job, `dailyClose`,
escribe el cierre del día. El mismo jar que sirve HTTP es la CLI que corre los lotes, y un endpoint
nuevo, `GET /api/v1/batches/{id}`, cuenta qué hizo cada ejecución. Termina cuando un lote de mil
líneas con una corrupta deja 998 ajustes y una cuarentena de dos, cuando matar la JVM a mitad de
lote y reiniciar deja **exactamente** el mismo inventario que un lote sin caída, y cuando dos
réplicas del mismo `JobInstance` se estorban como deben.

> **Vigencia:** 2026-09-28. Versiones verificadas ese día en Maven Central y en el BOM de Spring
> Boot 4.1.1 (Spring Batch 6.0.5).

**Salto rápido:** [1](#1--qué-enseña-este-taller) · [2](#2--prerrequisitos-y-versiones) · [3](#3-️-mapa-de-carpetas) · [4](#4--el-núcleo-adjuststock) · [5](#5--el-job-stockadjustment-chunk-checkpoint-cuarentena) · [6](#6-️-el-jar-como-cli-y-el-jobrepository-como-memoria) · [7](#7--provocaciones) · [8](#8--evidencia) · [9](#9--errores-provocados-a-propósito) · [10](#10--teardown) · [Preguntas](#-preguntas) · [Ejercicios](#-ejercicios)

## 1. 🎯 Qué enseña este taller

```text
stock-2026-09-28.csv ──► FlatFileItemReader ──► validate (processor) ──► apply (writer) ──► AdjustStock ──► Inventory.adjust ──► PostgreSQL
   1000 líneas              lee 100 (chunk)        forma; CRASH (caos)      por cada fila            (caso de uso)      (puerto)            │
                                                        │ InvalidStockLine       │ NotFound / InsufficientInventory                       │
                                                        └──────── skip ──────────┘──► cuarentena (<archivo>.quarantine.csv)               │
                                                                                                                                          │
JobRepository (BATCH_* en hex_orders): un commit por chunk, con las filas del chunk ◄──────────────────────────────────────────────────────┘
```

Cinco cosas que un `@Scheduled` con un bucle no obliga a pensar y Spring Batch sí:

- **El lote no tiene lógica de negocio.** El `ItemWriter` llama a `AdjustStock`, el mismo caso de uso
  que mañana llamará un endpoint o una cola. El capítulo
  [03/03](../03-adaptadores-de-entrada/03-jobs-cli-y-procesos-batch.md) lo decía; aquí se ve el
  precio de no hacerlo: cero.
- **El chunk es la transacción.** Cien filas, un commit. Si la fila 350 mata el proceso, las 300
  anteriores están confirmadas y las 50 de su chunk no; nada queda a medias.
- **El `JobRepository` es el checkpoint.** En PostgreSQL, junto a los datos. Tras la caída, el
  reinicio con los mismos parámetros sigue desde la línea 301: ni repite ni salta.
- **La política de skip es una cuarentena.** Una línea corrupta o un ajuste imposible no paran el
  lote ni se pierden: van a `<archivo>.quarantine.csv` con su motivo, y hay un límite.
- **`JobExecutionAlreadyRunningException` es un lease.** Una ejecución `STARTED` en el repositorio
  es una réplica que ya lo está haciendo, o una que murió sin despedirse; en ambos casos hay que
  decidir antes de volver a lanzar.

El precio: 233 líneas de adaptador, un caso de uso de 30, seis tablas `BATCH_*` y un endpoint. La
ganancia: un lote reanudable, auditable y con cuarentena que no sabe qué es un inventario.

## 2. 🧰 Prerrequisitos y versiones

| Herramienta | Versión fijada | Para qué |
|---|---|---|
| `spring-boot-starter-batch` | la del BOM de Boot 4.1.1 (Spring Batch `6.0.5`) | `JobBuilder`, `StepBuilder`, `FlatFileItemReader`, `JobRepository` |
| Esquema `BATCH_*` | `schema-postgresql.sql` de `spring-batch-core` 6.0.5, copiado a `contrato/seed/schema-batch.sql` con `IF NOT EXISTS` | las seis tablas y tres secuencias del `JobRepository`, en `hex_orders` |

Boot 4 ya no crea el esquema de Batch (`spring.batch.jdbc.initialize-schema` no existe) ni un
`JobRepository` JDBC por su cuenta: Batch 6 arranca "resourceless" (§9). El esquema entra con la
semilla y el repositorio se declara en el código.

```text
python3 06-talleres/laboratorio/scripts/lab.py up
python3 06-talleres/laboratorio/scripts/lab.py seed
python3 06-talleres/laboratorio/scripts/lab.py batch sample --out 06-talleres/laboratorio/batch/in/stock-2026-09-28.csv --lines 1000 --corrupt-at 500
python3 06-talleres/laboratorio/scripts/lab.py batch run --job stockAdjustment --file 06-talleres/laboratorio/batch/in/stock-2026-09-28.csv
```

- `seed` recarga la semilla y, desde este taller, aplica `schema-batch.sql` (idempotente), vacía
  las tablas `BATCH_*` y reinicia sus secuencias: cada semilla es también un `JobRepository`
  nuevo con ids desde 1.
- `batch sample` genera un CSV `sku,delta,reason` con N líneas deterministas (misma semilla, mismo
  archivo); `--corrupt-at N` mete una línea con `sku` y `delta` inválidos; `--crash-at N` marca una
  línea con `reason=CRASH` para la provocación de §7.
- `batch run` arranca el **mismo proyecto** del backend como CLI: `--spring.main.web-application-type=none`
  (sin Tomcat), `--spring.batch.job.enabled=true` y `--spring.batch.job.name=<job>` (Boot lanza
  ese job al arrancar), `--spring.jms.listener.auto-startup=false` (un lote no consume la cola del
  taller 08), y los parámetros del job sin guiones: `file=<ruta absoluta>` o `date=YYYY-MM-DD`.
  El proceso termina con el código de salida del job. Los mismos parámetros son el mismo
  `JobInstance`: correr dos veces es reiniciar, no repetir.

```text
python3 06-talleres/laboratorio/scripts/lab.py batch run --job dailyClose --date 2026-09-28
python3 06-talleres/laboratorio/scripts/lab.py batch status 1
python3 06-talleres/laboratorio/scripts/lab.py batch recover
```

- `dailyClose` escribe `laboratorio/batch/out/daily-close-<date>.csv` con pedidos e importe por
  estado; `date` identifica el `JobInstance`.
- `batch status ID` hace `GET /api/v1/batches/ID` al backend en `:8081` como `ops` (hay que tener
  `lab.py java` arriba): estado, código de salida y, por step, leídos, escritos, saltados, commits
  y rollbacks.
- `batch recover` marca `FAILED` lo que quedó `STARTED` por una caída: sin eso, el reinicio cree
  que el lote sigue corriendo (§7).

## 3. 🗂️ Mapa de carpetas

```text
laboratorio/
├── batch/in/                                        los CSV del proveedor (los genera lab.py batch sample); *.quarantine.csv al lado
├── batch/out/                                       informes del dailyClose (no se versionan)
├── contrato/seed/schema-batch.sql                   BATCH_* de Spring Batch 6.0.5; lo aplica seed y el initdb del compose
├── contrato/openapi.yaml                            + GET /api/v1/batches/{executionId} (tag batches, x-suite taller-11)
├── scripts/lab.py                                   + batch sample · run · status · recover; seed aplica y vacía BATCH_*
└── java/src/main/java/hex/orders/
    ├── application/port/out/Inventory.java          + adjust(sku, delta)                                   ← núcleo, declarado
    ├── application/usecase/AdjustStock.java         NUEVO: solo operator; delta ≠ 0; una unidad de trabajo    ← núcleo, declarado
    ├── infrastructure/inbound/batch/                NUEVO
    │   ├── StockAdjustmentJobConfiguration.java     reader (CSV, @StepScope), processor (forma + caos), writer (→ AdjustStock), skip, cuarentena
    │   ├── DailyCloseJobConfiguration.java          tasklet: el cierre del día a un CSV
    │   ├── StockLine.java · InvalidStockLine.java   la fila y su rechazo de forma
    ├── infrastructure/inbound/http/BatchController.java   GET /batches/{id} desde el JobRepository
    ├── infrastructure/config/BatchConfiguration.java      el JobRepository JDBC sobre el DataSource del sistema
    ├── infrastructure/config/TokenConfiguration.java      clave y codecs JWT, separados del filtro HTTP (§9)
    ├── infrastructure/config/SecurityConfiguration.java   ahora @ConditionalOnWebApplication(SERVLET)
    ├── infrastructure/outbound/postgres/JpaInventory.java + adjust
    └── HexOrdersApplication.java                    en modo lote, termina con el código de salida del job
```

## 4. 🧱 El núcleo: `AdjustStock`

```java
public Result execute(Command command) {
    command.actor().requireOperator();
    if (command.delta() == 0) throw new IllegalArgumentException("delta must not be zero");
    return unitOfWork.run(() -> new Result(command.sku(), command.delta(), inventory.adjust(command.sku(), command.delta())));
}
```

- `Inventory.adjust(sku, delta)` es el puerto nuevo: devuelve el disponible resultante, lanza
  `NotFound` si el SKU no existe e `InsufficientInventory` si dejaría el stock en negativo.
  `JpaInventory` lo implementa con la entidad de siempre; el fake de `CreateOrderTest` gana una
  línea.
- El actor del lote es un operador del sistema con identidad fija
  (`batch@hex.local`, rol `OPERATOR`): la misma decisión que en la cola del taller 08 —el que
  actúa es un sistema de confianza, y el núcleo aplica la misma regla (`requireOperator`) venga de
  donde venga.
- El caso de uso abre su unidad de trabajo. Dentro de un chunk, esa transacción **se une** a la
  del chunk (`REQUIRED`); fuera (un endpoint que lo llame mañana), es la suya. El caso de uso no
  sabe cuál de las dos.

`git diff --stat -- domain application` de este taller: `Inventory.java` (+1 método),
`AdjustStock.java` (nuevo, 30 líneas). Nada más.

## 5. 🔁 El job `stockAdjustment`: chunk, checkpoint, cuarentena

```java
return new StepBuilder("adjustStock", jobRepository)
    .<StockLine, AdjustStock.Command>chunk(properties.batch().chunkSize())   // 100 filas = una transacción
    .transactionManager(transactionManager)
    .reader(stockLineReader)          // FlatFileItemReader, @StepScope: el archivo es un parámetro del job
    .processor(validate)              // forma de la fila → Command; lanza InvalidStockLine
    .writer(apply)                    // por cada Command: adjustStock.execute(...)
    .faultTolerant()
    .skip(InvalidStockLine.class, NotFound.class, InsufficientInventory.class)
    .skipLimit(properties.batch().skipLimit())
    .skipListener(quarantine)         // cada fila saltada, con su motivo, a <archivo>.quarantine.csv
    .build();
```

- **Chunk = transacción pequeña.** El reader lee 100 líneas, el processor las convierte, el writer
  las aplica, y el commit confirma las 100 **y** el avance del reader en el `JobRepository`, en la
  misma transacción. Diez commits para mil líneas.
- **Reanudable por construcción.** `FlatFileItemReader` guarda `read.count` en el
  `ExecutionContext` del step; un reinicio de la misma ejecución lo lee y salta esas líneas. No
  hay código de "recuerda por dónde ibas": lo pone el reader, y el chunk lo confirma.
- **Skip como cuarentena.** Cuando una fila lanza en el writer, Batch revierte el chunk y lo
  vuelve a procesar fila a fila (el *chunk scan*) para aislar la culpable: por eso un lote con
  dos filas malas muestra `rollbackCount 2` y `commitCount 10`, no 12. La culpable va al
  `SkipListener`; las demás se confirman. Pasado `skipLimit`, el step falla: diez filas malas en
  mil es un archivo malo, no diez incidencias.
- `chunk(int)` sin gestor es el modelo nuevo de Batch 6 (`ChunkOrientedStepBuilder`); `chunk(int,
  tm)` es el heredado y avisa de su retirada en 7.0 (§9).

## 6. 🖥️ El jar como CLI y el `JobRepository` como memoria

```java
@Configuration
public class BatchConfiguration extends JdbcDefaultBatchConfiguration {
    @Override protected DataSource getDataSource() { return dataSource; }
    @Override protected PlatformTransactionManager getTransactionManager() { return transactionManager; }
}
```

- El `JobRepository` en PostgreSQL, con el `DataSource` y el gestor de transacciones **del
  sistema**: el checkpoint de un chunk y sus filas se confirman juntos o no se confirman. Un
  repositorio en otra base (o en memoria) rompería eso: filas confirmadas sin checkpoint, o al
  revés.
- El mismo jar arranca como servidor (`lab.py java`) o como CLI (`lab.py batch run`). En modo CLI:
  sin Tomcat (`web-application-type=none`), sin filtro de seguridad HTTP
  (`@ConditionalOnWebApplication`), sin listener JMS, con los tokens disponibles (`Login` los
  necesita aunque no haya HTTP: §9), y `System.exit(SpringApplication.exit(context))` al terminar el
  job, o el scheduler de la outbox mantiene la JVM viva para siempre.
- Boot lanza el job con los argumentos sin `--` como `JobParameters`. `file=...` identifica el
  `JobInstance` de `stockAdjustment`; `date=...` el de `dailyClose`. Mismo instancia + `COMPLETED`
  → `JobInstanceAlreadyCompleteException`; mismo instancia + `FAILED` → reinicio; mismo instancia +
  `STARTED` → `JobExecutionAlreadyRunningException`.

`BatchController` lee el `JobRepository` (`getJobExecution(id)`) y lo expone: es la ventana
operativa, como `/notifications` lo era a la outbox. El DAO JDBC de Batch 6 lanza
`EmptyResultDataAccessException` cuando no hay fila; el controlador lo traduce a `404` (§9).

## 7. 🧨 Provocaciones

### Matar el job a mitad y reiniciar

```text
python3 06-talleres/laboratorio/scripts/lab.py batch sample --out .../stock-2026-09-28.csv --lines 1000 --corrupt-at 500 --crash-at 350
python3 06-talleres/laboratorio/scripts/lab.py batch run --job stockAdjustment --file .../stock-2026-09-28.csv --chaos
```

- `--chaos` pone `hex.batch.chaos=crash-on-marker`: el processor ejecuta `Runtime.halt(137)` al
  ver `reason=CRASH`, en la línea 350, dentro del cuarto chunk (301–400).

Literal (2026-09-28):

```text
WARN batch: quarantined SKU-004,-1,supplier-receipt,"SKU-004: requested 1, available 0"
ERROR batch: CHAOS crash-on-marker at SKU-001 — halting the JVM mid-chunk
batch: el proceso terminó con código 1
--- tras la caída ---
2|STARTED|300|299|3|0|1|2                ← step: leídas 300, escritas 299, 3 commits; sigue STARTED
SKU-001|120 SKU-002|262 SKU-003|139 SKU-004|141 SKU-005|137
```

Tres chunks confirmados; el cuarto, revertido con la JVM. Reinicio directo, mismos parámetros:

```text
Caused by: org.springframework.batch.core.launch.JobExecutionAlreadyRunningException: A job execution for this job is already running: JobInstance: id=2
```

El repositorio no sabe que la JVM murió: la ejecución sigue `STARTED`, y eso es el **lease**. Se
declara fallida (`batch recover`, que es lo que `JobOperator.recover` hace en Batch 6) y se
reinicia:

```text
UPDATE 1
UPDATE 1
WARN batch: quarantined SKU-???,diez,typo,"sku must match SKU-nnn: StockLine[sku=SKU-???, delta=diez, reason=typo]"
INFO Job: [SimpleJob: [name=stockAdjustment]] completed
2|FAILED|300|299|3|0|1|2
3|COMPLETED|700|699|7|1|0|0              ← la segunda ejecución leyó las 700 restantes, ni una más
SKU-001|493 SKU-002|527 SKU-003|553 SKU-004|446 SKU-005|541
```

**El mismo inventario que un lote sin caída** (`493 527 553 446 541`, §8). La línea corrupta (500)
la vio la segunda ejecución; la 350 con `CRASH` ya no mata a nadie porque el caos está apagado, y
su ajuste se aplicó. `read_count 300 + 700 = 1000`.

### Dos réplicas del mismo `JobInstance`

Con el archivo ya procesado, un segundo lanzamiento:

```text
Caused by: org.springframework.batch.core.launch.JobInstanceAlreadyCompleteException: A job instance already exists and is complete for identifying parameters={file=...}
batch: el proceso terminó con código 1
```

Y con una ejecución `STARTED` (la de arriba, antes de `recover`), `JobExecutionAlreadyRunningException`.
Las dos son el `JobRepository` haciendo de cerradura: un mismo archivo no se aplica dos veces por
error, y dos réplicas no lo procesan a la vez. Lo que no hace es distinguir "corriendo" de "murió
sin avisar": esa decisión es de un operador (o de `recover`).

### Una línea corrupta entre mil

```text
--- cuarentena ---
SKU-004,-1,supplier-receipt,"SKU-004: requested 1, available 0"
SKU-???,diez,typo,"sku must match SKU-nnn: StockLine[sku=SKU-???, delta=diez, reason=typo]"
```

La primera es un ajuste imposible (el stock de `SKU-004` es 0 y la línea resta 1): el caso de uso
lanza `InsufficientInventory` y Batch la aparta. La segunda no tiene forma: el processor lanza
`InvalidStockLine`. Ninguna paró el lote; las dos quedan con su motivo para quien reciba el
archivo. `skipCount 2`, `writeCount 998`.

### El cierre del día, dos veces

```text
INFO batch: daily close for 2026-09-28 written to ../batch/out/daily-close-2026-09-28.csv (5 status rows)
status,orders,amount
CANCELLED,3,1528.90
CONFIRMED,1,109.70
PAID,2,19.90
PAYMENT_PENDING,1,666.00
PAYMENT_REJECTED,1,1499.00
$ lab.py batch run --job dailyClose --date 2026-09-28        (otra vez)
Caused by: org.springframework.batch.core.launch.JobInstanceAlreadyCompleteException
```

`date` es el parámetro identificador: cerrar el mismo día dos veces es un error del repositorio,
no un segundo informe.

## 8. 🧪 Evidencia

El lote de mil líneas con una corrupta, sin caída, y lo que dice el `JobRepository` (2026-09-28):

```text
WARN batch: quarantined SKU-004,-1,supplier-receipt,"SKU-004: requested 1, available 0"
INFO Chunk scan completed
WARN batch: quarantined SKU-???,diez,typo,"sku must match SKU-nnn: StockLine[sku=SKU-???, delta=diez, reason=typo]"
INFO Step: [adjustStock] executed in 456ms
INFO Job: [SimpleJob: [name=stockAdjustment]] completed with the following parameters: [{JobParameter{name='file', ...}}]
batch: el proceso terminó con código 0
1|COMPLETED|COMPLETED|1000|998|10|1|1|2      ← id, status, exit, read, write, commits, process_skip, write_skip, rollbacks
SKU-001|493 SKU-002|527 SKU-003|553 SKU-004|446 SKU-005|541
```

Y por HTTP, con `lab.py java` arriba:

```text
$ lab.py batch status 1
{ "id": 1, "jobName": "stockAdjustment", "status": "COMPLETED", "exitCode": "COMPLETED",
  "steps": [ { "name": "adjustStock", "status": "COMPLETED", "readCount": 1000, "writeCount": 998,
               "skipCount": 2, "commitCount": 10, "rollbackCount": 2 } ] }
$ lab.py batch status 99
404 {"instance":"/api/v1/batches/99","status":404,"title":"Order not found","code":"ORDER_NOT_FOUND"}
```

La suite HTTP de `06/01`, con Batch en el classpath y el mismo jar (7/7, 85 peticiones, 4019 ms),
y las pruebas del sabor:

```text
[INFO] Tests run: 17, Failures: 0, Errors: 0, Skipped: 0
[INFO] BUILD SUCCESS
```

Inventario (el código se generó de una vez; quien lo haga en un commit obtendrá este
`git diff --stat`):

```text
$ git diff --stat -- src/main/java/hex/orders/domain src/main/java/hex/orders/application
 application/port/out/Inventory.java        | +adjust(sku, delta)
 application/usecase/AdjustStock.java       | nuevo (30 líneas)
$ wc -l inbound/batch/*.java
     233 total
$ wc -l AdjustStock.java inbound/batch/*.java BatchController.java BatchConfiguration.java TokenConfiguration.java contrato/seed/schema-batch.sql
     476 total
```

Además: `JpaInventory` (+1 método), `SecurityConfiguration` (−3 beans, +1 condición),
`HexOrdersApplication` (+4 líneas), `HexProperties` (+1 record), `application.yaml` (+9 líneas),
`pom.xml` (+1 dependencia), `openapi.yaml` (+1 ruta), `lab.py` (+4 órdenes), `docker-compose.yml`
(+1 montaje), `CreateOrderTest` (+1 línea en el fake).

**Cinco plataformas:** no aplica. Es un taller de integración, solo Java (guía §10.3).

## 9. 🩺 Errores provocados a propósito

Cinco reales. Los tres primeros son lo que cuesta arrancar el mismo jar sin servidor; los dos
últimos, lo que cambió en Spring Batch 6 y Boot 4.

### `HttpSecurity` no existe sin servidor

```text
Parameter 0 of method api in hex.orders.infrastructure.config.SecurityConfiguration required a bean of type
'org.springframework.security.config.annotation.web.builders.HttpSecurity' that could not be found.
```

Con `web-application-type=none` no hay `HttpSecurity`, y la configuración de seguridad lo exigía.
Corrección: `@ConditionalOnWebApplication(type = SERVLET)`: el filtro de peticiones solo tiene
sentido si hay peticiones. Lección: una configuración que asume el borde HTTP es del borde HTTP.

### `Login` necesita emitir tokens aunque no haya HTTP

```text
Consider defining a bean of type 'org.springframework.security.oauth2.jwt.JwtEncoder' in your configuration.
```

Al apagar `SecurityConfiguration`, se fueron con ella la clave y los codecs JWT, y
`JwtTokenIssuer` (el adaptador del puerto `TokenIssuer`, que `Login` usa) se quedó sin
`JwtEncoder`. El modo CLI destapó una frontera mal puesta desde el taller 03: emitir y verificar
tokens es una capacidad del sistema; exigirlos en cada petición es del borde. Corrección:
`TokenConfiguration` (clave, encoder, decoder; incondicional) separada de `SecurityConfiguration`
(la cadena de filtros; solo con servlet). Lección: un segundo modo de arranque es la mejor prueba
de qué configuración era realmente de qué borde.

### El job terminó y la JVM no

El primer lote aplicó las mil líneas... y el proceso siguió vivo hasta el `timeout` del
orquestador. Boot no termina la aplicación cuando el job acaba, y el `ThreadPoolTaskScheduler` de
la outbox (`@EnableScheduling`, hilos no daemon) la mantenía. Corrección: en `main`, si
`spring.batch.job.enabled` es `true`, `System.exit(SpringApplication.exit(context))`, que además
propaga el código de salida del job (`JobExecutionExitCodeGenerator`). Lección: una CLI tiene que
saber terminar; un servidor, no.

### Batch 6 arranca sin memoria, y `@EnableJdbcJobRepository` no la puso

El lote completaba, el inventario cambiaba y las tablas `BATCH_*` seguían **vacías**. Spring Batch
6 usa por defecto un `ResourcelessJobRepository` (sin base, sin checkpoint) y Boot 4 registra esa
configuración por defecto (`SpringBootBatchDefaultConfiguration extends DefaultBatchConfiguration`);
la anotación `@EnableJdbcJobRepository` del taller no la desplazó. Corrección: un `@Configuration`
que **extiende** `JdbcDefaultBatchConfiguration` con el `DataSource` y el gestor del sistema; ante
una `DefaultBatchConfiguration` propia, Boot se retira. Lección: "el job corre" no es "el job se
puede reanudar"; sin repositorio durable, el reinicio empezaría de cero y aplicaría dos veces las
300 primeras filas. Y `spring.batch.jdbc.initialize-schema` ya no existe en Boot 4: el esquema
viene en la semilla.

### `TRUNCATE` no reinicia secuencias: el `404` que era un `500`

```text
500 {"code":"INTERNAL_ERROR"}   ← GET /api/v1/batches/2
org.springframework.dao.EmptyResultDataAccessException: Incorrect result size: expected 1, actual 0
```

Dos cosas a la vez. La semilla vaciaba `BATCH_*` pero las secuencias seguían: la ejecución "2"
era la 6. Y el DAO JDBC de Batch 6 no devuelve `null` cuando no hay fila: lanza, y el `500`
genérico se lo tragó. Corrección: `seed` reinicia las tres secuencias (`ALTER SEQUENCE ...
RESTART`), y el controlador traduce `EmptyResultDataAccessException` a `404`. Lección: "no existe"
tiene muchas formas según la biblioteca; el traductor del borde tiene que conocer la de cada
adaptador que expone.

## 10. 🧹 Teardown

Un lote termina solo; `Ctrl+C` a mitad deja una ejecución `STARTED` que hay que `recover` antes de
reiniciar (es la provocación de §7, no un fallo). `lab.py down` apaga el entorno, con las tablas
`BATCH_*` dentro. `batch/out/` y `*.quarantine.csv` no se versionan.

## ⚠️ Errores frecuentes

- "Un cron necesita su propia lógica de negocio." Necesita un caso de uso al que llamar. Si el
  writer tiene un `UPDATE inventory`, el día que HTTP también ajuste stock hay dos reglas.
- "Una transacción larga garantiza el lote." Garantiza que mil filas se bloqueen durante minutos y
  que una caída lo pierda todo. Chunks pequeños con checkpoint garantizan reanudar.
- "Si el job falló, lo vuelvo a lanzar." Si quedó `STARTED`, el repositorio lo rechaza; si quedó
  `COMPLETED`, también. Hay que mirar el estado antes: para eso existe `/batches/{id}`.
- "Skip es ignorar errores." Es apartar con motivo y con límite. Sin cuarentena escrita, es perder
  filas en silencio; sin límite, es aceptar un archivo roto.
- "El JobRepository puede ir en memoria para simplificar." Entonces no hay reinicio: es un bucle
  con más clases.

## ✅ Veredicto

La cuarta puerta costó un caso de uso de 30 líneas en el núcleo y 233 en el adaptador, y dejó un
lote que se reanuda desde el chunk exacto, aparta lo que no puede aplicar y no se deja lanzar dos
veces. Lo que el taller enseña no está en `ItemReader` ni en `ItemWriter`: está en que el chunk
es la transacción, en que el checkpoint vive junto a los datos, y en que "corriendo" y "murió sin
avisar" se ven iguales desde el repositorio. Los cinco errores reales dibujan lo que cuesta que un
mismo jar sea servidor y CLI, y lo que Batch 6 dejó de hacer por defecto.

## 📚 Referencias

- [Spring Batch: referencia](https://docs.spring.io/spring-batch/reference/index.html) · [procesamiento por chunks](https://docs.spring.io/spring-batch/reference/step/chunk-oriented-processing.html) · [skip](https://docs.spring.io/spring-batch/reference/step/chunk-oriented-processing/configuring-skip.html) · [reinicio](https://docs.spring.io/spring-batch/reference/step/chunk-oriented-processing/restart.html) · [`JobRepository`](https://docs.spring.io/spring-batch/reference/job/configuring-repository.html) · [ejecutar jobs](https://docs.spring.io/spring-batch/reference/job/running.html) · [`FlatFileItemReader`](https://docs.spring.io/spring-batch/reference/readers-and-writers/flat-files/file-item-reader.html) · [novedades de 6.0](https://docs.spring.io/spring-batch/reference/whatsnew.html)
- [Spring Boot: Batch](https://docs.spring.io/spring-boot/how-to/batch.html)

## 🧠 Preguntas

1. 🟢 ¿Por qué el `ItemWriter` llama a `AdjustStock` en vez de hacer el `UPDATE` él mismo?
2. 🟢 ¿Qué es un chunk y qué se confirma en su commit?
3. 🟢 ¿Quién es el actor de un lote y por qué el núcleo no lo trata distinto de un operador humano?
4. 🟢 ¿Qué pasa con las 50 filas del chunk en curso cuando la JVM muere en la fila 350?
5. 🟢 ¿Para qué sirve `<archivo>.quarantine.csv` y qué pasaría sin `skipLimit`?
6. 🟡 Explica el `rollbackCount 2` y el `commitCount 10` de un lote de mil filas con dos malas.
7. 🟡 ¿Por qué el `JobRepository` tiene que estar en la misma base y con el mismo gestor de transacciones que el inventario?
8. 🟡 Tras la caída, el reinicio directo dio `JobExecutionAlreadyRunningException`. ¿Qué sabe y qué no sabe el repositorio, y quién decide?
9. 🟡 ¿Qué identifica un `JobInstance` y por qué `dailyClose` usa `date` como parámetro identificador?
10. 🟡 ¿Cómo sabe la segunda ejecución que debe empezar en la línea 301?
11. 🟠 `read_count 300 + 700` y el mismo inventario que un lote sin caída. Enumera las tres garantías que se combinaron para que fuera exacto y qué fallaría si faltara cada una.
12. 🟠 El modo CLI destapó que la clave JWT vivía en la configuración del filtro HTTP. ¿Por qué eso era una frontera mal puesta desde el taller 03 y por qué no se notó hasta ahora?
13. 🟠 Batch 6 arranca "resourceless" y Boot 4 no crea el esquema. Argumenta si eso es una mejora o un riesgo, y qué señal en la evidencia delató que el repositorio no era durable.
14. 🟠 Compara las cuatro puertas del núcleo (HTTP, cola, gRPC, lote): qué tiene cada una de autenticación, idempotencia y traducción de errores, y qué es lo único que las cuatro comparten.

## 🧪 Ejercicios

1. 🟢 Baja `hex.batch.chunk-size` a `10`, repite el lote de mil líneas y pega `commitCount` y el
   tiempo del step. Súbelo a `1000` y repite. Explica qué se paga en cada extremo y qué pasa con
   la caída en la fila 350 en cada caso.
2. 🟢 Genera un CSV con `--corrupt-at` en doce líneas distintas (edítalo a mano) y `skip-limit`
   en 10. Pega el estado del step y explica por qué el lote debe fallar y no "apartar y seguir".
3. 🟡 Escribe una prueba de `AdjustStock` con el fake de inventario de `CreateOrderTest`: un
   customer no puede; `delta 0` se rechaza; un ajuste por debajo de cero lanza y no cambia nada.
   Explica qué anillo cubre y por qué no necesita Spring Batch.
4. 🟡 Añade una tabla `stock_adjustments` (sku, delta, reason, actor, created_at) y un puerto
   `StockAdjustments.record` que `AdjustStock` llame en la misma unidad de trabajo. Comprueba que
   tras la caída y el reinicio hay exactamente 998 filas, y explica por qué (chunk + checkpoint).
5. 🟠 Sustituye `batch recover` por `JobOperator.recover` (Batch 6) expuesto como
   `POST /api/v1/batches/{id}/recover` para operator. Explica qué comprueba `recover` que el
   `UPDATE` a mano no comprueba, y por qué "declarar muerta" una ejecución es una decisión
   humana o de un supervisor con *heartbeat*, nunca automática sin más.
6. 🟠 Ejecuta dos réplicas de verdad: lanza el mismo `batch run` en dos terminales con un segundo
   de diferencia y un CSV de 100 000 líneas. Pega las dos salidas. Después cambia el identificador
   del `JobInstance` para que sea `file` **y** `replica`, repite, y explica qué se rompió (el mismo
   archivo aplicado dos veces) y por qué el lease existe.
7. 🔴 Convierte `stockAdjustment` en un job de dos steps: el primero valida el archivo entero y
   escribe la cuarentena sin tocar el inventario; el segundo aplica solo lo válido. Explica qué
   gana (un archivo malo no ajusta nada), qué pierde (dos lecturas, dos checkpoints) y cómo cambia
   el reinicio tras una caída en cada step.
8. 🔥 Haz que `dailyClose` deje de ser un informe y cierre de verdad: un caso de uso `CloseDay` que
   resuelva los `PAYMENT_PENDING` del día consultando al proveedor gRPC del taller 10
   (`Lookup`), aplique las decisiones con `Order.resolvePayment` y publique `OrderPaid` /
   `OrderPaymentRejected` en el tópico del taller 09 vía la outbox. Explica qué transacción rodea
   cada pedido (una por fila, no una por día) y por qué el job sigue sin lógica de negocio.

---

**Siguiente:** el bloque termina aquí. Vuelve al [mapa de los talleres](README.md) para elegir
otro, o al [índice general](../README.md) del curso.
