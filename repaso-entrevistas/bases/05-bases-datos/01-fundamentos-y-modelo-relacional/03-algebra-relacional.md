# 03 — Álgebra relacional

> Los operadores que el motor sabe ejecutar —selección, proyección, producto, joins, unión,
> diferencia, intersección y división— y **cómo se escribe cada uno en SQL**. No están aquí como
> ejercicio de pizarra: son el vocabulario con el que piensa el planificador, y sus nombres aparecen
> literalmente en los planes. **Asume leído:** [`02`](02-el-modelo-relacional-y-sus-claves.md) — de
> ahí vienen relación, tupla, atributo y clave foránea. **Vigencia:** 27 de septiembre de 2026.

---

## 1. 🎯 El problema

Te piden **los clientes que no han comprado nunca**: lo resuelves con un `LEFT JOIN` y un `IS NULL`,
y funciona. Al día siguiente te piden **los pedidos sin ningún pago**, copias lo anterior y también
funciona. A la tercera —**los clientes que han comprado todos los productos de audio**— se te acaba
el repertorio, porque esa no sale de copiar la anterior.

El problema no es de sintaxis: SQL tiene varias formas de escribir la misma pregunta y ninguna obvia
de escribir algunas, y sin un mapa no sabes en cuál de las dos situaciones estás. El mapa existe
desde 1970 y son ocho operadores. Hay otra razón, más inmediata: cuando abras un plan vas a leer
esto.

```text
tienda=# EXPLAIN (ANALYZE, BUFFERS OFF)
tienda-# SELECT count(*) FROM pedidos p WHERE NOT EXISTS (SELECT 1 FROM pagos pg WHERE pg.pedido_id = p.id);
                                                              QUERY PLAN                                                              
--------------------------------------------------------------------------------------------------------------------------------------
 Aggregate  (cost=67471.50..67471.51 rows=1 width=8) (actual time=512.369..512.382 rows=1.00 loops=1)
   ->  Hash Anti Join  (cost=29886.00..67021.50 rows=180000 width=0) (actual time=165.124..506.543 rows=180000.00 loops=1)
         Hash Cond: (p.id = pg.pedido_id)
         ->  Seq Scan on pedidos p  (cost=0.00..20770.00 rows=1000000 width=8) (actual time=0.034..63.361 rows=1000000.00 loops=1)
         ->  Hash  (cost=16432.00..16432.00 rows=820000 width=8) (actual time=163.895..163.896 rows=820000.00 loops=1)
               Buckets: 524288  Batches: 4  Memory Usage: 12115kB
               ->  Seq Scan on pagos pg  (cost=0.00..16432.00 rows=820000 width=8) (actual time=0.019..57.763 rows=820000.00 loops=1)
 Planning Time: 1.067 ms
 Execution Time: 513.399 ms
(9 filas)

Duración: 516,941 ms
```

**`Hash Anti Join` es un operador del álgebra, no una palabra de SQL**: en la consulta no aparece.
El planificador tradujo tu `NOT EXISTS` y te lo devuelve con su nombre de familia, y su
`rows=180000` cuadra con el dominio —120 000 pedidos `PENDIENTE` más 60 000 `ANULADO` sin pago—.
Este capítulo enseña **el operador y su traducción**; los joins, los nulos dentro de un join y la
lectura del plan entero son del bloque 02.

> **📝 Contexto.** Las sesiones se corren con `\timing on`, puesto al abrir `psql`, y por eso cada
> salida acaba en `Duración:`. Se volvieron a correr el 27 de septiembre de 2026 con `psql` en
> español; los tiempos citados en la prosa que salen de un bloque pegado son los de esa corrida.

---

## 2. 🧱 Los dos unarios: selección y proyección

**Qué son.** La **selección** (σ, *sigma*) se queda con las filas que cumplen un predicado y no toca
las columnas; se escribe `WHERE`. La **proyección** (π, *pi*) se queda con los atributos que pides y
no toca las filas; se escribe en la lista del `SELECT`.

