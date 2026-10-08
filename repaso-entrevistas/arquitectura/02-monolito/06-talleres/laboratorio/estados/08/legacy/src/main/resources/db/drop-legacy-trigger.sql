-- Taller 06: la devolución del stock al cancelar pasó a InventoryService.release. El trigger que la
-- hacía en la base se retira; si se quedara, el stock volvería dos veces.
DROP TRIGGER IF EXISTS orders_restore_stock ON orders;
DROP FUNCTION IF EXISTS restore_stock_on_cancel();
