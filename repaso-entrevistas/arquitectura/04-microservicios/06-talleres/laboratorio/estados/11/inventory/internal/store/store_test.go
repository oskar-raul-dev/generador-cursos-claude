package store

import (
	"context"
	"testing"

	"github.com/jackc/pgx/v5/pgxpool"
	"github.com/testcontainers/testcontainers-go"
	"github.com/testcontainers/testcontainers-go/modules/postgres"
)

// Prueba de componente del inbox (taller 10), contra PostgreSQL de verdad en un contenedor efímero: la
// deduplicación depende de una clave primaria y de una transacción, justo lo que una base en memoria
// o un doble no reproducen. Es la prueba de idempotencia de 04/07 §7, en Go.
func TestApplySaleCountsEachEventOnce(t *testing.T) {
	ctx := context.Background()
	st := newStore(t, ctx)
	items := []Item{{SKU: "SKU-002", Qty: 2}}
	const eventID = "8c1f4a52-2d0e-4c55-9d3a-6a0f3f0b9e11"

	first, err := st.ApplySale(ctx, "inventory", eventID, items, true)
	if err != nil || !first {
		t.Fatalf("first delivery: applied=%v err=%v", first, err)
	}
	second, err := st.ApplySale(ctx, "inventory", eventID, items, true) // la re-entrega
	if err != nil || second {
		t.Fatalf("redelivery: applied=%v err=%v (want false)", second, err)
	}
	if got := sales(t, ctx, st)["SKU-002"]; got != 2 {
		t.Fatalf("SKU-002 = %d, want 2", got)
	}
}

// Y la provocación de 06/06 como prueba: sin inbox, la re-entrega cuenta dos veces.
func TestApplySaleWithoutInboxCountsTwice(t *testing.T) {
	ctx := context.Background()
	st := newStore(t, ctx)
	items := []Item{{SKU: "SKU-002", Qty: 2}}
	for range 2 {
		if _, err := st.ApplySale(ctx, "inventory", "8c1f4a52-2d0e-4c55-9d3a-6a0f3f0b9e11", items, false); err != nil {
			t.Fatal(err)
		}
	}
	if got := sales(t, ctx, st)["SKU-002"]; got != 4 {
		t.Fatalf("SKU-002 = %d, want 4 (the duplicate counted)", got)
	}
}

// newStore arranca un PostgreSQL con la MISMA imagen que el laboratorio, aplica el esquema del servicio
// y lo tira al terminar la prueba.
func newStore(t *testing.T, ctx context.Context) *Store {
	t.Helper()
	pg, err := postgres.Run(ctx, "postgres:17.11-alpine",
		postgres.WithDatabase("ms_inventory"), postgres.WithUsername("ms_inventory"), postgres.WithPassword("test"),
		postgres.BasicWaitStrategies())
	testcontainers.CleanupContainer(t, pg)
	if err != nil {
		t.Fatal(err)
	}
	dsn, err := pg.ConnectionString(ctx, "sslmode=disable")
	if err != nil {
		t.Fatal(err)
	}
	pool, err := pgxpool.New(ctx, dsn)
	if err != nil {
		t.Fatal(err)
	}
	t.Cleanup(pool.Close)
	if err := Migrate(ctx, pool); err != nil {
		t.Fatal(err)
	}
	return New(pool)
}

func sales(t *testing.T, ctx context.Context, st *Store) map[string]int {
	t.Helper()
	got, err := st.Sales(ctx)
	if err != nil {
		t.Fatal(err)
	}
	return got
}
