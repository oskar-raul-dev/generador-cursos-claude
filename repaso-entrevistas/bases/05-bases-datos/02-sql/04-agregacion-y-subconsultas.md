# 04 — Agregación y subconsultas

> Cómo colapsa filas `GROUP BY`, por qué `HAVING` no es "el `WHERE` de los grupos", y de dónde sale
> el error de la columna no agrupada, que no significa lo mismo en cada motor. Después las
> subconsultas: correlacionadas y no, y la decisión que más se pregunta en entrevista —`EXISTS`
> frente a `IN` frente a `JOIN`—, medida con sus tres planes. **Asume leído:** [`03`](03-joins.md) —
> de ahí vienen el join interno, el externo y el anti-join. **Vigencia:** 27 de septiembre de 2026.

---

## Salto rápido

- [1. El problema](#1--el-problema)
- [2. `GROUP BY`: qué colapsa y qué sobrevive](#2--group-by-qué-colapsa-y-qué-sobrevive)
- [3. `WHERE` contra `HAVING`](#3-️-where-contra-having)
- [4. Los tres `COUNT`, y contar con condición](#4--los-tres-count-y-contar-con-condición)
- [5. Correlacionada contra no correlacionada](#5-️-correlacionada-contra-no-correlacionada)
- [6. `EXISTS` frente a `IN` frente a `JOIN`](#6-️-exists-frente-a-in-frente-a-join)
- [7. Estándar, motor y convención](#7--estándar-motor-y-convención)
- [Errores frecuentes](#️-errores-frecuentes)
- [Para profundizar](#-para-profundizar)
- [Preguntas](#-preguntas)

---

## 1. 🎯 El problema

Contabilidad pide una cifra de una línea: *"cuánto facturamos en pedidos `PAGADO`"*. Como hay que
mirar las líneas para descartar los pedidos vacíos, se escribe el `JOIN` obvio y se suma el total.

```text
tienda=# SELECT count(*) AS filas, round(sum(p.total),2) AS suma
tienda-#   FROM pedidos p JOIN pedido_lineas l ON l.pedido_id = p.id
tienda-#  WHERE p.estado = 'PAGADO';
 filas  |     suma      
--------+---------------
 874913 | 5356879029.63
(1 fila)

Duración: 520,031 ms
```

Hay 250 000 pedidos `PAGADO`, no 874 913. El `JOIN` trajo **una fila por línea de pedido** y
`sum(p.total)` sumó el total del pedido tantas veces como líneas tuviera. La cifra buena es 1 292
915 896,63: el informe infla la facturación un **314 %** y no da ningún error.

De eso va el capítulo: no de qué hace `GROUP BY`, que se recita, sino de **qué filas llegan al
agregado y por qué tres formas de escribir lo mismo dejan de significarlo en cuanto aparece un nulo
o una cardinalidad que nadie declaró**.

> **📝 Contexto.** Las sesiones se corren con `\timing on`, puesto al abrir `psql`, y por eso cada
> salida acaba en `Duración:`. Se volvieron a correr el 27 de septiembre de 2026 con `psql` en
> español; los tiempos citados en la prosa que salen de un bloque pegado son los de esa corrida.

---

## 2. 🧱 `GROUP BY`: qué colapsa y qué sobrevive

`GROUP BY` parte las filas en grupos y **deja una de salida por grupo**. Lo que aparezca en la lista
de selección tiene que ser, por tanto, columna de agrupación o agregado: otra cosa no tiene
respuesta única, y el motor no elige por ti. Lo interesante empieza cuando **sí la tiene**: si la
columna está **funcionalmente determinada** por la de agrupación —conocido el grupo, su valor es
uno— la consulta tiene sentido y el motor podría deducirlo. `pedidos.codigo` es `NOT NULL UNIQUE`, o
sea clave candidata, así que agrupando por él `p.id` vale uno solo.

```text
tienda=# SELECT p.estado, p.codigo, count(*) FROM pedidos p GROUP BY p.estado;
ERROR:  column "p.codigo" must appear in the GROUP BY clause or be used in an aggregate function
LÍNEA 1: SELECT p.estado, p.codigo, count(*) FROM pedidos p GROUP BY ...
                          ^
Duración: 0,538 ms
tienda=# SELECT p.codigo, p.id, count(*) FROM pedidos p WHERE p.codigo='PED-00042' GROUP BY p.codigo;
ERROR:  column "p.id" must appear in the GROUP BY clause or be used in an aggregate function
LÍNEA 1: SELECT p.codigo, p.id, count(*) FROM pedidos p WHERE p.codig...
                          ^
Duración: 0,475 ms

mysql> SELECT p.codigo, p.id, count(*) FROM pedidos p WHERE p.codigo='PED-00042' GROUP BY p.codigo;
+-----------+----+----------+
| codigo    | id | count(*) |
+-----------+----+----------+
| PED-00042 | 42 |        1 |
+-----------+----+----------+
1 row in set (0.001 sec)
```

- El primer error es el de manual: el grupo `PAGADO` tiene 250 000 códigos distintos. **Cuánto
  cuesta:** nada, es análisis; la consulta no llega a ejecutarse.
- El segundo es el que descoloca. **La diferencia no es que MySQL 9.7.2 sea laxo: es que analiza
  más.** PostgreSQL 18.6 deduce la dependencia funcional **solo desde la clave primaria** —agrupar
  por `p.id` sí deja sacar `p.codigo`—; MySQL la deduce desde **cualquier candidata `NOT NULL
  UNIQUE`**, y aquí el `ONLY_FULL_GROUP_BY` de su `sql_mode` por defecto está activo.
- Que MySQL rechaza lo que no puede deducir se ve con la primera: `GROUP BY p.estado` con `p.codigo`
  suelto responde `ERROR 1055 (42000) … which is not functionally dependent on columns in GROUP BY
  clause; this is incompatible with sql_mode=only_full_group_by`.
- **MariaDB 12.3.3 no trae `ONLY_FULL_GROUP_BY` por defecto** y SQLite 3.53.4 no analiza nada: los
  dos devuelven un código arbitrario por grupo —`PED-00024`, `PED-00001`…— sin avisar. Es el fallo
  de §1, pero mudo.

Y **`GROUP BY` junta todos los nulos en un mismo grupo**, al revés de lo que hace una comparación:
agrupando el `LEFT JOIN` de pedidos con pagos por `g.metodo` salen cuatro grupos, y el que no tiene
nombre trae **180 000 filas**, los pedidos `PENDIENTE` y `ANULADO` sin pago. La sesión y el porqué
están en [`01/06`](../01-fundamentos-y-modelo-relacional/06-nulos-y-logica-de-tres-valores.md), que
es su dueño.

> **Veredicto:** en la lista de selección de un `GROUP BY` solo caben columnas de agrupación y
> agregados. Que tu motor te deje colar una tercera no dice que la consulta esté bien: dice hasta
> dónde llega su análisis de dependencia funcional, y no llegan todos igual de lejos.

---

## 3. ⚖️ `WHERE` contra `HAVING`

*"`HAVING` es el `WHERE` de los grupos"* es cierto y esconde lo importante: **`WHERE` decide qué
filas entran al agregado y `HAVING` qué grupos salen de él**. Mover la condición no cambia el plan;
cambia el número.

```text
tienda=# SELECT metodo, round(avg(importe),2) AS media, count(*) AS pagos
tienda-#   FROM pagos WHERE importe > 5000 GROUP BY metodo ORDER BY metodo;
    metodo     |  media  | pagos  
---------------+---------+--------
 EFECTIVO      | 7726.29 | 131426
 TARJETA       | 7734.48 | 131668
 TRANSFERENCIA | 7733.31 | 131940
(3 filas)

Duración: 86,366 ms
tienda=# SELECT metodo, round(avg(importe),2) AS media, count(*) AS pagos
tienda-#   FROM pagos GROUP BY metodo HAVING avg(importe) > 5000 ORDER BY metodo;
    metodo     |  media  | pagos  
---------------+---------+--------
 EFECTIVO      | 5171.35 | 273126
 TARJETA       | 5178.11 | 273245
 TRANSFERENCIA | 5182.74 | 273629
(3 filas)

Duración: 120,602 ms
```

- Los mismos tres grupos y medias que no se parecen: 7726,29 contra 5171,35. La primera promedia
  **solo los pagos de más de 5000**; la segunda promedia **todos** y luego comprueba si la media del
  grupo pasa de 5000. Dos preguntas distintas escritas casi igual.
- **Cuánto cuesta:** aquí poco, 86 contra 121 ms: sin índice en `importe` las dos leen las 820 000
  filas, y la de `WHERE` solo agrupa las 395 034 que pasan el filtro. Con un índice utilizable, la
  de `WHERE` descarta antes de agrupar y la de `HAVING` no puede: lo que cabía en `WHERE` y se
  filtró en `HAVING` se paga entero.
- `HAVING` sin `GROUP BY` trata la tabla como un grupo único y devuelve una fila o ninguna: `… FROM
  pagos HAVING count(*) > 900000` da `(0 rows)` en 57,925 ms y con `> 100000` da `820000`.

> **💡 Truco.** El orden lógico —`FROM`, `WHERE`, `GROUP BY`, `HAVING`, `SELECT`, `ORDER BY`— explica
> de paso una diferencia de dialecto: `HAVING` se evalúa **antes** que `SELECT`, así que el alias
> todavía no existe. `HAVING media > 5000` responde `ERROR: column "media" does not exist` en
> PostgreSQL 18.6 y funciona en MySQL 9.7.2, MariaDB 12.3.3 y SQLite 3.53.4.

**Veredicto:** `HAVING` solo para condiciones sobre agregados. Sobre una columna de agrupación el
resultado es idéntico y el coste no.

---

## 4. 🧱 Los tres `COUNT`, y contar con condición

`count(*)` cuenta **filas**; `count(columna)`, **valores no nulos**; `count(DISTINCT columna)`,
**valores no nulos distintos**. Sobre `pagos`, con sus 273 126 referencias nulas:

```text
tienda=# SELECT count(*) AS filas, count(referencia) AS valores,
tienda-#        count(DISTINCT referencia) AS distintos FROM pagos;
 filas  | valores | distintos 
--------+---------+-----------
 820000 |  546874 |    546874
(1 fila)

Duración: 110,627 ms
```

- Que `valores` y `distintos` coincidan no es casualidad: `referencia` es `UNIQUE`, así que ningún
  valor se repite. Si `count(DISTINCT …)` diera menos, la restricción estaría suelta.
- **El `+1` que descoloca:** `SELECT DISTINCT referencia FROM pagos` devuelve **546 875**, una fila
  más, en unos 125 ms. `SELECT DISTINCT` deduplica **filas** y el nulo es una fila —el grupo único
  de §2—, mientras que `count(DISTINCT …)` es un agregado de columna, y los agregados de columna
  **ignoran el nulo**. Dos reglas sobre el mismo valor, y por eso el `+1`.

Para contar con condición hay dos escrituras: `FILTER (WHERE …)`, la del estándar y la legible, y
`SUM(CASE WHEN … THEN 1 ELSE 0 END)`, la portable.

```text
tienda=# SELECT metodo, count(*) FILTER (WHERE importe > 500) AS caros_filter,
tienda-#        sum(CASE WHEN importe > 500 THEN 1 ELSE 0 END) AS caros_case
tienda-#   FROM pagos GROUP BY metodo ORDER BY metodo;
    metodo     | caros_filter | caros_case 
---------------+--------------+------------
 EFECTIVO      |       264876 |     264876
 TARJETA       |       264836 |     264836
 TRANSFERENCIA |       265195 |     265195
(3 filas)

Duración: 114,487 ms
```

Comprobado en los cuatro motores: PostgreSQL 18.6 y SQLite 3.53.4 admiten `FILTER`; **MySQL 9.7.2 y
MariaDB 12.3.3 responden `ERROR 1064 (42000)`**, ni lo reconocen, y solo les queda el `CASE`, que en
MySQL da los mismos 264 876 / 264 836 / 265 195. La ventaja del `FILTER` no es el tiempo sino que
**cada agregado lleva su condición al lado** en vez de esconderla en un `CASE`.

> **⚠️ Advertencia.** En SQLite esos agregados dan 123 274 / 123 380 / 123 620. No falla el
> `FILTER`: en `tienda.db` la columna `importe` es `TEXT` —SQLite no tiene decimal— y `importe >
> 500` compara cadenas, así que `'6949.33' > '500'` es cierto y `'123.45' > '500'` es falso. El
> agregado está bien; el tipo no, y eso es de [`01`](01-familias-del-lenguaje-y-tipos.md).

**Veredicto:** los tres `COUNT` responden tres preguntas; elige por la pregunta, no por el tiempo. Y
para contar con condición, `FILTER` donde exista y `CASE` donde haga falta portar.

---

## 5. ⚖️ Correlacionada contra no correlacionada

Una subconsulta **no correlacionada** no menciona nada de fuera: se evalúa una vez y se reutiliza.
Una **correlacionada** sí, y por definición se evalúa **una vez por cada fila externa**. El plan lo
dice con todas las letras, en `loops`:

```text
tienda=# EXPLAIN (ANALYZE, COSTS OFF, BUFFERS OFF)
tienda-# SELECT p.codigo, (SELECT max(g.pagado_en) FROM pagos g WHERE g.pedido_id = p.id) AS ultimo
tienda-#   FROM pedidos p WHERE p.codigo BETWEEN 'PED-00040' AND 'PED-00059';
                                            QUERY PLAN                                             
---------------------------------------------------------------------------------------------------
 Index Scan using pedidos_codigo_key on pedidos p (actual time=28.602..605.481 rows=20.00 loops=1)
   Index Cond: ((codigo >= 'PED-00040'::text) AND (codigo <= 'PED-00059'::text))
   Index Searches: 1
   SubPlan 1
     ->  Aggregate (actual time=30.262..30.262 rows=1.00 loops=20)
           ->  Seq Scan on pagos g (actual time=4.408..30.251 rows=0.85 loops=20)
                 Filter: (pedido_id = p.id)
                 Rows Removed by Filter: 819999
 Planning Time: 0.222 ms
 Execution Time: 605.536 ms
(10 filas)

Duración: 607,440 ms
```

- `loops=20`: veinte recorridos secuenciales enteros de `pagos`, uno por pedido, tirando 819 999
  filas cada vez. **Cuánto cuesta:** 605,536 ms para veinte filas de salida; con los mil pedidos de
  un informe real, cincuenta veces eso.
- La misma respuesta como `LEFT JOIN` más `GROUP BY p.codigo` sale en **114,327 ms** sobre un `Hash
  Right Join` alimentado por el mismo `Index Scan`: lee `pagos` una vez. Ocho veces más rápido, sin
  índice nuevo.

De ahí no se sigue que "correlacionada" signifique "lenta". **Cuando la correlación está en `WHERE`,
el planificador la aplana y las dos escrituras acaban en el mismo nodo.** Los pedidos con pago, una
vez correlacionada y otra no:

```text
tienda=# EXPLAIN (ANALYZE, COSTS OFF, BUFFERS OFF)
tienda-# SELECT count(*) FROM pedidos p WHERE EXISTS (SELECT 1 FROM pagos g WHERE g.pedido_id=p.id);
                                        QUERY PLAN                                        
------------------------------------------------------------------------------------------
 Aggregate (actual time=503.770..503.774 rows=1.00 loops=1)
   ->  Hash Semi Join (actual time=136.118..475.394 rows=820000.00 loops=1)
         Hash Cond: (p.id = g.pedido_id)
         ->  Seq Scan on pedidos p (actual time=0.006..56.979 rows=1000000.00 loops=1)
         ->  Hash (actual time=135.904..135.905 rows=820000.00 loops=1)
               Buckets: 524288  Batches: 4  Memory Usage: 12115kB
               ->  Seq Scan on pagos g (actual time=0.003..48.036 rows=820000.00 loops=1)
 Planning Time: 0.117 ms
 Execution Time: 503.821 ms
(9 filas)

Duración: 504,747 ms
tienda=# EXPLAIN (ANALYZE, COSTS OFF, BUFFERS OFF)
tienda-# SELECT count(*) FROM pedidos p WHERE p.id IN (SELECT g.pedido_id FROM pagos g);
                                        QUERY PLAN                                        
------------------------------------------------------------------------------------------
 Aggregate (actual time=572.772..572.776 rows=1.00 loops=1)
   ->  Hash Semi Join (actual time=141.164..546.387 rows=820000.00 loops=1)
         Hash Cond: (p.id = g.pedido_id)
         ->  Seq Scan on pedidos p (actual time=0.008..60.118 rows=1000000.00 loops=1)
         ->  Hash (actual time=140.991..140.992 rows=820000.00 loops=1)
               Buckets: 524288  Batches: 4  Memory Usage: 12115kB
               ->  Seq Scan on pagos g (actual time=0.004..48.156 rows=820000.00 loops=1)
 Planning Time: 0.131 ms
 Execution Time: 572.838 ms
(9 filas)

Duración: 573,797 ms
```

Árbol idéntico, `Hash Semi Join` las dos, y 69 ms de diferencia que es ruido entre corridas: el
árbol es el mismo. **En el plan no hay ninguna "consulta correlacionada": hay un semi-join.** La
correlación es una forma de escribir, no una forma de ejecutar.

> **🩺 Diagnóstico.** Antes de reescribir nada, busca un `loops` mayor que 1 bajo un `SubPlan`. Si
> vale 20, el problema es la correlación; si vale 1, ya se aplanó y el tiempo está en otro sitio.

**Veredicto:** la correlación duele en la lista de selección, donde el motor no tiene a qué
aplanarla, y desaparece casi siempre en `WHERE`.

---

## 6. ⚖️ `EXISTS` frente a `IN` frente a `JOIN`

El caso canónico del dominio: **los 180 000 pedidos sin pago**. Tres escrituras, y aquí sí divergen.

```text
tienda=# EXPLAIN (ANALYZE, COSTS OFF, BUFFERS OFF) SELECT count(*) FROM pedidos p
tienda-#  WHERE NOT EXISTS (SELECT 1 FROM pagos g WHERE g.pedido_id = p.id);
                                        QUERY PLAN                                        
------------------------------------------------------------------------------------------
 Aggregate (actual time=459.736..459.738 rows=1.00 loops=1)
   ->  Hash Anti Join (actual time=148.219..453.984 rows=180000.00 loops=1)
         Hash Cond: (p.id = g.pedido_id)
         ->  Seq Scan on pedidos p (actual time=0.010..58.535 rows=1000000.00 loops=1)
         ->  Hash (actual time=148.059..148.059 rows=820000.00 loops=1)
               Buckets: 524288  Batches: 4  Memory Usage: 12115kB
               ->  Seq Scan on pagos g (actual time=0.004..48.151 rows=820000.00 loops=1)
 Planning Time: 0.128 ms
 Execution Time: 459.781 ms
(9 filas)

Duración: 460,723 ms
tienda=# EXPLAIN (ANALYZE, COSTS OFF, BUFFERS OFF) SELECT count(*)
tienda-#   FROM pedidos p LEFT JOIN pagos g ON g.pedido_id = p.id WHERE g.id IS NULL;
                                         QUERY PLAN                                          
---------------------------------------------------------------------------------------------
 Aggregate (actual time=467.463..467.465 rows=1.00 loops=1)
   ->  Hash Right Join (actual time=333.568..461.831 rows=180000.00 loops=1)
         Hash Cond: (g.pedido_id = p.id)
         Filter: (g.id IS NULL)
         Rows Removed by Filter: 820000
         ->  Seq Scan on pagos g (actual time=0.014..49.635 rows=820000.00 loops=1)
         ->  Hash (actual time=162.633..162.634 rows=1000000.00 loops=1)
               Buckets: 524288  Batches: 4  Memory Usage: 13854kB
               ->  Seq Scan on pedidos p (actual time=0.007..57.714 rows=1000000.00 loops=1)
 Planning Time: 0.131 ms
 Execution Time: 467.534 ms
(11 filas)

Duración: 470,378 ms
tienda=# EXPLAIN SELECT count(*) FROM pedidos p WHERE p.id NOT IN (SELECT g.pedido_id FROM pagos g);
                                     QUERY PLAN                                     
------------------------------------------------------------------------------------
 Aggregate  (cost=12893024520.00..12893024520.01 rows=1 width=8)
   ->  Seq Scan on pedidos p  (cost=0.00..12893023270.00 rows=500000 width=0)
         Filter: (NOT (ANY (id = (SubPlan 1).col1)))
         SubPlan 1
           ->  Materialize  (cost=0.00..23736.00 rows=820000 width=8)
                 ->  Seq Scan on pagos g  (cost=0.00..16432.00 rows=820000 width=8)
(6 filas)

Duración: 0,608 ms
```

- Las dos primeras dan las mismas 180 000 filas en 459,781 y 467,534 ms: **la diferencia está dentro
  del ruido** —en otra corrida salieron 585,310 y 592,975—. El `Hash Anti Join` para al primer
  acierto; el `Hash Right Join` construye las 820 000 coincidencias y luego las tira, `Rows Removed
  by Filter: 820000`. Da igual mientras quepa en memoria, y deja de dar igual con una tabla derecha
  que multiplique.
- La tercera **no termina**. Coste estimado 12 893 024 520: un bucle anidado de un millón de filas
  contra 820 000 materializadas. La cancelé a los 3 min 23 s. La causa es de motor: para resolver
  `NOT IN` con tabla hash, a PostgreSQL le tiene que caber en `work_mem`, que este entorno fija en 8
  MB. Con `SET work_mem = '64MB'` el nodo pasa a `(hashed SubPlan 1)` y devuelve las 180 000 en
  **587,898 ms**. Mismo SQL, mismo dato, cuatro órdenes de magnitud por un parámetro de sesión.
- **MySQL 9.7.2 no cae ahí**: reescribe a `Nested loop antijoin` sobre un `Materialize with
  deduplication` con clave automática y responde 180 000 en 1,686 s de reloj. Cuidado al comparar
  motores: InnoDB creó solo el índice `fk_pagos_pedido` del lado hijo de la foránea, que en
  PostgreSQL no existe.

Lo que de verdad se pregunta es **dónde dejan de ser equivalentes**, y son dos sitios.

**Uno: `IN` con nulos dentro.** Los 273 126 pagos en efectivo no tienen `referencia`.

```text
tienda=# SELECT (SELECT count(*) FROM pagos p
tienda(#          WHERE p.referencia NOT IN (SELECT q.referencia FROM pagos q WHERE q.metodo='EFECTIVO')) AS con_not_in,
tienda-#        (SELECT count(*) FROM pagos p
tienda(#          WHERE NOT EXISTS (SELECT 1 FROM pagos q WHERE q.metodo='EFECTIVO' AND q.referencia=p.referencia)) AS con_not_exists;
 con_not_in | con_not_exists 
------------+----------------
          0 |         820000
(1 fila)

Duración: 242,805 ms
```

Cero contra 820 000, sin error y sin aviso. `NOT IN` es una cadena de `<>` unida por `AND`, y una
sola comparación desconocida impide que dé verdadero nunca; el porqué entero está en
[`01/06`](../01-fundamentos-y-modelo-relacional/06-nulos-y-logica-de-tres-valores.md). La
consecuencia: **`NOT IN` sobre subconsulta solo es seguro si la columna interna es `NOT NULL` y
puedes demostrarlo.** En `IN` afirmativo el nulo no hace daño, porque a `IN` le basta un acierto.

**Dos: el `JOIN` que multiplica**, que es el fallo de §1 y solo le pasa al `JOIN`.

| Escritura | Filas | `sum(p.total)` |
|---|---|---|
| `JOIN pedido_lineas` | 874 913 | 5 356 879 029,63 |
| `WHERE EXISTS (…)` | 250 000 | 1 292 915 896,63 |

`EXISTS` e `IN` son **semi-joins**: devuelven la fila izquierda una vez, haya una coincidencia o
mil; el `JOIN` devuelve el producto. Da igual mientras la derecha sea única por la columna de unión
—hoy ningún pedido tiene dos pagos, comprobado con `GROUP BY pedido_id HAVING count(*) > 1`, que da
`0`— y deja de dar igual el día que alguien registre un pago parcial: **nada en el esquema lo
impide, porque `pagos.pedido_id` no es `UNIQUE`**. Y la corrección no es `DISTINCT`, que arregla el
recuento y deja la suma mal: es agregar la derecha aparte, o pasar a `EXISTS`.

> **Veredicto:** `EXISTS` cuando solo preguntas si existe; `JOIN` cuando necesitas columnas del otro
> lado y sabes que no multiplica; `IN` con listas cortas o columnas `NOT NULL`. En negativo, `NOT
> EXISTS` casi siempre.

---

## 7. 📜 Estándar, motor y convención

> **📜 Estándar o motor.** ISO/IEC 9075 es de pago y **no he verificado ninguna de sus cláusulas**
> para esta tabla. Donde la columna "Estándar" dice *no verificado*, lo afirmado es lo que hacen los
> motores, comprobado en sesión.

| Afirmación | Estándar | PostgreSQL 18.6 | MySQL 9.7.2 | MariaDB 12.3.3 | SQLite 3.53.4 |
|---|---|---|---|---|---|
| Una columna ni agrupada ni agregada es error | No verificado | ✅ siempre | ✅ con `ONLY_FULL_GROUP_BY`, activo por defecto | ❌ no viene activo | ❌ devuelve un valor arbitrario |
| La dependencia funcional exime de agrupar | No verificado | Solo desde la **clave primaria** | Desde **cualquier candidata `NOT NULL UNIQUE`** | — | — |
| `HAVING` acepta el alias de la lista de selección | No verificado; el orden lógico dice que no | ❌ `ERROR: column "media" does not exist` | ✅ | ✅ | ✅ |
| `count(*) FILTER (WHERE …)` | Sí, `<filter clause>` | ✅ | ❌ `ERROR 1064` | ❌ `ERROR 1064` | ✅ |
| `NOT IN` con un nulo dentro no devuelve nada | No verificado; se deriva de `AND` y `<>` | ✅ | ✅ | ✅ | ✅ |
| `NOT IN` se resuelve como anti-join | No lo fija: es del optimizador | ❌ sin `work_mem` suficiente | ✅ `Nested loop antijoin` | — | — |

**Convención — *"`EXISTS` siempre es más rápido que `IN`"*.** Viene de los Oracle y los SQL Server
de hace veinte años, donde `IN` se materializaba y `EXISTS` no, y se sigue recitando. Sobre este
entorno es **falsa en afirmativo y cierta en negativo**, y las dos mitades están medidas arriba:

| Forma | Escritura | Plan | Tiempo |
|---|---|---|---|
| Afirmativa | `EXISTS` | `Hash Semi Join` | 503,821 ms |
| Afirmativa | `IN` | `Hash Semi Join`, idéntico | 572,838 ms |
| Negativa | `NOT EXISTS` | `Hash Anti Join` | 459,781 ms |
| Negativa | `LEFT JOIN … IS NULL` | `Hash Right Join` + `Filter` | 467,534 ms |
| Negativa | `NOT IN` | `Materialize` + bucle anidado | cancelada a 3 min 23 s |

Lo preciso no es "`EXISTS` es más rápido", sino **"`EXISTS` e `IN` afirmativos son el mismo
semi-join y el mismo tiempo; `NOT IN` es otra cosa, por los nulos antes que por el plan"**. Dicho
con estos números, es la respuesta que distingue al que midió del que lo leyó en un blog.

---

## ⚠️ Errores frecuentes

| Se dice | Lo preciso |
|---|---|
| "`HAVING` es el `WHERE` de los grupos" | `WHERE` elige qué filas entran al agregado y `HAVING` qué grupos salen. Movida la condición, la media pasa de 7726,29 a 5171,35 |
| "Si la columna es única, `GROUP BY` debería dejarme sacarla" | Depende del motor: PostgreSQL deduce solo desde la primaria, MySQL desde cualquier candidata `NOT NULL UNIQUE` |
| "`count(DISTINCT col)` y `SELECT DISTINCT col` dan lo mismo" | 546 874 contra 546 875: el agregado ignora el nulo, la deduplicación lo cuenta como una fila |
| "`EXISTS` siempre es más rápido que `IN`" | En afirmativo dan el mismo `Hash Semi Join` y el mismo tiempo. La diferencia real está en `NOT IN`, y es semántica antes que de plan |
| "`IN` y `JOIN` son intercambiables" | Solo si la derecha es única por la columna de unión. Con `pedido_lineas`, el `JOIN` infla la suma un 314 % |
| "Un `JOIN` que multiplica se arregla con `DISTINCT`" | `DISTINCT` arregla el recuento y deja la suma mal. Se agrega la derecha aparte, o se usa `EXISTS` |
| "Una subconsulta correlacionada siempre es lenta" | En `WHERE` el planificador la aplana a un semi-join. Duele en la lista de selección: `loops=20` y 606 ms para veinte filas |

---

## 📚 Para profundizar

- **Doc** — PostgreSQL 18, «SELECT», cláusulas `GROUP BY` y `HAVING`:
  <https://www.postgresql.org/docs/18/sql-select.html>
- **Doc** — PostgreSQL 18, «Aggregate Functions», `FILTER` y `count(DISTINCT …)`:
  <https://www.postgresql.org/docs/18/functions-aggregate.html>
- **Doc** — PostgreSQL 18, «Subquery Expressions», `EXISTS`, `IN` y `NOT IN`:
  <https://www.postgresql.org/docs/18/functions-subquery.html>
- **Doc** — MySQL 9.7, «MySQL Handling of GROUP BY»: la dependencia funcional desde cualquier clave
  candidata. <https://dev.mysql.com/doc/refman/9.7/en/group-by-handling.html>
- **Doc** — MySQL 9.7, «Optimizing Subqueries, Derived Tables, and View References»: semi-joins y
  materialización. <https://dev.mysql.com/doc/refman/9.7/en/optimizing-subqueries.html>
- **Doc** — MariaDB Server, «Subquery Optimizations»:
  <https://mariadb.com/docs/server/ha-and-performance/optimization-and-tuning/query-optimizations/subquery-optimizations>
- **Doc** — SQLite, «SELECT», *Bare columns in an aggregate query*:
  <https://www.sqlite.org/lang_select.html#bareagg>
- **Estándar** — ISO/IEC 9075-2 (*Foundation*), `<group by clause>`, `<having clause>` y `<filter
  clause>`. De pago, sin URL pública y **no verificadas en esta edición**.

---

## 🧠 Preguntas

1. ¿Cuántas filas de salida produce un `GROUP BY`, y qué puede aparecer en la lista de selección? 🟢
2. Da los tres números de `count(*)`, `count(referencia)` y `count(DISTINCT referencia)` sobre
   `pagos`, y di qué cuenta cada uno. 🟢
3. ¿Qué es una subconsulta correlacionada, y en qué parte del plan se nota? 🟢
4. ¿Cuántos pedidos sin pago hay, y en qué grupo aparecen al agrupar por `pagos.metodo`? 🟢
5. Escribe las dos formas de contar con condición dentro de un `GROUP BY` y di cuál es portable. 🟡
6. Diferencia `WHERE` de `HAVING` diciendo sobre qué actúa cada uno. 🟡
7. ¿Por qué `count(DISTINCT referencia)` da 546 874 y `SELECT DISTINCT referencia` da 546 875? 🟡
8. `EXISTS` e `IN` afirmativos, ¿dan el mismo plan en PostgreSQL 18.6? Di el nodo y los tiempos. 🟡
9. ¿Qué significa que `EXISTS` sea un semi-join, y en qué se distingue de un `JOIN`? 🟡
10. `count(*) FILTER (WHERE …)`: ¿lo fija el estándar, y qué motores del corpus lo admiten? 🟡
11. `HAVING media > 5000` funciona en MySQL y falla en PostgreSQL. ¿Estándar o motor, y por qué? 🟠
12. El informe de §1 da 874 913 filas y una suma inflada un 314 %. Explica el mecanismo y da dos
    correcciones distintas. 🟠
13. Agrupando por `pedidos.codigo`, PostgreSQL rechaza `p.id` y MySQL lo devuelve. Explica de dónde
    sale la diferencia y si alguno de los dos incumple algo. 🟠
14. `NOT IN` sobre `pagos.referencia` da 0 y `NOT EXISTS` da 820 000. ¿Cuál responde a la pregunta,
    y por qué el otro no da ningún error? 🟠
15. ¿Por qué el mismo `NOT IN` no termina con `work_mem` de 8 MB y tarda 587 ms con 64 MB? Nombra el
    nodo que cambia. 🟠
16. La media por método sale 7726,29 con `WHERE` y 5171,35 con `HAVING`. Di cuál responde a *"media
    de los pagos grandes"* y cuál a *"métodos cuya media es grande"*. 🟠
17. Escribe la consulta que dé, por estado de pedido, el número de pedidos y el importe total
    cobrado, sin que desaparezca ningún pedido sin pago y sin inflar ninguna suma. 🔴
18. Un informe une `pedidos` con `pedido_lineas` y con `pagos` a la vez y suma `p.total`. Da tres
    hipótesis del número inflado en orden de probabilidad, y la consulta que confirma cada una. 🔴
19. Escribe la comprobación previa a un despliegue que detecte los `NOT IN` peligrosos de un
    repositorio: qué buscas, qué descartas, y qué consulta del catálogo decide si la columna interna
    es anulable. 🔴
20. El último pago de cada uno de los 1000 pedidos de un informe tarda minutos con subconsulta
    correlacionada. Escribe la reescritura con agregación, di qué gana, y nombra la familia de
    funciones que resolvería *"y además el importe de ese pago"*, que `GROUP BY` no resuelve. 🔴

---

**Anterior:** [`03`](03-joins.md) · **Siguiente:** [`05`](05-cte-y-recursion.md) · **Relacionado:**
[`01/06`](../01-fundamentos-y-modelo-relacional/06-nulos-y-logica-de-tres-valores.md), de donde
salen la aniquilación de `NOT IN` y el grupo de los nulos; las funciones de ventana, que resuelven
lo que `GROUP BY` no puede, son [`06`](06-funciones-de-ventana.md).
