# 🌐 Fase 05 — HTTP y REST con la stdlib

> Go para desarrolladores Java senior · Fase 5 de 17 · **8 horas**
> Época: **Go 1.13 (stdlib pura)**
> Depende de: Fase 04 · Habilita: Fase 06
> Proyectos que avanzan: **OpsReport** y **EventRelay** (APIs REST en memoria) · nace `fakeconsumer`
> Mini proyectos: `tiny-router`, `middleware-chain`, `httptest-lab`

---

## 🎯 1. Propósito

Los dos servicios tienen dominio, servicio, errores, configuración y tests. Les
falta lo único que los hace servicios: **hablar HTTP**.

Y aquí la época de 1.13 nos hace un regalo que no buscábamos. El `ServeMux` de
2019 no sabe de métodos ni de variables de ruta, así que **el enrutado lo vas a
escribir tú**. Es media hora de trabajo y produce el descubrimiento más liberador
del Bloque A: `@GetMapping("/work-items/{id}")` es un `switch` sobre el método y un
corte de cadena. Nada más. Todo lo que Spring MVC hace por encima de eso —
negociación de contenido, conversión de tipos, validación declarativa— es
comodidad construida sobre esas dos operaciones.

Al terminar, OpsReport y EventRelay tienen API REST completa y probada, y dejas de
tenerle respeto reverencial a una anotación.

---

## ✅ 2. Qué queda listo al terminar

- [ ] OpsReport expone `/work-items` (GET, POST), `/work-items/{id}` (GET, DELETE),
      `/work-items/{id}/start`, `/health` y `/ready`.
- [ ] EventRelay expone `/endpoints`, `/events`, `/deliveries` y sus
      subrecursos, con la misma forma.
- [ ] Los errores del dominio se traducen a códigos HTTP **en una sola función**,
      apoyada en `errors.Is`/`errors.As` de la Fase 03.
- [ ] La cadena de middleware está montada: identificador de petición, registro,
      recuperación de panic y límite de tamaño del cuerpo.
- [ ] `http.Server` se construye con **los cuatro tiempos de espera** puestos, y
      sabes qué ataque previene cada uno.
- [ ] Las dos APIs tienen suite HTTP completa con `httptest.NewRecorder`.
- [ ] `fakeconsumer` existe como segundo binario de EventRelay, con `/ok`,
      `/slow` y `/fail/{code}`.
- [ ] `go1.13 test -race ./...` en verde y la cobertura sigue sobre el umbral.

---

## 🚫 3. Qué NO entra todavía

- **`ServeMux` con método y patrón de ruta** → Fase 08 🕰️ (Go 1.22). El
  `tiny-router` que escribes hoy **se guarda** para ponerlos lado a lado allí, y esa
  comparación es la mejor clase de diseño de API del curso.
- Cliente HTTP (`http.Client`, reintentos, timeouts de salida) → Fase 10. Hoy solo
  servimos; `fakeconsumer` existe para que en la Fase 06 haya algo a lo que llamar.
- Concurrencia explícita → Fase 06. **Ojo:** `net/http` ya lanza una goroutine por
  petición, así que la concurrencia está aquí aunque no la escribas — y por eso el
  `memstore` de la Fase 02 va a dar problemas. Está previsto y se resuelve allí. 💸
- `context` para cancelación → Fase 07. Aquí tocamos `r.Context()` lo mínimo y se
  dice que está incompleto.
- Autenticación real → **fuera del curso**. Los servicios de Meridian viven tras un
  gateway que ya autenticó; el middleware de esta fase solo verifica una cabecera
  interna, y se dice explícitamente que eso no es seguridad.
- Logging estructurado → Fase 14. El middleware de registro usa `log.Printf`. 💸
- Métricas y trazas → Fase 14.

---

## 🧠 4. Concepto mínimo

### Dos tipos, y ya está

```go
type Handler interface {
	ServeHTTP(ResponseWriter, *Request)
}

type HandlerFunc func(ResponseWriter, *Request)

func (f HandlerFunc) ServeHTTP(w ResponseWriter, r *Request) { f(w, r) }
```

Todo `net/http` gira alrededor de esto. Un handler es cualquier cosa con
`ServeHTTP`; `HandlerFunc` adapta una función suelta a la interfaz — es el mismo
truco de `NotifierFunc` de la Fase 02, y ahora ves de dónde venía.

```go
func handleHealth(w http.ResponseWriter, r *http.Request) {
	w.WriteHeader(http.StatusOK)
	w.Write([]byte(`{"status":"ok"}`))
}

http.Handle("/health", http.HandlerFunc(handleHealth))
```

📖 El paralelo exacto es `javax.servlet.Servlet.service(req, resp)`, y la
diferencia es que **aquí no hay contenedor de servlets**: el servidor HTTP es una
librería que importas, no un entorno donde tu código se despliega. Eso tiene
consecuencias que se notan enseguida: el ciclo de vida lo controlas tú, no hay
`web.xml`, no hay `DispatcherServlet` que decida por ti, y `main` arranca y para
el servidor como cualquier otra cosa.

### `ResponseWriter` y el orden que no se puede romper

```go
w.Header().Set("Content-Type", "application/json")  // 1º cabeceras
w.WriteHeader(http.StatusCreated)                   // 2º código de estado
json.NewEncoder(w).Encode(payload)                  // 3º cuerpo
```

**Ese orden es obligatorio y no hay forma de deshacerlo.** En cuanto llamas a
`WriteHeader` —o a `Write`, que llama a `WriteHeader(200)` implícitamente— las
cabeceras salieron por el cable. Un `w.Header().Set(...)` posterior no hace nada y
**no da error**: simplemente se ignora.

```go
// ❌ El bug silencioso más común de net/http
func handleBroken(w http.ResponseWriter, r *http.Request) {
	if err := json.NewEncoder(w).Encode(result); err != nil {
		// Demasiado tarde: el 200 ya salió con los primeros bytes del cuerpo.
		w.WriteHeader(http.StatusInternalServerError)  // ignorado
		return
	}
}
```

Vas a ver `superfluous response.WriteHeader call` en el log cuando pase. **Ese
mensaje es la pista de que tu handler escribió dos veces.**

> 🧭 **Regla del proyecto.** Un handler decide el código de estado **antes** de
> escribir un solo byte. Si la serialización puede fallar y quieres poder
> responder con un error, serializa a un buffer primero y escribe después. Para
> respuestas pequeñas eso es gratis; para un reporte de 500.000 filas, no — y esa
> tensión la resolvemos en la Fase 13 con streaming, aceptando que un fallo a
> mitad de la respuesta ya no se puede convertir en un 500.

### 🪞 Tu instinto de Java dice… y esta vez se equivoca

**El instinto:** *"lo primero es elegir el framework web"*. En Java es una
decisión real y con consecuencias: Spring MVC, WebFlux, Quarkus, Micronaut,
Jakarta REST. Cada uno trae su modelo de programación, su ciclo de vida y su forma
de hacer las cosas.

**Qué pasa si lo aplicas aquí:** buscas "best go web framework", encuentras Gin,
Echo, Fiber y Chi, lees cinco comparativas de rendimiento, eliges uno, y **te
pierdes la lección entera**. Porque en Go los frameworks web son delgados: casi
todos son enrutadores con azúcar encima de `net/http`, y todos aceptan
`http.Handler`. Elegir framework aquí no es como elegir entre Spring y Quarkus; es
como elegir entre dos librerías de enrutado.

Y la consecuencia práctica que te duele cuando te la saltas: **no entiendes qué
hace tu framework porque nunca escribiste lo que él hace.**

**Qué pensar en su lugar:** `net/http` es el framework. Lo que un enrutador de
terceros añade es sintaxis para lo que hoy vas a escribir a mano en cuarenta
líneas. Escríbelo una vez, mídelo, y después elige con criterio — que es
exactamente lo que haremos en la Fase 08 comparando tu `tiny-router` con el
`ServeMux` de 1.22, y lo que la propuesta del curso hace con `chi`.

> 📝 **Nota de época.** El `ServeMux` de 1.13 solo hace *prefix matching*: un
> patrón que acaba en `/` casa con todo lo que empiece así, y uno que no, casa
> exacto. **No mira el método HTTP y no extrae variables de ruta.** En Go 1.22 el
> `ServeMux` aprendió las dos cosas (`mux.HandleFunc("GET /work-items/{id}", h)`),
> y eso jubila a la mayoría de los enrutadores de terceros para APIs sencillas. 🕰️

### El enrutado, desmitificado

Esto es lo que `@GetMapping("/work-items/{id}")` hace por debajo:

```go
func (h *Handler) ServeHTTP(w http.ResponseWriter, r *http.Request) {
	// 1. Quitar el prefijo y quedarse con lo que sobra.
	rest := strings.TrimPrefix(r.URL.Path, "/work-items")
	rest = strings.Trim(rest, "/")

	switch {
	case rest == "":
		// 2. Despachar por método.
		switch r.Method {
		case http.MethodGet:
			h.list(w, r)
		case http.MethodPost:
			h.create(w, r)
		default:
			methodNotAllowed(w, http.MethodGet, http.MethodPost)
		}

	default:
		// 3. Lo que sobra es el identificador, con posible subrecurso.
		parts := strings.Split(rest, "/")
		id := parts[0]

		if len(parts) == 2 && parts[1] == "start" && r.Method == http.MethodPost {
			h.start(w, r, id)
			return
		}
		// ...
	}
}
```

Un `TrimPrefix`, un `Split` y dos `switch`. **Eso es todo.** Spring MVC hace lo
mismo con un árbol de patrones compilados y una tabla de despacho, y le añade
conversión de tipos, negociación de contenido, resolución de argumentos por
reflexión y un modelo de excepciones. Todo eso es trabajo real y útil; lo que no
es, es magia.

### 🩻 Esto sí funciona igual

- **REST es REST.** Los códigos de estado, los verbos, los recursos anidados, la
  idempotencia de `PUT` frente a `POST` — todo tu criterio de diseño de API se
  traslada intacto. Esta fase no te enseña REST, te enseña a servirlo.
- **Middleware es middleware.** Un `Filter` de servlet y un middleware de Go
  resuelven el mismo problema con el mismo patrón de envoltura. El orden importa
  igual, y por las mismas razones.
- **La separación handler / servicio / dominio** es la misma arquitectura. El
  handler decodifica, llama y codifica; la lógica no vive ahí. Igual que en
  Spring 🩻.
- **Validar en el borde** sigue siendo correcto, y sigue sin sustituir a la
  validación del dominio.
- **Los tiempos de espera de un servidor HTTP** son la misma preocupación que
  configuras en Tomcat (`connectionTimeout`, `maxKeepAliveRequests`). Aquí los
  campos tienen otro nombre y **ninguno tiene valor por defecto**, que es la única
  diferencia importante.
- **`Content-Type` y la negociación** funcionan igual; simplemente no hay nadie que
  la haga por ti.

---

## 🛠️ 5. CLI de la fase

