# l05 — Los otros modelos

> Una sesión mínima con cada motor que no es PostgreSQL ni sus vecinos: **Cassandra**, que obliga a
> diseñar la tabla por la consulta; **Neo4j**, que recorre relaciones sin `JOIN`; **TimescaleDB**,
> que parte una tabla por tiempo sin que la consulta lo sepa; **pgvector y Qdrant**, que buscan por
> cercanía y dan las mismas distancias; y **OpenSearch**, que ordena por relevancia en vez de
> filtrar. Cada uno con los datos de la tienda, un error provocado y su teardown. **Opcional.**
> **Tiempo estimado:** 45 minutos. **Asume levantado:** el entorno de
> [`l00`](l00-el-entorno-y-los-datos.md). **Vigencia:** 24 de septiembre de 2026.

---

## Salto rápido

- [1. Qué vas a ver](#1--qué-vas-a-ver) · [2. De uno en uno](#2--paso-1--de-uno-en-uno) · [3.
  Cassandra](#3--paso-2--cassandra-la-tabla-por-la-consulta)
- [4. Neo4j](#4--paso-3--neo4j-la-relación-como-dato) · [5.
  TimescaleDB](#5--paso-4--timescaledb-la-tabla-partida-por-tiempo)
- [6. pgvector y Qdrant](#6--paso-5--pgvector-y-qdrant-la-cercanía) · [7.
  OpenSearch](#7--paso-6--opensearch-la-relevancia) · [Preguntas](#-preguntas)

---

## 1. 🎯 Qué vas a ver

Cada uno de estos motores resuelve mejor que SQL una forma concreta de pregunta, y paga por ello
algo que PostgreSQL da gratis. Cuándo conviene cada uno es del bloque 09, que lista el [README de la
raíz](../README.md). Aquí se toca cada uno lo justo para reconocerlo: cómo se le habla, qué error te
da cuando le hablas como a una base relacional, y qué deja al irse.

> **📝 Contexto.** Todo está corrido. Las versiones se fijaron el 24 de septiembre de 2026 en §4.5
> del documento de dominio, en el mismo lab que las estrena. **Los identificadores que aparecen,
> salvo los canónicos del corpus, salen de la salida real** de una consulta a la tienda. Cada motor
> se levantó solo y se paró antes del siguiente. **Longitud:** 450 líneas, por las cinco
> sesiones; lab normal que pasa el disparador de 400.

---

## 2. 🧱 Paso 1 — De uno en uno

Los cinco van en un `compose` aparte, porque juntos piden varios GB de memoria:

```bash
docker compose -f 13-laboratorio/entorno/docker-compose.otros.yml --profile otros up -d cassandra
docker compose -f 13-laboratorio/entorno/docker-compose.otros.yml --profile otros stop cassandra
```

- `-f …/docker-compose.otros.yml` es el fichero de estos motores; `--profile otros` activa sus
  servicios, que sin el perfil no arrancan. El último argumento elige uno: `cassandra`, `neo4j`,
  `timescale`, `opensearch` o `qdrant`.
- `stop` lo para al terminar su paso, sin borrar sus datos. El teardown entero está en §8.

| Servicio | Imagen | Hasta `healthy` |
|---|---|---|
| `bd-lab-cassandra` | `cassandra:5.0.9` | 64 s |
| `bd-lab-neo4j` | `neo4j:5.26.31-community` | 12 s |
| `bd-lab-timescale` | `timescale/timescaledb-ha:pg18.6-ts2.30.1` | 6 s |
| `bd-lab-opensearch` | `opensearchproject/opensearch:3.8.0` | 21 s |
| `bd-lab-qdrant` | `qdrant/qdrant:v1.19.1` | Segundos; no se midió |

---

## 3. 🩺 Paso 2 — Cassandra: la tabla por la consulta

**Qué es:** una base distribuida en la que **la tabla se diseña para una consulta**. La clave de
partición decide en qué nodo vive cada fila, y solo se puede preguntar por ella. Los datos, los tres
últimos pedidos de `CLI-00311`, salen de PostgreSQL:

```bash
psql -h 127.0.0.1 -U postgres -d tienda -At -F ' | ' -c "SELECT codigo, to_char(creado_en AT TIME ZONE 'UTC','YYYY-MM-DD HH24:MI:SS'), total FROM pedidos WHERE cliente_id = 311 ORDER BY creado_en DESC LIMIT 3"
```

```text
PED-418201 | 2025-09-02 21:36:23 | 4323.61
PED-991372 | 2025-08-25 11:38:12 | 10077.32
PED-352201 | 2025-07-07 11:33:41 | 2018.26
```

```bash
docker exec -it bd-lab-cassandra cqlsh
```

```text
cqlsh> CREATE KEYSPACE tienda WITH replication = {'class': 'SimpleStrategy', 'replication_factor': 1};
cqlsh> CREATE TABLE tienda.pedidos_por_cliente (cliente_id int, creado_en timestamp, codigo text, total decimal, PRIMARY KEY ((cliente_id), creado_en)) WITH CLUSTERING ORDER BY (creado_en DESC);
cqlsh> INSERT INTO tienda.pedidos_por_cliente (cliente_id, creado_en, codigo, total) VALUES (311, '2025-09-02 21:36:23+0000', 'PED-418201', 4323.61);
cqlsh> INSERT INTO tienda.pedidos_por_cliente (cliente_id, creado_en, codigo, total) VALUES (311, '2025-08-25 11:38:12+0000', 'PED-991372', 10077.32);
cqlsh> INSERT INTO tienda.pedidos_por_cliente (cliente_id, creado_en, codigo, total) VALUES (311, '2025-07-07 11:33:41+0000', 'PED-352201', 2018.26);
cqlsh> SELECT codigo, creado_en, total FROM tienda.pedidos_por_cliente WHERE cliente_id = 311 LIMIT 2;

 codigo     | creado_en                       | total
------------+---------------------------------+----------
 PED-418201 | 2025-09-02 21:36:23.000000+0000 |  4323.61
 PED-991372 | 2025-08-25 11:38:12.000000+0000 | 10077.32

(2 rows)
cqlsh> SELECT codigo FROM tienda.pedidos_por_cliente WHERE codigo = 'PED-991372';
InvalidRequest: Error from server: code=2200 [Invalid query] message="Cannot execute this query as it might involve data filtering and thus may have unpredictable performance. If you want to execute this query despite the performance unpredictability, use ALLOW FILTERING"
cqlsh> DROP KEYSPACE tienda;
```

- **`PRIMARY KEY ((cliente_id), creado_en)`**: `cliente_id` es la partición y `creado_en` ordena
  dentro de ella, descendente. «Los últimos pedidos de un cliente» es una lectura de una partición,
  ya ordenada. Es la consulta para la que se diseñó la tabla.
- **El error, a propósito**: buscar por `codigo` exige recorrer todas las particiones, y Cassandra
  se niega. `ALLOW FILTERING` lo permitiría y lo convertiría en un barrido del clúster. La
  corrección no es la bandera: es **otra tabla**, `pedidos_por_codigo`, con los mismos datos
  duplicados.
- **`replication_factor: 1`** porque hay un nodo; en producción, tres. `DROP KEYSPACE` es el
  teardown del paso.

---

## 4. 🩺 Paso 3 — Neo4j: la relación como dato

**Qué es:** una base de grafos. Los nodos y las relaciones se guardan como tales, y **recorrer una
relación no es un `JOIN`**: es seguir un puntero. Se cargan las compras de los diez clientes
`CLI-0031_`, anclados en `CLI-00311`, generando desde PostgreSQL una sentencia Cypher:

```bash
psql -h 127.0.0.1 -U postgres -d tienda -At -f grafo.sql > grafo.cypher
docker exec -i bd-lab-neo4j cypher-shell -u neo4j -p tienda_neo4j < grafo.cypher
```

- `grafo.sql`, que escribes en `codigo/`, agrega las unidades por cliente y producto y las escribe
  como un `UNWIND [ … ] AS f MERGE (c:Cliente …) MERGE (p:Producto …) MERGE (c)-[:COMPRO]->(p)`.
  `cypher-shell` ejecuta el fichero: 825 relaciones en 3,4 s.

```text
neo4j@neo4j> MATCH (c:Cliente) RETURN count(c) AS clientes;
+----------+
| clientes |
+----------+
| 10       |
+----------+

1 row
neo4j@neo4j> MATCH (yo:Cliente {codigo: 'CLI-00311'})-[:COMPRO]->(:Producto)<-[:COMPRO]-(otro:Cliente)-[:COMPRO]->(rec:Producto) WHERE NOT (yo)-[:COMPRO]->(rec) RETURN rec.codigo AS producto, count(DISTINCT otro) AS clientes_en_comun ORDER BY clientes_en_comun DESC, producto LIMIT 3;
+---------------------------------+
| producto    | clientes_en_comun |
+---------------------------------+
| "PRD-00004" | 5                 |
| "PRD-00032" | 5                 |
| "PRD-00045" | 5                 |
+---------------------------------+

3 rows
neo4j@neo4j> CREATE CONSTRAINT cliente_unico FOR (c:Cliente) REQUIRE c.codigo IS UNIQUE;
0 rows
Added 1 constraints
neo4j@neo4j> CREATE (:Cliente {codigo: 'CLI-00311'});
Node(81) already exists with label `Cliente` and property `codigo` = 'CLI-00311'
neo4j@neo4j> MATCH (n) DETACH DELETE n;
0 rows
Deleted 692 nodes, Deleted 825 relationships
neo4j@neo4j> DROP CONSTRAINT cliente_unico;
0 rows
Removed 1 constraints
```

- **La recomendación es un patrón que se dibuja**: yo compré algo, otros lo compraron, y ¿qué más
  compraron que yo no? En SQL son cuatro `JOIN` sobre `pedido_lineas` y un anti-join; aquí, una
  línea que se lee como la pregunta.
- **El error, a propósito**: con la restricción de unicidad, un segundo `CLI-00311` se rechaza. Sin
  ella, `CREATE` lo habría creado duplicado: Neo4j no tiene claves por defecto. Por eso la carga usa
  `MERGE`, que crea solo si no existe.
- **Se omiten arriba**, para leer las tablas, las líneas de tiempo que `cypher-shell` imprime tras
  cada consulta —`ready to start consuming query after … ms`— y el recuento de relaciones, que dio
  825. El teardown deja **0 nodos**.

---

## 5. 🩺 Paso 4 — TimescaleDB: la tabla partida por tiempo

**Qué es:** una extensión de PostgreSQL. Una **hipertabla** se parte sola en tramos por tiempo, y
las consultas no lo saben: se escribe SQL normal. Corre en `bd-lab-timescale`, un PostgreSQL 18.6 en
el puerto 5433.

```text
tienda=# CREATE TABLE eventos (id bigint PRIMARY KEY, ocurrido_en timestamptz NOT NULL, pedido_id bigint, tipo text);
CREATE TABLE
tienda=# SELECT create_hypertable('eventos', by_range('ocurrido_en', INTERVAL '1 day'));
ERROR:  cannot create a unique index without the column "ocurrido_en" (used in partitioning)
SUGERENCIA:  If you're creating a hypertable on a table with a primary key, ensure the partitioning column is part of the primary or composite key.
tienda=# DROP TABLE eventos;
DROP TABLE
tienda=# CREATE TABLE eventos (ocurrido_en timestamptz NOT NULL, pedido_id bigint, tipo text);
CREATE TABLE
tienda=# SELECT create_hypertable('eventos', by_range('ocurrido_en', INTERVAL '1 day'));
 create_hypertable
-------------------
 (2,t)
(1 fila)
```

- **El error, a propósito**: cada tramo es una tabla, y una clave única solo se puede comprobar
  dentro de cada una. Una clave que no incluye la columna de tiempo no se puede garantizar entre
  tramos, y TimescaleDB se niega. Es la misma regla que el particionado nativo de PostgreSQL.

Se copian los 106 735 eventos de septiembre de 2025 del PostgreSQL principal, con dos `psql` unidos
por una tubería —`\copy (…) TO STDOUT` en uno, `\copy eventos FROM STDIN` en el otro—, en 0,5 s:

```text
tienda=# SELECT extname, extversion FROM pg_extension WHERE extname IN ('timescaledb', 'vector');
   extname   | extversion
-------------+------------
 timescaledb | 2.30.1
(1 fila)

tienda=# SELECT count(*) AS tramos FROM show_chunks('eventos');
 tramos
--------
     27
(1 fila)

tienda=# SELECT time_bucket('1 week', ocurrido_en) AS semana, count(*) AS eventos FROM eventos GROUP BY semana ORDER BY semana;
         semana         | eventos
------------------------+---------
 2025-09-01 00:00:00+00 |   28323
 2025-09-08 00:00:00+00 |   28870
 2025-09-15 00:00:00+00 |   29117
 2025-09-22 00:00:00+00 |   20425
(4 filas)

tienda=# EXPLAIN (COSTS OFF) SELECT count(*) FROM eventos WHERE ocurrido_en >= '2025-09-25';
                   QUERY PLAN
-------------------------------------------------
 Finalize Aggregate
   ->  Append
         ->  Partial Aggregate
               ->  Seq Scan on _hyper_2_22_chunk
         ->  Partial Aggregate
               ->  Seq Scan on _hyper_2_23_chunk
         ->  Partial Aggregate
               ->  Seq Scan on _hyper_2_27_chunk
(8 filas)
```

- **27 tramos, uno por día**, creados solos al insertar. `time_bucket` es el `date_trunc` de
  TimescaleDB, con cualquier anchura.
- **El plan solo toca 3 de los 27**: los de los días 25, 26 y 27. Es la **exclusión de tramos**, y
  es lo que hace barata una consulta de «los últimos días» sobre años de datos. `vector` aún no
  aparece en `pg_extension`: está en la imagen, pero se activa en §6.

---

## 6. 🩺 Paso 5 — pgvector y Qdrant: la cercanía

**Qué es:** buscar **por parecido** en vez de por igualdad. Cada elemento es un vector —en la vida
real, cientos de números que produce un modelo; aquí, tres escritos a mano— y la pregunta es cuáles
están más cerca de uno dado. pgvector lo hace dentro de PostgreSQL, en el mismo `bd-lab-timescale`:

```text
tienda=# CREATE EXTENSION vector;
CREATE EXTENSION
tienda=# CREATE TABLE productos_vec (codigo text PRIMARY KEY, embedding vector(3));
CREATE TABLE
tienda=# INSERT INTO productos_vec VALUES ('PRD-00017', '[0.9, 0.1, 0.3]'), ('PRD-04980', '[0.1, 0.8, 0.5]');
INSERT 0 2
tienda=# UPDATE productos_vec SET embedding = '[0.5, 0.5]' WHERE codigo = 'PRD-04980';
ERROR:  expected 3 dimensions, not 2
tienda=# SELECT codigo, embedding <-> '[0.8, 0.2, 0.4]' AS distancia FROM productos_vec ORDER BY embedding <-> '[0.8, 0.2, 0.4]';
  codigo   |      distancia
-----------+---------------------
 PRD-00017 | 0.17320505731319497
 PRD-04980 |  0.9273618572623713
(2 filas)
```

Y lo mismo en Qdrant, un motor dedicado, por su API REST:

```bash
curl -s -X PUT localhost:6333/collections/productos -H 'Content-Type: application/json' \
  -d '{"vectors": {"size": 3, "distance": "Euclid"}}'
curl -s -X POST localhost:6333/collections/productos/points/query -H 'Content-Type: application/json' \
  -d '{"query": [0.8, 0.2, 0.4], "limit": 2, "with_payload": true}'
```

- `curl -X` elige el método; `-H` declara el cuerpo como JSON y `-d` lo envía. La colección se crea
  con su dimensión y su distancia —`Euclid`, la misma que `<->`—; los puntos se cargan con un `PUT`
  a `…/points?wait=true`, que espera a que queden escritos.

```text
{"result":true,"status":"ok","time":0.065696792}
{"result":{"operation_id":1,"status":"completed"},"status":"ok","time":0.01227775}
{"status":{"error":"Wrong input: Vector dimension error: expected dim: 3, got 2"},"time":0.00007275}
{"result":{"points":[{"id":17,"version":1,"score":0.17320506,"payload":{"codigo":"PRD-00017"}},{"id":4980,"version":1,"score":0.92736185,"payload":{"codigo":"PRD-04980"}}]},"status":"ok","time":0.01210575}
```

- **Las mismas distancias en los dos**: 0,1732 y 0,9274. El cálculo es el mismo; lo que cambia es
  dónde vive. En pgvector, junto al resto de los datos y en la misma transacción; en Qdrant, en un
  servicio aparte que hay que mantener sincronizado.
- **El error, a propósito, en los dos**: un vector de dos dimensiones en una columna o colección de
  tres. La dimensión se fija al crear y todos los vectores deben venir del mismo modelo.
- **Teardown**: `DROP TABLE productos_vec`, `DROP EXTENSION vector` y `DROP TABLE eventos` en
  PostgreSQL —queda con 0 tablas—, y `DELETE …/collections/productos` en Qdrant.

---

## 7. 🩺 Paso 6 — OpenSearch: la relevancia

**Qué es:** un motor de búsqueda. Guarda documentos JSON en un índice invertido y **ordena por
relevancia**: no dice si un documento cumple, dice cuánto. Se cargan los 5 000 productos con un
mapeo explícito y la API `_bulk`:

```bash
curl -s -X PUT localhost:9200/productos -H 'Content-Type: application/json' -d '{"mappings": {"properties": {"codigo": {"type": "keyword"}, "nombre": {"type": "text"}, "categoria": {"type": "keyword"}, "precio": {"type": "float"}, "activo": {"type": "boolean"}}}}'
curl -s -X POST 'localhost:9200/productos/_bulk?refresh=true&filter_path=took,errors' \
  -H 'Content-Type: application/x-ndjson' --data-binary @datos/productos.ndjson
```

- `keyword` guarda el valor entero, para filtrar y agrupar; `text` lo parte en palabras, para
  buscar. `productos.ndjson` sale de PostgreSQL, dos líneas por producto: la acción y el documento.
  `refresh=true` hace visibles los documentos al terminar, y `filter_path` recorta la respuesta.

```text
{"acknowledged":true,"shards_acknowledged":true,"index":"productos"}
{"took":344,"errors":false}
```

Una agregación por categoría, una búsqueda y el error, con su respuesta literal:

```bash
curl -s 'localhost:9200/productos/_search?size=0&filter_path=aggregations.por_categoria.buckets' -H 'Content-Type: application/json' -d '{"aggs": {"por_categoria": {"terms": {"field": "categoria"}}}}'
curl -s 'localhost:9200/productos/_search?size=3&filter_path=hits.total.value,hits.hits._id,hits.hits._score' -H 'Content-Type: application/json' -d '{"query": {"match": {"nombre": "PRODUCTO 17"}}}'
curl -s -X PUT 'localhost:9200/productos/_doc/PRD-00017' -H 'Content-Type: application/json' -d '{"codigo": "PRD-00017", "precio": "caro"}'
```

```text
{"aggregations":{"por_categoria":{"buckets":[{"key":"informatica","doc_count":839},{"key":"libros","doc_count":834},{"key":"video","doc_count":830},{"key":"juguetes","doc_count":824},{"key":"hogar","doc_count":763},{"key":"deporte","doc_count":467},{"key":"audio","doc_count":443}]}}}
{"hits":{"total":{"value":5000},"hits":[{"_id":"PRD-00017","_score":3.6872852},{"_id":"PRD-00001","_score":4.5447727E-5},{"_id":"PRD-00002","_score":4.5447727E-5}]}}
{"error":{"root_cause":[{"type":"mapper_parsing_exception","reason":"failed to parse field [precio] of type [float] in document with id 'PRD-00017'. Preview of field's value: 'caro'"}],"type":"mapper_parsing_exception","reason":"failed to parse field [precio] of type [float] in document with id 'PRD-00017'. Preview of field's value: 'caro'","caused_by":{"type":"number_format_exception","reason":"For input string: \"caro\""}},"status":400}
```

- **La agregación es el `GROUP BY categoria`**, y coincide con el de PostgreSQL: 839, 834, 830, 824,
  763, 467 y 443.
- **La búsqueda encontró los 5 000**, porque todos se llaman «Producto …», y los ordenó: `PRD-00017`
  con 3,69 y el resto con 0,00005. Un `WHERE nombre LIKE '%17%'` diría sí o no; aquí la pregunta es
  cuánto se parece. Y no distingue mayúsculas: el analizador pasa el texto a minúsculas al indexar y
  al buscar.
- **El error, a propósito**: el mapeo dice que `precio` es `float`, y `"caro"` no lo es. Sin mapeo
  explícito, OpenSearch deduce el tipo del primer documento, y un primer documento raro fija un tipo
  malo para siempre.
- **Teardown**: `curl -X DELETE localhost:9200/productos` responde `{"acknowledged":true}`, y el
  fichero `productos.ndjson` se borra.

---

## 8. 🧭 El teardown, entero

```bash
docker compose -f 13-laboratorio/entorno/docker-compose.otros.yml --profile otros down -v
```

- `down -v` borra los cinco contenedores, su red y **sus volúmenes**; el `compose` principal no se
  toca. Terminó con `Volume bd-lab-otros_qdrantdata Removed` y el resto de volúmenes.
- **Las imágenes quedan**: 7 GB entre las cinco. `docker image rm` con sus cinco etiquetas las
  borra.

---

## 9. 📜 Estándar, motor y convención

> **📜 Estándar o motor.** De los cinco, solo TimescaleDB y pgvector hablan SQL, porque son
> PostgreSQL. Cassandra tiene su CQL, Neo4j su Cypher —con un estándar propio de lenguaje de grafos,
> GQL, que no se ha verificado aquí—, y OpenSearch y Qdrant, APIs JSON.

| Motor | Qué hace mejor que SQL | Lo que paga | Qué pregunta falla |
|---|---|---|---|
| Cassandra | Escribir y leer por partición, repartido en muchos nodos | Una tabla por consulta, datos duplicados | Cualquiera que no nombre la partición |
| Neo4j | Recorrer relaciones de profundidad variable | Sin claves por defecto; los agregados masivos | Las de tabla: totales sobre millones de filas |
| TimescaleDB | Series temporales grandes, por tramos | Claves únicas atadas al tiempo | Las que no filtran por tiempo |
| pgvector y Qdrant | Buscar por parecido | Vectores que produce otro sistema; índices aproximados | Las de igualdad exacta |
| OpenSearch | Texto y relevancia | Otro sistema, casi en tiempo real | Las transaccionales |

**Convención, la que más se repite.** *«Para esto hace falta una base especializada»* — dos de los
cinco son PostgreSQL con una extensión. La pregunta previa es si la extensión basta.

---

## ⚠️ Errores frecuentes

| Se dice | Lo preciso |
|---|---|
| "`ALLOW FILTERING` arregla la consulta de Cassandra" | La convierte en un barrido de todo el clúster; la corrección es otra tabla |
| "En Neo4j los nodos tienen clave" | Solo si se declara una restricción; `CREATE` duplica sin avisar |
| "Una hipertabla admite cualquier clave primaria" | La clave tiene que incluir la columna de tiempo |
| "Qdrant calcula distinto que pgvector" | Con la misma distancia, las mismas cifras: 0,1732 y 0,9274 |
| "OpenSearch filtra como un `WHERE`" | Ordena por relevancia: encontró los 5 000 y puntuó cada uno |

---

## 🧪 Ejercicios

1. Crea en Cassandra la tabla `pedidos_por_codigo` y consulta el pedido que falló en §3. 🟢
2. En Neo4j, busca los clientes a dos saltos de `CLI-00311`: los que compraron algo que compró
   alguien que compró lo mismo que él. 🟡
3. En TimescaleDB, cambia el tramo a una semana y compara el número de tramos y el plan de §5. 🟡
4. Crea un índice HNSW en `productos_vec` con cien vectores de prueba y compara el plan con y sin
   él. 🟠
5. En OpenSearch, busca `"Producto 17"` como frase exacta con `match_phrase` y compara el total con
   el de `match`. 🟠
6. Para la tienda, elige cuál de los cinco motores añadirías primero y para qué consulta, con el
   coste de sincronizarlo desde PostgreSQL. 🔴
7. Levanta los cinco a la vez y mide la memoria de cada contenedor con `docker stats`. 🔥 *(fuera de
   conteo)*

---

## 📚 Para profundizar

- **Documentación** — Apache Cassandra 5.0, «Data Modeling».
  <https://cassandra.apache.org/doc/5.0/cassandra/developing/data-modeling/index.html>
- **Documentación** — Neo4j 5, «Cypher Manual».
  <https://neo4j.com/docs/cypher-manual/5/introduction/>
- **Documentación** — TimescaleDB, «Understand hypertables».
  <https://www.tigerdata.com/docs/learn/hypertables/understand-hypertables>
- **Código y documentación** — pgvector. <https://github.com/pgvector/pgvector>
- **Documentación** — Qdrant, «Search». <https://qdrant.tech/documentation/concepts/search/>
- **Documentación** — OpenSearch 3.8, «Mappings and field types».
  <https://docs.opensearch.org/3.8/field-types/>

---

## 🧠 Preguntas

1. ¿Qué es la clave de partición en Cassandra? 🟢
2. ¿Qué es una hipertabla de TimescaleDB? 🟢
3. ¿Qué mide el operador `<->` de pgvector? 🟢
4. ¿Qué diferencia hay entre un campo `keyword` y uno `text` en OpenSearch? 🟢
5. ¿Por qué Cassandra rechaza una consulta por una columna que no es la partición? 🟢
6. Distingue `CREATE` de `MERGE` en Cypher. 🟡
7. ¿Por qué una hipertabla no admite una clave primaria sin la columna de tiempo? 🟡
8. ¿Cuáles de los cinco motores hablan SQL y por qué? ¿Qué parte es estándar? 🟡
9. ¿Qué es la exclusión de tramos, y cómo se vio en el plan de §5? 🟠
10. ¿Por qué pgvector y Qdrant dieron las mismas distancias, y qué los distingue entonces? 🟠
11. ¿Por qué la búsqueda de OpenSearch devolvió 5 000 documentos, y en qué se diferencia de un
    `LIKE`? 🟠
12. ¿Qué pasa si no declaras el mapeo de un índice de OpenSearch? 🟠
13. ¿Por qué la recomendación de §4 es más natural en Cypher que en SQL? 🟠
14. Diagnostica: una tabla de Cassandra responde en milisegundos a la consulta de siempre y el
    equipo añade `ALLOW FILTERING` a una nueva que tarda minutos. Da la causa y la corrección. 🔴
15. Diseña cómo mantendrías sincronizado un índice de OpenSearch con la tabla `productos` de
    PostgreSQL, y qué pasa si la sincronización se retrasa. 🔴

---

**Anterior:** [`l04`](l04-redis-y-mongodb.md) — Redis y MongoDB · **Siguiente:**
[`06`](06-simulacion-de-entrevista.md) — la simulación de entrevista del bloque · **Relacionado:**
[`l01`](l01-explain-e-indices-medidos.md) — los planes de PostgreSQL con los que se comparan estos.
