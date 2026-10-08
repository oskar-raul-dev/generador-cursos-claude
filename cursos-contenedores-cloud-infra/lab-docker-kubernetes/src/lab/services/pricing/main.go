// pricing: paso G4. Su propio almacén —Postgres si hay DATABASE_URL, SQLite en DATA_DIR si no— y el
// tope regulado opcional; nadie llama a nadie todavía. `pricing migrate` aplica el esquema y termina.
// Desde G4, la readiness comprueba lo único que pricing necesita para atender: su base. Desde G5, el
// apagado limpio: ante SIGTERM deja de aceptar conexiones, termina las que tiene y sale con 0. Desde
// G6, /metrics: el histograma común de los cuatro backends, más los contadores que trae el runtime. Desde
// G7, el log es JSON: una línea por evento a stdout, y la de cada petición con su request_id. Desde G8,
// un segundo listener con TLS mutuo en el 8443 (tls.go), para inventory. Desde G10, gRPC en el 9090 (grpc.go),
// con el mismo mTLS.
package main

import (
	"bufio"
	"context"
	"crypto/rand"
	"database/sql"
	"encoding/hex"
	"encoding/json"
	"errors"
	"log"
	"log/slog"
	"net"
	"net/http"
	"os"
	"os/signal"
	"regexp"
	"strconv"
	"strings"
	"syscall"
	"time"

	"github.com/prometheus/client_golang/prometheus"
	"github.com/prometheus/client_golang/prometheus/promauto"
	"github.com/prometheus/client_golang/prometheus/promhttp"
	"go.opentelemetry.io/contrib/instrumentation/net/http/otelhttp"
	"go.opentelemetry.io/otel/trace"
	"google.golang.org/grpc"
)

var (
	skuPattern   = regexp.MustCompile(`^SKU-[0-9]{4}$`)
	storePattern = regexp.MustCompile(`^DRO-[0-9]{3}$`)
)

// requestDuration es el histograma que el contrato fija para los cuatro backends (G6): mismo nombre,
// mismas etiquetas y mismos segundos, para que un solo tablero los lea. uri es el patrón de la ruta y
// nunca la ruta cruda: con /prices/SKU-0001 habría una serie por producto.
var requestDuration = promauto.NewHistogramVec(prometheus.HistogramOpts{
	Name:    "http_server_requests_seconds",
	Help:    "Duración de las peticiones HTTP atendidas, en segundos.",
	Buckets: []float64{0.005, 0.01, 0.025, 0.05, 0.1, 0.25, 0.5, 1, 2.5, 5, 10},
}, []string{"method", "uri", "status"})

// routeOf saca el patrón con el que el mux atendió la petición ("GET /prices/{sku}" → "/prices/{sku}").
// La ruta de "todo lo demás" se cuenta junta, como /** (el nombre que le da Spring en inventory).
// METRICS_URI=raw etiqueta con la ruta cruda: es el antipatrón, y existe solo para medirlo (Fase 17).
var rawURI = os.Getenv("METRICS_URI") == "raw"

func routeOf(r *http.Request) string {
	if rawURI {
		return r.URL.Path
	}
	pattern := r.Pattern
	if i := strings.IndexByte(pattern, ' '); i >= 0 {
		pattern = pattern[i+1:]
	}
	if pattern == "" || pattern == "/" {
		return "/**"
	}
	return pattern
}

// G7: el log del servicio. slog escribe JSON con time, level y msg; se agrega service. Con slog como
// logger por defecto, los log.Printf de siempre también salen como JSON, con nivel INFO.
func setupLogging() {
	handler := slog.NewJSONHandler(os.Stdout, nil)
	slog.SetDefault(slog.New(handler).With("service", "pricing"))
}

// requestID es el X-Request-Id que pone la puerta (o quien llame), o uno nuevo si no vino ninguno: cada
// línea de una petición lleva el mismo, y así se encuentra en los cuatro servicios (Fase 18).
func requestID(r *http.Request) string {
	if id := r.Header.Get("X-Request-Id"); id != "" {
		return id
	}
	b := make([]byte, 16)
	_, _ = rand.Read(b)
	return hex.EncodeToString(b)
}

