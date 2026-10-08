# 06 — Observabilidad y resiliencia del monolito

Aprenderás a localizar un fallo y a contener un recurso dentro de un proceso compartido: cómo
seguir un pedido a través de hilos y módulos, cómo impedir que un workload secundario se coma las
conexiones de checkout, y qué parte de eso es observabilidad y qué parte es resiliencia.

## 1. 🎯 Síntoma y decisión

Cada cierre de mes, finanzas lanza sus reportes y checkout falla en un 8 % de las peticiones durante
quince minutos. Los logs dicen `timeout acquiring connection`, sin identificador de pedido ni de
módulo: nadie puede decir quién retiene las conexiones. Para empeorar, el health check de liveness
consulta la base, falla, y el orquestador reinicia réplicas en plena saturación, con lo que el
tráfico se concentra en las que quedan.

Hay dos carencias distintas. No se ve quién consume el recurso, y nada impide que lo consuma todo. La
decisión de este capítulo es qué instrumentar para atribuir el consumo y qué límites poner para
contenerlo, antes de pensar en separar procesos.

## 2. 🧠 Modelo mental

```text
sin bulkhead: un pool, gana el primero que llega
checkout ──┐
reportes ──┼──► pool SQL ──► base        los reportes llenan el pool; checkout espera
jobs     ──┘

con bulkhead: capacidad repartida por workload
checkout ─────────────────► pool SQL ──► base
reportes ─► cupo propio ──┘               el cupo rechaza el sobrante en el acto
```

Observabilidad y resiliencia se necesitan, pero no se sustituyen. **Ver** es que cada operación
lleve su contexto —identificador de petición y de pedido— por todos los hilos que atraviesa, y que
las métricas digan qué módulo y qué resultado, con dimensiones acotadas. **Contener** es que cada
workload tenga presupuesto de tiempo, cupo de recursos y una degradación definida. Propagar contexto
no limita nada; poner cupos sin contexto limita a ciegas.

## 3. 🔍 Evidencia antes del diagnóstico

| Nivel | En el sistema de comercio |
|---|---|
| Observación | 8 % de errores en checkout durante quince minutos en cada cierre; `timeout acquiring connection` sin `order_id`; en `pg_stat_activity`, las conexiones ocupadas ejecutan consultas de reportes; reinicios de réplicas por liveness fallido durante el pico |
| Inferencia | reportes y checkout compiten por un pool sin cupos; el contexto se pierde al pasar a executors; liveness depende de la base |
| Diagnóstico | falta aislamiento de recursos y atribución, y el health check amplifica el incidente |
| Recomendación | cupo para reportes, presupuesto de espera para checkout, contexto propagado en cada salto de hilo y liveness sin dependencias externas |

Las cifras son supuestos del ejercicio. Qué refutaría el diagnóstico: si las conexiones las
retuviera el propio checkout con transacciones largas, un cupo para reportes no cambiaría nada y el
problema estaría en la frontera transaccional. La sección de código reproduce en Java el contexto
perdido y el pool agotado, y los corrige.

## 4. 🛠️ Ver el flujo y contener el recurso

Los logs registran eventos discretos; las métricas muestran tendencia y saturación; las trazas
atribuyen latencia a etapas. Los logs y las trazas se correlacionan mediante `request_id` o `order_id`. Las métricas usan
dimensiones acotadas, como versión, módulo y resultado; no usan identificadores únicos de petición
como etiquetas. Un exemplar puede vincular una medición con una traza sin crear una serie por pedido. Un SLO de checkout se mide en el
límite del usuario, aunque las señales internas expliquen qué módulo consume el presupuesto.

| Recurso compartido | Bulkhead interno | Degradación posible |
|---|---|---|
| conexiones SQL | pool o cuota por workload | rechazar reportes, conservar checkout |
| threads/executors | colas acotadas por clase | diferir notificaciones |
| memoria | límites de lote y streaming | respuesta parcial de reporting |
| dependencia remota | timeout dentro del budget | estado pendiente visible |

Un *bulkhead* separa capacidad, no código. Si reportes llena su propia cola, checkout conserva una
reserva de conexiones. Cuando esa reserva desperdicia demasiada capacidad o el runtime no permite
aislarla, mover el workload a otro proceso es un siguiente paso medible.

