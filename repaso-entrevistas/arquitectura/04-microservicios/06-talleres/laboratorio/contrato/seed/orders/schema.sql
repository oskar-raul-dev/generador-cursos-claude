-- Esquema de ms_orders: el del servicio orders, extraído del monolito en el taller 04.
-- Mismas tablas que tenía el monolito para pedidos, pagos, idempotencia y notificaciones, SIN las
-- claves foráneas a users y products: clientes y catálogo son de otro servicio (el monolito).
DROP TABLE IF EXISTS customer_overview, order_overview, order_saga_log, order_sagas, processed_messages, outbox_events, notifications, idempotency_keys, payments, order_lines, orders CASCADE;

CREATE TABLE orders (
    id           uuid PRIMARY KEY,
    customer_id  uuid NOT NULL,                        -- de customers (monolito): referencia, no FK
    customer_email text NOT NULL,                      -- foto del correo al crear el pedido (del token): el aviso de cancelación no llama a customers
    status       text NOT NULL CHECK (status IN       -- PENDING: solo v2, la saga en curso (taller 08)
                   ('PENDING', 'CONFIRMED', 'PAID', 'PAYMENT_REJECTED', 'PAYMENT_PENDING', 'CANCELLED')),
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

-- Taller 06: el outbox. El evento se escribe en la MISMA transacción que el cambio del pedido; un
-- proceso aparte (OutboxPublisher) lo lleva a Kafka y marca published_at. Si el proceso muere entre
-- el envío y la marca, el evento sale dos veces: al menos una vez, y los consumidores lo saben.
CREATE TABLE outbox_events (
    id           uuid PRIMARY KEY,                     -- el eventId: la clave de deduplicación de los consumidores
    aggregate_id uuid NOT NULL,                        -- el orderId: la clave de partición
    topic        text NOT NULL DEFAULT 'orders.events',  -- taller 08: OrderPlaced de v2 sale a orders.placed
    type         text NOT NULL,                        -- OrderPlaced · OrderPaid · OrderCancelled
    payload      text NOT NULL,                        -- el evento tal cual sale al topic
    occurred_at  timestamptz NOT NULL DEFAULT clock_timestamp(),
    published_at timestamptz,                          -- NULL mientras esté pendiente
    trace_context text                                 -- taller 07: el traceparent de la petición que creó el hecho
);
CREATE INDEX outbox_events_pending_idx ON outbox_events (occurred_at) WHERE published_at IS NULL;

-- Taller 08: el inbox de orders, que ahora también CONSUME (los resultados de la saga coreografiada).
CREATE TABLE processed_messages (
    consumer     text NOT NULL,
    event_id     uuid NOT NULL,
    processed_at timestamptz NOT NULL DEFAULT now(),
    PRIMARY KEY (consumer, event_id)
);

-- Taller 09: el orquestador. Una fila por saga con el paso en curso, cuántas veces se intentó, cuándo
-- toca el siguiente intento y el plazo del paso. Es lo que en la coreografía no existía: un sitio
-- donde preguntar "¿en qué punto está este pedido y desde cuándo?".
CREATE TABLE order_sagas (
    order_id        uuid PRIMARY KEY REFERENCES orders (id),
    step            text NOT NULL CHECK (step IN ('RESERVE_INVENTORY', 'AUTHORIZE_PAYMENT', 'COMMIT_INVENTORY',
                                                 'RELEASE_INVENTORY', 'DONE', 'ESCALATED')),
    attempts        integer NOT NULL DEFAULT 0,          -- intentos del paso en curso
    next_attempt_at timestamptz NOT NULL DEFAULT clock_timestamp(),
    step_started_at timestamptz NOT NULL DEFAULT clock_timestamp(),
    deadline_at     timestamptz,                         -- plazo del paso; NULL = sin plazo (la provocación)
    last_error      text
);
CREATE INDEX order_sagas_due_idx ON order_sagas (next_attempt_at) WHERE step NOT IN ('DONE', 'ESCALATED');

CREATE TABLE order_saga_log (                          -- cada transición, para auditar la saga entera
    id        bigserial PRIMARY KEY,
    order_id  uuid NOT NULL,
    at        timestamptz NOT NULL DEFAULT clock_timestamp(),
    step      text NOT NULL,
    outcome   text NOT NULL
);

-- Taller 11: el read model de "mis pedidos con su estado de pago". Solo lectura para la API, escrito
-- únicamente por el proyector (OverviewProjector) a partir de orders.events. Se puede tirar y
-- reconstruir desde el log: por eso no tiene claves foráneas a las tablas de escritura.
CREATE TABLE order_overview (
    order_id       uuid PRIMARY KEY,
    customer_id    uuid NOT NULL,
    status         text NOT NULL,
    payment_status text,                                 -- lo que el log dice del pago (no la verdad de payments)
    total_amount   numeric(12, 2) NOT NULL,
    currency       char(3) NOT NULL,
    placed_at      timestamptz NOT NULL,
    updated_at     timestamptz NOT NULL DEFAULT clock_timestamp()
);
CREATE INDEX order_overview_customer_idx ON order_overview (customer_id, placed_at DESC);

CREATE TABLE customer_overview (                       -- el resumen: la parte que NO es idempotente por naturaleza
    customer_id uuid PRIMARY KEY,
    paid_orders integer NOT NULL DEFAULT 0,
    paid_amount numeric(12, 2) NOT NULL DEFAULT 0
);
