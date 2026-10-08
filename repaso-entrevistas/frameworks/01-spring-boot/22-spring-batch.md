# 22 — Spring Batch

> **Objetivo:** diseñar un proceso por lotes reiniciable, saber qué pasa si se cae a la
> mitad de la ventana nocturna y poder defender el tamaño del chunk que elegiste.
> **Asume:** [`16`](16-transacciones.md) —el chunk es una transacción—,
> [`15`](15-datos-jdbc-jpa-mongo-y-redis.md) y [`05`](05-proxies-y-aop.md).
> **Vigencia:** 19 de septiembre de 2026 · Spring Boot 3.5.16 · Spring Batch 5.2.6 (el
> que trae el BOM de Boot 3.5.16) · Java 21.

---

## 1. 🧭 El problema: el fichero de las dos de la mañana

El core bancario deja cada noche un fichero con seiscientos mil movimientos: hay que leerlo,
validarlo y conciliarlo contra `inventory_item` antes de que abra la sucursal. A las 02:41,
con cuatrocientos mil procesados, la base se reinicia y tu proceso muere. Te preguntarán:

```text
¿qué quedó escrito?        → lo que confirmó cada transacción, ni un registro más
¿desde dónde reanudo?      → desde el último commit, no desde el principio
¿puedo relanzarlo igual?   → no, si ya corrió para esa fecha: es la misma instancia
```

