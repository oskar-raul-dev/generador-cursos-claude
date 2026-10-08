# 🗺️ Propuesta de fases y alcance
## Go para desarrolladores Java senior — 18 fases, 4 servicios, 131 horas

Documento de encuadre. Reparte el presupuesto y fija qué construye cada fase, de
qué proyecto y con qué mini proyectos. Junto con `alcance-del-proyecto.md` es la
fuente de verdad del mapa del curso.

---

## 🧭 1. La idea que ordena todo el curso

El curso tiene **tres bloques** y la frontera entre ellos es una decisión de
diseño, no un accidente de temario:

```text
Bloque A — Fases 00-07   Go 1.13, stdlib pura        El lenguaje sin azúcar
Bloque B — Fase 08 ⭐     La migración                 Dos servicios reales migran
Bloque C — Fases 09-17   Go moderno, ecosistema      El Go que vas a escribir
```

**Por qué empezar en 1.13.** Sin genéricos no hay dónde esconder un diseño
perezoso; sin `slog` se ve qué es un log estructurado; sin `slices` y `maps` se
aprende que un `for` de cuatro líneas casi siempre gana. Y sobre todo: sin
`ServeMux` moderno hay que escribir el enrutado a mano una vez, que es la única
forma de entender qué hace Spring MVC por debajo de `@GetMapping`.

**Por qué migrar a mitad y no al final.** Si la migración fuera la última fase,
el estudiante habría pasado el curso entero escribiendo Go de 2019 y saldría a
buscar trabajo con reflejos viejos. Migrando en la Fase 08, **más de la mitad del
curso transcurre en Go moderno**, y la migración misma es más rica: se migran dos
servicios que ya tienen persistencia, concurrencia y tests, no un puñado de
ejemplos.

**Por qué cuatro proyectos y no uno.** Un solo servicio no cubre las cuatro
familias de backend Go que existen en la industria: el de datos y lotes, el de
red y resiliencia, el de lectura intensiva con caché, y el transaccional con
cierre contable. Y porque el veredicto final —*¿Go o Spring Boot?*— solo es
honesto si hay un servicio implementado dos veces.

---

## ⏱️ 2. Reparto horario: 131h

| Fase | Nombre | Época | Horas | Proyecto que avanza |
|---|---|---|---|---|
| 🛠️ 00 | Ambiente, tooling y el comando `go` | — | **5h** | monorepo |
| 🔤 01 | Sintaxis, tipos y el modelo de valores | 1.13 | **7h** | OpsReport nace |
| 🧱 02 | Structs, métodos, interfaces y composición | 1.13 | **7h** | OpsReport · EventRelay nace |
| 🧯 03 | Errores, paquetes, I/O y JSON | 1.13 | **7h** | OpsReport · EventRelay |
| 🧪 04 | Testing idiomático, dobles y cobertura | 1.13 | **8h** | ambos |
| 🌐 05 | HTTP y REST con la stdlib | 1.13 | **8h** | ambos |
| ⚙️ 06 | **Concurrencia** ⭐ | 1.13 | **9h** | ambos |
| ⏱️ 07 | Context, cancelación y ciclo de vida | 1.13 | **7h** | ambos |
| 🚀 08 | **La migración a Go moderno** ⭐ | frontera | **8h** | ambos |
| 🗄️ 09 | SQL: PostgreSQL y SQLite | moderna | **9h** | OpsReport · ClearingHouse nace |
| 🔌 10 | Clientes HTTP, APIs externas y dobles generados | moderna | **8h** | EventRelay · AtlasSync nace |
| 🍃 11 | MongoDB y modelado documental | moderna | **7h** | AtlasSync |
| ⚡ 12 | Caché con Valkey | moderna | **6h** | AtlasSync · EventRelay |
| 📦 13 | Lotes, scheduling y trabajo asíncrono | moderna | **8h** | ClearingHouse · OpsReport |
| 👁️ 14 | Observabilidad, configuración y hardening | moderna | **7h** | los cuatro |
| 📈 15 | Rendimiento, profiling y benchmarking | moderna | **7h** | los cuatro |
| ⚖️ 16 | **Go frente a Spring Boot: el duelo medido** ⭐ | moderna | **8h** | ClearingHouse |
| 🏁 17 | Capstone: la plataforma completa y el veredicto | moderna | **5h** | los cuatro |
| | **Total** | | **131h** | |

Son **unos treinta y tres días de media jornada**. Para un senior que dedique dos
horas diarias, poco más de tres meses; para alguien en una semana de inmersión a
tiempo completo, tres semanas y media.

