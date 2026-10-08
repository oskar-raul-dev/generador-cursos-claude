-- Esquema común de hex_orders para los cinco sabores del bloque 06.
-- Decisión declarada en 06/01: el esquema es un detalle compartido para que los cinco backends
-- corran contra los mismos datos y la misma suite. Cada backend lo mapea en su adaptador de salida;
-- ninguno lo genera con migraciones propias.
--
-- El catálogo (products) y el inventario (inventory) son tablas separadas desde el principio, sin
-- clave foránea entre ellas: en la parte 3 de cada sabor el catálogo se muda a MongoDB y el
-- inventario se queda aquí. Una FK entre ambas haría imposible ese cambio interno.

CREATE TABLE users (
    id            uuid PRIMARY KEY,
    email         text NOT NULL UNIQUE,
    password_hash text NOT NULL,                       -- bcrypt, coste 10
    role          text NOT NULL CHECK (role IN ('customer', 'operator')),
    created_at    timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE products (                                -- catálogo: lo que se vende y a qué precio
    sku        text PRIMARY KEY,
    name       text NOT NULL,
    unit_price numeric(12, 2) NOT NULL CHECK (unit_price >= 0),
    currency   char(3) NOT NULL DEFAULT 'USD',
    created_at timestamptz NOT NULL DEFAULT now(),
    updated_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE inventory (                               -- control de existencias: lo que hay
    sku        text PRIMARY KEY,                       -- sin FK a products, a propósito (ver cabecera)
    available  integer NOT NULL CHECK (available >= 0),
    version    bigint NOT NULL DEFAULT 0,              -- bloqueo optimista para el adaptador que lo use
    updated_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE orders (
    id           uuid PRIMARY KEY,
    customer_id  uuid NOT NULL REFERENCES users (id),
    status       text NOT NULL CHECK (status IN
                   ('CONFIRMED', 'PAID', 'PAYMENT_REJECTED', 'PAYMENT_PENDING', 'CANCELLED')),
    total_amount numeric(12, 2) NOT NULL,
    currency     char(3) NOT NULL DEFAULT 'USD',
    version      bigint NOT NULL DEFAULT 0,
    created_at   timestamptz NOT NULL DEFAULT now(),
    updated_at   timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE order_lines (                             -- foto del catálogo en el momento de la venta
    order_id     uuid NOT NULL REFERENCES orders (id) ON DELETE CASCADE,
    line_no      smallint NOT NULL,
    sku          text NOT NULL,
    product_name text NOT NULL,
    quantity     integer NOT NULL CHECK (quantity > 0),
    unit_price   numeric(12, 2) NOT NULL,
    PRIMARY KEY (order_id, line_no)
);

CREATE TABLE inventory_reservations (                  -- una fila por línea reservada; se libera al cancelar
    id         uuid PRIMARY KEY,
    order_id   uuid NOT NULL REFERENCES orders (id) ON DELETE CASCADE,
    sku        text NOT NULL,
    quantity   integer NOT NULL CHECK (quantity > 0),
    status     text NOT NULL CHECK (status IN ('RESERVED', 'RELEASED')),
    created_at timestamptz NOT NULL DEFAULT now(),
    updated_at timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX inventory_reservations_order_idx ON inventory_reservations (order_id);

CREATE TABLE payments (
    id           uuid PRIMARY KEY,
    order_id     uuid NOT NULL REFERENCES orders (id),
    operation_id text NOT NULL UNIQUE,                 -- la Idempotency-Key del intento; nunca se regenera
    status       text NOT NULL CHECK (status IN ('AUTHORIZED', 'REJECTED', 'PENDING')),
    reference    text,                                 -- referencia del proveedor cuando la hay
    amount       numeric(12, 2) NOT NULL,
    currency     char(3) NOT NULL DEFAULT 'USD',
    created_at   timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE idempotency_keys (                        -- respuesta guardada por (clave, actor)
    key             text NOT NULL,
    actor_id        uuid NOT NULL,
    request_hash    text NOT NULL,                     -- para detectar la misma clave con otro cuerpo
    response_status integer NOT NULL,
    response_body   jsonb NOT NULL,
    created_at      timestamptz NOT NULL DEFAULT now(),
    PRIMARY KEY (key, actor_id)
);

CREATE TABLE outbox (                                  -- intención durable de publicar (04/03)
    id             uuid PRIMARY KEY,
    aggregate_type text NOT NULL,
    aggregate_id   uuid NOT NULL,
    event_type     text NOT NULL,
    payload        jsonb NOT NULL,
    occurred_at    timestamptz NOT NULL DEFAULT now(),
    published_at   timestamptz,                        -- NULL mientras esté pendiente
    attempts       integer NOT NULL DEFAULT 0
);
CREATE INDEX outbox_pending_idx ON outbox (occurred_at) WHERE published_at IS NULL;

CREATE TABLE notifications (                           -- lo que el Notifier entregó; el taller 09 lo saca a Kafka
    id         uuid PRIMARY KEY,
    order_id   uuid NOT NULL,
    type       text NOT NULL,
    recipient  text NOT NULL,
    payload    jsonb NOT NULL,
    created_at timestamptz NOT NULL DEFAULT now()
);

-- Taller 09: la proyección que alimenta GET /reports/orders-summary desde el tópico orders.events.
-- Se reconstruye desde el offset 0; applied_events es la deduplicación por eventId (at-least-once).
CREATE TABLE orders_summary (
    customer_id      uuid PRIMARY KEY,
    orders_created   integer NOT NULL DEFAULT 0,
    orders_cancelled integer NOT NULL DEFAULT 0,
    open_amount      numeric(12, 2) NOT NULL DEFAULT 0,  -- suma de pedidos creados y no cancelados
    currency         text NOT NULL DEFAULT 'USD',
    updated_at       timestamptz NOT NULL DEFAULT now()
);
CREATE TABLE applied_events (                           -- qué eventos ya aplicó cada proyección
    projection text NOT NULL,
    event_id   uuid NOT NULL,
    applied_at timestamptz NOT NULL DEFAULT now(),
    PRIMARY KEY (projection, event_id)
);
