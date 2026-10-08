# 06 — Vectorial y embeddings

> Qué es un embedding, qué es buscar por parecido y por qué casi todo índice vectorial devuelve
> resultados aproximados. Medido con pgvector y Qdrant: un modelo de embeddings que en español
> encuentra aspiradoras «sin cable» cuando se le piden auriculares; un índice HNSW que con vectores
> aleatorios recupera el 32,5 % de los vecinos reales y con los de la tienda el 100 %; y un filtro
> por categoría que devuelve 0 filas de las 10 pedidas. **Asume leído:**
> [`01`](01-mas-alla-de-las-tablas.md) y [`05`](05-busqueda-de-texto.md), la búsqueda por palabras.
> **Vigencia:** 27 de septiembre de 2026.

---

## Salto rápido

- [1. El problema](#1--el-problema) · [2. Embeddings y distancia](#2--embeddings-y-distancia)
- [3. KNN exacto frente a ANN](#3--knn-exacto-frente-a-ann) · [4. HNSW frente a
  IVFFlat](#4--hnsw-frente-a-ivfflat)
- [5. El filtro que vacía el resultado](#5--el-filtro-que-vacía-el-resultado) · [6. pgvector o
  Qdrant](#6-️-pgvector-o-qdrant)
- [7. La ficha del modelo](#7--la-ficha-del-modelo) · [8. Estándar, motor y
  convención](#8--estándar-motor-y-convención)
- [Errores frecuentes](#️-errores-frecuentes) · [Preguntas](#-preguntas)

---

## 1. 🎯 El problema

El buscador de [`05`](05-busqueda-de-texto.md) encuentra palabras: quien escribe «algo para escuchar
música sin cables» no encuentra ningún auricular, porque ninguna descripción dice «música» ni
«escuchar». La promesa de la búsqueda **semántica** es encontrar por significado: convertir cada
texto en un vector de números de modo que los textos que dicen lo mismo queden cerca, y buscar los
vectores más próximos a la pregunta. Es también lo que usa un asistente para recuperar los
documentos con los que contestar.

Dos preguntas deciden si funciona, y solo la segunda es de bases de datos: **¿el modelo pone cerca
lo que se parece?**, y **¿el motor encuentra los vectores cercanos rápido y sin perder ninguno?**

> **📝 Contexto.** Los vectores de §2 salen de las descripciones generadas de §4.8 del documento de
> dominio, con **Ollama 0.34.2 y `nomic-embed-text`**, 768 dimensiones, en el anfitrión y no en el
> `compose` —`codigo/embeddings.py`, 61 s para los 5 000—. Los de §3 y §4 son **aleatorios**, para
> medir el índice sin depender del modelo. pgvector 0.8.6 corre en `bd-lab-timescale`, que lo trae
> en la imagen, y Qdrant en `bd-lab-qdrant`, `qdrant/qdrant:v1.19.1` (§4.5 del dominio).
> **Longitud:** unas 530 líneas; capítulo denso, declarado en §4.6 de la guía de estilo: 214
> líneas de sesión.

---

## 2. 🧱 Embeddings y distancia

**Qué es:** un **embedding** es un vector —aquí, 768 números— que un modelo calcula para un texto.
El modelo se entrena para que textos de significado parecido den vectores cercanos. La cercanía se
mide con una **distancia**: la del coseno compara la dirección de los dos vectores, y es la habitual
para texto; la euclídea, la longitud del segmento que los une.

**Quién lo manda:** el vector, el **modelo**; guardarlo y buscarlo, el **motor**. pgvector añade a
PostgreSQL el tipo `vector(n)` y los operadores `<->` (euclídea) y `<=>` (coseno).

```text
tienda=# CREATE EXTENSION vector;
CREATE EXTENSION
tienda=# CREATE TABLE productos_vec (codigo text PRIMARY KEY, categoria text NOT NULL, descripcion text NOT NULL, embedding vector(768) NOT NULL);
CREATE TABLE
tienda=# CREATE TABLE consultas (texto text PRIMARY KEY, embedding vector(768) NOT NULL);
CREATE TABLE
tienda=# \copy productos_vec FROM 'datos/vectores/productos.csv' WITH (FORMAT csv)
COPY 5000
tienda=# \copy consultas FROM 'datos/vectores/consultas.csv' WITH (FORMAT csv)
COPY 3
tienda=# SELECT p.codigo, p.descripcion, round((p.embedding <=> c.embedding)::numeric, 4) AS distancia FROM productos_vec p, consultas c WHERE c.texto = 'algo para escuchar música sin cables' ORDER BY p.embedding <=> c.embedding LIMIT 5;
  codigo   |                        descripcion                        | distancia 
-----------+-----------------------------------------------------------+-----------
 PRD-01631 | aspiradora sin cable fácil de limpiar. Envío en 24 horas. |    0.3021
 PRD-01931 | aspiradora sin cable fácil de limpiar. Envío en 24 horas. |    0.3021
 PRD-01231 | aspiradora sin cable fácil de limpiar. Envío en 24 horas. |    0.3021
 PRD-00431 | aspiradora sin cable fácil de limpiar. Envío en 24 horas. |    0.3021
 PRD-02231 | aspiradora sin cable fácil de limpiar. Envío en 24 horas. |    0.3021
(5 filas)

tienda=# SELECT codigo, descripcion FROM productos_vec WHERE to_tsvector('spanish', descripcion) @@ plainto_tsquery('spanish', 'algo para escuchar música sin cables') LIMIT 5;
 codigo | descripcion 
--------+-------------
(0 filas)

tienda=# SELECT p.codigo, p.descripcion, round((p.embedding <=> c.embedding)::numeric, 4) AS distancia FROM productos_vec p, consultas c WHERE c.texto = 'hacer ejercicio en casa' ORDER BY p.embedding <=> c.embedding LIMIT 5;
  codigo   |                       descripcion                        | distancia 
-----------+----------------------------------------------------------+-----------
 PRD-02228 | sartén antiadherente de bajo consumo. Envío en 24 horas. |    0.3847
 PRD-01928 | sartén antiadherente de bajo consumo. Envío en 24 horas. |    0.3847
 PRD-01428 | sartén antiadherente de bajo consumo. Envío en 24 horas. |    0.3847
 PRD-02028 | sartén antiadherente de bajo consumo. Envío en 24 horas. |    0.3847
 PRD-02328 | sartén antiadherente de bajo consumo. Envío en 24 horas. |    0.3847
(5 filas)
```

- **`vector(768)`** fija la dimensión: todos los vectores de la columna salen del mismo modelo. En
  `l05` §6 se provocó el error de meter uno de otra dimensión.
- **`<=>`** es la distancia del coseno: 0 es la misma dirección, 1 ninguna relación. `consultas`
  guarda los vectores de tres preguntas, calculados con el mismo modelo.
- **La búsqueda por palabras no encuentra nada**, como se esperaba. **La semántica encuentra
  aspiradoras «sin cable»** para la música y **sartenes** para el ejercicio.
- **El fallo es del modelo, no de la base.** `nomic-embed-text` está entrenado sobre todo con texto
  en inglés, y en español apenas separa significados: lo que acerca la aspiradora a la pregunta es
  compartir «sin cable». Medido aparte, la distancia de la pregunta a los auriculares inalámbricos
  es 0,468, peor que a la aspiradora, 0,302. Un modelo multilingüe lo haría mejor; no está en el
  entorno y no se ha medido.
- **Y los cinco primeros son el mismo texto**: descripciones idénticas dan vectores idénticos.
  Quitar repetidos o diversificar el resultado es trabajo de la aplicación.

> **Veredicto:** la base de datos guarda y compara vectores; si «parecido» significa algo, lo decide
> el modelo. Antes de elegir motor, se evalúa el modelo con preguntas reales.

---

## 3. 🧱 KNN exacto frente a ANN

**Qué es:** buscar los *k* vecinos más cercanos —**KNN**— de forma exacta obliga a calcular la
distancia a **todos** los vectores. Un índice vectorial hace **ANN**, búsqueda aproximada: mira solo
una parte y acepta perderse algún vecino a cambio de velocidad. El README de pgvector lo dice: sin
índice, la búsqueda es exacta y el *recall* perfecto; con índice, se cambia *recall* por velocidad,
y los resultados **cambian** al crear el índice.

**El *recall*** es la fracción de los vecinos reales que la búsqueda aproximada devuelve. Para
medirlo se necesita la respuesta exacta. Con 100 000 vectores aleatorios de 128 dimensiones y 20
consultas, en la misma base:

```text
tienda=# SELECT setseed(0.42);
 setseed 
---------
 
(1 fila)

tienda=# \timing on
El despliegue de duración está activado.
tienda=# CREATE TABLE azar AS SELECT i AS id, (SELECT array_agg(random()) FROM generate_series(1, 128) WHERE i > 0)::vector(128) AS v FROM generate_series(1, 100000) AS i;
SELECT 100000
Duración: 792,649 ms
tienda=# CREATE TABLE consultas_azar AS SELECT i AS id, (SELECT array_agg(random()) FROM generate_series(1, 128) WHERE i > 0)::vector(128) AS v FROM generate_series(1, 20) AS i;
SELECT 20
Duración: 1,740 ms
tienda=# CREATE TABLE verdad AS SELECT c.id AS consulta, a.id FROM consultas_azar c CROSS JOIN LATERAL (SELECT id FROM azar ORDER BY v <-> c.v LIMIT 10) AS a;
SELECT 200
Duración: 277,958 ms
tienda=# CREATE INDEX azar_hnsw ON azar USING hnsw (v vector_l2_ops);
ERROR:  could not resize shared memory segment "/PostgreSQL.2546254292" to 1036863424 bytes: No space left on device
Duración: 3,054 ms
tienda=# \timing off
El despliegue de duración está desactivado.
tienda=# SELECT pg_size_pretty(pg_relation_size('azar')) AS tabla, pg_size_pretty(pg_relation_size('azar_hnsw')) AS hnsw;
ERROR:  relation "azar_hnsw" does not exist
LÍNEA 1: ...azar')) AS tabla, pg_size_pretty(pg_relation_size('azar_hnsw...
                                                              ^
tienda=# \timing on
El despliegue de duración está activado.
tienda=# SELECT round(avg(aciertos) / 10, 3) AS recall FROM (SELECT c.id, count(*) FILTER (WHERE EXISTS (SELECT 1 FROM verdad t WHERE t.consulta = c.id AND t.id = a.id)) AS aciertos FROM consultas_azar c CROSS JOIN LATERAL (SELECT id FROM azar ORDER BY v <-> c.v LIMIT 10) AS a GROUP BY c.id) x;
 recall 
--------
  1.000
(1 fila)

Duración: 271,196 ms
```

- **`setseed`** fija la semilla de `random()`, para que los vectores salgan iguales cada vez; el
  `WHERE i > 0` obliga a calcular un array distinto por fila.
- **`verdad`** guarda los 10 vecinos exactos de cada consulta: 278 ms para 20 recorridos completos.
- **El índice falló**: la construcción en paralelo pide 1 036 863 424 bytes de memoria compartida, y
  el contenedor tiene 64 MB en `/dev/shm`, el valor por defecto de Docker. Es un error del entorno,
  no de pgvector, y aparece en cuanto el índice crece.
- **Sin índice, la consulta de *recall* es exacta**: 1,000 en 271 ms. Es la referencia.

La corrección, construir en serie, y el índice aproximado midiéndose contra `verdad`:

```text
tienda=# SET max_parallel_maintenance_workers = 0;
SET
tienda=# \timing on
El despliegue de duración está activado.
tienda=# CREATE INDEX azar_hnsw ON azar USING hnsw (v vector_l2_ops);
CREATE INDEX
Duración: 40827,514 ms (00:40,828)
tienda=# \timing off
El despliegue de duración está desactivado.
tienda=# SELECT pg_size_pretty(pg_relation_size('azar')) AS tabla, pg_size_pretty(pg_relation_size('azar_hnsw')) AS hnsw;
 tabla | hnsw  
-------+-------
 56 MB | 79 MB
(1 fila)

tienda=# EXPLAIN (ANALYZE, COSTS OFF, SUMMARY OFF) SELECT id FROM azar ORDER BY v <-> (SELECT v FROM consultas_azar WHERE id = 1) LIMIT 10;
                                       QUERY PLAN                                       
----------------------------------------------------------------------------------------
 Limit (actual time=1.407..1.421 rows=10.00 loops=1)
   Buffers: shared hit=1418
   InitPlan 1
     ->  Seq Scan on consultas_azar (actual time=0.009..0.010 rows=1.00 loops=1)
           Filter: (id = 1)
           Rows Removed by Filter: 19
           Buffers: shared hit=2
   ->  Index Scan using azar_hnsw on azar (actual time=1.406..1.419 rows=10.00 loops=1)
         Order By: (v <-> (InitPlan 1).col1)
         Index Searches: 1
         Buffers: shared hit=1418
 Planning:
   Buffers: shared hit=125 dirtied=2
(13 filas)

tienda=# \timing on
El despliegue de duración está activado.
tienda=# SELECT round(avg(aciertos) / 10, 3) AS recall FROM (SELECT c.id, count(*) FILTER (WHERE EXISTS (SELECT 1 FROM verdad t WHERE t.consulta = c.id AND t.id = a.id)) AS aciertos FROM consultas_azar c CROSS JOIN LATERAL (SELECT id FROM azar ORDER BY v <-> c.v LIMIT 10) AS a GROUP BY c.id) x;
 recall 
--------
  0.325
(1 fila)

Duración: 19,966 ms
tienda=# SET hnsw.ef_search = 200;
SET
Duración: 0,430 ms
tienda=# SELECT round(avg(aciertos) / 10, 3) AS recall FROM (SELECT c.id, count(*) FILTER (WHERE EXISTS (SELECT 1 FROM verdad t WHERE t.consulta = c.id AND t.id = a.id)) AS aciertos FROM consultas_azar c CROSS JOIN LATERAL (SELECT id FROM azar ORDER BY v <-> c.v LIMIT 10) AS a GROUP BY c.id) x;
 recall 
--------
  0.665
(1 fila)

Duración: 75,108 ms
```

- **`max_parallel_maintenance_workers = 0`** construye el índice en el proceso de la sesión, sin
  memoria compartida. Tardó **41 s** y ocupa **79 MB**, más que la tabla. La otra salida es dar al
  contenedor más `/dev/shm`.
- **El plan usa `Index Scan using azar_hnsw`** con `Order By`: 1,4 ms por consulta.
- **Con el índice, *recall* 0,325 en 20 ms**: trece veces más rápido y **dos de cada tres vecinos
  reales perdidos**. Con `hnsw.ef_search = 200` —cuántos candidatos explora; 40 por defecto—, 0,665
  en 75 ms.
- **Los vectores aleatorios son el peor caso**: en 128 dimensiones uniformes todos los puntos están
  casi a la misma distancia, y ningún índice aproximado lo hace bien. Los embeddings reales tienen
  estructura, y §4 lo mide.

> **Veredicto:** un índice vectorial no es un B-tree: cambia exactitud por velocidad, y la cuenta se
> mide con *recall*, no se supone.

---

## 4. 🧱 HNSW frente a IVFFlat

**Qué son:** **HNSW** construye un grafo de varias capas en el que cada vector enlaza con sus
vecinos, y la búsqueda baja por él acercándose a la pregunta. **IVFFlat** reparte los vectores en
**listas** alrededor de centros calculados al crear el índice, y busca solo en las listas más
cercanas. El README de pgvector los compara así: HNSW responde mejor para el mismo *recall*, pero se
construye más despacio y usa más memoria; IVFFlat se construye rápido y necesita datos para calcular
sus centros.

```text
tienda=# CREATE TABLE verdad_real AS SELECT q.codigo AS consulta, p.codigo FROM (SELECT codigo, embedding FROM productos_vec ORDER BY codigo LIMIT 20) AS q CROSS JOIN LATERAL (SELECT codigo FROM productos_vec ORDER BY embedding <=> q.embedding LIMIT 10) AS p;
SELECT 200
tienda=# SET max_parallel_maintenance_workers = 0;
SET
tienda=# \timing on
El despliegue de duración está activado.
tienda=# CREATE INDEX productos_vec_hnsw ON productos_vec USING hnsw (embedding vector_cosine_ops);
CREATE INDEX
Duración: 818,255 ms
tienda=# \timing off
El despliegue de duración está desactivado.
tienda=# SELECT round(avg(aciertos) / 10, 3) AS recall FROM (SELECT q.codigo, count(*) FILTER (WHERE EXISTS (SELECT 1 FROM verdad_real t WHERE t.consulta = q.codigo AND t.codigo = p.codigo)) AS aciertos FROM (SELECT codigo, embedding FROM productos_vec ORDER BY codigo LIMIT 20) AS q CROSS JOIN LATERAL (SELECT codigo FROM productos_vec ORDER BY embedding <=> q.embedding LIMIT 10) AS p GROUP BY q.codigo) x;
 recall 
--------
  0.885
(1 fila)

tienda=# DROP INDEX azar_hnsw;
DROP INDEX
tienda=# \timing on
El despliegue de duración está activado.
tienda=# CREATE INDEX azar_ivf ON azar USING ivfflat (v vector_l2_ops) WITH (lists = 100);
CREATE INDEX
Duración: 790,331 ms
tienda=# \timing off
El despliegue de duración está desactivado.
tienda=# SELECT pg_size_pretty(pg_relation_size('azar_ivf')) AS ivfflat;
 ivfflat 
---------
 53 MB
(1 fila)

tienda=# \timing on
El despliegue de duración está activado.
tienda=# SELECT round(avg(aciertos) / 10, 3) AS recall FROM (SELECT c.id, count(*) FILTER (WHERE EXISTS (SELECT 1 FROM verdad t WHERE t.consulta = c.id AND t.id = a.id)) AS aciertos FROM consultas_azar c CROSS JOIN LATERAL (SELECT id FROM azar ORDER BY v <-> c.v LIMIT 10) AS a GROUP BY c.id) x;
 recall 
--------
  0.080
(1 fila)

Duración: 5,537 ms
tienda=# SET ivfflat.probes = 10;
SET
Duración: 0,409 ms
tienda=# SELECT round(avg(aciertos) / 10, 3) AS recall FROM (SELECT c.id, count(*) FILTER (WHERE EXISTS (SELECT 1 FROM verdad t WHERE t.consulta = c.id AND t.id = a.id)) AS aciertos FROM consultas_azar c CROSS JOIN LATERAL (SELECT id FROM azar ORDER BY v <-> c.v LIMIT 10) AS a GROUP BY c.id) x;
 recall 
--------
  0.355
(1 fila)

Duración: 45,039 ms
```

- **Con los embeddings reales, *recall* 0,885**, y parece un 11,5 % de fallos. No lo es: hay
  descripciones idénticas, y entre vecinos a la misma distancia el índice elige otros códigos. Se
  comprueba en §5 comparando distancias en vez de códigos.
- **IVFFlat se construyó en 0,8 s frente a los 41 del HNSW**, y ocupa 53 MB frente a 79. Con cien
  listas, el valor que el README propone para empezar —filas entre mil—, y buscando solo en la más
  cercana, que es lo de defecto: *recall* 0,080. Con `ivfflat.probes = 10`, 0,355 en 45 ms: peor que
  el HNSW con `ef_search = 200`, 0,665 en 75 ms, como avisa el README.

> **Veredicto:** HNSW para consultar, IVFFlat si el índice se reconstruye a menudo. En los dos, el
> parámetro de búsqueda —`ef_search` o `probes`— es el mando entre velocidad y *recall*.

---

## 5. 🩺 El filtro que vacía el resultado

Dos comprobaciones sobre `productos_vec` con su índice HNSW. La primera, que el 0,885 son empates;
la segunda, lo que pasa al añadir un `WHERE`:

```text
tienda=# SET enable_indexscan = off;
SET
tienda=# CREATE TEMP TABLE exacto AS SELECT q.codigo AS consulta, p.embedding <=> q.embedding AS d, row_number() OVER (PARTITION BY q.codigo ORDER BY p.embedding <=> q.embedding) AS n FROM (SELECT codigo, embedding FROM productos_vec ORDER BY codigo LIMIT 20) AS q CROSS JOIN LATERAL (SELECT embedding FROM productos_vec ORDER BY embedding <=> q.embedding LIMIT 10) AS p;
SELECT 200
tienda=# RESET enable_indexscan;
RESET
tienda=# CREATE TEMP TABLE aprox AS SELECT q.codigo AS consulta, p.embedding <=> q.embedding AS d, row_number() OVER (PARTITION BY q.codigo ORDER BY p.embedding <=> q.embedding) AS n FROM (SELECT codigo, embedding FROM productos_vec ORDER BY codigo LIMIT 20) AS q CROSS JOIN LATERAL (SELECT embedding FROM productos_vec ORDER BY embedding <=> q.embedding LIMIT 10) AS p;
SELECT 200
tienda=# SELECT count(*) FILTER (WHERE e.d = a.d) AS misma_distancia, count(*) AS posiciones FROM exacto e JOIN aprox a USING (consulta, n);
 misma_distancia | posiciones 
-----------------+------------
             200 |        200
(1 fila)
```

- **`enable_indexscan = off`** impide usar el índice, así que `exacto` es la búsqueda exacta; sin
  él, `aprox` usa el HNSW. **Las 200 posiciones coinciden en distancia**: el índice encontró siempre
  un vecino igual de cercano. Con datos con estructura, el *recall* real fue 1.

Y en la misma sesión, el filtro por categoría: diez productos de «deporte» parecidos a la pregunta
de la música.

```text
tienda=# SELECT count(*) FROM productos_vec WHERE categoria = 'deporte';
 count 
-------
   467
(1 fila)

tienda=# SELECT count(*) AS devueltas FROM (SELECT p.codigo FROM productos_vec p WHERE p.categoria = 'deporte' ORDER BY p.embedding <=> (SELECT embedding FROM consultas WHERE texto = 'algo para escuchar música sin cables') LIMIT 10) AS x;
 devueltas 
-----------
         0
(1 fila)

tienda=# SET hnsw.iterative_scan = strict_order;
SET
tienda=# SELECT count(*) AS devueltas FROM (SELECT p.codigo FROM productos_vec p WHERE p.categoria = 'deporte' ORDER BY p.embedding <=> (SELECT embedding FROM consultas WHERE texto = 'algo para escuchar música sin cables') LIMIT 10) AS x;
 devueltas 
-----------
        10
(1 fila)
```

- **Cero filas de diez, con 467 productos que cumplen el filtro.** El README lo explica: con un
  índice aproximado, el `WHERE` se aplica **después** de recorrer el índice, y el HNSW solo trae
  `ef_search` candidatos, 40. Ninguno de los 40 más cercanos a la pregunta era de deporte.
- **`hnsw.iterative_scan = strict_order`**, desde pgvector 0.8.0, sigue recorriendo el índice hasta
  reunir las filas pedidas, y devuelve 10. Se paga en tiempo, y tiene un tope configurable.
- **Sin error y sin aviso**: la consulta devuelve menos filas de las pedidas y nada lo señala.

> **⚠️ Advertencia.** Toda búsqueda vectorial con filtro —por categoría, por cliente, por permisos—
> se prueba con filtros poco frecuentes. Un resultado vacío que debería tener diez filas es el fallo
> más silencioso de este capítulo.

---

## 6. ⚖️ pgvector o Qdrant

Qdrant es un motor vectorial dedicado. Los mismos 5 000 vectores, en una colección con distancia
del coseno:

```bash
curl -s -X PUT localhost:6333/collections/productos -H 'Content-Type: application/json' -d '{"vectors": {"size": 768, "distance": "Cosine"}}'
python3 codigo/qdrant_carga.py
curl -s -X POST localhost:6333/collections/productos/points/query -H 'Content-Type: application/json' -d @datos/vectores/consulta-cables.json
curl -s -X POST localhost:6333/collections/productos/points/query -H 'Content-Type: application/json' -d @datos/vectores/consulta-cables-exacta.json
curl -s localhost:6333/collections/productos | python3 -c "import json,sys; r=json.load(sys.stdin)['result']; print(r['status'], r['points_count'], r['indexed_vectors_count'], r['config']['hnsw_config'], r['config']['optimizer_config']['indexing_threshold'])"
```

```text
{"result":true,"status":"ok","time":0.052109}
5000 puntos, ok
{"result":{"points":[{"id":431,"version":1,"score":0.69789314,"payload":{"codigo":"PRD-00431","descripcion":"aspiradora sin cable fácil de limpiar. Envío en 24 horas."}},{"id":1231,"version":3,"score":0.69789314,"payload":{"codigo":"PRD-01231","descripcion":"aspiradora sin cable fácil de limpiar. Envío en 24 horas."}},{"id":1931,"version":4,"score":0.69789314,"payload":{"codigo":"PRD-01931","descripcion":"aspiradora sin cable fácil de limpiar. Envío en 24 horas."}}]},"status":"ok","time":0.00273075}
{"result":{"points":[{"id":431,"version":1,"score":0.69789314,"payload":{"codigo":"PRD-00431","descripcion":"aspiradora sin cable fácil de limpiar. Envío en 24 horas."}},{"id":1231,"version":3,"score":0.69789314,"payload":{"codigo":"PRD-01231","descripcion":"aspiradora sin cable fácil de limpiar. Envío en 24 horas."}},{"id":1931,"version":4,"score":0.69789314,"payload":{"codigo":"PRD-01931","descripcion":"aspiradora sin cable fácil de limpiar. Envío en 24 horas."}}]},"status":"ok","time":0.001597833}
green 5000 0 {'m': 16, 'ef_construct': 100, 'full_scan_threshold': 10000, 'max_indexing_threads': 0, 'on_disk': False} 10000
```

- **`qdrant_carga.py`** manda los puntos en lotes de 500 con `PUT .../points?wait=true`: el
  identificador es el número del código, y la carga útil, `codigo`, `categoria` y `descripcion`.
  `consulta-cables.json` lleva el vector de la pregunta, `limit` 3 y los campos que devolver; la
  versión `-exacta` añade `"params": {"exact": true}`. El último `python3` resume la colección.
- **La misma respuesta que pgvector**: Qdrant da similitud, no distancia, y 0,6979 es 1 − 0,3021.
  El modelo es el mismo, y el fallo también.
- **Con 5 000 puntos, Qdrant no ha construido índice**: `indexed_vectors_count` es 0, y la consulta
  exacta devolvió lo mismo. Su
  documentación fija un umbral, `indexing_threshold`, 10 000 KB por defecto, por debajo del cual un
  segmento se recorre entero.

**Lo que decide**, más allá de la sesión: pgvector deja el vector **junto al resto de los datos**,
en la misma transacción, con SQL y con las copias de seguridad de PostgreSQL. Qdrant es otro
servicio y otra copia que sincronizar, y a cambio trae lo que un motor dedicado optimiza: su
documentación describe un HNSW que tiene en cuenta los filtros si los índices de la carga útil se
crean antes de cargar, justo el problema de §5.

> **Veredicto:** pgvector es la respuesta pragmática mientras quepa en PostgreSQL; un motor dedicado
> se justifica por volumen, por filtros complejos a gran escala o por latencias que PostgreSQL no
> da, medido.

---

## 7. 🧭 La ficha del modelo

| Punto | Vectorial |
|---|---|
| **Qué resuelve mejor que SQL** | Encontrar los elementos más parecidos a uno dado, por la distancia entre sus embeddings |
| **Dónde falla SQL, y por qué** | No hay orden de B-tree para «parecido»: sin índice vectorial, cada búsqueda calcula la distancia a todos los vectores, 271 ms para 20 consultas sobre 100 000 |
| **Producto principal y stack** | pgvector en PostgreSQL, con SQL y los drivers de siempre; Qdrant como motor dedicado, con API REST; `bd-lab-timescale` y `bd-lab-qdrant` |
| **El caso** | Recuperación para un asistente → abajo, con números |

**El caso, con números.** Un escenario, no una medida del entorno: el asistente de atención al
cliente contesta con los fragmentos más parecidos de **200 000 fragmentos** de documentación, con
filtro por idioma y producto, y 50 preguntas por segundo. **Por qué SQL falla ahí**: sin índice,
cada pregunta recorre los 200 000 vectores; con `LIKE` o texto completo, «mi pedido no llega» no
encuentra «plazos de entrega». **Cómo lo resuelve el modelo**: embeddings de un modelo evaluado en
el idioma, índice HNSW con `ef_search` ajustado midiendo *recall*, y búsqueda iterativa por los
filtros. **Qué se paga a cambio**: resultados aproximados; un índice más grande que la tabla y lento
de construir; recalcular todos los vectores si cambia el modelo; y un filtro que puede vaciar el
resultado sin avisar.

**Milvus**, el otro motor del temario, es de la misma familia que Qdrant: un servicio vectorial
dedicado. No está en el entorno, y lo que diferencia a los dos no se ha medido aquí.

---

## 8. 📜 Estándar, motor y convención

> **📜 Estándar o motor.** No hay estándar de tipos ni de índices vectoriales en SQL. `vector`,
> `<=>`, HNSW e IVFFlat son de pgvector; la distancia del coseno es matemática, y el modelo que da
> el vector es otra pieza, con sus propias limitaciones.

| Afirmación | Categoría | pgvector 0.8.6 | Qdrant 1.19 |
|---|---|---|---|
| Sin índice, la búsqueda es exacta | Motor | Sí: *recall* 1 en 271 ms | Sí, por debajo de `indexing_threshold` |
| Con índice, la búsqueda es aproximada | Motor | Sí: 0,325 con vectores aleatorios | Sí, HNSW |
| El filtro se aplica después del índice | Motor | Sí, salvo búsqueda iterativa: 0 de 10 | Tiene HNSW con filtros, según su documentación |
| El vector y los datos, en una transacción | Motor | Sí | No: otro servicio |
| La calidad de «parecido» la decide el modelo | Convención | — | — |
| Quitar resultados repetidos | Convención | — | — |

**Convención, la que más se repite.** *«Para IA hace falta una base vectorial»* — hace falta un
modelo que entienda el idioma, que aquí faltó, y un índice con *recall* medido, que PostgreSQL da
con pgvector. La base dedicada es la última decisión, no la primera.

---

## ⚠️ Errores frecuentes

| Se dice | Lo preciso |
|---|---|
| "La búsqueda semántica entiende el significado" | Lo entiende el modelo si sabe el idioma: `nomic-embed-text` devolvió aspiradoras para la música |
| "Un índice vectorial acelera sin cambiar el resultado" | Cambia el resultado: *recall* 0,325 con vectores aleatorios y los parámetros de defecto |
| "Un *recall* de 0,885 es un 11,5 % de fallos" | Eran empates: las 200 posiciones tenían la misma distancia |
| "`WHERE categoria = ...` devuelve lo que pides" | Devolvió 0 de 10 con 467 candidatos, hasta activar la búsqueda iterativa |
| "HNSW es siempre mejor que IVFFlat" | Mejor *recall* por tiempo, pero 41 s de construcción frente a 0,8 |
| "Crear el índice no puede fallar" | En Docker falló por los 64 MB de `/dev/shm` en la construcción paralela |
| "Qdrant es más exacto que pgvector" | Con los mismos vectores devolvió los mismos productos: 0,6979 = 1 − 0,3021 |

---

## 📚 Para profundizar

- **Documentación** — pgvector 0.8.6, README: exacto y aproximado, HNSW, IVFFlat y la búsqueda
  iterativa. <https://github.com/pgvector/pgvector/blob/v0.8.6/README.md>
- **Documentación** — Qdrant, «Indexing»: índices de vectores y de carga útil, y el HNSW con
  filtros. <https://qdrant.tech/documentation/manage-data/indexing/>
- **Documentación** — Qdrant, «Optimizer»: `indexing_threshold` y cuándo se construye el índice.
  <https://qdrant.tech/documentation/ops-optimization/optimizer/>
- **Documentación** — Qdrant, «Search»: la consulta y el parámetro `exact`.
  <https://qdrant.tech/documentation/search/search/>
- **Documentación** — Qdrant, «Filtering». <https://qdrant.tech/documentation/search/filtering/>

---

## 🧠 Preguntas

1. ¿Qué es un embedding? 🟢
2. ¿Qué mide la distancia del coseno, y qué operador la calcula en pgvector? 🟢
3. ¿Qué es el *recall* de una búsqueda aproximada? 🟢
4. Distingue KNN de ANN. ¿Lo fija el estándar o es cosa del motor? 🟡
5. Distingue HNSW de IVFFlat: cómo buscan y qué cuesta cada uno. 🟡
6. ¿Qué hacen `hnsw.ef_search` e `ivfflat.probes`, y cuál es su valor por defecto? 🟡
7. ¿Por qué `vector(768)` fija la dimensión, y qué implica cambiar de modelo? 🟡
8. ¿Por qué la búsqueda semántica devolvió aspiradoras para «algo para escuchar música sin
   cables»? 🟠
9. ¿Por qué falló la creación del índice HNSW sobre `azar`, y cómo se corrigió? 🟠
10. ¿Por qué el HNSW tuvo *recall* 0,325 con vectores aleatorios y efectivamente 1 con los de la
    tienda? 🟠
11. ¿Cómo se comprobó que el 0,885 eran empates y no fallos? 🟠
12. ¿Por qué el filtro por «deporte» devolvió 0 filas de 10, y qué lo corrige? ¿Lo fija el estándar
    o es cosa del motor? 🟠
13. ¿Por qué Qdrant no había construido índice con 5 000 puntos? 🟠
14. ¿Qué gana y qué pierde la tienda con Qdrant frente a pgvector? 🟠
15. Diseña la búsqueda semántica del catálogo: modelo, tabla, índice, parámetros y cómo medirías que
    funciona antes de publicarla. 🔴
16. Diagnostica: tras añadir un filtro por idioma, el asistente contesta «no he encontrado nada»
    para preguntas en portugués, aunque hay miles de fragmentos en ese idioma. 🔴
17. Defiende o refuta montar Qdrant para la tienda en vez de pgvector, con los números del capítulo.
    🔴

---

**Anterior:** [`05`](05-busqueda-de-texto.md) — búsqueda de texto · **Siguiente:**
[`07`](07-simulacion-de-entrevista.md) — la simulación del bloque · **Relacionado:**
[`l05`](../13-laboratorio/l05-los-otros-modelos.md) §6 — pgvector y Qdrant con tres dimensiones.
