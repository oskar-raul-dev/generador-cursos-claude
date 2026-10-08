-- ============================================================================
--  semilla.sql — la carga determinista (PostgreSQL)
--
--  Dueno de las cifras: `prompts/dominio-entorno-y-datos-fijos.md` §3.
--
--    psql -h 127.0.0.1 -U postgres -d tienda -f semilla.sql
--
--  DETERMINISMO. Misma semilla, mismos datos, mismos planes. Se consigue con tres
--  cosas, y las tres son obligatorias:
--    1. `setseed(0.42)` antes de cualquier `random()`, en la MISMA sesion.
--    2. Paralelismo apagado durante la carga: un plan paralelo reparte las filas
--       entre procesos y el orden de las llamadas a `random()` deja de ser fijo.
--    3. `ORDER BY g` en los INSERT que dependen de que `id` siga a la serie, para
--       que PED-00042 sea de verdad el pedido de id 42.
--
--  Lo que ESTO fija y lo que NO:
--    fija   -> las filas, los recuentos, las cardinalidades y, con ellas, los `cost`
--              y los `rows` de EXPLAIN.
--    no fija -> los milisegundos de `actual time`. Dependen de la maquina, del disco
--              y del estado de la cache. Un tiempo que no reproduces no es un error.
-- ============================================================================

SELECT setseed(0.42);

SET max_parallel_workers_per_gather = 0;   -- ver punto 2 de la cabecera
SET synchronous_commit = off;              -- solo durante la carga: la acelera mucho

\timing on

-- ---------------------------------------------------------------------------
--  1. clientes — 50 000
-- ---------------------------------------------------------------------------
\echo '>> clientes'
INSERT INTO clientes (codigo, nombre, email, pais, creado_en)
SELECT
  'CLI-' || lpad(g::text, 5, '0'),
  'Cliente ' || g,
  'cliente' || g || '@ejemplo.test',
  (ARRAY['ES','MX','CO','AR','CL','PE','US','FR'])[1 + (random() * 7)::int],
  timestamptz '2023-01-01' + (random() * 1000) * interval '1 day'
FROM generate_series(1, 50000) AS g
ORDER BY g;

-- ---------------------------------------------------------------------------
--  2. productos — 5 000
--     `activo` falso en uno de cada 50: el filtro que nadie recuerda poner.
--     El precio nunca es 0, para que ningun pedido acabe con total 0 y el CHECK
--     de `pagos.importe > 0` se pueda cumplir siempre.
-- ---------------------------------------------------------------------------
\echo '>> productos'
INSERT INTO productos (codigo, nombre, categoria, precio, activo)
SELECT
  'PRD-' || lpad(g::text, 5, '0'),
  'Producto ' || g,
  (ARRAY['audio','video','informatica','hogar','libros','juguetes','deporte'])
    [1 + (random() * 6)::int],
  round((1 + random() * 998.99)::numeric, 2),
  (g % 50) <> 0
FROM generate_series(1, 5000) AS g
ORDER BY g;

