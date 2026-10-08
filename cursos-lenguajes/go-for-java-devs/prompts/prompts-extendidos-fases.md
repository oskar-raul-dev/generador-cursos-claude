# 📍 Prompts para redactar las fases
## Go para desarrolladores Java senior — 18 chats, 18 archivos

Cada fase se escribe en **su propio chat** y produce **un solo archivo**. Si un
chat no produce entregable, o sobra o se salió de alcance.

## Cómo se usa este archivo

Un prompt completo se arma con **dos bloques pegados en este orden**:

1. **El bloque MARCO** (§1). Es idéntico para las dieciocho fases y se pega
   primero, siempre.
2. **El bloque de la fase** (§2). Es el que cambia.

Se separó así a propósito: el marco es la parte que más se corrige durante la
escritura del curso, y tenerlo en un solo sitio evita que dieciocho copias se
desincronicen. Si cambias una regla, la cambias una vez.

> ⚠️ Los valores de los bloques de fase salen de `propuesta-fases-y-alcance.md`
> §2 y §3 y de los cuatro `proyecto-0N-*.md`. Si alguna vez cambian allí, se
> cambian aquí **después**, nunca al revés.

---

# 1. Bloque MARCO

Pégalo tal cual al inicio de cada chat de fase.

```markdown
Vas a escribir una fase del tutorial **Go para desarrolladores Java senior — la
plataforma Meridian**. Trabajamos una fase por chat y el entregable es un único
archivo `.md`.

## Fuentes de verdad (no las repitas, aplícalas)

En este orden: `prompts/alcance-del-proyecto.md`,
`prompts/propuesta-fases-y-alcance.md`, los cuatro `prompts/proyecto-0N-*.md`,
`prompts/guia-de-estilo-y-convenciones.md`, `prompts/plantillas-de-capitulo.md`,
`prompts/formato-de-benchmarks.md`, los entregables de fases anteriores, y las
decisiones explícitas de este chat.

Los archivos `prompts/_desechable-*.md` **no cuentan como fuente de nada** y no se
referencian nunca.

La plantilla de fase —**diez secciones**, el bloque 🏷️ del cierre y el bloque 📌
de autoría— está en `plantillas-de-capitulo.md` y se sigue literal: sin secciones
extra, sin reordenar, sin fusionar. La voz, el tuteo, la regla del andamio y la
prosa antes que listas están en la guía de estilo.

## Las siete reglas que más se rompen

1. **La época.** Las Fases 00–07 son **Go 1.13 con stdlib pura**: nada de
   genéricos, `slog`, `slices`, `maps`, `errors.Join`, `embed`, `io/fs`,
   `os.ReadFile`, `go.work`, `ServeMux` con patrones, ni fuzzing. Lo moderno
   puede aparecer **solo** como comparación, marcado 🕰️ y con su versión mínima.
   El compilador no te va a avisar: la disciplina es tuya.
2. **Código en inglés, comentarios en español con tildes.** Sin excepciones, ni
   en SQL, ni en YAML, ni en el Dockerfile. Los mensajes de error van en español,
   con minúscula inicial y sin punto final, como manda la convención de Go.
3. **"Diciendo y haciendo".** Ningún bloque teórico de más de dos pantallas sin
   un comando o un fragmento de código de por medio. Primero el problema, después
   la herramienta, después el código que corre.
4. **Nada de Java escrito en Go.** Paquetes de una palabra, sin `utils`,
   `common`, `helpers`, `models` ni `impl`; interfaces pequeñas y **declaradas en
   el consumidor**; sin prefijo `I` ni sufijo `Impl`; dependencias por
   constructor, sin contenedor ni estado global; errores como valores, sin
   `panic` como flujo; `context.Context` como primer parámetro de todo lo que
   hace E/S; ninguna goroutine sin dueño ni tope.
5. **Cada 💸 declara en qué fase se paga**, o dice por qué no se paga.
6. **Ninguna afirmación de rendimiento sin su entrada en `BENCHMARKS.md`**,
   marcada 📐 y citada por su identificador. Si no tienes la medición, creas la
   entrada o no escribes la frase.
7. **Respeto por Java y por Spring.** Ninguna comparación puede leerse como
   "Spring es malo". Lo que decimos, con datos, es dónde el intercambio conviene
   — y también dónde no.

## Secciones obligatorias dentro de la plantilla

🪞 *Tu instinto de Java dice… y esta vez se equivoca*, 🩻 *Esto sí funciona
igual*, 🛠️ *CLI de la fase*, 📖 *Diccionario Java ⇄ Go* (en las dos direcciones,
con la columna "dónde se rompe la equivalencia"), ⚖️ *Cuándo NO usar esto*, al
menos un 🧨 *rompe a propósito*, y —desde la Fase 02— una ⚰️ *autopsia* de un
antipatrón con su costo en números.

Y las dos que cierran la fase y **no cuentan para su extensión** (guía §9.2):

- **🔴 Desafíos de cierre**, al final de la §8: exactamente tres, identificados
  `D1`/`D2`/`D3`, sin numerar y **fuera del total declarado**. Cubren lo que la
  fase dejó fuera a propósito —el hueco de la §3, la comparación que no se hizo, la
  herramienta que el temario no montó—, no lo que ya consolidan los 🔴 numerados.
  Con rúbrica, respetando la época, y sin duplicar nada de arriba.
- **📚 Referencias**, la §9 completa, con sus cinco partes. **Nunca se recorta por
  longitud.** Si hay que quitar contenido, sale de la §6.

## Cómo quiero que trabajes

**Paso 1 — Preguntas antes de escribir.** No redactes todavía. Devuélveme:

a) Las **preguntas bloqueantes** que necesitas resueltas para no inventar:
   nombres y firmas heredados de fases previas, decisiones que esta fase fija y
   las siguientes heredan. Numéralas y marca cuáles son bloqueantes y cuáles
   puedes asumir con un valor por defecto razonable si no contesto.
b) Tu **lectura del alcance**: qué sobra o falta en lo que te di, y si las horas
   asignadas cuadran con el contenido pedido.
c) Un **esbozo de la sección 6**: qué archivos vas a mostrar, en qué orden, qué
   mini proyecto abre, y qué queda fuera. Quiero verlo antes de que escribas mil
   líneas.
d) Cualquier **contradicción** con fases anteriores o con los documentos base. Si
   la hay, dímela; no la resuelvas por tu cuenta.

**Paso 2 — Redacción.** Cuando yo responda, escribe el documento completo. Si en
mitad aparece una duda nueva, **para y pregunta** en vez de rellenar con un
supuesto plausible.

**Paso 3 — Autoverificación.** Al final, pásale el checklist de §13 de la guía de
estilo y repórtame en una lista corta qué cumples y qué no, con el motivo. Presta
atención especial a cuatro: la época respetada, el ritmo de "diciendo y
haciendo", cada 💸 con su fase de cobro, y cada afirmación de rendimiento con su
entrada de `BENCHMARKS.md`.

**Fuera de alcance:** si aparece un tema interesante que no cabe, anótalo en el
bloque 📌 del final con su destino (fase posterior, ejercicio 🔥, entrada de
`INSTINTOS.md` o de `BENCHMARKS.md`). No infles la fase.
```

