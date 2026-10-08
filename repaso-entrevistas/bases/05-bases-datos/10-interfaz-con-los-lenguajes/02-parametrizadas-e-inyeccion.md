# 02 — Parametrizadas e inyección

> Cómo ocurre una inyección SQL, provocada contra la tienda; por qué el parámetro la corta de raíz y
> no como un escape más cuidadoso; qué recibe de verdad el servidor desde cada uno de los cuatro
> drivers; y las cuatro cosas que un parámetro **no** protege. Este capítulo es el dueño de la
> inyección SQL en todo el corpus. **Asume leído:** [`01`](01-el-driver-la-conexion-y-el-pool.md) —
> de ahí vienen los drivers, los marcadores `?`, `%s` y `$1`, y los contenedores donde se corre.
> **Vigencia:** 23 de septiembre de 2026.

---

## Salto rápido

- [1. El problema](#1--el-problema) · [2. Por qué ocurre](#2--por-qué-ocurre)
- [3. El parámetro, en los cuatro lenguajes](#3--el-parámetro-en-los-cuatro-lenguajes) · [4. Lo que
  el parámetro no protege](#4--lo-que-el-parámetro-no-protege)
- [5. En el cliente o en el servidor](#5-️-en-el-cliente-o-en-el-servidor) · [6. La segunda línea: el
  mínimo privilegio](#6--la-segunda-línea-el-mínimo-privilegio)
- [7. Estándar, motor y convención](#7--estándar-motor-y-convención) · [Errores
  frecuentes](#️-errores-frecuentes) · [Para profundizar](#-para-profundizar) ·
  [Preguntas](#-preguntas)

---

## 1. 🎯 El problema

El panel de soporte tiene un buscador de pedidos por código. Alguien lo escribió así, en Python, y
funciona con cualquier código que se le dé:

```python
sql = f"SELECT codigo, estado FROM pedidos WHERE codigo = '{codigo}'"
filas = con.execute(sql).fetchall()
```

Corrido con tres entradas —la que se espera y dos que no—:

```text
concatenado  'PED-00042'                      -> 1 filas
concatenado  "PED-00042' OR '1'='1"           -> 1000000 filas
concatenado  "x'; DROP TABLE pagos; --"       -> InsufficientPrivilege: must be owner of table pagos
```

- **La segunda devuelve el millón de pedidos.** El usuario no pidió un pedido: reescribió la
  consulta. Con una tabla de clientes, eso son sus correos.
- **La tercera intentó borrar `pagos`, y el motor la ejecutó.** No la paró el código: la paró que
  `tienda_app` no es dueña de la tabla. `pagos` sigue en sus 820 000 filas, y el capítulo vuelve a
  esto en §6.

```text
¿Por qué un texto del usuario acaba ejecutándose como SQL?
¿Qué cambia exactamente cuando se usa un parámetro, y dónde se ve?
¿Qué sigue sin proteger el parámetro?
```

> **📝 Contexto.** Todo está **corrido** en los contenedores de lenguaje del entorno. Para ver qué
> recibe el servidor, §3 activa `log_statement = 'all'` solo para `tienda_app`, con `ALTER ROLE`, y
> lo retira al terminar con `ALTER ROLE tienda_app RESET log_statement`; nada más cambia en el
> servidor. La base queda intacta: el único intento de escritura es el `DROP` de arriba, y falló.

---

## 2. 🧱 Por qué ocurre

**Qué es:** una inyección ocurre cuando **un dato se mezcla con el código SQL antes de que el motor
lo analice**. El motor recibe un solo texto y no tiene forma de saber qué trozo escribió el
programador y qué trozo tecleó el usuario:

```text
plantilla   SELECT codigo, estado FROM pedidos WHERE codigo = '{codigo}'
entrada     PED-00042' OR '1'='1
resultado   SELECT codigo, estado FROM pedidos WHERE codigo = 'PED-00042' OR '1'='1'
                                                                         ^ la comilla del usuario
                                                                           cierra el literal
```

- **La comilla del usuario termina la cadena** que abrió el programador, y lo que viene detrás ya es
  SQL. Da igual lo cuidadoso que sea el código de alrededor: el daño está hecho cuando se concatena.
- **«Escapar las comillas a mano» es la solución equivocada.** Hay que acertar con todas las formas
  de escribir una comilla, con la codificación de la conexión y con las opciones del motor sobre
  barras invertidas; basta con fallar una vez. Es la **convención** que se sigue recitando, y la
  razón de que el remedio no sea escapar mejor, sino **no mezclar**.

**Quién lo manda:** nadie en particular: es una consecuencia de enviar SQL como texto, y le pasa
igual a todo motor. **Cuánto cuesta:** lo que valga lo que haya en la base, más lo que el rol de la
aplicación pueda hacer con ella.

---

## 3. 🧱 El parámetro, en los cuatro lenguajes

**Qué es:** el texto SQL se escribe **fijo**, con un marcador donde irá el dato, y el dato viaja
**por separado**. El motor analiza la consulta sin el dato y lo recibe después como un valor, que
nunca se interpreta como código. La misma búsqueda, con la entrada maliciosa, en los cuatro:

```java
ps = con.prepareStatement("SELECT codigo, estado FROM pedidos WHERE codigo = ?");
ps.setString(1, "PED-00042' OR '1'='1");
```

```python
con.execute("SELECT codigo, estado FROM pedidos WHERE codigo = %s", ("PED-00042' OR '1'='1",))
```

```typescript
await pool.query("SELECT codigo, estado FROM pedidos WHERE codigo = $1", ["PED-00042' OR '1'='1"]);
```

```go
con.Query(ctx, "SELECT codigo, estado FROM pedidos WHERE codigo = $1", "PED-00042' OR '1'='1")
```

Los cuatro imprimen `0 filas`: ningún pedido se llama así. Y esto es lo que el servidor escribió en
su log al recibir cada uno, sin la hora y el `pid` del principio de cada línea:

```text
-- Java, pgjdbc
LOG:  statement: SET application_name = 'PostgreSQL JDBC Driver'
LOG:  execute <unnamed>: SELECT codigo, estado FROM pedidos WHERE codigo = $1
DETAIL:  Parameters: $1 = 'PED-00042'' OR ''1''=''1'
-- Python, psycopg
LOG:  statement: BEGIN
LOG:  execute <unnamed>: SELECT codigo, estado FROM pedidos WHERE codigo = $1
DETAIL:  Parameters: $1 = 'PED-00042'' OR ''1''=''1'
LOG:  statement: COMMIT
-- TypeScript, pg
LOG:  execute <unnamed>: SELECT codigo, estado FROM pedidos WHERE codigo = $1
DETAIL:  Parameters: $1 = 'PED-00042'' OR ''1''=''1'
-- Go, pgx
LOG:  execute stmtcache_f3fc985e7329cfeabd3238246e1a073b9f25a97599c2b077: SELECT codigo, estado FROM pedidos WHERE codigo = $1
DETAIL:  Parameters: $1 = 'PED-00042'' OR ''1''=''1'
```

- **Los cuatro mandan `$1` en el texto y el valor aparte**, aunque en el código se escribiera `?` o
  `%s`: el driver traduce el marcador y usa el protocolo extendido de PostgreSQL, que separa el
  análisis de la consulta (*Parse*) de la entrega de los valores (*Bind*).
- **Las comillas dobladas del `DETAIL` son solo cómo el log imprime el valor**; lo que llegó al
  motor es la cadena tal cual, con sus comillas sueltas, como un dato.
- **Tres detalles de driver que conviene reconocer**: pgjdbc fija `application_name` al conectar;
  psycopg **abrió una transacción** que nadie pidió, con `BEGIN` y `COMMIT` alrededor de la
  consulta, que es su comportamiento por defecto y el tema de `04` de este bloque; y pgx preparó la
  sentencia con nombre, `stmtcache_…`, para reutilizar el análisis la próxima vez.

La misma prueba de §1 con parámetro, en Python:

```text
parametrizado 'PED-00042'                      -> 1 filas
parametrizado "PED-00042' OR '1'='1"           -> 0 filas
parametrizado "x'; DROP TABLE pagos; --"       -> 0 filas
```

**Quién lo manda:** **motor** para el protocolo que separa texto y valores; **driver** para la
traducción del marcador. **Cuánto cuesta:** nada; con la sentencia preparada y reutilizada, incluso
ahorra el análisis. **Cuándo sí:** todo valor que venga de fuera del código, sin excepción. **Cuándo
no:** no hay caso; lo que no se puede parametrizar es otra cosa, y es §4.

> **Veredicto:** un parámetro no escapa el dato mejor que tú: hace que el dato **nunca pase por el
> analizador de SQL**. Por eso es la única defensa que no depende de acertar.

---

## 4. 🩺 Lo que el parámetro no protege

**Qué es:** un parámetro ocupa el lugar de **un valor**. Todo lo que no es un valor —un nombre de
columna, un nombre de tabla, un comodín, una lista— se queda fuera, y ahí es donde vuelve la
inyección. Los cuatro casos, corridos en Python:

```text
ORDER BY %s   -> ['8400.77', '2302.98', '1211.28', '8846.28']
Identifier   -> ['307.28', '1211.28', '1806.90', '2302.98']
texto enviado: "total" LIMIT 4
LIKE '%' -> 1000000 filas
LIKE '\\%%' -> 0 filas
IN (%s) con 'PED-00042,PED-99999' -> 0 filas
= ANY(%s) con una lista -> 2 filas
FROM %s -> SyntaxError: syntax error at or near "$1"
```

- **`ORDER BY %s` no da error y no ordena.** El parámetro es el **valor** `'total'`, una constante
  igual para todas las filas: los cuatro totales salen desordenados. El orden por columna necesita
  el **nombre**, y un nombre no se parametriza: se elige de una **lista blanca** y se cita con la
  herramienta del driver, que en Python es `sql.Identifier` y produce `"total"`.
- **`LIKE %s` con un `%` del usuario devuelve toda la tabla.** El parámetro llegó intacto; lo que
  pasa es que `%` y `_` **son comodines del propio `LIKE`**. Si la búsqueda es literal, se escapan
  antes de pasarla —`\%`, `\_` y la propia barra—, y entonces el `%` escrito por el usuario no
  coincide con ningún código.
- **`IN (%s)` con una lista separada por comas es un solo valor**, la cadena
  `'PED-00042,PED-99999'`, y no coincide con nada. La forma correcta en PostgreSQL es `= ANY(%s)`
  con una lista del lenguaje, que viaja como un *array*: dos filas.
- **Un nombre de tabla directamente no admite parámetro**: el motor rechaza el `$1` donde espera un
  identificador, con error de sintaxis.

Cómo se cita un identificador en cada lenguaje, corrido con uno limpio y otro malicioso:

| Lenguaje | Herramienta | `total` | `to"tal; DROP` |
|---|---|---|---|
| Java | `Statement.enquoteIdentifier(nombre, true)` | `"total"` | **Rechaza**: `SQLException: Invalid name` |
| Python | `psycopg.sql.Identifier(nombre)` | `"total"` | `"to""tal; DROP"` |
| TypeScript | `pg.escapeIdentifier(nombre)` | `"total"` | `"to""tal; DROP"` |
| Go | `pgx.Identifier{nombre}.Sanitize()` | `"total"` | `"to""tal; DROP"` |

- **Citar no sustituye a la lista blanca**: un identificador bien citado que el usuario eligió sigue
  siendo una columna que el usuario eligió. La lista blanca decide **qué** se puede pedir; la cita
  garantiza que lo pedido **no se convierta en código**.
- **La quinta, que se menciona y no se corre aquí:** SQL construido dentro de la base, con `EXECUTE`
  en una función. La concatenación dentro de un procedimiento es la misma inyección un piso más
  abajo, y se evita con `format()` y sus marcadores `%I` y `%L`.

> **⚠️ Advertencia.** Los cuatro casos tienen algo en común: **ninguno da error con la entrada
> normal**. El `ORDER BY` desordenado pasa las pruebas si nadie mira el orden, y el `LIKE` con
> comodines parece funcionar con cualquier búsqueda que no los lleve.

---

## 5. ⚖️ En el cliente o en el servidor

**Qué es:** un driver puede cumplir la promesa del parámetro de dos formas. **En el servidor**:
manda el texto con `$1` y los valores aparte, como en §3. **En el cliente**: cita cada valor él
mismo y manda un único texto ya relleno. La segunda es segura si el driver cita bien, pero el motor
vuelve a recibir datos dentro del SQL.

| Driver | Por defecto | La otra forma, si existe |
|---|---|---|
| pgjdbc 42.7.13 | Servidor, visto en el log de §3 | — |
| psycopg 3.3.6 | Servidor, visto en el log de §3 | `ClientCursor`, en el cliente |
| `pg` 8.23.0 | Servidor, visto en el log de §3 | — |
| pgx 5.11.0 | Servidor, con sentencia preparada y cacheada | `QueryExecModeSimpleProtocol`, en el cliente |

- **psycopg 2 interpolaba siempre en el cliente**, y es lo que va a encontrar quien lea código
  Python de hace unos años. La documentación de psycopg 3 lo dice al explicar la migración, y añade
  el límite del enlace en el servidor: **solo funciona con `SELECT` y con la manipulación de
  datos**. Un `SET statement_timeout = %s` no admite parámetro; ahí se usa `set_config()` o se cita
  el literal con la herramienta del driver.
- **El modo simple de pgx** existe para intermediarios de conexión que no soportan sentencias
  preparadas, y su propia documentación recomienda evitarlo cuando se pueda.

**Quién lo manda:** **driver**, entero. **Cuánto cuesta:** el enlace en el servidor añade un viaje
de ida y vuelta la primera vez que se prepara una sentencia, y lo ahorra en las siguientes.

---

## 6. 🧱 La segunda línea: el mínimo privilegio

**Qué es:** la inyección del `DROP TABLE pagos` de §1 **llegó al motor y se ejecutó**. La paró el
catálogo, no el código: `tienda_app` puede leer y escribir filas, pero no es dueña de ninguna tabla,
y solo el dueño puede borrarla.

```text
concatenado  "x'; DROP TABLE pagos; --"       -> InsufficientPrivilege: must be owner of table pagos
```

- **Pasó porque psycopg envía una consulta sin parámetros por el protocolo simple**, que acepta
  varias sentencias separadas por `;`. Con parámetros, el protocolo extendido solo admite una:
  corrido con un `%s` y el `DROP` detrás, responde `cannot insert multiple commands into a prepared
  statement`.
- **El rol de la aplicación no debería poder hacer más de lo que la aplicación hace.** El entorno
  del corpus trae tres roles —`tienda_app`, `tienda_ro` y `tienda_admin`— precisamente para eso, y
  cómo se reparten los permisos es del bloque 06, de operación, que lista el [README de la
  raíz](../README.md).

**Cuánto cuesta:** nada en ejecución; cuesta disciplina, porque las migraciones necesitan un rol
distinto del que usa la aplicación. **Cuándo no basta:** nunca basta sola. Con una inyección de
lectura, `tienda_app` sigue leyendo todo lo que puede leer.

> **Veredicto:** el parámetro impide que el dato se vuelva código; el privilegio mínimo limita lo
> que el código puede hacer si algo se escapa. Son dos líneas distintas, y hacen falta las dos.

---

## 7. 📜 Estándar, motor y convención

> **📜 Estándar o motor.** ISO/IEC 9075 es de pago y **no he verificado sus cláusulas**. El SQL
> dinámico del estándar marca los parámetros con `?`; el protocolo que los separa del texto, en
> cambio, es de cada motor.

| Afirmación | Estándar | PostgreSQL 18.6 | Drivers del corpus |
|---|---|---|---|
| Hay marcador de parámetro | Sí, `?` en SQL dinámico | `$1`, `$2`… en el protocolo | `?`, `%s`, `$1`, `$1`, traducidos a `$1` |
| El valor viaja separado del texto | No lo define | Protocolo extendido: *Parse* y *Bind* | Los cuatro por defecto |
| Un identificador puede ser parámetro | No | No: error de sintaxis | Cada uno trae su forma de citarlo |
| Varias sentencias en una llamada | No lo define | Solo por el protocolo simple | psycopg sin parámetros lo usa |
| `%` y `_` son comodines en `LIKE` | Sí | Sí | El driver no los escapa |

**Convención, las dos que más se repiten.** *«Escapar las comillas evita la inyección»* — la evita
mientras aciertes con todas las formas de escribir una comilla; el parámetro la evita sin tener que
acertar. Y *«con consultas preparadas ya estoy a salvo»* — de la inyección por valores sí; de la que
entra por un nombre de columna, un comodín o una lista, no.

---

## ⚠️ Errores frecuentes

| Se dice | Lo preciso |
|---|---|
| "Escapo las comillas y listo" | Es la defensa que falla una vez de cada muchas. El parámetro no depende de escapar nada |
| "El `PreparedStatement` protege todo" | Protege los valores. Nombres de columna, comodines de `LIKE` y listas en `IN` siguen expuestos |
| "`ORDER BY ?` ordena por la columna que me pasen" | Ordena por una constante. No da error y no ordena |
| "`IN (?)` con una lista separada por comas funciona" | Es un único valor. En PostgreSQL se usa `= ANY(?)` con un *array* |
| "La inyección solo lee datos" | Por el protocolo simple admite varias sentencias: el `DROP` de §1 llegó al motor |
| "El log muestra las comillas dobladas, así que el driver escapó" | El driver no escapó nada: el valor viajó aparte y el log lo imprime citado para leerlo |
| "Si el rol no puede borrar, la inyección no importa" | Sigue pudiendo leer todo lo que el rol lee, que en una tienda son clientes y pagos |

---

## 📚 Para profundizar

- **Documentación** — PostgreSQL 18, «Message Flow»: el protocolo extendido, con *Parse*, *Bind* y
  *Execute*. <https://www.postgresql.org/docs/18/protocol-flow.html>
- **Documentación** — PostgreSQL 18, «Pattern Matching»: `LIKE`, sus comodines y la cláusula
  `ESCAPE`. <https://www.postgresql.org/docs/18/functions-matching.html>
- **Documentación** — psycopg 3, «Passing parameters to SQL queries»: marcadores y lo que nunca se
  debe hacer. <https://www.psycopg.org/psycopg3/docs/basic/params.html>
- **Documentación** — psycopg 3, «Differences from psycopg2»: el enlace en el servidor y sus
  límites. <https://www.psycopg.org/psycopg3/docs/basic/from_pg2.html>
- **Documentación** — psycopg 3, «sql – SQL string composition»: `Identifier`, `Literal` y
  `SQL.format`. <https://www.psycopg.org/psycopg3/docs/api/sql.html>
- **Documentación** — node-postgres, «Queries»: consultas parametrizadas y por qué no se concatena.
  <https://node-postgres.com/features/queries>
- **Documentación** — pgx, el paquete principal: los modos de ejecución y el protocolo simple.
  <https://pkg.go.dev/github.com/jackc/pgx/v5>
- **Referencia** — OWASP, «SQL Injection Prevention Cheat Sheet».
  <https://cheatsheetseries.owasp.org/cheatsheets/SQL_Injection_Prevention_Cheat_Sheet.html>

---

## 🧠 Preguntas

1. ¿Qué es una inyección SQL, en una frase? 🟢
2. ¿Qué marcador de parámetro usa cada uno de los cuatro drivers del corpus, y cuál llega al
   servidor? 🟢
3. ¿Qué dos mensajes del protocolo extendido de PostgreSQL separan el texto de los valores? 🟢
4. ¿Por qué la entrada `PED-00042' OR '1'='1` devuelve toda la tabla si se concatena? 🟢
5. ¿Es el marcador `?` del estándar o de cada motor? Responde para la norma, para PostgreSQL y para
   los drivers del corpus. 🟡
6. Distingue el enlace de parámetros en el servidor del enlace en el cliente, y di qué hace por
   defecto cada driver del corpus. 🟡
7. ¿Por qué escapar las comillas a mano no es equivalente a usar un parámetro? 🟡
8. ¿Por qué `IN (%s)` con `'PED-00042,PED-99999'` no devuelve nada, y cómo se escribe bien en
   PostgreSQL? 🟡
9. En el log del servidor, el valor del parámetro aparece con las comillas dobladas. ¿Quién las
   dobló y qué significa? 🟡
10. `ORDER BY ?` con el valor `'total'` no da error. Explica qué hace el motor y cómo se ordena de
    verdad por una columna elegida por el usuario. 🟠
11. Una búsqueda por `LIKE` con parámetro devuelve toda la tabla cuando el usuario escribe `%`. ¿Es
    una inyección? Explica qué pasa y cómo se corrige. 🟠
12. ¿Por qué el `DROP TABLE pagos` de §1 llegó a ejecutarse en psycopg, y por qué no se habría
    ejecutado con un parámetro? 🟠
13. Compara cómo cita un identificador con comillas dentro `Statement.enquoteIdentifier` de Java y
    las herramientas de los otros tres lenguajes. ¿Cuál prefieres y por qué? 🟠
14. Tu equipo migra de psycopg 2 a psycopg 3 y una consulta `SET statement_timeout = %s` empieza a
    fallar. Explica por qué y da la corrección. 🟠
15. Diseña el `ORDER BY` dinámico de un listado de pedidos que el usuario puede ordenar por total,
    fecha o estado, en el lenguaje que prefieras, sin posibilidad de inyección. 🔴
16. Revisa este fragmento y di cuántos problemas tiene y cómo los corriges: `f"SELECT * FROM {tabla}
    WHERE nombre LIKE '%{texto}%' ORDER BY {orden}"`. 🔴
17. Diagnostica: en una auditoría aparece en el log del servidor la sentencia `SELECT … WHERE codigo
    = 'x' OR '1'='1'` completa, sin `$1`. Da tres hipótesis sobre cómo llegó así, en orden de
    probabilidad, y cómo confirmarías cada una. 🔴

---

**Anterior:** [`01`](01-el-driver-la-conexion-y-el-pool.md) — los drivers y el *pool* ·
**Siguiente:** [`03`](03-mapeo-de-tipos.md) — qué valor de tu lenguaje sale de cada columna ·
**Relacionado:** [`02/01`](../02-sql/01-familias-del-lenguaje-y-tipos.md) — las cuatro familias del
lenguaje, `GRANT` y `REVOKE` incluidos · [README de la raíz](../README.md) — el bloque 06, dueño de
roles y permisos.
