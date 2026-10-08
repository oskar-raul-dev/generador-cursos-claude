# 03 — Atomicidad, scripts y durabilidad

> Qué garantiza Redis cuando una operación son varias órdenes, y qué queda de lo confirmado cuando
> el proceso muere. Cuatro herramientas —*pipeline*, `MULTI`, `WATCH` y los scripts de Lua— que se
> parecen y garantizan cosas distintas, con la transacción que **no deshace nada** y el script que
> deja el servidor entero sin atender. Y los dos modos de persistencia, RDB y AOF, con Redis matado
> a mitad de escritura: en uno no se perdió nada; en el otro, 149 498 confirmaciones. **Asume
> leído:** [`02`](02-redis-estructuras-y-ttl.md), las estructuras, y
> [`04/06`](../04-transacciones-y-concurrencia/06-wal-durabilidad-y-fsync.md), el WAL y `fsync`.
> **Vigencia:** 26 de septiembre de 2026.

---

## Salto rápido

- [1. El problema](#1--el-problema) · [2. Pipeline: menos viajes, no
  atomicidad](#2--pipeline-menos-viajes-no-atomicidad)
- [3. MULTI y EXEC](#3--multi-y-exec) · [4. WATCH: el bloqueo
  optimista](#4--watch-el-bloqueo-optimista) · [5. Scripts de Lua](#5--scripts-de-lua)
- [6. Durabilidad: RDB y AOF, con Redis matado](#6--durabilidad-rdb-y-aof-con-redis-matado)
- [7. Estándar, motor y convención](#7--estándar-motor-y-convención) · [Errores
  frecuentes](#️-errores-frecuentes) · [Preguntas](#-preguntas)

---

## 1. 🎯 El problema

El carrito de `CLI-00311` vive en un hash de Redis, como en `02` §3. Añadir un producto son dos
cosas: sumar la cantidad en el carrito y sumar una visita al contador del producto. Dos órdenes. Si
el servicio muere entre la primera y la segunda, o si otra pestaña del mismo cliente cambia el
carrito justo en medio, ¿qué queda?

Y hay una pregunta más grave. En [`01`](01-el-modelo-clave-valor.md) §4, Redis sumaba 28 veces más
rápido que PostgreSQL porque no esperaba al disco en cada orden. Un equipo que usaba Redis solo con
instantáneas midió esto al reiniciarlo tras un corte:

```text
último confirmado: 803890 (ConnectionError)
tras reiniciar:
654392
```

**Ciento cuarenta y nueve mil incrementos que el servidor había confirmado, desaparecidos.** Nadie
recibió un error: cada `INCR` respondió con su número. Este capítulo separa lo que Redis garantiza
de lo que parece garantizar, orden a orden y modo a modo.

> **📝 Contexto.** Todo está corrido contra `bd-lab-redis`, salvo la prueba de solo RDB, que usó un
> Redis desechable con la misma imagen en la red del entorno —`bd-lab-prueba-redis`, borrado al
> terminar—, porque el del corpus lleva AOF. Las sesiones de dos terminales son **dos `redis-cli`
> abiertos a la vez**, registrados en orden de llegada. Redis se mató con `docker kill`, que manda
> `SIGKILL`: muere el proceso, **no la máquina**. Lo que se pierde cuando cae la máquina entera —el
> último segundo del modo por defecto— no se puede producir en este entorno sin arriesgar el disco
> del anfitrión; se explica en §6 y se dice con qué se vería. Toda configuración cambiada se
> devolvió a la del `compose`. **Longitud:** unas 450 líneas; capítulo normal que pasa el disparador
> de 400.

---

## 2. 🧱 Pipeline: menos viajes, no atomicidad

**Qué es:** mandar varias órdenes seguidas sin esperar la respuesta de cada una, y recoger todas
las respuestas al final. El cliente ahorra el viaje de ida y vuelta por orden; el servidor las
ejecuta igual que si llegaran de una en una.

```bash
redis-benchmark -h 127.0.0.1 -q -c 1 -P 16 -n 1000000 INCR vistas:PRD-00017
```

- `-c 1` usa **un solo cliente**, para que la diferencia no venga de la concurrencia, y `-P 16`
  manda las órdenes en grupos de dieciséis. Con `-P 1`, cada orden espera su respuesta.

```text
-P 1:  INCR vistas:PRD-00017: 17725.47 requests per second, p50=0.055 msec
-P 16: INCR vistas:PRD-00017: 222222.22 requests per second, p50=0.063 msec
```

- **Doce veces y media más con el mismo cliente**, y eso sin red de verdad: aquí cliente y servidor
  están en el mismo contenedor. Con 1 ms de ida y vuelta entre máquinas, una orden por viaje no pasa
  de mil por segundo, y la ganancia del *pipeline* se multiplica.
- **No es atómico**: si otra conexión escribe, sus órdenes pueden colarse entre las del grupo. El
  *pipeline* es una optimización de red, no una garantía.

**Quién lo manda:** **protocolo y cliente**; el servidor no distingue un grupo de órdenes sueltas.
**Cuánto:** memoria en el servidor para las respuestas pendientes, y en el cliente para el grupo.
**Cuándo sí:** cargas y lecturas en lote, como el `redis-cli --pipe` de `01` §2. **Cuándo no:**
cuando la segunda orden depende de la respuesta de la primera, que es para lo que están los scripts.

> **Veredicto:** el *pipeline* ahorra viajes y multiplica el rendimiento; no aísla nada de nadie.

---

## 3. 🧱 MULTI y EXEC

**Qué es:** la transacción de Redis. Tras `MULTI`, las órdenes no se ejecutan: se encolan, y `EXEC`
las ejecuta todas seguidas, **sin que ninguna orden de otro cliente se cuele entre ellas**. La
sesión tiene tres partes, y la segunda es la que importa:

```text
127.0.0.1:6379> HSET carrito:CLI-00311 PRD-04454 2 PRD-00082 4
(integer) 2
127.0.0.1:6379> MULTI
OK
127.0.0.1:6379(TX)> HINCRBY carrito:CLI-00311 PRD-00082 1
QUEUED
127.0.0.1:6379(TX)> INCR vistas:PRD-00017
QUEUED
127.0.0.1:6379(TX)> EXEC
1) (integer) 5
2) (integer) 1
127.0.0.1:6379> MULTI
OK
127.0.0.1:6379(TX)> HINCRBY carrito:CLI-00311 PRD-00082 1
QUEUED
127.0.0.1:6379(TX)> INCR carrito:CLI-00311
QUEUED
127.0.0.1:6379(TX)> HGET carrito:CLI-00311 PRD-00082
QUEUED
127.0.0.1:6379(TX)> EXEC
1) (integer) 6
2) (error) WRONGTYPE Operation against a key holding the wrong kind of value
3) "6"
127.0.0.1:6379> MULTI
OK
127.0.0.1:6379(TX)> HINCRBY carrito:CLI-00311 PRD-00082
(error) ERR wrong number of arguments for 'hincrby' command
127.0.0.1:6379(TX)> EXEC
(error) EXECABORT Transaction discarded because of previous errors.
127.0.0.1:6379> HGET carrito:CLI-00311 PRD-00082
"6"
```

- **El prompt cambia a `(TX)`** mientras hay transacción abierta, como el `tienda=*#` de `psql`.
- **El error en ejecución no deshace nada**: el `INCR` sobre el hash falló con `WRONGTYPE`, y el
  `HINCRBY` anterior **se quedó aplicado** —el carrito pasó de 5 a 6— y la orden siguiente también
  corrió. La documentación lo dice sin rodeos: Redis no admite *rollback* de transacciones.
- **El error de sintaxis sí aborta**, porque se detecta al encolar: `EXECABORT` descarta la
  transacción entera, y el carrito sigue en 6.

**Quién lo manda:** **motor**. **Cuánto:** casi nada; las órdenes esperan en una cola del servidor.
El precio está en lo que no da: si la tercera orden falla por un tipo equivocado, las dos primeras
ya están escritas, y deshacerlas es trabajo tuyo.

**Cuándo sí:** agrupar órdenes que no pueden fallar por tipo, para que ningún otro cliente vea un
estado a medias. **Cuándo no:** si esperas el «todo o nada» de PostgreSQL, donde un error dentro de
la transacción la deja abortada entera
([`04/01`](../04-transacciones-y-concurrencia/01-acid-con-precision.md) §3).

> **Veredicto:** `MULTI` garantiza que nadie se cuele entre tus órdenes, no que se deshagan si una
> falla. Es aislamiento sin la A de ACID.

---

## 4. 🧱 WATCH: el bloqueo optimista

`MULTI` aísla la ejecución, pero no la lectura previa. Si A lee el carrito, decide y escribe, B
puede cambiarlo entre la lectura y la escritura de A. **Qué es `WATCH`:** una vigilancia sobre una
o más claves; si alguna cambia antes del `EXEC`, la transacción no se ejecuta. Dos terminales a la
vez:

```text
-- sesión A                                        -- sesión B
127.0.0.1:6379> WATCH carrito:CLI-00311
OK
127.0.0.1:6379> HGET carrito:CLI-00311 PRD-00082
"6"
                                                   127.0.0.1:6379> HINCRBY carrito:CLI-00311 PRD-00082 1
                                                   (integer) 7
127.0.0.1:6379> MULTI
OK
127.0.0.1:6379(TX)> HSET carrito:CLI-00311 PRD-00082 7
QUEUED
127.0.0.1:6379(TX)> EXEC
(nil)
127.0.0.1:6379> HGET carrito:CLI-00311 PRD-00082
"7"
```

- **`EXEC` devuelve `(nil)`**: la transacción de A no se ejecutó, porque B tocó la clave vigilada.
  El 7 que queda es el de B, no el de A. A tiene que volver a leer y reintentar.
- **No bloquea a nadie**: B escribió sin esperar. Es la columna de versión de
  [`04/05`](../04-transacciones-y-concurrencia/05-optimista-pesimista-y-transacciones-largas.md) §3
  con otro mecanismo: comprobar al final en vez de bloquear al principio.

**Quién lo manda:** **motor**; la documentación lo llama *check-and-set*. **Cuánto:** en
**reintentos**; con muchos escritores sobre la misma clave, casi todas las transacciones fallan y se
repiten. **Cuándo sí:** leer, decidir en el cliente y escribir, con poca contienda. **Cuándo no:**
con mucha contienda sobre la misma clave, donde un script hace lo mismo en un solo paso.

> **Veredicto:** `WATCH` convierte «leer y luego escribir» en una operación que falla limpia si
> alguien se adelantó; el reintento lo escribes tú.

---

## 5. 🧱 Scripts de Lua

**Qué es:** un programa en Lua que el servidor ejecuta entero, **sin atender a nadie más mientras
dura**. Es la herramienta cuando la segunda orden depende de la respuesta de la primera. El caso
clásico es liberar un candado solo si es tuyo: el `SET NX` de la estampida de
[`l04`](../13-laboratorio/l04-redis-y-mongodb.md) §3 lo toma, y un `DEL` a secas podría borrar el
candado que otro proceso tomó después de que el tuyo caducara.

```text
127.0.0.1:6379> SET pedido:PED-00042:candado proceso-a NX EX 30
OK
127.0.0.1:6379> EVAL "if redis.call('GET', KEYS[1]) == ARGV[1] then return redis.call('DEL', KEYS[1]) else return 0 end" 1 pedido:PED-00042:candado proceso-b
(integer) 0
127.0.0.1:6379> EVAL "if redis.call('GET', KEYS[1]) == ARGV[1] then return redis.call('DEL', KEYS[1]) else return 0 end" 1 pedido:PED-00042:candado proceso-a
(integer) 1
127.0.0.1:6379> EXISTS pedido:PED-00042:candado
(integer) 0
```

- **`1` es el número de claves** que siguen, que el script lee como `KEYS[1]`; lo demás llega en
  `ARGV`. Declarar las claves aparte es lo que permite a Redis saber qué toca el script.
- **`proceso-b` no puede liberarlo** —devuelve `0`— y `proceso-a` sí. Comprobar y borrar ocurren en
  un solo paso: nadie puede tomar el candado entre las dos cosas.

El precio de «sin atender a nadie más» se ve con un script que no termina. A lo lanza, y B hace
`PING` un segundo después:

```text
-- sesión A                                        -- sesión B
127.0.0.1:6379> EVAL "while true do end" 0
-- ⏸ el script no termina
                                                   127.0.0.1:6379> PING
                                                   -- ⏸ espera: el único hilo está ocupado
                                                   (error) BUSY Redis is busy running a script. You can only call SCRIPT KILL or SHUTDOWN NOSAVE.
                                                   (3.89s)
                                                   127.0.0.1:6379> SCRIPT KILL
                                                   OK
(error) ERR Script killed by user with SCRIPT KILL... script: 694a5fe1ddb97a4c6a1bf299d9537c7d3d0f84e7, on @user_script:1.
(5.00s)
                                                   127.0.0.1:6379> PING
                                                   PONG
```

- **El `PING` de B esperó 3,89 s** —lo imprime el propio `redis-cli`— sin respuesta, y después
  recibió `BUSY`. Redis no contesta a nadie mientras un script corre; al llegar a
  `busy-reply-threshold`, 5 000 ms en este entorno, empieza a responder `BUSY` a todos, pero **sigue
  sin ejecutar sus órdenes**.
- **`SCRIPT KILL` solo funciona si el script no ha escrito nada.** Si ya escribió, la documentación
  dice que matarlo rompería su atomicidad, y la única salida es `SHUTDOWN NOSAVE`: parar el servidor
  sin guardar.

**Quién lo manda:** **motor**. **Cuánto:** en **concurrencia**, todo el servidor durante lo que dure
el script. Un script de 50 ms son 50 ms en que ningún cliente recibe nada. **Cuándo sí:** lógica
corta de varios pasos sobre pocas claves —liberar un candado, un límite de tasa, un «decrementa si
queda»—. **Cuándo no:** recorrer muchas claves o hacer cálculos largos.

> **📝 Contexto.** Muchos ejemplos por internet mandan el script entero con `EVAL` en cada llamada o
> lo cachean con `EVALSHA`. **Esa caché no se persiste**: tras un `docker restart bd-lab-redis`,
> `SCRIPT EXISTS` pasó de `1` a `0` y `EVALSHA` respondió con el error `NOSCRIPT`. Desde Redis 7
> existen las *Functions*, que se cargan con `FUNCTION LOAD`, se guardan en el AOF con los datos y
> se replican; la biblioteca de `04` siguió en `FUNCTION LIST` tras el mismo reinicio. Son la forma
> vigente de tener lógica estable en el servidor.

> **Veredicto:** un script da atomicidad de verdad porque para el mundo mientras corre; por eso
> tiene que ser corto.

---

## 6. 🩺 Durabilidad: RDB y AOF, con Redis matado

Redis vive en memoria y tiene dos formas de dejar rastro en disco:

- **RDB**: una **instantánea** del contenido entero cada cierto tiempo. El entorno la configura con
  `save 60 1000`: si en 60 s hubo al menos 1 000 cambios, se escribe una.
- **AOF** (*append-only file*): un **registro de cada escritura**, que al arrancar se vuelve a
  ejecutar. `appendfsync` decide cada cuánto se fuerza a disco: `always`, en cada orden; `everysec`,
  una vez por segundo, que es lo que usa el entorno; o `no`, cuando el sistema operativo quiera.

La prueba: un programa suma 1 sin parar y guarda el último valor que el servidor le confirmó; a los
pocos segundos, Redis muere con `docker kill`; al reiniciar, se lee el contador.

```python
r = redis.Redis(host=sys.argv[1], port=6379, socket_timeout=2)
r.delete("vistas:PRD-00017")
ultimo = 0
try:
    while True:
        ultimo = r.incr("vistas:PRD-00017")      # la respuesta es la confirmación
except redis.exceptions.ConnectionError as e:
    print(f"último confirmado: {ultimo} ({type(e).__name__})")
```

```bash
docker compose -f 13-laboratorio/entorno/docker-compose.yml --profile lenguajes run --rm -q python python durabilidad.py redis &
docker kill bd-lab-redis
docker start bd-lab-redis
docker exec bd-lab-redis redis-cli GET vistas:PRD-00017
```

- `run --rm -q python` arranca el contenedor de Python del perfil `lenguajes` con `durabilidad.py`,
  de la carpeta `codigo/`, y `&` lo deja corriendo en segundo plano. El argumento es el servidor:
  `redis`, el del corpus, o `bd-lab-prueba-redis`.
- `docker kill` manda `SIGKILL` al proceso de Redis, que no tiene ocasión de guardar nada, y
  `docker start` lo arranca otra vez sobre el mismo volumen.

**Con AOF por segundo**, el modo del entorno:

```text
último confirmado: 56510 (ConnectionError)
$ docker exec bd-lab-redis redis-cli GET vistas:PRD-00017
56510
```

**Con solo RDB**, en el Redis desechable arrancado con `--appendonly no --save "60 1000"`, dejando
sumar 72 s para que haga una instantánea a mitad:

```text
último confirmado: 803890 (ConnectionError)
$ docker exec bd-lab-prueba-redis redis-cli GET vistas:PRD-00017
654392
$ docker logs bd-lab-prueba-redis 2>&1 | grep -iE 'changes in|Background saving|DB saved|Done loading|DB loaded'
1:M 27 Sep 2026 00:34:30.065 * 1000 changes in 60 seconds. Saving...
1:M 27 Sep 2026 00:34:30.066 * Background saving started by pid 38
38:C 27 Sep 2026 00:34:30.069 * DB saved on disk
1:M 27 Sep 2026 00:34:30.166 * Background saving terminated with success
1:M 27 Sep 2026 00:34:53.489 * Done loading RDB, keys loaded: 1, keys expired: 0.
1:M 27 Sep 2026 00:34:53.489 * DB loaded from disk: 0.001 seconds
```

- **Con AOF, cero pérdidas**: 56 510 confirmados y 56 510 recuperados. Otra corrida dio 33 618 y
  33 618. Al arrancar, el registro dice que volvió a ejecutar el fichero incremental del AOF.
- **Con solo RDB, 149 498 confirmaciones perdidas**: todo lo escrito desde la instantánea de las
  00:34:30 hasta el `kill`, veintitrés segundos después. El `INCR` respondía, y la respuesta no
  significaba que el dato fuera a sobrevivir.
- **Por qué el AOF por segundo no perdió nada aquí**: lo que Redis ya escribió en el fichero queda
  en manos del sistema operativo aunque el proceso muera; el `fsync` por segundo solo decide cuándo
  pasa de esa memoria al disco. El segundo que la documentación da por perdible «si hay un
  desastre» es el de **la máquina**: un corte de luz o un fallo del núcleo antes del `fsync`. Eso no
  se observa aquí; se vería apagando de golpe la máquina virtual de Docker durante la escritura, que
  es arriesgar el disco del anfitrión.

Y lo que cuesta cada modo, con dieciséis clientes sumando:

| Persistencia | `INCR` por segundo | Qué se pierde si cae |
|---|---|---|
| Solo RDB (sin AOF) | 124 595 | Todo desde la última instantánea, muera el proceso o la máquina |
| AOF con `appendfsync everysec` | 117 536 | Nada si muere el proceso; hasta un segundo si cae la máquina |
| AOF con `appendfsync always` | 16 086 | Nada confirmado, según la documentación, «muy muy lento, muy seguro» |

- **El AOF por segundo apenas cuesta** frente a no tenerlo: un 6 %. `always` cuesta siete veces, y
  cae al orden de las escrituras durables de PostgreSQL de `01` §4.

**Quién lo manda:** **motor**, y lo decide la configuración: `appendonly`, `appendfsync` y `save`.
**Cuánto:** en **riesgo de pérdida** o en **tiempo**, sin tercera vía; es la misma palanca que
`synchronous_commit` en [`04/06`](../04-transacciones-y-concurrencia/06-wal-durabilidad-y-fsync.md)
§4. **Cuándo sí:** AOF por segundo para casi todo lo que importa; `always` si una sola confirmación
perdida es inaceptable. **Cuándo no:** solo RDB para datos que no puedas regenerar: el ejemplo de
arriba es lo que pasa.

> **Veredicto:** pregunta siempre qué persistencia tiene un Redis antes de guardar en él algo que no
> esté en otro sitio; «responde OK» no significa «sobrevive».

**Teardown del capítulo:** `DEL` de `vistas:PRD-00017` y `carrito:CLI-00311` en `bd-lab-redis`;
`docker rm -f bd-lab-prueba-redis`; y la configuración de vuelta a `appendonly yes` y
`appendfsync everysec`, que un reinicio también restaura porque vienen del `compose`.

---

## 7. 📜 Estándar, motor y convención

> **📜 Estándar o motor.** Ninguna norma define las transacciones ni la persistencia de Redis. Lo
> que se compara con ISO/IEC 9075 es la palabra «transacción», que en los dos lados no significa lo
> mismo.

| Afirmación | Estándar | PostgreSQL 18 | Redis 8.10 |
|---|---|---|---|
| Una transacción es «todo o nada» | Sí, la atomicidad de 9075 | Sí: un error la aborta entera | No: `EXEC` aplica las que no fallan |
| Nadie se cuela entre las órdenes de una transacción | Según el nivel de aislamiento | Según el nivel | Sí, siempre: se ejecutan seguidas |
| Hay control optimista de concurrencia | — | Columna de versión, hecha a mano | `WATCH` |
| Se puede ejecutar lógica en el servidor | Rutinas SQL, 9075-4 | Funciones y procedimientos | Scripts de Lua y *Functions* |
| Una lógica larga en el servidor bloquea a los demás | — | Solo lo que bloquee | Sí: a todos los clientes |
| Una confirmación sobrevive a la muerte del proceso | La D de ACID | Sí | Con AOF sí; con solo RDB, no |
| Una confirmación sobrevive a un corte de la máquina | — | Con `synchronous_commit = on` | Solo con `appendfsync always` |

**Convención, la que más se repite.** *«Redis tiene transacciones»* — tiene `MULTI`, que aísla y no
deshace. Quien la usa pensando en un `BEGIN … COMMIT` escribe código que deja estados a medias el
día que una orden falla por tipo, y no se entera, porque `EXEC` no devolvió error: devolvió una
lista con un error dentro.

---

## ⚠️ Errores frecuentes

| Se dice | Lo preciso |
|---|---|
| "`MULTI` es como `BEGIN`: si algo falla, no se aplica nada" | Un error en ejecución no deshace las demás órdenes; solo el error de sintaxis aborta |
| "El *pipeline* es atómico" | Es una optimización de red; otras conexiones pueden colarse entre sus órdenes |
| "Un script de Lua largo no molesta a nadie" | Bloquea a todos los clientes; tras 5 s responden `BUSY`, pero siguen sin ser atendidos |
| "`SCRIPT KILL` para cualquier script" | Solo uno que no haya escrito; si escribió, queda `SHUTDOWN NOSAVE` |
| "Con AOF por segundo pierdes el último segundo si Redis muere" | Si muere el proceso, no se perdió nada medido; el segundo es el de un corte de la máquina |
| "Con RDB cada 60 s pierdes como mucho un minuto" | Pierdes todo desde la última instantánea, y la instantánea solo se hace si hubo cambios suficientes |
| "`EVALSHA` deja el script guardado en Redis" | La caché de scripts no se persiste; lo que se guarda en el AOF son las *Functions* |

---

## 📚 Para profundizar

- **Documentación** — Redis, «Transactions»: `MULTI`, `EXEC`, `WATCH` y por qué no hay *rollback*.
  <https://redis.io/docs/latest/develop/using-commands/transactions/>
- **Documentación** — Redis, «Pipelining»: el viaje de ida y vuelta y lo que ahorra.
  <https://redis.io/docs/latest/develop/using-commands/pipelining/>
- **Documentación** — Redis, «Scripting with Lua»: atomicidad, `KEYS` y `ARGV`, y la caché volátil.
  <https://redis.io/docs/latest/develop/programmability/eval-intro/>
- **Documentación** — Redis, «SCRIPT KILL»: cuándo se puede matar un script.
  <https://redis.io/docs/latest/commands/script-kill/>
- **Documentación** — Redis, «Redis functions»: la lógica que se persiste con los datos.
  <https://redis.io/docs/latest/develop/programmability/functions-intro/>
- **Documentación** — Redis, «Redis persistence»: RDB, AOF y las tres políticas de `fsync`.
  <https://redis.io/docs/latest/operate/oss_and_stack/management/persistence/>
- **Libro** — Martin Kleppmann, *Designing Data-Intensive Applications*, O'Reilly, 2017, capítulo 7:
  qué significa de verdad cada letra de ACID.

---

## 🧠 Preguntas

1. ¿Qué hace un *pipeline*, y qué no garantiza? 🟢
2. ¿Qué significa el `(TX)` en el prompt de `redis-cli`? 🟢
3. ¿Qué devuelve `EXEC` cuando una clave vigilada con `WATCH` cambió? 🟢
4. ¿Qué es RDB y qué es AOF, en una frase cada uno? 🟢
5. ¿Qué hace el `1` en `EVAL "…" 1 pedido:PED-00042:candado proceso-a`? 🟢
6. Distingue el error de sintaxis del error en ejecución dentro de `MULTI`: qué pasa con cada uno.
   ¿Lo fija el estándar o es cosa del motor? 🟡
7. Distingue *pipeline* de `MULTI`: qué da cada uno. 🟡
8. ¿La transacción de Redis cumple la A de ACID tal como la define el estándar SQL? ¿Y la I? 🟡
9. `WATCH` frente al `SELECT … FOR UPDATE` de PostgreSQL: qué hace cada uno ante un escritor
   concurrente. 🟡
10. ¿Por qué liberar un candado con un `DEL` a secas puede borrar el candado de otro proceso? 🟠
11. ¿Por qué un script de 50 ms es un problema en Redis y una función de 50 ms en PostgreSQL no lo
    es tanto? 🟠
12. Con AOF por segundo, matar Redis no perdió ninguna confirmación. ¿Por qué, y cuándo sí se pierde
    el último segundo? 🟠
13. ¿Qué cuesta pasar de `appendfsync everysec` a `always`, y qué se gana? 🟠
14. ¿Por qué solo RDB perdió 149 498 confirmaciones, si la instantánea es cada 60 s? 🟠
15. ¿Por qué `EVALSHA` puede fallar tras reiniciar Redis, y qué se usa hoy en su lugar? 🟠
16. Escribe el script de Lua que resta una unidad de `stock:PRD-00017` solo si queda alguna, y
    explica por qué no se puede hacer con `MULTI`. 🔴
17. Diagnostica: tras un reinicio de Redis, los contadores de visitas volvieron a valores de hace
    veinte segundos y nadie vio un error. Da la causa más probable, cómo la confirmarías y qué
    cambiarías. 🔴
18. Diseña el añadido de un producto al carrito de `CLI-00311` —cantidad en el hash y visita en el
    contador— para que dos pestañas a la vez no se pisen y un fallo a mitad no deje el carrito a
    medias. Di qué herramienta usas y por qué no las otras. 🔴

---

**Anterior:** [`02`](02-redis-estructuras-y-ttl.md) — estructuras y caducidad · **Siguiente:**
[`04`](04-cache-invalidacion-y-estampida.md) — caché, invalidación y estampida · **Relacionado:**
[`04/06`](../04-transacciones-y-concurrencia/06-wal-durabilidad-y-fsync.md) §4 —
`synchronous_commit`, la misma palanca en PostgreSQL ·
[`04/05`](../04-transacciones-y-concurrencia/05-optimista-pesimista-y-transacciones-largas.md) §3 —
la columna de versión, el `WATCH` de SQL.
