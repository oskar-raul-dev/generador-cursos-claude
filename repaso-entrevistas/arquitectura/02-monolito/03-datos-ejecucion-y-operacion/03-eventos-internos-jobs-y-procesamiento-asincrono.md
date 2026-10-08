# 03 — Eventos internos, jobs y procesamiento asíncrono

Aprenderás a sacar trabajo del camino de la respuesta sin perderlo: qué garantía da cada mecanismo
asíncrono —evento en memoria, scheduler, tabla de trabajo, broker— y cuál necesita un efecto
obligatorio como avisar al cliente de que su pedido está confirmado.

## 1. 🎯 Síntoma y decisión

El p95 de `CreateOrder` sube de 180 ms a 1,2 s: el caso de uso envía el correo de confirmación en
línea y el proveedor de email está lento. El equipo mueve el envío a una tarea en memoria y la
latencia vuelve a su sitio. Tras el siguiente despliegue, soporte recibe quejas: 140 clientes con el
pedido confirmado y sin correo. En el pico de la campaña, además, la cola interna del executor
acumula miles de tareas y la memoria del proceso crece.

El arreglo separó el tiempo del trabajo, pero no lo conservó ni lo frenó. La decisión de este
capítulo es qué trabajo puede diferirse, qué mecanismo lo mantiene vivo y quién controla su ritmo.

## 2. 🧠 Modelo mental

Hay dos preguntas y no se responden con el mismo mecanismo. **¿Cuándo corre?** lo deciden un hilo,
una promesa o una goroutine. **¿Sobrevive si el proceso cae?** solo lo decide un almacenamiento que
comparta `COMMIT` con el cambio de negocio.

```text
¿perder el efecto es aceptable?
   ├─ sí → evento en memoria tras el commit: barato, sin rastro si se pierde
   └─ no → ¿quién lo consume?
            ├─ el propio monolito        → tabla de trabajo en el mismo COMMIT
            │                              + worker con lease, límite y deduplicación
            └─ otros procesos o equipos  → outbox + broker
```

Asíncrono no significa distribuido: un worker del mismo proceso que lee una tabla de la misma base
es asíncrono y no añade red, contratos ni despliegues. Y durable no significa una sola vez: la tabla
garantiza que el trabajo no se pierde; que el efecto ocurra una vez lo garantiza la deduplicación.

## 3. 🔍 Evidencia antes del diagnóstico

| Nivel | En el sistema de comercio |
|---|---|
| Observación | el 85 % del tiempo de `CreateOrder` estaba en la llamada al proveedor de email; los 140 pedidos sin correo se crearon en los 20 s previos a reinicios; la cola del executor llegó a miles de tareas en el pico |
| Inferencia | el trabajo diferido vive solo en memoria y la cola no tiene límite |
| Diagnóstico | se separó el tiempo sin conservar el trabajo ni controlar la presión |
| Recomendación | tabla de trabajo escrita en la transacción del pedido, worker con lease y concurrencia limitada, y aviso deduplicado por la clave del trabajo |

Las cifras son supuestos del ejercicio. Qué refutaría el diagnóstico: si los correos perdidos no
coinciden con reinicios, la causa puede estar en el proveedor —rebotes, filtros—, y hay que mirar sus
respuestas antes de tocar el mecanismo. La sección de código reproduce la pérdida en TypeScript y la
recuperación, con su doble ejecución, en Python.

## 4. 🛠️ Elegir la garantía, no solo el hilo

Un evento en memoria sirve para observadores prescindibles dentro de la misma ejecución. Si el
proceso cae después del commit y antes del callback, el evento se pierde. Para trabajo obligatorio,
`orders` guarda en la misma transacción una fila con identidad, tipo, payload mínimo y estado. Un
worker la reclama con lease, ejecuta y registra intento, resultado y próxima fecha.

| Mecanismo | Sobrevive caída | Presión y reintento | Cuándo basta |
|---|---|---|---|
| callback/evento en memoria | no | propios del proceso | telemetría prescindible |
| scheduler sin store | no necesariamente | limitado | trabajo reconstruible |
| tabla de trabajo | sí, si comparte commit | explícitos | volumen moderado y operación local |
| broker + outbox | sí, con publicación recuperable | infraestructura propia | consumidores o escala independientes |

El consumidor asume repeticiones: actualiza mediante una clave estable o una transición ya aplicada.
El orden solo se garantiza donde sea necesario, normalmente por pedido, no para toda la cola. Cuando
la dependencia se satura, el worker reduce concurrencia o rechaza producción; una cola que crece sin
límite convierte latencia en agotamiento de almacenamiento.

