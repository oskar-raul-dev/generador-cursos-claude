# 07 — Respuestas

> Solucionario del bloque: el enunciado copiado literalmente de su lab y la respuesta en tres capas.
> Los ejercicios 🧪 no tienen respuesta aquí: se resuelven corriéndolos.
>
> **Cómo se usa.** Responde primero en voz alta, con el cronómetro. La capa ⏱️ es lo que dices en
> los primeros treinta segundos; la 🗣️ es lo que añades cuando te dicen "cuéntame más"; la 🔬 es el
> matiz que casi nadie trae, y es donde vive la distinción entre **lo que manda el estándar, lo que
> hace el motor y lo que es pura convención**.
>
> **Vigencia:** 24 de septiembre de 2026.

---

## Salto rápido

- [Lab l00 — El entorno y los datos](#lab-l00--el-entorno-y-los-datos)
- [Lab l01 — `EXPLAIN` e índices medidos](#lab-l01--explain-e-índices-medidos)
- [Lab l02 — Aislamiento y bloqueos en vivo](#lab-l02--aislamiento-y-bloqueos-en-vivo)
- [Lab l03 — Respaldo y restauración](#lab-l03--respaldo-y-restauración)
- [Lab l04 — Redis y MongoDB](#lab-l04--redis-y-mongodb)
- [Lab l05 — Los otros modelos](#lab-l05--los-otros-modelos)
- [Simulación de entrevista](#simulación-de-entrevista)

---

## Lab l00 — El entorno y los datos

Las 15 preguntas de [`l00`](l00-el-entorno-y-los-datos.md).

**00 → 1.** ¿Qué hace `docker compose up -d`, y qué significa `(healthy)` en `docker compose ps`? 🟢

⏱️ **30 segundos** — Crea lo que falte —red, volúmenes y contenedores— y arranca los servicios en
segundo plano. `(healthy)` significa que el `healthcheck` del servicio pasó: el motor acepta
conexiones.

🗣️ **2 minutos** — Mientras dice `health: starting`, conectarse da errores que parecen de
credenciales. En el lab, los cinco servicios tardaron unos diez segundos en llegar a `(healthy)`.

🔬 **El detalle** — **Docker Compose**, no el motor. Cada servicio lleva su propia prueba:
`pg_isready`, `mysqladmin ping`, `redis-cli ping`, un `ping` de `mongosh`.

---

**00 → 2.** ¿Por qué el corpus fija la versión de cada imagen y nunca usa `latest`? 🟢

⏱️ **30 segundos** — Porque una imagen móvil cambia el motor el día que se publica la siguiente
versión, y con él los planes pegados en el corpus.

🗣️ **2 minutos** — `postgres:18.6`, `mysql:9.7.2` y las demás son exactas. Si un plan deja de
coincidir, la versión queda descartada como causa.

🔬 **El detalle** — **Convención** del corpus, con un procedimiento: cambiar una versión obliga a
verificarla en su fuente y a volver a correr los capítulos cuyos planes puedan cambiar.

---

**00 → 3.** ¿Qué hace `setseed(0.42)` en la semilla, y qué pasaría sin él? 🟢

⏱️ **30 segundos** — Fija el generador de números al azar de la sesión antes del primer `random()`.
Sin él, cada carga produciría otros datos y ningún plan del corpus sería reproducible.

🗣️ **2 minutos** — Con él, la carga es determinista: la copia aislada del lab produjo CSV que pesan
byte a byte lo mismo que los del corpus.

🔬 **El detalle** — **Motor**: `setseed` es de PostgreSQL. MySQL y SQLite no tienen equivalente para
toda la sesión, y es una de las razones de que los datos se generen en PostgreSQL.

---

**00 → 4.** ¿Qué diferencia hay entre `stop`, `down` y `down -v`? 🟢

⏱️ **30 segundos** — `stop` para los procesos; `down` borra además contenedores y red; `down -v`
borra también los volúmenes, con todas las bases.

🗣️ **2 minutos** — Tras `stop` o `down`, un `up -d` vuelve con los datos. Tras `down -v` hay que
cargar de nuevo: unos cuatro minutos entre los cuatro motores.

🔬 **El detalle** — **Docker Compose.** `-v` es la única bandera que destruye datos, y no pregunta.

---

**00 → 5.** Distingue `COPY` de `\copy` en PostgreSQL: quién lee o escribe el fichero en cada uno. 🟡

⏱️ **30 segundos** — `COPY … TO` o `FROM` un fichero lo hace el **servidor**, en su máquina. `\copy`
es de `psql`: el **cliente** lee o escribe el fichero en la tuya, y los datos viajan por la
conexión.

🗣️ **2 minutos** — Por eso la exportación del lab usa `\copy`: con el servidor en un contenedor, un
`COPY … TO` escribiría dentro del contenedor.

🔬 **El detalle** — **Motor y cliente.** `COPY` a un fichero del servidor exige superusuario o un rol
de lectura y escritura de ficheros; `\copy` solo necesita permiso sobre la tabla.

---

**00 → 6.** ¿Por qué PostgreSQL responde lo mismo a un rol inexistente que a una contraseña mala? 🟡

⏱️ **30 segundos** — Para no decirle a un atacante qué nombres de rol existen. Los dos casos dan
`password authentication failed`.

🗣️ **2 minutos** — En el lab, conectarse como `tienda_app` antes de `esquema.sql` dio ese mensaje
aunque el rol aún no existía. La causa real queda en el registro del servidor, que ve el
administrador.

🔬 **El detalle** — **Motor.** Es una decisión de seguridad, y engaña al diagnosticar: el primer paso
es comprobar que el rol existe.

---

**00 → 7.** ¿Por qué `LOAD DATA LOCAL INFILE` falla si solo el servidor tiene `local_infile`
activado? 🟡

⏱️ **30 segundos** — Porque `LOCAL` significa que el fichero lo lee el cliente, y el cliente también
tiene que permitirlo, con `--local-infile=1`. Sin él: `ERROR 2068 … file request rejected due to
restrictions on access`.

🗣️ **2 minutos** — El permiso hace falta en los dos lados. Sin `LOCAL`, el fichero lo leería el
servidor, y solo desde el directorio de `secure_file_priv`.

🔬 **El detalle** — **Motor**, MySQL y MariaDB. Es una defensa: un servidor malicioso podría pedirle
al cliente que le mande cualquier fichero.

---

**00 → 8.** ¿Qué parte de la carga es del estándar SQL y qué parte de cada motor? Da dos ejemplos. 🟡

⏱️ **30 segundos** — Casi nada es del estándar. `COPY` es de PostgreSQL, `LOAD DATA` de MySQL y
`.import`, del cliente de SQLite; `generate_series` y `setseed`, de PostgreSQL.

🗣️ **2 minutos** — Del estándar son las piezas: `CREATE TABLE`, las restricciones, `INSERT … SELECT`
o la CTE recursiva con la que MySQL y SQLite podrían generar filas.

🔬 **El detalle** — ISO/IEC 9075 es de pago y no he verificado sus cláusulas; ninguna carga masiva
desde fichero consta en lo que los motores documentan como estándar.

---

**00 → 9.** ¿Por qué el corpus genera los datos en PostgreSQL y los exporta, en vez de sembrar cada
motor por separado? 🟠

⏱️ **30 segundos** — Porque MySQL y SQLite no tienen `generate_series` ni `setseed`, y una semilla
propia en cada motor daría otros clientes, otros importes y otras cardinalidades.

🗣️ **2 minutos** — Exportando, los cuatro motores tienen las mismas filas con los mismos `id`, y la
comparación entre motores compara el motor, no los datos.

🔬 **El detalle** — La **convención** contraria —cada motor, su script— parece más limpia y rompe
todas las comparaciones de `02/08`.

---

**00 → 10.** ¿Por qué `.import` de SQLite rompe el `UNIQUE` de `pagos.referencia`, y cómo lo evita
la semilla? 🟠

⏱️ **30 segundos** — Porque `.import` no entiende de nulos: el `\N` del CSV llega como la cadena
`'\N'`, y el segundo pago en efectivo repite ese valor. La semilla importa en una tabla de paso,
convierte `'\N'` en `NULL` y después copia.

🗣️ **2 minutos** — En el lab falló en la línea 5 del CSV y dejó 4 filas a medias. Por eso se vuelve
a correr `esquema-sqlite.sql` antes de la carga buena.

🔬 **El detalle** — **Herramienta**, el cliente `sqlite3`. `UNIQUE` admite varios `NULL`, pero no dos
cadenas iguales.

---

**00 → 11.** ¿Qué tres conversiones hace la exportación a CSV, y qué rompería cada una si faltara? 🟠

⏱️ **30 segundos** — Las marcas de tiempo a texto UTC, los booleanos a 0/1 y los nulos a `\N`.

🗣️ **2 minutos** — Sin la primera, el `TIMESTAMP` de MySQL no lee el sufijo de zona. Sin la segunda,
`t` y `f` se guardan como 0 y todos los productos quedan inactivos. Sin la tercera, los 273 126
nulos llegan como cadenas vacías y chocan contra el `UNIQUE` de `pagos.referencia`.

🔬 **El detalle** — La verificación de MySQL tiene cuatro comprobaciones propias para esto: 101
inactivos, 273 126 referencias nulas, ninguna vacía y el JSON leído como JSON.

---

**00 → 12.** `up -d` responde `Recreate` en tres contenedores. ¿Qué lo provoca, y se pierden los
datos? 🟠

⏱️ **30 segundos** — Que la configuración de esos servicios en el `compose` cambió desde que se
crearon. No se pierden: los datos viven en volúmenes con nombre, que sobreviven al contenedor.

🗣️ **2 minutos** — En el lab, tras recrear MySQL, MariaDB y Redis, los recuentos seguían en un
millón de pedidos y la verificación de PostgreSQL daba 22 de 22.

🔬 **El detalle** — **Docker Compose.** Lo que sí se pierde al recrear o reiniciar es el estado en
memoria: la caché y los contadores de `pg_stat_*`.

---

**00 → 13.** Después de un `down -v` y una carga nueva, un plan del bloque 03 da otro `rows=`. ¿Es
un error de la carga? 🟠

⏱️ **30 segundos** — No. Los datos son los mismos, pero la muestra de `ANALYZE` es al azar, y
`rows=` sale de ella.

🗣️ **2 minutos** — Lo que tiene que coincidir es la forma del plan —qué nodos y qué índice— y las
filas reales. Si coinciden, la carga está bien.

🔬 **El detalle** — **Motor.** `setseed` fija los datos, no la muestra de las estadísticas.

---

**00 → 14.** Diagnostica: `docker compose up -d` falla con `port is already allocated` en el 5432.
Da la orden que encuentra al culpable y la corrección. 🔴

⏱️ **30 segundos** — `docker ps --format '{{.Names}}\t{{.Ports}}' | grep 5432` dice qué contenedor
tiene el puerto. La corrección es pararlo, no cambiar el puerto del corpus.

🗣️ **2 minutos** — Si no sale ningún contenedor, lo tiene un PostgreSQL instalado en la máquina; se
para con su gestor de servicios. Cambiar el puerto rompe todas las órdenes que copies del corpus.

🔬 **El detalle** — **Docker**: el contenedor se crea y falla al publicar el puerto. Con `--rm`
desaparece solo.

---

**00 → 15.** Diseña la comprobación de que un entorno recién cargado es el del corpus: qué mirarías
en cada motor y en qué orden. 🔴

⏱️ **30 segundos** — Primero `docker compose ps`, con los cinco en `(healthy)`. Después
`verificar.sql` en PostgreSQL, 22 en `OK`; `verificar-mysql.sql` en MySQL y MariaDB, 26; y
`verificar-sqlite.sql`, 17.

🗣️ **2 minutos** — PostgreSQL primero, porque es la fuente: si falla, lo demás no tiene sentido.
Después, el tamaño de `pedidos` —10 770 páginas— y el mapa de visibilidad vacío, que son los que
usan los planes del bloque 03. Para no leer tablas a ojo, `grep -c "| OK"`.

🔬 **El detalle** — Las comprobaciones de importación de MySQL —booleanos, nulos, JSON— son las que
atrapan los fallos silenciosos: una carga puede tener las filas correctas y los tipos estropeados.

---

## Lab l01 — `EXPLAIN` e índices medidos

Las 15 preguntas de [`l01`](l01-explain-e-indices-medidos.md).

**01 → 1.** ¿Qué añaden `ANALYZE` y `BUFFERS` a un `EXPLAIN`? 🟢

⏱️ **30 segundos** — `ANALYZE` ejecuta la consulta y añade los tiempos y las filas reales de cada
nodo. `BUFFERS` añade las páginas de 8 kB tocadas, en caché —`hit`— o leídas —`read`—.

🗣️ **2 minutos** — Sin `ANALYZE`, el plan solo trae estimaciones. En el lab, `BUFFERS` enseñó que el
`Seq Scan` tocó las 10 770 páginas de `pedidos` para 52 filas.

🔬 **El detalle** — **Motor.** `ANALYZE` ejecuta de verdad: con un `UPDATE` o un `DELETE`, se hace
dentro de una transacción que se deshace.

---

**01 → 2.** ¿Qué diferencia hay entre `Duración` de `\timing` y `Execution Time` del plan? 🟢

⏱️ **30 segundos** — `Duración` la mide `psql` desde el cliente, con la planificación y el viaje de
red. `Execution Time` lo mide el servidor, solo para ejecutar.

🗣️ **2 minutos** — En el lab: `Execution Time: 0.235 ms` y `Duración: 5,121 ms` para el mismo
`EXPLAIN`, que además tuvo que devolver el texto del plan.

🔬 **El detalle** — **Cliente frente a motor.** El usuario percibe la primera, y la diferencia son
red, planificación y formato.

---

**01 → 3.** ¿Qué significan los prompts `tienda=#`, `tienda=>`, `tienda=*#` y `tienda=!#`? 🟢

⏱️ **30 segundos** — `#` es superusuario y `>` rol normal. `*` significa dentro de una transacción,
y `!`, dentro de una transacción que falló y solo acepta `ROLLBACK`.

🗣️ **2 minutos** — En el lab, tras el error de `CREATE INDEX CONCURRENTLY` dentro de un `BEGIN`, el
prompt pasó de `=*#` a `=!#`.

🔬 **El detalle** — **Cliente**, `psql`. Leer el prompt evita el error clásico de seguir mandando
sentencias a una transacción abortada.

---

**01 → 4.** ¿Qué hace `text_pattern_ops` en un índice? 🟢

⏱️ **30 segundos** — Hace que el índice compare los textos byte a byte en vez de con la colación de
la base, y así sirve para `LIKE 'prefijo%'`.

🗣️ **2 minutos** — En el lab, el `LIKE 'PED-0004%'` pasó de `Seq Scan` en 87 ms a un rango `~>=~
'PED-0004' AND ~<~ 'PED-0005'` en 0,167 ms.

🔬 **El detalle** — **Motor**, PostgreSQL. Ese índice no sirve para `ORDER BY` con la colación de la
base: por eso se añade, no se sustituye.

---

**01 → 5.** Distingue `Filter` de `Index Cond` en un plan. 🟡

⏱️ **30 segundos** — `Index Cond` es la condición que se usa para bajar por el índice. `Filter` se
evalúa fila a fila sobre lo que ya se leyó.

🗣️ **2 minutos** — Sin índice, `cliente_id = 311` estaba en `Filter` y descartó 999 948 filas. Con
él, pasó a `Index Cond`, y el nodo leyó 9 páginas.

🔬 **El detalle** — **Motor.** Un índice que aparece con la condición en `Filter` se está usando para
otra cosa; esa columna no la cubre.

---

**01 → 6.** ¿Por qué `CREATE INDEX CONCURRENTLY` no puede ir dentro de una transacción? 🟡

⏱️ **30 segundos** — Porque construye en varias transacciones propias: confirma el índice en el
catálogo para que las demás empiecen a mantenerlo, y después lo llena. Dentro de un `BEGIN` no puede
confirmar.

🗣️ **2 minutos** — El error es literal: `CREATE INDEX CONCURRENTLY cannot run inside a transaction
block`. A cambio de no bloquear las escrituras, tarda más y puede quedar inválido si se interrumpe.

🔬 **El detalle** — **Motor.** Es el error típico de las herramientas de migraciones que envuelven
cada fichero en una transacción.

---

**01 → 7.** ¿Por qué el `LIKE 'PED-0004%'` no usa `pedidos_codigo_key`, y por qué el `ORDER BY
codigo` sí? 🟡

⏱️ **30 segundos** — Porque `pedidos_codigo_key` está ordenado por la colación `en_US.utf8`, y el
`LIKE` necesita el orden byte a byte para convertirse en un rango. El `ORDER BY` pide justo el orden
de la colación.

🗣️ **2 minutos** — Corrido: el `LIKE` hizo `Seq Scan` sobre las 10 770 páginas; el `ORDER BY codigo
LIMIT 3`, `Index Only Scan using pedidos_codigo_key`.

🔬 **El detalle** — **Motor.** Con la base en colación `C`, los dos órdenes coinciden y un solo
índice serviría para ambos.

---

**01 → 8.** Distingue un plan personalizado de uno genérico en una sentencia preparada. 🟡

⏱️ **30 segundos** — El personalizado se planifica con el valor real del parámetro; el genérico, sin
saberlo, y se reutiliza para cualquier valor.

🗣️ **2 minutos** — PostgreSQL planifica las primeras ejecuciones con el valor y, tras cinco, puede
quedarse con el genérico si su coste sale parecido. En el lab: 5,2 ms con el personalizado, que usó
el índice parcial, y 70,7 ms con el genérico, que no pudo.

🔬 **El detalle** — **Motor.** `plan_cache_mode` fuerza uno u otro, y `EXPLAIN (GENERIC_PLAN)` enseña
el genérico sin ejecutar.

---

**01 → 9.** ¿Qué parte de lo visto en este lab es del estándar y qué parte del motor? Da dos
ejemplos. 🟡

⏱️ **30 segundos** — Casi todo es del motor. El estándar no define índices, `EXPLAIN` ni planes
preparados con caché.

🗣️ **2 minutos** — Ejemplos: `CREATE INDEX CONCURRENTLY` y `text_pattern_ops` son de PostgreSQL;
MySQL tiene `ALGORITHM=INPLACE, LOCK=NONE` y usa su índice normal para el `LIKE` con prefijo.

🔬 **El detalle** — `LIKE` y `PREPARE` sí están en ISO/IEC 9075; lo que hacen con un índice, no. La
norma es de pago y no he verificado sus cláusulas.

---

**01 → 10.** ¿Por qué el `BitmapOr` tardó 263 ms la primera vez y 38 ms después? 🟠

⏱️ **30 segundos** — Por la caché. La primera vez leyó 8 637 páginas del disco, con 182 ms de `I/O
Timings`; después, todas estaban en `shared_buffers`.

🗣️ **2 minutos** — El `Seq Scan` anterior no dejó la tabla en caché, porque los barridos de tablas
grandes usan un anillo pequeño de páginas. En caliente, el mapa de bits ganó al `Seq Scan`: 38 ms
contra 71.

🔬 **El detalle** — **Motor.** La lección es de método: dos planes se comparan en las mismas
condiciones de caché, o se compara el disco.

---

**01 → 11.** ¿Por qué un `OR` entre dos columnas necesita un índice por rama? 🟠

⏱️ **30 segundos** — Porque la rama sin índice podría traer cualquier fila, y para encontrarlas hay
que leer la tabla entera; entonces el índice de la otra rama no ahorra nada.

🗣️ **2 minutos** — Con solo `pedidos_cliente_id_idx`, `cliente_id = 311 OR estado = 'ANULADO'` hizo
`Seq Scan`. Con un índice también en `estado`, el motor combinó los dos con `BitmapOr`.

🔬 **El detalle** — **Motor.** La alternativa con un solo índice es partir en dos consultas unidas
con `UNION`, pagando la deduplicación.

---

**01 → 12.** ¿Por qué el `Index Scan` de `CLI-00311` tocó 9 páginas y el de `cliente_id = 4210`, 31?
🟠

⏱️ **30 segundos** — Porque el coste de un `Index Scan` son las páginas del heap que visita, y los
52 pedidos de `CLI-00311` viven en tres páginas por cómo los fija la semilla. Los 25 de 4210 están
repartidos.

🗣️ **2 minutos** — Mismo índice, mismo plan: lo que cambia es dónde viven las filas. Para un cliente
cualquiera, cada fila es casi una página más.

🔬 **El detalle** — **Motor.** Es la correlación física que el bloque 03 enseña con BRIN: cuanto más
juntas estén las filas, más barato es visitarlas.

---

**01 → 13.** ¿Qué harías con un índice parcial que tu aplicación deja de usar tras unas ejecuciones?
🟠

⏱️ **30 segundos** — Comprobar si el valor llega como parámetro con un plan genérico. Si la consulta
siempre pregunta por el mismo valor, lo escribiría como literal en el SQL.

🗣️ **2 minutos** — Si pregunta por varios valores, el parcial no es la herramienta: un índice normal
sobre `(estado, creado_en)`. Como último recurso, `plan_cache_mode = force_custom_plan` para esa
sesión, pagando la planificación en cada ejecución.

🔬 **El detalle** — **Motor y driver.** Se diagnostica con `EXPLAIN (GENERIC_PLAN)` sobre la
sentencia con `$1`.

---

**01 → 14.** Diagnostica: una migración falla con `CREATE INDEX CONCURRENTLY cannot run inside a
transaction block`. Da la causa y la corrección en la herramienta de migraciones. 🔴

⏱️ **30 segundos** — La herramienta envuelve cada migración en una transacción. La corrección es
marcar esa migración para que corra fuera de ella, sola y con el índice concurrente como única
sentencia.

🗣️ **2 minutos** — Si la construcción se interrumpe, el índice queda inválido: la migración
siguiente lo comprueba en `pg_index` y lo borra antes de reintentar.

🔬 **El detalle** — Cómo se marca depende de la herramienta; es del bloque 06, dueño de las
migraciones, que lista el [README de la raíz](../README.md).

---

**01 → 15.** Diseña, con las sesiones de este lab, la prueba que demuestra si el motor tenía razón
al no usar un índice. Escribe las sentencias. 🔴

⏱️ **30 segundos** — Medir los dos caminos en caliente: el plan elegido y el rechazado, forzado con
un `enable_*` en la sesión, comparando páginas y `Execution Time`.

🗣️ **2 minutos** — La secuencia:

```sql
EXPLAIN (ANALYZE, BUFFERS, COSTS OFF, TIMING OFF) SELECT …;   -- dos veces: la primera calienta
SET enable_bitmapscan = off;                                  -- o enable_seqscan = off, según el caso
EXPLAIN (ANALYZE, BUFFERS, COSTS OFF, TIMING OFF) SELECT …;
RESET enable_bitmapscan;
```

En el lab, el `OR` dio 38 ms con el mapa de bits y 71 con el `Seq Scan` forzado.

🔬 **El detalle** — `enable_*` no prohíbe un camino: lo encarece. Y se devuelve con `RESET`, o los
planes siguientes de la sesión no son los del motor.

---

## Lab l02 — Aislamiento y bloqueos en vivo

Las 15 preguntas de [`l02`](l02-aislamiento-y-bloqueos-en-vivo.md).

**02 → 1.** ¿Para qué sirve `PGAPPNAME`, y dónde se ve su valor? 🟢

⏱️ **30 segundos** — Fija el `application_name` de la conexión, y se ve en la columna del mismo
nombre de `pg_stat_activity`.

🗣️ **2 minutos** — En el lab, cada terminal se llamó `sesion_a`, `sesion_b` o `sesion_c`, y el
diagnóstico se leyó por nombre, no por número de proceso. Una aplicación debería ponerlo siempre.

🔬 **El detalle** — **Cliente y motor**: la variable la lee libpq; la columna es de PostgreSQL. Los
drivers tienen su equivalente en la cadena de conexión.

---

**02 → 2.** ¿Qué significan los estados `active` e `idle in transaction` de `pg_stat_activity`? 🟢

⏱️ **30 segundos** — `active` es que está ejecutando una sentencia, o esperando dentro de ella.
`idle in transaction` es que tiene una transacción abierta y no está haciendo nada: espera al
cliente.

🗣️ **2 minutos** — En el lab, B estaba `active` pero esperando un bloqueo, y A, la que bloqueaba,
`idle in transaction`.

🔬 **El detalle** — **Motor.** `active` no significa «trabajando»: la columna que dice qué espera es
`wait_event_type`.

---

**02 → 3.** ¿Qué hace `pg_blocking_pids()`? 🟢

⏱️ **30 segundos** — Devuelve la lista de procesos que bloquean al proceso que se le pasa, sin tener
que cruzar `pg_locks` a mano.

🗣️ **2 minutos** — En el lab, para B devolvió `{2872}`, el proceso de A. Es una lista porque se
puede esperar a varios a la vez.

🔬 **El detalle** — **Motor**, PostgreSQL. El culpable no aparece esperando a nadie: su lista está
vacía, y hay que buscarlo por los que lo esperan.

---

**02 → 4.** ¿Qué limita `lock_timeout`, y qué lo distingue de `statement_timeout`? 🟢

⏱️ **30 segundos** — `lock_timeout` limita cuánto se espera a un bloqueo. `statement_timeout` limita
lo que dura la sentencia entera, esperas incluidas.

🗣️ **2 minutos** — Con `lock_timeout = '2s'`, el `UPDATE` de B falló con `canceling statement due to
lock timeout`. Por defecto vale 0: sin límite.

🔬 **El detalle** — **Motor.** Se fija por sesión, por transacción o por rol, y `RESET` lo devuelve
al valor del servidor.

---

**02 → 5.** Distingue lo que ve A en `READ COMMITTED` y en `REPEATABLE READ` cuando B cambia una
fila entre sus dos lecturas. 🟡

⏱️ **30 segundos** — En `READ COMMITTED`, A ve el cambio en la segunda lectura: `PAGADO` y después
`ENVIADO`. En `REPEATABLE READ` ve `PAGADO` las dos veces, porque lee siempre la foto de su primera
sentencia.

🗣️ **2 minutos** — Al confirmar la transacción `REPEATABLE READ`, la siguiente lectura de A ya ve
`ENVIADO`. En ningún caso B esperó.

🔬 **El detalle** — **Estándar** el fenómeno —lectura no repetible— y **motor** el mecanismo: el MVCC
de PostgreSQL da la foto sin bloquear.

---

**02 → 6.** ¿Por qué B espera un bloqueo de tipo `transactionid` y no uno sobre la fila? 🟡

⏱️ **30 segundos** — Porque la fila ya tiene una versión nueva escrita por una transacción que no ha
terminado, y B tiene que saber si esa transacción confirma o deshace. Espera a la transacción.

🗣️ **2 minutos** — Por eso el bloqueo dura hasta el `COMMIT` o el `ROLLBACK` de A, no hasta que A
termine su sentencia.

🔬 **El detalle** — **Motor.** PostgreSQL no guarda los bloqueos de fila en memoria compartida: los
marca en la propia fila, y quien choca espera al identificador de la transacción que la marcó.

---

**02 → 7.** ¿Qué significa el SQLSTATE `40001`, y qué tiene que hacer la aplicación al recibirlo? 🟡

⏱️ **30 segundos** — Fallo de serialización: la transacción no se puede completar sin romper el
aislamiento. La aplicación tiene que repetir la transacción entera desde el principio.

🗣️ **2 minutos** — En el lab salió en `REPEATABLE READ`, al escribir una fila que otra había
cambiado: `could not serialize access due to concurrent update`. El reintento se decide por el
código, no por el texto.

🔬 **El detalle** — **Estándar** el código. Sin bucle de reintento, subir el aislamiento solo cambia
datos corruptos por errores.

---

**02 → 8.** ¿Qué parte de este lab es del estándar y qué parte del motor? Da dos ejemplos. 🟡

⏱️ **30 segundos** — Del estándar, los niveles de aislamiento y el código `40001`. Del motor,
`lock_timeout`, `pg_stat_activity`, `pg_blocking_pids()` y los tiempos de espera.

🗣️ **2 minutos** — El nivel por defecto tampoco lo fija la norma: PostgreSQL usa `READ COMMITTED` y
MySQL `REPEATABLE READ`.

🔬 **El detalle** — ISO/IEC 9075 es de pago y no he verificado sus cláusulas; el bloque 04 recoge lo
que consta.

---

**02 → 9.** ¿Por qué en el paso 3 la sesión que bloquea está `idle in transaction`, y qué dice eso
del código? 🟠

⏱️ **30 segundos** — Porque terminó su `UPDATE` y no confirmó: tiene la fila y está esperando al
cliente. Dice que el código abrió una transacción y se fue a hacer otra cosa.

🗣️ **2 minutos** — Lo típico: una llamada a otro servicio, un cálculo largo o un error capturado que
deja la transacción abierta. La corrección está en el código: la transacción alrededor de las
sentencias, nada más.

🔬 **El detalle** — **Aplicación.** La base no tiene la culpa; lo que puede hacer es cortar con
`idle_in_transaction_session_timeout`.

---

**02 → 10.** ¿Por qué el `UPDATE` de A falla en `REPEATABLE READ` y en `READ COMMITTED` no habría
fallado? 🟠

⏱️ **30 segundos** — En `REPEATABLE READ`, A decide con su foto, y la fila cambió después;
escribirla perdería el cambio de B, así que PostgreSQL lo impide. En `READ COMMITTED`, el `UPDATE`
relee la versión confirmada y escribe encima.

🗣️ **2 minutos** — Eso último es la actualización perdida: sin error, y con el cambio de B pisado.

🔬 **El detalle** — **Motor.** En MySQL, `REPEATABLE READ` no lanza este error: la escritura lee la
última versión confirmada.

---

**02 → 11.** ¿Qué información da el registro del servidor en un interbloqueo que el cliente no da? 🟠

⏱️ **30 segundos** — Las dos sentencias del ciclo: una línea `Process …:` por cada proceso, con su
SQL.

🗣️ **2 minutos** — El cliente solo recibe los números de proceso y de transacción. Con las dos
sentencias se encuentran las dos rutas de código que toman las filas en orden distinto.

🔬 **El detalle** — **Motor.** Por eso el mensaje dice `See server log for query details`, y el
registro va en inglés aunque el cliente esté en español: lo fija `lc_messages` del servidor.

---

**02 → 12.** ¿Qué pasa con los bloqueos de una sesión que supera
`idle_in_transaction_session_timeout`, y qué ve su aplicación? 🟠

⏱️ **30 segundos** — El servidor cierra la conexión y deshace la transacción, con lo que suelta
todos sus bloqueos. La aplicación ve un error de conexión en su siguiente sentencia.

🗣️ **2 minutos** — En el lab: `FATAL: terminating connection due to idle-in-transaction timeout`, y
`psql` reconectó solo. Un *pool* tiene que detectar la conexión rota y descartarla.

🔬 **El detalle** — **Motor.** En producción se fija en minutos, por rol o en el servidor, no en
segundos.

---

**02 → 13.** ¿Por qué subir `deadlock_timeout` no arregla los interbloqueos? 🟠

⏱️ **30 segundos** — Porque solo es cuánto se espera antes de buscar el ciclo. El ciclo no se
resuelve solo: al buscarlo, el motor mata a una de las dos igual, más tarde.

🗣️ **2 minutos** — Lo que los arregla es el orden: que todas las rutas tomen las filas en el mismo
sentido, por ejemplo por `id` ascendente.

🔬 **El detalle** — **Motor.** Subirlo solo tiene sentido para reducir el coste de buscar ciclos en
sistemas con muchas esperas cortas que no lo son.

---

**02 → 14.** Diagnostica: una API se queda colgada y en `pg_stat_activity` hay una fila `idle in
transaction` con `xact_start` de hace doce minutos. Da la secuencia de pasos, de la consulta a la
corrección. 🔴

⏱️ **30 segundos** — Confirmar con `pg_blocking_pids()` que las peticiones esperan a ese proceso;
mirar su `application_name` y su última consulta; terminarlo con `pg_terminate_backend`; y corregir
el código que dejó la transacción abierta.

🗣️ **2 minutos** — Terminarlo deshace su transacción y libera a los demás, pero es el síntoma. La
causa está en la ruta de código de su última consulta. Y como red,
`idle_in_transaction_session_timeout` para el rol de la aplicación.

🔬 **El detalle** — `pg_cancel_backend` no sirve aquí: cancela la sentencia en curso, y esa sesión no
está ejecutando nada.

---

**02 → 15.** Diseña cómo reproducirías en un entorno de pruebas un interbloqueo que aparece en
producción una vez al día, partiendo del registro del servidor. 🔴

⏱️ **30 segundos** — Sacar del registro las dos sentencias del ciclo y sus filas; abrir dos sesiones
con `BEGIN`; ejecutar la primera de cada una, y después la segunda de cada una en orden cruzado.

🗣️ **2 minutos** — Es la secuencia del paso 5: el ciclo se produce siempre que el orden se cruza, y
en producción solo coincide una vez al día. Reproducido, se prueba la corrección: el mismo guion con
las filas en el mismo orden no debe dar el error nunca.

🔬 **El detalle** — `CONTEXTO` da la tupla y la tabla; con ellas se eligen filas equivalentes en el
entorno de pruebas.

---

## Lab l03 — Respaldo y restauración

Las 15 preguntas de [`l03`](l03-respaldo-y-restauracion.md).

**03 → 1.** ¿Qué diferencia hay entre un respaldo lógico y uno físico? 🟢

⏱️ **30 segundos** — El lógico guarda el contenido como sentencias y datos; el físico copia los
ficheros del servidor tal cual, páginas e índices incluidos.

🗣️ **2 minutos** — El lógico es portable y selectivo, y al restaurar reconstruye los índices. El
físico se restaura sin reconstruir nada y, con el WAL, permite volver a cualquier instante.

🔬 **El detalle** — **Motor.** Un respaldo físico solo se restaura en la misma versión mayor de
PostgreSQL; uno lógico, en otras.

---

**03 → 2.** ¿Qué hace el formato `-Fc` de `pg_dump`? 🟢

⏱️ **30 segundos** — Es el formato propio de PostgreSQL: comprimido y con un índice de su contenido.

🗣️ **2 minutos** — El índice permite restaurar tablas sueltas y restaurar en paralelo con
`pg_restore -j`. En el lab: 142 MB.

🔬 **El detalle** — **Motor.** El formato plano, `-Fp`, es SQL legible, pero no admite `-j` ni
selección al restaurar.

---

**03 → 3.** ¿Qué son el RPO y el RTO? 🟢

⏱️ **30 segundos** — El RPO es cuántos datos puedes perder, medido en tiempo. El RTO, cuánto tardas
en volver a funcionar.

🗣️ **2 minutos** — Con un respaldo diario, el RPO es de hasta 24 horas. Con WAL continuo, segundos.
El RTO es el tiempo de restaurar, verificar y redirigir la aplicación.

🔬 **El detalle** — **Convención** de operaciones, no de ningún motor. Su definición es del bloque
06.

---

**03 → 4.** ¿Para qué sirve `pg_switch_wal()`? 🟢

⏱️ **30 segundos** — Cierra el segmento de WAL en curso y empieza uno nuevo, para que el que tenía
los últimos cambios se pueda archivar entero.

🗣️ **2 minutos** — En el lab, tras el accidente, garantizó que `pg_receivewal` tuviera completo el
segmento con el `DELETE`.

🔬 **El detalle** — **Motor.** En un servidor tranquilo, sin él, el último segmento puede tardar
mucho en llenarse, y el RPO real crece.

---

**03 → 5.** ¿Por qué el respaldo lógico ocupa 142 MB y la base 1 316? 🟡

⏱️ **30 segundos** — Porque guarda los datos, no las páginas: ni índices, ni espacio libre, ni
versiones muertas, y además comprimido.

🗣️ **2 minutos** — Los índices se reconstruyen al restaurar, que es donde está el coste: 15 s en
paralelo y 22 en serie.

🔬 **El detalle** — **Motor.** La base restaurada salió con 1 322 MB: índices recién construidos.

---

**03 → 6.** ¿Por qué `pg_restore -j` no funciona leyendo de la entrada estándar? 🟡

⏱️ **30 segundos** — Porque varias conexiones leen partes distintas del fichero a la vez, y eso
necesita acceso aleatorio. Un flujo solo se lee una vez, en orden.

🗣️ **2 minutos** — El error es literal: `parallel restore from standard input is not supported`. Se
copia el fichero donde corre `pg_restore` y se le pasa la ruta.

🔬 **El detalle** — **Herramienta.** `-j` tampoco admite el formato plano.

---

**03 → 7.** Distingue `pg_receivewal` de `archive_command`: qué hace cada uno y dónde corre. 🟡

⏱️ **30 segundos** — `pg_receivewal` corre en otra máquina y recibe el WAL por replicación, en
tiempo real. `archive_command` es una orden que el servidor ejecuta cada vez que completa un
segmento.

🗣️ **2 minutos** — `archive_command` no guarda el segmento en curso; `pg_receivewal`, sí, como
`.partial`. El primero exige configurar el servidor; el segundo, permiso de replicación.

🔬 **El detalle** — **Motor.** El lab usó `pg_receivewal` porque no requiere reiniciar el servidor.

---

**03 → 8.** ¿Qué parte de este lab es del estándar y qué parte del motor? Da dos ejemplos. 🟡

⏱️ **30 segundos** — Nada es del estándar. `pg_dump`, `pg_basebackup` y el WAL son de PostgreSQL;
`mysqldump` y el *binary log*, de MySQL.

🗣️ **2 minutos** — Hasta el concepto de recuperación a un instante es de cada motor: PostgreSQL
reaplica WAL y MySQL reaplica el *binary log*.

🔬 **El detalle** — ISO/IEC 9075 es de pago y no he verificado sus cláusulas; ningún motor documenta
sus respaldos como parte de la norma.

---

**03 → 9.** ¿Por qué `pg_basebackup` tardó 216 s por defecto y 3 s con `-c fast`? 🟠

⏱️ **30 segundos** — Porque el respaldo empieza con un *checkpoint*, y por defecto lo pide
espaciado: el servidor reparte la escritura a lo largo de su intervalo normal. `-c fast` lo pide
inmediato.

🗣️ **2 minutos** — La copia de 1,4 GB tardó segundos en los dos casos; el resto era esperar. En
producción cargada, espaciado es más amable; con prisa o en una ventana tranquila, rápido.

🔬 **El detalle** — **Motor.** La documentación de `pg_basebackup` declara `spread` como defecto.

---

**03 → 10.** ¿Por qué falló la primera recuperación, y qué orden la habría evitado? 🟠

⏱️ **30 segundos** — Faltaba un segmento de WAL entre el final del respaldo y el principio del
flujo. Arrancar `pg_receivewal` antes del respaldo base lo habría evitado.

🗣️ **2 minutos** — El respaldo traía hasta el `…8F`, el flujo empezó en el `…91`, y el `…90` no
estaba en ningún sitio. El servidor aplicó lo que tenía y se paró antes del instante pedido.

🔬 **El detalle** — **Motor.** El error es `recovery ended before configured recovery target was
reached`, y el registro enseña antes el `cp: cannot stat` del segmento que falta.

---

**03 → 11.** ¿Qué significa `selected new timeline ID: 2`, y por qué hace falta? 🟠

⏱️ **30 segundos** — Que el servidor restaurado empieza una historia nueva desde el instante
elegido, en otra línea temporal.

🗣️ **2 minutos** — Su WAL nuevo no se puede confundir con el del original, que siguió y vivió el
borrado. Los segmentos llevan la línea temporal en el nombre.

🔬 **El detalle** — **Motor.** Sin líneas temporales, una segunda recuperación no sabría qué rama de
la historia seguir.

---

**03 → 12.** ¿Por qué se restaura al lado del servidor dañado y no encima? 🟠

⏱️ **30 segundos** — Porque el dañado tiene todo lo bueno posterior al accidente, y restaurar encima
lo perdería. Al lado, se comprueba y se copia solo lo perdido.

🗣️ **2 minutos** — En el lab, el restaurado tenía los 273 126 pagos y el original seguía con 0: se
copiarían de uno a otro. Y si la restauración sale mal, no se ha empeorado nada.

🔬 **El detalle** — **Convención** de operaciones, la que hace de una restauración un proceso
reversible.

---

**03 → 13.** ¿Qué se pierde en una recuperación a un instante, y de qué depende? 🔴

⏱️ **30 segundos** — Lo que pasó entre el instante elegido y el momento del accidente, y lo que no
llegó a guardarse del WAL.

🗣️ **2 minutos** — Depende de lo fino que se elija el instante y de que el WAL esté completo y
continuo. Con `pg_receivewal` en tiempo real, segundos.

🔬 **El detalle** — **Motor.** Se puede apuntar a un identificador de transacción o a un nombre de
punto de restauración, además de a una hora.

---

**03 → 14.** Diagnostica: una recuperación termina con `recovery ended before configured recovery
target was reached`. Da dos causas y cómo comprobarías cada una. 🔴

⏱️ **30 segundos** — Un hueco en el WAL, o un instante objetivo posterior al último WAL guardado. Lo
primero se ve en el registro, con `cp: cannot stat` de un segmento intermedio; lo segundo, con `last
completed transaction was at log time`, anterior al objetivo.

🗣️ **2 minutos** — Para el hueco: comparar el final del respaldo, en su `backup_label` o su
manifiesto, con el primer segmento guardado. Para el objetivo: comprobar que el WAL llega hasta
después de esa hora.

🔬 **El detalle** — **Motor.** Un instante anterior al final del respaldo base tampoco se puede
alcanzar: se restaura desde un respaldo más antiguo.

---

**03 → 15.** Diseña el procedimiento, orden por orden, para deshacer un `DELETE` sin `WHERE` en
producción sin perder las escrituras buenas posteriores. 🔴

⏱️ **30 segundos** — Localizar la hora del `DELETE`; restaurar el último respaldo base en otro
servidor con `recovery_target_time` justo antes; comprobar los datos; y copiar al servidor de
producción solo las filas borradas.

🗣️ **2 minutos** — Orden: el respaldo base anterior al accidente; `recovery.signal` y
`restore_command` apuntando al WAL; el objetivo; arrancar, leer `recovery stopping before commit` en
el registro; exportar las filas con `\copy` o `COPY` y cargarlas en producción. Todo lo bueno
posterior sigue en producción, porque no se ha tocado.

🔬 **El detalle** — `recovery_target_action = 'pause'` permite mirar los datos antes de promover y,
si el instante no era el bueno, moverlo.

---

## Lab l04 — Redis y MongoDB

Las 15 preguntas de [`l04`](l04-redis-y-mongodb.md).

**04 → 1.** ¿Qué hace `SET clave valor EX 5`, y qué responde `TTL` después? 🟢

⏱️ **30 segundos** — Guarda el valor con una caducidad de cinco segundos, en una sola orden. `TTL`
responde los segundos que le quedan; cuando caduca, `-2`.

🗣️ **2 minutos** — En el lab respondió `(integer) 3` poco después, y `-2` pasados los cinco
segundos, con `GET` devolviendo `(nil)`.

🔬 **El detalle** — **Motor**, Redis. Ponerlo en la misma orden importa: un `SET` y después un
`EXPIRE` dejan un instante en que la clave existe sin caducidad.

---

**04 → 2.** ¿Qué es el patrón *cache-aside*? 🟢

⏱️ **30 segundos** — La aplicación busca primero en la caché; si no está, lee de la base, guarda el
resultado en la caché con una caducidad y lo devuelve.

🗣️ **2 minutos** — La caché no sabe nada de la base: es la aplicación la que la llena y la invalida.
Es simple, y su punto débil es el instante en que una clave caduca.

🔬 **El detalle** — **Convención** de diseño, no de Redis. Su dueño es el bloque 07.

---

**04 → 3.** ¿Qué son `COLLSCAN` e `IXSCAN` en un `explain` de MongoDB? 🟢

⏱️ **30 segundos** — `COLLSCAN` es recorrer la colección entera, el `Seq Scan` de MongoDB. `IXSCAN`
es recorrer un índice, y suele ir debajo de un `FETCH` que trae los documentos.

🗣️ **2 minutos** — En el lab, sin índice: `COLLSCAN`, 99 999 documentos examinados para devolver 7.
Con él: `FETCH` sobre `IXSCAN`, 7 y 7.

🔬 **El detalle** — **Motor.** Los nombres cambian; el razonamiento es el de `EXPLAIN` en PostgreSQL.

---

**04 → 4.** ¿Qué significa el error `E11000`? 🟢

⏱️ **30 segundos** — Clave duplicada en un índice único. En el lab, un segundo documento con `_id`
`PED-00042`.

🗣️ **2 minutos** — Toda colección tiene un índice único sobre `_id`, llamado `_id_`, y el error dice
qué índice y qué valor chocaron.

🔬 **El detalle** — **Motor.** Es el SQLSTATE `23505` de PostgreSQL con otro nombre.

---

**04 → 5.** Distingue los valores -1 y -2 de `TTL`. 🟡

⏱️ **30 segundos** — `-2` es que la clave no existe. `-1` es que existe y no tiene caducidad.

🗣️ **2 minutos** — Una clave de caché con `-1` es un error de diseño: se quedará para siempre. Por
eso se guarda con `EX` en la misma orden.

🔬 **El detalle** — **Motor.** Los dos valores se distinguen desde Redis 2.8; antes, `-1` servía para
los dos casos.

---

**04 → 6.** ¿Por qué `SET … NX` sirve de candado, y por qué necesita caducidad? 🟡

⏱️ **30 segundos** — Porque escribe solo si la clave no existe, y lo hace de forma atómica: de
muchos que lo intentan a la vez, uno lo consigue. Necesita caducidad para que un proceso que muere
con el candado no lo deje puesto para siempre.

🗣️ **2 minutos** — En el lab, `ex=5` en el candado: si quien cargaba moría, a los cinco segundos
otro podía intentarlo.

🔬 **El detalle** — **Motor.** Para un candado entre varios nodos de Redis, un solo `SET NX` no
basta; para una caché, sí.

---

**04 → 7.** ¿Por qué el importe se exportó como `$numberDecimal` y no como número? 🟡

⏱️ **30 segundos** — Porque un número de JSON se importa como coma flotante, y el dinero no puede ir
en coma flotante. `$numberDecimal` lo guarda como `Decimal128`.

🗣️ **2 minutos** — Gracias a eso, la suma por estado de MongoDB coincidió al céntimo con la de
PostgreSQL.

🔬 **El detalle** — Es la trampa del dinero de
[`10/03`](../10-interfaz-con-los-lenguajes/03-mapeo-de-tipos.md) §4, en otro motor. La fecha, igual:
`$date`.

---

**04 → 8.** ¿Qué parte de este lab tiene equivalente en SQL y cuál no? Da dos ejemplos. 🟡

⏱️ **30 segundos** — Tienen equivalente el `explain` —`EXPLAIN`—, el `$group` —`GROUP BY`— y el
`E11000` —`23505`—. No lo tiene la caducidad de un dato: PostgreSQL no borra filas solas.

🗣️ **2 minutos** — El candado `SET NX` se parece a un `INSERT … ON CONFLICT DO NOTHING`, pero sin
transacción ni durabilidad garantizadas en la misma medida.

🔬 **El detalle** — Ni Redis ni MongoDB siguen un estándar como ISO/IEC 9075: cada uno es su propia
especificación.

---

**04 → 9.** ¿Qué es una estampida de caché, y por qué ocurre justo al caducar una clave? 🟠

⏱️ **30 segundos** — Muchas peticiones encuentran la caché vacía a la vez y todas van a la base por
el mismo dato. Ocurre al caducar porque es el único instante en que todas fallan juntas.

🗣️ **2 minutos** — En el lab, 50 peticiones fueron 50 consultas idénticas a PostgreSQL. Con carga
real y una consulta cara, el pico puede tumbar la base justo cuando la caché no la protege.

🔬 **El detalle** — **Convención** de diseño: se llama también *thundering herd* o *dog-piling*.

---

**04 → 10.** ¿Por qué la versión con candado tardó menos en total que la ingenua? 🟠

⏱️ **30 segundos** — Porque la base atendió una consulta de 200 ms en vez de cincuenta compitiendo
entre sí: 283 ms frente a 405.

🗣️ **2 minutos** — Los 49 que esperaban solo leían de Redis cada 50 ms, que es barato. La versión
ingenua repartía la base entre cincuenta consultas a la vez.

🔬 **El detalle** — Con una base más cargada, la diferencia crece: cincuenta consultas simultáneas
compiten por CPU, disco y conexiones.

---

**04 → 11.** ¿Por qué el error de `mongoimport` sin credenciales despista, y dónde se ve la causa? 🟠

⏱️ **30 segundos** — Porque no dice «autenticación»: dice que el servidor cerró la conexión
inesperadamente. La causa está en el registro del servidor, que anota `Connection not
authenticating`.

🗣️ **2 minutos** — Se ve con `docker logs bd-lab-mongo`. Con `-u`, `-p` y `--authenticationDatabase
admin`, la importación de 99 999 documentos tardó 2,96 s.

🔬 **El detalle** — **Motor y herramienta.** La lección es general: cuando el cliente da un error de
red, el registro del servidor dice si fue la red.

---

**04 → 12.** ¿Qué dos cifras de `explain("executionStats")` delatan que falta un índice? 🟠

⏱️ **30 segundos** — `totalDocsExamined` frente a `nReturned`: 99 999 examinados para devolver 7.

🗣️ **2 minutos** — Con el índice, las dos se igualan —7 y 7—, y `totalKeysExamined` también. Cuando
se parecen, la consulta hace el trabajo justo.

🔬 **El detalle** — **Motor.** Es la misma lectura que `Rows Removed by Filter` en PostgreSQL.

---

**04 → 13.** ¿Qué otras dos defensas contra la estampida hay además del candado, y qué protege cada
una? 🟠

⏱️ **30 segundos** — Caducidades con azar, que evitan que caduquen juntas muchas claves creadas a la
vez; y refresco anticipado, que recarga una clave antes de que caduque.

🗣️ **2 minutos** — El candado protege una clave de muchas peticiones a la vez; el azar protege un
lote de claves; el refresco evita que la clave llegue a faltar.

🔬 **El detalle** — Se combinan. Ninguna sustituye a que la base aguante una carga en frío, tras un
reinicio de la caché.

---

**04 → 14.** Diagnostica: cada hora en punto la base recibe un pico de consultas idénticas y la
latencia se dispara durante unos segundos. Da la hipótesis, cómo la confirmarías y dos correcciones.
🔴

⏱️ **30 segundos** — Claves de caché creadas a la vez con la misma caducidad de una hora, que
caducan juntas y provocan una estampida. Se confirma con el `TTL` de esas claves y con el log de
consultas en el pico.

🗣️ **2 minutos** — Correcciones: azar en la caducidad, para repartirlas, y un candado por clave para
que solo un proceso recargue cada una. Con el refresco anticipado, ni siquiera faltarían.

🔬 **El detalle** — En PostgreSQL, las consultas idénticas en el pico se ven agrupadas en
`pg_stat_statements`, del bloque 06.

---

**04 → 15.** Diseña la comprobación de que una colección de MongoDB cargada desde PostgreSQL tiene
los mismos datos: qué agregaciones y qué consultas SQL compararías. 🔴

⏱️ **30 segundos** — El recuento de documentos contra el de filas; y una agregación por estado con
recuento y suma de importes contra su `GROUP BY`, que en el lab coincidió al céntimo.

🗣️ **2 minutos** — Además, el recuento de líneas con `$unwind` contra `pedido_lineas`, y una muestra
de documentos concretos —`PED-00042`— comparados campo a campo, con sus tipos.

🔬 **El detalle** — Los tipos son lo que falla en silencio: una suma que no cuadra al céntimo delata
un importe importado como coma flotante.

---

## Lab l05 — Los otros modelos

Las 15 preguntas de [`l05`](l05-los-otros-modelos.md).

**05 → 1.** ¿Qué es la clave de partición en Cassandra? 🟢

⏱️ **30 segundos** — La parte de la clave primaria que decide en qué nodo vive cada fila. Toda
consulta tiene que nombrarla.

🗣️ **2 minutos** — En el lab, `cliente_id`: los pedidos de un cliente viven juntos y ordenados por
`creado_en`, la columna de agrupamiento.

🔬 **El detalle** — **Motor.** La tabla se diseña para una consulta; otra consulta, otra tabla.

---

**05 → 2.** ¿Qué es una hipertabla de TimescaleDB? 🟢

⏱️ **30 segundos** — Una tabla que se parte sola en tramos por tiempo, sin que las consultas lo
sepan: se escribe SQL normal.

🗣️ **2 minutos** — En el lab, con tramos de un día, un mes de eventos dio 27 tramos, creados al
insertar.

🔬 **El detalle** — **Motor**, extensión de PostgreSQL. Es particionado automático, con funciones
propias como `time_bucket`.

---

**05 → 3.** ¿Qué mide el operador `<->` de pgvector? 🟢

⏱️ **30 segundos** — La distancia euclídea entre dos vectores. Ordenar por ella da los más
parecidos.

🗣️ **2 minutos** — En el lab, `PRD-00017` quedó a 0,1732 del vector buscado y `PRD-04980` a 0,9274.

🔬 **El detalle** — **Extensión.** pgvector tiene otros operadores para otras distancias, como el
coseno; la elección depende del modelo que produce los vectores.

---

**05 → 4.** ¿Qué diferencia hay entre un campo `keyword` y uno `text` en OpenSearch? 🟢

⏱️ **30 segundos** — `keyword` guarda el valor entero, para filtrar y agrupar. `text` lo parte en
palabras analizadas, para buscar.

🗣️ **2 minutos** — En el lab, `categoria` como `keyword` sirvió para la agregación; `nombre` como
`text`, para la búsqueda por relevancia.

🔬 **El detalle** — **Motor.** Un campo puede tener los dos, con subcampos, cuando hace falta buscar
y agrupar por lo mismo.

---

**05 → 5.** ¿Por qué Cassandra rechaza una consulta por una columna que no es la partición? 🟢

⏱️ **30 segundos** — Porque sin la partición no sabe en qué nodo están las filas, y tendría que
recorrerlas todas. Se niega salvo `ALLOW FILTERING`.

🗣️ **2 minutos** — El error lo dice: podría implicar filtrar datos con rendimiento impredecible. En
un clúster grande, es un barrido de todos los nodos.

🔬 **El detalle** — **Motor.** La corrección es una tabla más, con esa columna como partición, y los
datos duplicados.

---

**05 → 6.** Distingue `CREATE` de `MERGE` en Cypher. 🟡

⏱️ **30 segundos** — `CREATE` crea siempre, aunque ya exista algo igual. `MERGE` busca el patrón y
solo lo crea si no existe.

🗣️ **2 minutos** — Por eso la carga del lab usó `MERGE`: cada producto aparecía en muchas compras.
Con una restricción de unicidad, un `CREATE` duplicado falla, como se vio.

🔬 **El detalle** — **Motor.** Sin restricción, Neo4j no tiene claves por defecto y `CREATE` duplica
sin avisar.

---

**05 → 7.** ¿Por qué una hipertabla no admite una clave primaria sin la columna de tiempo? 🟡

⏱️ **30 segundos** — Porque cada tramo es una tabla, y la unicidad solo se puede comprobar dentro de
cada una. Una clave sin la columna de tiempo no se podría garantizar entre tramos.

🗣️ **2 minutos** — El error del lab: `cannot create a unique index without the column
"ocurrido_en"`. Se corrige incluyendo la columna de tiempo en la clave, o sin clave única.

🔬 **El detalle** — **Motor.** Es la misma regla que el particionado nativo de PostgreSQL.

---

**05 → 8.** ¿Cuáles de los cinco motores hablan SQL y por qué? ¿Qué parte es estándar? 🟡

⏱️ **30 segundos** — TimescaleDB y pgvector, porque son extensiones de PostgreSQL. Cassandra habla
CQL; Neo4j, Cypher; OpenSearch y Qdrant, APIs JSON.

🗣️ **2 minutos** — Lo estándar de TimescaleDB y pgvector es el SQL de PostgreSQL; `time_bucket` y
`<->` son de cada extensión.

🔬 **El detalle** — Para grafos existe un estándar propio, GQL, que no se ha verificado en este lab.

---

**05 → 9.** ¿Qué es la exclusión de tramos, y cómo se vio en el plan de §5? 🟠

⏱️ **30 segundos** — Que el planificador descarta los tramos que no pueden contener filas del filtro
de tiempo. En el lab, la consulta de los últimos tres días recorrió 3 de 27 tramos.

🗣️ **2 minutos** — El plan tenía un `Append` con tres `Seq Scan`, uno por tramo, y ninguno de los
otros 24. Es lo que hace barata una consulta reciente sobre años de datos.

🔬 **El detalle** — **Motor.** Solo funciona si la consulta filtra por la columna de tiempo.

---

**05 → 10.** ¿Por qué pgvector y Qdrant dieron las mismas distancias, y qué los distingue entonces?
🟠

⏱️ **30 segundos** — Porque calcularon la misma distancia euclídea sobre los mismos vectores. Los
distingue dónde viven: pgvector en PostgreSQL, junto a los datos; Qdrant, en un servicio aparte.

🗣️ **2 minutos** — Con pgvector, los vectores están en la misma transacción que el resto. Con Qdrant
hay que sincronizarlo, a cambio de un motor hecho solo para eso.

🔬 **El detalle** — A gran escala importan los índices aproximados y su calidad; con dos vectores, la
búsqueda es exacta en los dos.

---

**05 → 11.** ¿Por qué la búsqueda de OpenSearch devolvió 5 000 documentos, y en qué se diferencia de
un `LIKE`? 🟠

⏱️ **30 segundos** — Porque todos los nombres contienen «producto», así que todos casan, y los
ordena por relevancia: `PRD-00017` con 3,69 y el resto con 0,00005. Un `LIKE` solo dice sí o no.

🗣️ **2 minutos** — Además, el analizador no distingue mayúsculas: `PRODUCTO 17` encontró «Producto
17» sin hacer nada.

🔬 **El detalle** — **Motor.** Para exigir la frase exacta está `match_phrase`.

---

**05 → 12.** ¿Qué pasa si no declaras el mapeo de un índice de OpenSearch? 🟠

⏱️ **30 segundos** — OpenSearch deduce el tipo de cada campo del primer documento que lo trae, y ese
tipo se queda.

🗣️ **2 minutos** — Un primer documento con un número como texto fijaría un tipo malo para siempre.
Con mapeo explícito, `"caro"` en un `float` dio `mapper_parsing_exception`.

🔬 **El detalle** — **Motor.** Cambiar el tipo de un campo exige crear otro índice y reindexar.

---

**05 → 13.** ¿Por qué la recomendación de §4 es más natural en Cypher que en SQL? 🟠

⏱️ **30 segundos** — Porque es un recorrido de relaciones: yo compré algo, otros lo compraron, ¿qué
más compraron? En Cypher es un patrón que se dibuja; en SQL, varios `JOIN` y un anti-join.

🗣️ **2 minutos** — En Neo4j, seguir una relación es seguir un puntero. En SQL, cada salto es un
`JOIN` que se resuelve buscando en un índice.

🔬 **El detalle** — Para agregados masivos sobre toda la tabla, el orden se invierte: SQL es mejor.

---

**05 → 14.** Diagnostica: una tabla de Cassandra responde en milisegundos a la consulta de siempre y
el equipo añade `ALLOW FILTERING` a una nueva que tarda minutos. Da la causa y la corrección. 🔴

⏱️ **30 segundos** — La consulta nueva no nombra la clave de partición y recorre todo el clúster. La
corrección es una tabla nueva, con la columna de la consulta como partición, y los datos duplicados
al escribir.

🗣️ **2 minutos** — La consulta de siempre lee una partición; la nueva, todas. `ALLOW FILTERING` solo
quitó el aviso. La escritura pasa a ir a dos tablas, idealmente en un lote.

🔬 **El detalle** — **Motor.** Es el diseño por consulta: en Cassandra, el modelo de datos sale de la
lista de consultas, no de las entidades.

---

**05 → 15.** Diseña cómo mantendrías sincronizado un índice de OpenSearch con la tabla `productos`
de PostgreSQL, y qué pasa si la sincronización se retrasa. 🔴

⏱️ **30 segundos** — Capturando los cambios de la tabla —con el registro de cambios del WAL o con
una tabla de eventos escrita en la misma transacción— y aplicándolos al índice en orden, por
`codigo`.

🗣️ **2 minutos** — Si se retrasa, la búsqueda enseña datos viejos: un producto desactivado sigue
apareciendo. Por eso la ficha se lee de PostgreSQL y el buscador solo sirve para encontrar, y se
vigila el retraso.

🔬 **El detalle** — Escribir en los dos desde la aplicación, sin transacción común, acaba
desincronizando: si la segunda escritura falla, ya no coinciden.

---

## Simulación de entrevista

Las 24 preguntas `S#` y los cuatro escenarios de [`06`](06-simulacion-de-entrevista.md). Los
escenarios no se responden de memoria: se defienden en voz alta, y la capa 🔬 es la que dice qué se
está evaluando de verdad.

**06 → S1.** ¿Por qué el corpus genera los datos en PostgreSQL y los exporta a los demás motores? 🟢

⏱️ **30 segundos** — Porque MySQL y SQLite no tienen `generate_series` ni `setseed`, y una semilla
propia en cada uno daría otra tienda. Exportando, los cuatro motores tienen las mismas filas y los
mismos `id`.

🗣️ **2 minutos** — Así, una comparación entre motores compara el motor, no los datos. La copia del
lab lo demostró: sus CSV pesaron byte a byte lo mismo que los del corpus.

🔬 **El detalle** — La exportación convierte tres cosas —fechas, booleanos y nulos—, y la
verificación de MySQL tiene cuatro comprobaciones propias para detectar si alguna se estropeó.

---

**06 → S2.** ¿Qué te dice `password authentication failed` de PostgreSQL, y qué no? 🟡

⏱️ **30 segundos** — Que la autenticación falló. No dice si fue la contraseña o que el rol no
existe: PostgreSQL responde igual a propósito.

🗣️ **2 minutos** — En el lab salió al conectarse como `tienda_app` antes de que `esquema.sql` creara
el rol. La causa real queda en el registro del servidor.

🔬 **El detalle** — **Motor.** Distinguirlos le diría a un atacante qué nombres de rol existen.

---

**06 → S3.** Un `up -d` responde `Recreate` en tres contenedores. ¿Perdiste los datos? 🟢

⏱️ **30 segundos** — No. Los contenedores se rehicieron porque su configuración en el `compose`
cambió, pero los datos viven en volúmenes con nombre, que sobreviven.

🗣️ **2 minutos** — Tras recrear MySQL, MariaDB y Redis, los recuentos seguían en un millón de
pedidos y la verificación de PostgreSQL daba 22 de 22.

🔬 **El detalle** — Lo que se pierde al recrear es el estado en memoria: cachés y contadores. Solo
`down -v` borra los volúmenes.

---

**06 → S4.** ¿Por qué un plan del corpus puede darte otro `rows=` con los mismos datos, y qué tiene
que coincidir? 🟠

⏱️ **30 segundos** — Porque `rows=` sale de la muestra de `ANALYZE`, que es al azar. Tiene que
coincidir la forma del plan y las filas reales.

🗣️ **2 minutos** — También mueven el coste el mapa de visibilidad y el tamaño de los índices, que se
pueden devolver al estado declarado; la muestra, no.

🔬 **El detalle** — **Motor.** `setseed` fija los datos, no la muestra.

---

**06 → S5.** ¿Qué dos números defienden un índice, y cuánto dieron en el lab? 🟢

⏱️ **30 segundos** — Cuánto baja la consulta y cuánto cuesta tenerlo. En `l01`, de 101,6 a 0,235
ms y de 10 770 páginas a 9, a cambio de 7 800 kB y 457 ms de construcción.

🗣️ **2 minutos** — Y una escritura más en cada `INSERT` y en cada `UPDATE` que toque la columna, que
es el coste que no se ve en la consulta.

🔬 **El detalle** — Las 9 páginas son pocas porque los pedidos de `CLI-00311` viven en tres páginas;
con un cliente cualquiera fueron 31.

---

**06 → S6.** ¿Por qué un `OR` entre dos columnas necesita un índice por rama? 🟡

⏱️ **30 segundos** — Porque la rama sin índice obliga a leer toda la tabla igualmente. Con un índice
en cada rama, el motor las combina con `BitmapOr`.

🗣️ **2 minutos** — En `l01`, con un índice solo, `Seq Scan`; con los dos, `BitmapOr`, 38 ms frente a
71 en caliente.

🔬 **El detalle** — **Motor.** Con un solo índice, la reescritura es partir la consulta con `UNION`.

---

**06 → S7.** ¿Por qué un `LIKE 'X%'` puede no usar el índice de la columna en PostgreSQL? 🟡

⏱️ **30 segundos** — Porque el índice está ordenado por la colación de la base, y el `LIKE` necesita
el orden byte a byte para convertirse en un rango.

🗣️ **2 minutos** — En `l01`, con `en_US.utf8`, el `LIKE 'PED-0004%'` barrió la tabla en 87 ms; con
un índice `text_pattern_ops`, 0,167 ms.

🔬 **El detalle** — **Motor.** En MySQL el índice normal sirve; en PostgreSQL, solo con colación `C`.

---

**06 → S8.** Un índice parcial se usa en `psql` y deja de usarse en la aplicación. ¿Por qué? 🟠

⏱️ **30 segundos** — Porque la aplicación pasa el valor como parámetro y, tras unas ejecuciones,
PostgreSQL puede quedarse con un plan genérico, que no sabe el valor y no puede demostrar que el
parcial aplica.

🗣️ **2 minutos** — En `l01`: 5,2 ms con el plan personalizado y 70,7 con el genérico, la misma
sentencia. Se ve con `EXPLAIN (GENERIC_PLAN)`.

🔬 **El detalle** — **Motor y driver.** Si el valor es siempre el mismo, va como literal en el SQL.

---

**06 → S9.** ¿Por qué hay que comparar dos planes en las mismas condiciones de caché? 🟠

⏱️ **30 segundos** — Porque la primera ejecución paga el disco. El `BitmapOr` de `l01` tardó 263 ms
en frío y 38 en caliente.

🗣️ **2 minutos** — Si comparas uno en frío con otro en caliente, comparas el disco, no el plan. Se
miden los dos en caliente, o se miran las páginas, que no dependen de la caché.

🔬 **El detalle** — Los barridos de tablas grandes usan un anillo pequeño de páginas y no dejan la
tabla en caché; por eso el plan siguiente la encontró fría.

---

**06 → S10.** ¿Qué significa `idle in transaction`, y por qué es tan habitual en la sesión que
bloquea? 🟢

⏱️ **30 segundos** — Que la sesión tiene una transacción abierta y no está ejecutando nada. Es
habitual porque terminó de escribir, no confirmó y el código se fue a hacer otra cosa.

🗣️ **2 minutos** — En `l02`, A estaba `idle in transaction` y B esperaba un `Lock` de tipo
`transactionid` sobre la transacción de A.

🔬 **El detalle** — **Aplicación.** La base solo puede cortar con
`idle_in_transaction_session_timeout`.

---

**06 → S11.** ¿Qué es `40001`, y qué tiene que hacer la aplicación al recibirlo? 🟡

⏱️ **30 segundos** — Un fallo de serialización. La aplicación repite la transacción entera desde el
principio.

🗣️ **2 minutos** — En `l02` salió en `REPEATABLE READ` al escribir una fila que otra transacción
había cambiado. Se reconoce por el código, no por el texto.

🔬 **El detalle** — **Estándar** el código. Sin reintento, subir el aislamiento solo cambia datos
malos por errores.

---

**06 → S12.** ¿Dónde se ven las dos sentencias de un interbloqueo en PostgreSQL? 🟡

⏱️ **30 segundos** — En el registro del servidor: una línea `Process …:` por cada proceso, con su
SQL.

🗣️ **2 minutos** — El cliente solo recibe los números de proceso y de transacción, y la sugerencia
de mirar el registro. En el contenedor, `docker logs bd-lab-postgres`.

🔬 **El detalle** — **Motor.** Con las dos sentencias se encuentran las rutas de código que toman las
filas en orden distinto.

---

**06 → S13.** Distingue `lock_timeout`, `statement_timeout` e `idle_in_transaction_session_timeout`.
🟡

⏱️ **30 segundos** — `lock_timeout` limita la espera de un bloqueo; `statement_timeout`, la duración
de una sentencia; `idle_in_transaction_session_timeout`, lo que una sesión puede estar inactiva con
una transacción abierta.

🗣️ **2 minutos** — Los dos primeros cancelan la sentencia; el tercero cierra la conexión y deshace
la transacción, como se vio en `l02`.

🔬 **El detalle** — **Motor.** Se fijan por rol para la aplicación, con valores distintos para
procesos por lotes.

---

**06 → S14.** ¿Qué diferencia hay entre un respaldo lógico y uno físico, con las cifras del lab? 🟢

⏱️ **30 segundos** — El lógico guarda datos y sentencias: 142 MB en 18,7 s. El físico copia los
ficheros: 1,4 GB en 3 s con `-c fast`.

🗣️ **2 minutos** — Restaurar el lógico reconstruye los índices: 22 s en serie, 15 en paralelo. El
físico, con el WAL, permite volver a cualquier instante.

🔬 **El detalle** — **Motor.** El físico solo se restaura en la misma versión mayor.

---

**06 → S15.** ¿Por qué `pg_basebackup` tardó 216 s y después 3? 🟡

⏱️ **30 segundos** — Porque por defecto pide un *checkpoint* espaciado y lo espera. Con `-c fast`,
el *checkpoint* es inmediato.

🗣️ **2 minutos** — La copia de 1,4 GB era rápida en los dos casos; el resto era esperar. Espaciado
en producción cargada; rápido con prisa.

🔬 **El detalle** — **Motor.** La documentación de `pg_basebackup` declara `spread` como defecto.

---

**06 → S16.** ¿Qué hace falta, además del respaldo base, para recuperar a un instante? 🟡

⏱️ **30 segundos** — Todo el WAL desde el respaldo, continuo, guardado con `pg_receivewal` o
`archive_command`.

🗣️ **2 minutos** — En `l03`, el primer intento falló por un segmento que faltaba: el flujo se había
arrancado después del respaldo. El orden correcto es flujo primero.

🔬 **El detalle** — **Motor.** Y `recovery.signal`, `restore_command` y `recovery_target_time` en el
servidor que se restaura.

---

**06 → S17.** ¿Por qué se restaura al lado del servidor dañado y no encima? 🟠

⏱️ **30 segundos** — Porque el dañado tiene todo lo bueno posterior al accidente. Se restaura al
lado, se comprueba y se copian solo las filas perdidas.

🗣️ **2 minutos** — En `l03`, el restaurado tenía los 273 126 pagos y el original seguía con el
cambio bueno. Encima, se habría perdido ese cambio.

🔬 **El detalle** — **Convención** de operaciones: hace reversible la restauración.

---

**06 → S18.** ¿Qué es una estampida de caché, y cómo se corrigió en el lab? 🟡

⏱️ **30 segundos** — Muchas peticiones encuentran la caché vacía a la vez y van todas a la base. En
`l04`, 50 peticiones fueron 50 consultas; con un candado `SET NX`, una.

🗣️ **2 minutos** — El candado deja que solo uno recargue; los demás esperan el valor. Lleva su
propia caducidad por si quien lo tiene muere.

🔬 **El detalle** — Se combina con caducidades con azar y refresco anticipado.

---

**06 → S19.** ¿Qué cifras de un `explain` de MongoDB delatan que falta un índice? 🟢

⏱️ **30 segundos** — `totalDocsExamined` frente a `nReturned`: en `l04`, 99 999 frente a 7, con
`COLLSCAN`.

🗣️ **2 minutos** — Con el índice, `IXSCAN` y 7 frente a 7.

🔬 **El detalle** — **Motor.** Es la lectura de `Rows Removed by Filter` en PostgreSQL.

---

**06 → S20.** ¿Por qué Cassandra obliga a diseñar una tabla por consulta? 🟡

⏱️ **30 segundos** — Porque solo se puede consultar por la clave de partición, que decide en qué
nodo vive cada fila. Otra consulta necesita otra partición, y por tanto otra tabla.

🗣️ **2 minutos** — En `l05`, buscar por `codigo` en una tabla particionada por cliente dio el error
de `ALLOW FILTERING`.

🔬 **El detalle** — **Motor.** Los datos se duplican a propósito: es el precio de escalar escrituras.

---

**06 → S21.** ¿En qué se diferencia una búsqueda de OpenSearch de un `WHERE`? 🟡

⏱️ **30 segundos** — Un `WHERE` dice si una fila cumple; OpenSearch dice cuánto se parece cada
documento y los ordena.

🗣️ **2 minutos** — En `l05`, los 5 000 productos casaron con «producto», y `PRD-00017` salió primero
con 3,69 frente a 0,00005 del resto.

🔬 **El detalle** — **Motor.** El analizador pasa a minúsculas: `PRODUCTO 17` encontró «Producto 17».

---

**06 → S22.** «Tenemos respaldo diario, así que estamos cubiertos». ¿Qué preguntas harías? 🟠

⏱️ **30 segundos** — ¿Se ha restaurado alguna vez, y cuánto tardó? ¿Hay WAL entre respaldos? ¿Dónde
se guarda, fuera de la máquina?

🗣️ **2 minutos** — Sin WAL, el RPO es de hasta 24 horas. Sin restauración probada, el RTO es
desconocido. Y un respaldo en la misma máquina no sobrevive a perder la máquina.

🔬 **El detalle** — Un respaldo que no se ha restaurado no existe.

---

**06 → S23.** «Para búsqueda por vectores hace falta una base especializada». Refútalo con el lab. 🟠

⏱️ **30 segundos** — pgvector, dentro de PostgreSQL, dio las mismas distancias que Qdrant con los
mismos vectores: 0,1732 y 0,9274.

🗣️ **2 minutos** — Lo que cambia es dónde viven: pgvector, en la misma transacción que los datos;
Qdrant, en otro servicio que hay que sincronizar. A gran escala, la elección depende de los índices
aproximados y de la carga.

🔬 **El detalle** — Dos de los cinco motores del lab eran PostgreSQL con una extensión.

---

**06 → S24.** «Si el índice existe y no se usa, el motor se equivoca». Da tres casos del bloque en
que el motor acertó. 🟠

⏱️ **30 segundos** — El `OR` con un índice en una sola rama; el `LIKE` con un índice de colación
`en_US.utf8`; y el plan genérico que no puede demostrar un índice parcial.

🗣️ **2 minutos** — En los tres, el índice no servía para esa consulta tal como estaba escrita o
preparada. La corrección fue otro índice, otra clase de operadores o el literal en el SQL.

🔬 **El detalle** — **Motor.** Lo que se evalúa es no culpar al planificador antes de mirar el plan.

---

**06 → E1.** Escenario 1 — El entorno que no reproduce

⏱️ **30 segundos** — Primero versiones y datos: la imagen exacta y `verificar.sql`, 22 en `OK`.
Después los parámetros del servidor. Los `rows=` y costes distintos son normales: salen de la
muestra de `ANALYZE`. El `Gather` no lo es: el paralelismo está encendido.

🗣️ **2 minutos** — Orden: `SELECT version()`; `verificar.sql`; `SHOW
max_parallel_workers_per_gather`, que en el corpus es 0 —si arrancó el servidor sin los parámetros
del `compose`, vale el defecto—; el tamaño de `pedidos`, 10 770 páginas. Lo que tiene que coincidir
es la forma del plan y las filas reales.

🔬 **El detalle** — Lo que se evalúa es no dar por malo el corpus antes de descartar el montaje: la
causa más común es un servidor arrancado sin la configuración fijada.

---

**06 → E2.** Escenario 2 — El `DELETE` sin `WHERE` del viernes

⏱️ **30 segundos** — Con un respaldo lógico de las 03:00 y sin WAL, se pueden recuperar los pagos en
efectivo tal como estaban a las 03:00. Lo creado entre las 03:00 y las 18:07 se pierde: es el RPO
real.

🗣️ **2 minutos** — Procedimiento: restaurar el respaldo en otro servidor, con `pg_restore -t pagos`;
extraer los pagos en efectivo; y cargarlos en producción, sin tocar lo demás, que sigue bueno. El
RTO es lo que tarde esa restauración y la copia. El lunes: `pg_receivewal` o `archive_command` antes
de un respaldo base, y una restauración de prueba programada.

🔬 **El detalle** — Lo que se evalúa es no prometer lo que no hay: sin WAL no se vuelve a las 18:06,
y decirlo pronto es parte de la respuesta.

---

**06 → E3.** Escenario 3 — La API que se cuelga a ratos

⏱️ **30 segundos** — Una transacción que el código deja abierta y retiene bloqueos: una sesión `idle
in transaction` que bloquea a las demás. Alternativas: el *pool* de conexiones agotado, o una
llamada externa lenta dentro de la transacción.

🗣️ **2 minutos** — Durante el cuelgue, `pg_stat_activity` con `pg_blocking_pids()`: si hay una
sesión `idle in transaction` con `xact_start` antiguo y otras esperándola, es la primera. Si hay
muchas `idle` y ninguna espera, es el *pool*. Corrección: la transacción alrededor de las
sentencias, nada más. Red: `idle_in_transaction_session_timeout` en minutos para el rol de la
aplicación.

🔬 **El detalle** — Lo que se evalúa es mirar la base antes de reiniciar la API: el reinicio borra la
evidencia.

---

**06 → E4.** Escenario 4 — El pico de cada hora en punto

⏱️ **30 segundos** — Esto no lo resuelve la base de datos. Las consultas idénticas son una estampida
de caché: claves creadas a la vez con una caducidad de una hora, que caducan juntas. Una base más
grande aguanta el pico, pero el pico sigue.

🗣️ **2 minutos** — Correcciones en la caché: azar en la caducidad, para que no caduquen juntas; un
candado por clave, para que solo uno recargue; y refresco anticipado. Las réplicas reparten las
lecturas, pero cada una recibe su parte de la misma estampida.

🔬 **El detalle** — Qué es de cada capa: la caducidad simultánea es de la **caché**; la protección de
la recarga, de la **aplicación**; lo único de la base es que responde bien 59 minutos de cada hora.
Lo que se evalúa es decirlo antes de pedir presupuesto.

---

**Volver:** [README del bloque](README.md) · **Primer lab:** [`l00`](l00-el-entorno-y-los-datos.md).
