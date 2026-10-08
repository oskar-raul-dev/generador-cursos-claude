# 🔭 Fase 16 — Operación y rendimiento

> Python para desarrolladores Java senior · Fase 16 de 18 · Bloque C
> Depende de: Fase 15 · Habilita: Fase 17
> Registro de esta fase: **aplicación**
> Proyecto que avanza: **los cuatro**
> Fecha de verificación de las versiones: 12/09/2026

---

## 🎯 1. Propósito

Dejar los cuatro proyectos **operables por alguien que no los escribió**, y optimizar con
evidencia en vez de con intuición.

Son dos oficios y esta fase los junta a propósito, porque comparten una misma disciplina: **no se
arregla lo que no se mide, y no se mide lo que no se ve**. Pero son dos, y por eso esta fase tiene
**dos bloques de medición separados** y no uno promediado — uno para lo que cuesta ver, y otro
para lo que el perfil dice sobre dónde se va el tiempo.

Y trae la regla que más veces vas a citar después del curso, que va contra el instinto de
cualquiera que sepa optimizar código:

> 🧭 **Primero SQL, después Python.** Al revés es teatro. Y el número de §6.2 lo dice sin
> ambigüedad: en el cierre nocturno, el **87% del tiempo es esperar a la base de datos**.
> Optimizar el Python que está encima de eso toca el 13% restante.

---

## ✅ 2. Qué queda listo al terminar

- [ ] Los cuatro proyectos emiten registro **estructurado**, con identificador de petición y sin
      datos clínicos.
- [ ] Tienes trazas y métricas, y sabes cuánto te cuestan, medido.
- [ ] La configuración viene del ambiente y **ningún secreto está en el repositorio**.
- [ ] Sabes qué es `pickle` y por qué no se usa para datos que vengan de afuera.
- [ ] Puedes leer un perfil de `cProfile` y decir dónde está el tiempo — y distinguir eso de dónde
      **crees** que está.
- [ ] Sabes cuándo el problema es el intérprete y cuáles son las salidas de emergencia, con su
      costo.
- [ ] El miniproyecto de la sección 7 corre y cumple sus criterios de aceptación.

---

## 🚫 3. Qué NO entra todavía

- **Contenedores, imagen y despliegue** → Fase 17, y solo lo justo para medir arranque en frío y
  costo. No hay fase de contenedores y el curso lo dice desde el principio.
- **Alertas y turnos de guardia.** Se nombran: una métrica que nadie mira no es observabilidad. Lo
  que entra es producirlas; a quién despiertan es organización, no código.
- **Auditoría de accesos** → ya está, en la Fase 12. Es otra cosa que el registro de operación, y
  conviene no confundirlas: una es legal y la otra es técnica.
- **Optimización con extensiones nativas** —Cython, Rust, C—. Se nombran en §5.7 **con su costo y
  su umbral**, no como recomendación.

---

## 🧠 4. Concepto mínimo

### Tu instinto de Java dice… y esta vez se equivoca

Dos reflejos, y el segundo es específico de este dominio.

#### Primero: `print` como registro

```python
# ❌ Lo que sale solo, y lo que hay hoy en los cuatro proyectos
print(f"procesando sede {branch}")
print(f"error: {error}")
```

Vienes de un mundo donde nadie hace esto: Log4j o Logback están puestos desde el arquetipo, con
niveles, appenders y un patrón configurado. En Python el `print` funciona, sale por pantalla, y en
desarrollo parece suficiente. **Y a las dos de la mañana no sirve para nada**, por cuatro razones
concretas: no tiene nivel —no puedes apagar el detalle sin apagar todo—, no tiene marca de tiempo,
no dice de qué módulo viene, y va a `stdout`, así que se mezcla con la salida útil del programa.

La respuesta no es "usa `logging`", que ya lo sabes. Es **registro estructurado**:

```python
# ✅ Un evento con sus campos, no una frase
log.info("cierre_lote_terminado", month="2026-01", batch=17, rows=20_000,
         elapsed_ms=412, request_id=request_id)
```

La diferencia práctica: *"procesando sede centro"* se puede leer; `{"event":
"cierre_lote_terminado", "month": "2026-01", "rows": 20000, ...}` se puede **consultar**.
`grep` contra una frase encuentra líneas; una consulta contra campos encuentra *"todos los lotes
del cierre de enero que tardaron más de un segundo"*. A las dos de la mañana, la segunda pregunta
es la que tienes.

#### Segundo, y es el caro: optimizar el Python que está encima de una consulta mala

Es el reflejo del buen programador, y por eso es tan difícil de desactivar: ves un bucle lento,
miras el bucle, y lo optimizas. Cambias la comprehension, precalculas, memoizas, y ganas un 20%
sobre el 13% del tiempo que era tuyo.

```python
# ❌ El cierre "optimizado" a mano
for documento, codigo, valor in filas:
    if paciente_existe(documento):          # ← una consulta por fila
        total += Decimal(valor) * tasa      # ← y optimizamos ESTO
```

El perfil de §6.2 dice lo que de verdad pasa ahí: **0.729 segundos de 0.837 son
`psycopg...wait`** — esperando a Postgres. El `Decimal`, el hash y el bucle, todos juntos, son el
resto.

```python
# ✅ Una consulta, y el Python ni se nota
conocidos = {fila[0] for fila in traer_todos_los_documentos()}   # una consulta
for documento, codigo, valor in filas:
    if documento in conocidos:              # Fase 01: pertenencia en set
        total += Decimal(valor) * tasa
```

**0.55 s → 0.02 s. Veintisiete veces.** Y ni una sola línea del cálculo cambió.

> 🧭 **La regla operativa, que es la fase entera:** antes de optimizar una línea de Python,
> perfila y mira **cuánto del tiempo es tuyo**. Si el 87% es esperar a la base, la red o el disco,
> el código Python no es el problema — y mejorarlo es trabajo que se siente productivo y no mueve
> el número.

### Esto sí funciona igual

Y aquí transfiere casi todo, porque es la fase menos "de lenguaje" del curso:

