-- V3 — expand (taller 09). Nace inventory, dueña del stock, al lado de products.stock, que sigue
-- existiendo: las instancias de la versión anterior lo siguen leyendo y escribiendo. Nada se borra.
CREATE TABLE inventory (
    sku   varchar(255) PRIMARY KEY REFERENCES products (sku),
    stock integer NOT NULL CHECK (stock >= 0)
);

INSERT INTO inventory (sku, stock)
SELECT sku, stock FROM products
ON CONFLICT (sku) DO NOTHING;

-- la versión nueva, al terminar la migración (paso contract), ya no escribirá esta columna al crear
-- un producto
ALTER TABLE products ALTER COLUMN stock SET DEFAULT 0;