```text
tienda=# SELECT codigo, categoria, precio, activo FROM productos WHERE codigo = 'PRD-04980';
  codigo   | categoria | precio | activo 
-----------+-----------+--------+--------
 PRD-04980 | libros    | 237.89 | f
(1 fila)

Duración: 0,655 ms
```

Ahí están los dos a la vez: el `WHERE` elige una fila de 5 000 y el `SELECT`, cuatro columnas de
seis. **PRD-04980 está inactivo** (`activo = f`), como otros 100 productos. Y en la misma tabla vive
la trampa de la traducción, medida en sesión: `SELECT categoria FROM productos` devuelve 5 000 filas
y `count(DISTINCT categoria)` devuelve 7, que es **lo que da π**. El álgebra trabaja con
**conjuntos** (sin repetidos ni orden) y SQL con **bolsas** (*bags*, multiconjuntos); por eso existe
`DISTINCT`.

**Cuánto cuesta.** σ no gasta CPU y gasta toda la E/S si no hay índice; π es gratis, pero `DISTINCT`
obliga a ordenar o a levantar una tabla hash con todas las filas candidatas. **Cuándo no:** poner
`DISTINCT` "por si acaso", que casi siempre tapa un join mal escrito.

> **📜 Estándar o motor.** La semántica de bolsa la manda el estándar y los tres motores del corpus
> coinciden. Lo que el estándar **no** fija es el orden de las filas: sin `ORDER BY` no hay orden, y
> el que ves es un accidente del plan.

> **Veredicto:** `WHERE` es σ, `SELECT` es π **con duplicados**, y `DISTINCT` es el peaje que pagas
> por volver al conjunto.

---

## 3. ⚖️ Producto cartesiano, y el join como atajo

**Qué es.** El producto cartesiano (×) empareja **cada fila de una relación con todas las de la
otra** y no filtra nada. Es el operador del que salen todos los joins: el **join theta** (⋈θ) es
`σ(condición)` aplicada sobre el producto, y el **equijoin** es el caso en que esa condición es una
igualdad. En SQL, `CROSS JOIN` y `JOIN ... ON`.

```text
tienda=# EXPLAIN SELECT * FROM clientes CROSS JOIN productos;
                                QUERY PLAN                                
--------------------------------------------------------------------------
 Nested Loop  (cost=0.00..3126229.50 rows=250000000 width=112)
   ->  Seq Scan on clientes  (cost=0.00..1118.00 rows=50000 width=67)
   ->  Materialize  (cost=0.00..124.00 rows=5000 width=45)
         ->  Seq Scan on productos  (cost=0.00..99.00 rows=5000 width=45)
(4 filas)

Duración: 0,589 ms
```

50 000 × 5 000 = **250 millones de filas**; el `EXPLAIN` va sin `ANALYZE` a propósito, porque esa
consulta no se ejecutó ni se va a ejecutar. Ese es el precio de olvidar la condición de unión: el
join degenera en producto y el informe que tardaba dos segundos deja de terminar. La condición
tampoco tiene que ser una igualdad; un theta-join con `>` entre `pedido_lineas` y `productos` —las
líneas cuyo precio congelado superó al precio actual— devuelve 5 008 filas en 468 ms. El **join
natural** (⋈) es el equijoin **sobre los atributos que se llaman igual**, y es la trampa del
temario:

```text
tienda=# SELECT count(*) FROM clientes NATURAL JOIN pedidos;
 count 
-------
     0
(1 fila)

Duración: 21,969 ms
```

`EXPLAIN (COSTS OFF)` sobre esa consulta lo explica en su `Merge Cond` y su `Join Filter`: las dos
tablas comparten tres nombres —`id`, `codigo` y `creado_en`— y el motor unió por los tres, cuando lo
que querías era `pedidos.cliente_id = clientes.id`. No dio error: dio **cero filas**, el peor
resultado posible porque parece una respuesta. `JOIN ... USING (columna)` es el punto medio, pero
añadir una columna al esquema no puede cambiar lo que devuelven tus consultas: en producción, `ON`.