Las horas incluyen escribir el código y hacer los ejercicios, que es donde
realmente se va el tiempo. Leer las dieciocho fases seguidas, sin teclear, son
unas doce horas y no sirve de nada.

---

## 🪜 3. Las fases, con su alcance

### 🛠️ Fase 00 — Ambiente, tooling y el comando `go` (5h)

La única fase sin código de negocio, y no es opcional: **la mitad de la
frustración de un recién llegado a Go viene del tooling, no del lenguaje**.

Instalación con varias versiones conviviendo (la oficial, `go install
golang.org/dl/go1.13@latest` para la época legacy, y la directiva `toolchain`
para lo moderno). `GOROOT`, `GOPATH`, `GOMODCACHE`, `GOBIN`, y por qué ya no te
importa casi ninguna. El comando `go` recorrido de punta a punta: `build`, `run`,
`test`, `vet`, `fmt`, `mod`, `doc`, `env`, `list`, `clean`, `install`,
`generate`, compilación cruzada con `GOOS`/`GOARCH`.

**Ambiente de edición**, con mínimo de plugins y criterio explícito:

- **VS Code**: la extensión `golang.go` y nada más; `gopls`, `dlv`, `staticcheck`
  y qué hace cada uno; `settings.json` mínimo del curso; tareas de `go test` y
  configuración de depuración.
- **GoLand**: qué trae de fábrica que en VS Code hay que montar, los plugins que
  sí valen (`.env`, Database Tools, Makefile), el ejecutor de tests, el perfilador
  integrado, y la configuración de *file watchers* para `gofmt`.
- Lo común: `golangci-lint` con el `.golangci.yml` del curso, `EditorConfig`, y
  los hooks de pre-commit.

El monorepo del curso queda creado, con un módulo por servicio, el `Makefile` y
el `compose.yaml` con PostgreSQL, MongoDB y Valkey apagados a la espera.

**Mini proyectos:** `hello-go` (y el primer `declared and not used`),
`build-info` (información de compilación con `-ldflags`, que es el equivalente
del `MANIFEST.MF`), `crossbuild` (el mismo binario para cinco plataformas en un
comando, que es el argumento más corto a favor de Go que existe).

> 💸 El `Makefile` se escribe a mano y sin validación de entrada. Se paga en la
> Fase 14, cuando la configuración se vuelve seria.

---

### 🔤 Fase 01 — Sintaxis, tipos y el modelo de valores (7h)

Todo lo que un senior necesita para leer código Go, dicho en función de lo que ya
sabe: declaraciones y `:=`, tipos con nombre y por qué no son *typedefs*, valores
cero y por qué no hay `null`, `if` con inicializador, `switch` sin `break`,
`for` como única estructura de bucle, y `defer`.

Y el corazón de la fase: **arrays, slices y mapas**, con el modelo de memoria
delante. Un slice es una cabecera de tres campos, y de ahí salen el `append` que
a veces comparte respaldo y a veces no, el subslice que retiene un array de diez
megas por tres bytes, y el mapa nulo en el que no puedes escribir. Es la familia
de bugs número uno del recién llegado desde Java.

Strings, bytes y runas: por qué `len("ñ")` es 2, y por qué `range` sobre un
string no te da lo que esperas. Y punteros: los hay, no hay aritmética, y el
compilador decide dónde vive cada cosa.

**Mini proyectos:** `movement-parser` (parsear líneas de un archivo de
movimientos: el laboratorio de strings y errores), `text-toolkit` (normalizar,
partir y unir, con `strings.Builder` frente a la concatenación, medido 📐),
`log-grep` (expresiones regulares con `regexp`, compilación fuera del bucle, y la
comparación con `java.util.regex.Pattern`).

**OpsReport nace:** el tipo `WorkItem`, sus estados, las reglas de validación y
la puntuación de prioridad. Todo en memoria, sin servicio ni HTTP.

🪞 *El instinto dice que un slice es un `ArrayList`.* Es un `ArrayList` que a
veces comparte el arreglo interno con otro, y esa diferencia produce bugs
silenciosos.

---

### 🧱 Fase 02 — Structs, métodos, interfaces y composición (7h)

La fase donde se decide si el estudiante va a escribir Go o Java con llaves
distintas. Structs y etiquetas, métodos con receptor por valor o por puntero y
cuándo importa de verdad, embedding —que **no es herencia**, y la diferencia se
demuestra con un método que no se sobrescribe—, y **las interfaces implícitas**.

El punto central, que se repite todo el curso: **la interfaz se declara donde se
consume**. Eso invierte la dirección de las dependencias respecto a lo que un dev
de Spring tiene interiorizado, y es lo que permite que las interfaces sean
diminutas.

