# 📈 Fase 15 — Rendimiento, profiling y benchmarking

> Go para desarrolladores Java senior · Fase 15 de 17 · **7 horas**
> Época: **Go moderno (1.25)**
> Depende de: Fase 14 · Habilita: Fase 16
> Proyectos que avanzan: **los cuatro** (perfilado de sus rutas calientes)
> Mini proyectos: `benchstat-lab`, `escape-lab`, `pool-vs-alloc`

---

## 🎯 1. Propósito

Llevas catorce fases midiendo cosas sueltas. Hoy se monta el banco de pruebas en
serio, y con él la disciplina que lo hace útil.

Esta fase tiene dos reglas que se dicen dos veces porque se olvidan las dos:

> 🧭 **Optimizar sin medir es cambiar código al azar.** Y no es una frase bonita:
> la intuición sobre rendimiento en Go acierta menos de la mitad de las veces,
> porque el compilador hace cosas que no ves —*inlining*, escape analysis,
> eliminación de código muerto— y el recolector tiene un comportamiento que no es
> lineal.

> 🧭 **Publica también la optimización que no funcionó.** Es la regla 5 de
> `prompts/formato-de-benchmarks.md`, y en esta fase vas a escribir una de verdad: una
> mejora que parecía obvia, se midió, no cambió nada, y se revirtió. Ese es el
> entregable menos glamuroso y el más honesto.

Al terminar, el banco de pruebas está listo para el duelo de la Fase 16.

---

## ✅ 2. Qué queda listo al terminar

- [ ] Todos los benchmarks del curso usan `b.Loop` y se corren con `-count=10` y
      `benchstat`.
- [ ] Sabes leer un perfil de CPU, uno de heap y uno de goroutines, y distinguir
      cuál responde qué pregunta.
- [ ] Has perfilado las rutas calientes de los cuatro servicios y **has anotado lo
      que te sorprendió**.
- [ ] `-gcflags=-m` te dice por qué una variable escapa, y sabes actuar sobre ello.
- [ ] `sync.Pool` está medido en un caso real, con su advertencia entendida.
- [ ] `GOGC` y `GOMEMLIMIT` están medidos sobre los servicios reales (B-22).
- [ ] EventRelay tiene medido su rendimiento de entregas contra `fakeconsumer`
      (B-23).
- [ ] Las pruebas de carga con `k6` o `vegeta` corren sobre los cuatro servicios y
      son reproducibles.
- [ ] **`docs/optimizaciones-fallidas.md` existe** y tiene al menos una entrada
      real.

---

## 🚫 3. Qué NO entra todavía

- El duelo contra Spring Boot → Fase 16. Aquí se prepara el banco; allí se usa.
- Optimización del recolector a nivel de runtime, arena allocators o
  `unsafe` → fuera del curso.
- Ensamblador y optimizaciones de bajo nivel → fuera del curso.
- Optimización de consultas SQL más allá de lo visto en la Fase 09 → allí quedó.
- Tuning del sistema operativo y de red → fuera del curso; se nombra dónde importa.

---

## 🧠 4. Concepto mínimo

### El método, antes que las herramientas

Cuatro pasos, y saltarse el primero es el error de siempre:

```text
1. MEDIR      → ¿cuál es el número real hoy? Sin esto no hay línea base.
2. PERFILAR   → ¿dónde se va el tiempo o la memoria? Casi nunca donde crees.
3. CAMBIAR    → una cosa, no cinco.
4. VOLVER A MEDIR → ¿mejoró de verdad, o es ruido?
```

Y el paso cero, que es el que más tiempo ahorra:

> 🧭 **Regla del proyecto: define el objetivo antes de optimizar.** *"Hacerlo más
> rápido"* no es un objetivo. *"La latencia p99 de `POST /work-items` por debajo de
> 50 ms con 500 peticiones por segundo"* sí lo es, porque **se puede alcanzar y se
> puede dejar de trabajar en ello**. Sin objetivo, la optimización no termina
> nunca y consume tiempo que valía más en otra parte.

### `testing.B` bien usado

```go
// La forma moderna (Go 1.24+): b.Loop.
func BenchmarkReconcile(b *testing.B) {
	movements := buildMovements(1000)
	svc := newService(b)

	for b.Loop() {
		_ = svc.reconcileAll(movements)
	}
}
```

**`b.Loop` no es azúcar sobre `for i := 0; i < b.N; i++`, y la diferencia importa:**

1. **Evita que el compilador elimine el código medido.** El compilador sabe que el
   resultado no se usa y puede borrar la llamada entera. Con `b.N`, la defensa era
   asignar a una variable global (`sink`), y **si se te olvidaba, medías un bucle
   vacío y no te enterabas**. `b.Loop` lo impide por construcción.
2. **Los parámetros no se evalúan en cada iteración**, así que la preparación no
   contamina.
3. **El cronómetro se gestiona solo**: no hace falta `b.ResetTimer` tras la
   preparación.

```go
// La forma antigua, que vas a seguir viendo en todo el código anterior a 2025:
var sink []LedgerEntry    // ← la defensa contra la eliminación

func BenchmarkReconcileOld(b *testing.B) {
	movements := buildMovements(1000)
	svc := newService(b)

	b.ResetTimer()        // ← no medir la preparación
	b.ReportAllocs()
	for i := 0; i < b.N; i++ {
		sink = svc.reconcileAll(movements)   // ← asignar para que no se elimine
	}
}
```

🧨 **Rompe a propósito, y hazlo ahora:**

```go
func BenchmarkEliminated(b *testing.B) {
	for i := 0; i < b.N; i++ {
		_ = expensiveComputation(42)   // el resultado se descarta
	}
}
```

```text
BenchmarkEliminated-10    1000000000    0.2521 ns/op
```

**0,25 nanosegundos** para una función que hace trabajo real. Eso no es una
optimización: **es que el compilador borró la llamada** y estás midiendo un bucle
vacío. Mil millones de iteraciones a 0,25 ns es la firma inconfundible de este
error, y hay que aprender a reconocerla.

### `benchstat`: por qué una corrida no es un resultado

```bash
go test -run '^$' -bench BenchmarkReconcile -benchmem -count=10 ./internal/batch > new.txt
git stash && go test -run '^$' -bench BenchmarkReconcile -benchmem -count=10 ./internal/batch > old.txt
git stash pop
benchstat old.txt new.txt
```

```text
                │   old.txt   │              new.txt               │
                │   sec/op    │   sec/op     vs base               │
Reconcile-10      1.284m ± 2%   1.019m ± 3%  -20.64% (p=0.000 n=10)

                │   old.txt    │              new.txt               │
                │     B/op     │     B/op      vs base              │
Reconcile-10      412.1Ki ± 0%   198.3Ki ± 0%  -51.88% (p=0.000 n=10)

                │  old.txt   │             new.txt              │
                │ allocs/op  │ allocs/op   vs base              │
Reconcile-10      3.012k ± 0%   1.006k ± 0%  -66.60% (p=0.000 n=10)
```

**Lo que hay que leer, y es lo que casi nadie mira:**

- **`± 2%`** es la variabilidad entre corridas. Si es mayor del 5%, tu máquina tiene
  ruido —otro proceso, ahorro de energía, térmica— y **el resultado no es fiable**.
  Cierra el navegador y repite.
- **`p=0.000`** es el valor p de la prueba estadística. **Si es mayor que 0,05,
  `benchstat` escribe `~` en vez de un porcentaje**, y eso significa *"no hay
  diferencia detectable"*. Un `~` es un resultado válido y hay que publicarlo.
- **`n=10`** son las muestras. Menos de diez y el contraste no tiene potencia.

> 🧭 **Regla del proyecto: una sola corrida no es un resultado.** Mínimo
> `-count=10` y `benchstat`. Una diferencia sin intervalo de confianza es ruido con
> formato de tabla, y una "mejora del 8%" con variabilidad del 12% es una mejora
> imaginaria.

📖 Es exactamente el problema que JMH resuelve en Java con sus *forks*, sus
iteraciones de calentamiento y sus intervalos de confianza. **La diferencia
cultural:** en Java, JMH es obligatorio porque **sin calentamiento mides el
intérprete en vez del código compilado por el JIT**. En Go no hay JIT, así que la
primera iteración ya es código máquina — lo cual hace los benchmarks más simples y
**hace que mucha gente se salte la estadística**, que sigue siendo necesaria por el
ruido del sistema.

### 🪞 Tu instinto de Java dice… y esta vez se equivoca

**El instinto:** *"esto asigna mucho, hay que hacer un pool de objetos"*. En Java es
un reflejo formado por años de experiencia real: la asignación en el TLAB es
barata, pero la presión sobre el recolector en la generación joven es medible, y
los pools de objetos —de buffers, de conexiones, de DTOs— fueron una optimización
estándar durante mucho tiempo.

**Qué pasa si lo aplicas aquí.** Metes `sync.Pool` en la ruta caliente:

```go
// ☕ — el pool que no ayudó
var entryPool = sync.Pool{
	New: func() any { return make([]ledger.Entry, 0, 64) },
}

func (s *Service) reconcileChunk(movements []Movement) []ledger.Entry {
	entries := entryPool.Get().([]ledger.Entry)[:0]
	defer entryPool.Put(entries)     // ☠️ y aquí hay un bug, además

	for _, m := range movements {
		entries = append(entries, s.reconcile(m)...)
	}
	// Devolvemos un slice que acabamos de devolver al pool. Otro goroutine
	// puede sacarlo y sobrescribirlo mientras el llamador lo lee.
	return entries
}
```

Y mides, y no mejora. O mejora un 3% con una variabilidad del 5%, que es `~`.

**Por qué el reflejo falla aquí, y son tres razones concretas:**

1. **El asignador de Go es muy bueno para objetos pequeños.** Tiene cachés por
   procesador lógico (`mcache`) sin contención; asignar un struct pequeño son unas
   pocas instrucciones.
2. **El escape analysis ya evitó la mayoría de las asignaciones que te preocupan.**
   Un objeto que no escapa se asigna **en la pila**, y eso es gratis: no hay
   trabajo de recolección. En Java, **todo objeto va al heap** (el análisis de
   escape de la JVM existe, y es menos determinista y no lo puedes inspeccionar).
   Esa es una diferencia estructural.
3. **`sync.Pool` tiene un coste propio**: un `Get`/`Put` no es gratis, y el pool se
   **vacía en cada recolección**, así que entre ciclos no conserva nada.

**Dónde `sync.Pool` SÍ gana, y es un caso estrecho:**

```go
// Objetos GRANDES, reutilizados con MUCHA frecuencia, con vida CORTA y acotada.
// El caso canónico: buffers de serialización.
//
// Lo usa la propia stdlib en fmt y en encoding/json, y ahí sí se nota.
var bufPool = sync.Pool{
	New: func() any { return new(bytes.Buffer) },
}

func (h *Handler) writeReport(w io.Writer, rows []Row) error {
	buf := bufPool.Get().(*bytes.Buffer)
	buf.Reset()
	defer bufPool.Put(buf)

	// ... escribir en buf ...

	_, err := buf.WriteTo(w)   // el contenido SALE del buffer antes de devolverlo
	return err
}
```

