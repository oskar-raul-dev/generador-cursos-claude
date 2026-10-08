# 04 — Estadísticas y el planificador

> De dónde salen los números del plan: la muestra que `ANALYZE` deja en `pg_stats`, cómo una
> frecuencia se convierte en el `rows=` que decide el plan, y las tres formas en que esa estimación
> se separa de la realidad —valor atípico, correlación entre columnas y estadística vieja—. **Asume
> leído:** [`03`](03-compuestos-parciales-y-de-cobertura.md), de donde viene el orden de las
> columnas de un índice. **Vigencia:** 20 de septiembre de 2026.

---

## Salto rápido

[1. El problema](#1--el-problema) · [2. Dónde viven](#2--dónde-viven-las-estadísticas) · [3. De la
frecuencia al `rows=`](#3--de-la-frecuencia-al-rows-del-plan) · [4. Cuántos
cubos](#4--cuántos-cubos-y-cuántos-valores) · [5. Correlación entre
columnas](#5--el-error-de-correlación-entre-columnas) · [6. Estadísticas
viejas](#6--estadísticas-viejas) · [7. Los otros motores](#7-️-los-otros-motores) · [8. Estándar,
motor y convención](#8--estándar-motor-y-convención) · [Errores frecuentes](#️-errores-frecuentes) ·
[Para profundizar](#-para-profundizar) · [Preguntas](#-preguntas)

---

## 1. 🎯 El problema

Un informe cuenta las líneas de un producto concreto que acabaron en pedidos entregados. Nadie tocó
el código ni el esquema, y hoy tarda 187 ms donde antes tardaba una décima parte.

```text
tienda=# EXPLAIN (ANALYZE, COSTS, BUFFERS)
tienda-# SELECT count(*) FROM pedido_lineas pl
tienda-#   JOIN pedidos p ON p.id = pl.pedido_id
tienda-#  WHERE pl.producto_id = 48 AND pl.precio_unit = 117.86
tienda-#    AND p.estado = 'ENTREGADO';
                                                                QUERY PLAN
-------------------------------------------------------------------------------------------------------------------------------------------
 Aggregate  (cost=81878.66..81878.67 rows=1 width=8) (actual time=187.780..187.784 rows=1.00 loops=1)
   Buffers: shared hit=60262 read=29165 dirtied=28
   I/O Timings: shared read=15.825
   ->  Nested Loop  (cost=0.42..81878.60 rows=24 width=0) (actual time=0.178..187.466 rows=4385.00 loops=1)
         Buffers: shared hit=60262 read=29165 dirtied=28
         I/O Timings: shared read=15.825
         ->  Seq Scan on pedido_lineas pl  (cost=0.00..81667.00 rows=80 width=8) (actual time=0.165..144.617 rows=14864.00 loops=1)
               Filter: ((producto_id = 48) AND (precio_unit = 117.86))
               Rows Removed by Filter: 3485136
               Buffers: shared hit=2 read=29165
               I/O Timings: shared read=15.825
         ->  Index Scan using pedidos_pkey on pedidos p  (cost=0.42..2.65 rows=1 width=8) (actual time=0.003..0.003 rows=0.30 loops=14864)
               Index Cond: (id = pl.pedido_id)
               Filter: (estado = 'ENTREGADO'::text)
               Rows Removed by Filter: 1
               Index Searches: 14864
               Buffers: shared hit=60260 dirtied=28
 Planning:
   Buffers: shared hit=387 read=2
   I/O Timings: shared read=0.401
 Planning Time: 1.829 ms
 Execution Time: 187.822 ms
(22 filas)
```

El motor presupuestó **80 filas** para el filtro de `pedido_lineas` y salieron **14 864**: con ese
presupuesto bajar ochenta veces por `pedidos_pkey` salía regalado, y con la cifra real son 14 864
descensos y 60 260 páginas. **El planificador no mide, estima**: elige el plan más barato según un
modelo de costes alimentado por una **muestra estadística**, y cuando la muestra describe mal la
tabla toma una decisión racional y pésima.

---

## 2. 🧱 Dónde viven las estadísticas

`ANALYZE` muestrea la tabla y guarda el resumen en `pg_statistic`; la vista legible es
**`pg_stats`**, el primer sitio al que mirar cuando un `rows=` no cuadra. **Quién lo manda:** motor:
nada de esto existe en el estándar (§8).

```text
tienda=# \x on
Se ha activado el despliegue expandido.
tienda=# SELECT attname, null_frac, avg_width, n_distinct, most_common_vals, most_common_freqs,
tienda-#        histogram_bounds IS NULL AS sin_histograma, correlation
tienda-#   FROM pg_stats
tienda-#  WHERE schemaname = 'public' AND tablename = 'pedidos' AND attname = 'estado';
-[ RECORD 1 ]-----+---------------------------------------------------
attname           | estado
null_frac         | 0
avg_width         | 8
n_distinct        | 5
most_common_vals  | {ENTREGADO,ENVIADO,PAGADO,PENDIENTE,ANULADO}
most_common_freqs | {0.2945,0.27203333,0.2514,0.121533334,0.060533334}
sin_histograma    | t
correlation       | 0.24938495
```

- **`null_frac`** — fracción de filas con `NULL`; cero, porque `estado` es `NOT NULL`.
  **`avg_width`** es el ancho medio en bytes y alimenta el `width=` del plan.
- **`n_distinct`** — cardinalidad. **Positivo es un recuento absoluto** —cinco estados—; **negativo
  es una proporción**, la forma que se usa cuando el número de valores crecerá con la tabla: `-1` es
  "todos distintos", y el `-0,319835` de `pedidos.total`, que el 32 % tiene valor propio.
- **`most_common_vals`** (MCV) y **`most_common_freqs`** — los valores más frecuentes y su
  frecuencia, en el mismo orden; la pareja que hace la mayor parte del trabajo. `ENTREGADO` sale con
  `0,2945` y el reparto real son 300 000 de 1 000 000: **29,45 % estimado contra 30 % real**.
- **`histogram_bounds`** — cotas de un histograma **equipoblado**: cada tramo tiene aproximadamente
  la misma cantidad de filas, no el mismo rango. Es nulo aquí porque el histograma solo describe lo
  que el MCV no cubre, y estos cinco valores ya están dentro.
- **`correlation`** — correlación entre el orden lógico de **una** columna y el orden físico en
  disco, de `-1` a `1`. Decide cuántas páginas cree el motor que saltará en un `Index Scan`.

Con cardinalidad alta la foto se invierte: el MCV se vacía y aparece el histograma. La misma
consulta sobre `pedido_lineas.producto_id` devuelve `n_distinct = 4984`, **56** valores en el MCV
—de un límite de 100: el motor guarda *hasta* cien, no cien siempre— encabezados por `17` con
`0,005566667` y `48` con `0,004766667`, y **101 cotas, que son 100 tramos**, más anchos donde hay
menos filas por valor: eso es ser *equipoblado*. Sobre `pedidos.cliente_id`, con 47 988 clientes y
30 000 filas de muestra, solo **dos** valores llegaron al MCV, con `0,0002` cada uno.

> **⚠️ Advertencia.** `pedidos.id` sale con `correlation` **0,2225**, no 1, aunque la carga insertó
> los pedidos en orden de `id`: el `UPDATE` que rellenó `pedidos.total` reescribió todas las filas.
> Un `UPDATE` masivo destruye la correlación física de la tabla entera, no solo de esa columna.

> **Veredicto:** antes de discutir un plan, mira `pg_stats` de las columnas del `WHERE`. El plan es
> la consecuencia; esa fila es la causa.

---

## 3. 🧱 De la frecuencia al `rows=` del plan

**Selectividad** es la fracción de filas que el planificador cree que pasarán un filtro; el `rows=`
del plan es esa fracción por las filas que cree que tiene la tabla. Con un valor frecuente sale del
MCV, directamente:

```text
tienda=# EXPLAIN (ANALYZE, COSTS, BUFFERS) SELECT count(*) FROM pedidos WHERE estado = 'ENTREGADO';
                                                        QUERY PLAN
--------------------------------------------------------------------------------------------------------------------------
 Aggregate  (cost=29016.96..29016.97 rows=1 width=8) (actual time=156.312..156.317 rows=1.00 loops=1)
   Buffers: shared hit=15287 read=76
   I/O Timings: shared read=27.495
   ->  Seq Scan on pedidos  (cost=0.00..28257.47 rows=303794 width=0) (actual time=0.318..140.298 rows=300000.00 loops=1)
         Filter: (estado = 'ENTREGADO'::text)
         Rows Removed by Filter: 700000
         Buffers: shared hit=15287 read=76
         I/O Timings: shared read=27.495
 Planning:
   Buffers: shared hit=80
 Planning Time: 0.207 ms
 Execution Time: 156.376 ms
(12 filas)
```

**`rows=303794` sale de `most_common_freqs`**: `0,2945` por las filas que el planificador cree que
hay, 1 031 558 —`reltuples`, que vale 1 000 000 exactos, reescalado por el tamaño físico de hoy: 15
363 páginas contra las 14 893 anotadas en `pg_class`—; `0,2945 × 1 031 558 = 303 794`, **1,3 % de
error**. El valor raro va por otro camino: fuera del MCV se aplica la frecuencia media de lo que el
MCV no cubre, `(1 − Σ most_common_freqs) / (n_distinct − n_mcv) = (1 − 0,0004) / (47 988 − 2) = 2,08
× 10⁻⁵`. El mismo `EXPLAIN` sobre `WHERE cliente_id = 311` presupuesta **`rows=22` y devuelve 52
filas en 48 ms**: **2,4 veces de error** contra el 1,3 % del valor frecuente.

`CLI-00311` es atípico —52 pedidos— y ningún atípico fuera del MCV se estima bien: por definición se
le aplica la media de los demás. **Cuánto cuesta:** aquí nada, porque sin índice los dos planes son
el mismo `Seq Scan`; con un índice, ese `rows=` decide entre bajar por él y barrer la tabla, y entre
`Nested Loop` y `Hash Join`, como en §1. Cómo se lee el árbol es de
[`05`](05-explain-y-explain-analyze.md).

> **🧠 Modelo mental.** El planificador no compara consultas: compara **presupuestos**. `rows=` es el
> presupuesto, y `cost`, la forma del `JOIN` y el orden de las tablas se derivan de él.

---

## 4. 🧱 Cuántos cubos y cuántos valores

**Cien significa dos cosas a la vez: hasta 100 valores en el MCV y hasta 100 tramos de histograma.**
Y una tercera, indirecta: `ANALYZE` muestrea **300 × el objetivo**, 30 000 filas, el 0,86 % de los
3,5 millones de `pedido_lineas`. **Quién lo manda:** motor; subirlo se mide, no se supone.

```text
tienda=# SHOW default_statistics_target;
 default_statistics_target
---------------------------
 100
(1 fila)

tienda=# \timing on
El despliegue de duración está activado.
tienda=# BEGIN;
BEGIN
tienda=*# ANALYZE pedido_lineas;
ANALYZE
Duración: 174,236 ms
tienda=*# SET default_statistics_target = 1000;
SET
tienda=*# ANALYZE pedido_lineas;
ANALYZE
Duración: 649,091 ms
tienda=*# SELECT array_length(most_common_vals::text::text[],1) AS n_mcv,
tienda-*#        array_length(histogram_bounds::text::text[],1) AS n_cotas
tienda-*#   FROM pg_stats WHERE tablename='pedido_lineas' AND attname='producto_id';
 n_mcv | n_cotas
-------+---------
   115 |    1001
(1 fila)

tienda=*# ROLLBACK;
ROLLBACK
```

- **Lo que se gana:** el MCV de `producto_id` pasa de 56 valores a 115 y el histograma de 100 tramos
  a 1 000; más valores con frecuencia propia son menos valores estimados por la media, que es el
  error de `CLI-00311` en §3. **Lo que cuesta, medido:** ese `ANALYZE` pasa de **174 ms a 649 ms**,
  3,7 veces, y **cada planificación se hace más lenta**, porque recorre arrays de 1 000 elementos.
- **Cuándo sí:** una columna con muchos valores distintos y reparto desigual, y **por columna**, con
  `ALTER TABLE … ALTER COLUMN … SET STATISTICS n`. **Cuándo no:** global, o "por si acaso".
- **Teardown:** el `ROLLBACK` devuelve las estadísticas a 56 y 101; `ANALYZE` es transaccional en
  PostgreSQL y se deshace como cualquier escritura.

---

## 5. 🩺 El error de correlación entre columnas

Es el fallo caro, y el que abrió el capítulo. **El planificador asume independencia entre
columnas**: para `WHERE a = 1 AND b = 2` multiplica las dos selectividades, y si están relacionadas
el producto sale absurdamente pequeño. Aquí la dependencia la trae la semilla:
`pedido_lineas.precio_unit` se copió del precio del producto en el momento de la compra, así que
**`producto_id` determina `precio_unit`**.

```text
tienda=# SELECT precio_unit, count(*) FROM pedido_lineas WHERE producto_id = 48 GROUP BY 1;
 precio_unit | count
-------------+-------
      117.86 | 14864
(1 fila)
```

Un solo precio para las 14 864 líneas del producto 48. El `Seq Scan` de §1 lo estimó en **80
filas**: `producto_id = 48` sale de su MCV con `0,004766667`, `precio_unit = 117.86` del suyo, y
multiplicarlas da 186 veces menos de lo que hay. El error no está en ninguna de las dos estimaciones
sino en multiplicarlas: el segundo filtro no descarta nada que el primero no descartara ya.

```text
tienda=# BEGIN;
BEGIN
tienda=*# CREATE STATISTICS st_linea_producto_precio (dependencies)
tienda-*#   ON producto_id, precio_unit FROM pedido_lineas;
CREATE STATISTICS
tienda=*# ANALYZE pedido_lineas;
ANALYZE
tienda=*# SELECT dependencies FROM pg_stats_ext WHERE statistics_name = 'st_linea_producto_precio';
               dependencies
------------------------------------------
 {"3 => 5": 0.993600, "5 => 3": 0.890933}
(1 fila)

tienda=*# EXPLAIN (ANALYZE, COSTS, BUFFERS)
tienda-*# SELECT count(*) FROM pedido_lineas WHERE producto_id = 48 AND precio_unit = 117.86;
                                                          QUERY PLAN
------------------------------------------------------------------------------------------------------------------------------
 Aggregate  (cost=81708.15..81708.16 rows=1 width=8) (actual time=129.263..129.263 rows=1.00 loops=1)
   Buffers: shared hit=1196 read=27971
   I/O Timings: shared read=0.819
   ->  Seq Scan on pedido_lineas  (cost=0.00..81667.00 rows=16461 width=0) (actual time=0.095..128.583 rows=14864.00 loops=1)
         Filter: ((producto_id = 48) AND (precio_unit = 117.86))
         Rows Removed by Filter: 3485136
         Buffers: shared hit=1196 read=27971
         I/O Timings: shared read=0.819
 Planning:
   Buffers: shared hit=28
 Planning Time: 0.092 ms
 Execution Time: 129.280 ms
(12 filas)

tienda=*# ROLLBACK;
ROLLBACK
```

- **`rows=80` pasa a `rows=16461`, contra 14 864 reales**: el error cae de **186 veces a un 11 %**,
  en el mismo nodo y con el mismo filtro que en §1.
- `pg_stats_ext` se lee por número de columna: **`"3 => 5": 0.9936`** es *`producto_id` (attnum 3)
  determina `precio_unit` (attnum 5) con grado 0,9936*. No llega a 1 porque el corpus reasignó
  líneas a `PRD-00017` sin tocar su precio; la inversa vale 0,89, porque hay precios repetidos.
- **Sigue siendo una muestra.** Repitiendo el mismo `ANALYZE` en otra transacción la estimación
  salió **13 099** en vez de 16 461, contra las mismas 14 864 reales: no la hacen exacta, la ponen
  en el orden de magnitud correcto, que es lo que cambia el plan.
- **Cuánto cuesta:** una entrada más en cada `ANALYZE` y algo de planificación; en disco, nada.
  **Cuándo sí:** columnas de la misma tabla que aparecen juntas en el `WHERE`. **Cuándo no:**
  columnas de tablas distintas, que `CREATE STATISTICS` no cruza.
- **Teardown:** `ROLLBACK`, y `pg_statistic_ext` vuelve a cero filas; dejarla cambiaría los planes
  de los demás capítulos.

> **🩺 Diagnóstico.** Compara el `rows=` estimado con el real en el nodo de más abajo. Si la
> diferencia es de dos órdenes de magnitud y el filtro toca dos columnas de la misma tabla, sospecha
> de la independencia asumida antes que del índice.

---

## 6. 🩺 Estadísticas viejas

La otra forma de equivocarse no necesita correlación: basta con que los datos hayan cambiado desde
el último `ANALYZE`. Se reproduce entera en una transacción, incluido el `ANALYZE` que la corrige.

```text
tienda=# BEGIN;
BEGIN
tienda=*# INSERT INTO pedidos (codigo, cliente_id, estado, total, creado_en)
tienda-*# SELECT 'PED-T' || g, 311, 'PENDIENTE', 10.00, timestamptz '2026-01-01'
tienda-*# FROM generate_series(1, 300000) AS g;
INSERT 0 300000
Duración: 2624,154 ms (00:02,624)
tienda=*# EXPLAIN (ANALYZE, COSTS) SELECT count(*) FROM pedidos WHERE estado = 'PENDIENTE';
                                                        QUERY PLAN
--------------------------------------------------------------------------------------------------------------------------
 Aggregate  (cost=30772.14..30772.15 rows=1 width=8) (actual time=214.572..214.574 rows=1.00 loops=1)
   Buffers: shared hit=17640
   ->  Seq Scan on pedidos  (cost=0.00..30460.51 rows=124650 width=0) (actual time=0.042..196.425 rows=420000.00 loops=1)
         Filter: (estado = 'PENDIENTE'::text)
         Rows Removed by Filter: 880000
         Buffers: shared hit=17640
 Planning:
   Buffers: shared hit=15
 Planning Time: 0.237 ms
 Execution Time: 214.611 ms
(10 filas)

tienda=*# ANALYZE pedidos;
ANALYZE
Duración: 150,683 ms
tienda=*# EXPLAIN (ANALYZE, COSTS) SELECT count(*) FROM pedidos WHERE estado = 'PENDIENTE';
                                                       QUERY PLAN
-------------------------------------------------------------------------------------------------------------------------
 Aggregate  (cost=34938.78..34938.79 rows=1 width=8) (actual time=105.052..105.053 rows=1.00 loops=1)
   Buffers: shared hit=17640
   ->  Seq Scan on pedidos  (cost=0.00..33890.00 rows=419510 width=0) (actual time=0.013..89.165 rows=420000.00 loops=1)
         Filter: (estado = 'PENDIENTE'::text)
         Rows Removed by Filter: 880000
         Buffers: shared hit=17640
 Planning:
   Buffers: shared hit=15
 Planning Time: 0.099 ms
 Execution Time: 105.077 ms
(10 filas)

tienda=*# ROLLBACK;
ROLLBACK
```

- **`rows=124650` contra 420 000 reales**, 3,4 veces de error: el MCV todavía cree que `PENDIENTE`
  es el 12,15 % de la tabla cuando ya es el 32 %. Subió algo sobre los 121 533 teóricos porque el
  reescalado por tamaño físico de §3 nota que la tabla creció; lo que no se enteró son las
  frecuencias. Tras `ANALYZE`: **419 510 contra 420 000**, 0,1 % de error, en 150 ms.
- **Por qué pasa con autovacuum encendido.** El demonio corre `ANALYZE` solo, pero con umbral:
  `autovacuum_analyze_threshold = 50` más `autovacuum_analyze_scale_factor = 0.1`, o sea **50 + 10 %
  de las filas**, y luego hasta `autovacuum_naptime = 60` segundos de espera. Un millón de pedidos
  necesita 100 050 modificaciones: una carga nocturna de 90 000 filas no lo dispara **nunca**. Peor
  es `pg_restore`, que deja la base sin estadística ninguna.
- **Teardown:** `ROLLBACK` deshace las 300 000 filas **y el `ANALYZE`**.

---

## 7. ⚖️ Los otros motores

InnoDB no guarda histogramas por columna: **estima muestreando páginas del índice**, veinte por
defecto —`innodb_stats_persistent_sample_pages = 20`—, y de ahí saca una cardinalidad aproximada que
refresca sola.

```text
mysql> SELECT INDEX_NAME, COLUMN_NAME, CARDINALITY FROM information_schema.STATISTICS
    ->  WHERE TABLE_SCHEMA='tienda' AND TABLE_NAME='pedidos';
+--------------------+-------------+-------------+
| INDEX_NAME         | COLUMN_NAME | CARDINALITY |
+--------------------+-------------+-------------+
| codigo             | codigo      |      974338 |
| fk_pedidos_cliente | cliente_id  |       48309 |
| PRIMARY            | id          |      996132 |
+--------------------+-------------+-------------+
```

La tabla tiene **exactamente** un millón de filas y todos los `codigo` son distintos; InnoDB dice
996 132 y 974 338. No es un error: es lo que se ve desde veinte páginas, y para elegir un índice
sobra con el orden de magnitud. Para una columna **sin** índice no hay nada —`estado` no lo está—, y
sin histograma MySQL aplica su conjetura fija para una igualdad, el 10 %. Los histogramas llegaron
en 8.0 y **hay que crearlos a mano**.

```text
mysql> EXPLAIN SELECT COUNT(*) FROM pedidos WHERE estado='ENTREGADO';
+-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------+
| EXPLAIN                                                                                                                                                                           |
+-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------+
| -> Aggregate: count(0)  (cost=123640 rows=1)
    -> Filter: (pedidos.estado = 'ENTREGADO')  (cost=100698 rows=99568)
        -> Table scan on pedidos  (cost=100698 rows=995684)
 |
+-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------+

mysql> ANALYZE TABLE pedidos UPDATE HISTOGRAM ON estado WITH 5 BUCKETS;
+----------------+-----------+----------+---------------------------------------------------+
| Table          | Op        | Msg_type | Msg_text                                          |
+----------------+-----------+----------+---------------------------------------------------+
| tienda.pedidos | histogram | status   | Histogram statistics created for column 'estado'. |
+----------------+-----------+----------+---------------------------------------------------+

mysql> SELECT JSON_UNQUOTE(JSON_EXTRACT(HISTOGRAM,'$.buckets')) AS cubos
    ->   FROM information_schema.COLUMN_STATISTICS WHERE SCHEMA_NAME='tienda';
+---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------+
| cubos                                                                                                                                                                                                                                                   |
+---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------+
| [["base64:type254:QU5VTEFETw==", 0.058836952801125775], ["base64:type254:RU5UUkVHQURP", 0.3583590055654864], ["base64:type254:RU5WSUFETw==", 0.629800073530344], ["base64:type254:UEFHQURP", 0.8799046641057823], ["base64:type254:UEVORElFTlRF", 1.0]] |
+---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------+

mysql> EXPLAIN SELECT COUNT(*) FROM pedidos WHERE estado='ENTREGADO';
+------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------+
| EXPLAIN                                                                                                                                                                            |
+------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------+
| -> Aggregate: count(0)  (cost=169415 rows=1)
    -> Filter: (pedidos.estado = 'ENTREGADO')  (cost=100698 rows=298229)
        -> Table scan on pedidos  (cost=100698 rows=995684)
 |
+------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------+

mysql> ANALYZE TABLE pedidos DROP HISTOGRAM ON estado;
+----------------+-----------+----------+---------------------------------------------------+
| Table          | Op        | Msg_type | Msg_text                                          |
+----------------+-----------+----------+---------------------------------------------------+
| tienda.pedidos | histogram | status   | Histogram statistics removed for column 'estado'. |
+----------------+-----------+----------+---------------------------------------------------+
```

- **`rows=99568` era el 10 % de 995 684**, la conjetura. Con histograma pasa a **`rows=298229`**
  contra 300 000 reales: la conjetura erraba 3 veces, el histograma yerra el 0,6 %.
- Los cubos `singleton` son el equivalente del MCV de PostgreSQL —uno por valor distinto—, pero con
  la **frecuencia acumulada**: `ENTREGADO` va de `0,05884` a `0,35836`, o sea `0,29952`, y `0,29952
  × 995 684 = 298 229`. El base64 es por ser columna de texto.
- **El DDL de MySQL confirma y no hay `ROLLBACK` que valga**, así que el histograma se borra a mano
  con el `DROP HISTOGRAM` de arriba. **Cuánto cuesta:** se calcula en memoria hasta
  `histogram_generation_max_mem_size`, 20 MB por defecto; no se refresca solo, y cada pasada vuelve
  a muestrear —dos creaciones anteriores dieron 299 372 y 297 679—.

SQLite es el extremo opuesto: **no tiene estadísticas hasta que corres `ANALYZE`**, y cuando las
tiene las guarda en tablas normales de la base.

```text
sqlite> SELECT tbl, idx, stat FROM sqlite_stat1 ORDER BY tbl, idx;
     tbl                      idx                    stat
--------------  --------------------------------  -----------
clientes        sqlite_autoindex_clientes_1       50000 1
clientes        sqlite_autoindex_clientes_2       50000 1
eventos_pedido                                    4100000
pagos           sqlite_autoindex_pagos_1          820000 2
pedido_lineas   sqlite_autoindex_pedido_lineas_1  3500000 4 1
pedidos         sqlite_autoindex_pedidos_1        1000000 1
productos       sqlite_autoindex_productos_1      5000 1
```

- `stat` es **las filas de la tabla y la media que devuelve cada prefijo del índice**, exacta y no
  muestreada: `3500000 4 1` son 3,5 millones de filas, 4 por `pedido_id` y 1 por par `(pedido_id,
  linea)`.
- Con `sqlite_stat4` —esta base la trae, 24 muestras por tabla— se estima por valor y no solo por
  media. **Sin `ANALYZE` no existe ninguna de las dos**, y SQLite planifica con conjeturas fijas.

---

## 8. 📜 Estándar, motor y convención

> **📜 Estándar o motor.** ISO/IEC 9075 es de pago y **no he verificado sus cláusulas**, pero la
> columna "Estándar" no es una laguna sino una respuesta: la norma define **qué resultado devuelve
> una consulta, no cómo se ejecuta**. No hay `ANALYZE`, ni estadísticas, ni planificador, ni
> `EXPLAIN` en el SQL estándar.

| Afirmación | Estándar | PostgreSQL 18.6 | MySQL 9.7.2 | SQLite 3.53.4 |
|---|---|---|---|---|
| Existe `ANALYZE` para recoger estadísticas | No lo define | `ANALYZE [tabla]` | `ANALYZE TABLE tabla` | `ANALYZE` |
| Hay histogramas por columna | No lo define | Sí, siempre, con `ANALYZE` | Solo si se crean a mano, desde 8.0 | Solo en `sqlite_stat4`, y por índice |
| Se recogen solas | No lo define | Sí: autovacuum, umbral 50 + 10 % | Cardinalidad de índice sí (`innodb_stats_auto_recalc`); histogramas **no** | **No**, nunca |
| La estimación es exacta | No lo define | No: muestra de 300 × `default_statistics_target` | No: muestreo de 20 páginas de índice | Sí en `sqlite_stat1`: recorre el índice entero |
| Se puede declarar correlación entre columnas | No lo define | Sí: `CREATE STATISTICS … (dependencies)` | No | No |
| `ANALYZE` se puede deshacer | No lo define | **Sí**: es transaccional, muere con el `ROLLBACK` | **No**: el DDL confirma de forma implícita | No en la práctica |
| Se leen en SQL | No lo define | `pg_stats`, `pg_stats_ext` | `COLUMN_STATISTICS`, `SHOW INDEX` | `sqlite_stat1`, `sqlite_stat4` |

**Convención:** *"hay que correr `ANALYZE` a mano después de cada carga"*. Comprobado contra el
autovacuum de este entorno, es **cierto a medias**: falso como rutina general, porque los valores
por defecto mantienen al día cualquier tabla con escritura normal; cierto y obligatorio **tras una
carga masiva o una restauración**, y **en una tabla grande alimentada por lotes pequeños**, donde el
10 % de un millón de filas no se alcanza nunca.

---

## ⚠️ Errores frecuentes

| Se dice | Lo preciso |
|---|---|
| "El planificador sabe cuántas filas hay" | No lo sabe: lo estima desde una muestra de 300 × `default_statistics_target` filas. En §1 presupuestó 80 y salieron 14 864 |
| "Si el plan es malo, falta un índice" | En §1 el índice existía —`pedidos_pkey`— y el problema era el `rows=` del otro lado del `JOIN`. Primero se compara estimado contra real |
| "Subir `default_statistics_target` siempre mejora" | Mejora la estimación y empeora lo demás: el `ANALYZE` de `pedido_lineas` pasa de 174 ms a 649 ms, y cada planificación recorre arrays diez veces más largos |
| "Con autovacuum no hace falta tocar nada" | El umbral es 50 + 10 % de las filas: un millón de pedidos necesita 100 050 modificaciones, y una carga de 90 000 filas no lo dispara nunca |
| "MySQL tiene histogramas como PostgreSQL" | Los tiene desde 8.0 pero no los crea ni los refresca solo. Sin él, una igualdad sobre columna no indexada se estima al 10 %: 99 568 contra 300 000 reales |

---

## 📚 Para profundizar

- **Documentación** — PostgreSQL 18, «Statistics Used by the Planner»: `n_distinct`, MCV, histograma
  y `correlation`. <https://www.postgresql.org/docs/18/planner-stats.html>
- **Documentación** — PostgreSQL 18, «How the Planner Uses Statistics»: la aritmética de la
  selectividad de §3. <https://www.postgresql.org/docs/18/planner-stats-details.html>
- **Documentación** — PostgreSQL 18, `CREATE STATISTICS`: `dependencies`, `ndistinct` y `mcv`.
  <https://www.postgresql.org/docs/18/sql-createstatistics.html>
- **Documentación** — MySQL 9.7, «Optimizer Statistics»: histogramas y `COLUMN_STATISTICS`.
  <https://dev.mysql.com/doc/refman/9.7/en/optimizer-statistics.html>
- **Documentación** — SQLite, «The ANALYZE Command»: `sqlite_stat1`, `sqlite_stat4` y el formato de
  `stat`. <https://www.sqlite.org/lang_analyze.html>
- **Libro** — Markus Winand, *SQL Performance Explained*, self-published, 2012, capítulo 1.

---

## 🧠 Preguntas

1. ¿Qué hace exactamente `ANALYZE` y dónde deja lo que recoge? 🟢
2. ¿Qué columnas de `pg_stats` usa el planificador al estimar una igualdad, y qué guarda cada una? 🟢
3. ¿Qué significa un `n_distinct` negativo, y por qué PostgreSQL lo escribe así a veces? 🟢
4. ¿Qué dos cosas fija `default_statistics_target = 100`, y cuántas filas muestrea `ANALYZE`? 🟢
5. En §2, `pedidos.estado` tiene `histogram_bounds` nulo. ¿Por qué? 🟢
6. Distingue selectividad de cardinalidad, y di cuál de las dos aparece en el `rows=` del plan. 🟡
7. Un histograma equipoblado y uno de rangos iguales: ¿en qué se diferencian, y por qué el
   planificador quiere el primero? 🟡
8. ¿Qué mide `correlation` en `pg_stats`? Nombra las dos cosas con las que se confunde. 🟡
9. ¿El estándar SQL define `ANALYZE`, los histogramas o el planificador? Di qué hace cada motor. 🟡
10. Distingue el error de §3 —`rows=22` contra 52— del error de §5 —`rows=80` contra 14 864—. 🟡
11. ¿Por qué el `rows=` de `ENTREGADO` salió 303 794 y no 294 500, si `most_common_freqs` dice
    0,2945 y la tabla tiene un millón de filas? 🟠
12. Tu tabla tiene 40 millones de filas y recibe 200 000 modificaciones al día. Con el autovacuum
    por defecto, ¿cuándo corre el próximo `ANALYZE`? Haz la cuenta. 🟠
13. Justifica con los dos números medidos en §4 por qué subir `default_statistics_target` a 1 000 en
    toda la base es mala idea. 🟠
14. La estadística extendida bajó el error de 186 veces al 11 %, y un segundo `ANALYZE` dio 13 099
    en vez de 16 461. ¿Por qué no queda exacto, y por qué da igual? 🟠
15. ¿Que `ANALYZE` se pueda deshacer con un `ROLLBACK` es cosa del estándar o del motor? Di qué hace
    cada uno y qué consecuencia tiene al escribir un capítulo de este corpus. 🟠
16. Un compañero dice que MySQL "ya tiene histogramas como Postgres". Corrígelo con los dos
    `EXPLAIN` de §7 y di qué hay que hacer a mano. 🟠
17. Una consulta que iba a 50 ms tarda 8 segundos y nadie tocó el código ni el esquema. Da tres
    hipótesis en orden de probabilidad y, para cada una, la consulta que la confirma. 🔴
18. Escribe la secuencia completa —SQL incluido— para diagnosticar y corregir un `Nested Loop` que
    hace 14 864 `Index Searches` donde el plan presupuestó 80, sin crear un solo índice. 🔴
19. Un despliegue restaura la base con `pg_restore` a las 3:00 y a las 3:05 el primer informe tarda
    veinte minutos. Explica qué pasó, qué añadirías al despliegue y qué consulta te lo habría dicho
    en diez segundos. 🔴

---

**Anterior:** [`03`](03-compuestos-parciales-y-de-cobertura.md) · **Siguiente:**
[`05`](05-explain-y-explain-analyze.md) — cómo se lee el árbol que aquí solo sirve de evidencia ·
**Relacionado:** [`06`](06-cuando-el-indice-no-se-usa.md) — las seis razones por las que un índice
no se usa, de las que esta es la cuarta.