Liveness responde si el proceso debe reiniciarse; readiness, si puede recibir tráfico. Hacer que
liveness dependa de cada proveedor externo puede provocar reinicios masivos. Timeouts, retries y
circuit breaking comparten un presupuesto: repetir en cada capa multiplica carga durante el fallo.

## 5. 💻 Los dos fallos del síntoma, en Java

El síntoma de este capítulo tiene dos mitades: los logs no permiten seguir un pedido, y los reportes
agotan las conexiones de checkout. Un solo programa Java las reproduce y las corrige. El pool es un
**modelo**: un `Semaphore` de cuatro permisos hace el papel de las cuatro conexiones de un pool SQL,
porque lo que se demuestra es el reparto de capacidad, no el driver.

```java
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;
import java.util.concurrent.Semaphore;
import java.util.concurrent.TimeUnit;

public class Bulkhead {
    // Contexto de la petición en el hilo actual, como hace un MDC de logging
    static final ThreadLocal<String> ORDER_ID = new ThreadLocal<>();

    static void log(String msg) { System.out.printf("order_id=%s %s%n", ORDER_ID.get(), msg); }

    // Copia el contexto del hilo que envía al hilo que ejecuta, y lo limpia al terminar
    static Runnable withContext(Runnable task) {
        String captured = ORDER_ID.get();
        return () -> {
            ORDER_ID.set(captured);
            try { task.run(); } finally { ORDER_ID.remove(); }
        };
    }

    // Modelo de un pool de 4 conexiones SQL compartido por todo el proceso
    static final Semaphore SQL_POOL = new Semaphore(4);
    // Cupo propio de reportes: nunca más de 2 conexiones, y sin cola
    static final Semaphore REPORTS_QUOTA = new Semaphore(2);

    static void runReport(boolean bulkhead) {
        if (bulkhead && !REPORTS_QUOTA.tryAcquire()) { System.out.println("report rejected: quota full"); return; }
        try {
            SQL_POOL.acquire();
            try { Thread.sleep(300); } finally { SQL_POOL.release(); }   // consulta pesada
        } catch (InterruptedException e) {
            Thread.currentThread().interrupt();
        } finally {
            if (bulkhead) REPORTS_QUOTA.release();
        }
    }

    static void checkout() throws InterruptedException {
        long start = System.nanoTime();
        // presupuesto de checkout para obtener conexión: 150 ms
        if (!SQL_POOL.tryAcquire(150, TimeUnit.MILLISECONDS)) {
            log("checkout FAILED: no SQL connection within 150 ms");
            return;
        }
        try { log("checkout OK: connection after " + (System.nanoTime() - start) / 1_000_000 + " ms"); }
        finally { SQL_POOL.release(); }
    }

    static void scenario(String name, boolean bulkhead) throws Exception {
        System.out.println("--- " + name);
        try (ExecutorService reports = Executors.newFixedThreadPool(8)) {
            for (int i = 0; i < 8; i++) reports.submit(() -> runReport(bulkhead));
            Thread.sleep(50);                  // los reportes ya tomaron sus conexiones
            ORDER_ID.set("o-42");
            checkout();
            ORDER_ID.remove();
        }
    }

    public static void main(String[] args) throws Exception {
        try (ExecutorService io = Executors.newSingleThreadExecutor()) {
            System.out.println("--- context across an executor");
            ORDER_ID.set("o-42");
            log("checkout received");
            io.submit(() -> log("stock check in executor")).get();
            io.submit(withContext(() -> log("stock check in executor, context copied"))).get();
            ORDER_ID.remove();
        }
        scenario("shared pool, no bulkhead", false);
        scenario("reports limited to 2 connections", true);
    }
}
```

- `ORDER_ID` es un `ThreadLocal`, que es como guardan el contexto los MDC de logging en Java. Vive en
  el hilo que atiende la petición y **no** viaja solo a otro hilo.
- `withContext` captura el valor en el hilo que envía la tarea y lo restablece en el hilo que la
  ejecuta; el `finally` lo borra para que un hilo reutilizado del pool no arrastre el pedido anterior.
- `SQL_POOL` modela el recurso común. Sin *bulkhead*, ocho reportes piden conexión: cuatro la
  obtienen y la retienen 300 ms, y los otros cuatro esperan en la cola del mismo pool.
