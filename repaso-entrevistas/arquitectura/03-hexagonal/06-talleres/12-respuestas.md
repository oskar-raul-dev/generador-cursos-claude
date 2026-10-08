# 12 — Respuestas del bloque 06 · Talleres

Solucionario único de los once talleres. Cada enunciado está copiado literalmente de su taller y
cada respuesta conserva las tres capas: **⏱️ 30 segundos** (lo que dirías primero), **🗣️ 2
minutos** (contexto, alternativa y coste) y **🔬 El detalle** (para estudiar, no para recitar). Los
ejercicios llevan una guía de solución, no un código completo: el código está en `laboratorio/`.

> **Vigencia:** 2026-09-27.

**Salto rápido:** [01 Contrato y suite](#01--contrato-openapi-y-suite) · [02 Frontend](#02--frontend-mínimo-en-react) · [03 Java](#03--java-y-spring-boot) · [04 NestJS](#04--typescript-y-nestjs) · [05 Go](#05--go) · [06 FastAPI](#06--python-y-fastapi) · [07 Laravel](#07--php-y-laravel) · [08 Colas](#08--colas-con-jms-y-activemq-artemis) · [09 Kafka](#09--tópicos-con-kafka) · [10 gRPC](#10--grpc) · [11 Lotes](#11--lotes-con-spring-batch)

---

## 01 · Contrato OpenAPI y suite

### Preguntas

### 1. 🟢 ¿Por qué el contrato se escribe antes que cualquier backend en este bloque?

⏱️ **30 segundos:** Porque cinco backends tienen que ser intercambiables, y solo lo son si
traducen el mismo contrato al mismo puerto. Si cada uno documenta al final, hay cinco contratos.

🗣️ **2 minutos:** El contrato es el criterio de terminado: un sabor está listo cuando la suite
pasa con su URL base. Escribirlo primero convierte el diseño de la API en una decisión explícita
(códigos, errores, idempotencia, dinero) en vez de en un efecto secundario del framework de cada
uno. El coste es mantener un YAML largo antes de tener nada que corra; la ganancia es que "terminado"
significa lo mismo en los cinco.

🔬 **El detalle:** Es el mismo argumento que el corpus hace para el puerto de entrada: se diseña
desde el caso de uso hacia afuera, no copiando un endpoint. Aquí el orden se invierte solo en
apariencia: el contrato HTTP es la forma pública de ese puerto, y fijarlo primero es fijar el
puerto antes que los adaptadores.

### 2. 🟢 ¿Qué relación hay entre el `openapi.yaml` y el puerto de entrada del núcleo?

⏱️ **30 segundos:** El YAML es la forma externa del puerto: describe la misma intención
(`CreateOrder`, `CancelOrder`) en vocabulario HTTP. El adaptador HTTP traduce entre ambos.

🗣️ **2 minutos:** Un puerto de entrada expresa una capacidad con entrada y salida propias; el
contrato expresa cómo se pide esa capacidad por HTTP: ruta, método, cabeceras, códigos. No son lo
mismo: el puerto no sabe de `201` ni de `Location`, y el contrato no sabe de `CreateOrderCommand`.
Cinco adaptadores distintos traducen el mismo contrato a cinco puertos con la misma semántica.

🔬 **El detalle:** La prueba de que están bien separados es la parte 3 de cada sabor: el catálogo
cambia de base y el YAML no cambia. Si cambiara, el contrato estaría describiendo detalles, no
capacidades.

### 3. 🟢 ¿Qué campos añade este contrato a RFC 9457 y para qué sirve cada uno?

⏱️ **30 segundos:** `code`, un identificador estable para máquinas, y `errors`, la lista de campos
cuando el problema es de forma.

🗣️ **2 minutos:** RFC 9457 da `type`, `title`, `status`, `detail` e `instance`, pero `title` y
`detail` son texto para humanos y pueden cambiar sin romper nada. El frontend y la suite necesitan
algo por lo que decidir: `code` es un enum cerrado (`INSUFFICIENT_INVENTORY`, `TOKEN_REVOKED`…).
`errors` da `field` y `message` por campo para que un formulario señale dónde corregir.

🔬 **El detalle:** La RFC permite extensiones y recomienda que `type` sea la clave estable; aquí
`type` queda en `about:blank` y `code` cumple ese papel porque es más corto y no obliga a mantener
URLs de documentación por cada error.

### 4. 🟢 ¿Por qué el pedido de otro cliente responde `404` y no `403`?

⏱️ **30 segundos:** Porque `403` confirma que el pedido existe; `404` no revela nada.

🗣️ **2 minutos:** Con `403`, un cliente podría enumerar identificadores y saber cuáles existen
aunque no pueda leerlos. Con `404`, "no es tuyo" y "no existe" son indistinguibles desde fuera. Es
una decisión del borde: el caso de uso decide que el actor no puede ver ese pedido, y el adaptador
elige cómo presentarlo sin filtrar existencia.

🔬 **El detalle:** El capítulo de DTO y errores lo recoge en la tabla de traducción: `AccessDenied`
→ "403 o respuesta que no revele existencia". Aquí se eligió lo segundo para pedidos; para
`createProduct` se usa `403` porque el recurso (la colección) es público y no hay nada que
ocultar.

### 5. 🟢 ¿Por qué `amount` es un `string` y no un número JSON?

⏱️ **30 segundos:** Porque un número JSON se convierte en `double` en JavaScript, PHP y Go sin
pedirlo, y el dinero no sobrevive a la aritmética binaria.

🗣️ **2 minutos:** Con texto decimal (`"49.90"`), cada backend lo lee con su tipo exacto
(`BigDecimal`, `Decimal`, `shopspring/decimal`) y el contrato no depende de la aritmética de
nadie. El patrón del esquema (`^-?[0-9]+\.[0-9]{2}$`) exige dos cifras: `"35"` es un error de
validación, no una conveniencia. La alternativa de unidades menores enteras (`4990`) también es
válida; se descartó por legibilidad en la suite.

🔬 **El detalle:** El capítulo de clientes externos hace el mismo argumento con el proveedor de
pagos: `decimal` o enteros menores acordados explícitamente; `double` sin contrato "crea errores de
dinero".

### 6. 🟡 ¿Qué diferencia semántica separa `400`, `409` y `422` en este contrato?

⏱️ **30 segundos:** `400`: no entiendo la petición. `409`: la entiendo y el estado actual no lo
permite. `422`: la entiendo y contradice una petición anterior con la misma clave.

🗣️ **2 minutos:** `400` cubre forma (`VALIDATION_FAILED`, `IDEMPOTENCY_KEY_REQUIRED`); `409` cubre
conflictos de identidad (`PRODUCT_ALREADY_EXISTS`) y de estado (`INSUFFICIENT_INVENTORY`,
`ORDER_NOT_PAYABLE`, `ORDER_NOT_CANCELLABLE`); `422` queda solo para `IDEMPOTENCY_KEY_REUSED`. La
utilidad es para el cliente: `400` se corrige y se reenvía; `409` se consulta el estado; `422` se
cambia de clave.

🔬 **El detalle:** RFC 9110 define `409` como conflicto con el estado actual del recurso y `422`
como contenido sintácticamente correcto pero semánticamente inválido. Muchas APIs usan `422` para
toda validación; este contrato prefiere `400` para la forma y reserva `422` para el caso
genuinamente "semántico".

### 7. 🟡 ¿Qué promete `Idempotency-Key` en `createOrder` y qué pasa si la misma clave llega con otro cuerpo?

⏱️ **30 segundos:** Que la misma clave con el mismo cuerpo devuelve el pedido original (`200`,
`Idempotent-Replay: true`) sin reservar dos veces; con otro cuerpo, `422`.

🗣️ **2 minutos:** La clave la elige el cliente y tiene alcance por actor y 24 h de vida. Sirve
para reintentar tras un timeout sin crear dos pedidos. La misma clave con otro cuerpo es un error
del cliente, y decírselo con `422` es mejor que devolverle silenciosamente el pedido anterior, que
no es lo que pidió.

🔬 **El detalle:** Es la semántica del borrador de la IETF para la cabecera. Lo que el contrato no
dice es dónde se guarda la clave: eso es un adaptador de salida (`idempotency_keys` en PostgreSQL),
y la protección debe persistir donde se confirma el efecto, no en memoria del controller.

### 8. 🟡 ¿Por qué `/payment` y `/cancel` son `POST` a un sub-recurso y no `PATCH` del estado?

⏱️ **30 segundos:** Porque un cambio de estado es una intención con reglas propias, y una
intención se nombra.

🗣️ **2 minutos:** `PATCH /orders/{id}` con `{"status": "CANCELLED"}` obliga al cliente a conocer
la máquina de estados y al servidor a adivinar la intención a partir del destino: ¿`PAID` significa
"cobra" o "márcalo como pagado"? Un sub-recurso con `POST` expresa "cancela este pedido", tiene sus
propios errores (`ORDER_NOT_CANCELLABLE`) y sus efectos (liberar reserva, notificar). Es
`CancelOrder`, no `UpdateOrder`.

🔬 **El detalle:** El coste es más rutas; la ganancia es que cada ruta mapea a un caso de uso y la
autorización contextual ("solo el dueño") se evalúa por intención. `Idempotency-Key` en `/payment`
y la idempotencia natural de `/cancel` (cancelar lo cancelado es `200`) completan la semántica.

### 9. 🟡 ¿Por qué `products` e `inventory` son tablas separadas sin clave foránea?

⏱️ **30 segundos:** Porque la parte 3 de cada sabor se lleva el catálogo a MongoDB y el inventario
se queda en PostgreSQL; una FK entre ambas lo haría imposible.

🗣️ **2 minutos:** Catálogo (qué se vende y a qué precio) e inventario (cuánto hay) tienen ritmos
de cambio y consistencia distintos: el primero es lectura pesada y forma variable; el segundo
exige atomicidad al reservar. Separarlos desde el día uno dibuja la frontera del cambio interno en
el esquema. El precio: el núcleo no puede hacer JOIN entre ambos; compone en aplicación.

🔬 **El detalle:** `order_lines` guarda `product_name` y `unit_price` como foto de la venta, así que
un pedido no necesita el catálogo para mostrarse. Lo que sí lo necesita es `createOrder` (nombre y
precio) y `listProducts` (catálogo + stock): ahí aparece la composición en aplicación que la parte
3 hace visible.

### 10. 🟡 ¿Qué aserciones de la suite puede pasar el mock y cuáles no puede pasar nunca?

⏱️ **30 segundos:** Pasa las de contrato: códigos, `Content-Type`, forma de los cuerpos. No pasa
las de negocio: qué contraseña vale, cuánto stock queda, qué pedido se puede cancelar.

🗣️ **2 minutos:** El mock responde con los ejemplos del YAML y valida las peticiones contra los
esquemas; no tiene memoria ni reglas. Por eso `01-health` pasa entero, los `login` pasan, y cada
archivo falla en la primera aserción que depende de estado o de una regla. Uno de siete es el
techo, y es correcto.

🔬 **El detalle:** Hay un matiz: el mock puede fallar aserciones de contrato por sus propias
decisiones (elige la 2xx más baja, valida cuerpos con su propio código). Esos fallos no dicen que
el contrato esté mal; dicen que un mock no es un backend.

### 11. 🟠 El mock devolvió `422` a un cuerpo con `lines: []` cuando el contrato promete `400`. ¿Qué está midiendo cada código?

⏱️ **30 segundos:** El `422` mide que Prism validó el cuerpo contra el esquema y lo rechazó; el
`400` del contrato mide lo que el backend promete para ese caso. Son dos herramientas distintas
opinando.

🗣️ **2 minutos:** Prism detectó `minItems: 1` incumplido, buscó una respuesta `422` documentada en
la operación y usó su ejemplo (el de `IDEMPOTENCY_KEY_REUSED`, que no tiene nada que ver). Es la
diferencia entre "el YAML es válido y el cuerpo no cumple el esquema" y "el backend cumple el
contrato". El backend real debe devolver `400 VALIDATION_FAILED`; el mock nunca lo hará.

🔬 **El detalle:** Si se quisiera que el mock coincidiera, habría que documentar `422` como
respuesta de validación, lo que empeoraría el contrato para adaptarlo a la herramienta. La decisión
correcta es dejar el contrato como está y leer ese fallo como "falla donde debe".

### 12. 🟠 `up --wait` devolvió el control y la primera petición recibió "connection reset". ¿Qué faltaba y qué lección general deja?

⏱️ **30 segundos:** Faltaba un `healthcheck` en el servicio `mock`. Sin él, Compose considera
"healthy" al contenedor en cuanto el proceso arranca, no cuando escucha.

🗣️ **2 minutos:** Prism tarda unos segundos en cargar el contrato; `hurl` llegó antes y el puerto
estaba cerrado. Con `wget -qO- http://127.0.0.1:4010/health` como `healthcheck`, `--wait` espera
hasta que el mock responde. La lección general: "arrancado" y "listo" son dos estados, y toda
pieza que otros esperan debe exponer el segundo. Los backends de los talleres lo harán con
`/health`.

🔬 **El detalle:** El mismo patrón aparece en producción como *readiness* frente a *liveness*: un
proceso vivo que aún no puede atender no debe recibir tráfico. Aquí se reprodujo a propósito
quitando el `healthcheck` y se documentó con la salida literal.

### 13. 🟠 Un compañero propone que la suite corra los siete archivos en paralelo. ¿Qué rompería y cómo lo rediseñarías para permitirlo?

⏱️ **30 segundos:** Rompería las aserciones de stock: `04` asume `SKU-001` en 20 y `05` reserva
sobre la misma semilla. Para permitirlo, cada archivo tendría que crear sus propios productos.

🗣️ **2 minutos:** `06-cancel` ya lo hace: da de alta `SKU-101` y calcula sobre él. Extender ese
patrón a `04` y `05` (cada uno con su SKU propio) los haría independientes del orden. Quedaría un
acoplamiento: todos usan la misma cuenta `ana`, y los listados (`items count >= 1`) siguen
valiendo. El coste es más entradas por archivo; la ganancia, `--jobs` sin restricciones.

🔬 **El detalle:** Aun así, `02-auth` revoca el token de `ana`; en paralelo, otro archivo podría
tener ese mismo token si el `jti` no fuera único por login. Lo es (cada `login` emite un `jti`
nuevo), así que no interfiere. Verificarlo es un buen ejercicio de lectura del contrato.

### 14. 🟠 ¿Qué cambiaría en el contrato si el catálogo se mudara a MongoDB? Defiende la respuesta.

⏱️ **30 segundos:** Nada. Si algo cambiara, el contrato estaría describiendo un detalle de
persistencia, y estaría en el sitio equivocado.

🗣️ **2 minutos:** `listProducts` devuelve `sku`, `name`, `unitPrice` y `stock`; de dónde salen es
del adaptador de salida. Lo único que podría tentar a cambiar es el cursor de paginación (un
`ObjectId` en vez de un `sku`), pero el cursor es opaco precisamente para eso: su contenido es del
servidor. La parte 3 de cada sabor es la prueba empírica: el YAML no se toca.

🔬 **El detalle:** Lo que sí cambia es la composición en aplicación: `listProducts` ahora lee dos
fuentes (catálogo en Mongo, stock en PostgreSQL) y las une por `sku`. Ese código aparece en
`application/`, no en el contrato ni en el dominio, y es la lección de la parte 3.

### Ejercicios

### 1. 🟢 Abre Swagger UI, localiza `authorizePayment` y explica, sin mirar este documento, por qué `PAYMENT_PENDING` no vuelve a ser pagable con otra clave.

⏱️ **30 segundos:** Porque "pendiente" significa que el proveedor pudo haber cobrado y no lo
sabemos; un segundo intento a ciegas podría cobrar dos veces.

🗣️ **2 minutos:** `PAYMENT_REJECTED` es una respuesta definitiva del proveedor: se puede
reintentar con otra clave. `PAYMENT_PENDING` es ausencia de respuesta: lo correcto es consultar el
estado por la clave original, no emitir otra. El contrato lo codifica devolviendo
`ORDER_NOT_PAYABLE` en pendiente.

🔬 **El detalle:** La consulta de estado al proveedor no está en el contrato porque el
`PaymentGateway` determinista del taller no la ofrece; el taller 10 (gRPC) es donde tendría
sentido añadirla.

### 2. 🟢 Con `Prefer: code=…`, pide al mock cada una de las respuestas de error de `createOrder` y comprueba que todas llegan con `Content-Type: application/problem+json` y un `code` del enum.

⏱️ **30 segundos:** `curl -s -i … -H 'Prefer: code=400'`, y lo mismo con `401`, `404`, `409` y
`422`; en todas, la cabecera y el `code`.

🗣️ **2 minutos:** Es la forma de verificar la *forma* de los errores sin backend: el mock devuelve
el ejemplo documentado para ese código. Si un código no tiene ejemplo, Prism genera uno a partir del
esquema, y `code` sale del enum. El frontend del taller 02 programa contra exactamente eso.

🔬 **El detalle:** Para `400`, que tiene dos ejemplos con nombre (`validation` y `missingKey`),
Prism devuelve el primero; seleccionar por nombre con `example=` depende de la versión y no se
garantiza en 5.15.

### 3. 🟡 Añade a `03-products.hurl` una entrada que pida `limit=1000` y afirme que llegan como mucho 100 ítems. Decide qué código esperar y justifícalo en un comentario del archivo.

⏱️ **30 segundos:** `GET …/products?limit=1000` → `HTTP 200` y `jsonpath "$.items" count <= 100`.
El contrato dice "el servidor lo acota", no "lo rechaza".

🗣️ **2 minutos:** Hay dos diseños válidos: acotar en silencio (`200` con 100) o rechazar (`400`
por `maximum: 100`). El contrato eligió acotar, porque un cliente que pide "todo" no está haciendo
nada malo. La aserción `<= 100` es la que vale con la semilla de 5 productos; contra un backend con
más de 100 sería exactamente 100.

🔬 **El detalle:** El esquema declara `maximum: 100`, lo que sugiere rechazo; la prosa del
parámetro dice "lo acota". Esa contradicción es un hallazgo del ejercicio: hay que elegir una y
alinear esquema y descripción. La respuesta canónica del bloque es acotar y quitar `maximum`, o
rechazar y cambiar la descripción; ambas se aceptan si se argumentan.

### 4. 🟡 Corre `seed` y luego la suite dos veces seguidas contra el mock sin volver a sembrar. Explica qué archivo fallaría distinto contra un backend real y por qué contra el mock no cambia nada.

⏱️ **30 segundos:** Contra un backend real, `03-products` fallaría en el alta de `SKU-006` (`409`
en vez de `201`) y `06-cancel` en `SKU-101`; contra el mock nada cambia porque no tiene memoria.

🗣️ **2 minutos:** La suite no es idempotente por diseño: crea productos con SKU fijos y consume
stock. Por eso `seed` va antes de cada corrida y por eso `lab.py` no lo hace automáticamente: la
disciplina es del que corre, y hacerlo implícito escondería que la suite muta estado.

🔬 **El detalle:** Las claves de idempotencia también son fijas (`suite-04-order-0001`); en un
backend real, la segunda corrida devolvería `200` con `Idempotent-Replay` donde la suite espera
`201`, si el `TRUNCATE` de la semilla no las hubiera borrado. Lo borra.

### 5. 🟠 Diseña la entrada de `hurl` que probaría que dos peticiones **concurrentes** de `createOrder` con la misma clave crean un solo pedido. Explica por qué `hurl` no puede ejecutarla y qué herramienta usarías.

⏱️ **30 segundos:** Dos `POST` idénticos lanzados a la vez, y después un `GET /orders` que afirme
un solo pedido con esa clave. `hurl` ejecuta las entradas en secuencia; no puede lanzar dos a la
vez.

🗣️ **2 minutos:** `--jobs` paraleliza *archivos*, no entradas, y dos archivos no comparten
capturas. La prueba real se hace con un pequeño script Python (`concurrent.futures` con dos hilos y
`urllib`) o con una herramienta de carga, y después se verifica con `hurl`. Es la carrera que la
tabla `idempotency_keys` debe resolver con su clave primaria: la segunda inserción falla y devuelve
la respuesta de la primera.

🔬 **El detalle:** El capítulo de mensajería lo llama "dos entregas de la misma identidad
compiten" y recomienda una restricción única. Aquí es la misma restricción, en HTTP.

### 6. 🟠 Quita el `healthcheck` del servicio `mock`, corre `up --mock` seguido de `suite` y documenta el fallo con su salida literal. Vuelve a ponerlo.

⏱️ **30 segundos:** La salida es `(56) Recv failure: Connection reset by peer` en la primera
entrada de cada archivo; diez segundos después, la misma suite pasa lo que pasaba antes.

🗣️ **2 minutos:** Es la reproducción de §8 del taller. Lo que hay que anotar es que `up --wait`
terminó "bien": el fallo no está en el arranque sino en la definición de "listo". Al restaurar el
`healthcheck`, `--wait` tarda unos segundos más y la primera petición encuentra el puerto abierto.

🔬 **El detalle:** Con `docker compose ps` se ve la diferencia: sin `healthcheck` la columna de
estado dice `Up`; con él dice `Up (healthy)` solo cuando `wget` ha tenido éxito.

### 7. 🔴 Escribe la versión `v2` de `createOrder` en la que `lines` acepta `quantity` decimal para productos a granel. Define qué cambia en `Money`, en `OrderLine`, en la suite y **qué no cambia** en el núcleo, y argumenta si merece una ruta nueva o una cabecera de versión.

⏱️ **30 segundos:** `quantity` pasa a `string` decimal con unidad (`"2.500"`, `unit: "kg"`);
`Money` no cambia; `OrderLine` gana `unit`; el núcleo gana un value object `Quantity` y la regla de
redondeo del `lineTotal`. Merece `/api/v2/orders`, porque cambia el tipo de un campo obligatorio.

🗣️ **2 minutos:** Un cambio de tipo de `integer` a `string` rompe a todos los clientes de `v1`; no
es compatible hacia atrás y por tanto no es un cambio de cabecera ni de campo opcional. `v2`
convive con `v1` traduciendo al mismo puerto: `v1` construye `Quantity.units(2)` y `v2`
`Quantity.of("2.500", "kg")`. La suite gana una carpeta `v2/` y la de `v1` sigue pasando.

🔬 **El detalle:** El capítulo de DTO y errores lo dice: "versionar la ruta no obliga a versionar
el caso de uso"; dos adaptadores traducen al mismo comando. Lo que sí cambia en el núcleo es la
aritmética: `lineTotal` con cantidades decimales exige una política de redondeo explícita (medio
hacia arriba, dos cifras), que es una regla de negocio y vive en `Money`.

### 8. 🔥 Sustituye Prism por un mock hecho a mano en Python con `http.server` que respete la semántica de `Idempotency-Key` (memoria por clave). Mide cuántos archivos más de la suite pasan y cuáles siguen sin poder pasar.

⏱️ **30 segundos:** Con memoria por clave y por SKU, pasan `01`, `02` (si además valida las dos
contraseñas de la semilla) y buena parte de `04`; `05`, `06` y `07` no pasan sin implementar la
máquina de estados y el `PaymentGateway`.

🗣️ **2 minutos:** El ejercicio enseña dónde termina un mock y empieza un backend: en cuanto hay
memoria por clave, stock por SKU y estados por pedido, lo que se está escribiendo es el núcleo del
sistema, en Python, sin hexágono. Es una buena forma de sentir cuánto de la suite es negocio.

🔬 **El detalle:** Si el mock llega a pasar las siete, se ha implementado el sabor 06 sin
arquitectura. Compararlo después con el taller 06 (FastAPI) es un ejercicio de diseño en sí mismo:
mismo comportamiento, distinta dirección de dependencias.

---

## 02 · Frontend mínimo en React

### Preguntas

### 1. 🟢 ¿Qué es `OrdersApi` en términos del corpus y quién lo define?

⏱️ **30 segundos:** Es el puerto del frontend: lo que la UI necesita del sistema. Lo define el
consumidor —la UI— en vocabulario del contrato, no el adaptador HTTP.

🗣️ **2 minutos:** Igual que un puerto de salida del núcleo se define desde el caso de uso que lo
necesita, `OrdersApi` se define desde las pantallas: `login`, `createOrder`, `cancelOrder`… Los
adaptadores (fetch real, o fetch interceptado por MSW) lo implementan. Que su vocabulario coincida
con el contrato de `06/01` es lo que lo hace estable ante cinco backends.

🔬 **El detalle:** Es un puerto de *salida* desde el punto de vista del frontend (la UI lo
consume) y un *driving adapter* desde el punto de vista del backend. Las dos lecturas son
correctas: depende de dónde se ponga el hexágono.

### 2. 🟢 ¿Qué archivo es el composition root del frontend y qué decide?

⏱️ **30 segundos:** `main.tsx`: lee el modo y la URL base, arranca MSW si toca, construye
`HttpOrdersApi` y se lo pasa a `App`.

🗣️ **2 minutos:** Es el único archivo que importa una implementación del puerto y el único que
conoce `import.meta.env`. Ni `App.tsx` ni el adaptador leen configuración. Cambiar de backend es
cambiar una variable que solo `main.tsx` ve.

🔬 **El detalle:** El `import("./mock/browser")` dinámico hace que el código de MSW no entre en el
bundle si el modo no es `mock`; el composition root también decide qué se carga.

### 3. 🟢 ¿Por qué `App.tsx` no importa `httpOrdersApi.ts`?

⏱️ **30 segundos:** Porque la UI depende del puerto, no de un adaptador. Si importara la clase,
probarla exigiría red o MSW, y cambiar de transporte la tocaría.

🗣️ **2 minutos:** `App` recibe `api: OrdersApi` por props. Eso permite una `InMemoryOrdersApi`
en pruebas de componentes, y hace visible la regla de dependencias en un `grep`: `App.tsx`
importa `ordersApi.ts` y `types.ts`, nada más.

🔬 **El detalle:** Es la misma regla que el corpus verifica con ArchUnit en Java; en TypeScript se
puede automatizar con una regla de lint de imports restringidos.

### 4. 🟢 ¿Qué diferencia hay entre el mock de Prism de `06/01` y el mock MSW de este taller?

⏱️ **30 segundos:** Prism responde con los ejemplos del contrato y no tiene estado; MSW aquí
implementa reglas de negocio en memoria. Prism valida el contrato; MSW hace usable la UI.

🗣️ **2 minutos:** Prism sirve para comprobar formas y códigos sin escribir nada; MSW exige
escribir un backend de juguete, pero permite el flujo completo (stock que baja, pago que se
rechaza, cancelación que notifica). Son complementarios: el primero mide el YAML, el segundo mide
el adaptador y la UI.

🔬 **El detalle:** El mock MSW es "sin arquitectura" a propósito: reglas y parsing en un archivo.
Compararlo con un sabor real es ver la misma conducta con y sin dirección de dependencias.

### 5. 🟢 ¿Por qué la clave de idempotencia está en la firma del puerto?

⏱️ **30 segundos:** Porque cuándo se genera una clave nueva es una decisión del cliente (un
intento de compra, una clave), no del transporte.

🗣️ **2 minutos:** Si el adaptador la generara en cada llamada, un reintento de red crearía dos
pedidos; si la generara por sesión, dos compras distintas chocarían con `422`. La UI sabe qué es
un intento; el adaptador no. Por eso `App.tsx` llama a `crypto.randomUUID()` al pulsar "Crear
pedido" y la pasa.

🔬 **El detalle:** Un cliente robusto la guardaría hasta recibir respuesta, para reintentar con
la misma clave tras un timeout; esa persistencia sería también política del cliente.

### 6. 🟡 ¿Por qué en modo mock no existe una clase `MockOrdersApi`?

⏱️ **30 segundos:** Porque MSW intercepta `fetch`: el adaptador HTTP real es el que corre en
modo mock, y así queda ejercitado.

🗣️ **2 minutos:** Un `MockOrdersApi` que devolviera objetos saltaría rutas, cabeceras, códigos y
`problem+json`; en modo mock nada probaría el adaptador. Con MSW, el mismo `HttpOrdersApi`
serializa, envía `Idempotency-Key`, lee `Idempotent-Replay` y traduce errores. El "segundo
adaptador" es el mismo código con la red interceptada.

🔬 **El detalle:** La contrapartida es que el mock tiene que hablar HTTP de verdad (cabeceras,
códigos), que es más trabajo que devolver objetos; es trabajo que compra cobertura del adaptador.

### 7. 🟡 ¿Qué prueba `httpOrdersApi.test.ts` y qué no prueba?

⏱️ **30 segundos:** Prueba la traducción del adaptador: rutas, cabeceras, replay, `ApiError` con
`code` y `status`. No prueba la UI ni que el mock tenga razón.

🗣️ **2 minutos:** Las diez pruebas son las situaciones de la suite `hurl` vistas desde el cliente.
Si un sabor pasa la suite y la UI falla contra él, el defecto está en el adaptador o en la UI, y
estas pruebas acotan cuál. Lo que no cubren: renderizado, estado de React, y cualquier
divergencia entre el mock y un backend real.

🔬 **El detalle:** `onUnhandledRequest: "error"` en `server.listen` hace fallar la prueba si el
adaptador pide una ruta que el mock no conoce: es la forma de detectar una ruta mal escrita.

### 8. 🟡 ¿Por qué `createOrder` devuelve `{ order, replayed }` y no solo `Order`?

⏱️ **30 segundos:** Porque la repetición idempotente es parte del contrato (`200` +
`Idempotent-Replay`) y la UI puede querer decirlo; si el puerto devolviera solo `Order`, esa
información moriría en el adaptador.

🗣️ **2 minutos:** El adaptador lee la cabecera y la traduce a un booleano con nombre de negocio;
la UI no sabe de cabeceras. Es el mismo principio que devolver `UnknownResult` desde un
`PaymentGateway`: lo que el contrato distingue, el puerto lo distingue.

🔬 **El detalle:** Alternativa: un tipo `CreateOrderResult = { kind: "created" | "replayed"; order }`.
Más expresivo; el booleano se eligió por brevedad.

### 9. 🟡 ¿Qué hace `run` en `App.tsx` y con qué pieza del backend se corresponde?

⏱️ **30 segundos:** Envuelve toda llamada al puerto, limpia el estado de error y convierte
`ApiError` en un banner por `code`. Es el traductor central de errores, como el `@ControllerAdvice`
de un backend.

🗣️ **2 minutos:** Sin `run`, cada botón repetiría el `try/catch` y la decisión de qué mostrar.
Con él, la UI decide una vez cómo presentar un error propio y deja pasar los inesperados con un
mensaje genérico. Es la regla "traducir una vez por frontera" aplicada al frontend.

🔬 **El detalle:** `run` está en `useCallback` sin dependencias porque no cierra sobre estado; si
lo hiciera, habría que declararlo o se leería estado viejo.

### 10. 🟡 ¿Por qué las diez pruebas pasaban con un error de tipos en `handlers.ts`?

⏱️ **30 segundos:** Porque Vitest transpila TypeScript sin comprobar tipos; el `unknown` se
serializaba bien en runtime.

🗣️ **2 minutos:** Es el mismo hecho que el corpus repite para Node: los tipos desaparecen al
ejecutar. `npm test` en verde no significa que el proyecto compile; por eso `build` empieza por
`tsc --noEmit` y por eso `typecheck` existe como script aparte.

🔬 **El detalle:** La corrección fue tipar el cuerpo guardado como `Record<string, unknown>`, que
`HttpResponse.json` acepta. Un `as` es una afirmación, no una comprobación; en el mock es
aceptable porque lo que se guardó fue un objeto que el propio handler serializó.

### 11. 🟠 Un backend devuelve `amount` como número. Ni `tsc` ni las pruebas lo detectan. ¿Qué lo detecta y por qué es correcto que sea así?

⏱️ **30 segundos:** Lo detecta la suite `hurl` (`jsonpath "$.total.amount" == "109.70"` falla con
`109.7`). Es correcto porque el contrato es del backend, y su cumplimiento se mide en el backend.

🗣️ **2 minutos:** Los tipos de `api/types.ts` son una promesa, no una validación; las pruebas
del adaptador corren contra el mock, que cumple el contrato por construcción. Poner validación
runtime en el frontend (un schema por respuesta) sería defenderse del backend; es legítimo en un
cliente público, pero aquí duplicaría lo que la suite ya garantiza.

🔬 **El detalle:** Si el frontend fuera de otro equipo, la validación runtime en el borde del
cliente sería lo prudente: el capítulo de Node lo dice para el backend, y la simetría aplica.

### 12. 🟠 El equipo quiere que el adaptador reintente `createOrder` automáticamente tras un timeout. ¿Es correcto por contrato? ¿Dónde pondrías la decisión?

⏱️ **30 segundos:** Por contrato es seguro **solo con la misma clave**. La decisión de reintentar
es política del cliente y va fuera del transporte: en la UI o en un envoltorio del puerto, no en
`HttpOrdersApi`.

🗣️ **2 minutos:** Reintentar con la misma `Idempotency-Key` devuelve el pedido original o lo crea
una sola vez; reintentar con otra clave crea dos. Como la clave la pasa la UI, el reintento con la
misma clave es trivial desde la UI. Un decorador `RetryingOrdersApi` que implemente el puerto
sería la forma limpia: la política queda visible y probable sin tocar el adaptador.

🔬 **El detalle:** Presupuesto de reintentos y deadline total aplican igual que en el capítulo de
resiliencia: tres reintentos de 3 s no caben en una UI que espera 5 s.

### 13. 🟠 `VITE_API_MODE=mock vite` funcionaba en tu máquina. ¿Por qué se cambió y qué regla general del bloque aplica?

⏱️ **30 segundos:** Porque `VAR=valor comando` es sintaxis de shell POSIX y no existe en
`cmd.exe` ni PowerShell. La regla: lo que depende del shell no es multi-OS; se cambió a `vite
--mode mock` con `.env.mock`.

🗣️ **2 minutos:** Es la misma razón por la que la orquestación del bloque es `lab.py` en Python y
no scripts `bash`. Vite resuelve el problema en su propio dominio: `.env.<modo>` se carga con
`--mode`, y `import.meta.env` expone las `VITE_*`.

🔬 **El detalle:** `cross-env` habría sido la solución típica; añadir una dependencia para
evitar una sintaxis es peor que usar el mecanismo que la herramienta ya trae.

### 14. 🟠 ¿Qué habría que cambiar en el frontend para que el sabor Java y el sabor Go se usen alternadamente durante una demo? Defiende que sea solo eso.

⏱️ **30 segundos:** Solo `VITE_API_BASE_URL` (o `--base-url` en `lab.py front`). Nada en `src/`.

🗣️ **2 minutos:** Los dos sabores pasan la misma suite, así que hablan el mismo contrato, y el
adaptador solo conoce la URL base. Si hiciera falta tocar `src/`, sería porque un sabor no cumple
el contrato (y la suite lo habría dicho) o porque la UI conoce algo del transporte que no debería.

🔬 **El detalle:** Para alternar sin reiniciar, la URL base podría ser un campo en la UI que
reconstruya el adaptador; eso movería la decisión del composition root a la UI, que es
aceptable en una demo y discutible en producción.

### Ejercicios

### 1. 🟢 Corre `front --mock`, entra como `ana`, añade `SKU-004` al carrito y crea el pedido. Anota qué muestra el banner y en qué archivo se decidió cada palabra que ves.

⏱️ **30 segundos:** `INSUFFICIENT_INVENTORY (409) SKU-004: requested 1, available 0` y debajo
`lines[0].quantity: requested 1, available 0`.

🗣️ **2 minutos:** El `code`, el `status`, el `detail` y `errors` los decidió `mock/handlers.ts`
(en un backend real, su adaptador HTTP); el formato del banner lo decidió `App.tsx`; que el error
llegue como `ApiError` con `problem` lo decidió `httpOrdersApi.ts`. Tres archivos, tres
responsabilidades.

🔬 **El detalle:** El `title` ("Insufficient inventory") no aparece porque la UI prefiere
`detail` cuando existe; es una decisión de presentación.

### 2. 🟢 Entra como `ops@hex.local`, cancela un pedido de `ana` (créalo antes con `ana`) y carga las notificaciones. Explica por qué `ops` puede cancelar un pedido ajeno y `ana` no puede leer notificaciones.

⏱️ **30 segundos:** `ops` es `operator`: ve y opera cualquier pedido. Las notificaciones son de
`operator` por contrato; `ana` recibe `403 FORBIDDEN`.

🗣️ **2 minutos:** Son dos reglas distintas: la primera es autorización contextual sobre un
recurso (dueño u operador), la segunda es una capacidad gruesa sobre una colección. En el
backend, la primera vive en el caso de uso y la segunda puede vivir en el borde; en el mock las
dos están en `findOrder` y en el handler de notificaciones.

🔬 **El detalle:** La notificación va a `ana@hex.local` aunque la cancelara `ops`: el destinatario
es el dueño del pedido, no el actor. Es un dato del pedido, no del request.

### 3. 🟡 Añade a `httpOrdersApi.test.ts` una prueba de que `logout` con el token ya revocado produce `ApiError 401` y que el adaptador no vuelve a enviar `Authorization` después.

⏱️ **30 segundos:** Tras `login` y `logout`, guardar el token, volver a inyectarlo no es posible
desde fuera; se prueba con un `fetchImpl` espía que capture las cabeceras.

🗣️ **2 minutos:** `HttpOrdersApi` acepta `fetchImpl` por constructor justo para esto: un
envoltorio que registre cada `Request` y delegue en `fetch`. La prueba afirma que la petición
posterior al `logout` no lleva `Authorization`. Para el `401` del segundo `logout` hace falta un
token revocado: se obtiene con un segundo `login` que se revoca, y luego se fuerza la cabecera con
el espía.

🔬 **El detalle:** El adaptador olvida el token también al recibir `TOKEN_REVOKED`; probar ambas
rutas (olvido por `logout` y olvido por `401`) es lo que cierra el contrato del token.

### 4. 🟡 Haz que el banner de error muestre un texto en español por cada `ProblemCode`, con un mapa `code → mensaje` en un solo archivo. Explica por qué ese mapa vive en la UI y no en el adaptador.

⏱️ **30 segundos:** `const MESSAGES: Record<ProblemCode, string>` en `src/ui/messages.ts`; el
banner busca por `error.problem.code`. Vive en la UI porque es presentación e idioma.

🗣️ **2 minutos:** El adaptador traduce protocolo a error propio; qué frase ve el usuario, y en
qué idioma, es de la capa que lo muestra. Si el mapa estuviera en el adaptador, cambiar de idioma
tocaría el transporte. `Record<ProblemCode, string>` obliga al compilador a exigir un mensaje por
código: un `ProblemCode` nuevo sin mensaje no compila.

🔬 **El detalle:** `detail` sigue siendo útil para el operador; se puede mostrar debajo, en
pequeño, como "detalle técnico".

### 5. 🟠 Añade paginación real al catálogo: un botón "Más" que use `nextCursor`. El mock ya pagina; comprueba con `limit=2` y describe qué tuvo que cambiar en el puerto (nada) y en la UI.

⏱️ **30 segundos:** La UI guarda `nextCursor` y llama `listProducts(cursor)` al pulsar "Más",
concatenando `items`. El puerto ya recibía `cursor?`.

🗣️ **2 minutos:** El cursor es opaco: la UI lo devuelve tal cual. El `limit` no está en el puerto
a propósito (el contrato lo acota a 100 y la UI no necesita elegirlo); si se quisiera exponer,
sería un cambio de puerto, pequeño y justificado.

🔬 **El detalle:** Probar con `limit=2` exige o bien añadir `limit` al puerto o bien una prueba
del adaptador que llame la ruta con el parámetro; la segunda es más honesta con el diseño.

### 6. 🟠 Escribe una segunda implementación del puerto, `InMemoryOrdersApi`, sin `fetch` ni MSW, y úsala en una prueba de `App.tsx` con `@testing-library/react`. Compara qué cubre esa prueba frente a la de `httpOrdersApi.test.ts` y cuándo elegirías cada una.

⏱️ **30 segundos:** `InMemoryOrdersApi` prueba la UI (render, botones, banners) sin red; la de
MSW prueba el adaptador. Ninguna sustituye a la otra.

🗣️ **2 minutos:** La prueba de componentes falla si un botón no llama al puerto o si el banner no
muestra el `code`; la del adaptador falla si una ruta o cabecera está mal. Elegir una sola deja
una frontera sin cubrir. Es el "testing por anillos" del corpus aplicado al frontend.

🔬 **El detalle:** `InMemoryOrdersApi` puede reutilizar `mock/state.ts` para no duplicar reglas;
lo que no reutiliza es `handlers.ts`, que es HTTP.

### 7. 🔴 El contrato añade `GET /api/v1/orders/{orderId}/payment` para consultar al proveedor cuando el pedido está `PAYMENT_PENDING`. Extiende puerto, adaptador, mock y UI, y decide qué debe pasar en la UI si la consulta también devuelve pendiente. Documenta qué parte del cambio es contrato y qué parte es política del cliente.

⏱️ **30 segundos:** Contrato: la ruta, `PaymentResponse` como respuesta, `404` y `409` si no
hay pago. Cliente: cuándo consultar (botón "Consultar" o sondeo) y qué hacer si sigue pendiente
(mostrar "en verificación", no reintentar el pago).

🗣️ **2 minutos:** El puerto gana `getPayment(orderId)`; el adaptador, una ruta; el mock, un
handler que resuelve pendiente → autorizado a la segunda consulta (o nunca, configurable). La
política del cliente es no ofrecer "Pagar" mientras esté pendiente: el contrato ya lo hace
imposible con `409`, pero la UI no debería llegar a ese `409`.

🔬 **El detalle:** El sondeo automático es tentador y peligroso: sin presupuesto, una pantalla
abierta consulta al proveedor para siempre. Si se sondea, con límite y backoff, y se dice.

### 8. 🔥 Sustituye el `useState` de `App.tsx` por un `useReducer` con acciones por intención (`ORDER_CREATED`, `PAYMENT_RESOLVED`, …) sin cambiar el puerto ni las pruebas. Argumenta si el reducer es "dominio" del frontend o solo presentación.

⏱️ **30 segundos:** Es presentación con nombres de negocio: decide qué se ve, no qué es válido.
Las invariantes (qué pedido es cancelable) siguen en el backend.

🗣️ **2 minutos:** Un reducer por intención mejora legibilidad y hace las transiciones de pantalla
probables sin React. Pero si empieza a decidir "este pedido no se puede cancelar" antes de
llamar al puerto, está duplicando una invariante del núcleo, y eso divergirá. La regla del
corpus: validar forma en el borde, invariantes en el dominio; el frontend es borde.

🔬 **El detalle:** Un uso legítimo de conocer estados en la UI es *deshabilitar* botones por
comodidad; la decisión final sigue siendo del backend, y la UI debe seguir mostrando bien el
`409` si llega.

---

## 03 · Java y Spring Boot

### Preguntas

### 1. 🟢 ¿Por qué los casos de uso no llevan `@Service` ni `@Transactional`?

⏱️ **30 segundos:** Porque son Java ordinario: reciben puertos por constructor y los ensambla
`OrdersConfiguration`. La transacción es un puerto (`UnitOfWork`), no una anotación.

🗣️ **2 minutos:** `@Service` los haría depender del escaneo de Spring y `@Transactional` de un
proxy; ninguna de las dos cosas es política de negocio. Sin anotaciones, `CreateOrderTest` los
instancia con `new` y fakes, y ArchUnit puede exigir que `application` no importe Spring. El coste
es escribir los `@Bean` a mano; la ganancia es que el núcleo compila sin el framework.

🔬 **El detalle:** Es la recomendación del capítulo 05/02: si Spring delimita la transacción, que
sea en un facade consciente del proxy; aquí ni eso, porque `TransactionTemplate` no necesita proxy.

### 2. 🟢 ¿Qué es `UnitOfWork` y cuál es su adaptador?

⏱️ **30 segundos:** Un puerto de salida con `<T> T run(Supplier<T>)`: "ejecuta esto y confirma
todo o nada". El adaptador es un `TransactionTemplate` de Spring construido en el composition root.

🗣️ **2 minutos:** El caso de uso decide qué operaciones forman una decisión (02/05) y las envuelve
en `run`. No sabe si detrás hay JDBC, JPA o nada (en pruebas, un doble que restaura fakes). Al no
haber proxy, una llamada interna entre métodos del mismo objeto no puede saltarse la transacción.

🔬 **El detalle:** `TransactionTemplate.execute` hace rollback si el `Supplier` lanza una
`RuntimeException`; `InsufficientInventory` extiende `RuntimeException` por eso. Una excepción
comprobada no revertiría por defecto.

### 3. 🟢 ¿Por qué `Order` y `OrderEntity` son dos clases?

⏱️ **30 segundos:** Porque una protege invariantes y la otra describe columnas. Compartirlas
obliga al dominio a tener setters, constructor vacío y anotaciones JPA, y a arrastrar el ciclo de
vida de la sesión.

🗣️ **2 minutos:** `Order` tiene constructor privado, fábricas y métodos con reglas; `OrderEntity`
tiene campos de paquete y `@Column`. `JpaOrders` traduce en `save` y `toOrder`. El precio es ese
mapper; la ganancia es que `OrderTest` no necesita Hibernate y que cambiar una columna no toca
una regla.

🔬 **El detalle:** Para un CRUD estable el capítulo 04/01 admite un solo modelo con excepción
declarada; aquí hay máquina de estados y dos bases, y la separación paga.

### 4. 🟢 ¿Dónde vive la regla "solo el dueño o un operator ve el pedido" y por qué no en `SecurityConfiguration`?

⏱️ **30 segundos:** En `Actor.canSee(order)`, que `GetOrder`, `AuthorizePayment` y `CancelOrder`
aplican. `SecurityConfiguration` solo decide qué rutas exigen token.

🗣️ **2 minutos:** Es autorización contextual: depende del recurso, no de la ruta. Un job o un
consumidor que use `CancelOrder` tiene que cumplirla igual, y un filtro HTTP no los cubre. Además,
la respuesta correcta es `404` (no revelar existencia), y eso es una decisión que el caso de uso
toma devolviendo `NotFound`.

🔬 **El detalle:** La capacidad gruesa (`operator` para dar de alta productos) también está en el
caso de uso (`requireOperator`), aunque el borde pudiera filtrarla: por la misma razón.

### 5. 🟢 ¿Qué comprueba `ArchitectureTest` que un `grep` no comprobaría?

⏱️ **30 segundos:** Lo mismo, pero en el build y sobre el bytecode: dependencias por herencia,
anotaciones y tipos de retorno, no solo `import` textuales, y falla la compilación de pruebas.

🗣️ **2 minutos:** Un `grep` de `import org.springframework` en `domain/` se salta un
`jakarta.persistence.Entity` o una referencia con nombre calificado; ArchUnit analiza clases
importadas y sus dependencias reales. Y está en `mvn test`: nadie tiene que acordarse de correrlo.

🔬 **El detalle:** Las tres reglas son deliberadamente estrechas (dominio, aplicación, inbound ↔
outbound). Reglas más ambiciosas ("todo adaptador implementa un puerto") suelen producir falsos
positivos y se acaban ignorando.

### 6. 🟡 ¿Por qué `AuthorizePayment` usa dos unidades de trabajo y no una?

⏱️ **30 segundos:** Para que la llamada al proveedor no ocurra con una transacción abierta.
Primera transacción: comprobar; llamada al proveedor sin transacción; segunda: aplicar y guardar.

🗣️ **2 minutos:** Una transacción que espera a un tercero mantiene bloqueos por un tiempo que no
controlamos y no vuelve atómico el cobro (02/05). Con el gateway determinista la diferencia es
invisible; con el gRPC del taller 10 sería un bloqueo de segundos por pedido. El diseño se hace
para el proveedor real aunque el de hoy sea local.

🔬 **El detalle:** Queda una carrera aceptada: dos intentos con claves distintas pueden pasar la
primera comprobación a la vez. La clave persistida con el efecto y la unicidad de `operation_id`
en `payments` limitan el daño; cerrar la carrera del todo exigiría un estado intermedio
("cobrando").

### 7. 🟡 ¿Qué garantiza que un `409 INSUFFICIENT_INVENTORY` no deje reservas huérfanas, y qué prueba lo demuestra?

⏱️ **30 segundos:** La transacción de `UnitOfWork`: `reserve` lanza al primer faltante y todo lo
anterior —pedido, reservas, clave— se revierte. Lo demuestra
`CreateOrderTest.insufficientInventoryLeavesNothingBehind`.

🗣️ **2 minutos:** El orden de las llamadas no lo garantiza: el pedido se guarda antes de reservar
(la FK lo exige). La prueba usa `SnapshotUnitOfWork`, que restaura los fakes si el trabajo lanza,
y afirma que no queda pedido ni clave; con un `UnitOfWork` que no revirtiera, la prueba falla, y
debe fallar.

🔬 **El detalle:** El adaptador real descuenta con `UPDATE … WHERE available >= :q` y no hace
`SELECT` previo: dos pedidos por la última unidad no pueden ganar los dos, sin `FOR UPDATE`.

### 8. 🟡 ¿Por qué `JpaOrders` carga las líneas con `EAGER` y qué relación tiene con `open-in-view: false`?

⏱️ **30 segundos:** Porque fuera del caso de uso no hay sesión JPA: con `open-in-view: false`, un
proxy lazy que el controller tocara lanzaría `LazyInitializationException`. Un agregado se
reconstruye completo o no se devuelve.

🗣️ **2 minutos:** `open-in-view: true` (el defecto de Boot) mantiene la sesión abierta durante
toda la petición y esconde el problema: el controller dispara consultas al serializar. Apagarlo
obliga a que el adaptador decida qué carga, que es lo correcto, y a que el dominio no devuelva
nada que vaya a la base después.

🔬 **El detalle:** El coste es una consulta más por pedido (líneas) y otra por el último pago. Para
`listOrders` con páginas de 20 son 40 consultas: un N+1 asumido y declarado, que una proyección de
lectura resolvería si el volumen lo exigiera.

### 9. 🟡 ¿Qué hace `TableNotifier` para que "al menos una vez" no se convierta en "dos filas"?

⏱️ **30 segundos:** Usa el `eventId` como clave primaria de la notificación y comprueba
`existsById` antes de insertar. Una segunda entrega del mismo hecho no crea otra fila.

🗣️ **2 minutos:** El dispatcher puede caer entre `notify` y `markPublished`; la siguiente ronda
vuelve a entregar. Un `Notifier` que mande un correo tendría que deduplicar igual, por `eventId`,
antes de enviar. Es la responsabilidad que el capítulo 04/03 asigna al consumidor.

🔬 **El detalle:** `existsById` + `save` no es atómico entre dos dispatchers concurrentes; la
clave primaria sí lo es: el segundo `INSERT` fallaría. Con un solo dispatcher, como aquí, basta.

### 10. 🟡 ¿Qué tuvo que cambiar y qué no para llevar el catálogo a MongoDB?

⏱️ **30 segundos:** Tres archivos nuevos en `outbound/mongo/` y la selección `hex.catalog` en el
composition root, que ya existía. En `domain/`, `application/` e `inbound/`, nada.

🗣️ **2 minutos:** Porque `Products` era un puerto con vocabulario de negocio y la composición
"producto + stock" ya ocurría en aplicación uniendo dos puertos por `sku`. Si hubiera sido un JOIN
en el adaptador, la parte 3 habría empezado por reescribir la lectura. La evidencia es la suite en
verde dos veces y los productos nuevos apareciendo en Mongo y no en la tabla `products`.

🔬 **El detalle:** El inventario no se movió: es otra unidad de consistencia (reserva atómica),
y la FK entre `products` e `inventory` no existía desde el esquema de `06/01` precisamente para
esto.

### 11. 🟠 El `TOKEN_REVOKED` llegaba como `UNAUTHENTICATED`. ¿Qué frontera del framework lo causó y cómo se resolvió sin tocar el caso de uso?

⏱️ **30 segundos:** El proveedor JWT de Spring envuelve cualquier fallo de validación en
`InvalidBearerTokenException` con código `invalid_token`; el `token_revoked` del validador queda
en la causa. Se resolvió leyendo la cadena de causas en el entry point.

🗣️ **2 minutos:** Es una traducción de errores del propio framework, con pérdida: conserva el
mensaje y la causa, no el código. La corrección está entera en el borde
(`ProblemAuthenticationEntryPoint`); ni `Logout` ni `TokenRevocationStore` cambiaron, porque la
revocación funcionaba; lo que fallaba era cómo se presentaba.

🔬 **El detalle:** La alternativa de comparar el mensaje ("token revoked") habría funcionado y
sería frágil: los mensajes cambian entre versiones; los códigos de `OAuth2Error` son contrato.

### 12. 🟠 El backend habló con el Mongo equivocado y la suite lo detectó. ¿Qué dos decisiones del bloque hicieron posible detectarlo?

⏱️ **30 segundos:** Los puertos no estándar del laboratorio (`17017`) y la suite de contrato con
reglas de negocio. Con Mongo en `27017` el error habría sido invisible; sin la suite, nadie habría
consultado el catálogo.

🗣️ **2 minutos:** La propiedad renombrada se ignoró en silencio y el cliente cayó al puerto por
defecto, donde había otro Mongo con autenticación. Si ese Mongo hubiera sido el nuestro, el
backend habría "funcionado" contra la base equivocada. La suite convirtió el silencio en seis
archivos en `500` con el puerto en el mensaje.

🔬 **El detalle:** Verificar el nombre correcto se hizo contra los metadatos del jar
(`spring-configuration-metadata.json` en `spring-boot-mongodb-4.1.1.jar`), no contra la memoria:
la regla de versiones verificadas de la guía aplicada a una propiedad.

### 13. 🟠 `jsonb` devolvió `{"ref": "…"}` con espacio y rompió la repetición idempotente. ¿Qué tipo de acoplamiento había y cómo lo evitarías desde el diseño?

⏱️ **30 segundos:** Acoplamiento al formato textual de un tipo que no es texto. Se evita
tratando la columna como JSON: un parser, o un tipo mapeado (`Map` con `SqlTypes.JSON`), o no
guardar JSON si solo se necesita un id.

🗣️ **2 minutos:** El adaptador guardaba un `String` con forma de JSON y lo leía por posición;
`jsonb` lo normaliza (reordena, quita duplicados, espacia). Lo mínimo fue leer por patrón; lo
correcto sería que el adaptador hable JSON con un parser. Y la pregunta de diseño: la columna
`response_body` es `jsonb` por el contrato del esquema compartido; este sabor solo necesita una
referencia. Un esquema propio tendría `order_id uuid`.

🔬 **El detalle:** El mismo error afectó a la outbox (`customerId` del payload). Dos lecturas por
posición, dos fallos; una utilidad común los habría concentrado en un solo sitio.

### 14. 🟠 Un compañero propone quitar `UnitOfWork` y poner `@Transactional` en los controllers "para simplificar". Defiende o refuta con lo que este taller mostró.

⏱️ **30 segundos:** Refuto: movería el límite de consistencia al transporte, mantendría abierta la
transacción durante la llamada al proveedor en `AuthorizePayment`, y haría que un job o consumidor
que reutilice el caso de uso no tenga transacción.

🗣️ **2 minutos:** El límite lo define quien conoce la decisión de negocio, no quien conoce HTTP.
Con `@Transactional` en el controller, `AuthorizePayment` perdería sus dos transacciones y el
cobro remoto ocurriría con filas bloqueadas; `CreateOrderTest` no podría probar el rollback sin
levantar Spring; y `CancelOrder` desde el JMS del taller 08 llegaría sin transacción. "Simplificar"
aquí es esconder.

🔬 **El detalle:** Lo que sí simplificaría con criterio: un `UnitOfWork` con `runInNew` para
casos concretos (el dispatcher por fila), añadido cuando haga falta y no antes.

### Ejercicios

### 1. 🟢 Pon `@Entity` en `Order` (solo la anotación) y corre `lab.py java --test`. Pega la salida de ArchUnit y explica qué regla falló.

⏱️ **30 segundos:** Falla `domainDependsOnNothingOutside`: `Order` pasa a depender de
`jakarta.persistence.Entity`, que está en la lista prohibida.

🗣️ **2 minutos:** El mensaje de ArchUnit nombra la clase, la anotación y la regla. Es la única
línea de defensa automática contra "solo es metadata": el capítulo 01/02 dice que una anotación
también es una dependencia de compilación y de modelo.

🔬 **El detalle:** Hibernate además exigiría constructor sin argumentos y campos accesibles;
`Order` no los tiene. La regla falla antes de que eso importe.

### 2. 🟢 Cambia `poll-ms` de la outbox a `5000` y corre solo `07-notifications.hurl`. Explica por qué pasa igual y qué cambió en la duración.

⏱️ **30 segundos:** Pasa porque `hurl` reintenta 20 veces cada 500 ms (hasta 10 s) y el
dispatcher entrega en menos de 5 s; la duración del archivo sube de ~2 s a ~5 s.

🗣️ **2 minutos:** La suite no asume un tiempo de entrega: asume que la entrega ocurre. Es la
forma correcta de probar lo asíncrono; con `poll-ms: 15000` la suite fallaría, y también sería
correcto que fallara: el contrato promete la notificación en un tiempo razonable.

🔬 **El detalle:** La segunda comprobación del archivo (que no haya segunda notificación) espera
1,5 s fijos; con `poll-ms` alto seguiría siendo verdadera, pero por la razón equivocada.

### 3. 🟡 Añade `@Transactional` a `CreateOrder.execute` y quita `unitOfWork.run`. Corre la suite. ¿Pasa? Explica por qué sí, y qué habrías perdido aunque pase (pista: `AuthorizePayment`).

⏱️ **30 segundos:** Pasa, siempre que `CreateOrder` sea un bean que Spring pueda proxear (lo es:
lo crea `@Bean`). Se pierde la portabilidad del caso de uso, la prueba sin Spring, y el patrón
de dos transacciones de `AuthorizePayment` si se hiciera lo mismo allí.

🗣️ **2 minutos:** Que la suite pase demuestra que el comportamiento externo es el mismo; no
demuestra que el diseño lo sea. `CreateOrderTest` dejaría de probar el rollback (no hay proxy en
`new CreateOrder(...)`), y ArchUnit fallaría por el import de `org.springframework.transaction`.

🔬 **El detalle:** Con clases `final` como `CreateOrder`, el proxy CGLIB no puede crearse: habría
que quitar `final`. Otro detalle del framework que se filtra al núcleo.

### 4. 🟡 Provoca la carrera de la última unidad: dos `POST /orders` concurrentes por el último `SKU-005` (stock 3 → pide 3 dos veces). Explica por qué el `UPDATE … WHERE available >= :q` hace que uno gane y otro reciba `409`, sin `SELECT FOR UPDATE`.

⏱️ **30 segundos:** El `UPDATE` condicional es atómico por fila: el segundo espera al bloqueo del
primero, reevalúa `available >= 3` sobre la fila ya actualizada (0) y afecta 0 filas → `409`.

🗣️ **2 minutos:** Un `SELECT` seguido de `UPDATE` sin bloqueo dejaría que ambos leyeran 3 y
descontaran, con `available` negativo o un `CHECK` violado (500). El `UPDATE` con condición mueve
la decisión a la base, que serializa escrituras sobre la misma fila. Se prueba con dos hilos en
Python (`concurrent.futures`) y claves distintas.

🔬 **El detalle:** El `CHECK (available >= 0)` del esquema es la última defensa: si el `WHERE` se
olvidara, el segundo `UPDATE` fallaría con una violación de restricción en vez de un `409` limpio.

### 5. 🟠 Sustituye la lectura por patrón de `JpaIdempotencyStore` por un `Map<String, String>` mapeado con `@JdbcTypeCode(SqlTypes.JSON)`. Explica qué gana y qué cuesta frente al `String`.

⏱️ **30 segundos:** Gana que Hibernate serializa y deserializa con Jackson: sin patrones, sin
formato. Cuesta una dependencia del mapeo JSON de Hibernate y un tipo menos transparente en la
entidad.

🗣️ **2 minutos:** Con `Map`, `responseBody.get("ref")` es la lectura; el problema del espacio
desaparece porque nunca se ve texto. Es lo que "hablar JSON" significa. La entidad se acopla al
serializador de Hibernate, que ya estaba en el classpath.

🔬 **El detalle:** El mismo cambio en `OutboxEntity.payload` elimina la segunda lectura por
patrón. Y la pregunta de fondo sigue: si solo hace falta un id, `uuid` sería la columna honesta.

### 6. 🟠 Escribe una prueba de contrato del puerto `Orders` con Testcontainers (PostgreSQL 17.11): guardar, recargar y comprobar que `status`, `version` y las líneas sobreviven. Decide si la misma prueba debe correr también contra el fake de `CreateOrderTest`, y por qué.

⏱️ **30 segundos:** Sí: el contrato del puerto es uno, y el fake debe cumplirlo. La prueba se
escribe una vez, parametrizada por implementación (`JpaOrders` con Testcontainers,
`InMemoryOrders` sin nada).

🗣️ **2 minutos:** Es el "test de contrato de puerto" del capítulo 04/06: mismas expectativas
sobre el doble y el adaptador real. Detecta fakes que mienten (un `InMemoryOrders` que no guarde
`version`) y adaptadores que pierden datos. Testcontainers cuesta arranque; se usa solo aquí, no
para cada regla.

🔬 **El detalle:** `spring-boot-testcontainers` y `@ServiceConnection` evitan configurar la URL a
mano; el esquema se carga desde `contrato/seed/schema.sql` como script de inicialización del
contenedor.

### 7. 🔴 Implementa `GET /api/v1/orders/{id}/payment` (consulta al proveedor para un pedido `PAYMENT_PENDING`) sin tocar `domain/`. Define el puerto nuevo, el adaptador determinista y el cambio en `AuthorizePayment` o en un caso de uso nuevo. Argumenta cuál.

⏱️ **30 segundos:** Caso de uso nuevo `CheckPayment`; puerto `PaymentGateway.status(operationId)`
(o un puerto aparte); adaptador determinista que resuelve pendiente → autorizado a la segunda
consulta. `Order.applyPayment` ya sabe pasar de `PAYMENT_PENDING` a `PAID`… si `isPayable` lo
permite.

🗣️ **2 minutos:** Y ahí está la trampa del enunciado: `isPayable()` excluye `PAYMENT_PENDING`, así
que aplicar el resultado de la consulta sí toca `domain/`: hace falta un `resolvePayment` que
acepte pendiente como origen. Lo honesto es decirlo: la regla "sin tocar dominio" no se cumple
porque el dominio no tenía la transición; y eso es correcto, porque la transición es negocio.

🔬 **El detalle:** Separar `CheckPayment` de `AuthorizePayment` mantiene una intención por caso
de uso y evita que "pagar" y "consultar" compartan clave de idempotencia.

### 8. 🔥 Convierte `hex.catalog` en una decisión por petición: un header `X-Catalog: mongo` que el composition root traduce a un `Products` distinto. Explica por qué es una mala idea aunque funcione, y qué lección hexagonal contradice.

⏱️ **30 segundos:** Funciona con un `Products` que delegue según un contexto de petición. Es mala
idea porque un detalle de persistencia pasa a ser parte del contrato HTTP y a depender del cliente.

🗣️ **2 minutos:** Contradice la regla de que el contrato no dice dónde vive el catálogo (06/01 §4)
y la de que la composición se decide al arrancar, no por petición (04/04). Además rompe la
consistencia: un producto creado "en Mongo" no existe para el siguiente request "en Postgres".

🔬 **El detalle:** El caso legítimo parecido es una migración con doble lectura (04/07), decidida
por configuración y por un tiempo acotado, nunca por el cliente.

---

## 04 · TypeScript y NestJS

### Preguntas

### 1. 🟢 ¿Por qué los puertos necesitan un `Symbol` en NestJS y no en Spring?

⏱️ **30 segundos:** Porque una `interface` de TypeScript desaparece al compilar y Nest no tiene
nada por lo que resolverla; Java conserva la interfaz en runtime y Spring resuelve por tipo.

🗣️ **2 minutos:** Nest inyecta por el tipo que `emitDecoratorMetadata` deja en el constructor; para
una interfaz ese tipo es `Object`. Un `Symbol` (`ORDERS`) es un valor real que sirve de clave en
el contenedor; `@Inject(ORDERS)` en el consumidor o `inject: [ORDERS]` en una `useFactory` lo
resuelven. El token es composición: no convierte al adaptador en mejor puerto.

🔬 **El detalle:** Registrar los adaptadores como clases (`PrismaOrders`) y luego `{ provide:
ORDERS, useExisting: PrismaOrders }` evita instanciar dos veces y deja visible el enlace en un
solo archivo.

### 2. 🟢 ¿Qué hace `useFactory` en `app.module.ts` y por qué los casos de uso no llevan `@Injectable()`?

⏱️ **30 segundos:** `useFactory` construye el caso de uso con `new` y sus puertos resueltos por
token. Sin `@Injectable()`, el caso de uso no importa `@nestjs/common` y `depcruise` puede
prohibirlo.

🗣️ **2 minutos:** Es el equivalente de los `@Bean` de Java: el composition root sabe qué
implementación va en cada puerto; el caso de uso solo conoce interfaces. Como los casos de uso son
clases normales, `vitest` los prueba con `new` y fakes, sin contenedor ni decoradores.

🔬 **El detalle:** El propio caso de uso hace de token (`provide: CreateOrder`): es una clase, y
por tanto un valor en runtime; los controllers lo piden con `@Inject(CreateOrder)`.

### 3. 🟢 ¿Qué es `prisma.db` y qué devuelve dentro y fuera de una transacción?

⏱️ **30 segundos:** Un getter de `PrismaService`: la transacción en curso (`AsyncLocalStorage`) si
la hay, o el cliente raíz si no. Los adaptadores solo usan `db`.

🗣️ **2 minutos:** `PrismaUnitOfWork.run` abre `$transaction` y guarda el `tx` en el contexto
asíncrono; toda consulta que ocurra dentro del `await` de `work` ve `db === tx`. Fuera, `db` es el
cliente y cada consulta es autocommit. El caso de uso no distingue: llama a los mismos puertos.

🔬 **El detalle:** Si `run` se llama anidado, reutiliza la transacción existente (`if
(this.current.getStore()) return work()`): dos unidades de trabajo anidadas son una.

### 4. 🟢 ¿Por qué `Money` guarda centavos enteros en lugar de usar `decimal.js`?

⏱️ **30 segundos:** Porque sumar y multiplicar enteros es exacto en JavaScript, el contrato
serializa texto, y así no hace falta una dependencia en el dominio.

🗣️ **2 minutos:** Los importes del laboratorio caben de sobra en `Number.MAX_SAFE_INTEGER`; la
aritmética que hace el dominio es entera; y `amountAsText()` produce `"49.90"` sin pasar por un
flotante. Con divisiones o porcentajes haría falta una política de redondeo y probablemente una
biblioteca; aquí no las hay.

🔬 **El detalle:** Prisma devuelve `Decimal` (decimal.js) para `numeric(12,2)`; el adaptador lo
convierte con `toFixed(2)` a texto y el dominio lo lee con `Money.of`. El `Decimal` no cruza el
puerto.

### 5. 🟢 ¿Por qué el proyecto se arranca con `tsc` + `node` y no con `nest start` o `tsx`?

⏱️ **30 segundos:** Porque la inyección por tipo de Nest necesita `emitDecoratorMetadata`, que
`tsc` emite y los transpiladores basados en esbuild no.

🗣️ **2 minutos:** Sin esa metadata, `constructor(private readonly prisma: PrismaService)` no
tiene tipo en runtime y Nest no puede resolverlo. `tsc` compila a `dist/` y `node dist/main.js`
arranca. El coste es un paso de build; la ganancia es que el arranque no depende de un
transpilador con su propia lista de limitaciones.

🔬 **El detalle:** SWC con el plugin de decoradores también emite metadata y es lo que usa la CLI
de Nest por defecto en proyectos nuevos; se evitó para no añadir una toolchain más al taller.

### 6. 🟡 ¿Qué problema resuelve `AsyncLocalStorage` en `PrismaService` y qué problema NO debe resolver?

⏱️ **30 segundos:** Resuelve compartir una transacción entre adaptadores sin pasar `tx` por los
puertos. No debe resolver quién es el actor ni qué puede hacer: eso va por parámetro.

🗣️ **2 minutos:** Pasar `tx` a `Orders.save(order, tx)` filtra Prisma al núcleo; un contexto
asíncrono deja los puertos limpios y la transacción sigue la cadena de `await`. Pero el mismo
mecanismo, usado para el actor, esconde una entrada de la política: un job que llamara al caso de
uso sin ese contexto se saltaría la autorización sin que nadie lo viera. El capítulo 05/03 lo dice
y el archivo lo repite.

🔬 **El detalle:** El contexto se pierde si algo rompe la cadena asíncrona (un `setTimeout` sin
`AsyncResource`, una cola manual). En este proyecto no ocurre; en uno mayor es la primera
sospecha cuando "la transacción no revierte".

### 7. 🟡 ¿Cómo distingue el borde `TOKEN_REVOKED` de `UNAUTHENTICATED`, y dónde se decide cada cosa?

⏱️ **30 segundos:** `AuthGuard` verifica firma y fecha con `jose` (si falla, `UNAUTHENTICATED`)
y después consulta la revocación por `jti` (si está, `TOKEN_REVOKED`). Lanza un error propio con
el código y `ProblemFilter` lo traduce a `401`.

🗣️ **2 minutos:** A diferencia de Java, no hay un proveedor intermedio que envuelva el error: el
guard es nuestro y decide el código directamente. La revocación es un puerto
(`TokenRevocationStore`) que el guard consume: infraestructura de entrada usando un puerto de
salida, con el adaptador de Redis detrás.

🔬 **El detalle:** Un token con firma válida pero sin `jti` se rechaza como `UNAUTHENTICATED`: sin
`jti` no hay forma de revocarlo, así que no se acepta.

### 8. 🟡 ¿Por qué `ValidationPipe` lleva un `exceptionFactory` propio en vez de dejar el `400` de Nest?

⏱️ **30 segundos:** Porque el contrato exige `problem+json` con `code: VALIDATION_FAILED` y
`errors[{field, message}]`; el `BadRequestException` de Nest tiene otra forma.

🗣️ **2 minutos:** `exceptionFactory` recibe los `ValidationError` de `class-validator` y produce
un `ValidationFailed` propio con la lista aplanada de campos (incluidos los anidados, como
`lines.0.quantity`). `ProblemFilter` lo traduce una vez. Es el mismo principio del
`@ControllerAdvice`: el borde traduce, y traduce todo por el mismo camino.

🔬 **El detalle:** `whitelist: true` descarta campos que el DTO no declara; sin él, un cliente
podría colar `status: "PAID"` en el cuerpo y el DTO lo dejaría pasar hasta donde alguien lo
leyera.

### 9. 🟡 ¿Qué hace que el `OutboxDispatcher` sea "una promesa con dueño"? Nombra los tres mecanismos.

⏱️ **30 segundos:** `onModuleInit` crea el intervalo, `onModuleDestroy` lo destruye, y un flag
`running` impide que dos rondas se solapen. `enableShutdownHooks` en `main.ts` hace que el
destroy ocurra con `SIGINT`.

🗣️ **2 minutos:** Sin dueño, un `setInterval` sigue vivo tras cerrar el módulo, dos rondas pueden
entregar el mismo evento a la vez, y un rechazo no capturado mata el proceso. Aquí `void
this.poll()` es explícito ("no espero esta promesa, y lo sé"), y `poll` captura y registra para que
la siguiente ronda reintente.

🔬 **El detalle:** Con `@nestjs/schedule` se escribiría `@Interval(500)`; el resultado es el
mismo y la dependencia sobra para un solo intervalo.

### 10. 🟡 El problema de "jsonb normaliza el texto" del taller 03 no aparece aquí. ¿Por qué?

⏱️ **30 segundos:** Porque Prisma mapea `jsonb` a JSON: se escribe `{ ref }` como objeto y se
lee como objeto. Nunca hay texto que parsear por posición.

🗣️ **2 minutos:** En Java el adaptador guardaba un `String` con forma de JSON en una columna
`jsonb` y lo leía por posición; PostgreSQL lo había normalizado. Aquí `response_body: { ref: body
}` y `row.response_body as { ref: string }`: el tipo de columna se respeta desde el primer día. Es
la lección del taller 03 aplicada antes de tropezar.

🔬 **El detalle:** El `as { ref: string }` es una afirmación, no una validación; en un sistema con
varios escritores, un esquema para ese JSON sería prudente.

### 11. 🟠 `CreateProduct` con el catálogo en Mongo guarda en dos almacenes dentro de `unitOfWork.run`. ¿Qué garantiza la unidad de trabajo y qué no?

⏱️ **30 segundos:** Garantiza el `INSERT` en `inventory` (PostgreSQL). No garantiza nada sobre el
documento de Mongo: si el inventario falla, el producto se queda en el catálogo.

🗣️ **2 minutos:** La transacción de Prisma cubre PostgreSQL; `MongoProducts.save` escribe con su
propio cliente, fuera de ella. Es el límite de consistencia del capítulo 02/05: la unidad de
trabajo coordina recursos locales; entre dos almacenes hace falta orden de operaciones,
compensación o consistencia eventual. El taller lo acepta para un alta de catálogo y lo declara;
el ejercicio 6 lo resuelve.

🔬 **El detalle:** El orden "inventario primero, catálogo después" dejaría, en el fallo inverso,
un inventario sin producto (invisible para el catálogo: reparable). Es el orden más defendible
si se elige orden en vez de compensación.

### 12. 🟠 `prisma db pull` dejó el cliente generado en el sitio equivocado. ¿Qué regla del bloque se aplicó al diagnosticarlo y qué habría pasado sin `tsc --noEmit` antes de arrancar?

⏱️ **30 segundos:** La de "versiones exactas y herramientas verificadas": se miró qué escribió la
herramienta, no qué se creía haber escrito. Sin `tsc` previo, `node dist/main.js` habría fallado
con un `MODULE_NOT_FOUND` menos claro, o `build` habría compilado con `any` por todas partes.

🗣️ **2 minutos:** `db pull` reescribe el archivo entero, incluido el bloque `generator`; el
`output` a mano se perdió y el cliente fue a `prisma/generated/`. `tsc --noEmit` dio un `TS2307`
que nombraba el módulo ausente, y el resto de errores (`any` implícitos) eran consecuencia. La
corrección es fijar el generador después de cada `pull`, y el script `build` regenera siempre.

🔬 **El detalle:** Alternativa: no versionar el `schema.prisma` y regenerarlo desde la base en el
build. Se descartó porque el esquema versionado es lo que un lector lee para entender el mapeo.

### 13. 🟠 La suite pasó a la primera. Da tres razones concretas, y explica por qué ninguna es "NestJS es mejor que Spring".

⏱️ **30 segundos:** (1) El contrato y la suite ya existían y fijaban cada código y cabecera. (2)
El esquema compartido y sus restricciones ya habían enseñado el orden pedido→reserva. (3) Las
lecciones de Java (jsonb como JSON, revocación distinguida en el borde) se aplicaron desde el
diseño.

🗣️ **2 minutos:** Ninguna es del framework: son del contrato, del esquema y de haber pagado los
errores una vez. Un tercer sabor en Go debería pasar igual de rápido; si no lo hace, será por algo
específico de Go (por ejemplo, `sql.Tx` explícito), no por "madurez". Medir el coste del segundo
sabor es medir cuánto del sistema es contrato y cuánto es ecosistema.

🔬 **El detalle:** Los dos fallos que sí hubo fueron de toolchain (Prisma, driver de Mongo) y los
detectó el compilador. Eso también es un dato: TypeScript estricto adelantó a compilación lo que
en otro sabor sería un `500`.

### 14. 🟠 Un compañero propone un `@Module` por agregado (`OrdersModule`, `ProductsModule`) "para que sea más hexagonal". ¿Qué le respondes?

⏱️ **30 segundos:** Que un módulo Nest organiza providers, no dependencias de negocio: no hace
hexagonal nada por sí mismo (05/03). Y que dividirlo aquí crearía importaciones cruzadas entre
módulos para compartir `PrismaService`, `UnitOfWork` y los tokens.

🗣️ **2 minutos:** La frontera hexagonal está en `domain/` y `application/` sin importar Nest,
verificada por `depcruise`; un solo `app.module.ts` como composition root la hace visible en un
archivo. Módulos por agregado tendrían sentido si hubiera equipos distintos o despliegues
distintos; con doce casos de uso y un despliegue, son ceremonia. Si crece, se divide por
capacidad, y cada módulo sigue siendo solo composición.

🔬 **El detalle:** Un `@Module` con `exports` es también una frontera de visibilidad útil para
evitar que `inbound` importe `outbound`; aquí esa regla la pone `depcruise`, que es más barato.

### Ejercicios

### 1. 🟢 Cambia `{ provide: ORDERS, useExisting: PrismaOrders }` por inyectar `Orders` (la interfaz) en `GetOrder` con `@Inject(Orders)`. Compila y arranca. Pega el error de Nest y explica por qué `tsc` no lo detectó.

⏱️ **30 segundos:** No compila siquiera con `@Inject(Orders)` porque `Orders` es solo un tipo; si
se quita el `@Inject` y se deja `constructor(private orders: Orders)`, compila y Nest falla al
arrancar: "Nest can't resolve dependencies of GetOrder (?)".

🗣️ **2 minutos:** `tsc` ve un tipo válido; `emitDecoratorMetadata` emite `Object` para una
interfaz; Nest busca un provider para `Object` y no lo hay. El error aparece en el arranque, no
en compilación: por eso el taller tiene una prueba de arranque implícita (`lab.py nestjs` y
`/health`) además de `tsc`.

🔬 **El detalle:** Es el mismo fallo que el capítulo 05/03 pone como trampa frecuente; verlo una
vez con el mensaje real vale más que leerlo.

### 2. 🟢 Añade `@Injectable()` a `CreateOrder` y corre `lab.py nestjs --test`. Pega la violación de `depcruise` y explica qué regla la produjo.

⏱️ **30 segundos:** `application-does-not-know-infrastructure`: `src/application/usecases/create-order.ts`
→ `node_modules/@nestjs/common`.

🗣️ **2 minutos:** La regla prohíbe que `application/` dependa de `@nestjs`; el decorador obliga a
importarlo. `vitest` seguiría en verde (los decoradores no rompen la prueba); la regla de
dependencias es la única que lo ve, igual que ArchUnit en Java.

🔬 **El detalle:** `depcruise` analiza `import`, no anotaciones: si el decorador se importara desde
un archivo intermedio en `application/`, la violación la daría ese archivo.

### 3. 🟡 En `PrismaInventory.reserve`, sustituye `this.prisma.db` por `this.prisma.client` solo en el `create` de la reserva. Corre `04-orders.hurl` y explica qué queda en `inventory_reservations` tras un `409` y por qué la suite no lo detecta.

⏱️ **30 segundos:** La reserva de la primera línea (`SKU-001`) se inserta fuera de la transacción
y sobrevive al rollback: una fila `RESERVED` huérfana. La suite mira `stock`, que sí revirtió, y
no mira reservas.

🗣️ **2 minutos:** Es "usar `db` en vez de `tx`" del capítulo 05/04, en Prisma. El descuento de
inventario revierte (iba por `db` = `tx`), la fila de reserva no. Al cancelar más tarde otro
pedido no pasa nada, pero un informe de reservas vivas mentiría. Detectarlo exige una aserción
sobre `inventory_reservations` o una prueba de adaptador.

🔬 **El detalle:** Con una FK a `orders` y el pedido revertido, el `INSERT` fuera de la
transacción fallaría por FK... solo si el pedido aún no está visible: como el pedido se creó
dentro de la transacción no confirmada, la FK fuera de ella falla con `500`. El experimento real
puede dar ese `500` en vez de la fila huérfana: también vale, y enseña lo mismo.

### 4. 🟡 Escribe la prueba de `AuthorizePayment` con fakes: autorizado, rechazado y pendiente por importe, y la repetición idempotente. Explica qué doble de `PaymentGateway` usas y por qué no el `DeterministicPaymentGateway` real.

⏱️ **30 segundos:** Un fake que devuelve lo que la prueba decide por `operationId`; el real
serviría (es determinista y sin red), pero acoplaría la prueba del caso de uso a la regla de §11.

🗣️ **2 minutos:** La prueba del caso de uso verifica coordinación: dos unidades de trabajo,
estado resultante, clave guardada, repetición. Qué importe rechaza es política del adaptador, no
del caso de uso; usar el real haría que un cambio en la regla determinista rompiera pruebas de
`AuthorizePayment` que no hablan de importes.

🔬 **El detalle:** Un fake que registre el orden de llamadas permite afirmar que `authorize` se
llamó **entre** las dos unidades de trabajo y no dentro de ninguna.

### 5. 🟠 Cambia `outboxPollMs` a `5000`, corre `07-notifications.hurl` y mide. Luego mata el proceso con `SIGINT` en medio de una ronda y comprueba en el registro que `onModuleDestroy` se ejecutó y que la fila de outbox quedó pendiente, no perdida.

⏱️ **30 segundos:** El archivo pasa en ~5 s (el `retry` de `hurl` espera). Con `SIGINT`,
`enableShutdownHooks` dispara `onModuleDestroy`: el intervalo se limpia, Prisma se desconecta; la
fila de outbox sigue con `published_at IS NULL` y la siguiente ejecución la entrega.

🗣️ **2 minutos:** Lo que se comprueba es que "cerrar" no pierde trabajo: la outbox es durable, y
el dispatcher es un mecanismo sin estado propio. Si la ronda estaba a mitad, la transacción de
`DeliverPendingPublications` no confirmó y no queda ni notificación ni marca: se repite entera.

🔬 **El detalle:** Un `SIGKILL` no ejecuta hooks y el resultado es el mismo para la outbox: la
durabilidad está en la base, no en el cierre ordenado.

### 6. 🟠 Resuelve la escritura en dos almacenes de `CreateProduct` con catálogo en Mongo: ordena las operaciones para que un fallo deje el sistema recuperable, o introduce una compensación. Argumenta cuál, y qué dice el capítulo 02/05 al respecto.

⏱️ **30 segundos:** Ordenar: inventario (PostgreSQL, transaccional) primero; catálogo (Mongo)
después. Si Mongo falla, la transacción revierte el inventario; si PostgreSQL falla, nada llegó a
Mongo.

🗣️ **2 minutos:** Con el orden actual (catálogo, luego inventario) un fallo del inventario deja un
producto visible sin existencias: peor que un inventario invisible. Una compensación (borrar de
Mongo si falla PostgreSQL) es más código y sigue teniendo una ventana. El capítulo 02/05: para
efectos externos a la transacción, orden explícito, estado pendiente, outbox o compensación; aquí
el orden basta.

🔬 **El detalle:** El caso realmente robusto sería que el catálogo se alimentara desde la outbox
(`ProductCreated` → Mongo), como en el taller 09: consistencia eventual declarada.

### 7. 🔴 Sustituye `AsyncLocalStorage` por un `UnitOfWork` que devuelva un "contexto de transacción" opaco que los adaptadores acepten como parámetro opcional, sin que el núcleo importe Prisma. Compara ambos diseños: qué se hace explícito, qué se vuelve ceremonia.

⏱️ **30 segundos:** `UnitOfWork.run(work: (ctx: TxContext) => …)` con `TxContext` como tipo opaco
de aplicación; los puertos ganan un parámetro `ctx?`; el adaptador de Prisma sabe leer su `tx`
dentro. Explícito: qué llamadas participan. Ceremonia: un parámetro más en cada puerto y en cada
llamada.

🗣️ **2 minutos:** El diseño explícito no depende de la cadena asíncrona (más robusto ante colas y
timers) y se lee en la firma. El implícito deja los puertos limpios y no se olvida en ninguna
llamada. Ninguno filtra Prisma si `TxContext` es opaco. Para doce casos de uso, el implícito es
menos código con el mismo comportamiento; en un sistema con trabajo fuera de la cadena `await`,
el explícito evita un fallo silencioso.

🔬 **El detalle:** Go hace lo explícito por convención (`ctx` en todo), Java lo implícito por
proxy o `ThreadLocal`: el taller 05 y este son los dos extremos con código.

### 8. 🔥 Escribe una prueba de contrato del puerto `Orders` que corra contra `PrismaOrders` (con el entorno de `06/01` arriba) y contra `InMemoryOrders` (sin nada), con la misma batería. Decide cómo distinguir en `vitest` las pruebas que necesitan Docker de las que no.

⏱️ **30 segundos:** Una función `ordersContract(name, factory)` con `describe` parametrizado;
la variante Prisma se marca con `describe.skipIf(!process.env.HEX_INTEGRATION)`.

🗣️ **2 minutos:** El contrato afirma lo mismo para ambos (guardar, recargar, `status`,
`version`, líneas, `find` ausente → `null`). La variante de integración necesita el entorno y
`seed`; la variable de entorno la enciende en un `lab.py nestjs --test --integration`. Es el test
de contrato de puerto de 04/06, en `vitest`.

🔬 **El detalle:** Los fakes de `create-order.test.ts` deberían pasar ese mismo contrato; si no
lo pasan, mienten, y las pruebas del caso de uso que los usan valen menos de lo que parece.

---

## 05 · Go

### Preguntas

### 1. 🟢 ¿Dónde están declaradas las interfaces de los puertos y por qué ahí?

⏱️ **30 segundos:** En `application/ports.go`, junto a los casos de uso que las consumen. En Go
la interfaz pertenece a quien la necesita, no a quien la implementa.

🗣️ **2 minutos:** Como la satisfacción es implícita, el adaptador no tiene que conocer la
interfaz; por tanto puede vivir donde está el consumidor sin crear un ciclo. Un paquete
`interfaces` global sería el antipatrón de 05/04: contratos sin dueño que cualquiera amplía. Aquí
un cambio de puerto se hace en el archivo del caso de uso que lo pide.

🔬 **El detalle:** `httpin.TokenVerifier` es el mismo principio aplicado al borde: la interfaz
está en `httpin` porque es el middleware quien la consume, y `security.JWT` la satisface sin
importar `httpin`... salvo por el tipo `TokenClaims`, que sí importa. Es un acoplamiento pequeño
y declarado; el ejercicio de moverlo es útil.

### 2. 🟢 ¿Cómo comprueba el compilador que `postgres.Orders` satisface `application.Orders` si nadie lo declara?

⏱️ **30 segundos:** En `main`, al asignar `postgres.Orders{DB: db}` a un campo de tipo
`application.Orders`. Si falta un método o cambia una firma, `go build` falla ahí.

🗣️ **2 minutos:** La comprobación es estructural y ocurre en el punto de uso. Eso significa que
el adaptador puede compilar solo y no encajar; el error aparece en el composition root, que es el
sitio correcto. Un `var _ application.Orders = Orders{}` en el paquete del adaptador adelanta la
comprobación al propio paquete; se omitió para mantener el ejemplo mínimo.

🔬 **El detalle:** Un adaptador que implementa "casi" el puerto (por ejemplo, con receptor de
puntero donde se asigna un valor) da un error de compilación que conviene haber visto una vez.

### 3. 🟢 ¿Qué devuelve `DB.Q(ctx)` dentro y fuera de `DB.Run`?

⏱️ **30 segundos:** Dentro, la `pgx.Tx` que `Run` guardó en el contexto; fuera, el pool. Los
adaptadores no distinguen.

🗣️ **2 minutos:** `Querier` es la intersección de `*pgxpool.Pool` y `pgx.Tx` (`Exec`, `Query`,
`QueryRow`). Al centralizar la elección en `Q`, el error "usar `db` dentro de `tx`" solo se comete
escribiendo `Pool` a propósito. Es lo que el error provocado de §8 demuestra.

🔬 **El detalle:** El coste es que un adaptador no puede pedir una transacción propia sin pasar
por `Run`; para el dispatcher, que quiere una transacción por ronda, es exactamente lo que se
quiere.

### 4. 🟢 ¿Por qué los identificadores del dominio son `string` y no un tipo UUID?

⏱️ **30 segundos:** Porque no hay UUID en la biblioteca estándar y el dominio no necesita
interpretar el id para decidir nada: lo compara y lo transporta.

🗣️ **2 minutos:** Un `uuid.UUID` de `github.com/google/uuid` sería la única dependencia externa
del dominio, y `arch_test.go` la prohíbe. El borde valida la forma (`requireUUID`) y la base la
exige (`::uuid`); el dominio recibe un texto que ya pasó ambos controles. `main` genera v4 con
`crypto/rand` en quince líneas.

🔬 **El detalle:** Un tipo `OrderID string` del dominio daría más seguridad de tipos sin
dependencia; se dejó como `string` por brevedad, y es un buen ejercicio de refactor.

### 5. 🟢 ¿Qué hace `arch_test.go` y qué no puede detectar?

⏱️ **30 segundos:** Lee los `import` de cada archivo de `domain/`, `application/` e `inbound/`
con `go/parser` y falla si alguno empieza por un prefijo prohibido. No detecta dependencias que
no sean `import`.

🗣️ **2 minutos:** Un `import` es la única forma de depender de otro paquete en Go, así que la
regla es completa para paquetes. Lo que no ve: un tipo del dominio que copie la forma de una fila
SQL sin importar nada, o una interfaz de puerto diseñada como espejo del driver. Eso lo ve una
revisión, no un parser.

🔬 **El detalle:** La lista de prefijos prohibidos es la política; añadir `"net/http"` a
`application` es una decisión de este taller (el caso de uso no debe conocer HTTP), no una regla
de Go.

### 6. 🟡 ¿Por qué `Run` reutiliza la transacción si ya hay una en el contexto?

⏱️ **30 segundos:** Para que dos unidades de trabajo anidadas sean una: si `CreateProduct` llama
dentro de su `Run` a algo que también usa `Run`, no se abre una segunda transacción que la
primera no pueda ver.

🗣️ **2 minutos:** pgx no tiene transacciones anidadas reales (hay `SAVEPOINT`, pero es otra
semántica). Reutilizar es la propagación `REQUIRED` de Spring: participar en la existente. La
alternativa —abrir siempre— haría que la interna confirmara antes que la externa y rompería la
atomicidad.

🔬 **El detalle:** Si algún día hace falta `REQUIRES_NEW` (por ejemplo, registrar un intento de
pago aunque el resto revierta), sería un método distinto (`RunNew`) con un contexto limpio, no un
parámetro de `Run`.

### 7. 🟡 ¿Por qué el `defer tx.Rollback(ctx)` de `Run` no oculta un error de `Commit`?

⏱️ **30 segundos:** Porque `Commit` es la última sentencia y su error se devuelve; el `Rollback`
diferido corre después y su resultado se descarta.

🗣️ **2 minutos:** Tras un `Commit` exitoso, `Rollback` devuelve `pgx.ErrTxClosed`, que es
inofensivo y se ignora. Tras un `Commit` fallido, `Rollback` intenta revertir lo que quede y
también se ignora, pero el error de `Commit` ya está en el `return`. La trampa que 05/04 nombra
es hacer `defer func() { err = tx.Rollback() }()` con una variable con nombre: entonces el
`Rollback` pisa el error de `Commit`.

🔬 **El detalle:** El patrón alternativo "rollback solo si hubo error" con una variable `done`
es más explícito y más largo; `Run` prefiere el `defer` incondicional con el comentario que
explica por qué es seguro.

### 8. 🟡 ¿Qué gana y qué pierde la validación a mano de `dto.go` frente a `class-validator` o Bean Validation?

⏱️ **30 segundos:** Gana que se lee entera y no hay reflexión ni anotaciones; pierde
concisión y la lista de reglas la mantiene el equipo.

🗣️ **2 minutos:** `createOrderRequest.validate()` acumula errores por línea y los devuelve con
el `field` del contrato (`lines[1].quantity`); el mismo resultado que Bean Validation con menos
magia y más líneas. Los `*int` distinguen "falta" de "cero", algo que las anotaciones resuelven
con `@NotNull` y que aquí es un puntero. Para veinte DTO empieza a compensar una librería; para
cuatro, no.

🔬 **El detalle:** `http.MaxBytesReader` de 1 MiB en `decode` es la validación de tamaño que el
capítulo 03/01 pide al borde y que los frameworks suelen traer configurada.

### 9. 🟡 ¿Por qué `security.JWT` implementa dos interfaces de dos paquetes distintos sin declararlo, y qué dice eso del diseño?

⏱️ **30 segundos:** `Issue` satisface `application.TokenIssuer` y `Verify` satisface
`httpin.TokenVerifier`. Un tipo, dos contratos, definidos por dos consumidores distintos.

🗣️ **2 minutos:** Emitir es una necesidad del caso de uso `Login`; verificar es una necesidad
del middleware HTTP. Que ambas las cumpla el mismo secreto y el mismo tipo es un detalle del
adaptador. En Java eran dos beans (`JwtTokenIssuer` y el `JwtDecoder` de Spring); aquí es un
struct porque el lenguaje no obliga a separar lo que comparte estado.

🔬 **El detalle:** `security` importa `httpin` por el tipo `TokenClaims`: un adaptador de salida
que conoce al de entrada. Es una dependencia lateral pequeña que `arch_test.go` permite (solo
prohíbe `inbound` → `outbound`); moverla a `application` sería tratar el token como algo del
núcleo, que no lo es.

### 10. 🟡 ¿Cómo evita el `Dispatcher` "lanzar una goroutine y perder el error"?

⏱️ **30 segundos:** Con un `context` que `main` cancela, un `select` que lo escucha y un registro
por ronda: el error no se pierde, se anota, y la siguiente ronda reintenta.

🗣️ **2 minutos:** `go dispatcher.Run(ctx)` es la única goroutine que arranca `main` y tiene tres
propiedades: sabe cuándo parar (`ctx.Done()`), no se solapa (el `select` es secuencial) y no se
traga errores (`slog.Warn`). Con `Ctrl+C`, `signal.NotifyContext` cancela, el `select` sale y
`server.Shutdown` espera lo demás.

🔬 **El detalle:** Lo que no hace: esperar a que la ronda en curso termine antes de que `main`
retorne. Un `sync.WaitGroup` lo cerraría; para un laboratorio, la transacción de la ronda a
medias simplemente revierte.

### 11. 🟠 El error provocado dio `500` y no una fila huérfana. ¿Qué lo impidió, y qué habría pasado sin la FK?

⏱️ **30 segundos:** La FK `inventory_reservations.order_id → orders.id`: el pedido solo existía
en la transacción no confirmada, y el `INSERT` por el pool no lo vio. Sin FK, la reserva se habría
guardado fuera de la transacción y habría sobrevivido al rollback.

🗣️ **2 minutos:** La conexión del pool es otra sesión: no ve filas no confirmadas de otra. Por
eso la FK falló y el caso de uso revirtió todo: el sistema quedó limpio pero con un `500` en vez
del `409`. Sin la FK, el resultado sería peor y silencioso: `409` correcto para el cliente y una
fila `RESERVED` sin pedido. Las dos capas —`Q(ctx)` para que no ocurra, la FK para atraparlo si
ocurre— son complementarias.

🔬 **El detalle:** Con el `UPDATE` de inventario por el pool (ejercicio 2) el efecto es distinto:
no hay FK que lo atrape, el descuento se confirma solo y la suite lo ve porque el stock no vuelve
a 20.

### 12. 🟠 ¿Por qué el `ctx` de la petición y el `ctx` de la transacción son el mismo objeto en la mayoría de las llamadas, y cuándo no lo son?

⏱️ **30 segundos:** No son el mismo: el de la transacción es un hijo del de la petición
(`context.WithValue`). Comparten cancelación y deadline; el hijo añade la transacción.

🗣️ **2 minutos:** Dentro de `Run`, `fn` recibe el hijo, y todo lo que se llame con él —adaptadores
incluidos— ve la transacción. Fuera de `Run` (la llamada al proveedor en `AuthorizePayment`) se
usa el padre: sin transacción, con la misma cancelación. Si el cliente cierra la conexión, ambos
se cancelan y `pgx` aborta la transacción en curso.

🔬 **El detalle:** El dispatcher recibe el contexto de `main`, no el de una petición; su
transacción es hija de ese. Es la razón por la que `Ctrl+C` corta también una ronda de entrega
a medias, y por la que la outbox es durable.

### 13. 🟠 En modo `postgres` el binario no abre Mongo; en NestJS y Java sí se conectaba siempre. ¿Cuál es mejor y por qué?

⏱️ **30 segundos:** El de Go: un recurso que no se usa no se abre, no falla al arrancar si no
está y no consume conexiones. Es consecuencia de que la composición sea código imperativo.

🗣️ **2 minutos:** En Java y Nest el contenedor instancia todos los providers registrados;
condicionar la creación exige `@ConditionalOnProperty` o un `useFactory` que devuelva `null`, y
lo segundo rompe la inyección. En `main` es un `if`. Es un argumento honesto a favor de la
composición explícita: lo condicional se escribe como condicional.

🔬 **El detalle:** El precio es que la parte 3 tocó `main` (siete líneas) además del paquete
nuevo, mientras que en Nest tocó cero líneas fuera de `outbound/mongo`... porque la `useFactory`
ya instanciaba ambos. Dos formas de la misma decisión.

### 14. 🟠 Un compañero quiere un paquete `internal/interfaces` "para no duplicar". ¿Qué le respondes con este código delante?

⏱️ **30 segundos:** Que no hay nada duplicado: cada interfaz tiene un consumidor y vive con él.
Un paquete `interfaces` juntaría contratos de dueños distintos y crearía dependencia de todos
hacia todos.

🗣️ **2 minutos:** `application/ports.go` tiene las interfaces que consumen los casos de uso;
`httpin.TokenVerifier` la que consume el middleware. Si mañana un consumidor nuevo necesita otra
forma de `Orders` (solo lectura, por ejemplo), declara la suya con los métodos que necesita y el
mismo `postgres.Orders` la satisface. Con un paquete central, esa interfaz nueva se añadiría al
catálogo y todos la importarían. Es la trampa "paquete `interfaces` global" de 05/04.

🔬 **El detalle:** Lo que sí puede centralizarse sin daño son *tipos de datos* compartidos
(`Money`, `Page`); ya lo están, en `domain` y `application`, que es donde tienen dueño.

### Ejercicios

### 1. 🟢 Haz que `domain/order.go` importe `github.com/google/uuid` (solo el import) y corre `lab.py go --test`. Pega el fallo de `TestDependencyRule`.

⏱️ **30 segundos:** Antes del test, `go mod tidy` añade el módulo; después,
`arch_test.go` falla: `../domain/order.go imports github.com/google/uuid (forbidden in ../domain)`.

🗣️ **2 minutos:** Go además exige usar lo importado (`_ = uuid.New` o un blank import); con el
blank import la regla sigue fallando porque mira el `import`, no el uso. Es la prueba más barata
del bloque y la única que distingue "compila" de "respeta la frontera".

🔬 **El detalle:** `go vet` no tiene opinión sobre esto; la regla es del proyecto, no del
lenguaje.

### 2. 🟢 Cambia `Q(ctx)` por `i.DB.Pool` en el `UPDATE` de `Reserve` (no en el `INSERT`) y corre `04-orders.hurl`. Explica por qué esta vez **sí** queda un descuento huérfano y la suite lo detecta por el stock.

⏱️ **30 segundos:** El `UPDATE` de inventario no depende de ninguna fila de la transacción, así
que el pool lo confirma solo; el `409` de `SKU-004` revierte pedido e `INSERT` de reserva, pero
`SKU-001` queda en 19. La aserción `stock == 20` tras el `409` falla.

🗣️ **2 minutos:** Es el caso peligroso: ningún error, ninguna FK, un dato mal. La suite lo ve
porque comprueba el stock después de un fallo, que es una aserción de "no dejó nada atrás" y no
de camino feliz. Escribir esa aserción en `06/01` fue lo que hizo detectable este error.

🔬 **El detalle:** El efecto se acumula: cada `409` de la suite deja una unidad menos; tras varias
corridas sin `seed`, `SKU-001` habría "desaparecido" sin que nadie lo comprara.

### 3. 🟡 Escribe una prueba con `httptest` para `POST /api/v1/orders` usando un `Deps` con dobles del caso de uso: sin cabecera → `400 IDEMPOTENCY_KEY_REQUIRED`; con cuerpo `{ "lines": [] }` → `400 VALIDATION_FAILED`. Explica qué anillo cubre y qué no.

⏱️ **30 segundos:** `httptest.NewRecorder` + `NewHandler(Deps{...})` con un `Verifier` fake que
acepte cualquier token y un `CreateOrder` con puertos en memoria. Cubre el adaptador HTTP
(validación, cabeceras, códigos); no cubre SQL ni la transacción.

🗣️ **2 minutos:** `CreateOrder` es un struct, no una interfaz, así que no se sustituye: se
construye con fakes de sus puertos (los de `create_order_test.go`). El test verifica que el borde
no llegó a llamar al caso de uso en los dos casos (`400` antes de ejecutar): el fake de `Orders`
queda vacío.

🔬 **El detalle:** Para el `Verifier`, una interfaz de un método se dobla con un tipo de una
línea; es una de las razones para que `TokenVerifier` sea interfaz y no el struct `security.JWT`.

### 4. 🟡 Quita `jwt.WithValidMethods([]string{"HS256"})` del verificador y explica qué ataque permite un token firmado con `alg: none` o con otro algoritmo. Vuelve a ponerlo.

⏱️ **30 segundos:** Sin la lista, el parser acepta el algoritmo que declara el token. `none`
está bloqueado por defecto en golang-jwt, pero un algoritmo asimétrico con la clave pública
conocida, o la confusión HS/RS, quedan abiertos si la `keyFunc` no comprueba el método.

🗣️ **2 minutos:** La `keyFunc` devuelve el secreto HMAC para cualquier token; si el token dice
`RS256`, la librería intentaría verificar una firma RSA con bytes de HMAC y fallaría, pero la
regla general es no dejar que el atacante elija el algoritmo. `WithValidMethods` lo fija en el
verificador, que es donde debe estar.

🔬 **El detalle:** `WithExpirationRequired` es la otra opción que vale la pena: un token sin
`exp` no debería aceptarse aunque la firma sea válida.

### 5. 🟠 Escribe una prueba de contrato del puerto `Orders` con `testing` y una etiqueta de build (`//go:build integration`) que corra contra `postgres.Orders` con el entorno arriba y contra el fake sin nada. Decide cómo `lab.py go --test` la activa.

⏱️ **30 segundos:** Una función `testOrdersContract(t, orders application.Orders)` en un archivo
sin etiqueta, llamada desde `orders_fake_test.go` (siempre) y desde `orders_postgres_test.go`
con `//go:build integration`. `lab.py go --test --integration` añade `-tags integration`.

🗣️ **2 minutos:** El contrato afirma lo mismo para ambos: guardar, recargar, `Status`, `Version`,
líneas, `Find` de un id ausente → `nil, nil`. La variante de integración usa
`postgres.Open` con la URL de §11 y `seed` antes. Es el test de contrato de puerto de 04/06 con
las herramientas del lenguaje: etiquetas de build, no un framework.

🔬 **El detalle:** El fake de `create_order_test.go` está en el paquete `application` y no se
exporta; el contrato obligaría a moverlo a un paquete `applicationtest` exportado. Es un cambio
sano: los fakes que valen para un contrato valen para todos.

### 6. 🟠 Sustituye el `select` del `Dispatcher` por un `time.AfterFunc` recursivo. Compara el manejo de cancelación y de solapamiento de rondas, y argumenta cuál es más fácil de razonar.

⏱️ **30 segundos:** `AfterFunc` programa la siguiente ronda al terminar la actual, así nunca se
solapan por construcción; pero la cancelación exige `timer.Stop()` y una comprobación de
`ctx.Err()` dentro del callback. El `select` con ticker se lee de arriba abajo y se para solo.

🗣️ **2 minutos:** Con ticker, una ronda lenta hace que se acumulen ticks (el canal tiene tamaño
1, así que a lo sumo uno) y la siguiente arranca inmediatamente después; con `AfterFunc`, la
espera es siempre entre rondas. Ambas son correctas; el `select` deja la cancelación en un solo
sitio y por eso el taller lo prefiere.

🔬 **El detalle:** La versión de NestJS tenía el flag `running` por lo mismo: `setInterval` no
espera a la ronda. En Go el `select` secuencial lo hace innecesario.

### 7. 🔴 Implementa un `middleware` de deadline (`context.WithTimeout` de 2 s por petición) y comprueba con el proveedor determinista modificado (un `time.Sleep` de 3 s en `Authorize`) qué error ve el cliente, qué queda en la base y por qué `AuthorizePayment` con dos transacciones deja el sistema consistente aunque la petición se cancele entre ambas.

⏱️ **30 segundos:** El cliente ve `500 INTERNAL_ERROR` (el `ctx` cancelado llega a pgx como
error); la primera transacción ya confirmó (sin cambios: solo leyó); la segunda nunca abrió; el
pedido sigue `CONFIRMED` y pagable; la clave no se guardó.

🗣️ **2 minutos:** Es el estado incierto del capítulo 04/02 desde el lado del servidor: el
proveedor pudo haber cobrado y nosotros no lo aplicamos. Con la clave de idempotencia estable, el
reintento del cliente con la **misma** clave vuelve a llamar al proveedor con la misma
`operationId`, que en un proveedor real es idempotente; con el determinista, simplemente devuelve
lo mismo. Sin las dos transacciones, un `@Transactional` alrededor de todo habría mantenido filas
bloqueadas 2 s y revertido igual.

🔬 **El detalle:** El `500` debería ser un `504` o un `503` con `code` propio; traducir
`context.DeadlineExceeded` en `problem.go` es la parte del ejercicio que toca el borde.

### 8. 🔥 Elimina `internal/` (mueve los paquetes un nivel arriba) y comprueba que todo compila igual. Explica qué protegía `internal/` y qué no, y por qué `arch_test.go` sigue siendo necesario.

⏱️ **30 segundos:** Compila igual: `internal/` solo impide que **otro módulo** importe esos
paquetes. Dentro del módulo, `domain` podría importar `pgx` con o sin `internal/`; eso lo impide
`arch_test.go`.

🗣️ **2 minutos:** Son dos fronteras distintas: `internal/` es visibilidad hacia fuera (útil si el
módulo se publica como librería); la regla de dependencias es dirección hacia dentro. La trampa de
05/04 —"un paquete `internal` garantiza hexagonal"— es confundirlas. El taller conserva `internal/`
porque cuesta nada y documenta que `cmd/server` es la única entrada.

🔬 **El detalle:** Tras mover los paquetes, `arch_test.go` necesita ajustar sus rutas relativas;
que la prueba se rompa por rutas y no por reglas es un recordatorio de que es un test casero, no
una herramienta.

---

## 06 · Python y FastAPI

### Preguntas

### 1. 🟢 ¿Qué comprueba un `Protocol` y cuándo?

⏱️ **30 segundos:** Que una clase tiene los métodos con las firmas declaradas. Lo comprueba un
type checker (mypy, pyright) antes de ejecutar; el intérprete no comprueba nada.

🗣️ **2 minutos:** Es un contrato estructural: `PgOrders` satisface `Orders` sin heredar. Eso
permite que los fakes de las pruebas sean clases cualesquiera con los mismos métodos. El coste es
que sin type checker un método que falta se descubre en la primera llamada; el taller lo
declara y el ejercicio 1 lo cierra.

🔬 **El detalle:** `runtime_checkable` permite `isinstance(x, Orders)`, pero solo mira nombres de
métodos, no firmas; no sustituye al type checker.

### 2. 🟢 ¿Por qué los casos de uso son `dataclass(frozen=True)` y no clases con `Depends`?

⏱️ **30 segundos:** Porque `Depends` es de FastAPI y el caso de uso no debe importar FastAPI. La
`dataclass` recibe los puertos por constructor; `main.py` la construye.

🗣️ **2 minutos:** `frozen=True` deja claro que el caso de uso no tiene estado propio: sus campos
son colaboradores. `import-linter` prohíbe `fastapi` en `application`, así que `Depends` allí ni
compila en el sentido del linter. Y `pytest` los instancia con fakes sin levantar nada.

🔬 **El detalle:** `slots=True` reduce memoria y evita atributos accidentales; es cosmético para
el taller, pero coherente con "sin estado".

### 3. 🟢 ¿Por qué los endpoints son `def` y no `async def`?

⏱️ **30 segundos:** Porque el driver de PostgreSQL es síncrono: una consulta dentro de un
`async def` bloquearía el bucle de eventos. FastAPI ejecuta los `def` en un threadpool.

🗣️ **2 minutos:** El capítulo 05/05: `async def` no vuelve async a una llamada bloqueante. Con
`def`, cada petición ocupa un hilo del pool mientras espera a la base, y el bucle sigue libre para
otras. Es el diseño honesto para una cadena síncrona; la alternativa coherente es driver async +
`AsyncSession` en todo el camino.

🔬 **El detalle:** El pool de hilos por defecto de Starlette es de 40; bajo carga real sería un
parámetro a medir, no a suponer.

### 4. 🟢 ¿Qué hace `ConfigDict(strict=True, extra="ignore")` y por qué solo en el borde?

⏱️ **30 segundos:** `strict` impide coerciones (`"10"` no es `10`); `extra="ignore"` descarta
campos que el DTO no declara. Solo en el borde porque ahí entran datos de fuera; el dominio ya
recibe tipos propios.

🗣️ **2 minutos:** Sin `strict`, Pydantic convierte `"35"` en `35` y `1` en `True`; el contrato
dice que `stock` es entero y `amount` es texto con dos decimales, y quiere rechazar lo demás. Sin
`extra="ignore"`, un `status` colado en el cuerpo llegaría al modelo.

🔬 **El detalle:** `extra="forbid"` sería más estricto (400 ante campos desconocidos); se eligió
`ignore` porque el contrato no promete rechazar campos extra y Prism los tolera.

### 5. 🟢 ¿Dónde vive `Depends` en este proyecto y dónde está prohibido?

⏱️ **30 segundos:** Solo en `infrastructure/inbound/http/app.py` (y el `Authenticator` que se
inyecta). Prohibido en `domain` y `application` por `import-linter`.

🗣️ **2 minutos:** `Depends` resuelve composición por petición (actor, clave de idempotencia); la
composición del sistema la hace `main.py` sin FastAPI. Es la frontera de 05/05: `Depends`
pertenece a la composición FastAPI, no al caso de uso.

🔬 **El detalle:** `create_app(deps)` es la función de arranque que recibe los casos de uso ya
hechos; se puede probar con `TestClient` y dobles sin tocar `main.py`.

### 6. 🟡 ¿Cómo comparte `Db.run` la transacción con los adaptadores sin pasar una sesión?

⏱️ **30 segundos:** Con un `ContextVar`: `run` abre `engine.begin()`, guarda la conexión, llama a
`work()` y la quita; `rows`/`exec` la usan si está.

🗣️ **2 minutos:** El caso de uso no ve conexiones; los adaptadores no reciben parámetros extra.
Si `run` se anida, reutiliza la existente. Es el `AsyncLocalStorage` de NestJS y el `ctx` de Go,
en Python. Y se usa solo para la transacción: el actor va por parámetro.

🔬 **El detalle:** `_current.reset(token)` en el `finally` restaura el valor anterior aunque
`work` lance; sin eso, una excepción dejaría el `ContextVar` apuntando a una conexión cerrada.

### 7. 🟡 ¿Por qué el `ContextVar` funciona aunque FastAPI ejecute los `def` en un threadpool?

⏱️ **30 segundos:** Porque el caso de uso entero corre en el mismo hilo: `run`, `work` y los
adaptadores. El `ContextVar` es por contexto de ejecución, y ese hilo es uno.

🗣️ **2 minutos:** Starlette copia el contexto al hilo del pool al despachar el `def`; dentro,
`run` establece la conexión y todo lo que llama la ve. Si el caso de uso lanzara otro hilo
(`ThreadPoolExecutor`) para una consulta, ese hilo no la vería: es la trampa del ejercicio 8.

🔬 **El detalle:** El dispatcher corre en su propio hilo y llama a `deliver.execute`, que hace su
propio `run`: contexto independiente, transacción independiente.

### 8. 🟡 ¿Por qué `problems.py` convierte `RequestValidationError` en `400` y no deja el `422` de FastAPI?

⏱️ **30 segundos:** Porque el contrato dice `400 VALIDATION_FAILED` con `errors[{field,message}]`
para la forma, y reserva `422` para la clave de idempotencia reutilizada.

🗣️ **2 minutos:** El `422` por defecto de FastAPI tiene otra forma (`detail: [{loc, msg, type}]`)
y otro código. El handler aplana `loc` a `lines[0].quantity` y produce `problem+json`. Es el
traductor central del borde, como el `@RestControllerAdvice` de Java.

🔬 **El detalle:** Un `order_id: UUID` inválido en la ruta también es `RequestValidationError`;
por eso el mismo handler devuelve `400` con `field: order_id` sin código extra.

### 9. 🟡 ¿Qué hace `Event.wait(interval)` en el dispatcher que un `sleep` en bucle no hace?

⏱️ **30 segundos:** Espera el intervalo **o** la señal de parada, lo que llegue antes. `stop()`
hace `set()` y el hilo sale en el acto; con `sleep`, tardaría hasta un intervalo entero.

🗣️ **2 minutos:** `while not self._stop.wait(self._interval)` es a la vez el temporizador y la
condición de salida: no hay flag que comprobar ni `sleep` que interrumpir. `join(timeout=5)` en
`stop()` espera a que la ronda en curso termine. Es "un hilo con dueño".

🔬 **El detalle:** `daemon=True` es la red de seguridad: si algo impide el `join`, el proceso no
se queda colgado al salir.

### 10. 🟡 ¿Por qué no hay `Session` ni modelos declarativos de SQLAlchemy en este sabor?

⏱️ **30 segundos:** Porque no hay un modelo de persistencia con vida propia: cada adaptador
escribe y lee filas con SQL, y `Order` se reconstruye a mano. Un ORM añadiría una clase por tabla
para traducirla después a otra.

🗣️ **2 minutos:** El capítulo 05/05 pone SQLAlchemy ORM en el adaptador cuando compensa; aquí
`Core` con `text()` basta y hace visible qué SQL corre. El ejercicio 7 pide el ORM para medir la
diferencia: más archivos, mapeo automático, y la tentación de devolver el modelo.

🔬 **El detalle:** `Decimal(...).quantize(Decimal("0.01"))` y `json` son las dos únicas
conversiones; con ORM las haría un `TypeDecorator`, otra pieza más.

### 11. 🟠 El error de §8: ¿por qué `from __future__ import annotations` rompió las dependencias y no las rutas sin dependencias?

⏱️ **30 segundos:** Porque FastAPI evalúa las anotaciones como strings con los `globals` del
módulo; `Who` y `Key` eran locales de `create_app` y no se resolvieron. `/health` no tiene
parámetros: nada que resolver.

🗣️ **2 minutos:** PEP 563 hace que `def f(_: Who)` guarde `"Who"` como texto. FastAPI hace
`get_type_hints` con el espacio de nombres del módulo, donde `Who` no existe, y cae a tratar `_`
como parámetro de query obligatorio: `400` "Field required" en cada ruta autenticada. `login`
también falló porque `body: schemas.LoginRequest`... no, ese se resolvió: `schemas` es global. Las
que fallaron eran exactamente las que usaban un alias local.

🔬 **El detalle:** Definir los alias a nivel de módulo evitaría el problema con el import
diferido, pero exigiría que `authenticate` fuera global; quitar el import es la corrección menor.

### 12. 🟠 Sin type checker, ¿cómo se descubriría un `PgOrders` al que le falta `list`? Propón dónde poner el type checker y por qué ahí.

⏱️ **30 segundos:** En la primera petición a `GET /orders`: `AttributeError` → `500`. El type
checker va en `lab.py python --test`, junto a `pytest` y `lint-imports`, para que "pruebas en
verde" incluya el contrato de los `Protocol`.

🗣️ **2 minutos:** Un `Protocol` es una promesa que solo mypy/pyright cobra. Ponerlo en el mismo
comando que las pruebas evita que alguien lo corra "a veces". `main.py` también lo verifica
implícitamente al anotar `products: Products = PgProducts(db)`: el checker exige que encaje.

🔬 **El detalle:** Para los fakes de `tests/`, el checker con `--strict` también los comprobaría
contra los `Protocol`: los fakes que mienten se detectarían antes de mentir.

### 13. 🟠 Compara `ContextVar` (Python), `AsyncLocalStorage` (Node) y `ctx` explícito (Go) para la transacción: qué hace visible cada uno y qué esconde.

⏱️ **30 segundos:** Go la hace visible en cada firma (`ctx`), a cambio de un parámetro en todo;
Python y Node la esconden en el contexto de ejecución, con firmas limpias y un fallo silencioso
si la cadena se rompe.

🗣️ **2 minutos:** Los tres resuelven lo mismo: que dos adaptadores compartan la transacción sin
que el caso de uso conozca la base. Go paga en ruido y gana en trazabilidad; Python y Node pagan
en un mecanismo que hay que conocer (hilos, `await`) y ganan en puertos limpios. Ninguno filtra la
base al núcleo si el contexto no lleva tipos de la base... y en Go sí los lleva (`pgx.Tx` en
`ctx`), pero el núcleo no lo lee.

🔬 **El detalle:** El caso donde el implícito falla es trabajo fuera de la cadena (otro hilo,
otra tarea): el ejercicio 8 lo provoca en Python y el 7 del taller 04 lo hace explícito en Node.

### 14. 🟠 Un compañero quiere `async def` en todas las rutas "porque FastAPI es async". Con `psycopg` síncrono, ¿qué pasaría bajo carga, y qué dos caminos correctos hay?

⏱️ **30 segundos:** Cada consulta bloquearía el bucle de eventos: una petición lenta en la base
congela a todas las demás, incluso `/health`. Caminos: `def` en threadpool (el actual) o driver
async (`psycopg` en modo async / `asyncpg`) con `AsyncSession` en toda la cadena.

🗣️ **2 minutos:** El bucle de eventos es un solo hilo; un `await` que no cede (porque la llamada
es síncrona) lo detiene. Con `def`, FastAPI cede al pool. Mezclar `async def` con
`asyncio.to_thread` por consulta funciona pero convierte cada adaptador en un híbrido difícil de
razonar. Elegir una cadena y ser coherente es la regla de 05/05.

🔬 **El detalle:** Con driver async el `ContextVar` sigue funcionando (asyncio copia el contexto a
cada tarea), pero la unidad de trabajo pasa a `async with engine.begin()` y todos los puertos a
`async def`: es otro taller.

### Ejercicios

### 1. 🟢 Añade `mypy` (o `pyright`) al grupo `dev`, corre `uv run mypy src` y arregla lo que encuentre. Después borra el método `list` de `PgOrders` y comprueba que el type checker lo ve y `pytest` no.

⏱️ **30 segundos:** mypy señala `main.py`: `PgOrders` no es compatible con `Orders` (falta
`list`). `pytest` sigue en verde porque las pruebas del caso de uso usan fakes.

🗣️ **2 minutos:** Es la demostración de que `Protocol` sin type checker es documentación. Lo que
mypy encuentre antes (probablemente `# type: ignore` en `Authenticator` por el `Role` como
`str`) es deuda real del taller que conviene pagar.

🔬 **El detalle:** `uv run mypy src --strict` en `lab.py python --test` es el cambio de una
línea; lo que cueste arreglar es la medida de cuánto se confiaba en el checker sin tenerlo.

### 2. 🟢 Vuelve a poner `from __future__ import annotations` en `app.py`, arranca y corre `02-auth.hurl`. Pega el `400` con `"field": "_"` y quítalo otra vez.

⏱️ **30 segundos:** `{"code":"VALIDATION_FAILED","errors":[{"field":"_","message":"Field required"}]}`
en cada ruta con `_: Who`.

🗣️ **2 minutos:** Reproducir el error de §8 a propósito es la forma de que se recuerde: el
síntoma (un campo `_` obligatorio) no apunta a la causa (anotaciones diferidas). Anotar el
diagnóstico en el archivo es lo que hace el docstring de `app.py`.

🔬 **El detalle:** Con Python 3.14 y PEP 649 (anotaciones perezosas nativas) el comportamiento
cambia: las anotaciones se evalúan bajo demanda con su ámbito real. Comprobar si el import
diferido sigue rompiendo en 3.14 es una buena extensión del ejercicio.

### 3. 🟡 Escribe una prueba con `TestClient` sobre `create_app(deps)` con dobles: sin cabecera → `400 IDEMPOTENCY_KEY_REQUIRED`; `{ "lines": [] }` → `400 VALIDATION_FAILED` con `field` `lines`. Explica qué anillo cubre.

⏱️ **30 segundos:** `Deps` con fakes de los puertos y un `verifier` que acepte cualquier token;
`TestClient(app).post("/api/v1/orders", ...)`. Cubre el adaptador HTTP: dependencias, Pydantic,
handlers de error. No cubre SQL ni la transacción.

🗣️ **2 minutos:** `create_app` recibe los casos de uso; los casos de uso son `dataclass` con
fakes: la prueba no toca `main.py` ni Docker. Es el anillo "adaptador HTTP integrado" de 04/06,
sin servidor real.

🔬 **El detalle:** `httpx` está en el grupo `dev` precisamente para `TestClient`.

### 4. 🟡 Cambia `stock: int` por `stock: int = Field(ge=0)` sin `strict` (quita `strict=True` de `Strict`) y envía `"stock": "10"`. Explica qué pasó y por qué el contrato prefiere rechazarlo.

⏱️ **30 segundos:** Pydantic coerciona `"10"` → `10` y el producto se crea. El contrato declara
`stock` como entero: aceptar texto es aceptar un cliente que no cumple el contrato, y `"10 "` o
`"1e1"` empezarían a ser cuestión de suerte.

🗣️ **2 minutos:** La coerción silenciosa es cómoda y peligrosa: el capítulo 05/05 dice "configura
modo estricto cuando aceptar conversiones silenciosas rompería el contrato". Un `amount` en
número que se convirtiera a texto es el ejemplo de dinero: `49.9` → `"49.9"` no cumple el patrón,
pero `49.90` como float ya perdió información antes de llegar.

🔬 **El detalle:** `strict` por modelo (en `Strict`) es más fácil de auditar que por campo.

### 5. 🟠 En `PgInventory.reserve`, sustituye `self.db.exec` del `INSERT` de la reserva por un `with self.db.engine.begin() as c: c.execute(...)` (una conexión propia). Corre `04-orders.hurl`. Compara con el error provocado del taller 05 (Go).

⏱️ **30 segundos:** Igual que en Go: la conexión propia no ve el pedido no confirmado, la FK
rechaza el `INSERT`, `500` en vez de `409`, y nada huérfano gracias a la FK.

🗣️ **2 minutos:** `Db.exec` existe para que este error exija escribir el `engine` a mano; es el
`Q(ctx)` de Go. La diferencia con Go es la forma del error: aquí una `IntegrityError` de SQLAlchemy
que el handler genérico convierte en `500` con la traza en el registro.

🔬 **El detalle:** Con el `UPDATE` de inventario en conexión propia (no el `INSERT`), el
descuento sobrevive al rollback y la suite lo ve por el stock: mismo análisis que el ejercicio 2
del taller 05.

### 6. 🟠 Convierte el dispatcher en una tarea `asyncio` dentro del `lifespan` (`asyncio.create_task`) que llame al caso de uso con `asyncio.to_thread`. Explica qué gana, qué pierde y por qué `to_thread` es obligatorio con este driver.

⏱️ **30 segundos:** Gana vivir en el mismo bucle que la app (cancelación con `task.cancel()`,
sin hilo propio). Pierde simplicidad: cada ronda es `await asyncio.to_thread(deliver.execute, 50)`,
porque el caso de uso es síncrono y bloquearía el bucle.

🗣️ **2 minutos:** `to_thread` manda la ronda al threadpool y copia el contexto, así que el
`ContextVar` de la transacción funciona. Sin `to_thread`, `deliver.execute` bloquearía el bucle
medio segundo por ronda: la app se congelaría periódicamente. Es la misma regla de las rutas
(`def` vs `async def`) aplicada al trabajo en segundo plano.

🔬 **El detalle:** `asyncio.CancelledError` hay que dejarlo propagar en el bucle de la tarea; un
`except Exception` no lo captura (hereda de `BaseException`), y eso es correcto.

### 7. 🔴 Sustituye `Db.rows`/`Db.exec` por una `Session` de SQLAlchemy ORM con un modelo declarativo `OrderRow` distinto de `Order`, manteniendo `Db.run` como unidad de trabajo. Mide cuántos archivos cambian y argumenta si el ORM compensa en este sistema.

⏱️ **30 segundos:** Cambian `db.py` (la `Session` en el `ContextVar`), `adapters.py` (modelos +
mapeo) y nada más: el núcleo y el borde no se enteran. Unas 150 líneas de modelos y mapeos a
cambio de eliminar el SQL a mano.

🗣️ **2 minutos:** Compensa si el esquema evoluciona a menudo o hay muchas relaciones; aquí hay
diez tablas fijas y consultas cortas, y `text()` es más legible que el mapeo. La lección es que la
decisión cabe en dos archivos porque los puertos están bien colocados: el ORM es un detalle que se
puede probar y descartar.

🔬 **El detalle:** El mayor riesgo del ORM aquí es `OrderRow` con `lazy="select"` en las líneas y
alguien devolviéndolo desde el adaptador: exactamente el lazy loading fuera de sesión de 05/05.

### 8. 🔥 Implementa el catálogo con `motor`/`pymongo` async y una ruta `async def` para `GET /products`, dejando el resto síncrono. Explica qué problema de consistencia de hilos aparece con el `ContextVar` de la transacción y cómo lo resolverías.

⏱️ **30 segundos:** `ListProducts` mezclaría un puerto async (catálogo) y uno síncrono
(inventario, en `to_thread`): el `ContextVar` de la transacción se copia al hilo, pero una
transacción abierta en el bucle y usada desde un hilo es una conexión compartida entre hilos,
que SQLAlchemy prohíbe.

🗣️ **2 minutos:** La solución honesta es no mezclar: o toda la cadena async (driver async,
`AsyncSession`, puertos `async def`) o toda síncrona. Una ruta async aislada que no toque
PostgreSQL (solo Mongo) funciona, pero `ListProducts` toca ambos. El ejercicio enseña que "async
parcial" no es un punto intermedio: es dos sistemas.

🔬 **El detalle:** Con Python 3.14 y el intérprete *free-threaded* opcional, el argumento de
rendimiento de async frente a hilos cambia; el argumento de consistencia (una cadena, un modelo
de ejecución) no.

---

## 07 · PHP y Laravel

### Preguntas

### 1. 🟢 ¿Por qué `src/` contiene el núcleo y `app/` la infraestructura, cuando Laravel espera lo contrario?

⏱️ **30 segundos:** Porque `app/` es el directorio que Laravel llena de cosas suyas
(controladores, providers, modelos): es infraestructura por definición. El núcleo va a un
namespace propio (`Hex\`) en `src/`, donde no hay ningún `use Illuminate`.

🗣️ **2 minutos:** El esqueleto pone `App\` en `app/` y autodescubre providers y comandos ahí. Si el
dominio viviera en `app/Domain`, compartiría namespace y hábitos con los adaptadores, y `deptrac`
tendría que distinguirlos por subcarpeta. Con `Hex\Domain` y `Hex\Application` en `src/`, la regla
es un `grep`: ningún archivo bajo `src/` importa `Illuminate`.

🔬 **El detalle:** El `autoload.psr-4` de `composer.json` es lo único que Laravel necesita para
encontrar `src/`; el framework no tiene opinión sobre dónde vive lo que no es suyo.

### 2. 🟢 ¿Qué comprueba `implements` en PHP y cuándo, comparado con un `Protocol` de Python?

⏱️ **30 segundos:** Que la clase declara todos los métodos de la interfaz con firmas compatibles,
y lo comprueba el intérprete al cargar la clase: un `PgOrders` sin `list` es un error fatal antes
de la primera petición. Un `Protocol` solo lo comprueba un type checker externo.

🗣️ **2 minutos:** Es contrato nominal: el adaptador *dice* que implementa el puerto. La ventaja
es que el fallo aparece temprano y sin herramienta extra; la desventaja, que los fakes de las
pruebas también tienen que declararlo. Lo que `implements` no comprueba es el comportamiento
(que `reserve` descuente o lance): para eso están la suite y `deptrac`.

🔬 **El detalle:** PHP permite covarianza en retornos y contravarianza en parámetros al
implementar; `Page` sin genéricos reales obliga a los `@return Page<Order>` en docblocks para
PHPStan (ejercicio 1).

### 3. 🟢 ¿Cómo llega un `CreateOrder` al controlador sin que nadie lo registre en el provider?

⏱️ **30 segundos:** Por autowiring: el contenedor lee el constructor de `OrderController`, ve
`CreateOrder`, lee el constructor de `CreateOrder`, ve interfaces (`Products`, `Orders`…) y
resuelve cada una con el `singleton` que el provider registró para ese puerto.

🗣️ **2 minutos:** El provider solo enlaza interfaz → implementación. Todo lo que sea una clase
concreta con dependencias tipadas se construye solo, recursivamente. Por eso un caso de uso nuevo
no toca el provider: si sus puertos ya están enlazados, funciona. Es la misma idea que el
`@Component` de Spring, sin anotación.

🔬 **El detalle:** Los casos de uso no son singletons: el contenedor construye uno por
resolución. Da igual porque son `readonly` sin estado; si tuvieran estado, habría que
registrarlos como `scoped`.

### 4. 🟢 ¿Por qué `Order` no extiende `Model`?

⏱️ **30 segundos:** Porque un modelo Eloquent es una fila con métodos: conoce su tabla, su
conexión, sus relaciones y se guarda solo. `Order` protege invariantes y transiciones; no sabe
que existe una base.

🗣️ **2 minutos:** Con Eloquent, `$order->status = 'PAID'; $order->save()` es legal desde cualquier
sitio: la máquina de estados se vuelve una convención. Con `private(set)` y `applyPayment`, la
única forma de llegar a `PAID` es la que el dominio permite. Eloquent puede vivir en el
adaptador (ejercicio 7) como modelo de persistencia; en el núcleo, no.

🔬 **El detalle:** El coste real de `extends Model` no es el acoplamiento a la base, sino el
*lazy loading*: `$order->lines` fuera de la transacción hace una consulta que nadie ve.

### 5. 🟢 ¿Qué hace `public private(set)` en `Order` y qué problema evita?

⏱️ **30 segundos:** Lectura pública, escritura privada (PHP 8.4). `$order->status` se lee desde
el controlador; `$order->status = …` desde fuera no compila. Evita los getters vacíos y la
mutación accidental.

🗣️ **2 minutos:** Antes de 8.4 había que elegir entre propiedad pública (mutable desde fuera) o
privada con `getStatus()`. La visibilidad asimétrica da lo primero sin lo segundo. Es el mismo
mecanismo que hace que `readonly` no sirva aquí: `status` cambia, pero solo desde `Order`.

🔬 **El detalle:** Fue exactamente lo que `qossmic/deptrac` no supo leer (§8): un rasgo del
lenguaje de 2024 contra un parser de 2023.

### 6. 🟡 ¿Cómo comparten `PgOrders` y `PgInventory` la transacción sin `ContextVar` ni `AsyncLocalStorage`?

⏱️ **30 segundos:** Reciben la misma instancia de `ConnectionInterface` (singleton en el
provider). `DbUnitOfWork::run` llama a `transaction()` sobre ella; todo lo que use esa conexión
dentro del closure está en la transacción.

🗣️ **2 minutos:** En PHP clásico una petición es un proceso: no hay concurrencia dentro de él,
así que "la conexión" es única y sirve de contexto. Python y Node comparten un proceso entre
peticiones y necesitan un contexto por ejecución; Go lo pasa explícito. PHP obtiene gratis lo que
los otros construyen. La pregunta 13 mira qué pasa cuando esa premisa cae.

🔬 **El detalle:** `transaction()` anidado usa `SAVEPOINT`; `AuthorizePayment` no anida (dos
`run` consecutivos), y por eso el proveedor queda fuera de cualquier transacción.

### 7. 🟡 ¿Por qué la outbox es un comando artisan y no un hilo o un `lifespan`?

⏱️ **30 segundos:** Porque no hay proceso de servidor con vida larga donde colgar un hilo: cada
petición arranca y muere. El trabajo periódico es otro proceso, y artisan es la forma canónica
de escribirlo.

🗣️ **2 minutos:** Es el mismo modelo de `queue:work` y `schedule:work`: un proceso que arranca el
framework una vez y hace un bucle. Tiene su conexión, su `UnitOfWork` y su parada (`pcntl_signal`).
El caso de uso `DeliverPendingPublications` es idéntico al de los otros sabores; solo cambia
quién lo llama. Es lo que el capítulo 04/03 quería decir con "la política es del núcleo, el
disparador es infraestructura".

🔬 **El detalle:** Con Octane o FrankenPHP sí hay proceso de larga vida, pero seguiría siendo
mala idea mezclar el bucle con el servidor: un proceso, una responsabilidad.

### 8. 🟡 ¿Qué son "reportar" y "traducir" en el manejador de excepciones de Laravel, y por qué el taller necesita `dontReport`?

⏱️ **30 segundos:** Reportar es registrar (log, Sentry) y traducir es convertir en respuesta.
Laravel hace ambas con toda excepción. Un `InvalidCredentials` que se traduce a `401` seguía
apareciendo como `ERROR` en el log: 24 líneas en una corrida en verde.

🗣️ **2 minutos:** Los frameworks suelen preguntar solo "¿qué respondo?". Laravel pregunta también
"¿lo cuento?", y por defecto cuenta todo. Un rechazo de negocio con nombre propio no es una
alarma; `dontReport` lo declara. Sin eso, el log de producción está lleno de ruido y la alerta
real no se ve.

🔬 **El detalle:** `ValidationException` ya está en la lista interna de no reportables de Laravel;
las nuestras, no. `report: false` como propiedad en la excepción es la alternativa por clase.

### 9. 🟡 ¿Por qué `StrictInteger` existe si la regla `integer` ya está?

⏱️ **30 segundos:** Porque `integer` usa `FILTER_VALIDATE_INT` y acepta `"10"` como texto. El
contrato dice entero, y aceptar texto es aceptar un cliente que no lo cumple.

🗣️ **2 minutos:** Laravel valida sobre datos de formulario, donde todo es texto; su regla
`integer` está pensada para eso. Con JSON el tipo existe y se puede exigir: `is_int`. Se
mantiene `integer` además de `StrictInteger` porque `min:0` calcula el tamaño como número solo
si la regla numérica está presente; sin ella compararía longitud de cadena.

🔬 **El detalle:** Es el `strict=True` de Pydantic, hecho a mano; Laravel no tiene un modo
estricto global.

### 10. 🟡 ¿Qué pierde un `DateTimeImmutable` enlazado directamente en una consulta de Laravel, y cómo lo evita `Rows::bindTime`?

⏱️ **30 segundos:** Laravel formatea los `DateTimeInterface` con `Y-m-d H:i:s`: sin
microsegundos ni zona horaria. `bindTime` produce `Y-m-d H:i:s.uP` como texto y el SQL lo castea
a `timestamptz`.

🗣️ **2 minutos:** Sin microsegundos, dos pedidos en el mismo segundo empatan en `created_at` y el
cursor `(created_at, id)` sigue funcionando por el `id`, pero el orden ya no es el de creación. Sin
zona, PostgreSQL interpreta la hora en la zona de la sesión; en el laboratorio es UTC y no se nota,
en producción sí. Enlazar texto hace explícito lo que se manda.

🔬 **El detalle:** `prepareBindings` de la conexión es donde ocurre; se puede cambiar el formato
por gramática, pero es más honesto no enlazar objetos de fecha.

### 11. 🟠 El error de `deptrac`: ¿por qué una herramienta que "funciona" deja de funcionar al usar `private(set)`, y qué dice eso de las herramientas de análisis en PHP?

⏱️ **30 segundos:** Porque `deptrac` no usa el parser de PHP: embebe `nikic/php-parser`, y la
versión embebida (4.19, en un paquete abandonado) es anterior a la sintaxis. El lenguaje avanzó y
la herramienta no.

🗣️ **2 minutos:** En PHP el análisis estático (PHPStan, deptrac, Rector, Pint) parsea el código
por su cuenta; cada herramienta arrastra su versión de php-parser. Un rasgo nuevo del lenguaje
puede dejar una herramienta ciega sin que nada avise. Y `qossmic/deptrac` no dijo "me he mudado a
`deptrac/deptrac`": Packagist listaba 2.0.4 como última. Lección: fijar versiones no basta;
hay que saber si el paquete sigue vivo.

🔬 **El detalle:** El síntoma era una traza de `Lexer->getNextToken('private(set)')`, no un
mensaje de "sintaxis no soportada": la herramienta ni sabía que le faltaba algo.

### 12. 🟠 Sin `Accept: application/json`, una validación fallida devuelve `302`. Explica por qué el framework hace eso y por qué un traductor central es la respuesta y no `$request->expectsJson()`.

⏱️ **30 segundos:** Laravel asume que una petición sin `Accept: application/json` viene de un
formulario Blade: redirige atrás con los errores en sesión. Con el `Accept`, responde `422` con
su forma. El contrato no depende de una cabecera opcional del cliente: `400` siempre, con
`errors[{field, message}]`.

🗣️ **2 minutos:** `expectsJson()` haría el comportamiento correcto condicional a que el cliente
mande la cabecera; hurl no la manda y muchos clientes tampoco. El traductor central captura
`ValidationException` antes de que Laravel decida, y lo convierte a la forma del contrato sin
mirar cabeceras. Es la misma idea que `problems.py` en FastAPI y el `@RestControllerAdvice` en
Java: una API con contrato sustituye el comportamiento por defecto entero.

🔬 **El detalle:** `shouldRenderJsonWhen` (que el esqueleto trae) solo cambia el `302` por el
`422` de Laravel; sigue sin ser el contrato.

### 13. 🟠 Compara el contexto transaccional de los cinco sabores: `ContextVar`, `AsyncLocalStorage`, `ctx`, `TransactionTemplate` y "la conexión de la petición" en PHP. ¿Qué modelo de ejecución lo hace posible en PHP y qué pasa con PHP-FPM, Octane o un worker de larga vida?

⏱️ **30 segundos:** Los cinco resuelven lo mismo: que dos adaptadores compartan la transacción
sin que el caso de uso la vea. PHP lo obtiene del modelo "una petición, un proceso": la conexión
es única y no hay con quién compartirla. Con FPM sigue siendo cierto (un proceso por petición a
la vez); con Octane o un worker, el proceso vive muchas peticiones y los singletons se comparten.

🗣️ **2 minutos:** Java lo guarda en un `ThreadLocal` (una petición, un hilo); Python y Node en
un contexto por ejecución (muchas peticiones, un hilo); Go lo pasa a mano. PHP clásico no
necesita nada porque el proceso *es* el contexto. Octane rompe la premisa: la misma instancia de
`ConnectionInterface` atiende peticiones sucesivas, y una transacción que no cerró contamina la
siguiente. Sigue sin haber concurrencia dentro del proceso (Swoole por corrutinas sí puede
tenerla), así que la solución es reiniciar estado entre peticiones, no un `ContextVar`.

🔬 **El detalle:** El worker de la outbox ya es un proceso de larga vida: por eso su `UnitOfWork`
abre y cierra la transacción en cada ronda y no guarda nada entre rondas.

### 14. 🟠 Un compañero propone `mongodb/laravel-mongodb` para la parte 3 "porque ya tenemos Eloquent". ¿Qué cambiaría en el núcleo y por qué el taller elige la librería oficial?

⏱️ **30 segundos:** En el núcleo, nada, si el adaptador sigue devolviendo `Product`: el puerto
manda. Pero `laravel-mongodb` es Eloquent para Mongo, y este sabor no tiene Eloquent en ningún
sitio; meterlo solo para el catálogo añade un modelo activo y una conexión Laravel para una
colección.

🗣️ **2 minutos:** La librería oficial (`mongodb/mongodb`) da `Client`, `Collection`, `find` y
`updateOne`: es lo que el adaptador necesita y nada más, sin `config/database.php` ni provider
extra. La razón de fondo es la coherencia: el sabor decidió que el ORM activo no es el dominio;
un adaptador con Eloquent sería la excepción que invita a la siguiente. Si el proyecto ya usara
Eloquent para PostgreSQL (ejercicio 7), la conversación sería otra.

🔬 **El detalle:** `laravel-mongodb` 5.11 exige `ext-mongodb ^2` igual que la librería: el coste
de instalación es el mismo, la diferencia es solo de diseño.

### Ejercicios

### 1. 🟢 Añade `phpstan/phpstan` al grupo `dev`, corre `vendor/bin/phpstan analyse src app --level 6` y arregla lo que encuentre. Después borra `list` de `PgOrders` y comprueba que PHP mismo lo detecta al cargar la clase (y en qué momento).

⏱️ **30 segundos:** PHPStan pedirá tipos de arrays (`list<OrderLine>`, `array<string, int>`)
donde solo hay docblocks parciales. Sin `list`, PHP lanza un error fatal
("Class PgOrders contains 1 abstract method") en cuanto el contenedor intenta instanciarla: la
primera petición que la necesite, no al arrancar.

🗣️ **2 minutos:** Es la diferencia con Python: allí el `Protocol` roto pasa hasta que se llama al
método; aquí falla al cargar la clase. Pero "al cargar" es perezoso (autoload): un `lab.py php
--test` no la carga, así que la suite es la que la vería. Un `php artisan route:list` o un
`composer dump-autoload --strict-psr` tampoco. PHPStan sí, sin correr nada.

🔬 **El detalle:** Con `--level 6`, `Page` sin genéricos reales produce avisos de tipo
`mixed`; `@template` en docblocks los resuelve y es la práctica de PHPStan para colecciones.

### 2. 🟢 Quita `$exceptions->dontReport([...])` de `bootstrap/app.php`, corre `02-auth.hurl` y cuenta las líneas `local.ERROR`. Vuelve a ponerlo.

⏱️ **30 segundos:** Cuatro: dos `invalid credentials`, un `UNAUTHENTICATED` y un
`TOKEN_REVOKED`, todos de peticiones que la suite espera en `401`.

🗣️ **2 minutos:** Reproducir el error de §8 muestra que el ruido nace de respuestas correctas.
Con `LOG_CHANNEL=stderr` se ve en la terminal del servidor; en producción sería un archivo o un
agregador donde cada `401` de un cliente con token caducado cuenta como error del sistema.

🔬 **El detalle:** `dontReport` acepta clases base: `DomainError` y `ApplicationError` cubren
todas las suyas; las del borde (`Unauthenticated`, `MissingIdempotencyKey`, `ValidationFailed`)
se listan una a una.

### 3. 🟡 Escribe una prueba con el `TestCase` de Laravel (`Tests\TestCase` + `$this->postJson`) que sustituya `CreateOrder` por un fake con `$this->app->instance(CreateOrder::class, …)`: sin cabecera → `400 IDEMPOTENCY_KEY_REQUIRED`; `{ "lines": [] }` → `400 VALIDATION_FAILED` con `field` `lines`. Explica qué anillo cubre y qué hay que configurar para que no toque PostgreSQL.

⏱️ **30 segundos:** Cubre el borde HTTP: middleware, Form Request, traductor. `CreateOrder` es
`final readonly`, así que el fake no puede extenderla: se registra una instancia construida con
fakes de los puertos (`new CreateOrder($fakeProducts, …)`), o se enlazan los puertos a fakes y
se deja al contenedor construirla.

🗣️ **2 minutos:** El `TestCase` de Laravel arranca la aplicación entera, con `.env`; para no tocar
PostgreSQL hay que enlazar `ConnectionInterface` a un doble (o los puertos, que es más limpio) y
`TokenVerifier` a uno que acepte cualquier token. `phpunit.xml` del esqueleto ya fuerza
`DB_CONNECTION=sqlite :memory:` para eso. Es el anillo "adaptador HTTP integrado" de 04/06.

🔬 **El detalle:** El `400 IDEMPOTENCY_KEY_REQUIRED` sale antes de tocar el caso de uso (la
cabecera se lee en el controlador), pero después del middleware: la prueba necesita un token
válido o un `TokenVerifier` falso.

### 4. 🟡 Quita `new StrictInteger` de `CreateProductRequest` y envía `"stock": "10"`. Explica qué pasó, dónde se convirtió el texto en entero y por qué el contrato prefiere rechazarlo.

⏱️ **30 segundos:** Pasa la validación (`integer` acepta `"10"`) y `$request->integer('stock')`
lo convierte a `10` en el controlador: el producto se crea. La conversión ocurre en el borde,
silenciosa.

🗣️ **2 minutos:** El contrato declara `stock` como entero; aceptar `"10"` es aceptar `"10 "`,
`"1e1"` o `" 10"` según lo que `FILTER_VALIDATE_INT` tolere, y un cliente que no cumple el
contrato sin enterarse. Rechazarlo hace visible el error donde se produce (el cliente), no donde
se descubre (un informe con stocks raros).

🔬 **El detalle:** `TrimStrings` y `ConvertEmptyStringsToNull`, en la pila global, ya
transforman la entrada antes de validar: otra coerción silenciosa que conviene conocer.

### 5. 🟠 En `PgInventory::reserve`, sustituye `$this->db` del `INSERT` de la reserva por una conexión nueva: `DB::connectUsing('extra', config('database.connections.pgsql'))` (o `DB::purge` + `DB::connection`). Corre `04-orders.hurl` y compara con el error provocado del taller 05 (Go).

⏱️ **30 segundos:** Igual que en Go: la conexión nueva no ve el pedido no confirmado, la FK
rechaza el `INSERT` (`QueryException`), `500` en vez de `201`, y nada huérfano gracias al
`ROLLBACK` de la transacción original.

🗣️ **2 minutos:** En PHP el error exige esfuerzo: hay que pedir otra conexión a propósito,
porque la única que el contenedor entrega ya es la de la transacción. Es la ventaja del modelo
"una petición, un proceso" frente a Go, donde `db` y `tx` conviven en el mismo `struct` y el
error es un despiste.

🔬 **El detalle:** `DB::connection('pgsql')` devolvería la misma instancia (el `DatabaseManager`
las cachea por nombre); para una conexión distinta de verdad hace falta otro nombre o `purge`.

### 6. 🟠 Convierte `OutboxWork` en una tarea del scheduler (`Schedule::command('outbox:work --once')->everySecond()`) y corre `php artisan schedule:work`. Explica qué gana, qué pierde y por qué `--once` es obligatorio ahí.

⏱️ **30 segundos:** Gana un único proceso supervisor para todos los trabajos periódicos y la
integración con `withoutOverlapping`. Pierde el intervalo de 500 ms (el scheduler baja a un
segundo) y arranca el framework en cada ronda. `--once` es obligatorio porque el scheduler espera
que el comando termine: un bucle infinito bloquearía todas las demás tareas.

🗣️ **2 minutos:** El scheduler de Laravel es `cron` con azúcar: lanza comandos y espera. Un
comando que no vuelve rompe el modelo. Con `--once`, cada ronda es un proceso nuevo con conexión
nueva: más lento, pero sin estado acumulado. Es el mismo trade-off que la pregunta 13: el
proceso corto es más simple y más caro.

🔬 **El detalle:** `everySecond` existe desde Laravel 10 con `schedule:work`; con `cron` real el
mínimo es un minuto.

### 7. 🔴 Sustituye `PgOrders` por una implementación con Eloquent (`OrderRow extends Model` con `HasMany` a `OrderLineRow`) que devuelva el mismo `Order` del dominio, manteniendo `DbUnitOfWork`. Mide cuántos archivos cambian y argumenta si el ORM compensa en este sistema.

⏱️ **30 segundos:** Cambian `PgOrders` y aparecen dos modelos (`OrderRow`, `OrderLineRow`) más
un mapeo en cada dirección; el núcleo y el borde no se enteran. Unas 120 líneas de modelos y
mapeo a cambio de quitar tres consultas a mano.

🗣️ **2 minutos:** Eloquent compensa cuando el modelo de persistencia tiene vida propia:
relaciones que se cargan a demanda, scopes, eventos. Aquí hay tres tablas fijas leídas siempre
enteras. Y trae el riesgo de 05/01: `$row->lines` cargado perezosamente fuera de la transacción,
o alguien devolviendo `OrderRow` en vez de `Order` "por ahorrar". La lección es que la decisión
cabe en un archivo porque el puerto está bien puesto.

🔬 **El detalle:** `DbUnitOfWork` sigue valiendo: Eloquent usa la misma conexión del
`DatabaseManager`, así que `transaction()` lo envuelve igual.

### 8. 🔥 Corre el sabor bajo Laravel Octane (Swoole o FrankenPHP) en vez de `artisan serve`. Explica qué deja de ser cierto de "una petición es un proceso" (singletons, la conexión, el `Actor` en los atributos), qué se rompería en este taller y cómo lo resolverías.

⏱️ **30 segundos:** Con Octane el proceso vive miles de peticiones: los singletons del provider
se reutilizan, la conexión también, y cualquier estado que quedara en ellos pasa a la petición
siguiente. En este taller, nada guarda estado por petición en singletons (el `Actor` va en la
`Request`, que sí es por petición), así que funcionaría; el riesgo está en lo que no se ve: una
transacción abierta por un error no capturado.

🗣️ **2 minutos:** Octane reinicia parte del contenedor entre peticiones, pero los singletons
registrados por providers se conservan. La regla es la de los otros sabores: los adaptadores no
guardan estado de la petición; el estado va en la `Request` o en parámetros. Lo que habría que
revisar: `MongoProducts` y `PredisClient` (conexiones persistentes, bien), `DbUnitOfWork` (la
transacción se cierra siempre porque `transaction()` la envuelve en `try/finally`), y el
`Authenticate` (no tiene estado). El rendimiento subiría de 19 a cientos de peticiones por
segundo: el arranque del framework por petición desaparece.

🔬 **El detalle:** Con Swoole en modo corrutina sí habría concurrencia dentro del proceso, y
entonces la conexión única deja de ser un contexto seguro: haría falta un pool y un contexto
por corrutina, que es exactamente el `ContextVar` de Python.

---

## 08 · Colas con JMS y ActiveMQ Artemis

### Preguntas

### 1. 🟢 ¿Por qué el consumidor JMS llama a `CreateOrder` y no a `JpaOrders`?

⏱️ **30 segundos:** Porque crear un pedido es reservar inventario, comprobar idempotencia y
guardar la clave con el efecto, todo en una transacción: eso es el caso de uso. Un consumidor que
escribiera en `orders` directamente tendría que repetir esa política, y la repetiría mal.

🗣️ **2 minutos:** El consumidor es un adaptador de entrada del mismo puerto que HTTP. Traduce el
mensaje a `CreateOrder.Command`, exactamente como `OrderController` traduce el JSON. Cuando cambie
una regla (un límite de líneas, una validación de SKU), cambia en un sitio y las dos puertas la
heredan. Es lo que 03/02 llama "el handler no es el caso de uso".

🔬 **El detalle:** El adaptador sí usa un puerto de salida (`Users.findByEmail`) para construir el
`Actor`. Un adaptador de entrada puede usar puertos de aplicación; lo que no puede es usar otro
adaptador (`inbound` → `outbound`), y ArchUnit lo vigila.

### 2. 🟢 ¿Qué es `operationId` para el caso de uso y por qué un mensaje repetido no crea un segundo pedido?

⏱️ **30 segundos:** Es la `Idempotency-Key`. El caso de uso la busca en `idempotency_keys`
(actor + clave) antes de hacer nada; si existe con la misma huella, devuelve el pedido guardado y
`replayed=true`.

🗣️ **2 minutos:** La clave se guarda en la misma transacción que el pedido; por eso una caída
entre commit y ACK deja *o las dos cosas o ninguna*. La re-entrega encuentra la clave, no reserva
otra vez y responde lo mismo. Nada de esto se escribió para la cola: estaba desde el taller 03
porque HTTP también reintenta.

🔬 **El detalle:** Con la misma clave y otra huella (`sku:qty` distinto), el caso de uso lanza
`IdempotencyKeyReused` y el adaptador responde `REJECTED` con ese código: la clave protege contra
repetir, no contra reutilizar.

### 3. 🟢 ¿De dónde sale el `Actor` en el consumidor y qué del mensaje NO se usa para construirlo?

⏱️ **30 segundos:** De `Users.findByEmail(customerEmail)`: id, email y rol reales de la base. Del
mensaje no se usa ningún rol ni id que pudiera venir en el cuerpo.

🗣️ **2 minutos:** La autenticación la hizo el broker: el emisor se conectó con usuario y
contraseña. El mensaje solo dice a nombre de quién actúa, y el sistema decide qué es esa persona.
Es el mismo principio que en HTTP, donde el rol viene del token que el servidor firmó, nunca del
cuerpo (03/04).

🔬 **El detalle:** Si el correo no existe se responde `UNKNOWN_CUSTOMER` y se confirma: no es un
fallo técnico y reintentarlo no lo arreglaría.

### 4. 🟢 ¿Qué se responde y qué se reintenta? Da un ejemplo de cada uno.

⏱️ **30 segundos:** Se responde lo que el negocio decidió: `INSUFFICIENT_INVENTORY`,
`PRODUCT_NOT_FOUND`, `IDEMPOTENCY_KEY_REUSED`, `UNKNOWN_CUSTOMER`. Se reintenta lo que no se pudo
decidir: un cuerpo ilegible, PostgreSQL caído.

🗣️ **2 minutos:** La prueba es la pregunta "¿el siguiente intento puede salir distinto?". Sin stock,
reintentar en medio segundo no crea stock: se responde. Base caída, sí puede: se reintenta. Un
cuerpo que no es JSON nunca será JSON: se reintenta igual, pero solo porque no hay a quién
responder, y por eso acaba en la DLQ como cuarentena.

🔬 **El detalle:** En el código, la línea es `catch` de las excepciones de negocio → `OrderReply.rejected`;
todo lo demás sale del método como excepción y el contenedor hace rollback.

### 5. 🟢 ¿Qué es la DLQ en Artemis y cuándo llega ahí un mensaje con la configuración por defecto?

⏱️ **30 segundos:** La *dead letter queue*: la cola a la que el broker mueve un mensaje que falló
`max-delivery-attempts` veces (10 por defecto) con `redelivery-delay` 0. Deja de bloquear la cola
original y espera a que alguien lo mire.

🗣️ **2 minutos:** El taller la vio en un segundo: diez `delivery #` y `MESSAGE COUNT 1` en `DLQ`.
Es la política por defecto de las *address settings* (`#`); en producción se fija por dirección:
menos intentos, un `delay` creciente, y alguien que lea la DLQ. El ejercicio 5 lo hace.

🔬 **El detalle:** `JMSXDeliveryCount` es la propiedad que el broker incrementa; el listener la lee
para el caos. Es también lo que un consumidor usaría para "al tercer intento, apartar sin esperar".

### 6. 🟡 Describe el orden exacto de commit de la base, envío de la respuesta y ACK en este taller, y dónde está la ventana.

⏱️ **30 segundos:** (1) el caso de uso confirma PostgreSQL y vuelve; (2) el listener encola la
respuesta en la sesión transaccionada; (3) el método vuelve; (4) el contenedor confirma la sesión:
respuesta enviada y ACK, juntos. La ventana está entre (1) y (4).

🗣️ **2 minutos:** Si el proceso cae entre (1) y (4), el pedido existe, la respuesta no salió y el
mensaje vuelve a la cola. La re-entrega hace (1) otra vez —que ahora es un `replayed`— y llega a
(4). El resultado: efecto único en la base, respuesta posiblemente doble, mensaje confirmado una
vez. El taller lo provocó con `Runtime.halt` entre (2) y (3).

🔬 **El detalle:** (2) y (4) van juntos porque el `JmsTemplate` participa en la sesión que el
`JmsTransactionManager` ligó al hilo; con una sesión propia la respuesta saldría antes del ACK y
podría salir sin pedido si (1) fallara después... que no puede, porque (1) ya pasó. El orden lo
salva.

### 7. 🟡 ¿Por qué el `JmsTransactionManager` no es un `@Bean`?

⏱️ **30 segundos:** Porque `OrdersConfiguration` inyecta `PlatformTransactionManager` para
construir el `UnitOfWork`, y con dos beans de ese tipo (JPA y JMS) la inyección sería ambigua. Se
construye dentro de la fábrica del listener y no sale de ahí.

🗣️ **2 minutos:** La alternativa es `@Primary` en el de JPA o `@Qualifier` en cada punto de uso;
ambas funcionan y ambas reparten por el sistema una decisión que solo importa al adaptador JMS.
Un objeto local dice lo que es: el gestor de transacciones *de esta sesión*.

🔬 **El detalle:** El mismo problema apareció en el taller 03 con dos `CorsConfigurationSource`.
Spring resuelve por tipo; dos candidatos del mismo tipo son un error de diseño antes que de
configuración.

### 8. 🟡 ¿Por qué `replayed` va en la respuesta? ¿Quién lo necesita?

⏱️ **30 segundos:** Porque la respuesta puede llegar dos veces (una por cada entrega tras una
caída) y el emisor puede haber reenviado. `replayed=true` le dice: "esto ya lo tenías; no es un
segundo pedido".

🗣️ **2 minutos:** Es la `Idempotent-Replay: true` de HTTP en el canal de mensajes. Sin ella, un
emisor que contara respuestas `ACCEPTED` contaría pedidos de más. El contrato lo declara para que
el consumidor de respuestas deduplique por `operationId` en vez de por respuesta.

🔬 **El detalle:** En la provocación con dos instancias, la respuesta re-entregada vino de la
instancia que nunca había visto el mensaje, y aun así traía `replayed=true`: lo sabe la base.

### 9. 🟡 Con dos instancias, la re-entrega fue a la otra y aun así respondió `replayed=True`. ¿Dónde vive la deduplicación y qué pasaría si viviera en memoria?

⏱️ **30 segundos:** En `idempotency_keys`, en PostgreSQL, guardada en la misma transacción que el
pedido. En memoria, la segunda instancia no sabría nada y crearía el pedido otra vez.

🗣️ **2 minutos:** Una caché de "mensajes vistos" por instancia es la trampa clásica: funciona con
una instancia y con dos deja de ser deduplicación. Lo que hace correcto el reparto de una cola
anycast es que cualquier consumidor llegue al mismo estado compartido. La clave única de la tabla
además resuelve la carrera de dos entregas simultáneas (ejercicio 6).

🔬 **El detalle:** El coste es una lectura por mensaje; el beneficio es que "al menos una vez" del
broker se convierte en "efecto una vez" sin coordinar consumidores.

### 10. 🟡 ¿Por qué el listener recibe `jakarta.jms.Message` y no `@Payload String`?

⏱️ **30 segundos:** Porque el emisor decide la forma: un cliente STOMP con `content-length`
entrega un `BytesMessage`, uno JMS un `TextMessage`, y un mensaje STOMP puede no traer
`JMSMessageID`. Con `@Payload String` y `@Header(MESSAGE_ID)`, todo mensaje STOMP fue a la DLQ.

🗣️ **2 minutos:** Un borde asume lo mínimo del otro lado: lee texto o bytes, trata cada cabecera
como opcional y solo exige lo que el contrato exige (un cuerpo JSON con `operationId`). Es la
robustez del capítulo 03/05 aplicada a mensajes: la forma pública se valida donde entra, no se
presupone.

🔬 **El detalle:** `@Payload String` sobre un `BytesMessage` habría hecho `toString()` de un
`byte[]` (`[B@...`) si la conversión hubiera pasado: un error más silencioso que el que se vio.

### 11. 🟠 Explica el error del `JpaTransactionManager` en el contenedor: por qué un rechazo de negocio acabó en `Transaction silently rolled back` y diez re-entregas.

⏱️ **30 segundos:** Con la transacción de la base abierta por el contenedor, `unitOfWork.run` se
une a ella. `IdempotencyKeyReused` sale de ese `run`, y Spring marca la transacción externa como
*rollback-only*. El listener captura y responde, pero al volver el contenedor intenta confirmar y
recibe `UnexpectedRollbackException`: rollback, redelivery, y así diez veces.

🗣️ **2 minutos:** La regla de Spring: una transacción participante que lanza marca la global; el
que abrió la global no puede "desmarcarla" capturando después. El diseño arreglado devuelve la
transacción de la base al caso de uso —que la abre, la cierra y traduce sus excepciones a
resultados dentro de ella— y deja al contenedor solo la sesión JMS. Es la lección hexagonal: la
transacción del caso de uso es suya; un adaptador que la envuelve cambia la semántica de sus
excepciones.

🔬 **El detalle:** El síntoma engañaba: `replied REJECTED` en el log y sin embargo re-entregas; y
cinco segundos de *backoff* entre intentos porque el contenedor trata el fallo de commit como
"fallo de setup" y reintenta con `FixedBackOff`.

### 12. 🟠 ¿Qué pierde y qué gana este diseño frente a XA (una transacción distribuida entre PostgreSQL y Artemis)? ¿Cuándo elegirías XA?

⏱️ **30 segundos:** Pierde la atomicidad entre base y broker: existe la ventana y se necesita
idempotencia. Gana simplicidad, rendimiento (sin *two-phase commit*, sin coordinador, sin
recuperación de transacciones en duda) y que la idempotencia protege también de reintentos que XA
no cubre (el emisor que reenvía).

🗣️ **2 minutos:** XA hace que commit y ACK sean uno, a cambio de un protocolo de dos fases con un
gestor (Narayana, Atomikos), *heurísticas* cuando algo cae entre fases, y bloqueos más largos.
Como el sistema necesita idempotencia de todos modos (HTTP reintenta, el emisor reintenta), XA
añade coste sin quitar la necesidad. La elegiría cuando los efectos no son idempotizables y el
coste de un duplicado es inaceptable: raro, y mejor rediseñar el efecto.

🔬 **El detalle:** Spring lo llama "best effort 1PC" cuando el JMS participa en la transacción de
la base; aquí ni eso: dos transacciones locales ordenadas, que es más honesto sobre la ventana.

### 13. 🟠 El emisor STOMP y el listener JMS discreparon en tres cosas (tipo de cuerpo, `JMSMessageID`, tipo del `reply-to`). ¿Qué dice eso sobre dónde va la tolerancia en un borde de mensajes, y qué debería fijar el contrato AsyncAPI?

⏱️ **30 segundos:** Que un broker multiprotocolo no normaliza la forma: cada cliente produce
mensajes ligeramente distintos y el consumidor los ve todos. La tolerancia va en el adaptador
(leer texto o bytes, cabeceras opcionales, `reply-to` solo si es cola), y el contrato debería fijar
lo que el consumidor sí exige: cuerpo JSON, `operationId`, y que la respuesta va a `orders.reply`
salvo `JMSReplyTo` de tipo cola.

🗣️ **2 minutos:** AsyncAPI describe canales, mensajes y esquemas; no describe si el cuerpo viaja
como bytes o texto ni qué tipo tiene un destino de respuesta. Eso es protocolo (bindings), y
conviene declararlo o, mejor, no depender de ello. El taller eligió no depender: el adaptador
acepta ambas formas y decide el destino de respuesta por su tipo. El contrato quedó como lo que
un emisor tiene que cumplir, no como lo que un consumidor asume.

🔬 **El detalle:** El `reply-to` de STOMP sin prefijo llega al lado JMS como topic porque Artemis
no puede saber el *routing type* de un nombre; `jms.queue.`/`jms.topic.` como prefijo lo
desambiguaría, a costa de acoplar el emisor a Artemis.

### 14. 🟠 Compara este adaptador con `OrderController`: qué comparten, qué traduce cada uno distinto y por qué `IdempotencyKeys.hash` tiene que ser el mismo en los dos.

⏱️ **30 segundos:** Comparten el caso de uso, el comando, la clave y la huella. Difieren en cómo
llega la identidad (token verificado vs correo resuelto por puerto), cómo se responde (201/200 con
cabeceras vs `OrderReply` correlacionado) y qué es un error (`problem+json` vs `REJECTED` o
redelivery). La huella debe ser la misma para que un pedido enviado por HTTP y repetido por cola
con la misma clave sea *la misma operación* y no un `IDEMPOTENCY_KEY_REUSED` falso.

🗣️ **2 minutos:** Dos adaptadores del mismo puerto son la prueba de que la frontera está bien
puesta: todo lo que tuvieron que duplicar es forma; todo lo que compartieron es política. Por eso
`IdempotencyKeys` pasó a `public`: era del borde HTTP y resultó ser del borde entero. Si mañana la
huella incluyera el correo, cambiaría en un sitio.

🔬 **El detalle:** Lo que sí difiere legítimamente: HTTP devuelve `Location`; la cola no tiene
recursos, devuelve `orderId`. Y la cola tiene un código más (`UNKNOWN_CUSTOMER`) porque su
identidad viene del cuerpo.

### Ejercicios

### 1. 🟢 Envía un `OrderRequested` con `--email ops@hex.local`. ¿Se crea el pedido a nombre del operador? Explica por qué el consumidor no comprueba el rol y qué regla del núcleo sí aplica igual.

⏱️ **30 segundos:** Sí: `ops` es un usuario y puede crear pedidos (también por HTTP). El
consumidor no comprueba el rol porque crear un pedido no exige ninguno; la regla que sí aplica es
la de `Actor.canSee` al consultarlo después, y `requireOperator` en lo que sí lo exige.

🗣️ **2 minutos:** La autorización contextual vive en el núcleo y se aplica igual venga la petición
de HTTP o de la cola: eso es lo que el taller demuestra. Lo que el consumidor no debe hacer es
inventarse una política propia ("por cola solo customers"): sería una regla de negocio en un
adaptador.

🔬 **El detalle:** `ops` creando pedidos a nombre propio es raro pero legal en el contrato; si el
negocio lo prohibiera, iría en `CreateOrder`, no en el listener.

### 2. 🟢 Vuelve a poner `factory.setTransactionManager(transactionManager)` con el de JPA, corre el escenario 3 (misma clave, otro cuerpo) y pega las diez líneas de `delivery #`. Restaura.

⏱️ **30 segundos:** Diez `OrderRequested received (delivery #N)` seguidas de `replied REJECTED`, un
`Transaction silently rolled back` y el mensaje en la DLQ; con cinco segundos entre intentos.

🗣️ **2 minutos:** Reproducir el error de §9 a mano fija la regla: el resultado de un caso de uso
puede ser una excepción, y esa excepción no debe marcar una transacción que el caso de uso no
abrió. Al restaurar, el mismo escenario responde `REJECTED` una vez y confirma.

🔬 **El detalle:** Hay que inyectar `PlatformTransactionManager` en la fábrica; como solo existe
el de JPA como bean, no hay ambigüedad. Precisamente por eso el error es fácil de cometer.

### 3. 🟡 Añade a `lab.py jms send` la opción `--content-length` que vuelva a mandar la cabecera, y comprueba que el listener sigue respondiendo (llega como `BytesMessage`). Explica qué habría pasado con la primera versión del listener.

⏱️ **30 segundos:** Con la cabecera, Artemis entrega un `BytesMessage`; `bodyOf` lo lee con
`getBodyLength` y `readBytes` y todo sigue igual. La primera versión (`@Payload String`) habría
fallado en la resolución de argumentos y el mensaje habría ido a la DLQ.

🗣️ **2 minutos:** Es la diferencia entre "funciona con mi cliente" y "funciona con el protocolo".
Un consumidor en producción recibe de clientes que no controla; probar con las dos formas es lo
mínimo. La opción en `lab.py` deja el experimento repetible.

🔬 **El detalle:** STOMP 1.2 recomienda `content-length` siempre; que Artemis cambie el tipo de
mensaje JMS por su presencia es una decisión del broker, documentada en su capítulo de STOMP.

### 4. 🟡 Escribe una prueba del adaptador sin broker: construye `OrderRequestedListener` con un `CreateOrder` de fakes (los del `CreateOrderTest`), un `JmsTemplate` de Mockito y un `ActiveMQTextMessage` en memoria, y comprueba que un `INSUFFICIENT_INVENTORY` produce un `OrderReply` `REJECTED` y **no** lanza. Explica qué anillo cubre.

⏱️ **30 segundos:** Cubre el adaptador: traducción del mensaje, resolución del actor, mapa de
excepciones a respuestas y correlación. No cubre la transacción JMS ni la redelivery, que son del
contenedor y del broker.

🗣️ **2 minutos:** `CreateOrder` con fakes es exactamente el de las pruebas del taller 03: el
listener recibe un caso de uso real con puertos falsos. El `JmsTemplate` de Mockito captura el
`MessagePostProcessor` para verificar el `JMSCorrelationID`. Es el anillo "adaptador aislado" de
04/06, para mensajes.

🔬 **El detalle:** `ActiveMQTextMessage` necesita una sesión para algunos métodos; para la prueba
basta con el `ClientMessage` interno o un `TextMessage` de Mockito con `getText` y `getJMSReplyTo`
configurados.

### 5. 🟠 Configura en el broker `max-delivery-attempts=3` y `redelivery-delay=500` para `orders.inbound` (address settings; la imagen admite un `broker.xml` propio montado en `etc-override/`), repite el mensaje envenenado y pega `jms dlq` con los tiempos del log. Explica por qué un `delay` de 0 es peligroso en producción.

⏱️ **30 segundos:** Tres entregas separadas medio segundo y a la DLQ. Con `delay` 0, un fallo
transitorio (base caída un segundo) consume los diez intentos en milisegundos y aparta mensajes
buenos.

🗣️ **2 minutos:** La política de reintentos es del broker, no del consumidor, y se configura por
dirección: `<address-setting match="orders.inbound">` con `redelivery-delay`,
`redelivery-delay-multiplier`, `max-redelivery-delay` y `max-delivery-attempts`. Un *backoff*
creciente da tiempo a que lo transitorio pase; un tope evita esperar para siempre.

🔬 **El detalle:** La imagen copia lo que haya en `etc-override/` sobre `etc/` al arrancar: hay
que montar un `broker.xml` completo, no un fragmento.

### 6. 🟠 Cambia `hex.jms.concurrency` a `3` en una sola instancia y envía `--count 9`. ¿Cuántos hilos aparecen en el log? ¿Sigue siendo correcto el reparto si dos mensajes traen el mismo `operationId` y llegan a la vez? Argumenta con la clave única de `idempotency_keys`.

⏱️ **30 segundos:** Tres hilos (`ntContainer#0-1..3`). Dos mensajes con la misma clave en paralelo:
los dos pasan el `find` sin encontrarla, los dos crean el pedido, y el `INSERT` en
`idempotency_keys` (clave única por actor + clave) falla en el segundo: su transacción revierte
entera, incluido su pedido.

🗣️ **2 minutos:** La clave única es la última línea de defensa, y por eso la clave se guarda en
la misma transacción que el efecto. El segundo mensaje sale del listener con una excepción de
integridad → rollback JMS → redelivery → esta vez encuentra la clave → `replayed`. Correcto, con
un reintento de más. Un `SELECT ... FOR UPDATE` de la clave evitaría la carrera al precio de
serializar.

🔬 **El detalle:** El mismo razonamiento vale para dos instancias: la base es la que serializa,
no el consumidor.

### 7. 🔴 Sustituye la respuesta por cola por un `OrderAccepted` en la outbox del taller 03: el listener solo crea el pedido y deja el hecho; el `DeliverPendingPublications` publica la respuesta en `orders.reply`. Explica qué garantía cambia (la respuesta ya no sale con el ACK) y qué pasa con `JMSCorrelationID`.

⏱️ **30 segundos:** La respuesta pasa a salir después del commit, por el dispatcher, al menos una
vez, y desacoplada del ACK: el mensaje de entrada se confirma aunque la respuesta tarde. El
`JMSCorrelationID` tiene que viajar en el hecho de la outbox (o en el pedido) para que el
dispatcher lo ponga en la respuesta.

🗣️ **2 minutos:** Se gana que una caída del broker de salida no bloquee la entrada y que la
respuesta sea un hecho durable; se pierde la simultaneidad respuesta+ACK. El `Notifier` del taller
03 se convierte en un publicador JMS: un adaptador de salida más detrás del mismo puerto. Es
04/03 aplicado a un canal de respuesta.

🔬 **El detalle:** El evento necesita `operationId` y `correlationId` como datos propios; el
dominio no sabe de JMS, así que el `correlationId` viaja como "referencia del solicitante", no
como cabecera.

### 8. 🔥 Implementa el mismo consumidor en NestJS (`06/04`) con un cliente STOMP o AMQP contra el mismo broker y el mismo `asyncapi.yaml`, y haz que `lab.py jms send` reciba respuestas de cualquiera de los dos. ¿Qué parte del contrato descubriste que estaba implícita en Java?

⏱️ **30 segundos:** Al menos tres: que la respuesta va a `orders.reply` si `JMSReplyTo` no es una
cola (Node no tiene "JMSReplyTo": tiene cabeceras STOMP), que el `operationId` es la
`Idempotency-Key` con la misma huella `sku:qty`, y qué cabeceras exactas correlacionan.

🗣️ **2 minutos:** Un segundo consumidor en otra plataforma es la mejor prueba de un contrato
asíncrono: todo lo que tuvo que copiarse del código Java en vez de leerse del `asyncapi.yaml`
estaba implícito. La corrección es escribirlo en el contrato (bindings de protocolo, huella
canónica, política de respuesta), no en un comentario.

🔬 **El detalle:** Dos consumidores de plataformas distintas compitiendo en la misma cola es
además la demostración de que la deduplicación en la base no depende del lenguaje.

---

## 09 · Tópicos con Kafka

### Preguntas

### 1. 🟢 ¿Por qué `OrderCreated` nace en `Order.place` y no lo construye `CreateOrder` después de guardar?

⏱️ **30 segundos:** Porque el hecho es del dominio: "se creó un pedido con este total" lo sabe el
agregado en el momento en que lo decide. El caso de uso solo lo recoge (`pullEvents`) y lo deja en
la outbox. Es el mismo patrón que `cancel` en el taller 03.

🗣️ **2 minutos:** Si lo construyera `CreateOrder`, el caso de uso tendría que repetir lo que el
agregado ya sabe (id, cliente, total) y cualquier otro camino que creara pedidos (un lote, otro
adaptador) tendría que acordarse de emitirlo. En el agregado, no hay forma de crear un pedido sin
el hecho. Es 02/07: los eventos los emite quien cambia de estado.

🔬 **El detalle:** El `eventId` se genera en el agregado y viaja con el hecho desde el primer
segundo; nunca se regenera por reintento. Toda la deduplicación posterior depende de eso.

### 2. 🟢 ¿Qué garantiza la outbox en este taller y qué no?

⏱️ **30 segundos:** Garantiza que si el pedido se confirmó, el hecho se publicará (están en la
misma transacción), y que se publicará al menos una vez. No garantiza una sola vez ni un plazo:
el dispatcher puede repetir y tarda lo que tarde su ronda.

🗣️ **2 minutos:** "Al menos una vez" nace de `publish` → `markPublished`: una caída entre los dos
republica el mismo `eventId`. Por eso el registro lleva el `eventId` y los consumidores
deduplican. La outbox resuelve el problema de "escribir en la base y publicar" sin XA; el resto
es responsabilidad del que consume.

🔬 **El detalle:** El dispatcher no es concurrente (un `@Scheduled` con `fixedDelay`); con dos
instancias del backend, las dos rondas pueden tomar el mismo lote y publicarlo dos veces. Sigue
siendo correcto por la deduplicación; el ejercicio 7 mira cómo evitarlo en el productor.

### 3. 🟢 ¿Por qué hay dos grupos de consumidores y no uno que haga las dos cosas?

⏱️ **30 segundos:** Porque son dos efectos con vidas distintas: notificar es un efecto externo que
no se repite; proyectar es un modelo derivado que se reconstruye. Con grupos separados, cada uno
avanza, falla y se reajusta por su cuenta.

🗣️ **2 minutos:** El `rebuild` del taller reajusta `hex-orders-summary` al offset 0 y
`hex-notifications` no reprocesa nada: si fueran un solo grupo, reconstruir la proyección
reenviaría notificaciones (o habría que filtrarlas). Añadir un tercer consumidor mañana es un
grupo más, sin tocar los dos que hay. Un tópico se consume por grupo, no por tópico.

🔬 **El detalle:** Los dos listeners viven en la misma clase por comodidad del taller; en un
sistema real serían servicios distintos, y eso es precisamente lo que el grupo permite.

### 4. 🟢 ¿Qué decide la partición de un registro y qué consecuencia tiene para el orden?

⏱️ **30 segundos:** La clave: `hash(orderId) % particiones`. Todos los hechos de un pedido caen en
la misma partición y se leen en el orden en que se escribieron; entre pedidos distintos no hay
orden.

🗣️ **2 minutos:** Kafka solo promete orden dentro de una partición. Elegir la clave es elegir qué
orden importa: aquí, el de un pedido (creado antes que cancelado). Sin clave, el particionador
reparte como quiera y `OrderCancelled` puede adelantar a `OrderCreated`; con la clave equivocada
(por ejemplo, el cliente), el paralelismo se concentra y el orden que importa sigue sin estar
garantizado si un pedido cambia de cliente... que no cambia, pero es el tipo de pregunta.

🔬 **El detalle:** Cambiar el número de particiones cambia el `hash % n` y rompe la co-ubicación
de las claves ya escritas: por eso es una decisión de contrato.

### 5. 🟢 ¿En qué momento exacto se confirma el offset en `OrdersEventsConsumers` y por qué ahí?

⏱️ **30 segundos:** En `ack.acknowledge()`, después de que el caso de uso devolvió: el efecto
está confirmado en PostgreSQL. `ack-mode=manual_immediate` hace que ese `acknowledge` sea un
commit síncrono del offset.

🗣️ **2 minutos:** Confirmar antes del efecto sería "at most once": una caída después del commit
y antes del efecto pierde el hecho. Confirmar después es "at least once": una caída entre efecto
y commit repite el hecho, y la deduplicación lo absorbe. El taller elige lo segundo porque perder
un hecho no se arregla y repetirlo sí.

🔬 **El detalle:** `manual` (sin `immediate`) acumularía los acks y los confirmaría al terminar
el `poll`; funciona igual para este caso pero ensancha la ventana.

### 6. 🟡 Describe la ventana entre "aplicado" y "offset confirmado" y qué la absorbe. Compárala con la ventana commit/ACK del taller 08.

⏱️ **30 segundos:** Efecto en la base → (ventana) → commit del offset. Si el proceso cae en la
ventana, Kafka vuelve a entregar desde el último offset confirmado; `applied_events` reconoce el
`eventId` y no aplica. Es exactamente commit → (ventana) → ACK del taller 08, con el offset en el
papel del ACK y `applied_events` en el de `idempotency_keys`.

🗣️ **2 minutos:** La estructura es la misma porque el problema es el mismo: dos sistemas, dos
confirmaciones, sin transacción distribuida. La diferencia es de mecanismo: la cola olvida el
mensaje al confirmarlo; el log lo conserva y el consumidor solo mueve un puntero. Por eso en Kafka
la "re-entrega" es simplemente volver a leer desde el offset, y por eso reconstruir una proyección
es posible y en una cola no.

🔬 **El detalle:** En el taller 08 la re-entrega fue casi inmediata; aquí tardó 45 segundos
porque el consumidor muerto retenía la partición (pregunta 8). La garantía es la misma; la
latencia, no.

### 7. 🟡 ¿Por qué `applied_events` tiene la proyección como parte de la clave?

⏱️ **30 segundos:** Porque el mismo `eventId` lo aplica cada proyección por su cuenta: que
`orders_summary` lo haya aplicado no dice nada de una proyección futura `daily_totals`. La clave
es (proyección, evento).

🗣️ **2 minutos:** Es una tabla compartida por diseño: cualquier consumidor nuevo deduplica igual
sin crear su propia tabla. Y el `rebuild` borra solo las filas de su proyección (`WHERE projection
= 'orders_summary'`), lo que permite reconstruir una sin tocar las demás.

🔬 **El detalle:** `INSERT ... ON CONFLICT DO NOTHING` devolviendo filas afectadas es atómico
frente a dos consumidores aplicando el mismo hecho a la vez: solo uno escribe 1.

### 8. 🟡 Tras el `halt`, el consumidor nuevo tardó 45 segundos en recibir la partición. ¿Por qué, y qué dos parámetros lo gobiernan?

⏱️ **30 segundos:** Porque un `halt` no envía `LeaveGroup`: el broker sigue creyendo que el
consumidor vive hasta que deja de recibir *heartbeats* durante `session.timeout.ms` (45 s por
defecto). `heartbeat.interval.ms` (3 s) es cada cuánto se envían.

🗣️ **2 minutos:** Mientras tanto, la partición sigue asignada a un muerto: el lag crece y nadie
consume. Un cierre limpio (`Ctrl+C`) envía `LeaveGroup` y el *rebalance* es inmediato. En
producción se ajusta el timeout al tiempo que se tolera sin consumir, sabiendo que bajarlo mucho
provoca *rebalances* falsos en una pausa de GC o una red lenta (ejercicio 5).

🔬 **El detalle:** Hay un tercer plazo: `max.poll.interval.ms` (5 min). Un consumidor vivo que no
llama a `poll` a tiempo (un caso de uso lento) también es expulsado, y esa es la causa más común
de *rebalances* inesperados.

### 9. 🟡 ¿Por qué `PublishPendingEvents` espera con `.get()` la confirmación del broker antes de `markPublished`?

⏱️ **30 segundos:** Porque `send` es asíncrono: devuelve antes de que el broker haya escrito el
registro. Marcar la fila como publicada sin esperar sería creer que salió algo que quizá no salió.

🗣️ **2 minutos:** Con `acks=all` y el `get`, `markPublished` solo corre cuando el registro está
en el log. El coste es una publicación a la vez por ronda: cincuenta hechos, cincuenta esperas.
Para este taller es correcto; a volumen se agrupan envíos y se marca el lote cuando todos
confirmaron, sin perder la regla.

🔬 **El detalle:** La alternativa "marcar primero, enviar después" invierte la garantía: un hecho
marcado y no enviado se pierde para siempre. "Enviar, luego marcar" a lo sumo duplica.

### 10. 🟡 ¿Qué hace `auto-offset-reset=earliest` y qué riesgo tiene en producción?

⏱️ **30 segundos:** Cuando un grupo no tiene offset confirmado para una partición (es nuevo, o se
borró), empieza por el principio del log. Es lo que permite que `hex-orders-summary` recién
creado reconstruya la proyección entera. El riesgo: un consumidor nuevo en producción reprocesa
toda la historia retenida sin que nadie lo pidiera.

🗣️ **2 minutos:** La alternativa `latest` empieza por el final: nada de historia, y un grupo que
perdió sus offsets se salta lo que no vio. Ninguna es correcta en general: `earliest` para
proyecciones (quieren la historia), `latest` para efectos que no deben repetirse en masa. Lo
importante es decidirlo por consumidor y saber cuánta historia retiene el tópico.

🔬 **El detalle:** El `rebuild` del taller no depende de `earliest`: reajusta los offsets a 0
explícitamente. `earliest` es lo que hace que el primer arranque de un grupo nuevo también lea
desde el principio.

### 11. 🟠 La reconstrucción dio `13|7|4095.40`. Explica las dos causas y por qué la corrección fue cambiar el hecho (`OrderCancelled` con total) y no la proyección.

⏱️ **30 segundos:** Primera causa: el tópico guardaba los hechos de todas las semillas
anteriores mientras la base se había vaciado varias veces; la proyección reconstruida era fiel al
log. Segunda: `OrderCancelled` no traía el importe y la proyección lo leía de `orders`, donde esos
pedidos ya no estaban; el importe abierto solo subía.

🗣️ **2 minutos:** La primera causa es del laboratorio (`seed --kafka` alinea base y log) y del
concepto: la proyección cree al log, y si el log y la base cuentan historias distintas, la
proyección cuenta la del log. La segunda es de diseño: una proyección que necesita leer otra tabla
para aplicarse no es una función del log, y por tanto no es reconstruible. Cambiar la proyección
("si no existe el pedido, ignora") sería esconder el defecto; cambiar el hecho lo elimina: ahora
`OrderCancelled` dice cuánto se cancela, y la proyección no sabe que existe `orders`.

🔬 **El detalle:** Es el mismo criterio que hace que `OrderCreated` lleve el total desde el
principio. La regla práctica: el hecho lleva todo lo que cualquier consumidor razonable necesita
sin volver a preguntar.

### 12. 🟠 Sin clave, la primera prueba no mostró desorden y la segunda (round robin) sí separó los hechos de un pedido. ¿Qué dice eso de las pruebas de propiedades de orden, y cuál es la única garantía real?

⏱️ **30 segundos:** Que "no se rompió" no prueba nada: el particionador *sticky* metió la ráfaga
en un lote y una partición por azar de tamaño. Con *round robin* los hechos de un pedido cayeron en
particiones distintas, y aun así el consumidor los aplicó bien porque el `poll` los trajo casi
juntos. La única garantía es la clave: misma clave, misma partición, mismo orden.

🗣️ **2 minutos:** El orden es una propiedad que se rompe bajo carga, con lag, con más
consumidores: justo las condiciones que una prueba corta no tiene. Por eso se razona sobre el
contrato del log y no sobre lo que se vio en tres pedidos. La provocación del taller no demuestra
el desorden; demuestra que los hechos de un pedido *pueden* separarse, y a partir de ahí el orden
es cuestión de suerte.

🔬 **El detalle:** Con concurrencia 3 en el listener (un hilo por partición), la separación se
convierte en desorden real en cuanto una partición se atrasa un milisegundo. El ejercicio 6 mira
el otro extremo: una sola partición, orden total, paralelismo cero.

### 13. 🟠 `hex-notifications` reutiliza `TableNotifier` sin cambios y la suite HTTP sigue en verde. ¿Qué frontera hizo eso posible y qué habría pasado si el `Notifier` hubiera sido "escribir en la tabla desde el dispatcher"?

⏱️ **30 segundos:** El puerto `Notifier` separó "a quién y qué se entrega" (política, en
`NotifyCustomer`) de "cómo llega el hecho hasta ahí" (transporte: outbox directa o tópico). Cambiar
el transporte fue añadir un consumidor que llama a la misma política. Si el dispatcher hubiera
escrito en la tabla, el taller habría tenido que copiar esa escritura al consumidor de Kafka, y
`07-notifications.hurl` habría sido la primera víctima.

🗣️ **2 minutos:** Es la prueba de que la frontera del taller 03 estaba en el sitio correcto: el
`Notifier` ya toleraba repeticiones (deduplicaba por `eventId`) porque la outbox era al menos una
vez; Kafka también lo es, así que no hubo nada que añadir. `NotifyCustomer` se extrajo de
`DeliverPendingPublications` para que la política tuviera un nombre y dos llamadores.

🔬 **El detalle:** Lo único que "sabe" el consumidor de Kafka es traducir el registro a un
`DomainEvent` (`EventJson.fromRecord`); a partir de ahí es el mismo código que el dispatcher de
tabla.

### 14. 🟠 El núcleo cambió (`OrderCreated`, total en `OrderCancelled`, `CreateOrder` → outbox). Argumenta que esos cambios son del dominio y no una filtración de Kafka hacia dentro.

⏱️ **30 segundos:** Ninguno nombra Kafka, tópicos, particiones ni claves. `OrderCreated` es un
hecho del negocio que faltaba; el total en `OrderCancelled` es información que el hecho ya
debería llevar (cuánto se deja de deber); dejar el hecho en la outbox es lo que `CancelOrder` ya
hacía. Kafka fue la ocasión, no la razón.

🗣️ **2 minutos:** La prueba de filtración es preguntarse si el cambio seguiría teniendo sentido
con otro transporte, o sin ninguno: un `OrderCreated` con total serviría igual a un correo, a un
informe nocturno o a un webhook. Lo que sí sería filtración: un campo `partitionKey` en el hecho,
un `Order.kafkaOffset`, o que `CreateOrder` llamara a `EventPublisher` directamente en vez de a
la outbox. ArchUnit sigue en verde: `application` no importa `org.apache.kafka` ni
`org.springframework.kafka`.

🔬 **El detalle:** `EventJson` (la forma del hecho fuera del proceso) vive en infraestructura y
no en el dominio: el dominio emite `record`s; qué JSON se escribe es del borde.

### Ejercicios

### 1. 🟢 Arranca sin `--events kafka` (transporte `table`) con `hex-kafka` arriba y corre la suite. Comprueba con `kafka groups` que ningún grupo existe y explica qué hace `@ConditionalOnProperty` en los consumidores y en `KafkaConfiguration`.

⏱️ **30 segundos:** La suite pasa igual (las notificaciones van por la tabla) y `kafka groups` no
lista `hex-notifications` ni `hex-orders-summary`: los beans con `@ConditionalOnProperty(hex.events.transport=kafka)`
no se crean, así que no hay listeners ni `NewTopic`.

🗣️ **2 minutos:** Es la forma de que un taller opcional no cueste nada a quien no lo hace: el
backend del taller 03 sigue siendo el mismo binario. `KafkaTemplate` sí existe (lo crea el
starter), pero nadie lo usa y no conecta hasta el primer `send`. El tópico tampoco se crea: lo
crea `KafkaAdmin` a partir del `NewTopic`, que no existe.

🔬 **El detalle:** El `OutboxDispatcher` recibe los dos casos de uso y elige por la propiedad;
`PublishPendingEvents` existe siempre pero no se llama.

### 2. 🟢 Cambia `spring.kafka.listener.ack-mode` a `batch` y `enable-auto-commit` a `true`, repite la provocación `crash-before-offset-commit` y pega los offsets tras la caída. Explica qué se perdió.

⏱️ **30 segundos:** Según el momento de la caída, el offset puede aparecer ya confirmado (lag 0)
aunque el consumidor cayera antes de "terminar": el commit automático corre por su cuenta cada
`auto.commit.interval.ms`. En este taller el efecto ya estaba en la base, así que no se pierde
nada visible... hasta que la caída ocurra *antes* del efecto y después del commit automático: ese
hecho no se reprocesa nunca.

🗣️ **2 minutos:** Auto commit desacopla "leído" de "aplicado". La provocación del taller no lo
muestra porque el caos está después del efecto; con el caos antes del efecto (o un fallo real
ahí), el offset avanza y la proyección se queda sin ese hecho: at most once. Manual e inmediato
tras el efecto es la única configuración con la que "at least once" es cierto.

🔬 **El detalle:** Spring desactiva `enable-auto-commit` por defecto y confirma según `AckMode`;
poner ambos a la vez es contradictorio y Spring avisa.

### 3. 🟡 Añade un tercer consumidor en un grupo `hex-audit` que escriba cada hecho en un archivo `audit.log` (un `Notifier` distinto). Comprueba que los otros dos grupos no se enteran y que `kafka groups` lo muestra desde el offset 0.

⏱️ **30 segundos:** Un `@KafkaListener(groupId = "hex-audit")` que llame a un `FileNotifier`
(o directamente escriba la línea). Al arrancar, `earliest` lo lleva al principio; `kafka groups`
muestra el nuevo grupo con lag inicial igual al tamaño del log y los otros dos sin cambios.

🗣️ **2 minutos:** Es la demostración de "un tópico, N lectores": el productor no supo que existe
un tercer consumidor, y los dos primeros tampoco. Lo que sí hay que decidir es la deduplicación:
una auditoría que registra duplicados es aceptable (y hasta deseable: muestra las re-entregas);
una que no, usa `applied_events` con `projection = 'audit'`.

🔬 **El detalle:** Si el archivo es el efecto, el offset se confirma después de `flush`: la misma
regla que con PostgreSQL.

### 4. 🟡 Escribe una prueba de `ProjectOrdersSummary` con fakes de `AppliedEvents` y `OrdersSummary`: el mismo `OrderCreated` dos veces aplica una; `OrderCreated` + `OrderCancelled` del mismo pedido deja `openAmount` en `0.00`. Explica qué anillo cubre.

⏱️ **30 segundos:** Un `AppliedEvents` con un `Set` y un `OrdersSummary` en memoria que sume y
reste; un `UnitOfWork` que ejecute sin más. Dos pruebas de diez líneas. Cubre el caso de uso
(la política de deduplicar y aplicar); no cubre el SQL ni el consumidor.

🗣️ **2 minutos:** Es el anillo interior de 04/06 para el lado de lectura: la proyección tiene
reglas (idempotencia, aritmética) que se prueban sin Kafka ni PostgreSQL. La prueba con el broker
real (la provocación del taller) cubre el otro anillo: que el offset y la transacción se ordenan
bien.

🔬 **El detalle:** Con `DomainEvent` sellado, un fake de `OrdersSummary` que haga `switch` sin
`default` falla al compilar cuando aparezca un hecho nuevo: la prueba también vigila el contrato.

### 5. 🟠 Baja `session.timeout.ms` a 10 s y `heartbeat.interval.ms` a 3 s en el consumidor, repite el `halt` y mide cuánto tarda el *rebalance*. Explica qué se paga por bajarlos demasiado.

⏱️ **30 segundos:** El *rebalance* llega en unos 10 s en vez de 45. Se paga que cualquier pausa
del consumidor mayor que el timeout (un GC largo, una red congestionada, un `poll` retrasado por un
caso de uso lento) lo expulsa del grupo aunque esté vivo: *rebalances* falsos, particiones que
cambian de mano y hechos reprocesados.

🗣️ **2 minutos:** Los tres plazos (`session.timeout.ms`, `heartbeat.interval.ms`,
`max.poll.interval.ms`) son un compromiso entre detectar caídas rápido y no confundir lentitud con
muerte. La regla habitual: `heartbeat` ≈ un tercio del `session`, y `max.poll.interval` mayor que
el peor caso de uso. Lo que se mide para decidir es el lag en el tiempo, no la latencia de un
experimento.

🔬 **El detalle:** Con el protocolo de *rebalance* cooperativo (KIP-848, `group.protocol=consumer`)
el broker gestiona la asignación y las pausas son menores; los plazos siguen existiendo.

### 6. 🟠 Configura `hex.kafka.partitions=1`, recrea el tópico y repite la provocación sin clave. ¿Hay desorden posible? ¿Qué se pierde? Relaciónalo con el *rebalance* de dos instancias.

⏱️ **30 segundos:** No: con una partición todo está ordenado, con clave o sin ella. Se pierde el
paralelismo: una segunda instancia no recibe ninguna partición y se queda de reserva. El
*rebalance* con dos instancias mostró tres particiones repartidas 2/1; con una, sería 1/0.

🗣️ **2 minutos:** Es la tensión central de Kafka: particiones = paralelismo máximo = unidades
de orden. Una partición da orden total y ningún escalado; muchas dan escalado y orden solo por
clave. La clave es lo que permite tener ambas cosas donde importan: orden dentro de cada pedido,
paralelismo entre pedidos.

🔬 **El detalle:** Recrear el tópico con otro número de particiones es exactamente lo que
`seed --kafka` hace con tres: cambiarlo en un tópico con historia reubica las claves.

### 7. 🔴 Sustituye la deduplicación por `applied_events` por el productor idempotente y transacciones de Kafka (`enable.idempotence`, `transactional.id`, `read_committed`). Explica qué cubre eso (duplicados del productor) y qué no (una re-entrega tras caída del consumidor con efecto en PostgreSQL), y por qué la tabla sigue haciendo falta.

⏱️ **30 segundos:** El productor idempotente evita que un reintento de `send` escriba dos veces
el mismo registro; las transacciones de Kafka hacen atómico "consumir de un tópico y producir en
otro". Ninguna de las dos sabe nada de PostgreSQL: una caída entre el efecto en la base y el
commit del offset sigue re-entregando, y la tabla sigue siendo lo que lo absorbe.

🗣️ **2 minutos:** "Exactly once" en Kafka es exactamente once *dentro de Kafka* (consumir →
transformar → producir). En cuanto el efecto está fuera (una base, un correo), vuelve a ser "al
menos una vez" más deduplicación en el destino. La outbox del taller ya tenía su propio duplicado
posible (`publish` sin `markPublished`), que el productor idempotente tampoco cubre porque son dos
`send` distintos con el mismo `eventId`.

🔬 **El detalle:** Lo que sí mejora el productor idempotente: los duplicados por reintento de red
dentro de un mismo `send`, que con `acks=all` y reintentos existen. Es barato y conviene; no
sustituye la tabla.

### 8. 🔥 Haz que `orders_summary` viva en MongoDB (`hex_catalog.orders_summary`) detrás del mismo puerto `OrdersSummary`, con `applied_events` en la misma colección (un documento por cliente con la lista de `eventId` aplicados). ¿Qué garantía transaccional cambia respecto a PostgreSQL y cómo la recuperas con una escritura condicional?

⏱️ **30 segundos:** En PostgreSQL, `markApplied` y `apply` van en una transacción sobre dos
tablas. En Mongo, sin transacciones multi-documento, la garantía se recupera poniendo ambas cosas
en el mismo documento y aplicándolas con un solo `updateOne` condicional: `{ _id: customerId,
applied: { $ne: eventId } }` con `$inc` de contadores y `$push` del `eventId`. Si el hecho ya
estaba, el filtro no casa y no se modifica nada.

🗣️ **2 minutos:** Es la deduplicación y el efecto en una sola operación atómica por documento:
el mismo `INSERT ... ON CONFLICT` + `UPDATE` de PostgreSQL, colapsado. El coste: la lista de
`eventId` crece con el cliente (hay que acotarla o rotarla), y el `rebuild` es borrar la colección.
El puerto `OrdersSummary` no cambia; `ProjectOrdersSummary` tampoco si la unidad de trabajo de
Mongo es "no hacer nada" y la atomicidad la da la escritura.

🔬 **El detalle:** El `matchedCount == 0` del `updateOne` es el equivalente del `rowcount == 0`
de `insertIfAbsent`: la re-entrega se detecta por la escritura que no ocurrió, no por una lectura
previa.

---

## 10 · gRPC

### Preguntas

### 1. 🟢 ¿Por qué `AuthorizePayment` no cambió al sustituir el proveedor en proceso por uno remoto?

⏱️ **30 segundos:** Porque el caso de uso habla con el puerto `PaymentGateway`
(`authorize(operationId, amount) → Payment`), y ese contrato ya contemplaba las tres respuestas
posibles: autorizado, rechazado, incierto. El adaptador gRPC devuelve las mismas tres.

🗣️ **2 minutos:** El puerto se diseñó en el taller 03 pensando en un proveedor real aunque el
primero fuera una regla en memoria: llamada fuera de la transacción, clave por intento, `PENDING`
como resultado y no como excepción. Cuando llegó la red, todo lo nuevo (plazo, metadata, códigos)
cupo en el adaptador. Es 02/04: el puerto describe la necesidad del núcleo, no la forma del
proveedor.

🔬 **El detalle:** Lo único que cambió en el sabor fue *qué bean* implementa el puerto, y lo
decide una propiedad. ArchUnit no tuvo nada que decir.

### 2. 🟢 ¿Por qué `Money` en el `.proto` es texto y no `double`?

⏱️ **30 segundos:** Porque `49.90` no existe en binario: un `double` guarda `49.89999...` y dos
sistemas que redondeen distinto discrepan en un centavo. Texto decimal con dos cifras es exacto y
es el mismo tipo que usa `openapi.yaml`.

🗣️ **2 minutos:** protobuf no tiene decimal nativo; las opciones son texto, o entero en la unidad
mínima (centavos) más moneda. El taller elige texto por coherencia con el contrato HTTP y con el
`Money` del dominio (`amountAsText`), y valida el patrón en el servidor: un importe sin dos
decimales es `INVALID_ARGUMENT`.

🔬 **El detalle:** `google.type.Money` (units + nanos) es la alternativa estándar de Google; sirve
igual, con el coste de dos conversiones más.

### 3. 🟢 ¿Qué códigos gRPC se traducen a `PENDING`, cuáles a excepción, y por qué esa línea y no otra?

⏱️ **30 segundos:** `UNAVAILABLE` y `DEADLINE_EXCEEDED` → `PENDING`: no se sabe si el proveedor
decidió. Todo lo demás (`INVALID_ARGUMENT`, `INTERNAL`, `UNKNOWN`, `UNAUTHENTICATED`) → excepción
→ 500: el contrato está roto o el sistema mal configurado, y eso no es incertidumbre.

🗣️ **2 minutos:** La línea es "¿el proveedor pudo haber ejecutado la operación?". Con
`UNAVAILABLE` (no llegó, o llegó y cayó) y `DEADLINE_EXCEEDED` (llegó y no contestó a tiempo), sí.
Con `INVALID_ARGUMENT`, no: rechazó la petición sin ejecutarla, y repetirla igual daría lo mismo.
Traducir `INVALID_ARGUMENT` a `PENDING` escondería un bug detrás de un estado de negocio.

🔬 **El detalle:** `ABORTED` y `RESOURCE_EXHAUSTED` son discutibles (reintentables según gRPC);
el taller los deja como excepción por simplicidad y el ejercicio 5 mira los reintentos.

### 4. 🟢 ¿Por qué la respuesta del proveedor no tiene un estado `PENDING`?

⏱️ **30 segundos:** Porque "no sé" no es algo que un proveedor responda: si responde, sabe. El
resultado incierto nace en el cliente cuando no hay respuesta, y por eso se modela como error
gRPC, no como valor.

🗣️ **2 minutos:** Si el proveedor pudiera responder `PENDING`, el cliente tendría dos caminos para
la misma incertidumbre (la respuesta y el error) y dos formas de resolverla. Con uno solo, la
regla es clara: respuesta → decisión; error de transporte → pendiente; error de contrato → fallo.
El `666.00` de §11 se implementa como `UNAVAILABLE` precisamente por eso.

🔬 **El detalle:** Un proveedor asíncrono real ("lo procesaré, consulta después") sí devolvería
algo parecido a pendiente, con un identificador para consultar; sería otro contrato y otro
caso de uso (ejercicio 6).

### 5. 🟢 ¿Qué hace `STATUS_UNSPECIFIED = 0` en el enum y cómo lo trata el cliente?

⏱️ **30 segundos:** En proto3 todo campo tiene valor por defecto y para un enum es el `0`. Si `0`
fuera `AUTHORIZED`, un servidor que olvidara poner el estado autorizaría cobros. `UNSPECIFIED`
hace que "no puesto" sea visible, y el cliente lo trata como error del proveedor (excepción).

🗣️ **2 minutos:** Es la convención de estilo de protobuf y de las AIP de Google: el cero es
"sin valor", nunca un valor con significado. En el `switch` del cliente, `default` lanza; un
enum con un valor nuevo que el cliente no conozca (versión más nueva del servidor) cae ahí
también, que es lo correcto: no se decide sobre lo que no se entiende.

🔬 **El detalle:** Los enums de proto3 son abiertos: el cliente recibe valores desconocidos como
`UNRECOGNIZED` en Java; por eso el `default` cubre dos casos, no uno.

### 6. 🟡 ¿Por qué el deadline se pone con `withDeadlineAfter` en cada llamada y no una vez al crear el stub?

⏱️ **30 segundos:** Porque un deadline es un instante absoluto. `stub.withDeadlineAfter(2 s)`
guardado en un campo fija "ahora + 2 s" en el momento de crear el stub; dos segundos después,
toda llamada nace vencida. Por eso se deriva un stub nuevo por llamada.

🗣️ **2 minutos:** Es el error más repetido con gRPC en Java y el más difícil de ver en pruebas
cortas (todas ocurren dentro de los dos segundos). En producción aparece como
`DEADLINE_EXCEEDED` en el 100 % de las llamadas tras el arranque. La regla: el stub base sin plazo
como campo; el plazo, en el punto de la llamada.

🔬 **El detalle:** `withDeadlineAfter` devuelve un stub nuevo (son inmutables); no muta el base.
Lo mismo con `withInterceptors`.

### 7. 🟡 La latencia de 3 s con plazo de 2 s devolvió `PENDING` en 2,17 s y el servidor dijo "the client gave up". ¿Qué hizo cada lado y qué habría pasado sin `Context.current().isCancelled()`?

⏱️ **30 segundos:** El cliente canceló la llamada a los 2 s (`DEADLINE_EXCEEDED`) y devolvió
`PENDING`; el servidor, al despertar al segundo 3, vio el contexto cancelado y no respondió. Sin
esa comprobación, habría construido y "enviado" una respuesta a una llamada que ya no existe:
trabajo perdido y, si la decisión tuviera efectos (un cobro real), un cobro que nadie recibió.

🗣️ **2 minutos:** El deadline viaja al servidor en la cabecera `grpc-timeout`; el servidor lo ve
como un `Context` que se cancela solo. Respetarlo es la mitad servidor del contrato de plazos:
no trabajar para clientes que se fueron, y sobre todo no ejecutar efectos irreversibles después
de que el cliente dejó de escuchar. En un proveedor real, la comprobación va *antes* de cobrar.

🔬 **El detalle:** El servidor guarda la decisión solo si llegó a decidir; en este caso no
decidió, y por eso un reintento con la misma `operation_id` volvería a decidir desde cero. Eso es
correcto: no hubo cobro.

### 8. 🟡 ¿Para qué viaja la clave de idempotencia en metadata si ya va en el cuerpo?

⏱️ **30 segundos:** El cuerpo la lleva para el proveedor, que decide con ella. La metadata la
lleva para todo lo que está entre los dos: un proxy que deduplique, un *rate limiter*, la traza
de observabilidad, un log de acceso. Nada de eso debería abrir el mensaje.

🗣️ **2 minutos:** Es la misma razón por la que HTTP la lleva en una cabecera (`Idempotency-Key`)
y no en el JSON: la infraestructura intermedia trabaja con cabeceras. En gRPC las cabeceras son
la metadata, y el interceptor del cliente la adjunta en cada llamada sin que el código del
adaptador la vea dos veces.

🔬 **El detalle:** En este taller nadie la lee de la metadata (el servidor usa el cuerpo); está
ahí porque el contrato la define así y el ejercicio 8 la necesita en el servidor.

### 9. 🟡 ¿Por qué el `.proto` vive en `contrato/` y los stubs no se versionan?

⏱️ **30 segundos:** Porque el `.proto` es el contrato entre dos procesos, como `openapi.yaml`
entre backend y frontend: pertenece a los dos y a ninguno. Los stubs son código derivado; se
generan en cada build con la versión de `protoc` que el BOM fija, y versionarlos sería versionar
un artefacto.

🗣️ **2 minutos:** Con el plugin de Maven, ni servidor ni cliente necesitan `protoc` instalado:
lo descarga. Si cambia el `.proto`, los dos proyectos dejan de compilar hasta que se adapten, que
es exactamente lo que un contrato debe hacer. Versionar los stubs permitiría que uno de los dos
compilara contra una versión vieja sin enterarse.

🔬 **El detalle:** En un monorepo el `.proto` compartido es un directorio; entre repositorios sería
un paquete propio (o un registro de esquemas), con versión semántica.

### 10. 🟡 Un pedido `PAYMENT_PENDING` respondió `409` a un nuevo intento de pago. ¿Es correcto? ¿Quién lo resuelve y cómo?

⏱️ **30 segundos:** Correcto: `PAYMENT_PENDING` no es pagable (`Order.isPayable` es
`CONFIRMED` o `PAYMENT_REJECTED`). Cobrar otra vez con otra clave podría cobrar dos veces. Lo
resuelve un caso de uso aparte que consulte al proveedor por `operation_id` y aplique la decisión
que exista (ejercicio 6).

🗣️ **2 minutos:** La máquina de estados del taller 03 ya distinguía "rechazado" (se puede
reintentar) de "pendiente" (no se puede, hasta saber). El proveedor remoto es la primera vez que
`PENDING` ocurre de verdad, y la regla aguanta sin cambios. La resolución necesita una capacidad
nueva del proveedor (`Lookup`) y una transición nueva del agregado (`resolvePayment`).

🔬 **El detalle:** El `Idempotent-Replay: true` con la clave original demuestra que el intento
pendiente sigue siendo "la misma operación": lo que el cliente HTTP ve al reintentar es el mismo
`PENDING`, no un cobro nuevo.

### 11. 🟠 El canal apuntó a un host inexistente y la suite falló en dos archivos pero sin ningún 500. Explica por qué eso es una degradación correcta y qué habría sido incorrecto.

⏱️ **30 segundos:** "No puedo hablar con el proveedor" es incertidumbre, no error del sistema:
cada cobro quedó `PENDING`, el resto de la API siguió sirviendo (productos, pedidos, cancelaciones
de pedidos no pagados), y ningún cliente recibió un 500 por algo que no era su culpa. Incorrecto
habría sido `REJECTED` (mentir: "no se cobró") o `500` (convertir una dependencia caída en una
caída propia).

🗣️ **2 minutos:** La suite falló donde debía: donde esperaba `AUTHORIZED` y recibió `PENDING`.
Eso es una prueba de contrato haciendo su trabajo, no un fallo del diseño. Lo notable es que la
causa fuera una clave de `yaml` y no una caída real: la traducción de códigos protege de cualquier
cosa entre los dos procesos, incluidos los errores propios. Es 04/05: degradar con un estado
honesto en vez de fallar.

🔬 **El detalle:** Un `circuit breaker` aquí cambiaría la latencia (fallar rápido tras N fallos),
no la semántica: el resultado seguiría siendo `PENDING`.

### 12. 🟠 Compara el `PaymentGateway` con un cliente HTTP al mismo proveedor: qué cambia en la traducción de errores (`problem+json` vs `Status`), en los plazos y en la idempotencia.

⏱️ **30 segundos:** Cambia la forma, no la política. Errores: `problem+json` con `code` vs
`Status` con código y `ErrorInfo`; en ambos, "no respondió" → `PENDING`, "contrato roto" →
excepción. Plazos: un timeout de cliente HTTP vs un deadline que viaja al servidor. Idempotencia:
cabecera `Idempotency-Key` vs metadata `idempotency-key`.

🗣️ **2 minutos:** La diferencia real está en el plazo: HTTP tiene timeouts de conexión y lectura
que el servidor no ve; gRPC manda el deadline en `grpc-timeout` y el servidor puede cancelar su
trabajo. Y en los errores: HTTP mezcla códigos de transporte (503) y de aplicación (422) en el
mismo número; gRPC separa el `Status` del transporte de los detalles de aplicación
(`google.rpc.Status`). El adaptador HTTP tendría una tabla 503/504/timeout → `PENDING`, 4xx →
excepción; la misma línea, otros nombres.

🔬 **El detalle:** El puerto no cambia en ninguno de los dos casos; por eso el taller pudo tener
un `DeterministicPaymentGateway`, un `GrpcPaymentGateway` y podría tener un `HttpPaymentGateway`
detrás de la misma interfaz.

### 13. 🟠 `payments-grpc` guarda las decisiones en un `ConcurrentHashMap`. ¿Qué garantía da y cuál no? ¿Qué necesitaría un proveedor real para que "misma clave, misma respuesta" sobreviva a su propio reinicio?

⏱️ **30 segundos:** Da "misma clave, misma respuesta" mientras el proceso vive y para una sola
instancia. No sobrevive a un reinicio ni se comparte entre réplicas. Un proveedor real guarda la
decisión con la clave en almacenamiento durable, en la misma transacción que el cobro, y consulta
antes de decidir: la `idempotency_keys` del taller 03, al otro lado.

🗣️ **2 minutos:** Es el mismo diseño que el backend aplica a sus clientes HTTP, visto desde el
proveedor: la clave se persiste con el efecto; si el efecto ocurrió, la clave está; si no, no. Y
con réplicas, la clave única en la base es lo que serializa dos peticiones simultáneas con la
misma `operation_id`. El `Map` del taller existe para mostrar el mecanismo sin una base más.

🔬 **El detalle:** La retención de esas claves es una decisión de contrato (24 h, 7 días): un
reintento fuera de la ventana es una operación nueva, y el contrato debe decirlo.

### 14. 🟠 Dos claves de `yaml` renombradas se ignoraron en silencio y produjeron un síntoma de red. ¿Cómo se detecta esto antes de arrancar, y qué papel juegan los metadatos de configuración y `@ConfigurationProperties` tipadas?

⏱️ **30 segundos:** Antes de arrancar: con el editor leyendo
`spring-configuration-metadata.json` (autocompletado y aviso de "propiedad desconocida"), y con
propiedades propias tipadas (`HexProperties` valida `provider` y fallaría con un valor
inexistente). Lo que Boot no hace es fallar por una clave que no existe bajo `spring.*`: la ignora.

🗣️ **2 minutos:** Las dos claves (`channels` → `channel`, `address` → `target`) son de Spring
gRPC 0.x y cambiaron al entrar en Boot 4; ninguna documentación en línea lo decía todavía y el
síntoma (`Unable to resolve host payments`) apuntaba a la red. La herramienta que lo resolvió fue
la que no engaña: los metadatos del módulo y `javap` sobre `GrpcClientProperties$Channel`. Para
las propiedades propias, el taller ya usa `record`s validados; para las de terceros, la defensa es
un arranque que compruebe lo que importa (un `HealthIndicator` del canal, o una llamada de humo).

🔬 **El detalle:** El fallo fue *doble* y el primer arreglo no bastó: corregir una clave y ver el
mismo síntoma es la señal de que el diagnóstico era incompleto, no de que la corrección era
errónea.

### Ejercicios

### 1. 🟢 Baja `hex.payment.deadline-ms` a `500` y corre la suite con el proveedor gRPC sin fallos. ¿Sigue en verde? Sube la latencia inyectada a `600` y repite. Explica qué mide cada resultado.

⏱️ **30 segundos:** Con 500 ms y sin fallos, verde: el proveedor responde en milisegundos. Con
latencia 600 > plazo 500, `05-payment` y `06-cancel` fallan porque los cobros que esperaban
`AUTHORIZED` vuelven `PENDING`. Lo primero mide el plazo contra la latencia normal; lo segundo, la
degradación cuando el proveedor se pasa.

🗣️ **2 minutos:** El plazo es una decisión de producto disfrazada de número: "cuánto espera un
cliente a que le confirmemos el pago". Demasiado corto, muchos pendientes que resolver después;
demasiado largo, hilos bloqueados y clientes esperando. Se fija midiendo el percentil alto del
proveedor y sumando margen, no adivinando.

🔬 **El detalle:** Con plazos muy cortos aparece un modo nuevo: el servidor decide *y* el cliente
ya se fue. Ahí la idempotencia del proveedor deja de ser un detalle.

### 2. 🟢 Escribe en `payments.proto` un campo `double amount_value = 3` en `Money`, regenera y manda `49.90`. Imprime lo que llega al servidor y explica por qué el contrato lo prohíbe.

⏱️ **30 segundos:** Llega `49.9` (protobuf serializa el `double` más cercano y Java lo imprime
corto), y al operar (`* 3`, `+ 0.10`) aparecen `149.70000000000002` y similares. El contrato lo
prohíbe porque dos partes que redondeen distinto discrepan en centavos, y un centavo en pagos es
un incidente.

🗣️ **2 minutos:** El problema no es la impresión, es la aritmética y la comparación: `666.00`
como `double` puede no ser igual a `666.00` calculado de otra forma, y la regla de §11 dejaría de
disparar. Texto decimal (o entero en centavos) hace que la igualdad sea igualdad.

🔬 **El detalle:** Añadir el campo no rompe a nadie (proto3 tolera campos desconocidos); por eso
un contrato necesita revisión humana además de compilar.

### 3. 🟡 Fuerza la idempotencia del proveedor: con `grpc fault none`, llama dos veces a `Authorize` con la misma `operation_id` desde una prueba contra `payments-grpc` real (un `ManagedChannel` a `localhost:19090`) y comprueba en el log "replaying previous answer". Explica qué diferencia hay entre esta prueba y la del servidor en proceso.

⏱️ **30 segundos:** La segunda llamada devuelve la misma referencia `gw-<id>` y el servidor
registra "replaying previous answer". La prueba en proceso verifica el *adaptador* (qué manda,
cómo traduce); esta verifica el *proveedor* (que cumple su parte del contrato) y el transporte
real.

🗣️ **2 minutos:** Son anillos distintos de 04/06: la primera corre en milisegundos sin nada
levantado y vive en el `mvn test` del sabor; la segunda necesita el servidor arriba y pertenece a
la suite de integración. Ninguna sustituye a la otra: el adaptador puede traducir perfecto contra
un proveedor que no deduplica, y viceversa.

🔬 **El detalle:** La prueba real se salta el backend a propósito: el `IdempotencyStore` HTTP
habría respondido antes de llegar al proveedor, y lo que se quiere probar es el proveedor.

### 4. 🟡 Añade un `ClientInterceptor` que propague un `deadline` **entrante** (de una petición gRPC de entrada, ejercicio 8) al proveedor sin ampliarlo: `min(plazo propio, plazo restante)`. Explica por qué "nunca ampliar" y qué pasa si el plazo restante ya es cero.

⏱️ **30 segundos:** `Context.current().getDeadline()` da el plazo del que nos llamó;
`withDeadline(min(propio, restante))` en la salida. Nunca ampliar porque el que espera es el
cliente original: trabajar más allá de su plazo es trabajar para nadie. Si el restante es cero o
negativo, no se llama: se devuelve `PENDING` (o `DEADLINE_EXCEEDED` hacia arriba) sin gastar una
llamada que ya está muerta.

🗣️ **2 minutos:** Es la propagación de deadlines de gRPC, y la razón por la que un deadline es
absoluto y no una duración: al cruzar servicios, la duración habría que recalcularla; el instante
se pasa tal cual. En el taller no hay entrada gRPC (ejercicio 8), así que el plazo nace en el
adaptador; con la entrada, nace en el cliente original y cada salto lo respeta.

🔬 **El detalle:** grpc-java ya propaga el deadline del `Context` automáticamente si la llamada
saliente se hace dentro del contexto de la entrante y no se pone otro; poner `min` explícito es
para acotarlo además con el propio.

### 5. 🟠 Sustituye la traducción a `PENDING` por tres reintentos inmediatos ante `UNAVAILABLE` (`withRetry` o un bucle). Corre `grpc fault unavailable` y mide cuántas llamadas recibe el proveedor por cada pago. Argumenta cuándo reintentar en el adaptador es correcto y cuándo es una tormenta.

⏱️ **30 segundos:** Tres (o cuatro) llamadas por pago, todas `UNAVAILABLE`, y el mismo `PENDING`
al final, más tarde. Reintentar en el adaptador es correcto para fallos transitorios cortos (una
conexión reciclada, un *rebalance*) con espera exponencial y tope; es una tormenta cuando el
proveedor está saturado o caído: cada cliente multiplica su carga justo cuando menos puede.

🗣️ **2 minutos:** La política de reintentos tiene tres partes: qué códigos (solo los que dicen
"no llegó a ejecutar"), cuántas veces y con qué espera, y un *circuit breaker* que deje de
intentar cuando el patrón es de caída. Y una cuarta: qué pasa después, que en este sistema ya
existe (`PENDING` y un proceso de resolución). Reintentar sin idempotencia en el proveedor sería
además cobrar dos veces; con ella (la `operation_id`), reintentar es seguro pero no gratis.

🔬 **El detalle:** gRPC tiene reintentos configurables en el *service config* del canal
(`retryPolicy`), transparentes al código; siguen necesitando que el método sea idempotente, y
solo aplican a códigos declarados.

### 6. 🟠 Implementa `ResolvePendingPayment`: un caso de uso que, para un pedido `PAYMENT_PENDING`, consulta al proveedor por `operation_id` (añade `rpc Lookup` al `.proto`) y aplica la decisión si existe. Explica qué transición nueva necesita `Order` y por qué el `operation_id` es la única llave posible.

⏱️ **30 segundos:** `Order.resolvePayment(Payment)` desde `PAYMENT_PENDING` a `PAID` o
`PAYMENT_REJECTED` (o quedarse si el proveedor tampoco sabe). `Lookup(operation_id)` devuelve la
decisión guardada o `NOT_FOUND`. El `operation_id` es la única llave porque es lo único que las
dos partes compartieron *antes* de la incertidumbre: el pedido no tiene referencia del proveedor
(no llegó) y el proveedor no tiene el id del pedido.

🗣️ **2 minutos:** Es el cierre del ciclo de `PENDING`: el taller 03 lo dejó como estado terminal
"hasta que alguien consulte", y este caso de uso es ese alguien. Lo dispara un `@Scheduled` o un
operador; la política (qué hacer con `NOT_FOUND`: reintentar el cobro con la misma clave, o dar por
no cobrado tras N horas) es de negocio y va en el caso de uso, no en el adaptador.

🔬 **El detalle:** `Lookup` con `NOT_FOUND` significa "no decidí": en ese caso volver a llamar a
`Authorize` con la misma `operation_id` es seguro por la idempotencia del proveedor; es la única
situación en que reintentar un cobro es correcto.

### 7. 🔴 Sustituye `Status.UNAVAILABLE.withDescription(...)` en el servidor por un error rico con `google.rpc.Status` y `ErrorInfo` (razón `PROVIDER_DOWN`, dominio `payments.hex`), y haz que el cliente lo lea con `StatusProto.fromThrowable`. Explica qué gana el cliente frente a un texto en `description` y cómo se mapearía a `problem+json` si el error tuviera que salir por HTTP.

⏱️ **30 segundos:** Gana un código estable y estructurado (`reason`, `domain`, `metadata`) que se
puede comparar y traducir sin analizar texto: `PROVIDER_DOWN` → `PENDING`, `AMOUNT_INVALID` →
excepción. Hacia HTTP, `ErrorInfo.reason` es el `code` de `problem+json`, `Status.code` da el
`status` (UNAVAILABLE → 503, INVALID_ARGUMENT → 400) y `metadata` los `errors[]`.

🗣️ **2 minutos:** Es AIP-193: el `Status` de transporte dice *qué clase* de fallo; los detalles
dicen *cuál*. Un cliente que decide por `description` se rompe con la primera traducción o
reformulación del mensaje. `grpc-protobuf` trae `StatusProto` para empaquetar y desempaquetar; el
coste es una dependencia de `google.rpc` en los dos lados y disciplina en las razones.

🔬 **El detalle:** El mapeo a `problem+json` es el `ProblemHandler` del taller 03 con una entrada
más: es la prueba de que los dos formatos de error expresan lo mismo con dos sintaxis.

### 8. 🔥 Entrada gRPC: expón `OrderService.CreateOrder` en el backend Java (starter de servidor) sobre el mismo `CreateOrder` que sirven HTTP y la cola, con el actor sacado de metadata `authorization: Bearer <jwt>` (el mismo `JwtDecoder`), la clave de idempotencia en metadata, y `google.rpc.Status` con `ErrorInfo.reason = INSUFFICIENT_INVENTORY` donde HTTP daría `problem+json`. Propaga el deadline entrante al proveedor de pagos (ejercicio 4). ¿Qué parte de `ProblemHandler` tuviste que duplicar y qué parte pudiste compartir?

⏱️ **30 segundos:** Duplicada: la *forma* (de `ProblemDetail` a `google.rpc.Status` + `ErrorInfo`,
de `HttpStatus` a `Status.Code`). Compartida: la *tabla* de qué excepción del núcleo es qué código
estable (`INSUFFICIENT_INVENTORY`, `PRODUCT_NOT_FOUND`, `IDEMPOTENCY_KEY_REUSED`), que conviene
extraer a una clase sin HTTP ni gRPC y que los dos traductores consulten.

🗣️ **2 minutos:** Es el tercer adaptador de entrada del mismo caso de uso (HTTP, cola, gRPC), y
cada uno repite lo mismo: autenticar, traducir la petición, llamar, traducir el resultado y los
errores. Lo que se aprende es dónde estaba la frontera mal puesta: `ProblemHandler` mezclaba la
tabla de códigos (política del borde entero) con la forma HTTP (detalle de un borde). Un
`ServerInterceptor` hace lo del middleware JMS y del filtro de Spring Security: verificar el JWT y
dejar el `Actor` en el `Context`.

🔬 **El detalle:** Con la entrada gRPC, el deadline nace en el cliente original y el adaptador de
pagos lo acota con `min`: es la única configuración en la que "nunca ampliar" tiene algo que
proteger.

---

## 11 · Lotes con Spring Batch

### Preguntas

### 1. 🟢 ¿Por qué el `ItemWriter` llama a `AdjustStock` en vez de hacer el `UPDATE` él mismo?

⏱️ **30 segundos:** Porque ajustar existencias tiene reglas (quién puede, delta distinto de
cero, nunca por debajo de cero) que no son del lote: son del negocio, y mañana las necesitará un
endpoint o una cola. En el caso de uso se escriben una vez; en el writer se copiarían.

🗣️ **2 minutos:** El lote es la cuarta puerta del mismo núcleo, y se comporta como las otras
tres: traduce (una fila → un comando), autentica (el actor del sistema), llama y traduce el
resultado (una excepción → cuarentena). Es 03/03: un job no tiene lógica de negocio porque un
job es un adaptador. Lo que Spring Batch aporta —chunk, checkpoint, skip— está todo alrededor de
la llamada, no dentro.

🔬 **El detalle:** El coste de hacerlo bien fue cero líneas extra en el writer: `adjustStock.execute(command)`
es lo único que hace.

### 2. 🟢 ¿Qué es un chunk y qué se confirma en su commit?

⏱️ **30 segundos:** Un grupo de N filas (100 aquí) que se leen, procesan y escriben dentro de una
transacción. Su commit confirma las N filas aplicadas al inventario **y** el avance del reader
(`read.count`) en el `JobRepository`, juntos.

🗣️ **2 minutos:** El chunk es la unidad de "todo o nada" del lote: una transacción corta que no
bloquea la tabla durante minutos y que deja un checkpoint cada N filas. Su tamaño es un
compromiso: más grande, menos commits y más trabajo perdido en una caída; más pequeño, al revés
(ejercicio 1). Que el checkpoint vaya en la misma transacción que las filas es lo que hace
correcto el reinicio.

🔬 **El detalle:** El writer recibe el chunk entero (`Chunk<Command>`) y lo recorre: si una fila
lanza, la transacción del chunk revierte todas y Batch pasa al *chunk scan*.

### 3. 🟢 ¿Quién es el actor de un lote y por qué el núcleo no lo trata distinto de un operador humano?

⏱️ **30 segundos:** Un operador del sistema con identidad fija (`batch@hex.local`, rol
`OPERATOR`). El núcleo aplica `requireOperator` igual: no sabe si el comando viene de un archivo o
de una persona, y no debe saberlo.

🗣️ **2 minutos:** Es la misma decisión que en la cola del taller 08: el que actúa es un sistema de
confianza (el lote lo lanzó alguien con acceso a la máquina y al archivo), y su identidad se
construye en el adaptador, no en el cuerpo de los datos. Si mañana los ajustes por lote
necesitaran otra regla ("solo hasta 1000 unidades por fila"), iría en `AdjustStock`, aplicada a
todos los actores o a un rol nuevo, nunca en el processor.

🔬 **El detalle:** La identidad fija hace el lote auditable: el ejercicio 4 guarda `actor` en cada
ajuste, y "batch@hex.local" en un registro dice de dónde salió.

### 4. 🟢 ¿Qué pasa con las 50 filas del chunk en curso cuando la JVM muere en la fila 350?

⏱️ **30 segundos:** Nada queda de ellas: la transacción del cuarto chunk (301–400) no llegó a
commit y PostgreSQL la revierte al cerrarse la conexión. El inventario queda como tras el tercer
chunk (300 filas), y el checkpoint también dice 300.

🗣️ **2 minutos:** Es la propiedad que hace posible el reinicio exacto: el estado de la base y el
del repositorio siempre coinciden en una frontera de chunk. La evidencia lo muestra:
`read_count 300, commit_count 3` y el inventario a mitad de camino. Con una transacción por fila
sería igual de correcto pero diez veces más commits; con una transacción por archivo, la caída
lo perdería todo.

🔬 **El detalle:** El `halt` ocurrió en el processor de la fila 350, es decir, con 49 filas del
chunk ya procesadas en memoria y ninguna escrita: en Batch 6 el writer recibe el chunk completo,
así que ni siquiera había llegado a la base.

### 5. 🟢 ¿Para qué sirve `<archivo>.quarantine.csv` y qué pasaría sin `skipLimit`?

⏱️ **30 segundos:** Guarda cada fila saltada con su motivo, para que quien mandó el archivo la
corrija o la explique. Sin `skipLimit`, un archivo entero corrupto se "procesaría" con éxito
apartando mil filas: un lote que no hizo nada y terminó `COMPLETED`.

🗣️ **2 minutos:** Skip sin cuarentena escrita es perder datos en silencio; skip sin límite es
aceptar un archivo roto. El límite expresa una decisión de negocio: diez filas malas en mil son
incidencias; cien son otro archivo. Pasado el límite, el step falla y el `JobRepository` lo dice.

🔬 **El detalle:** El `SkipListener` distingue `onSkipInProcess` (forma inválida) de
`onSkipInWrite` (el caso de uso rechazó); el archivo de cuarentena los mezcla porque a quien lo
lee le da igual en qué fase se detectó.

### 6. 🟡 Explica el `rollbackCount 2` y el `commitCount 10` de un lote de mil filas con dos malas.

⏱️ **30 segundos:** Diez chunks, diez commits. Dos filas malas en dos chunks distintos: cada una
hace revertir su chunk una vez (`rollbackCount 2`); Batch entonces reprocesa ese chunk fila a
fila (*chunk scan*), aparta la culpable y confirma las demás. El commit del chunk reprocesado
cuenta como el mismo commit del chunk, no como uno extra.

🗣️ **2 minutos:** La fila corrupta (500) falla en el processor: Batch la aparta sin revertir,
porque aún no había escrito nada de ese chunk... y aun así hay dos rollbacks, porque en Batch 6
el writer del chunk anterior (el de `SKU-004`) falla, revierte, y el *scan* aísla la fila. El
recuento exacto depende de dónde falle cada fila; la regla es: un rollback por chunk que falló al
escribir, ningún commit de más.

🔬 **El detalle:** Batch 6 reintenta la escritura del chunk (`Retry policy for operation
'Retryable write operation' exhausted` en el log) antes del *scan*: por eso la misma fila mala
aparece dos veces en el log antes de la cuarentena.

### 7. 🟡 ¿Por qué el `JobRepository` tiene que estar en la misma base y con el mismo gestor de transacciones que el inventario?

⏱️ **30 segundos:** Para que "las 100 filas aplicadas" y "el reader va por la 100" se confirmen en
la misma transacción. En otra base, una caída entre los dos commits dejaría filas aplicadas sin
checkpoint (se repetirían al reiniciar) o checkpoint sin filas (se saltarían).

🗣️ **2 minutos:** Es la misma razón por la que la outbox va en la base del pedido (04/03) y la
clave de idempotencia en la base del efecto: el registro de "esto ya se hizo" solo es fiable si se
escribe con el efecto. Un `JobRepository` en memoria (el "resourceless" de Batch 6) tiene la
misma pinta desde el código y ninguna de estas garantías: el lote corre, el reinicio no existe.

🔬 **El detalle:** `BatchConfiguration` pasa el `DataSource` y el `PlatformTransactionManager`
del sistema; con un `@BatchDataSource` distinto, Batch usaría dos conexiones y el argumento se
rompería.

### 8. 🟡 Tras la caída, el reinicio directo dio `JobExecutionAlreadyRunningException`. ¿Qué sabe y qué no sabe el repositorio, y quién decide?

⏱️ **30 segundos:** Sabe que hay una ejecución `STARTED` sin `end_time`. No sabe si su proceso
vive (una réplica que está en ello) o murió sin avisar (un `halt`, un `kill -9`, un nodo caído).
Decide un operador, o `JobOperator.recover`, o un supervisor con *heartbeat*: alguien que pueda
comprobar si el proceso existe.

🗣️ **2 minutos:** Es el lease: un registro que dice "esto es mío" y que solo su dueño debería
soltar. Cuando el dueño muere, el lease queda huérfano y hay que romperlo a mano o con un plazo.
Batch no pone plazo porque no puede saber cuánto dura un lote legítimo; por eso `recover` es una
acción explícita. Automatizarla sin más (ejercicio 5) reabre el problema que el lease evitaba:
dos réplicas procesando el mismo archivo.

🔬 **El detalle:** `batch recover` marca `FAILED` con un `UPDATE`; `JobOperator.recover` de Batch 6
hace lo mismo con más cuidado (steps, contexto). Ninguno comprueba si el proceso vive: eso sigue
siendo del que lo invoca.

### 9. 🟡 ¿Qué identifica un `JobInstance` y por qué `dailyClose` usa `date` como parámetro identificador?

⏱️ **30 segundos:** El nombre del job más sus parámetros identificadores. `stockAdjustment` +
`file=X` es una instancia; `dailyClose` + `date=2026-09-28` es otra. Un día se cierra una vez:
con `date` como identificador, cerrarlo dos veces es `JobInstanceAlreadyCompleteException`, no un
segundo informe.

🗣️ **2 minutos:** Los parámetros son la idempotencia del lote: definen qué es "la misma
operación". Un `timestamp` como parámetro (el truco habitual para "poder relanzar") destruye esa
protección: cada lanzamiento es una instancia nueva y el mismo archivo se aplica dos veces. Si de
verdad hay que repetir un día, es una decisión explícita: parámetro `run=2`, o borrar la
instancia.

🔬 **El detalle:** `file` es una ruta absoluta; copiar el archivo a otra ruta lo convierte en otra
instancia. Un hash del contenido como identificador sería más honesto (ejercicio 6 lo roza).

### 10. 🟡 ¿Cómo sabe la segunda ejecución que debe empezar en la línea 301?

⏱️ **30 segundos:** `FlatFileItemReader` es un `ItemStream`: en cada commit de chunk guarda
`read.count` en el `ExecutionContext` del step, que va al `JobRepository` en la misma transacción.
Al reiniciar la ejecución fallida, `open()` recibe ese contexto y salta 300 líneas antes de
empezar a leer.

🗣️ **2 minutos:** No hay código del taller que haga esto: lo pone el reader y lo confirma el
chunk. Es la razón para usar los readers de Batch y no un `BufferedReader` a mano: el reinicio
exacto viene incluido. Lo que sí es decisión del taller es que ese contexto se confirme con los
datos (pregunta 7).

🔬 **El detalle:** `read_count 700` en la segunda ejecución y no 1000: el contador es por
ejecución; el contexto restaurado dice desde dónde, no cuánto.

### 11. 🟠 `read_count 300 + 700` y el mismo inventario que un lote sin caída. Enumera las tres garantías que se combinaron para que fuera exacto y qué fallaría si faltara cada una.

⏱️ **30 segundos:** (1) Chunk = transacción: las 300 confirmadas y las 50 revertidas, sin
mitades; sin ella, filas del chunk 4 aplicadas y no contadas. (2) Checkpoint en la misma
transacción: `read.count 300` confirmado con las 300 filas; en otra base, un desfase y filas
repetidas o saltadas. (3) Reader reanudable: `open()` salta 300 líneas; sin él, la segunda
ejecución empezaría por la 1 y aplicaría 300 ajustes dos veces.

🗣️ **2 minutos:** Ninguna de las tres es "exactly once" por sí sola; juntas dan un lote que, tras
cualquier número de caídas, produce el mismo resultado que un lote sin caídas. Es el equivalente
en lotes de la idempotencia de los talleres 08 y 09, con una diferencia: aquí no se deduplica el
efecto (no hay `eventId` por fila), se reanuda la lectura. Eso solo funciona porque el archivo no
cambia entre ejecuciones; con una cola o un tópico, no se puede contar con eso y por eso se
deduplica.

🔬 **El detalle:** La línea 350 con `CRASH` se aplicó en la segunda ejecución porque el caos
estaba apagado: el marcador está en los datos, la política en la configuración. Un lote real
con una fila "que mata" sería una fila envenenada, y la respuesta sería el skip, no el reinicio.

### 12. 🟠 El modo CLI destapó que la clave JWT vivía en la configuración del filtro HTTP. ¿Por qué eso era una frontera mal puesta desde el taller 03 y por qué no se notó hasta ahora?

⏱️ **30 segundos:** Emitir tokens es una capacidad del sistema que `Login` usa a través del
puerto `TokenIssuer`; exigirlos en cada petición es del borde HTTP. Estaban en la misma clase
porque la primera vez que hicieron falta había una sola forma de arrancar. Con un segundo modo
(CLI sin servidor), lo que era del sistema se fue con lo que era del borde.

🗣️ **2 minutos:** Es una filtración de configuración, no de código: `JwtTokenIssuer` estaba en
`outbound/security` (bien), pero su `JwtEncoder` lo creaba `SecurityConfiguration` (mal). Nada lo
detectaba porque ArchUnit mira paquetes y no beans, y porque el servidor siempre arrancaba con
todo. Un segundo modo de arranque es la prueba más barata de qué configuración pertenece a qué
adaptador; conviene tenerla aunque no haga falta un lote.

🔬 **El detalle:** La corrección fue mover tres `@Bean` a `TokenConfiguration`; `Login` no cambió
porque nunca supo de dónde venía el encoder. Esa es la ventaja de haber tenido el puerto.

### 13. 🟠 Batch 6 arranca "resourceless" y Boot 4 no crea el esquema. Argumenta si eso es una mejora o un riesgo, y qué señal en la evidencia delató que el repositorio no era durable.

⏱️ **30 segundos:** Mejora: un lote sin reinicio (un informe, una carga única) ya no necesita una
base para su metadata, y el arranque es más rápido. Riesgo: un lote que sí necesita reinicio
corre igual de bien en apariencia y no se reanuda. La señal fue `BATCH_*` vacío tras un lote
`COMPLETED` con el inventario cambiado.

🗣️ **2 minutos:** El valor por defecto cambió de "durable, exige una base" a "efímero, no exige
nada"; ambos son razonables y ninguno es correcto para todos. Lo peligroso es que el fallo es
silencioso: no hay error hasta la primera caída en producción, cuando el reinicio empieza de
cero. La defensa del taller es una prueba que mira la evidencia (filas en `BATCH_STEP_EXECUTION`
tras un lote) y una configuración explícita que diga dónde vive la memoria.

🔬 **El detalle:** `@EnableJdbcJobRepository` existe para esto y no bastó frente a la
configuración de Boot; extender `JdbcDefaultBatchConfiguration` sí. Es un defecto de encaje
entre dos proyectos en el mismo ciclo de versiones, y es exactamente lo que una verificación por
evidencia atrapa y una lectura de la documentación no.

### 14. 🟠 Compara las cuatro puertas del núcleo (HTTP, cola, gRPC, lote): qué tiene cada una de autenticación, idempotencia y traducción de errores, y qué es lo único que las cuatro comparten.

⏱️ **30 segundos:** HTTP: JWT verificado por filtro, `Idempotency-Key` en cabecera,
`problem+json`. Cola: el emisor autenticado en el broker y el cliente resuelto por correo,
`operationId` como clave, respuesta `REJECTED` o redelivery. gRPC (como cliente, taller 10): la
clave en metadata y códigos de estado traducidos a `PENDING` o excepción. Lote: actor del
sistema fijo, el `JobInstance` como idempotencia del archivo entero, skip a cuarentena por fila.
Lo único que comparten: el caso de uso y sus excepciones.

🗣️ **2 minutos:** Cada puerta traduce tres cosas —quién, si ya se hizo, qué salió mal— a su
forma, y ninguna decide nada de negocio. Verlas juntas es la prueba de la arquitectura: cuatro
adaptadores de entrada de distinta naturaleza (síncrono, asíncrono, remoto, por archivo) sobre
los mismos `CreateOrder` y `AdjustStock`, con ArchUnit en verde y `git diff --stat` del núcleo
casi vacío en cada taller. Lo que se repitió entre ellas (la tabla de códigos estables) es la
única deuda visible: el ejercicio 8 del taller 10 propone extraerla.

🔬 **El detalle:** Las idempotencias son distintas porque el reintento es distinto: HTTP y cola
reintentan una operación (clave por operación); el lote reintenta un archivo (instancia por
archivo, reanudación por línea); Kafka reprocesa un log (deduplicación por evento). Mismo
problema, cuatro llaves.

### Ejercicios

### 1. 🟢 Baja `hex.batch.chunk-size` a `10`, repite el lote de mil líneas y pega `commitCount` y el tiempo del step. Súbelo a `1000` y repite. Explica qué se paga en cada extremo y qué pasa con la caída en la fila 350 en cada caso.

⏱️ **30 segundos:** Con 10: cien commits, más tiempo (cada commit escribe el checkpoint), y la
caída en la 350 pierde como mucho 9 filas. Con 1000: un commit, más rápido, y la caída lo pierde
todo: el reinicio empieza por la línea 1 y el lote es, en la práctica, una transacción larga.

🗣️ **2 minutos:** El tamaño del chunk es el precio del reinicio: cuánto trabajo se acepta repetir
frente a cuánto cuesta cada checkpoint. Se fija midiendo (filas por segundo, coste del commit) y
pensando en el peor caso (cuánto dura un lote que cae al final). Cien es un valor de laboratorio;
en producción va del orden de cientos a miles según la fila.

🔬 **El detalle:** Con chunk 1000 y dos filas malas, el *chunk scan* reprocesa 999 filas una a
una en transacciones individuales: el skip también se paga en tamaño de chunk.

### 2. 🟢 Genera un CSV con `--corrupt-at` en doce líneas distintas (edítalo a mano) y `skip-limit` en 10. Pega el estado del step y explica por qué el lote debe fallar y no "apartar y seguir".

⏱️ **30 segundos:** El step termina `FAILED` con `skipCount 10` y una `SkipLimitExceededException`
en la undécima; las filas de los chunks confirmados quedan aplicadas, el resto no. Debe fallar
porque doce filas malas en mil no son incidencias: es un archivo que el proveedor generó mal, y
aplicarlo a medias es peor que no aplicarlo.

🗣️ **2 minutos:** El límite convierte una política ("toleramos algunas filas malas") en una
decisión automática con un umbral explícito. Tras el fallo, hay dos caminos: corregir el archivo
y reiniciar (el checkpoint sigue desde donde quedó, con el archivo corregido en la misma ruta), o
pedir otro archivo. Ninguno es "subir el límite".

🔬 **El detalle:** Reiniciar con el archivo corregido en la misma ruta es legal para Batch (misma
instancia) pero peligroso si cambió el número de líneas anteriores al checkpoint: el reader
saltaría 300 líneas del archivo nuevo, no del viejo. El ejercicio 7 evita esto validando primero.

### 3. 🟡 Escribe una prueba de `AdjustStock` con el fake de inventario de `CreateOrderTest`: un customer no puede; `delta 0` se rechaza; un ajuste por debajo de cero lanza y no cambia nada. Explica qué anillo cubre y por qué no necesita Spring Batch.

⏱️ **30 segundos:** Tres pruebas de cinco líneas con `InMemoryInventory` (haciéndole lanzar
`InsufficientInventory` si el resultado es negativo) y un `UnitOfWork` que ejecute sin más. Cubre
el caso de uso: la política. No necesita Batch porque Batch es un adaptador, y el caso de uso no
sabe que existe.

🗣️ **2 minutos:** Es la misma prueba que `CreateOrderTest`: dobles fieles a los puertos, se
observa el estado, no las llamadas. Lo que Batch aporta (chunk, skip, reinicio) se prueba con
Batch (`spring-batch-test`, `JobOperatorTestUtils`), en otro anillo, contra un `JobRepository`
real o en memoria según lo que se quiera verificar.

🔬 **El detalle:** `AdjustStock` con `delta 0` lanza `IllegalArgumentException`, que el processor
nunca produce (ya lo filtra); la prueba del caso de uso vale para el día en que lo llame otro
adaptador que no filtre.

### 4. 🟡 Añade una tabla `stock_adjustments` (sku, delta, reason, actor, created_at) y un puerto `StockAdjustments.record` que `AdjustStock` llame en la misma unidad de trabajo. Comprueba que tras la caída y el reinicio hay exactamente 998 filas, y explica por qué (chunk + checkpoint).

⏱️ **30 segundos:** 998 y no más: cada fila de auditoría se escribe en la misma transacción que
el ajuste, que es la del chunk. Las 50 del chunk que murió se revirtieron con él; el reinicio las
volvió a escribir una vez. Las dos filas en cuarentena no tienen fila de auditoría porque su
transacción (el *scan* fila a fila) revirtió.

🗣️ **2 minutos:** Es la prueba de que "misma unidad de trabajo" no es una frase: el caso de uso
escribe en dos tablas dentro de `unitOfWork.run`, y el chunk las envuelve a ambas. Con la
auditoría fuera de la transacción (un log, otra base), la caída dejaría 349 filas de auditoría
para 300 ajustes.

🔬 **El detalle:** `actor` es `batch@hex.local` en las 998: la identidad fija de la pregunta 3
hecha registro.

### 5. 🟠 Sustituye `batch recover` por `JobOperator.recover` (Batch 6) expuesto como `POST /api/v1/batches/{id}/recover` para operator. Explica qué comprueba `recover` que el `UPDATE` a mano no comprueba, y por qué "declarar muerta" una ejecución es una decisión humana o de un supervisor con *heartbeat*, nunca automática sin más.

⏱️ **30 segundos:** `recover` recorre la ejecución y sus steps de forma consistente (estado, fin,
contexto), sobre cualquier repositorio (JDBC o Mongo), y falla si la ejecución no está en un
estado recuperable. El `UPDATE` a mano solo cambia dos columnas y confía en que quien lo lanza
sabe lo que hace. Ninguno de los dos comprueba si el proceso vive: eso solo lo puede saber quien
vea el proceso (una persona, o un supervisor que reciba *heartbeats*).

🗣️ **2 minutos:** Un `recover` automático al reiniciar ("si está STARTED, márcalo FAILED y sigue")
convierte el lease en decoración: dos réplicas que arranquen a la vez se declararían muertas la
una a la otra y procesarían el archivo dos veces. La versión segura es un supervisor que sepa
qué procesos existen (un orquestador de contenedores, un *heartbeat* en el `ExecutionContext`) y
que rompa el lease solo cuando el dueño lleva N minutos sin señales.

🔬 **El detalle:** Exponerlo por HTTP con `requireOperator` lo pone en la ventana operativa junto
a `/batches/{id}`: mirar y actuar en el mismo sitio.

### 6. 🟠 Ejecuta dos réplicas de verdad: lanza el mismo `batch run` en dos terminales con un segundo de diferencia y un CSV de 100 000 líneas. Pega las dos salidas. Después cambia el identificador del `JobInstance` para que sea `file` **y** `replica`, repite, y explica qué se rompió (el mismo archivo aplicado dos veces) y por qué el lease existe.

⏱️ **30 segundos:** Primera pareja: la segunda réplica muere con
`JobExecutionAlreadyRunningException` y la primera termina sola. Segunda pareja (con `replica=1` y
`replica=2` como parámetros identificadores): son dos instancias distintas, las dos corren, y el
inventario recibe cada ajuste dos veces.

🗣️ **2 minutos:** El lease existe porque el lote no es idempotente por fila: no hay `eventId`
que deduplicar; la idempotencia es del archivo entero, y la da el `JobInstance`. Añadir un
parámetro identificador "para poder lanzar en paralelo" destruye exactamente esa garantía. Si de
verdad hay que paralelizar, se particiona el archivo (Batch tiene `partitioner`) bajo la misma
instancia, no se duplica la instancia.

🔬 **El detalle:** Con 100 000 líneas, la ventana para que la segunda réplica encuentre `STARTED`
es de segundos; con mil, la primera termina antes y la segunda ve `COMPLETED`: es lo que pasó en
la evidencia del taller.

### 7. 🔴 Convierte `stockAdjustment` en un job de dos steps: el primero valida el archivo entero y escribe la cuarentena sin tocar el inventario; el segundo aplica solo lo válido. Explica qué gana (un archivo malo no ajusta nada), qué pierde (dos lecturas, dos checkpoints) y cómo cambia el reinicio tras una caída en cada step.

⏱️ **30 segundos:** Gana que un archivo con más filas malas que el límite se rechaza entero antes
de tocar nada, y que la cuarentena esté completa antes de aplicar. Pierde una lectura y un
checkpoint más, y un archivo intermedio (o una tabla) con lo válido. Una caída en el step 1 se
reanuda sin efectos (no escribió nada); una en el step 2, como ahora, desde el último chunk.

🗣️ **2 minutos:** Es la diferencia entre "apartar mientras aplico" y "decidir antes de aplicar".
La primera es más simple y tolera archivos casi buenos; la segunda es la que un negocio pide
cuando un archivo malo aplicado a medias es un incidente. El caso de uso no cambia: el step 2
sigue llamando a `AdjustStock`; lo que cambia es el adaptador, que ahora tiene dos fases.

🔬 **El detalle:** El step 1 puede validar más de lo que el processor valida hoy (SKU existentes,
suma de deltas por SKU no negativa) porque ve el archivo entero; eso sí es lógica que conviene
mover a un caso de uso `ValidateStockFile` si crece.

### 8. 🔥 Haz que `dailyClose` deje de ser un informe y cierre de verdad: un caso de uso `CloseDay` que resuelva los `PAYMENT_PENDING` del día consultando al proveedor gRPC del taller 10 (`Lookup`), aplique las decisiones con `Order.resolvePayment` y publique `OrderPaid` / `OrderPaymentRejected` en el tópico del taller 09 vía la outbox. Explica qué transacción rodea cada pedido (una por fila, no una por día) y por qué el job sigue sin lógica de negocio.

⏱️ **30 segundos:** Un chunk de pedidos pendientes (reader JDBC), un writer que por cada uno
llama a `CloseDay.resolve(orderId)`: consulta al proveedor **fuera** de la transacción, aplica la
decisión y deja el hecho en la outbox **dentro**. Una transacción por pedido (o por chunk), nunca
una por día: un día con mil pendientes no bloquea mil filas mientras espera al proveedor.

🗣️ **2 minutos:** Es el cierre de todo el bloque: el lote (11) llama a un caso de uso que usa el
puerto de pagos (10) y la outbox que publica en el tópico (09), con la misma transición del
agregado que HTTP usaría si alguien consultara a mano. El job no sabe qué es un pedido pendiente
ni qué decide el proveedor; sabe leer ids y llamar. Si mañana el cierre se dispara por un mensaje
en la cola (08), el caso de uso es el mismo.

🔬 **El detalle:** `Lookup` con `NOT_FOUND` (el proveedor nunca decidió) es la única situación en
que reintentar `Authorize` con la misma `operation_id` es correcto; `CloseDay` lo hace y, si el
proveedor sigue sin responder, deja el pedido pendiente para el cierre siguiente. Un lote que
"resuelve" por su cuenta ("si no sabemos, rechazamos") sería lógica de negocio en el adaptador y
además una mentira.

---

**Siguiente:** [mapa de los talleres](README.md) · [índice general](../README.md)
