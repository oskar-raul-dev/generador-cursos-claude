package domain

import "time"

// Event es un hecho del dominio con identidad propia desde que nace: la outbox y el consumidor
// deduplican por EventID, y nunca se regenera por intento.
type Event interface {
	EventID() string
	OrderID() string
	OccurredAt() time.Time
	Type() string
}

type OrderCancelled struct {
	ID         string
	Order      string
	Customer   string
	Occurred   time.Time
}

func (e OrderCancelled) EventID() string       { return e.ID }
func (e OrderCancelled) OrderID() string       { return e.Order }
func (e OrderCancelled) OccurredAt() time.Time { return e.Occurred }
func (e OrderCancelled) Type() string          { return "ORDER_CANCELLED" }
