-- ============================================================================
--  semilla-mysql.sql — carga los mismos datos en MySQL / MariaDB
--
--  Requiere haber corrido antes, contra PostgreSQL:
--    psql ... -f esquema.sql && psql ... -f semilla.sql && psql ... -f exportar-csv.sql
--  y despues, contra MySQL:
--    docker exec -i bd-lab-mysql mysql -uroot -proot tienda < esquema-mysql.sql
--
--  Y entonces esta carga:
--    docker exec -i bd-lab-mysql mysql --local-infile=1 -uroot -proot tienda < semilla-mysql.sql
--    docker exec -i bd-lab-maria mariadb --local-infile=1 -uroot -proot tienda < semilla-mysql.sql
--
--  `LOCAL INFILE` y no `INFILE` a secas: sin LOCAL, el servidor lee el fichero el
--  mismo, y solo puede leer de su `secure_file_priv` —por defecto
--  `/var/lib/mysql-files/`, no el volumen montado—. Con LOCAL lo lee el CLIENTE, que
--  aqui corre dentro del contenedor y si ve `/entorno`. La bandera hace falta en los
--  dos lados: `local_infile=1` en el servidor (esta en el `docker-compose.yml`) y
--  `--local-infile=1` en la linea del cliente.
-- ============================================================================

SET SESSION time_zone = '+00:00';   -- los CSV traen la hora ya en UTC, sin sufijo de zona
SET SESSION sql_mode  = 'STRICT_ALL_TABLES';  -- que un dato mal formado falle, no se trunque en silencio

-- Comprobaciones apagadas SOLO durante la carga. Los datos vienen de PostgreSQL, que
-- ya los valido; volver a comprobar cada clave foranea fila a fila multiplica el
-- tiempo de carga sin encontrar nada.
SET FOREIGN_KEY_CHECKS = 0;
SET UNIQUE_CHECKS      = 0;

SELECT '>> clientes' AS paso;
LOAD DATA LOCAL INFILE '/entorno/datos/clientes.csv' INTO TABLE clientes
  FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"' ESCAPED BY '\\'
  LINES TERMINATED BY '\n'
  (id, codigo, nombre, email, pais, creado_en);

SELECT '>> productos' AS paso;
LOAD DATA LOCAL INFILE '/entorno/datos/productos.csv' INTO TABLE productos
  FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"' ESCAPED BY '\\'
  LINES TERMINATED BY '\n'
  (id, codigo, nombre, categoria, precio, activo);

SELECT '>> pedidos' AS paso;
LOAD DATA LOCAL INFILE '/entorno/datos/pedidos.csv' INTO TABLE pedidos
  FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"' ESCAPED BY '\\'
  LINES TERMINATED BY '\n'
  (id, codigo, cliente_id, estado, total, creado_en, @actualizado_en)
  SET actualizado_en = NULLIF(@actualizado_en, '');

SELECT '>> pedido_lineas' AS paso;
LOAD DATA LOCAL INFILE '/entorno/datos/pedido_lineas.csv' INTO TABLE pedido_lineas
  FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"' ESCAPED BY '\\'
  LINES TERMINATED BY '\n'
  (pedido_id, linea, producto_id, cantidad, precio_unit);

SELECT '>> pagos' AS paso;
LOAD DATA LOCAL INFILE '/entorno/datos/pagos.csv' INTO TABLE pagos
  FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"' ESCAPED BY '\\'
  LINES TERMINATED BY '\n'
  (id, pedido_id, metodo, importe, pagado_en, @referencia)
  SET referencia = NULLIF(@referencia, '');

SELECT '>> eventos_pedido' AS paso;
LOAD DATA LOCAL INFILE '/entorno/datos/eventos_pedido.csv' INTO TABLE eventos_pedido
  FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"' ESCAPED BY '\\'
  LINES TERMINATED BY '\n'
  (id, pedido_id, tipo, carga, ocurrido_en);

SET FOREIGN_KEY_CHECKS = 1;
SET UNIQUE_CHECKS      = 1;

-- InnoDB no mantiene estadisticas exactas: las estima muestreando paginas del indice.
-- Sin este ANALYZE, el optimizador trabaja con las de la tabla vacia.
SELECT '>> analyze' AS paso;
ANALYZE TABLE clientes, productos, pedidos, pedido_lineas, pagos, eventos_pedido;

SELECT 'semilla-mysql.sql: carga terminada. Ahora corre verificar-mysql.sql.' AS resultado;
