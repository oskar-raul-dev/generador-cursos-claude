# 01 — Qué resuelve un DBMS

> Qué te da un gestor de bases de datos que un fichero no te da, y qué te cuesta. Cuatro garantías
> —concurrencia, integridad, recuperación y consulta declarativa—, cada una vista en la sesión que
> la demuestra y nombrada con lo que cobra. **Asume leído:** nada. Es el primer capítulo del corpus.
> **Vigencia:** 27 de septiembre de 2026.

---

## Salto rápido

- [1. El problema](#1--el-problema)
- [2. Concurrencia: dos que escriben a la vez](#2--concurrencia-dos-que-escriben-a-la-vez)
- [3. Integridad: la regla vive en el motor, no en tu código](#3--integridad-la-regla-vive-en-el-motor-no-en-tu-código)
- [4. Atomicidad y recuperación: todo o nada, y qué sobrevive al corte](#4--atomicidad-y-recuperación-todo-o-nada-y-qué-sobrevive-al-corte)
- [5. Consulta declarativa: dices qué quieres, no cómo](#5--consulta-declarativa-dices-qué-quieres-no-cómo)
- [6. Estándar, motor y convención](#6--estándar-motor-y-convención)
- [7. Dónde aparece de verdad](#7--dónde-aparece-de-verdad)
- [Errores frecuentes](#️-errores-frecuentes)
- [Para profundizar](#-para-profundizar)
- [Preguntas](#-preguntas)

---

## 1. 🎯 El problema

Tienes los pedidos de la tienda en un fichero. No un CSV de juguete: **un millón de pedidos y tres
millones y medio de líneas de detalle**. Tu aplicación lo lee, lo modifica y lo vuelve a escribir.
Funciona durante un tiempo. Hasta que pasan cuatro cosas el mismo trimestre:

- **Dos cajeros cobran el mismo pedido en el mismo segundo.** Los dos leen el total, los dos suman
  su importe, los dos escriben. Se cobró dos veces y el fichero refleja una.
- **Alguien escribe un pedido con un cliente que no existe.** Nadie se entera hasta que el informe
  mensual sale con un hueco.
- **Se va la luz a mitad de un guardado** y el fichero queda con medio pedido escrito.
- **Marketing pide "los diez clientes que más gastaron en audio el último trimestre".** Escribes
  cuatrocientas líneas de código, tardan ochenta segundos, y al mes siguiente piden otra cosa.

Ninguno de los cuatro es un problema de tu código. Los cuatro son el mismo problema: **nadie está
haciendo de árbitro**. Este capítulo es qué hace exactamente ese árbitro, y qué pagas por tenerlo.
Los dos rechazos de §3 y los dos planes de §5 se volvieron a correr el 27 de septiembre de 2026 con
`psql` en español, en una copia recién cargada del entorno: por eso la fila rechazada lleva esa
fecha, y el segundo plan va entero, con las líneas `Buffers` que el original había perdido.

> **🧠 Modelo mental.** Un fichero guarda *bytes en un orden*. Una tabla guarda *hechos con
> restricciones*, sin orden propio: el orden solo existe si lo pides con `ORDER BY`. Todo lo que
> hace un DBMS sale de esa diferencia.

---

## 2. 🧱 Concurrencia: dos que escriben a la vez

**Qué es.** Un DBMS arbitra el acceso simultáneo de muchos clientes a los mismos datos: define **qué
ve cada uno y qué pasa cuando chocan**.

**Cómo va.** Dos cajeros aplican un pago al mismo pedido. Cada uno lee el total, suma su importe y
escribe. Con dos sesiones abiertas de verdad:

```text
-- sesión A                                    -- sesión B
BEGIN;
SELECT total FROM pedidos
  WHERE codigo='PED-00042';
  total
---------
 3186.23
                                               BEGIN;
                                               SELECT total FROM pedidos
                                                 WHERE codigo='PED-00042';
                                                 total
                                               ---------
                                                3186.23
UPDATE pedidos SET total = 3186.23 + 10
  WHERE codigo='PED-00042';
COMMIT;
                                               UPDATE pedidos SET total = 3186.23 + 20
                                                 WHERE codigo='PED-00042';
                                               -- ⏸ bloqueada: espera a que A confirme
                                               -- ▶ continúa, y pisa el cambio de A
                                               COMMIT;
```

```text
tienda=# SELECT 3186.23 AS partida, total AS final, total - 3186.23 AS aplicado
tienda-#   FROM pedidos WHERE codigo='PED-00042';
 partida |  final  | aplicado
---------+---------+----------
 3186.23 | 3206.23 |    20.00
(1 fila)
```

- **Se aplicaron dos pagos, 10 y 20, y el total subió 20.** El de A desapareció.
- **El motor hizo su trabajo**: B se quedó bloqueada esperando a que A confirmara, y nadie corrompió
  nada. Las dos transacciones fueron atómicas por separado.
- **Y aun así el dato está mal.** Se llama *lost update* —actualización perdida— y es la prueba de
  que "usar una base de datos" no es una garantía: hay que pedirlas por su nombre.

**Quién lo manda.** **Estándar**: ISO/IEC 9075 define cuatro niveles de aislamiento y qué fenómeno
permite cada uno. **Motor**: el nivel por defecto lo elige cada uno —PostgreSQL `READ COMMITTED`,
MySQL/InnoDB `REPEATABLE READ`— y ninguno de los dos evita esto.

**Cuánto cuesta.** Concurrencia: la solución —dejar que el `UPDATE` haga la aritmética, o leer con
`SELECT … FOR UPDATE`— serializa a los dos cajeros sobre esa fila. **Cuándo sí:** siempre que dos
caminos de código puedan tocar la misma fila. **Cuándo no:** un proceso único, o datos que solo se
insertan.

> **Veredicto:** el motor garantiza que nadie corrompa la fila. Que el valor sea correcto cuando dos
> la tocan a la vez **es otra garantía, y la tienes que pedir**.

---

## 3. 🧱 Integridad: la regla vive en el motor, no en tu código

**Qué es.** Una restricción declarada en el esquema es una regla que el motor comprueba **en cada
escritura, venga de donde venga**: de tu servicio, del script de migración, o de alguien con `psql`
abierto un viernes por la tarde.

**Cómo va.** Dos intentos de escribir algo inválido:

```text
tienda=# INSERT INTO pedidos (codigo, cliente_id, estado, creado_en)
tienda-# VALUES ('PED-XXXXX', 99999999, 'PAGADO', now());
ERROR:  insert or update on table "pedidos" violates foreign key constraint "pedidos_cliente_id_fkey"
DETALLE:  Key (cliente_id)=(99999999) is not present in table "clientes".
tienda=# INSERT INTO pedidos (codigo, cliente_id, estado, creado_en)
tienda-# VALUES ('PED-XXXXX', 42, 'DEVUELTO', now());
ERROR:  new row for relation "pedidos" violates check constraint "pedidos_estado_check"
DETALLE:  Failing row contains (1000002, PED-XXXXX, 42, DEVUELTO, 0.00, 2026-09-27 20:17:14.762986+00, null).
```

- **Dos clases de regla, dos rechazos**, y el `DETAIL` trae la fila entera que falló.
- Fíjate en el `1000002` del segundo: **la secuencia avanzó aunque la fila se rechazara**. Los
  identificadores generados tienen huecos, y es normal.

**Quién lo manda.** **Estándar** para las cuatro clases de restricción. **Motor** para si se
comprueban de verdad, y ahí hay una trampa grande:

```text
sqlite> PRAGMA foreign_keys;
0
sqlite> INSERT INTO pedidos (codigo, cliente_id, estado, creado_en)
   ...> VALUES ('PED-XXXXX', 99999999, 'PAGADO', '2026-09-20 00:00:00');
sqlite> SELECT 'insertado: ' || changes();
insertado: 1

sqlite> PRAGMA foreign_keys = ON;
sqlite> INSERT INTO pedidos (codigo, cliente_id, estado, creado_en)
   ...> VALUES ('PED-XXXXX', 99999999, 'PAGADO', '2026-09-20 00:00:00');
Error near line 4: FOREIGN KEY constraint failed
```

**SQLite acepta la fila huérfana**: sus claves foráneas vienen apagadas por compatibilidad hacia
atrás y hay que encenderlas **en cada conexión**. El `CHECK`, en cambio, sí se aplica siempre. Si tu
suite corre contra SQLite y producción contra PostgreSQL, **tu suite no está probando la integridad
referencial** salvo que alguien se acordara del `PRAGMA`.

**Cuánto cuesta.** Tiempo y concurrencia: cada clave foránea obliga a una búsqueda en la tabla padre
por inserción y toma un bloqueo compartido sobre la fila referenciada. **Cuándo sí:** casi siempre.
**Cuándo no:** en cargas masivas puntuales, donde se apagan, se carga y se vuelven a encender
**comprobando**.

> **Veredicto:** una regla que está en el código se cumple donde pasa ese código. Una regla que está
> en el esquema se cumple siempre.

---

## 4. 🧱 Atomicidad y recuperación: todo o nada, y qué sobrevive al corte

**Qué es.** Una transacción agrupa varias escrituras en una unidad indivisible, y lo confirmado
sobrevive a un corte de corriente.

**Cómo va.** Una operación de dos pasos donde el segundo falla:

```text
tienda=# BEGIN;
BEGIN
tienda=# UPDATE pedidos SET total = total - 100 WHERE codigo = 'PED-00042';
UPDATE 1
tienda=# SELECT total AS dentro_de_la_transaccion FROM pedidos WHERE codigo = 'PED-00042';
 dentro_de_la_transaccion
--------------------------
                  3086.23
(1 fila)

tienda=# UPDATE pedidos SET estado = 'REEMBOLSADO' WHERE codigo = 'PED-00042';
ERROR:  new row for relation "pedidos" violates check constraint "pedidos_estado_check"
tienda=# SELECT 'esto ya no se ejecuta' AS nota;
ERROR:  current transaction is aborted, commands ignored until end of transaction block
tienda=# COMMIT;
ROLLBACK
tienda=# SELECT total AS despues_del_commit FROM pedidos WHERE codigo = 'PED-00042';
 despues_del_commit
--------------------
            3186.23
(1 fila)
```

- **El primer `UPDATE` se aplicó** y dentro de la transacción se ve: 3086.23.
- **Al fallar el segundo, PostgreSQL abortó la transacción entera** y rechazó todo lo posterior.
  Esto es propio de PostgreSQL; MySQL y SQLite dejan seguir tras un error de sentencia.
- **El `COMMIT` respondió `ROLLBACK`.** No es errata: pediste confirmar y el motor dice que deshizo.

**La durabilidad no se ve en la sesión**, y la guía de este corpus pide decirlo en vez de fingirlo.
La garantiza el WAL —*write-ahead log*, registro de escritura anticipada—: antes de tocar la tabla,
el motor anota en un registro secuencial qué va a hacer. Lo único observable desde `psql` es que ese
registro avanza —`pg_current_wal_lsn()` pasó de `1/9341F048` a `1/9341F0C0`, 120 bytes, al
actualizar una sola fila—. **Qué hay dentro de esos bytes no se ve desde aquí**: haría falta
`pg_waldump` sobre los ficheros de `pg_wal`.

**Quién lo manda.** **Estándar** para `COMMIT` y `ROLLBACK`. **Motor** para el resto: qué pasa tras
un error, si el DDL se deshace, y cuánto aprieta el `fsync` al confirmar. **Cuánto cuesta:** tiempo
y riesgo de pérdida, con la misma palanca. Con `synchronous_commit = on` —el valor por defecto y el
de este entorno— cada `COMMIT` espera a que el WAL esté en disco. Apagarlo los acelera mucho y abre
una ventana de pérdida de unos cientos de milisegundos.

> **Veredicto:** "confirmado" significa *está en el registro, en disco*. Todo lo que acelere el
> `COMMIT` lo hace acortando esa frase.

---

## 5. 🧱 Consulta declarativa: dices qué quieres, no cómo

**Qué es.** En SQL describes **el resultado**. El motor decide cómo obtenerlo, y puede decidir
distinto mañana con los mismos datos y la misma consulta.

**Cómo va.** Dos preguntas parecidas, dos estrategias que nadie pidió:

```text
tienda=# EXPLAIN (ANALYZE, BUFFERS, COSTS OFF, TIMING OFF, SUMMARY OFF)
tienda-# SELECT count(*) FROM pedidos WHERE estado = 'ANULADO';
                        QUERY PLAN                        
----------------------------------------------------------
 Aggregate (actual rows=1.00 loops=1)
   Buffers: shared hit=10770
   ->  Seq Scan on pedidos (actual rows=60000.00 loops=1)
         Filter: (estado = 'ANULADO'::text)
         Rows Removed by Filter: 940000
         Buffers: shared hit=10770
 Planning:
   Buffers: shared hit=6
(8 filas)

tienda=# EXPLAIN (ANALYZE, BUFFERS, COSTS OFF, TIMING OFF, SUMMARY OFF)
tienda-# SELECT count(*) FROM pedidos p JOIN clientes c ON c.id = p.cliente_id
tienda-#  WHERE c.codigo = 'CLI-00311';
                                           QUERY PLAN                                            
-------------------------------------------------------------------------------------------------
 Aggregate (actual rows=1.00 loops=1)
   Buffers: shared hit=10773
   ->  Hash Join (actual rows=52.00 loops=1)
         Hash Cond: (p.cliente_id = c.id)
         Buffers: shared hit=10773
         ->  Seq Scan on pedidos p (actual rows=1000000.00 loops=1)
               Buffers: shared hit=10770
         ->  Hash (actual rows=1.00 loops=1)
               Buckets: 1024  Batches: 1  Memory Usage: 9kB
               Buffers: shared hit=3
               ->  Index Scan using clientes_codigo_key on clientes c (actual rows=1.00 loops=1)
                     Index Cond: (codigo = 'CLI-00311'::text)
                     Index Searches: 1
                     Buffers: shared hit=3
 Planning:
   Buffers: shared hit=114
(16 filas)
```

- **En la primera eligió leer la tabla entera** y descartar 940 000 filas al vuelo: con 60 000
  resultados de un millón, bajar por un índice sale más caro, y el motor lo sabe.
- **En la segunda montó una tabla hash** con el único cliente que pasa el filtro —al que sí llegó
  por índice, porque `codigo` es `UNIQUE`— y recorrió los pedidos comparando contra ella.
- **Tú no pediste ninguna de las dos cosas.** `Seq Scan`, `Hash Join` e `Index Scan` son decisiones
  del planificador.

**Quién lo manda.** **Estándar** el lenguaje. **Motor** todo lo demás: los nodos, sus nombres, la
sintaxis de `EXPLAIN` y los criterios; los planes de PostgreSQL y de MySQL no son comparables nodo a
nodo. **Cuánto cuesta:** pierdes el control. Cuando el motor elige mal —y elige mal, sobre todo con
estadísticas viejas— tu consulta pasa de 50 ms a 8 segundos **sin que hayas cambiado nada**.

> **Veredicto:** declarativo significa que delegas el *cómo*. La contrapartida es que cuando el
> *cómo* se tuerce, hay que saber leerlo.

---

## 6. 📜 Estándar, motor y convención

| Afirmación | Estándar | PostgreSQL | MySQL 9.7 | SQLite |
|---|---|---|---|---|
| Las filas tienen un orden | No: una tabla es un conjunto | Igual | Igual | Igual |
| El motor comprueba las claves foráneas | Sí, si están declaradas | Sí, siempre | Sí en InnoDB | **No por defecto**: `PRAGMA foreign_keys = ON` por conexión |
| El `CHECK` se aplica | Sí | Sí | Sí desde 8.0.16; antes se ignoraba en silencio | Sí, siempre |
| Un `ALTER TABLE` se deshace con `ROLLBACK` | No lo exige | **Sí** | **No**: el DDL confirma implícitamente | Sí |
| Tras un error, la transacción sigue usable | Lo deja al implementador | **No**: abortada hasta `ROLLBACK` | Sí | Sí |
| Nivel de aislamiento por defecto | Define los cuatro niveles, no cuál es el defecto | `READ COMMITTED` | `REPEATABLE READ` | `SERIALIZABLE` de facto: un solo escritor |

La fila del DDL transaccional, corrida en los dos motores:

```text
tienda=# BEGIN;
tienda=# ALTER TABLE pedidos ADD COLUMN nota text;
ALTER TABLE
tienda=# ROLLBACK;
ROLLBACK
tienda=# SELECT count(*) AS columnas_tras_rollback FROM information_schema.columns
tienda-#  WHERE table_name='pedidos' AND column_name='nota';
 columnas_tras_rollback
------------------------
                      0
(1 fila)

mysql> START TRANSACTION;
mysql> ALTER TABLE pedidos ADD COLUMN nota TEXT;
mysql> ROLLBACK;
mysql> SELECT count(*) AS columnas_tras_rollback FROM information_schema.columns
    ->  WHERE table_schema='tienda' AND table_name='pedidos' AND column_name='nota';
+------------------------+
| columnas_tras_rollback |
+------------------------+
|                      1 |
+------------------------+
```

**En MySQL la columna sigue ahí**: el `ALTER` confirmó la transacción por su cuenta antes de
ejecutarse, así que el `ROLLBACK` no tenía nada que deshacer. Es la razón por la que una migración
fallida deja a MySQL a medias y a PostgreSQL intacto. *(La columna se eliminó después con un `DROP
COLUMN` explícito: el esquema del corpus no la lleva.)*

**Convención.** *"Usar una base de datos hace que los datos estén bien."* Lo desmiente la sesión de
§2: el motor impidió la corrupción y el total quedó mal. Lo que un DBMS da son **garantías concretas
que hay que pedir por su nombre**.

> **📝 Contexto.** No he verificado la cláusula exacta de ISO/IEC 9075 para ninguna fila de esta
> tabla: la norma es de pago. Lo comprobado es el comportamiento de los motores, corrido en este
> entorno. Donde digo "el estándar" es por doctrina asentada y reproducida por la documentación de
> los tres, no porque haya leído la cláusula.

---

## 7. 🔭 Dónde aparece de verdad

- **El informe que no cuadra por un céntimo al mes:** una regla que vive en el código y un camino de
  escritura que no pasa por ese código.
- **La migración que dejó la tabla a medias:** MySQL, `ALTER` fallido, sin transacción que deshacer.
- **La suite verde que no probaba nada:** SQLite sin `PRAGMA foreign_keys = ON`.
- **El botón de "pagar" pulsado dos veces:** la actualización perdida de §2, tal cual.
- **La consulta que iba bien con mil filas y murió con un millón:** el plan cambió solo.

---

## ⚠️ Errores frecuentes

| Se dice | Lo preciso |
|---|---|
| "Una transacción es todo o nada" | Eso es solo la **A** de ACID. La **I** —el aislamiento— es la que cuesta, la que se configura y la que te preguntan |
| "Si uso una base de datos, los datos están bien" | El motor impide la corrupción, no el error lógico. La actualización perdida de §2 ocurrió con todo correcto |
| "`COMMIT` significa que se guardó" | Significa que está en el registro, en disco, **si `synchronous_commit` está en `on`**. Apagado hay ventana de pérdida |
| "Las claves foráneas se comprueban siempre" | En SQLite vienen **apagadas** y hay que encenderlas en cada conexión |
| "Si funciona en SQLite, funciona en PostgreSQL" | Difieren en claves foráneas, tipado, DDL y concurrencia. Probar contra SQLite lo que corre en PostgreSQL es probar otra cosa |
| "Puedo deshacer un `ALTER TABLE` con `ROLLBACK`" | En PostgreSQL sí. En MySQL el DDL confirma por su cuenta y no hay nada que deshacer |
| "Las filas salen en el orden en que las inserté" | Sin `ORDER BY` no hay orden garantizado, y el orden físico cambia con cada actualización |

---

## 📚 Para profundizar

- **Documentación** — PostgreSQL 18, «Transactions»:
  <https://www.postgresql.org/docs/18/tutorial-transactions.html>
- **Documentación** — PostgreSQL 18, «Write-Ahead Logging (WAL)»:
  <https://www.postgresql.org/docs/18/wal-intro.html>
- **Documentación** — PostgreSQL 18, «Constraints»:
  <https://www.postgresql.org/docs/18/ddl-constraints.html>
- **Documentación** — MySQL 9.7, «Statements That Cause an Implicit Commit»:
  <https://dev.mysql.com/doc/refman/9.7/en/implicit-commit.html>
- **Documentación** — SQLite, «SQLite Foreign Key Support»:
  <https://www.sqlite.org/foreignkeys.html>
- **Documentación** — SQLite, «Atomic Commit In SQLite»: <https://www.sqlite.org/atomiccommit.html>
- **Estándar** — ISO/IEC 9075-2, cláusulas de `<table constraint definition>` y de gestión de
  transacciones. De pago, sin URL pública. **No verificado para este capítulo.**
- **Libro** — Martin Kleppmann, *Designing Data-Intensive Applications*, O'Reilly, 2017, capítulo 7.

---

## 🧠 Preguntas

1. Nombra las cuatro garantías que un DBMS da y un fichero no. 🟢
2. ¿Qué significa exactamente que una transacción esté confirmada? 🟢
3. ¿Qué es el WAL y para qué sirve? 🟢
4. ¿Por qué una tabla no tiene orden de filas? 🟢
5. ¿Qué es una actualización perdida (*lost update*)? 🟢
6. Diferencia entre que el motor impida la corrupción y que garantice que el dato sea correcto. 🟡
7. ¿En qué se diferencia una restricción declarada en el esquema de la misma comprobación escrita en
   el código de la aplicación? 🟡
8. `NULL`, cadena vacía y cero: ¿por qué no son lo mismo? 🟡
9. ¿Qué quiere decir que SQL sea declarativo, y qué pierdes a cambio? 🟡
10. ¿El nivel de aislamiento por defecto lo fija el estándar o cada motor? Di cuál usan PostgreSQL y
    MySQL. 🟠
11. ¿El estándar SQL obliga a que un `ALTER TABLE` se pueda deshacer con `ROLLBACK`? ¿Qué hace cada
    motor? 🟠
12. En la sesión de §2 ninguna de las dos transacciones falló y el dato quedó mal. Explica por qué,
    y qué garantía faltó pedir. 🟠
13. Tu suite de pruebas corre contra SQLite y producción contra PostgreSQL. Da dos diferencias que
    harían pasar una prueba que debería fallar. 🟠
14. ¿Por qué el planificador eligió leer la tabla entera para contar los 60 000 pedidos ANULADOS en
    vez de usar un índice? 🟠
15. En el error del `CHECK` de §3 aparece el identificador `1000002` aunque la fila se rechazó. ¿Qué
    te dice eso sobre las claves generadas? 🟠
16. Escribe la secuencia de sentencias —con `BEGIN` y `COMMIT`— que aplica los dos pagos de §2
    **sin** perder ninguno. Da dos soluciones distintas y di qué cuesta cada una. 🔴
17. Tienes un proceso nocturno que carga dos millones de filas y tarda cuatro horas por las claves
    foráneas. Da la secuencia completa que lo acelera sin dejar datos huérfanos, y di qué riesgo
    asumes. 🔴
18. Un compañero propone quitar todas las restricciones del esquema "porque la aplicación ya
    valida". Da tres argumentos concretos en contra, cada uno con el escenario donde la aplicación
    no alcanza. 🔴

---

**Anterior:** — · **Siguiente:** [`02`](02-el-modelo-relacional-y-sus-claves.md) — qué es
exactamente una clave y cuántas clases hay · **Relacionado:**
[`06`](06-nulos-y-logica-de-tres-valores.md) — por qué `NULL` no es una celda vacía.
