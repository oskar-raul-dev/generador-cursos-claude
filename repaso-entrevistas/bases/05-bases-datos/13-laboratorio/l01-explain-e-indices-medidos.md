# l01 — `EXPLAIN` e índices medidos

> El mismo `SELECT` antes y después de su índice, con plan, páginas y tiempo; los dos errores de
> crear un índice sin permiso o dentro de una transacción; y **los tres casos de «el índice no se
> usa» que [`03/06`](../03-el-motor-por-dentro/06-cuando-el-indice-no-se-usa.md) §6 explicó sin
> sesión**, corridos por primera vez: el `OR` entre columnas, el `LIKE` con la colación de la base y
> el plan genérico que no ve un índice parcial. **Tiempo estimado:** 30 minutos. **Asume
> levantado:** el entorno de [`l00`](l00-el-entorno-y-los-datos.md), con la carga verificada.
> **Asume leído:** [`03/05`](../03-el-motor-por-dentro/05-explain-y-explain-analyze.md), que enseña
> a leer un plan. **Vigencia:** 24 de septiembre de 2026.

---

## Salto rápido

- [1. Qué vas a ver](#1--qué-vas-a-ver) · [2. Medir sin índice](#2--paso-1--medir-sin-índice) · [3.
  Crear el índice](#3--paso-2--crear-el-índice-y-los-dos-errores)
- [4. El `OR`](#4--paso-3--el-or-entre-dos-columnas) · [5. `LIKE`](#5--paso-4--like-y-la-colación) ·
  [6. El plan genérico](#6--paso-5--el-plan-genérico-y-el-índice-parcial)
- [Ejercicios](#-ejercicios) · [Preguntas](#-preguntas)

---

## 1. 🎯 Qué vas a ver

Un índice se defiende con dos números: **cuánto baja la consulta y cuánto cuesta tenerlo**. Este lab
los mide sobre la tienda del corpus y se mete en los tres casos en que el índice correcto existe y
el motor no lo usa, los que más se discuten en una revisión y menos gente ha visto con sus propios
ojos. **Cada índice se crea, se mide y se borra en el mismo paso**: la base termina con sus 11
índices.

> **📝 Contexto.** Las sesiones se corrieron sobre la copia recién cargada de
> [`l00`](l00-el-entorno-y-los-datos.md) §1, en el estado declarado. **Los tiempos dependen de la
> caché**, y §4 lo enseña con la misma consulta en frío y en caliente; lo que tiene que coincidir
> con tu máquina es la forma del plan, las filas reales y las páginas. **Denso**: 280 líneas de
> sesión en 549; se podó la prosa, y el recuento de uso de índices pasó al bloque 06.

---

## 2. 🧱 Paso 1 — Medir sin índice

```bash
PGPASSWORD=postgres psql -h 127.0.0.1 -U postgres -d tienda
```

- Una sesión interactiva como superusuario, que es quien crea y borra índices. Todo el lab ocurre en
  ella. `\timing on` hace que `psql` mida cada sentencia desde el cliente.

```text
tienda=# \timing on
El despliegue de duración está activado.
tienda=# SELECT id, codigo, total FROM pedidos WHERE cliente_id = 311 ORDER BY id LIMIT 3;
  id   |  codigo   |  total
-------+-----------+---------
  1719 | PED-01719 | 9948.26
  9054 | PED-09054 | 4958.95
 31267 | PED-31267 | 1433.09
(3 filas)

Duración: 73,810 ms
tienda=# EXPLAIN (ANALYZE, BUFFERS) SELECT id, codigo, total FROM pedidos WHERE cliente_id = 311;
                                                  QUERY PLAN
--------------------------------------------------------------------------------------------------------------
 Seq Scan on pedidos  (cost=0.00..23270.00 rows=21 width=25) (actual time=65.490..101.566 rows=52.00 loops=1)
   Filter: (cliente_id = 311)
   Rows Removed by Filter: 999948
   Buffers: shared hit=455 read=10315
   I/O Timings: shared read=44.303
 Planning Time: 0.095 ms
 Execution Time: 101.625 ms
(7 filas)

Duración: 106,106 ms
```

- `EXPLAIN (ANALYZE, BUFFERS)` **ejecuta** la consulta: `ANALYZE` añade tiempos y filas reales;
  `BUFFERS`, las páginas de 8 kB tocadas —`hit` en caché, `read` pedidas al sistema—. Cómo se lee
  cada número es de [`03/05`](../03-el-motor-por-dentro/05-explain-y-explain-analyze.md) §3.
- **455 + 10 315 = 10 770 páginas, la tabla entera**, para devolver 52 filas. `rows=21` estimadas
  contra 52: el planificador usa la media por cliente, y `CLI-00311` es grande.

---

## 3. 🧱 Paso 2 — Crear el índice, y los dos errores

**El primer error, a propósito**: crearlo con el rol de la aplicación, en otra terminal.

```text
tienda=> CREATE INDEX pedidos_cliente_id_idx ON pedidos (cliente_id);
ERROR:  must be owner of table pedidos
```

- **Crear un índice es cambiar el esquema**, y solo puede el dueño de la tabla. `tienda_app` escribe
  filas; el esquema es de las migraciones, como en [`l00`](l00-el-entorno-y-los-datos.md) §8.

**El segundo**: `CONCURRENTLY` —construir sin bloquear las escrituras— dentro de una transacción:

```text
tienda=# BEGIN;
BEGIN
Duración: 2,291 ms
tienda=*# CREATE INDEX CONCURRENTLY pedidos_cliente_id_idx ON pedidos (cliente_id);
ERROR:  CREATE INDEX CONCURRENTLY cannot run inside a transaction block
Duración: 2,372 ms
tienda=!# ROLLBACK;
ROLLBACK
Duración: 1,590 ms
```

- **`CONCURRENTLY` confirma por su cuenta entre sus dos pasadas**, y dentro de un `BEGIN` no puede.
  El prompt lo cuenta: `=*#` es «en una transacción»; `=!#`, «falló y solo acepta `ROLLBACK`».
- **Es el error de una herramienta de migraciones que envuelve cada fichero en una transacción**: el
  índice concurrente va en una migración marcada para correr fuera de ella.

La corrección, y la medida:

```text
tienda=# CREATE INDEX CONCURRENTLY pedidos_cliente_id_idx ON pedidos (cliente_id);
CREATE INDEX
Duración: 457,306 ms
tienda=# SELECT pg_size_pretty(pg_relation_size('pedidos_cliente_id_idx')) AS indice, pg_size_pretty(pg_relation_size('pedidos')) AS tabla;
 indice  | tabla
---------+-------
 7800 kB | 84 MB
(1 fila)

Duración: 9,350 ms
tienda=# EXPLAIN (ANALYZE, BUFFERS) SELECT id, codigo, total FROM pedidos WHERE cliente_id = 311;
                                                              QUERY PLAN
---------------------------------------------------------------------------------------------------------------------------------------
 Index Scan using pedidos_cliente_id_idx on pedidos  (cost=0.42..24.99 rows=21 width=25) (actual time=0.107..0.130 rows=52.00 loops=1)
   Index Cond: (cliente_id = 311)
   Index Searches: 1
   Buffers: shared hit=8 read=1
   I/O Timings: shared read=0.034
 Planning:
   Buffers: shared hit=56 read=1
   I/O Timings: shared read=0.073
 Planning Time: 1.324 ms
 Execution Time: 0.235 ms
(10 filas)

Duración: 5,121 ms
```

| | Sin índice | Con índice |
|---|---|---|
| Nodo | `Seq Scan` | `Index Scan` |
| Páginas tocadas | 10 770 | 9 |
| `Execution Time` | 101,625 ms | 0,235 ms |
| Lo que cuesta | — | 7 800 kB, 457 ms de construcción y una escritura más por `INSERT` |

- **`Filter` se volvió `Index Cond`**: la condición sirve para bajar por el árbol, una vez —`Index
  Searches: 1`—. `Duración` la mide `psql`, con planificación y red; `Execution Time`, el servidor.
- **Nueve páginas para 52 filas tienen un porqué**: los pedidos de `CLI-00311` viven en **tres
  páginas** del heap, por cómo los fija la semilla. Con `cliente_id = 4210` el mismo plan tocó 31
  páginas para 25 filas —`shared hit=11 read=20`—. El coste real de un `Index Scan` son las páginas
  del heap que visita, y dependen de dónde vivan las filas.

**Teardown de este índice** —al terminar §4, que también lo usa—: `DROP INDEX
pedidos_cliente_id_idx;`. Después, `SELECT count(*) FROM pg_indexes WHERE schemaname = 'public'` dio
**11**, los de [`l00`](l00-el-entorno-y-los-datos.md): otro número es un teardown olvidado. Saber
qué índices no usa nadie es de la monitorización del bloque 06, que lista el [README de la
raíz](../README.md).

---

## 4. 🩺 Paso 3 — El `OR` entre dos columnas

**El caso**: un `OR` sobre dos columnas necesita **un índice por rama**; con uno solo, la otra rama
podría traer cualquier fila y hay que leer la tabla igual. `COSTS OFF` quita las estimaciones del
plan para leerlo mejor.

```text
tienda=# EXPLAIN (ANALYZE, BUFFERS, COSTS OFF) SELECT count(*) FROM pedidos WHERE cliente_id = 311 OR estado = 'ANULADO';
                                 QUERY PLAN
-----------------------------------------------------------------------------
 Aggregate (actual time=98.397..98.402 rows=1.00 loops=1)
   Buffers: shared hit=1416 read=9354
   I/O Timings: shared read=3.666
   ->  Seq Scan on pedidos (actual time=0.066..95.539 rows=60049.00 loops=1)
         Filter: ((cliente_id = 311) OR (estado = 'ANULADO'::text))
         Rows Removed by Filter: 939951
         Buffers: shared hit=1416 read=9354
         I/O Timings: shared read=3.666
 Planning:
   Buffers: shared hit=97 read=1
   I/O Timings: shared read=2.751
 Planning Time: 6.636 ms
 Execution Time: 98.657 ms
(13 filas)
```

- **`pedidos_cliente_id_idx` existe y no aparece**: es la razón 5 de `03/06`. Con un índice en la
  otra rama, el motor los combina con un `BitmapOr`:

```text
tienda=# CREATE INDEX pedidos_estado_idx ON pedidos (estado);
CREATE INDEX
tienda=# EXPLAIN (ANALYZE, BUFFERS, COSTS OFF) SELECT count(*) FROM pedidos WHERE cliente_id = 311 OR estado = 'ANULADO';
                                                 QUERY PLAN
-------------------------------------------------------------------------------------------------------------
 Aggregate (actual time=263.595..263.596 rows=1.00 loops=1)
   Buffers: shared hit=2165 read=8637
   I/O Timings: shared read=182.523
   ->  Bitmap Heap Scan on pedidos (actual time=4.677..257.093 rows=60049.00 loops=1)
         Recheck Cond: ((cliente_id = 311) OR (estado = 'ANULADO'::text))
         Heap Blocks: exact=10743
         Buffers: shared hit=2165 read=8637
         I/O Timings: shared read=182.523
         ->  BitmapOr (actual time=3.441..3.441 rows=0.00 loops=1)
               Buffers: shared hit=6 read=53
               I/O Timings: shared read=1.402
               ->  Bitmap Index Scan on pedidos_cliente_id_idx (actual time=0.088..0.088 rows=52.00 loops=1)
                     Index Cond: (cliente_id = 311)
                     Index Searches: 1
                     Buffers: shared hit=6
               ->  Bitmap Index Scan on pedidos_estado_idx (actual time=3.341..3.341 rows=60000.00 loops=1)
                     Index Cond: (estado = 'ANULADO'::text)
                     Index Searches: 1
                     Buffers: shared read=53
                     I/O Timings: shared read=1.402
 Planning:
   Buffers: shared hit=22 read=1
   I/O Timings: shared read=0.050
 Planning Time: 0.608 ms
 Execution Time: 263.690 ms
(25 filas)
```

- **Aparece el `BitmapOr` y tarda más: 263 ms contra 98.** Son los 182 ms de `I/O Timings`: el `Seq
  Scan` no dejó la tabla en caché —los barridos de tablas grandes usan un anillo pequeño de páginas
  para no vaciarla—, y el mapa de bits leyó 8 637 páginas en frío.
- **`Heap Blocks: exact=10743`**: las 60 049 filas están en casi todas las páginas. El índice ahorra
  evaluar el filtro, no leer la tabla.

**La misma comparación en caliente**, forzando el `Seq Scan` con `enable_bitmapscan = off`, que no
lo prohíbe sino que lo encarece, y se devuelve con `RESET`:

```text
tienda=# EXPLAIN (ANALYZE, BUFFERS, COSTS OFF, TIMING OFF) SELECT count(*) FROM pedidos WHERE cliente_id = 311 OR estado = 'ANULADO';
                                        QUERY PLAN
-------------------------------------------------------------------------------------------
 Aggregate (actual rows=1.00 loops=1)
   Buffers: shared hit=10799
   ->  Bitmap Heap Scan on pedidos (actual rows=60049.00 loops=1)
         Recheck Cond: ((cliente_id = 311) OR (estado = 'ANULADO'::text))
         Heap Blocks: exact=10743
         Buffers: shared hit=10799
         ->  BitmapOr (actual rows=0.00 loops=1)
               Buffers: shared hit=56
               ->  Bitmap Index Scan on pedidos_cliente_id_idx (actual rows=52.00 loops=1)
                     Index Cond: (cliente_id = 311)
                     Index Searches: 1
                     Buffers: shared hit=3
               ->  Bitmap Index Scan on pedidos_estado_idx (actual rows=60000.00 loops=1)
                     Index Cond: (estado = 'ANULADO'::text)
                     Index Searches: 1
                     Buffers: shared hit=53
 Planning Time: 0.150 ms
 Execution Time: 38.229 ms
(18 filas)

tienda=# SET enable_bitmapscan = off;
SET
tienda=# EXPLAIN (ANALYZE, BUFFERS, COSTS OFF, TIMING OFF) SELECT count(*) FROM pedidos WHERE cliente_id = 311 OR estado = 'ANULADO';
                             QUERY PLAN
--------------------------------------------------------------------
 Aggregate (actual rows=1.00 loops=1)
   Buffers: shared hit=10770
   ->  Seq Scan on pedidos (actual rows=60049.00 loops=1)
         Filter: ((cliente_id = 311) OR (estado = 'ANULADO'::text))
         Rows Removed by Filter: 939951
         Buffers: shared hit=10770
 Planning Time: 0.205 ms
 Execution Time: 70.851 ms
(8 filas)

tienda=# RESET enable_bitmapscan;
RESET
tienda=# DROP INDEX pedidos_estado_idx;
DROP INDEX
```

- **En caliente gana el mapa de bits, 38 ms contra 71**, leyendo casi las mismas páginas en los dos.
  La diferencia es de CPU: el `Seq Scan` evalúa el `OR` sobre un millón de filas. `TIMING OFF` quita
  los tiempos por nodo, que cuesta medir, y deja el total.

> **⚠️ Advertencia.** La primera ejecución paga la caché. Compara dos planes en las mismas
> condiciones —los dos en caliente o los dos en frío— o compararás el disco, no el plan.

---

## 5. 🩺 Paso 4 — `LIKE` y la colación

**El caso**: `pedidos_codigo_key`, el índice del `UNIQUE`, ordena según la colación de la base,
`en_US.utf8`. `LIKE 'PED-0004%'` necesita el orden **byte a byte** para volverse un rango. `~~` es
el nombre interno de `LIKE`.

```text
tienda=# SELECT count(*) FROM pedidos WHERE codigo LIKE 'PED-0004%';
 count
-------
    10
(1 fila)

tienda=# EXPLAIN (ANALYZE, BUFFERS, COSTS OFF, TIMING OFF) SELECT count(*) FROM pedidos WHERE codigo LIKE 'PED-0004%';
                      QUERY PLAN
-------------------------------------------------------
 Aggregate (actual rows=1.00 loops=1)
   Buffers: shared hit=10770
   ->  Seq Scan on pedidos (actual rows=10.00 loops=1)
         Filter: (codigo ~~ 'PED-0004%'::text)
         Rows Removed by Filter: 999990
         Buffers: shared hit=10770
 Planning Time: 0.559 ms
 Execution Time: 87.026 ms
(8 filas)
```

La corrección es un índice con la clase de operadores que compara bytes:

```text
tienda=# \timing on
El despliegue de duración está activado.
tienda=# CREATE INDEX pedidos_codigo_patron_idx ON pedidos (codigo text_pattern_ops);
CREATE INDEX
Duración: 357,702 ms
tienda=# \timing off
El despliegue de duración está desactivado.
tienda=# EXPLAIN (ANALYZE, BUFFERS, COSTS OFF, TIMING OFF) SELECT count(*) FROM pedidos WHERE codigo LIKE 'PED-0004%';
                                          QUERY PLAN
----------------------------------------------------------------------------------------------
 Aggregate (actual rows=1.00 loops=1)
   Buffers: shared hit=10 read=3
   I/O Timings: shared read=0.050
   ->  Index Only Scan using pedidos_codigo_patron_idx on pedidos (actual rows=10.00 loops=1)
         Index Cond: ((codigo ~>=~ 'PED-0004'::text) AND (codigo ~<~ 'PED-0005'::text))
         Filter: (codigo ~~ 'PED-0004%'::text)
         Heap Fetches: 10
         Index Searches: 1
         Buffers: shared hit=10 read=3
         I/O Timings: shared read=0.050
 Planning:
   Buffers: shared hit=62 read=4
   I/O Timings: shared read=0.822
 Planning Time: 1.722 ms
 Execution Time: 0.167 ms
(15 filas)

tienda=# EXPLAIN (COSTS OFF) SELECT codigo FROM pedidos ORDER BY codigo LIMIT 3;
                        QUERY PLAN
-----------------------------------------------------------
 Limit
   ->  Index Only Scan using pedidos_codigo_key on pedidos
(2 filas)

tienda=# DROP INDEX pedidos_codigo_patron_idx;
DROP INDEX
```

- **El `LIKE` se volvió un rango** con los operadores de `text_pattern_ops`, `~>=~` y `~<~`: de
  87 ms a 0,167 ms. `Heap Fetches: 10` es la razón 6 de `03/06` en pequeño: el mapa de visibilidad
  vacío obliga a volver al heap.
- **Cada índice sirve para su orden**: `ORDER BY codigo` sigue usando el de la colación. La
  corrección es **añadir** un índice, con su construcción y su escritura extra; con la base en
  colación `C`, uno serviría para los dos.

---

## 6. 🩺 Paso 5 — El plan genérico y el índice parcial

**El caso**: un índice parcial solo se usa si el planificador **demuestra** que el `WHERE` de la
consulta implica el del índice. Con el valor en `$1` y un plan genérico, no sabe qué vale.

```text
tienda=# CREATE INDEX pedidos_anulados_idx ON pedidos (creado_en) WHERE estado = 'ANULADO';
CREATE INDEX
tienda=# PREPARE anulados_recientes (text) AS SELECT count(*) FROM pedidos WHERE estado = $1 AND creado_en >= timestamptz '2025-09-01';
PREPARE
tienda=# EXPLAIN (COSTS OFF) EXECUTE anulados_recientes('ANULADO');
                                                        QUERY PLAN
--------------------------------------------------------------------------------------------------------------------------
 Aggregate
   ->  Bitmap Heap Scan on pedidos
         Recheck Cond: ((creado_en >= '2025-09-01 00:00:00+00'::timestamp with time zone) AND (estado = 'ANULADO'::text))
         ->  Bitmap Index Scan on pedidos_anulados_idx
               Index Cond: (creado_en >= '2025-09-01 00:00:00+00'::timestamp with time zone)
(5 filas)

tienda=# EXPLAIN (GENERIC_PLAN, COSTS OFF) SELECT count(*) FROM pedidos WHERE estado = $1 AND creado_en >= timestamptz '2025-09-01';
                                              QUERY PLAN
-------------------------------------------------------------------------------------------------------
 Aggregate
   ->  Seq Scan on pedidos
         Filter: ((creado_en >= '2025-09-01 00:00:00+00'::timestamp with time zone) AND (estado = $1))
(3 filas)
```

- `PREPARE` guarda una sentencia con parámetros, como hace tu driver; `EXECUTE` la corre. Las
  primeras ejecuciones se planifican **con el valor real** y ven el parcial. `EXPLAIN
  (GENERIC_PLAN)` enseña el plan sin valor: `Seq Scan`. Es el que PostgreSQL puede guardar tras
  cinco ejecuciones si su coste sale parecido.

Forzando cada modo con `plan_cache_mode`, y devolviéndolo con `RESET`:

```text
tienda=# SET plan_cache_mode = force_generic_plan;
SET
tienda=# EXPLAIN (ANALYZE, COSTS OFF, TIMING OFF) EXECUTE anulados_recientes('ANULADO');
                                              QUERY PLAN
-------------------------------------------------------------------------------------------------------
 Aggregate (actual rows=1.00 loops=1)
   Buffers: shared hit=10770
   ->  Seq Scan on pedidos (actual rows=1507.00 loops=1)
         Filter: ((creado_en >= '2025-09-01 00:00:00+00'::timestamp with time zone) AND (estado = $1))
         Rows Removed by Filter: 998493
         Buffers: shared hit=10770
 Planning Time: 0.805 ms
 Execution Time: 70.694 ms
(8 filas)

tienda=# RESET plan_cache_mode;
RESET
tienda=# EXPLAIN (ANALYZE, COSTS OFF, TIMING OFF) EXECUTE anulados_recientes('ANULADO');
                                                        QUERY PLAN
--------------------------------------------------------------------------------------------------------------------------
 Aggregate (actual rows=1.00 loops=1)
   Buffers: shared hit=1405 read=6
   I/O Timings: shared read=0.251
   ->  Bitmap Heap Scan on pedidos (actual rows=1507.00 loops=1)
         Recheck Cond: ((creado_en >= '2025-09-01 00:00:00+00'::timestamp with time zone) AND (estado = 'ANULADO'::text))
         Heap Blocks: exact=1405
         Buffers: shared hit=1405 read=6
         I/O Timings: shared read=0.251
         ->  Bitmap Index Scan on pedidos_anulados_idx (actual rows=1507.00 loops=1)
               Index Cond: (creado_en >= '2025-09-01 00:00:00+00'::timestamp with time zone)
               Index Searches: 1
               Buffers: shared hit=1405 read=6
               I/O Timings: shared read=0.251
 Planning Time: 0.148 ms
 Execution Time: 5.241 ms
(15 filas)

tienda=# DEALLOCATE anulados_recientes;
DEALLOCATE
tienda=# DROP INDEX pedidos_anulados_idx;
DROP INDEX
```

- **La misma sentencia, 70,7 ms contra 5,2 ms**: solo cambió si el plan sabía el valor. Es el caso
  del «en `psql` se usaba»: con un driver que prepara sentencias, el parcial puede desaparecer a la
  sexta ejecución sin tocar el código.
- **La corrección depende de cuántos valores haya**: si siempre es `ANULADO`, el literal en el SQL;
  si son varios, un parcial por valor no es la herramienta, y sí uno sobre `(estado, creado_en)`.

---

## 7. 📜 Estándar, motor y convención

> **📜 Estándar o motor.** ISO/IEC 9075 no define índices, ni `EXPLAIN`, ni planes preparados con
> caché: todo este lab es de PostgreSQL. Los equivalentes de los otros motores se comportan
> distinto.

| Pieza | PostgreSQL 18 | MySQL 9.7 | SQLite 3.53 |
|---|---|---|---|
| Plan con lo que pasó de verdad | `EXPLAIN (ANALYZE, BUFFERS)` | `EXPLAIN ANALYZE` | No: `EXPLAIN QUERY PLAN`, sin ejecutar |
| Índice sin bloquear escrituras | `CREATE INDEX CONCURRENTLY`, fuera de transacción | `ALGORITHM=INPLACE, LOCK=NONE` | No aplica: un solo escritor |
| Combinar índices para un `OR` | `BitmapOr` | *Index merge* | `MULTI-INDEX OR`, sin mapa de bits |
| `LIKE` con prefijo sobre un índice | Con colación `C` o `text_pattern_ops` | Sí, con el índice normal | No con el `LIKE` por defecto, que no distingue mayúsculas |

**Convención, la que más se repite.** *«Si el índice existe y no se usa, el motor se equivoca»* — en
los tres casos el motor hizo lo correcto con lo que sabía: un `OR` no cabe en un índice de una rama,
un orden de colación no sirve para un patrón de bytes y un plan sin el valor no demuestra nada.

---

## ⚠️ Errores frecuentes

| Se dice | Lo preciso |
|---|---|
| "Con un índice en `cliente_id`, el `OR` con `estado` lo usa" | Hace falta uno por rama; con uno solo, `Seq Scan` |
| "El `BitmapOr` fue más lento, el índice sobra" | En frío pagó el disco; en caliente ganó, 38 ms contra 71 |
| "`LIKE 'X%'` usa el índice de la columna" | Solo con colación `C` o `text_pattern_ops`; con `en_US.utf8`, barrió la tabla |
| "Si en `psql` usa el parcial, en la aplicación también" | Con plan genérico desaparece: 70,7 ms contra 5,2 |

---

## 🧪 Ejercicios

1. Mide cuánto tarda `DROP INDEX pedidos_cliente_id_idx` frente a su creación, y explica la
   diferencia. 🟢
2. Reproduce la razón 1 de `03/06`: `WHERE lower(email) = 'cliente311@ejemplo.test'` sobre
   `clientes`, antes y después de un índice funcional. Bórralo al terminar. 🟡
3. Reescribe la consulta de §4 como dos consultas unidas con `UNION`, con solo el índice de
   `cliente_id`, y compara plan y tiempo con el `BitmapOr`. 🟡
4. Reproduce la razón 2: un índice `(producto_id, cantidad)` sobre `pedido_lineas` y `WHERE cantidad
   = 5`. Compara su `Index Searches` con los 51 de `03/06` §3. Bórralo. 🟠
5. Ejecuta seis veces `EXECUTE anulados_recientes('ANULADO')` sin forzar nada y mira si el plan
   cambia y en qué ejecución. Explícalo con §6. 🟠
6. Crea el índice de §5 como `(codigo COLLATE "C")` y comprueba si sirve para el `LIKE` y para
   `ORDER BY codigo`. 🔴
7. Rompe un índice con `statement_timeout` durante un `CREATE INDEX CONCURRENTLY`, como en `03/06`
   §6, y encuéntralo con `pg_index`. 🔥 *(fuera de conteo)*

---

## 📚 Para profundizar

- **Documentación** — PostgreSQL 18, «Using EXPLAIN».
  <https://www.postgresql.org/docs/18/using-explain.html>
- **Documentación** — PostgreSQL 18, «Combining Multiple Indexes»: el `BitmapOr`.
  <https://www.postgresql.org/docs/18/indexes-bitmap-scans.html>
- **Documentación** — PostgreSQL 18, «Operator Classes and Operator Families»: `text_pattern_ops`.
  <https://www.postgresql.org/docs/18/indexes-opclass.html>
- **Documentación** — PostgreSQL 18, `PREPARE`: planes personalizados y genéricos.
  <https://www.postgresql.org/docs/18/sql-prepare.html>
- **Documentación** — PostgreSQL 18, `CREATE INDEX`: «Building Indexes Concurrently».
  <https://www.postgresql.org/docs/18/sql-createindex.html>

---

## 🧠 Preguntas

1. ¿Qué añaden `ANALYZE` y `BUFFERS` a un `EXPLAIN`? 🟢
2. ¿Qué diferencia hay entre `Duración` de `\timing` y `Execution Time` del plan? 🟢
3. ¿Qué significan los prompts `tienda=#`, `tienda=>`, `tienda=*#` y `tienda=!#`? 🟢
4. ¿Qué hace `text_pattern_ops` en un índice? 🟢
5. Distingue `Filter` de `Index Cond` en un plan. 🟡
6. ¿Por qué `CREATE INDEX CONCURRENTLY` no puede ir dentro de una transacción? 🟡
7. ¿Por qué el `LIKE 'PED-0004%'` no usa `pedidos_codigo_key`, y por qué el `ORDER BY codigo` sí? 🟡
8. Distingue un plan personalizado de uno genérico en una sentencia preparada. 🟡
9. ¿Qué parte de lo visto en este lab es del estándar y qué parte del motor? Da dos ejemplos. 🟡
10. ¿Por qué el `BitmapOr` tardó 263 ms la primera vez y 38 ms después? 🟠
11. ¿Por qué un `OR` entre dos columnas necesita un índice por rama? 🟠
12. ¿Por qué el `Index Scan` de `CLI-00311` tocó 9 páginas y el de `cliente_id = 4210`, 31? 🟠
13. ¿Qué harías con un índice parcial que tu aplicación deja de usar tras unas ejecuciones? 🟠
14. Diagnostica: una migración falla con `CREATE INDEX CONCURRENTLY cannot run inside a transaction
    block`. Da la causa y la corrección en la herramienta de migraciones. 🔴
15. Diseña, con las sesiones de este lab, la prueba que demuestra si el motor tenía razón al no usar
    un índice. Escribe las sentencias. 🔴

---

**Anterior:** [`l00`](l00-el-entorno-y-los-datos.md) — el entorno y los datos · **Siguiente:**
[`l02`](l02-aislamiento-y-bloqueos-en-vivo.md) — aislamiento y bloqueos en vivo · **Relacionado:**
[`03/06`](../03-el-motor-por-dentro/06-cuando-el-indice-no-se-usa.md) §6 — la razón 5, con los tres
casos que este lab corre.