Constructores por convención (`New`), el reloj y el generador de identificadores
como dependencias inyectadas, y la inyección sin contenedor: una función `main`
que cablea cincuenta líneas y se lee entera.

**Mini proyectos:** `shapes` (interfaces mínimas y el cálculo de área, con la
autopsia del `AbstractShape`), `store-registry` (composición frente a herencia
con un caso que en Java sería una jerarquía de tres niveles), `notifier`
(interfaz de un método, tres implementaciones, cero fábricas).

**OpsReport:** dominio, servicio, almacén en memoria, reloj y generador de IDs
inyectados. **EventRelay nace:** `Endpoint`, `Event`, `Delivery`, y la máquina de
estados de la entrega.

⚰️ **Primera autopsia:** `WorkItemServiceImpl` con su interfaz de nueve métodos y
su fábrica, frente a un struct de cuarenta líneas. Se cuentan archivos, líneas e
indirecciones.

---

### 🧯 Fase 03 — Errores, paquetes, I/O y JSON (7h)

Errores como valores, con todo lo que eso implica: el `if err != nil` que el
recién llegado odia la primera semana y agradece el primer incidente de
producción, los errores centinela, los tipos de error, el envoltorio con `%w` de
Go 1.13 —que es **la** novedad de esta versión— y `errors.Is`/`errors.As`.

Se dice con todas las letras dónde Java gana: las excepciones comprobadas
obligan a decidir, y el `err` ignorado con `_` es un agujero que Go permite. Y
dónde gana Go: el flujo de error es visible en la firma y en el cuerpo, no en un
`throws` que nadie lee.

`defer` y su semántica exacta —cuándo se evalúan los argumentos, el orden LIFO, y
el `defer` dentro del bucle que agota descriptores—, `panic`/`recover` con su
lugar estrecho, y por qué `recover` no es `catch`.

Paquetes: visibilidad por mayúscula, `internal/`, ciclos de importación y por qué
el compilador los prohíbe. E/S con `io.Reader`/`io.Writer` como las dos
interfaces más importantes del ecosistema, y `encoding/json` con sus etiquetas,
sus trampas (`omitempty`, campos no exportados, el `interface{}` que devuelve
`float64`) y el streaming con `Decoder`/`Encoder`.

**Mini proyectos:** `error-chain` (una cadena de cuatro niveles y `errors.As`
recuperando el tipo del fondo), `config-loader` (entorno más archivo, con
validación y errores agregados), `json-codec` (el mismo documento con etiquetas,
con `json.RawMessage` y con decodificación en streaming, medido 📐).

**Ambos proyectos:** política de errores del paquete, configuración, y
serialización.

---

### 🧪 Fase 04 — Testing idiomático, dobles y cobertura (8h)

El paquete `testing` completo: tests de tabla, subtests con `t.Run`, `t.Helper`,
`t.Cleanup` —que es el `@After` de JUnit hecho bien—, `t.Parallel` y sus
trampas, golden files con `-update`, y `TestMain`.

**Dobles de prueba con el orden del curso**: función, fake, generado — y en esta
fase solo se llega a *fake*, deliberadamente. Un `FakeClock` y un `FakeStore` de
veinte líneas cubren las dos primeras fases de negocio, y el estudiante ve que
no necesitó Mockito. El generador llega en la Fase 10, cuando la interfaz del
cliente HTTP lo justifique.

Cobertura: `-coverprofile`, `-covermode=atomic`, el informe HTML, el umbral del
curso y la advertencia de que cobertura no es verificación. Y el detector de
carreras presentado aquí aunque se explote en la Fase 06.

**Mini proyectos:** `validator-tests` (una tabla de veinte casos que en JUnit
serían veinte métodos o un `@ParameterizedTest` con `@CsvSource`, comparados lado
a lado), `fake-clock`, `golden-report` (comparación contra archivo esperado).

**Ambos proyectos:** suite unitaria completa del dominio y el servicio, con
cobertura medida y umbral en el `Makefile`.

🪞 *El instinto dice que hay que mockear el almacén.* El fake tiene menos líneas
que la configuración del mock, y además prueba comportamiento en vez de
interacción.

---

### 🌐 Fase 05 — HTTP y REST con la stdlib (8h)

`net/http` de arriba abajo con el enrutado escrito a mano, que es lo que fuerza
la época de 1.13 y resulta ser una ventaja pedagógica: el estudiante descubre que
`@GetMapping("/work-items/{id}")` es un `switch` sobre método y un corte de
cadena, y deja de tenerle respeto reverencial.

