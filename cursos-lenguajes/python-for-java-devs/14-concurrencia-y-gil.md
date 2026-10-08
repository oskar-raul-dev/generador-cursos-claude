# 🧵 Fase 14 ⭐ — Concurrencia y el GIL

> Python para desarrolladores Java senior · Fase 14 de 18 · Bloque C
> Depende de: Fase 13 · Habilita: Fase 15
> Registro de esta fase: **aplicación**
> Proyecto que avanza: **los tres** — el CLI, la API y el back-office
> Fecha de verificación de las versiones: 12/09/2026

---

## 🎯 1. Propósito

Esta es la fase donde tu instinto de Java es **más fuerte y más inútil**, y donde todo se decide
midiendo.

Llevas once años con hilos, `synchronized`, `ConcurrentHashMap` y pools configurados con criterio.
Todo eso es conocimiento real y aquí casi nada aplica igual — no porque Python sea peor, sino
porque las dos preguntas que importan tienen respuestas distintas: **qué te compra un hilo** y
**dónde vive el estado que hay que proteger**.

Y la fase trae **dos mediciones, no una**: la misma carga de CPU y la misma de E/S en las mismas
formas. **El veredicto se invierte entre las dos, y esa inversión es la lección.** Quien se lleve
una sola de las dos tablas se lleva media fase y una conclusión equivocada.

---

## ✅ 2. Qué queda listo al terminar

- [ ] Puedes explicar qué es el GIL exactamente, y —más importante— **qué no es**.
- [ ] Sabes para qué sirven los hilos en Python y para qué no, con el número de cada caso.
- [ ] Reconoces el error de bloquear el bucle de eventos y sabes qué le cuesta, medido.
- [ ] Sabes qué cambia de verdad con el intérprete sin GIL, sin entusiasmo y sin desdén.
- [ ] El caso de las 3:40 está resuelto **en la base de datos**, y sabes por qué un `Lock` no
      servía.
- [ ] Puedes elegir el modelo de concurrencia para un encargo nuevo y defenderlo con una tabla.
- [ ] El miniproyecto de la sección 7 corre y cumple sus criterios de aceptación.

---

## 🚫 3. Qué NO entra todavía

- **Colas de trabajo y procesos de fondo** → Fase 15. Aquí la concurrencia ocurre dentro de un
  proceso que tú lanzas; los trabajos diferidos son otro problema.
- **Perfilado serio** → Fase 16, con la regla de *primero SQL, después Python*. Aquí se mide
  tiempo total, no dónde se va.
- **Concurrencia distribuida** —varias máquinas coordinándose— y los algoritmos de consenso. Se
  nombran y se cierran: Áurea tiene una máquina virtual de dos núcleos.
- **`async` en profundidad**: generadores asíncronos, `anyio`, el protocolo de cancelación
  completo. Entra lo que hace falta para no escribir código que bloquee, que es donde está el 90%
  del daño.

---

## 🧠 4. Concepto mínimo

### Qué es el GIL exactamente

El *Global Interpreter Lock* es un candado del intérprete que garantiza que **un solo hilo ejecute
bytecode de Python a la vez** dentro de un proceso. No es un candado sobre tus datos, no es un
candado sobre la E/S, y no impide que tengas hilos: impide que dos hilos **calculen** en paralelo.

Tres consecuencias, y las tres tienen su número en la sección 6:

**Para trabajo de CPU, los hilos no compran nada.** Cuatro hilos haciendo cuentas tardan lo mismo
que uno haciendo las cuatro. Medido: **1.02×**, que es ruido.

**Para trabajo de E/S, los hilos compran casi todo.** Cuando un hilo espera —una lectura de red, de
disco, una consulta— **suelta el GIL**, y otro entra. Medido: **3.95×** con cuatro hilos.

**Y el GIL no te protege de las carreras.** Este es el malentendido más caro y hay que decirlo con
todas las letras: el GIL garantiza que una operación de bytecode no se parte, **no** que tu
operación de negocio sea atómica. `contador += 1` son tres bytecodes y se puede interrumpir entre
ellos. Todo lo que sabes de sincronización sigue haciendo falta.

> 🧭 **La regla corta:** el GIL decide **qué te compra un hilo**, no si necesitas candados.
> Necesitas candados igual.

### Tu instinto de Java dice… y esta vez se equivoca

**El reflejo:** `synchronized`, `ConcurrentHashMap`, un pool de hilos bien dimensionado. Es el
kit completo, lo tienes afinado, y para el problema de Áurea **no sirve ninguno de los tres**.

El problema, concreto: **dos auxiliares, en dos sedes, reservan el mismo espacio de las 3:40 con
dos segundos de diferencia.** Lo que sale solo:

```python
# ❌ El reflejo, traducido
candado = threading.Lock()

def reservar(paciente: str) -> str:
    with candado:                                    # "protegido"
        if ya_existe("Suba", "2026-10-15 15:40"):
            return "ocupado"
        insertar("Suba", "2026-10-15 15:40", paciente)
        return "reservado"
```

Y así se comporta cuando dos **procesos** lo ejecutan a la vez —que es lo que pasa, porque
AgendaAPI corre con varios trabajadores—:

```text
$ python reservar.py yuli & python reservar.py auxiliar-suba & wait
reservado
reservado
filas para las 3:40 -> 2
```

**Dos reservas para el mismo espacio, con el candado puesto.** Comprobado al escribir esta fase.

**Por qué falla:** `threading.Lock` protege **un proceso**. AgendaAPI corre con varios procesos —
y mañana con dos máquinas. Cada proceso tiene su propio candado, y dos candados distintos no
coordinan nada. No es un defecto de Python: en Java pasa exactamente lo mismo con dos instancias
de tu servicio, solo que allá el despliegue de una sola JVM te escondió el problema durante años.