---

# 2. Bloques de fase

## Fase 00

```markdown
## Identidad

- Fase **00 de 17** — 🛠️ Ambiente, tooling y el comando `go`
- Archivo: `00-instalacion-ambiente-y-tooling.md` · Horas: **5h**
- Época: **previa** — se instalan las dos, y se explica por qué hay dos
- Depende de: ninguna · Habilita: Fase 01
- Proyectos: ninguno todavía; se crea el monorepo
- Mini proyectos: `hello-go`, `build-info`, `crossbuild`

## Alcance

- **Propósito:** dejar la máquina lista y al lector capaz de moverse por el
  toolchain sin IDE. La mitad de la frustración del recién llegado a Go viene de
  aquí, no del lenguaje.
- **Entra:** instalación con Go moderno y `go1.13` conviviendo
  (`go install golang.org/dl/go1.13@latest`); `GOROOT`, `GOPATH`, `GOMODCACHE`,
  `GOBIN`, `GOFLAGS` y por qué casi ninguna te importa ya; el comando `go`
  completo (`build`, `run`, `test`, `vet`, `fmt`, `mod`, `doc`, `env`, `list`,
  `clean`, `install`, `generate`, `version`); módulos, `go.mod`, `go.sum`,
  versionado semántico y `replace`; compilación cruzada con `GOOS`/`GOARCH`;
  `-ldflags` para inyectar versión y commit; **VS Code** con `golang.go`, `gopls`,
  `dlv`, `staticcheck`, el `settings.json` mínimo y la configuración de
  depuración; **GoLand** con lo que trae de fábrica, sus plugins útiles, su
  ejecutor de tests y sus *file watchers*; `golangci-lint` con el `.golangci.yml`
  del curso; el `Makefile`; el `compose.yaml` con PostgreSQL, MongoDB y Valkey; y
  el layout del monorepo con un módulo por servicio y `labs/`.
- **NO entra:** sintaxis del lenguaje → Fase 01. `go.work` → Fase 08 (Go 1.18),
  marcado 🕰️ aunque duela, porque el monorepo se maneja con módulos
  independientes hasta entonces.
- **💸 Deuda:** el `Makefile` sin validación de entrada y con rutas fijas. Se paga
  en la Fase 14.
- **📐 Medición:** B-01, compilación cruzada — mismo binario para cinco
  plataformas, tiempo total y tamaño de cada uno.
- **Diccionario:** JDK / SDKMAN, Maven y Gradle, `pom.xml`, el repositorio local
  `~/.m2`, `mvn wrapper`, Checkstyle y Spotless, el classpath, `MANIFEST.MF`.
- **Ejercicios:** 20.

## Advertencia especial

Esta fase envejece más rápido que las otras: versiones, extensiones y menús de
IDE cambian. Escríbela para que lo esencial —qué hace cada herramienta y por qué—
sobreviva aunque el menú se mueva, y marca explícitamente lo que es volátil.
```

---

## Fase 01

```markdown
## Identidad

- Fase **01 de 17** — 🔤 Sintaxis, tipos y el modelo de valores
- Archivo: `01-sintaxis-y-valores.md` · Horas: **7h**
- Época: **Go 1.13, stdlib pura**
- Depende de: Fase 00 · Habilita: Fase 02
- Proyecto: **OpsReport nace**
- Mini proyectos: `movement-parser`, `text-toolkit`, `log-grep`

## Alcance

- **Propósito:** darle al lector todo lo que necesita para leer código Go, dicho
  en función de lo que ya sabe — y dejarle claro dónde el modelo de valores de Go
  difiere del de Java.
- **Entra:** declaraciones y `:=`; tipos con nombre y por qué no son alias;
  valores cero y la ausencia de `null`; conversiones explícitas y por qué no hay
  promoción implícita; `if` con inicializador; `switch` sin `break` y con
  `fallthrough`; `for` como único bucle; `defer` presentado aquí y profundizado
  en la Fase 03; **arrays, slices y mapas con el modelo de memoria delante** —la
  cabecera de tres campos, `append` y el respaldo compartido, `copy`, el subslice
  que retiene un array grande, el mapa nulo, el orden de iteración aleatorio—;
  strings, bytes y runas; punteros sin aritmética; y el compilador que falla por
  un import sin usar.
- **NO entra:** structs y métodos → Fase 02. Errores más allá de `if err != nil`
  → Fase 03. Genéricos → Fase 08 (Go 1.18) 🕰️.
- **OpsReport:** el tipo `WorkItem` como struct simple, sus constantes de estado y
  tipo, la validación y el cálculo de prioridad efectiva. Todo en un paquete y en
  memoria.
- **📐 Mediciones:** B-02 (`strings.Builder` frente a `+=` y `fmt.Sprintf`), B-03
  (`regexp` compilado fuera del bucle), B-04 (slice pre-dimensionado).
- **🪞 El instinto obligado:** "un slice es un `ArrayList`". Es un `ArrayList` que
  a veces comparte el arreglo interno con otro, y esa diferencia produce bugs
  silenciosos. Demuéstralo con código que sorprenda.
- **Diccionario:** `ArrayList`, `HashMap`, `String` y su pool, `char` frente a
  runa, `StringBuilder`, autoboxing, `Optional`, `var` de Java 10, `final`,
  `Pattern`/`Matcher`.
- **Ejercicios:** 24.
```

---

## Fase 02

```markdown
## Identidad

- Fase **02 de 17** — 🧱 Structs, métodos, interfaces y composición
- Archivo: `02-structs-interfaces-composicion.md` · Horas: **7h**
- Época: **Go 1.13, stdlib pura**
- Depende de: Fase 01 · Habilita: Fase 03
- Proyectos: **OpsReport** (dominio y servicio) · **EventRelay nace**
- Mini proyectos: `shapes`, `store-registry`, `notifier`

## Alcance

- **Propósito:** la fase que decide si el lector va a escribir Go o Java con
  llaves distintas. Es la más importante del Bloque A para el objetivo del curso.
- **Entra:** structs, campos exportados y etiquetas; métodos con receptor por
  valor o por puntero y cuándo importa de verdad; el conjunto de métodos de un
  tipo y por qué `*T` implementa más que `T`; **embedding, que no es herencia** —
  demostrado con un método que no se sobrescribe como el lector espera—;
  **interfaces implícitas**; la interfaz vacía y sus aserciones de tipo; `Stringer`
  y `error` como las dos interfaces que todo el mundo implementa; constructores
  por convención `New`; y la inyección de dependencias sin contenedor: una `main`
  que cablea y se lee entera.
- **El punto central, que se repite todo el curso:** la interfaz se declara donde
  se **consume**. Eso invierte la dirección de dependencias que el lector trae de
  Spring y es lo que permite que las interfaces sean diminutas.
- **NO entra:** manejo serio de errores → Fase 03. Tests → Fase 04. Genéricos →
  Fase 08 🕰️ (y con ellos la advertencia de no generalizar antes de tiempo).
- **OpsReport:** paquete `workitem` con dominio y máquina de estados; paquete
  `opsreport` con el servicio, que **declara** `Store`, `Clock` e `IDGenerator`;
  `memstore` que las implementa sin conocerlas.
- **EventRelay nace:** `Endpoint`, `Event`, `Delivery` y su máquina de estados,
  más rica que la de OpsReport.
- **⚰️ La autopsia obligada, y es la primera del curso:** `WorkItemServiceImpl`
  con su interfaz de nueve métodos y su fábrica, frente a un struct de cuarenta
  líneas. Cuenta archivos, líneas, indirecciones y lo que cuesta seguir una
  llamada de punta a punta.
- **📐 Medición:** B-05, coste de una llamada a través de interfaz frente a
  llamada directa — con el veredicto de que no es motivo para evitar interfaces.
- **Diccionario:** `class`, `extends`, `implements`, `abstract`, `@Override`,
  `super`, clase interna, `record`, `sealed`, Lombok, `@Service`, `@Component`,
  `@Autowired`, `@Qualifier`, `ApplicationContext`.
- **Ejercicios:** 26, con **tres** de detección de ☕.
```

