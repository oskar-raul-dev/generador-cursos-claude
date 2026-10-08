# 07 — Respuestas: Adaptadores de entrada

Solucionario del bloque `03-adaptadores-de-entrada`. Cada enunciado está copiado literalmente de su
capítulo o de la simulación, con la numeración de su documento, y cada respuesta conserva las tres
capas: **⏱️ 30 segundos** (lo que dirías primero), **🗣️ 2 minutos** (contexto, alternativa y
coste) y **🔬 El detalle** (para estudiar, no para recitar).

> **Vigencia:** 2026-09-28.

**Salto rápido:** [01 HTTP como adaptador de entrada](#01--http-como-adaptador-de-entrada) · [02 Mensajería, consumidores y comandos](#02--mensajería-consumidores-y-comandos) · [03 Jobs, CLI y procesos batch](#03--jobs-cli-y-procesos-batch) · [04 Autenticación, autorización y contexto de actor](#04--autenticación-autorización-y-contexto-de-actor) · [05 DTO, mapeo y presentación de errores](#05--dto-mapeo-y-presentación-de-errores) · [06 Simulación](#06--simulación-de-entrevista)

---

## 01 · HTTP como adaptador de entrada

### 1. 🟢 ¿Qué hace un adaptador HTTP de entrada?

⏱️ **30 segundos:** Convierte una petición HTTP en una intención de aplicación y el resultado de esa
intención en una respuesta HTTP.

🗣️ **2 minutos:** Recibe la petición, aplica límites de tamaño, valida la forma del cuerpo y los
parámetros, extrae una identidad confiable del token ya verificado y construye un comando propio.
Llama a `CreateOrder` y traduce lo que vuelva: `201` con `Location` y un response DTO si fue bien, o
un Problem Details con el código correcto si fue un error de negocio o técnico. Status, headers,
JSON y versión de la API quedan fuera del núcleo.

🔬 **El detalle:** Su prueba cubre ambos sentidos de la traducción, incluidos los errores: que la
petición correcta produce el comando esperado y que cada error del núcleo produce el status y el
cuerpo que promete el contrato.

### 2. 🟢 ¿Qué información pertenece al controller y no al dominio?

⏱️ **30 segundos:** Ruta, método, headers, status, formato de serialización, versión de API y el
request/response DTO.

🗣️ **2 minutos:** Son decisiones del protocolo y del contrato público, y cambian por razones ajenas
al negocio: una v2, un cliente nuevo, una convención de nombres. El dominio conserva las invariantes
del pedido y del pago, y la aplicación la coordinación. Si una de estas decisiones de protocolo
aparece en el núcleo (un status en una excepción, un header leído en un caso de uso), el transporte
empieza a dictar la política.

🔬 **El detalle:** Un identificador de correlación puede acompañar la operación —en logs, trazas,
incluso en el comando como metadato— sin convertirse en regla de dominio ni en identidad de negocio.

### 3. 🟢 ¿Qué diferencia hay entre request DTO y comando?

⏱️ **30 segundos:** El DTO representa el contrato HTTP; el comando representa la intención interna
de la aplicación.

🗣️ **2 minutos:** El request DTO tiene los nombres públicos, los opcionales por compatibilidad y las
anotaciones de validación y serialización del framework. El comando tiene los datos que el caso de
uso necesita, con tipos propios, y además datos que no vienen en el cuerpo: el actor del token, la
clave de idempotencia del header. Un DTO puede cambiar entre la v1 y la v2 mientras ambos se
traducen al mismo `CreateOrderCommand`.

🔬 **El detalle:** No se pasan al comando los decoradores ni los valores por defecto del framework:
un default aplicado por el deserializador es una decisión de contrato que conviene hacer explícita
en el mapper.

### 4. 🟢 ¿Quién decide el status HTTP de `OrderCreated`?

⏱️ **30 segundos:** El adaptador HTTP, según el contrato de la API.

🗣️ **2 minutos:** `CreateOrder` devuelve `OrderCreated` con el id y el estado; el controller elige
`201 Created`, construye el header `Location` con la URL del recurso y el cuerpo de respuesta. Si la
misma clave de idempotencia se repite, el contrato puede decir que se responde el mismo `201` con
una cabecera que indique la repetición. Todas esas son decisiones de representación.

🔬 **El detalle:** Otro driver puede representar el mismo resultado de otra forma: un mensaje de
respuesta correlacionado y un ACK en una cola, o una línea y código de salida cero en una CLI.

### 5. 🟢 ¿Dónde se valida que un JSON tenga la forma correcta?

⏱️ **30 segundos:** En el borde HTTP, antes de construir el comando.

🗣️ **2 minutos:** El parser rechaza JSON mal formado; la validación runtime (Bean Validation, un
pipe de Nest, Pydantic, un esquema) rechaza tipos incorrectos, campos obligatorios ausentes, tamaños
fuera de rango y formatos inválidos, con un `400` y la lista de campos a corregir. El caso de uso
recibe un comando ya estructurado y no tiene que defenderse de basura sintáctica.

🔬 **El detalle:** El dominio también valida sus invariantes aunque el borde haya validado la forma:
"la cantidad es un entero positivo" es forma; "hay stock suficiente" es negocio y no puede decidirse
en el borde.

### 6. 🟢 ¿Por qué `CreateOrder` no debe recibir `HttpRequest`?

⏱️ **30 segundos:** Porque ata la aplicación a un transporte y a un framework concretos.

🗣️ **2 minutos:** Si recibe `HttpRequest`, solo HTTP puede invocarlo de forma natural: una cola, un
job o una prueba tendrían que fabricar una petición falsa. Además el caso de uso empezaría a leer
headers, parámetros y cuerpo, haciendo el trabajo del adaptador. Con un comando propio, cualquier
entrada puede construirlo, y el caso de uso se prueba sin servidor.

🔬 **El detalle:** `HttpRequest` filtra headers, sesión, atributos del framework y ciclo de vida de
la petición al puerto. Incluso tenerlo disponible "por si acaso" invita a usarlo.

### 7. 🟢 ¿Qué devuelve el puerto de entrada al controller?

⏱️ **30 segundos:** Un resultado propio de aplicación o un error tipado propio.

🗣️ **2 minutos:** Por ejemplo, `OrderCreated(orderId, status)` en caso de éxito, o
`InsufficientInventory` / `ProductNotFound` como errores de negocio. El controller lo traduce a
response DTO, status y headers, y un traductor central convierte los errores. El resultado debe
contener lo que el adaptador necesita para responder, sin obligarlo a conocer el interior del
dominio.

🔬 **El detalle:** No debe devolver una entidad ORM ni un `ResponseEntity`: la primera arrastra
persistencia hasta la API; el segundo mete HTTP en la aplicación.

### 8. 🟡 ¿Qué hace delgado a un controller sin volverlo inútil?

⏱️ **30 segundos:** Que traduzca el protocolo con cuidado y delegue toda decisión de negocio en el
caso de uso.

🗣️ **2 minutos:** Un controller delgado sigue teniendo trabajo real: validar la forma, construir el
comando con identidad e idempotencia, invocar el puerto, proyectar el resultado a un DTO, elegir
status y headers, y dejar que el traductor central convierta errores. Lo que no hace es consultar
repositorios, calcular totales ni decidir si un pedido puede cancelarse.

🔬 **El detalle:** Delgado no significa sin responsabilidades de borde. Un controller que ni siquiera
valida ni traduce está empujando ese trabajo al núcleo, que es el problema opuesto.

### 9. 🟡 ¿Cómo traduces `InsufficientInventory` a HTTP?

⏱️ **30 segundos:** El adaptador lo convierte en un rechazo documentado, típicamente `409 Conflict`,
con un código público estable.

🗣️ **2 minutos:** El traductor central mapea `InsufficientInventory` a Problem Details: `status:
409`, un `type` y un `code` estables (`INSUFFICIENT_INVENTORY`), un `detail` seguro ("no hay stock
suficiente para SKU-004") y la correlación. El cliente puede reaccionar programáticamente por el
código sin interpretar el texto. El dominio no conoce el status; solo lanza o devuelve el error
propio.

🔬 **El detalle:** La elección exacta del status (`409` o `422`) pertenece al contrato de la API y
debe ser la misma en todos los endpoints. Lo importante es que esté documentada y que el `code` sea
estable.

### 10. 🟡 ¿Dónde acotas `limit` en una consulta paginada?

⏱️ **30 segundos:** En el adaptador de entrada, antes de construir la petición de lectura.

🗣️ **2 minutos:** El adaptador aplica un valor por defecto, rechaza o recorta valores fuera de rango
(por ejemplo, máximo 100) y traduce `limit` y `cursor` a una petición de lectura propia de la
aplicación. Así un cliente no puede pedir un millón de filas y el núcleo recibe siempre valores
razonables. El máximo es parte del contrato público y se documenta.

🔬 **El detalle:** El caso de uso puede imponer además límites de recursos propios, independientes
del query string —por ejemplo, un techo absoluto de elementos por consulta—, como defensa ante
cualquier entrada.

### 11. 🟡 ¿Qué parte de una clave de idempotencia cruza al caso de uso?

⏱️ **30 segundos:** Una identidad de operación normalizada, como dato propio del comando.

🗣️ **2 minutos:** El borde valida el header `Idempotency-Key` (presente cuando el contrato lo exige,
formato, longitud) y lo pone en el comando como `operationId`. El caso de uso lo usa para detectar
repeticiones y devolver el resultado anterior. El header en sí, su nombre y su formato, se quedan en
el adaptador; si mañana la clave viene en otro header o en el cuerpo, solo cambia el adaptador.

🔬 **El detalle:** La deduplicación durable ocurre junto al efecto, en la misma transacción que
guarda el pedido, no en el objeto HTTP ni en una caché del controller.

### 12. 🟡 ¿Por qué no basta comprobar la clave en memoria del controller?

⏱️ **30 segundos:** Porque un reinicio borra ese estado y varias instancias no lo comparten.

🗣️ **2 minutos:** Si el controller recuerda las claves en un mapa, basta con que el reintento llegue
a otra instancia o después de un despliegue para crear un segundo pedido. Además, dos peticiones
simultáneas con la misma clave pueden pasar ambas la comprobación. La clave debe asociarse al efecto
persistido, de modo que el reintento encuentre el pedido creado y recupere el resultado anterior.

🔬 **El detalle:** Una restricción única sobre la clave en la base cierra la carrera entre dos
peticiones simultáneas: una inserta, la otra falla y se traduce a "devolver el resultado de la
primera".

### 13. 🟡 ¿Qué probarías en el adaptador HTTP además del caso de uso?

⏱️ **30 segundos:** El mapeo de request y response, los status, los headers y la traducción de cada
error.

🗣️ **2 minutos:** Con peticiones reales contra el adaptador (MockMvc, supertest, TestClient) y un
doble del caso de uso, compruebo que el JSON correcto produce el comando esperado, que el `201`
lleva `Location`, que cada error del núcleo produce su status y su `code`, que un JSON inválido da
`400` sin llegar al caso de uso, y que la respuesta no expone campos internos. La suite de contrato
contra el sistema completo cubre además la integración.

🔬 **El detalle:** El caso de uso se prueba aparte por sus invariantes; un mock del controller solo
no cubre HTTP, porque no ejecuta el routing, la deserialización ni el traductor de errores.

### 14. 🟡 ¿Por qué TypeScript necesita validación runtime de `@Body()`?

⏱️ **30 segundos:** Porque los tipos de TypeScript no inspeccionan el JSON en ejecución: se borran
al compilar.

🗣️ **2 minutos:** Declarar `@Body() body: CreateOrderDto` no garantiza nada sobre lo que llega: un
campo ausente llega como `undefined` y un número como string. Un `ValidationPipe` con
class-validator, un esquema Zod o una función de parseo explícita valida el cuerpo antes de
construir el comando. A partir de ahí, el tipo estático protege el resto del camino porque el dato
ya tiene la forma declarada.

🔬 **El detalle:** No hay que confiar en un cast de `unknown` a DTO: cambia lo que cree el
compilador, no los datos. En Nest, además, el `ValidationPipe` necesita `whitelist` y transformación
bien configurados para no dejar pasar campos extra.

### 15. 🟡 ¿Qué ventaja tiene un traductor central de errores de Spring?

⏱️ **30 segundos:** Centraliza la traducción de errores del núcleo a HTTP, de modo que el mismo
error produce siempre la misma respuesta.

🗣️ **2 minutos:** Un `@ControllerAdvice` con `@ExceptionHandler` por tipo de error mantiene status y
cuerpos Problem Details consistentes entre rutas, evita `try/catch` repetidos en cada controller y
hace revisable la tabla de traducción contra el contrato OpenAPI. Los controllers quedan limpios y
un error nuevo del núcleo se mapea en un solo lugar.

🔬 **El detalle:** No debe convertir toda excepción inesperada en error del cliente: lo desconocido
debe salir como `500` con correlación y registrarse con su causa completa, para que los fallos
técnicos sigan siendo visibles.

### 16. 🟡 ¿Cuándo el mapper de DTO puede ser ceremonia innecesaria?

⏱️ **30 segundos:** Cuando no protege ninguna diferencia real ni evolución probable entre el
contrato HTTP y el comando.

🗣️ **2 minutos:** En un CRUD interno muy estable, con un solo cliente que evoluciona junto al
servicio, una copia campo a campo entre dos tipos idénticos agrega coste sin aislar ningún contrato:
cada campo nuevo se toca en dos sitios y se olvida en uno. Ahí puede aceptarse que el DTO validado
sea el comando, siempre que no lleve anotaciones que el núcleo tenga que conocer.

🔬 **El detalle:** Revisaría la decisión si surge otra entrada, una versión pública o un campo
sensible. Y el mapper de salida es distinto: aunque hoy sea idéntico, evita exponer por accidente lo
que se añada al modelo.

### 17. 🟠 Un controller llama directamente a JPA para crear un pedido. ¿Qué extraes primero?

⏱️ **30 segundos:** Un caso de uso que concentre la acción de crear pedido, con sus reglas, detrás
de un puerto de entrada.

🗣️ **2 minutos:** Empiezo con una prueba del endpoint tal como está, para fijar el comportamiento.
Después muevo la lógica a `CreateOrder`: recibe un comando, aplica las reglas, guarda por un puerto
`Orders` que por ahora puede implementar el mismo repositorio JPA envuelto en un adaptador. El
controller conserva la validación de forma y la traducción. La persistencia queda detrás de un
puerto de salida y la transacción alrededor del caso de uso.

🔬 **El detalle:** Primero identifico la regla y el límite transaccional; no creo interfaces por cada
clase ni reorganizo carpetas. El objetivo del primer paso es que la regla viva en un sitio que otra
entrada pueda usar.

### 18. 🟠 Una nueva versión HTTP cambia nombres de campos. ¿Debe cambiar `CreateOrder`?

⏱️ **30 segundos:** No necesariamente. Si la intención no cambió, solo cambia el adaptador.

🗣️ **2 minutos:** El adaptador v2 tiene su propio request DTO con los nombres nuevos y un mapper que
lo traduce al mismo `CreateOrderCommand` que usa la v1. Ambas versiones conviven, cada una con su
contrato público, sobre el mismo caso de uso y el mismo dominio. Las pruebas de mapeo de cada
versión garantizan que producen el mismo comando para la misma intención.

🔬 **El detalle:** Solo cambio el núcleo si cambió la política —por ejemplo, la v2 admite pedidos con
varias direcciones de entrega—, no la ortografía pública. Versionar la ruta no obliga a versionar el
caso de uso.

### 19. 🟠 El mismo comando llega por HTTP y por cola. ¿Dónde deduplicas?

⏱️ **30 segundos:** En el límite de aplicación que confirma el efecto, con una identidad de
operación común.

🗣️ **2 minutos:** Ambos adaptadores aportan la misma identidad de operación al caso de uso: HTTP
desde `Idempotency-Key`, la cola desde el identificador de operación del mensaje. El caso de uso
registra esa identidad en la misma transacción que crea el pedido, con restricción única; cualquier
repetición, venga por donde venga, devuelve el resultado anterior sin crear otro pedido.

🔬 **El detalle:** Deduplicar por header en el controller o por delivery id en el consumidor dejaría
huecos entre transportes: la misma operación reintentada por el otro camino no se reconocería.

### 20. 🟠 Un cliente ve el mensaje de una excepción SQL. ¿Qué frontera falló?

⏱️ **30 segundos:** El adaptador filtró un detalle técnico al contrato público; probablemente tanto
el de persistencia como el de HTTP.

🗣️ **2 minutos:** El adaptador de persistencia debió traducir la excepción SQL a un error propio, y
el traductor HTTP debió convertir cualquier fallo técnico en una respuesta genérica. Corrijo ambos:
la excepción SQL se clasifica (conflicto, transitorio, fallo técnico); la respuesta pública es un
Problem Details seguro con correlación; la causa completa va al log.

🔬 **El detalle:** No expongo SQL ni stack trace en `detail`: revelan esquema, motor y a veces datos,
y facilitan ataques de inyección y enumeración.

### 21. 🟠 En Go, `ServeHTTP` ejecuta reglas e inserta SQL. ¿Cómo lo refactorizas?

⏱️ **30 segundos:** Dejo el handler como parser y traductor, y extraigo el caso de uso con sus
puertos.

🗣️ **2 minutos:** El handler decodifica el cuerpo con `http.MaxBytesReader` y un decoder estricto,
construye el comando, llama a `createOrder.Execute(ctx, cmd)` y traduce el resultado o el error con
`errors.As` a status y JSON. El caso de uso contiene la regla y depende de una interfaz `Orders`
declarada en su paquete; un adaptador con `pgx` la implementa. `main` compone todo.

🔬 **El detalle:** Verifico la transacción y la traducción de errores con pruebas de frontera:
`httptest` para el handler y una base real para el adaptador. Mover el SQL es fácil; lo que suele
romperse es que alguna consulta quede fuera de la transacción.

### 22. 🟠 En FastAPI, el dominio lanza `HTTPException`. ¿Qué contrato introduces?

⏱️ **30 segundos:** Errores propios del núcleo, como `OrderNotFound` o `InsufficientInventory`,
traducidos a HTTP en el borde.

🗣️ **2 minutos:** El dominio lanza sus excepciones de negocio; un `exception_handler` registrado en
la app de FastAPI las convierte en respuestas Problem Details con el status y el código del
contrato. El dominio deja de importar FastAPI, se prueba con pytest sin cliente HTTP y puede ser
invocado por un worker o una CLI que reaccionarán a su manera al mismo error.

🔬 **El detalle:** La misma semántica puede mapearse distinto en un consumidor:
`InsufficientInventory` es un `409` en HTTP y un rechazo registrado con ACK en una cola.

### 23. 🟠 Una consulta acepta `limit=1000000`. ¿Cómo proteges el sistema sin contaminar el dominio?

⏱️ **30 segundos:** Acotando `limit` en el borde con un máximo documentado y un valor por defecto.

🗣️ **2 minutos:** El adaptador valida el parámetro: si supera el máximo, lo rechaza con `400` o lo
recorta según diga el contrato. Construye una petición de lectura propia con el valor acotado y la
aplicación ejecuta una consulta que respeta ese límite. El dominio no se entera de que existía un
query string; el núcleo puede además imponer un techo propio como defensa.

🔬 **El detalle:** Prefiero cursores estables a offsets cuando los datos cambian entre páginas, y
limitar también el tamaño de la respuesta y el tiempo de la consulta, no solo el número de filas.

### 24. 🟠 ¿Qué evidencia demuestra que el controller contiene política de negocio?

⏱️ **30 segundos:** Reglas, acceso directo a repositorios o decisiones de permiso dependientes del
recurso dentro del controller.

🗣️ **2 minutos:** Señales concretas: `if` sobre estados del pedido, cálculos de totales o
descuentos, consultas a la base, comprobaciones de "este usuario puede cancelar este pedido". La
prueba más clara es el historial: si cambiar la regla de inventario obliga a editar la ruta HTTP y
el job por separado, la política está duplicada y vive en los adaptadores.

🔬 **El detalle:** Una prueba que invoque la misma operación desde otro driver evidencia el
acoplamiento: si el resultado difiere del de HTTP, la regla estaba en el controller.

---

## 02 · Mensajería, consumidores y comandos

### 1. 🟢 ¿Por qué un consumidor es un adaptador de entrada?

⏱️ **30 segundos:** Porque convierte una entrega externa —un mensaje de un broker— en una intención
del núcleo, igual que un controller convierte una petición HTTP.

🗣️ **2 minutos:** El consumidor conoce el broker, el cliente, el esquema del mensaje, la versión,
los headers y la mecánica de confirmación. Con todo eso construye un comando propio y llama al mismo
puerto de entrada que usan los demás drivers. La simetría es exacta: HTTP y la cola son dos puertas
al mismo caso de uso, cada una con su traducción y su forma de responder.

🔬 **El detalle:** El caso de uso no debe importar un cliente de mensajes ni saber que existe un
broker. Si lo sabe, cambiar de broker o añadir otra entrada vuelve a tocar la política.

### 2. 🟢 ¿Qué traduce el consumer antes de llamar a `CreateOrder`?

⏱️ **30 segundos:** Deserializa el payload, valida el esquema, la versión y la identidad del
productor, y construye un comando.

🗣️ **2 minutos:** Limita el tamaño, parsea, comprueba que la versión del esquema sea una que sabe
interpretar y que los campos obligatorios existan, extrae la identidad de operación estable y la
correlación, y construye `CreateOrderCommand`. Los headers del broker, el offset, el delivery tag y
el contexto de entrega se quedan en el adaptador, que los usará para confirmar, reintentar o apartar
el mensaje.

🔬 **El detalle:** La firma o la procedencia se comprueban antes de confiar en el payload: un mensaje
en la cola no es confiable por estar dentro de la red. Si el canal lo exige, se verifica quién lo
publicó.

### 3. 🟢 ¿Qué es un ACK del consumidor?

⏱️ **30 segundos:** La confirmación al broker de que la entrega fue procesada según su contrato,
para que no la vuelva a entregar.

🗣️ **2 minutos:** Suele emitirse después del commit local, porque es la forma de no perder trabajo:
si el proceso cae antes, el broker reentrega. No equivale al commit de la base: son dos
confirmaciones de sistemas distintos, y entre ambas hay una ventana en la que el efecto ya ocurrió
pero el broker no lo sabe. Por eso el consumidor debe ser idempotente.

🔬 **El detalle:** La mecánica exacta varía: en colas como RabbitMQ o Artemis se confirma cada
entrega; en logs como Kafka se confirma una posición (offset) que implica todas las anteriores de la
partición.

### 4. 🟢 ¿Qué datos del broker no deben entrar al núcleo?

⏱️ **30 segundos:** Offset, delivery tag, nombre del topic o cola, headers de transporte y el propio
cliente del broker.

🗣️ **2 minutos:** Todos ellos describen cómo llegó el mensaje, no qué se pide. Si el caso de uso los
recibe, empieza a depender de un broker concreto y a decidir con datos de entrega. Lo que sí puede
pasar, normalizado, es una correlación para observabilidad y la identidad de operación propia que
definió el productor, ambas como datos del comando.

🔬 **El detalle:** El núcleo no usa metadatos de entrega como identidad de negocio: el offset cambia
si el mensaje se republica y el delivery tag es local a un canal.

### 5. 🟢 ¿Qué significa redelivery?

⏱️ **30 segundos:** Volver a recibir un mensaje que ya se entregó antes, porque el broker no recibió
su confirmación.

🗣️ **2 minutos:** Sucede, por ejemplo, si hubo commit local y el proceso cayó antes del ACK; si el
consumidor tardó más que el timeout de visibilidad; si hubo un rebalance en Kafka antes del commit
de offset; o si el consumidor rechazó el mensaje para reintentarlo. Es el comportamiento normal de
una entrega al menos una vez, no una anomalía.

🔬 **El detalle:** La idempotencia protege el efecto ante esa repetición. Diseñar asumiendo que no
habrá redeliveries es diseñar para el caso en que nada falla.

### 6. 🟢 ¿Qué diferencia hay entre mensaje y comando?

⏱️ **30 segundos:** El mensaje es un contrato de integración entre sistemas; el comando es la
intención interna de la aplicación.

🗣️ **2 minutos:** El mensaje `OrderRequested` tiene su esquema, su versión, sus nombres de campos
acordados con otro equipo y sus metadatos. El comando `CreateOrderCommand` tiene los datos que el
caso de uso necesita con tipos propios. El adaptador traduce nombres y versiones externos al
comando, y así el contrato con el productor y la aplicación pueden evolucionar por separado.

🔬 **El detalle:** Un evento de dominio tampoco es automáticamente un mensaje externo: en la salida
también hay una traducción entre el hecho interno y el contrato publicado.

### 7. 🟢 ¿Qué es una DLQ o cola de cuarentena?

⏱️ **30 segundos:** Un destino aparte para las entregas que no deben bloquear el flujo normal:
mensajes ilegibles o que agotaron sus reintentos.

🗣️ **2 minutos:** En lugar de reintentar para siempre o descartar en silencio, el mensaje se aparta
con contexto saneado: la causa, el número de intentos, la correlación. Así el flujo normal sigue, y
alguien puede inspeccionar, corregir el problema (un bug, un dato malo del productor) y reinyectar
el mensaje de forma controlada. Muchos brokers la ofrecen de forma nativa tras N entregas fallidas.

🔬 **El detalle:** Sin responsable, alertas y política de retención, la DLQ solo acumula deuda: cada
mensaje en ella es una operación que el sistema no hizo.

### 8. 🟡 ¿Por qué confirmas después del commit local?

⏱️ **30 segundos:** Para no marcar como hecho un trabajo que todavía puede revertirse.

🗣️ **2 minutos:** Si confirmo antes de ejecutar y el proceso cae, o la transacción se revierte, el
broker ya no reentregará y la operación se pierde. Confirmando después, la peor consecuencia de una
caída es que el mensaje llegue otra vez, y eso lo resuelve la idempotencia. Es preferir duplicados,
que se pueden detectar, a pérdidas, que no se pueden recuperar.

🔬 **El detalle:** La caída entre commit y ACK causa repetición, por lo que deduplico por identidad
de operación en la misma transacción que el efecto. En el taller de JMS se provoca exactamente esa
caída y el segundo intento responde "ya aplicado".

### 9. 🟡 ¿Cómo distingues error permanente de transitorio?

⏱️ **30 segundos:** Preguntando si el mismo input puede tener éxito al repetirse sin que nada
cambie.

🗣️ **2 minutos:** Un timeout, una base momentáneamente caída o un proveedor saturado son
transitorios: repetir más tarde puede funcionar. Un esquema inválido, un campo imposible de
interpretar o un rechazo de negocio (stock insuficiente) son permanentes: repetir el mismo mensaje
producirá el mismo resultado. Los transitorios se reintentan con límite y espera; los permanentes se
registran y se confirman, o van a cuarentena.

🔬 **El detalle:** Fijo límite, espera (backoff) y destino final por tipo de error. Un error
transitorio que agota sus reintentos también termina en cuarentena, con la causa registrada.

### 10. 🟡 ¿Qué identidad usarías para deduplicar?

⏱️ **30 segundos:** Una identidad de operación estable emitida por el productor, que represente la
intención de negocio y no la entrega.

🗣️ **2 minutos:** Por ejemplo, un `operationId` que el sistema externo genera una vez por pedido
solicitado y repite en cada reintento o republicación. El consumidor la pasa en el comando; el caso
de uso la persiste con el efecto, con restricción única, y ante una repetición devuelve el resultado
anterior. Si el productor no ofrece una, hay que negociarla: sin ella, no hay forma fiable de
reconocer la misma operación.

🔬 **El detalle:** Defino el alcance (¿única por productor?, ¿global?) y la retención de la clave
según el contrato: debe cubrir la ventana real en que el productor puede reintentar.

### 11. 🟡 ¿Por qué un offset no es una clave de negocio suficiente?

⏱️ **30 segundos:** Porque identifica una posición de entrega en una partición, no una intención de
negocio.

🗣️ **2 minutos:** Si el productor republica la misma operación —porque no recibió confirmación, o
por un reproceso—, llega con otro offset y un deduplicador por offset la trata como nueva. Además,
si el tópico se recrea o el consumidor cambia de grupo, los offsets pierden sentido. El offset sirve
para saber hasta dónde se ha leído, no para saber si una operación ya se aplicó.

🔬 **El detalle:** Tampoco el delivery tag de RabbitMQ o el message id del broker sirven como clave
estable: son locales a la entrega o se regeneran al republicar.

### 12. 🟡 ¿Cómo evitas dos ejecuciones simultáneas del mismo comando?

⏱️ **30 segundos:** Con una operación atómica: restricción única sobre la identidad de operación, en
la misma transacción que el efecto.

🗣️ **2 minutos:** Dos workers pueden recibir el mismo mensaje (redelivery mientras el primero aún
procesa) y pasar ambos una comprobación previa "¿existe esta operación?". Si la comprobación y la
inserción no son atómicas, ambos crean el pedido. Con una restricción única, el segundo falla al
insertar, la transacción se revierte y el adaptador lo traduce a "ya procesado".

🔬 **El detalle:** La deduplicación debe compartir límite de consistencia con el efecto: si el
registro de operaciones vive en otra base o en una caché, vuelve a haber una ventana entre ambos.

### 13. 🟡 ¿Qué debe conservar una respuesta idempotente?

⏱️ **30 segundos:** El mismo efecto y una respuesta compatible para la misma identidad de operación.

🗣️ **2 minutos:** Ante una redelivery no creo otro pedido: recupero el resultado ya confirmado (el
id del pedido creado, o el rechazo registrado) y lo devuelvo, de modo que el productor reciba lo
mismo que habría recibido la primera vez. En un flujo de petición-respuesta por colas, eso significa
responder por la cola de réplica con la misma correlación y el mismo contenido.

🔬 **El detalle:** Si el payload cambia bajo la misma clave, es un conflicto: rechazo o lo marco como
error de integración, porque el productor está reutilizando una clave para otra intención.

### 14. 🟡 ¿Qué diferencia hay entre un ACK de RabbitMQ y un commit de offset de Kafka?

⏱️ **30 segundos:** RabbitMQ confirma una entrega concreta; Kafka confirma el avance de una posición
en la partición.

🗣️ **2 minutos:** En RabbitMQ (o Artemis), cada mensaje se confirma individualmente y los no
confirmados se reentregan, posiblemente a otro consumidor. En Kafka, el consumidor confirma "he
procesado hasta el offset N" y eso implica todos los anteriores de esa partición; no se confirman
mensajes sueltos. En ambos casos se coordina con el commit local de la misma forma —confirmar
después del efecto—, pero las consecuencias de un error difieren.

🔬 **El detalle:** Un offset avanzado prematuramente puede omitir mensajes anteriores de la partición
que aún no se habían procesado, por ejemplo con procesamiento concurrente dentro de una partición.
En colas, el error típico es otro: mensajes que quedan sin confirmar y se reentregan en bucle.

### 15. 🟡 ¿Qué riesgo tiene reintentar sin límite un mensaje inválido?

⏱️ **30 segundos:** Consume recursos para siempre y nunca corrige un dato que no se puede
interpretar; en un log, además, bloquea la partición.

🗣️ **2 minutos:** Un mensaje envenenado que se reintenta indefinidamente ocupa un consumidor, genera
ruido en logs y métricas y, en Kafka, impide avanzar a los mensajes siguientes de la misma
partición. Tras un número acotado de intentos (o inmediatamente, si el error es claramente
permanente) se envía a cuarentena o se rechaza según el contrato, y el flujo sigue.

🔬 **El detalle:** Evito registrar el payload completo si puede contener datos sensibles: basta la
correlación, la causa y un resumen saneado, con el mensaje original en un almacenamiento protegido
si hay que reprocesarlo.

### 16. 🟡 ¿Cómo pruebas el adaptador más allá de un mock del puerto?

⏱️ **30 segundos:** Con el broker real o uno equivalente, provocando redelivery, caídas y errores de
cada categoría.

🗣️ **2 minutos:** Pruebo: esquema inválido (va a cuarentena y no llega al caso de uso); el mismo
mensaje dos veces (un solo efecto); caída después del commit y antes del ACK (la segunda entrega
devuelve el resultado anterior); error transitorio (se reintenta con límite); rechazo de negocio (se
registra y se confirma). Y compruebo que el ACK ocurre después del commit, no antes.

🔬 **El detalle:** Un mock del puerto no verifica la coordinación con el broker, que es justamente
donde están los fallos de este adaptador. Contenedores efímeros del broker hacen barata esa prueba.

### 17. 🟠 El commit se completó y el proceso cayó antes del ACK. ¿Qué ocurrirá?

⏱️ **30 segundos:** El broker volverá a entregar el mensaje, y el sistema debe devolver el resultado
anterior sin repetir el efecto.

🗣️ **2 minutos:** Como el ACK no llegó, para el broker el mensaje sigue pendiente, aunque la base ya
confirmó el pedido. Al reiniciar el consumidor, u otra instancia, lo recibirá otra vez. El caso de
uso encontrará la identidad de operación registrada, devolverá el pedido ya creado, el adaptador
responderá igual que la primera vez y enviará el ACK. Resultado: un solo pedido.

🔬 **El detalle:** Sin deduplicación durable, esta caída crearía un segundo pedido o un segundo
cobro. Es el escenario que toda revisión de un consumidor debería preguntar primero.

### 18. 🟠 Un productor republica la misma operación con otro ID de mensaje. ¿Qué revisas?

⏱️ **30 segundos:** La identidad de operación que usa el consumidor para deduplicar y el contrato
con el productor.

🗣️ **2 minutos:** Si solo deduplico por el id de mensaje, la republicación se trata como nueva y se
ejecuta otra vez. Reviso si el mensaje trae una identidad de operación estable que se mantenga entre
republicaciones; si existe, deduplico por ella; si no, la negocio con el productor como parte del
contrato. Mientras tanto, puedo apoyarme en una invariante de negocio equivalente (por ejemplo,
número de pedido externo único).

🔬 **El detalle:** Exijo una clave estable para la misma intención. Sin ella, ningún consumidor puede
ser idempotente de verdad, y el problema aparecerá en el primer reproceso masivo.

### 19. 🟠 El broker entrega fuera de orden dos cambios de pedido. ¿Qué protege el estado?

⏱️ **30 segundos:** Una versión o secuencia por pedido y un caso de uso que rechace transiciones
obsoletas.

🗣️ **2 minutos:** Si "pedido pagado" llega antes que "pedido creado", o "cancelado" antes que
"confirmado", aplicar en orden de llegada deja un estado incorrecto. Cada cambio lleva la versión
del agregado; el caso de uso aplica solo si es la siguiente esperada, descarta las obsoletas y
pospone o reintenta las que llegan antes de tiempo. El control optimista de versión en la base
protege además frente a escrituras concurrentes.

🔬 **El detalle:** No confío en un orden global de entrega si hay particiones, varios productores o
reintentos. Kafka garantiza orden por partición y clave; eso ayuda si la clave es el `orderId`, pero
no si alguien publica sin clave.

### 20. 🟠 Un error de negocio conocido se reintenta para siempre. ¿Qué cambias?

⏱️ **30 segundos:** Clasifico ese rechazo como permanente: se registra y se confirma, no se
reintenta.

🗣️ **2 minutos:** `InsufficientInventory` no va a desaparecer reintentando el mismo mensaje cada
segundo. Registro el resultado —y si el flujo es petición-respuesta, respondo al productor con el
rechazo—, envío el ACK y sigo. Si el contrato lo pide, lo desvío a una cola de rechazos para que el
otro sistema actúe. Lo que no hago es tratarlo como un fallo de infraestructura.

🔬 **El detalle:** Mezclar rechazos de negocio con fallos técnicos es la causa típica de estos
bucles: el adaptador captura cualquier excepción y la trata como reintentable. La taxonomía de
errores del núcleo existe para evitarlo.

### 21. 🟠 Un `@KafkaListener` contiene SQL y reglas. ¿Cómo repartes responsabilidades?

⏱️ **30 segundos:** Extraigo la intención a un caso de uso; el listener queda como adaptador de
entrada y la persistencia detrás de un puerto.

🗣️ **2 minutos:** El listener deserializa, valida el esquema, construye el comando, llama al caso de
uso y gestiona el commit de offset y la clasificación de errores. El caso de uso aplica las reglas y
usa `Orders` para persistir, dentro de una transacción. La deduplicación se hace en el caso de uso
por identidad de operación. Así la misma regla puede invocarse desde HTTP y la lógica se prueba sin
Kafka.

🔬 **El detalle:** Pruebo el momento del commit de offset y la redelivery, no solo el método del
listener. Mover el código es la parte fácil; el riesgo real es que el commit de offset quede antes
del commit de la base.

### 22. 🟠 Un handler de NestJS asume que `@EventPattern()` da entrega exactamente una vez. ¿Qué corriges?

⏱️ **30 segundos:** La suposición: ninguna anotación garantiza efecto único de extremo a extremo; el
efecto local necesita idempotencia.

🗣️ **2 minutos:** El transporte configurado puede repetir entregas por reconexión, timeout o
reinicio, y algunos transportes ni siquiera confirman: pueden perder. Reviso la semántica real de
ACK del transporte (manual o automático, antes o después del handler), hago que el handler invoque
un caso de uso idempotente por identidad de operación y confirmo después del commit.

🔬 **El detalle:** `@EventPattern()` es un mecanismo de enrutado, no una garantía de entrega. La
garantía la construye el diseño: ACK tras commit, deduplicación y cuarentena.

### 23. 🟠 La DLQ crece y nadie la revisa. ¿Qué capacidad operativa falta?

⏱️ **30 segundos:** Falta ownership del reproceso: alguien responsable, alertas y un procedimiento.

🗣️ **2 minutos:** Defino un equipo responsable, alertas por volumen y por antigüedad, retención
acorde al negocio, un procedimiento para inspeccionar y corregir (arreglar el bug, pedir al
productor que corrija el dato) y una forma segura de reinyectar mensajes, con registro de quién lo
hizo. También clasifico las causas: si la mayoría son del mismo tipo, hay un problema sistemático
que arreglar.

🔬 **El detalle:** La métrica de edad del mensaje más antiguo suele ser más útil que el conteo: diez
mensajes de hace un mes son más graves que mil de hace un minuto.

### 24. 🟠 El mismo comando llega por HTTP y mensajería. ¿Dónde haces idempotencia?

⏱️ **30 segundos:** En el caso de uso o servicio de aplicación, junto al efecto, con una identidad
de operación común.

🗣️ **2 minutos:** HTTP aporta la identidad desde `Idempotency-Key`; el broker, desde el
identificador de operación del mensaje. Ambos adaptadores la ponen en el mismo campo del comando, y
el caso de uso la registra en la misma transacción que crea el pedido. Así la misma operación,
llegue por donde llegue y cuantas veces llegue, se aplica una vez.

🔬 **El detalle:** No uso exclusivamente el header HTTP ni el offset de Kafka: cada uno solo ve su
propio transporte, y la deduplicación quedaría partida entre entradas.

---

## 03 · Jobs, CLI y procesos batch

### 1. 🟢 ¿Qué tienen en común un job, una CLI y HTTP como entradas?

⏱️ **30 segundos:** Que los tres son drivers de un puerto de entrada: traducen su disparador a un
comando y llaman al mismo caso de uso.

🗣️ **2 minutos:** Cambia quién dispara (un reloj, una persona en una terminal, un cliente remoto) y
cómo se representa el resultado (métricas y checkpoint, texto y código de salida, status y JSON),
pero no la regla de `ConfirmOrder`. Si el cron confirma pedidos con su propio SQL y la API con el
caso de uso, las dos políticas divergen al primer cambio. Con un único caso de uso, cambiar la regla
afecta a todas las entradas a la vez.

🔬 **El detalle:** Cada adaptador puede tener sus propios permisos (el job opera con una identidad de
servicio, la CLI con la del operador) y su propia forma de reaccionar a los errores, sin tocar la
política común.

### 2. 🟢 ¿Qué decide el scheduler y qué decide el caso de uso?

⏱️ **30 segundos:** El scheduler decide cuándo y sobre qué ejecutar; el caso de uso decide si cada
pedido puede confirmarse.

🗣️ **2 minutos:** El adaptador del job elige el momento, selecciona la página de pedidos pendientes,
toma un lease si hay varias réplicas, invoca el caso de uso por pedido, guarda el checkpoint y
reporta progreso. La aplicación aplica la política y las invariantes: si el pedido está en un estado
confirmable, si el inventario sigue disponible. El scheduler coordina la ejecución; no interpreta el
negocio.

🔬 **El detalle:** El cron no debe convertirse en una segunda implementación de negocio. Si para
escribir el job hace falta copiar reglas del caso de uso, lo que falta es un puerto de entrada que
el job pueda llamar.

### 3. 🟢 ¿Qué es un checkpoint de lote?

⏱️ **30 segundos:** La posición durable desde la que un lote puede reanudarse tras una caída sin
empezar desde cero.

🗣️ **2 minutos:** Puede ser el último id procesado, un cursor, un número de línea o el estado de un
paso en un `JobRepository`. Se guarda después de confirmar una unidad de trabajo (un pedido, un
chunk de cien líneas), de modo que al reanudar se continúa desde ahí. Sin checkpoint, un lote de
diez horas que cae en la hora nueve vuelve a empezar.

🔬 **El detalle:** Como puede haber una caída entre confirmar el efecto y guardar el checkpoint, el
caso de uso debe tolerar que la última unidad se repita. El checkpoint dice desde dónde seguir; la
idempotencia hace seguro repetir.

### 4. 🟢 ¿Para qué sirve un lock o lease en un job?

⏱️ **30 segundos:** Para evitar o coordinar ejecuciones concurrentes del mismo trabajo entre varias
réplicas o lanzamientos.

🗣️ **2 minutos:** Si el mismo job arranca en tres réplicas, un lease en la base (una fila con dueño
y vencimiento) hace que solo una trabaje. Un lease tiene vencimiento para que, si el dueño cae, otro
pueda tomar el trabajo, y por eso puede requerir renovación periódica mientras se ejecuta. En Spring
Batch, la propia fila de ejecución en estado `STARTED` actúa como lease sobre el `JobInstance`.

🔬 **El detalle:** No reemplaza la idempotencia ante caídas o particiones de red: un lease puede
vencer mientras el primer proceso sigue trabajando (una pausa larga del GC, por ejemplo), y durante
un momento habrá dos.

### 5. 🟢 ¿Qué es un `dry-run`?

⏱️ **30 segundos:** Una ejecución que evalúa e informa qué haría sin aplicar ningún efecto.

🗣️ **2 minutos:** Es muy útil para operadores: "este lote confirmaría 1.200 pedidos y rechazaría 3".
Pero debe tener semántica explícita en la aplicación: el caso de uso ofrece un modo de evaluación
que aplica las reglas y devuelve el resultado sin persistir ni llamar a sistemas externos. Así el
`dry-run` refleja la regla real y no una aproximación.

🔬 **El detalle:** Hacer llamadas externas y luego un rollback no es un `dry-run` seguro: el rollback
local no deshace una autorización de pago, un correo enviado ni un mensaje publicado.

### 6. 🟢 ¿Qué debe expresar el exit code de una CLI?

⏱️ **30 segundos:** Éxito, fallo parcial o error de invocación, según un contrato documentado.

🗣️ **2 minutos:** `0` si todo fue bien; un código distinto si hubo elementos fallidos pero el
proceso completó; otro si los argumentos eran inválidos; otro si hubo un fallo técnico que impidió
ejecutar. Los scripts de operación y los orquestadores (cron, CI, Kubernetes Jobs) actúan según ese
código, y el resumen en texto le dice a la persona qué pasó. Mezclarlos todos en `1` obliga a leer
logs para decidir.

🔬 **El detalle:** Que un proceso terminara no significa que cada elemento terminara bien. Un lote
que procesa mil pedidos y falla en tres debe reflejarlo en el código y en el resumen, no salir con
`0`.

### 7. 🟢 ¿Por qué el dominio no recibe `argv`?

⏱️ **30 segundos:** Porque `argv` es un detalle de la CLI, igual que un request es un detalle de
HTTP.

🗣️ **2 minutos:** El adaptador de CLI parsea los argumentos con la biblioteca del lenguaje, valida
flags y rangos, y construye un comando propio (`ConfirmOrderCommand(orderId, operationId)`). El caso
de uso no sabe que existe una terminal. Así el mismo caso de uso puede invocarse desde HTTP, desde
un job o desde una prueba, y la CLI puede cambiar sus flags sin tocar la aplicación.

🔬 **El detalle:** El mismo caso debe poder invocarse desde HTTP o pruebas sin fabricar una línea de
comandos. Si una prueba del núcleo tiene que construir `argv`, la frontera está mal puesta.

### 8. 🟡 ¿Por qué prefieres transacciones pequeñas en batch?

⏱️ **30 segundos:** Para limitar bloqueos, memoria y el alcance de un rollback.

🗣️ **2 minutos:** Una transacción por todo el lote bloquea filas durante horas, acumula cambios en
memoria y, si falla en el elemento 9.000 de 10.000, revierte todo el trabajo hecho. Procesando por
pedido o por grupo pequeño (un chunk), cada transacción es corta, un fallo solo afecta a su unidad y
el checkpoint permite reanudar. La unidad correcta es la de consistencia de negocio, no la del
archivo.

🔬 **El detalle:** Un lote completo en una transacción no vuelve atómicos los pagos ni los correos
remotos: si el lote los dispara, siguen necesitando outbox o estados pendientes.

### 9. 🟡 ¿Cuándo guardas el checkpoint?

⏱️ **30 segundos:** Después de que el efecto de la unidad quedó confirmado, nunca antes.

🗣️ **2 minutos:** Si el checkpoint se adelanta al efecto y el proceso cae, al reanudar se salta una
unidad que nunca se aplicó: trabajo perdido en silencio. Guardándolo después, la peor consecuencia
de una caída es repetir la última unidad. Lo ideal es guardar checkpoint y efecto en la misma
transacción cuando están en la misma base, como hace Spring Batch con el contexto de ejecución del
step en cada commit de chunk.

🔬 **El detalle:** Si checkpoint y efecto no pueden compartir transacción, la caída entre ambos exige
idempotencia en la unidad: se repetirá, y debe ser seguro repetirla.

### 10. 🟡 ¿Por qué un cursor estable supera a paginar por offset mutable?

⏱️ **30 segundos:** Porque con offset las filas pueden moverse entre páginas cuando se insertan,
borran o cambian datos durante el recorrido.

🗣️ **2 minutos:** Si un job procesa pedidos pendientes con `OFFSET 100 LIMIT 100` y mientras tanto
confirma los primeros cien (que dejan de ser pendientes), la siguiente página salta cien pedidos. Un
cursor por clave y orden estables (`WHERE id > :last ORDER BY id LIMIT 100`) avanza por posición
real y no se ve afectado por los cambios de las páginas anteriores. Además es más eficiente en
tablas grandes.

🔬 **El detalle:** Hay que definir la semántica ante datos nuevos: ¿un pedido pendiente creado
durante la ejecución entra en este lote o en el siguiente? Un snapshot (fecha de corte) hace la
respuesta explícita.

### 11. 🟡 ¿Qué relación hay entre lease e idempotencia?

⏱️ **30 segundos:** El lease reduce el solapamiento de ejecuciones; la idempotencia protege las
repeticiones que el lease no puede evitar.

🗣️ **2 minutos:** Un lease vence para que otro pueda tomar el trabajo si el dueño cae; pero si el
dueño no cayó sino que se pausó (GC, red lenta), durante un momento dos procesos creen tener el
lease y ambos trabajan. Además, un lease no protege contra caídas entre efecto y checkpoint. Por
eso, junto al lease, cada unidad usa una identidad de operación estable y una restricción única
junto al efecto.

🔬 **El detalle:** Uso identidades de operación y restricciones junto al efecto como garantía; el
lease es una optimización para no hacer trabajo duplicado, no la garantía de corrección.

### 12. 🟡 ¿Cómo propagas cancelación en Go sin contaminar el dominio?

⏱️ **30 segundos:** Pasando `context.Context` por el puerto de aplicación y los adaptadores de I/O,
no por las entidades.

🗣️ **2 minutos:** El runner del job crea un contexto con deadline o cancelación (por ejemplo, al
recibir SIGTERM), y lo pasa a `useCase.Execute(ctx, ...)`, que lo propaga a los repositorios y
clientes remotos. Esos adaptadores respetan `ctx.Done()` y abortan las operaciones en curso. La
entidad de dominio, que no hace I/O, no necesita recibirlo: sus métodos son síncronos y puros.

🔬 **El detalle:** La cancelación no debe dejar un checkpoint adelantado: si se cancela a mitad de
una unidad, esa unidad no se confirma y el checkpoint se queda en la anterior.

### 13. 🟡 ¿Qué observabilidad necesita un proceso nocturno?

⏱️ **30 segundos:** Duración, elementos procesados con éxito, fallidos y pendientes, y edad del
último checkpoint.

🗣️ **2 minutos:** Cada ejecución tiene un identificador de correlación y cada elemento se puede
rastrear hasta ella sin exponer datos sensibles. Métricas de ritmo (elementos por minuto) permiten
saber si terminará a tiempo; los fallidos, con su causa clasificada, dicen si hay un problema
sistemático. El resumen final se registra y, si el contrato lo pide, se envía a los responsables.

🔬 **El detalle:** Una métrica de "último éxito" con alerta detecta el fallo más traicionero de los
jobs: que dejaron de ejecutarse y nadie se enteró porque no hay errores que ver.

### 14. 🟡 ¿Qué riesgo tiene `@Scheduled` con varias réplicas de Spring?

⏱️ **30 segundos:** Que cada réplica ejecuta la misma tarea programada: con tres réplicas, el job
corre tres veces.

🗣️ **2 minutos:** `@Scheduled` es local al proceso; no sabe que hay otras instancias. Si el job
tiene efectos duplicables (confirmar pedidos, enviar correos, cobrar), necesito un coordinador: un
lock distribuido (ShedLock o una fila en la base), un scheduler externo que lance una sola ejecución
(Kubernetes CronJob), o una partición explícita del trabajo entre réplicas. Y, en cualquier caso,
idempotencia por elemento.

🔬 **El detalle:** La elección depende del scheduler y de la topología de despliegue. Lo que no se
puede asumir es que "solo hay una instancia", porque los despliegues sin caída levantan la nueva
antes de bajar la vieja.

### 15. 🟡 ¿Por qué `setInterval` de Node no es una cola durable?

⏱️ **30 segundos:** Porque vive en la memoria del proceso: si el proceso cae o se reinicia, el
trabajo pendiente y el progreso desaparecen.

🗣️ **2 minutos:** `setInterval` resuelve "ejecuta esto cada N segundos", nada más. No sabe qué quedó
a medias, no reintenta, no coordina con otras instancias y no sobrevive a un despliegue. Si el
trabajo debe sobrevivir, guardo el estado en la base (una tabla de pendientes con su estado) o uso
un scheduler o una cola durables, y el timer, si queda, solo dispara la lectura de ese estado.

🔬 **El detalle:** Un timer resuelve tiempo, no reanudación ni idempotencia. Además, sus callbacks
necesitan dueño: una promesa rechazada dentro de un intervalo sin manejo puede tumbar el proceso o
perderse en silencio.

### 16. 🟡 ¿Qué valida una CLI antes de invocar el caso de uso?

⏱️ **30 segundos:** La forma y coherencia de los argumentos, los rangos y los permisos del operador.

🗣️ **2 minutos:** Que los flags obligatorios estén, que los ids tengan formato válido, que las
fechas sean fechas, que no se combinen opciones incompatibles y que el operador tenga credenciales
para la operación. Si algo falla, muestra un error de uso claro y sale con el código correspondiente
sin llamar al núcleo. Si todo es correcto, construye un comando propio y lo invoca.

🔬 **El detalle:** La validación de la CLI no sustituye las invariantes del dominio: "el pedido
existe y está pendiente" lo decide el caso de uso, no el parser de argumentos.

### 17. 🟠 El job cae después de procesar un pedido y antes del checkpoint. ¿Qué ocurre al reanudar?

⏱️ **30 segundos:** Volverá a procesar ese pedido, y la idempotencia hará que no se repita el
efecto.

🗣️ **2 minutos:** Al reanudar, el checkpoint apunta al pedido anterior, así que el job lee otra vez
el que ya confirmó. Como la invocación lleva una identidad de operación estable (por ejemplo,
`confirm:<orderId>`), el caso de uso encuentra que ya se aplicó y devuelve el resultado confirmado
sin volver a confirmar, cobrar ni notificar. El job avanza el checkpoint y sigue.

🔬 **El detalle:** El checkpoint se guarda después del efecto y no debe saltarse un elemento que
falló: si falló, se reintenta o se registra como fallido, pero no se da por procesado.

### 18. 🟠 Dos réplicas ejecutan el mismo cron. ¿Cómo evitas daño?

⏱️ **30 segundos:** Coordinando con un lock o una partición del trabajo, y con idempotencia en el
caso de uso como garantía final.

🗣️ **2 minutos:** El lock (una fila con dueño y vencimiento, o una herramienta como ShedLock) hace
que normalmente solo una réplica trabaje. La partición (cada réplica procesa un rango de ids) evita
el conflicto por diseño. Pero si el lock vence o se rompe, las dos pueden procesar el mismo pedido;
una identidad de operación estable con restricción única evita que eso produzca dos efectos.

🔬 **El detalle:** Mido los solapamientos (cuántas veces dos ejecuciones coincidieron) para detectar
configuraciones defectuosas: un lock que vence antes de que el job termine, por ejemplo.

### 19. 🟠 El lote contiene un registro inválido entre mil válidos. ¿Qué política defines?

⏱️ **30 segundos:** Decido explícitamente si el lote se detiene, aísla el registro y continúa, o
continúa hasta un límite de errores, y cómo se reporta el resultado parcial.

🗣️ **2 minutos:** Si el contrato lo permite, el registro inválido se aparta a una cuarentena con su
causa y el lote sigue con los otros 999, informando al final "999 aplicados, 1 en cuarentena". Si el
archivo es todo o nada (un cierre contable), el lote se detiene sin aplicar nada. Un límite de
errores (por ejemplo, más de 10) distingue un dato malo de un archivo corrupto.

🔬 **El detalle:** No avanzo el checkpoint de forma que oculte errores pendientes: los registros
apartados quedan visibles y trazables, y el resultado del lote refleja que hubo excepciones.

### 20. 🟠 Un `dry-run` llama un proveedor de pagos y luego hace rollback. ¿Qué corriges?

⏱️ **30 segundos:** Construyo una evaluación sin efectos en la aplicación, o retiro la opción hasta
tenerla.

🗣️ **2 minutos:** El rollback local no deshace una autorización de pago, ni una notificación, ni un
mensaje publicado: el `dry-run` actual cobra de verdad. El caso de uso debe ofrecer un modo de
evaluación que aplique las reglas y devuelva el resultado previsto sin llamar a puertos con efectos
externos (o llamando a sus operaciones de consulta, si las hay). La CLI invoca ese modo.

🔬 **El detalle:** La interfaz debe decir con claridad qué puede observar sin mutar. Si alguna parte
del resultado solo se sabe llamando al proveedor, el `dry-run` debe decir "no evaluable sin efectos"
en lugar de simularlo.

### 21. 🟠 La CLI escribe SQL para confirmar pedidos. ¿Cómo la reconectas al núcleo?

⏱️ **30 segundos:** Haciendo que la CLI llame al mismo puerto `ConfirmOrder` que usan HTTP y el job.

🗣️ **2 minutos:** La CLI conserva lo suyo: parseo y validación de flags, credenciales del operador,
resumen y códigos de salida. En lugar de ejecutar SQL, construye `ConfirmOrderCommand` y llama al
caso de uso, que aplica las reglas del dominio y persiste por `Orders`. El SQL queda detrás de un
adaptador de salida. Así la CLI no puede confirmar pedidos que la API rechazaría.

🔬 **El detalle:** Conservo la validación de flags y los exit codes en la CLI, y añado una prueba que
compare el resultado de confirmar por CLI y por HTTP: si divergen, la regla vuelve a estar
duplicada.

### 22. 🟠 Un batch de diez horas bloquea filas todo el tiempo. ¿Cómo cambias el límite?

⏱️ **30 segundos:** Partiendo el trabajo en unidades pequeñas, cada una con su propia transacción
corta.

🗣️ **2 minutos:** Confirmo por pedido o por grupo pequeño (chunk) y persisto el progreso entre
unidades con un checkpoint. Cada transacción bloquea solo sus filas y durante segundos; el resto del
sistema puede seguir trabajando. Si el lote falla, se reanuda desde el último checkpoint en lugar de
repetir diez horas. La idempotencia por unidad hace segura la repetición de la última.

🔬 **El detalle:** También limito la concurrencia (cuántas unidades en paralelo) y la duración máxima
de cada transacción, y programo el lote en ventanas de menor carga si compite con el tráfico
interactivo.

### 23. 🟠 Un operador reintenta manualmente una ejecución parcial. ¿Qué identificadores conservas?

⏱️ **30 segundos:** La identidad de la ejecución y la identidad de operación de cada pedido.

🗣️ **2 minutos:** La identidad de operación por pedido (derivada del pedido y de la acción, no de la
ejecución) hace que relanzar no genere un segundo efecto: los pedidos ya confirmados devuelven su
resultado anterior y solo se procesan los pendientes. La identidad de ejecución permite reanudar
desde su checkpoint o distinguir en los informes qué hizo cada intento.

🔬 **El detalle:** Guardo la correlación para distinguir un nuevo intento de la misma intención
(reanudar, no duplicar) de una nueva intención (otro lote, con otros datos). Si ambos comparten
identidad, el sistema no puede diferenciarlos.

### 24. 🟠 ¿Cuándo evitarías construir un framework de jobs propio?

⏱️ **30 segundos:** Cuando el volumen y el riesgo caben en un script bien escrito o en un scheduler
existente.

🗣️ **2 minutos:** Antes de construir infraestructura, aseguro lo mínimo: idempotencia por elemento,
límites de tamaño y tiempo, checkpoint si el lote es largo, y observabilidad básica (último éxito,
fallidos). Con eso, un CronJob que ejecuta una CLI del propio servicio suele bastar. Si las
necesidades crecen (reinicios, particionado, historial de ejecuciones), existen herramientas maduras
como Spring Batch o schedulers gestionados.

🔬 **El detalle:** Un framework de jobs propio añade operación, documentación y mantenimiento sin
mejorar la política de negocio. Es código que alguien tendrá que depurar de madrugada.

---

## 04 · Autenticación, autorización y contexto de actor

### 1. 🟢 ¿Qué diferencia hay entre autenticación y autorización?

⏱️ **30 segundos:** La autenticación comprueba quién presenta la credencial y si es válida; la
autorización decide si ese actor puede hacer esta acción sobre este recurso.

🗣️ **2 minutos:** Un token firmado y vigente prueba que la petición viene de Ana; no prueba que Ana
pueda cancelar el pedido de Luis. La autenticación ocurre en el borde, una vez, con el mecanismo del
transporte (JWT, certificado, sesión). La autorización tiene dos niveles: una comprobación gruesa en
el borde (¿está autenticado?, ¿tiene el rol mínimo para esta ruta?) y otra contextual en la
aplicación, que necesita cargar el recurso.

🔬 **El detalle:** Puede haber autorización gruesa en el borde y contextual en la aplicación, y ambas
son necesarias: la primera ahorra trabajo, la segunda protege la acción desde cualquier driver.

### 2. 🟢 ¿Qué es un actor de aplicación?

⏱️ **30 segundos:** Una identidad mínima y confiable que la aplicación entiende, construida por el
adaptador después de autenticar.

🗣️ **2 minutos:** `Actor(id, tenantId, kind, capabilities)`: identificador verificado, tenant, tipo
(usuario o servicio) y las capacidades que la política necesita. No contiene el JWT crudo, claims
sin verificar, un `SecurityContext` ni ningún objeto del framework. Cualquier entrada puede
construirlo: HTTP desde el token, un job con una identidad de servicio, una prueba con un valor
fijo.

🔬 **El detalle:** Puede representar un usuario o un servicio, con tipos y permisos distintos.
Distinguirlos explícitamente evita que un job "se haga pasar" por un usuario que nunca pidió la
acción.

### 3. 🟢 ¿Dónde se verifica un JWT recibido por HTTP?

⏱️ **30 segundos:** En el adaptador de entrada HTTP o su middleware de seguridad, antes de llegar al
caso de uso.

🗣️ **2 minutos:** El middleware valida la firma con la clave correcta, la expiración, la audiencia y
el emisor, y comprueba si el token fue revocado (por ejemplo, por `jti` en una lista de revocación).
Si todo es correcto, extrae los claims permitidos y construye el `Actor`; si no, responde `401` sin
llamar al núcleo. En Spring es Spring Security; en Nest, un guard; en FastAPI, una dependencia; en
Go, un middleware.

🔬 **El detalle:** El dominio no importa ninguna biblioteca JWT ni conoce el formato del token. Si
mañana se cambia a sesiones o a mTLS, solo cambia el adaptador.

### 4. 🟢 ¿Qué dato de identidad no debes confiar al body público?

⏱️ **30 segundos:** Un `actorId` o `userId` enviado en el cuerpo de la petición como prueba de quién
invoca.

🗣️ **2 minutos:** Cualquier cliente puede escribir cualquier cosa en el body. Un campo `customerId`
puede describir a un tercero legítimamente (un operador que crea un pedido para un cliente), pero
nunca prueba quién está llamando. La identidad del invocante sale de la credencial verificada; si el
body menciona a otro, la aplicación decide si el actor tiene permiso para actuar en su nombre.

🔬 **El detalle:** La identidad confiable viene de la credencial verificada. Confiar en el body para
identidad es una de las vulnerabilidades más comunes y más fáciles de explotar.

### 5. 🟢 ¿Qué es una autorización contextual?

⏱️ **30 segundos:** Un permiso que depende del actor y del recurso concretos, no solo del rol del
actor.

🗣️ **2 minutos:** "Solo el dueño del pedido o un operador de su mismo tenant puede cancelarlo"
depende de quién es el dueño del pedido y a qué tenant pertenece, datos que solo se conocen al
cargar el pedido. Por eso no puede decidirse en el middleware HTTP, que no tiene el recurso, y vive
en el caso de uso, que lo carga y compara con el actor antes de invocar al dominio.

🔬 **El detalle:** El caso de uso carga el pedido antes de decidir. Y la respuesta al "no" suele ser
un `404` indistinguible de "no existe", para no revelar recursos ajenos.

### 6. 🟢 ¿Qué invariante conserva el dominio al cancelar un pedido?

⏱️ **30 segundos:** Que el estado del pedido permita la cancelación: uno enviado o ya cancelado no
se cancela.

🗣️ **2 minutos:** Aunque el actor tenga permiso —es el dueño o un operador—, `Order.cancel()`
comprueba que la transición sea válida y falla con un error propio si no lo es. Esa regla vale para
cualquier actor y cualquier entrada, por eso vive en la entidad y no en la aplicación. La
autorización decide quién puede intentarlo; la invariante decide si el pedido puede cambiar.

🔬 **El detalle:** La regla debe sobrevivir a cualquier entrada, incluidos un job de mantenimiento o
un script de migración que usen el dominio. Si la protección estuviera solo en el controller, esos
caminos podrían saltársela.

### 7. 🟢 ¿Qué registra una auditoría útil sin exponer secretos?

⏱️ **30 segundos:** Actor, acción, recurso, resultado, momento y correlación.

🗣️ **2 minutos:** "Ana (usuario, tenant X) intentó cancelar el pedido 123 a las 10:02; resultado:
rechazado por estado; correlación abc". Eso permite responder quién hizo qué, cuándo y con qué
resultado, y enlazarlo con los logs técnicos. La aplicación decide qué registrar porque conoce la
semántica; la infraestructura almacena y protege el registro.

🔬 **El detalle:** Se evita guardar tokens, secretos o payloads completos, y la auditoría necesita su
propia protección (acceso restringido, integridad) y una política de retención acorde a la
regulación.

### 8. 🟡 ¿Por qué un rol global no basta para cancelar cualquier pedido?

⏱️ **30 segundos:** Porque faltan el dueño, el tenant y el estado del pedido: un rol dice qué tipo
de actor eres, no sobre qué recursos puedes actuar.

🗣️ **2 minutos:** Un rol `ADMIN` que permite cancelar "cualquier pedido" ignora que en un sistema
multitenant un operador de un cliente no debería tocar pedidos de otro, que algunos pedidos tienen
reglas propias y que el estado puede impedirlo. La política contextual combina el rol con el
recurso: operador y mismo tenant, o dueño del pedido.

🔬 **El detalle:** La política contextual vive cerca del caso de uso, donde se carga el recurso. El
rol puede seguir usándose en el borde como filtro grueso.

### 9. 🟡 ¿Cómo autorizas un job que no representa a un usuario?

⏱️ **30 segundos:** Con una identidad de servicio explícita y capacidades limitadas a lo que ese job
necesita.

🗣️ **2 minutos:** El job se ejecuta con un `Actor` de tipo servicio (por ejemplo, `batch@...`, con
rol operador y solo las capacidades de ajustar stock), construido en su composition root. Pasa por
la misma autorización del caso de uso que cualquier otro actor. No invento un usuario ficticio ni
omito los controles por venir de la red interna: si alguien compromete el job, sus permisos deben
ser acotados.

🔬 **El detalle:** Audito la acción como realizada por el servicio y enlazo con la ejecución del job,
para poder distinguir "lo hizo el cierre nocturno del día X" de "lo hizo una persona".

### 10. 🟡 ¿Por qué pasas `Actor` explícitamente al caso de uso?

⏱️ **30 segundos:** Para que sea una entrada visible de la decisión, igual que los demás datos del
comando.

🗣️ **2 minutos:** Con el actor en el comando, la firma del caso de uso dice que la decisión depende
de quién opera; un job y una prueba proporcionan su actor sin necesidad de un contexto HTTP; y no
hay forma de invocar el caso de uso "sin actor" por accidente. Si el actor se lee de un contexto
implícito, un driver que no lo establece ejecuta la regla sin permisos, o con los de otra petición.

🔬 **El detalle:** Evito leer `SecurityContextHolder` o equivalentes desde el dominio o la
aplicación. Los contextos implícitos están bien para correlación y logs; para política, no.

### 11. 🟡 ¿Qué verifica el borde antes de construir `Actor`?

⏱️ **30 segundos:** La validez y el origen de la credencial: firma, emisor, audiencia, expiración y
revocación.

🗣️ **2 minutos:** Solo después de esas comprobaciones extrae los claims que la aplicación necesita
(identificador, tenant, rol) y los convierte en el `Actor`, descartando los demás. Si la identidad
llega de un proxy o gateway, verifica que el canal sea confiable (red privada, mTLS, firma del
header) antes de aceptarla. El resultado es un actor en el que la aplicación puede confiar sin
repetir comprobaciones.

🔬 **El detalle:** Un header de identidad sin confianza no basta: `X-User-Id` en una petición que
puede venir directamente de internet es una invitación a suplantar.

### 12. 🟡 ¿Cuándo una consulta de permisos merece un puerto de salida?

⏱️ **30 segundos:** Cuando la decisión necesita datos de un sistema externo de permisos o de una
fuente que cambia con frecuencia.

🗣️ **2 minutos:** Si los permisos viven en un servicio de autorización (políticas por recurso,
delegaciones, listas de acceso), el caso de uso depende de un contrato propio
(`Permissions.canCancel(actor, order)`) y un adaptador consulta al proveedor. Así la política sigue
siendo explícita y probable con un fake, y el proveedor se puede cambiar. Si los permisos caben en
el token y cambian poco, no hace falta.

🔬 **El detalle:** Defino la latencia aceptable, la caché (y su ventana de revocación) y la conducta
ante fallo: para acciones sensibles, fallar cerrado (denegar) si no se puede consultar.

### 13. 🟡 ¿Qué diferencia hay entre un guard de NestJS y una regla de ownership?

⏱️ **30 segundos:** El guard filtra el acceso a una ruta; la regla de ownership compara el actor con
un recurso concreto.

🗣️ **2 minutos:** Un guard se ejecuta antes del handler y suele decidir con lo que tiene: el token,
el rol, la ruta. No conoce el pedido, porque cargarlo es trabajo del caso de uso. La regla "solo el
dueño puede cancelar" necesita el pedido cargado, así que vive en la aplicación. Además, un guard
solo protege HTTP; la regla de ownership en el caso de uso protege cualquier entrada.

🔬 **El detalle:** Pueden coexistir como defensas con responsabilidades distintas: el guard rechaza
pronto a quien no tiene ni el rol mínimo; el caso de uso decide sobre el recurso.

### 14. 🟡 ¿Qué riesgo tiene `SecurityContextHolder` dentro del dominio Java?

⏱️ **30 segundos:** Acopla la regla a Spring Security y al hilo de la petición HTTP.

🗣️ **2 minutos:** `SecurityContextHolder` guarda la autenticación en un `ThreadLocal` que Spring
rellena al procesar una petición. Un job, un consumidor de mensajes o un proceso asíncrono se
ejecutan en otros hilos donde ese contexto está vacío o contiene otra cosa: la regla puede lanzar
una excepción, o peor, ejecutarse sin control de permisos. Además, las pruebas del dominio necesitan
preparar ese contexto.

🔬 **El detalle:** Paso `Actor` explícito al caso de uso. El adaptador HTTP es el único que lee
`SecurityContextHolder`, para construirlo.

### 15. 🟡 ¿Cómo evitas confiar en un header de identidad en Go?

⏱️ **30 segundos:** Aceptando identidad solo desde un middleware que verifica su origen y la pone en
el `context` con una clave tipada.

🗣️ **2 minutos:** El middleware valida el token o el certificado; si la identidad viene de un proxy,
comprueba que la petición llega por el canal confiable (red interna, mTLS, firma) y descarta el
header si no. Después guarda el actor verificado en el contexto con una clave privada del paquete,
de modo que ningún otro código pueda falsificarla. El handler lo recupera y lo pasa explícitamente
al caso de uso.

🔬 **El detalle:** El `context` transporta un valor ya validado, no lo valida por sí mismo. Un
handler que lee `r.Header.Get("X-User-Id")` directamente confía en cualquiera.

### 16. 🟡 ¿Qué casos mínimos pruebas para una política por tenant?

⏱️ **30 segundos:** Dueño, tercero, operador del mismo tenant y operador de otro tenant.

🗣️ **2 minutos:** El dueño puede cancelar su pedido; un tercero no (y recibe `404`, no `403`); un
operador del mismo tenant puede; uno de otro tenant no. También cubro el pedido en estado no
cancelable (rechazo de dominio, aunque el actor tenga permiso) y el actor de servicio (el job de
mantenimiento, con sus capacidades limitadas). Esas pruebas van contra el caso de uso, con fakes, y
son rápidas.

🔬 **El detalle:** Una prueba de "ruta autenticada devuelve 200" no demuestra autorización
contextual: solo demuestra que el token era válido.

### 17. 🟠 HTTP autoriza por rol, pero batch cancela sin control. ¿Qué mueves?

⏱️ **30 segundos:** Muevo las reglas de ownership y tenant al caso de uso, para que cualquier
entrada pase por ellas.

🗣️ **2 minutos:** El controller conserva la autenticación y el filtro grueso por rol. El batch
construye un actor de servicio con sus capacidades y llama al mismo `CancelOrder`. El caso de uso
carga el pedido, compara con el actor y decide; el dominio protege el estado. Ahora el batch solo
puede cancelar lo que su identidad le permite, y si alguien le da demasiados permisos, es una
decisión visible en su configuración.

🔬 **El detalle:** Pruebo ambos drivers con el mismo contrato: la misma matriz de actores contra el
caso de uso, y una prueba de cada adaptador que confirme que construye el actor correcto.

### 18. 🟠 Un request trae `actorId` distinto al token. ¿Cuál usas y por qué?

⏱️ **30 segundos:** Uso la identidad de la credencial verificada; el `actorId` del body no autentica
a nadie.

🗣️ **2 minutos:** El body puede legítimamente describir a otra persona (un operador que actúa sobre
el pedido de un cliente), pero entonces se trata como un dato de la operación, y la aplicación
decide si el actor autenticado tiene permiso para actuar sobre ese recurso. Nunca se usa para
decidir quién está llamando. Si el campo no tiene razón de existir, lo elimino del contrato.

🔬 **El detalle:** Registro las discrepancias sospechosas (un cliente que envía el id de otro) en
auditoría, sin revelar en la respuesta si el otro usuario existe.

### 19. 🟠 Un servicio reenvía claims de usuario a otro proceso. ¿Qué verificas?

⏱️ **30 segundos:** La confianza en el emisor, la audiencia del token, su vigencia y el alcance de
los claims reenviados.

🗣️ **2 minutos:** El servicio receptor debe verificar el token como si viniera de fuera: firma,
audiencia (¿estaba destinado a este servicio?), expiración. Reenviar el mismo token de usuario a
todos los servicios internos amplía su alcance: cualquier servicio comprometido puede reutilizarlo.
Si el receptor necesita saber en nombre de quién se actúa, prefiero un mecanismo de delegación
(token intercambiado con audiencia específica) o una identidad de servicio con el usuario como dato
auditado.

🔬 **El detalle:** No reenvío ciegamente el token a todos los servicios; cada salto es un lugar más
donde puede filtrarse.

### 20. 🟠 Un operador puede cancelar pedidos ajenos solo en su tenant. ¿Dónde expresas la regla?

⏱️ **30 segundos:** En la aplicación, después de cargar el pedido y con el actor explícito.

🗣️ **2 minutos:** `CancelOrder` carga el pedido; si el actor es su dueño, puede; si es operador y el
tenant del pedido coincide con el suyo, puede; en otro caso, no. La condición combina capacidad (ser
operador) y contexto (el tenant del recurso). Después, `Order.cancel()` conserva la invariante de
estado. La regla queda en un lugar, probada con la matriz de actores.

🔬 **El detalle:** Un guard de ruta puede rechazar antes a quien ni siquiera tiene rol de operador ni
es cliente, pero no puede decidir el tenant del pedido sin cargarlo.

### 21. 🟠 El token expira durante un job largo. ¿Cómo modelas la identidad de ejecución?

⏱️ **30 segundos:** Como una identidad de servicio para la ejecución, no como el token del usuario
que la lanzó.

🗣️ **2 minutos:** Un token de usuario de quince minutos no sirve para una tarea de horas, y
renovarlo desde el job mezcla responsabilidades. El job se ejecuta con su propia identidad de
servicio, con capacidades acotadas. Si se lanzó a petición de un usuario, ese usuario se registra
como solicitante en la ejecución, para auditoría, y la autorización se comprueba al lanzarla.

🔬 **El detalle:** Si el job realmente actúa en nombre del usuario (y sus permisos deben limitar lo
que hace), documento la delegación: qué se delega, por cuánto tiempo y qué pasa si el permiso se
revoca a mitad.

### 22. 🟠 Una caché de permisos permite una acción recién revocada. ¿Qué decides?

⏱️ **30 segundos:** Defino una ventana de revocación aceptable según la sensibilidad de la acción, o
consulto la fuente actual para las sensibles.

🗣️ **2 minutos:** La caché reduce latencia y carga sobre el servicio de permisos, a costa de
vigencia: durante su TTL, un permiso revocado sigue funcionando. Para acciones de bajo riesgo, unos
minutos pueden ser aceptables y se documentan. Para acciones sensibles (reembolsos, cambios de datos
bancarios), exijo comprobación fresca y fallo cerrado si la fuente no responde. También se puede
invalidar la caché al revocar.

🔬 **El detalle:** La caché es una decisión de negocio disfrazada de optimización: alguien tiene que
aceptar explícitamente cuánto tiempo puede durar un permiso revocado.

### 23. 🟠 Una prueba del controller pasa, pero un consumidor elude autorización. ¿Qué prueba falta?

⏱️ **30 segundos:** Una prueba del caso de uso que verifique la autorización con independencia del
driver, y una del consumidor que compruebe que pasa un actor.

🗣️ **2 minutos:** La prueba del controller demostraba que el filtro HTTP funciona, no que la regla
esté en el caso de uso. Añado pruebas del caso de uso con la matriz de actores —si pasan, la regla
está en el sitio correcto— y una prueba del consumidor que confirme que construye un actor (de
servicio o delegado) y que la política se ejecuta. Si el consumidor no tiene forma de construir un
actor, falta diseño, no solo una prueba.

🔬 **El detalle:** La seguridad no debe depender solo del controller. Cada vez que se añade una
entrada, la pregunta "¿con qué identidad actúa?" debe tener respuesta.

### 24. 🟠 ¿Cuándo aceptarías una verificación duplicada en borde y aplicación?

⏱️ **30 segundos:** Cuando el borde rechaza pronto y barato y la aplicación protege la regla común
para todas las entradas.

🗣️ **2 minutos:** Que el middleware HTTP exija estar autenticado y tener un rol mínimo, y que el
caso de uso compruebe ownership y tenant, es redundancia intencional: son dos comprobaciones
distintas con propósitos distintos. Lo que no hago es duplicar la lógica contextual en cada ruta:
eso produce divergencias en cuanto cambia la regla.

🔬 **El detalle:** La redundancia intencional se documenta (qué comprueba cada capa y por qué) y se
prueba en ambas, para que nadie la elimine pensando que es código repetido.

---

## 05 · DTO, mapeo y presentación de errores

### 1. 🟢 ¿Qué es un request DTO?

⏱️ **30 segundos:** El contrato de datos que recibe un transporte: la forma pública del cuerpo de
una petición.

🗣️ **2 minutos:** Define nombres de campos, cuáles son opcionales, formatos (fechas, decimales como
texto) y la versión del contrato. Suele llevar anotaciones de validación y serialización del
framework. Es propiedad del adaptador de entrada y del contrato público de la API: cambia cuando
cambia la API, por decisiones que se negocian con los clientes, no con el negocio.

🔬 **El detalle:** No es por sí mismo la intención de aplicación: el adaptador lo valida y lo traduce
a un comando, añadiendo lo que no viene en el cuerpo (el actor del token, la clave de idempotencia
del header).

### 2. 🟢 ¿Qué diferencia hay entre comando y request DTO?

⏱️ **30 segundos:** El comando representa una acción de la aplicación; el DTO, una representación
externa de datos en un transporte.

🗣️ **2 minutos:** El DTO pertenece al contrato HTTP y a su versión; el comando pertenece a la
aplicación y a su intención. Por eso la v1 y la v2 de la API, con nombres y estructuras distintas,
pueden mapear a un mismo `CreateOrderCommand`, y un consumidor de mensajes puede construir ese
comando desde un formato completamente distinto.

🔬 **El detalle:** El comando no debería cargar decoradores de serialización ni de validación del
framework: si los lleva, el núcleo vuelve a depender del transporte y de su biblioteca.

### 3. 🟢 ¿Qué es un response DTO?

⏱️ **30 segundos:** La representación de salida para un cliente: qué campos ve y con qué formato.

🗣️ **2 minutos:** El adaptador lo construye a partir del resultado del caso de uso, seleccionando
los campos públicos y formateándolos según el contrato: importes como texto con dos decimales,
fechas en ISO 8601, estados con los nombres acordados. Es la lista explícita de lo que se publica.
Cualquier cosa que no esté en él, no sale.

🔬 **El detalle:** Evita exponer el objeto ORM o el modelo de dominio entero, con sus campos
internos, relaciones y datos que el cliente no debería ver.

### 4. 🟢 ¿Quién decide los campos públicos de un pedido?

⏱️ **30 segundos:** El contrato de la API, implementado por el adaptador de entrada.

🗣️ **2 minutos:** El caso de uso devuelve un resultado propio con lo que la aplicación sabe; el
adaptador selecciona y formatea los campos que el contrato publica. Así, añadir un campo interno al
dominio no lo publica, y publicar un campo nuevo es una decisión explícita en el response DTO y en
el contrato OpenAPI, revisable en un PR.

🔬 **El detalle:** Una revisión de API debe controlar los cambios visibles: cada campo publicado es
un compromiso con clientes que quizá nunca se podrá retirar sin romperlos.

### 5. 🟢 ¿Qué problema causa serializar una entidad JPA?

⏱️ **30 segundos:** Expone campos internos, dispara cargas lazy inesperadas y convierte el esquema
de la base en contrato público.

🗣️ **2 minutos:** La entidad persiste estado y su estructura cambia por necesidades de la base: una
columna nueva, una relación, un campo de auditoría. Si se serializa directamente, cada uno de esos
cambios aparece en la API sin que nadie lo decida. Además, el serializador recorre relaciones lazy,
lo que dispara consultas (a veces fuera de la sesión, con error) o ciclos infinitos.

🔬 **El detalle:** Un response DTO evita que ese cambio publique datos accidentalmente. El coste es
un mapper; el beneficio es que la base y la API evolucionan por separado.

### 6. 🟢 ¿Qué expresa un código de error estable?

⏱️ **30 segundos:** Una categoría pública de error que los clientes pueden interpretar
programáticamente, sin leer el texto.

🗣️ **2 minutos:** `INSUFFICIENT_INVENTORY`, `ORDER_NOT_CANCELLABLE`, `IDEMPOTENCY_KEY_REUSED`: el
cliente decide qué hacer según el código (mostrar un mensaje, reintentar, pedir otra acción). Debe
mantenerse estable aunque cambie la excepción interna, el mensaje o el idioma; cambiarlo es un
cambio incompatible del contrato. El status HTTP es demasiado grueso para esto: muchos errores
distintos comparten `409`.

🔬 **El detalle:** Puede acompañarse de un identificador de correlación que permita a soporte
encontrar la causa en los logs, sin revelar implementación en la respuesta.

### 7. 🟢 ¿Qué es Problem Details según RFC 9457?

⏱️ **30 segundos:** Un formato estándar para respuestas de error HTTP legibles por máquinas, con el
media type `application/problem+json`.

🗣️ **2 minutos:** Define miembros como `type` (URI que identifica el tipo de problema), `title`
(resumen legible), `status`, `detail` (explicación de esta ocurrencia) e `instance` (URI de esta
ocurrencia), y permite extensiones propias, como un `code` estable o una lista de errores de
validación por campo. Usarlo hace que todos los errores de la API tengan la misma forma y que los
clientes puedan tratarlos de forma genérica.

🔬 **El detalle:** No es un contenedor para stack traces: el propio RFC advierte contra filtrar
detalles de implementación en `detail`.

### 8. 🟡 ¿Cuándo compensa separar DTO y comando?

⏱️ **30 segundos:** Cuando los contratos evolucionan a ritmos distintos, cuando hay varias entradas
o cuando hay datos sensibles.

🗣️ **2 minutos:** Una API pública versionada, varios drivers (HTTP y cola) que construyen el mismo
comando, o un contrato que incluye campos que el negocio no usa (o al revés), justifican la
traducción. También la justifica que el comando necesite datos que no vienen del cuerpo, como el
actor o la clave de idempotencia. En esos casos, el mapper protege a cada lado de los cambios del
otro.

🔬 **El detalle:** Un CRUD interno estable puede empezar con menos clases y separar cuando aparezca
la primera diferencia. Lo importante es que la decisión sea consciente.

### 9. 🟡 ¿Cuándo un mapper manual es preferible a uno generado?

⏱️ **30 segundos:** Cuando hay pocas conversiones y tienen significado: defaults, unidades,
compatibilidad entre versiones.

🗣️ **2 minutos:** Un mapper escrito a mano hace visible cada decisión: qué pasa si un campo de la v1
no viene, cómo se convierte un importe de céntimos a decimal, qué estado externo equivale a cuál
interno. Esas decisiones se revisan en un PR y se prueban. Un mapper generado las esconde en
convenciones o anotaciones que hay que conocer para entender.

🔬 **El detalle:** Un generador (MapStruct, por ejemplo) sirve para asignaciones grandes y triviales,
donde escribir cien líneas de copia es peor que configurar una herramienta. Muchas veces conviene
combinarlos: generado para lo trivial, manual para lo semántico.

### 10. 🟡 ¿Qué no puede decidir un mapper generado?

⏱️ **30 segundos:** La compatibilidad, el sentido de los valores por defecto y qué pérdida de
información es aceptable.

🗣️ **2 minutos:** Puede copiar `customerId` a `customerId`, pero no decidir qué significa un campo
ausente en la v1 (¿valor por defecto?, ¿error?), si un redondeo al convertir moneda es aceptable, o
si un campo nuevo del modelo debe publicarse. Esas son decisiones de contrato y de negocio que deben
tomarse explícitamente. Un generador que copia "todo lo que coincide por nombre" puede publicar
campos sin que nadie lo decida.

🔬 **El detalle:** Esas reglas requieren pruebas de contrato: ejemplos de entrada y salida que fallen
si el comportamiento cambia, generado o no.

### 11. 🟡 ¿Cómo conviven dos versiones HTTP con un caso de uso?

⏱️ **30 segundos:** Con un request DTO y un mapper de entrada por versión, ambos hacia el mismo
comando.

🗣️ **2 minutos:** `/v1/orders` recibe `CreateOrderRequestV1` con `customer_id`; `/v2/orders` recibe
`CreateOrderRequestV2` con `customerId` y quizá campos nuevos con valor por defecto. Cada mapper
traduce al mismo `CreateOrderCommand`, y cada versión tiene su response DTO. El caso de uso no sabe
que hay dos versiones. Las pruebas de mapeo garantizan que la misma intención produce el mismo
comando.

🔬 **El detalle:** Versiono el núcleo solo por un cambio real de política. Si la v2 existe por una
nueva regla de negocio, el cambio está en el caso de uso y la v1 decide cómo adaptarse.

### 12. 🟡 ¿Qué diferencias puede ocultar una capa anticorrupción?

⏱️ **30 segundos:** Modelos, nombres, unidades, estados y reglas externas distintas de las propias.

🗣️ **2 minutos:** Un proveedor que llama "cliente" a lo que para nosotros es "cuenta", que expresa
importes en céntimos enteros, que tiene doce estados donde nosotros tenemos tres, o que devuelve
nulos donde nosotros tenemos valores explícitos. La capa anticorrupción traduce todo eso en el borde
para que esos conceptos no invadan el núcleo, y el día que cambien, cambie solo la traducción.

🔬 **El detalle:** Hay que documentar la conversión y los errores cuando no hay equivalencia exacta:
si un estado externo no encaja en ninguno propio, la decisión (tratarlo como incierto, rechazarlo)
debe ser explícita, no un `default` silencioso.

### 13. 🟡 ¿Por qué TypeScript `interface` no protege una respuesta en runtime?

⏱️ **30 segundos:** Porque la `interface` se borra al compilar: en ejecución no existe y no filtra
nada.

🗣️ **2 minutos:** Si el handler devuelve un objeto tipado como `OrderResponse` pero que en realidad
es la entidad de Prisma con más campos, el tipo lo acepta (TypeScript es estructural: un objeto con
más campos es compatible) y el serializador publica todos. La interfaz describe lo que esperas, no
lo que envías. Para controlar la salida hay que construir el objeto de respuesta explícitamente con
solo los campos permitidos.

🔬 **El detalle:** Uso proyección explícita (construir el objeto campo a campo, o un esquema de
salida que elimine lo desconocido) y pruebas que inspeccionen el JSON real.

### 14. 🟡 ¿Qué pruebas necesita un error público?

⏱️ **30 segundos:** Que tenga el status, el código y el esquema correctos, y que no contenga
secretos ni detalles internos.

🗣️ **2 minutos:** Una prueba por cada error propio del núcleo que la API expone: provoco la
condición, compruebo el status, el `content-type` de Problem Details, el `code` estable y que el
`detail` sea seguro. Otra para un fallo inesperado: `500` genérico, con correlación, sin stack
trace, SQL ni nombres de clase. Estas pruebas protegen el contrato de errores tanto como las de
éxito protegen el de datos.

🔬 **El detalle:** No devuelvo `exception.getMessage()` por defecto: los mensajes de excepciones
técnicas suelen contener consultas, rutas o datos que no deben salir.

### 15. 🟡 ¿Por qué `InsufficientInventory` no lleva status HTTP?

⏱️ **30 segundos:** Porque el status pertenece a HTTP, y el error pertenece al negocio, que se
invoca desde varias entradas.

🗣️ **2 minutos:** El dominio expresa "no hay stock suficiente"; HTTP lo representa como `409` con un
código; una cola lo representa como una respuesta de rechazo y un ACK; una CLI, como un mensaje y un
código de salida. Si el error llevara `409`, las otras entradas tendrían que ignorar o reinterpretar
un concepto que no es suyo, y cambiar la convención HTTP obligaría a tocar el dominio.

🔬 **El detalle:** La misma semántica puede tener representaciones distintas; la tabla de traducción
de cada adaptador es donde se decide cada una.

### 16. 🟡 ¿Qué riesgo tienen relaciones lazy al serializar ORM?

⏱️ **30 segundos:** Consultas imprevistas, errores fuera de sesión, ciclos y exposición de
relaciones que no deberían publicarse.

🗣️ **2 minutos:** El serializador recorre todos los getters; al tocar una colección lazy, dispara
una consulta (N+1 si es una lista), o falla si la transacción ya cerró. Si las relaciones son
bidireccionales, puede entrar en un ciclo infinito. Y aunque funcione, publica datos relacionados
que nadie decidió exponer: el cliente de un pedido, con su dirección y su historial.

🔬 **El detalle:** Proyectar los campos en un response DTO dentro de la transacción (o con una
consulta que traiga exactamente lo necesario) evita tanto el N+1 como la exposición accidental.

### 17. 🟠 Aparece un campo interno nuevo en `OrderEntity`. ¿Cómo evitas exponerlo?

⏱️ **30 segundos:** Con una proyección explícita de salida: el response DTO enumera los campos
publicados, y los nuevos no aparecen.

🗣️ **2 minutos:** Si la respuesta se construye desde un DTO que lista sus campos, un campo nuevo de
la entidad no sale nunca sin que alguien lo añada deliberadamente. Complemento con una prueba de
respuesta que verifique la lista exacta de campos permitidos: si alguien cambia la proyección y
aparece un campo no previsto, la prueba falla.

🔬 **El detalle:** No confío en `@JsonIgnore` repartidos por la entidad como única política pública:
es una lista de exclusión que hay que acordarse de mantener, y el campo que se olvida es el que se
filtra. Una lista de inclusión es más segura.

### 18. 🟠 V2 renombra `customer_id` a `customerId`. ¿Qué cambia en el núcleo?

⏱️ **30 segundos:** Nada. Solo cambia el mapper de la v2.

🗣️ **2 minutos:** `CreateOrderCommand` ya tiene `customerId` y la intención no cambió. La v2 tiene
su request DTO con el nombre nuevo y un mapper que lo pone en el mismo campo del comando; la v1
sigue funcionando con el suyo. El caso de uso, el dominio y sus pruebas no se tocan. Es exactamente
el tipo de cambio que la separación DTO/comando existe para absorber.

🔬 **El detalle:** Si además de renombrar cambiara el significado (por ejemplo, `customerId` pasa a
ser el id de la cuenta y no del usuario), eso sí es un cambio de contrato de aplicación que hay que
revisar.

### 19. 🟠 Un cliente depende de un campo que quieres eliminar. ¿Cómo evolucionas el contrato?

⏱️ **30 segundos:** Con una alternativa, un período de deprecación acordado y medición del uso antes
de eliminar.

🗣️ **2 minutos:** Primero añado la alternativa (el campo nuevo o el endpoint que lo sustituye) sin
quitar el viejo. Marco el viejo como deprecado en el contrato y lo comunico, con una fecha. Mido
quién sigue usándolo (logs, métricas por cliente). Cuando el uso cae a cero, o vence el plazo
acordado, lo elimino, idealmente en una versión nueva de la API para no romper a quien no migró.

🔬 **El detalle:** Las pruebas de contrato dirigidas por el consumidor ayudan a detectar roturas
antes de desplegar: si un cliente declara que usa ese campo, su prueba falla al eliminarlo.

### 20. 🟠 Un mapper copia `null` y rompe una invariante. ¿Dónde validas?

⏱️ **30 segundos:** Valido forma y defaults en el borde, y la invariante en el dominio. El mapper no
debe convertir silenciosamente un `null` en un valor inválido.

🗣️ **2 minutos:** El adaptador decide qué significa un campo ausente según el contrato: un valor por
defecto documentado, o un `400` si es obligatorio. El mapper no debe pasar `null` a un comando que
no lo admite; si no puede convertir, lanza un error tipado de conversión que se traduce a `400`. Y
el dominio, al construir el pedido, rechaza estados inválidos aunque alguien se salte el borde.

🔬 **El detalle:** El mapper informa de las conversiones imposibles con un error tipado, no las
resuelve inventando un valor. Un `null` convertido en cero o en cadena vacía es un bug esperando a
manifestarse.

### 21. 🟠 Un error técnico muestra una consulta SQL en `detail`. ¿Qué corriges?

⏱️ **30 segundos:** El traductor de errores y el contrato público de errores técnicos.

🗣️ **2 minutos:** El traductor está pasando el mensaje de la excepción al `detail`. Lo cambio para
que los errores técnicos produzcan siempre un Problem Details genérico ("error interno, inténtalo
más tarde") con un identificador de correlación, y la causa completa (consulta, parámetros saneados,
código del driver) vaya al log protegido con esa correlación. Añado una prueba que provoque un fallo
técnico y compruebe que el cuerpo no contiene SQL.

🔬 **El detalle:** El propio RFC 9457 advierte contra filtrar detalles de implementación; además, la
consulta revela nombres de tablas y columnas útiles para un ataque.

### 22. 🟠 El equipo propone un DTO gemelo por cada clase. ¿Qué criterio aplicas?

⏱️ **30 segundos:** Pido, por cada DTO, una diferencia concreta que proteja: evolución
independiente, datos sensibles o varios consumidores.

🗣️ **2 minutos:** Si el DTO es una copia idéntica de la clase y no hay razón para que evolucionen
por separado, simplifico: menos tipos, menos mappers, menos lugares donde olvidar un campo. Mantengo
los DTO donde protegen algo real: contratos públicos, versiones, datos que no deben salir. Y reviso
la decisión cuando aparece una evolución que la justifique.

🔬 **El detalle:** Mantengo la dirección de dependencias aunque reduzca clases: el núcleo no debe
llegar a depender del DTO del transporte por haber quitado la copia.

### 23. 🟠 FastAPI o Spring serializa más campos de los previstos. ¿Qué prueba escribes?

⏱️ **30 segundos:** Una prueba de integración que haga la petición real e inspeccione el JSON
devuelto.

🗣️ **2 minutos:** La prueba compara el conjunto de claves de la respuesta con la lista permitida y
falla si aparece cualquier otra, y comprueba explícitamente que no salen campos sensibles (hashes de
contraseña, notas internas, relaciones). Se ejecuta contra el adaptador HTTP con su serializador
real, configuración incluida, porque ahí es donde aparecen los campos inesperados.

🔬 **El detalle:** Un test unitario del mapper no detecta todos los comportamientos del serializador:
valores por defecto de Jackson, `response_model` mal configurado en FastAPI, o propiedades
calculadas que se serializan solas.

### 24. 🟠 HTTP y mensajería presentan distinto un mismo rechazo. ¿Es necesariamente un defecto?

⏱️ **30 segundos:** No. Cada transporte presenta el rechazo según su propio contrato.

🗣️ **2 minutos:** HTTP elige un status y un Problem Details; mensajería decide si confirma el
mensaje y responde con un rechazo, lo reintenta o lo envía a la DLQ. Que la representación sea
distinta es correcto: cada protocolo tiene sus convenciones y sus consumidores. Lo que debe
coincidir es la semántica: ambos deben tratarlo como el mismo rechazo de negocio, no uno como error
técnico y otro como éxito.

🔬 **El detalle:** Sí sería un defecto que contradijeran la semántica de negocio compartida: por
ejemplo, que HTTP rechace un pedido que la cola acepta, porque la regla está en uno de los
adaptadores y no en el núcleo.

---

## 06 · Simulación de entrevista

### S1. 🟢 ¿Qué responsabilidad comparten HTTP, un consumidor y una CLI?

⏱️ **30 segundos:** Traducir su entrada a una intención del núcleo y presentar el resultado en su
propio protocolo.

🗣️ **2 minutos:** Cada driver valida la forma y el contexto propio (JSON y token en HTTP; esquema,
productor y entrega en el consumidor; flags y credenciales del operador en la CLI), construye un
comando, llama al puerto de entrada y traduce el éxito o el error: status y Problem Details, ACK o
DLQ, texto y código de salida. Todos invocan el mismo caso de uso, así que la regla de negocio es
una.

🔬 **El detalle:** Ninguno debe reimplementar la regla de negocio. En cuanto un adaptador contiene un
`if` de negocio, la política empieza a divergir entre entradas.

### S2. 🟢 ¿Qué debe quedarse fuera del comando al entrar por HTTP?

⏱️ **30 segundos:** El request, los headers, el status, el serializador y cualquier tipo del
framework web.

🗣️ **2 minutos:** El adaptador extrae los datos confiables —el actor desde el token verificado, la
clave de idempotencia desde su header, las líneas desde el cuerpo validado— y construye un comando
propio con tipos del núcleo. El caso de uso no conoce la ruta, el método, la versión de la API ni el
formato del cuerpo. Eso permite que una cola o una prueba construyan el mismo comando sin simular
HTTP.

🔬 **El detalle:** La correlación y la identidad pueden cruzar normalizadas si la aplicación las
necesita: el actor como `Actor`, la correlación como metadato para observabilidad, nunca como
objetos del transporte.

### S3. 🟢 ¿Cuándo debe confirmarse un mensaje?

⏱️ **30 segundos:** Después de que el efecto local que representa quede confirmado en la base.

🗣️ **2 minutos:** Si se confirma antes y el proceso cae o la transacción se revierte, el broker no
reentrega y el trabajo se pierde. Si se confirma después y el proceso cae entre el commit y el ACK,
el broker reentregará el mensaje: habrá un duplicado. Se elige el segundo riesgo porque un duplicado
se detecta y se neutraliza, y una pérdida no.

🔬 **El detalle:** La repetición exige idempotencia durable: una identidad de operación registrada en
la misma transacción que el efecto, para que la reentrega devuelva el resultado anterior.

### S4. 🟢 ¿Qué diferencia hay entre autenticación y autorización?

⏱️ **30 segundos:** La autenticación establece quién es el actor; la autorización decide qué puede
hacer sobre qué recurso.

🗣️ **2 minutos:** El borde verifica credenciales (firma y vigencia del token, certificado del
servicio) y construye un actor confiable. La aplicación aplica los permisos que dependen del
recurso, como ser dueño del pedido o pertenecer a su tenant, y el dominio protege las invariantes de
estado que valen para cualquier actor. Una credencial válida es necesaria pero no suficiente.

🔬 **El detalle:** Un JWT no es una entidad de dominio ni debe cruzar al núcleo: el núcleo recibe un
`Actor` construido a partir de él.

### S5. 🟢 ¿Qué distingue un request DTO de un response DTO?

⏱️ **30 segundos:** Que representan contratos externos en direcciones distintas: uno lo que entra,
otro lo que sale.

🗣️ **2 minutos:** El request captura la forma de entrada, con sus opcionales y validaciones; el
response decide qué se expone del resultado y con qué formato. Ambos pueden versionarse sin cambiar
la intención de la aplicación. Tienen razones de cambio distintas: el request cambia cuando se
aceptan datos nuevos; el response, cuando se publica información nueva.

🔬 **El detalle:** Reutilizar el mismo tipo para ambos suele filtrar campos (lo que se acepta al
crear termina devolviéndose, o al revés) y acopla su evolución.

### S6. 🟢 ¿Qué hace un job antes de invocar el caso de uso?

⏱️ **30 segundos:** Selecciona el trabajo, interpreta sus parámetros y establece el contexto
operativo de la ejecución.

🗣️ **2 minutos:** El scheduler decide cuándo corre; el adaptador del job toma un lease si hay
réplicas, lee una página del origen desde el último checkpoint, construye un comando por elemento
con una identidad de operación estable y un actor de servicio, invoca el caso de uso, registra el
progreso y observa los resultados. La política —si un pedido se puede confirmar— sigue en el caso de
uso.

🔬 **El detalle:** Un cron no merece su propia lógica de pedido: si la tiene, divergirá de la de HTTP
en el primer cambio de regla.

### S7. 🟢 ¿Por qué un offset no debe usarse como identidad de negocio?

⏱️ **30 segundos:** Porque identifica una posición de entrega en una partición, no la intención
estable del productor.

🗣️ **2 minutos:** Una republicación, un reproceso, un cambio en el número de particiones o una
recreación del tópico pueden dar otro offset a la misma operación. Si el consumidor deduplica por
offset, esas repeticiones pasan como nuevas. La identidad de negocio debe venir del contenido del
mensaje: un identificador de operación que el productor mantiene en cada reintento.

🔬 **El detalle:** El adaptador conserva el offset para lo que sirve —confirmar el avance y
diagnosticar— y pasa al núcleo una clave de operación normalizada.

### S8. 🟡 ¿Dónde limitas el tamaño de una página solicitada por HTTP?

⏱️ **30 segundos:** En el borde, y también en el contrato de aplicación si lo que se protege son
recursos del sistema.

🗣️ **2 minutos:** El controller normaliza `limit`: aplica un valor por defecto, rechaza o recorta
los valores fuera del máximo documentado y traduce el parámetro a una petición de lectura propia. El
caso de uso puede imponer un máximo propio, independiente del query string, que protege la base
frente a cualquier entrada (una CLI o un job también pueden pedir listados).

🔬 **El detalle:** El dominio no necesita conocer la paginación HTTP: ni cursores codificados, ni
parámetros de URL, ni enlaces a la siguiente página.

### S9. 🟡 ¿Cómo clasificas un error de consumidor como transitorio o permanente?

⏱️ **30 segundos:** Preguntando si el mismo input puede tener éxito al repetirse sin que nada
cambie.

🗣️ **2 minutos:** Timeouts, indisponibilidad de la base o saturación del proveedor suelen ser
transitorios: se reintentan con espera y un límite. Un esquema inválido o un campo imposible son
permanentes: van a cuarentena. Un rechazo de negocio también es permanente, pero no es un fallo: se
registra, se responde si hay réplica y se confirma el mensaje. Cada clase tiene su tratamiento.

🔬 **El detalle:** Cada clase necesita límites, espera y ownership operativo: quién mira la
cuarentena y qué pasa cuando un transitorio agota sus reintentos.

### S10. 🟡 ¿Qué protege una clave de idempotencia en varias entradas?

⏱️ **30 segundos:** El efecto de una misma intención frente a las repeticiones de cualquier
transporte.

🗣️ **2 minutos:** Un cliente HTTP reintenta por timeout, un broker reentrega tras una caída, un
operador relanza una CLI: en todos los casos es la misma intención. HTTP, broker y CLI normalizan su
fuente de identidad a un `operationId` común en el comando, y el caso de uso la registra con el
resultado, en la misma transacción que el efecto. Cualquier repetición devuelve el resultado
anterior.

🔬 **El detalle:** La validación del formato de la clave sigue en cada adaptador, porque cada
transporte la trae en un sitio distinto y con reglas distintas.

### S11. 🟡 ¿Por qué un lock de job no sustituye idempotencia?

⏱️ **30 segundos:** Porque un lock puede expirar, perderse o coexistir durante una partición de red,
y porque no cubre la caída entre efecto y checkpoint.

🗣️ **2 minutos:** Un lease vence para que otro pueda continuar si el dueño cae; si el dueño solo
estaba lento, durante un momento dos workers creen tener el trabajo. Y aunque el lock sea perfecto,
un worker que cae después de confirmar un pedido y antes de guardar el checkpoint lo repetirá al
reanudar. El lease reduce el solapamiento; la clave de operación evita el daño cuando ocurre.

🔬 **El detalle:** La renovación y la observabilidad del lock también son responsabilidades
operativas: un lease que vence sistemáticamente antes de que el job termine es un bug de
configuración.

### S12. 🟡 ¿Dónde vive una regla como “solo el dueño puede cancelar un pedido”?

⏱️ **30 segundos:** En la aplicación, con un actor confiable y el pedido cargado; el dominio protege
el estado.

🗣️ **2 minutos:** El borde autentica y puede filtrar permisos gruesos (estar autenticado, tener rol
de cliente u operador). El caso de uso `CancelOrder` carga el pedido y evalúa la política
contextual: el actor es el dueño o un operador del mismo tenant. Después, `Order.cancel()` comprueba
que el estado lo permita. Cada comprobación está donde tiene los datos que necesita.

🔬 **El detalle:** Copiar la regla en cada ruta deja sin protección a los otros drivers: un job o un
consumidor que cancelen pedidos se la saltarían.

### S13. 🟡 ¿Cómo presentas el mismo rechazo en HTTP y mensajería?

⏱️ **30 segundos:** Con representaciones distintas de una misma semántica interna.

🗣️ **2 minutos:** Ambos parten del mismo error propio, por ejemplo `InsufficientInventory`. HTTP lo
traduce a `409` con Problem Details y un código estable; el consumidor lo registra, responde con un
rechazo por la cola de réplica si el contrato lo prevé y confirma el mensaje, porque reintentar no
cambiará el resultado. Cada adaptador tiene su tabla de traducción.

🔬 **El detalle:** Consistencia semántica no significa respuestas idénticas: significa que ningún
transporte trate como éxito lo que otro trata como rechazo.

### S14. 🟡 ¿Cuándo un mapper manual supera a uno generado?

⏱️ **30 segundos:** Cuando hay decisiones de seguridad, valores por defecto o semántica que deben
verse en el código.

🗣️ **2 minutos:** El generado ahorra repetición en copias estables de muchos campos triviales. El
manual hace explícitos los renombres, las pérdidas de precisión, los campos que no deben publicarse
y qué significa un campo ausente. Esas decisiones se revisan en un PR y se prueban; en un generado
quedan en convenciones o configuración que hay que conocer.

🔬 **El detalle:** Ambos requieren pruebas del contrato real serializado: el mapper es solo una
parte; el serializador del framework también decide qué sale.

### S15. 🟡 ¿Cómo reanudas un batch sin omitir ni duplicar daño?

⏱️ **30 segundos:** Con un cursor durable que avanza después del efecto e idempotencia por unidad.

🗣️ **2 minutos:** El checkpoint solo se guarda cuando la unidad está confirmada, así que nunca se
omite trabajo. Una caída antes del checkpoint repite la última unidad al reanudar; como esa unidad
lleva una identidad de operación estable, el caso de uso devuelve el resultado ya confirmado sin
repetir el efecto. Si checkpoint y efecto pueden ir en la misma transacción, la ventana desaparece.

🔬 **El detalle:** El cursor debe tener un orden estable (una clave, no un offset mutable) y una
semántica clara ante datos nuevos que aparezcan durante la ejecución.

### S16. 🟡 ¿Qué observabilidad pertenece al adaptador de entrada?

⏱️ **30 segundos:** Latencia, resultado, reintentos y correlación del transporte o de la ejecución.

🗣️ **2 minutos:** El adaptador HTTP registra ruta, status y latencia; el consumidor, tópico,
partición, intentos y lag; el job, duración, procesados, fallidos y edad del checkpoint. Todos
propagan la correlación. El caso de uso puede emitir métricas de negocio (pedidos creados, rechazos
por tipo) sin conocer headers, tópicos ni rutas; el borde añade los atributos técnicos, saneados.

🔬 **El detalle:** No se incluyen secretos ni payloads completos en logs: bastan identificadores,
clasificación y correlación.

### S17. 🟠 Un controller y un consumer validan la misma invariante de forma distinta. ¿Qué extraes?

⏱️ **30 segundos:** La invariante al dominio o a la aplicación; en cada borde queda solo la
validación de forma.

🗣️ **2 minutos:** Si HTTP rechaza pedidos de más de diez unidades y el consumidor los acepta, hay
dos políticas. Llevo la regla al lugar que la posee —la entidad si es una invariante del pedido, el
caso de uso si depende de contexto— y hago que ambos adaptadores llamen a esa misma política. Las
pruebas del caso de uso cubren la regla una vez; las de cada adaptador cubren su traducción.

🔬 **El detalle:** No comparto automáticamente los DTO de protocolos distintos para "unificar": la
unificación está en el comando y la regla, no en el formato de entrada.

### S18. 🟠 Un job nocturno procesa todo en una transacción de diez horas. ¿Qué cambias?

⏱️ **30 segundos:** Parto el trabajo por unidad de consistencia y guardo el progreso de forma
durable.

🗣️ **2 minutos:** Confirmo por pedido o por lote pequeño, con transacciones de segundos; guardo un
checkpoint tras cada unidad para poder reanudar; limito la concurrencia para no saturar la base; y
hago cada efecto idempotente por identidad de operación. Un fallo afecta solo a su unidad y no
revierte nueve horas de trabajo; los bloqueos duran segundos y el resto del sistema sigue
funcionando.

🔬 **El detalle:** La atomicidad total de la transacción larga era ilusoria: no incluye proveedores
externos, y en cambio amplía bloqueos, memoria y alcance del rollback.

### S19. 🟠 El actor llega en un header que el cliente puede falsificar. ¿Qué falla?

⏱️ **30 segundos:** La frontera de confianza: la identidad no fue autenticada, solo declarada.

🗣️ **2 minutos:** Cualquier cliente puede poner `X-User-Id: 42` y actuar como el usuario 42. El
adaptador debe obtener el actor de credenciales verificadas (token firmado, certificado) o, si viene
de un proxy, verificar que la petición llegó por el canal confiable, y descartar los headers de
identidad que no cumplan. El caso de uso recibe un actor propio construido a partir de esa
verificación.

🔬 **El detalle:** La auditoría puede registrar el origen de la petición, pero sin convertir un
header en autoridad. Es de las vulnerabilidades más comunes en arquitecturas con gateway.

### S20. 🟠 Una respuesta serializa una relación nueva del ORM sin querer. ¿Qué prevención aplicas?

⏱️ **30 segundos:** Un response DTO explícito y una prueba de integración sobre el JSON real.

🗣️ **2 minutos:** El DTO actúa como lista de inclusión: solo salen los campos que enumera, así que
una relación nueva en la entidad no aparece. La prueba de integración hace la petición real y
compara las claves del JSON con la lista permitida, fallando si aparece cualquier otra. Así se
cubren los defaults del serializador, el lazy loading y los cambios del modelo persistente.

🔬 **El detalle:** Un test unitario del mapper no cubre toda la configuración del serializador:
módulos de Jackson, `response_model` de FastAPI o propiedades calculadas pueden publicar campos que
el mapper nunca tocó.

### S21. 🟡 ¿Puede un adapter llamar dos casos de uso para una sola petición?

⏱️ **30 segundos:** Puede, pero reviso si con eso está creando una transacción o una política
propia.

🗣️ **2 minutos:** Si la intención exige atomicidad o una decisión conjunta —crear el pedido y
reservar, o ambos o ninguno—, necesito un caso de uso que orqueste ambas cosas dentro de una
transacción; si el adaptador llama a dos, la atomicidad se pierde y el adaptador pasa a tener
política. Si son consultas independientes para componer una pantalla, el borde puede componer la
presentación sin problema.

🔬 **El detalle:** El protocolo no debe poseer una regla accidental. La pregunta es qué pasa si la
segunda llamada falla: si la respuesta es "hay que deshacer la primera", el adaptador está haciendo
trabajo de aplicación.

### S22. 🟡 ¿Debe la DLQ reprocesarse automáticamente?

⏱️ **30 segundos:** No por defecto: depende de la causa, de si se corrigió y de si es seguro
repetir.

🗣️ **2 minutos:** Reprocesar automáticamente un mensaje que falló por un bug no corregido lo
devolverá a la DLQ; uno que falló por un dato malo del productor, también. Defino ownership,
retención, diagnóstico de la causa y una operación de reingreso controlada, auditada y, si procede,
en lotes pequeños. Un reprocesado automático solo tiene sentido para causas transitorias ya
resueltas y con consumidores idempotentes.

🔬 **El detalle:** Una DLQ sin proceso operativo solo desplaza el fallo de lugar: las operaciones
siguen sin hacerse, ahora sin que nadie mire.

### S23. 🟠 ¿Un `dry-run` que hace rollback local es seguro?

⏱️ **30 segundos:** No si ejecuta efectos externos o consume recursos irreversibles antes del
rollback.

🗣️ **2 minutos:** Un rollback de la base no deshace una autorización de pago, un correo enviado, un
mensaje publicado ni una llamada a un sistema que no participa de la transacción. El modo `dry-run`
debe evaluar sin mutar —aplicando las reglas y devolviendo lo que haría— o declarar exactamente qué
sí cambia. Si la evaluación completa exige efectos, el `dry-run` debe decirlo en lugar de simularlo.

🔬 **El detalle:** Si no puede prometerse un `dry-run` sin efectos, retiro el modo: una falsa
sensación de seguridad es peor que no tenerlo.

### S24. 🟠 ¿Dónde colocas rate limiting?

⏱️ **30 segundos:** En el borde para proteger el sistema; las cuotas de negocio, si existen, en la
aplicación.

🗣️ **2 minutos:** El gateway o el adaptador controlan el tráfico técnico: peticiones por segundo por
IP o por cliente, para proteger capacidad. Si además hay una regla comercial —"el plan básico
permite 100 pedidos al día"—, esa es política de negocio: vive en el caso de uso y debe cumplirse
desde cualquier driver, incluida una importación masiva por cola.

🔬 **El detalle:** No confundo capacidad operativa con una regla comercial: la primera se ajusta
según la infraestructura; la segunda, según el contrato con el cliente, y cambian por razones
distintas.

### S25. 🟠 ¿Cuándo compartirías un comando entre HTTP y mensajería?

⏱️ **30 segundos:** Cuando representa la misma intención con la misma semántica, no solo campos
parecidos.

🗣️ **2 minutos:** Si ambos crean pedidos con las mismas reglas, cada adaptador conserva su DTO o
esquema y traduce al comando común, y el caso de uso es uno. Si difieren las garantías (el mensaje
exige idempotencia estricta, HTTP la hace opcional), el actor (servicio frente a usuario) o las
reglas (pedidos importados con precios ya fijados), quizá sean casos de uso distintos que comparten
dominio.

🔬 **El detalle:** Compartir un comando por ahorro de código puede ocultar contratos incompatibles y
llenar el caso de uso de ramas por origen.

### S26. 🟠 El consumidor usa topic, partición y offset para decidir descuentos. ¿Cómo lo corriges?

⏱️ **30 segundos:** Extraigo la regla a un caso de uso que decida con datos de negocio explícitos.

🗣️ **2 minutos:** Si el descuento depende del canal de origen, el adaptador traduce el tópico a un
dato de negocio (`channel = marketplace`) y lo pone en el comando; el caso de uso aplica la regla
con ese dato. Tópico, partición y offset quedan para lo que sirven: enrutar, confirmar y
diagnosticar. Así la regla se puede probar, invocar desde otra entrada y cambiar sin tocar el
consumidor.

🔬 **El detalle:** Antes de mover nada, caracterizo el comportamiento actual con pruebas, porque
puede haber decisiones válidas escondidas en esa lógica que nadie documentó.

### S27. 🟠 La misma operación entra por HTTP, CLI y un scheduler. ¿Qué compartes?

⏱️ **30 segundos:** El puerto de entrada, el comando, la autorización aplicable y la idempotencia.

🗣️ **2 minutos:** Los tres construyen el mismo comando con un actor (usuario, operador, servicio) y
una identidad de operación, y llaman al mismo caso de uso, que aplica la política y la deduplicación
una vez. Cada driver mantiene lo suyo: parseo de su entrada, obtención de credenciales, presentación
del resultado y observabilidad. El caso de uso coordina la intención una sola vez.

🔬 **El detalle:** No fuerzo el mismo contrato de errores en los tres transportes: cada uno presenta
el mismo error de la forma que su consumidor entiende.

### S28. 🟠 Un JWT contiene `role=admin`, pero el usuario perdió acceso al pedido. ¿Qué verificas?

⏱️ **30 segundos:** El permiso actual dependiente del recurso, no solo el claim del token.

🗣️ **2 minutos:** El borde valida el token, que sigue siendo válido hasta que expire o se revoque.
La aplicación consulta la relación vigente entre el actor y el pedido (tenant, asignación) en la
fuente actual, y decide con eso; el dominio protege las transiciones. Decido explícitamente cuánta
tolerancia acepto a claims desactualizados: tokens cortos, revocación por `jti` o consulta fresca
para acciones sensibles.

🔬 **El detalle:** La seguridad gruesa en el borde no reemplaza la autorización contextual: un rol en
un token es una foto del momento en que se emitió.

### S29. 🟠 Un batch cae después del efecto y antes del checkpoint. ¿Cómo reanuda?

⏱️ **30 segundos:** Repite la unidad con la misma identidad de operación y obtiene el resultado
previo, sin repetir el efecto.

🗣️ **2 minutos:** El checkpoint solo avanza tras la confirmación, así que al reanudar se relee la
última unidad. El caso de uso encuentra su identidad registrada —la deduplicación comparte
transacción con el efecto— y devuelve el resultado anterior. El job avanza el checkpoint y sigue. La
ejecución queda observable: el reintento aparece en métricas como "ya aplicado", no como procesado
nuevo.

🔬 **El detalle:** Un lock puede reducir la carrera entre réplicas, pero no elimina esta ventana: es
una caída del propio proceso, no una concurrencia.

### S30. 🟠 Dos versiones HTTP necesitan campos de respuesta incompatibles. ¿Cambias el dominio?

⏱️ **30 segundos:** No si la política no cambió: creo mapeos de presentación por versión.

🗣️ **2 minutos:** Ambas versiones consumen el mismo resultado interno, estable, y cada una tiene su
response DTO y su mapper: la v1 publica `total` como número y `customer_id`; la v2, `total` como
objeto con moneda y `customerId`. Conviven durante la migración de clientes y la v1 se retira cuando
deja de usarse. El dominio y el caso de uso no se enteran.

🔬 **El detalle:** Cambio el núcleo solo cuando cambió la intención o la información que debe
producir: si la v2 necesita un dato que el resultado interno no tiene, se añade al resultado, no a
la entidad por la puerta de atrás.

---

**Siguiente:** [índice del bloque](README.md) · [Adaptadores de salida y operación →](../04-adaptadores-de-salida-y-operacion/README.md)
