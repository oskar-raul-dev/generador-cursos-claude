# 03 — Caracterización

Este taller es **opcional**, como todo el bloque `06-talleres/`, y depende de
[`01` — Heredar el legado](01-heredar-el-legado.md); no necesita el frontend de [`02`](02-los-errores-escondidos.md).
Antes de tocar una línea del legado, congela lo que hace hoy —**defectos incluidos**— en una suite
`hurl` que corre contra el sistema vivo: `contrato/hurl/legacy`, un *golden master* del
comportamiento actual. Termina cuando la suite está en verde contra `mono-legacy`, se pone en rojo
ante un «arreglo» inocente y has visto que también depende del reloj si no lo controlas.

> Ejercita [`03/07` — Estrategia de pruebas y evidencia de modularidad](../03-datos-ejecucion-y-operacion/07-estrategia-de-pruebas-y-evidencia-de-modularidad.md)
> y [`05/03` — Recuperar modularidad en un monolito legado](../05-decision-evolucion-y-practica/03-recuperar-modularidad-en-un-monolito-legado.md).
> Las reglas del bloque están en §11 y §12 de la [guía de estilo](../prompts/guia-de-estilo-y-convenciones.md).
>
> **Vigencia:** 2026-09-29. Salidas corridas ese día en macOS con Docker Desktop y `hurl` 8.0.1.

