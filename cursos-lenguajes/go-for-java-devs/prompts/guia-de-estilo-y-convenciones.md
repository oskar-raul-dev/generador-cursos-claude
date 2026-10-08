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

### 9.2 Las dos secciones que cierran la fase y no cuentan para su extensión

Dos piezas obligatorias quedan **fuera de los presupuestos de la fase** —ni del
conteo de ejercicios de §10, ni de la longitud que se considera al juzgar si una
fase se infló—. Están así a propósito: son las dos que un lector consulta después
de haber terminado, y acotarlas por extensión las empobrecería.

**1. 🔴 Desafíos de cierre** — última subsección de la §8, después de los 🔥.

Tres ejercicios de dificultad alta que **no se numeran** y **no cuentan en el total
declarado** de la sección. Se identifican `D1`, `D2`, `D3`.

Su papel es distinto al de los 🔴 numerados, y esa distinción es lo que justifica
que existan aparte:

- Los 🔴 numerados **consolidan** lo que la fase enseñó y son parte del recorrido.
- Los **desafíos cubren lo que la fase dejó fuera a propósito**: el hueco declarado
  en §3, la comparación que no se hizo, la herramienta que el temario no montó.
  Cada uno debería producir algo que el estudiante se lleve al trabajo.

Reglas:
- **Exactamente tres por fase**, con rúbrica de cuatro a seis puntos cada uno, como
  todo 🔴.
- **No duplican un 🔴 numerado.** Si el desafío se parece a un ejercicio de la
  sección, está mal planteado.
- **Respetan la época de la fase**: un desafío del Bloque A no usa dependencias
  externas ni API posterior a 1.13, salvo marcado 🕰️ y como comparación.
- Van precedidos de una nota en blockquote que diga que no cuentan en el total y
  que no son parte del recorrido base.
- Son un sitio legítimo para **cerrar omisiones declaradas del propio curso** —una
  comparación que se debía y no se hizo, una entrada de `docs/rechazos.md` con
  condición de revisión pendiente—, y cuando lo hacen, se dice.

**2. 📚 Referencias** — la §9 completa.

Obligatoria en toda fase y **nunca se recorta por extensión**. Su estructura está
en §11 y no admite variantes: documentación oficial → libros → artículos y charlas
→ video → orden de lectura sugerido, con la advertencia de versión cuando el
material cubra otra época.