`http.Handler` y `http.HandlerFunc`, middleware como composición de handlers
—cadena de autenticación, registro, recuperación de panic, identificador de
petición—, codificación y decodificación de JSON en el borde, códigos de estado
con criterio, y el manejo de errores del dominio traducido a HTTP en un solo
sitio.

`httptest.NewRecorder` y `httptest.NewServer`, y la suite HTTP completa de los
dos servicios. Y los tiempos de espera del servidor (`ReadTimeout`,
`WriteTimeout`, `IdleTimeout`) explicados ahora, porque el `http.Server{}` por
defecto no tiene ninguno y eso es un incidente esperando.

**Mini proyectos:** `tiny-router` (enrutado por método y patrón, escrito a mano;
se guarda para compararlo con el `ServeMux` de 1.22 en la Fase 08),
`middleware-chain`, `httptest-lab`.

**OpsReport y EventRelay:** sus APIs REST en memoria, completas y probadas.

📖 El diccionario de esta fase es el más largo del curso: `@RestController`,
`@RequestMapping`, `@RequestBody`, `@ResponseStatus`, `@ControllerAdvice`,
`Filter`, `HandlerInterceptor`, `WebMvcConfigurer` — y qué ocupa el lugar de cada
uno, o por qué no lo ocupa nadie.

---

### ⚙️ Fase 06 — Concurrencia ⭐ (9h)

La fase estrella del Bloque A y la razón por la que mucha gente llega a Go.

El planificador y por qué una goroutine cuesta kilobytes y un hilo de la JVM
cuesta megas 📐. Canales con y sin búfer, `select`, el cierre de canales y quién
tiene derecho a cerrarlos, `sync.WaitGroup`, `sync.Mutex` y `RWMutex`,
`sync.Once`, `atomic`, y el modelo de memoria de Go leído de verdad.

Los patrones que se construyen, no se copian: **worker pool acotado**, fan-out /
fan-in, *pipeline*, semáforo con canal con búfer, y `errgroup` como comparación
🕰️ (llega en el Bloque C).

Y los laboratorios de desastre, que son la mitad del valor de la fase:
`race-counter` (la carrera que `-race` encuentra y el ojo no), `deadlock-lab`
(cuatro formas de colgar el programa), `leak-lab` (la goroutine que nadie
recoge), `unbounded-queue` (por qué la cola sin límite convierte un pico de
tráfico en un OOM).

**Ambos proyectos:** OpsReport estrena su motor de jobs con N workers y estados;
EventRelay estrena su cola de entregas con concurrencia acotada. Los dos pasan
`go test -race ./...`.

📖 Diccionario denso: `Thread`, `Runnable`, `ExecutorService`,
`ThreadPoolExecutor`, `CompletableFuture`, `BlockingQueue`, `synchronized`,
`ReentrantLock`, `AtomicInteger`, `CountDownLatch`, `Semaphore`, `ForkJoinPool`,
y las hebras virtuales de Java 21 — que son el paralelo más cercano a una
goroutine y merecen su párrafo honesto.

⚖️ Veredicto: hay problemas donde `CompletableFuture` encadenado se lee mejor que
tres canales, y decirlo no cuesta nada.

---

### ⏱️ Fase 07 — Context, cancelación y ciclo de vida (7h)

`context.Context` explicado por lo que es —un árbol de cancelación con fecha
límite y valores de petición— y por lo que no es: ni `ThreadLocal`, ni bolsa de
parámetros, ni sitio para meter el usuario autenticado por comodidad.

`WithCancel`, `WithTimeout`, `WithDeadline`, `WithValue` y sus reglas de uso;
propagación desde el handler HTTP hasta el driver de base de datos; `ctx.Done()`
en el `select` de todo worker; y el ciclo de vida completo del proceso: señales
del sistema operativo, `Shutdown` del servidor HTTP, drenaje del pool de workers,
y el tiempo límite de apagado.

Fugas de goroutines: cómo se detectan (`runtime.NumGoroutine`, el perfil
`goroutine` de `pprof`, `goleak`), por qué casi siempre son un canal sin lector o
un `context` sin cancelar, y el test que las caza.

**Mini proyectos:** `cancellable-worker`, `timeout-client`, `graceful-server`,
`leak-detector`.

**Ambos proyectos:** cancelación de punta a punta y apagado ordenado, con tests
que verifican que tras `SIGTERM` no queda ninguna goroutine viva.

---

### 🚀 Fase 08 — La migración a Go moderno ⭐ (8h)

La frontera. Se migran OpsReport y EventRelay **sin reescribirlos**, salto por
salto, con la suite de tests como red.