**Los niveles de registro son los mismos** y significan lo mismo: `DEBUG` para desarrollar,
`INFO` para el flujo normal, `WARNING` para lo raro que no rompe, `ERROR` para lo que falló,
`CRITICAL` para lo que se cae. Y la misma disciplina de no poner en `INFO` lo que pasa un millón
de veces.

**La instrumentación y el trazado distribuido** son los mismos conceptos, con el mismo estándar:
OpenTelemetry es OpenTelemetry, y un *span* es un *span*. Si has instrumentado con Micrometer o con
el agente de Java, esto se lee solo.

**La configuración por ambiente y los secretos fuera del repositorio** es la misma disciplina de
siempre, con las mismas trampas.

**Y todo tu criterio de perfilado se transfiere**: medir antes de cambiar, cambiar una cosa a la
vez, desconfiar de la microoptimización, y la ley de Amdahl. Lo que cambia son las herramientas y
—esto sí— **el orden de magnitud de lo que cuesta cada cosa**, que en un lenguaje interpretado es
distinto.

### Diccionario de traducción

| Java | Python | Dónde se rompe el paralelo |
|---|---|---|
| SLF4J + Logback | `logging` | Está en la caja; la configuración es un `dict` o un archivo |
| Logback con `JsonEncoder` | `structlog` | Es una capa **encima** de `logging`, no un reemplazo |
| MDC (contexto por hilo) | `structlog.contextvars` | Funciona también con `asyncio`, que es más que el MDC |
| Micrometer | `prometheus_client` | Mismo modelo: contadores, medidores, histogramas |
| Agente de OpenTelemetry | `opentelemetry-instrumentation-*` | **Sin agente mágico**: se instala por biblioteca y se activa en código |
| JFR / async-profiler | `py-spy` | Muestreo, sin modificar el proceso. Es lo más parecido |
| JProfiler / VisualVM | `cProfile` + `snakeviz` | `cProfile` instrumenta y distorsiona; `py-spy` no |
| `-XX:+HeapDumpOnOutOfMemory` | `tracemalloc` | Más limitado: mide lo que asigna Python |
| `@ConfigurationProperties` | Pydantic Settings, o `os.environ` | Validación en el arranque, si la pides |
| Vault / Secret Manager | lo mismo | No cambia nada; lo que cambia es que aquí no hay integración por defecto |
| Serialización Java | `pickle` | **Y el mismo agujero**: deserializar datos ajenos ejecuta código |

> 📝 **Nota de ecosistema — `logging` es viejo y se nota.** El módulo `logging` es de 2002 y su
> diseño lo delata: se configura con un diccionario que nadie recuerda, tiene una jerarquía de
> *loggers* por nombre con propagación, y su API usa `%s` en vez de f-strings —a propósito, para no
> formatear lo que no se va a emitir—. No hay un reemplazo estándar y sí dos capas encima muy
> usadas: `structlog`, que es la que usa el curso, y `loguru`, que es más simple y menos
> componible. Las dos escriben al final a través de `logging`, así que la elección no te encierra.

### Qué se registra, y qué no

En Áurea esto no es una preferencia: **la historia clínica es reservada**, y un registro es un
lugar donde los datos salen del sistema sin que nadie los audite.

| Se registra | No se registra |
|---|---|
| El identificador del paciente | El nombre, el diagnóstico, la nota clínica |
| La sede, la fase, el código | El motivo de consulta |
| Quién hizo la operación y cuándo | El contenido de la petición completa |
| El identificador de la petición | Tokens, contraseñas, cabeceras de autorización |

> ⚠️ **El registro más peligroso es el que alguien puso "para depurar".** Un
> `log.debug("payload: %s", request_body)` en producción vuelca la historia clínica a un archivo
> que después se copia a un servicio de registros de terceros. Y no lo va a atrapar ninguna
> revisión de código, porque estaba ahí desde el principio y parecía inofensivo.

### La seguridad que muerde en este ecosistema

Cinco cosas, y las cinco son específicas de Python:

**`pickle` ejecuta código al deserializar.** No es un error: es su diseño. Un `pickle.loads` sobre
datos que no controlas es equivalente a `eval` sobre datos que no controlas. Y aparece donde uno
no lo espera: cachés, colas —Celery lo usaba por defecto hace años—, y archivos "de modelo" que
alguien te manda.

**`yaml.load` sin `SafeLoader` hace lo mismo.** El YAML completo puede instanciar objetos
arbitrarios. La forma correcta es `yaml.safe_load`, y la biblioteca lleva años avisando.

**`shell=True`**, que la Fase 05 prohibió, sigue prohibido. Es la tercera vez que aparece y no es
casualidad: es el agujero más fácil de abrir.

**Y la cadena de suministro**, que en este ecosistema es peor que en el tuyo por la razón que la
Fase 00 señaló: **PyPI no tiene *namespace* por organización**. El nombre es de quien lo registró
primero, y un paquete que se llama casi igual que el que querías es un vector real. Las tres
defensas baratas: fijar versiones con hash en el lockfile (Fase 07), revisar el `uv.lock` en los
cambios, y desconfiar de cualquier dependencia nueva que no conozcas — el procedimiento que el
ejercicio 25 de la Fase 00 te hizo escribir.

**`python -m http.server` olvidado.** El servidor de pruebas de la Fase 13 usa `http.server`, y la
propia documentación dice que no es para producción: sirve el directorio donde se lanzó, sin
autenticación ni límites. Está bien para probar; el problema es el que queda corriendo en una
máquina de la sede porque "era un momento". `ss -ltnp` en las máquinas que operas lo encuentra.

---

## 💻 5. Código mínimo con comentarios

### 5.1 Registro estructurado

