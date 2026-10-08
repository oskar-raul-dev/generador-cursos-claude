# 02 — El problema N+1

> Cómo se produce el N+1 —una consulta para la lista y otra por cada elemento—, cómo se detecta en
> el log del motor en vez de adivinarlo, y las cuatro formas de corregirlo: un `JOIN` que trae todo,
> una segunda consulta con `IN`, consultas por lotes, y una proyección que no crea objetos. Corrido
> en los cuatro lenguajes con los 52 pedidos de `CLI-00311`, contando las consultas en el servidor.
> **Asume leído:** [`01`](01-el-desajuste-y-los-dos-patrones.md) —la navegación de objetos, que es
> donde nace— y [`10/05`](../10-interfaz-con-los-lenguajes/05-java.md) §5, donde Hibernate ya hizo
> una consulta de más al recorrer las líneas. **Vigencia:** 24 de septiembre de 2026.

---

## Salto rápido

- [1. El problema](#1--el-problema) · [2. Cómo se produce](#2--cómo-se-produce)
- [3. Cómo se detecta: el log del motor](#3--cómo-se-detecta-el-log-del-motor) · [4. Las cuatro
  correcciones](#4--las-cuatro-correcciones)
- [5. Los números, en los cuatro lenguajes](#5-️-los-números-en-los-cuatro-lenguajes) · [6. Cómo se
  elige](#6--cómo-se-elige)
- [7. Estándar, motor y convención](#7--estándar-motor-y-convención) · [Errores
  frecuentes](#️-errores-frecuentes) · [Para profundizar](#-para-profundizar) ·
  [Preguntas](#-preguntas)

---

## 1. 🎯 El problema

La ficha de cliente de la tienda enseña los pedidos de `CLI-00311` con sus líneas. En desarrollo,
con una base de pruebas de cinco pedidos, tarda 10 ms. En producción, el cliente tiene 52 pedidos y
la página tarda diez veces más; con uno de 500, se cae por tiempo de espera. Nadie tocó la consulta,
porque **no hay una consulta: hay 53**.

```text
¿Cuántas consultas hace de verdad esta página, y dónde se ve?
¿Por qué es culpa del código que recorre los objetos y no del ORM?
¿Cuál de las cuatro correcciones conviene, y qué cuesta cada una?
```

El nombre viene de la cuenta: **una** consulta trae la lista de N elementos, y después **N**
consultas traen algo de cada uno. Es el fallo de rendimiento más frecuente de cualquier aplicación
con ORM, y la frase que lo resume para una entrevista es la del README de la raíz: **el N+1 no es
culpa del ORM**, es culpa de recorrer objetos sin decir qué se va a necesitar.

> **📝 Contexto.** Todo está **corrido** en los contenedores de lenguaje, con los 52 pedidos y las
> 175 líneas de `CLI-00311`. Las consultas se cuentan **en el log del servidor**, con `log_statement
> = 'all'` activado para `tienda_app` durante cada medición y retirado después. Los recuentos de
> Hibernate y SQLAlchemy incluyen las consultas con que inspeccionan el servidor al arrancar —7 y
> 3—, y la tabla de §5 las descuenta. Los milisegundos son de esta máquina, con la base a un salto
> de red local. **Longitud:** capítulo denso, declarado en §4.6 de la guía de estilo.

---

## 2. 🧱 Cómo se produce

**Qué es:** el código pide una lista y después, dentro de un bucle, toca en cada elemento algo que
no se cargó con la lista. Con carga perezosa —el comportamiento por defecto de las colecciones en
Hibernate y SQLAlchemy—, **cada acceso es una consulta**:

```java
var pedidos = sesion.createQuery("from Pedido p where p.clienteId = 311", Pedido.class).getResultList();
for (var p : pedidos) lineas += p.lineas.size();      // recorrer dispara la carga perezosa
```

```python
pedidos = sesion.scalars(select(Pedido).where(Pedido.cliente_id == 311)).all()
lineas = sum(len(p.lineas) for p in pedidos)           # recorrer dispara la carga perezosa
```

En GORM y en Drizzle no hay carga perezosa, y el N+1 lo escribe el propio código, a la vista:

```go
db.Where("cliente_id = ?", 311).Find(&pedidos)
for i := range pedidos {
	db.Where("pedido_id = ?", pedidos[i].ID).Find(&pedidos[i].Lineas)   // una consulta por pedido
}
```

- **La línea que dispara las consultas no parece una consulta**: `p.lineas.size()` o `len(p.lineas)`
  son lecturas de un atributo. Por eso el N+1 sobrevive a las revisiones de código.
- **En GORM y Drizzle es más visible y no menos frecuente**: el bucle con una consulta dentro es el
  mismo error, sin la excusa de la carga perezosa.

**Quién lo manda:** **biblioteca** la carga perezosa por defecto; **código** el bucle. **Cuánto
cuesta:** un viaje de ida y vuelta por elemento —en producción, con la base en otra máquina, cada
uno cuesta lo que la red—, un análisis de consulta por elemento en el servidor, y conexiones
retenidas más tiempo.

---

## 3. 🩺 Cómo se detecta: el log del motor

**Qué es:** el N+1 no se ve en el código ni en el tiempo total de una prueba local: se ve **contando
sentencias en el servidor**. Con `log_statement = 'all'` para el rol de la aplicación, la página
perezosa deja en el log del servidor esto, una vez por pedido, con cada entrada seguida de su `FROM`
y su `WHERE`, recortados aquí:

```text
LOG:  execute <unnamed>: SELECT pedido_lineas.pedido_id AS pedido_lineas_pedido_id, pedido_lineas.linea AS pedido_lineas_linea, pedido_lineas.cantidad AS pedido_lineas_cantidad
DETAIL:  Parameters: $1 = '701756'
LOG:  execute <unnamed>: SELECT pedido_lineas.pedido_id AS pedido_lineas_pedido_id, pedido_lineas.linea AS pedido_lineas_linea, pedido_lineas.cantidad AS pedido_lineas_cantidad
DETAIL:  Parameters: $1 = '809038'
LOG:  execute <unnamed>: SELECT pedido_lineas.pedido_id AS pedido_lineas_pedido_id, pedido_lineas.linea AS pedido_lineas_linea, pedido_lineas.cantidad AS pedido_lineas_cantidad
DETAIL:  Parameters: $1 = '438932'
```

- **La firma es inconfundible**: la misma sentencia, muchas veces seguidas, con un solo parámetro
  que cambia. En esta corrida, **52** entradas contra `pedido_lineas`, una por pedido.
- **`log_statement` se activa para un rol y un rato**, como aquí: registrar todo en producción llena
  el disco. La alternativa permanente es `pg_stat_statements`, que agrupa las sentencias iguales y
  cuenta cuántas veces se ejecutó cada una; es una extensión que el entorno del corpus no carga, y
  su lugar en el corpus es el bloque 06, de operación.

> **🩺 Diagnóstico.** Ante una página lenta con ORM, lo primero no es el plan de ninguna consulta: es
> **cuántas consultas** hace. Si el número crece con el tamaño de la lista, es un N+1, y el plan de
> cada una de ellas probablemente es perfecto.

---

## 4. 🧱 Las cuatro correcciones

**Qué es:** cuatro formas de decir por adelantado lo que se va a necesitar. Cada una en la
biblioteca que la tiene:

| Corrección | Qué SQL produce | Hibernate | SQLAlchemy | GORM | Drizzle |
|---|---|---|---|---|---|
| **1. Todo en un `JOIN`** | Una consulta con la lista y sus hijos | `join fetch` | `joinedload` | — | Consulta relacional |
| **2. Segunda consulta con `IN`** | Dos: la lista, y todos los hijos de golpe | — | `selectinload` | `Preload` | — |
| **3. Por lotes** | 1 + N ÷ tamaño del lote, cada una con `IN` | `default_batch_fetch_size` | — | — | — |
| **4. Proyección** | Una, sin crear entidades | Consulta de columnas | Core | `Raw` con `JOIN` | `select` con `innerJoin` |

La primera, en JPQL y en SQLAlchemy:

```java
"select distinct p from Pedido p left join fetch p.lineas where p.clienteId = 311"
```

```python
select(Pedido).where(Pedido.cliente_id == 311).options(joinedload(Pedido.lineas))
```

- **El `JOIN` repite las columnas del padre en cada fila del hijo**: 52 pedidos con 175 líneas
  llegan como 175 filas, y el ORM las vuelve a agrupar —por eso el `distinct` de JPQL y el
  `unique()` de SQLAlchemy—. Con dos colecciones a la vez, el `JOIN` multiplica: es un producto
  cartesiano.
- **Drizzle resuelve el `JOIN` de otra forma**, y conviene verlo: su consulta relacional genera
  **una sola sentencia** con una subconsulta lateral que devuelve las líneas de cada pedido ya
  agregadas en JSON:

```text
Query: select "pedidos"."id", "pedidos"."codigo", "pedidos"."cliente_id", "pedidos_lineas"."data" as "lineas" from "pedidos" "pedidos" left join lateral (select coalesce(json_agg(json_build_array("pedidos_lineas"."pedido_id", "pedidos_lineas"."linea", "pedidos_lineas"."cantidad")), '[]'::json) as "data" from "pedido_lineas" "pedidos_lineas" where "pedidos_lineas"."pedido_id" = "pedidos"."id") "pedidos_lineas" on true where "pedidos"."cliente_id" = $1 -- params: [311]
```

- **Una fila por pedido, sin repetir el padre**, a cambio de que las líneas viajen como JSON, con
  las trampas de tipos de [`10/03`](../10-interfaz-con-los-lenguajes/03-mapeo-de-tipos.md) §4 si
  hubiera importes dentro.

**Cuánto cuesta cada una:** el `JOIN`, filas repetidas y el riesgo del producto cartesiano; el `IN`,
una segunda consulta y una lista de identificadores que crece con la página; los lotes, varias
consultas y un tamaño que ajustar; la proyección, renunciar a las entidades, que ya no se pueden
modificar ni navegar.

---

## 5. ⚖️ Los números, en los cuatro lenguajes

**Qué es:** las mismas 175 líneas de los 52 pedidos de `CLI-00311`, leídas de cada forma.
«Consultas» es lo que contó el servidor, descontadas las 7 de arranque de Hibernate y las 3 de
SQLAlchemy:

| Lenguaje | Forma | Consultas | Tiempo |
|---|---|---|---|
| Java, Hibernate | Perezosa | **53** | 347 ms |
| | `join fetch` | 1 | 286 ms |
| | Lotes de 16 | 5 | 267 ms |
| | Proyección | 1 | 297 ms |
| Python, SQLAlchemy | Perezosa | **53** | 85 ms |
| | `joinedload` | 1 | 60 ms |
| | `selectinload` | 2 | 61 ms |
| | Core, con `JOIN` | 1 | 51 ms |
| Go, GORM | Bucle | **53** | 87 ms |
| | `Preload` | 2 | 46 ms |
| | `Raw` con `JOIN` | 1 | 44 ms |
| TypeScript, Drizzle | Bucle | **53** | 97 ms |
| | Consulta relacional | 1 | 85 ms |
| | `innerJoin` | 1 | 71 ms |

- **53 en los cuatro lenguajes**: 1 para la lista y 52 para las líneas. Los lotes de Hibernate dejan
  **5** —1 más ⌈52 ÷ 16⌉ = 4—, y `selectinload` y `Preload`, **2**.
- **Los milisegundos aquí engañan a favor del N+1**: la base está en la misma máquina y un viaje de
  ida y vuelta cuesta décimas de milisegundo. Aun así, la versión ingenua es la más lenta en los
  cuatro. Con la base a 1 ms de red, las 52 consultas de más serían 52 ms más por página; con 500
  pedidos, medio segundo.
- **El tiempo de Hibernate incluye su arranque en frío**, con la compilación JIT a medio hacer: lo
  comparable entre sus filas es la diferencia, no el valor absoluto.

> **Veredicto:** el N+1 se mide en **número de consultas**, no en milisegundos de una prueba local.
> Si crece con la lista, está ahí, aunque el tiempo todavía no duela.

---

## 6. 🧭 Cómo se elige

**El criterio, en tres preguntas:**

```text
1. ¿Necesitas entidades para modificarlas, o solo datos para enseñarlos?
     -> solo datos: proyección. Una consulta, sin sesión que llenar.
2. ¿Traes una colección o varias?
     -> una: JOIN. Varias: una segunda consulta con IN por colección, o el producto cartesiano te come.
3. ¿La lista tiene un tamaño acotado (una página)?
     -> sí: cualquiera de las dos. No: IN o lotes, para no mandar una lista infinita en un JOIN.
```

- **Cambiar la carga por defecto a ansiosa no es la corrección**: carga las líneas en cada lectura
  de un pedido, las necesite quien las necesite. La decisión es **por consulta**, y el siguiente
  capítulo es sobre eso.
- **La proyección es la que más se olvida y la que mejor rinde para listados e informes**: es el
  terreno de [`04`](04-constructores-y-cuando-no-usar-orm.md) §6.

---

## 7. 📜 Estándar, motor y convención

> **📜 Estándar o motor.** ISO/IEC 9075 no habla de ORM. Lo que se afirma es de cada biblioteca, y el
> método de detección —`log_statement`— es de PostgreSQL.

| Afirmación | Estándar | PostgreSQL 18.6 | Bibliotecas del corpus |
|---|---|---|---|
| Existe la carga perezosa | No aplica | — | Hibernate y SQLAlchemy, por defecto en colecciones; GORM y Drizzle no |
| Se ve cuántas consultas hace una página | — | `log_statement`, o `pg_stat_statements` | Cada una tiene su log, que puede no coincidir con el del servidor |
| Hay forma de traerlo todo en una consulta | — | `JOIN`, o `LATERAL` con `json_agg` | Las cuatro, cada una a su manera |
| El N+1 lo produce el ORM | — | — | **No**: lo produce el código que recorre sin decir qué necesita |

**Convención, las dos que más se repiten.** *«El N+1 es un problema de Hibernate»* — lo corrido dice
53 consultas en los cuatro lenguajes, con y sin carga perezosa. Y *«se arregla poniendo la relación
en ansiosa»* — se cambia un N+1 por traer las líneas en cada lectura, incluidas las que no las
necesitan.

---

## ⚠️ Errores frecuentes

| Se dice | Lo preciso |
|---|---|
| "Mi página hace una consulta" | Hace las que diga el log del servidor: aquí, 53 |
| "Sin carga perezosa no hay N+1" | GORM y Drizzle no la tienen, y el bucle hizo 53 igual |
| "Lo arreglo con `FetchType.EAGER`" | Carga las líneas siempre, en cada lectura, las necesites o no |
| "El `JOIN` es siempre la mejor corrección" | Repite el padre en cada fila, y con dos colecciones produce un producto cartesiano |
| "En local va rápido, así que no hay N+1" | En local cada consulta cuesta décimas de milisegundo; en producción, la red |
| "`log_statement = 'all'` en producción para vigilarlo" | Llena el disco; se activa un rato, para un rol, o se usa `pg_stat_statements` |

---

## 📚 Para profundizar

- **Documentación** — Hibernate ORM 7.4, «User Guide», capítulo de *fetching*: `join fetch`, lotes y
  estrategias. <https://docs.hibernate.org/orm/7.4/userguide/html_single/>
- **Documentación** — SQLAlchemy 2.0, «Relationship Loading Techniques»: perezosa, `joinedload` y
  `selectinload`. <https://docs.sqlalchemy.org/en/20/orm/queryguide/relationships.html>
- **Documentación** — GORM, «Preloading (Eager Loading)». <https://gorm.io/docs/preload.html>
- **Documentación** — Drizzle ORM, «Relational queries»: la consulta con `with`.
  <https://orm.drizzle.team/docs/rqb>
- **Documentación** — PostgreSQL 18, «Error Reporting and Logging»: `log_statement` y
  `log_min_duration_statement`. <https://www.postgresql.org/docs/18/runtime-config-logging.html>
- **Documentación** — PostgreSQL 18, «pg_stat_statements»: agrupar y contar sentencias iguales.
  <https://www.postgresql.org/docs/18/pgstatstatements.html>

---

## 🧠 Preguntas

1. ¿Qué es el problema N+1, en una frase? 🟢
2. ¿Dónde se detecta un N+1 con certeza? 🟢
3. Nombra las cuatro correcciones del N+1. 🟢
4. ¿Qué parámetro de Hibernate activa la carga por lotes? 🟢
5. Distingue `joinedload` de `selectinload` en SQLAlchemy: cuántas consultas hace cada una y qué
   SQL. 🟡
6. ¿Por qué GORM y Drizzle también tienen N+1 si no tienen carga perezosa? 🟡
7. ¿Qué hace la consulta relacional de Drizzle para traer todo en una sentencia? ¿Lo fija el
   estándar o es cosa del motor? 🟡
8. ¿Está alguna de estas correcciones en el estándar SQL? Responde para la norma, para PostgreSQL y
   para las bibliotecas. 🟡
9. Con 52 pedidos y lotes de 16, ¿cuántas consultas hace Hibernate? Explica la cuenta. 🟡
10. ¿Por qué el tiempo de una prueba local no delata un N+1, y qué número sí lo hace? 🟠
11. ¿Qué pasa si corriges con un `JOIN` una página que necesita dos colecciones de cada pedido? 🟠
12. ¿Por qué poner la relación en ansiosa no es la corrección, y cuál es? 🟠
13. ¿Cuándo elegirías una proyección en vez de cargar entidades? 🟠
14. ¿Qué cuesta dejar `log_statement = 'all'` activado en producción, y qué usarías en su lugar? 🟠
15. Diagnostica: una ficha de cliente tarda 40 ms con clientes nuevos y 4 s con los antiguos. Da la
    hipótesis, la prueba que la confirma y la corrección. 🔴
16. Escribe, en el lenguaje que prefieras, la carga de los pedidos de un cliente con sus líneas en
    dos consultas como mucho, y di qué SQL genera. 🔴
17. Diseña una regla de revisión de código que atrape el N+1 antes de producción en un equipo que
    usa Hibernate. 🔴

---

**Anterior:** [`01`](01-el-desajuste-y-los-dos-patrones.md) — el desajuste y los dos patrones ·
**Siguiente:** [`03`](03-carga-caches-y-la-sesion.md) — la carga, las cachés y la sesión ·
**Relacionado:** [`10/05`](../10-interfaz-con-los-lenguajes/05-java.md) §5 — la primera consulta de
más de Hibernate · [`10/06`](../10-interfaz-con-los-lenguajes/06-python-typescript-y-go.md) §5 — el
`Preload` de GORM.