---

## Fase 03

```markdown
## Identidad

- Fase **03 de 17** — 🧯 Errores, paquetes, I/O y JSON
- Archivo: `03-errores-paquetes-io.md` · Horas: **7h**
- Época: **Go 1.13, stdlib pura**
- Depende de: Fase 02 · Habilita: Fase 04
- Proyectos: OpsReport y EventRelay (errores, configuración, serialización)
- Mini proyectos: `error-chain`, `config-loader`, `json-codec`

## Alcance

- **Propósito:** que el lector deje de vivir el `if err != nil` como un castigo y
  empiece a verlo como información en la firma.
- **Entra:** `error` como interfaz; errores centinela y cuándo; tipos de error
  con `Unwrap`; **el envoltorio con `%w`, que es LA novedad de Go 1.13**, con
  `errors.Is` y `errors.As`; cuándo envolver y cuándo no; `defer` con su
  semántica exacta —evaluación de argumentos, orden LIFO, el `defer` dentro del
  bucle que agota descriptores—; `panic` y `recover` con su lugar estrecho y por
  qué `recover` no es `catch`; paquetes, visibilidad por mayúscula, `internal/`,
  ciclos de importación; `io.Reader` e `io.Writer` como las dos interfaces más
  importantes del ecosistema, con `io.Copy`, `bufio` y los envoltorios;
  `encoding/json` con etiquetas, `omitempty`, campos no exportados, el
  `interface{}` que devuelve `float64`, `json.RawMessage`, y el streaming con
  `Decoder`/`Encoder`.
- **Lo que hay que decir con todas las letras:** dónde Java gana —las excepciones
  comprobadas obligan a decidir, y el `_` de Go permite ignorar un error en
  silencio— y dónde gana Go —el flujo de error está en la firma y en el cuerpo,
  no en un `throws` que nadie lee.
- **NO entra:** `errors.Join` → Fase 08 (Go 1.20) 🕰️. Logging estructurado →
  Fase 14; aquí el log es `log` de la stdlib y se dice que es provisional.
- **💸 Deuda:** el logger es `log.Printf` con formato libre. Se paga en la Fase 14.
- **📐 Medición:** B-06, decodificación completa frente a streaming, con un
  documento grande.
- **Diccionario:** `Exception` comprobada y no comprobada, `try/catch/finally`,
  `try-with-resources`, `throws`, `getCause`, `addSuppressed`, `finally` frente a
  `defer`, `@ControllerAdvice`, `package-private`, `module-info.java`, Jackson y
  sus anotaciones, `InputStream`/`OutputStream`.
- **Ejercicios:** 24.
```

---

## Fase 04

```markdown
## Identidad

- Fase **04 de 17** — 🧪 Testing idiomático, dobles y cobertura
- Archivo: `04-testing-dobles-cobertura.md` · Horas: **8h**
- Época: **Go 1.13, stdlib pura**
- Depende de: Fase 03 · Habilita: Fase 05
- Proyectos: OpsReport y EventRelay (suites unitarias completas)
- Mini proyectos: `validator-tests`, `fake-clock`, `golden-report`

## Alcance

- **Propósito:** dejar instalado el régimen de pruebas del curso, que a partir de
  aquí es una condición y no una fase.
- **Entra:** el paquete `testing` completo; **tests de tabla** con subtests
  `t.Run`; `t.Helper`, `t.Cleanup` —el `@After` de JUnit hecho bien—,
  `t.Parallel` y su trampa de la variable capturada; `TestMain`; golden files con
  bandera `-update`; el detector de carreras presentado aquí aunque se explote en
  la Fase 06; y la cobertura con `-coverprofile`, `-covermode=atomic`, el informe
  HTML y el umbral del curso.
- **Dobles, con el orden del curso y su justificación:** función → fake → **y
  aquí nos detenemos a propósito**. Un `FakeClock` y un `FakeStore` de veinte
  líneas cubren todo lo que hay hasta ahora, y el lector tiene que ver que no
  necesitó Mockito. El generador llega en la Fase 10 y allí se explica por qué
  tarda tanto.
- **NO entra:** mocks generados → Fase 10. Tests HTTP → Fase 05. Tests de
  integración con contenedores → Fase 09. Fuzzing → Fase 08 (Go 1.18) 🕰️.
- **La advertencia que se escribe una vez y se sostiene:** la cobertura mide
  líneas ejecutadas, no comportamiento verificado. Un test que llama a todo y no
  afirma nada da 100% y no vale nada. Demuéstralo con un ejemplo.
- **🪞 El instinto obligado:** "hay que mockear el almacén". Muestra el fake al
  lado de la configuración del mock, cuenta las líneas de cada uno, y señala que
  el fake además prueba comportamiento en vez de interacción.
- **Diccionario:** JUnit 5, `@Test`, `@BeforeEach`, `@AfterEach`,
  `@ParameterizedTest` con `@CsvSource` y `@MethodSource`, `@Nested`,
  `assertThat` de AssertJ, Mockito, `@Mock` y `@InjectMocks`, JaCoCo, Surefire.
- **Ejercicios:** 26, y al menos ocho de diagnóstico: tests que pasan y no
  deberían.
```

---

## Fase 05

