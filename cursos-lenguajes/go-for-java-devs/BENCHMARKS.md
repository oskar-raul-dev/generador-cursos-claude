# 📐 BENCHMARKS

> El banco de pruebas de la plataforma Meridian
> Go para desarrolladores Java senior

**Regla del curso: ninguna afirmación de rendimiento se escribe sin su entrada
aquí.** Vale también para las que parecen obvias —"Go arranca más rápido", "una
goroutine pesa menos que un hilo"—, porque *cuánto* más rápido y *cuánto* menos es
justo lo que el lector necesita para decidir.

El formato de cada entrada está en `prompts/formato-de-benchmarks.md`.

---

## ⚠️ Cómo se usa este documento

Cada entrada trae **hipótesis falsable, condiciones, comandos exactos, veredicto
provisional y la sección "qué NO demuestra"**. La tabla de resultados está
**preparada para que la completes en tu máquina**, y eso no es un atajo: es la
única forma honesta de usarla.

Un número de rendimiento sin la máquina que lo produjo no es reproducible, y
copiar el de otra persona es exactamente lo que las reglas de honestidad del
formato prohíben. **Corre el comando, anota tus números, y si contradicen el
veredicto provisional, corrige el veredicto** — eso es un resultado, no un fallo.

### La máquina de referencia

Rellena esto una vez y cítalo desde cada entrada:

```text
REF-1
  máquina:   macOS <versión> · Apple Silicon <modelo>
  cpu:       <marca>, <N> núcleos
  ram:       <N> GB
  go:        go1.25.x darwin/arm64
  go1.13:    go1.13 darwin/amd64 (bajo Rosetta 2)
  jdk:       <versión>
  graalvm:   <versión>
  postgres:  16-alpine en Docker, cpus=4 memory=2g
  mongo:     7 en Docker
  valkey:    8-alpine en Docker
  aislamiento: navegador cerrado, sin otros procesos, alimentación conectada
  generador de carga: [ ] misma máquina  [ ] máquina separada
```

> ⚠️ Si el generador de carga corre en la misma máquina que el servicio, **todas
> las mediciones de latencia bajo carga alta están contaminadas** y hay que
> decirlo en cada entrada afectada (B-17, B-23, B-24).

### Las reglas de honestidad, resumidas

1. Se prueban **todos** los competidores que el curso nombra, no solo el que
   queremos que gane.
2. **La JVM se mide ajustada y calentada.** Comparar contra una JVM sin configurar
   es hacer trampa y se nota.
3. El calentamiento se declara y se verifica.
4. **Mínimo diez corridas** y `benchstat` para los microbenchmarks.
5. **Se publica el resultado incómodo.** *"Lo medimos, no cambió, lo revertimos"*
   es de las lecciones más útiles del curso.
6. Se declara el hardware.
7. Números absolutos **y** relativos.
8. **Nada de extrapolar.**

---

## B-01 — Compilación cruzada: mismo binario, cinco plataformas

**Fase:** 00 · **Proyecto:** `labs/crossbuild` · **Fecha:** _____

### Hipótesis
Compilar el mismo paquete para cinco plataformas con `CGO_ENABLED=0` tarda menos de
30 s en total desde caché caliente, y ningún binario supera los 5 MB con
`-ldflags "-s -w"`.

### Condiciones
REF-1 · caché de build caliente (una compilación previa) · sin dependencias
externas.

### Cómo reproducirlo
```bash
cd labs/crossbuild
go build ./... && time ./build-all.sh && ls -lh bin/
```

### Resultados

| Plataforma | Tiempo | Tamaño (`-s -w`) | Tamaño sin `-s -w` |
|---|---|---|---|
| darwin/arm64 | | | |
| darwin/amd64 | | | |
| linux/amd64 | | | |
| linux/arm64 | | | |
| windows/amd64 | | | |
| **total** | | | |

### Veredicto
La compilación cruzada no requiere toolchain adicional ni contenedor, y el coste
por plataforma es marginal. **Es el argumento más corto a favor de Go que existe**
para herramientas de línea de comandos y agentes desplegados en hardware
heterogéneo — el caso de `storeagent` en 140 tiendas.

### Qué NO demuestra
No dice nada del rendimiento del binario resultante. No cubre cgo —con él, la
compilación cruzada necesita un compilador de C cruzado y deja de ser trivial—. Los
tiempos son con caché caliente; desde limpio son bastante mayores.

---

## B-02 — `strings.Builder` frente a `+=` y `fmt.Sprintf`

**Fase:** 01 · **Proyecto:** `labs/text-toolkit` · **Fecha:** _____

### Hipótesis
Con 10.000 elementos, `strings.Builder` con `Grow` reduce las asignaciones en más
de dos órdenes de magnitud frente a `+=`, y `fmt.Sprintf` en bucle es más lento que
`+=`.

### Condiciones
REF-1 · `go1.13` · 10.000 referencias externas de ~18 caracteres.

### Cómo reproducirlo
```bash
go1.13 test -run '^$' -bench . -benchmem -count=10 ./labs/text-toolkit > b02.txt
benchstat b02.txt
```

### Resultados

| Variante | ns/op | B/op | allocs/op |
|---|---|---|---|
| `JoinNaive` (`+=`) | | | |
| `JoinSprintf` | | | |
| `JoinBuilder` | | | |
| `JoinBuilderGrow` | | | |
| `JoinStdlib` (`strings.Join`) | | | |

### Veredicto
**Mira `allocs/op`, no `ns/op`:** ahí está el mecanismo. `+=` asigna una vez por
iteración; `Grow` asigna una vez en total. Usa `strings.Join` cuando tengas el
slice; `Builder` con `Grow` cuando construyas incrementalmente.

**Y el número que el curso no tiene:** el tamaño por debajo del cual da igual. Sale
del ejercicio 18 de la Fase 15.

### Qué NO demuestra
Un solo tamaño de entrada y de elemento. No cubre concatenación de dos o tres
cadenas, donde `+` es perfectamente correcto y más legible.

---

## B-03 — `regexp` compilado fuera del bucle frente a dentro

**Fase:** 01 · **Proyecto:** `labs/log-grep` · **Fecha:** _____

### Hipótesis
Compilar la expresión dentro del bucle multiplica el tiempo por más de 50 con
100.000 líneas.

### Condiciones
REF-1 · `go1.13` · 100.000 líneas de log · patrón con cuatro grupos con nombre.

### Cómo reproducirlo
```bash
go1.13 test -run '^$' -bench BenchmarkRegexp -benchmem -count=10 ./labs/log-grep
```

### Resultados

| Variante | ns/op | B/op | allocs/op |
|---|---|---|---|
| `MustCompile` en `var` de paquete | | | |
| `MustCompile` dentro del bucle | | | |

### Veredicto
Compilar una expresión regular construye un autómata: es trabajo real. **La
compilación va siempre fuera del bucle**, en una `var` de paquete con
`MustCompile`. 📖 Es el mismo error que `Pattern.compile` dentro del bucle en Java.

### Qué NO demuestra
El motor de Go es RE2 (tiempo lineal garantizado, sin *backtracking*). Los números
no se trasladan a PCRE, y el intercambio es distinto: RE2 no tiene backreferences
ni lookahead, y a cambio es inmune a ReDoS.

---

## B-04 — Slice pre-dimensionado frente a `append` desde cero

**Fase:** 01 · **Proyecto:** `labs/text-toolkit` · **Fecha:** _____

### Hipótesis
Con 100.000 elementos, `make([]T, 0, n)` reduce las asignaciones a una frente a las
~17 de `append` con crecimiento amortizado, y el tiempo en más de un 40%.

