# 01 — Funciones y procedimientos

> Cuándo merece la pena poner lógica dentro de la base de datos y cuándo no, con PL/pgSQL lo justo
> para defenderlo. Medido en PostgreSQL: anular 10 929 pedidos cuesta 6,2 s desde el cliente, una
> sentencia por fila; 888 ms en un bucle PL/pgSQL y 470 ms en una sola sentencia. Una función mal
> declarada convierte una búsqueda por índice de 0,037 ms en un recorrido de 414 ms; un bloque
> `EXCEPTION` multiplica casi por cinco el coste de un bucle; y un procedimiento que confirma por
> lotes falla si alguien lo llama dentro de una transacción. **Asume leído:**
> [`03/05`](../03-el-motor-por-dentro/05-explain-y-explain-analyze.md), los planes, y
> [`04/01`](../04-transacciones-y-concurrencia/01-acid-con-precision.md), las transacciones.
> **Vigencia:** 27 de septiembre de 2026.

---

## Salto rápido

- [1. El problema](#1--el-problema) · [2. Función y procedimiento](#2--función-y-procedimiento)
- [3. La volatilidad decide el plan](#3--la-volatilidad-decide-el-plan) · [4. PL/pgSQL lo
  justo](#4--plpgsql-lo-justo)
- [5. Las idas y vueltas](#5--las-idas-y-vueltas) · [6. Transacciones dentro de un
  procedimiento](#6--transacciones-dentro-de-un-procedimiento)
- [7. Tareas programadas: dentro o fuera](#7-️-tareas-programadas-dentro-o-fuera) · [8. Cómo se
  elige](#8--cómo-se-elige)
- [9. Estándar, motor y convención](#9--estándar-motor-y-convención) · [Errores
  frecuentes](#️-errores-frecuentes) · [Preguntas](#-preguntas)

---

## 1. 🎯 El problema

Cada noche, la tienda anula los pedidos que llevan meses en `PENDIENTE` y deja un evento por cada
uno. El servicio que lo hace lee los pedidos, y por cada uno manda un `UPDATE` y un `INSERT`: dos
viajes a la base por pedido. Con diez mil pedidos son veinte mil viajes, y el trabajo que en la base
dura medio segundo tarda seis en llegar y volver.

La tentación opuesta es conocida: meterlo todo en procedimientos almacenados. Durante años fue la
norma en muchas empresas, y la lógica de negocio acabaron siendo miles de líneas de PL/SQL que nadie
podía probar, versionar ni desplegar sin miedo. Después vinieron los ORM y la lógica volvió a la
aplicación, a veces hasta el extremo de los veinte mil viajes. El péndulo ha ido y ha vuelto.

Este capítulo no toma partido: mide **cuánto cuesta cada viaje, cuánto cuesta el bucle dentro del
motor y cuándo una sola sentencia hace las dos cosas innecesarias**, y enseña las tres trampas de
las funciones que se preguntan.

> **📝 Contexto.** Todo se corrió en una **copia aislada** de PostgreSQL 18.6 —`bd-lab-prueba`,
> puerto 15432, cargada con `esquema.sql` y `semilla.sql` en 106 s y con 22/22 en `verificar.sql`—,
> porque las sesiones anulan pedidos de verdad; el entorno principal no se tocó. Los tiempos son de
> un portátil y varían entre corridas. El contraste de MySQL, en un MySQL 9.7.2 vacío de la misma
> copia. **Longitud:** unas 480 líneas; capítulo normal que pasa el disparador de 400.

---

## 2. 🧱 Función y procedimiento

**Qué es:** una **función** recibe argumentos, devuelve un valor y se llama dentro de una consulta:
`SELECT total_de('PED-00042')`. Un **procedimiento** se llama con `CALL`, no devuelve valor y puede
**confirmar o deshacer transacciones** a mitad de camino. Las dos se escriben en SQL o en un
lenguaje procedural; en PostgreSQL, el de serie es **PL/pgSQL**.

**Quién lo manda:** el estándar tiene una parte para las rutinas guardadas, SQL/PSM, parte 4 de
ISO/IEC 9075, que no he verificado cláusula a cláusula. Lo que se usa en la práctica es **motor**:
PL/pgSQL en PostgreSQL, el `BEGIN … END` de MySQL, PL/SQL en Oracle, T-SQL en SQL Server. SQLite no
tiene rutinas en SQL: las funciones se registran desde la aplicación con `sqlite3_create_function`.

La función más simple, en SQL:

```text
tienda=# CREATE FUNCTION codigo_de(p_id bigint) RETURNS text LANGUAGE sql AS $$ SELECT 'PED-' || lpad(p_id::text, 5, '0') $$;
CREATE FUNCTION
tienda=# EXPLAIN (ANALYZE, COSTS OFF, SUMMARY OFF) SELECT codigo, estado, total FROM pedidos WHERE codigo = codigo_de(42);
                                         QUERY PLAN                                          
---------------------------------------------------------------------------------------------
 Index Scan using pedidos_codigo_key on pedidos (actual time=0.055..0.075 rows=1.00 loops=1)
   Index Cond: (codigo = 'PED-00042'::text)
   Index Searches: 1
   Buffers: shared hit=2 read=2
   I/O Timings: shared read=0.029
 Planning:
   Buffers: shared hit=81 read=7
   I/O Timings: shared read=1.319
(8 filas)

tienda=# ALTER FUNCTION codigo_de(bigint) IMMUTABLE;
ALTER FUNCTION
tienda=# EXPLAIN (ANALYZE, COSTS OFF, SUMMARY OFF) SELECT codigo, estado, total FROM pedidos WHERE codigo = codigo_de(42);
                                         QUERY PLAN                                          
---------------------------------------------------------------------------------------------
 Index Scan using pedidos_codigo_key on pedidos (actual time=0.008..0.008 rows=1.00 loops=1)
   Index Cond: (codigo = 'PED-00042'::text)
   Index Searches: 1
   Buffers: shared hit=4
 Planning:
   Buffers: shared hit=4
(6 filas)

tienda=# SELECT proname, provolatile FROM pg_proc WHERE proname = 'codigo_de';
  proname  | provolatile 
-----------+-------------
 codigo_de | i
(1 fila)
```

- **`Index Cond: (codigo = 'PED-00042'::text)`**: la función ha desaparecido del plan. Una función
  en SQL de una sola expresión se **integra** en la consulta —*inlining*— y el planificador ve
  directamente la expresión, que puede calcular antes de ejecutar.
- **Por eso declararla `IMMUTABLE` no cambió nada**: el plan era ya el bueno. La diferencia de
  tiempo es de caché —la primera leyó de disco, `read=2`—, no de la función. `provolatile` vale `i`,
  inmutable.

> **Veredicto:** una función no es una caja negra por definición; una función en SQL sencilla se
> integra y cuesta cero. Las cajas negras son las de §3.

---

## 3. 🩺 La volatilidad decide el plan

**Qué es:** cada función declara su **volatilidad**. `VOLATILE`, la de defecto, puede devolver algo
distinto en cada llamada y hay que llamarla por fila; `STABLE` devuelve lo mismo dentro de una
consulta; `IMMUTABLE`, siempre lo mismo para los mismos argumentos. La documentación de PostgreSQL
lo dice con una consecuencia directa: **una función `VOLATILE` no se puede usar en la condición de
un recorrido de índice**, porque el índice calcula el valor una sola vez.

La misma función en PL/pgSQL, que no se integra:

```text
tienda=# CREATE FUNCTION codigo_pl(p_id bigint) RETURNS text LANGUAGE plpgsql AS $$ BEGIN RETURN 'PED-' || lpad(p_id::text, 5, '0'); END $$;
CREATE FUNCTION
tienda=# EXPLAIN (ANALYZE, COSTS OFF, SUMMARY ON) SELECT codigo, estado, total FROM pedidos WHERE codigo = codigo_pl(42);
                              QUERY PLAN                              
----------------------------------------------------------------------
 Seq Scan on pedidos (actual time=414.125..414.134 rows=1.00 loops=1)
   Filter: (codigo = codigo_pl('42'::bigint))
   Rows Removed by Filter: 999999
   Buffers: shared hit=10793
 Planning:
   Buffers: shared hit=62
 Planning Time: 0.185 ms
 Execution Time: 414.172 ms
(8 filas)

tienda=# ALTER FUNCTION codigo_pl(bigint) STABLE;
ALTER FUNCTION
tienda=# EXPLAIN (ANALYZE, COSTS OFF, SUMMARY ON) SELECT codigo, estado, total FROM pedidos WHERE codigo = codigo_pl(42);
                                         QUERY PLAN                                          
---------------------------------------------------------------------------------------------
 Index Scan using pedidos_codigo_key on pedidos (actual time=0.024..0.024 rows=1.00 loops=1)
   Index Cond: (codigo = codigo_pl('42'::bigint))
   Index Searches: 1
   Buffers: shared hit=4
 Planning:
   Buffers: shared hit=17
 Planning Time: 0.171 ms
 Execution Time: 0.037 ms
(8 filas)
```

- **`VOLATILE` por defecto: `Seq Scan`, un millón de llamadas y 414 ms.** La función se ejecutó una
  vez por fila —`Rows Removed by Filter: 999999`— aunque siempre devuelve lo mismo, porque el motor
  no puede suponerlo.
- **`STABLE`: `Index Scan`, 0,037 ms**, once mil veces menos. La única diferencia es una palabra en
  la declaración.
- **Y el error contrario también existe**: declarar `IMMUTABLE` una función que lee una tabla o
  depende de la zona horaria permite usarla en un índice de expresión, y el índice guarda resultados
  que dejan de ser ciertos cuando cambian los datos. El motor se fía de lo que se declara.

> **⚠️ Advertencia.** Toda función que se use en un `WHERE` se declara con la volatilidad más
> estricta que sea verdad. Es la trampa de funciones que más se ve en producción, y no da ningún
> error: solo tarda once mil veces más.

---

## 4. 🧱 PL/pgSQL lo justo

**Qué es:** PL/pgSQL añade al SQL variables (`DECLARE`), control (`IF`, `LOOP`, `FOR`), mensajes
(`RAISE`) y captura de errores (`EXCEPTION`). Un `FOR r IN SELECT … LOOP` es un **cursor
implícito**: recorre el resultado fila a fila sin cargarlo entero en memoria.

La tarea de §1 como función, y la misma tarea como una sola sentencia, las dos dentro de una
transacción que se deshace al terminar:

```text
tienda=# CREATE FUNCTION anular_pendientes(p_antes timestamptz) RETURNS integer LANGUAGE plpgsql AS $$ DECLARE r record; n integer := 0; BEGIN FOR r IN SELECT id FROM pedidos WHERE estado = 'PENDIENTE' AND creado_en < p_antes LOOP UPDATE pedidos SET estado = 'ANULADO' WHERE id = r.id; INSERT INTO eventos_pedido (pedido_id, tipo, carga) VALUES (r.id, 'ANULADO', '{"origen": "sistema"}'); n := n + 1; END LOOP; RAISE NOTICE 'anulados: %', n; RETURN n; END $$;
CREATE FUNCTION
tienda=# \timing on
El despliegue de duración está activado.
tienda=# BEGIN;
BEGIN
Duración: 0,220 ms
tienda=*# SELECT anular_pendientes('2023-04-01');
NOTICE:  anulados: 10929
 anular_pendientes 
-------------------
             10929
(1 fila)

Duración: 888,373 ms
tienda=*# ROLLBACK;
ROLLBACK
Duración: 0,529 ms
tienda=# BEGIN;
BEGIN
Duración: 0,369 ms
tienda=*# WITH anulados AS (UPDATE pedidos SET estado = 'ANULADO' WHERE estado = 'PENDIENTE' AND creado_en < '2023-04-01' RETURNING id) INSERT INTO eventos_pedido (pedido_id, tipo, carga) SELECT id, 'ANULADO', '{"origen": "sistema"}' FROM anulados;
INSERT 0 10929
Duración: 469,591 ms
tienda=*# ROLLBACK;
ROLLBACK
Duración: 0,401 ms
tienda=# DO $$ DECLARE x bigint := 0; BEGIN FOR i IN 1..200000 LOOP x := x + i; END LOOP; END $$;
DO
Duración: 13,885 ms
tienda=# DO $$ DECLARE x bigint := 0; BEGIN FOR i IN 1..200000 LOOP BEGIN x := x + i; EXCEPTION WHEN others THEN NULL; END; END LOOP; END $$;
DO
Duración: 66,374 ms
```

- **El bucle: 888 ms** para 10 929 pedidos. Cada vuelta es un `UPDATE` por clave y un `INSERT`, y
  `RAISE NOTICE` devuelve el recuento como mensaje. Todo en el mismo proceso, sin viajes.
- **La sentencia única: 470 ms**, casi la mitad. Un `UPDATE … RETURNING` dentro de una CTE alimenta
  el `INSERT` —el `RETURNING` de [`02/07`](../02-sql/07-escritura-upsert-y-vistas.md), dentro de una
  CTE—: una sola pasada, sin buscar cada pedido otra vez por su `id`.
- **`DO`** ejecuta un bloque anónimo sin crear función. El segundo mete cada suma en un bloque con
  `EXCEPTION`: **de 14 a 66 ms**, casi cinco veces más, sin que salte un solo error. Cada bloque con
  `EXCEPTION` abre una subtransacción para poder deshacer lo que haga, y la documentación lo avisa:
  un bloque así es «significativamente más caro» de abrir y cerrar.

> **Veredicto:** PL/pgSQL ahorra los viajes, pero un bucle fila a fila sigue siendo más lento que la
> sentencia que hace lo mismo por conjuntos. Primero se busca la sentencia; el bucle, cuando la
> lógica no cabe en ella.

---

## 5. 🧱 Las idas y vueltas

Lo que hace el servicio de §1: una sentencia por fila, todas en una transacción, mandadas desde el
cliente. El fichero lo genera PostgreSQL con `format()` —un `UPDATE` y un `INSERT` por cada pedido,
entre `BEGIN` y `ROLLBACK`—, y `psql` lo manda línea a línea, esperando cada respuesta:

```bash
/usr/bin/time -p psql -X -q -h 127.0.0.1 -p 15432 -U postgres -d tienda -f desde_la_aplicacion.sql
```

```text
real 6.29
user 0.16
sys 0.35
```

- **`/usr/bin/time -p`** mide el tiempo total del proceso: `real` es el de reloj. **6,3 s**; una
  segunda corrida dio 6,19.
- **21 858 sentencias** —10 929 de cada— en el mismo trabajo que la función hizo en 888 ms: unos
  0,25 ms de más por sentencia, que es lo que cuesta cada viaje de ida y vuelta por el puerto de
  Docker en esta máquina. En una red de verdad, cada viaje cuesta más, no menos.
- **`user` y `sys` son 0,5 s**: el cliente apenas trabaja. El tiempo se va **esperando**.

| Forma | Viajes | Tiempo |
|---|---|---|
| Una sentencia por fila, desde el cliente | 21 858 | 6,2 s |
| Bucle en PL/pgSQL | 1 | 888 ms |
| Una sentencia por conjuntos | 1 | 470 ms |

> **Veredicto:** el coste de hacerlo desde la aplicación no es la lógica, es la latencia
> multiplicada por el número de sentencias. Se arregla con una sentencia por conjuntos o por lotes,
> y solo después con una función.

---

## 6. 🩺 Transacciones dentro de un procedimiento

**Qué es:** a diferencia de una función, un procedimiento puede hacer `COMMIT` a mitad de camino.
Sirve para trabajos largos: confirmar cada lote libera los bloqueos y deja que `VACUUM` avance, en
vez de una transacción de horas, que es el problema de
[`04/05`](../04-transacciones-y-concurrencia/05-optimista-pesimista-y-transacciones-largas.md).

```text
tienda=# CREATE PROCEDURE anular_por_lotes(p_antes timestamptz, p_lote integer) LANGUAGE plpgsql AS $$ DECLARE n integer; total integer := 0; BEGIN LOOP UPDATE pedidos SET estado = 'ANULADO' WHERE id IN (SELECT id FROM pedidos WHERE estado = 'PENDIENTE' AND creado_en < p_antes LIMIT p_lote); GET DIAGNOSTICS n = ROW_COUNT; EXIT WHEN n = 0; total := total + n; COMMIT; RAISE NOTICE 'lote de %, llevamos %', n, total; END LOOP; END $$;
CREATE PROCEDURE
tienda=# CALL anular_por_lotes('2023-02-01', 1000);
NOTICE:  lote de 1000, llevamos 1000
NOTICE:  lote de 1000, llevamos 2000
NOTICE:  lote de 1000, llevamos 3000
NOTICE:  lote de 804, llevamos 3804
CALL
tienda=# BEGIN;
BEGIN
tienda=*# CALL anular_por_lotes('2023-03-01', 1000);
ERROR:  invalid transaction termination
CONTEXTO:  PL/pgSQL function anular_por_lotes(timestamp with time zone,integer) line 1 at COMMIT
tienda=!# ROLLBACK;
ROLLBACK
tienda=# SELECT count(*) FROM pg_available_extensions WHERE name = 'pg_cron';
 count 
-------
     0
(1 fila)
```

- **Cuatro lotes, cuatro `COMMIT`**: si el proceso muere en el tercero, los dos primeros ya están
  confirmados, y volver a llamarlo sigue donde se quedó, porque solo toca lo que sigue `PENDIENTE`.
  **`GET DIAGNOSTICS n = ROW_COUNT`** recoge cuántas filas cambió el último `UPDATE`.
- **Dentro de un `BEGIN`, falla**: `invalid transaction termination`. La documentación lo acota: el
  control de transacciones solo funciona en un `CALL` o un `DO` llamado desde el nivel superior, sin
  una transacción abierta ni una consulta por medio. Un ORM o un *framework* que envuelve todo en
  una transacción lo rompe.
- **`pg_cron` no está en la imagen**: la última consulta es de §7.

---

## 7. ⚖️ Tareas programadas: dentro o fuera

**Qué es:** «anular cada noche» necesita que algo lance el procedimiento a una hora. Puede lanzarlo
**la propia base** o **algo de fuera**: `cron`, un programador de Kubernetes, el de la nube.

PostgreSQL no trae programador: `pg_cron` es una extensión, y la imagen oficial no la incluye, como
acaba de verse. MySQL sí lo trae, y encendido:

```text
mysql> CREATE TABLE tareas_log (ejecutada_en datetime(3) NOT NULL);
Query OK, 0 rows affected (0.011 sec)

mysql> DELIMITER //
mysql> CREATE PROCEDURE contar_tareas(OUT n INT) BEGIN SELECT count(*) INTO n FROM tareas_log; END //
Query OK, 0 rows affected (0.006 sec)

mysql> DELIMITER ;
mysql> SHOW VARIABLES LIKE 'event_scheduler';
+-----------------+-------+
| Variable_name   | Value |
+-----------------+-------+
| event_scheduler | ON    |
+-----------------+-------+
1 row in set (0.004 sec)

mysql> CREATE EVENT registrar ON SCHEDULE EVERY 5 SECOND DO INSERT INTO tareas_log VALUES (NOW(3));
Query OK, 0 rows affected (0.002 sec)
```

Doce segundos después, en la misma sesión:

```text
mysql> CALL contar_tareas(@n);
Query OK, 1 row affected (0.004 sec)

mysql> SELECT @n AS ejecuciones;
+-------------+
| ejecuciones |
+-------------+
|           3 |
+-------------+
1 row in set (0.000 sec)

mysql> DROP EVENT registrar;
Query OK, 0 rows affected (0.002 sec)
```

- **`DELIMITER //`** cambia el terminador del cliente `mysql`, para que los `;` del cuerpo del
  procedimiento no lo corten. Es del cliente, no del servidor.
- **`OUT n`** es un parámetro de salida, que se recoge en una variable de sesión, `@n`.
- **Tres ejecuciones en doce segundos**: a los 0, 5 y 10. El evento vive **dentro de la base**, se
  respalda con ella y no necesita otra máquina.

**Cuánto cuesta cada opción**: dentro, la tarea no se ve en el sistema de despliegue ni en la
monitorización de la aplicación, y un fallo solo queda en el registro del servidor; fuera, hace
falta otro sistema, pero la tarea se versiona, se alerta y se reintenta como el resto del código.

> **Veredicto:** la tarea se programa fuera salvo que sea mantenimiento puro de la base; lo que se
> lanza —el procedimiento por lotes— puede vivir dentro.

---

## 8. 🧭 Cómo se elige

**Cuándo sí** lógica en la base:

- **Operaciones sobre muchas filas** que la aplicación haría fila a fila: aquí fueron 6,2 s frente a
  medio segundo. Mejor aún si caben en una sentencia.
- **Reglas que deben cumplirse venga el cambio de donde venga** —otra aplicación, un script, una
  consola—: eso es trabajo de restricciones y disparadores, que es [`02`](02-disparadores.md).
- **Trabajos largos por lotes** que deben confirmar a trozos.

**Cuándo no**:

- **Lógica de negocio que cambia a menudo**: se prueba, se versiona y se despliega peor dentro de la
  base, y cambiar una función es una migración.
- **Lógica que necesita servicios externos** —pagos, correo, colas—: la base no debe esperar a la
  red dentro de una transacción.
- **Cuando atas la aplicación a un motor**: PL/pgSQL no corre en MySQL, y el `BEGIN … END` de MySQL
  no corre en PostgreSQL.

---

## 9. 📜 Estándar, motor y convención

> **📜 Estándar o motor.** SQL/PSM, parte 4 de ISO/IEC 9075, define rutinas guardadas; no he
> verificado la cláusula, y cada motor usa su propio lenguaje. La volatilidad, el *inlining* y el
> control de transacciones en procedimientos son de PostgreSQL.

| Afirmación | Categoría | PostgreSQL 18 | MySQL 9.7 | SQLite 3.53 |
|---|---|---|---|---|
| Hay procedimientos con `CALL` | Motor | Sí | Sí | No |
| Un procedimiento puede hacer `COMMIT` | Motor | Sí, desde el nivel superior | Sí | — |
| La volatilidad declarada cambia el plan | Motor | Sí: 414 ms frente a 0,037 | — | — |
| Una función en SQL sencilla se integra en la consulta | Motor | Sí | — | — |
| Hay programador de tareas en el motor | Motor | No, salvo `pg_cron` | Sí, encendido | No |
| Funciones escritas desde la aplicación | Motor | — | — | Sí, `sqlite3_create_function` |
| Primero la sentencia por conjuntos, después el bucle | Convención | — | — | — |

**Convención, la que más se repite.** *«La lógica de negocio nunca va en la base»* — la regla
sensata es otra: la lógica que cambia a menudo va fuera, y el trabajo sobre muchas filas va donde
están las filas. Veinte mil viajes para anular diez mil pedidos no es separación de
responsabilidades: es latencia.

---

## ⚠️ Errores frecuentes

| Se dice | Lo preciso |
|---|---|
| "Mover la lógica a una función siempre la acelera" | Ahorra viajes; el bucle PL/pgSQL tardó el doble que la sentencia por conjuntos |
| "La volatilidad es un detalle" | Con `VOLATILE`, 414 ms y un millón de llamadas; con `STABLE`, 0,037 ms |
| "Marcarla `IMMUTABLE` por si acaso" | Si lee tablas, un índice de expresión guardará resultados que dejan de ser ciertos |
| "Capturar excepciones es gratis si no saltan" | Cada bloque con `EXCEPTION` abre una subtransacción: el bucle pasó de 14 a 66 ms |
| "Un procedimiento puede confirmar siempre" | Dentro de un `BEGIN` dio `invalid transaction termination` |
| "PostgreSQL programa tareas como MySQL" | MySQL trae `EVENT` encendido; PostgreSQL necesita `pg_cron`, que la imagen no trae |
| "Desde la aplicación es igual de rápido" | 21 858 viajes tardaron 6,2 s, y el cliente solo trabajó medio segundo |

---

## 📚 Para profundizar

- **Documentación** — PostgreSQL 18, «Function Volatility Categories».
  <https://www.postgresql.org/docs/18/xfunc-volatility.html>
- **Documentación** — PostgreSQL 18, «Control Structures»: bucles, cursores y el coste de
  `EXCEPTION`. <https://www.postgresql.org/docs/18/plpgsql-control-structures.html>
- **Documentación** — PostgreSQL 18, «Transaction Management» en PL/pgSQL.
  <https://www.postgresql.org/docs/18/plpgsql-transactions.html>
- **Documentación** — PostgreSQL 18, «CREATE PROCEDURE».
  <https://www.postgresql.org/docs/18/sql-createprocedure.html>
- **Documentación** — MySQL 9.7, «CREATE PROCEDURE and CREATE FUNCTION Statements».
  <https://dev.mysql.com/doc/refman/9.7/en/create-procedure.html>
- **Documentación** — MySQL 9.7, «Event Scheduler Configuration».
  <https://dev.mysql.com/doc/refman/9.7/en/event-scheduler.html>
- **Documentación** — SQLite, «Create Or Redefine SQL Functions».
  <https://www.sqlite.org/c3ref/create_function.html>

---

## 🧠 Preguntas

1. ¿Qué diferencia una función de un procedimiento en PostgreSQL? 🟢
2. ¿Qué son las tres categorías de volatilidad? 🟢
3. ¿Qué es un cursor implícito en PL/pgSQL? 🟢
4. ¿Qué hace `DELIMITER` en el cliente de MySQL? 🟢
5. ¿Por qué declarar `IMMUTABLE` la función en SQL no cambió el plan? ¿Lo fija el estándar o es cosa
   del motor? 🟡
6. ¿Por qué la función PL/pgSQL `VOLATILE` produjo un `Seq Scan`, y qué la arregló? 🟡
7. ¿Qué hace `GET DIAGNOSTICS n = ROW_COUNT`? 🟡
8. ¿Qué tiene SQLite en lugar de funciones y procedimientos en SQL? 🟡
9. Distingue programar una tarea con `EVENT` en MySQL y con `cron` fuera de la base. 🟡
10. ¿Por qué el bucle PL/pgSQL tardó casi el doble que la sentencia con `UPDATE … RETURNING`? 🟠
11. ¿Por qué un bloque con `EXCEPTION` multiplicó el coste del bucle, si no saltó ningún error? 🟠
12. ¿Qué riesgo tiene declarar `IMMUTABLE` una función que lee una tabla? 🟠
13. ¿Dónde se fueron los 6,2 s de la versión desde el cliente, si el cliente solo trabajó medio
    segundo? 🟠
14. ¿Por qué el procedimiento por lotes falló dentro de un `BEGIN`, y qué implica para un ORM? 🟠
15. ¿Por qué confirmar por lotes es mejor que una transacción larga para anular miles de
    pedidos? 🟠
16. Diseña la anulación nocturna de pedidos pendientes: qué va en la base, qué fuera y cómo lo
    lanzas. 🔴
17. Diagnostica: tras refactorizar una consulta para usar una función PL/pgSQL que construye el
    código del pedido, el endpoint pasó de 2 ms a 400 ms. 🔴
18. Defiende o refuta la regla «la lógica de negocio nunca va en la base de datos», con los números
    del capítulo. 🔴

---

**Anterior:** [README del bloque](README.md) · **Siguiente:** [`02`](02-disparadores.md) —
disparadores · **Relacionado:**
[`04/05`](../04-transacciones-y-concurrencia/05-optimista-pesimista-y-transacciones-largas.md) — la
transacción larga, y por qué se parte en lotes.
