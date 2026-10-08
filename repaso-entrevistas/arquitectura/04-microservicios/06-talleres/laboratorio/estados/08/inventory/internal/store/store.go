package store

import (
	"context"
	"crypto/rand"
	"errors"
	"fmt"

	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgxpool"
)

// Item es una línea de una retención: cuántas unidades de un SKU.
type Item struct {
	SKU string `json:"sku"`
	Qty int    `json:"qty"`
}

// Shortage explica por qué no se pudo retener un SKU.
type Shortage struct {
	SKU       string `json:"sku"`
	Requested int    `json:"requested"`
	OnHand    int    `json:"onHand"`
}

// OutOfStock se devuelve cuando alguna línea no cabe; no se retuvo nada.
type OutOfStock struct{ Shortages []Shortage }

func (e *OutOfStock) Error() string { return fmt.Sprintf("out of stock: %v", e.Shortages) }

type Store struct{ pool *pgxpool.Pool }

func New(pool *pgxpool.Pool) *Store { return &Store{pool: pool} }

// Stock devuelve las unidades disponibles de los SKU pedidos (los desconocidos no aparecen).
func (s *Store) Stock(ctx context.Context, skus []string) (map[string]int, error) {
	rows, err := s.pool.Query(ctx, `SELECT sku, on_hand FROM inventory WHERE sku = ANY($1)`, skus)
	if err != nil {
		return nil, err
	}
	out := map[string]int{}
	for rows.Next() {
		var sku string
		var n int
		if err := rows.Scan(&sku, &n); err != nil {
			return nil, err
		}
		out[sku] = n
	}
	return out, rows.Err()
}

// Hold retiene todas las líneas o ninguna, bajo la referencia del llamador (el id del pedido).
// Es idempotente por referencia: repetir la misma retención devuelve replay=true sin tocar nada.
func (s *Store) Hold(ctx context.Context, reference string, items []Item) (replay bool, err error) {
	err = pgx.BeginFunc(ctx, s.pool, func(tx pgx.Tx) error {
		var short []Shortage
		replay, short, err = HoldTx(ctx, tx, reference, items)
		if err == nil && len(short) > 0 {
			return &OutOfStock{Shortages: short}
		}
		return err
	})
	return replay, err
}

// HoldTx es la retención dentro de una transacción ajena: la usa Hold (gRPC) y la saga (taller 08),
// que necesita el inbox, la retención y el hecho en la MISMA transacción. Con faltantes no retiene nada.
func HoldTx(ctx context.Context, tx pgx.Tx, reference string, items []Item) (replay bool, short []Shortage, err error) {
	// Solo cuenta como "ya retenido" lo que sigue retenido o vendido. Una retención liberada no es una
	// reserva: si la misma referencia vuelve a pedir (el ciclo de 06/08 §8), se retiene de nuevo.
	var exists bool
	if err := tx.QueryRow(ctx, `SELECT EXISTS (SELECT 1 FROM holds WHERE reference = $1 AND status <> 'RELEASED')`, reference).Scan(&exists); err != nil {
		return false, nil, err
	}
	if exists {
		return true, nil, nil
	}
	want := map[string]int{}
	var skus []string
	for _, it := range items {
		if _, seen := want[it.SKU]; !seen {
			skus = append(skus, it.SKU)
		}
		want[it.SKU] += it.Qty
	}
	// las filas quedan bloqueadas hasta el commit: dos retenciones del mismo SKU no se pisan
	rows, err := tx.Query(ctx, `SELECT sku, on_hand FROM inventory WHERE sku = ANY($1) ORDER BY sku FOR UPDATE`, skus)
	if err != nil {
		return false, nil, err
	}
	onHand := map[string]int{}
	for rows.Next() {
		var sku string
		var n int
		if err := rows.Scan(&sku, &n); err != nil {
			return false, nil, err
		}
		onHand[sku] = n
	}
	if err := rows.Err(); err != nil {
		return false, nil, err
	}
	for _, sku := range skus {
		if onHand[sku] < want[sku] {
			short = append(short, Shortage{SKU: sku, Requested: want[sku], OnHand: onHand[sku]})
		}
	}
	if len(short) > 0 {
		return false, short, nil
	}
	for _, it := range items {
		if _, err := tx.Exec(ctx, `UPDATE inventory SET on_hand = on_hand - $2 WHERE sku = $1`, it.SKU, it.Qty); err != nil {
			return false, nil, err
		}
		if _, err := tx.Exec(ctx, `INSERT INTO holds (id, reference, sku, qty, status) VALUES ($1, $2, $3, $4, 'HELD')`,
			newUUID(), reference, it.SKU, it.Qty); err != nil {
			return false, nil, err
		}
	}
	return false, nil, nil
}

// Release devuelve al stock lo retenido bajo la referencia. Idempotente: la segunda vez libera 0.
func (s *Store) Release(ctx context.Context, reference string) (released int, err error) {
	err = pgx.BeginFunc(ctx, s.pool, func(tx pgx.Tx) error {
		back, err := ReleaseTx(ctx, tx, reference)
		released = len(back)
		return err
	})
	return released, err
}