```python
"""Configuración del registro para los cuatro proyectos."""

import logging
import sys

import structlog


def configure_logging(*, level: str = "INFO", as_json: bool = True) -> None:
    """Configura el registro una vez, al arrancar.

    En producción, JSON a stdout: lo recoge quien recoja los registros —el
    contenedor, systemd, el agente— y no hay que rotar nada a mano.
    En desarrollo, texto con colores, porque JSON en una terminal no se lee.
    """
    logging.basicConfig(format="%(message)s", stream=sys.stdout, level=level)

    processors = [
        structlog.contextvars.merge_contextvars,   # el contexto de la petición
        structlog.processors.add_log_level,
        structlog.processors.TimeStamper(fmt="iso", utc=True),
        structlog.processors.StackInfoRenderer(),
        structlog.processors.format_exc_info,      # la traza, como campo
    ]
    processors.append(
        structlog.processors.JSONRenderer() if as_json
        else structlog.dev.ConsoleRenderer()
    )

    structlog.configure(
        processors=processors,
        wrapper_class=structlog.make_filtering_bound_logger(getattr(logging, level)),
        logger_factory=structlog.stdlib.LoggerFactory(),
        cache_logger_on_first_use=True,
    )
```

```python
# El middleware que le pone identificador a cada petición.
@app.middleware("http")
async def add_request_context(request: Request, call_next):
    """Cada petición lleva su identificador en TODOS sus eventos.

    contextvars y no una variable global: funciona con asyncio, donde varias
    peticiones se turnan en el mismo hilo. Es el MDC de siempre, y aquí
    resuelve un caso que el MDC por hilo no cubre.
    """
    request_id = request.headers.get("X-Request-ID") or str(uuid4())
    structlog.contextvars.clear_contextvars()
    structlog.contextvars.bind_contextvars(request_id=request_id, path=request.url.path)
    response = await call_next(request)
    response.headers["X-Request-ID"] = request_id
    return response
```

**Detalles con intención**

- **`utc=True` en la marca de tiempo.** Áurea opera en un huso, pero los registros se comparan con
  los de servicios que reportan en UTC, y una hora de diferencia a las dos de la mañana cuesta
  media hora de confusión.
- **`cache_logger_on_first_use=True`**, que es lo que hace que el costo por evento se quede en los
  ~10 µs de §6.1 en vez de reconstruir la cadena de procesadores cada vez.
- **A `stdout` y no a un archivo.** Rotar archivos es trabajo de operación y ya hay quien lo hace;
  el proceso solo tiene que escribir.
- **Y `format_exc_info`** para que la traza sea un campo del evento y no veinte líneas sueltas que
  se intercalan con las de otras peticiones.
- **La versión va en cada evento.** Un `structlog.contextvars.bind_contextvars(version=aur.__version__)`
  al arrancar responde la pregunta que la Fase 09 dejó abierta en su escenario 3 —qué versión
  corre en cada máquina—: la respuesta está en el registro, sin preguntarle a nadie.

### 5.2 Métricas

```python
from prometheus_client import Counter, Histogram, make_asgi_app

CLOSING_ROWS = Counter(
    "aurea_closing_rows_total", "Filas procesadas por el cierre nocturno", ["month"]
)
CLOSING_BATCH_SECONDS = Histogram(
    "aurea_closing_batch_seconds", "Duración de un lote del cierre",
    buckets=(0.1, 0.5, 1, 2, 5, 10, 30),     # los buckets se eligen; los de por defecto mienten
)

# El endpoint que raspa el recolector.
app.mount("/metrics", make_asgi_app())
```

**Detalles con intención**

- **Los *buckets* del histograma se eligen a mano.** Los valores por defecto están pensados para
  peticiones HTTP de milisegundos; con lotes de segundos, todo cae en el último *bucket* y el
  percentil 95 deja de significar nada.
- **Las etiquetas son pocas y de cardinalidad baja.** `month` tiene doce valores al año;
  `patient_document` tendría 2.800 y reventaría el recolector. Es el error clásico y es caro.
- **Y la métrica que de verdad importa en Áurea no es la latencia: es `¿terminó el cierre?`**. Un
  contador que sube una vez por noche, y una alerta si a las seis de la mañana no subió.

### 5.3 Trazas, con lo justo

```python
from opentelemetry import trace
from opentelemetry.instrumentation.fastapi import FastAPIInstrumentor
from opentelemetry.instrumentation.sqlalchemy import SQLAlchemyInstrumentor

FastAPIInstrumentor.instrument_app(app)
SQLAlchemyInstrumentor().instrument(engine=engine)

tracer = trace.get_tracer("aurea.cartera")


def run_closing(session, month, source):
    """El cierre, con un span por lote."""
    with tracer.start_as_current_span("cierre_mensual", attributes={"month": month}):
        while lote := read_batch(file, BATCH_SIZE):
            with tracer.start_as_current_span("lote", attributes={"rows": len(lote)}):
                process_batch(session, lote, month)
```

> 📝 **No hay agente mágico.** En Java pones un `-javaagent` y toda la aplicación queda
> instrumentada sin tocar código. Aquí se instala una biblioteca por framework
> —`opentelemetry-instrumentation-fastapi`, `-sqlalchemy`, `-httpx`— y se activa explícitamente.
> Es más trabajo, y a cambio sabes exactamente qué está instrumentado.

### 5.4 Configuración y secretos

```python
"""La configuración de los cuatro proyectos, validada al arrancar."""

from pydantic import Field, PostgresDsn, SecretStr
from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    """Configuración por ambiente. Falla al ARRANCAR si algo falta."""

    model_config = SettingsConfigDict(env_prefix="AUREA_", env_file=".env")

    database_url: PostgresDsn
    partner_secret: SecretStr            # SecretStr: no se imprime al hacer repr
    log_level: str = "INFO"
    batch_size: int = Field(default=20_000, ge=1_000, le=200_000)
    environment: str = "dev"
```

**Detalles con intención**

- **Falla al arrancar y no al usarse.** Un proceso que arranca bien y revienta a las 2:47 porque
  faltaba una variable es mucho peor que uno que no arranca. Es la validación en la frontera de la
  Fase 10, aplicada al ambiente.
- **`SecretStr` para el secreto**, que al imprimirlo muestra `**********`. No es seguridad de
  verdad —el valor está en memoria— pero evita el accidente más común: el secreto en un mensaje de
  error o en un volcado de configuración.
- **Y `.env` está en `.gitignore` desde la Fase 00.** El archivo que se versiona es `.env.example`,
  con los nombres y sin los valores.

### 5.5 Perfilar antes de tocar nada

Dos herramientas, y hacen cosas distintas:

**`cProfile`** instrumenta cada llamada. Da el detalle exacto de cuántas veces se llamó cada
función y cuánto tardó — y **distorsiona**: sobre código con muchas llamadas pequeñas, el
sobrecosto es notable. Sirve para desarrollar, no para producción.

```bash
uv run python -m cProfile -o cierre.prof -m cartera.cierre --mes 2026-01
uv run python -c "import pstats; pstats.Stats('cierre.prof').sort_stats('tottime').print_stats(15)"
```

**`py-spy`** muestrea la pila de un proceso **que ya está corriendo**, desde fuera, sin
modificarlo y sin reiniciarlo. Es lo más parecido a un `async-profiler`, y es lo que se usa en
producción:

```bash
uv run py-spy top --pid 4821          # en vivo
uv run py-spy record --pid 4821 -o perfil.svg --duration 60    # gráfico de llamas
```

**Y las dos columnas que hay que saber leer en `cProfile`:**

- **`tottime`** — el tiempo **en esa función**, sin contar lo que llamó. Es donde se va el tiempo
  de verdad.
- **`cumtime`** — el tiempo de esa función **y todo lo que llamó**. Es donde está la causa.

Ordenar por `tottime` te dice qué línea optimizar; ordenar por `cumtime` te dice **qué decisión
reconsiderar**. En el perfil de §6.2, `tottime` señala a `psycopg...wait` y `cumtime` señala a la
función del cierre: la respuesta no era optimizar `wait`, era no llamarlo veinte mil veces.

### 5.6 El orden correcto

```text
1. ¿Cuánto tarda de verdad?          → mide el total, con el arnés de la Fase 02
2. ¿Dónde se va el tiempo?           → perfila: cProfile en desarrollo, py-spy en producción
3. ¿Cuánto de eso es MÍO?            → si es esperar a la base o a la red, sigue en 4; si no, ve a 5
4. Arregla la consulta               → índice, una consulta en vez de N, menos filas
5. Y AHORA sí, el código Python      → y vuelve al paso 1 después de cada cambio
```

El paso 3 es el que casi nadie hace, y es el que evita el trabajo inútil.

### 5.7 Las salidas de emergencia, con su costo

Cuando el perfil dice que el tiempo está en tu código Python y ya no hay algoritmo que mejorar,
quedan cuatro salidas. **Ninguna es una recomendación**: las cuatro tienen un costo que hay que
presupuestar.

**Vectorizar con NumPy.** Si el trabajo es numérico y en lote, mueve el bucle a C. Compra órdenes
de magnitud y cuesta una dependencia pesada y un estilo de código distinto. No aplica a lo que
hace Áurea, que es texto y `Decimal`.

**Cython o `mypyc`.** Compila tu Python a C. Compra entre 2× y 10× en código con bucles cerrados,
y cuesta un paso de compilación, una rueda por plataforma —lo que la Fase 09 midió— y depuración
más difícil.

**Una extensión en Rust con PyO3.** Lo mismo, con mejor ergonomía moderna, y con el costo de
mantener código en otro lenguaje que solo tú sabes leer — en una empresa de un ingeniero, ese
costo es el que decide.

**Y la que casi siempre gana: no hacer el trabajo.** Cachear, precalcular, procesar menos filas,
o mover el cálculo a la base de datos. En el cierre de Áurea, la mejora de 27× de §6.2 fue
exactamente esto.

> ⚖️ **El umbral honesto:** si tu perfil dice que el 80% del tiempo está en un bucle de Python
> puro que ya no se puede mejorar algorítmicamente, y el trabajo justifica mantener un artefacto
> compilado, entonces Cython o Rust son la respuesta. En todo lo demás —y "todo lo demás" es el
> 95% de los casos— la respuesta está en los pasos 3 y 4 de §5.6.

### 5.8 Cuatro cabos que el curso dejó para la operación

Cuatro fases anteriores dejaron un problema anotado con destino aquí. Ninguno merece una sección
propia, y los cuatro aparecen en producción antes que en desarrollo.

**El archivo que sobrevive al apagón** (Fase 04, ejercicio 23). `os.replace` es atómico: el
archivo queda entero o no queda. Pero no garantiza que esté **en disco** si se corta la luz un
segundo después. Para eso, antes del `replace`, `f.flush()` y `os.fsync(f.fileno())` sobre el
temporal, y después un `fsync` del directorio (`os.open(dir, os.O_RDONLY)` y `os.fsync` sobre ese
descriptor), que es lo que hace durable el cambio de nombre. En macOS, `fsync` no vacía la caché
del disco; hace falta `fcntl.fcntl(fd, fcntl.F_FULLFSYNC)`.

**Los nietos que sobreviven a un `timeout`** (Fases 05 y 14). `subprocess.run(..., timeout=)` mata
al hijo, no a lo que el hijo lanzó. Se lanza el hijo en su propia sesión —`start_new_session=True`—
y, al vencer el plazo, se mata el grupo entero con `os.killpg(proc.pid, signal.SIGTERM)`. En
Windows el equivalente es un *job object*, que la biblioteca estándar no expone.

**El primer `import` lento después de instalar con `uv`** (Fase 07). `uv` no compila el *bytecode*
al instalar y `pip` sí, así que el primer arranque paga la compilación de todo lo que importa: 2.28
segundos para `fastapi` en la medición de la Fase 07. En un servidor que arranca una vez no
importa; en un contenedor que arranca muchas veces, se instala con `--compile-bytecode` (o
`UV_COMPILE_BYTECODE=1`) y se paga una sola vez, al construir la imagen.

**Las cadenas repetidas** (Fase 01, ejercicio 9). Medio millón de filas con el mismo código de sede
crean medio millón de objetos `str` iguales cuando se leen de un archivo. `sys.intern(sede)` hace
que todas apunten al mismo. Antes de usarlo, el arnés de la Fase 02 con `tracemalloc` dice si la
memoria de esas columnas es la que importa: si no lo es, `intern` es complejidad sin pago.

---

## 📏 6. Medición — dos bloques, porque son dos oficios

