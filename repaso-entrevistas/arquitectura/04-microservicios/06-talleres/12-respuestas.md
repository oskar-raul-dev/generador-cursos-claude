# 12 — Respuestas del bloque 06 · Talleres

Solucionario único de los once talleres. Cada enunciado está copiado **literalmente** de su taller y
cada respuesta lleva las tres capas de §8.3 de la guía: **⏱️ 30 segundos** (lo que dirías primero),
**🗣️ 2 minutos** (lo que añades cuando te dicen "cuéntame más") y **🔬 El detalle** (para estudiar).
Los ejercicios llevan una guía de solución, no el código completo: el código está en `laboratorio/`
y las salidas, en cada taller.

> **Vigencia:** 2026-09-29.

**Salto rápido:** [01](#01--el-monolito-y-su-contrato) · [02](#02--strangler-fig-con-envoy) · [03](#03--http-entre-servicios) · [04](#04--grpc) · [05](#05--resiliencia-en-tres-plataformas) · [06](#06--kafka-outbox-inbox-idempotencia-y-dlq) · [07](#07--observabilidad-de-extremo-a-extremo) · [08](#08--saga-coreografiada) · [09](#09--saga-orquestada-comparación-y-autopsia) · [10](#10--contratos-entre-servicios-y-testing) · [11](#11--consultas-entre-servicios-y-tiempo-real)

---

# 01 — El monolito y su contrato

## Preguntas

**01 → 1.** ¿Qué tres cosas fija el contrato de este taller además de las rutas? 🟢

⏱️ **30 segundos** — Cómo viaja el dinero, cómo se ven los errores y cómo se repite una operación sin
duplicarla: texto decimal, `problem+json` con un código estable, e `Idempotency-Key`.

🗣️ **2 minutos** — Las rutas dicen qué se puede pedir; esas tres convenciones dicen cómo se entiende
la respuesta. El dinero como texto evita que el cliente redondee un `double`; el `code` del
`problem+json` permite decidir sin parsear un mensaje en inglés; la clave de idempotencia hace seguro
el reintento de un cliente que no supo si su petición llegó. Las tres sobreviven a todas las
extracciones: son parte del contrato, no de la implementación.

🔬 **El detalle** — Hay una cuarta, menos visible: el pedido de otro cliente responde `404`, no `403`.
Es una decisión de contrato (no revelar existencia) que la suite afirma explícitamente, y que cualquier
servicio extraído tiene que respetar aunque su framework haga otra cosa por defecto.

**01 → 2.** ¿Por qué la suite se corre con `--jobs 1` y después de `lab.py seed`? 🟢

⏱️ **30 segundos** — Porque los archivos comparten estado: crean pedidos y consumen stock. Sembrar da
un punto de partida conocido y un solo hilo evita que dos archivos se pisen.

🗣️ **2 minutos** — La suite afirma valores absolutos (`stock == 18`) porque `hurl` no sabe restar; eso
solo es posible si se sabe de dónde se parte. Y `03-products` comprueba el stock inicial antes de que
`04-orders` lo consuma: en paralelo, el resultado dependería del orden de llegada. El precio es que la
suite tarda lo que tarda en serie, que aquí son tres segundos.

🔬 **El detalle** — La alternativa sería que cada archivo creara sus propios datos con identificadores
únicos y solo afirmara diferencias; es más robusta frente a paralelismo pero más difícil de leer, y en
un laboratorio pesa más que se lea.

**01 → 3.** ¿Qué hace el tóxico `latency` de Toxiproxy y por qué `base-url` apunta al proxy y no al simulador? 🟢

⏱️ **30 segundos** — Retrasa cada respuesta que pasa por el proxy un tiempo fijo. El monolito habla con
el proxy para que la latencia se pueda meter y quitar sin tocar ni el monolito ni el simulador.

🗣️ **2 minutos** — Toxiproxy es un proxy TCP con una API de control: cada proxy tiene un puerto de
escucha y un destino, y se le añaden "tóxicos" —latencia, corte, ancho de banda, cierre—. Si el
monolito apuntara directo al simulador, provocar la lentitud obligaría a meter un `sleep` en el código
del simulador, que es justo lo que la guía prohíbe: el fallo tiene que venir de fuera, como en
producción.

🔬 **El detalle** — `stream: downstream` significa que el retraso se aplica a los datos que vuelven del
destino, es decir, a la respuesta. Con `upstream` se retrasaría la petición. Para un timeout de lectura
da lo mismo; para ver cuándo empieza a trabajar el servidor, no.

**01 → 4.** ¿Qué significa `PAYMENT_PENDING` y por qué el pedido no pasa a rechazado? 🟡

⏱️ **30 segundos** — Que no sabemos si el cobro ocurrió: el proveedor no respondió a tiempo. Tratarlo
como rechazo liberaría un stock que quizá ya está pagado.

🗣️ **2 minutos** — En la corrida, el simulador **sí** cobró los 666,00 y respondió a los 3 s; el
monolito había dejado de escuchar a los 2 s. Un timeout no es un "no": es un "no sé". Por eso la
reserva se queda y el pago se registra como pendiente, a la espera de una conciliación o de un
reintento con la misma clave, que el proveedor reconocerá.

🔬 **El detalle** — Es el paso "pivote" de una saga de pagos: el que no se puede compensar a ciegas.
El [taller 09](09-saga-orquestada.md) lo convierte en un estado del orquestador con plazo, y la respuesta correcta al vencer el
plazo es escalar, no compensar.

**01 → 5.** La suite falla contra el mock en `02-auth` y en `03-products`. ¿Por qué eso es correcto? 🟡

⏱️ **30 segundos** — Porque un mock valida la forma del contrato, no las reglas ni el estado: acepta
cualquier contraseña y devuelve el único producto de ejemplo.

🗣️ **2 minutos** — Prism genera respuestas a partir del `openapi.yaml`: comprueba que la petición
encaja con el esquema y responde con un ejemplo. No tiene base de datos ni lógica. Que `01-health`
pase y los demás fallen en las reglas separa dos preguntas: ¿cliente y contrato hablan el mismo
idioma? (el mock lo contesta) y ¿el sistema cumple las reglas? (solo el sistema real lo contesta).

🔬 **El detalle** — Hay un tercer fallo instructivo: al crear, Prism devolvió `200` —la respuesta de
repetición idempotente— y no `201`, porque elige un ejemplo entre los `2xx` declarados sin saber si ya
vio esa clave. Un mock que devolviera `201` tampoco estaría "bien": estaría eligiendo otro ejemplo.

**01 → 6.** ¿Qué diferencia hay entre el timeout de lectura del `PspClient` y el `connection-timeout` del pool, y cuál de los dos disparó los `500`? 🟡

⏱️ **30 segundos** — El de lectura acota cuánto espera una llamada al proveedor; el del pool, cuánto
espera una petición por una conexión a la base. Los `500` los disparó el del pool.

🗣️ **2 minutos** — Con 1,5 s de latencia y 2 s de timeout de lectura, ninguna llamada al proveedor
expiró. Lo que expiró fue la espera por conexión: cinco pagos ocupaban el pool durante 1,5 s cada uno,
y los demás —pagos y catálogo— esperaban más de 2 s. El log lo dice literalmente:
`Connection is not available, request timed out after 2003ms (total=5, active=5, idle=0, waiting=10)`.

🔬 **El detalle** — Los `500` de los pagos llegaron a los 2,03 s y **nunca alcanzaron al proveedor**:
no hay cobro que conciliar. Los `PAID` tardaron 3,1 s, dos tandas de 1,5 s. Esa diferencia de
latencias en la salida de `storm` es la firma del agotamiento de pool.

**01 → 7.** ¿Por qué cae el catálogo si no llama al proveedor de pago? 🟡

⏱️ **30 segundos** — Porque comparte el pool de conexiones con el pago. Los pagos lo retienen
esperando al proveedor, y el catálogo se queda sin conexión.

🗣️ **2 minutos** — Es la forma más común de fallo en cascada dentro de un proceso: un recurso finito
compartido —pool de base, hilos del servidor, conexiones HTTP salientes— convierte la lentitud de una
dependencia en la caída de funcionalidades que no la usan. La corrección de fondo es no retener el
recurso mientras se espera a un tercero; la de contención es separarlo por dependencia (bulkhead).

🔬 **El detalle** — Partir en servicios también separa los pools, y ese es uno de los argumentos
honestos a favor de extraer `payments`: no el tamaño del código, sino que su dependencia lenta deje de
compartir recursos con el catálogo. Pero dentro del monolito se consigue lo mismo con dos pools o
sacando la llamada de la transacción, y eso hay que decirlo.

**01 → 8.** ¿Qué te da Go por defecto en el pool de `database/sql` y en qué cambia el síntoma respecto de Java? 🟡

⏱️ **30 segundos** — Un pool sin límite de conexiones abiertas. El servicio no se queda sin
conexiones: abre tantas como necesite hasta agotar las del servidor PostgreSQL.

🗣️ **2 minutos** — En Java el límite está en el pool (HikariCP, diez por defecto) y el síntoma aparece
en tu servicio: esperas y `500` propios. En Go, con `SetMaxOpenConns(0)`, el síntoma aparece en el
servidor de base de datos: `too many clients`, y lo sufren **todos** los servicios que comparten ese
servidor. Es peor, porque el que falla no es el que causó el problema.

🔬 **El detalle** — Por eso en Go se fija siempre `SetMaxOpenConns`, `SetMaxIdleConns` y
`SetConnMaxLifetime`, y el `context.Context` con plazo en cada consulta hace el papel del
`connection-timeout`: la espera por conexión respeta el deadline del contexto.

**01 → 9.** Con el pool en 20, veinte pagos salen bien. ¿Qué dato de esa corrida dice que el problema sigue ahí? 🟠

⏱️ **30 segundos** — Que el catálogo tardó 1,44 s en responder: estuvo esperando conexión, solo que
menos de 2 s.

🗣️ **2 minutos** — Un sondeo de catálogo normal tarda 10–20 ms. 1,44 s es tiempo de cola en el pool,
por debajo del umbral de error. Con sesenta pedidos el umbral se cruza y vuelven los `500`. El pool
más grande compró margen, no corrección; y cuesta conexiones del servidor, que es un recurso
compartido por todos los servicios.

🔬 **El detalle** — En producción este es el patrón de "latencia que sube antes de la caída": el p99
del catálogo empeora semanas antes de que alguien vea un `500`. Mirar la métrica de conexiones
pendientes del pool (`hikaricp.connections.pending`) lo delata antes que los errores.

**01 → 10.** Propón dos correcciones al defecto de `PaymentService.pay` y di qué cuesta cada una. 🟠

⏱️ **30 segundos** — Sacar la llamada de la transacción, o darle al pago su propio pool. La primera
arregla la causa; la segunda contiene el daño.

🗣️ **2 minutos** — **Fuera de la transacción:** registrar el intento (`PAYMENT_PENDING`) y hacer
commit, llamar al proveedor sin conexión tomada, y registrar el resultado en otra transacción. Cuesta
una ventana en la que el pedido está pendiente y el cobro pudo ocurrir, que hay que conciliar; y
perder el bloqueo de fila durante la llamada, así que la cancelación concurrente necesita otra regla.
**Pool propio:** dos `DataSource`, uno para pagos. Cuesta configuración y conexiones, y los pagos
siguen cayendo entre ellos, pero el catálogo ya no.

🔬 **El detalle** — Hay una tercera, que es la del bloque: extraer `payments` y hablarle por HTTP con
timeout y circuit breaker (talleres 03 y 05). No sustituye a la primera: el servicio extraído tiene
que hacer lo mismo con su propia base.

**01 → 11.** El monolito respondía `500` cuando el simulador devolvía `400`. ¿Qué debería responder y por qué? 🟠

⏱️ **30 segundos** — Un `502 Bad Gateway`, o un `500` con un código propio que diga "fallo del
proveedor", nunca un `400`: el cliente no hizo nada mal.

🗣️ **2 minutos** — Un `4xx` del tercero significa que **nosotros** le hablamos mal; reenviarlo al
cliente le echaría la culpa de algo que no puede corregir. Tampoco es un `500` genérico: hay que
distinguir "el proveedor dijo que no" (negocio: `PAYMENT_REJECTED`), "el proveedor no entiende
nuestra petición" (bug nuestro: alerta) y "el proveedor no respondió" (incierto: `PAYMENT_PENDING`).

🔬 **El detalle** — Lo que no hay que hacer es reintentar un `4xx`: no va a cambiar. El
[taller 03](03-http-entre-servicios.md) añade esa clasificación al cliente de `payments`: reintenta
timeouts, fallos de conexión y `5xx`, y no reintenta los `4xx` ni los cuenta como fallo para el
circuit breaker.

**01 → 12.** ¿Qué parte de este monolito extraerías primero, y qué argumento de este taller usarías para defenderlo? 🟠

⏱️ **30 segundos** — Pagos, porque su dependencia lenta tumba al resto; o inventario, porque su frontera
es la más clara. Este taller da el argumento para pagos.

🗣️ **2 minutos** — La serie extrae primero `inventory` (frontera clara, el `JOIN` que más duele) y
después `payments`. Defender `payments` primero con este taller es legítimo: hay un incidente
reproducido que muestra que su dependencia comparte recursos con todo lo demás. Pero hay que decir
también que ese incidente se corrige sin extraer nada; la extracción se justifica cuando además hay
equipo propio, cumplimiento o ritmo de cambio distinto.

🔬 **El detalle** — Lo que no vale como argumento es "el monolito es grande". El criterio de
[`01/03`](../01-fundamentos-y-descomposicion/03-el-camino-desde-el-monolito.md) es valor de negocio,
frontera y riesgo; el tamaño no aparece.

**01 → 13.** Dibuja la cadena de fallo de §7 y marca dónde pondrías un bulkhead, un timeout y un circuit breaker. 🔴

⏱️ **30 segundos** — Proveedor lento → pagos retienen conexiones → pool agotado → catálogo sin
conexión. El bulkhead va en el pool, el timeout en la llamada, y el circuit breaker delante del
proveedor.

🗣️ **2 minutos** —

```text
psp lento
   │ ← circuit breaker: tras N fallos, no llamar; responder 503 en ms (no se llamó: seguro que no cobró)
   ▼
PaymentService.pay retiene la conexión
   │ ← timeout de lectura ajustado al p99 del proveedor (ya existe: 2 s)
   │ ← la corrección de fondo: la llamada FUERA de @Transactional
   ▼
pool compartido agotado
   │ ← bulkhead: pool propio para pagos, o límite de pagos concurrentes
   ▼
catálogo sin conexión → 500
```

🔬 **El detalle** — El orden importa: el timeout solo acota la espera; el bulkhead evita que la espera
se contagie; el circuit breaker evita seguir pagando la espera cuando ya se sabe que el proveedor está
mal. Ninguno de los tres sustituye a sacar la llamada de la transacción, que elimina el préstamo de
conexión.

**01 → 14.** En producción ves `HikariPool-1 - Connection is not available … (total=10, active=10, idle=0, waiting=40)`. Da tres hipótesis en orden de probabilidad y qué mirarías para cada una. 🔴

⏱️ **30 segundos** — Transacciones largas por una llamada remota dentro, consultas lentas que retienen
la conexión, o fuga de conexiones que no se devuelven.

🗣️ **2 minutos** —

```text
1. Llamada remota dentro de una transacción   latencia de las dependencias en ese momento;
                                              trazas: spans HTTP dentro del span de la transacción
2. Consultas lentas o bloqueos                pg_stat_activity: estado, wait_event, duración;
                                              bloqueos (pg_locks) sobre las mismas filas
3. Fuga de conexiones                         active sube y no baja sin carga; leakDetectionThreshold
                                              de HikariCP para ver quién la tomó
```

🔬 **El detalle** — `waiting=40` con `active=10` dice que el problema es de **tiempo de retención**, no
de tamaño: agrandar el pool solo sirve si el servidor aguanta más conexiones y la causa es un pico
legítimo. Y la primera acción no es reiniciar: es capturar `pg_stat_activity` y un volcado de hilos,
porque después del reinicio la evidencia desaparece.

## Ejercicios

**01 → E1.** 🟢 Corre `lab.py storm --orders 20` con `psp-slow --latency 500` y luego con `--latency 3000`. Pega las dos salidas y explica por qué con 3 000 ms los pagos que llegan al proveedor terminan `PAYMENT_PENDING` y no `PAID`.

⏱️ **30 segundos** — Con 500 ms todo sale `PAID` en tandas rápidas; con 3 000 ms el timeout de lectura
de 2 s expira antes de la respuesta, y el monolito registra resultado incierto.

🗣️ **2 minutos** — Con 500 ms cada pago retiene la conexión medio segundo: veinte pagos en cuatro
tandas, dentro del `connection-timeout`. Con 3 000 ms cada pago que obtiene conexión la retiene 2 s y
expira: `PAYMENT_PENDING`. Los que esperan conexión más de 2 s reciben `500`. El proveedor, entretanto,
**cobró** los que le llegaron: su registro (`GET :28085/payments`) tiene cargos que el monolito marcó
como inciertos.

🔬 **El detalle** — Es el escenario más caro del taller: la conciliación tiene que cruzar el registro
del proveedor con los pagos `PENDING` por `operationId`, que es la `Idempotency-Key`. Sin esa clave
viajando al proveedor, la conciliación sería por importe y fecha, y fallaría con dos cobros iguales.

**01 → E2.** 🟢 **Orientación en código ajeno.** Encuentra, con ruta y línea, dónde se decide que un pedido de otro cliente responde `404` en vez de `403`, y dónde se traduce el error a `problem+json`.

⏱️ **30 segundos** — En `OrderService.visible`, que lanza `OrderNotFound` si el actor no es operador ni
dueño; y en `ApiErrors`, que lo convierte en `404` con `code: ORDER_NOT_FOUND`.

🗣️ **2 minutos** — `service/OrderService.java`, método estático `visible` (al final de la clase): lo
usan `get`, `cancel` y `PaymentService.pay`. La traducción está en `web/ApiErrors.java`, en el
`@ExceptionHandler` de `Errors.OrderNotFound`, que también atrapa `MethodArgumentTypeMismatchException`
para que un identificador mal formado dé el mismo `404`.

🔬 **El detalle** — La búsqueda eficaz en código ajeno no empieza por el controlador: empieza por el
código de error del contrato (`ORDER_NOT_FOUND`), que lleva directo al traductor, y de ahí a quien
lanza la excepción. Es el recorrido inverso al de la petición, y suele ser el más corto.

**01 → E3.** 🟢 Añade a `05-payment.hurl` una aserción sobre `GET /api/v1/orders/{{pending_id}}` que compruebe que el pago incierto queda registrado con `payment.status == "PENDING"`. Córrela y pega la salida.

⏱️ **30 segundos** — Una petición `GET` con el token y `jsonpath "$.payment.status" == "PENDING"`, más
`jsonpath "$.status" == "PAYMENT_PENDING"`.

🗣️ **2 minutos** — Se añade después del pago de `666.00`:

```text
GET {{base_url}}/api/v1/orders/{{pending_id}}
Authorization: Bearer {{token}}
HTTP 200
[Asserts]
jsonpath "$.status" == "PAYMENT_PENDING"
jsonpath "$.payment.status" == "PENDING"
jsonpath "$.payment.operationId" == "suite-v1-pay-0004"
```

El archivo gana una petición; si la aserción de `operationId` falla, la clave se está regenerando en algún punto del camino.

🔬 **El detalle** — La aserción sobre `operationId` es la que protege la conciliación: si una
refactorización regenerara la clave en vez de conservar la del cliente, la suite lo cazaría.

**01 → E4.** 🟡 Consulta `/actuator/metrics/hikaricp.connections.pending` durante una tormenta y describe cómo se ve el agotamiento del pool en esa métrica.

⏱️ **30 segundos** — Sube de 0 al número de peticiones que esperan conexión y vuelve a 0 cuando la
tormenta termina.

🗣️ **2 minutos** — Con el pool de 5 y veinte pagos, lo esperable es que `pending` suba hasta unos 15
(los que no caben) y baje por escalones a medida que las tandas de cinco terminan o expiran. Junto con `hikaricp.connections.active` en 5 y `idle` en 0, es la foto
exacta de la línea del log. El sondeo es un `curl` en bucle durante `storm`.

🔬 **El detalle** — En producción esta métrica es la alarma temprana: `pending > 0` sostenido indica
cola en el pool mucho antes de los `500`. Y `hikaricp.connections.usage` (histograma del tiempo de
retención) delata la causa: si el p99 de retención se parece a la latencia del proveedor, la llamada
remota está dentro de la transacción.

**01 → E5.** 🟠 Baja `connection-timeout` a 250 ms y repite la tormenta. ¿Qué mejora para el catálogo, qué empeora para los pagos y por qué no es la corrección?

⏱️ **30 segundos** — El catálogo falla antes (a 250 ms en vez de 2 s), los pagos fallan más, y la causa
sigue: solo cambias cuánto se espera antes de rendirse.

🗣️ **2 minutos** — Fallar rápido es mejor que colgar: el usuario del catálogo recibe un error en 250 ms
y los hilos del servidor se liberan antes. Pero más pagos reciben `500` sin llegar al proveedor, y el
catálogo sigue sin servir mientras dure la tormenta. Es una mitigación del síntoma (menos hilos
bloqueados), no una corrección de la causa (conexiones prestadas a un tercero).

🔬 **El detalle** — Un `connection-timeout` corto tiene sentido junto con un bulkhead: si el pago
tiene su propio pool, que falle rápido es la degradación deseada; si comparte pool con el catálogo,
fallar rápido solo acelera la caída de ambos.

**01 → E6.** 🟠 Mueve la llamada al proveedor fuera de la transacción en `PaymentService` (registrar intento → commit → llamar → registrar resultado) y repite la tormenta. Pega la salida y explica qué ventana de inconsistencia has abierto a cambio.

⏱️ **30 segundos** — La tormenta ya no agota el pool y el catálogo sigue en 200. A cambio, entre el
primer commit y el segundo el pedido está `PAYMENT_PENDING` con el cobro quizá hecho.

🗣️ **2 minutos** — Se parte `pay` en tres pasos con `TransactionTemplate`: T1 bloquea el pedido,
comprueba `CONFIRMED`, lo pasa a `PAYMENT_PENDING` y guarda el intento; sin transacción, la llamada;
T2 aplica el resultado. Cada pago retiene una conexión unos milisegundos, no 1,5 s. La ventana nueva:
si el proceso muere entre la llamada y T2, queda un pago `PENDING` con un cobro real; y una
cancelación concurrente ya no está bloqueada por la fila, así que `cancel` debe rechazar
`PAYMENT_PENDING` en curso o esperar su resolución.

🔬 **El detalle** — Esa ventana es la que resuelve la conciliación con el proveedor por
`operationId`, y la que el [taller 09](09-saga-orquestada.md) convierte en un estado con plazo. Es el precio general de salir
de una transacción: la atomicidad se sustituye por estados intermedios explícitos.

**01 → E7.** 🔴 Cambia `ProductRepository.findAllWithStock` para que no haga `JOIN` con `inventory` y el stock salga de otra consulta. Corre la suite. ¿Qué te dice el esfuerzo de este cambio sobre el taller 02?

⏱️ **30 segundos** — Que la consulta se parte en dos y hay que cruzarlas en memoria; funciona, y es la
primera pieza de *branch by abstraction* que el taller 02 necesita.

🗣️ **2 minutos** — Se leen los productos (`findAll` ordenado) y el stock (`inventory.findAllById`) y se
combinan por `sku`. La suite sigue en verde. El esfuerzo es pequeño aquí porque hay dos consultas; el
problema real es `lockForOrder`, que bloquea filas de `inventory` en la misma transacción que crea el
pedido: sin `JOIN` y sin transacción común, la reserva deja de ser atómica con el alta, y eso ya no es
refactorizar, es rediseñar.

🔬 **El detalle** — Un `JOIN` de lectura se sustituye por composición; un `JOIN` con bloqueo en una
transacción de escritura se sustituye por un protocolo (reserva con plazo, o saga). Distinguir los dos
tipos de cruce es lo que decide cuánto cuesta una extracción.

**01 → E8.** 🔥 Escribe `lab.py storm` en otra plataforma que no sea Python y compara cómo expresa cada una la concurrencia de veinte peticiones con un sondeo en paralelo.

⏱️ **30 segundos** — En Go, veinte goroutines y un `WaitGroup` más una goroutine de sondeo con un
`context` que la cancela; en Java, un `Executors.newVirtualThreadPerTaskExecutor()`.

🗣️ **2 minutos** — Python usa hilos del sistema (`ThreadPoolExecutor`), baratos aquí porque todo es
espera de red y el GIL se suelta en E/S. Go lo expresa con goroutines y el sondeo termina por
`ctx.Done()`. Java 21+ con hilos virtuales escribe código bloqueante que escala igual. La diferencia
está en cómo se detiene el sondeo: evento en Python, cancelación de contexto en Go, interrupción o
`StructuredTaskScope` en Java.

🔬 **El detalle** — El ejercicio no mide rendimiento —la herramienta espera a la red, no calcula—: mide
cuánto código cuesta expresar "N en paralelo y uno vigilando hasta que terminen", que es la forma de
casi toda prueba de carga casera.

---

# 02 — Strangler fig con Envoy

## Preguntas

**02 → 1.** ¿Por qué se pone Envoy delante antes de extraer nada, si al principio no cambia ninguna ruta? 🟢

⏱️ **30 segundos** — Porque la fachada es el sitio donde ocurrirá cada extracción. Ponerla cuando todo
va al monolito es barato y reversible; ponerla el día de la primera extracción suma dos cambios a la vez.

🗣️ **2 minutos** — El *strangler fig* necesita un punto que decida a dónde va cada petición. Si ese punto
existe y la suite pasa a través de él con el 100 % al monolito, la primera extracción es añadir una
ruta más específica: el cliente no cambia de URL ni de contrato. Además, el borde asume
responsabilidades transversales —aquí, validar el token— que dejan de repetirse en cada servicio.

🔬 **El detalle** — El coste real apareció en el taller: el gateway tiene su propio contrato de errores
(`401`, `503`, `504` en texto plano por defecto) y su propia forma de fallar (la resolución IPv6). Por
eso conviene pasar la suite a través de él **antes** de que haya una extracción que confunda las
causas.

**02 → 2.** ¿Qué hace `forward_payload_header` y quién puede usar ese encabezado? 🟢

⏱️ **30 segundos** — Copia el contenido del JWT ya verificado en un encabezado, `x-jwt-payload`, para
que un servicio de detrás lo lea sin volver a verificar la firma.

🗣️ **2 minutos** — Solo lo puede usar con seguridad un servicio al que **no se pueda llegar sin pasar por
Envoy**: si la red interna está abierta, cualquiera puede inventarse el encabezado. En este laboratorio
el monolito lo ignora y sigue verificando el `Authorization` (que Envoy reenvía con `forward: true`);
`orders` lo usa a partir del [taller 04](04-grpc.md), cuando confía en el borde.

🔬 **El detalle** — El valor va en base64url, sin firma: es una afirmación del gateway, no un token. Si
un servicio lo usa, el borde tiene que **borrar** cualquier `x-jwt-payload` que venga del cliente
antes de añadir el suyo, o se abre una suplantación trivial.

**02 → 3.** ¿Qué es *branch by abstraction* y qué papel juega `ms.inventory.mode`? 🟢

⏱️ **30 segundos** — Poner una interfaz entre el código y lo que se quiere sustituir, mover la
implementación vieja detrás, y después cambiarla por la nueva. La propiedad elige cuál se usa.

🗣️ **2 minutos** — Es la técnica para cambiar una pieza grande sin una rama larga: el código de negocio
depende de `Inventory`, detrás hay `LocalInventory` o `RemoteInventory`, y `ms.inventory.mode` activa
una u otra con `@ConditionalOnProperty`. Mientras la local esté activa, la suite demuestra que la
costura no cambió el comportamiento; activar la remota es un cambio de configuración, reversible.

🔬 **El detalle** — La propiedad es también el mecanismo de vuelta atrás: si la remota falla en
producción, se vuelve a `local`… siempre que los datos no hayan divergido. Tras la migración, volver
exige migrar en sentido inverso, y por eso el taller no deja las dos escribiendo a la vez.

**02 → 4.** ¿Por qué `release` y `consume` tienen que ser idempotentes? 🟢

⏱️ **30 segundos** — Porque se van a llamar más de una vez: en reintentos, en compensaciones después de
un timeout y en cancelaciones repetidas. La segunda llamada no puede devolver stock otra vez.

🗣️ **2 minutos** — En remoto, un `release` puede expirar habiendo ocurrido; el que llama no sabe si
repetirlo. Si es idempotente, repetir es seguro. En `inventory` lo es por construcción: solo pasan a
`RELEASED` las retenciones que siguen `HELD`, y el stock se devuelve por las filas que cambiaron.

🔬 **El detalle** — `reserve` también lo es, por referencia: la segunda retención con el mismo id de
pedido devuelve `200` sin descontar. Es lo que permitiría reintentar una reserva que expiró sin
compensar primero, aunque el monolito del taller prefiere compensar y responder `503`.

**02 → 5.** ¿Por qué hubo que quitar la FK de `inventory_reservations.order_id` a `orders`? 🟡

⏱️ **30 segundos** — Porque la reserva pasó a hacerse antes de que exista el pedido, y porque cuando las
reservas vivan en otra base esa FK no puede existir.

🗣️ **2 minutos** — Con una base y una transacción, la FK era gratis. Al separar la reserva del pedido,
la reserva se escribe primero —si no hay stock no se crea el pedido— y la FK la rechazaría. Y en el
paso siguiente las reservas se van a `ms_inventory`: una FK entre bases no existe. La integridad pasa a
ser responsabilidad del flujo (compensar si el pedido no se crea).

🔬 **El detalle** — Es un patrón general: cada FK que cruza una frontera de servicio es una dependencia
que hay que convertir en otra cosa —una referencia por identificador, un evento, una conciliación—
antes de poder partir la base. Buscarlas es el primer paso del análisis de datos de una extracción.

**02 → 6.** ¿Qué diferencia hay entre el `401` que devolvía Envoy y el del monolito, y por qué importa al cliente? 🟡

⏱️ **30 segundos** — Envoy devolvía `text/plain` con "Jwt is missing"; el monolito, `problem+json` con
`code: UNAUTHENTICATED`. Un cliente que decide por el `code` se rompe con el primero.

🗣️ **2 minutos** — El contrato dice que todo error es `problem+json`. Al mover la validación al borde, el
`401` lo genera otro componente con otro formato, y el cliente ve dos contratos según quién rechazó la
petición. `local_reply_config` reescribe las respuestas locales de Envoy con la forma del contrato, y
la suite deja de distinguir quién respondió.

🔬 **El detalle** — El *mapper* se aplica solo a respuestas generadas por Envoy; un `401` del monolito
pasa tal cual. Por eso hay que enumerar cada código que Envoy puede generar (`401`, `503`, `504`…): el
`504` apareció después, cuando un timeout lo provocó.

**02 → 7.** En la parte 3, ¿quién cometió el error: el equipo del monolito o el de inventory? 🟡

⏱️ **30 segundos** — Ninguno en su código: el error es de diseño, compartir la tabla. Cada equipo hizo
lo correcto para el suyo.

🗣️ **2 minutos** — Inventory migró "su" esquema al arrancar, que es lo normal en un servicio dueño de sus
datos. El monolito leía una columna que llevaba años ahí. Con la tabla compartida, los dos tienen
razón y el sistema cae. La decisión que falló es la de extraer sin darle al servicio una base propia.

🔬 **El detalle** — Las alternativas de "coordinar" —revisar migraciones entre equipos, un comité de
esquema— vuelven a acoplar los despliegues, que es lo que se quería romper. La salida es una sola
tabla con un solo dueño, y un contrato (la API) para todos los demás.

**02 → 8.** ¿Qué te da Go para escribir `inventory` sin router ni framework, y qué te obliga a escribir a mano? 🟡

⏱️ **30 segundos** — `net/http` con rutas por método y comodines, `context` en cada petición y apagado
ordenado con `Shutdown`. A mano: la migración, la idempotencia, los errores en `problem+json` y el
pool configurado.

🗣️ **2 minutos** — Desde Go 1.22, `ServeMux` acepta `POST /holds/{reference}/release` y `PathValue`, lo
que elimina la razón habitual para un router externo. `pgx` da pool y transacciones (`BeginFunc`). Lo
que no hay es convención: dónde van la migración, el mapeo de errores o la validación lo decide quien
escribe, y queda a la vista en ≈ 360 líneas.

🔬 **El detalle** — Esa visibilidad es la ventaja pedagógica: en el servicio Go se ve la idempotencia
(`SELECT EXISTS` por referencia), el bloqueo (`FOR UPDATE` ordenado por SKU para no interbloquear) y el
`MaxConns` explícito. En Spring las tres cosas existen y viven en anotaciones o valores por defecto.

**02 → 9.** ¿Por qué la migración se verifica operando un dato migrado y no solo contando filas? 🟡

⏱️ **30 segundos** — Porque el recuento dice que llegaron las filas, no que el sistema nuevo las
entiende. Cancelar un pedido de antes de la migración prueba el mapeo de punta a punta.

🗣️ **2 minutos** — La migración traduce: `available` a `on_hand`, `RESERVED` a `HELD`, `order_id` a
`reference`. Un error en cualquiera deja las cuentas bien y el comportamiento mal —por ejemplo, una
reserva migrada que el servicio no reconoce y no libera—. Operar el dato por el camino nuevo (cancelar
y ver el stock volver a 20) verifica la traducción, la referencia y el flujo a la vez.

🔬 **El detalle** — En producción se suman dos cosas: una comparación por muestreo entre origen y
destino antes del cambio, y un período de doble lectura (leer de ambos y comparar sin servir el
nuevo) si el riesgo lo justifica.

**02 → 10.** El timeout de 800 ms devolvió `503` en 0,8 s y dejó una retención huérfana. Explica por qué y qué cuesta la corrección. 🟠

⏱️ **30 segundos** — El tóxico retrasaba la respuesta, no la petición: inventory retuvo y respondió
tarde. El monolito no lo supo. La corrección, un `release` por la misma referencia, cuesta otra espera.

🗣️ **2 minutos** — Un timeout es un "no sé", no un "no". Para una escritura remota, hay que decidir qué
hacer con la duda; aquí, compensar: tras el `503`, el monolito llama a `release` con el id del pedido,
que es idempotente y libera si la retención existe. Cuesta latencia (1,7 s en la corrida: dos
llamadas que expiran) y no es infalible: si el `release` llegara antes que la retención, esta quedaría.

🔬 **El detalle** — La defensa completa tiene tres capas: compensación inmediata, retenciones con
caducidad (el servicio libera solas las vencidas) y conciliación periódica. El [taller 09](09-saga-orquestada.md) añade la
caducidad; es la misma lección que el pago incierto de `06/01`.

**02 → 11.** Sin timeout propio, ¿quién corta la espera y qué queda trabajando? 🟠

⏱️ **30 segundos** — La corta el timeout de la ruta de Envoy, a los 10 s, con un `504` al cliente. El
monolito sigue esperando al inventario, para nadie.

🗣️ **2 minutos** — Cada componente de la cadena tiene su plazo o no lo tiene; el efectivo es el más
corto de los que existen. Sin timeout en el monolito, el único es el del gateway, que corta la conexión
con el cliente pero no avisa al monolito. El hilo del monolito y, si hubiera transacción, su conexión
quedan ocupados hasta que el inventario responda.

🔬 **El detalle** — Es el argumento de los presupuestos de latencia decrecientes de
[`04/03`](../04-operacion-y-resiliencia/03-resiliencia-en-la-practica.md): cada salto debe tener un
plazo menor que el de quien lo llama, o el trabajo sigue cuando la respuesta ya no importa. gRPC lo
resuelve propagando el plazo con cada llamada ([taller 04](04-grpc.md)).

**02 → 12.** ¿Extraerías `catalog` en este sistema? Argumenta con lo que costó `inventory`. 🟠

⏱️ **30 segundos** — No, hoy no. `inventory` costó una costura, una migración, una compensación y un
salto de red por petición; `catalog` no tiene un motivo equivalente que lo pague.

🗣️ **2 minutos** — `inventory` se extrajo por frontera clara y porque su acceso concurrente y sus
reglas son propias. `catalog` cambia poco, lo lee todo el mundo y no tiene equipo ni requisito de
cumplimiento distinto. Extraerlo añade un salto a cada pedido y cada consulta y obliga a copiar nombre
y precio en el pedido de otra forma. Lo honesto es dejarlo dentro y reevaluar si aparece un motivo.

🔬 **El detalle** — La pregunta de entrevista "¿cuántos microservicios harías?" se contesta así: con el
coste medido de uno y el motivo concreto de cada uno. El strangler no tiene que terminar: lo que se
queda en el monolito también es una decisión.

**02 → 13.** Dibuja el flujo de `POST /api/v1/orders` en modo `remote`, con la transacción, la llamada, la compensación y los tres resultados posibles de la reserva. 🔴

⏱️ **30 segundos** — Idempotencia y catálogo locales; reserva remota sin transacción; si hay stock,
transacción corta para guardar el pedido; si falla el guardado, compensar; si la reserva no responde,
compensar y `503`.

🗣️ **2 minutos** —

```text
tx(ro): ¿Idempotency-Key ya vista? ──sí──► 200 replay
catálogo local: ¿existen los SKU? ──no──► 404
POST /holds {reference: orderId}          (sin transacción abierta)
   ├── 201/200 → tx: INSERT order + idempotency ──ok──► 201
   │                     └── falla ──► POST /holds/{id}/release ──► error original
   ├── 409 OUT_OF_STOCK → ACL → 409 INSUFFICIENT_INVENTORY (lines[i])
   └── timeout / conexión → POST /holds/{id}/release (mejor esfuerzo) ──► 503 INVENTORY_UNAVAILABLE
```

🔬 **El detalle** — Lo que el entrevistador preguntará después: ¿y si el proceso muere entre la
retención y el guardado? No hay compensación que corra: la retención queda huérfana y solo la libera la
caducidad o una conciliación. Es la ventana que cierra una saga con estado persistido ([taller 09](09-saga-orquestada.md)).

**02 → 14.** En producción, tras desplegar un servicio extraído, otro servicio empieza a fallar con `column … does not exist`. Da la causa probable, cómo la confirmas y qué cambiarías en el proceso para que no vuelva a pasar. 🔴

⏱️ **30 segundos** — Base compartida y una migración del servicio nuevo que renombró o quitó una
columna que otro leía. Se confirma en el historial de migraciones y en el log del que falla; se evita
dándole al servicio su base y prohibiendo el acceso cruzado.

🗣️ **2 minutos** —

```text
Confirmar   hora del primer error ≈ hora del despliegue; tabla de migraciones del servicio
            nuevo (qué sentencia corrió); pg_stat_statements del que falla (qué columna pide)
Mitigar     revertir la migración o añadir la columna vieja como vista/columna generada
Corregir    un dueño por tabla: base o esquema propios, credenciales separadas, sin GRANT cruzados
Proceso     inventario de lecturas cruzadas antes de extraer; migraciones expand/contract si hay
            una ventana de convivencia
```

🔬 **El detalle** — En este laboratorio la prevención está en `init-databases.sql`: cada usuario de
servicio no puede conectarse a otra base. Con ese control desde el día uno, el atajo de la parte 3 ni
siquiera habría arrancado con otro usuario que el del monolito, y alguien habría tenido que pedir
permiso por escrito.

**02 → 15.** Tu equipo va a extraer `payments` siguiendo el camino de este taller. Escribe los pasos en orden —fachada, costura, datos, primera llamada remota— y, para cada uno, la prueba que te dice que puedes pasar al siguiente. 🔴

⏱️ **30 segundos** — Fachada, costura, datos propios y llamada remota con timeout, en ese orden, y ningún
paso empieza sin la suite de contrato en verde por el camino que dejó el anterior.

🗣️ **2 minutos** — Cada paso tiene su prueba de salida:

```text
1. Fachada   Envoy ya enruta todo al monolito; solo se prepara la ruta futura
             prueba: suite v1 en verde a través de Envoy
2. Costura   interfaz Payments con LocalPayments; nadie más llama al PSP directamente
             prueba: suite v1 en verde en modo local, y el diff sin cambios fuera del pago
3. Datos     ms_payments con su usuario; migración de los pagos vivos
             prueba: operar un pago migrado (repetirlo con su clave) por el camino nuevo
4. Remoto    RemotePayments con timeout y el "no sé" decidido: PENDING, nunca rechazo
             prueba: provocación con latencia, sin doble cobro y con el pedido resoluble
```

El precio se concentra en el paso 4: un cobro que expira no se compensa como una retención; se vuelve a
preguntar con la misma clave.

🔬 **El detalle** — Lo que el entrevistador pregunta después: por qué la costura va antes que el
servicio (convierte la extracción en añadir una implementación, §8), por qué no compartir la base
"mientras tanto" (§7) y qué distingue el pago de la reserva: la reserva tiene un `release` idempotente;
el cobro incierto solo se resuelve preguntando con la clave de idempotencia, que es lo que hace el
taller 03. En producción, antes del 100 %, una ruta de Envoy por porcentaje deja ver el servicio nuevo con
tráfico real y una vuelta atrás que es cambiar un peso.

## Ejercicios

**02 → E1.** 🟢 Añade a `envoy.yaml` un *mapper* para `403` con `code: FORBIDDEN` y demuestra con `curl` que solo afecta a respuestas del propio Envoy y no a un `403` del monolito.

⏱️ **30 segundos** — Un cuarto *mapper* con `status_code_filter` en `403`. El monolito no devuelve `403`
en este contrato, así que para verlo hace falta que Envoy lo genere, por ejemplo con una regla de RBAC.

🗣️ **2 minutos** — El *mapper* se copia del de `401`. Para provocar un `403` local, se añade el filtro
`envoy.filters.http.rbac` con una política que niegue, por ejemplo, `DELETE`; `curl -X DELETE` recibe
el `problem+json`. Para el otro lado, una ruta de prueba en el monolito que devuelva `403` pasa sin
tocar: el access log muestra `via_upstream` y el cuerpo original.

🔬 **El detalle** — `%RESPONSE_CODE_DETAILS%` en el access log es la forma de saber quién generó un
código: `rbac_access_denied_matched_policy[…]` o `via_upstream`.

**02 → E2.** 🟢 **Orientación en código ajeno.** Encuentra, con ruta y línea, dónde decide el servicio `inventory` que una retención repetida no vuelve a descontar stock, y qué código HTTP devuelve en ese caso.

⏱️ **30 segundos** — `inventory/internal/store/store.go`, líneas 57–64: `SELECT EXISTS` por referencia
y `replay = true`. `internal/api/api.go`, línea 70: `status = 200` en vez de `201`.

🗣️ **2 minutos** — La comprobación ocurre dentro de la misma transacción que la retención
(`pgx.BeginFunc`), antes de bloquear filas. Si la referencia existe, la función sale sin tocar stock y
el manejador HTTP traduce `replay` a `200`.

🔬 **El detalle** — Hay una carrera: dos retenciones simultáneas con la misma referencia pueden pasar
las dos el `EXISTS`. La corrección es un índice único parcial o una restricción que haga fallar la
segunda; con un índice no único, como hoy, la idempotencia es "casi". Encontrar ese hueco es parte del
ejercicio de leer código ajeno.

**02 → E3.** 🟡 Corre `lab.py inventory --db shared` con el monolito en modo `remote` en vez de `local`. ¿Se rompe algo? ¿Por qué eso no convierte la base compartida en una buena idea?

⏱️ **30 segundos** — En `remote` el monolito ya no lee `inventory.available`, así que el renombrado no lo
rompe. Pero la tabla sigue siendo alcanzable por dos procesos con dos usuarios que pueden escribirla.

🗣️ **2 minutos** — La suite pasa porque el acceso cruzado desapareció del código, no del sistema: el
usuario del monolito sigue pudiendo leer y escribir `inventory`. El próximo informe, script o
consulta de soporte que la toque vuelve a acoplar los despliegues. Lo que garantiza la frontera es
quitar el permiso, no dejar de usarlo.

🔬 **El detalle** — Además, `ms.inventory.mode=local` sigue siendo una opción válida del monolito: basta
un cambio de configuración para volver a leer la tabla. Con base propia, esa vuelta atrás exige migrar
datos y es una decisión, no un accidente.

**02 → E4.** 🟡 Mide con `storm` (del taller 01) cuánto añade el salto de red al alta de pedidos: pedidos en modo `local` frente a `remote`, con la cifra etiquetada como reproducción local.

⏱️ **30 segundos** — Se crean los mismos pedidos en los dos modos y se comparan las latencias de alta que
imprime `storm` (o `curl -w %{time_total}` en bucle); la diferencia es del orden de milisegundos en local.

🗣️ **2 minutos** — La cifra se etiqueta: "reproducción local, un solo nodo, sin red real, Toxiproxy en
medio". Lo que mide es el coste de serializar, cruzar un proxy y un segundo proceso; lo que **no** mide
es la latencia de una red de centro de datos, la carga concurrente ni el efecto de la cola del pool.

🔬 **El detalle** — El número útil no es la media sino la cola: el p99 del alta en `remote` incluye el
p99 del inventario. Por eso el timeout de 800 ms se decide mirando el p99 del inventario, no su media.

**02 → E5.** 🟠 Da a `catalog` el mismo tratamiento hasta la parte 2 (interfaz y dos implementaciones, sin servicio). ¿Qué consultas del monolito cruzan hoy el catálogo y qué te dice eso sobre su frontera?

⏱️ **30 segundos** — Lo leen el alta de pedidos (nombre y precio para la foto de la línea) y el listado
de productos; `order_lines.sku` tiene FK a `products`. Es una frontera de lectura, sin escrituras
cruzadas.

🗣️ **2 minutos** — La interfaz `Catalog` tendría `find(skus)` y `list()`; la implementación local es
`ProductRepository`. La FK de `order_lines` a `products` habría que quitarla, como la de reservas. Que
solo haya lecturas y que el pedido ya copie nombre y precio dice que el catálogo es buen candidato
técnico… y que no gana nada saliendo.

🔬 **El detalle** — Es la evidencia que pide el ejercicio: la costura es barata y
se puede hacer ya; el servicio no se hace hasta que haya un motivo que pague el salto de red.

**02 → E6.** 🔴 Haz que las retenciones de `inventory` caduquen: columna `expires_at` y un proceso que libere las vencidas cada 30 s. Repite la prueba de la retención huérfana sin la compensación del monolito y pega la salida.

⏱️ **30 segundos** — `expires_at` al retener (ahora + N minutos), una goroutine con `time.Ticker` que
libera las `HELD` vencidas, y `commit` que borra la caducidad. La retención huérfana pasa a `RELEASED`
sola.

🗣️ **2 minutos** — El proceso hace `UPDATE holds SET status='RELEASED' WHERE status='HELD' AND
expires_at < now() RETURNING sku, qty` y devuelve el stock en la misma transacción, igual que
`Release`. Con N pequeño para la prueba (30 s), la retención de la prueba del timeout desaparece sin que
el monolito haga nada.

🔬 **El detalle** — La caducidad tiene su propio riesgo: liberar la retención de un pedido que sí se
guardó pero tardó en confirmarse. Por eso `commit` (al pagar) o una confirmación explícita al guardar el
pedido tienen que ocurrir antes del vencimiento, y el plazo se elige mirando el p99 del flujo completo.

**02 → E7.** 🔴 Añade a Envoy una ruta que mande el 10 % de `GET /api/v1/products` a una segunda instancia del monolito (`--port 28091`) y demuestra el reparto con el access log. ¿Qué tendría que ser verdad para hacer esto con el alta de pedidos?

⏱️ **30 segundos** — Una ruta con `weighted_clusters` 90/10 sobre dos clústeres. Para el alta de pedidos,
las dos instancias tendrían que compartir estado —base, idempotencia, inventario— o ser la misma
versión.

🗣️ **2 minutos** — La ruta específica va antes de la general; `%UPSTREAM_HOST%` en el log muestra el
reparto en unas decenas de peticiones. Para lecturas, basta que las dos instancias lean los mismos
datos. Para el alta, un reintento del cliente puede caer en la otra instancia: la `Idempotency-Key`
tiene que estar en un almacén común, y las dos versiones tienen que escribir datos que la otra entienda.

🔬 **El detalle** — Es el canary de [`04/06`](../04-operacion-y-resiliencia/06-despliegue-y-entrega.md) sin
orquestador: Envoy hace el reparto; lo que no hace es decidir cuándo subir del 10 % ni revertir solo.
Eso lo pone una herramienta de despliegue o una persona mirando métricas.

**02 → E8.** 🔥 Sustituye `RemoteInventory` por un cliente generado a partir de un `openapi.yaml` de `inventory` escrito por ti. ¿Dónde queda ahora la capa anticorrupción?

⏱️ **30 segundos** — El cliente generado reemplaza los `record` privados y las llamadas; la traducción
(`translate`, el mapeo a `InsufficientInventory`, el `503`) sigue siendo código propio en
`RemoteInventory`.

🗣️ **2 minutos** — El generador da tipos y métodos con el vocabulario del servicio: `HoldRequest`,
`OutOfStock`. Eso no es anticorrupción: es la forma del otro, generada. La ACL es la clase que
convierte esos tipos en los del monolito, y sigue siendo necesaria; el generador solo quita el trabajo
mecánico de serializar.

🔬 **El detalle** — El riesgo típico es dejar que los tipos generados se filtren a `OrderService` "porque
ya están ahí". En cuanto eso pasa, el vocabulario de `inventory` se extiende por el monolito y cada
cambio de su API vuelve a tocar el núcleo. La prueba de que la ACL funciona es que ningún tipo generado
aparezca fuera de su paquete.

---

# 03 — HTTP entre servicios

## Preguntas

**03 → 1.** ¿En qué tres pasos se partió `PaymentService.pay` y qué se ganó con ello? 🟢

⏱️ **30 segundos** — Transacción corta para comprobar y leer el importe, llamada al cobro sin conexión
tomada, y transacción corta para aplicar el resultado. Se ganó que un proveedor lento no retenga
conexiones de la base.

🗣️ **2 minutos** — En `06/01` la llamada al proveedor ocurría dentro de `@Transactional`: cada pago
lento retenía una conexión y el pool se vaciaba para todos. Partido en tres, cada transacción dura
milisegundos y la espera ocurre sin recursos compartidos tomados. La tormenta lo demuestra: 20 `PAID`
en 1,9 s con el mismo pool de 5 y el catálogo a 20 ms.

🔬 **El detalle** — El precio es que entre el paso 1 y el 3 el pedido no está bloqueado. El paso 3
vuelve a comprobar `CONFIRMED`; si una cancelación se coló, el cobro existe sobre un pedido cancelado y
hace falta una compensación (devolución), que es trabajo de saga.

**03 → 2.** ¿Qué excepciones reintenta `RemotePayments` y por qué no un `4xx`? 🟢

⏱️ **30 segundos** — `ResourceAccessException` (timeout o conexión) y `HttpServerErrorException`
(`5xx`). Un `4xx` significa que la petición está mal, y repetirla no la arregla.

🗣️ **2 minutos** — Se reintenta lo que puede ser transitorio o puede no haber ocurrido. Un `400` o un
`422` es un error del que llama: reintentarlo es carga inútil y retrasa el error al cliente. Además, el
breaker ignora los `4xx` (`ignoreExceptions`): no son una caída del destino y no deben abrir el
circuito.

🔬 **El detalle** — La excepción es el `409 PAYMENT_IN_PROGRESS` de `payments`: no se reintenta, pero
se interpreta como `PENDING` (otro intento con la misma clave está en curso), no como error.

**03 → 3.** ¿Qué hace `payments` cuando le llega una petición sin `Idempotency-Key`? 🟢

⏱️ **30 segundos** — Inventa una clave (`gen-…`) y trata la petición como una operación nueva. Por eso
cada reintento sin clave es un cobro nuevo.

🗣️ **2 minutos** — Es el comportamiento de muchos servicios reales: la idempotencia es opcional y, sin
clave, no hay forma de reconocer una repetición. `payments` además propaga su clave inventada al
proveedor, que tampoco puede deduplicar. El resultado de la provocación fue tres operaciones
`gen-…` distintas y tres cobros.

🔬 **El detalle** — La alternativa estricta es exigir la clave (`400` si falta), como hace el contrato
público con `IDEMPOTENCY_KEY_REQUIRED`. Para un servicio interno que cobra, es la opción defendible:
un llamador que olvida la clave descubre el error en desarrollo, no en el extracto de un cliente.

**03 → 4.** ¿Qué diferencia hay entre `503 PAYMENTS_UNAVAILABLE` y `PAYMENT_PENDING` para el cliente? 🟡

⏱️ **30 segundos** — `503` dice que es seguro que no se cobró y el pedido sigue pagable; `PAYMENT_PENDING`
dice que no se sabe si se cobró. Ante el primero se reintenta sin miedo; ante el segundo, con la misma
clave o se espera.

🗣️ **2 minutos** — El monolito solo devuelve `503` cuando no llegó a hablar con `payments` (conexión
rechazada o breaker abierto): no hay efecto posible. Con un timeout, la petición pudo llegar y cobrar,
así que se registra `PENDING`. Para el cliente, la diferencia es qué puede hacer después sin riesgo.

🔬 **El detalle** — En los dos casos el reintento con la misma `Idempotency-Key` es seguro: el `503` no
guardó nada en la tabla de idempotencia, y el `PENDING` se vuelve a preguntar. Sin clave, solo el `503`
sería seguro de repetir.

**03 → 5.** ¿Por qué `payments` registra la intención y hace commit antes de llamar al proveedor? 🟡

⏱️ **30 segundos** — Para que, si el proceso muere durante la llamada, quede una fila `IN_PROGRESS` con la
clave: un cobro que se puede conciliar, en vez de un cobro sin rastro.

🗣️ **2 minutos** — Si se llamara primero y se guardara después, una caída entre las dos cosas dejaría un
cobro en el proveedor sin ninguna fila en `payments`. Registrando antes, la fila existe; la
conciliación busca `IN_PROGRESS` antiguas y pregunta al proveedor por su `operation_id`. Además, el
índice único sobre `operation_id` hace que dos peticiones simultáneas con la misma clave no llamen dos
veces: la segunda recibe `409`.

🔬 **El detalle** — Es el mismo razonamiento que el outbox ([taller 06](06-kafka-outbox-inbox-y-dlq.md)): nunca hay que escribir en dos
sistemas sin dejar primero, en el propio, constancia de la intención.

**03 → 6.** Explica los tiempos 0,72 s, 0,13 s y 0,011 s de los tres pagos con `payments` apagado. 🟡

⏱️ **30 segundos** — El primero hizo tres intentos con backoff; el segundo abrió el breaker en su primer
intento y no pudo reintentar; el tercero ni siquiera llamó.

🗣️ **2 minutos** — Pago 1: tres conexiones rechazadas (inmediatas) más dos esperas de backoff con jitter
(102 y 578 ms) ≈ 0,72 s. Eso son tres fallos en la ventana. Pago 2: el primer intento es el cuarto
fallo, se alcanza el mínimo de 4 con un 100 % de error, el breaker se abre, y el reintento recibe
`CallNotPermittedException`: ≈ 0,13 s. Pago 3: el breaker abierto rechaza sin llamar: 11 ms.

🔬 **El detalle** — El caso intermedio muestra el efecto del orden: con el breaker dentro del reintento,
el reintento se detiene en cuanto el breaker se abre. Con el orden inverso, el breaker vería una sola
llamada por pago y tardaría más en abrir.

**03 → 7.** ¿Por qué el breaker va dentro del reintento y no fuera? 🟡

⏱️ **30 segundos** — Para que cada intento cuente como una llamada y para que, en cuanto el breaker se
abre, el reintento se detenga en vez de insistir.

🗣️ **2 minutos** — Con el breaker dentro, tres intentos fallidos son tres fallos: el circuito ve la
realidad de lo que llega al destino. Y como `CallNotPermittedException` no es reintentable, el breaker
abierto corta el bucle de reintentos. Con el breaker fuera, vería "un pago" aunque hubiera tres
llamadas, y seguiría dejando pasar reintentos contra un destino caído.

🔬 **El detalle** — Es la misma discusión de [`04/03`](../04-operacion-y-resiliencia/03-resiliencia-en-la-practica.md)
sobre el orden de `@Retry` y `@CircuitBreaker`; con decoradores programáticos el orden se lee en una
línea, y con anotaciones depende del orden de los aspectos, que Resilience4j fija por configuración.

**03 → 8.** ¿Qué te da Python asíncrono para `payments` y qué pasa con el estado de un breaker si arrancas varios workers? 🟡

⏱️ **30 segundos** — Un solo proceso atiende muchas esperas al proveedor sin un hilo por petición. Con
varios workers, cada uno tiene su propio breaker: deciden por separado.

🗣️ **2 minutos** — FastAPI con `async def`, `httpx.AsyncClient` y el pool asíncrono de psycopg hacen que
la espera al proveedor no bloquee nada: el bucle de eventos atiende otras peticiones. Pero cualquier
estado en memoria —un breaker, un contador, una caché— es por proceso. Con `uvicorn --workers 4`, un
destino caído tiene que abrir cuatro breakers, uno por worker, y cada uno ve un cuarto del tráfico.

🔬 **El detalle** — El riesgo típico es mezclar un cliente bloqueante (`requests`, un driver síncrono)
dentro de un `async def`: bloquea el bucle entero. En este servicio todo lo que espera es asíncrono, y
esa es la condición para que el modelo funcione.

**03 → 9.** La tormenta de `06/01` ya no tumba el catálogo. ¿Qué cambió exactamente, y qué no hizo falta cambiar? 🟠

⏱️ **30 segundos** — Cambió que el pago ya no retiene una conexión mientras espera al cobro. No hizo
falta cambiar ni el tamaño del pool ni el proveedor.

🗣️ **2 minutos** — Con el mismo pool de 5 y el proveedor a +1,5 s, en `06/01` salieron 10 `PAID` y 10
`500` y el catálogo cayó; ahora, 20 `PAID` en 1,9 s y el catálogo respondiendo en 20 ms. La
diferencia es quién espera con qué recurso tomado. Extraer `payments` ayudó a separar recursos, pero
el cambio decisivo es el flujo de tres pasos, que funciona igual en `--payments local`.

🔬 **El detalle** — Es la respuesta honesta a "¿por qué extrajisteis pagos?": no para arreglar la cascada
—eso se arregla en el monolito—, sino por despliegue, equipo o cumplimiento. Mezclar los dos
argumentos es la forma más común de justificar una extracción con un motivo que no la necesita.

**03 → 10.** ¿Por qué guardar un `PENDING` en la tabla de idempotencia es un error, y qué hace ahora una repetición con la misma clave? 🟠

⏱️ **30 segundos** — Porque la idempotencia repite respuestas, y un `PENDING` repetido nunca se resuelve.
Ahora una repetición sobre un `PENDING` vuelve a preguntar con la misma clave.

🗣️ **2 minutos** — La tabla guarda la respuesta para no repetir el efecto. Una respuesta firme
(`PAID`, `PAYMENT_REJECTED`) debe repetirse tal cual; un "no sé" no es un efecto, es falta de
información. Si se guarda como definitivo, el reintento del cliente —que es justo lo que traería la
información— devuelve la duda. Ahora `resolvePending` pregunta otra vez a `payments` con la misma clave
y, si hay respuesta firme, resuelve el pedido y sustituye la respuesta guardada.

🔬 **El detalle** — El error estaba en las dos capas: `payments` también repetía sus `PENDING` sin
volver a preguntar al proveedor. Cada capa de idempotencia tiene que distinguir "ya hecho" de "no sé
si hecho", y la regla vale para cualquier resultado incierto, no solo para pagos.

**03 → 11.** El breaker se abrió por una prueba de latencia y rechazó un pago ajeno. ¿Es un fallo del breaker? ¿Qué ajustarías? 🟠

⏱️ **30 segundos** — No: es su comportamiento, porque la ventana es por destino. Lo que se ajusta es el
umbral y el mínimo de llamadas, que con 4 están pensados para verlo en un laboratorio.

🗣️ **2 minutos** — Tres timeouts y un éxito son cuatro llamadas con un 75 % de fallos: con
`minimumNumberOfCalls` 4 y umbral 50 %, el breaker hizo lo que tenía que hacer. En producción, el
mínimo se calcula con el tráfico real (decenas o cientos de llamadas en la ventana), se usa ventana por
tiempo si el tráfico es irregular, y se valora abrir por llamadas lentas además de por errores.

🔬 **El detalle** — Un breaker compartido por todos los clientes del destino es lo correcto cuando el
destino está caído para todos. Si el fallo es por tipo de petición (un importe, un país), un breaker por
destino castiga a todos por unos pocos; ahí el bulkhead o un breaker por clave de negocio encajan mejor.

**03 → 12.** Tres intentos de 2,5 s más backoff son hasta 8 s. ¿Cómo encaja eso con el timeout de 10 s de Envoy y con lo que espera el cliente? 🟠

⏱️ **30 segundos** — Cabe por poco dentro de los 10 s de Envoy, pero un cliente que espere 8 s por un pago
es un cliente que ya reintentó o se fue. El presupuesto está mal repartido.

🗣️ **2 minutos** — Cada salto debe tener un plazo menor que el de quien lo llama, contando reintentos:
aquí Envoy 10 s, monolito hasta 8,4 s, `payments` 2 s hacia el proveedor. Encaja, pero con 1,6 s de
margen. Lo sano es fijar un presupuesto total para el pago (por ejemplo 4 s) y derivar de él cuántos
intentos caben, o reintentar menos en el monolito y resolver la duda después (§7).

🔬 **El detalle** — Si el plazo del cliente es menor que el tiempo de reintentos, el cliente abandona
mientras dentro se sigue reintentando: trabajo para nadie y, en un pago, más dudas que resolver. gRPC
lo resuelve propagando el plazo con cada llamada, en el encabezado `grpc-timeout`
([taller 04](04-grpc.md)).

**03 → 13.** Dibuja el recorrido de la `Idempotency-Key` desde el cliente hasta el proveedor y marca dónde se deduplica en cada salto. 🔴

⏱️ **30 segundos** — El cliente la elige; el monolito la guarda y la reenvía; `payments` la usa como
`operation_id` único y la reenvía; el proveedor deduplica por ella. Tres puntos de deduplicación.

🗣️ **2 minutos** —

```text
cliente ── Idempotency-Key: K ──► Envoy ──► monolito
                                            idempotency_keys (K, actor): respuesta guardada;
                                            PENDING → vuelve a preguntar
                                              │ Idempotency-Key: K
                                              ▼
                                          payments
                                            payments.operation_id = K UNIQUE;
                                            IN_PROGRESS → 409 · PENDING → vuelve a preguntar
                                              │ Idempotency-Key: K
                                              ▼
                                          psp-simulator: deduplica por K (repite la respuesta)
```

🔬 **El detalle** — Lo que preguntará el entrevistador: ¿y si el monolito reintenta con otra clave? Se
rompe la cadena en ese salto y vuelve el doble cobro. La clave la genera quien origina la intención
(el cliente) y nadie en medio la regenera; si un salto necesita su propia clave, la deriva de forma
determinista de la original.

**03 → 14.** En producción, un cliente reporta dos cargos por un pedido que figura `PAYMENT_PENDING`. Da tres hipótesis en orden de probabilidad y qué mirarías para cada una. 🔴

⏱️ **30 segundos** — Un reintento que no propagó la clave, dos claves distintas para el mismo pedido
(el cliente repitió con otra), o un fallo de deduplicación en `payments` por una carrera.

🗣️ **2 minutos** —

```text
1. Reintento sin clave en un salto   log de reintentos del monolito a esa hora; en payments,
                                     operation_id gen-… para el mismo order_id
2. El cliente repitió con otra clave  idempotency_keys: dos claves para el mismo pedido; el segundo
                                     pago debió dar ORDER_NOT_PAYABLE salvo que el primero
                                     quedara PAYMENT_PENDING… y ese es el hueco
3. Carrera en payments               dos filas con el mismo order_id y claves distintas creadas en
                                     el mismo segundo; el índice único es por clave, no por pedido
```

🔬 **El detalle** — La hipótesis 2 señala un hueco de diseño: el estado `PAYMENT_PENDING` no es pagable,
pero si alguien lo cambia para "dejar reintentar", dos claves pueden cobrar el mismo pedido. La defensa
de fondo es una restricción por pedido en `payments` (un solo cobro autorizado por `order_id`) y la
conciliación con el extracto del proveedor.

## Ejercicios

**03 → E1.** 🟢 Repite la provocación de §6 con `--latency 2000` en vez de 3000. ¿Cuántos cobros hay y por qué? Pega la salida.

⏱️ **30 segundos** — Uno, sin reintentos: con 2 s de latencia la respuesta llega antes de los 2,5 s del
monolito, así que no hay timeout ni reintento, con clave o sin ella.

🗣️ **2 minutos** — La provocación depende de que la latencia supere el timeout del que llama. Con 2 000 ms
y un timeout de 2 500 ms, la llamada es lenta pero termina: `PAID` en ≈ 2 s y un cobro. El doble cobro no
es una propiedad de la latencia sino de la combinación latencia > timeout + reintento sin clave.

🔬 **El detalle** — Es la razón para que el timeout del que llama se calcule desde el p99 del llamado:
demasiado corto, y cada pico de latencia se convierte en reintentos que, sin idempotencia, duplican
efectos.

**03 → E2.** 🟢 **Orientación en código ajeno.** Encuentra, con ruta y línea, dónde decide `payments` que una petición con una clave ya vista y estado `IN_PROGRESS` responde `409`, y qué hace el monolito con ese `409`.

⏱️ **30 segundos** — `payments/app/main.py`, líneas 87–88 (y 107–108 cuando la carrera la gana el índice
único). El monolito lo atrapa en `RemotePayments` como `HttpClientErrorException.Conflict` y devuelve
`PENDING`.

🗣️ **2 minutos** — Hay dos caminos al `409`: la fila existe y está `IN_PROGRESS` (otra petición con la
misma clave está en curso), o dos peticiones simultáneas llegan al `INSERT` y el índice único rechaza la
segunda (`UniqueViolation`). En el monolito, el `catch` de `Conflict` en `authorize` lo traduce a
`Result("PENDING", null)`: hay una operación en curso cuyo resultado no se conoce todavía.

🔬 **El detalle** — El `409` no cuenta como fallo para el breaker (`ignoreExceptions` de los `4xx`), y es
correcto: no dice nada de la salud de `payments`. Buscar primero el código de error (`PAYMENT_IN_PROGRESS`)
lleva directo a los dos sitios.

**03 → E3.** 🟡 Cambia el orden de los decoradores en `RemotePayments` (el reintento dentro del breaker) y repite la prueba de §8. Pega los tiempos y las transiciones y explica la diferencia.

⏱️ **30 segundos** — Con el breaker fuera, cada pago cuenta como una sola llamada aunque haga tres
intentos: el breaker tarda cuatro pagos en abrir en vez de dos, y cada uno de esos pagos hace tres
intentos.

🗣️ **2 minutos** — `CircuitBreaker.decorateSupplier(breaker, Retry.decorateSupplier(retry, call))`: el
breaker registra el resultado final de cada pago. Con `minimumNumberOfCalls` 4, los cuatro primeros pagos
tardan ≈ 0,7 s cada uno y el quinto falla en milisegundos. El destino caído recibe doce intentos en vez de
cuatro antes de que el breaker actúe.

🔬 **El detalle** — Ese orden tiene un uso: si se quiere que el breaker mida "pagos fallidos" y no
"llamadas fallidas". Pero entonces el reintento sigue insistiendo con el breaker abierto dentro del mismo
pago, y hay que decidirlo sabiendo que multiplica la carga sobre quien intenta recuperarse.

**03 → E4.** 🟡 Arranca `payments` con dos workers de uvicorn (`--workers 2`) y añade un contador de peticiones en memoria. ¿Qué te dice el resultado sobre cualquier estado en memoria del servicio, breaker incluido?

⏱️ **30 segundos** — Cada worker tiene su contador y cuenta aproximadamente la mitad: el estado en
memoria es por proceso, no por servicio.

🗣️ **2 minutos** — uvicorn con `--workers 2` arranca dos procesos que comparten el puerto; el sistema
operativo reparte las conexiones. Un `GET` al contador devuelve el de quien atienda esa conexión. Lo
mismo pasaría con un breaker o una caché en `payments`: cada proceso decide con la mitad de la
información.

🔬 **El detalle** — Es la fila de Python de la tabla de plataformas: el estado del breaker "por proceso"
no es un detalle, es el diseño. Si hace falta una decisión común, el estado va fuera (Redis) o la
protección se mueve a un sitio único (el gateway o un sidecar), con su propio coste.

**03 → E5.** 🟠 Añade al monolito un proceso de conciliación que, cada 30 s, busque pagos `PENDING` con más de un minuto y pregunte a `payments` por su `operation_id`. Demuestra que resuelve un pago pendiente sin que el cliente reintente.

⏱️ **30 segundos** — Un `@Scheduled` que lee `payments` con `status = 'PENDING'` y `created_at` antiguo y,
para cada uno, llama a `Payments.authorize` con la misma clave; si la respuesta es firme, aplica la
misma lógica que `resolvePending`.

🗣️ **2 minutos** — Reutiliza `resolvePending` extrayendo la parte que no depende del actor (la
conciliación no tiene cliente: actúa como sistema). La prueba: provocar un `666.00`, no reintentar, esperar
un minuto y ver el pedido pasar a `PAID` en el log y en `GET /orders/{id}`.

🔬 **El detalle** — La conciliación necesita un límite: un pago que sigue `PENDING` tras N intentos no se
decide solo; se escala a una persona. Y con varias instancias del monolito, dos procesos de conciliación
preguntarán lo mismo: por eso la operación tiene que ser idempotente (lo es) o el proceso tiene que tomar
un *lease* sobre la fila.

**03 → E6.** 🟠 Configura el breaker por **tasa de llamadas lentas** (`slowCallDurationThreshold`, `slowCallRateThreshold`) en vez de por errores y provoca que se abra con `slow payments`. ¿Qué gana y qué arriesga respecto de abrir solo por errores?

⏱️ **30 segundos** — Gana que el breaker actúa antes de los timeouts: un destino que se degrada deja de
recibir tráfico cuando empieza a ir lento, no cuando ya falla. Arriesga abrir por picos de latencia
normales.

🗣️ **2 minutos** — Con `slowCallDurationThreshold` de, por ejemplo, 1 s y `slowCallRateThreshold` del
50 %, `slow payments --latency 1500` abre el breaker aunque ninguna llamada expire. El monolito responde
`503` en milisegundos en vez de esperar. El umbral de "lento" se toma del p99 normal del destino, o el
breaker abrirá en cada pico.

🔬 **El detalle** — En un pago, abrir por lentitud tiene una ventaja extra: evita llamadas que acabarían
en timeout y, por tanto, en `PENDING` que luego hay que resolver. Menos dudas que conciliar.

**03 → E7.** 🔴 Sustituye `LocalPayments` por la llamada directa al proveedor **dentro** de una transacción, como en `06/01`, con el breaker delante. Repite la tormenta con el proveedor lento. ¿Salva el breaker al catálogo? Argumenta con la salida.

⏱️ **30 segundos** — No mientras el proveedor sea lento pero no falle: con 1,5 s y un timeout de 2 s no hay
errores, el breaker no abre y el pool se agota igual. Solo ayudaría si abriera por lentitud.

🗣️ **2 minutos** — El breaker cuenta errores; la cascada de `06/01` no los tenía del lado del proveedor:
eran llamadas lentas **exitosas** que retenían conexiones. La salida esperada es la de `06/01`: `500` por
`Connection is not available` en pagos y catálogo, y el breaker en `CLOSED` todo el tiempo. Configurado
por llamadas lentas (E6) abriría, y los pagos fallarían rápido con `503`… salvando el catálogo a costa de
no cobrar.

🔬 **El detalle** — Es la lección de fondo del bloque: los patrones de resiliencia contienen el daño de
un diseño que retiene recursos; no lo sustituyen. El orden correcto es primero no retener (§5), después
contener (breaker, bulkhead).

**03 → E8.** 🔥 Escribe el cliente de `payments` en Go con `sony/gobreaker` y un reintento con jitter propio, y compáralo en líneas y en decisiones con `RemotePayments`.

⏱️ **30 segundos** — `gobreaker.NewCircuitBreaker` con `ReadyToTrip` sobre el recuento, un bucle de
reintento con `time.Sleep(base * 2^n * (0,5 + rand))` y el `context` con plazo por intento.

🗣️ **2 minutos** — Las mismas decisiones aparecen escritas a mano: qué error se reintenta (comprobar
`errors.Is(err, context.DeadlineExceeded)` frente a `syscall.ECONNREFUSED`), dónde va el breaker
respecto del bucle, y cómo distinguir "no llegó" de "no sé". En líneas sale parecido a `RemotePayments`;
en visibilidad, más: nada está en una configuración.

🔬 **El detalle** — El detalle propio de Go es el `context`: el reintento tiene que respetar el plazo del
contexto padre, o el bucle sigue reintentando cuando quien llamó ya se fue. En Java ese plazo global no
existe salvo que se construya; en Go viene con la firma de cada función.

---

# 04 — gRPC

## Preguntas

**04 → 1.** ¿Qué genera el `.proto` de `inventory` y quién lo genera en cada lenguaje? 🟢

⏱️ **30 segundos** — Los mensajes y los stubs de cliente y servidor. En Go, `buf generate` con plugins
remotos; en Java, el `protobuf-maven-plugin` en cada build; en Python, `grpc_tools.protoc` al vuelo.

🗣️ **2 minutos** — Un solo archivo produce el código de los tres lenguajes, así que no pueden discrepar
sobre la forma de un mensaje. En Go los archivos generados se versionan con el servicio (`inventory/gen`);
en Java se generan en `target/` y no se versionan; en Python se generan en `tools/bench/gen/` la primera
vez. Ninguno necesita `protoc` instalado en la máquina.

🔬 **El detalle** — Versionar o no el código generado es una decisión: versionarlo hace el build
reproducible sin red y permite revisar el cambio en un pull request; no versionarlo evita que el código
generado y el `.proto` se desincronicen. Lo que no se negocia es que la fuente de verdad sea el `.proto`.

**04 → 2.** ¿Por qué el deadline se pone en cada llamada y no una vez en el stub? 🟢

⏱️ **30 segundos** — Porque un deadline es un instante absoluto: un stub con "800 ms desde ahora" caduca
800 ms después de crearlo, y todas las llamadas posteriores nacen vencidas.

🗣️ **2 minutos** — `withDeadlineAfter` calcula `ahora + 800 ms` en el momento en que se llama. Por eso
`GrpcInventory` crea un stub derivado en cada operación (`call()`). Además permite plazos distintos por
operación y encadenarlos: si la petición HTTP de entrada ya tiene un plazo, el de la llamada gRPC debería
ser el menor de los dos.

🔬 **El detalle** — Es el error más común con gRPC en Java: configurar el deadline al construir el bean
del stub. Las primeras llamadas funcionan y, a partir de un momento, todas fallan con `DEADLINE_EXCEEDED`
inmediato, lo que parece un problema del servidor.

**04 → 3.** ¿Qué hace `lab.py lock-stock` y por qué provoca lentitud sin tocar el código del servidor? 🟢

⏱️ **30 segundos** — Abre en `ms_inventory` una transacción que bloquea la fila del SKU con `FOR UPDATE` y
espera N segundos. Toda retención de ese SKU espera al bloqueo.

🗣️ **2 minutos** — `Hold` hace `SELECT … FOR UPDATE` sobre las filas de `inventory`; si otra transacción
las tiene, espera. Así el servidor es lento de verdad —esperando a la base, como en producción— sin un
`sleep` en el código de negocio, que la guía prohíbe. Y la espera es cancelable: es exactamente lo que
permite ver si el deadline llega hasta la consulta.

🔬 **El detalle** — Es también un escenario real frecuente: un proceso por lotes o una migración que
bloquea filas calientes. Los síntomas en los servicios son timeouts; la causa está en `pg_locks`.

**04 → 4.** ¿Qué es `x-jwt-payload` y quién lo escribe? 🟢

⏱️ **30 segundos** — El contenido del JWT ya verificado, en base64url, que Envoy añade a la petición para
los servicios de detrás. Lo escribe el filtro `jwt_authn`.

🗣️ **2 minutos** — `forward_payload_header` hace que Envoy, tras validar la firma, copie el payload en ese
encabezado. `orders` lo lee y construye el `Actor` sin volver a verificar nada. En la prueba, Envoy
**sobrescribió** un `x-jwt-payload` falso que venía del cliente: lo que llega a `orders` por el gateway es
siempre el del token verificado.

🔬 **El detalle** — El encabezado no está firmado: es una afirmación del gateway. Solo vale si el gateway es
el único camino al servicio; si no, cualquiera puede escribirlo (§10 del taller).

**04 → 5.** ¿Por qué `orders` guarda el correo del cliente en su propia tabla? 🟡

⏱️ **30 segundos** — Porque el correo es de `customers`, que sigue en el monolito, y el aviso de
cancelación lo necesita. Guardar una foto al crear el pedido evita llamar a `customers` al cancelar.

🗣️ **2 minutos** — Es la misma técnica que el nombre y el precio en las líneas: copiar el dato ajeno en el
momento en que importa. El correo sale del token (`email`), así que no cuesta ninguna llamada. El precio
es que la foto puede quedar vieja: si el cliente cambia de correo, el aviso de un pedido anterior va al
viejo.

🔬 **El detalle** — Si el negocio exige el correo actual, las alternativas son consultar a `customers` al
cancelar (acoplamiento temporal) o mantener una copia actualizada por eventos `CustomerUpdated`
([`03/02` §4](../03-datos-y-consistencia/02-consultas-entre-servicios.md#4--réplica-de-datos-de-referencia);
el read model del [taller 11](11-consultas-y-tiempo-real.md) es la misma idea con otro dato). La foto es la
más barata y casi siempre suficiente para un aviso.

**04 → 6.** ¿Qué diferencia hay entre `DEADLINE_EXCEEDED` en el cliente y `context canceled` en el servidor? 🟡

⏱️ **30 segundos** — Ninguna en significado: nadie espera ya la respuesta. El cliente vence su plazo y
cancela la llamada; el servidor ve la cancelación antes de llegar a su propia copia del plazo.

🗣️ **2 minutos** — El plazo viaja como duración relativa (`grpc-timeout`); el servidor calcula su deadline
al recibir la llamada, un poco después del cliente. Cuando el cliente vence, envía `RST_STREAM`, y el
`ctx` del servidor se cancela con `Canceled` antes de que su deadline expire. Por eso el log del servidor
dice `context canceled`.

🔬 **El detalle** — En el servidor, los dos se tratan igual: dejar de trabajar y no escribir nada. Un
servidor que solo reacciona a `DeadlineExceeded` y no a `Canceled` sigue trabajando en la mitad de los
casos.

**04 → 7.** ¿Por qué el detalle de "sin stock" va en `ErrorInfo` y no en el texto del mensaje? 🟡

⏱️ **30 segundos** — Porque el texto es para personas y puede cambiar; un dato estructurado es contrato.
Parsear el mensaje ata al cliente a una redacción.

🗣️ **2 minutos** — El modelo `google.rpc.Status` permite adjuntar detalles tipados: `PreconditionFailure`
dice qué SKU falló y `ErrorInfo` lleva en `metadata` el stock en mano por SKU. `GrpcInventory` los lee con
`StatusProto.fromThrowable` y construye el `409` del contrato público con el índice de línea. Si mañana
alguien traduce el mensaje al español, nada se rompe.

🔬 **El detalle** — La primera versión del taller parseaba "on hand N" del texto y se corrigió antes de
correrla; es exactamente el error que el detalle estructurado evita. En HTTP, el equivalente es un campo
propio en `problem+json` (`errors`, `shortages`), no el `detail`.

**04 → 8.** ¿Qué te da Go para respetar el deadline hasta la base de datos, y qué línea lo rompe? 🟡

⏱️ **30 segundos** — El `ctx` de la llamada gRPC, que `pgx` usa para cancelar la consulta. Lo rompe
`context.WithoutCancel(ctx)`.

🗣️ **2 minutos** — En Go el plazo no es una configuración: es un parámetro de cada función. Si el `ctx`
llega intacto de `Hold` a `pool.Query`, el vencimiento cancela la consulta y la transacción se deshace. La
provocación sustituye ese `ctx` por uno desacoplado: el servidor sigue esperando al bloqueo, completa la
retención y la deja huérfana.

🔬 **El detalle** — `WithoutCancel` tiene usos legítimos (terminar una escritura de auditoría aunque el
cliente se vaya), pero entonces esa escritura tiene que ser segura sin cliente. Usarlo para "silenciar
errores de cancelación" es el antipatrón.

**04 → 9.** El cambio de `qty = 2` a `qty = 3` compila en los tres lenguajes. ¿Qué pasa en producción si se despliega? 🟡

⏱️ **30 segundos** — Los clientes viejos mandan la cantidad en el campo 2; el servidor nuevo la busca en el
3, no la encuentra y lee cero. Se retienen cero unidades sin error.

🗣️ **2 minutos** — En el cable, un campo es su número, no su nombre. Con despliegues escalonados siempre hay
clientes y servidores de versiones distintas conviviendo, y ese es el momento en que el renumerado
corrompe datos en silencio. Por eso `buf breaking` lo trata como borrar el campo 2 y crear otro: sale con
código 100 y el pipeline se detiene.

🔬 **El detalle** — Un campo que se quiere retirar se marca `reserved 2;` y `reserved "qty";` para que nadie
reutilice el número ni el nombre. Cambiar el tipo de un campo tiene el mismo riesgo, y `buf` también lo
detecta.

**04 → 10.** Con el contexto desacoplado, la compensación del cliente no liberó nada. ¿Por qué, y qué la habría hecho funcionar? 🟠

⏱️ **30 segundos** — Porque llegó antes de que existiera la retención: `Release` no encontró nada y
devolvió 0. Habría funcionado si el servidor respetara el deadline, o si la retención caducara.

🗣️ **2 minutos** — La compensación inmediata supone que la operación ya ocurrió o no va a ocurrir. Con el
servidor trabajando desacoplado, la operación ocurre **después**. Tres salidas: respetar el deadline en el
servidor (la corrección de fondo), retenciones con caducidad (la red de seguridad) o una conciliación que
busque retenciones sin pedido.

🔬 **El detalle** — Un `Release` que llega primero podría dejar una "lápida" (marca de liberado por
referencia) para que el `Hold` que llegue después la vea y no retenga. Es la técnica de los *tombstones* en
sistemas con mensajes desordenados, y tiene su propio coste de limpieza.

**04 → 11.** La medición dio medio milisegundo a favor de gRPC en dos de tres corridas. ¿Qué dices si te preguntan cuál es más rápido? 🟠

⏱️ **30 segundos** — Que en ese servicio el protocolo no es el cuello de botella: el tiempo es de la base de
datos. Elijo gRPC por el contrato compilado y el deadline, no por la latencia.

🗣️ **2 minutos** — La medición es honesta y pequeña: un cliente secuencial, local, sin TLS, mensajes
diminutos y dos transacciones con bloqueo por muestra. En esas condiciones la diferencia es de ruido, y en
una corrida gRPC perdió en la cola. gRPC gana más cuando los mensajes son grandes, la serialización pesa o
hay muchas llamadas concurrentes multiplexadas en una conexión.

🔬 **El detalle** — Las cifras de "gRPC es N veces más rápido" miden servidores que no hacen nada. La
pregunta útil es qué fracción del tiempo total es protocolo, y eso lo da una traza con los spans de red y
de base ([taller 07](07-observabilidad-de-extremo-a-extremo.md)), no un microbenchmark.

**04 → 12.** ¿Es correcto que `orders` confíe en `x-jwt-payload`? ¿Qué tendría que ser verdad? 🟠

⏱️ **30 segundos** — Solo si nadie puede llegar a `orders` sin pasar por Envoy. En el laboratorio no es
verdad —el puerto está abierto— y la prueba lo demuestra.

🗣️ **2 minutos** — Confiar en el gateway ahorra verificar firmas en cada servicio y centraliza la política.
Pero convierte la red en parte del control de acceso: en producción, los servicios solo aceptan tráfico del
gateway (red privada, `NetworkPolicy`, mTLS con identidad del gateway) y el gateway limpia los encabezados
de identidad entrantes. Sin eso, `x-jwt-payload` es una puerta abierta.

🔬 **El detalle** — La alternativa conservadora es que cada servicio verifique el token (la firma es barata
con claves públicas). Con HS256, además, el secreto compartido permite firmar: cualquier servicio que lo
tenga puede fabricar tokens. Es otro motivo para pasar a claves asimétricas.

**04 → 13.** Dibuja el alta de un pedido con `orders` extraído: cada salto, su protocolo, su plazo y qué pasa si falla. 🔴

⏱️ **30 segundos** — Cliente → Envoy (JWT) → `orders` → catálogo en el monolito (HTTP, 800 ms) →
`inventory` (gRPC, 800 ms, con compensación) → base de `orders`. Cada fallo tiene su código.

🗣️ **2 minutos** —

```text
cliente ─HTTP─► Envoy (10 s)             sin token → 401 UNAUTHENTICATED (local)
  └─► orders
       ├─ idempotencia (ms_orders)       repetición → 200 replay
       ├─ catálogo: GET monolith/products (HTTP, 800 ms, token relay)
       │     no existe SKU → 404 · no responde → 503 CATALOG_UNAVAILABLE
       ├─ inventory.Hold (gRPC, deadline 800 ms)
       │     FAILED_PRECONDITION → 409 INSUFFICIENT_INVENTORY (lines[i])
       │     DEADLINE_EXCEEDED/UNAVAILABLE → Release (compensación) → 503 INVENTORY_UNAVAILABLE
       └─ tx: INSERT order + idempotencia ── falla → Release → error original
```

🔬 **El detalle** — Lo que el entrevistador preguntará: la suma de plazos (800 + 800 + base) cabe en los 10 s
de Envoy, pero no hay un presupuesto común; el catálogo puede consumir su plazo entero y aun así se intenta
el inventario. Propagar un deadline de extremo a extremo (el de la petición de entrada) resolvería eso.

**04 → 14.** En producción, el stock de un SKU baja sin pedidos que lo expliquen y ves `DEADLINE_EXCEEDED` en el cliente. Da tres hipótesis en orden de probabilidad y qué mirarías para cada una. 🔴

⏱️ **30 segundos** — Retenciones hechas después de que el cliente se rindiera (el servidor no respeta el
plazo), compensaciones que llegaron antes que la retención, o compensaciones que fallaron por el mismo
problema que la operación.

🗣️ **2 minutos** —

```text
1. Servidor que ignora el plazo      holds HELD sin pedido cuyo commit (log) es posterior al timeout
                                     del cliente; buscar WithoutCancel o contextos nuevos en el código
2. Compensación antes que la operación  Release con 0 liberadas seguido de un Hold con la misma
                                     referencia en el log del servidor
3. Compensación fallida              Release con DEADLINE_EXCEEDED en el log de orders; misma causa
                                     de lentitud (bloqueos en pg_locks, pool agotado)
```

🔬 **El detalle** — Las tres se cubren con la misma red: retenciones que caducan y una conciliación que
compare `holds` con los pedidos existentes. La corrección de fondo de la primera es de código; las otras
dos son propiedades de cualquier sistema con timeouts, y no se eliminan, se acotan.

## Ejercicios

**04 → E1.** 🟢 Añade al `.proto` un campo nuevo y compatible (`string note = 3` en `HoldRequest`) y demuestra con `lab.py buf breaking` que no rompe. Luego borra el campo `reference` y pega lo que dice.

⏱️ **30 segundos** — Añadir un campo con número nuevo es compatible: `buf breaking` sale con 0. Borrar
`reference` rompe: sale con 100 y un mensaje de campo borrado.

🗣️ **2 minutos** — Un cliente viejo ignora el campo 3 que no conoce y un servidor nuevo recibe `note` vacía
de los clientes viejos: nadie falla. Borrar `reference` deja a los clientes viejos mandando un campo que el
servidor ya no lee, y a los nuevos sin forma de identificar la retención. El mensaje esperado es el mismo
que en §8: `Previously present field "1" with name "reference" on message "HoldRequest" was deleted.`

🔬 **El detalle** — Para retirar un campo sin romper, primero se deja de usar, se marca `deprecated`, y
cuando ningún cliente lo manda se borra con `reserved 1; reserved "reference";`. `buf` acepta el borrado
si el número queda reservado según la regla elegida (`FILE` es estricta).

**04 → E2.** 🟢 **Orientación en código ajeno.** Encuentra, con ruta y línea, dónde traduce `orders` un `FAILED_PRECONDITION` de `inventory` al `409 INSUFFICIENT_INVENTORY` del contrato, y qué dato usa para calcular el índice `lines[i]`.

⏱️ **30 segundos** — `orders/.../inventory/GrpcInventory.java`, línea 57 (la distinción) y el método
`outOfStock` (línea 90 lee el `ErrorInfo`); el índice sale del SKU de `PreconditionFailure`, buscado en las
líneas de la petición.

🗣️ **2 minutos** — `outOfStock` recorre los detalles del `Status`: de `PreconditionFailure` toma el
`subject` (el SKU) y de `ErrorInfo` el `metadata` con el stock por SKU. Luego busca en `lines` la primera
línea con ese SKU: su posición es el `i` de `lines[i].quantity`. `web/ApiErrors.java` convierte
`InsufficientInventory` en el `409` con `errors[0].field`.

🔬 **El detalle** — El servidor no sabe qué es una "línea de pedido"; el índice es un concepto del contrato
público de `orders`. Que la traducción viva en el cliente es la capa anticorrupción funcionando.

**04 → E3.** 🟢 Repite §7 con `lab.py orders --deadline 3000` y el bloqueo de 5 s. ¿Qué cambia para el cliente y para el servidor? Pega la salida.

⏱️ **30 segundos** — El cliente espera 3 s en vez de 0,8 y sigue recibiendo `503`; el servidor, con el
deadline propagado, sigue abandonando: con 5 s de bloqueo, 3 s tampoco alcanzan.

🗣️ **2 minutos** — Un deadline más largo solo ayuda si cubre la espera real. Con el bloqueo de 5 s, el
resultado es el mismo con más latencia para el cliente. Con `--seconds 2`, en cambio, el pedido se crea
(`201` en ≈ 2 s): el plazo se decide con el p99 de la dependencia, no con su peor caso.

🔬 **El detalle** — Un deadline largo también retiene más tiempo los recursos del llamador (hilos, el
contexto de la petición) y empeora la cola del cliente. Subirlo "por si acaso" traslada la lentitud hacia
arriba en vez de contenerla.

**04 → E4.** 🟡 Usa `grpcurl` en Docker (`fullstorydev/grpcurl`) para llamar a `GetStock` sin stubs. ¿Por qué falla sin reflexión, y qué dos formas hay de arreglarlo?

⏱️ **30 segundos** — `grpcurl` necesita el esquema para codificar la petición; sin reflexión en el servidor
no lo tiene. Se arregla registrando la reflexión en `inventory` o pasándole el `.proto` con `-proto`.

🗣️ **2 minutos** — Con `-import-path /proto -proto ms/inventory/v1/inventory.proto` (montando
`contrato/proto`) y `-d '{"skus":["SKU-001"]}'`, la llamada funciona sin tocar el servidor. La otra opción es
`reflection.Register(gs)` en `main.go` (paquete `google.golang.org/grpc/reflection`), que permite
descubrir servicios y métodos.

🔬 **El detalle** — La reflexión en producción expone el catálogo de métodos: útil para depurar y una
superficie más para un atacante. Lo habitual es activarla solo en entornos internos o tras autenticación.

**04 → E5.** 🟠 Haz que `orders` rechace peticiones que no vengan de Envoy sin romper la suite: por ejemplo, un secreto compartido que Envoy añade como encabezado y `orders` comprueba. Repite la prueba de §10 y pega la salida.

⏱️ **30 segundos** — Envoy añade `x-gateway-secret` con `request_headers_to_add` en la ruta de `orders`, y un
filtro en `orders` rechaza con `401` toda petición sin ese valor. La llamada directa al puerto deja de ver
nada.

🗣️ **2 minutos** — La suite sigue en verde porque todo su tráfico pasa por Envoy. La prueba directa con el
`x-jwt-payload` falso recibe `401`. Es una defensa barata para el laboratorio, con un límite claro: el
secreto es estático y quien lo robe entra.

🔬 **El detalle** — La versión de producción es mTLS entre gateway y servicio (el servicio solo acepta
certificados del gateway) o que el servicio verifique el JWT. Un secreto compartido en un encabezado es
autenticación de red de la época anterior a los service mesh ([`04/05`](../04-operacion-y-resiliencia/05-service-mesh-y-sidecar.md)).

**04 → E6.** 🟠 Borra del monolito el código de pedidos que ya no recibe tráfico. ¿Qué te dice `git diff --stat` sobre cuánto quedaba, y qué comprobarías antes de hacerlo en producción?

⏱️ **30 segundos** — Se van `OrderController`, `OrderService`, `PaymentService`, las entidades y
repositorios de pedidos y la costura de pagos: la mayoría del monolito. Antes, que ninguna ruta llegue a
ese código.

🗣️ **2 minutos** — El diff muestra que el monolito queda en catálogo, clientes y autenticación. La
comprobación previa en producción: el access log de Envoy y las métricas del monolito sin tráfico a esas
rutas durante un período representativo (incluidos procesos mensuales), y ningún otro consumidor interno.

🔬 **El detalle** — El strangler que no borra acumula código muerto que alguien mantiene sin saberlo. Borrar
es la última fase del patrón y la que más se omite.

**04 → E7.** 🔴 Repite la medición de §9 con 20 clientes concurrentes. ¿Cambia la conclusión? ¿Qué parte de la diferencia atribuyes a HTTP/2 y cuál a la base?

⏱️ **30 segundos** — Con concurrencia, gRPC multiplexa las llamadas en una conexión HTTP/2 y HTTP/1.1 necesita
varias; pero las retenciones del mismo SKU se serializan en el bloqueo de la fila, y eso domina.

🗣️ **2 minutos** — Si los 20 clientes retienen el mismo SKU, el `FOR UPDATE` los pone en fila y el protocolo
desaparece del resultado. Con SKU distintos, la diferencia de protocolo puede aparecer en la cola. La
conclusión probable sigue siendo que la base manda; cualquier cifra se etiqueta como reproducción local.

🔬 **El detalle** — Para atribuir, hace falta medir por partes: tiempo en el servidor (span) frente a tiempo
total. Sin trazas, la atribución es una conjetura; es el argumento para el [taller 07](07-observabilidad-de-extremo-a-extremo.md).

**04 → E8.** 🔥 Expón `CreateOrder` de `orders` por gRPC además de HTTP, con el mismo caso de uso detrás, y mide cuánto código es transporte y cuánto es negocio.

⏱️ **30 segundos** — Un `.proto` de `orders`, un servidor gRPC en Spring (`spring-boot-starter-grpc-server`)
que traduce el mensaje a `OrderService.create` y sus errores a códigos. El negocio no cambia.

🗣️ **2 minutos** — El transporte son el `.proto`, el adaptador de servidor y el mapeo de errores
(`409` → `FAILED_PRECONDITION`, `503` → `UNAVAILABLE`); el negocio es `OrderService`, intacto. La identidad,
que en HTTP venía en `x-jwt-payload`, viaja en la metadata de gRPC. El recuento suele dar más líneas de
transporte que de negocio.

🔬 **El detalle** — La idempotencia es la parte delicada: la clave, que en HTTP va en un encabezado, en gRPC
va en metadata o en el mensaje. Ponerla en el mensaje la hace parte del contrato y visible en `buf breaking`.

---

# 05 — Resiliencia en tres plataformas

## Preguntas

**05 → 1.** ¿Por qué a `inventory` le toca limitar y rechazar, y no un circuit breaker? 🟢

⏱️ **30 segundos** — Porque `inventory` no llama a nadie: es servidor. Un breaker protege al que llama;
a quien recibe le toca proteger su capacidad rechazando pronto lo que no cabe.

🗣️ **2 minutos** — El circuit breaker vive en el cliente de una dependencia. `inventory` solo recibe
llamadas y toca su base; su riesgo es aceptar más trabajo del que puede hacer y degradarse para todos.
El límite de tasa y el de peticiones en vuelo convierten el exceso en `RESOURCE_EXHAUSTED` inmediato,
antes de tocar PostgreSQL.

🔬 **El detalle** — Las dos piezas se complementan: el breaker del cliente deja de mandar cuando el
servidor falla; el límite del servidor evita llegar a fallar. Sin el segundo, el breaker del cliente se
entera tarde, cuando el servidor ya está saturado.

**05 → 2.** ¿Qué diferencia hay entre `Allow()` y `Wait()` en un `rate.Limiter`, y por qué se usa `Allow()`? 🟢

⏱️ **30 segundos** — `Allow()` contesta al instante si hay ficha; `Wait()` bloquea hasta que la haya.
Se usa `Allow()` porque la idea es rechazar, no encolar.

🗣️ **2 minutos** — Con `Wait()`, el exceso se convierte en cola dentro del servidor: las peticiones
esperan, retienen recursos y el cliente ve latencia en vez de un error que puede gestionar. `Allow()`
devuelve `false` y el servidor responde `RESOURCE_EXHAUSTED` en microsegundos.

🔬 **El detalle** — `Wait(ctx)` tiene sentido en un **cliente** que quiere respetar la cuota de un
tercero: ahí esperar es lo correcto, y el `ctx` acota cuánto.

**05 → 3.** ¿Qué significa `RESOURCE_EXHAUSTED` y qué debe hacer el cliente con él? 🟢

⏱️ **30 segundos** — Que el servidor no aceptó la petición por falta de capacidad y **no la procesó**.
El cliente puede reintentar más tarde, con backoff.

🗣️ **2 minutos** — Es el equivalente gRPC de un `429` o un `503` con `Retry-After`: la operación no
ocurrió, así que reintentar es seguro. Lo que no debe hacer el cliente es reintentar al instante, que
suma carga justo cuando falta.

🔬 **El detalle** — `orders` hoy lo trata como `INVENTORY_UNAVAILABLE` y compensa, lo que es seguro pero
innecesario (no hubo retención). El ejercicio 🟠 6 lo convierte en un reintento con backoff.

**05 → 4.** ¿Qué diferencia hay entre liveness y readiness? 🟡

⏱️ **30 segundos** — Liveness: ¿el proceso vive? Si no, se reinicia. Readiness: ¿puede atender su
trabajo ahora? Si no, se saca del balanceo sin reiniciarlo.

🗣️ **2 minutos** — Confundirlas tiene dos formas: una liveness que mira dependencias reinicia procesos
sanos en bucle; una readiness que mira dependencias saca del balanceo instancias que podrían atender
casi todo. En el taller, `orders` con `payments` en la readiness dejó de servir hasta la lista de
pedidos.

🔬 **El detalle** — Hay una tercera, *startup*, para procesos lentos en arrancar: evita que la liveness
los mate antes de estar listos. Las tres se exponen en Spring Boot como grupos de Actuator.

**05 → 5.** ¿Por qué el bulkhead de `orders` va por fuera del reintento? 🟡

⏱️ **30 segundos** — Para que cuente pagos en curso con sus reintentos incluidos. Dentro, cada intento
ocuparía y liberaría una plaza, y un pago que reintenta podría quedarse sin sitio a mitad.

🗣️ **2 minutos** — El bulkhead limita cuántas operaciones de pago acaparan hilos a la vez. Por fuera,
un pago toma una plaza y la conserva mientras dura, reintentos incluidos: el límite es sobre
operaciones, que es lo que se quiere proteger. Por dentro, el límite sería sobre llamadas
individuales.

🔬 **El detalle** — El orden completo es bulkhead → reintento → breaker → llamada. Cada decorador
responde a una pregunta distinta: cuántos a la vez, cuántas veces, y si vale la pena intentarlo.

**05 → 6.** ¿Por qué la lista de pedidos tardó 1,94 s sin bulkhead, si no llama a `payments`? 🟡

⏱️ **30 segundos** — Porque necesitaba un hilo de Tomcat y los 16 estaban esperando a `payments`.
Esperó a que uno quedara libre.

🗣️ **2 minutos** — Es la cascada de `06/01` con otro recurso: allí el pool de conexiones, aquí los hilos
del servidor. Treinta pagos lentos ocuparon los 16 hilos; cualquier petición, pagara o no, se encoló.
Con el bulkhead, solo 4 hilos se prestan a `payments` y los otros 12 atienden todo lo demás.

🔬 **El detalle** — Con los 200 hilos por defecto el efecto no se habría visto con 30 pagos, pero sí con
300: el bulkhead no depende del tamaño del pool; lo protege. Con hilos virtuales el recurso escaso
dejaría de ser el hilo y pasaría a ser la conexión o la memoria.

**05 → 7.** ¿Qué hace el modo pánico de Envoy y por qué ocultaba la provocación de la readiness? 🟡

⏱️ **30 segundos** — Si el porcentaje de instancias sanas baja del umbral (50 % por defecto), Envoy
ignora la salud y reparte entre todas. Con una sola instancia no lista, seguía mandándole tráfico.

🗣️ **2 minutos** — Es una protección: si "todo está caído", probablemente el chequeo se equivoca, y
mejor intentar que devolver `503` a todo. Pero hace que una readiness mal diseñada no se note en el
laboratorio. Con `healthy_panic_threshold: 0`, Envoy se comporta como un `Service` de Kubernetes: la
instancia no lista deja de recibir tráfico.

🔬 **El detalle** — En producción el umbral se deja o se baja con intención: con muchas instancias, el
pánico salva de un chequeo roto que marca todo como caído; con una readiness que depende de un
tercero compartido, todas las instancias caen a la vez y el pánico es lo único que mantiene el servicio.

**05 → 8.** ¿Qué te da Python para un circuit breaker asíncrono, y qué pasa con su estado si arrancas varios workers? 🟡

⏱️ **30 segundos** — `purgatory`, nativo de `asyncio`, porque el `call_async` de `pybreaker` es de
Tornado. Con varios workers, cada proceso tiene su breaker y decide por separado.

🗣️ **2 minutos** — `purgatory` usa `async with` y cuenta fallos consecutivos. Su estado vive en memoria
del proceso; con `uvicorn --workers 4`, un PSP caído tiene que abrir cuatro breakers, cada uno con un
cuarto del tráfico. `purgatory` permite guardar el estado en Redis para compartirlo, a cambio de una
dependencia más en el camino de cada llamada.

🔬 **El detalle** — `purgatory` no publica desde noviembre de 2024: se usa sabiéndolo y con el plan B
claro (un breaker propio son unas cuarenta líneas). Es la situación típica de Python en este temario:
la pieza existe, fuera del framework, y hay que evaluarla.

**05 → 9.** Explica por qué un pago con `payments` caído generó 9 llamadas, y cuántas serían con tres capas. 🟡

⏱️ **30 segundos** — Envoy hizo 3 intentos contra `orders` y cada uno hizo 3 llamadas a `payments`:
3 × 3 = 9. Con tres capas de tres intentos, 27.

🗣️ **2 minutos** — Cada capa reintenta sin saber que la de abajo ya reintentó. El access log de Envoy
lo dice (`attempts=3`, `URX`) y el de `orders` cuenta 6 reintentos más 3 fallos. La carga sobre el
servicio caído crece de forma geométrica con el número de capas, justo cuando intenta volver.

🔬 **El detalle** — Los breakers la acotan (en la corrida siguiente, el de `orders` se abrió y cortó),
pero no la evitan: la corrección es que reintente una sola capa. Otra herramienta es un presupuesto de
reintentos (*retry budget*): no más de un 10–20 % de las peticiones pueden ser reintentos.

**05 → 10.** ¿Por qué Envoy puede reintentar el `POST` de un pago sin cobrar dos veces, y por qué aun así no debería? 🟠

⏱️ **30 segundos** — Porque la `Idempotency-Key` viaja de extremo a extremo y cada salto deduplica. No
debería porque multiplica la carga y porque Envoy no sabe qué es seguro reintentar: lo sabe `orders`.

🗣️ **2 minutos** — La seguridad del reintento depende de un detalle de la aplicación que el gateway no
ve. Si mañana una ruta sin clave pasa por la misma política, Envoy duplica efectos. La política
segura del gateway reintenta solo lo que con certeza no llegó (`connect-failure`, `refused-stream`), y
deja el resto a la capa que entiende la operación.

🔬 **El detalle** — Envoy distingue por método con `retriable_request_headers` o reintentando solo
`GET`; es la otra forma de hacerlo seguro. Lo que no se hace es `retry_on: 5xx` global sobre `POST`.

**05 → 11.** El breaker de `orders` se abrió por los `503` del breaker de `payments`. ¿Es un error? ¿Qué cambiaste? 🟠

⏱️ **30 segundos** — Sí: `payments` estaba sano; el que fallaba era el PSP. `orders` dejó de reintentar
el `503 PSP_UNAVAILABLE` y así ya no acumula fallos por una negativa explícita.

🗣️ **2 minutos** — El `503` de `payments` significa "no llamo porque mi dependencia está mal", no "estoy
caído". Reintentarlo al instante da lo mismo tres veces, y contarlo como caída abre un segundo
breaker que corta también los pagos que `payments` sí podría atender. Con el predicado de reintento
corregido, cada pago hace una llamada y el breaker de `orders` sigue cerrado.

🔬 **El detalle** — Queda una decisión abierta: si ese `503` debe contar como fallo para el breaker de
`orders`. Tiene argumentos a favor (no hay forma de pagar) y en contra (payments está sano). Lo que no
es opinable es que el código de error tiene que decir cuál de las dos cosas pasa.

**05 → 12.** ¿Cómo eliges el número del bulkhead (4) y el umbral del breaker (3 seguidos) para producción? 🟠

⏱️ **30 segundos** — El bulkhead, con la ley de Little: concurrencia = ritmo de pagos × latencia normal
de la dependencia, con margen. El breaker, con la tasa de error normal y el tráfico por ventana.

🗣️ **2 minutos** — Si hay 20 pagos por segundo y `payments` tarda 150 ms, la concurrencia normal es 3;
un bulkhead de 8–10 deja margen para picos sin prestar todos los hilos. El breaker se calibra para no
abrir por ruido: con tráfico alto, porcentaje sobre una ventana de decenas de llamadas; con tráfico
bajo, fallos consecutivos como `purgatory`. Los números del laboratorio son bajos para verlos.

🔬 **El detalle** — Los dos se revisan con métricas reales: rechazos del bulkhead por minuto y
transiciones del breaker. Un bulkhead que rechaza en tráfico normal está mal dimensionado; un breaker
que nunca se abre, también.

**05 → 13.** Dibuja la cadena de protección de un pago —de Envoy al PSP— con cada mecanismo, dónde está y qué devuelve cuando actúa. 🔴

⏱️ **30 segundos** — Envoy (reintento solo si no llegó; readiness), `orders` (bulkhead, reintento,
breaker), `payments` (timeout y breaker hacia el PSP). Cada uno devuelve un código que dice si es seguro
repetir.

🗣️ **2 minutos** —

```text
Envoy     sin instancia lista      → 503 SERVICE_UNAVAILABLE (UH)       seguro: no llegó
          no conecta               → 1 reintento; luego 503              seguro
orders    bulkhead lleno           → 503 PAYMENTS_UNAVAILABLE (0,16 s)   seguro: no llamó
          breaker abierto          → 503 PAYMENTS_UNAVAILABLE (ms)       seguro
          timeout tras 3 intentos  → 200 PAYMENT_PENDING                 incierto: repetir con la clave
payments  breaker PSP abierto      → 503 PSP_UNAVAILABLE (no reintentar) seguro
          timeout del PSP (2 s)    → PENDING                             incierto
```

🔬 **El detalle** — Lo que el entrevistador preguntará después: cuánto tarda el peor caso (tres
intentos de 2,5 s en `orders`) y si cabe en los 10 s de Envoy; y qué pasa con el pago incierto si el
cliente no reintenta (el orquestador con plazo del [taller 09](09-saga-orquestada.md)).

**05 → 14.** En producción, una dependencia se cae y a los treinta segundos todo tu servicio devuelve `503` desde el gateway. Da tres hipótesis en orden de probabilidad y qué mirarías para cada una. 🔴

⏱️ **30 segundos** — Una readiness que incluye la dependencia, recursos agotados por llamadas colgadas
que hacen fallar también la readiness, o reintentos de varias capas que saturan el servicio.

🗣️ **2 minutos** —

```text
1. Readiness con la dependencia     /actuator/health/readiness en DOWN con liveness UP;
                                    en el gateway, UH / no healthy upstream
2. Hilos o pool agotados             volcado de hilos esperando a la dependencia; el chequeo
                                    de readiness también espera y expira
3. Tormenta de reintentos            attempts > 1 en el access log; tasa de peticiones hacia
                                    el servicio muy por encima de la de clientes
```

🔬 **El detalle** — La segunda es la que se confunde con la primera: la readiness no incluye la
dependencia, pero el chequeo no consigue hilo. La corrección es la del taller: bulkhead y timeouts
cortos, para que siempre queden recursos para responder a la salud y al resto del tráfico.

## Ejercicios

**05 → E1.** 🟢 Repite §5 con `--max-inflight 32` y sin límite de tasa. ¿Cuántas se rechazan ahora y por qué? Pega la salida.

⏱️ **30 segundos** — Prácticamente ninguna: con 32 clientes a la vez y 32 plazas, siempre cabe. El límite
solo actúa cuando la concurrencia supera la capacidad declarada.

🗣️ **2 minutos** — Sin límite de tasa, todas llegan a la base; con 32 en vuelo como techo, el semáforo
no rechaza. El resultado se parecerá a la corrida "sin límites": 100 OK por el stock y el resto
`FAILED_PRECONDITION`. El número útil sale de medir la capacidad real y ponerlo por debajo.

🔬 **El detalle** — Un límite que nunca rechaza en carga normal es correcto; uno que nunca rechaza
tampoco en sobrecarga está puesto demasiado alto para servir de algo.

**05 → E2.** 🟢 **Orientación en código ajeno.** Encuentra, con ruta y línea, dónde decide `orders` que un `503` de `payments` no se reintenta, y dónde decide que no cuenta como caída para su breaker (si es que lo decide).

⏱️ **30 segundos** — El reintento, en `RemotePayments.java`, línea 64 (`retryOnException` excluye
`PSP_UNAVAILABLE`). Para el breaker no hay exclusión: ese `503` sigue contando como fallo.

🗣️ **2 minutos** — `ignoreExceptions(HttpClientErrorException.class)` solo excluye los `4xx`. El `503`
es `HttpServerErrorException` y cuenta; lo que cambió es que ya no se multiplica por tres. Con cinco
negativas seguidas, el breaker de `orders` podría abrirse igualmente: es la decisión abierta de 05 → 11.

🔬 **El detalle** — Para excluirlo del breaker haría falta `recordException` con un predicado igual al del
reintento. Encontrar que **no** existe es parte del ejercicio: en código ajeno, la ausencia también es
una respuesta.

**05 → E3.** 🟡 Cambia `maxWaitDuration` del bulkhead a 500 ms y repite §6. ¿Qué gana y qué pierde la sonda y qué los pagos?

⏱️ **30 segundos** — Algunos pagos que antes se rechazaban esperan y salen; la sonda puede empeorar
algo, porque ahora hay hilos esperando una plaza hasta 500 ms.

🗣️ **2 minutos** — Con cola, el bulkhead absorbe picos cortos: si una plaza queda libre en medio segundo,
el pago entra. El precio es que cada pago en cola retiene un hilo de Tomcat esperando; con 16 hilos, la
cola se come parte del margen que protegía a la sonda. Con `payments` a 2 s, casi nadie consigue plaza
en 500 ms y el resultado se parece al de sin cola, pero más lento.

🔬 **El detalle** — La cola del bulkhead tiene sentido cuando la latencia normal de la dependencia es
menor que la espera; si es mayor, solo convierte rechazos rápidos en rechazos lentos.

**05 → E4.** 🟡 Arranca `payments` con dos workers de uvicorn y repite §7. ¿Cuántos timeouts hacen falta ahora para que "el breaker" se abra? Explícalo con el estado por proceso.

⏱️ **30 segundos** — Tres por worker: hasta seis timeouts, según cómo reparta el sistema operativo las
conexiones. Cada worker tiene su breaker.

🗣️ **2 minutos** — Los dos procesos comparten el puerto y reciben peticiones alternas; cada uno cuenta
sus fallos consecutivos. Un worker puede tener el breaker abierto y el otro cerrado, así que el cliente
ve respuestas mezcladas (`PENDING` lento y `503` rápido) hasta que los dos se abren.

🔬 **El detalle** — `purgatory` con `AsyncRedisUnitOfWork` comparte el estado entre procesos e
instancias. El coste es una llamada a Redis por petición y un punto más que puede fallar.

**05 → E5.** 🟡 Configura el breaker de `orders` con ventana por tiempo (`TIME_BASED`, 10 s) y repite §8 con el breaker activo. ¿Cuántas llamadas llegan a `payments`?

⏱️ **30 segundos** — Unas cuatro o cinco: el breaker se abre en cuanto alcanza el mínimo de llamadas con
fallo, y el resto de intentos de Envoy y de `orders` reciben `CallNotPermittedException`.

🗣️ **2 minutos** — Con ventana por tiempo, el breaker evalúa las llamadas de los últimos 10 s, lo que
encaja mejor con tráfico irregular. En la provocación, los primeros intentos fallan, se alcanza el mínimo
y se abre: el resto no llega. Es la demostración de que el breaker acota la tormenta aunque no la evite.

🔬 **El detalle** — En ventana por tiempo, `minimumNumberOfCalls` ya no se recorta al tamaño de la ventana
(que se mide en segundos): el hallazgo de §10 es propio de la ventana por recuento.

**05 → E6.** 🟠 Haz que `orders` trate `RESOURCE_EXHAUSTED` de `inventory` como "reintenta en N ms" (un reintento con backoff) y no como `INVENTORY_UNAVAILABLE`. Demuéstralo con `inventory --rps 5`.

⏱️ **30 segundos** — En `GrpcInventory`, `RESOURCE_EXHAUSTED` se reintenta una o dos veces con backoff y
jitter; si persiste, `503` sin compensación, porque la retención no ocurrió.

🗣️ **2 minutos** — Con `--rps 5`, un alta rápida tras otra recibe `RESOURCE_EXHAUSTED`; con el reintento,
la mayoría entra en el segundo intento. Hay que distinguir este código de `DEADLINE_EXCEEDED`: aquel es
"no ocurrió"; este, "no sé".

🔬 **El detalle** — El servidor podría ayudar con metadata de "reintenta en X ms" (como `Retry-After`);
gRPC tiene `RetryInfo` en los detalles de `google.rpc` para eso.

**05 → E7.** 🔴 Diseña la readiness de `orders` para el día en que la base de `orders` esté sana pero el pool de conexiones agotado. ¿Qué debe decir, y qué pasa si todas las instancias dicen lo mismo a la vez?

⏱️ **30 segundos** — Podría decir `DOWN` para que el balanceador reparta hacia otras instancias; pero si
todas están igual, todas salen del balanceo y el servicio entero da `503`.

🗣️ **2 minutos** — Un pool agotado en una instancia (por una fuga, por ejemplo) es motivo para sacarla;
en todas a la vez, suele ser una causa común (una consulta lenta, una dependencia) y sacarlas todas lo
empeora. Por eso se combina con el umbral de pánico o con una readiness que solo marque `DOWN` tras un
tiempo sostenido, y con alertas que miren la proporción de instancias no listas.

🔬 **El detalle** — Es el argumento de fondo del modo pánico: la señal de salud de una instancia es
fiable cuando es independiente de las demás. Cuando todas fallan por lo mismo, la señal describe el
sistema, no la instancia.

**05 → E8.** 🔥 Mueve el breaker de `payments` a Envoy (*outlier detection* en el clúster) y compara qué ve cada capa y qué código recibe el cliente.

⏱️ **30 segundos** — Envoy expulsa de su balanceo a la instancia que da errores consecutivos; con una
sola instancia, el cliente recibe `503` de Envoy (`UH`) en vez de `PSP_UNAVAILABLE`.

🗣️ **2 minutos** — Para eso `orders` tendría que llamar a `payments` a través de Envoy (hoy va directo por
Toxiproxy). La ganancia: la política vive en un sitio y vale para cualquier lenguaje. La pérdida: Envoy
no distingue "payments caído" de "payments me dice que el PSP está caído", y el código de error pierde
significado.

🔬 **El detalle** — Es la discusión de [`04/05`](../04-operacion-y-resiliencia/05-service-mesh-y-sidecar.md):
el mesh mueve parte de la resiliencia fuera del código, no toda. Lo que depende del significado de la
operación sigue en la aplicación.

---

# 06 — Kafka: outbox, inbox, idempotencia y DLQ

## Preguntas

**06 → 1.** ¿Qué garantiza el outbox y qué no? 🟢

⏱️ **30 segundos** — Garantiza que el hecho sale si y solo si el cambio se confirmó, y que sale al menos
una vez. No garantiza que salga una sola vez ni al instante.

🗣️ **2 minutos** — El hecho se escribe en `outbox_events` en la misma transacción que el pedido: o se
confirman los dos o ninguno. Un proceso aparte lo publica y lo marca; si muere entre el envío y la marca,
lo reenvía. Por eso los consumidores tienen que ser idempotentes, y por eso hay hasta 200 ms de retraso
entre el cambio y el evento.

🔬 **El detalle** — Tampoco garantiza el orden global: solo por clave, porque la clave decide la partición.
Y un publicador con varias instancias necesita `SKIP LOCKED` para no publicar la misma fila dos veces a la
vez, lo que no impide el duplicado por caída.

**06 → 2.** ¿Por qué la clave de los mensajes es el `orderId`? 🟢

⏱️ **30 segundos** — Porque la clave decide la partición, y el orden solo existe dentro de una partición.
Con el `orderId`, los hechos de un pedido llegan en el orden en que ocurrieron.

🗣️ **2 minutos** — Un `OrderCancelled` que adelante a su `OrderPlaced` confunde a cualquier consumidor. Con
la misma clave, los dos van a la misma partición y se leen en orden. Entre pedidos distintos no hay orden,
y no hace falta.

🔬 **El detalle** — El número de particiones fija el paralelismo máximo de un grupo y no se cambia sin
reubicar claves: añadir particiones cambia a qué partición va cada `orderId`, y durante la transición el
orden por clave se puede romper.

**06 → 3.** ¿Qué hace `FOR UPDATE SKIP LOCKED` en el publicador? 🟢

⏱️ **30 segundos** — Bloquea las filas que va a publicar y salta las que otro proceso ya tiene bloqueadas.
Así dos instancias de `orders` no publican la misma fila a la vez.

🗣️ **2 minutos** — Sin él, dos publicadores leerían las mismas filas pendientes y las enviarían dos veces.
Con `FOR UPDATE` a secas, el segundo esperaría al primero; con `SKIP LOCKED`, coge otras filas y los dos
trabajan en paralelo sobre lotes distintos.

🔬 **El detalle** — `SKIP LOCKED` sacrifica el orden entre lotes: si dos publicadores cogen lotes
consecutivos, pueden enviarlos en orden cruzado. Para eventos del mismo pedido importa; una salida es un
publicador por partición lógica o uno solo con un *lease*.

**06 → 4.** ¿Qué es el inbox y dónde se escribe? 🟢

⏱️ **30 segundos** — Una tabla `processed_messages` con los `eventId` que un consumidor ya aplicó. Se
escribe en la misma transacción que el efecto.

🗣️ **2 minutos** — Al llegar un evento, el consumidor intenta insertar su `eventId`; si ya estaba
(`ON CONFLICT DO NOTHING` no inserta nada), no aplica el efecto. Como la marca y el efecto se confirman
juntos, no hay ventana en la que uno esté y el otro no.

🔬 **El detalle** — La tabla crece para siempre si no se poda. Se purga lo más antiguo que la retención del
topic (si el log ya no tiene el mensaje, no puede volver a entregarlo), y la clave incluye el consumidor
para que varios compartan la tabla.

**06 → 5.** ¿Por qué el offset se confirma después del efecto y no antes? 🟡

⏱️ **30 segundos** — Porque confirmar antes y morir antes del efecto pierde el mensaje sin rastro. Confirmar
después y morir antes del commit solo lo duplica, y el duplicado se absorbe.

🗣️ **2 minutos** — Es elegir qué fallo se prefiere: perder o duplicar. Perder no se detecta; duplicar se
detecta con el inbox. El autocommit por tiempo es la versión peor de "antes": confirma lo que haya leído
cada cinco segundos, se haya aplicado o no.

🔬 **El detalle** — Las transacciones de Kafka (productor idempotente y `read_committed`) dan "exactamente
una vez" cuando el efecto es escribir en otro topic. Con el efecto en una base externa, no alcanzan: el
inbox sigue haciendo falta.

**06 → 6.** ¿Por qué la re-entrega tardó 39 s? ¿Es un error? 🟡

⏱️ **30 segundos** — Porque el consumidor muerto no se despidió del grupo y el broker esperó a darlo por
perdido (`session.timeout.ms`, 45 s por defecto) antes de dar su partición a otro. No es un error: es un
plazo.

🗣️ **2 minutos** — Un cierre limpio envía `LeaveGroup` y el reparto es inmediato; un `os.Exit` no. Durante
ese plazo la partición no la consume nadie y su *lag* crece. Se ajusta con `session.timeout.ms` y el
intervalo de latidos, sabiendo que bajarlos demasiado provoca repartos por pausas de GC o de red.

🔬 **El detalle** — El protocolo nuevo de grupos de Kafka 4 (KIP-848, `group.protocol=consumer`) cambia cómo
se reparte, pero no elimina el plazo de detección de un miembro muerto.

**06 → 7.** ¿Por qué hay dos copias del venenoso en la DLQ? 🟡

⏱️ **30 segundos** — Porque dos grupos leen el mismo topic y cada uno lo apartó por su cuenta. Una DLQ
compartida recibe una copia por consumidor.

🗣️ **2 minutos** — Cada grupo tiene sus offsets y su lógica: los dos fallaron al leer el mismo mensaje y los
dos lo mandaron a la DLQ con su encabezado `consumer`. Al reinyectar tras corregir, hay que devolver cada
copia a su grupo; reinyectar en el topic original lo entregaría a **todos** los grupos otra vez.

🔬 **El detalle** — Por eso muchos equipos usan una DLQ por consumidor (`orders.events.inventory.dlq`) o
reinyectan en un topic de reintentos propio del grupo. La DLQ compartida es más simple y exige el
encabezado.

**06 → 8.** ¿Qué te da Go con `franz-go` para consumir con commit manual, y qué escribes tú? 🟡

⏱️ **30 segundos** — Grupos, reparto de particiones, `DisableAutoCommit` y `CommitRecords`, y un productor
síncrono. Escribes el bucle, el inbox, la DLQ y qué hacer con cada error.

🗣️ **2 minutos** — `franz-go` es Go puro, sin cgo, y expone el modelo de Kafka con poca ceremonia:
`PollFetches` devuelve registros y errores por partición, y tú decides cuándo confirmar. En ≈ 100 líneas
quedan a la vista las decisiones que en Spring viven en `AckMode` y en un `ErrorHandler`.

🔬 **El detalle** — Las alternativas en Go son `segmentio/kafka-go` (más simple, menos completa) y
`confluent-kafka-go` (sobre librdkafka, con cgo). La elección suele ir por el despliegue: sin cgo el binario
es estático.

**06 → 9.** Con el modo `direct` y la caída, el cliente recibió `503` y el pedido existe. ¿Qué ve cada parte y qué haría falta para recuperarlo? 🟠

⏱️ **30 segundos** — El cliente cree que no se creó; `orders` tiene un pedido confirmado con stock
reservado; los consumidores no saben nada. Recuperarlo exige reconciliar la base con el log.

🗣️ **2 minutos** — Hay dos daños: el evento perdido y la respuesta perdida. El cliente, si reintenta con la
misma `Idempotency-Key`, recibirá el pedido que sí se creó (la idempotencia se guardó en la misma
transacción). El evento no tiene quien lo reenvíe: haría falta un proceso que compare pedidos con eventos
publicados, que es reinventar el outbox a posteriori.

🔬 **El detalle** — Con el outbox, el mismo corte deja la fila pendiente y se publica al volver: los dos
daños se reducen a uno (la respuesta perdida), y ese lo arregla la clave de idempotencia.

**06 → 10.** `payments` anula pagos por estado, que ya es idempotente. ¿Por qué pasa también por el inbox? 🟠

⏱️ **30 segundos** — Porque la idempotencia por estado depende de la forma del efecto, y el efecto cambia.
El inbox es la garantía que no depende de ella.

🗣️ **2 minutos** — Hoy `PENDING` → `VOIDED` es seguro de repetir. Mañana alguien añade "y avisa al proveedor
de la anulación" y el efecto deja de serlo sin que nadie lo note. Con el inbox, la segunda entrega no llega
al efecto, sea cual sea.

🔬 **El detalle** — La idempotencia natural sigue valiendo como segunda defensa: si el inbox se poda antes de
tiempo y llega un duplicado muy tardío, el estado lo absorbe.

**06 → 11.** ¿Qué pasaría con `sales` si reconstruyes el consumidor desde el offset 0, con y sin inbox? 🟠

⏱️ **30 segundos** — Sin inbox, se sumaría todo otra vez: el doble. Con inbox y sin vaciar nada, no se
sumaría nada: todos los eventos constan como aplicados. Para reconstruir hay que vaciar `sales` **y** el
inbox del consumidor.

🗣️ **2 minutos** — Reconstruir una proyección es recalcularla desde el log. El inbox la protege de
duplicados, y por eso también bloquea la reconstrucción si no se vacía con ella. Lo correcto es tratar
proyección e inbox como una unidad.

🔬 **El detalle** — Solo se puede reconstruir si el log conserva toda la historia (retención suficiente o
*compaction* con clave adecuada) y si cada evento lleva todo lo que la proyección necesita. Es la lección
del curso hexagonal con `orders_summary`.

**06 → 12.** ¿Por qué recrear un topic con los consumidores vivos rompió a los dos, y qué cambiaste en el laboratorio? 🔴

⏱️ **30 segundos** — Porque el topic recreado tiene otro ID y los consumidores seguían pidiendo el viejo
(`UNKNOWN_TOPIC_ID`). La siembra ya no toca Kafka; `seed --kafka` lo hace con los consumidores parados.

🗣️ **2 minutos** — En Kafka 4 los topics tienen identidad propia. `franz-go` se quedó pidiendo el ID viejo
en bucle; el consumidor de `payments` murió dentro de una tarea de fondo sin registrarlo. Además de separar
la siembra, la tarea de Python registra ahora si muere.

🔬 **El detalle** — En producción el equivalente es borrar y recrear un topic "para limpiarlo": los
consumidores activos quedan en un estado indefinido. Se limpia con retención o con un topic nuevo y una
migración de consumidores.

**06 → 13.** Dibuja el recorrido de un `OrderPaid` desde el `UPDATE` del pedido hasta la suma en `sales`, y marca los tres puntos donde puede duplicarse o perderse. 🔴

⏱️ **30 segundos** — Transacción del pago con el outbox, publicador, topic, consumidor con inbox y commit
del offset. Se duplica entre envío y marca, y entre efecto y commit; se perdería si se publicara fuera de
la transacción.

🗣️ **2 minutos** —

```text
tx { order.status = PAID ; INSERT outbox_events }          (1) sin outbox: perder aquí
   │
OutboxPublisher: send(key=orderId).get() ; published_at    (2) caída entre send y marca → duplicado
   │
orders.events, partición por orderId
   │
inventory: tx { INSERT processed_messages ; sales += n }   (3) caída entre efecto y commit → re-entrega
   │                                                           el inbox absorbe (2) y (3)
CommitRecords
```

🔬 **El detalle** — Lo que preguntarán después: ¿y si el consumidor falla siempre con ese evento? DLQ tras N
intentos. ¿Y el orden entre pedidos? No existe ni hace falta. ¿Y si el evento no trae las líneas? El
consumidor tendría que llamar a `orders`, y la proyección deja de ser reconstruible.

**06 → 14.** En producción, un contador alimentado por eventos va por encima de lo que dice la base de origen. Da tres hipótesis en orden de probabilidad y qué mirarías para cada una. 🔴

⏱️ **30 segundos** — Duplicados sin deduplicar (sin inbox, o inbox fuera de la transacción), una
reconstrucción desde el offset 0 sin vaciar la proyección, o eventos emitidos para cambios que luego se
deshicieron.

🗣️ **2 minutos** —

```text
1. Re-entregas sin inbox         el mismo eventId aplicado dos veces; caídas o repartos del grupo
                                 en esas horas (lag, rebalances)
2. Reprocesado desde el principio  reajustes de offset del grupo; el contador duplicado por un factor exacto
3. Hechos de cambios revertidos   publicación fuera de la transacción del cambio: eventos sin fila
                                 correspondiente en la base de origen
```

🔬 **El detalle** — La comprobación que las distingue es la conciliación por `eventId`: contar eventos
aplicados frente a eventos distintos en el log. Si coinciden y aun así el contador no cuadra, el problema
está en el origen (hipótesis 3), no en el consumidor.

## Ejercicios

**06 → E1.** 🟢 Crea tres pedidos, págalos y comprueba con `kafka tail` que los hechos de cada pedido están en una sola partición y en orden. Pega la salida.

⏱️ **30 segundos** — Cada `orderId` aparece con `OrderPlaced` y después `OrderPaid`, siempre en la misma
partición y con offsets crecientes.

🗣️ **2 minutos** — `kafka tail` imprime partición, offset, encabezados y clave. Agrupando por clave, cada
pedido tiene sus dos hechos juntos; entre pedidos, las particiones se mezclan. Con tres particiones y tres
pedidos, lo normal es verlos repartidos, aunque dos pueden coincidir.

🔬 **El detalle** — Si un pedido apareciera en dos particiones, la clave no se estaría enviando: es el fallo
que el curso hexagonal provocó con `--unkeyed`.

**06 → E2.** 🟢 **Orientación en código ajeno.** Encuentra, con ruta y línea, dónde decide `payments` que un error es transitorio y lo reintenta, y dónde decide que es venenoso y lo aparta.

⏱️ **30 segundos** — `payments/app/consumer.py`, función `handle`: el `except (ValueError, KeyError)` de la
línea 46 lo aparta a la DLQ sin reintentar (línea 48); el `except Exception` de la línea 52 lo trata como
transitorio y reintenta con espera creciente hasta `MAX_ATTEMPTS` (línea 18).

🗣️ **2 minutos** — La clasificación es por tipo de excepción: no poder leer el JSON o que falte un campo no
mejora reintentando; un error de la base sí puede. Tras tres intentos fallidos, también va a la DLQ (línea
56), con el motivo `max attempts`.

🔬 **El detalle** — El orden de los `except` importa: `ValueError` va antes que `Exception`, o todo sería
transitorio (`JSONDecodeError` es subclase de `ValueError`). Y leyendo con atención aparece un hueco: el
envío de la línea 56 no lleva el encabezado `consumer`, así que esa copia no se puede devolver a su grupo
sin adivinar de dónde vino.

**06 → E3.** 🟡 Mata `orders` con `kill -9` justo después de un pago (en modo `outbox`) y demuestra que el `OrderPaid` sale al reiniciar. ¿Puede salir dos veces? ¿Cómo lo verías?

⏱️ **30 segundos** — La fila queda en `outbox_events` con `published_at` vacío y el publicador la envía al
volver. Puede salir dos veces si la caída ocurre entre el envío y la marca.

🗣️ **2 minutos** — Con el publicador cada 200 ms, la ventana es corta pero real. Un duplicado se ve en
`kafka tail` como dos registros con el mismo `eventId`, y en el log del consumidor como un `already applied,
skipped`.

🔬 **El detalle** — Para provocarlo a voluntad haría falta un caos en el publicador (morir tras el `get()` y
antes del `UPDATE`), igual que el del consumidor.

**06 → E4.** 🟡 Añade al evento un campo nuevo (`channel`) y comprueba que los dos consumidores lo ignoran sin romperse. Luego renombra `lines` a `items`: ¿qué hace cada consumidor y por qué uno de los dos falla en silencio?

⏱️ **30 segundos** — El campo nuevo se ignora en los dos (lector tolerante). Al renombrar, `payments` no
usa las líneas y sigue igual; `inventory` deja de sumar **sin error**, porque `json.Unmarshal` deja el
campo vacío.

🗣️ **2 minutos** — El lector tolerante hace compatibles los cambios aditivos y esconde los que rompen: un
campo que desaparece llega como vacío, y "vacío" es un valor válido. `inventory` aplica un `OrderPaid` sin
líneas y suma cero.

🔬 **El detalle** — La defensa es validar lo obligatorio al leer (sin líneas → DLQ) y versionar el evento
(`version: 2`) con convivencia, o un registro de esquemas que rechace el cambio antes de publicarlo
([`03/05`](../03-datos-y-consistencia/05-evolucion-de-esquema-y-migraciones.md)).

**06 → E5.** 🟠 Reajusta el grupo `inventory` al offset 0 (`kafka-consumer-groups.sh --reset-offsets --to-earliest`), vacía `sales` y reinicia el consumidor con inbox. ¿Qué pasa y qué tendrías que vaciar además?

⏱️ **30 segundos** — Nada se vuelve a sumar: el inbox dice que todos los eventos ya se aplicaron. Hay que
vaciar también `processed_messages` del consumidor `inventory`.

🗣️ **2 minutos** — El reajuste solo se puede hacer con el grupo inactivo (consumidor parado). Tras vaciar
`sales` y el inbox, el consumidor recalcula desde el principio y el resultado coincide con los pedidos
pagados, siempre que el log conserve toda la historia.

🔬 **El detalle** — Si los contadores se habían duplicado por la provocación sin inbox, esta reconstrucción
los corrige: es la forma de reparar una proyección, en vez de un `UPDATE` a mano.

**06 → E6.** 🟠 Escribe una orden `lab.py kafka replay-dlq` que reinyecte en `orders.events` los mensajes de la DLQ de un consumidor concreto. ¿Qué riesgo tiene reinyectar para todos?

⏱️ **30 segundos** — Lee la DLQ, filtra por el encabezado `consumer` y produce en `orders.events`. El riesgo:
todos los grupos vuelven a recibir esos mensajes, también los que ya los habían procesado bien.

🗣️ **2 minutos** — Con inbox, los grupos que ya los aplicaron los saltan; sin él, duplican. Por eso lo
limpio es reinyectar en un topic de reintentos propio del consumidor, y que solo ese consumidor lo lea.

🔬 **El detalle** — Reinyectar cambia el orden: el mensaje vuelve detrás de otros del mismo pedido. Para
hechos que dependen del orden, la reinyección necesita lógica (descartar si ya hay un hecho posterior).

**06 → E7.** 🔴 Sustituye el publicador por CDC con Debezium leyendo `outbox_events` del WAL de PostgreSQL. ¿Qué desaparece del código de `orders` y qué aparece en la operación?

⏱️ **30 segundos** — Desaparecen el `OutboxPublisher`, el sondeo y la columna `published_at`; aparecen Kafka
Connect, el conector de Debezium, un slot de replicación en PostgreSQL y su vigilancia.

🗣️ **2 minutos** — Debezium lee el log de la base y publica cada fila insertada en el outbox (con su
*outbox event router* elige topic y clave). La latencia baja y la base deja de recibir sondeos. A cambio, un
slot de replicación que no avanza retiene WAL hasta llenar el disco.

🔬 **El detalle** — Es la comparación de `03/04` §⚖️: sondeo o CDC. El sondeo es código propio y simple; el
CDC es infraestructura potente con su propio modo de fallar.

**06 → E8.** 🔥 Arranca dos instancias de `inventory` y observa el reparto de particiones con `kafka groups`. Mata una y cronometra el *rebalance*.

⏱️ **30 segundos** — Tres particiones entre dos miembros: dos y una. Al matar una con `kill -9`, sus
particiones pasan a la otra tras `session.timeout.ms`; con `Ctrl+C`, al instante.

🗣️ **2 minutos** — La segunda instancia necesita otro puerto HTTP y gRPC (`-addr`, `-grpc`). `kafka groups`
muestra el `CONSUMER-ID` de cada partición. El tiempo del reparto tras una muerte abrupta es el plazo de
detección, no el del reparto en sí.

🔬 **El detalle** — Una tercera instancia recibiría una partición; una cuarta, ninguna: el paralelismo máximo
del grupo es el número de particiones.

---

# 07 — Observabilidad de extremo a extremo

## Preguntas

**07 → 1.** ¿Qué es un span y qué es una traza? Pon un ejemplo de este taller. 🟢

⏱️ **30 segundos** — Un span es una operación con inicio, duración, atributos y un padre; una traza es el
árbol de spans que comparten un `trace_id`. El pago del taller es una traza de 35 spans en cuatro
servicios.

🗣️ **2 minutos** — En la traza del pago, el span de Envoy es el padre del de `orders`; de él cuelgan el
`POST` a `payments` (que tiene su propio span de servidor y, debajo, el `POST` al PSP), el `Commit` gRPC a
`inventory` y, más tarde, el span de productor de Kafka con los dos consumidores como hijos. Cada span dice
de qué tipo es —servidor, cliente, productor, consumidor, interno— y eso permite leer quién esperó a quién.

🔬 **El detalle** — El padre de un span no tiene por qué estar en la traza que ves: el de Envoy tenía como
padre el span del cliente (`lab.py`), que no exporta a ningún sitio. Jaeger lo marca como padre ausente, y
cualquier lógica que dependa de "la raíz" tiene que contar con eso.

**07 → 2.** ¿Qué es `traceparent` y qué lleva cada uno de sus cuatro campos? 🟢

⏱️ **30 segundos** — El encabezado de W3C Trace Context que lleva el contexto de una traza entre procesos:
versión, `trace-id`, `parent-id` y banderas, separados por guiones.

🗣️ **2 minutos** — `00-f2ab22c7eba7cde2b9507e0554c0df7a-c337c719408f2b49-03`: versión `00`; `trace-id` de
16 bytes en hexadecimal, común a toda la traza; `parent-id` de 8 bytes, el span que envía, que será el
padre del que recibe; y las banderas, donde el bit bajo dice si la traza está muestreada. Es el mismo
formato en HTTP, en metadatos gRPC y en encabezados de Kafka.

🔬 **El detalle** — El agente de Java emitía `03`: muestreada y con el bit de "id aleatorio" del nivel 2
de la norma, que avisa de que el `trace-id` sirve para muestrear por hash. `tracestate` es el encabezado
compañero, para datos propios de cada proveedor.

**07 → 3.** ¿Qué instrumentó el agente de Java sin tocar código, y qué hubo que escribir igualmente? 🟢

⏱️ **30 segundos** — Servidor HTTP, clientes HTTP y gRPC, JDBC, Hibernate, Kafka y `@Scheduled`, y el
`trace_id` en el MDC. Hubo que escribir la propagación del contexto a través del outbox y el patrón de log.

🗣️ **2 minutos** — El agente reescribe las clases de las bibliotecas al cargarlas: no hay dependencias ni
código de instrumentación en `orders` ni en el monolito. Pero solo conoce el hilo en el que corre: el
publicador del outbox envía en otro hilo y más tarde, y ahí el contexto correcto no existe. Esas ≈ 40
líneas (inyectar en la fila, extraer y `makeCurrent()` al enviar) son la parte que ningún agente puede
adivinar.

🔬 **El detalle** — Para esas líneas basta `opentelemetry-api`, con la versión del BOM de Boot (1.62.0),
que el agente implementa en tiempo de ejecución (trae la 1.65.0). Sin agente, la API es un *no-op* y el
código sigue funcionando: `trace_context` queda vacío.

**07 → 4.** ¿Para qué sirve el collector si los servicios podrían mandar directo a Jaeger? 🟡

⏱️ **30 segundos** — Para que los servicios no conozcan el backend y para tener un solo sitio donde
muestrear, filtrar y cambiar de destino. En el taller, ahí vive el muestreo por cola.

🗣️ **2 minutos** — Los tres servicios y Envoy hablan OTLP con el collector. Cambiar Jaeger por otro backend,
o mandar a dos a la vez, es editar un archivo, no redesplegar tres servicios en tres lenguajes. Y el
collector puede hacer lo que un SDK no: decidir con la traza completa, que llega en trozos desde procesos
distintos.

🔬 **El detalle** — En producción suele haber dos capas: un collector por nodo (agente) que recibe de los
pods, y un grupo central (gateway). El muestreo por cola exige que todos los spans de una traza lleguen a la
misma instancia: se enruta por `trace_id` con el exportador `loadbalancing`.

**07 → 5.** ¿Por qué la traza se cortaba en Kafka si el mensaje sí llevaba `traceparent`? 🟡

⏱️ **30 segundos** — Porque llevaba el de la ronda del planificador que lo publicó, no el de la petición
que lo originó; y porque los consumidores no lo leían.

🗣️ **2 minutos** — El agente inyecta en el mensaje el contexto actual del hilo que envía. Con el outbox, ese
hilo es el de `@Scheduled`, y su contexto es un span `OutboxPublisher.publish` de una traza propia.
`kafka tail` lo mostró: el `OrderPaid` del pago `3bb6be58…` viajó con `traceparent` `f2ab22c7…`. Al otro
lado, los consumidores abrían cada mensaje como raíz. Tres trazas donde debía haber una.

🔬 **El detalle** — Es el matiz a `04/04` §4, que dice que la traza se corta porque el mensaje no lleva
encabezados. Con instrumentación automática, lo más probable es que lleve uno válido y equivocado: el
síntoma no es un hueco, es una traza que cuenta otra historia.

**07 → 6.** ¿Por qué no basta con corregir solo el productor, ni solo los consumidores? 🟡

⏱️ **30 segundos** — Solo el productor: el mensaje lleva el contexto correcto y nadie lo lee. Solo los
consumidores: leen el contexto equivocado y se cuelgan de la ronda del planificador.

🗣️ **2 minutos** — Se probó cada mitad. Con solo el productor, el span de productor quedó en la traza del
pago y el consumidor aplicó el evento en otra (`15f14a22`). Con solo los consumidores, los dos
consumidores se colgaron de la ronda, que había publicado el `OrderPlaced` y el `OrderPaid` a la vez: una
traza que mezcla dos peticiones. Propagar es un contrato de dos lados.

🔬 **El detalle** — La mitad "solo consumidores" es la peligrosa: parece que funciona. En una revisión, la
pregunta es "¿de qué traza es el `traceparent` que sale del outbox?", y se responde mirando el mensaje, no
la interfaz de trazas.

**07 → 7.** ¿Qué te dice la traza de un pago con `payments` caído que no te diga su log? 🟡

⏱️ **30 segundos** — Cuánto pesó cada intento y cada espera en la latencia que vio el cliente, y que todo
eso pasó dentro de una sola petición.

🗣️ **2 minutos** — El log de `orders` dice "retry 1 after 102 ms", "retry 2 after 407 ms" y el error final.
La traza pone los tres `POST` fallidos en una línea de tiempo: 5 ms, 116 ms y 537 ms desde el inicio, y
560 ms en total. Se ve que casi todo el tiempo fue espera de *backoff*, no trabajo, y que Envoy devolvió el
`503` que le dio `orders` sin reintentar.

🔬 **El detalle** — Lo contrario también vale: el log tiene el mensaje de la excepción completo; la traza,
solo su tipo (`java.io.IOException`). Se usan juntos, y por eso el `trace_id` en cada línea.

**07 → 8.** ¿Por qué apagar la instrumentación de `@Scheduled` empeoró el ruido en vez de quitarlo? 🟡

⏱️ **30 segundos** — Porque lo que colgaba de ese span —el `SELECT` y el commit de cada ronda— se quedó sin
padre y cada uno abrió su propia traza: dos por ronda en vez de una.

🗣️ **2 minutos** — Un span sin padre en el contexto se convierte en raíz. Apagar una instrumentación no
apaga las que cuelgan de ella; las huérfana. La forma de quitar ruido es decidir qué trazas se guardan
(muestreo), no quitar eslabones.

🔬 **El detalle** — Otra salida es la contraria: un muestreador en el propio proceso que descarte las trazas
cuya raíz es `OutboxPublisher.publish`, antes de exportarlas. Ahorra red y CPU, pero es muestreo por cabeza
y no puede saber si la ronda publicó algo.

**07 → 9.** Muestreo por cabeza y por cola: ¿cuál usa el laboratorio, por qué, y qué cuesta? 🟠

⏱️ **30 segundos** — Por cola, en el collector: decide con la traza entera si guardarla. Cuesta retener
cada traza 5 s en memoria y que todos sus spans lleguen al mismo collector.

🗣️ **2 minutos** — Por cabeza, la decisión se toma al crear el primer span y viaja en las banderas de
`traceparent`: barato y consistente, pero ciego a lo que pasará. El taller necesitaba saber si la traza
entró por Envoy o pasó por Kafka, y eso solo se sabe al final. El precio: memoria en el collector,
`decision_wait` de latencia antes de ver la traza, y los servicios exportan todo aunque luego se descarte.

🔬 **El detalle** — En producción se combinan: cabeza al 100 % o a un porcentaje alto para no perder
contexto, y cola para quedarse con los errores, las lentas y una muestra del resto. Con varios collectors,
el exportador `loadbalancing` por `trace_id` es obligatorio.

**07 → 10.** ¿Por qué la primera política de muestreo perdía justo las trazas de los clientes que mandaban su propio `traceparent`? 🟠

⏱️ **30 segundos** — Porque guardaba las trazas por su span raíz, y cuando el cliente abre la traza, el span
de Envoy tiene padre: en lo que llega al collector no hay raíz.

🗣️ **2 minutos** — `IsRootSpan() and name != …` exige un span sin padre. Con `lab.py buy`, el padre del
span de Envoy es el del cliente, que no se exporta. Con la corrección de Kafka puesta, la traza se salvaba
por la otra política (tenía un span de productor); en la provocación, sin él, desaparecía entera. Se cambió
a decidir por contenido: tiene un span de Envoy o uno de Kafka.

🔬 **El detalle** — Es el caso normal detrás de un CDN, de otro equipo o de un socio que ya instrumenta: la
traza empieza fuera de tu sistema. Algunos gateways dejan de confiar en el `traceparent` externo y abren
uno nuevo, enlazado (*span link*) al del cliente.

**07 → 11.** En la primera petición, `Hold` tardó 382 ms en el cliente y 12 ms en el servidor. ¿Dónde se fue la diferencia, y cómo lo confirmarías? 🟠

⏱️ **30 segundos** — En establecer la conexión del canal gRPC —TCP, HTTP/2, a través de Toxiproxy— antes
de que el servidor recibiera nada. Se confirma viendo que en la segunda llamada la diferencia desaparece.

🗣️ **2 minutos** — El span de cliente empieza cuando `orders` llama al *stub*; el de servidor, cuando
`inventory` recibe la petición. Lo que queda entre los dos es red y conexión. En las peticiones siguientes
el cliente tardó 6 ms y el servidor 4: el canal ya estaba abierto. El primer envío a Kafka (405 ms frente
a 8–11) es el mismo fenómeno con los metadatos del topic.

🔬 **El detalle** — Para separar conexión de red sin adivinar, los clientes pueden emitir eventos dentro
del span (conexión abierta, primer byte). Y la solución de producción es calentar antes de recibir
tráfico: abrir los canales al arrancar y no declararse listo hasta entonces.

**07 → 12.** ¿Por qué no hay span de servidor del PSP en la traza del pago, y qué harías si el problema estuviera ahí? 🟠

⏱️ **30 segundos** — Porque el PSP es un tercero que no exporta a tu collector. Solo tienes tu span de
cliente: cuánto tardó y qué respondió.

🗣️ **2 minutos** — `payments` inyecta `traceparent` en la llamada, pero nadie al otro lado lo usa. Si el
problema está en el PSP, tu evidencia es la distribución de duraciones de ese span de cliente y sus
códigos; con el `trace_id` y la clave de idempotencia puedes pedir al proveedor que busque tu petición.

🔬 **El detalle** — Por eso conviene mandar al tercero un identificador que él registre (la
`Idempotency-Key`, o el propio `trace_id` en un encabezado suyo), y medir su latencia como SLI propio, con
alerta, en vez de descubrirla en las trazas.

**07 → 13.** Un cliente dice "mi pago de ayer a las 10:14 tardó 8 s". Describe paso a paso cómo lo investigas con lo que montó este taller, y qué te falta. 🔴

⏱️ **30 segundos** — Encontrar la petición en el access log de Envoy por hora y ruta, tomar su `trace`, abrir
la traza y ver qué span se comió los 8 s; luego los logs por ese `trace_id`. Falta retención: Jaeger en
memoria ya no la tiene.

🗣️ **2 minutos** —

```text
1. Envoy access log   10:14 (¡en UTC, 15:14!) POST …/payment → 8xxx ms  → trace=…
2. lab.py trace ID    ¿qué span ocupa el tiempo? ¿reintentos? ¿espera de pool? ¿PSP?
3. logs por trace_id  el mensaje completo de cada error
4. si no hay traza    el muestreo la descartó, o la retención la borró: métricas de latencia
                      de esa hora para saber si fue un caso o una tendencia
```

🔬 **El detalle** — Lo que falta: retención de días (almacenamiento persistente), una política que guarde
siempre las trazas lentas (ejercicio 5), métricas para saber si 8 s es un caso o el p99, y que el cliente
reciba el `trace_id` en la respuesta de error para no buscar por hora.

**07 → 14.** Diseña la observabilidad del outbox en producción —trazas, métricas y alertas— sabiendo que el sondeo hace cinco rondas por segundo en cada instancia. 🔴

⏱️ **30 segundos** — Trazas: el contexto en la fila y ninguna traza por ronda vacía. Métricas: filas
pendientes, edad de la más antigua y retraso publicación–commit. Alertas: sobre la edad, no sobre los
errores.

🗣️ **2 minutos** —

```text
trazas     contexto en outbox_events.trace_context; rondas vacías descartadas (muestreo o sin span)
métricas   outbox_pending (gauge) · outbox_oldest_age_seconds · outbox_publish_delay (histograma)
           · outbox_send_errors_total · lag de los grupos consumidores
alertas    oldest_age > 60 s durante 5 min (el publicador está parado o el broker no acepta)
           · lag creciendo 10 min (un consumidor no avanza)
```

🔬 **El detalle** — La edad del pendiente más antiguo es la métrica que detecta todos los fallos del
publicador a la vez —caído, bloqueado o rechazado— sin enumerarlos. Y el retraso publicación–commit que
en el taller se leyó en las trazas (7–208 ms) es un histograma barato de emitir.

**07 → 15.** En producción, desde el último despliegue de `orders`, las trazas de los pagos terminan en el `Commit` de `inventory` y los consumidores de `OrderPaid` aparecen en trazas sueltas. Da tres hipótesis en orden de probabilidad y qué mirarías para cada una. 🔴

⏱️ **30 segundos** — Como solo cambió `orders`, sospecho primero del productor: que la fila del outbox ya
no guarde el contexto, o que el publicador envíe fuera del contexto restaurado. Y en tercer lugar, que
los consumidores hayan dejado de extraerlo.

🗣️ **2 minutos** — Cada hipótesis deja una huella distinta en el mensaje:

```text
1. La fila no guarda el contexto          trace_context nulo en las filas nuevas de outbox_events;
   (refactor del outbox, flag apagado)    el traceparent del mensaje es el de una ronda
2. El envío sale fuera del contexto       trace_context correcto en la fila, pero el mensaje lleva
   (makeCurrent movido o quitado)         el traceparent de la ronda del planificador
3. Los consumidores no extraen            el traceparent del mensaje es el del pago, y aun así el
   (configuración, encabezado renombrado) span de consumidor sale como raíz
```

La pista del enunciado —empezó con el despliegue de `orders`— ordena las tres: las dos primeras están en
el código que cambió.

🔬 **El detalle** — La comprobación que separa las hipótesis es leer el encabezado del mensaje con
`kafka tail` y compararlo con la columna de la fila: es exactamente la lectura de §7, y la de §8 para el
caso "solo una mitad corregida". Para que no vuelva a pasar, una prueba que publique con un `traceparent`
conocido y afirme que el span de productor cuelga de él; y una alerta sobre la proporción de spans de
consumidor sin padre, que sube en cuanto la cadena se rompe.

## Ejercicios

**07 → E1.** 🟢 Lanza `lab.py buy --then cancel`, abre la traza de la cancelación en la interfaz de Jaeger (`http://localhost:26686`) y en `lab.py trace`, y encuentra su `trace_id` en los logs de `payments` y de Envoy. Pega las cuatro salidas.

⏱️ **30 segundos** — La traza tiene Envoy, `orders`, el `Release` gRPC a `inventory` y, ≈ 100 ms después,
el productor con los dos consumidores; `payments` anota `OrderCancelled … voided` con el mismo trace.

🗣️ **2 minutos** — En la interfaz se busca por el id completo; en los logs de Python, por sus 8 primeros
caracteres; en el de Envoy, por el id entero y teniendo en cuenta que su hora está en UTC. En la corrida
del taller, `payments` escribió `[trace=0c2ac916] OrderCancelled 23aaae0d order=314476a7 → 0 pending
payment(s) voided`.

🔬 **El detalle** — El consumidor de `payments` es el único que hace algo con `OrderCancelled`; el de
`inventory` abre un span de 0 ms y lo ignora. En la traza se ve ese abanico: un hecho, dos grupos, dos
decisiones.

**07 → E2.** 🟢 **Orientación en código ajeno.** Encuentra, con ruta y línea, dónde se fija el nombre del servicio (`service.name`) en cada una de las tres plataformas, y dónde se elige el propagador W3C.

⏱️ **30 segundos** — Java: fuera del código, en la variable `OTEL_SERVICE_NAME` que pone `lab.py`. Go:
`telemetry.Setup(ctx, "inventory", …)` en `cmd/inventory/main.go`, línea 48. Python:
`telemetry.setup("payments")` en `app/main.py`, línea 36.

🗣️ **2 minutos** — El propagador: en Go, explícito en `telemetry.go`, línea 39
(`propagation.TraceContext{}`); en Java y Python, el de W3C (con *baggage*) es el que viene por defecto
—el agente lo configura con `OTEL_PROPAGATORS`, que no se toca—.

🔬 **El detalle** — Si una plataforma usara otro formato (B3 de Zipkin, por ejemplo), la traza se cortaría
en esa frontera sin ningún error: cada lado vería un encabezado que no entiende. Fijar el propagador es
parte del contrato entre equipos.

**07 → E3.** 🟡 Añade spans de base de datos a `inventory` (con `otelpgx` o con un `pgx.QueryTracer` propio) y compara la traza de `Hold` antes y después.

⏱️ **30 segundos** — `pgx` acepta un `QueryTracer` en la configuración del pool; con él, cada consulta
abre un span hijo del `ctx` que recibe. Después, bajo `Hold` aparecen las consultas y su duración.

🗣️ **2 minutos** — `cfg.ConnConfig.Tracer = otelpgx.NewTracer()` antes de crear el pool, o una
implementación propia de `TraceQueryStart`/`TraceQueryEnd` que abra y cierre un span. Funciona porque el
servidor gRPC ya pasa un `ctx` con el span de servidor a `store`. Antes: un span de 4 ms opaco; después, se
ve si el tiempo es la consulta, el bloqueo de fila o el commit.

🔬 **El detalle** — Es la provocación de `06/04` vista desde dentro: con `lock-stock`, el span del
`SELECT … FOR UPDATE` crece y el resto no, y la causa deja de ser una deducción.

**07 → E4.** 🟡 Cambia los logs de `payments` a JSON con `trace_id` y `span_id` completos. ¿Por qué el taller los recorta a 8 caracteres y por qué en producción no se hace?

⏱️ **30 segundos** — Un formateador JSON con los campos del filtro. El taller recorta para que las salidas
quepan en la página; en producción el id completo es la clave de unión con el backend de trazas.

🗣️ **2 minutos** — El filtro ya pone `trace_id` en cada registro; basta con cambiar el formato a un
`json.dumps` de los campos (o `python-json-logger`) y guardar el id entero y el `span_id`. Con 8
caracteres hay colisiones en cuanto hay volumen, y ningún backend busca por prefijo.

🔬 **El detalle** — `opentelemetry-instrumentation-logging` hace lo mismo que el filtro del taller
(`otelTraceID`, `otelSpanID`) y, con el exportador de logs, puede mandar los logs al collector por OTLP,
unidos a la traza sin parsear texto.

**07 → E5.** 🟡 Añade una tercera política de muestreo que guarde toda traza con error o de más de 1 s, y demuéstrala con `payments` parado y con un pago de `666.00`.

⏱️ **30 segundos** — Dos políticas más en `tail_sampling`: `status_code` con `ERROR` y `latency` con
`threshold_ms: 1000`. El pago con `payments` parado tiene spans en error; el de `666.00`, más de 1 s.

🗣️ **2 minutos** — Hoy esas trazas se guardan igual porque entran por Envoy, así que la prueba útil es
quitar antes la política del gateway y comprobar que las de error y las lentas se quedan y las normales
no. Es el muestreo de producción: poco de lo normal, todo lo raro.

🔬 **El detalle** — Con `666.00`, `payments` corta al PSP a los 2 s y deja el pago `PENDING`: el span de
cliente hacia el PSP acaba en error (el *timeout*), pero la petición del cliente no, porque `PENDING` es una
respuesta válida. Una política que mirara solo el código HTTP del span de Envoy la perdería; la de latencia
y la de estado de **cualquier** span la guardan, y es justo la que un cliente reclama.

**07 → E6.** 🟠 Sustituye el adaptador `Headers` de Go por el plugin `kotel` de `franz-go`. ¿Qué dejas de escribir y qué ganas (el envío a la DLQ, por ejemplo)?

⏱️ **30 segundos** — Dejas de escribir el adaptador y el `Extract`; ganas spans de productor en el envío a
la DLQ y spans de recepción, con los atributos de las convenciones semánticas.

🗣️ **2 minutos** — `kotel` se engancha con `kgo.WithHooks(...)` en el cliente: inyecta al producir y crea
spans al recibir; `tracer.WithProcessSpan(record)` devuelve el `ctx` y el span de procesado. El envío a
la DLQ, que hoy no deja rastro en la traza, aparecería como hijo del span de consumo.

🔬 **El detalle** — El precio es otra dependencia que sigue a `franz-go` con su propio calendario, y
menos control sobre nombres y atributos. Escribirlo a mano primero sirve para saber qué hace el plugin.

**07 → E7.** 🔴 Activa las métricas del agente en `orders` (quita `OTEL_METRICS_EXPORTER=none`), llévalas al collector y a un backend de métricas, y define el SLI "pago confirmado en menos de 1 s" con su SLO.

⏱️ **30 segundos** — El agente emite `http.server.request.duration` como histograma; el collector necesita
un pipeline `metrics` hacia, por ejemplo, Prometheus. El SLI es la fracción de `POST …/payment` con `200` y
duración < 1 s.

🗣️ **2 minutos** — En el collector, un pipeline `metrics` con el receptor OTLP y un exportador (el de
Prometheus, que expone un puerto para que lo raspen). SLI = peticiones buenas / peticiones válidas, donde
buena es `200` en menos de 1 s y válida excluye los `4xx` del cliente. SLO: 99 % en 28 días, con el
presupuesto de error de `04/04` §7.

🔬 **El detalle** — Los buckets del histograma deciden si "menos de 1 s" se puede medir exactamente: hace
falta un límite en 1 s. Y un pago `PENDING` responde `200`: ¿cuenta como bueno? Es una decisión de
producto, no técnica.

**07 → E8.** 🔥 Mete 300 ms de latencia en el proxy gRPC de `inventory` (`lab.py slow inventory-grpc --latency 300`) y usa solo trazas para demostrar dónde está el tiempo, comparando el span de cliente con el de servidor.

⏱️ **30 segundos** — El span de cliente de `Hold` crece ≈ 300 ms y el de servidor no: el tiempo está entre
los dos, en la red. La traza señala a Toxiproxy sin mirar Toxiproxy.

🗣️ **2 minutos** — Es el mismo razonamiento que la pregunta 11 con otra causa. Si el servidor también
creciera, el problema estaría dentro de `inventory`; si solo crece el cliente, está en el camino. Con el
deadline de 800 ms de `orders`, 300 ms caben; con más, el span de cliente acaba en `DEADLINE_EXCEEDED` y el
de servidor quizá termine bien, que es la autopsia de `06/04`.

🔬 **El detalle** — El toxic de Toxiproxy retrasa la respuesta (`downstream`): el servidor contesta a
tiempo y la respuesta llega tarde. Sin trazas, el servidor diría "yo respondí en 4 ms" y el cliente "tardó
300": las dos cosas son verdad.

---

# 08 — Saga coreografiada

## Preguntas

**08 → 1.** ¿Por qué el contrato `v2` responde `202` y no `201`? 🟢

⏱️ **30 segundos** — Porque al responder no se ha hecho lo que se pidió: el pedido está registrado, pero
la reserva y el cobro los decide después la saga. `201` diría "creado y listo"; `202`, "aceptado, en
proceso".

🗣️ **2 minutos** — `202 Accepted` es el código que HTTP reserva para una petición aceptada cuyo
procesamiento no ha terminado. Va con un `Location` al recurso que el cliente consulta y un estado
intermedio (`PENDING`). Con `v1` el alta reservaba por gRPC en el mismo acto y podía contestar `201` o
`409`; con una reserva asíncrona, `orders` no sabe al responder si habrá stock, y fingirlo es esperar a la
saga (el 2PC con peor cara).

🔬 **El detalle** — El precio lo paga el cliente: tiene que consultar (o suscribirse) y manejar un "no"
tardío. Sin stock ya no es un `409` inmediato, es un pedido que termina `CANCELLED`. La idempotencia de
`v2` devuelve otra vez el `202` guardado, no un `200`: la respuesta repetida es la misma.

**08 → 2.** ¿Qué publica cada participante de la saga, y en qué topic? 🟢

⏱️ **30 segundos** — `orders` publica `OrderPlaced` en `orders.placed`; `inventory`, `InventoryReserved`,
`InventoryReservationFailed` e `InventoryReleased` en `inventory.reservations`; `payments`,
`PaymentAuthorized` y `PaymentRejected` en `payments.results`.

🗣️ **2 minutos** — Cada servicio publica en su propio topic, por su propio outbox, y lee los de los demás:
`inventory` lee `orders.placed` y `payments.results`; `payments`, `inventory.reservations`; `orders`,
`inventory.reservations` y `payments.results`. Además, `orders` sigue publicando `OrderPaid` en
`orders.events`, del que vive la proyección de ventas de `06/06`.

🔬 **El detalle** — Un topic por productor hace que cada uno sea dueño de su esquema, pero reparte los
hechos de un mismo pedido en tres logs sin orden entre sí. Es la causa de que `orders` tenga que tolerar
un `PaymentAuthorized` antes que su `InventoryReserved`.

**08 → 3.** ¿Qué dicen los encabezados `Deprecation` y `Sunset`, y en qué formato va cada uno? 🟢

⏱️ **30 segundos** — `Deprecation` dice desde cuándo el recurso está obsoleto; `Sunset`, cuándo dejará de
responder. El primero es una fecha de Structured Fields (`@1790640000`); el segundo, un HTTP-date
(`Wed, 31 Mar 2027 00:00:00 GMT`).

🗣️ **2 minutos** — `Deprecation` es la RFC 9745 (2025): una fecha como `@` más segundos desde 1970, que
puede estar en el pasado o en el futuro. `Sunset` es la RFC 8594 (2019), con el formato de fecha clásico
de HTTP. El taller añade `Link: </api/v2/orders>; rel="successor-version"` para decir adónde migrar.

🔬 **El detalle** — El borrador anterior a la RFC 9745 usaba `Deprecation: true` o un HTTP-date; hay
clientes y pasarelas que aún lo esperan así. Y los encabezados solo sirven si alguien los vigila: lo útil
es que el SDK del cliente o el gateway los registre como aviso.

**08 → 4.** ¿Por qué `v1` sigue en verde sin cambiar la suite? 🟢

⏱️ **30 segundos** — Porque su comportamiento no cambió: sigue reservando por gRPC y respondiendo lo
mismo. Solo se añadieron encabezados, y un cliente que no los mira no se entera.

🗣️ **2 minutos** — Añadir encabezados es un cambio compatible hacia atrás (`02/07` §2): nada que un
cliente usara desaparece ni cambia de significado. Es lo que permite convivir: los clientes viejos
funcionan mientras migran, y la suite `v1` es la prueba de que no se les ha roto nada.

🔬 **El detalle** — El coste es mantener dos implementaciones del alta —síncrona y saga— hasta la fecha de
`Sunset`. Si esa fecha no se cumple, `v1` se convierte en deuda permanente.

**08 → 5.** ¿Por qué `payments` mira el inbox antes de llamar al PSP y lo escribe después? 🟡

⏱️ **30 segundos** — Porque la llamada al PSP no puede ir dentro de la transacción. Mirar antes ahorra la
llamada si el hecho ya se procesó; escribir después, junto con el pago y el hecho, mantiene todo atómico.

🗣️ **2 minutos** — Si el inbox se marcara antes de llamar y el proceso muriera durante la llamada, la
re-entrega vería el hecho como procesado y el cobro quedaría sin registrar. Si se marca después, una
re-entrega vuelve a llamar al PSP; por eso la clave `saga-<orderId>` es la misma siempre, y el PSP
devuelve la respuesta guardada en vez de cobrar otra vez. La segunda comprobación, dentro de la
transacción (`ON CONFLICT DO NOTHING`), cubre dos entregas simultáneas.

🔬 **El detalle** — Es el patrón general de un efecto externo en un consumidor: comprobación optimista,
efecto externo idempotente por clave, y registro atómico de todo lo local. Sin un PSP idempotente, no hay
forma segura de hacerlo.

**08 → 6.** ¿Por qué `orders` acepta pasar a `PAID` desde `PENDING`, si el orden natural es `PENDING` → `CONFIRMED` → `PAID`? 🟡

⏱️ **30 segundos** — Porque `InventoryReserved` y `PaymentAuthorized` llegan por topics distintos, y entre
topics no hay orden: el pago puede llegar antes que la reserva que lo causó.

🗣️ **2 minutos** — `orders` consume `inventory.reservations` y `payments.results` con el mismo grupo, pero
son logs independientes con su propio *lag*. Si el primero va retrasado, `PaymentAuthorized` encuentra el
pedido en `PENDING`. La tabla de transiciones lo acepta, y el `InventoryReserved` tardío se ignora
("ignored: order is PAID") en vez de devolver el pedido a `CONFIRMED`.

🔬 **El detalle** — La alternativa es ordenar por construcción: un solo topic por pedido con todos sus
hechos (la clave da el orden) o un número de secuencia por pedido. Los dos cambian quién es dueño de qué
topic; en la coreografía del taller, la tolerancia se escribe en el consumidor.

**08 → 7.** ¿Por qué el pedido de 666,00 no sale nunca de `CONFIRMED`, y qué ve cada participante? 🟡

⏱️ **30 segundos** — Porque el PSP tardó más que el timeout de `payments`, que registró `PENDING` y no
publicó nada; y nadie tiene un plazo que venza. `orders` ve `CONFIRMED`, `inventory` retiene, `payments`
dice `PENDING` y el PSP cobró.

🗣️ **2 minutos** — Cada participante terminó su parte y espera un hecho que no llegará. En la coreografía
no hay un proceso cuyo trabajo sea darse cuenta. El pedido seguía igual cinco minutos después, con el
dinero cobrado y el stock bloqueado; solo un `WARNING` en `payments` lo delataba.

🔬 **El detalle** — `v1` resolvía este caso con la clave: repetir el pago volvía a preguntar al PSP
(`06/03`). En `v2` no hay nadie que repita. Hace falta un dueño con plazo —un orquestador, o una
conciliación periódica— que es exactamente lo que añade el [taller 09](09-saga-orquestada.md).

**08 → 8.** `InventoryReserved` lleva el total del pedido. ¿Por qué, y qué problema tiene? 🟠

⏱️ **30 segundos** — Porque `payments` necesita el importe para cobrar y así no tiene que preguntar a
`orders`. El problema: `inventory` transporta un dato que no es suyo.

🗣️ **2 minutos** — Es un acoplamiento escondido: `inventory` copia el `total` de `OrderPlaced` a su hecho
sin entenderlo. Si el formato del importe cambia, `inventory` tiene que cambiar aunque no use el dato.
Las alternativas: que `payments` consuma también `orders.placed` y guarde el importe (una réplica local,
con su propio acoplamiento al esquema de `orders`), o que llame a `orders` (acoplamiento temporal).

🔬 **El detalle** — En coreografía, los datos que necesita el paso N tienen que viajar desde el paso 1 o
replicarse en N. En orquestación, el orquestador los tiene y se los pasa a cada comando: es una de las
diferencias que se ven al comparar las dos versiones.

**08 → 9.** ¿Cómo detectarías un ciclo de eventos en producción sin saber de antemano dónde está? 🟠

⏱️ **30 segundos** — Por la forma de las trazas y de los contadores: una traza que no termina y crece
(miles de spans, minutos de duración), y un pedido con muchos más hechos de lo normal.

🗣️ **2 minutos** — El ciclo del taller dejó una sola traza de 9 509 spans y 148 s, con 1 188 niveles. Una
alerta por trazas de más de N spans o de más de N segundos lo detecta sin conocer el ciclo. También sirve
contar hechos por `orderId` (148 `OrderPlaced` del mismo pedido) y vigilar la DLQ, que creció en 147.

🔬 **El detalle** — Para diagnosticarlo hace falta el `causationId` en cada hecho: con él se reconstruye la
cadena y se ve que el hecho 5 causó al 1 otra vez. Una defensa estructural es un contador de saltos o una
lista de hechos causantes en la cabecera, que corta a partir de un límite.

**08 → 10.** El ciclo terminó con `orders` en `CONFIRMED` y `payments` en `REJECTED`. ¿Por qué, y qué lección general deja? 🟠

⏱️ **30 segundos** — Porque `orders` insertaba el pago con un `operationId` que se repetía en cada vuelta;
violaba la unicidad, y 147 `PaymentRejected` acabaron en la DLQ. `orders` dejó de enterarse de los
rechazos.

🗣️ **2 minutos** — El inbox deduplica por `eventId`, y cada vuelta traía un `PaymentRejected` con
`eventId` nuevo pero la misma operación de pago. El efecto (`INSERT`) no era idempotente por la clave del
negocio. La corrección es registrar el pago por `operationId`, actualizándolo si ya existe.

🔬 **El detalle** — La lección: los casos límite de una saga (repeticiones, reintentos, ciclos) prueban la
idempotencia de cada efecto de una forma que la rama feliz nunca prueba. Y una DLQ que crece en silencio
deja proyecciones inconsistentes: hay que alertar sobre ella.

**08 → 11.** ¿Por qué el consumidor de Python murió con el primer hecho de `inventory` y no con los de `orders`? 🟠

⏱️ **30 segundos** — Porque `franz-go`, el cliente de Kafka de `inventory`, comprime con snappy por
defecto, y `aiokafka` no puede descomprimir snappy sin `cramjam`. El productor de Java no comprimía.

🗣️ **2 minutos** — La compresión la decide el productor por lote, y el consumidor la tiene que soportar.
Tres lenguajes, tres clientes con valores por defecto distintos: el hecho de Go fue el primero comprimido
que leyó Python. La tarea del consumidor murió, el *done callback* lo registró, y las sagas se quedaron en
`CONFIRMED` hasta reiniciar con la dependencia.

🔬 **El detalle** — En un sistema políglota, los códecs son parte del contrato del topic: se fija uno
(`zstd` o `lz4` suelen ser la elección) y se comprueba que todos los clientes lo leen. También se puede
fijar en el broker (`compression.type` del topic), que recomprime lo que reciba.

**08 → 12.** Un cliente de `v2` dejó de consultar al ver `PAYMENT_REJECTED`, y el pedido acabó pagado. ¿Cómo es posible, y qué debe garantizar el contrato? 🔴

⏱️ **30 segundos** — Porque una regla del sistema reabrió un estado que el cliente creía final (el ciclo:
"si liberaron, reintenta"). El contrato debe garantizar que los estados finales son finales.

🗣️ **2 minutos** — Con la regla del ciclo activa, `PAYMENT_REJECTED` pasaba a `PENDING` y la compra se
repetía; si en uno de esos intentos el pago se hubiera autorizado, el pedido acabaría `PAID` sin que el
cliente lo viera. El contrato `v2` dice qué estados son finales, y `orders` tiene que hacer cumplir que
nada los mueve después.

🔬 **El detalle** — Si el negocio quiere reintentos, se modelan como un pedido nuevo o como un estado no
final explícito (`PAYMENT_RETRYING`), nunca reabriendo uno final. Es la misma regla que en las máquinas de
estados de pagos reales: lo terminal no se toca.

**08 → 13.** En una entrevista te piden elegir entre esperar a la saga antes de responder (`201`/`409` como siempre) y el `202`. Defiende una y di cuándo cambiarías de opinión. 🔴

⏱️ **30 segundos** — El `202`: no finge una atomicidad que no existe, y la latencia del alta no depende de
Kafka ni de tres consumidores. Cambiaría si el cliente no puede consultar (un sistema externo que solo
entiende una respuesta) y el flujo cabe en un tiempo acotado.

🗣️ **2 minutos** — Esperar a la saga es acoplamiento temporal disfrazado: si un consumidor va lento, el
`POST` va lento; si pasa del timeout, el cliente recibe un error de algo que quizá sí ocurrió. El `202`
expone el estado real y deja al cliente decidir cómo esperar. La tercera vía es mantener la reserva
síncrona y hacer asíncrono solo el pago, que reduce la saga y conserva el `409`.

🔬 **El detalle** — El argumento que decide suele ser el de producto: ¿puede la interfaz decir "estamos
procesando tu pedido"? Si sí, `202`. Y con `202` hay que dar al cliente algo mejor que el sondeo: un
webhook, SSE (el [taller 11](11-consultas-y-tiempo-real.md)) o al menos un `Retry-After`.

**08 → 14.** Diseña lo mínimo que habría que añadir a esta coreografía para que el pedido de 666,00 no se quede atascado, sin introducir un orquestador. ¿Qué te dice lo que te salió? 🔴

⏱️ **30 segundos** — Un plazo con dueño: un proceso que encuentre pedidos `CONFIRMED` de más de N segundos
y vuelva a preguntar al PSP con la misma clave, o compense. Lo que sale es un orquestador parcial.

🗣️ **2 minutos** —

```text
cada 30 s (en payments, o en orders):
  pedidos CONFIRMED hace > 60 s, o pagos PENDING hace > 60 s
    → repetir el cobro con la clave saga-<orderId>  (el PSP devuelve lo que pasó)
    → publicar PaymentAuthorized o PaymentRejected
    → si tras N intentos sigue sin respuesta: PaymentRejected y alerta
```

🔬 **El detalle** — Ese proceso lleva la cuenta del tiempo y de los intentos de la saga, decide el
siguiente paso y conoce el flujo entero: es un orquestador que no se llama así. Cuando la coreografía
necesita plazos, la pregunta deja de ser "¿orquestador sí o no?" y pasa a ser "¿dónde vive el que ya
estoy escribiendo?".

## Ejercicios

**08 → E1.** 🟢 Corre las tres ramas con `buy --v2` y, para cada pedido, `saga-status`. Pega las salidas y marca en qué momento coinciden las cuatro partes.

⏱️ **30 segundos** — Coinciden cuando la saga termina: `PAID` con retención `COMMITTED` y pago
`AUTHORIZED`; `CANCELLED` sin retenciones ni pago; `PAYMENT_REJECTED` con la retención `RELEASED` y el
pago `REJECTED`.

🗣️ **2 minutos** — Antes de terminar hay ventanas de desacuerdo: `CONFIRMED` en `orders` con el pago ya
autorizado en `payments`, por ejemplo, durante los ≈ 150 ms entre un hecho y su consumo. En la rama sin
stock, el PSP nunca aparece; en la feliz, el cobro sí.

🔬 **El detalle** — Si `saga-status` se lanza a mitad de saga, cada línea es verdad en su sistema y falsa
como conjunto. Es la definición operativa de consistencia eventual.

**08 → E2.** 🟢 **Orientación en código ajeno.** Sigue un `PaymentRejected` desde que se escribe hasta que el stock vuelve: da, con ruta y línea, cada punto en que se escribe en una base o en un topic.

⏱️ **30 segundos** — `payments/app/consumer.py`, línea 147 (fila en `outbox_events`); `payments/app/outbox.py`,
el envío a `payments.results`; `inventory/internal/consumer/saga.go`, `react`, caso `PaymentRejected`
(línea 65), que libera y deja `InventoryReleased` en su outbox.

🗣️ **2 minutos** — En `inventory`, la liberación es `store.ReleaseTx` (`internal/store/store.go`) dentro
de `SagaStep` (línea 233), que además inserta en `processed_messages` y en `outbox_events`; su publicador
(`internal/outbox/outbox.go`, `send`, línea 82) lleva el hecho a `inventory.reservations`. En `orders`, el
mismo `PaymentRejected` llega a `SagaListener` (línea 76): pago y estado.

🔬 **El detalle** — Son seis escrituras en tres bases y tres topics para un rechazo. Ninguna se puede
saltar sin perder atomicidad o idempotencia: es el coste real de "cada servicio reacciona".

**08 → E3.** 🟡 Haz que `payments` consuma `orders.placed` y guarde el importe de cada pedido, y quita el `total` de `InventoryReserved`. ¿Qué ganas y qué nuevo acoplamiento aparece?

⏱️ **30 segundos** — Ganas que `inventory` deje de transportar un dato ajeno. Aparece el acoplamiento de
`payments` al esquema de `OrderPlaced`, y una carrera: `InventoryReserved` puede llegar antes que el
`OrderPlaced` que `payments` necesita.

🗣️ **2 minutos** — `payments` necesita una tabla de importes por pedido, alimentada por `orders.placed`. Si
llega un `InventoryReserved` de un pedido cuyo importe aún no tiene, no puede cobrar: reintenta con
espera o lo aparta. Es otra vez la falta de orden entre topics.

🔬 **El detalle** — Las dos opciones son legítimas; la del taller elige transportar el dato para no tener
esa carrera. En orquestación el problema desaparece: el orquestador manda `AuthorizePayment` con el
importe.

**08 → E4.** 🟠 Añade un límite de reintentos a la regla del ciclo (`--saga-retry-on-release`): como mucho tres `OrderPlaced` por pedido, contados con los hechos que ya existen. ¿Dónde guardas la cuenta?

⏱️ **30 segundos** — En `orders`: contar las filas de `outbox_events` con ese `aggregate_id` y `type =
'OrderPlaced'` antes de reintentar. A partir de tres, se deja `PAYMENT_REJECTED`.

🗣️ **2 minutos** — El outbox ya es un registro de lo que `orders` publicó, así que no hace falta otra
tabla. Lo que no se puede es contarlo en memoria: con varias instancias o un reinicio, la cuenta se
pierde.

🔬 **El detalle** — Al escribirlo, `orders` empieza a "saber" cuántas veces se intentó la saga: un trozo
de estado de orquestador dentro de un participante. Es la misma conclusión que la pregunta 14.

**08 → E5.** 🟠 Haz que un estado final no se reabra: `PAID`, `PAYMENT_REJECTED` y `CANCELLED` ignoran todo hecho posterior. Vuelve a correr el ciclo y comprueba qué ve el cliente.

⏱️ **30 segundos** — `retry` y `move` comprueban primero si el estado es final. El ciclo se corta solo en
la primera vuelta: `InventoryReleased` encuentra `PAYMENT_REJECTED` y no reintenta.

🗣️ **2 minutos** — Con la regla de estados finales, la provocación deja de funcionar aunque el flag siga
activo: la regla de negocio protege del error de diseño. El cliente ve `PAYMENT_REJECTED` y ese estado es,
por fin, final.

🔬 **El detalle** — Hay un caso límite: si `InventoryReleased` llega **antes** que `PaymentRejected` a
`orders` (topics distintos), `retry` ve `CONFIRMED`, que no es final, y reintenta. La regla completa es
"no reintentar si ya hubo un `PaymentRejected` para este pedido", que exige mirar la historia, no solo el
estado.

**08 → E6.** 🟠 Añade un consumidor `shipping` que prepare el envío al ver `PaymentAuthorized`, sin tocar ningún otro servicio. ¿Qué te costó, y qué no ves ahora del flujo completo?

⏱️ **30 segundos** — Costó un consumidor con su inbox y, si publica, su outbox; nada más. Lo que no ves:
que el flujo ahora tiene un paso más que nadie documentó en `orders` ni en `payments`.

🗣️ **2 minutos** — Es la promesa de la coreografía y se cumple: extensión sin tocar a nadie. El precio
llega después: si `shipping` falla, ¿el pedido `PAID` está enviado? `orders` no lo sabe, porque no
escucha a `shipping`; la pregunta de §7 tiene ahora cinco respuestas.

🔬 **El detalle** — Si `shipping` necesita que el pedido pase a `SHIPPED`, `orders` sí tiene que cambiar
(escuchar un topic más). La extensibilidad sin tocar a nadie solo vale para pasos que no afectan al estado
que otros ven.

**08 → E7.** 🔴 Escribe una comprobación periódica que encuentre pedidos `CONFIRMED` de más de 60 s y los compare con `payments` y con el PSP. ¿Qué haces con los que encuentres, y quién es dueño de esa decisión?

⏱️ **30 segundos** — Para cada pedido: si el PSP tiene el cobro, publicar `PaymentAuthorized`; si no lo
tiene y `payments` dice `PENDING`, repetir el cobro con la clave o publicar `PaymentRejected`. El dueño
tiene que ser uno solo, y normalmente es `payments`.

🗣️ **2 minutos** — Es una conciliación: compara la verdad externa (el PSP) con la interna y emite el hecho
que falta. Con el pedido de 666,00 del taller, encontraría el cobro `psp-510f4741` y publicaría
`PaymentAuthorized`; la saga terminaría en `PAID` y la retención pasaría a vendida.

🔬 **El detalle** — Si la comprobación vive en `orders`, `orders` decide sobre pagos; si vive en
`payments`, `payments` necesita saber de pedidos. Dónde la pongas define quién es dueño de la saga: es la
pregunta del [taller 09](09-saga-orquestada.md) hecha desde dentro de la coreografía.

**08 → E8.** 🔥 Configura `inventory` para que produzca sin compresión (`kgo.ProducerBatchCompression`), quita `cramjam` de `payments` y demuestra que todo funciona. Luego elige un códec para todo el sistema y justifícalo.

⏱️ **30 segundos** — `kgo.ProducerBatchCompression(kgo.NoCompression())` en el cliente del publicador; sin
`cramjam`, `payments` vuelve a leer. Para todo el sistema, `zstd` o `lz4`, fijado en los tres productores
y comprobado en los tres consumidores.

🗣️ **2 minutos** — Sin compresión funciona y ocupa más red y disco; con mensajes pequeños como estos, la
diferencia es mínima. La decisión importante no es el códec, es que sea **uno** y esté escrito: en la
configuración de cada cliente o en `compression.type` del topic.

🔬 **El detalle** — Con `compression.type` en el topic distinto del que usa el productor, el broker
descomprime y recomprime cada lote: CPU del broker a cambio de un contrato único. Con el mismo códec en
todos, el broker guarda los lotes tal cual.

---

# 09 — Saga orquestada, comparación y autopsia

## Preguntas

**09 → 1.** ¿Qué guarda `order_sagas` que en la coreografía no existía? 🟢

⏱️ **30 segundos** — El paso en curso de cada saga, cuántas veces se intentó, desde cuándo está en él,
cuándo toca el siguiente intento y cuándo vence. Y `order_saga_log`, cada transición.

🗣️ **2 minutos** — Es el estado de la saga como dato: se consulta con una fila, no reconstruyendo hechos
de tres bases. Permite plazos (un paso que vence), reintentos con espera y escalado, y es la auditoría del
flujo. En la coreografía, ese estado solo existía repartido en las proyecciones de cada servicio.

🔬 **El detalle** — La fila se inserta en la misma transacción que el pedido: hace de outbox del
orquestador. Si el pedido existe, su saga también, aunque el proceso muera un instante después.

**09 → 2.** ¿Por qué el orquestador reclama los pasos con un *lease* en vez de mantener la fila bloqueada durante la llamada? 🟢

⏱️ **30 segundos** — Porque la llamada remota puede tardar segundos, y mantener una transacción abierta
esperando a otro servicio retiene una conexión y un bloqueo (la lección de `06/01`). El *lease* aplaza la
fila 30 s y suelta la transacción enseguida.

🗣️ **2 minutos** — `claim` hace un `UPDATE … WHERE order_id IN (SELECT … FOR UPDATE SKIP LOCKED)` que mueve
`next_attempt_at` 30 s al futuro. Ninguna otra instancia la cogerá mientras tanto. Si el proceso muere a
mitad de la llamada, a los 30 s la fila vuelve a estar vencida y otro la retoma: el taller lo vio al matar
`orders` durante un cobro.

🔬 **El detalle** — El *lease* tiene que ser más largo que la llamada más lenta (con sus reintentos
internos), o dos instancias ejecutarán el mismo paso a la vez. Por eso los comandos tienen que ser
idempotentes aunque haya *lease*.

**09 → 3.** ¿Qué paso de la saga es el pivote, y qué cambia después de él? 🟢

⏱️ **30 segundos** — La autorización del pago. Antes, todo se puede compensar (liberar la reserva);
después, no: el cliente pagó, y el resto (vender la reserva) solo se reintenta hasta que salga.

🗣️ **2 minutos** — Es el orden de `03/03` §6: compensables primero, pivote en medio, reintentables
después. `COMMIT_INVENTORY` va después del pivote; si `inventory` no responde, el orquestador reintenta,
nunca devuelve el dinero por su cuenta.

🔬 **El detalle** — Cuando el reintentable no puede salir —la reserva caducó—, no hay compensación
automática buena: el taller escala. La salida correcta (volver a reservar, o devolver el cobro) es una
decisión de negocio.

**09 → 4.** ¿Por qué `v2` no notó el cambio de coreografía a orquestación? 🟢

⏱️ **30 segundos** — Porque el contrato solo dice que el alta responde `202 PENDING` y que el pedido llega a
un estado final; quién lo lleve hasta ahí es un detalle interno.

🗣️ **2 minutos** — La suite `v2` pasó 4/4 contra `--saga choreography` y contra el orquestador, con el
mismo código y los mismos estados. Es la ventaja de haber pagado la asincronía en el contrato en `08`: el
cambio de estilo quedó detrás de él.

🔬 **El detalle** — Lo que sí cambió para el cliente es la latencia: `PAID` a ≈ 0,9 s en vez de ≈ 0,3 s,
por el sondeo del planificador. Un contrato asíncrono no promete tiempos, pero los clientes los notan.

**09 → 5.** ¿Por qué el orquestador compensa cuando `payments` no responde, pero escala cuando responde `PENDING`? 🟡

⏱️ **30 segundos** — Porque `PaymentsUnavailable` significa que es seguro que no se cobró, y liberar es
correcto; `PENDING` significa que no se sabe, y liberar podría dejar un cobro sin pedido.

🗣️ **2 minutos** — `orders` distingue desde `06/03` entre "no llegué a cobrar" (no conectó, breaker
abierto) y "no sé qué pasó" (timeout con la llamada hecha). Con lo primero, al vencer el plazo, se
compensa y se cancela. Con lo segundo se vuelve a preguntar con la misma clave; si al vencer el plazo
sigue incierto, la saga se escala a una persona con el pedido en `PAYMENT_PENDING`.

🔬 **El detalle** — Es la misma distinción que el breaker de `payments` hace con `PSP_UNAVAILABLE`. Toda
la cadena de resiliencia depende de que cada capa diga honestamente cuál de los dos fallos tuvo.

**09 → 6.** ¿Cómo resolvió el orquestador el pago de `666.00` que en la coreografía se quedaba atascado? 🟡

⏱️ **30 segundos** — Reintentando `AuthorizePayment` con la misma clave: `payments` volvió a preguntar al
PSP, que devolvió el cobro que sí había hecho. `PAID` a los 3 s.

🗣️ **2 minutos** — El primer intento volvió `PENDING` a los 2 s. El orquestador lo anotó, esperó 500 ms y
repitió. `payments` tiene la operación en `PENDING` con esa clave y vuelve a preguntar al PSP (`06/03`), que
reconoce la clave y contesta `AUTHORIZED`. La coreografía tenía todas las piezas menos una: alguien que
volviera a preguntar.

🔬 **El detalle** — Funciona porque la idempotencia está de punta a punta: la clave del orquestador es la
de `payments` y la del PSP. Sin eso, reintentar sería cobrar dos veces.

**09 → 7.** ¿Qué pasó cuando `orders` murió en mitad del cobro, y por qué la saga no se perdió? 🟡

⏱️ **30 segundos** — La API respondió `503` mientras estuvo muerto, pero la saga estaba en una tabla. Al
reiniciar, venció el *lease*, otro intento volvió a preguntar con la misma clave y la saga cerró en `PAID`.

🗣️ **2 minutos** — El estado del orquestador no vive en su memoria: `order_sagas` dice en qué paso estaba,
y el *lease* garantiza que el intento interrumpido se repite. El cobro que el PSP ya había hecho se
recuperó por la clave, sin duplicarse.

🔬 **El detalle** — En la primera corrida, con la reserva caducando a 30 s, la saga se retomó a los 31 y
acabó escalada. Un orquestador que sobrevive a su caída sigue necesitando que los plazos de los demás
sean compatibles con su tiempo de recuperación.

**09 → 8.** ¿Por qué la fila de la saga violaba la clave foránea, si el pedido se guardaba antes en el código? 🟡

⏱️ **30 segundos** — Porque `save` de JPA no escribe hasta el *flush* (al confirmar), y la fila de la saga iba
por JDBC, que escribe en el acto. En la base, la saga llegaba antes que el pedido.

🗣️ **2 minutos** — Hibernate acumula los cambios en el contexto de persistencia y los envía al final, en el
orden que decide. `JdbcClient` no pasa por ese contexto. La corrección es `saveAndFlush`, que obliga a
escribir el pedido antes de seguir.

🔬 **El detalle** — En `06/06` el mismo patrón (JPA más un `INSERT` de outbox por JDBC) funcionaba porque
`outbox_events` no tiene clave foránea: el error estaba ahí, sin síntoma. La restricción lo hizo visible.

**09 → 9.** Sin plazo en la saga y con caducidad en la reserva, el cliente pagó un stock que ya no estaba retenido. Explica la secuencia y la regla que lo evita. 🟠

⏱️ **30 segundos** — La saga reintentaba el cobro sin fin; a los 30 s la reserva caducó y el stock volvió;
`payments` revivió y cobró; al vender, no había nada retenido. La regla: plazo del paso + *lease* <
caducidad de la reserva.

🗣️ **2 minutos** —

```text
t=0     reserva (HELD)                       saga: AUTHORIZE_PAYMENT, sin plazo
t=1…45  payments caído: reintentos
t=33    inventory: la reserva caduca → stock libre
t=58    payments vuelve: AUTHORIZED           saga: COMMIT_INVENTORY → 0 líneas → ESCALATED
```

🔬 **El detalle** — Con plazo de 20 s, la saga compensa a los 20 y la caducidad nunca actúa: la segunda
capa queda para cuando el orquestador muere del todo. Las dos capas se diseñan juntas, no por separado.

**09 → 10.** El antifraude tocó un servicio con orquestador y tres con coreografía. ¿Por qué, y por qué la coreografía tuvo menos líneas? 🟠

⏱️ **30 segundos** — Con orquestador, el orden vive en un sitio: se añade un paso. Con coreografía, el orden
es quién escucha qué: hay que cambiar lo que escucha `payments`, lo que libera `inventory` y lo que proyecta
`orders`. Tuvo menos líneas porque cada cambio es pequeño.

🗣️ **2 minutos** — Orquestación: 1 servicio (`orders`), 158 líneas contando el *stub*. Coreografía: 3
servicios más un topic, 124 líneas. La cuenta que importa no son líneas: son tres equipos que coordinan un
despliegue, en orden, y un flujo que nadie ve escrito.

🔬 **El detalle** — En la coreografía hay además un orden de despliegue: si `payments` pasa a escuchar
`fraud.results` antes de que `fraud` exista, ningún pedido se cobra. En la orquestación, el paso nuevo y su
cliente llegan juntos en un solo despliegue.

**09 → 11.** La fidelidad no tocó ningún servicio en ninguna de las dos sagas. ¿Qué dice eso de "orquestación contra coreografía"? 🟠

⏱️ **30 segundos** — Que el sistema ya era mixto: el orquestador publica `OrderPaid` al terminar, y los
consumidores al final se suscriben a ese hecho. La pregunta real no es "cuál", es "dónde va cada cosa".

🗣️ **2 minutos** — La secuencia que el negocio trata como transacción (reservar, cobrar, compensar) tiene
dueño; las reacciones a su resultado (puntos, avisos, analítica) se coreografían sobre los hechos que
publica. Si el orquestador no publicara hechos, `loyalty` obligaría a tocar `orders` y a decidir si su caída
falla la saga.

🔬 **El detalle** — El hecho publicado es un contrato: `loyalty` depende ahora del esquema de `OrderPaid`.
Coreografiar reacciones no las desacopla del todo; las acopla a un evento en vez de a un servicio.

**09 → 12.** Un consumidor nuevo reprocesó la historia y un pedido viejo se volvió a cobrar. ¿Qué falló y qué política pondrías para consumidores nuevos? 🔴

⏱️ **30 segundos** — `fraud` empezó con un grupo nuevo desde el principio del topic y publicó hechos para
pedidos antiguos; `payments` los cobró y el PSP, reiniciado, no reconoció la clave. Política: un consumidor
nuevo que produce efectos empieza por el final, o con un reajuste de offsets decidido y revisado.

🗣️ **2 minutos** — `auto_offset_reset` solo se aplica a un grupo sin offsets: `earliest` reprocesa todo lo
retenido; `latest`, solo lo que llegue. Para una proyección que se construye desde cero, `earliest` es lo
correcto; para algo que publica o cobra, es un incidente. `loyalty` hizo lo mismo con los puntos.

🔬 **El detalle** — La defensa de fondo es que los efectos sean idempotentes por la clave del negocio
**y** que esa idempotencia dure más que la retención del topic. Las claves de los proveedores de pago
suelen caducar en horas o días; los topics se retienen días o semanas.

**09 → 13.** En una entrevista de banca te preguntan "¿coreografía u orquestación para el alta de un préstamo?". Responde con los criterios de este taller. 🔴

⏱️ **30 segundos** — Orquestación: pasos con ramas (scoring, antifraude, aprobación), plazos regulatorios,
resultados inciertos que hay que decidir y auditoría del flujo. Y coreografía para las reacciones al
resultado: avisos, contabilidad analítica, fidelización.

🗣️ **2 minutos** — Los tres criterios del taller: un paso en medio (habrá muchos: el antifraude es uno) lo
gana la orquestación; un fallo que exige decidir (una verificación externa que no contesta) también; solo
los consumidores al final los gana la coreografía. Y el requisito de explicar a un regulador en qué punto
está cada solicitud y por qué es exactamente `order_saga_log`.

🔬 **El detalle** — Lo que convence a un entrevistador senior es añadir el coste: el orquestador tiene que
ser tan disponible como el proceso que coordina, su estado es una tabla que se vigila (sagas escaladas,
pasos con muchos intentos), y no puede empezar a decidir reglas de negocio de los participantes.

**09 → 14.** El orquestador acaba de escalar una saga con el pedido `PAID` y la reserva caducada. Diseña qué ve la persona que la recibe y qué opciones tiene. 🔴

⏱️ **30 segundos** — Ve el pedido, el cobro con su referencia, el registro de transiciones y el stock actual
del producto. Opciones: volver a reservar si hay stock, devolver el cobro si no, o contactar al cliente.

🗣️ **2 minutos** —

```text
bandeja de sagas escaladas
  pedido be81…  PAID · reserva caducada · 3 × SKU-003 · cobro psp-… 666.00 · escalada hace 4 min
  historial     RESERVE (16:54:39) → AUTHORIZE (…) → COMMIT: 0 líneas → ESCALATED
  acciones      [reservar de nuevo] (stock disponible: 5)   [devolver el cobro]   [marcar resuelta + motivo]
```

🔬 **El detalle** — Cada acción manual es un comando más de la saga, con su clave idempotente y su línea en
el registro. Una bandeja que permite editar la base a mano es cómo se pierde la auditoría que justificó
orquestar.

## Ejercicios

**09 → E1.** 🟢 Corre las tres ramas con el orquestador y pega `saga-status` de cada una. Señala en el registro de transiciones el paso pivote.

⏱️ **30 segundos** — El pivote es la línea `COMMIT_INVENTORY  payment authorized …` de la rama feliz: la
transición que sale de `AUTHORIZE_PAYMENT` con el cobro hecho.

🗣️ **2 minutos** — En la rama sin stock no hay pivote: `RESERVE_INVENTORY` → `DONE out of stock`. En la de
rechazo, la saga llega a `AUTHORIZE_PAYMENT` y sale por `RELEASE_INVENTORY`: no cruzó el pivote porque el
cobro no ocurrió.

🔬 **El detalle** — Marcar el pivote en el registro (una columna, o un evento `PaymentCaptured`) es lo que
permite a un operador saber, de un vistazo, si una saga escalada tiene dinero en juego.

**09 → E2.** 🟢 **Orientación en código ajeno.** Encuentra, con ruta y línea, dónde decide el orquestador que un paso ha vencido y dónde se calcula cuándo toca el siguiente intento.

⏱️ **30 segundos** — El vencimiento se calcula en SQL, en `SagaStore.claim` (`SagaStore.java`, línea 36):
`deadline_at < clock_timestamp()` devuelve `expired`. El siguiente intento, en `SagaStore.retryLater`
(línea 62), con la espera de la línea 63.

🗣️ **2 minutos** — El orquestador solo **consulta** `d.expired()` en cada caso de `Orchestrator.run` (líneas
80, 97 y 103). El reloj es el de PostgreSQL (`clock_timestamp()`), no el de la JVM: con varias
instancias, todas miden el plazo con el mismo reloj.

🔬 **El detalle** — `claim` incrementa `attempts` al reclamar, y `advance` lo pone a cero al cambiar de paso:
la espera exponencial es por paso, no por saga.

**09 → E3.** 🟡 Haz que el orquestador despierte en cuanto una saga avanza, en vez de esperar al siguiente sondeo, y mide cuánto baja el tiempo hasta `PAID`.

⏱️ **30 segundos** — Tras `advance`, ejecutar el siguiente paso en el mismo hilo (o encolarlo en memoria)
sin esperar a `tick`. `PAID` baja de ≈ 900 ms a lo que suman las llamadas (≈ 100 ms en local).

🗣️ **2 minutos** — Lo simple: que `run` devuelva si la saga avanzó y, en ese caso, reclamar esa misma fila
otra vez al momento. El sondeo sigue haciendo falta para los reintentos con espera y para retomar sagas de
otra instancia caída.

🔬 **El detalle** — PostgreSQL tiene `LISTEN`/`NOTIFY` para despertar a otras instancias sin sondear; es un
canal que no persiste, así que complementa al sondeo, no lo sustituye.

**09 → E4.** 🟡 Añade a `saga-status` (o a un `GET /api/v2/orders/{orderId}/saga` solo para operadores) el registro de transiciones, y decide qué no debe ver el cliente.

⏱️ **30 segundos** — El operador ve pasos, intentos, errores y plazos; el cliente, solo el estado del
pedido y, como mucho, "estamos confirmando tu pago".

🗣️ **2 minutos** — Los mensajes de error internos (`circuit breaker open`, rutas, puertos) filtran la
arquitectura y no ayudan al cliente. El endpoint de operadores se protege por rol (`operator` en el JWT) y
queda fuera del contrato público.

🔬 **El detalle** — Si el endpoint entra en el `openapi.yaml`, va con su `x-taller` y en una sección de
operaciones internas: un contrato que mezcla lo público y lo interno acaba con clientes que dependen de lo
interno.

**09 → E5.** 🟠 Implementa un contrato intermedio entre `v1` y `v2`: reserva síncrona por gRPC en el alta (`201`/`409` como en `v1`) y solo el pago asíncrono. Compara el tamaño de la máquina de estados con la de este taller.

⏱️ **30 segundos** — El alta vuelve a reservar en el acto y la saga empieza en `AUTHORIZE_PAYMENT`: desaparece
`RESERVE_INVENTORY` y la rama de sin stock (que vuelve a ser un `409`).

🗣️ **2 minutos** — La máquina pierde un paso y una rama; el contrato conserva el `409` inmediato, que los
clientes agradecen. El precio es que el alta depende de `inventory` en línea (acoplamiento temporal), que
es justo lo que `v2` quería evitar.

🔬 **El detalle** — Es una opción legítima y muy común: la parte que tiene respuesta rápida y fiable va
síncrona; la que depende de un tercero lento (el PSP), asíncrona. La saga se hace del tamaño del problema.

**09 → E6.** 🔴 Añade una bandeja de sagas escaladas: una consulta, una alerta cuando haya alguna de más de 5 minutos, y dos acciones manuales (reintentar el paso, marcar como resuelta con un motivo).

⏱️ **30 segundos** — Consulta: `step = 'ESCALATED'` con `step_started_at` y el último registro. Alerta: una
métrica con el número de escaladas y su edad máxima. Acciones: dos comandos que escriben en la tabla y en el
registro.

🗣️ **2 minutos** — "Reintentar" devuelve la saga a su paso anterior con `attempts = 0` y un plazo nuevo;
"resuelta" la pasa a `DONE` con un motivo obligatorio en `order_saga_log`. Las dos, solo para `operator`, con
el actor en el registro.

🔬 **El detalle** — `03/03` §6 lo dice sin rodeos: una saga sin bandeja de casos atascados está incompleta.
Lo que el taller añade es que la bandeja es también parte del orquestador, con las mismas reglas de
idempotencia y auditoría.

**09 → E7.** 🔴 Aplica el parche `1-antifraude-orquestacion.patch` sobre una copia y haz que el antifraude corra **en paralelo** con la reserva, no después. ¿Qué cambia en la máquina, y qué compensación nueva aparece?

⏱️ **30 segundos** — La saga tiene dos subpasos pendientes a la vez y avanza cuando los dos terminan. Si el
antifraude falla y la reserva ya se hizo, hay que liberar; si la reserva falla, el resultado del antifraude
se descarta.

🗣️ **2 minutos** — La tabla necesita el estado de cada subpaso (dos columnas, o una tabla de pasos por
saga). La latencia baja a la del más lento de los dos, a cambio de una máquina con más combinaciones y de
reservar stock para pedidos que el antifraude rechazará.

🔬 **El detalle** — Es el punto en que un orquestador escrito a mano empieza a pedir un motor: paralelismo,
esperas conjuntas y temporizadores por rama son lo que Temporal o un motor BPMN dan hecho.

**09 → E8.** 🔥 Escribe la misma saga como un flujo de Temporal (en el lenguaje que prefieras) sin levantarlo: tres actividades, compensaciones y plazos. Señala qué líneas de `Orchestrator.java` y de `SagaStore.java` desaparecen.

⏱️ **30 segundos** — Desaparece casi todo `SagaStore` (tabla, *lease*, reintentos con espera) y el bucle de
`tick`; queda la secuencia de `run` como código lineal con `try`/`catch` y compensaciones registradas.

🗣️ **2 minutos** — Cada paso es una actividad con su política de reintentos y su `StartToCloseTimeout`; el
plazo del paso es un temporizador del flujo; la compensación, una lista que se ejecuta al revés si algo
falla. Temporal persiste el historial y retoma el flujo tras una caída, que es lo que hacía la tabla.

🔬 **El detalle** — Lo que no desaparece: la clave idempotente de cada actividad (Temporal reintenta y
puede repetir una llamada) y la decisión de negocio sobre el `PENDING`. El motor da la mecánica; la
semántica de "¿se cobró?" sigue siendo tuya.

---

# 10 — Contratos entre servicios y testing

## Preguntas

**10 → 1.** ¿Qué ve la suite `hurl` y qué no puede ver por construcción? 🟢

⏱️ **30 segundos** — Ve el contrato público, por Envoy, con peticiones secuenciales. No ve las APIs
internas (`POST /payments`), los eventos de Kafka ni lo que depende de concurrencia o de tiempos.

🗣️ **2 minutos** — La suite es un cliente: solo observa respuestas públicas. Un cambio en la respuesta
interna de `payments` solo se nota si altera algo que la suite comprueba; un campo de `OrderPaid`, nunca,
porque la suite no lee el topic. Y como las peticiones van una detrás de otra, los casos de "mientras
tanto" no existen para ella.

🔬 **El detalle** — Por eso no se sustituyen: la suite comprueba que el flujo completo funciona, que es lo
único que los contratos no ven (`04/07` §4). Cada capa cubre lo que las otras no pueden.

**10 → 2.** ¿Qué es un estado de proveedor y quién lo implementa? 🟢

⏱️ **30 segundos** — La situación en la que tiene que estar el proveedor para que la interacción tenga
sentido ("hay un pago en curso con esta clave"). El consumidor lo nombra en el pacto; el proveedor lo
implementa en su verificación.

🗣️ **2 minutos** — En el taller, `payments` implementa dos: borrar la clave del pago autorizado (para que
no conteste la repetición guardada) e insertar un pago `IN_PROGRESS`. En el pacto de mensajes de
`inventory`, `orders` implementa "an order has been paid" con un método vacío, porque el mensaje se
construye en memoria.

🔬 **El detalle** — El nombre del estado es parte del contrato: si el consumidor lo cambia, la verificación
falla aunque la interacción sea idéntica. Conviene nombrarlos en términos de negocio, no de tablas.

**10 → 3.** ¿Por qué el pacto de `orders` describe `reference` como "texto cualquiera" y no con un valor? 🟢

⏱️ **30 segundos** — Porque `orders` necesita que haya una referencia de texto, no una referencia
concreta. Con un valor fijo, el pacto fallaría cada vez que el PSP diera otra.

🗣️ **2 minutos** — `stringType("reference", "psp-1a2b3c4d")` usa el valor solo como ejemplo para el
simulador; en la verificación, Pact comprueba el tipo. Lo mismo `status`, con un patrón que admite los tres
valores que `orders` sabe tratar.

🔬 **El detalle** — `04/07` §7 lo dice para Node (`like`): acoplarse a valores produce pactos que fallan por
los datos de prueba, no por cambios reales, y un pacto que falla sin motivo deja de mirarse.

**10 → 4.** ¿En qué orden se corren consumidores y proveedores, y por qué? 🟢

⏱️ **30 segundos** — Primero los consumidores, que escriben los pactos; después los proveedores, que los
verifican. `lab.py test` corre `inventory`, `orders` y `payments` en ese orden.

🗣️ **2 minutos** — `inventory` escribe el pacto de `OrderPaid`; `orders` escribe el suyo con `payments` y
verifica el de `inventory`; `payments` verifica el de `orders`. Con un broker de pactos el orden deja de
importar dentro de un build: cada pipeline publica o verifica la última versión publicada.

🔬 **El detalle** — En el laboratorio los pactos están versionados en `contrato/pacts`, así que el proveedor
puede verificar sin correr antes al consumidor. Si el consumidor cambia su pacto y no lo publica, el
proveedor verifica uno viejo: el broker existe para eso.

**10 → 5.** ¿Por qué el cambio `409` → `423` no lo detectó ninguna suite? 🟡

⏱️ **30 segundos** — Porque el `409` solo aparece cuando llega un pago repetido mientras el primero sigue
en curso, y las suites nunca provocan esa situación: son secuenciales.

🗣️ **2 minutos** — La suite `v1` paga una vez y repite con la misma clave **después**, cuando el primero ya
terminó. La `v2` no pasa por esa rama. El pacto, en cambio, declara la interacción con su estado de
proveedor, y `payments` la reproduce en su verificación aunque en su uso normal sea rara.

🔬 **El detalle** — Los contratos cubren bien las ramas raras de una interacción porque el estado se
prepara a mano; una prueba de extremo a extremo tendría que provocar la carrera, que es lenta y
frágil.

**10 → 6.** ¿Qué habría pasado en producción con el `423`, en `v1` y en el orquestador? 🟡

⏱️ **30 segundos** — `RemotePayments` solo traduce un `409` a `PENDING`. Con un `423`: en `v1`, el doble clic
del cliente acabaría en un `500`; en el orquestador, en una excepción inesperada que se reintenta sin mirar
el plazo.

🗣️ **2 minutos** — El `423` llega como `HttpClientErrorException` genérica, que no es `Conflict`. En `v1`
sube hasta el manejador de errores como error interno. En el orquestador, `tick` captura las excepciones
inesperadas y las reintenta con espera, pero sin comprobar `expired()`: la saga no vencería nunca por esa
vía.

🔬 **El detalle** — Y el `500` es mentira: el pago está en curso y quizá se complete. Es el peor tipo de
ruptura, la que convierte una respuesta honesta ("espera") en una que invita a reintentar a ciegas.

**10 → 7.** ¿Por qué falló la primera verificación de `payments`, si `payments` no tenía ningún defecto? 🟡

⏱️ **30 segundos** — Porque el pacto de `orders` exigía para el `409` un cuerpo JSON y un `Content-Type` que
`orders` no lee; `payments` responde `application/problem+json` y la verificación lo marcó como ruptura.

🗣️ **2 minutos** — El defecto estaba en el pacto: declaraba de más. `orders` solo mira el código `409`. Se
corrigió quitando el cuerpo de esa interacción, y la verificación pasó. Es la regla de `02/07` §6: el
consumidor declara lo que usa.

🔬 **El detalle** — Si ese pacto se hubiera quedado así, el equipo de `payments` habría tenido que mantener
un tipo de contenido que nadie usa, o desactivar la verificación. Los pactos sobredeclarados son la causa
número uno de que un equipo proveedor abandone el mecanismo.

**10 → 8.** ¿Por qué el pacto de eventos se escribió a mano en Go, y qué se pierde? 🟠

⏱️ **30 segundos** — Porque `pact-go` exige instalar una biblioteca nativa en el sistema (y cgo), y el
laboratorio no instala nada fuera de los proyectos. El pacto es un JSON con especificación pública.

🗣️ **2 minutos** — El test hace lo que haría el DSL: pasa el ejemplo por el decodificador real y escribe el
pacto con sus reglas. Se pierde la comprobación automática de que las reglas y el ejemplo son
coherentes, y la ayuda para escribir matchers complejos.

🔬 **El detalle** — En una empresa, lo razonable es instalar la biblioteca en la imagen de CI, no en cada
portátil. El ejercicio 8 compara el pacto generado con el escrito a mano.

**10 → 9.** Renombrar `lines` a `items` pasó la suite y dejó `sales` vacío. ¿Por qué falló en silencio y quién lo detectó? 🟠

⏱️ **30 segundos** — `inventory` es un lector tolerante: un campo ausente se lee como vacío, y "sin líneas"
es un evento válido que suma cero. Lo detectó la verificación del pacto en `orders`: "Actual map is missing
the following keys: lines".

🗣️ **2 minutos** — La suite no lee Kafka, así que pasó 6/6. `inventory` registró cada `OrderPaid` como
`applied`, sin error, y `GET /sales` quedó en `{}`. Solo el contrato mira el mensaje, y lo hace en el
pipeline de quien lo rompe, antes de desplegar.

🔬 **El detalle** — Dos defensas complementarias: el contrato (detecta antes) y validar lo obligatorio al
leer (un `OrderPaid` sin líneas a la DLQ, `06/06` E4). La segunda convierte el fallo silencioso en ruidoso
si el contrato no existe o se salta.

**10 → 10.** ¿Por qué `OrderEvents.payload` es un método estático separado, y qué dice eso de cómo se diseña para probar? 🟠

⏱️ **30 segundos** — Para verificar el cuerpo del evento sin base de datos ni Kafka: el contrato se comprueba
sobre la función que construye el mensaje, la misma que usa el outbox.

🗣️ **2 minutos** — Antes, el cuerpo se construía dentro de `record`, mezclado con el `INSERT` en el outbox.
Separarlo no cambia el comportamiento y hace que la prueba de proveedor sea unitaria (2,6 s, casi todo
arranque de Pact). Si la prueba necesitara el broker, sería una prueba de integración con otro nombre.

🔬 **El detalle** — Es la idea general de "núcleo funcional, cáscara imperativa": lo que decide (la forma del
mensaje) separado de lo que hace efecto (escribirlo). Lo que decide se prueba barato; lo que hace efecto, con
Testcontainers.

**10 → 11.** ¿Qué aporta Testcontainers en la prueba del inbox que no aporte una base en memoria o un doble? 🟠

⏱️ **30 segundos** — La deduplicación depende de una clave primaria, de `ON CONFLICT DO NOTHING` y de una
transacción de PostgreSQL; con la misma imagen del laboratorio, la prueba ejerce exactamente eso.

🗣️ **2 minutos** — Una base en memoria de otro motor no tiene el mismo `ON CONFLICT`, y un doble del store
probaría el doble. El precio son segundos (4,1 s la primera prueba, 1,6 s la segunda) y Docker en la
máquina y en CI.

🔬 **El detalle** — La segunda prueba demuestra el fallo (sin inbox cuenta dos veces). Una prueba que
reproduce el defecto protege la corrección: si alguien quita el inbox, la otra prueba falla con el número
exacto.

**10 → 12.** La pirámide medida da 13 s para todo menos el extremo a extremo. ¿Por qué no basta y qué prueba de extremo a extremo conservarías? 🟠

⏱️ **30 segundos** — Porque ninguna capa de abajo comprueba que el flujo completo funciona: que Envoy enruta,
que el JWT llega, que la saga termina. Conservaría una por flujo de negocio crítico: las tres ramas de la
saga y el pago incierto.

🗣️ **2 minutos** — Los contratos garantizan que cada par de servicios encaja; la prueba de extremo a
extremo, que el conjunto hace lo que el negocio espera. La suite actual (46 + 23 peticiones) ya es pequeña;
lo que no conviene es añadirle los casos raros que cubren mejor los contratos y los componentes.

🔬 **El detalle** — El coste de la cima no es su duración (5 s), es el entorno: seis contenedores, cinco
procesos, un minuto largo de arranque y estados que se contaminan entre corridas.

**10 → 13.** En una empresa con 30 servicios, ¿cómo organizarías los pactos (dónde viven, quién los publica, qué bloquea un despliegue)? 🔴

⏱️ **30 segundos** — Un Pact Broker: cada consumidor publica sus pactos por versión y rama; cada proveedor
verifica en su pipeline los pactos de sus consumidores en producción; `can-i-deploy` bloquea un
despliegue que rompa a alguien en el entorno de destino.

🗣️ **2 minutos** —

```text
consumidor  build → test de consumidor → publica pacto (versión, rama)
proveedor   build → verifica pactos "desplegados en prod" y "rama principal" → publica resultado
ambos       antes de desplegar: can-i-deploy --to-environment prod → sí / no
```

🔬 **El detalle** — Lo difícil no es la herramienta, es la regla organizativa: el proveedor acepta que su
build falle por un pacto ajeno, y a cambio el consumidor se compromete a no declarar de más. Sin ese acuerdo
explícito, el broker se llena de verificaciones desactivadas.

**10 → 14.** Un equipo proveedor se queja: "vuestros pactos nos rompen el build cada semana". Diagnostica tres causas probables y qué harías con cada una. 🔴

⏱️ **30 segundos** — Pactos que declaran de más, estados de proveedor frágiles, y valores concretos en vez de
formas. Para cada una: recortar a lo que se lee, estados en términos de negocio y matchers de tipo.

🗣️ **2 minutos** —

```text
1. Sobredeclaración      campos, cabeceras o tipos que el consumidor no usa (el 409 del taller)
                         → revisar el pacto contra el código del cliente, campo a campo
2. Estados frágiles      "given" que dependen de datos de otras pruebas o de tiempos
                         → estados autocontenidos, que preparan y limpian lo suyo
3. Valores concretos     fechas, ids, importes exactos en la respuesta
                         → matchers de tipo y de patrón; valores solo como ejemplo
```

🔬 **El detalle** — Hay una cuarta causa que no es técnica: que el proveedor esté rompiendo de verdad a sus
consumidores cada semana. Antes de "arreglar los pactos", conviene mirar si el mensaje es el problema.

## Ejercicios

**10 → E1.** 🟢 Corre `lab.py test` y pega la salida. Luego borra `contrato/pacts/inventory-orders.json` y córrelo solo para `orders`: ¿qué pasa y por qué?

⏱️ **30 segundos** — Sin el pacto de `inventory`, la verificación de proveedor de `orders` no encuentra nada
que verificar y falla (Pact trata "sin pactos" como error por defecto). Corriendo antes `inventory`, el
pacto se regenera.

🗣️ **2 minutos** — Es el orden de §2 visto fallar: el proveedor depende de que el consumidor haya escrito su
pacto. En el laboratorio, el pacto está versionado; con un broker, se descarga la última versión
publicada.

🔬 **El detalle** — `@IgnoreNoPactsToVerify` cambia ese comportamiento; conviene no usarlo en el pipeline
principal, porque convierte "nadie me ha verificado" en "todo bien".

**10 → E2.** 🟢 **Orientación en código ajeno.** Encuentra, con ruta y línea, dónde decide `RemotePayments` que un `409` significa `PENDING`, y relaciónalo con la interacción del pacto que lo protege.

⏱️ **30 segundos** — `orders/src/main/java/dev/ms/orders/payments/RemotePayments.java`, el `catch
(HttpClientErrorException.Conflict e)` que devuelve `new Result("PENDING", null)`. Lo protege la interacción
"a repeated payment while the first attempt is still running" (`PaymentsContractTest.java`, línea 52).

🗣️ **2 minutos** — El test de consumidor ejecuta `RemotePayments` contra el simulador que responde `409` y
comprueba que el resultado es `PENDING` (línea 81). Si alguien cambia el `catch`, falla el consumidor; si
`payments` cambia el código, falla el proveedor.

🔬 **El detalle** — Un contrato protege los dos lados de la misma frontera: la interpretación del consumidor
y el comportamiento del proveedor. Por eso se prueba con el cliente real, no con un `RestClient` suelto.

**10 → E3.** 🟢 Añade al pacto de `orders` la interacción del pago rechazado (`REJECTED`, importe de más de 1000,00) con su estado de proveedor, y verifícala.

⏱️ **30 segundos** — Un `@Pact` con `given("the PSP rejects payments above 1000.00")`, importe `1499.00` y
respuesta `201` con `status` `REJECTED`; en `payments`, un estado que borra la clave. El PSP ya rechaza por
encima de 1000.

🗣️ **2 minutos** — El test de consumidor comprueba que `RemotePayments` devuelve `REJECTED` con referencia.
En la verificación, el estado puede ser el mismo que el del autorizado (borrar la clave): la regla vive en el
PSP simulado, que tiene que estar en marcha.

🔬 **El detalle** — Es un buen ejemplo de estado que depende de un tercero: el PSP. En una empresa, la
verificación del proveedor correría con el PSP simulado, igual que aquí, porque el real no se deja preparar.

**10 → E4.** 🟡 Escribe el contrato de `payments` como consumidor de `OrderCancelled` (lo que lee su consumidor de Kafka) y verifícalo en `orders`.

⏱️ **30 segundos** — `payments` lee `eventId`, `type` y `orderId` de `OrderCancelled`. El pacto, a mano en
Python como el de Go, con esas tres reglas; en `orders`, un `@PactVerifyProvider("an OrderCancelled event")`
con `OrderEvents.payload`.

🗣️ **2 minutos** — Con `pact-python` 3 se puede generar el pacto de mensajes con su DSL (sin biblioteca
nativa aparte: va en la rueda). Es más cómodo que en Go, y el pacto resultante es el mismo formato.

🔬 **El detalle** — `orders` pasa a tener dos consumidores de sus hechos con expectativas distintas; el
contrato del evento es la unión de lo que leen, y ya no se puede quitar `orderId` sin romper a los dos.

**10 → E5.** 🟠 Escribe en Java una prueba de componente de `SagaStore` con Testcontainers (`@ServiceConnection`): reclamar con *lease* desde dos hilos y comprobar que cada saga la coge uno solo.

⏱️ **30 segundos** — Un `@SpringBootTest` (o un `@JdbcTest`) con un `PostgreSQLContainer` anotado con
`@ServiceConnection`, el esquema de `orders`, varias sagas vencidas y dos hilos llamando a `claim` a la vez;
la unión de lo reclamado no tiene repetidos.

🗣️ **2 minutos** — Es la prueba de que `FOR UPDATE SKIP LOCKED` hace lo que el orquestador supone. Con un
doble no tiene sentido: el comportamiento está en PostgreSQL. `@ServiceConnection` hace que Boot configure el
`DataSource` desde el contenedor, sin propiedades.

🔬 **El detalle** — Las pruebas de concurrencia son las que más rinden con base real y las que más cuesta
hacer deterministas: conviene una barrera (`CountDownLatch`) para que los dos `claim` coincidan de verdad.

**10 → E6.** 🟠 Sustituye `contrato/pacts` por un Pact Broker en Docker y haz que `payments` compruebe `can-i-deploy` antes de desplegar. ¿Qué pregunta nueva responde?

⏱️ **30 segundos** — `can-i-deploy` responde "¿esta versión de `payments` es compatible con las versiones de
sus consumidores que hay en el entorno al que voy?", no solo "¿cumplo el último pacto?".

🗣️ **2 minutos** — El broker guarda qué versión de cada servicio está en cada entorno y qué verificaciones
pasaron entre versiones. Así un proveedor sabe si puede desplegar aunque un consumidor tenga en producción
una versión antigua con otro pacto.

🔬 **El detalle** — Sin broker, el laboratorio verifica "el pacto que está en el repositorio", que es el de la
versión en desarrollo del consumidor. En producción conviven varias versiones: el broker es lo que hace el
mecanismo seguro con despliegues independientes.

**10 → E7.** 🔴 Escribe una prueba que reproduzca la concurrencia que la suite no ve: dos `POST /api/v1/orders/{id}/payment` simultáneos con la misma clave y el PSP lento. ¿En qué capa de la pirámide la pones, y por qué?

⏱️ **30 segundos** — Como prueba de componente de `orders` con `payments` simulado (WireMock o el simulador de
Pact) respondiendo `409` al segundo, o como prueba de componente de `payments` con Testcontainers y dos
peticiones concurrentes. No en la suite de extremo a extremo.

🗣️ **2 minutos** — La carrera real depende de tiempos (el PSP lento, el orden de llegada), y en extremo a
extremo sería lenta y frágil. En componente se controla: en `payments`, dos peticiones con la misma clave y
el PSP simulado bloqueado hasta que llegue la segunda.

🔬 **El detalle** — La pregunta de fondo es qué comportamiento se prueba: que `payments` devuelve `409` (prueba
de componente de `payments`) y que `orders` lo interpreta como `PENDING` (ya lo cubre el pacto). Dividida
así, no hace falta provocar la carrera de verdad en ningún sitio.

**10 → E8.** 🔥 Instala `pact-go` en una imagen de CI (no en tu máquina), reescribe `contract_test.go` con su DSL de mensajes y compara el pacto generado con el escrito a mano.

⏱️ **30 segundos** — Una imagen con Go, gcc y la biblioteca nativa de Pact (`pact-go install` en el
`Dockerfile`); el test con `message.NewMessagePact` y matchers. El pacto generado usa la especificación V3 o
V4 según se configure.

🗣️ **2 minutos** — Las diferencias esperables: el generado incluye `metadata` de la herramienta y puede
expresar los matchers con la sintaxis V4; las reglas de fondo (uuid, tipo, entero, mínimo de líneas) tienen
que coincidir. Si no coinciden, el escrito a mano estaba mal.

🔬 **El detalle** — Instalar dependencias nativas en la imagen de CI y no en los portátiles es la forma de
tener la herramienta sin que cada desarrollador cargue con ella; el precio es que el test no corre igual en
local sin Docker.

---

# 11 — Consultas entre servicios y tiempo real

## Preguntas

**11 → 1.** ¿Qué hace cada fuente de la vista, y cuánto tardó cada una en el taller? 🟢

⏱️ **30 segundos** — La composición lee los pedidos de `orders` y pregunta a `payments` el estado de sus
pagos en una llamada; la proyección lee dos tablas que mantiene un proyector con `orders.events`. En
caliente, ≈ 13–35 ms frente a ≈ 2 ms.

🗣️ **2 minutos** — La composición da el dato del dueño en el momento, a cambio de una llamada remota y de
decidir qué pasa si falla. La proyección es una consulta local con la forma exacta de la pantalla, a cambio
de un proceso más, retraso y saber solo lo publicado. `Server-Timing` lo mide en cada respuesta.

🔬 **El detalle** — La primera composición tras arrancar `orders` tardó ≈ 220–260 ms: cliente HTTP y JIT en
frío. Un número de latencia sin decir si es en frío o en caliente no significa nada.

**11 → 2.** ¿Por qué la composición pide todos los pedidos en una llamada y no uno a uno? 🟢

⏱️ **30 segundos** — Para no caer en el N+1: con N pedidos serían N llamadas a `payments`, N latencias y N
oportunidades de fallo. `GET /payments?orderId=…&orderId=…` las convierte en una.

🗣️ **2 minutos** — Hubo que añadir el filtro por lote a `payments` (`order_id = ANY(%s)`): la composición
eficiente exige que el dueño ofrezca una consulta por lote. Es la misma lección que `02/02` con el
catálogo.

🔬 **El detalle** — Un lote grande tiene sus límites: la URL (cientos de ids), el tamaño de la respuesta y
una consulta con `ANY` de miles de valores. Se pagina, o se pasa a `POST` con cuerpo, que ya no es una
lectura cacheable.

**11 → 3.** ¿Qué es un evento `snapshot` sin `id` y por qué se manda así? 🟢

⏱️ **30 segundos** — El estado del pedido en el momento de conectar. Va sin `id` para que no cambie el
punto de reanudación: si el cliente reconecta, sigue desde el último `step` que recibió.

🗣️ **2 minutos** — En SSE, el cliente recuerda el último `id` recibido y lo manda en `Last-Event-ID` al
reconectar. Si el `snapshot` llevara un `id`, habría que inventar uno que no está en el registro de la saga
y la reanudación dejaría de ser exacta.

🔬 **El detalle** — El `snapshot` da contexto a quien llega tarde; los `step` dan la historia. Separar "estado
actual" de "cambios" es la misma idea que un read model con su log de eventos.

**11 → 4.** ¿Para qué sirve el evento `end`? 🟢

⏱️ **30 segundos** — Para decir al cliente que no reconecte. Un `EventSource` reconecta solo cuando el
servidor cierra; sin un aviso explícito, pediría el flujo de una saga terminada una y otra vez.

🗣️ **2 minutos** — El servidor manda `end` al llegar a un paso final (`DONE` o `ESCALATED`) y cierra. El
cliente, al verlo, cierra él también (`EventSource.close()`). `lab.py follow` hace lo mismo: sale al recibir
`end` y reconecta si el flujo termina sin él.

🔬 **El detalle** — La alternativa estándar es que el servidor responda `204 No Content` a la reconexión,
que el navegador interpreta como "no vuelvas". Funciona, pero cuesta una petición más por cliente.

**11 → 5.** ¿Por qué la proyección deja en `PLACED` los pedidos con pago rechazado? 🟢

⏱️ **30 segundos** — Porque nadie publica un hecho para "pago rechazado" ni para "pago incierto". La
proyección solo sabe lo que llega por `orders.events`: `OrderPlaced`, `OrderPaid` y `OrderCancelled`.

🗣️ **2 minutos** — La composición lo ve porque pregunta a `payments`, el dueño del estado del pago. Para que
la proyección lo supiera, `orders` (o `payments`) tendría que publicar esos cambios. Mientras no lo haga, la
proyección se equivoca **por omisión**, sin ningún error que lo delate.

🔬 **El detalle** — Diseñar un read model empieza por la lista de hechos que el dueño se compromete a
publicar. Si esa lista no cubre la pantalla, el read model no es una opción, por rápido que sea.

**11 → 6.** ¿Qué devuelve la composición con `payments` caído, y por qué `200` y no `503`? 🟡

⏱️ **30 segundos** — Los pedidos con el pago `UNKNOWN` y `degraded: true`, con `200`. Porque la parte
principal —los pedidos— está, y el pago es información secundaria que se marca como desconocida.

🗣️ **2 minutos** — Es la tabla de `03/02` §2 aplicada: sin `orders` no hay pantalla; sin `payments`, la
pantalla se enseña con un aviso. Un `503` dejaría al cliente sin sus pedidos por culpa de un dato
accesorio. El precio: `pagados 0 · 0.00` con `DEGRADED` puede leerse como "no has pagado nada" si la
interfaz no enseña el aviso.

🔬 **El detalle** — Con `payments` lento, la composición espera su timeout (800 ms) antes de degradar. El
timeout de la composición es una decisión de producto: cuánto vale la frescura del pago frente a la
latencia de la pantalla.

**11 → 7.** ¿Por qué el reproceso sin inbox duplicó el total pagado pero no los estados de los pedidos? 🟡

⏱️ **30 segundos** — Porque las filas por pedido se escriben con operaciones repetibles (insertar si no
existe, fijar un estado) y el resumen **suma**. Repetir un "fija `PAID`" no cambia nada; repetir un "suma
9,90" suma otra vez.

🗣️ **2 minutos** — Tras 18 hechos reprocesados, la proyección decía 6 pedidos pagados y 79,20 USD frente a
3 y 39,60. La idempotencia natural depende de la **forma** de cada escritura, no del consumidor: un read
model mezcla escrituras idempotentes y no idempotentes, y basta una de las segundas para que el reproceso
lo corrompa.

🔬 **El detalle** — Otra forma de hacer idempotente el resumen es no guardarlo: calcularlo con `SUM` sobre
`order_overview` en cada consulta. Cambia escritura barata por lectura más cara, y el reproceso deja de
importar.

**11 → 8.** ¿Por qué Envoy cortaba el flujo SSE, y qué dos cambios lo resolvieron? 🟡

⏱️ **30 segundos** — Porque la ruta de `orders` tiene un timeout de 10 s para la respuesta entera, pensado
para peticiones. Se resolvió con una ruta propia para `/events` sin timeout de respuesta (`timeout: 0s`)
y con inactividad de 60 s, más un latido `: ping` cada 15 s desde el servidor.

🗣️ **2 minutos** — Envoy registró `UT response_timeout` a los 10 002 ms. Con la ruta propia, el flujo
duró 42 s en una sola conexión. El latido existe porque sin timeout de respuesta queda el de inactividad: un
flujo que no emite nada durante 60 s se cortaría.

🔬 **El detalle** — Cada salto entre cliente y servicio (CDN, balanceador, gateway, *ingress*) tiene sus
timeouts, y cada uno necesita su excepción para las rutas de conexión larga. El latido debe ser más corto que
el menor de todos.

**11 → 9.** ¿Cuál es el procedimiento completo para reconstruir el read model, y por qué en ese orden? 🟠

⏱️ **30 segundos** — Parar el proyector, vaciar la proyección **y** su inbox, reajustar los offsets del
grupo al principio, arrancar con inbox. El reajuste exige el grupo vacío, y vaciar solo la proyección haría
que el inbox saltara todos los hechos.

🗣️ **2 minutos** —

```text
1. parar orders (el grupo orders-overview queda vacío)
2. TRUNCATE order_overview, customer_overview; DELETE FROM processed_messages WHERE consumer = 'orders-overview'
3. kafka-consumer-groups.sh --group orders-overview --reset-offsets --to-earliest --execute
4. arrancar orders con inbox → reprocesa y deduplica
```

🔬 **El detalle** — Solo funciona si el topic conserva toda la historia (retención suficiente o
*compaction*) y si cada hecho lleva todo lo que la proyección necesita. En producción se reconstruye en
tablas nuevas y se cambia de tabla al terminar, para no enseñar una proyección a medias.

**11 → 10.** El orquestador empezó a publicar `OrderPlaced` y `OrderCancelled` en este taller. ¿Por qué hacía falta, y qué dice eso de quién decide qué se publica? 🟠

⏱️ **30 segundos** — Porque sin esos hechos la proyección no veía los pedidos `v2` orquestados ni sus
cancelaciones. Dice que lo que se publica lo decide el dueño del dato, y que los lectores dependen de esa
decisión.

🗣️ **2 minutos** — En `09`, el orquestador solo publicaba `OrderPaid`. Un read model nuevo necesitó dos hechos
más, y hubo que tocar el productor. Es el acoplamiento inverso de la coreografía: el consumidor no toca a
nadie... hasta que necesita un hecho que nadie publica.

🔬 **El detalle** — Por eso conviene publicar los hechos del ciclo de vida completo de un agregado aunque hoy
nadie los lea: el coste de publicarlos es bajo; el de añadirlos después es un cambio en el productor y una
historia incompleta en el topic.

**11 → 11.** ¿Qué pasa con las conexiones SSE cuando se despliega una versión nueva de `orders`, y cómo lo amortigua el diseño? 🟠

⏱️ **30 segundos** — Todas las conexiones de la instancia que se reemplaza se cortan a la vez. El diseño lo
amortigua con la reanudación: cada cliente vuelve con `Last-Event-ID` y no pierde ni repite eventos.

🗣️ **2 minutos** — Es `02/05` §6: una conexión abierta ata al cliente a una instancia. La reanudación
convierte el corte en un hueco, pero todos los clientes reconectan a la vez: una avalancha de peticiones a
las instancias nuevas justo cuando arrancan.

🔬 **El detalle** — El campo `retry:` de SSE permite al servidor indicar cuánto esperar antes de reconectar, y
conviene añadirle *jitter* por cliente para no sincronizar la avalancha.

**11 → 12.** ¿Cuándo elegirías composición y cuándo read model para esta pantalla, con los números del taller? 🟠

⏱️ **30 segundos** — Composición mientras el estado del pago no se publique y la pantalla se consulte con
frecuencia moderada: 13–35 ms es aceptable. Read model cuando sea la pantalla principal, con mucho tráfico o
filtros, **y** el dueño publique lo necesario.

🗣️ **2 minutos** — La composición arrastra la disponibilidad de `payments` (degradada si cae) y su latencia
(hasta 800 ms). La proyección responde en 2 ms pase lo que pase, pero ahora mismo miente sobre pagos
rechazados. Con los datos del taller, composición; con `payments` publicando sus cambios, proyección.

🔬 **El detalle** — Una salida intermedia muy usada: proyección para el listado y composición para el
detalle de un pedido, donde la frescura importa y el coste es una sola llamada.

**11 → 13.** Con tres instancias de `orders` detrás de Envoy, el cliente conecta el SSE a una y el orquestador avanza la saga en otra. ¿Funciona el diseño del taller? ¿Qué cambiarías si no? 🔴

⏱️ **30 segundos** — Funciona, porque el SSE no depende de quién avanza la saga: cada instancia lee el
registro de la saga en la base, que es compartida. El precio es que cada instancia sondea la base por cada
conexión que tiene.

🗣️ **2 minutos** — El problema de `02/05` §6 ("el evento nace en otro servicio") no aparece porque el
"backplane" es la tabla `order_saga_log`. Con muchas conexiones, el sondeo cada 200 ms por conexión pesa: se
agrupa en una consulta por instancia (todas las sagas seguidas a la vez) o se sustituye por `LISTEN`/`NOTIFY`
o por un topic de transiciones.

🔬 **El detalle** — Si el origen de los eventos no estuviera en una base compartida (por ejemplo, un evento en
memoria de otra instancia), haría falta un *backplane* de verdad —un topic, Redis *pub/sub*— o enrutar por
pedido (afinidad), que complica el balanceo y los despliegues.

**11 → 14.** Producto quiere que "mis pedidos" muestre también el estado del pago en tiempo real, sin la latencia de la composición. Diseña qué publica `payments`, qué consume el proyector y qué garantías das. 🔴

⏱️ **30 segundos** — `payments` publica por outbox `PaymentAuthorized`, `PaymentRejected`, `PaymentPending` y
`PaymentVoided`; el proyector los aplica por `orderId` con inbox; la garantía es "eventualmente
correcto, con un retraso medido" y un aviso cuando el retraso supera un umbral.

🗣️ **2 minutos** —

```text
payments   outbox → payments.results: PaymentAuthorized | Rejected | Pending | Voided (clave orderId)
proyector  consume orders.events + payments.results; fija payment_status por orderId; inbox
           payment_status solo avanza (un Pending tardío no pisa un Authorized): versión por pago
garantías  retraso típico < 1 s, alerta si el lag > 30 s; la vista incluye asOf; reconstrucción probada
```

🔬 **El detalle** — El punto delicado es el orden entre topics: `OrderPlaced` y el primer hecho de pago
pueden llegar en cualquier orden. El proyector tiene que aceptar un pago de un pedido que aún no conoce
(crear la fila parcial) y hacer que los estados solo avancen, con una versión o una marca de tiempo del
dueño.

## Ejercicios

**11 → E1.** 🟢 Corre `overview --items` tras la suite `v1` y marca, pedido a pedido, en qué difieren las dos fuentes y por qué.

⏱️ **30 segundos** — Coinciden en pedidos pagados y cancelados; difieren en los de pago rechazado o
incierto (la proyección dice `PLACED`) y en los `v1` sin pagar (`CONFIRMED` frente a `PLACED`).

🗣️ **2 minutos** — Dos causas distintas: los estados que nadie publica (rechazado, incierto) y el idioma de
cada fuente (la composición usa el estado de la tabla de `orders`; la proyección, el del último hecho). La
primera es un defecto de información; la segunda, una decisión de diseño.

🔬 **El detalle** — El total pagado coincide porque solo depende de `OrderPaid`, que sí se publica. Una
vista puede ser correcta en su resumen y engañosa en su detalle.

**11 → E2.** 🟢 **Orientación en código ajeno.** Encuentra, con ruta y línea, dónde decide la composición cuánto espera a `payments` y dónde marca la respuesta como degradada.

⏱️ **30 segundos** — `orders/.../web/OverviewController.java`: el timeout de lectura en la línea 44, a
partir de `ms.overview.composition-timeout-ms`; la degradación en la línea 72, en el `catch` de
`RestClientException`.

🗣️ **2 minutos** — El cliente de la composición es propio (no el de `RemotePayments`), con su timeout y sin
reintentos ni breaker: una pantalla prefiere degradar enseguida antes que esperar reintentos.

🔬 **El detalle** — Reutilizar `RemotePayments` habría traído su *retry* y su *breaker*, pensados para cobrar:
mismo servicio, otra operación, otra política de resiliencia.

**11 → E3.** 🟡 Haz que `payments` publique `PaymentVoided` cuando anula un pago (`06/06`), que el proyector lo aplique, y comprueba que la proyección refleja la cancelación de un pago pendiente.

⏱️ **30 segundos** — En `void_pending`, insertar en el outbox de `payments` un `PaymentVoided` en la misma
transacción; el proyector suscribe `payments.results` y fija `payment_status = 'VOIDED'`.

🗣️ **2 minutos** — El hecho sale por el outbox que `payments` ya tiene (`06/08`). En el proyector, un tópico
más en el `@KafkaListener` y un `case`. La prueba: un pedido `v1` de 666,00, cancelado; la composición dice
`VOIDED` y, con el cambio, la proyección también.

🔬 **El detalle** — Es la respuesta práctica a la pregunta 5: el read model mejora cuando el dueño publica
más, no cuando el proyector es más listo.

**11 → E4.** 🟡 Añade a la vista un campo `asOf` con la marca del último hecho aplicado por el proyector, y enséñalo en la respuesta de la proyección. ¿Qué le dice al cliente?

⏱️ **30 segundos** — Una columna con el `occurredAt` del último hecho aplicado (por cliente o global) y el
campo en la respuesta. Le dice "esto es cierto hasta este momento".

🗣️ **2 minutos** — Convierte la consistencia eventual en algo visible: si `asOf` va minutos por detrás, la
interfaz puede avisar o caer a la composición. Es la versión para el usuario del *lag* del consumidor.

🔬 **El detalle** — Hay que decidir de qué reloj sale: el de `orders` al emitir el hecho (el que tiene
sentido de negocio) o el del proyector al aplicarlo (que mide el retraso). Las dos respuestas son útiles y
distintas.

**11 → E5.** 🟠 Implementa `GET /api/v2/orders/overview?source=projection&minVersion=N`: si el proyector aún no ha aplicado el hecho N, espera hasta 2 s o responde con la composición. ¿Qué problema resuelve?

⏱️ **30 segundos** — El de "leer lo que acabo de escribir": el cliente que acaba de pagar ve su pago aunque
el proyector vaya por detrás.

🗣️ **2 minutos** — La escritura devuelve un número de versión (por ejemplo, el offset del hecho o un
contador por cliente); la lectura lo exige. Si la proyección ya lo tiene, responde; si no, espera un poco o
compone.

🔬 **El detalle** — Es la consistencia "read-your-writes" sobre un sistema eventual. Resuelve el caso más
visible —el usuario que no ve lo que acaba de hacer— sin pagar consistencia fuerte para todos los demás.

**11 → E6.** 🟠 Sustituye el sondeo del registro por `LISTEN`/`NOTIFY` de PostgreSQL para empujar los eventos SSE sin esperar al planificador. Mide la diferencia.

⏱️ **30 segundos** — Un `NOTIFY saga_log, '<orderId>'` al insertar en `order_saga_log` (o un disparador), y una
conexión que escucha y despierta al emisor de ese pedido. La latencia baja de hasta 200 ms a unos pocos.

🗣️ **2 minutos** — `NOTIFY` va dentro de la transacción y solo se entrega al confirmar, así que no avisa de
nada que no exista. Pero no persiste: si la instancia no escuchaba en ese momento, se pierde el aviso; el
sondeo sigue haciendo falta como red de seguridad o para la reconexión.

🔬 **El detalle** — Cada instancia necesita una conexión dedicada a escuchar, fuera del pool. Con muchas
instancias, es una conexión más por instancia contra la base.

**11 → E7.** 🔴 Levanta dos instancias de `orders` detrás de Envoy y reproduce la pregunta 13. Resuélvelo con un *backplane* (un topic con las transiciones) y justifica la elección frente a enrutar por pedido.

⏱️ **30 segundos** — Con el diseño actual funciona sin *backplane* porque la base es compartida. Para
ejercitar el caso, se quita el sondeo del registro y el orquestador publica cada transición en un topic que
todas las instancias leen con grupos distintos.

🗣️ **2 minutos** — Cada instancia empuja a sus conexiones lo que le llega del topic para los pedidos que
sigue. Enrutar por pedido (afinidad por `orderId` en Envoy) evitaría el topic, pero rompe el balanceo y hace
que un despliegue corte a todos los clientes de esa instancia sin otra que los recoja con estado.

🔬 **El detalle** — El topic de transiciones con un grupo por instancia es exactamente el patrón *fan-out*:
cada instancia recibe todo y filtra. Con muchas instancias, se pasa a una capa de conexiones dedicada.

**11 → E8.** 🔥 Reescribe el endpoint SSE en Go con `http.Flusher`, como servicio aparte que solo lee el registro de la saga, y ponlo detrás de Envoy: la "capa de conexiones aparte" de `02/05` §6.

⏱️ **30 segundos** — Un servidor Go que, por cada conexión, lee `order_saga_log` desde `Last-Event-ID`, escribe
`id:`, `event:` y `data:` y llama a `Flush()`; Envoy enruta `/events` a él en vez de a `orders`.

🗣️ **2 minutos** — `orders` deja de tener conexiones largas y puede desplegarse sin cortar a nadie; el
servicio de conexiones es pequeño, sin estado de negocio, y escala por número de conexiones. Necesita leer la
base de `orders`, lo que rompe la base por servicio: la versión correcta lee un topic de transiciones.

🔬 **El detalle** — Es la evolución natural de los sistemas con mucho tiempo real: separar "quién mantiene las
conexiones" de "quién tiene la lógica", y comunicarlos por eventos.

---

**Anterior:** [`11` — Consultas entre servicios y tiempo real](11-consultas-y-tiempo-real.md) ·
**Índice del bloque:** [README](README.md)
