# 👁️ Fase 14 — Observabilidad, configuración y hardening

> Go para desarrolladores Java senior · Fase 14 de 17 · **7 horas**
> Época: **Go moderno (1.25)**
> Depende de: Fase 13 · Habilita: Fase 15
> Proyectos que avanzan: **los cuatro**
> Mini proyectos: `slog-lab`, `metrics-lab`, `distroless-lab`

---

## 🎯 1. Propósito

Los cuatro servicios funcionan y están conectados. Lo que les falta es todo lo que
hace falta para **operarlos**: saber qué está pasando dentro, configurarlos sin
recompilar, apagarlos sin sorpresas y desplegarlos sin regalar la casa.

Esta es también la fase donde se pagan las deudas más viejas del curso. La
**validación de URL contra SSRF** de EventRelay lleva viva desde la Fase 02 —doce
fases— y hoy se cierra. El `Makefile` sin validación de la Fase 00. El logger
provisional de la Fase 03. La verificación de la firma HMAC de la Fase 10. Y el
umbral de cobertura que lleva diez fases imprimiéndose sin fallar nunca el build.

Y un 🧨 que va a incomodar: **registra un secreto a propósito y mira dónde acaba.**

---

## ✅ 2. Qué queda listo al terminar

- [ ] Los cuatro servicios usan `slog` con el logger **inyectado**, salida JSON en
      producción y texto en desarrollo, y correlación por identificador de
      petición.
- [ ] `/metrics` expone las métricas RED de cada servicio, y **ninguna etiqueta es
      de alta cardinalidad** — lo has verificado.
- [ ] Las trazas de OpenTelemetry atraviesan los cuatro servicios y se ven en un
      Jaeger local.
- [ ] `/health` y `/ready` hacen cosas **distintas**, y sabes explicar por qué.
- [ ] La configuración se valida entera al arrancar, con fallo rápido y secretos
      redactados en el log.
- [ ] Las imágenes son multi-etapa sobre `distroless`, con usuario sin
      privilegios, y sabes cuánto pesan frente al Spring Boot equivalente (B-21).
- [ ] **SSRF resuelta**: EventRelay rechaza URLs que resuelvan a rangos privados,
      con el control en el momento de conectar.
- [ ] La firma HMAC se verifica con `hmac.Equal` y ventana de validez.
- [ ] `govulncheck` corre en CI y el umbral de cobertura **falla el build**.

---

## 🚫 3. Qué NO entra todavía

- Perfilado y optimización → Fase 15. Hoy instrumentamos; allí medimos.
- El duelo contra Spring Boot → Fase 16. B-21 mide solo el tamaño de la imagen.
- Kubernetes, service mesh y orquestación → **fuera del curso**. Llegamos hasta la
  imagen y el `docker compose`. Los números del periodo de gracia se justifican
  contra el estándar de facto, sin entrar en manifiestos.
- Autenticación y autorización → fuera del curso: Meridian vive tras un gateway.
  El endurecimiento de hoy es lo que un servicio interno debe hacer **además** de
  eso.
- Alertas y paneles → se definen en el ejercicio 26; montarlos queda fuera.

---

## 🧠 4. Concepto mínimo

### Los tres pilares, y qué responde cada uno

```text
LOGS      → ¿qué pasó exactamente en esta petición?        (alta fidelidad, caro)
MÉTRICAS  → ¿cómo se comporta el sistema en agregado?      (barato, sin detalle)
TRAZAS    → ¿por dónde pasó esta petición y qué tardó?     (caro, muestreado)
```

La regla práctica que evita el error más común:

> 🧭 **Regla del proyecto.** **Si vas a contarlo, es una métrica. Si vas a leerlo,
> es un log. Si vas a seguirlo entre servicios, es una traza.**
>
> El error caro es usar logs como métricas: *"cuento las líneas que dicen `error`
> en el agregador"*. Eso funciona hasta que el volumen crece, y entonces tu factura
> de observabilidad supera la de cómputo.

📖 En Java esto son Logback + Micrometer + Sleuth/OTel. **La arquitectura es
idéntica**; lo que cambia es que en Go hay una sola fachada oficial de logging en
la stdlib (`slog`) en vez de la torre SLF4J con sus *bindings* y sus conflictos de
classpath.

### `slog`: lo que hay que hacer bien desde el principio

```go
// 1. El logger se CONSTRUYE en main, según la configuración.
func newLogger(cfg Config) *slog.Logger {
	opts := &slog.HandlerOptions{
		Level: parseLevel(cfg.LogLevel),
		// AddSource añade archivo y línea. Cuesta rendimiento (una llamada a
		// runtime.Caller por registro) y en producción casi nunca hace falta:
		// el mensaje y los atributos dicen más que la línea.
		AddSource: cfg.LogSource,

		// ReplaceAttr es el gancho de redacción. Ver §6.1: es la defensa
		// sistemática contra el 🧨 de esta fase.
		ReplaceAttr: redactSensitive,
	}

	var h slog.Handler
	if cfg.LogFormat == "json" {
		h = slog.NewJSONHandler(os.Stdout, opts)
	} else {
		h = slog.NewTextHandler(os.Stdout, opts)
	}

	// Los atributos comunes a TODO el proceso se ponen una vez, no en cada
	// llamada. With devuelve un logger nuevo con esos atributos precomputados.
	return slog.New(h).With(
		slog.String("service", cfg.ServiceName),
		slog.String("version", buildVersion),
		slog.String("env", cfg.Environment),
	)
}

// 2. Se INYECTA. slog.Default() existe y no lo usamos: es estado global mutable,
//    que es la regla 7 de la guía de estilo.
type Service struct {
	store  Store
	logger *slog.Logger
}

// 3. Se DERIVA en el borde con el contexto de la petición, y baja por parámetro.
func (h *Handler) create(w http.ResponseWriter, r *http.Request) {
	log := h.logger.With(
		slog.String("request_id", middleware.RequestIDFrom(r.Context())),
		slog.String("path", r.URL.Path),
	)
	// ...
}
```

**Y las tres decisiones que hay que tomar a conciencia:**

```go
// A. LogAttrs en vez de la forma variádica, en código de librería.
//
// logger.Info("msg", "clave")  ← número impar de argumentos: COMPILA y produce
//                                un registro con !BADKEY. vet no lo detecta.
logger.LogAttrs(ctx, slog.LevelInfo, "trabajo completado",
	slog.String("work_item_id", item.ID),
	slog.Duration("duration", elapsed))

// B. El nivel se comprueba ANTES de construir atributos caros.
//
// Sin esto, el cálculo se hace aunque el registro se descarte.
if logger.Enabled(ctx, slog.LevelDebug) {
	logger.LogAttrs(ctx, slog.LevelDebug, "estado del lote",
		slog.String("dump", expensiveDump(batch)))   // solo si va a salir
}

// C. Los nombres de atributo son ESTABLES y snake_case.
//
// Un atributo que se llama "workItemId" en un sitio y "work_item_id" en otro
// hace imposible la consulta agregada. Se fijan una vez, en constantes.
const (
	attrWorkItemID = "work_item_id"
	attrBatchID    = "batch_id"
	attrEndpointID = "endpoint_id"
)
```

### 🪞 Tu instinto de Java dice… y esta vez se equivoca

**El instinto:** *"pongo el `traceId` en el MDC y aparece en todos los logs de este
hilo"*. En Java es la solución estándar desde hace quince años: `MDC.put("traceId",
id)` en un filtro, `%X{traceId}` en el patrón de Logback, y todos los logs de esa
petición lo llevan sin que ninguna capa se entere.

**Qué pasa si lo aplicas aquí.** Buscas el MDC de Go, no lo hay, y acabas en una de
estas dos:

```go
// ☕ Opción A: un "MDC" con un mapa global protegido por mutex, indexado por...
//    ¿por qué? No hay identificador de goroutine estable y accesible. Y es
//    deliberado: el equipo de Go decidió no exponerlo precisamente para que
//    nadie construyera esto.

// ☕ Opción B: meter el *slog.Logger en el context.Context y sacarlo en cada capa.
func (s *Service) Create(ctx context.Context, item WorkItem) error {
	log := LoggerFrom(ctx)   // ← y si nadie lo puso, devuelve... ¿qué?
	log.Info("creando")
	// ...
}
```

La opción B **es defendible** y mucha gente la usa. Sus problemas concretos:

1. **`LoggerFrom` tiene que devolver algo cuando no hay nada**, y esa rama —un
   logger por defecto, o uno que descarta— se ejerce en producción el día que
   alguien olvidó el middleware.
2. **La dependencia deja de verse en la firma.** `Create(ctx, item)` parece no
   registrar nada.
3. **Es el `context` como bolsa de parámetros**, que es el ☕ de la Fase 07.

**Qué pensar en su lugar.** Un `*slog.Logger` es **barato de pasar**: es un puntero
a una struct con un manejador. Pasarlo como campo del struct —inyectado en el
constructor— y derivarlo en el borde cubre el 95% de los casos:

```go
// El logger del servicio lleva los atributos del proceso.
// El log de la petición lleva además los suyos, y se pasa donde haga falta.
func (h *Handler) create(w http.ResponseWriter, r *http.Request) {
	log := h.logger.With(slog.String("request_id", reqID))

	item, err := h.svc.Create(r.Context(), req.toDomain())
	if err != nil {
		log.LogAttrs(r.Context(), slog.LevelWarn, "creación rechazada",
			slog.String("reason", err.Error()))
		writeError(w, r, err)
		return
	}
	log.LogAttrs(r.Context(), slog.LevelInfo, "work item creado",
		slog.String(attrWorkItemID, item.ID))
}
```

**Y para lo que de verdad tiene que atravesar todas las capas —el identificador de
traza— la respuesta correcta no es el logger: es el `slog.Handler`.**

```go
// contextHandler saca del contexto los identificadores de correlación y los
// añade a CADA registro, sin que ninguna capa intermedia participe.
//
// Es el MDC hecho bien: el contexto ya viaja por parámetro por decisión de
// diseño (Fase 07), y el manejador lo lee. No hay estado por hilo, no hay
// dependencia oculta, y el `ctx` de LogAttrs deja de ser decorativo.
type contextHandler struct{ slog.Handler }

func (h contextHandler) Handle(ctx context.Context, r slog.Record) error {
	if id := middleware.RequestIDFrom(ctx); id != "" {
		r.AddAttrs(slog.String("request_id", id))
	}
	// Y la correlación con la traza, que es lo que une los tres pilares.
	if sc := trace.SpanContextFromContext(ctx); sc.IsValid() {
		r.AddAttrs(
			slog.String("trace_id", sc.TraceID().String()),
			slog.String("span_id", sc.SpanID().String()),
		)
	}
	return h.Handler.Handle(ctx, r)
}
```

> 🧭 **Regla del proyecto.** El logger se **inyecta**; la correlación se resuelve en
> un `slog.Handler` que lee el contexto. Ninguna capa de negocio saca el logger del
> `context`.

### Métricas RED, y la cardinalidad

```text
RED, para servicios que atienden peticiones:
  Rate      → peticiones por segundo
  Errors    → cuántas fallaron
  Duration  → cuánto tardaron (histograma, no media)

USE, para recursos:
  Utilization, Saturation, Errors
```

```go
var httpRequests = prometheus.NewCounterVec(
	prometheus.CounterOpts{
		Name: "meridian_http_requests_total",
		Help: "Peticiones HTTP atendidas.",
	},
	// ⚠️ LAS ETIQUETAS SON EL PELIGRO. Cada combinación distinta de valores crea
	// una serie temporal nueva, y cada serie consume memoria en Prometheus
	// INDEFINIDAMENTE.
	//
	// Estas tres son seguras porque su cardinalidad está acotada:
	//   method  → ~6 valores
	//   route   → el PATRÓN de ruta, no la ruta concreta: ~15 valores
	//   status  → ~10 valores
	// Total: ~900 series. Perfecto.
	[]string{"method", "route", "status"},
)
```

> ⚠️ **La cardinalidad de etiquetas es la forma más común de tumbar un
> Prometheus**, y el error es siempre el mismo:
>
> ```go
> // ☠️ Con un millón de work items, esto crea UN MILLÓN de series temporales.
> httpRequests.WithLabelValues(r.Method, r.URL.Path, status).Inc()
> //                                     ^^^^^^^^^^^
> //                          /work-items/WI-0001, /work-items/WI-0002, ...
> ```
>
> Prometheus se queda sin memoria, y lo peor es que **no se recupera al arreglar el
> código**: las series viejas viven hasta que expiran, y mientras tanto las
> consultas se degradan para todo el mundo.
>
> **La regla: la etiqueta es el PATRÓN de ruta, nunca la ruta concreta.** Y con el
> `ServeMux` de Go 1.22 eso es fácil, porque el patrón está disponible:
> ```go
> route := r.Pattern   // "GET /work-items/{id}", no "/work-items/WI-0001"
> ```
>
> Lo mismo con el identificador de usuario, el de tienda (140 valores, límite), el
> de socio (30, aceptable), el mensaje de error (**ilimitado, jamás**).

**Y los histogramas, que tienen su propia trampa:**

```go
var httpDuration = prometheus.NewHistogramVec(
	prometheus.HistogramOpts{
		Name: "meridian_http_request_duration_seconds",
		Help: "Duración de las peticiones HTTP.",
		// Cada cubo es UNA SERIE MÁS por combinación de etiquetas. Con 12 cubos
		// y 900 combinaciones son 10.800 series solo de este histograma.
		//
		// Los cubos por defecto de Prometheus están pensados para peticiones de
		// ~100 ms a ~10 s. Los nuestros están calibrados a lo que medimos: la
		// mayoría de nuestras peticiones tardan menos de 100 ms, y sin cubos
		// finos ahí el p50 no se puede calcular.
		Buckets: []float64{
			0.001, 0.005, 0.01, 0.025, 0.05, 0.1, 0.25, 0.5, 1, 2.5, 5, 10,
		},
	},
	[]string{"method", "route"},   // sin `status`: reduce series a la mitad
)
```

📖 El paralelo es Micrometer, y hay una diferencia que conviene saber: el `Timer`
de Micrometer con percentiles publica **percentiles precalculados por instancia**,
que **no se pueden agregar entre instancias** —el p99 de la media de los p99 no
significa nada—. Los histogramas de Prometheus guardan los cubos, y
`histogram_quantile` calcula el percentil **sobre el agregado**, que es lo correcto.
Micrometer también sabe publicar histogramas; hay que pedírselo.

### 🩻 Esto sí funciona igual

- **Los tres pilares son los tres pilares.** La arquitectura de observabilidad no
  cambia de lenguaje.
- **RED y USE** son los mismos marcos, y tu criterio sobre qué medir se traslada
  intacto.
- **La configuración doce-factores** es la misma disciplina: entorno, precedencia,
  validación al arrancar.
- **Health frente a readiness** es la misma distinción, con las mismas
  consecuencias ante un orquestador.
- **Los percentiles, no las medias.** Igual de cierto en los dos sitios.
- **No registrar secretos** es la misma regla, y se incumple igual de a menudo.
- **Las imágenes multi-etapa** son la misma técnica, con el mismo objetivo.
- **`govulncheck` es a Go lo que OWASP Dependency-Check a Java**, y se usa igual.

---

## 🛠️ 5. CLI de la fase

```bash
# Logs: la salida JSON se lee con jq, que es la mitad del valor de estructurarlos.
./bin/opsreport 2>&1 | jq -c 'select(.level == "ERROR")'
./bin/opsreport 2>&1 | jq -c 'select(.request_id == "req-8821")'
./bin/opsreport 2>&1 | jq -r '[.time, .level, .msg, .work_item_id] | @tsv'

