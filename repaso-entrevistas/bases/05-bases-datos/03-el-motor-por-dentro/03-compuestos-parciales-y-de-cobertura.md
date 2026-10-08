# 03 — Compuestos, parciales y de cobertura

> Por qué el orden de las columnas de un índice compuesto decide si el motor lo usa o lo ignora, qué
> son los índices parciales y los funcionales, y qué hace falta para que una consulta se resuelva
> sin tocar la tabla. **Asume leído:** [`02`](02-familias-de-indices.md) — de ahí viene el B-tree y
> por qué es la familia por defecto. **Vigencia:** 20 de septiembre de 2026.

---

## Salto rápido

- [1. El problema](#1--el-problema)
- [2. La guía telefónica y la regla del prefijo
  izquierdo](#2--la-guía-telefónica-y-la-regla-del-prefijo-izquierdo)
- [3. El orden importa, y se mide](#3-️-el-orden-importa-y-se-mide)
- [4. Índice parcial: indexar solo las filas que
  importan](#4--índice-parcial-indexar-solo-las-filas-que-importan)
- [5. Índice funcional: indexar el resultado](#5--índice-funcional-indexar-el-resultado)
- [6. Index-only scan y el Heap Fetches que sigue
  ahí](#6--index-only-scan-y-el-heap-fetches-que-sigue-ahí)
- [7. El precio del índice](#7-️-el-precio-del-índice)
- [8. Estándar, motor y convención](#8--estándar-motor-y-convención)

---

## 1. 🎯 El problema

El informe de rotación filtra `pedido_lineas` unas veces por producto y otras por cantidad, así que
alguien crea un índice sobre las dos columnas para cubrir las dos consultas.

```text
tienda=# BEGIN;
BEGIN
tienda=# CREATE INDEX ix_lineas_prod_cant ON pedido_lineas (producto_id, cantidad);
CREATE INDEX
Duración: 829,309 ms
tienda=# ANALYZE pedido_lineas;
ANALYZE
Duración: 115,015 ms
tienda=# SELECT pg_size_pretty(pg_relation_size('ix_lineas_prod_cant')) AS tamano;
 tamano
--------
 24 MB
(1 fila)

Duración: 0,612 ms
```

La consulta por producto pasa a tardar 34 ms. La de cantidad, que antes tardaba 167 ms leyendo la
tabla entera, ahora tarda **191 ms**: el índice existe, el planificador lo usa, y va peor.

---

## 2. 🧱 La guía telefónica y la regla del prefijo izquierdo

Un índice compuesto es **una guía telefónica ordenada por apellido y luego nombre**: sirve por
apellido y por apellido y nombre, y **no sirve para buscar solo por nombre**, porque todos los "Ana"
están desperdigados por las mil páginas. Eso es la **regla del prefijo izquierdo** (*leftmost
prefix*): un índice sobre `(a, b, c)` acelera los filtros sobre `a`, `(a, b)` y `(a, b, c)`, y no
los que empiezan por `b` o por `c`. **Quién lo manda:** el motor —el B-tree—, no el estándar.

```text
tienda=# EXPLAIN (ANALYZE, COSTS, BUFFERS)
tienda-# SELECT pedido_id, linea FROM pedido_lineas WHERE producto_id = 17;
                                                               QUERY PLAN
-----------------------------------------------------------------------------------------------------------------------------------------
 Bitmap Heap Scan on pedido_lineas  (cost=166.51..15174.72 rows=19017 width=10) (actual time=2.157..33.801 rows=20205.00 loops=1)
   Recheck Cond: (producto_id = 17)
   Heap Blocks: exact=11887
   Buffers: shared hit=381 read=11529
   I/O Timings: shared read=7.277
   ->  Bitmap Index Scan on ix_lineas_prod_cant  (cost=0.00..161.76 rows=19017 width=0) (actual time=0.948..0.948 rows=20205.00 loops=1)
         Index Cond: (producto_id = 17)
         Index Searches: 1
         Buffers: shared hit=3 read=20
         I/O Timings: shared read=0.116
 Planning:
   Buffers: shared hit=17 read=1
   I/O Timings: shared read=0.020
 Planning Time: 0.098 ms
 Execution Time: 34.492 ms
(15 filas)
```

- **`Index Searches: 1`**: una sola bajada por el árbol, y de ahí en adelante las 20 205 entradas
  están contiguas. Veintitrés páginas de índice (`hit=3 read=20`) contra las 29 167 de la tabla. El
  `Bitmap Heap Scan` de encima se paga porque esas filas viven en 11 887 páginas distintas.

Ahora las dos columnas, que es para lo que el índice está pensado:

```text
tienda=# EXPLAIN (ANALYZE, COSTS, BUFFERS)
tienda-# SELECT pedido_id, linea FROM pedido_lineas WHERE producto_id = 17 AND cantidad = 5;
                                                              QUERY PLAN
--------------------------------------------------------------------------------------------------------------------------------------
 Bitmap Heap Scan on pedido_lineas  (cost=28.28..2530.67 rows=2395 width=10) (actual time=0.313..2.048 rows=2541.00 loops=1)
   Recheck Cond: ((producto_id = 17) AND (cantidad = 5))
   Heap Blocks: exact=1895
   Buffers: shared hit=1900
   ->  Bitmap Index Scan on ix_lineas_prod_cant  (cost=0.00..27.68 rows=2395 width=0) (actual time=0.150..0.150 rows=2541.00 loops=1)
         Index Cond: ((producto_id = 17) AND (cantidad = 5))
         Index Searches: 1
         Buffers: shared hit=5
 Planning:
   Buffers: shared hit=8
 Planning Time: 0.081 ms
 Execution Time: 2.130 ms
(12 filas)
```

- Las dos condiciones entran en el `Index Cond`, cinco páginas, 2,130 ms: **eso compra la segunda
  columna**, bajar de 20 205 candidatas a 2 541 sin tocar el heap. Y el tercer caso:

```text
tienda=# EXPLAIN (ANALYZE, COSTS, BUFFERS)
tienda-# SELECT pedido_id, linea FROM pedido_lineas WHERE cantidad = 5;
                                                                  QUERY PLAN
-----------------------------------------------------------------------------------------------------------------------------------------------
 Bitmap Heap Scan on pedido_lineas  (cost=29743.15..64421.19 rows=440883 width=10) (actual time=41.816..175.705 rows=438435.00 loops=1)
   Recheck Cond: (cantidad = 5)
   Heap Blocks: exact=29167
   Buffers: shared hit=11999 read=19870 written=3
   I/O Timings: shared read=32.276 write=0.061
   ->  Bitmap Index Scan on ix_lineas_prod_cant  (cost=0.00..29632.93 rows=440883 width=0) (actual time=38.473..38.474 rows=438435.00 loops=1)
         Index Cond: (cantidad = 5)
         Index Searches: 51
         Buffers: shared hit=107 read=2595
         I/O Timings: shared read=20.614
 Planning Time: 0.036 ms
 Execution Time: 190.789 ms
(12 filas)
```

- **`Index Searches: 51`**, no 1. PostgreSQL 18 hace un *skip scan*: salta de un valor de
  `producto_id` al siguiente buscando `cantidad = 5` en cada tramo. Con 5 000 productos distintos
  eso no es saltar, es **leer el índice entero** —2 702 páginas de 3 072, el 88 %— y luego ir al
  heap igual: 190,789 ms.
- Con los accesos por índice apagados, el `Seq Scan` tarda **167,704 ms** y cuesta 72 917 estimados
  contra los 64 421 del plan de arriba: el planificador eligió el índice porque le salía más barato,
  y se equivocó por un 14 %.

> **📝 Contexto.** Hasta PostgreSQL 17 ese plan era un `Seq Scan` y punto: el índice **no se usaba**,
> que es como lo cuenta casi todo lo que vas a leer. La 18 añadió el *skip scan* de B-tree y el
> índice aparece en el plan. Cambia el síntoma, no el consejo: uno que necesita 51 bajadas y lee el
> 88 % de sus páginas no sirve. MySQL hace lo mismo desde la 8.0.13 (§8).

> **Veredicto:** la columna de más a la izquierda es la única que garantiza una sola bajada por el
> árbol. Si tu `WHERE` no la nombra, el índice te va a costar más de lo que te ahorra.

---

## 3. ⚖️ El orden importa, y se mide

Cuál va delante lo decide **la selectividad**, y la asimetría es brutal: `PRD-00017` se lleva 20 205
líneas de 3 500 000 —el 0,58 %— y `cantidad = 5`, 438 435 —el 12,5 %—. El mismo par al revés:

```text
tienda=# BEGIN;
BEGIN
tienda=# CREATE INDEX ix_lineas_cant_prod ON pedido_lineas (cantidad, producto_id);
CREATE INDEX
Duración: 1097,263 ms (00:01,097)
tienda=# ANALYZE pedido_lineas;
ANALYZE
tienda=# EXPLAIN (ANALYZE, COSTS, BUFFERS)
tienda-# SELECT pedido_id, linea FROM pedido_lineas WHERE producto_id = 17;
                                                               QUERY PLAN
-----------------------------------------------------------------------------------------------------------------------------------------
 Bitmap Heap Scan on pedido_lineas  (cost=168.85..15108.94 rows=18900 width=10) (actual time=2.629..22.625 rows=20205.00 loops=1)
   Recheck Cond: (producto_id = 17)
   Heap Blocks: exact=11887
   Buffers: shared hit=8770 read=3166
   I/O Timings: shared read=7.916
   ->  Bitmap Index Scan on ix_lineas_cant_prod  (cost=0.00..164.13 rows=18900 width=0) (actual time=1.488..1.488 rows=20205.00 loops=1)
         Index Cond: (producto_id = 17)
         Index Searches: 7
         Buffers: shared hit=13 read=36
         I/O Timings: shared read=0.385
 Planning:
   Buffers: shared hit=19 read=2
   I/O Timings: shared read=0.051
 Planning Time: 0.141 ms
 Execution Time: 23.433 ms
(15 filas)
```

- **`Index Searches: 7`** —una bajada por valor de `cantidad`— y **49 páginas de índice contra las
  23 del orden bueno**. El salto sale barato porque delante hay cinco valores; sobre 5 000, como en
  §2, no. Esa asimetría **es** la selectividad.
- **El reloj no distingue nada aquí** —23,433 ms contra 34,492 ms, y el "malo" salió más rápido
  porque el heap estaba en caché, `hit=8770` contra `hit=381`—: mide páginas y bajadas.

> **Veredicto:** delante va la columna por la que **siempre** filtras; si los dos filtros aparecen
> siempre juntos, delante va la más selectiva, que deja el tramo más corto que recorrer.

---

## 4. 🧱 Índice parcial: indexar solo las filas que importan

Un **índice parcial** lleva un `WHERE` en su definición y solo guarda las filas que lo cumplen.
`pedidos` tiene 60 000 `ANULADO` de 1 000 000 y el panel de soporte solo busca entre esos: indexar
el otro 94 % es pagar disco y escrituras por filas que nadie consulta.

```text
tienda=# BEGIN;
BEGIN
tienda=# CREATE INDEX ix_pedidos_cliente ON pedidos (cliente_id);
CREATE INDEX
Duración: 191,090 ms
tienda=# CREATE INDEX ix_pedidos_cliente_anulado ON pedidos (cliente_id) WHERE estado = 'ANULADO';
CREATE INDEX
Duración: 38,254 ms
tienda=# ANALYZE pedidos;
ANALYZE
tienda=# SELECT relname, pg_size_pretty(pg_relation_size(oid)) AS tamano, reltuples::bigint AS entradas
tienda-#   FROM pg_class WHERE relname IN ('ix_pedidos_cliente','ix_pedidos_cliente_anulado');
          relname           | tamano  | entradas
----------------------------+---------+----------
 ix_pedidos_cliente         | 7800 kB |  1000000
 ix_pedidos_cliente_anulado | 1136 kB |    56934
(2 filas)
```

- **7800 kB contra 1136 kB, y 191 ms contra 38 ms**, porque hay diecisiete veces menos entradas.
  `reltuples` es una **estimación**, no un recuento: dice 56 934 donde hay 60 000, y es el número
  con el que el planificador decide.

Lo peligroso es que **el motor solo lo usa si puede demostrar que el `WHERE` de la consulta implica
el del índice**. Los dos casos, seguidos:

```text
tienda=# EXPLAIN (ANALYZE, COSTS, BUFFERS)
tienda-# SELECT codigo FROM pedidos WHERE cliente_id = 311 AND estado = 'ANULADO';
                                                               QUERY PLAN
----------------------------------------------------------------------------------------------------------------------------------------
 Index Scan using ix_pedidos_cliente_anulado on pedidos  (cost=0.29..2.51 rows=1 width=10) (actual time=0.019..0.020 rows=3.00 loops=1)
   Index Cond: (cliente_id = 311)
   Index Searches: 1
   Buffers: shared hit=4 read=2
   I/O Timings: shared read=0.012
 Planning:
   Buffers: shared hit=29 read=2
   I/O Timings: shared read=0.020
 Planning Time: 0.081 ms
 Execution Time: 0.024 ms
(10 filas)

tienda=# EXPLAIN (ANALYZE, COSTS, BUFFERS)
tienda-# SELECT codigo FROM pedidos WHERE cliente_id = 311 AND estado = 'PENDIENTE';
                                                           QUERY PLAN
---------------------------------------------------------------------------------------------------------------------------------
 Index Scan using ix_pedidos_cliente on pedidos  (cost=0.42..25.04 rows=3 width=10) (actual time=0.034..0.054 rows=6.00 loops=1)
   Index Cond: (cliente_id = 311)
   Filter: (estado = 'PENDIENTE'::text)
   Rows Removed by Filter: 46
   Index Searches: 1
   Buffers: shared hit=2 read=4
   I/O Timings: shared read=0.026
 Planning:
   Buffers: shared hit=3
 Planning Time: 0.038 ms
 Execution Time: 0.057 ms
(11 filas)
```

- En el primero **el `Index Cond` no menciona `estado` y no hay línea `Filter`**: la condición la
  garantiza la definición del índice. Ese es el ahorro de verdad.
- En el segundo el parcial **ni aparece**, porque `PENDIENTE` no implica `ANULADO`: cae al índice
  completo y descarta 46 filas con un `Filter`. Con `WHERE cliente_id = 311` a secas, igual.
- **Cuándo sí:** una bandera desbalanceada que siempre se filtra igual —`productos` tiene 101
  inactivos de 5 000—, una cola con `WHERE procesado = false`, un histórico del que solo se consulta
  el último año. **Cuándo no:** cuando el `WHERE` varía, porque acabas con un parcial por valor.
- **El motivo número uno de "en mi máquina sí se usaba":** con el valor en un parámetro —`estado =
  $1`— el planificador no puede demostrar la implicación en plan genérico y el parcial no se usa.

---

## 5. 🧱 Índice funcional: indexar el resultado

La aplicación normaliza los correos antes de comparar y `clientes` ya tiene un `UNIQUE` sobre
`email`. El índice existe y no se usa.

```text
tienda=# EXPLAIN (ANALYZE, COSTS, BUFFERS)
tienda-# SELECT id, nombre FROM clientes WHERE lower(email) = 'cliente311@ejemplo.test';
                                                 QUERY PLAN
-------------------------------------------------------------------------------------------------------------
 Seq Scan on clientes  (cost=0.00..1368.00 rows=250 width=21) (actual time=17.490..17.494 rows=1.00 loops=1)
   Filter: (lower(email) = 'cliente311@ejemplo.test'::text)
   Rows Removed by Filter: 49999
   Buffers: shared read=618 dirtied=1
   I/O Timings: shared read=0.459
 Planning:
   Buffers: shared hit=89 read=3
   I/O Timings: shared read=0.020
 Planning Time: 0.220 ms
 Execution Time: 17.522 ms
(10 filas)
```

`clientes_email_key` guarda `email`, no `lower(email)`, y el motor no sabe que uno se deriva del
otro. Un **índice funcional** —o de expresión— guarda el resultado, y entonces sí hay qué comparar:

```text
tienda=# BEGIN;
BEGIN
tienda=# CREATE INDEX ix_clientes_email_lower ON clientes (lower(email));
CREATE INDEX
Duración: 134,664 ms
tienda=# ANALYZE clientes;
ANALYZE
tienda=# EXPLAIN (ANALYZE, COSTS, BUFFERS)
tienda-# SELECT id, nombre FROM clientes WHERE lower(email) = 'cliente311@ejemplo.test';
                                                              QUERY PLAN
--------------------------------------------------------------------------------------------------------------------------------------
 Index Scan using ix_clientes_email_lower on clientes  (cost=0.41..2.63 rows=1 width=21) (actual time=0.030..0.031 rows=1.00 loops=1)
   Index Cond: (lower(email) = 'cliente311@ejemplo.test'::text)
   Index Searches: 1
   Buffers: shared hit=1 read=3
   I/O Timings: shared read=0.017
 Planning:
   Buffers: shared hit=13 read=1
   I/O Timings: shared read=0.011
 Planning Time: 0.071 ms
 Execution Time: 0.041 ms
(10 filas)
```

- **17,522 ms contra 0,041 ms, y 618 páginas contra 4.** El precio: 2448 kB, 134 ms de construcción,
  y **la expresión se evalúa en cada `INSERT` y en cada `UPDATE` de `email`**.
- **La expresión del índice y la del `WHERE` tienen que coincidir exactamente**: `upper(email)`,
  `lower(trim(email))` o `email ILIKE …` son otras expresiones, sin índice. **Cuándo no:** comparar
  sin distinguir mayúsculas en todas partes es del tipo de la columna —*collation* no determinista o
  `citext`—, no un índice por consulta.
- **La columna envuelta en una función** es una de las seis razones por las que un índice existente
  no se usa; el catálogo completo lo lleva [`06`](06-cuando-el-indice-no-se-usa.md).

---

## 6. 🧱 Index-only scan y el `Heap Fetches` que sigue ahí

Si el índice contiene **todas** las columnas que la consulta pide, el motor puede responder sin
tocar la tabla: eso es un *index-only scan*, y el índice que lo permite es un **índice de
cobertura**. Con `(cliente_id, total)`, un `sum(total)` por cliente no necesita el heap:

```text
tienda=# BEGIN;
BEGIN
tienda=# CREATE INDEX ix_pedidos_cliente_total ON pedidos (cliente_id, total);
CREATE INDEX
Duración: 595,203 ms
tienda=# ANALYZE pedidos;
ANALYZE
tienda=# EXPLAIN (ANALYZE, COSTS, BUFFERS)
tienda-# SELECT sum(total) FROM pedidos WHERE cliente_id = 311;
                                                                    QUERY PLAN
---------------------------------------------------------------------------------------------------------------------------------------------------
 Aggregate  (cost=25.05..25.06 rows=1 width=32) (actual time=0.070..0.070 rows=1.00 loops=1)
   Buffers: shared hit=18 read=3
   I/O Timings: shared read=0.019
   ->  Index Only Scan using ix_pedidos_cliente_total on pedidos  (cost=0.42..24.99 rows=21 width=7) (actual time=0.034..0.043 rows=52.00 loops=1)
         Index Cond: (cliente_id = 311)
         Heap Fetches: 52
         Index Searches: 1
         Buffers: shared hit=18 read=3
         I/O Timings: shared read=0.019
 Planning:
   Buffers: shared hit=24 read=3
   I/O Timings: shared read=0.048
 Planning Time: 0.156 ms
 Execution Time: 0.087 ms
(14 filas)
```

El nodo dice `Index Only Scan` y debajo, **`Heap Fetches: 52`** de 52 filas: fue al heap por todas.
No es un fallo del ejemplo: explicarlo separa recitar de entender. Un índice de PostgreSQL **no
guarda la visibilidad**: si la fila está viva lo dice el heap. Para no preguntarlo siempre mantiene
un *visibility map* —un bit por página que `VACUUM` pone cuando todas sus filas son visibles para
todos—, y **las tablas de este corpus nunca pasaron por `VACUUM`**:

```text
tienda=# SELECT relname, relpages, relallvisible FROM pg_class
tienda-#  WHERE relname IN ('pedidos','clientes','pedido_lineas');
    relname    | relpages | relallvisible
---------------+----------+---------------
 pedidos       |    10770 |             0
 clientes      |      618 |             0
 pedido_lineas |    29167 |         29163
(3 filas)
```

- **`relallvisible = 0` de 10 770 páginas.** El planificador lo sabe y cobra el heap: 25,05 contra
  los 25,10 del plan que sí necesita la tabla. Añade `max(creado_en)`, que no está en el índice, y
  el nodo pasa a `Index Scan` con 18 páginas contra 21: **el de cobertura sale tres páginas más
  caro**, porque es más ancho y las visitas al heap siguen ahí.
- **Con el mapa al día** —lo normal en producción— ese plan daría `Heap Fetches: 0` y 3 páginas en
  vez de 21. Aquí no lo vas a ver: `VACUUM` cambiaría los planes de todo el corpus. `pedido_lineas`
  sí lo tiene, 29 163 de 29 167, porque autovacuum la tocó tras la carga.
- **La otra forma de cubrir** es `… (cliente_id) INCLUDE (total)`: la columna viaja en las hojas y
  no en las ramas, así que el árbol no engorda y no se puede filtrar ni ordenar por ella.

> **🩺 Diagnóstico.** `Index Only Scan` con `Heap Fetches` alto no es un índice mal elegido: es una
> tabla sin `VACUUM` reciente. Mira `relallvisible` contra `relpages` en `pg_class` y
> `last_autovacuum` en `pg_stat_user_tables` antes de tocar el índice.

---

## 7. ⚖️ El precio del índice

Lo medido, índice por índice: 24 MB y 829 ms el compuesto, 24 MB y 1 097 ms el inverso, 31 MB y 595
ms el de cobertura, 7800 kB y 191 ms el completo de `cliente_id`, 1136 kB y 38 ms el parcial, 2448
kB y 135 ms el funcional; y un `CREATE INDEX` normal **bloquea las escrituras mientras construye**.
La escritura se mide con `EXPLAIN (WAL)`, lo único que no depende de la caché: cien mil `INSERT` en
`pedidos` escriben **303 976 registros de WAL** con la tabla tal cual y **504 640** con
`ix_pedidos_cliente` e `ix_pedidos_cliente_total` encima —**dos más por fila, uno por índice**—, y
el `Insert` pasa de 447 ms a 723 ms. Un `UPDATE` solo paga si toca columna indexada: 39 905 filas
con `SET total = total + 0.01` dan 158 435 registros sin índice sobre `total` y 200 027 con él.

> **Veredicto:** **cada índice es una escritura extra por `INSERT`, por `DELETE` y por cada `UPDATE`
> que toque sus columnas**, más su disco y su parte de la caché. El catálogo completo, con los
> registros de WAL medidos, lo lleva [`06`](06-cuando-el-indice-no-se-usa.md) §8.

---

## 8. 📜 Estándar, motor y convención

> **📜 Estándar o motor.** ISO/IEC 9075 **no define los índices**: son estructuras de implementación
> y ni `CREATE INDEX` ni `EXPLAIN` están en la norma; decirlo es media respuesta. No he verificado
> ninguna cláusula del estándar aquí: lo de abajo es lo que hacen los motores, medido en sesión.

| Afirmación | Estándar | PostgreSQL 18.6 | MySQL 9.7.2 / InnoDB | SQLite 3.53.4 |
|---|---|---|---|---|
| `CREATE INDEX` está en la norma | **No**: no aparece en ISO/IEC 9075 | Sí, con extensiones propias | Sí, con extensiones propias | Sí, con extensiones propias |
| Rige la regla del prefijo izquierdo | No aplica | Sí | Sí | Sí |
| Hay *skip scan* cuando falta el prefijo | No aplica | Sí, desde la 18 (`Index Searches: 51`) | Sí, desde la 8.0.13 (`index skip scan`) | No |
| Índice parcial con `WHERE` | No aplica | Sí | **No**: `ERROR 1064` de sintaxis | Sí |
| Índice sobre una expresión | No aplica | Sí, nativo | Sí, desde la 8.0.13, como *functional key part* `((expr))` | Sí |
| Índice sobre un prefijo de columna `col(n)` | No aplica | **No** | Sí | **No** |
| Índice de cobertura sin las columnas en la clave | No aplica | Sí, `INCLUDE`, desde la 11 | No hace falta: el índice secundario ya lleva la PK | No |
| `CREATE INDEX` se puede deshacer con `ROLLBACK` | No aplica | **Sí**: DDL transaccional | **No**: confirma implícitamente | Sí |

Los cuatro comportamientos de MySQL 9.7.2 que se comprobaron a mano, con su salida —la del `EXPLAIN`
funcional, sin el marco de la tabla, porque su única línea no cabe—:

```text
mysql> CREATE INDEX ix_pedidos_cliente_anulado ON pedidos (cliente_id) WHERE estado = 'ANULADO';
ERROR 1064 (42000) at line 1: You have an error in your SQL syntax; check the manual that corresponds to your MySQL server version for the right syntax to use near 'WHERE estado = 'ANULADO'' at line 1

mysql> CREATE INDEX ix_clientes_email_pref ON clientes (email(10));
mysql> SHOW INDEX FROM clientes WHERE Key_name = 'ix_clientes_email_pref';
+----------+------------+------------------------+--------------+-------------+-----------+-------------+----------+--------+------+------------+---------+---------------+---------+------------+
| Table    | Non_unique | Key_name               | Seq_in_index | Column_name | Collation | Cardinality | Sub_part | Packed | Null | Index_type | Comment | Index_comment | Visible | Expression |
+----------+------------+------------------------+--------------+-------------+-----------+-------------+----------+--------+------+------------+---------+---------------+---------+------------+
| clientes |          1 | ix_clientes_email_pref |            1 | email       | A         |         946 |       10 |   NULL |      | BTREE      |         |               | YES     | NULL       |
+----------+------------+------------------------+--------------+-------------+-----------+-------------+----------+--------+------+------------+---------+---------------+---------+------------+

mysql> CREATE INDEX ix_clientes_email_lower ON clientes ((lower(email)));
mysql> EXPLAIN SELECT id, nombre FROM clientes WHERE lower(email) = 'cliente311@ejemplo.test';
-> Index lookup on clientes using ix_clientes_email_lower (lower(email) = 'cliente311@ejemplo.test')  (cost=0.35 rows=1)

mysql> EXPLAIN SELECT pedido_id, linea FROM pedido_lineas WHERE cantidad = 5;
+---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------+
| EXPLAIN                                                                                                                                                                                     |
+---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------+
| -> Filter: (pedido_lineas.cantidad = 5)  (cost=187277 rows=697900)
    -> Covering index skip scan on pedido_lineas using ix_lineas_prod_cant over cantidad = 5  (cost=187277 rows=697900)
 |
+---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------+
```

- **El prefijo `email(10)` no es un índice parcial**: indexa *menos columna*, no *menos filas*.
  `Sub_part` dice 10 y `Cardinality`, **946 valores distintos de 50 000**.
- **El DDL de MySQL confirma solo**: los cuatro índices se borraron con `DROP INDEX … ON …`. Al
  crear `ix_lineas_prod_cant`, InnoDB **eliminó el índice implícito de la foránea**
  `fk_lineas_producto` por redundante y luego negó soltar el nuevo —`ERROR 1553 … needed in a
  foreign key constraint`—; hubo que recrear el original.
- **SQLite tiene las dos que MySQL no.** Con el parcial de §4, `EXPLAIN QUERY PLAN` responde `SEARCH
  pedidos USING INDEX ix_pedidos_cliente_anulado (cliente_id=?)` a la consulta de `ANULADO` y `SCAN
  pedidos` a la de `PENDIENTE`; con el funcional, `SEARCH clientes USING INDEX
  ix_clientes_email_lower (<expr>=?)`.

**Convención:** *"pon un índice por cada columna del `WHERE`"*. Viene de cuando los motores no
combinaban índices, y produce lo que este capítulo desmonta: índices que nadie usa, porque el filtro
real lleva dos columnas, y el precio de escritura de todos ellos. La versión útil es **un índice por
patrón de acceso**, con la columna más selectiva delante.

---

## ⚠️ Errores frecuentes

| Se dice | Lo preciso |
|---|---|
| "Un índice sobre `(a, b)` sirve para buscar por `b`" | No: es la guía telefónica ordenada por apellido. PostgreSQL 18 lo intenta con *skip scan* y le cuesta 51 bajadas y el 88 % de las páginas del índice; pierde contra el `Seq Scan` por 23 ms |
| "`WHERE estado = $1` usa mi índice parcial de `ANULADO`" | Solo si el planificador puede demostrar la implicación. Con el valor en un parámetro y plan genérico, no puede, y el índice no se usa |
| "El índice sobre `email` sirve para `lower(email)`" | Son expresiones distintas. Medido: `Seq Scan` de 618 páginas y 17,522 ms contra 4 páginas y 0,041 ms con el índice funcional |
| "`Index Only Scan` significa que no se tocó la tabla" | Significa que se intentó. Mira `Heap Fetches`: aquí es 52 de 52 filas, porque `relallvisible` es 0 de 10 770 páginas |
| "El prefijo de columna de MySQL es un índice parcial" | Indexa menos columna, no menos filas. `email(10)` deja 946 valores distintos de 50 000 y no filtra ninguna fila |

---

## 📚 Para profundizar

- **Documentación** — PostgreSQL 18, «Multicolumn Indexes»: la regla del prefijo y el *skip scan*.
  <https://www.postgresql.org/docs/18/indexes-multicolumn.html>
- **Documentación** — PostgreSQL 18, «Partial Indexes»: cómo se demuestra la implicación del
  predicado. <https://www.postgresql.org/docs/18/indexes-partial.html>
- **Documentación** — PostgreSQL 18, «Indexes on Expressions»: el coste de evaluar la expresión en
  cada escritura. <https://www.postgresql.org/docs/18/indexes-expressional.html>
- **Documentación** — PostgreSQL 18, «Index-Only Scans and Covering Indexes»: el *visibility map* y
  `INCLUDE`. <https://www.postgresql.org/docs/18/indexes-index-only-scans.html>
- **Referencia** — Markus Winand, *Use The Index, Luke!*, «Concatenated Keys»: el prefijo izquierdo.
  <https://use-the-index-luke.com/sql/where-clause/the-equals-operator/concatenated-keys>

---

## 🧠 Preguntas

1. Enuncia la regla del prefijo izquierdo con la analogía de la guía telefónica. 🟢
2. ¿Qué lleva un índice parcial en su definición que un índice normal no lleva? 🟢
3. ¿Qué guarda un índice funcional que no guarda un índice sobre la columna? 🟢
4. ¿Qué es un *index-only scan* y qué condición cumple el índice que lo permite? 🟢
5. En un plan, ¿qué te dice la línea `Heap Fetches` y qué valor querrías ver? 🟢
6. Distingue el índice parcial de PostgreSQL del prefijo de columna `email(10)` de MySQL. 🟡
7. ¿Los índices los define el estándar SQL o cada motor? Di qué hay en ISO/IEC 9075 sobre `CREATE
   INDEX`. 🟡
8. Con `(producto_id, cantidad)` filtras solo por `cantidad`: ¿qué hacía PostgreSQL 17, qué hace la
   18 y por qué el consejo no cambia? 🟡
9. `CREATE INDEX` dentro de `BEGIN … ROLLBACK`: ¿qué pasa en PostgreSQL y en MySQL? ¿Es diferencia
   de estándar o de motor? 🟡
10. Te dan `(cantidad, producto_id)` y `(producto_id, cantidad)`, y solo puedes dejar uno para un
    `WHERE producto_id = ? AND cantidad = ?`. Elige y justifica con la selectividad medida. 🟠
11. ¿Por qué el plan del índice parcial no tiene línea `Filter` y el del completo sí? 🟠
12. Un compañero propone un índice parcial por cada uno de los cinco estados de `pedidos`. Dale el
    argumento de coste en contra, con números. 🟠
13. El *index-only scan* de §6 lee 21 páginas y el `Index Scan` equivalente 18: explica por qué el
    de cobertura sale más caro y qué tendría que cambiar para que ganara. 🟠
14. Escribe el DDL de los índices para este panel: pedidos `ANULADO` de un cliente, ordenados por
    `creado_en`, mostrando solo `codigo` y `total`. Justifica el orden de las columnas. 🔴
15. Te pasan un plan con `Index Only Scan` y `Heap Fetches: 438435`: escribe la secuencia de
    diagnóstico —qué miras, con qué catálogo, en qué orden— y la corrección. 🔴
16. Haz que `WHERE lower(email) = ?` use un índice en PostgreSQL 18.6, MySQL 9.7.2 y SQLite 3.53.4:
    el DDL de los tres, y en qué se diferencian. 🔴

---

**Anterior:** [`02`](02-familias-de-indices.md) · **Siguiente:**
[`04`](04-estadisticas-y-el-planificador.md) · **Relacionado:** [`02`](02-familias-de-indices.md) —
por qué el B-tree admite prefijos y las demás familias no · [`06`](06-cuando-el-indice-no-se-usa.md)
— el catálogo de las seis razones y el precio en escritura ·
[`02/04`](../02-sql/04-agregacion-y-subconsultas.md) — el `sum(total)` por cliente.
