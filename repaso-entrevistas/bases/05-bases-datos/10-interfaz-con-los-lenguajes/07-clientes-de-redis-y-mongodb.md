# 07 — Clientes de Redis y MongoDB

> Los clientes de los dos motores no relacionales del corpus en los cuatro lenguajes: el mismo
> pedido guardado en Redis con caducidad y en MongoDB como documento, y lo que importa de verdad en
> producción, que es **qué hace cada cliente cuando el servidor no está**: fallar en milisegundos,
> esperar treinta segundos o reintentar para siempre. No es el capítulo de los modelos —clave-valor
> y documental tienen sus bloques—: es el de la biblioteca que los usa. **Asume leído:**
> [`01`](01-el-driver-la-conexion-y-el-pool.md) —conexión, *pool* y tiempos de espera, que aquí se
> repiten con otros nombres—. **Vigencia:** 26 de septiembre de 2026.

---

## Salto rápido

- [1. El problema](#1--el-problema) · [2. Qué cambia respecto a un driver
  SQL](#2--qué-cambia-respecto-a-un-driver-sql)
- [3. El mismo pedido, en los cuatro](#3--el-mismo-pedido-en-los-cuatro) · [4. Cuando el servidor no
  está](#4--cuando-el-servidor-no-está)
- [5. Conexión, pool y tiempos por defecto](#5-️-conexión-pool-y-tiempos-por-defecto) · [6. Estándar,
  motor y convención](#6--estándar-motor-y-convención)
- [Errores frecuentes](#️-errores-frecuentes) · [Para profundizar](#-para-profundizar) ·
  [Preguntas](#-preguntas)

---

## 1. 🎯 El problema

La tienda cachea los pedidos en Redis y guarda un histórico en MongoDB. Un martes, el nodo de Redis
se reinicia durante un minuto y el de MongoDB se queda sin red durante otro. Lo que ven los cuatro
servicios, uno por lenguaje, no se parece:

```text
El servicio en Python devuelve error de Redis al instante, y sigue sirviendo sin caché.
El servicio en Node se queda colgado: sus peticiones no fallan ni terminan.
Los cuatro tardan exactamente treinta segundos en cada petición que toca MongoDB.
```

Nada de eso es de Redis ni de MongoDB: es **el comportamiento por defecto de cada cliente**, y se
decide al escribir la línea que lo crea. Es el mismo problema de `01` §5 con el *pool* de SQL, con
otros nombres y con valores por defecto todavía más distintos entre sí.

> **📝 Contexto.** Todo está **corrido** en los contenedores de lenguaje contra `bd-lab-redis` y
> `bd-lab-mongo`, con las bibliotecas de §5 fijadas en §4.6 del dominio. El pedido se guarda con los
> nombres que fija el dominio en §3.1 —la clave `pedido:PED-00042` y la colección `tienda.pedidos`—,
> y **cada programa lo borra al terminar**; los dos motores quedan vacíos. «El servidor no está» se
> provoca apuntando a un puerto donde no escucha nadie, sin parar ningún contenedor. Las salidas
> de MongoDB de §3 se volvieron a correr el 26 de septiembre contra MongoDB 8.0.20 (§4.1 del dominio
> dice por qué esa versión) y salieron idénticas; las de §4 no tocan ningún servidor.

---

## 2. 🧱 Qué cambia respecto a un driver SQL

**Qué es:** un cliente de Redis o de MongoDB hace lo mismo que un driver de `01` —abrir conexiones,
mandar órdenes, convertir respuestas— con tres diferencias que cambian cómo se escribe el código:

| | Driver SQL del corpus | Cliente de Redis | Cliente de MongoDB |
|---|---|---|---|
| Qué se manda | Texto SQL con `$1` | Órdenes con argumentos | Documentos BSON |
| Protocolo | *frontend/backend* de PostgreSQL | RESP de Redis | El protocolo de MongoDB |
| Cuándo conecta | Al pedir la conexión | En la primera orden, casi siempre | **En la primera operación** |
| Especificación común | JDBC, DB-API, `database/sql` | Ninguna | Las especificaciones de drivers de MongoDB |

- **La inyección de [`02`](02-parametrizadas-e-inyeccion.md) no desaparece**: en MongoDB se llama
  inyección de operadores —un `{"$ne": null}` que llega donde se esperaba una cadena— y se evita
  igual, sin construir la consulta con lo que manda el usuario.
- **Casi ningún cliente conecta al crearse**: el `MongoClient` y el `redis.Redis` de §3 no fallan
  aunque el servidor no exista; fallan en la primera operación, que es donde hay que medir.
- **Los drivers oficiales de MongoDB comparten especificación**, y por eso sus valores por defecto
  coinciden entre lenguajes. Los de Redis no tienen ninguna, y cada uno decide.

---

## 3. 🧱 El mismo pedido, en los cuatro

**Qué es:** `PED-00042` guardado en Redis como JSON con **60 s** de caducidad, y en MongoDB como
documento con sus líneas dentro. En Python, entero:

```python
r = redis.Redis.from_url("redis://redis:6379")       # la conexión real se abre con el primer comando
r.set("pedido:PED-00042", json.dumps(pedido), ex=60)  # caduca a los 60 s
print("redis:", r.get("pedido:PED-00042")[:40], "ttl", r.ttl("pedido:PED-00042"))
r.delete("pedido:PED-00042")

m = pymongo.MongoClient("mongodb://root:root@mongo:27017/")   # tampoco conecta aquí
pedidos = m.tienda.pedidos
pedidos.replace_one({"_id": "PED-00042"}, pedido, upsert=True)
print("mongo:", pedidos.find_one({"_id": "PED-00042"}, {"estado": 1, "total": 1}))
pedidos.drop()
```

En los otros tres, las líneas que cambian:

```java
try (var r = RedisClient.create("redis://redis:6379")) {                   // Jedis 8.0.1, trae su pool dentro
    r.set("pedido:PED-00042", pedido.toJson(), new SetParams().ex(60));
```

```typescript
const r = createClient({ url: "redis://redis:6379" });                    // redis 6.2.1
await r.connect();
await r.set("pedido:PED-00042", JSON.stringify(pedido), { EX: 60 });
```

```go
r := redis.NewClient(&redis.Options{Addr: "redis:6379"})                  // go-redis 9.22.0, con pool
r.Set(ctx, "pedido:PED-00042", "{...}", 60*time.Second)
```

Las salidas:

```text
-- Python: redis-py 8.1.0 y pymongo 4.18.2
redis: b'{"_id": "PED-00042", "estado": "PAGADO",' ttl 60
mongo: {'_id': 'PED-00042', 'estado': 'PAGADO', 'total': '3186.23'}
-- Java: Jedis 8.0.1 y mongodb-driver-sync 5.12.0
redis: {"_id": "PED-00042", "estado": "PAGADO", ttl 60
mongo: {"_id": "PED-00042", "estado": "PAGADO", "total": "3186.23"}
-- TypeScript: redis 6.2.1 y mongodb 7.6.0
redis: {"_id":"PED-00042","estado":"PAGADO","to ttl 60
mongo: { _id: 'PED-00042', estado: 'PAGADO', total: '3186.23' }
-- Go: go-redis 9.22.0 y mongo-driver 2.9.1
go-redis PoolSize por defecto: 80
redis: ttl 1m0s
mongo: {"_id":"PED-00042","estado":"PAGADO","total":"3186.23"}
```

- **redis-py devuelve bytes**: `b'{…'`, no una cadena. Por defecto no decodifica, y quien compare el
  resultado con un `str` compara con algo que nunca será igual. Se pide con `decode_responses=True`.
- **El total va como cadena en el documento** a propósito: MongoDB tiene un tipo decimal exacto,
  `Decimal128`, y cada driver lo representa con un tipo propio. Es la trampa del dinero de
  [`03`](03-mapeo-de-tipos.md) §4 con otro motor.
- **`JedisPool` está obsoleto**: el compilador lo avisa con Jedis 8, y la documentación de Redis
  dice que desde la 7.2.0 `RedisClient` sustituye a `JedisPool`, `JedisPooled` y `UnifiedJedis`. Los
  tutoriales que vas a encontrar usan todavía `JedisPool`.

---

## 4. 🩺 Cuando el servidor no está

**Qué es:** el experimento del §1. Los mismos programas, apuntando a un puerto de Redis y a uno de
MongoDB donde no escucha nadie, con **toda la configuración por defecto**:

```text
-- Python
redis falla a los 6 ms: ConnectionError: Error 111 connecting to redis:6390. Connection refused.
mongo falla a los 30283 ms: ServerSelectionTimeoutError: mongo:27090: [Errno 111] Connection refused (configured timeouts: socketTimeoutMS: 20000.0
-- Java
redis falla a los 184 ms: JedisConnectionException: Failed to connect to redis:6390.
mongo falla a los 30080 ms: MongoTimeoutException: Timed out while waiting for a server that matches WritableServerSelector. Client view of c
-- Go (más cuatro avisos del pool: failed to dial after 5 attempts)
go-redis PoolSize por defecto: 80
redis falla a los 1727 ms: dial tcp 172.19.0.3:6390: connect: connection refused
mongo falla a los 30003 ms: server selection error: context deadline exceeded, current topology: { Type: Unknown, Serv
-- TypeScript
redis evento error a los 31 ms: connect ECONNREFUSED 172.19.0.3:6390
redis evento error a los 271 ms: connect ECONNREFUSED 172.19.0.3:6390
redis evento error a los 421 ms: connect ECONNREFUSED 172.19.0.3:6390
redis evento error a los 747 ms: connect ECONNREFUSED 172.19.0.3:6390
redis evento error a los 1225 ms: connect ECONNREFUSED 172.19.0.3:6390
redis evento error a los 2069 ms: connect ECONNREFUSED 172.19.0.3:6390
redis evento error a los 3780 ms: connect ECONNREFUSED 172.19.0.3:6390
redis evento error a los 5848 ms: connect ECONNREFUSED 172.19.0.3:6390
redis evento error a los 7880 ms: connect ECONNREFUSED 172.19.0.3:6390
redis: sigue sin responder a los 8028 ms
```

- **MongoDB tarda 30 s en los cuatro**, con diferencias de milisegundos: es
  `serverSelectionTimeoutMS`, **30 000 ms por defecto** en la especificación común de los drivers.
  Durante esos 30 s, cada petición que toca MongoDB espera, y el servicio acumula peticiones
  colgadas.
- **Redis, en cambio, va de 6 ms a nunca.** redis-py y Jedis fallan enseguida; go-redis reintenta
  cinco veces y falla a los 1,7 s; y **node-redis no falla**: reintenta con esperas crecientes y el
  `connect()` no termina nunca. El programa lo cortó a los 8 s con un vigilante propio.
- **Los mensajes cortados a 90 caracteres son del programa**, no del driver: el de MongoDB sigue con
  la descripción entera de la topología.

La corrección en los dos casos es decir lo que el servicio está dispuesto a esperar. Corrida en
TypeScript, que es donde más se nota:

```typescript
const r = createClient({ url: "redis://redis:6390", socket: { reconnectStrategy: false } });   // sin reintentos
const m = new MongoClient("mongodb://root:root@mongo:27090/?serverSelectionTimeoutMS=2000");   // 2 s en vez de 30
```

```text
redis falla a los 39 ms: connect ECONNREFUSED 172.19.0.3:6390
mongo falla a los 2014 ms: MongoServerSelectionError
```

**Cuánto cuesta cada elección:** esperar poco convierte una caída breve en errores inmediatos, que
el servicio puede tratar —servir sin caché, devolver un 503—; esperar mucho la convierte en
peticiones colgadas que agotan hilos, memoria y el *pool* de SQL de al lado. **Cuándo se reintenta
de verdad:** en segundo plano, para reconectar, nunca con la petición del usuario esperando.

> **Veredicto:** un servicio que usa Redis como caché tiene que poder funcionar sin Redis, y eso
> empieza por un cliente que falle rápido. Treinta segundos de espera por defecto en MongoDB son un
> valor de biblioteca, no una decisión de tu servicio. La estampida que se produce cuando la caché
> caduca bajo carga se corre en §3 de
> [`l04`](../13-laboratorio/l04-redis-y-mongodb.md#3--paso-2--la-estampida).

---

## 5. ⚖️ Conexión, *pool* y tiempos por defecto

**Qué es:** la tabla de `01` §5 para estos clientes. Los valores de redis-py, Jedis y go-redis están
leídos del propio objeto; los de node-redis y MongoDB, de su documentación, y coinciden con §4.

| Cliente | Modelo de conexión | *Pool* por defecto | Espera por defecto |
|---|---|---|---|
| redis-py 8.1.0 | *Pool* dentro de `Redis()` | 100 conexiones | **Ninguna** al conectar ni al leer |
| Jedis 8.0.1 | `RedisClient`, con *pool* dentro | — | 2 s al conectar y 2 s al leer |
| redis 6.2.1 (Node) | Una conexión, multiplexada | No hay *pool* | 5 s al conectar, ninguna al leer, y **reintenta para siempre** |
| go-redis 9.22.0 | *Pool* | 10 × núcleos: **80** aquí | 5 s al conectar y al leer; cinco intentos |
| Drivers de MongoDB | *Pool* por servidor | **100** | **30 s** para elegir servidor |

- **«Ninguna espera» en redis-py** significa que un servidor que acepta la conexión y no contesta
  —colgado por una orden lenta, por ejemplo— deja el hilo esperando para siempre. El caso de §4
  falló rápido porque la conexión se rechazó, que es el caso fácil.
- **node-redis usa una sola conexión** para todas las órdenes, que se ponen en fila por ella; no
  necesita *pool* porque Node no bloquea mientras espera. Mientras está desconectado, además,
  **guarda las órdenes en una cola** para mandarlas al volver: memoria que crece durante la caída.
- **El tamaño del *pool* de go-redis depende de la máquina**, igual que el de `pgxpool` en `01`: 80
  en este portátil de 8 núcleos.

**Quién lo manda:** **biblioteca**, entero; en MongoDB, la especificación común de sus drivers.

> **⚠️ Advertencia.** El tiempo de espera que hay que fijar no es el de conexión, que casi siempre
> falla rápido, sino **el de lectura**: el servidor que acepta y no responde es el que cuelga
> servicios. Jedis y go-redis traen uno por defecto, de 2 y 5 s; **redis-py y node-redis no traen
> ninguno**.

---

## 6. 📜 Estándar, motor y convención

> **📜 Estándar o motor.** ISO/IEC 9075 no aplica: ni Redis ni MongoDB hablan SQL. Lo que se afirma
> es de cada motor, de sus bibliotecas cliente y, en MongoDB, de la especificación común de sus
> drivers.

| Afirmación | Norma | Redis 8.10.1 | MongoDB 8.0.20 | Clientes |
|---|---|---|---|---|
| Hay una interfaz común entre lenguajes | No aplica | No | Sí, la de sus drivers | Mismos valores por defecto en MongoDB |
| El cliente conecta al crearse | — | — | — | Casi ninguno: en la primera operación |
| Espera máxima al elegir servidor | — | — | 30 000 ms | Los cuatro, medidos |
| Qué hace el cliente sin servidor | — | — | — | Falla, reintenta o espera, según el cliente |
| Las respuestas llegan como texto | — | Bytes en el protocolo | BSON | redis-py devuelve bytes salvo que se pida lo contrario |

**Convención, las dos que más se repiten.** *«Si Redis se cae, la aplicación sigue, porque es solo
caché»* — sigue si el cliente falla rápido; con node-redis por defecto, se cuelga. Y *«el cliente de
MongoDB avisa enseguida si el servidor no está»* — espera 30 s antes de avisar, en los cuatro
lenguajes.

---

## ⚠️ Errores frecuentes

| Se dice | Lo preciso |
|---|---|
| "Crear el `MongoClient` comprueba que el servidor existe" | No conecta hasta la primera operación, y esa espera 30 s |
| "`redis-py` devuelve cadenas" | Devuelve bytes, salvo `decode_responses=True` |
| "Si Redis no está, el cliente da error" | node-redis reintenta para siempre y el `connect()` no termina |
| "`JedisPool` es la forma de usar Jedis" | Obsoleto desde la 7.2.0; lo sustituye `RedisClient` |
| "Con un tiempo de conexión corto ya está" | El caso que cuelga es el servidor que acepta y no contesta: hace falta tiempo de lectura, que redis-py y node-redis no traen |
| "El *pool* de go-redis es de 10" | Es de 10 por núcleo: 80 en una máquina de 8 |
| "En MongoDB no hay inyección porque no hay SQL" | Hay inyección de operadores, y se evita igual: sin construir la consulta con la entrada |

---

## 📚 Para profundizar

- **Documentación** — MongoDB, «Connection String Options»: `serverSelectionTimeoutMS`,
  `maxPoolSize` y sus valores por defecto.
  <https://www.mongodb.com/docs/manual/reference/connection-string-options/>
- **Documentación** — MongoDB, «Drivers»: la lista de drivers oficiales.
  <https://www.mongodb.com/docs/drivers/>
- **Documentación** — Redis, «Connect with Jedis»: `RedisClient` y las clases que sustituye.
  <https://redis.io/docs/latest/develop/clients/jedis/connect/>
- **Documentación** — Redis, «redis-py guide»: el cliente de Python y su *pool*.
  <https://redis.io/docs/latest/develop/clients/redis-py/>
- **Documentación** — Redis, «node-redis guide»: conexión, reconexión y cola.
  <https://redis.io/docs/latest/develop/clients/nodejs/>
- **Documentación** — Redis, «go-redis guide». <https://redis.io/docs/latest/develop/clients/go/>

---

## 🧠 Preguntas

1. ¿Cuánto espera por defecto un driver de MongoDB para elegir servidor? 🟢
2. ¿Qué devuelve redis-py al leer una cadena, si no se configura nada? 🟢
3. ¿Qué clase de Jedis sustituye a `JedisPool` desde la 7.2.0? 🟢
4. ¿Cuándo abre su primera conexión un `MongoClient`? 🟢
5. Distingue lo que hacen redis-py y node-redis cuando el servidor de Redis no está. 🟡
6. ¿Por qué los drivers de MongoDB tienen los mismos valores por defecto en todos los lenguajes y
   los de Redis no? ¿Lo fija el estándar o es cosa del motor? 🟡
7. ¿Por qué node-redis no necesita *pool*, y qué guarda en memoria mientras está desconectado? 🟡
8. ¿Hay inyección en MongoDB? Explica cómo se produce y cómo se evita. ¿Lo fija el estándar o es
   cosa del motor? 🟡
9. Un servicio usa Redis como caché y se cuelga cuando Redis se reinicia. Explica el mecanismo en
   Node y la corrección. 🟠
10. Diferencia el tiempo de espera de conexión del de lectura, y di cuál protege de un servidor que
    acepta y no contesta. 🟠
11. ¿Por qué 30 s de selección de servidor en MongoDB pueden agotar el *pool* de SQL de un servicio
    que usa los dos? 🟠
12. ¿Qué cuesta guardar el dinero como `Decimal128` en MongoDB, y qué cuesta guardarlo como cadena?
    🟠
13. El *pool* de go-redis es de 80 conexiones en tu portátil y de 320 en producción. ¿Por qué, y qué
    comprobarías en el servidor de Redis? 🟠
14. Diseña la configuración de los clientes de Redis y MongoDB de un servicio en el lenguaje que
    prefieras, para que una caída de cualquiera de los dos se note en milisegundos. 🔴
15. Diagnostica: cada vez que la red hacia MongoDB falla un minuto, el servicio tarda diez en
    recuperarse del todo. Da tres hipótesis y qué mirarías para cada una. 🔴
16. Escribe, en el lenguaje que prefieras, la lectura de un pedido con Redis como caché de modo que
    una caída de Redis no afecte a la respuesta, solo a su tiempo. 🔴

---

**Anterior:** [`06`](06-python-typescript-y-go.md) — Python, TypeScript y Go · **Siguiente:**
[`08`](08-simulacion-de-entrevista.md) — la simulación del bloque · **Relacionado:**
[`01`](01-el-driver-la-conexion-y-el-pool.md) §5 — el mismo agotamiento con los *pools* de SQL ·
[`03`](03-mapeo-de-tipos.md) §4 — el dinero, que en MongoDB vuelve a ser un problema de tipos.