> ⚠️ **Las tres reglas de `sync.Pool`, y romper cualquiera es un bug de
> corrupción de datos:**
> 1. **Lo que sacas hay que resetearlo** antes de usarlo: viene con basura del uso
>    anterior.
> 2. **Lo que devuelves no lo puedes seguir usando.** El bug del ejemplo ☕: se
>    devuelve al pool un slice que el llamador va a leer.
> 3. **El pool se vacía en cada recolección.** No sirve para cachear nada: solo
>    para amortiguar picos dentro de un ciclo.

**Qué pensar en su lugar.** La pregunta no es *"¿cómo reduzco asignaciones?"*, es
**"¿qué dice el perfil?"**. Y en Go, la respuesta suele ser una de estas tres, por
orden de frecuencia:

1. **Una asignación en un bucle que se puede sacar fuera** (pre-dimensionar un
   slice, compilar una expresión regular una vez — B-03 y B-04 de la Fase 01).
2. **Una conversión `string`↔`[]byte` en el camino caliente**, que **siempre
   copia**.
3. **Una interfaz que fuerza el escape** de un valor que si no viviría en la pila.

Ninguna de las tres se arregla con un pool.

### 🩻 Esto sí funciona igual

Esta es, probablemente, la fase donde más se traslada de todo el curso — porque la
metodología de rendimiento no es de un lenguaje:

- **El método completo** —medir, perfilar, cambiar una cosa, volver a medir— es el
  mismo que aplicas con JMH y con un perfilador de la JVM. No hay nada que
  desaprender.
- **Definir el objetivo antes de optimizar.** *"La latencia p99 por debajo de 50 ms
  a 500 peticiones por segundo"* es un objetivo en los dos mundos; *"hacerlo más
  rápido"* no lo es en ninguno.
- **Los percentiles, nunca las medias.** Igual de cierto, y se incumple igual de a
  menudo.
- **La omisión coordinada** afecta a JMeter, a Gatling, a `k6` y a `vegeta` por
  igual. La charla de Gil Tene es de Java y aplica a todo.
- **El análisis de complejidad.** Un algoritmo cuadrático es cuadrático en los dos
  lenguajes, y ese suele ser el problema real antes que cualquier micro-optimización.
- **La sospecha ante la intuición.** El *"yo creo que el cuello de botella está
  aquí"* acierta menos de la mitad de las veces en los dos ecosistemas.
- **Y el orden de magnitud de los cuellos de botella reales:** base de datos, red y
  diseño, por ese orden, muy por delante del lenguaje. El perfil de §6.2 lo
  confirma en Go exactamente igual que lo confirmaría en Java.

Lo que cambia es el instrumental —`pprof` y `benchstat` en vez de JFR y JMH— y dos
cosas de fondo: **no hay calentamiento que esperar**, y **el escape analysis es
inspeccionable**. Nada más.

### Escape analysis: la herramienta que Java no te da

```bash
go build -gcflags='-m' ./internal/batch 2>&1 | grep -v 'inlining'
```

```text
./reconcile.go:34:6:  can inline (*Service).reconcile
./reconcile.go:41:22: leaking param: m
./reconcile.go:47:13: &entry escapes to heap
./reconcile.go:52:24: []ledger.Entry{...} does not escape
./reconcile.go:58:19: ... argument does not escape
```

**Qué significa cada mensaje:**

- **`does not escape`** → se asigna en la **pila**. Gratis: se libera al volver de
  la función, sin trabajo del recolector.
- **`escapes to heap`** → se asigna en el **montículo**. Cuesta la asignación y,
  después, el trabajo de recolección.
- **`leaking param`** → el parámetro sobrevive a la llamada, normalmente porque se
  guarda en algo que escapa.
- **`moved to heap`** → una variable local que el compilador movió al montículo.

**Las cuatro causas de escape que explican casi todos los casos:**

```go
// 1. Devolver un puntero a una variable local.
func newEntry() *Entry {
	e := Entry{}    // moved to heap: necesariamente, el llamador lo va a usar
	return &e
}

// 2. Guardar en una interfaz. ESTA es la que sorprende y la más frecuente.
func log(v any) {}
func caller() {
	x := 42
	log(x)          // x escapes to heap: el compilador no sabe qué hará log con él
}
//
// 📖 Por eso slog.Any() es más caro que slog.Int(): el segundo tiene un tipo
// concreto en la firma y no fuerza el escape.

// 3. Un slice cuyo tamaño no se conoce en compilación.
func build(n int) []byte {
	return make([]byte, n)   // escapa: el tamaño es variable
}
func buildFixed() []byte {
	buf := make([]byte, 64)  // NO escapa si no sale de la función
	return process(buf[:])   // ← pero si sale, escapa
}

// 4. Closures que capturan por referencia.
func handler() func() {
	count := 0
	return func() { count++ }   // count moved to heap
}
```

> 💡 **Que algo escape no es un bug.** El 90% de las asignaciones al montículo son
> correctas y necesarias. Esto es una herramienta de **diagnóstico** para cuando el
> perfil ya te dijo que hay un problema de asignaciones **en un sitio concreto**.
> Ir línea por línea eliminando escapes es la definición de optimización prematura.

### `pprof`: cinco perfiles, cinco preguntas

```text
cpu        → ¿dónde se gasta el TIEMPO DE CPU?
heap       → ¿qué está reservando MEMORIA, y qué la retiene?
goroutine  → ¿cuántas goroutines hay y dónde están BLOQUEADAS?
mutex      → ¿dónde se espera por CONTENCIÓN de locks?
block      → ¿dónde se BLOQUEA el código (canales, locks, red)?
```

El error de método más común: **usar el perfil de CPU para un problema que no es de
CPU**. Si tu servicio está al 3% de CPU y responde lento, el perfil de CPU no te va
a decir nada; el que responde es `block` o `goroutine`.

> ⚠️ **`mutex` y `block` están DESACTIVADOS por defecto** porque instrumentan y
> cuestan. Hay que activarlos explícitamente:
> ```go
> runtime.SetMutexProfileFraction(5)   // muestrea 1 de cada 5 eventos
> runtime.SetBlockProfileRate(10000)   // 1 muestra por cada 10 µs bloqueado
> ```
> Con fracciones razonables el coste es bajo, y **la mayoría de la gente no sabe
> que existen**, así que nunca los usa — y son justo los que responden "el servicio
> está lento y la CPU está ociosa".

---

## 🛠️ 5. CLI de la fase

```bash
# BENCHMARKS
go test -run '^$' -bench . -benchmem ./...
go test -run '^$' -bench BenchmarkReconcile -benchmem -count=10 ./internal/batch

# -benchtime controla cuánto dura cada benchmark. Por defecto 1 s; con "100x"
# se fija el número exacto de iteraciones, que es lo que hace falta para comparar
# algo con efectos secundarios.
go test -run '^$' -bench . -benchtime=5s ./...
go test -run '^$' -bench . -benchtime=1000x ./...

# -cpu ejecuta con distintos GOMAXPROCS. Imprescindible para b.RunParallel.
go test -run '^$' -bench . -cpu=1,2,4,8 ./...

# benchstat: la comparación con estadística.
go install golang.org/x/perf/cmd/benchstat@latest
benchstat old.txt new.txt
benchstat -col /cpu old.txt        # comparar por número de procesadores

# PERFILES desde un benchmark: la forma más limpia, porque el trabajo está
# acotado y es reproducible.
go test -run '^$' -bench BenchmarkReconcile -count=5 \
  -cpuprofile=cpu.out -memprofile=mem.out -blockprofile=block.out \
  ./internal/batch

go tool pprof -http=:8081 cpu.out     # la interfaz web: grafo, llamas, líneas
go tool pprof cpu.out                 # la interactiva
#   (pprof) top20
#   (pprof) top -cum          ← ACUMULADO: incluye lo que llaman las funciones
#   (pprof) list reconcile    ← el código con el tiempo POR LÍNEA
#   (pprof) peek reconcile    ← quién la llama y a quién llama
#   (pprof) web               ← el grafo en el navegador
#   (pprof) traces            ← las pilas completas

# PERFILES de un proceso en marcha, por el puerto de administración de la F14.
go tool pprof -http=:8081 'http://localhost:9090/debug/pprof/profile?seconds=30'
go tool pprof -http=:8081 'http://localhost:9090/debug/pprof/heap'
go tool pprof -http=:8081 'http://localhost:9090/debug/pprof/allocs'
go tool pprof            'http://localhost:9090/debug/pprof/goroutine?debug=2'

# LA COMPARACIÓN DE PERFILES: -base resta uno de otro. Es cómo se ve qué cambió
# de verdad, y casi nadie la usa.
go tool pprof -http=:8081 -base=antes.out despues.out

# heap tiene CUATRO vistas y responden preguntas distintas:
go tool pprof -sample_index=inuse_space  heap.out   # memoria viva AHORA (fugas)
go tool pprof -sample_index=inuse_objects heap.out  # objetos vivos ahora
go tool pprof -sample_index=alloc_space  heap.out   # TOTAL asignado (presión)
go tool pprof -sample_index=alloc_objects heap.out  # total de objetos

# ESCAPE ANALYSIS
go build -gcflags='-m' ./... 2>&1 | grep escapes
go build -gcflags='-m -m' ./internal/batch 2>&1 | head -40   # con el porqué
go build -gcflags='-m' ./... 2>&1 | grep 'cannot inline'      # por qué no hay inlining

# TRAZA DE EJECUCIÓN: lo que pprof no ve. Muestra el planificador, las
# goroutines, las pausas del recolector y los bloqueos, en una línea de tiempo.
go test -run '^$' -bench BenchmarkReconcile -trace=trace.out ./internal/batch
go tool trace trace.out

# Y desde un proceso vivo:
curl -o trace.out 'http://localhost:9090/debug/pprof/trace?seconds=5'
go tool trace trace.out

# EL RECOLECTOR
GODEBUG=gctrace=1 ./bin/clearinghouse close --day 2026-09-11 2>&1 | head -20
GOGC=200 GOMEMLIMIT=1GiB ./bin/opsreport

# CARGA
brew install k6 vegeta   # o la instalación de tu sistema

echo "GET http://localhost:8080/work-items" | \
  vegeta attack -rate=500 -duration=60s | vegeta report
echo "GET http://localhost:8080/work-items" | \
  vegeta attack -rate=500 -duration=60s | vegeta encode | \
  vegeta plot > plot.html

k6 run --vus 50 --duration 60s scripts/load/opsreport.js

# CLIENTE HTTP: lo que pprof tampoco ve, porque el tiempo no se gasta en tu CPU.
# httptrace instrumenta el ciclo de vida de UNA petición: DNS, conexión, TLS,
# si reutilizó una conexión del pool, y cuánto tardó el primer byte.
go run ./labs/client-timeouts -trace -url https://api.frankfurter.app/latest

# Y el comando que evita la mitad de las mediciones malas: comprobar que la
# máquina está quieta antes de medir.
uptime                              # la carga media debería estar cerca de 0
pmset -g thermlevel 2>/dev/null     # macOS: nivel térmico
```