Introducir broker tiene sentido si compra aislamiento, fan-out durable o ownership independiente.
No hace distribuido al requisito original ni arregla por sí solo commit, idempotencia o poison jobs.

## 5. 💻 La garantía en código: TypeScript pierde, Python recupera

Dos ejemplos del mismo flujo: `CreateOrder` confirma el pedido y `NotifyCustomer` debe ocurrir
después. TypeScript muestra el fallo del aviso en memoria; Python, la tabla de trabajo que lo
sobrevive y el precio que cobra.

### TypeScript: la promesa no sobrevive al proceso

```typescript
// Aviso en memoria: se agenda después del commit y vive solo en este proceso
async function notifyCustomer(orderId: string): Promise<void> {
  await new Promise((resolve) => setTimeout(resolve, 50)); // latencia del canal de correo
  console.log(`notification sent for ${orderId}`);
}

function createOrder(orderId: string): string {
  // aquí ya se confirmó el pedido en la base
  void notifyCustomer(orderId); // fire-and-forget: nadie registra ni espera el trabajo
  return `order ${orderId} confirmed`;
}

console.log(createOrder("o-1"));
if (process.argv.includes("--crash")) process.exit(137); // despliegue, OOM o kill -9 tras responder
```

```bash
node fire-and-forget.ts
node fire-and-forget.ts --crash
```

- Node 24 ejecuta el `.ts` directamente, quitando los tipos; no hace falta compilar para correrlo.
- `--crash` termina el proceso justo después de responder, como lo haría un despliegue, un OOM o un
  `kill -9`. El código `137` imita el que la shell informa para un proceso terminado por `SIGKILL` (128 + 9).

```text
order o-1 confirmed
notification sent for o-1
```

```text
order o-1 confirmed
```

En la segunda corrida el cliente recibió la confirmación y el aviso no existe en ningún sitio: no hay
fila, ni log de error, ni reintento posible. `void` le dice al compilador que la promesa se ignora a
propósito; no la guarda. Omitir `await` es exactamente el mismo contrato, dicho con menos claridad.

### Python: tabla de trabajo con lease

```python
import sqlite3
import time

SCHEMA = """
CREATE TABLE IF NOT EXISTS orders (id TEXT PRIMARY KEY, status TEXT NOT NULL);
CREATE TABLE IF NOT EXISTS jobs (
  id          TEXT PRIMARY KEY,
  kind        TEXT NOT NULL,
  order_id    TEXT NOT NULL,
  status      TEXT NOT NULL DEFAULT 'PENDING',
  attempts    INTEGER NOT NULL DEFAULT 0,
  lease_until REAL NOT NULL DEFAULT 0
);
CREATE TABLE IF NOT EXISTS sent_notifications (job_id TEXT PRIMARY KEY, order_id TEXT NOT NULL);
"""


def create_order(db: sqlite3.Connection, order_id: str) -> None:
    # el pedido y su trabajo se confirman juntos, o no se confirma ninguno
    with db:
        db.execute("INSERT INTO orders VALUES (?, 'CONFIRMED')", (order_id,))
        db.execute("INSERT INTO jobs (id, kind, order_id) VALUES (?, 'NotifyCustomer', ?)",
                   (f"job-{order_id}", order_id))


def claim(db: sqlite3.Connection, lease_seconds: float):
    # reclama un trabajo pendiente o con lease vencido en una sola sentencia
    now = time.time()
    with db:
        return db.execute("""
            UPDATE jobs SET status = 'CLAIMED', attempts = attempts + 1, lease_until = ?
             WHERE id = (SELECT id FROM jobs
                          WHERE status = 'PENDING' OR (status = 'CLAIMED' AND lease_until < ?)
                          ORDER BY rowid LIMIT 1)
            RETURNING id, order_id, attempts""", (now + lease_seconds, now)).fetchone()


def notify_customer(db: sqlite3.Connection, job_id: str, order_id: str) -> None:
    # canal simulado que acepta la clave del trabajo: un segundo envío no duplica el aviso
    with db:
        db.execute("INSERT OR IGNORE INTO sent_notifications VALUES (?, ?)", (job_id, order_id))


def complete(db: sqlite3.Connection, job_id: str) -> None:
    with db:
        db.execute("UPDATE jobs SET status = 'DONE' WHERE id = ?", (job_id,))
```

- `with db:` abre y confirma una transacción de `sqlite3`; si algo lanza dentro, hace rollback. En
  `create_order` eso ata el pedido y su trabajo al mismo `COMMIT`: no existe un pedido confirmado sin
  aviso pendiente.
