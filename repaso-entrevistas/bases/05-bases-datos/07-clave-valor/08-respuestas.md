# 08 — Respuestas

> Solucionario del bloque: el enunciado copiado literalmente de su capítulo y la respuesta en tres
> capas.
>
> **Cómo se usa.** Responde primero en voz alta, con el cronómetro. La capa ⏱️ es lo que dices en
> los primeros treinta segundos; la 🗣️ es lo que añades cuando te dicen "cuéntame más"; la 🔬 es el
> matiz que casi nadie trae, y es donde vive la distinción entre **lo que manda el estándar, lo que
> hace cada motor y lo que es pura convención**.
>
> **Vigencia:** 27 de septiembre de 2026.

---

## Salto rápido

- [Capítulo 01 — El modelo clave-valor](#capítulo-01--el-modelo-clave-valor)
- [Capítulo 02 — Redis: estructuras y caducidad](#capítulo-02--redis-estructuras-y-caducidad)
- [Capítulo 03 — Atomicidad, scripts y durabilidad](#capítulo-03--atomicidad-scripts-y-durabilidad)
- [Capítulo 04 — Caché, invalidación y estampida](#capítulo-04--caché-invalidación-y-estampida)
- [Capítulo 05 — DynamoDB: el modelo y las claves](#capítulo-05--dynamodb-el-modelo-y-las-claves)
- [Capítulo 06 — DynamoDB: diseño desde el acceso](#capítulo-06--dynamodb-diseño-desde-el-acceso)
- [Simulación de entrevista](#simulación-de-entrevista)

---

## Capítulo 01 — El modelo clave-valor

Las 17 preguntas de [`01`](01-el-modelo-clave-valor.md).

**01 → 1.** ¿Qué es un almacén clave-valor, en una frase? 🟢

⏱️ **30 segundos** — Un almacén donde cada dato se guarda bajo una clave única y solo se recupera
por esa clave: sin columnas que filtrar, sin joins y sin planificador.

🗣️ **2 minutos** — Es un diccionario detrás de un puerto de red. A cambio de renunciar a preguntar
por el contenido, el motor no tiene que decidir cómo buscar: la clave dice dónde está el valor. Por
eso sus operaciones son tan predecibles, y por eso cualquier pregunta distinta de «dame esta
clave» la tiene que resolver tu código.

🔬 **El detalle** — **Motor**: no hay estándar de clave-valor. «Clave-valor» dice cómo se pregunta,
no dónde vive el dato: Redis vive en RAM y DynamoDB en disco, y los dos son clave-valor.

---

**01 → 2.** ¿Qué devuelve `TYPE` sobre una clave de Redis, y para qué sirve saberlo? 🟢

⏱️ **30 segundos** — Devuelve el tipo de estructura del valor —`string`, `list`, `hash`, `set`,
`zset` o `stream`—, y sirve porque el tipo decide qué órdenes admite la clave.

🗣️ **2 minutos** — `pedido:PED-00042` dio `string`. Si le mandas una orden de otro tipo, como
`LPUSH`, Redis responde `WRONGTYPE` y no hace nada. Saberlo antes evita ese error y, sobre todo,
evita el error de diseño de guardar como cadena algo que cambia campo a campo.

🔬 **El detalle** — **Motor**. El tipo es de la estructura, no del contenido: dentro de una cadena
puede haber JSON, un número o bytes, y eso Redis no lo mira. Es lo que lo separa de un diccionario
puro y, a la vez, de una columna SQL con dominio.

---

**01 → 3.** ¿Qué significa que `SCAN` devuelva una lista vacía con un cursor distinto de `0`? 🟢

⏱️ **30 segundos** — Que en ese tramo no había ninguna clave que encajara con el patrón, pero el
recorrido no ha terminado: hay que seguir llamando con el cursor devuelto hasta que vuelva `0`.

🗣️ **2 minutos** — En el capítulo, `SCAN 0 MATCH pedido:PED-0004* COUNT 100` devolvió el cursor
`74240` y una lista vacía. `COUNT` es cuánto trabajo hace cada llamada, no cuántos resultados
trae; `MATCH` filtra después de mirar el tramo. Por eso una llamada puede traer cero y la siguiente
diez.

🔬 **El detalle** — **Motor**. La documentación añade dos garantías débiles: un elemento puede salir
más de una vez, y la aplicación tiene que tolerar duplicados. El recorrido completo sí garantiza
devolver las claves que existieron durante todo el recorrido.

---

**01 → 4.** ¿Por qué `INCR` es atómico en Redis sin bloquear nada? 🟢

⏱️ **30 segundos** — Porque Redis ejecuta las órdenes de una en una en un solo hilo: nunca hay dos
`INCR` a medias a la vez, así que no hace falta ningún bloqueo.

🗣️ **2 minutos** — La atomicidad sale de la serialización, no de un mecanismo de bloqueo. Con
dieciséis clientes y dos millones de `INCR`, el contador acabó exactamente en `2000000`. En
PostgreSQL, el mismo contador necesita el bloqueo de fila, y ese bloqueo es el que hace cola.

🔬 **El detalle** — **Motor**, con la configuración del corpus, `io-threads 1`. Aun con hilos de
E/S, la ejecución de órdenes sigue en un solo hilo: lo que se reparte es leer y escribir en la red.

---

**01 → 5.** Distingue `KEYS` de `SCAN`: qué hace cada uno y qué cuesta. 🟡

⏱️ **30 segundos** — `KEYS` devuelve todas las claves que encajan de una vez y bloquea el servidor
mientras recorre; `SCAN` recorre por tramos con un cursor y no bloquea, a cambio de muchas idas y
vueltas.

🗣️ **2 minutos** — Con 99 999 claves, `KEYS` tuvo el servidor 6 062 µs sin atender a nadie; con
diez millones serían segundos. `SCAN` reparte el trabajo en llamadas cortas, pero puede devolver una
clave dos veces y hay que seguir el cursor hasta `0`.

🔬 **El detalle** — **Motor**. La página de `KEYS` dice que es para depuración y operaciones
especiales, no para el código de la aplicación. `redis-cli --scan` es `SCAN` por dentro.

---

**01 → 6.** Distingue `DEL` de `UNLINK`. 🟡

⏱️ **30 segundos** — Los dos borran la clave; `DEL` libera la memoria en el momento, en el hilo
principal, y `UNLINK` la quita del espacio de claves y libera la memoria en otro hilo.

🗣️ **2 minutos** — Con un valor pequeño no se nota. Con un hash o un conjunto de millones de
elementos, `DEL` tiene el servidor parado mientras libera cada uno; `UNLINK` responde enseguida.
Por eso el teardown de `01` §3 usa `--scan` con `UNLINK`.

🔬 **El detalle** — **Motor**. La documentación da a `UNLINK` un coste O(1) por clave en el hilo
principal y el trabajo de liberar, O(N) en asignaciones, en otro hilo.

---

**01 → 7.** ¿Existe un estándar de clave-valor como el de SQL? ¿Qué consecuencia tiene al cambiar
de producto? 🟡

⏱️ **30 segundos** — No: cada producto define su protocolo, sus tipos y sus órdenes. Cambiar de
producto es reescribir el acceso, no cambiar una cadena de conexión.

🗣️ **2 minutos** — Entre Redis y Valkey se comparte el protocolo porque uno viene del otro, pero
entre Redis y DynamoDB no se parece nada: otro modelo de claves, otra API, otra forma de pagar. En
SQL, al menos, el `SELECT` básico es portable y lo no portable está acotado
([`02/08`](../02-sql/08-dialectos.md)).

🔬 **El detalle** — La categoría es siempre **motor**. La consecuencia práctica es encapsular el
acceso detrás de una interfaz propia desde el primer día, porque no hay capa estándar que lo haga
por ti.

---

**01 → 8.** ¿En qué se diferencia el tipo de un valor en Redis del dominio de una columna en SQL?
🟡

⏱️ **30 segundos** — El dominio de una columna restringe el contenido —un `numeric(12,2)` no acepta
letras—; el tipo de Redis dice qué estructura es el valor, y el contenido de una cadena es opaco.

🗣️ **2 minutos** — En PostgreSQL, `pedidos.total` rechaza un texto al insertar. En Redis, dentro de
`pedido:PED-00042` puede haber cualquier cosa; el error solo llega si una orden necesita
interpretarlo, como el `INCR` sobre un JSON de `02` §2. La validación que hacía el esquema la hace
tu código, o nadie.

🔬 **El detalle** — **Estándar** el dominio de columna, en ISO/IEC 9075; **motor** el tipo de
Redis. Es la versión clave-valor de «NoSQL no significa sin esquema: significa que el esquema no lo
valida el motor».

---

**01 → 9.** Redis y Valkey frente a DynamoDB: ¿qué tienen en común y dónde vive el dato en cada
uno? 🟡

⏱️ **30 segundos** — Los tres se preguntan por clave. Redis y Valkey viven en RAM, con disco de
respaldo opcional; DynamoDB vive en disco, gestionado por AWS.

🗣️ **2 minutos** — Valkey parte del código BSD de Redis y habla su mismo protocolo. DynamoDB es otro
producto: además de identificar, la clave reparte los datos entre máquinas, y tiene índices
secundarios. Por eso tiene dos capítulos propios en el bloque.

🔬 **El detalle** — **Motor**, los tres. La licencia también separa: Redis es RSALv2, SSPLv1 o AGPLv3
desde la 8.0; Valkey, BSD con respaldo de la Linux Foundation; DynamoDB es un servicio de pago por
uso.

---

**01 → 10.** Un compañero dice que Redis es más rápido que PostgreSQL. Matiza con números: dónde es
cierto y dónde no. 🟠

⏱️ **30 segundos** — Para leer una fila por su clave, no: van a la par, 0,064 ms en PostgreSQL y
0,047 en Redis, y con dieciséis clientes gana PostgreSQL. Para escribir muchas veces el mismo valor,
sí: 121 080 por segundo frente a 4 373.

🗣️ **2 minutos** — Con dieciséis clientes, PostgreSQL leyó 199 997 veces por segundo y Redis 128
899, porque PostgreSQL reparte en ocho núcleos y Redis ejecuta en un hilo. En la escritura caliente,
el bloqueo de fila y la espera al WAL hunden a PostgreSQL, y Redis no tiene ninguna de las dos.

🔬 **El detalle** — Cifras de un portátil de 8 núcleos, cliente y servidor en el mismo contenedor:
lo que se sostiene en otra máquina es la proporción. Y la ventaja de Redis en escritura se paga en
riesgo de pérdida, que es lo que conviene decir a continuación.

---

**01 → 11.** ¿Por qué dieciséis clientes sumando sobre la misma fila hacen menos escrituras por
segundo que uno solo en PostgreSQL? 🟠

⏱️ **30 segundos** — Porque el bloqueo de fila los pone en cola, y cada uno tiene la fila bloqueada
mientras espera a que su `COMMIT` llegue al disco. Añadir clientes solo añade espera.

🗣️ **2 minutos** — Con uno, 6 421 por segundo; con dieciséis, 4 373 y 3,7 ms de latencia media. La
cola no aporta paralelismo, porque solo uno puede tener la fila, y sí aporta el coste de gestionar
los bloqueos y despertar al siguiente.

🔬 **El detalle** — **Motor**. Es el bloqueo de fila de
[`04/04`](../04-transacciones-y-concurrencia/04-bloqueos-e-interbloqueos.md) §2 sumado a la espera
del WAL de [`04/06`](../04-transacciones-y-concurrencia/06-wal-durabilidad-y-fsync.md) §4. Ni el
estándar SQL ni nadie promete que más clientes den más rendimiento sobre un solo dato.

---

**01 → 12.** ¿Qué parte de la diferencia entre 4 373 y 121 080 escrituras por segundo es el bloqueo
de fila y qué parte es la durabilidad? ¿Cómo lo separaste? 🟠

⏱️ **30 segundos** — Cambiando una sola cosa cada vez: quitar la espera al disco con
`synchronous_commit = off` multiplicó por siete, y repartir las escrituras en filas distintas, otra
vez por siete.

🗣️ **2 minutos** — Sobre la fila caliente: 4 373 con durabilidad y 32 453 sin ella. Repartidas en
5 000 productos: 32 093 con durabilidad y 209 126 sin ella. Las dos causas pesan parecido y se
multiplican, porque la espera al disco se paga con la fila bloqueada.

🔬 **El detalle** — Es el método de separar variables, y funciona porque cada experimento cambia
una sola. Sin la espera ni el bloqueo, PostgreSQL pasa de las 200 000 por segundo: el motor no era
lento, lo eran esas dos garantías.

---

**01 → 13.** ¿Qué cuesta en espacio pasar los pedidos de PostgreSQL a Redis, y por qué esa memoria
es más cara? 🟠

⏱️ **30 segundos** — Unos 216 bytes por pedido en Redis frente a 88 por fila en PostgreSQL, y en RAM
en vez de en disco, que es la memoria más cara y más escasa de la máquina.

🗣️ **2 minutos** — Cargar 99 999 pedidos subió la memoria de Redis de 1,53 a 22,09 MB. El pedido va
como JSON en texto, con los nombres de campo repetidos en cada valor, mientras PostgreSQL guarda
tipos binarios con el esquema aparte. Y todo el conjunto tiene que caber en memoria: no hay «leer
del disco lo que no quepa».

🔬 **El detalle** — `MEMORY USAGE` dio 195 bytes para `PED-00042`, con la clave y la contabilidad
interna. PostgreSQL tiene además 52 MB de índices para el millón, que Redis no necesita porque no
busca por nada que no sea la clave.

---

**01 → 14.** ¿Por qué el cambio de licencia de Redis es una pregunta de arquitectura? 🟠

⏱️ **30 segundos** — Porque decide qué puedes hacer con él: la 7.4 dejó de ser código abierto según
la OSI, y ofrecerlo como servicio a terceros dejó de ser libre. Elegir Redis, Valkey o la AGPLv3 de
la 8.0 cambia lo que puedes construir encima.

🗣️ **2 minutos** — Hasta la 7.2 era BSD-3-Clause. La 7.4 pasó a RSALv2 o SSPLv1. La 8.0 añadió la
AGPLv3, que es de la OSI pero obliga a publicar cambios si se ofrece por red. Valkey nació de ese
cambio y sigue siendo BSD. Un proveedor de nube y una tienda que lo usa internamente llegan a
respuestas distintas.

🔬 **El detalle** — Es de las preguntas que separan a quien conoce el producto de quien conoce el
ecosistema. No es una pregunta legal fina: es saber que existe y a quién hay que consultar.

---

**01 → 15.** Diseña cómo contarías las visitas por producto de una campaña de 10 000 visitas por
segundo sin traer un segundo motor, y di qué pierdes. 🔴

⏱️ **30 segundos** — Sumar en la memoria de cada proceso del servicio y volcar cada segundo con un
solo `UPDATE` por producto que añade la suma acumulada. Pierdo, si el proceso cae, el último
segundo de visitas de ese proceso.

🗣️ **2 minutos** — Diez mil visitas por segundo sobre `PRD-00017` son diez mil escrituras sobre una
fila; con el volcado, son tantas como procesos por segundo. El `UPDATE` suma la cantidad acumulada
dentro de la base, así que dos procesos que vuelcan a la vez no se pisan: se serializan, pero ya son
pocos. La tabla del contador va aparte, para no hinchar `productos` de versiones muertas.

🔬 **El detalle** — Es exactamente lo que Redis pierde con AOF por segundo si cae la máquina, sin
operar un segundo motor. Si el contador no puede perder nada, se escribe cada visita y se paga la
cola; si puede, el lote es la solución más barata. Y hay que decir que el total en tiempo real se
ve con un segundo de retraso.

---

**01 → 16.** Te piden «cuántos pedidos están `PAGADO`» sobre pedidos guardados en Redis como JSON.
Da dos formas de responder, con lo que cuesta cada una, y cuál montarías antes de que te lo pidan.
🔴

⏱️ **30 segundos** — Una, recorrer todas las claves con `SCAN`, leer cada valor y contar en el
cliente: cien mil idas y vueltas. Otra, mantener un conjunto `estado:PAGADO` que se actualiza con
cada cambio de estado. Montaría el conjunto, o mejor, respondería desde PostgreSQL.

🗣️ **2 minutos** — El recorrido no bloquea el servidor pero cuesta una llamada por tramo y un `GET`
por pedido, y el resultado no es una foto: los estados cambian mientras recorres. El conjunto
contesta con `SCARD` en microsegundos, pero lo escribes tú y tiene que cambiar en la misma operación
que el pedido —un `MULTI` o un script—, o se desfasa. Si la pregunta es de informe, la fuente es
PostgreSQL, donde un índice o un `GROUP BY` lo hacen solos y en transacción.

🔬 **El detalle** — `KEYS` no es una tercera forma: con 99 999 claves tuvo el servidor parado 6 ms.
Y es la regla de clave-valor: si el catálogo de preguntas no está cerrado, el modelo no es este.

---

**01 → 17.** Diagnostica: el servicio se queda cinco segundos sin respuesta de Redis una vez al día,
siempre a la misma hora, y la CPU del servidor no sube. Da tres hipótesis en orden de probabilidad y
qué mirarías para cada una. 🔴

⏱️ **30 segundos** — Algo programado a esa hora bloquea el único hilo sin gastar CPU: un respaldo
que satura el disco y hace esperar la escritura del AOF, un proceso hijo para una instantánea que
tarda en crearse, o un trabajo que lanza una orden lenta. Miraría el registro del servidor, `INFO` y
el *slowlog* a esa hora.

🗣️ **2 minutos** — Primero, el disco: si un respaldo del volumen o de la máquina lo satura, el hilo
principal espera al escribir el AOF; `INFO persistence` tiene `aof_delayed_fsync`, que cuenta esas
esperas. Segundo, el *fork* de `BGSAVE` o de la reescritura del AOF, que con mucha memoria detiene
el servidor mientras se copian las tablas de páginas: `latest_fork_usec`, en `INFO stats`. Tercero,
una orden bloqueante de un trabajo nocturno —`KEYS`, un `DEL` de una clave enorme, un script
largo—: el *slowlog* la tendría, aunque gastaría un núcleo de ocho y la CPU total apenas se movería.

🔬 **El detalle** — La pista «a la misma hora» apunta a algo programado, dentro o fuera de Redis.
Para la próxima vez, `CONFIG SET latency-monitor-threshold 100` enciende el monitor de latencia, que
en este entorno está a `0`, apagado, y `LATENCY DOCTOR` lo resume.

---

## Capítulo 02 — Redis: estructuras y caducidad

Las 18 preguntas de [`02`](02-redis-estructuras-y-ttl.md).

**02 → 1.** ¿Qué significa que `OBJECT ENCODING` devuelva `int` para una clave de tipo cadena? 🟢

⏱️ **30 segundos** — Que Redis guarda esa cadena como un entero de máquina, no como texto: el tipo
sigue siendo cadena, y la codificación es cómo la almacena por dentro.

🗣️ **2 minutos** — Pasa cuando el valor es un número, como `vistas:PRD-00017`. Así `INCR` suma sin
convertir de texto a número, y la clave ocupa menos: 35 bytes con su nombre. Si le metes un texto
que no es un número, cambia a otra codificación de cadena.

🔬 **El detalle** — **Motor**. Tipo y codificación son dos cosas: el tipo decide qué órdenes admite;
la codificación, cuánto ocupa y cómo de rápido va. Redis cambia la codificación solo, sin avisar.

---

**02 → 2.** ¿Qué hace `SET … NX`, y para qué patrón sirve? 🟢

⏱️ **30 segundos** — Escribe la clave solo si no existe, y devuelve nulo si ya existía. Sirve para
candados: el primero que lo consigue se queda con él.

🗣️ **2 minutos** — En el capítulo devolvió `(nil)` y el pedido siguió como estaba. Con `EX` en la
misma orden, el candado caduca solo si su dueño muere: es la pieza de la estampida de `l04` §3,
donde un solo proceso de cincuenta va a la base.

🔬 **El detalle** — **Motor**. `SET … NX EX` es atómico; `SETNX` seguido de `EXPIRE` no lo es: si el
proceso muere entre los dos, el candado queda para siempre.

---

**02 → 3.** ¿Qué devuelve `SADD` al añadir un miembro que ya estaba, y por qué importa? 🟢

⏱️ **30 segundos** — Devuelve `0`: no añade nada, porque un conjunto no tiene repetidos. Importa
porque añadir es idempotente y se puede repetir sin miedo.

🗣️ **2 minutos** — `SADD categoria:audio PRD-00017` dio `0`. Un reintento tras un fallo de red no
duplica, y el número devuelto dice cuántos miembros eran nuevos: sirve como «¿era la primera vez?».

🔬 **El detalle** — **Motor**. Es el mismo principio que un `UNIQUE` en SQL, sin el error: el
conjunto absorbe el duplicado en silencio en vez de rechazarlo.

---

**02 → 4.** ¿Qué es un conjunto ordenado, y qué dos estructuras lo sostienen por dentro? 🟢

⏱️ **30 segundos** — Un conjunto donde cada miembro lleva una puntuación y se guarda ordenado por
ella. Por dentro es una *skip list* y una tabla hash a la vez.

🗣️ **2 minutos** — La tabla hash da la puntuación de un miembro en O(1); la *skip list* mantiene el
orden y permite insertar, mover y leer rangos en O(log N). Por eso `ZREVRANGE` da el top 5 de 5 000
productos en microsegundos.

🔬 **El detalle** — **Motor**, según su documentación. Con menos de 128 miembros usa `listpack`,
más compacto; el ranking de 5 000 era `skiplist`.

---

**02 → 5.** ¿Qué significan `TTL -1` y `TTL -2`? 🟢

⏱️ **30 segundos** — `-1`: la clave existe y no caduca. `-2`: la clave no existe.

🗣️ **2 minutos** — Un número positivo son los segundos que le quedan. El `-1` inesperado es la
señal de alarma: una clave que debía caducar y alguien reescribió con `SET` sin `KEEPTTL`.

🔬 **El detalle** — **Motor**. `PTTL` da lo mismo en milisegundos, y `HTTL` lo da por campo de hash,
con `-1` para un campo sin fecha, como `PRD-04454` en el carrito.

---

**02 → 6.** Distingue tipo y codificación en Redis, con el ejemplo del conjunto que pasa de
`listpack` a `hashtable`. ¿Lo fija el estándar o es cosa del motor? 🟡

⏱️ **30 segundos** — El tipo es lo que es el valor —un conjunto— y decide las órdenes. La
codificación es cómo se guarda: `listpack` compacto mientras es pequeño, `hashtable` cuando crece.

🗣️ **2 minutos** — `categoria:audio`, con 428 miembros, era `hashtable` porque pasa de 128, el
umbral de `set-max-listpack-entries`: 13 694 bytes. El carrito, con tres campos, era `listpack` en
82 bytes. Las órdenes son las mismas en las dos codificaciones; cambian la memoria y la velocidad.

🔬 **El detalle** — **Motor**, y configurable. Subir los umbrales ahorra memoria con estructuras
medianas, a costa de operaciones más lentas, porque buscar en un `listpack` es recorrerlo.

---

**02 → 7.** Distingue caducidad de desalojo: quién decide cada uno y cuándo ocurre. ¿Lo fija el
estándar o es cosa del motor? 🟡

⏱️ **30 segundos** — La caducidad la pones tú con `EX` o `EXPIRE`, y la clave se borra al pasar su
fecha. El desalojo lo decide el servidor al llegar a `maxmemory`, según la política, y borra claves
que tú no marcaste.

🗣️ **2 minutos** — La caducidad es previsible: sabes qué y cuándo. El desalojo depende de la memoria
y de la política; con `allkeys-lru`, en el capítulo desaparecieron el ranking, la categoría y el
propio pedido. Con `noeviction` no se borra nada: se rechazan las escrituras.

🔬 **El detalle** — **Motor**. Se cruzan en `volatile-lru`, que solo desaloja claves con caducidad:
la fecha que pusiste marca también qué puede sacrificarse antes.

---

**02 → 8.** ¿Qué diferencia hay entre `INCR` y `SET` respecto a la caducidad de la clave? 🟡

⏱️ **30 segundos** — `INCR` la conserva; `SET` la borra, salvo con `KEEPTTL`.

🗣️ **2 minutos** — En el capítulo, tras `SET … EX 60` e `INCR`, `TTL` seguía en 60; tras un `SET` a
secas, `TTL` era `-1`. Las órdenes que modifican el valor sin reemplazarlo conservan la fecha; las
que lo reemplazan, no.

🔬 **El detalle** — **Motor**; la documentación de `SET` dice que descarta cualquier caducidad
anterior. Es la causa más común de cachés que no expiran.

---

**02 → 9.** Lista frente a conjunto para «los últimos productos vistos»: qué da cada uno y qué
patrón acota la lista. 🟡

⏱️ **30 segundos** — La lista guarda el orden y admite repetidos; el conjunto no repite pero no
guarda orden. La lista se acota con `LPUSH` seguido de `LTRIM`.

🗣️ **2 minutos** — Para «últimos vistos», el orden es lo que importa, así que es lista. Los
repetidos se quitan antes con `LREM`, y `LTRIM 0 9` la deja en diez. Sin `LTRIM`, crece para
siempre.

🔬 **El detalle** — **Motor**. Un conjunto ordenado con la marca de tiempo como puntuación da las dos
cosas —orden y sin repetidos—, a costa de más memoria y de recortar con `ZREMRANGEBYRANK`.

---

**02 → 10.** ¿Tiene PostgreSQL algo equivalente a la caducidad de una clave de Redis? ¿Qué harías
allí para que una sesión desapareciera sola? 🟡

⏱️ **30 segundos** — No: PostgreSQL no borra filas por fecha. Guardaría una columna de expiración,
filtraría por ella al leer y borraría las vencidas con un trabajo periódico.

🗣️ **2 minutos** — Lo que Redis hace solo, allí son tres piezas: la marca, el filtro en cada lectura
—para no ver una sesión vencida que aún no se borró— y el `DELETE` por lotes. Con mucho volumen, el
`DELETE` genera versiones muertas; particionar por fecha y borrar particiones enteras es más barato.

🔬 **El detalle** — **Estándar**: nada en ISO/IEC 9075. **Motor**: PostgreSQL no lo tiene; es de las
cosas que justifican un almacén clave-valor para las sesiones.

---

**02 → 11.** ¿Por qué el carrito va mejor en un hash que en una cadena JSON cuando dos pestañas lo
cambian a la vez? 🟠

⏱️ **30 segundos** — Porque el hash cambia un campo con `HINCRBY`, atómico y sin leer el resto; con
JSON, cada pestaña lee, modifica y reescribe el carrito entero, y la segunda pisa a la primera.

🗣️ **2 minutos** — Es la actualización perdida de
[`04/01`](../04-transacciones-y-concurrencia/01-acid-con-precision.md), fuera de la base. Con JSON
hay que añadir `WATCH` y reintentos, o un script. Con el hash, dos `HINCRBY` sobre el mismo producto
dan la suma correcta, y sobre productos distintos ni se rozan.

🔬 **El detalle** — **Motor**. El hash de tres productos ocupó 82 bytes en `listpack`. El límite:
un hash no anida; si el carrito necesita estructura dentro de cada línea, hay que aplanar o volver
a JSON y aceptar el precio.

---

**02 → 12.** El ranking en Redis tarda 8 µs y el `GROUP BY`, 696 ms. ¿Qué se paga por esa
diferencia, y cuándo elegirías una vista materializada en su lugar? 🟠

⏱️ **30 segundos** — Se paga en que el ranking es una copia que hay que mantener: cada venta hace su
`ZINCRBY` además de su `INSERT`, sin transacción común, y unos 445 KB de RAM. Si el ranking admite
minutos de retraso, elijo una vista materializada.

🗣️ **2 minutos** — Si el servicio cae entre el `INSERT` y el `ZINCRBY`, el ranking se desfasa hasta
que alguien lo recalcule. La vista materializada vive en PostgreSQL, se refresca cada cinco minutos
y no añade un motor que operar. Redis gana cuando el ranking tiene que moverse con cada venta.

🔬 **El detalle** — Los 8 µs son de una corrida; otra dio 26. El `GROUP BY` suma 3,5 millones de
líneas cada vez. La vista es de [`02/07`](../02-sql/07-escritura-upsert-y-vistas.md).

---

**02 → 13.** ¿Por qué el `SETRANGE` que pasa `maxmemory` se ejecuta, y falla la orden siguiente? 🟠

⏱️ **30 segundos** — Porque Redis comprueba el límite cuando llega una orden que añade datos, antes
de ejecutarla; en ese momento aún no se había pasado, así que la dejó entrar, y es la siguiente la
que ya lo encuentra superado.

🗣️ **2 minutos** — El `SETRANGE` estiró el pedido a 300 KB con 100 KB de margen: entró y dejó la
memoria por encima. El `SET` siguiente recibió `OOM` con `noeviction`. Una sola orden grande puede
pasar el límite de largo.

🔬 **El detalle** — **Motor**; la documentación de desalojo lo describe así. Consecuencia práctica:
`maxmemory` no es un techo exacto, y la máquina necesita holgura por encima.

---

**02 → 14.** Un equipo configura `volatile-lru` y aun así recibe `OOM`. ¿Por qué? 🟠

⏱️ **30 segundos** — Porque `volatile-lru` solo desaloja claves con caducidad; si no hay ninguna, o
no bastan, no puede liberar nada y rechaza la escritura como `noeviction`.

🗣️ **2 minutos** — En el capítulo, ninguna clave tenía caducidad y el `SET` falló igual que con
`noeviction`. Pasa en un Redis que mezcla caché, con fecha, y datos, sin ella, cuando la parte con
fecha es pequeña.

🔬 **El detalle** — **Motor**. O se pone caducidad a todo lo desalojable, o se usa `allkeys-lru` y se
acepta que puede irse cualquier clave, o se separan caché y datos en dos instancias.

---

**02 → 15.** ¿Por qué una clave caducada puede seguir ocupando memoria? 🟠

⏱️ **30 segundos** — Porque Redis no la borra en el instante exacto: la borra cuando alguien la
pide, o cuando el muestreo en segundo plano la encuentra.

🗣️ **2 minutos** — La documentación lo llama expiración pasiva y activa. Nadie puede leer una clave
caducada, pero hasta que se borra ocupa. Con millones de claves caducando a la vez, la memoria baja
más despacio de lo que dicen las fechas.

🔬 **El detalle** — **Motor**. El muestreo activo corre en el mismo hilo, así que borrar lo caducado
también compite con las órdenes de los clientes.

---

**02 → 16.** Diseña las estructuras de Redis para el carrito y los últimos vistos de un cliente y
para el ranking de la tienda, con la caducidad de cada una y la política de memoria de la instancia.
🔴

⏱️ **30 segundos** — Carrito en un hash `carrito:CLI-00311`, caducidad de días, renovada en cada
cambio. Últimos vistos en una lista `vistos:CLI-00311`, acotada con `LTRIM` y con caducidad de
semanas. Ranking en un conjunto ordenado `ranking:ventas`, sin caducidad. Instancia con
`noeviction`, porque el carrito no está en otro sitio.

🗣️ **2 minutos** — El carrito es un dato del cliente: desalojarlo es perder una compra, así que la
política no puede desalojar, y la memoria se vigila con alertas. Si el ranking se recalcula desde
PostgreSQL, podría ir en una instancia aparte de caché con `allkeys-lru`. Cada escritura del carrito
repite `EXPIRE`, o usa `KEEPTTL`, para no perder la fecha. Los campos sueltos que deban caducar —una
reserva de stock dentro del carrito— van con `HEXPIRE`.

🔬 **El detalle** — La persistencia de la instancia del carrito tiene que ser AOF, no solo RDB: es la
lección de `03` §6. Y el ranking necesita un recálculo periódico desde PostgreSQL, porque es una
copia sin transacción común.

---

**02 → 17.** Diagnostica: las claves de caché de fichas de producto dejaron de caducar tras un
despliegue y la memoria no para de crecer. Da la causa más probable y cómo la confirmarías. 🔴

⏱️ **30 segundos** — La causa más probable es un `SET` sin `EX` ni `KEEPTTL` en el código nuevo, que
borra la caducidad cada vez que refresca la ficha. Lo confirmo con `TTL` sobre varias claves de
ficha: si dan `-1`, es eso.

🗣️ **2 minutos** — `INFO keyspace` dice cuántas claves tienen caducidad; si ese número cayó tras el
despliegue mientras el total sube, las claves están perdiendo su fecha. Después, en el diff del
despliegue se busca el `SET` de la ficha. La corrección es `SET … EX` o `KEEPTTL`, y un recorrido
con `SCAN` que ponga fecha a las que se quedaron sin ella.

🔬 **El detalle** — Si la instancia tiene `noeviction`, acabará rechazando escrituras; si tiene
`volatile-lru`, también, porque las claves sin fecha no son desalojables. Es la combinación de
`02` §8 y §9.

---

**02 → 18.** Escribe la secuencia de órdenes para registrar una venta de `PRD-00017` en el ranking y
en los últimos vistos de `CLI-00311`, y di qué pasa si el servicio muere a mitad. 🔴

⏱️ **30 segundos** — `ZINCRBY ranking:ventas 1 PRD-00017`, `LREM vistos:CLI-00311 0 PRD-00017`,
`LPUSH vistos:CLI-00311 PRD-00017` y `LTRIM vistos:CLI-00311 0 9`, dentro de `MULTI`/`EXEC`. Si
muere antes del `EXEC`, no se aplica nada; si muere después, todo.

🗣️ **2 minutos** — Sin `MULTI`, morir a mitad dejaría el ranking sumado y los vistos sin tocar. Con
`MULTI`, las cuatro van juntas y nadie ve un estado a medias. Lo que `MULTI` no cubre es la venta en
PostgreSQL: si el `INSERT` se confirma y el servicio muere antes del `EXEC`, el ranking no se suma.

🔬 **El detalle** — `MULTI` tampoco deshace si una orden falla por tipo, como se ve en `03` §3. Para
atar la venta y el ranking hace falta otra cosa: recalcular el ranking desde PostgreSQL cada cierto
tiempo, o escribir el evento en una tabla dentro de la misma transacción y que otro proceso lo
lleve a Redis.

---

## Capítulo 03 — Atomicidad, scripts y durabilidad

Las 18 preguntas de [`03`](03-atomicidad-scripts-y-durabilidad.md).

**03 → 1.** ¿Qué hace un *pipeline*, y qué no garantiza? 🟢

⏱️ **30 segundos** — Manda varias órdenes sin esperar cada respuesta y las recoge al final. No
garantiza atomicidad: otras conexiones pueden colarse entre sus órdenes.

🗣️ **2 minutos** — Con un cliente, `INCR` pasó de 17 725 a 222 222 por segundo con grupos de
dieciséis. Ahorra el viaje de ida y vuelta por orden, que entre máquinas es lo que manda.

🔬 **El detalle** — **Protocolo y cliente**; el servidor no distingue un grupo de órdenes sueltas.

---

**03 → 2.** ¿Qué significa el `(TX)` en el prompt de `redis-cli`? 🟢

⏱️ **30 segundos** — Que hay una transacción abierta con `MULTI`: las órdenes se encolan en vez de
ejecutarse, hasta el `EXEC` o el `DISCARD`.

🗣️ **2 minutos** — Cada orden responde `QUEUED`. Es el equivalente del `tienda=*#` de `psql` dentro
de una transacción.

🔬 **El detalle** — **Cliente**: lo pinta `redis-cli`. Pero al contrario que en `psql`, no existe un
estado abortado como `tienda=!#`: un error en ejecución no invalida la transacción.

---

**03 → 3.** ¿Qué devuelve `EXEC` cuando una clave vigilada con `WATCH` cambió? 🟢

⏱️ **30 segundos** — `(nil)`: la transacción no se ejecuta, y no se aplica ninguna de sus órdenes.

🗣️ **2 minutos** — En el capítulo, B sumó uno al carrito entre el `WATCH` y el `EXEC` de A, y el
`EXEC` de A devolvió `(nil)`. A tiene que volver a leer y reintentar.

🔬 **El detalle** — **Motor**. El `WATCH` se retira tras el `EXEC`, se ejecute o no, así que cada
reintento vuelve a vigilar.

---

**03 → 4.** ¿Qué es RDB y qué es AOF, en una frase cada uno? 🟢

⏱️ **30 segundos** — RDB es una instantánea del contenido entero cada cierto tiempo. AOF es un
registro de cada escritura que se vuelve a ejecutar al arrancar.

🗣️ **2 minutos** — RDB es compacto y arranca rápido, pero pierde todo lo escrito desde la última
instantánea. AOF pierde, como mucho, lo que su política de `fsync` deje en el aire.

🔬 **El detalle** — **Motor**. El entorno usa los dos: `save 60 1000` y AOF con `everysec`.

---

**03 → 5.** ¿Qué hace el `1` en `EVAL "…" 1 pedido:PED-00042:candado proceso-a`? 🟢

⏱️ **30 segundos** — Dice cuántos de los argumentos siguientes son claves: el primero va a
`KEYS[1]` y el resto a `ARGV`.

🗣️ **2 minutos** — Así el script recibe `pedido:PED-00042:candado` como clave y `proceso-a` como
valor. Separarlos permite a Redis saber qué claves toca el script.

🔬 **El detalle** — **Motor**. Declarar las claves no es opcional en la práctica: en un clúster,
Redis enruta el script por ellas, y un script que toca claves no declaradas rompe ese enrutado.

---

**03 → 6.** Distingue el error de sintaxis del error en ejecución dentro de `MULTI`: qué pasa con
cada uno. ¿Lo fija el estándar o es cosa del motor? 🟡

⏱️ **30 segundos** — El de sintaxis se detecta al encolar y aborta toda la transacción con
`EXECABORT`. El de ejecución se descubre en el `EXEC`, y las demás órdenes se aplican igual.

🗣️ **2 minutos** — Un `HINCRBY` sin su tercer argumento dio error al encolar, y `EXEC` descartó
todo. Un `INCR` sobre un hash dio `WRONGTYPE` en el `EXEC`, y el `HINCRBY` anterior quedó aplicado:
el carrito pasó de 5 a 6.

🔬 **El detalle** — **Motor**. La documentación dice que Redis no admite *rollback* por simplicidad y
rendimiento. Deshacer lo aplicado es trabajo del cliente.

---

**03 → 7.** Distingue *pipeline* de `MULTI`: qué da cada uno. 🟡

⏱️ **30 segundos** — El *pipeline* da rendimiento: menos viajes. `MULTI` da aislamiento: nadie se
cuela entre sus órdenes. Ninguno de los dos deshace.

🗣️ **2 minutos** — Se combinan: un `MULTI … EXEC` mandado en *pipeline* es aislado y rápido. Lo que
ninguno permite es que una orden dependa de la respuesta de otra; para eso está el script.

🔬 **El detalle** — **Motor y protocolo**. `MULTI` encola en el servidor; el *pipeline* agrupa en el
cliente.

---

**03 → 8.** ¿La transacción de Redis cumple la A de ACID tal como la define el estándar SQL? ¿Y la
I? 🟡

⏱️ **30 segundos** — La A, no: si una orden falla en ejecución, las demás se aplican. La I, sí, y
más estricta que la mayoría: las órdenes se ejecutan seguidas sin que nadie se cuele.

🗣️ **2 minutos** — El estándar pide que la transacción sea todo o nada. Redis no deshace. Y el
aislamiento sale de ejecutar todo en un hilo: no hay intercalado posible durante el `EXEC`, aunque
sí antes, en la lectura previa, que es lo que cubre `WATCH`.

🔬 **El detalle** — **Estándar** frente a **motor**. Curiosamente, MySQL comparte con Redis que un
error no invalida la transacción; PostgreSQL es el que la deja abortada
([`04/01`](../04-transacciones-y-concurrencia/01-acid-con-precision.md) §8).

---

**03 → 9.** `WATCH` frente al `SELECT … FOR UPDATE` de PostgreSQL: qué hace cada uno ante un
escritor concurrente. 🟡

⏱️ **30 segundos** — `WATCH` no bloquea: deja escribir al otro y hace fallar tu `EXEC`. `FOR UPDATE`
bloquea la fila: el otro escritor espera a que termines.

🗣️ **2 minutos** — Uno es optimista y el otro pesimista. `WATCH` sale barato con poca contienda y
caro con mucha, por los reintentos; `FOR UPDATE` asegura el turno a costa de hacer esperar, y puede
producir interbloqueos.

🔬 **El detalle** — **Motor** los dos. El optimista de PostgreSQL es la columna de versión de
[`04/05`](../04-transacciones-y-concurrencia/05-optimista-pesimista-y-transacciones-largas.md) §3.

---

**03 → 10.** ¿Por qué liberar un candado con un `DEL` a secas puede borrar el candado de otro
proceso? 🟠

⏱️ **30 segundos** — Porque si tu candado caducó mientras trabajabas, otro proceso pudo tomarlo, y
tu `DEL` borra el suyo. Hay que comprobar que sigue siendo tuyo y borrar en un solo paso.

🗣️ **2 minutos** — El candado lleva un valor único por dueño. El script compara ese valor y borra
solo si coincide: en el capítulo, `proceso-b` recibió `0` y `proceso-a` lo liberó. Comprobar con un
`GET` y luego borrar con un `DEL` deja un hueco entre los dos.

🔬 **El detalle** — **Motor**. Aun así, un candado en un solo Redis no es un candado distribuido
seguro: si Redis cae sin haber persistido el candado, otro proceso puede tomarlo. Para exclusión
estricta, un `SELECT … FOR UPDATE` en la base de datos es más honesto.

---

**03 → 11.** ¿Por qué un script de 50 ms es un problema en Redis y una función de 50 ms en
PostgreSQL no lo es tanto? 🟠

⏱️ **30 segundos** — Porque Redis ejecuta en un solo hilo y no atiende a nadie mientras el script
corre: son 50 ms de servicio parado para todos. En PostgreSQL, cada conexión es un proceso y las
demás siguen.

🗣️ **2 minutos** — En el capítulo, un `PING` de otra sesión esperó 3,89 s a que el script llegara a
`busy-reply-threshold` y recibió `BUSY`. En PostgreSQL, una función lenta solo afecta a quien espere
los bloqueos que tome.

🔬 **El detalle** — **Motor**. Por eso los scripts de Redis tienen que ser cortos y tocar pocas
claves, y la lógica larga vive en la aplicación.

---

**03 → 12.** Con AOF por segundo, matar Redis no perdió ninguna confirmación. ¿Por qué, y cuándo sí
se pierde el último segundo? 🟠

⏱️ **30 segundos** — Porque lo que Redis escribió en el AOF ya estaba en manos del sistema
operativo, y eso sobrevive a la muerte del proceso. El último segundo se pierde si cae la máquina
—un corte de luz, un fallo del núcleo— antes del `fsync`.

🗣️ **2 minutos** — Medido dos veces: 56 510 confirmados y 56 510 recuperados, y 33 618 y 33 618.
`everysec` no decide cuándo se escribe en el fichero, sino cada cuánto se fuerza del sistema al
disco. La documentación habla de perder un segundo «si hay un desastre».

🔬 **El detalle** — El caso de la máquina no se reprodujo en el entorno, porque haría falta apagar de
golpe la máquina virtual de Docker. Es el mismo reparto que en PostgreSQL con
`synchronous_commit = off`.

---

**03 → 13.** ¿Qué cuesta pasar de `appendfsync everysec` a `always`, y qué se gana? 🟠

⏱️ **30 segundos** — Cuesta siete veces el rendimiento de escritura: de 117 536 a 16 086 `INCR` por
segundo con dieciséis clientes. Se gana que ninguna confirmación se pierda ni aunque caiga la
máquina.

🗣️ **2 minutos** — Con `always`, cada grupo de órdenes espera su `fsync` antes de responder, igual
que el `COMMIT` de PostgreSQL con `synchronous_commit = on`. Y el rendimiento queda en el orden del
de las escrituras durables de PostgreSQL.

🔬 **El detalle** — **Motor**; la documentación lo resume en «muy muy lento, muy seguro». Sin AOF,
124 595: el AOF por segundo cuesta un 6 %, y es casi siempre el punto de equilibrio.

---

**03 → 14.** ¿Por qué solo RDB perdió 149 498 confirmaciones, si la instantánea es cada 60 s? 🟠

⏱️ **30 segundos** — Porque perdió todo lo escrito desde la última instantánea, que fue veintitrés
segundos antes del `kill`, y a ese ritmo eso son casi ciento cincuenta mil incrementos.

🗣️ **2 minutos** — `save 60 1000` no es «cada 60 s»: es «si en 60 s hubo al menos 1 000 cambios».
Con poco tráfico, pueden pasar horas sin instantánea, y la pérdida es aún mayor. Último confirmado
803 890, recuperado 654 392.

🔬 **El detalle** — **Motor**. El `INCR` respondía con su número cada vez; la respuesta confirmaba la
escritura en memoria, no su supervivencia.

---

**03 → 15.** ¿Por qué `EVALSHA` puede fallar tras reiniciar Redis, y qué se usa hoy en su lugar? 🟠

⏱️ **30 segundos** — Porque la caché de scripts no se persiste: tras un reinicio, el hash que
guardabas ya no existe y `EVALSHA` falla. Hoy se usan las *Functions*, que se guardan en el AOF y se
replican.

🗣️ **2 minutos** — Con `EVALSHA`, el cliente tiene que estar preparado para reenviar el script con
`EVAL` cuando el servidor no lo conoce. Las *Functions*, desde Redis 7, se cargan una vez con
`FUNCTION LOAD` y forman parte de la base.

🔬 **El detalle** — **Motor**, y comprobado: tras un `docker restart`, `SCRIPT EXISTS` pasó de `1` a
`0`, `EVALSHA` respondió `NOSCRIPT` y la biblioteca de *Functions* seguía cargada. Muchos ejemplos
por internet siguen usando `EVALSHA` sin reintento.

---

**03 → 16.** Escribe el script de Lua que resta una unidad de `stock:PRD-00017` solo si queda
alguna, y explica por qué no se puede hacer con `MULTI`. 🔴

⏱️ **30 segundos** — Leer el stock, comprobar que queda y restar, los tres pasos dentro del script.
Con `MULTI` no se puede porque la condición depende del valor leído, y dentro de `MULTI` no ves los
resultados hasta el `EXEC`.

```lua
local n = tonumber(redis.call('GET', KEYS[1]) or '0')
if n > 0 then return redis.call('DECR', KEYS[1]) else return -1 end
```

🗣️ **2 minutos** — Corrido con el stock a 1: la primera llamada devolvió `0`, lo que quedaba; la
segunda, `-1`, sin bajar de cero; y `GET` dio `"0"`. Con `MULTI` solo podrías encolar el `DECR` a
ciegas; con `WATCH` podrías leer, decidir y reintentar, a costa de reintentos con contienda.

🔬 **El detalle** — **Motor**. Se llama con `EVAL "…" 1 stock:PRD-00017`. Y el `or '0'` cubre la
clave inexistente, que `GET` devuelve como nulo.

---

**03 → 17.** Diagnostica: tras un reinicio de Redis, los contadores de visitas volvieron a valores
de hace veinte segundos y nadie vio un error. Da la causa más probable, cómo la confirmarías y qué
cambiarías. 🔴

⏱️ **30 segundos** — Redis sin AOF, solo con instantáneas: al reiniciar cargó la última, de hace
veinte segundos. Lo confirmo con `CONFIG GET appendonly` y el registro de arranque. Cambiaría a AOF
con `everysec`.

🗣️ **2 minutos** — El registro dice de dónde cargó: `DB loaded from disk` es RDB; con AOF diría que
cargó el fichero del AOF. `INFO persistence` enseña `aof_enabled` y la hora de la última
instantánea. Con AOF por segundo, matar el proceso no perdió nada en las pruebas.

🔬 **El detalle** — Si el reinicio fue un corte de la máquina y ya había AOF por segundo, se habría
perdido como mucho un segundo, no veinte: veinte segundos apuntan a RDB.

---

**03 → 18.** Diseña el añadido de un producto al carrito de `CLI-00311` —cantidad en el hash y
visita en el contador— para que dos pestañas a la vez no se pisen y un fallo a mitad no deje el
carrito a medias. Di qué herramienta usas y por qué no las otras. 🔴

⏱️ **30 segundos** — `MULTI` con `HINCRBY carrito:CLI-00311 PRD-00017 1` e `INCR vistas:PRD-00017`,
y `EXEC`. `HINCRBY` ya evita que las pestañas se pisen, y `MULTI` hace que las dos órdenes vayan
juntas.

🗣️ **2 minutos** — No hace falta `WATCH`, porque no hay lectura previa de la que dependa la
escritura: `HINCRBY` suma sobre lo que haya. No hace falta script, porque ninguna orden depende de
otra. El *pipeline* solo no bastaría, porque no aísla.

🔬 **El detalle** — `MULTI` no deshace un error por tipo, así que las claves tienen que ser del tipo
esperado siempre. Si hubiera que comprobar stock antes de añadir, entonces sí: un script.

---

## Capítulo 04 — Caché, invalidación y estampida

Las 17 preguntas de [`04`](04-cache-invalidacion-y-estampida.md).

**04 → 1.** ¿Qué es *cache-aside*, en una frase? 🟢

⏱️ **30 segundos** — La aplicación mira primero en la caché; si no está, lee de la base, guarda el
resultado en la caché con caducidad y lo devuelve.

🗣️ **2 minutos** — La caché no sabe nada de la base: la rellena la aplicación al fallar, y la vacía
la aplicación al escribir, o la caducidad. Es el patrón más común porque solo pide un `GET` y un
`SET`, y sus dos defectos conocidos son la carrera de §3 y la estampida de §4.

🔬 **El detalle** — **Convención**: el nombre y el patrón son de arquitectura, no de Redis ni de
ninguna norma.

---

**04 → 2.** ¿Qué es una estampida de caché? 🟢

⏱️ **30 segundos** — Cuando una clave muy leída caduca, todas las peticiones que llegan en ese
instante fallan a la vez y van todas a la base a regenerar el mismo valor.

🗣️ **2 minutos** — En `l04` §3, cincuenta hilos a la vez hicieron cincuenta consultas idénticas a
PostgreSQL; con un candado `SET NX`, una. Con miles de peticiones por segundo y una consulta cara,
la caducidad de una clave puede tumbar la base justo cuando la caché deja de protegerla.

🔬 **El detalle** — **Convención** el nombre. La variante de muchas claves distintas que caducan
juntas es otro problema, con otra solución: la caducidad al azar.

---

**04 → 3.** ¿Qué es la lista de pendientes de un grupo de consumidores de un *stream*? 🟢

⏱️ **30 segundos** — La lista de mensajes entregados a algún consumidor del grupo que aún no se han
confirmado con `XACK`, cada uno a nombre de su consumidor.

🗣️ **2 minutos** — Es la PEL, *Pending Entries List*. `XPENDING` la enseña: en el capítulo, un
mensaje a nombre de `w1`, entregado una vez. `XAUTOCLAIM` pasa a otro consumidor los que llevan un
tiempo sin actividad, que es como se recupera lo que dejó un consumidor caído.

🔬 **El detalle** — **Motor**. Es lo que hace fiable la cola: el mensaje no se olvida al entregarse,
sino al confirmarse.

---

**04 → 4.** Distingue *cache-aside* de *write-through*: quién escribe en la caché y cuándo. ¿Qué
parte es del motor y qué parte es convención? 🟡

⏱️ **30 segundos** — En *cache-aside*, la caché se rellena al leer, cuando la aplicación falla en
ella. En *write-through*, se escribe al escribir: la aplicación actualiza la base y la caché en la
misma operación.

🗣️ **2 minutos** — *Write-through* evita el primer fallo tras un cambio, pero tiene su propia
carrera: dos escritores pueden actualizar la base en un orden y la caché en el contrario. Y llena la
caché de valores que quizá nadie lea.

🔬 **El detalle** — **Convención** los dos. Redis no implementa ninguno: es el código el que decide
cuándo escribir en él.

---

**04 → 5.** Distingue una sesión guardada en Redis de una entrada de caché, y di por qué importa
para la política de memoria. 🟡

⏱️ **30 segundos** — Una entrada de caché es una copia que se puede regenerar desde la base; una
sesión es un dato que solo está en Redis. Si se desaloja una caché, se recalcula; si se desaloja una
sesión, se echa al usuario.

🗣️ **2 minutos** — Por eso la política no puede ser la misma: una instancia solo de caché admite
`allkeys-lru`; una con sesiones necesita `noeviction` y alertas de memoria. Mezclarlas en una
instancia obliga a elegir entre perder sesiones o dejar de aceptar escrituras de caché.

🔬 **El detalle** — **Motor** la política, de `02` §9. La práctica común es separar instancias por
tipo de dato, no por servicio.

---

**04 → 6.** ¿Implementa Redis algún patrón de caché, o es convención de la aplicación? ¿Y PostgreSQL
avisa de algún cambio a la caché? 🟡

⏱️ **30 segundos** — Ninguno: Redis es un almacén, y el patrón lo escribe la aplicación. Y
PostgreSQL no avisa a nadie de que una fila cambió: no sabe que existe una copia.

🗣️ **2 minutos** — Todo lo que mantiene la caché al día es código tuyo: el borrado tras escribir, la
caducidad, la versión. Si quieres que un cambio en la base llegue solo a la caché, hace falta algo
que lea los cambios de la base y los propague, y eso es otra pieza que operar.

🔬 **El detalle** — **Convención** los patrones; **motor** que ninguno de los dos lo haga por
defecto. PostgreSQL tiene `LISTEN/NOTIFY` y la replicación lógica como piezas para construirlo, pero
ninguna de las dos es una caché.

---

**04 → 7.** Distingue una cola hecha con `BRPOP` de una hecha con un grupo de consumidores de un
*stream*: qué pasa si el consumidor cae. 🟡

⏱️ **30 segundos** — Con `BRPOP`, el mensaje sale de la lista al entregarse; si el consumidor cae,
se pierde. Con un grupo, el mensaje queda pendiente a nombre del consumidor hasta que lo confirma,
y otro puede reclamarlo.

🗣️ **2 minutos** — `BLMOVE` arregla la lista moviendo el mensaje a una segunda lista «en proceso»,
pero recuperar lo abandonado es código tuyo. El *stream* ya trae `XPENDING` y `XAUTOCLAIM`: en el
capítulo, `w2` reclamó el mensaje de `w1` tras un segundo sin actividad.

🔬 **El detalle** — **Motor**. El precio del *stream*: guarda los mensajes hasta que se recorten, así
que hay que recortarlo con `MAXLEN` o crece sin fin.

---

**04 → 8.** Distingue la ventana fija de la ventana deslizante en la limitación de tasa. 🟡

⏱️ **30 segundos** — La fija cuenta peticiones por tramos de tiempo que empiezan y acaban; la
deslizante cuenta las del último minuto contado desde ahora. La fija deja pasar el doble en el borde
entre dos tramos.

🗣️ **2 minutos** — Con un límite de cinco, cinco en el último segundo de una ventana y cinco en el
primero de la siguiente son diez en dos segundos. La deslizante guarda cada petición en un conjunto
ordenado con su marca de tiempo y cuenta las recientes, así que no tiene borde.

🔬 **El detalle** — **Convención** los dos algoritmos. La fija es un contador por cliente; la
deslizante, una entrada por petición: su precio es memoria.

---

**04 → 9.** En la sesión de §3, ¿por qué el `DEL` del servicio B devolvió `0`, y por qué eso es la
clave de la carrera? 🟠

⏱️ **30 segundos** — Porque cuando B borró, A aún no había escrito en la caché: no había nada que
borrar. Y A escribió después el valor que había leído antes del cambio.

🗣️ **2 minutos** — El orden fue: A falla y lee `PAGADO`; B actualiza a `ENVIADO` y borra; A escribe
`PAGADO` con 300 s. El borrado de B llegó en el hueco entre la lectura y la escritura de A. Nadie
volverá a borrar, porque B ya hizo lo que el manual dice.

🔬 **El detalle** — Ese `0` es la huella de la carrera: un borrado que no borra nada en una clave
que acaba de cambiar merece sospecha. La ventana es de milisegundos y aparece con volumen.

---

**04 → 10.** De las tres formas de acotar la carrera de *cache-aside*, ¿cuál la cierra de verdad y
qué necesita la fila para que funcione? 🟠

⏱️ **30 segundos** — Escribir en la caché solo si el valor es más nuevo que el que hay, con un
script que compare versiones. Necesita que la fila tenga una versión fiable, que crezca con cada
cambio.

🗣️ **2 minutos** — La caducidad solo acota cuánto dura el daño, y el doble borrado estrecha la
ventana sin cerrarla. Con la versión, el `SET` de A con la versión vieja no pisa el valor nuevo, y
si la clave no existe, cualquier versión vale. Es la columna de versión de `04/05` §3.

🔬 **El detalle** — La versión tiene que venir de la base, en la misma lectura; un reloj de la
aplicación no sirve, porque dos máquinas no comparten reloj exacto.

---

**04 → 11.** ¿Por qué una caducidad al azar no ayuda con una sola clave caliente, y un candado no
ayuda con mil claves que caducan juntas? 🟠

⏱️ **30 segundos** — Porque el azar reparte cuándo caducan claves distintas, y con una sola clave no
hay nada que repartir. Y el candado evita que muchas peticiones regeneren la misma clave, pero mil
claves distintas son mil candados y mil regeneraciones igual.

🗣️ **2 minutos** — Medido: con `EX 10` fijo, las mil claves desaparecieron en el mismo segundo; con
azar entre 7 y 13, el vaciado se repartió en seis segundos. Para una clave caliente sirven el
candado, el recálculo externo o la expiración anticipada probabilística.

🔬 **El detalle** — Son dos problemas: concurrencia sobre una clave, y sincronización de muchas. Se
combinan sin conflicto: caducidad con azar y candado a la vez.

---

**04 → 12.** ¿Por qué la limitación de tasa pone la caducidad solo cuando el contador vale 1, y qué
pasa si `INCR` y `EXPIRE` van en órdenes separadas? 🟠

⏱️ **30 segundos** — Porque la ventana empieza con la primera petición y no debe alargarse con cada
una. Y en órdenes separadas, si el proceso muere entre las dos, el contador queda sin caducidad y el
cliente bloqueado para siempre.

🗣️ **2 minutos** — Poner `EXPIRE` en cada llamada movería el final de la ventana y un cliente activo
nunca se desbloquearía. La *Function* del capítulo suma y pone la fecha en un solo paso atómico: la
sexta llamada dio `6` y `TTL` seguía en 60.

🔬 **El detalle** — **Motor**. `EXPIRE … NX` pone la caducidad solo si no tenía, y es otra forma
de lo mismo, pero sigue siendo una segunda orden: el paso atómico sigue haciendo falta.

---

**04 → 13.** Un grupo de consumidores entrega «al menos una vez». ¿Qué obliga eso a hacer al
consumidor, con un ejemplo de la tienda? 🟠

⏱️ **30 segundos** — A ser idempotente: procesar dos veces el mismo mensaje tiene que dejar el mismo
resultado que una. Por ejemplo, antes de facturar `PED-00042`, comprobar si ya tiene factura.

🗣️ **2 minutos** — Si el consumidor termina el trabajo y muere antes del `XACK`, otro lo reclamará y
lo repetirá. La forma más sólida es una restricción de unicidad en la base —una factura por
pedido— que convierte el segundo intento en un error inofensivo.

🔬 **El detalle** — No hay entrega «exactamente una vez» entre dos sistemas sin coordinación; lo que
existe es «al menos una vez» más un consumidor idempotente.

---

**04 → 14.** ¿Cuándo pondrías la cola de trabajo en PostgreSQL con `SKIP LOCKED` en vez de en
Redis? 🟠

⏱️ **30 segundos** — Cuando el trabajo nace de una transacción en PostgreSQL: la tarea se inserta en
la misma transacción que el cambio, y ninguna se pierde ni se crea de más.

🗣️ **2 minutos** — Con Redis, el cambio en la base y el mensaje en la cola van a dos motores sin
transacción común: si el servicio cae entre los dos, o se pierde la tarea o se crea para un cambio
que no se confirmó. `FOR UPDATE SKIP LOCKED` reparte las filas entre consumidores sin que se pisen.

🔬 **El detalle** — Redis gana con volúmenes muy altos o cuando el trabajo no toca la base. Es el
patrón de bandeja de salida de `04/07`, con la tabla de eventos como cola.

---

**04 → 15.** Diagnostica: un proceso precarga la caché de las fichas de producto cada día a las
9:00, y cada día a las 9:10 la base recibe un pico de consultas de fichas. Da la causa más probable,
cómo la confirmarías y la corrección. 🔴

⏱️ **30 segundos** — La precarga pone a todas las fichas la misma caducidad de diez minutos, así que
caducan todas a las 9:10 y todas las lecturas fallan a la vez. La corrección es una caducidad con
azar.

🗣️ **2 minutos** — Lo confirmo con `TTL` sobre varias fichas justo tras la precarga: todas darán el
mismo valor. Y el contador `expired_keys` de `INFO stats` dará un salto a las 9:10. Con caducidad al
azar —diez minutos más o menos dos—, el vaciado se reparte, como en la medición del capítulo.

🔬 **El detalle** — Si además alguna ficha es muy leída, cada una necesita su candado o su
expiración anticipada: el azar reparte las mil claves, pero no protege a la más caliente.

---

**04 → 16.** Diseña la caché de la ficha de `PED-00042` para que un cambio de estado nunca quede
tapado por una lectura concurrente: qué guardas, qué script usas y qué pasa con la caducidad. 🔴

⏱️ **30 segundos** — Guardo el valor junto con la versión de la fila, y escribo en la caché con un
script que solo reemplaza si la versión nueva es mayor que la guardada. La caducidad se mantiene,
corta, como red de seguridad.

🗣️ **2 minutos** — La lectura trae de PostgreSQL el estado y la versión en la misma consulta. El
escritor, tras confirmar, escribe el valor nuevo con su versión mediante el mismo script, en vez de
borrar. Así, el `SET` de un lector lento con la versión vieja no pisa nada. El script compara y
escribe en un solo paso, como el del candado de `03` §5.

🔬 **El detalle** — Hace falta una versión fiable en la fila, que el esquema de `pedidos` no trae:
es la columna de `04/05` §3. La caducidad sigue siendo útil por si un escritor muere antes de
actualizar la caché.

---

**04 → 17.** Diseña la limitación de tasa de la API de pedidos a 100 peticiones por minuto y
cliente, compartida entre diez instancias del servicio, y di qué pasa en el borde de la ventana y
qué harías si Redis no responde. 🔴

⏱️ **30 segundos** — Un contador por cliente y minuto en Redis, `limite:CLI-00311`, incrementado con
una *Function* que pone la caducidad de 60 s en la primera llamada. El servicio rechaza con 429 al
pasar de 100. En el borde de la ventana pueden pasar hasta 200 en dos segundos.

🗣️ **2 minutos** — Redis es el único sitio compartido por las diez instancias, y por eso va ahí. Si
el borde importa, ventana deslizante con un conjunto ordenado. Si Redis no responde, lo sensato es
dejar pasar las peticiones con un tiempo de espera corto —fallar abierto— y registrarlo, porque un
limitador no debe tumbar la API.

🔬 **El detalle** — Fallar abierto o cerrado es una decisión de negocio: para una API pública con
riesgo de abuso puede preferirse cerrado. El tiempo de espera del cliente de Redis tiene que ser
corto, por lo que se vio en `10/07` §4.

---

## Capítulo 05 — DynamoDB: el modelo y las claves

Las 18 preguntas de [`05`](05-dynamodb-modelo-y-claves.md).

**05 → 1.** ¿Qué son la clave de partición y la clave de orden de una tabla de DynamoDB? 🟢

⏱️ **30 segundos** — La de partición decide, con un hash, en qué partición física vive el elemento;
la de orden, el orden de los elementos dentro de esa partición. Juntas forman la clave primaria.

🗣️ **2 minutos** — En la tabla de pedidos, `cliente` es la partición y `fecha_pedido` el orden: los
pedidos de un cliente viven juntos y ordenados por fecha. Por eso «los pedidos de 2025 de
`CLI-00311`» es una consulta barata.

🔬 **El detalle** — **Motor**. La clave de orden es opcional; sin ella, la clave es simple y cada
valor de partición identifica un solo elemento.

---

**05 → 2.** ¿Qué es una unidad de lectura y una de escritura en DynamoDB? 🟢

⏱️ **30 segundos** — Una unidad de lectura es una lectura fuerte por segundo de hasta 4 KB, o dos
eventuales; una de escritura, una escritura por segundo de hasta 1 KB.

🗣️ **2 minutos** — Los tamaños se redondean hacia arriba: leer 5 KB fuerte son dos unidades. Con
modo aprovisionado reservas unidades por segundo; bajo demanda, pagas cada petición por las
unidades que consume.

🔬 **El detalle** — **Motor**, según la documentación de AWS. Es la moneda con que DynamoDB cobra, y
por eso cada decisión de modelo es también una decisión de factura.

---

**05 → 3.** ¿Qué devuelve `LastEvaluatedKey` en una `query`, y para qué sirve? 🟢

⏱️ **30 segundos** — La clave del último elemento leído cuando la respuesta se cortó; se pasa en la
siguiente llamada como `--exclusive-start-key` para seguir desde ahí.

🗣️ **2 minutos** — Es la paginación de DynamoDB. Aparece cuando la respuesta llega al `--limit` o a
1 MB. En el capítulo, con `--limit 3`, apuntaba a `2025-07-07T11:33:41Z#PED-352201`. Sin
`LastEvaluatedKey`, no queda nada más.

🔬 **El detalle** — **Motor**. Es paginación por clave, no por número de página: no se puede saltar
a la página diez sin pasar por las nueve anteriores.

---

**05 → 4.** ¿Qué diferencia hay entre `Count` y `ScannedCount`? 🟢

⏱️ **30 segundos** — `ScannedCount` son los elementos leídos; `Count`, los que quedan tras el
filtro y se devuelven. La capacidad se cobra por los leídos.

🗣️ **2 minutos** — En el capítulo, el filtro sobre `estado` dio `Count` 9 y `ScannedCount` 52; el
`scan`, 57 y 242. Cuando los dos se parecen, la consulta hace el trabajo justo.

🔬 **El detalle** — **Motor**. Es el equivalente de comparar filas devueltas con filas leídas en un
`EXPLAIN ANALYZE` de `03/05`.

---

**05 → 5.** Distingue `query` de `scan`: qué lee cada una y qué cuesta. ¿Lo fija el estándar o es
cosa del motor? 🟡

⏱️ **30 segundos** — `query` lee un tramo contiguo de una sola partición, a partir de un valor
exacto de la clave de partición; `scan` lee la tabla entera, partición por partición. Se paga lo
leído.

🗣️ **2 minutos** — La `query` de los tres pedidos de 2025 de `CLI-00311` costó 0,5 unidades; el
`scan` para contar los `PAGADO`, 8,5, leyendo 242 elementos para devolver 57. Con un millón de
elementos, el `scan` escala con la tabla y la `query` no.

🔬 **El detalle** — **Motor**. En el servicio de AWS el `scan` se puede repartir en segmentos
paralelos; DynamoDB Local lo hace siempre en serie, dice su documentación.

---

**05 → 6.** Distingue índice secundario local de global: clave, consistencia y cuándo se crean. 🟡

⏱️ **30 segundos** — El local usa la misma clave de partición con otra de orden, admite lectura
fuerte y se crea con la tabla. El global usa cualquier clave, es siempre eventual y se puede crear
después.

🗣️ **2 minutos** — Hasta cinco locales y, por defecto, veinte globales por tabla. El local tiene un
límite de 10 GB por valor de la clave de partición. En el capítulo, pedir lectura fuerte al global
dio `Consistent reads are not supported on global secondary indexes`.

🔬 **El detalle** — **Motor**, cifras de la documentación. El global tiene su propia capacidad, y si
se queda corto, estrangula las escrituras de la tabla.

---

**05 → 7.** Distingue lectura eventual de lectura fuerte, con su precio medido. 🟡

⏱️ **30 segundos** — La eventual puede no ver una escritura de hace un instante; la fuerte ve todo
lo confirmado antes de la petición. La fuerte cuesta el doble: la misma consulta, 0,5 unidades
frente a 1,0.

🗣️ **2 minutos** — La eventual es la opción por defecto en AWS. En DynamoDB Local las dos devuelven
lo mismo, porque no hay réplicas, pero la capacidad sí se calcula distinta. La fuerte se pide solo
donde leer lo recién escrito importa, como mostrar un pedido justo después de crearlo.

🔬 **El detalle** — **Motor**. Los índices globales y los *streams* solo ofrecen la eventual.

---

**05 → 8.** ¿Hay en DynamoDB un lenguaje estándar para preguntar por cualquier atributo, como en
SQL? ¿Qué hace PartiQL con una consulta sin clave? 🟡

⏱️ **30 segundos** — No: la API es propia y solo pregunta por clave o por índice. PartiQL da una
sintaxis parecida a SQL, pero un `SELECT` sin igualdad sobre la clave de partición puede acabar en
un `scan` de la tabla entera.

🗣️ **2 minutos** — `SELECT codigo FROM pedidos WHERE estado = 'PAGADO'` devolvió los 57 pedidos, y
la documentación avisa del `scan`. La sintaxis cambia; el modelo de acceso, no.

🔬 **El detalle** — **Motor**. ISO/IEC 9075 no aplica. PartiQL no es SQL del estándar: es un
lenguaje propio con aspecto de SQL.

---

**05 → 9.** ¿Qué garantiza PostgreSQL sobre un índice secundario que DynamoDB no garantiza sobre un
índice global? 🟡

⏱️ **30 segundos** — Que el índice se actualiza en la misma transacción que la tabla: quien lee por
el índice ve lo mismo que vería en la tabla. El índice global de DynamoDB se actualiza de forma
asíncrona.

🗣️ **2 minutos** — Tras escribir un pedido en DynamoDB, puede tardar en aparecer en `por-estado`, y
no se puede pedir lectura fuerte al índice para evitarlo. En PostgreSQL, el índice y la fila se
confirman juntos.

🔬 **El detalle** — **Motor** los dos. El índice local de DynamoDB sí admite lectura fuerte.

---

**05 → 10.** ¿Por qué `fecha_pedido` lleva la fecha delante y el código detrás? 🟠

⏱️ **30 segundos** — Porque la clave de orden ordena por su valor completo: con la fecha delante,
los pedidos quedan en orden cronológico y «los de 2025» es un prefijo, `begins_with`. El código
detrás hace única la clave aunque dos pedidos coincidan en el segundo.

🗣️ **2 minutos** — Con el código delante, el orden sería por código y las consultas por fecha
necesitarían un filtro que lee todo. La marca va en UTC y con formato fijo para que el orden de
texto sea el orden de tiempo.

🔬 **El detalle** — Es la técnica de las claves compuestas, que `06` usa a fondo.

---

**05 → 11.** ¿Por qué el filtro sobre `estado` cobró 2,0 unidades para devolver nueve pedidos? 🟠

⏱️ **30 segundos** — Porque el filtro se aplica después de leer: DynamoDB leyó los 52 pedidos de
`CLI-00311`, cobró esa lectura, y después descartó los que no eran `PAGADO`.

🗣️ **2 minutos** — `ScannedCount` 52, `Count` 9. La capacidad sale del tamaño de lo leído, no de lo
devuelto. Para pagar solo los nueve, `estado` tendría que formar parte de una clave.

🔬 **El detalle** — **Motor**. Filtrar sirve para no transferir datos, no para leer menos.

---

**05 → 12.** ¿Por qué cambiar el estado de un pedido costó cuatro unidades de escritura, y de dónde
sale cada una? 🟠

⏱️ **30 segundos** — Una en la tabla, una en el índice local `por-total`, que proyecta el elemento
entero, y dos en el global `por-estado`, porque `estado` es su clave: la entrada vieja se borra y se
inserta otra.

🗣️ **2 minutos** — Lo devolvió `--return-consumed-capacity INDEXES`. Cada índice que contiene el
atributo cambiado paga su escritura, y cambiar la clave de un índice global cuesta el doble.

🔬 **El detalle** — **Motor**. Por eso un índice global sobre un atributo que cambia a menudo es
caro, y proyectar solo las claves, como `por-estado`, abarata cada escritura.

---

**05 → 13.** ¿Por qué el índice `por-estado` produce una partición caliente aunque la tabla reparta
bien? 🟠

⏱️ **30 segundos** — Porque su clave de partición tiene cinco valores, y todo pedido nuevo entra
`PENDIENTE`: todas las escrituras del índice van a la misma partición, con su techo de 1 000
unidades por segundo.

🗣️ **2 minutos** — La tabla reparte por cliente, que tiene miles de valores. El índice reparte por
estado, que tiene cinco. Con 1 000 pedidos nuevos por segundo, el índice se estrangula aunque la
tabla vaya sobrada.

🔬 **El detalle** — **Motor**, cifras de la documentación; no se observa en DynamoDB Local. La
capacidad adaptativa no levanta el techo por partición.

---

**05 → 14.** ¿Qué no puedes probar con DynamoDB Local, y qué sí? 🟠

⏱️ **30 segundos** — No: la capacidad aprovisionada, la estrangulación, las particiones y la
diferencia real entre lectura eventual y fuerte. Sí: la API, el modelo de claves, los índices, los
errores de validación y la capacidad que consumiría cada operación.

🗣️ **2 minutos** — La documentación dice que ignora la capacidad, no particiona y que sus lecturas
eventuales parecen fuertes. Pero `--return-consumed-capacity` devuelve cifras reales: 0,5 frente a
1,0, 8,5 del `scan`, 4 de la escritura con índices.

🔬 **El detalle** — Tampoco lanza `TransactionConflictException` en las transacciones. Sirve para el
modelo y la factura estimada, no para la escala.

---

**05 → 15.** ¿Por qué no se puede leer `PED-00042` sin saber que es de `CLI-26446`, y qué harías
para poder? 🟠

⏱️ **30 segundos** — Porque la clave primaria es cliente y fecha: sin el cliente no hay `get-item`
posible. Añadiría un índice global con el código del pedido como clave de partición.

🗣️ **2 minutos** — Buscar por código sin ese índice es un `scan`. Con el índice, es una `query` de
un elemento; si la proyección es solo de claves, una segunda lectura a la tabla trae el resto.

🔬 **El detalle** — En `06`, la tabla única resuelve esto dando al pedido su propio elemento con el
código en la clave.

---

**05 → 16.** Diseña la clave de una tabla de DynamoDB para los eventos de pedido, con un millón de
eventos diarios y consultas por pedido y por intervalo de tiempo, y di qué índice añadirías para
«los eventos de hoy». 🔴

⏱️ **30 segundos** — Partición: el código del pedido; orden: la marca de tiempo del evento. Para
«los eventos de hoy», un índice global con la fecha como partición, pero repartida en varios
fragmentos —`2025-02-21#0` a `#9`— para no concentrar todas las escrituras del día en una partición.

🗣️ **2 minutos** — Un millón de eventos al día son unos doce por segundo de media, pero con picos; y
con la fecha sola como clave, todos los del día irían a una partición. El sufijo de fragmento
reparte la escritura, y leer el día son diez consultas en paralelo, una por fragmento.

🔬 **El detalle** — Es la técnica de fragmentar la clave de escritura. Cada evento ocupa poco, así
que una escritura cuesta una unidad en la tabla y otra en el índice.

---

**05 → 17.** Diagnostica: la tabla de pedidos está bajo demanda, con capacidad de sobra según la
consola, y la aplicación recibe errores de estrangulación cada vez que entra una oleada de pedidos
nuevos. Da la causa más probable y cómo la confirmarías. 🔴

⏱️ **30 segundos** — Una partición caliente, casi seguro en un índice global con una clave de pocos
valores, como el estado: todos los pedidos nuevos entran `PENDIENTE` y chocan con el techo de 1 000
unidades por partición.

🗣️ **2 minutos** — Lo confirmo en las métricas de estrangulación de CloudWatch, separadas por tabla
y por índice: si se estrangula el índice y no la tabla, es eso. Bajo demanda no protege del techo
por partición.

🔬 **El detalle** — La corrección es cambiar la clave del índice o fragmentarla, o quitar el índice
si su pregunta puede resolverse de otra forma.

---

**05 → 18.** Te piden en DynamoDB el panel «cuántos pedidos hay en cada estado», actualizado al
minuto. Da tres diseños con lo que cuesta cada uno, y di cuál montarías. 🔴

⏱️ **30 segundos** — Uno, un `scan` por minuto, que lee la tabla entera. Dos, un índice global por
estado y contar con `query`, que concentra escrituras y lee cada estado entero. Tres, un elemento
contador por estado, actualizado en cada cambio. Montaría el tercero.

🗣️ **2 minutos** — El `scan` escala con la tabla: 8,5 unidades con 242 elementos, unas 35 000 con un
millón, cada minuto. El índice cuesta dos unidades extra por cada cambio de estado y crea la
partición caliente. El contador cuesta una escritura más por cambio, en una transacción o desde un
*stream* de la tabla, y el panel lee cinco elementos.

🔬 **El detalle** — El contador también concentra escrituras si todos los pedidos cambian a la vez;
con mucho volumen, se fragmenta como en `05 → 16`, y el panel suma los fragmentos.

---

## Capítulo 06 — DynamoDB: diseño desde el acceso

Las 18 preguntas de [`06`](06-dynamodb-diseno-desde-el-acceso.md).

**06 → 1.** ¿Cuáles son los cinco pasos del diseño desde el acceso? 🟢

⏱️ **30 segundos** — Entidades y relaciones; patrones de acceso con su frecuencia; claves, para que
el patrón más frecuente sea una `query`; índices para los patrones que la clave no responde; y
comprobar cada patrón con su orden y contra datos reales.

🗣️ **2 minutos** — El que manda es el segundo: la tabla de patrones es el documento de diseño. Y el
quinto no es opcional: en el capítulo, el primer diseño de las líneas falló al comprobarlo contra
los datos, antes de llegar a producción.

🔬 **El detalle** — **Convención**, respaldada por la documentación de AWS, que pide conocer las
preguntas antes de diseñar. Es el método que `09/02` reutiliza con Cassandra.

---

**06 → 2.** ¿Qué es una tabla de patrones de acceso, y qué columnas lleva? 🟢

⏱️ **30 segundos** — La lista de todas las preguntas que hará la aplicación, cada una con lo que
recibe, lo que devuelve y cuántas veces por segundo se hace.

🗣️ **2 minutos** — En la tienda: la ficha del pedido por su código, los pedidos recientes de un
cliente, los pedidos que llevan un producto y los pendientes de un cliente. La frecuencia decide qué
patrón va en la clave de la tabla y cuál puede ir en un índice con menos proyección.

🔬 **El detalle** — Lo que no está en la tabla no se diseña, y se decide sabiéndolo: «el total por
categoría» será un `scan` o un índice nuevo el día que se pida.

---

**06 → 3.** ¿Qué es un índice disperso? 🟢

⏱️ **30 segundos** — Un índice global cuya clave solo tienen algunos elementos: el que no la tiene
no entra en el índice, y el índice contiene solo lo que buscas.

🗣️ **2 minutos** — `pendientes` usa `pendiente_de`, que solo existe mientras el pedido está
`PENDIENTE`: tenía 6 elementos de 231. Al pagarse, se borra el atributo y el pedido sale solo.

🔬 **El detalle** — **Motor**: DynamoDB no indexa elementos sin la clave del índice. Es más barato
que un índice por estado, porque solo paga escrituras de los elementos que entran.

---

**06 → 4.** Distingue el orden de diseño en PostgreSQL y en DynamoDB. 🟡

⏱️ **30 segundos** — En PostgreSQL se modelan los datos, se normalizan, y las preguntas llegan
después, con índices si hacen falta. En DynamoDB se escriben primero las preguntas y la tabla se
diseña para ellas.

🗣️ **2 minutos** — La documentación de AWS lo dice así: en relacional puedes crear un modelo
normalizado sin pensar en los patrones de acceso; en DynamoDB no deberías empezar hasta conocerlos.
El planificador de PostgreSQL responde lo imprevisto; DynamoDB solo lo previsto.

🔬 **El detalle** — Es la diferencia que decide la elección entre los dos: cuánto sabes hoy de las
preguntas de mañana.

---

**06 → 5.** Distingue lo que hace `put-item` con una clave que ya existe de lo que hace un `INSERT`
en PostgreSQL. ¿Lo decide el estándar o cada motor? 🟡

⏱️ **30 segundos** — `put-item` reemplaza el elemento entero en silencio; un `INSERT` con la clave
repetida falla con `23505`. La unicidad de la clave primaria es del estándar SQL; lo de `put-item`
es de DynamoDB.

🗣️ **2 minutos** — En el capítulo, el segundo `put-item` sobre la línea de `PRD-00014` devolvió el
elemento viejo, de 4 unidades, y dejó el de 2, sin error. Para que falle, hace falta una condición:
`attribute_not_exists(PK)` respondió `ConditionalCheckFailedException`.

🔬 **El detalle** — **Estándar** la restricción de clave de SQL; **motor** el reemplazo de DynamoDB.
El `INSERT … ON CONFLICT DO UPDATE` de PostgreSQL es el reemplazo explícito, y hay que pedirlo.

---

**06 → 6.** Distingue sobrecarga de claves, índice invertido e índice disperso, con el índice de la
tienda que usa cada uno. 🟡

⏱️ **30 segundos** — Sobrecarga: atributos de clave genéricos que cada tipo rellena a su modo, como
`GSI1PK` en `gsi1`. Invertido: recorrer una relación desde el otro lado, como `por-producto`.
Disperso: una clave que solo algunos elementos tienen, como `pendientes`.

🗣️ **2 minutos** — `gsi1` responde los pedidos de un cliente, y otro tipo de elemento podría usarlo
para otra pregunta. `por-producto` responde qué pedidos llevan un producto. `pendientes` solo tiene
los pendientes.

🔬 **El detalle** — **Convención** los tres nombres. `por-producto` usa un atributo y no la `SK`
como clave, porque la `SK` de la línea es su número; la idea es la misma.

---

**06 → 7.** Tabla única frente a varias tablas: qué recomienda la documentación y qué exceptúa. 🟡

⏱️ **30 segundos** — Recomienda el menor número de tablas posible, para que lo que se lee junto
comparta partición. Exceptúa las series temporales de mucho volumen y los datos con patrones de
acceso muy distintos.

🗣️ **2 minutos** — En la tienda, el pedido y sus líneas van juntos porque la ficha los lee juntos:
una `query` de 0,5 unidades. Un registro de millones de eventos al día iría en su propia tabla.

🔬 **El detalle** — **Convención**, recogida por AWS. La regla no es «una tabla», sino «lo que se lee
junto, en la misma partición».

---

**06 → 8.** ¿Garantiza DynamoDB la unicidad de algún atributo aparte de la clave primaria, como un
`UNIQUE` de SQL? 🟡

⏱️ **30 segundos** — No. La clave primaria es la única restricción de unicidad; cualquier otra hay
que construirla a mano.

🗣️ **2 minutos** — Para que un correo no se repita, por ejemplo, se escribe un segundo elemento con
el correo como clave, en la misma transacción que el principal, con la condición de que no exista.

🔬 **El detalle** — **Motor**. El `UNIQUE` de SQL es del estándar y PostgreSQL lo mantiene con un
índice en la misma transacción.

---

**06 → 9.** ¿Por qué el primer diseño de las líneas, con `PRODUCTO#` como clave de orden, estaba
mal, y cómo lo descubriste antes de producción? 🟠

⏱️ **30 segundos** — Porque un pedido puede llevar el mismo producto en dos líneas, y las dos
tendrían la misma clave. Lo descubrí contando en PostgreSQL: 6 855 pedidos repiten producto.

🗣️ **2 minutos** — La muestra tenía `PED-388526` con `PRD-00014` dos veces. Cargado así, un lote
entero se rechazó, y dos escrituras sueltas pisaron una línea. La corrección fue `LINEA#01`, única
por construcción como la clave de `pedido_lineas`, y el producto en un índice propio.

🔬 **El detalle** — Es la razón del paso 5: una clave elegida por intuición se equivoca con los datos
reales, y DynamoDB no avisa.

---

**06 → 10.** ¿Por qué `batch-write-item` rechazó 25 elementos por dos claves repetidas, y por qué es
peor lo que hace `put-item`? 🟠

⏱️ **30 segundos** — Porque un lote no admite dos elementos con la misma clave y se valida entero:
falla todo con `Provided list of item keys contains duplicates`. `put-item` es peor porque no falla:
reemplaza en silencio.

🗣️ **2 minutos** — El lote rechazado dejó la tabla con 206 elementos en vez de 231: el error se ve.
El reemplazo de `put-item` solo se ve si pides `ALL_OLD` o si alguien echa de menos cuatro unidades.

🔬 **El detalle** — **Motor**. Un error visible es un defecto que se corrige; una pérdida silenciosa
es un incidente que se descubre tarde.

---

**06 → 11.** ¿Por qué el índice `pendientes` tiene 6 elementos y la tabla 231? ¿Qué pasa con un
pedido cuando se paga? 🟠

⏱️ **30 segundos** — Porque solo los pedidos pendientes llevan `pendiente_de`, que es la clave del
índice; los demás pedidos y todas las líneas no la tienen y no entran. Al pagarse, se borra el
atributo y el pedido sale del índice.

🗣️ **2 minutos** — `describe-table` lo confirmó: 6 en `pendientes`, 53 en `gsi1` y 178 en
`por-producto`. Salir del índice cuesta una escritura en él, como cualquier cambio de su clave.

🔬 **El detalle** — **Motor**. El índice se mantiene pequeño por diseño: su tamaño es el de lo que
buscas, no el de la tabla.

---

**06 → 12.** ¿Por qué P1 responde con el pedido y sus líneas en una sola consulta, y qué tiene que
ver la partición con eso? 🟠

⏱️ **30 segundos** — Porque el pedido y sus líneas comparten `PK`, `PEDIDO#PED-00042`: viven en la
misma partición, y una `query` por esa clave los devuelve todos juntos.

🗣️ **2 minutos** — Es lo que la tabla única busca: juntar lo que se lee junto. La `SK` distingue el
tipo —`PEDIDO`, `LINEA#01`…— y el orden es de texto, por eso el pedido sale el último.

🔬 **El detalle** — Es el equivalente de un `JOIN` resuelto en el diseño, no en la consulta; y cuesta
0,5 unidades porque todo cabe en un bloque de lectura.

---

**06 → 13.** ¿Qué cuesta una transacción en DynamoDB frente a escribir los elementos sueltos, y qué
ganas? 🟠

⏱️ **30 segundos** — El doble: cada elemento se lee o escribe dos veces, para preparar y confirmar,
y se cobra aunque la transacción se cancele. Ganas todo o nada entre varios elementos, hasta 100
acciones.

🗣️ **2 minutos** — En el capítulo, la transacción que intentaba crear otra vez `PED-00042` con una
línea nueva se canceló entera, `[ConditionalCheckFailed, None]`, y la línea no se escribió.

🔬 **El detalle** — **Motor**, según la documentación. En local no se lanzan los conflictos entre
transacciones concurrentes, así que esa parte hay que probarla contra el servicio o simularla.

---

**06 → 14.** Te piden «los pedidos por estado», que no estaba en la tabla de patrones. Da las dos
salidas y lo que cuesta cada una. 🟠

⏱️ **30 segundos** — Un `scan` con filtro, que lee la tabla entera cada vez; o un índice global
nuevo, que se rellena leyendo la tabla y después cobra cada cambio de estado.

🗣️ **2 minutos** — El índice pasó de `CREATING` a `ACTIVE` con 53 pedidos en local; en AWS, el
relleno consume capacidad y puede estrangular escrituras. Y un índice por estado es una partición
caliente, como en `05` §6.

🔬 **El detalle** — Si la pregunta es de informe, la respuesta honesta es otra: exportar a un sistema
analítico o contar con elementos contadores.

---

**06 → 15.** Diseña la tabla de patrones y las claves para añadir los pagos a la tabla `tienda`: un
pedido tiene cero o más pagos, y se consultan por pedido y por referencia del proveedor. 🔴

⏱️ **30 segundos** — Patrones: los pagos de un pedido, y el pago por referencia. Clave: `PK`
`PEDIDO#<código>` y `SK` `PAGO#<fecha>`, en la colección del pedido; y un índice con la referencia
como clave para el segundo.

🗣️ **2 minutos** — Así la ficha del pedido trae pedido, líneas y pagos en la misma `query`. La
referencia puede ser nula —en efectivo—, así que el índice es disperso: solo entran los pagos con
referencia. Y como la referencia debe ser única, se escribe con un elemento auxiliar condicionado
en la misma transacción.

🔬 **El detalle** — En PostgreSQL, `pagos.referencia` es `UNIQUE` y admite nulos; aquí esa garantía
se construye a mano.

---

**06 → 16.** Diagnostica: tras migrar a DynamoDB, algunos pedidos aparecen con menos unidades de las
que compró el cliente, sin ningún error en los registros. Da la causa más probable y la corrección.
🔴

⏱️ **30 segundos** — Una clave de línea que no es única —como `PRODUCTO#`— y un `put-item` que
reemplazó la primera línea con la segunda en silencio. Se corrige con una clave única por
construcción y escrituras condicionales.

🗣️ **2 minutos** — Lo confirmo comparando las líneas de un pedido afectado con PostgreSQL: faltará
una de dos líneas con el mismo producto. Para reparar, se recarga desde la fuente con la clave
corregida.

🔬 **El detalle** — La ausencia de errores es la pista: un lote duplicado falla, un reemplazo no. La
migración necesitaba contar elementos antes y después.

---

**06 → 17.** Defiende ante un equipo si la tienda debería estar en DynamoDB o en PostgreSQL, con
tres argumentos por cada lado y la pregunta que harías para decidir. 🔴

⏱️ **30 segundos** — La pregunta: ¿tenemos escritas las preguntas que hará la aplicación, y cambian
poco? A favor de DynamoDB: latencia constante a cualquier escala, sin base que operar, escritura en
varias regiones. A favor de PostgreSQL: preguntas imprevistas, informes y transacciones baratas.

🗣️ **2 minutos** — El volumen de la tienda cabe en una instancia de PostgreSQL con réplicas. Las
preguntas nuevas de cada semana en DynamoDB son índices nuevos con relleno o `scan`. La transacción
de DynamoDB cuesta el doble. Mi recomendación es PostgreSQL para el núcleo, y clave-valor para lo
que tenga patrón cerrado y mucha escritura.

🔬 **El detalle** — No es una pregunta de moda, es de conocimiento del dominio: la tabla de patrones
es la que decide.

---

**06 → 18.** Diseña la consulta y la clave para «los últimos diez pedidos de la tienda entera», a
1 000 pedidos nuevos por segundo, sin crear una partición caliente. 🔴

⏱️ **30 segundos** — Un índice con la clave fragmentada: `RECIENTES#0` a `RECIENTES#9`, elegido al
escribir, y la fecha como orden. Leer son diez `query` con límite diez, en paralelo, y mezclar.

🗣️ **2 minutos** — Con una sola partición, 1 000 escrituras por segundo chocarían con su techo. Con
diez fragmentos, cada uno recibe unas cien. Se puede añadir el día a la clave para que cada
fragmento no crezca sin fin.

🔬 **El detalle** — Es la fragmentación de escritura; su precio es leer diez veces para una pregunta.

---

## Simulación de entrevista

Las 26 preguntas `S#` y los cuatro escenarios de [`07`](07-simulacion-de-entrevista.md). Los
escenarios no se responden de memoria: se defienden en voz alta, y la capa 🔬 es la que dice qué se
está evaluando de verdad.

**07 → S1.** Explica en qué es más rápido Redis que PostgreSQL y en qué no, con las cifras medidas.
🟡

⏱️ **30 segundos** — En leer por clave, no: 0,064 ms en PostgreSQL frente a 0,047 en Redis, y con
dieciséis clientes PostgreSQL gana, 199 997 frente a 128 899 por segundo. En escribir muchas veces
el mismo valor, sí: 121 080 frente a 4 373.

🗣️ **2 minutos** — PostgreSQL reparte en ocho núcleos y Redis ejecuta en un hilo. En la escritura
caliente, el bloqueo de fila y la espera al WAL hunden a PostgreSQL. Redis no tiene ninguna de las
dos, y lo paga en el riesgo de perder el último segundo si cae la máquina.

🔬 **El detalle** — Cifras de un portátil de ocho núcleos, con cliente y servidor en el mismo
contenedor; lo que se sostiene es la proporción.

---

**07 → S2.** ¿Por qué `KEYS` está prohibido en producción, y qué usas en su lugar? 🟢

⏱️ **30 segundos** — Porque recorre todas las claves de una vez con el único hilo de Redis ocupado:
con cien mil claves, 6 062 µs sin atender a nadie. En su lugar, `SCAN` por tramos, o un índice
propio.

🗣️ **2 minutos** — `SCAN` no bloquea, pero puede repetir claves y hay que seguir el cursor hasta
`0`.

🔬 **El detalle** — **Motor**; su documentación lo reserva para depuración.

---

**07 → S3.** El ranking de ventas: compara el `GROUP BY` de PostgreSQL con un conjunto ordenado de
Redis en tiempo, en espacio y en lo que hay que mantener. 🟠

⏱️ **30 segundos** — Tiempo: 696 ms el `GROUP BY` y 8 µs el conjunto ordenado. Espacio: unos 445 KB
de RAM. Mantenimiento: cada venta hace su `ZINCRBY` además de su `INSERT`, sin transacción común.

🗣️ **2 minutos** — Si el servicio cae entre las dos escrituras, el ranking se desfasa hasta el
siguiente recálculo. Si admite minutos de retraso, una vista materializada refrescada da lo mismo
sin segundo motor.

🔬 **El detalle** — Los 8 µs son de una corrida; otra dio 26. La diferencia es de decenas de miles de
veces porque uno suma al leer y el otro lee lo ya ordenado.

---

**07 → S4.** ¿Por qué el carrito de un cliente va en un hash y no en una cadena JSON? 🟡

⏱️ **30 segundos** — Porque el hash cambia un campo con `HINCRBY`, atómico y sin leer el resto; en
JSON, cada cambio lee y reescribe todo, y dos pestañas se pisan.

🗣️ **2 minutos** — Es la actualización perdida, fuera de la base. El carrito de tres productos ocupó
82 bytes en `listpack`.

🔬 **El detalle** — **Motor**. Un hash no anida; si las líneas necesitan estructura, hay que aplanar.

---

**07 → S5.** Una caché de fichas deja de caducar tras un despliegue. ¿Qué orden lo explica casi
siempre? 🟠

⏱️ **30 segundos** — Un `SET` sin `EX` ni `KEEPTTL`, que borra la caducidad cada vez que refresca la
clave.

🗣️ **2 minutos** — `INCR` conserva la caducidad; `SET` la descarta, lo dice su documentación y se
vio en la sesión: `TTL` pasó a `-1`. Se confirma con `TTL` sobre varias fichas.

🔬 **El detalle** — Con `volatile-lru`, esas claves ya no son desalojables y la memoria se llena.

---

**07 → S6.** Distingue caducidad y desalojo, y di qué política de memoria pondrías a un Redis que
guarda sesiones. 🟡

⏱️ **30 segundos** — La caducidad la pones tú; el desalojo lo decide el servidor al llegar a
`maxmemory`. Para sesiones, `noeviction`: desalojar una sesión es echar al usuario.

🗣️ **2 minutos** — Con `noeviction`, al llenarse se rechazan las escrituras, así que la memoria se
vigila con alertas. La caché, si se mezcla, se lleva a otra instancia con `allkeys-lru`.

🔬 **El detalle** — **Motor**. Mezclar caché y datos en una instancia es mezclar sus riesgos.

---

**07 → S7.** ¿Qué garantiza `MULTI … EXEC` y qué no? Compáralo con una transacción de PostgreSQL. 🟡

⏱️ **30 segundos** — Garantiza que nadie se cuela entre sus órdenes; no garantiza deshacer si una
falla en ejecución. En PostgreSQL, un error deja la transacción abortada entera.

🗣️ **2 minutos** — En la sesión, un `WRONGTYPE` dentro del `EXEC` dejó aplicado el `HINCRBY`
anterior. Solo el error de sintaxis aborta todo, con `EXECABORT`.

🔬 **El detalle** — **Motor**: la documentación dice que Redis no admite *rollback*. Es aislamiento
sin la A de ACID.

---

**07 → S8.** ¿Cuándo usas `WATCH`, cuándo un script de Lua y cuándo basta un `HINCRBY`? 🟠

⏱️ **30 segundos** — `HINCRBY` cuando la operación es una sola orden atómica. `WATCH` para leer,
decidir en el cliente y escribir con poca contienda. Un script cuando la escritura depende de lo
leído y hay contienda.

🗣️ **2 minutos** — `WATCH` falla limpio si alguien se adelanta —`EXEC` devolvió `(nil)`— y hay que
reintentar. El script decide en el servidor, sin reintentos, a costa de parar al resto mientras
dura.

🔬 **El detalle** — El stock que solo baja si queda es el caso típico de script.

---

**07 → S9.** Un script de Lua que tarda 50 ms, ¿qué le hace al resto de clientes? 🟠

⏱️ **30 segundos** — Los deja 50 ms sin respuesta: Redis no atiende a nadie mientras un script
corre.

🗣️ **2 minutos** — En la sesión, un `PING` esperó 3,89 s a que un script infinito llegara al umbral
de 5 s, y recibió `BUSY`. `SCRIPT KILL` solo mata scripts que no han escrito.

🔬 **El detalle** — **Motor**. En PostgreSQL una función lenta solo afecta a quien espere sus
bloqueos.

---

**07 → S10.** Con AOF por segundo, ¿qué se pierde si muere el proceso, y qué si cae la máquina? 🟠

⏱️ **30 segundos** — Si muere el proceso, nada medido: 56 510 confirmados y 56 510 recuperados. Si
cae la máquina, hasta un segundo, lo que aún no pasó del sistema operativo al disco.

🗣️ **2 minutos** — Lo escrito en el AOF queda en manos del sistema aunque el proceso muera; el
`fsync` por segundo decide cuándo llega al disco.

🔬 **El detalle** — El corte de la máquina no se reprodujo en el entorno. Es el mismo reparto que
`synchronous_commit = off` en PostgreSQL.

---

**07 → S11.** ¿Por qué un Redis solo con RDB perdió 149 498 confirmaciones al reiniciarlo? 🟠

⏱️ **30 segundos** — Porque al arrancar cargó la última instantánea, de veintitrés segundos antes, y
todo lo escrito después se perdió.

🗣️ **2 minutos** — Último confirmado 803 890, recuperado 654 392. `save 60 1000` solo guarda si hubo
mil cambios en sesenta segundos; con poco tráfico, la instantánea puede ser de hace horas.

🔬 **El detalle** — Cada `INCR` respondió con su número: la respuesta confirma la memoria, no la
supervivencia.

---

**07 → S12.** ¿Qué cuesta `appendfsync always`, y cuándo lo pondrías? 🟡

⏱️ **30 segundos** — Siete veces el rendimiento de escritura: de 117 536 a 16 086 `INCR` por
segundo. Lo pondría cuando una sola confirmación perdida sea inaceptable.

🗣️ **2 minutos** — Cada grupo de órdenes espera su `fsync` antes de responder, como el `COMMIT` de
PostgreSQL con `synchronous_commit = on`.

🔬 **El detalle** — La documentación lo resume en «muy muy lento, muy seguro».

---

**07 → S13.** Describe la carrera de *cache-aside* paso a paso y di qué la cierra de verdad. 🔴

⏱️ **30 segundos** — A falla en la caché y lee `PAGADO`; B actualiza a `ENVIADO` y borra la clave,
que aún no existe; A escribe `PAGADO` con cinco minutos de caducidad. La cierra escribir en la caché
solo si la versión es más nueva.

🗣️ **2 minutos** — El `DEL` de B devolvió `0`, que es la huella de la carrera. La caducidad acota el
daño; borrar dos veces estrecha la ventana; la versión comparada en un script la cierra.

🔬 **El detalle** — Se corrió con cuatro terminales a la vez. La versión tiene que venir de la fila,
que el esquema de `pedidos` no trae.

---

**07 → S14.** Las tres mitigaciones de la estampida, y el caso que ninguna de las tres cubre. 🟠

⏱️ **30 segundos** — Recálculo externo, candado y expiración anticipada probabilística. Ninguna
cubre mil claves distintas que caducan en el mismo instante; eso se arregla con caducidad al azar.

🗣️ **2 minutos** — El candado bajó cincuenta consultas a una en `l04`. Con `EX 10` fijo, mil claves
desaparecieron en el mismo segundo; con azar entre 7 y 13, en seis.

🔬 **El detalle** — Las tres mitigaciones son las del artículo de Vattani, Chierichetti y Lowenstein,
cuyo algoritmo XFetch usa una distribución exponencial.

---

**07 → S15.** ¿Cómo se implementa una limitación de tasa atómica en Redis, y qué defecto tiene la
ventana fija? 🟡

⏱️ **30 segundos** — Con un script o una *Function* que hace `INCR` y pone la caducidad en la
primera llamada, en un solo paso. La ventana fija deja pasar el doble en el borde entre dos
ventanas.

🗣️ **2 minutos** — La sexta llamada devolvió `6` y el servicio rechaza. La ventana deslizante, con
un conjunto ordenado de marcas de tiempo, no tiene borde, a costa de una entrada por petición.

🔬 **El detalle** — Con `INCR` y `EXPIRE` separados, un proceso que muere entre los dos deja al
cliente bloqueado para siempre.

---

**07 → S16.** Cola con `BRPOP` frente a grupo de consumidores de un *stream*: qué pasa si el
consumidor cae, y qué obliga eso a hacer. 🟠

⏱️ **30 segundos** — Con `BRPOP`, el mensaje se pierde. Con un grupo, queda pendiente a nombre del
consumidor y otro lo reclama con `XAUTOCLAIM`. Obliga a un consumidor idempotente, porque la entrega
es al menos una vez.

🗣️ **2 minutos** — En la sesión, el mensaje que `w1` no confirmó quedó en `XPENDING` y `w2` lo
reclamó. Si `w1` hubiera terminado el trabajo antes de caer, se habría hecho dos veces.

🔬 **El detalle** — Si el trabajo nace de una transacción de PostgreSQL, la cola con `SKIP LOCKED` en
la misma base evita el hueco entre dos motores.

---

**07 → S17.** ¿Qué son la clave de partición y la de orden, y qué decide cada una? 🟢

⏱️ **30 segundos** — La de partición decide, por hash, en qué partición vive el elemento; la de
orden, cómo se ordena dentro de ella.

🗣️ **2 minutos** — Con `cliente` y `fecha_pedido`, «los pedidos de 2025 de `CLI-00311`» es un tramo
contiguo: una `query` de 0,5 unidades.

🔬 **El detalle** — **Motor**. La de partición decide también la escala: su valor más popular marca
el techo.

---

**07 → S18.** Un filtro sobre `estado` devolvió nueve pedidos y cobró cincuenta y dos. Explícalo. 🟡

⏱️ **30 segundos** — Porque el filtro se aplica después de leer: se leyeron los 52 pedidos del
cliente y se cobraron, y luego se descartaron los que no eran `PAGADO`.

🗣️ **2 minutos** — `Count` 9, `ScannedCount` 52, 2,0 unidades. Para pagar solo los nueve, el estado
tendría que ser parte de una clave.

🔬 **El detalle** — **Motor**. Filtrar ahorra transferencia, no lectura.

---

**07 → S19.** Índice local frente a global: diferencias y precio. 🟡

⏱️ **30 segundos** — El local comparte la clave de partición, admite lectura fuerte y se declara al
crear la tabla. El global usa cualquier clave, es eventual y se crea cuando quieras. Los dos cobran
en cada escritura.

🗣️ **2 minutos** — Cambiar el estado de un pedido costó cuatro unidades: una en la tabla, una en el
local y dos en el global, porque cambió su clave.

🔬 **El detalle** — Hasta cinco locales y veinte globales por tabla, por defecto; el local tiene un
límite de 10 GB por valor de partición.

---

**07 → S20.** ¿Cómo se produce una partición caliente con una tabla que reparte bien? 🟠

⏱️ **30 segundos** — Con un índice global de pocos valores: un índice por estado recibe todas las
escrituras de los pedidos nuevos en la partición `PENDIENTE`, con su techo de 1 000 unidades por
segundo.

🗣️ **2 minutos** — La tabla reparte por cliente, pero el índice por estado tiene cinco particiones
lógicas. La capacidad adaptativa no pasa del máximo por partición.

🔬 **El detalle** — No se observa en DynamoDB Local; en AWS se ve en las métricas de estrangulación
del índice.

---

**07 → S21.** Explica el diseño desde los patrones de acceso en cinco pasos. 🟠

⏱️ **30 segundos** — Entidades; patrones con frecuencia; claves para el patrón más frecuente;
índices para el resto; y comprobar cada patrón con su orden contra datos reales.

🗣️ **2 minutos** — En la tienda, cuatro patrones se respondieron con cuatro `query` de 0,5 unidades,
en una tabla con tres índices: sobrecargado, invertido y disperso.

🔬 **El detalle** — **Convención**, respaldada por AWS. La tabla de patrones es el documento de
diseño.

---

**07 → S22.** ¿Por qué el primer diseño de las líneas con `PRODUCTO#` como clave de orden perdía
datos, y cómo se evita? 🔴

⏱️ **30 segundos** — Porque 6 855 pedidos repiten producto, y dos líneas del mismo producto tenían
la misma clave: un lote se rechazó entero y un `put-item` pisó una línea sin avisar. Se evita con
una clave única por construcción y escrituras condicionales.

🗣️ **2 minutos** — `LINEA#01`, como la clave compuesta de `pedido_lineas`, y el producto en un
índice. `attribute_not_exists(PK)` convierte el pisado en un error.

🔬 **El detalle** — Se detectó en el paso 5, comprobando la clave contra PostgreSQL antes de migrar.

---

**07 → S23.** «Redis es solo una caché». Corrígelo con dos ejemplos del bloque. 🟡

⏱️ **30 segundos** — También guarda datos que no están en otro sitio: el carrito, que no está en
PostgreSQL, y la limitación de tasa. Perderlos no es un fallo de caché, es perder datos.

🗣️ **2 minutos** — Por eso la política de memoria y la persistencia importan: `noeviction` y AOF
para lo que no se puede regenerar.

🔬 **El detalle** — Muchas instalaciones traen `noeviction`, que es justo lo contrario de lo que
quiere una caché.

---

**07 → S24.** «DynamoDB escala infinitamente». ¿Qué parte es cierta? 🟠

⏱️ **30 segundos** — Escala repartiendo por la clave de partición, y solo tanto como esa clave esté
repartida. Cada partición da como mucho 3 000 unidades de lectura y 1 000 de escritura por segundo.

🗣️ **2 minutos** — Una clave con cinco valores es una tabla de cinco particiones. Con una clave de
miles de valores bien repartidos, sí escala sin que operes nada.

🔬 **El detalle** — **Motor**, cifras de la documentación de AWS.

---

**07 → S25.** «Si borras la clave después de escribir en la base, la caché nunca queda vieja».
Refútalo. 🟠

⏱️ **30 segundos** — Un lector que leyó antes de tu cambio puede escribir el valor viejo en la caché
después de tu borrado. Pasó en la sesión: la caché dijo `PAGADO` 300 s con la base en `ENVIADO`.

🗣️ **2 minutos** — El borrado devolvió `0` porque aún no había nada. La caducidad acota el daño; la
versión comparada lo evita.

🔬 **El detalle** — **Convención** el consejo, y cierto a medias: reduce el problema, no lo elimina.

---

**07 → S26.** «DynamoDB Local sirve para probar si aguanta la carga». ¿Qué se puede probar y qué no?
🟡

⏱️ **30 segundos** — No sirve para la carga: ignora la capacidad y no particiona. Sirve para la API,
el modelo de claves, los índices, los errores y la capacidad que consumiría cada operación.

🗣️ **2 minutos** — Sus lecturas eventuales parecen fuertes y no lanza conflictos de transacción.
Pero `--return-consumed-capacity` da cifras reales para estimar la factura.

🔬 **El detalle** — Lo dice su propia documentación; la escala se prueba contra el servicio.

---

**07 → E1.** Escenario 1 — El contador de la campaña

⏱️ **30 segundos** — PostgreSQL no llega porque el bloqueo de fila serializa las escrituras y cada
`COMMIT` espera al WAL con la fila bloqueada: separado, cada causa multiplica por siete. Redis hace
121 080 por segundo, con AOF por segundo, y pierde hasta un segundo si cae la máquina.

🗣️ **2 minutos** — Las causas se separan cambiando una variable: `synchronous_commit = off` y filas
repartidas. La alternativa sin segundo motor es sumar en memoria y volcar cada segundo con un
`UPDATE`, que pierde lo mismo. Si el contador paga a proveedores, no puede perder nada: se escribe
cada visita en PostgreSQL de forma asíncrona y se agrega, o se usa `appendfsync always` y se acepta
su rendimiento.

🔬 **El detalle** — Lo que se evalúa es decir qué se pierde con cada opción y adaptarlo al uso del
dato: un contador de popularidad y uno que paga dinero no admiten la misma pérdida.

---

**07 → E2.** Escenario 2 — La factura de DynamoDB

⏱️ **30 segundos** — La factura es el `scan` del panel: lee la tabla entera cada minuto en treinta
pantallas, y filtrar no ayuda porque se paga lo leído. La estrangulación es el índice global por
estado: todos los pedidos nuevos escriben en la partición `PENDIENTE`.

🗣️ **2 minutos** — Con 242 elementos el `scan` costó 8,5 unidades; con un millón, unas 35 000 por
lectura. Diseños: elementos contadores por estado, fragmentados si hace falta; un índice disperso
por estado solo para los que interesan; o exportar a un sistema analítico. La tabla de patrones
habría puesto el panel en la lista y la clave del índice se habría fragmentado desde el principio.

🔬 **El detalle** — Bajo demanda no protege del techo por partición; es la confusión que se evalúa.

---

**07 → E3.** Escenario 3 — ¿DynamoDB para la tienda entera?

⏱️ **30 segundos** — La pregunta: ¿están escritas las preguntas de la aplicación, y cambian poco?
Con un equipo de datos que saca informes nuevos cada semana, no lo están, y 300 pedidos por minuto
caben de sobra en PostgreSQL.

🗣️ **2 minutos** — A favor: latencia constante, sin base que operar, varias regiones. En contra:
cada informe nuevo es un índice con relleno o un `scan`; las transacciones cuestan el doble; y el
volumen actual no lo necesita. Pondría en clave-valor lo de patrón cerrado y mucha escritura —el
carrito, las sesiones, contadores— y el resto en PostgreSQL.

🔬 **El detalle** — La recomendación en una frase: «DynamoDB se elige por la escala que ahorra; hoy
la tienda no la necesita y pagaría el método en cada informe».

---

**07 → E4.** Escenario 4 — El pedido que sigue `PAGADO`

⏱️ **30 segundos** — Esto no lo resuelve la base de datos: Redis no perdió nada y PostgreSQL tiene
`ENVIADO`. Es la carrera de *cache-aside*: un lector escribe en la caché lo que leyó antes del
cambio, después del borrado del escritor.

🗣️ **2 minutos** — La secuencia: el lector falla y lee `PAGADO`; envíos actualiza y borra, y el
`DEL` devuelve `0`; el lector escribe `PAGADO` con cinco minutos. Correcciones: caducidad más corta,
borrar dos veces, y escribir en la caché solo si la versión es más nueva, con un script que compare.
Esa última necesita una columna de versión fiable en `pedidos`.

🔬 **El detalle** — Lo que se evalúa es no aceptar el marco: `always`, la réplica y la memoria no
tocan la causa. El dato que delata la carrera es el `DEL` que no borró nada.