```bash
# Levantar el servicio y golpearlo. curl es la herramienta de esta fase.
go1.13 run ./cmd/opsreport &

# -i muestra la respuesta con sus cabeceras: el código de estado y el
# Content-Type son la mitad de lo que hay que verificar en una API.
curl -i localhost:8080/health

# -X elige el método; -d manda cuerpo; -H pone cabeceras.
curl -i -X POST localhost:8080/work-items \
  -H 'Content-Type: application/json' \
  -d '{"external_reference":"SAP-2026-000123","kind":"import","priority":3}'

# -s silencia la barra de progreso; combinado con jq, es cómo se lee una API.
curl -s localhost:8080/work-items | jq '.items[] | {id, status, priority}'

# -w imprime métricas de la petición. time_total es la latencia de punta a punta
# e incluye la resolución DNS y el handshake: útil para un primer olfateo.
curl -s -o /dev/null -w 'status=%{http_code} tiempo=%{time_total}s\n' \
  localhost:8080/work-items

# --max-time aborta desde el cliente. Es cómo se comprueba que un endpoint lento
# no cuelga a quien lo llama... y también cómo se descubre que tu servidor no
# tiene timeouts.
curl --max-time 2 localhost:8080/slow

# Ver el tráfico real, incluidas las cabeceras que Go añade solo.
curl -v localhost:8080/work-items/WI-0001

# TESTS de esta fase: los handlers se prueban sin abrir un puerto.
go1.13 test ./internal/httpapi -v

# -httptest.serve levanta el servidor de prueba en un puerto real, para poder
# golpearlo con curl mientras el test corre. Poco conocido y muy útil para
# depurar un test HTTP que falla y no entiendes.
go1.13 test -run TestWorkItemsAPI -httptest.serve=localhost:9090 ./internal/httpapi

# La documentación que más vas a consultar esta fase.
go1.13 doc net/http Server
go1.13 doc net/http ResponseWriter
go1.13 doc net/http/httptest NewRecorder
go1.13 doc net/http StatusText

# Y el truco para ver todos los códigos de estado con su constante:
go1.13 doc net/http | grep 'Status[A-Z]'
```

> 💡 **`http.StatusCreated` en vez de `201`.** Las constantes de `net/http` existen
> y se usan siempre: se leen mejor, el editor las autocompleta, y
> `http.StatusText(code)` te da el texto canónico si lo necesitas. Un `201`
> literal en un handler es de las pocas cosas que un revisor de Go va a marcar sin
> dudarlo.

---

## 💻 6. Construcción guiada

### 6.1 Mini proyecto: `tiny-router`

El enrutador que en la Fase 08 va a morir con dignidad. Lo escribimos completo
porque su valor está en haberlo escrito.

```go
// labs/tiny-router/router.go

// Package router implementa el enrutado mínimo que la stdlib de Go 1.13 no trae:
// despacho por método HTTP y extracción de variables de ruta.
//
// Existe para dos cosas: para que OpsReport y EventRelay tengan API en el Bloque
// A, y para compararlo con el ServeMux de Go 1.22 en la Fase 08. 🕰️
package router

import (
	"net/http"
	"strings"
)

// Params son las variables extraídas de la ruta: {id} → params["id"].
type Params map[string]string

// HandlerFunc es un handler que además recibe las variables de ruta.
//
// Nota de diseño: el ServeMux de 1.22 resuelve esto con r.PathValue("id"),
// guardando los valores DENTRO de la petición. Esa decisión es mejor —no cambia
// la firma del handler, así que cualquier http.Handler sigue sirviendo— y la
// comparación está en la Fase 08.
type HandlerFunc func(w http.ResponseWriter, r *http.Request, p Params)

// route es un patrón compilado. Los segmentos que empiezan por ':' son variables.
type route struct {
	method   string
	segments []string
	handler  HandlerFunc
}

// Router despacha peticiones por método y patrón.
// NO es seguro para registrar rutas concurrentemente: todas las rutas se
// registran en el arranque, antes de servir. Documentarlo evita la pregunta.
type Router struct {
	routes   []route
	notFound http.Handler
}

func New() *Router {
	return &Router{
		notFound: http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
			http.Error(w, `{"error":"recurso no encontrado"}`, http.StatusNotFound)
		}),
	}
}

// Handle registra un patrón. Los segmentos con ':' son variables:
//
//	r.Handle(http.MethodGet, "/work-items/:id", h.get)
func (rt *Router) Handle(method, pattern string, h HandlerFunc) {
	rt.routes = append(rt.routes, route{
		method:   method,
		segments: splitPath(pattern),
		handler:  h,
	})
}

// Atajos por método, que es lo que vas a usar de verdad.
func (rt *Router) GET(p string, h HandlerFunc)    { rt.Handle(http.MethodGet, p, h) }
func (rt *Router) POST(p string, h HandlerFunc)   { rt.Handle(http.MethodPost, p, h) }
func (rt *Router) DELETE(p string, h HandlerFunc) { rt.Handle(http.MethodDelete, p, h) }

// ServeHTTP hace del Router un http.Handler, así que se puede envolver en
// middleware y pasar a http.Server como cualquier otro.
func (rt *Router) ServeHTTP(w http.ResponseWriter, r *http.Request) {
	segments := splitPath(r.URL.Path)

	// methodMismatch recuerda si algún patrón casó por ruta pero no por método:
	// es la diferencia entre responder 404 y responder 405, y casi todo el mundo
	// la ignora.
	var allowed []string

	for _, rte := range rt.routes {
		params, ok := match(rte.segments, segments)
		if !ok {
			continue
		}
		if rte.method != r.Method {
			allowed = append(allowed, rte.method)
			continue
		}
		rte.handler(w, r, params)
		return
	}

	if len(allowed) > 0 {
		// 405 con la cabecera Allow, que el RFC exige y casi nadie manda.
		w.Header().Set("Allow", strings.Join(allowed, ", "))
		http.Error(w, `{"error":"método no permitido"}`, http.StatusMethodNotAllowed)
		return
	}

	rt.notFound.ServeHTTP(w, r)
}

// splitPath parte una ruta en segmentos no vacíos. "/work-items/WI-1/" produce
// ["work-items", "WI-1"], que es lo que hace que la barra final sea irrelevante.
func splitPath(p string) []string {
	trimmed := strings.Trim(p, "/")
	if trimmed == "" {
		return nil
	}
	return strings.Split(trimmed, "/")
}

// match compara un patrón con una ruta concreta y extrae las variables.
func match(pattern, path []string) (Params, bool) {
	if len(pattern) != len(path) {
		return nil, false
	}

	var params Params
	for i, seg := range pattern {
		if strings.HasPrefix(seg, ":") {
			if params == nil {
				// El mapa se crea solo si hay variables: la mayoría de las rutas
				// no las tiene y así no se asigna nada.
				params = make(Params, 2)
			}
			params[seg[1:]] = path[i]
			continue
		}
		if seg != path[i] {
			return nil, false
		}
	}
	return params, true
}
```

Sesenta líneas útiles. Y ya tienes lo que `@GetMapping`, `@PostMapping` y
`@PathVariable` te daban, menos la conversión automática de tipos.

> 🧪 **Prueba de fuego.** Registra `/work-items/:id` y pide `/work-items/`. El
> `splitPath` con `Trim` hace que la barra final no importe y casa con
> `/work-items`. Ahora pide `/work-items/WI-1/extra`: no casa, y responde 404.
> **La mentira de la pantalla:** este enrutador recorre las rutas en orden y
> devuelve la **primera** que casa. Con veinte rutas eso es lineal y no importa;
> con doscientas, y en el camino caliente, sí. El `ServeMux` de 1.22 usa un árbol
> de patrones con precedencia definida. Es exactamente la clase de diferencia que
> se mide antes de opinar (B-12, Fase 08).

> 💸 **Deuda técnica intencional.** Este enrutador tiene tres limitaciones
> conocidas: búsqueda lineal, sin comodines de cola (`/files/*path`), y el
> `switch` de despacho crece feo cuando hay subrecursos anidados. **Se paga en la
> Fase 08**, donde el `ServeMux` de 1.22 lo sustituye y ponemos las dos versiones
> lado a lado. Esa comparación es la mejor clase de diseño de API del curso — que
> quede dicho aquí para que la esperes.

### 6.2 Mini proyecto: `middleware-chain`

Un middleware en Go es **una función que recibe un handler y devuelve otro**. Esa
es toda la definición:

```go
// labs/middleware-chain/middleware.go
package middleware

import (
	"log"
	"net/http"
	"strconv"
	"sync/atomic"
	"time"
)

// Middleware envuelve un handler con comportamiento adicional.
type Middleware func(http.Handler) http.Handler

// Chain compone middlewares de forma que el PRIMERO de la lista es el más
// externo — es decir, el primero en ver la petición y el último en ver la
// respuesta. Ese orden es el que la gente espera y hay que fijarlo.
func Chain(h http.Handler, mws ...Middleware) http.Handler {
	for i := len(mws) - 1; i >= 0; i-- {
		h = mws[i](h)
	}
	return h
}
```

Y los cuatro que los dos servicios van a usar:

```go
// RequestID asigna un identificador a cada petición y lo devuelve en la
// respuesta. Es la pieza que hace posible correlacionar un log con un incidente
// reportado por un socio.
//
// El identificador se guarda en el contexto de la petición, que es el mecanismo
// correcto — pero el contexto es la Fase 07 y aquí lo usamos con lo mínimo
// explicado. Que conste que r.Context() NO es un ThreadLocal.  💸
func RequestID(next http.Handler) http.Handler {
	var counter uint64

	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		id := r.Header.Get("X-Request-ID")
		if id == "" {
			// atomic porque net/http lanza una goroutine por petición: este
			// contador lo tocan varias a la vez. La explicación completa es de
			// la Fase 06; el hecho es de hoy.
			n := atomic.AddUint64(&counter, 1)
			id = "req-" + strconv.FormatUint(n, 10)
		}

		w.Header().Set("X-Request-ID", id)
		ctx := context.WithValue(r.Context(), requestIDKey{}, id)
		next.ServeHTTP(w, r.WithContext(ctx))
	})
}

// requestIDKey es un tipo NO EXPORTADO usado como clave del contexto.
// Usar un string como clave permite que otro paquete pise tu valor sin querer;
// un tipo privado lo hace imposible. Es la convención del ecosistema.
type requestIDKey struct{}

func RequestIDFrom(ctx context.Context) string {
	id, _ := ctx.Value(requestIDKey{}).(string)
	return id
}

// statusRecorder envuelve el ResponseWriter para capturar el código de estado,
// que de otro modo se pierde: ResponseWriter no tiene forma de consultarlo.
type statusRecorder struct {
	http.ResponseWriter
	status int
	bytes  int
}

func (r *statusRecorder) WriteHeader(code int) {
	r.status = code
	r.ResponseWriter.WriteHeader(code)
}

func (r *statusRecorder) Write(b []byte) (int, error) {
	if r.status == 0 {
		// Write sin WriteHeader previo implica 200. Hay que registrarlo o el log
		// dirá 0 en todas las respuestas exitosas.
		r.status = http.StatusOK
	}
	n, err := r.ResponseWriter.Write(b)
	r.bytes += n
	return n, err
}

// Logging registra método, ruta, estado, tamaño y duración.
// El formato es libre y provisional: en la Fase 14 esto se convierte en slog con
// campos estructurados, y allí se comparan las dos salidas.  💸
func Logging(next http.Handler) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		start := time.Now()
		rec := &statusRecorder{ResponseWriter: w}

		next.ServeHTTP(rec, r)

		log.Printf("%s %s %s %d %dB %s",
			RequestIDFrom(r.Context()), r.Method, r.URL.Path,
			rec.status, rec.bytes, time.Since(start).Round(time.Microsecond))
	})
}

// Recover convierte un panic en un 500 en vez de dejar que tumbe la conexión.
//
// net/http YA recupera los panics de sus handlers y cierra la conexión sin
// respuesta; este middleware existe para (a) responder un 500 con cuerpo JSON
// como el resto de la API, y (b) registrar la pila donde nuestro log la vea.
func Recover(next http.Handler) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		defer func() {
			if rec := recover(); rec != nil {
				// La pila es lo único que hace útil este log. Sin ella, "panic:
				// runtime error" no te dice nada.
				log.Printf("%s PANIC %s %s: %v\n%s",
					RequestIDFrom(r.Context()), r.Method, r.URL.Path,
					rec, debug.Stack())

				// Ojo: si el handler ya escribió la cabecera, esto no hace nada
				// y se registra un "superfluous WriteHeader". Es aceptable: la
				// alternativa sería bufferizar toda respuesta, y no compensa.
				http.Error(w, `{"error":"error interno"}`, http.StatusInternalServerError)
			}
		}()
		next.ServeHTTP(w, r)
	})
}

// MaxBodyBytes limita el tamaño del cuerpo que el servidor acepta leer.
//
// Sin esto, un cliente puede mandar un cuerpo de diez gigas y tu servidor lo
// leerá hasta quedarse sin memoria. No es una validación de negocio: es una
// defensa, y va en el middleware, no en el handler.
func MaxBodyBytes(limit int64) Middleware {
	return func(next http.Handler) http.Handler {
		return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
			r.Body = http.MaxBytesReader(w, r.Body, limit)
			next.ServeHTTP(w, r)
		})
	}
}
```

