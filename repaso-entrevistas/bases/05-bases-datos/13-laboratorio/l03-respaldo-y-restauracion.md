# l03 — Respaldo y restauración

> Un respaldo lógico con `pg_dump` y su restauración cronometrada, en serie y en paralelo; un
> respaldo físico con `pg_basebackup`, y por qué el primero tardó 216 s y el segundo 3; y una
> **recuperación a un instante elegido** (PITR): un borrado accidental de 273 126 filas deshecho
> restaurando el servidor al segundo anterior, sin perder un cambio bueno hecho después del
> respaldo. Por el camino, los cuatro errores que se encuentran la primera vez. **Tiempo estimado:**
> 40 minutos. **Asume levantado:** el entorno de [`l00`](l00-el-entorno-y-los-datos.md).
> **Vigencia:** 24 de septiembre de 2026.

---

## Salto rápido

- [1. Qué vas a ver](#1--qué-vas-a-ver) · [2. El respaldo lógico](#2--paso-1--el-respaldo-lógico) ·
  [3. Restaurarlo](#3--paso-2--restaurarlo-con-dos-errores-antes)
- [4. El respaldo físico](#4--paso-3--el-respaldo-físico-y-el-permiso-de-replicación) · [5. La
  recuperación a un instante](#5--paso-4--la-recuperación-a-un-instante)
- [6. El teardown](#6--paso-5--el-teardown) · [Ejercicios](#-ejercicios) · [Preguntas](#-preguntas)

---

## 1. 🎯 Qué vas a ver

**Un respaldo que no se ha restaurado no existe.** La frase es del bloque 06, dueño de respaldos y
recuperación —lo lista el [README de la raíz](../README.md)—, y este lab la convierte en práctica:
cada respaldo se restaura, se verifica y se cronometra. Los dos números que salen son los que se
preguntan en una entrevista de diseño: **cuánto se tarda en volver** y **cuántos datos se pierden**.

Dos decisiones de diseño hacen que el lab sea seguro sobre tu `bd-lab`:

- **El accidente se provoca en una tabla de trabajo**, `pagos_copia`, no en `pagos`.
- **La restauración física ocurre en contenedores aparte**, con su propio volumen. El servidor del
  corpus solo recibe una línea temporal en `pg_hba.conf`, que el teardown quita.

> **📝 Contexto.** Todo está corrido sobre la copia aislada de [`l00`](l00-el-entorno-y-los-datos.md)
> §1, con los nombres del corpus en las órdenes. **Longitud:** 478 líneas, por los registros del
> servidor; lab normal. **Los tiempos son de una máquina de 8 núcleos con todo en local**; con el
> respaldo en otra máquina, la red se suma. Las horas de los registros están en UTC, y los
> identificadores de transacción y de segmento de WAL cambian en cada corrida.

---

## 2. 🧱 Paso 1 — El respaldo lógico

```bash
time docker exec bd-lab-postgres pg_dump -U postgres -Fc tienda > tienda.dump
ls -l tienda.dump
```

- `pg_dump` corre **dentro** del contenedor, para que su versión sea la del servidor —18.6—, y
  escribe por la salida estándar, que el `>` guarda en tu máquina.
- `-Fc` es el formato propio de PostgreSQL: comprimido y con un índice de su contenido, lo que
  permite restaurar tablas sueltas y en paralelo. `time` mide la orden entera.

```text
real 18.69
-rw-r--r--@ 1 oskar  wheel  142261677 Sep 24 20:16 tienda.dump
```

- **142 MB para una base de 1 316 MB.** El respaldo lógico guarda **sentencias y datos**, no
  páginas: ni índices construidos, ni espacio libre, ni versiones muertas. Los índices se vuelven a
  construir al restaurar, y ahí está su coste.
- **Es una foto de un instante**: `pg_dump` lo lee todo desde una sola instantánea, coherente aunque
  la base se esté usando, y sin bloquear las escrituras. Lo que pase después de empezar no está.

---

## 3. 🩺 Paso 2 — Restaurarlo, con dos errores antes

**El primer error**: restaurar en una base que no existe.

```bash
docker exec -i bd-lab-postgres pg_restore -U postgres -d tienda_restaurada < tienda.dump
```

```text
pg_restore: error: connection to server on socket "/var/run/postgresql/.s.PGSQL.5432" failed: FATAL:  database "tienda_restaurada" does not exist
```

- **`pg_restore` restaura dentro de una base**, no la crea. Se crea antes con `createdb`, que es lo
  que permite restaurar al lado de la original sin tocarla.

**El segundo**: pedir paralelismo leyendo de la entrada estándar.

```bash
docker exec bd-lab-postgres createdb -U postgres tienda_restaurada
docker exec -i bd-lab-postgres pg_restore -U postgres -j 4 -d tienda_restaurada < tienda.dump
```

```text
pg_restore: error: parallel restore from standard input is not supported
```

- **`-j 4` abre cuatro conexiones que leen del fichero a la vez**, cada una su parte, y eso exige un
  fichero con acceso aleatorio, no un flujo. Se copia dentro del contenedor:

```bash
docker cp tienda.dump bd-lab-postgres:/tmp/tienda.dump
time docker exec bd-lab-postgres pg_restore -U postgres -j 4 -d tienda_restaurada /tmp/tienda.dump
```

- `docker cp` copia un fichero de tu máquina al sistema de ficheros del contenedor.

| Restauración | Tiempo |
|---|---|
| En serie, sin `-j` | 21,97 s |
| En paralelo, `-j 4` | 15,22 s |

- **Paralelo gana un 30 %, no un 75 %**: las cuatro conexiones cargan tablas distintas, y la
  restauración espera a la más grande —`eventos_pedido`, con 4,1 millones de filas— y a sus índices.
- **Se verifica, no se supone.** `verificar.sql` contra la base restaurada:

```bash
PGPASSWORD=postgres psql -h 127.0.0.1 -U postgres -d tienda_restaurada \
  -f 13-laboratorio/entorno/verificar.sql | grep -c "| OK"
```

```text
22
```

- La base restaurada ocupa 1 322 MB frente a los 1 316 de la original: índices recién construidos,
  sin el desgaste de la carga.

**Teardown de este paso:**

```bash
docker exec bd-lab-postgres dropdb -U postgres tienda_restaurada
docker exec bd-lab-postgres rm /tmp/tienda.dump
```

- `dropdb` borra la base restaurada entera; `rm` quita la copia del fichero dentro del contenedor.
  El `tienda.dump` de tu máquina guárdalo o bórralo: el corpus no lo necesita.

---

## 4. 🩺 Paso 3 — El respaldo físico, y el permiso de replicación

**Qué es:** `pg_basebackup` copia **los ficheros del servidor** —las páginas tal cual, con índices y
todo— mientras el servidor sigue funcionando, usando el protocolo de replicación. Se corre desde un
contenedor aparte en la red del `compose`, como haría un servidor de respaldos:

```bash
docker run -d --name bd-lab-pitr --network bd-lab_default -v bd-lab-pitr:/respaldo \
  -e PGPASSWORD=postgres postgres:18.6 sleep infinity
docker exec bd-lab-pitr sh -c 'mkdir -p /respaldo/wal && chown -R postgres:postgres /respaldo'
docker exec -u postgres bd-lab-pitr pg_basebackup -h postgres -U postgres -D /respaldo/base -X stream -P
```

- `docker run` arranca un contenedor con la misma imagen, pero en vez de un servidor ejecuta `sleep
  infinity`: solo sirve para tener las herramientas de PostgreSQL a mano. `--network bd-lab_default`
  lo mete en la red del `compose`, donde el servidor se llama `postgres`. `-v bd-lab-pitr:/respaldo`
  crea un volumen con nombre para los respaldos.
- `-u postgres` ejecuta como el usuario `postgres`, porque un servidor de PostgreSQL no arranca
  sobre ficheros de `root`. `-D` es el directorio de destino; `-X stream` copia también el WAL
  generado mientras dura el respaldo, sin el cual la copia no es coherente; `-P` enseña el progreso.

```text
pg_basebackup: error: connection to server at "postgres" (172.24.0.4), port 5432 failed: FATAL:  no pg_hba.conf entry for replication connection from host "172.24.0.5", user "postgres", no encryption
```

- **La replicación es una base aparte en `pg_hba.conf`.** Las reglas de la imagen oficial la
  permiten solo desde el propio servidor. Se añade una línea y se recarga, sin reiniciar:

```bash
docker exec bd-lab-postgres sh -c "echo 'host replication postgres all scram-sha-256' >> /var/lib/postgresql/data/pg_hba.conf"
```

```text
tienda=# SELECT pg_reload_conf();
 pg_reload_conf
----------------
 t
(1 fila)

tienda=# SELECT type, database, user_name, address, auth_method FROM pg_hba_file_rules WHERE 'replication' = ANY(database);
 type  |   database    | user_name  |  address  |  auth_method
-------+---------------+------------+-----------+---------------
 local | {replication} | {all}      |           | trust
 host  | {replication} | {all}      | 127.0.0.1 | trust
 host  | {replication} | {all}      | ::1       | trust
 host  | {replication} | {postgres} | all       | scram-sha-256
(4 filas)
```

- `pg_reload_conf()` le dice al servidor que vuelva a leer su configuración; `pg_hba_file_rules`
  enseña las reglas como las entendió, que es la forma de comprobar que la línea nueva vale.

Con el permiso, el respaldo sale, y tarda. Después, el mismo con `-c fast`:

```text
-- pg_basebackup … -X stream -P
1437552/1437552 kB (100%), 1/1 tablespace
real 215.83
-- pg_basebackup … -X stream -c fast -P
1437552/1437552 kB (100%), 1/1 tablespace
real 3.12
```

- **Los mismos 1,4 GB, en 216 s y en 3 s.** La copia es rápida; lo lento es lo que pasa antes. Un
  respaldo físico empieza con un *checkpoint*, y por defecto `pg_basebackup` lo pide **espaciado**:
  el servidor reparte la escritura de las páginas sucias a lo largo de su intervalo normal para no
  castigar al resto. `-c fast` lo pide inmediato.
- **Cuándo cada uno**: espaciado en producción cargada, donde un *checkpoint* brusco se nota; rápido
  cuando el respaldo corre en una ventana tranquila o cuando hay prisa por tenerlo.

---

## 5. 🩺 Paso 4 — La recuperación a un instante

**Qué es:** un respaldo físico más **todo el WAL posterior** permite reconstruir el servidor en
cualquier instante entre el respaldo y el último WAL guardado. Es lo que salva un `DELETE` sin
`WHERE`: se vuelve al segundo anterior.

El WAL se guarda con `pg_receivewal`, que lo recibe por replicación y lo escribe en ficheros. **El
primer intento lo arrancó después del respaldo base**, y su registro terminó así:

```text
cp: cannot stat '/respaldo/wal/000000010000000200000090': No such file or directory
2026-09-25 01:23:19.524 UTC [32] LOG:  redo done at 2/8F308F68 system usage: CPU: user: 0.09 s, system: 0.11 s, elapsed: 0.25 s
2026-09-25 01:23:19.524 UTC [32] LOG:  last completed transaction was at log time 2026-09-25 01:19:25.165754+00
2026-09-25 01:23:19.524 UTC [32] FATAL:  recovery ended before configured recovery target was reached
```

- **Faltaba un segmento**: el respaldo traía hasta el `…8F`, el flujo empezó en el `…91`, y el `…90`
  no estaba en ningún sitio. **El WAL tiene que ser continuo desde el respaldo**, y la única forma
  de garantizarlo es arrancar el flujo **antes** del respaldo base.

El orden correcto, con la tabla de trabajo creada primero:

```bash
docker exec -d -u postgres bd-lab-pitr pg_receivewal -h postgres -U postgres -D /respaldo/wal
docker exec -u postgres bd-lab-pitr pg_basebackup -h postgres -U postgres -D /respaldo/base -X stream -c fast -P
```

- `docker exec -d` deja `pg_receivewal` corriendo en segundo plano dentro del contenedor. Arrancó en
  el segmento `…9B`; el respaldo, tomado después, empezó en el `…9C`. No hay hueco.

Antes que nada se crea la tabla de trabajo —`CREATE TABLE pagos_copia AS SELECT * FROM pagos`, en
0,4 s—. Después, un cambio bueno, el instante, y el accidente:

```text
tienda=# UPDATE pedidos SET estado = 'ENVIADO' WHERE codigo = 'PED-00042';
UPDATE 1
tienda=# SELECT now() AS instante_bueno;
        instante_bueno
------------------------------
 2026-09-25 01:24:12.29453+00
(1 fila)

tienda=# SELECT pg_sleep(2);
 pg_sleep
----------

(1 fila)

tienda=# DELETE FROM pagos_copia WHERE metodo = 'EFECTIVO';
DELETE 273126
tienda=# SELECT now() AS despues_del_accidente;
     despues_del_accidente
-------------------------------
 2026-09-25 01:24:23.815291+00
(1 fila)

tienda=# SELECT pg_switch_wal();
 pg_switch_wal
---------------
 2/A20E64A8
(1 fila)
```

- **El `UPDATE` es posterior al respaldo** y tiene que sobrevivir a la recuperación; el `DELETE` no.
  `pg_switch_wal()` cierra el segmento de WAL en curso para que `pg_receivewal` lo guarde entero.

**La recuperación**, en un segundo contenedor que arranca sobre la copia del respaldo:

```bash
docker exec bd-lab-pitr pkill pg_receivewal
docker exec -u postgres bd-lab-pitr sh -c "touch /respaldo/base/recovery.signal && cat >> /respaldo/base/postgresql.auto.conf <<'EOF'
restore_command = 'cp /respaldo/wal/%f %p'
recovery_target_time = '2026-09-25 01:24:12.29453+00'
recovery_target_action = 'promote'
EOF"
docker run -d --name bd-lab-pitr-restaurada -p 25432:5432 -v bd-lab-pitr:/respaldo -e PGDATA=/respaldo/base postgres:18.6
```

- `recovery.signal` le dice al servidor que arranque recuperando. `restore_command` es cómo obtener
  cada segmento de WAL: `%f` es su nombre y `%p` dónde dejarlo. `recovery_target_time` es el
  instante elegido; `promote`, que al llegar se convierta en un servidor normal.
- `-e PGDATA=/respaldo/base` arranca el servidor sobre la copia, y `-p 25432:5432` lo publica en
  otro puerto para consultarlo sin tocar el del corpus.

El final de su registro, sin las líneas `cp: cannot stat` de los segmentos que aún no existían:

```text
2026-09-25 01:24:45.485 UTC [37] LOG:  consistent recovery state reached at 2/9C000120
2026-09-25 01:24:45.485 UTC [1] LOG:  database system is ready to accept read-only connections
2026-09-25 01:24:45.532 UTC [37] LOG:  restored log file "00000001000000020000009E" from archive
2026-09-25 01:24:45.588 UTC [37] LOG:  restored log file "00000001000000020000009F" from archive
2026-09-25 01:24:45.644 UTC [37] LOG:  restored log file "0000000100000002000000A0" from archive
2026-09-25 01:24:45.709 UTC [37] LOG:  restored log file "0000000100000002000000A1" from archive
2026-09-25 01:24:45.762 UTC [37] LOG:  recovery stopping before commit of transaction 961, time 2026-09-25 01:24:20.733287+00
2026-09-25 01:24:45.762 UTC [37] LOG:  redo done at 2/A1F5B958 system usage: CPU: user: 0.10 s, system: 0.07 s, elapsed: 0.31 s
2026-09-25 01:24:45.762 UTC [37] LOG:  last completed transaction was at log time 2026-09-25 01:24:09.246182+00
2026-09-25 01:24:45.766 UTC [37] LOG:  selected new timeline ID: 2
2026-09-25 01:24:45.787 UTC [37] LOG:  archive recovery complete
2026-09-25 01:24:45.802 UTC [35] LOG:  checkpoint starting: end-of-recovery immediate wait
2026-09-25 01:24:45.957 UTC [35] LOG:  checkpoint complete: wrote 8235 buffers (50.3%), wrote 3 SLRU buffers; 0 WAL file(s) added, 0 removed, 5 recycled; write=0.127 s, sync=0.021 s, total=0.157 s; sync files=6, longest=0.013 s, average=0.004 s; distance=97646 kB, estimate=97646 kB; lsn=2/A1F5B958, redo lsn=2/A1F5B958
2026-09-25 01:24:45.960 UTC [1] LOG:  database system is ready to accept connections
```

- **`recovery stopping before commit of transaction 961`**: el `DELETE`, confirmado a las 01:24:20,
  después del instante pedido. El servidor aplicó todo el WAL hasta ahí y se paró.
- **`selected new timeline ID: 2`**: la historia se bifurca. El servidor restaurado sigue desde el
  instante bueno en una línea temporal nueva, para que su WAL no se confunda con el del original,
  que sí vivió el borrado.

Y los datos, en el restaurado:

```text
tienda=# SELECT count(*) AS efectivo FROM pagos_copia WHERE metodo = 'EFECTIVO';
 efectivo
----------
   273126
(1 fila)

tienda=# SELECT estado FROM pedidos WHERE codigo = 'PED-00042';
 estado
---------
 ENVIADO
(1 fila)

tienda=# SELECT timeline_id FROM pg_control_checkpoint();
 timeline_id
-------------
           2
(1 fila)
```

- **Los 273 126 pagos volvieron y el cambio bueno se quedó.** En el original, la misma consulta
  sobre `pagos_copia` sigue dando 0: el original no se toca; se restaura al lado y se copia lo
  perdido.
- **Lo que se perdió** es lo que pasó entre el instante elegido y el borrado, y eso es el RPO de
  este método: con WAL continuo, segundos.

> **⚠️ Advertencia.** Sin WAL continuo desde el respaldo, no hay recuperación a un instante: solo al
> momento del respaldo, o a ninguno. El flujo —`pg_receivewal` o `archive_command`— se arranca antes
> del primer respaldo base y se vigila como un servicio más.

---

## 6. 🩺 Paso 5 — El teardown

```bash
docker rm -f bd-lab-pitr bd-lab-pitr-restaurada
docker volume rm bd-lab-pitr
docker exec bd-lab-postgres sed -i '/^host replication postgres all scram-sha-256$/d' /var/lib/postgresql/data/pg_hba.conf
```

- `rm -f` para y borra los dos contenedores; `volume rm` borra el volumen con el respaldo y el WAL.
- `sed -i '/…/d'` borra del `pg_hba.conf` exactamente la línea que se añadió en §4.

```text
tienda=# UPDATE pedidos SET estado = 'PAGADO' WHERE codigo = 'PED-00042';
UPDATE 1
tienda=# DROP TABLE pagos_copia;
DROP TABLE
tienda=# SELECT pg_reload_conf();
 pg_reload_conf
----------------
 t
(1 fila)

tienda=# SELECT count(*) AS reglas_de_replicacion_remota FROM pg_hba_file_rules WHERE 'replication' = ANY(database) AND address = 'all';
 reglas_de_replicacion_remota
------------------------------
                            0
(1 fila)
```

- **La compensación y la comprobación**: `PED-00042` vuelve a `PAGADO`, la tabla de trabajo
  desaparece, y la regla de replicación ya no existe tras recargar.

---

## 7. 📜 Estándar, motor y convención

> **📜 Estándar o motor.** ISO/IEC 9075 no define respaldos, ni WAL, ni recuperación: todo es de cada
> motor, y cada uno lo resuelve con herramientas distintas.

| Pieza | PostgreSQL 18 | MySQL 9.7 | SQLite 3.53 |
|---|---|---|---|
| Respaldo lógico | `pg_dump`, `pg_dumpall` | `mysqldump`, `mysqlpump` retirado | `.dump` del cliente |
| Respaldo físico en caliente | `pg_basebackup` | Plugin `CLONE`, o herramientas externas | `.backup`, o `VACUUM INTO` |
| Registro para recuperar a un instante | WAL, con `pg_receivewal` o `archive_command` | *Binary log*, con `mysqlbinlog` | No tiene |
| Recuperar a un instante | `recovery_target_time` | Reaplicar el *binary log* hasta una posición o una hora | No aplica |

**Convención, las dos que más se repiten.** *«Tenemos respaldo diario»* — sin WAL continuo, eso es
un RPO de hasta 24 horas, no «tenemos respaldo». Y *«el respaldo lógico sirve para todo»* — es
portable y selectivo, pero restaurar reconstruye todos los índices: con bases grandes, el RTO pasa
de minutos a horas.

---

## ⚠️ Errores frecuentes

| Se dice | Lo preciso |
|---|---|
| "`pg_restore` crea la base" | Restaura dentro de una que ya existe; se crea con `createdb` |
| "`-j` acelera cualquier restauración" | Exige un fichero, no la entrada estándar; y el tiempo lo marca la tabla más grande |
| "`pg_basebackup` es lento" | Por defecto espera un *checkpoint* espaciado: 216 s frente a 3 con `-c fast` |
| "Con el respaldo base puedo volver a cualquier momento" | Solo con el WAL continuo desde antes del respaldo; con un hueco, la recuperación falla |
| "Se restaura sobre la base dañada" | Se restaura al lado, se comprueba y se copia lo perdido |

---

## 🧪 Ejercicios

1. Haz un respaldo lógico solo de `productos` con `-t` y restáuralo en una base nueva. Borra la base
   al terminar. 🟢
2. Compara el tamaño del respaldo en formato plano —`-Fp`— con el de `-Fc`, y di qué ganas y qué
   pierdes con cada uno. 🟡
3. Repite la restauración con `-j 2` y `-j 8` y explica por qué el tiempo deja de bajar. 🟡
4. Repite la recuperación a un instante con `recovery_target_action = 'pause'` y comprueba los datos
   antes de promover el servidor con `pg_wal_replay_resume()`. 🟠
5. Calcula el RPO y el RTO de lo que hiciste en §5, con los tiempos medidos, y di cuál de los dos
   cambiaría con una base de 1 TB. 🟠
6. Diseña la política de respaldos de la tienda para un RPO de un minuto y un RTO de una hora: qué
   respaldos, cada cuánto, dónde se guarda el WAL y cómo se prueba la restauración. 🔴
7. Configura `archive_command` en lugar de `pg_receivewal` en la copia aislada y repite §5. 🔥
   *(fuera de conteo)*

---

## 📚 Para profundizar

- **Documentación** — PostgreSQL 18, «Backup and Restore»: los tres métodos.
  <https://www.postgresql.org/docs/18/backup.html>
- **Documentación** — PostgreSQL 18, `pg_basebackup`: `--checkpoint` y `--wal-method`.
  <https://www.postgresql.org/docs/18/app-pgbasebackup.html>
- **Documentación** — PostgreSQL 18, «Continuous Archiving and Point-in-Time Recovery (PITR)».
  <https://www.postgresql.org/docs/18/continuous-archiving.html>
- **Documentación** — PostgreSQL 18, `pg_receivewal`.
  <https://www.postgresql.org/docs/18/app-pgreceivewal.html>
- **Documentación** — PostgreSQL 18, `pg_restore`: `-j` y sus límites.
  <https://www.postgresql.org/docs/18/app-pgrestore.html>
- **Documentación** — MySQL 9.7, «Point-in-Time (Incremental) Recovery».
  <https://dev.mysql.com/doc/refman/9.7/en/point-in-time-recovery.html>

---

## 🧠 Preguntas

1. ¿Qué diferencia hay entre un respaldo lógico y uno físico? 🟢
2. ¿Qué hace el formato `-Fc` de `pg_dump`? 🟢
3. ¿Qué son el RPO y el RTO? 🟢
4. ¿Para qué sirve `pg_switch_wal()`? 🟢
5. ¿Por qué el respaldo lógico ocupa 142 MB y la base 1 316? 🟡
6. ¿Por qué `pg_restore -j` no funciona leyendo de la entrada estándar? 🟡
7. Distingue `pg_receivewal` de `archive_command`: qué hace cada uno y dónde corre. 🟡
8. ¿Qué parte de este lab es del estándar y qué parte del motor? Da dos ejemplos. 🟡
9. ¿Por qué `pg_basebackup` tardó 216 s por defecto y 3 s con `-c fast`? 🟠
10. ¿Por qué falló la primera recuperación, y qué orden la habría evitado? 🟠
11. ¿Qué significa `selected new timeline ID: 2`, y por qué hace falta? 🟠
12. ¿Por qué se restaura al lado del servidor dañado y no encima? 🟠
13. ¿Qué se pierde en una recuperación a un instante, y de qué depende? 🔴
14. Diagnostica: una recuperación termina con `recovery ended before configured recovery target was
    reached`. Da dos causas y cómo comprobarías cada una. 🔴
15. Diseña el procedimiento, orden por orden, para deshacer un `DELETE` sin `WHERE` en producción
    sin perder las escrituras buenas posteriores. 🔴

---

**Anterior:** [`l02`](l02-aislamiento-y-bloqueos-en-vivo.md) — aislamiento y bloqueos en vivo ·
**Siguiente:** [`l04`](l04-redis-y-mongodb.md) — Redis y MongoDB · **Relacionado:**
[`04/06`](../04-transacciones-y-concurrencia/06-wal-durabilidad-y-fsync.md) — el WAL y la
durabilidad, que es lo que este lab reaplica.
