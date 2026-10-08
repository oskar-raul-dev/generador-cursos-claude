-- Esquema de ms_orders: el del servicio orders, extraído del monolito en el taller 04.
-- Mismas tablas que tenía el monolito para pedidos, pagos, idempotencia y notificaciones, SIN las
-- claves foráneas a users y products: clientes y catálogo son de otro servicio (el monolito).
DROP TABLE IF EXISTS notifications, idempotency_keys, payments, order_lines, orders CASCADE;

CREATE TABLE orders (
    id           uuid PRIMARY KEY,
    customer_id  uuid NOT NULL,                        -- de customers (monolito): referencia, no FK
    customer_email text NOT NULL,                      -- foto del correo al crear el pedido (del token): el aviso de cancelación no llama a customers
    status       text NOT NULL CHECK (status IN
                   ('CONFIRMED', 'PAID', 'PAYMENT_REJECTED', 'PAYMENT_PENDING', 'CANCELLED')),
    total_amount numeric(12, 2) NOT NULL,
    currency     char(3) NOT NULL DEFAULT 'USD',
    created_at   timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE order_lines (                             -- foto del catálogo en el momento de la venta
    order_id     uuid NOT NULL REFERENCES orders (id) ON DELETE CASCADE,
    line_no      smallint NOT NULL,
    sku          text NOT NULL,                        -- de catalog (monolito): referencia, no FK
    product_name text NOT NULL,
    quantity     integer NOT NULL CHECK (quantity > 0),
    unit_price   numeric(12, 2) NOT NULL,
    PRIMARY KEY (order_id, line_no)
);

CREATE TABLE payments (
    id           uuid PRIMARY KEY,
    order_id     uuid NOT NULL REFERENCES orders (id),
    operation_id text NOT NULL UNIQUE,
    status       text NOT NULL CHECK (status IN ('AUTHORIZED', 'REJECTED', 'PENDING')),
    reference    text,
    amount       numeric(12, 2) NOT NULL,
    created_at   timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE idempotency_keys (
    key             text NOT NULL,
    actor_id        uuid NOT NULL,
    request_hash    text NOT NULL,
    response_status integer NOT NULL,
    response_body   text NOT NULL,
    created_at      timestamptz NOT NULL DEFAULT now(),
    PRIMARY KEY (key, actor_id)
);

CREATE TABLE notifications (
    id         uuid PRIMARY KEY,
    order_id   uuid NOT NULL REFERENCES orders (id),
    type       text NOT NULL CHECK (type IN ('ORDER_CANCELLED')),
    recipient  text NOT NULL,
    created_at timestamptz NOT NULL DEFAULT now()
);