Y el montaje, que se lee de arriba abajo:

```go
handler := middleware.Chain(
	router,
	middleware.RequestID,              // 1º: todos los de abajo tienen el ID
	middleware.Logging,                // 2º: registra lo que pase dentro
	middleware.Recover,                // 3º: un panic ya queda registrado arriba
	middleware.MaxBodyBytes(1<<20),    // 4º: límite justo antes del handler
)
```

> ⚠️ **El orden no es decorativo.** `Recover` después de `Logging` significa que
> un panic queda registrado con su duración y su estado 500. Al revés, el panic
> saltaría por encima del logging y no habría línea de log. Lo mismo con
> `RequestID`: si no es el primero, los middlewares de arriba registran con ID
> vacío. **En una revisión de código, el orden de la cadena se revisa como
> código.**

📖 En Spring esto son `Filter` (nivel de servlet) y `HandlerInterceptor` (nivel de
Spring MVC), registrados en `WebMvcConfigurer` con un `@Order`. El modelo mental
es el mismo; lo que cambia es que aquí **el orden es el de las líneas** en vez de
un número que hay que buscar en tres clases distintas.

### 6.3 La traducción de errores: un solo sitio

Esta es la pieza que hace que la política de errores de la Fase 03 rinda.

```go
// services/opsreport/internal/httpapi/errors.go
package httpapi

import (
	"encoding/json"
	"errors"
	"log"
	"net/http"

	"github.com/meridian/opsreport/internal/opsreport"
	"github.com/meridian/opsreport/internal/workitem"
)

// errorBody es el cuerpo de error de la API. Un solo formato para todos los
// errores del servicio, porque un cliente que tiene que manejar tres formas
// distintas de error acaba parseando mensajes.
type errorBody struct {
	Error   string       `json:"error"`
	Code    string       `json:"code"`
	Fields  []fieldError `json:"fields,omitempty"`
	Request string       `json:"request_id,omitempty"`
}

type fieldError struct {
	Field  string `json:"field"`
	Reason string `json:"reason"`
}

// writeError traduce CUALQUIER error del dominio o del servicio a una respuesta
// HTTP. Es la única función del paquete que decide códigos de estado, y esa
// concentración es deliberada: la alternativa es que cada handler invente el
// suyo y que un día `not found` responda 404 en un endpoint y 500 en otro.
func writeError(w http.ResponseWriter, r *http.Request, err error) {
	status, body := classify(err)
	body.Request = middleware.RequestIDFrom(r.Context())

	// Los 5xx se registran con el error completo; los 4xx no, porque un cliente
	// mandando basura no es un incidente y llenaría el log.
	if status >= http.StatusInternalServerError {
		log.Printf("%s ERROR %s %s: %v", body.Request, r.Method, r.URL.Path, err)
	}

	writeJSON(w, status, body)
}

func classify(err error) (int, errorBody) {
	// El orden importa: de lo más específico a lo más general.
	var verr *workitem.ValidationError
	if errors.As(err, &verr) {
		fields := make([]fieldError, 0, len(verr.Fields))
		for _, f := range verr.Fields {
			fields = append(fields, fieldError{Field: f.Field, Reason: f.Reason})
		}
		return http.StatusUnprocessableEntity, errorBody{
			Error:  "la petición tiene campos inválidos",
			Code:   "validation_failed",
			Fields: fields,
		}
	}

	switch {
	case errors.Is(err, opsreport.ErrNotFound):
		return http.StatusNotFound, errorBody{
			Error: "el recurso no existe", Code: "not_found",
		}

	case errors.Is(err, opsreport.ErrConflict):
		// 409 y no 400: la petición es correcta, el estado del recurso no la
		// permite. La diferencia importa para un cliente que reintenta.
		return http.StatusConflict, errorBody{
			Error: "el estado actual del recurso no permite esta operación",
			Code:  "conflict",
		}

	case errors.Is(err, errBadJSON):
		return http.StatusBadRequest, errorBody{
			Error: "el cuerpo de la petición no es json válido", Code: "bad_request",
		}

	case errors.Is(err, errBodyTooLarge):
		return http.StatusRequestEntityTooLarge, errorBody{
			Error: "el cuerpo de la petición supera el límite", Code: "payload_too_large",
		}

	default:
		// Nunca se expone el error interno al cliente: puede llevar nombres de
		// tabla, rutas de archivo o cadenas de conexión. Va al log y punto.
		return http.StatusInternalServerError, errorBody{
			Error: "error interno", Code: "internal",
		}
	}
}

func writeJSON(w http.ResponseWriter, status int, payload interface{}) {
	// El orden obligatorio: cabeceras, estado, cuerpo.
	w.Header().Set("Content-Type", "application/json; charset=utf-8")
	w.WriteHeader(status)

	if payload == nil {
		return
	}
	if err := json.NewEncoder(w).Encode(payload); err != nil {
		// Aquí ya no se puede cambiar el código de estado. Solo queda registrar.
		log.Printf("no se pudo escribir la respuesta: %v", err)
	}
}
```

> 🧭 **Regla del proyecto.** Los códigos de estado se deciden **en un solo
> archivo**. Ningún handler escribe un `http.StatusNotFound` a mano: devuelve el
> error del dominio y `writeError` lo traduce. Cuando en la Fase 09 aparezcan
> errores de PostgreSQL, se añade un caso aquí y toda la API se comporta
> consistentemente.

📖 El equivalente es `@ControllerAdvice` con `@ExceptionHandler`, y el paralelo es
bueno con una diferencia importante: `@ControllerAdvice` captura **cualquier**
excepción que suba, incluidas las que ningún desarrollador previó. `writeError`
solo ve lo que el handler le pasa; un error tragado en el camino no llega. A
cambio, aquí no hay ningún orden de resolución que consultar en la documentación.

### 6.4 Los handlers de OpsReport

```go
// services/opsreport/internal/httpapi/workitems.go
package httpapi

import (
	"encoding/json"
	"errors"
	"net/http"
	"strconv"

	"github.com/meridian/opsreport/internal/router"
	"github.com/meridian/opsreport/internal/workitem"
)

// WorkItemService es lo que estos handlers necesitan del servicio.
//
// Se declara AQUÍ, en el consumidor, y tiene cuatro métodos porque se usan
// cuatro. El opsreport.Service concreto tiene más, y a este paquete no le
// importan. Es la regla de la Fase 02 aplicada donde más se nota.
type WorkItemService interface {
	Create(item workitem.WorkItem) (workitem.WorkItem, error)
	Get(id string) (workitem.WorkItem, error)
	Start(id string) (workitem.WorkItem, error)
	Cancel(id string) (workitem.WorkItem, error)
	Queue() ([]workitem.WorkItem, error)
}

type WorkItemHandler struct {
	svc WorkItemService
}

func NewWorkItemHandler(svc WorkItemService) *WorkItemHandler {
	return &WorkItemHandler{svc: svc}
}

// Register monta las rutas del recurso. Que el handler registre sus propias
// rutas mantiene juntos el patrón y el método que lo sirve.
func (h *WorkItemHandler) Register(r *router.Router) {
	r.POST("/work-items", h.create)
	r.GET("/work-items", h.list)
	r.GET("/work-items/:id", h.get)
	r.POST("/work-items/:id/start", h.start)
	r.DELETE("/work-items/:id", h.cancel)
}

// createRequest es la representación de entrada. Es un tipo APARTE del dominio y
// se justifica: el cliente no puede mandar ID, Status ni CreatedAt, y tenerlos
// fuera del struct hace imposible que alguien los acepte por descuido.
type createRequest struct {
	ExternalReference string `json:"external_reference"`
	Kind              string `json:"kind"`
	Description       string `json:"description"`
	Priority          int    `json:"priority"`
}

var (
	errBadJSON      = errors.New("json inválido en el cuerpo")
	errBodyTooLarge = errors.New("el cuerpo supera el límite")
)

func (h *WorkItemHandler) create(w http.ResponseWriter, r *http.Request, _ router.Params) {
	var req createRequest

	dec := json.NewDecoder(r.Body)
	// DisallowUnknownFields rechaza campos que no existen en el struct. Es una
	// decisión con matices: protege contra erratas del cliente ("prioriti") y a
	// cambio rompe la compatibilidad hacia adelante — un cliente nuevo que manda
	// un campo que esta versión no conoce recibe un 400.
	//
	// Para una API interna entre equipos de Meridian, la protección gana.
	// Para una API pública con muchos clientes, normalmente no.
	dec.DisallowUnknownFields()

	if err := dec.Decode(&req); err != nil {
		var maxErr *http.MaxBytesError // 🕰️ no existe en 1.13; ver nota abajo
		_ = maxErr
		writeError(w, r, decodeError(err))
		return
	}

	item, err := h.svc.Create(workitem.WorkItem{
		ExternalReference: req.ExternalReference,
		Kind:              workitem.Kind(req.Kind),
		Description:       req.Description,
		Priority:          workitem.Priority(req.Priority),
	})
	if err != nil {
		writeError(w, r, err)
		return
	}

	// 201 con Location, que es lo que un cliente REST espera y casi nadie manda.
	w.Header().Set("Location", "/work-items/"+item.ID)
	writeJSON(w, http.StatusCreated, toJSON(item, h.now()))
}

func (h *WorkItemHandler) get(w http.ResponseWriter, r *http.Request, p router.Params) {
	item, err := h.svc.Get(p["id"])
	if err != nil {
		writeError(w, r, err)
		return
	}
	writeJSON(w, http.StatusOK, toJSON(item, h.now()))
}

func (h *WorkItemHandler) list(w http.ResponseWriter, r *http.Request, _ router.Params) {
	items, err := h.svc.Queue()
	if err != nil {
		writeError(w, r, err)
		return
	}

	// El filtro de estado llega como query param. Convertirlo es trabajo del
	// handler: el servicio recibe tipos del dominio, no strings de la URL.
	if raw := r.URL.Query().Get("status"); raw != "" {
		items = filterByStatus(items, workitem.Status(raw))
	}

	// La respuesta va ENVUELTA en un objeto, no como array desnudo. Un array de
	// primer nivel no se puede extender con metadatos (paginación, totales) sin
	// romper a los clientes, y la paginación llega en la Fase 09.
	writeJSON(w, http.StatusOK, listResponse{
		Items: toJSONList(items, h.now()),
		Count: len(items),
	})
}

func (h *WorkItemHandler) start(w http.ResponseWriter, r *http.Request, p router.Params) {
	item, err := h.svc.Start(p["id"])
	if err != nil {
		writeError(w, r, err)
		return
	}
	writeJSON(w, http.StatusOK, toJSON(item, h.now()))
}

func (h *WorkItemHandler) cancel(w http.ResponseWriter, r *http.Request, p router.Params) {
	item, err := h.svc.Cancel(p["id"])
	if err != nil {
		writeError(w, r, err)
		return
	}
	writeJSON(w, http.StatusOK, toJSON(item, h.now()))
}
```

