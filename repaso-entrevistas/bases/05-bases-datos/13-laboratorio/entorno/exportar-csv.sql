-- ============================================================================
--  exportar-csv.sql — vuelca las seis tablas de PostgreSQL a CSV
--
--    psql -h 127.0.0.1 -U postgres -d tienda -f exportar-csv.sql
--
--  POR QUE ASI, y no una semilla propia para MySQL.
--  MySQL no tiene `generate_series` ni `setseed`, asi que una semilla equivalente
--  produciria OTROS datos: otros clientes, otros importes, otras cardinalidades. Y
--  entonces el contraste de dialecto del capitulo 02/08 —"la misma consulta, los dos
--  motores"— compararia dos cosas distintas y no demostraria nada.
--  Exportando e importando, los tres motores tienen **exactamente las mismas filas**,
--  con los mismos `id`. Lo unico que cambia es el motor.
--
--  Los CSV son artefactos, no fuente: pesan ~1 GB y no se versionan (ver .gitignore).
--
--  Las conversiones de tipo que hay que hacer AQUI, y por que:
--    - `timestamptz` -> texto sin zona. PostgreSQL escribe `2023-05-01 12:00:00+00`
--      y el `TIMESTAMP` de MySQL no sabe leer ese sufijo. Se pasa a UTC y se formatea.
--    - `boolean` -> 0/1. PostgreSQL escribe `t` y `f`; el `TINYINT(1)` de MySQL
--      guardaria 0 en ambos casos y todos los productos quedarian inactivos.
--    - NULL -> `\N`. Con el CSV por defecto, un NULL sale como campo vacio, y en
--      `pagos.referencia` eso serian 273 000 cadenas vacias chocando contra su UNIQUE.
-- ============================================================================

\echo '>> exportando a datos/'

\copy (SELECT id, codigo, nombre, email, pais, to_char(creado_en AT TIME ZONE 'UTC','YYYY-MM-DD HH24:MI:SS.US') FROM clientes ORDER BY id) TO 'datos/clientes.csv' WITH (FORMAT csv, NULL '\N')

\copy (SELECT id, codigo, nombre, categoria, precio, activo::int FROM productos ORDER BY id) TO 'datos/productos.csv' WITH (FORMAT csv, NULL '\N')

\copy (SELECT id, codigo, cliente_id, estado, total, to_char(creado_en AT TIME ZONE 'UTC','YYYY-MM-DD HH24:MI:SS.US'), to_char(actualizado_en AT TIME ZONE 'UTC','YYYY-MM-DD HH24:MI:SS.US') FROM pedidos ORDER BY id) TO 'datos/pedidos.csv' WITH (FORMAT csv, NULL '\N')

\copy (SELECT pedido_id, linea, producto_id, cantidad, precio_unit FROM pedido_lineas ORDER BY pedido_id, linea) TO 'datos/pedido_lineas.csv' WITH (FORMAT csv, NULL '\N')

\copy (SELECT id, pedido_id, metodo, importe, to_char(pagado_en AT TIME ZONE 'UTC','YYYY-MM-DD HH24:MI:SS.US'), referencia FROM pagos ORDER BY id) TO 'datos/pagos.csv' WITH (FORMAT csv, NULL '\N')

\copy (SELECT id, pedido_id, tipo, carga::text, to_char(ocurrido_en AT TIME ZONE 'UTC','YYYY-MM-DD HH24:MI:SS.US') FROM eventos_pedido ORDER BY id) TO 'datos/eventos_pedido.csv' WITH (FORMAT csv, NULL '\N')

\echo 'exportar-csv.sql: seis ficheros en datos/.'
