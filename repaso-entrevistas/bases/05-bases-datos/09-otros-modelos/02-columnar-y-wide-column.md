# 02 — Columnar y wide-column

> Cassandra desde su clave: la partición que decide dónde vive una fila y el *clustering* que la
> ordena dentro. Se ve con los 409 998 eventos de los pedidos hasta `PED-99999`, en dos tablas
> diseñadas cada una para una consulta, y con lo que cuesta: el `INSERT` que pisa sin avisar, la
> transacción ligera que tarda el triple y el `DELETE` que escribe. **Asume leído:**
> [`01`](01-mas-alla-de-las-tablas.md), CAP y los niveles de consistencia, y
> [`07/06`](../07-clave-valor/06-dynamodb-diseno-desde-el-acceso.md), el método de diseño desde el
> acceso, que aquí se aplica sin volver a explicarlo. **Vigencia:** 27 de septiembre de 2026.

---

## Salto rápido

- [1. El problema](#1--el-problema) · [2. Partición y clustering](#2--partición-y-clustering)
- [3. Una consulta, una tabla](#3--una-consulta-una-tabla) · [4. El camino de
  escritura](#4--el-camino-de-escritura)
- [5. Escribir no es comprobar](#5--escribir-no-es-comprobar) · [6. Borrar
  escribe](#6--borrar-escribe)
- [7. La ficha del modelo](#7--la-ficha-del-modelo) · [8. Estándar, motor y
  convención](#8--estándar-motor-y-convención)
- [Errores frecuentes](#️-errores-frecuentes) · [Preguntas](#-preguntas)

---

## 1. 🎯 El problema

La tabla `eventos_pedido` tiene 4 100 000 filas, solo crece, y casi nunca se consulta de otra
forma que **«los eventos de este pedido, en orden»** o **«lo de hoy, lo último primero»**. Mientras
cabe en memoria, un B-tree la atiende sin esfuerzo. Con escala de telemetría —millones de eventos
por hora y una tabla que no cabe en ninguna máquina— cada inserción tiene que **encontrar la página
donde va la clave**, leerla de disco si no está en memoria, y pasar por **un único primario**.

Cassandra se diseñó para ese caso: repartir las escrituras entre nodos iguales, sin primario, y
escribir sin leer. Este capítulo enseña qué cambia en el modelo para conseguirlo, y lo que se deja
por el camino, que es mucho.

> **📝 Contexto.** Todo está corrido contra `bd-lab-cassandra`, el servicio de
> `docker-compose.otros.yml` con `cassandra:5.0.9` (§4.5 del documento de dominio), **un solo
> nodo** y `replication_factor: 1`. La replicación se vio con tres nodos en
> [`01`](01-mas-alla-de-las-tablas.md) §4; al cargar los datos en ese anillo, los tres cayeron por
> memoria, así que **no hay medidas de escalado horizontal**. Los eventos salen de PostgreSQL con
> `\copy` a `13-laboratorio/entorno/datos/cassandra/eventos.csv`, que no se versiona. Las sesiones
> de §2 y §3 son una sola, partida en dos: las dos tablas se crearon antes de la primera carga.
> **Longitud:** unas 545 líneas; capítulo normal cerca del techo, podado en prosa: 157 líneas de
> sesión, por debajo de las 180 del denso.

---

## 2. 🧱 Partición y clustering

**Qué es:** Cassandra es una base **wide-column**: guarda filas agrupadas en **particiones**, y
cada partición vive entera en los mismos nodos. La clave primaria tiene dos partes:

- **La clave de partición** decide **en qué nodos** vive la fila: Cassandra le aplica una función
  hash y el resultado, el *token*, cae en el tramo de uno de los nodos del anillo. Filas con la
  misma clave de partición viven juntas.
- **Las columnas de clustering** deciden **el orden de las filas dentro de la partición**, que se
  guarda ya ordenada en disco.

**Quién lo manda:** el **motor**. CQL se parece a SQL a propósito, pero no hay estándar detrás; el
doble paréntesis de `PRIMARY KEY ((pedido), ...)` es sintaxis de Cassandra y marca la partición.

> **⚠️ El nombre engaña.** *Wide-column* no es **columnar**. Una base columnar analítica guarda cada
> columna por separado para sumar millones de valores; Cassandra guarda **filas**, agrupadas por
> partición. Lo analítico está fuera de este curso.

Los eventos se cargan en una tabla cuya partición es el pedido:

```text
cqlsh> CREATE KEYSPACE tienda WITH replication = {'class': 'SimpleStrategy', 'replication_factor': 1};
cqlsh> CREATE TABLE tienda.eventos_por_pedido (pedido text, dia date, ocurrido_en timestamp, tipo text, origen text, importe decimal, PRIMARY KEY ((pedido), ocurrido_en, tipo));
cqlsh> COPY tienda.eventos_por_pedido (pedido, dia, ocurrido_en, tipo, origen, importe) FROM '/datos/eventos.csv' WITH NUMPROCESSES = 2;
Using 2 child processes

Starting copy of tienda.eventos_por_pedido with columns [pedido, dia, ocurrido_en, tipo, origen, importe].
409998 rows imported from 1 files in 0 day, 0 hour, 0 minute, and 8.039 seconds (0 skipped).
```

- **`PRIMARY KEY ((pedido), ocurrido_en, tipo)`**: `pedido` es la partición; `ocurrido_en` y `tipo`
  ordenan dentro. `tipo` está en la clave para que dos eventos del mismo pedido en el mismo
  milisegundo no sean la misma fila —§5 dice por qué eso importa—.
- **`COPY ... FROM`** es una orden de `cqlsh`, no de CQL: el cliente lee el fichero y manda lotes.
  `NUMPROCESSES = 2` limita sus procesos; con los siete de defecto, el contenedor se quedó sin
  memoria. Tardó **8,039 segundos**: unas 51 000 filas por segundo, en un nodo y un portátil.

Y la lectura para la que se diseñó:

```text
cqlsh> SELECT ocurrido_en, tipo, importe FROM tienda.eventos_por_pedido WHERE pedido = 'PED-00042';

 ocurrido_en                     | tipo      | importe
---------------------------------+-----------+---------
 2025-02-21 03:45:09.349000+0000 |  VALIDADO | 3186.23
 2025-02-21 04:22:09.349000+0000 |    PAGADO | 3186.23
 2025-02-21 04:59:09.349000+0000 | PREPARADO | 3186.23

(3 rows)
```

- **Una partición, ya ordenada**: el nodo sabe por el hash de `PED-00042` dónde está, y las filas
  salen en el orden en que se guardaron, sin ordenar en memoria.

> **Veredicto:** en Cassandra la clave primaria no identifica solo la fila: decide dónde vive y en
> qué orden. Todo el diseño sale de elegirla bien.

---

## 3. 🧭 Una consulta, una tabla

El método es el de [`07/06`](../07-clave-valor/06-dynamodb-diseno-desde-el-acceso.md): primero la
lista de consultas, después una tabla por consulta. «Lo de hoy, lo último primero» no se sirve con
una partición por pedido, así que se crea otra tabla con **los mismos datos** y otra clave:

```text
cqlsh> CREATE TABLE tienda.eventos_por_dia (pedido text, dia date, ocurrido_en timestamp, tipo text, origen text, importe decimal, PRIMARY KEY ((dia), ocurrido_en, pedido)) WITH CLUSTERING ORDER BY (ocurrido_en DESC, pedido ASC);
cqlsh> COPY tienda.eventos_por_dia (pedido, dia, ocurrido_en, tipo, origen, importe) FROM '/datos/eventos.csv' WITH NUMPROCESSES = 2;
Using 2 child processes

Starting copy of tienda.eventos_por_dia with columns [pedido, dia, ocurrido_en, tipo, origen, importe].
409998 rows imported from 1 files in 0 day, 0 hour, 0 minute, and 6.649 seconds (0 skipped).
cqlsh> SELECT ocurrido_en, pedido, tipo FROM tienda.eventos_por_dia WHERE dia = '2025-02-21' LIMIT 3;

 ocurrido_en                     | pedido    | tipo
---------------------------------+-----------+-----------
 2025-02-21 23:58:11.268000+0000 | PED-22821 |    CREADO
 2025-02-21 23:53:56.223000+0000 | PED-57027 |   ENVIADO
 2025-02-21 23:53:01.824000+0000 | PED-89918 | PREPARADO

(3 rows)
```

- **`CLUSTERING ORDER BY (ocurrido_en DESC, ...)`** guarda la partición del día de lo más reciente
  a lo más antiguo: «lo último primero» es leer las tres primeras filas, sin ordenar.
- **Mismo dato, dos tablas**, y la aplicación escribe cada evento dos veces. Las vistas
  materializadas lo harían por ella, pero `cassandra.yaml` las trae apagadas, entre las funciones
  experimentales «no recomendadas para uso en producción».

Y lo que la tabla **no** puede contestar, porque no se diseñó para ello:

```text
cqlsh> SELECT ocurrido_en, tipo FROM tienda.eventos_por_pedido WHERE pedido = 'PED-00042' ORDER BY importe;
InvalidRequest: Error from server: code=2200 [Invalid query] message="Order by is currently only supported on the clustered columns of the PRIMARY KEY, got importe"
cqlsh> SELECT count(*) FROM tienda.eventos_por_dia WHERE dia >= '2025-02-01' AND dia < '2025-03-01';
InvalidRequest: Error from server: code=2200 [Invalid query] message="Cannot execute this query as it might involve data filtering and thus may have unpredictable performance. If you want to execute this query despite the performance unpredictability, use ALLOW FILTERING"
cqlsh> SELECT dia, count(*) FROM tienda.eventos_por_dia WHERE dia IN ('2025-02-20', '2025-02-21', '2025-02-22') GROUP BY dia;

 dia        | count
------------+-------
 2025-02-20 |   500
 2025-02-21 |   462
 2025-02-22 |   444

(3 rows)

Warnings :
Aggregation query used on multiple partition keys (IN restriction)
```

- **Solo se ordena por el clustering.** El orden se decide al escribir, no al leer.
- **Un rango sobre la clave de partición no existe.** Las particiones están repartidas por su hash,
  no por su valor: «los días de febrero» son 28 particiones sin relación entre sí. `ALLOW FILTERING`
  recorrería **todo** el clúster, como en [`l05`](../13-laboratorio/l05-los-otros-modelos.md) §3; la
  respuesta es otra tabla, o enumerar las particiones.
- **Enumerarlas con `IN` funciona**, y el aviso dice lo que cuesta: el coordinador pregunta a tres
  particiones que pueden estar en tres nodos distintos, y espera a la más lenta.

**Cuánto** ocupa cada partición es la otra mitad del diseño. `nodetool tablestats`, tras volcar a
disco con `nodetool flush`, lo da por tabla:

```bash
docker exec bd-lab-cassandra nodetool tablestats tienda.eventos_por_pedido tienda.eventos_por_dia | grep -E 'Table:|Number of partitions|Compacted partition'
```

```text
		Table: eventos_por_dia
		Number of partitions (estimate): 1001
		Compacted partition minimum bytes: 104
		Compacted partition maximum bytes: 24601
		Compacted partition mean bytes: 7825
		Table: eventos_por_pedido
		Number of partitions (estimate): 98935
		Compacted partition minimum bytes: 104
		Compacted partition maximum bytes: 372
		Compacted partition mean bytes: 235
```

- **`tablestats`** imprime casi cincuenta líneas por tabla; el `grep` deja las del tamaño. El número
  de particiones es una **estimación**: hay 99 999 pedidos y dice 98 935.
- **Una partición por pedido pesa 235 bytes de media; una por día, 7 825.** La del pedido tiene
  tope —un pedido tiene pocos eventos—; la del día crece con el negocio.
- **La del día es además una partición caliente**: todas las escrituras de hoy caen en la misma
  partición, y por tanto en los mismos nodos, mientras el resto del clúster no recibe ninguna. Es
  el mismo problema de la partición caliente de DynamoDB en
  [`07/05`](../07-clave-valor/05-dynamodb-modelo-y-claves.md).

**La corrección se llama *bucketing*** en la documentación de modelado: meter en la partición un
trozo más —la hora, o un cubo de 0 a 9 calculado del pedido— para que un día sean diez o
veinticuatro particiones repartidas. Se paga al leer: «lo de hoy» son diez lecturas que junta la
aplicación. El límite duro es de **dos mil millones de celdas por partición**, y la documentación
avisa de que el rendimiento sufre mucho antes.

> **Veredicto:** una consulta nueva es una tabla nueva, y cada tabla se diseña dos veces: por la
> consulta que sirve y por cómo crece su partición.

---

## 4. 🧱 El camino de escritura

**Qué es:** Cassandra no escribe en un B-tree. Cada escritura se **añade al commit log**, un
registro secuencial que es su WAL, y se **pone en la memtable**, ordenada en memoria. Cuando la
memtable se llena, se vuelca entera como una **SSTable**, un fichero ordenado e inmutable; la
**compactación** va fundiendo SSTables en segundo plano.

**Quién lo manda:** el **motor**. La documentación lo llama árbol LSM (*log-structured merge*) y lo
contrapone a los B-trees: un camino de escritura **sin lecturas previas**, que es la respuesta a §1.

Se ve con las escrituras sobre `PED-00042` de §5, que seguían en la memtable:

```bash
docker exec bd-lab-cassandra nodetool tablestats tienda.eventos_por_pedido | grep -E 'SSTable count:|Memtable (cell count|data size)'
docker exec bd-lab-cassandra nodetool flush tienda eventos_por_pedido
docker exec bd-lab-cassandra nodetool tablestats tienda.eventos_por_pedido | grep -E 'SSTable count:|Memtable (cell count|data size)'
docker exec bd-lab-cassandra bash -c 'ls /var/lib/cassandra/data/tienda/eventos_por_pedido-*/ | grep Data.db'
```

```text
		SSTable count: 1
		Old SSTable count: 0
		Memtable cell count: 3
		Memtable data size: 117
		SSTable count: 2
		Old SSTable count: 0
		Memtable cell count: 0
		Memtable data size: 0
nb-10-big-Data.db
nb-9-big-Data.db
```

- **`nodetool flush`** fuerza el volcado. Antes: tres celdas en memoria y una SSTable. Después: la
  memtable vacía y **dos** SSTables; la nueva no reemplazó a la vieja, se añadió. La línea de las
  SSTables viejas se cuela en el `grep` porque también contiene `SSTable count:`.
- **`nb-9` y `nb-10`** son los datos de las dos SSTables; junto a cada uno hay índice, filtro de
  Bloom y resumen, que el `grep` no lista.

**Cuánto cuesta**, comparado. El mismo CSV, con la misma clave primaria, en una tabla normal de
PostgreSQL —no temporal, para que escriba WAL— dentro de un esquema que se borra al final:

```sql
-- pgcopy.sql
CREATE SCHEMA prueba;
CREATE TABLE prueba.eventos_por_pedido (pedido text, dia date, ocurrido_en timestamptz, tipo text,
  origen text, importe numeric(12,2), PRIMARY KEY (pedido, ocurrido_en, tipo));
\timing on
\copy prueba.eventos_por_pedido FROM 'datos/cassandra/eventos.csv' WITH (FORMAT csv)
\timing off
SELECT pg_size_pretty(pg_total_relation_size('prueba.eventos_por_pedido'));
DROP SCHEMA prueba CASCADE;
```

```text
$ psql -X -q -h 127.0.0.1 -U postgres -d tienda -f pgcopy.sql
Duración: 1215,499 ms (00:01,215)
 pg_size_pretty 
----------------
 52 MB
(1 fila)

psql:pgcopy.sql:7: NOTICE:  drop cascades to table prueba.eventos_por_pedido
```

- **`-q`** calla los mensajes de cada orden; quedan el tiempo, la consulta y el aviso del `DROP`.
  **`\copy`** lee el CSV en el cliente y lo manda como `COPY ... FROM STDIN`.

| | PostgreSQL 18 | Cassandra 5.0, un nodo |
|---|---|---|
| Carga de 409 998 filas | 1,22 s | 8,04 s |
| Tamaño en disco | 52 MB, con el índice de la clave | 9,4 MB, `Space used (live)` |

- **En un nodo, PostgreSQL carga más de seis veces más rápido**, y en entrevista hay que decirlo
  así. El argumento de Cassandra es otro: **la capacidad de escritura crece añadiendo nodos**,
  porque cada uno recibe solo las particiones de su tramo y no hay primario. Aquí no se ha medido
  (sin confirmar en este entorno).
- **Cassandra ocupa cinco veces menos** porque comprime las SSTables por defecto —`LZ4Compressor`,
  en bloques de 16 KB, según `system_schema.tables`— y PostgreSQL no comprime las filas pequeñas.
- **Lo que se paga en lectura**: una fila puede estar repartida entre la memtable y varias SSTables,
  y leerla es fundirlas. Los filtros de Bloom evitan abrir las que seguro no tienen la clave, y la
  compactación mantiene pocas a costa de reescribir cada dato varias veces.

> **Veredicto:** el árbol LSM cambia escrituras aleatorias por secuenciales más compactación. Gana
> cuando el volumen supera la memoria y se reparte entre nodos; en una máquina, gana el B-tree.

---

## 5. 🩺 Escribir no es comprobar

**Qué es:** en Cassandra, `INSERT` y `UPDATE` **son la misma operación**: escriben las columnas con
una marca de tiempo, exista la fila o no. La documentación lo dice así: «a diferencia de SQL,
`INSERT` no comprueba por defecto si la fila existía».

Se ve escribiendo sobre un evento que ya existe, con otros valores:

```text
cqlsh> INSERT INTO tienda.eventos_por_pedido (pedido, dia, ocurrido_en, tipo, origen, importe) VALUES ('PED-00042', '2025-02-21', '2025-02-21 04:22:09.349+0000', 'PAGADO', 'movil', 1.00);
cqlsh> SELECT tipo, origen, importe FROM tienda.eventos_por_pedido WHERE pedido = 'PED-00042';

 tipo      | origen | importe
-----------+--------+---------
  VALIDADO |    web | 3186.23
    PAGADO |  movil |    1.00
 PREPARADO |    web | 3186.23

(3 rows)
```

- **Ningún error y ninguna fila nueva.** El evento `PAGADO` tenía `web` y 3 186,23; ahora tiene
  `movil` y 1,00. En PostgreSQL, el mismo `INSERT` habría fallado con violación de clave primaria.
- **Es el motivo de que `tipo` esté en la clave** (§2): con la misma clave, **el segundo evento pisa
  al primero en silencio**. Una clave mal elegida pierde datos sin un solo error.

**La salida es la transacción ligera** (*lightweight transaction*, LWT): una condición que el
servidor comprueba antes de escribir.

```text
cqlsh> INSERT INTO tienda.eventos_por_pedido (pedido, dia, ocurrido_en, tipo, origen, importe) VALUES ('PED-00042', '2025-02-21', '2025-02-21 04:22:09.349+0000', 'PAGADO', 'web', 3186.23) IF NOT EXISTS;

 [applied] | pedido    | ocurrido_en                     | tipo   | dia        | importe | origen
-----------+-----------+---------------------------------+--------+------------+---------+--------
     False | PED-00042 | 2025-02-21 04:22:09.349000+0000 | PAGADO | 2025-02-21 |    1.00 |  movil

cqlsh> UPDATE tienda.eventos_por_pedido SET origen = 'web', importe = 3186.23 WHERE pedido = 'PED-00042' AND ocurrido_en = '2025-02-21 04:22:09.349+0000' AND tipo = 'PAGADO' IF origen = 'movil';

 [applied]
-----------
      True

cqlsh> SELECT tipo, origen, importe FROM tienda.eventos_por_pedido WHERE pedido = 'PED-00042';

 tipo      | origen | importe
-----------+--------+---------
  VALIDADO |    web | 3186.23
    PAGADO |    web | 3186.23
 PREPARADO |    web | 3186.23

(3 rows)
```

- **`IF NOT EXISTS`** no escribió: `[applied] False`, y devuelve la fila que ya estaba para que la
  aplicación decida.
- **`IF origen = 'movil'`** es una comparación y cambio: escribe solo si el valor actual es el
  esperado. Aquí devolvió el evento a sus valores originales.

**Cuánto cuesta.** La documentación avisa de «un coste de rendimiento no despreciable» porque usa
**Paxos**, un protocolo de consenso con varias rondas entre réplicas. Con mil inserciones de cada
tipo sobre una tabla de prueba, `tienda.estados`, dentro del contenedor:

```text
$ time cqlsh -f /tmp/ins-normal.cql > /dev/null

real	0m0.871s
user	0m0.468s
sys	0m0.073s
$ time cqlsh -f /tmp/ins-lwt.cql > /dev/null

real	0m1.892s
user	0m0.743s
sys	0m0.084s
```

- **`cqlsh -f`** ejecuta un fichero de órdenes en serie: mil `INSERT` sobre claves distintas, el
  segundo con `IF NOT EXISTS` en cada uno.
- **Arrancar `cqlsh` cuesta 0,33 s**, medido aparte con una consulta a `system.local`. Descontado,
  son 0,54 ms por escritura normal y 1,56 ms con condición: **casi el triple**, en un nodo y sin
  red. Con tres réplicas, cada ronda de Paxos es un viaje de red más.

> **💡 Para la entrevista.** «¿Cómo evito duplicados en Cassandra?» tiene tres respuestas buenas, en
> este orden: una clave que haga imposible la colisión, una escritura idempotente que pueda
> repetirse sin daño, y solo si nada de eso vale, `IF NOT EXISTS`, sabiendo que cuesta el triple.

---

## 6. 🩺 Borrar escribe

**Qué es:** como las SSTables no se cambian, un `DELETE` **escribe una marca de borrado**, una
*tombstone*, que en la lectura tapa los valores anteriores. El dato desaparece cuando la
compactación junta la marca con él, y solo si la marca es más vieja que `gc_grace_seconds`.

```text
cqlsh> DELETE FROM tienda.eventos_por_pedido WHERE pedido = 'PED-00042' AND ocurrido_en = '2025-02-21 04:59:09.349+0000' AND tipo = 'PREPARADO';
cqlsh> SELECT tipo FROM tienda.eventos_por_pedido WHERE pedido = 'PED-00042';

 tipo
----------
 VALIDADO
   PAGADO

(2 rows)
cqlsh> SELECT gc_grace_seconds FROM system_schema.tables WHERE keyspace_name = 'tienda' AND table_name = 'eventos_por_pedido';

 gc_grace_seconds
------------------
           864000

(1 rows)
```

```bash
docker exec bd-lab-cassandra nodetool tablestats tienda.eventos_por_pedido | grep -E 'SSTable count:|tombstones per slice'
docker exec bd-lab-cassandra nodetool flush tienda eventos_por_pedido
docker exec bd-lab-cassandra nodetool compact tienda eventos_por_pedido
docker exec bd-lab-cassandra nodetool tablestats tienda.eventos_por_pedido | grep -E 'SSTable count:|Space used \(live\)'
```

```text
		SSTable count: 2
		Old SSTable count: 0
		Average tombstones per slice (last five minutes): 1.0
		Maximum tombstones per slice (last five minutes): 1
		SSTable count: 1
		Old SSTable count: 0
		Space used (live): 9388929
```

- **El `SELECT` ya no ve `PREPARADO`**, pero para devolver dos filas **leyó una tombstone**
  (`Average tombstones per slice: 1.0`). Con miles de borrados, lee miles de marcas.
- **`nodetool compact`** pasó de dos SSTables a una, y el espacio no bajó —9 388 929 bytes, lo de
  antes— porque **la marca sigue ahí**: `gc_grace_seconds` vale 864 000 segundos, diez días.
- **Los diez días existen por las réplicas caídas**: si la marca desapareciera antes de llegar a
  una, esa réplica devolvería el dato borrado. La documentación lo llama **zombi**, y lo evita la
  reparación periódica dentro del plazo.

> **⚠️ Advertencia.** Una cola de trabajo en Cassandra —insertar tareas, leerlas y borrarlas— es el
> antipatrón clásico: cada tarea hecha deja una tombstone que se recorre durante diez días. Para eso
> están los *streams* de Redis de [`07/02`](../07-clave-valor/02-redis-estructuras-y-ttl.md).

---

## 7. 🧭 La ficha del modelo

| Punto | Wide-column |
|---|---|
| **Qué resuelve mejor que SQL** | Escritura sostenida de datos que solo crecen, repartida entre nodos iguales, y leída siempre por una clave de partición y un rango ordenado dentro |
| **Dónde falla SQL, y por qué** | Cada inserción en un B-tree busca su página, y si no está en memoria la lee de disco; y todas las escrituras pasan por un único primario |
| **Producto principal y stack** | Apache Cassandra, con CQL y `cqlsh`; drivers para Java, Python, Node y Go; `bd-lab-cassandra`, `cassandra:5.0.9`, en `docker-compose.otros.yml` |
| **El caso** | Telemetría de pedidos a gran escala → abajo, con números |

**El caso, con números.** Un escenario, no una medida: la tienda registra la posición de cada
reparto, **veinte mil eventos por segundo** sostenidos, unos 400 GB al mes, consultados siempre por
pedido o por día y hora. **Por qué SQL falla
ahí**: el índice de la tabla deja de caber en memoria, cada inserción empieza a leer de disco, y un
primario único recibe todo. **Cómo lo resuelve el modelo**: particiones por pedido y por día con
cubo, repartidas entre nodos, escritas sin leer en el árbol LSM, con `QUORUM` si hace falta leer lo
último. **Qué se paga a cambio**: sin `JOIN` y sin `ORDER BY` arbitrario; cada consulta nueva es una
tabla nueva que la aplicación mantiene; el `INSERT` pisa sin avisar y evitarlo cuesta el triple; y
los borrados dejan tombstones que se leen durante diez días.

**ScyllaDB** habla el mismo CQL, y su documentación se presenta como sustituto directo de
**Cassandra 3.11**, con funciones de 4.0. Es la trampa de los «compatibles» de
[`08/05`](../08-documental/05-documental-relacional-o-jsonb.md): se comprueba función por función.

---

## 8. 📜 Estándar, motor y convención

> **📜 Estándar o motor.** CQL no tiene estándar: se parece a SQL a propósito, pero cada cláusula es
> de Cassandra, y ScyllaDB fija su compatibilidad contra versiones concretas de Cassandra. Todo lo
> de este capítulo es **motor**, salvo el método de diseño, que es **convención**.

| Afirmación | Categoría | PostgreSQL 18 | Cassandra 5.0 |
|---|---|---|---|
| Un `INSERT` sobre una clave existente da error | Motor | Sí, violación de clave primaria | No, sobrescribe |
| Se puede ordenar por cualquier columna | Motor | Sí | Solo por el clustering |
| Un rango sobre la clave principal se sirve con índice | Motor | Sí, con el B-tree | No: la partición va por hash |
| Borrar libera el espacio | Motor | Tras `VACUUM` | Tras compactar y pasar `gc_grace_seconds` |
| Escribir exige leer antes la página | Motor | Sí, el B-tree | No, árbol LSM |
| Una consulta nueva exige una tabla nueva | Convención | No: un índice | Sí, por diseño |

**Convención, la que más se repite.** *«Cassandra es para big data»* — es para un patrón concreto
a gran escala. Con muchos datos y consultas imprevistas es la peor elección: cada consulta nueva es
una tabla más o un `ALLOW FILTERING`.

---

## ⚠️ Errores frecuentes

| Se dice | Lo preciso |
|---|---|
| "Wide-column es lo mismo que columnar" | Cassandra guarda filas agrupadas por partición; columnar guarda cada columna por separado para analítica |
| "Cassandra escribe más rápido que PostgreSQL" | En un nodo, el `COPY` de PostgreSQL cargó más de seis veces más rápido; Cassandra escala añadiendo nodos |
| "`INSERT` falla si la fila ya existe" | Sobrescribe en silencio; para comprobar hace falta `IF NOT EXISTS`, casi tres veces más caro |
| "`ALLOW FILTERING` arregla la consulta" | La convierte en un recorrido de todas las particiones; se arregla con otra tabla |
| "Borrar libera espacio" | Escribe una tombstone que dura al menos `gc_grace_seconds`, diez días por defecto |
| "Una partición por día es un buen diseño para eventos" | Concentra las escrituras del día en los mismos nodos y crece sin tope; se parte en cubos |

---

## 📚 Para profundizar

- **Documentación** — Apache Cassandra 5.0, «Storage Engine»: commit log, memtable y SSTables.
  <https://cassandra.apache.org/doc/5.0/cassandra/architecture/storage-engine.html>
- **Documentación** — Apache Cassandra 5.0, «Data Manipulation»: `INSERT`, `UPDATE`, `IF NOT EXISTS`
  y `ALLOW FILTERING`. <https://cassandra.apache.org/doc/5.0/cassandra/developing/cql/dml.html>
- **Documentación** — Apache Cassandra 5.0, «Defining Application Queries»: el diseño desde la
  consulta.
  <https://cassandra.apache.org/doc/5.0/cassandra/developing/data-modeling/data-modeling_queries.html>
- **Documentación** — Apache Cassandra 5.0, «Evaluating and Refining Data Models»: el *bucketing*.
  <https://cassandra.apache.org/doc/5.0/cassandra/developing/data-modeling/data-modeling_refining.html>
- **Documentación** — Apache Cassandra 5.0, «Tombstones»: la marca, el plazo y los zombis.
  <https://cassandra.apache.org/doc/5.0/cassandra/managing/operating/compaction/tombstones.html>
- **Documentación** — ScyllaDB, «ScyllaDB and Apache Cassandra Compatibility».
  <https://docs.scylladb.com/manual/stable/using-scylla/cassandra-compatibility.html>

---

## 🧠 Preguntas

1. ¿Qué es una partición en Cassandra, y qué la decide? 🟢
2. ¿Qué hacen las columnas de clustering? 🟢
3. ¿Qué es una SSTable, y por qué no se modifica nunca? 🟢
4. ¿Qué es una tombstone? 🟢
5. Distingue *wide-column* de columnar. ¿Qué parte es del motor y qué parte es convención? 🟡
6. ¿Por qué `ORDER BY importe` falla en `eventos_por_pedido`, y qué tabla lo permitiría? ¿Lo fija el
   estándar o es cosa del motor? 🟡
7. ¿Por qué no se puede pedir un rango de días sobre `eventos_por_dia`, si `dia` es la clave? 🟡
8. Recorre el camino de una escritura en Cassandra desde que llega hasta que está en una SSTable. 🟡
9. ¿Por qué `tipo` forma parte de la clave de `eventos_por_pedido`? ¿Qué pasaría sin él? 🟠
10. PostgreSQL cargó el CSV en 1,22 s y Cassandra en 8,04 s. ¿Qué argumento a favor de Cassandra
    sobrevive a ese número? 🟠
11. ¿Por qué Cassandra ocupó 9,4 MB y PostgreSQL 52 MB con los mismos datos? 🟠
12. ¿Qué cuesta una transacción ligera, medido, y por qué? 🟠
13. ¿Por qué el espacio no bajó tras el `DELETE` y la compactación? 🟠
14. ¿Por qué una partición por día es una partición caliente, y cómo se corrige? ¿Qué se paga? 🟠
15. Diseña las tablas de Cassandra para tres consultas: los eventos de un pedido, los de un día por
    hora y los de un cliente en un mes. Di la clave de cada una y cómo crece su partición. 🔴
16. Diagnostica: una tabla de tareas pendientes en Cassandra, en la que cada tarea se inserta, se
    lee y se borra, tarda cada vez más en devolver las diez primeras aunque casi siempre hay pocas.
    🔴
17. Defiende o refuta pasar `eventos_pedido` de PostgreSQL a Cassandra en la tienda actual, con los
    números del capítulo. 🔴

---

**Anterior:** [`01`](01-mas-alla-de-las-tablas.md) — más allá de las tablas · **Siguiente:**
[`03`](03-grafo.md) — grafo · **Relacionado:**
[`07/06`](../07-clave-valor/06-dynamodb-diseno-desde-el-acceso.md) — el método de diseño desde el
acceso, con DynamoDB · [`l05`](../13-laboratorio/l05-los-otros-modelos.md) §3 — Cassandra en el lab.
