# 06 — Python, TypeScript y Go

> Lo que `05` hizo con Java, hecho con los otros tres lenguajes: el mismo ejemplo del bloque con
> SQLAlchemy —Core y ORM— en Python, con Kysely y Drizzle en TypeScript, y con `database/sql`, sqlc
> y GORM en Go. En cada uno, qué escribe el SQL y cómo se ve el SQL que de verdad llega a la base.
> **Asume leído:** [`05`](05-java.md) —el mapa de capas, que aquí se reutiliza— y
> [`01`](01-el-driver-la-conexion-y-el-pool.md) a [`04`](04-transacciones-y-resultados-grandes.md).
> **Vigencia:** 24 de septiembre de 2026.

---

## Salto rápido

- [1. El problema](#1--el-problema) · [2. El mapa, en tres lenguajes](#2--el-mapa-en-tres-lenguajes)
- [3. Python: SQLAlchemy Core y ORM](#3--python-sqlalchemy-core-y-orm) · [4. TypeScript: Kysely y
  Drizzle](#4--typescript-kysely-y-drizzle)
- [5. Go: database/sql, sqlc y GORM](#5--go-databasesql-sqlc-y-gorm) · [6. Cómo se
  elige](#6--cómo-se-elige)
- [7. Estándar, motor y convención](#7--estándar-motor-y-convención) · [Errores
  frecuentes](#️-errores-frecuentes) · [Para profundizar](#-para-profundizar) ·
  [Preguntas](#-preguntas)

---

## 1. 🎯 El problema

La tienda tiene tres servicios nuevos, uno por lenguaje, y cada equipo eligió su biblioteca por lo
que leyó esa semana. Seis meses después, en una revisión de rendimiento, alguien pregunta lo mismo
en los tres: **qué SQL se ejecuta exactamente, y dónde se ve**.

La respuesta cambia más con la capa que con el lenguaje. Las mismas tres familias de `05` existen en
los tres —SQL a mano, SQL construido desde código, y ORM—, con nombres distintos y con una
diferencia que conviene saber: **cómo te enseña cada una el SQL que genera, y si lo que enseña es lo
que llega a la base**.

> **📝 Contexto.** Todo está **corrido** en los contenedores de lenguaje, con las versiones de §2
> fijadas en sus `Dockerfile` y verificadas en §4.6 del dominio. Los tres lenguajes producen las
> mismas tres líneas del ejemplo común, así que la salida se pega una vez por biblioteca solo cuando
> dice algo nuevo. **Longitud:** capítulo denso, declarado en §4.6 de la guía de estilo: siete
> bibliotecas en tres lenguajes, cada una con su código y su SQL.

---

## 2. 🧱 El mapa, en tres lenguajes

**Qué es:** la tabla de capas de [`05`](05-java.md) §2, con lo que ocupa cada casilla en los otros
tres lenguajes. Lo que está en negrita se corre en este capítulo, con su versión; el resto se nombra
para que se reconozca.

| Capa | Python | TypeScript | Go |
|---|---|---|---|
| Driver | psycopg 3.3.6 | `pg` 8.23.0 | pgx 5.11.0 |
| SQL a mano, con mapeo | **SQLAlchemy Core** 2.0.54 | `pg` directo | **`database/sql`** sobre pgx |
| SQL construido o generado | SQLAlchemy Core | **Kysely** 0.29.6 | **sqlc** 1.31.1 |
| ORM | **SQLAlchemy ORM** 2.0.54 · Django ORM | **Drizzle** 0.45.3 · Prisma · TypeORM | **GORM** 1.31.2 · ent |
| Migraciones | Alembic | Las de cada ORM | golang-migrate |

- **Drizzle está entre dos casillas**: su API de `select` es un constructor de SQL tipado, y además
  tiene consultas relacionales de ORM. Aquí se usa como constructor.
- **sqlc es al revés que todos los demás**: escribes el SQL y la herramienta **genera** el código Go
  tipado que lo ejecuta. Es el mismo contrato que jOOQ con otra dirección.
- Las migraciones tienen dueño propio en el corpus, el bloque 06, que lista el [README de la
  raíz](../README.md).

---

## 3. 🧱 Python: SQLAlchemy Core y ORM

**Qué es:** SQLAlchemy son dos bibliotecas en una. **Core** manda SQL —escrito a mano o construido—
y convierte filas; el **ORM** mapea clases a tablas encima de Core. Las dos van sobre psycopg 3, con
la URL `postgresql+psycopg://`:

```python
motor = create_engine("postgresql+psycopg://", echo=True)

with motor.connect() as con:                       # 1. Core: SQL a mano, parámetros con nombre
    filas = con.execute(text("""
        SELECT p.estado, p.total, l.linea, l.cantidad, l.precio_unit
          FROM pedidos p JOIN pedido_lineas l ON l.pedido_id = p.id
         WHERE p.codigo = :codigo ORDER BY l.linea"""), {"codigo": "PED-00042"})

class Pedido(Base):                                # 2. ORM: clases mapeadas a tablas
    __tablename__ = "pedidos"
    id: Mapped[int] = mapped_column(primary_key=True)
    codigo: Mapped[str]
    estado: Mapped[str]
    total: Mapped[Decimal]
    lineas: Mapped[list["Linea"]] = relationship(order_by="Linea.linea")   # perezosa por defecto

with Session(motor) as sesion:
    pedido = sesion.scalars(select(Pedido).where(Pedido.codigo == "PED-00042")).one()
    for l in pedido.lineas: …                      # aquí se cargan las líneas
```

Con `echo=True`, SQLAlchemy registra cada sentencia. Estas son las líneas del log que muestran el
SQL de cada parte, sin la hora de cada línea ni las tres consultas con que el motor inspecciona el
servidor al conectar:

```text
INFO sqlalchemy.engine.Engine BEGIN (implicit)
INFO sqlalchemy.engine.Engine
        SELECT p.estado, p.total, l.linea, l.cantidad, l.precio_unit
          FROM pedidos p JOIN pedido_lineas l ON l.pedido_id = p.id
         WHERE p.codigo = %(codigo)s ORDER BY l.linea
INFO sqlalchemy.engine.Engine [generated in 0.00015s] {'codigo': 'PED-00042'}
INFO sqlalchemy.engine.Engine ROLLBACK
INFO sqlalchemy.engine.Engine BEGIN (implicit)
INFO sqlalchemy.engine.Engine SELECT pedidos.id, pedidos.codigo, pedidos.estado, pedidos.total
FROM pedidos
WHERE pedidos.codigo = %(codigo_1)s::VARCHAR
INFO sqlalchemy.engine.Engine [generated in 0.00017s] {'codigo_1': 'PED-00042'}
INFO sqlalchemy.engine.Engine SELECT pedido_lineas.pedido_id AS pedido_lineas_pedido_id, pedido_lineas.linea AS pedido_lineas_linea, pedido_lineas.cantidad AS pedido_lineas_cantidad, pedido_lineas.precio_unit AS pedido_lineas_precio_unit
FROM pedido_lineas
WHERE %(param_1)s::INTEGER = pedido_lineas.pedido_id ORDER BY pedido_lineas.linea
INFO sqlalchemy.engine.Engine [generated in 0.00008s] {'param_1': 42}
INFO sqlalchemy.engine.Engine ROLLBACK
```

- **`BEGIN (implicit)` y un `ROLLBACK` al cerrar**: es la transacción implícita de psycopg de
  [`04`](04-transacciones-y-resultados-grandes.md) §2, vista desde la capa de arriba. Una lectura
  sin `commit` termina deshecha, sin daño; una escritura sin `commit`, también, y ese sí es el daño.
- **El ORM hizo dos consultas**, la del pedido y, al recorrer `lineas`, la de las líneas: la misma
  carga perezosa que Hibernate en [`05`](05-java.md) §5, y la puerta del N+1 del bloque 11.
- **`Mapped[str]` se convierte en `::VARCHAR`** en el parámetro. La columna es `text`, y PostgreSQL
  compara los dos sin problema, pero es un recordatorio de que el tipo del lenguaje decide el tipo
  del parámetro, que es lo de [`03`](03-mapeo-de-tipos.md).

**Cuánto cuesta:** Core, casi nada sobre psycopg; el ORM, lo que cuesta cualquier ORM —SQL que no
escribes, una sesión que guarda lo cargado—. **Cuándo sí:** Core, siempre que quieras SQL a la vista
con parámetros con nombre; el ORM, un dominio de entidades.

---

## 4. 🧱 TypeScript: Kysely y Drizzle

**Qué es:** dos constructores de SQL tipados, sobre el mismo `pg`. **Kysely** recibe el esquema como
tipos de TypeScript, escritos o generados; **Drizzle** lo recibe declarado en código:

```typescript
interface BaseDeDatos {                       // el esquema, escrito como tipos: Kysely no lo lee de la base
  pedidos: { id: string; codigo: string; estado: string; total: string };
  pedido_lineas: { pedido_id: string; linea: number; cantidad: number; precio_unit: string };
}
const db = new Kysely<BaseDeDatos>({ dialect: new PostgresDialect({ pool: new pg.Pool({ max: 5 }) }) });
const consulta = db.selectFrom("pedidos as p")
  .innerJoin("pedido_lineas as l", "l.pedido_id", "p.id")
  .select(["p.estado", "p.total", "l.linea", "l.cantidad", "l.precio_unit"])
  .where("p.codigo", "=", "PED-00042")
  .orderBy("l.linea");
console.log(consulta.compile().sql);          // el SQL que construye
```

```text
select "p"."estado", "p"."total", "l"."linea", "l"."cantidad", "l"."precio_unit" from "pedidos" as "p" inner join "pedido_lineas" as "l" on "l"."pedido_id" = "p"."id" where "p"."codigo" = $1 order by "l"."linea"
PAGADO 3186.23 linea=1 cantidad=1 precio=102.83
PAGADO 3186.23 linea=2 cantidad=5 precio=27.03
PAGADO 3186.23 linea=3 cantidad=3 precio=982.75
```

```typescript
const pedidos = pgTable("pedidos", {           // el esquema, declarado en código
  id: bigint("id", { mode: "number" }).primaryKey(),
  codigo: text("codigo").notNull(),
  estado: text("estado").notNull(),
  total: numeric("total").notNull(),
});
// …y lineas, igual
const consulta = db.select({ estado: pedidos.estado, total: pedidos.total, linea: lineas.linea,
                             cantidad: lineas.cantidad, precio: lineas.precioUnit })
  .from(pedidos).innerJoin(lineas, eq(lineas.pedidoId, pedidos.id))
  .where(eq(pedidos.codigo, "PED-00042")).orderBy(lineas.linea);
console.log(consulta.toSQL().sql);
```

```text
select "pedidos"."estado", "pedidos"."total", "pedido_lineas"."linea", "pedido_lineas"."cantidad", "pedido_lineas"."precio_unit" from "pedidos" inner join "pedido_lineas" on "pedido_lineas"."pedido_id" = "pedidos"."id" where "pedidos"."codigo" = $1 order by "pedido_lineas"."linea"
```

- **Los dos parametrizan y citan identificadores** solos, igual que jOOQ.
- **Los tipos del esquema tienen que decir la verdad sobre el driver**: `pg` devuelve `bigint` y
  `numeric` como cadena, así que en Kysely `id` y `total` son `string`. En Drizzle, `mode: "number"`
  convierte el `bigint` a `number`, que pierde precisión por encima de 2⁵³: es la trampa de
  [`03`](03-mapeo-de-tipos.md) §4 tomada como decisión.
- **Ninguno de los dos comprueba que el esquema del código coincida con el de la base**: eso lo da
  generar los tipos desde la base, o las migraciones del propio ORM.

**Cuánto cuesta:** mantener el esquema en dos sitios, la base y el código. **Cuándo sí:** Kysely,
SQL tipado sin ORM; Drizzle, lo mismo con un ORM ligero al lado. Prisma y TypeORM, los otros dos
nombres que se van a oír, generan el cliente desde un esquema propio y usan decoradores,
respectivamente.

---

## 5. 🧱 Go: database/sql, sqlc y GORM

**`database/sql`** es la interfaz común de la biblioteca estándar, con su propio *pool*; pgx se
registra en ella como driver `pgx`:

```go
import _ "github.com/jackc/pgx/v5/stdlib" // registra pgx como driver "pgx" de database/sql

db, err := sql.Open("pgx", "") // database/sql trae su propio pool
db.SetMaxOpenConns(5)
rows, err := db.Query(`SELECT p.estado, p.total, … WHERE p.codigo = $1 ORDER BY l.linea`, "PED-00042")
```

**sqlc** va en la dirección contraria: escribes el SQL con un nombre, y `sqlc generate` escribe el
Go.

```sql
-- name: LineasDePedido :many
SELECT p.estado, p.total::text AS total, l.linea, l.cantidad, l.precio_unit::text AS precio_unit
  FROM pedidos p JOIN pedido_lineas l ON l.pedido_id = p.id
 WHERE p.codigo = $1 ORDER BY l.linea;
```

```go
// Code generated by sqlc. DO NOT EDIT.
type LineasDePedidoRow struct {
	Estado     string
	Total      string
	Linea      int16
	Cantidad   int32
	PrecioUnit string
}
func (q *Queries) LineasDePedido(ctx context.Context, codigo string) ([]LineasDePedidoRow, error) {
```

- **Los tipos salen del esquema**: `smallint` a `int16`, `integer` a `int32`, sin que nadie los
  escriba. Si la consulta nombra una columna que no existe, `sqlc generate` falla **antes** de
  compilar.
- **El SQL sigue siendo tuyo**, entero y a la vista: es la versión en Go de lo que jOOQ hace en
  Java, con el código generado en vez del SQL.

**GORM** es el ORM más usado de Go. Con `Preload`, trae las líneas en una segunda consulta:

```go
db.Preload("Lineas", func(q *gorm.DB) *gorm.DB { return q.Order("linea") }).
	Where("codigo = ?", "PED-00042").First(&p)
```

```text
/opt/modulo/codigo/con_gorm.go:43
[0.516ms] [rows:3] SELECT * FROM "pedido_lineas" WHERE "pedido_lineas"."pedido_id" = 42 ORDER BY linea
/opt/modulo/codigo/con_gorm.go:43
[1.917ms] [rows:1] SELECT * FROM "pedidos" WHERE codigo = 'PED-00042' ORDER BY "pedidos"."id" LIMIT 1
```

Y lo que recibió el servidor de esas mismas dos consultas, con `log_statement` activado para
`tienda_app` y retirado después:

```text
LOG:  execute stmtcache_89cc351cb0a3ba49fd91a31eb22477c57fed7b0066ce162a: SELECT * FROM "pedidos" WHERE codigo = $1 ORDER BY "pedidos"."id" LIMIT $2
DETAIL:  Parameters: $1 = 'PED-00042', $2 = '1'
LOG:  execute stmtcache_72c18f45120019410de4e97d6bd274c0d6fc834a60430284: SELECT * FROM "pedido_lineas" WHERE "pedido_lineas"."pedido_id" = $1 ORDER BY linea
DETAIL:  Parameters: $1 = '42'
```

- **El log de GORM enseña los valores pegados en el texto, y el servidor recibió `$1` y `$2`**: GORM
  sustituye los valores solo para que el log se lea. Copiar esa línea del log a una consola
  funciona; concluir de ella que GORM concatena, no.
- **El log de GORM ordena las consultas al revés**: registra la del pedido al terminar su `Preload`,
  y el servidor dice que se ejecutó primero.
- **`First` añade `ORDER BY "pedidos"."id" LIMIT 1`**, que nadie escribió: pedir «el primero» obliga
  a decir por qué columna. **`SELECT *`** trae todas las columnas, aunque el programa use cuatro.

**Cuánto cuesta:** `database/sql`, una capa de interfaz sobre pgx que pierde parte de sus tipos
propios; sqlc, un paso de generación y el esquema copiado donde la herramienta lo lea; GORM, el SQL
generado con sus añadidos. **Cuándo sí:** sqlc, cuando el SQL es el protagonista; GORM, cuando lo
son las estructuras; `database/sql`, cuando el código tiene que poder cambiar de motor.

---

## 6. 🧭 Cómo se elige

**La misma decisión en los cuatro lenguajes**, con la tabla de equivalencias que resume `05` y este
capítulo:

| Si quieres… | Java | Python | TypeScript | Go |
|---|---|---|---|---|
| SQL a mano y el mapeo hecho | `JdbcClient` | SQLAlchemy Core | `pg` | `database/sql`, pgx |
| SQL comprobado antes de ejecutar | jOOQ | SQLAlchemy Core | Kysely | **sqlc** |
| Objetos y el SQL generado | Hibernate | SQLAlchemy ORM | Drizzle, Prisma | GORM |

- **Lo que se comprueba y cuándo** es la diferencia que importa: sqlc y jOOQ con clases generadas
  fallan antes de ejecutar; Kysely y Drizzle, al compilar TypeScript, si sus tipos dicen la verdad;
  el SQL a mano, en producción.
- **Todos acaban en el mismo protocolo**: `$1` y el valor aparte. La diferencia entre un ORM y el
  SQL a mano no está en la seguridad, está en quién decide cuántas consultas se hacen.

> **Veredicto:** en los cuatro lenguajes hay una capa para cada nivel, y la pregunta es la misma que
> en Java: dónde quieres ver el SQL. La respuesta madura suele ser dos capas a la vez: un ORM o un
> constructor para el caso común, y SQL a mano para lo que el ORM no expresa bien.

---

## 7. 📜 Estándar, motor y convención

> **📜 Estándar o motor.** ISO/IEC 9075 es de pago y **no he verificado sus cláusulas**. Nada de este
> capítulo es de la norma: son bibliotecas de lenguaje sobre el protocolo de PostgreSQL.

| Afirmación | Estándar | PostgreSQL 18.6 | Bibliotecas |
|---|---|---|---|
| El valor viaja aparte del SQL | No lo define | Protocolo extendido | Las siete del capítulo |
| El log del cliente enseña lo que recibe el servidor | — | Su log, con `log_statement` | **GORM, no**: sustituye los valores para leer |
| Una colección se carga al recorrerla | — | — | SQLAlchemy ORM, como Hibernate; GORM solo con `Preload` |
| El esquema del código coincide con el de la base | — | — | Solo si se genera desde ella o se migra con el ORM |
| Pedir «el primero» ordena por algo | — | Sin `ORDER BY` no hay orden | GORM añade `ORDER BY id` |

**Convención, las dos que más se repiten.** *«Con un ORM no hay inyección SQL»* — no la hay en lo
que el ORM parametriza; la hay en cuanto se le pasa un fragmento de SQL como texto, como el
`Order("linea")` de GORM con un valor del usuario. Y *«el log de mi ORM es lo que ejecuta la base»*
— el de GORM no lo es; el que lo es, es el del servidor.

---

## ⚠️ Errores frecuentes

| Se dice | Lo preciso |
|---|---|
| "SQLAlchemy es un ORM" | Son dos bibliotecas: Core, que es SQL, y el ORM encima |
| "La lectura con SQLAlchemy no abre transacción" | `BEGIN (implicit)` al empezar y `ROLLBACK` al cerrar, heredados de psycopg |
| "Kysely sabe el esquema de la base" | Sabe el que le escribes como tipos. Si mienten, compila y falla en producción |
| "`mode: "number"` en un `bigint` de Drizzle es gratis" | Pierde precisión por encima de 2⁵³ |
| "GORM concatena los valores, lo dice su log" | El log los sustituye para leer; el servidor recibió `$1` |
| "`First` de GORM trae la primera fila" | Trae la de menor `id`, con un `ORDER BY` que añade él |
| "sqlc es un ORM" | Es un generador: el SQL es tuyo y el código Go lo escribe la herramienta |

---

## 📚 Para profundizar

- **Documentación** — SQLAlchemy 2.0, «Working with Engines and Connections»: Core, transacciones y
  `echo`. <https://docs.sqlalchemy.org/en/20/core/connections.html>
- **Documentación** — SQLAlchemy 2.0, «Relationship Loading Techniques»: perezosa, `selectinload` y
  `joinedload`. <https://docs.sqlalchemy.org/en/20/orm/queryguide/relationships.html>
- **Documentación** — Kysely, «Getting started»: el esquema como tipos.
  <https://kysely.dev/docs/getting-started>
- **Documentación** — Drizzle ORM, «Select»: el constructor de consultas.
  <https://orm.drizzle.team/docs/select>
- **Documentación** — sqlc, la documentación del proyecto: consultas con nombre y código generado.
  <https://docs.sqlc.dev/en/latest/>
- **Documentación** — GORM, «Preloading (Eager Loading)». <https://gorm.io/docs/preload.html>
- **Documentación** — pgx, «stdlib»: pgx como driver de `database/sql`.
  <https://pkg.go.dev/github.com/jackc/pgx/v5/stdlib>
- **Documentación** — GORM, «Security»: los métodos que no escapan su entrada, `Order` incluido.
  <https://gorm.io/docs/security.html>

---

## 🧠 Preguntas

1. ¿Qué son SQLAlchemy Core y el ORM de SQLAlchemy, y cómo se relacionan? 🟢
2. ¿Qué hace sqlc, en una frase? 🟢
3. ¿De dónde saca Kysely el esquema de la base? 🟢
4. ¿Qué hace `Preload` en GORM? 🟢
5. Distingue sqlc de jOOQ: qué escribe el programador y qué genera la herramienta en cada uno. 🟡
6. ¿Por qué el log de SQLAlchemy muestra `BEGIN (implicit)` y un `ROLLBACK` en una lectura? 🟡
7. El log de GORM enseña `WHERE codigo = 'PED-00042'`. ¿Concatenó GORM el valor? Di cómo lo
   compruebas, y si lo que ves es cosa del motor o de la biblioteca. 🟡
8. ¿Qué diferencia hay entre usar `pgx` directamente y usarlo a través de `database/sql`? 🟡
9. ¿Está alguna de estas bibliotecas en el estándar SQL? Responde para la norma, para el protocolo
   de PostgreSQL y para las bibliotecas. 🟡
10. En Kysely, un compañero declara `id: number` para una columna `bigint`. ¿Qué pasa al compilar y
    qué pasa al ejecutar? 🟠
11. ¿Por qué `First` de GORM añade un `ORDER BY` que nadie escribió, y qué cuesta en una tabla
    grande sin índice por esa columna? 🟠
12. ¿Qué gana un equipo de Go al pasar de SQL a mano a sqlc, y qué paga? 🟠
13. Tu servicio en Python usa el ORM de SQLAlchemy y los informes tardan. ¿Qué harías antes de
    reescribirlos, y con qué parte de SQLAlchemy los reescribirías? 🟠
14. Explica por qué la frase «con un ORM no hay inyección SQL» es falsa, con un ejemplo de GORM. 🟠
15. Diseña la capa de datos de un servicio de pedidos en TypeScript: qué biblioteca usarías, cómo
    mantendrías el esquema del código igual que el de la base, y cómo verías el SQL real. 🔴
16. Diagnostica: un servicio en Go con GORM hace una consulta `SELECT *` por cada pedido de un
    listado de cien. Da el mecanismo, cómo lo confirmarías en el servidor y la corrección. 🔴
17. Un equipo tiene servicios en los cuatro lenguajes del corpus y quiere una regla común de acceso
    a datos. Escríbela en cinco puntos, válida para los cuatro. 🔴

---

**Anterior:** [`05`](05-java.md) — el ecosistema de Java · **Siguiente:**
[`07`](07-clientes-de-redis-y-mongodb.md) — los clientes de Redis y MongoDB · **Relacionado:**
[`03`](03-mapeo-de-tipos.md) — los tipos que los esquemas de Kysely y Drizzle tienen que respetar ·
[`04`](04-transacciones-y-resultados-grandes.md) — la transacción implícita que SQLAlchemy hereda.
