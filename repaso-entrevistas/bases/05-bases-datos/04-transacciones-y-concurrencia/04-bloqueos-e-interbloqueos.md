# 04 — Bloqueos e interbloqueos

> Lo único que [`03`](03-mvcc-frente-a-bloqueo.md) no quitó: cuando dos transacciones quieren
> escribir lo mismo, alguien espera. Aquí están los modos de bloqueo (*lock*) que existen, los que
> pides tú con `FOR UPDATE`, el interbloqueo (*deadlock*) provocado a propósito con sus dos mensajes
> de error reales, y la regla de una línea que lo previene. **Asume leído:**
> [`03`](03-mvcc-frente-a-bloqueo.md) — de ahí viene por qué el lector no aparece en ninguna de
> estas esperas. **Vigencia:** 20 de septiembre de 2026.

---

## Salto rápido

- [1. El problema](#1--el-problema) · [2. Qué se bloquea, y en qué
  modo](#2--qué-se-bloquea-y-en-qué-modo)
- [3. El bloqueo que pides tú](#3--el-bloqueo-que-pides-tú) · [4. NOWAIT y SKIP
  LOCKED](#4--nowait-y-skip-locked)
- [5. El interbloqueo, provocado a propósito](#5--el-interbloqueo-provocado-a-propósito) · [6. Cómo
  lo ve cada motor](#6-️-cómo-lo-ve-cada-motor)
- [7. El bloqueo de tabla que tumba un despliegue](#7--el-bloqueo-de-tabla-que-tumba-un-despliegue)
  · [8. Cómo se evita](#8--cómo-se-evita)
- [9. Diagnóstico: quién bloquea a quién](#9--diagnóstico-quién-bloquea-a-quién) · [10. Estándar,
  motor y convención](#10--estándar-motor-y-convención)
- [Errores frecuentes](#️-errores-frecuentes) · [Para profundizar](#-para-profundizar) ·
  [Preguntas](#-preguntas)

---

## 1. 🎯 El problema

A las tres de la mañana corren dos procesos. El de conciliación recorre los pedidos anulados y les
apunta el pago de compensación; el de cierre recorre los pagados y les mueve el estado. Cada uno
toca dos pedidos, `PED-00042` y `PED-99999`, y cada uno los toca **en el orden que le resultó
natural a quien lo escribió**: el primero por código ascendente, el segundo por fecha.

Tres noches de cada diez, uno de los dos muere con esto:

```text
ERROR:  deadlock detected
DETALLE:  Process 89952 waits for ShareLock on transaction 1033; blocked by process 89953.
Process 89953 waits for ShareLock on transaction 1032; blocked by process 89952.
SUGERENCIA:  See server log for query details.
CONTEXTO:  while updating tuple (10769,112) in relation "pedidos"
```

Lo que **no** sirve es "hay demasiada concurrencia" ni "súbele el *timeout*". Lo que sirve son tres
frases: qué bloqueo tomó cada uno, en qué orden, y por qué invertir ese orden hace que el problema
desaparezca del todo —no que se reduzca—.

> **📝 Contexto.** Las sesiones de este capítulo están **corridas contra el entorno**, las dos
> terminales incluidas, y el mensaje de arriba es el que produjo el interbloqueo de §5 tal cual
> salió. Los **identificadores de proceso y de transacción cambian en cada corrida** —89952, 1033,
> el `ctid` del `CONTEXTO`—: lo que se lee es la forma del mensaje, el ciclo entre los dos procesos,
> no el número.

---

## 2. 🧱 Qué se bloquea, y en qué modo

**Qué es:** un bloqueo es una reserva sobre un objeto, tomada en un **modo**, que dura hasta el
final de la transacción. Lo que decide si dos sesiones se estorban no es que las dos "toquen la
tabla": es si sus dos modos **entran en conflicto**.

Hay dos niveles, y se confunden constantemente:

| | Bloqueo de tabla | Bloqueo de fila |
|---|---|---|
| Qué protege | La tabla como objeto: su estructura y su existencia | Una fila concreta |
| Quién lo toma | Toda sentencia, incluido un `SELECT` | Quien escribe, o quien lo pide con `FOR …` |
| Cuántos caben | Ocho modos, con una matriz de conflictos | Cuatro modos en PostgreSQL |
| Dónde se ve | `pg_locks` | `pg_locks`, y en la propia fila con `xmax` |

Los modos de tabla de PostgreSQL que de verdad hay que saber, con quién los toma:

```text
ACCESS SHARE        SELECT                              -- estorba solo a ACCESS EXCLUSIVE
ROW SHARE           SELECT ... FOR UPDATE / FOR SHARE
ROW EXCLUSIVE       INSERT, UPDATE, DELETE              -- dos escritores NO se estorban aquí
SHARE UPDATE EXCL.  VACUUM, ANALYZE, CREATE INDEX CONCURRENTLY
SHARE               CREATE INDEX (sin CONCURRENTLY)
ACCESS EXCLUSIVE    ALTER TABLE, DROP, TRUNCATE, VACUUM FULL  -- estorba a TODOS
```

- **Dos `UPDATE` sobre filas distintas no se estorban**, aunque tomen `ROW EXCLUSIVE` sobre la misma
  tabla: ese modo **no choca consigo mismo**. Lo que los enfrenta es el bloqueo de fila.
- **`ACCESS EXCLUSIVE` es el único que choca con todo**, y por eso es el que aparece en todos los
  incidentes de despliegue (§7).
- **En MySQL la lista es otra** con la misma idea, más los *metadata locks*: los toma cualquier
  sentencia y bloquean el DDL mientras existan.

Los modos de fila de PostgreSQL, de más débil a más fuerte, y qué los toma:

| Modo | Lo toma | Bloquea a |
|---|---|---|
| `FOR KEY SHARE` | Una clave foránea que comprueba que el padre existe | `FOR UPDATE` |
| `FOR SHARE` | `SELECT … FOR SHARE` | Todo lo que escriba la fila |
| `FOR NO KEY UPDATE` | Un `UPDATE` normal, que no toca columnas de clave | `FOR SHARE` y más fuertes |
| `FOR UPDATE` | `SELECT … FOR UPDATE`, `DELETE`, y el `UPDATE` que sí toca la clave | Todos |

> **🧠 Modelo mental.** Los bloqueos no se piden sobre "la tabla" ni sobre "la fila" a secas: se
> piden **sobre un objeto y en un modo**. La pregunta útil nunca es "¿esto bloquea?", sino "¿qué
> modo toma, sobre qué, y contra qué modo choca?".

**Quién lo manda:** **motor**, entero: el estándar no nombra ni un modo de bloqueo (§10). **Cuánto
cuesta:** no la memoria donde se anotan, sino **la espera** — una conexión ocupada sin hacer nada.

---

## 3. 🧱 El bloqueo que pides tú

**Qué es:** `SELECT … FOR UPDATE` lee **y reserva** esas filas, como si las hubieras actualizado,
hasta el final de la transacción. Es la respuesta al leer-decidir-escribir que
[`02`](02-aislamiento-y-sus-fenomenos.md) §6 dejó abierto: entre el `SELECT` y el `UPDATE` no cabe
nadie.

```text
-- sesión A                                  -- sesión B
BEGIN;
SELECT estado FROM pedidos
  WHERE codigo='PED-99999' FOR UPDATE;
 estado
---------
 ANULADO
                                             BEGIN;
                                             SELECT estado FROM pedidos
                                               WHERE codigo='PED-99999' FOR UPDATE;
                                             -- ⏸ bloqueada: espera a que A termine
UPDATE pedidos SET estado='PENDIENTE'
  WHERE codigo='PED-99999';
UPDATE 1
COMMIT;
                                             -- ▶ continúa, y lee el valor ya actualizado:
                                              estado
                                             ------------
                                              PENDIENTE
                                             ROLLBACK;
-- compensación inmediata, en A:
UPDATE pedidos SET estado='ANULADO' WHERE codigo='PED-99999';
UPDATE 1
```

- **B se queda esperando en el `SELECT`, no en el `UPDATE`.** Es lo que se quiere: cuando despierta
  lee el estado nuevo y decide con él, en vez de pisar el trabajo de A.
- **Un `SELECT` normal de una tercera sesión no habría esperado.** MVCC sigue funcionando
  ([`03`](03-mvcc-frente-a-bloqueo.md) §2): `FOR UPDATE` estorba a quien escribe o pide bloqueo.
- **La compensación va en A y va inmediatamente**, porque A confirmó: es la regla dura del [README
  del bloque](README.md), y deja `PED-99999` otra vez en `ANULADO`.

**`FOR SHARE` es el hermano débil:** varias sesiones lo tienen a la vez sobre la misma fila y todas
bloquean a quien la escriba. Sirve para "leo esto y nadie lo cambia mientras trabajo", y **es una
fábrica de interbloqueos** si luego las dos escriben: las dos tienen el compartido, las dos quieren
el exclusivo.

**Quién lo manda:** `FOR UPDATE` **está en el estándar**, en la definición de cursor, y los tres
motores lo aceptan en un `SELECT` suelto; los modos finos —`FOR NO KEY UPDATE`, `FOR KEY SHARE`— son
**de motor**, solo de PostgreSQL.

**Cuánto cuesta:** concurrencia de la cara: una fila muy disputada convierte el sistema en una fila
india. **Cuándo sí:** hay que decidir en la aplicación, el conflicto es frecuente y el trabajo entre
`SELECT` y `COMMIT` es corto. **Cuándo no:** si el cálculo cabe en el `UPDATE` —`SET total = total +
10` es gratis—, y **nunca** si entre el bloqueo y el `COMMIT` hay red o un humano.

---

## 4. 🧱 NOWAIT y SKIP LOCKED

**Qué es:** dos modificadores de `FOR UPDATE` que cambian lo que pasa cuando la fila ya está
bloqueada. Sin ellos se espera; con ellos, o se falla al instante, o se pasa de largo.

```text
-- sesión A: toma la fila y se queda dentro   -- sesión B
BEGIN;
SELECT codigo FROM pedidos
  WHERE codigo='PED-99999' FOR UPDATE;
  codigo
-----------
 PED-99999
                                              BEGIN;
                                              SELECT codigo FROM pedidos WHERE
                                                codigo='PED-99999' FOR UPDATE NOWAIT;
                                              ERROR:  could not obtain lock on row
                                                in relation "pedidos"
                                              ROLLBACK;
ROLLBACK;
```

- **`NOWAIT`** falla inmediatamente con `55P03` (*lock not available*) en vez de esperar. Sirve para
  que un proceso interactivo diga "está ocupado, vuelve luego" en lugar de colgarse.
- **`SKIP LOCKED`** no falla: **omite del resultado** las filas que otro tiene bloqueadas. Es la
  forma correcta de repartir trabajo entre varios consumidores sin coordinarlos:

```sql
-- Cada trabajador toma cinco pedidos que nadie más esté procesando.
BEGIN;
SELECT id, codigo FROM pedidos
 WHERE estado = 'PENDIENTE'
 ORDER BY creado_en
 LIMIT 5
   FOR UPDATE SKIP LOCKED;
-- ... se procesan, se actualizan, y el COMMIT suelta los bloqueos.
COMMIT;
```

Corrida en dos sesiones a la vez, cada una se lleva cinco pedidos **distintos** y ninguna espera:

```text
-- sesión A                                   -- sesión B, a la vez
   id   |   codigo                               id   |   codigo
--------+------------                         --------+------------
 896622 | PED-896622                            99362 | PED-99362
 414826 | PED-414826                           251768 | PED-251768
 890588 | PED-890588                           542198 | PED-542198
 403475 | PED-403475                           282183 | PED-282183
 736858 | PED-736858                            19310 | PED-19310
(5 filas)                                     (5 filas)
```

- **Ni un identificador repetido entre las dos columnas**, y las de B son exactamente **las cinco
  siguientes por `creado_en`**: B no esperó a A, se saltó lo que A tenía y siguió por la cola.
- **Sin `SKIP LOCKED`, cinco trabajadores con esta consulta se ponen en fila** detrás del primero:
  todos piden las mismas filas más antiguas y cuatro esperan. Con él, cada uno se lleva cinco
  distintas y ninguno espera.
- **El precio es que el resultado ya no es determinista**: dos ejecuciones idénticas devuelven
  conjuntos distintos. Por eso es correcto en una cola de trabajo y es un error en un informe.
- **`ORDER BY` no te salva del desorden**: ordena lo que quedó después de omitir.

**Quién lo manda:** **motor**, aunque ya no distinga a nadie: PostgreSQL los tiene desde hace una
década y MySQL 8.0 los añadió; SQLite, ninguno: con un solo escritor la pregunta no se plantea.

**Cuánto cuesta:** nada por sí mismos; cuesta la alternativa que sustituyen, una tabla de "quién
procesa qué" que hay que limpiar cuando un trabajador muere.

> **💡 Truco.** Cuando alguien propone Redis o una cola dedicada «porque la base no sabe repartir
> trabajo», `FOR UPDATE SKIP LOCKED` es la respuesta de una línea. No sustituye a una cola de verdad
> cuando hay millones de mensajes, pero para decenas de miles al día evita un sistema entero.

---

## 5. 🩺 El interbloqueo, provocado a propósito

**Qué es:** dos transacciones que se esperan en círculo. A tiene lo que B quiere, B tiene lo que A
quiere, y ninguna puede soltar nada porque los bloqueos duran hasta el final de la transacción.
Nadie hizo nada mal por separado: **la única causa es el orden**.

```text
-- sesión A                                  -- sesión B
BEGIN;
UPDATE pedidos SET estado='PENDIENTE'
  WHERE codigo='PED-00042';
UPDATE 1
                                             BEGIN;
                                             UPDATE pedidos SET estado='PENDIENTE'
                                               WHERE codigo='PED-99999';
                                             UPDATE 1
UPDATE pedidos SET estado='PAGADO'
  WHERE codigo='PED-99999';
-- ⏸ bloqueada: la fila la tiene B
                                             UPDATE pedidos SET estado='PAGADO'
                                               WHERE codigo='PED-00042';
                                             -- ⏸ un instante, y sigue: A ya murió
-- ...un segundo después, el motor mata a A:
ERROR:  deadlock detected
DETALLE:  Process 89952 waits for ShareLock
  on transaction 1033; blocked by process 89953.
Process 89953 waits for ShareLock on
  transaction 1032; blocked by process 89952.
SUGERENCIA:  See server log for query details.
CONTEXTO:  while updating tuple (10769,112)
  in relation "pedidos"
ROLLBACK;
                                             -- ▶ B continúa y termina:
                                             UPDATE 1
                                             COMMIT;
                                             -- compensación inmediata, en B:
                                             UPDATE pedidos SET estado='PAGADO'
                                               WHERE codigo='PED-00042';
                                             UPDATE pedidos SET estado='ANULADO'
                                               WHERE codigo='PED-99999';
```

**Cómo se escribe una demostración cuyo final mata una sesión**, que es la decisión que este
capítulo tenía que tomar y deja fijada para el bloque:

- **La víctima no necesita compensación.** El motor la aborta entera: nada de lo que escribió quedó,
  y es el único caso del bloque donde deshacer sale gratis.
- **La superviviente sí.** Deja sus dos `UPDATE` compensados inmediatamente después del `COMMIT`,
  devolviendo `PED-00042` a `PAGADO` y `PED-99999` a `ANULADO`, que son sus estados fijos.
- **Cuál de las dos muere no se elige.** Aquí muere **A**, y es repetible: PostgreSQL mata a la
  primera que agota su `deadlock_timeout`, la primera que se puso a esperar. Con otro entrelazado
  puede ser la otra, así que la demostración no depende de ello: compensa la que sobreviva.

**El detector no corre todo el rato.** PostgreSQL espera `deadlock_timeout` —**un segundo por
defecto**— antes de buscar un ciclo; si la espera se resuelve sola, no hay nada que detectar. Por
eso un interbloqueo tarda **al menos un segundo**, y ese segundo es la pista de que lo fue.

**Cuánto cuesta:** una transacción entera perdida y repetida, más el segundo de espera. **Cuándo es
tolerable:** si son raros y el código reintenta. **Cuándo no:** si son sistemáticos, que siempre
significa dos rutas de código accediendo a lo mismo en orden distinto (§8).

---

## 6. ⚖️ Cómo lo ve cada motor

**Qué es:** el mismo ciclo, tres comportamientos distintos. Es la tabla que conviene tener en la
cabeza, porque el código que reintenta depende de ella.

| | PostgreSQL 18.6 | MySQL 9.7.2 / InnoDB | SQLite 3.53.4 |
|---|---|---|---|
| Cuándo detecta | Tras `deadlock_timeout`, 1 s por defecto | Al instante, con el grafo de espera | No hay ciclo posible entre escritores |
| Error | `ERROR: deadlock detected`, `40P01` | `ERROR 1213`, `SQLSTATE 40001` | `SQLITE_BUSY` por espera, no por ciclo |
| A quién mata | A la que detecta el ciclo | A la que **menos trabajo** ha hecho | — |
| Espera vencida | `lock_timeout`, **desactivado** por defecto | `innodb_lock_wait_timeout`, **50 s** | `busy_timeout`, 0 por defecto |
| Dónde se ve el último | En el log del servidor | `SHOW ENGINE INNODB STATUS` | — |

- **La fila que más sorprende es la de la espera vencida.** Sin `lock_timeout`, una sesión bloqueada
  espera **para siempre**; InnoDB se rinde a los cincuenta segundos con un error distinto del de
  interbloqueo. Es la asimetría de `02` §8: cuelgue en uno, fallo tardío en el otro.
- **InnoDB elige víctima por trabajo hecho**, para deshacer lo menos posible —su *undo log* hace el
  `ROLLBACK` proporcional ([`03`](03-mvcc-frente-a-bloqueo.md) §5)—. PostgreSQL no tiene ese
  incentivo: deshacer le cuesta lo mismo.
- **El `SQLSTATE` de MySQL para el interbloqueo es `40001`**, el mismo que PostgreSQL usa para los
  conflictos de serialización de `02` §6. Conviene saberlo: **un bucle de reintento escrito para
  `40001` cubre el interbloqueo de MySQL**, y en PostgreSQL hay que añadir `40P01` aparte.

---

## 7. 🧱 El bloqueo de tabla que tumba un despliegue

**Qué es:** el incidente más común de este capítulo, y el que nunca se atribuye a un bloqueo. La
migración lleva un `ALTER TABLE`, que pide `ACCESS EXCLUSIVE`; hay un informe leyendo `pedidos`
desde hace cuarenta segundos con `ACCESS SHARE`; y el `ALTER` se pone **en la cola**.

```text
informe (ACCESS SHARE, 40 s)       -> corriendo
ALTER TABLE  (ACCESS EXCLUSIVE)    -> ⏸ espera al informe
SELECT del checkout (ACCESS SHARE) -> ⏸ espera al ALTER, que está delante en la cola
SELECT del checkout                -> ⏸ ...
```

- **Lo que tira la aplicación no es el `ALTER`: es la cola detrás del `ALTER`.** Los `SELECT` del
  *checkout* no chocan con el informe —dos `ACCESS SHARE` conviven—, pero **no adelantan** al
  `ACCESS EXCLUSIVE` que llegó antes: cuarenta segundos de informe, cuarenta de sitio caído.
- **La defensa cabe en dos líneas**, y es lo que hay que saber decir en una entrevista de banca:

```sql
SET lock_timeout = '3s';       -- si no consigo el bloqueo en 3 s, fallo yo y no tumbo a nadie
ALTER TABLE pedidos ADD COLUMN canal text;
```

Corrido con el informe de arriba abierto en otra terminal, el que se rinde es el `ALTER`:

```text
tienda=*# ALTER TABLE pedidos ADD COLUMN canal text;
ERROR:  canceling statement due to lock timeout
```

- **`lock_timeout` no acelera nada**: hace que falle la migración, que se reintenta, en vez de la
  aplicación entera. Un `ADD COLUMN` sin `DEFAULT` volátil es instantáneo —solo toca el catálogo—,
  así que el riesgo entero está en **conseguir** el bloqueo, no en usarlo.
- **En MySQL el mecanismo tiene otro nombre y el mismo final**: el *metadata lock* que sostiene
  cualquier transacción abierta —incluida una que solo leyó— bloquea el DDL, y detrás se forma la
  misma cola.
- **`CREATE INDEX` tiene su propia salida**: `CONCURRENTLY` toma `SHARE UPDATE EXCLUSIVE` en vez de
  `SHARE` y no bloquea escrituras; a cambio tarda más y puede dejar un índice inválido.

> **⚠️ Advertencia.** Una transacción abierta y ociosa —el `idle in transaction` de
> [`03`](03-mvcc-frente-a-bloqueo.md) §6— es a la vez la causa de que el disco crezca **y** la causa
> de que un despliegue se cuelgue. Es el mismo incidente contado dos veces, y por eso vigilar las
> transacciones largas rinde el doble de lo que parece.

---

## 8. 🧭 Cómo se evita

**El criterio, en orden de eficacia.** Los dos primeros eliminan el problema; los demás lo hacen
tolerable.

```text
1. Acceder siempre en el MISMO ORDEN         -> elimina el interbloqueo, no lo reduce
2. Tocar una sola fila por transacción       -> no hay ciclo posible con un solo recurso
3. Transacciones cortas, sin red ni humanos  -> menos ventana para cruzarse
4. lock_timeout / innodb_lock_wait_timeout   -> convierte la cuelgue en un error manejable
5. Bucle de reintento                        -> para lo que quede, que siempre queda algo
```

- **El orden fijo es la única solución completa**, y es barata: basta con que todas las rutas
  ordenen por la misma columna —`ORDER BY id` en el `SELECT … FOR UPDATE`— para que dos procesos no
  se crucen. El interbloqueo de §1 venía de ordenar uno por código y el otro por fecha.
- **Subir el *timeout* no arregla nada**: un interbloqueo es un ciclo, y un ciclo no se deshace
  esperando más. Lo único que consigue esperar más es que la sesión bloqueada ocupe la conexión más
  tiempo.
- **El reintento es el mismo bucle de `02` §9**, con las mismas tres condiciones —transacción
  entera, solo los códigos que lo merecen, trabajo repetible— y con `40P01` añadido a la lista en
  PostgreSQL.

> **Veredicto:** un interbloqueo no es un problema de carga, es un problema de orden. Si aparece
> bajo carga es porque la carga hace probable un cruce que siempre fue posible.

---

## 9. 🩺 Diagnóstico: quién bloquea a quién

**Qué es:** la consulta que hay que tener memorizada: en un incidente no da tiempo a buscarla. En
PostgreSQL, `pg_blocking_pids()` recorre `pg_locks` por ti:

```sql
SELECT bloqueada.pid            AS espera,
       bloqueada.query          AS consulta_en_espera,
       pg_blocking_pids(bloqueada.pid) AS bloqueada_por,
       now() - bloqueada.xact_start    AS lleva_esperando
  FROM pg_stat_activity AS bloqueada
 WHERE cardinality(pg_blocking_pids(bloqueada.pid)) > 0
 ORDER BY lleva_esperando DESC;
```

Corrida con el `ALTER TABLE` de §7 detrás de un informe —los `pid` cambian en cada corrida—:

```text
 espera |             consulta_en_espera             | bloqueada_por | lleva_esperando
--------+--------------------------------------------+---------------+-----------------
  90005 | ALTER TABLE pedidos ADD COLUMN canal text; | {90004}       | 00:00:04.349993
(1 fila)
```

- **`pg_blocking_pids()` devuelve una lista**, no un número: se puede esperar a varias a la vez, y
  el culpable de verdad no sale aquí porque **él no espera a nadie** — sale en `pg_stat_activity`.
- **Con el culpable localizado**, las salidas son `pg_cancel_backend(pid)` —cancela la consulta— y
  `pg_terminate_backend(pid)` —mata la conexión y deshace su transacción—, en ese orden y como
  decisión, no como rutina.
- **En MySQL el equivalente es `performance_schema.data_lock_waits`**, y `SHOW ENGINE INNODB STATUS`
  guarda las dos sentencias del último interbloqueo. En PostgreSQL se ven las dos cosas en `l02`: la
  espera desde una tercera sesión en
  [§4](../13-laboratorio/l02-aislamiento-y-bloqueos-en-vivo.md#4--paso-3--la-espera-vista-desde-fuera)
  y las sentencias en el registro del servidor en
  [§6](../13-laboratorio/l02-aislamiento-y-bloqueos-en-vivo.md#6--paso-5--el-interbloqueo-y-el-registro-del-servidor).

**Cuánto cuesta:** el diagnóstico, nada; la conclusión apresurada, la noche siguiente. Matar al
bloqueante quita el síntoma y deja la causa: el orden de §8, o una transacción demasiado larga.

---

## 10. 📜 Estándar, motor y convención

> **📜 Estándar o motor.** ISO/IEC 9075 es de pago y **no he verificado sus cláusulas**. Lo único que
> aquí se afirma de la norma es que define `FOR UPDATE` en el contexto de los cursores y que **no
> define ningún mecanismo de bloqueo**; todo lo demás es de motor y está enlazado a su
> documentación.

| Afirmación | Estándar | PostgreSQL 18.6 | MySQL 9.7.2 / InnoDB | SQLite 3.53.4 |
|---|---|---|---|---|
| Existen modos de bloqueo con nombre | **No los define** | Ocho de tabla, cuatro de fila | Propios, más *metadata locks* | No expuestos |
| `SELECT … FOR UPDATE` | Sí, en cursores | Sí, en cualquier `SELECT` | Sí | **No existe** |
| `SKIP LOCKED` y `NOWAIT` | No | Sí | Sí, desde 8.0 | No |
| Se detecta el ciclo automáticamente | No lo exige | Sí, tras `deadlock_timeout` | Sí, al instante | No aplica |
| Hay espera máxima por defecto | No lo define | **No**: `lock_timeout` desactivado | Sí: 50 s | No: `busy_timeout` a 0 |
| `SQLSTATE` del interbloqueo | No lo fija | `40P01` | `40001` | `SQLITE_BUSY` |
| Bloquear el hueco entre dos claves | No | No existe como tal | Sí: *next-key locks* (`02` §5) | No |
| El DDL espera a los lectores | No lo define | Sí: `ACCESS EXCLUSIVE` | Sí: *metadata lock* | La base entera se bloquea |

**Convención, las tres que más se repiten.** *«Los interbloqueos se arreglan subiendo el *timeout*»*
— un ciclo no se deshace esperando; lo único que cambia es cuánto tarda en fallar. *«PostgreSQL no
tiene bloqueos porque tiene MVCC»* — tiene ocho modos de tabla y cuatro de fila; lo que MVCC quita
es el bloqueo entre lector y escritor ([`03`](03-mvcc-frente-a-bloqueo.md) §2). Y la más cara en
producción: *«un `ALTER TABLE` que tarda un milisegundo no puede tumbar nada»* — lo que tumba el
sitio no es el `ALTER`, es la cola de peticiones que se forma detrás mientras espera su turno (§7).

---

## ⚠️ Errores frecuentes

| Se dice | Lo preciso |
|---|---|
| "Un `SELECT` no toma ningún bloqueo" | Toma `ACCESS SHARE` sobre la tabla. No estorba a otro `SELECT` ni a un `UPDATE`, pero sí bloquea un `ALTER TABLE`, y eso es lo que cuelga despliegues |
| "Los interbloqueos son un problema de carga" | Son un problema de orden de acceso. La carga solo hace probable un cruce que siempre fue posible |
| "Subo `lock_timeout` y se arregla" | Un ciclo no se resuelve esperando. `lock_timeout` sirve para lo contrario: fallar antes y no arrastrar a nadie |
| "`FOR UPDATE` bloquea la tabla" | Bloquea las filas que devuelve el `SELECT`, y toma `ROW SHARE` sobre la tabla, que casi no estorba |
| "Con `SKIP LOCKED` el reparto es más rápido" | Es que **no espera**; el resultado deja de ser determinista, y por eso vale en una cola y no en un informe |
| "El motor mata la transacción más nueva" | InnoDB mata la que menos trabajo ha hecho; PostgreSQL, la que detecta el ciclo. No hay regla de antigüedad en ninguno |
| "Si dos procesos actualizan tablas distintas no puede haber interbloqueo" | Puede: basta con que las toquen en orden inverso. El objeto en disputa no tiene que ser el mismo, solo el par |
| "El interbloqueo se ve en el momento" | En PostgreSQL tarda al menos `deadlock_timeout`, un segundo por defecto. Ese segundo es la pista de que fue un ciclo y no una espera |

---

## 📚 Para profundizar

- **Documentación** — PostgreSQL 18, «Explicit Locking»: los ocho modos de tabla, los cuatro de fila
  y la matriz de conflictos entera. <https://www.postgresql.org/docs/18/explicit-locking.html>
- **Documentación** — PostgreSQL 18, «pg_locks»: qué columna dice qué, para leer la vista sin
  adivinar. <https://www.postgresql.org/docs/18/view-pg-locks.html>
- **Documentación** — PostgreSQL 18, «Lock Management»: `deadlock_timeout`, `lock_timeout` y sus
  valores por defecto. <https://www.postgresql.org/docs/18/runtime-config-locks.html>
- **Documentación** — MySQL 9.7, «InnoDB Locking»: los modos de InnoDB, incluidos los de hueco.
  <https://dev.mysql.com/doc/refman/9.7/en/innodb-locking.html>
- **Documentación** — MySQL 9.7, «Deadlocks in InnoDB»: cómo elige víctima y dónde se lee el último.
  <https://dev.mysql.com/doc/refman/9.7/en/innodb-deadlocks.html>
- **Documentación** — MySQL 9.7, «Metadata Locking»: por qué una transacción que solo leyó bloquea
  un `ALTER TABLE`. <https://dev.mysql.com/doc/refman/9.7/en/metadata-locking.html>
- **Estándar** — ISO/IEC 9075-2, la cláusula de `<updatability clause>` donde aparece `FOR UPDATE`.
  De pago; aquí no se cita ninguna cláusula concreta.
- **Libro** — Martin Kleppmann, *Designing Data-Intensive Applications*, O'Reilly, 2017, capítulo 7,
  apartado «Two-Phase Locking (2PL)».

---

## 🧠 Preguntas

1. ¿Qué bloqueo toma un `SELECT` normal, a quién estorba, y lo fija el estándar o el motor? 🟢
2. ¿Qué hace exactamente `SELECT … FOR UPDATE`? 🟢
3. ¿Cuánto vale `deadlock_timeout` por defecto en PostgreSQL, y qué implica ese valor? 🟢
4. ¿Hay espera máxima por defecto en PostgreSQL y en MySQL? Di el parámetro y el valor de cada uno.
   🟢
5. Distingue un bloqueo de tabla de uno de fila, y di quién toma cada uno. 🟡
6. ¿Por qué dos `UPDATE` sobre filas distintas de la misma tabla no se estorban? 🟡
7. Diferencia `NOWAIT` de `SKIP LOCKED`: qué pasa con cada uno cuando la fila está bloqueada. 🟡
8. ¿Está `FOR UPDATE` en el estándar? Responde por separado para la norma y para los tres motores
   del corpus. 🟡
9. ¿Qué `SQLSTATE` da el interbloqueo en PostgreSQL y cuál en MySQL, y qué consecuencia tiene eso
   para tu bucle de reintento? 🟡
10. Explica por qué `FOR SHARE` es una fábrica de interbloqueos cuando las sesiones que lo toman
    acaban escribiendo. 🟠
11. ¿Por qué un interbloqueo en PostgreSQL tarda al menos un segundo en aparecer, y cómo usas ese
    dato para diagnosticar? 🟠
12. Un `ALTER TABLE ADD COLUMN` tarda un milisegundo y tumbó el sitio diez minutos. Explica el
    mecanismo completo y la defensa de dos líneas. 🟠
13. ¿Por qué InnoDB mata a la transacción que menos trabajo ha hecho, y por qué PostgreSQL no usa
    ese criterio? 🟠
14. Tienes una cola de pedidos pendientes y diez trabajadores. Explica qué pasa sin `SKIP LOCKED` y
    qué se pierde al usarlo. 🟠
15. Alguien propone subir `innodb_lock_wait_timeout` a 300 s «para que dejen de aparecer
    interbloqueos». Dile por qué no funciona y qué empeora. 🟠
16. Escribe la secuencia completa de dos sesiones —sentencia a sentencia, y dejando los datos como
    estaban— que produce un interbloqueo, y di qué sesión escribe la compensación y por qué la otra
    no. 🔴
17. Diagnostica: a las 3 de la mañana aparecen interbloqueos tres noches de cada diez, siempre entre
    los mismos dos procesos. Da tres hipótesis en orden de probabilidad, la consulta con la que
    mirarías la primera, y la corrección definitiva. 🔴
18. Diseña el acceso de dos procesos que tienen que actualizar los mismos pedidos y pagos, de forma
    que el interbloqueo sea **imposible** y no solo improbable. Di qué regla impones y dónde se
    escribe. 🔴
19. Tienes que migrar `pedidos` en producción con tráfico. Escribe la secuencia de sentencias que
    usarías, con sus parámetros de sesión, y di qué falla y qué no falla en cada paso si no
    consigues el bloqueo. 🔴

---

**Anterior:** [`03`](03-mvcc-frente-a-bloqueo.md) — por qué el lector no aparece en ninguna de estas
esperas · **Siguiente:** [`05`](05-optimista-pesimista-y-transacciones-largas.md) — cuándo este
bloqueo y cuándo una columna de versión · **Relacionado:** [`02`](02-aislamiento-y-sus-fenomenos.md)
§5 — los *next-key locks* de InnoDB, que son bloqueos de hueco · [`01`](01-acid-con-precision.md) —
el ámbito de la transacción, que es lo que decide cuánto duran estos bloqueos.
