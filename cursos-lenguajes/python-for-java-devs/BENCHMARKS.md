# 📊 BENCHMARKS
## Python para desarrolladores Java senior

Todas las mediciones del curso, en un solo sitio. Sirve para dos cosas: para recorrerlas sin
releer el material, y para que una fase pueda citar el número de otra sin repetirlo.

Cada entrada trae **de dónde salió, qué afirmaba, en qué condiciones, qué dio y a partir de qué
umbral cambia la respuesta**. El detalle completo —con el código y el competidor— está en la
sección 📏 de la fase enlazada.

---

## 🖥️ El entorno de referencia

Salvo que la entrada diga otra cosa, todos los números de este documento se tomaron aquí:

| | |
|---|---|
| Sistema | macOS 26.6 · Apple Silicon · **8 núcleos** |
| Intérprete | CPython **3.14.5** (y **3.14.7** más su compilación *free-threading* en la Fase 14) |
| Base de datos | PostgreSQL **18.0**, local, sobre socket Unix |
| JVM | OpenJDK **17.0.16** (Fase 00) y **21.0.8** (Fase 17), Zulu |
| Fecha | 12 de septiembre de 2026 |

> ⚠️ **Tus números van a ser distintos, y eso está bien.** Lo que tiene que conservarse es **la
> relación entre las opciones**, no el valor absoluto. Si en tu máquina la relación se invierte,
> eso es un hallazgo y vale la pena escribirlo — el ejercicio de medición de cada fase existe
> exactamente para eso.

> ⚠️ **La debilidad metodológica del curso, declarada:** casi todo se midió en un portátil de ocho
> núcleos, y **el dominio de Áurea tiene una máquina virtual de dos**. Las entradas de las Fases 14
> y 17 son las más afectadas, y las dos lo dicen en su sección. Reproducir las tablas con dos
> núcleos es el ejercicio pendiente más importante de este documento.

---

## 🅰️ Bloque A — el registro *script*

### 00 · Arranque en frío del intérprete contra la JVM

**Afirmaba:** que el arranque de Python es sensiblemente menor que el de la JVM, y que esa
diferencia importa para una herramienta que un cron invoca muchas veces.

**Condiciones:** 30 repeticiones por caso, 3 de calentamiento descartadas, medido desde crear el
proceso hasta recogerlo. JVM con y sin banderas de arranque.

| Caso | Mediana | p95 |
|---|---|---|
| `python -c "pass"` | 25.0 ms | 26.3 ms |
| `python -S -c "pass"` | 17.8 ms | 18.7 ms |
| `python -c "import json, csv, pathlib, argparse"` | 31.6 ms | 33.5 ms |
| `java -cp . Hello` | 42.0 ms | 52.1 ms |
| `java -XX:TieredStopAtLevel=1 -Xshare:auto Hello` | 39.9 ms | 41.5 ms |

⚖️ **1.7× a favor de Python, y son 17 ms** — que no deciden nada por debajo de decenas de miles de
invocaciones. **Lo aprovechable está en la tercera fila:** cuatro imports de la biblioteca
estándar cuestan 6.6 ms, un 26% sobre el arranque vacío. Las dependencias se pagan en cada
invocación.

→ [`00-instalacion-ambiente-editores-y-ecosistema.md`](00-instalacion-ambiente-editores-y-ecosistema.md) §6

---

### 01 · Pertenencia en `list` contra `set` contra `dict`

**Afirmaba:** que sobre los 2.800 pacientes activos de Áurea la diferencia deja de ser teórica.

**Condiciones:** 2.800 documentos con semilla `2026`, 2.800 consultas (mitad presentes), 15
repeticiones.

| Estructura | Mediana | Memoria |
|---|---|---|
| `list` | 53.97 ms | 23 KB |
| `set` | **0.101 ms** | 131 KB |
| `dict` | 0.106 ms | 104 KB |

Y la curva: 1.9× con 10 elementos, 9.5× con 50, 42× con 200, 624× con 2.800.

⚖️ **534× más rápido a cambio de 5.7× de memoria** (108 KB). **El umbral está alrededor de las 50
entradas**; por debajo da igual, por encima de mil no hay discusión. `set` y `dict` **empatan**:
la elección es de si necesitas el valor asociado.

→ [`01-modelo-de-datos.md`](01-modelo-de-datos.md) §6

---

### 02 · Lista intermedia contra tubería perezosa

**Afirmaba:** memoria constante contra memoria lineal. El tiempo era secundario — y resultó no
serlo.

**Condiciones:** 482.074 filas (27.1 MB) con semilla `2026`, el mismo cálculo en las dos formas,
verificado idéntico antes de medir. 5 repeticiones, pico con `tracemalloc`.

| Opción | Mediana | Pico de memoria |
|---|---|---|
| Lista intermedia | 349 ms | **291.0 MB** |
| Tubería perezosa | **171 ms** | **0.15 MB** |

| Filas | Lista | Perezosa |
|---|---|---|
| 1.000 | 0.4 ms / 0.6 MB | 0.4 ms / 0.15 MB |
| 50.000 | 31.3 ms / 30.2 MB | 19.5 ms / 0.15 MB |
| 482.074 | 369.9 ms / 291.0 MB | 161.8 ms / 0.15 MB |

⚖️ **Memoria constante contra 291 MB, y además 2.3× más rápida** — porque reservar 291 MB cuesta
trabajo. **Umbral: diez mil filas.** Por debajo, materializar está bien y es más fácil de depurar.

→ [`02-secuencias-perezosas.md`](02-secuencias-perezosas.md) §6

---

### 03 · La ceremonia, y el costo de un registro

**(a) El mismo motor de comisiones, dos estilos.** Verificados idénticos en los cuatro casos que
cubren las reglas especiales; líneas contadas con `ast`, sin docstrings ni comentarios.

| | Jerarquía de estrategias | Tabla + excepciones |
|---|---|---|
| Líneas | 54 | **22** |
| Clases | 7 | **0** |
| Agregar un aliado ordinario | 2 sitios | **0 sitios de código** |

**(b) Cinco formas de representar un registro**, 100.000 registros de cinco campos.

| | Memoria | Construir | Acceder |
|---|---|---|---|
| `tuple` | 9.6 MB | **9 ms** | 2.6 ms |
| `dict` | **19.2 MB** | 21 ms | 3.8 ms |
| `dataclass` | 12.0 MB | 22 ms | **2.4 ms** |
| **`dataclass(slots=True)`** | **8.0 MB** | 20 ms | **2.4 ms** |
| `NamedTuple` | 10.4 MB | 35 ms | 3.1 ms |

⚖️ **2.5× menos código y cero clases** para el mismo resultado; y `dataclass(slots=True)` gana en
memoria **y** en acceso: **el código más legible es también el más barato**. El `dict` solo gana
cuando las llaves no se conocen al escribir el código.

→ [`03-python-sin-ceremonia.md`](03-python-sin-ceremonia.md) §6

---

### 04 · EAFP contra LBYL

**Afirmaba:** que existe un punto de cruce y está más abajo de lo que se supone.

**Condiciones:** 200.000 filas por corrida, semilla `2026`, mediana de 7 repeticiones, las dos
versiones verificadas idénticas.