**Cuánto cuesta.** El producto es O(n × m) en filas producidas y se paga en memoria de trabajo y en
ficheros temporales. **Cuándo sí:** generar combinaciones a propósito, como todos los meses por
todas las categorías. **Cuándo no:** por accidente; cuando se quiere, se escribe `CROSS JOIN`.

> **Veredicto:** el join no es un operador primitivo, es `σ` sobre `×`; y el `NATURAL JOIN` se queda
> en la pizarra, porque une por los nombres que el esquema tenga hoy.

---

## 4. 🩺 Semi-join y anti-join: los que no tienen palabra clave

**Qué son.** El **semi-join** (⋉) devuelve las filas de la izquierda **que tienen pareja**, sin
traer ni una columna de la derecha; el **anti-join** (▷), las que **no la tienen**. Ninguno tiene
sintaxis propia en SQL: se escriben con `EXISTS` y `NOT EXISTS`. El **join externo** (⟕) es otra
cosa: conserva las filas sin pareja y rellena el otro lado con nulos.

```text
tienda=# SELECT c.codigo AS cliente, p.codigo AS pedido, p.estado
tienda-# FROM clientes c LEFT JOIN pedidos p ON p.cliente_id = c.id
tienda-# WHERE c.codigo = 'CLI-00007';
  cliente  | pedido | estado 
-----------+--------+--------
 CLI-00007 |        | 
(1 fila)

Duración: 45,137 ms
```

- **CLI-00007** es el único de los 50 000 clientes sin pedidos, y las dos celdas vacías son `NULL`,
  no cadenas vacías. El semi-join equivalente, con `EXISTS`, devuelve 49 999 en 131 ms.
- El anti-join hermano es el de §1: `NOT EXISTS (SELECT 1 FROM pagos pg WHERE pg.pedido_id = p.id)`
  devuelve 180 000 pedidos en 513 ms, y **PED-99999**, `ANULADO` y sin pagos, es uno de ellos. El
  `LEFT JOIN ... WHERE derecha IS NULL` da lo mismo, pero construye antes todas las parejas.

Y la razón de peso para preferir `NOT EXISTS` a `NOT IN`: la misma intención, dos escrituras, sobre
`pagos.referencia`, que admite nulos.

```text
tienda=# SELECT (SELECT count(*) FROM pagos p
tienda(#         WHERE p.referencia NOT IN (SELECT referencia FROM pagos WHERE metodo='EFECTIVO'))   AS con_not_in,
tienda-#        (SELECT count(*) FROM pagos p
tienda(#         WHERE NOT EXISTS (SELECT 1 FROM pagos q
tienda(#                           WHERE q.metodo='EFECTIVO' AND q.referencia = p.referencia))       AS con_not_exists;
 con_not_in | con_not_exists 
------------+----------------
          0 |         820000
(1 fila)

Duración: 246,403 ms
```

Cero contra ochocientos veinte mil. Los 273 126 pagos en efectivo tienen `referencia` nula, y un
solo `NULL` en la lista del `NOT IN` impide que la comparación sea verdadera para nadie; el porqué
es de [`06`](06-nulos-y-logica-de-tres-valores.md), dueño de la lógica de tres valores. **Cuánto
cuesta:** los dos paran en la primera coincidencia y **no multiplican filas**, y por eso `EXISTS` no
necesita `DISTINCT` y un `JOIN` a una tabla hija sí. **Cuándo no:** si necesitas columnas del otro
lado.

> **Veredicto:** si no vas a leer ni una columna del otro lado, es semi-join o anti-join, y se
> escribe `EXISTS` / `NOT EXISTS`.

---

## 5. 🧱 Los tres de conjuntos: unión, diferencia, intersección

**Qué son.** Unión (∪), diferencia (−) e intersección (∩) operan entre dos relaciones **compatibles
en unión** —mismo número de atributos y dominios compatibles— y traducen uno a uno a `UNION`,
`EXCEPT` e `INTERSECT`. La diferencia resuelve el primer encargo del capítulo sin un solo join:
`SELECT id FROM clientes EXCEPT SELECT cliente_id FROM pedidos` devuelve una fila en 148 ms, el `id`
de **CLI-00007**.

