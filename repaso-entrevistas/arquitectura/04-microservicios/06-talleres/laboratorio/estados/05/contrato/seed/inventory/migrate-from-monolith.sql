-- Migración de datos del taller 02: copia el inventario del monolito a ms_inventory.
-- La ejecuta `lab.py migrate-inventory` con el superusuario, porque es el único que ve las dos
-- bases (los usuarios de servicio no pueden conectarse a la base de otro). Se hace con dblink para
-- que sea una sola sentencia por tabla; en producción sería un job con verificación y ventana.
CREATE EXTENSION IF NOT EXISTS dblink;
TRUNCATE holds, inventory;
INSERT INTO inventory (sku, on_hand)
SELECT sku, available
  FROM dblink('dbname=ms_monolith user=ms_admin', 'SELECT sku, available FROM inventory')
       AS m(sku text, available integer);
-- las reservas vivas pasan a ser retenciones: mismo id de pedido como referencia
INSERT INTO holds (id, reference, sku, qty, status)
SELECT id, order_id, sku, quantity,
       CASE status WHEN 'RESERVED' THEN 'HELD' WHEN 'RELEASED' THEN 'RELEASED' ELSE 'COMMITTED' END
  FROM dblink('dbname=ms_monolith user=ms_admin', 'SELECT id, order_id, sku, quantity, status FROM inventory_reservations')
       AS m(id uuid, order_id uuid, sku text, quantity integer, status text);
SELECT (SELECT count(*) FROM inventory) AS skus, (SELECT sum(on_hand) FROM inventory) AS units,
       (SELECT count(*) FROM holds) AS holds;