- `claim` reclama con un solo `UPDATE ... RETURNING`: marca el trabajo, suma el intento y fija el
  vencimiento del lease. Un trabajo `CLAIMED` con lease vencido vuelve a ser reclamable; eso es lo
  que recupera el trabajo de un worker muerto.
- `sent_notifications.job_id` es la clave de idempotencia del efecto. El canal real tiene que
  aceptar una clave equivalente; si no la acepta, la garantía honesta es *at-least-once* y el
  cliente puede recibir dos correos.

El arnés crea el pedido `o-1` y lanza un proceso *worker A* que reclama el trabajo con un lease de un
segundo, envía el aviso y muere con `os._exit(137)` **antes** de llamar a `complete`. Después, el
*worker B* intenta reclamar dos veces, antes y después de que venza el lease.

```bash
python3 demo.py
```

- `demo.py` borra y recrea `commerce.db`, así que cada corrida parte de cero.
- El *worker A* es un subproceso real: su muerte no deja nada en memoria compartida con B.

```text
worker A claimed ('job-o-1', 'o-1', 1)
worker A sent the notification and dies before complete()
worker B, lease still valid: None
worker B, lease expired:     ('job-o-1', 'o-1', 2)
jobs: [('job-o-1', 'DONE', 2)]
notifications: 1
```

El trabajo sobrevivió a la muerte del worker, y el segundo intento es visible (`attempts = 2`). El
efecto se ejecutó dos veces y el aviso llegó una, solo porque el efecto deduplica por la clave del
trabajo. Esa es la regla: **la tabla de trabajo garantiza que el trabajo no se pierde, no que ocurra
una sola vez**.

Los límites también se ven. Mientras el lease está vigente, nadie más avanza el trabajo: un lease
largo retrasa la recuperación, uno corto provoca dobles ejecuciones de workers lentos pero vivos.
SQLite serializa las escrituras, así que aquí el reclamo es atómico sin más; en PostgreSQL, varios
workers usan `SELECT ... FOR UPDATE SKIP LOCKED` para no pisarse. Y falta el trabajo venenoso: sin un
máximo de intentos, un aviso que siempre falla se reclama para siempre.

**Validación.** El 2026-09-29, el TypeScript se comprobó con `tsc 5.8.3 --strict` y corrió en Node
24.21.0; el Python corrió dos veces con Python 3.13.4 y SQLite 3.51.0, con salidas idénticas. Son
reproducciones locales en un solo nodo; no miden rendimiento.

## 6. 🧰 Plataformas

| Plataforma | Mecanismo relevante | Qué no resuelve | Trampa frecuente |
|---|---|---|---|
| Java | executor y scheduler; tabla/cola durable para garantías | un `Executor` no persiste trabajo | usar pool sin capacidad límite |
| Node/TypeScript | cola explícita; `setImmediate` solo difiere ejecución | una promesa no sobrevive al proceso | omitir `await` como fire-and-forget |
| Go | goroutines y canales con cancelación | un canal no es almacenamiento durable | crear goroutines sin límite |
| Python | `concurrent.futures` o scheduler; store durable | un task local no garantiza entrega | confundir submit con commit |

La columna «Qué no resuelve» dice lo mismo cuatro veces: el mecanismo de concurrencia del runtime
—executor, promesa, goroutine, future— decide **cuándo** corre el trabajo, no **si sobrevive**. Ninguna
plataforma da durabilidad por sí sola; la da escribir el trabajo en un almacenamiento que comparte
`COMMIT` con el cambio de negocio. Lo que sí cambia entre plataformas es cómo se limita la
concurrencia: pool con cola acotada, número fijo de workers, semáforo.

## 7. ⚖️ Decisión y coste

Persiste el trabajo obligatorio junto con el cambio de negocio y procésalo con un worker recuperable. Pagas demora, deduplicación, control de presión y operación del consumidor. Un evento en memoria basta únicamente si perderlo es aceptable. Introduce un broker cuando el volumen o los consumidores requieran capacidades que la tabla de trabajo no cubra; comprueba edad de pendientes y recuperación antes de ampliar la solución.

## ⚠️ Errores frecuentes

- «Asíncrono equivale a distribuido». Un worker en el mismo proceso, leyendo una tabla de la misma base, es asíncrono y no añade red ni contratos.
- «Fire-and-forget es entrega garantizada». Es entrega mientras el proceso viva; el ejemplo en TypeScript pierde el aviso con un solo `exit`.
- «La tabla de trabajo garantiza que el efecto ocurra una vez». Garantiza que no se pierde; un worker que muere después de enviar provoca un segundo intento, y solo la deduplicación evita el segundo aviso.
- «Una cola interna sin límite absorbe los picos». Los convierte en memoria agotada o en latencia que nadie ve hasta que el proceso cae.
- «Con un broker se resuelven commit, orden e idempotencia». El broker aporta transporte durable; publicar tras el commit, ordenar por clave y deduplicar siguen siendo tuyos.

