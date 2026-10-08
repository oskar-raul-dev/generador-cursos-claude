# 04 — Expandir y contraer

> Cómo se cambia el esquema de una base que no puede parar, con la secuencia completa de un
> renombrado de columna: expandir, copiar, rellenar, cambiar la aplicación y contraer. Medido en
> PostgreSQL: un `ALTER TABLE` que espera un bloqueo **deja esperando a la consulta más simple de
> detrás**, y `lock_timeout` lo corta en dos segundos; un valor por defecto constante se añade en
> 1,6 ms y uno volátil reescribe el millón de pedidos en 1,97 s; y un `CREATE INDEX` normal bloquea
> los `UPDATE`, que el concurrente no. **Asume leído:** [`03`](03-migraciones-de-esquema.md), las
> migraciones, y [`04/04`](../04-transacciones-y-concurrencia/04-bloqueos-e-interbloqueos.md), los
> bloqueos. **Vigencia:** 27 de septiembre de 2026.

---

## Salto rápido

- [1. El problema](#1--el-problema) · [2. Expandir y contraer](#2--expandir-y-contraer)
- [3. La cola de bloqueos](#3--la-cola-de-bloqueos) · [4. Qué `ALTER` reescribe la
  tabla](#4--qué-alter-reescribe-la-tabla)
- [5. Índices sin bloquear escrituras](#5--índices-sin-bloquear-escrituras) · [6. El renombrado,
  entero](#6--el-renombrado-entero)
- [7. Estándar, motor y convención](#7--estándar-motor-y-convención) · [Errores
  frecuentes](#️-errores-frecuentes) · [Preguntas](#-preguntas)

---

## 1. 🎯 El problema

La tienda despliega varias veces al día, y durante cada despliegue conviven **dos versiones de la
aplicación**: la vieja, que aún atiende peticiones, y la nueva, que empieza a hacerlo. Una migración
que renombra `clientes.pais` a `pais_iso` rompe a la vieja en cuanto se aplica, y si se aplica
después del despliegue, rompe a la nueva mientras tanto.

Y hay un segundo problema, menos visible: algunas operaciones de esquema necesitan un bloqueo que
detiene la tabla entera. Si ese bloqueo tarda en llegar, **todo lo que llega detrás espera
también**, y la tienda se para aunque el `ALTER` en sí dure un milisegundo.

Este capítulo mide los dos: la secuencia que permite cambiar el esquema con las dos versiones vivas,
y las operaciones que bloquean y cómo evitarlo.

> **📝 Contexto.** Todo se corrió en la copia aislada `bd-lab-prueba` de
> [`01`](01-usuarios-roles-y-permisos.md), porque las sesiones renombran columnas y reescriben
> `pedidos`. Las sesiones con varias terminales intercalan sus órdenes en el orden en que se
> escribieron, con una línea `-- sesión A`, `B` o `C` al cambiar. **Longitud:** unas 450 líneas;
> capítulo normal que pasa el disparador de 400.

---

## 2. 🧱 Expandir y contraer

**Qué es:** **expandir y contraer** —también llamado cambio en paralelo— es partir un cambio
incompatible en pasos que **cada uno es compatible con la versión anterior y con la siguiente**:

1. **Expandir**: añadir lo nuevo sin quitar lo viejo. La columna `pais_iso` junto a `pais`.
2. **Copiar las escrituras**: que todo lo que se escriba en lo viejo llegue a lo nuevo, con un
   disparador o desde la aplicación.
3. **Rellenar** lo que ya había, por lotes.
4. **Cambiar la aplicación**: la nueva versión lee y escribe `pais_iso`; mientras la vieja siga
   viva, la copia va en los dos sentidos.
5. **Contraer**: cuando ya no queda ninguna versión que use lo viejo, borrarlo.

**Quién lo manda:** nadie. Es **convención** de despliegue; lo que la hace posible o imposible es el
**motor**: qué operaciones toman qué bloqueos y cuánto duran.

**Cuánto cuesta**: un renombrado pasa de una migración a cinco, repartidas en varios despliegues, y
durante un tiempo la tabla tiene la columna dos veces. Es el precio de no parar.

---

## 3. 🩺 La cola de bloqueos

Tres sesiones. `A` es un informe que lee `clientes` dentro de una transacción; `B`, la migración que
añade la columna; `C`, una pantalla de la tienda que busca un cliente por su código:

```text
-- sesión A
tienda=# BEGIN;
BEGIN
tienda=*# SELECT count(*) FROM clientes WHERE pais = 'ES';
 count 
-------
  3572
(1 fila)

-- sesión B: se queda esperando
tienda=# ALTER TABLE clientes ADD COLUMN pais_iso char(2);
-- sesión C: se queda esperando
tienda=# SELECT codigo FROM clientes WHERE codigo = 'CLI-00311';
-- sesión A
tienda=*# SELECT pid, pg_blocking_pids(pid) AS bloqueado_por, wait_event_type, left(query, 45) AS consulta FROM pg_stat_activity WHERE application_name LIKE 'sesion_%' ORDER BY backend_start;
 pid  | bloqueado_por | wait_event_type |                   consulta                    
------+---------------+-----------------+-----------------------------------------------
 2141 | {}            |                 | SELECT pid, pg_blocking_pids(pid) AS bloquead
 2142 | {2141}        | Lock            | ALTER TABLE clientes ADD COLUMN pais_iso char
 2143 | {2142}        | Lock            | SELECT codigo FROM clientes WHERE codigo = 'C
(3 filas)

tienda=*# ROLLBACK;
ROLLBACK
-- sesión B
ALTER TABLE
-- sesión C
  codigo   
-----------
 CLI-00311
(1 fila)
```

- **`B` espera a `A`**: `ADD COLUMN` necesita un bloqueo `ACCESS EXCLUSIVE`, que choca con cualquier
  otro, y `A` tiene la tabla abierta para leer.
- **Y `C` espera a `B`**, no a `A`: `pg_blocking_pids` lo dice, `{2142}`. La lectura de `C` sería
  compatible con la de `A`, pero **se pone en la cola detrás del `ALTER`**, que ya pidió su bloqueo.
  Una sola transacción de informe abierta, más una migración, bastan para parar todas las lecturas
  de la tabla.
- **Al terminar `A`, se deshace el nudo**: `B` añade la columna y `C` devuelve su fila.

La defensa es que la migración **se rinda** en vez de esperar:

```text
-- sesión B
tienda=# SET lock_timeout = '2s';
SET
-- sesión A
tienda=# BEGIN;
BEGIN
tienda=*# SELECT count(*) FROM clientes WHERE pais = 'ES';
 count 
-------
  3572
(1 fila)

-- sesión B
tienda=# ALTER TABLE clientes DROP COLUMN pais_iso;
ERROR:  canceling statement due to lock timeout
-- sesión C
tienda=# SELECT codigo FROM clientes WHERE codigo = 'CLI-00311';
  codigo   
-----------
 CLI-00311
(1 fila)

-- sesión A
tienda=*# ROLLBACK;
ROLLBACK
```

- **`lock_timeout`** cancela la sentencia que espera un bloqueo más del tiempo dado. El `ALTER`
  falló a los dos segundos —el guion que movía las sesiones midió 2,01 s— y `C`, lanzada después,
  respondió al instante.
- **Una migración que falla por `lock_timeout` se reintenta** más tarde; una que espera sin límite
  para la tienda. Toda migración que toque tablas en uso se lanza con él.

> **⚠️ Advertencia.** Lo que para la tienda no es el `ALTER`, que dura milisegundos, sino **la
> espera del `ALTER`**, que arrastra a todo lo de detrás. Por eso se mata antes la transacción
> larga, o se pone `lock_timeout`, y nunca se lanza una migración con un informe de horas corriendo.

---

## 4. 🩺 Qué `ALTER` reescribe la tabla

No todos los `ALTER TABLE` cuestan lo mismo. Sobre el millón de pedidos:

```text
tienda=# SELECT pg_relation_filenode('pedidos') AS fichero;
 fichero 
---------
   16530
(1 fila)

tienda=# \timing on
El despliegue de duración está activado.
tienda=# ALTER TABLE pedidos ADD COLUMN canal text NOT NULL DEFAULT 'web';
ALTER TABLE
Duración: 1,599 ms
tienda=# ALTER TABLE pedidos ADD COLUMN prioridad double precision NOT NULL DEFAULT random();
ALTER TABLE
Duración: 1970,725 ms (00:01,971)
tienda=# \timing off
El despliegue de duración está desactivado.
tienda=# SELECT pg_relation_filenode('pedidos') AS fichero;
 fichero 
---------
   16642
(1 fila)
```

- **Un valor por defecto constante: 1,6 ms**, sin tocar una fila. La documentación de `ALTER TABLE`
  lo explica: con un `DEFAULT` no volátil, el valor se guarda en los metadatos de la tabla y se
  devuelve al leer las filas viejas; no hace falta reescribir.
- **Uno volátil, `random()`: 1,97 s**, y **`pg_relation_filenode` cambió**, de 16530 a 16642: la
  tabla se reescribió entera en un fichero nuevo, porque cada fila necesita su propio valor. Durante
  esos dos segundos, con `ACCESS EXCLUSIVE`: nadie lee ni escribe `pedidos`. Con una tabla de cien
  veces más, son minutos.
- **La regla**: una columna nueva, sin valor por defecto o con uno constante; si necesita un valor
  por fila, se añade vacía y se **rellena por lotes**, como en §6.

**Añadir `NOT NULL`** tiene el mismo problema: comprobarlo recorre la tabla con el bloqueo tomado.
La documentación da la salida: si ya existe una restricción `CHECK` válida que demuestra que no hay
nulos, `SET NOT NULL` se salta el recorrido. Y esa `CHECK` se puede validar sin bloquear las
escrituras:

```text
tienda=# ALTER TABLE pedidos ADD CONSTRAINT canal_no_nulo CHECK (canal IS NOT NULL) NOT VALID;
ALTER TABLE
Duración: 0,640 ms
tienda=# ALTER TABLE pedidos VALIDATE CONSTRAINT canal_no_nulo;
ALTER TABLE
Duración: 52,965 ms
```

- **`NOT VALID`** crea la restricción al instante, comprobándola solo en las filas nuevas;
  **`VALIDATE CONSTRAINT`** recorre las viejas —53 ms aquí— con un bloqueo que deja seguir leyendo y
  escribiendo. Después, `SET NOT NULL` ya no necesita recorrer nada.

---

## 5. 🧱 Índices sin bloquear escrituras

Un índice nuevo sobre `pedidos`, con dos sesiones: `A` lo crea dentro de una transacción, para ver
qué bloqueo toma; `B` intenta cambiar un pedido.

```text
-- sesión A
tienda=# BEGIN;
BEGIN
tienda=*# CREATE INDEX pedidos_prioridad ON pedidos (prioridad);
CREATE INDEX
tienda=*# SELECT mode FROM pg_locks WHERE relation = 'pedidos'::regclass AND pid = pg_backend_pid();
   mode    
-----------
 ShareLock
(1 fila)

-- sesión B: se queda esperando
tienda=# UPDATE pedidos SET canal = 'movil' WHERE codigo = 'PED-00042';
-- sesión A
tienda=*# SELECT pid, pg_blocking_pids(pid) AS bloqueado_por, left(query, 40) AS consulta FROM pg_stat_activity WHERE application_name = 'sesion_B';
 pid  | bloqueado_por |                 consulta                 
------+---------------+------------------------------------------
 2255 | {2254}        | UPDATE pedidos SET canal = 'movil' WHERE
(1 fila)

tienda=*# ROLLBACK;
ROLLBACK
-- sesión B
UPDATE 1
tienda=# UPDATE pedidos SET canal = 'web' WHERE codigo = 'PED-00042';
UPDATE 1
```

- **`CREATE INDEX` toma `ShareLock`**, que deja leer y **no deja escribir**: el `UPDATE` de `B`
  esperó a que `A` terminara. La documentación lo dice: una creación normal bloquea las escrituras,
  no las lecturas, hasta que acaba. El segundo `UPDATE` devuelve `PED-00042` a su valor.

La alternativa es la creación **concurrente**, que no bloquea las escrituras:

```text
tienda=# CREATE INDEX pedidos_canal ON pedidos (canal);
CREATE INDEX
Duración: 166,396 ms
tienda=# DROP INDEX pedidos_canal;
DROP INDEX
Duración: 1,476 ms
tienda=# CREATE INDEX CONCURRENTLY pedidos_canal ON pedidos (canal);
CREATE INDEX
Duración: 192,274 ms
tienda=# BEGIN;
BEGIN
Duración: 0,343 ms
tienda=*# CREATE INDEX CONCURRENTLY pedidos_prioridad ON pedidos (prioridad);
ERROR:  CREATE INDEX CONCURRENTLY cannot run inside a transaction block
Duración: 0,426 ms
tienda=!# ROLLBACK;
ROLLBACK
Duración: 0,310 ms
```

- **`CONCURRENTLY` tarda algo más** —192 ms frente a 166— porque recorre la tabla dos veces y espera
  a las transacciones en curso, pero las escrituras siguen durante todo ese tiempo.
- **No puede ir dentro de una transacción**: es la excepción de
  [`03`](03-migraciones-de-esquema.md) §5. Una herramienta que envuelve cada migración en una
  transacción necesita que esa migración se marque como no transaccional.
- **Si falla a la mitad**, deja un índice inválido que hay que borrar y volver a crear; es parte de
  lo que su documentación llama las advertencias de la creación concurrente.

> **Veredicto:** en una tabla en uso, los índices se crean con `CONCURRENTLY`, las restricciones con
> `NOT VALID` y `VALIDATE`, y todo con `lock_timeout`.

---

## 6. 🧱 El renombrado, entero

La columna `pais_iso` ya existe desde §3. Los pasos 2 y 3 —copiar las escrituras y rellenar por
lotes— y el 5, contraer, en una sesión:

```text
tienda=# \timing on
El despliegue de duración está activado.
tienda=# CREATE FUNCTION copiar_pais() RETURNS trigger LANGUAGE plpgsql AS $$ BEGIN NEW.pais_iso := NEW.pais; RETURN NEW; END $$;
CREATE FUNCTION
Duración: 4,514 ms
tienda=# CREATE TRIGGER clientes_copiar_pais BEFORE INSERT OR UPDATE OF pais ON clientes FOR EACH ROW EXECUTE FUNCTION copiar_pais();
CREATE TRIGGER
Duración: 0,787 ms
tienda=# CREATE PROCEDURE rellenar_pais_iso(p_lote integer) LANGUAGE plpgsql AS $$ DECLARE n integer; BEGIN LOOP UPDATE clientes SET pais_iso = pais WHERE id IN (SELECT id FROM clientes WHERE pais_iso IS NULL LIMIT p_lote); GET DIAGNOSTICS n = ROW_COUNT; EXIT WHEN n = 0; COMMIT; END LOOP; END $$;
CREATE PROCEDURE
Duración: 0,710 ms
tienda=# CALL rellenar_pais_iso(10000);
CALL
Duración: 794,174 ms
tienda=# SELECT count(*) AS distintos FROM clientes WHERE pais_iso IS DISTINCT FROM pais;
 distintos 
-----------
         0
(1 fila)

Duración: 7,410 ms
tienda=# UPDATE clientes SET pais = 'PT' WHERE codigo = 'CLI-00311';
UPDATE 1
Duración: 1,084 ms
tienda=# SELECT codigo, pais, pais_iso FROM clientes WHERE codigo = 'CLI-00311';
  codigo   | pais | pais_iso 
-----------+------+----------
 CLI-00311 | PT   | PT
(1 fila)

Duración: 0,286 ms
tienda=# UPDATE clientes SET pais = 'ES' WHERE codigo = 'CLI-00311';
UPDATE 1
Duración: 0,431 ms
tienda=# SET lock_timeout = '2s';
SET
Duración: 0,220 ms
tienda=# DROP TRIGGER clientes_copiar_pais ON clientes;
DROP TRIGGER
Duración: 0,630 ms
tienda=# ALTER TABLE clientes DROP COLUMN pais;
ALTER TABLE
Duración: 0,547 ms
tienda=# ALTER TABLE clientes ALTER COLUMN pais_iso SET NOT NULL;
ALTER TABLE
Duración: 4,106 ms
tienda=# SELECT codigo, pais_iso FROM clientes WHERE codigo = 'CLI-00311';
  codigo   | pais_iso 
-----------+----------
 CLI-00311 | ES
(1 fila)

Duración: 0,571 ms
```

- **Paso 2, copiar**: el disparador `BEFORE INSERT OR UPDATE OF pais` copia `pais` en `pais_iso` en
  cada escritura. La versión vieja de la aplicación sigue escribiendo `pais` sin saber nada; la
  prueba con `CLI-00311` lo enseña: `PT` en las dos columnas.
- **Paso 3, rellenar**: el procedimiento por lotes de
  [`05/01`](../05-programacion-en-el-motor/01-funciones-y-procedimientos.md) §6, confirmando cada
  10 000 filas: 794 ms para los 50 000 clientes, sin retener bloqueos. `IS DISTINCT FROM` compara
  tratando los nulos como valores, y da cero diferencias.
- **Paso 4, cambiar la aplicación**, no sale en la sesión porque es un despliegue: la versión nueva
  lee y escribe `pais_iso`, y mientras quede la vieja, el disparador copia en los dos sentidos.
- **Paso 5, contraer**, con `lock_timeout`: borrar el disparador y la columna vieja son cambios de
  metadatos, 0,5 ms cada uno. `SET NOT NULL` recorrió la tabla, 4 ms para 50 000 filas; en una tabla
  grande, con la `CHECK` validada de §4 delante.

**Cuánto cuesta**: cinco pasos en al menos tres despliegues, un disparador vivo durante días, y la
disciplina de no contraer hasta que la última instancia de la versión vieja haya muerto.

---

## 7. 📜 Estándar, motor y convención

> **📜 Estándar o motor.** Expandir y contraer es convención de despliegue. Los bloqueos que toma
> cada `ALTER`, lo que reescribe la tabla, `CREATE INDEX CONCURRENTLY`, `NOT VALID` y `lock_timeout`
> son de PostgreSQL; MySQL tiene sus propios algoritmos para cambiar tablas en línea, con otras
> reglas.

| Afirmación | Categoría | PostgreSQL 18 |
|---|---|---|
| Una lectura puede quedar bloqueada por un `ALTER` que espera | Motor | Sí: `C` esperó a `B`, que esperaba a `A` |
| `lock_timeout` corta la espera | Motor | Sí, a los 2 s |
| Añadir una columna con valor constante reescribe la tabla | Motor | No: 1,6 ms |
| Con un valor volátil, sí | Motor | Sí: 1,97 s y fichero nuevo |
| `CREATE INDEX` normal bloquea escrituras | Motor | Sí, `ShareLock` |
| `CREATE INDEX CONCURRENTLY` va en una transacción | Motor | No: error |
| Cambiar una columna en cinco pasos compatibles | Convención | — |

**Convención, la que más se repite.** *«Las migraciones se hacen en la ventana de mantenimiento»* —
con despliegues diarios no hay ventana. La secuencia de expandir y contraer, con los bloqueos
medidos, es lo que sustituye a la ventana.

---

## ⚠️ Errores frecuentes

| Se dice | Lo preciso |
|---|---|
| "Un `ADD COLUMN` es instantáneo" | Con valor constante, sí: 1,6 ms; con `random()`, reescribió la tabla en 1,97 s |
| "Si el `ALTER` dura un milisegundo, no molesta" | Su espera dejó bloqueada una lectura que no tenía nada que ver |
| "Las lecturas no se bloquean nunca" | `C` esperó detrás del `ALTER` en la cola del bloqueo |
| "`CREATE INDEX` solo lee la tabla" | Toma `ShareLock` y bloqueó el `UPDATE` de otra sesión |
| "Todo se puede hacer en una migración transaccional" | `CREATE INDEX CONCURRENTLY` no puede ir en una transacción |
| "Renombrar es un `RENAME COLUMN` y listo" | Rompe a la versión de la aplicación que aún usa el nombre viejo |
| "Añadir `NOT NULL` es barato" | Recorre la tabla con el bloqueo tomado, salvo con una `CHECK` validada antes |

---

## 📚 Para profundizar

- **Documentación** — PostgreSQL 18, «ALTER TABLE»: qué reescribe y cómo evitar el recorrido de
  `SET NOT NULL`. <https://www.postgresql.org/docs/18/sql-altertable.html>
- **Documentación** — PostgreSQL 18, «Explicit Locking»: los modos de bloqueo y sus conflictos.
  <https://www.postgresql.org/docs/18/explicit-locking.html>
- **Documentación** — PostgreSQL 18, «CREATE INDEX»: la creación concurrente y sus advertencias.
  <https://www.postgresql.org/docs/18/sql-createindex.html>
- **Documentación** — PostgreSQL 18, «Client Connection Defaults»: `lock_timeout`.
  <https://www.postgresql.org/docs/18/runtime-config-client.html>

---

## 🧠 Preguntas

1. ¿Qué es expandir y contraer, y cuáles son sus cinco pasos? 🟢
2. ¿Qué hace `lock_timeout`? 🟢
3. ¿Qué diferencia `CREATE INDEX` de `CREATE INDEX CONCURRENTLY`? 🟢
4. ¿Qué hace `NOT VALID` en una restricción? 🟢
5. ¿Por qué un renombrado directo rompe un despliegue con dos versiones vivas? ¿Qué parte es del
   motor y qué parte es convención? 🟡
6. ¿Qué bloqueo toma `ADD COLUMN`, y con qué choca? ¿Lo fija el estándar o es cosa del motor? 🟡
7. ¿Qué indica que `pg_relation_filenode` cambie tras un `ALTER`? 🟡
8. ¿Por qué `CREATE INDEX CONCURRENTLY` no puede ir en una transacción, y qué implica para una
   herramienta de migraciones? 🟡
9. ¿Qué hace `IS DISTINCT FROM`, y por qué se usa para comprobar el relleno? 🟡
10. ¿Por qué la sesión `C` quedó bloqueada si solo quería leer? 🟠
11. ¿Por qué una columna con un valor por defecto constante se añadió en 1,6 ms y una con
    `random()` tardó 1,97 s? 🟠
12. ¿Cómo se añade `NOT NULL` a una columna de una tabla grande sin bloquearla durante el recorrido?
    🟠
13. ¿Por qué el relleno se hace por lotes con `COMMIT`, y no con un solo `UPDATE`? 🟠
14. ¿Cuándo es seguro el paso de contraer, y qué pasa si se hace antes? 🟠
15. ¿Qué pasa si `CREATE INDEX CONCURRENTLY` falla a la mitad? 🔴
16. Diseña la migración para cambiar `pedidos.total` de `numeric(12,2)` a `numeric(14,2)` sin parar
    la tienda. 🔴
17. Diagnostica: durante un despliegue que solo añadía una columna, todas las pantallas de clientes
    dejaron de responder dos minutos, y el `ALTER` registrado en el log tardó 3 ms. 🔴
18. Defiende o refuta hacer los cambios de esquema en una ventana de mantenimiento mensual en vez de
    con expandir y contraer, con lo que enseña el capítulo. 🔴

---

**Anterior:** [`03`](03-migraciones-de-esquema.md) — migraciones de esquema · **Siguiente:**
[`05`](05-monitorizacion-y-mantenimiento.md) — monitorización y mantenimiento · **Relacionado:**
[`04/04`](../04-transacciones-y-concurrencia/04-bloqueos-e-interbloqueos.md) — los bloqueos y sus
esperas.
