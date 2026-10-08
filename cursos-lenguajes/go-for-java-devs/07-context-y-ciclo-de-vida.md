# ⏱️ Fase 07 — Context, cancelación y ciclo de vida

> Go para desarrolladores Java senior · Fase 7 de 17 · **7 horas**
> Época: **Go 1.13 (stdlib pura)**
> Depende de: Fase 06 · Habilita: Fase 08
> Proyectos que avanzan: **OpsReport** y **EventRelay** (cancelación de punta a punta, apagado ordenado)
> Mini proyectos: `cancellable-worker`, `timeout-client`, `graceful-server`, `leak-detector`

---

## 🎯 1. Propósito

En la Fase 06 cerraste un canal `quit` para avisar a los workers de que había que
parar, y funcionó. Lo que hiciste a mano es exactamente lo que `context.Context`
empaqueta —y además le añade plazos, propagación automática por toda la pila de
llamadas, y la distinción entre "me cancelaron" y "se me acabó el tiempo".

Esta fase cierra el Bloque A con los dos servicios capaces de **apagarse sin
perder trabajo ni dejar goroutines vivas**. Y con una regla que a partir de aquí
gobierna cada firma que escribas: **`ctx context.Context` es el primer parámetro
de toda función que hace E/S, y ninguna estructura lo guarda dentro.**

También va de decir lo que `context` **no** es, porque el reflejo de Java lleva
directo al abuso: no es un `ThreadLocal`, no es una bolsa de parámetros, y no es
el sitio donde meter el usuario autenticado por comodidad.

---

## ✅ 2. Qué queda listo al terminar

- [ ] Toda función de los dos servicios que hace E/S recibe `ctx` como primer
      parámetro, y `golangci-lint` con `noctx` está en verde.
- [ ] `DELETE /work-items/{id}` cancela de verdad el trabajo en curso, y el worker
      se entera en milisegundos.
- [ ] `SIGTERM` drena la cola de OpsReport con tiempo límite: lo que quepa se
      termina, el resto vuelve a `queued`.
- [ ] EventRelay tiene tiempo límite por entrega y las entregas en vuelo que no
      alcanzan a terminar vuelven a `pending`.
- [ ] El servidor HTTP se apaga con `Shutdown`, sin cortar peticiones en curso.
- [ ] Hay un test que verifica que **tras el apagado no queda ninguna goroutine
      viva**, y lo detecta si la introduces.
- [ ] Sabes leer el perfil `goroutine` de `pprof` para encontrar una fuga.
- [ ] `go1.13 test -race ./...` en verde en los dos módulos.

---

## 🚫 3. Qué NO entra todavía

- `context.WithoutCancel` y `context.AfterFunc` → Fase 08 🕰️ (Go 1.21). El primero
  resuelve un problema real que vamos a encontrar hoy —una tarea de limpieza que
  **no** debe cancelarse con la petición— y hoy se soluciona a mano.
- `goleak` como librería → Fase 08. Hoy la detección es a mano con
  `runtime.NumGoroutine` y con el perfil `goroutine`, que se entiende mejor.
- Cliente HTTP con `ctx` → Fase 10. Hoy `timeout-client` usa el cliente mínimo
  para ilustrar la propagación, no para escribir el cliente definitivo.
- `context` a través de la base de datos → Fase 09, donde `QueryContext` y
  `ExecContext` cierran la propagación hasta el driver.
- Trazas distribuidas sobre el contexto → Fase 14.
- Reintentos y retroceso con plazos → Fase 10.

---

## 🧠 4. Concepto mínimo

### Qué es un `context`, literalmente

```go
type Context interface {
	Deadline() (deadline time.Time, ok bool)
	Done() <-chan struct{}
	Err() error
	Value(key interface{}) interface{}
}
```

Cuatro métodos. Y el que importa es `Done()`: **devuelve un canal que se cierra
cuando hay que parar**. Eso es todo el mecanismo. Es exactamente el canal `quit`
de la Fase 06, con tres añadidos:

1. **Se propaga.** Un contexto hijo se cancela cuando se cancela el padre, en
   cascada, sin que nadie escriba código para ello.
2. **Tiene plazo.** `WithTimeout` cierra el canal cuando expira el tiempo.
3. **Dice por qué.** `Err()` devuelve `context.Canceled` o
   `context.DeadlineExceeded`.

```go
func (w *Worker) run(ctx context.Context) {
	for {
		select {
		case job := <-w.jobs:
			w.process(ctx, job)

		case <-ctx.Done():
			// ctx.Err() dice si fue cancelación explícita o vencimiento del plazo.
			log.Printf("worker parando: %v", ctx.Err())
			return
		}
	}
}
```

> 🧠 **Modelo mental.** Un `context` es **un árbol de cancelación**. La raíz es
> `context.Background()`; cada `WithCancel`/`WithTimeout` cuelga un hijo. Cancelar
> un nodo cancela todo su subárbol, hacia abajo y nunca hacia arriba. En un
> servicio HTTP, la raíz de cada petición es `r.Context()`, y `net/http` lo cancela
> solo cuando el cliente se desconecta.

### Las cuatro constructoras

```go
ctx := context.Background()   // la raíz. En main, en tests, en TestMain.
ctx := context.TODO()         // "aquí irá un contexto cuando sepa cuál". Marcador.

ctx, cancel := context.WithCancel(parent)
defer cancel()                // ⚠️ SIEMPRE. Ver abajo.

ctx, cancel := context.WithTimeout(parent, 5*time.Second)
defer cancel()

ctx, cancel := context.WithDeadline(parent, someInstant)
defer cancel()

ctx := context.WithValue(parent, requestIDKey{}, "req-8821")
```

> ⚠️ **`defer cancel()` no es opcional, y la razón sorprende.** `WithCancel` y
> `WithTimeout` registran el hijo en el padre. Si nunca llamas a `cancel`, **ese
> registro no se suelta** y el hijo vive mientras viva el padre. Con un padre de
> larga duración —el contexto del proceso— eso es una fuga de memoria que crece
> con cada petición. `go vet` lo detecta y protesta con *"the cancel function is
> not used on all paths (possible context leak)"*.
>
> Y llamar a `cancel()` después de que el trabajo terminó **no hace daño**: es
> idempotente. Por eso la forma correcta es siempre `defer cancel()`, sin pensar.

### La regla de la firma

```go
// ✅ Primero, siempre, y se llama ctx.
func (s *Service) Create(ctx context.Context, item workitem.WorkItem) (workitem.WorkItem, error)

// ❌ Nunca guardado en un struct.
type Service struct {
	ctx context.Context   // ← mal
}

// ❌ Nunca nil.
s.Create(nil, item)       // usa context.TODO() si de verdad no tienes uno
```

> 🧭 **Regla del proyecto.** `ctx context.Context` es el **primer** parámetro de
> toda función que haga E/S, espere, o pueda tardar. Se llama `ctx`. **Nunca se
> guarda en un struct**, porque un contexto pertenece a una llamada, no a un
> objeto: un `Service` vive durante todo el proceso y una petición dura
> milisegundos. Guardarlo confunde los dos ciclos de vida y produce cancelaciones
> que no ocurren o que ocurren de más.

### 🪞 Tu instinto de Java dice… y esta vez se equivoca

**El instinto:** *"esto es un `ThreadLocal`: meto ahí el usuario, el tenant y el
identificador de traza, y lo leo donde haga falta sin ensuciar las firmas"*. En
Java es una práctica establecida: `SecurityContextHolder` de Spring Security, el
`MDC` de Logback, el `RequestContextHolder`. Funciona y evita que cada método
arrastre cinco parámetros.

**Qué pasa si lo aplicas aquí.** Escribes esto, y compila:

```go
// ☕ — el context como bolsa de parámetros
func (s *Service) Create(ctx context.Context) (workitem.WorkItem, error) {
	tenant := ctx.Value("tenant").(string)
	user := ctx.Value("user").(*User)
	ref := ctx.Value("externalReference").(string)
	prio := ctx.Value("priority").(int)

	// ...
}
```

Y has construido cuatro problemas:

1. **La firma miente.** `Create(ctx)` parece no necesitar nada y necesita cuatro
   cosas. El compilador no verifica ninguna: si falta `priority`, la aserción de
   tipo entra en **panic** en tiempo de ejecución. Acabas de cambiar errores de
   compilación por panics en producción.
2. **Las claves `string` colisionan.** `ctx.Value("user")` de tu paquete y
   `ctx.Value("user")` de una librería son la misma clave. Por eso la convención
   es un **tipo no exportado** como clave: nadie fuera de tu paquete puede
   fabricarlo.
3. **`Value` es una búsqueda lineal por la cadena de padres.** No es un mapa:
   cada `WithValue` envuelve el contexto anterior, y cada `Value` recorre esa
   cadena hacia arriba comparando claves hasta encontrar la suya. Es un hecho
   **estructural**, verificable leyendo `context.valueCtx` en la biblioteca
   estándar, y el argumento contra el abuso es ese, no un número: **el curso no lo
   ha medido y por eso no afirma cuánto cuesta.** Lo que sí se sostiene sin medir
   es que el coste crece con la profundidad de la cadena y que un valor en el
   fondo cuesta más que uno en la punta.
4. **Y lo importante: no es un `ThreadLocal`.** Un `ThreadLocal` es implícito y
   viaja con el hilo; el `context` es **explícito y viaja por parámetro**. Si
   alguien lanza una goroutine sin pasarlo, se pierde. Esa diferencia no es un
   defecto: es el diseño. Go prefiere que la dependencia se vea en la firma.

**Qué pensar en su lugar.** El `context` lleva **tres cosas y solo tres**:

- **Cancelación y plazos** — su razón de ser.
- **Valores de ámbito de petición que atraviesan capas sin pertenecer a ninguna**:
  el identificador de petición, el de traza, el de tenant en un sistema
  multi-inquilino.
- Y nada más.

Todo lo que es **entrada del caso de uso** va como parámetro. `externalReference`,
`priority` y el `WorkItem` entero son argumentos, no contexto.

```go
// ✅
func (s *Service) Create(ctx context.Context, item workitem.WorkItem) (workitem.WorkItem, error)
```

La prueba del algodón: **si quitar el valor del contexto rompe la lógica de
negocio, ese valor tenía que ser un parámetro.** Si solo empeora un log, es
contexto legítimo.