# Y la consulta que justifica todo el trabajo de estructurar:
./bin/opsreport 2>&1 | jq -s 'map(select(.status >= 500)) | group_by(.route) |
  map({route: .[0].route, errores: length}) | sort_by(-.errores)'

# Métricas: el endpoint devuelve texto plano en formato de exposición.
curl -s localhost:9090/metrics | head -40
curl -s localhost:9090/metrics | grep -E '^meridian_'

# CONTAR SERIES TEMPORALES, que es el chivato de cardinalidad.
curl -s localhost:9090/metrics | grep -c '^meridian_'

# Y las series por métrica, para encontrar la que se disparó.
curl -s localhost:9090/metrics | grep '^meridian_' | \
  sed 's/{.*//' | sort | uniq -c | sort -rn | head

# Trazas: Jaeger local para verlas.
docker run -d --name jaeger -p 16686:16686 -p 4317:4317 jaegertracing/all-in-one:latest
open http://localhost:16686

# Health y readiness, que responden cosas distintas.
curl -s -o /dev/null -w '%{http_code}\n' localhost:8080/health
curl -s localhost:8080/ready | jq

# Configuración: comprobarla SIN arrancar el servicio es una feature real.
./bin/opsreport --check-config
./bin/opsreport --print-config      # con los secretos redactados

# Imagen: construir, medir y comparar.
docker build -t meridian/opsreport:dev -f Dockerfile .
docker images meridian/opsreport --format '{{.Tag}}\t{{.Size}}'
docker history meridian/opsreport:dev --no-trunc --format '{{.Size}}\t{{.CreatedBy}}' | head

# Inspeccionar una imagen distroless: no tiene shell, así que `docker exec` no
# sirve. Se copia el sistema de archivos y se mira.
docker create --name tmp meridian/opsreport:dev && docker export tmp | tar -tv | head -20
docker rm tmp

# Comprobar que el proceso NO corre como root.
docker run --rm meridian/opsreport:dev --version
docker inspect meridian/opsreport:dev --format '{{.Config.User}}'

# Vulnerabilidades: govulncheck usa la base oficial de Go y —esto es lo
# importante— solo reporta las que tu código PUEDE ALCANZAR, no todas las de tus
# dependencias.
go install golang.org/x/vuln/cmd/govulncheck@latest
govulncheck ./...
govulncheck -show verbose ./...
govulncheck -mode=binary ./bin/opsreport    # sobre el binario compilado

# Escaneo de la imagen, que cubre la parte que govulncheck no ve.
trivy image meridian/opsreport:dev

# Cobertura con umbral que FALLA el build (la deuda de la Fase 00).
make cover-check

# Y el linter con las reglas nuevas de esta fase.
golangci-lint run ./...
```

> 💡 **`govulncheck` frente a un escáner de dependencias normal.** Un escáner
> reporta toda vulnerabilidad conocida en cualquier versión que uses.
> `govulncheck` hace análisis de alcanzabilidad: te dice si **tu código llama** a
> la función vulnerable. La diferencia en la práctica es pasar de cuarenta avisos
> que nadie mira a dos que hay que arreglar hoy.

---

## 💻 6. Construcción guiada

### 6.1 🧨 Rompe a propósito: registra un secreto

**Hazlo antes de leer el resto.**

```go
// services/eventrelay/internal/httpapi/endpoints.go

func (h *EndpointHandler) create(w http.ResponseWriter, r *http.Request) {
	req, err := decodeJSON[createEndpointRequest](w, r)
	if err != nil {
		writeError(w, r, err)
		return
	}

	// "Registro la petición completa para poder depurar."
	h.logger.LogAttrs(r.Context(), slog.LevelInfo, "creando endpoint",
		slog.Any("request", req))       // ☠️ 1

	ep, err := h.svc.Create(r.Context(), req.toDomain())
	if err != nil {
		// "Y el error con todo el contexto."
		h.logger.LogAttrs(r.Context(), slog.LevelError, "no se pudo crear",
			slog.Any("endpoint", ep),   // ☠️ 2
			slog.String("err", err.Error()))
		writeError(w, r, err)
		return
	}
}
```

```bash
curl -X POST localhost:8080/endpoints -d '{
  "partner_name": "PayGate",
  "url": "https://paygate.example.com/hooks",
  "secret": "whsec_9f2a8c1b4e7d6a3f0b5c8e1d4a7f2c9b",
  "event_patterns": ["payment.*"]
}'
```

```json
{"time":"2026-09-12T09:14:22Z","level":"INFO","msg":"creando endpoint",
 "request":{"partner_name":"PayGate","url":"https://paygate.example.com/hooks",
 "secret":"whsec_9f2a8c1b4e7d6a3f0b5c8e1d4a7f2c9b","event_patterns":["payment.*"]}}
```

**Y ahora sigue el rastro de ese secreto**, que es la parte del ejercicio que
importa:

1. **En la salida estándar del contenedor.** Todo el que pueda hacer `docker logs`
   lo ve.
2. **En el agregador de logs**, indexado, buscable, y **retenido treinta o noventa
   días**. Todo el que tenga acceso a los logs —que suele ser mucha más gente que
   la que tiene acceso a la base de datos— lo ve.
3. **En las copias de seguridad del agregador**, más tiempo todavía.
4. **Posiblemente en la traza**, si algún atributo de span lleva el mismo cuerpo.
5. Y si el agregador es un servicio gestionado, **ha salido de tu infraestructura**.

**Rotar ese secreto ahora significa coordinarlo con el socio.** Y saber si alguien
lo usó, mirar accesos de tres meses.

**La defensa, y tiene que ser sistemática, no por buena voluntad:**

```go
// services/shared/logging/redact.go

// redactSensitive se instala en HandlerOptions.ReplaceAttr y se ejecuta para
// CADA atributo de CADA registro.
//
// Que sea sistemático es el punto: confiar en que nadie registre un secreto
// falla el día que alguien añade un campo nuevo. Esto falla hacia el lado
// seguro.
func redactSensitive(groups []string, a slog.Attr) slog.Attr {
	if sensitiveKeys[strings.ToLower(a.Key)] {
		return slog.String(a.Key, "[REDACTADO]")
	}
	// Y la segunda línea de defensa: un valor que PARECE un secreto se redacta
	// aunque la clave no lo diga.
	if s, ok := a.Value.Any().(string); ok && looksLikeSecret(s) {
		return slog.String(a.Key, "[REDACTADO: patrón de secreto]")
	}
	return a
}

var sensitiveKeys = map[string]bool{
	"secret": true, "password": true, "token": true, "authorization": true,
	"api_key": true, "apikey": true, "signature": true, "cookie": true,
	"private_key": true, "dsn": true, "database_url": true, "credentials": true,
}

var secretPatterns = []*regexp.Regexp{
	regexp.MustCompile(`^whsec_[a-f0-9]{32}$`),
	regexp.MustCompile(`^(sk|pk)_(live|test)_[A-Za-z0-9]{20,}$`),
	regexp.MustCompile(`^eyJ[A-Za-z0-9_-]+\.[A-Za-z0-9_-]+\.`),   // JWT
	regexp.MustCompile(`^postgres(ql)?://[^:]+:[^@]+@`),          // DSN con contraseña
}
```

**Y la tercera defensa, la más fuerte: que el tipo no se pueda registrar.**

```go
// Secret es una cadena que NO SE PUEDE IMPRIMIR por accidente.
//
// Implementa Stringer, LogValuer, TextMarshaler y GoStringer. Con los cuatro,
// ni fmt, ni slog, ni encoding/json, ni %#v pueden sacar el valor. Para leerlo
// hay que llamar a Reveal(), que es explícito y se ve en la revisión de código.
//
// 📖 Es el equivalente de envolver el secreto en un tipo con toString()
// sobrescrito en Java, y aquí es más completo porque LogValuer es un gancho
// específico de slog.
type Secret string

func (Secret) String() string                  { return "[REDACTADO]" }
func (Secret) GoString() string                { return `"[REDACTADO]"` }
func (Secret) LogValue() slog.Value            { return slog.StringValue("[REDACTADO]") }
func (Secret) MarshalText() ([]byte, error)    { return []byte("[REDACTADO]"), nil }
func (s Secret) Reveal() string                { return string(s) }
```

```go
type Endpoint struct {
	ID          string
	PartnerName string
	URL         string
	Secret      Secret   // ← ya no se puede registrar por accidente
}
```

```json
{"msg":"creando endpoint","request":{"partner_name":"PayGate",
 "url":"https://paygate.example.com/hooks","secret":"[REDACTADO]"}}
```

> 🧭 **Regla del proyecto: tres capas, y las tres se implementan.** (1) El tipo
> `Secret` para lo que sabemos que es secreto. (2) `ReplaceAttr` por nombre de
> clave, para lo que llegue de fuera. (3) La detección por patrón, para lo que no
> previmos. Y un test que las verifica las tres.

### 6.2 Mini proyecto: `slog-lab`

El logging completo de los cuatro servicios, con la comparación que la Fase 03
prometió.

**La deuda de la Fase 03, pagada. Las dos salidas, lado a lado:**

```text
# ANTES — log.Printf, el logger provisional de la Fase 03
2026/09/12 09:14:22 req-8821 POST /work-items 201 312B 4.21ms
2026/09/12 09:14:23 error al guardar WI-0042: pq: duplicate key value
```

```json
# DESPUÉS — slog con JSONHandler
{"time":"2026-09-12T09:14:22.118Z","level":"INFO","msg":"petición servida",
 "service":"opsreport","version":"1.4.0","env":"prod","request_id":"req-8821",
 "trace_id":"4bf92f3577b34da6a3ce929d0e0e4736","method":"POST",
 "route":"POST /work-items","status":201,"bytes":312,"duration_ms":4.21}
{"time":"2026-09-12T09:14:23.004Z","level":"ERROR","msg":"no se pudo guardar el work item",
 "service":"opsreport","request_id":"req-8822","work_item_id":"WI-0042",
 "error":"pq: duplicate key value","error_code":"23505"}
```

**Lo que se gana, dicho como consultas concretas:**

| Pregunta | Con `log.Printf` | Con `slog` |
|---|---|---|
| ¿Cuántos 5xx hubo ayer por ruta? | expresión regular frágil | `status >= 500 \| group by route` |
| ¿Qué pasó en la petición `req-8821`? | `grep`, si el id está en todas las líneas | filtro por `request_id` |
| ¿Qué versión del servicio produjo este error? | **no está** | `version` |
| Latencia p99 de `POST /work-items` | imposible | del campo `duration_ms` |
| Correlacionar con la traza | **imposible** | `trace_id` |
| Filtrar por entorno en un índice compartido | frágil | `env` |

**Y lo que se pierde**, porque también hay algo:

- **La legibilidad en una terminal.** Una línea JSON de 400 caracteres es ilegible
  para un humano. Por eso el formato es configurable y en desarrollo se usa
  `TextHandler`.
- **Rendimiento.** `slog` con `JSONHandler` hace más trabajo que `log.Printf`:
  serializa a JSON en vez de concatenar, y **`slog.Any` pasa por reflexión mientras
  que los atributos tipados (`slog.String`, `slog.Int`) no**. Esa es la diferencia
  estructural, y es lo único que el curso afirma aquí: **cuánto cuesta no está
  medido en esta fase**. La fila de logging de **B-28** (Fase 15) lo cuantifica
  dentro de la cadena de middleware, y el ejercicio 23 de esa fase lo extiende a
  `slog.Any` y a la forma variádica.

**La política de niveles del curso, que hay que fijar o cada uno usa el suyo:**

```go
// DEBUG — detalle de diagnóstico. APAGADO en producción.
//         Se enciende por servicio y por un rato. Nunca en un bucle caliente.
//
// INFO  — eventos de negocio que un operador querría ver: work item creado,
//         lote iniciado, ingesta completada. NO "entrando en función X".
//
// WARN  — algo salió mal Y SE RECUPERÓ: reintento, caché no disponible,
//         movimiento omitido. Requiere atención si se repite.
//
// ERROR — algo salió mal y NO se recuperó: la petición falló, el lote abortó.
//         Cada ERROR debería ser accionable.
//
// ⚠️ La regla que evita el ruido: un error que se maneja y se devuelve al
// llamador NO se registra en el nivel donde ocurre, porque se registraría otra
// vez arriba. Se registra UNA VEZ, en el borde que decide qué hacer con él.
```

> ⚠️ **El error registrado tres veces** es el antipatrón de logging más común. El
> almacén lo registra, el servicio lo registra al recibirlo, y el handler lo
> registra al traducirlo. Resultado: tres entradas del mismo incidente, con tres
> mensajes distintos, y un recuento de errores multiplicado por tres. **Se registra
> donde se decide, no donde se detecta.**

### 6.3 Mini proyecto: `metrics-lab`

```go
// services/shared/metrics/http.go