| Filas malas | LBYL | EAFP | Gana |
|---|---|---|---|
| 0% | 20.9 ms | **14.1 ms** | EAFP, 33% |
| 5% | 20.4 ms | **18.8 ms** | EAFP, 8% |
| **10%** | **20.0 ms** | 23.3 ms | LBYL, 14% |
| 100% | **8.0 ms** | 101.3 ms | LBYL, 92% |

⚖️ **El cruce está alrededor del 8% de fallos.** Y con cero fallos EAFP es **33% más rápido**: el
`try` que no lanza es casi gratis, y comprobar nunca lo es. La pregunta no es cuál es más rápido:
es **con qué frecuencia falla esto de verdad**.

→ [`04-errores-y-recursos.md`](04-errores-y-recursos.md) §6

---

### 05 · El costo de crear un proceso

**Condiciones:** 200 facturas con semilla `2026`, de las cuales **166 medibles** (se excluyen las
que el simulador hace fallar o colgarse). El firmador tarda 40–120 ms por factura, determinado por
el NIT, de modo que el trabajo es idéntico en las dos formas.

| | Una invocación por factura | Una por lote | Sobrecosto |
|---|---|---|---|
| 10 facturas | 1.198 s | **0.889 s** | +309 ms (1.3×) |
| 166 facturas | 20.299 s | **14.300 s** | **+6.0 s** (1.4×) |

Y el dato que lo explica: **crear un proceso de Python vacío cuesta 25 ms**.

⚖️ **Agrupar ahorra el 30%**, con un sobrecosto constante de ~36 ms por invocación. **El umbral es
proporcional:** con un trabajo de 80 ms por unidad eso es el 30%; con uno de 2 s sería el 1.8%.
Y agrupar tiene su costo: un cuelgue mata el lote entero y reanudar es más difícil.

→ [`05-shell-con-esteroides.md`](05-shell-con-esteroides.md) §6

---

### 06 · Releer los CSV contra un índice en `sqlite3`

**Condiciones:** histórico simulado de 1, 6 y 24 meses; **50 consultas resueltas en una sola
pasada** por los CSV —el competidor en su mejor versión—; índice `(document, code, date)`.

| Histórico | Filas | Releer CSV | `sqlite3` | Disco CSV | Disco `.sqlite3` |
|---|---|---|---|---|---|
| 1 mes | 6.000 | 3.0 ms | **0.30 ms** | 0.2 MB | 0.4 MB |
| 6 meses | 36.000 | 18.8 ms | **0.37 ms** | 1.2 MB | 2.6 MB |
| 24 meses | 144.000 | 70.6 ms | **0.28 ms** | 5.0 MB | 10.6 MB |

⚖️ **252× con dos años de histórico, y lo que decide es la forma de la curva:** el tiempo de
SQLite es plano y el del CSV se duplica cuando se duplica el histórico. **Umbral: unas 20.000
filas** —tres meses de Áurea—; y un segundo umbral que no es de tamaño: en cuanto necesites una
consulta que no sea "recórrelo todo", el CSV pierde aunque sea pequeño. Cuesta el doble de disco.

→ [`06-formatos-en-la-caja.md`](06-formatos-en-la-caja.md) §6

---

## 🅱️ Bloque B — la frontera

### 07 · Los tres gestores de entorno

**Condiciones:** el mismo encargo —FastAPI, SQLAlchemy, httpx, pytest y uvicorn sobre 3.14—, con
**caché aislada y vacía** para cada herramienta y una segunda pasada en caliente.

| | `pip` + `pip-tools` | **`uv`** | Miniforge |
|---|---|---|---|
| Instalar, caché fría | 11.1 s | **0.4 s** | 43.0 s |
| Recrear, caché caliente | 7.4 s | **0.1 s** | 12.5 s |
| Entorno en disco | 74 MB | **27 MB** | 211 MB |
| ¿Instala el intérprete? | **no** | sí (3.2 s) | sí |
| **Primer `import`** | **0.33 s** | **2.28 s** | 2.54 s |
| **Pasos de Patricia** | 6 | **2** | 4 |

⚖️ **`uv` es el gestor del curso, y la decisión la toma la última fila, no la primera.** Y trae una
pérdida que casi nadie publica: **el primer `import` cuesta 2.28 s contra 0.33 s**, porque `uv` no
precompila el bytecode al instalar (`--compile-bytecode` lo arregla). **Para este stack conda no
hace falta**: ninguna de las cinco dependencias necesita compilarse.

→ [`07-cuando-deja-de-ser-un-script.md`](07-cuando-deja-de-ser-un-script.md) §6

---

### 08 · El verificador sobre el código del Bloque A

**Condiciones:** `mypy --strict` sobre `aur_cli.py` tal como queda al cerrar la Fase 06: **250
líneas**, sin una sola anotación.

| Clase | Cuántos | ¿Es un error? |
|---|---|---|
| Falta anotar (`no-untyped-def`, `no-untyped-call`, `var-annotated`) | **40** | No: el precio de entrada |
| **Atributo que puede no existir** (`union-attr`) | **2** | **Sí** |
| **`return` prohibido en `except*`** (`misc`) | **1** | **Sí, y es un `SyntaxError`** |

⚖️ **De 43 errores, 3 son reales — un 7%.** Y uno de ellos era código **que no se puede
ejecutar**, escondido en una rama que las pruebas manuales nunca ejercitaron. Los otros 40 son
trabajo de anotación: en un proyecto grande son miles, y por eso el tipado de Python es **gradual**
y se enciende por módulo.

→ [`08-el-contrato-del-codigo.md`](08-el-contrato-del-codigo.md) §6

---

### 09 · Las cuatro formas de entregar

**Condiciones:** el paquete `aur` **sin dependencias de terceros** —dato que favorece a las
opciones basadas en archivo y hay que declararlo—. Arranque: mediana de 10 ejecuciones.

| | `uv tool` | `.pyz` | PEP 723 | Congelado `--onefile` | Congelado `--onedir` |
|---|---|---|---|---|---|
| Tamaño | 128 KB | **6.9 KB** | 1 archivo | 8.4 MB | 31.2 MB |
| **Arranque** | **49 ms** | 54 ms | 99 ms | **3.099 ms** | 55 ms |
| ¿Necesita Python? | no | **sí** | no | **no** | **no** |
| Actualizar | **un comando** | mandar el archivo | mandar el archivo | 8.4 MB | una carpeta |

⚖️ **`uv tool` para Áurea**, y no por los 49 ms: por ser la única que se actualiza con un comando
y la única que te deja saber qué versión corre cada máquina. **El "archivo único" del congelado
arranca 56× más lento** que la carpeta, porque se desempaqueta entero en cada ejecución. Y hay
**empate en arranque** entre `uv tool`, `.pyz` y `--onedir`: la columna que todo el mundo mira
primero es la que menos decide.

→ [`09-distribucion.md`](09-distribucion.md) §6

---

## 🅲 Bloque C — el registro *aplicación*

### 10 · El costo de validar en la frontera

