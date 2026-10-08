# 01 — El modelo clave-valor

> Qué es un almacén clave-valor, qué resuelve mejor que una tabla y qué deja de poder hacer, medido
> contra PostgreSQL con el mismo pedido y el mismo producto: una lectura por clave, que **no** es
> donde SQL falla, y un contador que dieciséis clientes incrementan a la vez, que sí lo es. Cierra
> con la ficha del modelo y el mapa de productos. **Asume leído:**
> [`10/07`](../10-interfaz-con-los-lenguajes/07-clientes-de-redis-y-mongodb.md), donde los cuatro
> lenguajes ya hablan con Redis, y
> [`04/04`](../04-transacciones-y-concurrencia/04-bloqueos-e-interbloqueos.md), el bloqueo de fila.
> **Vigencia:** 26 de septiembre de 2026.

---

## Salto rápido

- [1. El problema](#1--el-problema) · [2. Qué es un almacén
  clave-valor](#2--qué-es-un-almacén-clave-valor)
- [3. Lo que no se puede preguntar](#3--lo-que-no-se-puede-preguntar) · [4. Dónde falla SQL,
  medido](#4--dónde-falla-sql-medido)
- [5. La ficha del modelo](#5--la-ficha-del-modelo) · [6. Los productos](#6-️-los-productos)
- [7. Estándar, motor y convención](#7--estándar-motor-y-convención) · [Errores
  frecuentes](#️-errores-frecuentes) · [Preguntas](#-preguntas)

---

## 1. 🎯 El problema

La ficha de `PRD-00017`, el producto más vendido de la tienda, lleva un contador de visitas. Cada
vez que alguien abre la ficha, el servicio suma uno. En una campaña, dieciséis procesos del servicio
suman a la vez sobre **la misma fila**, y el equipo mide lo siguiente en PostgreSQL:

```text
1 cliente sumando          6 421 escrituras por segundo
16 clientes sumando        4 373 escrituras por segundo, cada una tarda 3,7 ms
```

Con dieciséis veces más clientes, **el motor hace menos trabajo que con uno**. Y el mismo equipo
comprueba que leer la ficha de `PED-00042` por su código cuesta 0,064 ms y escala hasta 200 000
lecturas por segundo sin despeinarse. La lectura va bien; la escritura sobre un solo valor, no.

La propuesta que llega es «pongamos Redis, que es más rápido». Es media verdad, y este capítulo la
parte en dos: **en qué es más rápido, en qué no lo es, y qué se deja de poder hacer** al guardar
datos en un sitio donde lo único que se puede preguntar es «dame el valor de esta clave».

> **📝 Contexto.** Todo está corrido en un portátil de 8 núcleos, con el cliente de medición dentro
> del mismo contenedor que el servidor —`pgbench` en el de PostgreSQL, `redis-benchmark` en el de
> Redis—, así que no hay red de por medio y **las cifras absolutas son de esta máquina**; lo que se
> sostiene en cualquier otra es la proporción. Las lecturas se midieron contra `bd-lab`. **Las
> escrituras de PostgreSQL se midieron en una copia aislada**, cargada con la misma semilla, porque
> sumar miles de versiones de fila a `productos` cambiaría el estado que el resto del corpus
> necesita. Todo lo creado en Redis se borró en su sección. **Longitud:** unas 430 líneas;
> capítulo normal que pasa el disparador de 400 por las dos baterías de medición.

---

## 2. 🧱 Qué es un almacén clave-valor

**Qué es:** un almacén donde cada dato se guarda bajo una **clave** única y se recupera **solo por
esa clave**. No hay columnas que filtrar, ni joins, ni un planificador que decida cómo buscar: la
clave dice dónde está el valor, y el motor lo devuelve. Es la estructura de un diccionario de
cualquier lenguaje, puesta detrás de un puerto de red.

Para verlo con volumen, los 99 999 primeros pedidos de PostgreSQL pasan a Redis, uno por clave
`pedido:<código>`, como fija el documento de dominio. PostgreSQL escribe cada `SET` en el protocolo
de Redis y `redis-cli` lo manda de golpe:

```sql
SELECT format(E'*3\r\n$3\r\nSET\r\n$%s\r\n%s\r\n$%s\r\n%s\r',
              octet_length(k), k, octet_length(v), v)
  FROM (SELECT 'pedido:' || codigo AS k,
               json_build_object('codigo', codigo, 'cliente_id', cliente_id, 'estado', estado,
                                 'total', total::text, 'creado_en', creado_en)::text AS v
          FROM pedidos WHERE id <= 99999 ORDER BY id) AS t;
```

```bash
psql -h 127.0.0.1 -U postgres -d tienda -At -f resp.sql | docker exec -i bd-lab-redis redis-cli --pipe
```

- `format(E'*3\r\n$3\r\nSET…')` escribe cada orden en **RESP**, el protocolo de Redis: `*3` dice que
  la orden tiene tres partes, y cada `$N` la longitud en bytes de la parte que sigue. El último
  `\r\n` lo completa el salto de línea que `psql` pone al final de cada fila.
- `-At` quita la alineación y las cabeceras de `psql`: sale una orden por fila, sin adornos.
- `docker exec -i` pasa la entrada estándar al contenedor, y `redis-cli --pipe` manda todas las
  órdenes sin esperar cada respuesta; al final cuenta las que recibió.

```text
All data transferred. Waiting for the last reply...
Last reply received from server.
errors: 0, replies: 99999
```

Cien mil escrituras en 0,64 s. Ahora, desde la consola de Redis:

```text
127.0.0.1:6379> DBSIZE
(integer) 99999
127.0.0.1:6379> GET pedido:PED-00042
"{\"codigo\" : \"PED-00042\", \"cliente_id\" : 26446, \"estado\" : \"PAGADO\", \"total\" : \"3186.23\", \"creado_en\" : \"2025-02-21T03:08:09.349067+00:00\"}"
127.0.0.1:6379> TYPE pedido:PED-00042
string
127.0.0.1:6379> OBJECT ENCODING pedido:PED-00042
"raw"
127.0.0.1:6379> MEMORY USAGE pedido:PED-00042
(integer) 195
```

- **El valor es opaco para el motor**: Redis guardó una cadena de bytes. Que dentro haya JSON con un
  campo `estado` lo sabe tu código, no Redis, igual que en `10/07` §3.
- **`TYPE` dice `string`**: en Redis el valor tiene un tipo —cadena, lista, hash, conjunto…—, y el
  tipo decide qué órdenes admite. Es lo que separa a Redis de un diccionario puro, y es la materia
  de [`02`](02-redis-estructuras-y-ttl.md).
- **`MEMORY USAGE` da 195 bytes** para ese pedido, con la clave y la contabilidad interna incluidas.

**Quién lo manda:** **motor**, entero. No hay estándar de clave-valor: cada producto define su
protocolo, sus tipos y sus órdenes.

**Cuánto:** en **espacio**, y en la memoria más cara de la máquina. La memoria de Redis pasó de
1,53 MB a 22,09 MB con la carga, unos **216 bytes por pedido en RAM**. Ese mismo pedido ocupa **88
bytes en disco** como fila de PostgreSQL —84 MB el millón—, con tipos de verdad en vez de texto.

**Cuándo sí:** cuando el acceso es siempre por un identificador que el código ya conoce —la sesión
del usuario, el carrito de un cliente, el contador de un producto—. **Cuándo no:** cuando alguien va
a necesitar preguntar por el contenido, que es la sección siguiente.

> **Veredicto:** un almacén clave-valor cambia el lenguaje de consulta por una sola pregunta, «dame
> esta clave», y a cambio no tiene que planificar, filtrar ni unir nada.

---

## 3. 🩺 Lo que no se puede preguntar

La pregunta obvia sobre esos cien mil pedidos —**¿cuántos están `PAGADO`?**— no tiene orden en
Redis. El estado vive dentro de una cadena que el motor no lee. Lo más cerca que se puede llegar es
recorrer las claves, y eso tiene dos formas, las dos con trampa.

La primera es `SCAN`, que recorre el espacio de claves por tramos y filtra por el **nombre** de la
clave, nunca por su valor:

```text
127.0.0.1:6379> SCAN 0 MATCH pedido:PED-0004* COUNT 100
1) "74240"
2) (empty array)
```

- **Una lista vacía no significa que no haya**: significa que en ese tramo de unas cien claves
  ninguna encajaba con el patrón. El cursor `74240` es por dónde seguir, y el recorrido termina
  cuando el servidor devuelve cursor `0`. `COUNT` es cuánto trabajo hacer por llamada, no cuántos
  resultados traer.
- Aunque terminara, tendrías los nombres. Para saber el estado de cada uno harían falta cien mil
  `GET` y leer el JSON en tu código.

La segunda es `KEYS`, que devuelve todas las claves de una vez. Con el umbral del registro de
lentitud a cero, para que anote cualquier orden:

```text
$ docker exec bd-lab-redis redis-cli KEYS "pedido:*" | wc -l
   99999
$ docker exec bd-lab-redis redis-cli SLOWLOG GET 1
27
1790468017
6062
KEYS
pedido:*
127.0.0.1:44402

2
```

- La tercera línea del registro es la duración: **6 062 microsegundos**. Seis milisegundos en los
  que Redis no atendió a nadie más, porque ejecuta las órdenes de una en una en un solo hilo. Con
  diez millones de claves serían segundos de servicio parado.
- El umbral se había bajado con `CONFIG SET slowlog-log-slower-than 0` y se devolvió a su valor, que
  en este entorno es `10000` —diez milisegundos—.

**Quién lo manda:** **motor**. La documentación de `KEYS` avisa en su propia página de que es para
depuración y no para producción.

**Cuánto:** en **concurrencia**. `KEYS` bloquea el servidor entero mientras recorre; `SCAN` no lo
bloquea, pero cuesta una ida y vuelta por tramo y puede devolver una clave dos veces.

**La salida real es mantener tu propio índice**: un conjunto `estado:PAGADO` con los códigos, que se
actualiza en la misma operación que el pedido. Funciona, y **el índice lo escribes tú, lo mantienes
coherente tú y lo depuras tú** cuando no cuadre. Es exactamente el trabajo que un índice secundario
de PostgreSQL hace solo, dentro de la transacción.

**Teardown de esta sección:**

```bash
docker exec bd-lab-redis sh -c "redis-cli --scan --pattern 'pedido:*' | xargs redis-cli UNLINK"
```

- `redis-cli --scan --pattern` hace el recorrido con `SCAN` por dentro, sin bloquear, y escribe una
  clave por línea; `xargs` las agrupa en lotes y `UNLINK` las borra liberando la memoria en segundo
  plano, que es lo que la distingue de `DEL`. Salieron trece lotes que suman 99 999, y `DBSIZE`
  volvió a `0`.

> **Veredicto:** en clave-valor, cada pregunta que no sea «dame esta clave» la contestas tú,
> manteniendo a mano la estructura que la responda. Si el catálogo de preguntas no está cerrado, el
> modelo no es este.

---

## 4. 🩺 Dónde falla SQL, medido

Las dos operaciones del §1, con 1 y con 16 clientes. PostgreSQL con `pgbench`, Redis con
`redis-benchmark`, cada uno dentro de su contenedor:

```bash
pgbench -h 127.0.0.1 -U postgres -n -M prepared -f /tmp/caliente.sql -c 16 -j 8 -T 10 tienda
redis-benchmark -h 127.0.0.1 -q --threads 8 -c 16 -n 1000000 INCR vistas:PRD-00017
```

- `pgbench -f` corre el SQL del fichero en bucle. `caliente.sql` tiene una sola sentencia:
  `UPDATE productos SET precio = precio WHERE codigo = 'PRD-00017'`. El esquema no tiene columna de
  contador, y ese `UPDATE` hace
  lo mismo que un contador: **bloquea la fila y escribe una versión nueva** de ella, aunque el
  valor no cambie ([`04/03`](../04-transacciones-y-concurrencia/03-mvcc-frente-a-bloqueo.md)).
- `-M prepared` planifica una vez y reutiliza el plan; `-n` no hace el `VACUUM` previo de las tablas
  de ejemplo de `pgbench`, que aquí no existen; `-c 16 -j 8` son 16 clientes repartidos en 8 hilos;
  `-T 10`, diez segundos.
- `redis-benchmark -n 1000000` manda un millón de órdenes en total; `--threads 8` usa ocho hilos de
  cliente para que el medidor no sea el cuello de botella; `-q` imprime solo el resumen.

La corrida entera de la fila caliente, con 16 clientes:

```text
pgbench (18.6 (Debian 18.6-1.pgdg13+2))
transaction type: /tmp/caliente.sql
scaling factor: 1
query mode: prepared
number of clients: 16
number of threads: 8
maximum number of tries: 1
duration: 10 s
number of transactions actually processed: 43732
number of failed transactions: 0 (0.000%)
latency average = 3.658 ms
initial connection time = 5.774 ms
tps = 4373.402926 (without initial connection time)
```

Y las ocho medidas juntas, en operaciones por segundo:

| Operación | PostgreSQL, 1 | PostgreSQL, 16 | Redis, 1 | Redis, 16 |
|---|---|---|---|---|
| Leer la ficha de `PED-00042` | 15 575 | 199 997 | 19 221 | 128 899 |
| Sumar 1 al contador de `PRD-00017` | 6 421 | **4 373** | 17 925 | **121 080** |

- **En la lectura por clave, PostgreSQL no pierde**: 0,064 ms de media frente a una mediana de
  0,047 ms en Redis, y con dieciséis clientes gana, porque reparte el trabajo en 8 núcleos y Redis
  ejecuta en un solo hilo —`io-threads` vale `1` en este entorno—. Con la página en caché, leer una
  fila por su índice único es barato: es el `Index Scan` de
  [`03/05`](../03-el-motor-por-dentro/05-explain-y-explain-analyze.md).
- **En la escritura caliente, la diferencia es de 28 veces**, y en PostgreSQL empeora al añadir
  clientes. Redis contó los dos millones de `INCR` sin perder uno: el contador acabó en `2000000`.

¿Por qué empeora PostgreSQL? Hay dos causas encadenadas, y se separan cambiando una cosa cada vez:

| `UPDATE` con 16 clientes | `synchronous_commit = on` | `synchronous_commit = off` |
|---|---|---|
| Todos sobre la fila de `PRD-00017` | 4 373 | 32 453 |
| Cada uno sobre un producto al azar | 32 093 | 209 126 |

- **El bloqueo de fila serializa**: sobre la misma fila, cada `UPDATE` espera a que el anterior
  confirme, y los dieciséis hacen cola
  ([`04/04`](../04-transacciones-y-concurrencia/04-bloqueos-e-interbloqueos.md) §2). Repartidos por
  5 000 productos, apenas coinciden: 7 veces más.
- **Y cada confirmación espera al disco**: con `synchronous_commit = on`, el `COMMIT` no vuelve
  hasta que el WAL está escrito
  ([`04/06`](../04-transacciones-y-concurrencia/06-wal-durabilidad-y-fsync.md) §4). Sobre la fila
  caliente, esa espera la paga cada cliente **mientras tiene la fila bloqueada**, así que se suma
  en cola. Quitarla multiplica por 7 otra vez.
- **Redis no tiene ninguna de las dos**: ejecuta las órdenes de una en una, así que `INCR` es
  atómico sin bloquear nada, y su registro en disco —el AOF— se escribe **por segundo, no por
  orden**. Esa es la letra pequeña, y se paga en [`03`](03-atomicidad-scripts-y-durabilidad.md):
  un corte puede llevarse el último segundo de incrementos.

**Quién lo manda:** **motor**, en los dos lados. Ni el estándar SQL ni ningún estándar de
clave-valor dicen nada de hilos, bloqueos de fila ni de cuándo se escribe el registro.

**Cuánto:** PostgreSQL paga el contador caliente en **concurrencia** —3,7 ms de cola por escritura—
y a cambio no pierde una confirmación. Redis lo hace 28 veces más rápido y lo paga en **riesgo de
pérdida** y en que todo vive en RAM.

> **Veredicto:** SQL no falla en leer por clave; falla en muchas escrituras sobre el mismo valor,
> que es donde el bloqueo de fila y la espera al disco se multiplican. Ese es el caso de
> clave-valor.

---

## 5. 🧭 La ficha del modelo

| Punto | Clave-valor |
|---|---|
| **Qué resuelve mejor que SQL** | Muchas operaciones pequeñas sobre el mismo valor —contadores, límites, sesiones— con latencia de décimas de milisegundo y sin bloqueo de fila |
| **Dónde falla SQL, y por qué** | En la escritura concurrente sobre una sola fila: el bloqueo la serializa y cada confirmación espera al WAL con la fila bloqueada. No en la lectura por clave |
| **Producto principal y stack** | Redis, con su protocolo RESP y `redis-cli`; clientes Jedis, redis-py, node-redis y go-redis ([`10/07`](../10-interfaz-con-los-lenguajes/07-clientes-de-redis-y-mongodb.md)); `bd-lab-redis`, imagen `redis:8.10.1` |
| **El caso** | El contador de visitas de `PRD-00017` en campaña → abajo, con números |

**El caso, con números.** Dieciséis procesos suman visitas a la misma ficha. En PostgreSQL, el techo
medido es de **4 373 por segundo**, y cada suma tarda 3,7 ms esperando turno; una campaña de 10 000
visitas por segundo sobre ese producto no cabe. **Por qué SQL falla ahí**: la fila es un único punto
de bloqueo, y el `COMMIT` durable alarga el tiempo que se tiene. **Cómo lo resuelve el modelo**:
`INCR vistas:PRD-00017` en Redis, 121 080 por segundo con los mismos dieciséis clientes, atómico y
sin bloqueos. **Qué se paga a cambio**: el contador vive en RAM; un corte puede llevarse hasta el
último segundo de incrementos con la configuración del corpus; no hay forma de preguntar «qué
productos pasan de mil visitas» sin mantener otra estructura; y el total hay que volcarlo a
PostgreSQL cada cierto tiempo si alguien lo quiere en un informe.

> **💡 Truco.** La alternativa que casi nadie propone antes de traer un segundo motor: **no escribir
> cada visita**. Sumar en la memoria del proceso y volcar cada segundo con un solo `UPDATE` que
> añade la suma acumulada convierte miles de escrituras calientes en una. Pierde lo mismo que Redis
> ante una caída —el último segundo— y no añade nada que operar.

---

## 6. ⚖️ Los productos

| Producto | Dónde vive el dato | Qué ofrece | Licencia o modelo |
|---|---|---|---|
| **Redis** | RAM, con registro en disco opcional | Tipos de valor, caducidad, scripts, *streams* | BSD-3-Clause hasta la 7.2; RSALv2 o SSPLv1 en la 7.4; y desde la 8.0, además, AGPLv3 |
| **Valkey** | RAM, con registro en disco opcional | Parte del código BSD de Redis | BSD, respaldado por la Linux Foundation |
| **Memcached** | RAM | Se define como «sistema de caché de objetos en memoria, distribuido» | Código abierto |
| **DynamoDB** | Disco, gestionado por AWS | Clave de partición y de orden, índices secundarios | Servicio de pago por uso |

- **La licencia de Redis cambió dos veces**, y es una pregunta de arquitectura, no de abogados: la
  7.4 dejó de ser código abierto según la definición de la OSI, y la 8.0 volvió a serlo añadiendo la
  AGPLv3 como opción. Valkey nació de ese primer cambio y mantiene la BSD. Qué se puede ofrecer como
  servicio a terceros depende de cuál se elija.
- **DynamoDB es clave-valor en disco**, no en memoria, y por eso tiene dos capítulos propios: su
  modelo de claves, en [`05`](05-dynamodb-modelo-y-claves.md), y su método de diseño. Del mismo
  modelo sale una consecuencia distinta: allí la clave no solo identifica, también **reparte** los
  datos entre máquinas.

> **Veredicto:** «clave-valor» dice cómo se pregunta, no dónde vive el dato: Redis y Valkey son RAM
> con disco de respaldo, DynamoDB es disco con una sola forma de preguntar.

---

## 7. 📜 Estándar, motor y convención

> **📜 Estándar o motor.** No existe un estándar de clave-valor como ISO/IEC 9075: cada producto es
> su propia especificación. Lo que se compara aquí es qué pieza de PostgreSQL hace el mismo trabajo.

| Afirmación | Estándar | PostgreSQL 18 | Redis 8.10 |
|---|---|---|---|
| Hay un lenguaje para preguntar por el contenido | SQL, 9075-2 | Sí | No: solo por clave, y `SCAN` por el nombre |
| El valor tiene tipos que el motor valida | Sí, el dominio de cada columna | Sí | Tipos de estructura; el contenido de una cadena es opaco |
| Leer un valor por su clave cuesta décimas de milisegundo | — | 0,064 ms medidos, con la página en caché | 0,047 ms de mediana |
| Muchas escrituras sobre un solo valor escalan | — | No: bloqueo de fila y espera al WAL, 4 373/s | Sí: un hilo sin bloqueos, 121 080/s |
| Una confirmación es durable al volver | La D de ACID | Sí, con `synchronous_commit = on` | No por defecto: AOF por segundo |
| Recorrer todas las claves es seguro en producción | — | — | `KEYS` bloquea el servidor; `SCAN` no |

**Convención, la que más se repite.** *«Redis es más rápido que PostgreSQL»* — para leer una fila
por su clave con la página en caché, no: medido, van a la par y con dieciséis clientes gana
PostgreSQL. Redis es más rápido **escribiendo muchas veces el mismo valor**, porque no bloquea ni
espera al disco en cada orden, y ese es el precio que conviene decir en voz alta.

---

## ⚠️ Errores frecuentes

| Se dice | Lo preciso |
|---|---|
| "Redis es más rápido que PostgreSQL" | En lectura por clave van a la par; Redis gana en escrituras concurrentes sobre un mismo valor, 121 080 frente a 4 373 por segundo |
| "Si falta una consulta, se hace un `KEYS`" | `KEYS` bloqueó el servidor 6 ms con cien mil claves; en producción se recorre con `SCAN` o se mantiene un índice propio |
| "`SCAN` vacío significa que no hay resultados" | Significa que ese tramo no tenía; el recorrido acaba cuando el cursor vuelve a `0` |
| "En Redis el valor no tiene tipo" | Tiene tipo de estructura, que decide qué órdenes admite; lo opaco es el contenido de una cadena |
| "Clave-valor es siempre en memoria" | DynamoDB es clave-valor en disco; lo que define el modelo es la forma de preguntar |
| "Más clientes, más escrituras por segundo" | Sobre una sola fila, en PostgreSQL, 16 clientes hicieron menos que uno |
| "Redis es código abierto, sin más" | BSD hasta la 7.2, no OSI en la 7.4, y AGPLv3 como opción desde la 8.0 |

---

## 📚 Para profundizar

- **Documentación** — Redis, «Understand Redis data types»: el mapa de tipos de valor.
  <https://redis.io/docs/latest/develop/data-types/>
- **Documentación** — Redis, «SCAN»: el cursor, `MATCH`, `COUNT` y sus garantías.
  <https://redis.io/docs/latest/commands/scan/>
- **Documentación** — Redis, «KEYS»: el aviso de que no es para producción.
  <https://redis.io/docs/latest/commands/keys/>
- **Documentación** — Redis, «INCR»: el contador atómico.
  <https://redis.io/docs/latest/commands/incr/>
- **Documentación** — Redis, «Licenses»: la historia de las tres licencias.
  <https://redis.io/legal/licenses/>
- **Herramienta** — PostgreSQL 18, «pgbench». <https://www.postgresql.org/docs/18/pgbench.html>
- **Herramienta** — Redis, «Redis benchmark».
  <https://redis.io/docs/latest/operate/oss_and_stack/management/optimization/benchmarks/>
- **Libro** — Martin Kleppmann, *Designing Data-Intensive Applications*, O'Reilly, 2017, capítulo 3:
  el índice hash, que es el corazón de un almacén clave-valor.

---

## 🧠 Preguntas

1. ¿Qué es un almacén clave-valor, en una frase? 🟢
2. ¿Qué devuelve `TYPE` sobre una clave de Redis, y para qué sirve saberlo? 🟢
3. ¿Qué significa que `SCAN` devuelva una lista vacía con un cursor distinto de `0`? 🟢
4. ¿Por qué `INCR` es atómico en Redis sin bloquear nada? 🟢
5. Distingue `KEYS` de `SCAN`: qué hace cada uno y qué cuesta. 🟡
6. Distingue `DEL` de `UNLINK`. 🟡
7. ¿Existe un estándar de clave-valor como el de SQL? ¿Qué consecuencia tiene al cambiar de
   producto? 🟡
8. ¿En qué se diferencia el tipo de un valor en Redis del dominio de una columna en SQL? 🟡
9. Redis y Valkey frente a DynamoDB: ¿qué tienen en común y dónde vive el dato en cada uno? 🟡
10. Un compañero dice que Redis es más rápido que PostgreSQL. Matiza con números: dónde es cierto y
    dónde no. 🟠
11. ¿Por qué dieciséis clientes sumando sobre la misma fila hacen menos escrituras por segundo que
    uno solo en PostgreSQL? 🟠
12. ¿Qué parte de la diferencia entre 4 373 y 121 080 escrituras por segundo es el bloqueo de fila y
    qué parte es la durabilidad? ¿Cómo lo separaste? 🟠
13. ¿Qué cuesta en espacio pasar los pedidos de PostgreSQL a Redis, y por qué esa memoria es más
    cara? 🟠
14. ¿Por qué el cambio de licencia de Redis es una pregunta de arquitectura? 🟠
15. Diseña cómo contarías las visitas por producto de una campaña de 10 000 visitas por segundo sin
    traer un segundo motor, y di qué pierdes. 🔴
16. Te piden «cuántos pedidos están `PAGADO`» sobre pedidos guardados en Redis como JSON. Da dos
    formas de responder, con lo que cuesta cada una, y cuál montarías antes de que te lo pidan. 🔴
17. Diagnostica: el servicio se queda cinco segundos sin respuesta de Redis una vez al día, siempre
    a la misma hora, y la CPU del servidor no sube. Da tres hipótesis en orden de probabilidad y qué
    mirarías para cada una. 🔴

---

**Anterior:** [README del bloque](README.md) · **Siguiente:** [`02`](02-redis-estructuras-y-ttl.md)
— las estructuras de Redis y la caducidad · **Relacionado:**
[`04/04`](../04-transacciones-y-concurrencia/04-bloqueos-e-interbloqueos.md) §2 — el bloqueo de fila
que serializa el contador ·
[`10/07`](../10-interfaz-con-los-lenguajes/07-clientes-de-redis-y-mongodb.md) §5 — el cliente, su
*pool* y sus tiempos de espera.
