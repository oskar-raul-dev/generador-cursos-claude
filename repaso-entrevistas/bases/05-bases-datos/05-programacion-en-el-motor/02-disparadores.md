# 02 — Disparadores

> Los tres usos legítimos de un disparador —auditoría, desnormalización e integridad que una
> restricción no expresa— y por qué tienen tan mala fama, medido en PostgreSQL: la auditoría fila a
> fila multiplica por 2,4 el coste de actualizar 100 000 pedidos; mantener el total desde las
> líneas, por 8,4; y la regla «un solo pedido pendiente por cliente», comprobada en un disparador,
> deja pasar dos pedidos cuando llegan a la vez. **Asume leído:**
> [`01`](01-funciones-y-procedimientos.md), PL/pgSQL, y
> [`04/02`](../04-transacciones-y-concurrencia/02-aislamiento-y-sus-fenomenos.md), los niveles de
> aislamiento. **Vigencia:** 27 de septiembre de 2026.

---

## Salto rápido

- [1. El problema](#1--el-problema) · [2. Qué es un disparador](#2--qué-es-un-disparador)
- [3. Auditoría: fila o sentencia](#3--auditoría-fila-o-sentencia) · [4. Desnormalización: el total
  que se mantiene solo](#4--desnormalización-el-total-que-se-mantiene-solo)
- [5. Integridad: la regla que dos sesiones rompen](#5--integridad-la-regla-que-dos-sesiones-rompen)
  · [6. Por qué tienen mala fama](#6--por-qué-tienen-mala-fama)
- [7. Estándar, motor y convención](#7--estándar-motor-y-convención) · [Errores
  frecuentes](#️-errores-frecuentes) · [Preguntas](#-preguntas)

---

## 1. 🎯 El problema

Tres peticiones llegan en la misma semana. Auditoría quiere saber quién cambió cada pedido y qué
había antes. Producto quiere que `pedidos.total` sea siempre la suma de sus líneas, cambie quien
cambie una línea. Y fraude quiere que un cliente no pueda abrir un segundo pedido pendiente mientras
tenga otro.

Las tres se pueden hacer en la aplicación, y las tres tienen el mismo punto débil: **solo se cumplen
si todo el que escribe pasa por esa aplicación**. Un script de corrección, una consola, un segundo
servicio, y la regla no existe. Un disparador las pone en la base, donde se cumplen venga el cambio
de donde venga.

El precio es que el disparador **se ejecuta sin que nadie lo vea**: un `UPDATE` inocente tarda el
doble, o el octuple, y quien lo lanza no sabe por qué. Y en el tercer caso, además, no basta.

> **📝 Contexto.** Todo se corrió en la copia aislada de [`01`](01-funciones-y-procedimientos.md),
> `bd-lab-prueba` en el puerto 15432, y cada prueba de coste dentro de una transacción que se
> deshace. Los pedidos `PED-1000001` y `PED-1000002` de §5 son nuevos y solo existen en esa copia.
> La sesión de §5 son dos terminales de `psql` abiertas a la vez; cada bloque las intercala en el
> orden en que se escribió cada orden, con una línea `-- sesión A` o `-- sesión B` al cambiar de
> terminal. **Longitud:** unas 450 líneas; capítulo normal que pasa el disparador de 400, con 174
> líneas de sesión.

---

## 2. 🧱 Qué es un disparador

**Qué es:** un disparador es una función que el motor ejecuta sola cuando pasa algo en una tabla: un
`INSERT`, un `UPDATE` o un `DELETE`. Se define **cuándo** —`BEFORE`, antes del cambio, pudiendo
modificarlo o cancelarlo; `AFTER`, después— y **cuántas veces**: `FOR EACH ROW`, una por fila
tocada, o `FOR EACH STATEMENT`, una por sentencia, vea las filas que vea.

**Quién lo manda:** los disparadores están en el estándar, con las dos granularidades y la cláusula
`REFERENCING` para ver las filas cambiadas como tablas. La documentación de PostgreSQL dice que
implementa un subconjunto del estándar, con extensiones propias. **MySQL y SQLite solo tienen
disparadores por fila**:

```text
mysql> CREATE TRIGGER tareas_sentencia AFTER INSERT ON tareas_log FOR EACH STATEMENT INSERT INTO tareas_log VALUES (NOW(3));
ERROR 1064 (42000): You have an error in your SQL syntax; check the manual that corresponds to your MySQL server version for the right syntax to use near 'STATEMENT INSERT INTO tareas_log VALUES (NOW(3))' at line 1
```

```bash
/opt/homebrew/opt/sqlite/bin/sqlite3 :memory: < sqlite-trigger.sql
```

```text
Parse error near line 2: near "STATEMENT": syntax error
  TE TRIGGER t_sentencia AFTER UPDATE ON t FOR EACH STATEMENT BEGIN SELECT 1; EN
                                      error here ---^
```

- **MySQL no conoce `FOR EACH STATEMENT`**: su sintaxis de `CREATE TRIGGER`, según su manual, solo
  admite `FOR EACH ROW`. `tareas_log` es la tabla de [`01`](01-funciones-y-procedimientos.md) §7.
- **SQLite tampoco**: `sqlite-trigger.sql` crea una tabla y el mismo disparador por sentencia. Su
  documentación lo dice: solo admite disparadores `FOR EACH ROW`, así que escribirlo es opcional.
- **En PostgreSQL**, dentro de la función, `NEW` y `OLD` son la fila después y antes del cambio, y
  `TG_OP` y `TG_TABLE_NAME` dicen qué operación y sobre qué tabla.

> **Veredicto:** un disparador es código que corre dentro de la sentencia de otro. Todo lo bueno y
> todo lo malo que se dice de ellos sale de esa frase.

---

## 3. 🧱 Auditoría: fila o sentencia

La auditoría es el uso menos discutido: guardar quién cambió qué y qué había antes, en una tabla
`auditoria` con la fila de antes y la de después en `jsonb`. Un `UPDATE` de 100 000 pedidos sin
disparador, con un disparador por fila y con uno por sentencia:

```text
tienda=# CREATE TABLE auditoria (id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY, tabla text NOT NULL, operacion text NOT NULL, antes jsonb, despues jsonb, usuario text NOT NULL DEFAULT current_user, en timestamptz NOT NULL DEFAULT now());
CREATE TABLE
tienda=# \timing on
El despliegue de duración está activado.
tienda=# BEGIN;
BEGIN
Duración: 0,285 ms
tienda=*# UPDATE pedidos SET actualizado_en = now() WHERE id <= 100000;
UPDATE 100000
Duración: 881,655 ms
tienda=*# ROLLBACK;
ROLLBACK
Duración: 0,365 ms
tienda=# CREATE FUNCTION auditar_fila() RETURNS trigger LANGUAGE plpgsql AS $$ BEGIN INSERT INTO auditoria (tabla, operacion, antes, despues) VALUES (TG_TABLE_NAME, TG_OP, to_jsonb(OLD), to_jsonb(NEW)); RETURN NEW; END $$;
CREATE FUNCTION
Duración: 8,091 ms
tienda=# CREATE TRIGGER pedidos_auditar AFTER UPDATE ON pedidos FOR EACH ROW EXECUTE FUNCTION auditar_fila();
CREATE TRIGGER
Duración: 2,432 ms
tienda=# BEGIN;
BEGIN
Duración: 0,387 ms
tienda=*# UPDATE pedidos SET actualizado_en = now() WHERE id <= 100000;
UPDATE 100000
Duración: 2118,830 ms (00:02,119)
tienda=*# SELECT count(*) FROM auditoria;
 count  
--------
 100000
(1 fila)

Duración: 9,626 ms
tienda=*# ROLLBACK;
ROLLBACK
Duración: 0,408 ms
tienda=# DROP TRIGGER pedidos_auditar ON pedidos;
DROP TRIGGER
Duración: 3,918 ms
tienda=# CREATE FUNCTION auditar_sentencia() RETURNS trigger LANGUAGE plpgsql AS $$ BEGIN INSERT INTO auditoria (tabla, operacion, antes, despues) SELECT TG_TABLE_NAME, TG_OP, to_jsonb(a), to_jsonb(d) FROM antes a JOIN despues d USING (id); RETURN NULL; END $$;
CREATE FUNCTION
Duración: 0,647 ms
tienda=# CREATE TRIGGER pedidos_auditar AFTER UPDATE ON pedidos REFERENCING OLD TABLE AS antes NEW TABLE AS despues FOR EACH STATEMENT EXECUTE FUNCTION auditar_sentencia();
CREATE TRIGGER
Duración: 0,598 ms
tienda=# BEGIN;
BEGIN
Duración: 0,210 ms
tienda=*# UPDATE pedidos SET actualizado_en = now() WHERE id <= 100000;
UPDATE 100000
Duración: 1861,031 ms (00:01,861)
tienda=*# SELECT count(*) FROM auditoria;
 count  
--------
 100000
(1 fila)

Duración: 16,813 ms
tienda=*# ROLLBACK;
ROLLBACK
Duración: 0,389 ms
```

- **Sin disparador, 882 ms. Por fila, 2 119 ms**: 2,4 veces más, por 100 000 llamadas a la función,
  cada una con su `INSERT` y dos conversiones a `jsonb`. El que lanzó el `UPDATE` no escribió nada
  de eso.
- **Por sentencia, 1 861 ms**. `REFERENCING OLD TABLE AS antes NEW TABLE AS despues` da las filas
  cambiadas como dos tablas —las **tablas de transición**—, y la función hace una sola inserción
  desde una consulta que las une por `id`. Ahorra las 100 000 llamadas; no ahorra escribir 100 000
  filas de auditoría, que es la mayor parte del coste.
- **`RETURN NEW` y `RETURN NULL`**: en un disparador `AFTER`, lo devuelto se ignora; en uno `BEFORE`
  por fila, devolver `NULL` cancela el cambio de esa fila.

> **Veredicto:** la auditoría en disparador es legítima porque nadie puede saltársela, y cuesta lo
> que cuesta escribir otra fila por cada fila. Por sentencia se ahorran las llamadas, no la
> escritura.

---

## 4. 🧱 Desnormalización: el total que se mantiene solo

`pedidos.total` repite una información que ya está en `pedido_lineas`: es una **desnormalización**,
la de [`01/04`](../01-fundamentos-y-modelo-relacional/04-normalizacion-y-desnormalizacion.md). Un
disparador puede mantenerla al día, recalculando el total cada vez que cambia una línea:

```text
tienda=# DROP TRIGGER pedidos_auditar ON pedidos;
DROP TRIGGER
tienda=# CREATE FUNCTION recalcular_total() RETURNS trigger LANGUAGE plpgsql AS $$ DECLARE p bigint := coalesce(NEW.pedido_id, OLD.pedido_id); BEGIN UPDATE pedidos SET total = (SELECT coalesce(sum(cantidad * precio_unit), 0) FROM pedido_lineas WHERE pedido_id = p) WHERE id = p; RETURN NULL; END $$;
CREATE FUNCTION
tienda=# \timing on
El despliegue de duración está activado.
tienda=# BEGIN;
BEGIN
Duración: 0,254 ms
tienda=*# UPDATE pedido_lineas SET cantidad = cantidad WHERE pedido_id <= 10000;
UPDATE 35000
Duración: 116,329 ms
tienda=*# ROLLBACK;
ROLLBACK
Duración: 0,353 ms
tienda=# CREATE TRIGGER lineas_total AFTER INSERT OR UPDATE OR DELETE ON pedido_lineas FOR EACH ROW EXECUTE FUNCTION recalcular_total();
CREATE TRIGGER
Duración: 9,041 ms
tienda=# BEGIN;
BEGIN
Duración: 0,284 ms
tienda=*# UPDATE pedido_lineas SET cantidad = cantidad WHERE pedido_id <= 10000;
UPDATE 35000
Duración: 981,954 ms
tienda=*# ROLLBACK;
ROLLBACK
Duración: 0,647 ms
tienda=# \timing off
El despliegue de duración está desactivado.
tienda=# SELECT total FROM pedidos WHERE codigo = 'PED-00042';
  total  
---------
 3186.23
(1 fila)

tienda=# UPDATE pedido_lineas SET cantidad = cantidad + 1 WHERE pedido_id = 42 AND linea = 1;
UPDATE 1
tienda=# SELECT total FROM pedidos WHERE codigo = 'PED-00042';
  total  
---------
 3289.06
(1 fila)

tienda=# UPDATE pedido_lineas SET cantidad = cantidad - 1 WHERE pedido_id = 42 AND linea = 1;
UPDATE 1
tienda=# SELECT total FROM pedidos WHERE codigo = 'PED-00042';
  total  
---------
 3186.23
(1 fila)
```

- **`coalesce(NEW.pedido_id, OLD.pedido_id)`**: en un `DELETE` no hay `NEW`, y en un `INSERT` no hay
  `OLD`. La misma función sirve para las tres operaciones.
- **El total se mantiene solo**: al sumar una unidad a la primera línea de `PED-00042` pasa de
  3 186,23 a 3 289,06, y al quitarla vuelve. Nadie tuvo que acordarse de recalcularlo.
- **Y cuesta 8,4 veces más**: de 116 ms a 982 para tocar 35 000 líneas de 10 000 pedidos. Cada línea
  recalcula su pedido entero, así que cada pedido se recalcula y se reescribe **tres veces y
  media**, una por línea, y cada reescritura deja una versión muerta de la fila de `pedidos`, que es
  MVCC.

> **Veredicto:** mantener una desnormalización con un disparador es correcto y caro: el coste se
> multiplica por las filas que tocan el mismo agregado. Por sentencia, recalculando cada pedido una
> vez, se ahorraría la repetición.

---

## 5. 🩺 Integridad: la regla que dos sesiones rompen

La regla de fraude: **un cliente no puede abrir un pedido pendiente si ya tiene uno**. Ni una clave
foránea ni un `CHECK` la expresan, porque depende de otras filas. Un disparador `BEFORE INSERT` la
comprueba. `CLI-00007`, `id` 7, es el cliente sin pedidos del documento de dominio.

Dos sesiones, `A` y `B`, abren un pedido pendiente para él a la vez:

```text
-- sesión A
tienda=# CREATE FUNCTION un_pendiente() RETURNS trigger LANGUAGE plpgsql AS $$ BEGIN IF EXISTS (SELECT 1 FROM pedidos WHERE cliente_id = NEW.cliente_id AND estado = 'PENDIENTE') THEN RAISE EXCEPTION 'el cliente % ya tiene un pedido pendiente', NEW.cliente_id; END IF; RETURN NEW; END $$;
CREATE FUNCTION
tienda=# CREATE TRIGGER pedidos_un_pendiente BEFORE INSERT ON pedidos FOR EACH ROW WHEN (NEW.estado = 'PENDIENTE') EXECUTE FUNCTION un_pendiente();
CREATE TRIGGER
tienda=# BEGIN;
BEGIN
tienda=*# INSERT INTO pedidos (codigo, cliente_id, estado, total, creado_en) VALUES ('PED-1000001', 7, 'PENDIENTE', 100, now());
INSERT 0 1
-- sesión B
tienda=# BEGIN;
BEGIN
tienda=*# INSERT INTO pedidos (codigo, cliente_id, estado, total, creado_en) VALUES ('PED-1000002', 7, 'PENDIENTE', 100, now());
INSERT 0 1
-- sesión A
tienda=*# COMMIT;
COMMIT
-- sesión B
tienda=*# COMMIT;
COMMIT
-- sesión A
tienda=# SELECT codigo, estado FROM pedidos WHERE cliente_id = 7 ORDER BY codigo;
   codigo    |  estado   
-------------+-----------
 PED-1000001 | PENDIENTE
 PED-1000002 | PENDIENTE
(2 filas)

tienda=# INSERT INTO pedidos (codigo, cliente_id, estado, total, creado_en) VALUES ('PED-1000003', 7, 'PENDIENTE', 100, now());
ERROR:  el cliente 7 ya tiene un pedido pendiente
CONTEXTO:  PL/pgSQL function un_pendiente() line 1 at RAISE
```

- **Dos pedidos pendientes, y ningún error.** Cuando `B` comprobó, el pedido de `A` existía pero no
  estaba confirmado, y en `READ COMMITTED` no se ve lo no confirmado. Cada una vio cero pendientes,
  y las dos insertaron. Es el **sesgo de escritura** de
  [`04/02`](../04-transacciones-y-concurrencia/02-aislamiento-y-sus-fenomenos.md).
- **El tercer intento, en serie, sí falla**: la regla funciona cuando nadie compite. Por eso pasa
  todas las pruebas de una sola sesión y falla en producción.
- **`WHEN (NEW.estado = 'PENDIENTE')`** filtra antes de llamar a la función: los pedidos en otros
  estados no pagan la comprobación.

La corrección es **serializar las inserciones del mismo cliente**, bloqueando su fila de `clientes`
antes de mirar. Tras borrar los dos pedidos:

```text
-- sesión A
tienda=# DELETE FROM pedidos WHERE cliente_id = 7;
DELETE 2
tienda=# CREATE OR REPLACE FUNCTION un_pendiente() RETURNS trigger LANGUAGE plpgsql AS $$ BEGIN PERFORM 1 FROM clientes WHERE id = NEW.cliente_id FOR UPDATE; IF EXISTS (SELECT 1 FROM pedidos WHERE cliente_id = NEW.cliente_id AND estado = 'PENDIENTE') THEN RAISE EXCEPTION 'el cliente % ya tiene un pedido pendiente', NEW.cliente_id; END IF; RETURN NEW; END $$;
CREATE FUNCTION
tienda=# BEGIN;
BEGIN
tienda=*# INSERT INTO pedidos (codigo, cliente_id, estado, total, creado_en) VALUES ('PED-1000001', 7, 'PENDIENTE', 100, now());
INSERT 0 1
-- sesión B
tienda=# BEGIN;
BEGIN
tienda=*# INSERT INTO pedidos (codigo, cliente_id, estado, total, creado_en) VALUES ('PED-1000002', 7, 'PENDIENTE', 100, now());
-- sesión A
tienda=*# COMMIT;
COMMIT
-- sesión B
ERROR:  el cliente 7 ya tiene un pedido pendiente
CONTEXTO:  PL/pgSQL function un_pendiente() line 1 at RAISE
tienda=!# ROLLBACK;
ROLLBACK
-- sesión A
tienda=# SELECT codigo, estado FROM pedidos WHERE cliente_id = 7 ORDER BY codigo;
   codigo    |  estado   
-------------+-----------
 PED-1000001 | PENDIENTE
(1 fila)
```

- **`PERFORM 1 FROM clientes WHERE id = NEW.cliente_id FOR UPDATE`** bloquea la fila del cliente.
  `B` se queda **esperando** en su `INSERT` —no devuelve nada— hasta que `A` confirma; entonces su
  comprobación ya ve el pedido de `A`, y falla.
- **Un pedido pendiente, como pedía la regla.** El precio es que dos pedidos del mismo cliente ya no
  se insertan a la vez; los de clientes distintos, sí.
- **La otra salida es `SERIALIZABLE`**, que detecta el conflicto y aborta una de las dos con un
  error de serialización que la aplicación reintenta; es
  [`04/02`](../04-transacciones-y-concurrencia/02-aislamiento-y-sus-fenomenos.md).

> **⚠️ Advertencia.** Toda regla que un disparador comprueba **mirando otras filas** tiene esta
> carrera en `READ COMMITTED`. Si la regla se puede escribir como restricción —`UNIQUE`, un índice
> único parcial, una exclusión—, se escribe así, porque el motor ya la hace segura con concurrencia.
> Aquí, un índice único parcial sobre `cliente_id` con `WHERE estado = 'PENDIENTE'` la cumpliría sin
> disparador, una vez corregidos los clientes que ya la incumplen: `CLI-00311` tiene seis.

---

## 6. 🧭 Por qué tienen mala fama

Las tres secciones anteriores dan los motivos, medidos:

- **Son invisibles**: el `UPDATE` de 100 000 pedidos tardó 2,4 veces más, y el de 35 000 líneas 8,4,
  sin que la sentencia lo diga. Quien diagnostica una lentitud mira la consulta y no ve la causa.
- **Se encadenan**: el disparador de las líneas actualiza `pedidos`, y si `pedidos` tuviera el de
  auditoría, cada línea escribiría también una fila de auditoría. En PostgreSQL, varios disparadores
  del mismo evento se ejecutan **por orden alfabético de nombre**, según su documentación, y ese
  orden rara vez está en la cabeza de nadie.
- **Parecen integridad y no lo son** del todo: la regla de §5 falló con dos sesiones.
- **Estorban en las cargas masivas**: cada fila de una carga paga el disparador. Las herramientas de
  carga y réplica los apagan, y eso significa que durante la carga las reglas no se cumplen.

**Cuándo sí**: auditoría que nadie debe poder saltarse; una desnormalización que se lee mucho más de
lo que se escribe; y reglas que no caben en una restricción, con el bloqueo que las haga seguras.
**Cuándo no**: lógica de negocio que cambia —va en la aplicación— ni nada que llame a sistemas
externos, que haría esperar a la sentencia de otro.

---

## 7. 📜 Estándar, motor y convención

> **📜 Estándar o motor.** Los disparadores están en el estándar SQL, con `FOR EACH ROW`,
> `FOR EACH STATEMENT` y `REFERENCING`; no he verificado la cláusula. La documentación de PostgreSQL
> dice que implementa un subconjunto, con extensiones como `OR` entre eventos o disparadores de
> `TRUNCATE`.

| Afirmación | Categoría | PostgreSQL 18 | MySQL 9.7 | SQLite 3.53 |
|---|---|---|---|---|
| Disparadores por fila | Estándar | Sí | Sí | Sí |
| Disparadores por sentencia | Estándar | Sí, con tablas de transición | No: error 1064 | No: error de sintaxis |
| Varios disparadores del mismo evento, en orden | Motor | Alfabético por nombre | `FOLLOWS` y `PRECEDES` | — |
| Una regla sobre otras filas es segura con concurrencia | Motor | No, sin bloqueo o `SERIALIZABLE` | — | — |
| La auditoría por fila duplica el coste del `UPDATE` | Motor | 2,4 veces, medido | — | — |
| Si cabe en una restricción, no va en un disparador | Convención | — | — | — |

**Convención, la que más se repite.** *«Los disparadores son malos»* — son código que corre sin
avisar, y por eso se reservan para lo que nadie debe poder saltarse. Lo malo es usarlos para lógica
de negocio, o para integridad que una restricción haría mejor.

---

## ⚠️ Errores frecuentes

| Se dice | Lo preciso |
|---|---|
| "Un disparador es gratis si la función es corta" | La auditoría por fila llevó el `UPDATE` de 882 a 2 119 ms |
| "El disparador por sentencia elimina el coste" | Ahorra las llamadas, 1 861 ms frente a 2 119, no la escritura |
| "Una regla en un disparador se cumple siempre" | Dos sesiones insertaron dos pedidos pendientes sin error |
| "Si pasa las pruebas, la regla es segura" | Falló solo con dos transacciones a la vez, y en serie funcionó |
| "Mantener un total con disparador cuesta una actualización por cambio" | Cuesta una por línea: 8,4 veces más para 35 000 líneas |
| "MySQL tiene disparadores por sentencia" | Solo por fila: `FOR EACH STATEMENT` da error 1064 |
| "El orden de los disparadores lo decide quien los crea" | En PostgreSQL, el alfabético por nombre |

---

## 📚 Para profundizar

- **Documentación** — PostgreSQL 18, «Overview of Trigger Behavior»: fila, sentencia y el orden.
  <https://www.postgresql.org/docs/18/trigger-definition.html>
- **Documentación** — PostgreSQL 18, «CREATE TRIGGER»: `REFERENCING` y la compatibilidad con el
  estándar. <https://www.postgresql.org/docs/18/sql-createtrigger.html>
- **Documentación** — PostgreSQL 18, «Trigger Functions» en PL/pgSQL: `NEW`, `OLD` y `TG_OP`.
  <https://www.postgresql.org/docs/18/plpgsql-trigger.html>
- **Documentación** — MySQL 9.7, «CREATE TRIGGER Statement».
  <https://dev.mysql.com/doc/refman/9.7/en/create-trigger.html>
- **Documentación** — SQLite, «CREATE TRIGGER»: solo `FOR EACH ROW`.
  <https://www.sqlite.org/lang_createtrigger.html>

---

## 🧠 Preguntas

1. ¿Qué es un disparador, y qué diferencia `BEFORE` de `AFTER`? 🟢
2. ¿Qué diferencia `FOR EACH ROW` de `FOR EACH STATEMENT`? 🟢
3. ¿Qué son las tablas de transición? 🟢
4. ¿Qué son `NEW`, `OLD` y `TG_OP` en una función de disparador? 🟢
5. ¿Qué pasa si un disparador `BEFORE` por fila devuelve `NULL`? ¿Lo fija el estándar o es cosa del
   motor? 🟡
6. ¿Qué motores del curso tienen disparadores por sentencia? ¿Lo fija el estándar o es cosa del
   motor? 🟡
7. ¿Por qué `recalcular_total` usa `coalesce(NEW.pedido_id, OLD.pedido_id)`? 🟡
8. ¿En qué orden se ejecutan varios disparadores del mismo evento en PostgreSQL? 🟡
9. ¿Por qué el disparador por sentencia ahorró tan poco frente al de fila? 🟠
10. ¿Por qué mantener el total con un disparador multiplicó por 8,4 el coste, y cómo lo reducirías?
    🟠
11. ¿Por qué las dos sesiones pudieron insertar dos pedidos pendientes, si el disparador lo
    comprobaba? 🟠
12. ¿Cómo corrige `FOR UPDATE` sobre la fila del cliente la carrera, y qué cuesta? 🟠
13. ¿Qué restricción cumpliría la regla de §5 sin disparador? 🟠
14. ¿Por qué un disparador complica diagnosticar una lentitud? 🟠
15. ¿Qué pasa con las reglas de un disparador durante una carga masiva que los apaga? 🟠
16. Diseña la auditoría de `pedidos`: qué guardas, con qué granularidad y qué coste aceptas. 🔴
17. Diagnostica: un proceso nocturno que actualiza el precio de 200 000 líneas pasó de un minuto a
    ocho tras un despliegue en el que nadie tocó ese proceso. 🔴
18. Defiende o refuta mantener `pedidos.total` con un disparador en la tienda, con los números del
    capítulo. 🔴

---

**Anterior:** [`01`](01-funciones-y-procedimientos.md) — funciones y procedimientos · **Siguiente:**
[`03`](03-claves-generadas.md) — claves generadas · **Relacionado:**
[`04/02`](../04-transacciones-y-concurrencia/02-aislamiento-y-sus-fenomenos.md) — el sesgo de
escritura, en aislamiento.
