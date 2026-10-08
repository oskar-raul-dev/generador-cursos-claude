# 🔌 Fase 10 — Clientes HTTP, APIs externas y dobles generados

> Go para desarrolladores Java senior · Fase 10 de 17 · **8 horas**
> Época: **Go moderno (1.25)**
> Depende de: Fase 09 · Habilita: Fase 11
> Proyectos que avanzan: **EventRelay** (cliente de entrega en serio) · **AtlasSync nace** · **ClearingHouse** (`storeagent sync`)
> Mini proyectos: `client-timeouts`, `backoff-lab`, `recorded-responses`

---

## 🎯 1. Propósito

Hasta ahora Meridian solo servía peticiones. Hoy sale al mundo exterior, y el
mundo exterior es hostil: responde tarde, responde mal, responde a medias, o no
responde.

Esta fase tiene dos mitades igual de importantes. La primera es **salir sin que te
tumben**: el `http.Client` bien configurado —que es un tema en sí mismo, porque el
cliente por defecto **no tiene tiempo límite y espera para siempre**—, reintentos
con retroceso y *jitter*, clasificación de errores recuperables frente a
permanentes, y limitación de tasa.

La segunda es **cómo se prueba un servicio que depende de internet**, que es el
tema que el curso venía aplazando desde la Fase 04. La regla que gobierna todo:
**la suite entera corre sin red**, y solo un test marcado 🔥 —excluido de CI—
golpea la API real.

Y aquí entra por fin `go.uber.org/mock`, seis fases después de que la Fase 04 lo
aplazara, con su justificación escrita.

---

## ✅ 2. Qué queda listo al terminar

- [ ] EventRelay entrega por HTTP de verdad, firmado con HMAC, con tiempo límite y
      cuerpo drenado y cerrado.
- [ ] La clasificación de errores es una **función pura probada con tabla**:
      recuperable, permanente o de límite de tasa.
- [ ] El retroceso exponencial con *jitter* está escrito, es determinista en
      tests, y respeta `Retry-After`.
- [ ] Hay un cortacircuitos mínimo, **escrito y no importado**.
- [ ] **AtlasSync existe** y consume REST Countries y Frankfurter.
- [ ] `singleflight` evita el rebaño atronador en la ingesta de tipos de cambio.
- [ ] Los cinco niveles de prueba de AtlasSync están montados, y
      `go test ./...` **no toca la red** — lo verificas.
- [ ] Las respuestas reales están grabadas en `testdata/` y hay un procedimiento
      para refrescarlas.
- [ ] `go.uber.org/mock` se usa **en un sitio** y sabes decir por qué ahí y no en
      otros.
- [ ] `storeagent sync` sube los movimientos pendientes de forma reanudable.

---

## 🚫 3. Qué NO entra todavía

- MongoDB → Fase 11. AtlasSync guarda hoy en memoria y en un archivo JSON, y eso
  es deuda declarada. 💸
- Caché con Valkey → Fase 12. Hoy la caché es un mapa con TTL, y funciona
  sorprendentemente bien — cosa que el ⚖️ veredicto de la Fase 12 recogerá.
- Ingesta programada → Fase 13. Hoy se dispara con un endpoint.
- Trazas distribuidas y propagación de contexto entre servicios → Fase 14.
- Validación de URL contra SSRF → Fase 14. La deuda 💸 de la Fase 02 sigue viva y
  **se dice en el código**.
- gRPC → sección 🔥 opcional de la Fase 16.

---

## 🧠 4. Concepto mínimo

### `http.DefaultClient` no tiene tiempo límite. Ninguno.

```go
resp, err := http.Get("https://api.socio-lento.com/status")
```

Si ese servidor acepta la conexión y **nunca responde**, esa llamada espera para
siempre. No hay timeout por defecto, no hay límite de lectura, no hay nada. La
goroutine se queda ahí, y con ella la petición que la originó, la conexión de base
de datos que tenía tomada, y el worker del pool.

**Un socio lento cuelga al productor** — que es literalmente el incidente que dio
origen a EventRelay, descrito en su documento de proyecto.

```go
// El cliente mínimo aceptable en producción.
client := &http.Client{
	Timeout: 10 * time.Second,
}
```

Ese `Timeout` cubre **toda la operación**: resolución DNS, conexión TCP,
handshake TLS, envío, espera de respuesta y **lectura completa del cuerpo**. Es
importante entenderlo así, porque confunde a quien viene de configurar
`connectTimeout` y `readTimeout` por separado:

```go
// El cliente completo, con los plazos por fase. Cada uno responde a un fallo
// distinto y por eso no basta con el Timeout global.
func NewClient(cfg Config) *http.Client {
	transport := &http.Transport{
		// El marcador de conexión: DNS + TCP.
		DialContext: (&net.Dialer{
			Timeout:   5 * time.Second,  // conectar al socket
			KeepAlive: 30 * time.Second, // keep-alive de TCP
		}).DialContext,

		// El handshake TLS, aparte. Un servidor con un certificado que tarda en
		// validarse consume aquí, no en el Dial.
		TLSHandshakeTimeout: 5 * time.Second,

		// Desde que terminamos de enviar hasta el primer byte de la respuesta.
		// ES EL MÁS ÚTIL PARA DIAGNOSTICAR: distingue "el servidor no contesta"
		// de "el servidor contesta despacio".
		ResponseHeaderTimeout: 10 * time.Second,

		// Con "Expect: 100-continue", cuánto esperamos el visto bueno antes de
		// mandar el cuerpo.
		ExpectContinueTimeout: 1 * time.Second,

		// ⚠️ EL PARÁMETRO CUYO VALOR POR DEFECTO SORPRENDE: MaxIdleConnsPerHost
		// es 2. DOS. Si llamas a un solo host con cien goroutines, 98 conexiones
		// se cierran tras cada petición y se vuelven a abrir: handshake TLS
		// completo cada vez, y agotamiento de puertos efímeros bajo carga.
		//
		// Para un cliente que martillea pocos hosts —que es EventRelay— hay que
		// subirlo al nivel de concurrencia esperado.
		MaxIdleConns:        100, // total, entre todos los hosts
		MaxIdleConnsPerHost: 100, // por host
		MaxConnsPerHost:     200, // techo duro por host: contrapresión

		IdleConnTimeout: 90 * time.Second,

		// Compresión transparente. Está activada por defecto y conviene saber
		// que, si la desactivas, el cuerpo llega comprimido y hay que
		// descomprimirlo a mano.
		DisableCompression: false,
	}

	return &http.Client{
		Transport: transport,
		Timeout:   cfg.RequestTimeout, // el techo global, además de los de fase

		// Sin esto, el cliente sigue hasta 10 redirecciones automáticamente.
		// Para un webhook a un socio, seguir redirecciones es un riesgo: el
		// socio podría redirigir a una IP interna. Aquí no las seguimos.
		CheckRedirect: func(req *http.Request, via []*http.Request) error {
			return http.ErrUseLastResponse
		},
	}
}
```

> 🧭 **Regla del proyecto: un `http.Client` por destino, construido una vez,
> compartido.** El `Transport` guarda el pool de conexiones; crear un cliente por
> petición tira ese pool y **abre una conexión TLS nueva cada vez**. Es el
> equivalente exacto de crear un `DataSource` por consulta, y es igual de malo.

### Los tres deberes con el cuerpo de la respuesta

```go
resp, err := client.Do(req)
if err != nil {
	return fmt.Errorf("enviando la entrega: %w", err)
}

// 1. CERRAR. Siempre, en todos los caminos. Sin esto, la conexión se fuga.
//    ⚠️ Esto es el LADO CLIENTE. En el servidor (Fase 05), net/http lo cierra
//    por ti. Confundirlos es el error común #2 de aquella fase.
defer resp.Body.Close()

// 2. DRENAR antes de cerrar, si quieres reutilizar la conexión. Una conexión
//    keep-alive solo vuelve al pool si el cuerpo se consumió ENTERO. Si cierras
//    a medias, Go cierra la conexión TCP y la siguiente petición hace handshake
//    otra vez.
//
//    El límite evita que un servidor malicioso te haga leer un gigabyte solo
//    para poder reutilizar una conexión.
defer io.Copy(io.Discard, io.LimitReader(resp.Body, 64<<10))

// 3. LIMITAR lo que lees. Sin esto, un socio puede devolver diez gigas y tu
//    ReadAll se los traga.
body, err := io.ReadAll(io.LimitReader(resp.Body, maxResponseBytes))
```

> ⚠️ **El orden de los `defer` importa y es contraintuitivo.** Los `defer` se
> ejecutan en orden inverso (LIFO), así que `io.Copy` —declarado **después**— se
> ejecuta **antes** que `Close`. Que es exactamente lo que queremos: drenar y
> luego cerrar. Al revés no funcionaría.

### 🪞 Tu instinto de Java dice… y esta vez se equivoca

**El instinto:** *"pongo `@Retryable(maxAttempts=3)` y ya reintenta"*. Con Spring
Retry o Resilience4j, el reintento es una anotación y la política se declara. Es
cómodo, está probado, y funciona.

**Qué pasa si lo aplicas aquí.** Buscas la anotación, no la hay, y escribes el
reintento a mano. Y casi todo el mundo escribe **esta** versión:

```go
// ☕ — el reintento que hace más daño que el fallo que arregla
func (c *Client) SendWithRetry(ctx context.Context, d relay.Delivery) error {
	var lastErr error
	for attempt := 1; attempt <= 3; attempt++ {
		err := c.send(ctx, d)
		if err == nil {
			return nil
		}
		lastErr = err
		time.Sleep(time.Second)   // ← retroceso fijo
	}
	return lastErr
}
```

Tiene **cuatro** problemas, y los cuatro están resueltos en Spring Retry por
defecto, que es justo por lo que no se ven al escribirlo:

**1. Reintenta lo que no se debe reintentar.** Un `400 Bad Request` significa que
tu petición está mal; reintentarla tres veces produce tres respuestas idénticas y
retrasa el fallo. Un `401` igual. **Solo se reintenta lo que puede cambiar de
resultado.**

**2. Retroceso fijo: el rebaño atronador.** Si un socio se cae y tienes mil
entregas pendientes, las mil reintentan al segundo 1, las mil al 2, las mil al 3.
Cuando el socio vuelve, recibe mil peticiones simultáneas y se vuelve a caer. **Tú
acabas de convertir una caída de treinta segundos en una caída de diez minutos.**

**3. Sin *jitter*: la sincronización.** Aunque el retroceso sea exponencial, si
todos los clientes usan la misma fórmula, todos reintentan en el mismo instante.
El *jitter* —aleatoriedad en la espera— es lo que los desincroniza, y no es un
detalle: es la diferencia entre un pico y una curva.

**4. Ignora `Retry-After`.** Un `429` con `Retry-After: 60` te está diciendo
exactamente cuándo volver. Ignorarlo y reintentar al segundo es maleducado y suele
acabar en un bloqueo por parte del socio.

**Qué pensar en su lugar.** El reintento tiene **tres decisiones** y cada una es
una función:

```go
// 1. ¿Es reintentable?  →  función pura, probada con tabla
func Classify(resp *http.Response, err error) Outcome

// 2. ¿Cuánto espero?    →  función pura, con la fuente de aleatoriedad inyectada
func (p Policy) Backoff(attempt int, retryAfter time.Duration) time.Duration

// 3. ¿Sigo intentando?  →  el bucle, que además mira el contexto
func Do(ctx context.Context, p Policy, fn func(context.Context) (*http.Response, error)) error
```

Separarlas así tiene una ventaja concreta que la anotación no da: **las dos
primeras son puras y se prueban con una tabla de treinta casos en dos
milisegundos**, sin red, sin esperas, sin intermitencia.

### Y la decisión que precede a todas: idempotencia

