-- ============================================================================
--  verificar-sqlite.sql
--    sqlite3 tienda.db < verificar-sqlite.sql
-- ============================================================================
.mode table
.headers on

SELECT printf('%02d', orden) AS "#", comprobacion AS "Comprobacion",
       esperado AS "Esperado", real_ AS "Real",
       CASE WHEN real_ = esperado THEN 'OK' ELSE 'FALLA' END AS "Estado"
FROM (
  SELECT 1 AS orden, 'clientes' AS comprobacion, 50000 AS esperado, count(*) AS real_ FROM clientes
  UNION ALL SELECT 2, 'productos', 5000, count(*) FROM productos
  UNION ALL SELECT 3, 'pedidos', 1000000, count(*) FROM pedidos
  UNION ALL SELECT 4, 'pedido_lineas', 3500000, count(*) FROM pedido_lineas
  UNION ALL SELECT 5, 'pagos', 820000, count(*) FROM pagos
  UNION ALL SELECT 6, 'eventos_pedido', 4100000, count(*) FROM eventos_pedido
  UNION ALL SELECT 7, 'PED-00042 es el pedido de id 42', 1,
    (SELECT count(*) FROM pedidos WHERE codigo='PED-00042' AND id=42)
  UNION ALL SELECT 8, 'PED-00042 tiene 3 lineas', 3,
    (SELECT count(*) FROM pedido_lineas WHERE pedido_id=42)
  UNION ALL SELECT 9, 'PED-00042 esta PAGADO', 1,
    (SELECT count(*) FROM pedidos WHERE codigo='PED-00042' AND estado='PAGADO')
  UNION ALL SELECT 10, 'PED-99999 esta ANULADO', 1,
    (SELECT count(*) FROM pedidos WHERE codigo='PED-99999' AND estado='ANULADO')
  UNION ALL SELECT 11, 'CLI-00311 tiene 52 pedidos', 52,
    (SELECT count(*) FROM pedidos WHERE cliente_id=(SELECT id FROM clientes WHERE codigo='CLI-00311'))
  UNION ALL SELECT 12, 'CLI-00007 no tiene pedidos', 0,
    (SELECT count(*) FROM pedidos WHERE cliente_id=(SELECT id FROM clientes WHERE codigo='CLI-00007'))
  UNION ALL SELECT 13, 'PRD-04980 esta inactivo', 1,
    (SELECT count(*) FROM productos WHERE codigo='PRD-04980' AND activo=0)
  UNION ALL SELECT 14, 'productos inactivos', 101, (SELECT count(*) FROM productos WHERE activo=0)
  UNION ALL SELECT 15, 'pagos con referencia nula', 273126,
    (SELECT count(*) FROM pagos WHERE referencia IS NULL)
  UNION ALL SELECT 16, 'ningun literal \N sin reparar', 0,
    (SELECT count(*) FROM pagos WHERE referencia = '\N')
  UNION ALL SELECT 17, 'el JSON se lee como JSON', 4100000,
    (SELECT count(*) FROM eventos_pedido WHERE json_valid(carga))
);

SELECT '' AS "";
SELECT 'El tipado por afinidad, a la vista:' AS "";
SELECT typeof(id) AS id, typeof(codigo) AS codigo, typeof(total) AS total,
       typeof(creado_en) AS creado_en
FROM pedidos WHERE codigo = 'PED-00042';