> ⚠️ **Estas dos mediciones no se promedian y no se mezclan.** Una responde *"¿cuánto cuesta
> ver?"* y la otra *"¿dónde está el tiempo?"*. Juntarlas produciría un número que no significa
> nada.

### 6.1 Lo que cuesta la observabilidad

**Hipótesis.** El registro estructurado cuesta más que el de texto plano en volumen y casi nada en
tiempo, y la instrumentación completa de la API cuesta un porcentaje visible pero pequeño de la
latencia.

**Condiciones.** CPython 3.14.5 · macOS 26.6 · Apple Silicon · `structlog` 26.1.0,
`opentelemetry-sdk` 1.44.0 · **20.000 eventos** por caso para el registro, escribiendo a archivo
local · para la API, `uvicorn` con el endpoint de disponibilidad de la Fase 10, 300 peticiones más
40 de calentamiento, cliente `httpx` en `127.0.0.1` · **el exportador de trazas descarta**: se
mide el costo de instrumentar, no el de mandar las trazas por la red, que dependería del
recolector.

**Resultado — el costo por evento de registro:**

| | Tiempo | Volumen |
|---|---|---|
| Sin registro | 0.04 µs | — |
| `logging` estándar, texto | 9.98 µs | 68 B/evento |
| **`structlog` JSON con contexto** | **10.69 µs** | **189 B/evento** |
| `logging.debug` con `DEBUG` apagado | **0.13 µs** | 0 B |

**Resultado — la API completa:**

| | Mediana | p95 |
|---|---|---|
| Sin instrumentar | 0.94 ms | 1.40 ms |
| **Con registro + trazas + métricas** | **1.07 ms** | **1.65 ms** |
| | **+14%** | **+18%** |

> ⚖️ **Veredicto.** El registro estructurado cuesta un 7% más de tiempo que el de texto y **2.8
> veces más volumen** —189 bytes contra 68—, y el volumen es lo único que hay que presupuestar de
> verdad: a un millón de eventos, son 189 MB contra 68 MB. Si tu proveedor de registros cobra por
> gigabyte ingerido, esa relación es una línea del presupuesto, no un detalle técnico.
>
> **A cambio, el JSON estructurado se consulta y el texto se lee.** Eso no aparece en ninguna
> columna y es la razón entera de la decisión: a las dos de la mañana, la pregunta es *"¿qué
> lotes del cierre de enero tardaron más de un segundo?"*, y contra texto plano eso no se puede
> preguntar.
>
> **La instrumentación completa cuesta un 14% de la latencia mediana y un 18% del p95.** Es
> visible, es aceptable para AgendaAPI —que tiene un volumen de tres mil citas al mes— y **no lo
> sería para un servicio de alto volumen**, donde habría que muestrear las trazas en vez de
> exportarlas todas.
>
> **Y la fila que más vale de la tabla es la última: `logging.debug` con `DEBUG` apagado cuesta
> 0.13 µs** — el 1.3% de un evento emitido. Eso significa que **dejar los `debug` puestos es
> gratis**, y que la práctica de borrarlos "para que no pesen" está optimizando algo que no pesa.
> Lo que sí pesa, y mucho, es dejarlos **encendidos** en producción.
>
> **El umbral:** por debajo de unos cientos de eventos por segundo, el costo del registro es
> irrelevante y la decisión es solo de utilidad. Por encima de unos miles, el volumen decide — y
> la respuesta es muestrear o subir el nivel, no escribir menos campos.

### 6.2 Dónde está el tiempo del cierre

**Hipótesis.** En el cierre nocturno, la mayor parte del tiempo **no es Python**: es esperar a la
base de datos. Y por lo tanto la primera mejora grande no está en el código.

**Condiciones.** PostgreSQL 18.0 local sobre socket Unix · psycopg 3.3.5 · **un lote de 20.000
filas** del archivo de ventas del trimestre · perfilado con `cProfile` · el trabajo por fila es el
del cierre de la Fase 15: comprobar que el paciente existe, calcular el hash de control y liquidar
la comisión en `Decimal`.

**Competidores.** El cierre "ingenuo" —una consulta por fila, que es el N+1 de la Fase 11 dentro
de un batch— contra el que trae los documentos conocidos en una sola consulta. **El cálculo es
idéntico en los dos**, línea por línea: lo único que cambia es cuántas veces se habla con la base.

**Resultado — tiempo:**

| | 20.000 filas |
|---|---|
| Ingenuo: una consulta por fila | 0.55 s |
| **Una sola consulta** | **0.02 s** |
| | **27×** |

**Resultado — el perfil del ingenuo** (`cProfile`, ordenado por tiempo acumulado):

```text
   ncalls  tottime  cumtime  función
        1    0.041    0.837  cierre_ingenuo
    20000    0.015    0.750  psycopg/cursor.py:execute
    20000    0.367    0.729  psycopg/connection.py:wait        ← esperando a Postgres
    40000    0.028    0.363  psycopg/_cursor_base.py:_execute_gen
    40000    0.089    0.213  psycopg/_cursor_base.py:_maybe_prepare_gen
```

**Y el perfil del optimizado** (ordenado por tiempo propio):

```text
   ncalls  tottime  cumtime  función
        1    0.020    0.031  cierre_con_una_consulta
    20000    0.006    0.006  hexdigest
    20000    0.004    0.004  openssl_sha256
    20001    0.002    0.002  str.encode
        1    0.000    0.000  psycopg/connection.py:wait        ← una sola vez
```