## 8. ✅ Veredicto

Pregunta primero si perder el efecto es aceptable. Si lo es, un evento en memoria tras el commit
basta y es lo más simple. Si no, escríbelo en la misma transacción que el cambio de negocio y
procésalo con un worker que reclame con lease, limite su concurrencia, se rinda ante trabajos
venenosos y deduplique el efecto. Introduce un broker cuando otros procesos o equipos necesiten el
hecho, no para hacer asíncrono lo que ya lo es.

## 📚 Referencias

- [Node.js Event Loop](https://nodejs.org/learn/asynchronous-work/event-loop-timers-and-nexttick)
- [Go Concurrency Patterns: Context](https://go.dev/blog/context)
- [Python concurrent.futures](https://docs.python.org/3/library/concurrent.futures.html)
- [Python sqlite3: transacciones con el gestor de contexto](https://docs.python.org/3/library/sqlite3.html#sqlite3-connection-context-manager)
- [SQLite: RETURNING](https://sqlite.org/lang_returning.html)
- [PostgreSQL 17: SELECT, The Locking Clause](https://www.postgresql.org/docs/17/sql-select.html#SQL-FOR-UPDATE-SHARE)

## 🧠 Preguntas

1. 🟢 ¿Qué diferencia hay entre separar el tiempo de un trabajo y conservarlo?
2. 🟢 ¿Qué garantía da un evento en memoria y cuándo basta?
3. 🟢 ¿Por qué el trabajo obligatorio se escribe en la misma transacción que el cambio de negocio?
4. 🟢 ¿Qué es un lease y qué problema resuelve en una tabla de trabajo?
5. 🟢 ¿Qué significa *at-least-once* y por qué obliga a deduplicar el efecto?
6. 🟢 ¿Qué es *backpressure* y dónde aparece en un worker interno?
7. 🟡 ¿Por qué publicar un evento antes del commit es peligroso aunque el consumidor esté en el mismo proceso?
8. 🟡 ¿Cuándo elegirías un evento en memoria aunque ya exista una tabla de trabajo?
9. 🟡 En el ejemplo de Python, el worker A envió el aviso y murió. ¿Por qué el cliente recibió un solo aviso y qué lo habría duplicado?
10. 🟡 ¿Cómo elegirías la duración del lease?
11. 🟡 ¿Qué es un trabajo venenoso y cómo evitas que bloquee la cola?
12. 🟡 ¿Qué orden necesita realmente el sistema de ejemplo y por qué no conviene un orden global?
13. 🟡 ¿Qué métricas dicen si el worker va al día?
14. 🟡 ¿Qué cambia cuando dos réplicas ejecutan el mismo worker sobre la tabla?
15. 🟡 ¿Cuándo introducirías un broker con outbox en lugar de la tabla de trabajo?
16. 🟡 ¿Qué debe ver el cliente mientras el aviso está pendiente o fallando?
17. 🟡 ¿Qué garantía comparten un executor Java y una goroutine, y cuál requiere almacenamiento adicional?
18. 🟠 ¿Por qué omitir `await` en Node y hacer `submit` en Python no equivalen a entrega durable?
19. 🟠 Tras un despliegue, 140 pedidos confirmados no tienen aviso ni fila de trabajo. ¿Qué investigas y qué cambias?
20. 🟠 El proveedor de correo cae dos horas y la tabla acumula 30 000 trabajos. ¿Qué hace el worker durante la caída y qué pasa al volver?
21. 🟠 Un job programado se ejecuta dos veces al escalar a dos réplicas. ¿Cómo lo corriges sin volver a una sola réplica?
22. 🟠 Quieres reemplazar el envío en memoria por la tabla de trabajo sin perder avisos durante la transición. ¿Qué pasos reversibles darías?
23. 🟠 Un equipo quiere Kafka para las notificaciones y otro defiende la tabla de trabajo. ¿Cómo decidirías?
24. 🟠 ¿Qué criterio te diría que la tabla de trabajo ya no alcanza?

---

[Índice del bloque](README.md) · [Índice general](../README.md)

**Anterior:** [02 — Concurrencia, locking e idempotencia](02-concurrencia-locking-e-idempotencia.md).

**Siguiente:** [04 — Rendimiento, caché y escalado](04-rendimiento-cache-y-escalado.md).
