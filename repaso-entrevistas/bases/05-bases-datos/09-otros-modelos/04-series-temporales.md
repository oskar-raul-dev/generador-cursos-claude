# 04 — Series temporales

> Qué tienen de especial los datos que llegan ordenados por tiempo y no vuelven a cambiar, y qué
> hace TimescaleDB con ellos dentro de PostgreSQL. Medido con los 4 100 000 eventos de los pedidos
> en una hipertabla y en una tabla normal con índice: la consulta de la última semana empata; la
> compresión deja la hipertabla en 57 MB frente a 386; un agregado continuo contesta el año en 1,3
> ms; y la retención borra 52 tramos en 32 ms, mientras el `DELETE` deja la tabla en 309 MB. **Asume
> leído:** [`01`](01-mas-alla-de-las-tablas.md) y
> [`l05`](../13-laboratorio/l05-los-otros-modelos.md) §5, la primera hipertabla. **Vigencia:** 27 de
> septiembre de 2026.

---

## Salto rápido

- [1. El problema](#1--el-problema) · [2. La hipertabla](#2--la-hipertabla)
- [3. La consulta reciente: empate](#3--la-consulta-reciente-empate) · [4. Compresión en
  columnas](#4--compresión-en-columnas)
- [5. Agregados continuos](#5--agregados-continuos) · [6. Retención: borrar
  tramos](#6--retención-borrar-tramos)
- [7. La ficha del modelo](#7--la-ficha-del-modelo) · [8. Estándar, motor y
  convención](#8--estándar-motor-y-convención)
- [Errores frecuentes](#️-errores-frecuentes) · [Preguntas](#-preguntas)

---

## 1. 🎯 El problema

`eventos_pedido` tiene la forma de casi todos los datos de telemetría: **cada fila lleva una marca
de tiempo, llega en orden, no se cambia nunca**, y las consultas preguntan casi siempre por un
intervalo —«lo de ayer», «por hora este mes»—. Tres cosas se vuelven caras cuando esa tabla crece:

- **Los agregados sobre meses**: contar por tipo un año entero recorre millones de filas cada vez
  que alguien abre el panel.
- **El espacio**: los eventos viejos casi no se leen, y ocupan lo mismo que los nuevos.
- **Borrar lo viejo**: la política dice «dos años», y un `DELETE` de millones de filas genera WAL,
  deja filas muertas y necesita `VACUUM`.

El particionado nativo de PostgreSQL resuelve parte, pero hay que crear cada partición antes de que
lleguen sus datos y mantenerlo a mano. TimescaleDB es una extensión que lo automatiza y añade lo que
el particionado no trae: compresión en columnas y agregados que se mantienen solos.

> **📝 Contexto.** Todo está corrido contra `bd-lab-timescale`, el servicio de
> `docker-compose.otros.yml` con `timescale/timescaledb-ha:pg18.6-ts2.30.1` (§4.5 del documento de
> dominio): PostgreSQL 18.6 con TimescaleDB 2.30.1, en el puerto 5433. Los eventos se copian de
> `bd-lab-postgres` con dos `psql` unidos por una tubería, como en `l05` §5, y viven en la base
> `tienda` de ese servicio, no en la del entorno principal; §4.8 del dominio fija los nombres.
> **InfluxDB y Prometheus no están en el entorno**: lo que se dice de ellos sale de su
> documentación. **Longitud:** unas 545 líneas; capítulo denso, declarado en §2 del plan de
> producción: 208 líneas de sesión, que no se recortan.

---

## 2. 🧱 La hipertabla

**Qué es:** una **hipertabla** es una tabla que TimescaleDB parte sola en **tramos** (*chunks*) por
intervalos de tiempo. Cada tramo es una tabla de PostgreSQL normal; la hipertabla se consulta con
SQL normal, y el planificador descarta los tramos que no caen en el intervalo pedido.

**Quién lo manda:** el **motor**, una extensión. `create_hypertable` y el resto de funciones son de
TimescaleDB; el particionado por rango que hay debajo es el de PostgreSQL.

Las dos tablas que se comparan, la hipertabla con tramos de siete días y una tabla normal con un
índice por fecha:

```text
tienda=# CREATE TABLE eventos (ocurrido_en timestamptz NOT NULL, pedido_id bigint NOT NULL, tipo text NOT NULL);
CREATE TABLE
tienda=# SELECT create_hypertable('eventos', by_range('ocurrido_en', INTERVAL '7 days'));
 create_hypertable 
-------------------
 (1,t)
(1 fila)

tienda=# CREATE TABLE eventos_plano (ocurrido_en timestamptz NOT NULL, pedido_id bigint NOT NULL, tipo text NOT NULL);
CREATE TABLE
tienda=# CREATE INDEX ON eventos_plano (ocurrido_en);
CREATE INDEX
```

- **`by_range('ocurrido_en', INTERVAL '7 days')`** parte por la columna de tiempo en tramos de una
  semana. `create_hypertable` crea además un índice por `ocurrido_en` en cada tramo, el equivalente
  del que se crea a mano en `eventos_plano`.
- **Sin clave primaria**, a propósito: en `l05` §5 se vio que una clave única sin la columna de
  tiempo no se puede garantizar entre tramos, y TimescaleDB la rechaza.

La carga, las dos veces con los mismos 4 100 000 eventos ordenados por fecha:

```bash
time (psql -X -h 127.0.0.1 -p 5432 -U postgres -d tienda -c "\copy (SELECT ocurrido_en, pedido_id, tipo FROM eventos_pedido ORDER BY ocurrido_en) TO STDOUT" \
  | psql -X -h 127.0.0.1 -p 5433 -U postgres -d tienda -c "\copy eventos FROM STDIN")
```

```text
== eventos
COPY 4100000

real	0m8.785s
user	0m0.987s
sys	0m0.335s
== eventos_plano
COPY 4100000

real	0m6.287s
user	0m0.741s
sys	0m0.266s
```

- **El primer `psql` lee del puerto 5432**, el PostgreSQL del entorno, y escribe en la salida; el
  segundo lee de la entrada y escribe en el 5433. La orden se repite con `eventos_plano`; las líneas
  `==` las pone el guion que las lanza.
- **La hipertabla tarda más**: 8,8 s frente a 6,3. Con los datos llegando ordenados, el índice de la
  tabla normal solo crece por la derecha y es barato; la hipertabla, además, decide el tramo de cada
  fila y crea los tramos nuevos. **En la carga no gana.**

```text
tienda=# VACUUM ANALYZE eventos;
VACUUM
tienda=# VACUUM ANALYZE eventos_plano;
VACUUM
tienda=# SELECT count(*) AS tramos FROM show_chunks('eventos');
 tramos 
--------
    144
(1 fila)

tienda=# SELECT pg_size_pretty(hypertable_size('eventos')) AS hipertabla, pg_size_pretty(pg_total_relation_size('eventos_plano')) AS plana;
 hipertabla | plana  
------------+--------
 386 MB     | 309 MB
(1 fila)
```

- **144 tramos**, uno por semana desde enero de 2023, creados solos al insertar.
- **La hipertabla ocupa más**: 386 MB frente a 309. Son 144 tablas con 144 índices, y cada una tiene
  su página de cabecera y su sobrecoste. Hasta aquí, TimescaleDB solo ha costado.

> **Veredicto:** la hipertabla es particionado por tiempo automático. Por sí sola no carga más
> rápido ni ocupa menos; lo que gana está en §4, §5 y §6.

---

## 3. 🧱 La consulta reciente: empate

La consulta típica de un panel: eventos por día de la última semana. Es la misma sesión de los
tramos, tras el `VACUUM ANALYZE` de las dos tablas:

```text
tienda=# \timing on
El despliegue de duración está activado.
tienda=# SELECT time_bucket('1 day', ocurrido_en) AS dia, count(*) FROM eventos WHERE ocurrido_en >= '2025-09-21' GROUP BY dia ORDER BY dia;
          dia           | count 
------------------------+-------
 2025-09-21 00:00:00+00 |  4034
 2025-09-22 00:00:00+00 |  3991
 2025-09-23 00:00:00+00 |  4112
 2025-09-24 00:00:00+00 |  3912
 2025-09-25 00:00:00+00 |  4151
 2025-09-26 00:00:00+00 |  4025
 2025-09-27 00:00:00+00 |   234
(7 filas)

Duración: 2,796 ms
tienda=# SELECT date_trunc('day', ocurrido_en) AS dia, count(*) FROM eventos_plano WHERE ocurrido_en >= '2025-09-21' GROUP BY dia ORDER BY dia;
          dia           | count 
------------------------+-------
 2025-09-21 00:00:00+00 |  4034
 2025-09-22 00:00:00+00 |  3991
 2025-09-23 00:00:00+00 |  4112
 2025-09-24 00:00:00+00 |  3912
 2025-09-25 00:00:00+00 |  4151
 2025-09-26 00:00:00+00 |  4025
 2025-09-27 00:00:00+00 |   234
(7 filas)

Duración: 3,963 ms
tienda=# \timing off
El despliegue de duración está desactivado.
```

- **`time_bucket`** es el `date_trunc` de TimescaleDB, con cualquier anchura: `'15 minutes'`,
  `'1 week'`. Aquí da lo mismo que `date_trunc('day', ...)`.
- **2,8 ms frente a 4,0: empate.** Una semana son 24 000 filas, y un índice por fecha las encuentra
  igual de bien en una tabla que en 144. El plan de la hipertabla, al final de la misma sesión:

```text
tienda=# EXPLAIN (COSTS OFF) SELECT count(*) FROM eventos WHERE ocurrido_en >= '2025-09-21';
                                                QUERY PLAN                                                
----------------------------------------------------------------------------------------------------------
 Finalize Aggregate
   ->  Append
         ->  Partial Aggregate
               ->  Index Only Scan using _hyper_1_143_chunk_eventos_ocurrido_en_idx on _hyper_1_143_chunk
                     Index Cond: (ocurrido_en >= '2025-09-21 00:00:00+00'::timestamp with time zone)
         ->  Partial Aggregate
               ->  Seq Scan on _hyper_1_144_chunk
(7 filas)
```

- **Solo dos de los 144 tramos**: el 143, con índice, y el 144, entero porque todo él cae en el
  intervalo. Es la **exclusión de tramos**. Pero la tabla normal consigue lo mismo con su índice, y
  para una consulta así la exclusión no aporta nada que el índice no diera.

> **Veredicto:** para leer un intervalo reciente, un índice por fecha basta. Quien diga que
> TimescaleDB acelera esa consulta tiene que enseñar el plan.

---

## 4. 🧱 Compresión en columnas

**Qué es:** TimescaleDB puede convertir un tramo al **almacén en columnas** (*columnstore*, parte de
lo que su documentación llama Hypercore): las filas se agrupan, y cada columna del grupo se guarda
comprimida por separado. La documentación habla de compresión «de hasta un 98 %».

**Quién lo manda:** el **motor**. Se declara por qué columna se agrupan las filas —`segmentby`— y en
qué orden —`orderby`—, y se convierten los tramos viejos. Antes, el agregado de un año en las dos
tablas:

```text
tienda=# \timing on
El despliegue de duración está activado.
tienda=# SELECT tipo, count(*) FROM eventos WHERE ocurrido_en >= '2024-01-01' AND ocurrido_en < '2025-01-01' GROUP BY tipo ORDER BY tipo;
   tipo    | count  
-----------+--------
 CREADO    | 243905
 ENTREGADO | 255672
 ENVIADO   | 243629
 PAGADO    | 243708
 PREPARADO | 255949
 VALIDADO  | 255949
(6 filas)

Duración: 60,371 ms
tienda=# SELECT tipo, count(*) FROM eventos_plano WHERE ocurrido_en >= '2024-01-01' AND ocurrido_en < '2025-01-01' GROUP BY tipo ORDER BY tipo;
   tipo    | count  
-----------+--------
 CREADO    | 243905
 ENTREGADO | 255672
 ENVIADO   | 243629
 PAGADO    | 243708
 PREPARADO | 255949
 VALIDADO  | 255949
(6 filas)

Duración: 91,450 ms
tienda=# ALTER TABLE eventos SET (timescaledb.enable_columnstore = true, timescaledb.segmentby = 'tipo', timescaledb.orderby = 'ocurrido_en DESC');
ALTER TABLE
Duración: 2,092 ms
tienda=# SELECT count(compress_chunk(c)) AS comprimidos FROM show_chunks('eventos', older_than => '2025-09-01'::timestamptz) AS c;
 comprimidos 
-------------
         139
(1 fila)

Duración: 2197,620 ms (00:02,198)
tienda=# \timing off
El despliegue de duración está desactivado.
tienda=# SELECT pg_size_pretty(hypertable_size('eventos')) AS hipertabla, pg_size_pretty(pg_total_relation_size('eventos_plano')) AS plana;
 hipertabla | plana  
------------+--------
 57 MB      | 309 MB
(1 fila)

tienda=# \timing on
El despliegue de duración está activado.
tienda=# SELECT tipo, count(*) FROM eventos WHERE ocurrido_en >= '2024-01-01' AND ocurrido_en < '2025-01-01' GROUP BY tipo ORDER BY tipo;
   tipo    | count  
-----------+--------
 CREADO    | 243905
 ENTREGADO | 255672
 ENVIADO   | 243629
 PAGADO    | 243708
 PREPARADO | 255949
 VALIDADO  | 255949
(6 filas)

Duración: 20,131 ms
```

- **`segmentby = 'tipo'`** agrupa las filas de cada tipo juntas, así que el valor de `tipo` se
  guarda una vez por grupo y no una vez por fila. **`orderby`** ordena dentro del grupo, lo que hace
  que las fechas consecutivas se parezcan y compriman bien.
- **`compress_chunk`** convierte un tramo; `show_chunks(..., older_than => ...)` elige los 139
  anteriores a septiembre de 2025 y deja sin comprimir los cinco más recientes, que siguen
  recibiendo escrituras. Tardó 2,2 s.
- **De 386 MB a 57**, casi siete veces menos, y cinco veces menos que la tabla normal.
- **El agregado del año, de 60 ms a 20**, frente a 91 en la tabla normal: contar por `tipo` lee solo
  las columnas que necesita, y con `segmentby` el grupo ya viene por tipo.

**Cuánto cuesta**: un tramo en columnas está pensado para **no cambiar**. Actualizar o borrar una
fila vieja obliga al motor a tratar el grupo entero en el que está, y la documentación recomienda
convertir solo los tramos que ya no reciben cambios. Es el precio de toda base columnar, y la razón
de dejar sin comprimir los tramos recientes.

> **Veredicto:** la compresión en columnas es lo primero que TimescaleDB da y el particionado nativo
> no: siete veces menos espacio y agregados tres veces más rápidos, a cambio de que el pasado no se
> toque.

---

## 5. 🧱 Agregados continuos

**Qué es:** un **agregado continuo** es una vista materializada que TimescaleDB sabe **refrescar por
trozos**: solo recalcula los intervalos en los que han cambiado los datos. Es lo que hace que un
panel sobre años de eventos conteste sin recorrerlos.

```text
tienda=# \timing on
El despliegue de duración está activado.
tienda=# CREATE MATERIALIZED VIEW eventos_por_dia WITH (timescaledb.continuous) AS SELECT time_bucket('1 day', ocurrido_en) AS dia, tipo, count(*) AS eventos FROM eventos GROUP BY dia, tipo;
NOTICE:  refreshing continuous aggregate "eventos_por_dia"
SUGERENCIA:  Use WITH NO DATA if you do not want to refresh the continuous aggregate on creation.
CREATE MATERIALIZED VIEW
Duración: 314,055 ms
tienda=# SELECT tipo, sum(eventos) FROM eventos_por_dia WHERE dia >= '2024-01-01' AND dia < '2025-01-01' GROUP BY tipo ORDER BY tipo;
   tipo    |  sum   
-----------+--------
 CREADO    | 243905
 ENTREGADO | 255672
 ENVIADO   | 243629
 PAGADO    | 243708
 PREPARADO | 255949
 VALIDADO  | 255949
(6 filas)

Duración: 1,340 ms
```

- **`WITH (timescaledb.continuous)`** convierte la vista en agregado continuo; al crearla se calcula
  entera, 314 ms, como avisa el `NOTICE`.
- **El año en 1,3 ms**, con los mismos recuentos: la vista tiene una fila por día y tipo, unas 6 000
  en total, frente a los 1,5 millones de eventos del año.

**Cuánto cuesta**: el agregado va **por detrás** de los datos. Un evento nuevo de hoy, en la misma
sesión:

```text
tienda=# INSERT INTO eventos VALUES ('2025-09-27 12:00:00+00', 42, 'ENVIADO');
INSERT 0 1
Duración: 1,144 ms
tienda=# SELECT sum(eventos) FROM eventos_por_dia WHERE dia = '2025-09-27';
 sum 
-----
 234
(1 fila)

Duración: 0,528 ms
tienda=# CALL refresh_continuous_aggregate('eventos_por_dia', '2025-09-27', '2025-09-28');
CALL
Duración: 1,851 ms
tienda=# SELECT sum(eventos) FROM eventos_por_dia WHERE dia = '2025-09-27';
 sum 
-----
 235
(1 fila)

Duración: 0,428 ms
```

- **234 antes del refresco y 235 después.** El evento nuevo —del pedido 42, `PED-00042`— no aparece
  hasta que se refresca ese intervalo. En producción se programa el refresco con una política.
- **La documentación dice que desde la versión 2.13 la agregación en tiempo real viene desactivada
  por defecto**; activarla —`materialized_only = false`— hace que la vista sume al vuelo los datos
  aún no materializados, a cambio de consultas más lentas.

> **Veredicto:** el agregado continuo cambia recorrer millones de filas por leer miles, y lo paga
> con un retraso que hay que decidir: refresco programado, o agregación en tiempo real.

---

## 6. 🩺 Retención: borrar tramos

La política dice que los eventos de más de dos años se borran. En la tabla normal, un `DELETE`; en
la hipertabla, `drop_chunks`, que borra tramos enteros. Sigue la misma sesión de §5:

```text
tienda=# DELETE FROM eventos_plano WHERE ocurrido_en < '2024-01-01';
DELETE 1496342
Duración: 411,085 ms
tienda=# SELECT count(*) AS tramos_borrados FROM drop_chunks('eventos', older_than => '2024-01-01'::timestamptz);
 tramos_borrados 
-----------------
              52
(1 fila)

Duración: 32,354 ms
tienda=# \timing off
El despliegue de duración está desactivado.
tienda=# SELECT min(ocurrido_en) FROM eventos;
              min              
-------------------------------
 2023-12-28 00:00:04.681416+00
(1 fila)

tienda=# SELECT min(dia) FROM eventos_por_dia;
          min           
------------------------
 2023-01-01 00:00:00+00
(1 fila)

tienda=# SELECT pg_size_pretty(hypertable_size('eventos')) AS hipertabla, pg_size_pretty(pg_total_relation_size('eventos_plano')) AS plana;
 hipertabla | plana  
------------+--------
 40 MB      | 309 MB
(1 fila)
```

- **El `DELETE` tardó 411 ms y la tabla sigue en 309 MB.** Marcó 1 496 342 filas como muertas y
  escribió cada borrado en el WAL; el espacio no vuelve hasta que `VACUUM` lo recicle, y al disco
  solo si las páginas vacías quedan al final, como vio
  [`04/03`](../04-transacciones-y-concurrencia/03-mvcc-frente-a-bloqueo.md).
- **`drop_chunks` tardó 32 ms y la hipertabla bajó de 57 a 40 MB**: borrar un tramo es borrar una
  tabla, sin filas muertas ni `VACUUM`. En una tabla de cientos de GB, la diferencia deja de ser de
  milisegundos.
- **Pero borra tramos enteros**: queda un evento del 28 de diciembre de 2023, porque su tramo
  empieza ese día y llega a 2024. La documentación lo dice: solo se borra un tramo si **todo** su
  intervalo cae antes de la fecha.
- **El agregado conserva 2023**: `min(dia)` sigue en enero de 2023. Es el ***downsampling***:
  guardar el detalle unos meses y el resumen por día para siempre.

> **Veredicto:** borrar por antigüedad es donde la hipertabla más gana: un `DROP` de tramos frente a
> un `DELETE` que deja la tabla igual de grande. El particionado nativo lo consigue también, si
> alguien crea y borra las particiones.

---

## 7. 🧭 La ficha del modelo

| Punto | Series temporales |
|---|---|
| **Qué resuelve mejor que SQL** | Datos que llegan por tiempo y no cambian: agregados sobre intervalos largos, espacio de lo antiguo y borrado por antigüedad |
| **Dónde falla SQL, y por qué** | Un agregado de meses recorre millones de filas en cada consulta; las filas viejas ocupan como las nuevas; y un `DELETE` masivo genera WAL y filas muertas que solo `VACUUM` recicla |
| **Producto principal y stack** | TimescaleDB, extensión de PostgreSQL: SQL normal y los drivers de PostgreSQL de [`10`](../10-interfaz-con-los-lenguajes/01-el-driver-la-conexion-y-el-pool.md); `bd-lab-timescale`, `timescale/timescaledb-ha:pg18.6-ts2.30.1` |
| **El caso** | Métricas de la tienda → abajo, con números |

**El caso, con números.** Un escenario, no una medida del entorno: la tienda registra métricas de
sus servicios —latencia, errores, pedidos por segundo— de 200 instancias cada diez segundos, unos
**1,7 millones de filas al día**, con paneles por hora de los últimos 90 días y una retención de un
año. **Por qué SQL falla ahí**: el panel de 90 días recorre 150 millones de filas cada vez, y borrar
cada día lo que cumple un año es un `DELETE` de 1,7 millones de filas diario. **Cómo lo resuelve el
modelo**: hipertabla con tramos de un día, compresión de lo que tiene más de una semana, un agregado
continuo por hora para los paneles y `drop_chunks` diario. **Qué se paga a cambio**: el pasado
comprimido no se corrige barato; el agregado va por detrás del dato; y la carga es algo más lenta
que en una tabla normal, como en §2.

**El resto del mapa**, según su documentación:

- **InfluxDB 3 Core**, la versión de código abierto, guarda en ficheros Parquet, en disco local o en
  almacenamiento de objetos, y se consulta con SQL o con InfluxQL. Es un motor aparte, no una
  extensión: otra copia de los datos.
- **Prometheus** guarda las muestras en bloques de dos horas que compacta en segundo plano, con una
  retención de 15 días por defecto, y su documentación advierte de que el almacenamiento local **no
  está replicado ni en clúster**. Es un sistema de monitorización, no una base para datos de
  negocio.

---

## 8. 📜 Estándar, motor y convención

> **📜 Estándar o motor.** No hay estándar de series temporales. `time_bucket`, las hipertablas, la
> compresión y los agregados continuos son de TimescaleDB; el particionado por rango que hay debajo
> es de PostgreSQL. Todo el capítulo es **motor**, salvo el *downsampling*, que es **convención**.

| Afirmación | Categoría | PostgreSQL 18 | TimescaleDB 2.30 |
|---|---|---|---|
| Parte la tabla por tiempo | Motor | Con particionado declarativo, creando cada partición | Sola, al insertar: 144 tramos |
| Una consulta reciente descarta lo que no toca | Motor | Con el índice, o con poda de particiones | Con exclusión de tramos: 2 de 144 |
| Comprime los datos viejos en columnas | Motor | No | Sí: de 386 a 57 MB |
| Mantiene un agregado al día sin recalcularlo entero | Motor | No: `REFRESH MATERIALIZED VIEW` recalcula entero | Sí, por intervalos, con retraso |
| Borrar por antigüedad libera espacio al momento | Motor | Con `DROP` de partición; con `DELETE`, no | Sí, `drop_chunks`, por tramos enteros |
| Guardar el resumen y borrar el detalle | Convención | — | — |

**Convención, la que más se repite.** *«Para series temporales hace falta una base especializada»*
— en la tienda, la hipertabla empató en la consulta reciente y ganó en espacio, agregados y
retención sin salir de PostgreSQL. Una base aparte se justifica por volumen o por el ecosistema de
monitorización, no por la forma de los datos.

---

## ⚠️ Errores frecuentes

| Se dice | Lo preciso |
|---|---|
| "TimescaleDB acelera las consultas por fecha" | La de la última semana empató: 2,8 ms frente a 4,0 con un índice normal |
| "La hipertabla carga más rápido" | Cargó en 8,8 s frente a 6,3 con los datos ordenados |
| "La hipertabla ocupa menos" | Ocupa más, 386 MB frente a 309, hasta comprimir: entonces 57 MB |
| "Un agregado continuo siempre está al día" | Va por detrás hasta el refresco: 234 antes y 235 después |
| "`drop_chunks` borra justo hasta la fecha" | Borra tramos enteros; quedó un evento del 28 de diciembre |
| "Borrar con `DELETE` libera espacio" | La tabla siguió en 309 MB tras borrar 1,5 millones de filas |
| "Prometheus sirve para guardar datos de negocio" | Su almacenamiento local no está replicado, y retiene 15 días por defecto |

---

## 📚 Para profundizar

- **Documentación** — TimescaleDB, «Understand hypertables»: tramos y exclusión.
  <https://www.tigerdata.com/docs/learn/hypertables/understand-hypertables>
- **Documentación** — TimescaleDB, «Understand hypercore»: el almacén en columnas y la compresión.
  <https://www.tigerdata.com/docs/learn/columnar-storage/understand-hypercore>
- **Documentación** — TimescaleDB, «Continuous aggregates».
  <https://www.tigerdata.com/docs/learn/continuous-aggregates>
- **Documentación** — TimescaleDB, «Real-time aggregates»: desactivados por defecto desde la 2.13.
  <https://www.tigerdata.com/docs/learn/continuous-aggregates/real-time-aggregates>
- **Documentación** — TimescaleDB, «drop_chunks»: solo tramos enteros.
  <https://www.tigerdata.com/docs/reference/timescaledb/hypertables/drop_chunks>
- **Documentación** — PostgreSQL 18, «Table Partitioning»: el particionado nativo.
  <https://www.postgresql.org/docs/18/ddl-partitioning.html>
- **Documentación** — Prometheus, «Storage»: bloques, retención y sus límites.
  <https://prometheus.io/docs/prometheus/latest/storage/>
- **Documentación** — InfluxDB 3 Core. <https://docs.influxdata.com/influxdb3/core/>

---

## 🧠 Preguntas

1. ¿Qué es una hipertabla, y qué es un tramo? 🟢
2. ¿Qué hace `time_bucket`? 🟢
3. ¿Qué es un agregado continuo? 🟢
4. ¿Qué es el *downsampling*? 🟢
5. Distingue la hipertabla del particionado declarativo de PostgreSQL. 🟡
6. ¿Por qué la hipertabla no admite una clave primaria sin la columna de tiempo? 🟡
7. ¿Qué hacen `segmentby` y `orderby` al comprimir? 🟡
8. ¿Por qué se dejan sin comprimir los tramos más recientes? 🟡
9. ¿Qué dice la documentación de Prometheus sobre su almacenamiento local, y qué implica? 🟡
10. ¿Por qué la consulta de la última semana empató entre la hipertabla y la tabla normal? 🟠
11. ¿Por qué la hipertabla tardó más en cargar y ocupaba más antes de comprimir? 🟠
12. ¿Por qué el agregado del año bajó de 60 ms a 20 al comprimir? 🟠
13. ¿Por qué el evento nuevo no apareció en el agregado continuo hasta el refresco, y qué
    alternativas hay? 🟠
14. ¿Por qué quedó un evento de 2023 tras `drop_chunks` con fecha de 2024? 🟠
15. ¿Por qué el `DELETE` no redujo el tamaño de `eventos_plano`, y qué haría falta? 🟠
16. Diseña el almacenamiento de las métricas de §7: tramo, compresión, agregados y retención, con lo
    que cuesta cada decisión. 🔴
17. Diagnostica: un panel sobre un agregado continuo enseña cero pedidos en la última hora, aunque
    la tabla de eventos tiene cientos. 🔴
18. Defiende o refuta montar InfluxDB para los eventos de la tienda en vez de usar TimescaleDB, con
    los números del capítulo. 🔴

---

**Anterior:** [`03`](03-grafo.md) — grafo · **Siguiente:** [`05`](05-busqueda-de-texto.md) —
búsqueda de texto · **Relacionado:** [`l05`](../13-laboratorio/l05-los-otros-modelos.md) §5 — la
primera hipertabla, en el lab ·
[`04/03`](../04-transacciones-y-concurrencia/03-mvcc-frente-a-bloqueo.md) — por qué `DELETE` deja
filas muertas.