```go
// ⚠️ Antes de reintentar CUALQUIER cosa, la pregunta es: ¿es seguro?
//
// Un GET, sí. Un DELETE, normalmente. Un POST que cobra una tarjeta, NO — salvo
// que el receptor implemente idempotencia.
//
// EventRelay manda una cabecera de idempotencia en cada entrega. Si el socio la
// respeta, el reintento es seguro aunque la primera petición SÍ llegara y solo
// se perdiera la respuesta. Si no la respeta, un timeout de lectura seguido de
// un reintento produce una entrega duplicada, y el socio no puede distinguirla.
req.Header.Set("X-Meridian-Idempotency-Key", delivery.ID)
```

> 🧭 **Regla del proyecto.** Un reintento sobre una operación no idempotente es
> una entrega duplicada esperando. Se documenta en el contrato con el socio, se
> manda la clave, y **se asume que algunos socios la ignorarán** — por eso el
> historial de intentos existe y por eso EventRelay guarda cada uno.

### 🩻 Esto sí funciona igual

- **El patrón de reintento con retroceso exponencial** es el mismo que configuras
  en Resilience4j. La fórmula es idéntica; aquí se escribe.
- **El cortacircuitos** tiene los mismos tres estados —cerrado, abierto,
  semiabierto— y las mismas decisiones de umbral y ventana.
- **Distinguir errores recuperables de permanentes** es el mismo criterio que
  aplicas al configurar `retryOn` / `noRetryOn`.
- **La pirámide de pruebas para servicios externos** es la misma: unitarios con
  dobles, de componente con un servidor falso, de integración con el sistema real.
  WireMock y `httptest.Server` resuelven el mismo problema.
- **Grabar respuestas reales para los tests** es exactamente lo que haces con los
  ficheros de WireMock o con VCR.
- **La limitación de tasa** y el *token bucket* son los mismos algoritmos que usa
  Bucket4j.

---

## 🛠️ 5. CLI de la fase

```bash
# curl con detalle de tiempos por fase. Es el diagnóstico de primera línea de
# cualquier problema con una API externa, y separa DNS de conexión de TLS de
# respuesta.
curl -s -o /dev/null -w '
  dns:        %{time_namelookup}s
  conexión:   %{time_connect}s
  tls:        %{time_appconnect}s
  1er byte:   %{time_starttransfer}s
  total:      %{time_total}s
  estado:     %{http_code}
  tamaño:     %{size_download} bytes
' https://api.frankfurter.app/latest

# Refrescar el corpus grabado de testdata/ desde las APIs reales. Es el único
# comando de la fase que toca internet, y es deliberado y explícito.
curl -s 'https://restcountries.com/v3.1/all?fields=name,cca2,cca3,currencies,languages,timezones,region,subregion' \
  -o services/atlassync/testdata/restcountries_all.json

curl -s 'https://api.frankfurter.app/latest?from=EUR' \
  -o services/atlassync/testdata/frankfurter_latest.json

# Ver el tamaño de lo grabado: si crece mucho, el repositorio sufre.
du -h services/atlassync/testdata/*.json

# GODEBUG del cliente HTTP: traza el establecimiento y la reutilización de
# conexiones. Es cómo se comprueba de verdad que el keep-alive funciona.
GODEBUG=http2debug=1 go run ./cmd/atlassync

# El generador de mocks. Se instala como cualquier herramienta.
go install go.uber.org/mock/mockgen@latest

# Generación por directiva: el //go:generate vive junto a la interfaz.
go generate ./...

# Y directamente, para ver qué hace:
mockgen -source=internal/atlassync/ports.go -destination=internal/atlassync/mocks_test.go -package=atlassync_test

# LA VERIFICACIÓN MÁS IMPORTANTE DE LA FASE: comprobar que la suite no toca la
# red. En macOS y Linux, correr los tests sin resolución de nombres.
GODEBUG=netdns=go go test ./... 2>&1 | grep -i 'no such host' && echo "ALGO TOCÓ LA RED"

# El método fiable: un test que instala un DialContext que falla siempre.
go test -run TestNoNetworkAccess ./internal/atlassync -v

# Los tests 🔥 que sí golpean la red viven tras un build tag propio y NO corren
# en CI.
go test -tags=live ./internal/atlassync -run TestLive -v

# Sondeo de un endpoint con vegeta, para el laboratorio de límite de tasa.
echo "GET http://localhost:9100/ok" | vegeta attack -rate=50 -duration=10s | vegeta report

# Ver los puertos efímeros en uso: es cómo se diagnostica el agotamiento por
# MaxIdleConnsPerHost mal configurado.
netstat -an | grep -c TIME_WAIT          # macOS / Linux
ss -s                                     # Linux, resumen de sockets
```

> 💡 **`time_starttransfer` menos `time_appconnect` es el tiempo de proceso del
> servidor remoto.** Si esa resta es grande, el problema es de ellos. Si lo grande
> es `time_namelookup` o `time_connect`, el problema es de red o de DNS. Ese
> desglose evita discusiones enteras con un proveedor.

---

## 💻 6. Construcción guiada

### 6.1 Mini proyecto: `client-timeouts`

Las cuatro formas de colgarte esperando, y qué timeout para cada una.

```go
// labs/client-timeouts/scenarios.go
package timeouts

// Los cuatro escenarios de fallo, cada uno servido por un httptest.Server.
// Para cada uno: qué timeout lo ataja y cuál NO sirve.

// 1. El servidor que acepta la conexión y no responde nunca.
//    Lo ataja: ResponseHeaderTimeout, o el Timeout global.
//    NO lo ataja: DialContext.Timeout (la conexión SÍ se estableció).
func ServerNeverResponds() *httptest.Server {
	return httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		<-r.Context().Done()   // esperar hasta que el cliente se rinda
	}))
}

// 2. El servidor que responde las cabeceras y el cuerpo a gotas.
//    Lo ataja: SOLO el Timeout global del cliente.
//    NO lo ataja: ResponseHeaderTimeout (las cabeceras llegaron rápido).
//
//    Es el Slowloris de la Fase 05, en dirección contraria: un servidor
//    malicioso atacando a su cliente.
func ServerDripsBody() *httptest.Server {
	return httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		w.Header().Set("Content-Length", "10000")
		w.WriteHeader(http.StatusOK)
		flusher := w.(http.Flusher)
		for i := 0; i < 10000; i++ {
			w.Write([]byte("x"))
			flusher.Flush()
			time.Sleep(100 * time.Millisecond)   // 1000 segundos en total
		}
	}))
}

// 3. El servidor que responde un cuerpo gigantesco.
//    Lo ataja: io.LimitReader. NINGÚN timeout lo ataja si el servidor es rápido:
//    diez gigas a gran velocidad llegan antes del timeout y te dejan sin memoria.
func ServerReturnsHuge() *httptest.Server { /* ... */ }

// 4. El host que no resuelve o no acepta conexiones.
//    Lo ataja: DialContext.Timeout.
//    ⚠️ Y una trampa: la resolución DNS puede tardar más que el timeout del
//    Dialer si el resolutor del sistema no coopera. El contexto es la única
//    garantía real.
func UnreachableHost() string { return "http://192.0.2.1:9999" } // TEST-NET-1
```

🧨 **Rompe a propósito.** Corre los cuatro escenarios contra
`http.DefaultClient`:

```go
func TestDefaultClientHangsForever(t *testing.T) {
	srv := ServerNeverResponds()
	defer srv.Close()

	start := time.Now()

	// Con un contexto de 2 segundos como única defensa. Sin él, esto no termina.
	ctx, cancel := context.WithTimeout(context.Background(), 2*time.Second)
	defer cancel()

	req, _ := http.NewRequestWithContext(ctx, http.MethodGet, srv.URL, nil)
	_, err := http.DefaultClient.Do(req)

	t.Logf("falló tras %s con: %v", time.Since(start).Round(time.Millisecond), err)
	// falló tras 2.001s con: Get "http://127.0.0.1:52341": context deadline exceeded
}
```

Ahora **quita el contexto** y ponle un `-timeout 30s` al test. El test se cuelga
los treinta segundos y el runner lo mata imprimiendo todas las pilas.

**La lección:** `http.DefaultClient` sin contexto y sin `Timeout` no falla nunca.
Y en un servicio, "no falla nunca" significa "la goroutine se queda para siempre",
que es la fuga de la Fase 06 con un origen externo.

### 6.2 Mini proyecto: `backoff-lab`

Las tres funciones del reintento, escritas y probadas.

**Primero, la clasificación.** Función pura, tabla de treinta casos:

```go
// labs/backoff-lab/classify.go
package backoff

// Outcome dice qué hacer con el resultado de un intento.
type Outcome int

const (
	// Success: 2xx. Terminar.
	Success Outcome = iota
	// Retryable: puede cambiar si se reintenta. 5xx, timeouts, errores de red.
	Retryable
	// RateLimited: 429 o 503 con Retry-After. Reintentar RESPETANDO la cabecera.
	RateLimited
	// Permanent: no va a cambiar. 4xx (salvo 429), TLS inválido, URL mal formada.
	Permanent
)

// Classify decide qué hacer. Es una FUNCIÓN PURA: sin E/S, sin reloj, sin
// aleatoriedad. Por eso se prueba con una tabla de treinta casos en dos
// milisegundos, y por eso es la pieza que más confianza da de todo el cliente.
func Classify(resp *http.Response, err error) Outcome {
	if err != nil {
		return classifyError(err)
	}

	switch {
	case resp.StatusCode >= 200 && resp.StatusCode < 300:
		return Success

	case resp.StatusCode == http.StatusTooManyRequests:
		return RateLimited

	case resp.StatusCode == http.StatusServiceUnavailable:
		// 503 CON Retry-After es limitación de tasa declarada; sin ella es un
		// fallo temporal normal. La distinción cambia cuánto esperamos.
		if resp.Header.Get("Retry-After") != "" {
			return RateLimited
		}
		return Retryable

	case resp.StatusCode == http.StatusRequestTimeout,     // 408
		resp.StatusCode == http.StatusBadGateway,          // 502
		resp.StatusCode == http.StatusGatewayTimeout,      // 504
		resp.StatusCode >= 500:
		return Retryable

	default:
		// Todo 4xx que no sea 408 ni 429 es culpa nuestra: la petición está mal
		// y reintentarla produce el mismo resultado. Incluye 401 y 403: si el
		// secreto está mal, reintentar no lo arregla y sí puede activar un
		// bloqueo por intentos fallidos en el socio.
		return Permanent
	}
}

func classifyError(err error) Outcome {
	// La cancelación NUESTRA no es un fallo del socio: no gasta intento y no se
	// reintenta. Es la distinción de la Fase 07 aplicada.
	if errors.Is(err, context.Canceled) {
		return Permanent
	}
	// El vencimiento del plazo SÍ es reintentable: el socio estaba lento.
	if errors.Is(err, context.DeadlineExceeded) {
		return Retryable
	}

	// Los errores de red van envueltos en *url.Error. Timeout() y Temporary()
	// son de la interfaz net.Error.
	var netErr net.Error
	if errors.As(err, &netErr) && netErr.Timeout() {
		return Retryable
	}

	// Un error de TLS es permanente: certificado inválido, cadena rota,
	// nombre que no coincide. Reintentar no arregla un certificado.
	var certErr *tls.CertificateVerificationError
	if errors.As(err, &certErr) {
		return Permanent
	}

	// DNS: "no such host" es permanente (el dominio no existe); un fallo
	// temporal del resolutor es reintentable. La distinción la da el propio
	// error.
	var dnsErr *net.DNSError
	if errors.As(err, &dnsErr) {
		if dnsErr.IsNotFound {
			return Permanent
		}
		return Retryable
	}

	// Conexión rechazada o reiniciada: el servidor está reiniciando o
	// desplegando. Reintentable.
	var opErr *net.OpError
	if errors.As(err, &opErr) {
		return Retryable
	}

	// Ante la duda, permanente. Preferimos NO reintentar algo desconocido a
	// martillear a un socio por un error que no entendemos.
	return Permanent
}
```