### Condiciones
REF-1 · `go1.13` · struct `WorkItem` de ~200 bytes.

### Cómo reproducirlo
```bash
go1.13 test -run '^$' -bench BenchmarkPresize -benchmem -count=10 ./labs/text-toolkit
```

### Resultados

| Variante | ns/op | B/op | allocs/op |
|---|---|---|---|
| `var items []T` + `append` | | | |
| `make([]T, 0, n)` + `append` | | | |
| `make([]T, n)` + índice | | | |

### Veredicto
Pre-dimensionar cuando el tamaño se conoce. El crecimiento de `append` duplica la
capacidad, así que durante la copia **coexisten el slice viejo y el nuevo**: el pico
de memoria es mayor que el resultado.

### Qué NO demuestra
**No ayuda cuando el tamaño es desconocido o muy variable**, y pre-dimensionar de
más desperdicia memoria. Con slices pequeños (menos de ~100 elementos) la
diferencia es despreciable.

---

## B-05 — Coste de una llamada a través de interfaz

**Fase:** 02 · **Proyecto:** `labs/shapes` · **Fecha:** _____

### Hipótesis
La llamada por interfaz cuesta menos de 5 ns más que la directa, y **la diferencia
real está en el *inlining* perdido y en las asignaciones**, no en el salto
indirecto.

### Condiciones
REF-1 · `go1.13` · método trivial (`Area()` de un rectángulo).

### Cómo reproducirlo
```bash
go1.13 test -run '^$' -bench . -benchmem -count=10 ./labs/shapes
go1.13 build -gcflags='-m' ./labs/shapes 2>&1 | grep -E 'inline|escape'
```

### Resultados

| Variante | ns/op | B/op | allocs/op | ¿*inlined*? |
|---|---|---|---|---|
| Llamada directa | | | | |
| Llamada por interfaz | | | | |
| Slice de interfaces | | | | |

### Veredicto
**Evitar interfaces por rendimiento es optimización prematura en el 99,9% de los
casos.** El coste no está en el salto: está en que la llamada por interfaz impide
el *inlining*, y en que meter un valor en una interfaz puede hacerlo escapar al
montículo — mira `allocs/op` del tercer caso.

### Qué NO demuestra
Un método trivial maximiza el efecto relativo del *inlining* perdido. Con métodos
que hacen trabajo de verdad, la diferencia relativa desaparece. No cubre el coste de
las aserciones de tipo ni de los *type switch*.

---

## B-06 — Decodificación JSON completa frente a streaming

**Fase:** 03 · **Proyecto:** `labs/json-codec` · **Fecha:** _____

### Hipótesis
El decodificador en streaming mantiene la memoria máxima por debajo del 5% de la
del documento, con un coste en tiempo inferior al 20%.

### Condiciones
REF-1 · `go1.13` · documento de 50.000 work items (~12 MB).

### Cómo reproducirlo
```bash
go1.13 test -run '^$' -bench . -benchmem -count=10 ./labs/json-codec
```

### Resultados

| Variante | ns/op | B/op | allocs/op | RSS máx. |
|---|---|---|---|---|
| `json.Unmarshal` completo | | | | |
| `json.Decoder` en streaming | | | | |

### Veredicto
**Mira `B/op`, no `ns/op`.** El tiempo puede ser parecido; la memoria no lo es. Para
un documento que crece con los datos, el streaming es la única opción que no tiene
una bomba de tiempo dentro.

### Qué NO demuestra
Para documentos pequeños, la sobrecarga del `Decoder` puede hacerlo más lento sin
ninguna ventaja. El umbral está en tu caso de uso.

---

## B-07 — Goroutine frente a hilo de la JVM

**Fase:** 06 · **Proyecto:** `labs/race-counter` · **Fecha:** _____

### Hipótesis
Crear 100.000 goroutines consume menos de 500 MB de RSS y menos de 200 ms; crear
100.000 hilos de plataforma de la JVM **no es posible** en la máquina de
referencia. **Con hebras virtuales de Java 21, la diferencia se reduce a menos de
un orden de magnitud.**

### Condiciones
REF-1 · trabajo por unidad: dormir 10 ms · **cuatro variantes obligatorias**.

### Cómo reproducirlo
```bash
go test -run '^$' -bench BenchmarkSpawn -benchmem -count=10 ./labs/race-counter
/usr/bin/time -v ./bin/spawn-test 100000

cd reference/concurrency-comparison
./mvnw -q exec:java -Dexec.mainClass=PlatformThreads -Dexec.args=100000
./mvnw -q exec:java -Dexec.mainClass=VirtualThreads  -Dexec.args=100000
```

### Resultados

| Variante | Creación (100k) | RSS | Bytes/unidad | Límite práctico |
|---|---|---|---|---|
| Goroutines | | | | |
| Hilos de plataforma (`-Xss` por defecto) | | | | |
| Hilos de plataforma (`-Xss512k`) | | | | |
| **Hebras virtuales (Java 21)** | | | | |

### Veredicto
⚠️ **Esta es la entrada donde la regla 1 de honestidad más importa.** Medir solo
contra hilos de plataforma produce un titular espectacular y **engañoso desde Java
21**: las hebras virtuales son el paralelo más cercano a una goroutine que existe
fuera de Go.

Lo que queda a favor de Go tras Java 21 **no es el coste**: son canales y `select`
como primitivas del lenguaje, el detector de carreras en el toolchain, y quince
años de modelo M:N en producción. Eso es preferencia de diseño informada, no una
tabla de números.

### Qué NO demuestra
No mide el rendimiento del planificador bajo carga real, ni el comportamiento con
E/S bloqueante, ni el *pinning* de las hebras virtuales dentro de `synchronized`,
que es su limitación conocida.

---

## B-08 — Canal con búfer frente a mutex para un contador

**Fase:** 06 · **Proyecto:** `labs/race-counter` · **Fecha:** _____

### Hipótesis
Para un contador, `atomic` gana, el mutex va detrás, y el canal es entre uno y dos
órdenes de magnitud más lento.

### Condiciones
REF-1 · `b.RunParallel` · `-cpu=1,4,8`.

### Cómo reproducirlo
```bash
go test -run '^$' -bench BenchmarkCounter -benchmem -cpu=1,4,8 -count=10 ./labs/race-counter
```

### Resultados

| Variante | cpu=1 | cpu=4 | cpu=8 | allocs/op |
|---|---|---|---|---|
| `atomic` | | | | |
| `sync.Mutex` | | | | |
| Canal con búfer | | | | |

### Veredicto
**Esto NO significa que los canales sean lentos.** Significa que un canal es una
herramienta de **transferencia de propiedad y sincronización**, no un sustituto de
un lock. Usar la herramienta equivocada cuesta caro en cualquier lenguaje.

> *"Usa canales para pasar la propiedad de datos; usa mutex para proteger estado
> compartido."*

### Qué NO demuestra
Un contador es el peor caso posible para un canal. No dice nada sobre pipelines,
fan-out/fan-in ni coordinación, donde el canal es la herramienta correcta.

---

## B-09 — Worker pool acotado frente a goroutine por tarea, bajo pico

**Fase:** 06 · **Proyecto:** `labs/unbounded-queue` · **Fecha:** _____

### Hipótesis
Con un pico de 50.000 tareas en 2 s, la versión sin límite supera los 20 GB de
reserva o muere; la acotada mantiene la memoria estable y **rechaza** la mayoría.

### Condiciones
REF-1 · cada tarea reserva 1 MB y tarda 100 ms · pool: cola 1.000, 8 workers.

