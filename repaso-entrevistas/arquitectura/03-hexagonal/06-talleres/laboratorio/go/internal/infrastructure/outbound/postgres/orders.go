package postgres

import (
	"context"
	"errors"
	"time"

	"github.com/jackc/pgx/v5"

	"hexorders/internal/application"
	"hexorders/internal/domain"
)

// Orders traduce entre domain.Order y las filas de orders/order_lines/payments. Al leer,
// reconstruye un agregado completo: líneas y último pago.
type Orders struct{ DB *DB }

func (o Orders) Find(ctx context.Context, id string) (*domain.Order, error) {
	q := o.DB.Q(ctx)
	var customerID, status, total, currency string
	var version int64
	var createdAt time.Time
	err := q.QueryRow(ctx,
		"SELECT customer_id::text, status, total_amount::text, currency, version, created_at FROM orders WHERE id = $1::uuid", id).
		Scan(&customerID, &status, &total, &currency, &version, &createdAt)
	if errors.Is(err, pgx.ErrNoRows) {
		return nil, nil
	}
	if err != nil {
		return nil, err
	}
	return o.reconstitute(ctx, id, customerID, status, total, currency, version, createdAt)
}

func (o Orders) reconstitute(ctx context.Context, id, customerID, status, total, currency string, version int64, createdAt time.Time) (*domain.Order, error) {
	q := o.DB.Q(ctx)
	rows, err := q.Query(ctx, "SELECT sku, product_name, quantity, unit_price::text FROM order_lines WHERE order_id = $1::uuid ORDER BY line_no", id)
	if err != nil {
		return nil, err
	}
	var lines []domain.OrderLine
	for rows.Next() {
		var sku, name, amount string
		var quantity int
		if err := rows.Scan(&sku, &name, &quantity, &amount); err != nil {
			rows.Close()
			return nil, err
		}
		price, err := domain.ParseMoney(amount, currency)
		if err != nil {
			rows.Close()
			return nil, err
		}
		lines = append(lines, domain.OrderLine{SKU: sku, Name: name, Quantity: quantity, UnitPrice: price})
	}
	rows.Close()

	var payment *domain.Payment
	var pStatus, pOperation, pReference string
	err = q.QueryRow(ctx, "SELECT status, operation_id, coalesce(reference, '') FROM payments WHERE order_id = $1::uuid ORDER BY created_at DESC LIMIT 1", id).
		Scan(&pStatus, &pOperation, &pReference)
	if err == nil {
		payment = &domain.Payment{Status: domain.PaymentStatus(pStatus), OperationID: pOperation, Reference: pReference}
	} else if !errors.Is(err, pgx.ErrNoRows) {
		return nil, err
	}
	totalMoney, err := domain.ParseMoney(total, currency)
	if err != nil {
		return nil, err
	}
	return domain.Reconstitute(id, customerID, lines, totalMoney, createdAt, domain.OrderStatus(status), payment, version), nil
}

func (o Orders) Save(ctx context.Context, order *domain.Order) error {
	q := o.DB.Q(ctx)
	tag, err := q.Exec(ctx, "UPDATE orders SET status = $2, version = $3, updated_at = now() WHERE id = $1::uuid",
		order.ID(), string(order.Status()), order.Version()+1)
	if err != nil {
		return err
	}
	if tag.RowsAffected() > 0 {
		return nil
	}
	if _, err := q.Exec(ctx,
		"INSERT INTO orders (id, customer_id, status, total_amount, currency, version, created_at) VALUES ($1::uuid, $2::uuid, $3, $4::numeric, $5, 0, $6)",
		order.ID(), order.CustomerID(), string(order.Status()), order.Total().Text(), order.Total().Currency, order.CreatedAt()); err != nil {
		return err
	}
	for i, l := range order.Lines() {
		if _, err := q.Exec(ctx,
			"INSERT INTO order_lines (order_id, line_no, sku, product_name, quantity, unit_price) VALUES ($1::uuid, $2, $3, $4, $5, $6::numeric)",
			order.ID(), i, l.SKU, l.Name, l.Quantity, l.UnitPrice.Text()); err != nil {
			return err
		}
	}
	return nil
}

func (o Orders) List(ctx context.Context, customerID string, page application.PageRequest) (application.Page[*domain.Order], error) {
	// cursor sobre (created_at, id) descendente: estable aunque se creen pedidos entre páginas
	sql := "SELECT id::text, customer_id::text, status, total_amount::text, currency, version, created_at FROM orders WHERE true"
	args := []any{}
	if customerID != "" {
		args = append(args, customerID)
		sql += " AND customer_id = $" + itoa(len(args)) + "::uuid"
	}
	if ts, id, ok := decodeTimeCursor(page.Cursor); ok {
		args = append(args, ts, id)
		sql += " AND (created_at, id) < ($" + itoa(len(args)-1) + ", $" + itoa(len(args)) + "::uuid)"
	}
	args = append(args, page.Limit+1)
	sql += " ORDER BY created_at DESC, id DESC LIMIT $" + itoa(len(args))

	rows, err := o.DB.Q(ctx).Query(ctx, sql, args...)
	if err != nil {
		return application.Page[*domain.Order]{}, err
	}
	type row struct {
		id, customerID, status, total, currency string
		version                                 int64
		createdAt                               time.Time
	}
	var found []row
	for rows.Next() {
		var r row
		if err := rows.Scan(&r.id, &r.customerID, &r.status, &r.total, &r.currency, &r.version, &r.createdAt); err != nil {
			rows.Close()
			return application.Page[*domain.Order]{}, err
		}
		found = append(found, r)
	}
	rows.Close()

	var next *string
	if len(found) > page.Limit {
		found = found[:page.Limit]
		last := found[len(found)-1]
		next = encodeTimeCursor(last.createdAt, last.id)
	}
	items := make([]*domain.Order, 0, len(found))
	for _, r := range found {
		order, err := o.reconstitute(ctx, r.id, r.customerID, r.status, r.total, r.currency, r.version, r.createdAt)
		if err != nil {
			return application.Page[*domain.Order]{}, err
		}
		items = append(items, order)
	}
	return application.Page[*domain.Order]{Items: items, NextCursor: next}, nil
}

func itoa(n int) string {
	if n == 0 {
		return "0"
	}
	var b []byte
	for n > 0 {
		b = append([]byte{byte('0' + n%10)}, b...)
		n /= 10
	}
	return string(b)
}