// traceID es el de la traza en curso (G10), para que la línea de log se pueda buscar en Tempo y al revés.
func traceID(ctx context.Context) string {
	if sc := trace.SpanContextFromContext(ctx); sc.HasTraceID() {
		return sc.TraceID().String()
	}
	return ""
}

// statusRecorder guarda el código de estado para la línea de log.
type statusRecorder struct {
	http.ResponseWriter
	status int
}

func (r *statusRecorder) WriteHeader(code int) {
	r.status = code
	r.ResponseWriter.WriteHeader(code)
}

func writeJSON(w http.ResponseWriter, status int, body any) {
	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(status)
	_ = json.NewEncoder(w).Encode(body)
}

func writeError(w http.ResponseWriter, status int, code, message string) {
	writeJSON(w, status, map[string]string{"error": code, "message": message})
}

// price es la forma del contrato.
type price struct {
	Sku          string `json:"sku"`
	Store        string `json:"store"`
	Price        int    `json:"price"`
	Currency     string `json:"currency"`
	RegulatedCap *int   `json:"regulatedCap"`
	Capped       bool   `json:"capped"`
}

// server junta el almacén y la tabla de topes regulados.
type server struct {
	db   *sql.DB
	caps map[string]int // vacía si el tope está apagado
}

// loadCaps lee la tabla de topes regulados: una línea "SKU-0003,15000" por producto.
// Sin REGULATED_CAP_ENABLED=true, o sin el archivo, no hay topes. Desde la Fase 11 la tabla vive en un ConfigMap.
func loadCaps() map[string]int {
	caps := map[string]int{}
	if os.Getenv("REGULATED_CAP_ENABLED") != "true" {
		return caps
	}
	path := os.Getenv("REGULATED_CAP_FILE")
	if path == "" {
		path = "/etc/pricing/regulated-caps.csv"
	}
	file, err := os.Open(path)
	if err != nil {
		log.Printf("tope regulado encendido, pero sin tabla en %s: %v", path, err)
		return caps
	}
	defer file.Close()
	scanner := bufio.NewScanner(file)
	for scanner.Scan() {
		line := strings.TrimSpace(scanner.Text())
		if line == "" || strings.HasPrefix(line, "#") {
			continue
		}
		parts := strings.Split(line, ",")
		if len(parts) != 2 {
			continue
		}
		if value, err := strconv.Atoi(strings.TrimSpace(parts[1])); err == nil {
			caps[strings.TrimSpace(parts[0])] = value
		}
	}
	log.Printf("tope regulado encendido: %d productos con tope", len(caps))
	return caps
}

// view aplica el tope regulado al precio guardado: el precio guardado no cambia, el que se responde sí.
func (s *server) view(sku, store string, stored int) price {
	p := price{Sku: sku, Store: store, Price: stored, Currency: "COP"}
	if cap, ok := s.caps[sku]; ok {
		p.RegulatedCap = &cap
		if stored > cap {
			p.Price, p.Capped = cap, true
		}
	}
	return p
}

func (s *server) getPrice(w http.ResponseWriter, r *http.Request) {
	sku := r.PathValue("sku")
	store := r.URL.Query().Get("store")
	if store == "" {
		store = "DRO-001" // sin droguería, el contrato dice DRO-001
	}
	var stored int
	err := s.db.QueryRow(`SELECT price FROM prices WHERE sku = $1 AND store = $2`, sku, store).Scan(&stored)
	if errors.Is(err, sql.ErrNoRows) {
		writeError(w, http.StatusNotFound, "not_found", "sin precio para "+sku+" en "+store)
		return
	}
	if err != nil {
		writeError(w, http.StatusInternalServerError, "internal", err.Error())
		return
	}
	writeJSON(w, http.StatusOK, s.view(sku, store, stored))
}

