package domain

import (
	"errors"
	"time"
)

type OrderStatus string

const (
	StatusConfirmed       OrderStatus = "CONFIRMED"
	StatusPaid            OrderStatus = "PAID"
	StatusPaymentRejected OrderStatus = "PAYMENT_REJECTED"
	StatusPaymentPending  OrderStatus = "PAYMENT_PENDING"
	StatusCancelled       OrderStatus = "CANCELLED"
)

type PaymentStatus string

const (
	PaymentAuthorized PaymentStatus = "AUTHORIZED"
	PaymentRejected   PaymentStatus = "REJECTED"
	PaymentPending    PaymentStatus = "PENDING"
)

// Payment es el resultado de un intento de autorización. OperationID es la Idempotency-Key del
// intento. Reference vacía significa "el proveedor no dio referencia".
type Payment struct {
	Status      PaymentStatus
	OperationID string
	Reference   string
}

// OrderLine es la foto del catálogo en el momento de la venta.
type OrderLine struct {
	SKU       string
	Name      string
	Quantity  int
	UnitPrice Money
}

func (l OrderLine) LineTotal() Money { return l.UnitPrice.Times(l.Quantity) }

// Order es el agregado. Protege que haya líneas y que las transiciones sean las del contrato.
// Los campos son privados: el estado solo cambia por los métodos que aplican la regla.
type Order struct {
	id         string
	customerID string
	lines      []OrderLine
	total      Money
	createdAt  time.Time
	status     OrderStatus
	payment    *Payment
	version    int64
	events     []Event
}

// PlaceOrder crea un pedido: nace CONFIRMED (reservado, sin pagar).
func PlaceOrder(id, customerID string, lines []OrderLine, now time.Time) (*Order, error) {
	if len(lines) == 0 {
		return nil, ErrEmptyOrder
	}
	total := lines[0].LineTotal()
	for _, l := range lines[1:] {
		t, err := total.Plus(l.LineTotal())
		if err != nil {
			return nil, err
		}
		total = t
	}
	return &Order{id: id, customerID: customerID, lines: append([]OrderLine(nil), lines...), total: total,
		createdAt: now, status: StatusConfirmed}, nil
}

// Reconstitute vuelve de persistencia sin revalidar reglas de creación.
func Reconstitute(id, customerID string, lines []OrderLine, total Money, createdAt time.Time,
	status OrderStatus, payment *Payment, version int64) *Order {
	return &Order{id: id, customerID: customerID, lines: lines, total: total, createdAt: createdAt,
		status: status, payment: payment, version: version}
}

func (o *Order) ID() string           { return o.id }
func (o *Order) CustomerID() string   { return o.customerID }
func (o *Order) Lines() []OrderLine   { return o.lines }
func (o *Order) Total() Money         { return o.total }
func (o *Order) CreatedAt() time.Time { return o.createdAt }
func (o *Order) Status() OrderStatus  { return o.status }
func (o *Order) Payment() *Payment    { return o.payment }
func (o *Order) Version() int64       { return o.version }

func (o *Order) IsPayable() bool {
	return o.status == StatusConfirmed || o.status == StatusPaymentRejected
}

func (o *Order) IsCancellable() bool {
	return o.status == StatusConfirmed || o.status == StatusPaymentRejected || o.status == StatusPaymentPending
}

// ApplyPayment aplica el resultado del proveedor. PENDING no es un rechazo: el pedido queda a la
// espera y no vuelve a ser pagable.
func (o *Order) ApplyPayment(result Payment) error {
	if !o.IsPayable() {
		return OrderNotPayable{Status: o.status}
	}
	p := result
	o.payment = &p
	switch result.Status {
	case PaymentAuthorized:
		o.status = StatusPaid
	case PaymentRejected:
		o.status = StatusPaymentRejected
	case PaymentPending:
		o.status = StatusPaymentPending
	default:
		return errors.New("unknown payment status " + string(result.Status))
	}
	return nil
}

// Cancel es idempotente: la segunda vez no cambia nada ni emite el hecho. Devuelve true si hubo
// transición (y por tanto hay reserva que liberar y evento que publicar).
func (o *Order) Cancel(now time.Time, eventID string) (bool, error) {
	if o.status == StatusCancelled {
		return false, nil
	}
	if !o.IsCancellable() {
		return false, OrderNotCancellable{Status: o.status}
	}
	o.status = StatusCancelled
	o.events = append(o.events, OrderCancelled{ID: eventID, Order: o.id, Customer: o.customerID, Occurred: now})
	return true, nil
}

// PullEvents entrega los hechos recogidos y vacía la lista.
func (o *Order) PullEvents() []Event {
	pulled := o.events
	o.events = nil
	return pulled
}
