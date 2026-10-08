# 06 — WAL, durabilidad y `fsync`

> Qué significa exactamente «confirmado», que es el cabo que [`01`](01-acid-con-precision.md) §6
> dejó abierto a propósito. Aquí se ve el WAL por dentro con `pg_waldump`, se mata el servidor
> después de un `COMMIT` para ver cómo se recupera, **se pierde una confirmación a propósito** con
> `synchronous_commit = off`, y se mide lo que cuesta esperar al disco. **Asume leído:**
> [`01`](01-acid-con-precision.md) — de ahí vienen las cuatro letras y la tabla de los tres
> parámetros, que aquí se explican por dentro. **Vigencia:** 22 de septiembre de 2026.

---

## Salto rápido

- [1. El problema](#1--el-problema) · [2. Escribir antes en el
  registro](#2--escribir-antes-en-el-registro)
- [3. Qué hace el motor después de un corte](#3--qué-hace-el-motor-después-de-un-corte) · [4. La
  palanca: synchronous_commit](#4-️-la-palanca-synchronous_commit)
- [5. Checkpoints y páginas rotas](#5--checkpoints-y-páginas-rotas) · [6. El disco que
  miente](#6--el-disco-que-miente)
- [7. Lo que la D no cubre: otra máquina](#7--lo-que-la-d-no-cubre-otra-máquina) · [8. Estándar,
  motor y convención](#8--estándar-motor-y-convención)
- [Errores frecuentes](#️-errores-frecuentes) · [Para profundizar](#-para-profundizar) ·
  [Preguntas](#-preguntas)

---

## 1. 🎯 El problema

El servicio de pagos registra un cobro, recibe `COMMIT` del motor y le dice al cliente «pagado». Un
segundo después se va la luz del centro de datos. Al volver, alguien pregunta lo único que importa:
**¿está el pago?**

La respuesta «sí, porque se confirmó» es la recitada, y está incompleta de tres maneras. Depende de
que el `COMMIT` esperara de verdad al disco, que es un parámetro. Depende de que el disco no
mintiera al decir que había escrito. Y aunque las dos cosas fueran bien, el pago está en el disco de
**ese** servidor, que puede no volver.

```text
¿Qué tiene que estar en disco para que el motor diga COMMIT?
¿Cómo reconstruye la tabla si la página nunca llegó a escribirse?
¿Qué se pierde, exactamente, si le pides que no espere?
```

> **📝 Contexto.** Todo lo de este capítulo está **corrido contra el entorno**, incluidas las caídas:
> §3 mata el contenedor de PostgreSQL con `SIGKILL` y §4 mata un proceso del servidor desde dentro.
> Las posiciones del WAL, los `PID` y las horas cambian en cada corrida, y **los microsegundos de §4
> y §6 son de esta máquina**, un contenedor sobre un portátil: lo que se lee es la proporción. Lo
> único que el entorno **no puede producir** es un corte de corriente de verdad, y §6 dice con qué
> se vería. **Longitud:** capítulo de banda normal que cierra en 498 líneas, pasado el disparador de
> 400. Se podó prosa en seis sitios y no lleva `🔭 Dónde aparece de verdad`; lo que queda por encima
> son los dos logs de recuperación de §3 y §4, que son la evidencia y no se recortan.

---

## 2. 🧱 Escribir antes en el registro

**Qué es:** la regla del WAL —*write-ahead log*, registro de escritura anticipada— en una frase:
**ningún cambio llega a la página de la tabla en disco antes de que su descripción haya llegado al
registro en disco**. El registro es un fichero que solo crece por el final, así que escribir en él
es secuencial y barato; las páginas de la tabla se escriben después, cuando al motor le convenga.

Cada posición del registro tiene una dirección, el LSN (*log sequence number*), y el motor distingue
dos: **hasta dónde ha anotado** en memoria y **hasta dónde está en disco**.

```text
tienda=# SELECT pg_current_wal_lsn() AS antes, pg_walfile_name(pg_current_wal_lsn()) AS fichero;
   antes    |         fichero
------------+--------------------------
 2/1ED05288 | 00000001000000020000001E
(1 fila)

tienda=# BEGIN;
BEGIN
tienda=*# UPDATE pedidos SET estado = 'PENDIENTE' WHERE codigo = 'PED-99999';
UPDATE 1
tienda=*# SELECT pg_current_wal_insert_lsn() AS insertado, pg_current_wal_flush_lsn() AS en_disco;
 insertado  |  en_disco
------------+------------
 2/1ED052F8 | 2/1ED05288
(1 fila)

tienda=*# COMMIT;
COMMIT
tienda=# SELECT pg_current_wal_insert_lsn() AS insertado, pg_current_wal_flush_lsn() AS en_disco;
 insertado  |  en_disco
------------+------------
 2/1ED05320 | 2/1ED05320
(1 fila)

tienda=# UPDATE pedidos SET estado = 'ANULADO' WHERE codigo = 'PED-99999';   -- compensación
UPDATE 1
tienda=# SELECT pg_current_wal_lsn() AS despues;
  despues
------------
 2/1ED053A8
(1 fila)
```

- **Antes del `COMMIT`, el `UPDATE` está anotado y no está en disco**: la posición insertada va por
  `2/1ED052F8` y la volcada sigue en `2/1ED05288`, la de partida. Si el servidor cayera ahí, ese
  cambio no existiría, y está bien que no exista: nadie lo confirmó.
- **Justo después del `COMMIT`, las dos posiciones coinciden.** Eso es lo que compra el `COMMIT`:
  que todo lo anotado hasta su propio registro esté en disco antes de responder. Lo que **no** está
  en disco todavía es la página 10769 de `pedidos`, y no hace falta.

Qué hay dentro de esos bytes lo dice `pg_waldump`, que viene con el servidor:

```bash
docker exec -u postgres bd-lab-postgres pg_waldump -p /var/lib/postgresql/data/pg_wal \
  -s 2/1ED05288 -e 2/1ED053A8
```

- `docker exec -u postgres bd-lab-postgres` corre la herramienta dentro del contenedor, con el
  usuario dueño de los ficheros de datos.
- `-p …/pg_wal` es el directorio donde viven los segmentos del registro; `-s` y `-e` acotan el tramo
  entre las posiciones de antes y después de la sesión.

```text
rmgr: Heap        len (rec/tot):    109/   109, tx:       1061, lsn: 2/1ED05288, prev 2/1ED05250, desc: HOT_UPDATE old_xmax: 1061, old_off: 12, old_infobits: [], flags: 0x61, new_xmax: 0, new_off: 11, blkref #0: rel 1663/16384/16654 blk 10769, blkref #3: rel 1663/16384/16654 fork vm blk 0
rmgr: Transaction len (rec/tot):     34/    34, tx:       1061, lsn: 2/1ED052F8, prev 2/1ED05288, desc: COMMIT 2026-09-23 02:23:44.393764 UTC
rmgr: Heap        len (rec/tot):     93/    93, tx:       1062, lsn: 2/1ED05320, prev 2/1ED052F8, desc: HOT_UPDATE old_xmax: 1062, old_off: 11, old_infobits: [], flags: 0x60, new_xmax: 0, new_off: 13, blkref #0: rel 1663/16384/16654 blk 10769
rmgr: Transaction len (rec/tot):     34/    34, tx:       1062, lsn: 2/1ED05380, prev 2/1ED05320, desc: COMMIT 2026-09-23 02:23:44.404916 UTC
```

- **Cuatro registros, dos por transacción**: un `HOT_UPDATE` que describe la versión nueva de la
  fila en el bloque 10769 —la actualización HOT de [`03`](03-mvcc-frente-a-bloqueo.md) §3, sin
  entrada de índice— y un `COMMIT` de 34 bytes con la hora. **El `COMMIT` es un registro más**, y la
  transacción está confirmada cuando ese registro está en disco, no antes.
- **El tamaño se lee en las posiciones**: el `UPDATE` avanzó el registro 112 bytes —sus 109 más el
  relleno hasta múltiplo de 8— y el `COMMIT`, 40. Lo que [`01`](01-acid-con-precision.md) §6 solo
  podía medir desde fuera, aquí tiene nombre.

**Quién lo manda:** **motor**, entero. El estándar exige que lo confirmado persista y no dice cómo;
los tres motores del corpus usan un registro anticipado, con nombres distintos (§8).

**Cuánto cuesta:** cada cambio se escribe **dos veces**, una en el registro y otra en la página; lo
que se gana es que la segunda puede esperar y agruparse. **Cuándo duele:** en escrituras masivas,
donde el volumen de WAL es del orden del de los datos (§5).

> **Veredicto:** «confirmado» no significa «escrito en la tabla». Significa **«descrito en un
> registro que está en disco»**, y con eso basta para reconstruir la tabla después.

---

## 3. 🩺 Qué hace el motor después de un corte

**Qué es:** la recuperación (*crash recovery*). Al arrancar, el motor mira el último punto de
control (§5), **vuelve a aplicar** el registro desde ahí hasta el final, y deja cada página como
estaba en el último `COMMIT`. Se ve matando el servidor justo después de confirmar:

```bash
psql -h 127.0.0.1 -U postgres -d tienda \
  -c "UPDATE pedidos SET estado = 'PENDIENTE' WHERE codigo = 'PED-99999';" \
  && docker kill bd-lab-postgres
docker start bd-lab-postgres
```

- `&&` encadena la muerte al éxito del `UPDATE`: el contenedor recibe `SIGKILL` en cuanto `psql`
  devuelve `UPDATE 1`, sin apagado ordenado ni punto de control.
- `docker start` vuelve a levantar el mismo contenedor sobre el mismo volumen: los ficheros de datos
  están tal cual los dejó el proceso muerto.

```text
UPDATE 1
bd-lab-postgres
bd-lab-postgres
LOG:  database system was interrupted; last known up at 2026-09-23 02:22:08 UTC
LOG:  database system was not properly shut down; automatic recovery in progress
LOG:  redo starts at 2/16AE2F48
LOG:  invalid record length at 2/2011F430: expected at least 24, got 0
LOG:  redo done at 2/2011F408 system usage: CPU: user: 0.22 s, system: 0.30 s, elapsed: 0.54 s
LOG:  checkpoint starting: end-of-recovery immediate wait
LOG:  checkpoint complete: wrote 17208 buffers (52.5%), wrote 7 SLRU buffers; 0 WAL file(s) added, 10 removed, 0 recycled; write=0.582 s, sync=0.046 s, total=0.694 s; sync files=16, longest=0.040 s, average=0.003 s; distance=153841 kB, estimate=153841 kB; lsn=2/2011F430, redo lsn=2/2011F430
LOG:  database system is ready to accept connections

tienda=# SELECT estado FROM pedidos WHERE codigo = 'PED-99999';
  estado
-----------
 PENDIENTE
(1 fila)
```

- **El cambio confirmado está**, aunque el proceso murió sin escribir la página. La compensación va
  inmediatamente después, como pide el [README del bloque](README.md), y devuelve `ANULADO`.
- **El log está recortado de dos formas, y solo de dos**: se quitaron la hora y el `PID` del
  principio de cada línea, y las cinco líneas de arranque que preceden a la recuperación. `invalid
  record length … got 0` no es un error: es el final del registro, donde la recuperación deja de
  leer.
- **Rehízo unos 150 MB de registro en 0,54 s** —`distance=153841 kB`—: todo lo escrito desde el
  último punto de control, que en esta corrida incluía el `VACUUM` de `05` y la medición de
  `pgbench` de §4. Ese tramo es lo que decide cuánto tarda en volver un servidor caído (§5).

**Cuánto cuesta:** nada mientras todo va bien; al caer, **el tiempo de rehacer**, que crece con la
distancia al último punto de control. **Quién lo manda:** motor; InnoDB hace lo mismo con su *redo
log* y SQLite con su diario (§8). El mismo rehacer, hasta un instante elegido, es §5 de
[`l03`](../13-laboratorio/l03-respaldo-y-restauracion.md#5--paso-4--la-recuperación-a-un-instante).

---

## 4. ⚖️ La palanca: synchronous_commit

**Qué es:** el parámetro que decide si el `COMMIT` espera a que su registro esté en disco. En `on`,
el de fábrica, espera. En `off`, **responde en cuanto lo anota en memoria**, y un proceso de fondo
—el *WAL writer*— lo vuelca poco después: según la documentación, la ventana máxima es **tres veces
`wal_writer_delay`**, que vale 200 ms en el entorno, así que 600 ms.

Cuánto se gana, medido con `pgbench` sobre una sola conexión que confirma diez segundos seguidos un
`UPDATE` de `PED-99999` que no cambia el valor:

```bash
docker exec -u postgres -e PGOPTIONS="-c synchronous_commit=off" bd-lab-postgres \
  pgbench -n -f /tmp/confirmar.sql -c 1 -T 10 tienda
```

- `PGOPTIONS` fija el parámetro para las conexiones de `pgbench`, sin tocar el servidor; la corrida
  de `on` es la misma línea con el otro valor.
- `-n` no hace `VACUUM` previo —`pgbench` lo intenta sobre sus propias tablas, que aquí no existen—;
  `-f` es el guion, de una sola línea: `UPDATE pedidos SET estado = 'ANULADO' WHERE codigo =
  'PED-99999';`; `-c 1 -T 10`, un cliente durante diez segundos.

| `synchronous_commit` | Transacciones en 10 s | Latencia media | Transacciones por segundo |
|---|---|---|---|
| `on` | 55 349 | 0,181 ms | 5 535,58 |
| `off` | 115 209 | 0,087 ms | 11 522,10 |

- **El doble de confirmaciones por segundo**, y la diferencia de latencia, 0,094 ms, es lo que tarda
  aquí esperar al disco en cada `COMMIT`. En un disco sin caché protegida esa espera puede ser de
  milisegundos, y entonces la proporción ya no es el doble (§6).

**Y lo que se pierde, provocado.** Para perder algo hay que caer **dentro** de esos 600 ms, así que
el proceso se mata desde el propio servidor en la sentencia siguiente, con `COPY … TO PROGRAM`, que
ejecuta una orden del sistema como el usuario del servidor. El log va recortado igual que en §3:

```text
$ psql -h 127.0.0.1 -U postgres -d tienda -c "SELECT estado FROM pedidos WHERE codigo = 'PED-99999';"
 estado
---------
 ANULADO
(1 fila)

$ psql -h 127.0.0.1 -U postgres -d tienda -c "SET synchronous_commit = off" \
    -c "UPDATE pedidos SET estado = 'PENDIENTE' WHERE codigo = 'PED-99999'" \
    -c "COPY (SELECT 1) TO PROGRAM 'kill -9 \$PPID'"
SET
UPDATE 1
el servidor ha cerrado la conexión inesperadamente
	Probablemente se debe a que el servidor terminó de manera anormal
	antes o durante el procesamiento de la petición.
se ha perdido la conexión al servidor

LOG:  client backend (PID 1325) was terminated by signal 9: Killed
DETAIL:  Failed process was running: COPY (SELECT 1) TO PROGRAM 'kill -9 $PPID'
LOG:  terminating any other active server processes
LOG:  untracked child process (PID 1326) exited with exit code 0
LOG:  all server processes terminated; reinitializing
LOG:  database system was interrupted; last known up at 2026-09-23 02:36:13 UTC
LOG:  database system was not properly shut down; automatic recovery in progress
LOG:  redo starts at 2/20152930
LOG:  invalid record length at 2/201537D8: expected at least 24, got 0
LOG:  redo done at 2/201537B0 system usage: CPU: user: 0.00 s, system: 0.00 s, elapsed: 0.00 s
LOG:  checkpoint starting: end-of-recovery immediate wait
LOG:  checkpoint complete: wrote 1 buffers (0.0%), wrote 2 SLRU buffers; 0 WAL file(s) added, 0 removed, 0 recycled; write=0.002 s, sync=0.001 s, total=0.007 s; sync files=4, longest=0.001 s, average=0.001 s; distance=3 kB, estimate=3 kB; lsn=2/201537D8, redo lsn=2/201537D8
LOG:  database system is ready to accept connections

$ psql -h 127.0.0.1 -U postgres -d tienda -c "SELECT estado FROM pedidos WHERE codigo = 'PED-99999';"
 estado
---------
 ANULADO
(1 fila)
```

- **`psql` dijo `UPDATE 1` y el cambio no existe.** Esa es la frase del capítulo: con `off`, el
  cliente recibe confirmación de algo que el motor todavía no ha puesto a salvo.
- **Varias `-c` son varias transacciones** en la misma conexión, sin viaje de ida y vuelta entre
  ellas: es lo que mete la caída dentro de la ventana. `kill -9 $PPID` mata el proceso del propio
  servidor que atendía la sesión, y **PostgreSQL trata la muerte de cualquier proceso hijo como una
  caída**: reinicia todos y descarta la memoria compartida, con los búferes de WAL no volcados
  dentro.
- **No se pierde siempre, y eso es lo honesto.** En esta tanda, con `off` se perdió el cambio en **8
  de 12** caídas provocadas; con `on`, en **0 de 8**. La base no quedó rota en ninguna: la
  recuperación terminó limpia y lo perdido fue la transacción entera, no media.

> **💡 Truco.** `synchronous_commit` se puede cambiar **por transacción**, con `SET LOCAL
> synchronous_commit = off` dentro del `BEGIN`. Es la respuesta de una línea a «¿relajamos la
> durabilidad?»: los eventos de navegación pueden permitírselo, los `pagos` no, y los dos viven en
> la misma base.

**Quién lo manda:** motor. **Cuánto cuesta relajarla:** riesgo de pérdida de las últimas
transacciones confirmadas, nunca corrupción. **Cuándo sí:** datos que se pueden volver a generar o
perder sin daño. **Cuándo no:** todo lo que alguien más ya ha visto como hecho —el cliente al que se
le dijo «pagado»—.

> **Veredicto:** `off` no hace el disco más rápido: hace que el `COMMIT` diga que sí antes de que
> sea verdad. Se paga en transacciones enteras y recientes, y solo se acepta donde perderlas no
> tiene a nadie esperando al otro lado.

---

## 5. 🧱 Checkpoints y páginas rotas

**Qué es:** el punto de control (*checkpoint*) es el momento en que el motor **escribe en la tabla
todas las páginas modificadas** y anota que el registro anterior ya no hace falta para recuperar.
Sin él, el registro crecería para siempre y rehacer tras una caída empezaría desde el principio de
los tiempos. PostgreSQL lanza uno cada `checkpoint_timeout` —**5 min**— o al acumular `max_wal_size`
—**1 GB**—, lo que llegue antes.

**El problema que resuelve la página entera.** Una página de PostgreSQL son 8 kB y el sistema de
ficheros puede escribirla en trozos de 4 kB. Si la luz se va entre los dos, en disco queda una
**página rota** (*torn page*): media nueva, media vieja, y ningún registro del WAL sabe arreglarla,
porque todos describen cambios sobre una página sana. La defensa de PostgreSQL es
`full_page_writes`, **`on`** en el entorno: **la primera vez que se modifica una página después de
un punto de control, el WAL guarda la página entera**, y la recuperación parte de esa copia.

- **Se ve en el precio.** El `VACUUM (VERBOSE)` que se corrió para medir el horizonte de `05`
  escribió `19806 records, 18049 full page images, 135941599 bytes` de WAL: casi todo el volumen
  fueron páginas enteras, porque tocaba miles de páginas que no se habían tocado desde el último
  punto de control. Son la mayor parte de los 150 MB que la recuperación de §3 tuvo que rehacer.
- **InnoDB resuelve lo mismo por otro camino**: el *doublewrite buffer* escribe cada página primero
  en una zona aparte y después en su sitio, y la recuperación usa la copia sana de las dos.
  `innodb_doublewrite` está **`ON`** en MySQL 9.7.2 y en MariaDB 12.3.3.

**Cuánto cuesta:** puntos de control frecuentes dan recuperaciones cortas y **más páginas enteras en
el WAL**; espaciados, lo contrario. **Cuándo no se toca:** `full_page_writes`, cuyo ahorro se paga
con una corrupción invisible hasta el día del corte.

> **🧠 Modelo mental.** El registro dice **qué cambió**; el punto de control dice **desde dónde hay
> que leer el registro**; la página entera dice **sobre qué se aplica**. Las tres piezas hacen falta
> para que «confirmado» sobreviva a un corte a mitad de escritura.

---

## 6. 🩺 El disco que miente

**Qué es:** el último eslabón. Todo lo anterior descansa en que `fsync` —o `fdatasync`, que es el
método del entorno, `wal_sync_method = fdatasync`— **no vuelva hasta que el dato esté en un sitio
que sobrevive a un corte**. Y entre el sistema operativo y el plato o las celdas hay cachés que
pueden responder «hecho» antes de tiempo.

`pg_test_fsync` mide cuánto tarda de verdad cada método sobre el disco del servidor. Corrida sobre
el volumen de datos del entorno —esta es la primera de sus cinco secciones; las demás comparan
tamaños de escritura y no cambian la conclusión—:

```text
Compare file sync methods using one 8kB write:
(in "wal_sync_method" preference order, except fdatasync is Linux's default)
        open_datasync                     10967.570 ops/sec      91 usecs/op
        fdatasync                          9345.888 ops/sec     107 usecs/op
        fsync                              5787.406 ops/sec     173 usecs/op
        fsync_writethrough                              n/a
        open_sync                          5932.129 ops/sec     169 usecs/op
```

- **107 µs por `fdatasync` son unos 9 300 volcados por segundo**, del mismo orden que los 0,094 ms
  de diferencia de §4. Un número así solo es posible si alguien responde desde una caché: o una
  **con protección ante cortes** —batería o condensadores, y entonces es legítimo—, o una
  **volátil**, y entonces el `COMMIT` confirmado puede desaparecer en un corte aunque
  `synchronous_commit` esté en `on`.
- **`pg_test_fsync` mide velocidad, no verdad**, y aquí hay además una virtualización entre el
  contenedor y el disco del portátil cuya garantía no he verificado. Lo que distingue los dos casos
  es **cortar la corriente de verdad** en plena carga —la documentación remite a `diskchecker.pl`—,
  y el entorno del corpus no puede hacerlo.

> **⚠️ Advertencia.** La documentación de PostgreSQL lo dice sin rodeos: muchos SSD **no respetan
> las órdenes de vaciado de caché** por defecto, y los discos de consumo suelen tener caché de
> escritura volátil. En un servidor de verdad, la pregunta «¿el disco tiene caché protegida?» es
> parte de la respuesta a «¿es durable?», y no la contesta ningún parámetro del motor.

**Quién lo manda:** **ni el estándar ni el motor**: es del sistema operativo y del hardware, y es la
razón de que la D de ACID sea una promesa condicionada. **Cuánto cuesta hacerlo bien:** un disco con
caché protegida, o la latencia de un `fsync` real en cada confirmación.

---

## 7. 🧱 Lo que la D no cubre: otra máquina

**Qué es:** la durabilidad de un `COMMIT` acaba en el disco de **un** servidor. Si ese servidor no
vuelve —el disco muere, el centro de datos se inunda—, lo confirmado se perdió con él, por mucho
`fsync` que hubiera. Que el dato esté en dos máquinas es replicación, y en PostgreSQL se pide
aparte:

| `synchronous_commit` con réplica síncrona | El `COMMIT` espera a que… |
|---|---|
| `local` | Esté en el disco del primario, y nada más |
| `remote_write` | La réplica lo haya recibido y entregado a su sistema operativo |
| `on` | La réplica lo tenga **en su disco** |
| `remote_apply` | La réplica lo haya **aplicado**, y sea visible en sus lecturas |

- **Sin `synchronous_standby_names` las cuatro se comportan como `local`**: la réplica existe pero
  el `COMMIT` no la espera. Es el caso por defecto, y es replicación asíncrona.
- **Cada fila hacia abajo añade espera de red a cada confirmación.** Sin réplica en el entorno, la
  tabla es de la documentación y **no se observa aquí**; se vería en `pg_stat_replication`. La
  replicación no es de este corpus: se nombra para decir dónde termina la D.

---

## 8. 📜 Estándar, motor y convención

> **📜 Estándar o motor.** ISO/IEC 9075 es de pago y **no he verificado sus cláusulas**. Lo que se
> atribuye a la norma es solo que lo confirmado persiste; el registro, el volcado y sus parámetros
> son de motor, y la columna de cada uno está leída en el entorno.

| Afirmación | Estándar | PostgreSQL 18.6 | MySQL 9.7.2 / InnoDB | SQLite 3.53.4 |
|---|---|---|---|---|
| Hay registro anticipado | No lo define | WAL | *Redo log* | Diario de reversión, o WAL si se pide |
| El `COMMIT` espera al disco | No lo define | `synchronous_commit = on` | `innodb_flush_log_at_trx_commit = 1` | `PRAGMA synchronous = 2` (`FULL`) |
| Qué se pierde al relajarlo | — | Con `off`, hasta 600 ms de confirmaciones, también si solo cae el proceso | Con `2`, un segundo si cae el sistema; con `0`, también si cae el proceso | Con `NORMAL` en modo WAL, las últimas ante un corte |
| Defensa contra la página rota | — | `full_page_writes = on` | *Doublewrite*, `ON` | El diario y el WAL guardan páginas enteras |
| Modo del registro por defecto | — | WAL siempre | *Redo log* siempre | `delete`, leído en `tienda.db`; el WAL se pide |
| El registro de réplica espera al disco | — | Es el mismo WAL | `sync_binlog = 1`; en MariaDB 12.3.3, `0` y *binlog* apagado | No hay réplica |

- **La fila de lo que se pierde en MySQL está corrida en su mitad comprobable**: con
  `innodb_flush_log_at_trx_commit = 0` y el contenedor muerto con `SIGKILL` justo después del
  `UPDATE`, el cambio se perdió en **2 de 3** intentos; con `1`, en **0 de 2**. El caso del `2` pide
  que caiga el sistema operativo, no el proceso, y eso el entorno no lo produce.
- **El `synchronous` de SQLite no baja solo en modo WAL** con el binario del corpus: está compilado
  con `DEFAULT_WAL_SYNCHRONOUS=2`, así que una base en modo WAL sigue en `FULL` hasta que se pida
  `NORMAL`. Comprobado sobre una base de prueba, fuera del corpus.

**Convención, las dos que más se repiten.** *«`COMMIT` quiere decir que está en disco»* — quiere
decir que está en disco **si** `synchronous_commit` está en `on` **y** el disco no miente, y ni aun
así en otra máquina. Y *«`synchronous_commit = off` puede corromper la base»* — no puede: pierde las
últimas transacciones enteras y deja la base coherente. El que sí corrompe es `fsync = off`, que es
otro parámetro y nunca se toca en producción.

---

## ⚠️ Errores frecuentes

| Se dice | Lo preciso |
|---|---|
| "El `COMMIT` escribe la fila en la tabla" | Escribe un registro de 34 bytes en el WAL y espera a que esté en disco. La página de la tabla se escribe después, en el punto de control |
| "Si el servidor cae, se pierde lo que estaba en memoria" | Se pierde lo **no confirmado**; lo confirmado se rehace desde el WAL al arrancar. Corrido: 150 MB rehechos en 0,54 s |
| "`synchronous_commit = off` es como `fsync = off`" | El primero pierde transacciones enteras y recientes; el segundo puede dejar la base corrupta. Solo el primero es una decisión razonable |
| "Con `off` se pierde siempre algo en una caída" | Se pierde lo que caiga dentro de la ventana de hasta 600 ms. Provocado aquí, 8 de 12 veces |
| "`pg_test_fsync` dice que mi disco es durable" | Dice que es rápido. Si es muy rápido, la pregunta es si su caché sobrevive a un corte |
| "Durable quiere decir replicado" | Durable es en el disco de un servidor. La réplica se pide aparte, y por defecto es asíncrona |

---

## 📚 Para profundizar

- **Documentación** — PostgreSQL 18, «Write-Ahead Logging (WAL)»: la regla y por qué basta con
  volcar el registro. <https://www.postgresql.org/docs/18/wal-intro.html>
- **Documentación** — PostgreSQL 18, «Asynchronous Commit»: la ventana de tres veces
  `wal_writer_delay` y por qué no corrompe.
  <https://www.postgresql.org/docs/18/wal-async-commit.html>
- **Documentación** — PostgreSQL 18, «Reliability»: cachés de escritura, SSD que no vacían y
  `diskchecker.pl`. <https://www.postgresql.org/docs/18/wal-reliability.html>
- **Documentación** — PostgreSQL 18, «WAL Configuration»: puntos de control, `max_wal_size` y
  `full_page_writes`. <https://www.postgresql.org/docs/18/wal-configuration.html>
- **Herramienta** — PostgreSQL 18, «pg_waldump» y «pg_test_fsync», las dos que se corren en este
  capítulo. <https://www.postgresql.org/docs/18/pgwaldump.html> ·
  <https://www.postgresql.org/docs/18/pgtestfsync.html>
- **Documentación** — MySQL 9.7, «InnoDB Startup Options and System Variables»: los tres valores de
  `innodb_flush_log_at_trx_commit`. <https://dev.mysql.com/doc/refman/9.7/en/innodb-parameters.html>
- **Documentación** — MySQL 9.7, «Doublewrite Buffer»: la defensa de InnoDB contra la página rota.
  <https://dev.mysql.com/doc/refman/9.7/en/innodb-doublewrite-buffer.html>
- **Documentación** — SQLite, «Pragma statements»: `synchronous` y `journal_mode`, con lo que se
  pierde en cada nivel. <https://www.sqlite.org/pragma.html>

---

## 🧠 Preguntas

1. ¿Qué dice la regla del registro anticipado, en una frase, y quién la fija: el estándar o el
   motor? 🟢
2. ¿Qué es un LSN y qué dos posiciones distingue PostgreSQL? 🟢
3. ¿Qué es un punto de control y cada cuánto lo lanza PostgreSQL por defecto? 🟢
4. ¿Qué es una página rota y qué parámetro de PostgreSQL la previene? 🟢
5. ¿Cuánto vale por defecto `innodb_flush_log_at_trx_commit` y qué significa ese valor? 🟢
6. Distingue `synchronous_commit = off` de `fsync = off`: qué pierde cada uno. 🟡
7. ¿Está el WAL en el estándar SQL? Responde para la norma y para los tres motores del corpus. 🟡
8. Diferencia la defensa de PostgreSQL contra la página rota de la de InnoDB. 🟡
9. ¿Qué diferencia hay entre `remote_write`, `on` y `remote_apply` cuando hay réplica síncrona? 🟡
10. Explica qué hace PostgreSQL al arrancar después de una caída, y de qué depende cuánto tarda. 🟠
11. Con `synchronous_commit = off`, ¿cuánto puedes perder y qué nunca pierdes? Da el número y su
    origen. 🟠
12. `pg_test_fsync` da 9 000 volcados por segundo en tu servidor. ¿Es buena noticia? Explica qué
    puede significar y cómo lo comprobarías. 🟠
13. ¿Por qué el `VACUUM` de una tabla grande puede generar más WAL que los datos que limpia? 🟠
14. Un lote de eventos de navegación y los pagos viven en la misma base. Propón cómo relajar la
    durabilidad de uno sin tocar la del otro, con la sentencia exacta. 🟠
15. En MySQL, ¿qué diferencia hay entre perder el proceso y perder el sistema operativo con
    `innodb_flush_log_at_trx_commit = 2`? 🟠
16. Escribe la secuencia de sentencias que demuestra, desde `psql`, que un `COMMIT` es lo que vuelca
    el registro a disco, y di qué dos números comparas. 🔴
17. Diagnostica: tras un corte de corriente falta un pago que el cliente vio confirmado. Da tres
    hipótesis en orden de probabilidad y qué mirarías para cada una. 🔴
18. Te piden que el servidor vuelva en menos de un minuto tras una caída, y hoy tarda cinco. Di qué
    parámetros tocarías, en qué dirección, y qué pagas a cambio. 🔴

---

**Anterior:** [`05`](05-optimista-pesimista-y-transacciones-largas.md) — la transacción larga, que
aquí también alarga el WAL · **Siguiente:** [`07`](07-simulacion-de-entrevista.md) — la simulación
del bloque · **Relacionado:** [`01`](01-acid-con-precision.md) §6 — la D presentada, que aquí se
abre por dentro · [`03`](03-mvcc-frente-a-bloqueo.md) §3 — la actualización HOT que aparece en el
registro.
