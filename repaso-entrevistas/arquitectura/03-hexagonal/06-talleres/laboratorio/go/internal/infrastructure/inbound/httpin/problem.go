// Package httpin es el adaptador HTTP de entrada: router de net/http, middleware de
// autenticación, DTO y la traducción de errores a problem+json.
package httpin

import (
	"encoding/json"
	"errors"
	"log/slog"
	"net/http"

	"hexorders/internal/application"
	"hexorders/internal/domain"
)

type fieldError struct {
	Field   string `json:"field"`
	Message string `json:"message"`
}

type problem struct {
	Type     string       `json:"type"`
	Title    string       `json:"title"`
	Status   int          `json:"status"`
	Detail   string       `json:"detail,omitempty"`
	Instance string       `json:"instance"`
	Code     string       `json:"code"`
	Errors   []fieldError `json:"errors,omitempty"`
}

// Errores propios del borde (forma de la petición), separados de los del núcleo.
type validationFailed struct{ errs []fieldError }

func (e validationFailed) Error() string { return "validation failed" }

var errMissingIdempotencyKey = errors.New("Idempotency-Key header is required")

type unauthenticated struct{ code string } // UNAUTHENTICATED | TOKEN_REVOKED

func (e unauthenticated) Error() string { return e.code }

func writeProblem(w http.ResponseWriter, r *http.Request, p problem) {
	p.Type = "about:blank"
	p.Instance = r.URL.Path
	w.Header().Set("Content-Type", "application/problem+json")
	if p.Status == http.StatusUnauthorized {
		w.Header().Set("WWW-Authenticate", "Bearer")
	}
	w.WriteHeader(p.Status)
	_ = json.NewEncoder(w).Encode(p)
}

// handleError es el traductor central: cada error propio se convierte UNA vez en problem+json
// con el código estable del contrato. errors.As hace el trabajo que en Java hacía @ExceptionHandler.
func handleError(w http.ResponseWriter, r *http.Request, err error) {
	var (
		insufficient   domain.InsufficientInventory
		notPayable     domain.OrderNotPayable
		notCancellable domain.OrderNotCancellable
		notFound       application.NotFound
		exists         application.ProductAlreadyExists
		invalid        validationFailed
		unauth         unauthenticated
	)
	switch {
	case errors.As(err, &insufficient):
		writeProblem(w, r, problem{Status: 409, Title: "Insufficient inventory", Code: "INSUFFICIENT_INVENTORY", Detail: err.Error(),
			Errors: []fieldError{{Field: "lines[" + itoa(insufficient.LineIndex) + "].quantity",
				Message: "requested " + itoa(insufficient.Requested) + ", available " + itoa(insufficient.Available)}}})
	case errors.As(err, &notPayable):
		writeProblem(w, r, problem{Status: 409, Title: "Order not payable", Code: "ORDER_NOT_PAYABLE", Detail: err.Error()})
	case errors.As(err, &notCancellable):
		writeProblem(w, r, problem{Status: 409, Title: "Order not cancellable", Code: "ORDER_NOT_CANCELLABLE", Detail: err.Error()})
	case errors.Is(err, domain.ErrEmptyOrder):
		writeProblem(w, r, problem{Status: 400, Title: "Validation failed", Code: "VALIDATION_FAILED", Detail: err.Error(),
			Errors: []fieldError{{Field: "lines", Message: "must not be empty"}}})
	case errors.As(err, &notFound):
		if notFound.Kind == "PRODUCT" {
			writeProblem(w, r, problem{Status: 404, Title: "Product not found", Code: "PRODUCT_NOT_FOUND", Detail: notFound.ID})
		} else {
			writeProblem(w, r, problem{Status: 404, Title: "Order not found", Code: "ORDER_NOT_FOUND"})
		}
	case errors.Is(err, application.ErrAccessDenied):
		writeProblem(w, r, problem{Status: 403, Title: "Forbidden", Code: "FORBIDDEN"})
	case errors.Is(err, application.ErrInvalidCredentials):
		writeProblem(w, r, problem{Status: 401, Title: "Invalid credentials", Code: "INVALID_CREDENTIALS"})
	case errors.Is(err, application.ErrIdempotencyKeyReused):
		writeProblem(w, r, problem{Status: 422, Title: "Idempotency-Key reused with a different payload", Code: "IDEMPOTENCY_KEY_REUSED"})
	case errors.As(err, &exists):
		writeProblem(w, r, problem{Status: 409, Title: "Product already exists", Code: "PRODUCT_ALREADY_EXISTS", Detail: err.Error()})
	case errors.As(err, &invalid):
		writeProblem(w, r, problem{Status: 400, Title: "Validation failed", Code: "VALIDATION_FAILED", Errors: invalid.errs})
	case errors.Is(err, errMissingIdempotencyKey):
		writeProblem(w, r, problem{Status: 400, Title: "Idempotency-Key required", Code: "IDEMPOTENCY_KEY_REQUIRED"})
	case errors.As(err, &unauth):
		title := "Unauthenticated"
		if unauth.code == "TOKEN_REVOKED" {
			title = "Token revoked"
		}
		writeProblem(w, r, problem{Status: 401, Title: title, Code: unauth.code})
	default:
		// fallo técnico: la causa va al registro, nunca al cliente
		slog.Error("unexpected error", "method", r.Method, "path", r.URL.Path, "err", err)
		writeProblem(w, r, problem{Status: 500, Title: "Internal error", Code: "INTERNAL_ERROR"})
	}
}

func itoa(n int) string {
	b, _ := json.Marshal(n)
	return string(b)
}
