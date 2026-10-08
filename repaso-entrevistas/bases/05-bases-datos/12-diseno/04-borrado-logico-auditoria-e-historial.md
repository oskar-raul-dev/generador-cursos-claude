# 04 — Borrado lógico, auditoría e historial

> Tres formas de no perder el pasado —marcar en vez de borrar, apuntar quién cambió qué, guardar
> cada versión de una fila— y lo que cuesta cada una. Medido: un cliente borrado lógicamente impide
> que otro se registre con su correo hasta que la restricción se rehace como índice único parcial;
> PostgreSQL 18 rechaza dos precios solapados en el tiempo con una clave temporal; y MariaDB guarda
> las tres versiones de un precio, y la historia sobrevive al `DELETE`. **Asume leído:**
> [`05/02`](../05-programacion-en-el-motor/02-disparadores.md), la auditoría con disparadores.
> **Vigencia:** 27 de septiembre de 2026.

---

## Salto rápido

- [1. El problema](#1--el-problema) · [2. Borrado lógico](#2--borrado-lógico)
- [3. Auditoría](#3--auditoría) · [4. Historial en el tiempo de la
  aplicación](#4--historial-en-el-tiempo-de-la-aplicación)
- [5. Historial en el tiempo del sistema](#5-️-historial-en-el-tiempo-del-sistema) · [6. Cómo se
  elige](#6--cómo-se-elige)
- [7. Estándar, motor y convención](#7--estándar-motor-y-convención) · [Errores
  frecuentes](#️-errores-frecuentes) · [Preguntas](#-preguntas)

---

## 1. 🎯 El problema

Tres peticiones distintas que suelen llegar juntas. Atención al cliente quiere poder «recuperar» un
cliente dado de baja por error. Cumplimiento quiere saber quién cambió el precio de `PRD-00017` y
qué había antes. Contabilidad quiere saber qué precio tenía el producto el día en que se vendió cada
pedido.

Suenan a lo mismo —no perder datos— y son tres problemas con tres soluciones: el **borrado lógico**,
la **auditoría** y el **historial**. Mezclarlas es el fallo de diseño más habitual: una columna
`borrado` que se usa como auditoría, o una tabla de auditoría que se consulta como historial de
precios.

> **📝 Contexto.** PostgreSQL se corrió en la copia aislada `bd-lab-prueba`, donde se añadió
> `clientes.borrado_en` y se creó un cliente nuevo, `CLI-50001`, que solo existe ahí. MariaDB, en un
> contenedor desechable `mariadb:12.3.3` —la misma versión del entorno—, porque las tablas
> versionadas se crean y se tiran. **Longitud:** unas 360 líneas; capítulo normal.

---

## 2. 🩺 Borrado lógico

**Qué es:** en vez de borrar la fila, se marca como borrada —una columna `borrado_en` con la fecha—
y se filtra en cada consulta. La fila sigue ahí para recuperarla, para las claves foráneas que la
apuntan y para los informes del pasado.

**Quién lo manda:** es **convención** de diseño. El motor no sabe que una fila está «borrada», y eso
es exactamente el problema:

```text
tienda=# ALTER TABLE clientes ADD COLUMN borrado_en timestamptz;
ALTER TABLE
tienda=# UPDATE clientes SET borrado_en = now() WHERE codigo = 'CLI-00311';
UPDATE 1
tienda=# INSERT INTO clientes (codigo, nombre, email, pais) VALUES ('CLI-50001', 'Cliente 50001', 'cliente311@ejemplo.test', 'ES');
ERROR:  duplicate key value violates unique constraint "clientes_email_key"
DETALLE:  Key (email)=(cliente311@ejemplo.test) already exists.
tienda=# ALTER TABLE clientes DROP CONSTRAINT clientes_email_key;
ALTER TABLE
tienda=# CREATE UNIQUE INDEX clientes_email_activo ON clientes (email) WHERE borrado_en IS NULL;
CREATE INDEX
tienda=# INSERT INTO clientes (codigo, nombre, email, pais) VALUES ('CLI-50001', 'Cliente 50001', 'cliente311@ejemplo.test', 'ES');
INSERT 0 1
tienda=# INSERT INTO clientes (codigo, nombre, email, pais) VALUES ('CLI-50002', 'Cliente 50002', 'cliente311@ejemplo.test', 'ES');
ERROR:  duplicate key value violates unique constraint "clientes_email_activo"
DETALLE:  Key (email)=(cliente311@ejemplo.test) already exists.
tienda=# SELECT codigo, email, borrado_en IS NOT NULL AS borrado FROM clientes WHERE email = 'cliente311@ejemplo.test' ORDER BY codigo;
  codigo   |          email          | borrado 
-----------+-------------------------+---------
 CLI-00311 | cliente311@ejemplo.test | t
 CLI-50001 | cliente311@ejemplo.test | f
(2 filas)

tienda=# SELECT count(*) AS todos, count(*) FILTER (WHERE borrado_en IS NULL) AS activos FROM clientes;
 todos | activos 
-------+---------
 50001 |   50000
(1 fila)
```

- **El cliente «borrado» sigue ocupando su correo**: la restricción `UNIQUE` no sabe nada de
  `borrado_en`, y quien se registra con el mismo correo recibe un error de clave duplicada.
- **La corrección es un índice único parcial**: `WHERE borrado_en IS NULL` hace que la unicidad
  valga solo entre los activos. `CLI-50001` entró; un segundo activo con el mismo correo,
  `CLI-50002`, no.
- **Cada consulta tiene que filtrar**: `count(*)` a secas dice 50 001 clientes, uno de ellos
  borrado. Un informe, una exportación o un `JOIN` que olvide el filtro cuenta a los borrados. La
  defensa habitual es una vista de activos, o la seguridad a nivel de fila.

**Cuánto cuesta**: las filas borradas siguen ocupando la tabla y sus índices, cada restricción de
unicidad hay que rehacerla como parcial, y cada consulta nueva es una ocasión de olvidar el filtro.
Y un borrado lógico **no es un borrado** a efectos legales: si un cliente pide que se borren sus
datos, la fila marcada los sigue guardando.

> **Veredicto:** el borrado lógico sirve para deshacer bajas por error y para no romper referencias.
> No es auditoría ni historial, y tiene que venir con índices parciales y un filtro que nadie
> olvide.

---

## 3. 🧱 Auditoría

**Qué es:** una tabla aparte que apunta cada cambio —quién, cuándo, qué operación, la fila de antes
y la de después—, escrita por disparadores para que nadie se la salte.

**Quién lo manda:** **convención**, sobre los disparadores del **motor**. La midió
[`05/02`](../05-programacion-en-el-motor/02-disparadores.md) §3 con la tabla `auditoria`:

| Actualizar 100 000 pedidos | Tiempo |
|---|---|
| Sin disparador | 882 ms |
| Con disparador de auditoría por fila | 2 119 ms, 2,4 veces más |
| Con disparador por sentencia y tablas de transición | 1 861 ms |

- **La auditoría contesta «quién cambió esto»**, fila a fila y cambio a cambio. Es la que pide
  cumplimiento, y la que no puede depender de que la aplicación se acuerde de escribirla.
- **No contesta bien «cuánto valía el 15 de marzo»**: hay que reconstruir el estado recorriendo los
  cambios hacia atrás, con los datos guardados en `jsonb`. Para esa pregunta está el historial.
- **Cuánto cuesta**: una fila de auditoría por cada fila cambiada —el doble de escritura— y una
  tabla que solo crece, que se particiona por mes para poder borrar lo que caduca.

---

## 4. 🧱 Historial en el tiempo de la aplicación

**Qué es:** guardar para cada dato **el periodo en que es válido** según el negocio —un precio vale
del 1 de enero al 1 de julio— y consultar el de cualquier fecha. Es el **tiempo de la aplicación**:
lo fija quien carga el dato, y puede ser futuro («el precio baja el 1 de julio»).

**Quién lo manda:** el **motor**: PostgreSQL 18 trae **claves temporales**: una clave primaria con
`WITHOUT OVERLAPS` sobre un rango, que impide dos periodos solapados para el mismo producto.

```text
tienda=# CREATE TABLE precios_vigentes (producto text, vigencia daterange, precio numeric(12,2) NOT NULL, PRIMARY KEY (producto, vigencia WITHOUT OVERLAPS));
ERROR:  data type text has no default operator class for access method "gist"
SUGERENCIA:  You must specify an operator class for the index or define a default operator class for the data type.
tienda=# CREATE EXTENSION btree_gist;
CREATE EXTENSION
tienda=# CREATE TABLE precios_vigentes (producto text, vigencia daterange, precio numeric(12,2) NOT NULL, PRIMARY KEY (producto, vigencia WITHOUT OVERLAPS));
CREATE TABLE
tienda=# INSERT INTO precios_vigentes VALUES ('PRD-00017', '[2025-01-01,2025-07-01)', 129.90), ('PRD-00017', '[2025-07-01,)', 119.90);
INSERT 0 2
tienda=# INSERT INTO precios_vigentes VALUES ('PRD-00017', '[2025-06-01,2025-08-01)', 99.90);
ERROR:  conflicting key value violates exclusion constraint "precios_vigentes_pkey"
DETALLE:  Key (producto, vigencia)=(PRD-00017, [2025-06-01,2025-08-01)) conflicts with existing key (producto, vigencia)=(PRD-00017, [2025-01-01,2025-07-01)).
tienda=# SELECT precio FROM precios_vigentes WHERE producto = 'PRD-00017' AND vigencia @> date '2025-03-15';
 precio 
--------
 129.90
(1 fila)
```

- **El primer error pide `btree_gist`**: la clave se comprueba con un índice GiST, que de serie solo
  sabe comparar rangos. La documentación de `CREATE TABLE` lo dice: para las otras columnas, como el
  texto de `producto`, se añade esa extensión, que es la forma esperada de usar la función.
- **`daterange`** es un rango de fechas: `[2025-01-01,2025-07-01)` incluye el 1 de enero y excluye
  el 1 de julio, así que el periodo siguiente empieza justo donde acaba este. `[2025-07-01,)` no
  tiene fin.
- **El precio solapado se rechaza**, con el periodo con el que choca en el mensaje. La documentación
  llama a esto una **clave temporal**, y por debajo es una restricción de exclusión.
- **`vigencia @> date '2025-03-15'`** pregunta qué periodo contiene esa fecha: 129,90. Es la
  pregunta de contabilidad, contestada con una consulta y no reconstruyendo cambios.

---

## 5. ⚖️ Historial en el tiempo del sistema

**Qué es:** que la base guarde **sola** cada versión de cada fila, con el instante en que empezó y
terminó de estar vigente **en la base**, y permita consultar la tabla como estaba en cualquier
momento. Es el **tiempo del sistema**: lo fija el motor al confirmar, nadie puede ponerlo a mano.

**Quién lo manda:** también SQL:2011, según la documentación de MariaDB, que lo implementa.
PostgreSQL 18 no:

```text
tienda=# CREATE TABLE precios_sistema (producto text PRIMARY KEY, precio numeric(12,2)) WITH SYSTEM VERSIONING;
ERROR:  syntax error at or near "SYSTEM"
LÍNEA 1: ...ucto text PRIMARY KEY, precio numeric(12,2)) WITH SYSTEM VER...
                                                              ^
```

En MariaDB:

```text
MariaDB [tienda]> CREATE TABLE precios (producto CHAR(9) PRIMARY KEY, precio DECIMAL(12,2) NOT NULL) WITH SYSTEM VERSIONING;
Query OK, 0 rows affected (0.004 sec)

MariaDB [tienda]> INSERT INTO precios VALUES ('PRD-00017', 129.90);
Query OK, 1 row affected (0.001 sec)

MariaDB [tienda]> SELECT NOW(6) INTO @antes;
Query OK, 1 row affected (0.000 sec)
```

Un segundo después, en la misma sesión:

```text
MariaDB [tienda]> UPDATE precios SET precio = 119.90 WHERE producto = 'PRD-00017';
Query OK, 1 row affected (0.003 sec)
Rows matched: 1  Changed: 1  Inserted: 1  Warnings: 0

MariaDB [tienda]> UPDATE precios SET precio = 99.90 WHERE producto = 'PRD-00017';
Query OK, 1 row affected (0.001 sec)
Rows matched: 1  Changed: 1  Inserted: 1  Warnings: 0

MariaDB [tienda]> SELECT producto, precio FROM precios;
+-----------+--------+
| producto  | precio |
+-----------+--------+
| PRD-00017 |  99.90 |
+-----------+--------+
1 row in set (0.001 sec)

MariaDB [tienda]> SELECT producto, precio FROM precios FOR SYSTEM_TIME AS OF TIMESTAMP @antes;
+-----------+--------+
| producto  | precio |
+-----------+--------+
| PRD-00017 | 129.90 |
+-----------+--------+
1 row in set (0.000 sec)

MariaDB [tienda]> SELECT precio, row_start, row_end FROM precios FOR SYSTEM_TIME ALL ORDER BY row_start;
+--------+----------------------------+----------------------------+
| precio | row_start                  | row_end                    |
+--------+----------------------------+----------------------------+
| 129.90 | 2026-09-27 19:16:10.996004 | 2026-09-27 19:16:12.016177 |
| 119.90 | 2026-09-27 19:16:12.016177 | 2026-09-27 19:16:12.023359 |
|  99.90 | 2026-09-27 19:16:12.023359 | 2106-02-07 06:28:15.999999 |
+--------+----------------------------+----------------------------+
3 rows in set (0.001 sec)

MariaDB [tienda]> DELETE FROM precios WHERE producto = 'PRD-00017';
Query OK, 1 row affected (0.001 sec)

MariaDB [tienda]> SELECT count(*) AS vivas FROM precios;
+-------+
| vivas |
+-------+
|     0 |
+-------+
1 row in set (0.000 sec)

MariaDB [tienda]> SELECT count(*) AS historicas FROM precios FOR SYSTEM_TIME ALL;
+------------+
| historicas |
+------------+
|          3 |
+------------+
1 row in set (0.000 sec)
```

- **`WITH SYSTEM VERSIONING`** añade dos columnas ocultas, `row_start` y `row_end`. Cada `UPDATE`
  cierra la versión vigente e inserta otra: `Inserted: 1` en el resumen de cada uno.
- **`FOR SYSTEM_TIME AS OF`** consulta la tabla como estaba en ese instante: 129,90, el precio
  anterior a los dos cambios. **`FOR SYSTEM_TIME ALL`** enseña todas las versiones; la vigente
  termina en una fecha del año 2106, que es «sin fin».
- **El `DELETE` no borra la historia**: la tabla queda con 0 filas vivas y 3 históricas. Es
  auditoría de valores sin escribir un disparador, y el caso en que un borrado legal obliga a purgar
  la historia aparte.

**Cuánto cuesta**: cada cambio es una fila más para siempre, en la misma tabla o en particiones de
historia, y las consultas normales tienen que saltarse las versiones cerradas. Y el tiempo es el de
la base, no el del negocio: no sirve para «el precio baja el 1 de julio», que es §4.

---

## 6. 🧭 Cómo se elige

| Pregunta del negocio | Mecanismo | Precio |
|---|---|---|
| «Recupera este cliente dado de baja por error» | Borrado lógico | Índices parciales y un filtro en cada consulta |
| «¿Quién cambió este precio y qué había?» | Auditoría con disparadores | El doble de escritura; 2,4 veces el `UPDATE` |
| «¿Qué precio tenía el 15 de marzo, según el negocio?» | Tiempo de la aplicación: clave temporal | Rangos en las consultas; `btree_gist` |
| «¿Cómo estaba esta tabla en la base el día del incidente?» | Tiempo del sistema, donde el motor lo tenga | Cada versión, para siempre |

- **No se mezclan**: la columna `borrado_en` no dice quién borró; la auditoría no contesta rápido el
  precio de una fecha; el tiempo del sistema no sabe de precios futuros.
- **El borrado de verdad sigue haciendo falta**: para datos personales que hay que suprimir, ninguno
  de los tres sirve si no se purga también lo que guardan.

---

## 7. 📜 Estándar, motor y convención

> **📜 Estándar o motor.** Las tablas versionadas por el sistema llegaron con SQL:2011, según la
> documentación de MariaDB; el curso no cita la cláusula, ni la de los periodos de aplicación.
> PostgreSQL 18 implementa las claves temporales y no el versionado por el sistema; MariaDB, el
> versionado. El borrado lógico y la auditoría son convención.

| Afirmación | Categoría | PostgreSQL 18 | MariaDB 12.3 |
|---|---|---|---|
| Una fila marcada como borrada libera su valor único | Motor | No, hasta rehacer el `UNIQUE` como parcial | — |
| Se impiden periodos solapados con una clave | Motor | Sí, `WITHOUT OVERLAPS` con `btree_gist` | — |
| La base guarda cada versión sola | Estándar | No: error de sintaxis | Sí, `WITH SYSTEM VERSIONING` |
| Se consulta la tabla como estaba en un instante | Estándar | — | Sí, `FOR SYSTEM_TIME AS OF` |
| El `DELETE` borra la historia | Motor | — | No: 3 versiones tras el borrado |
| Borrado lógico con índices parciales y vista de activos | Convención | — | — |

**Convención, la que más se repite.** *«Nunca borramos nada, ponemos `borrado = true`»* — y el
primer informe que olvida el filtro cuenta clientes que no existen, el primer registro con un correo
reusado falla, y la petición de borrar datos personales queda sin cumplir.

---

## ⚠️ Errores frecuentes

| Se dice | Lo preciso |
|---|---|
| "El borrado lógico no afecta a las restricciones" | El correo del cliente borrado impidió registrar a otro, hasta el índice parcial |
| "Con `borrado_en` ya tenemos auditoría" | No dice quién ni qué había antes |
| "La auditoría da el historial de precios" | Da los cambios; el precio de una fecha se reconstruye, o se guarda con su vigencia |
| "Dos precios solapados se evitan en la aplicación" | La clave temporal los rechazó en la base |
| "PostgreSQL tiene tablas temporales como MariaDB" | Tiene claves temporales de aplicación; `WITH SYSTEM VERSIONING` dio error de sintaxis |
| "Un `DELETE` en una tabla versionada borra el dato" | Deja 0 filas vivas y 3 versiones históricas |
| "Marcar como borrado cumple con borrar los datos personales" | La fila y su historia siguen guardando los datos |

---

## 📚 Para profundizar

- **Documentación** — PostgreSQL 18, «Partial Indexes»: el índice único parcial.
  <https://www.postgresql.org/docs/18/indexes-partial.html>
- **Documentación** — PostgreSQL 18, «CREATE TABLE»: `WITHOUT OVERLAPS` y las claves temporales.
  <https://www.postgresql.org/docs/18/sql-createtable.html>
- **Documentación** — PostgreSQL 18, «btree_gist».
  <https://www.postgresql.org/docs/18/btree-gist.html>
- **Documentación** — MariaDB, «System-Versioned Tables».
  <https://mariadb.com/docs/server/reference/sql-structure/temporal-tables/system-versioned-tables>

---

## 🧠 Preguntas

1. ¿Qué es el borrado lógico? 🟢
2. ¿Qué diferencia el tiempo de la aplicación del tiempo del sistema? 🟢
3. ¿Qué es una clave temporal en PostgreSQL 18? 🟢
4. ¿Qué hace `FOR SYSTEM_TIME AS OF` en MariaDB? 🟢
5. ¿Por qué el cliente borrado lógicamente impidió registrar a otro con su correo? 🟡
6. ¿Qué hace un índice único parcial, y cómo arregló el problema del correo? ¿Lo fija el estándar o
   es cosa del motor? 🟡
7. ¿Por qué la clave temporal pidió la extensión `btree_gist`? 🟡
8. ¿Qué significa `[2025-01-01,2025-07-01)` como rango de fechas? 🟡
9. Distingue auditoría e historial: qué pregunta contesta cada uno. 🟡
10. ¿Por qué un informe puede contar clientes que no existen con borrado lógico, y cómo se evita? 🟠
11. ¿Por qué el borrado lógico no cumple con una petición de borrar datos personales? 🟠
12. ¿Por qué la auditoría no contesta bien «qué precio tenía el 15 de marzo»? 🟠
13. ¿Por qué el `DELETE` en la tabla versionada dejó 3 filas históricas, y qué implica? ¿Lo fija el
    estándar o es cosa del motor? 🟠
14. ¿Por qué el tiempo del sistema no sirve para un precio que baja el 1 de julio? 🟠
15. ¿Qué cuesta la auditoría con disparadores, con las cifras del curso? 🟠
16. Diseña cómo guardarías los precios de la tienda para contestar el precio de cualquier fecha,
    quién los cambió y cómo estaba la tabla el día de un incidente. 🔴
17. Diagnostica: tras implantar el borrado lógico en clientes, el panel dice que hay más clientes
    activos que nunca y varios clientes no pueden volver a registrarse. 🔴
18. Defiende o refuta «nunca borramos nada: todo lleva `borrado = true`», con lo que enseña el
    capítulo. 🔴

---

**Anterior:** [`03`](03-fechas-zonas-y-dinero.md) — fechas, zonas y dinero · **Siguiente:**
[`05`](05-multi-inquilino.md) — multi-inquilino · **Relacionado:**
[`05/02`](../05-programacion-en-el-motor/02-disparadores.md) — la auditoría con disparadores.