```markdown
## Identidad

- Fase **05 de 17** — 🌐 HTTP y REST con la stdlib
- Archivo: `05-http-rest-stdlib.md` · Horas: **8h**
- Época: **Go 1.13, stdlib pura**
- Depende de: Fase 04 · Habilita: Fase 06
- Proyectos: OpsReport y EventRelay (APIs REST en memoria) · nace `fakeconsumer`
- Mini proyectos: `tiny-router`, `middleware-chain`, `httptest-lab`

## Alcance

- **Propósito:** que el lector escriba el enrutado a mano una vez y deje de
  tenerle respeto reverencial a `@GetMapping`.
- **Entra:** `net/http` de arriba abajo; `http.Handler` y `http.HandlerFunc`;
  `ServeMux` de 1.13 con sus límites reales —sin método, sin variables de ruta— y
  el enrutado propio que hay que escribir por encima; middleware como composición
  de handlers, con la cadena de registro, identificador de petición,
  recuperación de panic y autenticación; decodificación y codificación de JSON en
  el borde, con límite de tamaño del cuerpo; códigos de estado con criterio; la
  traducción de errores de dominio a HTTP **en un solo sitio**; `httptest.NewRecorder`
  y `httptest.NewServer`; y los tiempos de espera del servidor —`ReadTimeout`,
  `ReadHeaderTimeout`, `WriteTimeout`, `IdleTimeout`—, porque el `http.Server{}`
  por defecto no tiene ninguno y eso es un incidente esperando.
- **NO entra:** `ServeMux` con método y patrón → Fase 08 (Go 1.22) 🕰️, y el
  `tiny-router` de aquí se guarda para compararlos allí. Cliente HTTP → Fase 10.
  Autenticación real → fuera del curso, el servicio vive tras un gateway.
- **OpsReport y EventRelay:** sus APIs completas en memoria, con suite HTTP.
- **`fakeconsumer` nace** con `/ok`, `/slow` y `/fail/{code}`.
- **💸 Deuda:** el enrutado a mano tiene un `switch` que crecerá feo. **Se paga en
  la Fase 08**, y la comparación de las dos versiones es la mejor clase de diseño
  de API del curso — déjalo dicho aquí.
- **Diccionario:** el más largo del curso — `@RestController`, `@RequestMapping`,
  `@GetMapping`, `@PathVariable`, `@RequestParam`, `@RequestBody`,
  `@ResponseStatus`, `ResponseEntity`, `@ControllerAdvice`, `Filter`,
  `HandlerInterceptor`, `WebMvcConfigurer`, `DispatcherServlet`, Tomcat embebido.
- **Ejercicios:** 26.
```

---

## Fase 06

```markdown
## Identidad

- Fase **06 de 17** — ⚙️ Concurrencia ⭐
- Archivo: `06-concurrencia.md` · Horas: **9h**
- Época: **Go 1.13, stdlib pura**
- Depende de: Fase 05 · Habilita: Fase 07
- Proyectos: OpsReport (motor de jobs) · EventRelay (cola de entregas)
- Mini proyectos: `race-counter`, `deadlock-lab`, `leak-lab`, `unbounded-queue`

## Alcance

- **Propósito:** la fase estrella del Bloque A y la razón por la que mucha gente
  llega a Go. Al terminar, el lector diseña concurrencia acotada por reflejo.
- **Entra:** el planificador y el modelo M:N; por qué una goroutine cuesta
  kilobytes; canales con y sin búfer; `select` con `default` y con `time.After`;
  el cierre de canales y **quién tiene derecho a cerrarlos**; `sync.WaitGroup`,
  `Mutex`, `RWMutex`, `Once`, `sync/atomic`; el modelo de memoria de Go leído de
  verdad; y los patrones **construidos, no copiados**: worker pool acotado,
  fan-out/fan-in, pipeline, semáforo con canal con búfer.
- **Los laboratorios de desastre, que son la mitad del valor de la fase:** la
  carrera que `-race` encuentra y el ojo no; cuatro formas de provocar un
  deadlock, incluido el `fatal error: all goroutines are asleep`; la goroutine
  que nadie recoge; y la cola sin límite que convierte un pico de tráfico en un
  OOM.
- **NO entra:** `context` → Fase 07, y dilo explícitamente porque el lector lo va
  a echar de menos a los veinte minutos. `errgroup` y `semaphore.Weighted` →
  Fase 08 🕰️ (son `golang.org/x/sync`, fuera del régimen de stdlib pura).
- **OpsReport:** cola con búfer acotado, N workers, estados avanzando, `WaitGroup`
  para el apagado, registro de `JobExecution`. **EventRelay:** cola de entregas
  con el contador de intentos que **tiene una carrera a propósito** en su primera
  versión.
- **💸 Deudas:** la cola de OpsReport vive solo en memoria (se paga en la Fase
  09); el planificador de reintentos de EventRelay usa un `time.Timer` por entrega
  (se paga en la Fase 09).
- **📐 Mediciones:** B-07 (goroutine frente a hilo de la JVM), B-08 (canal con
  búfer frente a mutex para un contador), B-09 (pool acotado frente a goroutine
  por tarea bajo pico), B-10 (cuánto cuesta `-race`).
- **Diccionario, denso:** `Thread`, `Runnable`, `ExecutorService`,
  `ThreadPoolExecutor` y su política de rechazo, `CompletableFuture`,
  `BlockingQueue`, `synchronized`, `ReentrantLock`, `AtomicInteger`,
  `CountDownLatch`, `Semaphore`, `ForkJoinPool`, `parallelStream`, y **las hebras
  virtuales de Java 21**, que son el paralelo más cercano a una goroutine y
  merecen su párrafo honesto.
- **⚖️ El veredicto tiene que ser honesto:** hay problemas donde un
  `CompletableFuture` encadenado se lee mejor que tres canales. Dilo.
- **Ejercicios:** 30, con **doce** de diagnóstico.
```

---

## Fase 07

```markdown
## Identidad

- Fase **07 de 17** — ⏱️ Context, cancelación y ciclo de vida
- Archivo: `07-context-y-ciclo-de-vida.md` · Horas: **7h**
- Época: **Go 1.13, stdlib pura**
- Depende de: Fase 06 · Habilita: Fase 08
- Proyectos: OpsReport y EventRelay (cancelación de punta a punta, apagado)
- Mini proyectos: `cancellable-worker`, `timeout-client`, `graceful-server`,
  `leak-detector`

## Alcance

- **Propósito:** cerrar el Bloque A con los dos servicios capaces de apagarse sin
  perder trabajo ni dejar goroutines vivas.
- **Entra:** `context.Context` explicado por lo que es —un árbol de cancelación
  con fecha límite y valores de petición— y por lo que **no** es: ni
  `ThreadLocal`, ni bolsa de parámetros, ni sitio para el usuario autenticado por
  comodidad; `WithCancel`, `WithTimeout`, `WithDeadline`, `WithValue` y sus
  reglas; la propagación desde el handler HTTP hasta el fondo; `ctx.Done()` en el
  `select` de todo worker; `ctx.Err()` y la diferencia entre `Canceled` y
  `DeadlineExceeded`; señales del sistema operativo con `os/signal`; `Shutdown`
  del servidor HTTP; drenaje del pool con límite de tiempo; y **las fugas de
  goroutines**: cómo se detectan con `runtime.NumGoroutine` y el perfil
  `goroutine`, por qué casi siempre son un canal sin lector o un `context` sin
  cancelar, y el test que las caza.
- **NO entra:** `context.WithoutCancel` y `AfterFunc` → Fase 08 🕰️. `goleak` como
  librería → Fase 08; aquí la detección es a mano, que se entiende mejor.
- **OpsReport:** el `DELETE` cancela el trabajo en curso; `SIGTERM` drena la cola.
  **EventRelay:** tiempo límite por entrega, cancelación propagada, y las
  entregas en vuelo que vuelven a `pending` si no alcanzan a terminar.
- **La regla que se lleva:** toda función que hace E/S recibe `ctx` como primer
  parámetro, y ninguna estructura lo guarda dentro.
- **Diccionario:** `ThreadLocal` y `InheritableThreadLocal`, `Thread.interrupt`,
  `Future.cancel`, `@Transactional(timeout=)`, `ScopedValue` de Java 21,
  `Runtime.addShutdownHook`, `SmartLifecycle` y `@PreDestroy`, el *graceful
  shutdown* de Spring Boot.
- **Ejercicios:** 24, con **ocho** de diagnóstico de fugas y cuelgues.
```