### Cómo reproducirlo
```bash
go test -tags=stress -run TestSpikeComparison -v ./labs/unbounded-queue
```

### Resultados

| Variante | RSS máx. | Completadas | **Rechazadas** | p99 de las aceptadas |
|---|---|---|---|---|
| Sin límite | | | — | |
| Acotada (1000/8) | | | | |

### Veredicto
⚠️ **"Rechazadas" no es una derrota: es el mecanismo funcionando.** Rechazar el 98%
de un pico y servir el 2% correctamente es un servicio degradado; aceptar el 100% y
morir es una caída total que además se lleva el trabajo en curso.

### Qué NO demuestra
Un pico sintético con tareas homogéneas. No modela la recuperación tras el pico ni
el comportamiento del cliente ante el rechazo.

---

## B-10 — Cuánto cuesta `-race`

**Fase:** 06 · **Proyecto:** las suites de las Fases 04 y 06 · **Fecha:** _____

### Hipótesis
El sobrecoste de `-race` está entre 2× y 20× en tiempo, **y depende de cuánta
memoria compartida se toque**: la suite de la Fase 06 tiene un ratio notablemente
mayor que la de la Fase 04.

### Condiciones
REF-1 · dos sujetos: suite unitaria de la Fase 04 y suite concurrente de la Fase 06.

### Cómo reproducirlo
```bash
time go test -count=1 ./internal/workitem ./internal/opsreport
time go test -race -count=1 ./internal/workitem ./internal/opsreport
time go test -count=1 ./internal/engine ./internal/dispatcher
time go test -race -count=1 ./internal/engine ./internal/dispatcher
```

### Resultados

| Suite | Sin `-race` | Con `-race` | Ratio | RSS sin | RSS con |
|---|---|---|---|---|---|
| Fase 04 (unitaria) | | | | | |
| Fase 06 (concurrente) | | | | | |

### Veredicto
**La diferencia entre los dos ratios es el resultado interesante**, más que el ratio
absoluto. `-race` instrumenta cada acceso a memoria: cuanta más memoria compartida,
más caro. Se corre siempre en CI y en desarrollo; **nunca en producción**.

### Qué NO demuestra
No mide el sobrecoste en un servicio bajo carga real, que es distinto al de una
suite de tests.

---

## B-11 — El mismo servicio en 1.13 y en Go moderno

**Fase:** 08 · **Proyecto:** OpsReport · **Fecha:** _____

### Hipótesis
⚠️ **Deliberadamente incómoda.** *"El binario de Go moderno será **más grande** que
el de 1.13, y el arranque y la memoria en reposo serán **similares**."*

### Condiciones
REF-1 · mismo código salvo los cambios de la Fase 08 · `-ldflags "-s -w"`,
`CGO_ENABLED=0`, `-trimpath` · caché de build limpia para el tiempo de compilación.

### Cómo reproducirlo
```bash
git checkout bloque-a-completo && go1.13 build -trimpath -ldflags "-s -w" -o bin/ops-113 ./cmd/opsreport
git checkout fase-08          && go     build -trimpath -ldflags "-s -w" -o bin/ops-125 ./cmd/opsreport
ls -lh bin/ops-*
scripts/bench/cold-start.sh ./bin/ops-113
scripts/bench/cold-start.sh ./bin/ops-125
go clean -cache && time go build ./cmd/opsreport
```

### Resultados

| | Go 1.13 | Go 1.25 | Δ |
|---|---|---|---|
| Binario (`-s -w`) | | | |
| Arranque hasta la 1ª petición | | | |
| RSS en reposo | | | |
| RSS bajo carga (300 rps) | | | |
| Compilación desde limpio | | | |
| Líneas de código (`--stat`) | | | |

### Veredicto
**Si tu medición dice que todo mejoró, desconfía y revisa las condiciones.** Trece
versiones de stdlib añadida pesan.

**Lo que se ganó con la migración no son milisegundos:** sesenta líneas de
enrutador que ya no mantienes, un logger consultable, un binario autosuficiente
(`embed`), un parser al que el fuzzer le encontró un bug, y una plantilla de
decodificación en vez de cinco copias. **Es mantenimiento, y ahí se va el dinero.**

Si alguien te pide justificar una migración de versión con un gráfico de latencia,
la respuesta honesta es que ese no es el argumento.

### Qué NO demuestra
Un solo servicio, sin persistencia real en el momento de la migración. No mide el
efecto de las mejoras del recolector entre 1.13 y 1.25 bajo carga sostenida, que es
donde sí hay diferencia medible.

---

## B-12 — `ServeMux` moderno frente al enrutado a mano

**Fase:** 08 · **Proyecto:** `labs/tiny-router` · **Fecha:** _____

### Hipótesis
Con 5 rutas, las tres variantes son **indistinguibles**. Con 200, la búsqueda
lineal se degrada linealmente y el árbol y el `ServeMux` se mantienen.

### Condiciones
REF-1 · tres variantes × tres tamaños (5, 50, 200 rutas) · petición que casa con la
última ruta registrada (peor caso de la lineal).

### Cómo reproducirlo
```bash
go test -run '^$' -bench BenchmarkRouter -benchmem -count=10 ./labs/tiny-router
```

### Resultados

| Variante | 5 rutas | 50 rutas | 200 rutas | allocs/op |
|---|---|---|---|---|
| `tiny-router` lineal | | | | |
| Árbol de prefijos (F05 ej23) | | | | |
| `http.ServeMux` (1.22) | | | | |

### Veredicto
**El rendimiento NO es la razón para adoptar el `ServeMux` moderno, y hay que
decirlo antes que nada.** Las razones son: sesenta líneas menos que mantener, y —la
importante— **la firma del handler vuelve a ser `http.HandlerFunc` estándar**, así
que cualquier middleware del ecosistema funciona.

Ese es el precio oculto de las abstracciones propias que alteran una interfaz
estándar, y es una lección que se transfiere a cualquier lenguaje.

### Qué NO demuestra
El enrutado rara vez es el cuello de botella de un servicio real: en el perfil de
la Fase 15, la serialización y la base de datos dominan por varios órdenes de
magnitud.

---

## B-13 — `database/sql` frente a `pgx` nativo

**Fase:** 09 · **Proyecto:** OpsReport · **Fecha:** _____

### Hipótesis
`pgx` nativo reduce la latencia de la consulta de listado entre un 10% y un 25%
gracias al protocolo binario; **`CopyFrom` es más de un orden de magnitud más
rápido que `INSERT` por fila** para carga masiva.

### Condiciones
REF-1 · PostgreSQL 16 en Docker, local · tabla `work_items` con 100.000 filas ·
consulta de listado con índice.

### Cómo reproducirlo
```bash
go test -tags=integration -run '^$' -bench BenchmarkDriver -benchmem -count=10 ./internal/postgres
```

### Resultados

| Variante | 10 filas | 100 filas | 1.000 filas | allocs/op |
|---|---|---|---|---|
| `database/sql` + driver pgx | | | | |
| `pgx` nativo (`pgxpool`) | | | | |

| Inserción de 100.000 filas | Tiempo | allocs |
|---|---|---|
| `INSERT` por fila | | |
| `INSERT` por lotes de 1.000 | | |
| `pgx.CopyFrom` | | |

### Veredicto
**Condicional, no un ganador.** Usa `database/sql` con el driver de pgx por
defecto: la portabilidad, los tests de contrato compartidos y el ecosistema valen
más que la diferencia en la mayoría de las rutas. Usa `pgx` nativo donde el tipo de
dato o el volumen lo justifiquen — `CopyFrom` en la ingesta de movimientos de
ClearingHouse es el caso claro.

