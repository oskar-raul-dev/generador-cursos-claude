# 01 — Cómo se almacena una tabla

> Dónde vive de verdad una fila: la página de 8 kB, la cabecera de 23 bytes, el relleno que te cobra
> bytes por el orden en que declaraste las columnas, y qué pasa cuando un valor no cabe. Cierra con
> el contraste que más se pregunta: **PostgreSQL guarda un `heap` desordenado con índices aparte,
> InnoDB guarda la tabla dentro de su índice primario**. **Asume leído:** el bloque
> [`02`](../02-sql/README.md). **Vigencia:** 20 de septiembre de 2026.

---

## Salto rápido

- [1. El problema](#1--el-problema)
- [2. La página de 8 kB y cuántas filas caben](#2--la-página-de-8-kb-y-cuántas-filas-caben)
- [3. `ctid`: la dirección física de la fila](#3--ctid-la-dirección-física-de-la-fila)
- [4. El ancho real de una fila](#4--el-ancho-real-de-una-fila)
- [5. TOAST: el valor que no cabe](#5--toast-el-valor-que-no-cabe)
- [6. InnoDB: la tabla **es** el índice primario](#6-️-innodb-la-tabla-es-el-índice-primario)
- [7. SQLite: `rowid` y `WITHOUT ROWID`](#7--sqlite-rowid-y-without-rowid)
- [8. Estándar, motor y convención](#8--estándar-motor-y-convención)
- [⚠️ Errores frecuentes](#️-errores-frecuentes)
- [📚 Para profundizar](#-para-profundizar)
- [🧠 Preguntas](#-preguntas)

---

## 1. 🎯 El problema

Contar el millón de pedidos tarda 109 ms y el motor toca **10 770 páginas**. Ni una menos, aunque
`count(*)` no mire una sola columna.

```text
tienda=# EXPLAIN (ANALYZE, BUFFERS, COSTS) SELECT count(*) FROM pedidos;
                                                        QUERY PLAN
---------------------------------------------------------------------------------------------------------------------------
 Aggregate  (cost=23270.00..23270.01 rows=1 width=8) (actual time=109.081..109.081 rows=1.00 loops=1)
   Buffers: shared hit=1587 read=9183
   I/O Timings: shared read=0.489
   ->  Seq Scan on pedidos  (cost=0.00..20770.00 rows=1000000 width=0) (actual time=0.113..70.956 rows=1000000.00 loops=1)
         Buffers: shared hit=1587 read=9183
         I/O Timings: shared read=0.489
 Planning:
   Buffers: shared hit=53
 Planning Time: 0.067 ms
 Execution Time: 109.096 ms
(10 filas)
```

`1587 + 9183 = 10 770`. Ese número no sale del recuento de filas ni del ancho del `SELECT`: sale de
**cuántas páginas de 8 kB ocupa la tabla en disco**, y en esa unidad se mide todo el bloque. Tres
preguntas antes de hablar de índices: de dónde salen esas páginas, qué hay dentro de una, y por qué
el mismo millón de filas ocupa 84 MB aquí, 71 en MySQL y 66 en SQLite.

---

## 2. 🧱 La página de 8 kB y cuántas filas caben

**Qué es.** PostgreSQL no lee filas del disco: lee **páginas** (*pages*, también llamadas
*bloques*), trozos de tamaño fijo que son la unidad de E/S, de caché y de bloqueo de búfer; el
tamaño se fija al compilar. El catálogo guarda por tabla cuántas ocupa y cuántas filas estima que
hay dentro, y de ahí sale la densidad.

```text
tienda=# SHOW block_size;
 block_size
------------
 8192
(1 fila)

tienda=# SELECT relname, relpages, reltuples::bigint,
tienda-#        round(reltuples/relpages) AS filas_por_pagina,
tienda-#        pg_size_pretty(pg_relation_size(oid)) AS tabla
tienda-#   FROM pg_class
tienda-#  WHERE relname IN ('pedidos','clientes','pedido_lineas','pagos','eventos_pedido','productos')
tienda-#  ORDER BY relpages DESC;
    relname     | relpages | reltuples | filas_por_pagina |  tabla
----------------+----------+-----------+------------------+---------
 eventos_pedido |    82016 |   4100000 |               50 | 641 MB
 pedido_lineas  |    29167 |   3500000 |              120 | 228 MB
 pedidos        |    10770 |   1000000 |               93 | 84 MB
 pagos          |     8232 |    820000 |              100 | 64 MB
 clientes       |      618 |     50000 |               81 | 4944 kB
 productos      |       49 |      5000 |              102 | 392 kB
(6 filas)
```

- `relpages` es el número del `Seq Scan` de §1: **el tamaño del fichero entre 8192**, no un cálculo.
  `reltuples` **es una estimación** del último `ANALYZE`, que aquí coincide con el millón real.

Dentro de una página hay tres zonas: una **cabecera de 24 bytes**, un vector de **punteros de
línea** (*line pointers*) de 4 bytes que crece desde arriba, y las filas, amontonadas desde abajo.
`pageinspect` lo enseña, instalado y deshecho en la misma transacción, que es la regla del bloque.

```text
tienda=# BEGIN;
BEGIN
tienda=*# CREATE EXTENSION pageinspect;
CREATE EXTENSION
tienda=*# SELECT count(*) AS filas, min(lp_len), max(lp_len), round(avg(lp_len)) AS media_lp_len
tienda-*#   FROM heap_page_items(get_raw_page('pedidos', 500));
 filas | min | max | media_lp_len
-------+-----+-----+--------------
    93 |  80 |  88 |           84
(1 fila)

tienda=*# ROLLBACK;
ROLLBACK
```

- 93 filas en la página 500, que es el `filas_por_pagina` del catálogo. **De ahí salen las 10 770
  páginas:** quedan `8192 − 24 = 8168` bytes útiles; cada fila consume su puntero más su ancho, `4 +
  84 = 88`; caben `8168 / 88 = 92,8`; y `1 000 000 / 92,8 = 10 770`.
- **Qué cambia ese número:** el ancho medio de la fila (§4), lo que se va fuera de línea (§5), el
  `fillfactor` y el espacio muerto de `UPDATE` y `DELETE` hasta que `VACUUM` lo recicla. **No** lo
  cambia cuántas columnas pide tu `SELECT`: se lee la página entera.

> **⏱️ Coste.** Como la página es la unidad de E/S, **leer una fila cuesta lo mismo que leer las 93
> que la acompañan**: meter 20 por página en vez de 93 quintuplica cualquier recorrido. Un índice
> gana justo ahí, no leyendo menos filas sino menos páginas. **Veredicto:** la unidad de este bloque
> es la página, no la fila; un coste que no sepas expresar en páginas no lo entendiste.

---

## 3. 🧱 `ctid`: la dirección física de la fila

**Qué es.** `ctid` es una columna de sistema que toda tabla de PostgreSQL tiene sin declararla: el
par **(página, puntero de línea)** donde está físicamente esa versión de la fila, y es lo único que
un índice guarda para volver a la tabla. El `heap` (*montón*) es el fichero donde viven esas
páginas, y el nombre describe el contenido: **no hay ningún orden**.

```text
tienda=# SELECT ctid, id FROM pedidos WHERE id BETWEEN 100 AND 105 ORDER BY id;
   ctid   | id
----------+-----
 (239,92) | 100
 (391,34) | 101
 (388,64) | 102
 (251,37) | 103
 (335,64) | 104
 (435,91) | 105
(6 filas)

tienda=# SELECT count(*) AS paginas_distintas
tienda-#   FROM (SELECT DISTINCT (ctid::text::point)[0] FROM pedidos WHERE id BETWEEN 1 AND 100) x;
 paginas_distintas
-------------------
                89
(1 fila)
```

- **Cien claves consecutivas viven en 89 páginas distintas**: casi una página por fila. Lo resume la
  **correlación**, `0,2225301` para `pedidos.id`, cuyo dueño es
  [`04`](04-estadisticas-y-el-planificador.md) §2.
- **Por qué está así:** la semilla inserta el millón en orden y **después actualiza `total` desde
  las líneas**; ese `UPDATE` reescribió todo y cada fila cayó en el primer hueco libre. El pedido de
  ejemplo acabó en la última página:

```text
tienda=# BEGIN;
BEGIN
tienda=*# SELECT ctid, id, estado FROM pedidos WHERE codigo = 'PED-00042';
    ctid    | id | estado
------------+----+--------
 (10769,20) | 42 | PAGADO
(1 fila)

tienda=*# UPDATE pedidos SET estado = 'ENVIADO' WHERE codigo = 'PED-00042';
UPDATE 1
tienda=*# SELECT ctid, id, estado FROM pedidos WHERE codigo = 'PED-00042';
    ctid    | id | estado
------------+----+---------
 (10769,21) | 42 | ENVIADO
(1 fila)

tienda=*# ROLLBACK;
ROLLBACK
tienda=# SELECT ctid, id, estado FROM pedidos WHERE codigo = 'PED-00042';
    ctid    | id | estado
------------+----+--------
 (10769,20) | 42 | PAGADO
(1 fila)
```

- **El `UPDATE` no modificó la fila: escribió una nueva** en la posición 21, y la vieja siguió en la
  20 hasta que el `ROLLBACK` la devolvió al mando. En PostgreSQL **un `UPDATE` es siempre un
  `INSERT` más un marcado de la versión anterior**, y de ahí las dos facturas del bloque: el espacio
  muerto que reciclar, y que cada índice tenga que apuntar a la dirección nueva.
- Ese mecanismo es **MVCC** (*multiversion concurrency control*, control de concurrencia
  multiversión), el eje del **bloque 04**; aquí solo explica por qué `ctid` se mueve.

> **⚠️ Advertencia.** **Nunca guardes un `ctid` en tu aplicación.** No es un identificador: es una
> dirección que cambia con cada `UPDATE` y con cada `VACUUM FULL`. Para identificar una fila están
> `pedidos.id` y, de cara afuera, `pedidos.codigo`. **Veredicto:** la tabla no tiene orden y los
> índices apuntan a direcciones que se mueven; todo lo demás del bloque sale de esas dos frases.

---

## 4. 🧱 El ancho real de una fila

**Qué es.** Lo que ocupa una fila no es la suma de sus columnas. Lleva delante una **cabecera de 23
bytes** —identificadores de transacción, puntero a la versión siguiente, mapa de nulos—, y entre
columna y columna el motor mete **relleno de alineación** (*padding*) para que cada tipo empiece en
una dirección múltiplo de su tamaño.

```text
tienda=# SELECT pg_column_size(id) AS id, pg_column_size(codigo) AS codigo,
tienda-#        pg_column_size(cliente_id) AS cliente_id, pg_column_size(estado) AS estado,
tienda-#        pg_column_size(total) AS total, pg_column_size(creado_en) AS creado_en,
tienda-#        pg_column_size(actualizado_en) AS actualizado_en, pg_column_size(p.*) AS fila_entera
tienda-#   FROM pedidos p WHERE codigo = 'PED-00042';
 id | codigo | cliente_id | estado | total | creado_en | actualizado_en | fila_entera
----+--------+------------+--------+-------+-----------+----------------+-------------
  8 |     10 |          8 |      7 |     7 |         8 |                | 80
(1 fila)
```

- La suma de columnas es `8 + 10 + 8 + 7 + 7 + 8 = 48` —`actualizado_en` es nulo y no ocupa nada— y
  la fila son **80**. Faltan **32**: **24 son la cabecera**, los 23 de `HeapTupleHeaderData` más un
  byte de mapa de nulos redondeados al múltiplo de 8, y `pageinspect` lo confirma con un `t_hoff` de
  24 en cada fila. **Los 8 restantes son relleno:** `codigo` acaba en el byte 42 y `cliente_id`, que
  es `bigint`, tiene que empezar en múltiplo de 8, así que se pierden 6 hasta el 48; `total` pierde
  1 más y `creado_en` otro. El 10 % de la fila, tirado.

El relleno depende del **orden en que declaraste las columnas**, y eso se mide sin crear nada:

```text
tienda=# SELECT pg_column_size(ROW(1::bigint, 1::smallint, 2::bigint, 2::smallint)) AS alternado,
tienda-#        pg_column_size(ROW(1::bigint, 2::bigint, 1::smallint, 2::smallint)) AS agrupado;
 alternado | agrupado
-----------+----------
        50 |       44
(1 fila)
```

- Mismas columnas, mismos valores, **6 bytes por fila**: alternando ancho y estrecho cada `smallint`
  deja detrás un agujero de 6, y agrupando de mayor a menor los dos comparten uno. **Cuánto
  cuesta:** 6 sobre 44 es un 13,6 %; sobre `pedido_lineas` —3,5 millones de filas, 228 MB— son unos
  30 MB de disco y **un 13 % más de páginas por recorrido**.
- **Cuándo sí** reordenar, y en qué orden: tabla nueva y grande, declarando **de mayor alineación a
  menor y lo de ancho variable al final** —`bigint` y `timestamptz`; luego `integer`; luego
  `smallint`, `boolean` y `char(n)`; y al final `text`, `numeric` y `jsonb`—. **Cuándo no:** en una
  tabla existente, donde exige reescribirla entera. **Quién lo manda:** motor, entero; la regla de
  alineación es la de la plataforma —`d` (8), `i` (4), `s` (2), `c` (1) en `pg_attribute.attalign`—,
  no la de SQL.

---

## 5. 🧱 TOAST: el valor que no cabe

**El problema.** Una fila no puede cruzar el borde de una página: 8 kB es el techo. ¿Qué pasa cuando
`eventos_pedido.carga` trae un `jsonb` de 12 kB? **TOAST** (*The Oversized-Attribute Storage
Technique*) es el almacén fuera de línea de PostgreSQL, y son **dos pasos en orden**: primero
**comprime** los valores anchos, y solo si la fila sigue sin caber los **mueve a una tabla
lateral**, dejando un puntero. Toda tabla con columna de ancho variable nace con la suya.

```text
tienda=# SELECT c.relname, t.relname AS toast,
tienda-#        pg_size_pretty(pg_relation_size(t.oid)) AS tam_toast,
tienda-#        pg_size_pretty(pg_relation_size(c.oid)) AS tam_tabla,
tienda-#        pg_size_pretty(pg_total_relation_size(c.oid)) AS total
tienda-#   FROM pg_class c LEFT JOIN pg_class t ON t.oid = c.reltoastrelid
tienda-#  WHERE c.relname IN ('pedidos','eventos_pedido','clientes') ORDER BY 1;
    relname     |     toast      | tam_toast | tam_tabla |  total
----------------+----------------+-----------+-----------+----------
 clientes       | pg_toast_16516 | 0 bytes   | 4944 kB   | 10064 kB
 eventos_pedido | pg_toast_16620 | 0 bytes   | 641 MB    | 729 MB
 pedidos        | pg_toast_16553 | 0 bytes   | 84 MB     | 136 MB
(3 filas)

tienda=# SELECT min(pg_column_size(carga)) AS min, round(avg(pg_column_size(carga))) AS media,
tienda-#        max(pg_column_size(carga)) AS max FROM eventos_pedido;
 min | media | max
-----+-------+-----
  89 |    98 | 105
(1 fila)
```

- **Las tres tienen tabla TOAST y las tres la tienen vacía.** Los 4,1 millones de `jsonb` miden
  entre 89 y 105 bytes, y la diferencia entre 641 MB y 729 MB son los dos índices. Que
  `pg_total_relation_size` supere a `pg_relation_size` **no es señal de valores fuera de línea**.

El umbral se localiza empujando valores de ancho creciente en una transacción que se deshace.
`lp_len` dice cuánto ocupa la fila **en la página**, que es lo único que decide:

```text
tienda=# BEGIN;
BEGIN
tienda=*# CREATE EXTENSION pageinspect;
CREATE EXTENSION
tienda=*# WITH ruido AS (SELECT string_agg(md5(g::text), '') AS s FROM generate_series(1,400) g)
tienda-*# INSERT INTO eventos_pedido (pedido_id, tipo, carga)
tienda-*# SELECT 42, 'CORTE-'||n, jsonb_build_object('n', left(ruido.s, n))   -- ruido incompresible
tienda-*#   FROM ruido, unnest(ARRAY[1900,2100,12000]) AS n
tienda-*# UNION ALL
tienda-*# SELECT 42, 'REPETIDO', jsonb_build_object('n', repeat('x', 12000)); -- mismo ancho, compresible
INSERT 0 4
tienda=*# SELECT e.tipo, pg_column_size(e.carga) AS ancho_valor,
tienda-*#        length(e.carga::text) AS texto_plano,
tienda-*#        (SELECT h.lp_len FROM heap_page_items(
tienda(*#           get_raw_page('eventos_pedido', (e.ctid::text::point)[0]::int)) h
tienda(*#          WHERE h.lp = (e.ctid::text::point)[1]::int) AS ancho_en_pagina
tienda-*#   FROM eventos_pedido e
tienda-*#  WHERE e.tipo LIKE 'CORTE-%' OR e.tipo = 'REPETIDO' ORDER BY e.tipo;
    tipo     | ancho_valor | texto_plano | ancho_en_pagina
-------------+-------------+-------------+-----------------
 CORTE-12000 |       12013 |       12009 |              80
 CORTE-1900  |        1917 |        1909 |            1984
 CORTE-2100  |        2113 |        2109 |              80
 REPETIDO    |         162 |       12009 |             224
(4 filas)

tienda=*# SELECT count(*) AS trozos_en_toast FROM pg_toast.pg_toast_16620;
 trozos_en_toast
-----------------
               9
(1 fila)

tienda=*# ROLLBACK;
ROLLBACK
```

- **Ahí está el corte.** Con 1 917 bytes de valor la fila sigue entera y ocupa 1 984. Con 2 113 se
  queda en **80 bytes**: el valor se fue a la tabla lateral y solo quedó el puntero. El umbral es
  `TOAST_TUPLE_THRESHOLD`, unos **2 000 bytes**, y se mide sobre **la fila completa**.
- **`REPETIDO` es el primer paso en acción:** los mismos 12 009 caracteres que `CORTE-12000`, pero
  repetidos, comprimen a **162 bytes** y la fila se queda en línea con 224. El ruido de `md5` no
  comprime y se parte en **9 trozos** de ~2 kB, que es como guarda TOAST: troceado y con su índice.
- **Cuánto cuesta:** leer un valor fuera de línea son **dos accesos**, la página del `heap` y los
  trozos por el índice de la TOAST; a cambio la tabla principal queda delgada, y `eventos_pedido`
  cabe a 50 filas por página porque `carga` mide 98 bytes de media. A 6 kB cabría una, y el
  recorrido costaría 80 veces más.
- **Nota honesta de esta edición:** el `ROLLBACK` deshace las filas pero **no devuelve las páginas
  que la TOAST ya reservó**, y solo `VACUUM` las recicla; no se corrió ninguno, porque cambiaría los
  planes del corpus.

> **🧠 Modelo mental.** TOAST no es "PostgreSQL guarda los JSON aparte": es comprimir primero y mover
> después, disparado por el ancho de la **fila completa**.

---

## 6. ⚖️ InnoDB: la tabla **es** el índice primario

El contraste que se pregunta en entrevista es de fondo, no de dialecto: **en InnoDB la fila vive
dentro de las hojas del índice primario**, en páginas de 16 kB, ordenada siempre por la clave
primaria, y un índice secundario guarda **esa clave entera** en vez del `ctid` de 6 bytes. Si no
declaras clave primaria, InnoDB se inventa una oculta. Eso es un **índice agrupado** (*clustered
index*), y de ahí que "el tamaño de la tabla" y "el de la clave primaria" sean el mismo número.

```text
mysql> SELECT TABLE_NAME, TABLE_ROWS, ROUND(DATA_LENGTH/1024/1024) AS datos_mb,
    ->        ROUND(INDEX_LENGTH/1024/1024) AS indices_mb
    ->   FROM information_schema.TABLES WHERE TABLE_SCHEMA='tienda' ORDER BY DATA_LENGTH DESC;
+----------------+------------+----------+------------+
| TABLE_NAME     | TABLE_ROWS | datos_mb | indices_mb |
+----------------+------------+----------+------------+
| eventos_pedido |    3959684 |      567 |         86 |
| pedido_lineas  |    3489504 |      168 |        132 |
| pedidos        |     996132 |       71 |         75 |
| pagos          |     816224 |       58 |         37 |
| clientes       |      49984 |        5 |          5 |
| productos      |       4987 |        0 |          0 |
+----------------+------------+----------+------------+
6 rows in set (0.00 sec)

mysql> SELECT index_name, stat_value AS paginas, ROUND(stat_value*16384/1024/1024) AS mb
    ->   FROM mysql.innodb_index_stats
    ->  WHERE database_name='tienda' AND table_name='pedidos' AND stat_name='size' ORDER BY 2 DESC;
+--------------------+---------+------+
| index_name         | paginas | mb   |
+--------------------+---------+------+
| PRIMARY            |    4519 |   71 |
| codigo             |    2407 |   38 |
| fk_pedidos_cliente |    2405 |   38 |
+--------------------+---------+------+
3 rows in set (0.00 sec)
```

```text
tienda=# SELECT indexrelname AS indice, pg_size_pretty(pg_relation_size(indexrelid)) AS tam
tienda-#   FROM pg_stat_user_indexes WHERE relname='pedidos'
tienda-#  ORDER BY pg_relation_size(indexrelid) DESC;
       indice       |  tam
--------------------+-------
 pedidos_codigo_key | 30 MB
 pedidos_pkey       | 21 MB
(2 filas)
```

- **`PRIMARY` son 71 MB y coinciden exactamente con `DATA_LENGTH`**: no es un índice al lado de la
  tabla, es la tabla. En PostgreSQL son 84 MB de `heap` **más** 21 MB de `pedidos_pkey`, aparte.
- **El índice sobre `codigo` mide 38 MB en InnoDB y 30 MB en PostgreSQL**, con las mismas filas:
  cambia lo que cuelga de cada entrada, el `ctid` de 6 bytes contra los 8 del `BIGINT`. `TABLE_ROWS`
  dice 996 132 porque en InnoDB **es una estimación muestreada**, y MySQL trae además
  `fk_pedidos_cliente`: **InnoDB crea un índice por cada clave foránea** y PostgreSQL no (`03/03`).

**La consecuencia práctica, que es la respuesta que buscan:** como cada índice secundario guarda la
clave primaria entera, **una clave ancha engorda todos los índices secundarios**. Esa misma consulta
a `mysql.innodb_index_stats` sobre `pagos` y `pedido_lineas` lo mide, y las dos tablas tienen un
índice secundario de **una sola columna `BIGINT`**: `fk_pagos_pedido`, que cuelga de una clave de 8
bytes, pesa 18 MB para 816 224 filas —**23 bytes por fila**—; `fk_lineas_producto`, que cuelga de la
compuesta `(pedido_id, linea)`, pesa 132 MB para 3 489 504 filas —**39,5 bytes por fila**—. Un 70 %
más caro por fila, y la única diferencia es el ancho de la clave primaria.
- **Extrapolado al caso que duele:** un `UUIDv4` en `CHAR(36)` mete 36 bytes por entrada en cada
  índice secundario en vez de 8; con tres índices y tres millones de filas, cientos de megabytes
  nuevos. Y hay segunda factura: como la tabla va ordenada por la clave, un UUID aleatorio inserta
  **en medio** y parte páginas, mientras que un entero creciente escribe siempre al final. De ahí la
  regla de InnoDB —clave **estrecha y creciente**— y de ahí UUIDv7.
- **Cuándo gana:** leyendo rangos por la clave primaria; `WHERE pedido_id = 42` sobre
  `pedido_lineas` da las tres líneas de la misma página. **Cuándo pierde:** con claves anchas o
  aleatorias, y con muchos índices secundarios.

> **📜 Estándar o motor.** Nada de esto es del estándar. ISO/IEC 9075 define `PRIMARY KEY` como una
> restricción lógica —unicidad más no nulo— y **no dice una palabra sobre dónde se guardan las
> filas**. Que en InnoDB la clave determine el orden físico y en PostgreSQL no determine nada es
> decisión de cada motor; confundirlo con la norma es el error más caro de este capítulo.

---

## 7. 🧱 SQLite: `rowid` y `WITHOUT ROWID`

SQLite es el tercer modelo, más cerca de InnoDB: **toda tabla es un B-tree ordenado por su
`rowid`**, un entero de 64 bits que el motor mantiene aunque no lo declares, en páginas de 4 kB.

```text
sqlite> pragma page_size;
4096
sqlite> pragma page_count;
218828
sqlite> SELECT rowid, id, codigo FROM pedidos WHERE id = 42;
42|42|PED-00042
sqlite> SELECT name, count(*) AS paginas, round(sum(pgsize)/1024.0/1024,1) AS mb
   ...>   FROM dbstat WHERE name LIKE '%pedido_lineas%' GROUP BY name;
pedido_lineas|21201|82.8
sqlite_autoindex_pedido_lineas_1|13359|52.2
```

- En `pedidos`, `rowid` **es** `id`: `INTEGER PRIMARY KEY` convierte la columna en alias del `rowid`
  y no hay índice aparte. En `pedido_lineas` la clave es compuesta y **no puede ser el `rowid`**:
  SQLite guarda las filas por un `rowid` invisible y fabrica un índice único aparte, que cuesta
  **52,2 MB sobre 82,8 MB de tabla**. Un 63 % extra por un orden que nadie usa.

`WITHOUT ROWID` es la respuesta: guarda la tabla ordenada **por su clave primaria declarada**, como
InnoDB, y el índice auxiliar desaparece. Repetido ese esquema sobre 350 000 líneas reales dentro de
un `BEGIN … ROLLBACK` —dos copias, una normal y otra `WITHOUT ROWID`, medidas con `dbstat` y
deshechas después—, la normal pide **8,0 MB de tabla más 5,1 MB de autoíndice** y la `WITHOUT ROWID`
**8,0 MB y nada más**: un **39 % menos**, y una búsqueda por `(pedido_id, linea)` que deja de dar
dos saltos.

- **Cuándo sí:** clave primaria natural, no entera, y filas estrechas. **Cuándo no:** filas anchas
  —rinde peor cuando la fila media pasa de ~5 % de la página— o clave larga, que se repite en cada
  índice secundario igual que en InnoDB; y ojo, la tabla pierde el `rowid`.

---

## 8. 📜 Estándar, motor y convención

> **📜 Estándar o motor.** **Casi nada de este capítulo está en el estándar, y eso es parte de la
> respuesta:** ISO/IEC 9075 describe un modelo lógico y **el almacenamiento físico es territorio
> exclusivo de cada motor**. Es de pago y **no he verificado ninguna cláusula en esta edición**;
> donde la columna dice *nada*, lo afirmado se midió en sesión.

| Afirmación | Estándar | PostgreSQL 18.6 | MySQL 9.7.2 | SQLite 3.53.4 |
|---|---|---|---|---|
| La E/S va por páginas de tamaño fijo | Nada: no define almacenamiento | Sí, 8 kB (`block_size`) | Sí, 16 kB (`innodb_page_size`) | Sí, 4 kB (`pragma page_size`) |
| Las filas tienen orden físico | Nada; y `SELECT` sin `ORDER BY` no garantiza orden en ninguno | **No**: `heap` desordenado, 89 páginas para 100 claves | Sí: por clave primaria | Sí: por `rowid` |
| Un índice secundario apunta a una dirección de disco | Nada: no define índices de acceso | Sí: `ctid`, 6 bytes | **No**: guarda la clave primaria entera | **No**: guarda el `rowid` |
| Hay una dirección de fila visible | Nada | Sí: `ctid`, y cambia con cada `UPDATE` | No hay equivalente expuesto | Sí: `rowid`, estable salvo `VACUUM` |
| Los valores grandes van fuera de la fila | Nada | Sí: TOAST, umbral ~2 kB; medido 1 917 dentro, 2 113 fuera | Sí: páginas de desbordamiento, según `ROW_FORMAT` | Sí: páginas de desbordamiento encadenadas |
| El orden de declaración afecta al tamaño | Nada | **Sí**: 44 contra 50 bytes, medido | Poco: depende del `ROW_FORMAT` | No: tipado dinámico, sin relleno fijo |
| `PRIMARY KEY` decide dónde se guarda la fila | **No**: es unicidad más no nulo | No decide nada | **Sí**: es el índice agrupado | Sí con `INTEGER PRIMARY KEY` o `WITHOUT ROWID` |

**Convención:** *"la clave primaria es el índice de la tabla"*, que se recita porque casi todo el
mundo aprendió sobre InnoDB o SQL Server, donde lo es. En PostgreSQL `pedidos_pkey` es **un índice
más**, de 21 MB, que podrías borrar —sin la restricción— sin tocar un byte del `heap`. La otra
mitad, *"pon siempre un `id` autoincremental"*, sí tiene justificación física, pero **solo en InnoDB
y en SQLite**: ahí un identificador estrecho y creciente ahorra espacio en cada índice secundario y
evita partir páginas. En PostgreSQL no aplica.

---

## ⚠️ Errores frecuentes

| Se dice | Lo preciso |
|---|---|
| "La clave primaria es el índice de la tabla" | En InnoDB y en SQLite la tabla vive dentro de él. En PostgreSQL es un índice aparte, y el `heap` no tiene orden |
| "Un índice secundario guarda un puntero a la fila" | Solo en PostgreSQL, y es el `ctid`, 6 bytes. En InnoDB guarda la clave primaria entera; en SQLite, el `rowid` |
| "Un `UPDATE` modifica la fila en su sitio" | En PostgreSQL escribe una versión nueva y la vieja queda muerta. Medido: el `ctid` pasa de `(10769,20)` a `(10769,21)` |
| "El tamaño de la fila es la suma de sus columnas" | En `PED-00042` la suma da 48 bytes y la fila ocupa 80: 24 de cabecera y 8 de relleno de alineación |
| "El orden de las columnas da igual" | En PostgreSQL cuesta bytes por fila: las mismas cuatro columnas miden 50 alternadas y 44 agrupadas |
| "PostgreSQL guarda los JSON aparte" | Solo si la fila completa pasa de ~2 kB **y** el valor no comprime: 12 009 caracteres repetidos quedan en 162 bytes, en línea |

---

## 📚 Para profundizar

- **Documentación** — PostgreSQL 18, «Database Page Layout»: cabecera, punteros de línea y los 23
  bytes de `HeapTupleHeaderData`. <https://www.postgresql.org/docs/18/storage-page-layout.html>
- **Documentación** — PostgreSQL 18, «TOAST»: umbral, estrategias `PLAIN`/`MAIN`/`EXTERNAL`/
  `EXTENDED` y troceado. <https://www.postgresql.org/docs/18/storage-toast.html>
- **Documentación** — PostgreSQL 18, «System Columns»: qué es `ctid` y por qué no identifica.
  <https://www.postgresql.org/docs/18/ddl-system-columns.html>
- **Documentación** — PostgreSQL 18, «pageinspect»: `get_raw_page` y `heap_page_items`.
  <https://www.postgresql.org/docs/18/pageinspect.html>
- **Documentación** — MySQL 9.7, «Clustered and Secondary Indexes»: por qué el índice secundario
  guarda la clave primaria. <https://dev.mysql.com/doc/refman/9.7/en/innodb-index-types.html>
- **Documentación** — SQLite, «The WITHOUT ROWID Optimization»: cuándo conviene y sus advertencias.
  <https://www.sqlite.org/withoutrowid.html>
- **Estándar** — ISO/IEC 9075-2 (*Foundation*), `<unique constraint definition>` para `PRIMARY KEY`.
  De pago, sin URL pública y **no verificada en esta edición**; se cita para decir qué **no** fija.

---

## 🧠 Preguntas

1. ¿De qué tamaño es una página en PostgreSQL 18.6, en MySQL 9.7.2 y en SQLite 3.53.4? 🟢
2. ¿Qué guarda un `ctid`, y qué es cada una de sus dos partes? 🟢
3. `pedidos` ocupa 10 770 páginas para un millón de filas: haz la aritmética desde los 8 192. 🟢
4. ¿Qué es el `heap` y qué orden tienen las filas dentro de él? 🟢
5. ¿Qué es TOAST y cuáles son sus dos pasos, en orden? 🟢
6. Distingue `relpages` de `reltuples`: ¿cuál es exacto, cuál estimado, y por qué? 🟡
7. La suma por columna de `PED-00042` da 48 y la fila mide 80. Reparte los 32 bytes que faltan. 🟡
8. ¿Que la clave primaria decida dónde se guarda la fila lo fija el estándar o el motor? Di qué hace
   cada uno de los tres. 🟡
9. `eventos_pedido` pesa 641 MB y tiene tabla TOAST, pero vacía. ¿Es contradictorio? 🟡
10. Cien claves consecutivas viven en 89 páginas distintas: explica por qué, sabiendo cómo se cargó
    la tabla, y di qué métrica del catálogo lo resume. 🟠
11. En InnoDB el índice sobre `codigo` mide 38 MB y en PostgreSQL 30, con las mismas filas: ¿por
    qué? 🟠
12. Un compañero propone `UUIDv4` en `CHAR(36)` como clave primaria en MySQL. Dale las **dos**
    facturas que va a pagar, con el mecanismo de cada una. 🟠
13. ¿Por qué 12 009 caracteres repetidos se quedan en la página y 2 113 de ruido se van fuera? 🟠
14. ¿Que un `UPDATE` reescriba la fila en otra posición lo manda el estándar o es del motor? Di qué
    consecuencia tiene para los índices de esa tabla. 🟠
15. Escribe el DDL de `pedido_lineas` reordenando las columnas para minimizar el relleno de
    alineación en PostgreSQL, y justifica el orden tipo por tipo. 🔴
16. Te dan una tabla de 200 GB donde cada fila trae un `jsonb` de 40 kB y los informes tardan.
    Escribe la secuencia de diagnóstico —qué consultas corres y en qué orden— y las dos hipótesis de
    almacenamiento que confirmarías. 🔴
17. Diseña la demostración que le harías a un entrevistador, en menos de tres minutos y sin dejar
    nada creado, de que en PostgreSQL un `UPDATE` mueve la fila: las sentencias exactas y qué salida
    esperas. 🔴

---

**Anterior:** [README del bloque](README.md) · **Siguiente:** [`02`](02-familias-de-indices.md) ·
**Relacionado:**
[`01/02`](../01-fundamentos-y-modelo-relacional/02-el-modelo-relacional-y-sus-claves.md) — la clave
primaria como restricción lógica · [`02/05`](../02-sql/05-cte-y-recursion.md) — el `Seq Scan` de
10 770 páginas desde el otro lado · el [README del bloque](README.md) — el orden de lectura y la
regla de crear índices dentro de `BEGIN … ROLLBACK`.
