-- Esquema en SQLite (G1; desde G3, el almacén de compose). Idempotente: todo es IF NOT EXISTS.
CREATE TABLE IF NOT EXISTS stock_levels (
    store             TEXT    NOT NULL,
    sku               TEXT    NOT NULL,
    quantity          INTEGER NOT NULL CHECK (quantity >= 0),
    reorder_threshold INTEGER NOT NULL DEFAULT 0 CHECK (reorder_threshold >= 0),
    PRIMARY KEY (store, sku)
);

-- La existencia solo cambia por movimientos (D33): la suma de quantity es la existencia.
CREATE TABLE IF NOT EXISTS stock_movements (
    id          INTEGER PRIMARY KEY AUTOINCREMENT,
    store       TEXT    NOT NULL,
    sku         TEXT    NOT NULL,
    type        TEXT    NOT NULL,
    quantity    INTEGER NOT NULL,
    reason_code TEXT,
    reference   TEXT,
    created_at  TEXT    NOT NULL
);

-- Una tabla de datos, no un enum del contrato: se agregan códigos sin cambiar el OpenAPI.
CREATE TABLE IF NOT EXISTS reason_codes (
    code        TEXT    PRIMARY KEY,
    description TEXT    NOT NULL,
    applies_to  TEXT    NOT NULL,
    active      INTEGER NOT NULL DEFAULT 1
);

-- G5: las ventas. Cada una deja además un movimiento SALE en stock_movements.
CREATE TABLE IF NOT EXISTS sales (
    id          INTEGER PRIMARY KEY AUTOINCREMENT,
    store       TEXT    NOT NULL,
    sku         TEXT    NOT NULL,
    quantity    INTEGER NOT NULL CHECK (quantity >= 1),
    unit_price  INTEGER NOT NULL,
    total       INTEGER NOT NULL,
    created_at  TEXT    NOT NULL
);

-- G11: el préstamo entre droguerías como saga. Una fila por préstamo, con el estado de la saga, y una
-- por cada paso hecho o deshecho: el registro que deja retomar una saga a medias.
CREATE TABLE IF NOT EXISTS loans (
    id                     INTEGER PRIMARY KEY AUTOINCREMENT,
    sku                    TEXT    NOT NULL,
    origin_store           TEXT    NOT NULL,
    destination_store      TEXT    NOT NULL,
    quantity               INTEGER NOT NULL CHECK (quantity >= 1),
    status                 TEXT    NOT NULL,
    sale_id                TEXT,
    replenishment_order_id TEXT,
    failure                TEXT,
    created_at             TEXT    NOT NULL,
    updated_at             TEXT    NOT NULL
);

CREATE TABLE IF NOT EXISTS loan_steps (
    id      INTEGER PRIMARY KEY AUTOINCREMENT,
    loan_id BIGINT  NOT NULL,
    step    TEXT    NOT NULL,
    action  TEXT    NOT NULL,
    outcome TEXT    NOT NULL,
    detail  TEXT,
    at      TEXT    NOT NULL
);

-- G13 (Fase 26): el outbox (ver schema-postgresql.sql). En SQLite nadie lo publica: el sidecar solo lee Postgres.
CREATE TABLE IF NOT EXISTS outbox (
    id           TEXT PRIMARY KEY,
    subject      TEXT NOT NULL,
    payload      TEXT NOT NULL,
    created_at   TEXT NOT NULL,
    published_at TEXT
);