**Esa asimetría en Meridian es la decisión, y la justifica esta medición.**

### Qué NO demuestra
Todo en local, sin latencia de red. **Con la base de datos a 1 ms de distancia, la
diferencia entre los dos drivers se diluye**, porque la red domina. No cubre tipos
nativos (arrays, `JSONB`), donde `pgx` gana más.

---

## B-14 — SQL a mano frente a `sqlc` frente a GORM

**Fase:** 09 · **Proyecto:** OpsReport · **Fecha:** _____

### Hipótesis
SQL a mano y `sqlc` son indistinguibles —`sqlc` genera el mismo código que
escribirías—. GORM añade sobrecarga por reflexión, **más visible en `allocs/op` que
en `ns/op`**.

### Condiciones
REF-1 · la **misma** consulta de listado con filtro y paginación · 1.000 filas.

### Cómo reproducirlo
```bash
sqlc generate
go test -tags=integration -run '^$' -bench BenchmarkORM -benchmem -count=10 ./internal/postgres
```

### Resultados

| Variante | ns/op | B/op | allocs/op | Líneas a mano | ¿Paso en el build? |
|---|---|---|---|---|---|
| SQL a mano | | | | ~25 | no |
| `sqlc` | | | | ~6 (el SQL) | **sí** |
| GORM | | | | ~5 | no |

### Veredicto
⚠️ **El argumento de esta sección NO es el rendimiento, y el veredicto tiene que
decirlo.** Lo que decide:

- **SQL a mano** para consultas pocas y no triviales (`SKIP LOCKED`, índices
  parciales, paginación por tupla), donde escribir el SQL **es** el trabajo. Es lo
  que Meridian usa.
- **`sqlc` es la recomendación por defecto para un proyecto nuevo con mucho CRUD**,
  aunque el curso no lo use: escribes SQL de verdad y el generador lo **valida
  contra el esquema en tiempo de compilación**, que es más de lo que JPA hace.
- **GORM** se descarta como opción por defecto, y no por ser malo: reproduce el
  modelo mental de JPA —*lazy loading*, asociaciones implícitas, convenciones
  mágicas— sin sus veinte años de madurez, y empuja a quien viene de Java hacia los
  errores que en Java ya sabe evitar.

### Qué NO demuestra
Una sola consulta, de una sola forma. GORM brilla en CRUD estándar masivo, que es
justo lo que esta medición no cubre. No mide el tiempo de desarrollo, que es el eje
que de verdad decide.

---

## B-15 — Paginación por cursor frente a `OFFSET`

**Fase:** 09 · **Proyecto:** OpsReport · **Fecha:** _____

### Hipótesis
La latencia del cursor se mantiene constante; la de `OFFSET` crece linealmente con
el desplazamiento. En la página 2.000 (offset 100.000), la diferencia supera 50×.

### Condiciones
REF-1 · 200.000 filas · índice `(created_at DESC, id DESC)` · páginas de 50.

### Cómo reproducirlo
```bash
go test -tags=integration -run '^$' -bench BenchmarkPagination -count=10 ./internal/postgres
docker compose exec postgres psql -U meridian -d meridian -c \
  "EXPLAIN (ANALYZE, BUFFERS) SELECT * FROM work_items ORDER BY created_at DESC LIMIT 50 OFFSET 100000;"
```

### Resultados

| Página | `OFFSET` (ms) | Cursor (ms) | Filas examinadas (OFFSET) | Filas examinadas (cursor) |
|---|---|---|---|---|
| 1 | | | | |
| 100 | | | | |
| 1.000 | | | | |
| 2.000 | | | | |

### Veredicto
Para listados profundos y para recorrer conjuntos grandes, cursor. **Y la
comparación de tuplas `(created_at, id) < ($1, $2)` es la clave**: PostgreSQL la
aprovecha con el índice compuesto mejor que la condición equivalente escrita a mano.

### Qué NO demuestra
⚠️ **Y aquí está lo que se pierde, que es real:** con cursor **no se puede saltar a
la página 47**, y no hay número total de páginas sin un `COUNT(*)` aparte. **Si tu
interfaz tiene paginación numerada, `OFFSET` es la respuesta correcta.**

---

## B-16 — SQLite con WAL y sin WAL

**Fase:** 09 · **Proyecto:** `storeagent` · **Fecha:** _____

### Hipótesis
WAL mejora las escrituras concurrentes con lectores en más de 5×. Con
`MaxOpenConns > 1` y sin `busy_timeout`, aparecen `SQLITE_BUSY`.

### Condiciones
REF-1 · `modernc.org/sqlite` · 100.000 inserciones de `Movement` · SSD local.

### Cómo reproducirlo
```bash
go test -tags=integration -run '^$' -bench BenchmarkSQLite -count=10 ./internal/sqlite
```

### Resultados

| Configuración | Inserciones/s | `SQLITE_BUSY` | Tamaño del archivo |
|---|---|---|---|
| journal=delete, `MaxOpenConns=1` | | | |
| **journal=wal, `MaxOpenConns=1`** | | | |
| journal=wal, `MaxOpenConns=8` | | | |
| journal=wal, `synchronous=FULL` | | | |
| journal=wal, `synchronous=NORMAL` | | | |

### Veredicto
Para el agente de tienda: **WAL + `synchronous=NORMAL` + `MaxOpenConns=1`**. SQLite
admite muchos lectores y **un solo escritor**; un pool de N conexiones escribiendo
produce `SQLITE_BUSY` constante.

Y `synchronous` es el intercambio durabilidad/rendimiento que el agente tiene que
decidir de verdad: con `NORMAL` y WAL, un corte de luz puede perder las últimas
transacciones; con `FULL`, no, y cuesta.

### Qué NO demuestra
SSD local. **SQLite sobre NFS o cualquier sistema de archivos en red es una
combinación conocida por corromper datos**, y esto no lo mide. No cubre el
comportamiento con la base en un disco lento o lleno.

---

## B-17 — AtlasSync: tasa de acierto y latencia con y sin caché

**Fase:** 12 · **Proyecto:** AtlasSync · **Fecha:** _____

### Hipótesis
⚠️ **Deliberadamente incómoda.** *"Frente a no cachear, las dos cachés reducen el
p99 de forma significativa. Frente al mapa en memoria, **Valkey NO mejora la
latencia —la empeora, porque añade un viaje de red—** y su ventaja está en otra
parte: se comparte entre instancias, sobrevive a los reinicios, y no multiplica la
memoria por el número de réplicas."*

### Condiciones
REF-1 · **tres variantes obligatorias** · 250 países · dos distribuciones de acceso
(uniforme y sesgada 80/20) · 500 rps durante 120 s con rampa · generador:
_____ (misma máquina / separada).

### Cómo reproducirlo
```bash
for backend in none memory valkey; do
  MERIDIAN_CACHE_BACKEND=$backend ./bin/atlassync &
  scripts/bench/warmup.sh http://localhost:8082
  vegeta attack -targets=targets.txt -rate=500 -duration=120s | vegeta report
  kill %1
done
```

### Resultados

| Variante | p50 | p95 | p99 | rps sostenido | Acierto | RSS/instancia |
|---|---|---|---|---|---|---|
| Sin caché | | | | | — | |
| Mapa en memoria + TTL | | | | | | |
| Valkey | | | | | | |

**Distribución temporal de fallos (efecto del jitter):**

| | Fallos en el segundo pico | Fallos/s de media |
|---|---|---|
| TTL sin jitter | | |
| TTL con jitter ±20% | | |

