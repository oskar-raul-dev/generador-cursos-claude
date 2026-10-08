# ⚙️ Fase 06 — Concurrencia ⭐

> Go para desarrolladores Java senior · Fase 6 de 17 · **9 horas**
> Época: **Go 1.13 (stdlib pura)**
> Depende de: Fase 05 · Habilita: Fase 07
> Proyectos que avanzan: **OpsReport** (motor de jobs) · **EventRelay** (cola de entregas)
> Mini proyectos: `race-counter`, `deadlock-lab`, `leak-lab`, `unbounded-queue`

---

## 🎯 1. Propósito

Esta es la fase estrella del Bloque A y la razón por la que mucha gente llega a
Go. También es donde más daño hace traer los reflejos de Java tal cual, porque
aquí los dos lenguajes tienen modelos **parecidos en la superficie y distintos en
el fondo**: una goroutine se parece a una tarea de `ExecutorService`, hasta que
descubres que no hay pool que la contenga, nadie te devuelve un `Future`, y si
nadie la espera el proceso puede terminar sin que haya corrido.

Y hay algo que ya te está pasando y no has visto. Desde que arrancaste el servidor
en la Fase 05, **`net/http` lanza una goroutine por petición**. Tu `memstore` no
es seguro para uso concurrente. Con dos peticiones simultáneas, ese mapa se
corrompe. Hoy lo vas a provocar, verlo con `-race`, y arreglarlo — en ese orden,
que es el único que enseña algo.

Al terminar, diseñas concurrencia **acotada** por reflejo, que es la lección
transferible de toda la fase.

---

## ✅ 2. Qué queda listo al terminar

- [ ] `memstore` es seguro para uso concurrente y lo demuestras con `-race` bajo
      carga.
- [ ] OpsReport tiene motor de jobs: cola con búfer acotado, N workers, estados
      avanzando y `JobExecution` registrada por ejecución.
- [ ] EventRelay tiene cola de entregas con concurrencia global y por endpoint
      acotada.
- [ ] `go1.13 test -race ./...` pasa en los dos módulos, y sabes cuánto cuesta
      correrlo (B-10).
- [ ] Los cuatro laboratorios de desastre están escritos y **los has visto
      fallar**: carrera, deadlock, fuga y cola sin límite.
- [ ] Puedes explicar quién tiene derecho a cerrar un canal, y por qué cerrar dos
      veces entra en panic.
- [ ] Has medido el coste de una goroutine (B-07), canal frente a mutex (B-08) y
      pool acotado frente a goroutine por tarea bajo pico (B-09).
- [ ] Ninguna goroutine del código de producción se lanza sin que puedas decir
      **quién la espera y cuál es su tope**.

---

## 🚫 3. Qué NO entra todavía

- **`context` y la cancelación** → Fase 07. Y **lo vas a echar de menos a los
  veinte minutos**, en cuanto quieras que un worker se entere de que hay que parar.
  Hoy se resuelve con un canal `quit` cerrado, que es exactamente el mecanismo que
  `context` empaqueta — y verlo a mano primero hace que `context` se entienda en
  cinco minutos en vez de en dos semanas.
- **`errgroup` y `semaphore.Weighted`** → Fase 08 🕰️. Son `golang.org/x/sync`,
  fuera del régimen de stdlib pura del Bloque A. Hoy escribimos el semáforo con un
  canal con búfer, que es lo que `semaphore` hace por dentro.
- Apagado ordenado del servidor HTTP y señales del sistema operativo → Fase 07.
- `goleak` como librería → Fase 08. Hoy la detección de fugas es a mano con
  `runtime.NumGoroutine`, que se entiende mejor.
- `sync.Map` — existe en 1.13 y **no lo vamos a usar**: está pensada para dos
  patrones de acceso muy concretos y en el 95% de los casos un `map` con
  `RWMutex` es más rápido y más claro. Se explica por qué en §7.
- Persistencia de la cola → Fase 09. Hoy todo vive en memoria, y eso es una deuda
  declarada. 💸

---

## 🧠 4. Concepto mínimo

### Una goroutine no es un hilo, y la diferencia es de tres órdenes de magnitud

```go
go doSomething()          // eso es todo
go func() { ... }()       // o con una función anónima
```

La palabra `go` delante de una llamada arranca una goroutine. No hay clase que
implementar, no hay pool al que enviarla, no hay `Future` de vuelta.

Lo que la hace distinta de un hilo de la JVM es el coste. Un hilo de plataforma en
Java reserva una pila de tamaño fijo —el valor por defecto ronda 1 MB, y se
configura con `-Xss`— y lo planifica el sistema operativo: cada cambio de contexto
pasa por el núcleo. Una goroutine arranca con **una pila de 2 KB que crece y
encoge sola**, y la planifica el runtime de Go **en espacio de usuario**, sin
llamadas al sistema.

```go
// labs/race-counter/scale.go
func SpawnN(n int) {
	var wg sync.WaitGroup
	wg.Add(n)
	for i := 0; i < n; i++ {
		go func() {
			defer wg.Done()
			time.Sleep(10 * time.Millisecond)
		}()
	}
	wg.Wait()
}
```

Llama a `SpawnN(100000)` y mira la memoria residente. Después intenta lo
equivalente en Java con hilos de plataforma y mira qué pasa.

> 📐 **Cómo se mide.** Entrada **B-07**: *coste de arranque de una goroutine
> frente a un hilo de la JVM*. Tiempo de creación, memoria por unidad, y el punto
> donde la JVM deja de poder. Las condiciones y los comandos están en
> `BENCHMARKS.md`; el número de tu máquina lo pones tú.
>
> **Y el veredicto tiene que incluir las hebras virtuales de Java 21**, que
> cambian esta comparación por completo. Hablamos de ellas en §6.8 y en el
> diccionario, con honestidad: son el paralelo más cercano a una goroutine que
> existe fuera de Go.

### El planificador M:N, en cuatro frases

El runtime de Go multiplexa **M** goroutines sobre **N** hilos del sistema
operativo. `GOMAXPROCS` —por defecto, el número de núcleos— fija cuántas goroutines
pueden estar **ejecutando código** a la vez.

Cuando una goroutine se bloquea en E/S, en un canal o en un mutex, el planificador
**la aparca y pone otra en ese hilo**. El hilo del sistema operativo nunca se
queda esperando. Por eso diez mil goroutines esperando respuestas HTTP consumen
casi nada: están todas aparcadas.

> 🧠 **Modelo mental.** El planificador de Go es cooperativo con puntos de
> interrupción: una goroutine cede el control en llamadas a función, en operaciones
> de canal, en E/S y en asignaciones de memoria. **Un bucle apretado sin ninguna de
> esas cosas puede monopolizar su hilo.** En Go 1.14 llegó la interrupción
> asíncrona y eso dejó de ser un problema práctico 🕰️; en 1.13, un
> `for {}` vacío todavía puede colgar el programa entero. Es un detalle de época
> que conviene conocer.

### Canales: colas tipadas con sincronización incorporada

```go
ch := make(chan string)      // SIN búfer: cada envío espera a un receptor
ch := make(chan string, 10)  // CON búfer de 10: los 10 primeros envíos no esperan

ch <- "hola"                 // enviar
msg := <-ch                  // recibir
msg, ok := <-ch              // recibir; ok es false si el canal está cerrado y vacío
close(ch)                    // cerrar
```

La diferencia entre con y sin búfer es **de semántica, no de rendimiento**:

- **Sin búfer** es un *rendez-vous*: el emisor se bloquea hasta que alguien recibe.
  Cuando el envío completa, sabes que el otro lado lo tiene. Es sincronización.
- **Con búfer** es una cola: el emisor sigue mientras haya sitio. Cuando el envío
  completa, solo sabes que está en la cola. Es desacoplamiento.

```go
for msg := range ch {        // recorre hasta que el canal se cierra
	fmt.Println(msg)
}
```

`range` sobre un canal recibe hasta que se cierra **y se vacía**. Si nadie lo
cierra, el bucle se queda esperando para siempre — que es la fuga de goroutines
número uno.

> 🧭 **Regla del proyecto: cierra el canal quien escribe, nunca quien lee.** Un
> canal se cierra **una sola vez**, y solo desde el lado que envía. Cerrar dos
> veces entra en panic; enviar a un canal cerrado entra en panic; **recibir de un
> canal cerrado no**, devuelve el valor cero con `ok == false`, y esa asimetría es
> la que hace que cerrar sea una forma de señalizar.

### `select`: esperar en varios sitios a la vez

```go
select {
case job := <-jobs:
	process(job)

case <-quit:
	return

case <-time.After(5 * time.Second):
	log.Println("sin trabajo en cinco segundos")
}
```

`select` bloquea hasta que **uno** de sus casos esté listo. Si hay varios listos,
elige **al azar** —a propósito, para que nadie escriba código que dependa del
orden—. Con `default`, no bloquea nunca:

```go
select {
case jobs <- job:
	// entró en la cola
default:
	// la cola está llena: aplicar contrapresión AHORA, no encolar infinito
	return ErrQueueFull
}
```

Ese `default` es la diferencia entre un servicio que rechaza trabajo bajo carga y
uno que muere por falta de memoria. Es todo el laboratorio `unbounded-queue`.

> ⚠️ **`time.After` en un `select` dentro de un bucle es una fuga de memoria.**
> Cada iteración crea un `Timer` nuevo que **no se recolecta hasta que expira**.
> Con un bucle rápido y un timeout largo, se acumulan. La forma correcta es crear
> el `time.Timer` fuera y hacer `Reset`. Es un error tan común que merece estar
> aquí, en el concepto mínimo.

### 🪞 Tu instinto de Java dice… y esta vez se equivoca

**El instinto:** *"creo un pool de N hilos y le envío las tareas"*. Es correcto en
Java y es la práctica recomendada desde hace veinte años: `Executors.newFixedThreadPool(8)`,
`submit()`, y el pool se encarga del límite, de la cola y del apagado.

**Qué pasa si lo aplicas aquí.** Buscas el equivalente, no lo encuentras, y
escribes esto:

```go
// ☕ — esto compila, funciona en desarrollo, y no es un pool
func (e *Engine) ProcessAll(items []workitem.WorkItem) {
	var wg sync.WaitGroup
	for _, item := range items {
		wg.Add(1)
		go func(item workitem.WorkItem) {
			defer wg.Done()
			e.run(item)
		}(item)
	}
	wg.Wait()
}
```

Con cien items funciona de maravilla. Con cien mil, **lanzas cien mil goroutines
simultáneas**, cada una abriendo su conexión a la base de datos, y descubres tres
cosas seguidas: el pool de conexiones se agota, la memoria se dispara, y el
sistema al que llamas te corta.

`ExecutorService` te daba **tres cosas** y ninguna viene con `go`:

1. **Un límite.** El pool tiene N hilos; la tarea 101 espera. `go` no espera nunca.
2. **Un resultado.** `submit()` devuelve un `Future`; `go` no devuelve nada.
3. **Un apagado.** `shutdown()` + `awaitTermination()`; `go` no tiene dónde
   pedirlo.

**Qué pensar en su lugar:** en Go el pool **es un patrón, no un tipo**, y se
construye con un canal y N goroutines:

```go
// El worker pool de Go, completo. Diez líneas.
jobs := make(chan workitem.WorkItem, queueSize)  // el límite, aquí
var wg sync.WaitGroup

for i := 0; i < workerCount; i++ {               // los N workers, aquí
	wg.Add(1)
	go func(id int) {
		defer wg.Done()
		for job := range jobs {                   // cada uno consume hasta el cierre
			e.run(job)
		}
	}(i)
}

// ... alguien envía a `jobs` ...

close(jobs)   // el apagado, aquí: no hay más trabajo
wg.Wait()     // esperar a que terminen el que tenían
```

Diez líneas, y **cada una de las tres garantías está visible**: el búfer del canal
es la cola acotada, el bucle de arranque es el tamaño del pool, y `close` + `Wait`
es el apagado ordenado.

> 🧭 **Regla del proyecto, y es la más importante de la fase.** **Cero concurrencia
> sin límite.** Toda goroutine tiene un dueño que sabe cuándo termina, y todo
> conjunto de goroutines tiene un tope. Si arrancas una goroutine y no puedes decir
> quién la espera, está mal.