-- ---------------------------------------------------------------------------
--  3. pedidos — 1 000 000
--     El estado NO se sortea: se reparte por cupo exacto sobre una mezcla
--     determinista (`row_number() OVER (ORDER BY md5(g))`). Asi los recuentos
--     por estado cuadran al ultimo pedido y, a la vez, el estado no queda
--     correlacionado con el `id` —que falsearia los ejemplos de BRIN y de
--     correlacion fisica del bloque 03—.
--
--       PENDIENTE  120 000        ANULADO     60 000   -> sin pago
--       PAGADO     250 000        ENVIADO    270 000   -> con pago
--       ENTREGADO  300 000                             -> 820 000 pagos
-- ---------------------------------------------------------------------------
\echo '>> pedidos'
INSERT INTO pedidos (codigo, cliente_id, estado, total, creado_en)
SELECT
  -- OJO con lpad: TRUNCA cuando el texto ya es mas largo que el ancho pedido.
  -- `lpad('100000', 5, '0')` devuelve '10000', no '100000'. Con un millon de pedidos
  -- eso colisiona contra el UNIQUE de `codigo` en la fila 100 000. El ancho minimo de
  -- cinco se conserva porque los identificadores canonicos del corpus —PED-00042,
  -- PED-99999— tienen cinco digitos; a partir de ahi el codigo crece de ancho.
  'PED-' || CASE WHEN s.g < 100000 THEN lpad(s.g::text, 5, '0') ELSE s.g::text END,
  1 + (random() * 49999)::int,            -- reparto no uniforme: hay clientes con muchos pedidos
  CASE
    WHEN s.n <= 120000 THEN 'PENDIENTE'
    WHEN s.n <= 180000 THEN 'ANULADO'
    WHEN s.n <= 430000 THEN 'PAGADO'
    WHEN s.n <= 700000 THEN 'ENVIADO'
    ELSE                    'ENTREGADO'
  END,
  0,                                      -- el total se calcula despues, desde las lineas
  timestamptz '2023-01-01' + (random() * 1000) * interval '1 day'
FROM (
  SELECT g, row_number() OVER (ORDER BY md5(g::text)) AS n
  FROM generate_series(1, 1000000) AS g
) AS s
ORDER BY s.g;

-- ---------------------------------------------------------------------------
--  4. pedido_lineas — 3 500 000 exactas
--     El numero de lineas de cada pedido sale de un ciclo de ocho cuya suma es 28:
--     28 / 8 = 3,5 lineas por pedido, y 1 000 000 / 8 = 125 000 ciclos enteros.
--     PED-00042 (id 42, 42 % 8 = 2) cae en el tercer hueco del ciclo -> 3 lineas.
--
--     El producto se sortea con sesgo: una de cada cinco lineas va a alguno de los
--     cincuenta primeros. Sin sesgo, todos los productos tendrian la misma
--     selectividad y el bloque 03 no podria ensenar por que el planificador elige
--     indice para un valor y barrido secuencial para otro.
-- ---------------------------------------------------------------------------
\echo '>> pedido_lineas'
INSERT INTO pedido_lineas (pedido_id, linea, producto_id, cantidad, precio_unit)
SELECT s.pedido_id, s.linea, s.producto_id, s.cantidad, pr.precio
FROM (
  SELECT
    p.id AS pedido_id,
    l.linea::smallint AS linea,
    CASE WHEN random() < 0.2
         THEN 1 + (random() * 49)::int
         ELSE 1 + (random() * 4999)::int
    END AS producto_id,
    1 + (random() * 4)::int AS cantidad
  FROM pedidos p
  CROSS JOIN LATERAL generate_series(
    1, (ARRAY[1,2,3,3,4,4,5,6])[1 + (p.id % 8)]
  ) AS l(linea)
) AS s
JOIN productos pr ON pr.id = s.producto_id;

-- ---------------------------------------------------------------------------
--  5. El total desnormalizado de `pedidos`
--     Existe a proposito: es el caso de desnormalizacion deliberada del corpus,
--     y el que permite ensenar como se desincroniza.
-- ---------------------------------------------------------------------------
\echo '>> pedidos.total'
UPDATE pedidos p
SET total = t.suma
FROM (
  SELECT pedido_id, sum(cantidad * precio_unit) AS suma
  FROM pedido_lineas GROUP BY pedido_id
) AS t
WHERE t.pedido_id = p.id;

-- ---------------------------------------------------------------------------
--  6. Ajustes deterministas: los identificadores fijos de §3.1
--     Se fuerzan despues de la carga, no durante. Forzarlos dentro del sorteo
--     obligaria a doblar cada INSERT con un caso especial; hacerlo aqui deja los
--     seis hechos declarados en un solo sitio y verificables uno a uno.
-- ---------------------------------------------------------------------------
\echo '>> ajustes deterministas'