- **1.14-1.16:** `errors` maduro, `os.ReadFile`, `io/fs`, `embed` —las
  migraciones SQL y las plantillas HTML dejan de ser archivos sueltos—, y el fin
  de `GOPATH` como tema.
- **1.17-1.18:** `go.work` y el monorepo del curso deja de pelearse consigo
  mismo; **genéricos**, enseñados en serio y restringidos en serio (guía §6.4);
  **fuzzing** con `testing.F`, aplicado al parser de movimientos y al verificador
  de firmas.
- **1.19-1.21:** `log/slog` reemplaza el logger propio y se comparan las dos
  salidas; `slices`, `maps` y `cmp`; `errors.Join`; `context.WithoutCancel`; la
  directiva `toolchain`; `GOMEMLIMIT`.
- **1.22-1.23:** el **`ServeMux` con método y patrón**, que jubila el
  `tiny-router` de la Fase 05 — y la comparación de los dos, lado a lado, es la
  mejor clase de diseño de API del curso; el cambio de semántica de la variable
  de bucle, con el ejercicio de buscar en el código de las siete fases anteriores
  dónde habría cambiado el comportamiento; `range` sobre enteros y funciones;
  iteradores.
- **Hasta la versión vigente:** qué se adopta y, sobre todo, **qué se rechaza**.
  La lista de rechazos con su motivo es un entregable de la fase.

El estudiante termina con dos ramas comparables y un `git diff` que es el
documento más instructivo del curso.

> 🧭 **La regla que se lleva:** modernizar no es sustituir cada API vieja por la
> nueva. Es preguntarse, una por una, si el cambio hace el código más simple de
> mantener. Las que no, se quedan.

---

### 🗄️ Fase 09 — SQL: PostgreSQL y SQLite (9h)

`database/sql` explicado por lo que es: **un pool, no una conexión**. De ahí
salen `SetMaxOpenConns`, `SetMaxIdleConns`, `SetConnMaxLifetime`, y el incidente
clásico de las filas no cerradas que agotan el pool.

Consultas con contexto, `Scan` y sus tipos nulos, `pgx` en modo nativo frente a
`database/sql` y qué gana cada uno, transacciones con `defer tx.Rollback()` como
patrón, niveles de aislamiento, y migraciones versionadas con `goose`.

El debate del ORM, resuelto con argumentos y no con dogma: **`sqlc` frente a
`GORM` frente a SQL a mano**, los tres probados sobre la misma consulta, con el
diccionario 📖 completo de JPA —`@Entity`, `@Repository`, `EntityManager`, el
`N+1`, el caché de primer nivel, el *lazy loading*, `@Transactional`— y el
veredicto: **en Go la propagación transaccional es un parámetro, no una
anotación**, y eso se paga en verbosidad y se cobra en que nunca te preguntas si
esta llamada está dentro de una transacción.

**SQLite** entra por la puerta que lo justifica: el agente de tienda de
ClearingHouse funciona sin red y acumula movimientos en local. `modernc.org/sqlite`
sin cgo, WAL, y las diferencias reales con PostgreSQL que muerden.

Tests de integración con `testcontainers-go`, build tags, y el objetivo de
`make test-integration`.

**OpsReport** persiste de verdad. **ClearingHouse nace**: el agente de tienda,
como CLI, con su SQLite.

---

### 🔌 Fase 10 — Clientes HTTP, APIs externas y dobles generados (8h)

`http.Client` bien configurado, que es un tema en sí mismo: el cliente por
defecto no tiene tiempo límite, el `Transport` se reutiliza o se agotan los
puertos efímeros, y el cuerpo de la respuesta se cierra siempre —y se drena antes
de cerrarlo si quieres reutilizar la conexión.

Reintentos con retroceso exponencial y *jitter* escritos a mano, clasificación
de errores recuperables frente a permanentes, `singleflight` para el rebaño
atronador, limitación de tasa con `golang.org/x/time/rate`, y un cortacircuitos
mínimo.

**AtlasSync nace** consumiendo APIs públicas reales y sin clave: **REST
Countries** para el catálogo de países y monedas, y **Frankfurter** para tipos de
cambio del BCE. Y con ello llega el tema que el curso venía aplazando:

**Cómo se prueba un servicio que depende de internet.** Tres niveles, los tres se
construyen: la interfaz del cliente con un fake para los unitarios; un
`httptest.Server` que sirve respuestas grabadas para los de componente; y una
suite de punta a punta con el servicio completo levantado contra ese servidor
falso, **sin tocar la red**, más una única prueba marcada 🔥 que sí golpea la API
real y que **no corre en CI**.