// ReleaseTx libera dentro de una transacción ajena y devuelve lo liberado (taller 08).
func ReleaseTx(ctx context.Context, tx pgx.Tx, reference string) ([]Item, error) {
	rows, err := tx.Query(ctx, `UPDATE holds SET status = 'RELEASED' WHERE reference = $1 AND status = 'HELD' RETURNING sku, qty`, reference)
	if err != nil {
		return nil, err
	}
	back, err := pgx.CollectRows(rows, pgx.RowToStructByPos[Item])
	if err != nil {
		return nil, err
	}
	for _, it := range back {
		if _, err := tx.Exec(ctx, `UPDATE inventory SET on_hand = on_hand + $2 WHERE sku = $1`, it.SKU, it.Qty); err != nil {
			return nil, err
		}
	}
	return back, nil
}

// Commit marca lo retenido como vendido: ya no vuelve al stock. Idempotente.
func (s *Store) Commit(ctx context.Context, reference string) (int, error) {
	tag, err := s.pool.Exec(ctx, `UPDATE holds SET status = 'COMMITTED' WHERE reference = $1 AND status = 'HELD'`, reference)
	return int(tag.RowsAffected()), err
}

// CommitTx marca como vendido dentro de una transacción ajena (taller 08).
func CommitTx(ctx context.Context, tx pgx.Tx, reference string) (int, error) {
	tag, err := tx.Exec(ctx, `UPDATE holds SET status = 'COMMITTED' WHERE reference = $1 AND status = 'HELD'`, reference)
	return int(tag.RowsAffected()), err
}

// IsOutOfStock desenvuelve el error de negocio.
func IsOutOfStock(err error) (*OutOfStock, bool) {
	var oos *OutOfStock
	ok := errors.As(err, &oos)
	return oos, ok
}

func newUUID() string {
	var b [16]byte
	_, _ = rand.Read(b[:])
	b[6] = (b[6] & 0x0f) | 0x40 // versión 4
	b[8] = (b[8] & 0x3f) | 0x80 // variante RFC 4122
	return fmt.Sprintf("%x-%x-%x-%x-%x", b[0:4], b[4:6], b[6:8], b[8:10], b[10:16])
}

// ApplySale suma a `sales` las unidades de un pedido pagado (taller 06). Con inbox, la marca del evento
// y el efecto van en la MISMA transacción: si el evento ya se aplicó, no se suma otra vez. Sin inbox
// (la provocación), cada entrega suma: una re-entrega cuenta dos veces.
func (s *Store) ApplySale(ctx context.Context, consumer, eventID string, items []Item, inbox bool) (applied bool, err error) {
	err = pgx.BeginFunc(ctx, s.pool, func(tx pgx.Tx) error {
		if inbox {
			tag, err := tx.Exec(ctx, `INSERT INTO processed_messages (consumer, event_id) VALUES ($1, $2) ON CONFLICT DO NOTHING`, consumer, eventID)
			if err != nil {
				return err
			}
			if tag.RowsAffected() == 0 { // ya estaba: un duplicado, no un error
				return nil
			}
		}
		for _, it := range items {
			if _, err := tx.Exec(ctx, `INSERT INTO sales (sku, units) VALUES ($1, $2)
				ON CONFLICT (sku) DO UPDATE SET units = sales.units + EXCLUDED.units`, it.SKU, it.Qty); err != nil {
				return err
			}
		}
		applied = true
		return nil
	})
	return applied, err
}

// Sales devuelve las unidades vendidas por SKU.
func (s *Store) Sales(ctx context.Context) (map[string]int, error) {
	rows, err := s.pool.Query(ctx, `SELECT sku, units FROM sales ORDER BY sku`)
	if err != nil {
		return nil, err
	}
	out := map[string]int{}
	for rows.Next() {
		var sku string
		var n int
		if err := rows.Scan(&sku, &n); err != nil {
			return nil, err
		}
		out[sku] = n
	}
	return out, rows.Err()
}

// Event es un hecho de inventory que sale por su outbox (taller 08).
type Event struct {
	ID, OrderID, Topic, Type string
	Payload                  []byte
	TraceContext             string // el traceparent del mensaje que lo provocó: la traza sigue
}

// SagaStep ejecuta un paso de la saga: inbox, efecto y hechos en UNA transacción (taller 08). Si el
// evento ya se aplicó, step no se llama y applied es false. Es la regla de 06/06 aplicada a un
// participante que, además de consumir, publica.
func (s *Store) SagaStep(ctx context.Context, consumer, eventID string, step func(tx pgx.Tx) ([]Event, error)) (applied bool, err error) {
	err = pgx.BeginFunc(ctx, s.pool, func(tx pgx.Tx) error {
		tag, err := tx.Exec(ctx, `INSERT INTO processed_messages (consumer, event_id) VALUES ($1, $2) ON CONFLICT DO NOTHING`, consumer, eventID)
		if err != nil {
			return err
		}
		if tag.RowsAffected() == 0 {
			return nil
		}
		events, err := step(tx)
		if err != nil {
			return err
		}
		for _, ev := range events {
			if _, err := tx.Exec(ctx, `INSERT INTO outbox_events (id, aggregate_id, topic, type, payload, trace_context)
				VALUES ($1, $2, $3, $4, $5, NULLIF($6, ''))`, ev.ID, ev.OrderID, ev.Topic, ev.Type, string(ev.Payload), ev.TraceContext); err != nil {
				return err
			}
		}
		applied = true
		return nil
	})
	return applied, err
}

// NewEventID devuelve un UUID v4 para un hecho nuevo.
func NewEventID() string { return newUUID() }