> ⚖️ **Veredicto. El 87% del tiempo del cierre ingenuo es esperar a la base de datos** —0.729 s
> de 0.837—, y de eso, 0.367 s es tiempo propio de `wait`: el proceso, literalmente, parado. Todo
> el código Python del cierre —el hash, el `Decimal`, el bucle, el parseo— **junto** es el 13%
> restante.
>
> **Eso es lo que hace que optimizar el Python sea teatro en este caso.** Un programador
> excelente que duplique la velocidad de todo el Python del cierre mejoraría el total un **6.5%**.
> Quitar el N+1 lo mejoró **27 veces**, y no tocó una línea del cálculo.
>
> **Y el segundo perfil dice qué hacer después**, que es la otra mitad de la lección: una vez
> arreglada la consulta, el tiempo propio se lo lleva `hashlib` —0.006 s de 0.031—. *Ahí* sí
> tendría sentido preguntarse si hace falta el hash por fila, o si se puede calcular en lote. Es
> el paso 5 de §5.6, y llega **después** del 4, no antes.
>
> **Dónde falla este veredicto**, y hay que decirlo: es una medición sobre socket local. Con la
> base en otra máquina, el 87% sube —cada consulta paga latencia de red— y la conclusión se
> refuerza. Pero si tu proceso **no habla con nada** —un cálculo puro sobre datos ya en memoria—
> el perfil va a decir lo contrario y **entonces sí** el Python es el problema. La regla no es
> "nunca optimices Python": es **perfila antes, y mira qué fracción del tiempo es tuya**.
>
> **El umbral, como criterio:** si el perfil dice que menos del 30% del tiempo es código tuyo, no
> optimices código: arregla la E/S. Si dice más del 70%, optimiza el código. Entre medias, el
> orden lo decide cuál de los dos es más fácil de cambiar.

**Lo que no se midió:** el cierre completo de 1.200.000 filas —se midió un lote, y la relación se
mantiene—, el efecto de la latencia de red, y el perfilado con `py-spy` sobre el proceso en
producción, que es lo que se usa de verdad y que el ejercicio 18 pide.

---

## 🧱 7. Miniproyecto — *Bajar el cierre de seis horas*

**El encargo**

Patricia: *"El cierre arranca a las dos y a veces todavía está corriendo cuando llego a las siete.
Cuando eso pasa no puedo facturar hasta la tarde, y si es día 5 se me atrasa todo el mes."* Y
Julián: *"¿Cuánto costaría un servidor más grande?"*

Instrumenta el cierre de la Fase 15, encuentra dónde se va el tiempo, y redúcelo — **con la
condición de que cada cambio venga con su número antes y después**.

**Por qué duele**

Porque la respuesta a la pregunta de Julián es probablemente *"nada, porque el servidor no es el
problema"*, y para poder decir eso hace falta el perfil. Y porque el instinto va a llevarte al
código Python, que es donde **no** está el tiempo.

**Datos de entrada**

El cierre de la Fase 15 corriendo sobre el trimestre completo, con la base de la Fase 11 y las
tablas de auditoría de la 15. Si tu cierre ya es rápido porque lo escribiste bien, **empeóralo a
propósito** —mete el N+1 de §6.2— y documenta que lo hiciste: el ejercicio es el método, no el
resultado.

**Criterios de aceptación**

- [ ] El cierre emite registro estructurado con: identificador de corrida, mes, número de lote,
      filas y milisegundos por lote. **Sin un solo dato clínico**, comprobado con `grep` sobre el
      archivo.
- [ ] Expone al menos tres métricas útiles, y una de ellas responde *"¿terminó el cierre?"*.
- [ ] Tienes un perfil **de antes**, guardado en el repositorio, con el reparto del tiempo entre
      consulta, serialización y código propio.
- [ ] **Al menos tres mejoras**, cada una con su número antes y después, aplicadas **en el orden
      de §5.6**. El registro de esos números es el entregable principal.
- [ ] **La regla bloqueante:** la primera mejora grande **no** puede ser código Python. Si tu
      primer cambio es una comprehension o un `lru_cache`, el miniproyecto no pasa — perfilaste
      después de optimizar.
- [ ] Respondes por escrito la pregunta de Julián: **cuánto mejoraría un servidor más grande**,
      con el perfil como argumento.
- [ ] **Medición:** tiempo total antes y después, y el reparto del perfil en los dos momentos.
      Esos números van en el mensaje del tag.

**Restricciones de registro**

> Esto es una **aplicación**, y la restricción propia de la fase es de método, no de forma: **no
> toques una línea de código hasta tener el perfil**. El reflejo que se ataca aquí es el del buen
> programador que ve un bucle y lo mejora — y que por eso gana un 6% donde había un 2.700%.

**La trampa**

Vas a mirar el bucle del cierre, vas a ver `Decimal`, `sha256` y un `split` por fila, y vas a
saber exactamente cómo mejorar los tres. Y los tres juntos son el 13% del tiempo.

La segunda trampa es más sutil y aparece **después** de arreglar la consulta: cuando el N+1 se
va, el perfil cambia de forma y lo que era irrelevante pasa a ser lo principal. **Hay que volver a
perfilar después de cada cambio**, porque el perfil de antes ya no describe el programa de ahora.
Optimizar tres cosas de un perfil viejo es la forma más común de perder una tarde.

**Pistas**

<details><summary>Pista 1 — el enfoque</summary>

Empieza midiendo el **total**, no el detalle. Después perfila **un lote**, no el cierre entero: el
perfil de veinte mil filas tiene la misma forma que el de un millón y se obtiene en segundos.

Y antes de mirar el perfil, escribe en un papel dónde **crees** que está el tiempo. Comparar esa
predicción con el perfil es la parte del ejercicio que más te va a enseñar.
</details>

<details><summary>Pista 2 — la herramienta</summary>