### Veredicto
**Si tu medición dice que Valkey es más rápido que un mapa en memoria, revisa el
experimento.** Un acceso a un mapa son nanosegundos; un viaje a Valkey, cientos de
microsegundos como mínimo. **La caché distribuida nunca gana a la local en latencia
pura**, y entender eso es el punto de la medición.

**Para AtlasSync tal como está —250 países de 2 KB, tres instancias— un mapa en
memoria con TTL resuelve el problema y Valkey no aporta lo suficiente para
justificar un servicio más en el `compose.yaml`.**

Lo que sí justifica Valkey en Meridian es **lo que no es caché**: el límite de tasa
por socio, que debe ser compartido por definición, y la idempotencia distribuida.
Esos dos casos no tienen alternativa local.

**Las cuatro condiciones que cambiarían el veredicto:** que el conjunto no quepa en
memoria, que las instancias sean muchas, que llenar la caché sea caro, o que la
coherencia entre instancias importe.

### Qué NO demuestra
Un conjunto de datos pequeño y acotado, que es justo lo que favorece a la caché
local. Con 250.000 entradas el veredicto cambia (ejercicio 21 de la Fase 15). Si el
generador corrió en la misma máquina, los p99 están contaminados.

---

## B-18 — Bytes precodificados frente a codificar por petición

**Fase:** 12 · **Proyecto:** AtlasSync · **Fecha:** _____

### Hipótesis
Servir bytes precodificados elimina más del 60% del tiempo de proceso por acierto
de caché frente a decodificar y recodificar.

### Condiciones
REF-1 · dos tamaños: un país (~2 KB) y un listado de región (~60 KB).

### Cómo reproducirlo
```bash
go test -run '^$' -bench BenchmarkCodec -benchmem -count=10 ./internal/cache
```

### Resultados

| Codec | 2 KB ns/op | 60 KB ns/op | B/op | allocs/op | Tamaño en Valkey |
|---|---|---|---|---|---|
| JSON (decodifica + recodifica) | | | | | |
| JSON precodificado (bytes) | | | | | |
| Comprimido (s2/gzip) | | | | | |

**Umbral donde comprimir compensa:** _____ bytes.

### Veredicto
Los bytes precodificados son la optimización más rentable de una caché de lectura y
casi nadie la hace: eliminan **dos** pasos de serialización por acierto.

**Y lo que se pierde:** la caché pasa a guardar **la representación de la API**, no
el dominio. Un cambio en el formato de salida obliga a invalidar todo — otra razón
para versionar las claves.

### Qué NO demuestra
No mide el coste de mantener las dos representaciones sincronizadas, que es donde
el intercambio se paga de verdad.

---

## B-19 — Reporte de 500.000 filas: streaming frente a carga completa

**Fase:** 13 · **Proyecto:** OpsReport · **Fecha:** _____

### Hipótesis
El streaming mantiene la memoria máxima por debajo de 60 MB frente a más de 1.500
MB de la carga completa, con un coste en tiempo total inferior al 15%.

### Condiciones
REF-1 · 500.000 filas · formato CSV · cursor declarado con `FETCH 1000`.

### Cómo reproducirlo
```bash
/usr/bin/time -v ./bin/opsreport report --id r-001 --format csv --buffered > /dev/null
/usr/bin/time -v ./bin/opsreport report --id r-001 --format csv --stream   > /dev/null
curl -s -o /dev/null -w 'primer byte: %{time_starttransfer}s total: %{time_total}s\n' \
  'localhost:8080/reports/r-001/download?format=csv'
```

### Resultados

| Variante | RSS máx. | Tiempo total | **Tiempo al primer byte** | Recolecciones |
|---|---|---|---|---|
| Carga completa | | | | |
| Streaming | | | | |

### Veredicto
El tiempo hasta el primer byte es donde el streaming gana de forma más visible para
el usuario. Y la memoria acotada es lo que separa un endpoint que funciona de uno
que tiene una bomba de tiempo.

### Qué NO demuestra
⚠️ **Lo que se pierde con el streaming:** no hay `Content-Length` ni barra de
progreso, y **un error a mitad de la respuesta ya no se puede convertir en un 500**
porque el 200 ya salió. Esa tensión se resuelve con el trailer HTTP (Fase 13 §6.6) y
no desaparece.

---

## B-20 — Tamaño de fragmento frente a tiempo total del cierre

**Fase:** 13 · **Proyecto:** ClearingHouse · **Fecha:** _____

### Hipótesis
El tiempo total mejora hasta unos 5.000 elementos por fragmento y se estabiliza; la
memoria y **la latencia de cancelación** crecen linealmente a partir de ahí.

### Condiciones
REF-1 · 1.000.000 de movimientos, semilla 42 · PostgreSQL local.

### Cómo reproducirlo
```bash
./bin/clearinghouse seed --movements 1000000 --seed 42
for size in 100 500 1000 5000 10000 50000; do
  ./bin/clearinghouse reset --day 2026-09-11
  /usr/bin/time -v ./bin/clearinghouse close --day 2026-09-11 --chunk-size $size
  # y la latencia de cancelación:
  ./bin/clearinghouse close --day 2026-09-11 --chunk-size $size & sleep 10; time kill -TERM %1; wait
done
```

### Resultados

| Fragmento | Tiempo total | RSS máx. | **Latencia de cancelación** | Trabajo perdido al matar |
|---|---|---|---|---|
| 100 | | | | |
| 500 | | | | |
| 1.000 | | | | |
| 5.000 | | | | |
| 10.000 | | | | |
| 50.000 | | | | |

### Veredicto
Recomendación **con su condición**: ~5.000 para el cierre nocturno, **y se baja si
la ventana de apagado es corta aunque cueste tiempo total**.

⚠️ **La latencia de cancelación es la columna que nadie mide y la que decide el
despliegue:** determina el `terminationGracePeriodSeconds` que tu plataforma
necesita, y es lo que valida la configuración de la Fase 14.

### Qué NO demuestra
Un solo volumen y un solo hardware. Con la base de datos remota, el óptimo se
desplaza hacia fragmentos mayores porque el coste por viaje sube.

---

## B-21 — Imagen de contenedor: Go distroless frente a Spring Boot

**Fase:** 14 · **Proyecto:** ClearingHouse · **Fecha:** _____

### Hipótesis
La imagen de Go sobre `distroless/static` pesa menos del 10% de la de Spring Boot
sobre `eclipse-temurin` completo. **La variante de `native-image` reduce la brecha a
menos de 3×.**

### Condiciones
REF-1 · **siete variantes** · el mismo servicio · sin capas de caché entre builds
para el tiempo.

### Cómo reproducirlo
```bash
for df in Dockerfile.golang Dockerfile.alpine Dockerfile.distroless Dockerfile.scratch; do
  time docker build --no-cache -t meridian/ch:$(basename $df .Dockerfile) -f $df .
done
cd reference/clearinghouse-spring
time docker build --no-cache -t meridian/ch-spring:jdk    -f Dockerfile.jdk .
time docker build --no-cache -t meridian/ch-spring:jre    -f Dockerfile.jre-alpine .
time docker build --no-cache -t meridian/ch-spring:native -f Dockerfile.native .
docker images | grep meridian/ch
```

### Resultados

| Variante | Tamaño | Base | Tiempo de build | CVE conocidos |
|---|---|---|---|---|
| Go: `golang:alpine` completa | | | | |
| Go: `alpine` mínima | | | | |
| Go: `distroless/static` | | | | |
| Go: `scratch` | | | | |
| Java: JDK completo | | | | |
| Java: JRE `alpine` | | | | |
| **Java: `native-image`** | | | | |

