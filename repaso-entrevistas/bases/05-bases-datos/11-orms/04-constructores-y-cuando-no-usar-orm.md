# 04 — Constructores, y cuándo no usar ORM

> Dos trabajos en los que el ORM estorba: un informe con una CTE recursiva y una función de ventana,
> y una carga de 10 000 filas. El informe se escribe en los cuatro constructores del corpus —jOOQ,
> SQLAlchemy Core, Kysely y sqlc— y da las mismas nueve filas; la carga se mide en los cuatro
> lenguajes, del ORM fila a fila al `COPY`, y va **de 1,4 s a 12 ms**. **Asume leído:**
> [`02`](02-el-problema-n-mas-1.md) —la proyección—, los constructores tal como los presentan
> [`10/05`](../10-interfaz-con-los-lenguajes/05-java.md) §4 y
> [`10/06`](../10-interfaz-con-los-lenguajes/06-python-typescript-y-go.md), y el SQL de
> [`02/05`](../02-sql/05-cte-y-recursion.md) y [`02/06`](../02-sql/06-funciones-de-ventana.md).
> **Vigencia:** 24 de septiembre de 2026.

---

## Salto rápido

- [1. El problema](#1--el-problema) · [2. El término medio](#2--el-término-medio)
- [3. El informe, en los cuatro constructores](#3--el-informe-en-los-cuatro-constructores)
- [4. El ORM ante el informe](#4--el-orm-ante-el-informe) ·
  [5. La carga masiva, medida](#5--la-carga-masiva-medida)
- [6. Cuándo no usar ORM](#6--cuándo-no-usar-orm) ·
  [7. Estándar, motor y convención](#7--estándar-motor-y-convención)
- [Errores frecuentes](#️-errores-frecuentes) · [Preguntas](#-preguntas)

---

## 1. 🎯 El problema

Dos tareas llegan al mismo equipo, que lo hace todo con su ORM:

```text
Informe: las compras mensuales de CLI-00311 en 2025, con los meses sin compras y el acumulado.
Carga nocturna: 10 000 eventos de pedido que llegan de otro sistema.
```

La primera necesita un calendario —una CTE recursiva— y un total acumulado —una función de
ventana—: dos cosas que la especificación de JPA no sabe expresar. La segunda, hecha como se hace
todo lo demás —crear el objeto y guardarlo—, tarda **un segundo y medio** donde el motor necesita
doce milisegundos. Ninguna de las dos da error. Las dos son el sitio donde un ORM deja de ayudar.

> **📝 Contexto.** Todo está **corrido** en los cuatro lenguajes, con las versiones de §4.6 del
> documento de dominio. El informe solo lee. La carga escribe en una **tabla temporal** creada con
> `LIKE eventos_pedido` dentro de una transacción que se deshace al final: desaparecen la tabla y
> las filas, y la secuencia de `eventos_pedido` no avanza. La tabla temporal no copia la clave
> foránea, así que los tiempos no incluyen su comprobación. **Longitud:** unas 410 líneas; capítulo
> normal que pasa el disparador de 400 por las cuatro versiones del informe, y lo declara aquí.

---

## 2. 🧱 El término medio

**Qué es:** entre escribir SQL en una cadena y dejar que el ORM lo escriba hay un tercer camino, el
**constructor de consultas**: el SQL se escribe en el lenguaje, con su estructura —`select`,
`join`, `with`, `over`—, y la biblioteca lo convierte en texto parametrizado. No hay sesión, ni mapa
de identidad, ni carga perezosa: lo que se escribe es lo que se ejecuta.

| Lenguaje | Constructor | Qué comprueba | Escotilla para lo que no cubre |
|---|---|---|---|
| Java | jOOQ 3.21.8 | Con clases generadas, nombres y tipos al compilar | `field("…")`, `table("…")` con SQL propio |
| Python | SQLAlchemy Core 2.0.54 | Columnas, si la tabla se declara o se lee de la base | `text()`, `literal_column()` |
| TypeScript | Kysely 0.29.6 | Nombres y tipos contra el esquema escrito como tipos | `` sql`…` `` |
| Go | sqlc 1.31.1 | El SQL entero contra el esquema, **antes** de compilar | No la necesita: el SQL es tuyo |

- **Tres construyen y uno genera**: jOOQ, Core y Kysely construyen el SQL en tiempo de ejecución;
  sqlc lee un fichero `.sql` y genera el código Go que lo ejecuta, como explica
  [`10/06`](../10-interfaz-con-los-lenguajes/06-python-typescript-y-go.md) §5.
- **Todos tienen escotilla**: un trozo de SQL literal donde el constructor no llega. Usarla no es
  un fracaso; es lo previsto. Lo que se pierde en ese trozo es la comprobación de nombres.

**Quién lo manda:** cada **biblioteca**. **Cuánto cuesta:** aprender una segunda forma de escribir
SQL y, en jOOQ y sqlc, un paso de generación. **Cuándo sí:** consultas con estructura —informes,
filtros dinámicos, CTE— que no son la carga y el guardado de una entidad.

---

## 3. 🧱 El informe, en los cuatro constructores

**Qué es:** el informe del §1, primero en SQL, como referencia. El calendario es la CTE recursiva
de [`02/05`](../02-sql/05-cte-y-recursion.md) §3; el acumulado, la ventana de
[`02/06`](../02-sql/06-funciones-de-ventana.md) §2; el mes se calcula en UTC para no depender de la
zona de la sesión, por la trampa de [`10/03`](../10-interfaz-con-los-lenguajes/03-mapeo-de-tipos.md)
§5.

```sql
WITH RECURSIVE meses (mes) AS (
  SELECT date '2025-01-01'
  UNION ALL
  SELECT (mes + interval '1 month')::date FROM meses WHERE mes < date '2025-09-01'
), compras AS (
  SELECT date_trunc('month', creado_en AT TIME ZONE 'UTC')::date AS mes, count(*) AS pedidos, sum(total) AS importe
    FROM pedidos
   WHERE cliente_id = 311 AND creado_en >= timestamptz '2025-01-01 00:00+00'
   GROUP BY 1
)
SELECT m.mes, coalesce(c.pedidos, 0) AS pedidos, coalesce(c.importe, 0) AS importe,
       sum(coalesce(c.importe, 0)) OVER (ORDER BY m.mes) AS acumulado
  FROM meses m LEFT JOIN compras c ON c.mes = m.mes
 ORDER BY m.mes;
```

```text
    mes     | pedidos | importe  | acumulado
------------+---------+----------+-----------
 2025-01-01 |       4 | 28767.68 |  28767.68
 2025-02-01 |       0 |        0 |  28767.68
 2025-03-01 |       1 | 10731.94 |  39499.62
 2025-04-01 |       0 |        0 |  39499.62
 2025-05-01 |       2 | 16570.51 |  56070.13
 2025-06-01 |       3 | 13496.03 |  69566.16
 2025-07-01 |       1 |  2018.26 |  71584.42
 2025-08-01 |       1 | 10077.32 |  81661.74
 2025-09-01 |       1 |  4323.61 |  85985.35
(9 filas)
```

- **Febrero y abril salen con cero** porque los pone el calendario; sin la CTE recursiva, el informe
  tendría siete filas y un hueco que nadie ve.

Lo mismo en cada constructor. Se enseña la parte que los distingue —el calendario recursivo y la
ventana—; `compras` y el `LEFT JOIN` siguen la misma forma:

```java
// jOOQ, sin clases generadas: los nombres van como texto
var meses = name("meses").fields("mes").as(
    select(val(LocalDate.of(2025, 1, 1)))
    .unionAll(select(localDateAdd(mes, 1, DatePart.MONTH))
              .from(name("meses")).where(mes.lt(LocalDate.of(2025, 9, 1)))));
// la zona fija del informe, por la escotilla: SQL con el campo como argumento
var mesCompra = field("date_trunc('month', {0} at time zone 'UTC')::date", SQLDataType.LOCALDATE, field(name("creado_en")));
… sql.withRecursive(meses, compras).select(…, sum(importe).over(orderBy(field(name("m", "mes")))).as("acumulado"))
```

```python
# SQLAlchemy Core: la tabla se lee de la base con autoload_with
meses = select(literal(date(2025, 1, 1), Date).label("mes")).cte("meses", recursive=True)
meses = meses.union_all(
    select(cast(meses.c.mes + literal_column("interval '1 month'"), Date))
    .where(meses.c.mes < date(2025, 9, 1)))
… func.sum(importe).over(order_by=meses.c.mes).label("acumulado")
```

```ts
// Kysely: el esquema escrito como tipos; los CTE los añade él
db.withRecursive("meses(mes)", (db) =>
    db.selectNoFrom(sql<string>`date '2025-01-01'`.as("mes"))
      .unionAll(db.selectFrom("meses")
        .select(sql<string>`(mes + interval '1 month')::date`.as("mes"))
        .where("mes", "<", sql<string>`date '2025-09-01'`)))
  … eb.fn.sum<string>(eb.fn.coalesce("c.importe", sql<string>`0`)).over((ob) => ob.orderBy("m.mes"))
```

```sql
-- sqlc: el mismo SQL de arriba en consultas.sql, con un nombre y el cliente como $1
-- name: ComprasMensuales :many
WITH RECURSIVE meses (mes) AS ( … ) … WHERE cliente_id = $1 …
```

Los cuatro devolvieron las mismas nueve filas. La última de cada uno, tal como la imprime:

```text
jOOQ      [2025-09-01, 1, 4323.61, 85985.35]
Core      (datetime.date(2025, 9, 1), 1, Decimal('4323.61'), Decimal('85985.35'))
Kysely    {"mes":"2025-09-01T00:00:00.000Z","pedidos":"1","importe":"4323.61","acumulado":"85985.35"}
sqlc      2025-09-01 1 4323.61 85985.35
```

- **El SQL generado es el mismo en forma**: los cuatro emiten `with recursive`, el `union all`, el
  `left join` y el `over (order by …)`. jOOQ y Core parametrizan las fechas; Kysely deja literales
  los trozos escritos con `` sql`…` ``, porque ahí el texto es tuyo.
- **Las escotillas aparecen donde el constructor no tiene palabra**: en jOOQ, el `at time zone` se
  escribió como SQL con `field("…", …)`; en Kysely, las fechas constantes y la suma del intervalo,
  con `` sql`…` ``. Core no la necesitó: `func.timezone` convierte cualquier nombre en una llamada a
  función.
- **Los tipos que llegan son los de [`10/03`](../10-interfaz-con-los-lenguajes/03-mapeo-de-tipos.md)
  §3**: `Decimal` en Python, cadenas para `numeric` y `count` en Kysely, y el mes como un `Date` a
  medianoche UTC. sqlc infirió el tipo de cada columna del SQL y generó
  `ComprasMensuales(ctx, clienteID int64)` con el mes como `pgtype.Date`: si la consulta nombrara
  una columna que no existe, `sqlc generate` fallaría antes de compilar.

**Quién lo manda:** el **motor** la consulta; cada **biblioteca** cómo se escribe. **Cuánto
cuesta:** el SQL del constructor es más largo que el SQL a secas, y en informes así la ventaja de
tipos es pequeña. **Cuándo sí:** cuando la consulta se compone —filtros opcionales, columnas
según el usuario—, que es donde concatenar cadenas es peligroso, como en
[`10/02`](../10-interfaz-con-los-lenguajes/02-parametrizadas-e-inyeccion.md).

---

## 4. 🩺 El ORM ante el informe

**Qué es:** la misma consulta, pedida a los ORM del bloque. El resultado depende menos de «ORM sí o
no» que de **qué lenguaje de consulta trae cada uno**.

Hibernate tiene el suyo, HQL, que es JPQL con añadidos. El informe entero, escrito en HQL sobre la
entidad `Pedido`:

```text
-- HQL: with meses as (select cast(:inicio as LocalDate) as mes union all select m.mes + 1 month …), compras as (…)
Hibernate: with recursive meses (mes) as (select cast(? as date) union all select cast(m1_0.mes+(1)*interval '1 month' as date) from meses m1_0 where m1_0.mes<?),compras (mes,pedidos,importe) as (select cast(date_trunc('month',timezone('UTC',p1_0.creado_en)) as date),count(*),sum(p1_0.total) from pedidos p1_0 where p1_0.cliente_id=311 and p1_0.creado_en>=? group by 1) select m2_0.mes,coalesce(c1_0.pedidos,0),coalesce(c1_0.importe,0),sum(coalesce(c1_0.importe,0)) over(order by m2_0.mes) from meses m2_0 left join compras c1_0 on c1_0.mes=m2_0.mes order by m2_0.mes
filas: 9, la última: [2025-09-01, 1, 4323.61, 85985.35]
```

- **Hibernate 7.4 lo hace**, y detecta solo que la CTE es recursiva. Dos detalles corridos: el
  parámetro del término base necesitó `cast(:inicio as LocalDate)` —sin él, la consulta falló al
  interpretarse, porque Hibernate no sabía el tipo de `mes`—, y la zona se pasó con
  `function('timezone', …)`, la escotilla de HQL.
- **JPQL, la especificación, no puede**: la gramática de Jakarta Persistence 3.2 tiene `UNION`, pero
  ni `WITH` ni `OVER`. Una consulta así en JPA estándar es una consulta nativa, SQL en una cadena.
  Quien dice «JPA no hace ventanas» tiene razón sobre JPA y no sobre Hibernate.

El resto de ORM del corpus:

| ORM | ¿Expresa el informe? | Cómo, corrido |
|---|---|---|
| Hibernate 7.4 | **Sí**, en HQL | La consulta de arriba |
| SQLAlchemy ORM | **Sí** | Es la consulta de Core: el ORM ejecuta las mismas construcciones |
| GORM 1.31 | No como constructor | `db.Raw(informe).Scan(&filas)`: 9 filas, la última `{2025-09-01T00:00:00Z 1 4323.61 85985.35}` |
| Drizzle 0.45 | Tiene `$with`, **sin recursivo** | `db.execute(sql.raw(informe))`: 9 filas |

- **Lo de Drizzle está leído en la biblioteca**, no deducido: su constructor de PostgreSQL expone
  `$with` y no tiene ninguna variante recursiva.
- **`Raw` y `sql.raw` no son una derrota**: ejecutan SQL escrito y verificado en `psql`, y lo mapean
  a una estructura. Es lo que hace sqlc, sin la comprobación previa.

> **Veredicto:** el informe no pide abandonar el ORM, sino **salir de la entidad**: el resultado no
> es un `Pedido` ni se va a modificar, es una proyección como las de
> [`02`](02-el-problema-n-mas-1.md) §4. Donde el lenguaje de consulta del ORM llega, se usa; donde
> no, SQL escrito.

---

## 5. 🩺 La carga masiva, medida

**Qué es:** 10 000 eventos para `PED-00042`, insertados de las formas que ofrece cada lenguaje, en
la tabla temporal del §1. Tres ejecuciones por forma; se da la central.

| Lenguaje | Forma | Sentencias | Tiempo |
|---|---|---|---|
| Java | Hibernate, clave `IDENTITY`, `jdbc.batch_size = 500` | 10 000 | **1 372 ms** |
| | Hibernate, clave de secuencia, lotes de 500 | En lotes | 157 ms |
| | JDBC, lotes con `reWriteBatchedInserts=true` | En lotes | 32 ms |
| | `COPY`, con `CopyManager` | 1 | 13 ms |
| Python | SQLAlchemy ORM, `add_all` y `flush` | 10, de 1 000 filas | 338 ms |
| | SQLAlchemy Core, lista de diccionarios | 10 000, en *pipeline* | 132 ms |
| | `COPY`, con `cursor.copy` de psycopg | 1 | 12 ms |
| Go | GORM, `Create` uno a uno | 10 000 | **1 105 ms** |
| | GORM, `CreateInBatches(lista, 500)` | 20 | 32 ms |
| | `CopyFrom` de pgx | 1 | 11 ms |
| TypeScript | Drizzle, `insert` uno a uno | 10 000 | **1 582 ms** |
| | Drizzle, un `insert` con las 10 000 | 1 | 183 ms |
| | `COPY` con `pg-copy-streams`, una línea por trozo | 1 | 102 ms |
| | `COPY` con `pg-copy-streams`, un solo trozo | 1 | 12 ms |

- **Uno a uno cuesta lo mismo en los cuatro**: entre 1,1 y 1,6 s, porque cada fila es un viaje de
  ida y vuelta a la base. Con la base a 1 ms de red, serían diez segundos más.
- **`IDENTITY` apaga los lotes de Hibernate.** Con `batch_size = 500` pedido, sigue insertando fila
  a fila: para asignar el identificador a cada objeto necesita que la base lo devuelva al insertar.
  La documentación lo dice tal cual: *«Hibernate disables insert batching at the JDBC level
  transparently if you use an identity identifier generator»*. Con una secuencia —que Hibernate
  consulta una vez cada 50 identificadores—, la misma carga baja a 157 ms. Invertir el orden de
  las pruebas dio 1 314 y 236 ms: la diferencia no es el calentamiento de la JVM.
- **SQLAlchemy no tiene esa trampa**: con la misma columna `IDENTITY`, el ORM agrupa las filas en
  diez sentencias de 1 000 con `RETURNING`, lo que su registro llama `insertmanyvalues`. Core, sin
  `RETURNING`, pasa una sola sentencia y las 10 000 filas al `executemany` de psycopg, que las envía
  en **modo *pipeline***: sin esperar la respuesta de cada una antes de mandar la siguiente.

```text
INFO sqlalchemy.engine.Engine INSERT INTO carga (pedido_id, tipo, carga) SELECT p0::BIGINT, p1::VARCHAR, p2::JSONB FROM (VALUES (%(pedido_id__0)s::BIGINT, …
INFO sqlalchemy.engine.Engine [generated in 0.03585s (insertmanyvalues) 1/10 (ordered)] {'tipo__0': 'CARGA', …
```

- **El `insert` de muchas filas tiene techo.** Drizzle mete las 10 000 en una sentencia con 30 000
  parámetros. Con 25 000 filas, 75 000 parámetros, falla con un error que despista:

```text
causa: bind message has 9464 parameter formats but 0 parameters
```

  El mensaje `Bind` del protocolo lleva el número de parámetros en un entero de 16 bits: 65 535 como
  máximo. 75 000 − 65 536 = 9 464: el número dio la vuelta. Los lotes de GORM, Hibernate y
  SQLAlchemy existen, entre otras cosas, para no llegar ahí.
- **`COPY` gana en los cuatro, y en Node depende de cómo se alimente.** Escribir una línea por trozo
  en el flujo de `pg-copy-streams` tardó 102 ms; unir las líneas y escribir un solo trozo, 12 ms, lo
  mismo que los demás. El coste estaba en los 10 000 mensajes pequeños, no en `COPY`.

**Quién lo manda:** el **motor** el `COPY` y el límite del protocolo; cada **biblioteca** si agrupa
o no. **Cuánto cuesta:** `COPY` no devuelve los identificadores ni pasa por las validaciones y
eventos del ORM; si la aplicación los necesita, se paga en otra parte. **Cuándo sí:** cargas y
migraciones de datos de miles de filas en adelante.

> **💡 Consejo.** En un servicio con JPA que carga en masa, la primera pregunta es **qué generador
> de claves tiene la entidad**. Con `IDENTITY`, subir `batch_size` no cambia nada, y el registro no
> dice por qué.

---

## 6. 🧭 Cuándo no usar ORM

Lo que dejan los dos experimentos, como regla de decisión:

| Tarea | Herramienta | Por qué |
|---|---|---|
| Cargar una entidad, cambiarla y guardarla | ORM | Es para lo que está: identidad, *dirty checking*, unidad de trabajo |
| Listados de solo lectura | Proyección del ORM, o constructor | No hacen falta entidades; ver [`02`](02-el-problema-n-mas-1.md) §4 |
| Informes con CTE, ventanas o agregados | Constructor, o SQL escrito | El resultado no es una entidad; JPQL no llega |
| Filtros que se componen según la petición | Constructor | Estructura sin concatenar cadenas |
| Cargas de miles de filas | `COPY`, o lotes del driver | El ORM fila a fila cuesta cien veces más |
| Cambios masivos: «todos los pedidos de X pasan a Y» | Un `UPDATE` con `WHERE` | Cargar, cambiar y guardar N objetos son N sentencias y N objetos en la sesión |
| Upsert | `INSERT … ON CONFLICT` escrito | El de [`02/07`](../02-sql/07-escritura-upsert-y-vistas.md) §4; los ORM lo exponen desigualmente |

- **No es una elección de proyecto, es de consulta.** El mismo servicio usa el ORM para la ficha
  del pedido y SQL para el informe mensual, **con la misma conexión y la misma transacción**: los
  cuatro ORM del corpus dejan ejecutar SQL dentro de su sesión.
- **El cambio masivo con `UPDATE` se salta la sesión**: si hay entidades cargadas de esas filas, la
  sesión no se entera y tiene el dato viejo de [`03`](03-carga-caches-y-la-sesion.md) §6. Se hace
  al principio de la transacción o con la sesión limpia.

> **🧠 Modelo mental.** El ORM es la herramienta para **una entidad cada vez**. En cuanto la tarea
> habla de conjuntos —un informe, una carga, un cambio a miles de filas—, la unidad natural es la
> sentencia, y la herramienta es SQL, escrito o construido.

---

## 7. 📜 Estándar, motor y convención

> **📜 Estándar o motor.** `WITH RECURSIVE` y las funciones de ventana son del estándar SQL; `COPY`
> y el límite de parámetros del protocolo son de PostgreSQL; lo demás es de cada biblioteca.

| Afirmación | ISO/IEC 9075 | PostgreSQL 18 | JPA 3.2 | Bibliotecas |
|---|---|---|---|---|
| CTE recursiva y ventanas | Sí | Sí | **No**: ni `WITH` ni `OVER` en JPQL | Hibernate en HQL, los cuatro constructores |
| `COPY` para cargar | No | Sí | — | Los cuatro drivers lo exponen |
| Máximo de parámetros por sentencia | — | 65 535, por el protocolo | — | Los lotes lo evitan |
| `IDENTITY` impide agrupar inserciones | — | — | — | **Hibernate** sí; SQLAlchemy no |
| Ejecutar SQL dentro de la sesión del ORM | — | — | Consultas nativas | Los cuatro |

**Convención, las dos que más se repiten.** *«Si usamos ORM, todo va por el ORM»* — los cuatro ORM
del corpus tienen escotilla de SQL porque sus autores saben que hace falta. Y *«los constructores
son para quien no sabe SQL»* — es al revés: jOOQ, Kysely y sqlc piden saber SQL, y lo que añaden es
comprobación de nombres y tipos.

---

## ⚠️ Errores frecuentes

| Se dice | Lo preciso |
|---|---|
| "JPA no hace funciones de ventana" | JPQL no; HQL de Hibernate 7.4 sí, y la CTE recursiva también |
| "Subir `batch_size` acelera la carga de Hibernate" | Con clave `IDENTITY`, Hibernate no agrupa: 1 372 ms con lotes de 500 pedidos |
| "Un `insert` con todas las filas es lo más rápido" | Tiene techo: 65 535 parámetros, y el error que da al pasarlo despista |
| "`COPY` es siempre rápido" | En Node, alimentado línea a línea, tardó 102 ms en vez de 12 |
| "Usar `Raw` es no usar el ORM" | Es usar su escotilla para lo que no es una entidad, dentro de su sesión |
| "Un constructor evita saber SQL" | Pide saberlo; lo que añade es comprobar nombres y tipos |

---

## 📚 Para profundizar

- **Documentación** — jOOQ 3.21, «The WITH RECURSIVE clause» y «Plain SQL», la escotilla y sus
  riesgos. <https://www.jooq.org/doc/3.21/manual/sql-building/sql-statements/with-recursive-clause/>
  · <https://www.jooq.org/doc/3.21/manual/sql-building/plain-sql/>
- **Documentación** — SQLAlchemy 2.0, «Working with Engines and Connections»: el comportamiento
  *insertmanyvalues*. <https://docs.sqlalchemy.org/en/20/core/connections.html>
- **Documentación** — Kysely, «Raw SQL»: `` sql`…` `` como escotilla.
  <https://kysely.dev/docs/recipes/raw-sql>
- **Documentación** — Hibernate ORM 7.4, «User Guide»: HQL con CTE y ventanas, y el generador
  `IDENTITY` frente a los lotes. <https://docs.hibernate.org/orm/7.4/userguide/html_single/>
- **Documentación** — Jakarta Persistence 3.2, la especificación: la gramática de JPQL.
  <https://jakarta.ee/specifications/persistence/3.2/jakarta-persistence-spec-3.2>
- **Documentación** — PostgreSQL 18, «COPY», «Populating a Database» y «Message Formats», con el
  `Int16` del mensaje `Bind`. <https://www.postgresql.org/docs/18/sql-copy.html> ·
  <https://www.postgresql.org/docs/18/populate.html> ·
  <https://www.postgresql.org/docs/18/protocol-message-formats.html>
- **Documentación** — GORM, «Create»: la inserción por lotes. <https://gorm.io/docs/create.html>
- **Código** — `pg-copy-streams`, el `COPY` de `pg`.
  <https://github.com/brianc/node-pg-copy-streams>

---

## 🧠 Preguntas

1. ¿Qué es un constructor de consultas, y en qué se diferencia de un ORM? 🟢
2. Nombra el constructor del corpus para cada uno de los cuatro lenguajes. 🟢
3. ¿Qué es la escotilla de un constructor, y cuál es la de Kysely? 🟢
4. ¿Qué comando de PostgreSQL es el más rápido para cargar miles de filas? 🟢
5. Distingue jOOQ o Kysely de sqlc: quién escribe el SQL y cuándo se comprueba. 🟡
6. ¿Puede JPA expresar una CTE recursiva con una función de ventana? ¿Y Hibernate? Responde por
   separado. 🟡
7. ¿Por qué la clave `IDENTITY` impide a Hibernate agrupar inserciones, y cómo se evita? 🟡
8. ¿Qué hace SQLAlchemy con 10 000 objetos nuevos al hacer `flush`, y en cuántas sentencias? 🟡
9. ¿Qué límite tiene un `INSERT` con muchas filas en PostgreSQL, y de dónde sale? ¿Lo fija el
   estándar o es cosa del motor? 🟡
10. Un informe mensual deja fuera los meses sin compras. ¿Qué le falta a la consulta, y cómo lo
    escribirías? ¿Lo fija el estándar o es cosa del motor? 🟠
11. ¿Por qué usar `Raw` en GORM o `sql.raw` en Drizzle no es abandonar el ORM? 🟠
12. ¿Qué pierdes al cargar con `COPY` en vez de con el ORM, y cuándo te importa? 🟠
13. Un compañero sube `hibernate.jdbc.batch_size` de 0 a 500 y la carga tarda lo mismo. Da la
    causa probable y cómo la confirmarías. 🟠
14. ¿Qué riesgo tiene un `UPDATE` masivo lanzado en medio de una sesión del ORM con entidades
    cargadas? 🟠
15. Un `insert` de Drizzle con 25 000 filas falla con `bind message has 9464 parameter formats but 0
    parameters`. Explica el mensaje y la corrección. 🔴
16. Diseña la carga nocturna de un millón de eventos en un servicio que usa GORM para todo lo
    demás: herramienta, transacción y qué pasa si falla a mitad. 🔴
17. Escribe, en el constructor que prefieras, las compras mensuales de un cliente con los meses sin
    compras y el acumulado. 🔴

---

**Anterior:** [`03`](03-carga-caches-y-la-sesion.md) — carga, cachés y la sesión · **Siguiente:**
[`05`](05-probar-contra-base-de-datos-real.md) — probar contra una base de datos real ·
**Relacionado:** [`02/05`](../02-sql/05-cte-y-recursion.md) — la CTE recursiva ·
[`10/06`](../10-interfaz-con-los-lenguajes/06-python-typescript-y-go.md) — Core, Kysely y sqlc.