-- CLI-00311: Espana, alta en 2024.
UPDATE clientes SET pais = 'ES', creado_en = timestamptz '2024-03-11 09:20:00+00'
WHERE codigo = 'CLI-00311';

-- PRD-00017: categoria audio.  PRD-04980: inactivo.
UPDATE productos SET categoria = 'audio' WHERE codigo = 'PRD-00017';
UPDATE productos SET activo = false     WHERE codigo = 'PRD-04980';

-- CLI-00311 con exactamente 52 pedidos y CLI-00007 sin ninguno.
-- Primero se vacian los dos, volcando lo suyo sobre CLI-00001.
UPDATE pedidos SET cliente_id = (SELECT id FROM clientes WHERE codigo = 'CLI-00001')
WHERE cliente_id IN (SELECT id FROM clientes WHERE codigo IN ('CLI-00311','CLI-00007'));

-- Y despues se le asignan a CLI-00311 cincuenta y dos pedidos elegidos de forma
-- determinista: los 52 primeros por md5 del codigo, saltandose los dos canonicos.
UPDATE pedidos
SET cliente_id = (SELECT id FROM clientes WHERE codigo = 'CLI-00311')
WHERE id IN (
  SELECT id FROM pedidos
  WHERE codigo NOT IN ('PED-00042','PED-99999')
  ORDER BY md5(codigo)
  LIMIT 52
);

-- PED-00042 tiene que quedar PAGADO y PED-99999 ANULADO. Se hace INTERCAMBIANDO
-- el estado con otro pedido que ya lo tenga, no asignandolo: asi los cupos por
-- estado de §3 siguen cuadrando al ultimo pedido.
WITH origen AS (SELECT id, estado FROM pedidos WHERE codigo = 'PED-00042'),
     destino AS (SELECT id FROM pedidos
                 WHERE estado = 'PAGADO' AND codigo NOT IN ('PED-00042','PED-99999')
                 ORDER BY id LIMIT 1)
UPDATE pedidos p
SET estado = CASE WHEN p.id = (SELECT id FROM origen)
                  THEN 'PAGADO'
                  ELSE (SELECT estado FROM origen) END
WHERE p.id IN ((SELECT id FROM origen), (SELECT id FROM destino));

WITH origen AS (SELECT id, estado FROM pedidos WHERE codigo = 'PED-99999'),
     destino AS (SELECT id FROM pedidos
                 WHERE estado = 'ANULADO' AND codigo NOT IN ('PED-00042','PED-99999')
                 ORDER BY id LIMIT 1)
UPDATE pedidos p
SET estado = CASE WHEN p.id = (SELECT id FROM origen)
                  THEN 'ANULADO'
                  ELSE (SELECT estado FROM origen) END
WHERE p.id IN ((SELECT id FROM origen), (SELECT id FROM destino));

-- PRD-00017 tiene que ser el mas vendido. Se le reasignan lineas de otros
-- productos hasta superar al lider actual con margen de 5 000.
-- El filtro por modulo y el ORDER BY por la clave primaria hacen que la eleccion
-- sea determinista sin ordenar los 3,5 millones de lineas.
WITH objetivo AS (SELECT id FROM productos WHERE codigo = 'PRD-00017'),
     conteo   AS (SELECT producto_id, count(*) AS n FROM pedido_lineas GROUP BY producto_id),
     falta    AS (
       SELECT (SELECT max(n) FROM conteo)
            - coalesce((SELECT n FROM conteo WHERE producto_id = (SELECT id FROM objetivo)), 0)
            + 5000 AS n
     ),
     victimas AS (
       SELECT pedido_id, linea FROM pedido_lineas
       WHERE producto_id <> (SELECT id FROM objetivo)
         AND (pedido_id % 89) = 7
       ORDER BY pedido_id, linea
       LIMIT (SELECT greatest(n, 0) FROM falta)
     )
UPDATE pedido_lineas pl
SET producto_id = (SELECT id FROM objetivo)
FROM victimas v
WHERE pl.pedido_id = v.pedido_id AND pl.linea = v.linea;