**Qué se escribe en su lugar:**

> 🧭 **El estado compartido de Áurea no vive en memoria: vive en Postgres. Así que el candado
> también tiene que vivir ahí.** La respuesta no es una primitiva del lenguaje — es una
> restricción de unicidad, un bloqueo optimista, o un `SELECT ... FOR UPDATE`. Y la restricción es
> la más barata de las tres.

```python
# ✅ La comprobación sigue estando —para dar un mensaje bonito— pero lo que
#    garantiza la corrección es la restricción de la tabla.
def reservar(paciente: str) -> str:
    if ya_existe("Suba", "2026-10-15 15:40"):
        return "ocupado"                     # el 99% de los casos, con buen mensaje
    try:
        insertar("Suba", "2026-10-15 15:40", paciente)
        return "reservado"
    except UniqueViolation:                  # el 1%: la carrera, cerrada por la base
        return "se lo ganaron mientras tanto"
```

Con la restricción puesta, el mismo experimento da: `['reservado', 'conflicto detectado']`, **una
fila**. Es de la Fase 11 —la restricción se plantó allí— y esto es cobrarla.

### Esto sí funciona igual

Y aquí transfiere más de lo que el párrafo anterior sugiere:

**Toda la teoría es la misma.** Carreras, interbloqueos, inanición, el problema de la
actualización perdida, los niveles de aislamiento, la diferencia entre concurrencia y
paralelismo. Nada de eso cambia, y es la parte difícil.

**El razonamiento sobre qué se puede paralelizar** —qué es independiente, dónde está la frontera
compartida, cuánto cuesta coordinar— es idéntico, y es lo que separa a alguien con experiencia de
alguien que descubrió `ThreadPoolExecutor` ayer.

**Las primitivas existen y se llaman casi igual:** `threading.Lock`, `RLock`, `Semaphore`,
`Event`, `Condition`, `Barrier`. Y `queue.Queue` es la `BlockingQueue` de siempre, con la misma
seguridad para hilos.

**Y `ThreadPoolExecutor` / `ProcessPoolExecutor` son `ExecutorService`**, con `submit`, `map` y
futuros que se esperan. La API se lee sola.

### Diccionario de traducción

| Java | Python | Dónde se rompe el paralelo |
|---|---|---|
| `Thread` | `threading.Thread` | Igual, pero **no calcula en paralelo** (salvo sin GIL) |
| `ExecutorService` | `concurrent.futures.ThreadPoolExecutor` | Igual de cómodo; `map` mantiene el orden |
| — | `ProcessPoolExecutor` | **No tiene equivalente**: en Java no hace falta escapar del GIL |
| `synchronized` | `with lock:` | Igual, y con el mismo alcance: **un proceso** |
| `ConcurrentHashMap` | `dict` + `Lock`, o `queue.Queue` | No hay colecciones concurrentes de referencia en la caja |
| `AtomicInteger` | `itertools.count()` o un `Lock` | No hay primitivas atómicas expuestas |
| `BlockingQueue` | `queue.Queue` | Igual |
| `CompletableFuture` | `asyncio.Task` / `Future` | Parecido; el modelo de ejecución es distinto |
| *Virtual threads* (Loom) | `asyncio` | **El parecido es real**: miles de tareas de E/S baratas. La diferencia: Loom es transparente y `asyncio` te obliga a marcar `async`/`await` |
| `parallelStream()` | `ProcessPoolExecutor` | Ni de lejos tan barato: los datos se serializan |
| `volatile` | no hace falta | El GIL da la visibilidad; sin GIL, el intérprete la garantiza igual |

> 📝 **Nota de ecosistema — el free-threading ya no es un experimento.** El intérprete sin GIL
> apareció como versión experimental en 3.13 (PEP 703) y en **3.14 pasó a ser una compilación
> oficialmente soportada** (PEP 779): se descarga de python.org, `uv python install 3.14t` la
> instala, y `sys._is_gil_enabled()` dice en cuál estás. Lo que **no** significa: que sea la
> compilación por defecto, ni que todas las extensiones en C funcionen en ella. Las que no
> declaran ser compatibles hacen que el intérprete vuelva a activar el GIL — y entonces tienes lo
> peor de los dos mundos sin que nada te avise. Compruébalo siempre con `sys._is_gil_enabled()`.

### Las cuatro formas, y qué compra cada una

**Secuencial.** Una cosa a la vez. Es la línea base y, más veces de las que parece, la respuesta
correcta.

**Hilos** (`ThreadPoolExecutor`). Baratos de crear, comparten memoria —para bien y para mal— y
**sirven para esperar, no para calcular**. Todo lo que sea red, disco o base de datos.

**Procesos** (`ProcessPoolExecutor`). Cada uno con su intérprete y su GIL, así que calculan en
paralelo de verdad. Cuestan arranque —unos 25 ms cada uno, de la Fase 05— y, sobre todo,
**serialización: todo lo que cruza la frontera se convierte a bytes y se reconstruye**. La
sección 6 mide cuánto duele eso, y duele más de lo que casi nadie espera.

**`asyncio`.** Un solo hilo, un bucle de eventos, y miles de tareas que se turnan en los puntos
de espera. Es lo más barato para E/S masiva — y tiene una condición absoluta: **nada dentro del
bucle puede bloquear**. Una sola llamada bloqueante y todas las tareas se detienen. Medido:
`asyncio` bien hecho da **4.32×**; con un `time.sleep` adentro, **1.01×** — es decir, nada.

**Y la quinta, que ahora existe: hilos sin GIL.** Calculan en paralelo de verdad. Cuánto, es la
sorpresa de la sección 6.