### Veredicto
⚠️ **Comparar el binario de Go contra el JAR es hacer trampa**, y hay que decirlo:
el JAR no trae la JVM. **La comparación honesta es imagen contra imagen.**

`distroless` es la elección del curso: sin shell, sin gestor de paquetes, usuario
sin privilegios, y trae los certificados raíz y `/etc/passwd` que `scratch` no tiene.
El precio es que no puedes entrar a depurar.

El tiempo de build de `native-image` —minutos frente a segundos— es un coste real en
un pipeline que corre cincuenta veces al día.

### Qué NO demuestra
El tamaño de la imagen importa para el tiempo de despliegue y la superficie de
ataque; **no dice nada del rendimiento en ejecución**, que es B-24.

---

## B-22 — `GOGC` y `GOMEMLIMIT`: efecto sobre pausas y memoria

**Fase:** 15 · **Proyecto:** OpsReport y ClearingHouse · **Fecha:** _____

### Hipótesis
Para la carga HTTP, `GOGC=200` reduce el tiempo de recolección por debajo del 3%
sin que la memoria crezca de forma problemática. Para el lote, el efecto es menor
porque las asignaciones son pocas y grandes.

### Condiciones
REF-1 · ⚠️ **dos cargas obligatorias**: OpsReport a 300 rps durante 120 s (muchos
objetos pequeños y efímeros) y el cierre de 1M (pocos objetos grandes).

### Cómo reproducirlo
```bash
for gogc in 50 100 200 400 off; do
  for limit in "" "GOMEMLIMIT=1GiB"; do
    env GOGC=$gogc $limit GODEBUG=gctrace=1 ./bin/opsreport 2> gc-$gogc-$limit.log &
    scripts/bench/warmup.sh http://localhost:8080
    vegeta attack -targets=targets.txt -rate=300 -duration=120s | vegeta report
    kill %1
    awk -F'[ %]' '/^gc /{print $4}' gc-$gogc-$limit.log | tail -1   # % CPU en GC
  done
done
```

### Resultados — carga HTTP

| `GOGC` | `GOMEMLIMIT` | % CPU en GC | RSS máx. | p99 | **Pausa máx.** |
|---|---|---|---|---|---|
| 50 | — | | | | |
| 100 | — | | | | |
| 200 | — | | | | |
| 400 | — | | | | |
| off | 1 GiB | | | | |

### Resultados — cierre por lotes

*(misma tabla)*

### Veredicto
**Por debajo del 5% de CPU en recolección no hay nada que ganar tocando `GOGC`**, y
ese es el caso mayoritario. **El veredicto tiene que decir cuándo no tocar nada.**

La combinación que recomienda el equipo de Go —`GOGC=off` con `GOMEMLIMIT`
ajustado— aprovecha todo el presupuesto de memoria del contenedor. ⚠️ **Y su riesgo:
si el límite se alcanza de verdad, el recolector entra en modo agresivo permanente
y el proceso se vuelve lentísimo** — el síntoma del 🧨 de la Fase 13, que es peor de
diagnosticar que un OOM limpio. `GOMEMLIMIT` se pone **por debajo** del límite del
contenedor, con margen para lo que no es heap (~90%).

### Qué NO demuestra
Dos cargas de un hardware. El comportamiento del recolector depende mucho del patrón
de asignación, y una tercera carga podría dar otro óptimo.

---

## B-23 — EventRelay: entregas por segundo contra `fakeconsumer`

**Fase:** 15 · **Proyecto:** EventRelay · **Fecha:** _____

### Hipótesis
Con `/ok`, EventRelay sostiene más de 2.000 entregas por segundo con p99 por debajo
de 50 ms. Con `/flaky` (30% de fallos), el rendimiento efectivo cae por debajo del
50% por los reintentos.

### Condiciones
REF-1 · ⚠️ **los tres comportamientos** de `fakeconsumer` · 100.000 entregas
encoladas · generador: _____ (misma máquina / separada).

### Cómo reproducirlo
```bash
./bin/fakeconsumer -addr :9100 -slow-delay 8s &
for endpoint in ok flaky slow; do
  ./bin/eventrelay seed --deliveries 100000 --endpoint "http://localhost:9100/$endpoint"
  /usr/bin/time -v ./bin/eventrelay run --drain
  curl -s localhost:9100/stats | jq
done
```

### Resultados

| Endpoint | Entregas/s | p50 | p95 | p99 | Tasa de reintento | CPU | RSS |
|---|---|---|---|---|---|---|---|
| `/ok` | | | | | — | | |
| `/flaky` (30%) | | | | | | | |
| `/slow` (8 s) | | | | | | | |

**Ritmo al que el p99 se dispara:** _____ entregas/s ← **la capacidad real**

**Efecto de `MaxIdleConnsPerHost`:**

| Valor | Conexiones nuevas/s | p99 |
|---|---|---|
| 2 (por defecto) | | |
| 100 | | |

### Veredicto
El número que decide el dimensionado no es el rendimiento máximo: es **el ritmo al
que el p99 se dispara**. Y el caso `/flaky` es el realista: un socio no está caído,
está inestable.

### Qué NO demuestra
Un consumidor local sin latencia de red ni variabilidad real. Con socios a decenas
de milisegundos, el modelo de concurrencia importa más y el número absoluto cambia.
Si el generador corrió en la misma máquina, los p99 están contaminados.

---

## B-24 — El duelo completo: Go frente a Spring Boot

**Fase:** 16 · **Proyecto:** ClearingHouse, en sus dos implementaciones ·
**Fecha:** _____

**La entrada más grande del banco, y la que más responsabilidad carga.**

### Hipótesis
Go gana claramente en arranque en frío (más de un orden de magnitud frente a la JVM,
menos de 3× frente a `native-image`) y en memoria residente (más de 2×). **En
rendimiento sostenido con la JVM ajustada y caliente, la diferencia es menor del
20%, y en el cierre por lotes largo la JVM puede ganar** porque el JIT tiene noventa
minutos para trabajar.

### Condiciones
REF-1 · **cinco variantes** · misma base de datos, mismo esquema, mismos datos ·
⚠️ **calentamiento de 60 s a 100 rps aplicado a las cinco y verificado con `jcmd`**
· generador: _____ (misma máquina / separada) · contenedores con `cpus=4 memory=2g`.

**Verificación previa obligatoria:** las dos implementaciones pasan la misma suite
de contrato HTTP **y** el `diff` de asientos tras el cierre es vacío.

### Cómo reproducirlo
```bash
scripts/bench/conditions.sh | tee b24-conditions.txt
scripts/bench/verify-equivalence.sh          # contrato + diff de asientos
for variant in go jvm-default jvm-tuned jvm-startup native; do
  scripts/bench/run-duel.sh $variant | tee b24-$variant.txt
done
```

### Resultados

**1. Arranque en frío hasta la primera petición servida** (10 corridas, mediana)

| Variante | Mediana | p90 | Variabilidad |
|---|---|---|---|
| Go | | | |
| JVM por defecto | | | |
| JVM ajustada (rendimiento) | | | |
| JVM ajustada (arranque + AppCDS) | | | |
| `native-image` | | | |

**2. Memoria residente (RSS)**

| Variante | En reposo | Bajo carga (500 rps) | Pico |
|---|---|---|---|
| *(cinco filas)* | | | |

**3. Latencia y rendimiento sostenido** — p50/p95/p99 a 50, 100, 250, 500, 1.000 y
2.000 rps, y **el ritmo de saturación de cada variante**.

**4. CPU por petición** — `(utime+stime)/peticiones`.