### Y la otra mitad: `sync`

Los canales no son la respuesta a todo, y el propio equipo de Go lo dice. Para
proteger estado compartido, un mutex es más simple:

```go
type Store struct {
	mu    sync.RWMutex                     // el mutex va JUNTO a lo que protege
	items map[string]workitem.WorkItem
}

func (s *Store) Save(item workitem.WorkItem) error {
	s.mu.Lock()
	defer s.mu.Unlock()
	s.items[item.ID] = item
	return nil
}

func (s *Store) FindByID(id string) (workitem.WorkItem, error) {
	s.mu.RLock()                           // RLock: varios lectores a la vez
	defer s.mu.RUnlock()
	item, ok := s.items[id]
	if !ok {
		return workitem.WorkItem{}, ErrNotFound
	}
	return item, nil
}
```

> 🧭 **Convención del ecosistema.** El mutex se declara **inmediatamente encima**
> del campo que protege, y si protege varios, con un comentario que lo diga. Un
> `sync.Mutex` suelto al principio del struct, sin relación visible con nada, es
> cómo se pierde la pista de qué protege qué.

Y la pieza que falta, que a un dev de Java le sorprende:

> ⚠️ **Un `sync.Mutex` en Go no es reentrante.** Si un método con el lock tomado
> llama a otro método que también lo toma, **deadlock inmediato**. `ReentrantLock`
> y `synchronized` de Java sí son reentrantes y eso permite un estilo que aquí se
> cuelga. La solución es la convención de la stdlib: el método exportado toma el
> lock y llama a un método privado `xxxLocked` que asume que ya está tomado.

El resto de `sync`, en una pasada:

```go
var wg sync.WaitGroup      // esperar a N goroutines. Add ANTES de lanzar.
var once sync.Once         // ejecutar algo exactamente una vez
var mu sync.Mutex          // exclusión mutua
var rw sync.RWMutex        // varios lectores O un escritor

atomic.AddInt64(&counter, 1)        // operaciones atómicas sin lock
atomic.LoadInt64(&counter)
```

📖 `WaitGroup` es `CountDownLatch` con el contador dinámico. `Once` es el
*double-checked locking* que en Java se escribe con `volatile` y todo el mundo se
equivoca al menos una vez. `atomic` es `AtomicInteger`, con la diferencia de que
en Go **es una función sobre una variable**, no un tipo envoltorio — así que
`counter++` a secas sigue siendo una carrera aunque el contador se lea con
`atomic.Load`.

### El detector de carreras

```bash
go1.13 test -race ./...
go1.13 run -race ./cmd/opsreport
```

`-race` instrumenta el binario para registrar cada acceso a memoria y detectar
cuándo dos goroutines tocan la misma dirección sin sincronización, **con al menos
una escritura**. Cuando lo encuentra, imprime las dos pilas.

**No es un análisis estático: solo detecta lo que ocurre.** Si tu test no ejerce
el camino con concurrencia, `-race` no ve nada. Por eso los tests de concurrencia
tienen que hacer trabajo de verdad, no una llamada.

> 📐 **Cómo se mide.** Entrada **B-10**: *cuánto cuesta `-race` en tiempo y
> memoria*. La regla que la documentación de Go da —del orden de 2 a 20 veces más
> lento y de 5 a 10 veces más memoria— es lo bastante amplia como para que merezca
> medirla sobre tu propia suite. Compara `go1.13 test ./...` contra
> `go1.13 test -race ./...` sobre la suite de la Fase 04 y sobre la de hoy: **el
> sobrecoste depende de cuánta memoria compartida se toque**, y tu suite de hoy
> toca mucha más.

### 🩻 Esto sí funciona igual

- **El modelo de memoria tiene la misma forma.** "Sucede antes" (*happens-before*)
  es el mismo concepto que en el JMM; solo cambian las operaciones que lo
  establecen. Tu intuición sobre visibilidad y reordenamiento se traslada.
- **Las carreras de datos son igual de malas y por las mismas razones.** El
  compilador y la CPU pueden reordenar; un `int` puede leerse a medias.
- **Los patrones clásicos son los mismos**: productor-consumidor, fan-out/fan-in,
  pipeline, semáforo. Los vas a reconocer; lo que cambia es la primitiva con la
  que se construyen.
- **Los deadlocks se producen igual**: espera circular, y se evitan igual, con
  orden total de adquisición de locks.
- **La contrapresión es el mismo problema.** Una cola sin límite es tan mala en
  Java como en Go; `ThreadPoolExecutor` con `LinkedBlockingQueue` sin capacidad es
  exactamente el mismo bug.
- **El estado inmutable sigue siendo la mejor defensa.** Lo que no se comparte
  mutable no puede tener carreras, aquí y allá.

---

## 🛠️ 5. CLI de la fase

```bash
# EL comando de la fase. A partir de hoy no se abre un PR sin él.
go1.13 test -race ./...

# También funciona sobre un binario que se ejecuta, no solo sobre tests.
go1.13 run -race ./cmd/opsreport

# Y sobre un binario compilado, para pruebas de carga con instrumentación.
go1.13 build -race -o bin/opsreport-race ./cmd/opsreport

# -cpu fuerza distintos valores de GOMAXPROCS en la misma corrida. Es la forma
# de sacar carreras que solo aparecen con paralelismo real, y de comprobar que
# tu código funciona con un solo núcleo.
go1.13 test -race -cpu=1,2,4,8 ./internal/engine

# -count repite la suite. Las carreras son probabilísticas: un test que pasa una
# vez no prueba nada. Con -race y -count=20, si hay carrera suele salir.
go1.13 test -race -count=20 ./internal/engine

# -timeout mata la suite si se cuelga, e imprime TODAS las pilas de goroutines.
# Ante un deadlock, esta salida es el diagnóstico completo.
go1.13 test -timeout 10s ./...

# -parallel controla cuántos tests con t.Parallel() corren a la vez.
go1.13 test -parallel 8 ./...

# Volcar todas las pilas de un proceso vivo, sin depurador: mándale SIGQUIT.
kill -QUIT <pid>
# En un programa en primer plano, Ctrl+\ hace lo mismo.

# GODEBUG: el runtime informa de su propio comportamiento.
# schedtrace imprime el estado del planificador cada N milisegundos.
GODEBUG=schedtrace=1000 go1.13 run ./cmd/opsreport

# scheddetail añade el detalle por procesador lógico y por goroutine.
GODEBUG=schedtrace=1000,scheddetail=1 go1.13 run ./cmd/opsreport

# gctrace muestra cada recolección de basura. Útil para ver el efecto de crear
# cien mil goroutines.
GODEBUG=gctrace=1 go1.13 run ./cmd/opsreport

# GOMAXPROCS limita cuántas goroutines ejecutan código a la vez. Ponerlo a 1 es
# un test valioso: si tu código se cuelga con GOMAXPROCS=1, tienes un problema de
# diseño que el paralelismo estaba escondiendo.
GOMAXPROCS=1 go1.13 test ./...

# Benchmarks concurrentes: b.RunParallel reparte las iteraciones entre goroutines.
go1.13 test -run '^$' -bench . -benchmem -cpu=1,4,8 ./labs/race-counter
```

> 💡 **`-cpu=1,2,4,8` es el comando infravalorado de esta fase.** Corre la misma
> suite cuatro veces con distinto paralelismo. Muchas carreras solo se manifiestan
> con más de un procesador lógico, y muchos deadlocks solo con uno. Ponerlo en CI
> cuesta tiempo de compilación cero y encuentra cosas.

---

## 💻 6. Construcción guiada

### 6.1 Mini proyecto: `race-counter`

La carrera que `-race` encuentra y el ojo no. Y el detalle que la hace didáctica:
**el programa parece funcionar**.

```go
// labs/race-counter/counter.go
package counter

import "sync"

// Unsafe incrementa sin ninguna sincronización. Es lo que todo el mundo escribe
// la primera vez, y produce un resultado equivocado sin dar ningún síntoma.
type Unsafe struct{ n int }

func (c *Unsafe) Inc() { c.n++ }
func (c *Unsafe) Get() int { return c.n }

// WithMutex protege con exclusión mutua.
type WithMutex struct {
	mu sync.Mutex
	n  int
}

func (c *WithMutex) Inc() {
	c.mu.Lock()
	defer c.mu.Unlock()
	c.n++
}

func (c *WithMutex) Get() int {
	c.mu.Lock()
	defer c.mu.Unlock()
	return c.n
}

// WithAtomic usa una operación atómica. Menos flexible —solo sirve para
// operaciones que el hardware soporta— y bastante más rápida.
type WithAtomic struct{ n int64 }

func (c *WithAtomic) Inc() { atomic.AddInt64(&c.n, 1) }
func (c *WithAtomic) Get() int64 { return atomic.LoadInt64(&c.n) }

// WithChannel serializa a través de una goroutine propietaria del estado.
// Es el "no comuniques compartiendo memoria; comparte memoria comunicando" del
// proverbio, llevado al extremo — y para un contador es exagerado. Está aquí
// para medirlo (B-08) y para que veas cuándo NO usar canales.
type WithChannel struct {
	incs chan struct{}
	gets chan chan int64
	done chan struct{}
}

func NewWithChannel() *WithChannel {
	c := &WithChannel{
		incs: make(chan struct{}, 1024),
		gets: make(chan chan int64),
		done: make(chan struct{}),
	}
	go c.loop()
	return c
}

// loop es la ÚNICA goroutine que toca n. Sin locks porque no hay nada que
// proteger: el estado tiene un solo dueño.
func (c *WithChannel) loop() {
	var n int64
	for {
		select {
		case <-c.incs:
			n++
		case reply := <-c.gets:
			reply <- n
		case <-c.done:
			return
		}
	}
}

func (c *WithChannel) Inc() { c.incs <- struct{}{} }

func (c *WithChannel) Get() int64 {
	reply := make(chan int64)
	c.gets <- reply
	return <-reply
}

// Close para la goroutine propietaria. Sin esto, hay fuga: la goroutine de loop
// vive para siempre. Es la lección del leak-lab, adelantada.
func (c *WithChannel) Close() { close(c.done) }
```

Y el test que lo destapa:

```go
// labs/race-counter/counter_test.go
func TestUnsafe_LosesIncrements(t *testing.T) {
	c := &Unsafe{}

	var wg sync.WaitGroup
	const goroutines, each = 100, 1000

	wg.Add(goroutines)
	for i := 0; i < goroutines; i++ {
		go func() {
			defer wg.Done()
			for j := 0; j < each; j++ {
				c.Inc()
			}
		}()
	}
	wg.Wait()

	want := goroutines * each
	if got := c.Get(); got != want {
		t.Logf("se perdieron %d incrementos de %d (%.1f%%)",
			want-got, want, 100*float64(want-got)/float64(want))
	}
	// Deliberadamente NO falla el test: queremos que se ejecute y se vea.
}
```

```bash
go1.13 test -run TestUnsafe -v ./labs/race-counter
# se perdieron 41208 incrementos de 100000 (41.2%)

go1.13 test -race -run TestUnsafe ./labs/race-counter
```

```text
==================
WARNING: DATA RACE
Read at 0x00c0000a4010 by goroutine 9:
  github.com/meridian/labs/counter.(*Unsafe).Inc()
      /Users/tu/dev/meridian/labs/race-counter/counter.go:9 +0x3c

Previous write at 0x00c0000a4010 by goroutine 8:
  github.com/meridian/labs/counter.(*Unsafe).Inc()
      /Users/tu/dev/meridian/labs/race-counter/counter.go:9 +0x50

Goroutine 9 (running) created at:
  github.com/meridian/labs/counter.TestUnsafe_LosesIncrements()
      /Users/tu/dev/meridian/labs/race-counter/counter_test.go:12 +0xd8
...
==================
```

**Léelo entero, porque es el formato que vas a ver durante todo el curso.** Tiene
tres partes: el acceso que disparó la detección, el acceso anterior en conflicto,
y dónde se creó cada goroutine. Esa tercera parte es la que suele resolver el
caso: te dice quién lanzó al culpable.