**Condiciones:** endpoint que devuelve 36 espacios; 300 peticiones más 40 de calentamiento, con
`uvicorn` en `127.0.0.1`; y el costo de Pydantic sin HTTP, 2.000 repeticiones.

| Endpoint | Mediana | p95 |
|---|---|---|
| `GET /availability` con modelo de salida | 0.83 ms | 1.28 ms |
| `GET /availability-raw` sin modelo | 0.83 ms | 1.06 ms |
| `POST /bookings` inválido → 422 | **0.67 ms** | 1.01 ms |

| Operación pura | Mediana |
|---|---|
| Validar la entrada (4 campos) | **1.1 µs** |
| Validar la salida (36 objetos) | 16.6 µs |
| Validar **y serializar** | 38.5 µs |
| `json.dumps` del `dict` crudo | 12.1 µs |

⚖️ **Validar la entrada cuesta 1.1 microsegundos**, y sobre HTTP real el modelo de salida **no se
nota**: 0.83 contra 0.83 ms. La objeción no tiene sustento por debajo de unos cien objetos en la
respuesta. **Rechazar es más barato que aceptar** (0.67 contra 0.80 ms), que es el argumento de
rendimiento a favor de validar temprano.

📌 **Nota de método:** medido **en proceso**, el modelo de salida parecía costar un **33%** más.
Sobre HTTP real, la diferencia desapareció. Las dos mediciones son correctas y miden cosas
distintas.

→ [`10-fastapi.md`](10-fastapi.md) §6

---

### 11 · SQL directo, Core y ORM, y el N+1

**Condiciones:** PostgreSQL 18.0 local; 700 planes con 3.500 fases y 23.141 citas; la consulta de
disponibilidad devuelve 16 filas; 40 repeticiones.

| Forma | Mediana | p95 |
|---|---|---|
| SQL directo, **conexión nueva** | 3.39 ms | 4.38 ms |
| SQL directo, conexión reutilizada | **0.06 ms** | 0.12 ms |
| SQLAlchemy Core | 0.51 ms | 1.10 ms |
| SQLAlchemy ORM | 0.74 ms | 1.50 ms |

| N+1 sobre 200 planes | Mediana | Consultas |
|---|---|---|
| Navegando la relación | 42.7 ms | **201** |
| Con `selectinload` | **9.4 ms** | **2** |

| "Planes quietos más de 90 días" | Mediana | Consultas |
|---|---|---|
| Una consulta por plan | 18.6 ms | 701 |
| Un `JOIN` | **0.23 ms** | **1** |

⚖️ **El costo que domina no es el ORM: es la conexión.** Abrirla cuesta 56× lo que la consulta. El
ORM cuesta 45% más que Core —0.23 ms— que compran identidad y detección de cambios: **Core para
leer, ORM para modificar**. Y el N+1 es de otra magnitud: 4.5× en tiempo y 100× en consultas.

→ [`11-persistencia.md`](11-persistencia.md) §6

---

### 12 · El mismo CRUD, Django contra FastAPI

**Condiciones:** el mismo encargo —CRUD, autenticación, permisos por fila, ocultamiento de la nota
clínica y auditoría—, **las dos implementaciones ejecutadas** y verificadas con el mismo guion.

| | Django | FastAPI + Jinja2 |
|---|---|---|
| Líneas, primera pantalla | **76** | 204 |
| Archivos | **2** (+1 línea) | 6 |
| CSRF | incluido | **no implementado** |
| Paginación | incluida | **no implementada** |
| **Líneas, pantalla siguiente** | **23** | 70 |

⚖️ **Para el back-office, Django y no está cerca** — y la fila que decide es la última: con
cuarenta pantallas, 23 contra 70 es la diferencia entre un proyecto que una persona mantiene y uno
que no. **Para AgendaAPI el resultado se invierte**, porque el 100% de esa ventaja es interfaz de
usuario que una API no necesita. **Son dos registros, no dos calidades.**

→ [`12-django-y-el-veredicto-web.md`](12-django-y-el-veredicto-web.md) §6

---

### 13 · Qué se pierde y qué se duplica

**Condiciones:** 60 notificaciones por escenario contra el servidor de pruebas del curso, semilla
`2026`, envío en serie. **El conteo de lo que llegó lo da el receptor**, no el emisor.

| Escenario | Enviadas | **Llegaron** | El emisor dijo que perdió | **Duplicadas** |
|---|---|---|---|---|
| Socio intermitente, **sin defensas** | 60 | **40** | **0** | 0 |
| Con reintento | 60 | **60** | 0 | 0 |
| Con reintento **sin clave** | 60 | **89** | 0 | **29** |
| Con reintento **con clave** | 60 | **60** | 0 | **0** |
| Socio **mentiroso** (200 y no procesa) | 60 | **0** | **0** | 0 |

| Socio lento | Tiempo (10 notif.) | Dadas por perdidas | **Llegaron** |
|---|---|---|---|
| Sin timeout | 39.3 s | 0 | 10 |
| Con timeout de 1 s | 10.0 s | **10** | **10** |

⚖️ **Sin defensas se pierde el 33% en silencio.** Con reintento y sin clave de idempotencia se
duplica el **48%**. Y la última tabla desmonta el modelo mental: **un timeout no es una
cancelación** — el emisor dio diez por perdidas y las diez se habían procesado. La idempotencia no
es una buena práctica: **es la condición para que reintentar sea legítimo**.

→ [`13-integraciones.md`](13-integraciones.md) §6

---

### 14 · El GIL, las dos cargas

**Condiciones:** 4 trabajadores, 8 núcleos; CPython **3.14.7** y su compilación *free-threading*;
CPU: conciliar 1.200.000 filas; E/S: 100 esperas de 10 ms.

**Carga de CPU:**

| Forma | Con GIL | Sin GIL |
|---|---|---|
| Secuencial | 0.83 s (1.00×) | 0.81 s (1.00×) |
| **Hilos** | 0.81 s (**1.02×**) | 0.71 s (**1.14×**) |
| Procesos, datos serializados | 0.94 s (**0.88×**) | 0.97 s (0.83×) |
| **Procesos, cada uno lee lo suyo** | **0.44 s (1.86×)** | 0.51 s (1.59×) |

**Carga de E/S:**

| Forma | Con GIL | Sin GIL |
|---|---|---|
| Secuencial | 1.18 s (1.00×) | 1.21 s (1.00×) |
| **Hilos** | 0.30 s (**3.95×**) | 0.30 s (4.01×) |
| Procesos | 0.38 s (3.15×) | 0.40 s (3.03×) |
| **`asyncio` con `TaskGroup`** | **0.28 s (4.32×)** | — |
| `asyncio` con `time.sleep` adentro | 1.20 s (**1.01×**) | — |

**Controles:** aritmética de Python puro con 4 hilos: **1.02× con GIL, 2.27× sin GIL**. Y **no hay
penalización de un solo hilo** en la compilación sin GIL: 0.272 contra 0.271 s.

⚖️ **La inversión es el punto: hilos 1.02× para CPU y 3.95× para E/S.** La única pregunta es *¿esto
espera o calcula?* Los procesos **pierden contra secuencial** cuando los datos cruzan la frontera.
`asyncio` se convierte en nada si bloqueas el bucle. Y el free-threading es **cierto y parcial**:
2.27× con Python puro, 1.14× con la carga real.

