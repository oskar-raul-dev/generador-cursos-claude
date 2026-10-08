-- Semilla de hex_orders. Es idempotente: `lab.py seed` la vuelve a cargar antes de cada corrida de
-- la suite, porque la suite crea pedidos y consume stock. Los valores son los de §11 de la guía.

TRUNCATE users, products, inventory, orders, order_lines, inventory_reservations, payments,
         idempotency_keys, outbox, notifications, orders_summary, applied_events RESTART IDENTITY CASCADE;

-- Los UUID son fijos para que los cinco backends y la suite hablen de los mismos actores.
INSERT INTO users (id, email, password_hash, role) VALUES
    ('11111111-1111-4111-8111-111111111111', 'ana@hex.local',
     '$2y$10$Rdmvw5b4tBFmQ7.1vLA/p.Mg5xRLfiL2itgsZuNtaAZGv2IJxsQf6', 'customer'),   -- ana-12345
    ('22222222-2222-4222-8222-222222222222', 'ops@hex.local',
     '$2y$10$VQasHiCmvPNmAKT1.V1lZerLdHrz/Qr.1RJQxFg2.QHD7cfnems3S', 'operator');   -- ops-12345

INSERT INTO products (sku, name, unit_price, currency) VALUES
    ('SKU-001', 'Mechanical keyboard',   49.90, 'USD'),
    ('SKU-002', 'USB-C cable',            9.90, 'USD'),
    ('SKU-003', '27" monitor',          222.00, 'USD'),   -- 3 unidades = 666.00: el importe del resultado incierto
    ('SKU-004', 'Webcam',                59.00, 'USD'),
    ('SKU-005', 'Workstation',         1499.00, 'USD');   -- > 1000.00: el pago se rechaza

INSERT INTO inventory (sku, available) VALUES
    ('SKU-001', 20),
    ('SKU-002', 100),
    ('SKU-003', 5),
    ('SKU-004', 0),                                       -- sin stock: provoca INSUFFICIENT_INVENTORY
    ('SKU-005', 3);
