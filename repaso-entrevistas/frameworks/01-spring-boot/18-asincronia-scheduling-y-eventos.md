# 18 — Asincronía, scheduling y eventos

> **Objetivo:** sacar trabajo del hilo del request sin perderlo, sin duplicarlo y sin
> perder el contexto — y poder decir en voz alta en qué hilo corre cada cosa.
> **Asume:** [`05`](05-proxies-y-aop.md), [`08`](08-modelo-de-ejecucion-web.md) y [`16`](16-transacciones.md).
> **Vigencia:** 18 de septiembre de 2026 · Spring Boot 3.5.16 · Spring Framework 6.2.19 · Java 21.

**Alcance recortado y declarado:** aquí solo hay asincronía **dentro de un proceso**. Colas,
brokers y outbox son diseño y solo aparecen como el límite de lo que esto garantiza (§9).

---

## 1. 🧭 El problema: trabajo que no cabe en el request

`inv-api` registra un movimiento: escribir la fila tarda 4 ms, y reconstruir la proyección y
avisar al proveedor tardan 1 200 ms más, casi todos de espera a otros. El cliente no necesita
nada de eso para saber que quedó grabado, pero espera 1 204 ms y tú retienes un hilo de Tomcat
([`08` §2](08-modelo-de-ejecucion-web.md#2--una-instancia-muchos-hilos)). Spring da tres herramientas, y no son intercambiables:

```text
@Async      → "esto lo hace otro hilo"                  lo dispara una llamada
@Scheduled  → "esto pasa cada N"                        lo dispara el reloj
eventos     → "esto pasó, que reaccione quien quiera"   lo dispara un hecho
```

La confusión más común es creer que la tercera implica la primera. No la implica: **los
eventos de Spring son síncronos** (§8).

---

## 2. 🧱 `@Async`: quién lo ejecuta y qué devuelve

```java
@Service
class ProjectionService {

    @Async("inventoryExecutor")                 // nombre del bean executor
    CompletableFuture<Integer> refresh(String sku) {
        return CompletableFuture.completedFuture(rebuild(sku));   // el trabajo lento
    }
}
```

- **Falta `@EnableAsync`** en alguna `@Configuration`, y sin él `@Async` es un comentario
  decorado: no hay proxy, el método corre en el hilo del llamante y **no avisa**. Boot no lo
  activa por ti: la autoconfiguración crea el executor, no el `@EnableAsync`.
- **`@Async("inventoryExecutor")`** elige el executor por nombre de bean; sin nombre usa el
  de §4. Y con dos candidatos de tipo `TaskExecutor` sin cualificar **no falla el arranque**:
  `AsyncExecutionAspectSupport.getDefaultExecutor()` atrapa la `NoUniqueBeanDefinitionException`,
  prueba con el bean llamado `taskExecutor` y, si tampoco existe, lo dice en un log de nivel
  **INFO** y devuelve `null`; el interceptor cae entonces a un `SimpleAsyncTaskExecutor` nuevo,
  sin pool y con **un hilo por tarea**. No hay fallo: hay degradación silenciosa ⏱️, visible en
  el thread dump y no en el log.
- **`CompletableFuture.completedFuture(...)`** devuelve el valor ya resuelto, pero el proxy
  lo desenvuelve y entrega al llamante **otro** future; que el tuyo esté completo no vuelve
  síncrona la llamada. Y el método es package-private y funciona porque el proxy es CGLIB:
  con `private` no funcionaría nunca ([`05` §6](05-proxies-y-aop.md#6--lo-que-un-proxy-no-puede-interceptar)).

Los tres retornos se distinguen por **quién ve el error**: con `void`, nadie salvo el handler
de §3; con `Future<T>`, quien llame a `get()` bloqueándose —heredado, evítalo—; y con
`CompletableFuture<T>`, quien encadene o haga `join()`, el default del curso.

> Nunca respondas: ~~"le pongo `@Async` y ya corre en paralelo"~~
>
> Mejor: "`@Async` no crea concurrencia: **delega la ejecución a un executor**. Si ese
> executor tiene un hilo, o la llamada es interna y no pasa por el proxy, no hay nada paralelo
> — hay un cambio de nombre de hilo, o ni eso."

---

## 3. ⚠️ Las dos formas de que `@Async` no haga nada

**La self-invocation**, idéntica a la de `@Transactional` y por la misma razón: el proxy
envuelve al objeto desde fuera y `this.refresh(sku)` se lo salta entero, sin excepción, sin log
y sin hilo nuevo ([`05` §5](05-proxies-y-aop.md#5-️-self-invocation-el-fallo-silencioso-número-uno)). **Y el `void`**, que se traga la excepción y deja al llamante sin nada.

```java
@Configuration
@EnableAsync
class AsyncConfig implements AsyncConfigurer {

    @Override   // este handler solo se consulta en métodos @Async que devuelven void
    public AsyncUncaughtExceptionHandler getAsyncUncaughtExceptionHandler() {
        return (ex, method, params) -> log.error("async falló en {}", method.getName(), ex);
    }
}
```

- **`AsyncConfigurer`** deja sobrescribir el executor por defecto y el handler, y se
  implementa en la misma clase que lleva `@EnableAsync`.
- **Solo aplica al retorno `void`.** Con `CompletableFuture` la excepción viaja **dentro**
  del future: la ves al hacer `join()` o con `.exceptionally(...)`, y si nadie lo consulta
  se pierde igual. El default, `SimpleAsyncUncaughtExceptionHandler`, sí loguea en `ERROR`,
  pero **sin el contexto de tu request** —sin `traceId`, sin usuario— (§5).

> **🧠 Modelo mental.** Un `void` asíncrono dice "confío en que esto no falla nunca". Como
> eso es falso, el handler es la única red que queda.

---

## 4. ⏱️ El executor: los tres números y la cola traicionera

Si no declaras nada, Boot autoconfigura un `applicationTaskExecutor` que es un
`ThreadPoolTaskExecutor`, y sus valores por defecto son justo los que producen el bug:

```yaml
spring:
  task:
    execution:
      pool:
        core-size: 8                # hilos que se crean y se quedan (default: 8)
        max-size: 16                # techo (default: Integer.MAX_VALUE)
        queue-capacity: 100         # cola de espera (default: Integer.MAX_VALUE)
      thread-name-prefix: inv-task- # para reconocerlo en un thread dump
      shutdown:
        await-termination: true     # ejecuta lo encolado en vez de descartarlo
        await-termination-period: 30s   # y el techo de espera; sin esto no hay techo
```

**`core-size` es el número que de verdad gobierna tu concurrencia**, por lo que viene a
continuación. Y **`await-termination` no va solo**: sin él, un `SIGTERM` mata el pool y vacía
la cola; con él pero sin `await-termination-period`, el executor se compromete a ejecutar
**toda** la cola mientras el resto del contexto se cierra en paralelo —tus tareas pueden
encontrarse el `DataSource` ya cerrado— y nada acota ese drenaje, que dura lo que la cola mida.
El periodo es el techo: el apagado bloquea esos 30 s como máximo. Ahora el reparto:

```text
tarea nueva → ¿hilos < core?        → crea hilo
            → si no, ¿cabe en cola? → ENCOLA        ← aquí se queda casi siempre
            → si no, ¿hilos < max?  → crea hilo
            → si no                 → política de rechazo
```

**`ThreadPoolTaskExecutor` llena la cola ANTES de crecer hasta `max`.** Con la cola por
defecto —ilimitada— "la cola está llena" no ocurre jamás y `max-size` **nunca se alcanza**: tu
pool de "hasta dos mil millones de hilos" son ocho hilos y una cola que crece hasta el heap.

> **⏱️ Los tres números, en unidades.** Cada hilo de plataforma reserva ~1 MB de stack:
> `core-size: 8` son ~8 MB y un `max-size: 200` alcanzado, ~200 MB. Cada elemento de la cola es
> un objeto vivo que retiene lo que la tarea capturó, así que una cola ilimitada no es "sin
> límite": es un `OutOfMemoryError` diferido, tras horas aceptando trabajo sin hacerlo.

Acotar la cola obliga a elegir política de rechazo: **`AbortPolicy`** (el default) lanza
`TaskRejectedException` al llamante y es ruidosa, que aquí es bueno; **`CallerRunsPolicy`**
ejecuta la tarea en el hilo que la envió, backpressure real que a la vez bloquea el request
que creías haber liberado; y **`DiscardPolicy`/`DiscardOldestPolicy`** tiran trabajo callando.

**Los virtual threads cambian la conversación** ([`12`](12-reactivo-bloqueante-y-virtual-threads.md)): con
`spring.threads.virtual.enabled=true` el executor de `@Async` pasa a ser un
`SimpleAsyncTaskExecutor` que estrena un virtual thread por tarea, sin pool y sin cola. Los tres
números desaparecen con el recurso escaso, y con ellos el límite que te protegía: el control
se muda al bulkhead ([`19` §6](19-resiliencia.md#6--bulkhead-y-rate-limiter)).

> **📝 Cuidado con la respuesta "clásica".** Toda fuente anterior a **Boot 2.1** —que es
> cuando aparece `TaskExecutionAutoConfiguration` con su `applicationTaskExecutor`— dice que
> el executor por defecto de `@Async` es `SimpleAsyncTaskExecutor` y que **crea un hilo nuevo
> por tarea sin reutilizar ninguno**. Sigue siendo cierto en Spring Framework a secas, no en Boot:
> son comportamientos opuestos bajo carga. En **Boot 3.2** reaparece sin pool, con los virtual threads.

---

## 5. 🧱 Propagación de contexto: lo que se queda en el hilo del request

El `SecurityContext`, el `traceId` del MDC y el `RequestContextHolder` viven en `ThreadLocal`,
y un `ThreadLocal` **no cruza a otro hilo**; el mecanismo está en
[`08` §8](08-modelo-de-ejecucion-web.md#8--threadlocal-el-contexto-que-viaja-pegado-al-hilo) y aquí solo toca el salto de hilo. Sus tres síntomas: perder el `SecurityContext` da
una `AccessDeniedException` con el mismo usuario que sí tenía el rol; perder el MDC deja logs
huérfanos; y perder el `RequestContextHolder` da `IllegalStateException: No thread-bound
request found`. Se propaga así:

```java
@Bean("inventoryExecutor")
TaskExecutor inventoryExecutor() {
    ThreadPoolTaskExecutor executor = new ThreadPoolTaskExecutor();   // tamaños de §4
    // copia el contexto del hilo que envía al hilo que ejecuta
    executor.setTaskDecorator(new ContextPropagatingTaskDecorator());
    executor.initialize();
    return new DelegatingSecurityContextAsyncTaskExecutor(executor);
}
```

- **`TaskDecorator`** es el gancho oficial: envuelve cada `Runnable` antes de entregarlo al
  pool, en el hilo del llamante, que es donde el contexto todavía existe. Y
  **`ContextPropagatingTaskDecorator`** (Framework 6.1+) usa Micrometer Context Propagation para
  arrastrar lo registrado —observación, `traceId`, MDC— y exige esa dependencia.
- **`DelegatingSecurityContextAsyncTaskExecutor`** copia el `SecurityContext` de Security y se
  pone **por fuera**, decorando al pool ya configurado. Y **`initialize()`** es obligatorio al
  construir el pool a mano: sin esa llamada la primera tarea revienta.
- **Declarar este bean apaga el `applicationTaskExecutor`.** Los de
  `TaskExecutionAutoConfiguration` llevan `@ConditionalOnMissingBean(Executor.class)`: con un
  `Executor` propio, el de §4 deja de crearse y los `spring.task.execution.*` no aplican a
  nadie —por eso este pool trae sus tamaños a mano—. Para tener los dos,
  `spring.task.execution.mode=force` (Boot 3.4+).
- **Lo que no se ve aquí:** propagar **copia**, no comparte. Si alguien limpia el
  `SecurityContextHolder` al terminar el request, tu copia sigue viva en el otro hilo.

---

## 6. 🧱 `@Scheduled`: el reloj, y el pool de un solo hilo

```java
@Component
class ReconciliationJob {

    @Scheduled(fixedDelay = 30_000)                                 // milisegundos
    void drainPending() { … }

    @Scheduled(cron = "0 15 3 * * *", zone = "America/Bogota")      // 03:15:00
    void nightlyReconcile() { … }
}
```

- **`fixedDelay`** cuenta desde que **termina** una ejecución hasta que empieza la siguiente:
  se autorregula si el trabajo se alarga, y por eso es el default sensato. **`fixedRate`**
  cuenta de **inicio a inicio**: si la tarea tarda más que el periodo el scheduler no las
  solapa pero **acumula retraso**, y al acelerarse dispara varias seguidas para ponerse al día.
- **`cron` son seis campos, no cinco**: segundo, minuto, hora, día del mes, mes, día de la
  semana. Pegar una de Unix de cinco es de los **pocos fallos ruidosos** de esta familia:
  `CronExpression.parse()` cuenta los campos antes de interpretarlos y el contexto no arranca,
  con `IllegalArgumentException: Cron expression must consist of 6 fields (found 5 in "15 3 *
  * *")`. El desplazamiento silencioso es el otro: **el campo de segundos va primero**, así
  que `0 15 3 * * *` son las 03:15:00 y `15 3 * * * *`, el segundo 15 del minuto 3 de cada hora.
- **`zone` es imprescindible.** Sin él manda la zona por defecto de la JVM, que en un contenedor
  suele ser UTC: tu "cierre de las 3 de la mañana" corre a las 10 de la noche. Y con horario de
  verano, un cron a las 2:30 corre dos veces un domingo al año y ninguna otro.
- **Falta `@EnableScheduling`**, igual que con `@EnableAsync`, y el método tiene que ser sin
  argumentos: el contenedor no tiene de dónde sacarlos.

> **⚠️ `spring.task.scheduling.pool.size` vale 1.** *Todas* las tareas `@Scheduled` de la
> aplicación —las tuyas y las de tus librerías— comparten **un único hilo**: una que tarda 40
> segundos retrasa otros 40 a todas las demás. El síntoma desconcierta —un job que "se salta
> ejecuciones" sin un solo error en su log— porque el culpable está en otra clase.

```yaml
spring:
  task:
    scheduling:
      pool:
        size: 4                      # tantos como jobs puedan solaparse
      thread-name-prefix: inv-sched-
```

- **`size`** se dimensiona por cuántos jobs pueden coincidir en el tiempo, no por cuántos
  tienes; y **`thread-name-prefix`** distingue el scheduler del executor de `@Async` en un
  thread dump. Son pools **distintos** a propósito: compartirlos deja que un `@Async` lento
  bloquee el reloj ⏱️.
- **Subir el pool no solapa una tarea consigo misma.** El scheduler nunca ejecuta dos veces a
  la vez el mismo método; para eso hay que combinarlo con `@Async`, y ahí pierdes esa garantía.

---

## 7. ⚠️ Tres réplicas, tres ejecuciones

El cron corre en cada JVM que tenga la clase: tres pods de `inv-api` son tres relojes
independientes, y a las 3:15 los tres empiezan la misma reconciliación.

> Nunca respondas: ~~"`@Scheduled` se ejecuta una vez aunque haya tres réplicas"~~
>
> Mejor: "`@Scheduled` es **local al proceso**. Con N instancias hay N ejecuciones, y si el job
> no es idempotente, eso es N veces el daño. Para ejecutarlo una sola vez hace falta un **lock
> distribuido**, que Spring no trae."

Las salidas, en orden de coste: **hacer el job idempotente** y dejar que corra N veces —si la
tarea es "recalcular la proyección del SKU", tres ejecuciones dan el mismo resultado—; **un
lock distribuido**, donde el estándar de hecho es **ShedLock**, pequeño y sin obligarte a
Spring Cloud entero para tomar un lock sobre una tabla o sobre Redis; o **un scheduler
externo** cuando la ejecución ya es una operación de negocio con su auditoría. ShedLock tampoco
garantiza nada: si quien tomó el lock muere a la mitad, esa ejecución se pierde hasta mañana.

---

## 8. 🧱 Eventos de aplicación: síncronos por defecto

El publicador no conoce a los consumidores: publica un hecho y reacciona quien quiera. Eso
desacopla el código y **no desacopla la ejecución**.

```java
// un record basta: desde Spring 4.2 el evento no extiende ApplicationEvent
record InventoryRecorded(String sku, int delta) { }

// dentro de InventoryService, con el publisher inyectado por constructor
void record(String sku, int delta) {
    publisher.publishEvent(new InventoryRecorded(sku, delta));   // no vuelve hasta
}                                                                // que todos terminen
```

- **`ApplicationEventPublisher`** se inyecta por constructor: lo implementa el propio
  `ApplicationContext`, así que siempre hay uno.
- **`publishEvent` no vuelve hasta que todos los `@EventListener` terminaron.** Corren en el
  hilo del publicador, dentro de su transacción si la hay, y **la excepción de un listener
  sube al publicador** y provoca el rollback. Esto no es una cola. **`@Order`** ordena entre
  ellos; si de verdad lo necesitas, querías una llamada a un método.

> Nunca respondas: ~~"uso eventos de Spring para desacoplar y que sea asíncrono"~~
>
> Mejor: "el `ApplicationEventMulticaster` por defecto es **síncrono**: desacopla en
> compilación, no en ejecución. Se vuelve asíncrono solo si pongo `@Async` en el listener, y
> entonces pierdo la propagación de la excepción y el contexto del hilo."

Poner `@Async` sobre un `@EventListener` cambia tres cosas: el listener pasa al executor de §4,
la excepción deja de llegar al publicador (§3) y el `traceId` se queda atrás (§5).

---

## 9. 🧱 El evento que espera al commit

El caso real no es "evento sí o no": es **publicar un efecto externo sin que salga si la
transacción se revierte**. El mecanismo, con su fase y su hilo, ya está en [`16` §8](16-transacciones.md#8--el-límite-de-la-transacción-no-es-el-límite-de-tu-método); aquí
se añade lo que allí no hacía falta:

- **Las cuatro fases.** `BEFORE_COMMIT` aún puede vetar el commit lanzando; `AFTER_COMMIT`
  (el default) es el puente al exterior; `AFTER_ROLLBACK` compensa; `AFTER_COMPLETION` corre
  pase lo que pase sin saber cuál de las dos ocurrió.
- **Sin transacción activa, el listener no se ejecuta en absoluto.** Ni excepción ni warning:
  el test que publica el evento fuera de una transacción "pasa" sin haber probado nada, y
  `fallbackExecution = true` es lo que lo salva.
- **`AFTER_COMMIT` + `@Async` es la combinación que casi siempre quieres**: el commit ya
  ocurrió, el hilo del request queda libre y el efecto externo —correo, proyección, llamada al
  proveedor— no retiene la conexión de base de datos ⏱️.
- **El límite, dicho otra vez porque en banca importa:** entre el commit y el listener no
  hay atomicidad. Si el proceso muere ahí el evento se perdió, y la respuesta es el outbox.

> **📝 Y el trabajo de arranque, que no es ninguno de los tres.** Para lo que pasa **una vez,
> al arrancar** —precargar un caché, validar una credencial— están `ApplicationRunner`
> (argumentos ya parseados) y `CommandLineRunner` (crudos), que corren con el contexto listo,
> **en el hilo `main` y bloqueando**: lo que tarde ahí es arranque, y lo que lance ahí impide
> arrancar ⏱️ ([`06`](06-arranque-y-autoconfiguracion.md)).

---

## 10. ⚠️ Errores frecuentes

- **"`@Async` lo hace concurrente."** Lo delega a un executor. Sin `@EnableAsync`, o llamándolo
  desde el mismo bean, corre en tu hilo sin decir nada. Y los eventos, igual: son síncronos.
- **"Subí `max-size` a 200 y sigue igual."** Con la cola ilimitada nunca pasa de `core-size`.
- **"El `@Async` falló pero no hay excepción."** Devuelve `void`: queda el log por defecto, sin
  `traceId`. Y si no hay usuario en ese hilo, es el `ThreadLocal` que nadie propagó.
- **"Un `CompletableFuture` y un `.join()` justo después."** Es una llamada síncrona con pasos
  extra, ocupando dos hilos en vez de uno.

---

## 🧠 Preguntas rápidas

1. ¿Qué hace `@EnableAsync` y qué ocurre si anotas con `@Async` sin haberlo puesto?
2. Explica por qué un `@Async` llamado desde otro método de la misma clase corre en el hilo
   del llamante, y nombra la salida preferible.
3. Tu método `@Async` devuelve `void` y lanza. ¿Quién se entera, y qué cambia con
   `CompletableFuture`?
4. Con `core-size: 8`, `max-size: 200` y la cola por defecto, ¿cuántos hilos llegas a tener?
5. ¿En qué se diferencian `AbortPolicy` y `CallerRunsPolicy`, y qué riesgo tiene la segunda?
6. Con virtual threads como executor de `@Async`, ¿qué problema desaparece y cuál aparece?
7. Tu `@Async` lanza `AccessDeniedException` con un usuario que sí tiene el rol. ¿Por qué?
8. Diferencia `fixedRate` de `fixedDelay` y di cuál eliges si la duración es variable.
9. Un `@Scheduled` tuyo "se salta ejecuciones" y su log no muestra ningún error. ¿Qué miras
   primero?
10. ¿Cuántos campos tiene un cron de Spring y qué pasa si pegas uno de Unix de cinco?
11. Tienes tres réplicas de `inv-api` y un job nocturno. Enumera las tres salidas posibles y
    di cuándo eliges cada una.
12. "Los eventos de Spring son asíncronos": corrige la frase y di en qué hilo, dentro de qué
    transacción y con qué efecto sobre el publicador corre un `@EventListener` que lanza.
13. ¿Qué ocurre con un `@TransactionalEventListener` sin transacción activa, y qué atributo
    lo cambia?

---

## 📚 Referencias oficiales

- Spring Framework 6.2 — Task execution y scheduling (`@Async`, `@Scheduled`, `TaskExecutor`, `TaskScheduler`): https://docs.spring.io/spring-framework/reference/6.2/integration/scheduling.html
- Spring Framework 6.2 — Eventos del `ApplicationContext` y `@EventListener`: https://docs.spring.io/spring-framework/reference/6.2/core/beans/context-introduction.html
- Spring Framework 6.2 — Eventos ligados a la transacción (`@TransactionalEventListener`): https://docs.spring.io/spring-framework/reference/6.2/data-access/transaction/event.html
- Spring Boot 3.5 — Ejecución de tareas y scheduling (`spring.task.*`, virtual threads): https://docs.spring.io/spring-boot/3.5/reference/features/task-execution-and-scheduling.html
- Spring Boot 3.5 — `ApplicationRunner` y `CommandLineRunner`: https://docs.spring.io/spring-boot/3.5/reference/features/spring-application.html
- Spring Security 6.5 — Propagación del `SecurityContext` a otros hilos: https://docs.spring.io/spring-security/reference/6.5/servlet/integrations/concurrency.html

### Documentación de terceros

- Micrometer Context Propagation — el mecanismo detrás de `ContextPropagatingTaskDecorator`: https://docs.micrometer.io/context-propagation/reference/
- ShedLock — lock distribuido para `@Scheduled` con múltiples instancias: https://github.com/lukas-krecan/ShedLock
- Java SE 21 — `ThreadPoolExecutor`, su política de cola y las de rechazo: https://docs.oracle.com/en/java/javase/21/docs/api/java.base/java/util/concurrent/ThreadPoolExecutor.html