→ [`14-concurrencia-y-gil.md`](14-concurrencia-y-gil.md) §6

---

### 15 · El fallo de la hora cinco

**Condiciones:** 1.200.000 filas, lotes de 20.000, punto de control en `sqlite3` con
**desplazamiento en bytes**, fallo inyectado al 80%.

| Corrida normal | Tiempo | Sobrecosto |
|---|---|---|
| Sin punto de control | 1.35 s | — |
| Con punto de control | 1.47 s | **+9%** |

| Con el fallo | Hasta el fallo | Recuperación | **Total** | **Perdido** |
|---|---|---|---|---|
| Sin punto de control | 1.15 s | 1.45 s | 2.60 s | **960.000 filas** |
| Con punto de control | 1.25 s | **0.31 s** | **1.56 s** | **0 filas** |

⚖️ **Cuesta 9% en la corrida buena y ahorra el 100% del trabajo en la mala.** Escalado a la ventana
de seis horas: 32 minutos más, contra cinco horas rehechas que ya no caben en la noche.
**Hallazgo de método:** guardar el **número de filas** en vez del desplazamiento dispara el
sobrecosto del 9% al **319%**, porque reanudar se vuelve cuadrático.

→ [`15-el-proceso-nocturno.md`](15-el-proceso-nocturno.md) §6

---

### 16 · Observabilidad, y dónde está el tiempo

**(a) Lo que cuesta ver.** 20.000 eventos; API con 300 peticiones.

| | Tiempo | Volumen |
|---|---|---|
| Sin registro | 0.04 µs | — |
| `logging` estándar, texto | 9.98 µs | 68 B |
| **`structlog` JSON con contexto** | **10.69 µs** | **189 B** |
| `logging.debug` con `DEBUG` apagado | **0.13 µs** | 0 B |

| API | Mediana | p95 |
|---|---|---|
| Sin instrumentar | 0.94 ms | 1.40 ms |
| Con registro + trazas + métricas | **1.07 ms (+14%)** | 1.65 ms (+18%) |

**(b) Dónde está el tiempo del cierre.** Un lote de 20.000 filas contra PostgreSQL 18.

| | Tiempo |
|---|---|
| Una consulta por fila | 0.55 s |
| **Una sola consulta** | **0.02 s (27×)** |

Y el perfil del ingenuo: **0.729 s de 0.837 son `psycopg...wait`** — el 87%.

⚖️ **El estructurado cuesta 7% más de tiempo y 2.8× el volumen**; el volumen es lo único que hay
que presupuestar. **Un `debug` apagado cuesta 0.13 µs: dejarlos puestos es gratis.** Y el
veredicto que ordena la fase: **el 87% del cierre es esperar a la base**, así que duplicar la
velocidad de todo el Python mejoraría el total un 6.5%. **Primero SQL, después Python.**

→ [`16-operacion-y-rendimiento.md`](16-operacion-y-rendimiento.md) §6

---

### 17 · El duelo: FastAPI contra Spring Boot 3

**Condiciones:** Spring Boot **3.5.16** sobre Java 21 (Zulu 21.0.8), JAR ejecutable, sin ajustes de
JVM · FastAPI 0.141.1 con Uvicorn 0.52.4 sobre CPython 3.14.5 · las dos respuestas verificadas
idénticas con `diff` · carga con **ApacheBench**, 20.000 peticiones, concurrencia 32 · arranque:
mediana de 5, con el puerto verificado libre.

| | req/s | p50 | p95 | p99 |
|---|---|---|---|---|
| **Spring Boot 3.5.16** | **13.834** | **2 ms** | **5 ms** | **8 ms** |
| uvicorn, 1 trabajador | 2.508 | 12 ms | 15 ms | 24 ms |
| uvicorn, 4 trabajadores | 6.258 | 4 ms | 7 ms | **9 ms** |
| uvicorn, 8 trabajadores | 6.905 | 4 ms | 9 ms | 20 ms |

| | Spring Boot 3 | FastAPI (1 trab.) | FastAPI (4 trab.) |
|---|---|---|---|
| Arranque en frío | 1.328 ms | **277 ms** | 429 ms |
| RSS en reposo | 216 MB | **54 MB** | **263 MB** |
| Líneas de código | 57 + 39 de config | **23** | 23 |
| Imagen | 329 MB | **297 MB** | 297 MB |
| **Arranque del contenedor** | **1.485 ms** | **1.359 ms** | — |
| **Costo al volumen de Áurea** | **$6/mes** | **$6/mes** | — |

⚖️ **Spring Boot gana el rendimiento 2.2×** (5.5× contra el despliegue ingenuo de un solo
trabajador). **FastAPI gana el arranque en frío 4.8×, la memoria 4× y las líneas 2.5×.** Y **tres
empates que casi ningún *benchmark* publica**: el arranque **dentro de un contenedor** (1.359
contra 1.485 ms — la ventaja de Python se evapora), la **memoria a igual rendimiento** (263 contra
216 MB: Python pierde), y la **latencia p99** (9 contra 8 ms). **El umbral está en unas 6.000
req/s sostenidas**; Áurea está tres órdenes de magnitud por debajo, y **el costo mensual es el
mismo para los dos**.

📌 **Confesión de método:** el primer generador de carga —escrito en Python con `httpx`— dio 390 y
418 req/s, números casi idénticos y por lo tanto sospechosos. El cuello de botella era el cliente.
**Un generador que no puede superar al servidor mide al generador.**

**No se midió:** GraalVM native-image ni compilación anticipada de Spring (cambiarían la columna
del arranque), ajustes de JVM, el comportamiento con base de datos de por medio, ni una máquina de
dos núcleos.

→ [`17-el-duelo-y-el-veredicto.md`](17-el-duelo-y-el-veredicto.md) §6

---

## 🧮 Los números que más se citan

Si solo te llevas doce de este documento, que sean estos — los diez del camino base y los dos
que trajeron los complementos:

| Número | Qué dice | Fase |
|---|---|---|
| **291 MB → 0.15 MB** | Materializar contra recorrer perezoso | 02 |
| **534×** | `set` contra `list` para preguntar "¿está?" | 01 |
| **8%** | La tasa de fallos donde EAFP deja de ganarle a comprobar | 04 |
| **2 pasos contra 6** | Lo que `uv` le ahorra a quien no es ingeniero | 07 |
| **3 de 43** | Errores reales al encender el verificador sobre código sin tipar | 08 |
| **1.1 µs** | Lo que cuesta validar en la frontera | 10 |
| **56×** | Abrir una conexión contra usar una del *pool* | 11 |
| **29 duplicados de 60** | Reintentar sin clave de idempotencia | 13 |
| **1.02× / 3.95×** | Hilos para CPU contra hilos para E/S | 14 |
| **87%** | Cuánto del cierre nocturno es esperar a la base de datos | 16 |
| **34 ms contra 97** | El bucle a mano ganándole a DuckDB en el informe mensual de Áurea | `ds03` |
| **20 de 40** | Síntomas que el guardrail léxico deja pasar, y que deciden si Recepción asistida se despliega | `ia07` |