`UNION` es el operador del álgebra: deduplica. Unir las categorías de los productos de más de 900
con las de los inactivos da **7 filas con `UNION` y 602 con `UNION ALL`**, corrido en sesión, y para
dejarlas en 7 el motor **ordena o levanta una tabla hash con esas 602**; `UNION ALL` es el
concatenador barato y no está en el álgebra. **Cuánto cuesta:** los tres son bloqueantes,
materializan los dos lados antes de devolver una fila, y de ahí el **cuándo no**: paginar, porque un
`UNION` con `LIMIT 20` procesa los conjuntos enteros igual.

La compatibilidad no es negociable, y aquí los motores se separan. PostgreSQL 18.6 rechaza `SELECT
codigo FROM clientes UNION SELECT total FROM pedidos` con `ERROR: UNION types text and numeric
cannot be matched`. La misma unión en MySQL 9.7.2, acotada a `CLI-00007` y `PED-00042`, devuelve dos
filas bajo una columna llamada `codigo` —`CLI-00007` y `3186.23`, el importe convertido a texto—: en
un motor es un error, en el otro un informe.

> **⚠️ Advertencia.** `INTERSECT` y `EXCEPT` **no existían en MySQL hasta la 8.0.31**. En la 9.7.2
> del corpus funcionan los tres, verificado en sesión. Si tu producción corre 5.7 o una 8.0
> anterior, la diferencia se escribe con `NOT EXISTS` y la intersección con `EXISTS`.

> **Veredicto:** los tres operadores de conjunto existen en SQL con su nombre, y el único que tienes
> que pensar dos veces es `UNION`, porque deduplica aunque no se lo pidas.

---

## 6. 🧭 La división relacional: "todos los de"

**Qué es.** La división (÷) contesta lo que ningún otro operador contesta: **¿quiénes están
relacionados con *todos* los elementos de este conjunto?**. No tiene palabra clave en SQL —ni en el
estándar ni en ningún motor del corpus—, y por eso es la que atasca la entrevista. El encargo del
dominio: **clientes que han comprado todos los productos de la categoría `audio`**; la traducción
práctica es agrupar y comparar el recuento de distintos con el tamaño del divisor.

```text
tienda=# SELECT c.codigo FROM clientes c
tienda-# JOIN pedidos p ON p.cliente_id = c.id JOIN pedido_lineas pl ON pl.pedido_id = p.id
tienda-# JOIN productos pr ON pr.id = pl.producto_id AND pr.categoria = 'audio'
tienda-# GROUP BY c.codigo
tienda-# HAVING count(DISTINCT pr.id) = (SELECT count(*) FROM productos WHERE categoria = 'audio');
 codigo 
--------
(0 filas)

Duración: 1188,010 ms (00:01,188)
```

Cero filas, y es la respuesta correcta: `audio` tiene 443 productos y el cliente con más variedad
llegó a 21. **Un cociente vacío no es un fallo de la consulta**; es lo normal cuando el divisor es
grande. Con un divisor realista —los dos productos de audio que pasan de 998, añadiendo `AND
pr.precio > 998` en los dos sitios— devuelve 13 clientes en 236 ms. La forma canónica de la pizarra
es el **doble `NOT EXISTS`**: *no existe ningún producto del divisor que este cliente no haya
comprado*, dos anti-joins anidados.

```text
tienda=# SELECT c.codigo FROM clientes c
tienda-# WHERE c.codigo IN ('CLI-00007','CLI-00311','CLI-02906')   -- dividendo acotado a tres clientes
tienda-#   AND NOT EXISTS (                                        -- no hay producto de audio caro...
tienda(#       SELECT 1 FROM productos pr
tienda(#       WHERE pr.categoria = 'audio' AND pr.precio > 998
tienda(#         AND NOT EXISTS (                                  -- ...que este cliente no haya comprado
tienda(#             SELECT 1 FROM pedidos p JOIN pedido_lineas pl ON pl.pedido_id = p.id
tienda(#             WHERE p.cliente_id = c.id AND pl.producto_id = pr.id));
  codigo   
-----------
 CLI-02906
(1 fila)

Duración: 103,524 ms
```