- `checkout` tiene un presupuesto de 150 ms para obtener conexión. Si no la obtiene, falla de forma
  explícita en lugar de esperar indefinidamente.
- `REPORTS_QUOTA` es el *bulkhead*: los reportes pasan primero por un cupo de dos, con `tryAcquire`
  sin espera. El sobrante se rechaza en el acto —la degradación elegida— y checkout encuentra
  conexiones libres.

```text
--- context across an executor
order_id=o-42 checkout received
order_id=null stock check in executor
order_id=o-42 stock check in executor, context copied
--- shared pool, no bulkhead
order_id=o-42 checkout FAILED: no SQL connection within 150 ms
--- reports limited to 2 connections
report rejected: quota full
report rejected: quota full
report rejected: quota full
report rejected: quota full
report rejected: quota full
report rejected: quota full
order_id=o-42 checkout OK: connection after 0 ms
```

La línea `order_id=null` es el log que no permite seguir el pedido: el trabajo ocurrió, pero nadie
puede atribuirlo. La corrección no es global: cada salto de hilo —executor, scheduler, callback de
un cliente HTTP— necesita la misma captura, y por eso las librerías de telemetría instrumentan los
executors en lugar de confiar en cada llamada.

El *bulkhead* conserva checkout a cambio de dos costes visibles: seis reportes rechazados y dos
conexiones que, en un día sin reportes, quedan sin uso para ellos. Que la reserva sea dos y no tres
es una decisión que se toma con la medición del pool y del SLO de compra, no con este ejemplo. Si el
cupo interno desperdicia demasiada capacidad o el runtime no permite aislarla, el siguiente paso es
el que menciona la sección anterior: reportes en otro proceso o contra una réplica.

**Validación.** El 2026-09-29 se compiló con `javac 25.0.4 -Xlint:all` sin advertencias y corrió tres
veces con salida idéntica. Es una reproducción local con un pool modelado; los 300 ms y los 150 ms
son supuestos del ejemplo, no mediciones.

## 6. 🧰 Plataformas

| Plataforma | Mecanismo relevante | Qué no resuelve | Trampa frecuente |
|---|---|---|---|
| Java | contexto de request, métricas JVM y pools acotados | MDC puede perderse al cambiar executor | un pool global para todo |
| Node/TypeScript | `AsyncLocalStorage`, métricas de event loop | contexto no limita recursos | crear promesas sin cancelación |
| Go | `context.Context`, métricas y límites de goroutines | context no debe guardar dependencias opcionales | ignorar deadlines |
| Python | `contextvars`, logging y executors acotados | contexto no es un bulkhead | compartir pool sin cuotas |

Las cuatro filas separan dos cosas que suelen confundirse: propagar contexto y limitar recursos.
MDC, `AsyncLocalStorage`, `context.Context` y `contextvars` dicen **quién** consume; ninguno impide que
consuma de más. Para eso hacen falta pools, cupos y colas acotadas, que en cada plataforma se
configuran aparte. `context.Context` es la excepción parcial: sus deadlines sí acotan tiempo, pero no
reparten capacidad entre workloads.

## 7. ⚖️ Decisión y coste

Correlaciona el flujo y limita el consumo de cada carga mediante presupuestos de tiempo, cuotas y colas acotadas. Conservas capacidad para checkout a cambio de reservas de recursos y rechazo explícito de trabajo secundario. Si el aislamiento interno no contiene el incidente, compara un worker o proceso separado. Verifica la mejora provocando saturación de reportes y midiendo el SLO de compra.

## ⚠️ Errores frecuentes

- «La observabilidad solo importa en sistemas distribuidos». En un monolito, sin correlación por operación tampoco se sabe qué módulo retiene el pool.
- «Un `order_id` como etiqueta de métrica permite seguir el pedido». Crea una serie por pedido y hunde el sistema de métricas; el identificador va en logs y trazas.
- «El contexto viaja solo». Cada salto de hilo, executor o callback lo pierde si nadie lo copia; el ejemplo muestra `order_id=null`.
- «Liveness debe comprobar la base y el proveedor». Si depende de algo externo, una caída ajena reinicia todas las réplicas y agrava el incidente.
- «Reintentar en cada capa da resiliencia». Multiplica la carga justo cuando la dependencia está peor; timeouts y reintentos comparten un único presupuesto.

