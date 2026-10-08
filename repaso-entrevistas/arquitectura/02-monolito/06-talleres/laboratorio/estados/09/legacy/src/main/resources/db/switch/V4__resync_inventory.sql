-- V4 — antes de leer de inventory (paso switch, taller 09). Mientras convivieron la versión del
-- estado 08 y la de expand, la vieja solo escribía products.stock: inventory pudo quedarse atrás.
-- Cuando ya no queda ninguna instancia vieja, products.stock es la verdad y se copia una vez más.
UPDATE inventory i SET stock = p.stock FROM products p WHERE p.sku = i.sku AND i.stock <> p.stock;

INSERT INTO inventory (sku, stock)
SELECT sku, stock FROM products
ON CONFLICT (sku) DO NOTHING;
