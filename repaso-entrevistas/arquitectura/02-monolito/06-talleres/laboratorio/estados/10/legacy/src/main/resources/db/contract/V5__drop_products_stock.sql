-- V5 — contract (taller 09). Solo cuando ninguna instancia lee ni escribe products.stock: es el paso
-- sin vuelta atrás. Una versión anterior a contract que arranque después de esto no funciona.
ALTER TABLE products DROP COLUMN stock;
