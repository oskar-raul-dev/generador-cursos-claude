# 09 — Respuestas: Comunicación

> Solucionario del bloque `02-comunicacion`. Cada respuesta va en tres capas:
> **⏱️ 30 segundos** lo que dices primero, **🗣️ 2 minutos** lo que añades cuando dicen "cuéntame
> más", y **🔬 El detalle** lo que estudias pero no dices en voz alta. El enunciado está copiado
> literalmente del capítulo: si no cuadra, manda el capítulo y este archivo está desactualizado.
>
> **Vigencia:** 2026-09-29.

**Salto rápido:** [01](#01--estilos-de-comunicación) · [02](#02--http-entre-servicios) · [03](#03--grpc) · [04](#04--http-contra-grpc) · [05](#05--tiempo-real-websockets-sse-y-los-demás) · [06](#06--mensajería-y-eventos) · [07](#07--contratos-y-versionado) · [08](#08--simulación-de-entrevista)

---

# 01 — Estilos de comunicación

**01 → 1. ¿Cuáles son los dos ejes que clasifican una integración? 🟢**

⏱️ **30 segundos** — Si el que llama espera respuesta —síncrono o asíncrono— y cuántos receptores hay
—uno-a-uno o uno-a-muchos—.

🗣️ **2 minutos** — Con esos dos ejes se sitúa cualquier tecnología: HTTP y gRPC unario en síncrono
uno-a-uno; colas en asíncrono uno-a-uno; topics en asíncrono uno-a-muchos. Lo útil de la matriz es
que la decisión se toma sobre los ejes y solo después se elige el protocolo.

🔬 **El detalle** — La casilla de síncrono uno-a-muchos está vacía en la práctica: esperar a N
receptores multiplica latencia y fallo por N. Lo que la gente llama así son varios request-response
en paralelo.

**01 → 2. Define acoplamiento temporal. 🟢**

⏱️ **30 segundos** — Que un servicio necesita que el otro esté disponible en ese instante para
completar su trabajo.

🗣️ **2 minutos** — Es la propiedad que decide cómo se comporta el sistema el día malo: con
acoplamiento temporal, la lentitud del otro se convierte en tu lentitud y su caída en la tuya. Sin
él, el trabajo se hace cuando el otro vuelva, a cambio de que la confirmación al usuario ya no sea
inmediata.

🔬 **El detalle** — No se elimina, se traslada: con una cola pasas a depender del broker. Es un
cambio de dependiente —de un servicio de negocio que despliegas cada semana a una infraestructura
diseñada para estar disponible—, y decirlo con ese matiz es lo que distingue la respuesta.

**01 → 3. ¿Qué diferencia hay entre un comando y un evento? 🟢**

⏱️ **30 segundos** — El comando dice "haz esto" y tiene destinatario conocido; el evento dice "esto
ha pasado" y el emisor no sabe quién escucha.

🗣️ **2 minutos** — La diferencia se nota en el acoplamiento: el que manda un comando conoce al
receptor y espera un efecto concreto, así que sigue acoplado a su existencia. El que publica un
evento solo afirma un hecho, y añadir un consumidor nuevo no le obliga a cambiar nada.

🔬 **El detalle** — El nombre delata la intención: los eventos van en pasado —`OrderPlaced`— y
los comandos en imperativo —`ReserveInventory`—. Publicar un comando en un topic es acoplarse igual que
con una llamada, pero con menos garantías y peor diagnóstico.

**01 → 4. ¿Cómo se nombran los eventos y por qué? 🟢**

⏱️ **30 segundos** — En pasado, porque describen un hecho que ya ocurrió y que no se puede rechazar.

🗣️ **2 minutos** — `OrderPlaced` es un hecho; `PlaceOrder` es una orden. La diferencia no
es estilística: si el nombre es imperativo, el emisor está decidiendo por el receptor y ha creado un
acoplamiento que el modelo de eventos pretendía evitar.

🔬 **El detalle** — El nombre también fija la evolución: un hecho no cambia, así que el evento es
inmutable y los consumidores futuros pueden interpretarlo como quieran. Una orden, en cambio, se
queda obsoleta cuando cambia el proceso.

**01 → 5. ¿Qué casilla de la matriz de §2 está vacía y por qué? 🟢**

⏱️ **30 segundos** — La de síncrono uno-a-muchos: nadie espera a N receptores.

🗣️ **2 minutos** — Esperar a varios multiplica la probabilidad de fallo y la latencia la marca el
más lento; además obligaría a saber cuántos receptores hay, que es justo lo que el modelo
uno-a-muchos evita. Cuando parece que existe, son varias llamadas uno-a-uno lanzadas en paralelo.

🔬 **El detalle** — Hay un caso que se le parece y no lo es: la difusión con confirmación por quórum
en sistemas de consenso. Ahí sí se espera a varios, pero es infraestructura, no integración entre
servicios de negocio.

**01 → 6. Enumera el precio de request-response, comando por cola y publicación-suscripción. 🟢**

⏱️ **30 segundos** — Acoplamiento temporal y fallo propagado; respuesta diferida e idempotencia
obligatoria; consistencia eventual y nadie con el estado global.

🗣️ **2 minutos** — Request-response se paga en disponibilidad compuesta y latencia acumulada, y se
cobra en simplicidad de lectura y error inmediato. La cola compra que el receptor pueda estar caído y
cuesta gestionar orden, reintentos y duplicados. El topic compra poder añadir consumidores sin tocar
al emisor y cuesta que ningún sitio conozca el estado completo del flujo.

🔬 **El detalle** — El coste menos evidente del topic es el diagnóstico: cuando algo no pasa, no hay
una llamada fallida que mirar, hay un consumidor que no reaccionó. Por eso la observabilidad de los
flujos asíncronos exige más trabajo del que se presupuesta.

**01 → 7. ¿En qué sentido un evento sigue siendo un contrato? 🟢**

⏱️ **30 segundos** — Su esquema es un contrato con todos los consumidores, presentes y futuros, y
romperlo los rompe a todos a la vez y en silencio.

🗣️ **2 minutos** — Los eventos desacoplan en el tiempo, no en el formato. Quitar un campo o cambiar
su significado rompe consumidores que ni siquiera conoces, y el fallo aparece tarde y lejos del
despliegue que lo causó. Por eso el esquema del evento se versiona y se verifica igual que una API,
como se ve en [`07`](07-contratos-y-versionado.md).

🔬 **El detalle** — Hay una diferencia importante con HTTP: los eventos suelen quedar almacenados, así
que los consumidores nuevos leerán mensajes viejos. La compatibilidad tiene que ser hacia atrás **y**
hacia adelante, y eso condiciona el formato que elijas.

**01 → 8. ¿Por qué pasar a una cola no elimina el acoplamiento temporal? 🟡**

⏱️ **30 segundos** — Porque sigues necesitando algo vivo para publicar: el broker.

🗣️ **2 minutos** — El cambio es de dependiente, y es un buen cambio: el broker está diseñado para
alta disponibilidad y no cambia cada semana, mientras que el servicio de negocio despliega a menudo y
tiene lógica que puede fallar. Pero si el broker se cae, `orders` tampoco puede completar su
trabajo, salvo que tenga outbox y escriba en su propia base.

🔬 **El detalle** — Ahí está la conexión con `03/04`: el outbox convierte la publicación en una
escritura local, y entonces sí desaparece la dependencia con el broker en el camino de la petición.
Esa es la versión completa de la respuesta.

**01 → 9. Diferencia entre asíncrono de integración y no bloqueante. Da un ejemplo de cada combinación. 🟡**

⏱️ **30 segundos** — Uno es si espero la respuesta del otro servicio; el otro es si el hilo se queda
parado mientras espera.

🗣️ **2 minutos** — Las cuatro combinaciones existen: llamada HTTP con cliente bloqueante —síncrono y
bloqueante—; llamada HTTP con cliente reactivo —síncrono y no bloqueante—; consumidor de cola escrito
con código bloqueante —asíncrono y bloqueante—; y consumidor reactivo —asíncrono y no bloqueante—. La
primera decisión es de arquitectura, la segunda de uso de recursos.

🔬 **El detalle** — La confusión es cara porque lleva a creer que "pasar a reactivo" desacopla
servicios. No desacopla nada: si el otro se cae, tu llamada falla igual, solo que sin ocupar un hilo
mientras tanto.

**01 → 10. "Asíncrono es más rápido": ¿qué parte es falsa y qué querían decir? 🟡**

⏱️ **30 segundos** — De extremo a extremo es más lento. Lo que mejora es la latencia percibida por el
usuario y la capacidad de absorber picos.

🗣️ **2 minutos** — El trabajo total tarda más: hay un salto extra por el broker, y el consumidor
procesa cuando puede. Lo que sí ocurre es que el que llama responde de inmediato porque ya no espera,
y que un pico de tráfico se convierte en una cola que crece en vez de en un sistema caído.

🔬 **El detalle** — El coste oculto es la latencia de cola bajo carga: si el consumidor no escala,
el retraso crece indefinidamente y el usuario ve su pedido "en proceso" durante minutos. Por eso el
lag del consumidor es una métrica de producto y no solo de infraestructura.

**01 → 11. ¿Por qué publicar `ReserveInventory` en un topic es un error de diseño? 🟡**

⏱️ **30 segundos** — Porque es un comando: sabes quién debe reaccionar y qué debe hacer. Un topic no
lo desacopla, solo esconde el acoplamiento.

🗣️ **2 minutos** — Un comando espera un efecto concreto de un destinatario concreto, así que si nadie
consume, el flujo se rompe en silencio. Además, si mañana se suscribe otro consumidor, ejecutará la
reserva dos veces. Los comandos van a una cola con destinatario, donde la ausencia de consumidor es
visible como acumulación.

🔬 **El detalle** — La prueba para distinguirlos en el diseño: si el emisor tiene que cambiar cuando
cambia el receptor, es comando. Si el emisor puede seguir igual aunque se añadan o quiten
consumidores, es evento.

**01 → 12. ¿Por qué una operación de CPU en el hilo principal de Node afecta a peticiones que no tienen nada que ver? 🟡**

⏱️ **30 segundos** — Porque hay un solo hilo ejecutando el bucle de eventos: mientras esa operación
corre, nada más avanza.

🗣️ **2 minutos** — El modelo de Node no bloquea en entrada y salida, pero sí bloquea en cómputo: un
bucle que ordena un millón de elementos o que serializa un objeto enorme detiene el proceso entero,
incluidas las respuestas ya listas. Las salidas son sacar ese trabajo a `worker_threads`, a otro
servicio, o partirlo para ceder el control.

🔬 **El detalle** — El equivalente en Python con `asyncio` es idéntico: una llamada bloqueante dentro
de un manejador asíncrono congela el bucle. En Java con hilos y en Go con goroutines el problema es
distinto —agotamiento de pool— pero no detiene lo que ya está en curso.

**01 → 13. Te preguntan "¿usarías programación reactiva?". Estructura la respuesta. 🟡**

⏱️ **30 segundos** — Primero distingo asíncrono de integración de no bloqueante; luego digo que
depende del perfil de carga y de la plataforma.

🗣️ **2 minutos** — La respuesta ordenada: reactivo resuelve concurrencia alta con pocos hilos en
servicios que sobre todo esperan a otros. Cuesta legibilidad, diagnóstico más difícil y un modelo que
todo el equipo tiene que dominar. En plataformas con hilos ligeros modernos, buena parte de la
ventaja se obtiene sin cambiar el estilo de programación, y eso cambia la recomendación respecto a
hace unos años.

🔬 **El detalle** — La trampa a nombrar: mezclar reactivo con una llamada bloqueante en medio anula
el beneficio y añade toda la complejidad. Si no se puede garantizar que toda la cadena sea no
bloqueante, conviene no empezar.

**01 → 14. ¿Qué le pides al broker antes de apoyar tu diseño en él? Nombra tres propiedades. 🟡**

⏱️ **30 segundos** — Persistencia con replicación, garantía de entrega al-menos-una-vez, y orden
dentro de la unidad de particionado.

🗣️ **2 minutos** — A eso se suman las propiedades operativas: qué pasa cuando un consumidor se queda
atrás, si hay DLQ nativa o hay que construirla, y cómo se observa el retraso. Y una que se olvida:
cuánto tiempo retiene los mensajes, porque de ahí depende si puedes reprocesar tras un incidente.

🔬 **El detalle** — La pregunta de control es qué ocurre durante un fallo del propio broker: si
pierde mensajes no confirmados, tu outbox tiene que ser el que garantice, y entonces el diseño del
productor cambia.

**01 → 15. ¿Qué cambia entre las cuatro plataformas al hablar de "asíncrono", y qué NO cambia? 🟡**

⏱️ **30 segundos** — Cambia el modelo de ejecución —hilos y virtuales en Java, bucle de eventos en
Node, goroutines en Go, `asyncio` o procesos en Python—, pero **no** cambia el estilo de integración.

🗣️ **2 minutos** — Que tu código no bloquee un hilo no desacopla nada en el tiempo: si llamas a otro
servicio y esperas su respuesta, sigues necesitándolo vivo. Lo que cambia entre plataformas es el
coste de esperar: en Node y Go una espera cuesta casi nada; en Java, con hilos virtuales, tampoco; en
Python depende de si el manejador es asíncrono o del modelo por procesos.

🔬 **El detalle** — De ahí el error clásico: "pasamos a reactivo para desacoplar". Reactivo cambia
cómo esperas, no de quién dependes. Para dejar de depender del otro en el instante hace falta cambiar
el estilo de integración, no el modelo de ejecución.

---
**01 → 16. `orders` necesita saber si hay stock antes de confirmar. ¿Síncrono o asíncrono? Justifica. 🟠**

⏱️ **30 segundos** — Síncrono: el usuario está esperando esa respuesta y no hay forma razonable de
diferirla.

🗣️ **2 minutos** — Hacerlo asíncrono obligaría a inventar un mecanismo de espera —sondeo, empuje al
cliente— sobre algo que el usuario percibe como una sola acción. Lo que sí conviene es separar la
**consulta** de disponibilidad, que puede servirse de una proyección eventual y rápida, de la
**reserva** real, que se hace al confirmar y decide la verdad.

🔬 **El detalle** — Ese doble nivel es el diseño habitual del comercio electrónico: la ficha muestra
disponibilidad aproximada y el momento de confirmar es transaccional. Si el stock cambió, el usuario
se entera al confirmar, que es cuando importa.

**01 → 17. El cobro se satura en los picos de venta. ¿Qué cambio de estilo propones y qué empeora? 🟠**

⏱️ **30 segundos** — Poner una cola delante del cobro: el pico se convierte en fila en vez de en
caída. Empeora que la confirmación deja de ser inmediata.

🗣️ **2 minutos** — Con cola, `orders` acepta el pedido y encola el cobro; el consumidor procesa al
ritmo que aguante. Lo que cambia para el usuario es que su pedido queda "en proceso" y la
confirmación llega por correo o por empuje. Hay que diseñar qué se le muestra mientras tanto y qué
pasa si el cobro falla después de haber aceptado.

🔬 **El detalle** — Es una decisión de producto tanto como técnica: en algunos negocios "pendiente de
cobro" es inaceptable y hay que escalar el cobro en vez de encolarlo. La respuesta completa nombra
esa conversación en vez de darla por hecha.

**01 → 18. Integras con un proveedor externo que se cae a menudo. ¿Cómo evitas que su disponibilidad sea la tuya? 🟠**

⏱️ **30 segundos** — Sacándolo de la ruta síncrona: encolar la petición, reintentar con backoff, y
responder al usuario con lo que ya sabes.

🗣️ **2 minutos** — El patrón completo tiene tres piezas: cola con reintentos y DLQ, timeout y
circuit breaker para no gastar recursos mientras está caído, y una decisión explícita de qué se le
dice al usuario mientras no hay respuesta. Si la respuesta del tercero es imprescindible en el
momento, no hay solución técnica: hay que negociar el requisito.

🔬 **El detalle** — Conviene medir su disponibilidad real y hacerla visible: un tablero con el
porcentaje mensual del tercero convierte una queja en un dato, y suele ser lo que desbloquea la
conversación contractual con él.

**01 → 19. ¿Cuándo convertirías una llamada síncrona existente en un evento, y qué tienes que añadir al hacerlo? 🟠**

⏱️ **30 segundos** — Cuando el que llama no necesita la respuesta. Y hay que añadir idempotencia,
manejo de duplicados y observabilidad del flujo.

🗣️ **2 minutos** — La lista de lo que aparece al cambiar: el consumidor debe tolerar reentregas; hace
falta DLQ y una política de qué se hace con lo que cae ahí; hay que poder responder "¿se procesó mi
pedido?" sin una llamada que devuelva error; y el contrato del evento necesita versionado. Si esas
piezas no se van a construir, la conversión empeora el sistema.

🔬 **El detalle** — Y falta una pieza que casi siempre se olvida: publicar el evento y guardar en la
base son dos escrituras que pueden desincronizarse. Sin outbox, el cambio introduce una ventana donde
el pedido existe y nadie se enteró.

**01 → 20. Un dato decorativo de la pantalla viene de un servicio lento. Da tres soluciones ordenadas por esfuerzo. 🟠**

⏱️ **30 segundos** — Timeout corto con valor por defecto; cargarlo aparte después de pintar; o
mantener una copia local actualizada por eventos.

🗣️ **2 minutos** — La primera cuesta una línea y convierte una caída en un hueco. La segunda mejora
la percepción: la pantalla aparece y el bloque llega después, sin bloquear nada. La tercera elimina
la dependencia en la ruta, y cuesta un consumidor y un almacén que mantener.

🔬 **El detalle** — El orden importa porque el 80 % del beneficio está en la primera, que además es
reversible. Empezar por la tercera —la más "arquitectónica"— es el error clásico: añade estado y
consistencia eventual para un dato que era decorativo.

**01 → 21. ¿Cómo explicarías a negocio que una confirmación pasa a ser eventual? 🟠**

⏱️ **30 segundos** — En términos de lo que ve el cliente y de cuánto tarda, no en términos técnicos:
"queda registrado al instante y se confirma en segundos; si algo falla, avisamos".

🗣️ **2 minutos** — Conviene llevar tres datos: el tiempo típico y el peor caso medido, qué se le
muestra al usuario mientras tanto, y qué pasa si finalmente falla. Y contrastarlo con la alternativa:
hoy, en un pico, el sistema devuelve errores y se pierde la venta. El cambio convierte un error en
una espera.

🔬 **El detalle** — Ayuda nombrar ejemplos que el negocio ya acepta: una transferencia bancaria que
aparece "en proceso", o un pedido que se confirma por correo. La consistencia eventual no es nueva
para ellos, solo para el equipo técnico.

**01 → 22. Toma el flujo de confirmación de pedido —reservar, cobrar, notificar— y asigna un estilo de comunicación a cada paso, justificando cada elección y diciendo qué pasa si falla. 🟠**

⏱️ **30 segundos** — Reservar, síncrono; cobrar, síncrono o encolado según el negocio; notificar,
evento. Y compensación si el cobro falla tras reservar.

🗣️ **2 minutos** — El diseño:

```text
Paso       Estilo                Por qué                          Si falla
─────────  ────────────────────  ───────────────────────────────  ─────────────────────────
reservar   síncrono (1:1)        el usuario espera saber si hay   respuesta inmediata: no hay stock
cobrar     síncrono, o cola      depende de si "pendiente" vale   compensar: liberar la reserva
notificar  evento (1:N)          nadie espera, y habrá más        reintento del consumidor; no afecta al pedido
```

Y la conclusión que conviene decir: el flujo es una saga en cuanto el cobro puede fallar después de
la reserva, y eso obliga a diseñar la compensación desde el principio, no después.

🔬 **El detalle** — El paso de notificación es el que mejor ilustra el valor del evento: mañana
marketing quiere reaccionar a la misma confirmación y no hay que tocar `orders`. Ese es el beneficio
concreto de publicar hechos, y es más convincente que hablar de desacoplamiento en abstracto.

**01 → 23. Diseña la integración entre `orders` y un sistema legado que solo acepta ficheros por lotes cada hora, sin que el usuario perciba que es por lotes. 🔴**

⏱️ **30 segundos** — Un adaptador que acumula los eventos, genera el fichero por hora y reconcilia
las respuestas, con el estado visible en `orders`.

🗣️ **2 minutos** — El diseño:

```text
orders ──evento──► adaptador ──acumula──► fichero por hora ──► legado
                        ▲                                         │
                        └────── fichero de respuestas ◄───────────┘
                                    ↓
                        evento de resultado por pedido
```

El adaptador es dueño del estado de cada envío —pendiente, enviado, confirmado, rechazado— y publica
un evento por cada resultado. El usuario ve "en proceso" con una expectativa de tiempo, y la
reconciliación del fichero de respuestas es obligatoria: sin ella, lo rechazado se pierde en
silencio.

🔬 **El detalle** — Las dos preguntas que vienen después: qué pasa con un pedido que llega justo
después del corte horario —se acumula para el siguiente, y el usuario debe verlo— y qué pasa si el
legado responde con un rechazo parcial del fichero. Esa segunda es la que obliga a tener
identificador propio por línea y conciliación por registro, no por fichero.

**01 → 24. Un equipo propone pasar todas las llamadas del sistema a eventos "para desacoplar". Da tu respuesta en dos minutos, con lo que concedes y lo que rechazas. 🔴**

⏱️ **30 segundos** — Concedo que para los efectos está bien; rechazo para las consultas que el
usuario espera, donde añade complejidad sin comprar nada.

🗣️ **2 minutos** — El argumento: los eventos desacoplan en el tiempo, no en el contrato, y traen su
propio equipaje —idempotencia, DLQ, orden, observabilidad del flujo, versionado de esquema—. Para un
"¿hay stock?" que el usuario está esperando, ese equipaje se paga y no se cobra nada, porque el
usuario sigue esperando. La propuesta razonable es convertir **los efectos** —notificar, actualizar
proyecciones, integrar con terceros— y dejar síncronas las consultas.

🔬 **El detalle** — Conviene cerrar con el coste organizativo, que suele ser el argumento decisivo:
un sistema todo-eventos exige que cualquiera que diagnostique un incidente sepa leer flujos
asíncronos, y eso es formación y herramientas, no solo diseño.

**01 → 25. Dibuja la misma operación en los cuatro estilos de §1 y di, para cada una, qué ve el usuario cuando `inventory` tarda ocho segundos. 🔴**

⏱️ **30 segundos** — En los dos síncronos, el usuario espera y acaba viendo un error; en los dos
asíncronos, ve una confirmación inmediata y el efecto llega tarde.

🗣️ **2 minutos** — El cuadro:

```text
Estilo              Qué pasa con 8 s de lentitud      Qué ve el usuario
──────────────────  ────────────────────────────────  ──────────────────────────
HTTP síncrono       hilo ocupado 8 s o timeout        espera, y luego error
gRPC unario         igual, pero el deadline corta     error más rápido y más claro
comando por cola    orders responde ya; el consumo    "en proceso", y confirmación después
                    se retrasa mientras crece el lag
evento en topic     orders ni se entera               confirmado, aunque la reserva llegue tarde
```

Y el matiz que cierra la respuesta: en las dos últimas filas el problema no desaparece, se hace
invisible — lo que obliga a vigilar el retraso del consumidor como métrica de producto, porque es lo
único que delata que algo va mal.

🔬 **El detalle** — En la fila de gRPC hay una ventaja concreta que conviene nombrar: el deadline
viaja con la llamada, así que `inventory` sabe cuánto tiempo le queda y puede abandonar trabajo que
ya no sirve. Con HTTP eso hay que construirlo a mano.

---

# 02 — HTTP entre servicios

**02 → 1. Nombra tres diferencias entre una API interna y una pública. 🟢**

⏱️ **30 segundos** — Los consumidores son conocidos, el versionado se negocia y se retira, y la
granularidad se ajusta a los casos de uso reales.

🗣️ **2 minutos** — En una pública diseñas para lo hipotético y mantienes versiones durante años; en
una interna sabes quién te llama, puedes acordar una migración y puedes exponer el endpoint por lote
que ese consumidor necesita. Además el contrato se verifica en CI en vez de vivir en la
documentación.

🔬 **El detalle** — El riesgo de la API interna es acabar con la unión de todos los casos de uso. Se
acota midiendo el uso real y retirando lo que nadie llama, que es algo que en una API pública no
puedes hacer.

**02 → 2. ¿Qué cinco parámetros del cliente HTTP son decisiones de arquitectura? 🟢**

⏱️ **30 segundos** — Timeout de conexión, timeout de lectura, pool de conexiones, límite de
concurrencia por destino y política de reintentos.

🗣️ **2 minutos** — Los dos primeros deciden cuánto te puede retener un servicio lento; el pool decide
si pagas el saludo TLS en cada llamada; el límite de concurrencia evita que una dependencia
consuma toda tu capacidad; y los reintentos deciden si ayudas o empeoras cuando el otro está mal.

🔬 **El detalle** — El límite de concurrencia por destino es el menos usado y el que más se parece a
un bulkhead barato: sin cambiar de librería, evitas que una sola dependencia ocupe todas tus
conexiones salientes.

**02 → 3. ¿Qué códigos de estado invitan a reintentar y cuáles no? 🟢**

⏱️ **30 segundos** — Reintentar con 408, 429, 503 y 504; no reintentar con 400, 404 y 422; y con 409
solo si cambias algo.

🗣️ **2 minutos** — Los primeros indican una condición transitoria o una petición de espera —y con 429
o 503 hay que respetar `Retry-After` si viene—. Los segundos son deterministas: el resultado será el
mismo. El 500 es ambiguo: como mucho un reintento, y solo si la operación es idempotente.

🔬 **El detalle** — Lo que decide de verdad no es el código sino si la operación es idempotente: un
504 en una escritura no idempotente puede significar que se ejecutó y se perdió la respuesta.
Reintentar ahí es una apuesta.

**02 → 4. ¿Qué es el `N+1` distribuido? 🟢**

⏱️ **30 segundos** — Pedir una lista y luego hacer una llamada por cada elemento.

🗣️ **2 minutos** — Con quince elementos y 40 ms por llamada, la pantalla pasa de 40 ms a más de 600, y
la probabilidad de que alguna falle crece con cada una. Las dos salidas son una consulta por lote o
una copia local del dato mantenida por eventos.

🔬 **El detalle** — No aparece en pruebas porque allí la lista tiene tres elementos y el servicio está
al lado. La señal para detectarlo en revisión de código es literal: un bucle con una llamada de red
dentro.

**02 → 5. ¿Por qué el contrato de error necesita un código estable además del código HTTP? 🟢**

⏱️ **30 segundos** — Porque el que llama tiene que decidir —reintentar, rendirse o degradar— y no
puede hacerlo leyendo un texto.

🗣️ **2 minutos** — El código HTTP da la categoría; el código de dominio da el caso concreto:
`INSUFFICIENT_STOCK` no es lo mismo que `PRODUCT_NOT_FOUND`, aunque ambos puedan viajar como 409 o
404. Con códigos estables el consumidor puede programar su comportamiento sin acoplarse al idioma ni
al formato del mensaje.

🔬 **El detalle** — La forma del error debe ser idéntica en todos tus servicios, y eso es trabajo del
chassis. Si cada servicio inventa su formato, el consumidor acaba con un parser por dependencia.

**02 → 6. ¿Qué pasa si no configuras timeout de lectura en un cliente que no lo trae por defecto? 🟡**

⏱️ **30 segundos** — Que la llamada espera indefinidamente y el hilo o la conexión quedan retenidos
hasta que el sistema operativo corte.

🗣️ **2 minutos** — Ese es el mecanismo del agotamiento de recursos: si la dependencia tarda, tus
hilos se van ocupando y llega un punto en que dejas de atender **todo**, incluidas las rutas que no
la usan. Por eso el timeout es la primera medida de resiliencia, antes que el circuit breaker.

🔬 **El detalle** — Es peor que un error: un error se ve y se cuenta; una espera indefinida aparece
como lentitud sin causa aparente y suele costar la primera hora del incidente.

**02 → 7. ¿Qué diferencia hay entre timeout de conexión y de lectura, y cuál falla primero cuando cae la red? 🟡**

⏱️ **30 segundos** — El de conexión mide establecer la conexión; el de lectura, esperar la respuesta.
Con la red caída falla el de conexión.

🗣️ **2 minutos** — El de conexión suele ser corto —cientos de milisegundos— porque conectar es rápido
o no es. El de lectura es más largo y depende del trabajo que haga el otro. Distinguirlos permite
diagnosticar: fallo de conexión apunta a red, DNS o instancia caída; fallo de lectura apunta a
servicio lento.

🔬 **El detalle** — Hay un caso que engaña: con una caída silenciosa de red, la conexión ya
establecida no da error y se queda esperando hasta el timeout de lectura o hasta que el sistema
operativo detecte que el otro extremo no responde. Ahí el `keep-alive` de TCP y los plazos de la
aplicación son lo único que te salva.

**02 → 8. ¿Por qué el `keep-alive` importa especialmente en HTTPS? 🟡**

⏱️ **30 segundos** — Porque sin él cada llamada repite el saludo TLS, que cuesta varios viajes de ida
y vuelta antes de enviar un solo byte útil.

🗣️ **2 minutos** — En llamadas entre servicios, donde el trabajo real puede ser de pocos
milisegundos, ese coste domina la latencia. Reutilizar conexiones es de los arreglos con mejor
relación entre esfuerzo y efecto, y suele estar mal configurado por tamaño de pool insuficiente o por
cerrar el cliente en cada uso.

🔬 **El detalle** — La señal para detectarlo es el número de conexiones nuevas por segundo contra el
número de peticiones. Si se parecen, no estás reutilizando nada, aunque el cliente diga que soporta
`keep-alive`.

**02 → 9. ¿En qué se diferencia reintentar una lectura de reintentar una escritura? 🟡**

⏱️ **30 segundos** — La lectura es idempotente por naturaleza; la escritura puede haberse ejecutado
aunque no te llegara la respuesta.

🗣️ **2 minutos** — Reintentar un `GET` solo cuesta tráfico. Reintentar un `POST` sin garantías puede
duplicar el efecto: dos cobros, dos reservas. Para poder reintentar escrituras hace falta una clave
de idempotencia que el servidor registre, de modo que la segunda vez devuelva el resultado de la
primera en vez de ejecutar otra vez.

🔬 **El detalle** — El caso más traicionero es el timeout: no sabes si el otro no recibió la petición
o si la ejecutó y la respuesta se perdió. Sin clave de idempotencia, ese caso no tiene solución
correcta, solo elecciones entre duplicar o perder.

**02 → 10. ¿Por qué un endpoint por lote necesita un límite declarado en el contrato? 🟡**

⏱️ **30 segundos** — Porque sin límite alguien pedirá diez mil elementos y convertirá tu servicio en
su problema.

🗣️ **2 minutos** — El límite protege memoria, tiempo de respuesta y la base de datos de detrás.
Declararlo en el contrato hace que el consumidor lo tenga en cuenta al escribir su cliente, en vez de
descubrirlo cuando su llamada empiece a fallar en producción con un pedido grande.

🔬 **El detalle** — Conviene devolver un error claro al superarlo —no truncar en silencio— y dar el
límite en el propio mensaje. Truncar produce datos incompletos que el consumidor no detecta, que es
peor que fallar.

**02 → 11. ¿Qué gana Go al llevar el plazo en el `context` en lugar de en el cliente? 🟡**

⏱️ **30 segundos** — Que el plazo se propaga y se compone: cada llamada hija hereda lo que queda del
padre.

🗣️ **2 minutos** — Eso convierte el presupuesto de latencia en algo automático: si el que llama tenía
500 ms y tú pides 800, tu plazo efectivo son los 500 que quedan. Además la cancelación viaja, así que
cuando el cliente se rinde, el trabajo aguas abajo puede abandonarse en vez de seguir consumiendo
recursos.

🔬 **El detalle** — El precio es la disciplina: hay que pasar el `context` por toda la cadena de
llamadas, y olvidarlo en un punto rompe la propagación en silencio. Es el equivalente en Go de
perder la traza al cruzar a un pool de hilos.

**02 → 12. ¿Por qué el timeout se elige desde lo que tú puedes esperar y no desde lo que tarda el otro? 🟠**

⏱️ **30 segundos** — Porque el timeout protege tus recursos, no la comodidad del otro.

🗣️ **2 minutos** — Si el destino tiene un p99 de dos segundos y tu endpoint promete responder en uno,
poner tres segundos no arregla nada: rompe tu promesa y te deja los hilos ocupados. La conversación
correcta es al revés: o el otro mejora, o tú degradas, o esa llamada sale de la ruta síncrona.

🔬 **El detalle** — El p99 del destino sí entra en la decisión, pero como dato para negociar, no como
valor a copiar. Y hay que recordar que tu timeout debe ser menor que el de quien te llama, o el
trabajo que hagas después de su corte se tira.

**02 → 13. Tu endpoint promete responder en 1 s y llama a dos servicios. ¿Cómo repartes los plazos? 🟠**

⏱️ **30 segundos** — Reservo tiempo propio, reparto el resto entre las dos, y si son independientes
las lanzo en paralelo para que mande la más lenta y no la suma.

🗣️ **2 minutos** — Un reparto razonable: 100 ms de trabajo propio, y 800 ms para las llamadas. Si son
secuenciales, 400 y 350 con margen; si son paralelas, 700 cada una y el presupuesto lo marca la más
lenta. Y siempre menos que el segundo completo, para tener margen de responder algo aunque sea un
error controlado.

🔬 **El detalle** — Si una de las dos es opcional, su plazo debe ser mucho menor y su fallo debe
degradar en vez de propagar. Distinguir dependencias imprescindibles de opcionales es la decisión que
más reduce incidentes y casi nunca está escrita en ningún sitio.

**02 → 14. `orders` hace quince llamadas a `catalog` por pantalla. Da dos soluciones y elige. 🟠**

⏱️ **30 segundos** — Endpoint por lote o copia local por eventos. Empiezo por el lote.

🗣️ **2 minutos** — El lote se implementa en una tarde, no añade estado y resuelve el problema hoy: una
llamada con quince identificadores y un límite declarado. La copia local elimina la llamada, sirve
para datos que cambian poco y se consultan mucho —el catálogo lo es—, y cuesta un consumidor, un
almacén y consistencia eventual. Empiezo por el lote y paso a copia si la latencia o el volumen lo
justifican con números.

🔬 **El detalle** — Hay un dato que conviene copiar siempre, incluso con lote: el precio y la
descripción **en el momento de la compra**, porque el negocio quiere la foto y no el enlace. Eso no es
caché, es dominio.

**02 → 15. Un consumidor reintenta tres veces sin backoff y el servicio destino está degradado. Explica qué pasa y corrige. 🟠**

⏱️ **30 segundos** — La carga se multiplica por cuatro justo cuando el destino está peor, y lo que era
lentitud se convierte en caída.

🗣️ **2 minutos** — Sin espera entre intentos, los reintentos llegan inmediatamente y todos los
clientes reintentan a la vez, sincronizados por el propio fallo. La corrección tiene tres piezas:
espera exponencial, jitter para desincronizar, y presupuesto —un porcentaje máximo de reintentos
sobre el tráfico—, además de un circuit breaker que deje de intentarlo cuando está claro que no
responde.

🔬 **El detalle** — Y una corrección de segundo orden: no reintentar en varias capas a la vez. Si
reintentan el cliente, la librería y el mesh, tres intentos se convierten en veintisiete, que es un
caso real y sorprendentemente común.

**02 → 16. ¿Cómo harías idempotente un `POST /payments` para poder reintentarlo con seguridad? 🟠**

⏱️ **30 segundos** — Con una clave de idempotencia que envía el cliente y que el servidor registra
junto con el resultado.

🗣️ **2 minutos** — El cliente genera la clave una vez por intención de cobro —no por intento— y la
manda en todos los reintentos. El servidor guarda clave, resultado y estado en la misma transacción
que el cobro; si llega otra vez, devuelve el resultado guardado sin ejecutar nada. Hay que decidir la
retención de esas claves y qué hacer si llega la misma clave con cuerpo distinto, que debe ser un
error.

🔬 **El detalle** — El caso borde importante es la petición en curso: si llega el reintento mientras
la primera todavía se procesa, lo correcto es responder que está en progreso, no ejecutar en
paralelo. Eso exige registrar la clave **antes** de empezar, no al terminar.

**02 → 17. Diseña el cuerpo de error común de tus servicios: qué campos lleva y por qué cada uno. 🟠**

⏱️ **30 segundos** — Código estable, mensaje para humanos, identificador de correlación, y detalles
por campo cuando es de validación.

🗣️ **2 minutos** — El código permite decidir sin parsear texto; el mensaje ayuda a quien depura; el
identificador de correlación permite encontrar la traza completa —y es lo que conviertes en el
"código de incidencia" que le das al usuario—; y los detalles por campo evitan que el consumidor
tenga que adivinar qué parte de la petición estaba mal. Todo con la misma forma en todos los
servicios.

🔬 **El detalle** — Lo que **no** debe llevar: trazas de pila, nombres de tablas ni mensajes de la
base de datos. Además de ser una fuga de información, acopla al consumidor a detalles internos que
cambiarán.

**02 → 18. El p99 de una dependencia se dobla tras un despliegue suyo. ¿Qué pasa en tu servicio y qué mecanismos lo contienen? 🟠**

⏱️ **30 segundos** — Tus hilos se ocupan más tiempo y tu propio p99 sube; lo contienen el timeout, el
límite de concurrencia por destino y el circuit breaker.

🗣️ **2 minutos** — El efecto depende de tu configuración: con timeout ajustado, empiezas a fallar
rápido esas llamadas y el resto del servicio sigue; sin él, la cola de peticiones crece hasta agotar
recursos. El límite de concurrencia evita que esa dependencia ocupe toda tu capacidad saliente, y el
circuit breaker corta cuando la tasa de fallo o lentitud supera el umbral.

🔬 **El detalle** — Conviene tener una alerta sobre la latencia **de tus dependencias vista desde ti**,
no solo sobre la tuya. Es la señal que distingue "somos nosotros" de "es el de al lado" en los
primeros cinco minutos de un incidente.

**02 → 19. ¿Cuándo sacarías una llamada HTTP de la ruta síncrona, y a dónde la moverías? 🟠**

⏱️ **30 segundos** — Cuando su resultado no hace falta para responder: se mueve a una cola o a un
evento, con outbox para no perderlo.

🗣️ **2 minutos** — Los casos típicos son notificar, integrar con un tercero lento, y actualizar datos
derivados. Al moverla hay que añadir idempotencia en el consumidor, DLQ, y una forma de que el
usuario consulte el estado si le importa. Si el resultado sí hace falta para responder, no se mueve:
se optimiza, se degrada o se precalcula.

🔬 **El detalle** — Existe un punto intermedio útil: responder 202 con un recurso de estado
consultable. Mantiene HTTP, quita la espera y le da al cliente una forma explícita de saber cómo va,
sin montar mensajería.

**02 → 20. ¿Qué encabezados propagas en toda llamada saliente y qué pasa si se pierde cada uno? 🟠**

⏱️ **30 segundos** — El contexto de traza, el identificador de correlación, la identidad y, cuando
aplica, la clave de idempotencia.

🗣️ **2 minutos** — Si se pierde la traza, el diagnóstico se corta justo donde cruza el servicio y
tienes dos trazas inconexas. Si se pierde la correlación, no puedes unir los logs. Si se pierde la
identidad, el servicio de destino no puede autorizar y acabas con llamadas "de sistema" que nadie
puede auditar. Si se pierde la clave de idempotencia, el reintento duplica.

🔬 **El detalle** — El punto donde más se pierden es al publicar en un broker: el contexto va en los
encabezados del mensaje y hay que inyectarlo y extraerlo a mano si la librería no lo hace. Es el
agujero más común de las trazas distribuidas.

**02 → 21. ¿Qué traen por defecto los clientes HTTP de las cuatro plataformas en cuanto a plazos? 🟠**

⏱️ **30 segundos** — Que en varias de ellas el valor por defecto es **esperar indefinidamente**: el
cliente clásico de Python y el `http.Client` desnudo de Go no traen plazo, y en Java depende de la
combinación.

🗣️ **2 minutos** — En Java hay que fijar el plazo por petición, no solo el de conexión. En Node, el
motor cubre fases concretas y falta un plazo total propio, que se pone con una señal de cancelación.
En Go el plazo va en el `context` de cada llamada y se propaga. En Python hay que pasarlo
explícitamente en cada llamada del cliente. Ninguna de las cuatro te protege por omisión.

🔬 **El detalle** — Por eso el chassis debería **obligar a declarar el plazo por dependencia** y fallar
al arrancar si falta: convierte un olvido silencioso —que se manifiesta como agotamiento de recursos
bajo carga— en un despliegue fallido, que es infinitamente más barato.

---
**02 → 22. Diseña el contrato de la API que `catalog` expone a `orders`: endpoints, tamaño de lote, errores, y qué se versiona. 🔴**

⏱️ **30 segundos** — Consulta individual, consulta por lote con límite, y un contrato de error con
códigos estables; se versiona el esquema, no la URL, mientras los cambios sean compatibles.

🗣️ **2 minutos** — El contrato:

```text
GET  /products/{id}                     → 200 producto | 404 PRODUCT_NOT_FOUND
POST /products/queries                  → 200 lista; cuerpo con hasta 100 ids
                                          413 BATCH_TOO_LARGE si se excede
Errores  {code, message, correlationId, details[]}
Versionado  aditivo: campos nuevos opcionales; nada se elimina sin aviso y
            sin comprobar el uso real; si hay ruptura, /v2 y convivencia temporal
Contrato   OpenAPI publicado por catalog; cliente generado; verificado en CI
```

🔬 **El detalle** — La decisión discutible es usar `POST` para una consulta por lote. Se justifica
porque la lista de identificadores no cabe razonablemente en la URL; a cambio se pierde la caché de
HTTP, y por eso conviene dejar el `GET` individual para lo que sí se cachea.

**02 → 23. Diagnostica: p99 de `orders` sube a 4 s, `catalog` responde en 60 ms, y el número de conexiones nuevas por segundo se ha multiplicado por diez. Da tres hipótesis ordenadas. 🔴**

⏱️ **30 segundos** — Pérdida de reutilización de conexiones; pool agotado que encola; o un `N+1` que
multiplicó las llamadas.

🗣️ **2 minutos** — En orden de probabilidad, dado el dato de conexiones:

```text
1. keep-alive roto     cliente recreado por petición, o pool demasiado pequeño
                       → cada llamada paga conexión + TLS; encaja con x10 conexiones
2. Pool saturado       las llamadas esperan turno; el destino responde rápido pero
                       tú tardas. Se ve en la métrica de espera en pool, no en la del destino
3. N+1 nuevo           un cambio convirtió una llamada en quince; explica conexiones
                       y latencia, pero debería verse en el número total de peticiones a catalog
```

Se distinguen mirando dos números: peticiones por segundo contra `catalog` —si no subieron, no es
`N+1`— y tiempo de espera en el pool.

🔬 **El detalle** — La causa 1 aparece a menudo tras un refactor que crea el cliente dentro del método
en vez de reutilizarlo. Es un cambio de una línea, pasa desapercibido en revisión y su efecto solo se
ve con carga real.

**02 → 24. Escribe la configuración de cliente HTTP que le darías al chassis del equipo, con los valores que dependen de cada dependencia y los que no. 🔴**

⏱️ **30 segundos** — Comunes: reutilización de conexiones, propagación de encabezados, métricas y
formato de error. Por dependencia: plazos, concurrencia y política de reintentos.

🗣️ **2 minutos** — El reparto:

```text
Del chassis (igual para todos)      Por dependencia (se configura al usarlo)
──────────────────────────────────  ───────────────────────────────────────────
keep-alive y tamaño de pool base    timeout de conexión y de lectura
propagación de traza e identidad    límite de concurrencia
métricas por destino y por código   reintentos: cuántos y para qué códigos
parseo del error común              circuit breaker: umbrales
sin reintento por defecto           si la operación es idempotente o no
```

La decisión de diseño importante es que **el chassis no reintenta por defecto**: activar reintentos
es una decisión por dependencia, porque depende de la idempotencia de la operación, que el chassis no
puede saber.

🔬 **El detalle** — Conviene que el chassis obligue a declarar los plazos —fallar al arrancar si
faltan— en vez de poner un valor por defecto. Un valor por defecto razonable se convierte en el valor
de todos, y deja de revisarse.

**02 → 25. Un servicio tuyo es llamado por otros cuatro equipos y uno de ellos te satura con reintentos. Da tu respuesta técnica y la conversación que tienes con ellos. 🔴**

⏱️ **30 segundos** — Técnicamente, límite de tasa por consumidor y respuestas 429 con `Retry-After`.
En la conversación, datos: cuánto tráfico suyo son reintentos.

🗣️ **2 minutos** — El plan:

```text
Inmediato    identificar al consumidor (encabezado de cliente o credencial)
             límite de tasa por consumidor, 429 con Retry-After
Corto plazo  panel por consumidor: peticiones, reintentos, errores
             alerta cuando el porcentaje de reintentos supere un umbral
Conversación enseñar el dato: "el 60 % de tu tráfico son reintentos sin backoff";
             acordar backoff con jitter y presupuesto; revisar si los 500 que
             provocan los reintentos son culpa nuestra
```

Lo importante es no empezar por el límite sin avisar: cortar sin conversación convierte un problema
técnico en uno entre equipos.

🔬 **El detalle** — Conviene revisar antes si los errores que disparan sus reintentos son tuyos. Si tu
servicio devuelve 500 intermitentes, el reintento es la reacción razonable y el problema de fondo es
otro: en ese caso el límite de tasa esconde tu propio fallo.

---

# 03 — gRPC

**03 → 1. ¿Sobre qué protocolo de transporte va gRPC y qué formato usa para los mensajes? 🟢**

⏱️ **30 segundos** — Sobre HTTP/2, con mensajes en Protocol Buffers, que es un formato binario
definido por un esquema.

🗣️ **2 minutos** — HTTP/2 aporta multiplexación —varias llamadas en una conexión— y flujos en ambos
sentidos, que es lo que hace posible el streaming. Protobuf aporta el contrato compilado: del `.proto`
salen los tipos, el servidor y el cliente en cada lenguaje.

🔬 **El detalle** — Que sea binario y posicional implica que sin el esquema los bytes no significan
nada: esa es a la vez la ventaja —compacto, barato de parsear— y la objeción de depuración, que tiene
respuesta con herramientas propias y con reflexión.

**03 → 2. ¿Qué representa el número de un campo en un `.proto`? 🟢**

⏱️ **30 segundos** — Es la identidad del campo en el cable: lo que viaja es el número, no el nombre.

🗣️ **2 minutos** — De ahí salen las dos reglas de evolución: puedes renombrar un campo sin romper
nada, porque el nombre solo existe en el código; y no puedes reutilizar un número, porque un
consumidor viejo leería el dato nuevo creyendo que es el viejo, sin error visible.

🔬 **El detalle** — Cuando se elimina un campo, su número se marca como reservado para que el
compilador impida reutilizarlo. Es una de esas protecciones que parecen burocracia hasta el día que
alguien recicla el número tres.

**03 → 3. Enumera los cuatro modos de gRPC con un caso de uso para cada uno. 🟢**

⏱️ **30 segundos** — Unario para llamadas normales; streaming de servidor para resultados largos; de
cliente para ingesta; bidireccional para sincronización continua.

🗣️ **2 minutos** — El unario cubre el 90 % de las llamadas entre servicios. El de servidor sirve para
exportaciones o seguimiento de un proceso. El de cliente, para telemetría o carga por lotes. El
bidireccional, para protocolos conversacionales, y es el que más se parece a un WebSocket.

🔬 **El detalle** — Los tres con streaming comparten los problemas de las conexiones largas: qué pasa
en un despliegue, cómo se reanuda, y cómo se detecta que el otro extremo murió. Por eso conviene
empezar en unario y justificar el cambio por volumen o duración.

**03 → 4. ¿Qué es un deadline y en qué se diferencia de un timeout local? 🟢**

⏱️ **30 segundos** — Es un plazo que viaja con la llamada y que cada salto hereda; el timeout local
solo lo conoce quien lo puso.

🗣️ **2 minutos** — Con deadline, `inventory` sabe cuánto tiempo le queda y puede abandonar si no le
da tiempo; y si llama a un tercero, le pasa lo que resta. Con timeouts locales, cada salto pone el
suyo sin conocer el presupuesto total, y el trabajo continúa aunque el de arriba ya se haya rendido.

🔬 **El detalle** — Sin deadline explícito, el comportamiento por defecto es esperar indefinidamente.
Es el mismo fallo del cliente HTTP sin timeout, con la diferencia de que aquí el protocolo traía la
solución incorporada.

**03 → 5. Nombra cuatro códigos de estado de gRPC y qué debe hacer el cliente con cada uno. 🟢**

⏱️ **30 segundos** — `UNAVAILABLE`, reintentar con espera; `DEADLINE_EXCEEDED`, solo si es idempotente
y queda margen; `INVALID_ARGUMENT`, nunca; `RESOURCE_EXHAUSTED`, reintentar más tarde.

🗣️ **2 minutos** — El conjunto es pequeño y está pensado para decidir, no para describir. `NOT_FOUND`
y `ALREADY_EXISTS` son deterministas; `PERMISSION_DENIED` y `UNAUTHENTICATED` piden renovar
credenciales o rendirse; `INTERNAL` es ambiguo y merece como mucho un reintento.

🔬 **El detalle** — `UNAVAILABLE` es el que las políticas estándar de reintento tratan como
transitorio. Devolver `INTERNAL` para algo que sí era transitorio le quita al cliente la información
con la que decide, y es un error de diseño del servidor, no del cliente.

**03 → 6. ¿Para qué sirve la metadata? 🟢**

⏱️ **30 segundos** — Es el equivalente de los encabezados HTTP: lleva identidad, contexto de traza,
clave de idempotencia y cualquier dato transversal.

🗣️ **2 minutos** — Va separada del mensaje, así que no contamina el contrato de negocio con campos
técnicos. Se lee y se escribe en los interceptores, que son el sitio natural para autenticación,
métricas y trazas — el chassis aplicado a gRPC.

🔬 **El detalle** — Hay metadata inicial y final; la final es útil para devolver información que solo
se conoce al terminar, como el coste de la operación. Es una de esas capacidades que casi nadie usa y
que resuelve bien algunos casos de facturación interna.

**03 → 7. ¿Por qué se pueden renombrar campos pero no reutilizar sus números? 🟡**

⏱️ **30 segundos** — Porque en el cable viaja el número: el nombre solo existe en el código generado.

🗣️ **2 minutos** — Renombrar cambia el código de ambos lados pero no el formato, así que la
compatibilidad binaria se mantiene. Reutilizar un número hace que un consumidor viejo interprete el
dato nuevo como si fuera el antiguo: no hay error, hay corrupción silenciosa, que es el peor tipo de
fallo.

🔬 **El detalle** — El mismo razonamiento explica por qué cambiar el tipo de un campo es peligroso
aunque el número se mantenga: algunos cambios de tipo son compatibles en el cable y otros no, y la
guía oficial enumera exactamente cuáles. No se improvisa.

**03 → 8. ¿Por qué el balanceo de nivel de transporte no reparte el tráfico gRPC? 🟡**

⏱️ **30 segundos** — Porque reparte conexiones, y gRPC multiplexa todas sus llamadas en una sola
conexión persistente.

🗣️ **2 minutos** — El cliente abre una conexión, el balanceador la asigna a una instancia, y a partir
de ahí todas las llamadas van ahí. Con pocas instancias y clientes de larga vida, el reparto queda
desequilibrado y no se nota hasta que hay carga. Las salidas son balanceo en el cliente, un proxy que
entienda HTTP/2, o un mesh.

🔬 **El detalle** — El síntoma en producción es claro y desconcierta: una instancia al 90 % de CPU y
las otras dos casi ociosas, con el balanceador informando de reparto correcto —porque para él lo es:
repartió conexiones—.

**03 → 9. ¿Qué diferencia práctica hay entre `UNAVAILABLE` e `INTERNAL` para quien llama? 🟡**

⏱️ **30 segundos** — `UNAVAILABLE` significa "vuelve a intentarlo"; `INTERNAL` significa "algo se
rompió y no sé si reintentar ayuda".

🗣️ **2 minutos** — Las políticas de reintento estándar tratan el primero como transitorio y no el
segundo. Por eso el servidor debe mapear con cuidado: una dependencia caída, una conexión rechazada o
un apagado en curso son `UNAVAILABLE`; un fallo de lógica o un dato corrupto son `INTERNAL`.

🔬 **El detalle** — Un caso frecuente y mal resuelto: durante el apagado ordenado, el servidor debería
devolver `UNAVAILABLE` para que el cliente reintente contra otra instancia. Si devuelve `INTERNAL`, el
cliente se rinde y el despliegue produce errores visibles.

**03 → 10. ¿Qué tiene que hacer el servidor para que el deadline ahorre recursos de verdad? 🟡**

⏱️ **30 segundos** — Comprobar la cancelación antes y durante el trabajo caro, y abandonar si el plazo
expiró.

🗣️ **2 minutos** — Si no lo comprueba, el deadline solo evita que el cliente espere: el servidor sigue
consultando la base de datos y llamando a terceros para producir una respuesta que nadie leerá. En un
incidente, ese trabajo inútil es precisamente lo que impide que el sistema se recupere.

🔬 **El detalle** — Los puntos donde conviene comprobar son antes de empezar, antes de cada llamada
saliente y entre iteraciones de un bucle largo. Pasar el contexto a la capa de datos permite además
que la propia consulta se cancele, que es donde está el ahorro grande.

**03 → 11. ¿Por qué el navegador no puede hablar gRPC directamente? 🟡**

⏱️ **30 segundos** — Porque las APIs del navegador no dan el control sobre los flujos HTTP/2 que gRPC
necesita.

🗣️ **2 minutos** — Por eso existe una variante pensada para web, que ajusta el protocolo a lo que el
navegador sí puede hacer y normalmente requiere un proxy que traduzca. La alternativa habitual en
sistemas reales es exponer una fachada REST o un BFF hacia el frontend, y dejar gRPC para el interior.

🔬 **El detalle** — Esa asimetría es uno de los argumentos prácticos del capítulo siguiente: gRPC hacia
adentro y HTTP hacia afuera no es una concesión, es reconocer que los consumidores son distintos y
tienen restricciones distintas.

**03 → 12. ¿Qué te da cada plataforma para gRPC y en cuál cuesta más adoptarlo? 🟡**

⏱️ **30 segundos** — En Go es donde menos cuesta —el código generado es idiomático y el `context` ya
trae deadline y cancelación—; en Java está muy integrado; en Node/TS y Python funciona y hay que
elegir entre variantes o entre API síncrona y asíncrona.

🗣️ **2 minutos** — El coste de adopción no es el mismo: en Go la generación y el servidor son parte
del ecosistema natural; en Java la generación se integra en la construcción y los marcos modernos
arrancan el servidor por convención, a cambio de elegir tipo de stub; en Node/TS hay implementación
madura y alternativas con mejor ergonomía de tipos; en Python hay que decidir entre la API síncrona y
la asíncrona y no mezclarlas. En un sistema políglota, el coste no es la suma de cuatro: es mantener
cuatro cadenas de generación en cuatro pipelines.

🔬 **El detalle** — Ese coste de adopción es lo que de verdad decide en la práctica, más que cualquier
comparación de rendimiento: el mismo cambio es barato en un equipo de Go y caro en uno que no domina
la generación de código. Se desarrolla en
[`05-plataformas/06`](../05-plataformas/06-la-matriz-de-decision.md).

---
**03 → 13. ¿Por qué en Go el deadline "sale gratis" y en Java hay que fijarlo en cada llamada? 🟡**

⏱️ **30 segundos** — Porque en Go el plazo vive en el `context`, que ya se pasa por toda la cadena; en
Java el stub no lo pone solo y hay que fijarlo en cada llamada.

🗣️ **2 minutos** — El `context` de Go transporta plazo, cancelación y valores, así que al pasarlo —que
es obligatorio por la firma— el deadline viaja y se compone: si quien llamó tenía 500 ms, tu plazo
efectivo es lo que quede. En Java el deadline se fija en el stub por llamada, y olvidarlo significa
esperar indefinidamente, que es el comportamiento por defecto del protocolo.

🔬 **El detalle** — El precio de Go es la disciplina: una función que no recibe o no propaga el
`context` rompe a la vez plazo, cancelación y traza, y lo hace en silencio. A cambio se ve en la
revisión de código, mientras que en Java el plazo ausente no deja ningún rastro visible.

---
**03 → 14. ¿Qué es la reflexión y qué decisión hay que tomar sobre ella fuera de desarrollo? 🟠**

⏱️ **30 segundos** — Es la capacidad del servidor de describir sus servicios y mensajes, para que las
herramientas funcionen sin tener el `.proto`. Fuera de desarrollo hay que decidir si se deja activa.

🗣️ **2 minutos** — Con reflexión, las herramientas de línea de comandos descubren la API sola, lo que
hace la depuración muy cómoda. A cambio publica el catálogo completo de tu servicio a quien pueda
conectarse, así que la decisión depende de quién tiene acceso a la red interna y de la política de la
organización.

🔬 **El detalle** — Es una decisión, no una regla: en una red interna con autenticación mutua, dejarla
activa suele compensar por lo que ahorra en incidentes. Lo que no vale es no haberlo decidido.

**03 → 15. Te dicen que gRPC no se puede depurar. Responde en un minuto. 🟠**

⏱️ **30 segundos** — Es cierto que no se lee a ojo; no es cierto que no se pueda depurar. Hay clientes
de línea de comandos equivalentes a `curl`, y con reflexión no hace falta ni el esquema.

🗣️ **2 minutos** — La respuesta completa reconoce el coste real: pierdes la inspección directa del
tráfico y la posibilidad de probar desde el navegador. A cambio ganas que el error venga con un código
preciso, que el contrato no se pueda romper sin que falle la compilación, y que las herramientas
conozcan el esquema. Si el equipo depura mucho con `curl`, eso es un argumento legítimo a favor de
HTTP, y así se dice.

🔬 **El detalle** — En depuración se puede activar el registro de mensajes del propio gRPC, que imprime
peticiones y respuestas decodificadas. No se deja activo en producción por volumen y por datos
sensibles, pero resuelve la mayoría de las dudas en desarrollo.

**03 → 16. ¿Cuándo elegirías streaming de servidor en vez de varias llamadas unarias? 🟠**

⏱️ **30 segundos** — Cuando el resultado es grande o se produce a lo largo del tiempo, y trocearlo en
llamadas obligaría a paginar y a repetir contexto.

🗣️ **2 minutos** — Casos claros: exportar un millón de registros, seguir el avance de un proceso
largo, o recibir actualizaciones continuas. El streaming evita la paginación y el coste de establecer
llamadas repetidas. A cambio mantiene una conexión viva, lo que complica el despliegue y el balanceo,
y obliga a diseñar la reanudación.

🔬 **El detalle** — La pregunta que decide: ¿el cliente puede reanudar desde donde se cortó? Si sí,
hace falta un identificador de posición en el protocolo; si no se puede reanudar, cada corte implica
empezar de cero y el streaming deja de compensar en volúmenes grandes.

**03 → 17. Tienes tres instancias de `inventory` y todo el tráfico va a una. Diagnostica y da dos soluciones. 🟠**

⏱️ **30 segundos** — Es el balanceo por conexión: el cliente abrió una y la multiplexa. Soluciones:
balanceo en el cliente o un proxy que entienda HTTP/2.

🗣️ **2 minutos** — El diagnóstico se confirma mirando conexiones por instancia: una tiene todas las
del cliente. Con balanceo en el cliente, este resuelve las direcciones de todas las instancias y
reparte llamada a llamada; con proxy o mesh, el intermediario reparte y el cliente no se entera. La
tercera opción, menos elegante, es reciclar conexiones periódicamente para forzar redistribución.

🔬 **El detalle** — El caso empeora cuando las instancias escalan: las nuevas no reciben tráfico
porque nadie abre conexiones nuevas hacia ellas. Por eso el escalado automático y gRPC sin balanceo
por llamada se llevan especialmente mal.

**03 → 18. ¿Cómo evolucionarías un `.proto` para añadir un campo obligatorio, sin romper a los consumidores actuales? 🟠**

⏱️ **30 segundos** — Se añade como opcional, se migra a los productores, y la obligatoriedad se valida
en la aplicación cuando todos lo envían.

🗣️ **2 minutos** — En protobuf no existe la obligatoriedad como la entendemos: todos los campos son
opcionales en el cable, y el valor ausente llega como valor por defecto. Así que la secuencia es
añadir con número nuevo, desplegar consumidores que lo toleren, migrar productores, y solo entonces
rechazar peticiones sin él —con un código de error claro—.

🔬 **El detalle** — El valor por defecto es la trampa: un entero ausente llega como cero y una cadena
como vacía, así que "no enviado" y "enviado con valor cero" son indistinguibles salvo que se marque
explícitamente el campo como opcional o se use un tipo envuelto. Ese detalle ha causado más errores
que cualquier otra cosa de protobuf.

**03 → 19. ¿Dónde pondrías la autenticación y la propagación de traza en un servicio gRPC, y por qué ahí? 🟠**

⏱️ **30 segundos** — En interceptores, del lado del servidor y del cliente, y provistos por el chassis.

🗣️ **2 minutos** — El interceptor es el punto único por el que pasan todas las llamadas, igual que un
filtro en HTTP: ahí se valida la credencial de la metadata, se extrae el contexto de traza y se
inyecta en el saliente, y se registran métricas por método y código. Ponerlo en cada método es
duplicación garantizada y garantía de olvidos.

🔬 **El detalle** — Conviene que el interceptor de traza sea el más externo para que mida también el
tiempo del resto de interceptores; si la autenticación va por delante, las llamadas rechazadas no
aparecen en las métricas y se pierde justo la señal de un ataque o de una credencial caducada.

**03 → 20. Un equipo quiere exponer su servicio gRPC al equipo de frontend. ¿Qué propones? 🟠**

⏱️ **30 segundos** — Una fachada HTTP —gateway o BFF— delante, y gRPC solo hacia adentro.

🗣️ **2 minutos** — El navegador no habla gRPC directamente y la variante web necesita un proxy, así
que en cualquier caso hay una traducción. La opción con mejor relación entre coste y beneficio suele
ser un BFF propiedad del equipo de frontend, que además adapta la granularidad a las pantallas en
lugar de exponer el contrato interno tal cual.

🔬 **El detalle** — Conviene evitar la tentación de generar automáticamente el REST a partir del
`.proto` y publicarlo: eso acopla el frontend al modelo interno y convierte cada refactor en una
ruptura para el navegador, que es el cliente más difícil de migrar.

**03 → 21. ¿Qué plazo pondrías a una llamada gRPC dentro de un endpoint que promete responder en 1 s, y qué haces si el destino a veces tarda más? 🟠**

⏱️ **30 segundos** — Claramente menor que un segundo —del orden de 600 a 800 ms— y, si el destino a
veces tarda más, esa operación no puede estar en la ruta síncrona.

🗣️ **2 minutos** — El plazo se reparte dejando margen para el trabajo propio y para responder un error
controlado. Si el p99 del destino se acerca al presupuesto, hay tres caminos: que mejore, degradar
—responder sin ese dato—, o sacar la operación de la petición y hacerla asíncrona. Subir el plazo solo
traslada el problema a quien te llama.

🔬 **El detalle** — Con gRPC hay una ventaja concreta: al expirar el plazo, el destino recibe la
cancelación y puede abandonar. Eso significa que ajustar el plazo no solo protege tu latencia, también
libera recursos del otro lado, cosa que con HTTP hay que construir a mano.

**03 → 22. ¿Qué pierdes al usar gRPC entre dos servicios de equipos que no coordinan sus despliegues? 🟠**

⏱️ **30 segundos** — No pierdes compatibilidad si respetas las reglas de evolución; pierdes agilidad,
porque el esquema y la generación hay que gobernarlos entre los dos.

🗣️ **2 minutos** — Protobuf es muy bueno evolucionando —campos opcionales, números reservados—, así
que la compatibilidad se mantiene si ambos siguen las reglas. Lo que cuesta es el proceso: quién
publica el esquema, dónde vive, cómo se versiona y cómo se verifica que un cambio no rompe. Sin ese
gobierno, el contrato compilado da una falsa sensación de seguridad.

🔬 **El detalle** — La solución habitual es un registro de esquemas con verificación de compatibilidad
en el pipeline: el cambio incompatible falla en CI del que lo propone, no en producción del que lo
consume. Eso es tema del capítulo `07`.

**03 → 23. Diseña el `.proto` del servicio `InventoryService` con las operaciones de reservar y liberar, incluyendo idempotencia y errores, y explica cada decisión. 🔴**

⏱️ **30 segundos** — Dos métodos unarios, clave de idempotencia en la petición, identificador de
reserva en la respuesta, y errores por código de estado con detalle.

🗣️ **2 minutos** — El contrato:

```protobuf
service InventoryService {
  rpc Reserve(ReserveRequest) returns (ReserveResponse);
  rpc Release(ReleaseRequest) returns (ReleaseResponse);
}

message ReserveRequest {
  string order_id = 1;
  repeated OrderLine lines = 2;
  string idempotency_key = 3;     // permite reintentar sin duplicar
}

message ReserveResponse {
  string reservation_id = 1;      // lo necesita Release: la compensación lo usa
  google.protobuf.Timestamp expires_at = 2;  // la reserva caduca: evita fugas
}
```

Decisiones: unario porque la operación es corta; la clave de idempotencia la genera `orders` por
intención, no por intento; `reservation_id` en la respuesta para que la compensación de la saga sea
explícita y no tenga que deducirse del pedido; y caducidad, para que una saga interrumpida no deje
stock bloqueado para siempre.

🔬 **El detalle** — Los errores no van en el mensaje sino en el estado: stock insuficiente es
`FAILED_PRECONDITION` con detalle de qué línea falló, y no un campo `success: false` en la respuesta.
Mezclar errores de negocio dentro del cuerpo obliga al cliente a comprobar dos sitios y rompe el
reintento automático.

**03 → 24. Diagnostica: tras migrar de HTTP a gRPC, el p99 mejora pero aparecen picos de `DEADLINE_EXCEEDED` en horas punta. Da tres hipótesis ordenadas. 🔴**

⏱️ **30 segundos** — Reparto desequilibrado por balanceo de conexiones; plazos demasiado ajustados
para la cola en punta; o trabajo del servidor que no se cancela y se acumula.

🗣️ **2 minutos** — Las tres, con cómo se distinguen:

```text
1. Balanceo   una instancia con CPU alta y las otras ociosas; conexiones
              concentradas. Se confirma mirando conexiones por instancia
2. Plazos     la latencia media está bien pero la cola crece en punta;
              el deadline corta antes de que llegue el turno
3. Sin cancelar el servidor sigue procesando peticiones ya abandonadas, lo que
              alimenta la saturación. Se ve comparando peticiones entrantes
              con respuestas entregadas
```

El orden responde a la probabilidad: el balanceo es el problema característico de gRPC y aparece justo
cuando hay carga.

🔬 **El detalle** — Las tres se refuerzan entre sí, y por eso el incidente parece repentino: el
desequilibrio satura una instancia, la saturación hace que los plazos expiren, y el trabajo no
cancelado impide que se recupere. Arreglar solo una puede no bastar.

**03 → 25. Diseña la política de reintentos de un cliente gRPC: qué códigos, cuántos intentos, qué espera, y qué interacción tiene con el deadline. 🔴**

⏱️ **30 segundos** — Reintentar solo `UNAVAILABLE` y `RESOURCE_EXHAUSTED`, dos intentos como máximo,
espera exponencial con jitter, y todo dentro del deadline original.

🗣️ **2 minutos** — La política:

```text
Códigos          UNAVAILABLE, RESOURCE_EXHAUSTED
                 DEADLINE_EXCEEDED solo si la operación es idempotente Y queda margen
Intentos         2 reintentos como máximo, y presupuesto global (p. ej. ≤10 % del tráfico)
Espera           exponencial con jitter, empezando en decenas de milisegundos
Deadline         NO se renueva: los reintentos consumen el plazo original.
                 Si no queda tiempo para otro intento, se falla directamente
Idempotencia     escrituras solo con clave de idempotencia
```

La interacción con el deadline es la parte que se olvida: si cada reintento renovara el plazo, una
llamada con tres intentos podría durar el triple de lo prometido y romper el presupuesto de quien
llama.

🔬 **El detalle** — Y la regla que evita el desastre: reintentar en una sola capa. Si reintentan el
cliente, la librería de resiliencia y el mesh, los intentos se multiplican entre sí. Conviene decidir
explícitamente dónde vive el reintento y desactivarlo en las demás.

**03 → 26. Un equipo propone pasar todas las llamadas internas a gRPC en un trimestre. Da tu plan por fases y di qué medirías para decidir si continuar. 🔴**

⏱️ **30 segundos** — Empezar por un par de servicios con contrato estable y equipos dispuestos, medir
antes de generalizar, y no tocar lo que sale al exterior.

🗣️ **2 minutos** — El plan:

```text
F1  Elegir un par de servicios con contrato estable y tráfico alto.
    Montar generación en el pipeline y registro de esquemas.
F2  Convivencia: el servicio expone gRPC y mantiene HTTP; el cliente migra.
    Medir latencia, errores, uso de CPU y esfuerzo real del equipo.
F3  Decisión con datos: si el beneficio no aparece, se para y se documenta por qué.
F4  Extensión gradual, con el balanceo resuelto ANTES de generalizar.
Nunca  el borde hacia el navegador y hacia terceros: eso sigue en HTTP.
```

🔬 **El detalle** — Lo que mediría para decidir: incidentes por deriva de contrato antes y después
—que es el beneficio real—, latencia y CPU —que suelen mejorar poco—, y tiempo de incorporación de un
desarrollador nuevo al flujo de generación, que es el coste que nadie presupuesta y el que más
determina si la migración se sostiene.

---

# 04 — HTTP contra gRPC

**04 → 1. Nombra cinco dimensiones en las que se comparan HTTP y gRPC. 🟢**

⏱️ **30 segundos** — Contrato, formato, plazos, tooling y soporte de infraestructura. Y añadiría
navegador y curva del equipo.

🗣️ **2 minutos** — El contrato es descriptivo en HTTP y compilado en gRPC; el formato es texto frente
a binario; los plazos son locales frente a deadlines que se propagan; el tooling es universal frente
a específico; y la infraestructura entiende HTTP en todas partes, mientras gRPC exige HTTP/2 de punta
a punta y balanceo por llamada.

🔬 **El detalle** — De las diez dimensiones de la tabla, solo dos suelen decidir: el contrato, que es
lo que justifica adoptar gRPC, y la infraestructura, que es lo que lo frena. Las demás rara vez
cambian la respuesta.

**04 → 2. ¿Cuál es la dimensión que más justifica adoptar gRPC? 🟢**

⏱️ **30 segundos** — El contrato compilado: romperlo deja de compilar en vez de fallar en producción.

🗣️ **2 minutos** — Si el dolor del equipo es que los contratos derivan —alguien renombra un campo y
el otro se entera con un incidente—, gRPC lo ataca de raíz, porque del `.proto` salen los tipos, el
cliente y el servidor. Si ese no es tu dolor, estás comprando la solución a un problema que no
tienes.

🔬 **El detalle** — El mismo beneficio se puede conseguir en HTTP con OpenAPI, cliente generado y
verificación de compatibilidad en CI. La diferencia es que en gRPC viene de serie y en HTTP hay que
montarlo y sostenerlo con disciplina.

**04 → 3. ¿Qué parte del tiempo de una llamada típica ocupa la serialización? 🟢**

⏱️ **30 segundos** — Una parte pequeña: casi todo el tiempo es red y trabajo del servidor.

🗣️ **2 minutos** — Una llamada entre servicios suele tener medio milisegundo a unos pocos de red y
decenas de milisegundos de trabajo real —base de datos, lógica, otras llamadas—. Serializar y parsear
JSON está en el orden de microsegundos a pocos milisegundos según el tamaño. Por eso el argumento de
velocidad casi nunca decide.

🔬 **El detalle** — Hay tres casos donde sí domina: mensajes grandes o muy frecuentes, clientes
móviles con ancho de banda limitado, y servicios de altísimo volumen donde el porcentaje de CPU
dedicado a serializar es medible. Nombrar esos tres casos es lo que hace creíble el argumento.

**04 → 4. ¿Por qué el navegador obliga a HTTP en el borde? 🟢**

⏱️ **30 segundos** — Porque no puede hablar gRPC directamente: sus APIs no dan el control sobre los
flujos HTTP/2 que gRPC necesita.

🗣️ **2 minutos** — Existe una variante pensada para web, pero requiere normalmente un proxy que
traduzca, así que en cualquier caso hay una capa de traducción. La opción habitual es exponer HTTP
—gateway o BFF— hacia el navegador y dejar gRPC para el interior, que es el caso mixto.

🔬 **El detalle** — Esta asimetría no es un defecto de gRPC: es que los consumidores del borde y los
del interior tienen restricciones distintas. Reconocerlo lleva directamente al diseño mixto en vez de
a elegir un solo protocolo para todo.

**04 → 5. ¿Cuál es el nicho exacto de tRPC? 🟢**

⏱️ **30 segundos** — Ambos lados en TypeScript, en el mismo repositorio y desplegados juntos.

🗣️ **2 minutos** — En ese escenario es imbatible en ergonomía: el tipo del servidor llega al cliente
sin generación de código ni esquema intermedio. En cuanto un lado deja de ser TypeScript o deja de
compartir repositorio, el modelo se rompe, porque el contrato no existe fuera del compilador.

🔬 **El detalle** — Por eso no es "el gRPC de TypeScript": gRPC está pensado precisamente para
equipos y lenguajes distintos que no comparten código. Son herramientas para problemas opuestos.

**04 → 6. ¿Dónde tiene su sitio GraphQL y dónde no? 🟡**

⏱️ **30 segundos** — En el borde, entre el frontend y los servicios. No entre dos servicios internos
que se conocen.

🗣️ **2 minutos** — Resuelve el problema de consumidores heterogéneos: cada pantalla necesita una
combinación distinta de campos y no quieres un endpoint por pantalla. Entre servicios internos esa
flexibilidad no se usa, y en cambio pagas el coste: proteger el punto de entrada de consultas caras,
caché más difícil y el `N+1` si no se agrupan resoluciones.

🔬 **El detalle** — El coste que más sorprende es la caché: con HTTP cacheas por URL en cualquier
capa intermedia; con GraphQL, las peticiones son `POST` con cuerpos distintos y la caché hay que
construirla dentro de la aplicación.

**04 → 7. ¿Por qué los benchmarks que comparan HTTP y gRPC exageran la diferencia? 🟡**

⏱️ **30 segundos** — Porque miden servidores vacíos que devuelven una respuesta fija: ahí serializar
es el 100 % del trabajo.

🗣️ **2 minutos** — En un servicio real que consulta una base de datos y llama a otros, la
serialización es una fracción pequeña, así que la mejora relativa se diluye hasta ser difícil de
medir. El benchmark no miente, mide otra cosa: la eficiencia del serializador, no la latencia de tu
sistema.

🔬 **El detalle** — La forma honesta de citar cifras en una entrevista es decir de dónde salen y qué
no miden. Y si de verdad importa, la medición correcta es tu propio servicio con tu propio tráfico,
comparando el mismo endpoint en ambos protocolos.

**04 → 8. ¿En qué se diferencia el versionado de un `.proto` del de una API REST? 🟡**

⏱️ **30 segundos** — En gRPC las reglas de compatibilidad están en el formato; en REST dependen de
convenciones y disciplina.

🗣️ **2 minutos** — Protobuf te dice exactamente qué puedes cambiar: añadir campos con número nuevo
sí, reutilizar números no, renombrar sí. En REST todo eso es acuerdo entre personas, y por eso se
necesita verificación automática de compatibilidad del esquema en CI para conseguir la misma
garantía.

🔬 **El detalle** — Lo que gRPC **no** te da gratis es la evolución semántica: puedes añadir un campo
compatible en el cable y romper al consumidor porque el significado de otro cambió. Eso sigue
necesitando contratos de consumidor o pruebas de compatibilidad reales.

**04 → 9. ¿Por qué los deadlines son una ventaja infravalorada frente a los timeouts locales? 🟡**

⏱️ **30 segundos** — Porque se propagan: cada salto sabe cuánto tiempo queda y puede abandonar, en
lugar de trabajar para una respuesta que ya nadie espera.

🗣️ **2 minutos** — Con timeouts locales, cada servicio pone el suyo sin conocer el presupuesto total,
así que el de abajo puede seguir consultando la base de datos cuando el de arriba ya se rindió. Con
deadlines, el presupuesto de latencia funciona solo y la cancelación libera recursos en toda la
cadena, que es justo lo que necesitas durante un incidente.

🔬 **El detalle** — Es replicable en HTTP: se propaga un encabezado con el plazo restante y cada
servicio lo respeta. Pero hay que construirlo, mantenerlo y que todos lo respeten, mientras que en
gRPC es parte del protocolo y las librerías ya lo implementan.

**04 → 10. ¿Qué coste de infraestructura introduce gRPC que HTTP no tiene? 🟡**

⏱️ **30 segundos** — Exige HTTP/2 de punta a punta y balanceo por llamada, no por conexión.

🗣️ **2 minutos** — Cualquier proxy, WAF, caché o balanceador entiende HTTP/1.1; con gRPC hay que
comprobar que toda la cadena soporta HTTP/2 sin degradar, y que el reparto no asigna una conexión
por cliente. Si la plataforma solo balancea conexiones, todo el tráfico irá a una instancia y se
descubrirá el día del pico.

🔬 **El detalle** — Se lleva especialmente mal con el escalado automático: las instancias nuevas no
reciben tráfico porque nadie abre conexiones hacia ellas. Comprobar esto antes de aprobar gRPC es la
diferencia entre una migración tranquila y un incidente.

**04 → 11. ¿En qué casos concretos sí domina el coste de serialización? 🟡**

⏱️ **30 segundos** — Mensajes grandes o muy frecuentes, clientes móviles con ancho de banda limitado,
y servicios de volumen muy alto.

🗣️ **2 minutos** — En telemetría o sincronización masiva, el tamaño del mensaje se traduce
directamente en ancho de banda y en CPU de parseo. En móvil, el ahorro de bytes se nota en batería y
en redes lentas. Y en servicios que procesan decenas de miles de mensajes por segundo, el porcentaje
de CPU dedicado a serializar es medible y se puede ahorrar.

🔬 **El detalle** — En los tres casos conviene medir antes: el mismo mensaje comprimido con gzip sobre
HTTP reduce mucho el ancho de banda, aunque no el coste de CPU de parseo. A veces la comparación
justa no es JSON contra protobuf, sino JSON comprimido contra protobuf.

**04 → 12. ¿Por qué no se debe generar el contrato externo a partir del interno? 🟠**

⏱️ **30 segundos** — Porque acopla al consumidor externo a tus decisiones internas, y cada refactor se
convierte en una ruptura para el cliente más caro de migrar.

🗣️ **2 minutos** — El contrato interno está optimizado para servicios que se conocen; el externo, para
consumidores heterogéneos con ritmos de despliegue que no controlas. Generar uno del otro parece
ahorro y es deuda: seis meses después, renombrar un campo interno rompe la web.

🔬 **El detalle** — La consecuencia de diseño es que el BFF o el gateway tienen que **traducir**, no
reenviar. Esa traducción es código aburrido que hay que mantener, y es exactamente lo que compra la
libertad de evolucionar por dentro.

**04 → 13. Sistema todo en Go, contratos estables, dos equipos. ¿HTTP o gRPC? Justifica. 🟠**

⏱️ **30 segundos** — gRPC, siempre que la plataforma balancee por llamada: en Go es donde menos
cuesta y donde más idiomático queda.

🗣️ **2 minutos** — La generación se integra sin fricción, el código generado es natural, y el
`context` ya trae deadline y cancelación, así que el presupuesto de latencia sale gratis. Con
contratos estables y dos equipos que pueden coordinar la generación, se cumplen las tres condiciones
del árbol de decisión. La comprobación que queda es el balanceo.

🔬 **El detalle** — Aun así, el borde hacia el navegador o hacia terceros sigue en HTTP. La respuesta
completa dice "gRPC hacia adentro, HTTP hacia afuera", porque una respuesta que elige un solo
protocolo para todo suele indicar que no se ha pensado en los consumidores externos.

**04 → 14. Sistema con cuatro plataformas y equipos que rotan. Misma pregunta, y di qué cambia. 🟠**

⏱️ **30 segundos** — Aquí me inclino por HTTP con OpenAPI y compatibilidad verificada en CI: el coste
de mantener cuatro cadenas de generación es desproporcionado.

🗣️ **2 minutos** — Lo que cambia es el coste de adopción: no es la suma de cuatro, es mantener cuatro
pipelines de generación, cuatro conjuntos de herramientas y cuatro curvas de aprendizaje, con gente
que rota entre servicios. Con HTTP, cualquiera puede depurar con `curl` y el contrato se verifica
igualmente en CI, que es el beneficio que de verdad buscábamos.

🔬 **El detalle** — La excepción razonable es aplicar gRPC solo en el tramo donde el beneficio es
claro: dos servicios de alto volumen con contrato estable, mientras el resto sigue en HTTP. Mezclar a
propósito es mejor respuesta que uniformar por estética.

**04 → 15. Te piden migrar a gRPC "por rendimiento". ¿Qué mides antes de aceptar? 🟠**

⏱️ **30 segundos** — Dónde se va el tiempo hoy: reparto entre red, trabajo del servidor y
serialización, en el endpoint que preocupa.

🗣️ **2 minutos** — Con una traza desglosada se ve enseguida si serializar es una fracción relevante.
Si no lo es —lo habitual—, la conversación cambia: ¿el problema real es la deriva de contratos, el
tamaño de los mensajes o simplemente la lentitud de una consulta? Y conviene medir también el tamaño
de los mensajes, porque ahí sí puede haber ahorro real.

🔬 **El detalle** — Si tras medir el beneficio de rendimiento es pequeño pero el de contrato es
grande, la propuesta sigue siendo razonable: solo hay que cambiar su justificación. Aceptar la
migración por el motivo correcto evita que dentro de seis meses alguien la juzgue por una métrica que
nunca iba a mejorar.

**04 → 16. ¿Cómo diseñarías el borde de un sistema que usa gRPC por dentro? 🟠**

⏱️ **30 segundos** — Un gateway o un BFF que habla HTTP hacia afuera y gRPC hacia adentro, con
contrato externo propio y traducción explícita.

🗣️ **2 minutos** — El borde se ocupa de TLS, autenticación, límite de tasa y enrutado; el BFF, además,
adapta la granularidad a cada experiencia de cliente. Lo importante es que el contrato externo se
diseñe para sus consumidores y se mantenga estable, aunque por dentro los servicios cambien. Nada de
generar el REST automáticamente del `.proto`.

🔬 **El detalle** — Conviene decidir también qué pasa con los errores: los códigos gRPC se traducen a
códigos HTTP y a códigos de dominio estables del contrato externo. Si esa traducción no está
diseñada, el cliente acaba recibiendo un 500 para cosas que eran perfectamente explicables.

**04 → 17. El equipo de frontend pide GraphQL. ¿Qué preguntas antes de decidir? 🟠**

⏱️ **30 segundos** — Cuántos consumidores distintos hay, cuánto varían sus necesidades de datos, y
quién va a operar y proteger el punto de entrada.

🗣️ **2 minutos** — GraphQL compensa con varios clientes heterogéneos —web, móvil, socios— que piden
combinaciones distintas. Con un solo frontend, un BFF con endpoints a medida da el mismo beneficio con
mucho menos coste. Y hay que acordar desde el principio quién se ocupa de los límites de profundidad
y complejidad, de la caché y del agrupamiento de resoluciones.

🔬 **El detalle** — Una pregunta que ordena la conversación: ¿el problema es que faltan datos en las
respuestas, o que sobran? Si sobran, casi siempre se arregla con campos opcionales o con un par de
endpoints nuevos; si faltan y cada pantalla necesita una combinación distinta, GraphQL empieza a
tener sentido.

**04 → 18. ¿Qué harías con un servicio SOAP del core bancario con el que tienes que integrarte? 🟠**

⏱️ **30 segundos** — Integrarme tal cual, detrás de una capa anticorrupción, y no dejar que su modelo
entre en mi dominio.

🗣️ **2 minutos** — Migrarlo normalmente no está sobre la mesa: es el core, lo mantiene otro equipo y
tiene auditorías encima. La estrategia es encapsularlo en un adaptador que traduzca su modelo al
tuyo, con sus propias pruebas de traducción, y tratar sus tiempos y sus modos de fallo como los de
cualquier dependencia lenta: timeout, reintento solo si es idempotente, y circuit breaker.

🔬 **El detalle** — SOAP tiene ventajas que conviene reconocer en voz alta: contrato fuerte con WSDL,
herramientas maduras y estándares de seguridad auditados durante años. Despacharlo con desdén en una
entrevista de banca es una mala señal; tratarlo como una dependencia más, con su capa de traducción,
es la respuesta de alguien que ha trabajado en el sector.

**04 → 19. ¿Qué tres comprobaciones haces sobre tu plataforma antes de aprobar gRPC? 🟠**

⏱️ **30 segundos** — Que haya HTTP/2 de punta a punta, que el balanceo sea por llamada, y que el
observatorio —trazas y métricas— entienda gRPC.

🗣️ **2 minutos** — La primera exige revisar proxies, balanceadores y cualquier WAF intermedio. La
segunda es la que produce el desequilibrio clásico y se resuelve con balanceo en cliente, proxy L7 o
mesh. La tercera se olvida: si tus paneles y alertas están construidos sobre códigos HTTP, con gRPC
dejan de ver lo que pasa hasta que se adaptan a sus códigos de estado.

🔬 **El detalle** — Añadiría una cuarta comprobación organizativa: quién publica y gobierna los
esquemas. Sin dueño del registro de contratos, el beneficio principal de gRPC se diluye en tres meses.

**04 → 20. Defiende HTTP con OpenAPI verificado en CI frente a alguien que quiere gRPC por el contrato. 🟠**

⏱️ **30 segundos** — El beneficio que busca —que un cambio incompatible falle antes de producción— se
consigue con OpenAPI, cliente generado y verificación de compatibilidad en el pipeline.

🗣️ **2 minutos** — Con eso obtienes contrato versionado, cliente generado y ruptura detectada en CI,
sin cambiar de protocolo, sin tocar la infraestructura y sin curva de aprendizaje. La diferencia real
que queda a favor de gRPC son los deadlines propagados y el streaming; si ninguno de los dos es tu
problema, el cambio no se paga.

🔬 **El detalle** — Conviene conceder lo que es cierto: en HTTP esa disciplina hay que montarla y
sostenerla, y se degrada si nadie la vigila; en gRPC viene de serie. Si el equipo no va a mantener la
verificación, entonces el argumento a favor de gRPC es legítimo y así hay que decirlo.

**04 → 21. Escribe la respuesta completa de dos minutos a "¿HTTP o gRPC entre tus servicios?", con las tres partes del capítulo. 🔴**

⏱️ **30 segundos** — "Depende de tres cosas: qué dimensión me duele, cómo balancea mi plataforma, y
cuánto cuesta adoptarlo en mis equipos."

🗣️ **2 minutos** — La respuesta desarrollada:

```text
1. Qué dimensión decide   La que justifica gRPC es el contrato compilado, no la velocidad:
                          en una llamada típica, serializar es una fracción pequeña frente
                          a red y trabajo del servidor.
2. Qué lo frena           gRPC exige HTTP/2 de punta a punta y balanceo por llamada;
                          si la plataforma balancea conexiones, todo el tráfico va a una
                          instancia. Y el navegador no habla gRPC, así que el borde es HTTP.
3. Qué cuesta adoptarlo   En Go es casi gratis; en un sistema con cuatro plataformas son
                          cuatro cadenas de generación que mantener.
Conclusión                gRPC hacia adentro si el contrato es mi dolor, la plataforma
                          acompaña y el equipo lo sostiene; si no, HTTP con OpenAPI
                          verificado en CI, que da el mismo beneficio de contrato.
```

🔬 **El detalle** — Lo que sube la nota es mencionar los deadlines: es la ventaja de gRPC que casi
nadie nombra y la que más se agradece en cadenas de llamadas, porque convierte el presupuesto de
latencia en algo automático en vez de un acuerdo que cada equipo respeta a su manera.

**04 → 22. Diseña la comunicación de un sistema con web, móvil, cinco servicios internos y una integración con un tercero, eligiendo estilo para cada tramo y justificando. 🔴**

⏱️ **30 segundos** — HTTP en el borde con un BFF por experiencia, gRPC o HTTP entre servicios según
el dolor, eventos para los efectos, y el tercero detrás de una cola.

🗣️ **2 minutos** — El diseño:

```text
Tramo                        Estilo                Por qué
───────────────────────────  ────────────────────  ──────────────────────────────────
web / móvil → borde          HTTP + JSON           el navegador no habla gRPC; caché,
                                                   herramientas y compatibilidad
borde → servicios            BFF por experiencia   granularidad por pantalla; el contrato
                                                   externo no se genera del interno
servicio ↔ servicio          gRPC si el contrato   deadlines propagados y contrato compilado;
 (consultas)                 es el dolor; si no,   HTTP si el equipo o la plataforma
                             HTTP con OpenAPI      no lo sostienen
efectos (notificar,          eventos en topic      desacopla en el tiempo; añadir consumidores
 proyecciones)                                     no toca al emisor
integración con tercero      cola + reintentos     su disponibilidad no puede ser la mía
                             + DLQ
```

🔬 **El detalle** — La decisión que el entrevistador va a cuestionar es el BFF por experiencia: parece
duplicar trabajo. El argumento es de propiedad, no de tecnología —lo mantiene quien conoce la
pantalla— y de ritmo: móvil no puede desplegar cuando quiere, así que su contrato tiene que durar más
que el de la web.

**04 → 23. Un equipo migró a gRPC y el rendimiento no mejoró. Analiza qué pudo pasar y qué beneficio pudieron haber obtenido igualmente. 🔴**

⏱️ **30 segundos** — Lo esperable: su tiempo estaba en red y en base de datos, no en serializar. El
beneficio real está en el contrato y en los deadlines.

🗣️ **2 minutos** — El análisis:

```text
Por qué no mejoró        serializar era una fracción pequeña del tiempo total
                         y el trabajo del servidor no cambió
Qué pudo empeorar        balanceo por conexión: una instancia saturada
                         y latencia peor en punta
Qué sí ganaron           contratos que no derivan: los cambios incompatibles
                         fallan al compilar
                         deadlines propagados: presupuesto de latencia automático
                         y cancelación aguas abajo
Qué medir ahora          incidentes por deriva de contrato antes/después,
                         y trabajo cancelado por deadline en horas punta
```

🔬 **El detalle** — La conclusión útil para el equipo es cambiar la métrica de éxito, no revertir: si
la migración se vendió por rendimiento, alguien la juzgará por rendimiento. Reconocer públicamente
que el beneficio es otro evita que el trabajo se dé por fallido y que la siguiente decisión técnica
se tome a la defensiva.

**04 → 24. Diseña el plan de prueba de tres semanas que decidiría si adoptar gRPC en tu sistema: qué mides, con qué umbrales, y qué decisión tomas con cada resultado. 🔴**

⏱️ **30 segundos** — Un par de servicios reales, convivencia con HTTP, y tres métricas: contrato,
latencia y esfuerzo del equipo.

🗣️ **2 minutos** — El plan:

```text
Semana 1  Montar generación en el pipeline y registro de esquemas.
          Un servicio expone gRPC y mantiene HTTP; el cliente sigue en HTTP.
Semana 2  El cliente migra a gRPC con 10 % del tráfico. Balanceo verificado ANTES.
Semana 3  100 % en ese tramo. Medición y decisión.

Métrica                   Umbral                      Decisión
────────────────────────  ──────────────────────────  ────────────────────────────
Reparto entre instancias  desvío < 20 %               si falla: arreglar balanceo o parar
p99 del tramo             no peor que HTTP            si empeora: investigar antes de seguir
Cambios incompatibles     detectados en CI, no en     si no se detectan: el registro
 detectados               producción                   no está bien montado
Esfuerzo del equipo       un desarrollador nuevo       si tarda más: el coste de adopción
                          produce en < 1 día           es mayor que el beneficio
```

🔬 **El detalle** — La métrica que casi nadie incluye y que más predice el resultado a un año es la
última: cuánto tarda alguien que no montó el sistema en añadir un método y desplegarlo. Si la cadena
de generación es frágil o está mal documentada, la migración funciona mientras la sostienen sus
autores y se degrada en cuanto rotan.

---

# 05 — Tiempo real: WebSockets, SSE y los demás

**05 → 1. ¿Qué problema resuelven SSE, WebSocket y el polling? 🟢**

⏱️ **30 segundos** — Que el servidor tenga algo que decir cuando el cliente no está preguntando, que
es justo lo contrario del supuesto de HTTP.

🗣️ **2 minutos** — Las tres son formas de rodear ese supuesto: preguntar repetidamente, mantener un
flujo abierto en un sentido, o abrir un canal en ambos. La elección depende de cuánta latencia tolera
el usuario, de cuántos clientes hay y de si hace falta canal de vuelta.

🔬 **El detalle** — Entre servicios internos casi nunca se necesita ninguna de las tres: ahí están los
eventos y el streaming de gRPC, que ya traen orden, reintentos y observabilidad. Estos mecanismos son
casi siempre para el tramo servidor → cliente final.

**05 → 2. ¿Qué campo de SSE permite reanudar tras un corte, y cómo funciona? 🟢**

⏱️ **30 segundos** — El `id` de cada evento: el cliente lo recuerda y al reconectar lo envía para
recibir desde ahí.

🗣️ **2 minutos** — El navegador reconecta solo y manda el último identificador recibido; el servidor
solo tiene que saber reenviar desde esa posición. Eso convierte un corte de red en un hueco de
milisegundos sin que nadie escriba lógica de reconexión, y es la ventaja que casi nadie menciona
cuando compara SSE con WebSocket.

🔬 **El detalle** — Para que funcione, el servidor debe poder recuperar los eventos posteriores a un
identificador dado, lo que implica retenerlos un tiempo. Si no se guarda nada, la reconexión
funciona pero se pierden los eventos ocurridos durante el corte.

**05 → 3. ¿Qué significa que WebSocket "no trae semántica"? 🟢**

⏱️ **30 segundos** — Que después del `Upgrade` no hay métodos, ni códigos de estado, ni reintento, ni
reconexión: el protocolo de mensajes lo inventas tú.

🗣️ **2 minutos** — Tienes un canal por el que viajan marcos y nada más. Eso significa definir tipos de
mensaje, formato de error, versionado, confirmaciones y latidos. Es trabajo real y es un contrato
como cualquier otro, con la diferencia de que aquí nadie te recuerda que hay que versionarlo.

🔬 **El detalle** — Por eso las capas que se usan encima —las que añaden reconexión, salas y
confirmaciones— no son un detalle de librería: eligen por ti el protocolo de mensajes, y cambiarlas
después es una migración.

**05 → 4. Enumera las cuatro piezas que hay que diseñar al recibir webhooks. 🟢**

⏱️ **30 segundos** — Verificación de firma, idempotencia, respuesta rápida con encolado, y política de
reintentos con DLQ si además emites.

🗣️ **2 minutos** — La firma es imprescindible porque tu URL es pública y cualquiera puede llamarla. La
idempotencia, porque el emisor reintentará y el mismo evento llegará varias veces y a veces
desordenado. Y responder rápido encolando evita que el procesamiento largo provoque timeouts que
disparan más reintentos.

🔬 **El detalle** — El orden importa: primero verificar firma, luego deduplicar por identificador del
evento, después encolar y responder. Deduplicar antes de verificar permite que alguien envenene tu
tabla de deduplicación con identificadores inventados.

**05 → 5. ¿Por qué se dice que una conexión abierta convierte al servicio en algo con estado? 🟢**

⏱️ **30 segundos** — Porque la conexión vive en una instancia concreta, y quien quiera empujar al
usuario tiene que llegar a esa instancia.

🗣️ **2 minutos** — Deja de ser cierto que cualquier instancia pueda atender cualquier petición: el
escalado no redistribuye conexiones existentes, el despliegue las corta todas de golpe, y el evento
que nace en otro servicio no sabe dónde está el usuario. Por eso aparecen el backplane y la capa de
conexiones dedicada.

🔬 **El detalle** — El coste se puede acotar mucho con reconexión y reanudación —lo que da SSE—:
entonces cortar una conexión deja de ser un problema grave y el despliegue vuelve a ser casi
transparente.

**05 → 6. ¿Qué mecanismo usarías entre dos servicios internos para notificar un cambio? 🟢**

⏱️ **30 segundos** — Un evento en un topic; y si es un flujo continuo de datos, streaming de gRPC.

🗣️ **2 minutos** — El broker ya resuelve entrega, reintentos, DLQ, orden dentro de la partición y
observabilidad, que es exactamente lo que tendrías que reinventar con un WebSocket entre servicios.
El streaming de gRPC tiene sentido cuando hay volumen alto y continuo entre dos servicios concretos,
no para notificaciones sueltas.

🔬 **El detalle** — Ver un WebSocket entre dos servicios internos suele indicar que alguien trasladó
una solución del frontend al backend. Merece la pregunta: ¿qué te da que no te dé el broker? A veces
la respuesta es latencia de milisegundos, y entonces es legítimo.

**05 → 7. ¿Por qué SSE atraviesa proxies y balanceadores mejor que WebSocket? 🟡**

⏱️ **30 segundos** — Porque es HTTP corriente: una respuesta con un tipo de contenido concreto que no
termina, sin cambio de protocolo.

🗣️ **2 minutos** — WebSocket requiere que toda la cadena intermedia entienda y permita el `Upgrade`,
y algunos WAF o proxies corporativos no lo hacen. SSE se autentica con los mismos encabezados que
cualquier petición y se registra en los mismos logs de acceso, lo que además simplifica el
diagnóstico.

🔬 **El detalle** — El punto de fricción que sí tiene SSE es la caché y el almacenamiento intermedio:
si un proxy decide almacenar la respuesta, no entrega nada hasta que termine —y no termina nunca—. Se
evita con `Cache-Control: no-cache` y, en algunos proxies, desactivando el búfer explícitamente.

**05 → 8. Diferencia entre polling, long polling y SSE en consumo de conexiones. 🟡**

⏱️ **30 segundos** — El polling abre y cierra continuamente; el long polling mantiene una conexión
ocupada esperando; SSE mantiene una abierta recibiendo.

🗣️ **2 minutos** — En consumo de conexiones, long polling y SSE se parecen: ambas retienen una
conexión por cliente. La diferencia es la ergonomía: el long polling reabre tras cada respuesta y
necesita lógica de reconexión y de detección de novedades, mientras SSE entrega eventos según llegan
y reconecta solo.

🔬 **El detalle** — El polling simple tiene una ventaja que se subestima: no retiene nada, así que
escala con el mismo modelo que el resto del servicio y el despliegue no lo nota. Por eso, con pocos
clientes y latencia tolerable, sigue siendo la opción más barata en total.

**05 → 9. ¿Qué es un backplane y qué problema concreto resuelve? 🟡**

⏱️ **30 segundos** — Un canal común —normalmente un broker— al que se suscriben todas las instancias
para poder empujar a las conexiones que cada una tiene.

🗣️ **2 minutos** — Resuelve que el evento nace en un sitio y la conexión del usuario está en otro:
`payments` publica, todas las instancias que mantienen conexiones lo reciben, y la que tiene a ese
usuario le empuja. Sin backplane, solo puede notificar la instancia donde se generó el evento, que
casi nunca es la correcta.

🔬 **El detalle** — El coste es latencia extra y un broker más en el camino crítico del empuje. Y una
decisión de diseño: si se difunde todo a todas las instancias, la carga crece con el número de
instancias; por eso a partir de cierta escala se usa enrutado por usuario en vez de difusión.

**05 → 10. ¿Por qué el despliegue es especialmente molesto con conexiones largas? 🟡**

⏱️ **30 segundos** — Porque al reemplazar una instancia se cortan de golpe todas sus conexiones, y
todos esos clientes reconectan a la vez.

🗣️ **2 minutos** — Eso produce un pico de reconexiones que puede tumbar a las instancias que quedan,
sobre todo si cada reconexión implica autenticar y recuperar estado. Las mitigaciones son reconexión
con espera aleatoria en el cliente, reemplazos graduales con margen entre instancias, y un modelo de
reanudación que haga barata la vuelta.

🔬 **El detalle** — El efecto es de rebaño: si todos los clientes reconectan en el mismo instante, el
pico se repite en cada despliegue. El jitter en el cliente no es un adorno, es lo que convierte ese
pico en una rampa.

**05 → 11. ¿Qué pasa con la autenticación cuando el token caduca a mitad de una conexión? 🟡**

⏱️ **30 segundos** — Que no hay una petición nueva donde renovarlo: hay que decidir si se renueva por
el propio canal o si se corta y se reconecta.

🗣️ **2 minutos** — Con WebSocket, lo habitual es un mensaje de renovación dentro del protocolo propio;
con SSE, cortar y reconectar con el token nuevo, que es barato porque la reanudación viene incluida.
Lo que no se puede es autenticar al abrir y olvidarse: una conexión de horas con un token de minutos
convierte la sesión en eterna.

🔬 **El detalle** — Hay un matiz de autorización, no solo de autenticación: si al usuario le revocan
permisos, la conexión abierta sigue recibiendo datos a los que ya no debería acceder. Por eso conviene
revalidar periódicamente, y no solo al abrir.

**05 → 12. ¿Por qué en Node una operación de CPU es más grave con conexiones abiertas que sin ellas? 🟡**

⏱️ **30 segundos** — Porque el bucle bloqueado congela a todos los conectados a la vez, no solo a
quien hizo la petición.

🗣️ **2 minutos** — Sin conexiones persistentes, un bloqueo retrasa las peticiones en curso y las
siguientes se atienden después. Con miles de conexiones abiertas, además dejan de fluir todos los
flujos y los latidos, lo que puede provocar que los clientes consideren muerta la conexión y
reconecten en masa —justo cuando el proceso ya iba mal—.

🔬 **El detalle** — La mitigación es la de siempre: sacar el cómputo a hilos de trabajo o a otro
servicio. Y en servicios con muchas conexiones conviene separar el proceso que mantiene conexiones
del que hace trabajo pesado, que es el argumento natural para la capa de conexiones dedicada.

**05 → 13. ¿Qué latidos y qué timeouts configuras en un canal persistente, y por qué? 🟡**

⏱️ **30 segundos** — Un latido cada 15 a 30 segundos, y un timeout de inactividad en el cliente algo
mayor que dos latidos.

🗣️ **2 minutos** — El latido evita que proxies e intermediarios corten la conexión por ociosa, y
permite al cliente detectar que el servidor murió sin avisar —en TCP, una conexión muerta puede
parecer viva mucho tiempo—. El timeout del cliente debe tolerar la pérdida de un latido para no
reconectar por una anomalía puntual.

🔬 **El detalle** — En SSE basta con enviar una línea de comentario como latido, que el cliente ignora.
En WebSocket hay marcos específicos para esto, y conviene usarlos en vez de mensajes propios, porque
las capas intermedias los entienden y algunos clientes los responden automáticamente.

**05 → 14. ¿Cuánto cuesta una conexión ociosa en cada plataforma, y por qué eso decide el diseño? 🟡**

⏱️ **30 segundos** — En Node y Go una conexión ociosa cuesta casi nada; en Java depende del modelo
—con hilo por conexión, un hilo— y en Python del modelo de despliegue por procesos.

🗣️ **2 minutos** — Ese coste decide si mil conexiones son un detalle o un problema. Node es el terreno
natural por memoria por conexión y por librerías con reconexión y salas; en Go, una goroutine por
conexión es idiomático y barato; en Java conviene el modelo reactivo si hay muchas conexiones
ociosas; en Python, el marco ASGI lo soporta, con el matiz de que el estado se multiplica por proceso
trabajador.

🔬 **El detalle** — En Node y Python hay un riesgo añadido: como el bucle es uno solo, cualquier
bloqueo congela **a todos los conectados a la vez**, no solo a la petición que bloquea. Con miles de
conexiones, eso puede desencadenar además una oleada de reconexiones.

---
**05 → 15. Tienes 200 usuarios y una latencia tolerable de 10 s. ¿Qué eliges y cómo lo defiendes? 🟠**

⏱️ **30 segundos** — Polling cada cinco o diez segundos. Son 20 a 40 consultas por segundo, que no es
nada, y me ahorro todo el estado.

🗣️ **2 minutos** — La defensa es la cuenta: 200 usuarios cada 10 s son 20 consultas por segundo, casi
todas respondidas con un `304` si uso `ETag`. A cambio, el servicio sigue sin estado, escala y se
despliega sin pensar, y no hay reconexión, backplane ni protocolo que mantener. Si el número de
usuarios crece un orden de magnitud o la latencia tolerable baja de un segundo, se revisa.

🔬 **El detalle** — Conviene decir explícitamente el umbral que dispararía el cambio. Una respuesta
que dice "polling, y pasaría a SSE si superamos unos miles de clientes o si nos piden menos de un
segundo" demuestra criterio; una que solo dice "polling" parece conformismo.

**05 → 16. El equipo propone WebSocket para mostrar el estado del pedido. Argumenta. 🟠**

⏱️ **30 segundos** — Si solo se empuja del servidor al cliente, SSE da lo mismo con reconexión y
reanudación incluidas y sin inventar protocolo.

🗣️ **2 minutos** — Con WebSocket hay que definir tipos de mensaje, versionado, errores, latidos y
reconexión; con SSE, nada de eso. Además SSE atraviesa proxies sin configuración especial y se
autentica igual que el resto. Si en el futuro hiciera falta un canal de vuelta —el usuario interactúa
en vivo—, entonces sí se justifica cambiar, y esa conversación se tiene con el caso concreto delante.

🔬 **El detalle** — Hay un argumento a favor de WebSocket que conviene reconocer: si el equipo ya
tiene una infraestructura de WebSocket montada y operada para otra cosa, reutilizarla puede salir más
barato que introducir un segundo mecanismo. La decisión también tiene componente de operación, no
solo de protocolo.

**05 → 17. Un evento nace en `payments` y hay que empujarlo al navegador, que está conectado a `orders`. Diseña el camino. 🟠**

⏱️ **30 segundos** — `payments` publica el evento, `orders` lo consume, y la instancia que tiene la
conexión del usuario se lo empuja por SSE.

🗣️ **2 minutos** — El camino:

```text
payments ──PaymentAuthorized──► topic ──► todas las instancias de orders
                                  └─► la que tiene la conexión del usuario, empuja
```

Cada instancia se suscribe y filtra por los usuarios que tiene conectados —eso es el backplane—. Si
el número de instancias crece, se pasa de difusión a enrutado por usuario, para no mandar cada evento
a todas.

🔬 **El detalle** — Hay que decidir qué pasa si el usuario no está conectado en ese momento: o se
descarta —y al reconectar consulta el estado actual por HTTP—, o se guarda para entregarlo luego. La
primera opción es mucho más simple y casi siempre suficiente, porque el estado real siempre se puede
consultar.

**05 → 18. ¿Cómo evitas que un despliegue corte todas las conexiones a la vez? 🟠**

⏱️ **30 segundos** — Reemplazo gradual con margen entre instancias, apagado ordenado que avisa, y
reconexión con espera aleatoria en el cliente.

🗣️ **2 minutos** — El reemplazo gradual reparte los cortes en el tiempo; el apagado ordenado permite
enviar un mensaje de cierre para que el cliente reconecte a propósito en vez de detectar una caída; y
el jitter en el cliente evita que todos vuelvan en el mismo instante. Con SSE, además, la reanudación
hace que el usuario no perciba el corte.

🔬 **El detalle** — Un detalle operativo que se olvida: el plazo de gracia del apagado tiene que ser
suficiente para que los clientes reconecten en otra instancia, pero si es muy largo el despliegue se
eterniza con conexiones que no terminan nunca. Con conexiones persistentes, "esperar a que terminen"
no es una opción: hay que cerrarlas activamente.

**05 → 19. Recibes webhooks de una pasarela de pago. Diseña el endpoint, paso a paso. 🟠**

⏱️ **30 segundos** — Verificar firma, deduplicar por identificador de evento, encolar, responder 200,
y procesar aparte.

🗣️ **2 minutos** — La secuencia:

```text
1. Verificar la firma con el secreto compartido. Si falla → 401, sin más pistas.
2. Deduplicar por el identificador del evento (tabla con retención).
3. Guardar el evento crudo y encolar el procesamiento.
4. Responder 200 rápido: procesar dentro de la petición provoca reintentos por timeout.
5. Procesar de forma idempotente; los fallos van a DLQ con alerta.
```

Y una decisión explícita sobre el desorden: los eventos pueden llegar fuera de orden, así que el
procesamiento debe basarse en el estado que trae el evento y no asumir la secuencia.

🔬 **El detalle** — Conviene guardar el cuerpo crudo antes de interpretarlo: cuando aparezca una
discrepancia con la pasarela, tener el mensaje original es lo único que permite resolver la discusión.
Y ayuda a reprocesar si un fallo de interpretación afectó a muchos eventos.

**05 → 20. ¿Cuándo montarías una capa de conexiones aparte en vez de mantenerlas en el servicio? 🟠**

⏱️ **30 segundos** — Cuando hay muchas conexiones y el servicio de negocio necesita desplegar a
menudo, o cuando varios servicios tienen que empujar al mismo usuario.

🗣️ **2 minutos** — Separar permite desplegar la lógica de negocio sin cortar conexiones y dimensionar
cada parte por su recurso limitante: la capa de conexiones por memoria y descriptores, los servicios
por CPU. A cambio es un servicio más que operar, con su propio backplane, y una frontera más en el
diagnóstico.

🔬 **El detalle** — El umbral práctico no es un número de conexiones sino una frecuencia: si el
servicio de negocio se despliega varias veces al día y cada despliegue produce un pico de
reconexiones visible, separar deja de ser una preferencia arquitectónica y pasa a ser la solución de
un problema medido.

**05 → 21. Funciona en local y en producción no llega nada por SSE. Da tres hipótesis ordenadas. 🟠**

⏱️ **30 segundos** — Un proxy que almacena la respuesta, falta de `Flush` en el servidor, o
compresión intermedia que espera a tener suficiente contenido.

🗣️ **2 minutos** — En orden: el intermediario que almacena la respuesta es la causa más frecuente y se
arregla con `Cache-Control: no-cache` y desactivando el búfer en el proxy; la falta de entrega
explícita hace que el contenido se acumule en el búfer del servidor; y la compresión puede retener
datos hasta juntar un bloque. Todas se diagnostican igual: mirando si los bytes salen del servidor y
si llegan al cliente.

🔬 **El detalle** — Hay una cuarta menos habitual: algún balanceador con timeout de respuesta corto
corta la conexión a los 30 o 60 segundos porque considera que el servidor tarda demasiado en
responder. El síntoma es característico —funciona un rato y se corta siempre al mismo tiempo— y se
arregla en la configuración del balanceador.

**05 → 22. Diseña el seguimiento en vivo del estado de un pedido para web y móvil, con reconexión, autenticación y escalado, y di qué mecanismo usas en cada tramo. 🟠**

⏱️ **30 segundos** — SSE para la web, notificaciones push para móvil, eventos por dentro, y consulta
HTTP del estado actual al conectar.

🗣️ **2 minutos** — El diseño:

```text
Tramo                   Mecanismo              Por qué
──────────────────────  ─────────────────────  ─────────────────────────────────
servicios → servicios   eventos en topic       ya resuelven orden, reintentos y DLQ
servidor → web          SSE                    reconexión y reanudación de serie
servidor → móvil        push del sistema       la app puede estar cerrada; la conexión
                                               persistente no sirve en segundo plano
al (re)conectar         GET del estado actual  la verdad siempre se puede consultar:
                                               evita guardar eventos por usuario
autenticación           token en la petición   al caducar, se corta y se reconecta
escalado                backplane por topic    cada instancia filtra por sus conectados
```

🔬 **El detalle** — La decisión que más simplifica es la tercera fila del medio: consultar el estado
al conectar. Con ella, perder eventos durante un corte deja de importar, y eso elimina la necesidad de
almacenar historial por usuario, que es la parte que más suele complicar estos diseños.

**05 → 23. Escribe el protocolo de mensajes de un WebSocket de chat: tipos, versionado, errores y confirmaciones. 🔴**

⏱️ **30 segundos** — Un sobre común con tipo, versión e identificador; tipos de mensaje explícitos;
confirmación por identificador; y errores con código estable.

🗣️ **2 minutos** — El protocolo:

```text
Sobre    {v: 1, type: "...", id: "uuid", ts: "...", data: {...}}
Tipos    cliente → servidor: send, read, typing, heartbeat
         servidor → cliente: message, ack, error, presence
Confirm. el servidor responde {type:"ack", ref:"<id del cliente>", status:"ok"}
         el cliente reintenta con el MISMO id si no llega: así se deduplica
Errores  {type:"error", ref:"<id>", code:"ROOM_NOT_FOUND", message:"..."}
Versión  el campo v permite convivencia; el servidor soporta N y N-1
Cierre   el servidor manda {tipo:"cierre", motivo:"despliegue"} antes de cerrar
```

🔬 **El detalle** — Las dos piezas que casi siempre faltan en los protocolos improvisados son el
identificador generado por el cliente —sin él no hay deduplicación posible al reintentar— y el
mensaje de cierre con motivo, que es lo que permite al cliente distinguir un despliegue de una caída
y reaccionar distinto.

**05 → 24. Tu servicio mantiene 50 000 conexiones y hay que desplegar dos veces al día sin que el usuario lo note. Diseña la solución completa. 🔴**

⏱️ **30 segundos** — Capa de conexiones separada del negocio, reemplazo gradual, cierre avisado y
reconexión con espera aleatoria y reanudación.

🗣️ **2 minutos** — El diseño:

```text
1. Separar: una capa de conexiones que solo mantiene sesiones y empuja;
   el negocio despliega sin tocarla (dos despliegues diarios → cero cortes).
2. Backplane por topic: cualquier servicio publica, la capa enruta al usuario.
3. Cuando SÍ hay que desplegar la capa: reemplazo gradual, con margen suficiente
   entre instancias para absorber la reconexión de cada tanda.
4. Cierre avisado antes de cortar, para que el cliente reconecte a propósito.
5. Cliente: espera aleatoria (100 ms – 2 s) y reanudación por último id.
6. Dimensionado por memoria y descriptores, no por CPU.
```

🔬 **El detalle** — El número que hay que calcular antes es el pico de reconexión tolerable: si la
capa aguanta 5 000 reconexiones por segundo y hay 50 000 conexiones, el reemplazo completo no puede
durar menos de unos diez segundos, y conviene repartirlo en varias tandas con margen. Sin esa cuenta,
el despliegue gradual sigue produciendo un pico que tumba lo que queda vivo.

**05 → 25. Diseña la recepción de webhooks de tres proveedores distintos con un solo mecanismo interno, incluyendo firma, deduplicación y reproceso. 🔴**

⏱️ **30 segundos** — Un adaptador por proveedor que verifica y normaliza, y un único flujo interno de
eventos normalizados con deduplicación y DLQ.

🗣️ **2 minutos** — El diseño:

```text
proveedor A ─┐   adaptador A (firma propia, formato propio)
proveedor B ─┼─► adaptador B  ──► evento normalizado ──► topic interno ──► consumidores
proveedor C ─┘   adaptador C                             {origen, id_externo, tipo, datos, recibido_en}

Deduplicación  por (origen, id_externo), con retención declarada
Almacén crudo  el cuerpo original se guarda antes de normalizar
Reproceso      se relee del almacén crudo y se reinyecta al topic
DLQ            por adaptador, con alerta y con el motivo del fallo
```

Lo importante es que la firma y el formato son responsabilidad del adaptador, y que el resto del
sistema solo conoce el evento normalizado: añadir un cuarto proveedor es escribir un adaptador, no
tocar consumidores.

🔬 **El detalle** — La clave de deduplicación debe incluir el origen: dos proveedores pueden usar el
mismo identificador y, si no se distingue, se descartan eventos legítimos. Es un error que aparece
tarde, cuando se añade el tercer proveedor, y que resulta muy difícil de diagnosticar porque el
síntoma es "faltan eventos".

---

# 06 — Mensajería y eventos

**06 → 1. ¿Qué diferencia hay entre una cola y un topic? 🟢**

⏱️ **30 segundos** — La cola tiene un destinatario lógico y el mensaje se reparte entre sus
consumidores; el topic entrega a varios consumidores independientes, cada uno con su propio avance.

🗣️ **2 minutos** — Por eso la cola encaja con los comandos —hay alguien que debe actuar, y si nadie
consume, la acumulación es visible— y el topic con los eventos —añadir un consumidor nuevo no toca al
emisor—. La elección no es de tecnología: describe si hay destinatario o no.

🔬 **El detalle** — En un log distribuido, la "cola" se consigue con un grupo de consumidores sobre el
mismo topic: cada partición la lee uno solo. Es la misma idea con otro vocabulario, y conviene
traducirlo cuando se habla con gente de otro ecosistema.

**06 → 2. ¿Qué garantía de entrega ofrece un broker en la práctica? 🟢**

⏱️ **30 segundos** — Al-menos-una-vez. Habrá duplicados, y son un hecho de diseño, no un fallo.

🗣️ **2 minutos** — El exactly-once de extremo a extremo no existe porque el efecto del consumidor
vive en otro sistema: entre aplicar el efecto y confirmar el mensaje siempre hay una ventana. Lo que
sí se construye es al-menos-una-vez más un consumidor idempotente, que es funcionalmente equivalente.

🔬 **El detalle** — Algunas plataformas ofrecen exactly-once dentro de sus fronteras —leer, procesar y
escribir en el mismo sistema, transaccionalmente—. Es real y útil, pero la garantía termina donde
termina su transacción, y eso hay que preguntarlo siempre.

**06 → 3. ¿Qué es un consumidor idempotente y cuáles son sus tres formas? 🟢**

⏱️ **30 segundos** — El que procesar dos veces el mismo mensaje deja el mismo resultado. Se consigue
con operaciones naturalmente idempotentes, con clave única, o con tabla de mensajes procesados.

🗣️ **2 minutos** — La primera forma es la más barata: expresar el efecto como estado final —"poner a
`PAID`"— en vez de como incremento. La segunda usa la base de datos: insertar con una clave que
rechaza el duplicado. La tercera, el inbox, es el caso general y funciona siempre, a costa de una
tabla y su retención.

🔬 **El detalle** — La regla que hace que funcione: marca y efecto en la misma transacción. Si se
registran por separado, queda una ventana donde el efecto se aplicó y la marca no, y el reintento
duplica exactamente lo que se quería evitar.

**06 → 4. ¿Qué es la DLQ y qué le falta si no tiene alerta? 🟢**

⏱️ **30 segundos** — Es donde acaban los mensajes que agotaron sus reintentos. Sin alerta, es un
agujero negro: el efecto no ocurrió y nadie se entera.

🗣️ **2 minutos** — Su función es que un mensaje problemático deje de bloquear al resto, no que
desaparezca el problema. Por eso hace falta alerta, un panel con el contenido y un procedimiento de
reproceso escrito antes de necesitarlo.

🔬 **El detalle** — Conviene guardar en la DLQ el motivo del fallo junto al mensaje. Sin esa causa,
reprocesar es a ciegas: no sabes si el problema era transitorio —y basta reinyectar— o de contenido
—y volverá a fallar igual—.

**06 → 5. ¿Qué es el lag de un consumidor y en qué se traduce para el usuario? 🟢**

⏱️ **30 segundos** — Cuántos mensajes publicados quedan sin procesar. Dividido por el ritmo de
consumo, son segundos de retraso que el usuario percibe.

🗣️ **2 minutos** — Un lag de 50 000 mensajes con 500 por segundo son cien segundos de retraso: cien
segundos con el pedido "en proceso". Por eso el lag es una métrica de producto y no solo de
infraestructura, y por eso se alerta sobre él en unidades de tiempo, no de mensajes.

🔬 **El detalle** — La forma del lag dice la causa: crecimiento lineal es falta de capacidad; picos
que se drenan son tráfico irregular y están bien; lag en una sola partición es clave desequilibrada;
y lag que no baja con capacidad libre es un consumidor atascado en un mensaje.

**06 → 6. ¿Qué es un mensaje envenenado? 🟢**

⏱️ **30 segundos** — Uno que falla siempre por su contenido, así que se reintenta indefinidamente.

🗣️ **2 minutos** — En una cola ordenada, bloquea todo lo que viene detrás; en un consumidor con
reintentos, consume capacidad para nada. La defensa es limitar los intentos y mandarlo a la DLQ, que
es exactamente para lo que existe.

🔬 **El detalle** — Casi siempre viene de un dato que rompe una invariante o de un cambio de contrato
mal hecho. Cuando aparecen varios envenenados a la vez, la causa suele ser un despliegue, no un dato:
conviene mirar primero qué se desplegó y después el contenido.

**06 → 7. ¿Por qué un duplicado no debe registrarse como error? 🟢**

⏱️ **30 segundos** — Porque es el comportamiento esperado del sistema, no una anomalía: registrarlo
como error llena el log de ruido y esconde los fallos reales.

🗣️ **2 minutos** — Con al-menos-una-vez, los duplicados ocurren por diseño: tras un reinicio, un
reequilibrio de consumidores o una confirmación perdida. El consumidor idempotente los descarta en
silencio. Lo que sí conviene es una métrica de duplicados descartados, porque un crecimiento súbito
indica otra cosa —un consumidor atascado, un reequilibrio constante—.

🔬 **El detalle** — Esa métrica es además la comprobación de que la idempotencia funciona: si nunca
descarta nada, o el sistema no tiene duplicados —improbable— o el mecanismo no está haciendo lo que
crees.

**06 → 8. ¿Por qué el orden solo se garantiza dentro de la partición? 🟡**

⏱️ **30 segundos** — Porque las particiones se procesan en paralelo e independientemente: no hay reloj
común entre ellas.

🗣️ **2 minutos** — Garantizar orden total obligaría a una sola partición y un solo consumidor, y con
eso se pierde el paralelismo, que es lo que hace escalable el modelo. Por eso se elige una clave de
particionado —el identificador del pedido, por ejemplo— para que lo que sí necesita orden viaje
junto.

🔬 **El detalle** — El coste de esa decisión es el desequilibrio: si un cliente genera el 30 % de los
eventos y la clave es el cliente, esa partición se convierte en el cuello de botella. Elegir la clave
es equilibrar orden contra reparto, y conviene decirlo así.

**06 → 9. ¿Por qué la marca de procesado y el efecto tienen que ir en la misma transacción? 🟡**

⏱️ **30 segundos** — Porque si no, existe una ventana donde uno ocurrió y el otro no, y el reintento
duplica o se salta el efecto.

🗣️ **2 minutos** — Si se marca antes y falla el efecto, el mensaje se considera procesado y el efecto
nunca ocurre. Si se marca después y el proceso muere en medio, el reintento aplica el efecto dos
veces. Con ambas en la misma transacción, o pasan las dos o ninguna, y el reintento es seguro.

🔬 **El detalle** — Cuando el efecto no es transaccional —una llamada a un tercero—, esto no se puede
conseguir dentro de una transacción. Ahí la salida es que el tercero acepte una clave de idempotencia,
o registrar la intención antes y conciliar después. No hay una tercera opción limpia.

**06 → 10. ¿Qué pasa si se confirma el mensaje antes de aplicar el efecto? ¿Y después? 🟡**

⏱️ **30 segundos** — Antes: si el proceso muere, se pierde el mensaje y nadie se entera. Después: si
muere, llega duplicado, y eso lo cubre la idempotencia.

🗣️ **2 minutos** — Confirmar antes es "como mucho una vez": el fallo es silencioso y produce datos que
faltan sin ninguna señal. Confirmar después es "al menos una vez": el fallo es ruidoso —duplicados— y
se resuelve con el consumidor idempotente. Por eso se confirma después, siempre.

🔬 **El detalle** — El detalle que hay que conocer de tu plataforma es cuál de las dos hace por
defecto tu marco de trabajo. Varios confirman automáticamente al recibir o por intervalos, y eso
cambia la garantía sin que nadie lo decida explícitamente.

**06 → 11. ¿Por qué publicar un evento por cada cambio de estado de la entidad es mala idea? 🟡**

⏱️ **30 segundos** — Porque publica tu modelo interno: los consumidores se acoplan a tus tablas y
cualquier refactor rompe a gente que no conoces.

🗣️ **2 minutos** — Un evento debe ser un hecho de negocio —`OrderPlaced`, `PaymentRejected`—, no
un `UPDATE` disfrazado. Los eventos que son volcados de fila producen consumidores que replican tu
esquema, dependen de campos internos y obligan a coordinar despliegues que se suponía que estaban
desacoplados.

🔬 **El detalle** — Hay una excepción declarada: la captura de cambios para replicar datos a un
almacén analítico o a una proyección propia. Ahí el "evento de fila" es una decisión consciente de
integración de datos, y por eso debe consumirse dentro de la frontera del dueño, no publicarse como
contrato.

**06 → 12. Diferencia entre reintento inmediato y cola de reintento con espera. 🟡**

⏱️ **30 segundos** — El inmediato sirve para fallos transitorios de milisegundos; la cola con espera
evita el bucle rápido cuando el problema dura.

🗣️ **2 minutos** — Un timeout puntual o una conexión perdida se resuelven reintentando al momento. Si
la base de datos está caída, reintentar cada milisegundo consume capacidad y no ayuda; ahí el mensaje
va a una cola de reintento con espera creciente, y después a la DLQ. Es el mismo razonamiento del
backoff en llamadas síncronas.

🔬 **El detalle** — El número de reintentos inmediatos debe ser pequeño —uno o dos—, porque cada uno
retiene al consumidor. Con muchos consumidores y reintentos largos en línea, el flujo entero se para
por un problema que afecta a una fracción de los mensajes.

**06 → 13. ¿Qué te da cada plataforma para consumir mensajes, y qué te deja a ti en las cuatro? 🟡**

⏱️ **30 segundos** — Java trae escucha declarativa con reintentos y DLQ configurables; Python, colas
de tareas veteranas; Node/TS y Go, clientes maduros y componentes de enrutado, con más cableado.

🗣️ **2 minutos** — En Java el marco gestiona el contenedor de escucha, la concurrencia y la
confirmación, y te deja la idempotencia. En Python las colas de tareas resuelven reintentos,
planificación y resultados desde hace más de una década. En Node/TS hay clientes sólidos de los
brokers y colas sobre Redis muy usadas para trabajo en segundo plano. En Go hay componentes de
enrutado con reintentos y DLQ, y el resto se ve explícito. En las cuatro, lo que te queda es lo mismo:
consumidor idempotente, apagado ordenado y observabilidad del flujo.

🔬 **El detalle** — La diferencia que más importa no es cuánta librería hay, sino cuánto esconde:
cuanto más declarativo es el consumo, más fácil es no saber **cuándo confirma** tu marco, que es lo
que decide si pierdes o duplicas mensajes.

---
**06 → 14. El lag crece en una sola partición. Diagnostica y propón dos soluciones. 🟠**

⏱️ **30 segundos** — Clave de particionado desequilibrada: una clave concentra demasiados mensajes.
Soluciones: cambiar la clave, o repartir esa clave caliente.

🗣️ **2 minutos** — El diagnóstico se confirma mirando la distribución de claves de esa partición: casi
siempre hay un cliente o un producto que genera una fracción enorme del tráfico. La primera solución
es elegir una clave con mejor reparto, si el orden que garantizaba no era necesario. La segunda es
repartir la clave caliente en subclaves —añadiendo un sufijo— y aceptar que dentro de ese cliente ya
no hay orden total.

🔬 **El detalle** — Cambiar la clave de particionado no es inocuo: durante la transición conviven
mensajes con criterios distintos y el orden por clave se rompe temporalmente. Conviene hacerlo con
una ventana donde el consumidor tolere el desorden, o crear un topic nuevo y migrar consumidores.

**06 → 15. ¿Cómo eliges la clave de particionado de `orders.placed`? 🟠**

⏱️ **30 segundos** — El identificador del pedido: garantiza orden de los eventos de un mismo pedido y
reparte bien, porque hay muchos pedidos.

🗣️ **2 minutos** — La pregunta que resuelve la elección es: ¿qué cosas tienen que llegar en orden
entre sí? Los eventos de un pedido, sí; los de pedidos distintos, no. Usar el cliente daría orden por
cliente —que casi nunca hace falta— y crearía puntos calientes con clientes grandes. Usar algo
aleatorio daría reparto perfecto y ningún orden.

🔬 **El detalle** — Hay un caso donde conviene el cliente: si el consumidor aplica reglas que dependen
del conjunto de pedidos de ese cliente —límites de crédito, por ejemplo—, procesar en orden por
cliente simplifica mucho. Es un ejemplo de que la clave se elige por el consumidor, no por el emisor.

**06 → 16. Diseña el procedimiento de reproceso desde la DLQ, incluyendo cómo evitas duplicar efectos. 🟠**

⏱️ **30 segundos** — Revisar la causa, corregir si aplica, reinyectar al topic original conservando el
identificador, y confiar en la idempotencia del consumidor.

🗣️ **2 minutos** — El procedimiento:

```text
1. Panel de DLQ: mensaje, motivo del fallo, cuándo y cuántos.
2. Clasificar: transitorio (reinyectar tal cual) o de contenido (corregir o descartar).
3. Reinyectar conservando el identificador original → la idempotencia evita duplicados
   si el efecto ya se había aplicado parcialmente.
4. Registrar la reinyección: quién, cuándo, cuántos mensajes.
5. Verificar: lag del consumidor y efectos esperados.
```

🔬 **El detalle** — El paso que se salta siempre es el cinco. Reinyectar y no comprobar deja casos en
los que el mensaje vuelve a fallar y regresa a la DLQ sin que nadie lo note, con lo que el incidente
parece resuelto y no lo está.

**06 → 17. `orders` quiere que `inventory` reserve. ¿Comando o evento? Justifica y di qué cambia dentro de `inventory`. 🟠**

⏱️ **30 segundos** — Evento `OrderPlaced`, salvo que estemos en una saga orquestada; entonces,
comando `ReserveInventory`.

🗣️ **2 minutos** — Con evento, `orders` publica un hecho y `inventory` decide que eso implica
reservar: esa regla vive en `inventory`, que es su dueño, y mañana puede cambiar —reservar solo para
ciertos clientes— sin tocar `orders`. Con comando, `orders` decide por `inventory`, lo que solo se
justifica si hay un coordinador explícito que dirige el flujo.

🔬 **El detalle** — Lo que cambia dentro de `inventory` es dónde vive la traducción: con evento
necesita un manejador que interprete `OrderPlaced` y decida la acción; con comando, ejecuta lo
que le dicen. La primera opción produce un servicio con criterio propio, que es lo que se busca.

**06 → 18. Un consumidor tiene que llamar a un tercero no idempotente. ¿Cómo lo haces seguro? 🟠**

⏱️ **30 segundos** — Registrando la intención antes de llamar, usando una clave de idempotencia si el
tercero la acepta, y conciliando después si no.

🗣️ **2 minutos** — El patrón: se guarda en la base "voy a llamar con esta referencia", se llama, y se
guarda el resultado. Si el proceso muere entre medias, al reintentar se ve que hay una llamada en
estado desconocido y se consulta al tercero por esa referencia antes de repetir. Si el tercero no
permite consultar ni acepta clave de idempotencia, no hay solución limpia: hay que elegir entre
arriesgar duplicado o arriesgar omisión, y decidirlo con el negocio.

🔬 **El detalle** — En pagos, la elección casi siempre es preferir la omisión y conciliar: es más
barato detectar un cobro que falta que devolver uno duplicado. Esa decisión es de negocio, y
plantearla así en una entrevista demuestra que se entiende el contexto.

**06 → 19. ¿Qué métricas y alertas pones en un flujo asíncrono para enterarte antes que el cliente? 🟠**

⏱️ **30 segundos** — Lag en segundos, mensajes en DLQ, tasa de error del consumidor y edad del mensaje
más antiguo sin procesar.

🗣️ **2 minutos** — El lag en tiempo es la métrica de producto. La edad del más antiguo detecta
consumidores atascados aunque el lag global sea bajo. La DLQ con cualquier mensaje debería generar
alerta inmediata. Y conviene una métrica de extremo a extremo —tiempo entre publicar el evento y
aplicar el efecto—, que es lo que el usuario percibe.

🔬 **El detalle** — La alerta más útil y menos habitual es la de **ausencia**: si un flujo procesa
normalmente mil mensajes por hora y lleva una hora a cero, algo se rompió aunque no haya errores. Los
fallos silenciosos solo se detectan vigilando lo que debería estar pasando.

**06 → 20. Te dicen "usamos exactly-once". ¿Qué preguntas? 🟠**

⏱️ **30 segundos** — Dónde termina esa garantía: ¿incluye el efecto en la base de datos y las
llamadas a terceros, o solo el tránsito dentro del broker?

🗣️ **2 minutos** — Si el flujo es leer de un topic, transformar y escribir en otro topic del mismo
sistema, la garantía transaccional del propio broker puede ser real. En cuanto el consumidor escribe
en una base de datos externa o llama a un tercero, hay dos sistemas y una ventana, y vuelves a
al-menos-una-vez. La pregunta siguiente es si el consumidor es idempotente igualmente.

🔬 **El detalle** — Conviene no plantearlo como un "te pillé": a veces la respuesta es correcta y el
flujo sí está dentro de esas fronteras. Preguntar dónde termina la garantía es una pregunta técnica
legítima, y la reacción a esa pregunta dice mucho del nivel del equipo.

**06 → 21. ¿Cómo depuras "el pedido se confirmó pero no se reservó" en un flujo asíncrono? 🟠**

⏱️ **30 segundos** — Cuatro preguntas en orden: ¿se publicó el evento? ¿está en el topic? ¿cuál es el
lag? ¿hay algo en la DLQ con ese identificador?

🗣️ **2 minutos** — Si no se publicó, el problema está en el emisor y casi siempre es la doble
escritura sin outbox. Si está publicado y el lag es alto, es capacidad. Si el lag es bajo y no está en
la DLQ, hay que mirar si el consumidor lo descartó por idempotencia —creyendo que ya estaba
aplicado— o si lo filtró por alguna regla.

🔬 **El detalle** — El caso más difícil es el cuarto: descartado por idempotencia por una marca escrita
en un intento anterior que falló después. Se detecta comparando la tabla de procesados con los efectos
reales, y es el argumento más fuerte para que marca y efecto vayan en la misma transacción.

**06 → 22. ¿Qué configuración de tu plataforma decide si pierdes o duplicas mensajes? 🟠**

⏱️ **30 segundos** — El momento de la confirmación: si tu marco confirma al recibir, pierdes mensajes;
si confirma tras el commit, los duplicas —y eso lo cubre la idempotencia—.

🗣️ **2 minutos** — Varias librerías confirman automáticamente al entregar el mensaje o por intervalos,
y eso cambia la garantía sin que nadie lo decida: un fallo entre la entrega y el efecto deja el
mensaje confirmado y el trabajo sin hacer, sin ningún error visible. La configuración correcta es
confirmación manual después del commit, aceptando duplicados. Conviene saber de memoria cuál es el
valor por defecto de tu plataforma, porque rara vez es el que quieres.

🔬 **El detalle** — El mismo razonamiento aplica al apagado: si el proceso muere con un mensaje
entregado y no confirmado, se reentrega. Por eso el consumidor idempotente no es opcional en ninguna
de las cuatro plataformas, por muy bien configurada que esté la confirmación.

---
**06 → 23. Diseña el contrato del evento `OrderPlaced`: campos, versionado, clave de particionado y qué NO va dentro. 🔴**

⏱️ **30 segundos** — Identidad del hecho, momento, datos del pedido necesarios para reaccionar,
versión de esquema; particionado por pedido; y nada de modelo interno.

🗣️ **2 minutos** — El contrato:

```text
{
  "id_evento": "uuid",              identidad del mensaje: base de la deduplicación
  "tipo": "OrderPlaced",
  "version": 1,                     evolución explícita del esquema
  "ocurrido_en": "2026-09-17T10:00:00Z",   cuándo pasó el hecho, no cuándo se publicó
  "order_id": "ORD-00042",          clave de particionado
  "customer_id": "CUS-00007",
  "lineas": [{"product_id":"SKU-017","cantidad":2}],
  "total": {"importe":"149.90","moneda":"EUR"}
}

NO va dentro: identificadores internos de fila, estados internos del agregado,
              campos "por si acaso", ni nada que no sea parte del hecho.
```

🔬 **El detalle** — La decisión discutible es cuántos datos incluir. Un evento delgado —solo
identificadores— obliga a cada consumidor a llamar de vuelta, reintroduciendo acoplamiento síncrono;
uno gordo duplica datos que pueden quedar obsoletos. La regla práctica: incluir lo que describe el
hecho en el momento en que ocurrió, que además es información que no caduca.

**06 → 24. Diseña el consumidor de `inventory` completo: consumo, idempotencia, reintentos, DLQ, observabilidad y apagado ordenado. 🔴**

⏱️ **30 segundos** — Consumo con confirmación tras el commit, inbox en la misma transacción,
reintentos escalonados, DLQ con alerta, métricas de lag y duplicados, y cierre que confirma lo que
está en curso.

🗣️ **2 minutos** — El diseño:

```text
Consumo       lote pequeño; confirmación DESPUÉS del commit
Idempotencia  tabla procesados(id_evento) + efecto, misma transacción; duplicado → salir en silencio
Reintentos    1 inmediato para transitorios → cola de reintento (5 s, 30 s, 5 min) → DLQ
DLQ           con motivo del fallo; alerta a partir del primer mensaje
Observabilidad lag en segundos, edad del más antiguo, duplicados descartados,
              tiempo de extremo a extremo (ocurrido_en → efecto aplicado)
Apagado       dejar de pedir mensajes → terminar el actual → confirmar → cerrar recursos
Trazas        extraer el contexto de los encabezados del mensaje para enlazar con el emisor
```

🔬 **El detalle** — La pieza que más se olvida es la última: sin extraer el contexto de traza del
mensaje, la traza se corta en la publicación y el consumo aparece como una operación huérfana. Es el
agujero más común de la observabilidad en flujos asíncronos.

**06 → 25. Diagnostica: el lag es cero, no hay nada en la DLQ, y aun así faltan reservas de algunos pedidos. Da tres hipótesis ordenadas. 🔴**

⏱️ **30 segundos** — El evento nunca se publicó; el consumidor lo descartó por idempotencia; o lo
filtró una regla de negocio silenciosa.

🗣️ **2 minutos** — Las tres, con cómo se distinguen:

```text
1. Nunca se publicó      doble escritura sin outbox: el pedido se guardó y la publicación
                         falló. Se comprueba buscando el id del pedido en el topic
2. Descartado por        una marca de procesado escrita en un intento anterior que luego
   idempotencia          falló. Se detecta comparando procesados con efectos reales
3. Filtrado en silencio  una condición del consumidor lo ignoró (tipo desconocido,
                         versión no soportada, regla de negocio). Se detecta con una
                         métrica de mensajes ignorados, que casi nunca existe
```

La primera es la más probable y la que más se subestima, porque el emisor no registra ningún error.

🔬 **El detalle** — La causa 3 merece una regla de diseño: un consumidor nunca debe ignorar un mensaje
en silencio. Si no lo entiende o no le aplica, debe contarlo en una métrica y, si es un tipo
desconocido, registrarlo. Los mensajes ignorados sin rastro son la fuente de incidentes más difícil
de diagnosticar del modelo asíncrono.

**06 → 26. Un equipo propone sustituir todas las llamadas síncronas por eventos y quitar las colas de reintento "porque el broker ya reintenta". Responde. 🔴**

⏱️ **30 segundos** — Dos objeciones distintas: no todo se convierte en evento, y el reintento del
broker no sustituye a una estrategia de reintento escalonada con DLQ.

🗣️ **2 minutos** — Sobre lo primero: las consultas que el usuario espera no mejoran al volverse
asíncronas; solo trasladan la espera y añaden idempotencia, DLQ y observabilidad que hay que
construir. Sobre lo segundo: el reintento del broker suele ser inmediato o con espera fija, y con un
fallo que dura —una base de datos caída— consume capacidad sin avanzar; además, sin límite de
intentos, un mensaje envenenado se reintenta indefinidamente y bloquea el flujo.

🔬 **El detalle** — Conviene conceder lo que hay de cierto: para fallos transitorios muy breves, el
reintento del broker basta y añadir colas intermedias es complejidad. La propuesta razonable es
escalonar —inmediato para transitorios, cola con espera para lo que dura, DLQ como final— y aplicar
eso solo a los flujos donde el efecto importa, no a todos por uniformidad.

---

# 07 — Contratos y versionado

**07 → 1. Define compatibilidad hacia atrás y hacia adelante. 🟢**

⏱️ **30 segundos** — Hacia atrás: un consumidor nuevo entiende datos viejos. Hacia adelante: un
consumidor viejo tolera datos nuevos.

🗣️ **2 minutos** — En una API síncrona la crítica suele ser la de adelante, porque el servidor
despliega antes que los clientes y ellos recibirán respuestas nuevas. En eventos hacen falta las dos,
porque los mensajes quedan almacenados: un consumidor nuevo leerá eventos viejos y uno viejo recibirá
eventos nuevos.

🔬 **El detalle** — La confusión de nombres es frecuente y conviene desambiguar en la propia respuesta
diciendo quién es nuevo y quién es viejo en cada caso, en vez de fiarse del término.

**07 → 2. ¿Cuáles son los tres pasos de expand/contract aplicado a un contrato? 🟢**

⏱️ **30 segundos** — Expandir —conviven lo viejo y lo nuevo—, migrar a los consumidores, y contraer
—eliminar lo viejo— cuando nadie lo usa.

🗣️ **2 minutos** — Al renombrar `amount` a `total`, el servidor devuelve ambos y acepta ambos;
después los consumidores migran a su ritmo; y solo cuando el uso del campo viejo es cero durante un
periodo, se anuncia y se elimina. Cada paso es compatible por separado, así que ningún despliegue
tiene que coordinarse.

🔬 **El detalle** — El paso que casi nunca se hace es el tercero, por falta de datos: sin una métrica
de uso por campo o por consumidor, nadie se atreve a borrar y la API acumula campos muertos durante
años.

**07 → 3. Nombra tres cambios compatibles y tres incompatibles. 🟢**

⏱️ **30 segundos** — Compatibles: añadir un campo opcional, relajar una validación, renombrar en
protobuf. Incompatibles: eliminar un campo, cambiar un tipo, endurecer una validación.

🗣️ **2 minutos** — El criterio es qué ve el otro lado: si el consumidor viejo puede seguir
funcionando y el productor viejo puede seguir emitiendo, es compatible. Renombrar es compatible en
protobuf porque en el cable viaja el número, no el nombre; en JSON, renombrar es eliminar y añadir.

🔬 **El detalle** — Los dos casos que se escapan a la revisión de esquemas: añadir un valor a un
enumerado —rompe al consumidor sin rama por defecto— y endurecer una validación —rechaza lo que antes
aceptabas sin tocar el esquema—.

**07 → 4. ¿Qué es un lector tolerante y cuáles son sus tres reglas? 🟢**

⏱️ **30 segundos** — Un consumidor que ignora lo que no conoce: ignora campos desconocidos, lee solo
lo que necesita, y tiene rama por defecto en los enumerados.

🗣️ **2 minutos** — Es lo que permite al proveedor añadir campos sin coordinar. El error frecuente es
activar el modo estricto de deserialización "para detectar errores antes": detecta errores, sí, y los
provoca en producción cada vez que el otro añade un campo opcional perfectamente compatible.

🔬 **El detalle** — El matiz que sube la nota: tolerante con lo que ignoras, estricto con lo que
interpretas. Un importe o una fecha que sí usas se validan con dureza; un campo nuevo que no te
concierne se ignora.

**07 → 5. ¿Qué es un contrato dirigido por el consumidor y en qué pipeline falla? 🟢**

⏱️ **30 segundos** — El consumidor declara lo que espera, y el proveedor verifica esa expectativa en
**su** pipeline. Falla en el del proveedor, antes de desplegar.

🗣️ **2 minutos** — El consumidor prueba contra un simulador generado del pacto y publica ese pacto;
el proveedor los verifica todos en su construcción. Así un cambio que rompe a alguien se detecta
antes de salir, sin levantar ambos servicios y sin depender de un entorno de integración.

🔬 **El detalle** — Lo que lo hace valioso es que captura expectativas de comportamiento, no solo
formas: una validación endurecida o un valor nuevo de enumerado hacen fallar el pacto, cuando una
comparación de esquemas los daría por compatibles.

**07 → 6. ¿Qué diferencia hay entre contrato primero y código primero? 🟡**

⏱️ **30 segundos** — Con contrato primero, el esquema se escribe y el código se genera de él; con
código primero, el esquema se genera de las clases.

🗣️ **2 minutos** — La diferencia práctica es quién decide el contrato: con código primero, un refactor
interno publica un contrato nuevo sin que ninguna persona lo haya decidido. Con contrato primero, el
cambio se revisa como lo que es —un acuerdo entre equipos— y el código se adapta.

🔬 **El detalle** — Código primero es cómodo al empezar y es defendible cuando el consumidor es uno
solo y del mismo equipo. En cuanto hay dos equipos, la comodidad se paga con rupturas accidentales.

**07 → 7. ¿Por qué en eventos hacen falta las dos compatibilidades y en una API síncrona sobre todo una? 🟡**

⏱️ **30 segundos** — Porque los eventos quedan almacenados y se releen; una respuesta HTTP se consume
en el momento.

🗣️ **2 minutos** — Un consumidor nuevo puede empezar a leer desde el principio del historial y se
encontrará eventos con esquema viejo: necesita compatibilidad hacia atrás. Y un consumidor viejo que
aún no migró recibirá eventos nuevos: necesita hacia adelante. En HTTP, el cliente viejo solo ve
respuestas nuevas, así que la crítica es una.

🔬 **El detalle** — De ahí una consecuencia de diseño: en eventos conviene elegir formatos pensados
para evolucionar —con números de campo o con esquema registrado— y evitar estructuras que dependan
del orden o de la presencia de campos.

**07 → 8. ¿Por qué añadir un valor a un enumerado puede romper a un consumidor? 🟡**

⏱️ **30 segundos** — Porque si el consumidor hace una selección exhaustiva sin rama por defecto, el
valor desconocido provoca un error.

🗣️ **2 minutos** — Es el caso que más se escapa: el esquema sigue siendo compatible, la comparación
automática no detecta nada, y el consumidor falla en producción la primera vez que llega un estado
nuevo. La defensa es de ambos lados: el consumidor con rama por defecto, y el proveedor anunciando
valores nuevos con antelación.

🔬 **El detalle** — En protobuf hay un matiz: los valores desconocidos de un enumerado se conservan al
reenviar el mensaje, lo que evita perder información, pero el código que hace la selección sigue
necesitando su rama por defecto. El formato protege los datos, no la lógica.

**07 → 9. ¿Por qué endurecer una validación es un cambio incompatible aunque el esquema no cambie? 🟡**

⏱️ **30 segundos** — Porque rechazas peticiones que antes aceptabas: el contrato efectivo cambió,
aunque el documento no.

🗣️ **2 minutos** — Limitar un campo de texto a cincuenta caracteres, exigir un formato de fecha
concreto o rechazar un valor límite son rupturas para quien estaba enviando lo que ahora se rechaza.
No lo detecta ninguna comparación de esquemas, y por eso es uno de los casos que justifican los
pactos.

🔬 **El detalle** — La forma de hacerlo sin romper es la misma de siempre: aplicar la validación nueva
en modo aviso primero —registrar cuántas peticiones la incumplirían—, avisar a los afectados, y
endurecerla cuando el contador esté a cero.

**07 → 10. ¿Qué resuelve un pacto que no resuelve una prueba de integración? 🟡**

⏱️ **30 segundos** — Responde solo a "¿este cambio rompe a alguien?", sin levantar los dos servicios y
sin fallar por motivos ajenos.

🗣️ **2 minutos** — La prueba de integración necesita entorno, datos y ambos servicios vivos; es lenta
y falla por causas que no tienen que ver con el contrato, lo que acaba con gente reintentando el
pipeline sin mirar. El pacto se ejecuta en la construcción del proveedor, es rápido, y su fallo tiene
un único significado.

🔬 **El detalle** — No sustituye a todas las pruebas: no comprueba que el sistema completo funcione ni
el comportamiento de extremo a extremo. Lo que sustituye es el **entorno de integración completo como
red de seguridad del contrato**, que es la pieza más cara y menos fiable del aparato de pruebas.

**07 → 11. ¿Por qué un `interface` de TypeScript no garantiza el contrato? 🟡**

⏱️ **30 segundos** — Porque los tipos desaparecen al compilar: en ejecución no hay ninguna
comprobación.

🗣️ **2 minutos** — Si el servidor devuelve algo distinto de lo declarado, el programa sigue adelante
con datos que no encajan y el error aparece más tarde, en un sitio que no tiene relación aparente.
Hace falta validación real en el borde con un esquema que sí exista en ejecución, generado del
contrato o declarado explícitamente.

🔬 **El detalle** — Muchos equipos creen tener validación de contrato y lo que tienen es
autocompletado. La comprobación rápida: si al recibir un campo con el tipo equivocado nadie se queja,
no hay validación.

**07 → 12. ¿Por qué crear `/v2` se describe como "una derrota administrada"? 🟡**

⏱️ **30 segundos** — Porque significa mantener dos implementaciones durante meses: no es una mejora,
es el precio de un cambio que no supo hacerse compatible.

🗣️ **2 minutos** — La versión mayor es útil y a veces inevitable, sobre todo en APIs externas con
consumidores desconocidos. Pero cada una duplica el mantenimiento, las pruebas y el diagnóstico, y
casi siempre existe una alternativa con expand/contract que no obliga a nadie a migrar en bloque.

🔬 **El detalle** — El coste real se ve al retirarla: para apagar `/v1` hace falta saber quién lo usa,
avisar, esperar y, a menudo, negociar. Muchas organizaciones mantienen versiones antiguas años porque
nunca planificaron la retirada, y eso es exactamente lo que había que evitar.

**07 → 13. ¿Qué te da cada plataforma para generar y verificar contratos, y dónde se valida de verdad? 🟡**

⏱️ **30 segundos** — Java genera cliente y servidor e integra la verificación de pactos; Go genera
desde `.proto` de forma idiomática; Node/TS y Python necesitan validación explícita en el borde
porque sus tipos no comprueban nada en ejecución.

🗣️ **2 minutos** — La diferencia útil no es qué generador tiene cada una, sino **dónde se valida de
verdad**: en Node/TS los tipos desaparecen al compilar, así que hace falta un esquema que exista en
ejecución; en Python la validación declarativa cubre eso de serie y además genera el esquema; en Java
y Go, el cliente generado del contrato hace la mayor parte del trabajo.

🔬 **El detalle** — El riesgo simétrico en Python es que el modelo del código se convierta en la fuente
de verdad del contrato y se publique lo que haya, campos internos incluidos. El contrato se escribe y
el modelo se deriva de él, no al revés.

---
**07 → 14. Tienes que renombrar un campo que usan tres consumidores. Da el plan completo. 🟠**

⏱️ **30 segundos** — Expand/contract: devolver ambos, medir el uso del viejo, avisar, y eliminarlo
cuando el contador esté a cero.

🗣️ **2 minutos** — El plan:

```text
1. Publicar el campo nuevo junto al viejo; aceptar ambos en la entrada.
   Documentar el viejo como obsoleto con fecha objetivo.
2. Métrica por consumidor de quién sigue leyendo el viejo.
3. Avisar a los tres consumidores con la fecha y ofrecer ayuda.
4. Esperar a cero uso durante un periodo (dos semanas suele bastar en interno).
5. Anunciar la retirada, eliminar, y verificar que nada falla.
```

Si en el paso 4 uno de los tres no migra, la conversación es de prioridades, no técnica: la fecha se
negocia, pero el campo se retira.

🔬 **El detalle** — Si los tres consumidores son del mismo equipo y despliegan juntos, este plan es
exagerado: ahí coordinar es más barato. Reconocer esa excepción en la respuesta demuestra criterio en
lugar de aplicar el patrón por reflejo.

**07 → 15. ¿Cómo mides si alguien sigue usando un campo que quieres eliminar? 🟠**

⏱️ **30 segundos** — Instrumentando el acceso al campo, o el uso por consumidor, con una métrica
etiquetada por cliente.

🗣️ **2 minutos** — En una API con representaciones parciales o con GraphQL, se puede contar el campo
solicitado. Si no, se aproxima con la versión del cliente o con el identificador del consumidor: si
solo dos clientes usan la ruta y ambos están en la versión nueva, el campo viejo probablemente no se
lee. La aproximación hay que declararla, no venderla como certeza.

🔬 **El detalle** — Existe una alternativa más contundente y muy efectiva: la retirada progresiva —
devolver el campo vacío durante una ventana corta y anunciada, y ver quién se queja—. Es agresiva,
solo vale en interno y con aviso, y encuentra a los consumidores que ninguna métrica detectó.

**07 → 16. Un consumidor no puede desplegar hasta dentro de dos meses. ¿Qué implica para tu cambio? 🟠**

⏱️ **30 segundos** — Que el cambio tiene que ser compatible y que la fase de convivencia dura al menos
esos dos meses.

🗣️ **2 minutos** — No se le puede pedir que migre antes, así que lo viejo se mantiene. Lo que sí se
puede es publicar ya lo nuevo, migrar al resto de consumidores, y programar la retirada para después
de su despliegue. Es el caso típico de una aplicación móvil, donde además hay usuarios que no
actualizan nunca y la convivencia es indefinida.

🔬 **El detalle** — Con móvil conviene un mecanismo de versión mínima soportada: la aplicación
comprueba al arrancar si su versión sigue admitida y pide actualizar. Sin eso, el contrato queda
congelado para siempre por la versión más vieja instalada.

**07 → 17. ¿Cuándo usarías versión en la ruta y cuándo evolución del esquema? 🟠**

⏱️ **30 segundos** — Ruta para APIs externas con consumidores desconocidos; evolución del esquema para
APIs internas y para eventos.

🗣️ **2 minutos** — La versión en la ruta es explícita y la entiende cualquiera, lo que importa cuando
no sabes quién te consume. Entre servicios internos, con consumidores conocidos y pactos verificando,
mantener dos implementaciones cuesta más de lo que aporta, y la disciplina de compatibilidad es
viable.

🔬 **El detalle** — Un híbrido frecuente y razonable: versión mayor en la ruta solo para rupturas
grandes y raras —una reestructuración completa del recurso— y evolución compatible para todo lo demás.
Lo que no funciona es crear versión mayor por cada cambio, que produce `/v7` en dos años.

**07 → 18. ¿Qué haces si un pacto de un consumidor te impide un cambio que necesitas? 🟠**

⏱️ **30 segundos** — Hablar con ese consumidor: el pacto está haciendo exactamente su trabajo, que es
hacer visible la ruptura antes de producción.

🗣️ **2 minutos** — Las salidas son tres: hacer el cambio compatible —casi siempre posible con
expand/contract—; acordar con el consumidor que actualice su pacto y su código en la misma ventana; o,
si la expectativa del pacto era incorrecta, corregir el pacto. Lo que no se hace es desactivar la
verificación para poder desplegar.

🔬 **El detalle** — Si los pactos bloquean a menudo, suele indicar que los consumidores están
declarando expectativas demasiado estrictas —esperando campos que no usan, o formas exactas—. Merece
una revisión conjunta: un pacto debe declarar lo que el consumidor **necesita**, no todo lo que
recibe.

**07 → 19. Diseña la política de versionado de los eventos de tu sistema. 🟠**

⏱️ **30 segundos** — Campo de versión en el sobre, solo cambios compatibles dentro de una versión, y
topic nuevo para una ruptura real.

🗣️ **2 minutos** — La política:

```text
Sobre        todo evento lleva tipo y version
Compatible   añadir campos opcionales; nunca eliminar ni cambiar tipos
Ruptura      si es inevitable: publicar en paralelo el tipo nuevo (v2) durante
             una ventana, migrar consumidores, y retirar el v1 cuando nadie lo lea
Registro     esquemas en un registro con verificación de compatibilidad en CI
Consumidores toleran campos desconocidos y tienen rama por defecto en enumerados
```

🔬 **El detalle** — La decisión importante es publicar en paralelo en vez de transformar: intentar que
el emisor produzca las dos versiones a partir de una sola fuente termina con lógica de conversión
duplicada. Es más limpio emitir ambos durante la ventana y borrar el viejo después.

**07 → 20. ¿Quién debería ser dueño del contrato de un BFF, y por qué? 🟠**

⏱️ **30 segundos** — El equipo de la experiencia que lo consume: web, móvil o socios.

🗣️ **2 minutos** — El BFF existe para adaptar el sistema a una experiencia concreta, así que quien
conoce esa experiencia es quien debe decidir su forma. Si lo posee el equipo de plataforma, cada
cambio de pantalla entra en una cola ajena, y el BFF acaba siendo genérico —que es justo lo que no
tenía que ser—.

🔬 **El detalle** — La consecuencia organizativa es que el equipo de frontend necesita capacidad de
operar un servicio: despliegue, alertas, guardia. Si no la tiene, el BFF se degrada igualmente. Por
eso la propiedad del BFF es una decisión de equipo antes que de arquitectura.

**07 → 21. Tu equipo genera el OpenAPI desde el código. Argumenta a favor de cambiarlo. 🟠**

⏱️ **30 segundos** — Porque así el contrato lo decide un refactor, no una persona: renombrar un campo
interno publica una ruptura sin revisión.

🗣️ **2 minutos** — Con contrato primero, el cambio de contrato se revisa como cualquier otro acuerdo
entre equipos, se puede discutir antes de implementarlo, y el código de servidor y cliente se genera
de la misma fuente. Además desaparece la tentación de exponer el modelo interno tal cual, que es la
causa habitual de contratos que se parecen sospechosamente a las tablas.

🔬 **El detalle** — Conviene conceder lo que tiene de bueno el modelo actual: generar del código es
rápido y evita que el documento se desincronice del comportamiento. La propuesta realista no es
prohibirlo, sino invertir la dirección y añadir verificación de compatibilidad en CI, que es lo que
de verdad falta.

**07 → 22. Diseña el proceso completo de cambio de contrato en tu organización: quién propone, quién verifica, qué falla y dónde, y cuándo se retira lo viejo. 🔴**

⏱️ **30 segundos** — Propone el proveedor, revisan los consumidores, verifica CI con pactos y
compatibilidad, y la retirada se programa con métrica de uso.

🗣️ **2 minutos** — El proceso:

```text
1. Propuesta   el proveedor abre el cambio del contrato (no del código) con motivo
               y tipo: compatible o ruptura
2. Revisión    los consumidores conocidos revisan; para rupturas, acuerdan ventana
3. CI proveedor  verificación de compatibilidad del esquema + todos los pactos publicados
                 → un fallo aquí bloquea el despliegue del proveedor
4. Publicación   contrato versionado en el registro; clientes generados disponibles
5. Migración     consumidores actualizan a su ritmo, con métrica de uso del viejo
6. Retirada      anuncio + espera + eliminación, con fecha desde el paso 1
```

🔬 **El detalle** — El paso que sostiene todo es el tercero, y tiene un requisito organizativo: el
equipo proveedor tiene que aceptar que su pipeline falle por expectativas de otro equipo. Sin ese
acuerdo explícito, alguien acabará desactivando la verificación un viernes con prisa.

**07 → 23. Un consumidor externo lleva seis meses sin actualizar y te bloquea la retirada de `/v1`. Da tu plan técnico y la conversación. 🔴**

⏱️ **30 segundos** — Técnicamente: medir su uso, ofrecer compatibilidad puente y poner fecha firme. En
la conversación: datos, aviso escalonado y coste explícito.

🗣️ **2 minutos** — El plan:

```text
Técnico     medir su tráfico real sobre v1; comprobar qué parte del contrato usa;
            si usa poco, ofrecer un adaptador que traduzca v2→v1 solo para él,
            con fecha de caducidad
Aviso       comunicación con fecha; recordatorios; y encabezado de obsolescencia
            en las respuestas para que aparezca en sus logs
Presión     ventanas de corte programadas y anunciadas (p. ej. una hora,
            luego un día) antes de la retirada definitiva
Conversación enseñar el coste de mantener v1: qué no estamos haciendo por sostenerlo
```

🔬 **El detalle** — Las ventanas de corte anunciadas son sorprendentemente efectivas y hay que
plantearlas con cuidado: se anuncian con semanas de antelación, se hacen en horario acordado, y
sirven para que el consumidor descubra dependencias que no sabía que tenía. Sin aviso, es un
incidente; con aviso, es un simulacro.

**07 → 24. Diseña la verificación de compatibilidad en CI para un sistema con APIs REST y eventos, diciendo qué comprueba cada paso y qué no puede detectar. 🔴**

⏱️ **30 segundos** — Tres capas: comparación de esquemas, pactos de consumidor y pruebas de
compatibilidad de datos reales. Ninguna detecta cambios de significado.

🗣️ **2 minutos** — El diseño:

```text
Capa                     Detecta                            No detecta
───────────────────────  ─────────────────────────────────  ──────────────────────────
Comparación de esquemas  campos eliminados, tipos cambiados, cambios de significado,
(REST y eventos)         obligatoriedad nueva                validaciones endurecidas
Pactos de consumidor     rupturas de lo que alguien USA,     lo que ningún consumidor
                         incluidas validaciones y enums      declaró
Reproducción de datos    que el esquema nuevo lee mensajes   errores de interpretación
reales (eventos)         históricos reales                   semántica
```

Y la conclusión que conviene decir: ninguna capa detecta un cambio de **significado** —el campo
`total` que pasa de excluir a incluir impuestos—. Eso solo lo detecta una persona revisando, y por eso
el cambio de contrato se revisa aunque el pipeline esté verde.

🔬 **El detalle** — La tercera capa es la menos habitual y la más reveladora en sistemas con eventos:
tomar una muestra de mensajes reales del histórico y comprobar que el esquema nuevo los lee sin
errores. Encuentra casos que ningún esquema sintético representa, como campos nulos que en teoría
nunca lo eran.

**07 → 25. Tienes que cambiar el significado de un campo sin cambiar su nombre ni su tipo —de importe sin impuestos a importe con impuestos—. Diseña el cambio. 🔴**

⏱️ **30 segundos** — No se cambia el significado de un campo: se añade uno nuevo con nombre
inequívoco y se retira el viejo con expand/contract.

🗣️ **2 minutos** — El plan:

```text
1. Añadir total_con_impuestos y total_sin_impuestos, ambos explícitos.
   El campo antiguo `total` se mantiene con su significado ORIGINAL.
2. Documentar `total` como obsoleto y decir a cuál de los dos equivale.
3. Migrar consumidores a los campos explícitos; medir uso de `total`.
4. Retirar `total` cuando nadie lo lea.
```

Cambiar el significado en silencio es el peor cambio posible: no falla nada, ningún pipeline se
queja, y las cifras empiezan a estar mal en sitios que nadie relaciona con el despliegue.

🔬 **El detalle** — Si por alguna razón hay que hacerlo de golpe —una corrección legal con fecha—, lo
mínimo es un cambio de versión mayor, aviso explícito a cada consumidor y una comprobación posterior
de cifras agregadas antes y después. Y conviene dejarlo por escrito: este es el tipo de cambio que se
revisa en una auditoría dos años más tarde.

---

# 08 — Simulación de entrevista

**Sobre las preguntas `S#`.** Están cubiertas por las preguntas de los siete capítulos del bloque:
`S1`–`S5` por [`01`](01-estilos-de-comunicacion.md), `S6`–`S10` por
[`02`](02-http-entre-servicios.md), `S11`–`S15` por [`03`](03-grpc.md) y
[`04`](04-http-contra-grpc.md), `S16`–`S19` por
[`05`](05-tiempo-real-websockets-y-sse.md), `S20`–`S24` por [`06`](06-mensajeria-y-eventos.md) y
`S25`–`S28` por [`07`](07-contratos-y-versionado.md). Las de "las que descolocan" —`S29` a `S34`— no
tienen respuesta única: se practican en voz alta.

**02/08 → E1. Tres integraciones del mismo sistema.**

⏱️ **30 segundos** — Disponibilidad en la ficha: consulta síncrona contra una proyección o copia
local. Confirmar pedido: síncrono para reservar y cobrar. Aviso al proveedor externo: asíncrono, por
cola.

🗣️ **2 minutos** — El diseño y el comportamiento con ocho segundos de lentitud:

```text
Integración            Estilo                      Si el otro tarda 8 s
─────────────────────  ──────────────────────────  ────────────────────────────
Disponibilidad         síncrono contra copia       da igual: la copia es local;
en la ficha            local por eventos           como mucho, dato algo viejo
Confirmar pedido       síncrono 1:1 (reservar,     el usuario espera; timeout corto
                       cobrar), con saga detrás    y error controlado, o pedido
                                                   PENDING si el negocio lo acepta
Aviso al proveedor     asíncrono por cola,         el usuario no se entera; el envío
externo                con reintentos y DLQ        se prepara cuando el tercero vuelva
```

🔬 **El detalle** — La primera fila es la decisión que más separa a un candidato: mucha gente propone
llamar a `inventory` desde la ficha, y eso convierte la pantalla más visitada del sistema en
dependiente del servicio más transaccional. La copia por eventos elimina la dependencia y el matiz
—la disponibilidad mostrada puede estar desfasada segundos, y la verdad la decide la reserva— es
exactamente lo que el negocio ya acepta. Para la tercera, conviene nombrar el outbox: sin él, el aviso
se pierde si el proceso muere tras confirmar el pedido.

**02/08 → E2. La plataforma cambia la respuesta.**

⏱️ **30 segundos** — En la versión A, gRPC; en la B, HTTP con OpenAPI y contratos verificados en CI. Y
en ambas, resolver el balanceo antes de nada.

🗣️ **2 minutos** — Qué cambia exactamente entre las dos:

```text
                       Versión A (dos de Go)        Versión B (Python + Node, sin gRPC)
Coste de adopción      bajo: es su terreno          medio-alto: dos cadenas de generación
                                                     nuevas y una curva por equipo
Deadlines              gratis con context           habría que construirlos a mano en HTTP
Balanceo               hay que resolverlo IGUAL     hay que resolverlo IGUAL
Beneficio de contrato  alto y barato                el mismo se consigue con OpenAPI +
                                                     verificación en CI
Decisión               gRPC                          HTTP con contrato verificado
```

🔬 **El detalle** — Lo que **no** cambia entre las dos versiones es el problema del balanceo: la
plataforma reparte conexiones, así que con gRPC todo el tráfico iría a una instancia. En la versión A
eso hay que resolverlo antes de migrar —cliente balanceado, proxy L7 o mesh—; en la versión B, al
quedarse en HTTP/1.1 con conexiones cortas, el balanceador clásico basta y el problema desaparece.
Mencionar esa asimetría es lo que demuestra que se entiende el coste real de gRPC.

**02/08 → E3. Seguimiento en vivo del pedido, web y móvil, eventos de tres servicios.**

⏱️ **30 segundos** — Eventos por dentro, SSE hacia la web, notificaciones push hacia el móvil, y
consulta del estado actual al conectar.

🗣️ **2 minutos** — El camino completo:

```text
orders/payments/shipping ──eventos──► topic ──► servicio que mantiene las conexiones
                                                    │  (backplane: cada instancia filtra
                                                    │   por los usuarios que tiene)
                                                    ├─► web: SSE (reconexión y reanudación
                                                    │        de serie; HTTP normal)
                                                    └─► móvil: push del sistema operativo
                                                             (la app puede estar cerrada)

Al (re)conectar   el cliente consulta el estado actual por HTTP
                  → perder eventos durante un corte deja de importar
Autenticación     token en la petición; al caducar, se corta y se reconecta
Despliegue        reemplazo gradual + cierre avisado + reconexión con jitter
```

🔬 **El detalle** — La decisión que más simplifica todo el diseño es consultar el estado al conectar:
con ella no hace falta almacenar historial por usuario ni garantizar entrega de cada evento a cada
conexión. Y la elección de SSE sobre WebSocket se defiende con dos hechos: el tráfico va en un solo
sentido y la reanudación por identificador viene incluida. Si el entrevistador pregunta por qué no
WebSocket, la respuesta es que tendríamos que inventarnos el protocolo de mensajes, la reconexión y el
versionado, a cambio de un canal de vuelta que no necesitamos.

**02/08 → E4. Un cambio de contrato que rompe, con una aplicación móvil que no se actualiza.**

⏱️ **30 segundos** — Expand/contract para el renombrado; campos nuevos con nombre inequívoco para el
cambio de significado; y versión mínima soportada para el móvil.

🗣️ **2 minutos** — El plan:

```text
Renombrado (importe → total)
  1. devolver ambos campos y aceptar ambos en la entrada
  2. migrar consumidores; medir uso del viejo por consumidor
  3. retirar cuando el uso sea cero y tras avisar

Cambio de significado (sin impuestos → con impuestos)
  NO se cambia el significado de un campo existente. Se añaden
  total_sin_impuestos y total_con_impuestos, explícitos;
  el campo antiguo conserva su significado original y se marca obsoleto.

Móvil
  · no puede migrar a nuestro ritmo → la fase de convivencia dura lo que dure
  · versión mínima soportada: la app comprueba al arrancar y pide actualizar
  · si no existe ese mecanismo, se introduce ahora: sin él, el contrato
    queda congelado para siempre por la versión más vieja instalada
```

🔬 **El detalle** — El cambio de significado es la parte donde se gana o se pierde la respuesta:
cambiarlo en silencio no rompe ningún pipeline, no da ningún error, y produce cifras incorrectas en
sitios que nadie relaciona con el despliegue. Es el peor cambio posible y por eso se convierte en dos
campos explícitos. Si por una obligación legal hubiera que hacerlo de golpe, lo mínimo es versión
mayor, aviso individual a cada consumidor y comprobación de cifras agregadas antes y después.

**02/08 → E5. El evento que nunca llegó: lag cero y DLQ vacía.**

⏱️ **30 segundos** — Compruebo en orden: outbox, topic, lag, tabla de procesados y DLQ. Las tres causas
más probables son que nunca se publicó, que se descartó por idempotencia, o que se filtró en
silencio.

🗣️ **2 minutos** — El recorrido y las hipótesis:

```text
Comprobación                          Qué descarta
────────────────────────────────────  ─────────────────────────────────────
¿está la fila en outbox_events?       si no: el fallo es del código de negocio
¿tiene marca de publicado?            si no: el publicador está parado o atascado
¿está el mensaje en el topic?         si no: falló la publicación
¿lag del consumidor?                  alto: es capacidad, no pérdida
¿está en processed_messages?          sí: se descartó por duplicado
¿está en la DLQ?                      sí: falló al procesar

Hipótesis, en orden
1. Nunca se publicó: doble escritura sin outbox; el pedido se guardó y
   la publicación falló. El emisor no registró ningún error.
2. Descartado por idempotencia: una marca escrita en un intento anterior
   que falló DESPUÉS de marcar y ANTES de aplicar el efecto.
3. Filtrado en silencio: el consumidor lo ignoró por tipo desconocido,
   versión no soportada o una condición de negocio, sin contarlo.
```

🔬 **El detalle** — La hipótesis 2 es la que justifica toda la insistencia del corpus en que la marca y
el efecto vayan en la misma transacción, y se confirma comparando la tabla de procesados con los
efectos reales. La 3 lleva a una regla de diseño que conviene enunciar: **un consumidor nunca debe
ignorar un mensaje en silencio**; si no le aplica, lo cuenta en una métrica. Los mensajes ignorados
sin rastro son la fuente de incidentes más difícil de diagnosticar del modelo asíncrono.

---

**Anterior:** [`08` — Simulación de entrevista](08-simulacion-de-entrevista.md) ·
**Índice del bloque:** [README](README.md)
