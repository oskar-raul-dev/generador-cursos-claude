# 01 — Usuarios, roles y permisos

> Qué significa de verdad «mínimo privilegio» para la aplicación de la tienda, y dónde se rompe sin
> dar ningún error. Medido en PostgreSQL y MySQL: el rol de la aplicación no puede crear tablas ni
> vaciar `pagos`; una tabla nueva nace sin permisos para nadie; un rol heredado con permisos por
> columna enseña el país de `CLI-00311` y niega su correo; y en MySQL un rol concedido no sirve de
> nada hasta que se activa. **Asume leído:**
> [`10/02`](../10-interfaz-con-los-lenguajes/02-parametrizadas-e-inyeccion.md), donde el privilegio
> de `tienda_app` paró un `DROP TABLE` inyectado. **Vigencia:** 27 de septiembre de 2026.

---

## Salto rápido

- [1. El problema](#1--el-problema) · [2. Roles, `GRANT` y `REVOKE`](#2--roles-grant-y-revoke)
- [3. Lo que la aplicación no puede hacer](#3--lo-que-la-aplicación-no-puede-hacer) · [4. La tabla
  nueva que nace sin permisos](#4--la-tabla-nueva-que-nace-sin-permisos)
- [5. Herencia y permisos por columna](#5--herencia-y-permisos-por-columna) · [6. MySQL: el rol que
  no está activo](#6-️-mysql-el-rol-que-no-está-activo)
- [7. Cómo se elige](#7--cómo-se-elige) · [8. Estándar, motor y
  convención](#8--estándar-motor-y-convención)
- [Errores frecuentes](#️-errores-frecuentes) · [Preguntas](#-preguntas)

---

## 1. 🎯 El problema

La forma más rápida de conectar una aplicación a PostgreSQL es con el usuario `postgres`. Funciona
siempre, porque puede con todo. Y por eso mismo, cuando algo sale mal —una inyección, un script de
limpieza con el `WHERE` equivocado, una migración lanzada contra la base que no era—, no hay nada
que lo pare.

En [`10/02`](../10-interfaz-con-los-lenguajes/02-parametrizadas-e-inyeccion.md) se vio el caso
bueno: un `DROP TABLE pagos` inyectado llegó al motor y lo paró el privilegio de `tienda_app`. Este
capítulo enseña cómo se construye ese privilegio y las tres formas de romperlo sin que nadie se
entere: la tabla nueva que la aplicación no puede leer, el rol que parece concedido y no lo está, y
el permiso heredado que da más de lo que se quería.

> **📝 Contexto.** Todo se corrió en la copia aislada `bd-lab-prueba` de
> [`05/01`](../05-programacion-en-el-motor/01-funciones-y-procedimientos.md), porque las sesiones
> crean roles y tablas; el entorno principal no se tocó. Los tres roles del dominio —`tienda_app`,
> `tienda_ro` y `tienda_admin`— los crea `esquema.sql`; las sesiones cambian de rol con `SET ROLE`
> desde el superusuario, que es como se prueba lo que puede cada uno sin cambiar de conexión. El
> MySQL es el vacío de la misma copia. **Longitud:** unas 380 líneas; capítulo normal.

---

## 2. 🧱 Roles, `GRANT` y `REVOKE`

**Qué es:** en PostgreSQL, un **rol** es a la vez usuario y grupo: con `LOGIN` puede conectarse, y
cualquier rol puede ser miembro de otro. Los **privilegios** se dan con `GRANT` y se quitan con
`REVOKE`, sobre un objeto concreto —una tabla, una columna, un esquema, una secuencia—, y cada tipo
de objeto tiene los suyos: `SELECT`, `INSERT`, `UPDATE`, `DELETE`, `TRUNCATE`, `USAGE`, `CREATE`…

**Quién lo manda:** `GRANT` y `REVOKE` están en el **estándar**; los roles, también. Lo que cambia
es el **motor**: en PostgreSQL el dueño de un objeto tiene todos sus privilegios y nadie más tiene
ninguno hasta que se le dan; en MySQL las cuentas son `usuario@host` y los roles, desde la versión
8, hay que activarlos. **SQLite no tiene ni usuarios ni `GRANT`**: su documentación dice que, como
lee y escribe un fichero, los únicos permisos posibles son los del sistema operativo sobre ese
fichero.

Los tres roles del dominio, tal como los deja `esquema.sql`:

| Rol | Qué puede | Para quién |
|---|---|---|
| `tienda_app` | `SELECT`, `INSERT`, `UPDATE`, `DELETE` en las tablas; usar las secuencias | La aplicación |
| `tienda_ro` | `SELECT` | Informes, réplicas de consulta, analistas |
| `tienda_admin` | Todo en las tablas, y `CREATE` en el esquema | Migraciones y el DBA |

> **Veredicto:** mínimo privilegio no es un rol «con pocos permisos», es un rol por función, con los
> permisos exactos de esa función, y el de las migraciones separado del de la aplicación.

---

## 3. 🧱 Lo que la aplicación no puede hacer

```text
tienda=# SET ROLE tienda_app;
SET
tienda=> CREATE TABLE cupones (codigo text PRIMARY KEY);
ERROR:  permission denied for schema public
LÍNEA 1: CREATE TABLE cupones (codigo text PRIMARY KEY);
                      ^
tienda=> DELETE FROM pagos WHERE false;
DELETE 0
tienda=> TRUNCATE pagos;
ERROR:  permission denied for table pagos
tienda=> RESET ROLE;
RESET
```

- **`SET ROLE tienda_app`** hace que la sesión actúe con los privilegios de ese rol. El *prompt*
  pasa de `tienda=#` a `tienda=>`: el `#` es de superusuario. `RESET ROLE` vuelve al rol de la
  conexión.
- **No puede crear tablas**: no tiene `CREATE` en el esquema `public`. La documentación de esquemas
  dice que desde PostgreSQL 15 la configuración por defecto ya no da ese permiso a todo el mundo; en
  bases creadas antes y actualizadas, hay que quitarlo a mano.
- **Puede borrar filas, pero no vaciar la tabla**: `DELETE` está concedido y `TRUNCATE` no.
  `TRUNCATE` es un privilegio aparte, y más peligroso: vacía la tabla de golpe, sin pasar por los
  disparadores de fila.
- **`DELETE … WHERE false`** comprueba el permiso sin tocar nada: devuelve `DELETE 0`.

**Cuánto cuesta**: tener dos roles —el de la aplicación y el de las migraciones— obliga a que las
migraciones corran con otras credenciales que la aplicación, que es exactamente lo que se quiere.

---

## 4. 🩺 La tabla nueva que nace sin permisos

Una migración crea `cupones`, con el rol que las lanza. La aplicación, al día siguiente:

```text
tienda=# CREATE TABLE cupones (codigo text PRIMARY KEY, descuento numeric(5,2) NOT NULL);
CREATE TABLE
tienda=# SET ROLE tienda_app;
SET
tienda=> SELECT count(*) FROM cupones;
ERROR:  permission denied for table cupones
tienda=> RESET ROLE;
RESET
tienda=# ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA public GRANT SELECT, INSERT, UPDATE, DELETE ON TABLES TO tienda_app;
ALTER DEFAULT PRIVILEGES
tienda=# CREATE TABLE devoluciones (pedido_id bigint PRIMARY KEY REFERENCES pedidos (id), motivo text NOT NULL);
CREATE TABLE
tienda=# SET ROLE tienda_app;
SET
tienda=> SELECT count(*) FROM devoluciones;
 count 
-------
     0
(1 fila)

tienda=> RESET ROLE;
RESET
```

- **`GRANT … ON ALL TABLES IN SCHEMA public`**, que es lo que hace `esquema.sql`, da permisos sobre
  las tablas **que existen en ese momento**. `cupones` se creó después y nadie más que su dueño
  puede leerla.
- **`ALTER DEFAULT PRIVILEGES FOR ROLE postgres`** fija los permisos que tendrán las tablas **que
  cree ese rol en adelante**. La documentación lo dice: no afecta a los objetos que ya existen. Por
  eso `devoluciones` nació legible y `cupones` sigue sin serlo.
- **`FOR ROLE`** importa: los privilegios por defecto son del rol que crea el objeto. Si las
  migraciones corren con `tienda_admin`, es `FOR ROLE tienda_admin`.

> **⚠️ Advertencia.** Es el fallo de permisos más común tras una migración, y aparece en producción
> con el primer usuario que toca la tabla nueva. Se evita declarando los privilegios por defecto una
> vez, para el rol que migra, o concediendo los permisos en la propia migración que crea la tabla.

---

## 5. 🧱 Herencia y permisos por columna

**Qué es:** un rol puede ser **miembro** de otro, y con la opción `INHERIT` —la de defecto— usa sus
privilegios sin más. Y un privilegio puede darse **por columna**: `SELECT (id, codigo)` y no la
tabla entera.

El analista entra como miembro de `tienda_ro`, que deja de ver el correo de los clientes:

```text
tienda=# CREATE ROLE analista LOGIN PASSWORD 'analista' IN ROLE tienda_ro;
CREATE ROLE
tienda=# REVOKE SELECT ON clientes FROM tienda_ro;
REVOKE
tienda=# GRANT SELECT (id, codigo, pais) ON clientes TO tienda_ro;
GRANT
tienda=# SET ROLE analista;
SET
tienda=> SELECT codigo, pais FROM clientes WHERE codigo = 'CLI-00311';
  codigo   | pais 
-----------+------
 CLI-00311 | ES
(1 fila)

tienda=> SELECT email FROM clientes WHERE codigo = 'CLI-00311';
ERROR:  permission denied for table clientes
tienda=> RESET ROLE;
RESET
tienda=# \dp clientes
                                                Privilegios
 Esquema |  Nombre  | Tipo  |          Privilegios           | Privilegios de acceso a columnas | Políticas 
---------+----------+-------+--------------------------------+----------------------------------+-----------
 public  | clientes | tabla | postgres=arwdDxtm/postgres    +| id:                             +| 
         |          |       | tienda_app=arwd/postgres      +|   tienda_ro=r/postgres          +| 
         |          |       | tienda_admin=arwdDxtm/postgres | codigo:                         +| 
         |          |       |                                |   tienda_ro=r/postgres          +| 
         |          |       |                                | pais:                           +| 
         |          |       |                                |   tienda_ro=r/postgres           | 
(1 fila)
```

- **`IN ROLE tienda_ro`** crea al analista ya como miembro de `tienda_ro`, y hereda sus permisos: no
  hizo falta darle nada a él.
- **El `REVOKE` y el `GRANT` por columna son a `tienda_ro`**, no al analista: cambiar el grupo
  cambia a todos sus miembros a la vez. Es la razón de conceder a roles de grupo y no a personas.
- **`\dp`** enseña la lista de permisos: cada letra es un privilegio —`r` lectura, `a` inserción,
  `w` actualización, `d` borrado, `D` vaciado, `x` referencias, `t` disparador, `m` mantenimiento—,
  y tras la barra, quién lo concedió. `tienda_ro` ya no aparece en la tabla, solo en tres columnas.
- **El error no dice qué columna**: dice la tabla. Quien depura tiene que saber que existen permisos
  por columna.

**Cuánto cuesta**: con permisos por columna, un `SELECT *` del analista falla, porque pide columnas
que no puede ver. Para ocultar filas, no columnas, hace falta seguridad a nivel de fila, que es
asunto del bloque 12.

---

## 6. ⚖️ MySQL: el rol que no está activo

MySQL tiene roles desde la versión 8, con una diferencia que se pregunta: **un rol concedido no está
activo** hasta que se activa en la sesión o se declara como rol por defecto.

```text
mysql> CREATE TABLE precios (producto CHAR(9) PRIMARY KEY, precio DECIMAL(12,2) NOT NULL);
Query OK, 0 rows affected (0.013 sec)

mysql> INSERT INTO precios VALUES ('PRD-00017', 129.90);
Query OK, 1 row affected (0.005 sec)

mysql> CREATE ROLE lectura;
Query OK, 0 rows affected (0.007 sec)

mysql> GRANT SELECT ON tienda.* TO lectura;
Query OK, 0 rows affected (0.003 sec)

mysql> CREATE USER analista IDENTIFIED BY 'analista';
Query OK, 0 rows affected (0.005 sec)

mysql> GRANT lectura TO analista;
Query OK, 0 rows affected (0.009 sec)
```

El analista intenta entrar con la base `tienda` como base por defecto:

```bash
docker exec bd-lab-prueba-mysql mysql -uanalista -panalista tienda -e "SELECT 1"
```

```text
mysql: [Warning] Using a password on the command line interface can be insecure.
ERROR 1044 (42000): Access denied for user 'analista'@'%' to database 'tienda'
```

Y conectado sin base por defecto:

```text
mysql> SELECT CURRENT_ROLE();
+----------------+
| CURRENT_ROLE() |
+----------------+
| NONE           |
+----------------+
1 row in set (0.000 sec)

mysql> SELECT * FROM tienda.precios;
ERROR 1142 (42000): SELECT command denied to user 'analista'@'localhost' for table 'precios'
mysql> SET ROLE lectura;
Query OK, 0 rows affected (0.000 sec)

mysql> SELECT * FROM tienda.precios;
+-----------+--------+
| producto  | precio |
+-----------+--------+
| PRD-00017 | 129.90 |
+-----------+--------+
1 row in set (0.001 sec)
```

- **`ERROR 1044` al entrar**: con el rol sin activar, el analista no tiene ningún permiso sobre
  `tienda`, ni siquiera para elegirla como base.
- **`CURRENT_ROLE()` da `NONE`** aunque el `GRANT lectura TO analista` se hizo. El `SELECT` falla
  con `ERROR 1142`, y tras `SET ROLE lectura`, funciona.
- **La corrección permanente** es `SET DEFAULT ROLE lectura TO analista`, o la variable
  `activate_all_roles_on_login`, que el manual describe junto a `mandatory_roles` para activar los
  roles al conectar.
- **`'analista'@'%'` y `'analista'@'localhost'`** son como MySQL nombra la cuenta: usuario y
  máquina de origen. El `CREATE USER` sin host crea la de `%`, cualquier máquina.

> **Veredicto:** en PostgreSQL, ser miembro de un rol basta; en MySQL, además hay que activarlo. Un
> `GRANT` que funciona en uno y «no hace nada» en el otro es casi siempre esto.

---

## 7. 🧭 Cómo se elige

- **Un rol por función, no por persona**: aplicación, solo lectura, migraciones. Las personas son
  miembros de los roles de función, y quitar a alguien es quitarlo del grupo.
- **La aplicación nunca con el superusuario ni con el dueño de las tablas**: sin `CREATE`, sin
  `TRUNCATE`, sin `DROP`. Es lo que paró el `DROP TABLE` de `10/02`.
- **Las migraciones con su propio rol**, que es el dueño de las tablas, y con **privilegios por
  defecto** declarados para él, para que cada tabla nueva nazca con los permisos de la aplicación.
- **Los datos sensibles, por columna o fuera**: el correo de los clientes no lo necesita un informe
  de ventas.

**Cuánto cuesta**: más roles y más credenciales que gestionar, y migraciones que fallan si alguien
olvida los privilegios por defecto. Es el precio de que un error no pueda borrar una tabla.

---

## 8. 📜 Estándar, motor y convención

> **📜 Estándar o motor.** `GRANT`, `REVOKE` y los roles están en el estándar; no he verificado la
> cláusula. Los privilegios por defecto, `TRUNCATE` como privilegio y el esquema `public` sin
> `CREATE` son de PostgreSQL; la activación de roles es de MySQL.

| Afirmación | Categoría | PostgreSQL 18 | MySQL 9.7 | SQLite 3.53 |
|---|---|---|---|---|
| Hay usuarios, roles y `GRANT` | Estándar | Sí | Sí | No: permisos del fichero |
| Un rol concedido se usa sin activarlo | Motor | Sí, con `INHERIT` | No: `CURRENT_ROLE()` = `NONE` | — |
| Los permisos llegan a las tablas nuevas | Motor | Solo con `ALTER DEFAULT PRIVILEGES` | — | — |
| Hay permisos por columna | Estándar | Sí | Sí | — |
| Cualquiera puede crear en el esquema por defecto | Motor | No, desde la 15 | — | — |
| `TRUNCATE` es un privilegio aparte de `DELETE` | Motor | Sí | — | — |
| Un rol por función, no por persona | Convención | — | — | — |

**Convención, la que más se repite.** *«En desarrollo, con `postgres` va bien»* — y la aplicación
llega a producción con el mismo usuario. Los permisos se prueban en desarrollo con el rol de
producción, o el primer fallo de permisos aparece en producción.

---

## ⚠️ Errores frecuentes

| Se dice | Lo preciso |
|---|---|
| "`GRANT ON ALL TABLES` cubre las tablas futuras" | Solo las que existen; `cupones` nació sin permisos para la aplicación |
| "Con `DELETE` ya puede vaciar la tabla" | `TRUNCATE` es otro privilegio, y `tienda_app` no lo tiene |
| "Si le concedí el rol, ya puede" | En MySQL, `CURRENT_ROLE()` dio `NONE` hasta `SET ROLE` |
| "Los permisos se dan a cada persona" | Se dan al rol de grupo: el `REVOKE` a `tienda_ro` afectó al analista |
| "El error dice qué columna falta" | Dice la tabla: «permission denied for table clientes» |
| "SQLite tiene usuarios como los demás" | No tiene `GRANT`: solo los permisos del fichero |
| "La aplicación necesita crear tablas" | Eso es de las migraciones, con otro rol |

---

## 📚 Para profundizar

- **Documentación** — PostgreSQL 18, «Privileges»: los privilegios de cada objeto.
  <https://www.postgresql.org/docs/18/ddl-priv.html>
- **Documentación** — PostgreSQL 18, «ALTER DEFAULT PRIVILEGES».
  <https://www.postgresql.org/docs/18/sql-alterdefaultprivileges.html>
- **Documentación** — PostgreSQL 18, «Role Membership»: miembros e `INHERIT`.
  <https://www.postgresql.org/docs/18/role-membership.html>
- **Documentación** — PostgreSQL 18, «Schemas»: el esquema `public` desde la 15.
  <https://www.postgresql.org/docs/18/ddl-schemas.html>
- **Documentación** — PostgreSQL 18, «GRANT». <https://www.postgresql.org/docs/18/sql-grant.html>
- **Documentación** — MySQL 9.7, «Using Roles»: activación y roles por defecto.
  <https://dev.mysql.com/doc/refman/9.7/en/roles.html>
- **Documentación** — SQLite, «SQL Features That SQLite Does Not Implement»: `GRANT` y `REVOKE`.
  <https://www.sqlite.org/omitted.html>

---

## 🧠 Preguntas

1. ¿Qué es un rol en PostgreSQL, y en qué se diferencia de un usuario? 🟢
2. ¿Qué hacen `GRANT` y `REVOKE`? 🟢
3. ¿Qué indica el `#` o el `>` al final del *prompt* de `psql`? 🟢
4. ¿Qué tiene SQLite en lugar de usuarios y permisos? 🟢
5. Distingue los privilegios `DELETE` y `TRUNCATE`. ¿Lo fija el estándar o es cosa del motor? 🟡
6. ¿Qué significan las letras `arwd` de `\dp`? ¿Lo fija el estándar o es cosa del motor? 🟡
7. ¿Qué cambió en PostgreSQL 15 con el esquema `public`? 🟡
8. ¿Qué hace `SET ROLE`, y por qué sirve para probar permisos? 🟡
9. ¿Por qué conviene dar los permisos al rol de grupo y no a cada persona? 🟡
10. ¿Por qué `tienda_app` no pudo leer `cupones`, si tenía `SELECT` en todas las tablas? 🟠
11. ¿Qué hace `ALTER DEFAULT PRIVILEGES`, y por qué importa el `FOR ROLE`? 🟠
12. ¿Por qué el analista pudo ver el país de `CLI-00311` y no su correo, si nadie le dio permisos a
    él? 🟠
13. ¿Por qué en MySQL el analista no pudo ni elegir la base, si tenía el rol concedido? 🟠
14. ¿Qué pasa con un `SELECT *` cuando hay permisos por columna? 🟠
15. ¿Por qué la aplicación no debe conectarse con el superusuario, aunque todo funcione? 🟠
16. Diseña los roles de la tienda para la aplicación, las migraciones, los informes y dos personas
    del equipo de datos. 🔴
17. Diagnostica: tras el despliegue de una migración que añade la tabla `cupones`, la aplicación
    falla con «permission denied» solo en las pantallas de cupones. 🔴
18. Defiende o refuta dar a la aplicación el rol `tienda_admin` «para no tener problemas con las
    migraciones», con lo que enseña el capítulo. 🔴

---

**Anterior:** [README del bloque](README.md) · **Siguiente:**
[`02`](02-respaldos-y-recuperacion.md) — respaldos y recuperación · **Relacionado:**
[`10/02`](../10-interfaz-con-los-lenguajes/02-parametrizadas-e-inyeccion.md) — la inyección que paró
el privilegio.
