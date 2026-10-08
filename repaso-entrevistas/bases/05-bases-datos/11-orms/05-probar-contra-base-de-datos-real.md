# 05 — Probar contra una base de datos real

> Por qué una prueba contra una base en memoria puede pasar y el mismo código fallar en producción:
> cinco comprobaciones sobre tres pedidos, corridas contra H2 —también en su modo PostgreSQL—,
> contra SQLite en memoria desde tres lenguajes y contra PostgreSQL 18.6. **La base en memoria
> miente en dos de cinco en el mejor caso, y en cuatro en el peor.** Después, Testcontainers en los
> cuatro lenguajes: el motor de producción, desechable, en unos dos segundos. **Asume leído:**
> [`10/05`](../10-interfaz-con-los-lenguajes/05-java.md) §7 —H2 y Derby— y §6 —la propagación—, y el
> orden de los nulos de
> [`01/06`](../01-fundamentos-y-modelo-relacional/06-nulos-y-logica-de-tres-valores.md) §5.
> **Vigencia:** 24 de septiembre de 2026.

---

## Salto rápido

- [1. El problema](#1--el-problema) · [2. La mentira, reproducida](#2--la-mentira-reproducida)
- [3. Por qué miente cada una](#3--por-qué-miente-cada-una) ·
  [4. Testcontainers](#4--testcontainers)
- [5. Desde dentro de un contenedor](#5--desde-dentro-de-un-contenedor) ·
  [6. Cómo se organiza una suite](#6--cómo-se-organiza-una-suite)
- [7. Estándar, motor y convención](#7--estándar-motor-y-convención) ·
  [Errores frecuentes](#️-errores-frecuentes) · [Preguntas](#-preguntas)

---

## 1. 🎯 El problema

La integración continua está en verde y producción enseña esto:

```text
El panel dice que el último pedido actualizado es uno que nunca se actualizó.
La suma de un informe de prueba sale 0.30000000000000004.
Un proceso deja líneas de pedido que apuntan a pedidos que no existen, y ninguna prueba lo vio.
```

Las pruebas pasaban. Pasaban **contra otra base de datos**: una en memoria, rápida, sin instalar
nada, que acepta casi el mismo SQL y se comporta casi igual. Ese «casi» es este capítulo.

> **📝 Contexto.** Todo está **corrido**. La base en memoria es H2 2.5.250 en Java y SQLite en
> Python —su `sqlite3`—, en TypeScript —el módulo `node:sqlite`— y en Go —`modernc.org/sqlite`
> 1.59.0, SQLite escrito en Go—. PostgreSQL lo arranca Testcontainers —2.0.5 en Java, 4.15.0 en
> Python, 12.1.0 en Node y 0.44.0 en Go— con la imagen `postgres:18.6` del corpus, en un contenedor
> que se crea y se borra en cada ejecución: **la base `tienda` no se toca**. Cómo se corre
> Testcontainers desde los contenedores de lenguaje está en §5. **No se corre** la organización de
> una suite de §6, que depende del marco de pruebas de cada lenguaje: se explica por mecanismo.
> **Longitud:** unas 400 líneas; capítulo normal.

---

## 2. 🩺 La mentira, reproducida

**Qué es:** un esquema mínimo y tres pedidos, el tercero sin fecha de actualización:

```sql
CREATE TABLE pedidos (id bigint PRIMARY KEY, codigo varchar(20) NOT NULL UNIQUE, estado varchar(20) NOT NULL, total numeric(12,2) NOT NULL, actualizado_en timestamp);
CREATE TABLE pedido_lineas (pedido_id bigint NOT NULL REFERENCES pedidos (id), linea int NOT NULL, PRIMARY KEY (pedido_id, linea));
INSERT INTO pedidos VALUES (1, 'PED-00001', 'PAGADO', 0.10, '2025-01-01 10:00'), (2, 'PED-00002', 'ENVIADO', 0.20, '2025-02-01 10:00'), (3, 'PED-00003', 'PAGADO', 0.00, NULL);
```

Y cinco sentencias que una suite de pruebas podría ejecutar, iguales en todos los motores:

```sql
SELECT codigo FROM pedidos ORDER BY actualizado_en DESC LIMIT 1;             -- 1. el último actualizado
SELECT sum(total) FROM pedidos;                                              -- 2. la suma de totales
INSERT INTO pedido_lineas VALUES (99, 1);                                    -- 3. una línea huérfana
SELECT count(*) FROM pedidos WHERE codigo LIKE 'ped-%';                      -- 4. LIKE en minúsculas
INSERT INTO pedidos VALUES (1, 'PED-00001', 'ENVIADO', 0.10, NULL)
  ON CONFLICT (id) DO UPDATE SET estado = excluded.estado;                   -- 5. el upsert de 02/07
```

Java, contra H2 en sus dos modos y contra PostgreSQL:

```text
== H2 en memoria
1 último actualizado  -> PED-00002
2 suma de totales     -> 0.30
3 línea huérfana      -> ERROR Referential integrity constraint violation: "CONSTRAINT_6: PUBLIC.PEDIDO_LINEAS FORE…
4 LIKE 'ped-%'        -> 0
5 upsert              -> ERROR Syntax error in SQL statement "INSERT INTO pedidos VALUES (1, 'PED-00001', 'ENVIADO'…
== H2 con MODE=PostgreSQL
1 último actualizado  -> PED-00002
2 suma de totales     -> 0.30
3 línea huérfana      -> ERROR Referential integrity constraint violation: "CONSTRAINT_6: PUBLIC.PEDIDO_LINEAS FORE…
4 LIKE 'ped-%'        -> 0
5 upsert              -> ERROR Syntax error in SQL statement "INSERT INTO pedidos VALUES (1, 'PED-00001', 'ENVIADO'…
(contenedor listo en 2174 ms)
== PostgreSQL 18.6 con Testcontainers
1 último actualizado  -> PED-00003
2 suma de totales     -> 0.30
3 línea huérfana      -> ERROR ERROR: insert or update on table "pedido_lineas" violates foreign key constraint "pe…
4 LIKE 'ped-%'        -> 0
5 upsert              -> aceptada, filas: 1
```

SQLite en memoria, desde los otros tres lenguajes:

```text
== SQLite 3.46.1 en memoria                                     -- Python, sqlite3
1 último actualizado  -> PED-00002
2 suma de totales     -> 0.30000000000000004
3 línea huérfana      -> aceptada, filas: 1
4 LIKE 'ped-%'        -> 3
5 upsert              -> aceptada, filas: 1
== SQLite 3.53.4 en memoria (node:sqlite)                        -- TypeScript
1 último actualizado  -> PED-00002
2 suma de totales     -> 0.30000000000000004
3 línea huérfana      -> ERROR FOREIGN KEY constraint failed
4 LIKE 'ped-%'        -> 3
5 upsert              -> aceptada, filas: 1
== SQLite 3.53.4 en memoria (modernc.org/sqlite)                 -- Go
1 último actualizado  -> PED-00002
2 suma de totales     -> 0.30000000000000004
3 línea huérfana      -> aceptada, filas: 1
4 LIKE 'ped-%'        -> 3
5 upsert              -> aceptada, filas: 1
```

Contra PostgreSQL, los cuatro lenguajes dieron las cinco líneas de Java. Solo cambia el texto del
error: pgjdbc y pgx lo empiezan con `ERROR:`, detrás del `ERROR` que antepone el programa, y
psycopg y `pg` no.

| Comprobación | PostgreSQL 18.6 | H2 | H2, modo PostgreSQL | SQLite, Python y Go | SQLite, `node:sqlite` |
|---|---|---|---|---|---|
| 1. Último actualizado | `PED-00003` | **`PED-00002`** | **`PED-00002`** | **`PED-00002`** | **`PED-00002`** |
| 2. Suma de totales | `0.30` | `0.30` | `0.30` | **`0.30000000000000004`** | **`0.30000000000000004`** |
| 3. Línea huérfana | Rechazada | Rechazada | Rechazada | **Aceptada** | Rechazada |
| 4. `LIKE 'ped-%'` | 0 | 0 | 0 | **3** | **3** |
| 5. `ON CONFLICT … DO UPDATE` | Aceptada | **Error de sintaxis** | **Error de sintaxis** | Aceptada | Aceptada |

- **H2 miente en dos de cinco y SQLite en tres o cuatro**, según la biblioteca que lo abra. Ninguna
  da un aviso: todas responden algo razonable.
- **El modo PostgreSQL de H2 no cambió nada** en estas cinco: ni el orden de los nulos ni la
  sintaxis del upsert. Un modo de compatibilidad imita partes de otro motor; cuáles, hay que
  comprobarlo.
- **La primera es la peor**: no falla, devuelve otro pedido. Una prueba que espere `PED-00002` pasa
  en las cuatro bases en memoria y en producción el panel enseña `PED-00003`, el que nunca se
  actualizó.

> **Veredicto:** una prueba verde contra una base en memoria demuestra que el código funciona
> **contra esa base**. Contra PostgreSQL, no demuestra nada.

---

## 3. 🧱 Por qué miente cada una

Las cinco diferencias tienen una causa concreta, y ninguna es un fallo del motor:

- **1. Los nulos al ordenar.** PostgreSQL trata el nulo como mayor que cualquier valor: va al final
  en `ASC` y **al principio en `DESC`**. H2 y SQLite lo tratan como menor. Es la divergencia de
  [`01/06`](../01-fundamentos-y-modelo-relacional/06-nulos-y-logica-de-tres-valores.md) §5, y se
  cierra escribiendo `NULLS LAST`, que no depende del motor.
- **2. El dinero.** En SQLite, `numeric(12,2)` no es un tipo: es una **afinidad**, y un `0.10`
  literal se guarda como `REAL`, coma flotante binaria. La suma es la de `0.1 + 0.2` en cualquier
  lenguaje. PostgreSQL y H2 guardan decimales exactos.
- **3. Las claves foráneas.** SQLite las trae **desactivadas por defecto** —su documentación lo dice
  así— y se activan por conexión con `PRAGMA foreign_keys = ON`. `sqlite3` de Python y
  `modernc.org/sqlite` las dejan como vienen; `node:sqlite` las activa, con
  `enableForeignKeyConstraints` a `true` por defecto. **El mismo motor miente distinto según quién
  lo abra.**
- **4. `LIKE`.** En SQLite no distingue mayúsculas de minúsculas en ASCII; en PostgreSQL y H2, sí.
  Una búsqueda que en pruebas encuentra tres pedidos en producción no encuentra ninguno.
- **5. El upsert.** H2 no entiende `ON CONFLICT … DO UPDATE` ni en modo PostgreSQL. Corrido aparte,
  su modo PostgreSQL acepta `ON CONFLICT DO NOTHING` y rechaza el `DO UPDATE` con la marca en el
  sitio exacto:

```text
Syntax error in SQL statement "INSERT INTO pedidos VALUES (1, 'ENVIADO') [*]ON CONFLICT (id) DO UPDATE SET estado = excluded.estado"; SQL statement:
filas: 0
```

- **La consecuencia del quinto es la más cara**: un equipo que prueba contra H2 deja de escribir el
  `INSERT … ON CONFLICT` de [`02/07`](../02-sql/07-escritura-upsert-y-vistas.md) §4 porque las
  pruebas no lo aceptan, y escribe un «leer y después insertar o actualizar» que tiene la carrera
  que el upsert evitaba. **La base de pruebas acaba decidiendo el SQL de producción.** Escribir
  portable tiene su sitio, que es el de [`02/08`](../02-sql/08-dialectos.md) §5; hacerlo para que
  pase H2 no es ese sitio.

**Quién lo manda:** cada **motor**, y en SQLite también **la biblioteca** que lo abre. **Cuánto
cuesta:** fallos que solo aparecen en producción, y SQL de producción rebajado para que pasen las
pruebas. **Cuándo sí:** la base en memoria sirve para probar lógica que no depende del motor, que en
el acceso a datos es casi ninguna.

---

## 4. 🧱 Testcontainers

**Qué es:** una biblioteca que, desde el propio programa de pruebas, **arranca un contenedor de
Docker** con el motor de producción, espera a que acepte conexiones, entrega la URL con un puerto
libre elegido al azar y lo borra al terminar. Existe para los cuatro lenguajes, con la misma idea y
casi los mismos nombres:

```java
try (var pg = new PostgreSQLContainer("postgres:18.6")) {      // Java: org.testcontainers.postgresql
    pg.start();
    DriverManager.getConnection(pg.getJdbcUrl(), pg.getUsername(), pg.getPassword());
```

```python
with PostgresContainer("postgres:18.6", driver=None) as pg:   # Python: testcontainers.community.postgres
    psycopg.connect(pg.get_connection_url(), autocommit=True)
```

```ts
const pgc = await new PostgreSqlContainer("postgres:18.6").start();   // TypeScript: @testcontainers/postgresql
new pg.Client({ connectionString: pgc.getConnectionUri() });
```

```go
pg, err := postgres.Run(ctx, "postgres:18.6", postgres.BasicWaitStrategies()) // Go: modules/postgres
defer testcontainers.TerminateContainer(pg)
url, _ := pg.ConnectionString(ctx, "sslmode=disable")
```

- **La imagen es la de producción, con su versión exacta**: `postgres:18.6`, la misma del `compose`
  del corpus. Con `latest` la prueba correría contra la versión que tocara ese día.
- **Esperar a que esté lista no es trivial**, y cada módulo lo resuelve. El de Go lo dice en su
  código: espera **dos veces** la línea `database system is ready to accept connections`, porque la
  imagen oficial arranca un servidor para inicializar la base, lo para y arranca el definitivo; y
  después espera a que el puerto responda.
- **El arranque, medido**, con la imagen ya descargada:

| Lenguaje | Contenedor listo |
|---|---|
| Java | 2 174 ms |
| Python | 1 791 ms; la primera ejecución, 7 097 ms |
| TypeScript | 1 530 ms |
| Go | 1 856 ms |

- **La limpieza la hace otro contenedor**: junto al de PostgreSQL apareció
  `testcontainers/ryuk:0.14.0`. Ryuk vigila la conexión del proceso de pruebas y, si el proceso
  muere sin borrar lo suyo, lo borra él. Tras cada ejecución, `docker ps` no dejó nada con la
  etiqueta de Testcontainers.

**Quién lo manda:** la **biblioteca**, sobre **Docker**. **Cuánto cuesta:** unos dos segundos por
contenedor, Docker disponible donde corran las pruebas —en local y en la integración continua— y la
primera descarga de la imagen. **Cuándo sí:** toda prueba que ejecute SQL.

---

## 5. 🩺 Desde dentro de un contenedor

**Qué es:** en el corpus, los programas corren **dentro** de los contenedores de lenguaje de §4.6
del documento de dominio, y Testcontainers necesita hablar con Docker desde ahí. El primer intento,
solo con el socket montado, falló así:

```text
[testcontainers-ryuk] WARN org.testcontainers.utility.RyukResourceReaper - Can not connect to Ryuk at 172.17.0.1:49229
Exception in thread "main" java.lang.IllegalStateException: Could not connect to Ryuk at 172.17.0.1:49229
```

- **Docker respondió y el contenedor se creó**, pero Testcontainers buscó su puerto en la pasarela
  de la red por defecto de Docker, `172.17.0.1`, y el contenedor de Java está en la red del
  `compose`, que tiene otra. En Docker Desktop, los puertos publicados se alcanzan desde un
  contenedor por `host.docker.internal`.
- **La corrección es una variable**, que los cuatro Testcontainers leen:

```bash
docker compose -f 13-laboratorio/entorno/docker-compose.yml run --rm \
  -v /var/run/docker.sock:/var/run/docker.sock \
  -e TESTCONTAINERS_HOST_OVERRIDE=host.docker.internal \
  java java Mentira.java
```

- `run --rm java java Mentira.java` es la forma de siempre: un contenedor efímero del servicio
  `java` que ejecuta el fichero fuente y se borra al terminar.
- `-v /var/run/docker.sock:/var/run/docker.sock` monta el socket de Docker dentro del contenedor, y
  con él **el control de Docker del anfitrión**: el programa puede crear y borrar contenedores. Por
  eso se monta solo en esta orden y no en el `compose`.
- `-e TESTCONTAINERS_HOST_OVERRIDE=host.docker.internal` le dice a Testcontainers en qué máquina
  están los puertos que publica. Fuera de un contenedor —el caso normal en un portátil— no hace
  falta.

> **⚠️ Advertencia.** Montar el socket de Docker en un contenedor equivale a darle permisos de
> administrador sobre el anfitrión. En la integración continua es habitual y aceptado; en un
> contenedor de aplicación, nunca.

---

## 6. 🧭 Cómo se organiza una suite

**Qué es:** el contenedor cuesta dos segundos; la organización decide si se pagan una vez o
doscientas. Se explica por mecanismo, sin correr: depende de JUnit, pytest, el *runner* de Node o
`go test`.

| Decisión | Lo habitual | Por qué |
|---|---|---|
| Cuántos contenedores | **Uno por suite**, compartido | Dos segundos una vez; cada prueba, milisegundos |
| El esquema | **Las migraciones de producción** | Si las pruebas crean el esquema de otra forma, prueban otro esquema |
| El aislamiento entre pruebas | Transacción deshecha al final de cada una | Rápido: nada llega al disco de forma visible |
| Entre ejecuciones | Reutilizar el contenedor, opcional | Java lo permite con `testcontainers.reuse.enable`; se paga en limpieza |

- **Las migraciones son de otro bloque**: quien las genera, el ORM o una herramienta, y cómo se
  aplican, es del bloque 06, que lista el [README de la raíz](../README.md). Aquí basta con la
  regla: la suite arranca aplicándolas sobre la base vacía.
- **La transacción por prueba tiene una trampa**: solo aísla lo que ocurre **dentro de ella**. Si el
  código probado confirma por su cuenta, o abre otra conexión —el `REQUIRES_NEW` de Spring es
  exactamente eso, otra conexión, como se corrió en
  [`10/05`](../10-interfaz-con-los-lenguajes/05-java.md) §6—, sus escrituras escapan al *rollback* y
  la siguiente prueba las ve. Para ese código, la limpieza es un `TRUNCATE` de las tablas entre
  pruebas.
- **Los datos de cada prueba los crea la prueba**, en su transacción. Una base precargada que
  comparten todas convierte el orden de ejecución en una dependencia.

> **🧠 Modelo mental.** La base de las pruebas no es un detalle de infraestructura: es **la mitad del
> sistema que se prueba**. Cambiarla por otra es probar otro sistema, más rápido.

---

## 7. 📜 Estándar, motor y convención

> **📜 Estándar o motor.** ISO/IEC 9075 ofrece `NULLS FIRST` y `NULLS LAST` para no depender del
> orden de cada motor, y no conoce `ON CONFLICT`. El tipo exacto de `numeric` y las claves foráneas
> sí son del estándar; SQLite se aparta en los dos por diseño.

| Afirmación | ISO/IEC 9075 | PostgreSQL 18 | H2 2.5 | SQLite |
|---|---|---|---|---|
| Nulos al final en `ASC` y al principio en `DESC` | `NULLS FIRST`/`LAST` para fijarlo | **Sí** | No: al revés | No: al revés |
| `numeric(12,2)` guarda decimales exactos | Sí | Sí | Sí | **No**: afinidad, y `REAL` |
| Las claves foráneas se comprueban | Sí | Sí | Sí | **Solo con `PRAGMA foreign_keys = ON`** |
| `LIKE` distingue mayúsculas | Según la intercalación | Sí | Sí | **No**, en ASCII |
| `ON CONFLICT … DO UPDATE` | No existe | Sí | **No**, ni en modo PostgreSQL | Sí |

**Convención, las dos que más se repiten.** *«H2 en modo PostgreSQL es PostgreSQL»* — imita la
sintaxis en parte y la semántica casi nada: cinco de cinco comprobaciones dieron lo mismo que sin el
modo. Y *«las pruebas contra la base real son lentas»* — el contenedor cuesta unos dos segundos por
suite, no por prueba.

---

## ⚠️ Errores frecuentes

| Se dice | Lo preciso |
|---|---|
| "Si pasa en H2, pasa en PostgreSQL" | El último actualizado salió `PED-00002` en H2 y `PED-00003` en PostgreSQL |
| "El modo PostgreSQL de H2 lo resuelve" | No cambió ninguna de las cinco comprobaciones, y rechaza `ON CONFLICT … DO UPDATE` |
| "SQLite comprueba las claves foráneas" | Solo si se activan; `sqlite3` de Python y `modernc.org/sqlite` no lo hacen |
| "`numeric` es exacto en todas partes" | En SQLite la suma dio `0.30000000000000004` |
| "Testcontainers hace las pruebas lentas" | Unos dos segundos por contenedor, que se comparte en toda la suite |
| "Deshacer la transacción de cada prueba lo aísla todo" | No aísla lo que el código confirma por su cuenta ni lo que hace otra conexión |

---

## 📚 Para profundizar

- **Documentación** — Testcontainers for Java: el módulo de PostgreSQL, «Custom configuration» con
  `TESTCONTAINERS_HOST_OVERRIDE`, y «Reusable Containers».
  <https://java.testcontainers.org/modules/databases/postgres/> ·
  <https://java.testcontainers.org/features/configuration/> ·
  <https://java.testcontainers.org/features/reuse/>
- **Documentación** — Testcontainers for Python.
  <https://testcontainers-python.readthedocs.io/en/latest/>
- **Documentación** — Testcontainers for Node.js, el módulo de PostgreSQL.
  <https://node.testcontainers.org/modules/postgresql/>
- **Documentación** — Testcontainers for Go, el módulo de PostgreSQL.
  <https://golang.testcontainers.org/modules/postgres/>
- **Documentación** — SQLite, «Foreign Key Support»: desactivadas por defecto.
  <https://www.sqlite.org/foreignkeys.html>
- **Documentación** — SQLite, «Datatypes In SQLite»: la afinidad `NUMERIC`.
  <https://www.sqlite.org/datatype3.html>
- **Documentación** — Node.js 24, `node:sqlite`: `enableForeignKeyConstraints`.
  <https://nodejs.org/docs/latest-v24.x/api/sqlite.html>

---

## 🧠 Preguntas

1. ¿Qué es Testcontainers, en una frase? 🟢
2. ¿Qué es una base de datos embebida en memoria, y cuáles usa el corpus en cada lenguaje? 🟢
3. ¿Dónde pone PostgreSQL los nulos en un `ORDER BY … DESC`? 🟢
4. ¿Qué hace Ryuk? 🟢
5. Distingue lo que cambia `MODE=PostgreSQL` en H2 de lo que no cambia, con un ejemplo corrido. 🟡
6. ¿Por qué `sum(total)` da `0.30000000000000004` en SQLite con una columna `numeric(12,2)`? 🟡
7. La misma línea huérfana se acepta en SQLite desde Python y se rechaza desde Node. ¿Por qué? 🟡
8. ¿Por qué el módulo de PostgreSQL de Testcontainers espera dos veces la línea de «listo»? 🟡
9. ¿Qué parte de las diferencias entre H2, SQLite y PostgreSQL es del estándar y qué parte de cada
   motor? Responde para dos de ellas. 🟠
10. ¿Cuál de las cinco diferencias es la más peligrosa y por qué? 🟠
11. ¿Cómo acaba una base de pruebas decidiendo el SQL de producción? Da el ejemplo del upsert. 🟠
12. ¿Por qué una suite comparte un solo contenedor, y qué precio tiene? 🟠
13. ¿Qué no aísla deshacer la transacción al final de cada prueba, y qué harías en ese caso? 🟠
14. ¿Qué riesgo tiene montar el socket de Docker en un contenedor, y cuándo es aceptable? 🟠
15. Diagnostica: Testcontainers crea el contenedor pero falla con `Could not connect to Ryuk at
    172.17.0.1`. Da la causa y la corrección. 🔴
16. Diseña la suite de pruebas de acceso a datos de un servicio con JPA que hoy prueba contra H2:
    contenedores, esquema, aislamiento y el orden en que harías la migración. 🔴
17. Escribe, en el lenguaje que prefieras, una prueba que falle contra H2 o SQLite y pase contra
    PostgreSQL, y di qué comportamiento del motor la separa. 🔴

---

**Anterior:** [`04`](04-constructores-y-cuando-no-usar-orm.md) — constructores, y cuándo no usar
ORM · **Siguiente:** [`06`](06-simulacion-de-entrevista.md) — la simulación de entrevista del
bloque · **Relacionado:** [`10/05`](../10-interfaz-con-los-lenguajes/05-java.md) §7 — H2 y Derby ·
[`01/06`](../01-fundamentos-y-modelo-relacional/06-nulos-y-logica-de-tres-valores.md) §5 — los
nulos al ordenar.
