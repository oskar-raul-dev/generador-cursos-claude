-- Semilla de mono_legacy. Valores de §12 de la guía.
-- Taller 09: el esquema lo crean las migraciones de Flyway al arrancar el legado (antes, ddl-auto), así
-- que `lab.py seed` sigue exigiendo que el legado haya arrancado una vez contra esta base. La semilla
-- vale para cualquier paso de la migración products → inventory: escribe products.stock si la columna
-- existe e inventory si la tabla existe.

DO $$
DECLARE
    t text;
BEGIN
    -- se vacía lo que exista; flyway_schema_history no se toca nunca
    FOREACH t IN ARRAY ARRAY['users', 'products', 'inventory', 'orders', 'order_lines', 'payments',
                             'notifications', 'batch_runs', 'idempotency_keys', 'outbox_events',
                             'revoked_tokens', 'job_leases', 'inventory_reservations'] LOOP
        IF to_regclass(t) IS NOT NULL THEN
            EXECUTE format('TRUNCATE %I RESTART IDENTITY CASCADE', t);
        END IF;
    END LOOP;
END $$;

INSERT INTO users (id, email, password_hash, role) VALUES
    ('11111111-1111-4111-8111-111111111111', 'ana@mono.local',
     '$2y$10$Rdmvw5b4tBFmQ7.1vLA/p.Mg5xRLfiL2itgsZuNtaAZGv2IJxsQf6', 'customer'),   -- ana-12345
    ('22222222-2222-4222-8222-222222222222', 'ops@mono.local',
     '$2y$10$VQasHiCmvPNmAKT1.V1lZerLdHrz/Qr.1RJQxFg2.QHD7cfnems3S', 'operator');   -- ops-12345

CREATE TEMP TABLE seed_products (sku text, name text, price numeric(12,2), stock int);
INSERT INTO seed_products VALUES
    ('SKU-001', 'Mechanical keyboard',   49.90,  20),
    ('SKU-002', 'USB-C cable',            9.90, 100),
    ('SKU-003', '27" monitor',          222.00,   5),   -- 3 unidades = 666.00: el resultado incierto
    ('SKU-004', 'Webcam',                59.00,   0),   -- sin stock
    ('SKU-005', 'Workstation',         1499.00,   3);   -- > 1000.00: pago rechazado

DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM information_schema.columns
               WHERE table_name = 'products' AND column_name = 'stock') THEN
        INSERT INTO products (sku, name, price, stock) SELECT sku, name, price, stock FROM seed_products;
    ELSE
        INSERT INTO products (sku, name, price) SELECT sku, name, price FROM seed_products;
    END IF;
    IF to_regclass('inventory') IS NOT NULL THEN
        -- taller 10: mono-inventory puede haber renombrado su columna; la semilla es otro cliente de
        -- la tabla compartida y también tiene que enterarse
        IF EXISTS (SELECT 1 FROM information_schema.columns
                   WHERE table_name = 'inventory' AND column_name = 'on_hand') THEN
            INSERT INTO inventory (sku, on_hand) SELECT sku, stock FROM seed_products;
        ELSE
            INSERT INTO inventory (sku, stock) SELECT sku, stock FROM seed_products;
        END IF;
    END IF;
END $$;
