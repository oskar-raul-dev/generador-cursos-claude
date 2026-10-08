# 01 — El driver, la conexión y el *pool*

> Qué hace el driver entre tu código y el motor, por qué una conexión es un proceso del servidor que
> cuesta abrir, y qué hace exactamente el *pool* (reserva de conexiones) de cada lenguaje cuando se
> queda sin ninguna libre: esperar treinta segundos, fallar, o esperar para siempre. El mismo
> ejemplo en Java, Python, TypeScript y Go. **Asume leído:**
> [`04/01`](../04-transacciones-y-concurrencia/01-acid-con-precision.md) §7 —el ámbito de una
> transacción es la conexión— y
> [`04/05`](../04-transacciones-y-concurrencia/05-optimista-pesimista-y-transacciones-largas.md) §5,
> donde una conexión vuelve al *pool* con la transacción abierta. **Vigencia:** 23 de septiembre de
> 2026.

---

## Salto rápido

- [1. El problema](#1--el-problema) · [2. Qué hace un driver](#2--qué-hace-un-driver)
- [3. Una conexión es un proceso](#3--una-conexión-es-un-proceso) · [4. El pool](#4--el-pool)
- [5. Qué pasa exactamente al agotarlo](#5--qué-pasa-exactamente-al-agotarlo) · [6.
  Fugas](#6--fugas)
- [7. Estándar, motor y convención](#7--estándar-motor-y-convención) · [Errores
  frecuentes](#️-errores-frecuentes) · [Para profundizar](#-para-profundizar) ·
  [Preguntas](#-preguntas)

---

## 1. 🎯 El problema

El servicio de pedidos abre una conexión nueva en cada petición, consulta y la cierra. Funciona en
desarrollo, funciona en las pruebas y, el día de la campaña, pasan tres cosas en una hora:

```text
Las peticiones tardan 5 ms más de lo que tarda su consulta.
A las 11:00, el motor responde "remaining connection slots are reserved…" a la mitad de ellas.
Se pone un pool de 10, y a las 12:00 las peticiones se quedan colgadas treinta segundos.
```

Las tres tienen la misma raíz: **una conexión no es un objeto barato del lenguaje, es un proceso del
servidor**, y el *pool* no es una optimización opcional sino la pieza que decide cuántos de esos
procesos hay, cuánto se espera por uno y qué pasa cuando no queda ninguno. Y la tercera línea tiene
cuatro respuestas distintas según el lenguaje, porque cada *pool* trae un valor por defecto
diferente.

> **📝 Contexto.** Desde este bloque el código se corre en los contenedores de lenguaje del entorno
> —Java 25, Python 3.14, Node 24 con TypeScript y Go 1.27—, con los drivers en versión exacta; cómo
> se levantan está en `dominio-entorno-y-datos-fijos.md` §4.6. Todo lo pegado está **corrido**. Los
> milisegundos y los `pid` son de esta máquina, y un valor lo es también: el tamaño por defecto del
> *pool* de Go sale del número de núcleos, que aquí son 8. **Longitud:** capítulo de banda normal
> —117 líneas de código, por debajo de las 180 del denso— que cierra en 481 líneas, pasado el
> disparador de 400, porque el mismo ejemplo va en cuatro lenguajes; no lleva `🔭 Dónde aparece de
> verdad`.

---

## 2. 🧱 Qué hace un driver

**Qué es:** la biblioteca que traduce las llamadas de tu lenguaje al **protocolo de red del motor**.
PostgreSQL habla su protocolo *frontend/backend*, versión 3; MySQL, el suyo. El driver abre el
*socket*, negocia TLS, se autentica, manda la consulta y convierte cada columna de la respuesta en
un valor de tu lenguaje, que es el tema de [`03`](03-mapeo-de-tipos.md).

| Lenguaje | Interfaz común del lenguaje | Driver del corpus | *Pool* del corpus |
|---|---|---|---|
| Java 25 | JDBC | pgjdbc 42.7.13 | HikariCP 7.1.0 |
| Python 3.14 | DB-API 2.0 (PEP 249) | psycopg 3.3.6 | psycopg-pool 3.3.3 |
| TypeScript, Node 24 | Ninguna | `pg` 8.23.0 | `pg.Pool`, del mismo paquete |
| Go 1.27 | `database/sql` | pgx 5.11.0, en modo nativo | `pgxpool`, del mismo módulo |

El ejemplo común del bloque, **leer `PED-00042` con sus líneas**, en los cuatro. En Java:

```java
var config = new HikariConfig();
config.setJdbcUrl("jdbc:postgresql://postgres:5432/tienda");
config.setUsername("tienda_app");
config.setPassword("tienda_app");
config.setMaximumPoolSize(5);
try (var pool = new HikariDataSource(config);           // el pool se crea una vez
     var con = pool.getConnection();                     // se pide prestada
     var ps = con.prepareStatement("""
         SELECT p.estado, p.total, l.linea, l.cantidad, l.precio_unit
           FROM pedidos p JOIN pedido_lineas l ON l.pedido_id = p.id
          WHERE p.codigo = ? ORDER BY l.linea""")) {
    ps.setString(1, "PED-00042");
    try (var rs = ps.executeQuery()) {
        while (rs.next()) {
            System.out.printf("%s %s linea=%d cantidad=%d precio=%s%n",
                rs.getString("estado"), rs.getBigDecimal("total"), rs.getInt("linea"),
                rs.getInt("cantidad"), rs.getBigDecimal("precio_unit"));
        }
    }
}                                                        // y se devuelve al cerrar
```

En Python, TypeScript y Go, con la misma consulta y solo cambiando el marcador del parámetro:

```python
with ConnectionPool("", min_size=1, max_size=5) as pool:
    with pool.connection() as con:                 # prestada y devuelta al salir del with
        for estado, total, linea, cantidad, precio in con.execute(SQL, ("PED-00042",)):
            print(estado, total, f"linea={linea} cantidad={cantidad} precio={precio}")
```

```typescript
const pool = new pg.Pool({ max: 5 });
const { rows } = await pool.query(SQL, ["PED-00042"]);   // presta, ejecuta y devuelve
for (const r of rows) {
  console.log(r.estado, r.total, `linea=${r.linea} cantidad=${r.cantidad} precio=${r.precio_unit}`);
}
await pool.end();
```

```go
pool, err := pgxpool.New(ctx, "pool_max_conns=5")
if err != nil {
	panic(err)
}
defer pool.Close()
rows, err := pool.Query(ctx, sql, "PED-00042") // la conexión vuelve al pool con rows.Close()
if err != nil {
	panic(err)
}
defer rows.Close()
for rows.Next() {
	var estado, total, precio string
	var linea int16
	var cantidad int32
	if err := rows.Scan(&estado, &total, &linea, &cantidad, &precio); err != nil {
		panic(err)
	}
	fmt.Printf("%s %s linea=%d cantidad=%d precio=%s\n", estado, total, linea, cantidad, precio)
}
```

Los cuatro, corridos con `docker compose run --rm <lenguaje>`, imprimen exactamente lo mismo:

```text
PAGADO 3186.23 linea=1 cantidad=1 precio=102.83
PAGADO 3186.23 linea=2 cantidad=5 precio=27.03
PAGADO 3186.23 linea=3 cantidad=3 precio=982.75
```

- **El marcador cambia con el driver, no con el motor**: `?` en JDBC, `%s` en psycopg, `$1` en `pg`
  y en pgx. El `$1` es el del protocolo de PostgreSQL; los otros dos los traduce el driver.
- **Python, TypeScript y Go leen la conexión de las variables `PGHOST`, `PGUSER`…**, las mismas que
  usa `psql`, que el entorno fija; pgjdbc no las lee y necesita la URL entera. El `postgres` de esa
  URL es el nombre del servicio dentro de la red del `compose`.
- **Go pide `total::text`** para imprimir el decimal sin adornos; cómo llega un `numeric` a cada
  lenguaje, y por qué en dos de ellos es una trampa, es de [`03`](03-mapeo-de-tipos.md).

**Quién lo manda:** **lenguaje** para la interfaz —JDBC es una especificación de Java, DB-API una
propuesta de mejora de Python, `database/sql` un paquete de la biblioteca estándar de Go— y
**motor** para el protocolo. Ninguna de las dos cosas está en ISO/IEC 9075 (§7).

---

## 3. 🧱 Una conexión es un proceso

**Qué es:** en PostgreSQL, **cada conexión es un proceso del sistema operativo** que el servidor
crea con `fork` al aceptarla y destruye al cerrarla. Con el *pool* por defecto de psycopg abierto
—cuatro conexiones ociosas—, así se ve desde el servidor:

```text
tienda=# SELECT pid, usename, application_name, state, backend_start FROM pg_stat_activity
           WHERE usename = 'tienda_app';
 pid  |  usename   | application_name | state |         backend_start
------+------------+------------------+-------+-------------------------------
 2148 | tienda_app |                  | idle  | 2026-09-24 03:28:46.197462+00
 2149 | tienda_app |                  | idle  | 2026-09-24 03:28:46.19759+00
 2150 | tienda_app |                  | idle  | 2026-09-24 03:28:46.197891+00
 2151 | tienda_app |                  | idle  | 2026-09-24 03:28:46.206719+00
(4 filas)
```

```text
$ docker exec bd-lab-postgres ps -o pid,rss,args -u postgres | grep tienda_app
 2148 14992 postgres: tienda_app tienda 172.19.0.7(52176) idle
 2149 14908 postgres: tienda_app tienda 172.19.0.7(52192) idle
 2150 14968 postgres: tienda_app tienda 172.19.0.7(52206) idle
 2151 15028 postgres: tienda_app tienda 172.19.0.7(52212) idle
```

- **Cuatro filas, cuatro procesos, con el mismo `pid`**, y cada uno con unos 15 MB de memoria
  residente, de la que una parte es memoria compartida del servidor contada en cada proceso. Una
  conexión ociosa **no es gratis**: ocupa un proceso aunque no haga nada.
- **`application_name` va vacío** porque psycopg no lo rellena; pgjdbc pone `PostgreSQL JDBC
  Driver`, que tampoco distingue un servicio de otro. Ponerlo es gratis y es lo que te dice, en un
  incidente, de qué servicio viene cada fila de `pg_stat_activity`.

**Hay un techo, y es del servidor.** `max_connections` vale **100** en el entorno, y tres de ellas
están reservadas al superusuario. Abriendo conexiones de `tienda_app` en Go sin cerrar ninguna:

```text
conexión 98: failed to connect to `user=tienda_app database=tienda`:
	172.19.0.2:5432 (postgres): tls error: server refused TLS connection
	172.19.0.2:5432 (postgres): server error: FATAL: remaining connection slots are reserved for roles with the SUPERUSER attribute (SQLSTATE 53300)
abiertas antes del fallo: 97
```

- **97 = 100 − 3.** Es el techo **de toda la base**, compartido por todas las instancias de todos
  los servicios que se conectan a ella.
- **La línea de TLS no es el error**: pgx prueba primero con TLS, el servidor del entorno no lo
  tiene, y reintenta en claro. Es un viaje de ida y vuelta más en cada conexión nueva.

**Y abrirla cuesta.** Doscientas consultas `SELECT 1` en Go, primero abriendo y cerrando una
conexión en cada una, después sobre un *pool* de una:

```text
sin pool: 200 consultas en 1.049s  (5.24 ms por consulta)
con pool: 200 consultas en 28ms  (0.14 ms por consulta)
```

- **Unas 40 veces más cara**, repetido en tres corridas —5,18 a 5,37 ms contra 0,12 a 0,14—. Lo que
  se paga cada vez: la conexión TCP, el intento de TLS, el `fork` del proceso y, sobre todo, la
  autenticación `scram-sha-256` que el entorno exige, que está diseñada para ser costosa.
- **En producción la cifra es mayor**: con TLS de verdad y con la base en otra máquina, cada viaje
  de ida y vuelta cuesta lo que tarde la red.

> **Veredicto:** una conexión se abre una vez y se usa miles. Abrir una por petición paga unos
> milisegundos en cada una y, bajo carga, choca contra un techo que comparten todos los servicios.

---

## 4. 🧱 El *pool*

**Qué es:** un conjunto de conexiones abiertas que el programa **presta** a quien las pide y
**recupera** cuando se devuelven. Pedir una ya abierta cuesta microsegundos; lo que el *pool* decide
son tres cosas: cuántas hay como mucho, cuánto se espera si no queda ninguna libre, y cuándo se
cierran y se reabren.

Devolver la conexión es la mitad del contrato, y cada lenguaje la escribe a su manera:

| Lenguaje | Pedir | Devolver |
|---|---|---|
| Java | `pool.getConnection()` | `close()`, dentro de un `try` con recursos |
| Python | `with pool.connection() as con:` | Al salir del `with`, también si hay excepción |
| TypeScript | `pool.query(...)`, o `await pool.connect()` | Automático en `query`; `client.release()` a mano con `connect` |
| Go | `pool.Query(...)`, o `pool.Acquire(ctx)` | `rows.Close()`, o `con.Release()` con `defer` |

**Cuántas conexiones.** La cuenta que sirve es la de ocupación: el *pool* necesita tantas conexiones
como consultas haya en curso a la vez, y eso es **peticiones por segundo por tiempo que cada una
retiene la conexión**. Doscientas peticiones por segundo que retienen la conexión 20 ms necesitan
unas cuatro. La fórmula que se recita, `núcleos × 2 + discos`, viene de la documentación de HikariCP
y apunta a lo mismo desde el otro lado: **el servidor no ejecuta más consultas a la vez que núcleos
tiene**, y las conexiones de más solo esperan dentro de él.

- **El techo es de la base, no del servicio.** Diez instancias con un *pool* de 10 son 100
  conexiones contra las 97 disponibles de §3: la instancia número diez no arranca, y nadie tocó su
  configuración.
- **Un *pool* más grande no acelera nada** si el cuello es el servidor: añade procesos que compiten
  por los mismos núcleos y por la misma memoria.

**Cuánto cuesta:** conexiones abiertas aunque no se usen —un proceso y su memoria en el servidor
cada una—, y un límite que obliga a alguien a esperar cuando la carga lo supera. **Cuándo sí:**
siempre que el proceso viva más que una consulta. **Cuándo no:** un guion que abre, hace una cosa y
termina.

> **Veredicto:** el tamaño del *pool* se calcula con lo que retiene cada petición y se reparte entre
> todas las instancias contra el `max_connections` del servidor. No se sube «por si acaso».

---

## 5. 🩺 Qué pasa exactamente al agotarlo

**Qué es:** el momento en que todas las conexiones están prestadas y llega otra petición. El
experimento es el mismo en los cuatro lenguajes: un *pool* de **dos** conexiones, **tres** tareas a
la vez, y cada tarea retiene su conexión 2 s con `SELECT pg_sleep(2)`. En Java:

```java
config.setMaximumPoolSize(2);          // dos conexiones...
config.setConnectionTimeout(1000);     // ...y un segundo de espera para conseguir una
// tres hilos, cada uno:
try (var con = pool.getConnection(); var st = con.createStatement()) {
    st.execute("SELECT pg_sleep(2)");
}
```

Lo que sale en cada uno, corrido, con el tiempo desde el arranque:

```text
-- Java, HikariCP (connectionTimeout = 1000)
tarea-3: falló a los 1045 ms: HikariPool-1 - Connection is not available, request timed out after 1032ms (total=2, active=2, idle=0, waiting=0)
tarea-1: terminó a los 2012 ms
tarea-2: terminó a los 2074 ms

-- Python, psycopg-pool (timeout = 1)
tarea-3: falló a los 1003 ms: PoolTimeout: couldn't get a connection after 1.00 sec
tarea-1: terminó a los 2021 ms
tarea-2: terminó a los 2022 ms

-- TypeScript, pg.Pool, sin tocar el tiempo de espera
[sin límite] tarea-2: terminó a los 2028 ms
[sin límite] tarea-1: terminó a los 2030 ms
[sin límite] tarea-3: terminó a los 4034 ms

-- TypeScript, pg.Pool (connectionTimeoutMillis = 1000)
[1 s de espera] tarea-3: falló a los 1004 ms: timeout exceeded when trying to connect
[1 s de espera] tarea-1: terminó a los 2026 ms
[1 s de espera] tarea-2: terminó a los 2027 ms

-- Go, pgxpool, con un contexto de 1 s solo para conseguir la conexión
tarea-2: falló a los 1001 ms: context deadline exceeded
tarea-3: terminó a los 2007 ms
tarea-1: terminó a los 2008 ms
```

- **El mensaje de HikariCP es el más útil de los cuatro**: `total=2, active=2, idle=0` dice en una
  línea que el *pool* estaba entero prestado. Es la primera cosa que hay que buscar en un log cuando
  las peticiones se cuelgan.
- **`pg.Pool` espera para siempre por defecto.** Sin `connectionTimeoutMillis`, la tercera tarea no
  falla: espera a que otra termine y sale a los 4 034 ms. Con una consulta que nunca termina, se
  quedaría ahí indefinidamente.
- **`pgxpool` no tiene tiempo de espera propio**: espera lo que diga el `context`. Y si el mismo
  contexto cubre la consulta, **la cancela a mitad**. Corrido con un solo contexto de 1 s para las
  dos cosas, fallaron las tres: dos con `timeout: context deadline exceeded`, cortadas en el
  servidor —que registra `canceling statement due to user request`—, y la tercera esperando turno.

Los valores por defecto, leídos del propio objeto de cada *pool* y no de memoria:

```text
-- HikariCP
por defecto: maximumPoolSize=10 connectionTimeout=30000 ms idleTimeout=600000 ms maxLifetime=1800000 ms leakDetectionThreshold=0 ms
-- psycopg-pool
por defecto: min_size=4 max_size=4 timeout=30.0 s max_idle=600.0 s max_lifetime=3600.0 s
-- pg.Pool
por defecto: max=10 idleTimeoutMillis=10000 connectionTimeoutMillis=undefined maxLifetimeSeconds=0
-- pgxpool
por defecto: MaxConns=8 MinConns=0 MaxConnLifetime=1h0m0s MaxConnIdleTime=30m0s HealthCheckPeriod=1m0s
```

| | Tamaño por defecto | Espera por defecto | Qué recibe quien espera de más |
|---|---|---|---|
| **HikariCP** | 10 | **30 s** | `SQLTransientConnectionException` con el estado del *pool* |
| **psycopg-pool** | 4 | **30 s** | `PoolTimeout` |
| **`pg.Pool`** | 10 | **Ninguna: para siempre** | Nada, salvo que se fije `connectionTimeoutMillis` |
| **`pgxpool`** | El mayor de 4 y los núcleos | **La del `context`** | `context deadline exceeded` |

**Cuánto cuesta cada elección:** esperar poco convierte un pico en errores rápidos y visibles;
esperar mucho lo convierte en peticiones colgadas que ocupan hilos y memoria en el servicio, y que
el balanceador acaba cortando igual. **Treinta segundos casi nunca es el valor correcto**: es más de
lo que un usuario espera una página.

> **🩺 Diagnóstico.** Peticiones colgadas y base tranquila es la firma de un *pool* agotado. Se mira
> primero el log del *pool* —el `total, active, idle` de HikariCP— y después `pg_stat_activity`: si
> las conexiones del servicio están `active`, el cuello es la consulta; si están `idle in
> transaction`, alguien retiene conexiones sin usarlas.

---

## 6. 🩺 Fugas

**Qué es:** una conexión que se pide y **no se devuelve nunca**. El *pool* la da por prestada para
siempre, y tras unas cuantas fugas queda agotado con la base sin trabajo. HikariCP puede avisar si
una conexión lleva prestada más de un umbral, apagado por defecto:

```text
[HikariPool-1:housekeeper] WARN com.zaxxer.hikari.pool.ProxyLeakTask - Connection leak detection triggered for org.postgresql.jdbc.PgConnection@6404f418 on thread main, stack trace follows
java.lang.Exception: Apparent connection leak detected
	at com.zaxxer.hikari.HikariDataSource.getConnection(HikariDataSource.java:99)
	at Fuga.main(Fuga.java:13)
```

- **Con `setLeakDetectionThreshold(2000)`** y un programa que pide la conexión y no la cierra, a los
  2 s el aviso señala **la línea exacta** donde se pidió: `Fuga.java:13`. Se cortó aquí la traza del
  lanzador de Java que sigue debajo, que no aporta nada.
- **En los otros tres no hay detector equivalente** en los *pools* del corpus. Lo que protege es la
  forma de escribirlo —el `with` de Python, el `pool.query` de `pg`, el `defer con.Release()` de Go—
  y un tiempo de espera que convierta el agotamiento en error.

**La fuga que no se ve como fuga** es la de
[`04/05`](../04-transacciones-y-concurrencia/05-optimista-pesimista-y-transacciones-largas.md) §5:
la conexión **sí** se devuelve, pero con una transacción abierta. El *pool* la presta a la siguiente
petición, que trabaja dentro de una transacción ajena, y mientras tanto el servidor la ve `idle in
transaction` y el horizonte de limpieza no avanza. La defensa es doble y ya está medida allí: que el
*pool* haga `ROLLBACK` al recibir cada conexión, y `idle_in_transaction_session_timeout` en el
servidor, que la cierra con `FATAL`.

**Cuánto cuesta detectarlas:** el detector de HikariCP guarda una traza por préstamo, poco, y avisa
de falsos positivos si el umbral es menor que la consulta más larga legítima. **Cuándo se
enciende:** en todo servicio, con un umbral por encima de su consulta más lenta.

---

## 7. 📜 Estándar, motor y convención

> **📜 Estándar o motor.** ISO/IEC 9075 es de pago y **no he verificado sus cláusulas**. Tiene una
> parte de interfaz de llamada, la 3 (SQL/CLI), emparentada con ODBC; **ninguno de los cuatro
> drivers del corpus la implementa**. Todo lo de este capítulo es de lenguaje, de driver o de motor.

| Afirmación | Estándar | PostgreSQL 18.6 | Lenguaje y driver |
|---|---|---|---|
| Existe una interfaz común para hablar con la base | SQL/CLI, que estos drivers no usan | — | JDBC en Java, DB-API en Python, `database/sql` en Go; ninguna en Node |
| Una conexión es un proceso del servidor | No lo define | **Sí**, un `fork` por conexión | — |
| Hay un máximo de conexiones | No lo define | `max_connections = 100`, 3 reservadas | — |
| Existe el *pool* | No lo define | No: el motor no trae *pool* | Lo pone la biblioteca: HikariCP, psycopg-pool, `pg.Pool`, `pgxpool` |
| Se espera un tiempo máximo por una conexión | No lo define | — | 30 s, 30 s, **para siempre** y lo que diga el `context` |
| El marcador del parámetro | `?` en SQL dinámico | `$1` en el protocolo | `?`, `%s`, `$1`, `$1` |

**Convención, las dos que más se repiten.** *«Un *pool* más grande aguanta más carga»* — aguanta más
espera dentro del servidor, que no ejecuta más consultas a la vez que núcleos tiene, y reparte
contra un techo común a todas las instancias. Y *«el *pool* ya pone un tiempo de espera razonable»*
— en Node no pone ninguno, y en Java y Python pone treinta segundos, que casi nunca es lo que el
servicio necesita.

---

## ⚠️ Errores frecuentes

| Se dice | Lo preciso |
|---|---|
| "Abrir una conexión es rápido" | Medido: 5,2 ms contra 0,13 ms reutilizándola. Es un proceso nuevo y una autenticación en cada una |
| "Una conexión ociosa no consume nada" | Es un proceso del servidor con su memoria, y cuenta contra `max_connections` |
| "El `max_connections` es por servicio" | Es de toda la base. Diez instancias con un *pool* de 10 no caben en 97 |
| "Si el *pool* se agota, la petición falla" | Depende del lenguaje: en Java y Python a los 30 s; en Node espera para siempre; en Go, lo que diga el `context` |
| "En Go el `context` solo limita la espera" | Si cubre también la consulta, la cancela en el servidor a mitad de ejecución |
| "Devolví la conexión, así que no hay fuga" | Si volvió con una transacción abierta, la siguiente petición trabaja dentro de ella y el servidor la ve `idle in transaction` |
| "El *pool* lo trae la base de datos" | PostgreSQL no trae *pool*; lo pone la biblioteca de cada lenguaje |

---

## 📚 Para profundizar

- **Documentación** — PostgreSQL 18, «Connections and Authentication»: `max_connections` y las
  conexiones reservadas. <https://www.postgresql.org/docs/18/runtime-config-connection.html>
- **Documentación** — PostgreSQL 18, «Protocol Overview»: qué intercambian el driver y el servidor.
  <https://www.postgresql.org/docs/18/protocol-overview.html>
- **Documentación** — HikariCP, el README con todos los parámetros y sus valores por defecto.
  <https://github.com/brettwooldridge/HikariCP>
- **Documentación** — HikariCP, «About Pool Sizing»: de dónde sale la fórmula de núcleos y discos.
  <https://github.com/brettwooldridge/HikariCP/wiki/About-Pool-Sizing>
- **Documentación** — psycopg 3, «Connection pools»: tamaño, espera y comprobación de conexiones.
  <https://www.psycopg.org/psycopg3/docs/advanced/pool.html>
- **Documentación** — node-postgres, «pg.Pool»: las opciones, y por qué `connectionTimeoutMillis` en
  0 es no esperar nunca de menos. <https://node-postgres.com/apis/pool>
- **Documentación** — pgx, «pgxpool»: configuración y relación con el `context`.
  <https://pkg.go.dev/github.com/jackc/pgx/v5/pgxpool>
- **Estándar de lenguaje** — PEP 249, «Python Database API Specification v2.0».
  <https://peps.python.org/pep-0249/>

---

## 🧠 Preguntas

1. ¿Qué hace un driver, en una frase? 🟢
2. ¿Qué es un *pool* de conexiones y qué tres cosas decide? 🟢
3. ¿Cuánto vale `max_connections` en el entorno del corpus, y cuántas le quedan a la aplicación? 🟢
4. Di el tiempo de espera por defecto del *pool* en los cuatro lenguajes del corpus. 🟢
5. ¿Está la interfaz entre el lenguaje y la base en el estándar SQL? Responde para la norma y para
   los cuatro lenguajes. 🟡
6. Distingue una conexión ociosa de una `idle in transaction`: qué retiene cada una. ¿Lo fija el
   estándar o es cosa del motor? 🟡
7. ¿Por qué pgjdbc necesita la URL entera y psycopg, `pg` y pgx no? 🟡
8. Diferencia el tiempo de espera del *pool* del `statement_timeout` del servidor. 🟡
9. ¿Qué dice exactamente el mensaje de HikariCP cuando se agota el *pool*, y qué mirarías primero? 🟡
10. Explica por qué abrir una conexión por petición cuesta unas 40 veces más que reutilizarla, y en
    qué se va ese tiempo. 🟠
11. En Go, un único `context` de 1 s cubre la espera del *pool* y la consulta. ¿Qué pasa con una
    consulta que tarda 2 s, en el cliente y en el servidor? 🟠
12. Tienes 200 peticiones por segundo que retienen la conexión 20 ms. Calcula el tamaño del *pool* y
    di qué cambiarías si la consulta pasa a 200 ms. 🟠
13. Diez instancias de un servicio, cada una con un *pool* de 10, contra una base con
    `max_connections = 100`. ¿Qué pasa y qué harías? 🟠
14. ¿Por qué subir el tamaño del *pool* no acelera un servicio cuyo cuello es la base? 🟠
15. Un servicio en Node se queda colgado con la base tranquila. Da la hipótesis más probable, qué
    parámetro falta y cómo lo confirmarías. 🔴
16. Diseña la configuración del *pool* de un servicio Java —tamaño, espera, tiempo de vida y
    detección de fugas— y justifica cada valor. 🔴
17. Diagnostica: tras un despliegue, `pg_stat_activity` muestra decenas de conexiones del servicio
    en `idle in transaction` y el disco crece. Da el mecanismo, la corrección en el código y la
    defensa en el servidor. 🔴
18. Escribe, en el lenguaje que prefieras, el préstamo de una conexión de forma que se devuelva
    siempre, también si la consulta lanza una excepción, y di qué pasa con una transacción abierta
    en ese caso. 🔴

---

**Anterior:** [README del bloque](README.md) · **Siguiente:**
[`02`](02-parametrizadas-e-inyeccion.md) — el parámetro que separa el código de los datos ·
**Relacionado:**
[`04/05`](../04-transacciones-y-concurrencia/05-optimista-pesimista-y-transacciones-largas.md) §5 —
la conexión que vuelve con la transacción abierta ·
[`04/01`](../04-transacciones-y-concurrencia/01-acid-con-precision.md) §7 — el ámbito de la
transacción es la conexión.
