package httpin

import (
	"net/http"

	"hexorders/internal/application"
	"hexorders/internal/domain"
)

// Los handlers traducen HTTP a intenciones y resultados a DTO, y aplican las decisiones del
// contrato (201 + Location al crear, 200 + Idempotent-Replay al repetir). Ninguna regla de negocio.
type handlers struct{ d Deps }

func (h handlers) health(w http.ResponseWriter, _ *http.Request) {
	writeJSON(w, http.StatusOK, map[string]string{"status": "UP"})
}

func (h handlers) login(w http.ResponseWriter, r *http.Request) {
	var body loginRequest
	if err := decode(r, &body); err != nil {
		handleError(w, r, err)
		return
	}
	if err := body.validate(); err != nil {
		handleError(w, r, err)
		return
	}
	token, err := h.d.Login.Execute(r.Context(), body.Email, body.Password)
	if err != nil {
		handleError(w, r, err)
		return
	}
	writeJSON(w, http.StatusOK, map[string]any{"accessToken": token.Value, "tokenType": "Bearer", "expiresIn": token.ExpiresInSeconds})
}

func (h handlers) logout(w http.ResponseWriter, r *http.Request) {
	claims := tokenFrom(r.Context())
	if err := h.d.Logout.Execute(r.Context(), claims.TokenID, claims.ExpiresAt); err != nil {
		handleError(w, r, err)
		return
	}
	w.WriteHeader(http.StatusNoContent)
}

func (h handlers) listProducts(w http.ResponseWriter, r *http.Request) {
	page, err := h.d.ListProducts.Execute(r.Context(), pageRequest(r))
	if err != nil {
		handleError(w, r, err)
		return
	}
	writeJSON(w, http.StatusOK, toPageResponse(application.MapPage(page, toProductResponse)))
}

func (h handlers) getProduct(w http.ResponseWriter, r *http.Request) {
	p, err := h.d.GetProduct.Execute(r.Context(), r.PathValue("sku"))
	if err != nil {
		handleError(w, r, err)
		return
	}
	writeJSON(w, http.StatusOK, toProductResponse(p))
}

func (h handlers) createProduct(w http.ResponseWriter, r *http.Request) {
	var body createProductRequest
	if err := decode(r, &body); err != nil {
		handleError(w, r, err)
		return
	}
	if err := body.validate(); err != nil {
		handleError(w, r, err)
		return
	}
	price, err := domain.ParseMoney(body.UnitPrice.Amount, body.UnitPrice.Currency)
	if err != nil {
		handleError(w, r, validationFailed{[]fieldError{{Field: "unitPrice.amount", Message: "must be a decimal with two digits"}}})
		return
	}
	created, err := h.d.CreateProduct.Execute(r.Context(), actorFrom(r.Context()), body.SKU, body.Name, price, *body.Stock)
	if err != nil {
		handleError(w, r, err)
		return
	}
	w.Header().Set("Location", "/api/v1/products/"+created.Product.SKU)
	writeJSON(w, http.StatusCreated, toProductResponse(created))
}

func (h handlers) createOrder(w http.ResponseWriter, r *http.Request) {
	key, err := requireIdempotencyKey(r)
	if err != nil {
		handleError(w, r, err)
		return
	}
	var body createOrderRequest
	if err := decode(r, &body); err != nil {
		handleError(w, r, err)
		return
	}
	if err := body.validate(); err != nil {
		handleError(w, r, err)
		return
	}
	lines := make([]application.LineRequest, 0, len(body.Lines))
	for _, l := range body.Lines {
		lines = append(lines, application.LineRequest{SKU: l.SKU, Quantity: *l.Quantity})
	}
	result, err := h.d.CreateOrder.Execute(r.Context(), application.CreateOrderCommand{
		Actor: actorFrom(r.Context()), IdempotencyKey: key, RequestHash: requestHash(body.canonical()), Lines: lines,
	})
	if err != nil {
		handleError(w, r, err)
		return
	}
	if result.Replayed {
		w.Header().Set("Idempotent-Replay", "true")
		writeJSON(w, http.StatusOK, toOrderResponse(result.Order))
		return
	}
	w.Header().Set("Location", "/api/v1/orders/"+result.Order.ID())
	writeJSON(w, http.StatusCreated, toOrderResponse(result.Order))
}

func (h handlers) getOrder(w http.ResponseWriter, r *http.Request) {
	id, err := requireUUID("orderId", r.PathValue("orderId"))
	if err != nil {
		handleError(w, r, err)
		return
	}
	o, err := h.d.GetOrder.Execute(r.Context(), actorFrom(r.Context()), id)
	if err != nil {
		handleError(w, r, err)
		return
	}
	writeJSON(w, http.StatusOK, toOrderResponse(o))
}

func (h handlers) listOrders(w http.ResponseWriter, r *http.Request) {
	page, err := h.d.ListOrders.Execute(r.Context(), actorFrom(r.Context()), pageRequest(r))
	if err != nil {
		handleError(w, r, err)
		return
	}
	writeJSON(w, http.StatusOK, toPageResponse(application.MapPage(page, toOrderResponse)))
}

func (h handlers) pay(w http.ResponseWriter, r *http.Request) {
	id, err := requireUUID("orderId", r.PathValue("orderId"))
	if err != nil {
		handleError(w, r, err)
		return
	}
	key, err := requireIdempotencyKey(r)
	if err != nil {
		handleError(w, r, err)
		return
	}
	result, err := h.d.AuthorizePayment.Execute(r.Context(), actorFrom(r.Context()), id, key)
	if err != nil {
		handleError(w, r, err)
		return
	}
	if result.Replayed {
		w.Header().Set("Idempotent-Replay", "true")
	}
	p := result.Payment
	writeJSON(w, http.StatusOK, paymentResultResponse{OrderID: result.Order.ID(), OrderStatus: string(result.Order.Status()), Payment: toPayment(&p)})
}

func (h handlers) cancel(w http.ResponseWriter, r *http.Request) {
	id, err := requireUUID("orderId", r.PathValue("orderId"))
	if err != nil {
		handleError(w, r, err)
		return
	}
	o, err := h.d.CancelOrder.Execute(r.Context(), actorFrom(r.Context()), id)
	if err != nil {
		handleError(w, r, err)
		return
	}
	writeJSON(w, http.StatusOK, toOrderResponse(o))
}

func (h handlers) listNotifications(w http.ResponseWriter, r *http.Request) {
	orderID := r.URL.Query().Get("orderId")
	if orderID != "" {
		id, err := requireUUID("orderId", orderID)
		if err != nil {
			handleError(w, r, err)
			return
		}
		orderID = id
	}
	page, err := h.d.ListNotifications.Execute(r.Context(), actorFrom(r.Context()), orderID, pageRequest(r))
	if err != nil {
		handleError(w, r, err)
		return
	}
	writeJSON(w, http.StatusOK, toPageResponse(application.MapPage(page, toNotificationResponse)))
}