> 📐 **Cómo se mide.** Entrada **B-08**: *canal con búfer frente a mutex para un
> contador*. Las cuatro implementaciones están escritas; el benchmark usa
> `b.RunParallel` y se corre con `-cpu=1,4,8`. **El veredicto está cantado y hay
> que sostenerlo con números:** para proteger un contador, `atomic` gana, el mutex
> va detrás, y el canal es entre uno y dos órdenes de magnitud más lento. Eso **no**
> significa que los canales sean lentos: significa que un canal es una herramienta
> de **transferencia de propiedad y sincronización**, no un sustituto de un lock.
> Usar la herramienta equivocada cuesta caro en cualquier lenguaje.

> 🧭 **Regla del proyecto.** *"No comuniques compartiendo memoria; comparte memoria
> comunicando"* es un proverbio excelente y **no es una prohibición de usar
> mutex**. La versión completa, del propio wiki de Go: *"usa canales para pasar la
> propiedad de datos, usa mutex para proteger estado compartido"*. Un contador es
> estado compartido.

### 6.2 Mini proyecto: `deadlock-lab`

Cuatro formas de colgar un programa, y cómo se ve cada una.

```go
// labs/deadlock-lab/deadlock.go
package deadlock

import "sync"

// 1. El canal sin búfer sin receptor.
// Go DETECTA este caso: si TODAS las goroutines están dormidas, el runtime lo
// sabe y mata el programa con un mensaje claro.
func UnbufferedNoReceiver() {
	ch := make(chan int)
	ch <- 1 // fatal error: all goroutines are asleep - deadlock!
}

// 2. El WaitGroup con el contador mal.
// Wait() espera un Done() que nunca llega. También lo detecta el runtime.
func WaitGroupMismatch() {
	var wg sync.WaitGroup
	wg.Add(2)             // se prometieron dos
	go func() { wg.Done() }() // solo llegó una
	wg.Wait()             // fatal error: all goroutines are asleep - deadlock!
}

// 3. Dos mutex tomados en orden distinto. El clásico de los libros.
// El runtime NO lo detecta si hay alguna otra goroutine viva (por ejemplo, el
// servidor HTTP): el programa simplemente se cuelga, sin mensaje.
type Account struct {
	mu      sync.Mutex
	balance int64
}

func TransferDeadlock(from, to *Account, amount int64) {
	from.mu.Lock()
	defer from.mu.Unlock()

	// Ventana para que la transferencia inversa tome el otro lock.
	time.Sleep(time.Millisecond)

	to.mu.Lock()
	defer to.mu.Unlock()

	from.balance -= amount
	to.balance += amount
}

// TransferOrdered lo arregla con la única técnica que funciona: un ORDEN TOTAL
// de adquisición. Se toma siempre primero el de identificador menor.
func TransferOrdered(from, to *Account, amount int64) {
	first, second := from, to
	if from.id > to.id {
		first, second = to, from
	}

	first.mu.Lock()
	defer first.mu.Unlock()
	second.mu.Lock()
	defer second.mu.Unlock()

	from.balance -= amount
	to.balance += amount
}

// 4. El mutex no reentrante. LA sorpresa para quien viene de Java.
type Registry struct {
	mu    sync.Mutex
	items map[string]int
}

func (r *Registry) Add(key string) {
	r.mu.Lock()
	defer r.mu.Unlock()

	if r.Has(key) { // ← Has también toma el lock: deadlock inmediato
		return
	}
	r.items[key] = 1
}

func (r *Registry) Has(key string) bool {
	r.mu.Lock()
	defer r.mu.Unlock()
	_, ok := r.items[key]
	return ok
}

// La convención de la stdlib para arreglarlo: el método exportado toma el lock,
// el privado con sufijo "Locked" asume que ya está tomado.
func (r *Registry) AddFixed(key string) {
	r.mu.Lock()
	defer r.mu.Unlock()

	if r.hasLocked(key) {
		return
	}
	r.items[key] = 1
}

// hasLocked asume que r.mu ya está tomado. El nombre es el contrato.
func (r *Registry) hasLocked(key string) bool {
	_, ok := r.items[key]
	return ok
}
```

🧨 **Rompe a propósito.** Corre los cuatro. Los casos 1 y 2 producen esto:

```text
fatal error: all goroutines are asleep - deadlock!

goroutine 1 [chan send]:
main.main()
	/Users/tu/dev/meridian/labs/deadlock-lab/main.go:8 +0x3c
exit status 2
```

**Ese mensaje es un regalo**, y Java no lo tiene: el runtime de Go sabe cuántas
goroutines hay y en qué están bloqueadas, así que puede afirmar con certeza que
nada va a progresar. Fíjate en `[chan send]`: el estado de la goroutine te dice en
qué primitiva está parada.

Los casos 3 y 4 **no** producen mensaje si hay otra goroutine viva: el programa se
queda quieto. Ahí la herramienta es `SIGQUIT`:

```bash
./bin/deadlock-demo &
kill -QUIT $!
```

Y obtienes todas las pilas, con el estado de cada goroutine:

```text
goroutine 18 [semacquire]:
sync.runtime_SemacquireMutex(...)
main.TransferDeadlock(...)
	/Users/tu/dev/meridian/labs/deadlock-lab/deadlock.go:31

goroutine 19 [semacquire]:
sync.runtime_SemacquireMutex(...)
main.TransferDeadlock(...)
	/Users/tu/dev/meridian/labs/deadlock-lab/deadlock.go:31
```

Dos goroutines en `semacquire` en la misma línea: espera circular, diagnóstico
cerrado.

> 💡 **`go test -timeout` hace lo mismo automáticamente.** Cuando la suite excede
> el tiempo, el runner imprime todas las pilas antes de morir. Por eso
> `-timeout 10s` es mejor que el valor por defecto de diez minutos: te da el
> diagnóstico en diez segundos en vez de dejarte esperando.

### 6.3 Mini proyecto: `leak-lab`

La goroutine que nadie recoge. Es la fuga más común de Go y **no la detecta
`-race`**, porque no es una carrera: es una goroutine bloqueada para siempre.

```go
// labs/leak-lab/leak.go
package leak

import "time"

// SearchLeaky lanza tres búsquedas y devuelve la primera que responda.
// Las otras dos se quedan bloqueadas para SIEMPRE intentando enviar a un canal
// sin búfer del que ya nadie lee.
func SearchLeaky(query string) string {
	results := make(chan string) // ← sin búfer: el problema

	go func() { results <- searchDB(query) }()
	go func() { results <- searchCache(query) }()
	go func() { results <- searchIndex(query) }()

	return <-results // se lee UNA; las otras dos goroutines quedan colgadas
}

// SearchFixed usa un búfer del tamaño del número de productores. Todas pueden
// enviar y terminar; el búfer se recolecta cuando nadie lo referencia.
func SearchFixed(query string) string {
	results := make(chan string, 3) // ← capacidad 3: nadie se bloquea

	go func() { results <- searchDB(query) }()
	go func() { results <- searchCache(query) }()
	go func() { results <- searchIndex(query) }()

	return <-results
}
```

Y el test que la caza, **a mano**, porque `goleak` es de la Fase 08:

```go
// labs/leak-lab/leak_test.go
func TestSearchLeaky_LeaksGoroutines(t *testing.T) {
	// La línea base tiene que tomarse después de que el runtime se estabilice.
	runtime.GC()
	time.Sleep(50 * time.Millisecond)
	before := runtime.NumGoroutine()

	for i := 0; i < 100; i++ {
		SearchLeaky("tiendas del norte")
	}

	// Dar tiempo a que lo que TENÍA que terminar, termine.
	time.Sleep(200 * time.Millisecond)
	runtime.GC()

	after := runtime.NumGoroutine()
	leaked := after - before

	t.Logf("goroutines antes=%d después=%d fugadas=%d", before, after, leaked)
	if leaked > 10 {
		t.Errorf("se fugaron %d goroutines; el recolector NO las recoge", leaked)
	}
}
```

```text
goroutines antes=2 después=202 fugadas=200
```

Doscientas goroutines vivas, bloqueadas para siempre, cada una reteniendo su pila
y todo lo que su closure captura.

> ⚠️ **El recolector de basura NO recoge goroutines bloqueadas.** Una goroutine
> esperando en un canal es alcanzable por definición —el runtime la tiene en su
> lista de ejecución— y su memoria no se libera. **Una fuga de goroutines es una
> fuga de memoria permanente**, y en un servidor de larga duración crece hasta
> matar el proceso.
>
> En Java el paralelo exacto es un hilo bloqueado en una cola que nadie alimenta:
> mismo problema, misma consecuencia. La diferencia es que **crear goroutines es
> tan barato que se crean muchas más**, y por eso las fugas se acumulan más
> rápido.

Las tres causas, que cubren el 95% de los casos:

1. **Envío a un canal sin receptor** (el ejemplo de arriba).
2. **Recepción de un canal que nadie cierra** — el `for range ch` eterno.
3. **Un `select` sin caso de salida** — se resuelve con `context`, Fase 07.

### 6.4 Mini proyecto: `unbounded-queue`

Por qué la cola sin límite convierte un pico de tráfico en un OOM.

```go
// labs/unbounded-queue/queue.go
package queue

// Unbounded acepta trabajo sin límite. Cada Submit lanza una goroutine; con un
// pico de tráfico, se lanzan tantas como peticiones lleguen.
//
// Es exactamente lo que hace un ThreadPoolExecutor con LinkedBlockingQueue sin
// capacidad, y el resultado es el mismo: la cola crece hasta que la memoria se
// acaba. La diferencia en Go es que goroutines baratas hacen que llegues al
// límite MÁS TARDE, y por eso duele más cuando llega.
type Unbounded struct {
	wg sync.WaitGroup
}

func (q *Unbounded) Submit(job Job) {
	q.wg.Add(1)
	go func() {
		defer q.wg.Done()
		job.Run() // cada job reserva 1 MB y tarda 100 ms
	}()
}

// Bounded acota de dos formas a la vez, y hay que entender que son DISTINTAS:
//   - el búfer del canal limita cuántos jobs esperan  (la cola)
//   - el número de workers limita cuántos se ejecutan (el paralelismo)
type Bounded struct {
	jobs chan Job
	wg   sync.WaitGroup
}

func NewBounded(queueSize, workers int) *Bounded {
	q := &Bounded{jobs: make(chan Job, queueSize)}

	q.wg.Add(workers)
	for i := 0; i < workers; i++ {
		go func() {
			defer q.wg.Done()
			for job := range q.jobs {
				job.Run()
			}
		}()
	}
	return q
}

// ErrQueueFull es contrapresión: se devuelve cuando la cola está llena.
//
// Devolver un error es MEJOR que encolar indefinidamente, y es el punto entero
// de este laboratorio. Un 503 rápido le dice al cliente que reintente más tarde;
// una cola infinita le dice que todo va bien mientras el servidor agoniza.
var ErrQueueFull = errors.New("la cola de trabajos está llena")

func (q *Bounded) Submit(job Job) error {
	select {
	case q.jobs <- job:
		return nil
	default:
		return ErrQueueFull
	}
}

// SubmitWait es la variante que espera hasta un límite de tiempo antes de
// rendirse. Es más amable con picos cortos y sigue teniendo tope.
func (q *Bounded) SubmitWait(job Job, timeout time.Duration) error {
	timer := time.NewTimer(timeout)
	defer timer.Stop() // sin este Stop, el timer no se recolecta hasta expirar

	select {
	case q.jobs <- job:
		return nil
	case <-timer.C:
		return ErrQueueFull
	}
}

func (q *Bounded) Shutdown() {
	close(q.jobs) // los workers salen de su `for range` al vaciarse la cola
	q.wg.Wait()
}
```

🧨 **Rompe a propósito.** El experimento: simula un pico de 50.000 peticiones en
dos segundos contra las dos colas, con jobs que reservan 1 MB y tardan 100 ms.
Mide `runtime.MemStats.Sys` cada 100 ms.

- **`Unbounded`**: 50.000 goroutines vivas, 50 GB de reservas pendientes, y el
  proceso muere por OOM o el sistema empieza a paginar.
- **`Bounded(1000, 8)`**: memoria estable, 8 jobs en vuelo, 1.000 esperando, y
  **49.000 peticiones rechazadas con `ErrQueueFull`**.

**La segunda parece peor y es infinitamente mejor.** Rechazar el 98% del pico y
servir el 2% correctamente es un servicio degradado; aceptar el 100% y morir es
una caída total, y además se lleva por delante el trabajo que ya estaba en curso.

