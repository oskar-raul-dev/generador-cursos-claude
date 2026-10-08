package store

import (
	"context"

	"github.com/jackc/pgx/v5/pgxpool"
)

// El esquema de inventory, aplicado al arrancar. El servicio es dueño de sus tablas y las migra
// él mismo: es lo correcto cuando la base es suya, y exactamente lo que rompe al monolito cuando
// la base es compartida (06/02 §7). La segunda sentencia renombra `available` a `on_hand` si
// encuentra el esquema viejo: para inventory es su lenguaje; para quien lea esa columna, un corte.
const schema = `
CREATE TABLE IF NOT EXISTS inventory (
    sku     text PRIMARY KEY,
    on_hand integer NOT NULL CHECK (on_hand >= 0)
);
DO $$ BEGIN
    IF EXISTS (SELECT 1 FROM information_schema.columns
                WHERE table_schema = current_schema() AND table_name = 'inventory' AND column_name = 'available') THEN
        ALTER TABLE inventory RENAME COLUMN available TO on_hand;
    END IF;
END $$;
CREATE TABLE IF NOT EXISTS holds (
    id         uuid PRIMARY KEY,
    reference  uuid NOT NULL,
    sku        text NOT NULL,
    qty        integer NOT NULL CHECK (qty > 0),
    status     text NOT NULL CHECK (status IN ('HELD', 'RELEASED', 'COMMITTED')),
    created_at timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS holds_reference_idx ON holds (reference);
`

func Migrate(ctx context.Context, pool *pgxpool.Pool) error {
	_, err := pool.Exec(ctx, schema)
	return err
}
