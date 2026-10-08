package postgres

import (
	"context"

	"hexorders/internal/domain"
)

// Inventory: existencias y reservas. Reserve descuenta línea a línea con un UPDATE condicional
// (WHERE available >= $2); al primer 0 devuelve InsufficientInventory y la transacción del caso
// de uso revierte lo ya descontado. La atomicidad no está aquí: está en DB.Run.
type Inventory struct{ DB *DB }

func (i Inventory) AvailableFor(ctx context.Context, skus []string) (map[string]int, error) {
	out := map[string]int{}
	if len(skus) == 0 {
		return out, nil
	}
	rows, err := i.DB.Q(ctx).Query(ctx, "SELECT sku, available FROM inventory WHERE sku = ANY($1)", skus)
	if err != nil {
		return nil, err
	}
	defer rows.Close()
	for rows.Next() {
		var sku string
		var available int
		if err := rows.Scan(&sku, &available); err != nil {
			return nil, err
		}
		out[sku] = available
	}
	return out, rows.Err()
}

func (i Inventory) Initialize(ctx context.Context, sku string, quantity int) error {
	_, err := i.DB.Q(ctx).Exec(ctx, "INSERT INTO inventory (sku, available) VALUES ($1, $2)", sku, quantity)
	return err
}

func (i Inventory) Reserve(ctx context.Context, orderID string, lines []domain.OrderLine) error {
	q := i.DB.Q(ctx)
	for idx, l := range lines {
		tag, err := q.Exec(ctx,
			"UPDATE inventory SET available = available - $2, version = version + 1, updated_at = now() WHERE sku = $1 AND available >= $2",
			l.SKU, l.Quantity)
		if err != nil {
			return err
		}
		if tag.RowsAffected() == 0 {
			var available int
			_ = q.QueryRow(ctx, "SELECT available FROM inventory WHERE sku = $1", l.SKU).Scan(&available)
			return domain.InsufficientInventory{SKU: l.SKU, Requested: l.Quantity, Available: available, LineIndex: idx}
		}
		if _, err := q.Exec(ctx,
			"INSERT INTO inventory_reservations (id, order_id, sku, quantity, status) VALUES (gen_random_uuid(), $1::uuid, $2, $3, 'RESERVED')",
			orderID, l.SKU, l.Quantity); err != nil {
			return err
		}
	}
	return nil
}

func (i Inventory) Release(ctx context.Context, orderID string) error {
	q := i.DB.Q(ctx)
	rows, err := q.Query(ctx, "SELECT id::text, sku, quantity FROM inventory_reservations WHERE order_id = $1::uuid AND status = 'RESERVED'", orderID)
	if err != nil {
		return err
	}
	type reservation struct {
		id, sku  string
		quantity int
	}
	var reservations []reservation
	for rows.Next() {
		var r reservation
		if err := rows.Scan(&r.id, &r.sku, &r.quantity); err != nil {
			rows.Close()
			return err
		}
		reservations = append(reservations, r)
	}
	rows.Close()
	for _, r := range reservations {
		if _, err := q.Exec(ctx, "UPDATE inventory SET available = available + $2, version = version + 1, updated_at = now() WHERE sku = $1", r.sku, r.quantity); err != nil {
			return err
		}
		if _, err := q.Exec(ctx, "UPDATE inventory_reservations SET status = 'RELEASED', updated_at = now() WHERE id = $1::uuid", r.id); err != nil {
			return err
		}
	}
	return nil
}