**5. Cierre de 1.000.000 de movimientos** — tiempo total, RSS máx., tiempo hasta el
primer fragmento confirmado.

**6. Imagen y compilación** — ver B-21.

**7. Pico de 10×** — subida del p99, peticiones fallidas, **y tiempo de vuelta a la
línea base**.

**8. Lo que no sale en un gráfico**

| | Go | Spring Boot |
|---|---|---|
| Líneas: lógica de negocio | | |
| Líneas: cableado/configuración | | |
| **Líneas: infraestructura que el framework daría** | | |
| Dependencias transitivas | | |
| Tiempo hasta el primer endpoint | | |

### Veredicto
**Tiene que doler un poco en las dos direcciones. Si el resultado es "Go gana en
todo", la medición está mal montada o la estás leyendo con los ojos que querías
tener.**

**Donde Go gana claro:** arranque, huella, imágenes, servicios de red concurrentes,
herramientas de línea de comandos, coste por instancia al escalar, simplicidad
operativa.

**Donde quedarse en Spring Boot es la decisión correcta:** transaccionalidad
compleja, lotes con reanudación fina (**Spring Batch no tiene rival**), equipos
grandes con la plataforma montada, ecosistemas donde la librería que necesitas solo
existe en Java, y —el que más proyectos decide— **cuando el problema no era el
lenguaje**.

### Qué NO demuestra
⚠️ **La sección más importante de esta entrada.**

- **Una máquina, una carga, una versión de cada stack.** Estos números enseñan a
  medir; **no son una tabla para citar en una reunión sin repetir el experimento**.
- **Un solo servicio.** ClearingHouse es transaccional y de lotes. Un servicio de
  lectura intensiva daría otra foto.
- **⚠️ La comparación NO incluye el almacén documental ni la caché.** Mongo y
  Valkey no entran en el duelo. **No extrapoles nada sobre ellos.**
- **No mide el coste de migrar**, que es casi siempre mayor que el ahorro de
  ejecutar. Ver el ejercicio 26 de la Fase 16.
- **No mide el periodo de convivencia** con dos plataformas, ni la curva de
  aprendizaje, ni el coste de oportunidad.
- Si el generador corrió en la misma máquina, todas las latencias bajo carga alta
  están contaminadas.
- El gemelo Java está escrito por una sola persona. Un equipo Spring experto podría
  mejorarlo, igual que un equipo Go podría mejorar el otro.

---

## B-25 — Amplificación del reintento: retroceso fijo frente a exponencial con jitter

**Fase:** 10 · **Proyecto:** EventRelay + `labs/backoff-lab` · **Fecha:** _____

### Hipótesis
Ante un socio que devuelve 503 durante 60 segundos, **el retroceso fijo multiplica
la carga sobre el socio caído en vez de aliviarla**, y el exponencial con jitter la
mantiene por debajo de la carga nominal. La hipótesis falsable: con 500 entregas
en vuelo, el retroceso fijo de 1 s produce **más de diez veces** las peticiones por
segundo que el exponencial con jitter completo, y el socio tarda más en
recuperarse aunque la carga entrante sea la misma.

### Condiciones
REF-1 · Go moderno · `fakeconsumer` configurado para devolver 503 durante 60 s y
luego 200 · 500 entregas encoladas · una sola instancia de EventRelay ·
`max_attempts=8`.

### Cómo reproducirlo
```bash
# El fakeconsumer registra la marca de tiempo de cada petición recibida.
go test -run TestRetryAmplification -v ./services/eventrelay/internal/delivery

# Histograma de peticiones por segundo, a partir del log del consumidor.
go run ./labs/backoff-lab -input fakeconsumer.log -bucket 1s
```

### Resultados

| Estrategia | Pico pet/s | Total de peticiones | Tiempo hasta drenar la cola | Entregas muertas |
|---|---|---|---|---|
| Sin retroceso (inmediato) | | | | |
| Fijo, 1 s | | | | |
| Exponencial sin jitter | | | | |
| Exponencial + jitter completo | | | | |

**Histograma** — peticiones por segundo, los primeros 120 s, una fila por
estrategia. Es el entregable de la entrada: el número medio miente aquí, la forma
de la curva no.

### Veredicto
Provisional: **el retroceso sin jitter no arregla el problema, lo reprograma.**
Todas las entregas fallan a la vez, esperan lo mismo y vuelven a la vez: el pico
se conserva y se desplaza. **El jitter es lo que rompe la sincronización**, y por
eso es la parte no negociable de la política, no un adorno del retroceso.

Si tus números muestran que el exponencial sin jitter ya basta, mira cuántas
entregas entraron en vuelo a la vez: con pocas, la sincronización no se nota y la
entrada no demuestra nada.

### Qué NO demuestra
Un solo socio y un solo modo de fallo (503 limpio y rápido). Un socio que responde
lento en vez de fallar produce otra foto, y es la peor de las dos. No cubre la
doble capa de reintento (aplicación + malla de servicios), que multiplica los
intentos y se discute en el ⚖️ de la Fase 10 sin medirse. No mide el efecto sobre
el resto de socios sanos, que es el argumento real del aislamiento.

---

## B-26 — MongoDB: `$push` sin límite frente al tamaño del documento

**Fase:** 11 · **Proyecto:** AtlasSync + `labs/bson-lab` · **Fecha:** _____

### Hipótesis
El array que crece sin límite dentro del documento **degrada la lectura mucho
antes de acercarse al límite de 16 MB**. Hipótesis falsable: con 10.000 elementos
en el array, la lectura del documento completo cuesta más de diez veces lo que
costaba con 100, aunque la consulta solo necesite tres campos de la raíz.

### Condiciones
REF-1 · Mongo 7 en Docker · un documento por variante · proyección explícita
frente a lectura completa · driver v2.

### Cómo reproducirlo
```bash
go test -run '^$' -bench BenchmarkDocumentGrowth -benchmem -count=10 ./labs/bson-lab
mongosh --eval 'db.products.stats().avgObjSize'
```

### Resultados

| Elementos en el array | Tamaño del doc | Lectura completa (ms) | Con proyección (ms) | `$push` (ms) |
|---|---|---|---|---|
| 100 | | | | |
| 1.000 | | | | |
| 10.000 | | | | |
| 100.000 | | | | |

### Veredicto
Provisional: **"los documentos no crecen sin límite" deja de ser un consejo y pasa
a ser un hecho medido.** El patrón de subcolección de la Fase 11 no es purismo de
modelado: es lo que mantiene plana la curva. Y la proyección explícita es el
parche barato cuando el modelo ya está mal y no se puede cambiar hoy.

### Qué NO demuestra
Un documento, sin concurrencia y sin contención de escritura. El caso feo real es
`$push` concurrente sobre el mismo documento, donde el coste no es el tamaño sino
el bloqueo. Tampoco mide el efecto sobre el conjunto de trabajo en RAM, que es
donde esto de verdad duele en producción.

---

## B-27 — El despachador del outbox frente al número de instancias

**Fase:** 13 · **Proyecto:** OpsReport + EventRelay · **Fecha:** _____

### Hipótesis
La cola en base de datos con `SKIP LOCKED` **escala de forma útil hasta unas pocas
instancias y luego deja de hacerlo**, porque la contención sobre el índice parcial
y el viaje de ida y vuelta a PostgreSQL dominan. Hipótesis falsable: pasar de 1 a
4 instancias multiplica el rendimiento por más de 2,5; pasar de 4 a 8 lo multiplica
por menos de 1,3.

**Esta es la entrada que sostiene el ⚖️ de la Fase 13**, donde se afirma que la
cola en base de datos aguanta "unos pocos miles de mensajes por segundo" antes de
que convenga un bróker.