> 💡 **`httptrace` es el perfilador del lado cliente, y aquí es donde toca usarlo
> en serio.** La Fase 10 lo presentó para contar conexiones nuevas; en esta fase
> responde la pregunta que el perfil de CPU no puede responder: **por qué una
> llamada al socio tarda 400 ms cuando el socio dice que responde en 30.** La
> respuesta casi siempre está en `GotConn.Reused == false` —el pool no reutiliza y
> cada petición paga DNS más TLS— y eso no aparece en ningún perfil, porque el
> proceso está esperando, no trabajando.
>
> ```go
> ctx := httptrace.WithClientTrace(ctx, &httptrace.ClientTrace{
>     GotConn: func(i httptrace.GotConnInfo) {
>         log.Printf("reused=%v idle=%v idleFor=%v", i.Reused, i.WasIdle, i.IdleTime)
>     },
>     TLSHandshakeDone: func(cs tls.ConnectionState, err error) {
>         log.Printf("tls listo: %v", err)
>     },
> })
> ```
>
> ⚠️ **No lo dejes puesto en producción.** El `ClientTrace` se llama en el camino
> caliente de cada petición; es una herramienta de diagnóstico, no de
> observabilidad continua. Para lo continuo están las métricas de la Fase 14.

> 💡 **`top -cum` frente a `top`.** `top` ordena por tiempo **propio** de cada
> función; `top -cum`, por tiempo **acumulado** incluyendo a quienes llama. Con
> `top` ves las hojas —`runtime.memmove`, `syscall.Syscall`— que rara vez son
> accionables. Con `top -cum` ves **qué operación de negocio** consume el tiempo,
> que es la pregunta real. Empieza siempre por `-cum`.

---

## 💻 6. Construcción guiada

### 6.1 Mini proyecto: `benchstat-lab`

Escribir benchmarks que no mientan, que es más difícil de lo que parece.

```go
// labs/benchstat-lab/pitfalls_test.go

// TRAMPA 1: el código eliminado (el 🧨 de §4).
func BenchmarkEliminated(b *testing.B) {
	for i := 0; i < b.N; i++ {
		_ = fibonacci(20)          // ❌ eliminado por el compilador
	}
}
func BenchmarkNotEliminated(b *testing.B) {
	for b.Loop() {
		_ = fibonacci(20)          // ✅ b.Loop lo impide
	}
}

// TRAMPA 2: medir la preparación.
func BenchmarkWithSetup(b *testing.B) {
	for i := 0; i < b.N; i++ {
		movements := buildMovements(1000)   // ❌ esto se mide también
		_ = reconcileAll(movements)
	}
}
func BenchmarkSetupOutside(b *testing.B) {
	movements := buildMovements(1000)
	for b.Loop() {                          // ✅ la preparación queda fuera
		_ = reconcileAll(movements)
	}
}

// TRAMPA 3: el estado que se acumula entre iteraciones.
func BenchmarkAccumulating(b *testing.B) {
	var all []ledger.Entry
	for b.Loop() {
		all = append(all, reconcileAll(movements)...)   // ❌ crece y crece
	}
	// La iteración 1000 mide un append sobre un slice de un millón: no mide
	// la función, mide el crecimiento del slice.
}

// TRAMPA 4: la caché caliente.
func BenchmarkCacheWarm(b *testing.B) {
	svc := newServiceWithCache(b)
	for b.Loop() {
		_, _ = svc.Country(ctx, "COL")   // ❌ la primera llena la caché; el resto
	}                                     //    mide un acceso a un mapa
}
// Medir el camino que quieres: o siempre acierto, o siempre fallo, no una mezcla
// dominada por el acierto.

// TRAMPA 5: comparar cosas que no son comparables.
func BenchmarkApplesOranges(b *testing.B) {
	b.Run("streaming", func(b *testing.B) {
		for b.Loop() { streamReport(io.Discard, 1000) }   // 1.000 filas
	})
	b.Run("buffered", func(b *testing.B) {
		for b.Loop() { bufferedReport(io.Discard, 10000) } // ❌ 10.000 filas
	})
}

// TRAMPA 6: no declarar el tamaño del problema en el nombre.
// Un "BenchmarkReconcile" sin decir cuántos movimientos no se puede reproducir
// ni comparar con nada.
func BenchmarkReconcile(b *testing.B) {
	for _, n := range []int{10, 100, 1000, 10000} {
		b.Run(fmt.Sprintf("movements=%d", n), func(b *testing.B) {
			movements := buildMovements(n)
			// SetBytes permite que el resultado incluya MB/s, que normaliza
			// entre tamaños y hace comparables las filas de la tabla.
			b.SetBytes(int64(n * approxMovementSize))
			for b.Loop() {
				_ = reconcileAll(movements)
			}
		})
	}
}
```

> 🧪 **Prueba de fuego.** Corre `BenchmarkEliminated` y `BenchmarkNotEliminated` y
> mira la diferencia: varios órdenes de magnitud.
>
> **La mentira de la pantalla:** el primero **no da error, no da aviso, y produce
> un número precioso**. Un equipo que optimice basándose en él va a "mejorar" cosas
> que nunca se ejecutaron. La señal a reconocer: **mil millones de iteraciones y
> menos de un nanosegundo por operación.**

**Y el guion que hace las mediciones reproducibles:**

```bash
#!/usr/bin/env bash
# scripts/bench.sh — mide, compara y deja constancia.
set -euo pipefail

PKG="${1:?uso: bench.sh <paquete> <patrón>}"
PATTERN="${2:-.}"
COUNT="${COUNT:-10}"

# Las condiciones se registran CON el resultado: sin ellas, el número no
# significa nada dentro de seis meses.
{
  echo "# fecha:    $(date -u +%Y-%m-%dT%H:%M:%SZ)"
  echo "# commit:   $(git rev-parse --short HEAD)"
  echo "# go:       $(go version)"
  echo "# máquina:  $(uname -srm)"
  echo "# cpu:      $(sysctl -n machdep.cpu.brand_string 2>/dev/null || lscpu | grep 'Model name')"
  echo "# carga:    $(uptime | sed 's/.*load/load/')"
  echo "# count:    $COUNT"
} > "bench-$(git rev-parse --short HEAD).txt"

go test -run '^$' -bench "$PATTERN" -benchmem -count="$COUNT" "$PKG" \
  | tee -a "bench-$(git rev-parse --short HEAD).txt"
```

### 6.2 Perfilar los servicios de verdad

**El método, aplicado a OpsReport:**

```bash
# 1. Carga sostenida y realista.
vegeta attack -targets=scripts/load/opsreport.txt -rate=300 -duration=120s > results.bin &

# 2. Perfil mientras corre.
go tool pprof -http=:8081 'http://localhost:9090/debug/pprof/profile?seconds=30'
```

**Lo que hay que mirar, en orden:**

```text
(pprof) top -cum 15
```

```text
      flat  flat%   sum%        cum   cum%
     0.02s  0.11%  0.11%     17.84s 95.02%  net/http.(*conn).serve
     0.01s 0.053%  0.16%     16.91s 90.07%  meridian/httpapi.(*WorkItemHandler).list
     0.03s  0.16%  0.32%     11.22s 59.76%  meridian/opsreport.(*Service).Queue
     0.01s 0.053%  0.37%      9.87s 52.57%  meridian/postgres.(*Store).ListByStatus
     4.21s 22.42% 22.79%      6.44s 34.30%  encoding/json.(*Encoder).Encode
     2.98s 15.87% 38.66%      2.98s 15.87%  runtime.mallocgc
     1.87s  9.96% 48.62%      1.87s  9.96%  runtime.memmove
```

**Tres lecturas, y la tercera es la que enseña:**

1. **`Encode` es el 34% acumulado y el 22% propio.** La serialización JSON domina.
2. **`mallocgc` es el 16%.** Se está asignando mucho, y `Encode` es el sospechoso.
3. **Y lo que NO está:** la consulta a PostgreSQL es el 52% acumulado pero su
   tiempo propio es 0,05%. **Está esperando E/S, no quemando CPU.** El perfil de
   CPU no mide espera, y confundir las dos cosas es el error de lectura más común.

```text
(pprof) list list
```

```go
ROUTINE ======================== httpapi.(*WorkItemHandler).list

         .          .     78:   items, err := h.svc.Queue(r.Context())
         .     11.22s     79:   if err != nil {
         .          .     80:       writeError(w, r, err)
         .          .     81:       return
         .          .     82:   }
         .          .     83:
         .      2.11s     84:   out := make([]workItemJSON, 0, len(items))
         .      3.98s     85:   for _, item := range items {
      1.02s     2.87s     86:       out = append(out, toJSON(item, now))
         .          .     87:   }
         .      6.44s     88:   writeJSON(w, http.StatusOK, listResponse{Items: out})
```

**El tiempo por línea.** La conversión al tipo de salida (líneas 84–86) cuesta 8,96
s y la serialización 6,44 s. **Ese es el sitio donde actuar**, y sin el perfil
habrías optimizado la consulta.

> 🧪 **Prueba de fuego.** Antes de perfilar, **escribe tu predicción**: ¿dónde crees
> que se va el tiempo? Después perfila. Guarda las dos cosas.
>
> **La mentira de la pantalla:** si acertaste, comprueba que no estás leyendo el
> perfil buscando lo que esperabas — `top` sin `-cum` y `top -cum` dan historias
> distintas del mismo perfil. Y si fallaste, has aprendido más que optimizando.
> **Este ejercicio es el 24 y merece hacerse de verdad.**

### 6.3 Mini proyecto: `escape-lab`

```go
// labs/escape-lab/escape.go

// CASO 1: la interfaz que fuerza el escape.
func FormatDirect(n int) string {
	return strconv.Itoa(n)            // no escapa
}
func FormatSprintf(n int) string {
	return fmt.Sprintf("%d", n)       // n escapes to heap: any lo fuerza
}
// Diferencia medida: tres o cuatro veces en tiempo, y una asignación frente a
// cero. Por eso strconv es preferible a fmt en caminos calientes, y por eso
// slog.Int() es preferible a slog.Any().

// CASO 2: el slice que se puede pre-dimensionar.
func BuildGrow(n int) []Entry {
	var out []Entry                   // escapa, y crece: log2(n) asignaciones
	for i := 0; i < n; i++ {
		out = append(out, Entry{ID: i})
	}
	return out
}
func BuildPresized(n int) []Entry {
	out := make([]Entry, 0, n)        // escapa (se devuelve), pero UNA asignación
	for i := 0; i < n; i++ {
		out = append(out, Entry{ID: i})
	}
	return out
}
// Es B-04 de la Fase 01, ahora con la explicación completa del porqué.

// CASO 3: string ↔ []byte, que SIEMPRE copia.
func CountBytes(s string) int {
	b := []byte(s)                    // COPIA: los strings son inmutables
	return len(b)
}
func CountDirect(s string) int {
	return len(s)                     // sin copia
}
//
// ⚠️ Y la excepción que el compilador SÍ optimiza y conviene conocer:
//   - m[string(b)]      → no copia: el compilador lo detecta
//   - for i, r := range string(b) → tampoco
//   - []byte(s) en una llamada que no retiene → a veces tampoco
// Verifícalo con -gcflags=-m antes de dar nada por hecho.

// CASO 4: el buffer reutilizado frente al nuevo.
func WriteNew(rows []Row) string {
	var sb strings.Builder            // no escapa si no sale
	for _, r := range rows {
		sb.WriteString(r.String())
	}
	return sb.String()                // el string SÍ escapa: es el resultado
}

// CASO 5: el método con receptor por puntero en un bucle caliente.
type Counter struct{ n int64 }
func (c *Counter) IncPtr()  { c.n++ }
func (c Counter) IncVal() Counter { c.n++; return c }
// Con receptor por puntero, si el Counter es local y no escapa, el compilador
// lo mantiene en la pila igualmente. La intuición de "puntero = heap" es FALSA
// en Go, y es una de las cosas que más sorprende a quien viene de C.
```