// Metrics agrupa las métricas RED de un servicio HTTP.
type Metrics struct {
	requests  *prometheus.CounterVec
	duration  *prometheus.HistogramVec
	inFlight  prometheus.Gauge
	reqSize   *prometheus.HistogramVec
	respSize  *prometheus.HistogramVec
}

// Middleware instrumenta un handler.
func (m *Metrics) Middleware(next http.Handler) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		m.inFlight.Inc()
		defer m.inFlight.Dec()

		start := time.Now()
		rec := &statusRecorder{ResponseWriter: w}

		next.ServeHTTP(rec, r)

		// EL PATRÓN DE RUTA, no la ruta. Con el ServeMux de 1.22 está
		// disponible en r.Pattern, y eso resuelve el problema de cardinalidad
		// sin trabajo extra.
		route := r.Pattern
		if route == "" {
			// Una petición que no casó con ninguna ruta: se agrupa en una
			// etiqueta fija. Sin esto, un escáner de vulnerabilidades probando
			// diez mil rutas crea diez mil series.
			route = "unmatched"
		}

		status := strconv.Itoa(rec.status)
		m.requests.WithLabelValues(r.Method, route, status).Inc()
		m.duration.WithLabelValues(r.Method, route).Observe(time.Since(start).Seconds())
	})
}
```

**Y las métricas de negocio, que son las que de verdad se miran en un incidente:**

```go
// services/clearinghouse/internal/metrics/batch.go

var (
	// El progreso del lote, consultable como métrica en vez de solo por API.
	batchProgress = prometheus.NewGaugeVec(
		prometheus.GaugeOpts{
			Name: "meridian_batch_progress_ratio",
			Help: "Fracción completada del lote en curso.",
		},
		[]string{"batch_type"},   // 2 valores, no el id del lote
	)

	// La ecuación de la Fase 13, expuesta como métrica. Un lote que no cuadra
	// se ve aquí antes de que alguien mire el informe.
	batchMovements = prometheus.NewCounterVec(
		prometheus.CounterOpts{
			Name: "meridian_batch_movements_total",
			Help: "Movimientos procesados por el cierre, por resultado.",
		},
		[]string{"outcome"},   // reconciled | skipped | failed
	)

	// La antigüedad del outbox pendiente: LA MÉTRICA que dice si el despachador
	// va bien. Si crece, algo está atascado, y se ve antes de que un socio se
	// queje.
	outboxOldestPending = prometheus.NewGauge(
		prometheus.GaugeOpts{
			Name: "meridian_outbox_oldest_pending_seconds",
			Help: "Antigüedad del evento pendiente más viejo del outbox.",
		},
	)

	// LOS CONTADORES DE LA FASE 12, EXPORTADOS TAL CUAL.
	//
	// AtlasSync ya lleva doce fases contando aciertos y fallos de caché en
	// memoria, y la tentación aquí es inventar métricas nuevas "bien nombradas".
	// No: se exportan LAS QUE YA EXISTEN. Dos fuentes para el mismo número es
	// cómo se llega a un panel que contradice a otro panel.
	cacheRequests = prometheus.NewCounterVec(
		prometheus.CounterOpts{
			Name: "meridian_cache_requests_total",
			Help: "Consultas a la caché, por resultado.",
		},
		[]string{"cache", "result"},   // result: hit | miss | error
	)

	// La tasa de acierto NO se exporta como gauge: se calcula en Prometheus con
	// rate() sobre el contador. Un gauge de porcentaje calculado en el proceso
	// miente en cuanto hay más de una réplica, porque promediar porcentajes de
	// réplicas con tráfico distinto no da el porcentaje global.
	cacheOrigin = prometheus.NewHistogramVec(
		prometheus.HistogramOpts{
			Name:    "meridian_cache_origin_duration_seconds",
			Help:    "Latencia de la consulta al origen cuando la caché falla.",
			Buckets: prometheus.DefBuckets,
		},
		[]string{"cache"},
	)
)
```

> ⚠️ **La caché es la métrica que más se inventa dos veces.** La Fase 12 dejó los
> contadores escritos y dijo explícitamente que esta fase los exportara. Si aquí
> defines unos nuevos, acabas con `cache_hits` en el código de AtlasSync y
> `meridian_cache_requests_total{result="hit"}` en el panel, midiendo lo mismo
> desde sitios distintos y divergiendo en cuanto alguien toque uno. **Exporta los
> que existen; si no te gusta cómo se llaman, renómbralos en la Fase 12.**

> 🧭 **Regla del proyecto.** Las métricas técnicas (RED) dicen si el sistema está
> sano; **las de negocio dicen si está haciendo su trabajo**. Un servicio con 0%
> de errores HTTP y el outbox atascado desde hace cuatro horas está roto, y solo la
> segunda lo ve.

**El endpoint, en su propio puerto:**

```go
// ⚠️ /metrics NO va en el puerto público.
//
// Expone la lista de rutas —incluidas las internas—, los nombres de las métricas
// de negocio, los volúmenes de operación y, con frecuencia, información que
// ayuda a un atacante a entender el sistema. Va en un puerto de administración
// que solo alcanza la red interna.
//
// Y en ese mismo puerto van /debug/pprof (Fase 07 y 15), por la misma razón y
// con más motivo: el perfil de heap puede contener datos de peticiones.
func newAdminServer(cfg Config, reg *prometheus.Registry) *http.Server {
	mux := http.NewServeMux()
	mux.Handle("GET /metrics", promhttp.HandlerFor(reg, promhttp.HandlerOpts{}))
	mux.HandleFunc("GET /debug/pprof/", pprof.Index)
	mux.HandleFunc("GET /debug/pprof/profile", pprof.Profile)
	mux.HandleFunc("GET /debug/pprof/heap", pprof.Handler("heap").ServeHTTP)
	// ...

	return &http.Server{
		Addr:              cfg.AdminAddr,   // ":9090", interno
		Handler:           mux,
		ReadHeaderTimeout: 5 * time.Second,
	}
}
```

### 6.4 Trazas con OpenTelemetry

```go
// services/shared/tracing/tracing.go

func Setup(ctx context.Context, cfg Config) (func(context.Context) error, error) {
	exporter, err := otlptracegrpc.New(ctx,
		otlptracegrpc.WithEndpoint(cfg.OTLPEndpoint),
		otlptracegrpc.WithInsecure(),
	)
	if err != nil {
		return nil, fmt.Errorf("creando el exportador OTLP: %w", err)
	}

	res, err := resource.New(ctx,
		resource.WithAttributes(
			semconv.ServiceName(cfg.ServiceName),
			semconv.ServiceVersion(buildVersion),
			semconv.DeploymentEnvironment(cfg.Environment),
		),
	)
	if err != nil {
		return nil, fmt.Errorf("creando el recurso: %w", err)
	}

	tp := sdktrace.NewTracerProvider(
		sdktrace.WithBatcher(exporter),
		sdktrace.WithResource(res),
		// EL MUESTREO. Trazar el 100% del tráfico es caro en red, en
		// almacenamiento y en factura. ParentBased respeta la decisión del
		// servicio que originó la petición: si el borde decidió trazar, todos
		// los saltos siguientes trazan, y así la traza queda completa.
		//
		// Muestrear independientemente en cada servicio produce trazas rotas,
		// que son peores que ninguna.
		sdktrace.WithSampler(
			sdktrace.ParentBased(sdktrace.TraceIDRatioBased(cfg.TraceSampleRatio)),
		),
	)

	otel.SetTracerProvider(tp)
	// El propagador decide CÓMO viajan los identificadores entre servicios.
	// W3C TraceContext es el estándar; B3 es el de Zipkin y lo usa mucho
	// software Java más antiguo. Poner los dos cuesta nada y evita trazas rotas
	// al integrar con un sistema que use el otro.
	otel.SetTextMapPropagator(propagation.NewCompositeTextMapPropagator(
		propagation.TraceContext{},
		propagation.Baggage{},
	))

	return tp.Shutdown, nil
}
```

```go
// La instrumentación, que es casi toda automática:

// Servidor HTTP: un middleware.
handler = otelhttp.NewHandler(handler, "meridian",
	otelhttp.WithSpanNameFormatter(func(_ string, r *http.Request) string {
		return r.Pattern   // el patrón, otra vez: cardinalidad
	}))

// Cliente HTTP: un Transport envuelto.
client.Transport = otelhttp.NewTransport(client.Transport)

// Base de datos: un driver envuelto.
db, err := otelsql.Open("pgx", dsn, otelsql.WithAttributes(semconv.DBSystemPostgreSQL))
```

**Y los spans manuales, donde aportan:**

```go
func (s *Service) processChunk(ctx context.Context, batch *Batch) (int, error) {
	ctx, span := s.tracer.Start(ctx, "batch.process_chunk",
		trace.WithAttributes(
			attribute.String("batch.id", batch.ID),
			attribute.Int("chunk.size", s.chunkSize),
			// ⚠️ Los atributos de span tienen el MISMO problema de cardinalidad
			// que las etiquetas de métrica, con un matiz: aquí es aceptable
			// poner el id del lote, porque los spans NO crean series
			// temporales — son eventos. La confusión entre las dos cosas es
			// habitual y conviene tenerla clara.
		))
	defer span.End()

	// ...

	if err != nil {
		// RecordError guarda el error en el span; SetStatus lo marca como
		// fallido para que la interfaz lo resalte. Hacen cosas distintas y hay
		// que hacer las dos.
		span.RecordError(err)
		span.SetStatus(codes.Error, "el fragmento falló")
		return 0, err
	}

	span.SetAttributes(attribute.Int("chunk.processed", len(movements)))
	return len(movements), nil
}
```

> 🧭 **Regla del proyecto.** Se instrumenta automáticamente el borde —HTTP entrante
> y saliente, base de datos— y **a mano solo lo que tiene significado de negocio**:
> un fragmento del lote, una ingesta, una entrega. Un span por función produce
> trazas de doscientos spans que nadie lee y una factura considerable.

### 6.5 Health y readiness: la diferencia que importa

```go
// /health — ¿está vivo el PROCESO?
//
// Responde 200 si el proceso puede atender. NO consulta dependencias.
// El orquestador usa esto para decidir si REINICIAR el contenedor.
//
// ⚠️ Si /health consultara la base de datos, una caída de la base reiniciaría
// TODOS los contenedores en bucle, convirtiendo una degradación en una caída
// total — y además impidiendo que el servicio sirva lo que sí podría servir
// desde caché.
func (h *HealthHandler) health(w http.ResponseWriter, r *http.Request) {
	writeJSON(w, http.StatusOK, map[string]string{
		"status":  "ok",
		"version": buildVersion,
	})
}

// /ready — ¿puede este proceso atender tráfico AHORA?
//
// Sí consulta dependencias. El orquestador usa esto para decidir si MANDARLE
// TRÁFICO. Un servicio con la base caída responde 503 aquí, deja de recibir
// tráfico, y NO se reinicia.
//
// ⚠️ Y AQUÍ EL ATAQUE DE DENEGACIÓN DE SERVICIO QUE TE HACES A TI MISMO: si
// /ready ejecuta un SELECT en cada petición y el orquestador lo llama cada
// segundo por cada una de las seis réplicas, son seis consultas por segundo
// permanentes. Con veinte servicios, ciento veinte. Y cuando la base se pone
// lenta, los sondeos de readiness la rematan.
//
// La defensa: CACHEAR el resultado unos segundos.
func (h *HealthHandler) ready(w http.ResponseWriter, r *http.Request) {
	result := h.checker.Check(r.Context())   // cacheado 5 s

	status := http.StatusOK
	if !result.Ready {
		status = http.StatusServiceUnavailable
	}
	writeJSON(w, status, result)
}
```

```go
// Checker ejecuta las comprobaciones con caché y con plazo.
type Checker struct {
	checks map[string]CheckFunc
	ttl    time.Duration

	mu     sync.RWMutex
	cached Result
	at     time.Time
}