Un bucle dentro de un `@Scheduled` no contesta ninguna, porque no persiste nada de sí mismo:
cuando muere se lleva el estado a la tumba. Spring Batch existe para eso — **para que el
proceso recuerde por dónde iba**. El diseño de la ventana en sí es de arquitectura: [`05-banca` §03 — el batch bancario](../../arquitectura/01-bases/05-banca/03-batch-y-spring-batch.md#6--el-batch-bancario-en-concreto).

> Nunca respondas: ~~"un job de Batch es un `@Scheduled` grande"~~
>
> Mejor: "un `@Scheduled` ejecuta código; un job de Batch ejecuta código **y escribe su
> propio estado en una base de datos**: por eso se reanuda y por eso no se repite."

---

## 2. 🧱 El modelo: seis sustantivos y ninguno sobra

```text
Job ─ Step                 la definición y sus fases: "conciliación", "leer fichero"
JobInstance                una corrida lógica: la conciliación DEL 17 DE SEPTIEMBRE
 └─ JobExecution           un intento de esa corrida (falló a las 02:41 → hubo otro)
     └─ StepExecution      un intento de un step, con sus contadores
         └─ ExecutionContext   el mapa clave/valor que sobrevive a la caída
```

- **`Job` y `Step` son configuración** —beans que declaras una vez—; **`JobInstance`
  (= `Job` + `JobParameters` identificadores, §5), `JobExecution` y `StepExecution` son
  datos**: filas que Spring Batch escribe mientras trabaja, y confundirlos es el error
  conceptual más caro del capítulo. **Un `StepExecution` solo existe si el step arrancó**: si
  el step 1 falló, no hay fila para el step 2 — no está vacía, no existe.
- **El `ExecutionContext` es un "property bag" persistido**: uno por `JobExecution` y otro
  por cada `StepExecution`. El del step se guarda **en cada commit**; el del job, entre step
  y step. Lo que metas ahí tiene que ser `Serializable`, o la restauración falla.

---

## 3. 🧱 El chunk: leer uno, procesar uno, escribir de a muchos

El modelo dominante no es "procesa la lista": es **leer de a un ítem, acumular hasta el
tamaño del chunk y escribir el bloque entero dentro de una transacción**, repitiendo hasta
que `read()` devuelve `null`.

```java
@Bean
Step reconcileStep(JobRepository jobRepository, PlatformTransactionManager transactionManager,
                   ItemReader<MovementLine> reader, ItemProcessor<MovementLine, InventoryEvent> processor,
                   ItemWriter<InventoryEvent> writer) {
    return new StepBuilder("reconcile-step", jobRepository)
            .<MovementLine, InventoryEvent>chunk(500, transactionManager)
            .reader(reader).processor(processor).writer(writer)   // el processor es opcional
            .build();
}
```

- **`new StepBuilder(nombre, jobRepository)`** es la API de Spring Batch 5: el
  `JobRepository` **se pasa al builder**, no se hereda de ninguna fábrica.
- **`chunk(500, transactionManager)`** declara el *commit interval* —cuántos ítems entran en
  una transacción— y **quién la abre y la confirma**, el mismo `PlatformTransactionManager`
  de [`16` §2](16-transacciones.md#2--el-modelo-y-quién-lo-invoca).
- **`<MovementLine, InventoryEvent>`** son los tipos de entrada y salida del step. Si el
  processor devuelve `null` el ítem **se filtra** —no se escribe y no es un error, cuenta en
  `filterCount`—; el `ItemWriter`, en cambio, **recibe una lista**, y esa firma es la que
  permite un `INSERT` por lote en vez de quinientos sueltos.
- **Lo que no se ve aquí:** no hay `@EnableBatchProcessing` (§4).

> **📝 En Spring Batch 4 esto se escribía distinto y el código viejo está en todas partes.**
> Hasta **Spring Batch** 4.x se inyectaban `JobBuilderFactory` y `StepBuilderFactory`
> (`stepBuilderFactory.get("step").chunk(500)`) y las dos fábricas **se eliminaron en la
> 5.0**: un ejemplo de 2021 no compila, y es un buen filtro de entrevista.

**Cuando el trabajo no tiene forma de ítems** —mover un fichero, lanzar un `TRUNCATE`— el
step es un **tasklet**: un método en una transacción, sin chunks y sin reanudación parcial.

**Los readers y writers ya vienen escritos**: `FlatFileItemReader` y `FlatFileItemWriter`
—con `LineMapper` y `FieldSetMapper` para mapear la línea—, `JdbcCursorItemReader`,
`JdbcPagingItemReader`, `JdbcBatchItemWriter`, `JpaPagingItemReader` y `JpaItemWriter`.

- **El cursor mantiene abiertos un `ResultSet` y una conexión del pool de
  [`15` §2](15-datos-jdbc-jpa-mongo-y-redis.md#2--el-datasource-y-hikaricp)** del primer ítem
  al último ⏱️; el paginado la suelta entre páginas a cambio de exigir un orden estable. Con
  JPA, cada chunk hace `flush` y limpia el persistence context, así que un chunk gigante es
  memoria retenida además de una transacción larga.

---

## 4. 🧱 El `JobRepository`: seis tablas y ningún truco

Todo lo del §2 vive en una base relacional. **Ese es el mecanismo**: no hay memoria mágica,
hay `INSERT` y `UPDATE` dentro de las mismas transacciones que tu negocio.

```text
BATCH_JOB_INSTANCE            una fila por corrida lógica
BATCH_JOB_EXECUTION           una fila por intento
BATCH_JOB_EXECUTION_PARAMS    los parámetros de ese intento, con su flag IDENTIFYING
BATCH_JOB_EXECUTION_CONTEXT   el property bag del job
BATCH_STEP_EXECUTION          contadores por step: read, write, commit, rollback, skips
BATCH_STEP_EXECUTION_CONTEXT  el property bag del step: aquí vive "por dónde iba"
```

- **Las tablas hay que crearlas.** Boot trae los scripts por motor y los ejecuta según
  `spring.batch.jdbc.initialize-schema`, con valor por defecto `embedded`: se crean solas en
  H2 **y no se crean en tu Postgres**. En serio van en Flyway
  ([`15` §9](15-datos-jdbc-jpa-mongo-y-redis.md#9--flyway-y-por-qué-el-esquema-no-lo-genera-hibernate))
  con la propiedad en `never`; **`table-prefix`** cambia el prefijo `BATCH_`. Boot **exige
  una base real**, aunque sea en memoria.
- **`@EnableBatchProcessing` no se escribe en una aplicación Boot.** Esa anotación —o
  extender `DefaultBatchConfiguration`— **desactiva la autoconfiguración**, incluida la
  creación del esquema. Es la trampa número uno al copiar ejemplos de la documentación de
  Spring Batch a secas, que sí la lleva porque no asume Boot.

> **⏱️ Costo en runtime del `JobRepository`.** Cada commit de chunk son varios `UPDATE` de
> metadatos además de tus escrituras: con `chunk(1)` y un millón de ítems, un millón de
> transacciones **y un millón de `UPDATE` de `BATCH_STEP_EXECUTION`**, y la contabilidad pasa
> a costar más que el trabajo.

---

## 5. 🧱 `JobParameters`: por qué no puedes relanzar lo mismo dos veces

**`JobInstance` = `Job` + `JobParameters` identificadores.** Ese es el contrato central: **si
el job ya terminó con éxito para esos parámetros, relanzarlo con los mismos no vuelve a
correr** — `JobInstanceAlreadyCompleteException`, o `JobExecutionAlreadyRunningException`.

```java
JobParameters params = new JobParametersBuilder()
        .addLocalDate("business.date", businessDate)          // identificador
        .addString("input.file", path, false)                 // NO identificador
        .toJobParameters();

jobLauncher.run(inventoryReconciliationJob, params);
```

- **`business.date`** es la clave de identidad —una instancia por fecha contable—: es lo que
  convierte "correr el job dos veces por error" en un rechazo en vez de un doble cargo.
- **El tercer argumento `false`** marca el parámetro como **no identificador**: participa en
  la ejecución pero no en la identidad —la ruta del fichero, un flag de verbosidad—. Al
  reintentar hay que volver a pasar *todos* los parámetros: los no identificadores **no se
  copian** de la ejecución anterior.
- **El antipatrón clásico** es añadir un `run.id` o un timestamp para "poder relanzar
  siempre": funciona y destruye la identidad — cada intento es una instancia nueva, así que
  **nunca se reanuda nada** y los duplicados quedan de tu cuenta.

> **🧠 Modelo mental.** Los `JobParameters` no son argumentos: son la **clave primaria** de
> la corrida. Si no puedes nombrar cuál es la clave de tu job, todavía no lo diseñaste.

---

## 6. 🩺 Restart: qué se reanuda, y qué tiene que cumplir tu reader

Cuando relanzas una instancia cuya última ejecución **falló**, Spring Batch crea un
`JobExecution` nuevo sobre la **misma** `JobInstance`: salta los steps en `COMPLETED` y
recupera de `BATCH_STEP_EXECUTION_CONTEXT` el contexto del step caído, que el step le pasa a
su reader al abrirlo.

**Y ahí está la condición que casi nadie menciona en una entrevista:** el reanudado lo hace
**el reader**, no el framework solo. Solo se reanuda uno que guarde su posición en el
`ExecutionContext` al abrirse y cerrarse —que implemente `ItemStream`—; el
`FlatFileItemReader` guarda cuántas líneas leyó y al reabrirse se las salta. **Un
`ItemReader` propio escrito como un iterador vuelve a empezar y duplica.**

- **`allowStartIfComplete(true)`** fuerza a un step a correr otra vez aunque quedara
  `COMPLETED` —por defecto es `false`—: lo quieres en validación o limpieza previa, y **no**
  en el step que mueve dinero. **`startLimit(n)`** limita cuántas veces puede arrancar un step
  en la instancia (`Integer.MAX_VALUE` por defecto); pasarse lanza `StartLimitExceededException`.
- **La granularidad del reanudado es el chunk, no el ítem.** Los ítems del chunk en vuelo se
  vuelven a leer y a escribir, así que el writer tiene que tolerar repetición: `upsert`,
  clave natural o un `INSERT` que choque contra una restricción única y sepa qué hacer.

> **⚠️ Reanudable no es idempotente.** Spring Batch garantiza que no vuelve a *contar* lo ya
> confirmado; no que tu escritura sea segura de repetir. El último chunk **se repite
> siempre** y esa parte la pones tú — se practica en [`L08` §10](l08-security-y-batch.md#10--caído-a-la-mitad-y-reanudado-las-tablas-antes-y-después).

---

## 7. ⚖ Skip y retry: cuando un registro malo no puede tumbar el lote

Por defecto, **cualquier excepción mata el step**: con tres líneas mal formadas pierdes la
ventana entera por el 0,0005 % de los datos. La tolerancia se activa con `faultTolerant()`,
que cambia el procesador del chunk por uno que sabe reintentar y descartar — sin esa
llamada, `skip` y `retry` no existen:

```java
return new StepBuilder("reconcile-step", jobRepository)
        .<MovementLine, InventoryEvent>chunk(500, transactionManager)
        .reader(reader).processor(processor).writer(writer)
        .faultTolerant()
        .skip(FlatFileParseException.class)       // línea ilegible: se descarta
        .skipLimit(50)                            // la 51 mata el step
        .retry(DeadlockLoserDataAccessException.class).retryLimit(3)
        .listener(skipAuditListener)              // un SkipListener: audita lo descartado
        .build();
```

- **`skip(...)` + `skipLimit(n)`**: la excepción declarada descarta el ítem y suma al
  contador. Los descartes se cuentan aparte en lectura, proceso y escritura, pero **el límite
  es global**, y si no lo declaras vale 10. El detalle fino: con límite 10, **es el descarte
  número once el que hace fallar el step**. **`noSkip(...)`** excluye excepciones de una regla
  ancha —`skip(Exception.class).noSkip(FileNotFoundException.class)`: descarto todo menos que
  falte el fichero, que no es un dato malo sino un problema de operación; y
  **`noRollback(...)`** es su pariente para la excepción de negocio que no revierte el chunk.
- **`retry(...)` + `retryLimit(n)` son para lo que no es determinista.** Una línea mal
  formada falla igual las tres veces: se descarta. Un deadlock puede resolverse esperando:
  se reintenta. Confundirlos da un job que tarda el triple en fallar por lo mismo.
- **`SkipListener`** recibe el ítem descartado y la excepción, y ahí escribes la fila de
  rechazados: **un `skipLimit` sin listener es pérdida de datos con permiso escrito.**

> **⚠️ Un skip es una decisión de negocio, no una configuración.** Cargar proveedores mal
> formateados se descarta; un movimiento de dinero, no. *"El `skipLimit` lo firma quien
> entiende el dato, no quien escribe el step"*.

---

## 8. ⚠️ El writer falla a la mitad del chunk: el puente con `16`

Es la pregunta favorita de quien ha sufrido batch en producción y tiene dos mitades.
**Sin `faultTolerant()`:** el `write(List)` lanza, la transacción del chunk hace rollback
—con las reglas de [`16` §6](16-transacciones.md#6-️-rollback-la-regla-que-casi-todo-el-mundo-dice-mal)—
y el step termina en `FAILED`. Los chunks anteriores **quedan confirmados**, porque cada uno
fue su propia transacción: se pierde el chunk en vuelo, no el trabajo hecho.

**Con `faultTolerant()` y skip en escritura:** el chunk se revierte igual y Spring Batch lo
reprocesa **aislando los ítems** para dar con el culpable; el malo se descarta y el resto se
escribe, en transacciones mucho más pequeñas. Ese chunk **cuesta un orden de magnitud más** y
tu writer ve el mismo ítem más de una vez.

- **El corolario de diseño** es el de [`16` §8](16-transacciones.md#8--el-límite-de-la-transacción-no-es-el-límite-de-tu-método):
  nada lento dentro del chunk — una llamada HTTP por ítem en el writer multiplica la duración
  de la transacción por el tamaño del chunk y retiene una conexión todo ese tiempo ⏱️. Y así
  se cierra el círculo de `16`: "una transacción por elemento evita que un fallo tumbe el
  lote" es esto, con el tamaño del chunk como perilla — `chunk(1)` es máxima granularidad y
  máximo costo; `chunk(100000)`, una transacción enorme que al fallar te devuelve al inicio.

> **🧠 Cómo se elige el tamaño del chunk.** Por **cuánto trabajo estás dispuesto a repetir**
> y cuánta memoria retiene la lista del writer; entre 100 y 1 000 con JDBC, midiendo. "1000
> porque sí" no es argumento; "porque el rollback máximo son 1 000 movimientos", sí.

---

## 9. ⚖ Flujo y paralelismo: cuatro formas y lo que cada una cobra

Los steps se encadenan con `.start(a).next(b)`, y con `.on("FAILED").to(c)` cuando la
transición depende del `ExitStatus` del anterior. El **multithreaded step** se activa dando
un `TaskExecutor` al `StepBuilder`: lo más barato de escribir y lo más fácil de romper.

| Forma | Qué paraleliza | Lo que cuesta |
|---|---|---|
| **Multithreaded step** | los chunks de un step, en varios hilos | readers y writers thread-safe, y el reanudado deja de ser fiable |
| **Parallel steps** (`split`) | flujos distintos a la vez | solo sirve si son independientes |
| **Partitioning** | el mismo step sobre rangos de datos | hay que saber partir el dominio |
| **Remote chunking** | el proceso de los ítems, en otras JVM | infraestructura de mensajería |

- **Partitioning** es la que se usa en banca: un step maestro divide el trabajo —por rango de
  cuenta, por sucursal, por fichero— y cada partición corre como **su propio `StepExecution`,
  con su fila y su `ExecutionContext`**. Por eso es la única que conserva intacta la semántica
  de reinicio: si falla la partición 7, reanudas la partición 7.
- **El veredicto: primero mide en un solo hilo**, y cuida el pool — ocho hilos contra un
  Hikari de diez dejan sin conexiones al resto de la aplicación ⏱️, así que el pool del job
  se dimensiona aparte o el job corre en su propio proceso.

---

## 10. 🧱 Lanzarlo, probarlo y vigilarlo

En una aplicación Boot, **si hay un solo bean `Job` en el contexto, se ejecuta al arrancar**
— lo hace el `JobLauncherApplicationRunner`. Perfecto para un contenedor que arranca, corre y
muere; mala sorpresa en una API que además sirve tráfico.

```properties
spring.batch.job.enabled=false
spring.batch.job.name=inventory-reconciliation-job
```

- **`spring.batch.job.enabled`** vale `true` por defecto: en `false` es lo que quieres cuando
  el job se dispara desde un endpoint o un scheduler, no al levantar el servicio; y
  **`spring.batch.job.name`** es obligatoria si hay más de un `Job` en el contexto.
- **Los parámetros del job se pasan por línea de comandos sin `--`**: `java -jar app.jar
  business.date=2026-09-17`. Lo que lleva `--` es una propiedad del `Environment` y el job no
  la ve: un error de un minuto que cuesta una ventana.
- **Probar un job** es `JobLauncherTestUtils`, que lanza el job —o un step suelto— y devuelve
  el `JobExecution` para afirmar sobre su estado y sus contadores. **Vigilarlo** son las
  métricas de Micrometer `spring.batch.job`, `.job.active`, `.step`, `.item.read`,
  `.item.process` y `.chunk.write`: no se alerta "falló", se alerta **duración por encima de
  la ventana** y **`skipCount` distinto de cero** ([`23`](23-actuator-y-observabilidad.md)).

**Si lo disparas con `@Scheduled`, hereda el problema de
[`18` §7](18-asincronia-scheduling-y-eventos.md#7-️-tres-réplicas-tres-ejecuciones)**: tres
réplicas son tres relojes y tres intentos. La diferencia es que el segundo intento no
duplica el trabajo, **lo rechaza** con `JobExecutionAlreadyRunningException`. Eso no es un
scheduler distribuido: te protege de la duplicación, no te dice quién debía correr.

---

## 11. ⚠️ Errores frecuentes

- **"Si falla, se vuelve a correr desde el principio."** Se reanuda desde el último commit
  del step caído y los ya completados se saltan — si el reader sabe retomar su posición.
- **"Le pongo un `run.id` con la hora."** Renunciaste al reinicio: cada intento es una
  instancia nueva que empieza de cero.
- **"El chunk size se pone en 1000."** Es cuánto trabajo aceptas repetir: se justifica.
- **"Con `skipLimit` el lote nunca falla."** Falla en el descarte `limit + 1`, y lo
  descartado antes desapareció si no había `SkipListener`.
- **"Pongo `@EnableBatchProcessing` porque así se hace."** En Boot apaga la
  autoconfiguración y la creación del esquema: no se escribe.
- **"Meto ocho hilos y va ocho veces más rápido."** Hasta que el pool dice basta o el
  reinicio deja de funcionar.

> **📝 Qué cambia en la línea 4.x.** Spring Boot 4 trae **Spring Batch 6**: el modelo sigue
> en pie —job, step, chunk, `JobRepository`— pero el `JobRepository` absorbe a `JobExplorer`,
> el `JobOperator` absorbe a `JobLauncher`, `@EnableBatchProcessing` se acompaña de
> `@EnableJdbcJobRepository` o `@EnableMongoJobRepository` y el transaction manager pasa a
> ser opcional. La migración completa vive en `A04`.

---

## 🧠 Preguntas rápidas

1. Explica en una frase qué hace un job de Spring Batch que un bucle dentro de un
   `@Scheduled` no hace, sin usar la palabra "framework".
2. ¿Qué distingue una `JobInstance` de una `JobExecution`, y cuál de las dos se crea cuando
   relanzas un job que falló anoche?
3. Escribe la ecuación que define la identidad de una `JobInstance` y di qué pasa si
   lanzas el job dos veces con los mismos parámetros identificadores tras un éxito.
4. ¿Por qué el chunk define la frontera de la transacción, y quién la abre exactamente?
5. Tu equipo añade un parámetro `run.id` con la marca de tiempo para poder relanzar el job
   cuando quiera. ¿Qué capacidad acaban de perder y por qué?
6. Nombra las dos tablas del `JobRepository` en las que mirarías primero para contestar
   "¿por dónde iba cuando se cayó?" y "¿cuántos registros descartó?".
7. Un `ItemReader` propio hace que el job, al reanudarse, duplique los primeros diez mil
   registros. ¿Qué le falta a ese reader?
8. ¿Cuándo eliges `skip` y cuándo `retry`? Da un ejemplo de cada uno que no se pueda
   intercambiar.
9. Con `skipLimit(10)`, ¿cuál es el descarte que hace fallar el step? ¿Y qué le falta a esa
   configuración para que el descarte no sea pérdida de datos?
10. El `ItemWriter` falla en el ítem 237 de un chunk de 500. Describe qué queda escrito en
    la base, qué pasa con los chunks anteriores y en qué cambia la respuesta si el step es
    `faultTolerant()`.
11. ¿Qué hace `allowStartIfComplete(true)` y en qué tipo de step **no** lo pondrías nunca?
12. De las cuatro formas de paralelizar un job, ¿cuál conserva intacta la semántica de
    reinicio, y por qué?
13. Arrancas tu API en producción y descubres que el job de conciliación corrió solo al
    levantar el servicio. ¿Quién lo lanzó y qué propiedad lo apaga?
14. Tres réplicas del servicio tienen el mismo `@Scheduled` que lanza el mismo job. ¿Qué
    pasa con la segunda y la tercera, y por qué esto no equivale a un scheduler
    distribuido?
15. Alguien defiende `chunk(1)` "para no perder nada si falla". Dale la versión precisa:
    qué gana, qué paga y con qué argumento se elige un tamaño.

---

## 📚 Referencias oficiales

- Spring Batch 5.2 — El lenguaje de dominio: `Job`, `JobInstance`, `JobExecution`, `ExecutionContext`: https://docs.spring.io/spring-batch/reference/5.2/domain.html
- Spring Batch 5.2 — Chunk-oriented processing y su configuración con los builders de la 5.x: https://docs.spring.io/spring-batch/reference/5.2/step/chunk-oriented-processing/configuring.html
- Spring Batch 5.2 — Configurar un step para reinicio (`allowStartIfComplete`, `startLimit`): https://docs.spring.io/spring-batch/reference/5.2/step/chunk-oriented-processing/restart.html
- Spring Batch 5.2 — Skip (`skipLimit`, `noSkip`, el descarte número once) y retry: https://docs.spring.io/spring-batch/reference/5.2/step/chunk-oriented-processing/configuring-skip.html
- Spring Batch 5.2 — Flujo entre steps (`next`, `on`, `split`): https://docs.spring.io/spring-batch/reference/5.2/step/controlling-flow.html
- Spring Batch 5.2 — Escalado y procesamiento paralelo: https://docs.spring.io/spring-batch/reference/5.2/scalability.html
- Spring Batch 5.2 — Esquema de metadatos (las seis tablas y el flag `IDENTIFYING`): https://docs.spring.io/spring-batch/reference/5.2/schema-appendix.html
- Spring Batch 5.2 — Métricas y monitorización: https://docs.spring.io/spring-batch/reference/5.2/monitoring-and-metrics.html
- Spring Batch — Guía de migración de 4.x a 5.0 (por qué el código viejo no compila): https://github.com/spring-projects/spring-batch/wiki/Spring-Batch-5.0-Migration-Guide
- Spring Boot 3.5 — Aplicaciones batch: arranque, parámetros y `@BatchDataSource`: https://docs.spring.io/spring-boot/3.5/how-to/batch.html