```bash
go build -gcflags='-m' ./labs/escape-lab 2>&1 | grep -E 'escapes|does not escape'
go test -run '^$' -bench . -benchmem -count=10 ./labs/escape-lab | tee escape.txt
benchstat escape.txt
```

### 6.4 Mini proyecto: `pool-vs-alloc`

**La medición que decide si el reflejo de Java aplica.**

```go
// labs/pool-vs-alloc/pool_test.go

// Tres tamaños de objeto × tres estrategias. El tamaño es la variable que
// decide, y es lo que la intuición no captura.
func BenchmarkAllocation(b *testing.B) {
	sizes := map[string]int{
		"small_64B":  64,
		"medium_4KB": 4 << 10,
		"large_1MB":  1 << 20,
	}

	for name, size := range sizes {
		b.Run(name+"/new", func(b *testing.B) {
			for b.Loop() {
				buf := make([]byte, size)
				use(buf)
			}
		})

		b.Run(name+"/pool", func(b *testing.B) {
			pool := sync.Pool{New: func() any {
				buf := make([]byte, size)
				return &buf
			}}
			for b.Loop() {
				p := pool.Get().(*[]byte)
				use(*p)
				pool.Put(p)
			}
		})

		// Y la tercera, que casi nadie considera y suele ganar: reutilizar una
		// variable local, sin pool, cuando el ámbito lo permite.
		b.Run(name+"/reused", func(b *testing.B) {
			buf := make([]byte, size)
			for b.Loop() {
				use(buf)
			}
		})
	}
}

// Y el caso realista, que es donde el resultado cambia: CON concurrencia.
// sync.Pool tiene cachés por procesador lógico, así que su ventaja aparece
// bajo contención, no en un bucle de una sola goroutine.
func BenchmarkAllocationParallel(b *testing.B) {
	b.Run("new", func(b *testing.B) {
		b.RunParallel(func(pb *testing.PB) {
			for pb.Next() {
				buf := make([]byte, 4<<10)
				use(buf)
			}
		})
	})
	b.Run("pool", func(b *testing.B) {
		pool := sync.Pool{New: func() any { buf := make([]byte, 4<<10); return &buf }}
		b.RunParallel(func(pb *testing.PB) {
			for pb.Next() {
				p := pool.Get().(*[]byte)
				use(*p)
				pool.Put(p)
			}
		})
	})
}
```

> 📐 **Lo que la medición debería mostrar, y hay que verificarlo en vez de
> creérselo:** con objetos pequeños, `sync.Pool` **pierde** frente a `make` —el
> coste de `Get`/`Put` supera al de asignar—. Con objetos grandes y concurrencia,
> gana claramente. **El umbral está en tu hardware y hay que encontrarlo**, que es
> el ejercicio 12.
>
> Y el resultado que más enseña: **`reused` gana a los dos** cuando el ámbito lo
> permite. La optimización más barata casi nunca es un pool: es no necesitarlo.

### 6.5 `GOGC` y `GOMEMLIMIT`

```text
GOGC=100 (por defecto):
  El recolector arranca cuando el heap vivo crece un 100% desde la última
  recolección. Con 100 MB vivos, recolecta al llegar a 200 MB.

GOGC=200:
  Recolecta la mitad de veces → menos CPU en recolección, más memoria usada.

GOGC=50:
  Recolecta el doble → menos memoria, más CPU.

GOGC=off:
  No recolecta. Solo tiene sentido en procesos efímeros y muy medidos.

GOMEMLIMIT=1GiB:
  Un límite SUAVE. Al acercarse, el recolector se vuelve agresivo sin importar
  GOGC. Es la respuesta de Go a los contenedores con límite de memoria, y llegó
  en 1.19.
```

> 🧭 **La combinación que recomienda el equipo de Go, y es contraintuitiva:**
> **`GOGC=off` (o muy alto) junto con `GOMEMLIMIT` ajustado.**
>
> La idea: no recolectar por proporción, sino **usar toda la memoria disponible y
> recolectar solo cuando haga falta**. En un contenedor con 1 GiB asignado, eso
> aprovecha el presupuesto entero en vez de recolectar innecesariamente al 200% de
> un heap vivo pequeño.
>
> ⚠️ **Y el riesgo, que hay que decir:** con `GOGC=off`, si el límite se alcanza de
> verdad, el recolector entra en modo agresivo permanente y el proceso se vuelve
> lentísimo —el síntoma del 🧨 de la Fase 13—. **`GOMEMLIMIT` se pone por debajo
> del límite del contenedor**, con margen para la memoria que no es del heap
> (pilas, el propio runtime, mapeos), y un ~90% es un punto de partida razonable.

```bash
GODEBUG=gctrace=1 ./bin/clearinghouse close --day 2026-09-11 2>&1 | head -5
```

```text
gc 1 @0.021s 2%: 0.018+1.2+0.005 ms clock, 0.18+0.35/1.1/0.61+0.05 ms cpu, 4->4->2 MB, 5 MB goal, 0 MB stacks, 0 MB globals, 10 P
```

**Cómo se lee, campo a campo:**

```text
gc 1         → número de recolección
@0.021s      → cuándo, desde el arranque
2%           → PORCENTAJE DE CPU ACUMULADO gastado en recolección ← el número clave
0.018+1.2+0.005 ms clock → las tres fases: barrido inicial + concurrente + final
4->4->2 MB   → heap al empezar -> al terminar -> VIVO tras la recolección
5 MB goal    → cuándo se disparará la siguiente
10 P         → procesadores lógicos
```

> 💡 **El porcentaje de CPU en recolección es el número que decide si merece la pena
> tocar `GOGC`.** Por debajo del 5% no hay nada que ganar. Por encima del 20%, hay
> un problema —normalmente de asignaciones, no de configuración del recolector—. En
> Java, el equivalente es lo que te da `-XX:+PrintGCDetails` y las herramientas de
> análisis de GC.

> 📐 **Cómo se mide.** Entrada **B-22**: *`GOGC` y `GOMEMLIMIT`: efecto sobre pausas
> y memoria*. Sobre **dos** cargas distintas, porque el resultado depende
> enteramente de eso: OpsReport bajo carga HTTP sostenida (muchos objetos pequeños
> y de vida corta) y el cierre de ClearingHouse (pocos objetos grandes y de vida
> media).
>
> Se miden `GOGC` en 50, 100, 200, 400 y `off`, con y sin `GOMEMLIMIT`, reportando:
> porcentaje de CPU en recolección, memoria residente máxima, latencia p99, y
> **pausa máxima de recolección**.
>
> **La hipótesis honesta:** *"para la carga HTTP, `GOGC=200` reduce el tiempo de
> recolección por debajo del 3% sin que la memoria residente crezca de forma
> problemática; para el lote, el efecto es menor porque las asignaciones son pocas
> y grandes"*. Y el veredicto debe decir explícitamente **cuándo no tocar nada**,
> que es el caso mayoritario.

### 6.6 El recolector de Go frente al de la JVM

**Dos filosofías distintas, y ningún ganador.**

| | Go | JVM (G1, el valor por defecto) |
|---|---|---|
| Algoritmo | marcado y barrido concurrente, **sin compactación** | generacional, **con compactación**, por regiones |
| Objetivo de diseño | **pausas por debajo del milisegundo** | rendimiento máximo, pausas acotadas |
| Generacional | **no** | sí (joven/vieja) |
| Compacta y desfragmenta | **no** | sí |
| Mueve objetos | **no** | sí |
| Perillas | **2** (`GOGC`, `GOMEMLIMIT`) | **decenas** |
| Elección de recolector | **ninguna** | G1, ZGC, Shenandoah, Parallel, Serial |
| Coste de una asignación | muy bajo (caché por procesador) | muy bajo (TLAB) |
| Fragmentación | **posible** | se resuelve compactando |
| Objetos que no escapan | **en la pila** (verificable con `-gcflags=-m`) | análisis de escape del JIT, no inspeccionable |

**Lo que cada uno hace mejor, honestamente:**

**Go gana en previsibilidad.** Las pausas son consistentemente cortas y **no hay
que ajustar nada**. Un servicio Go con la configuración por defecto tiene pausas de
recolección de decenas de microsegundos, y esa es una propiedad valiosísima para un
servicio con objetivos de latencia. La ausencia de perillas es una ventaja: no hay
veinte parámetros que alguien pueda poner mal.

**La JVM gana en rendimiento bruto y en madurez de análisis.** Un recolector
generacional aprovecha que la mayoría de los objetos mueren jóvenes, y para cargas
con muchísima asignación de objetos efímeros eso es medible. Y **ZGC y Shenandoah
tienen pausas comparables a las de Go** con heaps de cientos de gigas, donde Go no
está tan probado. Además, la JVM **compacta**: un proceso Go de larga duración con
un patrón de asignación adverso puede fragmentar el heap y no tiene forma de
resolverlo.

**Y lo que no es del recolector y se le atribuye:** en Go, muchos objetos **nunca
llegan al heap** gracias al escape analysis, así que hay menos trabajo que hacer
desde el principio. Eso no es mérito del recolector; es del compilador y del modelo
de valores (Fase 01).

> ⚖️ **Sin ganador, con criterio.** Si tu objetivo es latencia predecible sin
> dedicar a nadie a ajustar el recolector, Go llega antes. Si tienes heaps enormes,
> un equipo que sabe leer un registro de recolección, y necesitas exprimir el
> rendimiento, la JVM te da más herramientas. **Y para la mayoría de los servicios,
> ninguna de las dos cosas es el cuello de botella** — lo es la base de datos o la
> red, que es lo que el perfil de §6.2 mostró.

### 6.7 Las pruebas de carga

```javascript
// scripts/load/opsreport.js
import http from 'k6/http';
import { check, sleep } from 'k6';
import { Trend, Rate } from 'k6/metrics';

const createDuration = new Trend('create_duration');
const errorRate = new Rate('errors');

export const options = {
  // Las ETAPAS importan: una carga que salta de 0 a 500 mide el arranque en
  // frío, no el régimen estacionario. La rampa es lo que se parece a la
  // realidad.
  stages: [
    { duration: '30s', target: 100 },   // rampa
    { duration: '2m',  target: 100 },   // ← el régimen estacionario: lo que se mide
    { duration: '30s', target: 500 },   // pico
    { duration: '1m',  target: 500 },
    { duration: '30s', target: 0 },     // bajada: verifica que se recupera
  ],
  thresholds: {
    // Los umbrales convierten la prueba en un test: falla si no se cumplen.
    'http_req_duration{name:list}':   ['p(99)<100'],
    'http_req_duration{name:create}': ['p(99)<200'],
    'errors': ['rate<0.01'],
  },
};

export default function () {
  const list = http.get('http://localhost:8080/work-items?limit=50',
    { tags: { name: 'list' } });
  check(list, { 'list 200': (r) => r.status === 200 }) || errorRate.add(1);

  // El cuerpo varía por iteración: si fuera constante, la caché y el plan de
  // consulta lo servirían todo y medirías el mejor caso.
  const payload = JSON.stringify({
    external_reference: `SAP-2026-${__VU}-${__ITER}`,
    kind: 'import',
    priority: (__ITER % 9) + 1,
  });
  const create = http.post('http://localhost:8080/work-items', payload,
    { headers: { 'Content-Type': 'application/json' }, tags: { name: 'create' } });

  check(create, { 'create 201': (r) => r.status === 201 }) || errorRate.add(1);
  createDuration.add(create.timings.duration);

  sleep(0.1);
}
```