**Salto rápido:** [1](#1--qué-enseña-este-taller) · [2](#2--prerrequisitos-y-versiones) · [3](#3-️-mapa-de-carpetas) · [4](#4--recorrido-de-la-base-de-código) · [5](#5--qué-se-congela-y-qué-no) · [6](#6--un-archivo-por-capacidad) · [7](#7--la-suite-en-verde) · [8](#8--provocación-el-arreglo-inocente) · [9](#9--provocación-la-suite-depende-del-reloj) · [10](#10--evidencia) · [11](#11--errores-reales-al-escribirla) · [12](#12--plataformas) · [13](#13--teardown) · [Preguntas](#-preguntas) · [Ejercicios](#-ejercicios)

---

## 1. 🎯 Qué enseña este taller

Una prueba de caracterización, en el sentido de Michael Feathers, no afirma que el sistema haga lo
correcto: afirma que **sigue haciendo lo mismo**. Es la red de seguridad que permite mover un legado
sin especificación, porque convierte cualquier cambio de comportamiento —querido o no— en una
prueba en rojo que alguien tiene que mirar.

```text
lab.py suite ──► seed ──► hurl --test --jobs 1 ──► mono-legacy :38081
                          contrato/hurl/legacy/*.hurl
                          (lo que HAY: 200 con error, 500 con traza, double, passwordHash)
```

Tres ideas:

- **Se congela todo, incluso lo que está mal.** Un `200` con error, el hash de la contraseña o
  `29.700000000000003` se afirman igual que un pedido bien creado. Cada defecto congelado lleva un
  comentario que lo dice, para que nadie lo tome por especificación.
- **La suite habla solo HTTP.** No conoce clases ni tablas: por eso sobrevive a la reorganización
  interna de los talleres 05 a 10, y por eso el taller 04 puede reemplazarla por un contrato.
- **Un *golden master* es tan estable como su entorno.** Lo que depende del reloj, de una caché o de
  un job en segundo plano hay que fijarlo antes de congelarlo, o la suite mentirá a ratos.

El precio: 54 peticiones y 408 líneas de `hurl` que describen un comportamiento que en parte se
quiere cambiar. Lo que compra es que, desde ahora, cada cambio del legado deja rastro.

## 2. 🧰 Prerrequisitos y versiones

Lo del [taller 01](01-heredar-el-legado.md#2--prerrequisitos-y-versiones). La herramienta nueva es
`hurl` `8.0.1`, que `lab.py check` ya comprobaba: un cliente HTTP de línea de comandos que lee
peticiones y aserciones de archivos de texto.

## 3. 🗂️ Mapa de carpetas

```text
06-talleres/laboratorio/
├── contrato/
│   └── hurl/legacy/          nuevo: la caracterización
│       ├── 01-health.hurl    salud
│       ├── 02-auth.hurl      login, errores de credenciales, logout
│       ├── 03-products.hurl  catálogo y alta de productos
│       ├── 04-orders.hurl    pedidos, stock, errores y el 500 con traza
│       ├── 05-payment.hurl   autorizado, rechazado por el if, incierto
│       ├── 06-cancel.hurl    cancelación, trigger y notificaciones
│       └── 07-reports.hurl   informe y lotes
├── legacy/                   sin cambios respecto de estados/02
└── estados/03/               el laboratorio al cerrar este taller
```

## 4. 🔎 Recorrido de la base de código

Aquí la base de código a recorrer es la suite misma. Las rutas citan `laboratorio/estados/03/`.

| Pregunta | Dónde está la respuesta |
|---|---|
| ¿Qué estado inicial supone la suite? | `contrato/seed/seed.sql`: cinco productos con stock fijo y dos usuarios; `lab.py suite` siembra antes de correr |
| ¿Cómo pasa un dato de una petición a otra? | `[Captures]`, por ejemplo `order_id: jsonpath "$.id"` en `contrato/hurl/legacy/04-orders.hurl:15` |
| ¿Dónde se congela un defecto? | cada bloque precedido de un comentario «defecto congelado»: `02-auth.hurl` (hash y mensajes distintos), `04-orders.hurl` (el `double` y el `500` con traza), `03-products.hurl` (el alta que pisa) |
| ¿Por qué el orden importa? | los archivos consumen stock y crean pedidos: `06-cancel.hurl` espera `SKU-002` en 96 porque `04-orders.hurl` ya compró cuatro unidades |

## 5. 🧱 Qué se congela y qué no

La suite sigue cinco reglas, y cada una evita una forma de caracterización inútil:

1. **Se afirma por campo, no por texto completo.** `jsonpath "$.status" == "CONFIRMED"` sobrevive a
   un cambio en el orden de los campos o a un campo nuevo; comparar el cuerpo entero no.
2. **Los valores esperados salen de la semilla, no de copiar la salida.** Que `SKU-001` quede en 18
   se razona: 20 en la semilla menos 2 del primer pedido. Copiar la salida congela también los
   errores de quien escribe la suite (la sección 11 cuenta uno).
3. **Se congela lo observable y estable.** Los identificadores generados, las fechas y las referencias
   del banco se capturan o se comprueban por forma (`startsWith "psp-"`), nunca por valor.
4. **Cada defecto congelado se marca.** El comentario «defecto congelado» dice que esa aserción
   describe lo que hay, no lo que se quiere. El taller 04 las busca para decidir cuáles romper.
5. **Lo que depende del tiempo se controla o se deja fuera.** El `500` intermitente del taller 02 no
   entra en la suite: no es reproducible por HTTP sin controlar el cierre diario. La sección 9
   muestra qué pasa si no se controla.

## 6. 🔁 Un archivo por capacidad

Un fragmento de `04-orders.hurl`, el que congela el pedido que falla sin avisar:

```text
# sin stock: 200 con error y nada cambia (la primera línea también se deshace)
POST {{base_url}}/api/v1/orders
Authorization: Bearer {{ana_token}}
{ "lines": [ { "sku": "SKU-001", "quantity": 1 }, { "sku": "SKU-004", "quantity": 1 } ] }
HTTP 200
[Asserts]
jsonpath "$.error" == "Not enough stock for SKU-004"

GET {{base_url}}/api/v1/products/SKU-001
Authorization: Bearer {{ana_token}}
HTTP 200
[Asserts]
jsonpath "$.stock" == 18
```

- `{{base_url}}` y `{{ana_token}}` son variables: la primera la pasa `lab.py`, la segunda la capturó
  el login al principio del archivo.
- `HTTP 200` es una aserción sobre el código de estado; aquí congela el defecto de responder `200`
  a un fallo.
- `[Asserts]` compara campos del JSON con expresiones `jsonpath`; la segunda petición comprueba que
  el rollback dejó el stock donde estaba.

Y el que congela el `500` con traza:

```text
# SKU inexistente: 500 con la traza de Java en el cuerpo (defecto congelado)
POST {{base_url}}/api/v1/orders
Authorization: Bearer {{ana_token}}
{ "lines": [ { "sku": "SKU-999", "quantity": 1 } ] }
HTTP 500
[Asserts]
jsonpath "$.trace" contains "java.lang.NullPointerException"
jsonpath "$.path" == "/api/v1/orders"
```

- `contains` comprueba que la traza está y de qué excepción es, sin fijar números de línea que
  cambiarían con cualquier edición del código.

## 7. 🧪 La suite en verde

```bash
python3 laboratorio/scripts/lab.py legacy --daily-close-ms 600000    # en otra terminal
python3 laboratorio/scripts/lab.py suite
```

- `legacy --daily-close-ms 600000` arranca el legado con el cierre diario cada diez minutos: es la
  precondición de la suite (sección 9).
- `suite` siembra y corre `hurl --test --jobs 1` sobre `contrato/hurl/legacy` contra `:38081`.
  `--test` muestra un resumen por archivo; `--jobs 1` los corre en orden, porque comparten estado.

```text
psp-simulator reset: 200
semilla cargada
$ hurl --test --jobs 1 --variable base_url=http://localhost:38081 01-health.hurl 02-auth.hurl 03-products.hurl 04-orders.hurl 05-payment.hurl 06-cancel.hurl 07-reports.hurl
Success 01-health.hurl (1 request(s) in 2 ms)
Success 02-auth.hurl (6 request(s) in 456 ms)
Success 03-products.hurl (8 request(s) in 258 ms)
Success 04-orders.hurl (13 request(s) in 205 ms)
Success 05-payment.hurl (9 request(s) in 2173 ms)
Success 06-cancel.hurl (12 request(s) in 233 ms)
Success 07-reports.hurl (5 request(s) in 167 ms)
--------------------------------------------------------------------------------
Executed files:    7
Executed requests: 54 (15.4/s)
Succeeded files:   7 (100.0%)
Failed files:      0 (0.0%)
Duration:          3501 ms (0h:0m:3s:501ms)
```

`05-payment.hurl` tarda algo más de 2 s: es el pago de 666.00, que espera el timeout del legado. La
suite lo afirma con `duration >= 1900`.

## 8. 🧨 Provocación: el arreglo inocente

Un compañero cree que «Insufficient stock» suena mejor que «Not enough stock» y lo cambia:

```bash
sed -i '' 's/"Not enough stock for "/"Insufficient stock for "/' \
  laboratorio/legacy/src/main/java/dev/mono/legacy/service/InventoryService.java
```

- `sed -i ''` edita el archivo en su sitio (la cadena vacía tras `-i` es la sintaxis de macOS; en
  Linux es `sed -i`). Cambia solo el texto del mensaje.

```bash
diff laboratorio/estados/03/legacy/src/main/java/dev/mono/legacy/service/InventoryService.java \
     laboratorio/legacy/src/main/java/dev/mono/legacy/service/InventoryService.java
```

- `diff` compara el archivo congelado con el editado: una sola línea cambió.

```text
27c27
<             throw new LegacyException("Not enough stock for " + sku);
---
>             throw new LegacyException("Insufficient stock for " + sku);
```

Tras reiniciar el legado con la misma precondición, la suite (desde la primera línea de `hurl`; lo
anterior es la siembra, igual que en la sección 7):

```text
Success 01-health.hurl (1 request(s) in 2 ms)
Success 02-auth.hurl (6 request(s) in 477 ms)
Success 03-products.hurl (8 request(s) in 243 ms)
error: Assert failure
   --> 04-orders.hurl:44:0
    |
    | POST {{base_url}}/api/v1/orders
    | ...
 44 | jsonpath "$.error" == "Not enough stock for SKU-004"
    |   actual:   string <Insufficient stock for SKU-004>
    |   expected: string <Not enough stock for SKU-004>
    |

Failure 04-orders.hurl (5 request(s) in 160 ms)
Success 05-payment.hurl (9 request(s) in 2164 ms)
Success 06-cancel.hurl (12 request(s) in 237 ms)
Success 07-reports.hurl (5 request(s) in 166 ms)
--------------------------------------------------------------------------------
Executed files:    7
Executed requests: 46 (13.3/s)
Succeeded files:   6 (85.7%)
Failed files:      1 (14.3%)
Duration:          3458 ms (0h:0m:3s:458ms)
```

Para el legado, el mensaje **es** el contrato: el taller 02 mostró que el frontend y cualquier
cliente que compare cadenas dependen de él. La suite no dice si el cambio es bueno o malo; dice que
cambió algo que un cliente puede ver, y obliga a decidirlo a propósito. Se revierte con el `sed`
inverso, y la suite vuelve a verde.

## 9. 🧨 Provocación: la suite depende del reloj

El mismo legado, con el cierre diario cada 50 ms, y la suite tres veces seguidas:

```bash
python3 laboratorio/scripts/lab.py legacy --daily-close-ms 50    # en otra terminal, tras parar el anterior
for r in 1 2 3; do
  echo "== corrida $r"
  python3 laboratorio/scripts/lab.py suite 2>&1 | grep -E '^(Failure|error)|-->|actual|Succeeded files'
done
```

- `--daily-close-ms 50` hace que el job llene la caché de pedidos veinte veces por segundo.
- El bucle corre la suite tres veces; `2>&1` junta la salida de error con la normal y `grep -E` deja
  solo los fallos, la línea que falla, el valor obtenido y el resumen.

```text
== corrida 1
error: Assert status code
   --> 04-orders.hurl:79:6
    |      ^^^ actual value is <500>
Failure 04-orders.hurl (10 request(s) in 156 ms)
Succeeded files:   6 (85.7%)
== corrida 2
Succeeded files:   7 (100.0%)
== corrida 3
error: Assert status code
   --> 04-orders.hurl:79:6
    |      ^^^ actual value is <500>
Failure 04-orders.hurl (10 request(s) in 116 ms)
Succeeded files:   6 (85.7%)
```

La línea 79 es el
`GET` del pedido recién creado. Si el cierre diario corre entre la creación y la lectura, el pedido
sale de la caché sin sesión y responde `500`: la `LazyInitializationException` del taller 02, ahora
dentro de la suite. Dos corridas de tres en rojo, sin ningún cambio de código.

La conclusión no es «la suite es frágil», sino que **el comportamiento del legado depende del tiempo**
y la caracterización lo hizo visible. Hay dos respuestas legítimas: controlar la precondición —el
cierre diario lejos, como en la sección 7— y declararla, o congelar las dos variantes con un
escenario que fuerce el job. Esta suite elige la primera y la deja escrita. Una suite que a veces
falla sin cambios enseña al equipo a ignorar el rojo, y entonces deja de servir.

## 10. 🧪 Evidencia

```bash
git diff --no-index --stat laboratorio/estados/02 laboratorio/estados/03
```

- `git diff --no-index` compara dos carpetas que no están en un repositorio como versiones; `--stat`
  resume por archivo.

```text
 .../03/contrato/hurl/legacy/01-health.hurl         |   7 ++
 .../03/contrato/hurl/legacy/02-auth.hurl           |  46 +++++++++
 .../03/contrato/hurl/legacy/03-products.hurl       |  64 +++++++++++++
 .../03/contrato/hurl/legacy/04-orders.hurl         | 103 +++++++++++++++++++++
 .../03/contrato/hurl/legacy/05-payment.hurl        |  72 ++++++++++++++
 .../03/contrato/hurl/legacy/06-cancel.hurl         |  81 ++++++++++++++++
 .../03/contrato/hurl/legacy/07-reports.hurl        |  35 +++++++
 7 files changed, 408 insertions(+)
```

El legado no cambió: el taller solo añadió observación. Esa es la propiedad que hay que conservar:
la red se tiende antes de tocar el sistema.

## 11. 🩺 Errores reales al escribirla

### Un valor esperado escrito de memoria

**Síntoma.** El primer borrador de `07-reports.hurl` esperaba `ordersCreated == 9`.

**Causa.** El número se escribió estimando, no razonando sobre la semilla: los archivos anteriores
crean 2 + 3 + 2 = 7 pedidos. Se corrigió antes de la primera corrida.

**Lección.** Si el valor se hubiera copiado de la salida en lugar de razonarse, la suite habría
congelado un 7 igual; pero un error en el legado también habría quedado congelado como correcto. Un
*golden master* es fiable cuando cada valor tiene una explicación que no es «es lo que salió».

### El cierre diario en medio de la suite

**Síntoma.** Con el intervalo por defecto, 30 s, la suite pasa casi siempre. Con 50 ms, falla dos de
cada tres veces en `04-orders.hurl:79` (sección 9).

**Causa.** La caché de pedidos que llena `DailyCloseJob` convierte el resultado de un `GET` en una
función del tiempo transcurrido desde el último job.

**Lección.** Con 30 s la probabilidad de fallo es baja y el defecto aparecería como un «flaky test»
ocasional en CI, que es la peor forma de descubrirlo. Forzar el caso extremo lo convirtió en un
hallazgo reproducible y en una precondición escrita.

## 12. 🧰 Plataformas

Los talleres son solo Java (§6 de la guía), pero la caracterización por HTTP es neutral: la misma
suite sirve para cualquier reescritura del legado en otra plataforma, que es exactamente lo que la
hace valiosa antes de una migración. El contraste entre tipos de prueba por plataforma está en
[`03/07` — Estrategia de pruebas](../03-datos-ejecucion-y-operacion/07-estrategia-de-pruebas-y-evidencia-de-modularidad.md).

## 13. 🧹 Teardown

```bash
python3 laboratorio/scripts/lab.py down
```

- Apaga PostgreSQL y Toxiproxy y borra sus volúmenes. El legado y el `psp-simulator` se paran con
  Ctrl+C en sus terminales.

## ⚠️ Errores frecuentes

- «La caracterización valida que el sistema es correcto». Valida que no cambió; lo correcto lo decide
  el contrato del taller 04.
- «Copio la respuesta entera y la comparo». Congela el orden de los campos, las fechas y los
  identificadores, y falla por razones que no importan.
- «Los defectos no se congelan, se arreglan». Arreglarlos sin red es exactamente lo que la
  caracterización evita; primero se congelan, después se cambian a propósito.
- «Un test que falla a veces se reintenta». Un fallo intermitente es un comportamiento que depende de
  algo no controlado; reintentarlo lo esconde.
- «La suite de caracterización es para siempre». Es un andamio: cuando exista un contrato, la suite
  del contrato la reemplaza donde decidan diferir.

## 📚 Referencias

- [Characterization Testing, Michael Feathers](https://michaelfeathers.silvrback.com/characterization-testing)
- [Hurl: Asserting Response](https://hurl.dev/docs/asserting-response.html)
- [Hurl: Capturing Response](https://hurl.dev/docs/capturing-response.html)

## 🧠 Preguntas

1. ¿Qué afirma una prueba de caracterización y qué no afirma? 🟢
2. ¿Por qué la suite congela el `200` con error y el hash de la contraseña si son defectos? 🟢
3. ¿Por qué `lab.py suite` siembra antes de correr y usa `--jobs 1`? 🟢
4. ¿Por qué se afirma campo por campo en lugar de comparar el cuerpo completo? 🟢
5. ¿Qué dice la suite en rojo tras cambiar el mensaje de stock, y qué no dice? 🟡
6. ¿Por qué el valor 18 de `SKU-001` se razona desde la semilla y no se copia de la salida? 🟡
7. ¿Por qué el `500` intermitente del taller 02 no entra en la suite? 🟡
8. ¿Qué hace `contains "java.lang.NullPointerException"` que no haría comparar la traza entera? 🟡
9. La suite falla dos de cada tres veces con el cierre diario a 50 ms. ¿Es un problema de la suite o del legado? 🟡
10. ¿Qué relación tendrá esta suite con `hurl/v1` del taller 04? 🟠
11. Un cambio del legado rompe 12 aserciones de la suite. ¿Cómo decides cuáles son regresiones y cuáles cambios deseados? 🟠
12. ¿Qué parte del comportamiento del legado no puede caracterizar una suite HTTP? 🟠
13. Tienes que caracterizar un legado con 300 rutas y una semana. ¿Cómo eliges qué congelar primero? 🔴

## 🧪 Ejercicios

1. 🟢 **Orientación en código ajeno.** ¿En qué archivo y línea de la suite se congela que un login
   incorrecto responde distinto según exista o no el correo? Responde con rutas de
   `laboratorio/estados/03/`.
2. 🟢 Aplica el arreglo inocente de la sección 8, corre la suite, pega la salida y reviértelo.
3. 🟡 Añade a `04-orders.hurl` una aserción que congele que la respuesta de un pedido trae
   `payments` como lista vacía y que `lines[0].id` es un número. Córrela y explica qué defecto
   congela cada una.
4. 🟡 Cambia el precio de `SKU-001` en `seed.sql` a 50.00 y corre la suite. ¿Cuántas aserciones
   fallan y qué te dice eso sobre la dependencia de la suite con la semilla?
5. 🟡 **Orientación en código ajeno.** Encuentra en la suite la aserción que depende del *trigger*
   de PostgreSQL. ¿Qué pasaría con ella si el legado corriera contra SQLite?
6. 🟠 Escribe un escenario que congele también el `500` de la caché, de forma reproducible: con el
   legado a 50 ms, crea un pedido, espera a que `batch_runs` tenga una fila nueva y pídelo. ¿Dónde
   pondrías ese escenario y cómo evitarías que haga inestable al resto?
7. 🟠 Añade `08-edge.hurl` con tres comportamientos del legado que la suite todavía no congela.
   Justifica por qué cada uno le importa a un cliente.
8. 🔥 Escribe la misma caracterización de `04-orders.hurl` como pruebas JUnit con `RestClient` contra
   el legado vivo. Compara legibilidad, mantenimiento y lo que cada una deja fuera.

---

**Anterior:** [`02` — Los errores escondidos](02-los-errores-escondidos.md). **Siguiente:**
[`04` — El contrato](04-el-contrato.md).
