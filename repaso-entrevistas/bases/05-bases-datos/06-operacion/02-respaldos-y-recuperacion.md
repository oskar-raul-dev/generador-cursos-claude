# 02 — Respaldos y recuperación

> Lógico frente a físico, recuperación a un instante, y los dos números que deciden una política de
> respaldos: cuánto se tarda en volver y cuántos datos se pierden. Con las cifras de
> [`l03`](../13-laboratorio/l03-respaldo-y-restauracion.md) y tres medidas nuevas: un byte cambiado
> en un respaldo físico que `pg_verifybackup` detecta, una tabla de 820 000 filas restaurada en
> 0,85 s pero sin ninguno de sus índices, y el mismo `tienda` volcado en 142 MB por PostgreSQL y en
> 835 MB por MySQL. **Asume leído:**
> [`04/06`](../04-transacciones-y-concurrencia/06-wal-durabilidad-y-fsync.md), el WAL. **Vigencia:**
> 27 de septiembre de 2026.

---

## Salto rápido

- [1. El problema](#1--el-problema) · [2. Lógico y físico](#2--lógico-y-físico)
- [3. RPO y RTO, con números](#3--rpo-y-rto-con-números) · [4. Un respaldo que no se ha
  restaurado no existe](#4--un-respaldo-que-no-se-ha-restaurado-no-existe)
- [5. Restaurar una sola tabla](#5--restaurar-una-sola-tabla) · [6. MySQL y
  SQLite](#6-️-mysql-y-sqlite)
- [7. Cómo se elige](#7--cómo-se-elige) · [8. Estándar, motor y
  convención](#8--estándar-motor-y-convención)
- [Errores frecuentes](#️-errores-frecuentes) · [Preguntas](#-preguntas)

---

## 1. 🎯 El problema

«Tenemos respaldos» es una de las frases más caras que se dicen en una empresa. Casi siempre
significa que un proceso copia algo a algún sitio cada noche. Lo que casi nunca significa es que
alguien haya **restaurado** esa copia, cronometrado cuánto tarda y comprobado qué datos faltan.

El día que hace falta —un `DELETE` sin `WHERE`, un disco que muere, una migración que corrompe una
tabla— aparecen las preguntas que la frase escondía: ¿hasta qué minuto podemos volver? ¿Cuánto
tardamos? ¿La copia está entera? ¿Se puede sacar solo la tabla dañada sin tirar las demás?

[`l03`](../13-laboratorio/l03-respaldo-y-restauracion.md) hizo el ejercicio completo en PostgreSQL:
respaldo lógico, físico y recuperación a un instante, con sus tiempos. Este capítulo es el dueño del
concepto: ordena lo que se midió allí, mide lo que faltaba y lo compara con MySQL y SQLite.

> **📝 Contexto.** Las sesiones nuevas de PostgreSQL se corrieron en la copia aislada `bd-lab-prueba`
> de [`05/01`](../05-programacion-en-el-motor/01-funciones-y-procedimientos.md), con los respaldos
> dentro de su contenedor, en `/tmp`. Las de MySQL y SQLite, sobre el entorno principal y solo
> leyendo: `mysqldump` y el `.backup` de SQLite no cambian la base. Las cifras de `l03` se citan, no
> se repiten. **Longitud:** unas 345 líneas; capítulo normal.

---

## 2. 🧱 Lógico y físico

**Qué es:** un respaldo **lógico** guarda **sentencias y datos** —lo que haría falta para volver a
crear la base—: `pg_dump` en PostgreSQL, `mysqldump` en MySQL. Un respaldo **físico** guarda **los
ficheros del servidor**, página a página: `pg_basebackup`. Y la **recuperación a un instante**
(PITR) es un respaldo físico más **todo el WAL** posterior, que permite reconstruir el servidor en
cualquier segundo entre el respaldo y el último WAL guardado.

**Quién lo manda:** el **motor**, entero. El estándar no dice nada de respaldos; cada motor tiene
sus herramientas y su registro de cambios —el WAL de PostgreSQL, el *binary log* de MySQL—.

Lo que midió `l03` con la base del corpus, 1 316 MB:

| Operación | Tiempo | Tamaño |
|---|---|---|
| `pg_dump -Fc` | 18,69 s | 142 MB |
| `pg_restore` en serie / con `-j 4` | 21,97 s / 15,22 s | — |
| `pg_basebackup`, *checkpoint* espaciado / rápido | 215,83 s / 3,12 s | 1,4 GB |
| PITR: volver al segundo anterior a un `DELETE` de 273 126 filas | La recuperación, 0,31 s de WAL aplicado | — |

- **El lógico ocupa diez veces menos** porque no guarda índices construidos ni espacio libre; por
  eso restaurarlo es **reconstruir** todos los índices, y ahí está su coste.
- **El físico ocupa lo que la base**, y restaurarlo es copiar ficheros y arrancar: no reconstruye
  nada. Pero solo sirve para la misma versión mayor del motor y la misma plataforma.
- **Solo el físico con WAL permite PITR**: un volcado es una foto de un instante, y lo que pasó
  después no está.

> **Veredicto:** el lógico es portable y selectivo; el físico es rápido de restaurar y es la base de
> la recuperación a un instante. Una política seria usa el físico con WAL, y el lógico para lo que
> este no sabe hacer.

---

## 3. 🧭 RPO y RTO, con números

**Qué es:** el **RPO** (*recovery point objective*) es cuántos datos se aceptan perder, medido en
tiempo: «podemos perder hasta cinco minutos». El **RTO** (*recovery time objective*) es cuánto se
acepta tardar en volver a servir. Son **convención** de continuidad de negocio, no de ningún motor,
y lo que la entrevista busca es que se digan **con números**.

Lo que da cada estrategia, con las medidas del corpus:

| Estrategia | RPO | RTO de la base de 1,3 GB |
|---|---|---|
| Un `pg_dump` cada noche | Hasta 24 horas | ~15–22 s de restaurar, más copiar el fichero |
| Físico cada noche, sin WAL | Hasta 24 horas | Copiar 1,4 GB y arrancar |
| Físico más WAL continuo (PITR) | Lo que tarde en guardarse el último segmento de WAL | Copiar, arrancar y aplicar el WAL desde el respaldo |
| Réplica síncrona | Cero para lo confirmado | Promover la réplica |

- **El RPO de PITR depende de cómo se guarda el WAL**: con `pg_receivewal`, que lo recibe por
  replicación como en `l03`, son segundos; con archivado por segmento completo, lo que tarde en
  llenarse un segmento, salvo que se fuerce con un tiempo máximo.
- **El RTO de PITR crece con el WAL acumulado**: cuanto más lejos está el respaldo base, más WAL hay
  que aplicar. Por eso el físico se repite cada cierto tiempo aunque haya WAL continuo.
- **Una réplica no es un respaldo**: un `DELETE` sin `WHERE` llega a la réplica en milisegundos. Da
  RPO cero ante un fallo de disco y ninguna protección ante un error humano.

> **⚠️ Advertencia.** La respuesta «tenemos respaldo diario» en una entrevista se contesta sola: RPO
> de 24 horas. Lo que se espera es la cifra que pide el negocio, y la estrategia que la da.

---

## 4. 🩺 Un respaldo que no se ha restaurado no existe

La regla del bloque tiene dos partes: comprobar que el respaldo está **entero**, y comprobar que
**se puede restaurar**. PostgreSQL trae una herramienta para la primera. Un respaldo físico de la
copia, verificado, y el mismo tras cambiar un solo byte de un fichero de datos:

```text
$ docker exec -u postgres bd-lab-prueba-postgres pg_basebackup -h 127.0.0.1 -U postgres -D /tmp/base -X stream -c fast
$ docker exec -u postgres bd-lab-prueba-postgres pg_verifybackup /tmp/base
backup successfully verified
```

```text
$ docker exec -u postgres bd-lab-prueba-postgres sh -c 'printf X | dd of=/tmp/base/base/16384/16541 bs=1 seek=100000 conv=notrunc status=none'
$ docker exec -u postgres bd-lab-prueba-postgres pg_verifybackup /tmp/base
pg_verifybackup: error: checksum mismatch for file "base/16384/16541"
```

- **`pg_basebackup … -D /tmp/base -X stream -c fast`** es el respaldo físico de `l03` §4, aquí
  dentro del propio contenedor y por `127.0.0.1`, que la configuración de la imagen ya permite para
  replicación. No imprime nada si termina bien.
- **`pg_basebackup` escribe un manifiesto** con la suma de comprobación de cada fichero, y
  **`pg_verifybackup`** relee los ficheros y compara. `backup successfully verified` es la primera
  mitad de la regla.
- **`base/16384/16541` es `pagos`**: `pg_relation_filepath('pagos')` da esa ruta. **`dd`** escribe
  un solo byte —`printf X`— en la posición 100 000 sin truncar el fichero —`conv=notrunc`—. Es la
  corrupción que deja un disco o una copia a medias.
- **Un byte y `checksum mismatch`**. El respaldo parecía normal: mismo tamaño, mismos ficheros.

**Y la segunda mitad no la cubre**: la documentación de `pg_verifybackup` dice que no hace todas las
comprobaciones que haría un servidor al usar el respaldo, y que **aun usándola hay que hacer
restauraciones de prueba** y comprobar que la base resultante funciona y tiene los datos correctos.
Es lo que hizo `l03` con `verificar.sql`: 22 de 22 contra la base restaurada.

> **Veredicto:** verificar un respaldo es barato y detecta corrupción; restaurarlo de verdad, con un
> tiempo medido, es lo único que demuestra el RTO. Las dos cosas se programan, no se hacen el día
> del desastre.

---

## 5. 🧱 Restaurar una sola tabla

El caso más frecuente no es perder la base: es romper **una tabla**. El respaldo lógico en formato
propio permite sacar solo esa. Un volcado de la copia y la restauración de `pagos` en una base
aparte:

```text
$ docker exec bd-lab-prueba-postgres bash -c 'time pg_dump -U postgres -Fc -f /tmp/tienda.dump tienda'

real	0m17.197s
user	0m16.759s
sys	0m0.291s
$ docker exec bd-lab-prueba-postgres createdb -U postgres restaurada
$ docker exec bd-lab-prueba-postgres bash -c 'time pg_restore -U postgres -d restaurada -t pagos /tmp/tienda.dump'

real	0m0.853s
user	0m0.227s
sys	0m0.021s
$ docker exec bd-lab-prueba-postgres psql -U postgres -d restaurada -Atc "SELECT count(*) FROM pagos" -c "SELECT count(*) FROM pg_indexes WHERE tablename = 'pagos'"
820000
0
```

- **`-Fc`** es el formato propio, comprimido y con índice de contenido; `-f` escribe el fichero.
  **`pg_restore -t pagos`** restaura solo esa tabla, en la base `restaurada`, al lado de la original
  y sin tocarla.
- **820 000 filas en 0,85 s**, frente a los 15–22 s de restaurar la base entera.
- **Y cero índices**: ni siquiera su clave primaria. La documentación de `pg_restore` lo dice: su
  `-t` **no incluye los objetos dependientes**, como los índices, aunque el `-t` de `pg_dump` sí los
  vuelque. Una tabla así, puesta en producción, no tiene clave primaria ni sus claves foráneas.
- **El uso correcto** es restaurar al lado y copiar las filas perdidas a la tabla buena con un
  `INSERT … SELECT`, que es lo mismo que hizo `l03` tras la PITR.

---

## 6. ⚖️ MySQL y SQLite

**MySQL** tiene su respaldo lógico, `mysqldump`, y su registro de cambios, el *binary log*, que es
la base de su recuperación a un instante:

```text
$ docker exec bd-lab-mysql bash -c 'time mysqldump -uroot -proot --single-transaction tienda > /tmp/tienda.sql'
Warning: A partial dump from a server that has GTIDs will by default include the GTIDs of all transactions, even those that changed suppressed parts of the database. If you don't want to restore GTIDs, pass --set-gtid-purged=OFF. To make a complete dump, pass --all-databases --triggers --routines --events. 

real	0m5.840s
user	0m4.411s
sys	0m0.922s
$ docker exec bd-lab-mysql bash -c 'ls -l /tmp/tienda.sql'
-rw-r--r-- 1 root root 834524864 Sep 27 18:42 /tmp/tienda.sql
$ docker exec bd-lab-mysql mysql -uroot -proot -Nse "SELECT @@log_bin, @@binlog_format, @@binlog_expire_logs_seconds"
1	ROW	2592000
```

- **`--single-transaction`**, según su manual, pone el aislamiento en `REPEATABLE READ` y abre una
  transacción antes de volcar: una foto coherente sin bloquear las escrituras, **solo con tablas
  transaccionales** como las de InnoDB.
- **835 MB de SQL en texto**, frente a los 142 MB del formato comprimido de PostgreSQL: el volcado
  de MySQL son sentencias `INSERT` sin comprimir. Se comprime por fuera, con `gzip` en la tubería.
- **El aviso de GTID** dice que un volcado de una sola base arrastra los identificadores de
  transacción de todo el servidor, y que un volcado completo necesita `--all-databases`,
  `--triggers`, `--routines` y `--events`. Por defecto, `mysqldump` no guarda los procedimientos ni
  los eventos de [`05/01`](../05-programacion-en-el-motor/01-funciones-y-procedimientos.md).
- **`@@log_bin` vale 1**: el *binary log* está activo, en formato `ROW` y con 2 592 000 segundos de
  retención, treinta días. Con un volcado más el *binary log* desde entonces, MySQL recupera a un
  instante, como PostgreSQL con el WAL.
- El volcado se borró después con `rm`, porque vivía dentro del contenedor.

**SQLite** es un fichero, y copiarlo mientras alguien escribe puede dar una copia rota. Su
herramienta de línea de órdenes trae un respaldo en caliente, sobre la API de respaldo de la
biblioteca:

```text
$ /opt/homebrew/opt/sqlite/bin/sqlite3 …/13-laboratorio/entorno/datos/tienda.db ".backup …/respaldos-t37/tienda-copia.db"
$ /opt/homebrew/opt/sqlite/bin/sqlite3 …/respaldos-t37/tienda-copia.db "PRAGMA integrity_check; SELECT count(*) FROM pedidos;"
ok
1000000
```

- **`.backup`** copia la base página a página con la API de respaldo en línea, que su documentación
  describe precisamente para copiar una base en uso. Las rutas se acortan con `…`: la copia fue al
  scratchpad, fuera del corpus.
- **`PRAGMA integrity_check`** recorre la copia entera y responde `ok` si está sana; y el millón de
  pedidos está ahí. Es la restauración de prueba de SQLite: abrir la copia y comprobarla.

> **Veredicto:** los tres motores tienen respaldo en caliente y coherente, cada uno con su letra
> pequeña: `pg_restore -t` sin índices, `mysqldump` sin rutinas por defecto, y SQLite solo seguro
> con su API.

---

## 7. 🧭 Cómo se elige

- **Primero el RPO y el RTO que pide el negocio**, en minutos. De ahí sale la estrategia: sin PITR
  no hay RPO menor que el intervalo entre respaldos.
- **Físico con WAL continuo** como base, con un respaldo físico nuevo cada día o cada semana para
  acotar el WAL que habrá que aplicar.
- **Lógico además**, para restaurar tablas sueltas, cambiar de versión mayor o llevarse datos a otro
  sitio.
- **Verificación y restauración de prueba programadas**: `pg_verifybackup` tras cada respaldo, y una
  restauración completa cronometrada con regularidad, que es el RTO real.
- **Fuera de la máquina y fuera de la región**: un respaldo en el mismo disco muere con el disco.

**Cuánto cuesta**: espacio para el WAL de todo el periodo de recuperación, una máquina donde
restaurar a prueba, y alguien que mire los resultados. Es lo que diferencia «tenemos respaldo» de
«volvemos en veinte minutos perdiendo como mucho diez segundos».

---

## 8. 📜 Estándar, motor y convención

> **📜 Estándar o motor.** El estándar SQL no habla de respaldos. Las herramientas, los formatos y el
> registro de cambios son de cada motor; el RPO y el RTO son convención de continuidad de negocio.

| Afirmación | Categoría | PostgreSQL 18 | MySQL 9.7 | SQLite 3.53 |
|---|---|---|---|---|
| Respaldo lógico coherente sin parar | Motor | `pg_dump`: 18,69 s, 142 MB | `mysqldump --single-transaction`: 5,84 s, 835 MB | `.backup` |
| Respaldo físico en caliente | Motor | `pg_basebackup` | Herramientas aparte | `.backup` es físico |
| Recuperación a un instante | Motor | Físico más WAL | Volcado más *binary log* | No |
| Verificar un respaldo sin restaurarlo | Motor | `pg_verifybackup` | — | `PRAGMA integrity_check` en la copia |
| Restaurar una tabla sola trae sus índices | Motor | No, con `pg_restore -t` | — | — |
| El volcado por defecto incluye rutinas | Motor | Sí | No: hacen falta `--routines --events` | — |
| RPO y RTO | Convención | — | — | — |

**Convención, la que más se repite.** *«La réplica es nuestro respaldo»* — la réplica protege del
fallo de una máquina y replica al instante el error humano. El respaldo protege del error humano, y
solo si se puede volver a un instante anterior.

---

## ⚠️ Errores frecuentes

| Se dice | Lo preciso |
|---|---|
| "Tenemos respaldo diario" | Es un RPO de hasta 24 horas; sin WAL no hay nada mejor |
| "El respaldo terminó sin error, está bien" | Un byte cambiado dio `checksum mismatch`; y aun verificado, hay que restaurarlo |
| "Restaurar una tabla la deja como estaba" | `pg_restore -t` la restauró sin índices ni clave primaria |
| "La réplica sirve de respaldo" | Replica el `DELETE` sin `WHERE` en milisegundos |
| "El respaldo lógico es más rápido de restaurar" | Reconstruye todos los índices; el físico solo copia y arranca |
| "`mysqldump` lo guarda todo" | Sin `--routines --events` no guarda procedimientos ni eventos |
| "Un fichero de SQLite se respalda copiándolo" | Solo si nadie escribe; en caliente, con `.backup` |

---

## 📚 Para profundizar

- **Documentación** — PostgreSQL 18, «Backup and Restore»: lógico, físico y PITR.
  <https://www.postgresql.org/docs/18/backup.html>
- **Documentación** — PostgreSQL 18, «Continuous Archiving and Point-in-Time Recovery (PITR)».
  <https://www.postgresql.org/docs/18/continuous-archiving.html>
- **Documentación** — PostgreSQL 18, «pg_verifybackup»: qué comprueba y qué no.
  <https://www.postgresql.org/docs/18/app-pgverifybackup.html>
- **Documentación** — PostgreSQL 18, «pg_restore»: `-t` y los objetos dependientes.
  <https://www.postgresql.org/docs/18/app-pgrestore.html>
- **Documentación** — MySQL 9.7, «mysqldump»: `--single-transaction`.
  <https://dev.mysql.com/doc/refman/9.7/en/mysqldump.html>
- **Documentación** — MySQL 9.7, «Point-in-Time (Incremental) Recovery».
  <https://dev.mysql.com/doc/refman/9.7/en/point-in-time-recovery.html>
- **Documentación** — SQLite, «Using the SQLite Online Backup API».
  <https://www.sqlite.org/backup.html>

---

## 🧠 Preguntas

1. ¿Qué diferencia un respaldo lógico de uno físico? 🟢
2. ¿Qué son el RPO y el RTO? 🟢
3. ¿Qué es la recuperación a un instante, y qué necesita? 🟢
4. ¿Qué hace `pg_verifybackup`? ¿Lo fija el estándar o es cosa del motor? 🟡
5. ¿Por qué el volcado lógico ocupó 142 MB para una base de 1 316 MB? 🟡
6. ¿Por qué restaurar un volcado lógico tarda más que restaurar uno físico? 🟡
7. ¿Qué hace `--single-transaction` en `mysqldump`, y cuándo no basta? ¿Lo fija el estándar o es
   cosa del motor? 🟡
8. ¿Qué es el *binary log* de MySQL, y para qué sirve en una recuperación? 🟡
9. ¿Por qué copiar el fichero de SQLite no es un respaldo seguro, y qué lo es? 🟡
10. ¿Qué RPO da un `pg_dump` cada noche, y qué RPO da el WAL continuo? 🟠
11. ¿Por qué una réplica no es un respaldo? 🟠
12. ¿Por qué `pg_verifybackup` no basta, según su propia documentación? 🟠
13. ¿Qué le faltaba a `pagos` tras `pg_restore -t`, y cómo se usa bien una restauración selectiva? 🟠
14. ¿Por qué el volcado de MySQL ocupó casi seis veces más que el de PostgreSQL? 🟠
15. ¿Por qué el RTO de una recuperación a un instante crece con el tiempo desde el último respaldo
    físico? 🟠
16. Diseña la política de respaldos de la tienda para un RPO de un minuto y un RTO de treinta
    minutos, y cómo demostrarías que se cumple. 🔴
17. Diagnostica: tras restaurar `pedidos` desde el volcado nocturno para recuperar filas borradas,
    las consultas por código tardan segundos y se aceptan pedidos con código duplicado. 🔴
18. Defiende o refuta «con la réplica en otra zona no necesitamos respaldos», con lo que enseña el
    capítulo. 🔴

---

**Anterior:** [`01`](01-usuarios-roles-y-permisos.md) — usuarios, roles y permisos · **Siguiente:**
[`03`](03-migraciones-de-esquema.md) — migraciones de esquema · **Relacionado:**
[`l03`](../13-laboratorio/l03-respaldo-y-restauracion.md) — respaldo lógico, físico y PITR, en un
lab.