> ⚠️ **Los cuatro errores que invalidan una prueba de carga**, y los cuatro son de
> método:
> 1. **Medir desde la misma máquina que ejecuta el servicio.** El generador de
>    carga compite por CPU con lo que mide. Con `k6` a 500 peticiones por segundo
>    en un portátil, una parte de la latencia es tuya.
> 2. **No calentar.** Las primeras peticiones pagan conexiones nuevas, planes de
>    consulta y cachés frías. **La rampa existe por eso.**
> 3. **Mirar la media.** La media esconde la cola. El p99 es lo que sufre el 1% de
>    tus usuarios, que con un millón de peticiones son diez mil personas.
> 4. **Y el más sutil: la omisión coordinada.** Si el generador espera la respuesta
>    antes de mandar la siguiente, **cuando el servidor se ralentiza el generador
>    manda menos carga**, y la latencia medida es mejor que la real. `vegeta` con
>    `-rate` fijo evita esto; `k6` con usuarios virtuales y `sleep` no del todo.
>    **Es la razón por la que las pruebas de carga suelen ser optimistas.**

> 📐 **Cómo se mide.** Entrada **B-23**: *EventRelay, entregas por segundo contra
> `fakeconsumer`*. Se usa `fakeconsumer` —el binario de la Fase 05— con sus cuatro
> comportamientos, y se mide con `/ok` (el mejor caso), con `/flaky` (30% de
> fallos, el caso realista) y con `/slow`.
>
> Se reporta rendimiento sostenido, latencia p50/p95/p99 de entrega, tasa de
> reintento y uso de CPU y memoria. **Y el número que de verdad importa: cuántas
> entregas por segundo antes de que la latencia p99 se dispare**, que es la
> capacidad real del servicio.

### 6.8 El entregable incómodo: la optimización que no funcionó

**Esta sección es obligatoria y produce un archivo.**

La regla 5 de `prompts/formato-de-benchmarks.md`: *"se publica el resultado incómodo. Si
una optimización no mejoró nada, la entrada se escribe igual y la fase la cuenta:
'lo medimos, no cambió, lo revertimos' es una de las lecciones más útiles del
curso"*.

```markdown
# docs/optimizaciones-fallidas.md

## `sync.Pool` para los buffers de conversión a JSON en OpsReport

**Hipótesis.** El perfil de `GET /work-items` (§6.2) mostró que
`json.Encoder.Encode` es el 34% del tiempo acumulado y `runtime.mallocgc` el 16%.
Reutilizar el slice de `workItemJSON` con `sync.Pool` debería reducir las
asignaciones y bajar la presión sobre el recolector.

**Qué se cambió.** `sync.Pool` de `[]workItemJSON` con capacidad inicial de 64,
`Get`/`Put` en el handler de listado.

**Medición.** `-count=10`, `benchstat`, carga de `vegeta` a 300 peticiones por
segundo durante 120 s, en la máquina de referencia.

| | antes | después | delta |
|---|---|---|---|
| `ns/op` | 84.2µ ± 3% | 81.7µ ± 4% | ~ (p=0.19) |
| `B/op` | 41.2Ki ± 0% | 38.9Ki ± 0% | −5,6% (p=0.000) |
| `allocs/op` | 312 ± 0% | 308 ± 0% | −1,3% (p=0.000) |
| CPU en recolección (`gctrace`) | 3,1% | 3,0% | ~ |
| p99 bajo carga | 47 ms | 48 ms | ~ |

**Resultado: no hay mejora detectable en tiempo** (p=0.19, o sea `~`). La memoria
por operación bajó un 5,6%, que es real y **irrelevante**: el recolector ya
consumía solo el 3,1% de la CPU, así que no había nada que ganar ahí.

**Por qué falló la hipótesis.** Tres razones, en orden de peso:

1. **Se atacó el sitio equivocado.** El 34% de `Encode` **no** es asignación: es
   reflexión y formateo. El perfil lo decía y lo leí mal, mirando `mallocgc` por
   separado en vez de `list` sobre la función.
2. **El slice ya se pre-dimensionaba** con `make([]workItemJSON, 0, len(items))`.
   La asignación que el pool eliminaba era **una** por petición, no 312.
3. **El coste de `Get`/`Put` se comió la ganancia**, que es exactamente lo que
   `pool-vs-alloc` (§6.4) predice para objetos de este tamaño.

**Decisión: revertido.** El cambio añadía complejidad, un riesgo real de bug de
aliasing (las tres reglas de `sync.Pool`), y no mejoraba nada medible.

**Qué sí funcionó, después.** Precodificar el JSON en la caché (B-18, Fase 12):
elimina la serialización entera en los aciertos, que era el 34%. **La optimización
correcta estaba a un nivel por encima de donde miré primero.**

**Lección.** Leí el perfil buscando lo que esperaba encontrar —asignaciones— en vez
de lo que decía —reflexión y formateo—. `list` sobre la función habría evitado
media tarde.
```

> 🧭 **Regla del proyecto.** Toda optimización que se intenta se registra, funcione
> o no. **El archivo de las que fallaron es más útil que el de las que
> funcionaron**, porque impide que otra persona —o tú dentro de un año— repita el
> intento. Y porque enseña a leer perfiles, que es lo que de verdad se está
> aprendiendo.

---

## ⚰️ 7. Autopsia y errores comunes

### ⚰️ Autopsia: la optimización que empeoró el p99

**El cadáver.** El equipo perfiló AtlasSync y encontró que la serialización JSON
dominaba. La solución parecía evidente: cachear la respuesta serializada.

```go
// ☕
type cachedResponse struct {
	body []byte
	at   time.Time
}

type Handler struct {
	mu    sync.RWMutex                    // ← el problema está aquí
	cache map[string]cachedResponse
	ttl   time.Duration
}

func (h *Handler) getCountry(w http.ResponseWriter, r *http.Request) {
	code := r.PathValue("code")

	h.mu.RLock()
	cached, ok := h.cache[code]
	h.mu.RUnlock()

	if ok && time.Since(cached.at) < h.ttl {
		w.Header().Set("Content-Type", "application/json")
		w.Write(cached.body)
		return
	}

	country, err := h.svc.Country(r.Context(), code)
	if err != nil {
		writeError(w, r, err)
		return
	}
	body, _ := json.Marshal(country)

	h.mu.Lock()                            // ← ESCRITURA EXCLUSIVA
	h.cache[code] = cachedResponse{body: body, at: time.Now()}
	h.mu.Unlock()

	w.Header().Set("Content-Type", "application/json")
	w.Write(body)
}
```

**El benchmark decía que funcionaba:**

```text
BenchmarkGetCountry/sin_cache-10    12847    92847 ns/op   41232 B/op   312 allocs/op
BenchmarkGetCountry/con_cache-10   482103     2481 ns/op     384 B/op     3 allocs/op
```

**Treinta y siete veces más rápido.** Se desplegó.

**Y en producción, el p99 subió de 48 ms a 340 ms.**

**El informe forense.** El benchmark medía **una goroutine** pidiendo **un país**
con la caché **caliente**. La realidad era otra:

| | El benchmark | Producción |
|---|---|---|
| Goroutines concurrentes | **1** | ~200 |
| Países distintos | **1** | 250 |
| Estado de la caché | siempre caliente | expira constantemente |
| Proporción de escrituras | **0%** tras la primera | ~8% (por las expiraciones) |
| Contención del mutex | **ninguna** | **severa** |

Con TTL de 60 s y 250 países, **cada segundo expiran unos cuatro**. Cada expiración
provoca un `h.mu.Lock()` **exclusivo**, que bloquea a las 200 goroutines lectoras
mientras dura.

Y peor: `json.Marshal` ocurría **antes** del `Lock`, pero la consulta a MongoDB
también, y varias goroutines pedían el mismo país expirado a la vez —**sin
`singleflight`**, que es justo lo que la Fase 12 resolvió—. Cuatro consultas
simultáneas a MongoDB por cada expiración, con el mutex esperando.

**El perfil que lo habría detectado, y que nadie miró:**

```bash
runtime.SetMutexProfileFraction(5)
go tool pprof 'http://localhost:9090/debug/pprof/mutex'
```

```text
(pprof) top
      flat  flat%   sum%        cum   cum%
   48.21s 94.12% 94.12%     48.21s 94.12%  sync.(*RWMutex).Lock
    2.11s  4.12% 98.24%      2.11s  4.12%  sync.(*RWMutex).RLock
```

**El 94% del tiempo de espera por contención está en un solo `Lock`.** El perfil de
**CPU** no mostraba nada raro —el servicio estaba al 12% de CPU—, porque **esperar
un mutex no consume CPU**. Es exactamente el error de método de §4: usar el perfil
de CPU para un problema que no es de CPU.

**Las cuatro causas de la muerte:**

1. **El benchmark no reproducía la concurrencia real.** Sin `b.RunParallel`, sin
   claves variadas, sin expiraciones.
2. **Se midió el caso mejor y se desplegó como si fuera el caso medio.**
3. **No se midió después del despliegue.** El p99 llevaba dos días alto antes de
   que alguien lo relacionara.
4. **Y la de diseño: un `RWMutex` global para una caché con escrituras
   frecuentes.** Un `RWMutex` es excelente con muchísimas lecturas y escrituras
   raras; con un 8% de escrituras, el `Lock` exclusivo serializa todo.

**El fix, y son dos cosas distintas:**

```go
// 1. Eliminar la contención: una caché fragmentada. N mapas con N mutex, y la
//    clave decide cuál. Con 32 fragmentos, la probabilidad de que dos
//    escrituras coincidan baja drásticamente.
//
//    (Y la alternativa: la caché de la Fase 12, que ya estaba escrita y resuelve
//    esto mejor. Reescribirla en el handler fue el error original.)
type shardedCache struct {
	shards [32]struct {
		mu sync.RWMutex
		m  map[string]cachedResponse
		_  [40]byte   // relleno para que cada fragmento ocupe su propia línea de
		              // caché de CPU y no haya "false sharing"
	}
}

// 2. Eliminar la estampida: singleflight, que ya existía desde la Fase 12.
```

**Y el benchmark corregido, que es lo que hay que llevarse:**

```go
func BenchmarkGetCountryRealistic(b *testing.B) {
	h := newHandler(b, 60*time.Second)
	codes := allCountryCodes()   // 250, no uno

	b.RunParallel(func(pb *testing.PB) {
		// Cada goroutine empieza en un punto distinto: sin esto, todas piden la
		// misma clave a la vez y el patrón sigue sin ser realista.
		i := rand.IntN(len(codes))
		for pb.Next() {
			i = (i + 1) % len(codes)
			h.get(codes[i])
		}
	})
}
```