> 🧭 **Regla del proyecto: ante la duda, permanente.** Un falso permanente cuesta
> una entrega que va a la cola de muertos y alguien reprocesa a mano. Un falso
> reintentable cuesta martillear al socio con peticiones que nunca van a funcionar,
> y puede acabar en un bloqueo. **El coste de los dos errores no es simétrico.**

**Segundo, el retroceso.** También pura, con la aleatoriedad inyectada:

```go
// labs/backoff-lab/policy.go
package backoff

type Policy struct {
	Base        time.Duration // espera del primer reintento
	Max         time.Duration // techo de la espera
	Multiplier  float64       // factor de crecimiento; 2.0 es lo habitual
	MaxAttempts int

	// Rand se inyecta para que el jitter sea DETERMINISTA en tests. Sin esto,
	// probar el retroceso sería probar un número aleatorio, que no se puede.
	Rand *rand.Rand
}

func DefaultPolicy() Policy {
	return Policy{
		Base:        500 * time.Millisecond,
		Max:         2 * time.Minute,
		Multiplier:  2.0,
		MaxAttempts: 6,
		// math/rand/v2, adoptado en la Fase 08: sin el lock global de la v1.
		Rand: rand.New(rand.NewPCG(uint64(time.Now().UnixNano()), 0)),
	}
}

// Backoff calcula cuánto esperar antes del intento `attempt` (empezando en 1).
//
// Usa "full jitter": la espera es un valor aleatorio entre 0 y el tope
// exponencial. Es contraintuitivo —esperar menos de lo calculado— y es lo que
// mejor funciona según el análisis de AWS que está en las referencias: reparte
// las reintentos por toda la ventana en vez de agruparlos en su borde.
func (p Policy) Backoff(attempt int, retryAfter time.Duration) time.Duration {
	// Retry-After manda SIEMPRE. El socio nos dijo cuándo volver; discutirlo es
	// maleducado y contraproducente.
	if retryAfter > 0 {
		if retryAfter > p.Max {
			return p.Max
		}
		return retryAfter
	}

	cap := float64(p.Base) * math.Pow(p.Multiplier, float64(attempt-1))
	if cap > float64(p.Max) {
		cap = float64(p.Max)
	}

	// Full jitter: uniforme en [0, cap).
	return time.Duration(p.Rand.Float64() * cap)
}

// ParseRetryAfter entiende las DOS formas del RFC: segundos, o una fecha HTTP.
// La segunda es la que todo el mundo olvida, y algunos CDN la usan.
func ParseRetryAfter(h string, now time.Time) time.Duration {
	if h == "" {
		return 0
	}
	if secs, err := strconv.Atoi(h); err == nil {
		if secs < 0 {
			return 0
		}
		return time.Duration(secs) * time.Second
	}
	if t, err := http.ParseTime(h); err == nil {
		if d := t.Sub(now); d > 0 {
			return d
		}
	}
	return 0
}
```

**Tercero, el bucle**, que es lo único con efectos:

```go
// Do ejecuta fn con reintentos según la política.
//
// Lo importante del bucle: el contexto se mira en la espera. Sin eso, un apagado
// tendría que esperar hasta dos minutos a que terminara un retroceso.
func Do(ctx context.Context, p Policy, fn func(context.Context) (*http.Response, error)) (*http.Response, error) {
	var lastErr error

	for attempt := 1; attempt <= p.MaxAttempts; attempt++ {
		resp, err := fn(ctx)
		outcome := Classify(resp, err)

		switch outcome {
		case Success:
			return resp, nil

		case Permanent:
			if resp != nil {
				drainAndClose(resp)
			}
			if err != nil {
				return nil, fmt.Errorf("error permanente en el intento %d: %w", attempt, err)
			}
			return nil, fmt.Errorf("%w: el endpoint respondió %d", ErrPermanent, resp.StatusCode)

		case Retryable, RateLimited:
			var retryAfter time.Duration
			if resp != nil {
				retryAfter = ParseRetryAfter(resp.Header.Get("Retry-After"), time.Now())
				// Drenar y cerrar ANTES de esperar: si no, la conexión se queda
				// ocupada durante todo el retroceso y el pool se agota con
				// reintentos lentos.
				drainAndClose(resp)
				lastErr = fmt.Errorf("el endpoint respondió %d", resp.StatusCode)
			} else {
				lastErr = err
			}

			if attempt == p.MaxAttempts {
				return nil, fmt.Errorf("agotados %d intentos: %w", p.MaxAttempts, lastErr)
			}

			wait := p.Backoff(attempt, retryAfter)

			timer := time.NewTimer(wait)
			select {
			case <-timer.C:
				// siguiente intento
			case <-ctx.Done():
				timer.Stop()
				return nil, fmt.Errorf("cancelado esperando el reintento %d: %w", attempt+1, ctx.Err())
			}
		}
	}
	return nil, fmt.Errorf("agotados %d intentos: %w", p.MaxAttempts, lastErr)
}

func drainAndClose(resp *http.Response) {
	if resp == nil || resp.Body == nil {
		return
	}
	_, _ = io.Copy(io.Discard, io.LimitReader(resp.Body, 64<<10))
	_ = resp.Body.Close()
}
```

> 🧪 **Prueba de fuego.** Prueba el retroceso **sin esperar de verdad**: con el
> `Rand` inyectado y semilla fija, `Backoff` es determinista y se verifica con una
> tabla. Y para el bucle, `fakeconsumer /fail/503` con un `MaxAttempts` de 3 y una
> `Base` de 1 ms.
>
> **La mentira de la pantalla:** un test que mide el tiempo real que tarda el
> retroceso es intermitente por definición y va a fallar en CI un martes. **No
> midas el tiempo: verifica la política.** Comprueba que `Backoff(3, 0)` está en el
> rango esperado con la semilla dada, y que el bucle llamó a `fn` el número
> correcto de veces.

### 6.3 El cortacircuitos, escrito y no importado

```go
// services/eventrelay/internal/circuit/breaker.go

// Package circuit implementa un cortacircuitos mínimo.
//
// Se escribe en vez de importarse por dos razones: son ochenta líneas, y
// entender los tres estados y sus transiciones importa más que la
// implementación. Para producción, sony/gobreaker o el de resilience-go están
// bien probados — y después de escribir este, sabrás leer su configuración.
package circuit

type State int

const (
	// Closed: todo pasa. Se cuentan los fallos.
	Closed State = iota
	// Open: nada pasa. Se falla RÁPIDO, sin gastar una conexión ni un plazo.
	// Esta es la razón de ser del patrón: proteger al SOCIO caído de nuestras
	// peticiones, y protegernos a nosotros de gastar recursos en llamadas que
	// sabemos que van a fallar.
	Open
	// HalfOpen: pasa UNA petición de prueba. Si va bien, cerramos; si va mal,
	// abrimos otra vez.
	HalfOpen
)

type Breaker struct {
	failureThreshold int           // fallos consecutivos para abrir
	openDuration     time.Duration // cuánto estar abierto antes de probar
	clock            Clock

	mu               sync.Mutex
	state            State
	consecutiveFails int
	openedAt         time.Time
	halfOpenInFlight bool // solo UNA petición de prueba a la vez
}

var ErrCircuitOpen = errors.New("el cortacircuitos está abierto")

// Allow dice si se puede intentar. Devuelve la función de registro del
// resultado, para que el llamador no tenga que acordarse de llamar a dos cosas.
func (b *Breaker) Allow() (report func(success bool), err error) {
	b.mu.Lock()
	defer b.mu.Unlock()

	switch b.state {
	case Closed:
		return b.reportClosed, nil

	case Open:
		if b.clock.Now().Sub(b.openedAt) < b.openDuration {
			return nil, ErrCircuitOpen
		}
		// Se cumplió el plazo: pasamos a semiabierto y dejamos UNA prueba.
		b.state = HalfOpen
		b.halfOpenInFlight = true
		return b.reportHalfOpen, nil

	case HalfOpen:
		if b.halfOpenInFlight {
			// Ya hay una prueba en curso. Las demás se rechazan: si dejáramos
			// pasar todas, al vencer el plazo caería sobre el socio todo el
			// tráfico acumulado de golpe, que es justo lo que queremos evitar.
			return nil, ErrCircuitOpen
		}
		b.halfOpenInFlight = true
		return b.reportHalfOpen, nil
	}
	return nil, ErrCircuitOpen
}
```

> ⚠️ **El cortacircuitos es por destino, nunca global.** Uno por endpoint de socio.
> Un cortacircuitos compartido entre los treinta socios de Meridian significa que
> un socio caído corta las entregas de los otros veintinueve — que es exactamente
> el problema que EventRelay existe para resolver.

📖 Es lo mismo que Resilience4j y la configuración se traduce casi uno a uno.
Resilience4j hace más: ventana deslizante frente a fallos consecutivos, umbral por
porcentaje, detección de llamadas lentas, métricas integradas. **Este es un
cortacircuitos mínimo y no pretende otra cosa**; para producción, importa uno.

### 6.4 EventRelay: el cliente de entrega completo

```go
// services/eventrelay/internal/httpsender/sender.go

type Sender struct {
	client   *http.Client
	policy   backoff.Policy
	breakers *circuit.Registry   // uno por endpoint
	limiters *rate.Registry      // uno por endpoint
	clock    Clock
	logger   *slog.Logger
	maxBody  int64
}

func (s *Sender) Send(ctx context.Context, ep relay.Endpoint, ev relay.Event, d relay.Delivery) (relay.DeliveryAttempt, error) {
	// 1. Limitación de tasa POR ENDPOINT. Cada socio declara cuántas peticiones
	//    por segundo acepta, y se respeta. Wait bloquea hasta que hay permiso o
	//    hasta que el contexto se cancela.
	if err := s.limiters.For(ep.ID, ep.RateLimit).Wait(ctx); err != nil {
		return relay.DeliveryAttempt{}, fmt.Errorf("esperando permiso de tasa: %w", err)
	}

	// 2. Cortacircuitos POR ENDPOINT.
	report, err := s.breakers.For(ep.ID).Allow()
	if err != nil {
		return relay.DeliveryAttempt{}, fmt.Errorf("%w para el endpoint %s", err, ep.ID)
	}

	start := s.clock.Now()
	resp, err := backoff.Do(ctx, s.policy, func(ctx context.Context) (*http.Response, error) {
		return s.doOnce(ctx, ep, ev, d)
	})
	latency := s.clock.Now().Sub(start)

	attempt := relay.DeliveryAttempt{
		DeliveryID:  d.ID,
		Number:      d.Attempts + 1,
		LatencyMS:   latency.Milliseconds(),
		AttemptedAt: start,
	}

	if err != nil {
		report(false)
		attempt.Error = err.Error()
		return attempt, err
	}
	defer drainAndClose(resp)

	report(true)
	attempt.StatusCode = resp.StatusCode
	return attempt, nil
}

// doOnce construye y envía UNA petición. Se separa del bucle de reintentos
// porque cada intento necesita un cuerpo nuevo: un io.Reader se consume, y
// reutilizar el mismo entre intentos manda un cuerpo vacío en el segundo.
//
// Ese es un bug real y muy común del reintento escrito a mano.
func (s *Sender) doOnce(ctx context.Context, ep relay.Endpoint, ev relay.Event, d relay.Delivery) (*http.Response, error) {
	req, err := http.NewRequestWithContext(ctx, http.MethodPost, ep.URL,
		bytes.NewReader(ev.Payload))   // ← Reader NUEVO en cada intento
	if err != nil {
		return nil, fmt.Errorf("construyendo la petición: %w", err)
	}

	timestamp := s.clock.Now().UTC()

	req.Header.Set("Content-Type", "application/json")
	req.Header.Set("User-Agent", "Meridian-EventRelay/1.0")
	req.Header.Set("X-Meridian-Event-Id", ev.ID)
	req.Header.Set("X-Meridian-Event-Type", ev.Type)
	req.Header.Set("X-Meridian-Delivery-Id", d.ID)
	// La clave de idempotencia: permite al socio detectar el duplicado que un
	// reintento tras timeout puede producir.
	req.Header.Set("X-Meridian-Idempotency-Key", d.ID)
	req.Header.Set("X-Meridian-Timestamp", timestamp.Format(time.RFC3339))
	req.Header.Set("X-Meridian-Signature", sign(ep.Secret, timestamp, ev.Payload))

	return s.client.Do(req)
}

// sign produce la firma HMAC-SHA256 del cuerpo, con el timestamp incluido.
//
// El timestamp entra en la firma para prevenir el ataque de REPETICIÓN: sin él,
// alguien que capture una petición válida puede reenviarla indefinidamente y la
// firma seguirá siendo correcta. Con él, el socio rechaza lo que llegue con más
// de N minutos de antigüedad.
//
// ⚠️ Esto exige que el reloj del socio y el nuestro estén razonablemente
// sincronizados, y hay que documentarlo en el contrato de integración.
// La verificación del lado receptor y la comparación en tiempo constante
// están en la Fase 14.  💸
func sign(secret string, ts time.Time, payload []byte) string {
	mac := hmac.New(sha256.New, []byte(secret))
	fmt.Fprintf(mac, "%d.", ts.Unix())
	mac.Write(payload)
	return "v1=" + hex.EncodeToString(mac.Sum(nil))
}
```