func (c *Checker) Check(ctx context.Context) Result {
	c.mu.RLock()
	if time.Since(c.at) < c.ttl {
		defer c.mu.RUnlock()
		return c.cached
	}
	c.mu.RUnlock()

	// Plazo corto y propio: una comprobación de readiness que tarda cinco
	// segundos es inútil, porque el orquestador ya se rindió.
	ctx, cancel := context.WithTimeout(ctx, 2*time.Second)
	defer cancel()

	result := Result{Ready: true, Checks: make(map[string]CheckResult, len(c.checks))}

	// En paralelo: N comprobaciones secuenciales suman sus latencias.
	var wg sync.WaitGroup
	var mu sync.Mutex

	for name, fn := range c.checks {
		wg.Add(1)
		go func(name string, fn CheckFunc) {
			defer wg.Done()
			start := time.Now()
			err := fn(ctx)

			mu.Lock()
			defer mu.Unlock()
			cr := CheckResult{DurationMS: time.Since(start).Milliseconds()}
			if err != nil {
				cr.Status, cr.Error = "fail", err.Error()
				// ⚠️ Una dependencia OPCIONAL que falla NO debe marcar el
				// servicio como no listo. Si Valkey cae y el servicio funciona
				// sin caché (Fase 12), readiness sigue en verde.
				if c.required[name] {
					result.Ready = false
				}
			} else {
				cr.Status = "ok"
			}
			result.Checks[name] = cr
		}(name, fn)
	}
	wg.Wait()

	c.mu.Lock()
	c.cached, c.at = result, time.Now()
	c.mu.Unlock()

	return result
}
```

```json
{
  "ready": true,
  "checks": {
    "postgres": {"status": "ok",   "duration_ms": 2},
    "valkey":   {"status": "fail", "duration_ms": 2001,
                 "error": "context deadline exceeded"},
    "mongo":    {"status": "ok",   "duration_ms": 4}
  }
}
```

📖 Es Actuator con `/actuator/health` y sus `HealthIndicator`, incluida la
distinción de grupos (`liveness` y `readiness`) que Spring Boot añadió en la 2.3
precisamente por este problema. **El modelo es el mismo; aquí se escribe y por eso
decides tú qué es obligatorio y qué opcional** — que es exactamente la decisión que
más se equivoca en las configuraciones por defecto.

### 6.6 Configuración: la deuda del `Makefile` y el fallo rápido

**La configuración de la Fase 03, terminada:**

```go
// services/shared/config/config.go

// Load construye la configuración con la precedencia del curso:
//
//   valores por defecto  <  archivo  <  variables de entorno  <  banderas
//
// Las banderas ganan porque son lo más explícito y lo que un operador usa para
// una ejecución puntual.
func Load(args []string) (Config, error) { /* ... */ }

// Validate comprueba TODO y devuelve TODOS los problemas (Fase 03).
func (c Config) Validate() error {
	var problems []string

	// ... las validaciones de la Fase 03 ...

	// Y las nuevas, que son de coherencia entre campos y son las que más
	// incidentes evitan:

	// El plazo de apagado tiene que caber en el periodo de gracia del
	// orquestador. El valor por defecto de facto son 30 s.
	//
	// ⚠️ Y el margen no es arbitrario: sale de B-20 (Fase 13), que midió la
	// latencia de cancelación del lote en función del tamaño de fragmento.
	if c.ShutdownTimeout >= 30*time.Second {
		problems = append(problems, fmt.Sprintf(
			"shutdown_timeout (%s) debe ser menor que el periodo de gracia (30s) con margen",
			c.ShutdownTimeout))
	}

	// El plazo del cliente HTTP tiene que ser menor que el del servidor, o el
	// cliente espera respuestas que el servidor ya abandonó.
	if c.HTTPClientTimeout >= c.WriteTimeout {
		problems = append(problems, fmt.Sprintf(
			"http_client_timeout (%s) debe ser menor que write_timeout (%s)",
			c.HTTPClientTimeout, c.WriteTimeout))
	}

	// El presupuesto de conexiones (Fase 09, ejercicio 29).
	if c.DBMaxOpenConns*c.ExpectedReplicas > c.DBServerMaxConnections {
		problems = append(problems, fmt.Sprintf(
			"db_max_open_conns (%d) × réplicas (%d) = %d supera max_connections del servidor (%d)",
			c.DBMaxOpenConns, c.ExpectedReplicas,
			c.DBMaxOpenConns*c.ExpectedReplicas, c.DBServerMaxConnections))
	}

	// En producción, exigencias que en desarrollo son opcionales.
	if c.Environment == "prod" {
		if c.LogFormat != "json" {
			problems = append(problems, "en prod, log_format debe ser json")
		}
		if c.LogLevel == "debug" {
			problems = append(problems, "en prod, log_level no puede ser debug")
		}
		if c.AdminAddr == c.HTTPAddr {
			problems = append(problems,
				"en prod, admin_addr no puede ser el mismo puerto que http_addr: expondría /metrics y /debug/pprof")
		}
	}

	if len(problems) > 0 {
		return &ConfigError{Problems: problems}
	}
	return nil
}
```

> 🧭 **Regla del proyecto: `--check-config` es un objetivo del despliegue.** El
> binario puede validar su configuración **sin arrancar**, y eso permite
> comprobarla en el pipeline antes de desplegar. Es de las cosas más baratas de
> implementar y de las que más incidentes evitan.

**Y el `Makefile`, que lleva catorce fases con rutas fijas y sin validación:**

```makefile
# Makefile — la deuda de la Fase 00, pagada.

GO         ?= go
SERVICES   := opsreport eventrelay atlassync clearinghouse storeagent
COVER_MIN  ?= 80
VERSION    ?= $(shell git describe --tags --always --dirty)
COMMIT     ?= $(shell git rev-parse --short HEAD)
BUILD_DATE ?= $(shell date -u +%Y-%m-%dT%H:%M:%SZ)

LDFLAGS := -s -w \
  -X main.version=$(VERSION) \
  -X main.commit=$(COMMIT) \
  -X main.buildDate=$(BUILD_DATE)

.PHONY: build
build: ## Compila un servicio: make build SVC=opsreport
ifndef SVC
	$(error SVC no está definido. Uso: make build SVC=<$(SERVICES)>)
endif
ifeq ($(filter $(SVC),$(SERVICES)),)
	$(error SVC="$(SVC)" no es válido. Opciones: $(SERVICES))
endif
	CGO_ENABLED=0 $(GO) build -trimpath -ldflags "$(LDFLAGS)" \
		-o bin/$(SVC) ./services/$(SVC)/cmd/$(SVC)