### El error de bloquear el bucle

```python
# ❌ Parece asíncrono y no lo es
async def enviar_a_socios(eventos):
    for evento in eventos:
        time.sleep(0.01)     # ← bloquea el bucle entero
```

```python
# ✅ Lo mismo, sin bloquear, y con TaskGroup (3.11+)
async def enviar_a_socios(eventos):
    async with asyncio.TaskGroup() as grupo:
        for evento in eventos:
            grupo.create_task(enviar(evento))
```

`TaskGroup` es lo que hay que usar y no `gather`: si una tarea falla, cancela las demás y levanta
un **`ExceptionGroup`** con todo lo que falló — que es la otra razón por la que `ExceptionGroup`
existe, y el bucle que la Fase 04 dejó abierto.

Y cuando **tengas** que llamar a algo bloqueante desde código `async`, hay una salida:
`asyncio.to_thread(funcion, *args)`, que lo ejecuta en un hilo aparte y te devuelve el control.

---

## 💻 5. Código mínimo con comentarios

### 5.1 Las dos cargas del dominio

```python
"""Las dos cargas del dominio de Áurea: una de CPU y una de E/S."""

import hashlib
import time
from decimal import Decimal


def reconcile_chunk(rows: list[tuple[str, str, str]]) -> tuple[int, Decimal]:
    """CPU pura: conciliar ventas contra lo facturado.

    Por cada fila: normaliza el documento, calcula el hash de control que exige
    la aseguradora, y suma en Decimal. Es trabajo real de Áurea y es todo CPU.
    """
    total = Decimal("0")
    matched = 0
    for document, code, amount in rows:
        clean = document.replace(".", "").strip()
        digest = hashlib.sha256(f"{clean}|{code}|{amount}".encode()).hexdigest()
        total += Decimal(amount)
        if digest[0] in "0123456789":
            matched += 1
    return matched, total


def io_chunk(n: int) -> int:
    """E/S simulada: esperar a que un sistema ajeno responda.

    time.sleep libera el GIL, igual que lo libera una lectura de red o de disco.
    Es la forma honesta de simular E/S sin depender de un servidor.
    """
    for _ in range(n):
        time.sleep(0.01)
    return n
```

### 5.2 Procesos, y la frontera que cuesta

Esta es la parte que produce el resultado más contraintuitivo de la fase:

```python
# ❌ Lo natural: leer el archivo y repartir las filas entre los procesos
def cpu_procesos(rows):
    parts = chunks(rows, 4)
    with ProcessPoolExecutor(4) as executor:
        return list(executor.map(reconcile_chunk, parts))
    # 0.94 s — MÁS LENTO que secuencial (0.83 s)
```

```python
# ✅ Lo correcto: que cada proceso lea su propio pedazo
def reconcile_slice(job: tuple[str, int, int]) -> tuple[int, Decimal]:
    """Lo mismo, pero los datos NO cruzan la frontera: solo cruzan tres números."""
    path, start, count = job
    rows = read_slice(path, start, count)
    return reconcile_chunk(rows)


def cpu_procesos_bien(path, rows_total):
    size = rows_total // 4
    jobs = [(path, i * size, size) for i in range(4)]
    with ProcessPoolExecutor(4) as executor:
        return list(executor.map(reconcile_slice, jobs))
    # 0.44 s — 1.86× contra secuencial
```

**El mismo cálculo, los mismos cuatro procesos, y la diferencia es 2.1×.** Lo único que cambió es
qué cruza la frontera: en la primera versión, 1.200.000 tuplas de cadenas se serializan con
`pickle`, viajan por una tubería y se reconstruyen del otro lado. En la segunda cruzan tres
números por proceso.

> 🧭 **El patrón: manda instrucciones, no datos.** Es la regla que hace o deshace el
> multiprocesamiento, y no aparece en casi ningún tutorial. Si tienes que mandar los datos,
> calcula cuánto pesan antes de decidir que los procesos te van a ayudar.

### 5.3 `asyncio` como hay que escribirlo

```python
"""Notificar a los socios en paralelo, sin bloquear el bucle."""

import asyncio

import httpx


async def notify_all(event: AvailabilityEvent, partners: list[Partner]) -> list[DeliveryResult]:
    """Notifica a todos los socios a la vez.

    TaskGroup y no gather: si una tarea falla, cancela las demás y levanta un
    ExceptionGroup con todo lo que falló (Fase 04). `gather` con
    return_exceptions=True se traga el fallo, y sin él pierde los demás errores.
    """
    async with httpx.AsyncClient(timeout=httpx.Timeout(connect=2.0, read=5.0)) as client:
        async with asyncio.TaskGroup() as group:
            tasks = [
                group.create_task(deliver_async(client, partner, event))
                for partner in partners
            ]
    return [task.result() for task in tasks]


async def deliver_async(client, partner, event) -> DeliveryResult:
    """El envío de la Fase 13, sin bloquear.

    Los dos cambios: el cliente es AsyncClient y el backoff es asyncio.sleep.
    Un time.sleep aquí detendría a TODAS las tareas, no solo a esta.
    """
    for attempt in range(1, 4):
        response = await client.post(partner.url, json=event.payload,
                                     headers={"Idempotency-Key": event.key})
        if response.status_code < 400:
            return DeliveryResult(True, attempt, response.status_code, "entregado")
        await asyncio.sleep(0.05 * 2 ** (attempt - 1))   # ← await, no time.sleep
    return DeliveryResult(False, 3, response.status_code, "agotados los intentos")
```

**Detalles con intención**

- **`asyncio.sleep` y no `time.sleep`.** Es la diferencia entre 4.32× y 1.01×, medida en §6. Es el
  error más común del ecosistema y no produce ningún síntoma visible salvo latencia.