---

## Fase 08

```markdown
## Identidad

- Fase **08 de 17** — 🚀 La migración a Go moderno ⭐
- Archivo: `08-migracion-a-go-moderno.md` · Horas: **8h**
- Época: **la frontera** — entra en 1.13 y sale en la versión vigente
- Depende de: Fase 07 · Habilita: Fase 09
- Proyectos: OpsReport y EventRelay migran, sin reescribirse
- Mini proyectos: ninguno nuevo; `tiny-router` muere aquí con dignidad

## Alcance

- **Propósito:** la fase bisagra del curso. Se migran dos servicios reales, con
  persistencia todavía en memoria pero con concurrencia y tests completos, salto
  por salto y con la suite como red.
- **Entra, por saltos:**
  - **1.14–1.16:** `os.ReadFile`/`WriteFile`, `io/fs`, **`embed`** —las
    plantillas HTML del reporte y las migraciones dejan de ser archivos sueltos—,
    y el fin de `GOPATH` como tema.
  - **1.17–1.18:** **`go.work`** y el monorepo deja de pelearse consigo mismo;
    **genéricos**, enseñados en serio y **restringidos en serio** (guía §6.4:
    escribe la versión concreta primero, generaliza con el tercer caso delante);
    **fuzzing** con `testing.F`, aplicado al parser de movimientos y al
    verificador de firmas; `golang.org/x/sync` con `errgroup` y
    `semaphore.Weighted`.
  - **1.19–1.21:** **`log/slog`** reemplazando el logger propio, con las dos
    salidas comparadas; `slices`, `maps`, `cmp`; `errors.Join`;
    `context.WithoutCancel` y `AfterFunc`; la directiva `toolchain`; `GOMEMLIMIT`.
  - **1.22–1.23:** **el `ServeMux` con método y patrón**, que jubila al
    `tiny-router` — y poner las dos versiones lado a lado es la mejor clase de
    diseño de API del curso; **el cambio de semántica de la variable de bucle**,
    con el ejercicio de buscar en las siete fases anteriores dónde habría
    cambiado el comportamiento; `range` sobre enteros y sobre funciones;
    iteradores.
  - **Hasta la versión vigente:** lo que aporte, sin modernización cosmética.
- **El entregable diferencial:** **la lista de rechazos con su motivo.** Qué
  feature moderna se evaluó y se decidió no adoptar, y por qué. Vale tanto como
  la lista de adopciones.
- **💸 Se pagan aquí:** el enrutado a mano de la Fase 05 y el logger de la Fase 03.
  Di entre qué tags se lee la factura (`git diff fase-05 fase-08 -- ...`).
- **📐 Mediciones:** B-11 (el mismo servicio en 1.13 y moderno: tamaño del
  binario, arranque, memoria), B-12 (`ServeMux` moderno frente al enrutado a
  mano).
- **La regla que se lleva:** modernizar no es sustituir cada API vieja por la
  nueva; es preguntarse una por una si el cambio hace el código más simple de
  mantener.
- **Diccionario:** niveles de lenguaje de Java y `--release`, `var`, records,
  `sealed`, pattern matching de `switch`, el módulo `java.base`, Jakarta EE y el
  renombre de paquetes, la migración de Spring Boot 2 a 3.
- **Ejercicios:** 26, con al menos seis sobre **qué NO migrar**.
```

---

## Fase 09

```markdown
## Identidad

- Fase **09 de 17** — 🗄️ SQL: PostgreSQL y SQLite
- Archivo: `09-sql-postgres-sqlite.md` · Horas: **9h**
- Época: **Go moderno**
- Depende de: Fase 08 · Habilita: Fase 10
- Proyectos: **OpsReport** persiste · **EventRelay** mueve su cola a la base ·
  **ClearingHouse nace** (`storeagent` con SQLite)
- Mini proyectos: `pool-lab`, `tx-lab`, `cursor-vs-offset`

## Alcance

- **Propósito:** persistencia real en los dos modelos que un backend Go usa a
  diario, y el debate del ORM resuelto con argumentos en vez de dogma.
- **Entra:** `database/sql` explicado por lo que es —**un pool, no una
  conexión**—, con `SetMaxOpenConns`, `SetMaxIdleConns`, `SetConnMaxLifetime` y
  el incidente clásico de las filas sin cerrar que agotan el pool; consultas con
  `ctx`; `Scan` y los tipos nulos; `pgx` en modo nativo frente a `database/sql`;
  transacciones con `defer tx.Rollback()` como patrón y niveles de aislamiento;
  migraciones versionadas con `goose`; paginación **por cursor** frente a
  `OFFSET`; `SELECT ... FOR UPDATE SKIP LOCKED` para la cola de EventRelay —la
  joya de la fase—; **SQLite** con `modernc.org/sqlite` sin cgo, WAL, y las
  diferencias reales con PostgreSQL que muerden; y los **tests de integración**
  con `testcontainers-go`, build tags y `make test-integration`.
- **El debate del ORM, con los tres competidores medidos:** SQL a mano, `sqlc` y
  `GORM`, sobre la misma consulta. Con el diccionario completo de JPA y el
  veredicto: **en Go la propagación transaccional es un parámetro, no una
  anotación**, y eso se paga en verbosidad y se cobra en que nunca te preguntas
  si esta llamada está dentro de una transacción.
- **La zona horaria por tienda** entra aquí, con ClearingHouse: el cierre del día
  4 en Bogotá y en Ciudad de México no cubre el mismo intervalo UTC, y es el bug
  más caro que ese servicio puede tener.
- **NO entra:** MongoDB → Fase 11. El cierre por lotes → Fase 13.
- **💸 Se pagan aquí:** la cola en memoria de OpsReport y el planificador de
  reintentos de EventRelay, los dos declarados en la Fase 06.
- **📐 Mediciones:** B-13, B-14, B-15, B-16.
- **Diccionario:** JDBC, `DataSource`, HikariCP, `PreparedStatement`,
  `ResultSet`, `@Transactional` y su propagación, `EntityManager`, JPA, Hibernate,
  el problema N+1, el caché de primer nivel, el *lazy loading* y su
  `LazyInitializationException`, Spring Data y las consultas derivadas,
  `Pageable`, Flyway y Liquibase.
- **Ejercicios:** 30.
```

---

## Fase 10