- [`cProfile` y `pstats`](https://docs.python.org/3.14/library/profile.html) — y las dos columnas
  de §5.5.
- [`py-spy`](https://github.com/benfred/py-spy) para el proceso en marcha, y `--duration` para
  muestrear un rato.
- `snakeviz` si prefieres ver el perfil en gráfico en vez de en tabla.
- Y del lado de la base: `EXPLAIN ANALYZE` (Fase 11) y el contador de consultas de §5.4 de esa
  misma fase. Si no sabes cuántas consultas emite tu lote, no sabes lo que cuesta.
</details>

<details><summary>Pista 3 — el esqueleto</summary>

```python
# medir.py — el registro de tus mejoras, que ES el entregable
MEJORAS = [
    ("línea base", None),
    ("una consulta en vez de N", "..."),
    ("...", "..."),
]

def perfilar_lote(fn, filas) -> pstats.Stats: ...
def reparto(stats) -> dict[str, float]:
    """Cuánto es base de datos, cuánto serialización, cuánto código propio."""
```
</details>

**Cómo se entrega**

```bash
uv run python -m cartera.cierre --mes 2026-01 --perfil antes.prof
# ... mejoras, una por una, cada una con su número ...
uv run python -m cartera.cierre --mes 2026-01 --perfil despues.prof
```

```bash
git add src/cartera perfiles/ MEJORAS.md
git commit -m "fase 16 mini: el cierre, perfilado y reducido"
git tag -a mini-16 -m "Mini F16: cierre de <N> s a <M> s (<K>×) · perfil: BD <A>%, Python <B>%"
```

<details><summary>💡 Solución de referencia — el método, que es lo que se evalúa</summary>

**La decisión de método que se tomó**, y es lo único que de verdad se evalúa: **el orden**. Medir,
perfilar, preguntar qué fracción es propia, arreglar la E/S, y **solo entonces** el código. El
otro camino —optimizar lo que salta a la vista— no es solo menos eficaz: produce cambios que
después hay que deshacer, porque complican el código a cambio de nada.

**Las tres mejoras típicas, en orden y con su magnitud esperada:**

1. **Quitar el N+1** — 27× en el lote medido. Es el paso 4 de §5.6 y casi siempre es el primero.
2. **Hacer el trabajo en lote en vez de fila por fila** —insertar con `executemany` en vez de un
   `INSERT` por fila, que es el mismo problema del otro lado—. Suele dar entre 5× y 20×.
3. **Y ahora sí, el código:** evitar reconstruir objetos, mover cálculos fuera del bucle, y —solo
   si el perfil lo señala— reconsiderar el hash por fila. Suele dar entre 1.2× y 2×.

Fíjate en la forma de los números: **las dos primeras son de orden de magnitud y la tercera es
marginal**. Esa proporción no es de este caso: es la forma habitual del problema, y es la razón
por la que el orden importa tanto.

**La trampa, entera.** Optimizar sin perfilar falla de dos maneras distintas. La primera es obvia:
mejoras lo que no importa. La segunda es la que pierde tardes: **perfilas una vez y optimizas tres
cosas de ese perfil**. Después del primer cambio, el programa es otro y el perfil viejo describe
un programa que ya no existe — lo que era el 3% puede ser ahora el 40%, y lo que era el 40% puede
haber desaparecido.

**La respuesta a Julián**, que es parte del entregable: un servidor más grande mejora lo que está
limitado por CPU. Si el 87% del tiempo es esperar a la base, un servidor con el doble de núcleos
mejora el cierre un **6.5%** en el mejor caso —y cuesta todos los meses—. La misma plata en
arreglar la consulta lo mejoró 27 veces, una sola vez. **Poder decir eso con un perfil delante es
la diferencia entre una opinión y una recomendación.**

**Qué se habría hecho distinto si el registro fuera otro.** Como script, el cierre tardaría lo que
tardara y nadie lo perfilaría — y eso es defendible para algo que corre una vez al mes con alguien
mirando. Lo que hace que esta fase exista es que **nadie está mirando**: un proceso desatendido
que se degrada lo hace en silencio hasta el día que no cabe en la ventana, y para entonces nadie
recuerda qué cambió.
</details>

---

## 🧪 8. Ejercicios (25)

**🟢 Fácil (1–6)**

1. Cambia todos los `print` de los cuatro proyectos por `logging`, con niveles. Cuenta cuántos
   eran y cuántos quedaron en `DEBUG`.
2. Configura `structlog` con salida JSON y emite un evento con cinco campos. Míralo con `jq`.
3. Agrega el identificador de petición con `contextvars` y comprueba que aparece en todos los
   eventos de esa petición.
4. Expón `/metrics` y mira lo que sale. Identifica tres métricas que vienen gratis.
5. Perfila un lote del cierre con `cProfile` y ordena por `tottime` y por `cumtime`. Explica por
   qué las dos listas son distintas.
6. Busca en tus registros de una corrida completa si se coló algún dato clínico. Usa `grep` con
   los nombres de los pacientes de prueba.

**🟡 Intermedio (7–14)**

7. Reproduce la medición de §6.1 en tu máquina y calcula cuánto costaría el volumen de registro al
   año con el precio de un proveedor real.
8. Configura el muestreo de trazas al 10% y mide de nuevo la latencia. Decide qué porcentaje
   dejarías para AgendaAPI.
9. Elige los *buckets* del histograma del cierre a partir de tus tiempos reales y explica por qué
   los de por defecto no sirven.
10. Mueve toda la configuración a variables de ambiente con validación, y demuestra que el proceso
    **no arranca** si falta una.
11. Escribe un `pickle` malicioso que ejecute un comando inofensivo al deserializarse. **En un
    directorio temporal.** Después explica dónde podría llegarte uno de verdad.
12. Provoca una explosión de cardinalidad: agrega `patient_document` como etiqueta de una métrica y
    mira qué pasa con `/metrics`. Cuenta las series.
13. Usa `py-spy top` contra el cierre mientras corre y compáralo con el perfil de `cProfile`. Anota
    en qué se parecen y en qué no.
14. Averigua qué hace `logging.Logger.isEnabledFor` y por qué existe, sabiendo que un `debug`
    apagado cuesta 0.13 µs.

**🟠 Difícil (15–21)**

15. **Diagnóstico.** La API está lenta y los registros no dicen nada. Con lo de esta fase, diseña
    los tres eventos mínimos que habrías necesitado para diagnosticarlo sin reproducirlo.
16. **Diagnóstico.** El cierre tarda el triple los lunes. Hay al menos tres causas plausibles
    —una es de datos, una de la base y una del sistema—. Di cómo distinguirlas con lo que ya
    instrumentaste.
17. **Medición.** Reproduce §6.2: escribe el N+1 a propósito, perfila, arréglalo, y vuelve a
    perfilar. Reporta el reparto del tiempo en los dos momentos.
18. **Medición.** Perfila el cierre con `py-spy` en producción —o en un proceso largo simulado— y
    compara el resultado con `cProfile`. Mide también cuánto distorsiona `cProfile` el tiempo
    total.
19. **Medición.** Mide el costo de la instrumentación de SQLAlchemy por separado: con y sin
    `SQLAlchemyInstrumentor`, sobre 1.000 consultas.
20. **De registro.** Julián pregunta si vale la pena pagar un servicio de observabilidad. Escribe
    la respuesta con el volumen de §6.1 proyectado, el costo de operar la alternativa, y qué
    pasaría si nadie mira los tableros.
21. **De registro.** Patricia quiere saber "si el cierre va bien" mientras corre. Decide si eso es
    una métrica, un registro, o una pantalla — y quién debería mirarlo.

**🔴 Muy difícil (22–25)**

22. **Adversarial.** Filtra datos clínicos en los registros de tres formas distintas: un `debug`
    olvidado, una excepción que incluye el objeto, y una traza de OpenTelemetry con el cuerpo de la
    petición como atributo. Ciérralas las tres y escribe la prueba que lo comprueba.
23. **Adversarial.** Consigue que la instrumentación **cause** un incidente: una etiqueta de
    cardinalidad alta, un registro síncrono a un destino lento, o un exportador que bloquea.
    Reproduce uno y explica cómo se habría evitado.
24. **Defiende una decisión.** Optimiza el código Python del cierre tanto como puedas **sin tocar
    la consulta**, mide la mejora, y compárala con la de arreglar la consulta. Escribe el
    resultado dirigido a alguien que quiere reescribir el cierre "en un lenguaje más rápido".
25. **Diseño.** Diseña la observabilidad mínima del cierre nocturno de forma que, si falla a las
    2:47, alguien pueda diagnosticarlo a las 7:00 **sin reproducirlo**: qué eventos, qué métricas,
    qué se conserva y cuánto tiempo. Es el ejercicio más útil de la fase para tu vida profesional.

**🔥 Opcionales**

- Instala `snakeviz` y mira un perfil en gráfico. Es la misma información y a veces se ve lo que en
  la tabla no.
- Investiga `memray` para perfilar memoria y úsalo sobre el cierre. Compáralo con lo que reporta
  `tracemalloc` de la Fase 02.
- Escribe una extensión mínima con `mypyc` o Cython para la función más caliente del cierre, mídela,
  y decide si vale lo que cuesta. Casi seguro no — y saber decirlo con un número es el punto.

---

## 📚 9. Referencias

**Documentación oficial**

- [`logging` — how-to](https://docs.python.org/3.14/howto/logging.html) y
  [configuración por diccionario](https://docs.python.org/3.14/library/logging.config.html).
- [`structlog`](https://www.structlog.org/) — en particular el capítulo de `contextvars`.
- [OpenTelemetry para Python](https://opentelemetry.io/docs/languages/python/) — instrumentación
  por biblioteca, y muestreo.
- [`prometheus_client`](https://prometheus.github.io/client_python/) — tipos de métrica y la
  advertencia sobre cardinalidad.
- [`profile` y `cProfile`](https://docs.python.org/3.14/library/profile.html) — y la explicación de
  `tottime` contra `cumtime`.
- [`py-spy`](https://github.com/benfred/py-spy) — muestreo sin modificar el proceso.
- [`pickle` — advertencia de seguridad](https://docs.python.org/3.14/library/pickle.html) — está en
  el primer párrafo de la documentación, en un recuadro, y aun así se sigue usando mal.

**Orden de lectura sugerido.** Antes de escribir: el how-to de `logging`, que desmitifica la
configuración. Durante: `structlog` y `prometheus_client`, por función. Después: la documentación
de `cProfile` sobre las columnas, que se entiende mucho mejor con un perfil delante.

> ⚠️ URLs y contenidos cambian; verifica antes de citar.

---

## 🚀 10. Cierre y conexión con la siguiente fase

Los cuatro proyectos son operables: emiten eventos que se pueden consultar, exponen métricas que
alguien puede mirar, y su configuración vive fuera del código con los secretos fuera del
repositorio.

Y te llevas dos cosas que valen fuera de Python. La primera es la regla: **primero SQL, después
Python** — con el 87% que la respalda y con el 27× que la demuestra. La segunda es el método de
§5.6, y sobre todo su paso 3: **preguntar qué fracción del tiempo es tuya antes de optimizar
nada**. Es lo que separa una tarde productiva de una que se siente productiva.

La **Fase 17** 🏁 cierra el curso con la única comparación que te va a servir el lunes: **el mismo
endpoint, implementado dos veces**, en FastAPI y en Spring Boot 3, con el mismo arnés —
rendimiento, latencia de cola, arranque en frío, consumo, líneas de código y costo mensual al
volumen real de Áurea. Y con el veredicto general: script, herramienta, aplicación… **o Java**.

El Spring Boot del duelo tiene que ser bueno, y eso no es cortesía: llevas once años escribiéndolo
y vas a notar en diez segundos si el competidor está mal configurado. Si lo está, la medición no
vale nada.

> **La señal de que quedó bien:** cuando alguien diga "hay que optimizar esto", tu primera pregunta
> ya no va a ser qué parte — va a ser si hay un perfil.

> 🏷️ **No cierres la fase sin el tag.** Con el checklist de la sección 2 en verde, el
> miniproyecto corriendo y `git status` limpio:
>
> ```bash
> git tag -a fase-16 -m "F16 cerrada:
> - registro estructurado con contexto de petición, y sin un solo dato clínico
> - métricas con buckets elegidos y etiquetas de cardinalidad baja
> - trazas con OpenTelemetry, instrumentadas por biblioteca
> - configuración validada al arrancar, secretos fuera del repositorio
> - el costo de ver, medido: +7% en tiempo y 2.8x en volumen; la API +14%
> - el perfil del cierre: 87% esperando a la base, y 27x al quitar el N+1"
> ```
>
> Los commits de la fase llevan su prefijo (`fase 16: …`), los de ejercicio su número
> (`fase 16 ej12: …`) y el miniproyecto el suyo (`fase 16 mini: …`). El miniproyecto terminado
> lleva además su tag anotado `mini-16`, y **en el mensaje de ese tag va el número que arrojó su
> medición**. La convención completa está en
> [`00-convencion-de-git-y-tags.md`](00-convencion-de-git-y-tags.md).
