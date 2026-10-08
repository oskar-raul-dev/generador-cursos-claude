# Bloque 10 — Interfaz con los lenguajes

> Lo que pasa entre tu código y el motor, en Java, Python, TypeScript y Go: el driver, la conexión y
> el *pool*, las consultas parametrizadas, el mapeo de tipos, las transacciones y los resultados
> grandes, y las bibliotecas de cada ecosistema. Al terminarlo sabes explicar qué hace el *pool*
> cuando se queda sin conexiones, por qué un parámetro corta una inyección de raíz, y qué entrega
> cada driver por cada columna.
> **Vigencia:** 27 de septiembre de 2026.

---

## 📖 Orden de lectura

`01` a `04` en orden, con el mismo ejemplo en los cuatro lenguajes; `05` y `06` recorren cada
ecosistema capa por capa; `07` se puede leer suelto.

| # | Documento | Preguntas | Qué cubre |
|---|---|---|---|
| `01` | [El driver, la conexión y el *pool*](01-el-driver-la-conexion-y-el-pool.md) | 18 | Qué hace el driver, por qué una conexión es un proceso del servidor, y qué hace cada *pool* cuando se agota: esperar, fallar o esperar para siempre |
| `02` | [Parametrizadas e inyección](02-parametrizadas-e-inyeccion.md) | 17 | La inyección provocada contra la tienda, qué recibe el servidor de cada driver y las cuatro cosas que un parámetro no protege |
| `03` | [Mapeo de tipos](03-mapeo-de-tipos.md) | 18 | La misma fila en cuatro lenguajes: el dinero como cadena, el entero que no cabe, la fecha desplazada y el nulo que es un cero o un error |
| `04` | [Transacciones y resultados grandes](04-transacciones-y-resultados-grandes.md) | 18 | Quién abre la transacción, la excepción tragada que confirma, y cómo se recorre un millón de filas sin cargarlas en memoria |
| `05` | [Java](05-java.md) | 18 | JDBC y HikariCP, `JdbcClient`, jOOQ, MyBatis y JPA con Hibernate; la propagación de Spring corrida; H2 y Derby |
| `06` | [Python, TypeScript y Go](06-python-typescript-y-go.md) | 17 | SQLAlchemy Core y ORM, Kysely y Drizzle, `database/sql`, sqlc y GORM, con el SQL que de verdad llega a la base |
| `07` | [Clientes de Redis y MongoDB](07-clientes-de-redis-y-mongodb.md) | 16 | El mismo pedido en Redis y en MongoDB desde los cuatro lenguajes, y qué hace cada cliente cuando el servidor no está |
| `08` | [Simulación de entrevista](08-simulacion-de-entrevista.md) | 26 `S#` + 4 escenarios | Las preguntas del bloque mezcladas, con cronómetro, y cuatro escenarios |
| `09` | [Respuestas](09-respuestas.md) | 152 | Todas las respuestas del bloque, con el enunciado literal y en tres capas |

**122 preguntas** en los siete capítulos y **30 más** en la simulación, todas con respuesta en
[`09`](09-respuestas.md).

> **📝 Longitud y entorno.** Los siete quedan entre 320 y 481 líneas; `05` y `06` están declarados
> densos. Cada lenguaje corre en su contenedor del perfil `lenguajes` del `compose`, con las
> versiones de cada biblioteca fijadas en §4.6 del documento de dominio, y el código de los
> ejemplos vive en `13-laboratorio/entorno/codigo/`.

---

## 🧩 Qué asume leído

El bloque [`04`](../04-transacciones-y-concurrencia/README.md) —el ámbito de una transacción es la
conexión, de `04/01`, y las transacciones largas de `04/05`— y
[`02/01`](../02-sql/01-familias-del-lenguaje-y-tipos.md), donde se elige el tipo de cada columna
que `03` ve llegar a cada lenguaje.

---

## 🔑 Dueños de concepto de este bloque

| Concepto | Dueño |
|---|---|
| **Pool de conexiones** | `10/01` — lo usa todo el corpus |
| **Inyección SQL** | `10/02` — lo usa todo el corpus |
| Mapeo de tipos por lenguaje | `10/03` |
| Transacciones desde el código y cursores | `10/04` |
| Las capas de acceso a datos de Java | `10/05` |
| Las capas de acceso a datos de Python, TypeScript y Go | `10/06` |
| Clientes de Redis y MongoDB, y su comportamiento sin servidor | `10/07` |

---

## 🧭 Si el calendario aprieta

**`01` y `02`.** El *pool* y la inyección son las dos preguntas de acceso a datos que llegan a
cualquier entrevista de backend, sea cual sea el lenguaje. Después, el capítulo de tu lenguaje:
`05` si el puesto es Java, `06` si no.

---

**Anterior:** [`09`](../09-otros-modelos/README.md) · **Siguiente bloque:**
[`11 — ORMs`](../11-orms/README.md) · **Volver:** [README del corpus](../README.md).
