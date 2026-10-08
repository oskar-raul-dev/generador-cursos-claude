package postgres

import (
	"context"
	"encoding/json"
	"time"

	"hexorders/internal/domain"
)

// PendingPublications es la outbox en PostgreSQL. Add corre dentro de la transacción del caso de
// uso; NextBatch y MarkPublished desde la ronda del dispatcher.
type PendingPublications struct{ DB *DB }

type outboxPayload struct {
	OrderID    string `json:"orderId"`
	CustomerID string `json:"customerId"`
}

func (p PendingPublications) Add(ctx context.Context, e domain.Event) error {
	customer := ""
	if c, ok := e.(domain.OrderCancelled); ok {
		customer = c.Customer
	}
	payload, _ := json.Marshal(outboxPayload{OrderID: e.OrderID(), CustomerID: customer})
	_, err := p.DB.Q(ctx).Exec(ctx,
		"INSERT INTO outbox (id, aggregate_type, aggregate_id, event_type, payload, occurred_at) VALUES ($1::uuid, 'Order', $2::uuid, $3, $4::jsonb, $5)",
		e.EventID(), e.OrderID(), e.Type(), string(payload), e.OccurredAt())
	return err
}

func (p PendingPublications) NextBatch(ctx context.Context, size int) ([]domain.Event, error) {
	q := p.DB.Q(ctx)
	rows, err := q.Query(ctx,
		"SELECT id::text, aggregate_id::text, payload::text, occurred_at FROM outbox WHERE published_at IS NULL ORDER BY occurred_at LIMIT $1", size)
	if err != nil {
		return nil, err
	}
	var events []domain.Event
	var ids []string
	for rows.Next() {
		var id, orderID, payload string
		var occurred time.Time
		if err := rows.Scan(&id, &orderID, &payload, &occurred); err != nil {
			rows.Close()
			return nil, err
		}
		var body outboxPayload
		if err := json.Unmarshal([]byte(payload), &body); err != nil {
			rows.Close()
			return nil, err
		}
		events = append(events, domain.OrderCancelled{ID: id, Order: orderID, Customer: body.CustomerID, Occurred: occurred})
		ids = append(ids, id)
	}
	rows.Close()
	if len(ids) > 0 {
		if _, err := q.Exec(ctx, "UPDATE outbox SET attempts = attempts + 1 WHERE id = ANY($1::uuid[])", ids); err != nil {
			return nil, err
		}
	}
	return events, nil
}

func (p PendingPublications) MarkPublished(ctx context.Context, eventID string) error {
	_, err := p.DB.Q(ctx).Exec(ctx, "UPDATE outbox SET published_at = now() WHERE id = $1::uuid", eventID)
	return err
}