---

## 🤖 Complementos `ia` — pendientes de ejecutar

> ⏳ **Las nueve mediciones del track de IA están especificadas y, salvo una fila, sin ejecutar.**
> Cada una tiene su hipótesis, sus condiciones, su competidor y su comando escritos en su 📏;
> lo que falta es correrlas. Se listan aquí **en vez de omitirlas** por la misma razón por la que
> el curso publica sus empates: un documento que solo muestra lo medido esconde cuánto falta.
>
> Tres de ellas cuestan dinero real —llaman a la API— y una necesita el único insumo que un script
> no puede producir: treinta juicios humanos. Ninguna cifra del track se cita en ninguna parte
> hasta que su medición exista.

| Sección | Qué compara | Estado |
|---|---|---|
| [`ia01`](ia01-el-modelo-de-acceso-de-un-llm.md) | Opus 5 ⇄ Haiku 4.5 ⇄ modelo local: latencia, tokens y **costo por respuesta** | ⏳ |
| [`ia02`](ia02-salida-estructurada.md) | Tres estrategias de salida estructurada: validez al primer intento y **citas fabricadas** | ⏳ |
| [`ia03`](ia03-tool-calling-y-el-bucle-de-agente.md) | Descripciones de herramienta pobres ⇄ completas, y **formulario + SQL sin agente** | ⏳ |
| [`ia04`](ia04-embeddings-y-busqueda-semantica.md) | `pgvector` ⇄ texto completo de Postgres ⇄ híbrida, **cortado por tipo de pregunta** | ⏳ |
| [`ia05`](ia05-normarag.md) | Contexto completo ⇄ RAG ⇄ **solo recuperar sin generar** ⇄ Patricia con los PDF | ⏳ |
| [`ia06`](ia06-evaluacion.md) | Cuatro formas de calificar contra juicio humano: acuerdo y **kappa** | ⏳ |
| [`ia07`](ia07-recepcion-asistida.md) | Cuatro guardrails: resolución y **falsos negativos** | 🟡 **parcial** |
| [`ia08`](ia08-produccion-y-el-veredicto.md) · 6.1 | Tres colocaciones de la caché de prompt sobre el tráfico de un día | ⏳ |
| [`ia08`](ia08-produccion-y-el-veredicto.md) · 6.2 | Bucle propio ⇄ LangChain ⇄ LlamaIndex ⇄ Pydantic AI, misma tarea y mismo conjunto | ⏳ |

> 🟡 **La única fila del track que ya tiene número es la del guardrail léxico de `ia07`**, y la
> tiene porque **no llama al modelo**: se corre gratis con `--solo-lexico`. Sobre setenta mensajes
> —treinta solicitudes de agenda y cuarenta con síntoma— resuelve el 67% sin persona, deja pasar
> **veinte síntomas** (los veinte que no usan su vocabulario) con **un** falso positivo, en
> centésimas de milisegundo. Ese 20 es el número que decide si Recepción asistida se despliega, y
> la conversación que abre no es técnica: el umbral aceptable lo fijan Marcela y Julián, que son
> quienes tienen el registro profesional.

**Y un número del track que no es una medición sino aritmética, y que conviene tener a la vista:**
partiendo de una calidad del 80%, detectar una mejora de **diez puntos** necesita unos **98 casos**
de evaluación; detectar **cinco**, unos **444**. Se reproduce con
`required_sample_size` de `src/ia06-evaluacion/statistics_helpers.py`. Es el número que limita todo
lo que el track puede afirmar sobre calidad, y por eso está aquí y no escondido en una sección.

---

## 📊 Complementos `ds` — el track de datos

> ✅ **A diferencia del track de IA, estas mediciones están ejecutadas.** No cuestan dinero, no
> necesitan una API ni juicios humanos: corren en un portátil con dos dependencias. Se tomaron en
> el entorno de referencia de este documento, con CPython **3.14.5**.

### ds01 · El bucle, la comprehension y el array

**Afirmaba:** que vectorizar la suma agrupada le gana al bucle por un orden de magnitud, y que el
umbral en el que **conviene** hacerlo es mucho más alto que eso porque la conversión desde una
lista de diccionarios se paga entera y se paga cada vez.

**Condiciones:** NumPy 2.5.3. `pauta.csv` del generador del Embudo, semilla 20260913, 49.260 filas
reales; los tamaños mayores son **el bloque real repetido** —sintético y declarado—. Cinco
repeticiones hasta el millón de filas, tres a cinco millones. Las cuatro versiones corren sobre las
mismas filas en memoria y hay una prueba que verifica que devuelven lo mismo.

| Filas | bucle | comprehension | vectorizado | vectorizado + conversión |
|---|---|---|---|---|
| 1.000 | 0,128 ms | 0,196 ms | **0,007 ms** | 0,276 ms |
| 100.000 | 14,8 ms | 29,9 ms | **0,526 ms** | 38,2 ms |
| 5.000.000 | 787 ms | 1.387 ms | **24,2 ms** | 1.865 ms |

⚖️ **32× sobre columnas ya construidas, y una derrota de 2,4× si hay que convertir.** El umbral no
es de tamaño sino de reúso: `k` cuentas vectorizadas valen `1840 + 24k` ms contra `787k` del bucle,
así que **a partir de la tercera** agregación sobre las mismas columnas el array gana. Con una
sola, pierde a cualquier tamaño. Y la comprehension por canal —la versión "pythónica"— es **un 82%
más lenta que el bucle** al que pretende mejorar.

→ [`ds01-numpy-y-el-modelo-vectorizado.md`](ds01-numpy-y-el-modelo-vectorizado.md) §6

### ds02 · El orden de unir y agregar

**Afirmaba:** que el orden de las operaciones domina sobre todo lo demás, y que los dtypes ayudan
mucho menos de lo que se cree.

**Condiciones:** pandas 3.0.5. Datos **reales** de Áurea, sin repetir bloque: 6.065 planes y 81.274
cuotas, semilla 20260913. Cinco repeticiones. Cada variante corre **en su propio proceso** y se
reporta el pico de RSS del sistema operativo, no `tracemalloc` — pandas asigna fuera del asignador
de Python y `tracemalloc` no lo ve. Las tres variantes producen la misma tabla, verificado por
prueba.

| Variante | Mediana | p95 | Pico RSS | Sobre la línea base |
|---|---|---|---|---|
| solo importar pandas | — | — | 76,9 MB | — |
| unir + `apply` | 286,7 ms | 295,8 ms | 131,2 MB | 54,3 MB |
| unir + máscara | 18,4 ms | 19,6 ms | 117,5 MB | 40,6 MB |
| **agregar + unir** | **11,1 ms** | **11,5 ms** | **107,3 MB** | **30,4 MB** |

⚖️ **26× en total, y casi la mitad de la memoria.** Quitar `apply(axis=1)` da 15,6× por una línea;
cambiar el orden —agregar antes de unir— agrega otro 1,7× y baja el trabajo de 54,3 a 30,4 MB.
**El umbral, dicho entero: a la escala de Áurea nada de esto decide nada** —son 287 ms contra 11,
una vez al mes—; empieza a decidir cuando el informe entra al cierre nocturno de la Fase 15 o
alguien lo corre en un bucle por sede y por mes. Lo que sí importa a cualquier tamaño es
`validate=`, que no es rendimiento sino corrección.