.PHONY: cover-check
cover-check: ## Cobertura CON UMBRAL QUE FALLA EL BUILD (deuda de la Fase 00)
	$(GO) test -race -covermode=atomic -coverprofile=cover.out ./services/*/internal/...
	@total=$$($(GO) tool cover -func=cover.out | tail -1 | awk '{print substr($$3, 1, length($$3)-1)}'); \
	echo "cobertura: $$total% (mínimo $(COVER_MIN)%)"; \
	if [ $$(echo "$$total < $(COVER_MIN)" | bc -l) -eq 1 ]; then \
		echo "❌ cobertura por debajo del umbral"; \
		$(GO) tool cover -func=cover.out | sort -k3 -n | head -15; \
		exit 1; \
	fi

.PHONY: check-config
check-config: ## Valida la configuración de todos los servicios sin arrancarlos
	@for svc in $(SERVICES); do \
		echo "→ $$svc"; ./bin/$$svc --check-config || exit 1; \
	done

.PHONY: vuln
vuln: ## Vulnerabilidades alcanzables
	govulncheck ./...

.PHONY: ci
ci: fmt vet lint test-race cover-check vuln ## Todo lo que CI ejecuta

.PHONY: hooks
hooks: ## Instala el hook de pre-commit (deuda de la Fase 00)
	git config core.hooksPath .githooks
	@echo "hooks instalados: $$(git config core.hooksPath)"
```

**Y el hook, que es la última deuda que la Fase 00 dejó abierta:**

```bash
# .githooks/pre-commit
#!/usr/bin/env bash
set -euo pipefail

# Rápido a propósito. Un hook que tarda más de unos segundos se termina saltando
# con --no-verify, y un hook que se salta no existe. Lo lento (los tests con
# -race, la cobertura, govulncheck) es trabajo de `make ci`, no de aquí.

# 1. Formato: sobre los archivos en el índice, no sobre todo el repositorio.
staged=$(git diff --cached --name-only --diff-filter=ACM -- '*.go')
[ -z "$staged" ] && exit 0

unformatted=$(gofmt -l $staged)
if [ -n "$unformatted" ]; then
  echo "❌ sin formatear:"; echo "$unformatted"
  echo "   corrige con: gofmt -w $unformatted"
  exit 1
fi

# 2. go vet sobre los paquetes tocados.
pkgs=$(echo "$staged" | xargs -n1 dirname | sort -u | sed 's|^|./|')
go vet $pkgs

# 3. El linter, solo sobre el diff. --new-from-rev evita que el hook te bloquee
#    por deuda que ya estaba ahí antes de tu commit.
golangci-lint run --new-from-rev=HEAD --fix=false $pkgs
```

```bash
chmod +x .githooks/pre-commit
make hooks
```

> 🧭 **`core.hooksPath` en vez de `.git/hooks/`.** Los hooks de `.git/hooks/` no se
> versionan y cada persona del equipo tiene los suyos, que es como no tener
> ninguno. `core.hooksPath` apunta a un directorio del repositorio, así que el hook
> se revisa en un PR como cualquier otro código. El precio es que cada clon tiene
> que ejecutar `make hooks` una vez, y por eso está en el `Makefile` y no en un
> README que nadie lee.

> ⚠️ **Un hook no sustituye a CI, y creerlo es el error.** Cualquiera puede pasar
> `--no-verify`, y hay que poder: a veces necesitas commitear roto en tu rama. El
> hook está para ahorrarte el viaje de ida y vuelta al pipeline por una errata de
> formato, no para ser la puerta. **La puerta es `make ci`**, que corre en el
> servidor, donde nadie puede saltársela.

> 💡 **`-trimpath` es la bandera que casi nadie pone y debería.** Quita las rutas
> absolutas de compilación del binario. Sin ella, tu binario de producción contiene
> `/Users/tu/dev/meridian/...` en cada volcado de pila y en los metadatos:
> filtra la estructura de tu máquina y hace las compilaciones no reproducibles.

### 6.7 SSRF: la deuda más vieja del curso

**Declarada en la Fase 02, doce fases atrás. Hoy se paga.**

**El ataque.** Un socio registra un endpoint con esta URL:

```text
http://169.254.169.254/latest/meta-data/iam/security-credentials/
```

EventRelay hace `POST` ahí con el payload del evento. Esa dirección es el servicio
de metadatos de la nube, accesible **solo desde dentro de la instancia**, y devuelve
credenciales. Si el socio puede leer la respuesta —o el cuerpo de la respuesta acaba
en el historial de intentos, que es exactamente lo que EventRelay guarda—, acaba de
extraer credenciales de tu infraestructura usando tu propio servicio como proxy.

Y hay más objetivos: `http://localhost:5432` (PostgreSQL), `http://10.0.0.5:9090`
(las métricas internas del §6.3), `http://[::1]:6379` (Valkey).

**Y la trampa: validar la URL no basta.**

```go
// ❌ Esto NO protege. Tres formas de saltárselo:
//
//  1. DNS que resuelve a una IP privada: el atacante controla
//     evil.example.com y le pone un registro A apuntando a 169.254.169.254.
//     La URL parece perfectamente pública.
//
//  2. Redirección: la URL pública responde 302 hacia la interna. Por eso el
//     cliente de la Fase 10 tiene CheckRedirect devolviendo ErrUseLastResponse —
//     esa decisión, que entonces pareció una precaución menor, es media defensa.
//
//  3. DNS rebinding: el nombre resuelve a una IP pública en la comprobación y a
//     una privada en la conexión, porque son DOS resoluciones distintas. Es la
//     condición de carrera TOCTOU aplicada al DNS, y es la razón por la que la
//     comprobación tiene que estar EN el momento de conectar.
func validateURLNaive(raw string) error {
	u, err := url.Parse(raw)
	if err != nil || u.Scheme != "https" {
		return ErrInsecureURL
	}
	ips, _ := net.LookupIP(u.Hostname())
	for _, ip := range ips {
		if ip.IsPrivate() || ip.IsLoopback() {
			return ErrPrivateAddress   // ← se comprueba aquí y se conecta después
		}
	}
	return nil
}
```

**La defensa correcta: el control va en el `DialContext`**, donde ya se conoce la
IP a la que se va a conectar de verdad.

```go
// services/eventrelay/internal/safehttp/dialer.go

// SafeDialer rechaza conexiones a direcciones no públicas EN EL MOMENTO DE
// CONECTAR.
//
// Es la única defensa correcta contra SSRF con DNS rebinding: la comprobación
// ocurre sobre la IP que se va a usar, no sobre una resolución anterior que ya
// puede haber cambiado.
type SafeDialer struct {
	dialer  *net.Dialer
	allowed []netip.Prefix   // lista blanca opcional, para entornos con excepciones
}

func (d *SafeDialer) DialContext(ctx context.Context, network, addr string) (net.Conn, error) {
	host, port, err := net.SplitHostPort(addr)
	if err != nil {
		return nil, fmt.Errorf("dirección inválida %q: %w", addr, err)
	}

	// Resolver AQUÍ, y usar EXACTAMENTE estas IPs para conectar.
	ips, err := d.dialer.Resolver.LookupNetIP(ctx, "ip", host)
	if err != nil {
		return nil, fmt.Errorf("no se pudo resolver %q: %w", host, err)
	}

	var lastErr error
	for _, ip := range ips {
		if err := d.checkIP(ip); err != nil {
			lastErr = err
			continue
		}
		// Se conecta a la IP COMPROBADA, no al nombre. Eso cierra la ventana
		// entre la comprobación y la conexión.
		conn, err := d.dialer.DialContext(ctx, network, net.JoinHostPort(ip.String(), port))
		if err != nil {
			lastErr = err
			continue
		}
		return conn, nil
	}
	if lastErr == nil {
		lastErr = fmt.Errorf("%w: %s no resolvió a ninguna dirección permitida", ErrBlockedAddress, host)
	}
	return nil, lastErr
}

// checkIP rechaza todo lo que no sea unicast público.
func (d *SafeDialer) checkIP(ip netip.Addr) error {
	// La lista blanca primero: en desarrollo, fakeconsumer vive en localhost.
	for _, p := range d.allowed {
		if p.Contains(ip) {
			return nil
		}
	}

	switch {
	case ip.IsLoopback():                    // 127.0.0.0/8, ::1
		return fmt.Errorf("%w: loopback %s", ErrBlockedAddress, ip)
	case ip.IsPrivate():                     // 10/8, 172.16/12, 192.168/16, fc00::/7
		return fmt.Errorf("%w: rango privado %s", ErrBlockedAddress, ip)
	case ip.IsLinkLocalUnicast():            // 169.254/16 ← LOS METADATOS DE LA NUBE
		return fmt.Errorf("%w: link-local %s", ErrBlockedAddress, ip)
	case ip.IsLinkLocalMulticast(), ip.IsInterfaceLocalMulticast(), ip.IsMulticast():
		return fmt.Errorf("%w: multicast %s", ErrBlockedAddress, ip)
	case ip.IsUnspecified():                 // 0.0.0.0, ::
		return fmt.Errorf("%w: no especificada %s", ErrBlockedAddress, ip)
	}

	// Y los rangos que Go no clasifica y hay que añadir a mano.
	for _, p := range extraBlocked {
		if p.Contains(ip) {
			return fmt.Errorf("%w: rango reservado %s (%s)", ErrBlockedAddress, ip, p)
		}
	}
	return nil
}

var extraBlocked = []netip.Prefix{
	netip.MustParsePrefix("100.64.0.0/10"),   // CGNAT (RFC 6598)
	netip.MustParsePrefix("192.0.0.0/24"),    // IETF protocol assignments
	netip.MustParsePrefix("192.0.2.0/24"),    // TEST-NET-1
	netip.MustParsePrefix("198.18.0.0/15"),   // benchmarking
	netip.MustParsePrefix("198.51.100.0/24"), // TEST-NET-2
	netip.MustParsePrefix("203.0.113.0/24"),  // TEST-NET-3
	netip.MustParsePrefix("240.0.0.0/4"),     // reservado
	netip.MustParsePrefix("::ffff:0:0/96"),   // IPv4 mapeada en IPv6 ← se olvida siempre
	netip.MustParsePrefix("64:ff9b::/96"),    // NAT64
}
```

> ⚠️ **`::ffff:169.254.169.254` es la evasión que se olvida.** Es la dirección
> IPv4 de los metadatos escrita como IPv6 mapeada. Si tu comprobación solo mira
> IPv4, pasa limpia. Por eso el prefijo `::ffff:0:0/96` está en la lista y por eso
> el ejercicio 20 lo verifica.

**Y las tres defensas que lo acompañan:**

```go
// 1. Sin redirecciones. Ya estaba en la Fase 10; aquí se explica su porqué real.
CheckRedirect: func(req *http.Request, via []*http.Request) error {
	return http.ErrUseLastResponse
},

// 2. El cuerpo de la respuesta NO se guarda entero en el historial de intentos.
//    Con SSRF mitigado sigue siendo mala idea: la respuesta de un socio puede
//    contener datos que no queremos retener.
const maxStoredResponseBytes = 512

// 3. La validación de la URL AL REGISTRAR el endpoint sigue existiendo, como
//    primera línea: da un error claro al socio en vez de fallar en la primera
//    entrega. Pero NO es la defensa; la defensa es el dialer.
```

> 🧭 **Regla del proyecto.** **La validación en el borde da buenos mensajes; la
> defensa va en el punto de uso.** Es la misma lección que la idempotencia de la
> Fase 12 —Valkey optimiza, la restricción única garantiza— aplicada a la
> seguridad.

### 6.8 La firma HMAC, verificada

**La deuda de la Fase 10.**

```go
// services/eventrelay/internal/signature/verify.go

// Verify comprueba la firma de una petición entrante.
//
// Está escrita para el lado receptor —el socio— y va en la documentación de
// integración, porque es el código que ellos tienen que escribir. Meridian la
// usa para el fakeconsumer y para los tests.
func Verify(secret Secret, header, timestampHeader string, body []byte, now time.Time, tolerance time.Duration) error {
	ts, err := strconv.ParseInt(timestampHeader, 10, 64)
	if err != nil {
		return fmt.Errorf("%w: timestamp inválido", ErrInvalidSignature)
	}

	// LA VENTANA DE VALIDEZ, que es lo que impide el ataque de REPETICIÓN.
	//
	// Sin ella, alguien que capture una petición válida puede reenviarla
	// indefinidamente: la firma sigue siendo correcta porque el cuerpo no
	// cambió.
	//
	// La comprobación es en VALOR ABSOLUTO: un timestamp del futuro también se
	// rechaza, porque indica un reloj desviado o un intento de alargar la
	// ventana.
	age := now.Sub(time.Unix(ts, 0))
	if age < 0 {
		age = -age
	}
	if age > tolerance {
		return fmt.Errorf("%w: timestamp fuera de la ventana de %s (desvío %s)",
			ErrInvalidSignature, tolerance, age.Round(time.Second))
	}

	expected := Sign(secret, time.Unix(ts, 0), body)

	// ⚠️ hmac.Equal Y NO ==.
	//
	// La comparación de cadenas de Go sale en cuanto encuentra el primer byte
	// distinto. Eso hace que el TIEMPO de la comparación dependa de cuántos
	// bytes iniciales acertó el atacante, y con suficientes intentos se puede
	// deducir la firma byte a byte. Es un ataque temporal, es real, y se ha
	// usado.
	//
	// hmac.Equal compara en tiempo constante: siempre recorre todo.
	if !hmac.Equal([]byte(expected), []byte(header)) {
		return ErrInvalidSignature
	}
	return nil
}
```

> 🧪 **Prueba de fuego.** Demuestra el ataque temporal con un benchmark:
> ```go
> func BenchmarkNaiveCompare(b *testing.B) {
>     correct := "v1=" + strings.Repeat("a", 64)
>     for _, guess := range []string{
>         "v1=" + strings.Repeat("b", 64),           // falla en el byte 3
>         "v1=" + strings.Repeat("a", 32) + strings.Repeat("b", 32), // en el 35
>     } {
>         b.Run(guess[:10], func(b *testing.B) {
>             for b.Loop() { _ = correct == guess }
>         })
>     }
> }
> ```
> Con cadenas de 64 bytes la diferencia son nanosegundos y **se pierde en el ruido
> de una sola medición**. Con `-count=20` y `benchstat` (Fase 15) es
> estadísticamente detectable, y sobre la red, con suficientes muestras, también.
>
> **La mentira de la pantalla:** que no puedas medir la diferencia en tu portátil
> no significa que no exista. Los ataques temporales reales usan millones de
> muestras y análisis estadístico. `hmac.Equal` cuesta lo mismo y elimina la
> categoría entera.

### 6.9 Mini proyecto: `distroless-lab`

```dockerfile
# services/opsreport/Dockerfile

# ─── ETAPA 1: compilación ────────────────────────────────────────────────────
FROM golang:1.25-alpine AS builder

WORKDIR /src

# Las dependencias en su propia capa: si go.mod y go.sum no cambian, Docker
# reutiliza esta capa y no vuelve a descargar. Es la diferencia entre un build
# de 8 segundos y uno de 2 minutos.
COPY go.work go.work.sum ./
COPY services/opsreport/go.mod services/opsreport/go.sum ./services/opsreport/
RUN go mod download

COPY . .

ARG VERSION=dev
ARG COMMIT=none
ARG BUILD_DATE=unknown

# CGO_ENABLED=0 → binario estático, que es lo que permite la imagen mínima.
# -trimpath     → sin rutas absolutas de la máquina de compilación.
# -s -w         → sin tabla de símbolos ni DWARF.
RUN CGO_ENABLED=0 GOOS=linux go build \
    -trimpath \
    -ldflags="-s -w -X main.version=${VERSION} -X main.commit=${COMMIT} -X main.buildDate=${BUILD_DATE}" \
    -o /out/opsreport \
    ./services/opsreport/cmd/opsreport

# ─── ETAPA 2: la imagen final ────────────────────────────────────────────────
# distroless/static: solo los certificados raíz, /etc/passwd y la zona horaria.
# SIN shell, SIN gestor de paquetes, SIN coreutils.
#
# Eso significa que un atacante con ejecución de código no tiene `sh`, ni `curl`,
# ni `wget`. No es una barrera infranqueable —se puede subir un binario estático—
# y sube el listón bastante.
#
# El precio: no puedes hacer `docker exec -it ... sh` para depurar. La respuesta
# son las imágenes :debug de distroless, que traen busybox, para usarlas puntualmente.
FROM gcr.io/distroless/static-debian12:nonroot

COPY --from=builder /out/opsreport /opsreport

# nonroot es el UID 65532, ya definido en la imagen base. Un proceso como root
# dentro del contenedor que se escape por un fallo del runtime es root fuera.
USER nonroot:nonroot

EXPOSE 8080 9090

# ENTRYPOINT en forma exec (JSON), no shell: sin shell no hay forma shell, y
# además el proceso es el PID 1 y RECIBE LAS SEÑALES directamente.
#
# ⚠️ Con la forma shell (`ENTRYPOINT /opsreport`), el PID 1 sería `sh` y el
# SIGTERM NO llegaría a tu proceso. Todo el apagado ordenado de la Fase 07 se
# perdería, y el síntoma sería que el contenedor tarda siempre los 30 segundos
# del periodo de gracia en morir.
ENTRYPOINT ["/opsreport"]
```

```bash
docker build \
  --build-arg VERSION=$(git describe --tags --always) \
  --build-arg COMMIT=$(git rev-parse --short HEAD) \
  --build-arg BUILD_DATE=$(date -u +%Y-%m-%dT%H:%M:%SZ) \
  -t meridian/opsreport:$(git describe --tags --always) \
  -f services/opsreport/Dockerfile .

docker images meridian/opsreport --format '{{.Repository}}:{{.Tag}}\t{{.Size}}'
```

> 📐 **Cómo se mide.** Entrada **B-21**: *imagen de contenedor Go distroless frente
> a Spring Boot*. Se miden **cuatro variantes de Go** —`golang:alpine` completa,
> `alpine` mínima, `distroless/static`, y `scratch`— y **tres de Java** — JAR sobre
> `eclipse-temurin` completo, sobre JRE `alpine`, y `native-image` de GraalVM.
>
> **Comparar el binario de Go contra el JAR es hacer trampa** y hay que decirlo: el
> JAR no trae la JVM. La comparación honesta es **imagen contra imagen**, y la
> variante con `native-image` es la que hace la comparación interesante — porque
> ahí Java se acerca mucho.
>
> Se reporta además el **tiempo de construcción desde limpio** y el número de CVE
> conocidos de cada imagen base, que es un dato operativo real.

**Y el `scratch`, con su matiz:**

```dockerfile
FROM scratch
# scratch es literalmente vacío: ni certificados raíz, ni /etc/passwd, ni zonas
# horarias. Hay que copiarlo todo a mano:
COPY --from=builder /etc/ssl/certs/ca-certificates.crt /etc/ssl/certs/
COPY --from=builder /etc/passwd /etc/passwd
COPY --from=builder /out/opsreport /opsreport
USER 65532:65532
ENTRYPOINT ["/opsreport"]
```

> ⚠️ **Los tres fallos de `scratch` que se descubren en producción:**
> 1. **Sin certificados raíz**, toda llamada HTTPS falla con
>    `x509: certificate signed by unknown authority`.
> 2. **Sin `/etc/passwd`**, el `USER nonroot` por nombre falla; hay que usar el UID
>    numérico.
> 3. **Sin zonas horarias**, `time.LoadLocation` falla — y eso es exactamente la
>    deuda de la Fase 09, que se cierra con `import _ "time/tzdata"`.
>
> `distroless/static` trae las tres cosas y pesa poco más. **El curso usa
> distroless**; `scratch` se explora en el ejercicio 22 para que veas los tres
> fallos con tus ojos.

### 6.10 El resto del endurecimiento

```go
// Los cinco sitios donde hacen falta timeouts, de una vez:
//
//  1. http.Server: los cuatro de la Fase 05
//  2. http.Client: los cinco de la Fase 10
//  3. database/sql: los cuatro del pool de la Fase 09
//  4. El contexto de cada operación
//  5. El plazo de apagado, menor que el periodo de gracia
//  6. Y el sexto, que casi nadie enumera: el plazo POR CONEXIÓN, con
//     http.ResponseController.SetWriteDeadline. Es el de la Fase 13 §6.6, para
//     la descarga de reportes que dura más que el WriteTimeout global. Existe
//     justamente para no tener que subir el global y exponer a todos los
//     endpoints a un cliente lento.
//
// La configuración de §6.6 valida que sean coherentes entre sí, que es lo que
// casi nunca se comprueba. Y el sexto no se valida ahí: es local a un handler,
// y por eso se revisa leyendo el código, no la configuración.
```

```go
// Cabeceras de seguridad. Para una API JSON tras un gateway, la mayoría no
// aplica — y conviene saber cuáles sí y por qué, en vez de copiar quince.
func SecurityHeaders(next http.Handler) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		// Impide que un navegador adivine el tipo de contenido. Relevante si
		// alguna respuesta puede contener contenido controlado por el usuario.
		w.Header().Set("X-Content-Type-Options", "nosniff")

		// HSTS: solo tiene sentido si el servicio se sirve por HTTPS
		// directamente. Tras un gateway que ya lo pone, es redundante.
		if r.TLS != nil {
			w.Header().Set("Strict-Transport-Security", "max-age=31536000; includeSubDomains")
		}

		// Para una API JSON, una CSP que lo prohíbe todo es correcta y barata:
		// si una respuesta acabara renderizándose en un navegador, no ejecuta
		// nada.
		w.Header().Set("Content-Security-Policy", "default-src 'none'; frame-ancestors 'none'")

		// Referrer-Policy y X-Frame-Options no aplican a una API que no se
		// renderiza. Ponerlas "por si acaso" es ruido: cada cabecera son bytes
		// en cada respuesta.
		next.ServeHTTP(w, r)
	})
}
```

```go
// CORS: se escribe, no se importa, y con la lista de orígenes EXPLÍCITA.
//
// ⚠️ El error catastrófico de CORS es reflejar el Origin de la petición con
// Access-Control-Allow-Credentials: true. Eso permite que CUALQUIER sitio haga
// peticiones autenticadas a tu API desde el navegador de la víctima.
//
// Si no necesitas credenciales —y una API tras un gateway con token en cabecera
// no las necesita—, no lo pongas.
func CORS(allowed []string) Middleware { /* ... */ }
```

---

## ⚰️ 7. Autopsia y errores comunes

### ⚰️ Autopsia: el panel que decía que todo iba bien

**El cadáver.** Meridian tenía observabilidad. Panel con las métricas RED de los
cuatro servicios, logs estructurados en un agregador, trazas en Jaeger. Todo verde.

Y durante **nueve días**, EventRelay no entregó ni un solo evento a tres de sus
treinta socios.

Nadie se enteró hasta que uno de ellos llamó.

```go
// ☕ — el código que produjo el punto ciego
func (d *Dispatcher) deliver(ctx context.Context, delivery relay.Delivery) {
	attempt, err := d.sender.Send(ctx, endpoint, event, delivery)
	if err != nil {
		// El error se registra y se sigue. Correcto.
		d.logger.Warn("entrega fallida",
			slog.String("delivery_id", delivery.ID),
			slog.String("err", err.Error()))

		_ = delivery.RecordFailure(d.clock.Now(), err.Error())
		d.store.UpdateDelivery(ctx, delivery)
		return
	}
	// ...
}
```

**Por qué el panel estaba verde:**

| Métrica | Qué mostraba | Por qué era verde |
|---|---|---|
| `http_requests_total{status="5xx"}` | 0 | EventRelay **atendía** peticiones bien; el fallo era **saliente** |
| `http_request_duration_seconds` | p99 de 12 ms | las peticiones entrantes iban rápido |
| Tasa de errores del servicio | 0,02% | las entregas fallidas no eran errores HTTP entrantes |
| Uso de CPU y memoria | normal | el servicio estaba perfectamente sano |
| Logs con `level=ERROR` | ~3 al día | las entregas fallidas eran **WARN**, no ERROR |

**Todo lo que se medía estaba bien. Lo que fallaba no se medía.**

El diagnóstico, cuando por fin alguien miró la base de datos:

```sql
SELECT endpoint_id, status, count(*), max(attempts)
FROM deliveries WHERE created_at > now() - interval '9 days'
GROUP BY 1, 2 ORDER BY 3 DESC;
```

```text
 endpoint_id | status |  count  | max