Aquí entra por fin **`go.uber.org/mock`**, con su justificación: verificar que el
cliente reintentó exactamente tres veces y no cuatro es verificación de
interacción, y para eso el fake se queda corto.

📖 Diccionario: `RestTemplate`, `WebClient`, `@FeignClient`, `@Retryable`,
WireMock, `@MockBean`, `RestClientTest`.

---

### 🍃 Fase 11 — MongoDB y modelado documental (7h)

Por qué AtlasSync usa Mongo y OpsReport no: el documento de un país de REST
Countries tiene una forma irregular, anidada y cambiante, y normalizarlo a diez
tablas para volver a unirlo en cada lectura es trabajo sin destinatario. Se dice
así, con el contraejemplo delante.

El driver oficial, BSON y sus etiquetas, `Decode` frente a `All`, índices
—incluidos los de texto y los TTL—, el *framework* de agregación con el
paralelo a `GROUP BY`, actualizaciones atómicas con operadores, `upsert`, y
transacciones multi-documento con su advertencia de coste.

Y el modelado, que es la parte que se transfiere: incrustar frente a referenciar,
el límite de dieciséis megas, los patrones de atributo y de cubo, y por qué
"esquemaless" no significa "sin esquema" sino "esquema en el código".

📖 Diccionario: Spring Data MongoDB, `MongoTemplate`, `@Document`,
`MongoRepository`, y la diferencia entre un repositorio derivado de nombres de
método y una consulta escrita.

⚖️ Veredicto: los tres casos en los que Mongo es la respuesta equivocada, y por
qué el primero de ellos es "porque el equipo ya lo tenía levantado".

---

### ⚡ Fase 12 — Caché con Valkey (6h)

Valkey como qué es —el fork de Redis bajo la Linux Foundation— y el cliente
`valkey-go`, con `go-redis` como alternativa comentada.

Los patrones de verdad: *cache-aside* con su condición de carrera, *write-through*
y *write-behind* con sus riesgos, TTL con *jitter*, la estampida de caché
resuelta con `singleflight` local más bloqueo distribuido, invalidación por clave
y por etiqueta, y el diseño de las claves —que es el 80% de la calidad de una
caché y casi nunca se discute.

Y los usos que no son caché: limitación de tasa por socio comercial, bloqueos
distribuidos con su advertencia grande sobre corrección, colas ligeras, y
`SETNX` para idempotencia.

**AtlasSync** cachea el catálogo y los tipos de cambio, con métricas de aciertos
y fallos medidas 📐. **EventRelay** limita la tasa por endpoint.

📖 Diccionario: `@Cacheable`, `@CacheEvict`, `@CachePut`, `CacheManager`,
`RedisTemplate`, Spring Session. ⚖️ Veredicto: un mapa en memoria con TTL resuelve
más casos de los que la gente cree, y no necesita un servicio más en el
`compose.yaml`.

---

### 📦 Fase 13 — Lotes, scheduling y trabajo asíncrono (8h)

El cierre diario de ClearingHouse es el caso: leer millones de movimientos,
conciliarlos, producir asientos y cerrar el periodo, de forma reanudable y sin
cargar nada entero en memoria.

Procesamiento por lotes con cursores y *streaming* (`sql.Rows` recorrido de
verdad, no un `[]T` de un millón), fragmentación y punto de control, idempotencia
del lote, reanudación tras caída, y el informe de ejecución.

Scheduling: `time.Ticker` frente a un planificador propio, cron con `robfig/cron`
evaluado, y el problema que Spring resuelve con `ShedLock` y aquí se resuelve con
un bloqueo en base de datos — con el veredicto de que una instancia y un
planificador simple ganan casi siempre.

El **patrón outbox**, que es donde EventRelay y OpsReport se encuentran: la
transacción que escribe el estado y el evento juntos, y el proceso que los
despacha. Se implementa completo.

Y `errgroup` con límite, `semaphore.Weighted`, y el diseño de contrapresión.

📖 Diccionario: Spring Batch entero —`Job`, `Step`, `ItemReader`,
`ItemProcessor`, `ItemWriter`, `JobRepository`, chunks, `@Scheduled`,
`TaskExecutor`— con la parte honesta: **Spring Batch resuelve reanudación,
reintento por ítem y métricas de job que aquí hay que escribir.** Si tu proceso
por lotes es complejo de verdad, eso es un argumento real a favor de Java, y así
se dice.

---

### 👁️ Fase 14 — Observabilidad, configuración y hardening (7h)