> 🧭 **Regla del proyecto.** Si al revisar una fase hay que quitar contenido por
> longitud, **se quita de la §6, nunca de la §8 ni de la §9**. Los ejercicios y las
> referencias son lo que convierte el documento en material de estudio en vez de en
> un artículo largo.

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

  ### 🔴 Desafíos de cierre        ← fuera del conteo, ver §9.2
  **D1 — …**  **D2 — …**  **D3 — …**
  ```

- **El número entre paréntesis del encabezado cuenta solo los ejercicios
  numerados.** Los 🔥 opcionales y los 🔴 desafíos de cierre quedan fuera, y eso es
  lo que permite que una fase tenga 24 ejercicios del recorrido base y otros siete
  para quien quiera más.

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
- [ ] **El número declarado en el encabezado de §8 coincide con los ejercicios
      numerados**, y los rangos son contiguos y sin huecos.
- [ ] **Lleva los tres 🔴 Desafíos de cierre** (§9.2), con rúbrica, sin duplicar
      ningún ejercicio numerado y respetando la época de la fase.
- [ ] **La §9 Referencias está completa**: documentación oficial, libros, artículos,
      video, orden de lectura, y la advertencia de versión donde toque.
- [ ] El código mostrado compila y los comandos mostrados se pueden ejecutar tal
      cual, en el orden en que aparecen.
- [ ] Referencias con URL completa, con advertencia cuando cubran otra versión.
- [ ] Ninguna comparación se lee como "Spring es malo" (§2).
- [ ] Coherencia de la ficción: nada que afirme sobre Meridian algo que el curso
      no pueda mostrar, y ningún ejercicio que exija un sistema externo o una
      clave de API.
- [ ] Incluye "La señal de que quedó bien" y el bloque 🏷️ del tag (§9.1).
- [ ] Los ☕ nuevos que aparezcan quedan anotados para `INSTINTOS.md`.

---

## 14. Excepciones a los lineamientos del repositorio

> 📝 **Sección agregada el 05/10/2026**, en la revisión del curso contra los lineamientos de
> producción del repositorio. Va después del checklist para no renumerar nada: §13 sigue siendo el
> checklist. Esta guía se escribió antes de que esos lineamientos existieran; lo que aquí se declara
> ya era la práctica del curso, y desde ahora está escrito como decisión.

El `CLAUDE.md` del repositorio da **valores por defecto**, y esta guía los reemplaza donde lo
declara: la regla general, el valor nuevo y por qué. Lo que esta sección no menciona se hereda tal
cual.

| Regla general del repositorio | Lo que hace este curso | Por qué |
|---|---|---|
| Comentarios dentro del código en inglés | **En español, con tildes**, igual que los mensajes de error (§5) | El comentario es el canal del *porqué*, y el curso piensa en español; los identificadores siguen en inglés |
| Apéndices `aNN-` | **Ninguno** (alcance §9) | "Diciendo y haciendo" pierde sentido si hay que saltar a otro archivo para ejecutar el siguiente comando |
| Código ejecutable del curso en `src/` | **No hay `src/` ni `.gitignore` de curso**: el lector construye los cuatro servicios en su propio repositorio (`00-convencion-de-git-y-tags.md`) | El curso enseña a escribirlos; entregarlos hechos le quitaría el ejercicio. La única pieza que sí se entregaría hecha es el gemelo Spring Boot (§14.2) |
| Ninguna salida inventada; lo no ejecutado se marca | **Las salidas de las fases son ilustrativas**, y así se le declara al lector en `0-ESTRUCTURA-CURSO.md` §6 y en el README. Las cifras que cuentan las mide el lector en `BENCHMARKS.md` | Decisión del 05/10/2026: las salidas no se ejecutaron al escribir el curso. Enseñan a leer la herramienta; ninguna sostiene una afirmación |
| Diagramas a criterio de quien escribe | **Mermaid**, salvo árboles de archivos, salidas y correspondencias (D-12, §14.1) | Pedido explícito del autor en la revisión del 05/10/2026 |

### 14.1 D-12 · Diagramas en Mermaid

**Decidido el 05/10/2026 por el autor, en la revisión del curso.** Todo diagrama —arquitectura, flujo,
secuencia, estructura en memoria— va en un bloque `mermaid`, con una frase antes que diga qué mirar.
Quedan en `text` los árboles de archivos, las salidas de terminal, las correspondencias en columnas
(`cpu → ¿dónde se gasta…?`), las listas de pasos con flechas y las líneas de tiempo de un incidente,
que no son diagramas.

La revisión convirtió siete: el slice compartido (F01), cache-aside y su carrera, como
`sequenceDiagram` (F12), la transacción con punto de control y sus dos ventanas de fallo (F13), JVM
frente a Go (F16) y la plataforma del capstone (F17).

### 14.2 Deudas y ausencias declaradas

- **El gemelo Spring Boot no se publicó.** El alcance §13, la historia §7, `proyecto-04-clearinghouse.md`
  y la F16 lo dan por entregado en `reference/clearinghouse-spring/`, y no existe; el alcance §9
  tampoco lo incluye en la estructura. Desde el 05/10/2026 la F16 y el README lo avisan al lector.
  Cuando se escriba, se revisa además la versión: el curso nombra **Spring Boot 3**, y conviene
  medir contra la línea vigente con fecha y fuente.
- **Las versiones no tienen fecha ni fuente** (go1.25.1, PostgreSQL 16, MongoDB 7, Valkey 8). Quedan
  como están; la próxima sesión que toque el curso las verifica antes de cambiar nada.
- **Plan de producción, diccionario de términos, contrato de nombres y README de `prompts/`** no
  existen con esos nombres: el curso es anterior a los lineamientos y está cerrado. Hacen su papel el
  diccionario del dominio del alcance §5.2, los `proyecto-0N-*.md` (nombres de cada servicio) y
  `prompts-extendidos-fases.md` (los prompts de fase).
- **`aprendizaje.md` está en `prompts/`, pero es para el lector**: el método de estudio. Como
  `prompts/` no se publica, si se quiere que el lector lo tenga hay que sacarlo a la raíz del curso.
- **Verificador:** `prompts/verificar-corpus.py`, subclase del perfil `courses-ia` de
  `prompts/verificador_base.py`, con los marcadores y callouts de §8. Se corre desde la raíz del curso
  con `python3 prompts/verificar-corpus.py`.