-------------+--------+---------+-----
 EP-0012     | dead   | 184.291 |   6
 EP-0019     | dead   |  92.117 |   6
 EP-0007     | dead   |  41.882 |   6
```

Los tres socios habían rotado sus certificados TLS. El error era
`x509: certificate has expired`, clasificado como **permanente** por la Fase 10 —
correctamente—, así que cada entrega agotaba sus intentos y moría sin que nada
subiera de nivel.

**El informe forense:**

| | Lo que había | Lo que hacía falta |
|---|---|---|
| Métricas de peticiones **entrantes** | sí | sí |
| Métricas de entregas **salientes** por resultado | **no** | `deliveries_total{outcome, endpoint}` |
| Métrica de la cola de muertos | **no** | `dead_letter_queue_size` |
| Antigüedad del pendiente más viejo | **no** | `oldest_pending_seconds` |
| Entregas por socio | **no** | etiqueta `endpoint` (30 valores: aceptable) |
| Alerta sobre ausencia de entregas exitosas | **no** | la que habría saltado el día uno |
| Tiempo hasta detectar | **9 días, por llamada del socio** | minutos |

**La causa de la muerte: se instrumentó lo técnico y no lo que el servicio existe
para hacer.** Las métricas RED son necesarias y miden si el servicio **responde**,
no si **cumple su función**. EventRelay existe para entregar eventos, y la
entrega de eventos **no estaba medida**.

**Y el segundo error, más sutil: el nivel de log como decisión de arquitectura.**
Una entrega fallida es `WARN` porque se va a reintentar. Una entrega que **agota
sus intentos y muere** no es un aviso: **es un fallo del servicio en su función
principal**, y merece `ERROR`. Elegir mal ese nivel es lo que hizo que nueve días
de fallos no dispararan nada.

**El fix:**

```go
// Las métricas de negocio que faltaban.
var (
	deliveriesTotal = prometheus.NewCounterVec(
		prometheus.CounterOpts{
			Name: "meridian_deliveries_total",
			Help: "Entregas por resultado final.",
		},
		// endpoint_id: 30 valores, acotado por el negocio. Aceptable, y es
		// justo la etiqueta que permite ver que TRES socios concretos fallan.
		[]string{"outcome", "endpoint_id"},
	)

	deadLetterSize = prometheus.NewGauge(prometheus.GaugeOpts{
		Name: "meridian_dead_letter_queue_size",
		Help: "Entregas en la cola de muertos.",
	})

	lastSuccessfulDelivery = prometheus.NewGaugeVec(
		prometheus.GaugeOpts{
			Name: "meridian_last_successful_delivery_timestamp_seconds",
			Help: "Instante de la última entrega exitosa, por endpoint.",
		},
		[]string{"endpoint_id"},
	)
)
```

```yaml
# Y las alertas, que son la otra mitad. La primera es la que habría saltado.
- alert: EndpointSinEntregasExitosas
  expr: time() - meridian_last_successful_delivery_timestamp_seconds > 3600
  for: 15m
  annotations:
    summary: "El endpoint {{ $labels.endpoint_id }} no recibe una entrega exitosa desde hace más de una hora"

- alert: ColaDeMuertosCreciendo
  expr: increase(meridian_deliveries_total{outcome="dead"}[15m]) > 50
  for: 5m
```

> ☕ **El patrón a memorizar.** **Las métricas técnicas dicen si el servicio está
> vivo; las de negocio dicen si está haciendo su trabajo.** Un servicio con 0% de
> errores HTTP que no entrega nada está roto, y solo las segundas lo ven.
>
> La pregunta que hay que hacerse por cada servicio: *"¿qué métrica se movería si
> este servicio dejara de hacer aquello para lo que existe?"* Si no existe esa
> métrica, hay un punto ciego.

### Errores comunes

**1. Registrar un secreto.**
*Síntoma:* el 🧨 de §6.1.
*Fix mínimo:* las tres capas, y un test.

**2. Etiqueta de métrica de alta cardinalidad.**
*Síntoma:* Prometheus se queda sin memoria.
*Causa:* el id en la etiqueta.
*Fix mínimo:* el patrón de ruta. Y un test que cuente series.

**3. `/health` que consulta la base de datos.**
*Síntoma:* una caída de la base reinicia todos los contenedores en bucle.
*Fix mínimo:* `/health` no consulta nada; `/ready` sí, cacheado.

**4. `/ready` sin caché.**
*Síntoma:* consultas permanentes proporcionales a réplicas × frecuencia de sondeo.
*Fix mínimo:* cachear 5 s.

**5. Una dependencia opcional marcando no listo.**
*Síntoma:* Valkey cae y el servicio deja de recibir tráfico pese a funcionar.
*Fix mínimo:* distinguir obligatorias de opcionales.

**6. El mismo error registrado tres veces.**
*Síntoma:* el recuento de errores triplicado y logs ruidosos.
*Fix mínimo:* registrar donde se decide, no donde se detecta.

**7. Nivel de log mal elegido.**
*Síntoma:* la autopsia.
*Fix mínimo:* el fallo definitivo de una función principal es `ERROR`.

**8. `slog` con número impar de argumentos.**
*Síntoma:* `!BADKEY`.
*Fix mínimo:* `LogAttrs` con atributos tipados.

**9. Atributos caros construidos aunque el nivel esté apagado.**
*Síntoma:* CPU gastada en logs que se descartan.
*Fix mínimo:* `logger.Enabled(ctx, level)` antes.

**10. Muestreo de trazas independiente por servicio.**
*Síntoma:* trazas rotas, con saltos que faltan.
*Fix mínimo:* `ParentBased`.

**11. `/metrics` y `/debug/pprof` en el puerto público.**
*Síntoma:* se regalan las rutas internas, los volúmenes y el perfil de memoria.
*Fix mínimo:* puerto de administración aparte, y la validación de §6.6 que lo
comprueba en prod.

**12. Validar la URL contra SSRF en vez de la IP al conectar.**
*Síntoma:* evasión por DNS, por redirección o por *rebinding*.
*Fix mínimo:* el control en `DialContext`.

**13. Comparar firmas con `==`.**
*Síntoma:* ataque temporal.
*Fix mínimo:* `hmac.Equal`.

**14. Firma sin ventana de validez.**
*Síntoma:* ataque de repetición.
*Fix mínimo:* timestamp dentro de la firma y tolerancia comprobada en valor
absoluto.

**15. `ENTRYPOINT` en forma shell.**
*Síntoma:* el contenedor tarda siempre el periodo de gracia completo en morir.
*Causa:* el PID 1 es `sh` y no propaga el `SIGTERM`.
*Fix mínimo:* forma exec (JSON).

**16. Contenedor como root.**
*Síntoma:* ninguno, hasta el incidente.
*Fix mínimo:* `USER nonroot`, y una comprobación en CI.

**17. `scratch` sin certificados raíz.**
*Síntoma:* `x509: certificate signed by unknown authority` solo en producción.
*Fix mínimo:* `distroless/static`, o copiar los tres archivos.

**18. Sin `time/tzdata` en una imagen mínima.**
*Síntoma:* `unknown time zone America/Bogota` solo en producción.
*Fix mínimo:* `import _ "time/tzdata"`. La deuda de la Fase 09.

### 🧨 Rompe a propósito

Ya registraste un secreto. El segundo es **la explosión de cardinalidad**, y hay
que verla en el reloj:

```go
func TestCardinalityExplosion(t *testing.T) {
	reg := prometheus.NewRegistry()

	bad := prometheus.NewCounterVec(
		prometheus.CounterOpts{Name: "bad_requests_total"},
		[]string{"method", "path", "status"},   // path CONCRETA
	)
	good := prometheus.NewCounterVec(
		prometheus.CounterOpts{Name: "good_requests_total"},
		[]string{"method", "route", "status"},  // PATRÓN
	)
	reg.MustRegister(bad, good)

	for i := 0; i < 100000; i++ {
		id := fmt.Sprintf("WI-%06d", i)
		bad.WithLabelValues("GET", "/work-items/"+id, "200").Inc()
		good.WithLabelValues("GET", "GET /work-items/{id}", "200").Inc()
	}

	mfs, _ := reg.Gather()
	for _, mf := range mfs {
		t.Logf("%-22s series=%d", mf.GetName(), len(mf.GetMetric()))
	}

	var buf bytes.Buffer
	enc := expfmt.NewEncoder(&buf, expfmt.NewFormat(expfmt.TypeTextPlain))
	for _, mf := range mfs {
		_ = enc.Encode(mf)
	}
	t.Logf("tamaño de /metrics: %.1f MB", float64(buf.Len())/(1<<20))
}
```

```text
bad_requests_total     series=100000
good_requests_total    series=1
tamaño de /metrics: 7.3 MB
```

**Un solo endpoint, 100.000 series, y un `/metrics` de 7,3 MB** que Prometheus
descarga y parsea **cada quince segundos**. Multiplicado por seis réplicas son
2,9 GB por hora solo de recolección.

Y la parte que hay que entender: **no se arregla arreglando el código**. Las series
viejas viven en Prometheus hasta que expiran —normalmente horas—, y mientras tanto
las consultas de todo el mundo se degradan.

**La defensa preventiva es un test:**

```go
// TestMetricCardinality falla si alguna métrica supera un límite razonable.
// Corre en CI, y es de las cosas más baratas que se pueden poner ahí.
func TestMetricCardinality(t *testing.T) {
	reg := setupServiceWithTraffic(t, 10000)   // tráfico sintético variado

	mfs, err := reg.Gather()
	if err != nil {
		t.Fatal(err)
	}
	const maxSeries = 500
	for _, mf := range mfs {
		if n := len(mf.GetMetric()); n > maxSeries {
			t.Errorf("la métrica %s tiene %d series (máximo %d): ¿alguna etiqueta es de alta cardinalidad?",
				mf.GetName(), n, maxSeries)
		}
	}
}
```

---

## 🧪 8. Ejercicios (26)

**🟢 Fácil (1–6)**

1. Registra un secreto a propósito y sigue su rastro por los cinco sitios de
   §6.1. *Criterio:* escribes el procedimiento de rotación que haría falta.
2. Implementa el tipo `Secret` con sus cuatro métodos. *Criterio:* un test
   verifica que `fmt.Sprintf("%v")`, `%#v`, `json.Marshal` y `slog` lo redactan.
3. Configura `slog` con JSON en prod y texto en desarrollo. *Criterio:* la misma
   línea de código produce las dos salidas según la configuración.
4. Provoca el `!BADKEY`. *Criterio:* explicas por qué el compilador no lo detecta
   y lo arreglas con `LogAttrs`.
