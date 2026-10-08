package httpin

import (
	"encoding/json"
	"net/http"
	"strconv"

	"hexorders/internal/application"
)

// Deps son los casos de uso y lo que el borde necesita para autenticar. Es lo único que el router
// conoce; nada de pgx, Mongo ni Redis.
type Deps struct {
	Login             application.Login
	Logout            application.Logout
	ListProducts      application.ListProducts
	GetProduct        application.GetProduct
	CreateProduct     application.CreateProduct
	CreateOrder       application.CreateOrder
	GetOrder          application.GetOrder
	ListOrders        application.ListOrders
	AuthorizePayment  application.AuthorizePayment
	CancelOrder       application.CancelOrder
	ListNotifications application.ListNotifications
	Verifier          TokenVerifier
	Revocations       application.TokenRevocationStore
	CORSOrigin        string
}

// NewHandler monta el router de net/http (patrones con método, Go 1.22+) y los middleware.
func NewHandler(d Deps) http.Handler {
	mux := http.NewServeMux()
	h := handlers{d}
	mux.HandleFunc("GET /health", h.health)
	mux.HandleFunc("POST /api/v1/auth/login", h.login)
	mux.HandleFunc("POST /api/v1/auth/logout", h.logout)
	mux.HandleFunc("GET /api/v1/products", h.listProducts)
	mux.HandleFunc("GET /api/v1/products/{sku}", h.getProduct)
	mux.HandleFunc("POST /api/v1/products", h.createProduct)
	mux.HandleFunc("GET /api/v1/orders", h.listOrders)
	mux.HandleFunc("POST /api/v1/orders", h.createOrder)
	mux.HandleFunc("GET /api/v1/orders/{orderId}", h.getOrder)
	mux.HandleFunc("POST /api/v1/orders/{orderId}/payment", h.pay)
	mux.HandleFunc("POST /api/v1/orders/{orderId}/cancel", h.cancel)
	mux.HandleFunc("GET /api/v1/notifications", h.listNotifications)
	return cors(d.CORSOrigin, authenticate(d.Verifier, d.Revocations, mux))
}

func writeJSON(w http.ResponseWriter, status int, body any) {
	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(status)
	_ = json.NewEncoder(w).Encode(body)
}

func pageRequest(r *http.Request) application.PageRequest {
	limit, _ := strconv.Atoi(r.URL.Query().Get("limit"))
	return application.NewPageRequest(r.URL.Query().Get("cursor"), limit)
}
