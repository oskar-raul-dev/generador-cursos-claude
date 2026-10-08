# 03 — Joins

> Qué hace cada clase de join —interno, externo, cruzado y reflexivo—, los dos que no tienen palabra
> clave —semi-join y anti-join—, y **qué le pasa a un nulo dentro de un join**: el que llega en la
> columna de unión y el que fabrica el propio join. Cierra con la trampa que más informes rompe en
> silencio: un predicado en el `WHERE` en lugar de en el `ON`. **Asume leído:**
> [`02`](02-select-y-el-orden-logico.md) — de ahí viene el orden lógico de evaluación, que es lo que
> explica esa trampa. **Vigencia:** 27 de septiembre de 2026.

---

## Salto rápido

- [1. El problema](#1--el-problema)
- [2. El interno, y la multiplicación de filas](#2--el-interno-y-la-multiplicación-de-filas)
- [3. Los externos: izquierdo, derecho y completo](#3-️-los-externos-izquierdo-derecho-y-completo)
- [4. El `ON` contra el `WHERE`](#4--el-on-contra-el-where)
- [5. Unir por una columna con nulos](#5--unir-por-una-columna-con-nulos-no-empareja-nada)
- [6. El cruzado y el reflexivo](#6-️-el-cruzado-y-el-reflexivo)
- [7. Semi-join y anti-join](#7--semi-join-y-anti-join-los-que-no-se-escriben)
- [8. Estándar, motor y convención](#8--estándar-motor-y-convención)
- [Errores frecuentes](#️-errores-frecuentes)
- [Para profundizar](#-para-profundizar)
- [Preguntas](#-preguntas)

---

## 1. 🎯 El problema

Contabilidad pide lo que gastó `CLI-00311`, que tiene 52 pedidos. Sumas sus líneas y el número
cuadra con el `total` desnormalizado de `pedidos`. Al día siguiente te piden lo mismo con el rastro
de eventos de cada pedido: añades un `JOIN`, no tocas el `sum`, y el importe se multiplica por
cuatro.

```text
tienda=# SELECT (SELECT sum(pl.cantidad * pl.precio_unit) FROM pedidos p
tienda(#           JOIN pedido_lineas pl ON pl.pedido_id = p.id
tienda(#          WHERE p.cliente_id = 311)                        AS con_una_hija,
tienda-#        (SELECT sum(pl.cantidad * pl.precio_unit) FROM pedidos p
tienda(#           JOIN pedido_lineas pl ON pl.pedido_id = p.id
tienda(#           JOIN eventos_pedido e ON e.pedido_id = p.id
tienda(#          WHERE p.cliente_id = 311)                        AS con_dos_hijas;
 con_una_hija | con_dos_hijas 
--------------+---------------
    272035.61 |    1101161.99
(1 fila)

Duración: 369,726 ms
```

Ni error ni aviso: el informe sale firmado. Este capítulo es el inventario de lo que un join hace de
verdad con tus filas: **cuántas devuelve, cuáles conserva cuando no hay pareja, y qué pasa cuando la
columna por la que unes vale `NULL`**. El álgebra que hay debajo está en
[`01/03`](../01-fundamentos-y-modelo-relacional/03-algebra-relacional.md); aquí los joins son
herramienta.

> **📝 Contexto.** Las sesiones se corren con `\timing on`, puesto al abrir `psql`, y por eso cada
> salida acaba en `Duración:`. Se volvieron a correr el 27 de septiembre de 2026 con `psql` en
> español; los tiempos citados en la prosa que salen de un bloque pegado son los de esa corrida, y
> las estimaciones de filas de los planes cambian con cada muestra de `ANALYZE`.

---

## 2. 🧱 El interno, y la multiplicación de filas

**Qué es.** El `INNER JOIN` —`JOIN` a secas— devuelve **una fila por cada pareja** que cumple el
`ON`. Ninguna fila sin pareja sobrevive, de ninguno de los dos lados.

```text
tienda=# SELECT p.codigo AS pedido, pl.linea, pr.codigo AS producto, pl.cantidad, pl.precio_unit
tienda-#   FROM pedidos p
tienda-#   JOIN pedido_lineas pl ON pl.pedido_id = p.id
tienda-#   JOIN productos pr     ON pr.id = pl.producto_id
tienda-#  WHERE p.codigo = 'PED-00042'
tienda-#  ORDER BY pl.linea;
  pedido   | linea | producto  | cantidad | precio_unit 
-----------+-------+-----------+----------+-------------
 PED-00042 |     1 | PRD-01395 |        1 |      102.83
 PED-00042 |     2 | PRD-00872 |        5 |       27.03
 PED-00042 |     3 | PRD-03623 |        3 |      982.75
(3 filas)

Duración: 1,064 ms
```

- **Un pedido entró y salieron tres filas.** Sobre las tablas enteras, `pedidos JOIN pedido_lineas`
  no da 1 000 000 de filas sino **3 500 000, en 874 ms**: 3,5 líneas por pedido.
- **Cuánto cuesta:** el resultado crece con el producto de cardinalidades, y lo paga todo lo que
  venga encima. Un `sum` sobre 3 500 000 filas es 3,5 veces el de un millón, más la memoria del
  intermedio.

De ahí sale §1: `pedido_lineas` y `eventos_pedido` son **dos hijas del mismo padre sin relación
entre sí**, y unirlas a la vez empareja cada línea con cada evento del pedido —175 líneas por unos 4
eventos, 706 filas—, así que cada importe se cuenta cuatro veces. Es la *fan trap* (trampa del
abanico), y la corrección no es tocar el `sum`: es agregar cada hija por separado y combinar después
resultados ya reducidos a una fila por pedido, con las subconsultas de
[`04`](04-agregacion-y-subconsultas.md). **Cuándo sí** el interno: quieres columnas de los dos lados
y las filas sin pareja no te interesan. **Cuándo no:** cuando la pregunta es "¿existe?" —eso es
semi-join, §7— o cuando la ausencia es el dato.

> **⚠️ Advertencia.** `DISTINCT` delante no arregla esto: quita filas idénticas, y las 706 de §1
> difieren en el evento. El total sigue inflado, y ahora además ordenando.

> **Veredicto:** un join no filtra filas, produce parejas. Antes de sumar nada después de un join,
> pregúntate cuántas filas del resultado le tocan a una sola fila del padre.

---

## 3. ⚖️ Los externos: izquierdo, derecho y completo

**Qué son.** Un join **externo** conserva las filas sin pareja de un lado y rellena con `NULL` las
columnas del otro: `LEFT` las de la izquierda, `RIGHT` las de la derecha, `FULL` las de los dos. La
palabra `OUTER` es opcional y no cambia nada.

```text
tienda=# SELECT c.codigo AS cliente, p.codigo AS pedido, p.estado
tienda-#   FROM clientes c LEFT JOIN pedidos p ON p.cliente_id = c.id
tienda-#  WHERE c.codigo = 'CLI-00007';
  cliente  | pedido | estado 
-----------+--------+--------
 CLI-00007 |        | 
(1 fila)

Duración: 43,438 ms
```

- `CLI-00007` es **el único de los 50 000 clientes sin pedidos**, y esas dos celdas vacías son
  `NULL` fabricados por el join: en `pedidos` no hay una fila con nulos, hay **ausencia de fila**.
  El nulo lo inventa la operación, y luego se comporta como cualquier otro
  ([`01/06`](../01-fundamentos-y-modelo-relacional/06-nulos-y-logica-de-tres-valores.md)).
- El recuento lo confirma: `pedidos LEFT JOIN pagos` da **1 000 000 de filas** frente a 820 000 del
  interno. Las 180 000 de diferencia son los `PENDIENTE` y `ANULADO` sin pago, `PED-99999` entre
  ellos.

`RIGHT` es `LEFT` con los operandos al revés. El que aporta algo que no se escribe de otra forma en
una pasada es **`FULL OUTER JOIN`**: conciliar dos conjuntos viendo a la vez qué sobra en cada lado.

```text
tienda=# SELECT count(*) AS filas,
tienda-#        count(*) FILTER (WHERE pg.id IS NULL) AS solo_pedido,
tienda-#        count(*) FILTER (WHERE p.id IS NULL)  AS solo_pago,
tienda-#        count(*) FILTER (WHERE p.id IS NOT NULL AND pg.id IS NOT NULL) AS en_ambos
tienda-#   FROM (SELECT id FROM pedidos WHERE estado = 'ANULADO') p
tienda-#   FULL OUTER JOIN pagos pg ON pg.pedido_id = p.id;
 filas  | solo_pedido | solo_pago | en_ambos 
--------+-------------+-----------+----------
 880000 |       60000 |    820000 |        0
(1 fila)

Duración: 169,235 ms
```

- 60 000 pedidos anulados sin pago, 820 000 pagos que no son de un pedido anulado, y **cero en ambos
  lados**: ningún anulado se cobró. Ese `en_ambos = 0` es el informe, y solo el `FULL` lo da junto
  con los dos descartes. **Cuánto cuesta:** un externo lee entero el lado que conserva; el `FULL`,
  los dos.

**MySQL 9.7.2 no tiene `FULL OUTER JOIN`**, y no lo tiene de la forma más ruidosa posible:

```text
mysql> SELECT c.codigo, p.codigo FROM clientes c
    -> FULL OUTER JOIN pedidos p ON p.cliente_id = c.id LIMIT 1;
ERROR 1064 (42000) at line 1: You have an error in your SQL syntax; check the manual that corresponds to your MySQL server version for the right syntax to use near 'FULL OUTER JOIN pedidos p ON p.cliente_id = c.id LIMIT 1' at line 2
```

Sin `OUTER` da el mismo 1064, y MariaDB 12.3.3 responde igual. El apaño portable es **un externo
unido al anti-join del otro lado**, y da las mismas 880 000 filas:

```text
mysql> SELECT count(*) AS filas FROM (
    ->   SELECT p.id AS pedido_id, pg.id AS pago_id
    ->     FROM (SELECT id FROM pedidos WHERE estado='ANULADO') p
    ->     LEFT JOIN pagos pg ON pg.pedido_id = p.id
    ->   UNION ALL
    ->   SELECT p.id, pg.id FROM pagos pg
    ->     LEFT JOIN (SELECT id FROM pedidos WHERE estado='ANULADO') p ON pg.pedido_id = p.id
    ->    WHERE p.id IS NULL) t;
+--------+
| filas  |
+--------+
| 880000 |
+--------+
```

- **`UNION ALL` y no `UNION`**: el segundo brazo solo trae lo que el primero no pudo, así que no hay
  duplicados y deduplicar costaría ordenar 880 000 filas para nada. Y el `WHERE p.id IS NULL` de ese
  brazo no es decorativo: sin él, las parejas ya emparejadas saldrían dos veces.

SQLite tiene `RIGHT` y `FULL OUTER JOIN` **desde la 3.39.0** y funciona en la 3.53.4 del corpus, con
una salvedad medida: sin más índices que los de las claves, el `FULL` entre `clientes` y `pedidos`
completo **no terminó y lo corté a los seis minutos**; acotado a los primeros 20 000 pedidos
responde en 0,748 s y da 17 542 filas. Qué es portable entre los cuatro motores y qué no tiene su
propio capítulo al final de este bloque, [`08`](08-dialectos.md).

> **Veredicto:** el externo se usa cuando **la ausencia es el dato**. Si toda fila va a tener
> pareja, un `LEFT JOIN` solo le quita opciones al planificador.

---

## 4. 🩺 El `ON` contra el `WHERE`

El encargo es *"un renglón por cliente, con sus pedidos anulados si los tiene"*. Dos escrituras que
parecen la misma: el predicado sobre `estado` en el `ON`, o en el `WHERE`.

```text
tienda=# SELECT count(*) AS filas, count(p.id) AS con_pedido, count(DISTINCT c.id) AS clientes
tienda-#   FROM clientes c LEFT JOIN pedidos p
tienda-#     ON p.cliente_id = c.id AND p.estado = 'ANULADO';
 filas | con_pedido | clientes 
-------+------------+----------
 75124 |      60000 |    50000
(1 fila)

Duración: 84,499 ms
tienda=# SELECT count(*) AS filas, count(p.id) AS con_pedido, count(DISTINCT c.id) AS clientes
tienda-#   FROM clientes c LEFT JOIN pedidos p ON p.cliente_id = c.id
tienda-#  WHERE p.estado = 'ANULADO';
 filas | con_pedido | clientes 
-------+------------+----------
 60000 |      60000 |    34876
(1 fila)

Duración: 78,858 ms
```

- **En el `ON`** aparecen los **50 000 clientes**: 60 000 filas emparejadas más 15 124 clientes sin
  ningún pedido anulado, con las columnas de `pedidos` a `NULL`. Es lo que pedía el encargo.
- **En el `WHERE`** quedan **34 876**. Los otros 15 124 desaparecieron, `CLI-00007` incluido:
  acotada a ese cliente, la primera devuelve una fila y la segunda, cero.
- **El porqué es el orden lógico de evaluación** de [`02`](02-select-y-el-orden-logico.md): el `ON`
  decide **qué empareja** mientras el join se construye, y el `WHERE` filtra **después**, sobre las
  filas ya fabricadas —nulos incluidos—. `NULL = 'ANULADO'` no es verdadero, así que se las lleva
  todas.

El planificador no se lo calla: la segunda consulta ya no es un join externo.

```text
tienda=# EXPLAIN SELECT c.id FROM clientes c
tienda-#   LEFT JOIN pedidos p ON p.cliente_id = c.id AND p.estado = 'ANULADO';
                                 QUERY PLAN                                  
-----------------------------------------------------------------------------
 Hash Right Join  (cost=1743.00..25165.00 rows=57900 width=8)
   Hash Cond: (p.cliente_id = c.id)
   ->  Seq Scan on pedidos p  (cost=0.00..23270.00 rows=57900 width=8)
         Filter: (estado = 'ANULADO'::text)
   ->  Hash  (cost=1118.00..1118.00 rows=50000 width=8)
         ->  Seq Scan on clientes c  (cost=0.00..1118.00 rows=50000 width=8)
(6 filas)

Duración: 2,664 ms
tienda=# EXPLAIN SELECT c.id FROM clientes c
tienda-#   LEFT JOIN pedidos p ON p.cliente_id = c.id WHERE p.estado = 'ANULADO';
                                 QUERY PLAN                                  
-----------------------------------------------------------------------------
 Hash Join  (cost=1743.00..25165.00 rows=57900 width=8)
   Hash Cond: (p.cliente_id = c.id)
   ->  Seq Scan on pedidos p  (cost=0.00..23270.00 rows=57900 width=8)
         Filter: (estado = 'ANULADO'::text)
   ->  Hash  (cost=1118.00..1118.00 rows=50000 width=8)
         ->  Seq Scan on clientes c  (cost=0.00..1118.00 rows=50000 width=8)
(6 filas)

Duración: 0,632 ms
```

- `Hash Right Join` contra `Hash Join`: mismo árbol, mismo `cost=25171.91`, **distinta clase de
  join**. PostgreSQL vio que el predicado rechaza nulos y **reescribió tu externo como interno**:
  escribiste `LEFT JOIN` y ejecutaste un `JOIN`. Los dos nombres son algoritmos, y su mecánica se ve
  en el bloque siguiente, [`03/05`](../03-el-motor-por-dentro/05-explain-y-explain-analyze.md) §7.
- MySQL 9.7.2 hace la misma reescritura y su manual la llama *outer join simplification*: medido con
  `EXPLAIN FORMAT=TREE`, el operador pasa de `Nested loop left join` a `Nested loop inner join`. Que
  los dos coincidan no lo vuelve estándar, pero sí algo con lo que contar.
- **Cuánto cuesta:** nada en tiempo. El precio es de corrección, y se paga en filas que faltan sin
  que nadie proteste.

> **💡 Truco.** La regla, dicha en voz alta: **en un join externo, los predicados sobre la tabla
> conservada van en el `WHERE` y los de la tabla opcional van en el `ON`**. La única excepción
> deliberada es `WHERE derecha.clave IS NULL`, que es un anti-join a propósito.

---

## 5. 🧱 Unir por una columna con nulos: no empareja nada

Un join une comparando, y `=` sobre un `NULL` no da verdadero ni falso: da desconocido, y el join
solo conserva lo verdadero. `pagos.referencia` es el material exacto: **273 126 nulos de 820 000
filas**, los pagos en efectivo, que no traen referencia de la pasarela.

```text
tienda=# SELECT count(*) AS emparejadas
tienda-#   FROM pagos a JOIN pagos b ON a.referencia = b.referencia
tienda-#  WHERE a.metodo = 'EFECTIVO';
 emparejadas 
-------------
           0
(1 fila)

Duración: 50,978 ms
```

**Cero**, y no por falta de candidatos: cada uno de esos 273 126 pagos tendría una pareja obvia,
**él mismo**. Una fila con la columna de unión nula **ni siquiera se une consigo misma**, porque la
condición no es "tienen el mismo contenido" sino "la comparación es verdadera".

- El comparador que sí trata dos ausencias como iguales —`IS NOT DISTINCT FROM` en el estándar y en
  PostgreSQL, `<=>` en MySQL y MariaDB— es de
  [`01/06`](../01-fundamentos-y-modelo-relacional/06-nulos-y-logica-de-tres-valores.md), su dueño.
  Lo que importa aquí es lo que hace **dentro de un join**: medido, un solo pago con referencia nula
  se empareja con **los 273 126** que también la tienen. Sin acotar serían 273 126² parejas, más de
  setenta y cuatro mil millones, y por eso la consulta va limitada a una fila. **Esa es la medida
  del riesgo**: el día que alguien "arregla" el join con ese comparador sin mirar la cardinalidad,
  el informe deja de terminar.
- **Cuándo sí** unir por una columna anulable: cuando la ausencia significa "sin pareja" y quieres
  que no empareje. **Cuándo no:** cuando el nulo significa "desconocido"; ahí el dato está mal
  modelado y la salida es un centinela declarado, no un comparador exótico.

> **🧠 Modelo mental.** Un join no pregunta "¿son el mismo valor?", pregunta "¿es **verdadera** la
> comparación?". Sobre nulos nunca lo es: esas filas desaparecen de un interno y sobreviven sin
> pareja en un externo.

---

## 6. ⚖️ El cruzado y el reflexivo

**El cruzado** (`CROSS JOIN`) es el producto cartesiano sin condición: cada fila de un lado con
todas las del otro. Legítimo cuando lo quieres —todas las combinaciones de una rejilla—,
catastrófico cuando se te olvidó el `ON`.

- 50 000 × 5 000 = **250 000 000 de filas**. El plan —un `Nested Loop` sobre `Seq Scan` y
  `Materialize`, con `rows=250000000` y un coste estimado de 3 126 229 contra las 1 217 unidades que
  cuesta leer las dos tablas— está pegado entero en
  [`01/03`](../01-fundamentos-y-modelo-relacional/03-algebra-relacional.md), que es el dueño del
  producto cartesiano. Va **sin `ANALYZE` a propósito**: no se ejecuta.
- **La coma es un `CROSS JOIN`.** `FROM clientes c, productos pr` sin condición produce **el mismo
  plan, línea por línea**, comprobado en sesión: el producto accidental no se ve, porque lo que
  falta es una línea que nadie escribió.

**El reflexivo** (*self join*) es unir una tabla consigo misma con dos alias. No es una clase aparte
—es un interno o un externo— pero merece nombre porque resuelve las comparaciones entre filas de la
misma tabla. El caso del dominio: líneas del mismo pedido que repiten producto.

```text
tienda=# SELECT a.pedido_id, a.linea AS linea_a, b.linea AS linea_b, a.producto_id,
tienda-#        a.cantidad AS cant_a, b.cantidad AS cant_b
tienda-#   FROM pedido_lineas a
tienda-#   JOIN pedido_lineas b
tienda-#     ON b.pedido_id = a.pedido_id AND b.producto_id = a.producto_id AND b.linea > a.linea
tienda-#  ORDER BY a.pedido_id LIMIT 3;
 pedido_id | linea_a | linea_b | producto_id | cant_a | cant_b 
-----------+---------+---------+-------------+--------+--------
         7 |       1 |       2 |          17 |      5 |      3
         7 |       1 |       3 |          17 |      5 |      1
         7 |       1 |       4 |          17 |      5 |      3
(3 filas)

Duración: 0,883 ms
```

- **`b.linea > a.linea`, no `b.linea <> a.linea`.** Con `<>` cada par saldría dos veces, una en cada
  orden; con `>` sale una vez y además se descartan las filas emparejadas consigo mismas.
- Sin el `LIMIT`, el recorrido completo da **13 764 parejas en 1 544 ms**, que son **6 855
  combinaciones (pedido, producto) repetidas** en **6 846 pedidos distintos** —nueve pedidos repiten
  dos productos—. Que los tres números no coincidan es el aviso de §2: contar parejas no es contar
  padres.

> **⏱️ Coste.** Ese reflexivo tarda 1 544 ms porque recorre 3 500 000 filas dos veces y empareja por
> `(pedido_id, producto_id)`, que no está indexado: la primaria es `(pedido_id, linea)`. Con un
> índice por esas dos columnas es otra historia, y es del bloque siguiente:
> [`03/03`](../03-el-motor-por-dentro/03-compuestos-parciales-y-de-cobertura.md).

---

## 7. 🧱 Semi-join y anti-join: los que no se escriben

**Qué son.** El **semi-join** devuelve las filas de la izquierda **que tienen al menos una pareja**,
sin traer ni una columna de la derecha y **sin multiplicar filas**; el **anti-join**, las que no
tienen ninguna. Ninguno tiene sintaxis propia: se escriben con `EXISTS` y `NOT EXISTS`, y **el plan
es quien los nombra**.

```text
tienda=# EXPLAIN (ANALYZE, BUFFERS OFF)
tienda-# SELECT c.codigo FROM clientes c
tienda-#  WHERE NOT EXISTS (SELECT 1 FROM pedidos p WHERE p.cliente_id = c.id);
                                                          QUERY PLAN                                                           
-------------------------------------------------------------------------------------------------------------------------------
 Hash Right Anti Join  (cost=1743.00..35740.35 rows=2349 width=10) (actual time=159.620..159.712 rows=1.00 loops=1)
   Hash Cond: (p.cliente_id = c.id)
   ->  Seq Scan on pedidos p  (cost=0.00..20770.00 rows=1000000 width=8) (actual time=0.008..48.287 rows=1000000.00 loops=1)
   ->  Hash  (cost=1118.00..1118.00 rows=50000 width=18) (actual time=7.715..7.716 rows=50000.00 loops=1)
         Buckets: 65536  Batches: 1  Memory Usage: 3247kB
         ->  Seq Scan on clientes c  (cost=0.00..1118.00 rows=50000 width=18) (actual time=0.006..3.136 rows=50000.00 loops=1)
 Planning Time: 0.069 ms
 Execution Time: 159.732 ms
(8 filas)

Duración: 160,488 ms
```

- `Anti Join` aparece en el plan **y no en la consulta**: el planificador reconoció el patrón `NOT
  EXISTS`. La única fila que devuelve es `CLI-00007`; su hermano el semi-join, con `EXISTS`,
  devuelve los otros **49 999 clientes en 199 ms**.
- **Cuánto cuesta:** los dos **paran en la primera coincidencia** y no producen parejas, así que
  nunca inflan el resultado. Por eso un `EXISTS` no necesita `DISTINCT` y un `JOIN` contra una hija
  sí. El `rows=2349` estimado frente al `rows=1.00` real es cosa de las estadísticas —bloque
  siguiente—, no del resultado.

MySQL 9.7.2 hace lo mismo y lo dice con otras palabras, en su formato de árbol:

```text
mysql> EXPLAIN FORMAT=TREE SELECT c.codigo FROM clientes c
    -> WHERE NOT EXISTS (SELECT 1 FROM pedidos p WHERE p.cliente_id = c.id);
-> Nested loop antijoin  (cost=115680 rows=974473)
    -> Covering index scan on c using codigo  (cost=5287 rows=49984)
    -> Covering index lookup on p using fk_pedidos_cliente (cliente_id = c.id)  (cost=5.05 rows=19.5)
```

- `Nested loop antijoin`: mismo operador, otro algoritmo. Y una diferencia de esquema que no es
  casual: MySQL usa `fk_pedidos_cliente`, **el índice que InnoDB crea solo al declarar la foránea**
  —el esquema declara la restricción, no el índice— y que PostgreSQL no crea. Dos motores, dos
  planes, por una decisión que nadie escribió. `EXPLAIN FORMAT=TREE` es de MySQL: PostgreSQL usa
  `EXPLAIN` a secas y SQLite `EXPLAIN QUERY PLAN`.

> **Veredicto:** si no vas a leer ni una columna del otro lado, no es un join: es un semi-join o un
> anti-join, se escribe con `EXISTS` / `NOT EXISTS` y se confirma en el plan.

---

## 8. 📜 Estándar, motor y convención

> **📜 Estándar o motor.** ISO/IEC 9075 es de pago y **no he verificado sus cláusulas** para esta
> tabla. Donde la columna "Estándar" dice *no verificado*, lo afirmado es lo que hacen los motores,
> comprobado en sesión contra las versiones del corpus.

| Afirmación | Estándar | PostgreSQL 18.6 | MySQL 9.7.2 | SQLite 3.53.4 |
|---|---|---|---|---|
| `INNER` y `OUTER` son palabras opcionales | No verificado | Sí | Sí | Sí |
| `FULL OUTER JOIN` disponible | En `<joined table>`; cláusula no verificada | Sí | **No**: `ERROR 1064`, con `OUTER` y sin él | Sí, **desde 3.39.0** |
| `RIGHT JOIN` disponible | No verificado | Sí | Sí | Sí, desde 3.39.0 |
| Unir por una columna nula empareja | No verificado | No (medido: 0 de 273 126) | No | No |
| Comparador que iguala dos nulos | No verificado | `IS NOT DISTINCT FROM` | **`<=>`; la forma larga da error de sintaxis** | Las dos formas |
| Un predicado del `WHERE` que rechaza nulos convierte el externo en interno | No verificado | Sí: `Hash Right Join` pasa a `Hash Join` | Sí: `left join` pasa a `inner join`, y el manual lo llama *outer join simplification* | No comprobado aquí |
| Semi-join y anti-join tienen sintaxis propia | No la tienen; cláusula no verificada | No: `EXISTS` / `NOT EXISTS`, y el plan dice `Anti Join` | No: igual, y el plan dice `antijoin` | No: igual |
| `NATURAL JOIN` disponible | No verificado | Sí | Sí | Sí |

**Convención, no estándar:** *"los filtros van en el `WHERE`, que es donde van los filtros"*. Viene
de la sintaxis de coma, donde no había `ON` y todo iba junto, y es exactamente lo que rompe un
externo. La otra mitad —*"usa `NATURAL JOIN`, que es más limpio"*— une por los nombres que el
esquema tenga hoy: entre `clientes` y `pedidos` devuelve cero filas y ningún error, medido en
[`01/03`](../01-fundamentos-y-modelo-relacional/03-algebra-relacional.md). En producción, `ON`.

---

## ⚠️ Errores frecuentes

| Se dice | Lo preciso |
|---|---|
| "Un `LEFT JOIN` nunca pierde filas de la izquierda" | No las pierde **el join**. Un predicado sobre la tabla derecha en el `WHERE` sí: 50 000 clientes pasaron a 34 876 |
| "Da igual poner la condición en el `ON` o en el `WHERE`" | Da igual en un interno. En un externo el `WHERE` lo convierte en interno, y el plan lo delata: `Hash Right Join` pasa a `Hash Join` |
| "Unir por una columna con nulos agrupa los nulos" | No empareja nada: una fila con la clave de unión nula **ni se une consigo misma**. 273 126 candidatos, 0 parejas |
| "Unir `pedidos` con `pedido_lineas` da un millón de filas" | Da 3 500 000: un join produce parejas, no columnas. Todo agregado posterior cuenta cada pedido 3,5 veces |
| "`DISTINCT` arregla las filas repetidas de un join" | Solo si son idénticas. En la trampa del abanico difieren en una columna de la otra hija, y el total sigue inflado |
| "`FULL OUTER JOIN` es estándar, así que funciona en todos" | MySQL 9.7.2 y MariaDB 12.3.3 no lo implementan: error 1064. Se escribe con `UNION ALL` de dos externos |
| "Un anti-join se escribe `LEFT JOIN … WHERE x IS NULL`" | Da el mismo resultado, pero construye antes todas las parejas. `NOT EXISTS` deja que el motor elija un `Anti Join` |

---

## 📚 Para profundizar

- **Documentación** — PostgreSQL 18, «Table Expressions», §7.2.1: las clases de join, `ON`, `USING`
  y `NATURAL`. <https://www.postgresql.org/docs/18/queries-table-expressions.html>
- **Documentación** — PostgreSQL 18, «Comparison Functions and Operators»: `IS NOT DISTINCT FROM` y
  los comparadores que toleran nulos. <https://www.postgresql.org/docs/18/functions-comparison.html>
- **Documentación** — MySQL 9.7, «JOIN Clause»: la sintaxis admitida, y `<=>` como comparador que
  iguala nulos. <https://dev.mysql.com/doc/refman/9.7/en/join.html>
- **Documentación** — MySQL 9.7, «Outer Join Simplification»: cuándo el optimizador convierte un
  externo en interno. <https://dev.mysql.com/doc/refman/9.7/en/outer-join-simplification.html>
- **Documentación** — SQLite, «SELECT»: `RIGHT` y `FULL OUTER JOIN`, disponibles desde la 3.39.0.
  <https://www.sqlite.org/lang_select.html>
- **Estándar** — ISO/IEC 9075-2 (*Foundation*), `<joined table>` y `<join condition>`. De pago, sin
  URL pública y **no verificadas en esta edición**.
- **Referencia** — Markus Winand, *Use The Index, Luke!*, «The Join Operation»: por qué el orden de
  las tablas y los índices deciden el coste de un join. <https://use-the-index-luke.com/sql/join>
- **Libro** — Markus Winand, *SQL Performance Explained*, self-published, 2012, capítulo 4, «The
  Join Operation».

---

## 🧠 Preguntas

1. ¿Qué devuelve un `INNER JOIN` y qué filas se pierden respecto de las dos tablas de origen? 🟢
2. ¿Qué pone un join externo en las columnas del lado que se quedó sin pareja, y de dónde sale ese
   valor? 🟢
3. `pedidos JOIN pedido_lineas` sobre las tablas enteras devuelve 3 500 000 filas y no 1 000 000.
   ¿Por qué? 🟢
4. ¿Qué cliente de los 50 000 no tiene pedidos, y con qué clase de join lo encuentras? 🟢
5. ¿Qué es un join reflexivo y qué pregunta del dominio resuelve sobre `pedido_lineas`? 🟢
6. Diferencia un semi-join de un join interno: ¿qué devuelve cada uno, y cuál puede multiplicar
   filas? 🟡
7. `CROSS JOIN` y la sintaxis de coma sin condición: ¿en qué se diferencian el resultado y el plan?
   🟡
8. Explica en una frase por qué unir por `pagos.referencia` no empareja ninguno de los 273 126 pagos
   en efectivo. 🟡
9. En el reflexivo de `pedido_lineas`, ¿por qué la condición es `b.linea > a.linea` y no `b.linea <>
   a.linea`? 🟡
10. ¿`FULL OUTER JOIN` lo manda el estándar o es una extensión de PostgreSQL? Di qué motores del
    corpus lo tienen y desde qué versión. 🟡
11. El informe de §1 multiplica el importe por cuatro al añadir un `JOIN` a `eventos_pedido`.
    Explica el mecanismo, y por qué `DISTINCT` no lo arregla. 🟠
12. Con `estado = 'ANULADO'` en el `ON` salen 50 000 clientes y en el `WHERE` 34 876. Explica el
    porqué apoyándote en el orden lógico de evaluación. 🟠
13. El plan pasa de `Hash Right Join` a `Hash Join` entre esas dos escrituras. ¿Qué decidió el
    planificador, y por qué tenía permiso para hacerlo? 🟠
14. ¿Por qué prefieres `NOT EXISTS` a `LEFT JOIN … IS NULL` cuando solo quieres saber si hay pareja?
    Apóyate en lo que dice el plan. 🟠
15. Un compañero propone unir por `IS NOT DISTINCT FROM` "para no perder los nulos". ¿Qué le
    preguntas antes de aprobarlo, y con qué número lo sostienes? 🟠
16. El mismo anti-join da `Hash Right Anti Join` en PostgreSQL y `Nested loop antijoin` en MySQL,
    con índices distintos. ¿Qué parte de esa diferencia es del estándar, cuál del motor y cuál del
    esquema? 🟠
17. Escribe la consulta que da, por cliente, el número de pedidos y el importe total de sus líneas
    **sin inflar ninguno de los dos**, y explica en una frase qué evita tu versión. 🔴
18. Escribe el `FULL OUTER JOIN` de conciliación de §3 tal como lo tendrías que entregar para MySQL
    9.7.2, y justifica las dos decisiones de escritura que hacen que el recuento coincida. 🔴
19. Te dan un informe con un `LEFT JOIN` a `pagos` y un `WHERE pg.metodo = 'TARJETA'` que "pierde
    pedidos". Da el diagnóstico, la corrección y las dos consultas con las que lo demostrarías. 🔴
20. Diseña la consulta que detecta líneas repetidas por producto dentro del mismo pedido y devuelve
    una sola fila por `(pedido, producto)` con la suma de cantidades. Di qué recuento esperas, y por
    qué no es el número de pedidos afectados. 🔴

---

**Anterior:** [`02`](02-select-y-el-orden-logico.md) · **Siguiente:**
[`04`](04-agregacion-y-subconsultas.md) — `EXISTS` frente a `IN` frente a `JOIN`, y los agregados
que aquí salieron inflados · **Relacionado:**
[`01/03`](../01-fundamentos-y-modelo-relacional/03-algebra-relacional.md) — el operador del álgebra
detrás de cada join ·
[`01/06`](../01-fundamentos-y-modelo-relacional/06-nulos-y-logica-de-tres-valores.md) — por qué
`NULL = NULL` no es verdadero.