5. Implementa `/health` y `/ready` con comportamientos distintos. *Criterio:*
   apagas PostgreSQL y `/health` sigue en 200 mientras `/ready` da 503.
6. Ejecuta `govulncheck` y compara su salida con la de un escáner de imagen.
   *Criterio:* explicas por qué los números difieren tanto.

**🟡 Intermedio (7–17)**

7. Instala `redactSensitive` con las tres capas. *Criterio:* un test con quince
   formas de colar un secreto y las tres defensas las paran.
8. Implementa `contextHandler` que añade `request_id` y `trace_id`. *Criterio:*
   ninguna capa de negocio menciona esos campos y aparecen en todos los registros.
9. Implementa las métricas RED con el patrón de ruta. *Criterio:* mil peticiones a
   mil ids distintos producen **una** serie.
10. Reproduce el 🧨 de la cardinalidad y escribe el test que lo previene.
    *Criterio:* el test falla con la versión mala y pasa con la buena.
11. Añade las métricas de negocio de la autopsia. *Criterio:* apagas un endpoint y
    la métrica de última entrega exitosa lo delata en menos de un minuto.
12. Calibra los cubos del histograma para tu distribución real. *Criterio:*
    justificas cada límite con datos medidos, no con los valores por defecto.
13. Monta las trazas con Jaeger local. *Criterio:* una petición a OpsReport que
    dispara una entrega produce una traza con los saltos de los dos servicios.
14. Implementa el `Checker` con caché, paralelismo y dependencias opcionales.
    *Criterio:* con Valkey caído, readiness sigue en verde y lo reporta.
15. Termina la validación de configuración con las comprobaciones cruzadas.
    *Criterio:* `--check-config` detecta los cinco problemas de §6.6 de una vez.
16. Paga la deuda del `Makefile`. *Criterio:* `make build` sin `SVC` da un error
    claro; con un `SVC` inválido, también; y `make cover-check` **falla** con la
    cobertura por debajo del umbral.
17. **Línea de comandos.** Con `jq`, responde sobre tus logs: los cinco endpoints
    con más 5xx, la latencia p95 por ruta, y todas las líneas de una petición.
    *Criterio:* tres comandos, y explicas cuáles serían imposibles con
    `log.Printf`.

**🟠 Difícil (18–23)**

18. Construye el Dockerfile multi-etapa sobre distroless. *Criterio:* la imagen
    pesa menos de 25 MB, corre como no-root, y `docker exec sh` falla.
19. Mide **B-21**. *Criterio:* las cuatro variantes de Go y las tres de Java,
    reportando tamaño, tiempo de construcción y CVE de la base; y explicas por qué
    comparar el binario contra el JAR sería tramposo.
20. **Cierra la deuda de SSRF.** *Criterio:* (a) `SafeDialer` bloquea loopback,
    privadas, link-local y las IPv4 mapeadas en IPv6; (b) demuestras que la
    validación de URL sola **no** para el DNS rebinding y que el dialer **sí**; (c)
    la lista blanca permite `fakeconsumer` en desarrollo; (d) un test cubre las
    tres evasiones de §6.7.
21. **Cierra la deuda de la firma HMAC.** *Criterio:* (a) verificación con
    `hmac.Equal` y ventana de validez en valor absoluto; (b) demuestras el ataque
    de repetición sin la ventana y su bloqueo con ella; (c) mides la diferencia
    temporal de `==` con `benchstat` y `-count=20`; (d) documentas la tolerancia de
    reloj que el socio debe cumplir.
22. Construye la imagen sobre `scratch` y provoca los **tres** fallos de §6.9.
    *Criterio:* los tres reproducidos con su mensaje exacto, arreglados uno a uno,
    y comparas el resultado final con distroless en tamaño y en esfuerzo.
23. Implementa el endurecimiento HTTP completo. *Criterio:* (a) los cinco sitios
    de timeouts, validados entre sí; (b) cabeceras con justificación **una por
    una**, y las que descartas con su porqué; (c) CORS con lista explícita y un
    test que demuestra el peligro de reflejar el `Origin` con credenciales; (d)
    límite de cuerpo comprobado.

**🔴 Muy difícil (24–26)**

24. **Encuentra tus puntos ciegos.** Para cada uno de los cuatro servicios,
    responde: *"¿qué métrica se movería si este servicio dejara de hacer aquello
    para lo que existe?"*. *Rúbrica:* (a) para cada servicio, la función principal
    en una frase y la métrica que la mide; (b) **encuentras al menos dos puntos
    ciegos reales** además del de la autopsia; (c) los instrumentas; (d)
    **demuestras cada uno rompiendo el servicio de esa forma concreta** y viendo
    que la métrica lo detecta; (e) defines la alerta con su umbral justificado.
25. **El incidente simulado.** Prepara un entorno con los cuatro servicios y pide a
    alguien que introduzca un fallo sin decirte cuál. *Rúbrica:* (a) el catálogo de
    seis fallos posibles —entregas paradas, outbox atascado, pool agotado, caché
    envenenada, lote que no cuadra, fuga de goroutines—; (b) **diagnosticas usando
    solo la observabilidad**, sin mirar el código ni la base de datos; (c)
    cronometras el tiempo hasta el diagnóstico de cada uno; (d) para los que
    tardaste más de cinco minutos, añades lo que faltaba; (e) escribes el árbol de
    decisión que seguiste, para el runbook.
26. **El manual de operación de Meridian.** Escribe `docs/operacion.md`, la guía
    que el equipo de guardia va a usar. *Rúbrica:* (a) qué se monitoriza en cada
    servicio y por qué, separando técnico de negocio; (b) el catálogo de alertas con
    umbral, severidad y **acción concreta** —una alerta sin acción es ruido—; (c)
    cómo diagnosticar los seis fallos del ejercicio 25, con los comandos exactos;
    (d) la política de logs: niveles, qué se registra, qué **nunca**, y la retención;
    (e) el procedimiento de rotación de secretos, incluido qué hacer si uno se
    filtró en los logs; (f) los requisitos de plataforma —periodo de gracia,
    memoria, sondeos— **con sus números justificados desde las mediciones del
    curso**, no inventados; (g) utilizable a las 3 de la mañana.

**🔥 Opcionales**

- Implementa el muestreo *tail-based* en trazas: decidir si se guarda la traza
  **al terminar**, quedándote solo con las lentas o las que fallaron. Es mucho más
  útil que el muestreo por proporción y requiere un colector que lo soporte.
- Explora los *exemplars* de Prometheus: enlazar un cubo del histograma con una
  traza concreta, para saltar de "el p99 es alto" a "esta es una petición lenta de
  verdad". Es la unión práctica entre métricas y trazas.
- Investiga `GODEBUG` y las métricas del runtime (`runtime/metrics`): goroutines,
  pausas del recolector, tamaño del heap. Expónlas en `/metrics` y mira si te dicen
  algo que no sabías.

---

### 🔴 Desafíos de cierre

> Tres ejercicios de dificultad alta que **no cuentan en el total de la sección** y
> no son parte del recorrido base.

**D1 — Los *exemplars*: saltar de la métrica a la traza.**
Enlaza los cubos del histograma de latencia con trazas concretas, para pasar de *"el
p99 es alto"* a *"esta es una petición lenta de verdad"*.
*Rúbrica:* (a) el histograma publica *exemplars* con el `trace_id` de la petición
observada; (b) funciona de punta a punta: desde el panel se llega a la traza en
Jaeger; (c) explicas por qué el *exemplar* se guarda **solo para algunas
observaciones** y cuáles interesan —las de los cubos altos—; (d) mides el coste de
la instrumentación; (e) argumentas por qué esto es la unión práctica entre métricas
y trazas, y por qué sin ella los tres pilares están desconectados.

**D2 — El presupuesto de cardinalidad, automatizado.**
Convierte el test del 🧨 en una defensa real de CI.
*Rúbrica:* (a) el test genera tráfico sintético **variado y realista** —incluidas
rutas que no casan, que es el vector que nadie prevé— y cuenta series por métrica;
(b) el límite es por métrica y está justificado, no un número redondo; (c) el fallo
dice **qué etiqueta** disparó la cardinalidad, no solo que se superó; (d) lo
extiendes a los atributos de span, distinguiendo el caso —los spans son eventos, no
series— y explicando la diferencia; (e) lo pones en `make ci` y demuestras que falla
al introducir el bug.

**D3 — La rotación de secretos sin caída.**
Rota el secreto de firma de un endpoint de EventRelay **mientras entrega**, sin
perder ni rechazar ninguna entrega.
*Rúbrica:* (a) el endpoint admite dos secretos válidos durante la ventana de
rotación, y el socio puede verificar con cualquiera de los dos; (b) las entregas en
vuelo con el secreto viejo se completan; (c) hay un procedimiento para cerrar la
ventana y **una consulta que demuestra que ya nadie usa el secreto viejo**; (d) lo
demuestras bajo carga, con cero fallos; (e) escribes el procedimiento para el caso
urgente: el secreto se filtró en un log y hay que rotarlo **ya**, aceptando el
impacto — y dices cuál es ese impacto.

---

## 📚 9. Referencias

### Documentación oficial

- **`log/slog`** — https://pkg.go.dev/log/slog y https://go.dev/blog/slog — lee la
  documentación entera; es corta y cubre `LogValuer` y `ReplaceAttr`.
- **`prometheus/client_golang`** — https://pkg.go.dev/github.com/prometheus/client_golang/prometheus
- **Prometheus: naming y labels** —
  https://prometheus.io/docs/practices/naming/ y
  https://prometheus.io/docs/practices/instrumentation/ — **la sección sobre
  cardinalidad es obligatoria** en esta fase.
- **Prometheus: histogramas y resúmenes** —
  https://prometheus.io/docs/practices/histograms/ — por qué los histogramas
  agregan y los resúmenes no.
- **OpenTelemetry Go** — https://opentelemetry.io/docs/languages/go/ y
  **Semantic Conventions** — https://opentelemetry.io/docs/specs/semconv/
- **`crypto/hmac`** — https://pkg.go.dev/crypto/hmac — y por qué existe
  `hmac.Equal`.
- **`net/netip`** — https://pkg.go.dev/net/netip — `IsPrivate`, `IsLinkLocalUnicast`
  y compañía, que son la base del `SafeDialer`.
- **`govulncheck`** — https://go.dev/blog/govulncheck y https://pkg.go.dev/golang.org/x/vuln
- **Distroless** — https://github.com/GoogleContainerTools/distroless
- **`time/tzdata`** — https://pkg.go.dev/time/tzdata
- **The Twelve-Factor App** — https://12factor.net — la sección III (*Config*) es
  la base de §6.6.

### Libros

- **Observability Engineering** — Majors, Fong-Jones y Miranda. **El mejor libro
  sobre el tema**, y su argumento central —los tres pilares no bastan, hacen falta
  eventos de alta cardinalidad— es una crítica útil a lo que hemos montado aquí.
- **Site Reliability Engineering** (Google) — los capítulos de *Monitoring
  Distributed Systems* y *Practical Alerting*. **De donde sale la regla de que una
  alerta sin acción es ruido.**
- **The Site Reliability Workbook** — más práctico; los capítulos sobre SLO y
  alertas.
- **Release It!** — Nygard, por tercera vez: los patrones de estabilidad y el
  capítulo de transparencia.

### Artículos y charlas

- **Structured Logging with slog** — https://go.dev/blog/slog — oficial, por el
  autor del paquete.
- **How to instrument Go code with Prometheus** — la documentación oficial y sus
  ejemplos.
- **Cardinality is key** — busca los artículos de Grafana y Honeycomb sobre
  explosión de cardinalidad; todos cuentan la misma historia con datos de
  producción.
- **SSRF: Server Side Request Forgery** — https://portswigger.net/web-security/ssrf
  — la explicación canónica, con los vectores y las evasiones.
- **OWASP SSRF Prevention Cheat Sheet** —
  https://cheatsheetseries.owasp.org/cheatsheets/Server_Side_Request_Forgery_Prevention_Cheat_Sheet.html
  — **la lista de rangos a bloquear de §6.7 sale de aquí.**
- **A Lesson In Timing Attacks** — busca el artículo clásico de Coda Hale; explica
  por qué `==` sobre un MAC es explotable aunque parezca imposible.
- **Distroless container images** — el README del proyecto y las charlas de Google
  sobre por qué existen.
- **My Philosophy on Alerting** — Rob Ewaschuk (el documento que originó el
  capítulo de SRE). **Corto, y cambia cómo defines alertas.**

### Video

- **GopherCon: Observability in Go** — busca las posteriores a 2023, para que
  cubran `slog`.
- **PromCon: Cardinality** — hay varias charlas sobre el tema con casos reales.
- **OpenTelemetry for Go** — la serie oficial de CNCF.

> ⚠️ Casi todo el material sobre logging en Go anterior a agosto de 2023 recomienda
> `zap`, `zerolog` o `logrus`, porque `slog` no existía. Los tres siguen siendo
> buenos y `zap` es más rápido; **la ventaja de `slog` es que es la fachada de la
> stdlib**, así que una librería que registra con `slog` funciona con el manejador
> que tú elijas — incluidos manejadores que delegan en `zap`. Ese es el argumento,
> no el rendimiento.

### Orden de lectura sugerido

**Antes de escribir código:** la sección de cardinalidad de Prometheus y *My
Philosophy on Alerting* de Ewaschuk. Cuarenta minutos, y evitan los dos errores más
caros de esta fase.
**Durante:** la OWASP SSRF Cheat Sheet cuando llegues a §6.7, y la documentación de
`slog` cuando dudes de `ReplaceAttr`.
**Después:** *Observability Engineering*, al menos los primeros capítulos. Te va a
hacer dudar de si las métricas agregadas bastan, y esa duda es productiva.