### El caso incómodo: el usuario autenticado

Y aquí hay que ser honesto, porque la respuesta no es limpia.

El usuario autenticado atraviesa todas las capas y no es exactamente un parámetro
de negocio. La respuesta idiomática de Go es **pasarlo como parámetro explícito** a
las funciones que lo necesitan, y la respuesta pragmática que se ve en muchos
repositorios serios es **guardarlo en el contexto con una clave privada y un par de
funciones de acceso tipadas**:

```go
type userKey struct{}

func WithUser(ctx context.Context, u *auth.User) context.Context {
	return context.WithValue(ctx, userKey{}, u)
}

// UserFrom devuelve el usuario de la petición. El segundo valor es false si no
// hay ninguno, y el llamador TIENE que comprobarlo: la aserción de un solo valor
// entra en panic y eso es exactamente lo que no queremos en un camino de
// autorización.
func UserFrom(ctx context.Context) (*auth.User, bool) {
	u, ok := ctx.Value(userKey{}).(*auth.User)
	return u, ok
}
```

Eso es aceptable **si** la clave es privada, el acceso es tipado, y la ausencia se
maneja explícitamente. Lo que no es aceptable es `ctx.Value("user").(*User)` con
aserción de un valor en mitad de la lógica de negocio.

En este curso Meridian vive tras un gateway que ya autenticó, así que el problema
no aparece. Pero si lo tienes en tu trabajo, esa es la forma menos mala.

### `Canceled` frente a `DeadlineExceeded`

```go
if err := doWork(ctx); err != nil {
	switch {
	case errors.Is(err, context.Canceled):
		// Alguien canceló a propósito: el cliente cerró la conexión, o pedimos
		// el apagado. NO es un error del sistema y no se cuenta como fallo.
		log.Printf("trabajo cancelado: %s", item.ID)

	case errors.Is(err, context.DeadlineExceeded):
		// Se acabó el tiempo. ESO sí es una señal: el sistema está lento o el
		// plazo está mal calibrado. Se cuenta como fallo y se mide.
		log.Printf("trabajo agotó su plazo: %s", item.ID)

	default:
		// Un error de verdad.
	}
}
```

**La distinción importa para las métricas y para la alerta.** Si cuentas las
cancelaciones como errores, una tarde con muchos clientes impacientes te despierta
de madrugada sin motivo. Si no cuentas los vencimientos de plazo, un sistema que
se está degradando te parece sano.

### Propagación: de dónde sale el contexto de una petición

```go
func (h *Handler) start(w http.ResponseWriter, r *http.Request, p router.Params) {
	// r.Context() se cancela solo cuando:
	//   - el cliente cierra la conexión
	//   - la respuesta termina de escribirse
	//   - el servidor se apaga (a partir de Go 1.8, con Shutdown)
	ctx := r.Context()

	item, err := h.svc.Start(ctx, p["id"])
	// ...
}
```

**`net/http` te da la cancelación del cliente gratis**, y esa es una diferencia
grande con el modelo de servlets: cuando un usuario cierra la pestaña, el contexto
se cancela y todo lo que cuelga de él —la consulta a la base de datos incluida—
recibe la señal. En Java, ese trabajo sigue hasta terminar y nadie se entera.

> 🧪 **Prueba de fuego.** Añade esto a un handler lento y llámalo con
> `curl --max-time 2`:
> ```go
> select {
> case <-time.After(10 * time.Second):
>     w.Write([]byte("terminado"))
> case <-r.Context().Done():
>     log.Printf("el cliente se fue: %v", r.Context().Err())
>     return
> }
> ```
> A los dos segundos, el log dice *"el cliente se fue: context canceled"*.
>
> **La mentira de la pantalla:** en la Fase 05, `fakeconsumer` seguía durmiendo los
> ocho segundos aunque el cliente se hubiera rendido. Ese handler no miraba
> `ctx.Done()`, así que seguía quemando un worker para nadie. **Ese es el
> argumento entero de esta fase en un ejemplo.**

### 🩻 Esto sí funciona igual

- **Los tiempos límite en cascada** son el mismo diseño que ya haces:
  `@Transactional(timeout=30)` y un `HttpClient` con timeout responden a la misma
  necesidad. Lo que cambia es que aquí el plazo se **hereda** hacia abajo sin que
  nadie lo reconfigure.
- **El apagado ordenado** es el mismo concepto que
  `Runtime.addShutdownHook` y el *graceful shutdown* de Spring Boot: dejar de
  aceptar, terminar lo empezado, cerrar recursos. La secuencia es idéntica.
- **La cancelación cooperativa** es exactamente `Thread.interrupt()`: una señal que
  el código tiene que **mirar**. Un bucle que ignora `isInterrupted()` no se para,
  igual que uno que ignora `ctx.Done()`.
- **Las fugas de recursos por hilos bloqueados** son el mismo problema con otro
  nombre. Un hilo esperando en una cola que nadie alimenta es una goroutine
  esperando en un canal que nadie cierra.
- **Y el criterio de dónde poner el plazo** es el mismo: en el borde, derivando
  hacia adentro, con margen para que la capa interna falle antes que la externa.

---

## 🛠️ 5. CLI de la fase

```bash
# El perfil de goroutines, que es LA herramienta para cazar fugas. debug=1 da el
# resumen agrupado por pila; debug=2 da una entrada por goroutine con su estado.
curl -s 'localhost:8080/debug/pprof/goroutine?debug=1' | head -40
curl -s 'localhost:8080/debug/pprof/goroutine?debug=2' > goroutines.txt

# El conteo rápido, que es lo primero que se mira.
curl -s 'localhost:8080/debug/pprof/goroutine?debug=1' | head -1
# goroutine profile: total 143

# Y la comparación antes/después, que es el diagnóstico real de una fuga.
curl -s 'localhost:8080/debug/pprof/goroutine?debug=1' | head -1
# ...generar carga...
curl -s 'localhost:8080/debug/pprof/goroutine?debug=1' | head -1

# Analizar el perfil con la herramienta, no a ojo. `top` ordena por número de
# goroutines en cada pila: la fuga está arriba del todo.
go1.13 tool pprof http://localhost:8080/debug/pprof/goroutine
# (pprof) top
# (pprof) traces
# (pprof) list nombreDeLaFuncion

# Mandar SIGTERM y ver el apagado ordenado. Es lo que hace un orquestador.
kill -TERM <pid>

# SIGQUIT sigue siendo el volcado de todas las pilas, de la Fase 06.
kill -QUIT <pid>

# Comprobar que el proceso terminó con código 0 y no lo mató el sistema.
echo $?

# Simular lo que hace Kubernetes: SIGTERM, esperar el periodo de gracia, y SIGKILL.
kill -TERM <pid>; sleep 30; kill -KILL <pid> 2>/dev/null

# El linter de esta fase: noctx detecta peticiones HTTP sin contexto. Está en el
# .golangci.yml desde la Fase 00 esperando a que hubiera algo que revisar.
golangci-lint run --enable-only noctx ./...

# Tests con detección de fugas: -count=5 para que una fuga acumulativa se note.
go1.13 test -race -count=5 ./internal/engine

# La documentación de la fase.
go1.13 doc context
go1.13 doc context.WithTimeout
go1.13 doc net/http Server.Shutdown
go1.13 doc os/signal Notify
```

> 💡 **`debug=2` es el que resuelve el caso.** `debug=1` agrupa por pila y te dice
> *"143 goroutines, 120 de ellas aquí"*. `debug=2` te da cada una con su estado y
> **cuánto tiempo lleva bloqueada**: `goroutine 847 [chan send, 62 minutes]`. Esos
> "62 minutes" son el diagnóstico.

---

## 💻 6. Construcción guiada

### 6.1 Mini proyecto: `cancellable-worker`

El canal `quit` de la Fase 06, reescrito con `context`, para que veas que es lo
mismo con más cosas.

```go
// labs/cancellable-worker/worker.go
package worker

import (
	"context"
	"log"
	"time"
)

// RunWithQuit es la versión de la Fase 06: un canal que alguien cierra.
func RunWithQuit(jobs <-chan Job, quit <-chan struct{}) {
	for {
		select {
		case job, ok := <-jobs:
			if !ok {
				return
			}
			process(job)
		case <-quit:
			return
		}
	}
}

// RunWithContext es lo mismo, y además hereda plazos y se propaga hacia abajo
// sin que nadie escriba código para ello.
func RunWithContext(ctx context.Context, jobs <-chan Job) {
	for {
		select {
		case job, ok := <-jobs:
			if !ok {
				return
			}
			// El contexto baja al procesamiento: si se cancela a mitad de un
			// job, el job se entera. Con el canal quit habría que pasarlo a mano
			// por cada nivel.
			processCtx(ctx, job)

		case <-ctx.Done():
			log.Printf("worker parando: %v", ctx.Err())
			return
		}
	}
}
```

Y ahora lo que de verdad cuesta entender: **cómo se hace cancelable un trabajo
largo.** Porque `ctx.Done()` en el `select` del bucle exterior no ayuda si el
trabajo en sí tarda diez minutos.

```go
// processCtx hace un trabajo largo que SE PUEDE cancelar, porque comprueba el
// contexto entre fragmentos.
//
// Esta es la parte que nadie cuenta: la cancelación es COOPERATIVA. Go no puede
// matar una goroutine desde fuera —no hay Thread.stop(), y es deliberado, porque
// matar un hilo a mitad de una operación deja el estado inconsistente—. Si tu
// código no mira el contexto, no se cancela y punto.
func processCtx(ctx context.Context, job Job) error {
	for i, chunk := range job.Chunks() {
		// La comprobación no bloqueante, entre fragmentos. Con fragmentos de
		// ~100 ms, la cancelación se nota en ~100 ms.
		select {
		case <-ctx.Done():
			return fmt.Errorf("procesando el fragmento %d: %w", i, ctx.Err())
		default:
		}

		if err := processChunk(ctx, chunk); err != nil {
			return err
		}
	}
	return nil
}
```

