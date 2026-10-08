-- ============================================================================
--  verificar-mysql.sql — las mismas comprobaciones, contra MySQL / MariaDB
--
--    docker exec -i bd-lab-mysql mysql -uroot -proot tienda < verificar-mysql.sql
--    docker exec -i bd-lab-maria mariadb -uroot -proot tienda < verificar-mysql.sql
--
--  Son las 22 de `verificar.sql` mas cuatro propias de la importacion (23 a 26):
--  las conversiones de tipo que el CSV pudo estropear en silencio —el booleano que
--  se vuelve 0, la marca de tiempo que se desplaza de zona, el JSON que llega como
--  texto plano, el NULL que se convierte en cadena vacia—.
-- ============================================================================

SET SESSION time_zone = '+00:00';

SELECT
  LPAD(orden, 2, '0') AS '#',
  comprobacion        AS 'Comprobacion',
  FORMAT(esperado, 0) AS 'Esperado',
  FORMAT(real_, 0)    AS 'Real',
  IF(real_ = esperado, 'OK', 'FALLA') AS 'Estado'
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
  UNION ALL SELECT 11, 'PED-99999 no tiene pagos', 0,
    (SELECT count(*) FROM pagos WHERE pedido_id=(SELECT id FROM pedidos WHERE codigo='PED-99999'))
  UNION ALL SELECT 12, 'CLI-00311 tiene 52 pedidos', 52,
    (SELECT count(*) FROM pedidos WHERE cliente_id=(SELECT id FROM clientes WHERE codigo='CLI-00311'))
  UNION ALL SELECT 13, 'CLI-00311 es de ES y alta en 2024', 1,
    (SELECT count(*) FROM clientes WHERE codigo='CLI-00311' AND pais='ES' AND YEAR(creado_en)=2024)
  UNION ALL SELECT 14, 'CLI-00007 no tiene pedidos', 0,
    (SELECT count(*) FROM pedidos WHERE cliente_id=(SELECT id FROM clientes WHERE codigo='CLI-00007'))
  UNION ALL SELECT 15, 'PRD-00017 es de categoria audio', 1,
    (SELECT count(*) FROM productos WHERE codigo='PRD-00017' AND categoria='audio')
  UNION ALL SELECT 16, 'PRD-00017 es el mas vendido (lineas)', 1,
    (SELECT count(*) FROM (SELECT producto_id FROM pedido_lineas GROUP BY producto_id
                           ORDER BY count(*) DESC LIMIT 1) t
     WHERE t.producto_id=(SELECT id FROM productos WHERE codigo='PRD-00017'))
  UNION ALL SELECT 17, 'PRD-00017 es el mas vendido (unidades)', 1,
    (SELECT count(*) FROM (SELECT producto_id FROM pedido_lineas GROUP BY producto_id
                           ORDER BY sum(cantidad) DESC LIMIT 1) t
     WHERE t.producto_id=(SELECT id FROM productos WHERE codigo='PRD-00017'))
  UNION ALL SELECT 18, 'PRD-04980 esta inactivo', 1,
    (SELECT count(*) FROM productos WHERE codigo='PRD-04980' AND activo=0)

  UNION ALL SELECT 19, 'pedidos sin pago = PENDIENTE+ANULADO', 180000,
    (SELECT count(*) FROM pedidos p WHERE NOT EXISTS (SELECT 1 FROM pagos g WHERE g.pedido_id=p.id))
  UNION ALL SELECT 20, 'pedidos con total desincronizado', 0,
    (SELECT count(*) FROM pedidos p
     JOIN (SELECT pedido_id, sum(cantidad*precio_unit) s FROM pedido_lineas GROUP BY pedido_id) t
       ON t.pedido_id=p.id WHERE p.total <> t.s)
  UNION ALL SELECT 21, 'pagos en EFECTIVO sin referencia', 0,
    (SELECT count(*) FROM pagos WHERE metodo='EFECTIVO' AND referencia IS NOT NULL)
  UNION ALL SELECT 22, 'pedidos con actualizado_en no nulo', 0,
    (SELECT count(*) FROM pedidos WHERE actualizado_en IS NOT NULL)

  -- Propias de la importacion desde CSV
  UNION ALL SELECT 23, 'productos inactivos (booleano convertido)', 101,
    (SELECT count(*) FROM productos WHERE activo=0)
  UNION ALL SELECT 24, 'pagos con referencia nula (NULL, no cadena vacia)', 273126,
    (SELECT count(*) FROM pagos WHERE referencia IS NULL)
  UNION ALL SELECT 25, 'ningun pago con referencia vacia', 0,
    (SELECT count(*) FROM pagos WHERE referencia = '')
  UNION ALL SELECT 26, 'el JSON llego como JSON, no como texto', 4100000,
    (SELECT count(*) FROM eventos_pedido WHERE JSON_VALID(carga))
) AS c
ORDER BY orden;

SELECT '--- Reparto por estado ---' AS '';
SELECT estado, count(*) AS pedidos FROM pedidos GROUP BY estado ORDER BY 2 DESC;

SELECT '--- Rango de fechas (tiene que coincidir con PostgreSQL) ---' AS '';
SELECT min(creado_en) AS primera, max(creado_en) AS ultima FROM pedidos;
