package postgres

import (
	"context"

	"hexorders/internal/domain"
)

type Payments struct{ DB *DB }

func (p Payments) Record(ctx context.Context, orderID string, payment domain.Payment, amount domain.Money) error {
	var reference *string
	if payment.Reference != "" {
		r := payment.Reference
		reference = &r
	}
	_, err := p.DB.Q(ctx).Exec(ctx,
		"INSERT INTO payments (id, order_id, operation_id, status, reference, amount, currency) VALUES (gen_random_uuid(), $1::uuid, $2, $3, $4, $5::numeric, $6)",
		orderID, payment.OperationID, string(payment.Status), reference, amount.Text(), amount.Currency)
	return err
}