```bash
go test -run '^$' -bench BenchmarkGetCountryRealistic -cpu=1,4,8,16 -count=10 ./internal/httpapi
```

```text
GetCountryRealistic-1     2.48µ ± 2%
GetCountryRealistic-4     8.91µ ± 7%     ← empeora con más paralelismo
GetCountryRealistic-8    21.40µ ± 12%    ← la contención se ve aquí
GetCountryRealistic-16   58.20µ ± 18%
```

**Un benchmark que empeora al añadir procesadores lógicos es la firma de la
contención**, y `-cpu=1,4,8,16` la revela en treinta segundos.

> ☕ **El patrón a memorizar.** **Un benchmark que no reproduce la concurrencia, la
> variedad de datos y el estado real de las cachés mide el mejor caso.** Y el mejor
> caso no es lo que tus usuarios experimentan. **`-cpu=1,4,8,16` y `b.RunParallel`
> no son opcionales cuando hay estado compartido.**

### Errores comunes

**1. El código eliminado por el compilador.**
*Síntoma:* mil millones de iteraciones a menos de un nanosegundo.
*Fix mínimo:* `b.Loop`.

**2. Medir la preparación.**
*Síntoma:* el benchmark mide `buildMovements`, no la función.
*Fix mínimo:* preparación fuera del bucle.

**3. Una sola corrida.**
*Síntoma:* "mejoras" que no se reproducen.
*Fix mínimo:* `-count=10` y `benchstat`.

**4. Ignorar el valor p.**
*Síntoma:* celebrar un `~` como si fuera una mejora.
*Fix mínimo:* leer la columna; `~` significa "sin diferencia detectable".

**5. Benchmark secuencial para código concurrente.**
*Síntoma:* la autopsia.
*Fix mínimo:* `b.RunParallel` y `-cpu=1,4,8,16`.

**6. Perfil de CPU para un problema de bloqueo.**
*Síntoma:* el servicio está lento con la CPU ociosa y el perfil no dice nada.
*Fix mínimo:* perfiles `mutex` y `block`, activados explícitamente.

**7. Leer `top` sin `-cum`.**
*Síntoma:* el perfil solo muestra `mallocgc` y `memmove`, que no son accionables.
*Fix mínimo:* `top -cum` primero, y `list` sobre la función sospechosa.

**8. Confundir `alloc_space` con `inuse_space`.**
*Síntoma:* buscar una fuga en el perfil equivocado.
*Causa:* `alloc_space` es el **total asignado desde el arranque**; `inuse_space` es
lo **vivo ahora**. Para fugas, el segundo; para presión sobre el recolector, el
primero.

**9. Optimizar sin objetivo.**
*Síntoma:* semanas de trabajo sin criterio para parar.
*Fix mínimo:* un objetivo numérico antes de empezar.

**10. Optimizar sin línea base.**
*Síntoma:* no se puede demostrar la mejora.
*Fix mínimo:* medir **antes**, y guardar el archivo con sus condiciones.

**11. Cambiar cinco cosas a la vez.**
*Síntoma:* mejoró, y no se sabe cuál.
*Fix mínimo:* un cambio por medición.

**12. `sync.Pool` mal usado.**
*Síntoma:* corrupción de datos intermitente.
*Causa:* no resetear, o seguir usando lo devuelto.
*Fix mínimo:* las tres reglas de §4.

**13. Medir en una máquina con ruido.**
*Síntoma:* variabilidad del 15% en `benchstat`.
*Fix mínimo:* cerrar todo, comprobar `uptime`, y desconfiar si `±` supera el 5%.

**14. Omisión coordinada en la prueba de carga.**
*Síntoma:* la latencia medida es mucho mejor que la real.
*Fix mínimo:* generador con ritmo fijo (`vegeta -rate`), no con usuarios que
esperan.

**15. Generar la carga en la misma máquina.**
*Síntoma:* números inconsistentes y peores de lo real.
*Fix mínimo:* otra máquina, o declararlo como limitación del experimento.

**16. Extrapolar.**
*Síntoma:* "si un millón tarda X, diez millones tardarán 10X".
*Fix mínimo:* medir. La regla 8 de `prompts/formato-de-benchmarks.md` lo prohíbe
explícitamente.

### 🧨 Rompe a propósito

Ya viste el código eliminado. El segundo es **el benchmark que miente por la
caché**, que es la autopsia en miniatura y se hace en dos minutos:

```go
func TestBenchmarkLies(t *testing.T) {
	// Versión 1: siempre la misma clave. La caché acierta el 100%.
	// Versión 2: claves rotatorias con TTL corto. Acierto realista.
	// Versión 3: la misma que la 2, pero con -cpu=8.
	//
	// Los tres números difieren en un orden de magnitud, y solo el tercero se
	// parece a producción.
}
```

Y el tercero, que enseña sobre el hardware: **el *false sharing***.

```go
// Dos contadores en campos adyacentes de un struct. Están en la MISMA línea de
// caché de la CPU (64 bytes), así que cuando dos núcleos actualizan cada uno el
// suyo, el protocolo de coherencia invalida la línea del otro constantemente.
//
// Se llama false sharing porque no comparten datos: comparten línea de caché.
type CountersBad struct {
	a int64
	b int64
}

// Con relleno, cada uno ocupa su propia línea.
type CountersPadded struct {
	a int64
	_ [56]byte   // 8 + 56 = 64
	b int64
	_ [56]byte
}
```

```bash
go test -run '^$' -bench BenchmarkFalseSharing -cpu=8 -count=10 ./labs/escape-lab
```

```text
FalseSharing/adjacent-8    41.20n ± 3%
FalseSharing/padded-8       8.91n ± 2%    ← 4,6 veces más rápido
```

**Cuatro veces más rápido por añadir bytes que no se usan.** Es contraintuitivo, es
real, y es la clase de cosa que **solo se encuentra midiendo** — ningún perfil de
CPU señala "esta línea de caché está en disputa".

**El matiz honesto:** esto importa en un contador actualizado millones de veces por
segundo desde varios núcleos. En el 99,9% del código, añadir relleno es ruido que
gasta memoria. Está aquí para que sepas que existe cuando el perfil no explique
algo.

---

## 🧪 8. Ejercicios (26)

**🟢 Fácil (1–6)**

1. Reproduce el benchmark eliminado y arréglalo con `b.Loop`. *Criterio:* pegas
   los dos números y explicas la firma que delata el problema.
2. Corre un benchmark con `-count=1` y con `-count=10` + `benchstat`. *Criterio:*
   muestras la variabilidad y explicas qué significan `±` y `p`.
3. Perfila un benchmark y usa `top`, `top -cum` y `list`. *Criterio:* explicas qué
   pregunta responde cada uno.
4. Ejecuta `-gcflags=-m` sobre `escape-lab` y clasifica los escapes en las cuatro
   causas de §4. *Criterio:* al menos un ejemplo de cada.
5. Corre el cierre con `GODEBUG=gctrace=1` e interpreta la primera línea.
   *Criterio:* explicas los seis campos y dices cuál es el que decide si tocar
   `GOGC`.
6. Lanza `vegeta` contra OpsReport y produce el informe. *Criterio:* distingues
   media de p99 y explicas por qué solo la segunda importa.

**🟡 Intermedio (7–17)**

7. Mide las seis trampas de `benchstat-lab`. *Criterio:* para cada una, el número
   equivocado y el correcto, con la explicación.
8. Perfila `GET /work-items` bajo carga. *Criterio:* **escribes tu predicción
   antes**; identificas las tres funciones que más consumen; y reportas si
   acertaste.
9. Usa `list` sobre la función más cara y localiza la línea. *Criterio:* pegas la
   salida anotada y explicas qué hace esa línea.
10. Distingue tiempo de CPU de tiempo de espera en un perfil. *Criterio:*
    identificas una función con mucho acumulado y poco propio, y explicas qué
    significa.
11. Activa los perfiles `mutex` y `block` y encuentra contención. *Criterio:* la
    provocas con un `RWMutex` compartido y la localizas.
12. Mide `pool-vs-alloc` con los tres tamaños, secuencial y en paralelo.
    *Criterio:* encuentras el umbral donde `sync.Pool` empieza a ganar, y
    compruebas si `reused` gana a los dos.
13. Rompe las tres reglas de `sync.Pool`, una a una. *Criterio:* para cada una,
    demuestras la corrupción con un test que falla con `-race`.
14. Escribe un benchmark de tabla con `b.Run` y `SetBytes` para cuatro tamaños.
    *Criterio:* el resultado incluye MB/s y explicas qué muestra la escala.
15. Compara `fmt.Sprintf` con `strconv` y con `strings.Builder` en el camino
    caliente de un log. *Criterio:* mides, conectas con el escape analysis, y
    explicas por qué `slog.Int` es preferible a `slog.Any`.
16. Usa `go tool trace` sobre el cierre y localiza las pausas del recolector.
    *Criterio:* explicas qué ves que `pprof` no te mostraba.
17. **Línea de comandos.** Automatiza la comparación: un guion que mide `HEAD` y
    `HEAD~1` y produce el `benchstat`. *Criterio:* registra las condiciones y es
    reproducible.

**🟠 Difícil (18–23)** — *"mide antes de creerme"*

18. **Mide antes de creerme (1).** El curso afirma que `strings.Builder` es
    sustancialmente más rápido que `+=` (B-02, Fase 01). *Criterio:* lo verificas
    con 10, 100, 1.000 y 100.000 elementos, y **encuentras el tamaño por debajo del
    cual da igual**. Ese número no está en el curso.
19. **Mide antes de creerme (2).** El curso afirma que el coste de una llamada por
    interfaz no justifica evitar interfaces (B-05, Fase 02). *Criterio:* lo
    verificas, mides el coste del *inlining* perdido por separado, y dices en qué
    caso concreto **sí** importaría.
20. **Mide antes de creerme (3).** El curso afirma que la paginación por cursor no
    se degrada (B-15, Fase 09). *Criterio:* lo verificas hasta la página 10.000 y
    **buscas el punto donde sí se degrada** — porque hay uno, y tiene que ver con el
    índice.
21. **Mide antes de creerme (4).** El curso afirma que un mapa en memoria con TTL
    resuelve el caso de AtlasSync mejor que Valkey (B-17, Fase 12). *Criterio:* lo
    verificas con 250 y con 250.000 entradas, y encuentras dónde cambia el
    veredicto.
22. **Mide antes de creerme (5).** El curso afirma que el streaming mantiene la
    memoria acotada con un coste en tiempo menor del 15% (B-19, Fase 13).
    *Criterio:* lo verificas y **buscas un caso donde el streaming sea más lento de
    lo prometido** — pista: fragmentos muy pequeños.
23. **Mide antes de creerme (6).** El curso afirma en §6.2 de la Fase 14 que la
    diferencia entre `slog` con `LogAttrs` y `log.Printf` es pequeña. *Criterio:*
    lo mides con las tres formas —`LogAttrs` tipado, variádica, `slog.Any`— y
    **si la afirmación no se sostiene, escribes la corrección**. (Esta medición
    está pendiente de asignar en el curso: puede que estés escribiendo una entrada
    nueva de `BENCHMARKS.md`.)

**🔴 Muy difícil (24–26)**