**Y el número incómodo:** importar pandas cuesta **76,9 MB** antes de leer un solo dato, para un
informe que maneja 10 MB. Para un script mensual da igual; para un contenedor que atiende
peticiones, no.

→ [`ds02-pandas.md`](ds02-pandas.md) §6

### ds03 · Cuatro motores, dos preguntas y dos ganadores

**Afirmaba:** que el motor perezoso le gana al ansioso y los dos al bucle, **y que todo eso deja
de ser cierto al tamaño y la frecuencia reales de Áurea**, donde el arranque de la dependencia
pesa más que la consulta.

**Condiciones:** pandas 3.0.5, Polars 1.44.2, DuckDB 1.5.5. El consolidado mensual de las diez
sedes —cinco cifras, cuatro fuentes, un `join` inevitable— sobre seis tamaños, **cuatro de ellos
recortes reales** del conjunto del Embudo: un mes (11.116 filas), un trimestre (30.392), un año
(115.332) y la historia completa (298.581); los dos mayores, a escala 4 y 16, son sintéticos
declarados. Cinco repeticiones por celda. Un proceso por celda, pico de RSS del sistema
operativo. **Los cinco motores devuelven exactamente la misma tabla**, verificado por prueba.

**La consulta, con el motor ya cargado:**

| Motor | Líneas | Importar | 11k | 299k | 1,1M | 4,2M |
|---|---|---|---|---|---|---|
| bucle (stdlib) | 28 | 23 MB | 6,3 ms | 276,2 ms | 847,8 ms | 3.148,3 ms |
| pandas | 25 | 105 MB | 12,2 ms | 85,4 ms | 259,4 ms | 916,2 ms |
| polars (lazy) | 27 | 57 MB | **3,6 ms** | 11,1 ms | 28,8 ms | 122,6 ms |
| duckdb (csv) | 33 | 45 MB | 146,6 ms | 196,2 ms | 258,0 ms | 346,8 ms |
| duckdb (parquet) | 32 | 45 MB | 8,4 ms | **12,3 ms** | **16,0 ms** | **25,1 ms** |

**El informe completo, de punta a punta**, cada motor en un entorno con solo su dependencia:

| Motor | 11k | 30k | 115k | 299k |
|---|---|---|---|---|
| bucle (stdlib) | **34 ms** | **49 ms** | 120 ms | 297 ms |
| duckdb (parquet) | 97 ms | 98 ms | **98 ms** | **103 ms** |
| polars (lazy) | 150 ms | 151 ms | 154 ms | 154 ms |
| pandas | 326 ms | 346 ms | 373 ms | 453 ms |

⚖️ **Tres veredictos.** (1) **Para el informe mensual de Áurea gana la biblioteca estándar**: 34
ms contra 97 de DuckDB y 326 de pandas, sin instalar nada. El umbral está **entre 30.000 y
115.000 filas** —entre un trimestre y un año de la red—, y Áurea genera unas 11.000 filas al mes.
(2) **Con el proceso caliente el orden se invierte y no está cerca**: DuckDB sobre Parquet hace
en 25,1 ms lo que al bucle le toma 3.148, **125×** a 4,2 millones de filas. (3) **El formato pesa
más que el motor**: el mismo SQL tarda 346,8 ms sobre CSV y 25,1 sobre Parquet —**14×**— y el
Parquet ocupa entre 24 y 42 veces menos disco, con un costo de conversión de 222 a 431 ms que se
paga una sola vez.

**Y un empate que vale la pena:** en líneas de código efectivas los cinco motores están entre
**25 y 33**. "En SQL son cuatro líneas" no sobrevive a contar el SQL.

**Arranque en frío, que es de dónde sale todo lo anterior:** intérprete solo **26,3 ms**; con
DuckDB **84,7**; con Polars **129,2**; con pandas **342,7**.

→ [`ds03-polars-y-el-modelo-lazy.md`](ds03-polars-y-el-modelo-lazy.md) §6

### ds04 · Cuatro atribuciones, cuatro respuestas

**Afirmaba:** que la elección del modelo de atribución mueve el costo por paciente adquirido
**más que cualquier diferencia real entre canales**, y que esa diferencia no es ruido de
muestreo.

**Condiciones:** biblioteca estándar, sin dependencias. Conjunto del Embudo con semilla
20260913: 32.550 leads y 6.065 adquiridos. Corte el 2026-03-31 con **madurez de 96 días** —el
rezago máximo del canal más lento—, que deja 28.416 leads maduros y **5.451 pacientes**. El
gasto se recorta a la misma ventana: 5.283.929.067 COP. Intervalo bootstrap por percentiles,
200 remuestreos, semilla fija. Los cuatro modelos corren sobre el mismo conjunto de pacientes y
**los cuatro reparten 5.451,0 créditos**, verificado por prueba.

Costo por paciente adquirido, en millones de COP, con su intervalo al 95%:

| Canal | Primer toque | Último toque | Lineal | Decaimiento |
|---|---|---|---|---|
| google | 2,76 [2,59–3,04] | **1,55** [1,47–1,64] | 2,01 [1,94–2,10] | 1,90 [1,83–1,98] |
| instagram | 1,14 [1,09–1,18] | 3,35 [3,08–3,67] | 1,74 [1,66–1,80] | 1,81 [1,73–1,88] |
| tiktok | **1,06** [1,03–1,11] | **7,96** [7,01–9,07] | 1,93 [1,87–2,02] | 2,14 [2,07–2,25] |

⚖️ **7,5× sobre los mismos 5.451 pacientes, y el ranking no se mueve: se invierte.** TikTok es
el canal más barato de los tres por primer toque y el más caro por un factor de cinco por último
toque. **No es ruido:** los intervalos al 95% ni se tocan —[1,03–1,11] contra [7,01–9,07]—, así
que la diferencia viene de quién decide que un video cuenta, no de qué pacientes tocaron. La
recomendación es reportar el **lineal** como cifra principal y publicar las dos esquinas al
lado: la banda entre modelos **es** la incertidumbre real.

**Y dos correcciones técnicas que casi nadie aplica**, con su efecto medido: esperar a que las
cohortes maduren y recortar el gasto a la misma ventana abaratan a TikTok un **8,6%**, a
Instagram un 5,9% y a Google un 2,2% —cuanto más lento el canal, más lo castiga el cálculo
ingenuo—. Son correcciones reales, y **mueven cuarenta veces menos que la elección del
modelo**.

**La red de aliados**, que nadie había calculado: 23 aliados, 2.599 remisiones, **925 pacientes
retenidos (35,6%)** y 1.165.174.000 COP de comisiones → **1.259.648 COP por paciente retenido**,
entre el costo de Google (1,55 M) y el de Instagram (3,35 M). Es el segundo canal más barato de
la empresa. Entre el mejor aliado y el peor hay 1,68×, más que entre especialidades (1,20×) o
zonas (1,16×).

