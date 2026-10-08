-- Esquema de ms_payments: el del servicio payments (Python), extraído en el taller 03.
DROP TABLE IF EXISTS outbox_events, processed_messages, payments CASCADE;

CREATE TABLE payments (
    id           uuid PRIMARY KEY,
    order_id     uuid NOT NULL,                        -- referencia al pedido de otro servicio: sin FK
    operation_id text NOT NULL UNIQUE,                 -- la Idempotency-Key: dos peticiones con la misma, un solo cobro
    amount       numeric(12, 2) NOT NULL CHECK (amount > 0),
    status       text NOT NULL CHECK (status IN ('IN_PROGRESS', 'AUTHORIZED', 'REJECTED', 'PENDING', 'VOIDED')),   -- VOIDED: taller 06
    reference    text,                                 -- la del proveedor, si respondió
    created_at   timestamptz NOT NULL DEFAULT now()
);

-- Taller 06: el inbox del consumidor de orders.events.
CREATE TABLE processed_messages (
    consumer     text NOT NULL,
    event_id     uuid NOT NULL,
    processed_at timestamptz NOT NULL DEFAULT now(),
    PRIMARY KEY (consumer, event_id)
);

-- Taller 08: el outbox de payments. En la saga, payments también publica hechos, y con la misma regla que
-- orders: el hecho se escribe en la transacción del efecto y un publicador lo lleva a Kafka.
CREATE TABLE outbox_events (
    id            uuid PRIMARY KEY,                    -- el eventId
    aggregate_id  uuid NOT NULL,                       -- el orderId: la clave de partición
    topic         text NOT NULL,                       -- payments.results
    type          text NOT NULL,
    payload       text NOT NULL,
    trace_context text,                                -- el traceparent del mensaje que lo provocó (taller 07)
    occurred_at   timestamptz NOT NULL DEFAULT clock_timestamp(),
    published_at  timestamptz
);
CREATE INDEX outbox_events_pending_idx ON outbox_events (occurred_at) WHERE published_at IS NULL;