> 💸 **Deudas declaradas.** (1) La verificación de la firma del lado del receptor y
> la comparación en **tiempo constante** —`hmac.Equal`, no `==`— son de la **Fase
> 14**. (2) La validación de la URL contra SSRF sigue pendiente desde la Fase 02 y
> se paga en la **Fase 14**: hoy, un socio puede registrar
> `http://169.254.169.254/` y usar EventRelay como proxy hacia los metadatos de la
> nube. **Está escrito en el código con un TODO y su fase.**

### 6.5 AtlasSync nace

El tercer servicio en nacer y el primero que **depende del mundo exterior**.

Meridian opera en once países. Cada uno tiene su moneda, su código ISO, su zona
horaria y su tipo de cambio del día. Hoy esos datos están copiados a mano en
cuatro archivos de configuración distintos, ligeramente distintos entre sí.

**Las dos fuentes, las dos públicas y sin clave de API:**

- **REST Countries** — `https://restcountries.com/v3.1/all` — países, códigos ISO,
  monedas, idiomas, zonas horarias.
- **Frankfurter** — `https://api.frankfurter.app/latest` — tipos de cambio del BCE.

```go
// services/atlassync/internal/countries/client.go

// Package countries consume la API de REST Countries.
//
// ⚠️ ADVERTENCIA QUE TIENE QUE ESTAR EN EL CÓDIGO, no solo en la documentación:
// esta API es pública, gratuita y puede cambiar de forma, moverse o desaparecer.
// El curso lo asume:
//   - todas las respuestas usadas en pruebas están GRABADAS en testdata/;
//   - el servicio arranca y funciona con ellas;
//   - solo un test marcado 🔥, tras el build tag `live` y excluido de CI, toca
//     la red de verdad.
//
// Que un curso dependa de que un servicio gratuito siga vivo en 2029 es un
// defecto de diseño, y aquí se evita a propósito.
package countries

// Fetcher es lo que AtlasSync necesita de este paquete. Se declara en el
// consumidor (Fase 02); esta copia está aquí solo como documentación.
//
//	type Fetcher interface {
//	    FetchAll(ctx context.Context) ([]Country, error)
//	}

type Client struct {
	http    *http.Client
	baseURL string
	policy  backoff.Policy
	maxBody int64
	logger  *slog.Logger
}

// fields limita lo que pedimos. La respuesta completa de REST Countries son
// varios megas; con ?fields= baja a unos cientos de kilobytes.
//
// Pedir solo lo que se usa no es solo eficiencia: es que un campo que no pides
// no puede romperte el parseo cuando cambie de forma.
const fields = "name,cca2,cca3,ccn3,currencies,languages,timezones,region,subregion,population,flags"

func (c *Client) FetchAll(ctx context.Context) ([]Country, error) {
	u := c.baseURL + "/v3.1/all?fields=" + fields

	resp, err := backoff.Do(ctx, c.policy, func(ctx context.Context) (*http.Response, error) {
		req, err := http.NewRequestWithContext(ctx, http.MethodGet, u, nil)
		if err != nil {
			return nil, err
		}
		req.Header.Set("Accept", "application/json")
		req.Header.Set("User-Agent", "Meridian-AtlasSync/1.0")
		return c.http.Do(req)
	})
	if err != nil {
		return nil, fmt.Errorf("consultando REST Countries: %w", err)
	}
	defer drainAndClose(resp)

	// Decodificación en STREAMING sobre el cuerpo limitado. Es B-06 de la Fase
	// 03 aplicado donde de verdad importa: el documento tiene 250 países con
	// nombres en nueve idiomas.
	var raw []countryDTO
	dec := json.NewDecoder(io.LimitReader(resp.Body, c.maxBody))
	if err := dec.Decode(&raw); err != nil {
		return nil, fmt.Errorf("decodificando la respuesta de REST Countries: %w", err)
	}

	out := make([]Country, 0, len(raw))
	for _, dto := range raw {
		country, err := dto.toDomain()
		if err != nil {
			// Un país mal formado NO aborta la ingesta entera: se registra y se
			// sigue. Con una fuente externa que no controlamos, la tolerancia
			// parcial es la diferencia entre un servicio que funciona y uno que
			// se cae porque un tercero cambió un campo.
			c.logger.Warn("país descartado en la ingesta",
				slog.String("cca3", dto.CCA3),
				slog.String("error", err.Error()))
			continue
		}
		out = append(out, country)
	}

	if len(out) == 0 {
		// Cero países SÍ es un error: significa que la API cambió de forma por
		// completo y estamos descartándolo todo.
		return nil, fmt.Errorf("%w: la respuesta no contenía ningún país válido", ErrUnexpectedShape)
	}
	return out, nil
}
```

> 🧭 **Regla del proyecto para fuentes externas: tolerancia parcial con suelo.**
> Un registro mal formado se descarta y se registra; **cero registros válidos es un
> error**. Sin el suelo, un cambio de formato en la fuente se manifiesta como una
> base de datos que se vacía en silencio.

**Y `singleflight`, contra el rebaño atronador:**

```go
// services/atlassync/internal/fxrates/service.go

type Service struct {
	client Fetcher
	cache  *ttlCache
	// singleflight garantiza que N llamadas concurrentes con la MISMA clave
	// producen UNA sola llamada al exterior; las demás esperan y comparten el
	// resultado.
	//
	// El escenario: la caché de tipos de cambio expira a las 9:00. En ese
	// instante hay cuarenta peticiones en vuelo. Sin singleflight, cuarenta
	// llamadas simultáneas a Frankfurter. Con él, una.
	group singleflight.Group
}

func (s *Service) Latest(ctx context.Context, base string) (Rates, error) {
	if rates, ok := s.cache.Get(base); ok {
		return rates, nil
	}

	// La clave del grupo es la unidad de deduplicación. Si fuera constante,
	// una petición de USD esperaría a una de EUR y recibiría el resultado
	// equivocado — que es un bug muy desagradable.
	v, err, shared := s.group.Do("latest:"+base, func() (any, error) {
		// ⚠️ NO se usa el ctx de la petición que ganó la carrera. Si ESA
		// petición se cancela —el cliente cerró la pestaña—, las otras treinta
		// y nueve que están esperando recibirían un context.Canceled que no es
		// suyo.
		//
		// context.WithoutCancel (Fase 08) conserva los valores de traza y
		// descarta la cancelación. Es exactamente el caso para el que existe.
		fetchCtx, cancel := context.WithTimeout(
			context.WithoutCancel(ctx), 10*time.Second)
		defer cancel()

		rates, err := s.client.Latest(fetchCtx, base)
		if err != nil {
			return nil, err
		}
		s.cache.Set(base, rates, s.ttlWithJitter())
		return rates, nil
	})

	if err != nil {
		return Rates{}, fmt.Errorf("obteniendo tipos de cambio para %s: %w", base, err)
	}
	if shared {
		s.logger.Debug("resultado compartido por singleflight", slog.String("base", base))
	}
	return v.(Rates), nil
}

// ttlWithJitter evita que todas las claves expiren a la vez.
//
// Sin jitter, si se cachean cincuenta monedas en el mismo segundo del arranque,
// las cincuenta expiran en el mismo segundo una hora después, y se produce el
// pico que la caché existía para evitar. El jitter reparte los vencimientos.
//
// Se desarrolla en serio en la Fase 12.
func (s *Service) ttlWithJitter() time.Duration {
	base := s.ttl
	jitter := time.Duration(rand.N(int64(base / 5)))   // ±20%
	return base + jitter
}
```

> ⚠️ **La trampa de `singleflight` que arruina muchas implementaciones:** si la
> llamada compartida falla, **todos los que esperaban reciben el mismo error**. Con
> un socio caído y un reintento agresivo, eso amplifica el fallo en vez de
> contenerlo. `Group.Forget(key)` permite no cachear el fallo, y decidir cuándo
> usarlo es parte del diseño.

### 6.6 Los cinco niveles de prueba

**Esta es la mitad más valiosa de la fase.** El problema: AtlasSync depende de dos
APIs públicas que pueden estar caídas, ser lentas, o cambiar. ¿Cómo se prueba eso
sin que la suite sea intermitente?

**Nivel 1 — Unitario con fake.** Sin HTTP.

```go
// La interfaz es pequeña porque la declara el consumidor.
type fakeFetcher struct {
	countries []countries.Country
	err       error
	calls     int
}

func (f *fakeFetcher) FetchAll(ctx context.Context) ([]countries.Country, error) {
	f.calls++
	if f.err != nil {
		return nil, f.err
	}
	return f.countries, nil
}
```

**Nivel 2 — De componente con `httptest.Server` sirviendo respuestas grabadas.**

```go
// services/atlassync/internal/countries/client_test.go

// newRecordedServer sirve el corpus grabado en testdata/. No toca la red, es
// determinista, y ejercita el cliente HTTP COMPLETO: cabeceras, decodificación,
// límites, clasificación de errores.
func newRecordedServer(t *testing.T, fixture string, status int) *httptest.Server {
	t.Helper()

	body, err := os.ReadFile(filepath.Join("testdata", fixture))
	if err != nil {
		t.Fatalf("leyendo el corpus %s: %v", fixture, err)
	}

	srv := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		// Verificar que mandamos lo que creemos mandar es la mitad del valor de
		// este nivel: detecta el día que alguien borra una cabecera.
		if got := r.Header.Get("Accept"); got != "application/json" {
			t.Errorf("Accept = %q, quería application/json", got)
		}
		w.Header().Set("Content-Type", "application/json")
		w.WriteHeader(status)
		w.Write(body)
	}))
	t.Cleanup(srv.Close)
	return srv
}

func TestClient_FetchAll_RecordedResponse(t *testing.T) {
	srv := newRecordedServer(t, "restcountries_all.json", http.StatusOK)
	c := countries.NewClient(srv.Client(), srv.URL, backoff.DefaultPolicy())

	got, err := c.FetchAll(context.Background())
	if err != nil {
		t.Fatalf("FetchAll() error = %v", err)
	}
	if len(got) < 200 {
		t.Errorf("se decodificaron %d países; el corpus tiene más de 200", len(got))
	}

	// Verificar un país concreto: es lo que detecta un cambio de forma cuando
	// alguien refresque el corpus.
	co, ok := find(got, "COL")
	if !ok {
		t.Fatal("falta Colombia en el resultado")
	}
	if co.Currencies[0].Code != "COP" {
		t.Errorf("moneda de Colombia = %q, quería COP", co.Currencies[0].Code)
	}
}
```

**Nivel 3 — De comportamiento: el servidor simula fallos.**

