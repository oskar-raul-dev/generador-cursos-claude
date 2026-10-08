-- Al cancelar un pedido, el stock vuelve a products. Lo añadió DBA en 2023 "porque la app a veces no
-- lo devolvía". La aplicación no sabe que existe.
CREATE OR REPLACE FUNCTION restore_stock_on_cancel() RETURNS trigger AS $$
BEGIN
    UPDATE products p
       SET stock = p.stock + l.quantity
      FROM order_lines l
     WHERE l.order_id = NEW.id
       AND p.sku = l.sku;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS orders_restore_stock ON orders;
CREATE TRIGGER orders_restore_stock
    AFTER UPDATE OF status ON orders
    FOR EACH ROW
    WHEN (NEW.status = 'CANCELLED' AND OLD.status IS DISTINCT FROM 'CANCELLED')
    EXECUTE FUNCTION restore_stock_on_cancel();