> 📐 **Cómo se mide.** Entrada **B-09**: *worker pool acotado frente a goroutine
> por tarea, bajo pico*. Se reportan memoria máxima, trabajos completados,
> trabajos rechazados y latencia p99 de los aceptados. **El veredicto tiene que
> decir explícitamente que "trabajos rechazados" no es una derrota**: es el
> mecanismo funcionando.

### 6.5 OpsReport: el motor de jobs

Todo lo anterior, aplicado. Este es el entregable de la fase.

```go
// services/opsreport/internal/engine/engine.go

// Package engine ejecuta work items en segundo plano con concurrencia acotada.
//
// El diseño responde a las tres garantías que un ExecutorService daba y que en Go
// hay que construir: un límite (el búfer del canal y el número de workers), un
// resultado (el JobExecution que se persiste) y un apagado (Shutdown).
package engine

import (
	"log"
	"sync"
	"time"

	"github.com/meridian/opsreport/internal/workitem"
)

// Runner ejecuta un work item. Es la interfaz que el motor CONSUME: cada tipo de
// trabajo —conciliación, importación, recálculo— tendrá su implementación.
type Runner interface {
	Run(item workitem.WorkItem) error
}

// Store es lo que el motor necesita para registrar el progreso. Dos métodos.
type Store interface {
	Update(item workitem.WorkItem) error
	SaveExecution(exec workitem.JobExecution) error
}

type Clock interface{ Now() time.Time }

// Engine es el motor de jobs.
type Engine struct {
	runner  Runner
	store   Store
	clock   Clock
	workers int

	jobs chan workitem.WorkItem
	wg   sync.WaitGroup

	// quit se CIERRA para señalizar el apagado. Cerrar un canal es la forma
	// idiomática de avisar a N receptores a la vez: todos ven el cierre.
	//
	// En la Fase 07 esto lo sustituye context.Context, que es exactamente este
	// mecanismo empaquetado con plazos y propagación. Verlo a mano primero hace
	// que context se entienda enseguida.  💸
	quit     chan struct{}
	quitOnce sync.Once // para que dos llamadas a Shutdown no cierren dos veces

	// mu protege los contadores de estadísticas de abajo.
	mu        sync.Mutex
	completed int
	failed    int
	rejected  int
}

func New(runner Runner, store Store, clock Clock, workers, queueSize int) *Engine {
	if workers < 1 {
		workers = 1
	}
	if queueSize < 1 {
		queueSize = 1
	}
	return &Engine{
		runner:  runner,
		store:   store,
		clock:   clock,
		workers: workers,
		jobs:    make(chan workitem.WorkItem, queueSize),
		quit:    make(chan struct{}),
	}
}

// Start arranca los workers. Se llama una vez, desde main, antes de servir.
func (e *Engine) Start() {
	e.wg.Add(e.workers)
	for i := 0; i < e.workers; i++ {
		go e.worker(i)
	}
	log.Printf("motor de jobs arrancado con %d workers y cola de %d",
		e.workers, cap(e.jobs))
}

// Submit encola un trabajo. Devuelve ErrQueueFull si la cola está llena, que el
// handler HTTP traduce a 503 con Retry-After.
//
// El select con default es lo que convierte esto en contrapresión en vez de en
// una cola infinita.
func (e *Engine) Submit(item workitem.WorkItem) error {
	select {
	case <-e.quit:
		return ErrShuttingDown
	default:
	}

	select {
	case e.jobs <- item:
		return nil
	default:
		e.mu.Lock()
		e.rejected++
		e.mu.Unlock()
		return ErrQueueFull
	}
}

// worker consume trabajos hasta que el canal se cierra.
//
// Fíjate en que NO mira e.quit dentro del bucle: el apagado se señaliza cerrando
// e.jobs, y `for range` termina solo al vaciarse. Eso hace un apagado que DRENA
// la cola. Si quisiéramos abortar el trabajo pendiente, ahí sí haría falta el
// select con e.quit — y es exactamente la distinción que la Fase 07 formaliza
// entre apagado ordenado y cancelación.
func (e *Engine) worker(id int) {
	defer e.wg.Done()

	for item := range e.jobs {
		e.execute(id, item)
	}
	log.Printf("worker %d terminado", id)
}

// execute corre un trabajo y registra su ejecución, pase lo que pase.
func (e *Engine) execute(workerID int, item workitem.WorkItem) {
	start := e.clock.Now()

	// El recover es OBLIGATORIO aquí. Un panic dentro de un Runner —un índice
	// fuera de rango en el parser de un proveedor— mataría el proceso ENTERO,
	// no solo este job. net/http recupera los panics de sus handlers; nadie
	// recupera los de tus goroutines.
	var runErr error
	func() {
		defer func() {
			if rec := recover(); rec != nil {
				runErr = fmt.Errorf("el trabajo entró en panic: %v", rec)
				log.Printf("PANIC en el worker %d ejecutando %s: %v\n%s",
					workerID, item.ID, rec, debug.Stack())
			}
		}()
		runErr = e.runner.Run(item)
	}()

	finish := e.clock.Now()

	if err := item.MarkRunning(start); err != nil {
		// El item cambió de estado por debajo (alguien lo canceló). No es un
		// error del motor: se registra y se sigue.
		log.Printf("worker %d: %s ya no estaba encolado: %v", workerID, item.ID, err)
		return
	}

	exec := workitem.JobExecution{
		WorkItemID: item.ID,
		WorkerID:   workerID,
		StartedAt:  start,
		FinishedAt: finish,
		DurationMS: finish.Sub(start).Milliseconds(),
	}

	if runErr != nil {
		exec.Error = runErr.Error()
		_ = item.MarkFailed(finish, runErr.Error())
		e.countFailure()
	} else {
		_ = item.MarkDone(finish)
		e.countSuccess()
	}

	if err := e.store.SaveExecution(exec); err != nil {
		log.Printf("worker %d: no se pudo registrar la ejecución de %s: %v",
			workerID, item.ID, err)
	}
	if err := e.store.Update(item); err != nil {
		log.Printf("worker %d: no se pudo actualizar %s: %v", workerID, item.ID, err)
	}
}

func (e *Engine) countSuccess() {
	e.mu.Lock()
	defer e.mu.Unlock()
	e.completed++
}

func (e *Engine) countFailure() {
	e.mu.Lock()
	defer e.mu.Unlock()
	e.failed++
}

// Stats devuelve una copia de los contadores. Devolver una copia y no punteros
// al estado interno es lo que hace que el llamador no pueda provocar una carrera
// sin querer.
func (e *Engine) Stats() Stats {
	e.mu.Lock()
	defer e.mu.Unlock()
	return Stats{
		Completed: e.completed,
		Failed:    e.failed,
		Rejected:  e.rejected,
		QueueLen:  len(e.jobs),
		QueueCap:  cap(e.jobs),
	}
}

// Shutdown deja de aceptar trabajo, drena la cola y espera a los workers.
//
// sync.Once garantiza que llamarlo dos veces no entre en panic por cerrar un
// canal cerrado. Es un detalle pequeño y es exactamente el tipo de cosa que en
// producción pasa: dos rutas de apagado que se disparan a la vez.
//
// Lo que le FALTA —un tiempo límite, para no esperar eternamente a un worker
// atascado— es de la Fase 07.  💸
func (e *Engine) Shutdown() {
	e.quitOnce.Do(func() {
		close(e.quit)  // Submit empieza a rechazar
		close(e.jobs)  // los workers salen al vaciar la cola
	})
	e.wg.Wait()
	log.Printf("motor detenido: %+v", e.Stats())
}
```

Y el `memstore` que por fin aprende a convivir con esto:

```go
// services/opsreport/internal/memstore/store.go

// Store guarda work items en memoria.
//
// ES seguro para uso concurrente desde la Fase 06: el motor de jobs y los
// handlers HTTP lo comparten, y net/http sirve cada petición en su propia
// goroutine.
type Store struct {
	// mu protege items y executions. RWMutex y no Mutex porque el patrón de
	// acceso es de muchas lecturas y pocas escrituras: la cola se consulta en
	// cada petición y se modifica solo al crear o al cambiar de estado.
	mu         sync.RWMutex
	items      map[string]workitem.WorkItem
	executions []workitem.JobExecution
}

func (s *Store) ListByStatus(status workitem.Status) ([]workitem.WorkItem, error) {
	s.mu.RLock()
	defer s.mu.RUnlock()

	out := make([]workitem.WorkItem, 0, len(s.items))
	for _, item := range s.items {
		if item.Status == status {
			// Los WorkItem son valores: al copiarlos al slice, el llamador
			// recibe copias y no puede tocar el estado interno. Si tuvieran un
			// campo slice o map, habría que copiarlo a mano — es la lección de
			// la Fase 01 y aquí es una cuestión de corrección concurrente, no
			// solo de aliasing.
			out = append(out, item)
		}
	}
	return out, nil
}
```

> 🧪 **Prueba de fuego.** Antes de poner el mutex, corre esto:
> ```bash
> go1.13 build -race -o bin/opsreport-race ./cmd/opsreport
> ./bin/opsreport-race &
> for i in $(seq 1 200); do
>   curl -s -X POST localhost:8080/work-items \
>     -H 'Content-Type: application/json' \
>     -d "{\"external_reference\":\"SAP-$i\",\"kind\":\"import\",\"priority\":5}" &
> done
> wait
> ```
> Vas a ver el `WARNING: DATA RACE` sobre el mapa de `memstore`, con una goroutine
> de `net/http` en cada pila. **Esa carrera lleva ahí desde la Fase 05** y ningún
> test la había detectado, porque los tests llamaban al handler de uno en uno.
>
> **La mentira de la pantalla:** sin `-race`, esas 200 peticiones responden 201 y
> todo parece correcto. Un mapa de Go corrompido por escritura concurrente puede
> tardar miles de peticiones en manifestarse, y cuando lo hace es con un
> `fatal error: concurrent map writes` que mata el proceso **sin recuperación
> posible** —ese panic en concreto no se puede capturar con `recover`—.

### 6.6 EventRelay: la cola de entregas, con una carrera a propósito

El segundo servicio, y aquí la primera versión **tiene un bug deliberado**.

```go
// services/eventrelay/internal/dispatcher/dispatcher.go — PRIMERA VERSIÓN, CON BUG

type Dispatcher struct {
	sender  Sender
	store   Store
	workers int

	deliveries chan relay.Delivery
	wg         sync.WaitGroup

	// ☕ BUG DELIBERADO: este contador lo tocan N workers sin sincronización.
	attemptCount int
}

func (d *Dispatcher) worker(id int) {
	defer d.wg.Done()

	for delivery := range d.deliveries {
		d.attemptCount++ // ← carrera de datos

		err := d.sender.Send(delivery)
		// ...
	}
}
```

```bash
go1.13 test -race -run TestDispatcher_ConcurrentDeliveries ./internal/dispatcher
```

```text
WARNING: DATA RACE
Write at 0x00c0000b4030 by goroutine 12:
  ...dispatcher.(*Dispatcher).worker()
      dispatcher.go:47 +0x64
Previous write at 0x00c0000b4030 by goroutine 11:
  ...dispatcher.(*Dispatcher).worker()
      dispatcher.go:47 +0x64
```

Y la versión correcta, con el límite **por endpoint** que es lo que de verdad
necesita EventRelay:

```go
// services/eventrelay/internal/dispatcher/dispatcher.go — VERSIÓN CORRECTA

type Dispatcher struct {
	sender Sender
	store  Store
	clock  Clock

	deliveries chan relay.Delivery
	wg         sync.WaitGroup
	quit       chan struct{}
	quitOnce   sync.Once

	attempts int64 // se toca solo con atomic

	// endpointLimits es un semáforo POR ENDPOINT: un socio lento no puede
	// acaparar los workers y dejar sin servicio a los otros veintinueve.
	//
	// Es el problema real que EventRelay resuelve, y la razón por la que un
	// simple worker pool global no basta: con ocho workers y un socio que tarda
	// ocho segundos, ocho entregas a ese socio bloquean el servicio entero.
	limitsMu       sync.Mutex
	endpointLimits map[string]chan struct{}
	perEndpoint    int
}

func New(sender Sender, store Store, clock Clock, workers, queueSize, perEndpoint int) *Dispatcher {
	d := &Dispatcher{
		sender:         sender,
		store:          store,
		clock:          clock,
		deliveries:     make(chan relay.Delivery, queueSize),
		quit:           make(chan struct{}),
		endpointLimits: make(map[string]chan struct{}),
		perEndpoint:    perEndpoint,
	}
	d.wg.Add(workers)
	for i := 0; i < workers; i++ {
		go d.worker(i)
	}
	return d
}

// acquire obtiene un permiso para entregar a un endpoint concreto.
//
// El semáforo es un canal con búfer: enviar es adquirir, recibir es liberar.
// Es literalmente lo que hace semaphore.Weighted de golang.org/x/sync, que
// llega en la Fase 08. 🕰️
func (d *Dispatcher) acquire(endpointID string) func() {
	d.limitsMu.Lock()
	sem, ok := d.endpointLimits[endpointID]
	if !ok {
		sem = make(chan struct{}, d.perEndpoint)
		d.endpointLimits[endpointID] = sem
	}
	d.limitsMu.Unlock()

	sem <- struct{}{} // adquirir: se bloquea si ya hay perEndpoint en vuelo

	// Devolver la función de liberación es un idioma común en Go y evita que el
	// llamador tenga que saber de qué canal se trata.
	return func() { <-sem }
}

func (d *Dispatcher) worker(id int) {
	defer d.wg.Done()

	for delivery := range d.deliveries {
		release := d.acquire(delivery.EndpointID)

		atomic.AddInt64(&d.attempts, 1)
		d.deliver(id, delivery)

		release()
	}
}

func (d *Dispatcher) deliver(workerID int, delivery relay.Delivery) {
	// El recover por worker, igual que en OpsReport: un panic en una entrega no
	// puede llevarse el proceso.
	defer func() {
		if rec := recover(); rec != nil {
			log.Printf("PANIC entregando %s: %v\n%s", delivery.ID, rec, debug.Stack())
		}
	}()

	now := d.clock.Now()
	err := d.sender.Send(delivery)

	if err != nil {
		if rerr := delivery.RecordFailure(now, err.Error()); rerr != nil {
			log.Printf("no se pudo registrar el fallo de %s: %v", delivery.ID, rerr)
			return
		}

		// 💸 El reintento se programa con un time.Timer POR ENTREGA. Con diez mil
		// entregas fallando, son diez mil timers vivos, y no escala.
		// Se paga en la Fase 09: la cola pasa a la base de datos y los
		// reintentos se eligen con un SELECT ... WHERE next_attempt <= now().
		if delivery.Status == relay.DeliveryFailing {
			d.scheduleRetry(delivery)
		}
	} else {
		_ = delivery.RecordSuccess(now)
	}

	if err := d.store.UpdateDelivery(delivery); err != nil {
		log.Printf("no se pudo actualizar la entrega %s: %v", delivery.ID, err)
	}
}

// scheduleRetry vuelve a encolar la entrega cuando llegue su momento.
func (d *Dispatcher) scheduleRetry(delivery relay.Delivery) {
	wait := delivery.NextAttempt.Sub(d.clock.Now())
	if wait < 0 {
		wait = 0
	}

	timer := time.NewTimer(wait)

	// Esta goroutine TIENE dueño: muere con el timer o con el apagado. Sin el
	// caso <-d.quit, cada reintento pendiente sería una fuga al apagar.
	go func() {
		defer timer.Stop()
		select {
		case <-timer.C:
			if err := delivery.Retry(); err == nil {
				select {
				case d.deliveries <- delivery:
				case <-d.quit:
				}
			}
		case <-d.quit:
			return
		}
	}()
}
```

> 💸 **Deudas declaradas.** (1) La cola de OpsReport vive **solo en memoria**: un
> reinicio pierde el trabajo encolado. **Se paga en la Fase 09.** (2) El
> planificador de reintentos de EventRelay usa un `time.Timer` por entrega. **Se
> paga en la Fase 09**, con `SELECT ... FOR UPDATE SKIP LOCKED`. (3) El apagado no
> tiene tiempo límite: un worker atascado bloquea el proceso para siempre. **Se
> paga en la Fase 07.**

### 6.7 Los patrones, construidos y no copiados

Los cuatro que el curso usa, escritos una vez para que los reconozcas:

```go
// labs/patterns/patterns.go

// 1. FAN-OUT / FAN-IN: repartir trabajo entre N workers y juntar los resultados.
func FanOutFanIn(inputs []Input, workers int) []Result {
	in := make(chan Input)
	out := make(chan Result)

	// Fan-out: N consumidores del mismo canal de entrada.
	var wg sync.WaitGroup
	wg.Add(workers)
	for i := 0; i < workers; i++ {
		go func() {
			defer wg.Done()
			for input := range in {
				out <- process(input)
			}
		}()
	}

	// Alimentador: cierra `in` al terminar, que es lo que hace salir a los
	// workers de su `for range`.
	go func() {
		defer close(in)
		for _, input := range inputs {
			in <- input
		}
	}()

	// Cerrador: cierra `out` cuando TODOS los workers terminaron. Sin esta
	// goroutine, el `for range out` de abajo no terminaría nunca.
	go func() {
		wg.Wait()
		close(out)
	}()

	// Fan-in: un solo lector junta todo.
	var results []Result
	for r := range out {
		results = append(results, r)
	}
	return results
}

// 2. PIPELINE: etapas conectadas por canales. Cada etapa cierra su salida.
func Pipeline(paths []string) <-chan Movement {
	return validate(parse(read(paths)))
}

func read(paths []string) <-chan []byte {
	out := make(chan []byte)
	go func() {
		defer close(out) // ← cada etapa cierra SU salida. La regla del pipeline.
		for _, p := range paths {
			data, err := ioutil.ReadFile(p)
			if err != nil {
				continue
			}
			out <- data
		}
	}()
	return out
}

func parse(in <-chan []byte) <-chan Movement {
	out := make(chan Movement)
	go func() {
		defer close(out)
		for data := range in {
			for _, m := range parseAll(data) {
				out <- m
			}
		}
	}()
	return out
}

// 3. SEMÁFORO con canal con búfer: limitar concurrencia sin un pool.
func WithSemaphore(items []Item, limit int) {
	sem := make(chan struct{}, limit)
	var wg sync.WaitGroup

	for _, item := range items {
		wg.Add(1)
		sem <- struct{}{} // adquirir (se bloquea si hay `limit` en vuelo)

		go func(item Item) {
			defer wg.Done()
			defer func() { <-sem }() // liberar, pase lo que pase
			process(item)
		}(item)
	}
	wg.Wait()
}

// 4. EL PRIMERO QUE RESPONDA, sin fugas. Compárese con SearchLeaky.
func FirstResult(query string) string {
	// Búfer = número de productores: todos pueden enviar y terminar.
	results := make(chan string, 3)

	go func() { results <- searchDB(query) }()
	go func() { results <- searchCache(query) }()
	go func() { results <- searchIndex(query) }()

	return <-results
}
```

> ⚠️ **La regla del pipeline que hay que memorizar: cada etapa cierra su canal de
> salida, nunca el de entrada.** Si una etapa intermedia cerrara su entrada, la
> anterior entraría en panic al intentar enviar. Es el error de diseño más común
> en pipelines y produce un `send on closed channel` desconcertante.

### 6.8 La conversación pendiente: hebras virtuales de Java 21

Si has seguido el curso pensando *"esto ya lo tengo con Loom"*, tienes razón y
merece decirse con todas las letras.

Las **hebras virtuales** de Java 21 son el paralelo más cercano a una goroutine que
existe fuera de Go: hilos ligeros planificados por la JVM sobre un pool de hilos
de plataforma, con pilas que crecen bajo demanda. `Thread.ofVirtual().start(...)`
y `Executors.newVirtualThreadPerTaskExecutor()` hacen desaparecer casi toda la
ventaja de coste que Go tenía en este terreno, y la comparación de B-07 cambia por
completo si el lado Java usa hebras virtuales en vez de hilos de plataforma.
**Ese es el escenario que hay que medir, y así se plantea la entrada.**

Lo que **sigue** siendo distinto, y conviene tenerlo claro:

- **Los canales y `select` son primitivas del lenguaje**, con soporte del
  compilador y del planificador. Java tiene `BlockingQueue` y ahora *structured
  concurrency*, y son librería.
- **El detector de carreras está en el toolchain**, no es una herramienta aparte.
- **`GOMAXPROCS` y el modelo M:N llevan quince años en producción**; las hebras
  virtuales son recientes y todavía tienen aristas conocidas (el *pinning* al
  bloquear dentro de `synchronized` es la más citada, y está mejorando versión a
  versión).
- Y en dirección contraria: **la observabilidad de la JVM es mejor.** JFR te dice
  qué está haciendo cada hebra virtual con un detalle que `pprof` no alcanza.

> ⚖️ **El veredicto honesto, adelantado.** Si tu argumento para migrar a Go era
> "las goroutines son más baratas que los hilos", **Java 21 se comió buena parte
> de ese argumento**. Lo que queda a favor de Go en concurrencia es el modelo de
> programación —canales y `select` como primitivas, `-race` incluido, apagado
> explícito— y eso es más una preferencia de diseño que una ventaja medible. Lo
> medimos de verdad en la Fase 16.

---

## ⚰️ 7. Autopsia y errores comunes

### ⚰️ Autopsia: el "pool" que era un `for` con `go` dentro

**El cadáver.** Meridian tenía un importador de catálogo de proveedor que procesaba
archivos por lotes. Este era su motor:

```go
// ☕
type ImportPool struct {
	size int                  // "el tamaño del pool"
	sem  chan struct{}
}

func NewImportPool(size int) *ImportPool {
	return &ImportPool{size: size, sem: make(chan struct{}, size)}
}

func (p *ImportPool) ProcessBatch(rows []Row) []error {
	var (
		mu     sync.Mutex
		errs   []error
		wg     sync.WaitGroup
	)

	for _, row := range rows {
		wg.Add(1)
		go func(row Row) {            // ← una goroutine POR FILA
			defer wg.Done()

			p.sem <- struct{}{}        // el semáforo limita la EJECUCIÓN...
			defer func() { <-p.sem }()

			if err := importRow(row); err != nil {
				mu.Lock()
				errs = append(errs, err)
				mu.Unlock()
			}
		}(row)
	}

	wg.Wait()
	return errs
}
```

Pasaba la revisión de código. Tiene semáforo, tiene `WaitGroup`, tiene el mutex
para los errores, no tiene carreras. Y con un archivo de dos millones de filas,
el proceso reservaba varios gigas antes de procesar la primera.

**El informe forense.** El semáforo limita **cuántas se ejecutan a la vez**; no
limita **cuántas se crean**. El bucle lanza dos millones de goroutines de
inmediato; 2.000.000 − `size` de ellas se quedan bloqueadas en `p.sem <- struct{}{}`,
cada una viva, cada una con su pila y con la fila capturada en la closure.

| | Con goroutine por fila | Con worker pool |
|---|---|---|
| Goroutines creadas para 2M filas | **2.000.000** | `workers` (8) |
| Goroutines vivas simultáneamente | **2.000.000** | 8 |
| Filas retenidas en memoria a la vez | **2.000.000** (capturadas en closures) | `queueSize` (1.000) + 8 |
| Memoria mínima solo por pilas (2 KB) | **~4 GB** | ~16 KB |
| Cuándo se procesa la primera fila | después de crear 2M goroutines | inmediatamente |
| Se puede aplicar contrapresión | **no** | sí, `ErrQueueFull` |

**La causa de la muerte:** confundir **limitar la ejecución** con **limitar la
creación**. El semáforo es la herramienta correcta cuando el número de tareas es
acotado y conocido; con un flujo de entrada grande, el pool con canal es la
respuesta, porque el canal **frena al productor**.

**El fix, y es de cinco líneas:**