→ [`ds04-embudo.md`](ds04-embudo.md) §6

### ds05 · Cuatro formas del mismo tablero

**Afirmaba:** que las tres bibliotecas de gráficos cuestan bastante más que una tabla de texto
en las cuatro dimensiones que importan, y que la diferencia entre ellas es menor que la
diferencia con no usar ninguna.

**Condiciones:** matplotlib 3.11.2, plotly 7.0.0, altair 6.2.2. El mismo tablero —tres canales
con la banda de `ds04`—. Cinco repeticiones con la biblioteca cargada; cinco procesos nuevos
para el tiempo en frío. **Cada opción en un entorno donde solo está su dependencia.**

| Opción | Render | En frío | Pico RSS | Artefacto | Líneas |
|---|---|---|---|---|---|
| **tabla de texto** | **0,07 ms** | **30 ms** | **23 MB** | **0,35 KB** | **6** |
| altair | 9,7 ms | 275 ms | 108 MB | 2,3 KB | 13 |
| plotly | 14,6 ms | 193 ms | 111 MB | 9,4 KB | 15 |
| matplotlib | 57,5 ms | 457 ms | 113 MB | 29,3 KB | 18 |

⚖️ **Para las siete cifras del comité de franquicia, gana la tabla** — y no por los 30 ms, que
a nadie le importan, sino porque **cabe la columna de la banda**, se pega en un correo y se
compara con la del mes pasado con un `diff`. Entre las tres bibliotecas la elección es por
destino: matplotlib es la única que se ve sin navegador y cuesta el doble en frío que plotly;
altair da el archivo más chico y la especificación más revisable. **El umbral:** la tabla gana
mientras el dato quepa en una pantalla y lo que importe sean los valores; en cuanto la pregunta
sea *"¿sube o baja?"* sobre veintisiete meses, pierde y no está cerca.

**Dos números al margen que deciden más que la tabla:** el HTML de plotly pesa 9,4 KB con el
JavaScript traído de un CDN y **4,10 MB** con él embebido —435×, por un argumento— y el dorado
de la marca de Áurea da **3,25** de contraste: no sirve para texto (4,5 exige la norma) y sí
para una barra (3,0). Y la paleta completa **no sobrevive a una impresión en gris**: teja y
pizarra quedan a 1,04 de contraste entre sí.

⏳ **Pendiente, y es la que de verdad importa:** *tiempo hasta la primera decisión correcta* con
cinco personas sobre las tres presentaciones. El protocolo está completo en `ds05` §6.2; lo que
falta son cinco voluntarios. Es la única medición del track que no se puede hacer con un portátil.

→ [`ds05-visualizacion.md`](ds05-visualizacion.md) §6

### ds06 · Cuántos cuadernos vuelven a correr

**Afirmaba:** que de una carpeta de cuadernos escritos con normalidad la mayoría no reejecuta, y
que el subconjunto que además da el mismo resultado dos veces es todavía menor.

**Condiciones:** `nbclient` 0.11.0 vía papermill 2.7.0 y jupyterlab 4.6.3. Seis cuadernos del
análisis del Embudo —uno limpio y cinco con un defecto sembrado, todos guardados **con sus
salidas**—. Cada uno en un **kernel nuevo**, desde un **directorio temporal vacío**, de la
primera celda a la última. Los que corren se ejecutan **una segunda vez** y se comparan las
salidas.

| Cuaderno | Corre | Estable | Qué pasó |
|---|---|---|---|
| `limpio.ipynb` | ✅ | ✅ | — |
| `azar-sin-semilla.ipynb` | ✅ | ❌ | salidas distintas entre corridas |
| `estado-oculto.ipynb` | ❌ | — | `NameError` (contadores 1, 3, 2) |
| `celda-borrada.ipynb` | ❌ | — | `NameError`: la celda que la definía ya no está |
| `ruta-absoluta.ipynb` | ❌ | — | `FileNotFoundError` |
| `dependencia-no-declarada.ipynb` | ❌ | — | `ModuleNotFoundError` |

⚖️ **2 de 6 corren; 1 de 6 es estable**, y ese uno es el cuaderno de control escrito correcto a
propósito. La auditoría completa —ocho ejecuciones— tarda **siete segundos**. Esa desproporción
—siete segundos contra meses de cuadernos que nadie sabe si sirven— es el resultado. **Solo uno
de los cinco defectos es propio del formato** (el estado oculto, que marimo elimina por diseño);
la ruta absoluta y la dependencia no declarada rompen un `.py` exactamente igual.

📝 **No es una estadística del mundo:** son seis cuadernos generados con defectos puestos a
propósito. Lo que demuestra es que cada defecto se detecta y lo barato que es detectarlo. El
número sobre un repositorio real es el ejercicio 22 y está pendiente.

→ [`ds06-notebooks-y-reproducibilidad.md`](ds06-notebooks-y-reproducibilidad.md) §6

### ds07 · La regla de ocho líneas contra la regresión logística

**Afirmaba:** que la logística de cinco variables le gana a la regla de tres, que la fuga infla
el AUC de forma visible, y que el costo de mantener el modelo es despreciable para el uso que
Áurea le da.

**Condiciones:** scikit-learn 1.9.1. Histórico de ausentismo con semilla 20260913: **105.620
citas de 12.400 pacientes**. Corte temporal en **2025-10-01**, tomado del manifiesto del
conjunto: 72.396 citas de entrenamiento y 33.224 de prueba, con 19,9% de inasistencia en el
tramo de prueba. Umbral por **capacidad del 20%**, que es la media mañana de Yuli, no el que
maximiza una métrica.

| Candidato | AUC | Marcadas | Precisión | Recall |
|---|---|---|---|---|
| siempre asiste | 0,500 | 33.224 (100%) | 0,199 | 1,000 |
| regla de 3 variables | 0,672 | 9.712 (29%) | 0,351 | 0,516 |
| **logística de 5** | **0,799** | **6.645 (20%)** | **0,526** | **0,530** |
| logística + FUGA | 0,862 | 6.645 (20%) | 0,588 | 0,592 |

⚖️ **El modelo gana, y donde importa:** a la misma capacidad, **0,526 de precisión contra
0,351** — de cada diez llamadas de Yuli aciertan cinco en vez de tres y media, **un 50% más por
el mismo tiempo de trabajo**. Y la regla trae un problema que el AUC no muestra: **no puede
operar a capacidad**, porque con cuatro puntajes distintos marca el 29% cuando le pides el 20%.

**La fuga regala 0,063 de AUC** —una columna de un `GROUP BY`, sin error ni advertencia— y lo
hace **con cualquier partición**, que es el hallazgo metodológico: la fuga es un problema de
columnas, no de partición.

| Partición | Variables honestas | Con la columna con fuga |
|---|---|---|
| temporal (la correcta) | 0,799 | 0,862 |
| al azar | 0,799 | 0,859 |
| por paciente | 0,798 | 0,856 |

