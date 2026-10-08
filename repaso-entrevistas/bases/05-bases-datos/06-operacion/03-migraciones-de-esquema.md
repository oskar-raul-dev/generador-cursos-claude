# 03 — Migraciones de esquema

> Cómo se cambia el esquema de una base que ya tiene datos, con herramientas que llevan la cuenta de
> qué cambio se aplicó: Flyway, Liquibase, Alembic, golang-migrate, Prisma Migrate. Medido con
> Flyway y Alembic: una base existente que la herramienta se niega a migrar sin línea base, una
> migración editada que ya no pasa la validación, la misma migración fallida que PostgreSQL deshace
> entera y MySQL deja a medias, y un renombrado de columna que Alembic genera como borrado y alta, y
> que se lleva el descuento de un cupón sin un error. **Este capítulo es el dueño de las
> migraciones**, incluidas las que genera un ORM. **Asume leído:**
> [`01`](01-usuarios-roles-y-permisos.md), el rol que migra. **Vigencia:** 27 de septiembre de 2026.

---

## Salto rápido

- [1. El problema](#1--el-problema) · [2. Qué es una herramienta de
  migraciones](#2--qué-es-una-herramienta-de-migraciones)
- [3. Flyway: línea base y la primera migración](#3--flyway-línea-base-y-la-primera-migración) ·
  [4. La migración que no se edita](#4--la-migración-que-no-se-edita)
- [5. La migración que falla a la mitad](#5--la-migración-que-falla-a-la-mitad) · [6. Generadas por
  el ORM](#6--generadas-por-el-orm)
- [7. El mapa de herramientas](#7-️-el-mapa-de-herramientas) · [8. Estándar, motor y
  convención](#8--estándar-motor-y-convención)
- [Errores frecuentes](#️-errores-frecuentes) · [Preguntas](#-preguntas)

---

## 1. 🎯 El problema

La tienda necesita cupones. En el portátil de quien lo programa, basta un `CREATE TABLE`. Pero hay
cuatro bases —desarrollo, pruebas, preproducción y producción—, tres personas cambiando el esquema a
la vez, y un despliegue que tiene que saber **qué cambios le faltan a cada base** y aplicarlos en el
mismo orden en todas.

Sin herramienta, eso es un documento compartido con los `ALTER` pendientes y alguien que se acuerda
de cuáles lanzó. Con herramienta, es una carpeta de ficheros numerados y una tabla en cada base que
dice cuáles se aplicaron. Lo que la herramienta no resuelve, y este capítulo mide, es lo que pasa
cuando una migración se edita después de aplicarla, cuando falla a la mitad, y cuando no la escribe
nadie sino el ORM.

> **📝 Contexto.** Todo se corrió contra la copia aislada `bd-lab-prueba` de
> [`01`](01-usuarios-roles-y-permisos.md), PostgreSQL y MySQL, con Flyway 13.8.0 y Alembic 1.20.0 en
> contenedores efímeros (§4.9 del documento de dominio). **Cada orden de Flyway imprime primero tres
> líneas de cabecera** —la edición, una línea en blanco y el enlace a sus notas de versión— **que se
> omiten** en los bloques; el resto de la salida va entera. **Longitud:** unas 470 líneas; capítulo
> normal que pasa el disparador de 400.

---

## 2. 🧱 Qué es una herramienta de migraciones

**Qué es:** una **migración** es un cambio de esquema numerado —crear una tabla, añadir una columna,
un índice— guardado como fichero junto al código. La herramienta aplica, en orden, las que le faltan
a cada base, y apunta cada una en una **tabla de historial** dentro de la propia base, con su
versión, cuándo se aplicó y una **suma de comprobación** de su contenido.

**Quién lo manda:** nadie. Es **convención** de ingeniería, sin estándar; lo que cada herramienta
puede garantizar depende del **motor** que tiene debajo, como se ve en §5.

Dos familias:

- **Escritas a mano**, en SQL o en el formato de la herramienta: Flyway, Liquibase, golang-migrate.
  Lo que se ejecuta es exactamente lo que alguien escribió y revisó.
- **Generadas por el ORM** comparando los modelos del código con la base: Alembic con
  `--autogenerate`, Prisma Migrate, las de Django o de Hibernate. Rápidas de escribir, y **lo que se
  ejecuta es lo que la herramienta dedujo**, que hay que leer antes de aplicar.

---

## 3. 🧱 Flyway: línea base y la primera migración

Las migraciones de Flyway son ficheros `V<versión>__<descripción>.sql`. Dos, para crear
`cupones_flyway` y un índice:

```sql
-- V1__crear_cupones.sql
CREATE TABLE cupones_flyway (
  codigo    text PRIMARY KEY,
  descuento numeric(5,2) NOT NULL CHECK (descuento > 0)
);
-- V2__indice_descuento.sql
CREATE INDEX cupones_flyway_descuento ON cupones_flyway (descuento);
```

Flyway se ejecuta con un guion, `fw.sh`, que lanza la imagen oficial en la red de la copia:

```bash
docker run --rm --network bd-lab-prueba_default -v "$(dirname "$0")/sql:/flyway/sql:ro" flyway/flyway:13.8.0 \
  -url=jdbc:postgresql://postgres:5432/tienda -user=postgres -password=postgres \
  -locations=filesystem:/flyway/sql "$@"
```

- **`--network bd-lab-prueba_default`** mete el contenedor en la red de la copia, donde el servidor
  se llama `postgres`. **`-v …/sql:/flyway/sql:ro`** monta la carpeta de migraciones, solo lectura.
- **`-url`, `-user` y `-password`** son la conexión JDBC; **`-locations`**, dónde buscar las
  migraciones. **`"$@"`** pasa al final la orden de Flyway que se le dé al guion.

La primera orden, sobre una base que ya tiene las seis tablas de la tienda:

```text
$ ./fw.sh migrate
Database: jdbc:postgresql:******** (PostgreSQL 18.6)
Schema history table "public"."flyway_schema_history" does not exist yet
Successfully validated 2 migrations (execution time 00:00.014s)
ERROR: Found non-empty schema(s) "public" but no schema history table. Use baseline() or set baselineOnMigrate to true to initialize the schema history table.
```

- **Flyway se niega**: el esquema tiene tablas y no hay historial, así que no puede saber qué
  migraciones representan ya esas tablas. Es la situación real de **adoptar migraciones en una base
  que ya existe**.

La corrección es la **línea base**: declarar que lo que hay es la versión 0.

```text
$ ./fw.sh baseline -baselineVersion=0 -baselineDescription=esquema_inicial
Database: jdbc:postgresql:******** (PostgreSQL 18.6)
Creating Schema History table "public"."flyway_schema_history" with baseline ...
Successfully baselined schema with version: 0
$ ./fw.sh migrate
Database: jdbc:postgresql:******** (PostgreSQL 18.6)
Successfully validated 3 migrations (execution time 00:00.021s)
Current version of schema "public": 0
Migrating schema "public" to version "1 - crear cupones"
Migrating schema "public" to version "2 - indice descuento"
Successfully applied 2 migrations to schema "public", now at version v2 (execution time 00:00.010s)
$ ./fw.sh info
Database: jdbc:postgresql:******** (PostgreSQL 18.6)
Schema version: 2
+-----------+---------+------------------+----------+---------------------+----------+----------+
| Category  | Version | Description      | Type     | Installed On        | State    | Undoable |
+-----------+---------+------------------+----------+---------------------+----------+----------+
|           | 0       | esquema_inicial  | BASELINE | 2026-09-27 18:44:58 | Baseline | No       |
| Versioned | 1       | crear cupones    | SQL      | 2026-09-27 18:44:59 | Success  | No       |
| Versioned | 2       | indice descuento | SQL      | 2026-09-27 18:44:59 | Success  | No       |
+-----------+---------+------------------+----------+---------------------+----------+----------+
```

- **`-baselineVersion=0`** a propósito: la línea base por defecto es la versión 1, y con ella Flyway
  habría dado **`V1` por aplicada sin ejecutarla**. `cupones_flyway` no existiría y nadie lo sabría
  hasta usarla.
- **`migrate`** aplica lo que falta en orden; **`info`** lee `flyway_schema_history` y enseña el
  estado de cada una.

---

## 4. 🩺 La migración que no se edita

Alguien añade a `V1`, ya aplicada en todas las bases, un comentario que explica el descuento, y a
la vez escribe `V3`, que añade una caducidad con un error:

```sql
-- V3__caducidad.sql
ALTER TABLE cupones_flyway ADD COLUMN caduca_en date;
ALTER TABLE cupones_flyway ADD CONSTRAINT caducidad_futura CHECK (caduca_en > fecha_alta);
```

```text
$ ./fw.sh migrate
Database: jdbc:postgresql:******** (PostgreSQL 18.6)
ERROR: Validate failed: Migrations have failed validation
Migration checksum mismatch for migration version 1
-> Applied to database : -512497279
-> Resolved locally    : -974417556
Either revert the changes to the migration, or run repair to update the schema history.
Need more flexibility with validation rules? Learn more: https://help.red-gate.com/help/flyway-cli13/help_8.aspx?topic=flyway-blog/older-posts/customize-validation-rules-with-ignoremigrationpatterns
```

- **Un comentario y la validación falla**: la suma de comprobación de `V1` en la base ya no coincide
  con la del fichero. Flyway no ejecuta nada, ni siquiera `V3`.
- **Es lo que se quiere**: una migración aplicada es historia. Si se edita, las bases donde ya
  corrió tienen una versión y las nuevas tendrían otra. Lo que cambia se escribe como **migración
  nueva**.
- **`repair`** actualiza la suma en el historial, y se usa cuando el cambio es de verdad inocuo,
  como este comentario; aquí se deshizo el cambio en el fichero.

---

## 5. 🩺 La migración que falla a la mitad

Con `V1` restaurada, `V3` se ejecuta y falla en su segunda sentencia, porque `fecha_alta` no existe.
**En PostgreSQL**:

```text
$ ./fw.sh migrate
Database: jdbc:postgresql:******** (PostgreSQL 18.6)
Successfully validated 4 migrations (execution time 00:00.016s)
Current version of schema "public": 2
Migrating schema "public" to version "3 - caducidad"
ERROR: Migration of schema "public" to version "3 - caducidad" failed! Changes successfully rolled back.
ERROR: Failed to execute script V3__caducidad.sql
------------------------------------------
SQL State  : 42703
Error Code : 0
Message    : ERROR: column "fecha_alta" does not exist
Location   : /flyway/sql/V3__caducidad.sql (/flyway/sql/V3__caducidad.sql)
Line       : 2
Statement  : Run Flyway with -X option to see the actual statement causing the problem
Caused by: Failed to execute script V3__caducidad.sql
------------------------------------------
SQL State  : 42703
Error Code : 0
Message    : ERROR: column "fecha_alta" does not exist
Location   : /flyway/sql/V3__caducidad.sql (/flyway/sql/V3__caducidad.sql)
Line       : 2
Statement  : Run Flyway with -X option to see the actual statement causing the problem
Caused by: org.postgresql.util.PSQLException: ERROR: column "fecha_alta" does not exist
$ ./fw.sh info
Database: jdbc:postgresql:******** (PostgreSQL 18.6)
Schema version: 2
+-----------+---------+------------------+----------+---------------------+----------+----------+
| Category  | Version | Description      | Type     | Installed On        | State    | Undoable |
+-----------+---------+------------------+----------+---------------------+----------+----------+
|           | 0       | esquema_inicial  | BASELINE | 2026-09-27 18:44:58 | Baseline | No       |
| Versioned | 1       | crear cupones    | SQL      | 2026-09-27 18:44:59 | Success  | No       |
| Versioned | 2       | indice descuento | SQL      | 2026-09-27 18:44:59 | Success  | No       |
| Versioned | 3       | caducidad        | SQL      |                     | Pending  | No       |
+-----------+---------+------------------+----------+---------------------+----------+----------+
```

- **`Changes successfully rolled back`**: Flyway envuelve cada migración en una transacción, dice su
  documentación, y en PostgreSQL **el DDL es transaccional**. El `ADD COLUMN caduca_en` de la
  primera línea se deshizo con el fallo de la segunda: la tabla quedó con `codigo` y `descuento`, lo
  comprobó una consulta a `information_schema.columns`.
- **`V3` sigue `Pending`**: se corrige el fichero y se vuelve a lanzar. Nada que limpiar.

**En MySQL**, las mismas migraciones adaptadas —`VARCHAR` y `DECIMAL`—, con la caducidad como `V2`:

```text
$ ./fwm.sh baseline -baselineVersion=0 -baselineDescription=esquema_inicial
Database: jdbc:mysql:******** (MySQL 9.7)
WARNING: Using MySQL 9.7 which is newer than the version Flyway has been verified with. The latest verified version of MySQL is 9.4.
Creating Schema History table `tienda`.`flyway_schema_history` with baseline ...
Successfully baselined schema with version: 0
$ ./fwm.sh migrate
Database: jdbc:mysql:******** (MySQL 9.7)
WARNING: Using MySQL 9.7 which is newer than the version Flyway has been verified with. The latest verified version of MySQL is 9.4.
Successfully validated 3 migrations (execution time 00:00.023s)
Current version of schema `tienda`: 0
Migrating schema `tienda` to version "1 - crear cupones"
Migrating schema `tienda` to version "2 - caducidad"
ERROR: Migration of schema `tienda` to version "2 - caducidad" failed! Please restore backups and roll back database and code!
ERROR: Failed to execute script V2__caducidad.sql
------------------------------------------
SQL State  : 42S22
Error Code : 1054
Message    : (conn=189) Unknown column 'fecha_alta' in 'check constraint caducidad_futura expression'
Location   : /flyway/sql/V2__caducidad.sql (/flyway/sql/V2__caducidad.sql)
Line       : 2
Statement  : Run Flyway with -X option to see the actual statement causing the problem
Caused by: Failed to execute script V2__caducidad.sql
------------------------------------------
SQL State  : 42S22
Error Code : 1054
Message    : (conn=189) Unknown column 'fecha_alta' in 'check constraint caducidad_futura expression'
Location   : /flyway/sql/V2__caducidad.sql (/flyway/sql/V2__caducidad.sql)
Line       : 2
Statement  : Run Flyway with -X option to see the actual statement causing the problem
Caused by: java.sql.SQLSyntaxErrorException: (conn=189) Unknown column 'fecha_alta' in 'check constraint caducidad_futura expression'
Caused by: org.mariadb.jdbc.internal.util.exceptions.MariaDbSqlException: Unknown column 'fecha_alta' in 'check constraint caducidad_futura expression'
Caused by: java.sql.SQLException: Unknown column 'fecha_alta' in 'check constraint caducidad_futura expression'
$ ./fwm.sh info
Database: jdbc:mysql:******** (MySQL 9.7)
WARNING: Using MySQL 9.7 which is newer than the version Flyway has been verified with. The latest verified version of MySQL is 9.4.
Schema version: 2
+-----------+---------+-----------------+----------+---------------------+----------+----------+
| Category  | Version | Description     | Type     | Installed On        | State    | Undoable |
+-----------+---------+-----------------+----------+---------------------+----------+----------+
|           | 0       | esquema_inicial | BASELINE | 2026-09-27 18:45:35 | Baseline | No       |
| Versioned | 1       | crear cupones   | SQL      | 2026-09-27 18:45:36 | Success  | No       |
| Versioned | 2       | caducidad       | SQL      | 2026-09-27 18:45:36 | Failed   | No       |
+-----------+---------+-----------------+----------+---------------------+----------+----------+
$ docker exec bd-lab-prueba-mysql mysql -uroot -proot tienda -e "SHOW COLUMNS FROM cupones_flyway"
mysql: [Warning] Using a password on the command line interface can be insecure.
Field	Type	Null	Key	Default	Extra
codigo	varchar(20)	NO	PRI	NULL	
descuento	decimal(5,2)	NO		NULL	
caduca_en	date	YES		NULL
```

- **`fwm.sh`** es el mismo guion con la URL de MySQL. El aviso de versión sale en cada orden: Flyway
  13.8.0 solo está verificado hasta MySQL 9.4, y funciona igual.
- **`caduca_en` se quedó**: en MySQL, cada sentencia de DDL **confirma implícitamente** la
  transacción en curso, dice su manual, así que el primer `ALTER` ya estaba confirmado cuando falló
  el segundo. La migración quedó **a medias**.
- **`V2` en estado `Failed`**, y Flyway lo dice sin rodeos: «restaura los respaldos y deshaz la base
  y el código». Arreglar el fichero y relanzar no basta: la columna ya existe, y el `ADD COLUMN`
  fallaría. Hay que deshacer a mano y limpiar el historial con `repair`.

> **⚠️ Advertencia.** En MySQL, **una migración, una sentencia de DDL**. Si una migración tiene
> varias y falla a la mitad, deja la base en un estado que ninguna versión describe. En PostgreSQL
> no hace falta, porque el DDL se deshace con la transacción; salvo lo que no puede ir en una, como
> `CREATE INDEX CONCURRENTLY`, que se verá en [`04`](04-expandir-contraer.md).

---

## 6. 🩺 Generadas por el ORM

Alembic, la herramienta de migraciones de SQLAlchemy, puede **generar** la migración comparando los
modelos con la base. Un modelo `Cupon` con `codigo` y `descuento`, una primera migración generada y
aplicada, un cupón `VERANO` del 15 %, y después **un cambio de nombre en el modelo**: `descuento`
pasa a llamarse `porcentaje`.

```text
$ docker exec bd-lab-prueba-python alembic revision --autogenerate -m crear_cupones
INFO  [alembic.runtime.migration] Context impl PostgresqlImpl.
INFO  [alembic.runtime.migration] Will assume transactional DDL.
INFO  [alembic.runtime.plugins] setting up autogenerate plugin alembic.autogenerate.schemas
INFO  [alembic.runtime.plugins] setting up autogenerate plugin alembic.autogenerate.tables
INFO  [alembic.runtime.plugins] setting up autogenerate plugin alembic.autogenerate.types
INFO  [alembic.runtime.plugins] setting up autogenerate plugin alembic.autogenerate.constraints
INFO  [alembic.runtime.plugins] setting up autogenerate plugin alembic.autogenerate.defaults
INFO  [alembic.runtime.plugins] setting up autogenerate plugin alembic.autogenerate.comments
INFO  [alembic.autogenerate.compare.tables] Detected added table 'cupones_alembic'
Generating /trabajo/migraciones/versions/c22f5f6db321_crear_cupones.py ...  done
$ docker exec bd-lab-prueba-python alembic upgrade head
INFO  [alembic.runtime.migration] Context impl PostgresqlImpl.
INFO  [alembic.runtime.migration] Will assume transactional DDL.
INFO  [alembic.runtime.migration] Running upgrade  -> c22f5f6db321, crear_cupones
$ PGPASSWORD=postgres psql -X -q -h 127.0.0.1 -p 15432 -U postgres -d tienda -c "INSERT INTO cupones_alembic VALUES ('VERANO', 15.00)"
$ sed -i '' 's/descuento: Mapped/porcentaje: Mapped/' modelos.py
$ docker exec bd-lab-prueba-python alembic revision --autogenerate -m renombrar_descuento
INFO  [alembic.runtime.migration] Context impl PostgresqlImpl.
INFO  [alembic.runtime.migration] Will assume transactional DDL.
INFO  [alembic.runtime.plugins] setting up autogenerate plugin alembic.autogenerate.schemas
INFO  [alembic.runtime.plugins] setting up autogenerate plugin alembic.autogenerate.tables
INFO  [alembic.runtime.plugins] setting up autogenerate plugin alembic.autogenerate.types
INFO  [alembic.runtime.plugins] setting up autogenerate plugin alembic.autogenerate.constraints
INFO  [alembic.runtime.plugins] setting up autogenerate plugin alembic.autogenerate.defaults
INFO  [alembic.runtime.plugins] setting up autogenerate plugin alembic.autogenerate.comments
INFO  [alembic.autogenerate.compare.tables] Detected added column 'cupones_alembic.porcentaje'
INFO  [alembic.autogenerate.compare.tables] Detected removed column 'cupones_alembic.descuento'
Generating /trabajo/migraciones/versions/2716e8a85074_renombrar_descuento.py ...  done
$ docker exec bd-lab-prueba-python sh -c 'sed -n "/^def upgrade/,/^def downgrade/p" migraciones/versions/*renombrar_descuento.py'
def upgrade() -> None:
    """Upgrade schema."""
    # ### commands auto generated by Alembic - please adjust! ###
    op.add_column('cupones_alembic', sa.Column('porcentaje', sa.Numeric(precision=5, scale=2), nullable=True))
    op.drop_column('cupones_alembic', 'descuento')
    # ### end Alembic commands ###


def downgrade() -> None:
$ docker exec bd-lab-prueba-python alembic upgrade head
INFO  [alembic.runtime.migration] Context impl PostgresqlImpl.
INFO  [alembic.runtime.migration] Will assume transactional DDL.
INFO  [alembic.runtime.migration] Running upgrade c22f5f6db321 -> 2716e8a85074, renombrar_descuento
$ PGPASSWORD=postgres LC_ALL=es_ES.UTF-8 psql -X -h 127.0.0.1 -p 15432 -U postgres -d tienda -c "SELECT * FROM cupones_alembic"
 codigo | porcentaje 
--------+------------
 VERANO |           
(1 fila)
```

- **`bd-lab-prueba-python`** es un `python:3.14.7` con Alembic instalado y el proyecto montado en
  `/trabajo`; su `env.py` apunta a los modelos y solo compara `cupones_alembic`, para no proponer
  borrar las seis tablas de la tienda, que no están en los modelos.
- **`revision --autogenerate`** compara los modelos con la base y escribe un fichero de migración;
  **`upgrade head`** aplica todas las pendientes. `Will assume transactional DDL` es Alembic
  diciendo que en PostgreSQL puede deshacer una migración fallida, lo mismo que se vio con Flyway.
- **`Detected added column … porcentaje` y `Detected removed column … descuento`**: para Alembic no
  hubo un renombrado, hubo una columna que aparece y otra que desaparece. El fichero generado lo
  dice en dos líneas: `add_column` y `drop_column`. La documentación de Alembic lo advierte con esas
  palabras: la autogeneración **no detecta cambios de nombre de columna**, los detecta como un alta
  y un borrado, «que no es en absoluto lo mismo que un cambio de nombre».
- **Y `VERANO` perdió su 15 %**: la columna nueva nació vacía y la vieja se borró con su dato.
  Ningún error, ningún aviso fuera del comentario «please adjust!» del fichero.

> **Veredicto:** una migración generada es un borrador. Se lee antes de aplicarla, y un renombrado
> se reescribe a mano como `op.alter_column(…, new_column_name=…)` —o como la secuencia de
> [`04`](04-expandir-contraer.md) si la aplicación no puede parar—.

---

## 7. ⚖️ El mapa de herramientas

| Herramienta | Cómo se escriben las migraciones | Lo que la distingue |
|---|---|---|
| **Flyway** | SQL a mano, `V<versión>__<nombre>.sql` | Historial con suma de comprobación; cada migración en una transacción |
| **Liquibase** | *Changelog* en XML, YAML, JSON o SQL, con *changesets* | Independiente del motor si se escribe en su formato, no en SQL |
| **golang-migrate** | Pares de ficheros `up` y `down` en SQL | Una biblioteca y un binario para Go, sin ORM |
| **Alembic** | Python, a mano o generado desde SQLAlchemy | La autogeneración, con lo que no detecta |
| **Prisma Migrate** | Generado desde el esquema de Prisma | La misma familia que Alembic: compara un esquema declarado con la base |

- **Todas llevan una tabla de historial en la base**, y todas dependen de que el motor sepa deshacer
  el DDL para que un fallo no deje la base a medias.
- **Las que generan** ahorran escribir y obligan a leer: el renombrado de §6 es el caso de manual.
- **La reversión** —`down`, `downgrade`, *rollback*— existe en casi todas, y casi nadie la usa en
  producción: deshacer un cambio que ya borró datos no los devuelve. Lo habitual es corregir hacia
  delante con otra migración.

---

## 8. 📜 Estándar, motor y convención

> **📜 Estándar o motor.** No hay estándar de migraciones: es convención. Lo que depende del motor es
> si el DDL es transaccional —PostgreSQL sí, MySQL no, porque cada DDL confirma implícitamente—, y
> eso decide si una migración fallida deja la base limpia.

| Afirmación | Categoría | PostgreSQL 18 | MySQL 9.7 |
|---|---|---|---|
| El DDL se deshace con la transacción | Motor | Sí: `Changes successfully rolled back` | No: `caduca_en` se quedó |
| Una migración fallida se relanza sin limpiar | Motor | Sí, sigue `Pending` | No, queda `Failed` |
| Editar una migración aplicada rompe la validación | Convención | Sí, en Flyway: `checksum mismatch` | Igual |
| Adoptar migraciones en una base existente pide línea base | Convención | Sí | Sí |
| La autogeneración detecta renombrados | Convención | No, en Alembic: alta y borrado | — |
| Una migración, una sentencia de DDL | Convención | No hace falta | Sí |

**Convención, la que más se repite.** *«Las migraciones del ORM son seguras porque las genera la
herramienta»* — las genera a partir de una comparación, y un renombrado se compara como un borrado.
La seguridad está en leerlas y en probarlas contra una copia con datos, como en este capítulo.

---

## ⚠️ Errores frecuentes

| Se dice | Lo preciso |
|---|---|
| "Flyway migra cualquier base" | Con tablas y sin historial se niega; hace falta una línea base |
| "La línea base por defecto está bien" | Es la versión 1, y daría `V1` por aplicada sin ejecutarla |
| "Corregir una errata en una migración aplicada es inocuo" | Un comentario cambió la suma y bloqueó todas las migraciones |
| "Si falla, se corrige y se relanza" | En MySQL quedó a medias y marcada `Failed`: hay que limpiar a mano |
| "El ORM entiende que renombré la columna" | Alembic generó `add_column` y `drop_column`, y el 15 % de `VERANO` se perdió |
| "Tenemos `downgrade`, podemos volver atrás" | Deshacer un borrado de columna no devuelve sus datos |
| "Las migraciones las lanza la aplicación al arrancar" | Las lanza el rol que migra, no el de la aplicación, que no puede crear tablas |

---

## 📚 Para profundizar

- **Documentación** — Flyway, «Migrations»: versionadas, historial y transacciones.
  <https://documentation.red-gate.com/fd/migrations-271585107.html>
- **Documentación** — Alembic, «Auto Generating Migrations»: qué detecta y qué no.
  <https://alembic.sqlalchemy.org/en/latest/autogenerate.html>
- **Documentación** — Liquibase, «What is a changelog?».
  <https://docs.liquibase.com/secure/user-guide-5-2-1/what-is-a-changelog>
- **Documentación** — golang-migrate, el repositorio del proyecto.
  <https://github.com/golang-migrate/migrate>
- **Documentación** — Prisma, «How migrations work».
  <https://www.prisma.io/docs/orm/migrations/how-migrations-work>
- **Documentación** — MySQL 9.7, «Statements That Cause an Implicit Commit».
  <https://dev.mysql.com/doc/refman/9.7/en/implicit-commit.html>
- **Documentación** — PostgreSQL 18, «ALTER TABLE».
  <https://www.postgresql.org/docs/18/sql-altertable.html>

---

## 🧠 Preguntas

1. ¿Qué es una migración de esquema, y qué guarda la tabla de historial? 🟢
2. ¿Qué es la línea base en Flyway? 🟢
3. ¿Qué diferencia una migración escrita a mano de una generada por el ORM? 🟢
4. ¿Qué es el DDL transaccional? 🟢
5. ¿Por qué Flyway se negó a migrar la base de la tienda la primera vez? 🟡
6. ¿Qué hace `repair`, y cuándo está justificado? 🟡
7. Distingue Flyway, Liquibase y golang-migrate en una frase cada uno. 🟡
8. ¿Por qué se usó `-baselineVersion=0` y no la línea base por defecto? 🟡
9. ¿Qué significa el aviso de Flyway sobre MySQL 9.7? 🟡
10. ¿Por qué añadir un comentario a `V1` bloqueó la aplicación de `V3`? ¿Qué parte es del motor y
    qué parte es convención? 🟠
11. ¿Por qué `V3` quedó limpia en PostgreSQL y `V2` a medias en MySQL, con el mismo error? ¿Lo fija
    el estándar o es cosa del motor? 🟠
12. ¿Qué habría que hacer en MySQL para volver a lanzar la migración fallida? 🟠
13. ¿Por qué Alembic generó un borrado y un alta para un renombrado, y qué se perdió? 🟠
14. ¿Por qué casi nadie usa la reversión de migraciones en producción? 🟠
15. ¿Qué regla de escritura de migraciones es obligatoria en MySQL y opcional en PostgreSQL, y por
    qué? 🟠
16. Diseña el flujo de migraciones de la tienda: herramienta, quién las escribe, quién las revisa,
    con qué rol se lanzan y cuándo. 🔴
17. Diagnostica: tras un despliegue, la columna `descuento` de los cupones aparece vacía para todos
    los cupones antiguos, y el equipo solo cambió el nombre del campo en el modelo. 🔴
18. Defiende o refuta dejar que el ORM genere y aplique las migraciones al arrancar la aplicación,
    con lo que enseña el capítulo. 🔴

---

**Anterior:** [`02`](02-respaldos-y-recuperacion.md) — respaldos y recuperación · **Siguiente:**
[`04`](04-expandir-contraer.md) — expandir y contraer · **Relacionado:**
[`11`](../11-orms/README.md) — los ORM, que generan estas migraciones.