```go
// TestClient_RetriesOn503 verifica que el cliente reintenta ante un 5xx y se
// rinde ante un 4xx. Es lo que el Nivel 2 no puede probar porque siempre
// responde bien.
func TestClient_RetriesOn503(t *testing.T) {
	var calls int32

	srv := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		n := atomic.AddInt32(&calls, 1)
		if n < 3 {
			w.WriteHeader(http.StatusServiceUnavailable)
			return
		}
		w.Header().Set("Content-Type", "application/json")
		w.Write(recordedBody(t, "restcountries_all.json"))
	}))
	defer srv.Close()

	// Política con Base de 1ms: el test tarda microsegundos y sigue probando la
	// política de verdad.
	p := backoff.Policy{
		Base: time.Millisecond, Max: 10 * time.Millisecond,
		Multiplier: 2, MaxAttempts: 5,
		Rand: rand.New(rand.NewPCG(42, 0)),   // semilla fija: determinista
	}
	c := countries.NewClient(srv.Client(), srv.URL, p)

	if _, err := c.FetchAll(context.Background()); err != nil {
		t.Fatalf("FetchAll() error = %v", err)
	}
	if got := atomic.LoadInt32(&calls); got != 3 {
		t.Errorf("se hicieron %d llamadas, querían 3", got)
	}
}
```

**Nivel 4 — De punta a punta: el servicio completo contra servidores falsos.**

```go
// TestAtlasSync_EndToEnd levanta AtlasSync ENTERO —API, almacén, ingesta— con
// las dos fuentes externas sustituidas por httptest.Server.
//
// Es "end to end" de verdad, y NO toca la red. Esa es la lección de esta fase:
// "end to end" no significa "depender de internet".
func TestAtlasSync_EndToEnd(t *testing.T) {
	countriesSrv := newRecordedServer(t, "restcountries_all.json", http.StatusOK)
	fxSrv := newRecordedServer(t, "frankfurter_latest.json", http.StatusOK)

	app := atlassync.NewForTest(t, atlassync.Config{
		CountriesBaseURL: countriesSrv.URL,
		FxBaseURL:        fxSrv.URL,
	})

	// Disparar la ingesta por su endpoint.
	rec := httptest.NewRecorder()
	app.ServeHTTP(rec, httptest.NewRequest(http.MethodPost, "/sync", nil))
	if rec.Code != http.StatusAccepted {
		t.Fatalf("POST /sync = %d, quería 202", rec.Code)
	}
	app.WaitForSync(t, 5*time.Second)

	// Y consultar el resultado por la API pública.
	rec = httptest.NewRecorder()
	app.ServeHTTP(rec, httptest.NewRequest(http.MethodGet, "/countries/COL", nil))
	if rec.Code != http.StatusOK {
		t.Fatalf("GET /countries/COL = %d, quería 200", rec.Code)
	}
}
```

**Nivel 5 — 🔥 El único que toca la red, tras un build tag, excluido de CI.**

```go
//go:build live

// services/atlassync/internal/countries/live_test.go
//
// 🔥 Este archivo SOLO se compila con -tags=live y NO corre en CI.
//
// Su propósito no es verificar nuestro código: es detectar que la API real
// cambió de forma. Se corre a mano, periódicamente, y cuando falla la acción es
// refrescar el corpus de testdata/ y adaptar el DTO.
package countries_test

func TestLive_RESTCountriesShapeUnchanged(t *testing.T) {
	if testing.Short() {
		t.Skip("test contra la red; omitido con -short")
	}

	ctx, cancel := context.WithTimeout(context.Background(), 30*time.Second)
	defer cancel()

	c := countries.NewClient(http.DefaultClient, "https://restcountries.com", backoff.DefaultPolicy())

	got, err := c.FetchAll(ctx)
	if err != nil {
		// Un fallo aquí puede ser de la API, no nuestro. El mensaje tiene que
		// decirlo, o alguien va a perder una tarde buscando un bug propio.
		t.Fatalf("la API real falló (puede ser suya, no nuestra): %v", err)
	}
	if len(got) < 200 {
		t.Errorf("la API devolvió %d países; el corpus tiene más de 200: ¿cambió la forma?", len(got))
	}
}
```

> 🧭 **Regla del proyecto, y es la que define la fase.** **`go test ./...` no toca
> la red. Nunca.** Un test que depende de internet es intermitente por diseño:
> falla en el avión, falla en el tren, falla el día que el proveedor tiene un
> incidente, y el equipo aprende a reintentar el pipeline en vez de a mirar el
> fallo. **Ese aprendizaje es el verdadero coste**, y es mucho mayor que el valor
> del test.

Y la verificación de que la regla se cumple, porque una regla sin verificación es
un deseo:

```go
// services/atlassync/internal/atlassync/nonetwork_test.go

// TestNoNetworkAccess instala un Transport que falla ante CUALQUIER intento de
// conexión y corre las rutas principales. Si algo intenta salir a la red, este
// test lo dice con nombre y apellidos.
func TestNoNetworkAccess(t *testing.T) {
	blocked := &http.Transport{
		DialContext: func(ctx context.Context, network, addr string) (net.Conn, error) {
			return nil, fmt.Errorf("PROHIBIDO: intento de conexión a %s", addr)
		},
	}
	client := &http.Client{Transport: blocked}

	app := atlassync.NewForTest(t, atlassync.Config{HTTPClient: client})

	rec := httptest.NewRecorder()
	app.ServeHTTP(rec, httptest.NewRequest(http.MethodGet, "/countries", nil))

	if rec.Code >= 500 {
		t.Errorf("una ruta de lectura intentó salir a la red: %s", rec.Body.String())
	}
}
```

### 6.7 Y por fin: `go.uber.org/mock`

Seis fases después de que la Fase 04 lo aplazara. **La justificación, ahora que
hay un caso real:**

Todos los tests que hemos escrito hasta aquí verifican **estado**: el work item
quedó guardado, la entrega pasó a `dead`, el país se decodificó. Para eso el fake
gana.

Pero ahora hay un requisito distinto:

> *"El cliente tiene que reintentar exactamente tres veces ante un 503, con
> retroceso creciente, y no reintentar nunca ante un 400."*

**Aquí no hay estado que mirar.** El resultado final en los dos casos es el mismo:
un error. Lo que importa es **cuántas veces se llamó y en qué orden**, y eso es
verificación de interacción.

¿Y el contador `atomic.AddInt32` del Nivel 3? Funciona, y es la respuesta correcta
para ese caso. Deja de serlo cuando la expectativa se vuelve más rica:

```go
// Lo que el fake con contador NO expresa bien:
//   - que la PRIMERA llamada lleve la cabecera X y la tercera la cabecera Y
//   - que entre la llamada 1 y la 2 pasen al menos N milisegundos
//   - que NO se llame a Fetch después de un 400
//   - que el orden entre dos dependencias distintas sea el correcto
//
// Escribir todo eso a mano es escribir un mock, peor y sin mensajes de error
// útiles.
```

```go
// services/atlassync/internal/atlassync/ports.go

// La directiva vive JUNTO a la interfaz: quien la cambie ve que hay un mock que
// regenerar.
//
//go:generate mockgen -source=ports.go -destination=mocks_test.go -package=atlassync_test

// RatesFetcher obtiene tipos de cambio de una fuente externa.
type RatesFetcher interface {
	Latest(ctx context.Context, base string) (fxrates.Rates, error)
	Historical(ctx context.Context, base string, day time.Time) (fxrates.Rates, error)
}
```

```go
// Y el test que justifica el generador:
func TestService_DoesNotRefetchAfterPermanentError(t *testing.T) {
	ctrl := gomock.NewController(t)   // desde 1.5 no hace falta ctrl.Finish()

	mockFetcher := NewMockRatesFetcher(ctrl)

	// La expectativa RICA: se llama exactamente UNA vez, con esta base, y
	// devuelve un error permanente. Si el servicio reintentara, este test
	// falla con un mensaje que dice cuántas llamadas hubo de más.
	mockFetcher.EXPECT().
		Latest(gomock.Any(), "XYZ").
		Return(fxrates.Rates{}, backoff.ErrPermanent).
		Times(1)

	svc := atlassync.NewService(mockFetcher, newTestCache(), testLogger(t))

	_, err := svc.Latest(context.Background(), "XYZ")
	if !errors.Is(err, backoff.ErrPermanent) {
		t.Fatalf("Latest() error = %v, quería ErrPermanent", err)
	}

	// La segunda llamada tampoco debe ir al exterior: el error permanente se
	// cachea negativamente. Si fuera, `Times(1)` falla.
	_, _ = svc.Latest(context.Background(), "XYZ")
}
```

> 🧭 **Regla del proyecto, cerrada.** **Función → fake → generado**, y se sube de
> escalón solo cuando el anterior no alcanza:
> - **Función**: la dependencia es una operación.
> - **Fake**: quieres verificar **estado** y la interfaz es pequeña.
> - **Generado**: quieres verificar **interacción rica** —cuántas veces, en qué
>   orden, con qué argumentos—, o la interfaz es lo bastante grande como para que
>   el fake se vuelva mantenimiento.
>
> En todo Meridian, el generado se usa en **un** sitio. Esa proporción es el
> resultado, no la meta.

### 6.8 `storeagent sync`

```go
// services/storeagent/internal/sync/sync.go

// Run sube los movimientos pendientes a ClearingHouse.
//
// Tres propiedades que lo hacen usable en una tienda con red intermitente:
//  1. REANUDABLE: se marca lo subido en SQLite tras confirmar la recepción, así
//     que un corte a mitad no pierde ni repite.
//  2. ACOTADO EN MEMORIA: se sube por lotes con cursor; un millón de movimientos
//     acumulados no se cargan enteros (la lección de B-06, Fase 03).
//  3. IDEMPOTENTE: cada lote lleva el hash de su contenido y ClearingHouse
//     descarta los duplicados, así que reintentar tras un timeout es seguro.
func (s *Syncer) Run(ctx context.Context) (Report, error) {
	var report Report

	for {
		select {
		case <-ctx.Done():
			// Devolver el informe PARCIAL y no un error: se subió lo que se
			// subió, y eso hay que reportarlo.
			return report, ctx.Err()
		default:
		}

		batch, err := s.store.PendingBatch(ctx, s.batchSize)
		if err != nil {
			return report, fmt.Errorf("leyendo movimientos pendientes: %w", err)
		}
		if len(batch) == 0 {
			return report, nil
		}

		accepted, err := s.client.Upload(ctx, s.storeID, batch)
		if err != nil {
			report.Failed += len(batch)
			// El error se devuelve con lo subido hasta ahora: la próxima
			// ejecución retoma donde esta se quedó.
			return report, fmt.Errorf("subiendo el lote de %d movimientos: %w", len(batch), err)
		}

		// Marcar como sincronizado SOLO lo que el servidor confirmó. Si el
		// servidor aceptó 48 de 50, los otros 2 se reintentan.
		if err := s.store.MarkSynced(ctx, accepted, s.clock.Now()); err != nil {
			// ⚠️ Aquí hay un caso incómodo y hay que decirlo: el servidor ya
			// tiene los movimientos y nosotros no pudimos marcarlos. La próxima
			// ejecución los volverá a subir, y la idempotencia del servidor es
			// lo ÚNICO que impide el duplicado. Por eso existe el content_hash.
			return report, fmt.Errorf("marcando %d movimientos como sincronizados: %w",
				len(accepted), err)
		}

		report.Uploaded += len(accepted)
		report.Batches++
	}
}
```

---

## ⚰️ 7. Autopsia y errores comunes

### ⚰️ Autopsia: el reintento que amplificó la caída

**El cadáver.** Un martes a las 14:32, el socio principal de Meridian —la pasarela
de pagos— tuvo un incidente de 40 segundos. EventRelay tenía 8.000 entregas
pendientes para ese endpoint.

El código del reintento era este:

```go
// ☕
const maxAttempts = 5

func (c *Client) Send(ctx context.Context, d relay.Delivery) error {
	for attempt := 1; attempt <= maxAttempts; attempt++ {
		resp, err := c.http.Post(d.URL, "application/json", bytes.NewReader(d.Payload))
		if err == nil && resp.StatusCode < 300 {
			resp.Body.Close()
			return nil
		}
		if resp != nil {
			resp.Body.Close()
		}
		time.Sleep(2 * time.Second)
	}
	return errors.New("agotados los intentos")
}
```

