# 03 — Grafo

> Qué es una base de grafos, cuándo recorrer relaciones deja de ser cosa de `JOIN` y cuándo no.
> Medido con las 345 378 compras de los pedidos hasta `PED-99999` en Neo4j y en PostgreSQL: con
> profundidad fija, la recomendación de productos, PostgreSQL gana (143 ms frente a 305); con
> profundidad variable, el camino más corto, Neo4j tarda 25 ms y la CTE recursiva entre 75 ms, con
> un truco que su documentación desaconseja, y 3,7 s; y cuando no hay camino, 2 ms frente a 24,6 s.
> Y un producto con 2 528 compradores que pone a toda la tienda a dos productos de distancia.
> **Asume leído:** [`01`](01-mas-alla-de-las-tablas.md) y
> [`02/05`](../02-sql/05-cte-y-recursion.md), la CTE recursiva. **Vigencia:** 27 de septiembre de
> 2026.

---

## Salto rápido

- [1. El problema](#1--el-problema) · [2. Nodos, relaciones y
  propiedades](#2--nodos-relaciones-y-propiedades)
- [3. Profundidad fija: la recomendación](#3-️-profundidad-fija-la-recomendación) · [4. Profundidad
  variable: el camino más corto](#4--profundidad-variable-el-camino-más-corto)
- [5. El supernodo](#5--el-supernodo) · [6. La ficha del modelo](#6--la-ficha-del-modelo)
- [7. Estándar, motor y convención](#7--estándar-motor-y-convención) · [Errores
  frecuentes](#️-errores-frecuentes) · [Preguntas](#-preguntas)

---

## 1. 🎯 El problema

Dos preguntas sobre las mismas compras. La primera: **«quienes compraron lo mismo que `CLI-00311`,
¿qué más compraron?»**. Es la recomendación clásica, y tiene una forma fija: yo → producto → otro
cliente → otro producto. Tres saltos, siempre tres.

La segunda: **«¿cómo se llega de `CLI-00311` a `CLI-26446` a través de productos comprados en
común?»**. No se sabe de antemano cuántos saltos hay. Pueden ser dos, cuatro u ocho, y la
respuesta es el camino, no solo la distancia. Es la forma de las preguntas de fraude —«¿esta
cuenta nueva está conectada con alguna cuenta bloqueada, por la tarjeta, el teléfono o la
dirección?»— y de los grados de separación.

En SQL, la primera es un `JOIN` de tres tablas. La segunda es una CTE recursiva que busca desde un
solo lado. Una base de grafos promete resolver las dos recorriendo relaciones en vez de unir tablas.
Este capítulo mide si cumple, y descubre que solo cumple en una.

> **📝 Contexto.** Todo está corrido contra `bd-lab-neo4j`, el servicio de `docker-compose.otros.yml`
> con `neo4j:5.26.31-community` (§4.5 del documento de dominio), y contra `bd-lab-postgres`. El
> grafo son las compras agregadas por cliente y producto de los pedidos hasta `PED-99999`,
> exportadas con `\copy` a `13-laboratorio/entorno/datos/neo4j/compras.csv`, que no se versiona. Las
> mismas 345 378 filas se cargaron en PostgreSQL en una tabla `grafo.compras`, en un esquema que se
> borró al terminar. Los tiempos de Neo4j son los que imprime `cypher-shell`, con la caché ya
> caliente; los de PostgreSQL, los de `\timing`. La recomendación de §3 y la primera CTE de §4 son
> un mismo fichero, en su segunda ejecución, y su salida se parte entre las dos secciones.
> **Longitud:** unas 535 líneas; capítulo denso, declarado en §4.6 de la guía de estilo: 181 líneas
> de sesión y plan.

---

## 2. 🧱 Nodos, relaciones y propiedades

**Qué es:** una base de grafos guarda **nodos** —las cosas—, **relaciones** entre ellos —con
dirección y un tipo— y **propiedades** en los dos. En Neo4j, un nodo lleva **etiquetas**
(`:Cliente`, `:Producto`) y una relación, un **tipo** (`:COMPRO`). Lo que la distingue no es poder
representar un grafo —una tabla `compras (cliente, producto)` también lo representa— sino que
**la relación se guarda como dato propio**: desde un nodo se llega a sus vecinos sin buscar en un
índice. La documentación de Neo4j lo resume en una frase: las bases de grafos no usan `JOIN`.

**Quién lo manda:** el lenguaje es **Cypher**, de Neo4j, y desde 2024 hay estándar: **GQL**, ISO/IEC
39075:2024, que la documentación de Cypher dice cubrir en la mayoría de sus funciones obligatorias.
El almacenamiento y el recorrido son **motor**.

El grafo se carga con `cypher-shell`, el cliente de línea de órdenes de Neo4j, con el CSV copiado a
la carpeta `import` del contenedor:

```text
neo4j@neo4j> CREATE CONSTRAINT cliente_codigo FOR (c:Cliente) REQUIRE c.codigo IS UNIQUE;
0 rows
ready to start consuming query after 62 ms, results consumed after another 0 ms
Added 1 constraints
neo4j@neo4j> CREATE CONSTRAINT producto_codigo FOR (p:Producto) REQUIRE p.codigo IS UNIQUE;
0 rows
ready to start consuming query after 18 ms, results consumed after another 0 ms
Added 1 constraints
neo4j@neo4j> LOAD CSV WITH HEADERS FROM 'file:///compras.csv' AS f CALL (f) { MERGE (c:Cliente {codigo: f.cliente}) MERGE (p:Producto {codigo: f.producto}) CREATE (c)-[:COMPRO {unidades: toInteger(f.unidades)}]->(p) } IN TRANSACTIONS OF 10000 ROWS;
0 rows
ready to start consuming query after 6814 ms, results consumed after another 0 ms
Added 48252 nodes, Created 345378 relationships, Set 393630 properties, Added 48252 labels
neo4j@neo4j> MATCH (c:Cliente) RETURN count(c) AS clientes;
+----------+
| clientes |
+----------+
| 43252    |
+----------+

1 row
ready to start consuming query after 52 ms, results consumed after another 0 ms
neo4j@neo4j> MATCH ()-[r:COMPRO]->() RETURN count(r) AS compras;
+---------+
| compras |
+---------+
| 345378  |
+---------+

1 row
ready to start consuming query after 60 ms, results consumed after another 0 ms
```

- **`CREATE CONSTRAINT ... IS UNIQUE`** es lo más parecido a una clave: Neo4j no tiene claves por
  defecto, y sin la restricción nada impide dos nodos `CLI-00311`. La restricción crea además un
  índice, que es lo que hace rápida la búsqueda del nodo de partida.
- **`MERGE`** crea el nodo solo si no existe —usa el índice de la restricción— y **`CREATE`** crea
  la relación siempre, porque cada fila del CSV es un par cliente-producto distinto.
- **`CALL (f) { ... } IN TRANSACTIONS OF 10000 ROWS`** parte la carga en transacciones de diez mil
  filas, para no tener 345 378 escrituras pendientes en memoria a la vez.
- **6,8 s** para 48 252 nodos —43 252 clientes y 5 000 productos— y 345 378 relaciones.
- **`ready to start consuming query after ... ms`** es el tiempo hasta el primer resultado, y
  `results consumed after another ... ms`, el que falta para el último. La suma es lo que tardó.

> **Veredicto:** el grafo no es otra forma de dibujar las tablas: es otra forma de guardarlas, con
> la relación como dato y sin claves por defecto.

---

## 3. ⚖️ Profundidad fija: la recomendación

La primera pregunta de §1, en Cypher, se escribe como se dibuja:

```text
neo4j@neo4j> MATCH (yo:Cliente {codigo: 'CLI-00311'})-[:COMPRO]->(:Producto)<-[:COMPRO]-(otro:Cliente)-[:COMPRO]->(rec:Producto) WHERE NOT (yo)-[:COMPRO]->(rec) RETURN rec.codigo AS producto, count(DISTINCT otro) AS clientes_en_comun ORDER BY clientes_en_comun DESC, producto LIMIT 3;
+---------------------------------+
| producto    | clientes_en_comun |
+---------------------------------+
| "PRD-00017" | 386               |
| "PRD-00026" | 280               |
| "PRD-00011" | 270               |
+---------------------------------+

3 rows
ready to start consuming query after 4 ms, results consumed after another 301 ms
```

- **El patrón es la pregunta**: yo compré un producto, otro lo compró, ¿qué más compró que yo no?
  `WHERE NOT (yo)-[:COMPRO]->(rec)` es el anti-join, escrito como un trozo de dibujo.
- **305 ms**, con la caché caliente.

Y la misma en SQL, sobre la tabla `grafo.compras` con su clave primaria `(cliente, producto)` y un
índice `(producto, cliente)` para recorrerla en los dos sentidos:

```sql
SELECT c3.producto, count(DISTINCT c2.cliente) AS clientes_en_comun
FROM grafo.compras c1
JOIN grafo.compras c2 ON c2.producto = c1.producto AND c2.cliente <> c1.cliente
JOIN grafo.compras c3 ON c3.cliente = c2.cliente
WHERE c1.cliente = 'CLI-00311'
  AND NOT EXISTS (SELECT 1 FROM grafo.compras y
                  WHERE y.cliente = 'CLI-00311' AND y.producto = c3.producto)
GROUP BY c3.producto ORDER BY clientes_en_comun DESC, c3.producto LIMIT 3;
```

```text
 producto  | clientes_en_comun 
-----------+-------------------
 PRD-00017 |               386
 PRD-00026 |               280
 PRD-00011 |               270
(3 filas)

Duración: 142,721 ms
```

- **El mismo resultado en 143 ms**, menos de la mitad. Es la segunda ejecución; la primera tardó
  153 ms.
- **Por qué gana SQL aquí**: la profundidad es fija, así que el planificador ve los tres saltos de
  una vez y elige cómo unirlos, con índices que ya cubren las dos direcciones. Un `JOIN` con índice
  no es lento; lo lento es un `JOIN` que no sabe cuántas veces repetirse.

> **Veredicto:** con profundidad fija y conocida, un `JOIN` con buenos índices empata o gana. La
> recomendación de productos, sola, no justifica una base de grafos.

---

## 4. 🩺 Profundidad variable: el camino más corto

La segunda pregunta, en Cypher:

```text
neo4j@neo4j> MATCH p = shortestPath((a:Cliente {codigo: 'CLI-00311'})-[:COMPRO*..10]-(b:Cliente {codigo: 'CLI-26446'})) RETURN [n IN nodes(p) | n.codigo] AS camino, length(p) AS saltos;
+----------------------------------------------------------------------------+
| camino                                                            | saltos |
+----------------------------------------------------------------------------+
| ["CLI-00311", "PRD-00015", "CLI-49552", "PRD-00035", "CLI-26446"] | 4      |
+----------------------------------------------------------------------------+

1 row
ready to start consuming query after 13 ms, results consumed after another 12 ms
```

- **`[:COMPRO*..10]`** es una relación de longitud variable, hasta diez saltos, en cualquier
  dirección porque el patrón no lleva flecha. **`shortestPath`** pide el más corto.
- **25 ms**, y devuelve **el camino entero**: `CLI-00311` compró `PRD-00015`, que compró
  `CLI-49552`, que compró `PRD-00035`, que compró `CLI-26446`.
- **Por qué es tan rápido**: la documentación dice que el planificador hace una **búsqueda en
  anchura desde los dos extremos** y para en cuanto se encuentran, en vez de recorrer todo el grafo.

En SQL, la herramienta es la CTE recursiva de [`02/05`](../02-sql/05-cte-y-recursion.md). Cada
vuelta avanza dos saltos —de cliente a producto y de producto a cliente—, y hay que decirle dónde
parar. La versión directa calcula la distancia con `min`:

```sql
WITH RECURSIVE bfs(cliente, saltos) AS (
  SELECT 'CLI-00311'::text, 0
  UNION
  SELECT c2.cliente, b.saltos + 1
  FROM bfs b
  JOIN grafo.compras c1 ON c1.cliente = b.cliente
  JOIN grafo.compras c2 ON c2.producto = c1.producto
  WHERE b.saltos < 2
)
SELECT min(saltos) * 2 AS saltos FROM bfs WHERE cliente = 'CLI-26446';
```

```text
 saltos 
--------
      4
(1 fila)

Duración: 3672,620 ms (00:03,673)
```

- **`WHERE b.saltos < 2`** limita a dos vueltas, cuatro saltos. Si el destino estuviera a seis, esta
  consulta no lo encontraría; y subir el límite multiplica el trabajo.
- **3,7 s frente a 25 ms**, casi ciento cincuenta veces más. Y solo da la distancia: para devolver
  el camino habría que arrastrar un array con los nodos visitados en cada fila.
- **`UNION`** descarta las filas repetidas, pero la fila es el par `(cliente, saltos)`: un cliente
  alcanzado en la vuelta 1 vuelve a aparecer en la 2 con otro número.

El plan dice dónde se va el tiempo. Es la misma CTE bajo `EXPLAIN` con las opciones `ANALYZE`,
`BUFFERS`, `COSTS OFF` y `TIMING OFF`, y agrupando por `saltos` para contar los clientes de cada
vuelta en vez de buscar uno:

```text
                                                      QUERY PLAN                                                       
-----------------------------------------------------------------------------------------------------------------------
 Sort (actual rows=3.00 loops=1)
   Sort Key: bfs.saltos
   Sort Method: quicksort  Memory: 25kB
   Buffers: shared hit=329894 read=1633
   I/O Timings: shared read=81.955
   CTE bfs
     ->  Recursive Union (actual rows=49055.00 loops=1)
           Storage: Memory  Maximum Storage: 2493kB
           Buffers: shared hit=329891 read=1633
           I/O Timings: shared read=81.955
           ->  Result (actual rows=1.00 loops=1)
           ->  Nested Loop (actual rows=8644018.33 loops=3)
                 Buffers: shared hit=329891 read=1633
                 I/O Timings: shared read=81.955
                 ->  Nested Loop (actual rows=20887.67 loops=3)
                       Buffers: shared hit=17411
                       ->  WorkTable Scan on bfs b (actual rows=1934.33 loops=3)
                             Filter: (saltos < 2)
                             Rows Removed by Filter: 14417
                       ->  Index Only Scan using compras_pkey on compras c1 (actual rows=10.80 loops=5803)
                             Index Cond: (cliente = b.cliente)
                             Heap Fetches: 0
                             Index Searches: 5803
                             Buffers: shared hit=17411
                 ->  Index Only Scan using compras_producto_cliente_idx on compras c2 (actual rows=413.83 loops=62663)
                       Index Cond: (producto = c1.producto)
                       Heap Fetches: 0
                       Index Searches: 62663
                       Buffers: shared hit=312480 read=1633
                       I/O Timings: shared read=81.955
   ->  HashAggregate (actual rows=3.00 loops=1)
         Group Key: bfs.saltos
         Batches: 1  Memory Usage: 32kB
         Buffers: shared hit=329891 read=1633
         I/O Timings: shared read=81.955
         ->  CTE Scan on bfs (actual rows=49055.00 loops=1)
               Storage: Memory  Maximum Storage: 2429kB
               Buffers: shared hit=329891 read=1633
               I/O Timings: shared read=81.955
 Planning:
   Buffers: shared hit=134
 Planning Time: 0.569 ms
 Execution Time: 4995.335 ms
(43 filas)
```

- **`Nested Loop (actual rows=8644018.33 loops=3)`**: en total, unos **25,9 millones de filas**
  generadas —8,6 millones por vuelta de media— para quedarse con **49 055** en el `Recursive Union`.
  Cada fila es un camino, no un cliente: la CTE recorre **caminos**, y el número de caminos crece
  multiplicando.
- **`actual rows=413.83 loops=62663`**: cada producto visitado devuelve de media 414 compradores.
  Esa media la infla un solo producto, que es §5.
- **La consulta del plan tardó 5,0 s** porque cuenta todos los clientes por vuelta: 1, 5 802 y
  43 252.

**La CTE puede parar antes**, y conviene saberlo antes de que lo diga el entrevistador. Si arrastra
el camino en un array, usa `UNION ALL` y la consulta de fuera pide una sola fila:

```sql
WITH RECURSIVE bfs(cliente, camino) AS (
  SELECT 'CLI-00311'::text, ARRAY['CLI-00311']
  UNION ALL
  SELECT c2.cliente, b.camino || c1.producto || c2.cliente
  FROM bfs b
  JOIN grafo.compras c1 ON c1.cliente = b.cliente
  JOIN grafo.compras c2 ON c2.producto = c1.producto AND c2.cliente <> ALL (b.camino)
  WHERE cardinality(b.camino) < 5
)
SELECT camino FROM bfs WHERE cliente = 'CLI-26446' LIMIT 1;
```

```text
                       camino                        
-----------------------------------------------------
 {CLI-00311,PRD-00001,CLI-01135,PRD-00035,CLI-26446}
(1 fila)

Duración: 75,301 ms
```

- **75 ms y el camino entero**, otro de cuatro saltos que el de Neo4j. Es el mismo destino a la
  misma distancia: la vuelta de la CTE va por niveles, así que el primer camino que sale es de los
  más cortos.
- **Para porque PostgreSQL evalúa la CTE solo hasta las filas que pide la consulta de fuera**, y
  `LIMIT 1` deja de pedir en cuanto llega la primera. La documentación lo explica y **desaconseja
  usarlo como truco en producción**: otros sistemas pueden no hacerlo, y deja de funcionar si la
  consulta de fuera ordena o une el resultado con otra tabla.
- **`c2.cliente <> ALL (b.camino)`** evita volver a un cliente **del mismo camino**; no evita que
  otros caminos lo visiten. Y `cardinality(b.camino) < 5` es el tope: cuatro saltos.

**Y cuando no hay camino**, el truco no ayuda. `CLI-00007` es el cliente sin pedidos del documento
de dominio. La misma CTE, buscándolo:

```text
 camino 
--------
(0 filas)

Duración: 24619,385 ms (00:24,619)
```

Y en Neo4j, con `CLI-00007` dado de alta como nodo sin relaciones, que es lo que es:

```text
neo4j@neo4j> MERGE (:Cliente {codigo: 'CLI-00007'});
0 rows
ready to start consuming query after 26 ms, results consumed after another 0 ms
Added 1 nodes, Set 1 properties, Added 1 labels
neo4j@neo4j> MATCH p = shortestPath((a:Cliente {codigo: 'CLI-00311'})-[:COMPRO*..10]-(b:Cliente {codigo: 'CLI-00007'})) RETURN [n IN nodes(p) | n.codigo] AS camino, length(p) AS saltos;
+-----------------+
| camino | saltos |
+-----------------+
+-----------------+

0 rows
ready to start consuming query after 1 ms, results consumed after another 1 ms
```

- **24,6 s frente a 2 ms.** La CTE busca desde un solo extremo, así que no sabe que no hay camino
  hasta haber enumerado todos los caminos hasta el tope. Neo4j busca también desde el destino: su
  frontera está vacía desde el primer paso, y la búsqueda termina.

> **⚠️ Advertencia.** Las dos defensas de [`02/05`](../02-sql/05-cte-y-recursion.md) §5 —`UNION` y
> el tope de profundidad— evitan el bucle infinito, no la explosión. Parar al encontrar el destino
> depende de la evaluación perezosa, y descartar pronto que no hay camino no se puede.

> **Veredicto:** con profundidad variable, el grafo gana por algoritmo, no por magia: busca desde
> los dos lados y sabe cuándo parar. La CTE, con truco, se acerca cuando hay camino; cuando no lo
> hay, enumera todos hasta el límite.

---

## 5. 🩺 El supernodo

La media de 414 compradores por producto visitado no se parece a la de la tienda. Contando
compradores por producto:

```text
neo4j@neo4j> MATCH (p:Producto)<-[r:COMPRO]-() RETURN p.codigo AS producto, count(r) AS compradores ORDER BY compradores DESC LIMIT 3;
+---------------------------+
| producto    | compradores |
+---------------------------+
| "PRD-00017" | 2528        |
| "PRD-00025" | 1522        |
| "PRD-00027" | 1507        |
+---------------------------+

3 rows
ready to start consuming query after 36 ms, results consumed after another 90 ms
neo4j@neo4j> MATCH (a:Cliente {codigo: 'CLI-00311'})-[:COMPRO*4]-(o:Cliente) WHERE o <> a RETURN count(DISTINCT o) AS a_dos_productos;
+-----------------+
| a_dos_productos |
+-----------------+
| 43251           |
+-----------------+

1 row
ready to start consuming query after 1 ms, results consumed after another 212 ms
```

- **`PRD-00017`, el más vendido, tiene 2 528 compradores**; la media por producto es de 69,1, medida
  en PostgreSQL. Un nodo con muchas más relaciones que el resto se llama **supernodo**.
- **`[:COMPRO*4]` con `count(DISTINCT o)`** cuenta los clientes a exactamente dos productos de
  distancia: **43 251**, es decir, **todos** los demás clientes del grafo. Lo hizo en 213 ms, frente
  a los 5,0 s del plan de §4 para la misma pregunta.
- **El supernodo hace inútil la pregunta**: si todo el mundo está a dos productos de todo el mundo
  porque todos compraron el más vendido, «estar conectado» no dice nada.

**Cuánto cuesta** y qué se hace, que es **convención** de modelado: cada recorrido que pasa por un
supernodo arrastra sus miles de relaciones. Las salidas habituales son **excluirlo del recorrido**
—el más vendido no dice nada de los gustos de nadie—, **ponderar** por lo raro que es el producto, o
**limitar la profundidad**. En fraude pasa lo mismo con un teléfono de atención al cliente que
aparece en miles de cuentas: se excluye, o todo acaba conectado con todo.

> **Veredicto:** en un grafo real, unos pocos nodos concentran las relaciones. Hay que saber cuáles
> son antes de recorrer, o el recorrido mide el supernodo y no la pregunta.

---

## 6. 🧭 La ficha del modelo

| Punto | Grafo |
|---|---|
| **Qué resuelve mejor que SQL** | Recorridos de profundidad variable o desconocida —caminos, alcance, anillos— que siguen relaciones y paran al encontrar lo que buscan |
| **Dónde falla SQL, y por qué** | La CTE recursiva busca desde un solo extremo y enumera caminos, que crecen multiplicando en cada salto; solo para antes del tope si la consulta de fuera deja de pedir filas, y cuando no hay camino los recorre todos |
| **Producto principal y stack** | Neo4j, con Cypher y `cypher-shell`; drivers oficiales en Java, Python, JavaScript y Go; `bd-lab-neo4j`, `neo4j:5.26.31-community`, en `docker-compose.otros.yml` |
| **El caso** | Detección de anillos de fraude → abajo, con números |

**El caso, con números.** Un escenario, no una medida del entorno: la tienda cruza cada alta de
cliente con las cuentas bloqueadas por fraude, **a través de tarjetas, teléfonos y direcciones
compartidas, hasta seis saltos**, con 200 altas por minuto en campaña y una respuesta antes de
aceptar el primer pedido. **Por qué SQL falla ahí**: casi todas las cuentas nuevas son limpias, es
decir, **no hay camino**, que es el caso en que la CTE tardó 24,6 s con solo cuatro saltos. **Cómo
lo resuelve el modelo**: una búsqueda del camino más corto entre la cuenta nueva y el conjunto de
las bloqueadas, que para al encontrar el primero, como los 25 ms de §4. **Qué se paga a cambio**:
otra copia de los datos, que hay que mantener sincronizada con la base principal; los supernodos,
que hay que identificar y excluir; y un motor que en consultas de conjunto —sumas, agrupaciones
sobre todas las compras— no gana a PostgreSQL, como enseñó §3 con un recorrido fijo.

---

## 7. 📜 Estándar, motor y convención

> **📜 Estándar o motor.** Desde 2024 hay estándar para lenguajes de grafos: **GQL**, ISO/IEC
> 39075:2024, que Cypher cubre en la mayoría de sus funciones obligatorias según su documentación.
> El estándar SQL añadió en 2023 una parte para consultar grafos de propiedades dentro de SQL,
> SQL/PGQ, con la función `GRAPH_TABLE`; no he verificado la cláusula, y **PostgreSQL 18 no la
> implementa**: `SELECT * FROM GRAPH_TABLE (...)` da error de sintaxis.

| Afirmación | Categoría | PostgreSQL 18 | Neo4j 5 |
|---|---|---|---|
| Hay un lenguaje estándar para consultar grafos | Estándar | SQL/PGQ, no implementado | GQL, cubierto en su mayoría por Cypher |
| Los nodos tienen clave única por defecto | Motor | Sí, la clave primaria | No: hace falta una restricción |
| Recorrer una relación de profundidad fija es rápido | Motor | Sí: 143 ms con índices | Sí: 305 ms |
| El camino más corto para al encontrar el destino | Motor | Con `UNION ALL` y `LIMIT`, por evaluación perezosa: 75 ms | Sí, búsqueda desde los dos extremos: 25 ms |
| Sabe pronto que no hay camino | Motor | No: 24,6 s | Sí: 2 ms |
| El recorrido recuerda los nodos ya visitados | Motor | Solo por fila repetida, con `UNION` | Sí, en `shortestPath` |
| Los supernodos se excluyen del recorrido | Convención | — | — |

**Convención, la que más se repite.** *«Si los datos tienen relaciones, van en una base de grafos»*
— todos los datos relacionales tienen relaciones; por eso se llaman así. Lo que decide es la
**profundidad variable** del recorrido, no la existencia de relaciones.

---

## ⚠️ Errores frecuentes

| Se dice | Lo preciso |
|---|---|
| "Las bases de grafos son más rápidas con relaciones" | Con profundidad fija, PostgreSQL lo hizo en 143 ms y Neo4j en 305; ganan con profundidad variable |
| "Una CTE recursiva es un recorrido en anchura" | Enumera caminos hasta el límite: 25,9 millones de filas para 49 055 clientes |
| "La CTE recursiva no puede parar al encontrar el destino" | Con `UNION ALL` y `LIMIT 1` paró en 75 ms; es evaluación perezosa, que la documentación desaconseja como truco |
| "Neo4j impide nodos duplicados" | Solo con una restricción de unicidad; sin ella, `CREATE` duplica |
| "`MERGE` es como `INSERT`" | Busca el patrón y lo crea solo si no existe; sin índice, busca recorriendo |
| "Estar conectado en el grafo indica relación" | Con un supernodo, 43 251 de 43 252 clientes estaban a dos productos |
| "No hay estándar de grafos" | GQL es ISO/IEC 39075:2024, y SQL/PGQ es parte del estándar SQL |
| "PostgreSQL ya tiene SQL/PGQ" | PostgreSQL 18 rechaza `GRAPH_TABLE` con un error de sintaxis |

---

## 📚 Para profundizar

- **Documentación** — Neo4j, «What is a graph database?»: nodos, relaciones y por qué no hay `JOIN`.
  <https://neo4j.com/docs/getting-started/graph-database/>
- **Documentación** — Neo4j Cypher Manual 5, «Shortest paths»: la búsqueda desde los dos extremos.
  <https://neo4j.com/docs/cypher-manual/5/patterns/shortest-paths/>
- **Documentación** — Neo4j Cypher Manual 5, «LOAD CSV»: la carga y `CALL ... IN TRANSACTIONS`.
  <https://neo4j.com/docs/cypher-manual/5/clauses/load-csv/>
- **Documentación** — Neo4j Cypher Manual 5, «Constraints»: la unicidad que no viene por defecto.
  <https://neo4j.com/docs/cypher-manual/5/constraints/>
- **Documentación** — Neo4j Cypher Manual 5, «GQL conformance»: Cypher frente a ISO/IEC 39075:2024.
  <https://neo4j.com/docs/cypher-manual/5/appendix/gql-conformance/>
- **Documentación** — PostgreSQL 18, «WITH Queries»: la CTE recursiva y sus defensas.
  <https://www.postgresql.org/docs/18/queries-with.html>

---

## 🧠 Preguntas

1. ¿Qué es un nodo, una relación y una propiedad en Neo4j? 🟢
2. ¿Qué es un supernodo? 🟢
3. ¿Qué es GQL, y quién lo publica? 🟢
4. ¿Qué hace `MERGE`, y en qué se diferencia de `CREATE`? ¿Lo fija el estándar o es cosa del motor?
   🟡
5. ¿Por qué Neo4j necesita `CREATE CONSTRAINT` para evitar dos `CLI-00311`? ¿Lo fija el estándar o
   es cosa del motor? 🟡
6. Distingue un recorrido de profundidad fija de uno de profundidad variable, con un ejemplo de la
   tienda para cada uno. 🟡
7. ¿Qué hace `shortestPath` para tardar 25 ms, según su documentación? 🟡
8. ¿Qué es SQL/PGQ, y qué pasó al probar `GRAPH_TABLE` en PostgreSQL 18? 🟡
9. ¿Por qué la recomendación fue más rápida en PostgreSQL que en Neo4j? 🟠
10. ¿Por qué la CTE recursiva necesita `WHERE b.saltos < 2`, y qué pasa si el destino está más
    lejos? 🟠
11. En el plan de §4, ¿qué significan `actual rows=8644018.33 loops=3` y `49055` en el
    `Recursive Union`? 🟠
12. ¿Por qué `UNION` no evita que la CTE vuelva a visitar clientes? 🟠
13. ¿Por qué el supernodo `PRD-00017` hace que «estar a dos productos» no signifique nada, y qué
    harías con él? 🟠
14. ¿Cómo conseguiste que la CTE devolviera el camino y parara al encontrar el destino, y por qué
    su documentación no lo recomienda? 🟠
15. ¿Por qué Neo4j supo en 2 ms que no hay camino hasta `CLI-00007`, y la CTE tardó 24,6 s? 🟠
16. Diseña el grafo para detectar anillos de fraude en la tienda: nodos, relaciones, restricciones
    y qué supernodos esperas. 🔴
17. Diagnostica: una consulta de «clientes conectados» en Neo4j pasó de 50 ms a 20 s tras dar de
    alta el teléfono de atención al cliente como dato de contacto en todas las cuentas. 🔴
18. Defiende o refuta añadir Neo4j a la tienda solo para la recomendación de productos, con los
    números del capítulo. 🔴

---

**Anterior:** [`02`](02-columnar-y-wide-column.md) — columnar y *wide-column* · **Siguiente:**
[`04`](04-series-temporales.md) — series temporales · **Relacionado:**
[`02/05`](../02-sql/05-cte-y-recursion.md) — la CTE recursiva y sus dos defensas ·
[`l05`](../13-laboratorio/l05-los-otros-modelos.md) §4 — Neo4j en el lab, con diez clientes.
