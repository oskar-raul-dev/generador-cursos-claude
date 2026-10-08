# 02 — Familias de índices

> Un índice no es "más rápido": es una estructura de datos con una forma concreta, y esa forma
> decide qué preguntas puede responder y cuáles no. Aquí están las cinco familias de PostgreSQL
> —B-tree, hash, GIN, GiST y BRIN—, medidas contra el millón de pedidos y los cuatro millones de
> eventos. **Asume leído:** [`01`](01-como-se-almacena-una-tabla.md) — de ahí vienen la página de 8
> kB y el heap al que apunta un índice. **Vigencia:** 20 de septiembre de 2026.

---

## Salto rápido

- [1. El problema](#1--el-problema) · [2. B-tree](#2--b-tree-mantiene-el-orden)
- [3. Hash](#3--hash-solo-igualdad) · [4. GIN](#4--gin-indexa-las-partes)
- [5. GiST](#5--gist-el-que-no-puedo-demostrar) · [6. BRIN](#6--brin-40-kb-y-la-correlación)
- [7. Motores](#7-️-el-contraste-de-motor) · [8. Estándar](#8--estándar-motor-y-convención)
- [Errores](#️-errores-frecuentes) · [Referencias](#-para-profundizar) · [Preguntas](#-preguntas)

---

## 1. 🎯 El problema

La pantalla de "mis pedidos" pide los pedidos de un cliente: veinticinco filas. El esquema del
corpus llega sin un solo índice más allá de los once de `PRIMARY KEY` y `UNIQUE`, así que el motor
hace esto:

```text
tienda=# EXPLAIN (ANALYZE, COSTS, BUFFERS)
tienda-# SELECT id, codigo, total FROM pedidos WHERE cliente_id = 4210;
                                                 QUERY PLAN
------------------------------------------------------------------------------------------------------------
 Seq Scan on pedidos  (cost=0.00..23270.00 rows=21 width=25) (actual time=0.686..43.653 rows=25.00 loops=1)
   Filter: (cliente_id = 4210)
   Rows Removed by Filter: 999975
   Buffers: shared hit=10770
 Planning:
   Buffers: shared hit=86
 Planning Time: 0.177 ms
 Execution Time: 43.684 ms
(8 filas)

Duración: 44,923 ms
```

Para devolver 25 filas el motor leyó **10 770 páginas de 8 kB —los 84 MB de la tabla entera— y tiró
999 975 filas por el camino**. La respuesta obvia es "ponle un índice"; la útil es otra: **¿cuál?**
`SELECT amname FROM pg_am WHERE amtype='i'` devuelve seis métodos de acceso en PostgreSQL 18.6
—`brin`, `btree`, `gin`, `gist`, `hash` y `spgist`— y no son variantes del mismo truco. Un B-tree
responde igualdad **y** rango, porque mantiene el orden; un hash solo igualdad, porque no lo
mantiene; un GIN responde "¿cuál de estos documentos contiene esta pareja clave-valor?", porque
indexa las partes y no el valor; un BRIN no sabe dónde está nada, solo descarta zonas del disco, y
únicamente si los datos ya están ordenados en él. **SPGiST queda fuera**: es la variante
particionada de GiST, comparte su caso de uso, y el dominio no da un ejemplo honesto de ninguna de
las dos (§5).

> **⚠️ Advertencia.** Todos los índices de aquí se crean **dentro de `BEGIN … ROLLBACK`**.
> PostgreSQL tiene DDL transaccional: el índice existe para la sesión que lo creó, sirve para medir
> y desaparece al deshacer. Ninguno queda confirmado, y al cerrar la edición `pg_indexes` vuelve a
> dar once. Un índice confirmado cambiaría los planes pegados en el resto del corpus.

---

## 2. 🧱 B-tree: mantiene el orden

**Qué es.** Un árbol equilibrado cuyas hojas guardan los valores **ordenados** y encadenados entre
sí: bajar cuesta la altura del árbol —tres o cuatro páginas con un millón de filas— y, una vez
abajo, seguir la cadena de hojas da los siguientes en orden sin volver a subir. Es el índice por
defecto: `CREATE INDEX … ON tabla (columna)` sin más palabras crea un B-tree.

```text
tienda=# BEGIN;
BEGIN
tienda=*# CREATE INDEX pedidos_cliente_id_btree ON pedidos (cliente_id);
CREATE INDEX
Duración: 169,145 ms
tienda=*# ANALYZE pedidos;
ANALYZE
Duración: 122,827 ms
tienda=*# SELECT pg_size_pretty(pg_relation_size('pedidos_cliente_id_btree')) AS indice,
tienda-*#        pg_size_pretty(pg_relation_size('pedidos')) AS tabla;
 indice  | tabla
---------+-------
 7800 kB | 84 MB
(1 fila)

tienda=*# EXPLAIN (ANALYZE, COSTS, BUFFERS)
tienda-*# SELECT id, codigo, total FROM pedidos WHERE cliente_id = 4210;
                                                               QUERY PLAN
-----------------------------------------------------------------------------------------------------------------------------------------
 Index Scan using pedidos_cliente_id_btree on pedidos  (cost=0.42..24.99 rows=21 width=25) (actual time=0.072..0.108 rows=25.00 loops=1)
   Index Cond: (cliente_id = 4210)
   Index Searches: 1
   Buffers: shared hit=28 read=3
   I/O Timings: shared read=0.047
 Planning:
   Buffers: shared hit=21 read=1
   I/O Timings: shared read=0.053
 Planning Time: 0.140 ms
 Execution Time: 0.118 ms
(10 filas)
```

- **De 43,684 ms a 0,118 ms: 370 veces**, y de 10 770 páginas a 31. Ya no hay `Rows Removed by
  Filter`: el `Filter` pasó a ser `Index Cond`, la diferencia entre *leer todo y descartar* y *ir
  directo*. El `ANALYZE` no es opcional —sin estadísticas del índice el planificador no lo
  considera— y también se deshace con el `ROLLBACK`.
- **Cuánto cuesta:** 169 ms de construcción y 7,6 MB, un 9 % de la tabla, que hay que mantener: cada
  `INSERT` escribe también aquí, y un `UPDATE` que toque `cliente_id` deja de poder ser HOT.

Y ahora lo que define a la familia. Como **el orden se mantiene en las hojas**, el mismo índice
responde un rango —`WHERE cliente_id BETWEEN 4210 AND 4260` pasa a `Bitmap Index Scan` y baja de
41,467 ms y 10 770 páginas a **1,289 ms y 979 páginas**— y responde un `ORDER BY` **sin ordenar
nada**: `SELECT id FROM pedidos ORDER BY cliente_id LIMIT 10` da un `Index Scan` bajo el `Limit`,
**sin nodo `Sort`**, en trece páginas y **0,034 ms**. Las tres medidas salen de esta misma
transacción, que termina en `ROLLBACK`; guarda la última, porque en §3 se repite esa consulta con un
hash.

- **Cuándo sí:** por defecto. Igualdad, rango, `ORDER BY`, `MIN`/`MAX`, prefijo con `LIKE
  'PED-0042%'` y columnas de clave foránea. **Cuándo no:** cuando el operador no es de orden —`@>`
  sobre `jsonb`, solapamiento de rangos— o cuando la tabla es enorme y está tan bien ordenada en
  disco que un BRIN de 40 kB hace el mismo trabajo (§6).

> **Veredicto:** el B-tree es la respuesta por defecto porque mantiene el orden, y el orden es lo
> que convierte un índice de igualdad en uno de rango y de `ORDER BY` sin pagar nada extra.

---

## 3. 🧱 Hash: solo igualdad

**Qué es.** Una tabla de dispersión: el motor calcula `hash(valor)`, eso da un *bucket* (cubo), y en
ese cubo está la lista de punteros a filas. No hay árbol y **no hay orden**, porque la dispersión
destruye a propósito la relación entre el valor y su posición. De ahí sale todo lo demás.

```text
tienda=# BEGIN;
BEGIN
tienda=*# CREATE INDEX pedidos_cliente_id_hash ON pedidos USING hash (cliente_id);
CREATE INDEX
Duración: 1050,213 ms (00:01,050)
tienda=*# ANALYZE pedidos;
ANALYZE
tienda=*# SELECT pg_size_pretty(pg_relation_size('pedidos_cliente_id_hash')) AS hash_size;
 hash_size
-----------
 32 MB
(1 fila)
```

- **Cuánto cuesta:** 32 MB contra los 7,6 MB del B-tree —**4,2 veces más grande**— y 1 050 ms de
  construcción contra 169 ms. Es de estructura: el B-tree comparte el prefijo entre valores vecinos
  y se compacta; el hash reserva cubos de tamaño fijo y los llena de forma dispersa. Para `=`
  funciona, y hasta un pelo mejor porque no baja por ningún árbol: el `SELECT` de §1 da `Index Scan
  using pedidos_cliente_id_hash`, 31 páginas y **0,070 ms** contra 0,118 ms.
- **Pero para el rango el índice está ahí y el planificador ni lo mira.** No lo descarta por coste:
  el método de acceso hash **solo declara el operador `=`**, así que para `>=` y `<=` ni es
  candidato. El mismo `BETWEEN` de §2 vuelve a `Seq Scan on pedidos` con `Rows Removed by Filter:
  998982`, 41,467 ms y las 10 770 páginas de siempre, contra 1,289 ms y 979 con el B-tree.

Y el `ORDER BY`, que es donde mejor se ve qué significa "no mantiene el orden":

```text
tienda=*# EXPLAIN (ANALYZE, COSTS, BUFFERS)
tienda-*# SELECT id FROM pedidos ORDER BY cliente_id LIMIT 10;
                                                            QUERY PLAN
----------------------------------------------------------------------------------------------------------------------------------
 Limit  (cost=42379.64..42379.67 rows=10 width=16) (actual time=130.603..130.614 rows=10.00 loops=1)
   Buffers: shared hit=10770
   ->  Sort  (cost=42379.64..44879.64 rows=1000000 width=16) (actual time=130.602..130.603 rows=10.00 loops=1)
         Sort Key: cliente_id
         Sort Method: top-N heapsort  Memory: 25kB
         Buffers: shared hit=10770
         ->  Seq Scan on pedidos  (cost=0.00..20770.00 rows=1000000 width=16) (actual time=0.006..71.042 rows=1000000.00 loops=1)
               Buffers: shared hit=10770
 Planning:
   Buffers: shared hit=30
 Planning Time: 0.090 ms
 Execution Time: 130.631 ms
(12 filas)

tienda=*# ROLLBACK;
ROLLBACK
```

- **130,631 ms contra los 0,034 ms del B-tree: 3 842 veces.** Para devolver diez filas el motor leyó
  el millón entero y lo ordenó con un `top-N heapsort`; el hash no puede ayudar ni en teoría, porque
  sus cubos no tienen ningún orden que recorrer.
- **Cuándo sí:** casi nunca. El caso defendible es una columna **larga** consultada solo por
  igualdad —una URL, un texto de cientos de bytes—, donde el hash guarda 32 bits por fila y el
  B-tree el valor entero; sobre un `bigint` de 8 bytes el B-tree gana en todo. **Cuándo no:** si
  algún día puede aparecer un `BETWEEN`, un `ORDER BY` o un `LIKE 'pre%'`.

> **📝 Contexto.** El consejo *"no uses índices hash en PostgreSQL, no son seguros ante caídas"*
> describe un motor anterior a **PostgreSQL 10, de octubre de 2017**: hasta la 9.6 el índice hash no
> se escribía en el WAL, no se replicaba y había que reconstruirlo tras una caída. Desde la 10 se
> registra como cualquier otro. El motivo para no usarlo hoy no es la seguridad: es que solo sabe
> responder `=` y ocupa cuatro veces más.

---

## 4. 🧱 GIN: indexa las partes

**Qué es.** GIN es el *Generalized Inverted Index* (índice invertido generalizado), y la palabra que
importa es **invertido**: en vez de una entrada por fila, **parte cada valor en elementos y guarda
una entrada por elemento**, con la lista de filas donde aparece —en `jsonb`, las parejas
clave-valor; en un `tsvector`, las palabras—. Por eso responde "¿cuál contiene esto?", que un B-tree
no puede ni plantearse: indexa el documento entero como un valor opaco.

`eventos_pedido` tiene 4 100 000 filas y 641 MB, con una columna `carga` de tipo `jsonb`. Buscar los
eventos de un pedido anulado que entró por el call center, en su primera versión, sin índice da un
`Seq Scan` de **82 017 páginas y 596,011 ms** para devolver 20 295 filas —el 0,49 % de la tabla—,
con `Rows Removed by Filter: 4079705`: el operador `@>` es **contención** (*"el documento de la
izquierda contiene al de la derecha"*) y sin índice se evalúa fila por fila. Un GIN sobre cuatro
millones de documentos puede tardar minutos de construir, así que el plan era acotarlo con un índice
parcial; **no hizo falta y por eso no lo acoté**: con los `maintenance_work_mem=256MB` que fija el
`compose`, el índice completo se construye en 5,8 s.

```text
tienda=# BEGIN;
BEGIN
tienda=*# CREATE INDEX eventos_pedido_carga_gin ON eventos_pedido USING gin (carga);
CREATE INDEX
Duración: 5824,744 ms (00:05,825)
tienda=*# ANALYZE eventos_pedido;
ANALYZE
Duración: 216,803 ms
tienda=*# SELECT pg_size_pretty(pg_relation_size('eventos_pedido_carga_gin')) AS gin_size;
 gin_size
----------
 85 MB
(1 fila)

tienda=*# EXPLAIN (ANALYZE, COSTS, BUFFERS)
tienda-*# SELECT count(*) FROM eventos_pedido
tienda-*#  WHERE carga @> '{"estado":"ANULADO","origen":"callcenter","version":1}';
                                                                      QUERY PLAN
------------------------------------------------------------------------------------------------------------------------------------------------------
 Aggregate  (cost=35165.08..35165.09 rows=1 width=8) (actual time=137.769..137.770 rows=1.00 loops=1)
   Buffers: shared hit=3967 read=16721 written=36
   I/O Timings: shared read=17.954 write=0.518
   ->  Bitmap Heap Scan on eventos_pedido  (cost=270.79..35061.54 rows=41414 width=0) (actual time=73.938..136.797 rows=20295.00 loops=1)
         Recheck Cond: (carga @> '{"estado": "ANULADO", "origen": "callcenter", "version": 1}'::jsonb)
         Heap Blocks: exact=16828
         Buffers: shared hit=3967 read=16721 written=36
         I/O Timings: shared read=17.954 write=0.518
         ->  Bitmap Index Scan on eventos_pedido_carga_gin  (cost=0.00..260.44 rows=41414 width=0) (actual time=72.138..72.138 rows=20295.00 loops=1)
               Index Cond: (carga @> '{"estado": "ANULADO", "origen": "callcenter", "version": 1}'::jsonb)
               Index Searches: 1
               Buffers: shared hit=3860
 Planning:
   Buffers: shared hit=24
 Planning Time: 0.114 ms
 Execution Time: 137.793 ms
(16 filas)

tienda=*# ROLLBACK;
ROLLBACK
```

- **596,011 ms a 137,793 ms: 4,3 veces**, mucho menos espectacular que el 370× del B-tree, y el plan
  dice por qué: el `Bitmap Index Scan` resuelve las 20 295 filas en 72 ms leyendo 3 860 páginas de
  índice, pero esas filas están repartidas por **16 828 páginas del heap** que hay que ir a buscar.
  El índice hizo su trabajo; lo caro es recoger las filas.
- **Cuánto cuesta:** 85 MB, un 13 % de la tabla, y **es caro de actualizar**: un `INSERT` no añade
  una entrada sino tantas como elementos tenga el documento. PostgreSQL lo amortigua con una lista
  pendiente (`fastupdate`, activa por defecto) que acumula entradas y las mezcla de golpe, así que
  la inserción sale barata casi siempre y muy cara cuando toca vaciar la lista. La variante `USING
  gin (carga jsonb_path_ops)` indexa rutas completas en vez de claves y valores sueltos: medido,
  **60 MB en vez de 85 y 2,2 s en vez de 5,8**, a cambio de servir solo para `@>`.
- **Lo que el GIN no acelera**, y es el error más caro con `jsonb`: con ese mismo índice creado,
  `WHERE carga->>'origen' = 'callcenter'` sigue dando `Seq Scan` y **518,021 ms**, medido. `->>`
  devuelve texto y no está en su clase de operadores. Para acelerarlo hace falta un índice de
  expresión sobre `(carga->>'origen')`, que es un B-tree y es material de
  [`03`](03-compuestos-parciales-y-de-cobertura.md).

> **Veredicto:** GIN es para "¿contiene?" —`jsonb`, texto completo, arrays—, no para "¿es igual a?".
> Si tu `WHERE` usa `->>`, el GIN no es tu índice aunque la columna sea `jsonb`.

---

## 5. 🧱 GiST: el que no puedo demostrar

**Esta sección no trae sesión de medición, y se declara.** GiST —*Generalized Search Tree*, árbol de
búsqueda generalizado— es un árbol en el que cada nodo interno guarda un **predicado que cubre a
todos sus hijos**: una caja que contiene otras cajas, un rango que contiene otros rangos. Con eso
responde solapamiento (`&&`), contención geométrica y proximidad (`ORDER BY punto <-> punto`, el
*k-nearest neighbour*), que ningún árbol de orden total sabe plantearse: dos rangos que se solapan
no son comparables con "menor que". El dominio de la tienda **no da un caso honesto** —sus seis
tablas no tienen columna de tipo rango, ni geométrica, ni `tsvector`— y el motor lo dice al
forzarlo:

```text
tienda=# BEGIN;
BEGIN
tienda=*# CREATE INDEX eventos_pedido_ocurrido_gist ON eventos_pedido USING gist (ocurrido_en);
ERROR:  data type timestamp with time zone has no default operator class for access method "gist"
SUGERENCIA:  You must specify an operator class for the index or define a default operator class for the data type.
tienda=!# ROLLBACK;
ROLLBACK
```

- **Ese error es el mecanismo, no un obstáculo.** Un método de acceso no sabe indexar tipos: sabe
  indexar **clases de operadores**. `timestamptz` no tiene clase GiST por defecto porque un instante
  no se solapa con otro instante; un `tstzrange` sí, y para eso habría que cambiar el esquema. La
  extensión `btree_gist` añade la clase, pero solo consigue que GiST imite a un B-tree.
- **Cuándo sí, sin sesión que lo respalde aquí:** rangos de fecha con `EXCLUDE USING gist (sala WITH
  =, periodo WITH &&)` para que dos reservas no se pisen; PostGIS, que es GiST entero; y `pg_trgm`
  para `LIKE '%texto%'`. **Cuándo no:** igualdad y rango sobre un escalar. **Cuánto cuesta,
  declarado como no medido:** GiST es **con pérdida** por diseño —devuelve candidatos y el motor
  recomprueba cada fila— y se construye más despacio que un B-tree. No tengo el número aquí y no me
  lo invento.

> **Veredicto:** B-tree ordena, hash dispersa, GIN descompone, **GiST agrupa por región**; si tu
> pregunta es "¿qué cae cerca de esto, o se solapa con esto?", ninguna de las otras tres sabe
> contestarla.

---

## 6. 🧱 BRIN: 40 kB y la correlación

**Qué es.** Un *Block Range INdex* no guarda una entrada por fila: guarda **el mínimo y el máximo de
cada grupo de 128 páginas consecutivas**. Con eso no sabe dónde está una fila; solo sabe decir *"en
este tramo del disco seguro que no está"*. Por eso es diminuto, y por eso su utilidad depende de una
sola cosa: **que los valores ya estén ordenados en el disco**. Si cada tramo contiene valores de
todo el rango, todos son candidatos y no descarta nada. Eso se mide antes de crear nada con
`pg_stats.correlation`: la correlación entre el orden lógico de los valores y su orden físico en el
heap, entre -1 y 1.

```text
tienda=# SELECT tablename, attname, correlation FROM pg_stats
tienda-#  WHERE schemaname='public'
tienda-#    AND (tablename, attname) IN (('eventos_pedido','ocurrido_en'),
tienda-#                                 ('eventos_pedido','pedido_id'),
tienda-#                                 ('pedidos','creado_en'))
tienda-#  ORDER BY 1, 2;
   tablename    |   attname   | correlation
----------------+-------------+--------------
 eventos_pedido | ocurrido_en |  0.009783591
 eventos_pedido | pedido_id   |            1
 pedidos        | creado_en   | -0.007319069
(3 filas)
```

**Y ahí está el hallazgo.** Las dos columnas de fecha, candidatas obvias a BRIN en cualquier manual,
tienen correlación **0,0098 y -0,0073**: cero a efectos prácticos. No es un defecto de los datos —la
semilla reparte las fechas al azar sobre 1 000 días— y es lo que le pasa a una tabla real que ha
sufrido `UPDATE` y reutilización de espacio. La que sí está correlacionada es `pedido_id`, con un 1
perfecto. Empecemos por el caso que no funciona: con el BRIN creado el planificador **ni lo elige**,
así que hay que forzarlo para mirar por qué.

```text
tienda=# BEGIN;
BEGIN
tienda=*# CREATE INDEX eventos_pedido_ocurrido_brin ON eventos_pedido USING brin (ocurrido_en);
CREATE INDEX
Duración: 208,951 ms
tienda=*# ANALYZE eventos_pedido;
ANALYZE
tienda=*# SET LOCAL enable_seqscan = off;
SET
tienda=*# EXPLAIN (ANALYZE, COSTS, BUFFERS)
tienda-*# SELECT count(*) FROM eventos_pedido
tienda-*#  WHERE ocurrido_en >= '2024-03-18' AND ocurrido_en < '2024-03-25';
                                                                               QUERY PLAN
------------------------------------------------------------------------------------------------------------------------------------------------------------------------
 Aggregate  (cost=143619.98..143619.99 rows=1 width=8) (actual time=387.194..387.201 rows=1.00 loops=1)
   Buffers: shared hit=7 read=82017 written=5
   I/O Timings: shared read=16.872 write=0.138
   ->  Bitmap Heap Scan on eventos_pedido  (cost=33.05..143549.63 rows=28142 width=0) (actual time=2.024..385.512 rows=28528.00 loops=1)
         Recheck Cond: ((ocurrido_en >= '2024-03-18 00:00:00+00'::timestamp with time zone) AND (ocurrido_en < '2024-03-25 00:00:00+00'::timestamp with time zone))
         Rows Removed by Index Recheck: 4071472
         Heap Blocks: lossy=82017
         Buffers: shared hit=7 read=82017 written=5
         I/O Timings: shared read=16.872 write=0.138
         ->  Bitmap Index Scan on eventos_pedido_ocurrido_brin  (cost=0.00..26.01 rows=4099972 width=0) (actual time=1.715..1.715 rows=820170.00 loops=1)
               Index Cond: ((ocurrido_en >= '2024-03-18 00:00:00+00'::timestamp with time zone) AND (ocurrido_en < '2024-03-25 00:00:00+00'::timestamp with time zone))
               Index Searches: 1
               Buffers: shared hit=7
 Planning:
   Buffers: shared hit=25
 Planning Time: 0.288 ms
 Execution Time: 387.232 ms
(17 filas)

tienda=*# ROLLBACK;
ROLLBACK
```

- **`Heap Blocks: lossy=82017`**: el índice marcó como candidatas **las 82 017 páginas de la
  tabla**, o sea todas, y `Rows Removed by Index Recheck: 4071472` confirma que el filtro lo hizo el
  recheck. El BRIN leyó 7 páginas en 1,7 ms e hizo su trabajo: es que **no había ningún tramo que
  descartar**. Resultado: **387,232 ms forzado contra 328,042 ms** del `Seq Scan` que el
  planificador elige solo. Aquí el BRIN no es neutro, es peor.

Sobre `pedido_id`, correlación 1, la misma familia cambia de bando: el BRIN se construye en 173 ms y
ocupa **40 kB**, y `WHERE pedido_id BETWEEN 400000 AND 400500` da `Heap Blocks: lossy=128` de 82 017
—descarta el 99,8 % del disco— y baja de **218,960 ms sin índice a 1,478 ms**, 148 veces, con 4 347
filas de `Rows Removed by Index Recheck`. El B-tree equivalente, medido en la misma máquina, **ocupa
51 MB y tarda 645 ms en construirse**: mil trescientas veces más grande para el mismo rango.

- **Cuándo sí:** tablas grandes donde se inserta al final y no se actualiza —bitácoras, series
  temporales, eventos—, consultadas por rango. **Cuándo no:** correlación baja, tablas pequeñas, o
  igualdad puntual, donde el B-tree va a la fila y el BRIN trae 128 páginas.

> **🩺 Diagnóstico.** Antes de crear un BRIN mira `pg_stats.correlation`: por debajo de ~0,9 no te
> molestes. Si ya está creado y sospechas, mira `Heap Blocks: lossy=`: si se parece al total de
> páginas de la tabla, no está descartando nada.

---

## 7. ⚖️ El contraste de motor

Las cinco familias de arriba son de PostgreSQL. En un proyecto con MySQL la lista es mucho más
corta: **InnoDB solo tiene B-tree** en tablas normales, más `FULLTEXT` y `SPATIAL` como tipos
aparte. No hay GIN, ni GiST, ni BRIN. Y la sintaxis `USING HASH` existe, se acepta y **no crea un
índice hash**:

```text
mysql> CREATE INDEX pedidos_cliente_id_hash ON pedidos (cliente_id) USING HASH;
Query OK, 0 rows affected, 2 warnings
Records: 0  Duplicates: 0  Warnings: 2

mysql> SHOW WARNINGS;
+---------+------+-------------------------------------------------------------------------------------------------------------------------------------------------+
| Level   | Code | Message                                                                                                                                         |
+---------+------+-------------------------------------------------------------------------------------------------------------------------------------------------+
| Note    | 3502 | This storage engine does not support the HASH index algorithm, storage engine default was used instead.                                         |
| Warning | 1831 | Duplicate index 'pedidos_cliente_id_hash' defined on the table 'tienda.pedidos'. This is deprecated and will be disallowed in a future release. |
+---------+------+-------------------------------------------------------------------------------------------------------------------------------------------------+
2 rows in set

mysql> DROP INDEX pedidos_cliente_id_hash ON pedidos;
Query OK, 0 rows affected
```

- **El índice se llama `hash` y el motor lo crea B-tree:** `information_schema.STATISTICS` le da
  `INDEX_TYPE = BTREE`, comprobado en la misma sesión. MySQL 9.7.2 no falla, solo emite una `Note`
  **3502**, y una `Note` no la imprime el cliente por defecto ni la levanta la mayoría de los
  drivers: desde fuera el `CREATE INDEX` devuelve `Query OK` y el equipo se queda creyendo que tiene
  un índice hash. El `USING HASH` sí funciona en el motor `MEMORY`, de donde viene la sintaxis.
- **Las otras familias ni se parsean.** `USING GIN` y `USING BRIN` dan `ERROR 1064 … right syntax to
  use near 'GIN'`: no es que no estén soportadas, es que no son palabras del lenguaje.
- **En MySQL el DDL confirma implícitamente**, así que aquí no hay `BEGIN … ROLLBACK` que valga: el
  índice se borró con un `DROP INDEX` explícito, y `SHOW INDEX FROM pedidos` vuelve a dar los tres
  originales —`PRIMARY`, `codigo` y `fk_pedidos_cliente`—.

SQLite es todavía más simple, y también lo dice al parsear:

```text
sqlite> CREATE INDEX pedidos_cliente_id_hash ON pedidos (cliente_id) USING HASH;
Parse error near line 2: near "USING": syntax error
  X pedidos_cliente_id_hash ON pedidos (cliente_id) USING HASH;
                                      error here ---^
```

- **SQLite 3.53.4 no tiene ninguna sintaxis para elegir familia** porque solo tiene una: todos sus
  índices son B-tree, igual que sus tablas. La búsqueda de texto completo existe, pero como **tabla
  virtual** (`FTS5`), no como un tipo de índice sobre una columna.

---

## 8. 📜 Estándar, motor y convención

> **📜 Estándar o motor.** **El estándar SQL no dice nada de familias de índice.** ISO/IEC 9075 ni
> siquiera define `CREATE INDEX`: los índices son una decisión de implementación física, no del
> lenguaje, y por eso toda la sintaxis —`USING`, las clases de operadores, los índices parciales— es
> extensión de cada motor. **No he verificado la cláusula**, porque la norma es de pago; lo que sí
> he verificado es que los tres motores aceptan `CREATE INDEX` con sintaxis distinta e incompatible.

| Afirmación | Estándar | PostgreSQL 18.6 | MySQL 9.7.2 (InnoDB) | SQLite 3.53.4 |
|---|---|---|---|---|
| `CREATE INDEX` está en la norma, y se puede elegir la familia | **No** las dos cosas; cláusula no verificada, pero no es parte del lenguaje | Sí: `USING btree`, `hash`, `gin`, `gist`, `spgist` o `brin` | `CREATE INDEX` sí; familia no: `Note 3502` y crea `BTREE` | `CREATE INDEX` sí; `USING` es error de sintaxis |
| Existen índice hash, invertido para `jsonb` y por rangos de bloque | No lo contempla | Los tres: hash (desde la 10 va al WAL), GIN y BRIN | Solo hash, y solo en el motor `MEMORY`; para `jsonb`, índices sobre columnas generadas | No; `FTS5` es tabla virtual |
| Un índice responde `ORDER BY` sin ordenar | No lo contempla | Sí con B-tree; no con hash (medido: `Sort`, 130,631 ms) | Sí, siempre es B-tree | Sí, siempre es B-tree |

**Convención:** *"un índice hace las consultas más rápidas"* es falsa en las dos direcciones. **No
todas las consultas**: el hash de §3 no acelera un `BETWEEN` ni un `ORDER BY`, el GIN de §4 no
acelera un `->>`, y el BRIN de §6 sobre una columna con correlación 0,0098 deja la consulta **más
lenta** que sin él —387 ms contra 328—. **Y nunca es gratis**: 7,6 MB para el B-tree de
`pedidos(cliente_id)`, 32 MB para su hash, 85 MB para el GIN, más una escritura extra en cada
`INSERT` y un `UPDATE` que deja de poder ser HOT. La versión precisa: *un índice cambia el plan de
algunas consultas, y se paga en espacio y en cada escritura*.

---

## ⚠️ Errores frecuentes

| Se dice | Lo preciso |
|---|---|
| "Un índice hace las consultas más rápidas" | Acelera las que su estructura sabe responder. El hash de §3 deja el `ORDER BY` en 130,631 ms; el B-tree, en 0,034 ms |
| "Los índices hash de PostgreSQL no son seguros" | Cierto hasta la 9.6. Desde PostgreSQL 10, de 2017, van al WAL y se replican. El motivo para no usarlos es que solo sirven para `=` |
| "Si la columna es `jsonb`, le pongo un GIN y ya" | El GIN sirve para `@>` y los operadores de existencia de clave. Con `carga->>'origen' = …` el plan sigue siendo `Seq Scan`: 518,021 ms medidos |
| "BRIN es el índice para columnas de fecha" | Es el índice para columnas **correlacionadas con el orden físico**. Aquí `ocurrido_en` da 0,0098 y el BRIN forzado lee las 82 017 páginas |
| "MySQL también tiene índices hash, se pone `USING HASH`" | En InnoDB se acepta y se crea un B-tree, con una `Note 3502` que el cliente no imprime. Solo el motor `MEMORY` los tiene de verdad |

---

## 📚 Para profundizar

- **Documentación** — PostgreSQL 18, «Index Types»: las seis familias y qué operador sirve cada una.
  <https://www.postgresql.org/docs/18/indexes-types.html>
- **Documentación** — PostgreSQL 18, «BRIN Indexes»: rangos de bloque y `pages_per_range`.
  <https://www.postgresql.org/docs/18/brin.html>
- **Documentación** — PostgreSQL 18, «GIN Indexes»: índice invertido y `fastupdate`.
  <https://www.postgresql.org/docs/18/gin.html>
- **Documentación** — PostgreSQL 18, «GiST Indexes»: predicados que cubren a los hijos.
  <https://www.postgresql.org/docs/18/gist.html>
- **Documentación** — MySQL 9.7, «Comparison of B-Tree and Hash Indexes»: por qué InnoDB ignora
  `USING HASH`. <https://dev.mysql.com/doc/refman/9.7/en/index-btree-hash.html>
- **Libro** — Markus Winand, *SQL Performance Explained*, self-published, 2012, capítulo 1: la
  anatomía del B-tree.

---

## 🧠 Preguntas

1. Nombra las cinco familias que cubre este capítulo y di en una frase qué estructura es cada una. 🟢
2. ¿Qué operador responde un índice hash, y cuáles no? 🟢
3. ¿Qué guarda un BRIN por cada grupo de páginas, y por qué eso lo hace tan pequeño? 🟢
4. ¿Qué significa que un GIN sea un índice "invertido"? 🟢
5. `Index Cond` o `Filter`: ¿cuál usa el índice? ¿Lo fija el estándar o es cosa del motor? 🟡
6. ¿Por qué el GIN de §4 no acelera `carga->>'origen' = 'callcenter'` si la columna es la misma? 🟡
7. Distingue `Heap Blocks: exact=` de `Heap Blocks: lossy=`: ¿qué implica cada uno para el recheck?
   🟡
8. ¿Las familias de índice las fija el estándar SQL o cada motor? Di qué tiene PostgreSQL 18.6, qué
   tiene MySQL 9.7.2 con InnoDB y qué tiene SQLite 3.53.4. 🟡
9. Alguien escribe `CREATE INDEX … USING HASH` en MySQL y afirma que tiene un índice hash: ¿qué
   ocurrió de verdad, y cómo se lo demuestras en dos consultas? 🟠
10. Te proponen un BRIN sobre `pedidos.creado_en` "porque es una fecha": ¿qué consultas antes de
    responder, y qué contestas con el número que salga? 🟠
11. Justifica por qué un BRIN de 40 kB puede sustituir a un B-tree de 51 MB sobre
    `eventos_pedido(pedido_id)`, y di qué se pierde en el cambio. 🟠
12. ¿Por qué `CREATE INDEX … USING gist (ocurrido_en)` falla con "no default operator class", y qué
    te enseña ese error sobre cómo funcionan los métodos de acceso? 🟠
13. Un compañero propone crear en producción, y sin transacción, los cinco índices de este capítulo
    "para probar cuál gana". Escribe la secuencia exacta que usarías tú en su lugar —comandos y
    orden— y justifica cada paso, incluido el `ANALYZE`. 🔴
14. `eventos_pedido` se consulta por `carga @> '{…}'` y por rango de `pedido_id`. Diseña la
    indexación completa con las familias de este capítulo, escribe el DDL y pon el precio de cada
    índice en espacio y en construcción. 🔴
15. Tienes que defender ante un equipo que migra de PostgreSQL a MySQL 9.7.2 que dos de sus índices
    no pueden viajar: escribe qué dos son, qué los sustituye del lado de MySQL y qué se degrada en
    cada caso. 🔴

---

**Anterior:** [`01`](01-como-se-almacena-una-tabla.md) · **Siguiente:**
[`03`](03-compuestos-parciales-y-de-cobertura.md) — el orden de las columnas, los parciales y el
índice de expresión que sí acelera un `->>` · **Relacionado:**
[`06`](06-cuando-el-indice-no-se-usa.md) — por qué un índice de la familia correcta puede seguir sin
usarse.