**La reconstrucción, segundo a segundo:**

```text
14:32:00  el socio devuelve 503. 8.000 entregas reciben el error.
14:32:02  8.000 reintentos SIMULTÁNEOS (retroceso fijo, sin jitter).
14:32:04  8.000 más.
14:32:06  8.000 más.
14:32:08  8.000 más. → 40.000 peticiones en 8 segundos.
14:32:40  el socio se recupera... y recibe la cola acumulada de golpe.
14:32:41  el socio vuelve a caerse, esta vez por SOBRECARGA.
          → y ahora la caída la estamos causando nosotros.
14:51:00  se recupera de verdad, tras 19 minutos.
```

**Una caída de 40 segundos se convirtió en una de 19 minutos**, y la causó el
reintento.

**El informe forense:**

| | El código ☕ | El de §6.2 |
|---|---|---|
| Peticiones en los primeros 10 s tras el fallo | **40.000** | ~8.000, repartidas |
| Distribución temporal de los reintentos | 4 picos exactos | uniforme en la ventana |
| Peticiones a un endpoint con 4xx | **5 por entrega** | 1 |
| ¿Respeta `Retry-After`? | **no** | sí, y manda |
| ¿Para cuando el socio sigue caído? | no | sí, el cortacircuitos |
| ¿Se puede cancelar el reintento al apagar? | **no** (`time.Sleep` no mira el contexto) | sí |
| ¿Reutiliza conexiones? | **no** (cuerpo sin drenar) | sí |
| Bug adicional: el cuerpo en el segundo intento | **vacío** (`bytes.Reader` consumido) | nuevo en cada intento |

**Y el bug silencioso que nadie vio hasta leer el código con calma:** el
`bytes.NewReader` se crea **fuera** del bucle. Se consume en el primer intento, y
del segundo en adelante **manda un cuerpo vacío**. El socio recibía cuatro
peticiones vacías tras cada fallo — que, además de inútiles, podrían haberse
interpretado como eventos válidos con carga vacía.

**Las cuatro causas de la muerte:**

1. **Reintentar sin clasificar.** El 4xx se reintentaba igual que el 5xx.
2. **Retroceso fijo sin *jitter*.** Todo el mundo a la vez, cuatro veces.
3. **Sin cortacircuitos.** Nada paró la avalancha cuando ya era evidente que el
   socio estaba caído.
4. **Sin límite de tasa por destino.** La cola entera podía dirigirse a un solo
   endpoint.

**Y la parte justa:** el retroceso exponencial con jitter, la clasificación y el
cortacircuitos **vienen todos por defecto en Resilience4j**. Quien escribió esto
venía de Java, donde nunca tuvo que pensarlo porque la librería lo pensaba por él.
El error no fue no saber: fue **traducir la llamada sin traducir la política**.

> ☕ **El patrón a memorizar.** Un reintento mal diseñado **amplifica** el fallo
> que pretendía absorber. Las tres decisiones —qué reintentar, cuánto esperar, y
> cuándo parar del todo— son tres funciones distintas, y si tu código solo tiene la
> tercera, tienes un multiplicador de caídas.

### Errores comunes

**1. `http.DefaultClient` en producción.**
*Síntoma:* goroutines colgadas indefinidamente.
*Causa:* no tiene `Timeout` ni contexto por defecto.
*Fix mínimo:* cliente propio con `Timeout` y **siempre** `NewRequestWithContext`.
El linter `noctx` lo detecta.

**2. Un `http.Client` nuevo por petición.**
*Síntoma:* latencia alta, agotamiento de puertos efímeros, muchos `TIME_WAIT`.
*Causa:* cada cliente trae su `Transport` y su pool; se tira en cada uso.
*Fix mínimo:* uno por destino, construido en el arranque.

**3. `resp.Body` sin cerrar.**
*Síntoma:* fuga de conexiones y de descriptores.
*Causa:* en el **cliente**, cerrar es tuyo.
*Fix mínimo:* `defer resp.Body.Close()` tras comprobar el error. `bodyclose` lo
detecta y está en el `.golangci.yml` desde la Fase 00.

**4. `resp.Body` cerrado sin drenar.**
*Síntoma:* el keep-alive no funciona; handshake TLS en cada petición.
*Causa:* una conexión solo vuelve al pool si el cuerpo se consumió entero.
*Fix mínimo:* `io.Copy(io.Discard, io.LimitReader(body, 64<<10))` antes de cerrar.

**5. `MaxIdleConnsPerHost` con el valor por defecto.**
*Síntoma:* bajo carga contra pocos hosts, latencia alta y conexiones nuevas
constantes.
*Causa:* el valor por defecto es **2**.
*Fix mínimo:* subirlo al nivel de concurrencia esperado.

**6. El cuerpo reutilizado entre reintentos.**
*Síntoma:* el segundo intento manda un cuerpo vacío.
*Causa:* un `io.Reader` se consume.
*Fix mínimo:* crear el `Reader` dentro de la función que se reintenta, o
`req.GetBody`.

**7. Reintentar un 4xx.**
*Síntoma:* cinco peticiones idénticas fallando igual; posible bloqueo del socio.
*Causa:* no hay clasificación.
*Fix mínimo:* `Classify` como función pura, con su tabla.

**8. Retroceso sin *jitter*.**
*Síntoma:* picos exactos de tráfico tras cada fallo.
*Causa:* todos los clientes calculan la misma espera.
*Fix mínimo:* *full jitter*.

**9. `time.Sleep` en el bucle de reintento.**
*Síntoma:* el apagado tarda hasta el retroceso máximo.
*Causa:* `Sleep` no mira el contexto.
*Fix mínimo:* `select` con `time.NewTimer` y `ctx.Done()`.

**10. Ignorar `Retry-After`.**
*Síntoma:* el socio bloquea a Meridian.
*Causa:* la cabecera no se lee.
*Fix mínimo:* `ParseRetryAfter`, con las **dos** formas del RFC.

**11. Un cortacircuitos global.**
*Síntoma:* un socio caído corta las entregas de todos los demás.
*Causa:* un solo `Breaker` compartido.
*Fix mínimo:* registro de cortacircuitos indexado por endpoint.

**12. `singleflight` con clave constante.**
*Síntoma:* una petición de USD recibe los tipos de EUR.
*Causa:* la clave no distingue las variantes.
*Fix mínimo:* la clave incluye todos los parámetros que cambian el resultado.

**13. `singleflight` con el contexto del ganador.**
*Síntoma:* si el cliente que ganó la carrera se desconecta, todos los que
esperaban reciben `context.Canceled`.
*Causa:* el contexto de una petición gobierna el trabajo compartido.
*Fix mínimo:* `context.WithoutCancel` y un plazo propio.

**14. Un test que toca la red.**
*Síntoma:* la suite es intermitente; el equipo aprende a reintentar el pipeline.
*Causa:* no hay corpus grabado.
*Fix mínimo:* `testdata/` más `httptest.Server`, y el test de §6.6 que lo
verifica.

### 🧨 Rompe a propósito

**Reproduce la amplificación de la autopsia en tu máquina**, a escala:

```go
// labs/backoff-lab/amplification_test.go

// TestAmplification mide cuántas peticiones llegan al socio en los primeros 10
// segundos tras un fallo, con las dos políticas.
func TestAmplification(t *testing.T) {
	const pending = 500

	for _, tc := range []struct {
		name   string
		policy backoff.Policy
	}{
		{"retroceso fijo sin jitter", backoff.Policy{
			Base: 2 * time.Second, Multiplier: 1, MaxAttempts: 5,
			Rand: rand.New(rand.NewPCG(1, 0)),
		}},
		{"exponencial con full jitter", backoff.Policy{
			Base: 500 * time.Millisecond, Max: 30 * time.Second,
			Multiplier: 2, MaxAttempts: 5,
			Rand: rand.New(rand.NewPCG(1, 0)),
		}},
	} {
		t.Run(tc.name, func(t *testing.T) {
			// Histograma de peticiones por segundo durante 10 s.
			buckets := make([]int, 10)
			for i := 0; i < pending; i++ {
				elapsed := time.Duration(0)
				for attempt := 1; attempt <= tc.policy.MaxAttempts; attempt++ {
					elapsed += tc.policy.Backoff(attempt, 0)
					if sec := int(elapsed.Seconds()); sec < len(buckets) {
						buckets[sec]++
					}
				}
			}
			t.Logf("%s → peticiones por segundo: %v", tc.name, buckets)
		})
	}
}
```

```text
retroceso fijo sin jitter  → [0 0 500 0 500 0 500 0 500 0]
exponencial con full jitter → [128 97 74 61 48 39 31 24 19 15]
```

**Los picos de 500 frente a una curva que decae.** El socio que recibe la primera
serie ve cuatro martillazos; el que recibe la segunda ve una recuperación gradual.

Y la segunda mitad del experimento, que es la que convence: **haz que el servidor
falso se caiga si recibe más de 200 peticiones por segundo**, y corre las dos
políticas. La primera nunca se recupera; la segunda sí.

---

## 🧪 8. Ejercicios (28)

**🟢 Fácil (1–6)**

1. Demuestra que `http.DefaultClient` no tiene tiempo límite, con el servidor que
   nunca responde. *Criterio:* el test se cuelga sin contexto y falla en 2 s con
   él.
2. Construye el cliente completo con los cinco plazos por fase. *Criterio:* para
   cada uno, en una línea, qué escenario ataja **y cuál no**.
3. Provoca el aviso de `bodyclose` olvidando un `Close`. *Criterio:* pegas el
   mensaje del linter y explicas la fuga.
4. Usa `curl -w` para desglosar los tiempos de Frankfurter. *Criterio:* separas el
   tiempo de proceso del servidor del de red, con la resta.
5. Escribe `ParseRetryAfter` con las dos formas del RFC. *Criterio:* una tabla con
   segundos, fecha futura, fecha pasada, negativo y basura.
6. Graba el corpus de las dos APIs en `testdata/`. *Criterio:* documentas el
   comando de refresco y el tamaño de cada archivo.

**🟡 Intermedio (7–17)**

7. Escribe `Classify` con la tabla completa. *Criterio:* al menos veinte casos,
   incluidos los errores de red envueltos en `*url.Error`, DNS no encontrado, y
   `context.Canceled` frente a `DeadlineExceeded`.
8. Implementa `Backoff` con *full jitter* y `Rand` inyectado. *Criterio:* el test
   es determinista con semilla fija y verifica el rango, no un valor exacto.
9. Implementa el bucle `Do` con cancelación durante la espera. *Criterio:* un test
   cancela el contexto a mitad del retroceso y verifica que sale en menos de 50 ms.
10. Reproduce el bug del cuerpo reutilizado. *Criterio:* el servidor falso reporta
    que el segundo intento llegó vacío; lo arreglas y lo verificas.
11. Configura `MaxIdleConnsPerHost` y mide la diferencia con 100 peticiones
    concurrentes al mismo host. *Criterio:* cuentas conexiones nuevas con
    `httptrace` o con `netstat`.
12. Escribe el cortacircuitos con sus tres estados. *Criterio:* un test recorre
    cerrado → abierto → semiabierto → cerrado con un reloj falso, sin esperas
    reales.
13. Implementa el registro de cortacircuitos por endpoint. *Criterio:* un test con
    dos endpoints demuestra que uno caído no afecta al otro.
14. Añade limitación de tasa por endpoint con `golang.org/x/time/rate`.
    *Criterio:* con límite de 10/s y 50 entregas, la duración total es la esperada
    y el contexto cancela la espera.
15. Implementa `singleflight` en los tipos de cambio. *Criterio:* un test con 40
    goroutines concurrentes verifica **una** llamada al exterior, y otro verifica
    que la cancelación de una no afecta a las demás.
16. Monta el Nivel 2 con el corpus grabado. *Criterio:* el test verifica también
    las cabeceras que se envían.