Acotar el dividendo a tres clientes no es cosmético: **sin ese `IN`, la consulta no terminó en siete
minutos y la corté**, frente a los 236 ms de la agregada. Es cosa de este esquema: sin más índices
que los de las claves, el doble `NOT EXISTS` correlacionado recorre `pedido_lineas` por cada pareja
cliente-producto. **Cuándo no** montar la agregada: con un divisor corto y fijo sale más barato
contar la pertenencia con `count(*) FILTER (WHERE …)`.

> **💡 Truco.** Di las dos y la diferencia: el doble `NOT EXISTS` es la división exacta y no supone
> nada; la agregada **exige que el dividendo no traiga duplicados**, y por eso lleva `count(DISTINCT
> pr.id)` y no `count(*)`.

> **Veredicto:** "todos los de" es división, y en SQL se escribe con doble `NOT EXISTS` o contando
> distintos contra el tamaño del divisor. No hay tercera forma.

---

## 7. 📜 Estándar, motor y convención

| Afirmación | Estándar | PostgreSQL 18.6 | MySQL 9.7.2 | SQLite 3.53.4 |
|---|---|---|---|---|
| `SELECT` conserva duplicados; `DISTINCT` los quita | Sí, semántica de bolsa | Igual | Igual | Igual |
| `INTERSECT` y `EXCEPT` disponibles | Sí, 9075-2 | Sí | **Desde 8.0.31**; sí en 9.7.2 | Sí |
| `FULL OUTER JOIN` disponible | Sí | Sí | **No**: error 1064 de sintaxis | Sí, desde 3.39.0 |
| `UNION` entre `text` y `numeric` | No verifiqué la cláusula | Error: *types text and numeric cannot be matched* | Lo convierte a texto y lo acepta | No probado aquí |
| La división tiene operador propio | **No lo tiene** | No | No | No |
| `NOT IN` con un `NULL` dentro no devuelve nada | Sí, lógica de tres valores | Igual | Igual | Igual |

**Convención:** *"el `NATURAL JOIN` es más limpio"* y *"usa `UNION` para no repetir filas"*. Lo
primero es costumbre de aula, y acabas de verlo devolver cero filas; lo segundo, reflejo de tecleo.
La columna de cada motor la verifiqué corriendo las consultas; del estándar me apoyo en lo público
—que los operadores de conjunto y los joins externos están en la norma—, y **la cláusula sobre
compatibilidad de tipos en `UNION` no la verifiqué**.

---

## ⚠️ Errores frecuentes

| Se dice | Lo preciso |
|---|---|
| "`SELECT` es la proyección del álgebra" | Es proyección **con duplicados**: 5 000 filas frente a las 7 de π. Necesitas `DISTINCT` para igualarla |
| "`NOT IN` y `NOT EXISTS` son equivalentes" | Solo si la subconsulta no puede devolver `NULL`. Con un nulo dentro, `NOT IN` dio 0 filas donde `NOT EXISTS` dio 820 000 |
| "`EXCEPT` no existe en MySQL" | Existe desde 8.0.31 y funciona en 9.7.2. Lo que MySQL sigue sin tener es `FULL OUTER JOIN` |
| "La división es teoría que no se usa" | Es "clientes que compraron todos los productos de la promoción", y se escribe con doble `NOT EXISTS` |
| "Un `LEFT JOIN` con `IS NULL` es un anti-join" | Da el mismo resultado, pero construye antes todas las parejas. `NOT EXISTS` deja que el motor elija un `Hash Anti Join` |

---

## 📚 Para profundizar

- **Documentación** — PostgreSQL 18, «Table Expressions»: joins, `USING`, `NATURAL` y externos.
  <https://www.postgresql.org/docs/18/queries-table-expressions.html>
- **Documentación** — PostgreSQL 18, «Combining Queries»: `UNION`, `INTERSECT` y `EXCEPT`.
  <https://www.postgresql.org/docs/18/queries-union.html>
- **Documentación** — PostgreSQL 18, «Subquery Expressions»: `EXISTS`, `IN` y los nulos.
  <https://www.postgresql.org/docs/18/functions-subquery.html>