-- El total se recalcula por si algun ajuste lo movio. Normalmente no mueve nada:
-- reasignar `producto_id` no toca `precio_unit`, que es el precio congelado en el
-- momento de la compra y por eso puede diferir del precio actual del producto.
UPDATE pedidos p
SET total = t.suma
FROM (
  SELECT pedido_id, sum(cantidad * precio_unit) AS suma
  FROM pedido_lineas GROUP BY pedido_id
) AS t
WHERE t.pedido_id = p.id AND p.total <> t.suma;

-- ---------------------------------------------------------------------------
--  7. pagos — 820 000
--     Uno por cada pedido que llego a cobrarse. Los PENDIENTE y los ANULADO no
--     tienen: de ahi sale el caso del anti-join, con PED-99999 de ejemplo.
--     `referencia` es nula en efectivo: el nulo con significado del dominio.
-- ---------------------------------------------------------------------------
\echo '>> pagos'
INSERT INTO pagos (pedido_id, metodo, importe, pagado_en, referencia)
SELECT
  p.id,
  m.metodo,
  p.total,
  p.creado_en + (1 + (random() * 72)::int) * interval '1 hour',
  CASE WHEN m.metodo = 'EFECTIVO' THEN NULL
       ELSE 'REF-' || lpad(p.id::text, 9, '0') END
FROM pedidos p
CROSS JOIN LATERAL (
  SELECT (ARRAY['TARJETA','TRANSFERENCIA','EFECTIVO'])[1 + (p.id % 3)] AS metodo
) AS m
WHERE p.estado IN ('PAGADO','ENVIADO','ENTREGADO')
ORDER BY p.id;

-- ---------------------------------------------------------------------------
--  8. eventos_pedido — 4 100 000 exactos
--     Ciclo de diez cuya suma es 41: 4,1 eventos por pedido.
--     Es la tabla de alta cardinalidad y con JSON dentro de relacional; el bloque
--     09 la usa de contraste contra una serie temporal de verdad.
-- ---------------------------------------------------------------------------
\echo '>> eventos_pedido'
INSERT INTO eventos_pedido (pedido_id, tipo, carga, ocurrido_en)
SELECT
  p.id,
  t.tipo,
  jsonb_build_object(
    'origen',  (ARRAY['web','movil','callcenter'])[1 + (p.id % 3)],
    'version', 1 + (e.n % 3),
    'estado',  p.estado,
    'importe', p.total
  ),
  p.creado_en + e.n * interval '37 minutes'
FROM pedidos p
CROSS JOIN LATERAL generate_series(
  1, (ARRAY[2,3,3,4,4,4,5,5,5,6])[1 + (p.id % 10)]
) AS e(n)
CROSS JOIN LATERAL (
  SELECT (ARRAY['CREADO','VALIDADO','PAGADO','PREPARADO','ENVIADO','ENTREGADO'])
           [1 + ((p.id + e.n) % 6)] AS tipo
) AS t
ORDER BY p.id, e.n;

-- ---------------------------------------------------------------------------
--  9. Cierre: heap limpio y estadisticas frescas
--     VACUUM FULL, no VACUUM a secas. Los UPDATE de los pasos 5 y 6 dejaron una
--     version muerta por cada fila tocada, y un heap hinchado cambia el numero de
--     paginas que lee un `Seq Scan` —es decir, cambia todos los planes del corpus.
-- ---------------------------------------------------------------------------
RESET synchronous_commit;

\echo '>> vacuum full + analyze'
VACUUM (FULL, ANALYZE) clientes;
VACUUM (FULL, ANALYZE) productos;
VACUUM (FULL, ANALYZE) pedidos;
VACUUM (FULL, ANALYZE) pedido_lineas;
VACUUM (FULL, ANALYZE) pagos;
VACUUM (FULL, ANALYZE) eventos_pedido;

RESET max_parallel_workers_per_gather;

\echo 'semilla.sql: carga terminada. Ahora corre verificar.sql.'