17. **Línea de comandos.** Con `GODEBUG=http2debug=1`, comprueba si la reutilización
    de conexiones funciona. *Criterio:* muestras la diferencia con y sin drenado del
    cuerpo.

**🟠 Difícil (18–24)**

18. Reproduce la amplificación del 🧨 con las dos políticas y el histograma.
    *Criterio:* los números están, y añades el experimento del servidor que se cae
    por sobrecarga.
19. Monta los cinco niveles de prueba de AtlasSync. *Criterio:* los niveles 1 a 4
    corren sin red; el 5 está tras `-tags=live` y no está en el objetivo de `make
    test`.
20. Escribe `TestNoNetworkAccess`. *Criterio:* falla de verdad si introduces una
    llamada a la red en una ruta de lectura, y lo demuestras.
21. Introduce `go.uber.org/mock` en **un** sitio. *Criterio:* (a) el test verifica
    interacción rica que un fake no expresaría bien; (b) escribes por qué ahí y no
    en los otros quince; (c) la directiva `//go:generate` está junto a la interfaz
    y `go generate ./...` funciona.
22. Escribe el cliente de Frankfurter con tolerancia parcial y suelo. *Criterio:*
    un corpus con tres monedas corruptas produce advertencias y sigue; un corpus
    vacío produce error.
23. Implementa `storeagent sync` reanudable por lotes. *Criterio:* (a) cortas la
    red a mitad y al reanudar no pierde ni repite; (b) con un millón de movimientos
    la memoria se mantiene acotada, y lo mides; (c) el servidor que acepta 48 de 50
    se maneja correctamente.
24. **Detección de ☕.** Te dan el código de la autopsia. Refactorízalo.
    *Criterio:* identificas los **cinco** problemas —incluido el cuerpo
    reutilizado—, y para cada uno das la corrección mínima y la refactorización
    correcta por separado.

**🔴 Muy difícil (25–28)**

25. **El cliente resiliente, probado bajo caos.** Somete al cliente de EventRelay
    a un servidor que falla de forma aleatoria: 20% de 503, 10% de timeouts, 5% de
    conexiones cerradas a mitad de la respuesta, y un 1% de cuerpos gigantes.
    *Rúbrica:* (a) ninguna entrega se pierde en silencio: todas terminan en
    `delivered` o `dead` con su historial; (b) ninguna goroutine se fuga tras mil
    entregas (test de la Fase 07); (c) la memoria se mantiene acotada pese a los
    cuerpos gigantes; (d) mides el rendimiento y la tasa de éxito; (e) con una
    semilla fija el experimento es reproducible.
26. **El contrato con el socio, documentado y verificado.** Escribe
    `docs/webhooks.md`: el contrato de integración que Meridian entrega a un socio
    nuevo. *Rúbrica:* (a) formato de la petición, cabeceras, algoritmo de firma con
    ejemplo verificable a mano; (b) política de reintentos con los tiempos exactos
    y el comportamiento ante `Retry-After`; (c) qué garantías se dan —al menos una
    entrega, no exactamente una— y qué exige eso del socio; (d) la ventana de
    validez del timestamp y qué pasa si su reloj se desvía; (e) **un test que
    verifica que la implementación cumple el documento**, para que no puedan
    divergir.
27. **El presupuesto de fallos.** Diseña y mide la política completa de EventRelay
    para los treinta socios. *Rúbrica:* (a) calculas el número máximo de peticiones
    por segundo que Meridian puede generar hacia un socio en el peor caso, con la
    política actual, y lo demuestras; (b) ajustas la política para que ese número
    sea aceptable y justificas el valor con el socio en mente; (c) mides cuánto
    tarda el sistema en drenar 10.000 entregas pendientes tras una caída de 5
    minutos; (d) identificas el cuello de botella real y dices qué lo movería; (e)
    comparas con lo que Resilience4j habría configurado por defecto y dices en qué
    te apartaste.
28. **El corpus que no envejece.** Diseña el mecanismo que mantiene `testdata/`
    sincronizado con las APIs reales sin que la suite dependa de ellas. *Rúbrica:*
    (a) un comando refresca el corpus y muestra un diff legible de qué cambió en la
    forma; (b) un test 🔥 detecta la divergencia y falla con un mensaje que dice
    exactamente qué campo cambió; (c) el corpus está minimizado —solo los campos que
    se usan— y explicas el intercambio frente a guardar la respuesta completa; (d)
    hay un procedimiento escrito de qué hacer cuando la API cambia de forma; (e)
    demuestras el flujo completo simulando un cambio en el corpus.

**🔥 Opcionales**

- Implementa la deduplicación de peticiones con `httptrace` para ver exactamente
  cuándo se reutiliza una conexión y cuándo se abre una nueva. Es la herramienta
  que resuelve las discusiones sobre keep-alive.
- Compara tu cortacircuitos con `sony/gobreaker` leyendo su código. Son unas 300
  líneas y vas a reconocer cada decisión.
- Investiga qué pasa con HTTP/2 y el pool de conexiones: el modelo cambia por
  completo (multiplexación sobre una conexión) y buena parte de §6.1 no aplica
  igual. Es una tarde bien invertida si tus socios lo usan.

---

### 🔴 Desafíos de cierre

> Tres ejercicios de dificultad alta que **no cuentan en el total de la sección** y
> no son parte del recorrido base.

**D1 — La resiliencia como `RoundTripper` apilable.**
Reescribe toda la resiliencia de EventRelay —reintentos, cortacircuitos, límite de
tasa, trazas, métricas— como `http.RoundTripper` componibles en vez de como lógica
dentro del `Sender`.
*Rúbrica:* (a) cada preocupación es un `RoundTripper` que envuelve al siguiente, y
el orden de la pila importa —documéntalo—; (b) el `Sender` queda reducido a
construir la petición y leer la respuesta; (c) **el `Client` resultante se puede
pasar a cualquier librería** que acepte un `*http.Client`, y eso es el punto entero
del ejercicio; (d) demuestras que la pila funciona igual con el cliente de AtlasSync
sin duplicar nada; (e) comparas con la composición de decoradores de Resilience4j y
di qué modelo se lee mejor.

**D2 — El cliente generado frente al escrito.**
Escribe la especificación OpenAPI de REST Countries —al menos la parte que usas— y
genera el cliente con `oapi-codegen`.
*Rúbrica:* (a) el cliente generado pasa los mismos tests que el escrito a mano; (b)
comparas líneas, legibilidad y qué pasa cuando la API cambia un campo; (c)
identificas qué **no** puedes expresar en OpenAPI de esta API concreta y cómo lo
resuelves; (d) mides el rendimiento de los dos, y si no hay diferencia, lo dices;
(e) das una recomendación para una API externa que no controlas frente a una interna
que sí.

**D3 — El clasificador, fuzzeado.** 🕰️
`Classify` es una función pura sobre respuestas y errores: es un candidato perfecto
para fuzzing, que llega en la Fase 08.
*Rúbrica:* (a) escribes el fuzz test que genera códigos de estado, cabeceras y
errores envueltos arbitrariamente; (b) el invariante: `Classify` nunca entra en
panic y siempre devuelve uno de los cuatro valores; (c) añades un invariante más
fuerte: **todo lo clasificado como `Retryable` tiene que ser reintentable de
verdad**, y buscas contraejemplos; (d) el corpus descubierto se commitea; (e) si
encuentras un caso donde la clasificación es discutible, lo documentas como decisión
en vez de como bug.

---

## 📚 9. Referencias

### Documentación oficial

- **`net/http` (lado cliente)** — https://pkg.go.dev/net/http#Client y
  https://pkg.go.dev/net/http#Transport — lee la documentación de `Transport`
  **entera**: todos los plazos y `MaxIdleConnsPerHost` están ahí.
- **`net/http/httptrace`** — https://pkg.go.dev/net/http/httptrace — para ver el
  ciclo de vida real de una petición.
- **`golang.org/x/sync/singleflight`** —
  https://pkg.go.dev/golang.org/x/sync/singleflight
- **`golang.org/x/time/rate`** — https://pkg.go.dev/golang.org/x/time/rate — el
  *token bucket* de la stdlib extendida.
- **`crypto/hmac`** — https://pkg.go.dev/crypto/hmac — y fíjate en `hmac.Equal` y
  en por qué existe.
- **`go.uber.org/mock`** — https://github.com/uber-go/mock — el sucesor mantenido
  de `golang/mock`.
- **RFC 9110 §10.2.3 (`Retry-After`)** —
  https://www.rfc-editor.org/rfc/rfc9110#field.retry-after — las dos formas.
- **REST Countries** — https://restcountries.com · **Frankfurter** —
  https://frankfurter.dev

### Libros

- **Let's Go Further** — Alex Edwards. Cubre clientes HTTP, limitación de tasa y
  pruebas con `httptest` con el mismo enfoque de stdlib.
- **Release It!** — Michael Nygard. **La referencia sobre estabilidad de
  sistemas**, y de donde vienen los patrones de esta fase: cortacircuitos,
  *bulkhead*, *timeout*, *fail fast*. No es de Go y es la lectura más valiosa de
  la fase.
- **Site Reliability Engineering** (Google) — el capítulo *Handling Overload* y el
  de *Addressing Cascading Failures* describen exactamente la autopsia de §7.
- **100 Go Mistakes** — Harsanyi, errores #74 a #77: el cliente por defecto, el
  cuerpo sin cerrar, los timeouts.

### Artículos y charlas

- **The complete guide to Go net/http timeouts** — Filippo Valsorda,
  https://blog.cloudflare.com/the-complete-guide-to-golang-net-http-timeouts/ —
  ya era la referencia de la Fase 05; la mitad del cliente está ahí.
- **Exponential Backoff And Jitter** — AWS Architecture Blog,
  https://aws.amazon.com/blogs/architecture/exponential-backoff-and-jitter/ — **la
  fuente del *full jitter* de §6.2**, con las simulaciones que lo justifican.
- **Timeouts, retries and backoff with jitter** — Amazon Builders' Library,
  https://aws.amazon.com/builders-library/timeouts-retries-and-backoff-with-jitter/
  — más completo que el anterior e igual de práctico.
- **Circuit Breaker** — Martin Fowler,
  https://martinfowler.com/bliki/CircuitBreaker.html — el patrón, con sus estados.
- **Don't use the default HTTP client in production** — busca artículos con este
  título; hay varios y todos dicen lo mismo, que es la señal de que es importante.
- **Go: singleflight, the thundering herd problem** — varios buenos; busca los que
  cubran la trampa del error compartido.
- **Testing HTTP clients in Go** — busca artículos sobre `httptest.Server` y
  respuestas grabadas.

### Video

- **GopherCon: Resilience patterns in Go** — busca charlas posteriores a 2019.
- **AWS re:Invent: Cascading failures** — no es de Go y explica la autopsia mejor
  que ningún texto.
- **JustForFunc: HTTP client internals** — Francesc Campoy, sobre el `Transport`.

> ⚠️ Mucho material sobre clientes HTTP en Go es anterior a
> `http.NewRequestWithContext` (Go 1.13) y usa `req.WithContext` o directamente
> nada. **Si un ejemplo no lleva contexto, es de antes de 2019.** Y lo que hable de
> `golang/mock` está archivado: el sucesor es `go.uber.org/mock`.

### Orden de lectura sugerido

**Antes de escribir código:** *Timeouts, retries and backoff with jitter* de
Amazon. Cuarenta minutos, y es lo que separa un reintento que ayuda de uno que
amplifica.
**Durante:** la documentación de `http.Transport` cuando configures el cliente, y
el artículo de Valsorda cuando un plazo no haga lo que esperas.
**Después:** *Release It!* de Nygard, al menos la parte de patrones de estabilidad.
Es el libro que hace que entiendas por qué el cortacircuitos existe, y se lee en un
par de tardes.

---

## ⚖️ 10. Veredicto y cierre

### ⚖️ Cuándo NO usar esto

