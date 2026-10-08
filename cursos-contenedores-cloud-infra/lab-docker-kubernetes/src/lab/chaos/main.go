// chaos: el generador de caos del laboratorio (Fase 22). Se pone entre un servicio y su vecino, como un
// proxy inverso, y le hace al tráfico lo que se le pida: latencia, errores, respuestas malformadas o
// silencio. Solo biblioteca estándar, a propósito: se lee de una sentada.
//
//	CHAOS_UPSTREAM=http://catalog:8080   a quién le pasa el tráfico
//	PUT /chaos {"latencyMs":5000,"latencyPercent":100,"errorPercent":0,"malformedPercent":0,"hangPercent":0}
//	GET /chaos                            la configuración y lo que lleva contado
//
// Todo lo que no sea /chaos ni /health/* va al vecino, con lo que diga la configuración en ese momento.
package main

import (
	"context"
	"encoding/json"
	"errors"
	"log/slog"
	"math/rand/v2"
	"net/http"
	"net/http/httputil"
	"net/url"
	"os"
	"os/signal"
	"sync"
	"sync/atomic"
	"syscall"
	"time"
)

// faults es lo que se inyecta. Cada porcentaje se sortea por petición, en este orden: colgarse, fallar,
// demorar, romper la respuesta. Una petición puede llevarse la demora y además la respuesta rota.
type faults struct {
	LatencyMs        int `json:"latencyMs"`
	LatencyPercent   int `json:"latencyPercent"`
	ErrorPercent     int `json:"errorPercent"`
	MalformedPercent int `json:"malformedPercent"`
	HangPercent      int `json:"hangPercent"`
}

// counters es lo que lleva contado desde que arrancó: cuánto pasó y cuánto se le hizo a lo que pasó.
type counters struct {
	Received  atomic.Int64
	Forwarded atomic.Int64
	Delayed   atomic.Int64
	Errored   atomic.Int64
	Malformed atomic.Int64
	Hung      atomic.Int64
}

type chaos struct {
	mu     sync.RWMutex
	f      faults
	c      counters
	proxy  *httputil.ReverseProxy
	target string
}

func (ch *chaos) current() faults {
	ch.mu.RLock()
	defer ch.mu.RUnlock()
	return ch.f
}

// roll dice que sí con la probabilidad pedida.
func roll(percent int) bool { return percent > 0 && rand.IntN(100) < percent }

func (ch *chaos) admin(w http.ResponseWriter, r *http.Request) {
	if r.Method == http.MethodPut {
		var f faults
		if err := json.NewDecoder(r.Body).Decode(&f); err != nil {
			http.Error(w, `{"error":"bad_request"}`, http.StatusBadRequest)
			return
		}
		ch.mu.Lock()
		ch.f = f
		ch.mu.Unlock()
		slog.Info("caos nuevo", "faults", f)
	}
	w.Header().Set("Content-Type", "application/json")
	_ = json.NewEncoder(w).Encode(map[string]any{
		"target": ch.target,
		"faults": ch.current(),
		"counts": map[string]int64{
			"received": ch.c.Received.Load(), "forwarded": ch.c.Forwarded.Load(), "delayed": ch.c.Delayed.Load(),
			"errored": ch.c.Errored.Load(), "malformed": ch.c.Malformed.Load(), "hung": ch.c.Hung.Load(),
		},
	})
}

func (ch *chaos) serve(w http.ResponseWriter, r *http.Request) {
	ch.c.Received.Add(1)
	f := ch.current()
	// Colgarse: no contestar nunca. Solo se suelta cuando el cliente se cansa (o se apaga el proxy).
	if roll(f.HangPercent) {
		ch.c.Hung.Add(1)
		<-r.Context().Done()
		return
	}
	// Fallar: un 503 sin pasarle nada al vecino, como un vecino sobrecargado.
	if roll(f.ErrorPercent) {
		ch.c.Errored.Add(1)
		w.Header().Set("Content-Type", "application/json")
		w.WriteHeader(http.StatusServiceUnavailable)
		_, _ = w.Write([]byte(`{"error":"unavailable","message":"caos: error inyectado"}`))
		return
	}
	// Demorar: esperar y después pasar la petición. Si el cliente se cansa antes, se corta ahí.
	if roll(f.LatencyPercent) && f.LatencyMs > 0 {
		ch.c.Delayed.Add(1)
		select {
		case <-time.After(time.Duration(f.LatencyMs) * time.Millisecond):
		case <-r.Context().Done():
			return
		}
	}
	// Romper la respuesta: un 200 con JSON cortado a la mitad, que el cliente tiene que saber rechazar.
	if roll(f.MalformedPercent) {
		ch.c.Malformed.Add(1)
		w.Header().Set("Content-Type", "application/json")
		_, _ = w.Write([]byte(`{"sku":"SKU-00`))
		return
	}
	ch.c.Forwarded.Add(1)
	ch.proxy.ServeHTTP(w, r)
}

func main() {
	slog.SetDefault(slog.New(slog.NewJSONHandler(os.Stdout, nil)).With("service", "chaos"))
	upstream := os.Getenv("CHAOS_UPSTREAM")
	target, err := url.Parse(upstream)
	if err != nil || target.Host == "" {
		slog.Error("CHAOS_UPSTREAM no es una dirección", "value", upstream)
		os.Exit(1)
	}
	ch := &chaos{target: upstream, proxy: httputil.NewSingleHostReverseProxy(target)}
	// La configuración inicial, si viene: CHAOS_FAULTS con el mismo JSON del PUT.
	if raw := os.Getenv("CHAOS_FAULTS"); raw != "" {
		if err := json.Unmarshal([]byte(raw), &ch.f); err != nil {
			slog.Error("CHAOS_FAULTS no es JSON válido", "error", err.Error())
			os.Exit(1)
		}
	}

	mux := http.NewServeMux()
	mux.HandleFunc("GET /health/live", func(w http.ResponseWriter, _ *http.Request) { _, _ = w.Write([]byte(`{"status":"live"}`)) })
	mux.HandleFunc("GET /health/ready", func(w http.ResponseWriter, _ *http.Request) { _, _ = w.Write([]byte(`{"status":"ready"}`)) })
	mux.HandleFunc("/chaos", ch.admin)
	mux.HandleFunc("/", ch.serve)

	port := os.Getenv("PORT")
	if port == "" {
		port = "8080"
	}
	srv := &http.Server{Addr: ":" + port, Handler: mux}
	go func() {
		if err := srv.ListenAndServe(); err != nil && !errors.Is(err, http.ErrServerClosed) {
			slog.Error("el servidor falló", "error", err.Error())
			os.Exit(1)
		}
	}()
	slog.Info("caos escuchando", "port", port, "upstream", upstream, "faults", ch.current())
	ctx, stop := signal.NotifyContext(context.Background(), syscall.SIGTERM, syscall.SIGINT)
	defer stop()
	<-ctx.Done()
	shutdown, cancel := context.WithTimeout(context.Background(), 5*time.Second)
	defer cancel()
	_ = srv.Shutdown(shutdown)
}