> 🧭 **Regla del proyecto: la granularidad de la comprobación define la latencia
> de la cancelación.** Comprobar `ctx.Done()` cada fragmento de 100 ms significa
> que el apagado tarda hasta 100 ms en notarse. Comprobarlo cada fragmento de diez
> minutos significa que tu `SIGTERM` no sirve de nada y el orquestador te va a
> mandar un `SIGKILL`. **Los fragmentos se dimensionan pensando en el apagado, no
> solo en la memoria.**

Y el error que todo el mundo comete la primera semana:

```go
// ❌ Esto NO es una comprobación: es un bucle de espera activa que quema una CPU.
for {
	select {
	case <-ctx.Done():
		return ctx.Err()
	default:
		// no hay trabajo que hacer aquí, así que gira a toda velocidad
	}
}

// ✅ Si no tienes nada que hacer, BLOQUÉATE en el select, sin default.
select {
case <-ctx.Done():
	return ctx.Err()
case job := <-jobs:
	return process(job)
}
```

El `default` es solo para cuando **sí** hay trabajo que hacer y quieres comprobar
de paso.

### 6.2 Mini proyecto: `timeout-client`

Plazos en cascada, y la lección de que el plazo se **hereda**.

```go
// labs/timeout-client/client.go
package client

import (
	"context"
	"fmt"
	"net/http"
	"time"
)

// FetchWithTimeout hace una petición con su propio plazo.
//
// ⚠️ Fíjate en que el plazo se aplica a TODA la operación: resolución DNS,
// conexión, handshake TLS, envío y lectura completa del cuerpo. No es un timeout
// de conexión. Eso confunde a mucha gente que viene de configurar
// connectTimeout y readTimeout por separado.
func FetchWithTimeout(parent context.Context, url string, timeout time.Duration) ([]byte, error) {
	ctx, cancel := context.WithTimeout(parent, timeout)
	defer cancel()

	req, err := http.NewRequest(http.MethodGet, url, nil)
	if err != nil {
		return nil, fmt.Errorf("construyendo la petición: %w", err)
	}
	// 🕰️ En Go 1.13, http.NewRequestWithContext ya existe (llegó en 1.13
	// justamente), y es lo que hay que usar. WithContext sobre una petición ya
	// construida sigue funcionando y es lo que verás en código anterior.
	req = req.WithContext(ctx)

	resp, err := http.DefaultClient.Do(req)
	if err != nil {
		// El error de un contexto vencido llega envuelto en un *url.Error, así
		// que errors.Is lo encuentra igual gracias a la cadena de %w.
		if errors.Is(err, context.DeadlineExceeded) {
			return nil, fmt.Errorf("la petición a %s agotó su plazo de %s: %w",
				url, timeout, err)
		}
		return nil, fmt.Errorf("petición a %s: %w", url, err)
	}
	defer resp.Body.Close()  // ⚠️ en el CLIENTE esto es obligatorio (Fase 10)

	return ioutil.ReadAll(resp.Body)
}
```

**La demostración que hay que ver: el plazo del padre gana.**

```go
func DemoInheritedDeadline() {
	// El padre da dos segundos.
	parent, cancelParent := context.WithTimeout(context.Background(), 2*time.Second)
	defer cancelParent()

	// El hijo pide diez... y no los consigue. El contexto resultante vence en el
	// MENOR de los dos plazos, siempre.
	child, cancelChild := context.WithTimeout(parent, 10*time.Second)
	defer cancelChild()

	deadline, _ := child.Deadline()
	fmt.Printf("el hijo pidió 10s y vence en %s\n", time.Until(deadline).Round(time.Millisecond))
	// el hijo pidió 10s y vence en 1.999s
}
```

> 🧠 **Modelo mental: el presupuesto de tiempo.** Si el borde HTTP fija un plazo de
> 3 s para la petición, todo lo que cuelgue de él comparte esos 3 s. Una consulta a
> base de datos que pida 10 s recibirá 3. **Eso es lo que quieres**: el plazo
> externo es el contrato con el cliente, y ninguna capa interna puede prometer más
> de lo que la externa concedió.
>
> El corolario práctico: **los plazos internos se ponen más cortos que el externo**,
> para que el fallo sea diagnosticable. Si el borde da 3 s y la base de datos tiene
> 2,5 s, un vencimiento de base de datos te dice *"la consulta es lenta"*. Si los
> dos tienen 3 s, solo sabes que algo tardó.

### 6.3 Mini proyecto: `graceful-server`

El apagado completo, que es el entregable estructural de la fase.

```go
// labs/graceful-server/main.go
package main

import (
	"context"
	"log"
	"net/http"
	"os"
	"os/signal"
	"syscall"
	"time"
)

func main() {
	srv := &http.Server{
		Addr:              ":8080",
		Handler:           buildHandler(),
		ReadHeaderTimeout: 5 * time.Second,
		ReadTimeout:       15 * time.Second,
		WriteTimeout:      30 * time.Second,
		IdleTimeout:       120 * time.Second,
	}

	// ListenAndServe BLOQUEA, así que va en su propia goroutine y comunica su
	// error por un canal. Con búfer 1 para que la goroutine pueda terminar
	// aunque nadie esté leyendo todavía: si fuera sin búfer y el apagado llegara
	// primero, esa goroutine se quedaría colgada. Es la fuga de la Fase 06
	// aplicada a un caso real.
	serverErr := make(chan error, 1)
	go func() {
		log.Printf("escuchando en %s", srv.Addr)
		serverErr <- srv.ListenAndServe()
	}()

	// signal.Notify redirige las señales a un canal.
	//
	// SIGTERM es lo que manda un orquestador (Docker, Kubernetes, systemd) para
	// pedir un apagado ordenado. SIGINT es el Ctrl+C.
	//
	// ⚠️ SIGKILL no se puede capturar. Por eso el apagado tiene que terminar
	// ANTES del periodo de gracia del orquestador (30 s por defecto en
	// Kubernetes), o te matan a mitad.
	//
	// El canal DEBE tener búfer: signal.Notify no bloquea al enviar, así que si
	// el canal está lleno la señal SE PIERDE. Con búfer 1 basta.
	shutdown := make(chan os.Signal, 1)
	signal.Notify(shutdown, syscall.SIGINT, syscall.SIGTERM)

	select {
	case err := <-serverErr:
		log.Fatalf("el servidor falló: %v", err)

	case sig := <-shutdown:
		log.Printf("recibida la señal %v, apagando", sig)

		// El plazo del apagado. Tiene que ser MENOR que el periodo de gracia
		// del orquestador, con margen.
		ctx, cancel := context.WithTimeout(context.Background(), 20*time.Second)
		defer cancel()

		// Shutdown: deja de aceptar conexiones nuevas, cierra las ociosas, y
		// espera a que terminen las peticiones EN CURSO.
		//
		// Devuelve el error del contexto si el plazo vence antes de que
		// terminen. En ese caso las peticiones en vuelo se cortan.
		if err := srv.Shutdown(ctx); err != nil {
			log.Printf("apagado forzado tras %s: %v", 20*time.Second, err)

			// Close() cierra todo de golpe, sin esperar. Es el último recurso.
			if cerr := srv.Close(); cerr != nil {
				log.Printf("error cerrando el servidor: %v", cerr)
			}
		}
		log.Println("servidor detenido")
	}
}
```

> ⚠️ **Tres detalles de este código que parecen menores y no lo son.**
>
> **1. `ListenAndServe` devuelve `http.ErrServerClosed` tras un `Shutdown`.** No es
> un error: es cómo te avisa de que terminó bien. Tratarlo como fallo produce un
> `log.Fatal` en cada apagado limpio.
>
> **2. El canal de señales necesita búfer.** `signal.Notify` documenta
> explícitamente que **no bloquea**: si el canal está lleno, la señal se descarta.
> Un canal sin búfer al que nadie está escuchando en ese instante pierde el
> `SIGTERM`, y tu proceso muere por `SIGKILL` treinta segundos después sin haber
> drenado nada.
>
> **3. `Shutdown` no espera a las conexiones *hijacked* ni a los WebSockets**, y
> tampoco a las goroutines que tus handlers hayan lanzado. Eso es responsabilidad
> tuya, y es justo lo que hacemos en §6.5.

### 6.4 Mini proyecto: `leak-detector`

Cazar fugas a mano, que es lo que hace entender qué busca `goleak`.

```go
// labs/leak-detector/detect.go
package leak

import (
	"runtime"
	"sort"
	"strings"
	"testing"
	"time"
)

// CheckNoLeaks compara el número de goroutines antes y después, dando margen
// para las que están terminando.
//
// Es lo que goleak hace, simplificado. La diferencia importante: goleak inspecciona
// las PILAS y sabe ignorar las goroutines legítimas del runtime y de la stdlib
// (el recolector, el servidor de pprof, los timers). Esta versión solo cuenta, y
// por eso necesita el margen y los reintentos.
func CheckNoLeaks(t *testing.T, before int) {
	t.Helper()

	// Reintentar: una goroutine que está saliendo tarda un poco en desaparecer
	// de la cuenta. Fallar al primer intento produce tests intermitentes.
	deadline := time.Now().Add(2 * time.Second)
	var after int

	for time.Now().Before(deadline) {
		runtime.Gosched() // ceder el turno para que las que salen, salgan
		after = runtime.NumGoroutine()
		if after <= before {
			return
		}
		time.Sleep(20 * time.Millisecond)
	}

	// Si seguimos aquí, hay fuga. Volcar las pilas es lo único que la hace
	// diagnosticable.
	buf := make([]byte, 1<<20)
	n := runtime.Stack(buf, true) // true = todas las goroutines

	t.Errorf("fuga de goroutines: antes=%d después=%d (+%d)\n\n%s",
		before, after, after-before, buf[:n])
}

// Snapshot toma la línea base. Se llama al principio del test.
func Snapshot() int {
	runtime.GC()
	time.Sleep(50 * time.Millisecond)
	return runtime.NumGoroutine()
}
```

```go
// Y su uso, que es el patrón que a partir de hoy llevan los tests de
// concurrencia de los dos servicios:
func TestEngine_NoLeaksAfterShutdown(t *testing.T) {
	before := leak.Snapshot()
	defer leak.CheckNoLeaks(t, before)

	eng := engine.New(runner, store, clk, 4, 100)
	eng.Start()

	for i := 0; i < 50; i++ {
		_ = eng.Submit(makeItem(i))
	}

	ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
	defer cancel()
	eng.Shutdown(ctx)
}
```