```go
func (p *ImportPool) ProcessBatch(rows []Row) []error {
	jobs := make(chan Row, p.size*2)  // la cola acotada FRENA al productor
	errCh := make(chan error, len(rows))

	var wg sync.WaitGroup
	wg.Add(p.size)
	for i := 0; i < p.size; i++ {
		go func() {                    // p.size goroutines, no len(rows)
			defer wg.Done()
			for row := range jobs {
				if err := importRow(row); err != nil {
					errCh <- err
				}
			}
		}()
	}

	for _, row := range rows {
		jobs <- row  // ← aquí el productor SE BLOQUEA cuando la cola está llena
	}
	close(jobs)
	wg.Wait()
	close(errCh)

	var errs []error
	for err := range errCh {
		errs = append(errs, err)
	}
	return errs
}
```

La línea que lo cambia todo es `jobs <- row`: **el productor se bloquea cuando la
cola está llena**. Eso es contrapresión, y es gratis.

**Corrección mínima frente a refactorización correcta.** El parche del viernes es
el de arriba: cinco líneas, mismo comportamiento, memoria constante. La
refactorización del lunes es que `ProcessBatch` no reciba `[]Row` sino un
`<-chan Row`, para que el archivo se lea en streaming y las dos millones de filas
nunca estén en memoria a la vez. **Eso es la Fase 13**, y es el 🧨 más memorable
del curso.

> ☕ **El patrón a memorizar.** `go` dentro de un `for` sobre datos de entrada es
> una señal de alarma. La pregunta es siempre: **¿cuántas goroutines crea esto en
> el peor caso?** Si la respuesta depende del tamaño de la entrada, está mal.

### Errores comunes

**1. La variable de bucle capturada.**
*Síntoma:* todas las goroutines procesan el último elemento.
*Causa:* 🕰️ en Go 1.13 la variable del `for range` es una sola, compartida.
*Fix mínimo:* pasarla como argumento (`go func(item T){...}(item)`) o copiarla
(`item := item`). **En Go 1.22 esto deja de ser un problema** y es uno de los
cambios más importantes de la Fase 08.

**2. `wg.Add` dentro de la goroutine.**
*Síntoma:* `Wait()` vuelve antes de tiempo, de forma intermitente.
*Causa:* `Wait` puede ejecutarse antes de que la goroutine llegue a su `Add`.
*Fix mínimo:* `wg.Add(1)` **siempre antes** de `go`, en la goroutine que lanza.

**3. `WaitGroup` copiado por valor.**
*Síntoma:* deadlock, o `Wait` que no espera.
*Causa:* pasar `sync.WaitGroup` (no `*sync.WaitGroup`) a una función copia el
contador.
*Fix mínimo:* pasar el puntero. `go vet` lo detecta y por eso está en el
`Makefile` desde la Fase 00.

**4. Cerrar un canal desde el receptor.**
*Síntoma:* `panic: send on closed channel`.
*Causa:* el receptor cerró y un emisor todavía tenía trabajo.
*Fix mínimo:* cierra quien envía. Para señalizar en dirección contraria, un canal
`quit` aparte (o `context`, Fase 07).

**5. `time.After` en un bucle.**
*Síntoma:* la memoria crece lentamente en un servicio de larga duración.
*Causa:* cada llamada crea un `Timer` que vive hasta expirar.
*Fix mínimo:* `timer := time.NewTimer(d)` fuera del bucle, `timer.Reset(d)` dentro,
`defer timer.Stop()`.

**6. `sync.Map` usado como "el mapa concurrente".**
*Síntoma:* rendimiento peor que un `map` con `RWMutex`, y código menos legible.
*Causa:* `sync.Map` está optimizada para dos casos concretos —claves que se
escriben una vez y se leen muchas, y goroutines que acceden a conjuntos de claves
disjuntos—. Fuera de esos, pierde. Además no es tipada (`interface{}` por todas
partes) y no tiene `len`.
*Fix mínimo:* `map` + `RWMutex`, y `sync.Map` solo si mides que gana.

**7. El mutex no reentrante.**
*Síntoma:* deadlock al llamar a un método público desde otro público.
*Causa:* `sync.Mutex` no es reentrante, a diferencia de `synchronized`.
*Fix mínimo:* la convención `xxxLocked` de §6.2.

**8. `t.Fatal` desde una goroutine del test.**
*Síntoma:* el test pasa aunque la goroutine falló, o panic confuso.
*Causa:* `Fatal` hace `runtime.Goexit`, que solo termina esa goroutine.
*Fix mínimo:* `t.Errorf` desde la goroutine, o mandar el fallo por un canal y
comprobarlo en la goroutine del test.

**9. El panic en una goroutine que mata el proceso.**
*Síntoma:* el servicio muere entero por un bug en un job.
*Causa:* `recover` solo funciona en la misma goroutine; el de `net/http` cubre su
handler, no las goroutines que el handler lanza.
*Fix mínimo:* `defer recover()` en el arranque de toda goroutine de larga
duración. Es lo que hace `Engine.execute`.

**10. `fatal error: concurrent map writes`.**
*Síntoma:* el proceso muere sin `recover` posible.
*Causa:* dos goroutines escribiendo un `map` a la vez. El runtime lo detecta a
veces y aborta a propósito.
*Fix mínimo:* mutex. Y ten claro que **este panic no se puede capturar**: es un
`fatal error`, no un `panic`.

**11. El apagado que no drena.**
*Síntoma:* trabajo perdido al reiniciar.
*Causa:* cerrar el canal de `quit` en vez del de trabajo hace que los workers
abandonen lo que tenían pendiente.
*Fix mínimo:* distinguir **drenar** (cerrar el canal de trabajo y esperar) de
**abortar** (señalizar `quit`). Los dos son válidos y resuelven cosas distintas;
la Fase 07 lo formaliza.

**12. Medir concurrencia con una sola corrida.**
*Síntoma:* conclusiones que no se reproducen.
*Causa:* la planificación es no determinista.
*Fix mínimo:* `-count=10` mínimo y `-cpu=1,2,4,8`. Y `benchstat` en la Fase 15.

### 🧨 Rompe a propósito

Ya rompiste tres cosas. La cuarta es la más instructiva: **haz que el `-race` no
encuentre una carrera que existe.**

```go
func TestRaceThatRaceMisses(t *testing.T) {
	c := &Unsafe{}

	// Dos goroutines, pero con un sleep que las serializa de hecho.
	go func() { c.Inc() }()
	time.Sleep(50 * time.Millisecond)
	go func() { c.Inc() }()
	time.Sleep(50 * time.Millisecond)

	if c.Get() != 2 {
		t.Error("se perdió un incremento")
	}
}
```

Corre con `-race`. **No detecta nada**, y sin embargo el código es exactamente el
mismo que el del §6.1 que sí tenía carrera.

**La lección:** `-race` es un detector **dinámico**. Solo ve los accesos que
ocurren, y si tu test serializa las goroutines sin querer —con un `sleep`, con una
llamada lenta, o simplemente porque la máquina va sobrada— la carrera existe y no
se manifiesta.

Corolario práctico: **un test de concurrencia tiene que crear contención real.**
Cien goroutines haciendo mil operaciones cada una, no dos con un `sleep` en medio.
Y `-count=20` porque una corrida no prueba nada.

---

## 🧪 8. Ejercicios (30)

**🟢 Fácil (1–6)**

1. Lanza 100.000 goroutines que duerman 10 ms y mide la memoria residente.
   *Criterio:* anotas el dato en B-07 y calculas los bytes por goroutine.
2. Escribe las cuatro versiones del contador y comprueba con `-race` cuál falla.
   *Criterio:* pegas el informe de carrera completo e identificas sus tres partes.
3. Provoca los dos deadlocks que el runtime **sí** detecta. *Criterio:* pegas los
   dos mensajes y explicas qué significa `[chan send]` y `[semacquire]`.
4. Usa `GOMAXPROCS=1` sobre tu suite completa. *Criterio:* pasa igual, y explicas
   qué habría significado que no pasara.
5. Manda `SIGQUIT` a un proceso colgado y lee las pilas. *Criterio:* identificas
   las dos goroutines en espera circular.
6. Corre `GODEBUG=schedtrace=1000` sobre OpsReport bajo carga. *Criterio:*
   explicas qué son `runqueue` y los números por procesador lógico.

**🟡 Intermedio (7–17)**

7. Arregla `memstore` con `RWMutex` y demuestra con `-race` y 200 peticiones
   concurrentes que la carrera desapareció. *Criterio:* pegas el antes y el
   después.
8. Mide B-08: las cuatro implementaciones del contador con `b.RunParallel` y
   `-cpu=1,4,8`. *Criterio:* tu veredicto explica **por qué** el canal pierde, no
   solo que pierde.
9. Implementa el worker pool de OpsReport con cola acotada. *Criterio:* con la
   cola llena, `Submit` devuelve `ErrQueueFull` de inmediato y el handler HTTP
   responde 503 con `Retry-After`.
10. Añade `Shutdown` que drene la cola. *Criterio:* un test encola 100 jobs, llama
    a `Shutdown`, y verifica que los 100 se ejecutaron.
11. Ahora añade un modo de apagado que **aborte** en vez de drenar. *Criterio:*
    explicas en qué caso querrías cada uno, con un ejemplo de Meridian.
12. Implementa el semáforo por endpoint de EventRelay. *Criterio:* un test con un
    endpoint lento y otro rápido demuestra que el lento no bloquea al rápido.
13. Escribe el fan-out/fan-in completo con sus tres goroutines de coordinación.
    *Criterio:* explicas por qué hace falta la goroutine que cierra `out`, y qué
    pasa si la quitas.
14. Implementa el pipeline de tres etapas sobre `movement-parser` de la Fase 01.
    *Criterio:* cada etapa cierra su salida; provocas el `send on closed channel`
    cerrando la entrada por error y lo explicas.
15. Reproduce la fuga de `leak-lab` y arréglala de las dos formas: con búfer y
    con un canal `done`. *Criterio:* el test de `NumGoroutine` pasa con las dos.
16. Añade `recover` a los workers de los dos motores y provoca un panic en un
    job. *Criterio:* el proceso sobrevive, la pila queda en el log, y el job se
    marca como `failed` con motivo.
17. **Línea de comandos.** Mide B-10: el coste de `-race` sobre la suite de la
    Fase 04 y sobre la de hoy. *Criterio:* dos ratios distintos, y explicas por
    qué difieren.

**🟠 Difícil (18–25)**

18. **Diagnóstico (1).** Un `WaitGroup` con `Add` dentro de la goroutine.
    *Criterio:* reproduces el fallo intermitente con `-count=100`, lo explicas y
    lo arreglas.
19. **Diagnóstico (2).** Un `WaitGroup` copiado por valor. *Criterio:* `go vet` lo
    detecta; pegas el mensaje y explicas por qué el compilador no.
20. **Diagnóstico (3).** Una fuga por `time.After` en un bucle. *Criterio:* mides
    el crecimiento de memoria con `runtime.ReadMemStats` y lo arreglas con
    `Timer.Reset`.
21. **Diagnóstico (4).** El mutex no reentrante. *Criterio:* reproduces el
    deadlock, lo diagnosticas con `SIGQUIT`, y lo arreglas con la convención
    `xxxLocked`.
22. **Diagnóstico (5).** Dos mutex en orden inverso, con una goroutine viva para
    que el runtime **no** lo detecte. *Criterio:* muestras que no hay mensaje, lo
    encuentras con `SIGQUIT`, y lo arreglas con orden total.
23. **Diagnóstico (6).** Un test de concurrencia que pasa siempre y no prueba
    nada. *Criterio:* demuestras que `-race` no lo detecta, lo reescribes para que
    cree contención real, y entonces sí falla.
24. **Diagnóstico (7).** El `for` con `go` dentro de la autopsia. *Criterio:*
    mides goroutines vivas y memoria con un millón de filas en las dos versiones, y
    demuestras que el semáforo no limita la creación.
25. Mide B-09: worker pool acotado frente a goroutine por tarea bajo un pico de
    50.000. *Criterio:* reportas memoria máxima, completados, **rechazados** y p99;
    y tu veredicto defiende explícitamente que rechazar es correcto.

**🔴 Muy difícil (26–30)**

26. **Diagnóstico (8) — el caso difícil.** Te dan un servicio que funciona bien
    durante horas y después se degrada hasta dejar de responder, sin errores en el
    log. La causa es una fuga de goroutines en un camino de error poco frecuente.
    *Rúbrica:* (a) instrumentas el servicio para exponer `runtime.NumGoroutine()`
    y demuestras el crecimiento; (b) localizas el camino exacto; (c) escribes el
    test que lo habría detectado desde el principio; (d) explicas por qué `-race`
    no servía aquí y qué herramienta sí (adelanto: el perfil `goroutine`, Fase 07).