- **Cuando ya tienes una malla de servicios.** Istio, Linkerd o un proxy lateral
  hacen reintentos, cortacircuitos, límite de tasa y timeouts **fuera de tu
  proceso**, con política centralizada y sin que ninguna aplicación los
  implemente. Si tu plataforma la tiene, escribir esto en Go es duplicar — y peor,
  porque **dos capas de reintento se multiplican**: tres intentos de la aplicación
  por tres del proxy son nueve peticiones. Ese bug es real y sutil.
- **Cuando Resilience4j ya está en tu stack y funciona.** Hace más que lo que
  hemos escrito: ventana deslizante, umbral por porcentaje, detección de llamadas
  lentas, *bulkhead*, métricas integradas. Si el equipo lo conoce y está
  configurado, ese es un argumento serio a favor de quedarse en Java para un
  servicio que integra con muchos terceros.
- **Cuando el escenario de integración es un sistema de mensajería, no HTTP.** Si
  puedes publicar en una cola y que el consumidor tire cuando pueda, casi todo esto
  sobra: la cola es el reintento, el retroceso y la contrapresión. **EventRelay
  existe porque los socios de Meridian solo aceptan webhooks**, y eso es una
  restricción del dominio, no una elección de arquitectura.
- **Y sobre los mocks generados**: si tu código integra con un SDK de nube con
  interfaces de treinta métodos, escribir fakes **sí** es prohibitivo y el
  generador es la respuesta correcta desde el primer día. La regla del curso
  —función, fake, generado— está calibrada para interfaces pequeñas declaradas en
  el consumidor. Con interfaces que te vienen dadas, el cálculo cambia.

### 📖 Diccionario Java ⇄ Go de esta fase

| Java / Spring | Go | Dónde se rompe la equivalencia |
|---|---|---|
| `RestTemplate` | `*http.Client` | **Sin timeout por defecto en Go.** `RestTemplate` tampoco lo trae, y en Spring Boot se configura; aquí hay que acordarse |
| `WebClient` (reactivo) | `*http.Client` + goroutines | No hay API reactiva: la concurrencia son goroutines bloqueantes, que se leen mejor |
| `HttpClient` (Java 11) | `*http.Client` | El más parecido en diseño. Los dos separan cliente, petición y respuesta |
| `@FeignClient` | una interfaz declarada en el consumidor + una implementación escrita | **No hay generación desde la interfaz.** Se escribe el cliente; unas 40 líneas |
| `ClientHttpRequestInterceptor` | envolver el `RoundTripper` | Mismo patrón de composición que el middleware del servidor |
| `RestTemplate` con pool de Apache | `http.Transport` | ⚠️ `MaxIdleConnsPerHost` por defecto es **2** |
| `connectTimeout` / `readTimeout` | `DialContext.Timeout` / `ResponseHeaderTimeout` | Go los separa en más fases y además tiene un `Timeout` global que los cubre todos |
| `@Retryable(maxAttempts=3)` | un bucle escrito, con tres funciones separadas | Sin anotación. A cambio, la clasificación y el retroceso son funciones puras probables con tabla |
| `@Recover` | el `return` tras agotar intentos | Explícito |
| `RetryPolicy` / `BackOffPolicy` | `backoff.Policy` escrito | Resilience4j trae *full jitter*; aquí se escribe |
| `CircuitBreaker` de Resilience4j | `circuit.Breaker` escrito, o `sony/gobreaker` | Mismos tres estados. Resilience4j hace más: ventana deslizante, llamadas lentas, métricas |
| `Bulkhead` | semáforo por destino (canal con búfer, o `semaphore.Weighted`) | Escrito, y es lo que ya hacía el dispatcher de la Fase 06 |
| `RateLimiter` / Bucket4j | `golang.org/x/time/rate` | *Token bucket* equivalente. `Wait(ctx)` respeta la cancelación |
| Caffeine con `refreshAfterWrite` | `singleflight` + caché con TTL | Se compone a mano; `singleflight` cubre solo la deduplicación |
| `@Cacheable(sync=true)` | `singleflight.Group` | Mismo propósito: una sola llamada concurrente por clave |
| WireMock | `httptest.Server` con corpus grabado | **En la stdlib**, sin proceso aparte ni DSL. Menos potente para escenarios complejos |
| WireMock *record & playback* | `curl` a `testdata/` + `httptest.Server` | Manual, y por eso el corpus se revisa como código |
| `@RestClientTest` / `MockRestServiceServer` | `httptest.Server` | Idéntico en propósito |
| `@MockBean` | pasar otro doble al constructor | Sin contenedor que sustituir |
| Mockito `verify(mock, times(3))` | `mock.EXPECT().X().Times(3)` de `go.uber.org/mock` | Muy parecido. La diferencia es **cuándo** usarlo: aquí, solo para interacción rica |
| `@Order` / `InOrder` de Mockito | `gomock.InOrder(...)` | Equivalente |
| Jackson con `ObjectMapper` compartido | `encoding/json` | Sin configuración global ni módulos |
| `HttpMessageConverter` | decodificar a mano en el cliente | Sin negociación automática |
| `X-B3-TraceId` propagado por Sleuth | propagación manual, u OpenTelemetry (Fase 14) | Explícito |

### Qué sigue

La Fase 11 le da a AtlasSync su persistencia definitiva: **MongoDB y modelado
documental**. Y empieza con la pregunta que hay que responder antes de usarlo: por
qué AtlasSync usa Mongo y OpsReport no.

El contraejemplo está delante: un país de REST Countries trae nombres en nueve
idiomas, monedas anidadas, y campos que unos tienen y otros no. Normalizarlo a
diez tablas para volver a unirlo en cada lectura es trabajo sin destinatario.

Con el driver oficial, BSON, índices —incluidos los de texto y los TTL—, el
*framework* de agregación con el paralelo a `GROUP BY`, y el modelado que sí se
transfiere: incrustar frente a referenciar, el límite de dieciséis megas, y por qué
"esquemaless" no significa "sin esquema" sino **"esquema en el código"**.

Y el ⚖️ veredicto obligatorio: los tres casos en que Mongo es la respuesta
equivocada, y por qué el primero de ellos es *"porque el equipo ya lo tenía
levantado"*.

### La señal de que quedó bien

> *"Cuando un socio se cae, mis reintentos hacen que se recupere antes, no
> después. Y mi suite de tests pasa en el avión."*

Si tu política de reintentos no tiene clasificación, jitter y un sitio donde
pararse, lo que tienes no es resiliencia: es un multiplicador de caídas con buena
intención.

> 🏷️ **No cierres la fase sin el tag.** Con el checklist de la sección 2 en
> verde, `go test -race ./...` en verde **sin red**, `golangci-lint run` limpio y
> `git status` sin cambios pendientes:
>
> ```bash
> git tag -a fase-10 -m "F10 cerrada: cliente HTTP con plazos por fase y pool configurado; clasificación de errores como función pura; retroceso exponencial con full jitter y Retry-After; cortacircuitos y límite de tasa por endpoint; firma HMAC con timestamp; AtlasSync nace con REST Countries y Frankfurter; cinco niveles de prueba sin red; go.uber.org/mock en un solo sitio; storeagent sync reanudable"
> git tag -a eventrelay/v0.9 -m "EventRelay: entrega HTTP resiliente y firmada"
> git tag -a atlassync/v0.1 -m "AtlasSync: nace con ingesta de fuentes externas"
> git tag -a clearinghouse/v0.2 -m "ClearingHouse: storeagent sincroniza"
> ```
>
> Los commits de la fase llevan su prefijo (`fase 10: …`) y los de ejercicio su
> número (`fase 10 ej25: …`). Todo eso está en
> [`00-convencion-de-git-y-tags.md`](00-convencion-de-git-y-tags.md).

---

# 📌 Bloque de autoría (fuera de lo que lee el estudiante)

## 📌 Pendientes sugeridos

- **La verificación de la firma HMAC del lado receptor y `hmac.Equal`** — deuda 💸
  declarada en §6.4 para la **Fase 14**. Está en su alcance (*"firma HMAC con
  timestamp y su ataque de repetición, comparación en tiempo constante"*).
  Verificado.
- **SSRF en la validación de URL** — deuda 💸 arrastrada desde la **Fase 02**,
  prometida a la **Fase 14**. Está en su alcance. Verificado. **Es la deuda más
  antigua del curso viva: cuatro fases.** Comprobar que la Fase 14 la cita como
  tal.
- **`fakeconsumer` con `/flaky`** — se usa aquí para el caos del ejercicio 25.
  Verificar que la **Fase 15** lo reutiliza para B-23 y no monta otra cosa.
- **La caché con TTL y jitter de §6.5** — es un mapa en memoria, deuda 💸 hacia la
  **Fase 12**. Y es **material del ⚖️ veredicto de la Fase 12** (*"un mapa en
  memoria con TTL resuelve más casos de los que la gente cree"*): esta
  implementación es la evidencia de esa afirmación. **Anotar en la Fase 12 que
  debe compararse contra ella**, no contra el vacío.
- **HTTP/2 y el pool de conexiones** — ejercicio 🔥. El modelo cambia por completo y
  el curso no lo trata. Si algún socio de la ficción usara HTTP/2, habría que
  decirlo. Candidato a nota 📝 en la **Fase 14**.
- **La doble capa de reintento (aplicación + malla)** — mencionado en el ⚖️. Es un
  argumento fuerte para la **Fase 16** (cuándo NO migrar) y para el veredicto
  general de la Fase 17.
- **`httptrace`** — ejercicio 🔥 y herramienta del ejercicio 11. Su sitio natural
  para uso serio es la **Fase 15** (perfilado). Anotarlo allí.

## ☕ Reflejos para `INSTINTOS.md`

- **"`@Retryable` y ya reintenta"** — el reflejo raíz de la fase. Coste medido en
  la autopsia: una caída de 40 s convertida en una de 19 minutos, 40.000 peticiones
  en 8 segundos. Antídoto: **tres funciones separadas** —clasificar, esperar,
  parar— y las dos primeras puras.
- **"Un reintento siempre ayuda"** — reintentar un 4xx produce el mismo fallo N
  veces y puede activar un bloqueo del socio.
- **"El retroceso exponencial basta"** — sin *jitter*, todos los clientes reintentan
  en el mismo instante.
- **"`http.Get` es la forma de llamar a una API"** — sin timeout, sin contexto,
  con el cliente global.
- **"Un `http.Client` por llamada"** — tira el pool de conexiones en cada uso. Es
  crear un `DataSource` por consulta.
- **"Cerrar el cuerpo basta"** — sin drenar, el keep-alive no funciona.
- **"Los tests de integración prueban contra el sistema real"** — una suite que
  depende de internet enseña al equipo a reintentar el pipeline en vez de a mirar
  el fallo.

## 📐 Mediciones para `BENCHMARKS.md`

Esta fase produce **dos entradas propias, B-25 y B-29**, y alimenta una tercera:

- **B-25 — Amplificación del reintento.** El histograma del 🧨: peticiones por
  segundo tras un fallo, con retroceso fijo frente a exponencial con jitter, y el
  tiempo de recuperación del socio en los dos casos. **Es la medición más
  didáctica de la fase** y sostiene la parte no negociable de la política: el
  jitter. Asignada al cerrar el curso.
- **Sin ID — Efecto de `MaxIdleConnsPerHost`.** Conexiones nuevas y latencia con el
  valor por defecto (2) frente al ajustado, con 100 peticiones concurrentes al
  mismo host. Barato de medir y desmonta un valor por defecto sorprendente.
  **Propuesta: sección de B-23 (Fase 15)**, que ya mide entregas por segundo contra
  `fakeconsumer`.
- **B-29 — Fake frente a mock generado en tiempo de suite.**
  `prompts/formato-de-benchmarks.md` §1 la nombraba como candidata desde el
  principio y la Fase 04 la dejó anotada. Con `go.uber.org/mock` introducido aquí,
  este es su sitio. Asignada al cerrar el curso. Ojo con su veredicto: **el
  argumento real a favor del fake no es el tiempo**, y la entrada lo dice.