- **Documentación** — MySQL 9.7, «Set Operations with UNION, INTERSECT, and EXCEPT».
  <https://dev.mysql.com/doc/refman/9.7/en/set-operations.html>
- **Documentación** — SQLite, «SELECT»: `RIGHT` y `FULL OUTER JOIN`, desde la 3.39.0.
  <https://www.sqlite.org/lang_select.html>
- **Estándar** — ISO/IEC 9075-2, `<query expression>` y `<joined table>`. De pago, sin URL pública y
  **no verificadas en esta edición**.
- **Libro** — C. J. Date, *SQL and Relational Theory*, O'Reilly, 3.ª ed., capítulos 6 y 7: los
  operadores y la división.

---

## 🧠 Preguntas

1. ¿Qué hace la selección (σ) y qué hace la proyección (π), y con qué se escribe cada una en SQL? 🟢
2. ¿Cuáles son los tres operadores de conjunto del álgebra y qué palabra clave les corresponde? 🟢
3. ¿Qué es un join externo y qué pone en las columnas del lado que se queda sin pareja? 🟢
4. ¿Qué pregunta contesta la división relacional que no contesta ningún otro operador? 🟢
5. `SELECT categoria FROM productos` devuelve 5 000 filas y la proyección del álgebra sobre ese
   atributo devuelve 7. ¿Por qué? 🟡
6. Diferencia entre `UNION` y `UNION ALL`, y cuál de los dos es el operador del álgebra. 🟡
7. Diferencia entre un semi-join y un join normal, y cómo se escribe cada uno. 🟡
8. `JOIN ... ON`, `JOIN ... USING` y `NATURAL JOIN` sobre las mismas tablas: ¿en qué se diferencian
   el resultado y las columnas devueltas? 🟡
9. ¿`INTERSECT` y `EXCEPT` los fija el estándar, y desde qué versión los tiene MySQL? Di también qué
   motor del corpus sigue sin `FULL OUTER JOIN`. 🟠
10. Un `NATURAL JOIN` entre `clientes` y `pedidos` devuelve cero filas y no da error. Explica por
    qué y qué columnas usó el motor para unir. 🟠
11. ¿Por qué prefieres `NOT EXISTS` a `NOT IN` cuando la subconsulta puede devolver nulos? Apóyate
    en un número. 🟠
12. Un compañero añade `DISTINCT` a un informe porque "salían filas repetidas". ¿Qué le preguntas
    antes de aprobarlo, y qué sospechas? 🟠
13. La división sobre los 443 productos de audio devuelve cero filas. ¿Es un error de la consulta?
    Justifica. 🟠
14. Unir `text` con `numeric` es un error en PostgreSQL 18.6 y devuelve filas en MySQL 9.7.2. ¿Cuál
    de los dos comportamientos puedes atribuir al estándar, cuál al motor, y cómo lo comprobarías? 🟠
15. Escribe la consulta que devuelve los clientes sin ningún pedido en las tres formas del álgebra:
    anti-join, join externo y diferencia de conjuntos. 🔴
16. Escribe la división "clientes que compraron todos los productos de la categoría `audio`" en sus
    dos formas, doble `NOT EXISTS` y `GROUP BY ... HAVING`, y di qué supone cada una sobre los
    duplicados. 🔴
17. Te dan un plan con `Hash Anti Join` sobre `pedidos` y `pagos` y `rows=180000`. Reconstruye la
    consulta que lo produjo y explica de dónde sale ese número. 🔴
18. Reescribe el anti-join de `pagos` contra los pagos en efectivo para que funcione aunque
    `referencia` admita nulos, y di en una frase qué arregla tu versión. 🔴

---

**Anterior:** [`02`](02-el-modelo-relacional-y-sus-claves.md) · **Siguiente:**
[`04`](04-normalizacion-y-desnormalizacion.md) · **Relacionado:**
[`06`](06-nulos-y-logica-de-tres-valores.md) — por qué un `NULL` en un `NOT IN` deja la consulta sin
filas.
