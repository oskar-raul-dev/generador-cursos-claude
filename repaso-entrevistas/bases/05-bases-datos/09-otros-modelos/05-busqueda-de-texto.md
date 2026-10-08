# 05 — Búsqueda de texto

> Por qué `LIKE '%cámara%'` es la búsqueda que peor envejece en cualquier aplicación, y qué hace un
> motor de búsqueda en su lugar: analizar el texto, guardar un índice invertido y ordenar por
> relevancia. Medido con las descripciones de los 5 000 productos en PostgreSQL y en OpenSearch:
> `LIKE` sin tilde encuentra 0 de 328; la búsqueda de texto de PostgreSQL arregla la tilde pero no
> el singular, 0 frente a 95; OpenSearch arregla las dos y la errata, y a cambio enseña un cambio
> un segundo tarde. **Asume leído:** [`01`](01-mas-alla-de-las-tablas.md) y
> [`03/02`](../03-el-motor-por-dentro/02-familias-de-indices.md), las familias de índices y GIN.
> **Vigencia:** 27 de septiembre de 2026.

---

## Salto rápido

- [1. El problema](#1--el-problema) · [2. Lo que `LIKE` no puede](#2--lo-que-like-no-puede)
- [3. Analizar el texto](#3--analizar-el-texto) · [4. Relevancia](#4--relevancia)
- [5. Erratas, y el segundo de retraso](#5--erratas-y-el-segundo-de-retraso) · [6. La ficha del
  modelo](#6--la-ficha-del-modelo)
- [7. Estándar, motor y convención](#7--estándar-motor-y-convención) · [Errores
  frecuentes](#️-errores-frecuentes) · [Preguntas](#-preguntas)

---

## 1. 🎯 El problema

El buscador de la tienda empieza siempre igual: una caja de texto y un
`WHERE descripcion LIKE '%' || :texto || '%'`. Funciona el primer día. Después llegan las quejas, y
son siempre las mismas cinco:

1. Quien escribe `camara`, sin tilde, no encuentra ninguna cámara.
2. Quien escribe `auricular` no encuentra los «auriculares».
3. Quien escribe `auriculres`, con una errata, no encuentra nada.
4. Los resultados salen en cualquier orden, sin que el más parecido vaya primero.
5. Y con la tabla grande, la búsqueda recorre todas las filas, porque ningún B-tree sirve para un
   comodín por la izquierda.

Ninguna de las cinco es un fallo del código: es que `LIKE` compara caracteres, y una búsqueda
compara palabras. Este capítulo mide cuánto arregla la búsqueda de texto de PostgreSQL y cuánto
OpenSearch, y qué cuesta cada uno.

> **📝 Contexto.** Los productos se llaman «Producto N», así que las descripciones se **generan**
> con la consulta determinista de §4.8 del documento de dominio, que el esquema de seis tablas no
> cambia. En PostgreSQL viven en `texto.productos_texto`, un esquema de prueba de `bd-lab-postgres`
> que se borró al terminar; en OpenSearch, en el índice `productos` de `bd-lab-opensearch`, el
> servicio de `docker-compose.otros.yml` con `opensearchproject/opensearch:3.8.0` (§4.5 del
> dominio). La sesión de PostgreSQL es una sola, repartida entre §2, §3 y §4; las órdenes de
> OpenSearch se corrieron en dos guiones y aquí se presentan por tema, no en el orden en que se
> lanzaron —son lecturas independientes, salvo el cambio de §5, que va el último—. **Longitud:**
> unas 415 líneas; capítulo normal que pasa el disparador de 400.

---

## 2. 🩺 Lo que `LIKE` no puede

Las descripciones van de «guía de viajes en tapa dura» a «cámara deportiva con visión nocturna»: 328
productos llevan la palabra «cámara». La tabla se crea en el esquema de prueba desde la consulta del
dominio:

```bash
psql -X -h 127.0.0.1 -U postgres -d tienda -f datos/texto/texto.sql
```

```text
CREATE SCHEMA
SELECT 5000
```

- **`texto.sql`** es `CREATE SCHEMA texto` seguido de `CREATE TABLE texto.productos_texto AS` y la
  consulta de §4.8 del dominio, tal cual.

Y la primera queja, con el índice que se suele crear para arreglarla:

```text
tienda=# SELECT count(*) FROM texto.productos_texto WHERE descripcion LIKE '%camara%';
 count 
-------
     0
(1 fila)

tienda=# SELECT count(*) FROM texto.productos_texto WHERE descripcion ILIKE '%cámara%';
 count 
-------
   328
(1 fila)

tienda=# CREATE INDEX ON texto.productos_texto (descripcion);
CREATE INDEX
tienda=# EXPLAIN (COSTS OFF) SELECT codigo FROM texto.productos_texto WHERE descripcion LIKE '%cámara%';
                 QUERY PLAN                  
---------------------------------------------
 Seq Scan on productos_texto
   Filter: (descripcion ~~ '%cámara%'::text)
(2 filas)
```

- **`LIKE '%camara%'` da 0**: compara caracteres, y `a` no es `á`. Con la tilde y sin distinguir
  mayúsculas, `ILIKE`, encuentra las 328.
- **El B-tree no se usa**: un B-tree ordena por el principio de la cadena, y con un comodín a la
  izquierda no hay principio por el que buscar. `~~` es como escribe el plan un `LIKE`.
  [`03/06`](../03-el-motor-por-dentro/06-cuando-el-indice-no-se-usa.md) lo explicó por mecanismo,
  sin plan; aquí está el plan. Con 5 000 filas el recorrido es barato, pero crece con la tabla.

> **Veredicto:** `LIKE` responde «¿contiene estos caracteres?». Un buscador necesita responder
> «¿habla de esto?», y eso ya no es comparar cadenas.

---

## 3. 🧱 Analizar el texto

**Qué es:** un motor de búsqueda no guarda el texto para compararlo: lo **analiza**. Lo parte en
palabras —**tokenización**—, las pasa a minúsculas, quita las vacías como «con» o «de», y reduce
cada una a su **raíz** —***stemming***—, de modo que «auriculares» y «auricular» queden iguales.
Después guarda un **índice invertido**: para cada raíz, la lista de documentos que la contienen.

**Quién lo manda:** el **motor**, y cada uno con sus reglas de idioma. PostgreSQL trae la búsqueda
de texto completo con `tsvector` y `tsquery`; OpenSearch, analizadores por idioma.

En PostgreSQL, lo que queda de una descripción y de dos búsquedas:

```text
tienda=# SELECT to_tsvector('spanish', 'Auriculares inalámbricos con batería') AS documento, plainto_tsquery('spanish', 'auricular') AS singular, plainto_tsquery('spanish', 'camara') AS sin_tilde;
             documento              | singular  | sin_tilde 
------------------------------------+-----------+-----------
 'auricular':1 'bat':4 'inalambr':2 | 'auricul' | 'cam'
(1 fila)

tienda=# SELECT count(*) FILTER (WHERE to_tsvector('spanish', descripcion) @@ plainto_tsquery('spanish', 'camara')) AS camara, count(*) FILTER (WHERE to_tsvector('spanish', descripcion) @@ plainto_tsquery('spanish', 'auriculares')) AS auriculares, count(*) FILTER (WHERE to_tsvector('spanish', descripcion) @@ plainto_tsquery('spanish', 'auricular')) AS auricular, count(*) FILTER (WHERE to_tsvector('spanish', descripcion) @@ plainto_tsquery('spanish', 'auriculres')) AS errata FROM texto.productos_texto;
 camara | auriculares | auricular | errata 
--------+-------------+-----------+--------
    328 |          95 |         0 |      0
(1 fila)
```

- **`to_tsvector('spanish', ...)`** analiza el texto con la configuración española: «con»
  desaparece, y cada palabra queda en su raíz con su posición. **`plainto_tsquery`** analiza la
  búsqueda igual, y **`@@`** comprueba si coinciden.
- **La tilde, arreglada**: `camara` y `cámara` quedan en `cam`, y la búsqueda encuentra las 328.
- **El singular, no**: «auriculares» queda en `auricular`, pero «auricular» queda en `auricul`, y
  no coinciden. Buscar el singular da **0 de 95**. El *stemmer* español de PostgreSQL recorta cada
  palabra por sus reglas, y las de la palabra suelta y las del plural no llegan a la misma raíz.
- **La errata, tampoco**: `auriculres` no es ninguna raíz del índice.
- **Cuánto cuesta el `cam`**: una raíz tan corta junta palabras distintas que empiecen igual. Es el
  precio de reducir: más coincidencias, algunas falsas.

En OpenSearch, el índice se declara con el analizador español y se carga con la API `_bulk`:

```bash
curl -s -X PUT localhost:9200/productos -H 'Content-Type: application/json' -d '{"mappings": {"properties": {"codigo": {"type": "keyword"}, "categoria": {"type": "keyword"}, "descripcion": {"type": "text", "analyzer": "spanish"}}}}'
curl -s -X POST 'localhost:9200/productos/_bulk?refresh=true&filter_path=took,errors' -H 'Content-Type: application/x-ndjson' --data-binary @datos/texto/productos.ndjson
curl -s 'localhost:9200/productos/_count?q=descripcion:camara'
curl -s 'localhost:9200/productos/_count?q=descripcion:auricular'
```

```text
{"acknowledged":true,"shards_acknowledged":true,"index":"productos"}
{"took":220,"errors":false}
{"count":328,"_shards":{"total":1,"successful":1,"skipped":0,"failed":0}}
{"count":95,"_shards":{"total":1,"successful":1,"skipped":0,"failed":0}}
```

- **`"analyzer": "spanish"`** en el campo `descripcion`, de tipo `text`; `codigo` y `categoria` son
  `keyword`, que se guardan enteros para filtrar. `productos.ndjson` sale de `texto.productos_texto`
  con `json_build_object`: dos líneas por producto, la acción y el documento.
- **`_count?q=descripcion:camara`** cuenta los documentos que coinciden en ese campo. **328 y 95**:
  la tilde y el singular, arreglados los dos.

El porqué, con la API que enseña lo que hace el analizador:

```bash
curl -s -X POST 'localhost:9200/_analyze?filter_path=tokens.token' -H 'Content-Type: application/json' -d '{"analyzer": "spanish", "text": "Cámara deportiva con batería; auriculares inalámbricos"}'
```

```text
{"tokens":[{"token":"camar"},{"token":"deportiv"},{"token":"bateri"},{"token":"auricular"},{"token":"inalambric"}]}
```

- **Las tildes desaparecen** y «auriculares» queda en `auricular`, igual que el singular. La
  documentación dice que el analizador español usa el *stemmer* `light_spanish`: recorta menos que
  el de PostgreSQL, y en este caso acierta donde el otro falla.

> **Veredicto:** buscar palabras exige analizarlas, y el análisis decide lo que se encuentra. Los
> dos motores arreglan la tilde; el singular lo arregló uno solo, y se sabe porque se probó.

---

## 4. 🧱 Relevancia

**Qué es:** ordenar los resultados por **cuánto** se parecen a la búsqueda, no solo filtrar los que
coinciden. OpenSearch usa por defecto **BM25**, según su documentación: puntúa más un documento que
contiene muchas veces las palabras buscadas, que contiene palabras raras en la colección, y que es
corto. PostgreSQL ofrece `ts_rank`, que pondera por frecuencia.

Con el índice GIN sobre el `tsvector`, en PostgreSQL:

```text
tienda=# CREATE INDEX productos_texto_fts ON texto.productos_texto USING gin (to_tsvector('spanish', descripcion));
CREATE INDEX
tienda=# EXPLAIN (COSTS OFF) SELECT codigo FROM texto.productos_texto WHERE to_tsvector('spanish', descripcion) @@ plainto_tsquery('spanish', 'camara');
                                         QUERY PLAN                                         
--------------------------------------------------------------------------------------------
 Bitmap Heap Scan on productos_texto
   Recheck Cond: (to_tsvector('spanish'::regconfig, descripcion) @@ '''cam'''::tsquery)
   ->  Bitmap Index Scan on productos_texto_fts
         Index Cond: (to_tsvector('spanish'::regconfig, descripcion) @@ '''cam'''::tsquery)
(4 filas)

tienda=# SELECT codigo, descripcion, round(ts_rank(to_tsvector('spanish', descripcion), q)::numeric, 4) AS rango FROM texto.productos_texto, plainto_tsquery('spanish', 'auriculares inalámbricos batería') AS q WHERE to_tsvector('spanish', descripcion) @@ q ORDER BY rango DESC, codigo LIMIT 3;
  codigo   |                                 descripcion                                 | rango  
-----------+-----------------------------------------------------------------------------+--------
 PRD-00300 | auriculares inalámbricos con batería de larga duración. Ideal para regalar. | 0.2669
 PRD-00325 | auriculares inalámbricos con batería de larga duración. Envío en 24 horas.  | 0.2669
 PRD-00475 | auriculares inalámbricos con batería de larga duración. Últimas unidades.   | 0.2669
(3 filas)
```

- **El índice GIN sobre la expresión** es el índice invertido de PostgreSQL: el plan lo usa con un
  `Bitmap Index Scan`. Tiene que ser exactamente la misma expresión que la consulta, con la
  configuración `'spanish'` incluida, o no se usa.
- **`plainto_tsquery` une las palabras con Y**: solo salen los productos que tienen las tres, y
  `ts_rank` los ordena.

En OpenSearch, la misma búsqueda:

```bash
curl -s 'localhost:9200/productos/_search?size=3&filter_path=hits.total.value,hits.hits._id,hits.hits._score,hits.hits._source.descripcion' -H 'Content-Type: application/json' -d '{"query": {"match": {"descripcion": "auriculares inalámbricos batería"}}}'
```

```text
{"hits":{"total":{"value":162},"hits":[{"_id":"PRD-00300","_score":5.175293,"_source":{"descripcion":"auriculares inalámbricos con batería de larga duración. Ideal para regalar."}},{"_id":"PRD-00475","_score":5.175293,"_source":{"descripcion":"auriculares inalámbricos con batería de larga duración. Últimas unidades."}},{"_id":"PRD-00800","_score":5.175293,"_source":{"descripcion":"auriculares inalámbricos con batería de larga duración. Ideal para regalar."}}]}}
```

- **162 resultados, no solo los que tienen las tres palabras**: `match` une los términos con O por
  defecto, y BM25 pone primero los que tienen más. Es la diferencia de enfoque: PostgreSQL filtra y
  después ordena; un motor de búsqueda **ordena todo lo que se parece** y deja que el usuario mire
  arriba.
- **`filter_path`** recorta la respuesta a los campos pedidos; sin él, la respuesta trae también el
  índice, la puntuación máxima y el documento entero.
- **Los tres primeros empatan a 5,18**: sus descripciones solo difieren en la coletilla, que no
  contiene ninguna palabra buscada.

> **Veredicto:** los dos ordenan por parecido; la diferencia es de enfoque —filtrar y ordenar frente
> a ordenarlo todo— y de cuánto se puede afinar la puntuación, que en OpenSearch es mucho más.

---

## 5. 🩺 Erratas, y el segundo de retraso

La tercera queja, `auriculres`, y lo que se paga por tener el índice fuera de la base:

```bash
curl -s 'localhost:9200/productos/_count' -H 'Content-Type: application/json' -d '{"query": {"match": {"descripcion": {"query": "auriculres", "fuzziness": "AUTO"}}}}'
```

```text
{"count":95,"_shards":{"total":1,"successful":1,"skipped":0,"failed":0}}
```

- **`"fuzziness": "AUTO"`** acepta términos a una o dos ediciones de distancia —una letra de más, de
  menos o cambiada—, según la longitud de la palabra. `auriculres` está a una de `auricular`, y
  aparecen los 95. En PostgreSQL, la búsqueda de texto no lo hace; la extensión `pg_trgm`, que
  compara trigramas, sí se acerca, y es la que también indexa `LIKE '%x%'`.

**El precio**: OpenSearch no es la base de datos, es **otra copia** que se ve con retraso. Un
cambio de la descripción de `PRD-00017`, contado justo después y tras forzar el refresco:

```bash
curl -s -X PUT 'localhost:9200/productos/_doc/PRD-00017?filter_path=result' -H 'Content-Type: application/json' -d '{"codigo": "PRD-00017", "categoria": "audio", "descripcion": "cascos con cancelación de ruido en edición limitada"}' && curl -s 'localhost:9200/productos/_count?q=descripcion:limitada&filter_path=count'
curl -s -X POST 'localhost:9200/productos/_refresh?filter_path=_shards.successful'
curl -s 'localhost:9200/productos/_count?q=descripcion:limitada&filter_path=count'
curl -s 'localhost:9200/productos/_settings?include_defaults=true&filter_path=**.refresh_interval'
```

```text
{"result":"updated"}{"count":0}
{"_shards":{"successful":1}}
{"count":1}
{"productos":{"defaults":{"index":{"refresh_interval":"1s"}}}}
```

- **`updated` y, acto seguido, 0**: el documento está escrito pero **no es visible para la
  búsqueda** hasta el siguiente refresco. Tras `_refresh`, 1.
- **`refresh_interval` vale `1s` por defecto**: la documentación dice que el índice se refresca cada
  segundo mientras reciba búsquedas. Es búsqueda *casi* en tiempo real, no en tiempo real.
- **Y el segundo es lo de menos**: en una arquitectura real, el cambio llega de la base principal
  por una cola o un proceso de sincronización, y ese retraso es de segundos o minutos. El producto
  que se acaba de dar de baja puede seguir saliendo en el buscador.

> **⚠️ Advertencia.** Un motor de búsqueda nunca es la fuente de verdad: no hay transacción que lo
> una con la base, y si la sincronización falla, se desincroniza en silencio. Se diseña para poder
> **reconstruirlo entero** desde la base principal.

---

## 6. 🧭 La ficha del modelo

| Punto | Búsqueda de texto |
|---|---|
| **Qué resuelve mejor que SQL** | Encontrar documentos por las palabras que contienen, con tildes, plurales y erratas, ordenados por relevancia |
| **Dónde falla SQL, y por qué** | `LIKE` compara caracteres: no entiende tildes ni plurales, no ordena por parecido, y con comodín a la izquierda ningún B-tree lo sirve |
| **Producto principal y stack** | OpenSearch, con su API REST y su DSL de consultas en JSON; clientes oficiales en Java, Python, JavaScript y Go; `bd-lab-opensearch`, `opensearchproject/opensearch:3.8.0` |
| **El caso** | El buscador de la tienda → abajo, con números |

**El caso, con números.** Un escenario, no una medida del entorno: el catálogo pasa a 2 millones
de productos con descripciones largas, y el buscador recibe **300 búsquedas por segundo** en
campaña, con tolerancia a erratas y filtros por categoría y precio. **Por qué SQL falla ahí**:
`LIKE` recorre 2 millones de descripciones por búsqueda y no ordena; la búsqueda de texto de
PostgreSQL con GIN aguanta mucho más, pero no tolera erratas ni afina la relevancia. **Cómo lo
resuelve el modelo**: un índice invertido con analizador español, `fuzziness` y BM25, repartido en
fragmentos. **Qué se paga a cambio**: otra copia de los datos, sincronizada desde la base principal
y visible con retraso; otro sistema que operar; y una consulta que ya no es SQL.

**Elasticsearch y OpenSearch.** La FAQ de OpenSearch dice que deriva de Elasticsearch 7.10.2,
bifurcado de la última versión con licencia Apache 2.0 cuando Elasticsearch cambió de licencia.
Comparten el modelo, el índice invertido y buena parte de la API; han divergido desde entonces, así
que lo compatible se comprueba, como con los «compatibles» de
[`08/05`](../08-documental/05-documental-relacional-o-jsonb.md).

**Antes de montarlo**, la pregunta 3 del criterio de [`01`](01-mas-alla-de-las-tablas.md): con
miles o decenas de miles de productos, `tsvector` con GIN, `unaccent` para las tildes y `pg_trgm`
para las erratas cubren mucho sin salir de PostgreSQL. OpenSearch se gana su sitio con volumen,
relevancia afinada o facetas, y no antes.

---

## 7. 📜 Estándar, motor y convención

> **📜 Estándar o motor.** El estándar SQL define `LIKE` y su comodín; no define búsqueda de texto
> completo. `tsvector`, `ts_rank` y los analizadores son de cada motor, y BM25 es un algoritmo de
> recuperación de información, no una norma.

| Afirmación | Categoría | PostgreSQL 18 | OpenSearch 3.8 |
|---|---|---|---|
| `LIKE` con comodín a la izquierda usa un B-tree | Estándar el `LIKE`, motor el plan | No: `Seq Scan` | — |
| Encuentra la palabra sin tilde | Motor | Con `to_tsvector('spanish')`: 328 | Sí: 328 |
| Encuentra el plural buscando el singular | Motor | No: 0 de 95 | Sí: 95 |
| Tolera erratas | Motor | No, salvo `pg_trgm` | Sí, con `fuzziness`: 95 |
| Ordena por relevancia | Motor | `ts_rank`, sobre lo filtrado | BM25, sobre todo lo que se parece |
| Un cambio es visible al instante | Motor | Sí, al confirmar | Tras el refresco, cada segundo |
| El buscador se reconstruye desde la base | Convención | — | — |

**Convención, la que más se repite.** *«Para buscar texto hace falta Elasticsearch»* — para un
catálogo como el de la tienda, PostgreSQL arregló la tilde y ordenó por relevancia con un índice
GIN. El motor aparte se justifica por volumen, erratas y relevancia afinada, y se paga con una
copia.

---

## ⚠️ Errores frecuentes

| Se dice | Lo preciso |
|---|---|
| "Un índice en la columna acelera el `LIKE`" | Con comodín a la izquierda el plan siguió en `Seq Scan` |
| "La búsqueda de texto de PostgreSQL entiende plurales" | Buscando «auricular» encontró 0 de los 95 «auriculares» |
| "`to_tsvector` ignora las tildes porque no las entiende" | Las quita el *stemmer* español; el riesgo es que raíces cortas como `cam` junten palabras |
| "OpenSearch devuelve lo que coincide" | Devuelve todo lo que se parece, ordenado: 162 resultados con tres palabras unidas por O |
| "Lo escrito en OpenSearch se encuentra al momento" | Tras escribir, la búsqueda dio 0 hasta el refresco |
| "OpenSearch puede ser la base de la aplicación" | Es una copia sin transacción con la base, que hay que poder reconstruir |
| "OpenSearch y Elasticsearch son lo mismo" | OpenSearch deriva de Elasticsearch 7.10.2 y han divergido desde entonces |

---

## 📚 Para profundizar

- **Documentación** — PostgreSQL 18, «Introduction» a la búsqueda de texto: `tsvector` y `tsquery`.
  <https://www.postgresql.org/docs/18/textsearch-intro.html>
- **Documentación** — PostgreSQL 18, «Controlling Text Search»: `ts_rank` y el análisis.
  <https://www.postgresql.org/docs/18/textsearch-controls.html>
- **Documentación** — PostgreSQL 18, «pg_trgm»: trigramas, similitud y `LIKE` con índice.
  <https://www.postgresql.org/docs/18/pgtrgm.html>
- **Documentación** — PostgreSQL 18, «unaccent»: quitar tildes antes de indexar.
  <https://www.postgresql.org/docs/18/unaccent.html>
- **Documentación** — OpenSearch 3.8, «Spanish analyzer»: el *stemmer* `light_spanish`.
  <https://docs.opensearch.org/3.8/analyzers/language-analyzers/spanish/>
- **Documentación** — OpenSearch 3.8, «Keyword search»: BM25 como puntuación por defecto.
  <https://docs.opensearch.org/3.8/search-plugins/keyword-search/>
- **Documentación** — OpenSearch 3.8, «Refresh index»: el refresco de cada segundo.
  <https://docs.opensearch.org/3.8/api-reference/index-apis/refresh/>
- **Documentación** — OpenSearch, «FAQ»: su origen en Elasticsearch 7.10.2.
  <https://opensearch.org/faq/>

---

## 🧠 Preguntas

1. ¿Qué es un índice invertido? 🟢
2. ¿Qué son la tokenización y el *stemming*? 🟢
3. ¿Qué es BM25, y quién lo usa por defecto? 🟢
4. ¿Qué es el refresco de un índice de OpenSearch, y cada cuánto ocurre por defecto? 🟢
5. ¿Por qué `LIKE '%camara%'` no encontró ninguna de las 328 cámaras? 🟡
6. ¿Por qué el B-tree sobre `descripcion` no sirvió para `LIKE '%cámara%'`? 🟡
7. Distingue `to_tsvector` de `plainto_tsquery`, y di qué hace `@@`. 🟡
8. Distingue `keyword` de `text` en un mapeo de OpenSearch. 🟡
9. ¿Qué hace `"fuzziness": "AUTO"`, y cómo se acerca PostgreSQL a lo mismo? 🟡
10. ¿Por qué PostgreSQL encontró 0 productos buscando «auricular», si hay 95 «auriculares»? 🟠
11. ¿Por qué el índice GIN tiene que usar exactamente la misma expresión que la consulta? 🟠
12. ¿Por qué PostgreSQL devolvió solo productos con las tres palabras y OpenSearch 162? 🟠
13. ¿Qué riesgo tiene que «cámara» se reduzca a `cam`? 🟠
14. Tras actualizar `PRD-00017`, la búsqueda devolvió 0. ¿Por qué, y qué pasa en una arquitectura
    real? 🟠
15. ¿Por qué un motor de búsqueda nunca debe ser la fuente de verdad? 🔴
16. Diseña el buscador de la tienda en PostgreSQL, sin motor aparte: extensiones, índices y consulta
    para tildes, plurales, erratas y orden. 🔴
17. Diagnostica: un producto dado de baja hace una hora sigue saliendo en el buscador, aunque en la
    base consta como inactivo. 🔴
18. Defiende o refuta montar OpenSearch para el buscador de la tienda actual, con los números del
    capítulo. 🔴

---

**Anterior:** [`04`](04-series-temporales.md) — series temporales · **Siguiente:**
[`06`](06-vectorial-y-embeddings.md) — vectorial y embeddings · **Relacionado:**
[`03/06`](../03-el-motor-por-dentro/06-cuando-el-indice-no-se-usa.md) — el `LIKE` con comodín que no
usa el índice · [`l05`](../13-laboratorio/l05-los-otros-modelos.md) §7 — OpenSearch en el lab.