`log/slog` bien usado: niveles, atributos, grupos, manejadores, el `Logger`
inyectado en vez del global, correlación con el identificador de petición a
través del `context`, y qué **no** se registra nunca.

Métricas con `prometheus/client_golang`: los cuatro tipos, las métricas RED, la
cardinalidad de etiquetas como la forma más común de tumbar un Prometheus, y el
`/metrics`. Trazas con OpenTelemetry, propagación de contexto entre servicios, e
instrumentación de HTTP y de base de datos.

Health y readiness de verdad: la diferencia importa cuando hay un orquestador
delante, y el `/ready` que consulta la base de datos en cada petición es un
ataque de denegación de servicio que te haces a ti mismo.

Configuración doce-factores: entorno, precedencia, validación al arrancar y
fallo rápido, secretos, y la comparación con `@ConfigurationProperties` y los
perfiles de Spring. Contenedores multi-etapa, imagen `distroless` o `scratch`,
usuario sin privilegios, y el tamaño final comparado 📐 con el de la imagen de un
Spring Boot equivalente.

Y el endurecimiento: límite de tamaño del cuerpo, tiempos de espera en los cinco
sitios donde hacen falta, recuperación de panic en el borde, cabeceras, CORS,
`govulncheck` y `nancy` para dependencias.

📖 Diccionario: Actuator, Micrometer, Logback y MDC, `application.yml` y perfiles.

---

### 📈 Fase 15 — Rendimiento, profiling y benchmarking (7h)

Benchmarks con `testing.B` hechos bien: `b.ResetTimer`, `b.ReportAllocs`,
`b.RunParallel`, y **`benchstat`**, porque una sola corrida no dice nada y la
diferencia entre ruido y mejora es estadística.

`pprof` completo —CPU, heap, goroutine, mutex, block—, el servidor de depuración
y cómo exponerlo sin regalarlo, la lectura de un gráfico de llamas, y el `trace`
para ver el planificador de verdad.

Escape analysis con `-gcflags=-m`, el coste de las asignaciones, `sync.Pool` con
su advertencia, el pre-dimensionado de slices y mapas, la interfaz que fuerza una
asignación, y la concatenación de cadenas medida cuatro maneras.

El recolector de basura de Go frente al de la JVM: dos filosofías distintas
—latencia baja y predecible frente a rendimiento máximo con pausas mayores— y las
perillas que existen (`GOGC`, `GOMEMLIMIT`) comparadas con las cuarenta de la
JVM. Sin ganador: con criterio.

Y las pruebas de carga con `k6` o `vegeta` sobre los cuatro servicios, que dejan
el banco de pruebas listo para la fase siguiente.

Todo lo que se mide aquí va a `BENCHMARKS.md` con el formato de
`formato-de-benchmarks.md`.

---

### ⚖️ Fase 16 — Go frente a Spring Boot: el duelo medido ⭐ (8h)

La fase por la que existe el curso. **ClearingHouse está implementado dos veces**:
la versión Go que el estudiante construyó y una versión Spring Boot 3 equivalente
que el curso **entrega hecha** —no se enseña a escribirla, el estudiante ya sabe—
con el mismo esquema, los mismos endpoints y el mismo cierre por lotes.

Se miden, con el mismo banco y la misma máquina:

- arranque en frío hasta la primera petición servida;
- memoria residente en reposo y bajo carga;
- latencia p50/p95/p99 y rendimiento sostenido;
- consumo de CPU por petición;
- tamaño de la imagen y tiempo de compilación;
- el cierre por lotes de un millón de movimientos, extremo a extremo;
- y la JVM en sus tres configuraciones: por defecto, ajustada, y `native-image`
  con GraalVM — porque comparar Go contra una JVM sin ajustar es hacer trampa.

Y se miden las cosas que no salen en los gráficos y deciden proyectos: líneas de
código, dependencias de tercero, tiempo hasta el primer endpoint funcionando,
madurez del ecosistema por área, y facilidad de contratar.

🔥 Sección opcional: gRPC en los dos stacks, que es la pregunta que siempre
aparece cuando alguien dice "microservicios".

⚖️ **El veredicto honesto** es el entregable de la fase, y tiene que doler un
poco en las dos direcciones. Los casos donde Go gana claro: arranque, huella,
contenedores, servicios de red concurrentes, herramientas de línea de comandos,
escalado horizontal con coste por instancia. Los casos donde **quedarse en Spring
Boot es la decisión correcta**: dominios con transaccionalidad compleja, lotes
con reanudación fina, equipos grandes que ya tienen la plataforma montada,
ecosistemas donde la librería que necesitas solo existe en Java, y —el que más
proyectos decide— cuando el problema no era el lenguaje.