func (s *server) listPrices(w http.ResponseWriter, r *http.Request) {
	store := r.URL.Query().Get("store")
	if !storePattern.MatchString(store) {
		writeError(w, http.StatusBadRequest, "bad_request", "store es obligatorio, con la forma DRO-000")
		return
	}
	rows, err := s.db.Query(`SELECT sku, price FROM prices WHERE store = $1 ORDER BY sku`, store)
	if err != nil {
		writeError(w, http.StatusInternalServerError, "internal", err.Error())
		return
	}
	defer rows.Close()
	prices := []price{}
	for rows.Next() {
		var sku string
		var stored int
		if err := rows.Scan(&sku, &stored); err != nil {
			writeError(w, http.StatusInternalServerError, "internal", err.Error())
			return
		}
		prices = append(prices, s.view(sku, store, stored))
	}
	writeJSON(w, http.StatusOK, prices)
}

func (s *server) putPrice(w http.ResponseWriter, r *http.Request) {
	sku := r.PathValue("sku")
	var body struct {
		Store string `json:"store"`
		Price *int   `json:"price"`
	}
	if !skuPattern.MatchString(sku) {
		writeError(w, http.StatusBadRequest, "bad_request", "sku con la forma SKU-0000")
		return
	}
	if err := json.NewDecoder(r.Body).Decode(&body); err != nil || !storePattern.MatchString(body.Store) ||
		body.Price == nil || *body.Price < 0 {
		writeError(w, http.StatusBadRequest, "bad_request", "se esperan store (DRO-000) y price entero no negativo")
		return
	}
	_, err := s.db.Exec(`INSERT INTO prices (sku, store, price) VALUES ($1, $2, $3)
		ON CONFLICT (sku, store) DO UPDATE SET price = excluded.price`, sku, body.Store, *body.Price)
	if err != nil {
		writeError(w, http.StatusInternalServerError, "internal", err.Error())
		return
	}
	writeJSON(w, http.StatusOK, s.view(sku, body.Store, *body.Price))
}

