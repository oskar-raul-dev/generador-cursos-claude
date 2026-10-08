# l02 — Aislamiento y bloqueos en vivo

> Dos y tres terminales abiertas contra la misma base: una lectura que cambia a mitad de transacción
> y el nivel que lo impide; una espera vista desde fuera, con quién bloquea a quién; los tres
> errores que la concurrencia produce a propósito —`lock_timeout`, el `40001` de serialización y el
> interbloqueo—, y dónde deja el servidor lo que el cliente no enseña; y la transacción olvidada que
> retiene bloqueos hasta que alguien la mata. **Tiempo estimado:** 30 minutos. **Asume levantado:**
> el entorno de [`l00`](l00-el-entorno-y-los-datos.md). **Asume leído:**
> [`04/02`](../04-transacciones-y-concurrencia/02-aislamiento-y-sus-fenomenos.md) y
> [`04/04`](../04-transacciones-y-concurrencia/04-bloqueos-e-interbloqueos.md), que explican lo que
> aquí se provoca. **Vigencia:** 24 de septiembre de 2026.

---

## Salto rápido

- [1. Qué vas a ver](#1--qué-vas-a-ver) · [2. Tres terminales](#2--paso-1--tres-terminales)
- [3. La lectura que cambia](#3--paso-2--la-lectura-que-cambia) · [4. La espera, vista desde
  fuera](#4--paso-3--la-espera-vista-desde-fuera)
- [5. El `40001`](#5--paso-4--el-40001-de-serialización) · [6. El interbloqueo y el
  registro](#6--paso-5--el-interbloqueo-y-el-registro-del-servidor)
- [7. La transacción olvidada](#7--paso-6--la-transacción-olvidada) · [Ejercicios](#-ejercicios) ·
  [Preguntas](#-preguntas)

---

## 1. 🎯 Qué vas a ver

La concurrencia no se aprende leyendo: se aprende viendo una terminal quedarse quieta mientras otra
termina. El bloque 04 explica cada fenómeno con su sesión pegada; este lab te pone a producirlos, y
añade lo que el bloque no enseña: **cómo se mira desde fuera** una base con sesiones esperándose, y
qué deja cada error en el cliente y en el registro del servidor.

**Las reglas de las sesiones**, las del bloque 04: toda escritura se deshace o se compensa en la
misma sesión, y `PED-00042` termina en `PAGADO` y `PED-99999` en `ANULADO`.

> **📝 Contexto.** Todo está corrido con tres `psql` abiertos a la vez sobre la copia aislada de
> [`l00`](l00-el-entorno-y-los-datos.md) §1, y cada bloque se pega en el orden en que ocurrió. **Los
> identificadores de proceso, de transacción y de tupla cambian en cada corrida** —2872, 830,
> `(10769,18)`—: lo que se lee es la forma del mensaje. **Longitud:** 482 líneas, por las sesiones
> de dos columnas; lab normal.

---

## 2. 🧱 Paso 1 — Tres terminales

Abre tres terminales, cada una con un nombre que luego se lea en el diagnóstico:

```bash
PGAPPNAME=sesion_a PGPASSWORD=postgres psql -h 127.0.0.1 -U postgres -d tienda
PGAPPNAME=sesion_b PGPASSWORD=postgres psql -h 127.0.0.1 -U postgres -d tienda
PGAPPNAME=sesion_c PGPASSWORD=postgres psql -h 127.0.0.1 -U postgres -d tienda
```

- `PGAPPNAME` fija el `application_name` de la conexión, que es la columna por la que
  `pg_stat_activity` dice quién es quién. Las aplicaciones reales deberían ponerlo siempre: en un
  incidente, «`sesion_b`» se lee mejor que un número de proceso.
- A y B son las que compiten; **C solo mira**, y nunca abre transacciones.

**El prompt es tu primer instrumento**: `tienda=#` fuera de una transacción, `tienda=*#` dentro, y
`tienda=!#` dentro de una que falló y solo acepta `ROLLBACK`. Si una terminal no devuelve el prompt,
está esperando.

---

## 3. 🩺 Paso 2 — La lectura que cambia

En `READ COMMITTED`, el nivel por defecto, **cada sentencia ve lo confirmado cuando empieza**. Dos
lecturas de la misma transacción pueden dar dos respuestas:

```text
-- sesión A                                    -- sesión B
BEGIN;
BEGIN
SELECT estado FROM pedidos
  WHERE codigo = 'PED-00042';
 estado
--------
 PAGADO
(1 fila)
                                               UPDATE pedidos SET estado = 'ENVIADO'
                                                 WHERE codigo = 'PED-00042';
                                               UPDATE 1
SELECT estado FROM pedidos
  WHERE codigo = 'PED-00042';
 estado
---------
 ENVIADO
(1 fila)
COMMIT;
COMMIT
                                               UPDATE pedidos SET estado = 'PAGADO'
                                                 WHERE codigo = 'PED-00042';
                                               UPDATE 1
```

- **Es la lectura no repetible** de
  [`04/02`](../04-transacciones-y-concurrencia/02-aislamiento-y-sus-fenomenos.md) §4. Un informe que
  lee el mismo dato dos veces en una transacción puede sumar cosas que nunca convivieron.
- **La última sentencia de B es la compensación**: devuelve `PED-00042` a `PAGADO`.

La misma secuencia con `REPEATABLE READ` en A:

```text
-- sesión A                                    -- sesión B
BEGIN ISOLATION LEVEL REPEATABLE READ;
BEGIN
SELECT estado FROM pedidos
  WHERE codigo = 'PED-00042';
 estado
--------
 PAGADO
(1 fila)
                                               UPDATE pedidos SET estado = 'ENVIADO'
                                                 WHERE codigo = 'PED-00042';
                                               UPDATE 1
SELECT estado FROM pedidos
  WHERE codigo = 'PED-00042';
 estado
--------
 PAGADO
(1 fila)
COMMIT;
COMMIT
SELECT estado FROM pedidos
  WHERE codigo = 'PED-00042';
 estado
---------
 ENVIADO
(1 fila)
                                               UPDATE pedidos SET estado = 'PAGADO'
                                                 WHERE codigo = 'PED-00042';
                                               UPDATE 1
```

- **A ve la misma foto toda la transacción**: la que tomó con su primera sentencia. Al confirmar, la
  siguiente lectura ya ve `ENVIADO`.
- **B no esperó en ningún momento.** Leer no bloquea a quien escribe en PostgreSQL: es el MVCC de
  [`04/03`](../04-transacciones-y-concurrencia/03-mvcc-frente-a-bloqueo.md). El precio llega en §5,
  cuando A intenta escribir sobre su foto.

---

## 4. 🩺 Paso 3 — La espera, vista desde fuera

A escribe y deja su transacción abierta; B quiere la misma fila; C mira:

```text
-- sesión A                                    -- sesión B
BEGIN;
BEGIN
UPDATE pedidos SET estado = 'ENVIADO'
  WHERE codigo = 'PED-00042';
UPDATE 1
                                               BEGIN;
                                               BEGIN
                                               UPDATE pedidos SET estado = 'ANULADO'
                                                 WHERE codigo = 'PED-00042';
                                               -- ⏸ sin respuesta: la fila la tiene A
```

Desde C, a los dos segundos:

```text
tienda=# SELECT pid, application_name AS sesion, state, wait_event_type, wait_event, pg_blocking_pids(pid) AS bloqueada_por, left(query, 40) AS consulta FROM pg_stat_activity WHERE application_name LIKE 'sesion_%' ORDER BY application_name;
 pid  |  sesion  |        state        | wait_event_type |  wait_event   | bloqueada_por |                 consulta
------+----------+---------------------+-----------------+---------------+---------------+------------------------------------------
 2872 | sesion_a | idle in transaction | Client          | ClientRead    | {}            | UPDATE pedidos SET estado = 'ENVIADO' WH
 2873 | sesion_b | active              | Lock            | transactionid | {2872}        | UPDATE pedidos SET estado = 'ANULADO' WH
 2871 | sesion_c | active              |                 |               | {}            | SELECT pid, application_name AS sesion,
(3 filas)
```

- **La culpable no está haciendo nada.** A está `idle in transaction`, esperando al cliente
  —`ClientRead`—: terminó su `UPDATE` y no confirmó. Es el perfil más común de un bloqueo en
  producción: una transacción abierta por código que se quedó esperando otra cosa.
- **B espera un `Lock` de tipo `transactionid`**: no espera a la fila, espera a que **termine la
  transacción** de A, el proceso 2872, que la escribió. Dura hasta su `COMMIT` o su `ROLLBACK`.
- **`pg_blocking_pids(pid)`** da la lista de quién bloquea a cada uno, sin leer `pg_locks` a mano.
  Es la consulta de [`04/04`](../04-transacciones-y-concurrencia/04-bloqueos-e-interbloqueos.md) §9.

A deshace, y B sigue en el acto:

```text
-- sesión A                                    -- sesión B
ROLLBACK;
ROLLBACK
                                               UPDATE 1
                                               ROLLBACK;
                                               ROLLBACK
```

**El error, a propósito: `lock_timeout`.** Por defecto B esperaría para siempre. Con un límite, la
espera se convierte en un error que la aplicación puede tratar:

```text
-- sesión A                                    -- sesión B
BEGIN;
BEGIN
UPDATE pedidos SET estado = 'ENVIADO'
  WHERE codigo = 'PED-00042';
UPDATE 1
                                               SET lock_timeout = '2s';
                                               SET
                                               UPDATE pedidos SET estado = 'ANULADO'
                                                 WHERE codigo = 'PED-00042';
                                               ERROR:  canceling statement due to lock timeout
                                               CONTEXTO:  while updating tuple (10769,18) in relation "pedidos"
ROLLBACK;
ROLLBACK
                                               RESET lock_timeout;
                                               RESET
```

- **`lock_timeout` limita solo la espera de un bloqueo**, no la sentencia entera —eso es
  `statement_timeout`—. Se fija por sesión o por transacción, y **`RESET` lo devuelve** al valor del
  servidor.
- B estaba en *autocommit*: el error canceló su sentencia y no dejó nada que deshacer. C comprobó al
  final que `PED-00042` seguía en `PAGADO`.

> **🩺 Diagnóstico.** Ante una aplicación colgada, la primera consulta es la de C. Si la fila
> culpable dice `idle in transaction`, el problema no está en la base: está en el código que abrió
> esa transacción y no la cerró.

---

## 5. 🩺 Paso 4 — El `40001` de serialización

**El caso**: A lee en `REPEATABLE READ`, B cambia la fila y confirma, y A intenta escribirla. `\set
VERBOSITY verbose` hace que `psql` enseñe el código SQLSTATE del error:

```text
-- sesión A                                    -- sesión B
\set VERBOSITY verbose
BEGIN ISOLATION LEVEL REPEATABLE READ;
BEGIN
SELECT estado FROM pedidos
  WHERE codigo = 'PED-00042';
 estado
--------
 PAGADO
(1 fila)
                                               UPDATE pedidos SET estado = 'ENVIADO'
                                                 WHERE codigo = 'PED-00042';
                                               UPDATE 1
UPDATE pedidos SET estado = 'ANULADO'
  WHERE codigo = 'PED-00042';
ERROR:  40001: could not serialize access due to concurrent update
UBICACIÓN:  ExecUpdate, nodeModifyTable.c:2602
ROLLBACK;
ROLLBACK
                                               UPDATE pedidos SET estado = 'PAGADO'
                                                 WHERE codigo = 'PED-00042';
                                               UPDATE 1
```

- **A decidía con una foto vieja**, y PostgreSQL se niega a que escriba sobre ella: en `READ
  COMMITTED` este `UPDATE` habría pisado el cambio de B sin avisar, que es la actualización perdida
  de [`04/02`](../04-transacciones-y-concurrencia/02-aislamiento-y-sus-fenomenos.md) §6.
- **`40001` es el código que la aplicación tiene que reconocer**, no el texto: significa «repite la
  transacción entera desde el principio». Es el bucle de reintento de `04/02` §9, y sin él este
  nivel solo convierte datos corruptos en errores.
- `UBICACIÓN` es el fichero y la línea del código de PostgreSQL que lo lanzó; solo sale con
  `VERBOSITY verbose` y no hace falta para diagnosticar.

---

## 6. 🩺 Paso 5 — El interbloqueo y el registro del servidor

**El caso**: A y B toman dos filas en orden inverso. El resultado es el interbloqueo de
[`04/04`](../04-transacciones-y-concurrencia/04-bloqueos-e-interbloqueos.md) §5, y lo que añade este
paso es **dónde está la información que el mensaje no da**.

```text
-- sesión A                                    -- sesión B
BEGIN;
BEGIN
UPDATE pedidos SET estado = 'PENDIENTE'
  WHERE codigo = 'PED-00042';
UPDATE 1
                                               BEGIN;
                                               BEGIN
                                               UPDATE pedidos SET estado = 'PENDIENTE'
                                                 WHERE codigo = 'PED-99999';
                                               UPDATE 1
UPDATE pedidos SET estado = 'PAGADO'
  WHERE codigo = 'PED-99999';
-- ⏸ espera a B
                                               UPDATE pedidos SET estado = 'PAGADO'
                                                 WHERE codigo = 'PED-00042';
                                               -- ⏸ espera a A: el ciclo está cerrado
ERROR:  deadlock detected
DETALLE:  Process 2957 waits for ShareLock on transaction 830; blocked by process 2956.
Process 2956 waits for ShareLock on transaction 829; blocked by process 2957.
SUGERENCIA:  See server log for query details.
CONTEXTO:  while updating tuple (10769,10) in relation "pedidos"
                                               UPDATE 1
ROLLBACK;
ROLLBACK
                                               COMMIT;
                                               COMMIT
                                               UPDATE pedidos SET estado = 'PAGADO'
                                                 WHERE codigo = 'PED-00042';
                                               UPDATE 1
                                               UPDATE pedidos SET estado = 'ANULADO'
                                                 WHERE codigo = 'PED-99999';
                                               UPDATE 1
```

- **Murió A**, la primera que se puso a esperar; B siguió en cuanto A soltó sus filas, confirmó y
  compensó en el acto. La víctima no necesita compensación: el motor deshizo su transacción entera.
- **El mensaje no dice qué sentencias formaban el ciclo**, y en una aplicación con cien rutas de
  código es lo único que importa. Lo dice `SUGERENCIA`: está en el registro del servidor.

```bash
docker logs --since 30s bd-lab-postgres
```

- `docker logs` imprime lo que el proceso del contenedor escribió en su salida, que en la imagen
  oficial de PostgreSQL es su registro. `--since 30s` limita a los últimos treinta segundos.

```text
2026-09-25 01:12:15.138 UTC [2957] ERROR:  deadlock detected
2026-09-25 01:12:15.138 UTC [2957] DETAIL:  Process 2957 waits for ShareLock on transaction 830; blocked by process 2956.
	Process 2956 waits for ShareLock on transaction 829; blocked by process 2957.
	Process 2957: UPDATE pedidos SET estado = 'PAGADO' WHERE codigo = 'PED-99999';
	Process 2956: UPDATE pedidos SET estado = 'PAGADO' WHERE codigo = 'PED-00042';
2026-09-25 01:12:15.138 UTC [2957] HINT:  See server log for query details.
2026-09-25 01:12:15.138 UTC [2957] CONTEXT:  while updating tuple (10769,10) in relation "pedidos"
2026-09-25 01:12:15.138 UTC [2957] STATEMENT:  UPDATE pedidos SET estado = 'PAGADO' WHERE codigo = 'PED-99999';
```

- **Las dos líneas `Process …:` son el diagnóstico**: la sentencia de cada lado del ciclo. Con ellas
  se encuentran las dos rutas de código que toman las filas en orden distinto, y la corrección es
  ordenar —por `id`, siempre en el mismo sentido—, no subir tiempos de espera.
- **El registro del servidor va en inglés** aunque el cliente esté en español: lo fija el
  `lc_messages` del servidor, no el de `psql`. La hora está en UTC.

---

## 7. 🩺 Paso 6 — La transacción olvidada

El perfil del §4 —una transacción `idle in transaction`— tiene un límite propio. A lo fija para su
sesión, abre una transacción, lee y se olvida; C la mira:

```text
-- sesión A
SET idle_in_transaction_session_timeout = '5s';
SET
BEGIN;
BEGIN
SELECT estado FROM pedidos WHERE codigo = 'PED-00042';
 estado
--------
 PAGADO
(1 fila)

-- sesión C, un segundo después
tienda=# SELECT application_name AS sesion, state, now() - xact_start AS transaccion_abierta, left(query, 45) AS ultima_consulta FROM pg_stat_activity WHERE state = 'idle in transaction';
  sesion  |        state        | transaccion_abierta |                ultima_consulta
----------+---------------------+---------------------+-----------------------------------------------
 sesion_a | idle in transaction | 00:00:02.714924     | SELECT estado FROM pedidos WHERE codigo = 'PE
(1 fila)

-- sesión A, pasados los cinco segundos
SELECT 1;
FATAL:  terminating connection due to idle-in-transaction timeout
el servidor ha cerrado la conexión inesperadamente
	Probablemente se debe a que el servidor terminó de manera anormal
	antes o durante el procesamiento de la petición.
La conexión al servidor se ha perdido. Intentando reiniciar: Con éxito.
```

- **El servidor cerró la conexión de A a los cinco segundos de inactividad**, y deshizo su
  transacción con todos sus bloqueos. A se enteró en su siguiente sentencia; `psql` reconectó solo,
  y una aplicación con *pool* vería una conexión rota que el *pool* tiene que descartar.
- **`xact_start` es la columna que delata la transacción larga**: cuánto lleva abierta, no cuánto
  lleva la última consulta. Una transacción abierta minutos retiene sus bloqueos y, si escribió,
  frena el `VACUUM`, como mide
  [`04/05`](../04-transacciones-y-concurrencia/05-optimista-pesimista-y-transacciones-largas.md).
- **Se fijó por sesión**, así que no hay nada que devolver: la sesión murió con él. En producción se
  fija por rol o en el servidor, con un valor de minutos, no de segundos.

---

## 8. 📜 Estándar, motor y convención

> **📜 Estándar o motor.** Los niveles de aislamiento y el código `40001` son del estándar ISO/IEC
> 9075; cómo se implementan, los tiempos de espera y las vistas de diagnóstico son de cada motor.

| Pieza | Estándar | PostgreSQL 18 | MySQL 9.7 (InnoDB) |
|---|---|---|---|
| Nivel por defecto | No lo fija | `READ COMMITTED` | `REPEATABLE READ` |
| Fallo de serialización | SQLSTATE `40001` | `40001`, también en `REPEATABLE READ` | No en `REPEATABLE READ`; el interbloqueo es el error 1213, con SQLSTATE `40001` |
| Límite de espera de bloqueo | No lo define | `lock_timeout`, sin límite por defecto | `innodb_lock_wait_timeout`, 50 s por defecto |
| Quién bloquea a quién | No lo define | `pg_stat_activity` y `pg_blocking_pids()` | `performance_schema.data_lock_waits` |
| Límite a la transacción inactiva | No lo define | `idle_in_transaction_session_timeout` | Solo `wait_timeout`, para cualquier conexión inactiva |

**Convención, la que más se repite.** *«Un interbloqueo se arregla subiendo el tiempo de espera»* —
el detector actúa tras `deadlock_timeout` y mata a una de las dos igual; lo que lo arregla es el
orden, y el orden solo se encuentra con las dos sentencias del registro.

---

## ⚠️ Errores frecuentes

| Se dice | Lo preciso |
|---|---|
| "La sesión que bloquea está haciendo algo pesado" | Lo habitual es que esté `idle in transaction`, esperando al cliente |
| "B espera a la fila" | Espera a que termine la transacción que la escribió: `Lock`, `transactionid` |
| "`REPEATABLE READ` evita todos los conflictos" | Los convierte en `40001`, que la aplicación tiene que reintentar |
| "El mensaje del interbloqueo dice qué sentencias chocaron" | Las dos sentencias están en el registro del servidor, no en el cliente |
| "`lock_timeout` limita cuánto tarda la sentencia" | Limita la espera de un bloqueo; la sentencia entera es `statement_timeout` |

---

## 🧪 Ejercicios

1. Repite el paso 2 en `SERIALIZABLE` y compara lo que ve A con lo que vio en `REPEATABLE READ`. 🟢
2. Mientras B espera en el paso 3, consulta `pg_locks` para la tabla `pedidos` desde C y di qué
   modos tiene cada sesión. 🟡
3. Escribe el bucle de reintento del paso 4 en el lenguaje que prefieras, con un máximo de tres
   intentos, y provoca el `40001` para verlo reintentar. 🟡
4. Repite el interbloqueo del paso 5 en MySQL y compara su mensaje con el de PostgreSQL. Busca las
   dos sentencias en `SHOW ENGINE INNODB STATUS`. 🟠
5. Cambia el orden del paso 5 para que las dos sesiones tomen las filas por `id` ascendente y
   comprueba que el interbloqueo desaparece, no que se hace más raro. 🟠
6. Diseña los valores de `lock_timeout`, `statement_timeout` e `idle_in_transaction_session_timeout`
   para el rol `tienda_app`, justificando cada uno, y aplícalos con `ALTER ROLE … SET`. Devuélvelos
   con `ALTER ROLE … RESET` al terminar. 🔴
7. Provoca un *write skew* en `REPEATABLE READ` y comprueba que `SERIALIZABLE` lo convierte en
   `40001`. 🔥 *(fuera de conteo)*

---

## 📚 Para profundizar

- **Documentación** — PostgreSQL 18, «Transaction Isolation».
  <https://www.postgresql.org/docs/18/transaction-iso.html>
- **Documentación** — PostgreSQL 18, «The Cumulative Statistics System»: `pg_stat_activity` y sus
  eventos de espera. <https://www.postgresql.org/docs/18/monitoring-stats.html>
- **Documentación** — PostgreSQL 18, «Client Connection Defaults»: `lock_timeout` e
  `idle_in_transaction_session_timeout`.
  <https://www.postgresql.org/docs/18/runtime-config-client.html>
- **Documentación** — PostgreSQL 18, «Explicit Locking»: los interbloqueos.
  <https://www.postgresql.org/docs/18/explicit-locking.html>
- **Documentación** — MySQL 9.7, «Deadlocks in InnoDB».
  <https://dev.mysql.com/doc/refman/9.7/en/innodb-deadlocks.html>

---

## 🧠 Preguntas

1. ¿Para qué sirve `PGAPPNAME`, y dónde se ve su valor? 🟢
2. ¿Qué significan los estados `active` e `idle in transaction` de `pg_stat_activity`? 🟢
3. ¿Qué hace `pg_blocking_pids()`? 🟢
4. ¿Qué limita `lock_timeout`, y qué lo distingue de `statement_timeout`? 🟢
5. Distingue lo que ve A en `READ COMMITTED` y en `REPEATABLE READ` cuando B cambia una fila entre
   sus dos lecturas. 🟡
6. ¿Por qué B espera un bloqueo de tipo `transactionid` y no uno sobre la fila? 🟡
7. ¿Qué significa el SQLSTATE `40001`, y qué tiene que hacer la aplicación al recibirlo? 🟡
8. ¿Qué parte de este lab es del estándar y qué parte del motor? Da dos ejemplos. 🟡
9. ¿Por qué en el paso 3 la sesión que bloquea está `idle in transaction`, y qué dice eso del
   código? 🟠
10. ¿Por qué el `UPDATE` de A falla en `REPEATABLE READ` y en `READ COMMITTED` no habría fallado? 🟠
11. ¿Qué información da el registro del servidor en un interbloqueo que el cliente no da? 🟠
12. ¿Qué pasa con los bloqueos de una sesión que supera `idle_in_transaction_session_timeout`, y qué
    ve su aplicación? 🟠
13. ¿Por qué subir `deadlock_timeout` no arregla los interbloqueos? 🟠
14. Diagnostica: una API se queda colgada y en `pg_stat_activity` hay una fila `idle in transaction`
    con `xact_start` de hace doce minutos. Da la secuencia de pasos, de la consulta a la corrección.
    🔴
15. Diseña cómo reproducirías en un entorno de pruebas un interbloqueo que aparece en producción una
    vez al día, partiendo del registro del servidor. 🔴

---

**Anterior:** [`l01`](l01-explain-e-indices-medidos.md) — `EXPLAIN` e índices medidos ·
**Siguiente:** [`l03`](l03-respaldo-y-restauracion.md) — respaldo y restauración · **Relacionado:**
[`04/04`](../04-transacciones-y-concurrencia/04-bloqueos-e-interbloqueos.md) — bloqueos e
interbloqueos · [`04/02`](../04-transacciones-y-concurrencia/02-aislamiento-y-sus-fenomenos.md) —
los niveles y sus fenómenos.
