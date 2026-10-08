# 01 — Más allá de las tablas

> Por qué «NoSQL» no dice nada útil de un motor, qué dice de verdad el teorema CAP y cómo se elige
> un modelo sin vender folletos. Se ve con dos sesiones que hacen lo contrario ante el mismo fallo:
> un conjunto de réplicas de MongoDB que **deja de aceptar escrituras** cuando pierde dos de sus
> tres nodos, y un anillo de Cassandra que **las sigue aceptando**. Cierra con la tabla comparada de
> las siete fichas del curso y el criterio de elección. **Asume leído:**
> [`07/01`](../07-clave-valor/01-el-modelo-clave-valor.md) y
> [`08/01`](../08-documental/01-el-modelo-documental.md), las dos primeras fichas, y
> [`08/04`](../08-documental/04-indices-transacciones-y-consistencia.md) §4 y §5, las
> réplicas de MongoDB. **Vigencia:** 27 de septiembre de 2026.

---

## Salto rápido

- [1. El problema](#1--el-problema) · [2. Por qué «NoSQL» no es una
  categoría](#2--por-qué-nosql-no-es-una-categoría)
- [3. CAP, lo justo](#3--cap-lo-justo) · [4. Dos motores ante el mismo
  fallo](#4--dos-motores-ante-el-mismo-fallo)
- [5. La tabla comparada de las fichas](#5-️-la-tabla-comparada-de-las-fichas) · [6. El criterio
  de elección](#6--el-criterio-de-elección)
- [7. Estándar, motor y convención](#7--estándar-motor-y-convención) · [Errores
  frecuentes](#️-errores-frecuentes) · [Preguntas](#-preguntas)

---

## 1. 🎯 El problema

En una revisión de arquitectura alguien propone: «para los eventos de los pedidos usemos NoSQL,
que escala». Nadie pregunta cuál. Y la palabra no alcanza para decidirlo, porque bajo ella caben
Redis, MongoDB, DynamoDB, Cassandra, Neo4j, OpenSearch y Qdrant, y **no comparten ni el modelo de
datos, ni el lenguaje de consulta, ni lo que hacen cuando se cae un nodo**.

Ese último punto es el que más dinero cuesta equivocar. Si los eventos se escriben en un motor que,
ante una avería de red, **prefiere negarse** a escribir antes que arriesgarse a perder un dato, el
servicio da errores. Si se escriben en uno que **prefiere aceptar** la escritura y reconciliar
después, el servicio sigue, y alguien leerá un dato viejo. Las dos cosas son decisiones de diseño
legítimas, y las dos se pueden ver con un solo pedido y dos órdenes de `docker stop`.

Este capítulo abre el bloque con tres cosas: por qué la etiqueta no sirve, qué es CAP y qué no es,
y cómo se elige.

> **📝 Contexto.** Las dos sesiones de §4 se corrieron sobre copias desechables, no sobre el entorno
> fijo: un conjunto de réplicas `rs0` de tres nodos con `mongo:8.0.20` (`bd-lab-prueba-mongo1` a
> `3`) y un anillo de tres nodos de Cassandra 5.0.9, la versión de §4.5 del documento de dominio
> (`bd-lab-prueba-cassandra1` a `3`, con la memoria limitada a 1 100 MB por nodo para que quepan en
> un portátil). Las dos copias se borraron al terminar. **No hay mediciones de rendimiento**: aquí
> se ve comportamiento ante fallos; los números de cada modelo están en su capítulo. **Longitud:**
> unas 450 líneas; capítulo normal que pasa el disparador de 400 por prosa comparada —siete
> modelos en dos tablas—, con 52 líneas de sesión.

---

## 2. 🧱 Por qué «NoSQL» no es una categoría

**Qué es:** «NoSQL» es una **etiqueta histórica** para los motores que no siguen el modelo
relacional. Nació como etiqueta de reuniones y artículos a finales de la década de 2000, no como
definición técnica, y se ha leído de dos formas: «sin SQL» y, después, «no solo SQL».

**Quién lo manda:** nadie. Es **convención**: no hay estándar, especificación ni documento de un
motor que diga qué propiedades tiene un motor NoSQL. Lo único que tienen en común es lo que no
son.

**Cuánto** difieren, en los tres ejes que deciden un diseño:

| Motor | Modelo | Cómo se pregunta | Ante la caída de nodos |
|---|---|---|---|
| **Redis** | Clave → estructura | Una orden por estructura: `GET`, `ZADD`, `XADD` | Un primario por fragmento; lo que no llegó a la réplica se pierde al promoverla |
| **MongoDB** | Documento | Filtros por cualquier campo y *pipeline* de agregación | Sin mayoría, no hay primario ni escrituras |
| **DynamoDB** | Clave compuesta → ítem | `GetItem`, `Query` por partición, índices declarados | Servicio gestionado; la lectura fuerte se pide, la eventual es la de defecto |
| **Cassandra** | Partición → filas ordenadas | CQL, solo por la clave de partición | Cada operación elige cuántas réplicas esperar |
| **Neo4j** | Nodos y relaciones | Cypher, recorriendo relaciones | En clúster, que es de la edición Enterprise, un líder elegido procesa las escrituras |
| **OpenSearch** | Documento con índice invertido | Consultas de relevancia sobre texto analizado | Réplicas de fragmento; se lee lo último refrescado |
| **Qdrant** | Vector con carga útil | Vecinos más cercanos por distancia | En modo distribuido, fragmentos con réplicas repartidas entre nodos |

Siete filas, y ninguna columna se repite. Decir «NoSQL» de cualquiera de ellos da la misma
información que decir «no es un coche» de una bicicleta, un tren y un barco.

**Y la frontera tampoco es nítida por el otro lado.** De los cinco modelos de este bloque, tres se
resuelven **dentro de PostgreSQL** en algún grado: el recorrido de grafo, con la CTE recursiva de
[`02/05`](../02-sql/05-cte-y-recursion.md); las series temporales, con TimescaleDB, que es una
extensión; y el vectorial, con `pgvector`, otra extensión. La búsqueda de texto tiene `tsvector` en
el propio motor. Y el documento tiene `jsonb`, que fue el capítulo
[`08/05`](../08-documental/05-documental-relacional-o-jsonb.md). Cassandra, Couchbase o DynamoDB, a
su vez, tienen lenguajes con `SELECT` y `WHERE`.

- **Cuándo sí** se usa la palabra: para nombrar el grupo en una conversación informal, sabiendo que
  no aporta información.
- **Cuándo no**: en una decisión. «Usemos NoSQL» no es una propuesta; «usemos Cassandra, porque los
  eventos se leen siempre por pedido y rango de fecha, y aceptamos leer un dato viejo durante un
  fallo» sí lo es.

> **Veredicto:** se nombra el modelo y el motor, nunca la etiqueta. La etiqueta solo dice lo que el
> motor no es.

---

## 3. 🧭 CAP, lo justo

**Qué es:** el teorema CAP dice que un sistema de datos **distribuido**, cuando la red se parte en
dos grupos que no se ven —una *partición*—, no puede garantizar a la vez:

- **C, consistencia**: toda lectura ve la última escritura confirmada, como si hubiera una sola
  copia.
- **A, disponibilidad**: toda petición a un nodo que funciona recibe una respuesta que no es un
  error.

La **P**, tolerancia a particiones, no es una opción: en una red real las particiones ocurren, y
el sistema tiene que hacer algo cuando pasan. Lo que se elige es **qué hacer durante la
partición**: negarse a responder a una parte de las peticiones (CP) o responder con lo que se tiene
y arriesgarse a devolver un dato viejo (AP).

**Quién lo manda:** es un **teorema**, no un estándar. Eric Brewer lo planteó como conjetura en
2000, y Seth Gilbert y Nancy Lynch lo demostraron en 2002. Lo que sí es **motor** es la elección de
cada uno: la documentación de Cassandra dice literalmente que elige disponibilidad y tolerancia a
particiones, «comprometiendo en cierta medida la consistencia»; la de MongoDB dice que el conjunto
de réplicas no procesa escrituras hasta que una elección termina con éxito.

**Lo que CAP no dice**, y es donde se cae la mayoría de las respuestas de entrevista:

1. **No dice nada sin partición.** Con la red sana, un sistema puede ser consistente y disponible a
   la vez. La elección solo se activa durante el fallo.
2. **No se aplica a un nodo solo.** Un PostgreSQL sin réplicas no es «CA»: no es distribuido, así
   que el teorema no habla de él. Si se cae, no está disponible y ya.
3. **La C de CAP no es la C de ACID.** La de ACID es que la transacción deja la base en un estado
   que cumple sus reglas ([`04/01`](../04-transacciones-y-concurrencia/01-acid-con-precision.md));
   la de CAP es que todas las copias parezcan una sola.
4. **No clasifica motores, clasifica configuraciones.** Cassandra con `QUORUM` en lectura y
   escritura se comporta como CP para esa operación, como se ve en §4. Un motor «AP» o «CP» es el
   comportamiento **por defecto**, no una propiedad fija.

**Cuánto cuesta** cada elección, que es lo que importa en diseño:

- **CP** paga en **errores durante el fallo**: las escrituras fallan, o esperan, hasta que vuelve la
  mayoría. El cliente tiene que saber reintentar.
- **AP** paga en **datos viejos y conflictos**: dos copias pueden aceptar escrituras distintas del
  mismo dato, y alguien decide después cuál gana —en Cassandra, la de marca de tiempo más reciente—.

Hay una extensión muy citada, **PACELC**, que añade lo que CAP calla: **sin partición** (*Else*),
se elige entre **latencia** y **consistencia**, porque esperar a más réplicas tarda más. Es
**convención** de análisis, no teorema, y es la que explica por qué Cassandra ofrece `ONE` además de
`QUORUM` incluso con la red sana.

- **Cuándo sí** citar CAP: al decidir qué hace un servicio cuando una zona de la nube se queda
  aislada, y para explicar por qué un motor da un error o un dato viejo.
- **Cuándo no**: para decir que un motor «es más rápido» o «escala más». CAP no habla de rendimiento
  ni de volumen.

> **Veredicto:** CAP responde a una sola pregunta —qué hace el sistema durante una partición— y la
> respuesta se configura por operación. Todo lo demás que se le atribuye no es CAP.

---

## 4. 🩺 Dos motores ante el mismo fallo

El experimento es el mismo en los dos: **tres copias de `PED-00042`, se apagan dos, y se intenta
cambiar el estado**. Con tres nodos, la mayoría son dos; con uno solo en pie, no hay mayoría.

**MongoDB, un conjunto de réplicas de tres nodos.** La sesión está conectada directamente al nodo 1,
que empieza como primario:

```text
rs0 [direct: primary] tienda> rs.status().members.map(m => [m.name, m.stateStr])
[
  [ 'bd-lab-prueba-mongo1:27017', 'PRIMARY' ],
  [ 'bd-lab-prueba-mongo2:27017', 'SECONDARY' ],
  [ 'bd-lab-prueba-mongo3:27017', 'SECONDARY' ]
]
rs0 [direct: primary] tienda> db.pedidos.insertOne({_id: "PED-00042", estado: "PAGADO"})
{ acknowledged: true, insertedId: 'PED-00042' }
```

En otra terminal se paran los otros dos nodos:

```bash
docker stop bd-lab-prueba-mongo2 bd-lab-prueba-mongo3
```

- **`docker stop`** manda la señal de parada a los contenedores y espera a que terminen. Es la forma
  más simple de simular que dos nodos quedan al otro lado de una partición: el nodo 1 deja de
  verlos.

Y quince segundos después, en la misma sesión de `mongosh`:

```text
rs0 [direct: primary] tienda> rs.status().members.map(m => [m.name, m.stateStr])
[
  [ 'bd-lab-prueba-mongo1:27017', 'SECONDARY' ],
  [ 'bd-lab-prueba-mongo2:27017', '(not reachable/healthy)' ],
  [ 'bd-lab-prueba-mongo3:27017', '(not reachable/healthy)' ]
]
rs0 [direct: secondary] tienda> db.pedidos.updateOne({_id: "PED-00042"}, {$set: {estado: "ENVIADO"}})
Uncaught MongoServerError[NotWritablePrimary]: not primary
rs0 [direct: secondary] tienda> db.pedidos.find({_id: "PED-00042"}).readPref("secondaryPreferred")
[ { _id: 'PED-00042', estado: 'PAGADO' } ]
```

- **El nodo 1 se degradó solo**, de `PRIMARY` a `SECONDARY`: un primario que no ve a la mayoría deja
  de serlo, porque al otro lado podría haberse elegido otro. El *prompt* cambió de
  `[direct: primary]` a `[direct: secondary]`.
- **La escritura falla** con `NotWritablePrimary`. Esa es la elección CP: antes que aceptar un
  cambio que la mayoría no ha visto, error.
- **La lectura funciona si se pide expresamente** con `readPref("secondaryPreferred")`, que acepta
  leer de un secundario. Y devuelve `PAGADO`: el último valor que ese nodo conoce, sin garantía de
  que sea el último del sistema.

Al arrancar solo uno de los dos nodos parados, vuelve a haber mayoría, dos de tres:

```text
rs0 [direct: primary] tienda> rs.status().members.map(m => [m.name, m.stateStr])
[
  [ 'bd-lab-prueba-mongo1:27017', 'PRIMARY' ],
  [ 'bd-lab-prueba-mongo2:27017', 'SECONDARY' ],
  [ 'bd-lab-prueba-mongo3:27017', '(not reachable/healthy)' ]
]
```

- **Con dos de tres basta**: hay elección, el nodo 1 vuelve a ser primario, y las escrituras se
  aceptan otra vez aunque el nodo 3 siga caído.

**Cassandra, un anillo de tres nodos**, con un *keyspace* que guarda tres copias de cada fila:

```text
cqlsh> CREATE KEYSPACE tienda WITH replication = {'class': 'SimpleStrategy', 'replication_factor': 3};
cqlsh> CREATE TABLE tienda.pedidos (codigo text PRIMARY KEY, estado text);
cqlsh> INSERT INTO tienda.pedidos (codigo, estado) VALUES ('PED-00042', 'PAGADO');
```

- **`replication_factor: 3`** pide tres copias de cada fila, una en cada nodo. `SimpleStrategy`
  reparte las copias sin tener en cuenta centros de datos: vale para un laboratorio, no para
  producción, donde se usa `NetworkTopologyStrategy`.

En otra terminal, la misma orden de antes:

```bash
docker stop bd-lab-prueba-cassandra2 bd-lab-prueba-cassandra3
```

Y en `cqlsh`, el mismo cambio de estado con dos **niveles de consistencia** distintos. El nivel
dice a cuántas réplicas espera el coordinador antes de responder:

```text
cqlsh> CONSISTENCY QUORUM;
Consistency level set to QUORUM.
cqlsh> UPDATE tienda.pedidos SET estado = 'ENVIADO' WHERE codigo = 'PED-00042';
NoHostAvailable: ('Unable to complete the operation against any hosts', {<Host: 127.0.0.1:9042 datacenter1>: Unavailable('Error from server: code=1000 [Unavailable exception] message="Cannot achieve consistency level QUORUM" info={\'consistency\': \'QUORUM\', \'required_replicas\': 2, \'alive_replicas\': 1}')})
cqlsh> CONSISTENCY ONE;
Consistency level set to ONE.
cqlsh> UPDATE tienda.pedidos SET estado = 'ENVIADO' WHERE codigo = 'PED-00042';
cqlsh> SELECT codigo, estado FROM tienda.pedidos WHERE codigo = 'PED-00042';

 codigo    | estado
-----------+---------
 PED-00042 | ENVIADO

(1 rows)
```

- **`CONSISTENCY QUORUM`** exige la respuesta de la mayoría de las réplicas: dos de tres. El error
  lo dice con sus números, `'required_replicas': 2, 'alive_replicas': 1`, y **no se intentó la
  escritura**: el coordinador sabía de antemano que no llegaría a dos. Con `QUORUM`, Cassandra se
  comporta como CP.
- **`CONSISTENCY ONE`** se conforma con una réplica. La escritura se acepta con dos de tres nodos
  caídos, y la lectura en `ONE` la devuelve. Esa es la elección AP: el servicio sigue, y las otras
  dos copias todavía dicen `PAGADO`.

Al volver los dos nodos, un minuto después, se lee exigiendo las tres réplicas:

```text
cqlsh> CONSISTENCY ALL;
Consistency level set to ALL.
cqlsh> SELECT codigo, estado FROM tienda.pedidos WHERE codigo = 'PED-00042';

 codigo    | estado
-----------+---------
 PED-00042 | ENVIADO

(1 rows)
```

- **`ALL`** espera a las tres réplicas, y las tres responden `ENVIADO`. Quien las puso al día es el
  **hinted handoff**: el nodo que aceptó la escritura guardó una nota —un *hint*— para cada réplica
  caída, y se la entregó al verla volver. La documentación fija la ventana en tres horas por
  defecto: un nodo caído más tiempo no recibe *hints* y necesita una reparación, que es trabajo de
  operación.
- **Si la lectura no hubiera esperado a todas**, con `ONE` y antes de que llegaran los *hints*,
  podría haber devuelto `PAGADO` desde una réplica atrasada. Esa ventana es el precio de AP.

> **💡 La regla del solapamiento.** Con tres réplicas, escribir en `QUORUM` y leer en `QUORUM`
> garantiza leer lo último escrito, porque dos más dos es más que tres y las dos mayorías comparten
> al menos una réplica. La documentación de Cassandra lo formula así. Es la forma de tener
> consistencia fuerte en un motor que por defecto es AP, y se paga con disponibilidad: con dos nodos
> caídos, ni se escribe ni se lee.

> **Veredicto:** CP y AP no son motores, son respuestas a una avería. MongoDB responde con un error
> por defecto; Cassandra deja que cada operación elija, y el diseño decide cuál conviene a cada
> dato.

---

## 5. ⚖️ La tabla comparada de las fichas

Cada modelo no relacional del curso tiene una ficha con cuatro puntos: qué resuelve mejor que SQL,
dónde falla SQL, el producto y el caso con su precio. Las siete, comparadas en una línea cada una:

| Modelo | Resuelve mejor que SQL | Lo que se rompe en SQL | Producto | Lo que se paga |
|---|---|---|---|---|
| **Clave-valor** ([`07/01`](../07-clave-valor/01-el-modelo-clave-valor.md)) | Muchas escrituras pequeñas sobre el mismo valor | El bloqueo de fila serializa las escrituras sobre una fila | Redis | Solo se pregunta por la clave; la durabilidad se configura |
| **Documental** ([`08/01`](../08-documental/01-el-modelo-documental.md)) | La entidad que se lee y escribe entera | El agregado se reparte en tablas que se unen en cada lectura | MongoDB | El tipo no lo comprueba nadie salvo validación; las partes no se consultan solas |
| **Wide-column** ([`02`](02-columnar-y-wide-column.md)) | Escritura masiva repartida entre nodos, leída por partición | Un B-tree y un primario únicos para todas las escrituras | Cassandra | Sin `JOIN`; una consulta nueva es una tabla nueva |
| **Grafo** ([`03`](03-grafo.md)) | Recorridos de profundidad variable | Cada salto es un `JOIN` más y la CTE recursiva crece sin control | Neo4j | Las consultas por conjunto y los agregados son su punto flojo |
| **Series temporales** ([`04`](04-series-temporales.md)) | Ingesta por tiempo, agregado por intervalos y borrado por antigüedad | El índice y el `DELETE` sobre una tabla que solo crece | TimescaleDB | Pensado para añadir, no para cambiar el pasado |
| **Texto** ([`05`](05-busqueda-de-texto.md)) | Relevancia sobre palabras, con acentos, plurales y erratas | `LIKE '%x%'` no usa el B-tree y no ordena por relevancia | OpenSearch | Otra copia del dato, que se ve con retraso |
| **Vectorial** ([`06`](06-vectorial-y-embeddings.md)) | Vecinos más cercanos por significado | No hay orden de B-tree para «parecido» | pgvector y Qdrant | Resultados aproximados, y un índice que ocupa y se construye despacio |

Leída por columnas, la tabla dice tres cosas:

- **La primera columna es siempre una forma de acceso**, no un tamaño. Ningún modelo resuelve
  «muchos datos» en abstracto; resuelve una forma concreta de leer o escribir.
- **La segunda nombra siempre un mecanismo**: el bloqueo de fila, el `JOIN`, el B-tree. Si no se
  puede nombrar el mecanismo que falla, no hay caso para cambiar de modelo.
- **La última columna nunca está vacía.** Todo modelo que resuelve algo mejor que SQL lo paga con
  algo que SQL daba gratis: consultas arbitrarias, tipos comprobados, una sola copia del dato.

---

## 6. 🧭 El criterio de elección

**Qué es:** una secuencia de preguntas que se hace **antes** de nombrar un motor. Es
**convención** de diseño, la de este curso, y sale de las fichas.

1. **¿Cómo se lee el dato?** Por clave, por entidad entera, por partición y rango, recorriendo
   relaciones, por relevancia o por parecido. Es la pregunta que elige el modelo; las demás eligen
   el motor y su configuración. Si la respuesta es «de muchas formas que aún no conocemos», el
   modelo es relacional.
2. **¿Qué mecanismo falla hoy, medido?** El plan con `EXPLAIN`, el bloqueo en `pg_locks`, la
   latencia del percentil 99. Si no hay medición, no hay caso: primero se mide
   ([`03/05`](../03-el-motor-por-dentro/05-explain-y-explain-analyze.md)).
3. **¿Lo resuelve algo dentro de la base actual?** Un índice, una columna `jsonb`, una extensión,
   una réplica de lectura. Es la pregunta que más migraciones evita.
4. **¿Qué hace el dato durante un fallo?** Un saldo no admite leerse viejo; un contador de visitas
   sí. Esa respuesta elige entre CP y AP, y el nivel de consistencia de cada operación.
5. **¿Quién lo opera y cuántas copias del dato habrá?** Un motor nuevo es otra copia que mantener
   sincronizada, otra copia de seguridad y otra guardia. Ese coste no sale en los folletos.

**Cuánto cuesta** equivocarse en cada paso: saltarse el 1 da un motor que no puede responder a la
consulta que llega el mes siguiente; saltarse el 2 o el 3, una migración para un problema que
resolvía un índice; saltarse el 4, un error en producción o un saldo mal leído.

- **Cuándo sí** proponer otro modelo: cuando las tres primeras respuestas apuntan a él, con el
  mecanismo que falla medido y sin arreglo razonable dentro de la base actual.
- **Cuándo no**: cuando el motivo es la etiqueta, la moda o «escala». Y casi nunca para
  **sustituir** la base relacional: lo habitual es **añadir** un motor para una forma de acceso
  concreta, con el relacional como fuente de verdad.

> **⚠️ Advertencia.** La pregunta 3 es la que más se salta en entrevista, porque parece una
> respuesta conformista. Es la contraria: demuestra que se conoce el motor actual lo bastante como
> para saber dónde se acaba. El bloque 12 vuelve a este criterio con la elección de motor completa.

> **Veredicto:** se elige el modelo por la forma de acceso, el motor por lo que hace durante un
> fallo y quién lo opera, y solo después de medir que la base actual no llega.

---

## 7. 📜 Estándar, motor y convención

> **📜 Estándar o motor.** No hay estándar de los modelos no relacionales comparable a ISO/IEC 9075,
> ni una definición de «NoSQL». CAP es un teorema, no una norma. Lo que es de cada motor —si deja de
> escribir sin mayoría, qué niveles de consistencia ofrece— está en su documentación.

| Afirmación | Categoría | MongoDB 8.0 | Cassandra 5.0 |
|---|---|---|---|
| Sin partición, se puede tener C y A a la vez | Teorema CAP | Sí | Sí |
| Ante la pérdida de la mayoría, rechaza escrituras | Motor | Sí: `NotWritablePrimary` | Depende del nivel: con `QUORUM` sí, con `ONE` no |
| Se puede leer durante el fallo | Motor | Solo pidiendo leer del secundario | Sí, con `ONE` |
| Las réplicas atrasadas se ponen al día solas | Motor | Replicando el registro de operaciones al volver | *Hints* durante tres horas; después, reparación |
| El comportamiento por defecto se llama CP o AP | Convención | CP | AP, según su propia documentación |
| «NoSQL» describe propiedades del motor | Convención | No | No |

**Convención, la que más se repite.** *«NoSQL escala y SQL no»* — la escala depende de cómo se
reparte el dato y de qué consulta se hace, no de la etiqueta. Un PostgreSQL con réplicas de lectura
escala las lecturas; un MongoDB con una consulta que no usa índice no escala nada.

---

## ⚠️ Errores frecuentes

| Se dice | Lo preciso |
|---|---|
| "NoSQL es una categoría de bases de datos" | Es una etiqueta histórica que agrupa modelos que no comparten ni modelo, ni lenguaje, ni comportamiento ante fallos |
| "CAP: elige dos de tres" | La partición no se elige; se elige qué hacer durante ella: error o dato posiblemente viejo |
| "PostgreSQL es CA" | Un nodo solo no es distribuido; CAP no habla de él |
| "Cassandra es AP, luego nunca es consistente" | Con `QUORUM` en lectura y escritura garantiza leer lo último escrito, y rechazó la escritura con un nodo |
| "MongoDB no está disponible si se cae un nodo" | Con tres nodos aguanta uno caído; sin mayoría deja de escribir |
| "La C de CAP y la de ACID son la misma" | La de ACID son las reglas de integridad; la de CAP, que las copias parezcan una sola |
| "Si es más rápido, es por ser NoSQL" | CAP no habla de rendimiento; la velocidad sale de la forma de acceso y del índice |

---

## 📚 Para profundizar

- **Documentación** — Apache Cassandra 5.0, «Guarantees»: CAP y la elección de disponibilidad.
  <https://cassandra.apache.org/doc/5.0/cassandra/architecture/guarantees.html>
- **Documentación** — Apache Cassandra 5.0, «Dynamo»: replicación y niveles de consistencia.
  <https://cassandra.apache.org/doc/5.0/cassandra/architecture/dynamo.html>
- **Documentación** — Apache Cassandra 5.0, «Hints»: el *hinted handoff* y su ventana.
  <https://cassandra.apache.org/doc/5.0/cassandra/managing/operating/hints.html>
- **Documentación** — MongoDB 8.0, «Replica Set Elections»: sin elección, no hay escrituras.
  <https://www.mongodb.com/docs/v8.0/core/replica-set-elections/>
- **Documentación** — MongoDB 8.0, «Read Preference»: leer del secundario.
  <https://www.mongodb.com/docs/v8.0/core/read-preference/>
- **Documentación** — MongoDB 8.0, «Replica Set with Three Members»: por qué tres.
  <https://www.mongodb.com/docs/v8.0/core/replica-set-architecture-three-members/>

---

## 🧠 Preguntas

1. ¿Qué significa «NoSQL», y quién lo define? 🟢
2. Enuncia el teorema CAP con tus palabras. 🟢
3. ¿Qué es un nivel de consistencia en Cassandra? 🟢
4. ¿Qué es el *hinted handoff*, y cuánto dura su ventana por defecto? 🟢
5. Distingue la C de CAP de la C de ACID. 🟡
6. ¿Por qué no tiene sentido decir que un PostgreSQL sin réplicas es «CA»? ¿Qué parte es del motor y
   qué parte es convención? 🟡
7. ¿Qué añade PACELC a CAP? 🟡
8. ¿Por qué el nodo 1 del conjunto de réplicas pasó de primario a secundario sin que nadie lo
   tocara? 🟡
9. ¿Por qué con tres réplicas, escribir y leer en `QUORUM` garantiza leer lo último escrito? 🟡
10. De los cinco modelos de este bloque, ¿cuáles se resuelven en algún grado dentro de PostgreSQL, y
    con qué? 🟡
11. Un compañero dice que Cassandra es AP y por eso nunca es consistente. Refútalo con la sesión. 🟠
12. ¿Qué paga un sistema CP durante una partición, y qué paga uno AP? Da un ejemplo de la tienda
    para cada uno. 🟠
13. ¿Por qué el error de `QUORUM` llegó sin intentar la escritura? 🟠
14. Tras la sesión de Cassandra, ¿en qué ventana podía una lectura devolver `PAGADO`, y cómo la
    habrías cerrado? 🟠
15. ¿Qué dice la segunda columna de la tabla comparada de las fichas, y por qué es la que decide si
    hay caso para cambiar de modelo? 🟠
16. ¿Por qué el criterio de elección pregunta por la base actual antes que por el motor nuevo? 🟠
17. Diseña qué nivel de consistencia usarías en Cassandra para el estado de un pedido y para un
    contador de visitas, y qué pasa en cada caso con dos de tres nodos caídos. 🔴
18. Diagnostica: tras un corte de red de cuatro horas entre dos zonas, un nodo de Cassandra devuelve
    estados de pedido viejos aunque la red volvió hace una hora. Da la causa y cómo la resolverías.
    🔴
19. Defiende o refuta la propuesta de §1, «para los eventos de los pedidos usemos NoSQL, que
    escala», recorriendo los cinco pasos del criterio de elección. 🔴

---

**Anterior:** [README del bloque](README.md) · **Siguiente:**
[`02`](02-columnar-y-wide-column.md) — columnar y *wide-column* · **Relacionado:**
[`08/04`](../08-documental/04-indices-transacciones-y-consistencia.md) §4 y §5 — réplicas,
`writeConcern` y lecturas del secundario en MongoDB ·
[`07/05`](../07-clave-valor/05-dynamodb-modelo-y-claves.md) — la lectura fuerte y la eventual en
DynamoDB.
