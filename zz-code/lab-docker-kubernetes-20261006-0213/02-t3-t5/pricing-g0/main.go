// pricing: paso G0. Salud trivial y un precio fijo; nada de datos ni de vecinos todavía.
package main

import (
	"encoding/json"
	"log"
	"net/http"
	"os"
)

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

func main() {
	port := os.Getenv("PORT")
	if port == "" {
		port = "8080" // el contrato fija 8080 por defecto
	}

	mux := http.NewServeMux()
	// La liveness nunca consulta dependencias.
	mux.HandleFunc("GET /health/live", func(w http.ResponseWriter, _ *http.Request) {
		writeJSON(w, http.StatusOK, map[string]string{"status": "live"})
	})
	// En G0 la readiness es trivial; se vuelve real en G4.
	mux.HandleFunc("GET /health/ready", func(w http.ResponseWriter, _ *http.Request) {
		writeJSON(w, http.StatusOK, map[string]string{"status": "ready"})
	})
	// El precio fijo de G0: la forma del contrato, sin datos detrás.
	mux.HandleFunc("GET /prices/{sku}", func(w http.ResponseWriter, r *http.Request) {
		store := r.URL.Query().Get("store")
		if store == "" {
			store = "DRO-001" // sin droguería, el contrato dice DRO-001
		}
		writeJSON(w, http.StatusOK, map[string]any{
			"sku": r.PathValue("sku"), "store": store, "price": 12900, "currency": "COP",
		})
	})
	// Todo lo demás todavía no existe.
	mux.HandleFunc("/", func(w http.ResponseWriter, _ *http.Request) {
		writeJSON(w, http.StatusNotFound, map[string]string{"error": "not_found"})
	})

	handler := http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		rec := &statusRecorder{ResponseWriter: w, status: http.StatusOK}
		mux.ServeHTTP(rec, r)
		log.Printf("%s %s %d", r.Method, r.URL.Path, rec.status) // texto libre hasta la Fase 18
	})

	log.Printf("pricing escuchando en :%s", port)
	log.Fatal(http.ListenAndServe(":"+port, handler))
}
