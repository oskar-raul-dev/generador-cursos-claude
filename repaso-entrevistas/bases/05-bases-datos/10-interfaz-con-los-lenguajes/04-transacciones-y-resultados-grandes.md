# 04 — Transacciones y resultados grandes

> Quién abre la transacción cuando tú no la abres —la respuesta cambia con el driver—, cómo se
> escribe una que se deshace entera en los cuatro lenguajes, el error más silencioso del bloque
> —tragarse la excepción y confirmar—, y cómo se recorre un millón de filas sin cargarlas en
> memoria. **Asume leído:** [`04/01`](../04-transacciones-y-concurrencia/01-acid-con-precision.md) —
> atomicidad, el ámbito de la conexión y la transacción abortada de PostgreSQL— y
> [`01`](01-el-driver-la-conexion-y-el-pool.md), de donde vienen los drivers. **Vigencia:** 24 de
> septiembre de 2026.

---

## Salto rápido

- [1. El problema](#1--el-problema) · [2. Quién abre la transacción](#2--quién-abre-la-transacción)
- [3. La transacción explícita, en los cuatro](#3--la-transacción-explícita-en-los-cuatro) · [4.
  Tragarse la excepción](#4--tragarse-la-excepción)
- [5. Recorrer un millón de filas](#5--recorrer-un-millón-de-filas) · [6. Estándar, motor y
  convención](#6--estándar-motor-y-convención)
- [Errores frecuentes](#️-errores-frecuentes) · [Para profundizar](#-para-profundizar) ·
  [Preguntas](#-preguntas)

---

## 1. 🎯 El problema

Tres incidentes, en tres servicios de la tienda:

```text
Un cambio de estado en dos pasos falla en el segundo, y el primero queda aplicado.
Un servicio captura el error del segundo paso, confirma "lo que se pudo", y no se guardó nada.
La exportación nocturna de pedidos muere por falta de memoria al pasar del millón de filas.
```

Los tres vienen de lo mismo: **el driver toma decisiones sobre la transacción y sobre el resultado
que el código no ve**. Si abre una transacción él solo o no, qué hace con un `COMMIT` que el
servidor convirtió en otra cosa, y si trae el resultado entero a memoria antes de darte la primera
fila. Cada driver decide distinto, y las tres decisiones se ven corriéndolas.

> **📝 Contexto.** Todo está **corrido** en los contenedores de lenguaje. Las pruebas de §2 a §4
> escriben sobre `PED-99999` y **lo devuelven a `ANULADO` al terminar**, con la compensación de la
> regla del bloque 04; el segundo paso falla por el `CHECK (total >= 0)`, así que no deja nada
> detrás. Los milisegundos y la memoria de §5 son de esta máquina.

---

## 2. 🧱 Quién abre la transacción

**Qué es:** si no abres una transacción, alguien decide por ti. En tres de los cuatro drivers cada
sentencia se confirma sola —el **autocommit** de `04/01` §2—; en uno, el driver abre una transacción
con la primera sentencia y la deja abierta hasta que alguien diga qué hacer con ella.

La prueba: el paso 1 pasa `PED-99999` a `PENDIENTE`; el paso 2 falla; y otra conexión mira cómo
quedó. Sin escribir ninguna transacción:

```text
-- Java, pgjdbc
autocommit por defecto: true
paso 2: ERROR: new row for relation "pedidos" violates check constraint "pedidos_total_check"
estado de PED-99999: PENDIENTE

-- Python, psycopg (la conexión se cierra sin commit ni rollback)
autocommit por defecto: False
tras el paso 1: INTRANS
paso 2: new row for relation "pedidos" violates check constraint "pedidos_total_check"
estado de PED-99999: ANULADO

-- TypeScript, pg
paso 2: new row for relation "pedidos" violates check constraint "pedidos_total_check"
estado de PED-99999: PENDIENTE

-- Go, pgx
paso 2: ERROR: new row for relation "pedidos" violates check constraint "pedidos_total_check" (SQLSTATE 23514)
estado de PED-99999: PENDIENTE
```

- **En Java, TypeScript y Go el paso 1 quedó confirmado** y el 2 no: la mitad de un cambio que tenía
  que ir entero. Es el primer incidente de §1.
- **En Python no quedó nada**, pero por un motivo que conviene entender: psycopg **abrió una
  transacción** con el paso 1 —`INTRANS`—, y al cerrar la conexión sin confirmar, se deshizo. Es la
  misma transacción implícita que el log del servidor enseñó en
  [`02`](02-parametrizadas-e-inyeccion.md) §3, con su `BEGIN` y su `COMMIT`.
- **La transacción implícita de psycopg es la que produce las conexiones `idle in transaction`**
  cuando el código no la cierra: un `SELECT` suelto basta para abrirla, y retiene el horizonte de
  limpieza hasta que alguien haga `commit` o `rollback`
  ([`04/05`](../04-transacciones-y-concurrencia/05-optimista-pesimista-y-transacciones-largas.md)
  §5).

| Driver | Por defecto | Qué hace una sentencia suelta |
|---|---|---|
| pgjdbc | Autocommit | Se confirma sola |
| psycopg | **Sin autocommit**, como pide la DB-API | Abre una transacción que queda abierta |
| `pg` | Autocommit | Se confirma sola |
| pgx | Autocommit | Se confirma sola |

**Quién lo manda:** **motor** para el autocommit por sentencia, que es lo que hace PostgreSQL si
nadie manda `BEGIN`; **driver** para mandar ese `BEGIN` sin que se lo pidan, que en Python lo exige
la PEP 249.

> **Veredicto:** una operación de más de una sentencia **siempre** va en una transacción explícita,
> en los cuatro lenguajes. Lo que haga el driver por defecto es un accidente que no hay que heredar.

---

## 3. 🧱 La transacción explícita, en los cuatro

**Qué es:** la forma de cada lenguaje de decir «estas sentencias van juntas, y si una falla, no
queda ninguna». La misma prueba de §2:

```java
con.setAutoCommit(false);
try { st.executeUpdate(PASO1); st.executeUpdate(PASO2); con.commit(); }
catch (Exception e) { con.rollback(); }
```

```python
with con.transaction():          # confirma al salir, deshace si sale una excepción
    con.execute(PASO1)
    con.execute(PASO2)
```

```typescript
const cliente = await pool.connect();     // la transacción necesita UNA conexión, no el pool
try {
  await cliente.query("BEGIN");
  await cliente.query(PASO1);
  await cliente.query(PASO2);
  await cliente.query("COMMIT");
} catch {
  await cliente.query("ROLLBACK");
} finally {
  cliente.release();                      // vuelve al pool pase lo que pase
}
```

```go
tx, err := pool.Begin(ctx)
if err != nil {
	return err
}
defer tx.Rollback(ctx) // no hace nada si ya se confirmó
if _, err := tx.Exec(ctx, paso1); err != nil {
	return err
}
if _, err := tx.Exec(ctx, paso2); err != nil {
	return err
}
return tx.Commit(ctx)
```

Las dos últimas líneas son las mismas en los cuatro —Java y Python imprimen antes su autocommit—:

```text
paso 2 falla y se deshace todo
estado de PED-99999: ANULADO
```

- **En TypeScript, `pool.query` no sirve para una transacción**: cada llamada puede ir a una
  conexión distinta del *pool*, y el `BEGIN` quedaría en una y el `UPDATE` en otra. Hay que pedir
  una conexión con `pool.connect()` y devolverla en el `finally`.
- **El `defer tx.Rollback(ctx)` de Go es la costumbre buena**: se ejecuta siempre al salir, y
  después de un `Commit` no hace nada. Así ningún camino de error deja la transacción abierta.
- **Anidar no existe**: lo que un marco de trabajo llama transacción anidada o `REQUIRES_NEW` son
  puntos de guardado o una segunda conexión, como explica
  [`04/01`](../04-transacciones-y-concurrencia/01-acid-con-precision.md) §7. La propagación de las
  anotaciones de Java es del capítulo [`05`](05-java.md).

**Cuánto cuesta:** una transacción explícita retiene su conexión desde el `BEGIN` hasta el `COMMIT`;
si dentro hay red o esperas, es una transacción larga, con sus facturas.

---

## 4. 🩺 Tragarse la excepción

**Qué es:** el error más silencioso del bloque. El código abre una transacción, el paso 2 falla,
**captura la excepción para seguir** y confirma. En PostgreSQL, una transacción con un error queda
**abortada** —lo de `04/01` §3— y su `COMMIT` se convierte en `ROLLBACK`. Lo que cambia es si el
driver te lo dice:

```text
-- Java, pgjdbc
error tragado
siguiente sentencia: ERROR: current transaction is aborted, commands ignored until end of transaction block
commit: sin error
estado de PED-99999: ANULADO

-- Python, psycopg
error tragado
siguiente sentencia: current transaction is aborted, commands ignored until end of transaction block
commit: sin error; estado de la conexión: IDLE
estado de PED-99999: ANULADO

-- TypeScript, pg
error tragado
commit: sin error; etiqueta devuelta por el servidor: ROLLBACK
estado de PED-99999: ANULADO

-- Go, pgx
error tragado
commit: commit unexpectedly resulted in rollback
estado de PED-99999: ANULADO
```

- **El paso 1 no se guardó en ninguno**, y en dos de los cuatro **el `commit()` no dio error**. El
  código cree que confirmó el cambio de estado y el pedido sigue `ANULADO`: es el segundo incidente
  de §1, y solo se descubre mirando los datos.
- **`pg` tampoco lanza error, pero lo dice**: el resultado del `COMMIT` trae la etiqueta `ROLLBACK`,
  que es lo que el servidor contestó. Hay que mirarla.
- **pgx es el único que convierte la situación en error**, con uno propio para este caso.

| Driver | ¿Avisa del `COMMIT` convertido en `ROLLBACK`? |
|---|---|
| pgjdbc | **No** |
| psycopg | **No** |
| `pg` | Solo en la etiqueta del resultado: `r.command === "ROLLBACK"` |
| pgx | **Sí**: `commit unexpectedly resulted in rollback` |

**La corrección no es mirar mejor el `commit`: es no capturar dentro de la transacción.** La
excepción tiene que salir del bloque para que el `rollback` —o el `with`, o el `defer`— haga su
trabajo. Si de verdad hay que seguir tras un error, se hace con un punto de guardado alrededor del
paso que puede fallar, como en `04/01` §7.

> **⚠️ Advertencia.** Un `catch` vacío dentro de una transacción es peor que no capturar nada:
> convierte un error visible en datos que faltan, y en Java y en Python ni siquiera el `commit` lo
> delata.

---

## 5. 🩺 Recorrer un millón de filas

**Qué es:** la exportación nocturna del tercer incidente. Hay dos formas de leer un resultado
grande: **de golpe**, con el driver trayendo todas las filas a memoria antes de darte la primera, o
**por tramos**, con un cursor en el servidor que entrega las filas de mil en mil. El experimento
recorre los 1 000 000 de pedidos sumando `total`, y mide el tiempo y el pico de memoria del proceso
(`VmHWM`, de `/proc/self/status`). La suma de referencia, del servidor:

```text
tienda=> SELECT count(*), sum(total) FROM pedidos;
  count  |      sum
---------+---------------
 1000000 | 5178452860.88
(1 fila)
```

Las formas de leer por tramos, que son las que cambian:

```java
con.setAutoCommit(false);        // el cursor solo existe dentro de una transacción
st.setFetchSize(1000);           // de mil en mil, no todo de golpe
```

```python
cur = con.cursor(name="recorrido")   # un cursor con nombre vive en el servidor
cur.itersize = 1000
```

```typescript
const cursor = cliente.query(new Cursor("SELECT id, total FROM pedidos"));   // pg-cursor 2.22.0
for (let lote = await cursor.read(1000); lote.length > 0; lote = await cursor.read(1000)) { … }
```

```go
rows, _ := con.Query(ctx, "SELECT id, total::text FROM pedidos")
for rows.Next() { … }    // pgx lee del socket según avanza; "de golpe" es pgx.CollectRows
```

Los resultados, todos con la misma suma, `5178452860.88`, y con la memoria del proceso vacío
—conectar y hacer `SELECT 1`— como línea base:

| Lenguaje | Base | De golpe | Por tramos | Tiempo, golpe / tramos |
|---|---|---|---|---|
| Java | 221 092 kB | 368 004 kB | 237 100 kB | 490 / 441 ms |
| Python | 40 748 kB | 96 348 kB | 41 116 kB | 783 / 724 ms |
| TypeScript | 74 288 kB | 348 368 kB | 96 176 kB | 712 / 717 ms |
| Go | 12 268 kB | 117 524 kB | 18 164 kB | 550 / 453 ms |

- **Lo que ocupa el millón es la diferencia con la base**: unos 147 MB en Java, 56 MB en Python, 274
  MB en TypeScript y 105 MB en Go, para dos columnas. Con las diez de una exportación real, la
  cuenta se multiplica, y ahí es donde el proceso muere.
- **Por tramos, la memoria no crece con las filas**: entre 0 y 22 MB sobre la base, lo mismo para un
  millón que para diez. Y **no es más lento**: en tres de los cuatro fue algo más rápido.
- **El tiempo base de Java es alto** porque `java Fichero.java` compila el fuente en memoria al
  arrancar; en un servicio ya arrancado no se paga.

**La trampa de pgjdbc**, corrida: `setFetchSize(1000)` **sin** desactivar el autocommit.

```text
fetchSize con autocommit: 1000000 filas, suma 5178452860.88, 421 ms, VmHWM: 405732 kB
```

- **405 MB, más que cargarlo todo a propósito.** El cursor del servidor muere al final de cada
  transacción, y con autocommit cada sentencia es una; la documentación del driver lo dice así: con
  autocommit, **vuelve en silencio** a traer el resultado entero.
- **psycopg y `pg` necesitan pedirlo** —cursor con nombre, `pg-cursor`—; **pgx ya lee por tramos**
  si recorres `rows`, y solo acumula si llamas a `CollectRows`.

**Cuánto cuesta el cursor:** una transacción abierta mientras dura el recorrido, con su instantánea
reteniendo el horizonte; una exportación de una hora es una transacción de una hora. **Cuándo sí:**
todo resultado cuyo tamaño no conoces o que crece con la tabla. **Cuándo no:** resultados pequeños y
acotados, donde el viaje de ida y vuelta por tramo no compensa.

> **Veredicto:** un resultado que crece con la tabla se lee por tramos, y el tramo se pide
> explícitamente en tres de los cuatro drivers. Lo que no se pide, se carga entero.

---

## 6. 📜 Estándar, motor y convención

> **📜 Estándar o motor.** ISO/IEC 9075 es de pago y **no he verificado sus cláusulas**. Define
> `COMMIT`, `ROLLBACK` y los cursores con `DECLARE CURSOR`; el autocommit, el cursor por tramos y lo
> que hace un driver con un `COMMIT` fallido son de motor y de driver.

| Afirmación | Estándar | PostgreSQL 18.6 | Drivers del corpus |
|---|---|---|---|
| Una sentencia sin `BEGIN` se confirma sola | Lo deja al implementador | Sí | pgjdbc, `pg` y pgx lo dejan así; psycopg abre transacción |
| Tras un error, la transacción queda abortada | No lo define | **Sí**, hasta `ROLLBACK` | — |
| El `COMMIT` de una transacción abortada se confirma | — | **No**: responde `ROLLBACK` | Solo pgx lo convierte en error |
| Existen los cursores | Sí, `DECLARE CURSOR` | Sí, y mueren con la transacción | Cada driver los expone a su manera |
| Un resultado se trae entero por defecto | No lo define | — | Sí en pgjdbc, psycopg y `pg`; no en pgx |

**Convención, las dos que más se repiten.** *«Si el `commit()` no dio error, está guardado»* — en
pgjdbc y psycopg, un `COMMIT` convertido en `ROLLBACK` no da error. Y *«`setFetchSize` limita la
memoria»* — en pgjdbc solo si la conexión no está en autocommit; si lo está, se ignora sin avisar.

---

## ⚠️ Errores frecuentes

| Se dice | Lo preciso |
|---|---|
| "Sin `BEGIN`, las dos sentencias van juntas" | En pgjdbc, `pg` y pgx cada una se confirma sola: el paso 1 queda aunque el 2 falle |
| "psycopg confirma cada sentencia" | Abre una transacción con la primera y la deja abierta hasta `commit` o `rollback` |
| "Capturo el error y confirmo lo que se pudo" | En PostgreSQL la transacción quedó abortada: el `COMMIT` se convierte en `ROLLBACK` y no se guarda nada |
| "El `commit()` me habría avisado" | pgjdbc y psycopg no avisan; `pg` lo dice en la etiqueta; solo pgx da error |
| "`pool.query('BEGIN')` abre una transacción" | Cada `pool.query` puede ir a otra conexión. La transacción necesita `pool.connect()` |
| "`setFetchSize` y listo" | En pgjdbc hace falta además `setAutoCommit(false)`; sin eso, 405 MB para un millón de filas |
| "Leer por tramos es más lento" | Medido, no: igual o algo más rápido, con la memoria plana |

---

## 📚 Para profundizar

- **Documentación** — PostgreSQL 18, «DECLARE»: los cursores del servidor y por qué mueren con la
  transacción. <https://www.postgresql.org/docs/18/sql-declare.html>
- **Documentación** — pgjdbc, «Issuing a Query and Processing the Result»: el cursor por tramos y
  sus condiciones. <https://jdbc.postgresql.org/documentation/query/>
- **Documentación** — psycopg 3, «Transactions management»: la transacción implícita y
  `transaction()`. <https://www.psycopg.org/psycopg3/docs/basic/transactions.html>
- **Documentación** — psycopg 3, «Cursor types»: cursores en el cliente y en el servidor.
  <https://www.psycopg.org/psycopg3/docs/advanced/cursors.html>
- **Documentación** — node-postgres, «Transactions»: por qué la transacción necesita un cliente del
  *pool*. <https://node-postgres.com/features/transactions>
- **Documentación** — node-postgres, «pg.Cursor»: leer por tramos.
  <https://node-postgres.com/apis/cursor>
- **Documentación** — pgx, el paquete principal: `Tx`, `Commit` y `ErrTxCommitRollback`.
  <https://pkg.go.dev/github.com/jackc/pgx/v5>

---

## 🧠 Preguntas

1. ¿Qué driver del corpus abre una transacción sin que se lo pidas, y por qué? 🟢
2. ¿Qué hace PostgreSQL con el `COMMIT` de una transacción en la que falló una sentencia? 🟢
3. ¿Qué dos condiciones necesita pgjdbc para leer un resultado por tramos? 🟢
4. ¿Qué es un cursor con nombre en psycopg? 🟢
5. Distingue lo que pasa con un cambio en dos pasos sin transacción en pgjdbc y en psycopg, cuando
   el segundo falla. 🟡
6. ¿Por qué en TypeScript una transacción no se puede hacer con `pool.query`? 🟡
7. ¿Es el autocommit del estándar SQL, del motor o del driver? Responde por separado. 🟡
8. Diferencia cómo avisan pgjdbc, psycopg, `pg` y pgx de un `COMMIT` convertido en `ROLLBACK`. 🟡
9. ¿Qué hace `defer tx.Rollback(ctx)` en Go después de un `Commit` que salió bien? 🟡
10. Un servicio captura el error del segundo paso de una transacción y confirma. Explica qué queda
    guardado y por qué nadie se entera. ¿Lo fija el estándar o es cosa del motor? 🟠
11. Explica por qué la transacción implícita de psycopg produce conexiones `idle in transaction`, y
    cómo se evita. 🟠
12. Con autocommit y `setFetchSize(1000)`, pgjdbc usó 405 MB para un millón de filas. Explica el
    mecanismo. 🟠
13. ¿Qué cuesta leer un millón de filas con un cursor del servidor, además de la conexión? 🟠
14. Si de verdad hay que seguir una transacción tras un error de una sentencia, ¿cómo se hace sin
    perder el resto? 🟠
15. Diagnostica: la exportación nocturna muere por memoria desde que la tabla pasó del millón de
    filas. Da tres hipótesis por lenguaje del servicio y la corrección de cada una. 🔴
16. Escribe, en el lenguaje que prefieras, una transacción de dos pasos que no pueda dejar ni media
    escritura ni la transacción abierta, pase lo que pase. 🔴
17. Revisa: `try { paso1(); try { paso2(); } catch (e) { log(e); } commit(); } catch (e) {
    rollback(); }`. Di qué queda en la base si falla el paso 2, en pgjdbc, y cómo lo corriges. 🔴
18. Diseña la exportación de todos los pedidos a CSV en el lenguaje que prefieras, con la memoria
    acotada, y di qué retiene en la base mientras dura. 🔴

---

**Anterior:** [`03`](03-mapeo-de-tipos.md) — qué tipo llega de cada columna · **Siguiente:**
[`05`](05-java.md) — el ecosistema de Java, de JDBC a Hibernate · **Relacionado:**
[`04/01`](../04-transacciones-y-concurrencia/01-acid-con-precision.md) — atomicidad y transacción
abortada ·
[`04/05`](../04-transacciones-y-concurrencia/05-optimista-pesimista-y-transacciones-largas.md) — lo
que retiene una transacción larga.
