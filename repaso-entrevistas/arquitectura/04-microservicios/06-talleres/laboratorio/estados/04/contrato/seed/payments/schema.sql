-- Esquema de ms_payments: el del servicio payments (Python), extraído en el taller 03.
DROP TABLE IF EXISTS payments CASCADE;

CREATE TABLE payments (
    id           uuid PRIMARY KEY,
    order_id     uuid NOT NULL,                        -- referencia al pedido de otro servicio: sin FK
    operation_id text NOT NULL UNIQUE,                 -- la Idempotency-Key: dos peticiones con la misma, un solo cobro
    amount       numeric(12, 2) NOT NULL CHECK (amount > 0),
    status       text NOT NULL CHECK (status IN ('IN_PROGRESS', 'AUTHORIZED', 'REJECTED', 'PENDING')),
    reference    text,                                 -- la del proveedor, si respondió
    created_at   timestamptz NOT NULL DEFAULT now()
);