```markdown
## Identidad

- Fase **10 de 17** — 🔌 Clientes HTTP, APIs externas y dobles generados
- Archivo: `10-clientes-http-y-apis-externas.md` · Horas: **8h**
- Época: **Go moderno**
- Depende de: Fase 09 · Habilita: Fase 11
- Proyectos: **EventRelay** (cliente de entrega en serio) · **AtlasSync nace** ·
  **ClearingHouse** (`storeagent sync`)
- Mini proyectos: `client-timeouts`, `backoff-lab`, `recorded-responses`

## Alcance

- **Propósito:** salir al mundo exterior sin que el mundo exterior te tumbe — y
  aprender a probarlo sin depender de él.
- **Entra:** `http.Client` bien configurado, que es un tema en sí mismo: el
  cliente por defecto **no tiene tiempo límite**, el `Transport` se reutiliza o se
  agotan los puertos efímeros, el cuerpo se cierra **siempre** y se drena antes de
  cerrarlo si quieres reutilizar la conexión; `MaxIdleConnsPerHost` y por qué su
  valor por defecto sorprende; reintentos con retroceso exponencial y *jitter*
  escritos a mano; clasificación de errores recuperables frente a permanentes
  como **función pura probada con tabla**; `429` con `Retry-After`;
  `singleflight` contra el rebaño atronador; `golang.org/x/time/rate`; y un
  cortacircuitos mínimo escrito, no importado.
- **AtlasSync nace** consumiendo **REST Countries** y **Frankfurter**, las dos sin
  clave de API. Y con él llega el tema que el curso venía aplazando: **cómo se
  prueba un servicio que depende de internet.** Los cinco niveles de
  `proyecto-03-atlassync.md` §8 se montan aquí, completos, incluida la regla de
  que **la suite entera corre sin red** y solo un test 🔥 excluido de CI golpea la
  API real.
- **Y aquí entra por fin `go.uber.org/mock`**, con su justificación tardía:
  verificar que el cliente reintentó exactamente tres veces y no cuatro es
  verificación de interacción, y para eso el fake se queda corto. Explica por qué
  llega en la Fase 10 y no en la 04.
- **NO entra:** MongoDB → Fase 11. Caché → Fase 12.
- **⚠️ Advertencia obligatoria en la fase:** estas APIs públicas pueden cambiar o
  desaparecer; por eso las respuestas viven grabadas en `testdata/`.
- **Diccionario:** `RestTemplate`, `WebClient`, `@FeignClient`, `@Retryable` y
  `@Recover`, Resilience4j, `@MockBean`, `@RestClientTest`, WireMock,
  `HttpClient` de Java 11, `ClientHttpRequestInterceptor`.
- **Ejercicios:** 28.
```

---

## Fase 11

```markdown
## Identidad

- Fase **11 de 17** — 🍃 MongoDB y modelado documental
- Archivo: `11-mongodb-y-modelado-documental.md` · Horas: **7h**
- Época: **Go moderno**
- Depende de: Fase 10 · Habilita: Fase 12
- Proyecto: **AtlasSync** (persistencia)
- Mini proyectos: `bson-lab`, `aggregation-lab`

## Alcance

- **Propósito:** modelar en documentos con criterio, y saber decir que no.
- **Entra:** por qué AtlasSync usa Mongo y OpsReport no —con el contraejemplo
  delante: un país de REST Countries trae nombres en nueve idiomas, monedas
  anidadas y campos que unos tienen y otros no; normalizarlo a diez tablas para
  volver a unirlo en cada lectura es trabajo sin destinatario—; el driver
  oficial; BSON y sus etiquetas; `Decode` frente a `All` y por qué importa con
  colecciones grandes; índices, incluidos el de texto y el TTL; el *framework* de
  agregación con el paralelo a `GROUP BY`; actualizaciones atómicas con
  operadores; `upsert`; transacciones multi-documento **con su advertencia de
  coste**; y el modelado que se transfiere: incrustar frente a referenciar, el
  límite de dieciséis megas, los patrones de atributo y de cubo, y por qué
  "esquemaless" no significa "sin esquema" sino **"esquema en el código"**.
- **El campo `Raw`** que guarda el documento de origen intacto: cuesta espacio,
  salva el día que alguien pregunta por un campo no modelado, y tiene un punto en
  el que se vuelve un vertedero. Di también eso.
- **NO entra:** caché → Fase 12. Ingesta programada → Fase 13.
- **⚖️ El veredicto obligatorio:** los tres casos en que Mongo es la respuesta
  equivocada, y por qué el primero de ellos es *"porque el equipo ya lo tenía
  levantado"*.
- **Diccionario:** Spring Data MongoDB, `MongoTemplate`, `@Document`, `@Indexed`,
  `@Field`, `MongoRepository` y sus consultas derivadas, `Criteria`,
  `AggregationOperation`, `@Transactional` sobre Mongo, y el contraste con JPA de
  la Fase 09.
- **Ejercicios:** 24, con al menos cuatro de **modelado** —dado un caso, decidir
  documento o tabla y defenderlo.
```

---

## Fase 12

```markdown
## Identidad

- Fase **12 de 17** — ⚡ Caché con Valkey
- Archivo: `12-cache-con-valkey.md` · Horas: **6h**
- Época: **Go moderno**
- Depende de: Fase 11 · Habilita: Fase 13
- Proyectos: **AtlasSync** (caché de lectura) · **EventRelay** (límite de tasa,
  idempotencia distribuida)
- Mini proyectos: `cache-aside-lab`, `stampede-lab`, `ratelimit-lab`

## Alcance

- **Propósito:** cachear con invalidación pensada, que es el problema difícil de
  verdad, y descubrir de paso los usos de Valkey que no son caché.
- **Entra:** Valkey como lo que es —el fork de Redis bajo la Linux Foundation— y
  `valkey-go`, con `go-redis` como alternativa comentada; *cache-aside* con su
  condición de carrera; *write-through* y *write-behind* con sus riesgos; TTL con
  *jitter* y por qué sin jitter todo expira a la vez; la **estampida** resuelta
  con `singleflight` local **más** bloqueo distribuido, que no es lo mismo;
  invalidación por clave y por etiqueta; y el **diseño de las claves**, que es el
  80% de la calidad de una caché y casi nunca se discute.
- **Y lo que no es caché:** limitación de tasa por socio con ventana deslizante o
  *token bucket*; bloqueos distribuidos **con su advertencia grande** sobre
  corrección —un bloqueo con TTL no garantiza exclusión mutua y hay que decirlo—;
  colas ligeras; `SET NX` con TTL para idempotencia.
- **El experimento que cierra la fase:** medir cuánto gana realmente la caché
  aquí. A veces la respuesta es *"poco, y acabas de añadir un servicio al
  `compose.yaml`"*, y esa es una lección mejor que la contraria.
- **NO entra:** Valkey como base de datos primaria, Streams, Pub/Sub como bus de
  eventos — se nombran en el ⚖️ veredicto y se quedan fuera.
- **📐 Mediciones:** B-17 (tasa de acierto y latencia con y sin caché), B-18
  (bytes precodificados frente a codificar por petición).
- **⚖️ El veredicto:** un mapa en memoria con TTL resuelve más casos de los que la
  gente cree, y no necesita un servicio más.
- **Diccionario:** `@Cacheable`, `@CacheEvict`, `@CachePut`, `CacheManager`,
  Caffeine, `RedisTemplate`, `StringRedisTemplate`, Spring Session, Redisson y
  sus locks, Bucket4j.
- **Ejercicios:** 22.
```

