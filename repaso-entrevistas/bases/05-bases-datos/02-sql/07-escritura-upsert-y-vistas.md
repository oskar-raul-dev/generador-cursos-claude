# 07 — Escritura, upsert y vistas

> Qué cuesta la deduplicación que `UNION` hace sin pedirte permiso, por qué `ON CONFLICT` necesita
> un índice único debajo, en qué no equivale a `MERGE`, y qué guarda de verdad una vista. **Asume
> leído:** [`05`](05-cte-y-recursion.md) — de ahí vienen `WITH`, el `UNION` del término recursivo y
> la costumbre de leer un plan entero antes de opinar. **Vigencia:** 20 de septiembre de 2026.

---

## Salto rápido

- [1. El problema](#1--el-problema)
- [2. `UNION` y `UNION ALL`](#2--union-y-union-all-la-deduplicación-que-nadie-pidió)
- [3. `INTERSECT` y `EXCEPT`](#3--intersect-y-except-y-qué-motor-los-tiene-de-verdad)
- [4. `INSERT … ON CONFLICT`](#4--insert--on-conflict-el-upsert-se-apoya-en-un-índice)
- [5. `MERGE` y sus sustitutos](#5--merge-más-general-y-no-equivalente)
- [6. Vistas y vistas materializadas](#6--una-vista-no-guarda-filas-guarda-la-consulta)
- [7. Estándar, motor y convención](#7--estándar-motor-y-convención)

---

## 1. 🎯 El problema

El proveedor reenvía su lote de la noche: 820 000 referencias de las que casi todas ya están en
`pagos`, y el trabajo tiene que poder correrse dos veces sin duplicar nada. El código que sale
primero es siempre el mismo —mira si existe, y si no existe, inserta—, y funciona en la máquina de
quien lo escribió, donde solo hay un hilo. Con dos sesiones abiertas el hueco se mide: A consulta
`clientes` por `codigo`, recibe cero filas y lanza su `INSERT`, que **se queda 4012,798 ms parado**
—medido— porque B tenía la misma clave a medio escribir en el índice único `clientes_codigo_key`, y
nadie puede leer esa entrada hasta que B confirme o deshaga. Si B hubiera confirmado, A se habría
llevado `ERROR: duplicate key value violates unique constraint "clientes_codigo_key"`. **Entre leer
y escribir cabe otra transacción**, así que el `SELECT` previo no protege de nada.

---

## 2. 🧱 `UNION` y `UNION ALL`: la deduplicación que nadie pidió

Un **operador de conjunto** apila el resultado de dos consultas con el mismo número de columnas y
tipos compatibles. `UNION ALL` las apila y ya; `UNION`, sin `ALL`, **elimina las repetidas**, y esa
palabra que no escribes cuesta dinero:

```text
tienda=# EXPLAIN (ANALYZE, COSTS, BUFFERS)
tienda-# SELECT cliente_id FROM pedidos WHERE estado='PAGADO'
tienda-# UNION ALL
tienda-# SELECT cliente_id FROM pedidos WHERE estado='ENVIADO';
                                                            QUERY PLAN
-----------------------------------------------------------------------------------------------------------------------------------
 Append  (cost=0.00..49157.17 rows=523433 width=8) (actual time=0.017..174.109 rows=520000.00 loops=1)
   Buffers: shared hit=21540
   ->  Seq Scan on pedidos  (cost=0.00..23270.00 rows=251400 width=8) (actual time=0.017..68.849 rows=250000.00 loops=1)
         Filter: (estado = 'PAGADO'::text)
         Rows Removed by Filter: 750000
         Buffers: shared hit=10770
   ->  Seq Scan on pedidos pedidos_1  (cost=0.00..23270.00 rows=272033 width=8) (actual time=0.035..62.649 rows=270000.00 loops=1)
         Filter: (estado = 'ENVIADO'::text)
         Rows Removed by Filter: 730000
         Buffers: shared hit=10770
 Planning:
   Buffers: shared hit=80
 Planning Time: 0.197 ms
 Execution Time: 189.145 ms
(14 filas)

Duración: 190,539 ms
```

La misma consulta quitando `ALL`:

```text
tienda=# EXPLAIN (ANALYZE, COSTS, BUFFERS)
tienda-# SELECT cliente_id FROM pedidos WHERE estado='PAGADO'
tienda-# UNION
tienda-# SELECT cliente_id FROM pedidos WHERE estado='ENVIADO';
                                                               QUERY PLAN
-----------------------------------------------------------------------------------------------------------------------------------------
 HashAggregate  (cost=65432.66..74756.31 rows=523433 width=8) (actual time=267.865..271.769 rows=49993.00 loops=1)
   Group Key: pedidos.cliente_id
   Planned Partitions: 4  Batches: 1  Memory Usage: 5657kB
   Buffers: shared hit=21540
   ->  Append  (cost=0.00..49157.17 rows=523433 width=8) (actual time=0.025..172.215 rows=520000.00 loops=1)
         Buffers: shared hit=21540
         ->  Seq Scan on pedidos  (cost=0.00..23270.00 rows=251400 width=8) (actual time=0.024..70.234 rows=250000.00 loops=1)
               Filter: (estado = 'PAGADO'::text)
               Rows Removed by Filter: 750000
               Buffers: shared hit=10770
         ->  Seq Scan on pedidos pedidos_1  (cost=0.00..23270.00 rows=272033 width=8) (actual time=0.020..63.169 rows=270000.00 loops=1)
               Filter: (estado = 'ENVIADO'::text)
               Rows Removed by Filter: 730000
               Buffers: shared hit=10770
 Planning:
   Buffers: shared hit=99
 Planning Time: 0.216 ms
 Execution Time: 274.114 ms
(18 filas)

Duración: 275,368 ms
```

- **El `Append` de abajo es idéntico**, hasta en las páginas: `shared hit=21540` en los dos. Encima
  aparece un `HashAggregate` con `Group Key: pedidos.cliente_id`: eso es la deduplicación.
- **Cuánto cuesta:** 274,114 ms contra 189,145 ms —**un 45 % más**— y **5 657 kB** de memoria para
  la tabla hash, que fuera de `work_mem` serían ficheros temporales. **Cuándo sí:** cuando las ramas
  se solapan —520 000 filas se quedan en 49 993—. **Cuándo no:** cuando son disjuntas por
  construcción, porque el hash se paga igual sin un duplicado que quitar.

> **Veredicto:** `UNION` es `UNION ALL` más un `DISTINCT` que cuesta un hash. Escribe `ALL` salvo
> que puedas decir qué duplicado quitas.

---

## 3. 🧱 `INTERSECT` y `EXCEPT`, y qué motor los tiene de verdad

`INTERSECT` devuelve las filas que están en las dos consultas; `EXCEPT`, las de la primera que no
están en la segunda. Los dos **deduplican por defecto** y admiten `ALL` para no hacerlo:

```text
tienda=# WITH compras AS (
tienda(#   SELECT p.estado, pr.categoria
tienda(#     FROM clientes c JOIN pedidos p ON p.cliente_id = c.id
tienda(#     JOIN pedido_lineas pl ON pl.pedido_id = p.id JOIN productos pr ON pr.id = pl.producto_id
tienda(#    WHERE c.codigo = 'CLI-00311'
tienda(# )
tienda-# SELECT categoria FROM compras WHERE estado = 'ANULADO'
tienda-# INTERSECT
tienda-# SELECT categoria FROM compras WHERE estado = 'ENTREGADO';
  categoria
-------------
 video
 deporte
 informatica
 juguetes
 hogar
 libros
(6 filas)

Duración: 163,764 ms
```

Seis de las siete categorías: falta `audio`, comprada en un lado y no en el otro. Y `EXCEPT` es el
anti-join escrito como conjunto —los pedidos sin ningún pago—:

```text
tienda=# SELECT count(*) FROM (SELECT id FROM pedidos EXCEPT SELECT pedido_id FROM pagos) t;
 count
--------
 180000
(1 fila)

Duración: 767,933 ms
```

- Los 180 000 son los `PENDIENTE` más los `ANULADO` del dominio. **Cuánto cuesta:** 767,933 ms
  contra 635,727 ms de `EXCEPT ALL`, que se ahorra deduplicar un conjunto donde `id` ya es único.
  **Cuándo no:** en una consulta caliente, donde `NOT EXISTS` le deja al planificador elegir un
  anti-join en vez de resolver los dos lados enteros.

Y esto es lo que más se falla en entrevista, con las mismas consultas en los otros tres motores:

- **MySQL 9.7.2 tiene `INTERSECT` y `EXCEPT`, y no tiene `MINUS`.** Llegaron en **8.0.31**, de
  octubre de 2022: *"MySQL solo tiene `UNION`"* describe un motor anterior a esa fecha.
- **MariaDB 12.3.3 tiene los tres**, con una condición medida: `MINUS` solo se reconoce con
  `sql_mode='ORACLE'`; por defecto da el mismo `ERROR 1064`.
- **SQLite 3.53.4 usa `EXCEPT`** —`MINUS` le da `Parse error`— y **no acepta `INTERSECT ALL` ni
  `EXCEPT ALL`**. `MINUS` es de Oracle; nunca fue el nombre portable.

---

## 4. 🧱 `INSERT … ON CONFLICT`: el upsert se apoya en un índice

El *upsert* (inserción que se vuelve actualización cuando la fila ya está) de PostgreSQL es una
cláusula del `INSERT`: `DO NOTHING` se traga el choque y `DO UPDATE` actualiza la fila existente.
**Todo lo que sigue va dentro de `BEGIN` … `ROLLBACK`**: el laboratorio se comparte.

```text
tienda=# BEGIN;
BEGIN
tienda=*# INSERT INTO clientes (codigo, nombre, email, pais)
tienda-*# VALUES ('CLI-00311','Cliente 311 corregido','cliente311@ejemplo.test','PT')
tienda-*# ON CONFLICT DO NOTHING RETURNING id, codigo, pais;
 id | codigo | pais
----+--------+------
(0 filas)

INSERT 0 0
tienda=*# INSERT INTO clientes (codigo, nombre, email, pais)
tienda-*# VALUES ('CLI-00311','Cliente 311 corregido','cliente311@ejemplo.test','PT')
tienda-*# ON CONFLICT (codigo) DO UPDATE SET nombre = EXCLUDED.nombre, pais = EXCLUDED.pais
tienda-*# RETURNING id, codigo, nombre, pais, (xmax <> 0) AS fue_update;
 id  |  codigo   |        nombre         | pais | fue_update
-----+-----------+-----------------------+------+------------
 311 | CLI-00311 | Cliente 311 corregido | PT   | t
(1 fila)

INSERT 0 1
```

- **`RETURNING` hace diagnosticable el upsert** y ahorra el viaje de vuelta: sin él, `INSERT 0 1` no
  distingue insertar de actualizar. **Cuánto cuesta:** cero consultas y cero latencia extra.
- **`EXCLUDED` es la fila que *no* entró**: la pseudotabla con los valores que proponía el `INSERT`.
  `SET total = clientes.total + EXCLUDED.total` acumularía, que es el patrón de los contadores.
- **`(xmax <> 0)` dice qué pasó de verdad**: en una fila recién insertada `xmax` vale 0 y devuelve
  `f`; aquí devolvió `t` porque actualizó. Es del MVCC de PostgreSQL, no del estándar.
- **`DO NOTHING` sin columnas vale para cualquier restricción única; `DO UPDATE` exige decir cuál**,
  porque tiene que saber con qué fila fusionar, y `clientes` tiene dos candidatas.

Y lo que casi nadie sabe explicar: **el conflicto se detecta contra un índice, no contra una
columna**. Sin índice único ni restricción de exclusión, el motor se planta antes de mirar una fila:

```text
tienda=*# INSERT INTO clientes (codigo, nombre, email, pais)
tienda-*# VALUES ('CLI-90002','Cliente 311','cliente90002@ejemplo.test','MX')
tienda-*# ON CONFLICT (nombre) DO UPDATE SET pais = EXCLUDED.pais;
ERROR:  there is no unique or exclusion constraint matching the ON CONFLICT specification
tienda=*# ROLLBACK;
ROLLBACK
```

- **El error es de planificación**, no de datos: el upsert es una **decisión de esquema**, y sin
  `UNIQUE` sobre la clave de negocio por la que quieres ser idempotente, no existe.
- La trampa gemela es `pagos.referencia`, `UNIQUE` **pero con nulos**: los 273 126 pagos en efectivo
  la tienen a `NULL`, y como dos nulos nunca son iguales, ahí el upsert **inserta siempre**.

> **Veredicto:** `ON CONFLICT` no compara valores, consulta un índice único. Sin ese índice no hay
> upsert; con uno que admite nulos hay upsert solo para las filas que no son nulas.

---

## 5. 🧱 `MERGE`: más general, y no equivalente

`MERGE` es la sentencia del estándar para lo mismo y para más: recorre una fuente, la empareja con
un destino por una condición cualquiera y ejecuta una rama distinta según el caso. **Llegó a
PostgreSQL en la 15** y en la 17 aprendió `RETURNING` con `merge_action()`:

```text
tienda=*# MERGE INTO pagos p
tienda-*# USING (VALUES ('REF-000000001', 7000.00), ('REF-000000003', 0.00),
tienda-*#               ('REF-900000001', 125.50)) AS entrante (referencia, importe)
tienda-*#    ON p.referencia = entrante.referencia
tienda-*#  WHEN MATCHED AND entrante.importe = 0 THEN DELETE
tienda-*#  WHEN MATCHED THEN UPDATE SET importe = entrante.importe
tienda-*#  WHEN NOT MATCHED THEN INSERT (pedido_id, metodo, importe, pagado_en, referencia)
tienda-*#       VALUES (42, 'TARJETA', entrante.importe, now(), entrante.referencia)
tienda-*# RETURNING merge_action() AS accion, p.id, p.referencia, p.importe;
 accion |   id   |  referencia   | importe
--------+--------+---------------+---------
 UPDATE |      1 | REF-000000001 | 7000.00
 DELETE |      3 | REF-000000003 | 6354.55
 INSERT | 820009 | REF-900000001 |  125.50
(3 filas)

MERGE 3
Duración: 2,648 ms
```

- **Tres acciones en una sentencia**, y `merge_action()` dice cuál le tocó a cada fila; en la
  borrada, `importe` muestra el valor de **antes**. **Gana la primera rama cuyo predicado se
  cumple**: con el `DELETE` en segundo lugar, el cero se habría guardado como actualización.
- **Lo que `ON CONFLICT` no puede hacer:** borrar, emparejar por algo que no sea un índice único, y
  tratar distinto dos casos que chocan con la misma clave.

Y lo que `MERGE` **no** hace: **no es atómicamente equivalente a `ON CONFLICT` frente a
concurrencia**. `ON CONFLICT` reintenta contra el índice dentro de la misma sentencia; `MERGE`
clasifica cada fila con la instantánea del principio y **no vuelve a mirar**. Se reproduce sin
concurrencia, repitiendo la clave en la fuente:

```text
tienda=*# MERGE INTO pagos p
tienda-*# USING (VALUES ('REF-900000002', 10.00), ('REF-900000002', 20.00))
tienda-*#       AS entrante (referencia, importe)
tienda-*#    ON p.referencia = entrante.referencia
tienda-*#  WHEN MATCHED THEN UPDATE SET importe = entrante.importe
tienda-*#  WHEN NOT MATCHED THEN INSERT (pedido_id, metodo, importe, pagado_en, referencia)
tienda-*#       VALUES (42, 'TARJETA', entrante.importe, now(), entrante.referencia);
ERROR:  duplicate key value violates unique constraint "pagos_referencia_key"
DETALLE:  Key (referencia)=(REF-900000002) already exists.
tienda=*# INSERT INTO pagos (pedido_id, metodo, importe, pagado_en, referencia)
tienda-*# VALUES (42,'TARJETA',10.00,now(),'REF-900000002'),
tienda-*#        (42,'TARJETA',20.00,now(),'REF-900000002')
tienda-*# ON CONFLICT (referencia) DO UPDATE SET importe = EXCLUDED.importe;
ERROR:  ON CONFLICT DO UPDATE command cannot affect row a second time
SUGERENCIA:  Ensure that no rows proposed for insertion within the same command have
duplicate constrained values.
tienda=*# ROLLBACK;
ROLLBACK
```

- Los dos fallan, y **fallan distinto**. `MERGE` clasificó las dos filas como `NOT MATCHED` y la
  segunda chocó contra el índice: un `duplicate key` corriente. `ON CONFLICT` sí ve que es el mismo
  destino y da un error propio. **Lo que aquí produce la fuente, en producción lo produce otra
  sesión** que inserta la clave entre el `ON` y el `INSERT`. No pude reproducir ese caso concurrente
  —exigiría un `COMMIT` en una base compartida—, así que lo medido es el mecanismo equivalente.

En MySQL y MariaDB **no hay `MERGE`**: las dos responden `ERROR 1064`. El sustituto es `INSERT … ON
DUPLICATE KEY UPDATE`, que actualiza contra *cualquier* clave única sin que puedas elegir cuál, y
cuyo `ROW_COUNT()` vale 1 cuando insertó y **2 cuando actualizó** —medido—: así se distinguen allí
donde no hay `RETURNING`. El otro sustituto hay que saber rechazarlo:

```text
mysql> START TRANSACTION;
mysql> REPLACE INTO pedidos (codigo, cliente_id, estado, total, creado_en)
    -> VALUES ('PED-99999', 10324, 'ENTREGADO', 5971.28, '2024-03-20 10:00:00');
mysql> SELECT ROW_COUNT() AS filas, (SELECT id FROM pedidos WHERE codigo='PED-99999') AS id_nuevo,
    ->        (SELECT count(*) FROM pedido_lineas WHERE pedido_id=99999) AS lineas,
    ->        (SELECT count(*) FROM eventos_pedido WHERE pedido_id=99999) AS eventos;
+-------+----------+--------+---------+
| filas | id_nuevo | lineas | eventos |
+-------+----------+--------+---------+
|     2 |  1000004 |      0 |       0 |
+-------+----------+--------+---------+
mysql> ROLLBACK;
mysql> SELECT (SELECT id FROM pedidos WHERE codigo='PED-99999') AS id_tras_rollback,
    ->        (SELECT count(*) FROM pedido_lineas WHERE pedido_id=99999) AS lineas;
+------------------+--------+
| id_tras_rollback | lineas |
+------------------+--------+
|            99999 |      6 |
+------------------+--------+
```

- **`REPLACE` no actualiza: borra e inserta**, y `ROW_COUNT()` a 2 lo confirma. Las tres
  consecuencias están en la misma línea: el `id` pasó de 99999 a **1 000 004**, así que toda
  referencia externa apunta a un pedido que ya no existe; **las seis líneas y los seis eventos
  desaparecieron** por sus foráneas `ON DELETE CASCADE`; y lo que no nombras vuelve a su valor por
  defecto. El `ROLLBACK` lo devolvió todo a su sitio.
- `PED-99999` está `ANULADO` y sin pagos, por eso pudo borrarse. Sobre `PED-00042`, cuya foránea
  desde `pagos` es `NO ACTION`, habría fallado con un error de integridad: el escenario bueno.

> **⚠️ Advertencia.** `REPLACE INTO` parece un upsert y es un `DELETE` más un `INSERT`: dispara los
> `ON DELETE CASCADE`, consume un `AUTO_INCREMENT` nuevo y pierde las columnas que no mencionas. Si
> quieres actualizar, el verbo es `ON DUPLICATE KEY UPDATE`.

---

## 6. 🧱 Una vista no guarda filas, guarda la consulta

Una **vista** es un nombre para un `SELECT`, guardado en el catálogo: no ocupa espacio de datos ni
tiene contenido propio. Cuando la consultas, el motor **la expande** —sustituye el nombre por su
definición— y planifica el resultado entero. Se nota en que el plan ni la menciona:

```text
tienda=# BEGIN;
BEGIN
tienda=*# CREATE VIEW pedidos_anulados AS
tienda-*#   SELECT id, codigo, cliente_id, total, creado_en FROM pedidos WHERE estado = 'ANULADO';
CREATE VIEW
tienda=*# EXPLAIN (ANALYZE, COSTS, BUFFERS)
tienda-*# SELECT codigo, total FROM pedidos_anulados WHERE codigo = 'PED-99999';
                                                           QUERY PLAN
--------------------------------------------------------------------------------------------------------------------------------
 Index Scan using pedidos_codigo_key on pedidos  (cost=0.43..2.65 rows=1 width=17) (actual time=0.045..0.045 rows=1.00 loops=1)
   Index Cond: (codigo = 'PED-99999'::text)
   Filter: (estado = 'ANULADO'::text)
   Index Searches: 1
   Buffers: shared hit=4
 Planning:
   Buffers: shared hit=81
 Planning Time: 0.326 ms
 Execution Time: 0.067 ms
(9 filas)
```

- **La vista desapareció del plan.** Queda un `Index Scan` sobre `pedidos` donde el `WHERE` de fuera
  se volvió `Index Cond` y el de la definición, `Filter`: cuatro páginas y **ningún resultado
  intermedio**. **Cuánto cuesta:** nada en disco ni en ejecución; el precio está en la planificación
  y en que una vista sobre otra produce planes que nadie entiende.
- **Teardown:** **PostgreSQL tiene DDL transaccional**, así que el `ROLLBACK` borra la vista y
  `pg_views` vuelve a quedar vacío.

Una vista **simple** es actualizable sola —`pedidos_anulados` lo es— porque el `UPDATE` sobre la
vista se traduce a un `UPDATE` sobre la tabla. Cuando la definición deja de corresponder uno a uno
con las filas de una sola tabla, deja de serlo:

```text
tienda=*# CREATE VIEW ventas_por_cliente AS
tienda-*#   SELECT c.codigo AS cliente, count(*) AS pedidos, sum(p.total) AS importe
tienda-*#     FROM clientes c JOIN pedidos p ON p.cliente_id = c.id
tienda-*#    WHERE p.estado IN ('PAGADO','ENVIADO','ENTREGADO') GROUP BY c.codigo;
CREATE VIEW
tienda=*# UPDATE ventas_por_cliente SET importe = 0 WHERE cliente = 'CLI-00311';
ERROR:  cannot update view "ventas_por_cliente"
DETALLE:  Views containing GROUP BY are not automatically updatable.
SUGERENCIA:  To enable updating the view, provide an INSTEAD OF UPDATE trigger or an
unconditional ON UPDATE DO INSTEAD rule.
```

- **`information_schema.views` lo dice antes de estrellarte** —`is_updatable` a `NO`, medido—, y el
  motivo es que **no hay forma de saber a qué fila de `pedidos` le toca bajar el `importe`**: `GROUP
  BY`, `DISTINCT`, agregados, ventanas, `UNION` y `LIMIT` rompen la actualizabilidad.

La **vista materializada** sí guarda filas, y por eso puede quedarse vieja. La misma consulta:

```text
tienda=*# SELECT count(*) FROM (
tienda(*#   SELECT c.codigo, count(*) AS pedidos, sum(p.total) AS importe
tienda(*#     FROM clientes c JOIN pedidos p ON p.cliente_id = c.id
tienda(*#    WHERE p.estado IN ('PAGADO','ENVIADO','ENTREGADO') GROUP BY c.codigo) t;
 count
-------
 49999
(1 fila)

Duración: 366,176 ms
tienda=*# CREATE MATERIALIZED VIEW mv_ventas AS
tienda-*#   SELECT c.codigo AS cliente, count(*) AS pedidos, sum(p.total) AS importe
tienda-*#     FROM clientes c JOIN pedidos p ON p.cliente_id = c.id
tienda-*#    WHERE p.estado IN ('PAGADO','ENVIADO','ENTREGADO') GROUP BY c.codigo;
SELECT 49999
Duración: 855,047 ms
tienda=*# SELECT count(*), pg_size_pretty(pg_total_relation_size('mv_ventas')) FROM mv_ventas;
 count | pg_size_pretty
-------+----------------
 49999 | 3600 kB
(1 fila)

Duración: 2,876 ms
tienda=*# REFRESH MATERIALIZED VIEW mv_ventas;
REFRESH MATERIALIZED VIEW
Duración: 857,911 ms
tienda=*# ROLLBACK;
ROLLBACK
```

- **Cuánto cuesta:** la consulta viva tarda **366,176 ms** y desde la materializada, **2,876 ms**
  —**127 veces menos**—, a cambio de **3 600 kB** de disco y **857,911 ms de `REFRESH`**. El
  `REFRESH` **no es incremental**: vuelve a correr la consulta entera, y entre dos refrescos la
  vista miente.
- **`REFRESH … CONCURRENTLY` no bloquea las lecturas**, pero exige un índice único sobre la vista y
  **no corre dentro de un bloque de transacción**; por eso aquí se usó la forma normal.

MySQL 9.7.2 tiene vistas —`pedidos_anulados` sale con `IS_UPDATABLE = YES`—, pero **su DDL confirma
implícitamente**: un `ROLLBACK` no la borra y el teardown es un `DROP VIEW` explícito.

- **MySQL 9.7.2 acepta la palabra `MATERIALIZED`** —`SHOW CREATE VIEW` devuelve `CREATE
  ALGORITHM=UNDEFINED MATERIALIZED /*(BY ENGINE=UNKNOWN)*/ … VIEW`—, pero **no tiene sentencia de
  refresco** (`REFRESH MATERIALIZED VIEW` y `ALTER VIEW … REFRESH` dan `ERROR 1064`) y deja
  `TABLE_ROWS` y `DATA_LENGTH` a `NULL`: **no pude verificar que materialice nada**.
- **SQLite 3.53.4 no las tiene** —`Parse error … near "MATERIALIZED"`— y sus vistas **nunca son
  actualizables**: `cannot modify pedidos_anulados because it is a view`. El apaño en los dos es el
  mismo: **una tabla de resumen que rellenas tú**, con su `INSERT … SELECT` periódico, su marca de
  última actualización y el trabajo programado que la mantiene.

> **🧠 Modelo mental.** Una vista guarda una consulta y cuesta planificación; una materializada
> guarda filas y cuesta disco más la decisión de cuándo están frescas. La pregunta que decide entre
> las dos no es de rendimiento: es cuánta caducidad tolera quien lee.

---

## 7. 📜 Estándar, motor y convención

> **📜 Estándar o motor.** ISO/IEC 9075 es de pago y **no he verificado sus cláusulas en esta
> edición**: donde la columna dice *no verificado*, lo afirmado es lo que hacen los motores, medido
> en sesión. Del estándar solo se afirma que `MERGE` es suyo y `ON CONFLICT` no.

| Afirmación | Estándar | PostgreSQL 18.6 | MySQL 9.7.2 | SQLite 3.53.4 |
|---|---|---|---|---|
| `UNION` deduplica y `UNION ALL` no | No verificado | Sí: `HashAggregate`, +45 % de tiempo | Sí | Sí |
| Existen `INTERSECT` y `EXCEPT`, y sus variantes `ALL` | No verificado | Sí | Sí, **desde 8.0.31** | Solo sin `ALL`: `Parse error … near "ALL"` |
| `MINUS` es sinónimo de `EXCEPT` | No: es de Oracle | No: error de sintaxis | No: `ERROR 1064` | No: `Parse error` |
| Upsert con `INSERT … ON CONFLICT` | **No**: es de PostgreSQL | Sí, desde la 9.5 | No: `ON DUPLICATE KEY UPDATE` | Sí, desde 3.24 |
| `MERGE` | **Sí**, es la del estándar | Sí, desde la 15; `RETURNING` desde la 17 | **No**: `ERROR 1064` | **No**: `Parse error` |
| `RETURNING` en `INSERT` | No verificado | Sí | **No**: `ERROR 1064` | Sí, desde 3.35 |
| Vistas materializadas con refresco | No verificado | Sí: `REFRESH`, 857,911 ms | Acepta la palabra; **sin `REFRESH`** | **No**: `Parse error` |
| Una vista simple es actualizable | No verificado | Sí, automáticamente | Sí: `IS_UPDATABLE = YES` | **No**: hace falta `INSTEAD OF` |
| El DDL de vistas se deshace con `ROLLBACK` | No verificado | Sí | **No**: confirma implícito | Sí |

MariaDB 12.3.3 coincide con MySQL en `INTERSECT`, `EXCEPT`, la ausencia de `MERGE` y el DDL no
transaccional, y diverge en dos puntos medidos: **tiene `RETURNING` en `INSERT` y `DELETE`** y
**reconoce `MINUS`, pero solo con `sql_mode='ORACLE'`**.

**Convención:** *"`REPLACE INTO` es el upsert de MySQL"*. Se repite desde MySQL 4 y es falso —§5 lo
mide: `REPLACE` borra e inserta—; viene de que existía años antes que `ON DUPLICATE KEY UPDATE`. La
otra es *"las vistas son lentas"*: una vista normal se expande y no cuesta nada en ejecución; lo que
cuesta es la consulta que lleva dentro.

---

## ⚠️ Errores frecuentes

| Se dice | Lo preciso |
|---|---|
| "`UNION` y `UNION ALL` son lo mismo, `ALL` es por claridad" | `UNION` deduplica con un hash. Medido: 274,114 ms contra 189,145 ms y 5 657 kB de memoria |
| "MySQL no tiene `INTERSECT` ni `EXCEPT`" | Los tiene desde 8.0.31, de 2022. Lo que no tiene es `MINUS`, que es de Oracle |
| "`ON CONFLICT` compara los valores de la columna" | Consulta un índice único o una restricción de exclusión. Sin él: `there is no unique or exclusion constraint matching the ON CONFLICT specification` |
| "Con `UNIQUE` en la columna, el upsert ya es idempotente" | No si admite nulos: los 273 126 pagos con `referencia` nula se reinsertan cada vez, sin error |
| "`MERGE` es el `ON CONFLICT` del estándar" | Es más general —puede borrar— y no es equivalente frente a concurrencia: clasifica con su instantánea y no vuelve a mirar |
| "`REPLACE INTO` actualiza la fila" | La borra y la inserta: cambia el `id`, dispara los `ON DELETE CASCADE` y reinicia las columnas que no nombras |
| "Una vista guarda el resultado de la consulta" | Guarda la consulta. El plan de §6 ni la menciona: el motor la expande antes de planificar |
| "Si la vista va lenta, la hago materializada" | Cambia el precio de sitio: 2,876 ms al leer, 857,911 ms por `REFRESH` y datos viejos entre uno y otro |

---

## 📚 Para profundizar

- **Documentación** — PostgreSQL 18, «Combining Queries»: `UNION`, `INTERSECT`, `EXCEPT` y `ALL`.
  <https://www.postgresql.org/docs/18/queries-union.html>
- **Documentación** — PostgreSQL 18, «INSERT»: `ON CONFLICT`, `EXCLUDED` y `RETURNING`.
  <https://www.postgresql.org/docs/18/sql-insert.html>
- **Documentación** — PostgreSQL 18, «MERGE»: el orden de las ramas y su nota de concurrencia.
  <https://www.postgresql.org/docs/18/sql-merge.html>
- **Documentación** — PostgreSQL 18, «CREATE MATERIALIZED VIEW», con `REFRESH` y `CONCURRENTLY`.
  <https://www.postgresql.org/docs/18/sql-creatematerializedview.html>
- **Documentación** — MySQL 9.7, «REPLACE Statement»: dice por escrito que borra e inserta.
  <https://dev.mysql.com/doc/refman/9.7/en/replace.html>
- **Documentación** — MySQL 9.7, «Set Operations with UNION, INTERSECT, and EXCEPT».
  <https://dev.mysql.com/doc/refman/9.7/en/set-operations.html>
- **Documentación** — SQLite, «UPSERT»: la sintaxis prestada de PostgreSQL y sus límites.
  <https://www.sqlite.org/lang_upsert.html>

---

## 🧠 Preguntas

1. ¿Qué hace `UNION` que no hace `UNION ALL`, y con qué nodo del plan lo hace en PostgreSQL? 🟢
2. ¿Qué devuelve `EXCEPT` y qué devuelve `INTERSECT`? 🟢
3. ¿Qué es la pseudotabla `EXCLUDED` dentro de un `ON CONFLICT DO UPDATE`? 🟢
4. ¿Qué guarda una vista normal y qué guarda una materializada? 🟢
5. Distingue `ON CONFLICT DO NOTHING` de `DO UPDATE`: ¿cuál exige nombrar la columna, y por qué? 🟡
6. `MINUS` y `EXCEPT`: ¿son lo mismo? Di qué acepta cada uno de los cuatro motores del corpus. 🟡
7. ¿`RETURNING` es del estándar o del motor? Di qué hace cada uno de los cuatro. 🟡
8. Un `CREATE VIEW` dentro de una transacción que luego se deshace: ¿qué queda en PostgreSQL y qué
   queda en MySQL? 🟡
9. Alguien escribe `UNION` en un informe cuyas dos ramas filtran por estados distintos del mismo
   pedido. Dale el argumento de coste con los números de §2. 🟠
10. `pagos.referencia` es `UNIQUE` y admite nulos: explica por qué el upsert por `referencia` no
    vuelve idempotente el lote de los pagos en efectivo. 🟠
11. ¿Por qué `MERGE` y `ON CONFLICT` fallan con errores distintos cuando la fuente trae dos veces la
    misma clave, y qué revela esa diferencia sobre la concurrencia? 🟠
12. Un compañero propone `REPLACE INTO pedidos` para el lote nocturno. Da las tres consecuencias
    medidas en §5, en orden de gravedad. 🟠
13. `EXCEPT` frente a `NOT EXISTS` para los pedidos sin pago: los dos dan 180 000, ¿por qué el
    capítulo prefiere el segundo dentro de una consulta caliente? 🟠
14. `ON CONFLICT (nombre)` falla con `there is no unique or exclusion constraint matching…`. Escribe
    el DDL mínimo que lo arreglaría en `clientes`, y di qué rompe ese DDL de los datos actuales. 🔴
15. Escribe el `MERGE` que aplica un lote del proveedor sobre `pagos` con sus tres ramas
    —actualizar, borrar cuando el importe es cero, insertar— y devuelve qué le pasó a cada fila. 🔴
16. El mismo lote idempotente tiene que correr en PostgreSQL y en MySQL 9.7.2: escribe las dos
    sentencias y señala qué garantía pierdes en MySQL. 🔴
17. Un panel tarda 366 ms por consulta y lo abren 200 personas cada mañana. Da la secuencia de
    diagnóstico y decisión —qué mides, en qué orden y qué artefacto creas al final— con los números
    de §6. 🔴

---

**Anterior:** [`06`](06-funciones-de-ventana.md) · **Siguiente:** [`08`](08-dialectos.md) — qué es
portable entre los cuatro motores · **Relacionado:** [`05`](05-cte-y-recursion.md) — el `UNION` del
término recursivo, que sí deduplica a propósito · [`04`](04-agregacion-y-subconsultas.md) — `EXISTS`
y `NOT EXISTS`, la alternativa a `INTERSECT` y `EXCEPT` ·
[`01/06`](../01-fundamentos-y-modelo-relacional/06-nulos-y-logica-de-tres-valores.md) — por qué dos
nulos no son iguales, lo que rompe el upsert sobre `pagos.referencia`.