> 📝 **Nota de época sobre `MaxBytesReader`.** En Go 1.13, cuando el cuerpo supera
> el límite, `Read` devuelve un error cuyo mensaje es `"http: request body too
> large"` y **no hay un tipo para comprobarlo**: hay que comparar el texto, que es
> justo lo que este curso desaconseja. `http.MaxBytesError` llegó en Go 1.19 🕰️ y
> lo arregla. Mientras tanto, la comparación por texto va encapsulada en
> `decodeError` con un comentario que dice que es un parche de época — y en la Fase
> 08 se sustituye. Es un buen ejemplo de que **leer código de 2019 requiere saber
> qué no existía**.

### 6.5 El servidor: los cuatro tiempos de espera

```go
// services/opsreport/cmd/opsreport/main.go
package main

func main() {
	cfg, err := config.Load(os.Getenv("MERIDIAN_CONFIG"))
	if err != nil {
		// Fallo rápido: la configuración se valida entera antes de abrir nada.
		fmt.Fprintln(os.Stderr, err)
		os.Exit(1)
	}
	log.Printf("arrancando con %s", cfg)

	store := memstore.New()
	clock := clock.System{}
	ids := ulid.NewGenerator()

	svc := opsreport.New(store, clock, ids)

	r := router.New()
	httpapi.NewWorkItemHandler(svc).Register(r)
	httpapi.NewHealthHandler().Register(r)

	handler := middleware.Chain(r,
		middleware.RequestID,
		middleware.Logging,
		middleware.Recover,
		middleware.MaxBodyBytes(1<<20), // 1 MiB
	)

	srv := &http.Server{
		Addr:    cfg.HTTPAddr,
		Handler: handler,

		// Los cuatro tiempos de espera. http.Server{} NO tiene NINGUNO por
		// defecto, y eso no es un descuido de la stdlib: es una decisión de no
		// imponer política. La consecuencia es que un servidor Go escrito sin
		// pensar es vulnerable a Slowloris desde el primer día.

		// ReadHeaderTimeout: desde que se acepta la conexión hasta que llegan
		// todas las cabeceras. ES EL QUE PARA SLOWLORIS: un atacante que manda
		// una cabecera por minuto mantiene la conexión viva indefinidamente.
		ReadHeaderTimeout: 5 * time.Second,

		// ReadTimeout: desde que se acepta hasta que se termina de leer el
		// cuerpo. Incluye al anterior. Un cliente que manda el cuerpo a un byte
		// por segundo se corta aquí.
		ReadTimeout: 15 * time.Second,

		// WriteTimeout: desde el final de la lectura de cabeceras hasta el final
		// de la escritura de la respuesta. Un cliente que lee la respuesta
		// lentísimo para ocupar un worker se corta aquí.
		//
		// ⚠️ Este es el que hay que subir cuando un endpoint sirve un reporte
		// grande en streaming (Fase 13). Si no, la descarga se corta a mitad.
		WriteTimeout: 30 * time.Second,

		// IdleTimeout: cuánto se mantiene viva una conexión keep-alive sin
		// peticiones. Sin esto, las conexiones ociosas se acumulan.
		IdleTimeout: 120 * time.Second,
	}

	log.Printf("escuchando en %s", cfg.HTTPAddr)
	if err := srv.ListenAndServe(); err != nil && err != http.ErrServerClosed {
		log.Fatalf("el servidor terminó con error: %v", err)
	}
}
```

> ⚠️ **`http.Server{}` sin tiempos de espera es un incidente esperando.** No es
> una opinión: es la configuración por defecto y es explotable. El ataque
> Slowloris consiste en abrir miles de conexiones y mandar una cabecera cada
> treinta segundos; sin `ReadHeaderTimeout`, cada una consume una goroutine y un
> descriptor **indefinidamente**. Con un servidor que aguanta 10.000 conexiones,
> un atacante con un portátil lo satura.
>
> Y lo peor es que **no se nota en desarrollo ni en las pruebas de carga**,
> porque un cliente normal nunca se comporta así.

> 💸 **Deuda técnica intencional.** Este `main` arranca pero **no sabe pararse**:
> un `Ctrl+C` mata el proceso en seco, cortando las peticiones en vuelo. **Se
> paga en la Fase 07**, con `Shutdown`, señales del sistema operativo y drenaje
> ordenado.

### 6.6 `fakeconsumer` nace

El segundo binario de EventRelay. Existe para que en la Fase 06 haya a quién
entregar, en la Fase 10 haya a quién reintentar, y en la Fase 15 haya contra quién
medir.

```go
// services/eventrelay/cmd/fakeconsumer/main.go

// Command fakeconsumer simula a un socio comercial que recibe webhooks.
//
// Sirve tres comportamientos: responder bien, responder lento y responder mal.
// Es la contraparte de EventRelay en todas las pruebas del curso, y existe para
// que ninguna prueba dependa de un servicio de internet.
package main

import (
	"flag"
	"fmt"
	"io"
	"io/ioutil"
	"log"
	"math/rand"
	"net/http"
	"strconv"
	"sync/atomic"
	"time"
)

// counters son las estadísticas que EventRelay consulta en los tests para saber
// cuántas entregas llegaron de verdad.
type counters struct {
	ok     uint64
	slow   uint64
	failed uint64
}

func main() {
	addr := flag.String("addr", ":9100", "dirección de escucha")
	slowDelay := flag.Duration("slow-delay", 8*time.Second, "retraso del endpoint /slow")
	flag.Parse()

	var c counters
	mux := http.NewServeMux()

	// /ok responde 200 siempre, leyendo y descartando el cuerpo.
	mux.HandleFunc("/ok", func(w http.ResponseWriter, r *http.Request) {
		body, _ := ioutil.ReadAll(io.LimitReader(r.Body, 1<<20))
		atomic.AddUint64(&c.ok, 1)

		log.Printf("OK   %s %d bytes evento=%s firma=%s",
			r.Method, len(body),
			r.Header.Get("X-Meridian-Event-Type"),
			r.Header.Get("X-Meridian-Signature"))

		w.WriteHeader(http.StatusOK)
		fmt.Fprintln(w, `{"received":true}`)
	})

	// /slow tarda a propósito. Es cómo se prueba que el cliente de EventRelay
	// tiene tiempo límite — y en la Fase 10 veremos que el http.Client por
	// defecto NO lo tiene y espera para siempre.
	mux.HandleFunc("/slow", func(w http.ResponseWriter, r *http.Request) {
		atomic.AddUint64(&c.slow, 1)
		log.Printf("SLOW %s esperando %s", r.URL.Path, *slowDelay)
		time.Sleep(*slowDelay)
		w.WriteHeader(http.StatusOK)
	})

	// /fail/{code} responde el código que le pidas. Sirve para probar la
	// clasificación de errores recuperables (5xx, 429) frente a permanentes
	// (4xx), que es el corazón de la Fase 10.
	mux.HandleFunc("/fail/", func(w http.ResponseWriter, r *http.Request) {
		atomic.AddUint64(&c.failed, 1)

		raw := r.URL.Path[len("/fail/"):]
		code, err := strconv.Atoi(raw)
		if err != nil || code < 100 || code > 599 {
			http.Error(w, "código inválido", http.StatusBadRequest)
			return
		}

		// El 429 lleva Retry-After, que es lo que un cliente educado respeta.
		if code == http.StatusTooManyRequests {
			w.Header().Set("Retry-After", "3")
		}
		log.Printf("FAIL respondiendo %d", code)
		w.WriteHeader(code)
	})

	// /flaky falla una fracción de las veces. Es el más realista de los cuatro:
	// un socio real no está caído, está inestable.
	mux.HandleFunc("/flaky", func(w http.ResponseWriter, r *http.Request) {
		if rand.Float64() < 0.3 {
			atomic.AddUint64(&c.failed, 1)
			w.WriteHeader(http.StatusServiceUnavailable)
			return
		}
		atomic.AddUint64(&c.ok, 1)
		w.WriteHeader(http.StatusOK)
	})

	// /stats permite que un test pregunte cuántas entregas llegaron.
	mux.HandleFunc("/stats", func(w http.ResponseWriter, r *http.Request) {
		w.Header().Set("Content-Type", "application/json")
		fmt.Fprintf(w, `{"ok":%d,"slow":%d,"failed":%d}`,
			atomic.LoadUint64(&c.ok),
			atomic.LoadUint64(&c.slow),
			atomic.LoadUint64(&c.failed))
	})

	srv := &http.Server{
		Addr:              *addr,
		Handler:           mux,
		ReadHeaderTimeout: 5 * time.Second,
		ReadTimeout:       15 * time.Second,
		// WriteTimeout tiene que ser MAYOR que slow-delay o /slow se corta solo
		// y deja de simular lo que queremos simular.
		WriteTimeout: *slowDelay + 5*time.Second,
		IdleTimeout:  60 * time.Second,
	}

	log.Printf("fakeconsumer escuchando en %s (slow=%s)", *addr, *slowDelay)
	log.Fatal(srv.ListenAndServe())
}
```

```bash
go1.13 run ./cmd/fakeconsumer -addr :9100 -slow-delay 8s &

curl -i -X POST localhost:9100/ok -d '{"type":"order.created"}'
curl -i localhost:9100/fail/503
curl -i localhost:9100/fail/429     # fíjate en el Retry-After
curl -s localhost:9100/stats | jq
```