24. **La optimización que no funcionó.** Elige una ruta caliente real, formula una
    hipótesis, impleméntala, mídela, y **escríbela en
    `docs/optimizaciones-fallidas.md` funcione o no**. *Rúbrica:* (a) la hipótesis
    está escrita **antes** de medir, con su número objetivo; (b) la medición usa
    `-count=10` y `benchstat`, con condiciones declaradas; (c) si mejoró, dices
    cuánto y qué complejidad costó; (d) **si no mejoró, explicas por qué falló la
    hipótesis** con el perfil delante; (e) tomas una decisión —mantener o
    revertir— y la justificas; (f) la lección está escrita para alguien que no hizo
    el experimento.
25. **Mide B-22 en serio.** *Rúbrica:* (a) las dos cargas —HTTP sostenida y lote—,
    con `GOGC` en 50, 100, 200, 400 y `off`, con y sin `GOMEMLIMIT`; (b) reportas
    CPU en recolección, memoria residente máxima, p99 y **pausa máxima**; (c)
    encuentras la combinación que recomienda el equipo de Go (`GOGC=off` +
    `GOMEMLIMIT`) y verificas si es mejor **para tus dos cargas**; (d) provocas
    deliberadamente el caso patológico —`GOMEMLIMIT` alcanzado de verdad— y
    describes el síntoma; (e) el veredicto dice **cuándo no tocar nada**, que es el
    caso mayoritario.
26. **El banco de pruebas de la plataforma.** Deja preparado todo lo que la Fase 16
    va a necesitar. *Rúbrica:* (a) un guion que mide los cuatro servicios con la
    misma carga y produce un informe reproducible; (b) las condiciones se registran
    automáticamente —máquina, versiones, commit, carga del sistema—; (c) incluye
    arranque en frío hasta la primera petición servida, memoria en reposo y bajo
    carga, latencia p50/p95/p99, rendimiento sostenido, y CPU por petición; (d) el
    resultado es comparable entre ejecuciones, y lo demuestras corriéndolo dos veces
    y verificando que la variabilidad está por debajo del 5%; (e) **el mismo guion
    tiene que poder medir el gemelo Spring Boot**, así que no puede depender de nada
    específico de Go; (f) documenta qué **no** mide y por qué.

**🔥 Opcionales**

- Investiga `testing/synctest` (Go 1.24, experimental), aplazado en la Fase 08 con
  revisión declarada **para esta fase**. Evalúalo sobre los tests con reloj falso y
  decide si ya merece adoptarse o sigue aplazado.
- Usa `perf` (Linux) o Instruments (macOS) para perfilar por debajo del runtime de
  Go: fallos de caché, predicción de saltos, IPC. Es otro nivel y a veces explica lo
  que `pprof` no.
- Compara el mismo algoritmo en Go y en Java con JMH, con calentamiento declarado.
  Es el ensayo del ejercicio 26 de la Fase 16 y te va a sorprender en las dos
  direcciones.

---

### 🔴 Desafíos de cierre

> Tres ejercicios de dificultad alta que **no cuentan en el total de la sección** y
> no son parte del recorrido base.

**D1 — El perfilado continuo casero.**
Monta la recogida periódica de perfiles en producción, con retención y comparación.
*Rúbrica:* (a) un componente que captura perfiles de CPU y heap cada N minutos y
los guarda con su marca de tiempo y su versión del binario; (b) el coste de la
captura es aceptable y lo mides —un perfil de CPU de 30 s tiene un sobrecoste
conocido—; (c) puedes comparar dos perfiles separados en el tiempo con
`pprof -base` y ver qué cambió tras un despliegue; (d) la retención está acotada y
los perfiles **no contienen datos de peticiones**, o explicas por qué el perfil de
heap puede contenerlos y qué haces al respecto; (e) comparas con JFR, que hace esto
de fábrica, y dices qué te falta.

**D2 — La optimización con objetivo, de principio a fin.**
Elige la ruta más cara de los cuatro servicios y **cumple un objetivo numérico
declarado de antemano**.
*Rúbrica:* (a) el objetivo está escrito antes de tocar nada, con su número y su
justificación de negocio; (b) línea base medida y guardada con sus condiciones; (c)
**un cambio por medición**, con `benchstat` en cada paso y el registro de los que no
funcionaron; (d) alcanzas el objetivo o **demuestras por qué no es alcanzable sin un
cambio de diseño**, que es un resultado igual de bueno; (e) mides también lo que
empeoró —porque algo empeora casi siempre— y decides si compensa; (f) el resultado
entra en `docs/optimizaciones-fallidas.md` o en su gemelo de las que sí
funcionaron.

**D3 — El microbenchmark que miente, y cazarlo.**
Construye un benchmark que reporte una mejora del 40% **completamente falsa**, y
después escribe la comprobación que lo detecta.
*Rúbrica:* (a) la mentira es sutil: no el código eliminado —eso ya lo viste— sino
una de estas: estado acumulado entre iteraciones, caché caliente en una variante y
fría en la otra, tamaños de entrada distintos, o una comparación entre `-count=1` de
cada; (b) alguien que no sepa qué buscas **se lo cree** al leer la salida; (c)
escribes la lista de comprobación que lo habría detectado; (d) la aplicas a los
benchmarks del curso y reportas si alguno la incumple; (e) explicas por qué esto
importa más que cualquier optimización concreta: **un equipo que se fía de
benchmarks malos optimiza en la dirección equivocada durante meses.**

---

## 📚 9. Referencias

### Documentación oficial

- **`testing`: benchmarks** — https://pkg.go.dev/testing#hdr-Benchmarks — y la
  documentación de `B.Loop`, que explica por qué existe.
- **Profiling Go Programs** — https://go.dev/blog/pprof — el artículo oficial, de
  2011 y todavía la mejor introducción al método.
- **Diagnostics** — https://go.dev/doc/diagnostics — el mapa completo:
  perfilado, trazas, depuración y estadísticas del runtime.
- **`runtime/pprof`** — https://pkg.go.dev/runtime/pprof ·
  **`net/http/pprof`** — https://pkg.go.dev/net/http/pprof
- **`runtime/trace`** — https://pkg.go.dev/runtime/trace
- **A Guide to the Go Garbage Collector** — https://go.dev/doc/gc-guide —
  **imprescindible para §6.5.** Explica `GOGC`, `GOMEMLIMIT` y la recomendación de
  combinarlos, con diagramas.
- **`benchstat`** — https://pkg.go.dev/golang.org/x/perf/cmd/benchstat
- **k6** — https://grafana.com/docs/k6/ · **vegeta** — https://github.com/tsenart/vegeta

### Libros

- **Efficient Go** — Bartłomiej Płotka. **Es el libro de esta fase.** Cubre el
  método —objetivos de eficiencia, cómo medir sin engañarse—, `pprof` completo, y
  el análisis de complejidad aplicado a Go. Su insistencia en definir el objetivo
  antes de optimizar es lo que sostiene §4.
- **Systems Performance** — Brendan Gregg. No es de Go y es la referencia sobre
  metodología de rendimiento: el método USE, cómo no engañarse, y las herramientas
  del sistema operativo.
- **100 Go Mistakes** — Harsanyi, capítulo 12 (*Optimizations*), errores #91 a
  #100: alineación de structs, *false sharing*, `sync.Pool`, y el escape analysis.
- **The Go Programming Language** — Donovan y Kernighan, la sección de benchmarks y
  perfilado del capítulo 11.

### Artículos y charlas

- **High Performance Go** — Dave Cheney,
  https://dave.cheney.net/high-performance-go-workshop/dotgo-paris.html — **el
  taller completo, gratis.** Benchmarks, perfilado, escape analysis, *inlining*,
  con ejercicios. Si solo lees una cosa de esta lista, que sea esta.
- **Go Execution Tracer** — https://go.dev/blog/execution-traces-2024 — el `trace`
  moderno, muy mejorado respecto a la versión antigua.
- **Go GC: Prioritizing low latency and simplicity** — https://go.dev/blog/go15gc —
  el artículo que explica la filosofía del recolector, y de donde sale §6.6.
- **Getting to Go: The Journey of Go's Garbage Collector** —
  https://go.dev/blog/ismmkeynote — Rick Hudson. Denso y **es la mejor explicación
  de por qué Go eligió latencia sobre rendimiento**, con la historia de las
  decisiones.
- **False Sharing** — busca el material clásico sobre el tema; Martin Thompson
  (*Mechanical Sympathy*) es la referencia, aunque escriba en Java.
- **How NOT to Measure Latency** — Gil Tene. **La charla sobre la omisión
  coordinada**, y explica por qué la mayoría de las pruebas de carga mienten. Es de
  Java y aplica a todo.
- **Profiling in production** — busca el material de Google sobre perfilado
  continuo; es la evolución natural de lo de esta fase.

### Video

- **How NOT to Measure Latency** — Gil Tene. **Obligatoria.** Una hora, y cambia
  cómo lees cualquier número de latencia.
- **Go Execution Tracer** y **Understanding Go's GC** — GopherCon; busca las
  posteriores a 2022.
- **Mechanical Sympathy** — las charlas de Martin Thompson sobre cachés de CPU,
  aunque el código sea Java: el hardware es el mismo.

> ⚠️ El material anterior a 2024 no conoce `b.Loop` y usa `b.N` con la variable
> `sink`. Sigue siendo correcto y hay que saber por qué esa variable estaba ahí.
> Y el anterior a 2022 no conoce `GOMEMLIMIT`, así que sus consejos sobre correr Go
> en contenedores con límite de memoria están fechados.

### Orden de lectura sugerido

**Antes de medir nada:** *High Performance Go* de Cheney, al menos las secciones de
benchmarking y perfilado. Dos horas, y evita todas las trampas de §6.1.
**Durante:** la *GC Guide* oficial cuando llegues a `GOGC`, y `pprof` cuando dudes
de una vista.
**Después:** *How NOT to Measure Latency* de Gil Tene, entera, y después vuelve a
mirar tus propias mediciones de carga. Vas a querer repetir alguna, y ese es el
punto.

---

## ⚖️ 10. Veredicto y cierre

### ⚖️ Cuándo NO usar esto

- **Cuando no tienes un problema de rendimiento.** Es el caso mayoritario y hay que
  decirlo primero. Perfilar un servicio que cumple sus objetivos es tiempo que
  valía más en otra parte. **El disparador es un objetivo incumplido, no la
  curiosidad.**
- **Cuando el cuello de botella no es tu código.** El perfil de §6.2 lo mostró: el
  52% acumulado estaba en la consulta a PostgreSQL, esperando. Optimizar el código
  Go no habría movido nada. **La mayoría de los problemas de rendimiento de un
  servicio de negocio están en la base de datos, en la red o en el diseño, no en el
  lenguaje.**
- **Cuando la optimización compromete la claridad sin un número que la
  justifique.** Un cambio que hace el código 3% más rápido y 30% más difícil de
  entender es un mal negocio, y la variabilidad de ese 3% probablemente lo convierte
  en `~`.
- **Y sobre las herramientas: la JVM tiene mejores.** Hay que decirlo. JFR (Java
  Flight Recorder) captura eventos de altísima resolución con sobrecarga mínima y
  está pensado para dejarse **encendido en producción**. `async-profiler` da perfiles
  de CPU, asignación y bloqueo con precisión que `pprof` no alcanza. Y las
  herramientas de análisis de GC de la JVM llevan veinte años de desarrollo.
  **`pprof` es simple, está en el toolchain y cubre el 90%; el 10% restante, la JVM
  lo cubre mejor.**