Y la otra herramienta, que es la que usarás en producción:

```go
// En main, detrás de una bandera y NUNCA en el puerto público:
if cfg.DebugAddr != "" {
	go func() {
		// net/http/pprof se registra solo en el DefaultServeMux al importarlo.
		// Ese efecto secundario del import es la razón por la que exponer el
		// DefaultServeMux en el puerto público es un fallo de seguridad: se
		// regalan los perfiles de memoria y las pilas del proceso.
		log.Printf("servidor de depuración en %s", cfg.DebugAddr)
		log.Println(http.ListenAndServe(cfg.DebugAddr, nil))
	}()
}
```

```bash
curl -s 'localhost:6060/debug/pprof/goroutine?debug=1' | head -20
```

```text
goroutine profile: total 847
812 @ 0x43b5a5 0x40b1cf 0x40ae3b 0x8f3a12 0x46c621
#	0x8f3a11	github.com/meridian/eventrelay/internal/dispatcher.(*Dispatcher).scheduleRetry.func1+0x91

 12 @ 0x43b5a5 0x4074fc 0x8a12cc 0x46c621
#	0x8a12cb	net/http.(*conn).serve+0x5cb
```

**812 goroutines en la misma línea de `scheduleRetry`.** Diagnóstico cerrado en
diez segundos: los reintentos programados no se están cancelando.

### 6.5 OpsReport: cancelación de punta a punta

Ahora lo real. Tres piezas: la firma con `ctx`, la cancelación de un trabajo
concreto, y el apagado con plazo.

**Primero, `ctx` en todas las firmas.** Es un cambio mecánico y grande:

```go
// services/opsreport/internal/opsreport/service.go

type Store interface {
	Save(ctx context.Context, item workitem.WorkItem) error
	FindByID(ctx context.Context, id string) (workitem.WorkItem, error)
	ListByStatus(ctx context.Context, status workitem.Status) ([]workitem.WorkItem, error)
	Update(ctx context.Context, item workitem.WorkItem) error
}

func (s *Service) Start(ctx context.Context, id string) (workitem.WorkItem, error) {
	item, err := s.store.FindByID(ctx, id)
	// ...
}
```

`memstore` no hace E/S de verdad, así que `ctx` ahí parece decorativo. **No lo
es**: en la Fase 09 esa misma interfaz la va a implementar PostgreSQL, y entonces
`ctx` llega hasta el driver y una consulta lenta se cancela de verdad. Poner el
parámetro ahora evita cambiar treinta firmas entonces.

```go
// Y memstore lo respeta aunque no lo necesite, porque un fake que ignora la
// cancelación esconde bugs que la implementación real sí tendría.
func (s *Store) FindByID(ctx context.Context, id string) (workitem.WorkItem, error) {
	if err := ctx.Err(); err != nil {
		return workitem.WorkItem{}, err
	}

	s.mu.RLock()
	defer s.mu.RUnlock()
	// ...
}
```

**Segundo, cancelar un trabajo en curso.** Este es el caso interesante: el motor
está ejecutando un trabajo y llega un `DELETE`.

```go
// services/opsreport/internal/engine/engine.go

type Engine struct {
	// ...

	// running lleva la función de cancelación de cada trabajo en vuelo, para
	// poder cancelar UNO concreto desde fuera.
	runningMu sync.Mutex
	running   map[string]context.CancelFunc
}

// Cancel cancela el trabajo en curso con ese identificador. Devuelve false si no
// estaba ejecutándose (puede estar en cola, o ya terminado).
func (e *Engine) Cancel(id string) bool {
	e.runningMu.Lock()
	defer e.runningMu.Unlock()

	cancel, ok := e.running[id]
	if !ok {
		return false
	}
	cancel()
	return true
}

func (e *Engine) execute(ctx context.Context, workerID int, item workitem.WorkItem) {
	// El contexto del trabajo cuelga del contexto del motor: si el motor se
	// apaga, todos los trabajos en vuelo se cancelan. Y además tiene su propio
	// plazo máximo, para que un trabajo colgado no bloquee un worker para
	// siempre.
	jobCtx, cancel := context.WithTimeout(ctx, e.maxJobDuration)
	defer cancel()

	e.runningMu.Lock()
	e.running[item.ID] = cancel
	e.runningMu.Unlock()

	defer func() {
		e.runningMu.Lock()
		delete(e.running, item.ID)   // ← sin este delete, el mapa crece sin fin
		e.runningMu.Unlock()
	}()

	start := e.clock.Now()
	runErr := e.runWithRecover(jobCtx, item)
	finish := e.clock.Now()

	switch {
	case errors.Is(runErr, context.Canceled):
		// Cancelación explícita: el trabajo pasa a cancelled y NO cuenta como
		// fallo en las métricas.
		_ = item.Cancel(finish)
		e.countCancelled()

	case errors.Is(runErr, context.DeadlineExceeded):
		// Venció el plazo máximo del trabajo. ESO sí es un fallo, y con un
		// motivo que el operador puede entender.
		_ = item.MarkFailed(finish, fmt.Sprintf("superó el plazo máximo de %s", e.maxJobDuration))
		e.countFailure()

	case runErr != nil:
		_ = item.MarkFailed(finish, runErr.Error())
		e.countFailure()

	default:
		_ = item.MarkDone(finish)
		e.countSuccess()
	}

	e.persist(item, start, finish, runErr)
}
```

Y el detalle que hace que esto funcione de punta a punta: **el contexto del
handler HTTP no sirve para el trabajo de fondo**.

```go
func (h *WorkItemHandler) start(w http.ResponseWriter, r *http.Request, p router.Params) {
	// ❌ Si pasáramos r.Context() al motor, el trabajo se cancelaría en cuanto la
	//    respuesta HTTP terminara de escribirse. El trabajo dura minutos; la
	//    petición, milisegundos.
	//
	// ✅ El motor tiene su PROPIO contexto, con el ciclo de vida del proceso. El
	//    de la petición solo gobierna la operación de encolar.
	item, err := h.svc.Start(r.Context(), p["id"])
	if err != nil {
		writeError(w, r, err)
		return
	}
	writeJSON(w, http.StatusAccepted, toJSON(item, h.now()))
}
```

> ⚠️ **Este es el error conceptual número uno con `context` en servicios.** Pasar
> el contexto de la petición a un trabajo de fondo hace que el trabajo muera en
> cuanto el cliente reciba la respuesta, de forma intermitente y desconcertante.
> **La pregunta que hay que hacerse siempre: ¿este trabajo tiene que morir cuando
> muera la petición?** Para una consulta, sí. Para un job encolado, no.
>
> 🕰️ Go 1.21 añadió `context.WithoutCancel(ctx)`, que crea un contexto que hereda
> los **valores** pero no la cancelación — exactamente para este caso, cuando
> quieres conservar el identificador de traza en el trabajo de fondo sin heredar
> su muerte. Fase 08.

**Tercero, el apagado con plazo**, que era la deuda de la Fase 06:

```go
// Shutdown deja de aceptar trabajo, drena la cola dentro del plazo del contexto,
// y devuelve a `queued` lo que no dio tiempo.
//
// Los dos comportamientos son deliberados y distintos:
//   - los trabajos EN COLA que no se procesan se quedan en queued: se retomarán
//     al arrancar (hoy se pierden, porque la cola es memoria — 💸 Fase 09);
//   - los trabajos EN VUELO se cancelan y vuelven a queued, no a failed: no
//     fallaron, los interrumpimos nosotros, y esa distinción importa para el
//     operador que mire el panel mañana.
func (e *Engine) Shutdown(ctx context.Context) error {
	e.quitOnce.Do(func() {
		close(e.quit)   // Submit empieza a rechazar
		close(e.jobs)   // los workers salen al vaciar la cola
	})

	done := make(chan struct{})
	go func() {
		e.wg.Wait()
		close(done)
	}()

	select {
	case <-done:
		log.Printf("motor detenido limpiamente: %+v", e.Stats())
		return nil

	case <-ctx.Done():
		// Se acabó el tiempo. Cancelar todo lo que siga en vuelo.
		log.Printf("apagado del motor agotó su plazo; cancelando %d trabajos en vuelo",
			e.runningCount())
		e.cancelAllRunning()

		// Segunda espera, corta: los trabajos cancelados tienen que poder
		// cerrar sus recursos.
		select {
		case <-done:
			return ctx.Err()
		case <-time.After(2 * time.Second):
			return fmt.Errorf("%w: quedaron workers sin terminar", ctx.Err())
		}
	}
}

func (e *Engine) cancelAllRunning() {
	e.runningMu.Lock()
	defer e.runningMu.Unlock()
	for _, cancel := range e.running {
		cancel()
	}
}
```

Y el `main` completo, que es donde se ve el orden del apagado:

```go
func main() {
	// ... configuración, cableado ...

	// El contexto raíz del proceso. Todo lo de larga duración cuelga de aquí.
	ctx, cancelRoot := context.WithCancel(context.Background())
	defer cancelRoot()

	eng := engine.New(runner, store, clk, cfg.WorkerCount, cfg.QueueSize)
	eng.Start(ctx)

	srv := buildServer(cfg, svc, eng)

	serverErr := make(chan error, 1)
	go func() { serverErr <- srv.ListenAndServe() }()

	shutdown := make(chan os.Signal, 1)
	signal.Notify(shutdown, syscall.SIGINT, syscall.SIGTERM)

	select {
	case err := <-serverErr:
		if err != nil && !errors.Is(err, http.ErrServerClosed) {
			log.Fatalf("el servidor falló: %v", err)
		}

	case sig := <-shutdown:
		log.Printf("recibida la señal %v; apagando en orden", sig)

		shutdownCtx, cancel := context.WithTimeout(context.Background(), cfg.ShutdownTimeout)
		defer cancel()

		// EL ORDEN IMPORTA, y es este:
		//
		// 1. Primero el servidor HTTP: deja de aceptar peticiones nuevas y
		//    termina las que estén en curso. Si apagáramos el motor primero, las
		//    peticiones en vuelo intentarían encolar en un motor muerto.
		if err := srv.Shutdown(shutdownCtx); err != nil {
			log.Printf("apagado del servidor HTTP incompleto: %v", err)
		}

		// 2. Después el motor: ya no entra trabajo nuevo, así que drenar es
		//    finito.
		if err := eng.Shutdown(shutdownCtx); err != nil {
			log.Printf("apagado del motor incompleto: %v", err)
		}

		// 3. Y al final, cancelar el contexto raíz para lo que quede vivo.
		cancelRoot()
	}

	log.Println("proceso terminado")
}
```