func main() {
	setupLogging()
	stopTracing := setupTracing() // G10
	defer stopTracing()
	port := os.Getenv("PORT")
	if port == "" {
		port = "8080" // el contrato fija 8080 por defecto
	}
	db, engine, err := openStore()
	if err != nil {
		log.Fatalf("no se pudo abrir el almacén: %v", err)
	}
	// `pricing migrate`: el Job de migraciones (G3). Aplica el esquema y termina, sin servir nada.
	if len(os.Args) > 1 && os.Args[1] == "migrate" {
		if err := migrate(db); err != nil {
			log.Fatalf("la migración falló: %v", err)
		}
		log.Printf("migraciones aplicadas en %s: %d", engine, len(migrations))
		return
	}
	// Con SQLite, el esquema se crea al arrancar, como en G1. Con Postgres, no: lo crea el Job, antes.
	if engine == "sqlite" {
		if err := migrate(db); err != nil {
			log.Fatalf("no se pudo crear el esquema: %v", err)
		}
	}
	log.Printf("almacén: %s", engine)
	s := &server{db: db, caps: loadCaps()}

	mux := http.NewServeMux()
	// La liveness nunca consulta dependencias.
	mux.HandleFunc("GET /health/live", func(w http.ResponseWriter, _ *http.Request) {
		writeJSON(w, http.StatusOK, map[string]string{"status": "live"})
	})
	// La readiness (G4): lista solo si la base contesta, en menos de un segundo. No pregunta por ningún
	// vecino: si pricing dependiera de que otro esté listo, una caída se volvería una cascada.
	mux.HandleFunc("GET /health/ready", func(w http.ResponseWriter, r *http.Request) {
		ctx, cancel := context.WithTimeout(r.Context(), time.Second)
		defer cancel()
		if err := s.db.PingContext(ctx); err != nil {
			slog.Warn("no listo: la base no contesta", "error", err.Error())
			writeJSON(w, http.StatusServiceUnavailable, map[string]string{"status": "not_ready"})
			return
		}
		writeJSON(w, http.StatusOK, map[string]string{"status": "ready"})
	})
	// G6: lo que Prometheus viene a buscar cada 15 s. El formato lo escribe la librería.
	mux.Handle("GET /metrics", promhttp.Handler())
	mux.HandleFunc("GET /prices", s.listPrices)
	mux.HandleFunc("GET /prices/{sku}", s.getPrice)
	mux.HandleFunc("PUT /prices/{sku}", s.putPrice)
	// Todo lo demás todavía no existe.
	mux.HandleFunc("/", func(w http.ResponseWriter, _ *http.Request) {
		writeJSON(w, http.StatusNotFound, map[string]string{"error": "not_found"})
	})

	handler := http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		rec := &statusRecorder{ResponseWriter: w, status: http.StatusOK}
		start := time.Now()
		mux.ServeHTTP(rec, r)
		// El mux deja en r.Pattern la ruta que atendió: por eso se lee después, no antes.
		requestDuration.WithLabelValues(r.Method, routeOf(r), strconv.Itoa(rec.status)).
			Observe(time.Since(start).Seconds())
		// G7: la línea de la petición, con los mismos campos en los cuatro servicios.
		slog.Info("request", "method", r.Method, "uri", routeOf(r), "path", r.URL.Path, "status", rec.status,
			"duration_ms", float64(time.Since(start).Microseconds())/1000, "request_id", requestID(r),
			"trace_id", traceID(r.Context()))
	})

	// G5: el servidor en su goroutine, y main esperando la señal. Sin esto, Go muere por la señal sin
	// cerrar nada (código 2 por SIGTERM, Fase 03), y las peticiones en vuelo se cortan.
	// G10: cada petición, un span; el nombre es la ruta del patrón, no la cruda (como la etiqueta de G6).
	traced := otelhttp.NewHandler(handler, "pricing", otelhttp.WithSpanNameFormatter(func(_ string, r *http.Request) string {
		return r.Method + " " + routeOf(r)
	}))
	srv := &http.Server{Addr: ":" + port, Handler: traced}
	go func() {
		if err := srv.ListenAndServe(); err != nil && !errors.Is(err, http.ErrServerClosed) {
			log.Fatalf("el servidor falló: %v", err)
		}
	}()
	log.Printf("pricing escuchando en :%s", port)

	// G8: el mismo manejador, detrás de TLS mutuo, si el pod trae los certificados.
	tlsSrv, err := mtlsServer(traced)
	if err != nil {
		log.Fatalf("no se pudo armar el mTLS: %v", err)
	}
	if tlsSrv != nil {
		go func() {
			if err := tlsSrv.ListenAndServeTLS("", ""); err != nil && !errors.Is(err, http.ErrServerClosed) {
				log.Fatalf("el servidor mTLS falló: %v", err)
			}
		}()
		log.Printf("pricing escuchando con mTLS en %s", tlsSrv.Addr)
	}

	// G10: el mismo precio por gRPC, con el mismo mTLS.
	var grpcSrv *grpc.Server
	if tlsSrv != nil {
		grpcSrv = grpcServer(s, tlsSrv.TLSConfig)
	}
	if grpcSrv != nil {
		lis, err := net.Listen("tcp", ":"+grpcPort())
		if err != nil {
			log.Fatalf("no se pudo abrir el puerto gRPC: %v", err)
		}
		go func() {
			if err := grpcSrv.Serve(lis); err != nil {
				log.Fatalf("el servidor gRPC falló: %v", err)
			}
		}()
		log.Printf("pricing escuchando gRPC con mTLS en :%s", grpcPort())
	}

	ctx, stop := signal.NotifyContext(context.Background(), syscall.SIGTERM, syscall.SIGINT)
	defer stop()
	<-ctx.Done()
	log.Printf("SIGTERM: no acepto conexiones nuevas y termino las que tengo")
	// Hasta 20 s para las que están en vuelo: menos que los 30 de terminationGracePeriodSeconds.
	shutdown, cancel := context.WithTimeout(context.Background(), 20*time.Second)
	defer cancel()
	if err := srv.Shutdown(shutdown); err != nil {
		log.Printf("apagado incompleto: %v", err)
	}
	if tlsSrv != nil {
		if err := tlsSrv.Shutdown(shutdown); err != nil {
			log.Printf("apagado incompleto del mTLS: %v", err)
		}
	}
	if grpcSrv != nil {
		grpcSrv.GracefulStop() // termina las llamadas en vuelo y cierra las conexiones HTTP/2
	}
	_ = db.Close()
	log.Printf("pricing apagado")
}
