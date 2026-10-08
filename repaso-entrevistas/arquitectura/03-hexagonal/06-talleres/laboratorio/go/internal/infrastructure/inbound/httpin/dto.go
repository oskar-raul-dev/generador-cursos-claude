package httpin

import (
	"encoding/json"
	"io"
	"net/http"
	"regexp"
	"strings"
	"time"

	"hexorders/internal/application"
	"hexorders/internal/domain"
)

// Los DTO del contrato HTTP y su validación de forma, a mano: en Go no hay anotaciones y la
// validación es código que se lee. El núcleo recibe comandos con tipos propios.

var (
	emailPattern  = regexp.MustCompile(`^[^@\s]+@[^@\s]+\.[^@\s]+$`)
	skuPattern    = regexp.MustCompile(`^SKU-[0-9]{3,}$`)
	amountPattern = regexp.MustCompile(`^-?[0-9]+\.[0-9]{2}$`)
	ccyPattern    = regexp.MustCompile(`^[A-Z]{3}$`)
	uuidPattern   = regexp.MustCompile(`^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$`)
)

func decode(r *http.Request, into any) error {
	body, err := io.ReadAll(http.MaxBytesReader(nil, r.Body, 1<<20)) // 1 MiB: límite de tamaño del borde
	if err != nil {
		return validationFailed{[]fieldError{{Field: "body", Message: "unreadable body"}}}
	}
	if err := json.Unmarshal(body, into); err != nil {
		return validationFailed{[]fieldError{{Field: "body", Message: "malformed request"}}}
	}
	return nil
}

func requireUUID(field, value string) (string, error) {
	if !uuidPattern.MatchString(strings.ToLower(value)) {
		return "", validationFailed{[]fieldError{{Field: field, Message: "must be a UUID"}}}
	}
	return strings.ToLower(value), nil
}

// ---------------------------------------------------------------- entrada

type loginRequest struct {
	Email    string `json:"email"`
	Password string `json:"password"`
}

func (b loginRequest) validate() error {
	var errs []fieldError
	if !emailPattern.MatchString(b.Email) {
		errs = append(errs, fieldError{"email", "must be an email"})
	}
	if len(b.Password) < 8 {
		errs = append(errs, fieldError{"password", "must be at least 8 characters"})
	}
	if errs != nil {
		return validationFailed{errs}
	}
	return nil
}

type moneyDTO struct {
	Amount   string `json:"amount"`
	Currency string `json:"currency"`
}

func (m moneyDTO) validate(prefix string) []fieldError {
	var errs []fieldError
	if !amountPattern.MatchString(m.Amount) {
		errs = append(errs, fieldError{prefix + ".amount", "must be a decimal with two digits"})
	}
	if !ccyPattern.MatchString(m.Currency) {
		errs = append(errs, fieldError{prefix + ".currency", "must be a 3-letter code"})
	}
	return errs
}

type createProductRequest struct {
	SKU       string   `json:"sku"`
	Name      string   `json:"name"`
	UnitPrice moneyDTO `json:"unitPrice"`
	Stock     *int     `json:"stock"`
}

func (b createProductRequest) validate() error {
	var errs []fieldError
	if !skuPattern.MatchString(b.SKU) {
		errs = append(errs, fieldError{"sku", "must match SKU-nnn"})
	}
	if strings.TrimSpace(b.Name) == "" || len(b.Name) > 120 {
		errs = append(errs, fieldError{"name", "must be 1 to 120 characters"})
	}
	errs = append(errs, b.UnitPrice.validate("unitPrice")...)
	if b.Stock == nil || *b.Stock < 0 {
		errs = append(errs, fieldError{"stock", "must be a non-negative integer"})
	}
	if errs != nil {
		return validationFailed{errs}
	}
	return nil
}

type lineRequest struct {
	SKU      string `json:"sku"`
	Quantity *int   `json:"quantity"`
}

type createOrderRequest struct {
	Lines []lineRequest `json:"lines"`
}