> 🧭 **Regla del proyecto: el apagado va de fuera hacia adentro.** Primero se cierra
> la puerta (el servidor HTTP), después se vacía lo de dentro (el motor), y al final
> se sueltan los recursos (conexiones, contexto raíz). Al revés, el trabajo en
> vuelo intenta usar cosas ya cerradas y el log se llena de errores que no son
> errores.

### 6.6 EventRelay: plazos por entrega y entregas en vuelo

```go
// services/eventrelay/internal/dispatcher/dispatcher.go

func (d *Dispatcher) deliver(ctx context.Context, workerID int, delivery relay.Delivery) {
	// Cada entrega tiene su propio plazo. Sin esto, un socio que no cierra la
	// conexión bloquea un worker para siempre — y es exactamente lo que
	// fakeconsumer /slow simula.
	ctx, cancel := context.WithTimeout(ctx, d.perDeliveryTimeout)
	defer cancel()

	now := d.clock.Now()
	err := d.sender.Send(ctx, delivery)

	switch {
	case errors.Is(err, context.Canceled):
		// Nos apagamos a mitad. La entrega NO ha fallado: vuelve a pending para
		// que la retome el siguiente arranque, sin gastar un intento.
		//
		// Esta distinción es la diferencia entre un socio que recibe su evento
		// con cinco minutos de retraso y un socio cuya entrega acabó en la cola
		// de muertos porque nosotros reiniciamos.
		if rerr := delivery.Requeue(); rerr != nil {
			log.Printf("no se pudo devolver %s a la cola: %v", delivery.ID, rerr)
		}

	case errors.Is(err, context.DeadlineExceeded):
		// El socio tardó demasiado. ESO sí gasta un intento: es información
		// sobre el socio, no sobre nosotros.
		_ = delivery.RecordFailure(now, fmt.Sprintf("el endpoint no respondió en %s",
			d.perDeliveryTimeout))

	case err != nil:
		_ = delivery.RecordFailure(now, err.Error())

	default:
		_ = delivery.RecordSuccess(now)
	}

	// El guardado usa un contexto APARTE, sin el plazo de la entrega.
	//
	// Si usáramos el mismo, una entrega que agota su plazo no podría ni
	// registrar que lo agotó: el contexto ya está vencido y el Update fallaría
	// también. Es un error sutil y muy común.
	//
	// 🕰️ Go 1.21: context.WithoutCancel(ctx) es exactamente esto, conservando
	// los valores (identificador de traza) y descartando la cancelación.
	saveCtx, saveCancel := context.WithTimeout(context.Background(), 5*time.Second)
	defer saveCancel()

	if err := d.store.UpdateDelivery(saveCtx, delivery); err != nil {
		log.Printf("no se pudo actualizar la entrega %s: %v", delivery.ID, err)
	}
}
```

> ⚠️ **El contexto vencido que impide registrar el fallo** es uno de esos bugs que
> solo aparecen bajo carga: todo funciona hasta que algo empieza a tardar, y
> entonces el sistema deja de poder anotar por qué está tardando. Cuando escribas
> una operación de limpieza o de registro después de un fallo, **pregúntate siempre
> si el contexto que estás usando sigue vivo.**

Y el test que cierra la fase:

```go
// services/eventrelay/internal/dispatcher/shutdown_test.go

func TestDispatcher_ShutdownRequeuesInFlight(t *testing.T) {
	before := leak.Snapshot()
	defer leak.CheckNoLeaks(t, before)

	// Un sender que tarda más de lo que vamos a esperar.
	slow := senderFunc(func(ctx context.Context, d relay.Delivery) error {
		select {
		case <-time.After(5 * time.Second):
			return nil
		case <-ctx.Done():
			return ctx.Err()
		}
	})

	store := newFakeStore()
	d := dispatcher.New(slow, store, clock.NewFake(testNow), 2, 10, 1, time.Minute)

	for i := 0; i < 4; i++ {
		d.Enqueue(makeDelivery(i))
	}
	time.Sleep(100 * time.Millisecond) // dejar que dos entren en vuelo

	ctx, cancel := context.WithTimeout(context.Background(), 500*time.Millisecond)
	defer cancel()

	start := time.Now()
	_ = d.Shutdown(ctx)
	elapsed := time.Since(start)

	// El apagado respeta su plazo: no espera los 5 s del sender.
	if elapsed > time.Second {
		t.Errorf("el apagado tardó %s; el plazo era 500ms", elapsed)
	}

	// Y las entregas en vuelo volvieron a pending, no a failing.
	for _, d := range store.All() {
		if d.Status == relay.DeliveryFailing || d.Status == relay.DeliveryDead {
			t.Errorf("la entrega %s quedó en %s; debería estar en pending", d.ID, d.Status)
		}
		if d.Attempts != 0 {
			t.Errorf("la entrega %s gastó %d intentos por nuestro apagado", d.ID, d.Attempts)
		}
	}
}
```

---

## ⚰️ 7. Autopsia y errores comunes

### ⚰️ Autopsia: el `context` guardado en el struct

**El cadáver.** Es el reflejo de `ThreadLocal` en su forma más convincente, porque
parece que ahorra trabajo:

```go
// ☕
type ReportGenerator struct {
	ctx    context.Context   // ← guardado en el struct
	store  Store
	logger *log.Logger
}

func NewReportGenerator(ctx context.Context, store Store) *ReportGenerator {
	return &ReportGenerator{ctx: ctx, store: store}
}

// Todos los métodos usan s.ctx y así las firmas quedan "limpias".
func (g *ReportGenerator) Generate(req ReportRequest) (*Report, error) {
	rows, err := g.store.Query(g.ctx, req.Filter)
	if err != nil {
		return nil, err
	}
	return buildReport(rows), nil
}
```

El argumento que lo sostiene es real: **las firmas quedan más cortas**, y en Java
no tendrías esta discusión porque el `ThreadLocal` lo resuelve.

**El informe forense.** Cuatro fallos, en orden de gravedad:

**1. El generador se construye una vez y vive todo el proceso; el contexto que
recibió pertenece a **una** petición.** En cuanto esa primera petición termina, el
contexto guardado está cancelado — y **todas las peticiones siguientes fallan con
`context canceled`**. Si el generador se construye con `context.Background()`, el
problema es el inverso: **ninguna** petición se puede cancelar nunca.

**2. Dos peticiones simultáneas comparten un contexto que pertenece a una.** El
plazo de la primera cancela el trabajo de la segunda.

**3. No se puede poner un plazo distinto por operación.** Todas las llamadas
heredan el mismo, sea cual sea su coste.

**4. Y el que lo hace indetectable en pruebas:** con un solo test secuencial,
funciona. El bug aparece con concurrencia, bajo carga, de forma intermitente.

| | `ctx` en el struct | `ctx` como primer parámetro |
|---|---|---|
| Longitud media de la firma | 1 parámetro menos | 1 parámetro más |
| Peticiones que pueden cancelarse independientemente | **1** (o ninguna) | todas |
| Plazo por operación | uno para todo | el que cada llamada necesite |
| Detectable en un test secuencial | **no** | n/a |
| Lo detecta `golangci-lint` | **`containedctx` sí** (no está en nuestra config) | n/a |
| Qué dice la documentación oficial | *"Do not store Contexts inside a struct type"* | es la recomendación |

**La causa de la muerte.** El reflejo de `ThreadLocal`, combinado con una aversión
razonable a la verbosidad. Y hay que reconocer que **el argumento de la verbosidad
es cierto**: `ctx` como primer parámetro de todo es ruidoso, aparece en cada firma,
y cuando refactorizas hay que propagarlo por veinte funciones.

El equipo de Go lo sabe y lo defendió explícitamente: prefieren la verbosidad
explícita a la magia implícita, porque **una dependencia invisible es una
dependencia que nadie mantiene**. Con `ThreadLocal`, el día que alguien lanza un
hilo y el contexto no se propaga, el fallo es silencioso y muy difícil de
diagnosticar. Con el parámetro, no compila.

**La única excepción reconocida**, y la documentación la nombra: algunos structs
de la stdlib —`http.Request`— llevan un contexto dentro, porque **el struct
representa la propia petición**, tiene exactamente su ciclo de vida, y se accede
con métodos (`Context()`/`WithContext()`), no con un campo público. Si tu struct
es literalmente "una operación en curso", guardarlo es defendible. Un `Service`,
un `Store` o un `Generator` no lo son.

> ☕ **El patrón a memorizar.** **Un contexto pertenece a una llamada, no a un
> objeto.** Si el struct vive más que la operación, el contexto no va dentro.

### Errores comunes

**1. `cancel()` sin llamar.**
*Síntoma:* la memoria crece con cada petición; `go vet` protesta.
*Causa:* `WithCancel`/`WithTimeout` registran el hijo en el padre y no lo sueltan.
*Fix mínimo:* `defer cancel()` **siempre**, sin excepciones.

**2. Pasar el contexto de la petición a un trabajo de fondo.**
*Síntoma:* trabajos que se cancelan solos, de forma intermitente, justo cuando
terminan de responder.
*Causa:* `r.Context()` se cancela al terminar la respuesta.
*Fix mínimo:* el trabajo de fondo usa el contexto del proceso. 🕰️
`context.WithoutCancel` en Go 1.21 conserva los valores sin heredar la
cancelación.

**3. El contexto vencido que impide la limpieza.**
*Síntoma:* un fallo por vencimiento de plazo no queda registrado en la base de
datos.
*Causa:* se usa el mismo contexto ya vencido para el `UPDATE` posterior.
*Fix mínimo:* contexto nuevo y corto para la limpieza.

**4. `ctx.Done()` con `default` en un bucle vacío.**
*Síntoma:* una CPU al 100% sin hacer nada.
*Causa:* `select` con `default` y sin trabajo dentro es espera activa.
*Fix mínimo:* quitar el `default` y bloquearse.

