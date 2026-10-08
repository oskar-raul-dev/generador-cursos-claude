-- Semilla de ms_monolith. Valores de §14 de la guía. `lab.py seed` la carga después de recrear el
-- esquema, porque la suite crea pedidos y consume stock: cada corrida parte del mismo estado.

-- UUID fijos para que la suite y los servicios hablen de los mismos actores.
INSERT INTO users (id, email, password_hash, role) VALUES
    ('11111111-1111-4111-8111-111111111111', 'ana@ms.local',
     '$2y$10$Rdmvw5b4tBFmQ7.1vLA/p.Mg5xRLfiL2itgsZuNtaAZGv2IJxsQf6', 'customer'),   -- ana-12345
    ('22222222-2222-4222-8222-222222222222', 'ops@ms.local',
     '$2y$10$VQasHiCmvPNmAKT1.V1lZerLdHrz/Qr.1RJQxFg2.QHD7cfnems3S', 'operator');   -- ops-12345

INSERT INTO products (sku, name, unit_price) VALUES
    ('SKU-001', 'Mechanical keyboard',   49.90),
    ('SKU-002', 'USB-C cable',            9.90),
    ('SKU-003', '27" monitor',          222.00),   -- 3 unidades = 666.00: el resultado incierto
    ('SKU-004', 'Webcam',                59.00),
    ('SKU-005', 'Workstation',         1499.00);   -- > 1000.00: el proveedor rechaza el pago

INSERT INTO inventory (sku, available) VALUES
    ('SKU-001', 20),
    ('SKU-002', 100),
    ('SKU-003', 5),
    ('SKU-004', 0),                              -- sin stock: provoca INSUFFICIENT_INVENTORY
    ('SKU-005', 3);