- **Un `AsyncClient` para todas las tareas**, no uno por tarea: mismo argumento del *pool* de la
  Fase 13.
- **Y las excepciones llegan agrupadas**, así que del otro lado se atrapan con `except*`.

### 5.4 El caso de las 3:40, cerrado

La Fase 11 puso la restricción; aquí se convierte en una respuesta útil:

```python
from psycopg.errors import UniqueViolation


@app.post("/bookings", response_model=BookingResponse, status_code=201)
def create_booking(request: BookingRequest, session: DbSession) -> Booking:
    """Reserva una cita.

    La comprobación previa existe para dar un buen mensaje en el 99% de los
    casos; lo que GARANTIZA que no haya dos reservas es la restricción de la
    tabla, y por eso el except no es opcional.
    """
    if is_taken(session, request.branch, request.starts_at):
        raise HTTPException(409, f"el espacio de las {request.starts_at:%H:%M} ya está reservado")

    booking = Booking(...)
    session.add(booking)
    try:
        session.flush()          # aquí es donde la base dice que no
    except IntegrityError as error:
        if not isinstance(error.orig, UniqueViolation):
            raise
        session.rollback()
        # La carrera: entre la comprobación y el insert, alguien más reservó.
        raise HTTPException(
            409, "se lo ganaron mientras tanto: el espacio acaba de ocuparse"
        ) from error
    return booking
```

**El patrón a memorizar**

> Comprobar antes es para el mensaje; la restricción es para la corrección. Las dos, siempre —y si
> solo puedes tener una, quédate con la restricción.

> ⚠️ **Y el solapamiento parcial sigue sin resolverse.** La restricción cubre *dos citas que
> empiezan a la misma hora*; no cubre *una cita de 90 minutos a las 15:00 y otra a las 15:40*. La
> respuesta correcta de Postgres son las **restricciones de exclusión** (`EXCLUDE USING gist` con
> un rango de tiempo), que la Fase 11 dejó en un ejercicio. Está declarado como límite en vez de
> fingir que el problema está cerrado.

---

## 📏 6. Medición — las dos cargas, y la inversión del veredicto

Esta es la medición central de la fase y **son dos tablas que hay que leer juntas**. Leer solo una
produce exactamente la conclusión equivocada.

**Hipótesis.** Para trabajo de CPU, los hilos no compran nada con GIL y los procesos ganan solo si
los datos no cruzan la frontera. Para trabajo de E/S, los hilos y `asyncio` ganan y los procesos
sobran. El intérprete sin GIL cambia la primera tabla y no la segunda.

**Condiciones.** macOS 26.6 · Apple Silicon, **8 núcleos** · **4 trabajadores** en todos los casos
· dos intérpretes: **CPython 3.14.7** y **CPython 3.14.7 free-threading**, los dos instalados con
`uv` · mediana de 3 repeticiones más una de calentamiento · carga de CPU: conciliar **1.200.000
filas** del archivo de ventas del trimestre, generado con semilla `2026` · carga de E/S: 100
esperas de 10 ms repartidas entre los trabajadores · `sys._is_gil_enabled()` confirmado en cada
corrida.

**Competidores.** Las cinco formas reales, con la versión de procesos **medida dos veces** —con y
sin serialización de los datos— porque presentar solo la primera sería sabotear a los procesos, y
presentar solo la segunda escondería el costo que casi todo el mundo paga sin saberlo.

**Resultado — carga de CPU (conciliar 1.200.000 filas):**

| Forma | Con GIL | | Sin GIL | |
|---|---|---|---|---|
| | mediana | aceleración | mediana | aceleración |
| Secuencial | 0.83 s | 1.00× | 0.81 s | 1.00× |
| **Hilos** | 0.81 s | **1.02×** | 0.71 s | **1.14×** |
| Procesos, datos serializados | 0.94 s | **0.88×** | 0.97 s | 0.83× |
| **Procesos, cada uno lee lo suyo** | **0.44 s** | **1.86×** | 0.51 s | 1.59× |

**Resultado — carga de E/S (100 esperas de 10 ms):**

| Forma | Con GIL | | Sin GIL | |
|---|---|---|---|---|
| | mediana | aceleración | mediana | aceleración |
| Secuencial | 1.18 s | 1.00× | 1.21 s | 1.00× |
| **Hilos** | 0.30 s | **3.95×** | 0.30 s | **4.01×** |
| Procesos | 0.38 s | 3.15× | 0.40 s | 3.03× |
| **`asyncio` con `TaskGroup`** | **0.28 s** | **4.32×** | — | — |
| `asyncio` con `time.sleep` adentro | 1.20 s | **1.01×** | — | — |

**Y dos mediciones de control, porque los números de arriba las necesitan:**

| | Con GIL | Sin GIL |
|---|---|---|
| Aritmética de Python puro, 4 hilos | 1.02× | **2.27×** |
| Un solo hilo, 400.000 filas | 0.272 s | **0.271 s** |