**5. No mirar `ctx.Done()` nunca.**
*Síntoma:* el `SIGTERM` no hace nada y el orquestador acaba mandando `SIGKILL`.
*Causa:* la cancelación es cooperativa; si nadie la mira, no ocurre.
*Fix mínimo:* comprobar entre fragmentos, y dimensionar los fragmentos pensando en
el apagado.

**6. Canal de señales sin búfer.**
*Síntoma:* el `SIGTERM` se pierde y el proceso muere sin drenar.
*Causa:* `signal.Notify` **no bloquea**: si el canal está lleno, descarta.
*Fix mínimo:* `make(chan os.Signal, 1)`.

**7. Tratar `http.ErrServerClosed` como error.**
*Síntoma:* `log.Fatal` en cada apagado limpio, y código de salida distinto de cero.
*Causa:* `ListenAndServe` devuelve ese error cuando `Shutdown` lo detuvo.
*Fix mínimo:* `if err != nil && !errors.Is(err, http.ErrServerClosed)`.

**8. Claves de contexto de tipo `string`.**
*Síntoma:* un valor se pisa con el de una librería, o `Value` devuelve algo
inesperado.
*Causa:* dos paquetes usan la misma cadena.
*Fix mínimo:* `type requestIDKey struct{}` — un tipo no exportado que nadie fuera
puede fabricar.

**9. `ctx.Value` con aserción de un solo valor.**
*Síntoma:* panic en producción cuando el valor no está.
*Causa:* `ctx.Value(k).(*User)` entra en panic si es nil.
*Fix mínimo:* la forma de dos valores y manejar la ausencia.

**10. Apagar el motor antes que el servidor HTTP.**
*Síntoma:* al apagar, el log se llena de "la cola está cerrada" y algunas
peticiones devuelven 503.
*Causa:* orden invertido.
*Fix mínimo:* de fuera hacia adentro, siempre.

### 🧨 Rompe a propósito

**Haz que el `SIGTERM` no sirva de nada**, que es lo que le pasa a la mayoría de
los servicios en su primer despliegue en Kubernetes:

```go
// El runner que ignora el contexto. Compila, funciona, y hace que el apagado
// ordenado sea decorativo.
type StubbornRunner struct{}

func (StubbornRunner) Run(ctx context.Context, item workitem.WorkItem) error {
	// 45 segundos de trabajo sin mirar ctx ni una vez.
	time.Sleep(45 * time.Second)
	return nil
}
```

Arranca el servicio, encola cuatro trabajos, y manda `SIGTERM`. Cronometra.

El apagado pide 20 segundos. `Shutdown` del motor espera esos 20, vence, llama a
`cancelAllRunning()`... y **no pasa nada**, porque `time.Sleep` no mira nada.
Espera dos segundos más y devuelve el error. El proceso sigue vivo con cuatro
workers durmiendo, hasta que el orquestador manda `SIGKILL` a los 30 segundos y
mata todo en seco.

Ahora cambia el runner por la versión que comprueba entre fragmentos:

```go
func (FragmentedRunner) Run(ctx context.Context, item workitem.WorkItem) error {
	for i := 0; i < 450; i++ {
		select {
		case <-ctx.Done():
			return ctx.Err()
		case <-time.After(100 * time.Millisecond):
		}
	}
	return nil
}
```

El apagado tarda ~100 ms.

**La lección, que es la de toda la fase:** el apagado ordenado no lo hace el
`main`. Lo hace **cada función que mira su contexto**. El `main` solo coordina, y
si una sola función del camino ignora la señal, toda la cadena se rompe.

---

## 🧪 8. Ejercicios (24)

**🟢 Fácil (1–6)**

1. Escribe una función que haga trabajo en diez fragmentos y se cancele entre
   ellos. *Criterio:* cancelar a mitad devuelve `context.Canceled` en menos de un
   fragmento de tiempo.
2. Demuestra que el plazo del padre gana sobre el del hijo. *Criterio:* imprimes
   los dos `Deadline()` y explicas el resultado.
3. Provoca el aviso de `go vet` por no llamar a `cancel()`. *Criterio:* pegas el
   mensaje exacto y explicas qué fuga previene.
4. Distingue `context.Canceled` de `context.DeadlineExceeded` con `errors.Is` en
   los dos casos. *Criterio:* explicas por qué las métricas deben tratarlos
   distinto.
5. Monta el servidor con `signal.Notify` y apágalo con `SIGTERM`. *Criterio:* el
   proceso sale con código 0 y el log muestra la secuencia completa.
6. Usa `go1.13 doc context` y explica en tres líneas por qué `Value` es una
   búsqueda lineal y qué implica.

**🟡 Intermedio (7–15)**

7. Añade `ctx` como primer parámetro a todas las firmas de E/S de OpsReport.
   *Criterio:* `golangci-lint run --enable-only noctx` en verde, y explicas por
   qué `memstore` también lo comprueba aunque no haga E/S.
8. Haz que `DELETE /work-items/{id}` cancele el trabajo en curso. *Criterio:* un
   test encola un trabajo largo, lo cancela por HTTP, y verifica que termina en
   estado `cancelled` en menos de 200 ms.
9. Implementa el plazo máximo por trabajo. *Criterio:* un runner que tarda más se
   marca `failed` con un motivo legible, **no** `cancelled`.
10. Implementa `Engine.Shutdown(ctx)` con plazo y demuestra los dos caminos: el
    que termina a tiempo y el que vence. *Criterio:* dos tests, y el segundo
    verifica que los trabajos en vuelo vuelven a `queued`.
11. Monta el apagado completo de OpsReport con el orden correcto. *Criterio:*
    inviertes el orden a propósito, muestras qué se rompe, y lo restauras.
12. Implementa `CheckNoLeaks` y aplícalo a los tests del motor. *Criterio:*
    introduces una fuga a propósito y el test la detecta con la pila volcada.
13. Expón `/debug/pprof` en un puerto aparte y analiza el perfil `goroutine` bajo
    carga. *Criterio:* usas `debug=2`, encuentras una goroutine bloqueada mucho
    tiempo, y explicas por qué ese puerto no puede ser el público.
14. Implementa el plazo por entrega de EventRelay contra `fakeconsumer /slow`.
    *Criterio:* el worker se libera al vencer el plazo, la entrega gasta un
    intento, y el registro queda guardado.
15. **Línea de comandos.** Simula el ciclo de Kubernetes: `SIGTERM`, 30 s de
    gracia, `SIGKILL`. *Criterio:* con el apagado bien hecho el `SIGKILL` nunca
    llega a hacer falta, y lo demuestras con la marca de tiempo del log.

**🟠 Difícil (16–21)**

16. **Diagnóstico (1).** Un servicio donde todas las peticiones fallan con
    `context canceled` a partir de la segunda. *Criterio:* identificas el contexto
    guardado en el struct, lo arreglas, y escribes el test concurrente que lo
    habría detectado.
17. **Diagnóstico (2).** Un trabajo de fondo que se cancela solo, de forma
    intermitente. *Criterio:* localizas el `r.Context()` propagado al motor, lo
    arreglas, y explicas por qué era intermitente.
18. **Diagnóstico (3).** Un fallo por vencimiento de plazo que no queda registrado
    en el almacén. *Criterio:* identificas el contexto vencido reutilizado, lo
    arreglas, y anotas qué haría `context.WithoutCancel` 🕰️.
19. **Diagnóstico (4).** Un `SIGTERM` que no hace nada: reproduce el 🧨 de §7.
    *Criterio:* cronometras las dos versiones, y calculas qué tamaño de fragmento
    necesitas para que el apagado quepa en un periodo de gracia de 30 s.
20. **Diagnóstico (5).** Una fuga de 800 goroutines en `scheduleRetry`.
    *Criterio:* la encuentras con el perfil `goroutine`, identificas el `select`
    sin caso de salida, lo arreglas, y el test de fugas lo verifica.
21. **Diagnóstico (6).** Un `SIGTERM` que se pierde por un canal sin búfer.
    *Criterio:* reproduces la pérdida —hace falta que el proceso esté ocupado en el
    momento de la señal—, lo explicas citando la documentación de `signal.Notify`, y
    lo arreglas.

**🔴 Muy difícil (22–24)**

22. **Diagnóstico (7) — el caso compuesto.** Te dan un servicio que en apariencia
    se apaga bien: el log dice "servidor detenido" y el proceso sale con 0. Pero
    cada reinicio pierde entre tres y ocho entregas, que aparecen como `dead` sin
    haber gastado sus intentos. *Rúbrica:* (a) reproduces la pérdida de forma
    fiable; (b) identificas las **dos** causas —hay más de una: un contexto mal
    elegido y un orden de apagado invertido—; (c) las arreglas por separado y
    demuestras el efecto de cada arreglo; (d) escribes el test de invariante *"tras
    el apagado, ninguna entrega gastó un intento por nuestra culpa"*; (e) explicas
    por qué el log decía que todo había ido bien.
23. **Diagnóstico (8) — el apagado bajo carga real.** Somete OpsReport a 500
    peticiones por segundo y manda `SIGTERM` en medio. *Rúbrica:* (a) ninguna
    petición **aceptada** recibe una respuesta cortada o un error de conexión; (b)
    las que llegan después del `SIGTERM` reciben 503 y no una conexión rechazada
    en seco —investiga cómo, porque `Shutdown` deja de escuchar inmediatamente y
    esto requiere una decisión de diseño—; (c) ningún trabajo queda en estado
    inconsistente; (d) cero goroutines fugadas; (e) el apagado completo cabe en 10
    s y lo cronometras; (f) documentas qué le dirías al equipo de plataforma sobre
    el `terminationGracePeriodSeconds` que necesitas.
24. **El manual de ciclo de vida de Meridian.** Escribe
    `docs/ciclo-de-vida.md`: el contrato de arranque y apagado que los cuatro
    servicios del curso van a cumplir. *Rúbrica:* (a) define el orden exacto de
    apagado y el porqué de cada paso; (b) fija los plazos y su relación con el
    periodo de gracia del orquestador, con números y su justificación; (c) define
    qué estados son aceptables tras un apagado forzado y cuáles indican un bug; (d)
    incluye la regla de granularidad de fragmentos con el cálculo del ejercicio 19;
    (e) incluye la política de `context`: qué va dentro, qué no, y la lista de
    errores de §7 como revisión; (f) es lo bastante concreto como para que los
    servicios de las Fases 09 y 10 lo hereden sin decisiones nuevas.

