# 05 — Monitorización y mantenimiento

> Qué se mira en una base en producción y qué se le hace para que siga sana: las consultas que
> acumulan el tiempo, las sesiones que retienen el pasado, las filas muertas y el espacio que no
> vuelve. Medido en PostgreSQL: en diez segundos de carga, una consulta que es el 5 % de las
> llamadas se lleva el 99 % del tiempo; una transacción abierta y olvidada deja 100 000 filas
> muertas que `VACUUM` no puede quitar; y tras quitarlas, la tabla sigue ocupando 15 MB con dos
> tercios libres, hasta que `VACUUM FULL` la deja en 5 MB con la tabla bloqueada. **Asume leído:**
> [`04/03`](../04-transacciones-y-concurrencia/03-mvcc-frente-a-bloqueo.md), MVCC y las versiones
> muertas. **Vigencia:** 27 de septiembre de 2026.

---

## Salto rápido

- [1. El problema](#1--el-problema) · [2. Las consultas que cuestan](#2--las-consultas-que-cuestan)
- [3. La sesión que retiene el pasado](#3--la-sesión-que-retiene-el-pasado) · [4. El espacio que no
  vuelve](#4--el-espacio-que-no-vuelve)
- [5. MySQL: `performance_schema`](#5-️-mysql-performance_schema) · [6. Qué se mira cada
  día](#6--qué-se-mira-cada-día)
- [7. Estándar, motor y convención](#7--estándar-motor-y-convención) · [Errores
  frecuentes](#️-errores-frecuentes) · [Preguntas](#-preguntas)

---

## 1. 🎯 El problema

La tienda va lenta los lunes por la mañana. El primer reflejo es mirar la consulta más lenta del
registro, la que tarda diez segundos una vez al día. Casi nunca es el problema: el problema suele
ser una consulta de 40 ms que se ejecuta mil veces por minuto, que en ningún registro de lentas
aparece.

Y hay un segundo tipo de lentitud, que no está en ninguna consulta: la tabla que crece aunque no se
inserte nada, los índices que ocupan el doble de lo que deberían, las estadísticas que dejan de
reflejar los datos. Es el mantenimiento que hace `VACUUM`, casi siempre solo, y que alguien puede
sabotear sin saberlo con una transacción que se queda abierta.

Este capítulo mide las dos cosas: cómo se encuentra lo que acumula el tiempo, y cómo se ve y se
repara lo que el mantenimiento no alcanzó.

> **📝 Contexto.** Todo se corrió en la copia aislada `bd-lab-prueba` de
> [`01`](01-usuarios-roles-y-permisos.md), **reiniciada con `pg_stat_statements` en
> `shared_preload_libraries`**, que la extensión exige cargar al arrancar y el entorno principal no
> carga. La carga de §2 la genera `pgbench` dentro del contenedor. La consulta de MySQL de §5 lee
> las estadísticas del entorno principal, sin cambiar nada. La sesión de §3 y §4 son dos terminales
> de `psql`, intercaladas con `-- sesión A` y `-- sesión B`. **Longitud:** unas 350 líneas; capítulo
> normal.

---

## 2. 🧱 Las consultas que cuestan

**Qué es:** `pg_stat_statements` es una extensión que acumula, por cada forma de consulta —con los
valores sustituidos por `$1`, `$2`—, cuántas veces se ejecutó, cuánto tiempo sumó y cuánto de media.

**Quién lo manda:** el **motor**. Su documentación dice que hay que añadirla a
`shared_preload_libraries` y **reiniciar el servidor**, porque necesita memoria compartida.

Diez segundos de carga con cuatro clientes: el 95 % de las veces, buscar un pedido por su código; el
5 %, contar los pedidos de un cliente, que no tiene índice en `cliente_id`:

```text
tienda=# CREATE EXTENSION pg_stat_statements;
CREATE EXTENSION
tienda=# SELECT pg_stat_statements_reset() IS NOT NULL AS reiniciado;
 reiniciado 
------------
 t
(1 fila)

tienda=# $ docker exec bd-lab-prueba-postgres pgbench -U postgres -n -c 4 -T 10 -f /tmp/por_codigo.sql@95 -f /tmp/por_cliente.sql@5 tienda 2>&1 | grep -E "^(transaction type|number of transactions actually|latency average|tps|SQL script|  - weight|  - [0-9]+ trans)"
transaction type: multiple scripts
number of transactions actually processed: 19258
latency average = 2.082 ms
tps = 1921.409771 (without initial connection time)
SQL script 1: /tmp/por_codigo.sql
SQL script 2: /tmp/por_cliente.sql
tienda=# SELECT calls, round(total_exec_time) AS total_ms, round(mean_exec_time::numeric, 3) AS medio_ms, left(query, 60) AS consulta FROM pg_stat_statements WHERE query LIKE '%pedidos WHERE%' ORDER BY total_exec_time DESC;
 calls | total_ms | medio_ms |                           consulta                           
-------+----------+----------+--------------------------------------------------------------
   973 |    37883 |   38.935 | SELECT count(*) FROM pedidos WHERE cliente_id = $1
 18285 |      252 |    0.014 | SELECT codigo, estado, total FROM pedidos WHERE codigo = $1 
(2 filas)
```

- **`pgbench`** es el generador de carga de PostgreSQL. `-c 4` son cuatro clientes, `-T 10` diez
  segundos, `-n` no hace `VACUUM` antes, y cada `-f fichero@peso` es un guion con su proporción. El
  `grep` deja el resumen. La línea del `$` es la orden de shell lanzada entre dos consultas.
- **`por_codigo.sql`** elige un número al azar con `\set` y busca `PED-` más ese número;
  **`por_cliente.sql`**, un cliente al azar y cuenta sus pedidos.
- **973 llamadas y 37 883 ms; 18 285 llamadas y 252 ms.** La consulta sin índice es el **5 % de las
  llamadas y el 99 % del tiempo**: 39 ms de media, mil veces más que la otra. Un registro de
  consultas lentas con el umbral en 100 ms no la vería nunca.
- **Se ordena por `total_exec_time`, no por `mean_exec_time`**: lo que importa es lo que suma, no lo
  que tarda una vez. La corrección de esta, un índice en `pedidos (cliente_id)`, es la de
  [`03/02`](../03-el-motor-por-dentro/02-familias-de-indices.md) y los labs.

> **Veredicto:** las consultas que cuestan se buscan por tiempo total. La más lenta del registro
> rara vez es la que más carga la base.

---

## 3. 🩺 La sesión que retiene el pasado

Una sesión abre una transacción, lee un pedido y se queda así: un informe a medias, un depurador
parado, una conexión que la aplicación no devolvió. Mientras, la otra sesión actualiza todos los
clientes dos veces y pasa `VACUUM`:

```text
-- sesión B
tienda=# CREATE EXTENSION pgstattuple;
CREATE EXTENSION
-- sesión A
tienda=# BEGIN ISOLATION LEVEL REPEATABLE READ;
BEGIN
tienda=*# SELECT total FROM pedidos WHERE codigo = 'PED-00042';
  total  
---------
 3186.23
(1 fila)

-- sesión B
tienda=# SELECT pid, state, backend_xmin, now() - xact_start AS en_transaccion FROM pg_stat_activity WHERE state LIKE 'idle in%';
 pid |        state        | backend_xmin | en_transaccion  
-----+---------------------+--------------+-----------------
 170 | idle in transaction |          858 | 00:00:03.008973
(1 fila)

tienda=# UPDATE clientes SET nombre = nombre;
UPDATE 50000
tienda=# UPDATE clientes SET nombre = nombre;
UPDATE 50000
tienda=# VACUUM clientes;
VACUUM
tienda=# SELECT pg_stat_force_next_flush();
 pg_stat_force_next_flush 
--------------------------
 
(1 fila)

tienda=# SELECT n_live_tup, n_dead_tup, pg_size_pretty(pg_table_size('clientes')) AS tam FROM pg_stat_user_tables WHERE relname = 'clientes';
 n_live_tup | n_dead_tup |  tam  
------------+------------+-------
      50000 |     100000 | 15 MB
(1 fila)
```

- **`idle in transaction`**: la sesión no hace nada, pero tiene una transacción abierta desde hace
  tres segundos. **`backend_xmin`** es la transacción más antigua que esa sesión necesita seguir
  viendo: su instantánea.
- **`REPEATABLE READ`** a propósito: guarda la instantánea hasta el final de la transacción. En
  `READ COMMITTED`, una transacción que solo leyó suelta su instantánea al acabar cada sentencia y
  no retiene nada; con una escritura, sí retendría.
- **Dos `UPDATE` de 50 000 filas dejan 100 000 versiones muertas**, y **`VACUUM` no quitó ninguna**:
  la sesión `A` todavía podría necesitarlas, porque su instantánea es anterior. La tabla pasó de 5 a
  15 MB.
- **`pg_stat_force_next_flush()`** vuelca ya las estadísticas de esta sesión. Sin él, la
  documentación avisa de que cada proceso las publica como mucho una vez por segundo, y `n_dead_tup`
  podría salir a cero todavía.

> **⚠️ Advertencia.** Una sola transacción olvidada detiene la limpieza de **toda la base**, no solo
> de las tablas que tocó. Se vigila `pg_stat_activity` por `idle in transaction` y por la edad de
> `xact_start`, y se pone un límite con `idle_in_transaction_session_timeout`.

---

## 4. 🩺 El espacio que no vuelve

La sesión `A` termina, y `VACUUM` ya puede limpiar:

```text
-- sesión A
tienda=*# ROLLBACK;
ROLLBACK
-- sesión B
tienda=# VACUUM clientes;
VACUUM
tienda=# SELECT pg_stat_force_next_flush();
 pg_stat_force_next_flush 
--------------------------
 
(1 fila)

tienda=# SELECT n_live_tup, n_dead_tup, pg_size_pretty(pg_table_size('clientes')) AS tam FROM pg_stat_user_tables WHERE relname = 'clientes';
 n_live_tup | n_dead_tup |  tam  
------------+------------+-------
      50000 |          0 | 15 MB
(1 fila)

tienda=# SELECT round(free_percent::numeric, 1) AS libre_pct FROM pgstattuple('clientes');
 libre_pct 
-----------
      66.7
(1 fila)

tienda=# VACUUM FULL clientes;
VACUUM
tienda=# SELECT pg_size_pretty(pg_table_size('clientes')) AS tam;
   tam   
---------
 5264 kB
(1 fila)
```

- **Cero filas muertas, y la tabla sigue en 15 MB.** `VACUUM` marca el espacio como reutilizable
  dentro de la tabla, pero no lo devuelve al sistema, salvo las páginas vacías del final, como midió
  [`04/03`](../04-transacciones-y-concurrencia/03-mvcc-frente-a-bloqueo.md). **`pgstattuple`** lo
  cuantifica: el 66,7 % de la tabla está libre. Eso es la **hinchazón**.
- **`VACUUM FULL`** reescribe la tabla entera en un fichero nuevo: 5 264 kB, un tercio. Su precio lo
  dice la documentación: necesita un bloqueo `ACCESS EXCLUSIVE`, así que la tabla no se puede usar
  mientras dura, y es mucho más lento que el normal.
- **Cuándo cada uno**: el `VACUUM` normal, siempre, y casi siempre lo hace el *autovacuum* solo; el
  espacio libre lo reutilizarán las próximas escrituras. `VACUUM FULL`, solo si la tabla no va a
  volver a crecer y se puede parar; si no, se usan herramientas que reescriben la tabla sin
  bloquearla. Para un índice hinchado, `REINDEX CONCURRENTLY`.

**El *autovacuum*** lanza `VACUUM` y `ANALYZE` solo cuando una tabla acumula cambios. Sus umbrales
son proporcionales al tamaño de la tabla, así que en tablas muy grandes espera muchas filas muertas
antes de actuar, y se ajustan tabla a tabla. Lo que nunca puede hacer es limpiar lo que una sesión
abierta retiene, que es §3.

---

## 5. ⚖️ MySQL: `performance_schema`

MySQL acumula lo mismo en `performance_schema`, también por forma de consulta. Sobre el entorno
principal:

```text
mysql> SELECT COUNT_STAR AS llamadas, ROUND(SUM_TIMER_WAIT / 1e12, 1) AS total_s, SUM_ROWS_EXAMINED AS filas_examinadas, LEFT(DIGEST_TEXT, 55) AS consulta FROM performance_schema.events_statements_summary_by_digest WHERE SCHEMA_NAME = 'tienda' ORDER BY SUM_TIMER_WAIT DESC LIMIT 3;
+----------+---------+------------------+---------------------------------------------------------+
| llamadas | total_s | filas_examinadas | consulta                                                |
+----------+---------+------------------+---------------------------------------------------------+
|        3 |      39 |         53514744 | SELECT `LPAD` ( `orden` , ?, ... ) AS ? , `comprobacion |
|        1 |     3.6 |          4100000 | SELECT SQL_NO_CACHE * FROM `eventos_pedido`             |
|        1 |     0.9 |          3500000 | SELECT SQL_NO_CACHE * FROM `pedido_lineas`              |
+----------+---------+------------------+---------------------------------------------------------+
3 rows in set (0.012 sec)
```

- **`events_statements_summary_by_digest`** agrupa por el *digest*, la consulta normalizada con `?`
  en lugar de los valores. **`SUM_TIMER_WAIT`** está en picosegundos, de ahí el `1e12`.
- **Lo que más pesó en la base de la tienda** son las tres ejecuciones de `verificar-mysql.sql` de
  este corpus —39 s y 53 millones de filas examinadas— y los `SELECT *` de `mysqldump` de
  [`02`](02-respaldos-y-recuperacion.md). **`SUM_ROWS_EXAMINED`** es la columna que delata una
  consulta sin índice: muchas filas examinadas por cada una devuelta.

---

## 6. 🧭 Qué se mira cada día

| Qué | Dónde en PostgreSQL | Qué indica |
|---|---|---|
| Consultas por tiempo total | `pg_stat_statements` | Qué indexar o reescribir primero |
| Sesiones `idle in transaction` y su edad | `pg_stat_activity` | Quién frena `VACUUM` y retiene bloqueos |
| Esperas de bloqueo | `pg_stat_activity` y `pg_blocking_pids` | Colas como la de [`04`](04-expandir-contraer.md) §3 |
| Conexiones frente al máximo | `pg_stat_activity` y `max_connections` | Un *pool* mal dimensionado, [`10/01`](../10-interfaz-con-los-lenguajes/01-el-driver-la-conexion-y-el-pool.md) |
| Filas muertas y último *autovacuum* | `pg_stat_user_tables` | Tablas que el *autovacuum* no alcanza |
| Hinchazón | `pgstattuple` | Espacio que no vuelve sin reescribir |
| Respaldos verificados | `pg_verifybackup`, [`02`](02-respaldos-y-recuperacion.md) | Que el respaldo existe de verdad |

**Cuánto cuesta**: `pg_stat_statements` añade un poco de trabajo a cada consulta y memoria
compartida, y necesita un reinicio para activarse; por eso se deja activado desde el primer día, y
no se descubre el día del problema.

---

## 7. 📜 Estándar, motor y convención

> **📜 Estándar o motor.** El estándar SQL no dice nada de estadísticas de ejecución ni de
> mantenimiento. `pg_stat_statements`, `pg_stat_activity`, `VACUUM` y `performance_schema` son de
> cada motor; la lista de lo que se mira cada día es convención de operación.

| Afirmación | Categoría | PostgreSQL 18 | MySQL 9.7 |
|---|---|---|---|
| Estadísticas acumuladas por forma de consulta | Motor | `pg_stat_statements`, con reinicio | `performance_schema`, activo |
| Una transacción abierta frena la limpieza | Motor | Sí: 100 000 filas muertas sin quitar | — |
| La limpieza normal devuelve el espacio | Motor | No: 15 MB con el 66,7 % libre | — |
| Reescribir la tabla la bloquea | Motor | Sí, `VACUUM FULL`: `ACCESS EXCLUSIVE` | — |
| Las estadísticas se ven al instante | Motor | No: como mucho cada segundo | — |
| Buscar por tiempo total, no por el más lento | Convención | — | — |

**Convención, la que más se repite.** *«La base va lenta, hay que darle más máquina»* — en diez
segundos de carga, un índice que faltaba explicaba el 99 % del tiempo. Antes de más máquina, la
lista de §6.

---

## ⚠️ Errores frecuentes

| Se dice | Lo preciso |
|---|---|
| "La consulta problemática es la más lenta del registro" | Fue la de 39 ms: 5 % de las llamadas y 99 % del tiempo |
| "`pg_stat_statements` se activa con `CREATE EXTENSION`" | Hay que cargarla al arrancar y reiniciar |
| "Una sesión que solo lee no molesta" | En `REPEATABLE READ` retuvo 100 000 filas muertas frente a `VACUUM` |
| "`VACUUM` libera espacio en disco" | Dejó la tabla en 15 MB con el 66,7 % libre |
| "Si la tabla está hinchada, `VACUUM FULL` y listo" | Reescribe la tabla con `ACCESS EXCLUSIVE`: nadie la usa mientras tanto |
| "Las estadísticas son al momento" | Se publican como mucho cada segundo por proceso |
| "El *autovacuum* lo arregla todo" | No puede limpiar lo que una transacción abierta retiene |

---

## 📚 Para profundizar

- **Documentación** — PostgreSQL 18, «pg_stat_statements».
  <https://www.postgresql.org/docs/18/pgstatstatements.html>
- **Documentación** — PostgreSQL 18, «The Cumulative Statistics System»: `pg_stat_activity` y el
  retraso de las estadísticas. <https://www.postgresql.org/docs/18/monitoring-stats.html>
- **Documentación** — PostgreSQL 18, «Routine Vacuuming»: `VACUUM`, `VACUUM FULL` y el
  *autovacuum*. <https://www.postgresql.org/docs/18/routine-vacuuming.html>
- **Documentación** — PostgreSQL 18, «REINDEX»: la reconstrucción concurrente.
  <https://www.postgresql.org/docs/18/sql-reindex.html>
- **Documentación** — MySQL 9.7, «Statement Summary Tables» de `performance_schema`.
  <https://dev.mysql.com/doc/refman/9.7/en/performance-schema-statement-summary-tables.html>

---

## 🧠 Preguntas

1. ¿Qué acumula `pg_stat_statements`, y por forma de qué? 🟢
2. ¿Qué significa `idle in transaction`? 🟢
3. ¿Qué es la hinchazón de una tabla? 🟢
4. ¿Qué hace el *autovacuum*? 🟢
5. ¿Por qué `pg_stat_statements` exige reiniciar el servidor? ¿Lo fija el estándar o es cosa del
   motor? 🟡
6. Distingue `total_exec_time` de `mean_exec_time`, y di por cuál se ordena. ¿Qué parte es del motor
   y qué parte es convención? 🟡
7. ¿Qué es `backend_xmin`? 🟡
8. Distingue `VACUUM` de `VACUUM FULL`: qué hace cada uno y qué bloquea. 🟡
9. ¿Qué indica `SUM_ROWS_EXAMINED` en MySQL? 🟡
10. ¿Por qué la consulta del 5 % de las llamadas se llevó el 99 % del tiempo, y por qué no saldría
    en un registro de lentas? 🟠
11. ¿Por qué `VACUUM` no quitó las 100 000 filas muertas mientras la sesión `A` estaba abierta? 🟠
12. ¿Por qué la sesión `A` retuvo filas en `REPEATABLE READ` y no las habría retenido en
    `READ COMMITTED` solo leyendo? 🟠
13. ¿Por qué la tabla siguió en 15 MB tras un `VACUUM` que dejó cero filas muertas? 🟠
14. ¿Por qué `n_dead_tup` puede salir a cero justo después de un `UPDATE` masivo? 🟠
15. ¿Qué harías con una tabla hinchada que no se puede parar? 🟠
16. Diseña el panel de salud diario de la base de la tienda: qué consultas, con qué umbrales y qué
    alertas. 🔴
17. Diagnostica: la base crece 2 GB al día aunque apenas se insertan pedidos, y el *autovacuum*
    corre sin errores. 🔴
18. Defiende o refuta «si la base va lenta, lo primero es subirle la máquina», con los números del
    capítulo. 🔴

---

**Anterior:** [`04`](04-expandir-contraer.md) — expandir y contraer · **Siguiente:**
[`06`](06-simulacion-de-entrevista.md) — la simulación del bloque · **Relacionado:**
[`04/03`](../04-transacciones-y-concurrencia/03-mvcc-frente-a-bloqueo.md) — MVCC y las versiones
muertas.
