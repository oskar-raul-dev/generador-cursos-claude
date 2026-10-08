-- ============================================================================
--  verificar.sql — los recuentos esperados (PostgreSQL)
--
--    psql -h 127.0.0.1 -U postgres -d tienda -f verificar.sql
--
--  Si una sola fila sale FALLA, la carga se repite. Un corpus con datos distintos
--  a los declarados en `prompts/dominio-entorno-y-datos-fijos.md` §3 es un corpus
--  con planes que nadie puede reproducir.
-- ============================================================================

\pset border 2
\pset title 'Verificacion del conjunto de datos'

WITH c(orden, comprobacion, esperado, real) AS (

  -- §3.2 Volumenes
  SELECT  1, 'clientes',                        50000::bigint, count(*) FROM clientes
  UNION ALL
  SELECT  2, 'productos',                        5000, count(*) FROM productos
  UNION ALL
  SELECT  3, 'pedidos',                       1000000, count(*) FROM pedidos
  UNION ALL
  SELECT  4, 'pedido_lineas',                 3500000, count(*) FROM pedido_lineas
  UNION ALL
  SELECT  5, 'pagos',                          820000, count(*) FROM pagos
  UNION ALL
  SELECT  6, 'eventos_pedido',                4100000, count(*) FROM eventos_pedido

  -- §3.1 Identificadores fijos
  UNION ALL
  SELECT  7, 'PED-00042 es el pedido de id 42',      1,
         count(*) FROM pedidos WHERE codigo = 'PED-00042' AND id = 42
  UNION ALL
  SELECT  8, 'PED-00042 tiene 3 lineas',             3,
         count(*) FROM pedido_lineas WHERE pedido_id = (SELECT id FROM pedidos WHERE codigo='PED-00042')
  UNION ALL
  SELECT  9, 'PED-00042 esta PAGADO',                1,
         count(*) FROM pedidos WHERE codigo = 'PED-00042' AND estado = 'PAGADO'
  UNION ALL
  SELECT 10, 'PED-99999 esta ANULADO',               1,
         count(*) FROM pedidos WHERE codigo = 'PED-99999' AND estado = 'ANULADO'
  UNION ALL
  SELECT 11, 'PED-99999 no tiene pagos',             0,
         count(*) FROM pagos WHERE pedido_id = (SELECT id FROM pedidos WHERE codigo='PED-99999')
  UNION ALL
  SELECT 12, 'CLI-00311 tiene 52 pedidos',          52,
         count(*) FROM pedidos WHERE cliente_id = (SELECT id FROM clientes WHERE codigo='CLI-00311')
  UNION ALL
  SELECT 13, 'CLI-00311 es de ES y alta en 2024',    1,
         count(*) FROM clientes WHERE codigo='CLI-00311' AND pais='ES'
                              AND creado_en >= '2024-01-01' AND creado_en < '2025-01-01'
  UNION ALL
  SELECT 14, 'CLI-00007 no tiene pedidos',           0,
         count(*) FROM pedidos WHERE cliente_id = (SELECT id FROM clientes WHERE codigo='CLI-00007')
  UNION ALL
  SELECT 15, 'PRD-00017 es de categoria audio',      1,
         count(*) FROM productos WHERE codigo='PRD-00017' AND categoria='audio'
  UNION ALL
  SELECT 16, 'PRD-00017 es el mas vendido (lineas)', 1,
         count(*) FROM (
           SELECT producto_id FROM pedido_lineas GROUP BY producto_id
           ORDER BY count(*) DESC LIMIT 1
         ) t WHERE t.producto_id = (SELECT id FROM productos WHERE codigo='PRD-00017')
  UNION ALL
  SELECT 17, 'PRD-00017 es el mas vendido (unidades)', 1,
         count(*) FROM (
           SELECT producto_id FROM pedido_lineas GROUP BY producto_id
           ORDER BY sum(cantidad) DESC LIMIT 1
         ) t WHERE t.producto_id = (SELECT id FROM productos WHERE codigo='PRD-00017')
  UNION ALL
  SELECT 18, 'PRD-04980 esta inactivo',              1,
         count(*) FROM productos WHERE codigo='PRD-04980' AND activo = false

  -- Coherencia interna
  UNION ALL
  SELECT 19, 'pedidos sin pago = PENDIENTE+ANULADO', 180000,
         count(*) FROM pedidos p WHERE NOT EXISTS (SELECT 1 FROM pagos g WHERE g.pedido_id=p.id)
  UNION ALL
  SELECT 20, 'pedidos con total desincronizado',     0,
         count(*) FROM pedidos p
         JOIN (SELECT pedido_id, sum(cantidad*precio_unit) s FROM pedido_lineas GROUP BY 1) t
           ON t.pedido_id = p.id
         WHERE p.total <> t.s
  UNION ALL
  SELECT 21, 'pagos en EFECTIVO sin referencia',     0,
         count(*) FROM pagos WHERE metodo='EFECTIVO' AND referencia IS NOT NULL
  UNION ALL
  SELECT 22, 'pedidos con actualizado_en no nulo',   0,
         count(*) FROM pedidos WHERE actualizado_en IS NOT NULL
)
SELECT
  lpad(orden::text, 2, '0')  AS "#",
  comprobacion               AS "Comprobacion",
  to_char(esperado, 'FM9G999G999') AS "Esperado",
  to_char(real,     'FM9G999G999') AS "Real",
  CASE WHEN real = esperado THEN 'OK' ELSE 'FALLA' END AS "Estado"
FROM c
ORDER BY orden;

\echo ''
\echo '--- Reparto por estado (informativo) ---'
SELECT estado, count(*) AS pedidos FROM pedidos GROUP BY estado ORDER BY 2 DESC;

\echo ''
\echo '--- Tamano en disco (informativo) ---'
SELECT relname AS tabla,
       pg_size_pretty(pg_total_relation_size(c.oid)) AS total,
       (SELECT reltuples::bigint FROM pg_class x WHERE x.oid = c.oid) AS filas_estimadas,
       relpages AS paginas
FROM pg_class c JOIN pg_namespace n ON n.oid = c.relnamespace
WHERE n.nspname = 'public' AND c.relkind = 'r'
ORDER BY pg_total_relation_size(c.oid) DESC;