**🔥 Opcionales**

- Lee `context/context.go` en tu `GOROOT`. Son unas seiscientas líneas y el
  mecanismo de propagación —`propagateCancel`, la lista de hijos, `removeChild`—
  explica exactamente por qué `cancel()` sin llamar es una fuga.
- Implementa un `context.Context` propio que registre cada `Value` consultado, y
  úsalo para descubrir qué valores lee tu código de verdad. Es una forma rápida de
  encontrar abuso del contexto en un repositorio ajeno.
- Investiga qué hace `Shutdown` con una conexión *hijacked* (WebSocket, por
  ejemplo) y diseña cómo cerrarías esas conexiones ordenadamente. La stdlib no te
  ayuda y la respuesta es interesante.

---

### 🔴 Desafíos de cierre

> Tres ejercicios de dificultad alta que **no cuentan en el total de la sección** y
> no son parte del recorrido base.

**D1 — El árbol de cancelación, visible.**
Implementa un `context.Context` propio que envuelva a otro y **registre el árbol
completo**: quién creó a quién, con qué plazo, y quién canceló primero.
*Rúbrica:* (a) satisface la interfaz `context.Context` y funciona como sustituto;
(b) puede volcar el árbol en cualquier momento, con el estado de cada nodo; (c) al
cancelarse, registra **la causa raíz** —qué nodo se canceló primero y por qué—, que
es justo lo que el `context` estándar no te dice; (d) lo usas para depurar un
apagado real del motor de jobs y muestras el volcado; (e) comparas con
`context.Cause` de Go 1.20 🕰️, que resuelve parte de esto en la stdlib.

**D2 — El apagado con dependencias.**
Los cuatro componentes de OpsReport —servidor HTTP, motor de jobs, despachador y
pool de base de datos— tienen que apagarse **en orden topológico**, no en el orden
en que se escribieron.
*Rúbrica:* (a) declaras las dependencias entre componentes de forma explícita; (b)
el apagado las respeta y falla en compilación o en el arranque si hay un ciclo; (c)
cada componente tiene su propio plazo, y el total cabe en el plazo global; (d)
demuestras que invertir dos dependencias produce errores en el log, y cuáles; (e)
comparas con `SmartLifecycle` de Spring y con sus fases numeradas, y dices qué
prefieres.

**D3 — El presupuesto de tiempo repartido.**
Implementa la propagación de plazos con **presupuesto**: el borde HTTP concede 3 s,
y cada capa consume su parte reservando margen para las de abajo.
*Rúbrica:* (a) cada capa recibe el plazo restante y reserva un porcentaje para el
manejo de errores y la limpieza; (b) cuando el presupuesto se agota, la capa falla
**antes** de intentar la llamada, en vez de intentarla y agotar el plazo; (c) el
error dice **en qué capa** se agotó el presupuesto, que es lo que hace el incidente
diagnosticable; (d) mides el efecto bajo carga: con y sin presupuesto, cuántas
peticiones terminan en trabajo desperdiciado; (e) explicas la relación con el
patrón *deadline propagation* de los sistemas distribuidos y por qué Google lo
considera obligatorio.

---

## 📚 9. Referencias

### Documentación oficial

- **`context`** — https://pkg.go.dev/context — cortísima, y hay que leerla entera.
  La sección inicial contiene las reglas normativas del curso, incluido *"Do not
  store Contexts inside a struct type"*.
- **Go Concurrency Patterns: Context** — https://go.dev/blog/context — el artículo
  oficial que introdujo el paquete. Explica el porqué mejor que la referencia.
- **`os/signal`** — https://pkg.go.dev/os/signal — lee la sección de `Notify`
  entera: la advertencia sobre el búfer del canal está ahí y es la causa del error
  común #6.
- **`net/http.Server.Shutdown`** — https://pkg.go.dev/net/http#Server.Shutdown —
  qué espera y qué **no** espera. Los dos párrafos importan.
- **`runtime.Stack` y `NumGoroutine`** — https://pkg.go.dev/runtime
- **`net/http/pprof`** — https://pkg.go.dev/net/http/pprof — y fíjate en la
  advertencia sobre exponerlo públicamente.
- **Notas de Go 1.13: `http.NewRequestWithContext`** — https://go.dev/doc/go1.13

### Libros

- **Concurrency in Go** — Katherine Cox-Buday. El capítulo sobre *timeouts,
  cancellation and heartbeats* es exactamente esta fase, y su tratamiento de los
  *heartbeats* —cómo saber si una goroutine sigue viva— no está en ningún otro
  sitio bien explicado.
- **100 Go Mistakes** — Harsanyi. Errores #60 (`context` mal propagado), #61
  (goroutines sin parar) y #62 (`context.Value` abusado) son §7 entera.
- **Let's Go Further** — Alex Edwards. Su capítulo de *graceful shutdown* es la
  versión práctica de §6.3, con el código de un servicio real.
- **Cloud Native Go** — Matthew Titmus. Cubre el ciclo de vida en orquestadores,
  health checks y el contrato con Kubernetes, que es el contexto donde todo esto
  importa.

### Artículos y charlas

- **Go Concurrency Patterns: Context** — https://go.dev/blog/context — otra vez,
  porque es la lectura obligatoria.
- **Contexts and structs** — https://go.dev/blog/context-and-structs — **la
  autopsia de §7, escrita por el equipo de Go.** Discute honestamente las
  excepciones a la regla, incluida la de `http.Request`.
- **Pipelines and cancellation** — https://go.dev/blog/pipelines — cierra lo que
  empezamos en la Fase 06.
- **How to correctly use context.Context in Go 1.7** — Jack Lindamood. Antiguo y
  todavía la mejor guía práctica de qué meter y qué no en el contexto.
- **Graceful shutdown in Go** — busca artículos posteriores a 2020 que cubran el
  contrato con Kubernetes (`terminationGracePeriodSeconds`, `preStop`), no solo
  `srv.Shutdown`.
- **Kubernetes: Pod termination** —
  https://kubernetes.io/docs/concepts/workloads/pods/pod-lifecycle/#pod-termination
  — la secuencia exacta que tu servicio tiene que respetar, y de dónde salen los 30
  segundos.
- **goleak** — https://github.com/uber-go/goleak — léelo ahora aunque lo usemos en
  la Fase 08; el README explica qué goroutines se pueden ignorar y por qué, que es
  la parte difícil.

### Video

- **GopherCon: Understanding Context** — hay varias charlas con este título; busca
  las posteriores a 2019.
- **Rethinking Classical Concurrency Patterns** — Bryan C. Mills, GopherCon 2018.
  La parte sobre cancelación y sobre por qué "goroutine sin dueño" es un antipatrón
  es directamente esta fase.
- **Cancellation in Go** — busca las charlas de Sameer Ajmani, que diseñó el
  paquete.

> ⚠️ El material anterior a Go 1.21 no conoce `context.WithoutCancel` ni
> `context.AfterFunc`, y resuelve a mano casos que hoy tienen solución en la
> stdlib. Eso está bien para el Bloque A —es nuestra época— y hay que saberlo al
> leerlo desde el Bloque C.

### Orden de lectura sugerido

**Antes de escribir código:** *Go Concurrency Patterns: Context* y la
documentación del paquete. Media hora entre las dos.
**Durante:** *Contexts and structs* cuando llegues a la autopsia —es corto y
zanja la discusión—, y la documentación de `signal.Notify` antes de montar el
apagado.
**Después:** el capítulo de *timeouts y cancelación* de Cox-Buday, y la página de
terminación de pods de Kubernetes. Los dos convierten esta fase de "sé usar
`context`" en "sé diseñar el ciclo de vida de un servicio".

---

## ⚖️ 10. Veredicto y cierre

### ⚖️ Cuándo NO usar esto

`context` es una de las mejores decisiones de diseño de Go y tiene costes reales:

- **La verbosidad es real y no desaparece.** `ctx` como primer parámetro de todo
  ensucia cada firma, y el día que descubres que una función tres niveles abajo lo
  necesita, hay que propagarlo por las tres. Con `ThreadLocal` eso no pasa. El
  intercambio es explícito frente a implícito, y **si tu equipo valora más las
  firmas limpias que la trazabilidad de dependencias, `ThreadLocal` es una
  posición defendible** — y Java 21 la mejora con `ScopedValue`, que es inmutable y
  se propaga correctamente a las hebras virtuales.
- **La cancelación cooperativa no sirve contra código que no coopera.** Si llamas a
  una librería de terceros que no acepta `ctx`, o a cgo, o a una función de la
  stdlib sin variante contextual, **no hay forma de cancelarla**. En Java tampoco
  (`Thread.stop` está obsoleto por buenas razones), pero al menos `interrupt()`
  desbloquea las esperas de la stdlib. Esta limitación es la que más frustra en la
  práctica.
- **No hay propagación automática a goroutines hijas.** Si lanzas una goroutine y
  se te olvida pasar el contexto, esa rama del árbol se pierde en silencio. Un
  `ThreadLocal` heredable —con todos sus problemas— al menos lo intenta.
- **`context.Value` es un agujero de tipado** y no tiene defensa. Es `interface{}`
  con búsqueda lineal, y la única protección contra el abuso es la disciplina y la
  revisión de código.
- **Y en un sistema donde todo es síncrono y rápido**, montar contextos, plazos y
  apagado ordenado es ceremonia. Una herramienta de línea de comandos que procesa
  un archivo y termina no necesita nada de esto, y añadirlo "porque es buena
  práctica" es exactamente el tipo de ☕ que el curso persigue.

### 📖 Diccionario Java ⇄ Go de esta fase

