-- Esquema de ms_inventory: el del servicio inventory (Go). El servicio lo aplica también al
-- arrancar (inventory/internal/store/migrate.go); `lab.py seed` lo recrea para partir de cero.
DROP TABLE IF EXISTS holds, inventory CASCADE;

CREATE TABLE inventory (
    sku     text PRIMARY KEY,                      -- sin FK al catálogo: el catálogo es de otro servicio
    on_hand integer NOT NULL CHECK (on_hand >= 0)
);

CREATE TABLE holds (                               -- retenciones bajo una referencia (el id del pedido)
    id         uuid PRIMARY KEY,
    reference  uuid NOT NULL,
    sku        text NOT NULL,
    qty        integer NOT NULL CHECK (qty > 0),
    status     text NOT NULL CHECK (status IN ('HELD', 'RELEASED', 'COMMITTED')),
    created_at timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX holds_reference_idx ON holds (reference);