27. **El motor de jobs con prioridades.** Extiende el motor de OpsReport para que
    respete la prioridad efectiva: los trabajos urgentes adelantan a los normales.
    *Rúbrica:* (a) sin usar `container/heap` compartido entre goroutines sin
    protección, y justificas tu estructura de datos; (b) **sin inanición**: un
    trabajo de prioridad 1 acaba ejecutándose, y lo demuestras con un test; (c)
    pasa `-race -count=20`; (d) mides si la complejidad añadida se nota en el
    rendimiento y das un veredicto — incluida la opción "no compensa".
28. **Contrapresión de punta a punta.** Conecta el `Submit` del motor con el
    handler HTTP de forma que, bajo saturación, el servicio responda 503 con
    `Retry-After` calculado a partir del estado real de la cola. *Rúbrica:* (a) el
    `Retry-After` se deriva de la longitud de la cola y del ritmo de proceso
    observado, no es una constante; (b) una prueba de carga demuestra que la
    latencia p99 de las peticiones **aceptadas** se mantiene estable mientras el
    resto se rechaza; (c) las métricas de rechazo son consultables; (d) comparas
    con la política de rechazo de `ThreadPoolExecutor` (`AbortPolicy`,
    `CallerRunsPolicy`, `DiscardPolicy`) y dices cuál estás implementando.
29. **El experimento de las hebras virtuales.** Implementa el mismo benchmark de
    B-07 en Java, con hilos de plataforma **y** con hebras virtuales de Java 21.
    *Rúbrica:* (a) las tres mediciones con las mismas condiciones —mismo trabajo
    por tarea, misma máquina, con calentamiento declarado en el lado JVM—; (b)
    reportas creación, memoria por unidad y el punto donde cada una deja de
    escalar; (c) el veredicto es honesto y dice explícitamente dónde Java 21
    empata o gana; (d) identificas qué sigue siendo distinto más allá del coste, y
    si eso importa para el caso de Meridian.
30. **El motor probado bajo estrés.** Escribe una prueba de estrés del motor de
    OpsReport que mantenga invariantes durante un minuto: trabajos enviados =
    completados + fallidos + rechazados + en cola; ninguna goroutine fugada;
    ningún trabajo en estado inconsistente. *Rúbrica:* (a) corre con
    `-race -cpu=1,2,4,8`; (b) inyecta fallos aleatorios —runners que entran en
    panic, que tardan mucho, que fallan— con una semilla reproducible; (c) el
    apagado a mitad del estrés no pierde ni duplica trabajo, y lo verificas; (d)
    la prueba falla de verdad si introduces cualquiera de los bugs de §7 — y lo
    demuestras introduciendo dos.

**🔥 Opcionales**

- Lee `runtime/chan.go` en tu `GOROOT`. La implementación de un canal son unas
  setecientas líneas y es sorprendentemente legible: vas a ver la cola circular, la
  lista de emisores y receptores en espera, y por qué enviar a un canal cerrado
  entra en panic.
- Implementa un `errgroup` mínimo —lanzar N tareas, esperar a todas, quedarse con
  el primer error— sin mirar el código de `golang.org/x/sync`. Después compáralo
  con el real. En la Fase 08 lo vas a usar y agradecerás haberlo escrito.
