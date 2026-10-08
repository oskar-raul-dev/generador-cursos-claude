# 02 — Aislamiento y sus fenómenos

> Los cuatro niveles del estándar, los tres fenómenos que la norma nombra y los dos que no —la
> actualización perdida y el *write skew*—, cada uno con la sesión de dos terminales que lo produce.
> Y el contraste que más se pregunta en entrevista: **`REPEATABLE READ` significa tres cosas
> distintas** según hables del estándar, de PostgreSQL o de InnoDB. **Asume leído:**
> [`01`](01-acid-con-precision.md) — de ahí vienen el ámbito de la transacción, los puntos de
> guardado y por qué la I es la única letra con palanca. **Vigencia:** 20 de septiembre de 2026.

---

## Salto rápido

- [1. El problema](#1--el-problema) · [2. Los cuatro niveles del
  estándar](#2--los-cuatro-niveles-del-estándar)
- [3. Lectura sucia, la que PostgreSQL no te puede
  dar](#3--lectura-sucia-la-que-postgresql-no-te-puede-dar) · [4. Lectura no
  repetible](#4--lectura-no-repetible)
- [5. Fantasmas](#5--fantasmas) · [6. Actualización perdida](#6--actualización-perdida) · [7. Write
  skew](#7--write-skew)
- [8. Lo que hace de verdad cada motor](#8-️-lo-que-hace-de-verdad-cada-motor) · [9. Cómo se elige, y
  el bucle de reintento](#9--cómo-se-elige-y-el-bucle-de-reintento)
- [10. Estándar, motor y convención](#10--estándar-motor-y-convención) · [Errores
  frecuentes](#️-errores-frecuentes) · [Para profundizar](#-para-profundizar) ·
  [Preguntas](#-preguntas)

---

## 1. 🎯 El problema

El informe de cierre cuenta los pedidos pendientes dos veces en la misma transacción —una para el
total y otra para el desglose— y las dos cifras no coinciden: 120 000 arriba y 120 001 abajo. Nadie
tocó el informe, nadie tocó la consulta, y las dos veces se leyó la misma tabla.

La respuesta que no sirve es "hay concurrencia". La que sirve tiene tres partes, y las tres son
distintas:

```text
¿Qué anomalía es?          -> una lectura fantasma: apareció una fila que antes no estaba
¿Por qué es posible aquí?  -> el nivel por defecto de PostgreSQL es READ COMMITTED
¿Quién decide eso?         -> el motor, no el estándar. En MySQL el defecto es otro
```

Este capítulo es el dueño de esa terminología en todo el corpus: los cinco fenómenos, los cuatro
niveles, y qué evita cada motor de verdad. Todo lo demás del bloque —MVCC, bloqueos, control
optimista— se apoya en lo que aquí queda fijado.

> **📝 Contexto.** Las sesiones están **corridas contra el entorno**, las de PostgreSQL y las de
> InnoDB: la lectura sucia de §3 —B deja `total` en 9999.99 sin confirmar y A la lee—, la espera de
> 2.878 s de §6 tras la que InnoDB escribe **sin error**, y el `SERIALIZABLE` de §7. Los recuentos
> —120 000 `PENDIENTE`, 60 000 `ANULADO`— salen del reparto fijo del corpus y se comprobaron al
> correr §5.

---

## 2. 🧱 Los cuatro niveles del estándar

**Qué es:** el estándar no describe mecanismos —ni instantáneas, ni bloqueos—, sino **qué anomalías
tolera cada nivel**. Define tres fenómenos y cuatro niveles como la tabla de qué se permite:

| Nivel | Lectura sucia | Lectura no repetible | Fantasma |
|---|---|---|---|
| `READ UNCOMMITTED` | ✅ permitida | ✅ permitida | ✅ permitida |
| `READ COMMITTED` | ❌ prohibida | ✅ permitida | ✅ permitida |
| `REPEATABLE READ` | ❌ prohibida | ❌ prohibida | ✅ **permitida** |
| `SERIALIZABLE` | ❌ prohibida | ❌ prohibida | ❌ prohibida |

Los tres fenómenos, en una frase cada uno:

- **Lectura sucia** (*dirty read*): lees una fila que otra transacción escribió y **todavía no ha
  confirmado**. Si esa otra deshace, leíste algo que nunca existió.
- **Lectura no repetible** (*non-repeatable read*): lees **la misma fila** dos veces dentro de tu
  transacción y la segunda vez tiene otro valor, porque alguien la cambió y confirmó en medio.
- **Fantasma** (*phantom read*): repites **la misma consulta con rango** y la segunda vez aparecen o
  desaparecen filas, porque alguien insertó o borró dentro de ese rango.

La distinción entre las dos últimas es la pregunta de entrevista: **la no repetible es sobre una
fila que ya habías leído; la fantasma es sobre filas que aún no existían**. Es exactamente por eso
que un mecanismo que bloquea las filas leídas evita la segunda anomalía y no la tercera: no se puede
bloquear una fila que todavía no está.

**Quién lo manda:** **estándar** para los cuatro nombres y para esta tabla; **motor** para todo lo
demás, empezando por dos cosas que la norma deja abiertas y que deciden tu día a día: **cuál es el
nivel por defecto** y **con qué mecanismo se consigue**. Dos motores pueden cumplir la misma fila de
esta tabla con implementaciones opuestas —instantánea contra bloqueo— y darte comportamientos muy
distintos bajo carga.

**Cuánto cuesta subir de nivel:** concurrencia. Más aislamiento significa más transacciones que
esperan o que se abortan para volver a intentarlo, y la moneda cambia según el mecanismo: con
bloqueo pagas **espera**, con instantánea pagas **abortos y reintentos**. No hay nivel gratis, y esa
es la razón por la que ningún motor pone `SERIALIZABLE` por defecto.

> **🧠 Modelo mental.** El estándar describe **lo que no puede pasar**, no cómo evitarlo. Por eso dos
> motores «con `REPEATABLE READ`» pueden comportarse distinto sin que ninguno lo incumpla: cumplir
> la tabla por arriba —prohibir más de lo exigido— es perfectamente legal.

---

## 3. 🧱 Lectura sucia, la que PostgreSQL no te puede dar

**Qué es:** el nivel `READ UNCOMMITTED` deja ver el trabajo no confirmado de otro. Y lo que hay que
saber decir es que **en PostgreSQL ese nivel se puede pedir y no hace nada**:

```text
tienda=# BEGIN;
BEGIN
tienda=*# SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;
SET
tienda=*# SHOW transaction_isolation;
 transaction_isolation
-----------------------
 read uncommitted
(1 fila)

tienda=*# ROLLBACK;
ROLLBACK
```

- **La sentencia se acepta y el nombre se guarda**, porque la norma pide admitir los cuatro niveles.
- **El comportamiento es el de `READ COMMITTED`**: PostgreSQL nunca muestra filas no confirmadas,
  porque su control de versiones no tiene forma de enseñártelas. La documentación del motor lo dice
  literalmente, y es la razón por la que la lectura sucia **no se puede reproducir** en este corpus
  con PostgreSQL. Aquí no se pega una sesión que la demuestre porque no existe tal sesión.
- **En MySQL 9.7.2 sí es real.** Con `SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED`, una sesión
  ve el `UPDATE` que la otra aún no ha confirmado; si la otra deshace, la primera trabajó con un
  dato que nunca fue.

**Quién lo manda:** **estándar** define el nivel; **motor** decide si lo implementa de verdad.
PostgreSQL lo trata como `READ COMMITTED`; MySQL/InnoDB lo implementa tal cual; SQLite solo lo tiene
con caché compartida. **Cuánto cuesta:** nada, y ahí está la trampa: lo que ahorra en InnoDB es no
construir la vista de lectura, y lo que cuesta es **decidir con datos que pueden desaparecer**.

> **Veredicto:** si alguien te dice que bajó a `READ UNCOMMITTED` para acelerar un informe en
> PostgreSQL, no aceleró nada. Si lo hizo en MySQL, aceleró un poco y ahora su informe puede sumar
> importes que se deshicieron.

---

## 4. 🩺 Lectura no repetible

**Qué es:** la misma fila leída dos veces dentro de una transacción devuelve valores distintos.
Ocurre en `READ COMMITTED` porque **cada sentencia toma su propia instantánea**, no la transacción.

```text
-- sesión A (READ COMMITTED, el defecto)   -- sesión B
BEGIN;
SELECT estado FROM pedidos
  WHERE codigo='PED-99999';
 estado
---------
 ANULADO
                                           BEGIN;
                                           UPDATE pedidos SET estado='PENDIENTE'
                                             WHERE codigo='PED-99999';
                                           UPDATE 1
                                           COMMIT;
SELECT estado FROM pedidos
  WHERE codigo='PED-99999';
 estado
-----------
 PENDIENTE
COMMIT;
```

- **A no hizo nada raro**: leyó dos veces la misma fila, dentro de la misma transacción, y obtuvo
  dos respuestas. Todo el código que decide entre las dos lecturas —"si sigue anulado, no cobres"—
  está decidiendo con un dato caducado.
- **La sesión deja el dato como estaba**, y eso es obligatorio en este bloque: `PED-99999` vuelve a
  `ANULADO` con un `UPDATE` de compensación inmediato. Es la regla del bloque 03 —crear dentro de
  `BEGIN … ROLLBACK`— adaptada a un bloque que **sí confirma**: lo que se confirma, se deshace en la
  sentencia siguiente y se dice.

**La misma sesión en `REPEATABLE READ` devuelve `ANULADO` las dos veces**, en los tres motores: A
fija una instantánea al principio y la mantiene hasta el final. Lo que cambia es el precio, y se ve
en la sección 6: si A además escribe esa fila, ya no espera, **se aborta**.

**Quién lo manda:** **estándar**, que prohíbe la lectura no repetible a partir de `REPEATABLE READ`.
**Motor** para el mecanismo: PostgreSQL e InnoDB lo consiguen con una instantánea por transacción,
no bloqueando lo leído.

**Cuánto cuesta evitarlo:** subir a `REPEATABLE READ` cuesta que la instantánea envejezca —más
versiones antiguas que conservar cuanto más dura la transacción— y que aparezcan errores de
serialización que tu código tiene que reintentar. **Cuándo sí:** un informe que lee muchas tablas y
tiene que cuadrar consigo mismo. **Cuándo no:** una transacción que espera a un humano.

---

## 5. 🩺 Fantasmas

**Qué es:** la misma consulta **con rango o condición** devuelve un conjunto de filas distinto la
segunda vez. No es que cambiara una fila que leíste: es que apareció una que no existía en tu
resultado.

```text
-- sesión A (READ COMMITTED)               -- sesión B
BEGIN;
SELECT count(*) FROM pedidos
  WHERE estado='PENDIENTE';
 count
--------
 120000
                                           BEGIN;
                                           UPDATE pedidos SET estado='PENDIENTE'
                                             WHERE codigo='PED-99999';
                                           UPDATE 1
                                           COMMIT;
SELECT count(*) FROM pedidos
  WHERE estado='PENDIENTE';
 count
--------
 120001
COMMIT;
```

- **Las dos cifras son las del corpus**: el reparto fijo de estados da 120 000 pedidos `PENDIENTE`,
  y B mete uno más en ese conjunto moviendo `PED-99999` desde `ANULADO`. Compensación inmediata
  después, como en §4.
- **Se hace con un `UPDATE` y no con un `INSERT` a propósito.** Un pedido nuevo dejaría la tabla en
  1 000 001 filas y adelantaría la secuencia de `id`, que no vuelve atrás ni deshaciendo; mover uno
  ya existente produce el mismo fantasma y se revierte exacto.
- **Bloquear no lo evita.** Cuando A leyó, la fila que iba a aparecer todavía no cumplía la
  condición. Por eso el fantasma necesita otra cosa: o una instantánea estable, o bloquear **el
  rango** y no las filas.

**Aquí es donde `REPEATABLE READ` significa tres cosas distintas**, y es la pregunta de entrevista
más rentable de todo el bloque:

| | ¿Permite fantasmas en `REPEATABLE READ`? | Por qué |
|---|---|---|
| **El estándar** | **Sí**, los permite explícitamente | Su tabla solo prohíbe las dos primeras anomalías |
| **PostgreSQL 18.6** | **No** | Su `REPEATABLE READ` es *snapshot isolation*: la transacción entera ve una foto fija |
| **MySQL 9.7.2 / InnoDB** | **No** | Dos mecanismos: la lectura consistente ve su instantánea, y la lectura con bloqueo toma *next-key locks*, que bloquean el hueco entre índices |

- **El *gap lock* de InnoDB no está en el estándar** y es el responsable de la mitad de las
  sorpresas de bloqueo en MySQL: un `SELECT … FOR UPDATE` por un rango bloquea también **los
  huecos** donde podría insertarse una fila, así que un `INSERT` de otra sesión en ese hueco espera.
- **Cuánto cuesta cada camino:** la instantánea de PostgreSQL cuesta versiones retenidas; el bloqueo
  de hueco de InnoDB cuesta esperas en sesiones que insertan y que no tocan ninguna fila tuya.

> **⚠️ Advertencia.** Recitar *"`REPEATABLE READ` evita las lecturas fantasma"* sin decir de quién
> hablas es falso para el estándar y cierto por motivos distintos para los dos motores. Es el error
> de vocabulario que más veces se oye, y el más fácil de convertir en una buena respuesta: son tres
> respuestas y hay que dar las tres.

---

## 6. 🩺 Actualización perdida

**Qué es:** dos transacciones leen el mismo valor, cada una calcula el nuevo a partir de lo que
leyó, y la segunda escritura **pisa** la primera. El resultado es que un trabajo se perdió sin que
nadie viera un error.

El estándar **no la nombra**: no está entre sus tres fenómenos. Se llama así desde el artículo de
Berenson y otros de 1995, que es el que amplió el catálogo porque la tabla de la norma no bastaba
para clasificar los motores reales.

La sesión que la produce está corrida y pegada en
[`01/01`](../01-fundamentos-y-modelo-relacional/01-que-resuelve-un-dbms.md) §2: dos pagos de 10 y 20
sobre `PED-00042`, las dos transacciones confirman, y el total sube de 3186.23 a 3206.23 —veinte, no
treinta—. **Las dos fueron atómicas y las dos cumplieron `READ COMMITTED`.** Lo que sigue es qué
pasa con esa misma secuencia al subir de nivel:

```text
-- sesión A (REPEATABLE READ)              -- sesión B (REPEATABLE READ)
BEGIN;
UPDATE pedidos SET estado='PENDIENTE'
  WHERE codigo='PED-99999';
UPDATE 1
                                           BEGIN;
                                           UPDATE pedidos SET estado='PAGADO'
                                             WHERE codigo='PED-99999';
                                           -- ⏸ bloqueada: espera a que A termine
COMMIT;
                                           -- ▶ continúa, y no pisa nada:
                                           ERROR:  could not serialize access
                                             due to concurrent update
                                           ROLLBACK;
```

- **En `READ COMMITTED` B habría esperado y después habría pisado el cambio de A.** En `REPEATABLE
  READ` de PostgreSQL, B ve que la fila cambió desde su instantánea y **se aborta con `SQLSTATE
  40001`** en vez de escribir encima. Gana quien confirma primero.
- **Ese error no es un fallo: es el contrato.** Cualquier código que corra en `REPEATABLE READ` o en
  `SERIALIZABLE` tiene que reintentar la transacción entera cuando lo recibe (§9).
- **InnoDB no hace esto.** En `REPEATABLE READ`, B espera a que A confirme y entonces **aplica su
  `UPDATE` sobre la versión más reciente**, sin error. Para una escritura ciega —`SET x = x + 1`— el
  resultado es correcto; para un leer-decidir-escribir repartido entre la aplicación y la base, la
  actualización se pierde igual que en `READ COMMITTED`.

**Las tres defensas, y cuál se usa cuándo:**

| Defensa | Cómo | Cuándo |
|---|---|---|
| Dejar la aritmética al motor | `UPDATE … SET total = total + 10` | Siempre que el cálculo quepa en SQL. Es gratis y cierra el hueco entero |
| Bloqueo pesimista al leer | `SELECT … FOR UPDATE` y después escribir | Cuando hay que decidir en la aplicación y la contención es alta |
| Control optimista | columna de versión, `WHERE version = :leida` | Cuando la contención es baja y el conflicto es raro |

Las dos últimas tienen su dueño en este bloque: `FOR UPDATE` en
[`04`](04-bloqueos-e-interbloqueos.md) §3, y la elección entre las dos en
[`05`](05-optimista-pesimista-y-transacciones-largas.md).

---

## 7. 🩺 Write skew

**Qué es:** dos transacciones leen el mismo conjunto de filas, **cada una decide algo válido por
separado**, y las dos escrituras juntas rompen una regla que ninguna de las dos violó sola. Es la
anomalía que sobrevive a `REPEATABLE READ` en PostgreSQL, y la razón entera de que exista el nivel
`SERIALIZABLE`.

La regla de negocio del ejemplo: **un pedido anulado no puede tener más de un pago de
compensación**. Dos operadores la comprueban a la vez sobre `PED-99999`, que no tiene ninguno:

```text
-- sesión A (REPEATABLE READ)              -- sesión B (REPEATABLE READ)
BEGIN;
SELECT count(*) FROM pagos WHERE pedido_id
  = (SELECT id FROM pedidos
      WHERE codigo='PED-99999');
 count
-------
     0
                                           BEGIN;
                                           SELECT count(*) FROM pagos WHERE pedido_id
                                             = (SELECT id FROM pedidos
                                                 WHERE codigo='PED-99999');
                                            count
                                           -------
                                                0
INSERT INTO pagos (pedido_id, metodo,
  importe, pagado_en)
  VALUES ((SELECT id FROM pedidos
            WHERE codigo='PED-99999'),
          'EFECTIVO', 10.00, now());
INSERT 0 1
                                           INSERT INTO pagos (pedido_id, metodo,
                                             importe, pagado_en)
                                             VALUES ((SELECT id FROM pedidos
                                                       WHERE codigo='PED-99999'),
                                                     'EFECTIVO', 20.00, now());
                                           INSERT 0 1
COMMIT;
                                           COMMIT;
-- resultado: dos pagos donde la regla permite uno
```

- **Ninguna de las dos escribió sobre lo que la otra escribió**, así que no hay conflicto de
  actualización y `REPEATABLE READ` no ve nada que abortar. La regla se rompió **entre** las dos.
- **Las dos filas se borran inmediatamente después** —`DELETE FROM pagos WHERE pedido_id = (…)`— y
  el recuento vuelve a 820 000. La secuencia de `id` de `pagos` no vuelve atrás, y eso queda dicho:
  es el precio de demostrar esta anomalía con un `INSERT`, que aquí no se puede evitar.
- **Con `SERIALIZABLE` en PostgreSQL, el segundo `COMMIT` falla**, y esta es su salida literal:
  `could not serialize access due to read/write dependencies among transactions`, `DETALLE: Reason
  code: Canceled on identification as a pivot, during commit attempt.` y `SUGERENCIA: The
  transaction might succeed if retried.` El motor detecta que una transacción leyó algo que la otra
  escribió y que el entrelazado no equivale a ningún orden en serie.

**Quién lo manda:** **motor**, entero. El *write skew* no está en el estándar —lo nombra el mismo
artículo de 1995 que la actualización perdida— y el mecanismo que lo detecta, el *serializable
snapshot isolation* de PostgreSQL, tampoco. En MySQL/InnoDB el `SERIALIZABLE` es otra cosa:
convierte cada `SELECT` en una lectura con bloqueo compartido, así que **lo evita bloqueando**, no
detectando.

**Cuánto cuesta:** en PostgreSQL, memoria de seguimiento de dependencias y **abortos bajo carga**,
que tu código tiene que reintentar; en InnoDB, esperas y muchos más interbloqueos. **Cuándo sí:**
reglas que se comprueban leyendo y se aplican escribiendo, que es el patrón entero de las reservas,
los cupos y los saldos. **Cuándo no:** como nivel global para toda la aplicación.

> **💡 Truco.** Cuando no puedes subir a `SERIALIZABLE`, la salida barata es **materializar el
> conflicto**: haz que las dos transacciones escriban la misma fila —un contador, una fila de
> reserva, un `SELECT … FOR UPDATE` sobre el pedido padre— y el *write skew* se convierte en un
> conflicto de actualización, que sí detecta `REPEATABLE READ`.

---

## 8. ⚖️ Lo que hace de verdad cada motor

**Qué es:** la tabla que hay que tener en la cabeza, porque la misma palabra significa un mecanismo
distinto en cada columna.

| | PostgreSQL 18.6 | MySQL 9.7.2 / InnoDB | SQLite 3.53.4 |
|---|---|---|---|
| Por defecto | `READ COMMITTED` | `REPEATABLE READ` | `SERIALIZABLE` de facto |
| `READ UNCOMMITTED` | Se acepta; se comporta como `READ COMMITTED` | Real: lecturas sucias | Solo con caché compartida |
| `READ COMMITTED` | Instantánea **por sentencia** | Instantánea por sentencia; menos bloqueos de hueco | — |
| `REPEATABLE READ` | *Snapshot isolation*: sin fantasmas, con *write skew* | Instantánea por transacción + *next-key locks* en lecturas con bloqueo | — |
| `SERIALIZABLE` | SSI: detecta dependencias y **aborta** | Bloqueo: convierte cada `SELECT` en lectura compartida | Un solo escritor a la vez |
| Conflicto de escritura | `ERROR: could not serialize access…` (`40001`) | Espera, y al vencer `innodb_lock_wait_timeout` (50 s) da `ERROR 1205` | `SQLITE_BUSY` |
| Cómo se ve el nivel | `SHOW transaction_isolation` | `SELECT @@transaction_isolation` | No hay variable: es el modelo |

- **La fila que más duele es la última de comportamiento:** PostgreSQL te dice "vuelve a
  intentarlo"; InnoDB te deja esperando y al cabo de cincuenta segundos te lo dice. El mismo código
  con el mismo nivel se comporta como un reintento rápido en uno y como una petición colgada en el
  otro.
- **SQLite no es un motor cliente-servidor y por eso su fila es corta**: hay un solo escritor a la
  vez, así que el aislamiento entre conexiones es serializable sin configurarlo. En modo WAL,
  además, los lectores no bloquean al escritor ni al revés.

---

## 9. 🧭 Cómo se elige, y el bucle de reintento

**El criterio, en tres preguntas.** No se elige un nivel "para la aplicación": se elige por
transacción, y casi siempre la respuesta es la de más abajo.

```text
1. ¿La transacción decide algo leyendo y lo aplica escribiendo la MISMA fila?
     -> READ COMMITTED basta, si dejas la aritmética al UPDATE o usas FOR UPDATE.
2. ¿Lee varias tablas y tiene que cuadrar consigo misma?
     -> REPEATABLE READ. Y ya necesitas reintento.
3. ¿La regla se comprueba sobre un conjunto y se aplica escribiendo OTRA fila?
     -> SERIALIZABLE, o materializa el conflicto (§7). No hay tercera opción correcta.
```

**El reintento no es opcional, y es lo que más se olvida.** A partir de `REPEATABLE READ`,
PostgreSQL puede abortar cualquier transacción con `SQLSTATE 40001` —las dos variantes de §6 y §7—,
y el motor no la reintenta por ti. El bucle tiene tres condiciones, y las tres importan:

- **Se reintenta la transacción entera, desde el `BEGIN`**, no la sentencia que falló. El estado que
  leíste ya no vale.
- **Se reintenta solo el `40001`**, no cualquier error. Un `23505` de clave duplicada no se arregla
  repitiendo.
- **El trabajo tiene que ser repetible**: si entre medias ya mandaste un correo o llamaste a una
  pasarela de pago, el reintento lo hace dos veces. Esa es la razón real por la que las llamadas
  externas no van dentro de una transacción.

**Cuánto cuesta el reintento:** tiempo de la transacción repetida, y **riesgo de repetirse para
siempre** si la contención es alta y no hay espera creciente entre intentos. Tres o cuatro intentos
con retardo creciente es lo razonable; un bucle infinito convierte un pico de carga en una caída.

> **🩺 Diagnóstico.** Si ves errores `40001` en producción, no bajes el nivel de aislamiento: mira
> **qué dos transacciones chocan y cuánto duran**. En PostgreSQL, `pg_stat_activity` te da las
> abiertas y su `state`; casi siempre el culpable es una transacción larga que podría ser corta, y
> no el nivel.

---

## 10. 📜 Estándar, motor y convención

> **📜 Estándar o motor.** ISO/IEC 9075 es de pago y **no he verificado sus cláusulas**. La tabla de
> §2 —cuatro niveles y tres fenómenos— es doctrina asentada y la reproducen las documentaciones de
> los tres motores; lo comprobable, y lo que aquí se afirma con seguridad, es la columna de cada
> motor.

| Afirmación | Estándar | PostgreSQL 18.6 | MySQL 9.7.2 / InnoDB | SQLite 3.53.4 |
|---|---|---|---|---|
| Hay cuatro niveles con esos nombres | Sí | Sí | Sí | Se aceptan, pero solo hay un modelo |
| El nivel por defecto lo fija la norma | **No** | `READ COMMITTED` | `REPEATABLE READ` | `SERIALIZABLE` de facto |
| `READ UNCOMMITTED` permite lecturas sucias | Sí | **No**: equivale a `READ COMMITTED` | Sí | No aplica |
| `REPEATABLE READ` permite fantasmas | **Sí** | No: instantánea de transacción | No: instantánea y *next-key locks* | No aplica |
| La actualización perdida está en la norma | **No**: la nombra Berenson (1995) | Se detecta desde `REPEATABLE READ` | No se detecta: se espera y se pisa | Un escritor: no ocurre |
| El *write skew* está en la norma | **No** | Solo lo evita `SERIALIZABLE`, con SSI | Solo lo evita `SERIALIZABLE`, bloqueando | No ocurre |
| Bloquear el hueco entre dos claves | No lo define | No existe como tal | **Sí**: *gap* y *next-key locks* | No |
| Una transacción puede abortarse sola por conflicto | No lo exige | Sí, `40001` | Solo por interbloqueo o espera vencida | `SQLITE_BUSY` |

**Convención, las tres que más se repiten.** *"`REPEATABLE READ` evita los fantasmas"* es falso en
el estándar y cierto en los dos motores por mecanismos distintos: son tres respuestas (§5). *"Subir
el nivel de aislamiento arregla la concurrencia"* — sube el aislamiento y **baja la concurrencia**,
y en PostgreSQL te obliga a escribir reintentos que antes no tenías. Y la tercera, la más cara en
banca: *"con transacciones no hay condiciones de carrera"* — el *write skew* de §7 ocurre con las
cuatro letras de ACID funcionando y con el nivel por defecto de los dos motores principales.

---

## ⚠️ Errores frecuentes

| Se dice | Lo preciso |
|---|---|
| "`REPEATABLE READ` evita las lecturas fantasma" | Según quién: el estándar las permite, PostgreSQL las evita con instantánea e InnoDB con instantánea más *next-key locks* |
| "La lectura no repetible y el fantasma son lo mismo" | La primera es sobre una fila que ya leíste; la segunda, sobre filas que no existían en tu resultado. Bloquear filas evita una y no la otra |
| "`READ UNCOMMITTED` acelera los informes" | En PostgreSQL no hace absolutamente nada: se acepta y se trata como `READ COMMITTED` |
| "El estándar dice que el defecto es `READ COMMITTED`" | El estándar define los cuatro niveles y no fija cuál es el defecto. PostgreSQL elige `READ COMMITTED`, InnoDB `REPEATABLE READ` |
| "La actualización perdida es uno de los tres fenómenos" | No está en la norma: la nombra el artículo de Berenson y otros, de 1995, junto con el *write skew* |
| "Con `SERIALIZABLE` ya no hace falta pensar" | Hace falta un bucle de reintento para el `40001`, y que el trabajo de la transacción sea repetible. Sin eso, `SERIALIZABLE` solo convierte datos malos en errores en producción |
| "Si dos transacciones no tocan la misma fila, no hay conflicto" | El *write skew* es exactamente eso: leen lo mismo, escriben filas distintas, y rompen la regla entre las dos |

---

## 📚 Para profundizar

- **Documentación** — PostgreSQL 18, «Transaction Isolation»: los tres niveles reales, el *write
  skew* y por qué `READ UNCOMMITTED` no existe.
  <https://www.postgresql.org/docs/18/transaction-iso.html>
- **Documentación** — PostgreSQL 18, «Applications Using Serializable Transactions»: qué tiene que
  cumplir tu código para poder usar SSI.
  <https://www.postgresql.org/docs/18/applevel-consistency.html>
- **Documentación** — MySQL 9.7, «Transaction Isolation Levels»: qué hace InnoDB en cada nivel.
  <https://dev.mysql.com/doc/refman/9.7/en/innodb-transaction-isolation-levels.html>
- **Documentación** — MySQL 9.7, «Phantom Rows»: el *next-key lock* explicado por el motor que lo
  inventó. <https://dev.mysql.com/doc/refman/9.7/en/innodb-next-key-locking.html>
- **Documentación** — SQLite, «Isolation In SQLite»: por qué un solo escritor hace la pregunta
  distinta. <https://www.sqlite.org/isolation.html>
- **Estándar** — ISO/IEC 9075-2, cláusula de `SET TRANSACTION` y los cuatro niveles. De pago; aquí
  no se cita ninguna cláusula concreta.
- **Artículo** — Berenson, Bernstein, Gray, Melton, O'Neil y O'Neil, «A Critique of ANSI SQL
  Isolation Levels», 1995: de ahí salen la actualización perdida y el *write skew*.
- **Libro** — Martin Kleppmann, *Designing Data-Intensive Applications*, O'Reilly, 2017, capítulo 7,
  apartados «Weak Isolation Levels» y «Serializability».

---

## 🧠 Preguntas

1. Nombra los cuatro niveles de aislamiento del estándar, de menos a más estricto. 🟢
2. ¿Qué es una lectura sucia? 🟢
3. ¿Cuál es el nivel por defecto de PostgreSQL 18.6 y cuál el de MySQL 9.7.2? 🟢
4. ¿Qué comando te dice en qué nivel estás, en cada uno de los dos motores? 🟢
5. ¿Qué es el *write skew*, en una frase? 🟢
6. ¿Qué `SQLSTATE` devuelve PostgreSQL cuando aborta una transacción por conflicto de serialización?
   🟢
7. Distingue una lectura no repetible de una lectura fantasma, y di por qué bloquear las filas
   leídas evita una y no la otra. 🟡
8. ¿`REPEATABLE READ` evita los fantasmas? Da las tres respuestas: estándar, PostgreSQL e InnoDB. 🟡
9. ¿Está la actualización perdida entre los fenómenos del estándar? Di de dónde viene el nombre. 🟡
10. Diferencia el `SERIALIZABLE` de PostgreSQL del de MySQL: ¿qué hace cada uno cuando dos
    transacciones chocan? 🟡
11. Explica por qué en PostgreSQL pedir `READ UNCOMMITTED` no cambia nada, y qué categoría es esa
    afirmación. 🟡
12. ¿Qué es un *gap lock*, qué motor lo tiene, qué problema resuelve y a quién se lo cobra? 🟠
13. En `REPEATABLE READ`, dos sesiones actualizan la misma fila. Di qué hace PostgreSQL y qué hace
    InnoDB, y cuál de los dos puede perder una actualización. 🟠
14. Tienes un informe que lee cinco tablas y tiene que cuadrar consigo mismo. Elige nivel,
    justifícalo y di qué te obliga a escribir esa elección. 🟠
15. ¿Por qué subir el nivel de aislamiento no es gratis? Nombra las dos monedas y di cuál se paga
    con cada mecanismo. 🟠
16. Un compañero propone `SERIALIZABLE` para toda la aplicación. Dale dos argumentos en contra y una
    alternativa concreta para el caso que de verdad lo necesita. 🟠
17. Explica por qué no debe haber una llamada a una pasarela de pago dentro de una transacción que
    puede reintentarse. 🟠
18. Un servicio migra de MySQL a PostgreSQL sin tocar código y empiezan a aparecer datos
    incoherentes en un informe. Da la hipótesis más probable, la consulta que la confirma y la
    corrección. 🔴
19. Escribe el pseudocódigo del bucle de reintento para `SQLSTATE 40001`, con sus tres condiciones.
    🔴
20. Diseña la sesión completa de dos terminales —sentencia a sentencia, y dejando los datos como
    estaban— que demuestra el *write skew* sobre la regla "un pedido anulado no puede tener más de
    un pago". 🔴
21. La regla es "la suma de los pagos de un pedido no puede superar su total". Da dos formas de
    hacerla cumplir con el nivel por defecto y di qué cuesta cada una. 🔴
22. Diagnostica: en producción aparecen errores `40001` a las horas punta y alguien propone bajar a
    `READ COMMITTED`. Da tres hipótesis en orden de probabilidad, la consulta con la que mirarías la
    primera, y qué harías antes de tocar el nivel. 🔴

---

**Anterior:** [`01`](01-acid-con-precision.md) · **Siguiente:** [`03`](03-mvcc-frente-a-bloqueo.md)
— la instantánea por dentro · **Relacionado:**
[`01/01`](../01-fundamentos-y-modelo-relacional/01-que-resuelve-un-dbms.md) — la actualización
perdida corrida · [`03/01`](../03-el-motor-por-dentro/01-como-se-almacena-una-tabla.md) — dónde
viven las versiones de fila.
