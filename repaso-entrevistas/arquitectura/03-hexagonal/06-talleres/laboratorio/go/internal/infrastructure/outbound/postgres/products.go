package postgres

import (
	"context"
	"errors"

	"github.com/jackc/pgx/v5"

	"hexorders/internal/application"
	"hexorders/internal/domain"
)

// Products es el catálogo en PostgreSQL (partes 1 y 2). main elige entre este y el de Mongo.
// Los importes se leen y escriben como texto (unit_price::text, $n::numeric): ningún float64.
type Products struct{ DB *DB }

func (p Products) Find(ctx context.Context, sku string) (*domain.Product, error) {
	var name, amount, currency string
	err := p.DB.Q(ctx).QueryRow(ctx, "SELECT name, unit_price::text, currency FROM products WHERE sku = $1", sku).
		Scan(&name, &amount, &currency)
	if errors.Is(err, pgx.ErrNoRows) {
		return nil, nil
	}
	if err != nil {
		return nil, err
	}
	price, err := domain.ParseMoney(amount, currency)
	if err != nil {
		return nil, err
	}
	return &domain.Product{SKU: sku, Name: name, UnitPrice: price}, nil
}

func (p Products) Exists(ctx context.Context, sku string) (bool, error) {
	var n int
	err := p.DB.Q(ctx).QueryRow(ctx, "SELECT count(*) FROM products WHERE sku = $1", sku).Scan(&n)
	return n > 0, err
}

func (p Products) List(ctx context.Context, page application.PageRequest) (application.Page[domain.Product], error) {
	after := decodeCursor(page.Cursor)
	// una fila más que el límite para saber si hay página siguiente sin contar
	rows, err := p.DB.Q(ctx).Query(ctx,
		"SELECT sku, name, unit_price::text, currency FROM products WHERE sku > $1 ORDER BY sku LIMIT $2",
		after, page.Limit+1)
	if err != nil {
		return application.Page[domain.Product]{}, err
	}
	defer rows.Close()
	var items []domain.Product
	for rows.Next() {
		var sku, name, amount, currency string
		if err := rows.Scan(&sku, &name, &amount, &currency); err != nil {
			return application.Page[domain.Product]{}, err
		}
		price, err := domain.ParseMoney(amount, currency)
		if err != nil {
			return application.Page[domain.Product]{}, err
		}
		items = append(items, domain.Product{SKU: sku, Name: name, UnitPrice: price})
	}
	var next *string
	if len(items) > page.Limit {
		items = items[:page.Limit]
		next = encodeCursor(items[len(items)-1].SKU)
	}
	return application.Page[domain.Product]{Items: items, NextCursor: next}, rows.Err()
}

func (p Products) Save(ctx context.Context, product domain.Product) error {
	_, err := p.DB.Q(ctx).Exec(ctx, `
		INSERT INTO products (sku, name, unit_price, currency) VALUES ($1, $2, $3::numeric, $4)
		ON CONFLICT (sku) DO UPDATE SET name = EXCLUDED.name, unit_price = EXCLUDED.unit_price,
		    currency = EXCLUDED.currency, updated_at = now()`,
		product.SKU, product.Name, product.UnitPrice.Text(), product.UnitPrice.Currency)
	return err
}