> ⚖️ **Veredicto. La inversión es el punto, y se lee comparando las dos primeras tablas fila por
> fila.**
>
> **Los hilos: 1.02× para CPU y 3.95× para E/S.** El mismo mecanismo, el mismo código, el mismo
> número de trabajadores, y la diferencia es de un factor de cuatro según qué esté haciendo el
> trabajo. Esa es la única pregunta que hay que hacerse antes de elegir: **¿esto espera o
> calcula?** Todo lo demás es secundario.
>
> **Los procesos pierden contra secuencial —0.88×— cuando los datos cruzan la frontera**, y ganan
> 1.86× cuando no. Es el resultado que más sorprende y el que más se ignora: 1.200.000 tuplas
> serializadas con `pickle` cuestan más que el cálculo que venían a acelerar. **Multiprocesamiento
> no es "hilos que sí funcionan": es otro modelo, con un costo propio que hay que presupuestar.**
>
> **`asyncio` gana la carga de E/S —4.32×— y se convierte en nada si bloqueas el bucle: 1.01×.**
> No hay punto intermedio y no hay aviso. Es la trampa más cara del Bloque C y la que produce esas
> APIs que van bien en desarrollo y se caen con diez usuarios.
>
> **Y el free-threading, sin entusiasmo y sin desdén.** Con aritmética de Python puro, los hilos
> pasan de **1.02× a 2.27×**: el GIL era de verdad lo que estorbaba y quitarlo funciona. Sobre la
> carga **real** de Áurea, en cambio, apenas llega a **1.14×** — porque ese trabajo pasa la mitad
> del tiempo dentro de `hashlib` y `Decimal`, que son código en C, y asignando objetos, que en un
> intérprete sin GIL tiene su propio costo de coordinación. **La promesa es cierta y parcial, y
> depende de tu carga, no de la versión.** La buena noticia es la última fila: **ya no hay
> penalización por usar la compilación sin GIL en un solo hilo** —0.272 contra 0.271 s—, que era la
> objeción principal cuando esto era experimental.
>
> **Dónde pierde cada uno, en una línea:** los hilos pierden si calculas; los procesos pierden si
> tienes que mandarles los datos; `asyncio` pierde si alguna de tus dependencias no es asíncrona;
> y el free-threading pierde si tus extensiones en C no lo soportan —y entonces el intérprete
> vuelve a poner el GIL sin decírtelo.
>
> **El umbral, que es lo que hay que llevarse a la próxima decisión:**
>
> - **¿Espera o calcula?** Si espera: hilos, o `asyncio` si son muchísimas esperas.
> - **Si calcula: ¿los datos ya están donde va a correr?** Si sí, procesos. Si no, calcula cuánto
>   pesan antes de decidir.
> - **¿Y el free-threading?** Mídelo con **tu** carga. Con Python puro puede duplicarte; con
>   `numpy` y `pandas` —que ya sueltan el GIL— el beneficio puede ser cero porque ya lo tenías.

**Lo que no se midió, y es lo más importante de esta sección:** **todo esto es un portátil de ocho
núcleos**. Áurea corre en **una máquina virtual de dos núcleos**, y ahí la tabla de CPU cambia:
con dos núcleos y cuatro trabajadores, los procesos compiten entre sí y la aceleración se acerca a
2× en el mejor caso, mientras que el costo de arranque y de serialización se mantiene igual.
**El que gana en tu máquina no es el que gana en la de Áurea**, y el miniproyecto se juega
exactamente ahí. Tampoco se midió con más trabajadores que núcleos, ni el consumo de memoria de
los procesos —que es el otro costo real: cada uno es un intérprete entero.

---

## 🧱 7. Miniproyecto — *La conciliación del trimestre*

**El encargo**

Patricia: *"La conciliación del trimestre la corro el primer sábado y me toma toda la mañana. Son
como un millón doscientas mil líneas entre lo que reportaron las sedes y lo que facturamos. El
computador se queda pegado y no puedo hacer nada más."* Y Julián, detrás: *"¿Y no se puede poner a
usar todos los procesadores? El servidor que alquilamos tiene dos."*

Concilia el archivo de ventas contra lo facturado, **eligiendo el modelo de concurrencia con la
medición delante** y justificando por qué los otros tres pierden.

**Por qué duele**

Porque la respuesta correcta **depende de la máquina**, y la máquina de Áurea no es la tuya. El
modelo que gane en tu portátil de ocho núcleos puede perder en una máquina virtual de dos — y el
entregable de este miniproyecto no es el código rápido: es **la decisión defendida con números de
las dos máquinas**.

**Datos de entrada**

El archivo de ventas del trimestre, generado con semilla fija:

```python
"""Genera el archivo de ventas del trimestre para conciliar.

Uso:  python generar_ventas.py
Produce data/ventas-2026-Q1.csv, 1.200.000 filas, ~27 MB.
"""

import random
from pathlib import Path

CODES = ["D8010", "D8020", "D2740", "D7140", "D1110", "D8670"]
VALUES = [75000, 95000, 120000, 180000, 210000, 890000]


def main() -> None:
    rng = random.Random(2026)
    Path("data").mkdir(exist_ok=True)
    target = Path("data") / "ventas-2026-Q1.csv"
    with target.open("w", encoding="utf-8") as file:
        file.write("documento,codigo,valor\n")
        for _ in range(1_200_000):
            file.write(f"{rng.randint(10_000_000, 1_299_999_999)},"
                       f"{rng.choice(CODES)},{rng.choice(VALUES)}\n")
    print(f"{target}: 1.200.000 filas · {target.stat().st_size / 1e6:.1f} MB")


if __name__ == "__main__":
    main()
```

Y lo facturado sale del histórico en `sqlite3` de la Fase 06. La conciliación tiene que decir, por
cada fila de ventas: si está facturada, si no lo está, o si está facturada con otro valor.

**Criterios de aceptación**

- [ ] La conciliación corre en las **cuatro formas** —secuencial, hilos, procesos y `asyncio` si
      aplica— y las cuatro producen **exactamente el mismo resultado**. Compruébalo antes de medir:
      una optimización que cambia el resultado no es una optimización.
- [ ] Mides las cuatro con el arnés de la Fase 02, con al menos tres repeticiones, y reportas
      mediana y p95.
- [ ] **Mides con dos números de trabajadores distintos** y **simulando la máquina de Áurea**: dos
      núcleos. En Linux y macOS puedes acotar los trabajadores; si no puedes limitar los núcleos
      de verdad, dilo y razona qué cambiaría.