> 🧪 **Prueba de fuego.** Llama a `/slow` con `curl --max-time 2`. Tu `curl` corta
> a los dos segundos; el servidor sigue durmiendo los ocho. **La mentira de la
> pantalla:** que el cliente se rinda no detiene el trabajo del servidor. En la
> Fase 07 veremos que `r.Context()` **sí** se cancela cuando el cliente
> desaparece, y que un handler que no lo mira sigue quemando CPU para nadie. Ese
> es el argumento entero de la Fase 07 en una línea.

### 6.7 La suite HTTP: `httptest`

Y ahora lo que hace que todo esto sea probable sin abrir un puerto:

```go
// services/opsreport/internal/httpapi/workitems_test.go
package httpapi_test

import (
	"bytes"
	"encoding/json"
	"net/http"
	"net/http/httptest"
	"strings"
	"testing"
)

// newTestAPI arma la API completa con dobles. Es el equivalente de
// @SpringBootTest, escrito a mano en diez líneas y sin contexto que cachear.
func newTestAPI(t *testing.T) (http.Handler, *fakeStore) {
	t.Helper()

	store := newFakeStore()
	svc := opsreport.New(store, clock.NewFake(testNow), &seqIDs{})

	r := router.New()
	httpapi.NewWorkItemHandler(svc).Register(r)

	return middleware.Chain(r, middleware.RequestID, middleware.Recover), store
}

func TestCreateWorkItem(t *testing.T) {
	tests := []struct {
		name       string
		body       string
		wantStatus int
		wantCode   string
	}{
		{
			name:       "petición válida devuelve 201",
			body:       `{"external_reference":"SAP-2026-000123","kind":"import","priority":3}`,
			wantStatus: http.StatusCreated,
		},
		{
			name:       "sin referencia externa devuelve 422",
			body:       `{"kind":"import","priority":3}`,
			wantStatus: http.StatusUnprocessableEntity,
			wantCode:   "validation_failed",
		},
		{
			name:       "prioridad fuera de rango devuelve 422",
			body:       `{"external_reference":"SAP-1","kind":"import","priority":99}`,
			wantStatus: http.StatusUnprocessableEntity,
			wantCode:   "validation_failed",
		},
		{
			name:       "json roto devuelve 400",
			body:       `{"external_reference":`,
			wantStatus: http.StatusBadRequest,
			wantCode:   "bad_request",
		},
		{
			name:       "campo desconocido devuelve 400",
			body:       `{"external_reference":"SAP-1","kind":"import","priority":3,"prioriti":9}`,
			wantStatus: http.StatusBadRequest,
			wantCode:   "bad_request",
		},
	}

	for _, tt := range tests {
		tt := tt
		t.Run(tt.name, func(t *testing.T) {
			api, _ := newTestAPI(t)

			// httptest.NewRequest construye una petición lista para servir.
			// No abre un socket: es una struct.
			req := httptest.NewRequest(http.MethodPost, "/work-items",
				strings.NewReader(tt.body))
			req.Header.Set("Content-Type", "application/json")

			// NewRecorder es un ResponseWriter que guarda lo que se escribe.
			rec := httptest.NewRecorder()

			api.ServeHTTP(rec, req)

			if rec.Code != tt.wantStatus {
				t.Fatalf("status = %d, quería %d\ncuerpo: %s",
					rec.Code, tt.wantStatus, rec.Body.String())
			}

			if ct := rec.Header().Get("Content-Type"); !strings.HasPrefix(ct, "application/json") {
				t.Errorf("Content-Type = %q, quería application/json", ct)
			}

			if tt.wantCode != "" {
				var body struct {
					Code string `json:"code"`
				}
				if err := json.Unmarshal(rec.Body.Bytes(), &body); err != nil {
					t.Fatalf("respuesta no es json: %v", err)
				}
				if body.Code != tt.wantCode {
					t.Errorf("code = %q, quería %q", body.Code, tt.wantCode)
				}
			}

			if tt.wantStatus == http.StatusCreated {
				if loc := rec.Header().Get("Location"); loc == "" {
					t.Error("falta la cabecera Location en el 201")
				}
			}
		})
	}
}

func TestStartWorkItem_Conflict(t *testing.T) {
	api, store := newTestAPI(t)

	// Crear y arrancar.
	item := mustCreateViaAPI(t, api, "SAP-2026-000999")
	mustPost(t, api, "/work-items/"+item.ID+"/start", http.StatusOK)

	// Arrancarlo otra vez: 409, no 400 y no 500.
	rec := mustPost(t, api, "/work-items/"+item.ID+"/start", http.StatusConflict)

	var body struct {
		Code string `json:"code"`
	}
	json.Unmarshal(rec.Body.Bytes(), &body)
	if body.Code != "conflict" {
		t.Errorf("code = %q, quería conflict", body.Code)
	}
	_ = store
}

func TestMethodNotAllowed(t *testing.T) {
	api, _ := newTestAPI(t)

	req := httptest.NewRequest(http.MethodPatch, "/work-items", nil)
	rec := httptest.NewRecorder()
	api.ServeHTTP(rec, req)

	if rec.Code != http.StatusMethodNotAllowed {
		t.Fatalf("status = %d, quería 405", rec.Code)
	}
	// La cabecera Allow es obligatoria en un 405 según el RFC 7231, y es lo
	// primero que se olvida.
	if allow := rec.Header().Get("Allow"); allow == "" {
		t.Error("falta la cabecera Allow en el 405")
	}
}

// TestPanicIsRecovered verifica que un handler que entra en panic devuelve 500
// en vez de cerrar la conexión sin respuesta.
func TestPanicIsRecovered(t *testing.T) {
	r := router.New()
	r.GET("/boom", func(w http.ResponseWriter, r *http.Request, _ router.Params) {
		panic("algo explotó")
	})
	api := middleware.Chain(r, middleware.RequestID, middleware.Recover)

	req := httptest.NewRequest(http.MethodGet, "/boom", nil)
	rec := httptest.NewRecorder()

	api.ServeHTTP(rec, req)

	if rec.Code != http.StatusInternalServerError {
		t.Errorf("status = %d, quería 500", rec.Code)
	}
}
```

**`httptest.NewRecorder` no abre un puerto.** No hay socket, no hay red, no hay
resolución de nombres, no hay puerto ocupado. Es una struct que implementa
`ResponseWriter` y guarda lo que escribes. Por eso mil tests HTTP corren en menos
de un segundo.

Y cuando **sí** hace falta un servidor de verdad —para probar un cliente, que es
la Fase 10—, está `httptest.NewServer`:

```go
func TestFakeConsumerRespondsOK(t *testing.T) {
	// NewServer abre un puerto real en localhost, elegido por el sistema.
	srv := httptest.NewServer(fakeconsumer.Handler())
	defer srv.Close()

	resp, err := http.Post(srv.URL+"/ok", "application/json",
		strings.NewReader(`{"type":"order.created"}`))
	if err != nil {
		t.Fatalf("POST /ok: %v", err)
	}
	defer resp.Body.Close()

	if resp.StatusCode != http.StatusOK {
		t.Errorf("status = %d, quería 200", resp.StatusCode)
	}
}
```

📖 `NewRecorder` es `MockMvc` de Spring Test: sin servidor, rápido, para probar el
handler. `NewServer` es `@SpringBootTest(webEnvironment = RANDOM_PORT)`: servidor
real, más lento, para probar el ciclo completo incluido el cliente. **El mismo
criterio de cuándo usar cada uno se traslada tal cual** 🩻.

---

## ⚰️ 7. Autopsia y errores comunes

### ⚰️ Autopsia: el handler que hacía de servicio

**El cadáver.** Es el antipatrón más frecuente en APIs de Go escritas por gente que
viene de Spring, y viene de una confusión razonable: en Spring, `@RestController`
con `@Transactional` y `@Autowired` puede tener lógica, y en muchos proyectos la
tiene.

```go
// ☕
func (h *Handler) CreateWorkItem(w http.ResponseWriter, r *http.Request) {
	var req createRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		http.Error(w, "bad request", 400)
		return
	}

	// Validación aquí...
	if req.ExternalReference == "" {
		http.Error(w, "external_reference requerido", 400)
		return
	}
	if req.Priority < 1 || req.Priority > 9 {
		http.Error(w, "prioridad inválida", 400)
		return
	}

	// ...reglas de negocio aquí...
	item := workitem.WorkItem{
		ID:                uuid.New().String(),
		ExternalReference: strings.ToUpper(strings.TrimSpace(req.ExternalReference)),
		Kind:              workitem.Kind(req.Kind),
		Priority:          workitem.Priority(req.Priority),
		Status:            workitem.StatusQueued,
		CreatedAt:         time.Now(),
	}

	// ...y persistencia aquí.
	if err := h.store.Save(item); err != nil {
		log.Println(err)
		http.Error(w, "internal error", 500)
		return
	}

	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(201)
	json.NewEncoder(w).Encode(item)
}
```

Funciona. Y tiene seis problemas medibles.

**El informe forense**, contra la versión de §6.4:

| | Handler-servicio ☕ | Handler delgado |
|---|---|---|
| Líneas del handler | 38 | 22 |
| Responsabilidades | 5 (decodificar, validar, aplicar reglas, persistir, codificar) | 2 (decodificar, codificar) |
| Se puede probar sin HTTP | **no** | sí (el servicio ya tiene su suite de la Fase 04) |
| Sitios donde vive la regla "prioridad 1..9" | 2 (aquí y en el dominio) — **y pueden divergir** | 1 |
| Sitios donde se deciden códigos de estado | tantos como handlers | 1 (`classify`) |
| Llamadas a `time.Now()` fuera del reloj inyectado | 1 | 0 |
| Códigos de estado literales | 3 | 0 |

**Los dos problemas que de verdad duelen:**

**La validación duplicada que diverge.** La regla `1..9` está en el handler y en
`workitem.Validate()`. El día que el negocio la cambie a `1..5`, alguien va a
cambiar una y no la otra, y el sistema tendrá dos verdades. Esto no es hipotético;
es lo que pasa siempre.

**Y el que es un bug de seguridad, no de estilo:** el handler construye el
`WorkItem` a mano, así que **cualquier campo que el `createRequest` acepte va a
parar al dominio**. Si mañana alguien añade `Status` al `createRequest` "para las
pruebas", un cliente puede crear un work item directamente en estado `done`. La
versión delgada no puede tener ese bug: el servicio pone `ID`, `CreatedAt` y
`Status`, y el test del ejercicio 12 de la Fase 04 lo verifica.

**La causa de la muerte.** El reflejo de Spring de que el controlador "orquesta",
combinado con que en Go el handler tiene acceso directo al almacén y no hay nada
que lo impida. En Spring, la separación la sugiere la anotación (`@Service`
frente a `@RestController`); en Go no hay anotación, así que la disciplina es
tuya.

**Y el matiz honesto:** para un endpoint que de verdad no hace nada —un `/health`,
un `/version`— montar servicio, interfaz y dobles es ceremonia sin destinatario.
`/health` en este curso es un handler de cuatro líneas y está bien así. La regla no
es "siempre tres capas"; es **"el handler no toma decisiones de negocio"**.

> ☕ **El patrón a memorizar.** Un handler hace tres cosas: **decodifica, llama,
> codifica.** Si tiene un `if` que no sea manejo de error o de parámetros de
> consulta, párate y pregúntate dónde debería vivir esa condición.

### Errores comunes

**1. `WriteHeader` llamado dos veces.**
*Síntoma:* `http: superfluous response.WriteHeader call from ...` en el log.
*Causa:* el handler escribió el cuerpo y después intentó cambiar el estado, o dos
caminos escriben sin `return` en medio.
*Fix mínimo:* `return` después de cada `writeError`. Es el bug más común de los
handlers largos.

**2. El cuerpo de la petición sin cerrar... que no hay que cerrar.**
*Síntoma:* alguien escribe `defer r.Body.Close()` en cada handler.
*Causa:* confundir el lado servidor con el cliente. **En el servidor, `net/http`
cierra el cuerpo por ti**; en el cliente (Fase 10) cerrar la respuesta **es
obligatorio**.
*Fix mínimo:* quitarlo. No hace daño, pero es ruido que confunde sobre la regla
real.

**3. El cuerpo leído a medias y la conexión que no se reutiliza.**
*Síntoma:* con muchas peticiones, más conexiones abiertas de las esperadas.
*Causa:* si el handler no lee el cuerpo entero, la conexión no se puede reutilizar
para la siguiente petición keep-alive.
*Fix mínimo:* `io.Copy(ioutil.Discard, r.Body)` antes de responder, cuando decides
ignorar el cuerpo. Importa poco en el servidor y **mucho** en el cliente (Fase
10).

**4. Errores del dominio con `http.Error` a mano en cada handler.**
*Síntoma:* el mismo error responde 404 en un endpoint y 500 en otro.
*Causa:* cada handler decide su código.
*Fix mínimo:* `writeError` y solo `writeError`.

**5. El array JSON de primer nivel.**
*Síntoma:* hay que romper la API para añadir paginación.
*Causa:* `[{...}, {...}]` no tiene dónde poner metadatos.
*Fix mínimo:* envolver en `{"items": [...], "count": n}` desde el principio.

**6. `r.URL.Query().Get("x")` sin validar.**
*Síntoma:* `?limit=abc` produce un 500 o un comportamiento raro.
*Causa:* los parámetros de consulta son strings y siempre están presentes (vacíos
si no vienen).
*Fix mínimo:* parsear con `strconv` y devolver 400 con mensaje claro si falla.

**7. El servidor sin tiempos de espera.**
*Síntoma:* ninguno, hasta el día del incidente.
*Causa:* `http.Server{}` no los trae.
*Fix mínimo:* los cuatro de §6.5, siempre.

**8. El `panic` en un handler que tumba el proceso.**
*Síntoma:* el proceso muere, no solo la petición.
*Causa:* el panic ocurrió en una goroutine **lanzada por el handler**, no en la
del handler. `net/http` solo recupera la suya.
*Fix mínimo:* toda goroutine tiene su propio `recover`. Esto es de la Fase 06 y es
importante: **es la única forma de que un bug en una petición mate el servidor**.

### 🧨 Rompe a propósito

**Slowloris en tu propia máquina**, para que veas que no es teórico:

```go
// labs/httptest-lab/slowloris_test.go
// Abre N conexiones y manda una cabecera cada pocos segundos, sin terminar
// nunca la petición. Contra un servidor sin ReadHeaderTimeout, cada conexión se
// queda ocupada indefinidamente.
func TestSlowlorisWithoutTimeout(t *testing.T) {
	srv := &http.Server{
		Handler: http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
			w.WriteHeader(200)
		}),
		// ReadHeaderTimeout: 0  ← sin timeout, como http.Server{} por defecto
	}
	ln, _ := net.Listen("tcp", "127.0.0.1:0")
	go srv.Serve(ln)
	defer srv.Close()

	const attackers = 50
	for i := 0; i < attackers; i++ {
		go func() {
			conn, err := net.Dial("tcp", ln.Addr().String())
			if err != nil {
				return
			}
			defer conn.Close()

			fmt.Fprintf(conn, "GET / HTTP/1.1\r\nHost: localhost\r\n")
			for {
				// Una cabecera basura cada segundo, para siempre.
				fmt.Fprintf(conn, "X-Padding: %d\r\n", time.Now().UnixNano())
				time.Sleep(time.Second)
			}
		}()
	}

	time.Sleep(3 * time.Second)
	t.Logf("goroutines vivas con %d atacantes: %d", attackers, runtime.NumGoroutine())
	// Ahora repite con ReadHeaderTimeout: 2 * time.Second y compara.
}
```

Corre las dos versiones. Sin timeout, las cincuenta conexiones siguen vivas a los
tres segundos y las goroutines se acumulan. Con `ReadHeaderTimeout: 2s`, el
servidor las corta solo.

Cincuenta conexiones no tumban nada. Cincuenta mil, sí — y eso es un script de
diez líneas en cualquier máquina.

---

## 🧪 8. Ejercicios (26)

**🟢 Fácil (1–6)**

1. Escribe un handler `/version` que devuelva la versión inyectada con `-ldflags`
   de la Fase 00. *Criterio:* responde JSON con `Content-Type` correcto, y el
   valor cambia según cómo compiles.
2. Sirve `/health` y `/ready` con respuestas distintas y explica en dos líneas la
   diferencia. *Criterio:* `/health` no consulta ninguna dependencia; `/ready`
   está preparado para hacerlo (aunque hoy no tenga ninguna).
3. Usa `curl -i` para provocar un 404, un 405 y un 400 en OpsReport. *Criterio:*
   pegas las tres respuestas completas con sus cabeceras, y el 405 trae `Allow`.
4. Añade la cabecera `Location` a la respuesta 201 de creación. *Criterio:* un
   `curl` a esa URL devuelve el recurso recién creado.
5. Escribe el test que verifica que el `Content-Type` de todas las respuestas de
   error es `application/json`. *Criterio:* una tabla con al menos cuatro códigos
   distintos.
6. Usa `go1.13 doc net/http Server` y localiza los cuatro campos de timeout.
   *Criterio:* explicas en una línea qué pasa si cada uno vale cero.

**🟡 Intermedio (7–16)**

7. Implementa `tiny-router` completo con soporte para 405 y la cabecera `Allow`.
   *Criterio:* una ruta registrada solo para GET responde 405 —no 404— ante un
   POST, y el `Allow` lista los métodos disponibles.
8. Añade al enrutador soporte para barras finales opcionales, de forma que
   `/work-items` y `/work-items/` casen igual. *Criterio:* un test de tabla con
   las cuatro combinaciones.
9. Escribe el middleware `RequestID` y verifica que respeta el `X-Request-ID`
   entrante si viene. *Criterio:* dos tests: con cabecera y sin ella.
10. Escribe `statusRecorder` y comprueba que registra 200 cuando el handler llama
    a `Write` sin `WriteHeader`. *Criterio:* el test falla si quitas la
    inicialización de `r.status` en `Write`.
11. Monta la cadena de middleware completa y **cambia el orden** de `Logging` y
    `Recover`. *Criterio:* muestras las dos salidas de log ante un panic y
    explicas cuál quieres y por qué.
12. Implementa `MaxBodyBytes` y prueba que un cuerpo de 2 MiB con límite de 1 MiB
    devuelve 413. *Criterio:* el error se distingue de un JSON malformado, y
    reconoces el parche de época del mensaje por texto.
13. Traduce los errores de EventRelay a códigos HTTP en su propia función
    `classify`. *Criterio:* un endpoint dado de baja responde 409, un evento con
    payload demasiado grande responde 413, y un patrón de suscripción inválido
    responde 422.
14. Implementa la paginación por `?limit=&offset=` en `/work-items`. *Criterio:*
    valida los dos parámetros, tiene tope máximo de `limit`, devuelve el total en
    la respuesta, y un `limit=abc` da 400 con mensaje útil.
15. Escribe `fakeconsumer` completo y úsalo desde `curl` para los cuatro
    comportamientos. *Criterio:* `/stats` refleja las llamadas, y el `/fail/429`
    devuelve `Retry-After`.
16. **Línea de comandos.** Usa `curl -w` para medir la latencia de tus cinco
    endpoints y produce una tabla. *Criterio:* separas `time_starttransfer` de
    `time_total` y explicas qué mide cada uno.

**🟠 Difícil (17–22)**

17. **Diagnóstico.** Te dan un handler que produce
    `superfluous response.WriteHeader call`. Encuéntralo y arréglalo. *Criterio:*
    identificas los dos caminos que escriben, explicas por qué el `return` que
    faltaba es la causa, y escribes el test que lo habría detectado.
18. **Diagnóstico.** Un endpoint de OpsReport devuelve 500 en vez de 404 cuando el
    work item no existe. *Criterio:* localizas dónde se perdió la cadena de
    errores (`%v` en vez de `%w`), lo arreglas, y el test de `errors.Is` lo
    verifica.
19. Reproduce el ataque Slowloris de §7 contra tu propio servidor, con y sin
    `ReadHeaderTimeout`. *Criterio:* mides goroutines y descriptores abiertos en
    los dos casos, y anotas el número de conexiones que tu máquina aguanta.
20. **Detección de ☕ (1).** Te dan el handler-servicio de la autopsia. Refactorízalo
    a handler delgado. *Criterio:* cuentas líneas, responsabilidades y sitios donde
    vive cada regla; identificas el bug de seguridad y escribes el test que lo
    previene.
21. **Detección de ☕ (2).** Te dan una API donde cada handler tiene su propio
    `if err == sql.ErrNoRows { 404 } else { 500 }`. *Criterio:* lo centralizas,
    demuestras con un test que todos los endpoints responden igual ante el mismo
    error, y explicas qué gana un cliente de la API con esa consistencia.
22. Escribe una suite HTTP de contrato para OpsReport: una tabla de
    `(método, ruta, cuerpo) → (estado, código de error)` con al menos veinte
    filas. *Criterio:* la tabla se lee como la documentación de la API, y al menos
    cinco filas son casos de error que hoy no estaban cubiertos.

**🔴 Muy difícil (23–26)**

23. **El enrutador con árbol.** Reescribe `tiny-router` usando un árbol de
    prefijos en vez de búsqueda lineal. *Rúbrica:* (a) misma API pública, todos los
    tests anteriores pasan sin tocarlos; (b) soporta comodín de cola
    (`/files/*path`); (c) resuelve la precedencia entre `/work-items/new` y
    `/work-items/:id` de forma documentada y probada; (d) **mides las dos versiones
    con 200 rutas registradas** y anotas el resultado — y si la diferencia no
    justifica la complejidad, lo dices, que es la respuesta más probable y la más
    valiosa.
24. **La API versionada.** Monta `/v1/work-items` y `/v2/work-items` conviviendo,
    donde v2 cambia el nombre de un campo y añade otro. *Rúbrica:* (a) el dominio
    no se entera de que hay dos versiones; (b) la conversión vive en un solo sitio
    por versión; (c) los tests de v1 siguen pasando sin cambios; (d) explicas qué
    estrategia de versionado elegiste (ruta, cabecera, tipo de contenido) y qué
    pierdes con ella.
25. **Idempotencia en el borde.** Implementa `Idempotency-Key` en el POST de
    `/events` de EventRelay: dos peticiones con la misma clave producen un solo
    evento, y la segunda devuelve la respuesta de la primera. *Rúbrica:* (a)
    funciona con peticiones concurrentes (aunque hoy lo resuelvas con un mutex y
    anotes que la versión distribuida es de la Fase 12); (b) distingue "misma clave
    mismo cuerpo" de "misma clave cuerpo distinto", y responde 409 en el segundo
    caso; (c) la clave expira; (d) tienes un test que manda diez peticiones
    simultáneas y verifica que solo se creó un evento — córrelo con `-race`.
26. **La API documentada por sus tests.** Genera la documentación de la API de
    OpsReport **a partir de la suite de contrato del ejercicio 22**. *Rúbrica:* (a)
    un `go test` produce un `docs/api.md` con cada endpoint, sus códigos posibles y
    un ejemplo real de petición y respuesta tomado del test; (b) la documentación
    no se puede desincronizar del código porque sale de tests que pasan; (c)
    incluye los errores, no solo el camino feliz; (d) compara esta técnica con
    Swagger/OpenAPI generado por anotaciones y di honestamente qué pierdes.

**🔥 Opcionales**

- Lee `net/http/server.go` en tu `GOROOT` de 1.13, en concreto `conn.serve` y
  `ServeMux.ServeHTTP`. El primero te muestra dónde se lanza la goroutine por
  conexión y dónde se recupera el panic; el segundo, que el enrutado de la stdlib
  cabía en cincuenta líneas.
- Implementa negociación de contenido: el mismo endpoint devuelve JSON o CSV según
  el `Accept`. Es lo que `produces = {...}` de Spring hace, y verás que son quince
  líneas y una decisión de diseño.
- Sirve el reporte de OpsReport con `http.ServeContent` para que soporte
  peticiones de rango (`Range`) y reanudación de descarga. Es una función de la
  stdlib que casi nadie conoce y resuelve un problema real.

---

### 🔴 Desafíos de cierre

> Tres ejercicios de dificultad alta que **no cuentan en el total de la sección** y
> no son parte del recorrido base.

**D1 — El límite de conexiones concurrentes.**
`http.Server` no tiene forma de limitar cuántas conexiones acepta a la vez.
Impleméntalo envolviendo el `net.Listener`.
*Rúbrica:* (a) un `Listener` que bloquea el `Accept` cuando hay N conexiones vivas,
con semáforo; (b) las conexiones por encima del límite **esperan en la cola del
sistema operativo** en vez de consumir goroutines, y explicas la diferencia; (c)
mides con `vegeta` qué pasa al superar el límite: latencia frente a rechazo, y
decides cuál prefieres; (d) comparas con `server.tomcat.max-connections` y con
`accept-count` de Spring Boot, que resuelven exactamente esto, y dices qué te da
cada modelo.

**D2 — La API versionada de verdad.**
Sirve `/v1` y `/v2` del mismo recurso, donde v2 renombra un campo, añade otro y
cambia un código de estado.
*Rúbrica:* (a) el dominio **no se entera** de que hay dos versiones; (b) la
conversión vive en un solo sitio por versión y es la única que conoce el formato
antiguo; (c) los tests de contrato de v1 pasan **sin tocarlos**; (d) implementas
también el versionado por cabecera (`Accept: application/vnd.meridian.v2+json`) y
comparas las dos estrategias con sus ventajas reales; (e) documentas la política de
retirada: cuánto vive v1 y cómo se avisa.

**D3 — El cliente generado desde los tests.**
A partir de la suite de contrato, genera un cliente Go de la API de OpsReport.
*Rúbrica:* (a) el cliente cubre los cinco endpoints con tipos, no con `map`; (b) se
genera con `go generate` a partir de una definición única, de modo que no pueda
divergir del servidor; (c) los errores de la API se traducen a errores tipados que
el llamador puede comprobar con `errors.Is`; (d) comparas el resultado con lo que
daría `oapi-codegen` desde un OpenAPI y dices qué camino elegirías —definir el
contrato primero y generar los dos lados, o escribir el servidor y derivar el
cliente— con su argumento.

---

## 📚 9. Referencias

### Documentación oficial

- **`net/http`** — https://pkg.go.dev/net/http — la documentación de `Server`,
  `Handler`, `ResponseWriter` y `Request`. Es larga; léela por partes y vuelve.
- **`net/http/httptest`** — https://pkg.go.dev/net/http/httptest — corta y hay que
  leerla entera antes de escribir el primer test HTTP.
- **Writing Web Applications** — https://go.dev/doc/articles/wiki/ — el tutorial
  oficial. Básico, pero establece el modelo mental de handler.
- **`net/url`** — https://pkg.go.dev/net/url — `URL.Query()`, escapado y las
  trampas de la codificación de parámetros.
- **`context` (adelanto)** — https://pkg.go.dev/context — solo lo que usamos hoy;
  la Fase 07 lo cubre entero.
- **RFC 9110 (HTTP Semantics)** — https://www.rfc-editor.org/rfc/rfc9110.html —
  la referencia normativa de los códigos de estado y de cabeceras como `Allow`.
  No se lee entera; se consulta.
- **MDN: HTTP status codes** — https://developer.mozilla.org/en-US/docs/Web/HTTP/Status
  — más legible que el RFC para el día a día.

### Libros

- **Let's Go** — Alex Edwards. **Es el libro de esta fase.** Construye un servicio
  web completo con `net/http` puro: enrutado, middleware, manejo de errores,
  formularios. El enfoque es exactamente el del curso.
- **Let's Go Further** — Alex Edwards. La continuación: APIs JSON, versionado,
  limitación de tasa, métricas. Cubre material de las Fases 10, 12 y 14.
- **The Go Programming Language** — Donovan y Kernighan, capítulo 7.7 (el servidor
  web sobre `http.Handler`). Corto y muestra la elegancia del diseño.
- **100 Go Mistakes** — Harsanyi, capítulo 10 (*The Standard Library*), errores
  #74 a #81: los timeouts del servidor, el cuerpo sin cerrar y el
  `ResponseWriter` mal usado.

### Artículos y charlas

- **How I write HTTP services after eight years** — Mat Ryer. **Léelo.** Es el
  artículo más influyente sobre estructura de servicios HTTP en Go: el `server`
  como struct, las rutas en un solo sitio, los handlers que devuelven handlers.
  Hay una versión actualizada de 2024 en el blog de Grafana.
- **The complete guide to Go net/http timeouts** — Filippo Valsorda,
  https://blog.cloudflare.com/the-complete-guide-to-golang-net-http-timeouts/ —
  **la referencia definitiva sobre §6.5.** Explica cada timeout con su diagrama y
  qué cubre exactamente. Si solo lees un artículo de esta fase, que sea este.
- **Making and using HTTP middleware** — Alex Edwards,
  https://www.alexedwards.net/blog/making-and-using-middleware
- **Error handling in web applications** — Matt Silverlock,
  https://blog.questionable.services/article/http-handler-error-handling-revisited/
  — el patrón del handler que devuelve `error`, que es una alternativa legítima a
  `writeError` y conviene conocer.
- **Go's http.Server timeouts explained visually** — busca los diagramas de
  Valsorda reproducidos en varios blogs; son lo que hace que se entiendan.
- **Slowloris** — https://en.wikipedia.org/wiki/Slowloris_(computer_security) —
  para entender el ataque de §7 y por qué `ReadHeaderTimeout` existe.

### Video

- **How I Write HTTP Web Services after Eight Years** — Mat Ryer, GopherCon 2019.
  La charla del artículo, y se ve en cuarenta minutos.
- **GopherCon: Building APIs with Go** — hay varias; busca las que usen stdlib pura
  en vez de un framework.
- **JustForFunc: net/http deep dive** — Francesc Campoy. Serie corta y clara sobre
  el interior de `net/http`.

> ⚠️ **Advertencia especial para esta fase.** Casi todo el contenido sobre
> enrutado en Go es anterior a febrero de 2024 (Go 1.22) y da por hecho que
> necesitas un enrutador de terceros. **Eso cambió**: el `ServeMux` de 1.22 hace
> método y patrón de ruta. Un artículo de 2021 que dice "usa chi porque la stdlib
> no puede" no está mintiendo: está fechado. Lo veremos en la Fase 08.

### Orden de lectura sugerido

**Antes de escribir código:** *The complete guide to Go net/http timeouts* de
Valsorda. Veinte minutos y evita el único bug de esta fase que no se ve en
desarrollo.
**Durante:** *Making and using middleware* de Edwards cuando montes la cadena, y
la documentación de `httptest` antes del primer test.
**Después:** *How I write HTTP services after eight years* de Mat Ryer, entero, y
después vuelve a mirar tu propio `main`. Vas a querer cambiar dos cosas, y las dos
serán mejoras.

---

## ⚖️ 10. Veredicto y cierre

### ⚖️ Cuándo NO usar esto

`net/http` puro es suficiente para la mayoría de los servicios, y tiene límites
reales:

- **Cuando tu API es grande de verdad.** Con cinco endpoints, el enrutado a mano
  es un placer. Con ciento cincuenta, agrupados por prefijo, con middleware
  distinto por grupo y parámetros tipados, quieres un enrutador: `chi` para
  quedarte cerca de la stdlib, o el `ServeMux` de 1.22 si tu caso es sencillo. El
  curso evalúa `chi` en la Fase 13 con argumentos.
- **Cuando necesitas validación declarativa.** Bean Validation con `@NotNull`,
  `@Size`, `@Pattern` sobre el DTO es genuinamente menos código que escribir
  `Validate()` a mano, y los mensajes salen internacionalizados. En Go hay
  librerías (`go-playground/validator` con etiquetas de struct) pero este curso no
  las usa, porque la validación en el dominio —no en el DTO— es una decisión de
  diseño que preferimos mantener explícita. **Es una decisión defendible, no una
  verdad.**
- **Cuando necesitas OpenAPI generado.** Springdoc produce la especificación a
  partir de las anotaciones que ya escribiste. En Go hay que escribir el YAML a
  mano o generar el código **desde** el YAML (que es la dirección que prefiere el
  ecosistema, con `oapi-codegen`). Las dos funcionan; ninguna es tan cómoda como
  no hacer nada.
- **Cuando tu problema es reactivo de verdad.** WebFlux existe porque hay
  problemas —miles de conexiones largas con poca CPU por conexión— donde el modelo
  reactivo gana en un runtime con hilos de sistema operativo. En Go ese problema
  no existe porque una goroutine por conexión **es** el modelo eficiente, y esa es
  una ventaja genuina de Go. Pero si tu equipo ya domina WebFlux y su ecosistema,
  el argumento de migrar es más débil de lo que parece.
- **Y cuando necesitas el ecosistema completo de Spring Security.** OAuth2, OIDC,
  SAML, gestión de sesiones, CSRF, method security — es enorme, está muy probado y
  en Go hay que ensamblarlo de piezas. Este curso lo esquiva declarando que
  Meridian vive tras un gateway, que es lo que hacen muchas arquitecturas reales,
  pero la brecha es real.

### 📖 Diccionario Java ⇄ Go de esta fase

Es el diccionario más largo del curso, y con razón: es donde Spring MVC más cosas
hace por ti.

| Spring / Servlet | Go | Dónde se rompe la equivalencia |
|---|---|---|
| `@RestController` | un struct con métodos handler | No hay anotación ni registro automático: el handler se registra en una línea explícita |
| `@RequestMapping("/x")` | prefijo en el patrón del enrutador | Sin herencia de rutas por clase: cada ruta se escribe completa |
| `@GetMapping("/x/{id}")` | `r.GET("/x/:id", h)` (1.13) / `mux.HandleFunc("GET /x/{id}", h)` 🕰️ (1.22) | En 1.13 lo escribes tú; en 1.22 la stdlib lo trae |
| `@PathVariable("id") String id` | `p["id"]` / `r.PathValue("id")` 🕰️ | **Siempre string**: la conversión y su error son tuyos |
| `@PathVariable("id") Long id` | `strconv.ParseInt(p["id"], 10, 64)` + manejo de error | Spring convierte y lanza 400 solo; aquí decides tú el código y el mensaje |
| `@RequestParam` | `r.URL.Query().Get("x")` | Sin conversión, sin `required`, sin valor por defecto. Todo explícito |
| `@RequestBody Dto dto` | `json.NewDecoder(r.Body).Decode(&req)` | Sin negociación de contenido automática. Solo JSON, salvo que la escribas |
| `@Valid` + Bean Validation | `req.Validate()` escrito a mano | Sin anotaciones, sin mensajes internacionalizados. Más código, reglas en un solo sitio |
| `@ResponseStatus(CREATED)` | `w.WriteHeader(http.StatusCreated)` | Explícito, y **el orden importa**: después de escribir el cuerpo ya no se puede cambiar |
| `ResponseEntity<T>` | escribir en el `ResponseWriter` | No hay objeto de respuesta que construir y devolver; se escribe directamente al flujo |
| `@ControllerAdvice` + `@ExceptionHandler` | una función `writeError`/`classify` | Solo ve lo que el handler le pasa; un error tragado no llega. A cambio, sin orden de resolución que consultar |
| `HttpServletRequest` | `*http.Request` | El cuerpo es un `io.ReadCloser` de un solo uso: leerlo dos veces no funciona sin bufferizar |
| `HttpServletResponse` | `http.ResponseWriter` | **No se puede consultar el estado escrito**; por eso existe `statusRecorder` |
| `Filter` (servlet) | middleware `func(http.Handler) http.Handler` | Mismo patrón de envoltura. El orden es el de las líneas, no un `@Order` |
| `HandlerInterceptor` | middleware, otra vez | Go no distingue niveles: todo es el mismo mecanismo |
| `@Order` en filtros | la posición en la llamada a `Chain` | Visible en un sitio, en orden de lectura |
| `WebMvcConfigurer` | la función que monta la cadena en `main` | Sin configuración por clases repartidas |
| `DispatcherServlet` | tu enrutador (1.13) / `http.ServeMux` (1.22) 🕰️ | En 1.13 la stdlib solo hace prefijos; el despacho por método lo escribes |
| Tomcat / Jetty embebidos | `http.Server` | Es una struct de tu programa, no un contenedor. Tú controlas el ciclo de vida |
| `server.tomcat.connection-timeout` | `ReadHeaderTimeout` + `ReadTimeout` | **Ninguno tiene valor por defecto en Go.** Un `http.Server{}` desnudo es vulnerable a Slowloris |
| `server.tomcat.max-threads` | *(no aplica)* | Go lanza una goroutine por petición; el límite es la memoria, no un pool. El control se hace con semáforos (Fase 06) |
| `MockMvc` | `httptest.NewRecorder` | Sin servidor, sin puerto. Idéntico en propósito y más rápido |
| `@SpringBootTest(RANDOM_PORT)` + `TestRestTemplate` | `httptest.NewServer` + `http.Client` | Servidor real en un puerto efímero. Sin contexto cacheado entre clases |
| `produces`/`consumes` | escribir `Content-Type` y comprobar `Accept` a mano | Sin negociación automática de contenido |
| `HttpMessageConverter` | `encoding/json` directamente | Sin registro de conversores; si quieres XML o CSV, lo escribes |
| `@CrossOrigin` / CORS config | un middleware de CORS escrito o importado | Quince líneas, y merece entenderlas antes de copiarlas (Fase 14) |
| `spring.servlet.multipart.max-file-size` | `http.MaxBytesReader` en un middleware | Defensa explícita, en el borde, no configuración |
| Interceptor de logging de Spring | middleware `Logging` con `statusRecorder` | Hay que envolver el `ResponseWriter` para capturar el estado |
| `MDC` para correlación | valor en `context.Context` con clave de tipo privado | No es un `ThreadLocal`: se propaga explícitamente por parámetro (Fase 07) |

### Qué sigue

La Fase 06 es la estrella del Bloque A y la razón por la que mucha gente llega a
Go: **concurrencia**. El planificador, las goroutines, los canales, `select`,
`sync`, y el modelo de memoria leído de verdad.

Y algo que ya te afecta y todavía no has visto: **`net/http` lleva lanzando una
goroutine por petición desde que arrancaste el servidor en §6.5**. El `memstore`
de la Fase 02 no es seguro para uso concurrente, y con dos peticiones simultáneas
el mapa se corrompe. En la Fase 06 vas a provocarlo con `-race`, verlo, y
arreglarlo — y ese es exactamente el orden correcto de aprender concurrencia.

OpsReport estrena su motor de jobs con N workers; EventRelay, su cola de entregas
con concurrencia acotada, y **con una carrera de datos puesta a propósito** en su
primera versión.

### La señal de que quedó bien

> *"Veo una anotación de Spring MVC y ya no pienso 'magia'. Pienso: eso es un
> `switch` sobre el método, un corte de cadena y una conversión de tipos con su
> manejo de error. Y decido si el atajo me compensa."*

Si todavía te parece que `net/http` es "de bajo nivel", cuenta las líneas de tu
`Register`: cinco rutas, cinco líneas. La diferencia con `@GetMapping` no es de
nivel, es de quién escribe la conversión de tipos.

> 🏷️ **No cierres la fase sin el tag.** Con el checklist de la sección 2 en
> verde, `go1.13 test -race ./...` en verde, `golangci-lint run` limpio y
> `git status` sin cambios pendientes:
>
> ```bash
> git tag -a fase-05 -m "F5 cerrada: APIs REST de OpsReport y EventRelay con net/http y enrutado propio; middleware de request-id, logging, recover y límite de cuerpo; traducción de errores a HTTP en un solo sitio; los cuatro timeouts del servidor; suite HTTP con httptest; fakeconsumer funcionando"
> git tag -a opsreport/v0.5 -m "OpsReport: API REST completa en memoria"
> git tag -a eventrelay/v0.4 -m "EventRelay: API REST y fakeconsumer"
> ```
>
> Los commits de la fase llevan su prefijo (`fase 05: …`) y los de ejercicio su
> número (`fase 05 ej23: …`). Todo eso está en
> [`00-convencion-de-git-y-tags.md`](00-convencion-de-git-y-tags.md).

---

# 📌 Bloque de autoría (fuera de lo que lee el estudiante)

## 📌 Pendientes sugeridos

- **`tiny-router` con árbol de prefijos** (ejercicio 23) — su medición contra la
  versión lineal es una candidata natural a **B-12** (Fase 08), que ya compara el
  `ServeMux` de 1.22 con el enrutado a mano. **Sugerencia: que B-12 tenga tres
  variantes**, no dos: lineal, árbol propio, y `ServeMux` moderno.
- **CORS** — nombrado en el diccionario y en el ⚖️. Está en el alcance de la
  **Fase 14**; verificado.
- **Negociación de contenido (JSON/CSV por `Accept`)** — ejercicio 🔥 aquí, y
  **la Fase 13 decidió lo contrario**: sus descargas van por query param, con los
  tres argumentos documentados en su §6.6. El 🔥 se queda porque implementarlo una
  vez —con su `Vary: Accept`— es lo que hace entender por qué allí no se usa. Se
  vuelve necesario de verdad en la **Fase 13**, con la descarga de reportes en tres
  formatos. **Anotar allí que el mecanismo ya se exploró.**
- **`http.ServeContent` y peticiones de rango** — ejercicio 🔥. Su sitio real es la
  **Fase 13** (descarga de reportes grandes reanudable). Candidato a sección corta
  allí.
- **Idempotencia con `Idempotency-Key`** (ejercicio 25) — hoy con mutex local. La
  versión distribuida con `SET NX` es de la **Fase 12**; comprobar que allí se cita
  este ejercicio como punto de partida.
- **OpenAPI generado desde los tests** (ejercicio 26) — no tiene fase que lo
  adopte. Se queda como ejercicio 🔴; si alguna vez se quiere formalizar, la Fase
  17 (capstone) sería el sitio.
- **El patrón "handler que devuelve error"** (referencia a Silverlock) — es una
  alternativa legítima a `writeError` que el curso no adopta. **Candidato a
  ejercicio de la Fase 08**, donde se discute qué se adopta y qué se rechaza al
  modernizar.

## ☕ Reflejos para `INSTINTOS.md`

- **"Elegir framework web antes de escribir un handler"** — en Go los frameworks
  son enrutadores con azúcar; `net/http` es el framework. Coste: no entiendes lo
  que tu framework hace.
- **"El controlador orquesta"** — el handler-servicio de la autopsia. Coste: 38
  líneas frente a 22, validación duplicada que diverge, y un bug de escalada de
  privilegios al construir la entidad a mano.
- **"Cada handler decide su código de estado"** — el mismo error responde 404 aquí
  y 500 allá. Antídoto: una sola función `classify`.
- **"`http.Server{}` está bien así"** — sin timeouts es vulnerable a Slowloris y
  no se nota nunca en desarrollo.
- **"Devolver un array JSON de primer nivel"** — imposible de extender con
  metadatos sin romper clientes.
- **"`defer r.Body.Close()` en el servidor"** — confusión de lado. En el servidor
  lo cierra `net/http`; en el cliente es obligatorio (Fase 10).

## 📐 Mediciones para `BENCHMARKS.md`

Esta fase no produce entradas propias, pero deja tres preparadas:

- **B-12 (Fase 08)** — el `tiny-router` de §6.1 es el sujeto. **Proponer que
  incluya la variante con árbol de prefijos del ejercicio 23** y que mida con 5,
  50 y 200 rutas, porque el resultado con 5 rutas es previsiblemente "no importa" y
  esa es media lección.
- **B-23 (Fase 15)** — `fakeconsumer` es la contraparte contra la que se medirán
  las entregas por segundo de EventRelay. Nace aquí con el `/stats` que lo hace
  medible; **verificar que la Fase 15 lo usa y no monta otra cosa.**
- **Sin ID todavía:** coste del middleware por petición (cadena vacía frente a
  cadena de cuatro). Es barato de medir con `httptest` y desmonta la preocupación
  habitual. **Candidato a entrada de la Fase 15**, no aquí, porque hoy no hay banco
  de pruebas montado.