func (b createOrderRequest) validate() error {
	var errs []fieldError
	if len(b.Lines) == 0 {
		errs = append(errs, fieldError{"lines", "must not be empty"})
	}
	if len(b.Lines) > 50 {
		errs = append(errs, fieldError{"lines", "at most 50 lines"})
	}
	for i, l := range b.Lines {
		if !skuPattern.MatchString(l.SKU) {
			errs = append(errs, fieldError{"lines[" + itoa(i) + "].sku", "must match SKU-nnn"})
		}
		if l.Quantity == nil || *l.Quantity < 1 || *l.Quantity > 1000 {
			errs = append(errs, fieldError{"lines[" + itoa(i) + "].quantity", "must be between 1 and 1000"})
		}
	}
	if errs != nil {
		return validationFailed{errs}
	}
	return nil
}

// canonical es la huella del cuerpo para la idempotencia: mismo contenido, misma huella.
func (b createOrderRequest) canonical() string {
	parts := make([]string, 0, len(b.Lines))
	for _, l := range b.Lines {
		parts = append(parts, l.SKU+":"+itoa(*l.Quantity))
	}
	return strings.Join(parts, ",")
}

// ---------------------------------------------------------------- salida

type moneyResponse struct {
	Amount   string `json:"amount"`
	Currency string `json:"currency"`
}

func money(m domain.Money) moneyResponse { return moneyResponse{Amount: m.Text(), Currency: m.Currency} }

type productResponse struct {
	SKU       string        `json:"sku"`
	Name      string        `json:"name"`
	UnitPrice moneyResponse `json:"unitPrice"`
	Stock     int           `json:"stock"`
}

func toProductResponse(p application.ProductWithStock) productResponse {
	return productResponse{SKU: p.Product.SKU, Name: p.Product.Name, UnitPrice: money(p.Product.UnitPrice), Stock: p.Stock}
}

type lineResponse struct {
	SKU       string        `json:"sku"`
	Name      string        `json:"name"`
	Quantity  int           `json:"quantity"`
	UnitPrice moneyResponse `json:"unitPrice"`
	LineTotal moneyResponse `json:"lineTotal"`
}

type paymentResponse struct {
	Status      string  `json:"status"`
	OperationID string  `json:"operationId"`
	Reference   *string `json:"reference"`
}

func toPayment(p *domain.Payment) *paymentResponse {
	if p == nil {
		return nil
	}
	var ref *string
	if p.Reference != "" {
		r := p.Reference
		ref = &r
	}
	return &paymentResponse{Status: string(p.Status), OperationID: p.OperationID, Reference: ref}
}

type orderResponse struct {
	ID         string           `json:"id"`
	CustomerID string           `json:"customerId"`
	Status     string           `json:"status"`
	Lines      []lineResponse   `json:"lines"`
	Total      moneyResponse    `json:"total"`
	Payment    *paymentResponse `json:"payment"`
	CreatedAt  string           `json:"createdAt"`
}

func toOrderResponse(o *domain.Order) orderResponse {
	lines := make([]lineResponse, 0, len(o.Lines()))
	for _, l := range o.Lines() {
		lines = append(lines, lineResponse{SKU: l.SKU, Name: l.Name, Quantity: l.Quantity, UnitPrice: money(l.UnitPrice), LineTotal: money(l.LineTotal())})
	}
	return orderResponse{ID: o.ID(), CustomerID: o.CustomerID(), Status: string(o.Status()), Lines: lines,
		Total: money(o.Total()), Payment: toPayment(o.Payment()), CreatedAt: o.CreatedAt().UTC().Format(time.RFC3339)}
}

type paymentResultResponse struct {
	OrderID     string           `json:"orderId"`
	OrderStatus string           `json:"orderStatus"`
	Payment     *paymentResponse `json:"payment"`
}

type notificationResponse struct {
	ID        string `json:"id"`
	OrderID   string `json:"orderId"`
	Type      string `json:"type"`
	Recipient string `json:"recipient"`
	CreatedAt string `json:"createdAt"`
}

func toNotificationResponse(n application.Notification) notificationResponse {
	return notificationResponse{ID: n.ID, OrderID: n.OrderID, Type: n.Type, Recipient: n.Recipient, CreatedAt: n.CreatedAt.UTC().Format(time.RFC3339)}
}

type pageResponse[T any] struct {
	Items      []T     `json:"items"`
	NextCursor *string `json:"nextCursor"`
}

func toPageResponse[T any](p application.Page[T]) pageResponse[T] {
	if p.Items == nil {
		p.Items = []T{}
	}
	return pageResponse[T]{Items: p.Items, NextCursor: p.NextCursor}
}
