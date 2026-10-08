# 09 — Respuestas

> Solucionario del bloque: el enunciado copiado literalmente de su capítulo y la respuesta en tres
> capas.
>
> **Cómo se usa.** Responde primero en voz alta, con el cronómetro. La capa ⏱️ es lo que dices en
> los primeros treinta segundos; la 🗣️ es lo que añades cuando te dicen "cuéntame más"; la 🔬 es el
> matiz que casi nadie trae, y es donde vive la distinción entre **lo que manda el estándar, lo que
> hace el motor, lo que hace el driver y lo que es pura convención**.
>
> **Vigencia:** 24 de septiembre de 2026.

---

## Salto rápido

- [Capítulo 01 — El driver, la conexión y el pool](#capítulo-01--el-driver-la-conexión-y-el-pool)
- [Capítulo 02 — Parametrizadas e inyección](#capítulo-02--parametrizadas-e-inyección)
- [Capítulo 03 — Mapeo de tipos](#capítulo-03--mapeo-de-tipos)
- [Capítulo 04 — Transacciones y resultados
  grandes](#capítulo-04--transacciones-y-resultados-grandes)
- [Capítulo 05 — Java](#capítulo-05--java)
- [Capítulo 06 — Python, TypeScript y Go](#capítulo-06--python-typescript-y-go)
- [Capítulo 07 — Clientes de Redis y MongoDB](#capítulo-07--clientes-de-redis-y-mongodb)
- [Simulación de entrevista](#simulación-de-entrevista)

---

## Capítulo 01 — El driver, la conexión y el *pool*

Las 18 preguntas de [`01`](01-el-driver-la-conexion-y-el-pool.md).

**01 → 1.** ¿Qué hace un driver, en una frase? 🟢

⏱️ **30 segundos** — Traduce las llamadas de tu lenguaje al protocolo de red del motor, y cada
columna de la respuesta a un valor de tu lenguaje.

🗣️ **2 minutos** — Abre el *socket*, negocia TLS, se autentica, manda la consulta con sus parámetros
y convierte el resultado. En PostgreSQL habla el protocolo *frontend/backend*, versión 3. Por eso
dos drivers del mismo lenguaje pueden comportarse distinto con la misma consulta: la traducción es
suya.

🔬 **El detalle** — **Driver**, no motor ni estándar. En el corpus son pgjdbc, psycopg, `pg` y pgx, y
cada uno decide cosas que parecen del motor: el marcador del parámetro, la zona horaria de la sesión
en pgjdbc o el tipo al que llega un `numeric`.

---

**01 → 2.** ¿Qué es un *pool* de conexiones y qué tres cosas decide? 🟢

⏱️ **30 segundos** — Un conjunto de conexiones abiertas que el programa presta y recupera. Decide
cuántas hay como mucho, cuánto se espera si no queda ninguna libre, y cuándo se cierran y se
reabren.

🗣️ **2 minutos** — Existe porque abrir una conexión cuesta: en el entorno, 5,2 ms contra 0,13 ms
reutilizándola. El tamaño limita la carga que el servicio manda a la base; la espera decide si un
pico se convierte en errores rápidos o en peticiones colgadas; y el tiempo de vida evita conexiones
que un cortafuegos o un reinicio dejaron muertas.

🔬 **El detalle** — **Biblioteca**, no motor: PostgreSQL no trae *pool*. Lo ponen HikariCP,
psycopg-pool, `pg.Pool` y `pgxpool`, cada uno con valores por defecto distintos.

---

**01 → 3.** ¿Cuánto vale `max_connections` en el entorno del corpus, y cuántas le quedan a la
aplicación? 🟢

⏱️ **30 segundos** — 100, con 3 reservadas al superusuario: a la aplicación le quedan 97.

🗣️ **2 minutos** — Corrido abriendo conexiones de `tienda_app` en Go sin cerrarlas: la 98 falla con
`remaining connection slots are reserved for roles with the SUPERUSER attribute`, `SQLSTATE 53300`.
Y ese techo es de toda la base, compartido por todas las instancias de todos los servicios.

🔬 **El detalle** — **Motor.** Son `max_connections` y `superuser_reserved_connections`, 100 y 3 por
defecto. Las reservas existen para que un administrador pueda entrar a arreglar una base saturada.

---

**01 → 4.** Di el tiempo de espera por defecto del *pool* en los cuatro lenguajes del corpus. 🟢

⏱️ **30 segundos** — HikariCP, 30 s. psycopg-pool, 30 s. `pg.Pool`, ninguno: espera para siempre.
`pgxpool`, ninguno propio: el del `context` que le pases.

🗣️ **2 minutos** — Leídos del propio objeto: `connectionTimeout=30000 ms`, `timeout=30.0 s`,
`connectionTimeoutMillis=undefined`. En el experimento de agotamiento, `pg.Pool` sin tocar hizo
esperar a la tercera tarea hasta que otra terminó, a los 4 034 ms, en vez de fallar.

🔬 **El detalle** — **Biblioteca.** En Go, la espera y la consulta comparten el `context` si no las
separas, y entonces el límite también corta la consulta. Treinta segundos casi nunca es el valor que
un servicio necesita.

---

**01 → 5.** ¿Está la interfaz entre el lenguaje y la base en el estándar SQL? Responde para la norma
y para los cuatro lenguajes. 🟡

⏱️ **30 segundos** — La norma tiene una parte de interfaz de llamada, SQL/CLI, emparentada con ODBC,
pero ninguno de los cuatro drivers del corpus la usa. Cada lenguaje tiene la suya o ninguna.

🗣️ **2 minutos** — Java tiene JDBC, una especificación del propio lenguaje. Python, la DB-API 2.0,
que es una propuesta de mejora del lenguaje, la PEP 249. Go, el paquete `database/sql` de su
biblioteca estándar, aunque pgx se usa en modo nativo. Node no tiene ninguna: cada driver define la
suya.

🔬 **El detalle** — ISO/IEC 9075 es de pago y no he verificado sus cláusulas. Lo que se afirma es que
existe la parte 3 y que estos drivers no la implementan. **Lenguaje** para las cuatro interfaces;
**motor** para el protocolo que hay debajo.

---

**01 → 6.** Distingue una conexión ociosa de una `idle in transaction`: qué retiene cada una. ¿Lo
fija el estándar o es cosa del motor? 🟡

⏱️ **30 segundos** — La ociosa solo retiene su proceso en el servidor y su plaza en
`max_connections`. La `idle in transaction` retiene además sus bloqueos y el horizonte de limpieza
de toda la base.

🗣️ **2 minutos** — Una conexión ociosa en un *pool* es normal: es lo que el *pool* guarda para
prestar. Una en `idle in transaction` es una transacción abierta que nadie está usando: bloquea las
filas que tocó y, con identificador asignado o instantánea, impide que el `VACUUM` recicle nada
posterior.

🔬 **El detalle** — **Motor.** Las dos se ven en `pg_stat_activity.state`. Unos 15 MB de RSS por
proceso en el entorno, parte compartida. La segunda se corta con
`idle_in_transaction_session_timeout`, que cierra la conexión con `FATAL`, como se midió en `04/05`
§5.

---

**01 → 7.** ¿Por qué pgjdbc necesita la URL entera y psycopg, `pg` y pgx no? 🟡

⏱️ **30 segundos** — Porque psycopg, `pg` y pgx leen las variables `PGHOST`, `PGUSER` y compañía,
las mismas de `psql`, y pgjdbc no.

🗣️ **2 minutos** — Corrido: pgjdbc con `jdbc:postgresql:tienda`, sin host, intenta `localhost` y
falla con `Connection to localhost:5432 refused`, aunque `PGHOST` valga `postgres`. Los otros tres
conectan con una cadena vacía.

🔬 **El detalle** — **Driver.** Las variables vienen de `libpq`, la biblioteca en C del proyecto
PostgreSQL; los drivers que la imitan las heredan. En producción conviene no depender de ninguna de
las dos cosas sin saberlo, y configurar la conexión de forma explícita.

---

**01 → 8.** Diferencia el tiempo de espera del *pool* del `statement_timeout` del servidor. 🟡

⏱️ **30 segundos** — El del *pool* limita cuánto se espera para **conseguir** una conexión, en el
cliente. `statement_timeout` limita cuánto dura **una sentencia**, en el servidor.

🗣️ **2 minutos** — El primero salta cuando el *pool* está agotado y la base puede estar tranquila;
el segundo, cuando la consulta es lenta y la base está trabajando. Protegen de cosas distintas y
hacen falta los dos: sin el segundo, una consulta lenta retiene su conexión y acaba agotando el
*pool*.

🔬 **El detalle** — **Biblioteca** el primero; **motor** el segundo, que aborta la sentencia con
`ERROR` y deja viva la conexión. En Go hay una tercera vía: el `context` de la consulta, que cancela
en el servidor.

---

**01 → 9.** ¿Qué dice exactamente el mensaje de HikariCP cuando se agota el *pool*, y qué mirarías
primero? 🟡

⏱️ **30 segundos** — `Connection is not available, request timed out after 1032ms (total=2,
active=2, idle=0, waiting=0)`. Miraría esos números: todas prestadas y ninguna libre.

🗣️ **2 minutos** — Llega como `SQLTransientConnectionException`. Con el *pool* entero activo, lo
siguiente es `pg_stat_activity`: si las conexiones del servicio están `active`, el cuello es la
consulta; si están `idle in transaction`, el código las retiene sin usarlas; si no aparecen, se
perdieron por una fuga.

🔬 **El detalle** — **Biblioteca.** Es el mensaje más útil de los cuatro *pools*, porque describe el
estado en una línea. Para las fugas, HikariCP tiene además `leakDetectionThreshold`, que señala la
línea donde se pidió la conexión.

---

**01 → 10.** Explica por qué abrir una conexión por petición cuesta unas 40 veces más que
reutilizarla, y en qué se va ese tiempo. 🟠

⏱️ **30 segundos** — Porque cada conexión nueva es un proceso del servidor, un `fork`, una conexión
TCP, un intento de TLS y una autenticación `scram-sha-256`, que está hecha para costar. Medido: 5,2
ms por consulta contra 0,13 ms.

🗣️ **2 minutos** — Doscientas consultas `SELECT 1` en Go, repetido en tres corridas: entre 5,18 y
5,37 ms abriendo y cerrando, entre 0,12 y 0,14 ms sobre un *pool*. La consulta cuesta lo mismo en
los dos casos; todo lo demás es montar y desmontar la conexión. En el log de pgx se ve además el
intento de TLS rechazado, que es un viaje de ida y vuelta más.

🔬 **El detalle** — **Motor** para el proceso por conexión y la autenticación. En producción, con TLS
de verdad y la base en otra máquina, cada viaje cuesta lo que tarde la red, y la proporción crece.

---

**01 → 11.** En Go, un único `context` de 1 s cubre la espera del *pool* y la consulta. ¿Qué pasa
con una consulta que tarda 2 s, en el cliente y en el servidor? 🟠

⏱️ **30 segundos** — Al segundo, pgx cancela la consulta en el servidor y devuelve `timeout: context
deadline exceeded`. En el servidor, la sentencia se aborta con `canceling statement due to user
request`.

🗣️ **2 minutos** — Corrido con un *pool* de dos y tres tareas: fallaron las tres a los 1 000 ms. Dos
estaban ya ejecutando y se cancelaron en el servidor; la tercera fallaba esperando turno, con
`context deadline exceeded` sin prefijo. Separando los dos límites —un `context` para `Acquire` y
otro para la consulta— solo falla la que espera, y las otras terminan a los 2 s.

🔬 **El detalle** — **Driver.** Es un comportamiento correcto y útil: el `context` expresa cuánto le
importa el resultado a quien lo pidió. Lo que hay que decidir es si ese límite cubre la espera, la
consulta, o las dos.

---

**01 → 12.** Tienes 200 peticiones por segundo que retienen la conexión 20 ms. Calcula el tamaño del
*pool* y di qué cambiarías si la consulta pasa a 200 ms. 🟠

⏱️ **30 segundos** — 200 × 0,020 son 4 conexiones ocupadas de media; con margen para picos, 6 u 8.
Con 200 ms serían 40, y antes de subir el *pool* miraría por qué la consulta tarda diez veces más.

🗣️ **2 minutos** — Es la ley de Little: conexiones en uso = llegadas por segundo × tiempo que
retiene cada una. A 200 ms, 40 conexiones de un solo servicio ya se comen casi la mitad de las 97
del entorno. Lo primero es bajar el tiempo de retención —la consulta, o lo que haga el código con la
conexión prestada—, no subir el *pool*.

🔬 **El detalle** — **Convención** la fórmula de núcleos × 2 más discos, de la documentación de
HikariCP: apunta a lo mismo desde el lado del servidor, que no ejecuta más consultas a la vez que
núcleos tiene.

---

**01 → 13.** Diez instancias de un servicio, cada una con un *pool* de 10, contra una base con
`max_connections = 100`. ¿Qué pasa y qué harías? 🟠

⏱️ **30 segundos** — Son 100 conexiones contra 97 disponibles: la última instancia, o las últimas
conexiones, fallan con `SQLSTATE 53300`. Bajaría el *pool* de cada instancia.

🗣️ **2 minutos** — El techo es de la base, y hay que repartirlo contando todos los servicios, las
migraciones, los administradores y el margen para escalar instancias. Si diez instancias necesitan
de verdad más de 97 conexiones, el siguiente paso es un intermediario de conexiones delante de la
base, no subir `max_connections`.

🔬 **El detalle** — **Motor** para el techo: cada conexión es un proceso con su memoria, y subir
`max_connections` sube el consumo del servidor aunque las conexiones estén ociosas.

---

**01 → 14.** ¿Por qué subir el tamaño del *pool* no acelera un servicio cuyo cuello es la base? 🟠

⏱️ **30 segundos** — Porque la base no ejecuta más consultas a la vez que núcleos tiene. Más
conexiones son más procesos compitiendo por los mismos núcleos y la misma memoria: más espera dentro
del servidor, no más trabajo hecho.

🗣️ **2 minutos** — El *pool* pequeño hace cola en el cliente, donde es barata y visible; el grande
la traslada al servidor, donde además hay bloqueos y cambios de contexto. Y resta plazas del techo
común a los demás servicios.

🔬 **El detalle** — **Convención** falsa: «más conexiones, más rendimiento». Se mide con la latencia
y el uso de CPU de la base antes y después; si la CPU ya estaba llena, subir el *pool* solo sube la
latencia.

---

**01 → 15.** Un servicio en Node se queda colgado con la base tranquila. Da la hipótesis más
probable, qué parámetro falta y cómo lo confirmarías. 🔴

⏱️ **30 segundos** — `pg.Pool` agotado por una fuga —un `client` pedido con `connect()` y nunca
liberado con `release()`— y sin `connectionTimeoutMillis`, que por defecto deja esperar para
siempre.

🗣️ **2 minutos** — Lo confirmaría en `pg_stat_activity`: las conexiones del servicio estarán `idle`,
o `idle in transaction`, y ninguna `active`. En el propio servicio, `pool.totalCount`, `idleCount` y
`waitingCount` dirían que no hay libres y hay peticiones esperando. Con `connectionTimeoutMillis`
puesto, el síntoma pasa de cuelgue a error `timeout exceeded when trying to connect`, que al menos
aparece en los logs.

🔬 **El detalle** — **Biblioteca.** La corrección de fondo es usar `pool.query`, que devuelve la
conexión solo, o `try … finally { client.release() }` cuando hace falta una transacción. El tiempo
de espera no arregla la fuga: la hace visible.

---

**01 → 16.** Diseña la configuración del *pool* de un servicio Java —tamaño, espera, tiempo de vida
y detección de fugas— y justifica cada valor. 🔴

⏱️ **30 segundos** — Tamaño por la ley de Little con margen, repartido contra el techo de la base;
espera de uno o dos segundos; tiempo de vida por debajo de cualquier corte del lado de la red; y
detección de fugas por encima de la consulta legítima más larga.

🗣️ **2 minutos** — Con 200 peticiones por segundo y 20 ms de retención:

```java
config.setMaximumPoolSize(8);              // 4 de media por Little, con margen para picos
config.setConnectionTimeout(2_000);        // un pico se convierte en error rápido, no en cuelgue
config.setMaxLifetime(1_500_000);          // 25 min: por debajo de cortes de red o de proxies
config.setLeakDetectionThreshold(10_000);  // por encima de la consulta legítima más lenta
config.setPoolName("pedidos");             // para reconocerlo en los logs
```

Y la cuenta del techo: ocho por instancia, por el número de instancias, más migraciones y
administradores, por debajo de las 97.

🔬 **El detalle** — **Biblioteca.** Los valores por defecto medidos son 10, 30 s, 30 min y detección
apagada. Falta además `application_name` en la URL de conexión, porque pgjdbc pone `PostgreSQL JDBC
Driver`, que no distingue un servicio de otro en `pg_stat_activity`.

---

**01 → 17.** Diagnostica: tras un despliegue, `pg_stat_activity` muestra decenas de conexiones del
servicio en `idle in transaction` y el disco crece. Da el mecanismo, la corrección en el código y la
defensa en el servidor. 🔴

⏱️ **30 segundos** — El código nuevo deja transacciones abiertas y devuelve las conexiones así al
*pool*. Retienen el horizonte y el `VACUUM` no recicla: la tabla crece. Se corrige cerrando la
transacción en todo camino, y se defiende con `idle_in_transaction_session_timeout`.

🗣️ **2 minutos** — Lo típico es un camino de error que no hace `ROLLBACK`, o un driver que abre
transacción implícita —psycopg lo hace por defecto, visto en el log de `02` con su `BEGIN`— en una
conexión usada fuera de un bloque que la cierre. En el código: el préstamo dentro de una estructura
que confirme o deshaga siempre. En el *pool*: `ROLLBACK` al recibir la conexión. En el servidor, el
tiempo máximo de ocio en transacción, que cierra la conexión con `FATAL`.

🔬 **El detalle** — **Motor** el horizonte y el `FATAL`; **driver** la transacción implícita. La
consulta de diagnóstico ordena `pg_stat_activity` por `xact_start` y mira `backend_xid` además de
`backend_xmin`, como en `04/05` §5.

---

**01 → 18.** Escribe, en el lenguaje que prefieras, el préstamo de una conexión de forma que se
devuelva siempre, también si la consulta lanza una excepción, y di qué pasa con una transacción
abierta en ese caso. 🔴

⏱️ **30 segundos** — En Python, con `with pool.connection() as con:`. Al salir, con o sin excepción,
la conexión vuelve al *pool*; si hubo excepción, la transacción se deshace, y si no, se confirma.

🗣️ **2 minutos** — Corrido con un *pool* de una sola conexión, para que la siguiente sea la misma:

```python
with ConnectionPool("", min_size=1, max_size=1) as pool:
    try:
        with pool.connection() as con:              # se devuelve al salir, pase lo que pase
            con.execute("UPDATE pedidos SET estado = 'PENDIENTE' WHERE codigo = 'PED-99999'")
            con.execute("SELECT 1 / 0")              # falla dentro de la transacción
    except Exception as e:
        print("error:", type(e).__name__)
    with pool.connection() as con:
        print("transacción al prestarla:", con.info.transaction_status.name)
        print("estado:", con.execute("SELECT estado FROM pedidos WHERE codigo = 'PED-99999'").fetchone()[0])
```

```text
error: DivisionByZero
transacción al prestarla: IDLE
estado: ANULADO
```

La conexión volvió limpia y el `UPDATE` se deshizo: `PED-99999` sigue en `ANULADO`.

🔬 **El detalle** — **Biblioteca.** En Java es un `try` con recursos sobre la conexión; en Go, `defer
con.Release()` justo después de `Acquire`, y un `defer tx.Rollback(ctx)` que no hace nada si ya se
confirmó. Lo que decide si la transacción se deshace al devolverla es el *pool* o el bloque, no el
motor: por eso conviene comprobarlo, como aquí.

---

## Capítulo 02 — Parametrizadas e inyección

Las 17 preguntas de [`02`](02-parametrizadas-e-inyeccion.md).

**02 → 1.** ¿Qué es una inyección SQL, en una frase? 🟢

⏱️ **30 segundos** — Que un dato del usuario se mezcle con el texto SQL antes de que el motor lo
analice, y acabe ejecutándose como código.

🗣️ **2 minutos** — El motor recibe un solo texto y no distingue qué escribió el programador y qué
tecleó el usuario. Una comilla del usuario cierra el literal que abrió el programador, y lo que
viene detrás ya es SQL. Corrido en la tienda: una búsqueda por código devolvió el millón de pedidos.

🔬 **El detalle** — Le pasa igual a todo motor: es una consecuencia de mandar SQL como texto. El
capítulo `02` es su dueño en el corpus.

---

**02 → 2.** ¿Qué marcador de parámetro usa cada uno de los cuatro drivers del corpus, y cuál llega
al servidor? 🟢

⏱️ **30 segundos** — `?` en pgjdbc, `%s` en psycopg, `$1` en `pg` y en pgx. Al servidor llega
siempre `$1`.

🗣️ **2 minutos** — Visto en el log del servidor con `log_statement`: los cuatro mandan `WHERE codigo
= $1` y el valor aparte, en un `DETAIL: Parameters: $1 = …`. El `?` y el `%s` los traduce el driver
antes de enviar.

🔬 **El detalle** — **Motor** el `$1`, que es el marcador del protocolo de PostgreSQL; **driver** el
que escribes en el código.

---

**02 → 3.** ¿Qué dos mensajes del protocolo extendido de PostgreSQL separan el texto de los valores?
🟢

⏱️ **30 segundos** — *Parse*, que manda el texto con `$1` para analizarlo, y *Bind*, que manda los
valores para esa sentencia ya analizada.

🗣️ **2 minutos** — Después viene *Execute*. Como los valores llegan cuando la consulta ya está
analizada, no pueden cambiar su estructura: un valor nunca pasa por el analizador de SQL. Y la
sentencia analizada se puede reutilizar, que es lo que hace pgx con sus `stmtcache_…`.

🔬 **El detalle** — **Motor.** El protocolo simple, en cambio, manda un único texto y admite varias
sentencias separadas por `;`, que es por donde entró el `DROP` de `02` §1.

---

**02 → 4.** ¿Por qué la entrada `PED-00042' OR '1'='1` devuelve toda la tabla si se concatena? 🟢

⏱️ **30 segundos** — Porque su primera comilla cierra el literal del programador, y el `OR '1'='1'`
que sigue queda como parte del `WHERE`: una condición siempre verdadera.

🗣️ **2 minutos** — La consulta resultante es `WHERE codigo = 'PED-00042' OR '1'='1'`, y la última
comilla la pone la propia plantilla. Corrido: 1 000 000 filas en vez de una.

🔬 **El detalle** — Con parámetro, la misma entrada es un valor —un código de pedido que no existe— y
devuelve 0 filas en los cuatro lenguajes.

---

**02 → 5.** ¿Es el marcador `?` del estándar o de cada motor? Responde para la norma, para
PostgreSQL y para los drivers del corpus. 🟡

⏱️ **30 segundos** — El `?` es el marcador del SQL dinámico del estándar. PostgreSQL usa `$1` en su
protocolo. Y los drivers ponen cada uno el suyo: `?` en pgjdbc, `%s` en psycopg, `$1` en `pg` y pgx.

🗣️ **2 minutos** — JDBC hereda el `?` del estándar, y pgjdbc lo traduce a `$1`. psycopg usa `%s` por
la DB-API, que permite varios estilos. `pg` y pgx exponen directamente el del protocolo.

🔬 **El detalle** — ISO/IEC 9075 es de pago y **no he verificado la cláusula**: lo del `?` es
doctrina asentada. **Motor** el `$1`, **driver** lo demás.

---

**02 → 6.** Distingue el enlace de parámetros en el servidor del enlace en el cliente, y di qué hace
por defecto cada driver del corpus. 🟡

⏱️ **30 segundos** — En el servidor, el driver manda el texto con `$1` y los valores aparte. En el
cliente, el driver cita cada valor y manda un único texto ya relleno. Los cuatro del corpus lo hacen
en el servidor por defecto.

🗣️ **2 minutos** — Los cuatro se vieron en el log con `$1`. Tienen la otra vía: psycopg con
`ClientCursor`, pgx con `QueryExecModeSimpleProtocol`, que su documentación describe como
interpolación en el cliente con los valores citados y escapados. psycopg 2, en cambio, interpolaba
siempre en el cliente.

🔬 **El detalle** — **Driver.** El enlace en el cliente es seguro si el driver cita bien, pero el
motor vuelve a recibir datos dentro del SQL, y existe sobre todo para intermediarios de conexión que
no soportan sentencias preparadas.

---

**02 → 7.** ¿Por qué escapar las comillas a mano no es equivalente a usar un parámetro? 🟡

⏱️ **30 segundos** — Porque escapar exige acertar con todas las formas de escribir una comilla, con
la codificación y con las opciones del motor sobre barras invertidas, y basta fallar una vez. El
parámetro no escapa nada: el valor nunca pasa por el analizador.

🗣️ **2 minutos** — El escape a mano es mezclar con cuidado; el parámetro es no mezclar. Por eso el
primero depende de la calidad de quien lo escribe y el segundo no.

🔬 **El detalle** — **Convención** que se sigue recitando. El log confunde a veces: las comillas
dobladas que se ven en el `DETAIL` no son un escape del driver, son cómo el servidor imprime el
valor.

---

**02 → 8.** ¿Por qué `IN (%s)` con `'PED-00042,PED-99999'` no devuelve nada, y cómo se escribe bien
en PostgreSQL? 🟡

⏱️ **30 segundos** — Porque un parámetro es un valor, y ese valor es la cadena entera con su coma,
que no coincide con ningún código. En PostgreSQL se escribe `= ANY(%s)` con una lista del lenguaje.

🗣️ **2 minutos** — Corrido: `IN (%s)` con la cadena, 0 filas; `= ANY(%s)` con `["PED-00042",
"PED-99999"]`, 2 filas. La lista viaja como un *array*, que es un único valor de tipo `text[]`.

🔬 **El detalle** — **Motor** el `ANY` con *array*. La alternativa portable es generar tantos
marcadores como elementos, que cambia el texto de la consulta con cada tamaño de lista.

---

**02 → 9.** En el log del servidor, el valor del parámetro aparece con las comillas dobladas. ¿Quién
las dobló y qué significa? 🟡

⏱️ **30 segundos** — Las dobló el servidor al escribir el log, para imprimir el valor entre comillas
sin ambigüedad. No significa que el driver escapara nada.

🗣️ **2 minutos** — El valor llegó en el mensaje *Bind* tal cual, `PED-00042' OR '1'='1`, con sus
comillas sueltas, como dato. El `DETAIL: Parameters: $1 = 'PED-00042'' OR ''1''=''1'` es solo su
representación en texto.

🔬 **El detalle** — **Motor.** Es la confusión que lleva a creer que los parámetros son «escape
automático», cuando son otra cosa: separación.

---

**02 → 10.** `ORDER BY ?` con el valor `'total'` no da error. Explica qué hace el motor y cómo se
ordena de verdad por una columna elegida por el usuario. 🟠

⏱️ **30 segundos** — Ordena por una constante, la cadena `'total'`, igual para todas las filas: no
ordena. Se ordena de verdad eligiendo el nombre de una lista blanca y citándolo como identificador.

🗣️ **2 minutos** — Corrido: los cuatro totales salieron desordenados con el parámetro y ordenados
con `sql.Identifier`. El nombre no puede ser parámetro, porque un parámetro es un valor. La lista
blanca decide qué se puede pedir; la cita garantiza que lo pedido no se convierte en código.

🔬 **El detalle** — **Motor.** Cada lenguaje tiene su forma de citar: `enquoteIdentifier` en Java,
`sql.Identifier` en Python, `pg.escapeIdentifier` en TypeScript y `pgx.Identifier{…}.Sanitize()` en
Go.

---

**02 → 11.** Una búsqueda por `LIKE` con parámetro devuelve toda la tabla cuando el usuario escribe
`%`. ¿Es una inyección? Explica qué pasa y cómo se corrige. 🟠

⏱️ **30 segundos** — No es inyección: el parámetro llegó intacto. Pasa que `%` y `_` son comodines
del propio `LIKE`. Si la búsqueda es literal, se escapan antes de pasarlos.

🗣️ **2 minutos** — Corrido: `LIKE %s` con `'%'`, 1 000 000 filas. Escapando la barra, `%` y `_` con
una barra invertida y añadiendo el comodín de prefijo que sí se quiere, 0 filas. El motor sigue
recibiendo un valor; lo que cambia es qué significa ese valor para `LIKE`.

🔬 **El detalle** — **Estándar** los comodines de `LIKE`, y la cláusula `ESCAPE` para cambiar el
carácter de escape. El driver no los escapa, porque no sabe si quieres un comodín o un literal.

---

**02 → 12.** ¿Por qué el `DROP TABLE pagos` de §1 llegó a ejecutarse en psycopg, y por qué no se
habría ejecutado con un parámetro? 🟠

⏱️ **30 segundos** — Porque una consulta sin parámetros va por el protocolo simple, que acepta
varias sentencias separadas por `;`. Con un parámetro va por el extendido, que admite una sola.

🗣️ **2 minutos** — Llegó al motor y solo lo paró el privilegio: `must be owner of table pagos`.
Corrido con un `%s` y el `DROP` detrás, psycopg responde `cannot insert multiple commands into a
prepared statement`. Y con parámetro, la entrada ni siquiera sería SQL.

🔬 **El detalle** — **Motor** los dos protocolos; **driver** la elección de cuál usar. Es la razón de
tener dos líneas de defensa: el parámetro y el mínimo privilegio del rol de la aplicación.

---

**02 → 13.** Compara cómo cita un identificador con comillas dentro `Statement.enquoteIdentifier` de
Java y las herramientas de los otros tres lenguajes. ¿Cuál prefieres y por qué? 🟠

⏱️ **30 segundos** — Java **lo rechaza** con `SQLException: Invalid name`. Python, TypeScript y Go
**lo escapan**, doblando la comilla: `"to""tal; DROP"`. Prefiero el rechazo.

🗣️ **2 minutos** — Los dos son seguros: el escapado produce un identificador válido que no se
convierte en código. Pero un nombre de columna con comillas dentro no es un caso legítimo en una
aplicación; rechazarlo avisa de que algo va mal, en vez de producir un identificador que no existe.

🔬 **El detalle** — **Lenguaje y driver**, corrido en los cuatro. Ninguna de las dos sustituye a la
lista blanca, que es la que decide qué columnas se pueden pedir.

---

**02 → 14.** Tu equipo migra de psycopg 2 a psycopg 3 y una consulta `SET statement_timeout = %s`
empieza a fallar. Explica por qué y da la corrección. 🟠

⏱️ **30 segundos** — psycopg 2 interpolaba en el cliente, y el `SET` recibía un literal. psycopg 3
enlaza en el servidor, y `SET` no admite parámetros. Se corrige con `SELECT
set_config('statement_timeout', %s, false)`, o citando el literal con `sql.Literal`.

🗣️ **2 minutos** — La documentación de psycopg 3 lo dice al explicar las diferencias: el enlace en
el servidor funciona con `SELECT` y con la manipulación de datos, y no con muchas otras sentencias,
`SET` entre ellas. `set_config` es una función, así que sus argumentos sí son valores y aceptan
parámetro.

🔬 **El detalle** — **Driver** el cambio de comportamiento; **motor** la restricción de `SET`. El
tercer argumento de `set_config` decide si dura la transacción o la sesión.

---

**02 → 15.** Diseña el `ORDER BY` dinámico de un listado de pedidos que el usuario puede ordenar por
total, fecha o estado, en el lenguaje que prefieras, sin posibilidad de inyección. 🔴

⏱️ **30 segundos** — Un diccionario de lo que el usuario puede pedir hacia la columna real, un error
si pide otra cosa, y el nombre citado con la herramienta del driver. La dirección, de dos valores
fijos.

🗣️ **2 minutos** — Corrido en Python:

```python
COLUMNAS = {"total": "total", "fecha": "creado_en", "estado": "estado"}   # lo único que se puede pedir

def listar(con, orden: str, descendente: bool):
    columna = COLUMNAS.get(orden)
    if columna is None:
        raise ValueError(f"orden no permitido: {orden!r}")
    consulta = sql.SQL("SELECT codigo, total FROM pedidos WHERE codigo LIKE 'PED-0004_' ORDER BY {} {} LIMIT 3").format(
        sql.Identifier(columna), sql.SQL("DESC" if descendente else "ASC"))
    return con.execute(consulta).fetchall()
```

```text
[('PED-00045', Decimal('8846.28')), ('PED-00043', Decimal('8400.77')), ('PED-00044', Decimal('7755.29'))]
orden no permitido: 'total; DROP TABLE pagos'
```

🔬 **El detalle** — El diccionario separa el nombre que ve el usuario del nombre de la columna, que
así se puede renombrar sin romper la API. Y cada combinación de orden conviene que tenga su índice,
o el listado ordenará en memoria el millón de filas: eso es del bloque 03.

---

**02 → 16.** Revisa este fragmento y di cuántos problemas tiene y cómo los corriges: `f"SELECT *
FROM {tabla} WHERE nombre LIKE '%{texto}%' ORDER BY {orden}"`. 🔴

⏱️ **30 segundos** — Tres inyecciones y un defecto: la tabla, el texto y el orden van concatenados,
y el texto además no escapa los comodines de `LIKE`.

🗣️ **2 minutos** — Corrección: la tabla y el orden, de listas blancas y citados como
identificadores; el texto, como parámetro, con `%`, `_` y la barra escapados antes y los `%` de los
extremos añadidos por el código: `WHERE nombre LIKE %s` con `f"%{escapado}%"`. Y el `SELECT *`,
cambiado por las columnas que se usan.

🔬 **El detalle** — Aun corregido, `LIKE '%…%'` con comodín por la izquierda no usa un índice B-tree
normal, que es una de las seis razones de `03/06`: lo seguro no es necesariamente rápido.

---

**02 → 17.** Diagnostica: en una auditoría aparece en el log del servidor la sentencia `SELECT …
WHERE codigo = 'x' OR '1'='1'` completa, sin `$1`. Da tres hipótesis sobre cómo llegó así, en orden
de probabilidad, y cómo confirmarías cada una. 🔴

⏱️ **30 segundos** — Primera, código que concatena. Segunda, un driver en modo de enlace en el
cliente, que interpola bien pero manda el texto relleno. Tercera, alguien lo tecleó en una consola.

🗣️ **2 minutos** — Para la primera, el log da el usuario, la aplicación y la hora: se busca la
consulta en el código de ese servicio. Para la segunda, se mira la configuración del driver —el modo
simple de pgx, un `ClientCursor` de psycopg, un psycopg 2—; en ese caso el valor estaría bien
citado, y la condición `OR '1'='1'` seguiría siendo un literal dentro de la cadena, no un `OR`. Para
la tercera, `application_name` y la dirección de origen del log.

🔬 **El detalle** — La distinción clave es la segunda: con interpolación correcta en el cliente
verías `codigo = 'x'' OR ''1''=''1'`, todo dentro de un literal. Si el `OR` está fuera, es
concatenación, y es un incidente de seguridad.

---

## Capítulo 03 — Mapeo de tipos

Las 18 preguntas de [`03`](03-mapeo-de-tipos.md).

**03 → 1.** ¿Qué tipo de TypeScript entrega `pg` para una columna `numeric`, y por qué? 🟢

⏱️ **30 segundos** — Una cadena, `"3186.23"`. Porque el único número de JavaScript es de coma
flotante, y no representa decimales exactos.

🗣️ **2 minutos** — `pg` prefiere darte el texto antes que un valor equivocado. El precio es que `+`
con una cadena concatena: `"3186.23" + 10` es `"3186.2310"`.

🔬 **El detalle** — **Driver**, corrido en la sonda de `03` §3. Se cambia con
`pg.types.setTypeParser` sobre el OID 1700, pero a un número no conviene.

---

**03 → 2.** ¿Qué devuelve `getLong` de JDBC cuando la columna es nula? 🟢

⏱️ **30 segundos** — Cero. Y solo `wasNull()`, preguntado después, dice que era nulo.

🗣️ **2 minutos** — Corrido: `getLong(nulo) 0 wasNull=true`. Un `long` de Java no puede ser nulo. Se
evita con `getObject(…, Long.class)`, que devolvió `null`.

🔬 **El detalle** — **Especificación JDBC**, que los primitivos siguen. Un saldo nulo leído con
`getLong` es un saldo cero, sin ningún error.

---

**03 → 3.** ¿Qué tipo de Go entrega pgx para un `uuid` si lo lees con `rows.Values()`? 🟢

⏱️ **30 segundos** — `[16]uint8`: los 16 bytes del UUID, que se imprimen como una lista de números.

🗣️ **2 minutos** — Escaneando a `string` o a `pgtype.UUID` se obtiene el texto de siempre,
`4cc23f8e-4baf-a114-cbd3-e8cad657270b`; corrido con los dos.

🔬 **El detalle** — **Driver.** Java y Python lo entregan como tipo `UUID` propio y TypeScript como
cadena.

---

**03 → 4.** ¿Qué guarda de verdad una columna `timestamptz`? 🟢

⏱️ **30 segundos** — Un instante, en UTC. La zona con que se escribió no se guarda.

🗣️ **2 minutos** — Al leerlo, el motor lo convierte a la zona de la sesión, y el driver lo entrega
en la zona que decida: UTC, la del proceso o la de la sesión.

🔬 **El detalle** — **Motor.** Es la **convención** equivocada más repetida del tema: «`timestamptz`
guarda la zona horaria».

---

**03 → 5.** ¿Qué tipo tiene el resultado de `count(*)` en PostgreSQL, y cómo llega a cada uno de los
cuatro lenguajes? 🟢

⏱️ **30 segundos** — `bigint`. Llega como `Long` en Java, `int` en Python, `int64` en Go y
**cadena** en TypeScript.

🗣️ **2 minutos** — Corrido en la sonda: `lineas` salió `"3"` en `pg`. Un `lineas + 1` en Node
concatena; con `setTypeParser(20, BigInt)` llega como `3n`.

🔬 **El detalle** — **Motor** el tipo, **driver** la conversión. Que el estándar fije el tipo de
`COUNT` no lo he verificado.

---

**03 → 6.** Distingue `timestamp` de `timestamptz`: qué guarda cada uno y qué hace el driver al
leerlo. 🟡

⏱️ **30 segundos** — `timestamptz` guarda un instante; `timestamp`, una hora de reloj sin zona. Al
leer, el driver convierte el instante a alguna zona, y a la hora sin zona le supone una, o no.

🗣️ **2 minutos** — Con el proceso en Bogotá: Python dio el instante con zona UTC y la hora sin zona
tal cual; Go, el instante en la zona del proceso y la hora sin zona marcada UTC; Node, el instante
sin microsegundos y la hora sin zona **leída como local**, cinco horas desplazada.

🔬 **El detalle** — **Motor** la diferencia de tipos, **driver** la interpretación. Para registrar
cuándo pasó algo, `timestamptz` siempre.

---

**03 → 7.** ¿La conversión de un `timestamptz` a fecha la hace el motor o el driver, y en qué zona?
🟡

⏱️ **30 segundos** — Si se escribe en SQL —`::date`, `::timestamp`, `date_trunc`—, la hace el motor,
en la zona de la sesión. Si se hace después en el lenguaje, la hace el código, en la zona que use.

🗣️ **2 minutos** — Y la zona de la sesión no siempre es la del servidor: pgjdbc la fija con la de la
JVM al conectar. Corrido: `America/Bogota` desde Java con `TZ` de Bogotá, `Etc/UTC` desde psycopg.

🔬 **El detalle** — **Motor** la conversión, **driver** la zona de la sesión. Por eso los informes
por día fijan la zona en la propia consulta, con `AT TIME ZONE`.

---

**03 → 8.** ¿Está en el estándar SQL cómo llega un `NUMERIC` a Java o a Python? Responde para la
norma, para JDBC y para los otros drivers. 🟡

⏱️ **30 segundos** — No. La norma define el tipo de columna y no dice nada de lenguajes. JDBC fija
`BigDecimal` para Java, y el resto lo decide cada driver.

🗣️ **2 minutos** — psycopg entrega `Decimal`; `pg`, cadena; pgx, `pgtype.Numeric`. Los tres son
decisiones del driver, y dos de ellos evitan perder precisión a costa de no darte un número.

🔬 **El detalle** — ISO/IEC 9075 es de pago y no he verificado sus cláusulas. **Especificación del
lenguaje** para JDBC y **driver** para los demás.

---

**03 → 9.** Diferencia lo que hacen Java y Go cuando leen un nulo en un tipo que no admite nulos. 🟡

⏱️ **30 segundos** — Java devuelve un valor por defecto, 0, sin error. Go devuelve un error: `cannot
scan NULL into *int64`.

🗣️ **2 minutos** — Los dos son del lenguaje: ni un `long` de Java ni un `int64` de Go pueden ser
nulos. Java elige no fallar y te deja preguntar con `wasNull()`; Go elige fallar y te obliga a usar
un puntero, que con el nulo devolvió `<nil>`.

🔬 **El detalle** — **Lenguaje y driver.** El comportamiento de Go es el más seguro: el nulo
imprevisto aparece como error y no como dato falso.

---

**03 → 10.** Un informe de «pedidos de ayer» da cifras distintas desde un servicio Java y desde uno
Python contra la misma base. Explica el mecanismo y dos formas de corregirlo. 🟠

⏱️ **30 segundos** — El informe convierte `creado_en` a fecha en SQL, en la zona de la sesión, y
pgjdbc pone la sesión en la zona de la JVM mientras psycopg la deja en la del servidor. El mismo
pedido cae en días distintos.

🗣️ **2 minutos** — Primera corrección: fijar la zona en la consulta, `(creado_en AT TIME ZONE
'America/Bogota')::date`, que no depende de nadie. Segunda: fijar la zona de la sesión a propósito
al conectar, la misma en todos los servicios.

🔬 **El detalle** — **Driver** la zona de la sesión; **motor** la conversión. Corrido: `SHOW
timezone` da `America/Bogota` desde Java con la JVM en Bogotá y `Etc/UTC` desde psycopg.

---

**03 → 11.** En Node, un pedido creado a las 03:08 aparece a las 08:08. Da la causa exacta y la
corrección con su código. 🟠

⏱️ **30 segundos** — La columna es `timestamp` sin zona, y `pg` la interpreta como hora local del
proceso, que está en Bogotá: la convierte a un instante cinco horas después.

🗣️ **2 minutos** — La corrección de fondo es usar `timestamptz`. Si no se puede, se le dice a `pg`
que no interprete ese tipo:

```typescript
pg.types.setTypeParser(1114, (texto) => texto);   // timestamp sin zona: se deja como texto
```

Corrido: `sin_zona` llegó como `2025-02-21 03:08:09.349067`, intacta.

🔬 **El detalle** — **Driver.** 1114 es el OID de `timestamp` en `pg_type`. El error no se ve con el
proceso en UTC, y por eso aparece en producción y no en las pruebas.

---

**03 → 12.** ¿Por qué `pg` entrega el dinero como cadena y no como número, y qué harías en un
servicio Node que tiene que sumar importes? 🟠

⏱️ **30 segundos** — Porque un `number` de JavaScript es coma flotante y no guarda decimales
exactos. Sumaría en la base, con `sum()` sobre `numeric`, o con una biblioteca decimal en el
servicio.

🗣️ **2 minutos** — Convertir la cadena con `parseFloat` devuelve el problema que el driver evitó. Si
la suma es de filas de la base, `SELECT sum(importe)` la hace exacta. Si hay que operar en el
servicio, se deja el texto y se usa un tipo decimal de una biblioteca.

🔬 **El detalle** — **Lenguaje** la limitación, **driver** la decisión. La regla del corpus es la del
bloque 12: nunca coma flotante para dinero.

---

**03 → 13.** Un importe guardado dentro de un `jsonb` aparece con un céntimo de diferencia en un
informe. ¿Dónde se pierde, y cómo lo evitas? 🟠

⏱️ **30 segundos** — Al analizar el JSON en el lenguaje: un número JSON se convierte a coma flotante
en Python, en TypeScript y en Go. Se evita guardando los importes como texto, o leyéndolos con un
analizador que devuelva decimales.

🗣️ **2 minutos** — En la sonda, el `importe` de `carga` llegó como `3186.23` flotante en los tres.
El error aparece al sumar muchos. También se puede extraer en SQL con
`(carga->>'importe')::numeric`, y entonces llega como decimal exacto.

🔬 **El detalle** — **Driver y lenguaje.** El `jsonb` guarda el número exacto; es la conversión al
leer la que redondea.

---

**03 → 14.** ¿Qué se pierde al leer un `timestamptz` en un `Date` de JavaScript, y cuándo importa? 🟠

⏱️ **30 segundos** — Los microsegundos: `Date` guarda milisegundos. `.349067` llegó como `.349`.

🗣️ **2 minutos** — Importa cuando la fecha se usa como clave o para ordenar: dos eventos del mismo
milisegundo quedan iguales, y un «dame lo posterior a esta fecha» que la reenvíe a la base puede
volver a traer la misma fila. Se evita con `setTypeParser(1184, …)` que la deje en texto.

🔬 **El detalle** — **Lenguaje.** PostgreSQL guarda microsegundos; el tipo de JavaScript no llega.

---

**03 → 15.** En Java, ¿qué tipo pedirías para leer un `timestamptz` sin depender de la zona de la
JVM, y qué zona trae el valor? 🟠

⏱️ **30 segundos** — `OffsetDateTime`, con `getObject(…, OffsetDateTime.class)`. Trae siempre UTC,
desplazamiento cero.

🗣️ **2 minutos** — Corrido: `2025-02-21T03:08:09.349067Z` con la JVM en Bogotá, mientras
`getTimestamp` enseñaba las 22:08. La documentación de pgjdbc lo explica: el motor guarda en UTC.

🔬 **El detalle** — **Driver**, con el soporte de JSR-310 de JDBC 4.2. `ZonedDateTime` e `Instant` no
están soportados directamente.

---

**03 → 16.** Escribe el fragmento que lee `actualizado_en`, que puede ser nulo, en el lenguaje que
prefieras, sin que un nulo se convierta en un valor por defecto. 🔴

⏱️ **30 segundos** — En Java, pidiendo el objeto, que sí puede ser `null`, en vez de un primitivo:
`rs.getObject("actualizado_en", OffsetDateTime.class)`.

🗣️ **2 minutos** — En Java, el mismo mecanismo que con el `Long`: `getObject(…, Long.class)`
devolvió `null` corrido. En Go, un puntero o un tipo con validez:

```go
var actualizado *time.Time   // nil si la columna es nula
err := con.QueryRow(ctx, "SELECT actualizado_en FROM pedidos WHERE codigo = $1", "PED-00042").Scan(&actualizado)
```

Corrido sobre `PED-00042`, cuyo `actualizado_en` es nulo: `<nil> <nil>`, sin valor y sin error.

🔬 **El detalle** — **Lenguaje.** En Python y TypeScript el nulo llega como `None` y `null`, y la
trampa pasa al código que los usa sin comprobar.

---

**03 → 17.** Diseña la configuración de tipos de un servicio en Node que lee pedidos —dinero,
identificadores y fechas— para que ningún valor se pierda ni se desplace, y di qué OID tocas. 🔴

⏱️ **30 segundos** — `int8` (20) a `BigInt`; `numeric` (1700), `timestamp` (1114) y `timestamptz`
(1184) a texto, para no perder precisión, no suponer zonas ni perder microsegundos.

🗣️ **2 minutos** — Corrido con el proceso en Bogotá:

```typescript
pg.types.setTypeParser(20, (t) => BigInt(t));    // int8: entero exacto
pg.types.setTypeParser(1700, (t) => t);          // numeric: texto, se opera con una biblioteca decimal
pg.types.setTypeParser(1114, (t) => t);          // timestamp sin zona: texto, sin suponer zona
pg.types.setTypeParser(1184, (t) => t);          // timestamptz: texto ISO, conserva los microsegundos
```

```text
{
  id: 42n,
  total: '3186.23',
  creado_en: '2025-02-21 03:08:09.349067+00',
  sin_zona: '2025-02-21 03:08:09.349067'
}
```

🔬 **El detalle** — **Driver**, y global: `setTypeParser` cambia el comportamiento de todo el
proceso. `BigInt` no se serializa con `JSON.stringify` sin ayuda, así que la API tiene que decidir
cómo exponer los identificadores.

---

**03 → 18.** Diagnostica: tras migrar un servicio de Python a Java, los totales diarios del panel
cambian a partir de las 19:00 de cada día. Da la hipótesis más probable, la consulta que la confirma
y la corrección. 🔴

⏱️ **30 segundos** — pgjdbc fija la zona de la sesión con la de la JVM, que está en Bogotá, cinco
horas por detrás de UTC. Las 19:00 de Bogotá son medianoche en UTC: a partir de ahí, los pedidos
caen en un día distinto que desde Python.

🗣️ **2 minutos** — La confirmación, desde el servicio Java: `SHOW timezone`, que dará
`America/Bogota`, contra `Etc/UTC` desde Python. La corrección: fijar la zona en la consulta,
`(creado_en AT TIME ZONE 'America/Bogota')::date`, o fijarla en la sesión de forma explícita en los
dos servicios.

🔬 **El detalle** — **Driver.** Lo que se evalúa es encontrar la hora exacta del cambio en la
diferencia entre zonas: un síntoma que empieza siempre a la misma hora local es casi siempre una
zona horaria.

---

## Capítulo 04 — Transacciones y resultados grandes

Las 18 preguntas de [`04`](04-transacciones-y-resultados-grandes.md).

**04 → 1.** ¿Qué driver del corpus abre una transacción sin que se lo pidas, y por qué? 🟢

⏱️ **30 segundos** — psycopg. Porque la DB-API de Python, la PEP 249, pide que las conexiones no
estén en autocommit, así que el driver manda un `BEGIN` con la primera sentencia.

🗣️ **2 minutos** — Corrido: tras el paso 1, `transaction_status` vale `INTRANS`. La transacción
queda abierta hasta `commit`, `rollback` o el cierre de la conexión, que la deshace. pgjdbc, `pg` y
pgx trabajan en autocommit: cada sentencia suelta se confirma sola.

🔬 **El detalle** — **Driver**, obligado por la especificación del lenguaje. Se ve en el log del
servidor de `02` §3: `BEGIN`, la consulta y `COMMIT` alrededor de un simple `SELECT`.

---

**04 → 2.** ¿Qué hace PostgreSQL con el `COMMIT` de una transacción en la que falló una sentencia? 🟢

⏱️ **30 segundos** — Lo convierte en `ROLLBACK`. La transacción quedó abortada al fallar la
sentencia, y todo lo que hizo se deshace.

🗣️ **2 minutos** — Mientras tanto, cualquier sentencia responde `current transaction is aborted,
commands ignored until end of transaction block`. Al mandar `COMMIT`, el servidor contesta con la
etiqueta `ROLLBACK`, que `pg` enseñó tal cual en `r.command`.

🔬 **El detalle** — **Motor**: MySQL deshace solo la sentencia fallida y deja la transacción usable,
como compara `04/01` §3. Por eso el mismo código de «capturo y sigo» se comporta distinto según el
motor.

---

**04 → 3.** ¿Qué dos condiciones necesita pgjdbc para leer un resultado por tramos? 🟢

⏱️ **30 segundos** — La conexión sin autocommit, con `setAutoCommit(false)`, y un tamaño de tramo
con `setFetchSize`.

🗣️ **2 minutos** — Con las dos, el driver abre un cursor en el servidor y trae las filas de mil en
mil: 237 MB contra una base de 221 MB para el millón de pedidos. Sin la primera, ignora la segunda
en silencio y trae el resultado entero: 405 MB.

🔬 **El detalle** — **Driver**; la documentación añade que el `Statement` tiene que ser
`TYPE_FORWARD_ONLY`, que es el valor por defecto. El cursor muere con la transacción, y por eso el
autocommit lo impide.

---

**04 → 4.** ¿Qué es un cursor con nombre en psycopg? 🟢

⏱️ **30 segundos** — Un cursor que vive en el servidor, creado con `con.cursor(name="…")`, del que
psycopg va trayendo las filas por tramos de `itersize`.

🗣️ **2 minutos** — El cursor normal de psycopg trae el resultado entero al cliente. El con nombre
hace un `DECLARE` en el servidor y recoge las filas poco a poco. Medido: 41 116 kB recorriendo el
millón de pedidos, igual que la base del proceso, contra 96 348 kB del cursor normal.

🔬 **El detalle** — **Driver** sobre un mecanismo del **motor**, `DECLARE CURSOR`. Vive dentro de la
transacción, que psycopg ya abre sola.

---

**04 → 5.** Distingue lo que pasa con un cambio en dos pasos sin transacción en pgjdbc y en psycopg,
cuando el segundo falla. 🟡

⏱️ **30 segundos** — En pgjdbc el paso 1 queda confirmado, porque cada sentencia se confirma sola.
En psycopg no queda nada, porque el paso 1 abrió una transacción que se deshizo al cerrar la
conexión.

🗣️ **2 minutos** — Corrido con `PED-99999`: en pgjdbc, `pg` y pgx quedó en `PENDIENTE`, medio cambio
aplicado; en psycopg, en `ANULADO`. El comportamiento de psycopg parece más seguro, y tiene su
propio riesgo: si nadie cierra ni confirma, la transacción queda abierta.

🔬 **El detalle** — **Driver** en los dos casos. La conclusión no es elegir el driver que falla
mejor, sino escribir la transacción explícita en los dos.

---

**04 → 6.** ¿Por qué en TypeScript una transacción no se puede hacer con `pool.query`? 🟡

⏱️ **30 segundos** — Porque cada `pool.query` pide una conexión al *pool* y la devuelve: el `BEGIN`,
los pasos y el `COMMIT` pueden ir a conexiones distintas, y una transacción vive en una sola.

🗣️ **2 minutos** — Hay que pedir una conexión con `pool.connect()`, mandar por ella `BEGIN`, los
pasos y `COMMIT` o `ROLLBACK`, y devolverla con `release()` en el `finally`. Así se corrió en `04`
§3.

🔬 **El detalle** — **Driver**: `pg` no tiene un objeto de transacción, y la forma correcta está en
su documentación de transacciones.

---

**04 → 7.** ¿Es el autocommit del estándar SQL, del motor o del driver? Responde por separado. 🟡

⏱️ **30 segundos** — El estándar deja al implementador cuándo empieza una transacción. PostgreSQL
confirma cada sentencia suelta. Y el driver decide si manda un `BEGIN` antes: psycopg sí, los otros
tres no.

🗣️ **2 minutos** — Por eso el mismo SQL enviado desde Java y desde Python se comporta distinto sin
que el motor cambie: lo que cambia es lo que el driver le manda.

🔬 **El detalle** — ISO/IEC 9075 es de pago y no he verificado sus cláusulas. La obligación de
psycopg viene de la PEP 249, que es del lenguaje, no de SQL.

---

**04 → 8.** Diferencia cómo avisan pgjdbc, psycopg, `pg` y pgx de un `COMMIT` convertido en
`ROLLBACK`. 🟡

⏱️ **30 segundos** — pgjdbc y psycopg no avisan: el `commit()` vuelve sin error. `pg` devuelve el
resultado con la etiqueta `ROLLBACK`. pgx devuelve el error `commit unexpectedly resulted in
rollback`.

🗣️ **2 minutos** — Corrido en los cuatro con el paso 2 capturado dentro de la transacción: en los
cuatro, `PED-99999` siguió en `ANULADO`. Solo pgx lo trató como el error que es.

🔬 **El detalle** — **Driver.** El motor responde lo mismo a todos; lo que cambia es si el driver
mira la respuesta. La defensa no depende de eso: no capturar dentro de la transacción.

---

**04 → 9.** ¿Qué hace `defer tx.Rollback(ctx)` en Go después de un `Commit` que salió bien? 🟡

⏱️ **30 segundos** — Nada: la transacción ya está cerrada, y el `Rollback` no la toca.

🗣️ **2 minutos** — Por eso es la costumbre buena: se escribe una vez justo después del `Begin` y
cubre todos los caminos de error, incluido un `panic`, sin tener que recordar el `Rollback` en cada
`return`.

🔬 **El detalle** — **Driver.** El `Rollback` sobre una transacción ya cerrada devuelve un error que
se ignora; lo que importa es que ningún camino deja la conexión con la transacción abierta.

---

**04 → 10.** Un servicio captura el error del segundo paso de una transacción y confirma. Explica
qué queda guardado y por qué nadie se entera. ¿Lo fija el estándar o es cosa del motor? 🟠

⏱️ **30 segundos** — No queda nada: la transacción quedó abortada con el error y el `COMMIT` se
convirtió en `ROLLBACK`. Nadie se entera porque en pgjdbc y psycopg el `commit()` no da error.

🗣️ **2 minutos** — Corrido: tras tragarse el error, la siguiente sentencia falla con `current
transaction is aborted`, pero el `commit()` vuelve limpio, y el paso 1 no está en la base. El código
cree que guardó el cambio de estado.

🔬 **El detalle** — **Motor** el aborto; **driver** el silencio. Se descubre mirando los datos, y
suele ser días después. La corrección es dejar que la excepción salga del bloque, o usar un punto de
guardado si de verdad hay que seguir.

---

**04 → 11.** Explica por qué la transacción implícita de psycopg produce conexiones `idle in
transaction`, y cómo se evita. 🟠

⏱️ **30 segundos** — Porque cualquier sentencia, incluido un `SELECT`, abre la transacción, y si el
código no hace `commit` ni `rollback`, la conexión se queda esperando dentro de ella.

🗣️ **2 minutos** — En un servicio, eso es una conexión del *pool* con la transacción abierta,
reteniendo el horizonte del `VACUUM`. Se evita de tres formas: `autocommit=True` en las conexiones
que solo leen; bloques `with con.transaction()` para las que escriben; y el `with pool.connection()`
del *pool*, que confirma o deshace al salir.

🔬 **El detalle** — **Driver.** La defensa en el servidor es `idle_in_transaction_session_timeout`,
de `04/05` §5, que convierte la fuga en un `FATAL` visible.

---

**04 → 12.** Con autocommit y `setFetchSize(1000)`, pgjdbc usó 405 MB para un millón de filas.
Explica el mecanismo. 🟠

⏱️ **30 segundos** — El cursor del servidor muere al final de la transacción, y en autocommit la
transacción termina con la sentencia. pgjdbc lo sabe, ignora el `fetchSize` sin avisar y trae el
resultado entero.

🗣️ **2 minutos** — Es exactamente lo que dice su documentación: con autocommit, vuelve en silencio a
traerlo todo. 405 MB frente a los 368 MB de pedirlo de golpe a propósito y los 237 MB de hacerlo
bien, con `setAutoCommit(false)`.

🔬 **El detalle** — **Driver**, sobre una regla del **motor**: los cursores sin `WITH HOLD` viven
dentro de su transacción.

---

**04 → 13.** ¿Qué cuesta leer un millón de filas con un cursor del servidor, además de la conexión?
🟠

⏱️ **30 segundos** — Una transacción abierta mientras dura el recorrido, con su instantánea
reteniendo el horizonte de limpieza de toda la base.

🗣️ **2 minutos** — Una exportación de una hora es una transacción de una hora: el `VACUUM` no
recicla nada posterior a su inicio, y un `ALTER TABLE` sobre la tabla esperaría detrás. Por tramo,
cuesta además un viaje de ida y vuelta.

🔬 **El detalle** — **Motor.** La alternativa para exportar es `COPY … TO STDOUT`, que es una sola
sentencia: retiene su instantánea lo que tarda en ejecutarse, y ni un segundo más.

---

**04 → 14.** Si de verdad hay que seguir una transacción tras un error de una sentencia, ¿cómo se
hace sin perder el resto? 🟠

⏱️ **30 segundos** — Con un punto de guardado alrededor de la sentencia que puede fallar: si falla,
se vuelve al punto y la transacción sigue viva.

🗣️ **2 minutos** — En psycopg, anidar `con.transaction()` abre un `SAVEPOINT`. Corrido:

```python
with con.transaction():                                   # la transacción de fuera
    con.execute("UPDATE pedidos SET estado = 'PENDIENTE' WHERE codigo = 'PED-99999'")
    try:
        with con.transaction():                           # anidada: psycopg abre un SAVEPOINT
            con.execute("UPDATE pedidos SET total = -1 WHERE codigo = 'PED-99999'")
    except psycopg.errors.CheckViolation:
        print("paso 2 deshecho hasta el punto de guardado")
```

```text
paso 2 deshecho hasta el punto de guardado
estado dentro: PENDIENTE
estado confirmado: PENDIENTE
```

El paso 1 se confirmó; después se compensó para dejar `PED-99999` en `ANULADO`.

🔬 **El detalle** — **Motor** el `SAVEPOINT`. Su coste está en `04/01` §7: cada uno es una
subtransacción, y pasados 64 por sesión se nota en las demás.

---

**04 → 15.** Diagnostica: la exportación nocturna muere por memoria desde que la tabla pasó del
millón de filas. Da tres hipótesis por lenguaje del servicio y la corrección de cada una. 🔴

⏱️ **30 segundos** — El driver trae el resultado entero antes de dar la primera fila. En Java,
autocommit o sin `fetchSize`; en Python, cursor sin nombre; en Node, `query` sin cursor; en Go,
`CollectRows` o acumular en un *slice*.

🗣️ **2 minutos** — Las correcciones, medidas en `04` §5: `setAutoCommit(false)` más `setFetchSize`;
`con.cursor(name=…)` con `itersize`; `pg-cursor` con `read(1000)`; y recorrer `rows` en Go sin
acumular. Tercera hipótesis en todos: el código lee por tramos pero **guarda** cada fila en una
lista para escribirla al final.

🔬 **El detalle** — Para una exportación a fichero, la solución más barata es `COPY … TO STDOUT`: el
servidor genera el CSV y el cliente solo lo copia. Medido en Python: 57 376 295 bytes en 1 039 ms
con la memoria en la base, 40 784 kB.

---

**04 → 16.** Escribe, en el lenguaje que prefieras, una transacción de dos pasos que no pueda dejar
ni media escritura ni la transacción abierta, pase lo que pase. 🔴

⏱️ **30 segundos** — En Go: `Begin`, `defer tx.Rollback`, los dos pasos devolviendo el error, y
`Commit` al final.

🗣️ **2 minutos** — La corrida en `04` §3:

```go
tx, err := pool.Begin(ctx)
if err != nil {
	return err
}
defer tx.Rollback(ctx) // no hace nada si ya se confirmó
if _, err := tx.Exec(ctx, paso1); err != nil {
	return err
}
if _, err := tx.Exec(ctx, paso2); err != nil {
	return err
}
return tx.Commit(ctx)
```

Con el paso 2 fallando, `PED-99999` siguió en `ANULADO`.

🔬 **El detalle** — Ningún `return` deja la transacción abierta, y un error en el `Commit` también se
devuelve. En los otros lenguajes, lo equivalente es el `try` con `rollback` en Java, el `with
con.transaction()` en Python y el `try … catch … finally` con `release()` en TypeScript.

---

**04 → 17.** Revisa: `try { paso1(); try { paso2(); } catch (e) { log(e); } commit(); } catch (e) {
rollback(); }`. Di qué queda en la base si falla el paso 2, en pgjdbc, y cómo lo corriges. 🔴

⏱️ **30 segundos** — Nada. El paso 2 deja la transacción abortada, el `catch` interno lo registra y
sigue, y el `commit()` se convierte en `ROLLBACK` sin error. El código cree haber confirmado el paso
1.

🗣️ **2 minutos** — Es el caso corrido en `04` §4 con pgjdbc: `commit: sin error` y el pedido sin el
cambio. La corrección: quitar el `catch` interno para que la excepción llegue al `rollback`; o, si
el paso 2 es opcional, envolverlo en un punto de guardado con `con.setSavepoint()` y
`con.rollback(punto)`.

🔬 **El detalle** — **Motor** el aborto y **driver** el silencio. En pgx el `commit` habría devuelto
`commit unexpectedly resulted in rollback`; en pgjdbc no hay aviso, y por eso el patrón es peligroso
precisamente en Java.

---

**04 → 18.** Diseña la exportación de todos los pedidos a CSV en el lenguaje que prefieras, con la
memoria acotada, y di qué retiene en la base mientras dura. 🔴

⏱️ **30 segundos** — Con `COPY (SELECT …) TO STDOUT WITH (FORMAT csv, HEADER)`: el servidor genera
el CSV y el cliente lo copia a fichero por trozos. Retiene la instantánea de esa única sentencia
mientras se ejecuta.

🗣️ **2 minutos** — Corrido en Python:

```python
with psycopg.connect("") as con, open("/tmp/pedidos.csv", "wb") as salida:
    with con.cursor().copy("COPY (SELECT codigo, estado, total, creado_en FROM pedidos ORDER BY id) TO STDOUT WITH (FORMAT csv, HEADER)") as copia:
        for trozo in copia:                     # el servidor manda el CSV ya hecho, por trozos
            salida.write(trozo)
```

```text
57376295 bytes en 1039 ms, VmHWM: 40784 kB
['codigo,estado,total,creado_en', 'PED-00001,ENTREGADO,6949.33,2025-07-13 16:19:31.89434+00', 'PED-00002,ENTREGADO,5157.80,2024-01-07 20:04:48.399608+00']
```

🔬 **El detalle** — **Motor** el `COPY`, que no está en el estándar. Si la exportación necesita
lógica fila a fila en el lenguaje, la alternativa es el cursor por tramos de `04` §5, que retiene
una transacción mientras dure el recorrido.

---

## Capítulo 05 — Java

Las 18 preguntas de [`05`](05-java.md).

**05 → 1.** Ordena de menos a más abstracción JDBC, `JdbcClient`, jOOQ, MyBatis y JPA, y di quién
escribe el SQL en cada una. 🟢

⏱️ **30 segundos** — JDBC y `JdbcClient`, donde lo escribes tú; MyBatis, donde también lo escribes
tú pero fuera del código; jOOQ, donde lo construye la biblioteca desde tu código Java; y JPA, donde
lo escribe Hibernate desde tus entidades.

🗣️ **2 minutos** — `JdbcClient` añade sobre JDBC el mapeo de filas a objetos. MyBatis añade el
enlace del SQL a un método. jOOQ añade la comprobación del SQL al compilar. JPA añade el ciclo de
vida de los objetos y el SQL generado.

🔬 **El detalle** — El orden de MyBatis y jOOQ es discutible: MyBatis abstrae menos el SQL y más el
mapeo. Lo que no se discute es que JPA es la única capa en la que el SQL que se ejecuta no está
escrito en ninguna parte del código.

---

**05 → 2.** ¿Qué es un motor embebido? Da dos ejemplos de Java. 🟢

⏱️ **30 segundos** — Un motor que corre dentro del proceso de la aplicación, sin servidor ni red. H2
y Apache Derby.

🗣️ **2 minutos** — Se conecta con una URL —`jdbc:h2:mem:tienda`, `jdbc:derby:memory:tienda;
create=true`— y, en memoria, desaparece al terminar el proceso. Por eso fue la base por defecto de
tutoriales y pruebas durante años.

🔬 **El detalle** — Fuera de Java, SQLite es el embebido más usado, y el corpus lo trata como motor
de contraste en los bloques anteriores.

---

**05 → 3.** ¿Qué pasó con Apache Derby en 2025? 🟢

⏱️ **30 segundos** — Se retiró: el 10 de octubre de 2025 sus desarrolladores votaron dejarlo en solo
lectura. No habrá más versiones ni correcciones.

🗣️ **2 minutos** — La 10.17.1.0, de noviembre de 2023, es la última. Su web, sus listas y su gestor
de errores quedan congelados. Un proyecto que lo use tiene una migración pendiente, aunque hoy
funcione.

🔬 **El detalle** — Es el caso de 🪦 del capítulo: tutoriales y proyectos heredados lo seguirán
mencionando durante años, y la respuesta actualizada es decir que está retirado.

---

**05 → 4.** ¿Qué diferencia hay entre `#{}` y `${}` en MyBatis? 🟢

⏱️ **30 segundos** — `#{}` es un parámetro, que MyBatis convierte en `?`. `${}` pega el texto tal
cual dentro del SQL.

🗣️ **2 minutos** — La documentación de MyBatis dice que con `${}` no modifica ni escapa la cadena, y
pone como ejemplo un `ORDER BY ${columna}`. Es la única forma de meter un identificador, y por eso
existe; con un valor del usuario, es la inyección de `02`.

🔬 **El detalle** — Si hace falta `${}` para un nombre de columna, el valor tiene que venir de una
lista blanca, como en `02` §4.

---

**05 → 5.** ¿Es JPQL lo mismo que SQL? Di quién lo traduce y dónde lo ves. 🟡

⏱️ **30 segundos** — No. JPQL consulta entidades y sus atributos; Hibernate lo traduce a SQL. El SQL
de verdad se ve en el log, con `hibernate.show_sql`.

🗣️ **2 minutos** — `from Pedido p where p.codigo = :codigo` se ejecutó como `select p1_0.id,
p1_0.codigo, p1_0.estado, p1_0.total from pedidos p1_0 where p1_0.codigo=?`. El nombre `Pedido` es
el de la entidad, no el de la tabla.

🔬 **El detalle** — **Especificación de Jakarta** para JPQL, **Hibernate** para la traducción. Lo que
llega a la base, y lo que hay que optimizar, es el SQL generado.

---

**05 → 6.** Distingue `REQUIRED` de `REQUIRES_NEW`: qué conexión usa cada una y qué pasa con sus
escrituras si la externa falla. 🟡

⏱️ **30 segundos** — `REQUIRED` usa la conexión y la transacción de la externa, y se deshace con
ella. `REQUIRES_NEW` usa otra conexión y otra transacción, y su escritura sobrevive aunque la
externa falle.

🗣️ **2 minutos** — Corrido: con `REQUIRED`, el mismo `pid` 33193 dentro y fuera, y `actualizado_en`
volvió a nulo tras el fallo. Con `REQUIRES_NEW`, `pid` 33191 fuera y 33192 dentro, y la escritura
interna se quedó.

🔬 **El detalle** — **Spring**, sobre dos conexiones reales del **motor**. `NESTED` sería un punto de
guardado en la misma conexión, que es lo único anidado de verdad.

---

**05 → 7.** ¿Por qué Hibernate hizo dos consultas para leer un pedido con sus líneas, y en qué
momento hizo la segunda? 🟡

⏱️ **30 segundos** — Porque la colección `lineas` es perezosa: Hibernate carga el pedido y deja las
líneas sin cargar hasta que alguien las usa. La segunda consulta salió al recorrer `pedido.lineas`.

🗣️ **2 minutos** — En la salida, la segunda línea `Hibernate:` aparece entre la del estado y las de
las líneas: justo donde el código empezó el bucle. Con un pedido son dos consultas; con cien, ciento
una.

🔬 **El detalle** — **Hibernate**: `@OneToMany` es perezosa por defecto en JPA. Cómo se detecta el
N+1 en el log del motor y sus cuatro correcciones son del bloque 11.

---

**05 → 8.** ¿Está `LIMIT` en el estándar SQL? Responde para la norma, para PostgreSQL, para H2 y
para Derby. 🟡

⏱️ **30 segundos** — La norma usa `FETCH FIRST n ROWS ONLY`, no `LIMIT`. PostgreSQL y H2 aceptan los
dos. Derby solo el del estándar.

🗣️ **2 minutos** — Corrido en los dos embebidos: H2 devolvió `PED-00043 PED-99999` con los dos;
Derby respondió `Syntax error: Encountered "LIMIT" at line 1, column 48.` y aceptó `FETCH FIRST`.

🔬 **El detalle** — ISO/IEC 9075 es de pago y no he verificado la cláusula: lo del `FETCH FIRST` es
doctrina asentada. Qué es portable entre los motores del corpus es de `02/08`.

---

**05 → 9.** ¿Qué ventaja tiene generar las clases de jOOQ desde el esquema frente a escribir los
nombres como texto? 🟡

⏱️ **30 segundos** — Que un nombre de tabla o de columna mal escrito, o un tipo equivocado, es un
error de compilación y no un error en producción.

🗣️ **2 minutos** — Con nombres como texto, como en el ejemplo, jOOQ construye y parametriza el SQL
igual, pero no sabe si `pedido_lineas.cantidad` existe. Con las clases generadas, sí, y el
autocompletado del editor pasa a saber del esquema.

🔬 **El detalle** — El precio es un paso de generación en la construcción, que necesita una base con
el esquema al día; el esquema y el código tienen que evolucionar juntos.

---

**05 → 10.** Un método anotado con `@Transactional` llama a otro método anotado del mismo objeto.
Explica qué transacción tiene el segundo y por qué. 🟠

⏱️ **30 segundos** — La del primero, sin más: su anotación no hace nada. La aplica un *proxy* que
envuelve al objeto, y una llamada desde dentro del objeto no pasa por el *proxy*.

🗣️ **2 minutos** — La documentación de Spring lo dice así: en el modo de *proxy*, que es el de por
defecto, la autoinvocación no produce una transacción en tiempo de ejecución aunque el método esté
anotado. Un `REQUIRES_NEW` en el segundo método se ignora en silencio.

🔬 **El detalle** — **Spring.** Las salidas son mover el segundo método a otro objeto, usar
`TransactionTemplate` de forma explícita, o el modo AspectJ, que teje el código y no usa *proxy*.

---

**05 → 11.** Un método `@Transactional` lanza una `IOException` después de escribir. ¿Qué queda en
la base, con la configuración por defecto, y cómo lo cambiarías? 🟠

⏱️ **30 segundos** — Queda todo: por defecto, Spring solo deshace ante excepciones no comprobadas y
`Error`. Una `IOException` es comprobada, y la transacción se confirma.

🗣️ **2 minutos** — Se cambia con `@Transactional(rollbackFor = Exception.class)`, o envolviendo la
excepción en una no comprobada. Lo que no se hace es asumir que cualquier excepción deshace.

🔬 **El detalle** — **Spring**, de su documentación sobre el rollback declarativo. Es una convención
heredada de los EJB, y sorprende a quien viene de otros marcos.

---

**05 → 12.** ¿Por qué `REQUIRES_NEW` puede agotar el *pool* bajo carga, y cómo lo tendrías en cuenta
al dimensionarlo? 🟠

⏱️ **30 segundos** — Porque cada petición retiene dos conexiones a la vez: la de la externa, que no
suelta hasta terminar, y la de la interna. Con el *pool* casi lleno, las internas no consiguen la
suya.

🗣️ **2 minutos** — Corrido con un *pool* de uno: `Could not open JDBC Connection for transaction`.
En el cálculo de Little de `01` §4, esas peticiones cuentan doble durante la parte interna. Y si
todas las peticiones retienen una y esperan otra, puede llegar un punto en que nadie avance.

🔬 **El detalle** — **Spring y biblioteca.** Por eso `REQUIRES_NEW` se usa poco y a propósito, y la
alternativa para auditoría es a menudo escribir el registro fuera de la transacción, después.

---

**05 → 13.** ¿Cuándo elegirías jOOQ en vez de JPA, y cuándo JPA en vez de jOOQ? 🟠

⏱️ **30 segundos** — jOOQ cuando el SQL es el protagonista: informes, consultas dinámicas, ventanas
y CTE. JPA cuando lo son los objetos: un dominio con muchas entidades que se cargan, se cambian y se
guardan de una en una.

🗣️ **2 minutos** — Con jOOQ ves y controlas cada consulta, con seguridad de tipos. Con JPA escribes
menos código para el caso común y pagas en SQL generado que hay que vigilar. Muchos proyectos usan
los dos: JPA para el alta y la edición, jOOQ para los informes.

🔬 **El detalle** — **Convención** que conviene desmontar: «JPA o SQL». Se pueden mezclar sobre la
misma conexión y la misma transacción.

---

**05 → 14.** Un proyecto heredado prueba contra H2 y despliega contra PostgreSQL. Da dos riesgos
concretos y qué harías antes de tocar nada. 🟠

⏱️ **30 segundos** — Que una consulta que H2 acepta falle en PostgreSQL, o al revés, y que el mismo
SQL dé resultados distintos por diferencias de tipos o de semántica. Antes de tocar nada, correría
la batería de pruebas contra un PostgreSQL de verdad para ver cuántas fallan.

🗣️ **2 minutos** — Un ejemplo corrido de sintaxis es el `LIMIT` que Derby rechaza y H2 acepta: los
motores no aceptan lo mismo. Los de semántica —tipos, zonas horarias, `jsonb`— no dan error, y son
peores. El caso reproducido de una prueba que pasa en H2 y falla en PostgreSQL es del bloque 11.

🔬 **El detalle** — Los modos de compatibilidad de H2 imitan la sintaxis, no el motor. El paso
siguiente es probar contra el motor de producción en un contenedor, que es de lo que trata `11/05`.

---

**05 → 15.** Un registro de auditoría tiene que guardarse aunque la operación de negocio falle.
Diseña la transacción con Spring y di qué cuesta. 🟠

⏱️ **30 segundos** — El registro de auditoría en un método de otro objeto, con
`@Transactional(propagation = REQUIRES_NEW)`: su propia conexión y su propia confirmación, que
sobreviven al fallo de la operación.

🗣️ **2 minutos** — Corrido con `TransactionTemplate`: la escritura de la interna quedó aunque la
externa falló. Tiene que estar en otro objeto, o la autoinvocación la deja sin transacción propia.

🔬 **El detalle** — Cuesta una segunda conexión mientras la primera sigue retenida, que cuenta en el
*pool*, y una inconsistencia deliberada: queda la auditoría de algo que no ocurrió, que es lo que se
quería.

---

**05 → 16.** Diagnostica: tras añadir `REQUIRES_NEW` a un método de auditoría, el servicio empieza a
fallar con `Could not open JDBC Connection for transaction` en las horas punta. Da el mecanismo y
dos correcciones. 🔴

⏱️ **30 segundos** — Cada petición retiene ahora dos conexiones mientras audita, y en la hora punta
el *pool* no tiene la segunda. Correcciones: dimensionar el *pool* contando las dos, o sacar la
auditoría de la transacción.

🗣️ **2 minutos** — Es el tercer escenario corrido de `05` §6, con un *pool* de uno. El log de
HikariCP de la causa dirá `total=N, active=N, idle=0, waiting=M`. Sacar la auditoría de la
transacción significa escribirla después del `COMMIT` o en un evento, y aceptar que puede perderse
si el proceso cae justo entonces.

🔬 **El detalle** — Subir el *pool* sin más tiene el límite de `01` §4: el techo de la base es común
a todas las instancias.

---

**05 → 17.** Diseña la capa de datos de un servicio de pedidos nuevo en Java: qué capa usarías para
el alta, cuál para los informes y cuál para una carga masiva nocturna, y por qué. 🔴

⏱️ **30 segundos** — Alta con JPA o `JdbcClient`, informes con jOOQ o `JdbcClient`, carga masiva con
`COPY` desde el driver. Todo sobre el mismo *pool* HikariCP.

🗣️ **2 minutos** — El alta toca pocas filas con reglas de dominio: JPA ahorra código si el dominio
es rico, `JdbcClient` si es sencillo. Los informes necesitan SQL a la vista, con ventanas y
agregados: jOOQ o `JdbcClient`. La carga masiva no pasa por ningún ORM: un `COPY` o inserciones por
lotes con confirmación cada pocos miles de filas.

🔬 **El detalle** — La decisión que más importa no es la biblioteca sino la transacción: el alta
corta, los informes por tramos o en réplica, y la carga partida y reanudable, como en `04/05` §5.

---

**05 → 18.** Revisa: `@Transactional public void cobrar() { guardarPago(); enviarCorreo(); }` con
`guardarPago()` y `enviarCorreo()` en el mismo objeto y el segundo anotado con `REQUIRES_NEW`. Di
qué transacciones existen de verdad y qué pasa si el correo falla. 🔴

⏱️ **30 segundos** — Existe una sola, la de `cobrar()`. El `REQUIRES_NEW` de `enviarCorreo()` se
ignora por autoinvocación. Si el correo falla con una excepción no comprobada, se deshace también el
pago.

🗣️ **2 minutos** — Y hay un problema más de fondo: un correo no es una operación de base de datos, y
meterlo dentro de la transacción la alarga con una llamada de red. Si la transacción se deshace
después de mandar el correo, el cliente recibe un correo de un pago que no existe.

🔬 **El detalle** — La corrección: el pago en su transacción, y el correo **después del `COMMIT`**,
por ejemplo con un evento que se procese al confirmar. Es el mismo razonamiento de la pasarela de
pago fuera de la transacción de `04/02` §9.

---

## Capítulo 06 — Python, TypeScript y Go

Las 17 preguntas de [`06`](06-python-typescript-y-go.md).

**06 → 1.** ¿Qué son SQLAlchemy Core y el ORM de SQLAlchemy, y cómo se relacionan? 🟢

⏱️ **30 segundos** — Core manda SQL, escrito a mano o construido, y convierte filas. El ORM mapea
clases a tablas y funciona **encima** de Core.

🗣️ **2 minutos** — Se pueden usar por separado o juntos, sobre el mismo motor y la misma
transacción: el ORM para las entidades y Core para los informes. Los dos van sobre un driver; en el
corpus, psycopg 3, con la URL `postgresql+psycopg://`.

🔬 **El detalle** — **Biblioteca.** Es la división que en Java son dos bibliotecas distintas,
`JdbcClient` o jOOQ por un lado e Hibernate por otro.

---

**06 → 2.** ¿Qué hace sqlc, en una frase? 🟢

⏱️ **30 segundos** — Lee consultas SQL con nombre y genera el código Go tipado que las ejecuta.

🗣️ **2 minutos** — De `-- name: LineasDePedido :many` generó una estructura `LineasDePedidoRow` con
los tipos del esquema —`int16` para `smallint`, `int32` para `integer`— y una función
`LineasDePedido(ctx, codigo)`. El SQL es tuyo; el código Go, suyo.

🔬 **El detalle** — **Herramienta**, no biblioteca: se ejecuta en la construcción, con `sqlc
generate`, y el programa final solo usa pgx.

---

**06 → 3.** ¿De dónde saca Kysely el esquema de la base? 🟢

⏱️ **30 segundos** — De una interfaz de TypeScript que describe las tablas, escrita a mano o
generada desde la base. Kysely no lee la base.

🗣️ **2 minutos** — Si la interfaz miente, TypeScript compila y el programa falla o devuelve algo
distinto en producción. Por eso los equipos que usan Kysely generan la interfaz desde la base en la
construcción.

🔬 **El detalle** — **Biblioteca.** Los tipos también tienen que respetar lo que devuelve `pg`: un
`bigint` es `string`, no `number`.

---

**06 → 4.** ¿Qué hace `Preload` en GORM? 🟢

⏱️ **30 segundos** — Carga una asociación en una consulta aparte: primero los pedidos, después las
líneas de todos ellos.

🗣️ **2 minutos** — Corrido: `SELECT * FROM "pedidos" WHERE codigo = $1 … LIMIT $2` y `SELECT * FROM
"pedido_lineas" WHERE "pedido_lineas"."pedido_id" = $1 ORDER BY linea`. Sin `Preload`, GORM no carga
la asociación: `Lineas` queda vacío, sin consulta perezosa.

🔬 **El detalle** — **Biblioteca.** Con varios pedidos, la segunda consulta usa `IN` con todos los
identificadores: dos consultas en total, no una por pedido.

---

**06 → 5.** Distingue sqlc de jOOQ: qué escribe el programador y qué genera la herramienta en cada
uno. 🟡

⏱️ **30 segundos** — En sqlc escribes el SQL y la herramienta genera el código Go. En jOOQ escribes
código Java y la biblioteca construye el SQL; con generación, las clases del esquema salen de la
base.

🗣️ **2 minutos** — Los dos buscan lo mismo: que un error de esquema se vea antes de ejecutar. sqlc
lo consigue analizando el SQL contra el esquema; jOOQ, con tipos de Java que representan tablas y
columnas.

🔬 **El detalle** — sqlc deja el SQL a la vista tal cual se ejecuta. jOOQ permite componer SQL
dinámico, con partes opcionales, que en sqlc hay que resolver con varias consultas o con SQL que ya
contemple los casos.

---

**06 → 6.** ¿Por qué el log de SQLAlchemy muestra `BEGIN (implicit)` y un `ROLLBACK` en una lectura?
🟡

⏱️ **30 segundos** — Porque va sobre psycopg, que abre una transacción con la primera sentencia, y
SQLAlchemy la deshace al cerrar la conexión sin `commit`.

🗣️ **2 minutos** — Es la transacción implícita de `04` §2 vista desde la capa de arriba. En una
lectura no hace daño; en una escritura sin `commit`, lo escrito se pierde al cerrar.

🔬 **El detalle** — **Driver y biblioteca.** SQLAlchemy lo registra como `implicit` para distinguirla
de una transacción que el código pidió con `begin()`.

---

**06 → 7.** El log de GORM enseña `WHERE codigo = 'PED-00042'`. ¿Concatenó GORM el valor? Di cómo lo
compruebas, y si lo que ves es cosa del motor o de la biblioteca. 🟡

⏱️ **30 segundos** — No. GORM sustituye los valores en su log para que se lea. Se comprueba en el
log del servidor, con `log_statement`: llegó `WHERE codigo = $1` con `Parameters: $1 = 'PED-00042'`.

🗣️ **2 minutos** — Corrido: el servidor registró `execute stmtcache_…: SELECT * FROM "pedidos" WHERE
codigo = $1 ORDER BY "pedidos"."id" LIMIT $2`. El log del cliente sirve para leer y para copiar a
una consola; para saber qué recibe la base, el del servidor.

🔬 **El detalle** — **Biblioteca.** Lo que sí concatena GORM es lo que se le pasa como fragmento de
SQL, como el texto de `Order`, y eso su documentación de seguridad lo dice.

---

**06 → 8.** ¿Qué diferencia hay entre usar `pgx` directamente y usarlo a través de `database/sql`? 🟡

⏱️ **30 segundos** — Directamente tienes los tipos y funciones propios de pgx y de PostgreSQL. A
través de `database/sql` tienes una interfaz común a cualquier motor, con su propio *pool*, y
pierdes parte de lo propio.

🗣️ **2 minutos** — `database/sql` sirve cuando el código tiene que poder cambiar de motor o cuando
una biblioteca lo exige. pgx directo da `pgxpool`, `CopyFrom`, tipos como `pgtype.Numeric` y el
control del `context`.

🔬 **El detalle** — **Lenguaje** la interfaz, **driver** lo demás. pgx se registra como driver `pgx`
con un `import` en blanco del paquete `stdlib`.

---

**06 → 9.** ¿Está alguna de estas bibliotecas en el estándar SQL? Responde para la norma, para el
protocolo de PostgreSQL y para las bibliotecas. 🟡

⏱️ **30 segundos** — Ninguna. La norma no habla de lenguajes; el protocolo es de PostgreSQL; y las
bibliotecas son de cada ecosistema.

🗣️ **2 minutos** — Lo común a todas es el protocolo extendido de PostgreSQL: todas terminan mandando
`$1` y el valor aparte. Lo que las distingue es quién escribe el SQL y qué se comprueba antes de
ejecutarlo.

🔬 **El detalle** — ISO/IEC 9075 es de pago y no he verificado sus cláusulas. Las especificaciones de
lenguaje —DB-API, `database/sql`— tampoco son de SQL.

---

**06 → 10.** En Kysely, un compañero declara `id: number` para una columna `bigint`. ¿Qué pasa al
compilar y qué pasa al ejecutar? 🟠

⏱️ **30 segundos** — Al compilar, nada: TypeScript se fía de la interfaz. Al ejecutar, `pg` devuelve
la cadena `"42"`, y el código la trata como número: `id + 1` concatena.

🗣️ **2 minutos** — Es la trampa de `03` §4 con un sello de seguridad falso encima. La corrección es
declarar `string`, o convertir el `bigint` en el driver con `setTypeParser(20, BigInt)` y declarar
`bigint`.

🔬 **El detalle** — **Biblioteca y driver.** Generar la interfaz desde la base evita el error de
declaración, pero no decide qué tipo entrega `pg`: eso sigue siendo del driver.

---

**06 → 11.** ¿Por qué `First` de GORM añade un `ORDER BY` que nadie escribió, y qué cuesta en una
tabla grande sin índice por esa columna? 🟠

⏱️ **30 segundos** — Porque «el primero» no existe sin un orden, y GORM ordena por la clave
primaria. Sin índice por esa columna, el motor tendría que ordenar todas las filas que pasan el
filtro para quedarse con una.

🗣️ **2 minutos** — En `pedidos`, el orden es por `id`, que tiene índice, y el filtro por `codigo`
también: sale barato. En una tabla con clave sin índice útil o con un filtro poco selectivo, `ORDER
BY … LIMIT 1` puede leer mucho más de lo esperado. `Take` no añade orden, y `Last` ordena al revés.

🔬 **El detalle** — **Biblioteca.** Cómo se lee ese plan es de `03/05`: el `Limit` encima de un
`Sort` o de un `Index Scan`.

---

**06 → 12.** ¿Qué gana un equipo de Go al pasar de SQL a mano a sqlc, y qué paga? 🟠

⏱️ **30 segundos** — Gana que los errores de SQL y de tipos se vean al generar, y se ahorra escribir
el escaneo de cada fila. Paga un paso de generación y mantener el esquema donde la herramienta lo
lea.

🗣️ **2 minutos** — El SQL sigue siendo el mismo, a la vista y revisable, y el código generado es el
mismo que se escribiría a mano. Lo que cuesta es el SQL dinámico: filtros opcionales que en SQL a
mano se componen con texto y en sqlc hay que escribir de forma que admitan nulos.

🔬 **El detalle** — **Herramienta.** El esquema que lee sqlc tiene que seguir a las migraciones; si
se queda atrás, genera código para una base que ya no existe.

---

**06 → 13.** Tu servicio en Python usa el ORM de SQLAlchemy y los informes tardan. ¿Qué harías antes
de reescribirlos, y con qué parte de SQLAlchemy los reescribirías? 🟠

⏱️ **30 segundos** — Antes, ver el SQL que generan, con `echo` o con el log del servidor, y contar
consultas. Si hay que reescribir, con Core: SQL a mano o construido, sin objetos.

🗣️ **2 minutos** — Lo más común es un N+1 por carga perezosa, que se arregla sin reescribir, con
`selectinload` o `joinedload`. Si el informe agrega o usa ventanas, el ORM no aporta nada y Core sí:
se escribe el SQL y se reciben filas.

🔬 **El detalle** — **Biblioteca.** Core y el ORM comparten motor y sesión, así que el informe puede
vivir en Core sin cambiar el resto del servicio.

---

**06 → 14.** Explica por qué la frase «con un ORM no hay inyección SQL» es falsa, con un ejemplo de
GORM. 🟠

⏱️ **30 segundos** — Porque los ORM parametrizan los valores, pero aceptan fragmentos de SQL como
texto, y esos no se escapan. En GORM, `db.Order(ordenDelUsuario)` pega el texto tal cual.

🗣️ **2 minutos** — La documentación de seguridad de GORM lista los métodos que no escapan su
entrada: `Order`, `Select`, `Group`, `Having`, `Table`, `Joins`, `Raw`, `Exec`… Con un valor del
usuario ahí, es la inyección de `02`.

🔬 **El detalle** — La corrección es la de `02` §4: el nombre de columna de una lista blanca. Pasa
igual con `${}` de MyBatis y con el SQL de texto de SQLAlchemy.

---

**06 → 15.** Diseña la capa de datos de un servicio de pedidos en TypeScript: qué biblioteca
usarías, cómo mantendrías el esquema del código igual que el de la base, y cómo verías el SQL real.
🔴

⏱️ **30 segundos** — Kysely sobre `pg`, con la interfaz del esquema generada desde la base en cada
construcción; `setTypeParser` para `bigint`, `numeric` y fechas; y el SQL real en el log del
servidor y con `compile()` en el código.

🗣️ **2 minutos** — Las migraciones mandan sobre el esquema; tras aplicarlas, se regenera la
interfaz, y el compilador señala el código que ya no encaja. Los tipos del driver se fijan una vez
al arrancar, como en `03` §4. Transacciones con una conexión prestada del *pool*, y
`connectionTimeoutMillis` puesto, que por defecto no existe.

🔬 **El detalle** — Si el equipo prefiere un ORM, Drizzle con su esquema en código y sus migraciones
cumple lo mismo desde el otro lado: el código es la fuente y la base se genera de él.

---

**06 → 16.** Diagnostica: un servicio en Go con GORM hace una consulta `SELECT *` por cada pedido de
un listado de cien. Da el mecanismo, cómo lo confirmarías en el servidor y la corrección. 🔴

⏱️ **30 segundos** — Es un N+1: el código recorre los cien pedidos y pide las líneas de cada uno por
separado, en un bucle. Se confirma contando consultas en el servidor, y se corrige con `Preload`,
que hace dos.

🗣️ **2 minutos** — GORM no tiene carga perezosa, así que el N+1 viene del propio código: un `Find`
por pedido dentro del bucle. En el servidor, con `log_statement` para el rol de la aplicación
durante una petición, salen ciento una sentencias casi iguales; `Preload("Lineas")` las deja en dos,
con `IN`.

🔬 **El detalle** — **Biblioteca.** Cómo se mide el N+1 en el log del motor, y las cuatro formas de
corregirlo, son del bloque 11. El `SELECT *` añade su propio coste: trae columnas que el listado no
usa.

---

**06 → 17.** Un equipo tiene servicios en los cuatro lenguajes del corpus y quiere una regla común
de acceso a datos. Escríbela en cinco puntos, válida para los cuatro. 🔴

⏱️ **30 segundos** — Uno, todo valor como parámetro y todo nombre de lista blanca. Dos, transacción
explícita en toda operación de más de una sentencia. Tres, *pool* con tiempo de espera fijado.
Cuatro, resultados grandes por tramos. Cinco, el SQL real se revisa en el log del servidor, no en el
del cliente.

🗣️ **2 minutos** — Cada punto tiene su capítulo y su trampa medida: la inyección de `02`, el
`COMMIT` silencioso de `04` §4, el `pg.Pool` que espera para siempre de `01` §5, los 405 MB de
pgjdbc de `04` §5 y el log de GORM de `06` §5.

🔬 **El detalle** — Hay un sexto que suele faltar: los tipos del driver fijados a propósito —dinero,
`bigint`, fechas—, que en TypeScript es obligatorio y en los demás evita las trampas de `03`.

---

## Capítulo 07 — Clientes de Redis y MongoDB

Las 16 preguntas de [`07`](07-clientes-de-redis-y-mongodb.md).

**07 → 1.** ¿Cuánto espera por defecto un driver de MongoDB para elegir servidor? 🟢

⏱️ **30 segundos** — 30 segundos: `serverSelectionTimeoutMS` vale 30 000 por defecto.

🗣️ **2 minutos** — Medido en los cuatro lenguajes con un puerto sin servidor: entre 30 003 y 30 283
ms antes de fallar. Durante ese tiempo, la operación espera.

🔬 **El detalle** — **Especificación de los drivers de MongoDB**, común a los oficiales. Se cambia en
la cadena de conexión: con `serverSelectionTimeoutMS=2000`, falló a los 2 014 ms.

---

**07 → 2.** ¿Qué devuelve redis-py al leer una cadena, si no se configura nada? 🟢

⏱️ **30 segundos** — Bytes: `b'…'`, no una cadena de Python.

🗣️ **2 minutos** — Redis guarda bytes y redis-py no los decodifica salvo que se pida con
`decode_responses=True`. Comparar el resultado con un `str` da siempre falso.

🔬 **El detalle** — **Biblioteca**, leído del cliente: `decode_responses` vale `None` por defecto.

---

**07 → 3.** ¿Qué clase de Jedis sustituye a `JedisPool` desde la 7.2.0? 🟢

⏱️ **30 segundos** — `RedisClient`, que trae el *pool* dentro.

🗣️ **2 minutos** — La documentación de Redis dice que sustituye a `UnifiedJedis`, `JedisPool` y
`JedisPooled`, y el compilador avisa de que `JedisPool` está obsoleto con Jedis 8.0.1.

🔬 **El detalle** — **Biblioteca.** Los tutoriales siguen usando `JedisPool`; la razón de fondo es la
misma de siempre: un objeto `Jedis` suelto no es seguro entre hilos.

---

**07 → 4.** ¿Cuándo abre su primera conexión un `MongoClient`? 🟢

⏱️ **30 segundos** — En la primera operación, no al crearse. Crear el cliente con un servidor que no
existe no da error.

🗣️ **2 minutos** — Por eso la espera de 30 s aparece en la primera consulta, dentro de una petición
de usuario, y no al arrancar el servicio. Si se quiere fallar al arrancar, hay que hacer una
operación a propósito, como un `ping`.

🔬 **El detalle** — **Especificación de los drivers**. Lo mismo pasa con redis-py y con go-redis: la
conexión se abre con la primera orden.

---

**07 → 5.** Distingue lo que hacen redis-py y node-redis cuando el servidor de Redis no está. 🟡

⏱️ **30 segundos** — redis-py falla enseguida: 6 ms con conexión rechazada. node-redis reintenta
para siempre con esperas crecientes, y su `connect()` no termina.

🗣️ **2 minutos** — Corrido: node-redis emitió nueve eventos `error` en 8 s, con esperas crecientes
hasta unos 2 s, y el programa tuvo que cortarlo con un vigilante propio. Con `reconnectStrategy:
false`, falla a los 39 ms.

🔬 **El detalle** — **Biblioteca.** La documentación de node-redis da la estrategia por defecto:
reintentos con espera exponencial hasta 2 000 ms más un poco de azar.

---

**07 → 6.** ¿Por qué los drivers de MongoDB tienen los mismos valores por defecto en todos los
lenguajes y los de Redis no? ¿Lo fija el estándar o es cosa del motor? 🟡

⏱️ **30 segundos** — Porque los drivers oficiales de MongoDB siguen una especificación común que
publica la propia MongoDB. Los clientes de Redis son proyectos independientes, cada uno con sus
decisiones.

🗣️ **2 minutos** — Por eso los cuatro drivers de MongoDB tardaron 30 s, y los de Redis fueron de 6
ms a nunca. Conocer un driver de MongoDB sirve para los demás; conocer un cliente de Redis, no.

🔬 **El detalle** — **Motor y biblioteca.** Redis mantiene hoy algunos clientes oficiales, pero sin
una especificación de comportamiento común.

---

**07 → 7.** ¿Por qué node-redis no necesita *pool*, y qué guarda en memoria mientras está
desconectado? 🟡

⏱️ **30 segundos** — Porque usa una sola conexión y pone las órdenes en fila por ella, y Node no se
bloquea esperando. Desconectado, guarda las órdenes en una cola para mandarlas al reconectar.

🗣️ **2 minutos** — La cola está activa por defecto —`disableOfflineQueue` vale `false`—: durante una
caída larga crece con cada orden y cada petición espera su respuesta. Desactivarla convierte la
caída en errores inmediatos.

🔬 **El detalle** — **Biblioteca.** Una sola conexión también significa que una orden lenta retrasa a
todas las que vienen detrás.

---

**07 → 8.** ¿Hay inyección en MongoDB? Explica cómo se produce y cómo se evita. ¿Lo fija el estándar
o es cosa del motor? 🟡

⏱️ **30 segundos** — Sí: la inyección de operadores. Si el filtro se construye con lo que manda el
usuario, un `{"$ne": null}` donde se esperaba una cadena convierte «igual a esto» en «distinto de
nulo», y devuelve todo.

🗣️ **2 minutos** — Se evita igual que en SQL: el valor del usuario se trata como valor, comprobando
que es del tipo esperado antes de meterlo en el filtro, y nunca se construye la consulta a partir de
un objeto recibido tal cual.

🔬 **El detalle** — **Motor.** No hay texto que analizar, pero hay estructura que el usuario puede
cambiar: la idea de fondo de `02` es la misma.

---

**07 → 9.** Un servicio usa Redis como caché y se cuelga cuando Redis se reinicia. Explica el
mecanismo en Node y la corrección. 🟠

⏱️ **30 segundos** — node-redis reintenta para siempre y guarda las órdenes en su cola: cada
petición espera una respuesta de caché que no llega. Se corrige limitando los reintentos y
desactivando la cola, y tratando el error de caché como «sin caché».

🗣️ **2 minutos** — Con `reconnectStrategy` limitado o en `false`, y `disableOfflineQueue: true`, la
orden falla enseguida y el código puede ir a la base. El reintento de conexión puede seguir en
segundo plano, sin petición esperando.

🔬 **El detalle** — **Biblioteca.** Es la diferencia entre una caché que acelera y una que se
convierte en una dependencia dura.

---

**07 → 10.** Diferencia el tiempo de espera de conexión del de lectura, y di cuál protege de un
servidor que acepta y no contesta. 🟠

⏱️ **30 segundos** — El de conexión limita cuánto se espera para establecerla; el de lectura, cuánto
se espera una respuesta. Del servidor que acepta y no contesta protege el de lectura.

🗣️ **2 minutos** — Una conexión rechazada falla rápido con o sin límite: es el caso fácil de §4. El
difícil es el servidor colgado, que acepta y no responde. Jedis trae 2 s y go-redis 5 s de lectura;
redis-py y node-redis, ninguno.

🔬 **El detalle** — **Biblioteca**, leído del propio cliente en tres de los cuatro. En redis-py se
fija con `socket_timeout`.

---

**07 → 11.** ¿Por qué 30 s de selección de servidor en MongoDB pueden agotar el *pool* de SQL de un
servicio que usa los dos? 🟠

⏱️ **30 segundos** — Porque si la petición toma la conexión de SQL antes de llamar a MongoDB, la
retiene los 30 s de espera. Con suficientes peticiones, el *pool* de SQL se queda sin conexiones
aunque la base SQL esté bien.

🗣️ **2 minutos** — Es el cálculo de Little de `01` §4: el tiempo de retención pasa de milisegundos a
30 s, y la ocupación del *pool* se multiplica. El fallo de un motor se contagia al otro.

🔬 **El detalle** — Dos correcciones: bajar `serverSelectionTimeoutMS`, y no retener la conexión de
SQL mientras se espera a otro sistema, que es la regla de las llamadas externas fuera de la
transacción.

---

**07 → 12.** ¿Qué cuesta guardar el dinero como `Decimal128` en MongoDB, y qué cuesta guardarlo como
cadena? 🟠

⏱️ **30 segundos** — `Decimal128` es exacto y permite sumar en el motor, a cambio de un tipo propio
en cada driver. Como cadena, el driver no lo convierte, pero el motor no puede sumarlo ni compararlo
como número.

🗣️ **2 minutos** — Con cadena, `"10.00" < "9.00"` es verdadero, porque compara texto, y un `$sum` no
funciona. Con `Decimal128`, las agregaciones son exactas y el problema pasa al lenguaje, que es el
de `03` §4.

🔬 **El detalle** — **Motor y driver.** Lo que no se hace nunca es guardarlo como número de coma
flotante, que es lo que un JSON analizado tal cual produciría.

---

**07 → 13.** El *pool* de go-redis es de 80 conexiones en tu portátil y de 320 en producción. ¿Por
qué, y qué comprobarías en el servidor de Redis? 🟠

⏱️ **30 segundos** — Porque por defecto es 10 por núcleo, y producción tiene 32. Comprobaría que el
servidor de Redis admite todas las conexiones de todas las instancias: `maxclients` y el número de
clientes conectados.

🗣️ **2 minutos** — Es el mismo problema que el techo de `max_connections` de `01` §3: un tamaño que
sale de la máquina, multiplicado por las instancias, contra un límite del servidor. Con muchas
instancias, lo sensato es fijar el tamaño a mano.

🔬 **El detalle** — **Biblioteca**, leído del cliente: `PoolSize 80` en 8 núcleos. En Redis, `INFO
clients` da los conectados.

---

**07 → 14.** Diseña la configuración de los clientes de Redis y MongoDB de un servicio en el
lenguaje que prefieras, para que una caída de cualquiera de los dos se note en milisegundos. 🔴

⏱️ **30 segundos** — En Redis, tiempo de conexión y de lectura de unos cientos de milisegundos y sin
cola de órdenes desconectadas. En MongoDB, `serverSelectionTimeoutMS` de uno o dos segundos. Y el
código, preparado para seguir sin caché.

🗣️ **2 minutos** — En Python, corrido con Redis caído:

```python
cache = redis.Redis.from_url(URL_REDIS, socket_connect_timeout=0.2, socket_timeout=0.2,   # 200 ms, no para siempre
                             decode_responses=True)
```

y en MongoDB, corrido en TypeScript,
`mongodb://root:root@mongo:27090/?serverSelectionTimeoutMS=2000`, que falló a los 2 014 ms.

🔬 **El detalle** — El número depende de lo que tarde el servidor sano: un tiempo de lectura más
corto que la orden más lenta legítima convierte las órdenes lentas en errores. Se mide antes de
fijarlo.

---

**07 → 15.** Diagnostica: cada vez que la red hacia MongoDB falla un minuto, el servicio tarda diez
en recuperarse del todo. Da tres hipótesis y qué mirarías para cada una. 🔴

⏱️ **30 segundos** — Primera, peticiones acumuladas durante las esperas de 30 s que tardan en
vaciarse. Segunda, el *pool* de SQL agotado por peticiones que retenían conexiones mientras
esperaban a MongoDB. Tercera, reintentos del propio código que multiplican la carga al volver.

🗣️ **2 minutos** — Para la primera, la cola de peticiones y la latencia del servicio minuto a
minuto. Para la segunda, el log del *pool* de SQL —`active`, `waiting`— durante la caída. Para la
tercera, el número de operaciones por segundo contra MongoDB justo después de volver la red.

🔬 **El detalle** — La corrección común es fallar rápido —`serverSelectionTimeoutMS` bajo— y no
retener recursos mientras se espera a otro sistema: el minuto de caída pasa a ser un minuto de
errores, no diez de recuperación.

---

**07 → 16.** Escribe, en el lenguaje que prefieras, la lectura de un pedido con Redis como caché de
modo que una caída de Redis no afecte a la respuesta, solo a su tiempo. 🔴

⏱️ **30 segundos** — Leer de Redis con un tiempo corto; si falla o no está, leer de la base y
guardar en Redis ignorando el error; y devolver lo de la base.

🗣️ **2 minutos** — Corrido en Python:

```python
def leer_pedido(con, codigo):
    try:
        guardado = cache.get(f"pedido:{codigo}")
        if guardado:
            return json.loads(guardado), "caché"
    except redis.RedisError:
        pass                                          # sin caché: se sigue, más lento, pero se sigue
    fila = con.execute("SELECT codigo, estado, total::text FROM pedidos WHERE codigo = %s", (codigo,)).fetchone()
    pedido = {"codigo": fila[0], "estado": fila[1], "total": fila[2]}
    try:
        cache.set(f"pedido:{codigo}", json.dumps(pedido), ex=60)
    except redis.RedisError:
        pass
    return pedido, "base"
```

```text
-- con Redis
base  7 ms {'codigo': 'PED-00042', 'estado': 'PAGADO', 'total': '3186.23'}
caché 0 ms {'codigo': 'PED-00042', 'estado': 'PAGADO', 'total': '3186.23'}
-- con Redis caído
base  2 ms {'codigo': 'PED-00042', 'estado': 'PAGADO', 'total': '3186.23'}
base  0 ms {'codigo': 'PED-00042', 'estado': 'PAGADO', 'total': '3186.23'}
```

🔬 **El detalle** — Es el patrón *cache-aside*, que es del bloque 07 con sus problemas de
invalidación y estampida. Lo propio de este capítulo es la parte del cliente: el tiempo corto y el
error tratado como «sin caché».

---

## Simulación de entrevista

Las 26 preguntas `S#` y los cuatro escenarios de [`08`](08-simulacion-de-entrevista.md). Los
escenarios no se responden de memoria: se defienden en voz alta, y la capa 🔬 es la que dice qué se
está evaluando de verdad.

**08 → S1.** Explica por qué abrir una conexión por petición es caro, con el número medido en el
corpus y en qué se va ese tiempo. 🟡

⏱️ **30 segundos** — Porque cada conexión de PostgreSQL es un proceso nuevo del servidor, con su
conexión TCP, su intento de TLS y su autenticación. Medido en Go: 5,2 ms por consulta abriendo
conexión contra 0,13 ms reutilizándola, unas 40 veces más.

🗣️ **2 minutos** — La consulta cuesta lo mismo en los dos casos; lo que cambia es montar y
desmontar. La autenticación `scram-sha-256` del entorno está hecha para ser costosa, y pgx además
prueba TLS primero y repite en claro cuando el servidor lo rechaza.

🔬 **El detalle** — **Motor** el proceso por conexión, **driver** el intento de TLS. Con la base en
otra máquina y TLS de verdad, cada viaje de red se suma, y la proporción crece.

---

**08 → S2.** Diez instancias de un servicio con un *pool* de 10 cada una, contra un PostgreSQL con
los valores de fábrica. ¿Qué pasa y qué harías? 🟠

⏱️ **30 segundos** — Son 100 conexiones contra 97 disponibles —100 de `max_connections` menos 3
reservadas—: las últimas fallan con `SQLSTATE 53300`. Bajaría el *pool* de cada instancia, contando
también migraciones y administradores.

🗣️ **2 minutos** — El tamaño se calcula por la ley de Little —peticiones por segundo por tiempo de
retención— y se reparte contra el techo común. Si hace falta más de lo que cabe, lo siguiente es un
intermediario de conexiones delante de la base, no subir `max_connections`.

🔬 **El detalle** — **Motor** el techo, medido: la conexión 98 de `tienda_app` falló con `remaining
connection slots are reserved for roles with the SUPERUSER attribute`.

---

**08 → S3.** Un *pool* de dos conexiones recibe tres peticiones que tardan 2 s. Di qué pasa con la
tercera en HikariCP, psycopg-pool, `pg.Pool` y `pgxpool`, con sus valores por defecto. 🟡

⏱️ **30 segundos** — HikariCP y psycopg-pool la hacen esperar hasta 30 s: como las otras terminan a
los 2 s, la tercera acaba entrando. `pg.Pool` espera para siempre. `pgxpool` espera lo que diga el
`context`.

🗣️ **2 minutos** — Con la espera bajada a 1 s, corrido: HikariCP falla con `Connection is not
available … (total=2, active=2, idle=0, waiting=0)`, psycopg-pool con `PoolTimeout`, `pg.Pool` con
`timeout exceeded when trying to connect` y `pgxpool` con `context deadline exceeded`.

🔬 **El detalle** — **Biblioteca.** Sin tocar nada, `pg.Pool` hizo terminar a la tercera a los 4 034
ms, esperando su turno. Con una consulta que nunca termina, esperaría indefinidamente.

---

**08 → S4.** En Go, el mismo `context` de 1 s cubre la espera del *pool* y una consulta de 2 s. Di
qué ve el cliente y qué registra el servidor. 🟠

⏱️ **30 segundos** — El cliente recibe `timeout: context deadline exceeded` al segundo. El servidor
registra `canceling statement due to user request`: pgx canceló la consulta en él.

🗣️ **2 minutos** — Corrido con un *pool* de dos y tres tareas: fallaron las tres al segundo. Dos por
cancelación de la consulta en curso y la tercera esperando turno, sin el prefijo `timeout:`. Con un
`context` para `Acquire` y otro para la consulta, solo falla la que espera.

🔬 **El detalle** — **Driver.** Que el `context` cancele en el servidor es una ventaja: la base no
sigue trabajando para una petición que ya nadie espera.

---

**08 → S5.** Un compañero dice que un parámetro «escapa las comillas mejor que tú». Corrígelo y
explica qué hace de verdad. 🟡

⏱️ **30 segundos** — No escapa nada: separa. El texto SQL va con `$1` en un mensaje y el valor en
otro, y el valor nunca pasa por el analizador de SQL.

🗣️ **2 minutos** — Visto en el log del servidor en los cuatro drivers: `execute <unnamed>: SELECT …
WHERE codigo = $1` y `Parameters: $1 = '…'`. Las comillas dobladas del log son solo cómo el servidor
imprime el valor.

🔬 **El detalle** — **Motor** el protocolo extendido, con *Parse* y *Bind*. Por eso el parámetro no
depende de acertar con todas las formas de escribir una comilla.

---

**08 → S6.** Nombra cuatro cosas que un parámetro no protege, con la forma correcta de cada una en
PostgreSQL. 🟢

⏱️ **30 segundos** — Los nombres de columna, que van de una lista blanca y citados; los comodines de
`LIKE`, que se escapan; las listas de `IN`, que se pasan como *array* con `= ANY`; y los nombres de
tabla, que tampoco admiten parámetro.

🗣️ **2 minutos** — Corridos: `ORDER BY %s` ordena por una constante sin error; `LIKE` con `%`
devuelve el millón de filas; `IN (%s)` con una lista separada por comas devuelve 0; y `FROM %s` da
error de sintaxis.

🔬 **El detalle** — Cada driver trae su herramienta para citar identificadores: `enquoteIdentifier`,
`sql.Identifier`, `escapeIdentifier` y `pgx.Identifier`. Java rechaza un nombre con comillas en vez
de escaparlo.

---

**08 → S7.** Una búsqueda concatenada recibe `x'; DROP TABLE pagos; --` y `pagos` sigue ahí. Explica
por qué se ejecutó el `DROP` y qué lo paró. 🟠

⏱️ **30 segundos** — Se ejecutó porque una consulta sin parámetros va por el protocolo simple, que
admite varias sentencias. Lo paró que el rol de la aplicación no es dueño de la tabla: `must be
owner of table pagos`.

🗣️ **2 minutos** — Con un parámetro, el protocolo extendido solo admite una sentencia: corrido,
`cannot insert multiple commands into a prepared statement`. Las dos defensas son distintas: el
parámetro impide que el dato sea código, y el mínimo privilegio limita lo que el código puede hacer.

🔬 **El detalle** — **Motor** los dos protocolos y el catálogo de permisos. Con una inyección de
lectura, el rol sigue leyendo todo lo que puede leer.

---

**08 → S8.** El log de tu ORM enseña la consulta con los valores dentro del texto. ¿Hay inyección?
¿Cómo lo compruebas? 🟡

⏱️ **30 segundos** — No necesariamente: el de GORM sustituye los valores solo para que se lea. Se
comprueba en el log del servidor, que recibió `$1` y `$2`.

🗣️ **2 minutos** — Corrido con `log_statement` para el rol de la aplicación: GORM registraba `WHERE
codigo = 'PED-00042'` y el servidor, `WHERE codigo = $1` con `Parameters: $1 = 'PED-00042'`.

🔬 **El detalle** — Si el servidor también recibe el valor pegado, hay que distinguir interpolación
del driver —el valor queda entero dentro de un literal— de concatenación del código, que es la
inyección.

---

**08 → S9.** ¿Cómo llega una columna `numeric` a Java, a Python, a TypeScript y a Go, y en cuál de
los cuatro es una trampa? 🟡

⏱️ **30 segundos** — `BigDecimal`, `Decimal`, **cadena** y `pgtype.Numeric`. La trampa es
TypeScript: `total + 10` concatena.

🗣️ **2 minutos** — `pg` entrega cadena porque el único número de JavaScript es flotante. Go no
elige: entrega el entero y el exponente, y la conversión es tuya.

🔬 **El detalle** — **Driver.** Los números dentro de un `jsonb` llegan como flotante en Python,
TypeScript y Go, que es la misma trampa por otra puerta.

---

**08 → S10.** El informe de «pedidos de ayer» da cifras distintas desde un servicio Java y desde uno
Python. Da el mecanismo exacto y la corrección. 🟠

⏱️ **30 segundos** — pgjdbc fija la zona de la sesión con la de la JVM al conectar, y psycopg deja
la del servidor. La conversión a fecha la hace el motor en la zona de la sesión, así que el mismo
pedido cae en días distintos. Se corrige fijando la zona en la consulta.

🗣️ **2 minutos** — Corrido: `SHOW timezone` da `America/Bogota` desde Java con la JVM en Bogotá y
`Etc/UTC` desde psycopg. La corrección: `(creado_en AT TIME ZONE 'America/Bogota')::date`.

🔬 **El detalle** — **Motor** la conversión, **driver** la zona. Un síntoma que empieza siempre a la
misma hora local apunta a una zona horaria.

---

**08 → S11.** En Node, un pedido creado a las 03:08 aparece a las 08:08. Da la causa y el arreglo. 🟠

⏱️ **30 segundos** — La columna es `timestamp` sin zona, y `pg` la interpreta como hora local del
proceso, en Bogotá, cinco horas por detrás de UTC. Se arregla con `timestamptz` o diciéndole a `pg`
que no interprete el OID 1114.

🗣️ **2 minutos** — Con `pg.types.setTypeParser(1114, (texto) => texto)`, corrido, la hora llegó
intacta. No se ve con el proceso en UTC, y por eso aparece en producción y no en las pruebas.

🔬 **El detalle** — **Driver.** El `Date` de JavaScript pierde además los microsegundos de un
`timestamptz`.

---

**08 → S12.** Una columna nula, leída en Java con `getLong` y en Go con `Scan` a un `int64`. ¿Qué
pasa en cada uno, y cuál prefieres? 🟡

⏱️ **30 segundos** — Java devuelve 0 y solo `wasNull()` lo delata. Go devuelve un error. Prefiero
Go: el nulo imprevisto aparece como error y no como dato falso.

🗣️ **2 minutos** — Corrido: `getLong(nulo) 0 wasNull=true` y `cannot scan NULL into *int64`. Las
formas seguras: `getObject(…, Long.class)` en Java y un puntero en Go.

🔬 **El detalle** — **Lenguaje.** Un saldo nulo leído con `getLong` es un saldo cero.

---

**08 → S13.** ¿Qué driver del corpus abre una transacción sin que se lo pidas, y qué problema
produce eso en un servicio? 🟢

⏱️ **30 segundos** — psycopg, porque la DB-API lo pide. En un servicio produce conexiones `idle in
transaction` cuando el código no confirma ni deshace, que retienen el horizonte de limpieza.

🗣️ **2 minutos** — Basta un `SELECT` para abrirla. Se evita con `autocommit=True` para lecturas,
bloques `with con.transaction()` para escrituras, y el `with pool.connection()` del *pool*.

🔬 **El detalle** — **Driver.** SQLAlchemy lo hereda y lo registra como `BEGIN (implicit)`.

---

**08 → S14.** Un servicio captura el error del segundo paso de una transacción y confirma. ¿Qué
queda en la base, y cuál de los cuatro drivers te lo dice? 🟠

⏱️ **30 segundos** — Nada: la transacción quedó abortada y el `COMMIT` se convirtió en `ROLLBACK`.
Solo pgx lo trata como error; `pg` lo dice en la etiqueta del resultado; pgjdbc y psycopg, nada.

🗣️ **2 minutos** — Corrido en los cuatro: el paso 1 no se guardó en ninguno, y en Java y Python el
`commit()` volvió limpio. La corrección es no capturar dentro de la transacción, o usar un punto de
guardado si de verdad hay que seguir.

🔬 **El detalle** — **Motor** el aborto; **driver** el aviso. pgx devuelve `commit unexpectedly
resulted in rollback`.

---

**08 → S15.** La exportación nocturna muere por memoria. Explica qué hace cada driver por defecto
con un resultado grande, y la trampa específica de pgjdbc. 🟠

⏱️ **30 segundos** — pgjdbc, psycopg y `pg` traen el resultado entero a memoria antes de dar la
primera fila; pgx lee según avanza. La trampa de pgjdbc: con autocommit, ignora `setFetchSize` en
silencio.

🗣️ **2 minutos** — Medido con el millón de pedidos, sobre la base de cada proceso: 147 MB más en
Java, 56 en Python, 274 en TypeScript y 105 en Go acumulando. Por tramos, entre 0 y 22 MB más.
pgjdbc con autocommit y `fetchSize`: 405 MB.

🔬 **El detalle** — **Driver.** El cursor del servidor muere con la transacción; por eso pgjdbc
necesita `setAutoCommit(false)`, y lo dice su documentación.

---

**08 → S16.** ¿Cuál es la forma más barata de exportar un millón de pedidos a CSV, y qué retiene en
la base mientras dura? 🟡

⏱️ **30 segundos** — `COPY (SELECT …) TO STDOUT WITH (FORMAT csv)`: el servidor genera el CSV y el
cliente lo copia. Retiene la instantánea de una sola sentencia mientras se ejecuta.

🗣️ **2 minutos** — Medido en Python: 57 376 295 bytes en 1 039 ms, con la memoria del proceso en su
base. Con un cursor por tramos, la transacción queda abierta mientras dure el recorrido.

🔬 **El detalle** — **Motor** el `COPY`, que no es del estándar.

---

**08 → S17.** Ordena las capas de acceso a datos de Java de menos a más abstracción y di quién
escribe el SQL en cada una. 🟢

⏱️ **30 segundos** — JDBC y `JdbcClient`: tú. MyBatis: tú, fuera del código. jOOQ: la biblioteca,
desde código Java. JPA con Hibernate: Hibernate, desde tus entidades.

🗣️ **2 minutos** — Cuanto más arriba, menos SQL escribes y más SQL se escribe sin que lo veas. En
Hibernate, un pedido con sus líneas fueron dos consultas, la segunda al recorrer las líneas.

🔬 **El detalle** — La elección es dónde quieres ver el SQL. Muchos proyectos combinan JPA para el
alta y jOOQ o `JdbcClient` para los informes.

---

**08 → S18.** Explica `REQUIRES_NEW` en Spring: qué conexión usa, qué pasa con sus escrituras si la
externa falla, y por qué puede agotar el *pool*. 🟠

⏱️ **30 segundos** — Usa otra conexión y otra transacción; sus escrituras sobreviven al fallo de la
externa. Agota el *pool* porque cada petición retiene dos conexiones a la vez.

🗣️ **2 minutos** — Corrido con `TransactionTemplate`: `pid` distinto dentro y fuera, y la escritura
interna se quedó tras el *rollback* externo. Con un *pool* de uno: `Could not open JDBC Connection
for transaction`.

🔬 **El detalle** — **Spring.** Por autoinvocación, un `REQUIRES_NEW` en un método del mismo objeto
se ignora en silencio.

---

**08 → S19.** Distingue sqlc de GORM: qué escribe el programador, qué genera la herramienta y cuándo
elegirías cada uno. 🟡

⏱️ **30 segundos** — Con sqlc escribes el SQL y la herramienta genera el Go tipado. Con GORM
escribes estructuras y GORM genera el SQL al ejecutar. sqlc cuando el SQL es el protagonista; GORM
cuando lo son las estructuras.

🗣️ **2 minutos** — sqlc falla al generar si la consulta nombra una columna que no existe. GORM añade
cosas que nadie escribió, como el `ORDER BY id LIMIT 1` de `First`, y un `SELECT *`.

🔬 **El detalle** — GORM no tiene carga perezosa: el N+1 aparece por bucles del propio código, y se
corrige con `Preload`.

---

**08 → S20.** ¿Por qué no elegirías hoy Apache Derby para un proyecto nuevo? 🟢

⏱️ **30 segundos** — Porque está retirado: el 10 de octubre de 2025 sus desarrolladores lo dejaron
en solo lectura, sin más versiones ni correcciones.

🗣️ **2 minutos** — La 10.17.1.0, de noviembre de 2023, es la última. Además, su dialecto se separa
de los demás: rechazó `LIMIT` con un error de sintaxis y solo acepta `FETCH FIRST`.

🔬 **El detalle** — Si hace falta un embebido en Java, H2 sigue vivo; si hace falta en cualquier
lenguaje, SQLite. Para pruebas, ninguno: se prueba contra el motor de producción.

---

**08 → S21.** El servidor de Redis desaparece. Di qué hacen redis-py, Jedis, node-redis y go-redis
con su configuración por defecto. 🟠

⏱️ **30 segundos** — redis-py falla en 6 ms; Jedis, en 184; go-redis reintenta cinco veces y falla
en 1,7 s; y node-redis reintenta para siempre, y su `connect()` no termina.

🗣️ **2 minutos** — Corridos todos contra un puerto sin servidor. node-redis además guarda las
órdenes en una cola mientras está desconectado. Con `reconnectStrategy: false`, falla a los 39 ms.

🔬 **El detalle** — **Biblioteca.** Es el caso fácil, conexión rechazada; el difícil es el servidor
que acepta y no responde, donde solo Jedis y go-redis traen tiempo de lectura por defecto.

---

**08 → S22.** ¿Por qué la espera por defecto de los drivers de MongoDB puede tumbar el acceso a
PostgreSQL de un servicio que usa los dos? 🟠

⏱️ **30 segundos** — Porque la petición espera 30 s a MongoDB, y si tiene una conexión de PostgreSQL
prestada durante ese tiempo, el *pool* de PostgreSQL se vacía aunque la base esté bien.

🗣️ **2 minutos** — Los 30 s son `serverSelectionTimeoutMS`, medidos en los cuatro drivers. Con la
ley de Little, el tiempo de retención pasa de milisegundos a treinta segundos, y la ocupación del
*pool* crece en varios órdenes de magnitud.

🔬 **El detalle** — Correcciones: bajar el tiempo de MongoDB, y no retener recursos de un sistema
mientras se espera a otro.

---

**08 → S23.** «Con un ORM no hay inyección SQL». Refútalo con un ejemplo concreto del bloque. 🟠

⏱️ **30 segundos** — `db.Order(ordenDelUsuario)` en GORM pega el texto tal cual; su documentación de
seguridad lo lista entre los métodos que no escapan. Lo mismo `${}` en MyBatis.

🗣️ **2 minutos** — Los ORM parametrizan los valores y aceptan fragmentos de SQL como texto. Donde
hay texto del usuario, hay inyección.

🔬 **El detalle** — La corrección es la de siempre: lista blanca para nombres, parámetro para
valores.

---

**08 → S24.** «Si el `commit()` no dio error, está guardado». ¿Cuándo es falso, y en qué drivers? 🟠

⏱️ **30 segundos** — Cuando una sentencia de la transacción falló y el código capturó la excepción:
el servidor convierte el `COMMIT` en `ROLLBACK`. pgjdbc y psycopg no dan error; `pg` devuelve la
etiqueta `ROLLBACK`; pgx da error.

🗣️ **2 minutos** — Hay otros casos del bloque 04: `synchronous_commit = off` con caída del proceso,
y un disco que miente sobre su `fsync`. Este es el más frecuente porque lo provoca el propio código.

🔬 **El detalle** — **Motor** el aborto de la transacción, que en MySQL no existe igual: allí solo se
deshace la sentencia fallida.

---

**08 → S25.** ¿Hay algo de este bloque en el estándar SQL? Responde en una frase y di qué se sigue
para una entrevista. 🟡

⏱️ **30 segundos** — Casi nada: los drivers, los *pools*, los tipos del lenguaje y los ORM son de
cada ecosistema; el estándar pone el marcador `?` y los tipos de columna.

🗣️ **2 minutos** — Lo que se sigue: cada respuesta de este bloque tiene que decir de qué lenguaje y
de qué biblioteca habla. Una respuesta sin eso está recordada, no explicada.

🔬 **El detalle** — ISO/IEC 9075 es de pago y no he verificado sus cláusulas; la parte 3, SQL/CLI,
existe y ninguno de los drivers del corpus la usa.

---

**08 → S26.** «Un *pool* más grande aguanta más carga». Refútalo con dos argumentos del bloque. 🟡

⏱️ **30 segundos** — Uno: el servidor no ejecuta más consultas a la vez que núcleos tiene, así que
las conexiones de más solo esperan dentro de él. Dos: el techo de conexiones es común a todas las
instancias, y el *pool* grande de una deja sin sitio a otra.

🗣️ **2 minutos** — Y un tercero del escenario 4: si el cuello es una espera externa, un *pool* más
grande solo aloja más peticiones esperando.

🔬 **El detalle** — **Convención** falsa. El tamaño se calcula con lo que retiene cada petición.

---

**08 → E1.** Escenario 1 — El servicio en Node que se cuelga en la campaña

⏱️ **30 segundos** — La hipótesis más probable es un `pg.Pool` agotado sin
`connectionTimeoutMillis`, que espera para siempre. Alternativas: una fuga de conexiones sin
`release()`, o transacciones que se quedan abiertas. Subir el *pool* a 50 retrasa el cuelgue, no lo
quita.

🗣️ **2 minutos** — En `pg_stat_activity`: si las conexiones del servicio están `active`, hay
consultas lentas; si están `idle`, fugas; si están `idle in transaction`, transacciones sin cerrar.
En el *pool*, `totalCount`, `idleCount` y `waitingCount`. La configuración: `max` calculado por la
ley de Little y repartido contra `max_connections`; `connectionTimeoutMillis` de uno o dos segundos;
`statement_timeout` en el servidor; y transacciones con `connect` y `release` en `finally`.

🔬 **El detalle** — Lo que se evalúa es no aceptar el marco: con la base al 20 % de CPU, el cuello no
es la base. El valor por defecto de `pg.Pool` es la pista, y reiniciar funciona porque vacía el
*pool* de conexiones perdidas.

---

**08 → E2.** Escenario 2 — La conciliación que no cuadra

⏱️ **30 segundos** — Dinero: el servicio Node suma cadenas o las convierte a flotante. Fechas: el
servicio Node lee `timestamp` sin zona como hora local. Zona de la sesión: el servicio Java
convierte a fecha en la zona de la JVM, y el de Python en UTC.

🗣️ **2 minutos** — La regla común: dinero con decimal exacto o sumado en SQL; `timestamptz` siempre;
los días calculados en la consulta con `AT TIME ZONE` explícito; y en Node, los tipos del driver
fijados con `setTypeParser`. La comprobación: la misma consulta de conciliación desde los tres
servicios con el proceso en tres zonas distintas —como `TZ=America/Bogota` en el bloque— y los
resultados comparados con `psql`.

🔬 **El detalle** — Lo que se evalúa es separar las tres causas y asignar cada una a su capa: la base
está bien, y lo que falla es la lectura. Todas están corridas en `03`.

---

**08 → E3.** Escenario 3 — El proyecto Java de diez años

⏱️ **30 segundos** — JPA para las entidades que se editan de una en una, `JdbcClient` para informes
y consultas simples, y retirar MyBatis si se puede sin romper nada. H2, fuera de las pruebas en
cuanto haya pruebas contra PostgreSQL. Derby, migrado: está retirado.

🗣️ **2 minutos** — Riesgos de lo que se queda: el N+1 de JPA, que hay que vigilar en el log; y el
`${}` de MyBatis, si sobrevive, que hay que auditar. Orden: primero las pruebas contra el motor
real, para tener red; después la auditoría de `${}` y de propagaciones; después la consolidación de
capas. Derby es un caso distinto de H2: es una herramienta en producción que depende de un proyecto
retirado; H2 es solo una herramienta de pruebas.

🔬 **El detalle** — Se evalúa el orden: no se toca la capa de datos sin pruebas que la cubran, y las
pruebas contra H2 no cubren PostgreSQL. El caso reproducido de por qué, es del bloque 11.

---

**08 → E4.** Escenario 4 — Treinta segundos cuando cae MongoDB

⏱️ **30 segundos** — Esto no lo resuelve la base de datos. Los 30 s son el
`serverSelectionTimeoutMS` por defecto del driver de MongoDB, y se contagian a PostgreSQL porque las
peticiones retienen su conexión de PostgreSQL mientras esperan. Ni el *pool* ni los índices tocan
eso.

🗣️ **2 minutos** — El diseño: el cliente de MongoDB con un tiempo de selección de uno o dos segundos
y de lectura acotado; la lectura del histórico **fuera** del préstamo de la conexión de PostgreSQL;
y el panel que, si MongoDB falla, pinta los pedidos sin histórico y lo dice. Más pool solo aloja más
peticiones esperando, y un índice no acelera una espera de red.

🔬 **El detalle** — Qué es de cada capa: el tiempo de espera es configuración del **cliente**; no
retener conexiones y degradar el panel son decisiones de la **aplicación**; lo único de la base de
datos es que PostgreSQL siguió sano todo el rato. Lo que se evalúa es decirlo antes de proponer
nada.

---

**Volver:** [README del bloque](README.md) · **Primer capítulo:**
[`01`](01-el-driver-la-conexion-y-el-pool.md).