## 8. ✅ Veredicto

Haz que cada operación sea atribuible —contexto en logs y trazas, métricas con dimensiones
acotadas— y que ningún workload secundario pueda consumir sin límite un recurso que checkout
necesita. Empieza por cupos y presupuestos dentro del proceso, y comprueba la mejora provocando el
mismo incidente. Separa el workload en otro proceso cuando el cupo desperdicie demasiada capacidad o
el runtime no permita aislarlo.

## 📚 Referencias

- [OpenTelemetry Concepts](https://opentelemetry.io/docs/concepts/)
- [Node.js Async Context](https://nodejs.org/api/async_context.html)
- [Go context package](https://pkg.go.dev/context)
- [Python contextvars](https://docs.python.org/3/library/contextvars.html)
- [Java 25: ThreadLocal](https://docs.oracle.com/en/java/javase/25/docs/api/java.base/java/lang/ThreadLocal.html)
- [Java 25: Semaphore](https://docs.oracle.com/en/java/javase/25/docs/api/java.base/java/util/concurrent/Semaphore.html)

## 🧠 Preguntas

1. 🟢 ¿Qué pregunta responde cada señal: logs, métricas y trazas?
2. 🟢 ¿Qué es un *bulkhead* y qué separa?
3. 🟢 ¿Qué diferencia hay entre liveness y readiness?
4. 🟢 ¿Qué es un presupuesto de tiempo (*timeout budget*) en una petición?
5. 🟢 ¿Por qué un identificador de pedido va en logs y trazas y no como etiqueta de una métrica?
6. 🟢 ¿Qué significa degradar de forma explícita?
7. 🟡 ¿Por qué medir solo la CPU agregada es una simplificación peligrosa?
8. 🟡 ¿Cuándo moverías los reportes a un worker o proceso separado en lugar de ponerles un cupo?
9. 🟡 En el ejemplo Java, ¿por qué la línea del executor muestra `order_id=null` y qué hace `withContext`?
10. 🟡 ¿Por qué `withContext` limpia el valor en un `finally`?
11. 🟡 ¿Qué cuesta reservar conexiones para checkout con un cupo para reportes?
12. 🟡 ¿Por qué el cupo de reportes usa `tryAcquire` sin espera y checkout espera hasta 150 ms?
13. 🟡 ¿Qué pasa si liveness comprueba la base durante una saturación del pool?
14. 🟡 ¿Cómo se reparten timeouts y reintentos entre capas sin multiplicar la carga?
15. 🟡 ¿Qué es un exemplar y qué problema resuelve?
16. 🟡 ¿Qué SLO definirías para checkout y dónde lo medirías?
17. 🟡 ¿Qué problema común resuelven MDC/telemetría en Java y `context.Context` en Go, y cuál no resuelven?
18. 🟠 ¿Qué se pierde al propagar contexto en Node o Python si los pools siguen sin cuotas?
19. 🟠 Cada cierre de mes checkout falla un 8 % durante quince minutos. ¿Qué harías antes del próximo cierre?
20. 🟠 Durante un incidente, el orquestador reinicia réplicas en cadena por health checks fallidos. ¿Qué haces primero?
21. 🟠 Un cambio de librería HTTP hace que las trazas de `payments` aparezcan desconectadas del pedido. ¿Cómo lo detectarías y lo corregirías?
22. 🟠 Quieres introducir cupos por workload en producción. ¿Cómo lo harías de forma reversible?
23. 🟠 Un equipo quiere sacar los reportes a una réplica de lectura y otro prefiere un cupo en el proceso. ¿Cómo decidirías?
24. 🟠 ¿Qué criterio te diría que el aislamiento interno ya no alcanza?

---

[Índice del bloque](README.md) · [Índice general](../README.md)

**Anterior:** [05 — Despliegues, migraciones de esquema y rollback](05-despliegues-migraciones-de-esquema-y-rollback.md).

**Siguiente:** [07 — Estrategia de pruebas y evidencia de modularidad](07-estrategia-de-pruebas-y-evidencia-de-modularidad.md).
