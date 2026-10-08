package api

import (
	"encoding/json"
	"log"
	"net/http"
	"regexp"

	"ms.dev/inventory/internal/store"
)

// La API interna de inventory, con SU vocabulario: stock en mano (onHand) y retenciones (holds)
// bajo una referencia. No habla de "pedidos" ni de "reservas": eso es del monolito, y traducir
// entre los dos es trabajo de la capa anticorrupción del lado del monolito (06/02 §8).
type API struct{ store *store.Store }

func New(s *store.Store) http.Handler {
	a := &API{store: s}
	mux := http.NewServeMux()
	mux.HandleFunc("GET /health", func(w http.ResponseWriter, r *http.Request) { write(w, 200, map[string]string{"status": "UP"}) })
	mux.HandleFunc("GET /stock", a.stock)
	mux.HandleFunc("GET /sales", a.sales)
	mux.HandleFunc("POST /holds", a.hold)
	mux.HandleFunc("POST /holds/{reference}/release", a.release)
	mux.HandleFunc("POST /holds/{reference}/commit", a.commit)
	return mux
}

var uuidRe = regexp.MustCompile(`^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$`)

func (a *API) stock(w http.ResponseWriter, r *http.Request) {
	skus := r.URL.Query()["sku"]
	stock, err := a.store.Stock(r.Context(), skus)
	if err != nil {
		fail(w, r, err)
		return
	}
	type row struct {
		SKU    string `json:"sku"`
		OnHand int    `json:"onHand"`
	}
	items := []row{}
	for _, sku := range skus {
		if n, ok := stock[sku]; ok {
			items = append(items, row{sku, n})
		}
	}
	write(w, 200, map[string]any{"items": items})
}

func (a *API) sales(w http.ResponseWriter, r *http.Request) {
	sales, err := a.store.Sales(r.Context())
	if err != nil {
		fail(w, r, err)
		return
	}
	write(w, 200, map[string]any{"items": sales})
}

func (a *API) hold(w http.ResponseWriter, r *http.Request) {
	var req struct {
		Reference string       `json:"reference"`
		Items     []store.Item `json:"items"`
	}
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil || !uuidRe.MatchString(req.Reference) || len(req.Items) == 0 {
		problem(w, r, 400, "Bad request", "BAD_REQUEST", map[string]any{"detail": "reference (uuid) and items are required"})
		return
	}
	replay, err := a.store.Hold(r.Context(), req.Reference, req.Items)
	if oos, ok := store.IsOutOfStock(err); ok {
		problem(w, r, 409, "Out of stock", "OUT_OF_STOCK", map[string]any{"shortages": oos.Shortages})
		return
	}
	if err != nil {
		fail(w, r, err)
		return
	}
	status := 201
	if replay {
		status = 200
	}
	write(w, status, map[string]any{"reference": req.Reference, "items": req.Items})
}

func (a *API) release(w http.ResponseWriter, r *http.Request) {
	n, err := a.store.Release(r.Context(), r.PathValue("reference"))
	if err != nil {
		fail(w, r, err)
		return
	}
	write(w, 200, map[string]int{"released": n})
}

func (a *API) commit(w http.ResponseWriter, r *http.Request) {
	n, err := a.store.Commit(r.Context(), r.PathValue("reference"))
	if err != nil {
		fail(w, r, err)
		return
	}
	write(w, 200, map[string]int{"committed": n})
}

func write(w http.ResponseWriter, status int, body any) {
	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(status)
	_ = json.NewEncoder(w).Encode(body)
}

func problem(w http.ResponseWriter, r *http.Request, status int, title, code string, extra map[string]any) {
	body := map[string]any{"type": "about:blank", "title": title, "status": status, "code": code, "instance": r.URL.Path}
	for k, v := range extra {
		body[k] = v
	}
	w.Header().Set("Content-Type", "application/problem+json")
	w.WriteHeader(status)
	_ = json.NewEncoder(w).Encode(body)
}

func fail(w http.ResponseWriter, r *http.Request, err error) {
	log.Printf("%s %s: %v", r.Method, r.URL.Path, err)
	problem(w, r, 500, "Internal error", "INTERNAL_ERROR", nil)
}