⚖️ **Y el resultado que contradice al manual:** en este conjunto **partir al azar da exactamente
el mismo AUC que partir por fecha**. No hay inflación, y la razón se puede decir: el proceso que
genera los datos **no tiene deriva**. Eso no vuelve legítimo el atajo — lo que hace peligrosa a
la partición al azar es que **impide enterarse de si el conjunto tiene deriva**. Aquí no había
nada que esconder, y solo se sabe porque se partió por fecha.

**El costo de mantener:** entrenar 143,8 ms, predecir 33.224 filas 45,8 ms, artefacto **1,2 KB**,
y el arranque del intérprete pasa de 29 ms a **857 ms** al importar sklearn. La regla corre en
7,5 ms sin dependencia ninguna.

→ [`ds07-scikit-learn.md`](ds07-scikit-learn.md) §6

### ds08 · La red neuronal contra la línea base

**Afirmaba:** que la red le gana a la línea base de `ds07`, que la ventaja es pequeña, y que
**una columna de ingeniería de variables la iguala**.

**Condiciones:** PyTorch 2.14.0 en CPU y scikit-learn 1.9.1. Los mismos datos, corte y variables
de `ds07`: 72.396 citas de entrenamiento y 33.224 de prueba. Red de dos capas ocultas (16 y 8),
Adam, lotes de 512, semilla 20260913, parada temprana con paciencia 8 sobre el último 20% del
entrenamiento. Intervalos bootstrap de 200 remuestreos.

| Candidato | AUC | Brier | ECE | Precisión @20% |
|---|---|---|---|---|
| regla de 3 | 0,6723 | 0,1952 | **0,1918** | 0,351 |
| logística de 5 | 0,7993 | 0,1204 | 0,0127 | 0,526 |
| **logística + interacción** | **0,8118** | **0,1114** | **0,0106** | 0,547 |
| red neuronal | 0,8118 | 0,1116 | 0,0107 | 0,548 |

| Diferencia de AUC | Media | IC 95% |
|---|---|---|
| red − logística de 5 | +0,0125 | [+0,0109, +0,0141] |
| interacción − logística de 5 | +0,0126 | [+0,0107, +0,0142] |

⚖️ **La red gana, y gana exactamente lo que vale una columna.** La tesis que la historia de Áurea
daba por probable —*la red probablemente pierde*— **no se cumplió**: el intervalo de su ventaja
no toca el cero. Pero la misma logística con `lluvia × distancia` escrita a mano llega al mismo
0,8118 con un intervalo indistinguible. El proceso que genera estos datos tiene **una sola
interacción**; la red la encuentra y escribirla cuesta una línea. **La decisión deja de ser de
rendimiento y pasa a ser de mantenimiento:** 144 ms y 1,2 KB con seis coeficientes legibles,
contra PyTorch instalado, 4,0 KB y cinco decisiones de entrenamiento que alguien retoma cada vez
que los datos cambien.

**Y el hallazgo que más plata mueve, que no es sobre modelos sino sobre calibración.** Llevando
cada puntaje a la decisión de sobreagendar —con una colisión tres veces peor que una silla
vacía, umbral p > 0,75— sobre las 6.602 consultas que se pierden en el tramo de prueba:

| | Cupos sobreagendados | Consultas netas contra no hacer nada |
|---|---|---|
| regla de 3 (ECE 0,19) | 6.187 | **−6.336** |
| logística de 5 | 1.247 | +1.664 |
| logística + interacción | 1.878 | +3.006 |
| red neuronal | 1.994 | **+3.023** |

⚖️ **Un puntaje que ordena bien puede decidir catastróficamente.** La regla ordena
razonablemente —0,672 de AUC— y pierde más de lo que había para ganar, porque su 0,8 no
significa 80%. La diferencia entre 0,672 y 0,799 parecía moderada; en la decisión es la
diferencia entre ganar y destruir.

📝 **Falta el competidor que importaba:** un gradiente potenciado sobre las mismas cinco
variables, que para datos tabulares de este tamaño suele ganarles a todos. Dejarlo fuera le dio
a la red una comparación cómoda, y se declara.

→ [`ds08-ausentismo.md`](ds08-ausentismo.md) §6

### ds09 · El endpoint, con `pickle` y con ONNX

**Afirmaba:** que servir el modelo en ONNX arranca más rápido y responde igual o mejor, y que
**la diferencia de latencia es irrelevante** al lado de las dos razones de verdad: el arranque y
lo que hay que tener instalado.

**Condiciones:** FastAPI 0.141.1, uvicorn 0.52.4, scikit-learn 1.9.1, onnxruntime 1.30.0,
skl2onnx 1.20.0. El modelo ganador de `ds08`. **Medición sobre HTTP contra un uvicorn real** con
cliente de `urllib`, 500 peticiones por backend y 50 de calentamiento descartadas. Los dos
backends devuelven la misma probabilidad —diferencia 3,8 × 10⁻⁸—, verificado por prueba.

| Backend | Arranque en frío | p50 | p95 | Artefacto |
|---|---|---|---|---|
| `pickle` + scikit-learn | 1,10 s | 0,90 ms | 1,22 ms | 1,2 KB |
| **ONNX** + onnxruntime | **0,38 s** | **0,71 ms** | **0,99 ms** | **0,5 KB** |

⚖️ **ONNX gana, y no por la latencia.** La diferencia de p95 es de **0,23 ms**: real e
irrelevante al lado de cualquier red, y quien defienda ONNX con ese número pierde la discusión
con razón. Las tres razones que valen: **arranca 2,9× más rápido** —lo que espera un contenedor
que acaba de escalar—, **la imagen no necesita scikit-learn**, y **el artefacto no puede
ejecutar código**, que no es una optimización sino un cambio de categoría de riesgo.

**El umbral:** sirve `pickle` mientras el proceso que escribe el archivo y el que lo carga sean
tuyos y nadie pueda interponerse. En cuanto el modelo cruce una frontera organizativa, viaje por
un bucket o lo produzca alguien que no seas tú, la respuesta es un formato que solo describa
números.

📝 **La primera corrida de todas dio 32 segundos** de arranque para el backend de `pickle`,
porque el sistema de archivos no tenía nada de scikit-learn en caché. La tabla publica la cifra
estable; la nota existe porque en un contenedor recién creado la primera es la que vives. Y no
se midió con carga concurrente: 500 peticiones secuenciales contestan *"¿cuánto tarda una?"*, no
*"¿cuántas aguanta?"*.

→ [`ds09-servir-el-modelo.md`](ds09-servir-el-modelo.md) §6

---

## ✍️ Cómo se agregan entradas

Cuando escribas una medición nueva —tuya, o de un track opcional— sigue la forma de este
documento: **fase de origen, hipótesis en una línea, condiciones resumidas, resultado, y veredicto
con su umbral**, más el enlace a la sección 📏 donde está el detalle.

Y las reglas de honestidad de las mediciones del curso, que aquí valen igual:

- Se publica lo que salió, no lo que esperabas.
- **El empate se llama empate** — hay cinco en este documento y son de lo más valioso que tiene.
- Nada de números redondos sin dispersión.
- El competidor se configura bien. **Incluido el tuyo**, que es el error de la Fase 17.
- Se declara lo que no se midió.
- Y nunca se extrapola: un número de un portátil no predice una máquina virtual de dos núcleos.