---

### 🏁 Fase 17 — Capstone: la plataforma completa y el veredicto (5h)

Los cuatro servicios corriendo juntos con un `docker compose up`, con el flujo
completo atravesándolos: una tienda sincroniza movimientos, ClearingHouse los
concilia, OpsReport registra el trabajo y emite el reporte, EventRelay notifica
al socio, AtlasSync provee los tipos de cambio del día desde su caché.

Revisión final de código contra el catálogo de `INSTINTOS.md`, `golangci-lint` en
verde, cobertura sobre el umbral, y la suite de integración completa.

Y la defensa técnica, que son ocho preguntas con respuesta escrita:

1. ¿Qué reflejos de Java trasladaste y cuáles descartaste?
2. ¿Dónde Go te obligó a escribir más, y valió la pena?
3. ¿Dónde escribiste menos y el resultado fue más claro?
4. ¿Qué se rompió al migrar de 1.13 a moderno, y qué no?
5. ¿Qué features modernas decidiste **no** usar, y por qué?
6. ¿Qué medición te sorprendió?
7. ¿Qué servicio de tu trabajo actual migrarías, y cuál no tocarías?
8. ¿Qué le dirías a tu yo de la Fase 01?

---

## 📁 4. Convención de nombres de archivo

Fases: `NN-tema.md`, de `00-instalacion-ambiente-y-tooling.md` a `17-capstone.md`.
Minúsculas, guiones, dos dígitos, sin excepciones.

**No hay apéndices** (`alcance-del-proyecto.md` §9). Los documentos maestros del
curso, en la raíz, son `README.md`, `0-ESTRUCTURA-CURSO.md`,
`00-convencion-de-git-y-tags.md`, `INSTINTOS.md` y `BENCHMARKS.md`.

**Tags:** `fase-NN`. Prefijo de commit `fase NN:`; de ejercicio,
`fase NN ejNN:`. Cada proyecto además marca sus hitos con su propio prefijo
(`opsreport/v0.4`, `eventrelay/v0.2`), para poder leer la evolución de un solo
servicio sin el ruido de los otros tres.

---

## 🧰 5. Los mini proyectos

Son **veintiocho**, repartidos entre las fases, y su papel está acotado por la
guía §4.4: **aislar un concepto antes de llevarlo a un servicio grande**. Viven
en `labs/` dentro del monorepo, cada uno con su `main.go` y sus tests, y ninguno
supera las doscientas líneas.

La regla que los mantiene honestos: **si un mini proyecto no alimenta después a
un servicio, o sobra o está mal planteado.** `tiny-router` alimenta la API de la
Fase 05 y reaparece en la 08 para morir con dignidad; `fake-clock` se usa en los
cuatro servicios; `log-grep` es el germen del parser de movimientos de
ClearingHouse.

---

## 📌 6. Trazabilidad: qué fase toca qué proyecto

| Fase | OpsReport | EventRelay | AtlasSync | ClearingHouse |
|---|---|---|---|---|
| 01 | nace: dominio | — | — | — |
| 02 | servicio + memoria | nace: dominio + estados | — | — |
| 03 | errores + config | errores + config | — | — |
| 04 | suite unitaria | suite unitaria | — | — |
| 05 | API REST | API REST | — | — |
| 06 | motor de jobs | cola de entregas | — | — |
| 07 | cancelación + apagado | cancelación + apagado | — | — |
| 08 | migra | migra | — | — |
| 09 | PostgreSQL | — | — | nace: agente + SQLite |
| 10 | — | cliente HTTP robusto | nace: ingesta + dobles | — |
| 11 | — | — | MongoDB | — |
| 12 | — | límite de tasa | caché | — |
| 13 | outbox | consumo del outbox | — | cierre por lotes |
| 14 | los cuatro | los cuatro | los cuatro | los cuatro |
| 15 | perfilado | perfilado | perfilado | perfilado |
| 16 | — | — | — | duelo contra Spring |
| 17 | integración final | integración final | integración final | integración final |

---

## 🚦 7. Siguiente paso

Con este documento aprobado, el orden de escritura es:

1. `README.md` y `0-ESTRUCTURA-CURSO.md` del curso, derivados de aquí.
2. `00-convencion-de-git-y-tags.md`, que las dieciocho fases enlazan.
3. Las fases en orden, una por chat, con su prompt de
   `prompts-extendidos-fases.md`.
4. `INSTINTOS.md` y `BENCHMARKS.md` crecen con cada fase; **no se escriben al
   final**, se alimentan al cerrar cada una.
