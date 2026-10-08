# 05 — `EXPLAIN` y `EXPLAIN ANALYZE`

> Cómo se lee un plan de ejecución: en qué orden se recorre, qué significa cada número, en qué se
> diferencia lo que el planificador **estima** de lo que la consulta **hizo**, y los nodos que hay
> que reconocer de un vistazo. **Asume leído:** [`04`](04-estadisticas-y-el-planificador.md), de
> donde salen la selectividad y las estimaciones. **Vigencia:** 23 de septiembre de 2026.

---

## Salto rápido

- [1. El problema](#1--el-problema) · [2. Cómo se
  lee](#2--cómo-se-lee-un-plan-de-dentro-hacia-fuera) · [3. Cada
  número](#3--qué-significa-cada-número) · [4. `ANALYZE`](#4-️-explain-frente-a-explain-analyze)
- [5. Las opciones](#5--las-opciones) · [6. La brecha](#6--la-brecha-entre-lo-estimado-y-lo-real) ·
  [7. Los nodos](#7--los-nodos-que-hay-que-reconocer) · [8. `Gather`](#8--gather-y-el-paralelismo)
- [9. MySQL y SQLite](#9-️-el-mismo-plan-en-mysql-y-en-sqlite) · [10. Estándar, motor y
  convención](#10--estándar-motor-y-convención) · [Errores frecuentes](#️-errores-frecuentes) · [Para
  profundizar](#-para-profundizar) · [Preguntas](#-preguntas)

---

## 1. 🎯 El problema

El panel de `CLI-00311` pide cuántos pedidos tiene: son 52, y no hay nada que optimizar a la vista.

```text
tienda=# SELECT count(*) FROM pedidos p JOIN clientes c ON c.id = p.cliente_id
tienda-#  WHERE c.codigo = 'CLI-00311';
 count
-------
    52
(1 fila)

Duración: 86,492 ms
```

**Ochenta y seis milisegundos para devolver un número de dos cifras**, por los 200 paneles que se
abren cada minuto. Para ver qué hace el motor hay que preguntarle qué pensaba hacer y qué hizo: eso
es `EXPLAIN`, y este es el capítulo que el resto del corpus da por leído.

---

## 2. 🧱 Cómo se lee un plan: de dentro hacia fuera

Un **plan de ejecución** es el árbol de operaciones que el motor decidió ejecutar. `EXPLAIN` lo
imprime; `EXPLAIN ANALYZE` lo imprime **después de correr la consulta**, con lo que pasó de verdad.

```text
tienda=# EXPLAIN (ANALYZE, BUFFERS OFF) SELECT count(*) FROM pedidos p
tienda-#   JOIN clientes c ON c.id = p.cliente_id WHERE c.codigo = 'CLI-00311';
                                                                     QUERY PLAN
-----------------------------------------------------------------------------------------------------------------------------------------------------
 Aggregate  (cost=30267.79..30267.80 rows=1 width=8) (actual time=109.545..109.551 rows=1.00 loops=1)
   ->  Hash Join  (cost=2.52..30267.74 rows=20 width=0) (actual time=50.794..109.539 rows=52.00 loops=1)
         Hash Cond: (p.cliente_id = c.id)
         ->  Seq Scan on pedidos p  (cost=0.00..27640.00 rows=1000000 width=8) (actual time=0.022..60.962 rows=1000000.00 loops=1)
         ->  Hash  (cost=2.51..2.51 rows=1 width=8) (actual time=0.049..0.050 rows=1.00 loops=1)
               Buckets: 1024  Batches: 1  Memory Usage: 9kB
               ->  Index Scan using clientes_codigo_key on clientes c  (cost=0.29..2.51 rows=1 width=8) (actual time=0.046..0.046 rows=1.00 loops=1)
                     Index Cond: (codigo = 'CLI-00311'::text)
                     Index Searches: 1
 Planning Time: 0.966 ms
 Execution Time: 109.598 ms
(11 filas)
```

**La regla de lectura es la única que hay que memorizar: de dentro hacia fuera y de abajo hacia
arriba.** Cada `->` abre un hijo y la indentación marca la profundidad; el nodo **más indentado
corre primero** y el de arriba del todo es el **último**, el que entrega el resultado.

1. `Index Scan using clientes_codigo_key` —el más indentado— baja por el índice de `clientes.codigo`
   y saca **una fila**, el cliente 311; con ella, `Hash` construye una tabla hash en memoria de
   `Buckets: 1024` y 9 kB.
3. `Seq Scan on pedidos` lee **la tabla entera**, el millón de filas.
4. `Hash Join` prueba cada una contra esa tabla hash —es lo que dice `Hash Cond`— y deja pasar las
   52 que emparejan, que `Aggregate` cuenta.

Ahí está la respuesta a §1: **el paso 3**. Para 52 filas el motor leyó un millón, y los 60,962 ms
del `Seq Scan` son más de la mitad del tiempo; `Planning Time` y `Execution Time` son cosas
distintas, 0,966 ms pensando contra 109,598 ms ejecutando.

- **Los dos hijos de un join no son intercambiables:** el **primero** es el externo (*outer*), el
  que se recorre; el segundo, el interno (*inner*), el que se sondea y —en un `Hash Join`— el que se
  vuelve tabla hash, que por eso es el lado pequeño.

> **🧠 Modelo mental.** Un plan no es una lista de pasos: es un árbol que empuja filas hacia arriba.
> Cada nodo pide filas a sus hijos y se las entrega a su padre. Leerlo de arriba abajo, como un
> programa, es lo que impide ver dónde se va el tiempo.

---

## 3. 🧱 Qué significa cada número

Cada nodo lleva dos paréntesis: **el primero es lo que el planificador creyó, el segundo lo que
pasó**. Sin `ANALYZE` solo existe el primero.

| Número | Qué es | La trampa |
|---|---|---|
| `cost=0.00..27640.00` | **Dos** costes: el de la **primera** fila y el de la **última** | No son milisegundos: son unidades arbitrarias del planificador |
| `rows=1000000` | Filas que el planificador **estima** que saldrán del nodo | Es una predicción, y falla por órdenes de magnitud |
| `width=8` | Bytes por fila que ese nodo entrega hacia arriba | Solo de las columnas que propaga, no de la fila entera |
| `actual time=0.022..60.962` | Milisegundos hasta la primera fila y hasta la última | **Por iteración**; con `loops>1` hay que multiplicar |
| `rows=1000000.00` | Filas que salieron de verdad, **promediadas por iteración** | Por eso lleva decimales |
| `loops=1` | Cuántas veces se ejecutó el nodo | Es el multiplicador de todo lo anterior |

La unidad del coste está anclada en **`seq_page_cost`, que vale 1,0 y es leer una página en
secuencia**; todo se mide contra eso. Un coste de 27 640 son "unas 27 640 veces leer una página
secuencial": **solo sirve para comparar dos planes de la misma consulta**, nunca para predecir un
tiempo. Y hay dos porque un `Sort` no entrega nada hasta ordenarlo todo y un `Seq Scan` suelta filas
desde 0,00; con un `LIMIT 5`, eso decide.

**`loops` es el número que más se lee mal.** Aquí está, en un `Nested Loop`:

```text
tienda=# EXPLAIN (ANALYZE, BUFFERS OFF) SELECT p.id, l.linea FROM pedidos p
tienda-#   JOIN pedido_lineas l ON l.pedido_id = p.id WHERE p.id < 1000;
                                                                     QUERY PLAN
-----------------------------------------------------------------------------------------------------------------------------------------------------
 Nested Loop  (cost=0.85..2664.59 rows=3549 width=10) (actual time=0.017..1.756 rows=3499.00 loops=1)
   ->  Index Only Scan using pedidos_pkey on pedidos p  (cost=0.42..1040.13 rows=1014 width=8) (actual time=0.010..0.611 rows=999.00 loops=1)
         Index Cond: (id < 1000)
         Heap Fetches: 999
         Index Searches: 1
   ->  Index Only Scan using pedido_lineas_pkey on pedido_lineas l  (cost=0.43..1.56 rows=4 width=10) (actual time=0.001..0.001 rows=3.50 loops=999)
         Index Cond: (pedido_id = p.id)
         Heap Fetches: 120
         Index Searches: 999
 Planning Time: 0.426 ms
 Execution Time: 1.867 ms
(11 filas)
```

- El hijo interno dice `rows=3.50 loops=999`. **No devolvió 3,5 filas: devolvió 3 499**, que es 3,50
  × 999; los decimales son el promedio de 999 iteraciones, y `Index Searches: 999` lo confirma.
- Lo mismo con el tiempo: `actual time=0.001..0.001` es **por vuelta**. Un nodo con `actual time=0.8
  loops=5000` se comió cuatro segundos y parece que tardó menos de uno. **Es la causa número uno de
  leer mal un plan de `Nested Loop`.**

> **⚠️ Advertencia.** El tiempo de un nodo **incluye el de sus hijos**. Para saber qué cuesta por sí
> mismo hay que restar: en §2 el `Hash Join` marca 109,539 ms, pero 60,962 son del `Seq Scan`.

---

## 4. ⚖️ `EXPLAIN` frente a `EXPLAIN ANALYZE`

**`EXPLAIN` a secas no ejecuta la consulta**: le pide el plan al planificador, es instantáneo y solo
trae la mitad izquierda de los números de §3. **`EXPLAIN ANALYZE` sí la ejecuta**, y por eso añade
`actual time`, `actual rows`, `loops` y `Rows Removed by Filter`. De ahí la advertencia que hay que
dar siempre, porque en pantalla no aparece ninguna:

> **⚠️ Advertencia.** `EXPLAIN ANALYZE` sobre un `INSERT`, un `UPDATE`, un `DELETE` o un `MERGE`
> **ejecuta la escritura**. No la simula: tu tabla queda modificada.

`PED-00042` está `PAGADO` y con `actualizado_en` nulo; la demostración es la forma segura de
hacerlo:

```text
tienda=# BEGIN;
BEGIN
tienda=*# EXPLAIN ANALYZE UPDATE pedidos SET estado = 'ENVIADO', actualizado_en = now()
tienda-*#  WHERE codigo = 'PED-00042';
                                                              QUERY PLAN
--------------------------------------------------------------------------------------------------------------------------------------
 Update on pedidos  (cost=0.42..2.65 rows=0 width=0) (actual time=0.193..0.193 rows=0.00 loops=1)
   Buffers: shared hit=44 dirtied=1
   ->  Index Scan using pedidos_codigo_key on pedidos  (cost=0.42..2.65 rows=1 width=46) (actual time=0.007..0.007 rows=1.00 loops=1)
         Index Cond: (codigo = 'PED-00042'::text)
         Index Searches: 1
         Buffers: shared hit=4
 Planning:
   Buffers: shared hit=3
 Planning Time: 0.025 ms
 Execution Time: 0.226 ms
(10 filas)

tienda=*# SELECT estado, actualizado_en FROM pedidos WHERE codigo = 'PED-00042';
 estado  |        actualizado_en
---------+-------------------------------
 ENVIADO | 2026-09-20 16:21:30.686708+00
(1 fila)

tienda=*# ROLLBACK;
ROLLBACK
tienda=# SELECT estado, actualizado_en FROM pedidos WHERE codigo = 'PED-00042';
 estado | actualizado_en
--------+----------------
 PAGADO |
(1 fila)
```

- El pedido **cambió de verdad** y el `ROLLBACK` lo devolvió. `dirtied=1` es la página que se
  ensució al escribir; el `rows=0.00` del nodo `Update` es porque un `UPDATE` sin `RETURNING` no
  entrega filas hacia arriba: las que tocó se cuentan en el hijo.
- **La forma segura es siempre `BEGIN; EXPLAIN ANALYZE …; ROLLBACK;`**. **Cuánto cuesta:** la
  escritura ocurre igual —WAL, páginas sucias y la fila bloqueada hasta el `ROLLBACK`—, así que en
  producción no sale gratis aunque se deshaga.

> **Veredicto:** `EXPLAIN` para mirar, `EXPLAIN ANALYZE` para medir, y envuelto en `BEGIN …
> ROLLBACK` en cuanto la sentencia escriba.

---

## 5. 🧱 Las opciones

La sintaxis es `EXPLAIN (opción, opción) consulta`.

| Opción | Qué hace | Cuándo |
|---|---|---|
| `ANALYZE` | Ejecuta y añade los números reales | Siempre que puedas ejecutar |
| `BUFFERS` | Páginas leídas de caché, de disco, escritas y ensuciadas | Cuando el tiempo no es estable |
| `COSTS OFF` | Quita las estimaciones | Para pegar un plan en un documento o en un test |
| `TIMING OFF` | Quita los tiempos por nodo y deja `rows` y `loops` | Cuando leer el reloj distorsiona la medida |
| `SETTINGS` | Los parámetros del planificador cambiados respecto del arranque | Cuando el plan no se reproduce en otra máquina |
| `FORMAT JSON` | El mismo árbol como objetos, con una clave por número de §3 | Para herramientas, no para leer |

**`BUFFERS` es la opción que de verdad mide el trabajo** —los milisegundos dependen de qué había en
la caché y las páginas no— y 📝 desde PostgreSQL 18 viene incluida con `ANALYZE` sin pedirla:

```text
tienda=# EXPLAIN (ANALYZE, COSTS OFF) SELECT count(*) FROM pagos WHERE metodo = 'EFECTIVO';
                                 QUERY PLAN
----------------------------------------------------------------------------
 Aggregate (actual time=59.115..59.124 rows=1.00 loops=1)
   Buffers: shared read=8232
   I/O Timings: shared read=1.830
   ->  Seq Scan on pagos (actual time=0.137..48.733 rows=273126.00 loops=1)
         Filter: (metodo = 'EFECTIVO'::text)
         Rows Removed by Filter: 546874
         Buffers: shared read=8232
         I/O Timings: shared read=1.830
 Planning:
   Buffers: shared hit=78 read=2
   I/O Timings: shared read=0.030
 Planning Time: 0.351 ms
 Execution Time: 59.164 ms
(13 filas)
```

- **8 232 páginas.** Ese es el trabajo y no se mueve: 8 232 × 8 kB ≈ 64 MB recorridos para contar
  273 126 filas. La segunda ejecución seguida —que no pego por espacio— imprime las mismas 8 232
  páginas con otro reparto, `shared hit=188 read=8044`, y 57,328 ms en lugar de 59,164: **los
  milisegundos bailan casi dos sin que nada cambie, y eso no es información.** El `Index Scan` de §4
  resuelve lo suyo con cuatro páginas: esa es la única moneda que no depende de la máquina.

`SETTINGS` responde a *"¿por qué a ti te sale otro plan?"*: añade una línea con lo que está
cambiado, aquí la configuración fija del laboratorio —`effective_cache_size = '1GB', work_mem =
'8MB', random_page_cost = '1.1', max_parallel_workers_per_gather = '0', jit = 'off'`—. `COSTS OFF`
deja legible un plan corto; `TIMING OFF` quita el reloj, que con millones de iteraciones cuesta; y
`FORMAT JSON` da el mismo árbol con `"Node Type"` y `"Actual Rows"`, para un visualizador.

---

## 6. 🩺 La brecha entre lo estimado y lo real

**Lo primero que se mira en un plan no es el tiempo: es la distancia entre `rows=` y `actual
rows`.** Si el planificador cree que va a sacar 20 500 filas y saca un millón y medio, **todas las
decisiones que tomó a partir de ahí están mal**: eligió `Hash Join` donde tocaba `Nested Loop` y
descartó un índice que habría servido. El caso más limpio está en `eventos_pedido.carga`, que es
`jsonb`: con una clave que no existe —`carga->>'canal' = 'web'`— estima `rows=20500`, lee las 4 100
000 filas y no devuelve ninguna (ese plan no lo pego por espacio); con una que sí existe, la
estimación es **la misma**:

```text
tienda=# EXPLAIN (ANALYZE, BUFFERS OFF) SELECT count(*) FROM eventos_pedido WHERE carga->>'origen' = 'movil';
                                                            QUERY PLAN
----------------------------------------------------------------------------------------------------------------------------------
 Aggregate  (cost=143568.80..143568.81 rows=1 width=8) (actual time=523.900..523.900 rows=1.00 loops=1)
   ->  Seq Scan on eventos_pedido  (cost=0.00..143517.55 rows=20500 width=0) (actual time=0.038..476.259 rows=1366667.00 loops=1)
         Filter: ((carga ->> 'origen'::text) = 'movil'::text)
         Rows Removed by Filter: 2733333
 Planning Time: 0.173 ms
 Execution Time: 523.944 ms
(6 filas)
```

- **La misma estimación exacta, `rows=20500`, para una consulta que devuelve 0 y otra que devuelve 1
  366 667.** No es que el planificador se equivoque: **no tiene nada que consultar** y cae en su
  selectividad por defecto, así que ese `20500` es una constante disfrazada de estimación.
- **Qué hacer con una brecha así** —estadísticas primero, y luego algo medible sobre la expresión—
  es de [`04`](04-estadisticas-y-el-planificador.md), el dueño de por qué salen esos `rows=`.

> **🩺 Diagnóstico.** Recorre el plan de abajo arriba buscando **el primer nodo donde `rows` y
> `actual rows` se separan más de un orden de magnitud**. Todo lo que hay por encima está construido
> sobre un número falso, y tocar los nodos de arriba no sirve de nada.

---

## 7. 🧱 Los nodos que hay que reconocer

| Nodo | Qué hace | Cuándo lo elige el motor |
|---|---|---|
| `Seq Scan` | Lee la tabla entera, página a página | No hay índice útil, o el filtro deja pasar demasiado |
| `Index Scan` | Baja por el índice y va al heap por cada fila | Pocas filas, y hace falta una columna que el índice no tiene |
| `Index Only Scan` | Resuelve con el índice, sin tocar el heap | El índice cubre todas las columnas pedidas |
| `Bitmap Index Scan` + `Bitmap Heap Scan` | Marca páginas en un mapa de bits y las lee **en orden físico** | Filas intermedias: muchas para `Index Scan`, pocas para `Seq Scan` |
| `Nested Loop` | Por cada fila del externo, busca en el interno | El externo da pocas filas y el interno tiene índice |
| `Hash Join` | Tabla hash con el lado pequeño, sondeo con el grande | Join por igualdad, sin orden aprovechable |
| `Merge Join` | Avanza los dos lados **ya ordenados** a la vez | Ambos llegan ordenados por la clave del join |
| `Sort` | Ordena: `quicksort` o `top-N heapsort` en memoria, `external merge` en disco | `ORDER BY`, `Merge Join`, a veces `GROUP BY` |
| `Gather` | Recoge las filas de los *workers* paralelos | §8 |

En un `Seq Scan` lo que hay que mirar es `Rows Removed by Filter`: en §5, 546 874 filas leídas y
tiradas para quedarse con 273 126. Y en cualquier acceso por índice, **`Index Cond` contra `Filter`
es la distinción que más nota da**: el `Index Cond` se resuelve bajando por el árbol y solo toca las
filas que cumplen; el `Filter` se evalúa sobre filas ya leídas, así que verlo donde esperabas un
`Index Cond` significa que el índice no cubre esa condición.

**`Bitmap Heap Scan`** es el camino de en medio, y lo produce el mismo `pedidos_pkey` de §3 en
cuanto se piden 49 001 filas y una columna que el índice no tiene:

```text
tienda=# EXPLAIN (ANALYZE, BUFFERS OFF) SELECT count(codigo) FROM pedidos WHERE id BETWEEN 1000 AND 50000;
                                                               QUERY PLAN
----------------------------------------------------------------------------------------------------------------------------------------
 Aggregate  (cost=19305.80..19305.81 rows=1 width=8) (actual time=12.210..12.214 rows=1.00 loops=1)
   ->  Bitmap Heap Scan on pedidos  (cost=797.31..19181.73 rows=49628 width=10) (actual time=2.457..10.069 rows=49001.00 loops=1)
         Recheck Cond: ((id >= 1000) AND (id <= 50000))
         Heap Blocks: exact=2253
         ->  Bitmap Index Scan on pedidos_pkey  (cost=0.00..784.90 rows=49628 width=0) (actual time=2.247..2.248 rows=49001.00 loops=1)
               Index Cond: ((id >= 1000) AND (id <= 50000))
               Index Searches: 1
 Planning Time: 0.279 ms
 Execution Time: 12.298 ms
(9 filas)
```

- **Van siempre en pareja.** El `Bitmap Index Scan` recorre el índice y construye un mapa de bits de
  **páginas**, no de filas; el `Bitmap Heap Scan` las lee **en orden físico ascendente** y vuelve a
  aplicar la condición, que es lo que significa `Recheck Cond`.
- **Por qué el motor lo prefiere al `Index Scan`:** este visita el heap en el orden del índice, que
  es aleatorio respecto del disco, y **puede leer la misma página muchas veces**; con 49 001 filas
  en 2 253 páginas —`Heap Blocks: exact=2253`— leerlas una vez y en orden son 12,3 ms. **El
  precio:** el mapa de bits ocupa memoria, y si no cabe en `work_mem` el motor marca páginas enteras
  en lugar de filas, aparece `Heap Blocks: lossy` y el `Recheck` descarta filas de verdad.

**`Merge Join` y `Sort` salen juntos** cuando uno de los lados no llega ordenado; está medido, pero
su plan no lo pego por espacio. Con `SET enable_hashjoin = off` —que se devuelve con `RESET
enable_hashjoin`—, el join de `pedidos` con `pagos` sale como `Merge Join` con `Merge Cond` en vez
de `Hash Cond`: `pedidos` llega ordenado por su clave primaria, con un `Filter` que **descarta 750
000 filas** porque `estado` no está en `pedidos_pkey`, y `pagos` necesita un `Sort` que imprime
**`Sort Method: external merge Disk: 9648kB`**. Esa línea hay que saber leerla: la ordenación **no
cupo** en los 8 MB de `work_mem` y se fue a fichero temporal, así que o se sube `work_mem` o se
reducen filas antes de ordenar; si dijera `quicksort Memory: …`, cabía. **Cuánto cuesta el camino
equivocado:** 876,399 ms contra los 294,761 ms del `Hash Join` que el planificador elige solo.

**Y la respuesta a §1**, con el índice creado dentro de `BEGIN; CREATE INDEX idx_pedidos_cliente ON
pedidos (cliente_id); … ROLLBACK;` —177,321 ms de construcción— y el mismo `EXPLAIN ANALYZE` de §2
repetido dentro de la transacción; tampoco pego ese plan entero, por espacio. **Cambió de forma:**
el `Hash Join` con `Seq Scan` del millón de filas se volvió `Nested Loop` sobre `Index Scan using
clientes_codigo_key` más `Index Only Scan using idx_pedidos_cliente` (`Index Cond: (cliente_id =
c.id)`, `Heap Fetches: 52`), y con él **109,598 ms → 0,092 ms**. **El índice no se queda:**
`ROLLBACK` lo borra, porque PostgreSQL tiene DDL transaccional y un `CREATE INDEX` no concurrente se
deshace como cualquier otra sentencia. **Cuánto costaría dejarlo:** 177 ms de construcción, ~22 MB
de disco y una escritura extra por cada `INSERT` en `pedidos`.

> **💡 Truco.** En una entrevista, señala **`Rows Removed by Filter` y `Sort Method`** antes que
> nada: son los dos sitios donde un plan confiesa que tira trabajo a la basura, y casi nadie los
> nombra.

---

## 8. 🧱 `Gather` y el paralelismo

**Este corpus tiene el paralelismo apagado a propósito**, con `max_parallel_workers_per_gather=0` en
el `compose`: el número de *workers* depende de los núcleos, así que el mismo `SELECT` daría
`Parallel Seq Scan` en un portátil de ocho y `Seq Scan` en uno de dos, y **ningún plan pegado sería
reproducible**. Se enciende en la sesión, se mira y se devuelve:

```text
tienda=# SHOW max_parallel_workers_per_gather;
 max_parallel_workers_per_gather
---------------------------------
 0
(1 fila)

tienda=# SET max_parallel_workers_per_gather = 2;
SET
tienda=# EXPLAIN (ANALYZE, BUFFERS OFF) SELECT count(*) FROM pedidos WHERE estado = 'ENTREGADO';
                                                                  QUERY PLAN
----------------------------------------------------------------------------------------------------------------------------------------------
 Finalize Aggregate  (cost=24155.32..24155.33 rows=1 width=8) (actual time=48.137..51.730 rows=1.00 loops=1)
   ->  Gather  (cost=24155.10..24155.31 rows=2 width=8) (actual time=48.039..51.727 rows=3.00 loops=1)
         Workers Planned: 2
         Workers Launched: 2
         ->  Partial Aggregate  (cost=23155.10..23155.11 rows=1 width=8) (actual time=45.374..45.375 rows=1.00 loops=3)
               ->  Parallel Seq Scan on pedidos  (cost=0.00..22848.33 rows=122708 width=0) (actual time=0.014..41.521 rows=100000.00 loops=3)
                     Filter: (estado = 'ENTREGADO'::text)
                     Rows Removed by Filter: 233333
 Planning Time: 0.097 ms
 Execution Time: 51.749 ms
(10 filas)

tienda=# RESET max_parallel_workers_per_gather;
RESET
```

- **`Workers Planned: 2` contra `Workers Launched: 2`** no siempre coinciden: si el
  `max_parallel_workers` global está agotado se lanzan menos, y la consulta va más lenta sin que el
  plan cambie.
- **`loops=3` en un plan paralelo no son tres iteraciones: son tres procesos**, los dos *workers*
  más el que los coordina; por eso `rows=100000 loops=3` son las 300 000 filas de `ENTREGADO`,
  promediadas, y `Rows Removed by Filter: 233333` va en la misma moneda.
- `Gather` es la costura: debajo todo va en paralelo —`Partial Aggregate` cuenta en cada *worker*,
  `Finalize Aggregate` suma los tres parciales—, encima ya no. **Cuánto cuesta:** 51,749 ms contra
  96,317 ms en serie en la misma sesión (1,9 veces, no 3), y dos procesos más.

> **⚠️ Advertencia.** `SET` vale solo para tu sesión. Si enciendes el paralelismo para mirar un
> plan, **devuélvelo con `RESET`**, o los planes siguientes no se parecerán a los del corpus.

---

## 9. ⚖️ El mismo plan en MySQL y en SQLite

La consulta de §8 en MySQL 9.7.2: `FORMAT=TREE` no ejecuta; `EXPLAIN ANALYZE` sí, y añade tiempo,
filas reales y `loops`, igual que en PostgreSQL.

```text
mysql> EXPLAIN FORMAT=TREE SELECT count(*) FROM pedidos WHERE estado = 'ENTREGADO';
-> Aggregate: count(0)  (cost=123640 rows=1)
    -> Filter: (pedidos.estado = 'ENTREGADO')  (cost=100698 rows=99568)
        -> Table scan on pedidos  (cost=100698 rows=995684)

mysql> EXPLAIN ANALYZE SELECT count(*) FROM pedidos WHERE estado = 'ENTREGADO';
-> Aggregate: count(0)  (cost=123640 rows=1) (actual time=224..224 rows=1 loops=1)
    -> Filter: (pedidos.estado = 'ENTREGADO')  (cost=100698 rows=99568) (actual time=0.126..215 rows=300000 loops=1)
        -> Table scan on pedidos  (cost=100698 rows=995684) (actual time=0.124..148 rows=1e+6 loops=1)
```

```text
sqlite> EXPLAIN QUERY PLAN SELECT count(*) FROM pedidos WHERE estado = 'ENTREGADO';
QUERY PLAN
`--SCAN pedidos
```

> **📜 Estándar o motor.** **Los planes no son comparables nodo a nodo entre motores.** No hay
> equivalencia de nombres, ni de unidades de coste, ni de lo que cuenta un `rows`.

- **La brecha de §6 también existe en MySQL:** `rows=99568` estimadas contra `rows=300000` reales.
  El método se traslada; el vocabulario, no.
- **Ni el esquema es el mismo, aunque el DDL lo parezca.** `SHOW INDEX FROM pedidos` devuelve tres
  índices en MySQL y dos en PostgreSQL: **InnoDB crea uno por cada clave foránea** y PostgreSQL no.
  Eso ya hace que la consulta de §1 salga con `Nested loop` en uno y con `Hash Join` en el otro.
- **SQLite no imprime coste ni filas y no tiene `EXPLAIN ANALYZE`**: pedirlo da `Parse error … near
  "SELECT": syntax error`. Su `EXPLAIN` a secas es otra cosa: el volcado de *bytecode* de su VM.

---

## 10. 📜 Estándar, motor y convención

> **📜 Estándar o motor.** ISO/IEC 9075 es de pago y **no he verificado sus cláusulas**. Lo
> comprobable es que los tres motores implementan `EXPLAIN` con sintaxis, salidas y vocabulario
> **mutuamente incompatibles**: ni la palabra, ni el formato, ni los nodos los fija la norma.

| Afirmación | Estándar | PostgreSQL 18.6 | MySQL 9.7.2 | SQLite 3.53.4 |
|---|---|---|---|---|
| `EXPLAIN` es parte del lenguaje SQL | No verificado; no consta | Sí, `EXPLAIN [(opciones)]` | Sí, `EXPLAIN [FORMAT=…]` | Sí, `EXPLAIN QUERY PLAN` |
| Los nombres de los nodos están fijados | No verificado; no consta | `Seq Scan`, `Hash Join`, `Bitmap Heap Scan` | `Table scan`, `Nested loop inner join`, `Index lookup` | `SCAN`, `SEARCH`, `USE TEMP B-TREE` |
| El coste tiene unidad definida | No verificado; no consta | Arbitraria, con `seq_page_cost = 1.0` de ancla | Arbitraria y en otra escala | **No publica coste** |
| Existe `EXPLAIN ANALYZE` y ejecuta | No verificado; no consta | Sí (medido, §4) | Sí (medido, §9) | **No existe**: error de sintaxis |
| `EXPLAIN ANALYZE` de un `UPDATE` escribe | No verificado; no consta | **Sí** (medido, §4) | **No**: responde `<not executable by iterator executor>` | No aplica |
| `BUFFERS` va incluido en `ANALYZE` | No verificado; no consta | 📝 **Sí desde la 18**; antes había que pedirlo | No existe la opción | No aplica |
| Hay formato de máquina | No verificado; no consta | `FORMAT JSON \| XML \| YAML \| TEXT` | `FORMAT=JSON \| TREE \| TRADITIONAL` | No |

MariaDB 12.3.3 usa otra sintaxis todavía —`ANALYZE FORMAT=JSON`, con `r_rows` y `r_filtered`—; no la
he medido, y por eso no está en la tabla.

**Convención, las dos que más se repiten.** *"El coste está en milisegundos"* se refuta con §3: el
`Seq Scan` de §2 marca `cost=…27640.00` y tardó 60,962 ms. Y *"si sale `Seq Scan` está mal"* sale de
mirar tablas pequeñas: bajar por un índice para traer el 30 % de la tabla es **más caro**, porque
cada fila es un salto al azar en el heap. Un `Seq Scan` es un problema cuando **`Rows Removed by
Filter` es enorme comparado con las filas que salen** —546 874 contra 273 126 en §5—, no por
existir.

---

## ⚠️ Errores frecuentes

| Se dice | Lo preciso |
|---|---|
| "El coste está en milisegundos" | Es una unidad arbitraria con `seq_page_cost = 1.0` de ancla. En §2: coste 27 640 y 60,962 ms |
| "Si sale `Seq Scan`, hay que crear un índice" | Depende de cuántas filas pasan el filtro. Para el 30 % de una tabla, el `Seq Scan` es más barato |
| "`EXPLAIN` es seguro, no toca nada" | `EXPLAIN` sí. **`EXPLAIN ANALYZE` de un `UPDATE` ejecuta la escritura**: medido en §4 |
| "Ese nodo tardó 0,001 ms" | Es por iteración. Con `loops=999` el total es el producto, §3 |
| "El nodo lento es el de mayor `actual time`" | El tiempo incluye el de los hijos. Hay que restar, y empezar por la mayor brecha de §6 |
| "Un `Bitmap Heap Scan` es un `Index Scan` peor" | Es el camino para un número intermedio de filas: lee cada página del heap **una vez** y en orden físico |

---

## 📚 Para profundizar

- **Documentación** — PostgreSQL 18, «Using EXPLAIN»: la lectura del árbol, los dos costes, `loops`
  y los tipos de nodo. <https://www.postgresql.org/docs/18/using-explain.html>
- **Documentación** — PostgreSQL 18, «EXPLAIN»: la referencia de la sentencia y de sus opciones.
  <https://www.postgresql.org/docs/18/sql-explain.html>
- **Documentación** — MySQL 9.7, «Obtaining Query Execution Plan Information»: `FORMAT=TREE` y
  `EXPLAIN ANALYZE`. <https://dev.mysql.com/doc/refman/9.7/en/explain.html>
- **Documentación** — SQLite, «EXPLAIN QUERY PLAN»: cómo se leen `SCAN`, `SEARCH` y `USE TEMP
  B-TREE`. <https://www.sqlite.org/eqp.html>

---

## 🧠 Preguntas

1. ¿En qué orden se lee un plan de ejecución, y cuál es el nodo que corre primero? 🟢
2. `cost=0.00..23270.00` son dos números. ¿Qué es cada uno, y en qué unidad están? 🟢
3. ¿Qué diferencia hay entre `rows=` y `actual rows=`, y cuál de los dos no aparece sin `ANALYZE`? 🟢
4. ¿Qué mide `width=`, y de qué columnas? 🟢
5. Nombra los dos nodos que forman siempre la pareja de un acceso por mapa de bits. 🟢
6. ¿Qué significa `Rows Removed by Filter` y por qué es de lo primero que hay que mirar? 🟢
7. Distingue `EXPLAIN` de `EXPLAIN ANALYZE` en una frase, y di qué pasa si el segundo se corre sobre
   un `DELETE`. 🟡
8. Un nodo dice `actual time=0.001..0.001 rows=3.50 loops=999`. ¿Cuánto tardó y cuántas filas
   devolvió de verdad? 🟡
9. Distingue `Index Cond` de `Filter`. ¿Cuál de los dos delata que el índice no cubre la condición?
   🟡
10. ¿Qué diferencia hay entre `Index Scan` e `Index Only Scan`, y qué línea del plan dice si el
    segundo está funcionando de verdad? 🟡
11. ¿La palabra `EXPLAIN` y los nombres de los nodos los fija el estándar SQL o cada motor? Di qué
    imprime cada uno de los tres. 🟡
12. Explica por qué `BUFFERS` mide mejor el trabajo de una consulta que los milisegundos, con los
    números de §5. 🟠
13. ¿Cuándo prefiere el motor un `Bitmap Heap Scan` a un `Index Scan` sobre el mismo índice, y qué
    problema evita al hacerlo? 🟠
14. `Sort Method: external merge Disk: 9648kB`. ¿Qué te dice esa línea, y qué dos cosas puedes hacer
    al verla? 🟠
15. En un plan paralelo, `Parallel Seq Scan … rows=100000 loops=3`. ¿Por qué `loops=3` no significa
    lo mismo que en el `Nested Loop` de §3? 🟠
16. Este corpus corre con `max_parallel_workers_per_gather=0`. Justifica la decisión y di qué hay
    que hacer para enseñar un `Gather` sin romperla. 🟠
17. Alguien te dice que un `Seq Scan` en el plan siempre es un error. Dale la refutación con
    números. 🟠
18. ¿`EXPLAIN ANALYZE` sobre un `UPDATE` escribe en la tabla? Responde por separado para PostgreSQL
    18.6 y para MySQL 9.7.2, y di si alguna de las dos respuestas la impone el estándar. 🟠
19. Reconstruye la consulta que produjo este plan y di qué tabla tiene índice útil y cuál no:
    `Aggregate` → `Hash Join (Hash Cond: p.cliente_id = c.id)` → `Seq Scan on pedidos p` y `→ Hash →
    Index Scan using clientes_codigo_key on clientes c (Index Cond: codigo = …)`. 🔴
20. Un `Seq Scan` estima `rows=20500` y devuelve `actual rows=1366667`. Da **tres hipótesis en orden
    de probabilidad** y, para cada una, la consulta o el comando con el que la confirmarías. 🔴
21. Te pasan un plan de 40 líneas de una consulta que tarda ocho segundos. Escribe la secuencia de
    diagnóstico —qué miras, en qué orden y qué decides en cada paso— en cinco pasos como máximo. 🔴
22. Escribe la sesión completa, comando a comando, para medir el efecto de un índice nuevo sobre
    `pedidos(estado, creado_en)` **sin dejar nada detrás**, y di qué comparas antes y después. 🔴

---

**Anterior:** [`04`](04-estadisticas-y-el-planificador.md) — de dónde salen los `rows=` que aquí se
leen · **Siguiente:** [`06`](06-cuando-el-indice-no-se-usa.md) — las seis razones por las que un
índice no se usa · **Relacionado:** [`02/03`](../02-sql/03-joins.md) — los joins y sus planes.