---

## ⚖️ 10. Veredicto y cierre

### ⚖️ Cuándo NO usar esto

- **Cuando ya tienes Actuator y Micrometer**, montar esto en Go es trabajo que
  Spring Boot te da con una dependencia. `/actuator/health`, `/actuator/metrics`,
  `/actuator/info`, las métricas de JVM, de pool de conexiones y de HTTP **vienen
  hechas**, con convenciones de nombres consistentes. En Go se escriben.
  **Ese es un argumento real y honesto a favor de Spring Boot**, y lo retomamos en
  la Fase 16.
- **Cuando tu equipo no va a mirar los paneles.** Observabilidad que nadie consume
  es coste sin beneficio. Empieza por dos métricas de negocio y una alerta que
  alguien atienda, no por instrumentar cuarenta endpoints.
- **Cuando el volumen hace la factura insostenible.** Trazar el 100% de un servicio
  con cien mil peticiones por segundo cuesta más que el cómputo. El muestreo no es
  opcional a esa escala, y el muestreo *tail-based* —guardar las lentas y las que
  fallan— es lo que de verdad sirve.
- **Y sobre `distroless`: si tu equipo depura entrando al contenedor, te va a
  doler.** No hay shell. La respuesta son las imágenes `:debug`, los contenedores
  efímeros de depuración y una observabilidad lo bastante buena como para no
  necesitar entrar. Si no tienes eso, una imagen `alpine` con shell es una
  decisión defendible.
- **Y una crítica honesta a lo que hemos montado:** los tres pilares con métricas
  preagregadas tienen un límite. Cuando la pregunta es *"¿por qué **este** usuario
  concreto ve latencia alta y solo él?"*, ninguna métrica agregada responde, porque
  la agregación **es** la pérdida de esa información. Ese es el argumento de
  *Observability Engineering* a favor de eventos anchos de alta cardinalidad, y
  tiene razón. El curso monta lo estándar porque es lo que vas a encontrar; merece
  la pena saber que hay algo más.

### 📖 Diccionario Java ⇄ Go de esta fase

| Java / Spring | Go | Dónde se rompe la equivalencia |
|---|---|---|
| SLF4J + Logback | `log/slog` | **Una sola fachada en la stdlib.** Sin *bindings*, sin conflictos de classpath |
| `logback.xml` | código en `main` | Sin XML; el manejador se construye según la configuración |
| `%X{traceId}` + MDC | un `slog.Handler` que lee el `context` | ⚠️ **No hay MDC**: no hay estado por goroutine, y es deliberado |
| `Logger` por clase (`getLogger(X.class)`) | un `*slog.Logger` **inyectado** | Sin logger estático por tipo; se pasa como dependencia |
| `logger.debug("x {}", caro())` | `if logger.Enabled(...)` + `LogAttrs` | SLF4J evalúa perezosamente con `{}`; `slog` necesita la comprobación explícita |
| Marcadores de Logback | atributos | Más simple |
| Micrometer `MeterRegistry` | `prometheus.Registry` | Sin abstracción multi-backend; se acopla a Prometheus |
| `@Timed` | middleware escrito | Sin anotaciones |
| `Timer` con percentiles | `Histogram` con cubos | ⚠️ Los percentiles de Micrometer **no se agregan entre instancias**; los cubos sí |
| `Counter.increment()` | `counter.Inc()` | Igual |
| Etiquetas de Micrometer | etiquetas de Prometheus | **Mismo problema de cardinalidad**, y se comete igual de a menudo |
| Actuator `/actuator/health` | `/health` y `/ready` escritos | Spring lo trae con grupos `liveness`/`readiness`; aquí se escribe y decides tú qué es obligatorio |
| `HealthIndicator` | una `CheckFunc` registrada | Igual en concepto |
| `/actuator/metrics`, `/info`, `/env` | `/metrics` y `/version` escritos | **Mucho menos hecho.** Es una ventaja real de Spring Boot |
| Spring Cloud Sleuth / Micrometer Tracing | OpenTelemetry Go | OTel es el estándar en los dos ecosistemas hoy |
| `@ConfigurationProperties` + `@Validated` | struct + `Validate()` escrito | Sin anotaciones ni mensajes internacionalizados; el orden de precedencia se lee en veinte líneas |
| Perfiles (`application-prod.yml`) | un campo `Environment` y `if` | Explícito; sin resolución mágica de perfiles |
| `@Value("${x}")` | campo de la struct de configuración | Sin inyección por reflexión; el compilador verifica |
| Spring Cloud Config | *(fuera del curso)* | Configuración por entorno y archivo |
| Jib / Buildpacks | Dockerfile multi-etapa escrito | Jib construye sin Dockerfile y con capas óptimas; aquí se escribe (y son 25 líneas) |
| `eclipse-temurin:21-jre-alpine` | `gcr.io/distroless/static` | ~180 MB frente a ~2 MB de base. B-21 lo mide |
| OWASP Dependency-Check | `govulncheck` | **Análisis de alcanzabilidad**: reporta lo que tu código puede llamar, no todo lo conocido |
| Spring Security headers | middleware escrito, cabecera a cabecera | Sin valores por defecto; a cambio sabes por qué está cada una |
| `MessageDigest.isEqual` | `hmac.Equal` | Mismo propósito: comparación en tiempo constante |
| `@CrossOrigin` | middleware CORS escrito | **El error de reflejar el `Origin` con credenciales se comete igual** |

### Qué sigue

La Fase 15 deja de suponer y empieza a medir: **rendimiento, profiling y
benchmarking**.

`testing.B` bien usado —con `b.Loop`, que evita que el compilador elimine el código
medido— y **`benchstat`**, porque una sola corrida no dice nada y la diferencia
entre ruido y mejora es estadística. `pprof` completo: CPU, heap, goroutine, mutex y
block, con el servidor de depuración que hoy hemos puesto en su puerto correcto.
Escape analysis con `-gcflags=-m`, `sync.Pool` con su advertencia, y las pruebas de
carga que dejan el banco listo para el duelo.

Y el recolector de basura de Go frente al de la JVM: dos filosofías distintas
—latencia baja y predecible frente a rendimiento máximo con pausas mayores— y las
perillas que existen, `GOGC` y `GOMEMLIMIT`, comparadas con las cuarenta de la JVM.
**Sin ganador: con criterio.**

Con dos reglas que se dicen dos veces: **optimizar sin medir es cambiar código al
azar**, y **publica también la optimización que no funcionó** — de la que hay que
escribir una de verdad.

### La señal de que quedó bien

> *"Un socio me dice que no recibe eventos, y en dos minutos sé desde cuándo, por
> qué, cuántos se acumularon y si le pasa a alguien más. Sin abrir el código."*

Si para diagnosticar tienes que leer el código o consultar la base de datos a mano,
tu observabilidad tiene un punto ciego. Haz el ejercicio 24 sobre los cuatro
servicios: casi siempre aparecen dos.

> 🏷️ **No cierres la fase sin el tag.** Con el checklist de la sección 2 en
> verde, `make ci` en verde —que ahora incluye el umbral de cobertura y
> `govulncheck`—, las imágenes construidas y `git status` sin cambios pendientes:
>
> ```bash
> git tag -a fase-14 -m "F14 cerrada: slog inyectado con redacción en tres capas; métricas RED y de negocio sin alta cardinalidad; trazas OTel con muestreo ParentBased; health y readiness diferenciados con caché; configuración validada con --check-config; imágenes distroless no-root; SSRF resuelta en el dialer (deuda de la F02); firma HMAC verificada con hmac.Equal; Makefile y umbral de cobertura pagados; B-21 medido"
> git tag -a plataforma/v1.0-rc1 -m "Los cuatro servicios en estado de producción"
> ```
>
> Los commits de la fase llevan su prefijo (`fase 14: …`) y los de ejercicio su
> número (`fase 14 ej24: …`). Todo eso está en
> [`00-convencion-de-git-y-tags.md`](00-convencion-de-git-y-tags.md).

---

# 📌 Bloque de autoría (fuera de lo que lee el estudiante)

## 📌 Deudas cerradas en esta fase

Inventario, porque es la fase que más paga y conviene verificarlo:

| Deuda | Declarada en | Cerrada en | Estado |
|---|---|---|---|
| `Makefile` sin validación ni rutas | Fase 00 §6.7 | §6.6 | ✅ |
| Umbral de cobertura que no falla el build | Fase 00 / Fase 04 | §6.6 (`cover-check`) | ✅ |
| Logger provisional `log.Printf` | Fase 03 §6.8 | §6.2, con la comparación prometida | ✅ |
| Validación de URL contra SSRF | **Fase 02** §6.8 | §6.7 | ✅ **(12 fases)** |
| Verificación de firma HMAC en tiempo constante | Fase 10 §6.4 | §6.8 | ✅ |
| `import _ "time/tzdata"` en imagen mínima | Fase 09 §6.10 | §6.9 | ✅ |
| Hook de pre-commit | Fase 00 📌 | §6.6 (`.githooks/` + `make hooks`) | ✅ |

> ✅ **Las siete deudas que esta fase tenía asignadas quedan cerradas.** La del
> hook de pre-commit era la última y estuvo a punto de quedarse implícita en
> `make ci`; se implementó explícitamente porque la promesa de la Fase 00 era
> explícita, y porque `--new-from-rev` lo hace útil en vez de molesto.

## 📌 Pendientes sugeridos

- **El periodo de gracia y `terminationGracePeriodSeconds`** — la Fase 07 pidió que
  esta fase justificara el número contra algo, y la Fase 13 lo produjo con B-20.
  §6.6 lo valida contra 30 s citando B-20. **Cadena verificada en las tres fases.**
- **Métricas de caché de la Fase 12** — resuelto en §6.3: `meridian_cache_requests_total`
  y `meridian_cache_origin_duration_seconds` se exportan **desde los contadores que
  la Fase 12 ya escribió**, con un ⚠️ sobre por qué no se inventan nuevos y con la
  nota de que la tasa de acierto se calcula en Prometheus y no como gauge en el
  proceso. Cadena cerrada con la Fase 12.
- **`http.ResponseController`** — añadido a §6.10 como **el sexto sitio de
  timeouts**, con el matiz que lo hace distinto de los otros cinco: es local a un
  handler y por eso la validación de configuración de §6.6 no lo cubre. Cadena
  cerrada con la Fase 13.
- **La conexión trazas ↔ logs (`trace_id` en el log)** está en §4; **la conexión
  métricas ↔ trazas (exemplars)** solo como 🔥. Correcto para el alcance.
- **El ejercicio 25 (incidente simulado)** necesita a otra persona. Es deliberado y
  conviene que el enunciado admita hacerlo con un script que elija un fallo al azar
  con semilla, para quien estudie solo. **Sugerencia de mejora del enunciado.**

## ☕ Reflejos para `INSTINTOS.md`

- **"El `traceId` va en el MDC"** — no hay MDC ni estado por goroutine. La
  correlación se resuelve en un `slog.Handler` que lee el `context`; meter el
  logger en el `context` es el ☕ de la Fase 07 con otro nombre.
- **"Registro la petición completa para poder depurar"** — el 🧨. El secreto acaba
  en cinco sitios y rotarlo cuesta una coordinación con el socio.
- **"La ruta en la etiqueta de la métrica"** — 100.000 series de un endpoint, un
  `/metrics` de 7,3 MB, y no se arregla arreglando el código.
- **"Tenemos observabilidad: el panel está verde"** — la autopsia. Nueve días sin
  entregar a tres socios con el panel en verde. **Las métricas técnicas dicen si
  está vivo; las de negocio, si hace su trabajo.**
- **"Una entrega fallida es un WARN"** — una que **agota sus intentos** es un fallo
  de la función principal del servicio, y el nivel de log es una decisión de
  arquitectura.
- **"`/health` comprueba que todo funciona"** — reinicia todos los contenedores
  cuando la base cae, convirtiendo una degradación en una caída total.
- **"Valido la URL antes de llamarla"** — no para DNS rebinding. La defensa va en
  el `DialContext`.
- **"Comparo las firmas con `==`"** — ataque temporal; `hmac.Equal` cuesta lo mismo.

## 📐 Mediciones para `BENCHMARKS.md`

- **B-21 — Imagen de contenedor: Go distroless frente a Spring Boot.** ⚠️ **Siete
  variantes, no dos** (cuatro de Go, tres de Java), y **la de `native-image` es la
  que hace la comparación honesta**. Comparar el binario contra el JAR está
  explícitamente prohibido en el texto y hay que sostenerlo en la entrada. Añadir
  tiempo de construcción desde limpio y CVE conocidos de la base: son datos
  operativos que deciden más que el tamaño.
- **Coste de `slog` frente a `log.Printf` por registro** — §6.2 afirmaba que "la
  diferencia es pequeña con `LogAttrs` y no tanto con `slog.Any`" sin medirlo.
  **Resuelto por las dos vías:** la frase se suavizó a lo estructural (JSON frente
  a concatenación; `slog.Any` pasa por reflexión y los atributos tipados no) y
  **la fila de logging de B-28** da el número dentro de la cadena de middleware. El
  ejercicio 23 de la Fase 15 lo extiende a `slog.Any` y a la forma variádica.
- **Coste del middleware de observabilidad por petición** — pedido aquí, en la Fase
  05 y en la Fase 10: tres veces, y era la anotación más repetida del curso sin
  resolver. **Asignado como B-28 y medido en la Fase 15**, que es donde el banco de
  pruebas ya existe y el experimento es barato. La cadena vacía es la línea base de
  la entrada, sin la cual las otras filas no significan nada.