- [ ] Eliges una forma y **escribes la justificación**, con las otras tres descartadas por su
      número, no por intuición.
- [ ] La versión con procesos **no serializa los datos**: cada trabajador lee su parte. Demuestra
      la diferencia midiendo también la versión que sí serializa.
- [ ] El proceso es **interrumpible**: un `Ctrl-C` a la mitad no deja procesos hijos vivos.
      Compruébalo con `ps` (es la deuda que la Fase 05 dejó anotada).
- [ ] **Medición:** tiempo de la forma elegida y de las otras tres, en tu máquina y con dos
      trabajadores. Esos números van en el mensaje del tag.

**Restricciones de registro**

> Esto es una **aplicación**, y la restricción propia de la fase: **no elijas antes de medir.**
> Escribe las cuatro versiones —son parecidas entre sí, el cálculo es el mismo— y decide después.
> El reflejo que se ataca aquí no es la ceremonia ni la dependencia: es **decidir por experiencia
> previa en otro lenguaje**, que es lo que te va a hacer elegir hilos para CPU o procesos para
> E/S.

**La trampa**

El modelo que gana en tu portátil de ocho núcleos **no es el que gana en la máquina virtual de dos
que tiene Áurea**. Con cuatro procesos en dos núcleos, los procesos compiten entre ellos, el
arranque y la serialización se pagan igual, y la aceleración se desploma.

Y hay una segunda, más silenciosa: **cargar el archivo para repartirlo ya es la mitad del
trabajo**. Si mides solo el cálculo y no la lectura, vas a elegir el modelo equivocado — porque el
tiempo total lo domina lo que no mediste.

**Pistas**

<details><summary>Pista 1 — el enfoque</summary>

Primero mide **sin concurrencia** y averigua dónde se va el tiempo: leer, parsear, o calcular.
Es la regla de la Fase 16 adelantada, y decide todo lo demás: si el 70% es leer el archivo,
paralelizar el cálculo te va a comprar muy poco.

Después escribe las cuatro versiones con la **misma función de cálculo**, cambiando solo cómo se
reparte. Si las cuatro comparten el núcleo, comparar es legítimo.
</details>

<details><summary>Pista 2 — la herramienta</summary>