---

## Fase 13

```markdown
## Identidad

- Fase **13 de 17** — 📦 Lotes, scheduling y trabajo asíncrono
- Archivo: `13-lotes-scheduling-y-asincronia.md` · Horas: **8h**
- Época: **Go moderno**
- Depende de: Fase 12 · Habilita: Fase 14
- Proyectos: **ClearingHouse** (el cierre nocturno) · **OpsReport** (reportes en
  streaming y outbox) · **EventRelay** (consume el outbox) · **AtlasSync**
  (ingesta programada)
- Mini proyectos: `chunked-stream`, `checkpoint-lab`, `outbox-lab`

## Alcance

- **Propósito:** el territorio donde Java es fuerte, tratado con respeto y
  medido. Es la fase donde los cuatro servicios se conectan entre sí.
- **Entra:** procesamiento por lotes con cursores y *streaming* —`sql.Rows`
  recorrido de verdad, nunca un `[]T` de un millón—; fragmentación y **punto de
  control en la misma transacción**, que es lo que hace el lote reanudable;
  idempotencia del lote; reanudación tras caída; informe de ejecución y progreso
  consultable mientras corre; scheduling con `time.Ticker` frente a
  `robfig/cron`, y el problema que Spring resuelve con ShedLock resuelto aquí con
  un bloqueo en base de datos; el **patrón outbox** implementado completo, que es
  donde OpsReport y EventRelay se encuentran; `errgroup` con límite;
  `semaphore.Weighted`; y el diseño de contrapresión.
- **El 🧨 más memorable del curso va aquí:** escribe primero la versión ingenua
  del cierre que carga todo en memoria, mídela, y mira subir la memoria residente
  hasta que el proceso muere. Después la versión con fragmentos.
- **La comparación con Spring Batch, con el código de los dos delante** —el
  gemelo Java de `reference/clearinghouse-spring/` existe para esto—. Y la parte
  honesta, que es el corazón del ⚖️ veredicto: **Spring Batch resuelve
  reanudación, reintento por ítem, particionado y métricas de job que aquí hay
  que escribir.** Si tu proceso por lotes es complejo de verdad, eso es un
  argumento real a favor de Java, y así se dice.
- **Las cinco propiedades que se prueban:** reanudable, idempotente, acotado en
  memoria, observable y cancelable. Cada una con su test.
- **NO entra:** Kafka, RabbitMQ ni NATS. Se nombran en el ⚖️ veredicto con el
  punto exacto en que la cola en base de datos deja de bastar.
- **📐 Mediciones:** B-19 (reporte de 500.000 filas: streaming frente a carga
  completa), B-20 (tamaño de fragmento frente a tiempo total del cierre).
- **Diccionario:** Spring Batch entero —`Job`, `Step`, `ItemReader`,
  `ItemProcessor`, `ItemWriter`, `JobRepository`, `ExecutionContext`,
  `@StepScope`, chunks, particionado, `JobLauncher`—, `@Scheduled`, `@Async`,
  `TaskExecutor`, ShedLock, Quartz, `@TransactionalEventListener`.
- **Ejercicios:** 28.
```

---

## Fase 14

```markdown
## Identidad

- Fase **14 de 17** — 👁️ Observabilidad, configuración y hardening
- Archivo: `14-observabilidad-y-hardening.md` · Horas: **7h**
- Época: **Go moderno**
- Depende de: Fase 13 · Habilita: Fase 15
- Proyectos: **los cuatro**
- Mini proyectos: `slog-lab`, `metrics-lab`, `distroless-lab`

## Alcance

- **Propósito:** dejar los cuatro servicios en estado de producción: se pueden
  configurar, observar, apagar y desplegar sin sorpresas.
- **Entra:** `log/slog` bien usado —niveles, atributos, grupos, manejadores, el
  `Logger` **inyectado** en vez del global, correlación con el identificador de
  petición a través del `context`, y qué **no** se registra nunca—; métricas con
  `prometheus/client_golang`: los cuatro tipos, las métricas RED, **la
  cardinalidad de etiquetas como la forma más común de tumbar un Prometheus**, y
  el `/metrics`; trazas con OpenTelemetry, propagación entre servicios e
  instrumentación de HTTP y base de datos; health y readiness **con la diferencia
  que importa** —y el `/ready` que consulta la base en cada petición como ataque
  de denegación de servicio que te haces a ti mismo—; configuración
  doce-factores con validación al arrancar y fallo rápido; secretos; imagen
  multi-etapa `distroless` o `scratch` con usuario sin privilegios; y el
  endurecimiento: límite de tamaño del cuerpo, tiempos de espera en los cinco
  sitios donde hacen falta, recuperación de panic en el borde, cabeceras, CORS,
  **validación de URL contra SSRF** en EventRelay, **firma HMAC con timestamp** y
  su ataque de repetición, comparación en tiempo constante, y `govulncheck`.
- **💸 Se pagan aquí:** el `Makefile` sin validación (Fase 00) y el logger
  provisional (Fase 03).
- **🧨 obligatorio:** registra un secreto a propósito y mira qué queda en la
  salida, en el log agregado y en la traza.
- **📐 Medición:** B-21, imagen de contenedor Go distroless frente a Spring Boot.
- **Diccionario:** Actuator y sus endpoints, Micrometer, Logback y MDC, Log4j2,
  `application.yml` y perfiles, `@ConfigurationProperties`, `@Value`,
  `spring.config.import`, Spring Cloud Config, `@Validated`, Spring Security
  headers, Jib y Buildpacks.
- **Ejercicios:** 26.
```

---

## Fase 15

```markdown
## Identidad

- Fase **15 de 17** — 📈 Rendimiento, profiling y benchmarking
- Archivo: `15-rendimiento-y-profiling.md` · Horas: **7h**
- Época: **Go moderno**
- Depende de: Fase 14 · Habilita: Fase 16
- Proyectos: **los cuatro** (perfilado de sus rutas calientes)
- Mini proyectos: `benchstat-lab`, `escape-lab`, `pool-vs-alloc`

## Alcance

- **Propósito:** dejar al lector midiendo en vez de suponiendo, y con el banco de
  pruebas listo para el duelo de la fase siguiente.
- **Entra:** benchmarks con `testing.B` hechos bien —`b.ResetTimer`,
  `b.ReportAllocs`, `b.RunParallel`, `b.Loop` si la versión lo trae— y
  **`benchstat`**, porque una sola corrida no dice nada y la diferencia entre
  ruido y mejora es estadística; `pprof` completo —CPU, heap, goroutine, mutex,
  block—, el servidor de depuración y cómo exponerlo sin regalarlo, la lectura de
  un gráfico de llamas, y el `trace` para ver el planificador de verdad; **escape
  analysis** con `-gcflags=-m`; el coste de las asignaciones; `sync.Pool` con su
  advertencia; el pre-dimensionado de slices y mapas; la interfaz que fuerza una
  asignación; y las pruebas de carga con `k6` o `vegeta` sobre los cuatro
  servicios.
- **El recolector de basura de Go frente al de la JVM:** dos filosofías distintas
  —latencia baja y predecible frente a rendimiento máximo con pausas mayores— y
  las perillas que existen, `GOGC` y `GOMEMLIMIT`, comparadas con las cuarenta de
  la JVM. **Sin ganador: con criterio.**
- **La regla que se lleva y que hay que decir dos veces:** optimizar sin medir es
  cambiar código al azar. Y la que la acompaña: **publica también la optimización
  que no funcionó.** Escribe una de verdad en esta fase.
- **NO entra:** el duelo contra Spring Boot → Fase 16. Aquí se prepara el banco.
- **📐 Medición:** B-22 (`GOGC` y `GOMEMLIMIT` sobre pausas y memoria), B-23
  (entregas por segundo de EventRelay contra `fakeconsumer`).
- **Diccionario:** JMH y sus modos, JFR, VisualVM, async-profiler, `-Xmx`/`-Xms`,
  G1 frente a ZGC frente a Shenandoah, JIT y calentamiento, `-XX:+PrintGC`,
  Micrometer timers, Gatling y JMeter.
- **Ejercicios:** 26, con al menos seis de "mide antes de creerme".
```

