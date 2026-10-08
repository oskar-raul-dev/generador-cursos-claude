# 10 — El monolito distribuido provocado

Este taller es **opcional**, como todo el bloque `06-talleres/`, y depende de
[`09` — Migraciones de esquema](09-migraciones-de-esquema.md), que separó el stock en la tabla
`inventory`, y de [`06` — Modularizar](06-modularizar.md), que dio a `inventory` su API. Es el único
taller que distribuye, y lo hace **para medir el daño, no para recomendarlo**: saca `inventory` a un
segundo proceso Java, `mono-inventory`, que comparte la base con `mono-legacy`, provoca lo que eso
cuesta y después lo desmonta por los dos caminos posibles —fusionar de vuelta, o dar al proceso
propiedad de sus datos y un contrato— y compara el precio de cada uno.

> Ejercita el bloque [`04` — Monolito distribuido](../04-monolito-distribuido/01-anatomia-y-evidencia-del-monolito-distribuido.md)
> entero (`04/01`–`04/08`) y [`05/04` — Extraer un módulo a servicio](../05-decision-evolucion-y-practica/04-extraer-un-modulo-a-servicio.md).
> Las reglas del bloque están en §11 y §12 de la [guía de estilo](../prompts/guia-de-estilo-y-convenciones.md).
>
> **Vigencia:** 2026-09-29. Salidas corridas ese día en macOS con Docker Desktop, JDK 25.0.4 y `hurl`
> 8.0.1. Las latencias son una reproducción local, un solo nodo, sin red real: comparan modos entre sí,
> no predicen producción.

