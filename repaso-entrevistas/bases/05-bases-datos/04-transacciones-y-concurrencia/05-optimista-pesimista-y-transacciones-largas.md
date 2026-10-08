# 05 — Optimista, pesimista y transacciones largas

> La decisión entre las dos defensas contra la actualización perdida que
> [`02`](02-aislamiento-y-sus-fenomenos.md) §6 dejó apuntadas —la columna de versión y `FOR UPDATE`—
> y el factor que casi siempre la decide: **cuánto dura la transacción**. No hay mecanismo nuevo en
> este capítulo; hay una elección entre tres monedas que ya tienen nombre —espera, reintentos y
> abortos— y el precio de una transacción que dura lo que tarda un humano. **Asume leído:**
> [`04`](04-bloqueos-e-interbloqueos.md) — de ahí vienen `FOR UPDATE` y `lock_timeout` — y
> [`03`](03-mvcc-frente-a-bloqueo.md) §6, donde está el horizonte que una transacción larga congela.
> **Vigencia:** 22 de septiembre de 2026.

---

## Salto rápido

- [1. El problema](#1--el-problema) · [2. Las dos familias, y lo que cobra cada
  una](#2--las-dos-familias-y-lo-que-cobra-cada-una)
- [3. La columna de versión, corrida](#3--la-columna-de-versión-corrida) · [4. Cómo se
  elige](#4--cómo-se-elige)
- [5. La transacción larga, como decisión de
  diseño](#5--la-transacción-larga-como-decisión-de-diseño) · [6. Réplicas
  retrasadas](#6--réplicas-retrasadas)
- [7. Estándar, motor y convención](#7--estándar-motor-y-convención) · [Errores
  frecuentes](#️-errores-frecuentes) · [Para profundizar](#-para-profundizar) ·
  [Preguntas](#-preguntas)

---

## 1. 🎯 El problema

Un operador de soporte abre `PED-99999` en el panel interno: está `ANULADO`. Contesta una llamada,
decide que el cliente sí pagó y pulsa «Guardar» con el estado `PAGADO`. Mientras hablaba por
teléfono, otro operador había pasado el mismo pedido a `PENDIENTE` por un motivo que tenía sentido.
El segundo guardado pisa al primero, nadie ve un error, y el pedido queda con un estado que nadie
decidió con la información completa.

Es la actualización perdida de [`02`](02-aislamiento-y-sus-fenomenos.md) §6 con una diferencia que
lo cambia todo: **entre la lectura y la escritura hay un humano**, y con él dos peticiones HTTP, dos
préstamos distintos del *pool* de conexiones y varios minutos. `FOR UPDATE` no alcanza, porque el
bloqueo vive lo que vive la transacción y la transacción vive en una conexión
([`01`](01-acid-con-precision.md) §7). Y dejarla abierta esos minutos es el otro incidente del
bloque, el del horizonte de [`03`](03-mvcc-frente-a-bloqueo.md) §6.

```text
¿Dónde guardas el «yo leí esto» mientras el operador piensa?
¿Qué pasa si los dos pulsan «Guardar» en el mismo milisegundo?
¿Cuánto le cuesta a la base una transacción que dura lo que tarda una persona?
```

> **📝 Contexto.** Las sesiones están **corridas contra el entorno** y su salida es literal, las de
> dos terminales incluidas. Para enseñar la columna de versión, §3 **añade `pedidos.version` y la
> borra al terminar**, a la vista y con su tiempo medido: el esquema del corpus no la trae. Los
> `pid`, los identificadores de transacción y el `ctid` de §5 cambian en cada corrida. **Longitud:**
> capítulo de banda normal que cierra en 488 líneas, pasado el disparador de 400. Se podó prosa en
> tres sitios y no lleva `🔭 Dónde aparece de verdad`; `🧭 Cómo se elige` se queda porque la elección
> es la materia del capítulo, no un anexo.

---

## 2. 🧱 Las dos familias, y lo que cobra cada una

**Qué es:** dos formas opuestas de impedir que una escritura se haga sobre un dato que ya cambió.

- **Pesimista:** das por hecho que habrá conflicto y **reservas antes de leer**. Es `SELECT … FOR
  UPDATE`, cuyo dueño es [`04`](04-bloqueos-e-interbloqueos.md) §3: quien llega después espera.
- **Optimista:** das por hecho que no lo habrá, **no reservas nada**, y al escribir compruebas que
  lo que leíste sigue igual. Si cambió, la escritura no se aplica y el conflicto se le devuelve a
  quien lo provocó.

| | Pesimista (`FOR UPDATE`) | Optimista (columna de versión) |
|---|---|---|
| Cuándo se detecta el conflicto | Antes: al leer, esperando | Después: al escribir, fallando |
| Moneda que se paga | **Espera**, y una conexión ocupada | **Reintentos**, y trabajo tirado |
| Qué ve el usuario | Una pantalla que tarda | «Alguien cambió este pedido, recarga» |
| Puede cruzar dos peticiones HTTP | **No**: el bloqueo muere con la transacción | **Sí**: la versión viaja con el formulario |
| Interbloqueos posibles | Sí ([`04`](04-bloqueos-e-interbloqueos.md) §5) | No: nadie retiene nada |

**Quién lo manda:** **convención** para los dos nombres, que son del oficio y no de la norma. `FOR
UPDATE` es de estándar en los cursores y de motor en el `SELECT` suelto
([`04`](04-bloqueos-e-interbloqueos.md) §10). El control optimista **no es una función de ningún
motor**: es un `WHERE`, y lo que sí es de motor es cómo se comporta ese `WHERE` cuando dos llegan a
la vez (§3).

> **Veredicto:** pesimista cuando el conflicto es frecuente y la transacción es corta; optimista
> cuando el conflicto es raro o cuando entre leer y escribir hay algo que no controlas.

---

## 3. 🧱 La columna de versión, corrida

**Qué es:** un entero en la fila que **toda escritura incrementa**. Quien lee se guarda el valor;
quien escribe exige en el `WHERE` que siga siendo ese. Primero, la columna, que el esquema del
corpus no trae:

```text
tienda=# ALTER TABLE pedidos ADD COLUMN version integer NOT NULL DEFAULT 0;
ALTER TABLE
Duración: 8,285 ms
```

- **Ocho milisegundos sobre un millón de filas**, porque en PostgreSQL 18.6 añadir una columna con
  un `DEFAULT` constante **no reescribe la tabla**: guarda el valor en el catálogo y lo sirve a las
  filas antiguas al leerlas. Con un `DEFAULT` volátil —`now()`, `random()`— sí la reescribiría.

Ahora los dos operadores del §1, cada uno en su terminal y **sin transacción abierta entre la
lectura y la escritura**, que es justo lo que permite que el humano tarde lo que quiera:

```text
-- sesión A (operador 1)                  -- sesión B (operador 2)
SELECT estado, version FROM pedidos
  WHERE codigo='PED-99999';
 estado  | version
---------+---------
 ANULADO |       0
                                          SELECT estado, version FROM pedidos
                                            WHERE codigo='PED-99999';
                                           estado  | version
                                          ---------+---------
                                           ANULADO |       0
                                          UPDATE pedidos SET estado='PENDIENTE',
                                                 version=version+1
                                           WHERE codigo='PED-99999'
                                             AND version=0;
                                          UPDATE 1
-- A guarda lo que decidió con lo que leyó:
UPDATE pedidos SET estado='PAGADO',
       version=version+1
 WHERE codigo='PED-99999'
   AND version=0;
UPDATE 0
SELECT estado, version FROM pedidos
  WHERE codigo='PED-99999';
  estado   | version
-----------+---------
 PENDIENTE |       1
```

- **`UPDATE 0` es toda la señal.** No hay error ni excepción: la sentencia terminó bien y no tocó
  nada. **Si la aplicación no mira el número de filas afectadas, el control optimista no existe**, y
  ese olvido es el fallo más común del patrón.
- **A relee antes de decidir otra vez**, y ahora ve `PENDIENTE` y la versión 1. Es lo que el panel
  tiene que enseñar: el dato nuevo y la pregunta de si sigue queriendo guardar.

**¿Y si los dos guardan en el mismo milisegundo?** El `WHERE` y el `SET` van en **una sola
sentencia**, y el motor no deja que dos escriban la misma fila a la vez. La segunda espera al
bloqueo de fila, y al despertar **vuelve a evaluar el `WHERE` contra la versión confirmada**:

```text
-- sesión A                               -- sesión B
BEGIN;
UPDATE pedidos SET estado='ANULADO',
       version=version+1
 WHERE codigo='PED-99999'
   AND version=1;
UPDATE 1
                                          UPDATE pedidos SET estado='PAGADO',
                                                 version=version+1
                                           WHERE codigo='PED-99999'
                                             AND version=1;
                                          -- ⏸ bloqueada: la fila la tiene A
COMMIT;
                                          -- ▶ continúa y reevalúa el WHERE:
                                          UPDATE 0
                                          SELECT estado, version FROM pedidos
                                            WHERE codigo='PED-99999';
                                           estado  | version
                                          ---------+---------
                                           ANULADO |       2
```

- **Esto funciona en `READ COMMITTED`**, el nivel por defecto de PostgreSQL: B espera y después
  comprueba su condición sobre la fila nueva, que ya tiene versión 2. En `REPEATABLE READ` la misma
  B no daría `UPDATE 0` sino el `40001` de [`02`](02-aislamiento-y-sus-fenomenos.md) §6. Las dos son
  la misma noticia —«perdiste la carrera»— dicha de dos formas.
- **El `UPDATE` de A es a la vez la compensación**: devuelve `PED-99999` a `ANULADO`, y la columna
  se borra enseguida, que es la regla dura del [README del bloque](README.md):

```text
tienda=# ALTER TABLE pedidos DROP COLUMN version;
ALTER TABLE
Duración: 10,069 ms
```

- `DROP COLUMN` tampoco reescribe: **marca la columna como borrada en el catálogo** y deja que las
  filas nuevas no la lleven. Por eso es instantáneo, y por eso `pg_attribute` conserva una entrada
  invisible por cada columna borrada. No cambia ni un plan del corpus.

**Qué se usa como versión**, que es la pregunta que sigue siempre:

| Ficha | Cuándo sí | Cuándo no |
|---|---|---|
| Entero `version` | Siempre que puedas añadir la columna | — |
| Marca de tiempo (`actualizado_en`) | Si ya existe y las escrituras están espaciadas | Dos escrituras en el mismo milisegundo, o relojes de dos servidores |
| `xmin` de PostgreSQL | Si no puedes tocar el esquema | Si hay que migrar de motor: es columna de sistema, cambia con cualquier `UPDATE` de la fila, y no existe fuera de PostgreSQL |

**En MySQL el número que devuelve un `UPDATE` es de filas cambiadas, no encontradas**, y eso muerde
a cualquier comprobación que escriba el mismo valor que ya había:

```text
mysql> UPDATE pedidos SET estado = 'ANULADO' WHERE codigo = 'PED-99999';
Query OK, 0 rows affected (0.001 sec)
Rows matched: 1  Changed: 0  Warnings: 0
```

> **⚠️ Advertencia.** PostgreSQL responde `UPDATE 1` a esa misma sentencia
> ([`01`](01-acid-con-precision.md) §2), y SQLite da 1 en `changes()`. El código que interpreta «0
> filas» como «perdí la carrera» se equivoca en MySQL si la escritura no cambia nada. La defensa es
> que **la versión cambie siempre** —`version+1` nunca coincide con lo que había—; el protocolo de
> MySQL tiene además una bandera, `CLIENT_FOUND_ROWS`, para pedir las encontradas.

**Cuánto cuesta:** 4 bytes por fila, un incremento en cada escritura y, sobre todo, **el trabajo del
perdedor**, que tiene que releer y volver a decidir. **Cuándo sí:** conflictos raros, lecturas que
cruzan peticiones, formularios, API con `ETag`. **Cuándo no:** una fila muy disputada —el contador
de existencias de un producto en rebaja—, donde casi todos los intentos pierden.

---

## 4. 🧭 Cómo se elige

**El criterio, en cuatro preguntas y en este orden:**

```text
1. ¿El cálculo cabe en el UPDATE (SET total = total + 10)?   -> ni una ni otra: es gratis
2. ¿Entre leer y escribir hay un humano, una red o dos peticiones?  -> optimista, no hay otra
3. ¿Cuántas veces choca de verdad?  -> poco: optimista · mucho: pesimista
4. ¿La regla mira un conjunto y escribe OTRA fila?  -> ninguna de las dos: es write skew
```

- **La primera pregunta elimina la mitad de los casos** y es la que más se salta: la tercera fila de
  la tabla de [`02`](02-aislamiento-y-sus-fenomenos.md) §6 cierra el hueco entero sin columna ni
  bloqueo.
- **La cuarta no la resuelve ninguna de las dos**, porque las dos protegen una fila que se lee y se
  escribe: la regla repartida entre filas es el *write skew* de
  [`02`](02-aislamiento-y-sus-fenomenos.md) §7, y pide `SERIALIZABLE` o materializar el conflicto.

**La cuenta que decide la tercera pregunta.** Con diez procesos sobre la misma fila, el optimista
hace que en cada ronda gane uno y repitan los demás: 10 + 9 + … + 1 son **55 intentos para 10
escrituras**, y cada intento perdido es una lectura, un cálculo y un `UPDATE 0` tirados. El
pesimista hace esperar a los diez en fila, pero cada uno escribe a la primera. **Bajo contención
alta el optimista no falla: se vuelve caro**, y además de forma no lineal.

> **Veredicto:** el optimista gana por defecto en una aplicación web, porque es el único que
> sobrevive a una pausa humana. El pesimista se reserva para lo que es corto, frecuente y está
> entero dentro del servidor: una cola de trabajo, un saldo que se descuenta en la misma
> transacción.

---

## 5. 🩺 La transacción larga, como decisión de diseño

**Qué es:** una transacción que sigue abierta más tiempo del que tarda su trabajo. No la hace larga
el reloj sino **lo que hay dentro**: una llamada de red, una pausa humana, un lote de un millón de
filas en un solo `COMMIT`. Sus tres facturas ya tienen dueño y aquí solo se juntan: congela el
horizonte y frena el `VACUUM` ([`03`](03-mvcc-frente-a-bloqueo.md) §6), retiene sus bloqueos hasta
el final ([`04`](04-bloqueos-e-interbloqueos.md) §7) y en InnoDB alarga la cadena de *undo*
([`03`](03-mvcc-frente-a-bloqueo.md) §5).

Lo que este capítulo añade es **verlo y cortarlo**. El pesimista mal usado, con el operador del §1
dentro de la transacción:

```text
-- sesión A
tienda=# SET idle_in_transaction_session_timeout = '10s';
SET
tienda=# BEGIN;
BEGIN
tienda=*# SELECT estado FROM pedidos WHERE codigo = 'PED-99999' FOR UPDATE;
 estado
---------
 ANULADO
(1 fila)

-- sesión B, tres segundos después
tienda=# SELECT pid, state, backend_xid, backend_xmin, now() - xact_start AS abierta
           FROM pg_stat_activity WHERE state = 'idle in transaction';
  pid  |        state        | backend_xid | backend_xmin |     abierta
-------+---------------------+-------------+--------------+-----------------
 39765 | idle in transaction |        1052 |              | 00:00:03.147648
(1 fila)

tienda=# SET lock_timeout = '2s';
SET
tienda=# UPDATE pedidos SET estado = 'ANULADO' WHERE codigo = 'PED-99999';
ERROR:  canceling statement due to lock timeout
CONTEXTO:  while updating tuple (10769,119) in relation "pedidos"

-- sesión A, pasados los diez segundos
tienda=*# SELECT 1;
FATAL:  terminating connection due to idle-in-transaction timeout
el servidor ha cerrado la conexión inesperadamente
	Probablemente se debe a que el servidor terminó de manera anormal
	antes o durante el procesamiento de la petición.
La conexión al servidor se ha perdido. Intentando reiniciar: Con éxito.
```

- **`backend_xmin` está vacío y el horizonte sigue retenido.** En `READ COMMITTED` la instantánea se
  suelta al terminar cada sentencia, pero `FOR UPDATE` obligó a pedir un identificador de
  transacción —el 1052— para poder marcar la fila, y **una transacción con identificador en curso
  frena la limpieza igual que una instantánea**.
- **B no espera para siempre porque se puso un `lock_timeout`**; sin él, se habría quedado colgada
  detrás del operador ([`04`](04-bloqueos-e-interbloqueos.md) §6). Después del corte de A, el mismo
  `UPDATE` de B entró a la primera y respondió `UPDATE 1`.
- **El corte es `FATAL`, no `ERROR`**: el motor no aborta la transacción, **cierra la conexión**. Un
  *pool* que no valida sus conexiones le entregará a la siguiente petición una conexión muerta.

Y el precio medido, con una instantánea `REPEATABLE READ` abierta en B mientras A escribe dos
versiones de `PED-99999` y la segunda deja el estado como estaba:

```text
tienda=# VACUUM pedidos;                 -- con la instantánea de B abierta
VACUUM
tienda=# SELECT n_dead_tup FROM pg_stat_user_tables WHERE relname = 'pedidos';
 n_dead_tup
------------
          2
(1 fila)

tienda=# VACUUM pedidos;                 -- después del COMMIT de B
VACUUM
tienda=# SELECT n_dead_tup FROM pg_stat_user_tables WHERE relname = 'pedidos';
 n_dead_tup
------------
          0
(1 fila)
```

- **Dos versiones, porque solo había dos**; en producción son todas las escritas en la base desde
  que se abrió la transacción. Con `VERBOSE`, la primera pasada lo dice en su propia línea: `2 are
  dead but not yet removable`.

**Las tres guillotinas de PostgreSQL**, todas apagadas por defecto:

| Parámetro | Qué corta | Qué mata |
|---|---|---|
| `statement_timeout` | Una sentencia que tarda más de N | La sentencia (`ERROR`) |
| `idle_in_transaction_session_timeout` | Una transacción abierta y ociosa más de N | **La conexión** (`FATAL`) |
| `transaction_timeout` | Una transacción que dura más de N, trabaje o no | **La conexión** (`FATAL`) |

> **📝 Contexto.** `transaction_timeout` es de **PostgreSQL 17**; la mayoría de artículos que vas a
> encontrar no la conocen y resuelven lo mismo combinando las otras dos. Corrida aquí con `3s`, una
> transacción que duerme cinco segundos muere igual que la de arriba: `FATAL: terminating connection
> due to transaction timeout`.

- **En MySQL 9.7.2 no hay equivalente de la segunda ni de la tercera.** Lo más cercano es
  `wait_timeout`, **28 800 s** por defecto, que cierra una conexión ociosa —con transacción o sin
  ella— al cabo de ocho horas. **MariaDB 12.3.3 sí las tiene**: `idle_transaction_timeout` y sus
  variantes de lectura y escritura, las tres a 0 por defecto.
- **En SQLite no hay a quién cortar**: una transacción de lectura larga en modo WAL impide que el
  *checkpoint* recicle el fichero de WAL, que crece ([`03`](03-mvcc-frente-a-bloqueo.md) §9).

**Cómo se acorta, en vez de cortarla:** nada de red ni de humanos dentro —se lee fuera y se escribe
dentro, con la versión de §3 en el `WHERE`—, y los lotes por tramos de pocos miles de filas, de
forma que se puedan reanudar donde se cortaron.

> **Veredicto:** el tamaño de una transacción no lo decide el negocio, lo decide lo que está
> dispuesta a retener. Una operación de negocio de tres minutos son varias transacciones cortas, y
> la columna de versión es lo que las cose.

---

## 6. 🧱 Réplicas retrasadas

**Qué es:** el sitio donde una transacción larga hace daño **en otra máquina**. El entorno del
corpus no tiene réplica, así que esta sección **no se observa**; se explica por mecanismo, y se
diría con `pg_stat_database_conflicts` en la réplica y con `replay_lag` de `pg_stat_replication` en
el primario.

En PostgreSQL, un informe largo sobre una réplica de lectura necesita versiones que el `VACUUM` del
primario ya borró. Cuando la réplica tiene que aplicar esa limpieza, **choca con el informe** y solo
puede hacer una de dos cosas:

| La réplica… | Parámetro | Por defecto | Precio |
|---|---|---|---|
| Espera a que el informe termine | `max_standby_streaming_delay` | **30 s** | La réplica se retrasa: sirve datos viejos |
| Cancela el informe | — | pasados esos 30 s | `canceling statement due to conflict with recovery` |
| Avisa al primario de su horizonte | `hot_standby_feedback` | **`off`** | El informe de la réplica **frena el `VACUUM` del primario** |

- **La tercera fila es la trampa.** Activar `hot_standby_feedback` para que no se cancelen los
  informes traslada el horizonte de [`03`](03-mvcc-frente-a-bloqueo.md) §6 al primario: la tabla de
  producción se hincha por una consulta que corre en otra máquina.
- **En MySQL la forma es otra**: el *binlog* se escribe al confirmar, así que una transacción de
  cuarenta minutos llega entera a la réplica de golpe, y el retraso aparece después, no durante.

Los dos valores por defecto son los que da `pg_settings` en el servidor del corpus. La replicación
no es de este corpus: se nombra lo justo para ver dónde acaba la factura.

---

## 7. 📜 Estándar, motor y convención

> **📜 Estándar o motor.** ISO/IEC 9075 es de pago y **no he verificado sus cláusulas**. Lo único que
> aquí se atribuye a la norma es `FOR UPDATE` en los cursores; el control optimista es un patrón
> construido con SQL corriente, y los tiempos de corte son todos de motor.

| Afirmación | Estándar | PostgreSQL 18.6 | MySQL 9.7.2 / InnoDB | SQLite 3.53.4 |
|---|---|---|---|---|
| Existe «bloqueo optimista» como función | **No**: es un `WHERE` | No: se construye | No: se construye | No: se construye |
| El `UPDATE` devuelve filas encontradas | No lo define | Sí | **No**: cambiadas, salvo `CLIENT_FOUND_ROWS` | Sí, con `changes()` |
| El segundo `UPDATE` reevalúa su `WHERE` al despertar | No lo define | Sí, en `READ COMMITTED` | Sí | No hay dos escritores |
| Hay una versión de fila gratuita | No | `xmin` | No expuesta | No |
| Corta la transacción ociosa | No | `idle_in_transaction_session_timeout` | **No**: solo `wait_timeout`, 8 h | No |
| Corta la transacción por duración total | No | `transaction_timeout`, desde 17 | No | No |
| `ADD COLUMN` con `DEFAULT` constante sin reescribir | No lo define | Sí | Sí: `INSTANT` es el defecto | Sí |

**Convención, las dos que más se repiten.** *«El bloqueo optimista es más rápido»* — es más barato
cuando casi nunca choca y más caro cuando choca mucho: los 55 intentos para diez escrituras de §4. Y
*«el optimista no bloquea nada»* — no retiene nada entre la lectura y la escritura, pero su `UPDATE`
toma el bloqueo de fila igual que cualquier otro, y es precisamente esa espera la que hace correcta
la carrera del mismo milisegundo.

---

## ⚠️ Errores frecuentes

| Se dice | Lo preciso |
|---|---|
| "Pongo una columna de versión y ya está" | Sin mirar las filas afectadas no hay control: `UPDATE 0` no es un error y nadie se entera |
| "El optimista necesita `SERIALIZABLE`" | Funciona en `READ COMMITTED`: la segunda escritura espera y reevalúa el `WHERE` sobre la versión confirmada |
| "`FOR UPDATE` protege el formulario mientras el usuario edita" | El bloqueo muere con la transacción y la transacción con la conexión. Entre dos peticiones HTTP no hay nada que lo sostenga |
| "Una transacción ociosa no gasta nada" | Retiene bloqueos y, con identificador asignado, frena el `VACUUM` de toda la base aunque no tenga instantánea |
| "`idle_in_transaction_session_timeout` aborta la transacción" | Cierra la **conexión** con `FATAL`. El *pool* tiene que saber detectarlo |
| "Una marca de tiempo vale como versión" | Falla con dos escrituras en el mismo milisegundo y con relojes de dos servidores. Un entero no falla nunca |
| "Activo `hot_standby_feedback` y se acaban los problemas de la réplica" | Se acaban las cancelaciones y empieza la hinchazón del primario |

---

## 📚 Para profundizar

- **Documentación** — PostgreSQL 18, «Client Connection Defaults»: `statement_timeout`,
  `idle_in_transaction_session_timeout` y `transaction_timeout`, con lo que corta cada uno.
  <https://www.postgresql.org/docs/18/runtime-config-client.html>
- **Documentación** — PostgreSQL 18, «Hot Standby»: los conflictos con la recuperación y el precio
  de `hot_standby_feedback`. <https://www.postgresql.org/docs/18/hot-standby.html>
- **Documentación** — PostgreSQL 18, «ALTER TABLE»: por qué `ADD COLUMN` con `DEFAULT` constante y
  `DROP COLUMN` no reescriben la tabla. <https://www.postgresql.org/docs/18/sql-altertable.html>
- **Documentación** — MySQL 9.7, «Locking Reads»: `FOR UPDATE` y `FOR SHARE` en InnoDB.
  <https://dev.mysql.com/doc/refman/9.7/en/innodb-locking-reads.html>
- **Documentación** — MySQL 9.7, «Information Functions»: `ROW_COUNT()` y la diferencia entre filas
  cambiadas y encontradas. <https://dev.mysql.com/doc/refman/9.7/en/information-functions.html>
- **Documentación** — MariaDB, «Server System Variables»: `idle_transaction_timeout` y sus dos
  variantes.
  <https://mariadb.com/docs/server/server-management/variables-and-modes/server-system-variables>
- **Libro** — Martin Kleppmann, *Designing Data-Intensive Applications*, O'Reilly, 2017, capítulo 7,
  apartado «Preventing Lost Updates», con el *compare-and-set*.

---

## 🧠 Preguntas

1. ¿Qué es el control optimista y qué el pesimista, en una frase cada uno? 🟢
2. ¿Qué señal devuelve un `UPDATE` optimista que perdió la carrera, en PostgreSQL? 🟢
3. Nombra las tres guillotinas de PostgreSQL para transacciones y sentencias largas, y di su valor
   por defecto. 🟢
4. ¿Qué es `hot_standby_feedback` y cuál es su valor por defecto? 🟢
5. ¿Existe el «bloqueo optimista» en el estándar o en algún motor del corpus como función propia? 🟡
6. Diferencia `statement_timeout` de `idle_in_transaction_session_timeout`: qué corta cada uno y qué
   mata. 🟡
7. ¿Por qué `FOR UPDATE` no sirve para proteger un formulario que el usuario tarda tres minutos en
   guardar? 🟡
8. En MySQL, un `UPDATE` que escribe el mismo valor que ya había devuelve 0. ¿Qué categoría es esa
   diferencia con PostgreSQL y qué rompe en un control optimista? 🟡
9. Compara un entero, una marca de tiempo y `xmin` como ficha de versión: cuándo sirve cada uno. 🟡
10. Dos sesiones lanzan el mismo `UPDATE … WHERE version = 1` en el mismo milisegundo, en `READ
    COMMITTED`. Explica paso a paso qué hace el motor y por qué solo una gana. 🟠
11. Diez procesos compiten por la misma fila con control optimista. Haz la cuenta de intentos y di a
    partir de qué punto cambiarías de estrategia. 🟠
12. Una transacción en `READ COMMITTED` hizo un `FOR UPDATE` y lleva diez minutos ociosa, con
    `backend_xmin` vacío. ¿Frena el `VACUUM`? Explica por qué. 🟠
13. Tu *pool* empieza a devolver conexiones que fallan en la primera consulta desde que activaste
    `idle_in_transaction_session_timeout`. Explica el mecanismo y qué le pedirías al *pool*. 🟠
14. Un informe de dos horas en una réplica de PostgreSQL se cancela todas las noches. Da las dos
    salidas de configuración y el precio de cada una. 🟠
15. Escribe la secuencia completa —sentencias y comprobaciones— de un guardado optimista de un
    formulario sobre `pedidos`, desde que se abre la pantalla hasta que se confirma o se rechaza. 🔴
16. Diagnostica: la tabla `pedidos` del primario crece un 5 % al día y en el primario no hay ninguna
    transacción larga. Da tres hipótesis en orden de probabilidad y la consulta con la que
    comprobarías la primera. 🔴
17. Un lote nocturno actualiza 270 000 pedidos en una sola transacción de cuarenta minutos. Rediseña
    su forma de confirmar, di qué propiedad tiene que cumplir para poder reanudarse, y qué ganas en
    cada una de las facturas del §5. 🔴

---

**Anterior:** [`04`](04-bloqueos-e-interbloqueos.md) — el bloqueo que aquí se elige o se evita ·
**Siguiente:** [`06`](06-wal-durabilidad-y-fsync.md) — qué significa «confirmado» cuando se va la
luz · **Relacionado:** [`02`](02-aislamiento-y-sus-fenomenos.md) §6 — las tres defensas contra la
actualización perdida · [`03`](03-mvcc-frente-a-bloqueo.md) §6 — el horizonte que una transacción
larga congela.
