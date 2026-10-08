# Comandos Bash de la sesión 918474ae-7460-472e-b793-f214b48c19f6, en orden. Una bitácora, no un script: no se corre entera.

# --- 2026-09-12T02:51:56 · List files and line counts in the course
cd /Users/oskar/Developer/Learning/courses-ia-generated/go-for-java-devs && find . -type f | sort && echo "=== WC ===" && wc -l README.md prompts/*

# --- 2026-09-12T02:51:59 · Read README and roadmap
cat README.md && echo "=====ROADMAP=====" && cat prompts/00-roadmap-fases-go-java-senior.md

# --- 2026-09-12T02:52:01 · Read instructions doc head
sed -n '1,120p' prompts/02-instrucciones-chatgpt-project-go-course.md

# --- 2026-09-12T02:52:03 · Read instructions doc rest
sed -n '120,489p' prompts/02-instrucciones-chatgpt-project-go-course.md

# --- 2026-09-12T02:52:05 · Read opsreport enunciado head and outline
sed -n '1,80p' prompts/01-enunciado-opsreport-service.md; echo "...[corte]..."; grep -n '^#' prompts/01-enunciado-opsreport-service.md

# --- 2026-09-12T02:52:07 · Outline optional project
grep -n '^#' prompts/03-proyecto-opcional-eventrelay-service.md | head -60; echo "==="; sed -n '1,60p' prompts/03-proyecto-opcional-eventrelay-service.md

# --- 2026-09-12T02:52:09 · Tail outline of optional project
grep -n '^#' prompts/03-proyecto-opcional-eventrelay-service.md | tail -20

# --- 2026-09-12T03:02:29 · Read angular-16 style guide
cd /Users/oskar/Developer/Learning/courses-ia-generated/angular-16-legacy-for-backend-devs/prompts && wc -l *.md && echo "=========== GUIA ===========" && cat guia-de-estilo-y-convenciones.md

# --- 2026-09-12T03:02:31 · Read style guide part 2
sed -n '40,450p' guia-de-estilo-y-convenciones.md

# --- 2026-09-12T03:02:33 · Read style guide part 3
sed -n '450,859p' guia-de-estilo-y-convenciones.md

# --- 2026-09-12T03:02:37 · Read chapter template part 1
sed -n '1,200p' plantillas-de-capitulo.md

# --- 2026-09-12T03:02:39 · Read proposal and prompt samples
sed -n '1,140p' propuesta-fases-y-alcance.md; echo "======= PROMPTS EXT (sample) ======="; sed -n '1,150p' prompts-extendidos-fases.md

# --- 2026-09-12T03:02:43 · Headings of scope and proposal docs
grep -n '^#\{1,3\} ' alcance-del-proyecto.md | head -60; echo "=== propuesta headings ==="; grep -n '^#\{1,3\} ' propuesta-fases-y-alcance.md

# --- 2026-09-12T03:04:53 · Mark existing prompt docs as disposable
cd /Users/oskar/Developer/Learning/courses-ia-generated/go-for-java-devs/prompts && for f in 00-roadmap-fases-go-java-senior.md 01-enunciado-opsreport-service.md 02-instrucciones-chatgpt-project-go-course.md 03-proyecto-opcional-eventrelay-service.md; do mv "$f" "_desechable-$f"; done && ls

# --- 2026-09-12T03:06:47 · Write scope document
cat > alcance-del-proyecto.md <<'MDEOF'
# 🎯 Alcance del proyecto
## Go para desarrolladores Java senior — cuatro servicios de la plataforma Meridian

Documento de encuadre. Define **qué es este curso, para quién, qué construye y
dónde se detiene**. Junto con `propuesta-fases-y-alcance.md` y
`guia-de-estilo-y-convenciones.md` forma el marco que siguen todos los chats que
redactan fases.

---

## 1. En una frase

Un curso rápido y práctico donde un desarrollador Java senior aprende Go
**construyendo cuatro servicios empresariales reales**, empezando con la
disciplina de Go 1.13 para ver el lenguaje sin azúcar, migrando pronto a Go
moderno, y comparando cada decisión contra el reflejo que traería de Spring Boot
— con números, no con anécdotas.

---

## 2. El problema que resuelve

Un senior de Java no necesita que le expliquen qué es un `for`, una interfaz o
una transacción. Necesita otras tres cosas, y ningún tutorial de "Go en 30
minutos" se las da:

**Primera: un modelo mental, no una tabla de sintaxis.** Go no es Java con menos
paréntesis. No hay herencia, no hay excepciones, no hay contenedor de inyección,
no hay anotaciones, el compilador no tolera un import sin usar y la concurrencia
es del lenguaje, no de una librería. Traducir Java literalmente produce código
que compila, pasa los tests y es un dolor de mantener. Ese código tiene nombre en
este curso: **Java escrito en Go**, y detectarlo es media asignatura.

**Segunda: proyectos con peso.** Cincuenta ejemplos de veinte líneas no enseñan a
diseñar un servicio. Este curso construye **cuatro servicios completos** que se
sostienen entre sí, con base de datos, concurrencia, caché, lotes, observabilidad
y tests de integración. Los mini proyectos existen, pero son el laboratorio donde
se aísla un concepto antes de llevarlo al servicio grande — nunca el entregable.

**Tercera: criterio para decidir.** La pregunta que un senior lleva a su jefe no
es "¿cómo se escribe un handler en Go?", es "¿migramos este servicio de Spring
Boot a Go, y qué ganamos exactamente?". El curso responde esa pregunta con un
banco de pruebas consistente y termina con un **veredicto honesto**: los casos en
los que la respuesta correcta es quedarse en Java.

---

## 3. Objetivo pedagógico

Al terminar, el estudiante puede:

1. **Leer y escribir Go idiomático** sin arrastrar reflejos de Java, y explicar
   por qué una abstracción que en Spring sería obvia aquí sobra.
2. **Diseñar un servicio Go de cero**: layout, módulos, paquetes, interfaces en
   el consumidor, errores como valores, dependencias explícitas.
3. **Manejar la concurrencia del lenguaje con criterio**: goroutines, canales,
   `select`, `sync`, `context`, worker pools acotados, cierre ordenado, y el
   detector de carreras como parte de la rutina, no como curiosidad.
4. **Persistir en tres modelos distintos** —PostgreSQL, SQLite embebido y
   MongoDB— sin asumir que hace falta un ORM, y saber cuándo sí.
5. **Cachear con Valkey** con invalidación pensada, no con `@Cacheable` puesto de
   adorno.
6. **Probar en serio**: unitarios de tabla, dobles de prueba, cobertura medida
   con umbral, tests HTTP, tests de integración con contenedores y un cliente de
   API externa mockeado de punta a punta.
7. **Operar el servicio**: configuración, logs estructurados, métricas, trazas,
   health/readiness, apagado ordenado, imagen de contenedor mínima.
8. **Medir** con un banco de pruebas consistente y **decidir** con esos números,
   incluida la decisión de no migrar.
9. **Manejar la línea de comandos de Go con soltura** — que es donde vive medio
   el ecosistema, y donde un dev acostumbrado a Maven y a un IDE que lo hace todo
   suele quedarse corto.

---

## 4. Perfil del estudiante

Desarrollador **Java senior, 8+ años**, backend. Da por sabido: OOP, colecciones,
excepciones, hilos y `ExecutorService`, JDBC y JPA, REST, SQL, pruebas
unitarias, Maven o Gradle, Git, Docker básico, y Spring Boot en producción.

No da por sabido: Go, el comando `go`, el modelo de memoria de Go, `context`,
canales, `database/sql`, el ecosistema de librerías, ni por qué el proyecto
promedio de Go tiene la mitad de archivos que su equivalente en Spring.

**Nunca se explica** qué es una variable, un condicional, un bucle, una API REST,
un índice, una transacción o un test unitario. Sí se explica —siempre— **dónde el
modelo de Go difiere del de Java**, aunque el concepto sea elemental.

---

## 5. El dominio: la plataforma de Meridian

**Meridian Retail Group** es una empresa ficticia: cadena regional de tiendas con
operación logística propia y un puñado de socios comerciales integrados por API.
Los cuatro servicios del curso son piezas reales de su plataforma interna, y
comparten vocabulario de dominio para que el estudiante no cambie de mundo cada
fase.

> 🧭 **Regla de la ficción.** Meridian es ficticia y el curso la construye
> entera. Si un capítulo afirma que algo está así en la plataforma, ese código
> tiene que existir en alguna fase y el estudiante tiene que poder abrirlo. Lo
> que no se construye se cuenta en pasado y como contexto, nunca como si fuera un
> archivo disponible.

### 5.1 Los cuatro servicios

| # | Servicio | Qué resuelve | Eje técnico | Nace en | Doc |
|---|---|---|---|---|---|
| 1 | **OpsReport** | Trabajos operativos y reportes | CRUD, jobs asíncronos, PostgreSQL, streaming | Fase 01 (Go 1.13) | `proyecto-01-opsreport.md` |
| 2 | **EventRelay** | Webhooks a socios comerciales | Cliente HTTP, reintentos, idempotencia, resiliencia | Fase 02 (Go 1.13) | `proyecto-02-eventrelay.md` |
| 3 | **AtlasSync** | Catálogo de datos de referencia | APIs públicas, MongoDB, Valkey, testing serio | Fase 10 (Go moderno) | `proyecto-03-atlassync.md` |
| 4 | **ClearingHouse** | Conciliación y cierre por lotes | SQLite en el borde, lotes, scheduling, duelo con Spring Boot | Fase 09 (Go moderno) | `proyecto-04-clearinghouse.md` |

Los dos primeros nacen bajo la disciplina de Go 1.13 y se migran en la Fase 08.
Los dos últimos nacen ya en Go moderno, y esa asimetría es deliberada: el
estudiante escribe el mismo tipo de código en las dos épocas y puede comparar sin
que nadie se lo cuente.

### 5.2 Diccionario del dominio

El código va en inglés (§5 de la guía de estilo). Estos son los términos y su
forma canónica; **ningún servicio los renombra**:

- trabajo operativo → `WorkItem` · tabla `work_items` · ruta `/work-items`
- ejecución de un trabajo → `JobExecution` · `job_executions`
- solicitud de reporte → `ReportRequest` · `report_requests` · `/reports`
- endpoint webhook de un socio → `Endpoint` · `endpoints` · `/endpoints`
- evento publicado → `Event` · `events` · `/events`
- entrega de un evento → `Delivery` · `deliveries` · `/deliveries`
- intento de entrega → `DeliveryAttempt` · `delivery_attempts`
- país / moneda / tipo de cambio → `Country`, `Currency`, `FxRate`
- tienda → `Store` · `stores`
- movimiento de caja → `Movement` · `movements`
- lote de conciliación → `Batch` · `batches`
- asiento conciliado → `LedgerEntry` · `ledger_entries`
- periodo contable → `Period` · `periods`

**Los valores de `status` nunca se traducen.** Son identificadores del sistema y
viajan tal cual en el JSON. El español vive en la narrativa, en los comentarios y
en los mensajes de error.

---

## 6. Restricciones de versiones

### 6.1 Las dos épocas

El curso tiene **dos objetivos de versión**, y cuál rige depende de la fase:

- **Época legacy (Fases 00–07).** `go 1.13` en el `go.mod`, y **stdlib de 1.13**.
  Nada posterior entra, ni siquiera si el compilador instalado lo acepta.
- **Época moderna (Fases 08–17).** La versión estable vigente, fijada en la Fase
  00 y **no se cambia durante el curso**. Mínimo funcional del material: **Go
  1.22**, porque el `ServeMux` con método y patrón de ruta es un pilar de la
  comparación con Spring MVC.

> ⚠️ **La trampa que hay que evitar al escribir.** El compilador moderno acepta
> casi todo el código de 1.13 y no avisa cuando usas una API nueva. La disciplina
> es del autor, no del toolchain. Cada API posterior a 1.13 que aparezca antes de
> la Fase 08 va marcada 🕰️ y **solo como comparación**, nunca en el código que se
> ejecuta.

### 6.2 Qué está prohibido antes de la Fase 08

`embed`, `io/fs`, `os.ReadFile`/`os.WriteFile`, genéricos, `any` como alias,
`log/slog`, `slices`, `maps`, `cmp`, `errors.Join`, `go.work`, el `ServeMux` con
patrones de método y ruta, `for range` sobre enteros, iteradores (`iter`),
`testing.F` (fuzzing), `t.Setenv`, `context.WithoutCancel`, `min`/`max`
integrados, y la semántica por iteración de las variables de bucle.

Sí están disponibles desde el día uno, porque son de 1.13 o anteriores:
`errors.Is`, `errors.As`, `fmt.Errorf` con `%w`, `errors.Unwrap`, módulos,
`strings.Builder`, `sync.Map`, `t.Run` y subtests, `httptest`, `context`,
`database/sql`, el detector de carreras y `go test -cover`.

### 6.3 Librerías externas

**Bloque A (Fases 00–07): solo stdlib.** Ni un `require` de terceros, salvo el
driver de PostgreSQL cuando la persistencia entre en escena. La restricción es
pedagógica: si un framework resuelve el problema, el estudiante no aprende cuál
era el problema.

**Bloque C (Fases 08–17): librerías del ecosistema real**, cada una introducida
con su justificación y su alternativa descartada:

- PostgreSQL: `github.com/jackc/pgx/v5` (y `database/sql` como línea base)
- SQLite sin cgo: `modernc.org/sqlite`
- MongoDB: `go.mongodb.org/mongo-driver`
- Valkey: `github.com/valkey-io/valkey-go` (con `redis/go-redis` como alternativa
  comentada)
- Migraciones: `github.com/pressly/goose/v3`
- Tests de integración: `github.com/testcontainers/testcontainers-go`
- Aserciones: `github.com/stretchr/testify` — **uso acotado**, ver guía §7.4
- Dobles generados: `go.uber.org/mock` (el sucesor mantenido de `golang/mock`)
- Concurrencia: `golang.org/x/sync` (`errgroup`, `singleflight`, `semaphore`)
- Observabilidad: `go.opentelemetry.io/otel`, `github.com/prometheus/client_golang`
- CLI: `github.com/spf13/cobra` — evaluado contra `flag` en la Fase 13
- Enrutado: `github.com/go-chi/chi/v5` — evaluado contra el `ServeMux` de 1.22
- Linting: `golangci-lint`

Explícitamente **fuera**: GORM como opción por defecto (se evalúa y se descarta
con argumentos en la Fase 09), Gin/Echo/Fiber como base del curso, Wire y Fx,
Kafka, Kubernetes y service mesh.

### 6.4 Contrapartes en Java para la comparación

Spring Boot 3.x, Spring MVC, Spring Data JPA / Hibernate, Spring Batch, Spring
Cache, Spring Retry, Micrometer y Actuator, JUnit 5, Mockito, WireMock,
Testcontainers para Java, JMH, y la JVM con y sin GraalVM `native-image`. Se
nombran por su nombre y se tratan con respeto: **ninguna comparación del curso
puede leerse como "Spring es malo"**. Spring resuelve problemas reales y los
resuelve bien; el curso mide dónde el intercambio conviene y dónde no.

---

## 7. Lo que está dentro del alcance

- El lenguaje completo que un backend usa a diario, incluidos genéricos e
  iteradores **con criterio de cuándo no usarlos**.
- El comando `go` de punta a punta y el tooling: `build`, `run`, `test`, `vet`,
  `fmt`, `mod`, `work`, `tool`, `generate`, `doc`, `env`, `list`, `clean`,
  `install`, compilación cruzada, `pprof`, `trace`, `benchstat`, `golangci-lint`,
  `dlv`.
- Preparación del ambiente en **VS Code y GoLand**, con el mínimo de extensiones
  y sin recetas de plugins de moda.
- HTTP servidor y cliente, REST, middleware, streaming.
- Concurrencia, `context`, ciclo de vida y apagado ordenado.
- PostgreSQL, SQLite, MongoDB, Valkey.
- Lotes, scheduling, trabajo asíncrono, patrón outbox.
- Testing en todos sus niveles, cobertura con umbral, dobles, contenedores.
- Observabilidad: logs estructurados, métricas, trazas, health/readiness.
- Rendimiento: benchmarks, `pprof`, escape analysis, `GOGC`/`GOMEMLIMIT`.
- Contenedores multi-etapa, imágenes mínimas, configuración en tiempo de arranque.
- El duelo medido contra Spring Boot y el veredicto honesto.

---

## 8. Lo que está fuera del alcance

- Fundamentos de programación, de HTTP, de SQL o de pruebas.
- Frontend de cualquier tipo.
- Kubernetes, service mesh, orquestación. El curso llega hasta la imagen y el
  `docker compose`.
- Kafka, RabbitMQ, NATS. Se nombran en el veredicto de la Fase 13 como la
  alternativa que en algún momento reemplaza a la cola en base de datos, y ahí se
  quedan.
- gRPC como columna del curso. Aparece como sección 🔥 opcional en la Fase 16,
  porque en la comparación con Spring Boot es una pregunta legítima.
- Arquitectura hexagonal, DDD táctico y patrones GoF como marco. Cuando una capa
  aparece es porque algo la necesitó, y se dice qué.
- **Apéndices.** Este curso no los tiene (§9).

---

## 9. Estructura de archivos del curso

Divergencia declarada frente al `CLAUDE.md` del repositorio: **este curso no
tiene apéndices**. Lo que en otros cursos sería un apéndice —el detalle del
tooling, la tabla de equivalencias, la comparación con Spring— vive dentro de la
fase que lo necesita, porque el formato "diciendo y haciendo" (guía §4) pierde
sentido si el lector tiene que saltar a otro archivo para poder ejecutar el
siguiente comando. El precio es que algunas fases son más largas; se acepta.

```text
go-for-java-devs/
  README.md                      Presentación del curso
  0-ESTRUCTURA-CURSO.md          Mapa de fases, proyectos y dependencias
  00-convencion-de-git-y-tags.md Ramas, tags, prefijos de commit
  INSTINTOS.md                   Catálogo de reflejos Java ☕ (índice vivo)
  BENCHMARKS.md                  Banco de pruebas y resultados
  00-ambiente-y-tooling.md
  01-...  ...  17-capstone.md    Las 18 fases
  prompts/                       Esta maquinaria
```

Los nombres de fase siguen la convención del repositorio: `NN-tema.md`,
minúsculas, guiones, dos dígitos.

---

## 10. Entornos de desarrollo

**Anfitrión principal:** macOS en Apple Silicon. **Secundario:** Windows 11 y
Linux. Todo comando del curso se da en su forma POSIX, y cuando la de Windows
difiera de verdad —rutas, variables de entorno, `GOOS`/`GOARCH`— se da también,
en el mismo bloque.

Los servicios de infraestructura —PostgreSQL, MongoDB, Valkey— **no se instalan
en la máquina**: viven en un `compose.yaml` del repositorio que la Fase 00 deja
listo y que las fases siguientes amplían. SQLite es un archivo y no necesita
nada.

---

## 11. El eje que ordena el curso

> 🧭 **Go no te quita herramientas: te quita intermediarios.** Todo lo que en
> Spring resuelve una anotación, en Go lo resuelve código que tú escribes y
> puedes leer. Eso se paga en líneas y se cobra en que no hay magia que depurar a
> las dos de la mañana. El curso entero es la factura detallada de ese
> intercambio, y la Fase 16 es el total.

De ahí salen las dos preguntas que toda fase tiene que poder responder:

1. **¿Cómo lo haría en Spring, y qué me está dando esa anotación realmente?**
2. **¿Ese intermediario que ya no tengo, lo estoy reconstruyendo a mano sin
   darme cuenta?** — porque esa es la definición operativa de *Java escrito en
   Go*.

---

## 12. Criterios de éxito

El curso está bien hecho si al terminar el estudiante:

1. Lee un repositorio Go ajeno sin traducirlo mentalmente a Java.
2. Escribe un servicio Go nuevo sin preguntar qué framework usar.
3. Detecta un `ThingManagerFactoryImpl` en una revisión de código y sabe
   argumentar por qué sobra.
4. Ejecuta `go test -race -cover ./...` por reflejo antes de abrir un PR.
5. Depura un servicio con `pprof` en vez de con suposiciones.
6. Puede sentarse frente a su arquitecto y decir **"este servicio sí, ese no"**,
   con un número por cada afirmación.

---

## 13. Decisiones cerradas

No se rediscuten en los chats de redacción.

| Pregunta | Decisión | Qué implica |
|---|---|---|
| Número de proyectos | **Cuatro**, con vocabulario de dominio compartido | Los mini proyectos son laboratorio, nunca entregable |
| Época inicial | **Go 1.13, stdlib pura**, Fases 00–07 | Se ve el lenguaje sin genéricos, sin `slog` y sin azúcar |
| Momento de la migración | **Fase 08**, a mitad del curso, no al final | El grueso del curso se escribe en Go moderno, que es lo que el alumno usará |
| Proyectos 3 y 4 | **Nacen modernos** | La comparación de épocas es de primera mano |
| Apéndices | **No hay** | Todo vive en su fase; divergencia declarada del `CLAUDE.md` |
| Comparación con Spring | **Medida**, con banco de pruebas propio | Nace `BENCHMARKS.md` y la Fase 16 |
| Implementación gemela | **ClearingHouse se escribe dos veces**, Go y Spring Boot | Única forma honesta de comparar; el gemelo Java se entrega hecho, no se enseña a escribirlo |
| API externa real | **REST Countries + Frankfurter**, sin clave de API | AtlasSync puede correr en cualquier máquina; en CI va mockeada |
| Base documental | **MongoDB**, en AtlasSync | Justificada por la forma del dato, no por moda |
| Caché | **Valkey** | Se compara con `@Cacheable` + Redis |
| Mocking | **Interfaces pequeñas y fakes primero**; generados solo donde duele | `go.uber.org/mock` entra en la Fase 10, no antes |
| Cobertura | **Medida con umbral en CI**, desde la Fase 04 | El umbral se discute; el número se defiende |
| Ejercicios | **20 mínimo, 24 ideal, hasta 30** en las densas | Dentro del rango por defecto del repositorio |
| CLI | **Eje transversal**, con sección fija en cada fase | El alumno sale sabiendo mover el toolchain sin IDE |
MDEOF
wc -l alcance-del-proyecto.md

# --- 2026-09-12T03:10:15 · Write style guide
cat > guia-de-estilo-y-convenciones.md <<'MDEOF'
# ✍️ Guía de estilo, tono y convenciones de código
## Go para desarrolladores Java senior — la plataforma Meridian

Esta guía es la fuente de verdad editorial del curso. Cualquier chat que produzca
un `.md` la sigue. Su objetivo es que las dieciocho fases se lean como escritas
por la misma mano, con la misma voz y el mismo criterio, y que todas apunten al
mismo sitio: **que un senior de Java escriba Go que un gopher reconocería como
suyo**.

Si dudas entre dos formas de escribir algo, gana la que le sirva más a alguien
que el lunes tiene que abrir un repositorio Go ajeno y entregar un cambio sin que
su equipo le pida explicaciones.

---

## 1. Principio rector

**Todo lo que se escribe apunta a quitar un reflejo de Java o a confirmarlo.**

No enseñamos Go "desde cero". No formamos programadores. Tomamos a alguien que ya
sabe diseñar sistemas y le recalibramos los reflejos: los que sirven igual, los
que sirven con matices, y los que —trasladados literalmente— producen código que
funciona y nadie quiere mantener.

El filtro para cada párrafo es este: **¿esto cambia lo que el lector escribiría
mañana?** Si solo describe una API que ya está en `pkg.go.dev`, sobra. Enlázala y
sigue.

---

## 2. Tono

**Semiformal y colegial: senior a senior.** El lector lleva ocho o diez años
resolviendo en Java los mismos problemas que vamos a resolver en Go. Se le habla
como a un par que cambia de herramienta, no como a un aprendiz.

- **Tuteo latinoamericano, siempre.** *"Compila esto y mira qué te dice el
  vet"*. Nada de voseo (*"compilá"*, *"fijate"*), nada de "usted", nada de
  impersonal permanente (*"se debe compilar…"*) que enfría el texto.
- **Semiformal.** Cercano pero no chat. Frases completas, puntuación correcta,
  cero abreviaturas de mensajería. Un "che" no; un "ojo con esto" sí.
- **Humor seco y con moderación.** Un 😉 bien puesto, un chiste sobre la tarde
  que perdiste buscando una fuga de goroutines que era un `defer` mal colocado.
  Regla práctica: **máximo un chiste por sección**, y si no fluye solo, se borra.
- **Honesto sobre los intercambios.** Toda opción gana en algún sitio y pierde en
  otro, y la pérdida se dice con número cuando lo hay. Go arranca en quince
  milisegundos y consume veinte megas; también te obliga a escribir a mano lo que
  `@Transactional` te daba en una línea, y a veces esa línea valía la pena.
- **Respeto por Java y por Spring.** Este curso no viene a ridiculizar el stack
  de origen. Spring resuelve problemas reales con soluciones muy trabajadas.
  Cualquier párrafo que se lea como *"Spring es malo"* está mal escrito y se
  reescribe. Lo que sí decimos, con datos, es **dónde el intercambio conviene**.
- **Cálido sin condescendencia.** Cálido significa acompañar la fricción real
  —el primer `declared and not used`, el primer `nil map`, el primer deadlock—,
  no explicar qué es una petición HTTP.

Lo que evitamos: promesas vacías ("vas a dominar Go"), motivación de coach,
solemnidad de manual, y explicar lo obvio para el perfil.

---

## 3. Idioma y forma de la narrativa

- **Español latinoamericano neutro**, técnico y claro, para todo lo que no es
  código: títulos, explicaciones, ejercicios, referencias, callouts.
- **Los términos del stack se quedan en inglés** cuando son el nombre real de la
  cosa: *goroutine*, *channel*, *slice*, *receiver*, *embedding*, *worker pool*,
  *context*, *middleware*, *escape analysis*, *race detector*, *backoff*,
  *outbox*. Traducirlos forzadamente ("hilo ligero", "rebanada") confunde y no es
  lo que van a leer en el código. *goroutine* y *slice* se usan en masculino
  ("el goroutine" no: **"la goroutine"**, "el slice"), y se fija así en la Fase 01
  para no oscilar.
- **Markdown siempre.** Nada de HTML embebido.
- **Prosa antes que listas.** Un párrafo que explica *por qué* vale más que cinco
  viñetas que enumeran *qué*. Las listas se usan cuando la cosa es de verdad una
  lista: pasos, ítems paralelos, opciones.
- **Listas antes que tablas en comparativas extensas.** Para comparar tres
  drivers o cuatro estrategias de caché, una lista con subtítulos deja sitio para
  explicar el porqué de cada celda; una tabla de siete columnas no.
- **Tablas solo para lo tabular y corto**: versiones, mapeo concepto ⇄ concepto,
  matrices de decisión, resultados de benchmark. Tres o cuatro columnas máximo.
- **Encabezados con emoji, con moderación.** Uno por sección de la plantilla. Un
  documento que parece un teclado de emojis pierde autoridad.

---

## 4. Pedagogía: "diciendo y haciendo"

Es la política central del curso y condiciona la forma de cada fase.

### 4.1 El ritmo

Ningún bloque teórico supera **dos pantallas sin un comando o un bloque de
código**. El ciclo se repite dentro de la fase tantas veces como haga falta:

```text
el problema  →  el comando  →  el código mínimo  →  ejecútalo  →  qué observas
   →  cómo lo harías en Java  →  rómpelo  →  el test  →  llévalo al proyecto
```

Lo que **no** hacemos: escribir cuatro pantallas de teoría sobre el modelo de
memoria y luego un ejemplo. Primero se ve la carrera de datos en la consola, con
su `WARNING: DATA RACE` encima, y después se explica por qué el modelo de memoria
permite ese desastre.

### 4.2 La regla del andamio

Todo concepto nuevo llega en tres tiempos, en este orden:

1. **El problema primero.** Antes de nombrar la herramienta, el dolor que
   resuelve. *"Cinco goroutines escriben el contador de intentos. Puedes poner un
   mutex, o puedes pasar el contador por un canal, o puedes descubrir dentro de
   tres meses por qué los números no cuadran."*
2. **La herramienta después.** El nombre y la definición mínima: lo justo para
   usarla hoy, no el capítulo entero de la documentación.
3. **El código que corre.** El fragmento más pequeño que demuestra el punto.

Presentar la herramienta antes que el problema produce gente que sabe escribir un
`select` y no sabe cuándo hace falta.

### 4.3 Analogías con Java, y dónde se rompen

La analogía se usa **una vez, para abrir la puerta**, y se abandona. Y siempre se
dice dónde se rompe, porque ahí está la lección:

> Una goroutine se parece a una tarea en un `ExecutorService`: la lanzas y sigues.
> Hasta ahí el paralelo. La diferencia es que no hay pool que la contenga, nadie
> te devuelve un `Future`, y si nadie la espera el proceso puede terminar sin que
> haya corrido. El `ExecutorService` te daba tres cosas —límite, resultado y
> apagado— y ninguna viene incluida.

Una analogía sin su límite es peor que no dar analogía: instala un falso amigo.

### 4.4 Densidad calibrada

- Un concepto nuevo por vez. Si un bloque introduce tres cosas desconocidas, se
  parte en tres bloques.
- Repetir lo importante está bien. Los ejes del curso —errores como valores,
  interfaces en el consumidor, dependencias explícitas, `context` como primer
  parámetro, nada de concurrencia sin límite— pueden reaparecer con otras
  palabras en varias fases.
- Los mini proyectos existen para **aislar** un concepto antes de llevarlo al
  servicio grande. Si un mini proyecto no termina alimentando a un proyecto, o
  sobra o está mal planteado.

### 4.5 Cierra los bucles

Si abres un paréntesis —*"esto lo vemos en la Fase 12"*, *"acá dejamos deuda
💸"*— tiene que cerrarse en algún documento del curso. Un 💸 sin fase de cobro
declarada es un error de escritura.

---

## 5. Idioma del código fuente

> **Regla normativa y no negociable: todo el código fuente va en inglés**
> —paquetes, identificadores, funciones, tipos, campos, rutas, tablas, columnas,
> archivos, nombres de migración— **y todos los comentarios van en español, con
> tildes.** Aplica a cada fragmento del curso sin excepción: fases, ejercicios
> resueltos, tests, SQL, YAML, Dockerfile y scripts.

El código de la plataforma Meridian está en inglés como el de cualquier
repositorio que un equipo hereda. Si el curso usara `crearTrabajo` y
`servicioReportes`, el vocabulario que el estudiante practica durante un mes no
sería el que va a leer en producción.

Y la contraparte importa igual: los comentarios son el canal donde se explica el
*porqué* de una decisión, y ese razonamiento se lee en el idioma en que se piensa
el curso.

**Los mensajes de error van con los comentarios, no con el código.** Un
`errors.New(...)` o un `fmt.Errorf(...)` es texto dirigido a otro desarrollador:
se escribe en español, con tildes, y respetando la convención de Go —**minúscula
inicial y sin punto final**, porque los errores se concatenan:

```go
// El envoltorio añade contexto sin perder el error original: quien lo reciba
// puede seguir preguntando con errors.Is por el de más abajo.
if err != nil {
    return fmt.Errorf("no se pudo guardar el work item %s: %w", id, err)
}
```

### 5.1 Convenciones de nombrado en Go

Son las del lenguaje, no las de Java, y conviene decirlas una vez y sostenerlas:

- **Paquetes:** una sola palabra, minúscula, sin guiones ni guiones bajos, sin
  plural: `report`, `worker`, `delivery`, `ledger`. Nunca `utils`, `common`,
  `helpers`, `models` ni `impl`. Si no sabes cómo llamar al paquete, el paquete
  todavía no existe.
- **Nada de tartamudeo.** `report.Generator`, no `report.ReportGenerator`. El
  paquete ya dice de qué habla.
- **Interfaces:** pequeñas, nombradas por lo que hacen, con `-er` cuando tiene
  una sola operación: `Reader`, `Storer`, `Notifier`. **Sin prefijo `I`** y **sin
  sufijo `Impl` en la implementación**, jamás.
- **Constructores:** `New` cuando el paquete devuelve su tipo principal
  (`report.New()`), `NewX` cuando hay varios (`postgres.NewWorkItemStore()`).
- **Receivers:** una o dos letras, consistentes en todo el tipo: `func (s *Store)`
  siempre `s`, nunca `this` ni `self`.
- **Errores centinela:** `ErrNotFound`, `ErrDuplicate`, `ErrInvalidState`,
  exportados y declarados a nivel de paquete.
- **Tipos de error:** sufijo `Error` (`ValidationError`), con `Unwrap()` cuando
  envuelvan.
- **Acrónimos en mayúscula sostenida:** `ID`, `URL`, `HTTP`, `SQL`, `API`.
  `workItemID`, no `workItemId`.
- **Archivos:** `snake_case.go`, con `_test.go` para pruebas. Los tests de
  integración llevan build tag y sufijo: `store_integration_test.go`.
- **Tablas y columnas:** `snake_case` (`work_items`, `created_at`,
  `template_version`). Los campos BSON de Mongo también.
- **Constantes de configuración:** en Go se escriben `CamelCase`, no
  `SCREAMING_SNAKE`; las variables de entorno sí van en `SCREAMING_SNAKE`
  (`MERIDIAN_DB_URL`).

### 5.2 Layout de los proyectos

El layout **emerge**. Ninguna fase crea un paquete vacío para parecerse a nada.
El destino aproximado de cada servicio es este, y se llega por partes:

```text
cmd/<servicio>/main.go      Ensamblado: lee config, cablea, arranca, apaga
internal/<dominio>/         Tipos y reglas del negocio, sin infraestructura
internal/<servicio>/        Casos de uso; depende de interfaces, no de drivers
internal/postgres|mongo|... Implementaciones; una por tecnología
internal/httpapi/           Handlers, middleware, codificación
internal/config/            Lectura y validación de configuración
migrations/                 SQL versionado
testdata/                   Golden files y fixtures
```

Tres reglas sobre esto, que se repiten cuando aplican:

- **`internal/` de verdad**, para que el compilador impida importarlo desde
  fuera. Es lo más parecido a `package-private` que tiene Go, y es más fuerte.
- **Las interfaces se declaran donde se consumen**, no donde se implementan. El
  paquete `service` declara `WorkItemStore`; el paquete `postgres` no sabe que
  existe. Esto es lo contrario de la costumbre de Java y es la diferencia de
  diseño más importante del curso.
- **`main` ensambla y nada más.** Nada de lógica en `cmd/`.

---

## 6. El estilo de código del curso

### 6.1 La regla de época

> 🧭 **Fases 00–07: Go 1.13 y stdlib pura. Fases 08–17: Go moderno.** El
> compilador moderno no te va a avisar cuando te salgas de época; la disciplina
> es tuya. Cada API posterior a 1.13 que aparezca antes de la Fase 08 va marcada
> 🕰️ y solo como comparación, nunca en el código que corre.

El corolario que el estudiante se lleva: **saber qué llegó cuándo es parte de
leer código ajeno.** Un repositorio Go de 2019 no es peor: es de 2019, y el
`for i := range v` con la variable compartida que hay dentro era correcto para su
época.

### 6.2 Las diez reglas del código del curso

Valen en las dos épocas y no se negocian:

1. **Los errores son valores y se manejan donde ocurren.** Nada de `panic` como
   flujo de control. `panic` solo para invariantes rotos en el arranque, y
   `recover` solo en el borde de un worker o un handler, para que un error no
   tumbe el proceso — y ahí se registra y se explica.
2. **Envolver con `%w` cuando el que llama pueda querer preguntar** con
   `errors.Is`/`errors.As`; con `%v` cuando el detalle es solo para el log. La
   decisión se comenta.
3. **`context.Context` es el primer parámetro** de toda función que haga E/S, y
   se llama `ctx`. Nunca se guarda en un struct. Nunca se usa como bolsa de
   parámetros.
4. **Cero concurrencia sin límite.** Toda goroutine tiene un dueño que sabe
   cuándo termina, y todo conjunto de goroutines tiene un tope. Si arrancas una
   goroutine y no puedes decir quién la espera, está mal.
5. **Interfaces pequeñas y en el consumidor.** Una interfaz de siete métodos es
   casi siempre un struct disfrazado.
6. **Dependencias explícitas por constructor.** Sin contenedor, sin registro
   global, sin `init()` haciendo trabajo. `init()` casi nunca es la respuesta.
7. **Cero estado global mutable.** Ni `var db *sql.DB` de paquete, ni un logger
   global que alguien reconfigure a mitad de la ejecución.
8. **`gofmt` no se discute** y `go vet` pasa limpio antes de cualquier commit.
   No hay estilo personal en Go, y eso es una función, no un defecto.
9. **Tests desde la primera fase que produce código de negocio**, de tabla, con
   subtests, y `-race` en todo lo que toque concurrencia.
10. **Fechas con zona horaria explícita.** `time.Time` lleva ubicación; se guarda
    en UTC (`timestamptz` en PostgreSQL) y se formatea en la zona del negocio en
    el borde. Nunca un `time.Now()` suelto donde importe el día: el reloj se
    inyecta como dependencia desde la Fase 02.

### 6.3 El antipatrón que da nombre al curso: ☕ Java escrito en Go

Es el defecto que el curso persigue fase por fase. Se marca con ☕ y se nombra
cuando aparece. El catálogo vive en `INSTINTOS.md` y crece con el curso; estos
son los residentes fijos:

- `ThingServiceImpl`, `AbstractThing`, `ThingFactory`, `ThingManagerFactory`.
- Interfaces de un solo implementador creadas "por si acaso".
- Interfaces gigantes que replican una clase entera.
- Getters y setters para cada campo de un struct que ya es público.
- Un contenedor de inyección casero, o un mapa global de servicios.
- Jerarquías de errores con tipos por cada caso, cuando bastaban tres centinelas.
- `panic`/`recover` usados como `try`/`catch`.
- DTOs duplicados en cada capa sin que ninguna transformación lo justifique.
- Una capa `repository` para todo, incluso donde hay una sola consulta.
- Recrear la Streams API con canales y abstracciones, cuando un `for` de cuatro
  líneas era más rápido y más claro.
- Mockear todo lo mockeable en vez de usar un fake de veinte líneas.
- `utils`, `common`, `helpers`, `models`, `dto`, `impl` como nombres de paquete.
- Hilos manejados como en Java: un "pool" que en realidad es un `for` que lanza
  goroutines sin tope.

La pregunta recurrente, que se formula tal cual en el texto cuando toque:

> ☕ **¿Esta abstracción existe porque el dominio la necesita, o porque así la
> escribiríamos en Spring?**

Y la contraparte honesta, que también hay que decir: **algunos reflejos de Java
son correctos en Go.** Separar dominio de infraestructura, inyectar
dependencias, probar contra interfaces, versionar migraciones — todo eso sirve
igual y se marca 🩻. El curso no pide olvidar Java; pide dejar de aplicarlo por
reflejo.

### 6.4 Genéricos: se enseñan y se restringen

Desde la Fase 08 los genéricos existen y se enseñan bien. Y con ellos llega la
regla:

> 🧭 **Escribe la versión concreta primero. Generaliza cuando tengas el tercer
> caso de uso delante, no antes.** Un genérico prematuro es la forma moderna de
> `AbstractBaseService<T>`.

Sitios donde el curso sí los usa: contenedores (`Set[T]`, `Result[T]`), utilidades
de slices y mapas, y firmas donde la alternativa sería `interface{}` con
aserciones de tipo. Sitios donde el curso los rechaza explícitamente: los
repositorios (`Repository[T]` es el ☕ más elegante que existe) y las capas de
servicio.

### 6.5 Comentarios

Los comentarios explican **el porqué**, nunca el qué. Un `// incrementa el
contador` sobre `count++` es ruido.

Los comentarios de documentación —los que preceden a un identificador
exportado— siguen la convención de Go: empiezan con el nombre del identificador,
frase completa, y son lo que `go doc` va a mostrar:

```go
// Store guarda y recupera work items. Las implementaciones deben ser seguras
// para uso concurrente: el worker pool comparte una sola instancia.
type Store interface { ... }
```

### 6.6 Corrección mínima frente a refactorización

Cada vez que aparece un fix se distingue **el parche mínimo** —lo que va un
viernes— de **la refactorización correcta** —lo que iría con calma y pruebas. Es
una de las lecciones más transferibles del curso y no cuesta más de tres líneas
decirla.

---

## 7. Testing: el régimen del curso

El testing no es una fase, es una condición. La Fase 04 lo formaliza y a partir
de ahí todo código del curso llega con sus pruebas.

### 7.1 La pirámide y sus nombres

- **Unitarios**, de tabla, sin E/S, sin `sleep`, sin red. Rápidos de verdad.
- **De componente**, con `httptest.Server` y `httptest.NewRecorder`, sin
  contenedores.
- **De integración**, con `testcontainers-go` levantando PostgreSQL, MongoDB o
  Valkey de verdad. Con build tag `//go:build integration` y objetivo de `make`
  propio, para que la suite rápida siga siendo rápida.
- **De punta a punta**, con el servicio completo arriba y **la API externa
  mockeada**. Es el caso de AtlasSync y es donde el curso enseña que "end to end"
  no significa "depender de internet".

### 7.2 Tablas, subtests y nombres

Todo test de más de un caso es de tabla, con `t.Run` y nombre legible por caso.
El nombre describe el comportamiento esperado, no la función:
`TestCreate_RejectsEmptyExternalReference`, no `TestCreate2`.

Se usa `t.Parallel()` donde el caso lo permita, y se explica la trampa clásica de
la variable de bucle capturada — con la nota 🕰️ de que en Go 1.22 dejó de ser
trampa.

### 7.3 Dobles de prueba

**El orden de preferencia es: función, fake, generado.** En ese orden, y se
justifica cada salto:

1. **Una función.** Si la dependencia es una operación, el doble es una función.
   Go no necesita una clase para eso.
2. **Un fake escrito a mano.** Veinte líneas, un mapa dentro, comportamiento
   real. Cubre el 90% de los casos del curso y se lee mejor que cualquier
   generado.
3. **Un mock generado** con `go.uber.org/mock`, y solo cuando hace falta
   verificar interacciones —que se llamó, cuántas veces, con qué— o cuando la
   interfaz tiene tantos métodos que el fake se vuelve mantenimiento.

> ☕ **El reflejo de Mockito.** En Java mockear es el primer movimiento porque las
> dependencias son clases concretas y el contenedor las inyecta. En Go la
> interfaz es del consumidor, es pequeña, y un fake de veinte líneas suele ser
> más claro que tres `when(...).thenReturn(...)`. La Fase 10 enseña el generador
> y explica por qué llega tan tarde.

### 7.4 Aserciones y `testify`

La stdlib no trae aserciones y eso es deliberado: `if got != want { t.Errorf(...) }`
se lee bien y no esconde nada. El curso lo usa como forma por defecto.

`testify/require` entra en la Fase 09 **acotado a los tests de integración**,
donde encadenar diez comprobaciones sin abortar es ruido puro. `testify/mock` y
`testify/suite` **no entran**: el primero compite con `go.uber.org/mock` sin
ventaja y el segundo reintroduce el `setUp`/`tearDown` de JUnit que Go resolvió
con `t.Cleanup`.

### 7.5 Cobertura

Se mide desde la Fase 04 y se defiende:

```bash
go test -race -coverprofile=cover.out -covermode=atomic ./...
go tool cover -func=cover.out
go tool cover -html=cover.out
```

El umbral del curso es **80% en `internal/`**, con `cmd/` excluido. Y va con su
advertencia, que se escribe una vez y se sostiene: **la cobertura mide líneas
ejecutadas, no comportamiento verificado.** Un test que llama a todo y no afirma
nada da 100% y no vale nada.

---

## 8. Marcadores y callouts

Vocabulario visual compartido por todos los documentos.

### 8.1 Marcadores de estado

- ☕ **Reflejo Java.** El marcador propio de este curso: señala el punto exacto
  donde el instinto de Java lleva a la respuesta equivocada. Es el que más se
  busca con `Ctrl+F` y el que define el curso.
- 🩻 **Esto sí funciona igual.** Lo que se traslada sin cambios desde Java.
- 🕰️ **Fuera de época.** Una API que existe en Go moderno pero está prohibida
  hasta la Fase 08. Aparece solo como comparación, con su versión mínima.
- 💸 **Deuda técnica intencional.** Un atajo dejado a propósito. **Cada 💸 declara
  en qué fase se paga**, o dice explícitamente que no se paga y por qué. Un 💸 sin
  destino es un error de escritura.
- ⭐ **Pieza central.** Las Fases 06, 08 y 16.
- 🔥 **Opcional o ampliación.** Secciones y ejercicios fuera del recorrido base.
  No cuentan en el calendario.
- 📐 **Medido.** Marca una afirmación respaldada por una entrada de
  `BENCHMARKS.md`. Sin la entrada, la afirmación no se escribe.
- 🧨 **Rompe a propósito.** Experimento destructivo con resultado esperado.
- 🟢🟡🟠🔴 **Dificultad de ejercicios.**
- 🏷️ **Tag de progreso.** Una vez por documento, en el cierre, con la forma fija
  de §9.1.

### 8.2 Callouts en blockquote

- 🧭 **Regla del proyecto.** Una decisión que aplica a todo el curso y que el
  estudiante debería poder citar de memoria al terminar.
- 🧠 **Modelo mental.** Cómo pensar la pieza, no cómo usarla.
- ⚠️ **Advertencia.** Algo que rompe si lo ignoras.
- 💡 **Truco o atajo** que ahorra tiempo real.
- 📝 **Nota de época.** Qué versión trajo esta API, qué reemplazó y por qué el
  código anterior sigue siendo correcto para su momento.
- 📚 **Referencia rápida inline.** El enlace útil justo donde nace la duda.

### 8.3 Secciones narrativas recurrentes

Micro-secciones con nombre fijo, que aparecen cuando el contenido las pide:

- 🪞 **"Tu instinto de Java dice… y esta vez se equivoca."** El reflejo, por qué
  es razonable, y qué pasa exactamente si lo aplicas. Obligatoria en toda fase.
- 🩻 **"Esto sí funciona igual."** El contrapeso: qué se traslada intacto.
  Obligatoria en toda fase, aunque sean tres líneas.
- ⚰️ **"Autopsia de un antipatrón."** Un caso de ☕ concreto, con el código, el
  costo en números —líneas, asignaciones, latencia, tiempo de compilación— y el
  antes/después. Al menos una por fase desde la Fase 02.
- 📖 **"Diccionario Java ⇄ Go."** Mapeo en las **dos direcciones**, con la
  columna que más importa: *"dónde se rompe la equivalencia"*. Obligatoria.
- 🛠️ **"CLI de la fase."** Los comandos que la fase introduce, con lo que hace
  cada bandera que se usa. Es el eje transversal de línea de comandos y va en
  **todas** las fases.
- 🧪 **"Prueba de fuego."** Verificación manual concreta: qué ejecutar, qué
  esperar, y qué mentira te va a contar la pantalla si miras el sitio equivocado.
- 📐 **"Cómo se mide."** Cuando la fase hace una afirmación de rendimiento: la
  hipótesis, el comando, y el enlace a la entrada de `BENCHMARKS.md`.
- ⚖️ **"Veredicto honesto."** Cuándo **no** usar lo que la fase acaba de enseñar.
  Obligatoria en el cierre de toda fase.
- **"El patrón a memorizar."** Una o dos frases que destilan la lección
  transferible.
- **"La señal de que quedó bien."** En el cierre, un criterio en forma de cita.

---

## 9. Plantilla obligatoria de cada fase (10 secciones)

Toda fase produce un `.md` con exactamente estas diez secciones, en orden. El
esqueleto rellenable está en `plantillas-de-capitulo.md`.

1. **🎯 Propósito** — qué resuelve la fase, anclado al estado en que la dejó la
   anterior.
2. **✅ Qué queda listo al terminar** — checklist verificable, no promesas.
3. **🚫 Qué NO entra todavía** — qué se difiere y a qué fase exacta.
4. **🧠 Concepto mínimo** — la teoría justa. Aquí viven 🪞, 🩻 y 📝.
5. **🛠️ CLI de la fase** — los comandos nuevos, con sus banderas explicadas.
6. **💻 Construcción guiada** — el grueso, en ciclos de "diciendo y haciendo":
   mini proyectos primero, luego el avance del proyecto o proyectos de la fase.
   Aquí viven las 🧪 Pruebas de fuego y los 💸.
7. **⚰️ Autopsia y errores comunes** — el ☕ de la fase con su costo medido, más
   dos a cuatro errores típicos en formato síntoma → causa → fix mínimo, y al
   menos un 🧨.
8. **🧪 Ejercicios** — ver §10.
9. **📚 Referencias** — ver §11.
10. **⚖️ Veredicto y cierre** — cuándo no usar esto, el 📖 diccionario de la
    fase, qué sigue, La señal de que quedó bien, y el bloque 🏷️ del tag.

Después de la décima, y **fuera de lo que lee el estudiante**, cada fase cierra
con **📌 Pendientes sugeridos**: lo que apareció al escribirla y no cabía dentro,
con destino explícito. Es material de autoría.

### 9.1 El recordatorio del tag, en el cierre

Forma fija; cambian solo el número y el texto del checklist:

````markdown
> 🏷️ **No cierres la fase sin el tag.** Con el checklist de la sección 2 en
> verde, `go test -race ./...` en verde y `git status` limpio:
>
> ```bash
> git tag -a fase-04 -m "F4 cerrada: <el checklist, en una línea por ítem>"
> ```
>
> Los commits de la fase llevan su prefijo (`fase 04: …`) y los de ejercicio su
> número (`fase 04 ej17: …`). Todo eso está en
> [`00-convencion-de-git-y-tags.md`](../00-convencion-de-git-y-tags.md).
````

---

## 10. Ejercicios

- **Cantidad: 20 mínimo, 24 ideal, hasta 30 en las densas.** Las Fases 06, 09 y
  16 llegan a 30 y ese es el techo.
- **Distribución equilibrada.** Para ~24: unos 6 🟢, 8 🟡, 6 🟠 y 4 🔴, más los 🔥
  aparte.
- **Numeración continua con encabezado de rango:**

  ```markdown
  ## 🧪 8. Ejercicios (24)

  **🟢 Fácil (1–6)**
  1. ...

  **🟡 Intermedio (7–14)**
  **🟠 Difícil (15–20)**
  **🔴 Muy difícil (21–24)**
  **🔥 Opcionales**
  ```

- **Accionables y verificables**, con criterio de éxito medible: *"tu worker pool
  procesa 10.000 jobs sin que `-race` reporte nada y el proceso termina en menos
  de dos segundos tras la señal"*, no *"reflexiona sobre la concurrencia"*.
- **Al menos un tercio son de diagnóstico**: se entrega algo roto y se pide
  reproducir, localizar y explicar. Un deadlock, una fuga de goroutines, un
  `nil map`, un `defer` dentro de un bucle, un `context` que nadie cancela.
- **Al menos dos por fase, desde la Fase 02, son de detección de ☕**: se da un
  fragmento con olor a Java y se pide reescribirlo en Go idiomático y justificar
  qué se perdió y qué se ganó.
- **Al menos uno por fase toca la línea de comandos**: una bandera de `go test`,
  una consulta con `go list`, una compilación cruzada, un `go doc`.
- **Enganchados al dominio.** Work items, entregas, tiendas, movimientos, tipos
  de cambio. Nunca `foo` y `bar`.
- **Con el identificador vigente**: si el ejercicio nombra código, usa el nombre
  en inglés que ya existe en la fase.
- **Cada ejercicio 🔴 lleva rúbrica o solución de referencia**; los 🟢 y 🟡 basta
  con el criterio de éxito.

---

## 11. Bibliografía y referencias

**Regla de orden:** documentación oficial primero, después libros, después
artículos, después video. Y siempre se advierte cuando el enlace cubre una
versión distinta de la del curso — que con la época de 1.13 pasa casi siempre.

### 11.1 Formato

URLs completas y clicables, nunca solo el dominio. La sección se separa en
**documentación oficial**, **libros**, **artículos y charlas**, **video**, y
cierra con una línea de **orden de lectura sugerido**: qué leer antes de escribir
código, qué consultar durante, a qué volver después.

### 11.2 Fuentes oficiales de cabecera

- **Documentación de Go:** https://go.dev/doc/
- **Especificación del lenguaje:** https://go.dev/ref/spec
- **Referencia de paquetes:** https://pkg.go.dev
- **Effective Go:** https://go.dev/doc/effective_go
- **Go Code Review Comments:** https://go.dev/wiki/CodeReviewComments
- **Google Go Style Guide:** https://google.github.io/styleguide/go/
- **Modelo de memoria:** https://go.dev/ref/mem
- **Referencia de módulos:** https://go.dev/ref/mod
- **Notas de versión (todas):** https://go.dev/doc/devel/release
- **El blog de Go:** https://go.dev/blog/
- **Go by Example:** https://gobyexample.com
- **Uber Go Style Guide:** https://github.com/uber-go/guide
- **PostgreSQL:** https://www.postgresql.org/docs/ · **pgx:** https://pkg.go.dev/github.com/jackc/pgx/v5
- **SQLite:** https://www.sqlite.org/docs.html
- **MongoDB Go Driver:** https://www.mongodb.com/docs/drivers/go/current/
- **Valkey:** https://valkey.io/documentation/
- **Testcontainers Go:** https://golang.testcontainers.org
- **OpenTelemetry Go:** https://opentelemetry.io/docs/languages/go/
- **Spring Boot**, para el lado Java: https://docs.spring.io/spring-boot/index.html

### 11.3 Libros que el curso cita

Se citan por autor y título; **no se inventan ISBN, ediciones ni páginas**, y se
advierte que títulos y URLs pueden haber cambiado.

- *The Go Programming Language* — Donovan y Kernighan. La referencia del
  lenguaje; escrito en la época de 1.5-1.8, lo que lo vuelve extrañamente
  apropiado para el Bloque A.
- *Learning Go* — Jon Bodner. El más cercano a Go moderno y a este perfil.
- *100 Go Mistakes and How to Avoid Them* — Teiva Harsanyi. Es prácticamente el
  catálogo de ☕ por otros medios; se cita mucho.
- *Concurrency in Go* — Katherine Cox-Buday. Para las Fases 06 y 07.
- *Let's Go* y *Let's Go Further* — Alex Edwards. Servicios HTTP con stdlib, que
  es exactamente el enfoque del curso.
- *Efficient Go* — Bartłomiej Płotka. Para las Fases 15 y 16.

### 11.4 Video y charlas

Se citan por título y canal, con la advertencia de que la URL puede haber
cambiado. Las de referencia obligada:

- *Go Concurrency Patterns* y *Advanced Go Concurrency Patterns* — Rob Pike.
- *Concurrency is not Parallelism* — Rob Pike.
- El canal de las **GopherCon** en YouTube, para las charlas de `pprof`,
  `context` y diseño de APIs.
- **JetBrains Go** y **Google for Developers**, para tooling.

Y una advertencia que se escribe una vez por curso: **buena parte del contenido
en video sobre Go es anterior a los genéricos y a `slog`**. No está mal: está
fechado. Verifica la fecha antes de copiar un patrón.

---

## 12. Coherencia entre documentos

- **No contradecir fases anteriores**, ni en pedagogía ni en nombres.
- **Nombres estables.** Paquetes, tipos y funciones se mantienen idénticos entre
  fases. Si algo se renombra se documenta el cambio y se ajustan las fases
  afectadas.
- **Ninguna afirmación de rendimiento sin su entrada en `BENCHMARKS.md`.** Si la
  entrada no existe, se crea antes de escribir la frase, o la frase no se
  escribe. Vale también para los "Go arranca más rápido" que parecen obvios.
- **Fuentes de verdad, en este orden:** (1) `prompts/alcance-del-proyecto.md`,
  (2) `prompts/propuesta-fases-y-alcance.md`, (3) los cuatro documentos de
  proyecto `prompts/proyecto-0N-*.md`, (4) esta guía, (5)
  `prompts/plantillas-de-capitulo.md` y `prompts/formato-de-benchmarks.md`,
  (6) entregables ya aprobados de fases anteriores, (7) decisiones explícitas del
  chat actual.

> ⚠️ Los archivos `prompts/_desechable-*.md` **no cuentan como fuente de nada** y
> no se referencian nunca: son el material de arranque y se borran al terminar el
> curso.

---

## 13. Checklist antes de dar por cerrado un `.md`

- [ ] Sigue la plantilla de 10 secciones, sin secciones extra ni reordenadas.
- [ ] Tono semiformal y colegial, tuteo latinoamericano, humor con moderación.
- [ ] Ningún bloque teórico de más de dos pantallas sin comando o código (§4.1).
- [ ] Explica el problema antes que la herramienta, y el porqué de cada decisión.
- [ ] Prosa antes que listas; listas antes que tablas en comparativas extensas.
- [ ] **Todo el código en inglés, todos los comentarios en español con tildes**;
      mensajes de error en español, minúscula inicial, sin punto final (§5).
- [ ] **La época se respeta**: nada posterior a Go 1.13 antes de la Fase 08 salvo
      marcado 🕰️ y como comparación (§6.1).
- [ ] Nombres de paquete de una palabra, sin `utils`/`common`/`impl`, sin
      tartamudeo, interfaces sin `I` y sin `Impl` (§5.1).
- [ ] Las interfaces se declaran en el consumidor (§5.2).
- [ ] `context.Context` como primer parámetro en todo lo que hace E/S; ninguna
      goroutine sin dueño ni tope (§6.2).
- [ ] Cada 💸 declara en qué fase se paga, o por qué no se paga.
- [ ] Lleva 🪞, 🩻, 📖 y ⚖️; y ⚰️ desde la Fase 02.
- [ ] Lleva la sección 🛠️ CLI de la fase, con las banderas explicadas.
- [ ] Toda afirmación de rendimiento lleva 📐 y su entrada en `BENCHMARKS.md`.
- [ ] Tiene 20-30 ejercicios con rangos 🟢🟡🟠🔴 equilibrados, un tercio de
      diagnóstico, dos de detección de ☕ y al menos uno de línea de comandos.
- [ ] El código mostrado compila y los comandos mostrados se pueden ejecutar tal
      cual, en el orden en que aparecen.
- [ ] Referencias con URL completa, con advertencia cuando cubran otra versión.
- [ ] Ninguna comparación se lee como "Spring es malo" (§2).
- [ ] Coherencia de la ficción: nada que afirme sobre Meridian algo que el curso
      no pueda mostrar, y ningún ejercicio que exija un sistema externo o una
      clave de API.
- [ ] Incluye "La señal de que quedó bien" y el bloque 🏷️ del tag (§9.1).
- [ ] Los ☕ nuevos que aparezcan quedan anotados para `INSTINTOS.md`.
MDEOF
wc -l guia-de-estilo-y-convenciones.md

# --- 2026-09-12T03:13:50 · Write phase proposal
cat > propuesta-fases-y-alcance.md <<'MDEOF'
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

Fases: `NN-tema.md`, de `00-ambiente-y-tooling.md` a `17-capstone.md`.
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
MDEOF
wc -l propuesta-fases-y-alcance.md

# --- 2026-09-12T03:14:57 · Write chapter template
cat > plantillas-de-capitulo.md <<'MDEOF'
# 🧩 Plantilla de capítulo
## Go para desarrolladores Java senior — la plataforma Meridian

Este archivo contiene el esqueleto que se copia al abrir el chat de una fase.
Como el curso **no tiene apéndices** (`alcance-del-proyecto.md` §9), hay una sola
plantilla y es rígida: diez secciones, en orden, idénticas en las dieciocho fases.

Junto con la guía de estilo y el alcance, es lo que hace que dieciocho documentos
escritos en dieciocho chats se lean como un solo libro.

> **Nota de coherencia:** las cifras de referencia son las de
> `propuesta-fases-y-alcance.md` §2 — **131h en 18 fases**. Si cambian, se
> actualizan allí primero y aquí después, nunca al revés.

---

# 📐 Plantilla de fase

Copiar el bloque completo, rellenar los `{{placeholders}}` y borrar las notas
entre llaves antes de entregar.

````markdown
# {{emoji}} Fase {{NN}} — {{Nombre}}

> Go para desarrolladores Java senior · Fase {{N}} de 17 · **{{X}} horas**
> Época: **{{Go 1.13 (stdlib pura) | frontera | Go moderno ({{versión}})}}**
> Depende de: {{fase previa}} · Habilita: {{fase siguiente}}
> Proyectos que avanzan: {{OpsReport · EventRelay · AtlasSync · ClearingHouse}}
> Mini proyectos: {{`nombre-1`, `nombre-2`, `nombre-3`}}

---

## 🎯 1. Propósito

{{Una o dos frases: qué resuelve esta fase y por qué le importa a alguien que va
a escribir Go en su trabajo el mes que viene. Abrir con el estado en que la fase
anterior dejó los proyectos — no con una definición.}}

---

## ✅ 2. Qué queda listo al terminar

- [ ] {{resultado verificable 1}}
- [ ] {{resultado verificable 2}}
- [ ] {{...4 a 6 ítems}}
- [ ] `go vet ./...` y `golangci-lint run` en verde{{, y `go test -race ./...` si
      la fase toca concurrencia}}

{{Verificable = se comprueba corriendo un comando o mirando una salida.
"Entender los canales" no es un resultado verificable; "tu worker pool procesa
10.000 jobs sin que -race reporte nada" sí.}}

---

## 🚫 3. Qué NO entra todavía

- {{tema diferido}} → Fase {{M}}.
- {{...}}

{{Si la fase es del Bloque A, incluir aquí lo que está fuera por época, con su
marca 🕰️ y su versión mínima: "genéricos → Fase 08 (Go 1.18)".}}

---

## 🧠 4. Concepto mínimo

{{Solo la teoría necesaria para escribir el código de esta fase. Prosa, no
viñetas. El problema antes que la herramienta (guía §4.2). Ningún bloque de más
de dos pantallas sin un comando o un fragmento.}}

### 🪞 Tu instinto de Java dice… y esta vez se equivoca

{{Obligatoria. El reflejo concreto, por qué es razonable en Java, y qué pasa
exactamente si lo aplicas aquí. Con el código de las dos versiones cuando ayude.
Cerrar con qué pensar en su lugar.}}

### 🩻 Esto sí funciona igual

{{Obligatoria, aunque sean tres líneas. El contrapeso honesto: qué se traslada
intacto desde Java. El curso no pide olvidar lo que el lector sabe.}}

> 📝 **Nota de época.** {{Qué versión de Go trajo esta API, qué reemplazó, y por
> qué el código anterior sigue siendo correcto para su momento. En el Bloque A,
> además: qué existe hoy y aquí no podemos usar todavía, marcado 🕰️.}}

---

## 🛠️ 5. CLI de la fase

{{Obligatoria en todas las fases. Los comandos que esta fase introduce o usa en
serio, con lo que hace cada bandera que aparece. No es una lista de comandos: es
el sitio donde el estudiante aprende a moverse sin IDE.}}

```bash
# {{qué hace y por qué te importa}}
go {{subcomando}} {{banderas}}
```

{{Incluir siempre: qué salida esperas, qué significa cuando falla, y el
equivalente de Maven o Gradle cuando exista — con su límite, porque casi nunca es
exacto.}}

> 💡 {{Un atajo real: una bandera poco conocida, una variable de entorno, un
> `go doc` que ahorra una búsqueda en el navegador.}}

---

## 💻 6. Construcción guiada

{{El grueso de la fase, en ciclos de "diciendo y haciendo" (guía §4.1): problema
→ comando → código mínimo → ejecútalo → qué observas → cómo sería en Java →
rómpelo → el test → llévalo al proyecto. Tantos ciclos como conceptos tenga la
fase.}}

### 6.1 Mini proyecto: `{{nombre}}`

{{Aísla un concepto. Menos de doscientas líneas, con sus tests. Vive en
`labs/{{nombre}}/`. Decir explícitamente a qué servicio va a alimentar después —
si no alimenta a ninguno, sobra.}}

### 6.2 {{Avance de {{Proyecto}}}}

{{Qué se le agrega al servicio y por qué ahora. Código ejecutable, coherente con
la época de la fase.}}

{{Estilo obligatorio — guía §6.2:
- Errores como valores; `%w` cuando el llamador pueda preguntar, `%v` cuando no,
  y la decisión comentada.
- `context.Context` como primer parámetro de todo lo que hace E/S.
- Ninguna goroutine sin dueño ni tope.
- Interfaces pequeñas, declaradas en el consumidor.
- Dependencias por constructor; sin estado global mutable; sin trabajo en `init()`.
- Paquetes de una palabra; nada de `utils`, `common`, `impl`, ni tartamudeo.
- Código en inglés, comentarios en español con tildes; mensajes de error en
  español, minúscula inicial, sin punto final.
- Reloj inyectado; fechas con zona explícita.}}

**Detalles con intención**
- {{decisión deliberada del bloque anterior}} — {{su porqué, en media línea}}.

**El patrón a memorizar**
> {{Una o dos frases con la lección transferible del fragmento.}}

**🧪 Prueba de fuego**
{{Verificación concreta: qué ejecutar, qué salida esperar, y qué mentira te va a
contar la pantalla si miras el sitio equivocado.}}

{{💸 Marcar cada deuda intencional con sus dos partes: qué sería lo correcto y
**en qué fase se paga**. Si no se paga, decirlo y explicar por qué. Un 💸 sin
destino es un error de escritura.}}

{{📐 Si la fase afirma algo sobre rendimiento, marcarlo y enlazar su entrada de
`BENCHMARKS.md`. Sin entrada, la afirmación no se escribe.}}

---

## ⚰️ 7. Autopsia y errores comunes

### ☕ Autopsia: {{nombre del antipatrón}}

{{Obligatoria desde la Fase 02. Un caso concreto de Java escrito en Go: el código
tal como lo escribiría alguien que viene de Spring, por qué es razonable que lo
escriba así, y la versión idiomática al lado. Con el costo medido: archivos,
líneas, indirecciones, asignaciones, tiempo de compilación o latencia — lo que
aplique, pero un número. Se anota en `INSTINTOS.md`.}}

### Errores comunes

{{2 a 4 errores típicos, en formato síntoma → causa → fix mínimo. Distinguir
siempre el parche mínimo de la refactorización correcta (guía §6.6).}}

### 🧨 Rompe a propósito

{{Al menos uno. Qué tocar, qué comando correr, y qué esperas ver exactamente en
la salida — el mensaje del compilador, el `WARNING: DATA RACE`, el `fatal error:
all goroutines are asleep`. Que el estudiante reconozca el error por su cara
antes de encontrárselo en producción.}}

---

## 🧪 8. Ejercicios ({{total}})

**🟢 Fácil (1–{{a}})**
1. {{...}}

**🟡 Intermedio ({{a+1}}–{{b}})**
**🟠 Difícil ({{b+1}}–{{c}})**
**🔴 Muy difícil ({{c+1}}–{{total}})**
**🔥 Opcionales**

{{20 mínimo, 24 ideal, hasta 30 en las densas. Numeración continua; el título
lleva el conteo. Accionables y con criterio de éxito medible. Al menos un tercio
de diagnóstico (se entrega algo roto). Desde la Fase 02, al menos dos de
detección de ☕. Al menos uno de línea de comandos. Anclados al dominio de
Meridian, nunca `foo` y `bar`. Cada 🔴 lleva rúbrica o solución de referencia.}}

---

## 📚 9. Referencias

**Documentación oficial**
- {{URL completa}} — {{qué resuelve; advertencia de versión si aplica}}

**Libros**
- {{Autor, *Título*}} — {{capítulo o tema; sin inventar ISBN ni páginas}}

**Artículos y charlas**
- {{...}}

**Video**
- {{título y canal, con la advertencia de fecha}}

**Orden de lectura sugerido:** {{qué leer antes de escribir código → qué
consultar durante → a qué volver después}}

> ⚠️ URLs, títulos y contenidos pueden haber cambiado; verifícalos. {{Y en el
> Bloque A, la advertencia propia: casi toda la documentación en línea describe
> Go moderno, así que un ejemplo con genéricos o `slog` no es un error del autor
> — es que estamos trabajando en 2019 a propósito.}}

---

## ⚖️ 10. Veredicto y cierre

### ⚖️ Cuándo NO usar esto

{{Obligatoria. Los casos en los que lo que acabas de enseñar es la respuesta
equivocada, y qué usar en su lugar. Con nombres: si la respuesta es "quédate con
Spring", se dice.}}

### 📖 Diccionario Java ⇄ Go de esta fase

| Java / Spring | Go | Dónde se rompe la equivalencia |
|---|---|---|
| {{concepto}} | {{concepto}} | {{la parte que importa}} |

{{Obligatoria. Mapeo en las dos direcciones — la tercera columna es la que vale.
Distinguir equivalencia aproximada, parcial y ninguna.}}

### Qué sigue

{{Qué quedó construido y por qué la Fase {{siguiente}} es el paso natural: qué
necesita de esta fase para existir.}}

> **La señal de que quedó bien:** {{criterio en forma de cita — cómo se siente el
> trabajo bien hecho de esta fase.}}

> 🏷️ **No cierres la fase sin el tag.** Con el checklist de la sección 2 en
> verde, `go test -race ./...` en verde y `git status` limpio:
>
> ```bash
> git tag -a fase-{{NN}} -m "F{{N}} cerrada: <el checklist, en una línea por ítem>"
> ```
>
> Los commits de la fase llevan su prefijo (`fase {{NN}}: …`) y los de ejercicio
> su número (`fase {{NN}} ej17: …`). Todo eso está en
> [`00-convencion-de-git-y-tags.md`](00-convencion-de-git-y-tags.md).
>
> {{Si la fase tiene algo propio que decir sobre git —paga una deuda 💸 declarada
> antes, marca un hito de proyecto (`opsreport/v0.4`), deja una rama de
> comparación como la de la Fase 08— se añade un párrafo corto al final del mismo
> bloque, no un bloque nuevo.}}
````

---

# 📌 Bloque de autoría (fuera de lo que lee el estudiante)

Va después de la sección 10, separado por un `---`, y **no forma parte del
capítulo**: es material para quien escribe el curso.

````markdown
---

## 📌 Pendientes sugeridos

{{Lo que apareció al escribir la fase y no cabía dentro, cada uno con destino
explícito: fase posterior, ejercicio 🔥, entrada de `INSTINTOS.md`, entrada de
`BENCHMARKS.md`.}}

- {{pendiente}} → {{destino}}

## ☕ Reflejos para `INSTINTOS.md`

{{Los ☕ que esta fase descubrió, con su nombre, el síntoma en una línea y la
fase donde se documentan.}}

## 📐 Mediciones para `BENCHMARKS.md`

{{Las entradas que esta fase necesita: hipótesis, condiciones, comando. Con el
formato de `formato-de-benchmarks.md`.}}
````

---

# ✅ Antes de entregar

Pásale al documento el checklist de §13 de `guia-de-estilo-y-convenciones.md` y
reporta en una lista corta qué ítems cumples y cuáles no, con el motivo.

Los cinco que más se rompen, por orden de frecuencia:

1. **La época.** Una API posterior a 1.13 colada en el Bloque A sin marca 🕰️.
2. **El bloque teórico largo.** Más de dos pantallas sin un comando de por medio.
3. **El 💸 sin fase de cobro.**
4. **La afirmación de rendimiento sin entrada en `BENCHMARKS.md`.**
5. **La comparación que se lee como "Spring es malo".**
MDEOF
wc -l plantillas-de-capitulo.md

# --- 2026-09-12T03:16:14 · Write OpsReport project doc
cat > proyecto-01-opsreport.md <<'MDEOF'
# 🗂️ Proyecto 1 — OpsReport Service
## Trabajos operativos y reportes · Meridian Retail Group

> **Eje técnico:** CRUD empresarial, procesamiento asíncrono, PostgreSQL,
> generación de reportes con *streaming*.
> **Nace:** Fase 01, en Go 1.13 · **Migra:** Fase 08 · **Cierra:** Fase 17.
> **Módulo:** `services/opsreport` · **Binario:** `opsreport`.

---

## 1. El problema

Las áreas de Meridian —logística, tesorería, compras, soporte— lanzan cada día
trabajos operativos que hoy viven en hojas de cálculo y grupos de chat:
importaciones de catálogo, conciliaciones, recálculos de inventario, generación
de extractos, reprocesos de archivos de proveedor.

Nadie sabe cuántos hay en curso, cuántos fallaron ayer, ni cuánto tarda en
promedio una conciliación. Cuando dirección pide "el reporte de operación del
mes", alguien dedica dos días a juntarlo a mano.

**OpsReport** registra esos trabajos, los ejecuta en segundo plano con
concurrencia acotada, guarda el resultado de cada ejecución y produce reportes
descargables en CSV, JSON y HTML.

Es, deliberadamente, **el servicio más parecido a lo que un dev de Spring ya sabe
hacer**: CRUD, jobs, base de datos relacional, reportes. Por eso es el primero.
Lo que cambia no es el problema, es la forma de resolverlo — y esa es toda la
lección.

---

## 2. Objetivo funcional

1. Registrar un `WorkItem` con su referencia externa, tipo, descripción y
   prioridad.
2. Consultar y filtrar trabajos por estado, tipo, prioridad y rango de fechas.
3. Solicitar la ejecución de un trabajo.
4. Ejecutarlo de forma asíncrona, sin bloquear la petición HTTP.
5. Cancelar un trabajo encolado o en curso, cuando sea posible.
6. Registrar cada ejecución con su duración, su worker y su error si lo hubo.
7. Solicitar un reporte operativo con filtros.
8. Generar el reporte en segundo plano y consultar su estado.
9. Descargarlo en CSV, JSON o HTML.
10. Exponer `/health` y `/ready`.
11. Publicar eventos de dominio para que EventRelay los entregue a los socios
    (Fase 13, patrón outbox).

---

## 3. Entidades

### `WorkItem`

```text
ID                 string     identificador propio del servicio
ExternalReference  string     la referencia del sistema de origen (SAP-2026-000123)
Type               string     reconciliation | import | recalculation | statement | reprocess
Description        string
Priority           int        1 a 9; mayor es más urgente
Status             string     pending | queued | running | completed | failed | cancelled
CreatedAt          time.Time
UpdatedAt          time.Time
```

Transiciones legales, y **ninguna otra**:

```text
pending   -> queued | cancelled
queued    -> running | cancelled
running   -> completed | failed | cancelled
completed -> (final)
failed    -> queued            (reintento manual)
cancelled -> (final)
```

La máquina de estados se implementa en la Fase 02 como una función pura y se
prueba con una tabla exhaustiva en la Fase 04. **Es el primer sitio del curso
donde una interfaz sería un error**: es una función, y en Go se queda como
función.

### `JobExecution`

```text
ID            string
WorkItemID    string
AttemptNumber int
StartedAt     time.Time
FinishedAt    *time.Time    nulo mientras corre — y ese puntero es una decisión
Status        string        running | completed | failed | cancelled
ErrorMessage  string
WorkerID      int
DurationMS    int64
```

> 💡 El `*time.Time` frente a `time.Time` con valor cero es la primera discusión
> de modelado de la Fase 02, y la respuesta del curso es: **si "ausente" y "cero"
> significan cosas distintas, el puntero gana**. En Java esto era `null` y nadie
> lo pensaba.

### `ReportRequest`

```text
ID           string
Format       string     csv | json | html
Filter       Filter     embebido; ver abajo
Status       string     pending | generating | completed | failed
RequestedAt  time.Time
CompletedAt  *time.Time
FileName     string
SizeBytes    int64
RowCount     int
ErrorMessage string
```

```text
Filter:
  From, To       *time.Time
  Statuses       []string
  Types          []string
  MinPriority    *int
```

---

## 4. API objetivo

```http
POST   /work-items
GET    /work-items?status=&type=&from=&to=&limit=&cursor=
GET    /work-items/{id}
PUT    /work-items/{id}
DELETE /work-items/{id}
POST   /work-items/{id}/execute
POST   /work-items/{id}/cancel
GET    /work-items/{id}/executions

POST   /reports
GET    /reports
GET    /reports/{id}
GET    /reports/{id}/download

GET    /health
GET    /ready
GET    /metrics
```

Paginación **por cursor, no por número de página**, desde la Fase 09. Es una
decisión de diseño que el curso defiende con un número: el `OFFSET 100000` de la
paginación clásica hace que PostgreSQL recorra cien mil filas para descartarlas.

Ejemplo de alta:

```json
{
  "externalReference": "SAP-2026-000123",
  "type": "reconciliation",
  "description": "Conciliación diaria de tiendas del norte",
  "priority": 5
}
```

```json
{ "id": "wi_01HQ...", "status": "pending", "createdAt": "2026-03-04T08:12:00Z" }
```

---

## 5. Arquitectura objetivo

No se crea de golpe. Cada paquete aparece en la fase que lo necesita.

```text
services/opsreport/
  cmd/opsreport/main.go        ensambla y arranca; nada más
  internal/workitem/           dominio: tipos, estados, validación   (F01-F02)
  internal/opsreport/          casos de uso; declara sus interfaces  (F02)
  internal/memstore/           almacén en memoria                    (F02)
  internal/postgres/           almacén real                          (F09)
  internal/httpapi/            handlers, middleware, codificación    (F05)
  internal/worker/             cola y pool de ejecución              (F06-F07)
  internal/report/             generadores csv/json/html             (F13)
  internal/outbox/             publicación transaccional de eventos  (F13)
  internal/config/             configuración validada                (F03, F14)
  internal/obs/                logs, métricas, trazas                (F14)
  migrations/                  SQL versionado con goose              (F09)
  testdata/                    golden files                          (F04)
```

> 🧭 **Ninguna capa se crea vacía.** Si en la Fase 02 no hay nada que poner en
> `internal/httpapi`, el directorio no existe. La estructura es consecuencia, no
> plantilla.

---

## 6. Avance por fase

**Fase 01 — nace.** El tipo `WorkItem`, sus constantes de estado y tipo, la
validación y el cálculo de prioridad efectiva. Todo en un paquete, todo en
memoria, sin servicio. Aquí se pelea con slices y mapas por primera vez.

**Fase 02.** Separación real: el paquete `workitem` con el dominio y la máquina
de estados; el paquete `opsreport` con el servicio, que **declara** las
interfaces `Store`, `Clock` e `IDGenerator`; y `memstore` que las implementa sin
saberlo. Es la fase donde se ve por qué la interfaz vive en el consumidor.

**Fase 03.** Errores del paquete (`ErrNotFound`, `ErrInvalidTransition`,
`ErrDuplicateReference`), envoltorio con `%w`, configuración desde entorno y
archivo, y la serialización JSON del dominio con sus etiquetas.

**Fase 04.** Suite completa: tabla exhaustiva de transiciones, fakes de reloj y
almacén, golden files para la serialización, cobertura medida y umbral.

**Fase 05.** La API REST en memoria: los siete endpoints de work items, el
enrutado escrito a mano, la cadena de middleware, la traducción de errores de
dominio a códigos HTTP en un solo sitio, y la suite con `httptest`.

**Fase 06.** El motor asíncrono: cola con búfer acotado, N workers, el estado
avanzando de `queued` a `running` a `completed`, `sync.WaitGroup` para el
apagado, y el registro de `JobExecution`. Pasa `-race`.

💸 Aquí la cola vive **solo en memoria**: si el proceso muere, los trabajos
encolados se pierden. **Se paga en la Fase 09**, cuando la cola pasa a PostgreSQL
y la recuperación tras reinicio se vuelve un test.

**Fase 07.** `context` de punta a punta: el `DELETE` cancela el trabajo en curso,
el `SIGTERM` drena la cola con un límite de tiempo, y un test verifica que no
queda ninguna goroutine viva.

**Fase 08.** Migra. `embed` para las plantillas HTML del reporte, `slog` en lugar
del logger propio, el `ServeMux` moderno reemplazando el enrutado a mano
—comparación lado a lado—, `errors.Join` para los errores de validación
agregados, y la decisión explícita de **no** generalizar el almacén con
`Store[T]`.

**Fase 09.** PostgreSQL: esquema, migraciones, el almacén real, transacciones en
las transiciones de estado, paginación por cursor, recuperación de trabajos
encolados al arrancar, y la suite de integración con testcontainers.

**Fase 13.** El generador de reportes como job de larga duración: agregaciones en
SQL, recorrido de `sql.Rows` en *streaming* hacia el `io.Writer` de la respuesta
—sin cargar el dataset en memoria, y medido 📐 contra la versión ingenua—, los
tres formatos, y el patrón **outbox** publicando eventos de dominio para
EventRelay.

**Fase 14.** Logs estructurados con identificador de petición, métricas RED,
trazas, `/health` y `/ready` honestos, configuración validada al arrancar,
imagen de contenedor mínima.

**Fase 15.** Perfilado del endpoint de listado, del generador de reportes y del
pool de workers. Optimización **solo con evidencia**, y el registro de una mejora
que no lo fue.

**Fase 17.** Integración con los otros tres servicios y revisión final.

---

## 7. Los temas que este proyecto enseña y los otros no

- **El CRUD empresarial completo** sin un framework que lo genere, que es donde
  se ve cuánto hacía Spring Data y cuánto cuesta no tenerlo.
- **El job asíncrono clásico**: cola, workers, estados, reintento, cancelación.
- **El reporte grande**, que es el problema de *streaming* por excelencia: el
  momento en que `[]WorkItem` deja de caber en memoria y hay que pensar en
  `io.Writer`.
- **La paginación que escala.**
- **El patrón outbox**, que es la respuesta correcta a "cómo publico un evento
  dentro de una transacción" y que en Spring suele resolverse con una librería.

---

## 8. Qué NO se construye aquí

Autenticación real (el servicio vive tras un gateway y se dice así), interfaz de
usuario, exportación a Excel, programación por calendario —eso es ClearingHouse—,
y cualquier cola externa: la cola es PostgreSQL, y en la Fase 13 se explica en
qué punto eso deja de bastar y empieza el territorio de Kafka o NATS.

---

## 9. Criterio de finalización

1. Arranca con configuración externa y falla rápido si le falta algo.
2. Se conecta a PostgreSQL con el pool dimensionado y declarado.
3. Sirve los quince endpoints con sus códigos correctos.
4. Ejecuta trabajos concurrentes con tope, y el tope se puede configurar.
5. Recupera trabajos encolados tras un reinicio.
6. Cancela un trabajo en curso en menos de un segundo.
7. Genera un reporte de 500.000 filas sin que la memoria residente suba más de
   lo que dice su entrada en `BENCHMARKS.md`.
8. Apaga limpio ante `SIGTERM`, sin goroutines vivas.
9. Publica eventos por outbox sin perder ninguno ante caída entre commit y envío.
10. `go test ./...`, `go test -race ./...` y `make test-integration` en verde.
11. Cobertura de `internal/` sobre el umbral del curso.
12. Tiene benchmarks y perfiles de sus tres rutas calientes.

---

## 10. 📖 El diccionario de este proyecto

| Spring | OpsReport en Go | Dónde se rompe |
|---|---|---|
| `@RestController` + `@RequestMapping` | `http.Handler` registrado en el mux | No hay descubrimiento: si no lo registras, no existe |
| `@Service` | Un struct con sus dependencias por constructor | Nadie lo instancia por ti; `main` lo cablea |
| `@Repository` + `JpaRepository` | Una interfaz de 4 métodos en el consumidor | No hay consultas derivadas del nombre; escribes el SQL |
| `@Transactional` | `tx` pasado explícitamente | La propagación es un parámetro, no una anotación |
| `@Async` + `TaskExecutor` | Cola con búfer + pool de goroutines | No hay pool por defecto: lo dimensionas tú o no hay tope |
| `@Scheduled` | `time.Ticker` en una goroutine con `ctx` | Sin `ShedLock`: con dos instancias corren las dos |
| `ResponseEntity` | `w.WriteHeader` + `json.NewEncoder(w)` | Se escribe una vez; un segundo `WriteHeader` es un bug silencioso |
| `@ControllerAdvice` | Una función `writeError` en el borde | No es global: si no la llamas, no traduce |
| Jackson | `encoding/json` con etiquetas | Sin anotaciones de módulo; las fechas se deciden a mano |
| `Pageable` / `Page<T>` | Cursor opaco + `[]WorkItem` + `nextCursor` | No hay `totalElements` gratis, y contar cuesta |
MDEOF
wc -l proyecto-01-opsreport.md

# --- 2026-09-12T03:17:38 · Write EventRelay project doc
cat > proyecto-02-eventrelay.md <<'MDEOF'
# 📡 Proyecto 2 — EventRelay Service
## Entrega fiable de eventos a socios comerciales · Meridian Retail Group

> **Eje técnico:** cliente HTTP, reintentos, idempotencia, contrapresión,
> resiliencia.
> **Nace:** Fase 02, en Go 1.13 · **Migra:** Fase 08 · **Cierra:** Fase 17.
> **Módulo:** `services/eventrelay` · **Binarios:** `eventrelay`, `fakeconsumer`.

---

## 1. El problema

Meridian integra a una treintena de socios: transportistas, pasarelas de pago,
marketplaces, el ERP del grupo. Cada uno quiere enterarse cuando pasa algo:
`order.created`, `payment.approved`, `shipment.dispatched`,
`settlement.completed`.

Hoy cada servicio productor llama directamente a los consumidores, y eso produce
el incidente que todo el mundo ha visto: **un socio lento cuelga al productor.**
La pasarela de un partner tarda ocho segundos, el hilo se queda esperando, el
pool se agota, y de pronto Meridian no puede registrar ventas porque un tercero
tiene un mal día.

**EventRelay** se pone en medio. El productor publica el evento, recibe un
acuse en milisegundos y sigue. La entrega ocurre en segundo plano, con
reintentos, retroceso exponencial, firma, historial de intentos y cola de
mensajes muertos.

Si OpsReport es el servicio que un dev de Spring ya sabe hacer, **EventRelay es
el que Go hace notablemente mejor**: miles de entregas concurrentes, cada una
esperando E/S de red, es exactamente el trabajo para el que existe una goroutine.

---

## 2. Objetivo funcional

1. Registrar y administrar endpoints de socios, con su secreto de firma.
2. Activar y desactivar un endpoint sin perder su historial.
3. Suscribir un endpoint a patrones de tipo de evento (`order.*`).
4. Publicar un evento, con clave de idempotencia opcional.
5. Crear una entrega por cada endpoint suscrito.
6. Entregar por HTTP con tiempo límite, firmado con HMAC.
7. Registrar cada intento con su estado, su latencia y su error.
8. Clasificar el fallo en recuperable o permanente, y reintentar solo el primero.
9. Aplicar retroceso exponencial con *jitter* y un máximo configurable.
10. Limitar la concurrencia global y por endpoint.
11. Mandar a la cola de muertos lo que agote los intentos.
12. Reprocesar manualmente una entrega o una cola de muertos completa.
13. Cancelar entregas pendientes de un endpoint dado de baja.
14. Recuperar el trabajo pendiente tras un reinicio.
15. Consumir el outbox de OpsReport (Fase 13).
16. Exponer `/health`, `/ready` y `/metrics`.

---

## 3. Entidades

### `Endpoint`

```text
ID            string
Name          string
URL           string      validada: solo https en producción, sin IP privada
Secret        string      nunca se devuelve por la API, nunca se registra en log
Enabled       bool
EventPatterns []string    order.*  ·  payment.approved  ·  *
MaxRPS        int         límite de tasa propio del socio
CreatedAt, UpdatedAt time.Time
```

> ⚠️ La validación de URL es un tema de seguridad, no de formato: aceptar
> `http://169.254.169.254/` convierte a EventRelay en una herramienta de SSRF
> contra la propia infraestructura. Se trata en la Fase 14 y tiene sus ejercicios
> 🔴.

### `Event`

```text
ID              string
Type            string
Payload         json.RawMessage   se guarda tal cual; no se reinterpreta
IdempotencyKey  string            único cuando está presente
Source          string            qué servicio lo publicó
CreatedAt       time.Time
```

### `Delivery`

```text
ID            string
EventID       string
EndpointID    string
Status        string     pending | delivering | delivered | retry_scheduled
                         | failed | cancelled | dead_letter
AttemptCount  int
NextAttemptAt *time.Time
LastError     string
CreatedAt     time.Time
CompletedAt   *time.Time
```

### `DeliveryAttempt`

```text
ID            string
DeliveryID    string
AttemptNumber int
StartedAt     time.Time
FinishedAt    time.Time
HTTPStatus    int          0 cuando ni siquiera hubo respuesta
DurationMS    int64
ErrorMessage  string
Classification string      transient | permanent
```

---

## 4. API objetivo

```http
POST   /endpoints
GET    /endpoints
GET    /endpoints/{id}
PUT    /endpoints/{id}
DELETE /endpoints/{id}

POST   /events                     con cabecera Idempotency-Key
GET    /events
GET    /events/{id}
GET    /events/{id}/deliveries

GET    /deliveries?status=&endpoint=&from=&to=
GET    /deliveries/{id}
GET    /deliveries/{id}/attempts
POST   /deliveries/{id}/retry
POST   /deliveries/{id}/cancel
POST   /dead-letters/replay

GET    /health · /ready · /metrics
```

La entrega saliente:

```http
POST https://partner.example.com/webhooks
Content-Type: application/json
X-Meridian-Event-Id: evt_01HQ...
X-Meridian-Event-Type: order.created
X-Meridian-Delivery-Id: dlv_01HQ...
X-Meridian-Attempt: 3
X-Meridian-Timestamp: 1772611920
X-Meridian-Signature: sha256=...
```

La firma se calcula sobre `timestamp + "." + body` y **el timestamp entra en el
hash** — si no, cualquiera puede reenviar un mensaje interceptado. Se explica en
la Fase 14 con su ataque de repetición.

---

## 5. Política de reintentos

Base pedagógica de la Fase 06, endurecida en la 10:

```text
intento 1  ->  inmediato
intento 2  ->  +1s     · con jitter de ±20%
intento 3  ->  +2s
intento 4  ->  +4s
intento 5  ->  +8s
...        ->  base * 2^(n-1), tope de 1h, máximo 12 intentos
agotado    ->  dead_letter
```

Clasificación, que **es una función pura y se prueba con tabla**:

```text
transient:  408, 429, 500, 502, 503, 504
            timeout, connection refused, DNS temporal, EOF
permanent:  400, 401, 403, 404, 410, 422
            URL inválida, certificado TLS inválido, cuerpo ilegible
```

El `429` con cabecera `Retry-After` se respeta, y eso también se prueba.

> 🧭 **La regla:** no todo fallo se reintenta, y reintentar un `400` doce veces
> no es resiliencia, es acoso a un socio que ya te dijo que el mensaje está mal.

---

## 6. `fakeconsumer`: el segundo binario

Dentro del propio módulo vive un consumidor falso, y es una pieza pedagógica de
primer orden: permite probar reintentos sin depender de internet ni de un socio
real.

```http
POST /ok          200 inmediato
POST /slow        responde tras N segundos (parametrizable)
POST /fail/{code} devuelve el código pedido
POST /flaky       falla las dos primeras veces, responde 200 a la tercera
POST /verify      valida la firma HMAC y responde 401 si no cuadra
POST /hang        acepta la conexión y no responde nunca
```

Nace en la Fase 05 con tres rutas y crece hasta la 14. Es también el sitio donde
el estudiante ve **el otro lado del webhook**, que es lo que le van a pedir
implementar en su trabajo tan a menudo como el emisor.

---

## 7. Arquitectura objetivo

```text
services/eventrelay/
  cmd/eventrelay/main.go
  cmd/fakeconsumer/main.go
  internal/relay/          dominio: evento, entrega, estados        (F02)
  internal/eventrelay/     casos de uso                             (F02)
  internal/memstore/                                                (F02)
  internal/postgres/                                                (F09)
  internal/httpapi/                                                 (F05)
  internal/dispatch/       cola, workers, planificador de reintentos (F06-F07)
  internal/deliver/        cliente HTTP, clasificación, backoff      (F10)
  internal/signature/      HMAC y verificación                       (F14)
  internal/ratelimit/      límite por endpoint sobre Valkey          (F12)
  migrations/ · testdata/
```

---

## 8. Avance por fase

**Fase 02 — nace.** `Endpoint`, `Event`, `Delivery` y la máquina de estados de la
entrega, que es más rica que la de OpsReport y por eso llega después. Servicios y
almacén en memoria.

**Fase 03.** Errores del dominio, configuración, y la decodificación del cuerpo
entrante con `json.RawMessage` — el payload del socio **no se reinterpreta**, y
explicar por qué es una clase entera sobre acoplamiento.

**Fase 04.** Tabla exhaustiva de la máquina de estados, tests de la clasificación
de errores, fake de reloj para probar el cálculo del retroceso sin esperar ocho
segundos. Es el primer sitio donde el estudiante ve **por qué el reloj se
inyecta**.

**Fase 05.** La API REST, el `fakeconsumer` con sus tres primeras rutas, y la
entrega todavía simulada.

**Fase 06 ⭐.** El motor real: cola de entregas con búfer acotado, N workers,
`select` sobre el canal de trabajo y el de apagado, el contador de intentos que
en la primera versión **tiene una carrera de datos a propósito** y `-race` la
encuentra. Laboratorio de contrapresión: qué pasa cuando el productor publica más
rápido de lo que los socios absorben.

💸 El planificador de reintentos vive en memoria con un `time.Timer` por entrega.
Funciona y es didáctico; **se paga en la Fase 09**, cuando la reprogramación pasa
a ser una columna `next_attempt_at` y una consulta.

**Fase 07.** Tiempo límite por entrega, cancelación propagada al cliente HTTP,
apagado ordenado que espera a las entregas en vuelo hasta un límite y después las
devuelve a `pending`.

**Fase 08.** Migra. Fuzzing 🆕 sobre el verificador de firmas y el decodificador
de payloads —es el caso de uso perfecto y el curso lo aprovecha—, `slog`,
`errgroup` reemplazando el `WaitGroup` manual, y el `ServeMux` moderno.

**Fase 09.** PostgreSQL con el modelo de cuatro tablas, la cola en base de datos
con `SELECT ... FOR UPDATE SKIP LOCKED` —que es la joya de la fase—, y el test
que mata el proceso a mitad de una entrega y verifica que se recupera.

**Fase 10.** El cliente HTTP en serio: `Transport` reutilizado y dimensionado,
tiempos límite en las cuatro capas, drenaje del cuerpo antes de cerrarlo,
retroceso con *jitter*, cortacircuitos por endpoint, y **los mocks generados**
para verificar que reintentó tres veces y no cuatro.

**Fase 12.** Límite de tasa por socio sobre Valkey, e idempotencia distribuida
con `SET NX` y TTL.

**Fase 13.** Consume el outbox de OpsReport: los dos servicios se conectan por
fin, y el flujo `WorkItem completado → evento → entrega al socio` funciona de
punta a punta.

**Fase 14.** Firma HMAC con timestamp, validación de URL contra SSRF, secretos
que nunca aparecen en un log —con el ejercicio 🧨 de registrarlos a propósito y
ver qué queda en la salida—, métricas por endpoint, y trazas que cruzan de
OpsReport a EventRelay al socio.

**Fase 15.** Perfilado del despacho: cuánto cuesta la firma, cuánto la
serialización, cuánto el `Transport` mal reutilizado, y el rendimiento sostenido
de entregas por segundo contra el `fakeconsumer`.

---

## 9. Los temas que este proyecto enseña y los otros no

- **El cliente HTTP bien configurado**, que es de lo que menos se habla y más
  incidentes causa.
- **La semántica de entrega**: al menos una vez, idempotencia, duplicados, y por
  qué "exactamente una vez" no existe sobre HTTP.
- **La contrapresión** de verdad, con un productor rápido y un consumidor lento.
- **La clasificación de errores** como función pura y probada, en vez de un
  `catch (Exception e) { retry(); }`.
- **El fallo parcial**: veintinueve socios bien y uno caído, y que eso no degrade
  a los veintinueve.
- **La criptografía mínima** que un backend usa de verdad: HMAC, comparación en
  tiempo constante, y por qué `==` sobre firmas es un bug de seguridad.

---

## 10. Qué NO se construye aquí

Kafka, RabbitMQ ni NATS. La cola es PostgreSQL, y la Fase 13 explica con números
dónde deja de bastar. Tampoco hay multi-tenencia, ni entrega por lotes, ni
suscripciones con transformación de payload: son ampliaciones 🔥 listadas en la
Fase 17 para quien quiera seguir.

---

## 11. Criterio de finalización

1. Registra endpoints, valida sus URL y nunca devuelve ni registra el secreto.
2. Acepta un evento en menos de 20 ms p95 con la base bajo carga.
3. Dos publicaciones con la misma `Idempotency-Key` producen un solo evento.
4. Entrega firmada, y el `fakeconsumer` verifica la firma.
5. Un socio caído produce reintentos con retroceso y termina en la cola de
   muertos, sin afectar a los demás.
6. Un `400` no se reintenta ni una vez.
7. Un `429` con `Retry-After` respeta el valor indicado.
8. Matar el proceso a mitad de una entrega no pierde la entrega.
9. El límite de tasa por endpoint se respeta con dos instancias corriendo.
10. Apaga limpio, devolviendo a `pending` lo que no alcanzó a terminar.
11. `go test -race ./...` y la suite de integración en verde.
12. Sostiene el rendimiento declarado en su entrada de `BENCHMARKS.md` con el
    `fakeconsumer` como destino.

---

## 12. 📖 El diccionario de este proyecto

| Spring | EventRelay en Go | Dónde se rompe |
|---|---|---|
| `RestTemplate` / `WebClient` | `http.Client` con `Transport` propio | El cliente por defecto no tiene timeout; el tuyo sí o te cuelgas |
| `@Retryable` / `RetryTemplate` | Una función `backoff(attempt) time.Duration` | Es código tuyo: lo pruebas con tabla y lo lees entero |
| `@Recover` | La rama que marca `dead_letter` | No hay despacho por tipo de excepción; clasificas tú |
| `CircuitBreaker` de Resilience4j | Un struct con contador y ventana | Sin anotación, sin proxy, sin sorpresas de AOP |
| `@Async` + `CompletableFuture` | goroutine + canal | No hay `Future` que consultar; el resultado viaja o se guarda |
| `ThreadPoolTaskExecutor` | Canal con búfer + N workers | El tamaño de la cola es tuyo; no hay política de rechazo por defecto |
| WireMock | `httptest.Server` + `fakeconsumer` | Sin DSL de stubs: es un handler, y se lee mejor |
| `@Scheduled` para reprogramar | Consulta `next_attempt_at <= now()` | Con dos instancias hace falta `SKIP LOCKED`, no una anotación |
| `MessageDigest` / `Mac` | `crypto/hmac` + `hmac.Equal` | `hmac.Equal` es tiempo constante; `bytes.Equal` no, y eso importa |
MDEOF
wc -l proyecto-02-eventrelay.md

# --- 2026-09-12T03:17:44 · Fix stray marker
sed -i '' 's/Fuzzing 🆕 sobre/Fuzzing (Go 1.18) sobre/' proyecto-02-eventrelay.md && grep -n 'Fuzzing' proyecto-02-eventrelay.md

# --- 2026-09-12T03:19:13 · Write AtlasSync project doc
cat > proyecto-03-atlassync.md <<'MDEOF'
# 🌍 Proyecto 3 — AtlasSync Service
## Catálogo de datos de referencia · Meridian Retail Group

> **Eje técnico:** consumo de APIs externas, MongoDB, caché con Valkey, y la
> pirámide de pruebas completa con el mundo exterior mockeado.
> **Nace:** Fase 10, ya en **Go moderno** · **Cierra:** Fase 17.
> **Módulo:** `services/atlassync` · **Binario:** `atlassync`.

---

## 1. El problema

Meridian opera en once países. Cada uno tiene su moneda, su código ISO, su
formato de dirección, su zona horaria y su tipo de cambio del día. Esos datos los
necesitan los cuatro servicios de la plataforma, el ERP, el marketplace y tres
socios logísticos.

Hoy cada sistema los tiene copiados a mano en un archivo de configuración, y cada
sistema los tiene copiados de forma ligeramente distinta. El día que Meridian
abrió operación en un país nuevo, cuatro equipos hicieron el mismo cambio en
cuatro sitios, y uno se equivocó de código de moneda.

**AtlasSync** ingiere datos de referencia de fuentes públicas, los normaliza, los
almacena en MongoDB, los sirve por una API propia y los mantiene calientes en
Valkey. Es un servicio **de lectura intensiva**: pocas escrituras, muchísimas
lecturas, y una dependencia externa que puede estar caída.

---

## 2. Por qué este proyecto nace en Go moderno

Los dos primeros servicios nacieron en 1.13 y se migraron. AtlasSync **nace
después de la Fase 08**, ya con genéricos, `slog`, el `ServeMux` moderno e
iteradores disponibles desde la primera línea.

La asimetría es deliberada y didáctica: el estudiante va a escribir el mismo tipo
de código —un handler, un almacén, un cliente— con las dos cajas de herramientas,
y va a poder decir por experiencia propia dónde la moderna ayuda de verdad y
dónde es azúcar. Es la única forma honesta de contestar *"¿cuánto cambió Go en
diez años?"*.

---

## 3. Las fuentes externas

Todas públicas, **sin clave de API**, para que el curso funcione en cualquier
máquina y en cualquier momento:

- **REST Countries** — `https://restcountries.com/v3.1/all` — países, códigos
  ISO, monedas, idiomas, zonas horarias, región y subregión.
- **Frankfurter** — `https://api.frankfurter.app/latest` — tipos de cambio del
  Banco Central Europeo, con histórico por fecha.
- 🔥 **Open-Meteo** — `https://open-meteo.com` — opcional, como segunda fuente
  para los ejercicios de agregación de proveedores.

> ⚠️ **Estas APIs pueden cambiar, moverse o desaparecer.** El curso lo asume:
> todas las respuestas usadas en pruebas están **grabadas en `testdata/`**, el
> servicio arranca y funciona con ellas, y solo un test marcado 🔥 —excluido de
> CI— golpea la red de verdad. Que un curso dependa de que un servicio gratuito
> siga vivo en 2029 es un defecto de diseño, y aquí se evita a propósito.

---

## 4. Objetivo funcional

1. Ingerir el catálogo de países desde la fuente externa, de forma programada y
   bajo demanda.
2. Ingerir los tipos de cambio del día, y el histórico por rango.
3. Normalizar documentos de forma irregular a un modelo propio y estable.
4. Detectar y registrar cambios entre la versión anterior y la nueva.
5. Servir consultas por código, por región, por moneda y por texto libre.
6. Convertir importes entre monedas con el tipo de una fecha dada.
7. Mantener las lecturas calientes en caché, con invalidación al ingerir.
8. Seguir sirviendo —datos ligeramente viejos, pero sirviendo— cuando la fuente
   externa esté caída.
9. Exponer la antigüedad del dato en cada respuesta, para que el consumidor
   decida.
10. Exponer `/health`, `/ready` y `/metrics`.

El punto 8 es la tesis del servicio: **un catálogo de referencia nunca debe
devolver un error porque un tercero esté caído.** Los datos de ayer sirven; un
`503` no.

---

## 5. Entidades

MongoDB, y la justificación está en la forma del dato. Un país de REST Countries
trae nombres en nueve idiomas, monedas anidadas con símbolo y nombre, fronteras
como arreglo, y campos que unos países tienen y otros no. Normalizarlo a diez
tablas para volver a unirlo en cada lectura es trabajo sin destinatario.

### Colección `countries`

```go
type Country struct {
    Code       string            `bson:"_id"`          // ISO alfa-2, la clave natural
    Code3      string            `bson:"code3"`
    Names      map[string]string `bson:"names"`        // idioma -> nombre
    Currencies []Currency        `bson:"currencies"`
    Region     string            `bson:"region"`
    Subregion  string            `bson:"subregion"`
    Timezones  []string          `bson:"timezones"`
    Borders    []string          `bson:"borders"`
    Population int64             `bson:"population"`
    Raw        bson.Raw          `bson:"raw"`          // el documento original, intacto
    SourceETag string            `bson:"source_etag"`
    FetchedAt  time.Time         `bson:"fetched_at"`
    Version    int               `bson:"version"`
}
```

> 💡 El campo `Raw` guarda el documento de origen sin tocar. Cuesta espacio y
> salva el día que alguien pregunta por un campo que no se modeló. Es una
> decisión que en un esquema relacional sería impensable y aquí es barata —y el
> curso dice también cuándo se vuelve un vertedero.

### Colección `fx_rates`

```go
type FxRate struct {
    ID        string             `bson:"_id"`        // "2026-03-04:EUR"
    Date      string             `bson:"date"`
    Base      string             `bson:"base"`
    Rates     map[string]float64 `bson:"rates"`
    FetchedAt time.Time          `bson:"fetched_at"`
}
```

> ⚠️ **`float64` para dinero es un error**, y el curso lo aprovecha: los *tipos de
> cambio* sí son `float64` porque son factores, pero **los importes convertidos
> se calculan con enteros de centavos**. La diferencia se demuestra con un caso
> donde el redondeo se come dos centavos por transacción, y con quinientas mil
> transacciones al día eso es dinero real. ClearingHouse hereda la regla.

### Colección `sync_runs`

Bitácora de cada ingesta: cuándo, de qué fuente, cuántos documentos, cuántos
cambiaron, cuánto tardó, y el error si lo hubo.

---

## 6. API objetivo

```http
GET  /countries?region=&currency=&q=&limit=&cursor=
GET  /countries/{code}
GET  /countries/{code}/neighbors

GET  /fx/latest?base=EUR
GET  /fx/{date}?base=EUR
GET  /fx/convert?from=USD&to=COP&amount=149900&date=2026-03-04

POST /sync/countries          dispara ingesta bajo demanda
POST /sync/fx
GET  /sync/runs

GET  /health · /ready · /metrics
```

Toda respuesta lleva la antigüedad del dato, y eso es parte del contrato:

```json
{
  "data": { "...": "..." },
  "meta": { "fetchedAt": "2026-03-04T06:00:00Z", "ageSeconds": 7320, "stale": false, "cache": "hit" }
}
```

`amount` viaja **en la unidad mínima de la moneda** —centavos— como entero. Es la
misma decisión que toma Stripe y por la misma razón.

---

## 7. Arquitectura objetivo

```text
services/atlassync/
  cmd/atlassync/main.go
  internal/catalog/       dominio: país, moneda, tipo de cambio, conversión
  internal/atlassync/     casos de uso; declara CountryStore, RateStore, Cache, Source
  internal/mongo/         implementación de los almacenes
  internal/cache/         implementación sobre Valkey
  internal/source/        clientes de REST Countries y Frankfurter
  internal/httpapi/
  internal/sync/          orquestación de la ingesta, programada y bajo demanda
  testdata/               respuestas grabadas de las fuentes reales
```

La interfaz que hace posible todo el testing del servicio vive en `atlassync` y
tiene tres métodos:

```go
// Source obtiene datos de referencia de un proveedor externo. La implementación
// real habla por HTTP; la de pruebas lee de testdata/ y no toca la red.
type Source interface {
    Countries(ctx context.Context) ([]catalog.Country, error)
    Rates(ctx context.Context, date time.Time, base string) (catalog.FxRate, error)
    Name() string
}
```

---

## 8. La pirámide de pruebas, que es la razón de ser de este proyecto

Este es **el proyecto donde el curso enseña a probar en serio**, porque es el que
depende de algo que no controla.

**Nivel 1 — unitarios.** La normalización, la conversión de importes, la
selección de nombre por idioma, la lógica de "está viejo pero sirve". Sin E/S,
sin red, sin Mongo, en milisegundos. El doble de `Source` es un fake de treinta
líneas que lee `testdata/`.

**Nivel 2 — componente.** `httptest.Server` sirviendo las respuestas grabadas, y
el cliente real de `internal/source` hablando contra él. Aquí se prueba lo que el
fake no puede: que el cliente maneja el `ETag`, que reintenta el `503`, que
respeta el tiempo límite, que no explota con un JSON truncado. **Sin red.**

**Nivel 3 — integración.** `testcontainers-go` levanta MongoDB y Valkey de
verdad. Se prueban los índices, las agregaciones, el TTL, la invalidación. Build
tag `integration`, objetivo `make test-integration`.

**Nivel 4 — punta a punta.** El servicio completo arrancado en el test, con
MongoDB y Valkey en contenedores y **la fuente externa sustituida por el
`httptest.Server`**. Se ejercita el flujo entero: ingesta → almacenamiento →
consulta → caché → segunda consulta servida desde caché. Es la prueba que
demuestra que "end to end" no significa "depende de internet".

**Nivel 5 — 🔥 contrato, fuera de CI.** Un único test, marcado y excluido, que
golpea la API real y verifica que la forma del JSON sigue siendo la que
`testdata/` supone. Es la alarma de que la fuente cambió, y se corre a mano.

**Y los mocks generados**, aquí sí: `go.uber.org/mock` sobre `Source`, para
verificar que la ingesta llamó una vez y no dos cuando el `ETag` no cambió. Eso
es verificación de interacción y el fake no la da.

---

## 9. Avance por fase

**Fase 10 — nace.** El cliente de REST Countries y Frankfurter, con
`http.Client` bien configurado, tiempos límite, reintentos, `ETag`, y los cinco
niveles de prueba montados de una vez. Almacenamiento todavía en memoria: el
foco de la fase es el mundo exterior.

**Fase 11.** MongoDB: el modelo documental, los índices —incluido el de texto
para la búsqueda libre y el TTL sobre `fx_rates` antiguos—, las agregaciones para
"monedas por región", la actualización con detección de cambios, y la discusión
de incrustar frente a referenciar con `borders` como caso.

**Fase 12.** Valkey: *cache-aside* sobre las lecturas por código, TTL con
*jitter*, `singleflight` contra la estampida, invalidación al terminar una
ingesta, y las métricas de acierto y fallo medidas 📐. Y el experimento que
cierra la fase: cuánto gana realmente la caché aquí, porque a veces la respuesta
es "poco, y acabas de añadir un servicio al `compose.yaml`".

**Fase 13.** La ingesta programada, con su bloqueo para que dos instancias no la
corran a la vez, su punto de control y su bitácora en `sync_runs`.

**Fase 14.** Métricas de antigüedad del dato, alerta cuando la ingesta lleva N
horas fallando, trazas que cruzan al proveedor externo, y el modo degradado
declarado: qué devuelve y con qué cabecera cuando la fuente lleva tres días
caída.

**Fase 15.** Perfilado del camino de lectura, que es el 99% del tráfico: cuánto
cuesta la serialización JSON, cuánto el `Decode` de BSON, cuánto se gana
sirviendo bytes ya codificados desde la caché en vez de codificar en cada
petición 📐.

**Fase 17.** Sirve los tipos de cambio a ClearingHouse en el flujo integrado.

---

## 10. Los temas que este proyecto enseña y los otros no

- **Depender de algo que no controlas**, y que el servicio propio no se degrade
  con él.
- **Modelado documental** con criterio, y el contraejemplo de cuándo no.
- **Caché con invalidación pensada**, que es el problema difícil de verdad.
- **La pirámide de pruebas completa**, con la pregunta que todo el mundo hace en
  una entrevista: *"¿y cómo pruebas eso sin llamar a la API real?"*.
- **Los mocks generados**, con su justificación tardía y honesta.
- **El dinero como entero**, que es una lección que sobrevive al lenguaje.

---

## 11. Qué NO se construye aquí

Autenticación de la API propia, interfaz de administración, resolución de
conflictos entre dos fuentes que se contradicen —queda como ejercicio 🔴—, y
sincronización bidireccional: AtlasSync solo lee de fuera.

---

## 12. Criterio de finalización

1. Ingiere el catálogo completo y los tipos de cambio, programado y bajo demanda.
2. Una segunda ingesta sin cambios upstream no reescribe ningún documento.
3. Sirve por código, región, moneda y texto libre, con paginación por cursor.
4. Convierte importes con aritmética entera y sin perder centavos.
5. Con la fuente externa caída, sigue respondiendo y lo declara en `meta.stale`.
6. La caché invalida al terminar una ingesta, y el acierto medido supera el
   objetivo de su entrada en `BENCHMARKS.md`.
7. La suite completa corre **sin acceso a internet**.
8. El test de contrato 🔥 existe, está excluido de CI y está documentado.
9. `go test -race ./...` y `make test-integration` en verde.
10. Cobertura de `internal/` sobre el umbral.

---

## 13. 📖 El diccionario de este proyecto

| Spring | AtlasSync en Go | Dónde se rompe |
|---|---|---|
| `@FeignClient` | Un struct con `*http.Client` y métodos | No hay interfaz declarativa; escribes la petición, y ves los timeouts |
| `@MockBean` | Un fake que implementa `Source` | No hay contexto de test que sustituya beans; pasas el doble al constructor |
| WireMock | `httptest.Server` con `testdata/` | Sin DSL ni servidor aparte; es un handler en el mismo proceso |
| `MongoRepository` | Una interfaz de 5 métodos + `mongo.Collection` | Sin consultas derivadas del nombre del método; escribes el filtro BSON |
| `@Document` / `@Indexed` | Etiquetas `bson` + creación explícita de índices | El índice no aparece solo: hay una migración que lo crea |
| `MongoTemplate` | El `Collection` del driver oficial | Más cerca del protocolo; menos conversión mágica de tipos |
| `@Cacheable` | `cache-aside` escrito a mano | La invalidación es tuya — que es donde estaban los bugs igualmente |
| `RedisTemplate` | `valkey-go` con comandos tipados | Sin serializador configurable: decides qué bytes escribes |
| `@Scheduled(cron=...)` | `time.Ticker` + bloqueo en almacén | Dos instancias corren dos veces si no lo resuelves tú |
| `BigDecimal` | `int64` de unidades mínimas | No hay tipo decimal en la stdlib, y es a propósito: decides la escala |
MDEOF
wc -l proyecto-03-atlassync.md

# --- 2026-09-12T03:20:38 · Write ClearingHouse project doc
cat > proyecto-04-clearinghouse.md <<'MDEOF'
# 🧾 Proyecto 4 — ClearingHouse Service
## Conciliación y cierre contable por lotes · Meridian Retail Group

> **Eje técnico:** SQLite en el borde, procesamiento por lotes reanudable,
> scheduling, y **el duelo medido contra Spring Boot**.
> **Nace:** Fase 09, ya en **Go moderno** · **Cierra:** Fase 17.
> **Módulos:** `services/clearinghouse` (central) y `services/storeagent` (borde).
> **Binarios:** `clearinghouse`, `storeagent`.
> **Gemelo Java:** `reference/clearinghouse-spring/`, entregado hecho.

---

## 1. El problema

Meridian tiene ciento cuarenta tiendas. Cada una registra movimientos de caja
—ventas, devoluciones, anulaciones, retiros, depósitos— en un punto de venta que
funciona **con o sin red**, porque una tienda no puede dejar de vender porque el
enlace esté caído.

Cada noche hay que conciliar: juntar los movimientos de las ciento cuarenta
tiendas, cruzarlos con lo que reportó la pasarela de pagos y el banco, detectar
descuadres, producir los asientos y cerrar el periodo. Son entre dos y cinco
millones de movimientos por noche, y la ventana es de dos horas.

Hoy lo hace un proceso heredado que tarda tres horas cuando todo va bien, no se
puede reanudar si falla a la mitad, y nadie se atreve a tocar.

**ClearingHouse** son dos piezas: un **agente** que vive en cada tienda,
acumula movimientos en SQLite y los sincroniza cuando hay red; y un **servicio
central** que recibe, concilia por lotes reanudables, produce asientos y cierra
periodos.

---

## 2. Por qué este proyecto existe

Tres razones, y las tres son didácticas:

**Primera: SQLite en el borde tiene sentido de verdad.** No es un ejemplo
forzado. Un agente que corre en un mini-PC de una tienda, sin servidor de base de
datos, que sobrevive a cortes de luz y sincroniza cuando puede, es exactamente el
caso de SQLite — y es también exactamente el caso donde un binario estático de
quince megas gana a un JAR con una JVM.

**Segunda: el lote es el territorio donde Java es fuerte.** Spring Batch resuelve
reanudación, reintento por ítem, particionado y métricas de job. En Go eso se
escribe. El curso lo escribe, mide cuánto cuesta escribirlo, y da un veredicto
honesto — que en este terreno no siempre favorece a Go.

**Tercera: es el servicio del duelo.** ClearingHouse está implementado dos veces
con el mismo esquema, los mismos endpoints y el mismo cierre. La versión Spring
Boot **se entrega hecha** —el lector ya sabe escribirla— y existe para que la
Fase 16 tenga algo real que medir.

---

## 3. Las dos piezas

### 3.1 `storeagent` — el agente de tienda

Una **herramienta de línea de comandos**, y es el sitio donde el curso trabaja el
diseño de CLI en serio.

```bash
storeagent init --store-id ST-042 --db ./agent.db
storeagent record --type sale --amount 149900 --currency COP --ref TKT-889231
storeagent import --file ./pos-export.csv
storeagent status
storeagent sync --server https://clearing.meridian.internal --once
storeagent sync --daemon --interval 5m
storeagent export --from 2026-03-01 --to 2026-03-04 --format csv
```

Guarda en SQLite con WAL activo, marca cada movimiento como pendiente o
sincronizado, reintenta con retroceso, y **nunca borra un movimiento que el
central no haya confirmado**. Se compila para `linux/amd64`, `linux/arm64`,
`darwin/arm64` y `windows/amd64` en un comando, sin runtime que instalar — que es
el argumento comercial de Go resumido en una línea de `make`.

En la Fase 13 se discute `flag` frente a `cobra` con el código delante, y el
veredicto del curso es que `flag` bastaba hasta el cuarto subcomando.

### 3.2 `clearinghouse` — el servicio central

Recibe lotes del agente, valida, deduplica por `(store_id, external_ref)`,
persiste en PostgreSQL, y ejecuta el cierre nocturno.

---

## 4. Entidades

### `Store`

```text
ID, Name, Country, Currency, TimeZone, Active
```

La zona horaria de la tienda **no es decorativa**: el cierre del día 4 de marzo en
Bogotá y en Ciudad de México no cubre el mismo intervalo UTC, y ese es el bug
más caro que este servicio puede tener. La Fase 09 lo trata y hay un ejercicio 🔴
dedicado.

### `Movement`

```text
ID           string
StoreID      string
ExternalRef  string     único por tienda; la clave de idempotencia
Type         string     sale | refund | void | withdrawal | deposit
AmountMinor  int64      en unidades mínimas: 149900 son $1.499,00
Currency     string
OccurredAt   time.Time  hora del punto de venta, con zona
ReceivedAt   time.Time
BatchID      *string
Status       string     received | matched | unmatched | disputed | settled
```

> 🧭 **`AmountMinor int64`, nunca `float64`.** La regla la fija AtlasSync y aquí
> se hereda. Un centavo perdido por redondeo, cinco millones de veces, es
> cincuenta mil unidades monetarias que alguien va a buscar.

### `Batch`

```text
ID, PeriodID, StoreID
Status        pending | running | paused | completed | failed
TotalCount, ProcessedCount, MatchedCount, UnmatchedCount
Checkpoint    string     desde dónde reanudar
StartedAt, FinishedAt, ErrorMessage
```

### `LedgerEntry`

```text
ID, BatchID, MovementID, Account, DebitMinor, CreditMinor, Currency, PostedAt
```

### `Period`

```text
ID, StoreID, Date, Status (open | closing | closed | reopened), ClosedAt, ClosedBy
```

---

## 5. API objetivo

```http
POST /sync/batches                      el agente empuja un lote
GET  /sync/batches/{id}                 acuse y estado

GET  /movements?store=&status=&from=&to=&cursor=
GET  /movements/{id}
POST /movements/{id}/dispute

POST /periods/{storeId}/{date}/close
POST /periods/{storeId}/{date}/reopen
GET  /periods?store=&status=

POST /runs                              lanza un cierre
GET  /runs/{id}                         progreso: procesados, tasa, estimación
POST /runs/{id}/pause
POST /runs/{id}/resume
GET  /runs/{id}/report

GET  /health · /ready · /metrics
```

El endpoint `GET /runs/{id}` devolviendo progreso en vivo es una de las cosas que
Spring Batch da hecho con su `JobRepository` y aquí hay que escribir. Se dice.

---

## 6. El cierre por lotes: la pieza central

Lo que la Fase 13 construye, y el orden importa:

1. **Selección** del universo: movimientos `received` de la tienda y el día, con
   la zona horaria de la tienda aplicada.
2. **Recorrido en *streaming***, con cursor y fragmentos de N filas. Nunca un
   `[]Movement` de cinco millones — y la versión ingenua se escribe primero, se
   mide 📐, y se ve la memoria subir hasta que el proceso muere. Es el 🧨 más
   memorable del curso.
3. **Conciliación** contra el reporte de la pasarela: coincidencia exacta,
   coincidencia por tolerancia, y no coincidencia.
4. **Producción de asientos**, en transacción por fragmento, no por movimiento
   ni por lote entero. La elección del tamaño se discute con números.
5. **Punto de control** tras cada fragmento, en la misma transacción. Es lo que
   hace el lote reanudable, y es lo que Spring Batch te da con `@StepScope`.
6. **Cierre del periodo** si no quedan descuadres, o informe de excepciones si
   los hay.
7. **Informe final** y evento al outbox para que OpsReport lo registre y
   EventRelay lo notifique.

Y las propiedades que se prueban, cada una con su test:

- **Reanudable**: matar el proceso al 60% y relanzarlo produce el mismo resultado
  que no haberlo matado.
- **Idempotente**: correr el cierre dos veces no duplica un solo asiento.
- **Acotado**: la memoria residente no crece con el tamaño del lote.
- **Observable**: el progreso se consulta mientras corre.
- **Cancelable**: una pausa deja el lote en un estado consistente.

---

## 7. El gemelo Spring Boot

`reference/clearinghouse-spring/` contiene la implementación Java: Spring Boot 3,
Spring Web, Spring Data JPA sobre el **mismo esquema PostgreSQL** y las **mismas
migraciones**, Spring Batch para el cierre, Actuator para las métricas.

Tres reglas que lo mantienen honesto:

1. **El mismo esquema y las mismas migraciones.** Si cada versión tuviera su
   modelo, la comparación no valdría nada.
2. **Escrito como lo escribiría un equipo Java competente**, usando lo que Spring
   da. Una versión Java deliberadamente mala para que Go gane sería una estafa
   pedagógica.
3. **No se enseña a escribirlo.** El lector ya sabe. Se entrega, se lee, y se
   mide.

El curso lo usa en dos momentos: en la Fase 13, para comparar el código del lote
lado a lado —y ahí Spring Batch se ve bien, porque lo hace bien—, y en la Fase 16
para el duelo completo.

---

## 8. Avance por fase

**Fase 09 — nace.** `storeagent` con SQLite: esquema, WAL, `record`, `import`,
`status`, `export`. Y la comparación honesta SQLite frente a PostgreSQL: qué
comparten, qué no (tipos flexibles, concurrencia de escritura, `ALTER TABLE`
limitado), y cuándo cada uno. En el central, el modelo PostgreSQL y las
migraciones.

**Fase 10.** `storeagent sync` con el cliente HTTP robusto: lotes, reintento,
retroceso, y la confirmación antes de marcar como sincronizado. Aquí se ve la
diferencia entre "lo mandé" y "lo recibieron".

**Fase 13 ⭐.** El cierre por lotes completo, con sus cinco propiedades probadas.
El planificador. El outbox. Y la comparación con Spring Batch, con el código de
los dos delante.

**Fase 14.** Métricas del lote —filas por segundo, tamaño del fragmento, tiempo
por fase—, trazas del cierre, configuración, y la imagen del agente frente a la
del central.

**Fase 15.** Perfilado del cierre: dónde se va el tiempo de verdad, cuánto cuesta
el `Scan`, cuánto la asignación por fila, y qué gana pre-dimensionar el
fragmento.

**Fase 16 ⭐.** El duelo. Ver `propuesta-fases-y-alcance.md` §3, Fase 16.

**Fase 17.** Integración: el agente sincroniza, el central concilia, OpsReport
registra el trabajo, EventRelay notifica, AtlasSync provee el tipo de cambio.

---

## 9. Qué se mide en la Fase 16

Con el mismo banco, la misma máquina, el mismo esquema y la misma carga:

- Arranque en frío hasta la primera petición servida.
- Memoria residente en reposo y a rendimiento sostenido.
- Latencia p50/p95/p99 y peticiones por segundo en `GET /movements`.
- CPU por petición.
- **El cierre de un millón de movimientos, extremo a extremo.**
- Tamaño de la imagen y tiempo de compilación desde limpio.
- Consumo bajo un pico de diez veces el tráfico normal.
- La JVM en tres configuraciones: por defecto, ajustada, y `native-image`.

Y lo que no sale en un gráfico y decide proyectos igual: líneas de código,
dependencias de tercero, tiempo hasta el primer endpoint funcionando, madurez de
librería por área, y facilidad de contratar.

> ⚖️ **El veredicto tiene que doler un poco en las dos direcciones.** Si el
> resultado de la Fase 16 es "Go gana en todo", la fase está mal escrita.

---

## 10. Qué NO se construye aquí

Contabilidad de verdad —partida doble completa, plan de cuentas, cierre anual—:
el modelo es suficiente para el problema técnico y se dice que es una
simplificación. Tampoco hay interfaz, ni firma digital de asientos, ni
integración bancaria real: el reporte de la pasarela es un CSV que el curso
genera.

---

## 11. Criterio de finalización

1. El agente registra movimientos sin red y sobrevive a un corte de luz.
2. Compila para cuatro plataformas en un comando, sin runtime externo.
3. Sincroniza sin perder ni duplicar movimientos, con red intermitente.
4. El central deduplica por `(store_id, external_ref)`.
5. El cierre de un millón de movimientos entra en la ventana declarada en
   `BENCHMARKS.md`, con memoria acotada.
6. Matarlo al 60% y relanzarlo produce idénticos asientos.
7. Correrlo dos veces no duplica nada.
8. El progreso se consulta mientras corre.
9. Las zonas horarias por tienda son correctas, con test que cruza tres husos.
10. El gemelo Spring Boot corre contra el mismo esquema y pasa los mismos casos.
11. La Fase 16 tiene sus números en `BENCHMARKS.md` y su veredicto escrito.
12. `go test -race ./...` y la suite de integración en verde.

---

## 12. 📖 El diccionario de este proyecto

| Spring | ClearingHouse en Go | Dónde se rompe |
|---|---|---|
| `Job` / `Step` | Una función con su bucle de fragmentos | Sin `JobRepository`: el estado del lote es una tabla tuya |
| `ItemReader` | `sql.Rows` recorrido en streaming | No hay paginación automática; el cursor es tuyo |
| `ItemProcessor` | Una función pura `(Movement) (LedgerEntry, error)` | Aquí Go gana claro: es una función y se prueba como tal |
| `ItemWriter` | Un `INSERT` por lote dentro de la transacción | Sin `flush` automático; decides el tamaño y lo mides |
| `@StepScope` + `ExecutionContext` | Columna `checkpoint` en `batches` | Reanudación escrita a mano — es el mayor coste de no usar Spring Batch |
| `RetryTemplate` por ítem | Clasificación + tabla de excepciones | Sin política declarativa; más código, más visible |
| `JobLauncher` / `JobOperator` | `POST /runs` y un registro en memoria | El control de ejecuciones es tuyo, incluido el "ya hay una corriendo" |
| `@Scheduled` + ShedLock | Ticker + bloqueo en PostgreSQL | Dos instancias: sin bloqueo corren las dos, y aquí eso duele |
| `BigDecimal` | `int64` en unidades mínimas | Sin decimal en la stdlib; la escala es una decisión explícita |
| `picocli` / `CommandLineRunner` | `flag` y, desde el cuarto subcomando, `cobra` | Sin inyección en el comando; el CLI cablea igual que `main` |
| Un JAR + JRE en la tienda | Un binario estático de ~15 MB | Aquí Go gana sin discusión, y la Fase 16 lo mide |
MDEOF
wc -l proyecto-04-clearinghouse.md

# --- 2026-09-12T03:21:28 · Write benchmark format doc
cat > formato-de-benchmarks.md <<'MDEOF'
# 📐 Formato del banco de pruebas
## Go para desarrolladores Java senior — `BENCHMARKS.md`

Regla del repositorio y de este curso: **ninguna afirmación de rendimiento se
escribe sin su entrada aquí.** Vale también para las que parecen obvias —"Go
arranca más rápido", "una goroutine pesa menos que un hilo"—, porque *cuánto* más
rápido y *cuánto* menos es justo lo que el lector necesita para decidir.

Si al escribir una fase necesitas una afirmación y no tienes la medición, tienes
dos salidas honestas: **crear la entrada y medir**, o **no escribir la frase**.
La tercera —escribirla igual y suavizarla con un "suele ser"— no es una salida.

---

## 1. Qué entra en `BENCHMARKS.md`

- Comparaciones **Go frente a Spring Boot** sobre ClearingHouse (Fase 16).
- Comparaciones **entre alternativas dentro de Go**: `database/sql` frente a
  `pgx` nativo, SQL a mano frente a `sqlc` frente a GORM, fake frente a mock
  generado en tiempo de suite, `strings.Builder` frente a concatenación,
  streaming frente a carga completa.
- **Costes del lenguaje**: coste de una goroutine, de una asignación en el
  montículo, de una llamada a través de interfaz, de la serialización JSON.
- **Propiedades de los servicios**: rendimiento de entregas de EventRelay,
  memoria del reporte de OpsReport, tasa de acierto de la caché de AtlasSync,
  ventana del cierre de ClearingHouse.

**No entra** lo que no se midió en el banco del curso. Un número leído en un
artículo se cita como cita, en la sección de referencias de la fase, y nunca como
resultado propio.

---

## 2. Estructura de una entrada

````markdown
## B-{{NN}} — {{Título en una línea, afirmativo}}

**Fase:** {{NN}} · **Proyecto:** {{servicio o mini proyecto}} · **Fecha:** {{AAAA-MM-DD}}

### Hipótesis
{{Una frase falsable, con número y unidad. "pgx en modo nativo reduce la latencia
p95 de la consulta de listado en al menos un 20% frente a database/sql con el
mismo driver" — no "pgx es más rápido".}}

### Condiciones
- **Máquina:** {{CPU, núcleos, RAM, sistema y arquitectura}}
- **Versiones:** Go {{x.y.z}} · {{driver/librería y versión}} · {{JDK y Spring si aplica}}
- **Datos:** {{volumen, forma, cardinalidad}}
- **Carga:** {{concurrencia, duración, calentamiento, herramienta}}
- **Aislamiento:** {{qué más corría, gobernador de CPU, contenedores, límites}}

### Cómo reproducirlo
```bash
{{los comandos exactos, en orden, tal como se ejecutaron}}
```

### Resultados

| Variante | p50 | p95 | p99 | ops/s | B/op | allocs/op | RSS |
|---|---|---|---|---|---|---|---|
| {{A}} | | | | | | | |
| {{B}} | | | | | | | |

{{Para microbenchmarks, la salida de `benchstat` con su delta y su intervalo. Una
sola corrida no es un resultado: mínimo diez, y se dice cuántas.}}

### Veredicto
{{Guía accionable, no un adjetivo. "Usa pgx nativo en las rutas de listado; en el
resto la diferencia no paga el acoplamiento al driver."}}

### Qué NO demuestra
{{Obligatorio. Los límites de la medición: tamaño de datos, ausencia de red,
máquina única, carga sintética. Es lo que separa un benchmark de una consigna.}}
````

---

## 3. Reglas de honestidad

1. **Se prueba a todos los competidores que el curso nombra**, no solo al que
   queremos que gane. Si la fase menciona GORM, GORM se mide.
2. **La JVM se mide ajustada**, no con las opciones por defecto. Comparar Go
   contra una JVM sin calentar ni configurar es hacer trampa, y se nota.
3. **Con calentamiento declarado.** La JVM compila en caliente; ignorarlo es el
   error más común de las comparaciones que circulan por internet.
4. **Mínimo diez corridas** y `benchstat` para los microbenchmarks. Una
   diferencia sin intervalo de confianza es ruido con formato de tabla.
5. **Se publica el resultado incómodo.** Si una optimización no mejoró nada, la
   entrada se escribe igual y la fase la cuenta: *"lo medimos, no cambió, lo
   revertimos"* es una de las lecciones más útiles del curso.
6. **Se declara el hardware.** Un número sin máquina no es reproducible.
7. **Números absolutos y relativos.** "Un 40% más rápido" sin decir de qué a qué
   no sirve para decidir nada.
8. **Nada de extrapolar.** Que el cierre de un millón tarde X no autoriza a
   afirmar cuánto tardaría con diez millones. Si importa, se mide.

---

## 4. Numeración

`B-01`, `B-02`, … en orden de creación, no de fase. Cada entrada se cita desde
la fase con su identificador: *"📐 la caché sube el acierto al 94% (B-17)"*.

Un identificador **nunca se reutiliza**. Si una medición se rehace con otras
condiciones, es una entrada nueva que enlaza a la anterior y dice qué cambió.

---

## 5. Entradas mínimas que el curso necesita

Se listan aquí para que ninguna fase llegue a la afirmación sin la medición
preparada. La fase que las produce las escribe.

| ID | Tema | Fase |
|---|---|---|
| B-01 | Compilación cruzada: mismo binario, cinco plataformas, tiempo y tamaño | 00 |
| B-02 | `strings.Builder` frente a `+=` y `fmt.Sprintf` | 01 |
| B-03 | `regexp` compilado fuera del bucle frente a dentro | 01 |
| B-04 | Slice pre-dimensionado frente a `append` desde cero | 01 |
| B-05 | Coste de una interfaz frente a llamada directa | 02 |
| B-06 | Decodificación JSON completa frente a streaming | 03 |
| B-07 | Coste de arranque de una goroutine frente a un hilo de la JVM | 06 |
| B-08 | Canal con búfer frente a mutex para un contador | 06 |
| B-09 | Worker pool acotado frente a goroutine por tarea, bajo pico | 06 |
| B-10 | `-race`: cuánto cuesta en tiempo y memoria | 06 |
| B-11 | El mismo servicio en 1.13 y en Go moderno: binario, arranque, memoria | 08 |
| B-12 | `ServeMux` moderno frente al enrutado a mano | 08 |
| B-13 | `database/sql` frente a `pgx` nativo | 09 |
| B-14 | SQL a mano frente a `sqlc` frente a GORM | 09 |
| B-15 | Paginación por cursor frente a `OFFSET` a las 100.000 filas | 09 |
| B-16 | SQLite: con WAL y sin WAL, escrituras por segundo | 09 |
| B-17 | AtlasSync: tasa de acierto y latencia con y sin Valkey | 12 |
| B-18 | Caché: bytes precodificados frente a codificar por petición | 12 |
| B-19 | Reporte de 500.000 filas: streaming frente a carga completa | 13 |
| B-20 | Cierre por lotes: tamaño de fragmento frente a tiempo total | 13 |
| B-21 | Imagen de contenedor: Go distroless frente a Spring Boot | 14 |
| B-22 | `GOGC` y `GOMEMLIMIT`: efecto sobre pausas y memoria | 15 |
| B-23 | EventRelay: entregas por segundo contra `fakeconsumer` | 15 |
| B-24 | **El duelo completo**: Go frente a Spring Boot y `native-image` | 16 |
MDEOF
wc -l formato-de-benchmarks.md

# --- 2026-09-12T03:25:56 · Write phase prompts
cat > prompts-extendidos-fases.md <<'MDEOF'
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
- Archivo: `00-ambiente-y-tooling.md` · Horas: **5h**
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
MDEOF
wc -l prompts-extendidos-fases.md

# --- 2026-09-12T03:26:29 · Write course README
cd /Users/oskar/Developer/Learning/courses-ia-generated/go-for-java-devs && cat > README.md <<'MDEOF'
# 🐹 Go para desarrolladores Java senior

Un curso rápido y práctico para quien ya lleva años diseñando sistemas en Java y
quiere escribir Go **que un gopher reconocería como suyo** — no Java con llaves
distintas.

No se explica qué es una variable, un bucle, una API REST ni una transacción. Se
explica, siempre, **dónde el modelo de Go difiere del de Java** y qué reflejo hay
que recalibrar.

---

## 🎯 Qué vas a construir

Cuatro servicios de la plataforma de **Meridian Retail Group**, una empresa
ficticia con ciento cuarenta tiendas y treinta socios integrados por API:

| Servicio | Qué resuelve | Eje técnico |
|---|---|---|
| **OpsReport** | Trabajos operativos y reportes | CRUD, jobs asíncronos, PostgreSQL, streaming |
| **EventRelay** | Webhooks a socios comerciales | Cliente HTTP, reintentos, idempotencia, resiliencia |
| **AtlasSync** | Catálogo de datos de referencia | APIs públicas, MongoDB, Valkey, la pirámide de pruebas completa |
| **ClearingHouse** | Conciliación y cierre por lotes | SQLite en el borde, lotes reanudables, y el duelo contra Spring Boot |

Más veintiocho mini proyectos que aíslan un concepto antes de llevarlo al
servicio grande.

---

## 🕰️ La estructura: dos épocas y una frontera

```text
Bloque A — Fases 00-07   Go 1.13, stdlib pura     El lenguaje sin azúcar
Bloque B — Fase 08 ⭐     La migración              Dos servicios reales migran
Bloque C — Fases 09-17   Go moderno, ecosistema   El Go que vas a escribir
```

Empezar en **Go 1.13** no es nostalgia. Sin genéricos no hay dónde esconder un
diseño perezoso; sin `slog` se ve qué es un log estructurado; sin `ServeMux`
moderno hay que escribir el enrutado a mano una vez, que es la única forma de
entender qué hace Spring MVC por debajo de `@GetMapping`.

Y migrar **a mitad del curso**, no al final, tiene su razón: así más de la mitad
del material transcurre en el Go que de verdad vas a escribir, y la migración
misma es rica, porque migra dos servicios con persistencia, concurrencia y tests
— no un puñado de ejemplos.

---

## 📚 Cómo está escrito

**"Diciendo y haciendo".** Ningún bloque teórico pasa de dos pantallas sin un
comando o un fragmento de código. El ciclo se repite fase tras fase:

```text
el problema → el comando → el código mínimo → ejecútalo → qué observas
  → cómo sería en Java → rómpelo → el test → llévalo al proyecto
```

Cada fase lleva, obligatoriamente:

- 🪞 **Tu instinto de Java dice… y esta vez se equivoca**
- 🩻 **Esto sí funciona igual** — el contrapeso honesto
- ⚰️ **Autopsia de un antipatrón**, con su costo en números
- 🛠️ **CLI de la fase** — el toolchain sin IDE, que es medio Go
- 📖 **Diccionario Java ⇄ Go**, en las dos direcciones
- ⚖️ **Cuándo NO usar esto**
- 🧪 **20 a 30 ejercicios**, un tercio de diagnóstico

Y una regla que gobierna todo el material: **ninguna afirmación de rendimiento se
escribe sin su medición en [`BENCHMARKS.md`](BENCHMARKS.md)** — incluidas las que
parecen obvias.

---

## ⚖️ El veredicto honesto

El curso termina midiendo el mismo servicio implementado dos veces, en Go y en
Spring Boot 3, con la JVM ajustada y con `native-image` — porque comparar contra
una JVM sin configurar es hacer trampa.

Y termina diciendo **dónde quedarse en Spring Boot es la decisión correcta**.
Si el resultado fuera "Go gana en todo", el curso estaría mal escrito.

---

## 🗺️ Por dónde empezar

1. [`0-ESTRUCTURA-CURSO.md`](0-ESTRUCTURA-CURSO.md) — el mapa de las 18 fases
2. [`00-ambiente-y-tooling.md`](00-ambiente-y-tooling.md) — deja la máquina lista
3. De ahí en orden. Las fases se apoyan unas en otras y no se saltan.

Documentos transversales: [`INSTINTOS.md`](INSTINTOS.md) (el catálogo de reflejos
☕), [`BENCHMARKS.md`](BENCHMARKS.md) (el banco de pruebas) y
[`00-convencion-de-git-y-tags.md`](00-convencion-de-git-y-tags.md).

**Requisitos:** ocho años o más de backend en Java, Docker, y un terminal.
**Duración:** 131 horas · unos treinta y tres días de media jornada.
MDEOF
wc -l README.md && ls -la prompts/

# --- 2026-09-12T03:26:38 · Check no references to disposable docs
grep -rn "roadmap-fases-go-java-senior\|enunciado-opsreport\|instrucciones-chatgpt\|proyecto-opcional-eventrelay" prompts/*.md README.md | grep -v '^prompts/_desechable' | grep -v '_desechable-\*'