### Condiciones
REF-1 · PostgreSQL 16 en Docker con `cpus=4` · 100.000 filas en el outbox ·
`fakeconsumer` respondiendo 200 en menos de 1 ms · lote de reclamación de 100 ·
todas las instancias en la misma máquina.

### Cómo reproducirlo
```bash
make up
go run ./tools/outbox-seed -rows 100000
for n in 1 2 4 8 16; do
  ./scripts/dispatch-bench.sh --instances "$n" --duration 60s
done
```

### Resultados

| Instancias | Mensajes/s | p99 de reclamación (ms) | Reclamaciones vacías | CPU de PostgreSQL |
|---|---|---|---|---|
| 1 | | | | |
| 2 | | | | |
| 4 | | | | |
| 8 | | | | |
| 16 | | | | |

### Veredicto
Provisional: **hay un punto en el que añadir instancias solo añade carga a la base
de datos.** Ese punto —y no una cifra citada de un blog— es el que decide cuándo
la cola en base de datos deja de bastar y toca Kafka, NATS o Rabbit. Si tus
números lo sitúan mucho más arriba de lo esperado, mira el porcentaje de
reclamaciones vacías: es el primer indicador de que las instancias se estorban.

### Qué NO demuestra
Todas las instancias en la misma máquina y contra la misma base de datos local:
sin latencia de red real, el techo aparece **antes** de donde aparecería en
producción, no después. No mide el coste operativo del bróker alternativo, que es
la otra mitad de la decisión. No cubre el particionado por clave, que es lo que
hace escalar a un bróker de verdad.

---

## B-28 — Coste del middleware de observabilidad por petición

**Fase:** 15 · **Proyecto:** OpsReport · **Fecha:** _____

**Pedida por tres fases** —la 05, la 10 y la 14— y medida aquí, que es donde el
banco de pruebas ya existe.

### Hipótesis
La cadena completa de middleware (request-id, logging estructurado, métricas y
traza) cuesta **menos de 50 µs por petición** y la parte cara es el muestreo de la
traza, no el logging. Hipótesis falsable: con la traza al 100% el coste supera al
resto de la cadena junto.

### Condiciones
REF-1 · Go moderno · endpoint que no toca la base de datos, para aislar el
middleware del trabajo real · `httptest` y carga con `hey`.

### Cómo reproducirlo
```bash
go test -run '^$' -bench BenchmarkMiddlewareChain -benchmem -count=10 \
  ./services/opsreport/internal/httpapi | tee mw.txt
benchstat mw.txt
```

### Resultados

| Cadena | ns/op | B/op | allocs/op | Δ sobre la cadena vacía |
|---|---|---|---|---|
| Sin middleware | | | | — |
| + request-id | | | | |
| + logging (`slog`, `LogAttrs`) | | | | |
| + métricas | | | | |
| + traza, muestreo 100% | | | | |
| + traza, muestreo 1% | | | | |

### Veredicto
Provisional: **la observabilidad se paga y el precio es barato, pero no es cero,
y conviene saber qué línea de la cadena lo cuesta.** El muestreo no es un ajuste
de coste de almacenamiento: es también un ajuste de latencia.

Esta entrada también resuelve la afirmación que la Fase 14 §6.2 hacía sobre el
coste de `slog`: la fila de logging la mide con atributos tipados, y el ejercicio
23 de esta fase la extiende a `slog.Any` y a la forma variádica.

### Qué NO demuestra
Un endpoint trivial maximiza el peso relativo del middleware. Sobre un endpoint
que hace una consulta a PostgreSQL, todo esto se vuelve ruido — y ese es
justamente el veredicto útil. No mide el coste del *exporter* ni el de la red
hacia el colector, que son asíncronos pero no gratis.

---

## B-29 — Fake frente a mock generado: tiempo de suite

**Fase:** 10 · **Proyecto:** los cuatro servicios · **Fecha:** _____

La candidata que `prompts/formato-de-benchmarks.md` §1 nombra desde el principio y
que la Fase 04 dejó anotada. Se mide aquí, donde `go.uber.org/mock` entra en el
curso.

### Hipótesis
El fake escrito a mano **no es más rápido por magia**: gana en tiempo de suite
sobre todo porque no hay generación previa ni reflexión en la verificación de
expectativas. Hipótesis falsable: sobre la misma suite, la variante con mocks
generados tarda más del 20% adicional, y la diferencia crece con el número de
expectativas por test.

### Condiciones
REF-1 · la misma suite implementada dos veces sobre la misma interfaz ·
`-count=1` con caché limpia · se mide también el `go generate` previo, porque en
CI se paga en cada corrida.

### Cómo reproducirlo
```bash
go clean -testcache
time go generate ./...
time go test ./services/... -run 'Fake'
time go test ./services/... -run 'Mock'
```

### Resultados

| Variante | Tiempo de suite | `go generate` | Líneas de doble | Líneas generadas |
|---|---|---|---|---|
| Fake a mano | | — | | — |
| `go.uber.org/mock` | | | | |

### Veredicto
Provisional: **la diferencia de tiempo es pequeña y el argumento real no es el
tiempo.** El fake gana en legibilidad del fallo —el test dice qué pasó, no qué
expectativa no se cumplió— y pierde cuando la interfaz es grande o cuando de
verdad necesitas verificar la interacción. Si tus números muestran una diferencia
de tiempo grande, cuenta las expectativas por test antes de sacar conclusiones:
probablemente estés midiendo un estilo de test, no una herramienta.

### Qué NO demuestra
Una suite y un tamaño de interfaz. El coste del mock generado crece con el número
de métodos, y el del fake también: por eso la regla de la Fase 02 sobre interfaces
pequeñas decide más que la elección de herramienta. No mide el coste de
mantenimiento, que es donde la decisión se paga de verdad y que ningún benchmark
captura.

---

## 📋 Mediciones propuestas y no asignadas

Siete propuestas surgieron durante la escritura del curso. **Cinco se asignaron**
—B-25 a B-29, arriba— y **dos se resolvieron suavizando la afirmación** en vez de
midiéndola, que es la otra salida honesta que el formato admite:

| Propuesta | Pedida por | Resolución |
|---|---|---|
| Amplificación del reintento (histograma) | F10 | ✅ **B-25** |
| `$push` frente al tamaño del documento | F11 | ✅ **B-26** |
| Rendimiento del outbox por instancias | F13 | ✅ **B-27** |
| Coste del middleware por petición | F05, F10, F14 | ✅ **B-28**, medida en la F15 |
| Fake frente a mock en tiempo de suite | F04, F10, formato §1 | ✅ **B-29** |
| `slog` frente a `log.Printf` | F14 | 🔤 afirmación suavizada a lo estructural, y la fila de logging de **B-28** la cubre |
| `ctx.Value` por profundidad del árbol | F07 | 🔤 afirmación suavizada a lo estructural |
| Efecto de `MaxIdleConnsPerHost` | F10 | 📎 sección de **B-23** |

> 🧭 **Las dos suavizadas no son una derrota.** El formato §3 dice que ante una
> afirmación sin medición hay dos salidas —medir o no afirmar—, y para un dato que
> no cambia ninguna decisión de diseño, la segunda es la barata y la honesta. Lo
> que no se admite es la tercera: escribirla igual con un "suele ser".

---

## 📖 Numeración

`B-01`, `B-02`, … en orden de creación, no de fase. **Un identificador nunca se
reutiliza.** Si una medición se rehace con otras condiciones, es una entrada nueva
que enlaza a la anterior y dice qué cambió.
