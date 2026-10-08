# 04 — Caché, invalidación y estampida

> Los trabajos de Redis que más se preguntan en una entrevista de backend, con lo que se rompe en
> cada uno. La caché y sus cuatro patrones, con la carrera de *cache-aside* provocada de verdad: el
> pedido `ENVIADO` en la base y `PAGADO` en la caché durante cinco minutos. La estampida y sus tres
> mitigaciones, y la variante de las mil claves que caducan en el mismo segundo. La limitación de
> tasa y las colas, con el consumidor que cae sin confirmar. **Asume leído:**
> [`03`](03-atomicidad-scripts-y-durabilidad.md), los scripts y las *Functions*, y
> [`l04`](../13-laboratorio/l04-redis-y-mongodb.md) §3, donde la estampida ya se provocó y se
> corrigió con un candado. **Vigencia:** 26 de septiembre de 2026.

---

## Salto rápido

- [1. El problema](#1--el-problema) · [2. Los cuatro patrones de
  caché](#2--los-cuatro-patrones-de-caché)
- [3. La carrera de cache-aside](#3--la-carrera-de-cache-aside) · [4. La estampida y sus tres
  mitigaciones](#4--la-estampida-y-sus-tres-mitigaciones)
- [5. Limitación de tasa](#5--limitación-de-tasa) · [6. Colas: la lista y el
  stream](#6--colas-la-lista-y-el-stream)
- [7. Estándar, motor y convención](#7--estándar-motor-y-convención) · [Errores
  frecuentes](#️-errores-frecuentes) · [Preguntas](#-preguntas)

---

## 1. 🎯 El problema

Un cliente llama al soporte: su pedido `PED-00042` salió del almacén hace tres minutos —lo dice el
correo de envío— y la web sigue diciendo `PAGADO`. En la base de datos está `ENVIADO`. Nadie ha
cometido un error visible: el servicio que actualizó el estado **borró la caché después de
escribir**, como manda el manual. Y aun así, la caché tiene el estado viejo, y lo va a tener cinco
minutos más.

Es el defecto más común de una caché, y no es un fallo de Redis: es una carrera entre dos servicios
que se puede reproducir paso a paso, y se reproduce en §3. Detrás vienen los otros tres trabajos
que Redis hace en casi cualquier backend —aguantar la estampida cuando una clave caduca, limitar
cuántas peticiones hace un cliente y repartir trabajo en una cola—, cada uno con la forma exacta en
que falla.

> **📝 Contexto.** Todo está corrido contra `bd-lab-redis` y `bd-lab-postgres`. La carrera de §3 usa
> **cuatro terminales abiertas a la vez** —la conexión a PostgreSQL y la de Redis de cada servicio—
> y mueve `PED-00042` a `ENVIADO` con un `UPDATE` que se revierte exacto al terminar, con la regla
> del bloque 04: `pedidos` no tiene disparadores y `actualizado_en` sigue nulo. La estampida con
> cincuenta hilos no se repite: sus cifras son las de `l04` §3. En §4, los segundos de la muestra
> son aproximados, porque cada lectura de `DBSIZE` tarda algo más de un segundo. **Longitud:** unas
> 460 líneas; capítulo normal que pasa el disparador de 400.

---

## 2. 🧱 Los cuatro patrones de caché

**Qué es:** una caché guarda una copia del resultado de algo caro para no repetirlo. Lo que
distingue a los patrones es **quién escribe en la caché y cuándo**:

| Patrón | Quién rellena la caché | Cuándo se entera la caché de un cambio | Lo que se paga |
|---|---|---|---|
| ***Cache-aside*** (caché al lado) | La aplicación, al fallar la lectura | Cuando la aplicación borra la clave, o cuando caduca | La carrera de §3 y la estampida de §4 |
| ***Read-through*** | La propia caché, que sabe leer la base | Igual que *cache-aside* | Una capa que conoce la base; Redis no lo hace solo |
| ***Write-through*** | La aplicación, al escribir: base y caché a la vez | En la misma operación que la escritura | Dos escritores pueden dejar la caché en el orden contrario al de la base |
| ***Write-behind*** | La aplicación escribe en la caché, y otro proceso vuelca a la base | La caché es la primera en saberlo | La base va por detrás: si la caché cae, se pierde lo no volcado |

- **Redis no implementa ninguno**: es un almacén; el patrón lo escribe el código que lo usa. El
  *cache-aside* es el más común porque no obliga a nada más que a un `GET` y un `SET`.
- **Sesiones, contadores y rankings no son caché**: son datos que viven en Redis, como en
  [`02`](02-redis-estructuras-y-ttl.md). La diferencia importa para la política de memoria de `02`
  §9: una caché se puede desalojar; una sesión, no sin echar al usuario.

**Quién lo manda:** **convención**. Los nombres vienen de la literatura de arquitectura, no de
ningún motor. **Cuánto:** cada patrón mueve el riesgo a un sitio distinto, y ninguno lo elimina.
**Cuándo sí:** lecturas mucho más frecuentes que escrituras, y un valor que admite quedarse viejo
unos segundos. **Cuándo no:** un dato que no puede estar viejo ni un instante —el saldo que decide
un cobro—, que se lee de la base.

> **Veredicto:** una caché es una copia, y toda copia se desfasa; el patrón decide dónde y durante
> cuánto, no si ocurre.

---

## 3. 🩺 La carrera de cache-aside

Dos servicios y el pedido del §1. A atiende una lectura; B cambia el estado. Cada uno tiene su
conexión a PostgreSQL y la suya a Redis, las cuatro abiertas a la vez y en el orden en que
ocurrió:

```text
-- servicio A                                        -- servicio B
127.0.0.1:6379> GET pedido:PED-00042
(nil)
tienda=# SELECT estado, total FROM pedidos WHERE codigo = 'PED-00042';
 estado |  total
--------+---------
 PAGADO | 3186.23
(1 fila)

                                                     tienda=# UPDATE pedidos SET estado = 'ENVIADO' WHERE codigo = 'PED-00042';
                                                     UPDATE 1
                                                     127.0.0.1:6379> DEL pedido:PED-00042
                                                     (integer) 0
127.0.0.1:6379> SET pedido:PED-00042 "{\"estado\": \"PAGADO\", \"total\": \"3186.23\"}" EX 300
OK
tienda=# SELECT estado FROM pedidos WHERE codigo = 'PED-00042';
 estado
---------
 ENVIADO
(1 fila)

127.0.0.1:6379> GET pedido:PED-00042
"{\"estado\": \"PAGADO\", \"total\": \"3186.23\"}"
127.0.0.1:6379> TTL pedido:PED-00042
(integer) 300
```

- **A falla en la caché y lee la base: `PAGADO`.** Entre esa lectura y su `SET`, B actualiza el
  pedido y borra la clave, que es lo correcto. Pero **el `DEL` de B devuelve `0`**: no había nada
  que borrar, porque A aún no había escrito.
- **A escribe entonces lo que leyó**, que ya es viejo. La base dice `ENVIADO`; la caché, `PAGADO`,
  con 300 s por delante. Nadie volverá a borrarla, porque B ya hizo su parte.
- **La ventana es corta y aparece con volumen**: basta que la lectura de A dure unos milisegundos
  más de lo normal —una pausa del recolector de basura, una consulta lenta— para que un `UPDATE`
  caiga dentro. Con miles de lecturas por segundo, ocurre a diario.

**Qué la acota, de más barata a más cara:**

- **La caducidad**, que ya estaba: el daño dura, como mucho, el `EX`. Es el motivo de que toda clave
  de caché lleve fecha, y corta.
- **Borrar dos veces**: B borra tras escribir, y otra vez unos cientos de milisegundos después. La
  segunda borra lo que A haya escrito en medio. Estrecha la ventana, no la cierra.
- **Escribir en la caché solo si el dato es más nuevo**: guardar con el valor una versión o una
  marca de tiempo de la fila y hacer el `SET` con un script que compare, como el del candado de
  `03` §5. Es la única de las tres que cierra la carrera, y pide que la fila tenga una versión
  fiable, como la columna de
  [`04/05`](../04-transacciones-y-concurrencia/05-optimista-pesimista-y-transacciones-largas.md) §3.

**Quién lo manda:** **convención y aplicación**: ni Redis ni PostgreSQL saben que uno es copia del
otro. **Cuánto:** en **riesgo** de servir un dato viejo durante lo que dure la caducidad. **Cuándo
sí:** *cache-aside* con caducidad corta, para todo lo que admita segundos de retraso. **Cuándo no:**
estados que disparan decisiones —cobrar, enviar, reembolsar—, que se leen de la base.

**Teardown de esta sección:** B devolvió el pedido a `PAGADO` con el `UPDATE` inverso y borró la
clave: `PED-00042` sigue `PAGADO`, con `actualizado_en` nulo.

> **Veredicto:** en *cache-aside*, «borrar después de escribir» no basta, porque el que lee puede
> escribir lo viejo después de tu borrado; la caducidad acota el daño y la versión lo evita.

---

## 4. 🧱 La estampida y sus tres mitigaciones

**Qué es:** cuando una clave muy leída caduca, todas las peticiones que llegan en ese instante
fallan en la caché a la vez y van todas a la base. En
[`l04`](../13-laboratorio/l04-redis-y-mongodb.md) §3 se provocó con cincuenta hilos: **50 consultas
a PostgreSQL** para una sola respuesta, y **1** con un candado `SET NX`. Un artículo de VLDB sobre
el problema, de Vattani, Chierichetti y Lowenstein, enumera tres mitigaciones:

- **Recálculo externo**: un proceso aparte regenera la clave antes de que caduque, y las peticiones
  nunca la encuentran vacía. Lo que cuesta es ese proceso: hay que operarlo y decirle qué claves
  regenerar, incluso las que nadie va a pedir.
- **Candado**: la primera petición que falla toma un candado y regenera; las demás esperan o sirven
  un valor viejo. Es la de `l04`. Cuesta una escritura más por fallo y una caducidad del candado
  bien elegida: si quien lo tiene muere, nadie regenera hasta que caduque.
- **Expiración anticipada probabilística**: cada petición decide por su cuenta, con una
  probabilidad que crece al acercarse la caducidad, regenerar la clave antes de tiempo. Así, la
  regeneración ocurre casi siempre una vez y antes de que la clave desaparezca. El artículo
  demuestra que una decisión con distribución exponencial —su algoritmo XFetch— es óptima y no
  necesita saber cuántas peticiones llegan. No tiene coste de operación; su precio es regenerar un
  poco antes de lo necesario.

La estampida tiene una variante que ninguna de las tres cubre: **muchas claves distintas que
caducan en el mismo instante**, porque se crearon juntas. Mil pedidos cargados en la caché a la vez
con `EX 10`, y la cuenta de claves segundo a segundo; después, los mismos mil con una caducidad al
azar entre 7 y 13 s:

```text
     caducidad fija, EX 10        caducidad al azar, EX 7-13
 0 s  1000                     0 s  1000
 1 s  1000                     1 s  1000
 2 s  1000                     2 s  1000
 3 s  1000                     3 s  1000
 4 s  1000                     4 s  1000
 5 s  1000                     5 s  1000
 6 s  1000                     6 s  1000
 7 s  1000                     7 s  974
 8 s  1000                     8 s  710
 9 s  1000                     9 s  671
10 s  0                       10 s  436
11 s  0                       11 s  302
12 s  0                       12 s  153
13 s  0                       13 s  0
14 s  0                       14 s  0
15 s  0                       15 s  0
```

- **Con caducidad fija, las mil desaparecen en el mismo segundo**: mil fallos a la vez, mil
  consultas a la base a la vez. Es la estampida de `l04` repartida en mil claves en vez de
  concentrada en una.
- **Con azar, el vaciado se reparte en seis segundos**. La carga de la base es la misma en total,
  pero llega en goteo.
- Las claves se cargaron desde PostgreSQL con `SET … EX` por el `redis-cli --pipe` de `01` §2; la
  caducidad al azar sale de `7 + floor(random() * 7)` tras un `setseed(0.42)`, para que el reparto
  sea el mismo en cada corrida. Las dos columnas son dos corridas, una detrás de otra.

**Quién lo manda:** **convención y aplicación**; Redis solo da las piezas —`SET NX`, `EX`—.
**Cuánto:** el candado, una escritura y una espera por fallo; el recálculo externo, un proceso que
operar; la anticipada, regenerar antes de tiempo; el azar, nada. **Cuándo sí:** candado o anticipada
para una clave muy leída y cara de regenerar; azar siempre que se creen muchas claves juntas.
**Cuándo no:** claves baratas de regenerar o poco leídas, donde la estampida no existe.

> **Veredicto:** una clave caliente necesita que solo una petición la regenere; muchas claves
> creadas juntas necesitan que no caduquen juntas. Son dos problemas y dos soluciones.

---

## 5. 🧱 Limitación de tasa

**Qué es:** contar cuántas peticiones hace un cliente en una ventana de tiempo y rechazar las que
pasen del límite. En Redis es un contador con caducidad, y tiene que ser atómico: sumar y poner la
fecha en un solo paso. Aquí, con la *Function* que `03` §5 dejó presentada, una ventana de 60 s y
un límite de cinco que aplica el servicio:

```text
127.0.0.1:6379> FUNCTION LOAD "#!lua name=tienda\nredis.register_function('limite', function(keys, args) local n = redis.call('INCR', keys[1]) if n == 1 then redis.call('EXPIRE', keys[1], args[1]) end return n end)"
"tienda"
127.0.0.1:6379> FCALL limite 1 limite:CLI-00311 60
(integer) 1
127.0.0.1:6379> FCALL limite 1 limite:CLI-00311 60
(integer) 2
127.0.0.1:6379> FCALL limite 1 limite:CLI-00311 60
(integer) 3
127.0.0.1:6379> FCALL limite 1 limite:CLI-00311 60
(integer) 4
127.0.0.1:6379> FCALL limite 1 limite:CLI-00311 60
(integer) 5
127.0.0.1:6379> FCALL limite 1 limite:CLI-00311 60
(integer) 6
127.0.0.1:6379> TTL limite:CLI-00311
(integer) 60
127.0.0.1:6379> FUNCTION LIST LIBRARYNAME tienda
1) 1) "library_name"
   2) "tienda"
   3) "engine"
   4) "LUA"
   5) "functions"
   6) 1) 1) "name"
         2) "limite"
         3) "description"
         4) (nil)
         5) "flags"
         6) (empty array)
```

- **La sexta llamada devuelve `6`**, y el servicio la rechaza con un `429`. El contador lo lleva
  Redis; la decisión, el servicio.
- **La caducidad solo se pone en la primera llamada** —`if n == 1`—, así que la ventana empieza con
  la primera petición y no se alarga con cada una. Con `INCR` y `EXPIRE` en dos órdenes sueltas, un
  proceso que muriera entre las dos dejaría el contador sin fecha: el cliente bloqueado para
  siempre.
- **`FUNCTION LOAD` guarda la biblioteca en el servidor**, y `FCALL` la llama por su nombre. Tras un
  reinicio de Redis, siguió en `FUNCTION LIST`; es lo que la distingue de la caché de `EVALSHA`.

**El defecto de la ventana fija**: cinco peticiones en el último segundo de una ventana y cinco en
el primero de la siguiente son diez en dos segundos, todas aceptadas. La **ventana deslizante** lo
corrige guardando cada petición en un conjunto ordenado con su marca de tiempo como puntuación:
`ZREMRANGEBYSCORE` quita las de hace más de 60 s, `ZADD` añade la actual y `ZCARD` cuenta, las tres
en el mismo script. Cuesta una entrada por petición en vez de un contador por cliente.

**Quién lo manda:** **motor** las piezas; el algoritmo es **convención**. **Cuánto:** un contador de
unos bytes por cliente y ventana, y una llamada a Redis por petición. **Cuándo sí:** límites por
cliente o por clave de API, compartidos entre todas las instancias del servicio. **Cuándo no:** con
una sola instancia, un contador en memoria del proceso basta y no añade un viaje de red.

**Teardown de esta sección:** `FUNCTION DELETE tienda` y `DEL limite:CLI-00311`.

> **Veredicto:** la limitación de tasa es un `INCR` con caducidad puesta en el mismo paso; la
> ventana fija deja pasar el doble en el borde, y la deslizante lo paga en memoria.

---

## 6. 🧱 Colas: la lista y el stream

**Qué es:** una cola reparte trabajo entre procesos que no se conocen. Redis ofrece dos formas, y
difieren en lo único que importa: **qué pasa con un mensaje si el consumidor muere mientras lo
procesa**.

**Con una lista**, el productor hace `LPUSH` y el consumidor `BRPOP`, que espera bloqueado hasta que
haya algo. El mensaje **sale de la lista al entregarse**: si el consumidor muere antes de
terminarlo, se pierde. `BLMOVE` lo mueve a una segunda lista de «en proceso», de la que el
consumidor lo quita al acabar; así sobrevive, pero recuperar lo abandonado es código tuyo.

**Con un *stream* y un grupo de consumidores**, Redis lleva la cuenta: cada mensaje entregado queda
pendiente, a nombre de su consumidor, hasta que este lo confirma. `w1` espera bloqueado; el
productor publica dos eventos; `w1` recibe el primero y cae sin confirmar; `w2` recibe el segundo y
después reclama el de `w1`:

```text
-- consumidor w1                                     -- productor y consumidor w2
127.0.0.1:6379> XGROUP CREATE eventos:pedidos facturacion $ MKSTREAM
OK
127.0.0.1:6379> XREADGROUP GROUP facturacion w1 COUNT 1 BLOCK 0 STREAMS eventos:pedidos >
-- ⏸ bloqueado: no hay mensajes
                                                     127.0.0.1:6379> XADD eventos:pedidos * pedido PED-00042 tipo PAGADO
                                                     "1790470338091-0"
1) 1) "eventos:pedidos"
   2) 1) 1) "1790470338091-0"
         2) 1) "pedido"
            2) "PED-00042"
            3) "tipo"
            4) "PAGADO"
(1.13s)
-- w1 cae aquí, sin XACK
                                                     127.0.0.1:6379> XADD eventos:pedidos * pedido PED-99999 tipo ANULADO
                                                     "1790470338404-0"
                                                     127.0.0.1:6379> XREADGROUP GROUP facturacion w2 COUNT 1 STREAMS eventos:pedidos >
                                                     1) 1) "eventos:pedidos"
                                                        2) 1) 1) "1790470338404-0"
                                                              2) 1) "pedido"
                                                                 2) "PED-99999"
                                                                 3) "tipo"
                                                                 4) "ANULADO"
                                                     127.0.0.1:6379> XACK eventos:pedidos facturacion 1790470338404-0
                                                     (integer) 1
                                                     127.0.0.1:6379> XPENDING eventos:pedidos facturacion
                                                     1) (integer) 1
                                                     2) "1790470338091-0"
                                                     3) "1790470338091-0"
                                                     4) 1) 1) "w1"
                                                           2) "1"
                                                     127.0.0.1:6379> XAUTOCLAIM eventos:pedidos facturacion w2 1000 0-0 COUNT 1
                                                     1) "0-0"
                                                     2) 1) 1) "1790470338091-0"
                                                           2) 1) "pedido"
                                                              2) "PED-00042"
                                                              3) "tipo"
                                                              4) "PAGADO"
                                                     3) (empty array)
                                                     127.0.0.1:6379> XACK eventos:pedidos facturacion 1790470338091-0
                                                     (integer) 1
                                                     127.0.0.1:6379> XPENDING eventos:pedidos facturacion
                                                     1) (integer) 0
                                                     2) (nil)
                                                     3) (nil)
                                                     4) (nil)
```

- **`>` pide mensajes nunca entregados a este grupo**, y `BLOCK 0` espera sin límite. `w1` recibió
  el de `PED-00042` en cuanto se publicó; el `(1.13s)` es lo que llevaba esperando.
- **`XPENDING` es la lista de pendientes** —la PEL, *Pending Entries List*—: un mensaje, a nombre de
  `w1`, entregado una vez y sin confirmar.
- **`XAUTOCLAIM … w2 1000` transfiere a `w2` los pendientes con más de 1 000 ms sin actividad**.
  `w2` lo procesa y lo confirma, y la lista de pendientes queda vacía.
- **La entrega es «al menos una vez»**: si `w1` sí terminó su trabajo y murió justo antes del
  `XACK`, el evento se procesa dos veces. El consumidor tiene que ser idempotente —comprobar si ya
  facturó `PED-00042` antes de facturarlo—.

**Quién lo manda:** **motor**. **Cuánto:** el *stream* guarda los mensajes hasta que se recorten, y
cada grupo su lista de pendientes; en memoria, y con la durabilidad de `03` §6. **Cuándo sí:** colas
de trabajo con varios consumidores y reintentos, cuando ya se opera Redis. **Cuándo no:** si el
trabajo nace de una transacción de PostgreSQL, la cola en la misma base con `SKIP LOCKED` de
[`04/04`](../04-transacciones-y-concurrencia/04-bloqueos-e-interbloqueos.md) §4 va en la misma
transacción que el cambio, y ningún mensaje se pierde entre los dos motores.

**Teardown de esta sección:** `DEL eventos:pedidos`, que borra el *stream* con su grupo.

> **Veredicto:** una lista entrega y olvida; un *stream* con grupo entrega y espera confirmación.
> Con cualquiera de los dos, el consumidor tiene que aguantar el mismo mensaje dos veces.

---

## 7. 📜 Estándar, motor y convención

> **📜 Estándar o motor.** Los patrones de caché, la estampida y la limitación de tasa son
> **convención** de arquitectura; Redis pone las piezas y PostgreSQL no sabe que existe una copia.

| Afirmación | Estándar | PostgreSQL 18 | Redis 8.10 |
|---|---|---|---|
| La caché se entera sola de un cambio en la base | — | No: no avisa a nadie | No: es un almacén, no un observador |
| Borrar la clave tras escribir evita datos viejos | — | — | No: la lectura concurrente puede reescribir lo viejo, y lo hizo |
| Una clave caliente que caduca dispara la base | — | La recibe entera: 50 consultas en `l04` | Lo evita un candado con `SET NX`, o regenerar antes |
| Muchas claves creadas juntas caducan juntas | — | — | Sí, en el mismo segundo; el azar en `EX` lo reparte |
| Sumar y poner caducidad es un solo paso | — | — | Solo en un script o una *Function* |
| Un mensaje entregado sobrevive a la caída del consumidor | — | Con `SKIP LOCKED` y la transacción, sí | Con grupos de *stream*, queda pendiente; con `BRPOP`, se pierde |

**Convención, la que más se repite.** *«Borra la caché cuando actualices la base y siempre estará
al día»* — la sesión de §3 lo desmiente con cuatro terminales. Borrar después de escribir reduce el
problema; la caducidad lo acota; solo comparar versiones lo cierra.

---

## ⚠️ Errores frecuentes

| Se dice | Lo preciso |
|---|---|
| "Si borro la clave tras el `UPDATE`, la caché nunca queda vieja" | Una lectura que empezó antes puede escribir el valor viejo después del borrado; quedó 300 s en la sesión |
| "La caché sin caducidad es más eficiente" | Sin caducidad, cualquier carrera deja un dato viejo para siempre; la caducidad es el límite del daño |
| "La estampida se arregla con un candado" | Esa es una de tres; y el candado no ayuda cuando son mil claves distintas que caducan juntas |
| "`INCR` y luego `EXPIRE` bastan para limitar la tasa" | Si el proceso muere entre las dos, el contador queda sin fecha y el cliente bloqueado para siempre |
| "Con `BRPOP` la cola es fiable" | El mensaje sale al entregarse; si el consumidor cae, se pierde |
| "Un grupo de consumidores entrega cada mensaje una vez" | Al menos una vez: un consumidor que cae antes del `XACK` provoca una segunda entrega |
| "Redis hace *write-through*" | Redis no hace ningún patrón; los escribe tu código |

---

## 📚 Para profundizar

- **Artículo** — Andrea Vattani, Flavio Chierichetti y Keegan Lowenstein, «Optimal Probabilistic
  Cache Stampede Prevention», *Proceedings of the VLDB Endowment*, vol. 8, n.º 8, 2015: las tres
  mitigaciones y el algoritmo XFetch. <https://www.vldb.org/pvldb/vol8/p886-vattani.pdf>
- **Documentación** — Redis, «Redis Streams»: grupos de consumidores y la lista de pendientes.
  <https://redis.io/docs/latest/develop/data-types/streams/>
- **Documentación** — Redis, «XAUTOCLAIM»: reclamar los mensajes abandonados.
  <https://redis.io/docs/latest/commands/xautoclaim/>
- **Documentación** — Redis, «XPENDING». <https://redis.io/docs/latest/commands/xpending/>
- **Documentación** — Redis, «BLMOVE»: la lista con una segunda lista de trabajo en curso.
  <https://redis.io/docs/latest/commands/blmove/>
- **Documentación** — Redis, «FUNCTION LOAD»: la biblioteca que se guarda en el servidor.
  <https://redis.io/docs/latest/commands/function-load/>
- **Libro** — Martin Kleppmann, *Designing Data-Intensive Applications*, O'Reilly, 2017, capítulo
  11: colas, entrega al menos una vez e idempotencia.

---

## 🧠 Preguntas

1. ¿Qué es *cache-aside*, en una frase? 🟢
2. ¿Qué es una estampida de caché? 🟢
3. ¿Qué es la lista de pendientes de un grupo de consumidores de un *stream*? 🟢
4. Distingue *cache-aside* de *write-through*: quién escribe en la caché y cuándo. ¿Qué parte es del
   motor y qué parte es convención? 🟡
5. Distingue una sesión guardada en Redis de una entrada de caché, y di por qué importa para la
   política de memoria. 🟡
6. ¿Implementa Redis algún patrón de caché, o es convención de la aplicación? ¿Y PostgreSQL avisa
   de algún cambio a la caché? 🟡
7. Distingue una cola hecha con `BRPOP` de una hecha con un grupo de consumidores de un *stream*:
   qué pasa si el consumidor cae. 🟡
8. Distingue la ventana fija de la ventana deslizante en la limitación de tasa. 🟡
9. En la sesión de §3, ¿por qué el `DEL` del servicio B devolvió `0`, y por qué eso es la clave de
   la carrera? 🟠
10. De las tres formas de acotar la carrera de *cache-aside*, ¿cuál la cierra de verdad y qué
    necesita la fila para que funcione? 🟠
11. ¿Por qué una caducidad al azar no ayuda con una sola clave caliente, y un candado no ayuda con
    mil claves que caducan juntas? 🟠
12. ¿Por qué la limitación de tasa pone la caducidad solo cuando el contador vale 1, y qué pasa si
    `INCR` y `EXPIRE` van en órdenes separadas? 🟠
13. Un grupo de consumidores entrega «al menos una vez». ¿Qué obliga eso a hacer al consumidor, con
    un ejemplo de la tienda? 🟠
14. ¿Cuándo pondrías la cola de trabajo en PostgreSQL con `SKIP LOCKED` en vez de en Redis? 🟠
15. Diagnostica: un proceso precarga la caché de las fichas de producto cada día a las 9:00, y cada
    día a las 9:10 la base recibe un pico de consultas de fichas. Da la causa más probable, cómo la
    confirmarías y la corrección. 🔴
16. Diseña la caché de la ficha de `PED-00042` para que un cambio de estado nunca quede tapado por
    una lectura concurrente: qué guardas, qué script usas y qué pasa con la caducidad. 🔴
17. Diseña la limitación de tasa de la API de pedidos a 100 peticiones por minuto y cliente,
    compartida entre diez instancias del servicio, y di qué pasa en el borde de la ventana y qué
    harías si Redis no responde. 🔴

---

**Anterior:** [`03`](03-atomicidad-scripts-y-durabilidad.md) — atomicidad, scripts y durabilidad ·
**Siguiente:** [`05`](05-dynamodb-modelo-y-claves.md) — DynamoDB: el modelo y las claves ·
**Relacionado:** [`l04`](../13-laboratorio/l04-redis-y-mongodb.md) §3 — la estampida con cincuenta
hilos y el candado ·
[`04/04`](../04-transacciones-y-concurrencia/04-bloqueos-e-interbloqueos.md) §4 — la cola en
PostgreSQL con `SKIP LOCKED`.