- [`concurrent.futures`](https://docs.python.org/3.14/library/concurrent.futures.html) — los dos
  ejecutores tienen la misma interfaz, y eso hace que cambiar entre ellos sea una línea.
- [`multiprocessing`](https://docs.python.org/3.14/library/multiprocessing.html) — y sobre todo la
  sección de **métodos de arranque**: en macOS y Windows el arranque es `spawn`, que reimporta tu
  módulo en cada proceso hijo. Si tu código hace trabajo al importarse, lo vas a hacer cinco veces.
- [`asyncio`](https://docs.python.org/3.14/library/asyncio.html) — `TaskGroup` y `to_thread`.
- Y `os.cpu_count()` contra
  [`os.process_cpu_count()`](https://docs.python.org/3.14/library/os.html), que es de 3.13 y
  respeta los límites del contenedor. Para el escenario de Áurea, esa diferencia importa.
</details>

<details><summary>Pista 3 — el esqueleto</summary>

```python
def reconcile_chunk(rows) -> Reconciliation:
    """El cálculo. IDÉNTICO en las cuatro versiones."""

def run_sequential(path, workers) -> Reconciliation: ...
def run_threads(path, workers) -> Reconciliation: ...
def run_processes(path, workers) -> Reconciliation: ...   # sin serializar los datos

def compare(path, workers_list) -> str:
    """La tabla, con el arnés de la Fase 02. Verifica primero que dan lo mismo."""
```
</details>

**Cómo se entrega**

```bash
python generar_ventas.py
uv run python -m cartera.conciliar --forma todas --trabajadores 4
uv run python -m cartera.conciliar --forma todas --trabajadores 2   # la máquina de Áurea
```

```bash
git add src/cartera generar_ventas.py
git commit -m "fase 14 mini: conciliación del trimestre, con su modelo elegido y medido"
git tag -a mini-14 -m "Mini F14: conciliación · <forma> gana con <N> s (4 trab.) y <M> s (2 trab.)"
```

<details><summary>💡 Solución de referencia — la decisión depende de la máquina</summary>

**La decisión de diseño que se tomó.** **Procesos, con cada trabajador leyendo su propio rango del
archivo**, y el número de trabajadores tomado de `os.process_cpu_count()` en vez de fijado. Las
razones, con los números de §6: los hilos no compran nada para CPU con GIL (1.02×), y el
free-threading sobre esta carga concreta apenas llega a **1.14×**, porque el trabajo vive dentro
de `hashlib` y `Decimal`.

El otro camino defendible, y que en la máquina de Áurea puede ganar, es **secuencial**. Con dos
núcleos, el paralelismo real es 2× como techo, el arranque de los procesos cuesta ~25 ms cada uno
y la lectura del archivo compite consigo misma; si la conciliación baja de cuarenta minutos a
veinticinco, la pregunta legítima es si vale la complejidad. **Una respuesta correcta de este
miniproyecto puede ser "secuencial, y aquí está por qué"** — siempre que traiga la tabla.

**La trampa, entera.** Las dos mitades son la misma: **mediste la máquina equivocada, o mediste la
parte equivocada.** Un portátil de ocho núcleos con disco rápido y caché caliente da una respuesta
que no se traslada a una máquina virtual de dos núcleos con disco de red. Y medir solo el cálculo
—sin la lectura— hace que el modelo parezca mejor de lo que es, porque la parte que no
paralelizaste no aparece en el número.

La regla de Amdahl, que sabes y que aquí se cobra: **si el 40% del trabajo es leer el archivo en
serie, ninguna cantidad de procesos te va a dar más de 2.5×**, tengas los núcleos que tengas.

**Qué se habría hecho distinto si el registro fuera otro.** Como script —el Bloque A— esto sería
secuencial y tardaría lo que tardara, y para una corrida mensual **eso es defendible**: cuarenta
minutos una vez al mes no justifican mantener cuatro implementaciones. Como aplicación, la
conciliación no sería un proceso que alguien lanza: sería un trabajo encolado que corre de noche
y deja su resultado —que es la Fase 15, y que cambia la pregunta de "cuánto tarda" a "cuándo
está".
</details>

---

## 🧪 8. Ejercicios (25)

**🟢 Fácil (1–6)**

1. Comprueba en cuál intérprete estás con `sys._is_gil_enabled()`, en los dos. Anota qué devuelve
   en un 3.13 normal.
2. Corre la carga de CPU con 1, 2, 4 y 8 hilos y demuestra que el tiempo no cambia. Es el GIL,
   visto.
3. Corre la carga de E/S con los mismos números de hilos y encuentra dónde deja de mejorar.
4. Escribe la versión con `asyncio.TaskGroup` y mide. Después mete un `time.sleep` adentro y
   vuelve a medir. Los dos números van en tu cuaderno.
5. Provoca una carrera con `contador += 1` desde cuatro hilos, un millón de veces, y demuestra que
   el resultado no es cuatro millones. **Con el GIL puesto.**
6. Arregla la carrera anterior con un `Lock` y mide cuánto costó arreglarla.

**🟡 Intermedio (7–14)**

7. Mide el costo de arranque de un `ProcessPoolExecutor` con 2, 4 y 8 procesos. Compáralo con los
   25 ms por proceso de la Fase 05.
8. Mide cuánto cuesta serializar tus datos: `pickle.dumps` sobre el millón doscientas mil filas,
   con el arnés. Ese número es el que explica la fila 0.88× de §6.
9. Usa `asyncio.to_thread` para llamar a una función bloqueante desde código `async` y demuestra
   que el bucle sigue vivo.
10. Consulta la documentación de `multiprocessing` sobre métodos de arranque y averigua qué hace
    `spawn` con tu módulo. Pon un `print` a nivel de módulo y cuéntalos.
11. Usa `queue.Queue` para un patrón productor-consumidor entre hilos: uno lee el archivo, tres
    concilian. Mide y compara con `map`.
12. Provoca un interbloqueo con dos `Lock` tomados en orden distinto. Después arréglalo con la
    regla de siempre.
13. Averigua qué pasa si un `TaskGroup` tiene dos tareas que fallan. Atrápalo con `except*` y
    muestra las dos excepciones.
14. Lanza 500 tareas `asyncio` contra el servidor de la Fase 13 y compara con 500 hilos. Mide
    memoria además de tiempo: ahí está la diferencia real.

**🟠 Difícil (15–21)**

15. **Diagnóstico.** Una API `async` se degrada con diez usuarios concurrentes y va perfecta con
    uno. Reprodúcelo, encuentra la llamada bloqueante, y mide la diferencia antes y después.
16. **Diagnóstico.** Un `ProcessPoolExecutor` se cuelga sin mensaje. Hay tres causas clásicas —una
    es un objeto que no se puede serializar, otra es el arranque `spawn` en un archivo sin
    `if __name__ == "__main__":`—. Reproduce las tres.
17. **Medición.** Reproduce las dos tablas de §6 en tu máquina, con los dos intérpretes. Si no
    tienes la compilación sin GIL, instálala con `uv python install 3.14t`.
18. **Medición.** Limita tu proceso a dos núcleos —con `taskset` en Linux, con un contenedor, o
    con la herramienta que tenga tu sistema— y repite la tabla de CPU. Compara con la de ocho.
    Este es el número que decide el miniproyecto.
19. **Medición.** Mide la carga de CPU con free-threading usando una función que **no** use
    `hashlib` ni `Decimal` —solo aritmética de enteros— y compara con la tabla de §6. Explica la
    diferencia.
20. **De registro.** El envío de recordatorios de cita son 2.800 mensajes al mes por WhatsApp.
    Decide el modelo de concurrencia **y el registro**: ¿script, herramienta o aplicación? Con el
    costo de las tres.
21. **De registro.** Julián pregunta si "poniendo más procesadores" el cierre nocturno va a ir más
    rápido. Escribe la respuesta con la ley de Amdahl y con tus números: cuál es el techo real y
    qué habría que cambiar para subirlo.

**🔴 Muy difícil (22–25)**

22. **Adversarial.** Reproduce la doble reserva de las 3:40 **desde dos procesos**, primero sin la
    restricción de unicidad y después con ella. Documenta las dos salidas. Después intenta
    "arreglarlo" con un `threading.Lock` y demuestra que no sirve — es el 🪞 de la fase,
    comprobado por ti.
23. **Adversarial.** Consigue que el intérprete sin GIL **vuelva a activar el GIL** sin que tú se
    lo pidas. Pista: una extensión en C que no declare compatibilidad. Compruébalo con
    `sys._is_gil_enabled()` y explica por qué eso es peor que no haberlo usado.
24. **Defiende una decisión.** Un colega dice que con free-threading "ya no hace falta
    `multiprocessing`". Escribe las dos caras con los datos de §6 —incluido el 1.14× sobre la
    carga real— y di en qué caso concreto tendría razón.
25. **Diseño y medición.** AgendaAPI tiene que notificar a tres socios y consultar dos servicios
    externos por cada reserva, y no puede hacer esperar al usuario. Diseña la solución con lo de
    esta fase, mídela, y después anota por qué la Fase 15 va a proponerte algo distinto. Las dos
    respuestas son correctas para problemas distintos.

**🔥 Opcionales**

- Lee el PEP 703 entero —el que quitó el GIL— y en particular la sección de por qué costó veinte
  años. Es la mejor explicación de qué protegía el GIL de verdad.
- Investiga `multiprocessing.shared_memory` y úsalo para pasar el archivo de ventas entre procesos
  sin serializarlo. Mídelo contra la versión que lee del disco.
- Averigua qué son los *subintérpretes* (PEP 734) y en qué se diferencian de los procesos y de los
  hilos. Es la tercera vía y apenas empieza.

---

## 📚 9. Referencias

**Documentación oficial**

- [`concurrent.futures`](https://docs.python.org/3.14/library/concurrent.futures.html) — la puerta
  de entrada; los dos ejecutores con la misma interfaz.
- [`threading`](https://docs.python.org/3.14/library/threading.html) y
  [`multiprocessing`](https://docs.python.org/3.14/library/multiprocessing.html) — de este último,
  la sección de métodos de arranque y la de *programming guidelines*, que es literalmente una
  lista de las trampas.
- [`asyncio`](https://docs.python.org/3.14/library/asyncio.html) — empieza por *Coroutines and
  Tasks*, y lee `TaskGroup`.
- [Free-threaded Python: guía de uso](https://docs.python.org/3.14/howto/free-threading-python.html)
  — qué cambia, qué comprobar y qué extensiones lo soportan.
- [`sys._is_gil_enabled`](https://docs.python.org/3.14/library/sys.html) — la comprobación que hay
  que hacer siempre.

**PEPs**

- [PEP 703](https://peps.python.org/pep-0703/) — hacer el GIL opcional. Largo, y la parte del
  *rationale* vale por sí sola.
- [PEP 779](https://peps.python.org/pep-0779/) — el criterio con el que free-threading pasó a estar
  oficialmente soportado en 3.14.
- [PEP 654](https://peps.python.org/pep-0654/) — `ExceptionGroup`, otra vez: aquí se ve para qué
  nació.
- [PEP 734](https://peps.python.org/pep-0734/) — subintérpretes, para el ejercicio 🔥.

**Orden de lectura sugerido.** Antes de medir: `concurrent.futures`, que son veinte minutos.
Durante: las *programming guidelines* de `multiprocessing`, que te van a ahorrar el ejercicio 16.
Después: el PEP 703, que se lee distinto cuando ya viste con tus ojos el 1.02× y el 2.27×.

> ⚠️ URLs y contenidos cambian, y este tema se mueve: verifica contra 3.14.

---

## 🚀 10. Cierre y conexión con la siguiente fase

Lo que te llevas de esta fase cabe en una pregunta y una regla.

La pregunta: **¿esto espera o calcula?** Los hilos dan 1.02× para lo segundo y 3.95× para lo
primero, con el mismo código. Todo lo demás —procesos, `asyncio`, free-threading— es refinamiento
sobre esa respuesta.

La regla: **el candado tiene que estar donde está el estado.** El de Áurea vive en Postgres, así
que `threading.Lock` no podía funcionar y no funcionó — dos procesos, dos candados, dos reservas
para las 3:40. Lo cerró una restricción de unicidad, que es de la Fase 11 y que hoy se cobró.

Y te llevas una advertencia que vale más que las dos tablas: **ninguno de esos números es de la
máquina de Áurea.** Ocho núcleos contra dos cambia el ganador, y el miniproyecto se juega ahí. La
disciplina de preguntar *"¿en qué máquina?"* antes de citar un número de concurrencia es lo que
separa una decisión de una anécdota.

La **Fase 15** cambia la pregunta: hasta ahora, cuando algo tardaba, la respuesta era hacerlo más
rápido. Ahora la respuesta es **hacerlo cuando nadie esté mirando**. Nace el proyecto 4 —el cierre
nocturno—, que es reanudable, idempotente y auditable línea por línea. Y trae una costura
deliberada con el Bloque A: **el batch importa el CLI como biblioteca**. La misma validación que
Patricia corre a mano es la que corre desatendida a las dos de la mañana sobre las diez sedes —y
ese es el día en que se cobra, en uso real, todo lo que hiciste bien en la Fase 07.

> **La señal de que quedó bien:** cuando alguien diga "lo paralelicé y no mejoró", vas a tener dos
> preguntas listas antes de mirar el código: *¿espera o calcula?* y *¿qué cruza la frontera?*

> 🏷️ **No cierres la fase sin el tag.** Con el checklist de la sección 2 en verde, el
> miniproyecto corriendo y `git status` limpio:
>
> ```bash
> git tag -a fase-14 -m "F14 cerrada:
> - el GIL entendido: qué impide y qué no, con 1.02x y 3.95x medidos
> - la frontera entre procesos medida: 0.88x serializando, 1.86x sin serializar
> - asyncio con TaskGroup a 4.32x, y el bucle bloqueado a 1.01x
> - free-threading medido con las dos cargas, sin entusiasmo: 2.27x y 1.14x
> - la doble reserva de las 3:40 reproducida y cerrada con la restricción
> - el modelo del cierre elegido con la tabla de dos máquinas, no con intuición"
> ```
>
> Los commits de la fase llevan su prefijo (`fase 14: …`), los de ejercicio su número
> (`fase 14 ej12: …`) y el miniproyecto el suyo (`fase 14 mini: …`). El miniproyecto terminado
> lleva además su tag anotado `mini-14`, y **en el mensaje de ese tag va el número que arrojó su
> medición**. La convención completa está en
> [`00-convencion-de-git-y-tags.md`](00-convencion-de-git-y-tags.md).