---

## Fase 16

```markdown
## Identidad

- Fase **16 de 17** — ⚖️ Go frente a Spring Boot: el duelo medido ⭐
- Archivo: `16-go-frente-a-spring-boot.md` · Horas: **8h**
- Época: **Go moderno**
- Depende de: Fase 15 · Habilita: Fase 17
- Proyecto: **ClearingHouse**, en sus dos implementaciones
- Mini proyectos: ninguno; el banco de pruebas es el laboratorio

## Alcance

- **Propósito:** la fase por la que existe el curso. Responder con números la
  pregunta que el lector va a llevar a su arquitecto.
- **El montaje:** `reference/clearinghouse-spring/` contiene la versión Spring
  Boot 3 —**el mismo esquema, las mismas migraciones, los mismos endpoints, el
  mismo cierre**— y se entrega hecha: el lector ya sabe escribirla. Tres reglas
  que la mantienen honesta: mismo esquema, escrita como la escribiría un equipo
  Java competente, y no se enseña a escribirla.
- **Qué se mide, con la misma máquina y el mismo banco:** arranque en frío hasta
  la primera petición servida; memoria residente en reposo y bajo carga; latencia
  p50/p95/p99 y rendimiento sostenido; CPU por petición; el cierre de un millón
  de movimientos extremo a extremo; tamaño de imagen y tiempo de compilación
  desde limpio; comportamiento bajo un pico de diez veces el tráfico; y **la JVM
  en tres configuraciones: por defecto, ajustada y `native-image` con GraalVM** —
  porque comparar Go contra una JVM sin ajustar es hacer trampa.
- **Y lo que no sale en un gráfico y decide proyectos igual:** líneas de código,
  dependencias de tercero, tiempo hasta el primer endpoint funcionando, madurez
  del ecosistema por área, y facilidad de contratar.
- **🔥 Sección opcional:** gRPC en los dos stacks, que es la pregunta que siempre
  aparece cuando alguien dice "microservicios".
- **📐 Medición:** B-24, la entrada más grande de `BENCHMARKS.md`, con todas sus
  condiciones y su sección "qué NO demuestra".
- **⚖️ El veredicto honesto es el entregable de la fase**, y **tiene que doler un
  poco en las dos direcciones.** Si el resultado es "Go gana en todo", la fase
  está mal escrita. Los casos donde Go gana claro: arranque, huella, contenedores,
  servicios de red concurrentes, herramientas de línea de comandos, coste por
  instancia al escalar. Los casos donde **quedarse en Spring Boot es la decisión
  correcta**: transaccionalidad compleja, lotes con reanudación fina, equipos
  grandes con la plataforma ya montada, ecosistemas donde la librería que
  necesitas solo existe en Java, y —el que más proyectos decide— cuando el
  problema no era el lenguaje.
- **Advertencia de método, que va escrita en la fase:** estos números son de una
  máquina, una carga y una versión. Enseñan a medir; no son una tabla para citar
  en una reunión sin repetir el experimento.
- **Ejercicios:** 30, la mayoría de medición y argumentación. Al menos tres de la
  forma "defiende la decisión contraria a la tuya con datos".
```

---

## Fase 17

```markdown
## Identidad

- Fase **17 de 17** — 🏁 Capstone: la plataforma completa y el veredicto
- Archivo: `17-capstone.md` · Horas: **5h**
- Época: **Go moderno**
- Depende de: Fase 16 · Habilita: ninguna
- Proyectos: **los cuatro**, funcionando juntos
- Mini proyectos: ninguno

## Alcance

- **Propósito:** cerrar la plataforma como un sistema coherente, no como cuatro
  demos que comparten carpeta.
- **Entra:** el `compose.yaml` completo levantando los cuatro servicios más
  PostgreSQL, MongoDB, Valkey y el `fakeconsumer`; el **flujo integrado** que los
  atraviesa —una tienda sincroniza movimientos con `storeagent`, ClearingHouse los
  concilia y cierra el periodo, OpsReport registra el trabajo y emite el reporte,
  EventRelay notifica al socio, AtlasSync provee el tipo de cambio del día desde
  su caché—; la revisión final de código contra el catálogo de `INSTINTOS.md`;
  `golangci-lint` en verde; la cobertura sobre el umbral; y la suite de
  integración completa.
- **La defensa técnica**, que son ocho preguntas con respuesta escrita:
  1. ¿Qué reflejos de Java trasladaste y cuáles descartaste?
  2. ¿Dónde Go te obligó a escribir más, y valió la pena?
  3. ¿Dónde escribiste menos y el resultado fue más claro?
  4. ¿Qué se rompió al migrar de 1.13 a moderno, y qué no?
  5. ¿Qué features modernas decidiste **no** usar, y por qué?
  6. ¿Qué medición te sorprendió?
  7. ¿Qué servicio de tu trabajo actual migrarías, y cuál no tocarías?
  8. ¿Qué le dirías a tu yo de la Fase 01?
- **El cierre del curso:** el ⚖️ veredicto general —cuándo NO usar Go—, las rutas
  de continuación (gRPC, Kafka, Kubernetes, WebAssembly, Go en herramientas de
  línea de comandos), y la lista de lo que este curso deliberadamente no enseñó.
- **La sección que solo puede ir aquí:** un recorrido por `INSTINTOS.md` completo,
  con los reflejos ordenados por cuánto cuesta desaprenderlos.
- **Ejercicios:** 20, casi todos de integración y argumentación; los 🔴 son
  ampliaciones reales de la plataforma con criterio de aceptación.
```

---

# 3. Después de cada fase

Al cerrar el chat de una fase, tres cosas que **no se dejan para el final del
curso**:

1. **Alimentar `INSTINTOS.md`** con los ☕ que la fase descubrió.
2. **Alimentar `BENCHMARKS.md`** con las entradas que la fase midió.
3. **Revisar los 📌 Pendientes** del bloque de autoría y repartirlos a su destino.

Si las tres se dejan para la Fase 17, ninguna se hace bien.