**Salto rápido:** [1](#1--qué-enseña-este-taller) · [2](#2--prerrequisitos-y-versiones) · [3](#3-️-mapa-de-carpetas) · [4](#4--recorrido-de-la-base-de-código) · [5](#5--la-extracción-tal-como-se-suele-hacer) · [6](#6--provocación-la-falsa-transacción) · [7](#7--provocación-la-cadena-síncrona) · [8](#8--provocación-el-cambio-de-columna-y-el-lockstep) · [9](#9--salida-1-fusionar) · [10](#10--salida-2-propiedad-de-datos-y-contrato) · [11](#11--la-matriz-de-evidencias) · [12](#12--errores-reales-al-correrlo) · [13](#13--plataformas) · [14](#14--teardown) · [Preguntas](#-preguntas) · [Ejercicios](#-ejercicios)

---

## 1. 🎯 Qué enseña este taller

```text
antes (09): un proceso                         la extracción ingenua (este taller)
mono-legacy                                    mono-legacy ──HTTP──► Toxiproxy ──► mono-inventory
 orders ─► inventory ─► tabla inventory          orders ─► cliente           reservas ─┐
 una transacción, una base                        catálogo ─────────────┐              │
                                                                        ▼              ▼
                                                              la misma base: products, inventory
```

Tres ideas:

- **Separar el proceso no separa nada más.** Con la base compartida, el cambio de una columna rompe
  al otro proceso; con la llamada síncrona, un proceso caído tumba los pedidos; y la transacción que
  unía pedido y reserva se convierte en dos, con fallos a medias. Son las cinco monedas de
  [`04/01`](../04-monolito-distribuido/01-anatomia-y-evidencia-del-monolito-distribuido.md) medidas en
  el laboratorio.
- **Hay dos salidas, y las dos cuestan.** Fusionar devuelve la transacción y quita la red; dar
  propiedad de datos y contrato conserva el proceso separado a cambio de identificadores de reserva,
  compensaciones y una API más.
- **La decisión la toma la evidencia, no la topología.** El taller termina fusionado porque, en este
  laboratorio, nada compensaba la distribución: ningún equipo distinto, ninguna escala distinta. Con
  otros datos, la otra salida sería la correcta.

## 2. 🧰 Prerrequisitos y versiones

Lo de los talleres anteriores; `mono-inventory` usa la misma baseline (Java 25, Spring Boot 4.1.1,
Flyway 12.4.0 gestionado por Boot). Órdenes nuevas de `lab.py`:

| Orden | Qué hace |
|---|---|
| `lab.py inventory [--rename]` | compila y arranca `mono-inventory` en `:38082`; `--rename` es su versión siguiente, que renombra `inventory.stock` a `on_hand` |
| `lab.py legacy --inventory-mode local\|remote-naive\|remote` | dónde vive el stock para el legado (sección 4) |
| `lab.py proxy inventory --latency MS \| --down \| --off` | tóxicos en el proxy `inventory` de Toxiproxy (`:38182` → `:38082`) |
| `lab.py bench --n 50` | latencia de cincuenta pedidos seguidos |

## 3. 🗂️ Mapa de carpetas

```text
06-talleres/laboratorio/
├── inventory/                         nuevo: mono-inventory (dev.mono.inventory)
│   └── src/main/
│       ├── java/.../InventoryStore.java        reservas y liberaciones sobre la tabla inventory
│       ├── java/.../InventoryController.java   /internal/reservations, /releases, /items, /stock
│       └── resources/db/inventory/             V1: reservas con id; su propia historia de Flyway
│           resources/db/inventory-rename/      V2: la versión que renombra la columna
├── legacy/src/main/java/dev/mono/legacy/inventory/
│   ├── InventoryService.java           los tres modos; compensación al deshacer
│   └── internal/RemoteInventory.java   nuevo: el cliente HTTP
├── contrato/toxiproxy/proxies.json     + proxy inventory
├── contrato/seed/seed.sql              tolera la columna renombrada
└── estados/10/
```

## 4. 🔎 Recorrido de la base de código

Las rutas citan `laboratorio/estados/10/`.

| Pregunta | Dónde está la respuesta |
|---|---|
| ¿Cómo decide el legado dónde reservar? | `legacy/src/main/java/dev/mono/legacy/inventory/InventoryService.java:52`–`54`, según `legacy.inventory.mode` (`legacy/src/main/resources/application.yaml:44`) |
| ¿Qué hace el modo `remote` antes de llamar? | `InventoryService.java:56`: registra la compensación, porque si la llamada falla por la red la reserva pudo aplicarse |
| ¿Cuándo se compensa? | `InventoryService.java:96`, `afterCompletion`: si la transacción del pedido no confirmó |
| ¿Por qué el catálogo lee de la API solo en `remote`? | `legacy/.../inventory/internal/ProductService.java:23`–`28`: en los otros modos lee la tabla directamente |
| ¿Qué evita que una reserva que llega tarde se aplique después de su compensación? | `inventory/src/main/java/dev/mono/inventory/InventoryStore.java:61`–`64`: la lápida `RELEASED` |
| ¿De quién son las migraciones de `inventory`? | de `mono-inventory`, con su tabla `flyway_inventory_history` (`inventory/src/main/resources/application.yaml:17`) |

## 5. 🔀 La extracción tal como se suele hacer

`mono-inventory` es un proceso de Spring Boot con cuatro rutas internas y la misma base. El legado,
en modo `remote-naive`, le pide cada reserva por HTTP, sin identificador; el catálogo sigue leyendo la
tabla `inventory` directamente, «porque está ahí».

```bash
python3 laboratorio/scripts/lab.py inventory                                                 # terminal 1
python3 laboratorio/scripts/lab.py legacy --daily-close-ms 600000 --inventory-mode remote-naive   # terminal 2
```

- `inventory` compila `laboratorio/inventory` y lo arranca en `:38082`. Al arrancar aplica su propia
  V1 con su propia historia (la base ya tenía la de `mono-legacy`):

```text
Migrating schema "public" to version "1 - reservations"
Successfully applied 1 migration to schema "public", now at version v1 (execution time 00:00.010s)
```

- `--inventory-mode remote-naive` hace que el legado reserve y libere a través de Toxiproxy
  (`:38182`), con un timeout de 2 s.

Antes de extraer, en modo `local`: `hurl/v1` en verde y

```text
50 pedidos: mediana 13 ms, p95 18 ms, máximo 31 ms
```

## 6. 🧨 Provocación: la falsa transacción

`hurl/v1` con los dos procesos:

```text
Success 03-products.hurl (12 request(s) in 243 ms)
error: Assert failure
   --> 04-orders.hurl:64:0
    |   actual:   integer <19>
    |   expected: integer <20>
Failure 04-orders.hurl (7 request(s) in 265 ms)
Success 05-payment.hurl (12 request(s) in 2274 ms)
...
Succeeded files:   8 (88.9%)
```

La línea 64 es la aserción «el stock de `SKU-001` sigue intacto tras un pedido que falla en su
segunda línea». En el monolito, las dos reservas estaban en la transacción del pedido y el `409` de
`SKU-004` deshacía también la de `SKU-001`. Ahora la de `SKU-001` es una transacción confirmada en
otro proceso: el legado deshace su pedido y la unidad queda reservada para nadie. El contrato del
taller 04 se rompió sin tocar el contrato: es la «falsa transacción» de
[`04/05`](../04-monolito-distribuido/05-fallos-parciales-retries-y-falsas-transacciones.md).

## 7. 🧨 Provocación: la cadena síncrona

Con el proxy cortado:

```bash
python3 laboratorio/scripts/lab.py proxy inventory --down
python3 laboratorio/scripts/lab.py api POST /api/v1/orders '{"lines":[{"sku":"SKU-002","quantity":1}]}' --key naive-down-1
python3 laboratorio/scripts/lab.py api GET /api/v1/products
python3 laboratorio/scripts/lab.py proxy inventory --off
```

- `proxy inventory --down` deshabilita el proxy en Toxiproxy: las conexiones a `:38182` se rechazan.
  `--off` lo vuelve a habilitar y quita los tóxicos; `lab.py seed` también.

```text
inventory: cortado
POST /orders:
HTTP 500 · application/problem+json · 22 ms
  "code": "INTERNAL_ERROR"
GET /products:
HTTP 200 · application/json · 8 ms
```

Sin `mono-inventory` no se vende. El catálogo funciona, pero por la razón equivocada: lee la tabla del
otro proceso directamente. Y con la respuesta lenta —el proceso vivo, la red mal—:

```bash
python3 laboratorio/scripts/lab.py proxy inventory --latency 2500
```

Y en la base, el stock de `SKU-002` y el número de pedidos:

```text
POST /orders (un cable):
HTTP 500 · application/problem+json · 2022 ms
  "code": "INTERNAL_ERROR"
inventory: sin tóxicos
           99 |       0
```

La petición llegó a `mono-inventory`, que reservó y confirmó; la respuesta tardó 2,5 s y el legado se
rindió a los 2. Resultado: ningún pedido y una unidad menos de stock. El legado no puede compensar,
porque no sabe si la reserva se aplicó: es el resultado incierto del taller 07, ahora entre dos
procesos propios.

## 8. 🧨 Provocación: el cambio de columna y el *lockstep*

El equipo de inventario despliega su versión siguiente, que renombra `inventory.stock` a `on_hand`
con su propia migración:

```bash
python3 laboratorio/scripts/lab.py inventory --rename
```

- `--rename` aplica `db/inventory-rename/V2__rename_stock_column.sql` y hace que el proceso use
  `on_hand`. En la vida real sería otro jar; aquí es el mismo con otra configuración, para poder
  alternar.

```text
Migrating schema "public" to version "2 - rename stock column"
Success 01-health.hurl (1 request(s) in 4 ms)
Failure 02-auth.hurl (6 request(s) in 371 ms)
Failure 03-products.hurl (3 request(s) in 173 ms)
Failure 04-orders.hurl (7 request(s) in 322 ms)
Success 05-payment.hurl (12 request(s) in 2347 ms)
Failure 06-cancel.hurl (3 request(s) in 182 ms)
...
Succeeded files:   4 (44.4%)
column "stock" does not exist
```

El cambio es correcto para `mono-inventory` y rompe a `mono-legacy`, que lee y escribe esa tabla en el
catálogo y en el alta de productos. Y rompió también `lab.py seed`, un tercer cliente de la tabla que
nadie tenía en la lista (sección 12).

¿Y desplegar primero el legado? Con una versión que ya lee y escribe `on_hand`
(`--set legacy.inventory.stock-column=on_hand`) y `mono-inventory` sin renombrar:

```text
2) primero mono-legacy con on_hand (lectura y escritura), mono-inventory sin renombrar:
Failure 02-auth.hurl (6 request(s) in 396 ms)
...
Succeeded files:   4 (44.4%)
3) después mono-inventory con el renombre:
Failure 04-orders.hurl (7 request(s) in 241 ms)
Succeeded files:   8 (88.9%)
```

En cualquier orden, cuatro de nueve; solo con los dos desplegados, ocho de nueve (lo que queda es la
falsa transacción). Es el *lockstep* de
[`04/04`](../04-monolito-distribuido/04-contratos-fragiles-y-despliegues-coordinados.md): dos procesos
que solo se pueden desplegar juntos son un solo despliegue con más piezas.

## 9. 🔁 Salida 1: fusionar

El inventario vuelve al monolito: una línea de configuración, `legacy.inventory.mode: local` (el valor
por defecto), y `mono-inventory` apagado.

```bash
python3 laboratorio/scripts/lab.py legacy --daily-close-ms 600000
```

```text
fusión: mono-legacy local, mono-inventory apagado
Succeeded files:   9 (100.0%)
Succeeded files:   7 (100.0%)
Succeeded files:   6 (100.0%)
violaciones de respuesta según prism: 0
inventory: cortado
20 pedidos concurrentes de 1 × SKU-003: HTTP 201 × 5, HTTP 409 × 15
stock de SKU-003 después: 0
50 pedidos: mediana 13 ms, p95 18 ms, máximo 58 ms
Tests run: 8, Failures: 0, Errors: 0, Skipped: 0
BUILD SUCCESS
```

`hurl/v1`, las dos suites hermanas, el contrato, el stock exacto bajo carga y las pruebas del legado
(el `inventory: cortado` es el proxy apagado antes de la tormenta, con `mono-inventory` ya parado).
Vuelve la transacción única y desaparecen las tres provocaciones, porque ya no hay red, ni segundo
despliegue, ni segundo escritor de la tabla. Lo que cuesta: el equipo de inventario, si existiera,
perdería un despliegue propio que en la práctica no tenía (sección 8), y la fusión deja dos tablas
huérfanas de `mono-inventory` (`inventory_reservations`, `flyway_inventory_history`) que habría que
retirar con una migración.

## 10. 🔁 Salida 2: propiedad de datos y contrato

La otra salida conserva el proceso y arregla lo que lo hacía monolito distribuido. Modo `remote`:

| Moneda | Qué cambia |
|---|---|
| Datos | `mono-legacy` deja de leer y escribir `inventory`: el catálogo pide el stock a `GET /internal/stock` y el alta de productos a `POST /internal/items`. `mono-inventory` retira la clave `inventory → products` y lleva sus migraciones en su propia historia |
| Contrato | cada reserva lleva un `reservationId`; repetirla no reserva dos veces y liberar un id desconocido deja una lápida |
| Transacción | si el pedido se deshace —por una línea sin stock, un fallo al confirmar o un timeout—, el legado libera por id todas las reservas que intentó (`afterCompletion`) |

Las tres suites con los dos procesos:

```text
Succeeded files:   9 (100.0%)
Succeeded files:   7 (100.0%)
Succeeded files:   6 (100.0%)
```

La falsa transacción, compensada. El timeout, sin fuga:

```text
inventory: +2500 ms en cada respuesta
POST /orders (un cable):
HTTP 500 · application/problem+json · 4069 ms
  "code": "INTERNAL_ERROR"
inventory: sin tóxicos
          100 |       0
 SKU-002 |        1 | RELEASED
```

(Stock de `SKU-002` y pedidos; después, la reserva en `inventory_reservations`.)

El renombre, ahora solo en `mono-inventory`, **sin tocar el legado**:

```text
renombre solo en mono-inventory:
Migrating schema "public" to version "2 - rename stock column"
Succeeded files:   9 (100.0%)
```

Lo que no arregla, y lo que cuesta:

```text
inventory: cortado
POST /orders:
HTTP 500 · application/problem+json · 19 ms
GET /products:
HTTP 500 · application/problem+json · 27 ms
```

Con `mono-inventory` caído, ahora tampoco hay catálogo: al dejar de leer la tabla, el catálogo depende
del proceso en runtime. La propiedad de datos cambió acoplamiento de esquema por acoplamiento
temporal; bajarlo exigiría una copia local del stock para lectura, alimentada por eventos, con su
consistencia eventual. Y cada pedido paga la red:

```text
50 pedidos: mediana 17 ms, p95 33 ms, máximo 41 ms
```

Además, 200 líneas en `mono-inventory`, 71 en el cliente remoto del legado y una lógica de
compensación que es, a su vez, una llamada remota con resultado incierto (sección 12).

## 11. 🧪 La matriz de evidencias

La matriz de [`04/01`](../04-monolito-distribuido/01-anatomia-y-evidencia-del-monolito-distribuido.md),
rellenada con lo medido en este taller:

| Moneda | Extracción ingenua (`remote-naive`) | Salida 2 (`remote`) | Salida 1 (`local`) |
|---|---|---|---|
| Código | renombrar una columna exige cambiar los dos procesos | el renombre es un cambio de `mono-inventory` solo | un proceso, un cambio |
| Datos | dos escritores de `inventory`, `mono-legacy` lee la tabla del otro, clave foránea entre procesos | un solo escritor; el legado solo usa la API | una tabla con un dueño, `inventory`, dentro del monolito |
| Despliegue | *lockstep*: 4/9 en cualquier orden, 8/9 juntos | independiente: 9/9 con el renombre solo en `mono-inventory` | uno |
| Runtime | sin `mono-inventory` no hay pedidos; un timeout fuga stock | sin `mono-inventory` no hay pedidos **ni catálogo**; un timeout no fuga | sin red: 13 ms de mediana |
| Equipos | no medible en un laboratorio de una persona | — | — |

Con la columna de la extracción ingenua, el diagnóstico de
[`04/01`](../04-monolito-distribuido/01-anatomia-y-evidencia-del-monolito-distribuido.md) se cumple:
evidencia recurrente en cuatro monedas y ningún beneficio compensatorio —nadie despliega ni escala
`mono-inventory` por su cuenta—. Es un monolito distribuido. La salida 2 lo deja de ser en código,
datos y despliegue, y lo empeora en runtime. La salida 1 es la más barata aquí, y por eso es el estado
final del laboratorio. La salida 2 sería la correcta si hubiera un equipo de inventario con su propio
ritmo, o una carga que exigiera escalarlo aparte: la evidencia que falta para defenderla está en la
fila de equipos, y la aporta la organización, no el código.

## 12. 🩺 Errores reales al correrlo

### La semilla era un tercer cliente de la tabla

**Síntoma.** Tras el renombre, `lab.py suite` no llegaba a ejecutar ninguna petición:
`ERROR:  column "stock" of relation "inventory" does not exist` en la semilla.

**Causa.** `seed.sql` inserta en `inventory(sku, stock)`. Nadie la había contado entre los usuarios de
la tabla.

**Lección.** En una base compartida, los clientes de una tabla no son solo los procesos que la
arquitectura dibuja: son también *scripts*, informes, semillas y consultas de soporte. Se hizo la
semilla tolerante al nombre de la columna. La salida 2, que da la tabla a un solo dueño, no hace
desaparecer esos clientes: los convierte en clientes de la API o en lectores sin permiso.

### La versión «compatible» del legado solo cambiaba las lecturas

**Síntoma.** El primer intento del paso 3 del *lockstep* (los dos procesos con `on_hand`) dio 6 de 9,
no 8: el alta de productos y la cancelación fallaban.

**Causa.** La propiedad de la columna se había aplicado a la consulta del catálogo, pero
`StockStore.initialize` y `StockStore.add` seguían escribiendo `stock`.

**Lección.** Un despliegue coordinado es tan bueno como la búsqueda de referencias en el otro código
base. Cuantos más escritores tiene una tabla, más probable es que falte uno.

### La compensación también es incierta

**Síntoma.** En la salida 2, con la latencia de 2,5 s, el log del legado dice

```text
compensación pendiente: reserva 44ad8d62-9473-4986-a725-45d0b42f6019 de 1 × SKU-002 sin liberar: Could not retrieve response status code: java.net.SocketTimeoutException: Read timed out
```

y la base dice `RELEASED` y stock 100.

**Causa.** La liberación llegó y se aplicó; su respuesta, retrasada como la de la reserva, no llegó a
tiempo. El legado no sabe si la compensación se aplicó, igual que no sabía si la reserva se había
aplicado. La petición total tardó 4069 ms: dos timeouts.

**Lección.** Compensar con una llamada remota no cierra la incertidumbre, la desplaza. Lo que la hace
segura es la idempotencia (repetir la liberación con el mismo id no hace nada) y un reintento durable:
la *outbox* del taller 08. En el laboratorio la compensación fallida solo se registra; es el
ejercicio 7.

## 13. 🧰 Plataformas

Los talleres son solo Java (§6 de la guía). El diagnóstico de monolito distribuido no depende de la
plataforma —la tabla de [`04/01`](../04-monolito-distribuido/01-anatomia-y-evidencia-del-monolito-distribuido.md)
dice «no aplica» en las cuatro filas a propósito—, y los mecanismos de compensación e idempotencia
entre procesos se comparan en
[`04/05`](../04-monolito-distribuido/05-fallos-parciales-retries-y-falsas-transacciones.md).

## 14. 🧹 Teardown

```bash
python3 laboratorio/scripts/lab.py proxy inventory --off
python3 laboratorio/scripts/lab.py down
```

- `proxy inventory --off` quita tóxicos y cortes del proxy, si quedó alguno.
- `down` apaga PostgreSQL y Toxiproxy y borra sus volúmenes, con las tablas de `mono-inventory` y la
  columna renombrada. `mono-legacy`, `mono-inventory` y el `psp-simulator` se paran con Ctrl+C.

## ⚠️ Errores frecuentes

- «Si son dos procesos, son dos servicios». Con la base compartida y despliegue coordinado, son un
  despliegue repartido.
- «La base compartida es el problema». Es uno de cuatro; la salida 2 la resolvió y empeoró el runtime.
- «Una llamada HTTP con reintentos sustituye a la transacción». La transacción se partió en dos; sin
  identificadores y compensación, el reintento duplica o fuga.
- «Compensar resuelve el fallo parcial». La compensación es otra llamada que puede fallar a medias;
  necesita idempotencia y reintento durable.
- «Fusionar es un fracaso». Es la salida más barata cuando la distribución no compra nada; el taller
  lo midió.
- «La salida 2 siempre es mejor a largo plazo». Solo si alguien usa la autonomía que compra: un equipo,
  un ritmo o una escala propios.

## 📚 Referencias

- [Microservices, James Lewis y Martin Fowler (datos descentralizados)](https://martinfowler.com/articles/microservices.html)
- [Pattern: Saga, Chris Richardson](https://microservices.io/patterns/data/saga.html)
- [StranglerFigApplication, Martin Fowler](https://martinfowler.com/bliki/StranglerFigApplication.html)
- [Toxiproxy](https://github.com/Shopify/toxiproxy)

## 🧠 Preguntas

1. ¿Qué garantía perdió el pedido al sacar el inventario a otro proceso, aunque el código de reserva no cambiara? 🟢
2. ¿Por qué el catálogo seguía funcionando con `mono-inventory` caído en la extracción ingenua, y por qué no es una buena noticia? 🟢
3. ¿Qué es el despliegue en *lockstep* y cómo lo midió el taller? 🟢
4. ¿Por qué un timeout de la reserva fuga stock en `remote-naive` y no en `remote`? 🟡
5. ¿Qué hace la lápida `RELEASED` y qué carrera evita? 🟡
6. ¿Por qué la compensación se registra antes de llamar a `mono-inventory` y no después? 🟡
7. La salida 2 hizo que el catálogo dependa de `mono-inventory` en runtime. ¿Es un error del diseño o un precio? 🟡
8. ¿Qué evidencia de la matriz sostiene el diagnóstico de monolito distribuido, y cuál falta? 🟡
9. ¿Por qué la semilla se rompió con el renombre, y qué dice eso de las bases compartidas? 🟡
10. El equipo quiere mantener `mono-inventory` «para escalar el inventario en el futuro». ¿Qué le pides antes de aceptarlo? 🟠
11. Con la salida 2, ¿cómo harías que el catálogo sobreviviera a la caída de `mono-inventory` y qué consistencia aceptarías? 🟠
12. Un entrevistador dice que fusionar es un paso atrás. ¿Cómo lo defiendes con los datos de este taller? 🟠
13. Diseña la extracción de `inventory` desde cero con lo aprendido: qué harías antes de separar el proceso y en qué orden. 🔴

## 🧪 Ejercicios

1. 🟢 **Orientación en código ajeno.** ¿En qué archivo y línea decide el legado liberar una reserva
   remota porque el pedido no se confirmó? Responde con rutas de `laboratorio/estados/10/`.
2. 🟢 Repite la falsa transacción de la sección 6 y encuentra en la base la unidad reservada para
   nadie. ¿Qué consulta la delata?
3. 🟡 Con `remote-naive`, lanza `lab.py storm orders --n 20`. ¿Se vende de más? Explica quién bloquea
   qué fila.
4. 🟡 **Orientación en código ajeno.** Lista todas las sentencias SQL del legado que tocan `inventory`
   en cada modo. ¿Cuántas quedan en `remote`?
5. 🟡 Mide la latencia de `lab.py bench` con `lab.py proxy inventory --latency 50` en `remote` y en
   `local`. ¿Qué parte del tiempo de un pedido se va en la red?
6. 🟠 Escribe la migración de `mono-legacy` que retira las tablas huérfanas tras la fusión. ¿Qué
   comprobarías antes de aplicarla?
7. 🟠 Haz que la compensación fallida se reintente con la *outbox* del taller 08. ¿Qué garantiza y
   qué ventana queda?
8. 🔥 Da al catálogo una copia local del stock alimentada por eventos de `mono-inventory`. Mide qué
   pasa con `GET /products` con el proceso caído y con qué retraso refleja una reserva.

---

**Anterior:** [`09` — Migraciones de esquema](09-migraciones-de-esquema.md). **Siguiente:**
[`11` — Respuestas](11-respuestas.md).
