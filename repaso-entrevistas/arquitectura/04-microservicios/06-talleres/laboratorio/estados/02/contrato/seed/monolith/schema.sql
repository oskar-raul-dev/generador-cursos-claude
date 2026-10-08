-- Esquema de ms_monolith: la base única del monolito de partida (06/01).
-- Escrito como se escribe un monolito típico, no como uno ejemplar: el catálogo, el inventario, los
-- pedidos, los pagos y las notificaciones comparten base, y el código las cruza con JOIN y con
-- claves foráneas sin pedir permiso. Es el material que desarman los talleres 02 a 09.
-- `lab.py seed` lo recrea entero (DROP + CREATE) antes de cargar la semilla.

DROP TABLE IF EXISTS notifications, idempotency_keys, payments, inventory_reservations,
                     order_lines, orders, inventory, products, users,
                     holds CASCADE;                     -- holds: la deja inventory si arranca contra esta base (taller 02)

CREATE TABLE users (                                   -- customers: la identidad se queda en el monolito
    id            uuid PRIMARY KEY,
    email         text NOT NULL UNIQUE,
    password_hash text NOT NULL,                       -- bcrypt, coste 10
    role          text NOT NULL CHECK (role IN ('customer', 'operator'))
);

CREATE TABLE products (                                -- catalog: lo que se vende y a qué precio
    sku        text PRIMARY KEY,
    name       text NOT NULL,
    unit_price numeric(12, 2) NOT NULL CHECK (unit_price >= 0),
    currency   char(3) NOT NULL DEFAULT 'USD'
);

CREATE TABLE inventory (                               -- inventory: lo que hay
    sku       text PRIMARY KEY REFERENCES products (sku),   -- FK al catálogo: nadie pensó que algún día vivirían aparte
    available integer NOT NULL CHECK (available >= 0)
);

CREATE TABLE orders (
    id           uuid PRIMARY KEY,
    customer_id  uuid NOT NULL REFERENCES users (id),
    status       text NOT NULL CHECK (status IN
                   ('CONFIRMED', 'PAID', 'PAYMENT_REJECTED', 'PAYMENT_PENDING', 'CANCELLED')),
    total_amount numeric(12, 2) NOT NULL,
    currency     char(3) NOT NULL DEFAULT 'USD',
    created_at   timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE order_lines (                             -- foto del catálogo en el momento de la venta
    order_id     uuid NOT NULL REFERENCES orders (id) ON DELETE CASCADE,
    line_no      smallint NOT NULL,
    sku          text NOT NULL REFERENCES products (sku),
    product_name text NOT NULL,
    quantity     integer NOT NULL CHECK (quantity > 0),
    unit_price   numeric(12, 2) NOT NULL,
    PRIMARY KEY (order_id, line_no)
);

CREATE TABLE inventory_reservations (                  -- una fila por línea reservada
    id       uuid PRIMARY KEY,
    order_id uuid NOT NULL,                            -- sin FK a orders desde el taller 02: la reserva se hace ANTES de que exista el pedido
    sku      text NOT NULL REFERENCES inventory (sku),
    quantity integer NOT NULL CHECK (quantity > 0),
    status   text NOT NULL CHECK (status IN ('RESERVED', 'RELEASED', 'CONSUMED'))
);
CREATE INDEX inventory_reservations_order_idx ON inventory_reservations (order_id);

CREATE TABLE payments (
    id           uuid PRIMARY KEY,
    order_id     uuid NOT NULL REFERENCES orders (id),
    operation_id text NOT NULL UNIQUE,                 -- la Idempotency-Key del intento; viaja al proveedor
    status       text NOT NULL CHECK (status IN ('AUTHORIZED', 'REJECTED', 'PENDING')),
    reference    text,                                 -- referencia del proveedor, si respondió
    amount       numeric(12, 2) NOT NULL,
    created_at   timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE idempotency_keys (                        -- respuesta guardada por (clave, actor)
    key             text NOT NULL,
    actor_id        uuid NOT NULL,
    request_hash    text NOT NULL,                     -- la misma clave con otro cuerpo es un error del cliente
    response_status integer NOT NULL,
    response_body   text NOT NULL,
    created_at      timestamptz NOT NULL DEFAULT now(),
    PRIMARY KEY (key, actor_id)
);

CREATE TABLE notifications (                           -- se escribe en la MISMA transacción que la cancelación (taller 06)
    id         uuid PRIMARY KEY,
    order_id   uuid NOT NULL REFERENCES orders (id),
    type       text NOT NULL CHECK (type IN ('ORDER_CANCELLED')),
    recipient  text NOT NULL,
    created_at timestamptz NOT NULL DEFAULT now()
);
