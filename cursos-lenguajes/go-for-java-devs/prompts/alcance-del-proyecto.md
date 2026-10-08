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

La historia de la empresa —cómo llegó a existir, quién es quién, los incidentes que
originaron cada servicio y las cifras canónicas— vive en
[`00-historia-de-la-empresa-meridian.md`](../00-historia-de-la-empresa-meridian.md), y es la
**fuente de verdad de todo lo narrativo**. Ninguna fase inventa un número de Meridian
por su cuenta: si le falta uno, se agrega allí primero. Este documento sigue mandando
sobre el dominio y su diccionario.

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

Decisión de estructura declarada: **este curso no tiene apéndices**. Lo que
normalmente sería un apéndice —el detalle del tooling, la tabla de equivalencias,
la comparación con Spring— vive dentro de la fase que lo necesita, porque el formato "diciendo y haciendo" (guía §4) pierde
sentido si el lector tiene que saltar a otro archivo para poder ejecutar el
siguiente comando. El precio es que algunas fases son más largas; se acepta.

```text
go-for-java-devs/
  README.md                      Presentación del curso
  0-ESTRUCTURA-CURSO.md          Mapa de fases, proyectos y dependencias
  00-convencion-de-git-y-tags.md Ramas, tags, prefijos de commit
  00-historia-de-la-empresa-meridian.md  La empresa ficticia: fuente de verdad narrativa
  INSTINTOS.md                   Catálogo de reflejos Java ☕ (índice vivo)
  BENCHMARKS.md                  Banco de pruebas y resultados
  00-instalacion-ambiente-y-tooling.md
  01-...  ...  17-capstone.md    Las 18 fases
  prompts/                       Esta maquinaria
```

Los nombres de fase siguen la convención del curso: `NN-tema.md`,
minúsculas, guiones, dos dígitos.

---

## 10. Entornos de desarrollo

**Anfitrión principal:** macOS en Apple Silicon. **Secundario:** Windows 11 y
Linux. Todo comando del curso se da en su forma POSIX, y cuando la de Windows
difiera de verdad —rutas, variables de entorno, `GOOS`/`GOARCH`— se da también,
en el mismo bloque.

Los servicios de infraestructura —PostgreSQL, MongoDB, Valkey— **no se instalan
en la máquina**: viven en un `compose.yaml` del monorepo que la Fase 00 deja
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
| Apéndices | **No hay** | Todo vive en su fase; decisión de estructura declarada en §9 |
| Comparación con Spring | **Medida**, con banco de pruebas propio | Nace `BENCHMARKS.md` y la Fase 16 |
| Implementación gemela | **ClearingHouse se escribe dos veces**, Go y Spring Boot | Única forma honesta de comparar; el gemelo Java se entrega hecho, no se enseña a escribirlo |
| API externa real | **REST Countries + Frankfurter**, sin clave de API | AtlasSync puede correr en cualquier máquina; en CI va mockeada |
| Base documental | **MongoDB**, en AtlasSync | Justificada por la forma del dato, no por moda |
| Caché | **Valkey** | Se compara con `@Cacheable` + Redis |
| Mocking | **Interfaces pequeñas y fakes primero**; generados solo donde duele | `go.uber.org/mock` entra en la Fase 10, no antes |
| Cobertura | **Medida con umbral en CI**, desde la Fase 04 | El umbral se discute; el número se defiende |
| Ejercicios | **20 mínimo, 24 ideal, hasta 30** en las densas | El rango que fija la guía de estilo del curso |
| CLI | **Eje transversal**, con sección fija en cada fase | El alumno sale sabiendo mover el toolchain sin IDE |
| Diagramas | **Mermaid** (D-12, 05/10/2026, en la revisión del curso) | Árboles de archivos, salidas y correspondencias siguen en `text`; guía §14.1 |
| Gemelo Spring Boot | **Deuda declarada** (05/10/2026): `reference/clearinghouse-spring/` no se publicó | La F16 y el README lo avisan; la fase se lee y se prepara, el duelo espera al gemelo; guía §14.2 |
