-- Esquema de Contingencia: el subconjunto del Siga que opera en un solo sitio (2016).
-- Lo crea la imagen de Postgres la primera vez que arranca; Hibernate no toca el esquema.

CREATE TABLE store (
    id        VARCHAR(10) PRIMARY KEY,          -- DRO-001
    name      VARCHAR(80) NOT NULL,
    city      VARCHAR(40) NOT NULL
);

CREATE TABLE product (
    sku       VARCHAR(12) PRIMARY KEY,          -- SKU-0001
    name      VARCHAR(80) NOT NULL,
    category  VARCHAR(30) NOT NULL
);

CREATE TABLE price (
    sku       VARCHAR(12) REFERENCES product(sku),
    store_id  VARCHAR(10) REFERENCES store(id),
    amount    INTEGER NOT NULL,                 -- pesos colombianos, sin decimales
    PRIMARY KEY (sku, store_id)
);

CREATE TABLE stock_level (
    store_id          VARCHAR(10) REFERENCES store(id),
    sku               VARCHAR(12) REFERENCES product(sku),
    quantity          INTEGER NOT NULL,
    reorder_threshold INTEGER NOT NULL,
    PRIMARY KEY (store_id, sku)
);

CREATE TABLE stock_movement (
    id         BIGSERIAL PRIMARY KEY,
    store_id   VARCHAR(10) REFERENCES store(id),
    sku        VARCHAR(12) REFERENCES product(sku),
    type       VARCHAR(10) NOT NULL,            -- SALE, LOAN_OUT, LOAN_IN
    quantity   INTEGER NOT NULL,
    created_at TIMESTAMP NOT NULL DEFAULT now()
);

-- El préstamo entre vecinas es una reposición cuyo origen es otra droguería.
CREATE TABLE replenishment_order (
    id                   BIGSERIAL PRIMARY KEY,
    sku                  VARCHAR(12) REFERENCES product(sku),
    origin_store_id      VARCHAR(10) REFERENCES store(id),
    destination_store_id VARCHAR(10) REFERENCES store(id),
    quantity             INTEGER NOT NULL,
    status               VARCHAR(12) NOT NULL,  -- PENDING, DISPATCHED
    created_at           TIMESTAMP NOT NULL DEFAULT now()
);

-- Domicilios esperando moto. La Braqui los lee directamente de aquí (desde 2023).
CREATE TABLE dispatch (
    id         BIGSERIAL PRIMARY KEY,
    store_id   VARCHAR(10) REFERENCES store(id),
    address    VARCHAR(120) NOT NULL,
    status     VARCHAR(10) NOT NULL,            -- PENDING, ASSIGNED
    rider_id   INTEGER,
    created_at TIMESTAMP NOT NULL DEFAULT now()
);

-- Las tablas de la Braqui viven en la misma base desde que es un módulo del Siga.
CREATE TABLE rider (
    id    SERIAL PRIMARY KEY,
    name  VARCHAR(60) NOT NULL,
    plate VARCHAR(8) NOT NULL
);

CREATE TABLE braqui_transfer (
    id                   BIGSERIAL PRIMARY KEY,
    order_id             BIGINT NOT NULL,       -- el id del préstamo que trae el archivo
    sku                  VARCHAR(12) NOT NULL,
    origin_store_id      VARCHAR(10) NOT NULL,
    destination_store_id VARCHAR(10) NOT NULL,
    quantity             INTEGER NOT NULL,
    file_name            VARCHAR(60) NOT NULL,
    received_at          TIMESTAMP NOT NULL DEFAULT now()
);

-- El tercer parche del script de traslados: los nombres de archivo ya procesados.
CREATE TABLE transfer_file_processed (
    file_name    VARCHAR(60) PRIMARY KEY,
    processed_at TIMESTAMP NOT NULL DEFAULT now()
);
