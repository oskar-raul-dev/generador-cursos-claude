# 01 — ACID con precisión

> Qué garantiza exactamente cada una de las cuatro letras y, sobre todo, **qué no garantiza**: la A
> no te protege de otro que escribe a la vez, la C no la pone el motor, la I es la única que se
> configura y la D acaba en el disco de un servidor, no en dos. Con el ámbito de la transacción
> —dónde empieza de verdad—, los puntos de guardado y el anidamiento que no existe. **Asume leído:**
> [`01/01`](../01-fundamentos-y-modelo-relacional/01-que-resuelve-un-dbms.md) — de ahí vienen las
> cuatro garantías presentadas juntas y la sesión de la actualización perdida, que aquí no se
> repite. **Vigencia:** 22 de septiembre de 2026.

---

## Salto rápido

- [1. El problema](#1--el-problema) · [2. Dónde empieza una
  transacción](#2--dónde-empieza-una-transacción)
- [3. A de atomicidad, y lo que no cubre](#3--a-de-atomicidad-y-lo-que-no-cubre) · [4. C de
  consistencia, la letra que no pone el motor](#4--c-de-consistencia-la-letra-que-no-pone-el-motor)
- [5. I de aislamiento, la única que se configura](#5--i-de-aislamiento-la-única-que-se-configura) ·
  [6. D de durabilidad, y dónde acaba](#6--d-de-durabilidad-y-dónde-acaba)
- [7. Ámbito, puntos de guardado y el anidamiento que no
  existe](#7--ámbito-puntos-de-guardado-y-el-anidamiento-que-no-existe)
- [8. Estándar, motor y convención](#8--estándar-motor-y-convención) · [9. Dónde aparece de
  verdad](#9--dónde-aparece-de-verdad)
- [Errores frecuentes](#️-errores-frecuentes) · [Para profundizar](#-para-profundizar) ·
  [Preguntas](#-preguntas)

---

## 1. 🎯 El problema

Un reembolso son dos escrituras: insertar la fila en `pagos` y pasar el pedido a `ANULADO`. En la
tienda del corpus hay 820 000 pedidos con pago y 180 000 sin él —120 000 `PENDIENTE` y 60 000
`ANULADO`—, y ese reparto es exacto porque las dos escrituras van siempre juntas.

El día que no van juntas, el desajuste no avisa: no hay error, no hay alerta, hay **un pago sin
pedido anulado** esperando a que alguien concilie a fin de mes. Y la respuesta de entrevista que no
sirve es *"por eso existen las transacciones, que son ACID"*, porque la siguiente pregunta siempre
es la misma:

```text
A  ¿Y si el proceso muere entre las dos escrituras?          -> esto sí lo cubre
I  ¿Y si otro proceso lee el pago antes de que anules?       -> esto no lo cubre la A
C  ¿Y si el importe reembolsado supera el total del pedido?   -> esto no lo cubre el motor
D  ¿Y si el servidor se apaga justo después del COMMIT?       -> esto depende de un parámetro
```

Cuatro letras, cuatro garantías **distintas**, y tres de las cuatro se malinterpretan en voz alta
todos los días. Este capítulo las separa una por una y dice, de cada una, dónde termina.

> **📝 Contexto.** Las sesiones de este capítulo están **corridas contra el entorno** y su salida es
> literal, incluidas las de MySQL y SQLite de las tablas de §7 y §8. Las **cifras medidas** que
> aparecen —3186.23 de total, los 120 bytes de WAL— no son nuevas: vienen de la sesión corrida de
> [`01/01`](../01-fundamentos-y-modelo-relacional/01-que-resuelve-un-dbms.md) §2 y §4, y se citan
> donde se tomaron. Lo único que **no se observa desde la sesión** es el contenido del WAL de §6, y
> el capítulo lo dice allí en vez de fingirlo.

---

## 2. 🧱 Dónde empieza una transacción

**Qué es:** la unidad de trabajo que el motor confirma o deshace entera. Lo que casi nadie dice en
voz alta es que **siempre estás dentro de una**: si no la abres tú, el motor abre y cierra una por
cada sentencia.

```text
tienda=# \echo :AUTOCOMMIT
on
tienda=# UPDATE pedidos SET estado = 'ANULADO' WHERE codigo = 'PED-99999';
UPDATE 1
```

- **Ese `UPDATE` fue una transacción completa**: se abrió, escribió, confirmó y se cerró sin que
  nadie escribiera `BEGIN`. Por eso ya no hay nada que deshacer cuando la siguiente sentencia falla.
- `PED-99999` ya estaba en `ANULADO`, así que la sesión no cambia el dato: es el pedido que el
  corpus reserva para el caso del anti-join, y sirve aquí porque escribir sobre él es inocuo.
- **La forma explícita** es `BEGIN`, y entonces el `COMMIT` es tuyo. En `psql` el aviso de que estás
  dentro es el prompt: pasa de `tienda=#` a `tienda=*#`, y a `tienda=!#` si la transacción quedó
  abortada por un error —los tres prompts se ven en las sesiones de §4 y §7—.

Cómo se dice lo mismo en cada motor, que es lo primero que se pregunta cuando alguien viene de otro:

| | Abrir explícitamente | Ver el estado | Por defecto |
|---|---|---|---|
| **PostgreSQL 18.6** | `BEGIN` o `START TRANSACTION` | el `*` del prompt de `psql` | autoconfirma por sentencia |
| **MySQL 9.7.2** | `START TRANSACTION` o `BEGIN` | `SELECT @@autocommit` → `1` | autoconfirma por sentencia |
| **SQLite 3.53.4** | `BEGIN` / `BEGIN IMMEDIATE` | `.changes` no lo dice; no hay variable | autoconfirma por sentencia |

**Quién lo manda:** **estándar** para `COMMIT` y `ROLLBACK`, que existen en los tres con ese nombre;
**motor** para `BEGIN`, que es una extensión —la norma escribe `START TRANSACTION`— y para el
autoconfirmado, que ISO/IEC 9075 no fija así. *(No he verificado la cláusula: la norma es de pago.)*

**Cuánto cuesta:** una moneda que no se ve hasta que se mide, **el `fsync` por confirmación**. Cien
mil `INSERT` sueltos son cien mil confirmaciones y cien mil esperas al disco; los mismos cien mil
dentro de un `BEGIN … COMMIT` son **una**. Es el motivo por el que una carga «lenta» en SQLite
mejora dos órdenes de magnitud sin tocar una línea de SQL, solo envolviéndola.

> **⏱️ Coste.** La transacción larga no es gratis por el otro lado: mientras está abierta retiene su
> instantánea, y en PostgreSQL eso **bloquea la limpieza de versiones muertas de toda la base**, no
> solo de las tablas que tocaste. Cien mil filas en una transacción es una buena idea; diez millones
> en una que dura cuarenta minutos, no.

> **Veredicto:** no se decide *si* hay transacción, solo **cuál es su tamaño**. El tamaño lo pagas
> en dos monedas opuestas —confirmaciones al disco si la haces pequeña, retención de versiones si la
> haces grande—, y el punto medio se elige midiendo.

---

## 3. 🧱 A de atomicidad, y lo que no cubre

**Qué es:** o se aplican todas las escrituras de la transacción, o no se aplica ninguna. Es la letra
que la gente sí entiende, y por eso lo interesante es el borde.

La sesión que lo demuestra ya está corrida y pegada entera en
[`01/01`](../01-fundamentos-y-modelo-relacional/01-que-resuelve-un-dbms.md) §4, y aquí no se repite:
un `UPDATE` que baja el total de `PED-00042` de 3186.23 a 3086.23, un segundo `UPDATE` que viola el
`CHECK` de `estado`, y el `COMMIT` que responde `ROLLBACK` dejando el total otra vez en 3186.23. Lo
que sigue son las tres cosas que esa sesión **no** dice.

**Primera: el `ROLLBACK` no borra el trabajo, lo marca.** PostgreSQL no vuelve atrás las filas: cada
`UPDATE` escribió una versión nueva en el `heap` —el mecanismo está en
[`03/01`](../03-el-motor-por-dentro/01-como-se-almacena-una-tabla.md) §3— y al deshacer solo se
apunta que ese identificador de transacción abortó. Las versiones muertas **siguen ocupando
páginas** hasta que pase el `VACUUM`.

- **Cuánto cuesta:** el `ROLLBACK` en sí es casi instantáneo, y lo que pagas es espacio y E/S
  después. Deshacer cien mil `UPDATE` deja cien mil versiones muertas que alguien tendrá que barrer.
- **InnoDB hace lo contrario y el precio se invierte:** guarda la versión antigua en el *undo log* y
  al deshacer la **vuelve a aplicar**, fila por fila. Un `ROLLBACK` de un millón de filas puede
  tardar más que el trabajo que deshace, y no se puede cancelar a mitad.

**Segunda: la A es por transacción, no por operación de negocio.** Si tu reembolso son dos llamadas
HTTP a dos servicios, cada uno con su base, no hay ninguna letra de ACID que las una. Eso es otro
oficio —compensaciones, reintentos idempotentes— y no lo resuelve el motor.

**Tercera, y la que más se confunde: la A no dice nada sobre lo que ve el de al lado.** Dos
transacciones atómicas por separado producen perfectamente un dato incorrecto; la sesión de la
actualización perdida de [`01/01`](../01-fundamentos-y-modelo-relacional/01-que-resuelve-un-dbms.md)
§2 —dos pagos de 10 y 20 sobre `PED-00042`, y el total sube 20— es exactamente eso. Quien lo cubre
es la I, y tiene su capítulo.

**Quién lo manda:** **estándar** para el todo-o-nada; **motor** para lo que pasa después de un error
de sentencia, que es la diferencia práctica más grande entre los tres:

| Tras un error dentro de una transacción | Qué hace |
|---|---|
| **PostgreSQL 18.6** | Aborta la transacción entera: toda sentencia posterior responde `current transaction is aborted` hasta `ROLLBACK` |
| **MySQL 9.7.2** | Deshace **solo la sentencia** que falló; la transacción sigue abierta y usable |
| **SQLite 3.53.4** | Igual que MySQL en el caso normal; deshace la transacción entera solo en los errores que no dejan la base utilizable |

> **⚠️ Advertencia.** Ese "la transacción sigue usable" de MySQL es una trampa en los lotes: un
> `INSERT` de un millón de filas partido en sentencias, con una que falla y un `COMMIT` al final,
> confirma **todo lo demás**. En PostgreSQL no confirma nada. El mismo código migrado de un motor al
> otro cambia de resultado sin cambiar una línea.

> **Veredicto:** la A garantiza que no quede *media* escritura tuya. No garantiza que la escritura
> sea correcta, ni que nadie más la esté pisando mientras tanto.

---

## 4. 🧱 C de consistencia, la letra que no pone el motor

**Qué es:** la transacción lleva la base de un estado válido a otro estado válido. Y la pregunta que
desarma la respuesta recitada es: **¿válido según quién?**

Según lo que esté **declarado en el esquema**, y nada más. El motor comprueba `NOT NULL`, `UNIQUE`,
`CHECK` y `FOREIGN KEY` —el mecanismo de cada una está en
[`01/05`](../01-fundamentos-y-modelo-relacional/05-del-modelo-er-al-esquema.md)— y no sabe nada de
"el importe reembolsado no puede superar el total del pedido" mientras esa regla viva solo en tu
servicio. La C de ACID es, casi entera, **trabajo tuyo que el motor se limita a hacer cumplir**.

Lo que sí es del motor, y es la parte que se pregunta, es **cuándo** comprueba lo declarado. Por
defecto, en cada sentencia; y eso convierte una operación legítima en imposible:

```text
tienda=# BEGIN;
BEGIN
tienda=*# UPDATE pedido_lineas SET linea = 2 WHERE pedido_id = 42 AND linea = 1;
ERROR:  duplicate key value violates unique constraint "pedido_lineas_pkey"
DETALLE:  Key (pedido_id, linea)=(42, 2) already exists.
tienda=!# ROLLBACK;
ROLLBACK
```

- **Intercambiar dos líneas de `PED-00042` es válido al final y prohibido a la mitad.** El estado
  intermedio tiene dos veces `(42, 2)`, y la clave primaria se comprueba al terminar la sentencia.
- La salida del corpus dice `pedido_id = 42` porque `PED-00042` es de verdad el pedido de `id` 42:
  la semilla inserta en orden para que los identificadores canónicos coincidan.

**La forma de negociarlo es la restricción diferible**, que el estándar sí trae: se declara
`DEFERRABLE` y se aplaza hasta el `COMMIT` con `SET CONSTRAINTS`. Entonces el estado intermedio
inválido se tolera **dentro** de la transacción y se comprueba una sola vez al confirmar.

```text
tienda=# BEGIN;
BEGIN
tienda=*# ALTER TABLE pedido_lineas
tienda-*#   ADD CONSTRAINT pl_linea_unica UNIQUE (pedido_id, linea) DEFERRABLE INITIALLY DEFERRED;
ALTER TABLE
tienda=*# SET CONSTRAINTS pl_linea_unica DEFERRED;
SET CONSTRAINTS
tienda=*# ROLLBACK;
ROLLBACK
```

- **La restricción se crea y se deshace dentro de la misma transacción**, porque en PostgreSQL el
  DDL es transaccional. El esquema del corpus queda como estaba: es la regla del bloque 03 aplicada
  aquí, y vale igual para restricciones que para índices.
- **La clave primaria no se puede diferir sin recrearla**, y por eso el ejemplo añade una
  restricción única aparte en vez de tocar `pedido_lineas_pkey`.
- **Cuánto cuesta diferir:** el motor acumula las comprobaciones pendientes hasta el `COMMIT`, así
  que el error llega tarde —cuando ya no sabes qué sentencia lo provocó— y la lista de filas por
  verificar ocupa memoria de la transacción. **Cuándo sí:** intercambios, cargas con referencias
  circulares, importaciones que llegan desordenadas. **Cuándo no:** como remedio para no ordenar las
  escrituras.

**Quién lo manda:** **estándar** para `DEFERRABLE` y `SET CONSTRAINTS`; **motor** para el alcance
real, que es donde los tres se separan. PostgreSQL difiere claves foráneas, únicas y de exclusión;
**MySQL 9.7.2 no tiene restricciones diferibles** —lo más parecido es apagar `foreign_key_checks`,
que no es lo mismo: no comprueba nada al final—; SQLite difiere solo las foráneas, con `PRAGMA
defer_foreign_keys = ON`, y además hay que acordarse de que **las foráneas de SQLite están apagadas
por defecto** en cada conexión.

> **🧠 Modelo mental.** La C no es una garantía que el motor te dé: es la garantía de que **el motor
> no te va a dejar romper lo que tú declaraste**. Todo invariante que no esté en el esquema es una
> promesa de tu código, y sobrevive exactamente lo que sobreviva tu código.

---

## 5. 🧱 I de aislamiento, la única que se configura

**Qué es:** qué ve tu transacción de lo que están haciendo las demás mientras tanto. Es la única de
las cuatro letras que **tiene una palanca**, con cuatro posiciones y un valor por defecto distinto
en cada motor.

```text
tienda=# SHOW transaction_isolation;
 transaction_isolation
-----------------------
 read committed
(1 fila)

mysql> SELECT @@transaction_isolation;
+-------------------------+
| @@transaction_isolation |
+-------------------------+
| REPEATABLE-READ         |
+-------------------------+
1 row in set (0.000 sec)
```

- **Dos motores, dos valores por defecto, el mismo código de aplicación.** El mismo servicio migrado
  de MySQL a PostgreSQL cambia de nivel sin que nadie lo decida, y con él cambia qué anomalías puede
  sufrir.
- **El estándar define los cuatro niveles y no dice cuál es el defecto**, así que esto es motor puro
  y es una de las preguntas de entrevista más rentables.

Aquí se nombra y se cierra: el mecanismo de cada nivel, los cinco fenómenos —lectura sucia, lectura
no repetible, fantasma, actualización perdida y *write skew* (anomalía de escritura sesgada)— y qué
motor evita cuál tienen dueño, y es el capítulo siguiente,
[`02`](02-aislamiento-y-sus-fenomenos.md).

> **Veredicto:** si en una entrevista alguien recita las cuatro letras y no menciona que la I se
> configura, ya sabes por dónde va a seguir la conversación.

---

## 6. 🧱 D de durabilidad, y dónde acaba

**Qué es:** lo confirmado sobrevive a un corte de corriente. El matiz que casi nadie añade es
**dónde** sobrevive: en el disco de **ese** servidor, no en dos, y solo si el `COMMIT` esperó de
verdad a que el registro llegara al disco.

El mecanismo es el WAL —*write-ahead log*, registro de escritura anticipada—: antes de tocar la
tabla, el motor anota en un fichero secuencial qué va a hacer, y el `COMMIT` no vuelve hasta que esa
anotación está a salvo. **Esto no se observa desde la sesión**, y el corpus lo dice en vez de
fingirlo: lo único visible desde `psql` es que el registro avanza, medido en
[`01/01`](../01-fundamentos-y-modelo-relacional/01-que-resuelve-un-dbms.md) §4 —120 bytes al
actualizar una sola fila—. Qué hay dentro de esos bytes hace falta `pg_waldump` para verlo.

La palanca, con su precio, en los tres motores:

| Motor | Parámetro | Por defecto | Qué se pierde al relajarlo |
|---|---|---|---|
| **PostgreSQL 18.6** | `synchronous_commit` | `on` | Con `off`, las transacciones de una ventana de unos cientos de milisegundos. **La base no se corrompe** |
| **MySQL 9.7.2** | `innodb_flush_log_at_trx_commit` | `1` | Con `2`, lo del último segundo si cae el sistema operativo; con `0`, también si cae solo el proceso |
| **SQLite 3.53.4** | `PRAGMA synchronous` | `FULL`, también en modo WAL | Con `NORMAL` en modo WAL, las últimas transacciones ante un corte de corriente |

- **Las tres relajaciones comparten una propiedad y conviene decirla:** pierden transacciones
  **enteras y recientes**, no dejan la base a medias. Eso las hace aceptables para una tabla de
  eventos y no para `pagos`.
- **Cuánto cuesta no relajarlo:** un `fsync` por confirmación. Es la razón de §2 para agrupar, y la
  razón por la que un lote de escrituras rinde diez veces más con mil filas por transacción que con
  una.
- **Lo que la D no te da:** que el dato esté en otra máquina. Eso es replicación, y en PostgreSQL se
  pide aparte con `synchronous_standby_names`. Un `COMMIT` durable en un servidor que se incendia es
  un dato perdido igualmente.

El detalle completo —qué escribe exactamente el WAL, qué se pierde en cada modo, y por qué el disco
puede mentirte sobre su propio `fsync`— está en [`06`](06-wal-durabilidad-y-fsync.md), con el
registro leído por dentro y una confirmación perdida a propósito.

---

## 7. 🧱 Ámbito, puntos de guardado y el anidamiento que no existe

**Qué es:** el alcance de una transacción es **la conexión**, no la petición HTTP, ni el método, ni
el bloque `try`. Todo lo que parece una transacción anidada está construido encima de otra cosa.

**El punto de guardado es esa otra cosa.** `SAVEPOINT` marca un punto al que se puede volver sin
perder la transacción entera, y en PostgreSQL es además **la única forma de sobrevivir a un error de
sentencia** sin tirar todo el trabajo:

```text
tienda=# BEGIN;
BEGIN
tienda=*# SAVEPOINT antes_del_estado;
SAVEPOINT
tienda=*# UPDATE pedidos SET estado = 'REEMBOLSADO' WHERE codigo = 'PED-00042';
ERROR:  new row for relation "pedidos" violates check constraint "pedidos_estado_check"
DETALLE:  Failing row contains (42, PED-00042, 26446, REEMBOLSADO, 3186.23, 2025-02-21
03:08:09.349067+00, null).
tienda=!# ROLLBACK TO SAVEPOINT antes_del_estado;
ROLLBACK
tienda=*# SELECT count(*) AS sigo_viva FROM pedidos WHERE codigo = 'PED-00042';
 sigo_viva
-----------
         1
(1 fila)

tienda=*# ROLLBACK;
ROLLBACK
```

- **Sin el `SAVEPOINT`, ese `SELECT` habría respondido `current transaction is aborted`.** Con él,
  la transacción vuelve al punto marcado y sigue viva: es exactamente lo que hace `psql` cuando
  activas `\set ON_ERROR_ROLLBACK on`, y lo que hace un ORM cuando anida un `@Transactional`.
- **`REEMBOLSADO` no está en el `CHECK` del esquema** —los cinco estados son `PENDIENTE`, `PAGADO`,
  `ENVIADO`, `ENTREGADO` y `ANULADO`—, así que el error es reproducible y no depende de los datos.

**Cuánto cuesta un punto de guardado, que es lo que casi nadie dice.** En PostgreSQL cada
`SAVEPOINT` abre una **subtransacción** con su propio identificador, y cada sesión cachea como mucho
**64**. A partir del sexagésimo quinto, el resto de sesiones que quieran saber si una fila es
visible tienen que ir a buscarlo al disco, y el efecto es de sistema, no de tu consulta: se ve como
contención y latencia en transacciones que no tienen nada que ver con la tuya. **Cuándo sí:** un
puñado de puntos con nombre, en un procedimiento que sabe recuperarse. **Cuándo no:** un `SAVEPOINT`
por iteración de un bucle de diez mil vueltas, que es el patrón que genera un ORM cuando se le pide
"seguir aunque una fila falle".

**Y el anidamiento no existe.** No hay transacción dentro de transacción en ninguno de los tres
motores, y lo que hace cada uno cuando se lo pides es distinto y peligroso:

| Si abres una transacción dentro de otra | Qué pasa |
|---|---|
| **PostgreSQL 18.6** | `WARNING: there is already a transaction in progress`. No pasa nada más: sigues en la primera |
| **MySQL 9.7.2** | **`START TRANSACTION` confirma implícitamente la anterior.** Lo que llevabas hecho queda confirmado sin que nadie lo pidiera |
| **SQLite 3.53.4** | Error `cannot start a transaction within a transaction` |

> **⚠️ Advertencia.** La fila de MySQL es la más cara de las tres y la que menos se conoce: no es
> solo `START TRANSACTION`. Cualquier DDL —un `ALTER TABLE`, un `CREATE INDEX`— **también confirma
> implícitamente** la transacción abierta. Una migración que abre una transacción "por si acaso" y
> dentro hace dos `ALTER` no tiene ningún «por si acaso»: tiene dos confirmaciones y ningún camino
> de vuelta.

> **Veredicto:** el ámbito es la conexión. Todo lo que tu marco de trabajo llame «transacción
> anidada» son puntos de guardado, se paga en subtransacciones, y conviene saberlo antes de que
> aparezca en un perfil de producción.

---

## 8. 📜 Estándar, motor y convención

> **📜 Estándar o motor.** ISO/IEC 9075 es de pago y **no he verificado sus cláusulas**. Donde esta
> tabla dice "estándar" es por doctrina asentada y reproducida por la documentación de los tres
> motores, no porque haya leído la norma. Lo comprobable —y comprobado— es la columna de cada motor.

| Afirmación | Estándar | PostgreSQL 18.6 | MySQL 9.7.2 / InnoDB | SQLite 3.53.4 |
|---|---|---|---|---|
| Una sentencia suelta ya es una transacción | Sí, la abre implícitamente | Sí | Sí, con `autocommit = 1` | Sí |
| `BEGIN` abre la transacción | **No**: la norma dice `START TRANSACTION` | Sí, y también `START TRANSACTION` | Sí, las dos | Sí, y `BEGIN IMMEDIATE` para tomar el bloqueo ya |
| Tras un error, la transacción sigue usable | Lo deja al implementador | **No**: abortada hasta `ROLLBACK` o `ROLLBACK TO` | Sí | Sí, salvo errores graves |
| Un `ALTER TABLE` se deshace con `ROLLBACK` | No lo exige | **Sí** | **No**: el DDL confirma implícitamente | Sí |
| Abrir una transacción dentro de otra | No lo define | `WARNING`, y sigues en la primera | **Confirma la anterior** | Error |
| Hay `SAVEPOINT` y `ROLLBACK TO` | Sí | Sí | Sí | Sí |
| Las restricciones se pueden diferir al `COMMIT` | Sí, con `DEFERRABLE` | Sí: foráneas, únicas y de exclusión | **No** | Solo foráneas, con `PRAGMA defer_foreign_keys` |
| El `COMMIT` espera al disco | No lo define | `synchronous_commit = on` | `innodb_flush_log_at_trx_commit = 1` | `PRAGMA synchronous = FULL` |

**Convención, las dos que más se repiten.** *"ACID significa que los datos están bien."* Lo
desmiente la sesión de actualización perdida de `01/01` §2: las dos transacciones fueron atómicas,
duraderas y consistentes con lo declarado, y el total quedó mal. Y la segunda, más fina: *"la C es
la que hace cumplir las reglas de negocio"* — la C solo hace cumplir **lo que está declarado en el
esquema**; una regla que vive en un `if` de tu servicio no está en ninguna letra de ACID.

---

## 9. 🔭 Dónde aparece de verdad

- **La conexión que vuelve al pool con una transacción abierta.** El código lanzó una excepción, no
  hubo `COMMIT` ni `ROLLBACK`, y la conexión se devolvió tal cual. La siguiente petición la toma y
  sigue *dentro* de esa transacción: ve datos que no debería y, sobre todo, mantiene abierta la
  instantánea. En PostgreSQL se busca por `pg_stat_activity` con `state = 'idle in transaction'`.
- **El lote nocturno que confirma por fila.** Cien mil `INSERT` con autoconfirmado son cien mil
  `fsync`. Envolverlos en transacciones de mil filas suele ser la mejora más barata que existe, y no
  cambia ni una línea de SQL.
- **La migración de MySQL que se queda a medias.** Tres `ALTER TABLE` en un guion "transaccional":
  el primero confirmó, el segundo falló, y no hay `ROLLBACK` que valga. El mismo guion en PostgreSQL
  deja la base intacta.
- **El `@Transactional` que no cubre lo que crees.** Si el método anotado llama a otro del mismo
  objeto, o lanza una excepción comprobada que el marco no considera de reversión, la transacción no
  hace lo que el nombre promete. El ámbito sigue siendo la conexión, no la anotación.

---

## ⚠️ Errores frecuentes

| Se dice | Lo preciso |
|---|---|
| "Con transacciones, los datos no se corrompen ni se pierden" | La A y la D no dicen nada de lo que ve otro a la vez. La actualización perdida de `01/01` §2 ocurre con las cuatro letras funcionando |
| "La C de ACID garantiza las reglas de negocio" | Garantiza las restricciones **declaradas**. Lo que vive en tu código no lo comprueba nadie más que tu código |
| "Un `ROLLBACK` deja la base como estaba" | Lógicamente sí; físicamente deja versiones muertas en PostgreSQL —hasta el `VACUUM`— y trabajo de deshacer en InnoDB, que puede tardar más que el original |
| "Las transacciones anidadas existen" | No en estos tres motores. Lo que hay son puntos de guardado, y en MySQL pedir una anidada **confirma** la de fuera |
| "Después de un error puedo seguir con la transacción" | En MySQL y SQLite sí; en PostgreSQL toda sentencia posterior falla hasta `ROLLBACK` o `ROLLBACK TO SAVEPOINT` |
| "Confirmado es confirmado" | Confirmado es *escrito en el registro del servidor*. Con `synchronous_commit = off` o `innodb_flush_log_at_trx_commit = 2` hay una ventana de pérdida, y en ningún caso implica que el dato esté en otra máquina |
| "Poner `SAVEPOINT` por si acaso no cuesta nada" | Cada uno es una subtransacción; pasados **64** por sesión, el coste lo pagan en contención las sesiones de al lado |

---

## 📚 Para profundizar

- **Documentación** — PostgreSQL 18, «Transactions»: el tutorial que fija el vocabulario, con los
  puntos de guardado al final. <https://www.postgresql.org/docs/18/tutorial-transactions.html>
- **Documentación** — PostgreSQL 18, «SAVEPOINT»: qué libera `RELEASE` y qué no.
  <https://www.postgresql.org/docs/18/sql-savepoint.html>
- **Documentación** — PostgreSQL 18, «SET CONSTRAINTS»: qué restricciones se pueden diferir y cuáles
  no. <https://www.postgresql.org/docs/18/sql-set-constraints.html>
- **Documentación** — MySQL 9.7, «Statements That Cause an Implicit Commit»: la lista entera de lo
  que confirma sin avisar. <https://dev.mysql.com/doc/refman/9.7/en/implicit-commit.html>
- **Documentación** — SQLite, «Atomic Commit In SQLite»: cómo se consigue la atomicidad con un solo
  fichero. <https://www.sqlite.org/atomiccommit.html>
- **Estándar** — ISO/IEC 9075-2, sentencias `START TRANSACTION`, `COMMIT`, `ROLLBACK` y `SET
  CONSTRAINTS`. De pago; no hay URL pública y aquí no se cita ninguna cláusula concreta.
- **Libro** — Martin Kleppmann, *Designing Data-Intensive Applications*, O'Reilly, 2017, capítulo 7
  («Transactions»), apartado «The Slippery Concept of a Transaction».

---

## 🧠 Preguntas

1. ¿Qué garantiza cada una de las cuatro letras de ACID, en una frase cada una? 🟢
2. ¿Qué pasa si ejecutas un `UPDATE` sin haber escrito `BEGIN`? 🟢
3. ¿Qué es un punto de guardado y qué sentencia vuelve a él? 🟢
4. ¿Cuál es el alcance de una transacción: la petición, el método o la conexión? 🟢
5. Nombra el parámetro que decide si el `COMMIT` espera al disco en PostgreSQL y en MySQL. 🟢
6. Distingue lo que garantiza la A de lo que garantiza la I, con un caso en que la A se cumple y el
   dato acaba mal. 🟡
7. ¿Qué significa exactamente la C de ACID, y qué parte de ella no pone el motor? 🟡
8. ¿`BEGIN` es del estándar? Responde por separado para la norma y para los tres motores. 🟡
9. Tras un error de sentencia dentro de una transacción, ¿puedes seguir? Responde para PostgreSQL,
   MySQL y SQLite. 🟡
10. ¿En qué se diferencia deshacer en PostgreSQL de deshacer en InnoDB, y cuál de los dos puede
    tardar más que el trabajo que deshace? 🟡
11. ¿Qué diferencia hay entre diferir una restricción y apagar la comprobación de claves foráneas? 🟠
12. Un lote inserta cien mil filas con autoconfirmado y va lentísimo. Explica el mecanismo del coste
    y di qué cambiarías, con su contrapartida. 🟠
13. Explica por qué intercambiar dos valores de una columna única falla, y da las dos maneras de
    resolverlo. 🟠
14. Un compañero pone un `SAVEPOINT` en cada vuelta de un bucle de diez mil iteraciones. Dile qué se
    paga y dónde se va a notar. 🟠
15. ¿Por qué una migración con tres `ALTER TABLE` se queda a medias en MySQL y no en PostgreSQL? Di
    qué categoría es esa diferencia. 🟠
16. Escribe la secuencia completa —sentencia a sentencia— de una transacción que intente una
    operación que puede fallar, se recupere del fallo y confirme el resto del trabajo. 🔴
17. Diagnostica esto: la base crece sin parar y el `VACUUM` no libera espacio, aunque se borran
    filas todos los días. Da tres hipótesis en orden de probabilidad y la consulta con la que
    confirmarías la primera. 🔴
18. Defiende, ante alguien que propone `synchronous_commit = off` para toda la base, qué tablas
    aceptarías y cuáles no, y di exactamente qué se pierde en cada caso. 🔴

---

**Anterior:** [README del bloque](README.md) · **Siguiente:**
[`02`](02-aislamiento-y-sus-fenomenos.md) — los cuatro niveles y los cinco fenómenos ·
**Relacionado:** [`01/01`](../01-fundamentos-y-modelo-relacional/01-que-resuelve-un-dbms.md) — de
donde salen la sesión de atomicidad y la de actualización perdida ·
[`01/05`](../01-fundamentos-y-modelo-relacional/05-del-modelo-er-al-esquema.md) — las restricciones
que la C hace cumplir.