| Java / Spring | Go | Dónde se rompe la equivalencia |
|---|---|---|
| `ThreadLocal` | `context.Context` (solo valores de petición) | **Explícito, no implícito**: viaja por parámetro. Si no lo pasas, se pierde. No es un sustituto general |
| `InheritableThreadLocal` | *(no existe)* | No hay herencia automática a goroutines hijas. Se pasa o no llega |
| `ScopedValue` (Java 21) | `context.WithValue` | El más parecido: inmutable y de ámbito acotado. Sigue siendo implícito en Java |
| `MDC` de Logback | identificador de petición en el contexto + logger con campos | La correlación se propaga a mano; en la Fase 14 se automatiza en el borde |
| `Thread.interrupt()` | `cancel()` / `ctx.Done()` | **Cooperativa igual**: hay que mirarla. En Go no hay `InterruptedException` que desbloquee esperas |
| `Thread.isInterrupted()` | `ctx.Err() != nil` | Idéntico en propósito |
| `InterruptedException` | `ctx.Err()` devuelto como error normal | No hay excepción que desbloquee; el código comprueba explícitamente |
| `Thread.stop()` (obsoleto) | *(no existe, y es deliberado)* | No se puede matar una goroutine desde fuera. Ninguno de los dos lenguajes lo permite hoy |
| `Future.cancel(true)` | `cancel()` del contexto pasado a la tarea | La tarea tiene que mirarlo. `cancel(true)` interrumpe; aquí solo señaliza |
| `ExecutorService.awaitTermination(t)` | `select` sobre un canal `done` y `ctx.Done()` | Se escribe; son ocho líneas y están en §6.5 |
| `@Transactional(timeout = 30)` | `context.WithTimeout` + `QueryContext` (Fase 09) | El plazo se **hereda** hacia abajo: ninguna capa interna puede prometer más que la externa |
| `HttpClient.connectTimeout` + `readTimeout` | un solo `context.WithTimeout` | **Cubre toda la operación**, no cada fase. Para plazos por fase hay que configurar el `Transport` (Fase 10) |
| `Runtime.addShutdownHook` | `signal.Notify` + apagado explícito | El gancho de Java corre al salir; aquí el apagado es código normal en `main`, y se lee |
| `@PreDestroy` | una función `Close()`/`Shutdown()` llamada desde `main` | Sin contenedor que lo invoque: el orden lo escribes tú, y por eso lo controlas |
| `SmartLifecycle` con fases | el orden de las llamadas en `main` | Explícito, sin números de fase que coordinar entre clases |
| *Graceful shutdown* de Spring Boot | `srv.Shutdown(ctx)` | Mismo comportamiento: deja de aceptar, termina lo en curso. Aquí el plazo lo pasas tú |
| `server.shutdown=graceful` + `spring.lifecycle.timeout-per-shutdown-phase` | el plazo del contexto de apagado | Un valor, en código, en vez de dos propiedades |
| `SIGTERM` de Kubernetes | `signal.Notify(c, syscall.SIGTERM)` | Idéntico. ⚠️ El canal **necesita búfer** o la señal se pierde |
| `jstack` para hilos bloqueados | perfil `goroutine` de `pprof`, o `SIGQUIT` | `debug=2` da el estado **y el tiempo bloqueado** de cada goroutine |
| Fuga de hilos | fuga de goroutines | Mismo problema, y en Go se acumulan más rápido porque crear goroutines es barato |
| `ForkJoinPool.commonPool().shutdown()` | cerrar el canal de trabajo y `wg.Wait()` | Drenar y abortar son dos operaciones distintas; hay que elegir cuál |

### Qué sigue

**Aquí termina el Bloque A.** Tienes dos servicios reales, con dominio, errores,
tests, API REST, concurrencia acotada y ciclo de vida completo — **escritos enteros
en Go 1.13, con stdlib pura, sin una sola dependencia externa.**

La Fase 08 es la frontera del curso, y es la que la hace valiosa: se migran los dos
servicios a Go moderno **sin reescribirlos**, salto por salto, con la suite de
tests como red. `embed`, `go.work`, genéricos —enseñados en serio y restringidos en
serio—, fuzzing, `log/slog`, `slices`, `errors.Join`, `context.WithoutCancel`, y el
`ServeMux` de 1.22 que jubila a tu `tiny-router`.

Y el entregable que de verdad diferencia esa fase: **la lista de rechazos con su
motivo**. Qué feature moderna se evaluó y se decidió no adoptar. Vale tanto como la
lista de adopciones, y probablemente más.

### La señal de que quedó bien

> *"Mando `SIGTERM` a mi servicio bajo carga, y en el log veo la secuencia
> completa: deja de aceptar, termina lo que tenía, devuelve a la cola lo que no le
> dio tiempo, y sale con cero. Sin peticiones cortadas, sin goroutines vivas, sin
> trabajo perdido."*

Si tu apagado todavía es un `Ctrl+C` que mata el proceso en seco, reproduce el 🧨
de §7 y cronometra. La diferencia entre 45 segundos y 100 milisegundos es
enteramente si tus funciones miran su contexto.

> 🏷️ **No cierres la fase sin el tag.** Con el checklist de la sección 2 en
> verde, `go1.13 test -race ./...` en verde, el test de fugas pasando,
> `golangci-lint run` limpio y `git status` sin cambios pendientes:
>
> ```bash
> git tag -a fase-07 -m "F7 cerrada: ctx como primer parámetro en toda E/S; cancelación de trabajos en curso; apagado ordenado con plazo en los dos servicios; entregas en vuelo devueltas a pending; tests de fuga de goroutines; cancellable-worker, timeout-client, graceful-server y leak-detector"
> git tag -a opsreport/v0.7 -m "OpsReport: cancelación y apagado ordenado"
> git tag -a eventrelay/v0.6 -m "EventRelay: plazos por entrega y apagado sin perder trabajo"
> git tag -a bloque-a-completo -m "Bloque A cerrado: dos servicios completos en Go 1.13 con stdlib pura"
> ```
>
> Ese último tag es el punto de partida de la migración: el `git diff
> bloque-a-completo fase-08` es el documento más instructivo del curso.
>
> Los commits de la fase llevan su prefijo (`fase 07: …`) y los de ejercicio su
> número (`fase 07 ej22: …`). Todo eso está en
> [`00-convencion-de-git-y-tags.md`](00-convencion-de-git-y-tags.md).

---

# 📌 Bloque de autoría (fuera de lo que lee el estudiante)

## 📌 Pendientes sugeridos

- **`context.WithoutCancel` y `context.AfterFunc`** — 🕰️ mencionados **tres veces**
  en esta fase (§6.5, §6.6, error común #2), siempre con un caso real esperándolos.
  **Verificar que el salto 1.19–1.21 de la Fase 08 los recoge y vuelve a esos tres
  sitios concretos**; si no, esta fase deja tres cabos sueltos.
- **`goleak`** — la implementación a mano de §6.4 está escrita para que la Fase 08
  la sustituya y se vea la diferencia (ignorar goroutines legítimas del runtime).
  **Confirmar que la Fase 08 lo hace explícitamente**, no solo que menciona la
  librería.
- **El tag `bloque-a-completo`** — amplía la convención original de
  `prompts/propuesta-fases-y-alcance.md` §4, que solo contemplaba `fase-NN` y los
  de proyecto. **Ya está recogido en `00-convencion-de-git-y-tags.md` §3.3**, que
  es donde manda: el `git diff` entre ese tag y `fase-08` es un entregable
  declarado de la Fase 08. Resuelto.
- **Conexiones *hijacked* / WebSockets en el apagado** — ejercicio 🔥. No hay fase
  que lo trate y probablemente no debe haberla; queda como está.
- **El contrato con Kubernetes (`terminationGracePeriodSeconds`, `preStop`)** —
  aparece en el ejercicio 23 y en las referencias. El alcance del curso llega hasta
  el `docker compose` y deja Kubernetes fuera. **Verificar que la Fase 14 menciona
  los números del periodo de gracia sin entrar en Kubernetes**, porque el plazo de
  apagado hay que justificarlo contra algo.
- **`ScopedValue` de Java 21** — está en el diccionario. Es un buen candidato para
  el duelo de la **Fase 16**, en la sección de "lo que no sale en los gráficos".

## ☕ Reflejos para `INSTINTOS.md`

- **"El `context` es un `ThreadLocal`"** — el reflejo raíz de la fase. Deriva en
  dos ☕ distintos: guardarlo en el struct y usarlo como bolsa de parámetros. Coste
  del primero: todas las peticiones fallan a partir de la segunda, y es indetectable
  en un test secuencial. Antídoto: **un contexto pertenece a una llamada, no a un
  objeto**.
- **"`ctx.Value` para pasar los datos del caso de uso"** — la firma miente, el
  compilador no verifica, y la aserción entra en panic. Prueba: si quitarlo rompe
  la lógica, era un parámetro.
- **"Pasar `r.Context()` al trabajo de fondo"** — el trabajo muere cuando termina
  la respuesta, de forma intermitente.
- **"Reutilizar el contexto vencido para la limpieza"** — el sistema deja de poder
  registrar por qué está fallando, justo cuando falla.
- **"El apagado ordenado lo hace el `main`"** — lo hace cada función que mira su
  contexto. Coste medido en el 🧨: 45 s y `SIGKILL` frente a 100 ms.
- **"Claves de contexto como `string`"** — colisionan entre paquetes.

## 📐 Mediciones para `BENCHMARKS.md`

Esta fase no produce entradas nuevas, y deja dos propuestas:

- **Sin ID — Latencia de apagado frente a granularidad de fragmento.** Sale del
  ejercicio 19 y del 🧨: el tamaño del fragmento determina cuánto tarda el apagado.
  Es un dato **accionable** (permite calcular el periodo de gracia necesario) y
  barato de medir. **Propuesta: encajarlo como sección de la entrada B-20 de la
  Fase 13**, que ya mide tamaño de fragmento frente a tiempo total del cierre —
  serían dos ejes de la misma decisión.
- **Coste de `ctx.Value` por profundidad del árbol — resuelto sin medir.** La
  búsqueda lineal se mencionaba en §4 con un *"con veinte valores en un camino
  caliente, se nota"* que era una afirmación de rendimiento sin entrada en
  `BENCHMARKS.md`. **Se suavizó a lo estructural**: §4 ahora describe el mecanismo
  —cada `WithValue` envuelve al anterior y `Value` recorre la cadena— y dice
  explícitamente que el curso no ha medido el coste. Es la segunda salida que
  admite `prompts/formato-de-benchmarks.md`, y la correcta aquí: el argumento
  contra meter datos de negocio en el contexto es de diseño, no de nanosegundos, y
  darle un número lo debilitaría.