- **Lo que Go sí tiene y la JVM no:** el escape analysis **inspeccionable**
  (`-gcflags=-m` te dice **por qué** una variable escapa; en la JVM eso es una
  decisión opaca del JIT), y benchmarks sin necesidad de calentamiento, que hace la
  medición más simple y más rápida.

### 📖 Diccionario Java ⇄ Go de esta fase

| Java | Go | Dónde se rompe la equivalencia |
|---|---|---|
| JMH | `testing.B` + `benchstat` | **Sin calentamiento**: no hay JIT, la primera iteración ya es código máquina. Más simple, y la estadística sigue siendo necesaria |
| `@Warmup` / `@Fork` de JMH | *(no hacen falta)* | El *fork* de JMH aísla el estado del JIT; en Go no hay estado que aislar |
| `Blackhole.consume()` | `b.Loop` | Mismo propósito: impedir que el compilador elimine el código. En Go es automático desde 1.24 |
| `@State(Scope.Benchmark)` | variables antes del bucle | Sin anotaciones |
| Modos `Throughput` / `AverageTime` | `ns/op` + `SetBytes` para MB/s | Go da tiempo por operación; el rendimiento se deriva |
| JFR (Java Flight Recorder) | `runtime/trace` + `pprof` | **JFR es más completo y está pensado para producción continua.** Ventaja real de la JVM |
| `async-profiler` | `pprof` | async-profiler tiene mejor resolución y menos sesgo de puntos seguros |
| VisualVM / JMC | `go tool pprof -http` | La interfaz de `pprof` es sencilla; JMC hace mucho más |
| `-Xmx` / `-Xms` | `GOMEMLIMIT` | **Límite SUAVE**: el recolector se vuelve agresivo, no falla. `-Xmx` es duro y produce `OutOfMemoryError` |
| `-XX:NewRatio`, `SurvivorRatio`, … | *(no existen)* | El recolector de Go **no es generacional**: no hay generaciones que dimensionar |
| Elegir recolector (G1/ZGC/Shenandoah) | *(no se elige)* | Uno solo. Menos control, cero decisiones que equivocar |
| `-XX:MaxGCPauseMillis` | *(no existe)* | Go apunta a pausas sub-milisegundo por diseño, sin parámetro |
| `-XX:+PrintGCDetails` | `GODEBUG=gctrace=1` | Equivalente; la salida de Go es más escueta |
| Análisis de escape del JIT | `-gcflags='-m'` | **En Go es inspeccionable y determinista.** Ventaja real de Go |
| TLAB | caché por procesador lógico (`mcache`) | Mismo concepto |
| Pool de objetos (`ObjectPool` de Commons) | `sync.Pool` | ⚠️ `sync.Pool` **se vacía en cada recolección**: no cachea, amortigua |
| `ThreadLocal` como pool por hilo | `sync.Pool` (que es por procesador lógico) | Similar en efecto |
| JMeter / Gatling | k6 / vegeta | Mismo propósito. **La omisión coordinada afecta a todos por igual** |
| Micrometer `@Timed` con percentiles | histograma de Prometheus | Los cubos agregan entre instancias; los percentiles precalculados, no (Fase 14) |
| `System.nanoTime()` | `time.Now()` con reloj monótono | `time.Time` de Go **lleva reloj monótono incorporado** desde 1.9: restar dos `time.Now()` es correcto aunque el reloj del sistema salte |

### Qué sigue

**La Fase 16 es la fase por la que existe el curso.**

ClearingHouse está implementado dos veces: la versión Go que has construido y una
versión Spring Boot 3 equivalente que el curso **entrega hecha** —el mismo esquema,
las mismas migraciones, los mismos endpoints, el mismo cierre—.

Se miden, con la misma máquina y el banco que acabas de dejar listo: arranque en
frío hasta la primera petición servida, memoria residente en reposo y bajo carga,
latencia p50/p95/p99, rendimiento sostenido, CPU por petición, el cierre de un
millón de movimientos extremo a extremo, tamaño de imagen y tiempo de compilación
desde limpio, comportamiento bajo un pico de diez veces el tráfico, y **la JVM en
tres configuraciones: por defecto, ajustada, y `native-image` con GraalVM** —porque
comparar Go contra una JVM sin ajustar es hacer trampa.

Y lo que no sale en un gráfico y decide proyectos igual: líneas de código,
dependencias de tercero, tiempo hasta el primer endpoint funcionando, madurez del
ecosistema por área, y facilidad de contratar.

**El veredicto honesto es el entregable de la fase, y tiene que doler un poco en
las dos direcciones.** Si el resultado es "Go gana en todo", la fase está mal
escrita.

### La señal de que quedó bien

> *"Antes de tocar una línea por rendimiento, tengo el número de hoy, el número
> objetivo, y el perfil que me dice dónde mirar. Y cuando el cambio no mejora, lo
> revierto y lo escribo."*

Si tu última optimización no tiene una medición antes y otra después con
`benchstat`, no fue una optimización: fue un cambio de código con buena intención.

> 🏷️ **No cierres la fase sin el tag.** Con el checklist de la sección 2 en
> verde, el banco de pruebas reproducible, `docs/optimizaciones-fallidas.md` con al
> menos una entrada real, `make ci` en verde y `git status` sin cambios pendientes:
>
> ```bash
> git tag -a fase-15 -m "F15 cerrada: benchmarks con b.Loop y benchstat; perfilado de las rutas calientes de los cuatro servicios; escape analysis aplicado; sync.Pool medido con su umbral; GOGC y GOMEMLIMIT medidos sobre dos cargas; banco de pruebas de carga reproducible; optimizaciones fallidas documentadas; B-22 y B-23 medidos"
> git tag -a plataforma/v1.0-rc2 -m "Banco de pruebas listo para el duelo"
> ```
>
> Los commits de la fase llevan su prefijo (`fase 15: …`) y los de ejercicio su
> número (`fase 15 ej24: …`). Todo eso está en
> [`00-convencion-de-git-y-tags.md`](00-convencion-de-git-y-tags.md).

---

# 📌 Bloque de autoría (fuera de lo que lee el estudiante)

## 📌 Pendientes sugeridos

- **`testing/synctest`** — aplazado en la **Fase 08** con revisión declarada
  **para esta fase**. Está como ejercicio 🔥. **Cadena cerrada**, aunque de forma
  débil: si se quiere cumplir la promesa de `docs/rechazos.md`, debería producir
  una decisión escrita, no solo una exploración. **Sugerencia: que el 🔥 pida
  actualizar la entrada de `docs/rechazos.md`.**
- **B-28 — coste del middleware de observabilidad por petición.** Pedido **por la
  Fase 05, la Fase 10 y la Fase 14**: tres fases, y era la anotación más repetida
  del curso sin resolver. Se mide aquí porque es la fase donde el banco ya existe
  y el experimento es barato. Asignada al cerrar el curso. **La cadena vacía es la
  línea base**, y sin ella las otras cinco filas no significan nada.
- **Coste de `slog` frente a `log.Printf`** — la Fase 14 lo afirmaba sin medir.
  **Resuelto por las dos vías a la vez:** la afirmación de la Fase 14 §6.2 se
  suavizó a lo estructural (JSON frente a concatenación, reflexión de `slog.Any`
  frente a atributos tipados), y la fila de logging de **B-28** da el número
  dentro de la cadena. **El ejercicio 23 sigue siendo el sitio donde el estudiante
  extiende la entrada** a `slog.Any` y a la forma variádica.
- **Coste de `ctx.Value` por profundidad** — propuesto por la **Fase 07**.
  **Resuelto suavizando la afirmación**, no midiéndola: §4 de la Fase 07 ahora
  describe el mecanismo —cada `WithValue` envuelve al anterior— y dice que el
  curso no ha medido el coste. Es deliberado: el argumento contra meter datos de
  negocio en el contexto es de diseño, y un número lo debilitaría.
- **`httptrace`** — añadido a §5 como el perfilador del lado cliente, con el caso
  que lo justifica (`GotConn.Reused == false`: el pool no reutiliza y cada petición
  paga DNS más TLS, que es tiempo que ningún perfil de CPU ve porque el proceso
  está esperando) y con el ⚠️ de no dejarlo puesto en producción. Cadena cerrada
  con la Fase 10.
- **Perfilado continuo en producción** — solo en referencias. Correcto para el
  alcance.

## ☕ Reflejos para `INSTINTOS.md`

- **"Esto asigna mucho, hay que hacer un pool"** — el reflejo raíz de la fase. En
  Go, el escape analysis ya evitó la mayoría de las asignaciones, el asignador es
  muy bueno con objetos pequeños, y `sync.Pool` se vacía en cada recolección.
  Antídoto: **medir; y las tres opciones son `new`, `pool` y `reused`, donde la
  tercera suele ganar**.
- **"El benchmark dice que es 37 veces más rápido"** — la autopsia. Un benchmark
  secuencial, con una clave y la caché caliente, mide el mejor caso; el p99 en
  producción subió siete veces. Antídoto: **`b.RunParallel` y `-cpu=1,4,8,16`
  cuando hay estado compartido**.
- **"El perfil de CPU no muestra nada raro"** — esperar un mutex no consume CPU.
  Los perfiles `mutex` y `block` están desactivados por defecto y casi nadie sabe
  que existen.
- **"Una corrida basta"** — sin `-count=10` y `benchstat`, una mejora del 8% con
  variabilidad del 12% es imaginaria.
- **"El compilador no va a borrar mi código"** — sí lo hace, y el síntoma es mil
  millones de iteraciones a 0,25 ns.
- **"Puntero significa heap"** — falso en Go: el escape analysis mantiene en la
  pila lo que no escapa, aunque se use por puntero.
- **"Optimizo y luego mido"** — sin línea base no se puede demostrar nada.

## 📐 Mediciones para `BENCHMARKS.md`

- **B-22 — `GOGC` y `GOMEMLIMIT`: efecto sobre pausas y memoria.** ⚠️ **Dos cargas
  obligatorias** (HTTP sostenida y lote), porque el resultado depende enteramente
  del patrón de asignación y medir solo una produciría una recomendación que falla
  en la otra. Incluir **pausa máxima**, no solo porcentaje de CPU. Y el veredicto
  debe decir **cuándo no tocar nada**.
- **B-23 — EventRelay: entregas por segundo contra `fakeconsumer`.** Con los
  **tres** comportamientos (`/ok`, `/flaky`, `/slow`), no solo el mejor caso. El
  número que decide es **a partir de qué ritmo el p99 se dispara**. Y declarar si
  el generador corría en la misma máquina, por la omisión coordinada.
- **Revisión de entradas antiguas:** los ejercicios 18–22 piden **verificar cinco
  afirmaciones ya publicadas** (B-02, B-05, B-15, B-17, B-19). Es una práctica
  sana y **puede producir correcciones**. Si alguna no se sostiene, la entrada
  correspondiente se revisa según §4 del formato: **identificador nuevo que enlaza
  al anterior y dice qué cambió**, nunca reescribir en silencio.
