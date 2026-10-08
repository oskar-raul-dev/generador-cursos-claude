-- Semilla de mono_legacy. Valores de §12 de la guía.
-- Las tablas NO se crean aquí: las crea Hibernate al arrancar (ddl-auto: update). Por eso
-- `lab.py seed` exige que el legado haya arrancado al menos una vez contra esta base.

-- taller 07: también las claves de idempotencia; si no, una segunda corrida recibe las respuestas
-- guardadas de la primera. Taller 08: y la outbox, los tokens revocados y los leases de los jobs.
TRUNCATE users, products, orders, order_lines, payments, notifications, batch_runs, idempotency_keys,
    outbox_events, revoked_tokens, job_leases RESTART IDENTITY CASCADE;

INSERT INTO users (id, email, password_hash, role) VALUES
    ('11111111-1111-4111-8111-111111111111', 'ana@mono.local',
     '$2y$10$Rdmvw5b4tBFmQ7.1vLA/p.Mg5xRLfiL2itgsZuNtaAZGv2IJxsQf6', 'customer'),   -- ana-12345
    ('22222222-2222-4222-8222-222222222222', 'ops@mono.local',
     '$2y$10$VQasHiCmvPNmAKT1.V1lZerLdHrz/Qr.1RJQxFg2.QHD7cfnems3S', 'operator');   -- ops-12345

INSERT INTO products (sku, name, price, stock) VALUES
    ('SKU-001', 'Mechanical keyboard',   49.90,  20),
    ('SKU-002', 'USB-C cable',            9.90, 100),
    ('SKU-003', '27" monitor',          222.00,   5),   -- 3 unidades = 666.00: el resultado incierto
    ('SKU-004', 'Webcam',                59.00,   0),   -- sin stock
    ('SKU-005', 'Workstation',         1499.00,   3);   -- > 1000.00: pago rechazado
