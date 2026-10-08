-- ============================================================================
--  semilla-sqlite.sql — carga los mismos CSV en SQLite
--
--    sqlite3 tienda.db < semilla-sqlite.sql
--
--  `.import --csv` no entiende de nulos: guardaria la cadena literal '\N' donde
--  PostgreSQL escribio un NULL. Por eso cada columna anulable se repara despues,
--  y por eso `verificar-sqlite.sql` lo comprueba explicitamente.
-- ============================================================================

.bail on
.mode csv

-- Tabla de paso para `pagos`: mismas columnas, ninguna restriccion. Ver el
-- comentario de la reparacion de nulos, mas abajo.
CREATE TABLE pagos_carga (
  id INTEGER, pedido_id INTEGER, metodo TEXT, importe TEXT, pagado_en TEXT, referencia TEXT
);

PRAGMA foreign_keys = OFF;
PRAGMA journal_mode = OFF;      -- solo durante la carga: sin diario va mucho mas rapido
PRAGMA synchronous  = OFF;

.import --csv datos/clientes.csv       clientes
.import --csv datos/productos.csv      productos
.import --csv datos/pedidos.csv        pedidos
.import --csv datos/pedido_lineas.csv  pedido_lineas
.import --csv datos/pagos.csv          pagos_carga
.import --csv datos/eventos_pedido.csv eventos_pedido

-- Reparacion de los nulos que `.import` dejo como la cadena '\N'.
--
-- `pedidos.actualizado_en` se repara en sitio: no tiene restriccion que lo impida.
UPDATE pedidos SET actualizado_en = NULL WHERE actualizado_en = '\N';

-- `pagos.referencia` NO se puede reparar en sitio, y por eso paso por
-- `pagos_carga`. La razon merece entenderse porque es de las que muerden:
-- `.import` inserta fila a fila y **el UNIQUE se comprueba en cada INSERT**, no al
-- final. Los 273 126 pagos en efectivo llegan todos con la misma cadena literal
-- '\N', asi que el segundo de ellos ya viola la restriccion y la carga muere en la
-- linea 5 del fichero. Con tabla de paso sin restricciones, el NULLIF se aplica
-- antes de que `pagos` vea nada.
INSERT INTO pagos (id, pedido_id, metodo, importe, pagado_en, referencia)
SELECT id, pedido_id, metodo, importe, pagado_en, nullif(referencia, '\N')
FROM pagos_carga;

DROP TABLE pagos_carga;

PRAGMA journal_mode = DELETE;
PRAGMA synchronous  = FULL;
PRAGMA foreign_keys = ON;

-- SQLite no tiene planificador basado en costes como PostgreSQL, pero ANALYZE si
-- llena `sqlite_stat1` y el resolutor de indices lo consulta.
ANALYZE;

SELECT 'semilla-sqlite.sql: carga terminada.';
