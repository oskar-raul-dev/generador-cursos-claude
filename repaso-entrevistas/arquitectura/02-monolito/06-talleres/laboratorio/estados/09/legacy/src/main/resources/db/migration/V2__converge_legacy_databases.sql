-- V2 — converger (taller 09). Una base que pasó por los talleres 01–08 tiene cosas que una nueva no:
-- las claves foráneas que Hibernate creó para @ManyToOne antes del taller 06 y, si arrancó entre los
-- talleres 01 y 05, el trigger de stock. Decisión: las claves entre módulos se retiran (cada módulo es
-- dueño de sus tablas y la integridad entre módulos la garantiza la aplicación, 02/04); la de
-- order_lines → orders, dentro de orders, se conserva. IF EXISTS: en una base nueva no hace nada.
ALTER TABLE orders DROP CONSTRAINT IF EXISTS fksjfs85qf6vmcurlx43cnc16gy;     -- orders.customer_id → users
ALTER TABLE payments DROP CONSTRAINT IF EXISTS fk81gagumt0r8y3rmudcgpbk42l;   -- payments.order_id → orders
DROP TRIGGER IF EXISTS orders_restore_stock ON orders;                        -- lo retiraba SchemaFixer
DROP FUNCTION IF EXISTS restore_stock_on_cancel();
