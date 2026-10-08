# 02 — Redis: estructuras y caducidad

> Las seis estructuras de valor de Redis, cada una con el trabajo de la tienda que resuelve mejor
> que una tabla: el contador, el carrito, la categoría, los últimos vistos, el ranking de ventas y
> el registro de eventos. Después, las dos formas en que un dato desaparece de Redis sin que nadie
> lo borre: **la caducidad**, que eliges tú, y **el desalojo**, que elige el servidor cuando se
> queda sin memoria. **Asume leído:** [`01`](01-el-modelo-clave-valor.md), el modelo y por qué el
> valor tiene tipo. **Vigencia:** 26 de septiembre de 2026.

---

## Salto rápido

- [1. El problema](#1--el-problema) · [2. Cadenas y contadores](#2--cadenas-y-contadores) ·
  [3. Hash: el carrito](#3--hash-el-carrito)
- [4. Conjunto: la categoría](#4--conjunto-la-categoría) · [5. Lista: los últimos
  vistos](#5--lista-los-últimos-vistos)
- [6. Conjunto ordenado: el ranking](#6--conjunto-ordenado-el-ranking) · [7. Stream: los
  eventos](#7--stream-los-eventos)
- [8. La caducidad](#8--la-caducidad) · [9. Cuando se acaba la
  memoria](#9--cuando-se-acaba-la-memoria)
- [10. Estándar, motor y convención](#10--estándar-motor-y-convención) · [Errores
  frecuentes](#️-errores-frecuentes) · [Preguntas](#-preguntas)

---

## 1. 🎯 El problema

La portada de la tienda enseña los cinco productos más vendidos. En PostgreSQL, esa lista es una
agregación sobre las 3 500 000 líneas de pedido:

```text
tienda=# \timing on
El despliegue de duración está activado.
tienda=# SELECT p.codigo, sum(l.cantidad) AS unidades FROM pedido_lineas l JOIN productos p ON p.id = l.producto_id GROUP BY p.codigo ORDER BY unidades DESC LIMIT 5;
  codigo   | unidades
-----------+----------
 PRD-00017 |    60470
 PRD-00044 |    45687
 PRD-00003 |    45419
 PRD-00036 |    45365
 PRD-00018 |    45313
(5 filas)

Duración: 696,005 ms
```

Setecientos milisegundos por cada visita a la portada, para una respuesta que solo cambia cuando
alguien compra. Y la portada no es lo único: el carrito abierto de `CLI-00311` cambia una cantidad
cada pocos segundos, los productos que acaba de mirar son una lista que nunca debería pasar de diez,
y la sesión de quien no ha vuelto en una hora tendría que desaparecer sola.

En [`01`](01-el-modelo-clave-valor.md) el valor era una cadena opaca. **Redis no se queda ahí**:
cada tipo de valor trae las órdenes que lo modifican sin leerlo entero. Y al final, la pregunta que
casi nadie se hace hasta que pasa: **qué borra Redis por su cuenta, y cuándo**.

> **📝 Contexto.** Todo está corrido contra `bd-lab-redis`, con `redis:8.10.1`. Los miembros de cada
> estructura —qué productos hay en la categoría, quién encabeza el ranking, qué hay en el carrito—
> **salen de consultas reales a PostgreSQL**, como fija el documento de dominio: el carrito repite
> las líneas del último pedido de `CLI-00311`. §9 bajó `maxmemory` a propósito y lo devolvió a
> `0`. **Denso**: unas 540 líneas, por las nueve sesiones, una por estructura.

---

## 2. 🧱 Cadenas y contadores

**Qué es:** el tipo más simple, una secuencia de bytes bajo una clave. Es el de `pedido:PED-00042`
en `01`, y es también el contador: si la cadena contiene un entero, Redis sabe sumarle.

```text
127.0.0.1:6379> SET vistas:PRD-00017 0
OK
127.0.0.1:6379> INCRBY vistas:PRD-00017 5
(integer) 5
127.0.0.1:6379> OBJECT ENCODING vistas:PRD-00017
"int"
127.0.0.1:6379> SET pedido:PED-00042 "{\"estado\": \"PAGADO\", \"total\": \"3186.23\"}"
OK
127.0.0.1:6379> INCR pedido:PED-00042
(error) ERR value is not an integer or out of range
127.0.0.1:6379> SET pedido:PED-00042 "{\"estado\": \"ENVIADO\"}" NX
(nil)
127.0.0.1:6379> GET pedido:PED-00042
"{\"estado\": \"PAGADO\", \"total\": \"3186.23\"}"
```

- **`OBJECT ENCODING` dice `int`**: el tipo sigue siendo cadena; la codificación es cómo lo guarda
  por dentro, aquí como entero de máquina. **El error, a propósito**: `INCR` sobre un JSON falla.
- **`SET … NX` solo escribe si la clave no existe**, y devolvió `(nil)` porque existía. Es la pieza
  del candado de la estampida de [`l04`](../13-laboratorio/l04-redis-y-mongodb.md) §3.

**Quién lo manda:** **motor**. **Cuánto:** 35 bytes el contador con su clave; `INCR`, O(1). **Cuándo
sí:** contadores, candados, valores que se leen enteros. **Cuándo no:** objetos que cambian campo a
campo.

> **Veredicto:** una cadena con un entero dentro es el contador atómico más barato que hay; una
> cadena con JSON dentro es un valor que solo se puede reemplazar entero.

---

## 3. 🧱 Hash: el carrito

**Qué es:** un diccionario dentro de la clave, con campos y valores. El carrito de `CLI-00311` es un
hash de producto a cantidad, con las líneas de su último pedido:

```text
127.0.0.1:6379> HSET carrito:CLI-00311 PRD-04454 2 PRD-00082 3 PRD-03087 4 PRD-04044 5
(integer) 4
127.0.0.1:6379> HINCRBY carrito:CLI-00311 PRD-00082 1
(integer) 4
127.0.0.1:6379> HDEL carrito:CLI-00311 PRD-04044
(integer) 1
127.0.0.1:6379> HGETALL carrito:CLI-00311
1) "PRD-04454"
2) "2"
3) "PRD-00082"
4) "4"
5) "PRD-03087"
6) "4"
127.0.0.1:6379> HGET carrito:CLI-00311 PRD-00082
"4"
127.0.0.1:6379> OBJECT ENCODING carrito:CLI-00311
"listpack"
127.0.0.1:6379> MEMORY USAGE carrito:CLI-00311
(integer) 82
```

- **`HINCRBY` cambia un campo sin leer los demás**, y es atómico. En una cadena JSON sería leer,
  sumar y reescribir, y dos pestañas del mismo cliente se pisarían: la actualización perdida de
  [`04/01`](../04-transacciones-y-concurrencia/01-acid-con-precision.md), fuera de la base.
- **`listpack` es la codificación compacta**, un solo bloque de memoria: 82 bytes. Pasados 512
  campos o 64 bytes por valor, Redis la cambia por una tabla hash, más rápida y más grande.

**Quién lo manda:** **motor**. **Cuánto:** O(1) por campo; `HGETALL`, O(N) en campos. **Cuándo sí:**
campos que cambian por separado. **Cuándo no:** buscar carritos por producto, que sería otra
estructura mantenida a mano, como el índice de `01` §3.

> **Veredicto:** si el objeto cambia campo a campo, va en un hash; si siempre se lee y se escribe
> entero, una cadena basta.

---

## 4. 🧱 Conjunto: la categoría

**Qué es:** una colección sin orden y sin repetidos. `categoria:audio` tiene los 428 productos
activos de la categoría de `PRD-00017`, cargados con `SADD` por el `--pipe` de `01` §2:

```text
127.0.0.1:6379> SCARD categoria:audio
(integer) 428
127.0.0.1:6379> SISMEMBER categoria:audio PRD-00017
(integer) 1
127.0.0.1:6379> SISMEMBER categoria:audio PRD-04980
(integer) 0
127.0.0.1:6379> SADD categoria:audio PRD-00017
(integer) 0
127.0.0.1:6379> SRANDMEMBER categoria:audio 3
1) "PRD-01234"
2) "PRD-03092"
3) "PRD-00446"
127.0.0.1:6379> OBJECT ENCODING categoria:audio
"hashtable"
127.0.0.1:6379> MEMORY USAGE categoria:audio
(integer) 13694
```

- **`SISMEMBER` responde en O(1)**: `PRD-00017` está, `PRD-04980` —de `libros`, e inactivo— no.
- **`SADD` de un miembro que ya estaba devuelve `0`**: añadir es idempotente.
- **Pasó a `hashtable`** por tener más de 128 miembros: 13 694 bytes, unos 32 por código.

**Quién lo manda:** **motor**. **Cuánto:** O(1) por pertenencia; `SINTER`, el conjunto más pequeño
por el número de conjuntos. **Cuándo sí:** pertenencia, etiquetas, «quién ya hizo esto». **Cuándo
no:** si el orden importa.

> **Veredicto:** un conjunto responde «¿está?» en tiempo constante y no duplica; no recuerda en qué
> orden entraron las cosas.

---

## 5. 🧱 Lista: los últimos vistos

**Qué es:** una secuencia ordenada por inserción, con repetidos, que se empuja y se saca por los dos
extremos. Los últimos productos que miró `CLI-00311`, con los tres que sacó `SRANDMEMBER` arriba:

```text
127.0.0.1:6379> LPUSH vistos:CLI-00311 PRD-01234 PRD-03092 PRD-00446 PRD-00017
(integer) 4
127.0.0.1:6379> LPUSH vistos:CLI-00311 PRD-01234
(integer) 5
127.0.0.1:6379> LRANGE vistos:CLI-00311 0 -1
1) "PRD-01234"
2) "PRD-00017"
3) "PRD-00446"
4) "PRD-03092"
5) "PRD-01234"
127.0.0.1:6379> LTRIM vistos:CLI-00311 0 2
OK
127.0.0.1:6379> LRANGE vistos:CLI-00311 0 -1
1) "PRD-01234"
2) "PRD-00017"
3) "PRD-00446"
127.0.0.1:6379> OBJECT ENCODING vistos:CLI-00311
"listpack"
```

- **`LPUSH` mete por la izquierda**: el último de la línea queda primero.
- **La lista no deduplica**: `PRD-01234` aparece dos veces. Para «últimos vistos sin repetir» hay
  que quitar antes el que ya estaba, con `LREM`.
- **`LTRIM 0 2` la acota** a tres elementos. `LPUSH` seguido de `LTRIM` es el patrón de la lista con
  techo: nunca crece.

**Quién lo manda:** **motor**. **Cuánto:** O(1) por los extremos, O(N) por el medio. **Cuándo sí:**
historial acotado y colas sencillas, que son de [`04`](04-cache-invalidacion-y-estampida.md) §6.
**Cuándo no:** acceso por posición en listas largas, o sin repetidos.

> **Veredicto:** una lista es un historial con techo si cada `LPUSH` va con su `LTRIM`; sin él, es
> una fuga de memoria con forma de lista.

---

## 6. 🧱 Conjunto ordenado: el ranking

**Qué es:** un conjunto donde cada miembro lleva una **puntuación** y se guarda ordenado por ella.
`ranking:ventas` tiene los 5 000 productos con sus unidades, cargados del `GROUP BY` del §1, una
vez:

```text
127.0.0.1:6379> ZCARD ranking:ventas
(integer) 5000
127.0.0.1:6379> CONFIG SET slowlog-log-slower-than 0
OK
127.0.0.1:6379> SLOWLOG RESET
OK
127.0.0.1:6379> ZREVRANGE ranking:ventas 0 4 WITHSCORES
 1) "PRD-00017"
 2) "60470"
 3) "PRD-00044"
 4) "45687"
 5) "PRD-00003"
 6) "45419"
 7) "PRD-00036"
 8) "45365"
 9) "PRD-00018"
10) "45313"
127.0.0.1:6379> SLOWLOG GET 1
1) 1) (integer) 35
   2) (integer) 1790468865
   3) (integer) 8
   4) 1) "ZREVRANGE"
      2) "ranking:ventas"
      3) "0"
      4) "4"
      5) "WITHSCORES"
   5) "127.0.0.1:52476"
   6) ""
   7) (integer) 5
127.0.0.1:6379> CONFIG SET slowlog-log-slower-than 10000
OK
127.0.0.1:6379> ZREVRANK ranking:ventas PRD-00044
(integer) 1
127.0.0.1:6379> ZINCRBY ranking:ventas 400 PRD-00044
"46087"
127.0.0.1:6379> ZRANGE ranking:ventas 0 1 WITHSCORES
1) "PRD-05000"
2) "886"
3) "PRD-00632"
4) "1401"
127.0.0.1:6379> OBJECT ENCODING ranking:ventas
"skiplist"
127.0.0.1:6379> MEMORY USAGE ranking:ventas
(integer) 445585
```

- **Los mismos cinco que el `GROUP BY`, en 8 microsegundos** —la tercera línea del *slowlog*, con
  el umbral a cero como en `01` §3; 26 en otra corrida— frente a 696 ms: decenas de miles de veces
  menos, porque aquí no se suma nada al leer, se lee lo que ya está ordenado.
- **`ZINCRBY` suma y reordena**; `ZREVRANK` cuenta desde cero, y `ZRANGE` da el otro extremo.
- **`skiplist`**: según la documentación, es a la vez una *skip list* (lista con saltos) y una tabla
  hash; buscar un miembro es O(1) y moverlo, O(log N).

**Quién lo manda:** **motor**. **Cuánto:** 445 585 bytes, unos 89 por producto, y O(log N) por
venta. Y el precio que no sale en la sesión: **el ranking es una copia**. Cada venta hace su
`ZINCRBY` además de su `INSERT`, en dos motores y sin transacción que los ate: si el servicio muere
entre uno y otro, el ranking se desfasa hasta que alguien lo recalcule. **Cuándo sí:** rankings,
colas con prioridad, ventanas por tiempo. **Cuándo no:** si admite minutos de retraso, una vista
materializada refrescada cada cinco minutos da lo mismo sin segundo motor
([`02/07`](../02-sql/07-escritura-upsert-y-vistas.md)).

> **Veredicto:** el conjunto ordenado convierte un `GROUP BY` de setecientos milisegundos en una
> lectura de microsegundos, y lo cobra con una copia que tienes que mantener al día a mano.

---

## 7. 🧱 Stream: los eventos

**Qué es:** un registro de solo añadir; cada entrada es un pequeño hash con un identificador sacado
del reloj. Los tres eventos de `PED-00042` en `eventos_pedido`:

```text
127.0.0.1:6379> XADD eventos:pedidos * pedido PED-00042 tipo VALIDADO version 2
"1790468723505-0"
127.0.0.1:6379> XADD eventos:pedidos * pedido PED-00042 tipo PAGADO version 3
"1790468723514-0"
127.0.0.1:6379> XADD eventos:pedidos * pedido PED-00042 tipo PREPARADO version 1
"1790468723531-0"
127.0.0.1:6379> XLEN eventos:pedidos
(integer) 3
127.0.0.1:6379> XRANGE eventos:pedidos - + COUNT 1
1) 1) "1790468723505-0"
   2) 1) "pedido"
      2) "PED-00042"
      3) "tipo"
      4) "VALIDADO"
      5) "version"
      6) "2"
127.0.0.1:6379> XADD eventos:pedidos MAXLEN 2 * pedido PED-99999 tipo ANULADO version 1
"1790468723585-0"
127.0.0.1:6379> XLEN eventos:pedidos
(integer) 2
127.0.0.1:6379> XRANGE eventos:pedidos - + COUNT 1
1) 1) "1790468723531-0"
   2) 1) "pedido"
      2) "PED-00042"
      3) "tipo"
      4) "PREPARADO"
      5) "version"
      6) "1"
```

- **El `*` le pide el identificador a Redis**: milisegundos desde 1970 y un número de secuencia.
  Siempre crece, así que el orden de llegada va en el propio identificador.
- **`XRANGE - +` recorre de principio a fin**, por tramos con `COUNT`: O(log N) para situarse.
- **`MAXLEN 2` recorta al añadir**: tras el evento de `PED-99999`, las dos primeras entradas
  desaparecieron y la primera que queda es `PREPARADO`. Sin tope, un *stream* crece para siempre.

**Quién lo manda:** **motor**. **Cuánto:** O(1) por `XADD`, y en espacio lo que no se recorte.
**Cuándo sí:** eventos que varios consumidores leen a su ritmo; los **grupos de consumidores** son
de las colas de `04`. **Cuándo no:** como registro permanente de negocio, que es una tabla con su
durabilidad.

> **Veredicto:** un *stream* es una cola que no olvida al leer, con orden fijado por el reloj; se
> recorta con `MAXLEN` o se come la memoria.

---

## 8. 🧱 La caducidad

**Qué es:** una fecha pasada la cual Redis borra la clave. Tres sorpresas en una sesión:

```text
127.0.0.1:6379> SET vistas:PRD-00017 5 EX 60
OK
127.0.0.1:6379> INCR vistas:PRD-00017
(integer) 6
127.0.0.1:6379> TTL vistas:PRD-00017
(integer) 60
127.0.0.1:6379> SET vistas:PRD-00017 7
OK
127.0.0.1:6379> TTL vistas:PRD-00017
(integer) -1
127.0.0.1:6379> EXPIRE carrito:CLI-00311 3600
(integer) 1
127.0.0.1:6379> HEXPIRE carrito:CLI-00311 60 FIELDS 1 PRD-00082
1) (integer) 1
127.0.0.1:6379> HTTL carrito:CLI-00311 FIELDS 2 PRD-00082 PRD-04454
1) (integer) 60
2) (integer) -1
127.0.0.1:6379> PERSIST carrito:CLI-00311
(integer) 1
127.0.0.1:6379> TTL carrito:CLI-00311
(integer) -1
```

- **`INCR` conserva la caducidad; `SET` la borra**: el contador quedó con `TTL -1`, y la
  documentación de `SET` lo dice. Es el origen de las cachés que nunca expiran; se evita con
  `KEEPTTL` o poniendo `EX` en cada `SET`.
- **La caducidad es de la clave entera**, salvo en los hash: desde la 7.4, `HEXPIRE` caduca un campo
  suelto. `PRD-00082` se irá del carrito en 60 s y `PRD-04454` no tiene fecha.
- **`PERSIST` quita la caducidad**; `-2` significaría que la clave no existe, como en `l04` §2.

**Cómo se borra lo caducado**, según la documentación: de forma **pasiva**, al pedir una clave ya
caducada, y **activa**, muestreando en segundo plano. Hasta entonces, la clave ocupa memoria.

**Quién lo manda:** **motor**. **Cuánto:** unos bytes por clave y el muestreo, en el mismo hilo.
**Cuándo sí:** sesiones, cachés, límites. **Cuándo no:** datos que alguien espera encontrar mañana.

> **Veredicto:** la caducidad la pones tú y la quita cualquier `SET` sin `KEEPTTL`; revisa cada
> escritura de una clave con fecha.

---

## 9. 🩺 Cuando se acaba la memoria

**El desalojo** (*eviction*) borra lo que elige el servidor al llegar a `maxmemory`, según la
**política**. El corpus usa `noeviction`; la sesión baja el límite a cien kilobytes por encima del
uso de ese momento, con las siete claves del capítulo dentro:

```text
127.0.0.1:6379> CONFIG GET maxmemory-policy
1) "maxmemory-policy"
2) "noeviction"
127.0.0.1:6379> CONFIG SET maxmemory 9908736
OK
127.0.0.1:6379> SETRANGE pedido:PED-00042 300000 x
(integer) 300001
127.0.0.1:6379> SET vistas:PRD-00017 8
(error) OOM command not allowed when used memory > 'maxmemory'.
127.0.0.1:6379> CONFIG SET maxmemory-policy volatile-lru
OK
127.0.0.1:6379> SET vistas:PRD-00017 8
(error) OOM command not allowed when used memory > 'maxmemory'.
127.0.0.1:6379> CONFIG SET maxmemory-policy allkeys-lru
OK
127.0.0.1:6379> SET vistas:PRD-00017 8
OK
127.0.0.1:6379> SCAN 0 COUNT 100
1) "0"
2) 1) "eventos:pedidos"
   2) "carrito:CLI-00311"
   3) "vistas:PRD-00017"
   4) "vistos:CLI-00311"
127.0.0.1:6379> GETRANGE pedido:PED-00042 0 30
""
127.0.0.1:6379> CONFIG SET maxmemory 0
OK
127.0.0.1:6379> CONFIG SET maxmemory-policy noeviction
OK
```

- **El `SETRANGE` que rompe el límite entra**: Redis lo comprueba **al llegar la orden**, antes de
  ejecutarla, y aún no se había pasado. Falla la siguiente.
- **Con `noeviction`, toda escritura devuelve `OOM`**; las lecturas siguen.
- **Con `volatile-lru`, el mismo error**: solo desaloja claves **con caducidad**, y ninguna la
  tenía. Un Redis con `volatile-lru` y claves sin fecha se comporta como `noeviction`.
- **Con `allkeys-lru`, la escritura pasa y desaparecen tres claves**: `ranking:ventas`,
  `categoria:audio` y el propio `pedido:PED-00042` —por eso `GETRANGE` devuelve la cadena vacía—.
  `INFO stats` lo confirma con `evicted_keys:3`. El LRU es aproximado: la documentación explica que
  muestrea unas pocas claves —`maxmemory-samples`, 5— y desaloja la más antigua de la muestra.

**Quién lo manda:** **motor**, por configuración. **Cuánto:** **riesgo de pérdida** si desaloja, y
**disponibilidad** con `noeviction`. **Cuándo sí:** `allkeys-lru` o `allkeys-lfu` si todo se puede
regenerar. **Cuándo no:** desalojar datos sin copia, como un carrito que no está en PostgreSQL.

> **Veredicto:** decide para qué es cada Redis antes de elegir política: caché, `allkeys-lru`;
> datos, `noeviction` y alertas de memoria. Mezclar las dos cosas en la misma instancia es mezclar
> sus riesgos.

**Teardown del capítulo:** `DEL` de las cuatro claves que quedaron, y `DBSIZE` responde `0`.

---

## 10. 📜 Estándar, motor y convención

> **📜 Estándar o motor.** Las seis estructuras, sus órdenes, sus codificaciones y sus políticas son
> de Redis: no hay norma que las fije. La columna de PostgreSQL dice qué pieza hace el mismo trabajo
> allí.

| Afirmación | Estándar | PostgreSQL 18 | Redis 8.10 |
|---|---|---|---|
| Un «top N» se puede leer sin recalcular | — | Con una vista materializada, refrescada a mano | Conjunto ordenado: 8 µs frente a 696 ms del `GROUP BY` |
| Se puede cambiar un campo sin leer el objeto | `UPDATE` de una columna | Sí | Sí, en un hash; no en una cadena JSON |
| Un dato puede caducar solo | No | No: hace falta un proceso que borre | `EX`, `EXPIRE`, y por campo con `HEXPIRE` desde la 7.4 |
| Reescribir un valor conserva su caducidad | — | — | No: `SET` la borra salvo con `KEEPTTL`; `INCR` la conserva |
| El motor borra datos cuando se queda sin memoria | No | No: rechaza o usa disco | Según la política: `noeviction` rechaza, `allkeys-lru` desaloja |

**Convención, la que más se repite.** *«Redis es una caché»* — es una de las cosas que hace, y la
política por defecto de muchas instalaciones, `noeviction`, es justo la contraria a la de una caché.
Si se usa como caché, se configura como caché; si guarda carritos, se vigila como una base de datos.

---

## ⚠️ Errores frecuentes

| Se dice | Lo preciso |
|---|---|
| "Guardo el objeto en JSON y listo" | Si cambia campo a campo, en JSON cada cambio es leer y reescribir entero, y dos escritores se pisan; un hash lo cambia con `HINCRBY` |
| "`SET` respeta la caducidad que tenía la clave" | La borra; hace falta `KEEPTTL` o volver a poner `EX` |
| "Con `volatile-lru` Redis nunca se llena" | Solo desaloja claves con caducidad; sin ellas, rechaza escrituras como `noeviction` |
| "Una clave caducada ya no ocupa memoria" | Se borra al pedirla o cuando el muestreo activo la encuentra; hasta entonces ocupa |
| "La lista de últimos vistos no crece" | Crece para siempre si cada `LPUSH` no va seguido de `LTRIM` |
| "El ranking en Redis siempre cuadra con la base" | Es una copia sin transacción común; si el servicio cae entre el `INSERT` y el `ZINCRBY`, se desfasa |

---

## 📚 Para profundizar

- **Documentación** — Redis, «Understand Redis data types»: las seis estructuras y sus órdenes.
  <https://redis.io/docs/latest/develop/data-types/>
- **Documentación** — Redis, «Redis sorted sets»: la *skip list*, la tabla hash y los rankings.
  <https://redis.io/docs/latest/develop/data-types/sorted-sets/>
- **Documentación** — Redis, «Redis Streams»: identificadores, `XRANGE` y recorte.
  <https://redis.io/docs/latest/develop/data-types/streams/>
- **Documentación** — Redis, «EXPIRE»: las dos formas en que se borra una clave caducada.
  <https://redis.io/docs/latest/commands/expire/>
- **Documentación** — Redis, «SET»: las opciones `NX`, `EX` y `KEEPTTL`.
  <https://redis.io/docs/latest/commands/set/>
- **Documentación** — Redis, «HEXPIRE»: la caducidad por campo de hash.
  <https://redis.io/docs/latest/commands/hexpire/>
- **Documentación** — Redis, «Key eviction»: las políticas y el LRU aproximado.
  <https://redis.io/docs/latest/develop/reference/eviction/>

---

## 🧠 Preguntas

1. ¿Qué significa que `OBJECT ENCODING` devuelva `int` para una clave de tipo cadena? 🟢
2. ¿Qué hace `SET … NX`, y para qué patrón sirve? 🟢
3. ¿Qué devuelve `SADD` al añadir un miembro que ya estaba, y por qué importa? 🟢
4. ¿Qué es un conjunto ordenado, y qué dos estructuras lo sostienen por dentro? 🟢
5. ¿Qué significan `TTL -1` y `TTL -2`? 🟢
6. Distingue tipo y codificación en Redis, con el ejemplo del conjunto que pasa de `listpack` a
   `hashtable`. ¿Lo fija el estándar o es cosa del motor? 🟡
7. Distingue caducidad de desalojo: quién decide cada uno y cuándo ocurre. ¿Lo fija el estándar o es
   cosa del motor? 🟡
8. ¿Qué diferencia hay entre `INCR` y `SET` respecto a la caducidad de la clave? 🟡
9. Lista frente a conjunto para «los últimos productos vistos»: qué da cada uno y qué patrón acota
   la lista. 🟡
10. ¿Tiene PostgreSQL algo equivalente a la caducidad de una clave de Redis? ¿Qué harías allí para
    que una sesión desapareciera sola? 🟡
11. ¿Por qué el carrito va mejor en un hash que en una cadena JSON cuando dos pestañas lo cambian a
    la vez? 🟠
12. El ranking en Redis tarda 8 µs y el `GROUP BY`, 696 ms. ¿Qué se paga por esa diferencia, y
    cuándo elegirías una vista materializada en su lugar? 🟠
13. ¿Por qué el `SETRANGE` que pasa `maxmemory` se ejecuta, y falla la orden siguiente? 🟠
14. Un equipo configura `volatile-lru` y aun así recibe `OOM`. ¿Por qué? 🟠
15. ¿Por qué una clave caducada puede seguir ocupando memoria? 🟠
16. Diseña las estructuras de Redis para el carrito y los últimos vistos de un cliente y para el
    ranking de la tienda, con la caducidad de cada una y la política de memoria de la instancia. 🔴
17. Diagnostica: las claves de caché de fichas de producto dejaron de caducar tras un despliegue y
    la memoria no para de crecer. Da la causa más probable y cómo la confirmarías. 🔴
18. Escribe la secuencia de órdenes para registrar una venta de `PRD-00017` en el ranking y en los
    últimos vistos de `CLI-00311`, y di qué pasa si el servicio muere a mitad. 🔴

---

**Anterior:** [`01`](01-el-modelo-clave-valor.md) — el modelo clave-valor · **Siguiente:**
[`03`](03-atomicidad-scripts-y-durabilidad.md) — atomicidad, scripts y durabilidad ·
**Relacionado:** [`l04`](../13-laboratorio/l04-redis-y-mongodb.md) §2 — la caché con caducidad, en
un lab · [`02/07`](../02-sql/07-escritura-upsert-y-vistas.md) — la vista materializada, la
alternativa sin segundo motor.