- Lee el modelo de memoria de Go (https://go.dev/ref/mem) entero. Son diez páginas
  y responde con precisión qué garantías te da cada primitiva.

---

### 🔴 Desafíos de cierre

> Tres ejercicios de dificultad alta que **no cuentan en el total de la sección** y
> no son parte del recorrido base.

**D1 — El pipeline con contrapresión medida.**
Construye un pipeline de cuatro etapas con velocidades distintas —la tercera es diez
veces más lenta que las demás— e instruméntalo para **ver dónde se acumula el
trabajo**.
*Rúbrica:* (a) cada etapa reporta la ocupación de su canal de salida
(`len(ch)/cap(ch)`) de forma periódica; (b) demuestras que la contrapresión se
propaga hacia atrás hasta frenar al productor, y en cuánto tiempo; (c) identificas
la etapa lenta **solo con las métricas de ocupación**, sin saberlo de antemano; (d)
ajustas el paralelismo de esa etapa y demuestras que el cuello de botella se
desplaza, que es lo que siempre pasa; (e) explicas por qué un canal con búfer
grande **esconde** el problema en vez de resolverlo.

**D2 — El detector de fugas con lista de ignorados.**
Mejora el `CheckNoLeaks` de la Fase 07 para que inspeccione las **pilas** en vez de
contar goroutines.
*Rúbrica:* (a) usa `runtime.Stack(buf, true)` y parsea las pilas; (b) ignora las
goroutines legítimas del runtime y de la stdlib —el recolector, los temporizadores,
el servidor de `pprof`— con una lista justificada; (c) reporta la fuga **con la pila
completa y el tiempo bloqueado**, que es lo que la hace diagnosticable; (d) lo
comparas con `goleak` de Uber leyendo su código y dices qué hace él que tú no; (e)
lo aplicas a la suite del curso y encuentras al menos una goroutine que no sabías
que estaba viva.

**D3 — El bug de visibilidad que `-race` no siempre ve.**
Escribe un programa donde una goroutine publica un valor sin sincronización y otra
lo lee, y **consigue que el lector vea el valor viejo**.
*Rúbrica:* (a) reproduces la no-visibilidad de forma observable —normalmente hace
falta un bucle apretado y `GOMAXPROCS` alto—; (b) explicas con el modelo de memoria
de Go **por qué está permitido** que el compilador o la CPU reordenen ahí; (c)
compruebas si `-race` lo detecta y en qué condiciones sí y en cuáles no; (d) lo
arreglas de las tres formas —mutex, `atomic`, canal— y explicas qué garantía de
"sucede antes" establece cada una; (e) relacionas el caso con `volatile` de Java y
di si el razonamiento se traslada.

---

## 📚 9. Referencias

### Documentación oficial

- **The Go Memory Model** — https://go.dev/ref/mem — **la** referencia. Define qué
  operaciones establecen "sucede antes". Es corto, es denso, y responde con
  precisión preguntas que los blogs contestan a ojo.
- **`sync`** — https://pkg.go.dev/sync · **`sync/atomic`** — https://pkg.go.dev/sync/atomic
- **`runtime`** — https://pkg.go.dev/runtime — `NumGoroutine`, `GOMAXPROCS`,
  `ReadMemStats`.
- **Data Race Detector** — https://go.dev/doc/articles/race_detector — cómo
  funciona, qué detecta, qué no, y su coste. Léelo antes de medir B-10.
- **Effective Go: Concurrency** — https://go.dev/doc/effective_go#concurrency
- **`GODEBUG`** — https://pkg.go.dev/runtime#hdr-Environment_Variables — la
  documentación de `schedtrace`, `gctrace` y compañía.
- **Go Wiki: LoopvarExperiment** — https://go.dev/wiki/LoopvarExperiment — el
  cambio de la variable de bucle de Go 1.22, para saber a qué vamos en la Fase 08.

### Libros

- **Concurrency in Go** — Katherine Cox-Buday. **Es el libro de esta fase y de la
  siguiente.** Cubre el modelo, los patrones, el pipeline, la contrapresión y el
  planificador, con el mejor tratamiento escrito de por qué `select` elige al azar.
- **The Go Programming Language** — Donovan y Kernighan, capítulos 8 (*Goroutines
  and Channels*) y 9 (*Concurrency with Shared Variables*). El capítulo 9 es la
  mejor explicación del modelo de memoria para quien viene de Java.
- **100 Go Mistakes** — Harsanyi, capítulos 8 y 9 (errores #55 a #73). Es
  literalmente la lista de §7 con más detalle.
- **Learning Go** — Bodner, capítulo *Concurrency in Go*. Más breve y más moderno;
  bueno para consolidar.

### Artículos y charlas

- **Go Concurrency Patterns** — Rob Pike, https://go.dev/talks/2012/concurrency.slide
  — el original. Los patrones de §6.7 salen de aquí.
- **Advanced Go Concurrency Patterns** — Rob Pike,
  https://go.dev/talks/2013/advconc.slide — la continuación, con el manejo de
  estado y la cancelación.
- **Go Concurrency Patterns: Pipelines and cancellation** —
  https://go.dev/blog/pipelines — **la lectura obligatoria de §6.7.** Explica la
  regla de quién cierra qué y prepara la Fase 07.
- **Share Memory By Communicating** — https://go.dev/blog/codelab-share — el
  proverbio, con su matiz.
- **Go Wiki: MutexOrChannel** — https://go.dev/wiki/MutexOrChannel — la respuesta
  oficial a "¿canal o mutex?", y es más matizada que el proverbio suelto.
- **The Scheduler Saga** — Kavya Joshi, y **Analysis of the Go runtime scheduler**
  — para entender el modelo M:N por dentro.
- **Go scheduler: Ms, Ps & Gs** — Vincent Blanchon, serie en Medium con diagramas.
- **JEP 444: Virtual Threads** — https://openjdk.org/jeps/444 — para el §6.8, y
  para no hablar de Loom de oídas.

### Video

- **Concurrency is not Parallelism** — Rob Pike. **Treinta minutos, y es la charla
  que hay que ver antes de escribir concurrencia en Go.** No enseña API: enseña a
  pensar el problema.
- **Go Concurrency Patterns** — Rob Pike, Google I/O 2012. La versión hablada del
  artículo.
- **Understanding Channels** — Kavya Joshi, GopherCon 2017. Cómo funciona un canal
  por dentro, con el código del runtime delante.
- **Rethinking Classical Concurrency Patterns** — Bryan C. Mills, GopherCon 2018.
  **Muy recomendada**: critica patrones que la propia comunidad daba por buenos,
  incluido el uso excesivo de `sync.Pool` y de goroutines sin dueño.

> ⚠️ Todo el material anterior a 2023 lleva el `item := item` de la variable de
> bucle. Sigue siendo correcto, solo que desde Go 1.22 es innecesario. Y el
> material anterior a 2021 no menciona las hebras virtuales de Java, así que sus
> comparaciones con la JVM están fechadas.

### Orden de lectura sugerido

**Antes de escribir código:** ver *Concurrency is not Parallelism* de Pike. Media
hora, y cambia cómo planteas el problema.
**Durante:** *Go Concurrency Patterns: Pipelines and cancellation* cuando llegues a
§6.7, y la página del *Data Race Detector* antes de medir B-10.
**Después:** *Concurrency in Go* de Cox-Buday, con calma — al menos los capítulos
de patrones y de la escalera de errores—, y el modelo de memoria oficial de una
sentada. Los dos se amortizan en la Fase 07.

---

## ⚖️ 10. Veredicto y cierre

### ⚖️ Cuándo NO usar esto

La concurrencia de Go es su mejor carta, y hay que decir dónde no lo es:

- **Hay problemas donde un `CompletableFuture` encadenado se lee mejor que tres
  canales.** Una secuencia de cinco llamadas asíncronas con transformaciones entre
  medias y un manejo de error común es, en Java,
  `supplyAsync().thenApply().thenCompose().exceptionally()` — una expresión que se
  lee de arriba abajo. En Go son cinco goroutines, tres canales, un `WaitGroup` y
  la propagación de errores a mano. **Go no tiene composición de operaciones
  asíncronas**, y ese es un hueco real; la respuesta idiomática (llamadas
  bloqueantes secuenciales en una goroutine) funciona bien, pero es otra forma de
  pensar, no una traducción.
- **Cuando el paralelismo es de datos y no de tareas.** `parallelStream()` sobre
  un millón de elementos con `ForkJoinPool` y *work stealing* es una línea; en Go
  se escribe el fan-out a mano cada vez. Hay librerías, y no es lo mismo.
- **Cuando necesitas planificación con prioridades.** El planificador de Go no
  tiene prioridades y no las va a tener. Si tu sistema necesita que ciertas tareas
  desalojen a otras, eso se construye encima (ejercicio 27) y es artesanal. La JVM
  tampoco brilla aquí, pero al menos los hilos tienen prioridad nominal.
- **Cuando la observabilidad de la concurrencia es crítica.** JFR te dice qué hizo
  cada hilo, cuánto esperó en qué monitor y con qué latencia, con un detalle que
  `pprof` no alcanza. Para depurar un problema de contención en producción, la JVM
  está por delante.
- **Y con Java 21, el argumento de coste se desinfló.** Si tu justificación para
  migrar era "las goroutines son más baratas que los hilos", las hebras virtuales
  se comieron buena parte de eso. Lo que queda es el modelo de programación, y eso
  es preferencia informada, no una tabla de números. Lo medimos en la Fase 16.

Dicho todo eso: para el problema de EventRelay —miles de entregas concurrentes
bloqueadas en E/S de red, con límites por destino y apagado ordenado— el modelo de
Go es directo, el código cabe en una pantalla y el detector de carreras viene en la
caja. Ese caso existe mucho, y es donde Go se gana el sueldo.

### 📖 Diccionario Java ⇄ Go de esta fase

| Java | Go | Dónde se rompe la equivalencia |
|---|---|---|
| `Thread` (plataforma) | goroutine | Pila de 2 KB que crece frente a ~1 MB fija; planificada en espacio de usuario. Tres órdenes de magnitud de diferencia en coste |
| Hebra virtual (Java 21) | goroutine | **El paralelo más cercano que existe.** Mismo modelo M:N. Diferencias: canales y `select` son primitivas en Go; el *pinning* en `synchronized` es un problema de la JVM |
| `Runnable` / `Callable` | una función y `go` | No hay tipo que implementar. `Callable` devuelve valor; `go` no devuelve nada — el resultado viaja por un canal |
| `ExecutorService` | **un patrón, no un tipo**: canal + N goroutines | Hay que construirlo. A cambio, el límite, la cola y el apagado están visibles en diez líneas |
| `newFixedThreadPool(n)` | `make(chan Job, size)` + n goroutines | El tamaño de la cola y el del pool son **dos números distintos** y aquí se ven |
| `newCachedThreadPool()` | *(no tiene equivalente y es bueno)* | Un pool sin límite es el antipatrón de la autopsia |
| `Future<T>` / `get()` | un canal de resultados | Sin `isDone`, sin `cancel`. La cancelación es `context` (Fase 07) |
| `CompletableFuture` encadenado | *(no existe)* | No hay composición asíncrona. Se escribe secuencial dentro de una goroutine, que es más simple de leer y menos expresivo |
| `BlockingQueue` | canal con búfer | Casi idéntico. El canal además se **cierra**, y el cierre es una señal que `range` entiende |
| `queue.offer(x)` (no bloqueante) | `select` con `default` | La contrapresión, explícita |
| `queue.poll(timeout)` | `select` con `time.After`/`Timer` | ⚠️ `time.After` en un bucle acumula timers |
| `synchronized` | `sync.Mutex` | **NO es reentrante.** Un método con lock que llama a otro con lock se cuelga |
| `ReentrantLock` | `sync.Mutex` | Tampoco es reentrante. Ni `tryLock`, ni `lockInterruptibly`, ni condiciones con `await`/`signal` |
| `ReadWriteLock` | `sync.RWMutex` | Mismo concepto. Sin actualización de lectura a escritura |
| `volatile` | `sync/atomic` | No hay modificador de campo. La atomicidad es por operación, no por variable: `x++` sigue siendo carrera aunque leas con `atomic.Load` |
| `AtomicInteger` | `atomic.AddInt64(&x, 1)` | Funciones sobre una variable, no un tipo envoltorio. 🕰️ Go 1.19 añadió `atomic.Int64` como tipo, y eso lo mejora |
| `CountDownLatch` | `sync.WaitGroup` | Contador dinámico (`Add` en cualquier momento) en vez de fijo. `Add` **antes** de lanzar |
| `CyclicBarrier` | *(no hay)* | Se construye con canales |
| `Semaphore` | canal con búfer | `sem <- struct{}{}` adquiere, `<-sem` libera. Es lo que hace `semaphore.Weighted` 🕰️ |
| `ThreadPoolExecutor` + `RejectedExecutionHandler` | `select` con `default` devolviendo error | Tú escribes la política de rechazo, y por eso sabes cuál es |
| `ForkJoinPool` / `parallelStream` | fan-out/fan-in escrito a mano | Sin *work stealing* expuesto al usuario (el planificador lo hace internamente). Sin API de paralelismo de datos |
| `ThreadLocal` | *(no existe, y es deliberado)* | El estado por petición viaja en `context.Context`, explícito y por parámetro (Fase 07) |
| `Thread.sleep` | `time.Sleep` | Idéntico, y en los dos sitios es una señal de alarma en código de producción |
| `Thread.interrupt` | cerrar un canal `quit` / `context` | La cancelación es **cooperativa** y explícita: hay que mirarla en un `select` |
| `jstack` | `SIGQUIT` (o `Ctrl+\`) | Salida más escueta y con el estado de cada goroutine (`chan send`, `semacquire`, `select`) |
| ThreadSanitizer / FindBugs | `go test -race` | **En el toolchain, no aparte.** Dinámico: solo ve lo que ocurre |
| Java Memory Model | Go Memory Model | Mismo concepto de *happens-before*. El de Go es mucho más corto de leer |
| `ConcurrentHashMap` | `map` + `RWMutex` (o `sync.Map`) | `sync.Map` **no** es el equivalente general: está optimizada para dos patrones concretos y fuera de ellos pierde. Y no es tipada |
| `-Xss` (tamaño de pila) | *(no aplica)* | Las pilas de las goroutines crecen y encogen solas |
| Pool de hilos con `shutdown()` + `awaitTermination()` | `close(jobs)` + `wg.Wait()` | Cerrar el canal de trabajo drena; señalizar `quit` aborta. Dos operaciones distintas, y hay que elegir |

### Qué sigue

La Fase 07 cierra el Bloque A con lo que hoy has echado de menos: **`context`**.
El canal `quit` que cerramos a mano es exactamente lo que `context.Context`
empaqueta, y además con plazos, con propagación automática desde el handler HTTP
hasta el fondo, y con la distinción entre `Canceled` y `DeadlineExceeded`.

Y con él, el ciclo de vida completo del proceso: señales del sistema operativo,
`Shutdown` del servidor HTTP, drenaje del pool con **tiempo límite** —la deuda de
hoy—, y los tests que verifican que tras un `SIGTERM` no queda ninguna goroutine
viva.

Se explica también lo que `context` **no** es: ni un `ThreadLocal`, ni una bolsa de
parámetros, ni el sitio donde meter el usuario autenticado por comodidad.

### La señal de que quedó bien

> *"Veo `go` en una revisión de código y mi primera pregunta ya no es qué hace.
> Es: ¿quién la espera, cuál es su tope, y qué pasa con ella cuando apaguemos?"*

Si todavía lanzas goroutines dentro de un bucle sobre datos de entrada, vuelve a
la autopsia y cuenta cuántas crea tu código en el peor caso. Esa cuenta es el
reflejo que esta fase viene a instalar.

> 🏷️ **No cierres la fase sin el tag.** Con el checklist de la sección 2 en
> verde, `go1.13 test -race -cpu=1,2,4,8 ./...` en verde, `golangci-lint run`
> limpio y `git status` sin cambios pendientes:
>
> ```bash
> git tag -a fase-06 -m "F6 cerrada: motor de jobs de OpsReport con cola acotada y N workers; cola de entregas de EventRelay con límite global y por endpoint; memstore seguro para uso concurrente; race-counter, deadlock-lab, leak-lab y unbounded-queue; B-07, B-08, B-09 y B-10 medidos"
> git tag -a opsreport/v0.6 -m "OpsReport: motor de jobs con concurrencia acotada"
> git tag -a eventrelay/v0.5 -m "EventRelay: despachador concurrente con límite por endpoint"
> ```
>
> Los commits de la fase llevan su prefijo (`fase 06: …`) y los de ejercicio su
> número (`fase 06 ej30: …`). Todo eso está en
> [`00-convencion-de-git-y-tags.md`](00-convencion-de-git-y-tags.md).

---

# 📌 Bloque de autoría (fuera de lo que lee el estudiante)

## 📌 Pendientes sugeridos

- **`container/heap`** — abierto en la Fase 01 (ejercicio 24) y cerrado **aquí,
  como ejercicio 🔴 27**, con la complicación concurrente que es lo que lo hace
  interesante. **Decisión tomada: no tiene sección propia en ninguna fase.** La
  Fase 13 lo consideró para la cola de lotes y no lo necesita; darle una sección
  sería enseñar una estructura de datos, que no es de lo que va el curso. Cadena
  cerrada en las tres fases.
- **El `errgroup` escrito a mano** (🔥) — es una preparación excelente para la Fase
  08. **Verificar que la Fase 08 lo recoge** y pide comparar con el real.
- **Interrupción asíncrona del planificador (Go 1.14)** — mencionada como 📝 nota
  de época. Debe aparecer en la lista de saltos de la **Fase 08**, salto 1.14–1.16.
- **`atomic.Int64` como tipo (Go 1.19)** — en el diccionario como 🕰️. Verificar que
  el salto 1.19–1.21 de la Fase 08 lo menciona.
- **El apagado con tiempo límite** — deuda 💸 de hoy, prometida a la **Fase 07**.
  Está en su alcance; verificado.
- **La cola en memoria y el planificador de reintentos con `time.Timer`** — deudas
  💸 prometidas a la **Fase 09**. Están en su alcance; verificado.
- **Prueba de estrés con invariantes** (ejercicio 30) — es una técnica que la Fase
  13 (lotes) y la Fase 15 (carga) podrían reutilizar. **Anotar en la Fase 13** que
  las cinco propiedades del lote se pueden verificar con esta misma forma de test.

## ☕ Reflejos para `INSTINTOS.md`

- **"Un pool es un `for` con `go` dentro"** — el reflejo raíz de la fase. Coste
  medido: 2.000.000 de goroutines y ~4 GB solo en pilas frente a 8 goroutines y
  16 KB. Antídoto: el canal acotado frena al productor; el semáforo no.
- **"El semáforo limita las goroutines"** — limita la ejecución, no la creación.
  Es la distinción exacta de la autopsia.
- **"Los canales son la respuesta a todo"** — para proteger un contador, un canal
  es uno o dos órdenes de magnitud más lento que un mutex (B-08). Canales para
  transferir propiedad; mutex para proteger estado.
- **"`sync.Map` es el `ConcurrentHashMap` de Go"** — no lo es. Está optimizada para
  dos patrones concretos; fuera de ellos, `map` + `RWMutex` gana y además es
  tipado.
- **"`synchronized` es reentrante, esto también"** — `sync.Mutex` no lo es, y el
  deadlock es inmediato. Antídoto: la convención `xxxLocked`.
- **"`recover` en el borde HTTP me cubre"** — solo cubre la goroutine del handler.
  Un panic en una goroutine lanzada por el handler mata el proceso.
- **"Un test de concurrencia que pasa demuestra que no hay carrera"** — `-race` es
  dinámico; sin contención real no ve nada.

## 📐 Mediciones para `BENCHMARKS.md`

- **B-07 — Goroutine frente a hilo de la JVM.** ⚠️ **Esta entrada tiene que
  medirse contra las tres variantes de Java: hilos de plataforma, hilos de
  plataforma con `-Xss` reducido, y hebras virtuales de Java 21.** Medir solo
  contra hilos de plataforma es exactamente el tipo de comparación tramposa que
  `prompts/formato-de-benchmarks.md` §3 prohíbe. El ejercicio 29 produce los datos.
- **B-08 — Canal con búfer frente a mutex para un contador.** Cuatro variantes
  (`Unsafe` excluida del resultado, incluida como referencia de lo que se pierde),
  con `b.RunParallel` y `-cpu=1,4,8`. El veredicto debe decir explícitamente que el
  resultado **no** significa "los canales son lentos".
- **B-09 — Worker pool acotado frente a goroutine por tarea, bajo pico.** Reportar
  **rechazados** como columna de primera clase, no como nota al pie.
- **B-10 — Coste de `-race` en tiempo y memoria.** Dos sujetos: la suite de la Fase
  04 (poca memoria compartida) y la de la Fase 06 (mucha). **La diferencia entre
  los dos ratios es el resultado interesante**, más que el ratio absoluto.
