# 07 — Respuestas: Fundamentos y modelo mental

Solucionario del bloque `01-fundamentos-y-modelo-mental`. Cada enunciado está copiado literalmente de su
capítulo o de la simulación, con la numeración de su documento, y cada respuesta conserva las tres
capas: **⏱️ 30 segundos** (lo que dirías primero), **🗣️ 2 minutos** (contexto, alternativa y
coste) y **🔬 El detalle** (para estudiar, no para recitar).

> **Vigencia:** 2026-09-28.

**Salto rápido:** [01 Qué problema resuelve la arquitectura hexagonal](#01--qué-problema-resuelve-la-arquitectura-hexagonal) · [02 Regla de dependencias y dirección del código](#02--regla-de-dependencias-y-dirección-del-código) · [03 Puertos y adaptadores](#03--puertos-y-adaptadores) · [04 Hexagonal, Clean, Onion y capas](#04--hexagonal-clean-onion-y-capas) · [05 Cuándo no usarla y antipatrones](#05--cuándo-no-usarla-y-antipatrones) · [06 Simulación](#06--simulación-de-entrevista)

---

## 01 · Qué problema resuelve la arquitectura hexagonal

### 1. 🟢 ¿Qué problema concreto intenta resolver la arquitectura hexagonal?

⏱️ **30 segundos:** Evita que la política de negocio dependa de detalles como HTTP, el ORM o un
proveedor externo. Cuando una regla vive mezclada con esos detalles, cambiar el detalle obliga a
tocar la regla.

🗣️ **2 minutos:** El síntoma típico es `CreateOrder` escrito dentro de un controller: valida, llama
al ORM, publica y devuelve JSON. Funciona hasta que llega una segunda entrada (un consumidor de
mensajes), una base distinta para pruebas o una regla que debe ejecutarse sin HTTP. Hexagonal pone
el núcleo en el centro, expresa sus conversaciones mediante puertos y deja que los adaptadores
traduzcan el exterior. Así se puede cambiar una entrada o una salida y probar la política aislada.
El precio es más tipos, mapeo y composición explícita.

🔬 **El detalle:** No elimina dependencias; cambia su dirección y concentra el conocimiento de los
detalles en los bordes. El núcleo sigue necesitando guardar pedidos, pero lo expresa como `Orders` y
no como `JpaRepository`. La prueba de que funcionó no es el dibujo, sino que el núcleo compile y se
pruebe sin framework.

### 2. 🟢 ¿Qué diferencia hay entre política y detalle?

⏱️ **30 segundos:** La política decide qué debe hacer el sistema; el detalle decide con qué
tecnología lo hace. "Un pedido no puede cobrarse dos veces" es política; HTTP, PostgreSQL y el SDK
del proveedor son detalles.

🗣️ **2 minutos:** La distinción sirve para decidir hacia dónde apuntan las dependencias: el detalle
depende de la política, nunca al revés. Una forma práctica de separarlas es preguntar qué cambiaría
si mañana se sustituye la tecnología: si la frase sigue siendo cierta, es política. "El total supera
1000 y el pago se rechaza" sobrevive a cambiar de proveedor; "el proveedor responde `402`" no. En
una revisión de código, la política aparece como reglas, estados e invariantes; el detalle, como
anotaciones, clientes, SQL y códigos de protocolo.

🔬 **El detalle:** Lo que importa es la estabilidad relativa, no la popularidad. Una librería muy
usada puede ser detalle porque su API cambia a otro ritmo que el negocio; un tipo como `Money` puede
ser política aunque sea técnico, porque expresa una regla de redondeo que el negocio defiende.

### 3. 🟢 ¿Qué es un port en este modelo?

⏱️ **30 segundos:** Es el contrato de una conversación entre el núcleo y el exterior, escrito en el
lenguaje del núcleo. Hay puertos de entrada, que ofrecen una capacidad, y de salida, que declaran
una necesidad.

🗣️ **2 minutos:** Un puerto de entrada como `CreateOrder` dice qué puede pedirle el mundo a la
aplicación; uno de salida como `PaymentGateway` dice qué necesita la aplicación del mundo. En ambos
casos el núcleo es dueño del contrato: sus nombres, tipos y errores vienen del negocio, no de la
tecnología. Puede ser una interfaz, una función o un módulo, según la plataforma. Lo que no debe
hacer es copiar el API de un SDK o de un endpoint, porque entonces el detalle vuelve a mandar con
otro nombre.

🔬 **El detalle:** Su granularidad debe seguir una razón de cambio y una necesidad real del núcleo.
Un puerto demasiado ancho se convierte en fachada de infraestructura; uno demasiado fino obliga al
caso de uso a coordinar decisiones artificiales. La pregunta de diseño es qué capacidad puede
explicarse en una frase sin nombrar la tecnología.

### 4. 🟢 ¿Qué es un adapter?

⏱️ **30 segundos:** Es el código que traduce un protocolo externo al puerto del núcleo, o el puerto
del núcleo a un protocolo externo. Vive en el borde y conoce ambos lados.

🗣️ **2 minutos:** Un controller es un adaptador de entrada: convierte una petición HTTP en un
comando y el resultado en una respuesta con status y JSON. Un repositorio JPA es un adaptador de
salida: implementa `Orders` y traduce entre `Order` y un registro de tabla. La dirección de
dependencia es la misma en ambos: el adaptador depende del puerto, el núcleo no conoce al adaptador.
Por eso se puede sustituir un adaptador sin tocar la política, y probar la política con un doble en
lugar del adaptador real.

🔬 **El detalle:** Un adaptador no es un wrapper que renombra llamadas. También traduce errores (un
`SQLException` a `OrderNotFound`), formatos (decimales, fechas, identificadores), ciclo de vida
(conexiones, sesiones) y políticas de reintento cuando corresponde. Si solo reenvía métodos,
probablemente sobra.

### 5. 🟢 ¿Por qué el hexágono no tiene que tener literalmente seis lados?

⏱️ **30 segundos:** Porque el hexágono es una metáfora visual para mostrar varias conversaciones con
el núcleo, no una restricción. Lo que enseña es la relación dentro-fuera.

🗣️ **2 minutos:** Cockburn eligió un hexágono para dejar espacio a varias entradas y salidas en el
dibujo y romper la imagen de capas apiladas de arriba abajo. Un sistema real puede tener dos puertos
naturales o doce; forzar seis es tan arbitrario como forzar tres capas. En entrevista, la respuesta
útil es desplazar la conversación de la forma a la regla: todo lo que está dentro define contratos,
todo lo que está fuera los implementa o los invoca, y las dependencias de código apuntan hacia
dentro.

🔬 **El detalle:** El dibujo también sugiere simetría entre entradas y salidas, que es la aportación
real frente a una arquitectura en capas: la base de datos deja de ser "el fondo" y pasa a ser un
adaptador más, al mismo nivel que HTTP. Esa simetría es la que hace natural probar el núcleo
sustituyendo cualquier borde.

### 6. 🟢 ¿Puede existir arquitectura hexagonal dentro de un monolito?

⏱️ **30 segundos:** Sí. Hexagonal describe la dirección de las dependencias dentro del código, no el
número de procesos ni la forma de desplegar.

🗣️ **2 minutos:** Un monolito puede tener núcleo, puertos y adaptadores, compilarse como un solo
artefacto y desplegarse como una unidad. De hecho es el lugar más barato para aplicarla: no hay red
entre módulos, las transacciones siguen siendo locales y la frontera se verifica con reglas de
imports. Confundir hexagonal con microservicios lleva a dos errores: pensar que hay que partir el
sistema para "hacerla bien", o pensar que un microservicio ya es hexagonal por ser pequeño.

🔬 **El detalle:** El aislamiento interno puede hacer más segura una futura extracción, porque la
capacidad ya tiene un contrato y sus dependencias están nombradas. Pero no la garantiza: una base
compartida, transacciones que cruzan módulos o consistencia inmediata entre capacidades siguen
siendo acoplamiento, aunque los imports estén limpios.

### 7. 🟢 ¿Qué significa que el núcleo sea independiente de HTTP?

⏱️ **30 segundos:** Que puede ejecutar el caso de uso sin importar request, response, status codes,
headers ni middleware. HTTP es una de las formas de invocarlo, no la única.

🗣️ **2 minutos:** El adaptador HTTP lee el cuerpo, valida la forma, extrae la identidad autenticada
y construye un comando propio. El caso de uso devuelve un resultado o un error de negocio, y el
adaptador decide si eso es un `201`, un `409` o un `404`. Con esa separación, una cola, una CLI o
una prueba pueden usar el mismo puerto. La evidencia concreta es doble: el paquete del núcleo no
importa nada del framework web, y hay una prueba que ejecuta el caso de uso sin levantar un
servidor.

🔬 **El detalle:** El núcleo aún puede devolver errores de negocio con significado propio, como
`InsufficientInventory`; el borde decide cómo representarlos. La trampa frecuente es lo contrario:
lanzar `HTTPException` o `ResponseStatusException` desde la regla, que ata la semántica del negocio
al transporte.

### 8. 🟡 ¿Qué cambio de negocio queda protegido y cuál no?

⏱️ **30 segundos:** Queda protegido cambiar una regla sin reescribir transporte ni persistencia, y
cambiar transporte o persistencia sin reescribir la regla. No queda protegido un concepto de negocio
mal definido.

🗣️ **2 minutos:** La separación reduce el radio de los cambios técnicos y de los cambios de reglas
locales: ajustar el límite de crédito toca el dominio y sus pruebas, no el controller ni el SQL. En
cambio, si cambia qué significa "pedido" —por ejemplo, pasa a admitir varios clientes o varias
monedas—, habrá que tocar el núcleo, los contratos de sus puertos y probablemente todos los
adaptadores que los traducen. Eso no es un fallo de la arquitectura: es que el cambio afecta a la
política misma.

🔬 **El detalle:** Hexagonal protege direcciones de dependencia, no fronteras de dominio. Elegir bien
qué es un agregado, qué capacidad va junta y qué debe separarse es trabajo de modelado; la
arquitectura solo hace visible y barato mantener esa decisión una vez tomada.

### 9. 🟡 ¿Por qué un repositorio en memoria es una evidencia útil y no solo un mock?

⏱️ **30 segundos:** Porque demuestra que el caso de uso depende de una capacidad y no de una base
concreta, y porque se comporta como un repositorio: guarda y devuelve estado, no solo registra
llamadas.

🗣️ **2 minutos:** Un mock verifica interacciones ("se llamó `save` una vez"); un fake en memoria
permite verificar resultados ("el pedido quedó confirmado y se puede recuperar"). La segunda
aserción sobrevive a refactorizaciones internas y dice algo del negocio. Si además el adaptador real
se prueba aparte contra la base, cada prueba tiene un alcance claro: el fake cubre coordinación e
invariantes, la integración cubre SQL, restricciones y mapeo. Juntas cubren más que cien pruebas con
mocks.

🔬 **El detalle:** El fake debe respetar la semántica relevante del puerto: devolver vacío cuando no
existe, rechazar duplicados si la base lo haría, respetar el versionado optimista si el caso de uso
depende de él. Un doble que acepta lo que la base rechazaría produce confianza falsa; por eso
conviene un test de contrato que corra igual contra el fake y el adaptador real.

### 10. 🟡 ¿Qué precio introduce separar request, command y respuesta?

⏱️ **30 segundos:** Añade tipos y mapeos que mantener, a cambio de que el transporte no dicte el
contrato del núcleo. Se paga en líneas, pruebas de traducción y tiempo de lectura.

🗣️ **2 minutos:** El request pertenece al contrato HTTP (nombres, versiones, opcionales), el comando
a la aplicación (intención y datos suficientes) y la respuesta a la representación pública.
Separarlos permite versionar la API sin tocar el caso de uso, aceptar la misma intención desde una
cola y no exponer campos internos por accidente. El coste aparece en cada campo nuevo, que atraviesa
tres tipos y dos mapeos. Se paga bien cuando hay varias entradas, evolución independiente del
contrato público o reglas valiosas que proteger.

🔬 **El detalle:** Si los tres objetos son idénticos, no hay una segunda entrada y la API no es
pública, la separación puede ser ceremonia vacía. Lo que nunca compensa es el atajo contrario en la
salida: devolver la entidad de persistencia porque el serializador la acepta, que convierte el
esquema de la base en contrato público.

### 11. 🟡 ¿Cuándo un CRUD pequeño no justifica la ceremonia?

⏱️ **30 segundos:** Cuando es estable, tiene una entrada, una salida y pocas reglas que no necesitan
aislamiento. Ahí los puertos y mappers cuestan más que el cambio que protegen.

🗣️ **2 minutos:** Mantendría un módulo claro con una función de negocio separada, acceso a datos
directo y una prueba que cubra la regla que exista. Documentaría la decisión y la señal que haría
crecer la frontera: una segunda entrada, una integración volátil, una regla que empieza a cambiar
cada sprint. Esa nota evita dos fallos: que alguien añada capas "por consistencia" con el resto de
servicios, y que el día que la señal aparece nadie sepa que había que revisar el diseño.

🔬 **El detalle:** "Pequeño" no se mide en líneas. Un CRUD de tres tablas que mueve dinero o datos
regulados tiene más riesgo que un servicio grande de lectura. Volatilidad, coste del fallo y número
de adaptadores deciden; el tamaño solo es una pista.

### 12. 🟡 ¿Qué diferencia hay entre aislar una dependencia y eliminarla?

⏱️ **30 segundos:** Aislarla concentra su conocimiento en un borde; eliminarla la quita del sistema.
Lo primero casi siempre es posible; lo segundo rara vez es necesario.

🗣️ **2 minutos:** El núcleo puede depender de `PaymentGateway` mientras el adaptador depende del SDK
del proveedor. El SDK sigue existiendo, sigue teniendo bugs y sigue cambiando, pero cuando cambia
solo se edita un archivo y solo fallan las pruebas de ese adaptador. Ese es el beneficio medible:
menor radio de cambio y un lugar único donde se traducen errores y formatos. Prometer "eliminar la
dependencia del proveedor" es exagerar; lo honesto es "la aislamos detrás de un contrato propio".

🔬 **El detalle:** Una abstracción que solo renombra el SDK no constituye aislamiento semántico. Si
`PaymentGateway` expone los estados del proveedor, sus códigos y su modelo de reintentos, el
proveedor sigue dictando la política; solo cambió el nombre de la clase que se importa.

### 13. 🟡 ¿Por qué la arquitectura no arregla una frontera de negocio mala?

⏱️ **30 segundos:** Porque organiza dependencias alrededor de la política que ya existe; no descubre
la política por ti. Un hexágono ordenado puede envolver un modelo equivocado.

🗣️ **2 minutos:** Se puede tener un núcleo impecable en cuanto a imports con un caso de uso que
mezcla pagos, inventario y catálogo sin una decisión clara de quién es dueño de qué. Las pruebas
pasan, las reglas de arquitectura pasan, y aun así cada cambio de negocio toca cinco casos de uso
porque la responsabilidad está mal repartida. Hexagonal hará ese problema más visible —aparecen
puertos enormes y casos de uso que coordinan todo— pero no lo resuelve.

🔬 **El detalle:** Primero se aclaran responsabilidades y límites de consistencia (qué debe ser
atómico, quién posee cada dato); después se decide cuánto aislamiento técnico compensa. Invertir el
orden produce la peor combinación: mucha ceremonia alrededor de un modelo que habrá que rehacer.

### 14. 🟡 ¿Cómo explicarías el beneficio sin prometer “futuro-proofing”?

⏱️ **30 segundos:** Nombrando qué cambio concreto queda más barato y qué coste nuevo aceptamos a
cambio. Nada de "así estaremos preparados para cualquier cosa".

🗣️ **2 minutos:** Por ejemplo: "podemos probar las reglas de pedido sin PostgreSQL en milisegundos,
y el mismo caso de uso atiende HTTP y la cola de otro sistema; pagamos mapeos, un composition root
explícito y pruebas de cada adaptador". Esa frase tiene tres ventajas en entrevista: es verificable,
admite que hay un precio y deja claro qué no cubre. Si alguien pregunta por migrar de base, la
respuesta honesta es que se abarata, no que es gratis, y que no es la razón principal para hacerlo.

🔬 **El detalle:** Una arquitectura no hace gratis ningún futuro que no esté en sus fronteras. Si el
cambio llega por un lado que no tiene puerto —un requisito de consistencia distribuida, un nuevo
modelo de negocio—, costará lo mismo que sin hexágono.

### 15. 🟡 ¿Qué parte del sistema puede conocer al framework?

⏱️ **30 segundos:** Los adaptadores y el composition root; el núcleo debería recibir contratos
propios. Spring, Nest o FastAPI viven en el borde.

🗣️ **2 minutos:** El controller puede llevar anotaciones de rutas, el repositorio anotaciones de
ORM, y la configuración construye el grafo con el contenedor del framework. El caso de uso y el
dominio no deberían importar controller, ORM, contexto HTTP ni el propio contenedor. Esa separación
permite probar la política sin arrancar el framework y actualizar el framework sin reescribir
reglas. En Spring, por ejemplo, el caso de uso puede ser una clase Java sin anotaciones que un
`@Configuration` registra como bean.

🔬 **El detalle:** La línea exacta depende de qué se considere estable. Algunos equipos aceptan
anotaciones de validación o de nulabilidad en el dominio porque son estables y baratas; lo
importante es declararlo como excepción con motivo, no dejar que el framework entre sin que nadie lo
decida.

### 16. 🟡 ¿Qué parte del sistema puede conocer la política de negocio?

⏱️ **30 segundos:** El núcleo la posee y los contratos que expresa la hacen visible; los adaptadores
la conocen lo suficiente para traducirla, pero no la deciden.

🗣️ **2 minutos:** Un adaptador de pagos tiene que entender qué significa autorizar, qué es un
rechazo definitivo y qué es un resultado incierto, porque su trabajo es convertir respuestas del
proveedor en esos resultados. Lo que no debe hacer es decidir qué pasa con el pedido cuando el pago
falla, ni trasladar el modelo del SDK al dominio. La regla es: el adaptador sabe de la política lo
necesario para traducir; el núcleo decide.

🔬 **El detalle:** Conocer una regla para mapear no equivale a depender de la implementación externa.
La señal de que un adaptador cruzó la línea es que contiene `if` de negocio ("si el total supera X,
rechaza") en lugar de traducciones ("el proveedor dice `declined`, eso es `Rejected`").

### 17. 🟠 Tienes HTTP y Kafka como entradas. ¿Qué compartirías y qué separarías?

⏱️ **30 segundos:** Compartiría el caso de uso y su comando cuando la intención es la misma;
separaría adaptadores, validación de forma, identidad y manejo de errores de cada transporte.

🗣️ **2 minutos:** Ambos adaptadores pueden construir el mismo `CreateOrderCommand` si expresan la
misma intención. Lo que cambia es todo lo demás: HTTP tiene autenticación por token, status codes,
`Idempotency-Key` y respuesta síncrona; Kafka tiene esquema versionado, offsets, redelivery, orden
por partición y un productor que es otro sistema. La idempotencia pasa a ser obligatoria en la
entrada de Kafka y conviene que viva en el caso de uso o en su persistencia, para que ambos
transportes la compartan en vez de duplicarla.

🔬 **El detalle:** Si las entradas expresan intenciones distintas —por ejemplo, Kafka trae "pedido
importado de un marketplace" con reglas de precio propias—, no fuerzo un comando común. Dos comandos
que comparten parte de sus datos son más honestos que un comando con banderas por origen.

### 18. 🟠 El equipo quiere crear una interfaz por cada clase. ¿Cómo responderías?

⏱️ **30 segundos:** Pediría, por cada interfaz, la frontera que marca y el cambio que protege. Las
que no tengan respuesta sobran.

🗣️ **2 minutos:** Mantendría interfaces para los puertos del núcleo —capacidades que tienen o pueden
tener otra implementación, o que hay que sustituir en pruebas— y dejaría concretas las clases
internas: mappers, servicios de dominio, validadores. Una interfaz con una sola implementación que
nunca se sustituye añade un salto de navegación, un archivo más y la tentación de mockearla en todas
partes. En Java la regla es aún más clara porque los dobles de clases concretas son triviales.

🔬 **El detalle:** Las interfaces indiscriminadas no son neutras: aumentan navegación, mocks y
decisiones sin valor, y esconden cuáles son las fronteras reales entre muchas falsas. La respuesta
de entrevista es que la interfaz es una herramienta para un puerto, no la definición de hexagonal.

### 19. 🟠 Una migración de base es improbable, pero las reglas cambian cada semana. ¿Qué frontera priorizas?

⏱️ **30 segundos:** Aislaría el dominio y los casos de uso, que es donde está la volatilidad; no
diseñaría una abstracción de base de datos por una migración hipotética.

🗣️ **2 minutos:** El riesgo real está en la política: cada semana alguien cambia una regla, y cada
cambio debe poder hacerse y probarse rápido. Eso pide un dominio sin ORM, casos de uso con pruebas
rápidas y reglas en un lugar. La persistencia puede quedar simple: un puerto con los métodos que el
caso de uso necesita y un adaptador directo, sin repositorio genérico ni capa de portabilidad SQL.
El punto que sí defendería es que el modelo de negocio no sea la entidad ORM, porque eso ata las
reglas al esquema.

🔬 **El detalle:** La probabilidad y el coste del cambio deben justificar cada frontera. Separar el
dominio del ORM se paga aquí por la volatilidad de reglas, no por la migración; que de paso abarate
cambiar de base es un efecto secundario, no el argumento.

### 20. 🟠 Una aplicación solo tiene un endpoint y una tabla. ¿Qué diseño propones?

⏱️ **30 segundos:** Un módulo directo, con la regla de negocio separada en una función o clase
propia y una prueba; no un hexágono ceremonial con puertos y mappers.

🗣️ **2 minutos:** Dejaría una costura clara: el handler lee la petición, llama a una función que
contiene la regla y persiste el resultado. Esa función no importa el framework, así que se puede
probar sola y, si crece, convertirse en caso de uso sin reescribirla. Añadiría puertos cuando
aparezca otra entrada, otra salida o una volatilidad real. Registraría la decisión con la señal de
revisión, para que la simplicidad sea una elección y no un accidente.

🔬 **El detalle:** La ausencia de hexágono formal no autoriza a mezclar toda la lógica en el
controller. La diferencia entre "simple" y "descuidado" es precisamente esa costura: dirección de
dependencias correcta con el mínimo de tipos.

### 21. 🟠 ¿Cómo defenderías hexagonal ante alguien que la llama “sobreingeniería”?

⏱️ **30 segundos:** No la defendería en abstracto. Mostraría el cambio concreto que abarata, el
precio que introduce y, si no hay cambio que proteger, le daría la razón.

🗣️ **2 minutos:** La crítica suele ser justa sobre implementaciones ceremoniales: interfaces por
clase, mappers idénticos, seis módulos para un CRUD. Separaría esa ceremonia de la regla central,
que es barata: el núcleo no importa detalles. Si el sistema tiene reglas críticas y varios
adaptadores, enseñaría pruebas aisladas rápidas, un proveedor sustituido sin tocar el caso de uso o
un segundo transporte añadido en un día. Si no los tiene, aceptaría simplificar y conservaría solo
la dirección de dependencias.

🔬 **El detalle:** La respuesta madura puede ser "aquí no la usaría". En entrevista suma más
reconocer el coste y los casos donde no compensa que defender la arquitectura como si fuera un valor
en sí mismo.

### 22. 🟠 ¿Qué señal te haría retirar una abstracción?

⏱️ **30 segundos:** Que no tenga razón de cambio, implementación alternativa, prueba aislada que la
use ni límite semántico. Si no hace ninguna de esas cuatro cosas, es ceremonia.

🗣️ **2 minutos:** Revisaría si el puerto solo reenvía todos los métodos de un proveedor, si su
contrato cambia cada vez que cambia el SDK, si añade más mapeo que protección o si nadie lo
sustituye ni en pruebas. También miraría el historial: si en un año cada cambio del adaptador obligó
a cambiar el puerto, la abstracción no está aislando nada. Retirarla reduce archivos, saltos de
navegación y mocks, y hace más visibles las fronteras que sí importan.

🔬 **El detalle:** Retirar no significa perder la prueba ni la frontera conceptual valiosa. Se puede
quitar la interfaz y conservar la separación de la regla en una función pura, o conservar el test de
integración que protegía el comportamiento.

### 23. 🟠 ¿Qué prueba demostraría que la política está aislada?

⏱️ **30 segundos:** Una prueba del caso de uso que ejecute las reglas con dobles propios, sin
framework, red ni base real, y que falle cuando la regla cambia.

🗣️ **2 minutos:** Por ejemplo, `CreateOrder` con un fake de `Orders` y un fake de inventario: se
crea un pedido con stock insuficiente y se comprueba el error de negocio y que no quedó nada
guardado. Luego probaría cada adaptador por separado contra su recurso real. La prueba aislada no
demuestra que todo funcione, pero sí que el núcleo no necesita detalles para comportarse, que es
exactamente la propiedad que se quiere proteger. Si esa prueba necesita levantar el contexto del
framework, la política no está aislada.

🔬 **El detalle:** También inspeccionaría las dependencias de compilación con una regla de
arquitectura (ArchUnit, dependency-cruiser, import-linter). Una prueba aislada puede coexistir con
imports indebidos que no se ejecutan en ese camino; la regla de imports lo detecta, la prueba no.

### 24. 🟠 ¿Qué parte de tu respuesta cambiaría si el sistema fuera regulado?

⏱️ **30 segundos:** Subiría el valor de la trazabilidad, la auditoría, las pruebas y el control de
cambios. La dirección de dependencias no cambia; cambia cuánto merece la pena invertir en
demostrarla.

🗣️ **2 minutos:** En un sistema regulado hay que poder demostrar qué regla se ejecutó, con qué datos
y quién la invocó. Un núcleo aislado ayuda: las reglas están en un lugar, se prueban de forma
determinista y se versionan con historia clara. Aceptaría más estructura si permite esa evidencia:
actor explícito en cada caso de uso, auditoría como puerto, adaptadores verificables con pruebas de
contrato. Aun así, no añadiría capas sin una obligación concreta que cubran.

🔬 **El detalle:** La regulación cambia el coste del fallo, no la dirección de dependencias. Lo que
sí suele cambiar es la tolerancia a excepciones: en un sistema regulado, una dependencia de
framework en el dominio "por comodidad" necesita justificación escrita, porque dificulta auditar qué
ejecuta la regla.

---

## 02 · Regla de dependencias y dirección del código

### 1. 🟢 ¿Cuál es la regla de dependencias?

⏱️ **30 segundos:** Las dependencias de código apuntan hacia la política, no hacia los detalles. El
núcleo define contratos; los detalles los implementan o los invocan.

🗣️ **2 minutos:** En la práctica significa que `CreateOrder` declara que necesita `Orders` y el
adaptador JPA implementa `Orders`; el caso de uso nunca importa el adaptador. La composición conecta
ambos desde un borde que sí conoce los dos lados. La regla se comprueba en tres lugares: los imports
del núcleo, los tipos que cruzan sus puertos y quién construye el grafo al arrancar. Si los tres
apuntan hacia adentro, el detalle se puede cambiar sin tocar la política.

🔬 **El detalle:** También cuenta el formato de datos y los nombres importados, no solo las llamadas.
Un caso de uso que recibe una fila de base o el JSON de un proveedor depende de ese detalle aunque
no importe su librería. Es la *Dependency Rule* de Clean Architecture con otro vocabulario.

### 2. 🟢 ¿Qué diferencia hay entre una dependencia de compilación y una de runtime?

⏱️ **30 segundos:** La de compilación aparece en imports y tipos: qué necesita el código para
compilar. La de runtime aparece en los objetos conectados al ejecutar: quién llama a quién.

🗣️ **2 minutos:** En runtime, `CreateOrder` termina llamando a un adaptador JPA; en compilación,
solo conoce `Orders`. Esa asimetría es la inversión: el control fluye hacia afuera y la dependencia
de código apunta hacia adentro. Puedes tener imports limpios y un grafo de runtime mal construido
—por ejemplo, un singleton con estado de petición— o un grafo correcto con imports que filtran el
ORM. Por eso se revisan ambas: reglas de arquitectura para la primera, prueba de arranque para la
segunda.

🔬 **El detalle:** La configuración del contenedor no debe hacer invisible quién conoce a quién. Un
grafo resuelto por escaneo de anotaciones es cómodo, pero conviene que exista un lugar legible —una
clase de configuración o una función `build`— donde se vea qué implementación satisface cada puerto.

### 3. 🟢 ¿Por qué un `import` de JPA en el dominio es una señal?

⏱️ **30 segundos:** Porque el modelo de política conoce una tecnología de persistencia. Cambiar el
mapeo, el ORM o el esquema puede obligar a tocar clases que expresan reglas.

🗣️ **2 minutos:** `@Entity` parece metadata inocente, pero ata la compilación del dominio a JPA,
exige constructores sin argumentos y campos mutables, introduce colecciones lazy que fallan fuera de
sesión y hace que el esquema de tablas condicione la forma del agregado. Las pruebas de una
invariante pueden acabar necesitando una sesión abierta. Lo llamo señal y no error porque en algunos
sistemas es un compromiso razonable; lo importante es que sea una decisión y no un accidente.

🔬 **El detalle:** Solo lo toleraría con una razón explícita y un coste aceptado: CRUD estable, pocas
invariantes, equipo que conoce las trampas del ORM. La alternativa —registro de persistencia
separado y mapper— cuesta código, pero devuelve un dominio que se prueba sin base.

### 4. 🟢 ¿Dónde debería vivir un puerto de salida?

⏱️ **30 segundos:** Cerca del consumidor que expresa la necesidad, normalmente en la capa de
aplicación o en el núcleo, nunca junto a su implementación.

🗣️ **2 minutos:** Si el puerto vive con el adaptador, el núcleo tiene que importar el paquete de
infraestructura para usarlo y la dependencia queda al revés. Si vive con el caso de uso, su contrato
tiende a reflejar lo que el caso de uso necesita —tres métodos con nombres de negocio— y no todo lo
que ofrece la base o el proveedor. En Go esto es idiomático: la interfaz se declara en el paquete
que la consume. En Java suele ir en el paquete `application` junto a los casos de uso.

🔬 **El detalle:** La ubicación concreta depende de la estructura de módulos, pero la dirección no
cambia: el módulo del núcleo no depende del módulo que implementa. Si hay varios consumidores con
necesidades distintas, a veces conviene un puerto por consumidor en lugar de uno compartido.

### 5. 🟢 ¿Quién implementa un puerto de salida?

⏱️ **30 segundos:** Un adaptador de infraestructura o de integración. Puede haber varios: el real de
producción y uno en memoria para pruebas, o dos proveedores alternativos.

🗣️ **2 minutos:** `Orders` puede implementarlo un adaptador JPA, uno con SQL directo, uno en memoria
o un fake de prueba; `PaymentGateway`, un cliente HTTP, un cliente gRPC o una regla determinista.
Todos cumplen el mismo contrato del núcleo, y el composition root elige cuál se usa en cada entorno.
Esa pluralidad es la prueba de que el contrato está bien definido: si solo una implementación puede
satisfacerlo, probablemente describe esa implementación.

🔬 **El detalle:** Implementar no significa definir. El adaptador se adapta al contrato, no al revés;
cuando un proveedor nuevo no encaja, la pregunta es si el contrato del núcleo omitía una posibilidad
de negocio real (por ejemplo, el resultado incierto) o si el proveedor intenta imponer su modelo.

### 6. 🟢 ¿Qué es el composition root?

⏱️ **30 segundos:** Es el punto donde se construye y conecta el grafo de dependencias: el único
lugar que conoce las implementaciones concretas y a qué puerto satisfacen.

🗣️ **2 minutos:** Allí se leen y validan la configuración, se crean el pool de conexiones, los
adaptadores, el reloj, los casos de uso y los controllers, y se decide el ciclo de vida de cada uno.
Puede ser `main` en Go, una función `build_app` en Python, un `@Configuration` en Spring o un módulo
en NestJS. Es la excepción autorizada a la regla: importa hacia ambos lados para conectarlos, y
precisamente por eso no contiene política.

🔬 **El detalle:** Un contenedor de DI puede automatizarlo, pero no elimina el concepto. Si la
construcción se reparte por todo el código mediante escaneo y anotaciones, sigue habiendo un
composition root; solo que es invisible, y eso dificulta responder qué implementación se usa en cada
entorno.

### 7. 🟢 ¿Por qué mover una clase de carpeta no basta?

⏱️ **30 segundos:** Porque los imports, los tipos y los formatos pueden seguir apuntando al detalle
aunque la clase viva en una carpeta llamada `domain`.

🗣️ **2 minutos:** Un paquete `domain` con una clase que importa `javax.persistence` o recibe
`HttpServletRequest` sigue acoplado; solo cambió la ruta. La arquitectura se verifica con
dependencias de código y de datos, no con nombres de directorios. Las carpetas ayudan a navegar y a
comunicar intención, pero no impiden nada: cualquier desarrollador puede añadir un import prohibido
y el compilador lo aceptará si están en el mismo módulo.

🔬 **El detalle:** Los módulos compilables separados (Maven, Go modules, paquetes con visibilidad) y
las reglas automatizadas (ArchUnit, dependency-cruiser, import-linter) hacen que la frontera falle
en el build, cerca del cambio. Esa es la diferencia entre una convención que se respeta mientras
todos recuerdan y una restricción que se cumple sola.

### 8. 🟡 ¿DI y dependency inversion son lo mismo?

⏱️ **30 segundos:** No. La inyección de dependencias es un mecanismo para entregar objetos; la
inversión de dependencias es una decisión sobre quién define el contrato. Se pueden tener cada una
sin la otra.

🗣️ **2 minutos:** Un contenedor puede inyectar directamente un `StripeClient` en un caso de uso: hay
DI, pero la política depende del SDK. Al revés, en Go se puede invertir la dependencia sin ningún
contenedor: el caso de uso declara una interfaz, `main` construye el adaptador y se lo pasa por
constructor. DI resuelve construcción y ciclo de vida; la inversión resuelve dirección. Confundirlas
lleva a creer que un proyecto con `@Autowired` en todas partes ya es hexagonal.

🔬 **El detalle:** La evidencia está en quién define el contrato y quién conoce la implementación.
Pregunta útil en revisión: "si borro el adaptador, ¿qué deja de compilar?". Si deja de compilar el
caso de uso, la dependencia no está invertida, por mucho contenedor que haya.

### 9. 🟡 ¿Qué dependencia de datos puede filtrarse aunque no haya imports?

⏱️ **30 segundos:** El esquema o el formato externo: nombres de columnas, DTO del proveedor, enums
de estado, nulabilidad, unidades de dinero y fechas.

🗣️ **2 minutos:** Un dominio que trabaja con un `Map<String, Object>` construido desde una fila, o
con el JSON del proveedor deserializado a un tipo genérico, no importa ninguna librería y aun así
depende de ese formato: si la columna cambia de nombre o el proveedor añade un estado, la regla se
rompe. También se filtran semánticas: un `null` que en la base significa "no aplica" y en el dominio
debería ser un estado explícito, o importes en céntimos enteros tratados como decimales.

🔬 **El detalle:** El adaptador debe traducir forma y semántica, no solo tipos. Un buen indicador es
buscar en el núcleo literales que vienen del exterior —códigos del proveedor, nombres de columnas,
cadenas de estado ajenas—: cada uno es un punto donde el detalle todavía manda.

### 10. 🟡 ¿Cómo detectarías un contrato que repite a un proveedor?

⏱️ **30 segundos:** Comparando sus métodos, tipos y errores con el SDK. Si se parecen demasiado, el
puerto está describiendo al proveedor y no la necesidad del núcleo.

🗣️ **2 minutos:** Señales concretas: los métodos tienen los nombres de la API del proveedor
(`createCharge`, `capturePaymentIntent`), los parámetros son sus opciones, los resultados exponen
sus estados y sus códigos de error. Otra señal es histórica: cada actualización del SDK obliga a
cambiar el puerto. Un contrato del núcleo habla en términos de la decisión —`authorize(operationId,
amount)` devuelve `Authorized`, `Rejected` o `UnknownResult`— y deja que el adaptador traduzca todo
lo demás.

🔬 **El detalle:** Un contrato puede parecerse al proveedor por casualidad, porque el problema es el
mismo. La prueba decisiva es si oculta las decisiones externas: si cambiar de proveedor obligaría a
cambiar el puerto, no está invertido; si solo obliga a escribir otro adaptador, lo está.

### 11. 🟡 ¿Por qué una anotación es una dependencia?

⏱️ **30 segundos:** Porque el código necesita la librería que la define para compilar, y porque el
framework la interpreta para cambiar cómo se construye, persiste o serializa el objeto.

🗣️ **2 minutos:** `@Entity`, `@JsonProperty` o `@Transactional` no son llamadas explícitas, pero
alteran comportamiento: el ORM exige constructores y campos mutables, el serializador decide qué
campos salen, el proxy decide dónde empieza una transacción. Que no se vea una llamada no significa
que no haya acoplamiento; significa que está implícito, lo que suele ser peor para leerlo y
probarlo. Una clase de dominio con anotaciones de tres librerías tiene tres razones de cambio ajenas
al negocio.

🔬 **El detalle:** El criterio es la volatilidad y el lugar de la política, no la cantidad de
caracteres. Una anotación de nulabilidad estable puede ser aceptable en el núcleo; una de mapeo ORM
o de serialización pública, rara vez, porque describe cómo se guarda o se expone el objeto, no qué
regla protege.

### 12. 🟡 ¿Qué diferencia hay entre conocer una abstracción y conocer un detalle?

⏱️ **30 segundos:** Conocer una abstracción propia ata al núcleo a una necesidad estable; conocer el
detalle lo ata a una solución externa concreta y a su ritmo de cambio.

🗣️ **2 minutos:** `AuthorizePayment` puede depender de `PaymentGateway`, que expresa el resultado
que necesita: autorizado, rechazado o incierto. Si en cambio recibe tipos, errores o métodos del
SDK, el proveedor sigue definiendo la conversación aunque el objeto llegue inyectado por un
contenedor. La diferencia se nota cuando el proveedor cambia: con la abstracción propia se reescribe
un adaptador; con el detalle se reescribe la política y sus pruebas.

🔬 **El detalle:** La abstracción no vale por ser una interfaz. Una interfaz que copia el SDK es un
detalle con otro nombre. Vale si pertenece al consumidor —su nombre y sus tipos vienen del negocio—
y si oculta semántica que puede cambiar, como códigos de error, reintentos o formatos de dinero.

### 13. 🟡 ¿Cuándo un módulo compartido aumenta el acoplamiento?

⏱️ **30 segundos:** Cuando obliga a consumidores independientes a evolucionar y desplegar juntos
porque comparten un tipo que cambia por razones de uno solo.

🗣️ **2 minutos:** Un módulo `common-domain` con `Order`, `Customer` y sus reglas, usado por cinco
servicios, convierte cada cambio de negocio en una actualización coordinada de cinco repositorios.
Lo que parecía reutilización es una dependencia de release. En cambio, compartir una utilidad
técnica estable (un tipo `Money` con reglas de redondeo acordadas, un cliente generado de un
contrato versionado) puede ser razonable, porque cambia poco y por razones que todos los
consumidores comparten.

🔬 **El detalle:** Compartir código no es automáticamente malo; compartir razones de cambio
incompatibles sí. La pregunta útil es quién puede cambiar el módulo y a quién obliga ese cambio. Si
la respuesta es "cualquiera, a todos", el módulo es un monolito distribuido en miniatura.

### 14. 🟡 ¿Qué debe impedir una regla arquitectónica automatizada?

⏱️ **30 segundos:** Los imports y dependencias prohibidas entre política, aplicación y detalles: que
el dominio importe infraestructura, que la aplicación importe el framework web, que un adaptador
importe otro.

🗣️ **2 minutos:** Debe fallar cerca del cambio, en el build o en CI, con un mensaje que explique qué
frontera se cruzó. Ejemplos típicos: `domain` no depende de nada fuera de sí mismo y la biblioteca
estándar; `application` no depende de `infrastructure`; `inbound.http` no depende de
`outbound.postgres`. Herramientas como ArchUnit, dependency-cruiser, import-linter o deptrac lo
expresan en pocas líneas. Lo que no debe intentar es reemplazar el juicio sobre dónde van los
límites: codifica una decisión, no la toma.

🔬 **El detalle:** La regla debe ser pequeña, explicable y alineada con módulos reales. Una regla con
cuarenta excepciones deja de proteger; una regla que nadie entiende se desactiva en el primer apuro.
Tres o cuatro prohibiciones claras cubren casi todo el valor.

### 15. 🟡 ¿Qué cambia entre interfaces de Java y Go para esta decisión?

⏱️ **30 segundos:** Java declara explícitamente que una clase implementa una interfaz; Go la
satisface de forma implícita y por convención la declara junto al consumidor.

🗣️ **2 minutos:** En Go, el adaptador no necesita importar el paquete del caso de uso para
satisfacer su interfaz, lo que hace natural que el contrato sea pequeño y viva donde se usa. Eso
reduce ceremonia y facilita interfaces de uno o dos métodos. En Java, `implements` hace la relación
visible y verificable por el compilador, pero invita a crear interfaces por costumbre y a ubicarlas
junto a la implementación. Ninguno de los dos mecanismos decide el contrato: en ambos se puede
escribir un puerto que copia al proveedor.

🔬 **El detalle:** La dirección de dependencia es independiente del mecanismo del lenguaje. Lo que
cambia es la trampa típica: en Java, interfaces excesivas; en Go, paquetes `interfaces` globales sin
consumidor claro, o interfaces declaradas por el productor como si fuera Java.

### 16. 🟡 ¿Cómo revisarías un PR que añade un SDK al caso de uso?

⏱️ **30 segundos:** Preguntaría qué capacidad de negocio necesita el caso de uso y propondría un
puerto con esa capacidad y un adaptador que use el SDK.

🗣️ **2 minutos:** Revisaría qué tipos del SDK aparecen en la firma y en el cuerpo del caso de uso,
qué errores del proveedor se capturan ahí, dónde se configuran timeouts y credenciales y cómo se
construye el cliente. Cada uno de esos puntos es una decisión del borde que se ha colado en la
política. Pediría mover la llamada a un adaptador, definir resultados propios y dejar la
construcción del cliente en el composition root. Si el SDK realmente es política estable —caso raro,
como una librería de cálculo—, pediría justificarlo por escrito.

🔬 **El detalle:** No basta con mover la llamada a otra clase. Si el nuevo "adaptador" devuelve los
tipos del SDK, el contrato sigue filtrando al proveedor; la revisión tiene que mirar qué cruza la
frontera, no solo dónde está el `import`.

### 17. 🟠 El equipo dice que el contenedor “oculta” la dependencia. ¿Qué evidencia pides?

⏱️ **30 segundos:** Imports y tipos del caso de uso, el contrato que recibe, el grafo de módulos y
la configuración de composición. El contenedor oculta la construcción, no los tipos.

🗣️ **2 minutos:** Quiero ver si el caso de uso depende de un puerto propio y si el detalle
implementa ese puerto. Si el constructor del caso de uso recibe `JpaOrderRepository` o
`StripeClient`, la dependencia está ahí, visible en la firma, aunque nadie escriba `new`. El
contenedor cambia quién construye el objeto, pero no cambia qué tipo necesita el código para
compilar. La inversión se demuestra en el código fuente del núcleo, no en el XML ni en las
anotaciones del framework.

🔬 **El detalle:** Una prueba contundente es construir el caso de uso sin arrancar el contenedor, con
`new` y dobles. Si eso exige importar clases de infraestructura, la dependencia no está invertida;
si basta con fakes propios, sí.

### 18. 🟠 El ORM exige constructores y anotaciones. ¿Qué alternativas compararías?

⏱️ **30 segundos:** Tres: un modelo de persistencia separado con mapeo explícito, mapeo externo (XML
u ORM configurado fuera de la clase), o aceptar el acoplamiento y documentarlo.

🗣️ **2 minutos:** Separar `OrderRecord` de `Order` protege el dominio —constructores con
invariantes, campos inmutables, sin lazy loading— pero añade un mapper y pruebas de ida y vuelta. El
mapeo externo mantiene la clase limpia de anotaciones pero sigue imponiendo constructores y
mutabilidad. Aceptar el acoplamiento es válido en un CRUD estable si el coste está entendido: las
pruebas de reglas necesitarán más cuidado y cambiar el esquema tocará el modelo. Presentaría las
tres con su coste y elegiría según el sistema.

🔬 **El detalle:** La decisión se mide por volatilidad del modelo, riesgo del ORM y valor de las
pruebas aisladas. Si las invariantes son pocas y estables, acoplar es barato; si son muchas o
cambian a menudo, el mapper se paga solo en la primera migración de esquema que no rompe ninguna
regla.

### 19. 🟠 El puerto devuelve el DTO del proveedor. ¿Está realmente invertido?

⏱️ **30 segundos:** No del todo. El nombre del puerto puede apuntar hacia adentro, pero el formato
externo se filtró: el núcleo depende del DTO y, con él, del proveedor.

🗣️ **2 minutos:** Si `PaymentGateway.authorize` devuelve `StripeChargeResponse`, el caso de uso
tiene que conocer sus campos, sus estados y sus nulos para decidir. Cuando el proveedor cambie
`approved` por `authorized`, cambiará la política. El adaptador debe mapear ese DTO a un resultado
propio —`Authorized`, `Rejected`, `UnknownResult`— y el puerto expresar la necesidad, no el contrato
del proveedor. Solo así un segundo proveedor puede entrar sin tocar el caso de uso.

🔬 **El detalle:** Revisa también errores, enums y estados: son las filtraciones más frecuentes y las
menos visibles. Una excepción del SDK que atraviesa el puerto, o un enum del proveedor usado en un
`switch` del dominio, son dependencias igual de reales que el DTO.

### 20. 🟠 Dos casos de uso comparten un contrato enorme. ¿Qué sospechas?

⏱️ **30 segundos:** Que el contrato pertenece a un proveedor o a una abstracción genérica, o que
mezcla varias necesidades en un solo puerto.

🗣️ **2 minutos:** Mediría qué métodos usa cada consumidor. Si `CreateOrder` usa tres de veinte y
`CancelOrder` otros cuatro, el puerto no describe ninguna necesidad concreta: describe todo lo que
la tecnología puede hacer. Lo dividiría por capacidad o razón de cambio —lectura de pedidos,
escritura de pedidos, reservas— siguiendo el principio de segregación de interfaces. Cada caso de
uso depende solo de lo que usa, y sus dobles de prueba se vuelven pequeños y fieles.

🔬 **El detalle:** Las interfaces grandes producen mocks frágiles (hay que simular métodos que no
importan), dependencia accidental (un cambio en un método ajeno recompila y re-prueba todo) y la
tentación de usar métodos "porque están ahí". Partirlas cuesta poco y hace visible qué necesita cada
caso de uso.

### 21. 🟠 El equipo quiere verificar dependencias por convención de nombres. ¿Qué propones?

⏱️ **30 segundos:** Combinar los nombres con módulos compilables y reglas automáticas sobre imports
reales. La convención sola no falla cuando alguien la rompe.

🗣️ **2 minutos:** Una carpeta `domain` no basta: el compilador acepta cualquier import entre
paquetes del mismo módulo. Propondría mantener la convención, porque ayuda a leer, y añadir una
regla que falle cuando un símbolo de infraestructura o del framework se referencia desde el núcleo:
ArchUnit en Java, dependency-cruiser en TypeScript, import-linter en Python, deptrac en PHP, o
paquetes `internal` y un test de imports en Go. Si el proyecto crece, separaría el núcleo en un
módulo de build propio sin dependencias de infraestructura.

🔬 **El detalle:** Las convenciones ayudan a leer; los límites compilables ayudan a impedir. La regla
debe ejecutarse en CI y tener un mensaje que explique el porqué, para que el primer fallo enseñe en
vez de frustrar.

### 22. 🟠 Una dependencia es estable y ampliamente usada. ¿Aun así la aislarías?

⏱️ **30 segundos:** Solo si protege una razón de cambio o hace posible una prueba valiosa. La
estabilidad reduce el coste de acoplarse, y a veces lo deja por debajo del coste de aislar.

🗣️ **2 minutos:** Envolver la biblioteca estándar de fechas, una librería de colecciones o un tipo
decimal no protege nada: cambian menos que el propio negocio. En cambio, aislaría una dependencia
estable si su uso afecta a decisiones de negocio que quiero probar sin ella (el reloj, por ejemplo)
o si su semántica debe traducirse (una librería de monedas con reglas de redondeo que el negocio
discute). La popularidad no elimina el coste de acoplamiento, pero tampoco justifica envolver cada
utilidad estable.

🔬 **El detalle:** Aislar una librería técnica y aislar una política son decisiones distintas.
`Clock` se inyecta no porque el reloj del sistema sea inestable, sino porque las reglas que dependen
del tiempo tienen que probarse con tiempos fijos.

### 23. 🟠 ¿Cómo separarías la dependencia de datos de la dependencia de código?

⏱️ **30 segundos:** Con modelos propios en el núcleo y mapeo en el adaptador, además de imports
controlados. Las dos se verifican por separado.

🗣️ **2 minutos:** La dependencia de código se controla con reglas de imports y módulos. La de datos
requiere mirar qué forma tienen los valores que cruzan el puerto: un caso de uso puede importar solo
`Orders` y aun así recibir filas de SQL con nombres de columna, estados como cadenas de la base o
importes en la unidad del proveedor. Verifico nombres, tipos, estados y semántica, y exijo que el
adaptador devuelva tipos del dominio ya validados: `Money`, `OrderStatus`, identificadores con su
tipo.

🔬 **El detalle:** La traducción protege de cambios de forma, no solo de paquetes. Un test de
contrato del adaptador que compruebe la ida y vuelta —guardar y leer preserva estado, versión y
dinero— es la evidencia de que la dependencia de datos está contenida en el borde.

### 24. 🟠 ¿Cómo explicarías la dirección de dependencias en una pizarra?

⏱️ **30 segundos:** Dibujaría la política en el centro, los puertos definidos por ella en su borde y
flechas desde los detalles hacia esos contratos. Luego marcaría aparte el flujo de ejecución.

🗣️ **2 minutos:** Primero el flujo de runtime: petición → controller → caso de uso → puerto →
adaptador → base. Después, con otro color, las flechas de dependencia de código: controller → puerto
de entrada, adaptador → puerto de salida, composition root → todos. El contraste es el punto de la
explicación: el control viaja de afuera hacia adentro y de nuevo hacia afuera, pero el código
siempre depende hacia adentro. Cerraría señalando el composition root como el único lugar que conoce
ambos lados.

🔬 **El detalle:** Diferenciar dirección de control en ejecución y dirección de dependencia en código
es lo que distingue una respuesta de senior. Mucha gente dibuja las flechas de llamada y cree haber
dibujado dependencias; en ese diagrama la base de datos parece estar "debajo" del dominio, que es
justo lo que la arquitectura pretende evitar.

---

## 03 · Puertos y adaptadores

### 1. 🟢 ¿Qué es un puerto de entrada?

⏱️ **30 segundos:** El contrato de una capacidad que la aplicación ofrece al exterior, como
`CreateOrder` o `CancelOrder`. Es lo que un driver puede pedirle al núcleo.

🗣️ **2 minutos:** Un controller, un consumidor de mensajes, una CLI o una prueba lo usan para
activar un caso de uso sin conocer su implementación ni el transporte de los demás. Recibe un
comando propio (`CreateOrderCommand`) y devuelve un resultado o un error de negocio. Su valor
aparece cuando hay más de un driver: HTTP y una cola invocan la misma intención con la misma
validación de negocio, y cada adaptador se ocupa solo de su protocolo.

🔬 **El detalle:** Puede ser una interfaz, una función o un módulo; el nombre `Port` no es lo
esencial. En Java muchos equipos exponen directamente la clase del caso de uso como puerto de
entrada y solo crean una interfaz cuando hay una razón concreta, como sustituirla en las pruebas del
controller.

### 2. 🟢 ¿Qué es un puerto de salida?

⏱️ **30 segundos:** El contrato de una capacidad que el núcleo necesita del exterior: guardar un
pedido, leer el reloj, autorizar un pago, registrar una notificación pendiente.

🗣️ **2 minutos:** El núcleo lo declara en sus propios términos y un adaptador lo implementa con la
tecnología que toque. `Orders` puede resolverse con JPA o con SQL; `PaymentGateway`, con un cliente
HTTP, gRPC o una regla determinista para pruebas. Gracias a eso el caso de uso se prueba con fakes y
la tecnología se sustituye sin tocar la política. Es la mitad "hacia afuera" de la simetría
hexagonal: la base y el proveedor son adaptadores, igual que HTTP.

🔬 **El detalle:** Debe expresar la necesidad mínima, no todo lo que ofrece el proveedor. Un puerto
de salida que reproduce el API completo de la base o del SDK obliga al caso de uso a conocer
decisiones técnicas y a sus dobles de prueba a simular métodos que nadie usa.

### 3. 🟢 ¿Qué responsabilidad tiene un adapter?

⏱️ **30 segundos:** Traducir entre un puerto del núcleo y un protocolo o tecnología externa, en
ambos sentidos, sin decidir política.

🗣️ **2 minutos:** Mapea datos (JSON a comando, registro a agregado), errores (excepción del driver a
error propio), ciclo de vida (conexiones, sesiones, clientes) y, a veces, políticas técnicas como
timeouts y reintentos. Todo eso queda fuera de la política, que es la razón de su existencia: cuando
cambie el proveedor o el framework, el cambio se concentra en él. Un adaptador de entrada además
valida forma y autentica; uno de salida conoce credenciales y formatos del recurso externo.

🔬 **El detalle:** Puede contener lógica técnica compleja, pero no debe convertirse en dueño de la
regla de negocio. Si en un adaptador aparece "si el total supera X, rechaza", la regla se ha
escapado del núcleo y ya no se prueba ni se reutiliza desde otras entradas.

### 4. 🟢 ¿Quién define el contrato de salida?

⏱️ **30 segundos:** El consumidor: el núcleo o el caso de uso que expresa la necesidad. El proveedor
se adapta en el borde, no al revés.

🗣️ **2 minutos:** Cuando lo define el consumidor, el contrato puede ser pequeño y semántico:
`authorize(operationId, amount)` con tres resultados posibles. Cuando lo define el proveedor, el
núcleo hereda su vocabulario, sus estados y sus errores. Es la diferencia práctica entre inversión
de dependencias y una interfaz decorativa. Si mañana hay un segundo proveedor, el contrato definido
por el consumidor no cambia; el definido por el primer proveedor probablemente sí.

🔬 **El detalle:** La ubicación exacta del archivo depende de los módulos, pero no debe dictarla el
SDK. Un buen ejercicio es escribir el puerto antes de leer la documentación del proveedor: lo que el
caso de uso necesita saber sale de ahí, y lo demás es trabajo del adaptador.

### 5. 🟢 ¿Por qué `StripePort` es un nombre sospechoso?

⏱️ **30 segundos:** Porque pone al proveedor dentro de la política: el núcleo ahora "sabe" que paga
con Stripe, y el contrato tenderá a parecerse a su API.

🗣️ **2 minutos:** Preferiría `PaymentGateway`, que nombra la capacidad; Stripe quedaría en el
adaptador `StripePaymentGateway`. El nombre no es cosmético: condiciona qué métodos se añaden
("Stripe tiene `createPaymentIntent`, pongámoslo"), qué tipos cruzan y qué pasa cuando llega un
segundo proveedor o una migración. Un puerto con nombre de proveedor suele acabar exponiendo sus
estados y códigos, y el caso de uso razona en términos de Stripe en vez de en términos de pago.

🔬 **El detalle:** Un nombre técnico puede ser correcto en un borde explícito —el adaptador, el
cliente interno, la configuración— pero no en el puerto del núcleo. La regla sirve también para
`KafkaPublisher` o `S3Storage` como puertos: describen el cómo, no el qué.

### 6. 🟢 ¿Qué diferencia hay entre request y command?

⏱️ **30 segundos:** El request pertenece al transporte: nombres de campos públicos, versión,
headers, formato. El command expresa una intención de aplicación con los datos necesarios para
ejecutarla.

🗣️ **2 minutos:** El adaptador convierte JSON, headers y path en un `CreateOrderCommand` sin
arrastrar HTTP al caso de uso: la clave de idempotencia sale de un header y entra como
`operationId`, el cliente sale del token y entra como identidad verificada, los campos de la v1 y la
v2 de la API acaban en el mismo comando. Por eso un consumidor de mensajes puede construir el mismo
comando desde otro formato, y el caso de uso no distingue quién lo invocó.

🔬 **El detalle:** Pueden tener campos parecidos sin tener la misma responsabilidad. Que hoy
coincidan no significa que evolucionen juntos: el request cambia cuando cambia la API pública; el
comando, cuando cambia la intención de negocio.

### 7. 🟢 ¿Qué significa que una conversación sea de negocio?

⏱️ **30 segundos:** Que describe una capacidad o una necesidad entendible por alguien del negocio
sin mencionar la tecnología: "autorizar un pago", "reservar inventario".

🗣️ **2 minutos:** `authorize(operationId, amount)` es una conversación de negocio; `postJson(url,
body)` o `saveRow(table, values)` son mecanismos. La diferencia se nota en lo que devuelven: una
conversación de negocio devuelve `Authorized`, `Rejected` o `UnknownResult`; un mecanismo devuelve
un status HTTP o un número de filas. Con la primera, el caso de uso decide con conceptos propios;
con la segunda, tiene que interpretar la tecnología.

🔬 **El detalle:** La semántica es lo que permite cambiar el adaptador sin cambiar el contrato. Si
para explicar un puerto hay que nombrar el protocolo, el puerto está describiendo el adaptador y no
la conversación.

### 8. 🟡 ¿Cuándo crearías una interfaz?

⏱️ **30 segundos:** Cuando marca una frontera real: hay una implementación sustituible, una prueba
aislada que la necesita o una conversación que debe quedar explícita.

🗣️ **2 minutos:** Crearía interfaces para los puertos de salida hacia recursos externos (base,
proveedor, reloj), porque las sustituyo en pruebas y pueden tener otra implementación. No la crearía
solo porque una clase tiene métodos públicos, ni para mappers, validadores o servicios de dominio
internos que nadie sustituye. Primero identificaría la razón de cambio: si la clase y su única
implementación cambian siempre juntas, la interfaz no separa nada.

🔬 **El detalle:** En Go la interfaz suele aparecer junto al consumidor y solo cuando hace falta,
porque la satisfacción es implícita. En Java se declara explícitamente y es fácil crearla por
hábito; ahí la disciplina es preguntar qué pierde el sistema si la interfaz no existe.

### 9. 🟡 ¿Cómo elegirías la granularidad de un port?

⏱️ **30 segundos:** Por capacidad y razón de cambio, buscando el contrato mínimo útil que el caso de
uso pueda explicar en una frase.

🗣️ **2 minutos:** Separaría operaciones que tienen consumidores distintos, errores distintos o
ritmos de cambio distintos: leer pedidos para un informe y guardar pedidos en una transacción pueden
ser dos puertos. Evitaría los dos extremos: un puerto por método, que obliga al caso de uso a
orquestar piezas artificiales, y una fachada universal, que lo acopla a todo lo que ofrece la
tecnología. Empezaría con lo que el caso de uso necesita hoy y partiría cuando aparezca una razón.

🔬 **El detalle:** La cohesión semántica importa más que el número de métodos. Un puerto con cinco
métodos que siempre cambian juntos es mejor que cinco puertos de uno que cambian por la misma razón.

### 10. 🟡 ¿Qué datos no deberían cruzar desde HTTP al núcleo?

⏱️ **30 segundos:** El request, los headers, los status codes, los objetos del framework y los
detalles de serialización. El núcleo recibe solo lo que necesita para decidir, con tipos propios.

🗣️ **2 minutos:** El adaptador convierte la identidad autenticada, los parámetros y el cuerpo en
tipos del caso de uso: un `Actor`, un `CreateOrderCommand`, un identificador de operación. No cruzan
`HttpServletRequest`, el `Authorization` crudo, la versión de la API, el `Accept-Language` ni un DTO
decorado con anotaciones de validación. Si la política necesita algo que hoy solo viene en un header
—el idioma para un mensaje, por ejemplo—, el adaptador lo extrae y lo pasa como dato con nombre
propio.

🔬 **El detalle:** Un actor autenticado puede cruzar como concepto propio, no como JWT. La diferencia
importa porque un job o un consumidor también invocan el caso de uso y no tienen JWT; si el núcleo
esperaba el token, esas entradas se saltan la autorización o la falsifican.

### 11. 🟡 ¿Por qué un adapter también traduce errores?

⏱️ **30 segundos:** Porque un timeout, un `404` o una excepción del proveedor no son automáticamente
errores de negocio, y el núcleo no debe conocer esos tipos.

🗣️ **2 minutos:** El adaptador de salida clasifica: un `404` del proveedor puede ser "pedido
desconocido" (negocio), un timeout puede ser "resultado incierto" (negocio, con consecuencias), una
credencial inválida es un fallo técnico que debe alertar a operación. Traduce a errores que el caso
de uso pueda manejar. Luego, el adaptador de entrada convierte los errores del núcleo a su
protocolo: `409` en HTTP, ACK con rechazo registrado en una cola, código de salida en una CLI. Cada
lado traduce una vez.

🔬 **El detalle:** La traducción no debe ocultar fallos operativos que requieren observabilidad.
Convertir cualquier excepción en "pago rechazado" es cómodo y peligroso: esconde incidentes y, en
pagos, puede afirmar algo falso sobre dinero que quizá sí se cobró.

### 12. 🟡 ¿Qué hace que un adapter sea más que un wrapper?

⏱️ **30 segundos:** La traducción de semántica, datos, errores y ciclo de vida. Un wrapper solo
cambia el nombre de las llamadas; un adaptador cambia el lenguaje.

🗣️ **2 minutos:** Un wrapper que renombra `stripe.charges.create` a `gateway.charge` con los mismos
parámetros y tipos no protege mucho: el siguiente cambio de Stripe atraviesa el wrapper sin
resistencia. Un adaptador mapea estados externos a conceptos propios (`requires_action` a
`UnknownResult`), convierte importes a `Money`, añade la clave de idempotencia, fija el timeout y
decide qué errores se reintentan. Esa lógica es la que absorbe el cambio externo.

🔬 **El detalle:** La ausencia de traducción no siempre es mala: puede indicar que la frontera no
compensa. Si un adaptador no traduce nada porque el recurso ya habla el lenguaje del núcleo, quizá
sobra el puerto, y lo honesto es simplificar en lugar de mantener un wrapper por simetría.

### 13. 🟡 ¿Cómo probarías un puerto de entrada?

⏱️ **30 segundos:** Invocando el contrato directamente con datos de negocio y dobles de los puertos
de salida, sin framework ni transporte.

🗣️ **2 minutos:** Para `CreateOrder` construiría el caso de uso con fakes en memoria de `Orders` y
del inventario, y probaría escenarios: pedido válido, stock insuficiente, idempotencia con la misma
operación, cliente sin permiso. Verificaría resultado, estado persistido e invariantes, no solo que
se llamó a `save`. El adaptador HTTP tendría sus propias pruebas de mapeo: que el JSON correcto
produce el comando esperado y que cada error produce el status y el cuerpo correctos.

🔬 **El detalle:** Una prueba del puerto no prueba serialización, routing ni autenticación. Son dos
anillos distintos, y confundirlos lleva a pruebas lentas que cubren el caso de uso a través de HTTP
y fallan por motivos que no tienen que ver con la regla.

### 14. 🟡 ¿Cómo probarías un adapter de salida?

⏱️ **30 segundos:** Con pruebas de integración contra el recurso real o un equivalente fiel, y
pruebas unitarias de traducción cuando la traducción tenga lógica propia.

🗣️ **2 minutos:** Para un adaptador de persistencia usaría una base de la misma familia que
producción (Testcontainers, por ejemplo) y comprobaría ida y vuelta: guardar y leer preserva estado,
versión y dinero; las restricciones se traducen a errores propios; las consultas de lista no
disparan N+1. Para un proveedor HTTP, un servidor simulado que devuelva respuestas reales, errores y
latencia, y comprobaría headers, timeout y mapeo de estados. El caso de uso no necesita levantar ese
entorno en cada prueba.

🔬 **El detalle:** Un fake en memoria cubre la semántica del puerto, no la compatibilidad con
PostgreSQL. Por eso conviene un test de contrato que ejecute las mismas expectativas contra el fake
y contra el adaptador real: si divergen, el fake miente.

### 15. 🟡 ¿Qué diferencia hay entre un port y un DTO?

⏱️ **30 segundos:** El puerto es un contrato de interacción: qué se puede pedir y qué se obtiene. El
DTO es una forma de transportar datos a través de una frontera.

🗣️ **2 minutos:** Un puerto de entrada usa un comando y un resultado propios; el adaptador HTTP usa
un request DTO y un response DTO para hablar con el cliente. Son piezas de lados distintos: el DTO
de HTTP no debe convertirse automáticamente en la API del núcleo, porque arrastraría anotaciones,
opcionales y versiones del contrato público. El puerto define la conversación; el DTO, la forma del
mensaje en un transporte concreto.

🔬 **El detalle:** A veces un objeto cumple ambos papeles en sistemas pequeños, y puede ser
aceptable. Pero son responsabilidades distintas con razones de cambio distintas, y la primera vez
que la API pública necesite un campo que el negocio no usa, conviene separarlos.

### 16. 🟡 ¿Cuándo un port es una abstracción falsa?

⏱️ **30 segundos:** Cuando repite la tecnología y no ofrece semántica independiente: mismos métodos,
mismos tipos, mismos errores que el recurso que envuelve.

🗣️ **2 minutos:** Si el puerto renombra cada método del SDK y devuelve sus tipos, el cambio externo
seguirá filtrándose al núcleo; solo se añadió un archivo. Lo mismo con un `Repository<T>` genérico
que expone `findAll`, `findBy(criteria)` y paginación del ORM: el caso de uso termina construyendo
consultas con vocabulario de base. Una abstracción falsa tiene todos los costes de un puerto
(indirección, mocks, mapeo) y ninguno de sus beneficios.

🔬 **El detalle:** Llamarlo "port" no corrige un contrato mal elegido. La prueba es imaginar el
segundo proveedor o la segunda base: si el puerto tendría que cambiar para acomodarlos, no estaba
abstrayendo la necesidad sino copiando la implementación.

### 17. 🟠 Tienes una interfaz `ExternalClient` con veinte métodos. ¿Qué revisarías?

⏱️ **30 segundos:** Quién la consume, qué métodos usa cada consumidor y qué capacidades de negocio
mezcla. Casi seguro es el API del proveedor disfrazado de puerto.

🗣️ **2 minutos:** Haría un inventario: qué caso de uso llama a qué métodos, qué errores maneja cada
uno, qué cambia junto. Luego dividiría por necesidad del núcleo —`PaymentGateway`,
`CustomerDirectory`, `ShippingQuotes`— con contratos pequeños y tipos propios. El cliente grande
puede seguir existiendo, pero dentro del adaptador, que es donde el proveedor puede exigir su forma.
Así cada caso de uso depende solo de lo que usa y sus dobles de prueba son pequeños.

🔬 **El detalle:** No dividiría mecánicamente por número de métodos: buscaría razones de cambio y
modos de fallo diferentes. Dos métodos que siempre se llaman juntos y fallan igual pertenecen al
mismo puerto aunque vengan de secciones distintas del SDK.

### 18. 🟠 HTTP y un consumidor de eventos comparten cinco campos, pero cambian sus errores. ¿Qué compartes?

⏱️ **30 segundos:** Compartiría un comando propio solo si la intención de negocio es la misma;
separaría request, esquema del mensaje, ACK y traducción de errores.

🗣️ **2 minutos:** Que coincidan cinco campos no significa que coincida la intención. Si ambos crean
un pedido con las mismas reglas, ambos adaptadores construyen el mismo `CreateOrderCommand` y el
caso de uso es uno. Lo que no se comparte es lo propio de cada transporte: HTTP responde `409` a un
stock insuficiente; el consumidor confirma el mensaje y registra el rechazo, o lo manda a la DLQ si
es ilegible. Cada adaptador conserva sus metadatos y su política de redelivery o de respuesta.

🔬 **El detalle:** Compartir structs por comodidad —usar el DTO HTTP como esquema del evento, o al
revés— filtra un protocolo en el otro. El día que la API pública cambie un nombre de campo, el
contrato con el otro sistema cambiará sin que nadie lo haya decidido.

### 19. 🟠 Un proveedor ofrece una operación que el negocio no necesita. ¿Dónde la ocultas?

⏱️ **30 segundos:** Dentro del adaptador o del cliente externo, fuera del puerto del núcleo. El
puerto solo expone lo que el caso de uso puede defender.

🗣️ **2 minutos:** Si el proveedor ofrece, por ejemplo, un "pre-chequeo de fraude" que el negocio no
ha pedido, no lo añado al puerto "por si acaso". El adaptador puede usarlo internamente si ayuda a
cumplir la capacidad (llamar a dos operaciones del proveedor para una autorización), pero el núcleo
sigue viendo solo `authorize`. Así el contrato refleja decisiones de negocio y no el catálogo del
proveedor.

🔬 **El detalle:** Esto permite sustituir el proveedor sin ampliar la política. Si la operación extra
hubiera entrado al puerto, el segundo proveedor tendría que emularla o el puerto tendría que
marcarla como opcional, y el núcleo empezaría a tener ramas por proveedor.

### 20. 🟠 El port de salida devuelve una entidad ORM. ¿Qué frontera se rompió?

⏱️ **30 segundos:** La del modelo de persistencia: cruzó al núcleo con sus anotaciones, su ciclo de
vida de sesión y sus relaciones lazy.

🗣️ **2 minutos:** El caso de uso ahora trabaja con un objeto que puede disparar consultas al tocar
una colección, que falla fuera de la transacción y cuya forma sigue al esquema. Una prueba de regla
necesita una sesión, y un cambio de columna puede romper una invariante. Introduciría un modelo de
dominio o un resultado propio y mapearía en el adaptador —`OrderRecord` separado de `Order`—,
siempre que ese coste proteja una evolución real: reglas relevantes, esquema que cambia a otro
ritmo, pruebas rápidas valiosas.

🔬 **El detalle:** La separación no es dogma: en un CRUD estable puede ser aceptable devolver la
entidad y documentar la excepción. Lo que no es aceptable es no saberlo, porque entonces el
siguiente desarrollador añade reglas a un objeto cuyo comportamiento depende de la sesión.

### 21. 🟠 Un test llama directamente al caso de uso. ¿Es un adapter?

⏱️ **30 segundos:** Puede considerarse un adaptador de entrada de prueba, aunque no necesite una
clase formal: es un driver más que invoca el puerto.

🗣️ **2 minutos:** Lo importante es que use el contrato y no detalles HTTP: construye un comando,
llama al caso de uso y verifica el resultado. En ese sentido cumple el papel de un adaptador:
traduce la intención del test a la conversación del núcleo. De hecho es el driver más simple
posible, y su existencia es evidencia de que el núcleo no depende del transporte. Si el test
necesitara construir un request HTTP para invocar la regla, el puerto de entrada no estaría bien
separado.

🔬 **El detalle:** Cockburn menciona los harnesses de prueba entre los primeros adaptadores de un
sistema hexagonal: la motivación original era poder ejecutar la aplicación desde pruebas
automatizadas igual que desde una UI.

### 22. 🟠 ¿Cómo diseñarías un port para una segunda implementación futura sin especular?

⏱️ **30 segundos:** Diseñándolo por la necesidad actual del caso de uso, con el contrato mínimo y en
términos de negocio, sin métodos para capacidades hipotéticas.

🗣️ **2 minutos:** La primera implementación revela la semántica real: qué resultados existen, qué
errores importan, qué datos hacen falta. Un contrato escrito en términos de negocio ya facilita una
segunda implementación, porque no hereda los detalles de la primera. Lo que no haría es añadir
métodos, parámetros opcionales o genéricos pensando en un proveedor imaginario: cada uno es código
que mantener y probar sin evidencia. Cuando la segunda implementación llegue, revelará qué faltaba,
y ese es el momento de ampliar.

🔬 **El detalle:** Una segunda implementación futura es evidencia posible, no permiso para un API
genérico. La excepción son los resultados de negocio que ya existen aunque el primer proveedor los
oculte, como el resultado incierto de un pago: modelarlos desde el principio no es especular, es no
mentir.

### 23. 🟠 ¿Qué harías si dos adapters necesitan reglas de traducción distintas?

⏱️ **30 segundos:** Mantendría la traducción dentro de cada adaptador y normalizaría solo el
contrato común que ambos entregan al núcleo.

🗣️ **2 minutos:** Dos proveedores de pago tienen estados, códigos y reintentos distintos; cada
adaptador traduce los suyos a `Authorized`, `Rejected` o `UnknownResult`. Esa diversidad es
justamente lo que el puerto absorbe. Si las semánticas divergen de verdad —uno admite autorizaciones
parciales y el otro no—, revisaría si siguen siendo la misma capacidad o si el negocio necesita dos
puertos, o un resultado nuevo en el contrato común que ambos puedan expresar.

🔬 **El detalle:** No escondas diferencias operativas importantes en una utilidad compartida. Un
`ErrorMapper` común para ambos proveedores parece reutilización, pero acopla dos traducciones que
cambian por motivos distintos y hace que un arreglo para uno rompa al otro.

### 24. 🟠 ¿Cómo defenderías pocos ports en un sistema grande?

⏱️ **30 segundos:** Por cohesión y razones de cambio, no por una cuota de simplicidad. Un sistema
grande no necesita automáticamente muchos puertos; necesita los que protegen algo.

🗣️ **2 minutos:** Un puerto amplio puede ser correcto si expresa una conversación cohesiva: todas
sus operaciones cambian juntas, fallan de forma parecida y tienen los mismos consumidores. Para
defenderlo mediría consumidores, errores, versiones y alternativas: si partirlo no reduce
dependencias ni simplifica pruebas, partirlo solo añade archivos. También explicaría qué fronteras
sí existen y por qué, porque "pocos puertos" solo es una virtud si los que hay están bien puestos.

🔬 **El detalle:** El tamaño del sistema no determina el número de interfaces. Lo que sí suele crecer
con el tamaño es el número de equipos y de razones de cambio, y ahí es donde aparecen los puertos
necesarios: en las costuras entre capacidades con dueños distintos.

---

## 04 · Hexagonal, Clean, Onion y capas

### 1. 🟢 ¿Qué regla comparten Hexagonal, Clean y Onion?

⏱️ **30 segundos:** Que la política debe quedar protegida de los detalles y que las dependencias de
código apuntan hacia ella. Cambia el dibujo; la regla es la misma.

🗣️ **2 minutos:** Hexagonal lo expresa con puertos definidos por la aplicación y adaptadores que
dependen de ellos; Onion, con anillos donde cada uno solo conoce a los interiores; Clean, con la
*Dependency Rule*: nada de un círculo interior puede nombrar algo de uno exterior. Las tres surgen
contra el mismo problema —la lógica de negocio atada a la base de datos y a la UI— y las tres llegan
a la misma solución: invertir el acoplamiento para que el detalle se adapte a la política.

🔬 **El detalle:** La regla tiene que reflejarse en imports y módulos, no solo en diagramas. Por eso
en entrevista conviene pasar pronto del nombre del estilo a la evidencia: qué no puede importar el
núcleo y cómo se comprueba.

### 2. 🟢 ¿Qué destaca Hexagonal?

⏱️ **30 segundos:** Puertos y adaptadores en las entradas y salidas de la aplicación, y la simetría
entre ambas: la base de datos es un adaptador más, igual que la UI.

🗣️ **2 minutos:** Cockburn la propuso para poder conducir la aplicación desde una UI, una prueba
automatizada o un batch, y conectarla a una base real o a una en memoria, sin cambiar el núcleo. Su
aportación es hacer visible que todas esas conversaciones son intercambiables y que ninguna está
"debajo" de la aplicación. En la práctica, pone el foco en el contrato de cada conversación y en
quién lo define.

🔬 **El detalle:** No impone seis puertos, ni capas internas, ni una estructura de carpetas. Dice
poco sobre cómo organizar el interior; por eso suele combinarse con ideas de DDD o de Clean para
estructurar dominio y casos de uso.

### 3. 🟢 ¿Qué destaca Onion?

⏱️ **30 segundos:** Capas concéntricas con el modelo de dominio en el centro y las dependencias
siempre hacia dentro; la infraestructura queda en el anillo exterior.

🗣️ **2 minutos:** Jeffrey Palermo la describió como reacción a la arquitectura en capas clásica,
donde el dominio dependía de la capa de acceso a datos. Onion pone modelo de dominio, servicios de
dominio y servicios de aplicación en anillos sucesivos, y deja la base, la UI y las pruebas fuera.
Ayuda a hablar de qué conoce cada anillo y a explicar por qué las interfaces de repositorio viven
dentro y sus implementaciones fuera.

🔬 **El detalle:** El diagrama es una guía, no una lista obligatoria de cuatro círculos. Un sistema
con dos anillos bien respetados cumple la idea; uno con cinco anillos y un dominio que importa el
ORM no.

### 4. 🟢 ¿Qué significa dependencia hacia adentro?

⏱️ **30 segundos:** Que los módulos externos dependen de contratos internos y no al revés: el
adaptador conoce el puerto; el puerto no conoce al adaptador ni a su framework.

🗣️ **2 minutos:** Si se borra el adaptador JPA, el núcleo sigue compilando; si se borra el núcleo,
el adaptador deja de compilar. Esa asimetría es la definición operativa. Hacia adentro significa
hacia lo más estable y lo más valioso para el negocio. En código se nota en los imports:
`infrastructure` importa `application` y `domain`; `domain` no importa nada del sistema salvo a sí
mismo y a bibliotecas estables.

🔬 **El detalle:** La dirección de dependencia y la dirección del flujo de ejecución pueden ser
distintas. En runtime, el caso de uso llama al adaptador de salida; en código, el adaptador depende
del puerto que el caso de uso define. Confundir ambas flechas es el error más común al dibujar.

### 5. 🟢 ¿Por qué el dibujo no garantiza la arquitectura?

⏱️ **30 segundos:** Porque los imports y los tipos reales pueden contradecirlo, y el compilador no
lee diagramas.

🗣️ **2 minutos:** Un proyecto puede tener carpetas `domain`, `application` e `infrastructure`
perfectamente alineadas con el dibujo y aun así importar JPA desde el dominio, devolver entidades
ORM desde los casos de uso o llamar al SDK del proveedor desde la regla. El diagrama expresa una
intención; el código es lo que se ejecuta y lo que cuesta cambiar. Los diagramas además envejecen:
nadie los actualiza en el PR que introduce el import prohibido.

🔬 **El detalle:** La fuente de verdad técnica son las dependencias verificables: reglas de módulos,
análisis de imports y pruebas que construyen el núcleo sin infraestructura. Un diagrama útil es el
que se puede comprobar contra esas reglas.

### 6. 🟢 ¿Qué riesgo tiene una arquitectura por capas?

⏱️ **30 segundos:** Que cada capa dependa de la de abajo y la política termine atada a la
infraestructura, porque "abajo" suele ser la base de datos.

🗣️ **2 minutos:** En el esquema controller → service → repository → base, el servicio importa el
repositorio concreto, el repositorio devuelve entidades ORM y el servicio razona con ellas. La regla
de negocio queda en medio de una cadena de detalles: para probarla hace falta la base, y para
cambiar la base hay que tocar la regla. Además, "service" tiende a convertirse en el lugar donde
cabe todo, sin frontera de negocio clara.

🔬 **El detalle:** Layered no es incorrecta por sí misma: si la capa de acceso a datos implementa
interfaces definidas por la capa de negocio, se cumple la misma regla que en hexagonal. Lo que la
hace riesgosa es que su dirección suele quedar implícita y, por defecto, apunta hacia los detalles.

### 7. 🟢 ¿Qué debe declarar una capa de infraestructura?

⏱️ **30 segundos:** Qué adaptador implementa, qué detalle encapsula y qué contrato del núcleo
cumple. Cada pieza de infraestructura debería poder explicarse con esas tres respuestas.

🗣️ **2 minutos:** También debe hacer visibles el mapeo (qué traduce entre modelo propio y formato
externo), los errores (qué excepciones técnicas convierte y en qué), el ciclo de vida (quién crea y
cierra clientes, pools y sesiones) y la configuración relevante (timeouts, credenciales, URLs). Todo
eso es conocimiento del detalle que el núcleo no debe tener, y concentrarlo en un lugar
identificable es lo que permite cambiarlo con un radio pequeño.

🔬 **El detalle:** "Infrastructure" no es permiso para contener cualquier lógica. Una capa de
infraestructura con reglas de negocio —descuentos calculados en el repositorio, validaciones en el
cliente HTTP— es un síntoma de que la política se escapó del núcleo.

### 8. 🟡 ¿Son equivalentes Hexagonal y Clean?

⏱️ **30 segundos:** Comparten la regla central, pero tienen énfasis y vocabulario distintos. Pueden
producir implementaciones prácticamente iguales.

🗣️ **2 minutos:** Hexagonal habla de puertos y adaptadores y enfatiza la simetría entre entradas y
salidas. Clean habla de círculos —entidades, casos de uso, adaptadores de interfaz, frameworks— y
formaliza la *Dependency Rule*, además de nombrar explícitamente los casos de uso como una capa. Un
sistema con dominio, casos de uso, puertos y adaptadores puede describirse con cualquiera de los dos
vocabularios sin mentir. La diferencia práctica está en qué conversación facilita cada uno.

🔬 **El detalle:** No conviene discutir marcas si el equipo no puede explicar sus dependencias. En
entrevista suma más decir "son compatibles; lo que verifico es que el núcleo no importe detalles"
que defender una etiqueta frente a otra.

### 9. 🟡 ¿Cuándo usarías el vocabulario de ports?

⏱️ **30 segundos:** Cuando necesitas explicar entradas, salidas y sustitución de adaptadores: varios
drivers para el mismo caso de uso, o varias implementaciones para una necesidad.

🗣️ **2 minutos:** Es especialmente útil para mostrar que una prueba, un batch o un consumidor de
mensajes pueden conducir la aplicación igual que HTTP, y que un proveedor externo puede cambiarse
detrás del mismo contrato. También ayuda en revisiones de código: "¿este tipo pertenece al puerto o
al adaptador?" es una pregunta concreta que el vocabulario de capas no plantea con tanta claridad.

🔬 **El detalle:** El vocabulario debe ayudar a revisar código, no solo a presentar diapositivas. Si
el equipo dice "port" pero no puede señalar cuál es el contrato y quién lo define, el término no
está aportando nada.

### 10. 🟡 ¿Cuándo el vocabulario de capas es suficiente?

⏱️ **30 segundos:** Cuando las capas tienen responsabilidades claras y la dirección de dependencias
no filtra detalles hacia la política.

🗣️ **2 minutos:** Para un sistema sencillo, con una entrada y una base, "presentación, aplicación,
dominio, infraestructura" puede ser más comunicable que introducir puertos y adaptadores, sobre todo
si el equipo ya lo usa. Lo que importa es que la capa de dominio no dependa de la de
infraestructura, y eso se puede lograr sin cambiar el vocabulario: interfaces de repositorio en la
capa de dominio o aplicación, implementaciones en infraestructura.

🔬 **El detalle:** Si "servicio" oculta varias razones de cambio, el vocabulario deja de ser
suficiente. El momento de introducir nombres más precisos es cuando el vocabulario actual ya no
permite distinguir qué es regla, qué es coordinación y qué es detalle.

### 11. 🟡 ¿Qué revisarías en un paquete llamado `service`?

⏱️ **30 segundos:** Qué política contiene, qué dependencias conoce y si en realidad es aplicación,
dominio o infraestructura con otro nombre.

🗣️ **2 minutos:** Revisaría imports (¿ORM, cliente HTTP, framework web?), entradas (¿recibe DTO de
request o comandos propios?), transacciones (¿dónde empiezan?), qué devuelve (¿entidades ORM?) y
cuánto acceso a datos hace directamente. Un `OrderService` puede ser un caso de uso limpio, un
servicio de dominio, un adaptador disfrazado o un god object con todo lo anterior. El nombre no es
evidencia de nada.

🔬 **El detalle:** Renombrar puede ayudar a comunicar la intención, pero no arregla el acoplamiento.
Primero se corrigen las dependencias; después, si hace falta, el nombre, para que refleje lo que el
código ya es.

### 12. 🟡 ¿Cómo demostrarías que las dependencias apuntan hacia adentro?

⏱️ **30 segundos:** Con reglas de módulos o de imports en el build, y con una prueba que construya y
ejecute el núcleo sin framework ni infraestructura.

🗣️ **2 minutos:** La primera evidencia es estructural: ArchUnit, dependency-cruiser o import-linter
fallan si el dominio importa infraestructura. La segunda es de comportamiento: una prueba del caso
de uso con fakes propios, sin contexto de Spring ni base. La tercera es de datos: revisar que los
tipos que cruzan los puertos sean del núcleo y no filas, DTO del proveedor o entidades ORM. Y la
cuarta es de composición: un solo lugar donde se conectan implementaciones a puertos.

🔬 **El detalle:** Una sola métrica no basta. Una regla de imports no ve filtraciones de datos; una
prueba aislada no ve imports que no se ejecutan en ese camino. Combinar estructura y comportamiento
es lo que da confianza.

### 13. 🟡 ¿Qué diferencia hay entre una frontera conceptual y un módulo compilable?

⏱️ **30 segundos:** La conceptual guía al equipo; el módulo compilable impide violaciones. La
primera depende de disciplina; la segunda, del build.

🗣️ **2 minutos:** Una carpeta `domain` documenta la intención, pero el compilador permite que
cualquier clase del mismo módulo importe cualquier otra. Un módulo de build separado —un artefacto
Maven, un paquete con dependencias declaradas— vuelve la frontera una restricción: si el módulo del
dominio no declara dependencia de JPA, no puede importarlo. Entre ambos extremos está la regla
automatizada en CI, que da casi el mismo efecto con menos estructura.

🔬 **El detalle:** No toda frontera necesita un módulo separado: añade configuración de build y
fricción al refactorizar. Pero una frontera crítica —el núcleo de pagos, por ejemplo— merece alguna
forma de enforcement automático, porque la disciplina se erosiona con cada persona nueva y cada
entrega urgente.

### 14. 🟡 ¿Por qué los anillos no son una arquitectura ejecutable?

⏱️ **30 segundos:** Porque son una representación. El código necesita contratos, módulos,
composición y reglas para que la representación sea cierta.

🗣️ **2 minutos:** El dibujo orienta qué puede conocer cada zona, pero no crea puertos, no decide qué
tipos cruzan ni evita imports. Dos equipos con el mismo diagrama de anillos pueden producir sistemas
opuestos: uno con un dominio limpio y otro con entidades ORM en todas partes. Lo ejecutable son las
decisiones concretas: esta interfaz la define el caso de uso, este mapper vive en el adaptador, esta
regla de build prohíbe este import.

🔬 **El detalle:** La arquitectura aparece en decisiones repetidas y verificables, no en el dibujo
inicial. Un buen diagrama es un resumen fiel de esas decisiones; si no lo es, lo que hay que
corregir primero es el código o el diagrama, no discutir el estilo.

### 15. 🟡 ¿Qué relación hay entre DIP y la regla de dependencias?

⏱️ **30 segundos:** Ambos promueven que las políticas no dependan de detalles concretos. La regla de
dependencias es DIP aplicado a la escala de la arquitectura.

🗣️ **2 minutos:** El principio de inversión de dependencias dice que los módulos de alto nivel no
deben depender de los de bajo nivel, sino ambos de abstracciones, y que las abstracciones no deben
depender de detalles. En hexagonal, el puerto es la forma práctica de aplicarlo: el núcleo controla
el contrato y el adaptador depende de él. La regla de dependencias extiende esa idea de clases
individuales a zonas enteras del sistema.

🔬 **El detalle:** No todo DIP exige una interfaz. Una función que recibe otra función, un `Protocol`
en Python o una interfaz implícita en Go cumplen el principio. Lo esencial es quién posee la
abstracción; la interfaz explícita es solo uno de los mecanismos.

### 16. 🟡 ¿Qué lenguaje usarías para explicar una migración gradual?

⏱️ **30 segundos:** Hablaría de conservar la política, introducir una costura y mover los detalles
detrás de ella por etapas, con el sistema funcionando en cada paso.

🗣️ **2 minutos:** Empezaría por un flujo con dolor real, escribiría pruebas de caracterización del
comportamiento actual, y crearía un puerto alrededor del código legado: el adaptador inicial puede
ser el propio código viejo envuelto. Después extraería la regla al núcleo y cambiaría adaptadores
cuando haya motivo. Términos útiles: *seam*, *strangler* interno, *branch by abstraction*. Todos
transmiten que no hay una gran reescritura.

🔬 **El detalle:** No hay que renombrar todas las carpetas antes de crear la primera costura útil.
Empezar por la reorganización del árbol es el error típico: cambia nombres, no dependencias, y
consume el crédito del equipo antes de entregar valor.

### 17. 🟠 Un equipo mezcla Clean, Onion y Hexagonal en una presentación. ¿Qué preguntas harías?

⏱️ **30 segundos:** Qué dependencias permite cada zona, qué cambio protege cada frontera y cómo se
verifica. Si las respuestas son coherentes, la mezcla es solo vocabulario.

🗣️ **2 minutos:** Mezclar términos no es grave si describen la misma regla: "casos de uso" de Clean,
"puertos" de Hexagonal y "dominio al centro" de Onion encajan bien. El problema aparece cuando cada
término se usa para una cosa distinta, o cuando nadie puede decir qué no puede importar el núcleo.
Preguntaría por una frontera concreta: qué import está prohibido, dónde se define el puerto de
pagos, dónde se construye el grafo. Si la respuesta es la misma para todos, el problema era nominal;
si no, es conceptual.

🔬 **El detalle:** Pediría un ejemplo de import prohibido y una composición real. Esos dos artefactos
resuelven en cinco minutos lo que una discusión de estilos no resuelve en una hora.

### 18. 🟠 Una capa `domain` importa un mapper de infraestructura. ¿Qué nombre del estilo lo detecta?

⏱️ **30 segundos:** Todos: viola la regla de dependencias hacia adentro, se llame *Dependency Rule*,
anillos de Onion o puertos de Hexagonal.

🗣️ **2 minutos:** El término cambia, pero el diagnóstico y la corrección son los mismos: el mapper
pertenece al borde, porque traduce entre el modelo propio y un formato externo. Lo movería al
adaptador, haría que el adaptador entregue al dominio objetos propios ya construidos y, si el
dominio usaba el mapper para crear objetos, le daría un constructor o una fábrica propia que no
conozca el formato externo.

🔬 **El detalle:** Verifica también que el modelo que recibe el dominio sea propio. A veces se mueve
el mapper y el dominio sigue recibiendo el DTO externo por otro camino; la dependencia de código
desaparece y la de datos sigue ahí.

### 19. 🟠 Un equipo quiere una única capa `application`. ¿Qué riesgo aceptas?

⏱️ **30 segundos:** Que mezcle casos de uso, reglas de dominio y adaptadores hasta volverse una
frontera sin significado.

🗣️ **2 minutos:** Para un servicio pequeño, una sola capa de aplicación con las reglas dentro puede
ser suficiente, y separar un dominio aparte sería ceremonia. Aceptaría el nombre si sus dependencias
están claras: no importa infraestructura, recibe comandos propios, depende de puertos. Separaría
dominio de aplicación cuando aparezcan razones de cambio distintas: invariantes ricas que conviene
probar solas, o casos de uso que coordinan varias entidades.

🔬 **El detalle:** La estructura mínima puede ser válida; la ambigüedad sostenida no. El riesgo real
es que "application" termine conteniendo también controllers y repositorios "porque todo es
aplicación", y eso ya no es una capa, es el proyecto entero.

### 20. 🟠 La empresa tiene un estándar de capas que no puedes renombrar. ¿Cómo preservas la regla?

⏱️ **30 segundos:** Mantendría los nombres corporativos y haría explícitos los contratos, los
imports permitidos y el punto de composición.

🗣️ **2 minutos:** La arquitectura no depende del branding. Puedo usar `service` como capa de
aplicación si no deja entrar el ORM al dominio, `repository` para las interfaces del núcleo y `dao`
para sus implementaciones. Lo que añadiría es una regla automatizada con esos nombres: `service` no
importa `dao`, `domain` no importa nada de infraestructura. Así el estándar se respeta y la
dirección se cumple.

🔬 **El detalle:** Documentaría el mapeo entre el estándar corporativo y los conceptos del equipo
—"nuestro `service` es el caso de uso; nuestro `repository` es el puerto de salida"— para que la
gente nueva no tenga que adivinarlo.

### 21. 🟠 El diagrama es correcto, pero los imports no. ¿Qué consideras fuente de verdad?

⏱️ **30 segundos:** El código y sus dependencias reales. El diagrama describe una intención que el
código ya no cumple.

🗣️ **2 minutos:** Decidiría cuál de los dos refleja la arquitectura deseada. Normalmente es el
diagrama, y entonces el trabajo es corregir los imports; a veces el código revela que la frontera
dibujada no tenía sentido, y entonces se corrige el diagrama. Lo que no aceptaría es que ambos
convivan como verdad simultánea, porque el equipo tomará decisiones con el diagrama y sufrirá las
consecuencias del código.

🔬 **El detalle:** Automatizaría la regla para que el dibujo no sea la única defensa. Una prueba de
arquitectura en CI hace que el diagrama y el código no puedan divergir sin que alguien lo decida
explícitamente.

### 22. 🟠 ¿Cómo decidirías si un adapter merece módulo separado?

⏱️ **30 segundos:** Por su volatilidad, su tamaño, su ciclo de vida y el riesgo de contaminar el
núcleo con sus dependencias.

🗣️ **2 minutos:** Un SDK crítico con muchas dependencias transitivas, o una base con un modelo de
persistencia propio y migraciones, merece aislamiento fuerte: así el núcleo no puede ni siquiera ver
sus clases. Un adaptador pequeño y estable, como un reloj o un generador de identificadores, no lo
necesita. También pesa quién lo mantiene: si otro equipo es dueño del adaptador, un módulo separado
hace explícita esa frontera organizativa.

🔬 **El detalle:** Un módulo separado es una herramienta de enforcement, no un trofeo. Cada módulo
añade configuración de build, versionado y fricción al refactorizar; se paga cuando la frontera es
crítica o está siendo violada.

### 23. 🟠 ¿Qué evidencia pedirías antes de llamar “Clean” a un sistema?

⏱️ **30 segundos:** Imports hacia adentro, núcleo ejecutable sin detalles y adaptadores conectados
desde un composition root. Sin esas tres, el nombre es decoración.

🗣️ **2 minutos:** Pediría una prueba de caso de uso aislado que corra sin framework ni base, una
regla de arquitectura en CI y un ejemplo reciente de cambio de infraestructura con radio acotado:
"cambiamos el cliente del proveedor y solo tocamos el adaptador". También revisaría qué tipos cruzan
los puertos: si son entidades ORM o DTO externos, el sistema tiene la forma de Clean pero no su
propiedad central.

🔬 **El detalle:** También buscaría que la separación no esconda un god service: casos de uso que
coordinan todo el sistema, o una capa de aplicación de miles de líneas. Clean no impide ese
problema; solo lo coloca en otra carpeta.

### 24. 🟠 ¿Cómo explicarías las diferencias en treinta segundos?

⏱️ **30 segundos:** "Hexagonal nombra puertos y adaptadores; Onion dibuja anillos alrededor del
dominio; Clean formaliza políticas y detalles con la *Dependency Rule*. Las tres exigen que las
dependencias apunten hacia la política."

🗣️ **2 minutos:** Después de esa frase, pasaría a un ejemplo concreto, porque el nombre importa
menos que el contrato y la composición: `CreateOrder` define `Orders`, el adaptador JPA lo
implementa, la configuración los conecta y una regla de build impide que el dominio importe JPA. Con
ese ejemplo, cualquiera de los tres vocabularios queda anclado a algo verificable, y la conversación
puede ir a trade-offs en lugar de a definiciones.

🔬 **El detalle:** Layered también puede compartir la regla si no convierte las capas en una cadena
hacia los detalles. Mencionarlo muestra que la diferencia no está en el nombre del estilo sino en la
dirección de las flechas.

---

## 05 · Cuándo no usarla y antipatrones

### 1. 🟢 ¿Cuál es la primera pregunta antes de añadir una frontera?

⏱️ **30 segundos:** ¿Qué cambio real protege? Si no hay una respuesta concreta —una regla volátil,
una segunda entrada, un proveedor inestable, una prueba que hoy es imposible—, la frontera es
sospechosa.

🗣️ **2 minutos:** Para responderla miro volatilidad de las reglas, número de entradas y salidas,
valor de probar el núcleo aislado y coste de un fallo. Cada frontera introduce tipos, mapeo,
indirección y pruebas; tiene que comprar algo a cambio. Una frontera que protege un cambio
observable se paga sola en el primer cambio; una que protege un cambio imaginario se paga todos los
días en navegación y mantenimiento sin devolver nada.

🔬 **El detalle:** La pregunta evita convertir la arquitectura en plantilla. Es la misma disciplina
que YAGNI aplicada a la estructura: no añadir flexibilidad hasta tener evidencia de que hace falta,
pero dejar la costura que permita añadirla barato.

### 2. 🟢 ¿Qué es sobreabstracción?

⏱️ **30 segundos:** Añadir abstracciones cuyo coste supera el cambio que protegen: interfaces,
mappers, módulos y capas que no aíslan ninguna dependencia real.

🗣️ **2 minutos:** El ejemplo típico es un CRUD de tres pantallas con controller, comando, handler,
puerto de entrada, caso de uso, entidad, mapper, puerto de salida, adaptador y configuración de DI:
diez lugares para cambiar una validación sencilla. Cada pieza es defendible en abstracto, pero
juntas multiplican la navegación, los mocks y el tiempo de incorporación de gente nueva, y no
protegen ningún cambio que el sistema vaya a sufrir.

🔬 **El detalle:** Se evalúa por evidencia, no por aversión a las interfaces. La misma estructura
puede ser sobreabstracción en un CRUD interno y protección necesaria en un flujo de pagos; lo que
cambia es el riesgo y la volatilidad.

### 3. 🟢 ¿Qué es un port espejo?

⏱️ **30 segundos:** Un puerto que copia el API de una tecnología sin expresar una necesidad propia:
mismos métodos, mismos tipos, mismos errores.

🗣️ **2 minutos:** `UserRepositoryPort` con `findAll`, `findById`, `save`, `deleteById` y paginación
de Spring Data, que devuelve las entidades del ORM, es un puerto espejo: el borde sigue dictando el
contrato, solo que ahora hay una interfaz más en medio. Tiene todos los costes de un puerto
—indirección, dobles de prueba, mantenimiento— y ninguno de sus beneficios, porque cambiar de
tecnología seguiría obligando a cambiar el contrato y a sus consumidores.

🔬 **El detalle:** Puede ser útil como paso de transición en una migración: primero se envuelve el
legado tal cual para tener una costura, luego se refina el contrato. Pero ese uso debe tener una
fecha o un criterio de salida, porque si no, la transición se vuelve la arquitectura.

### 4. 🟢 ¿Qué es un modelo anémico?

⏱️ **30 segundos:** Un modelo con datos y getters/setters pero sin comportamiento, mientras las
reglas de negocio viven dispersas en servicios que manipulan su estado desde fuera.

🗣️ **2 minutos:** El riesgo concreto es que cualquier código pueda poner un pedido en un estado
imposible porque la entidad no protege sus transiciones: un servicio lo marca pagado, otro lo
cancela, un job lo modifica con otra regla. Encontrar "la regla de cancelación" exige buscar en
varios servicios. Un modelo con comportamiento concentra esas transiciones en métodos como
`order.cancel()`, que validan el estado y fallan si la transición no es válida.

🔬 **El detalle:** No siempre es incorrecto: en sistemas con pocas reglas, un modelo de datos y
funciones cohesivas puede ser más claro. El contexto y la complejidad mandan, y el anémico no se
corrige añadiendo capas, sino moviendo invariantes junto al estado que protegen.

### 5. 🟢 ¿Qué significa infraestructura filtrada?

⏱️ **30 segundos:** Que tipos, errores o decisiones de infraestructura cruzan al núcleo: entidades
ORM, excepciones HTTP, DTO del proveedor, clientes del SDK.

🗣️ **2 minutos:** Cuando `CreateOrder` recibe un `ResponseEntity`, captura `SQLException` o decide
según el campo `status` del JSON del proveedor, la política ya conoce detalles externos. El efecto
es que cambiar esos detalles obliga a cambiar reglas y sus pruebas, y que las pruebas del núcleo
necesitan simular tecnología. Es el antipatrón que la arquitectura existe para evitar, y el más
fácil de introducir por comodidad en una entrega urgente.

🔬 **El detalle:** También puede filtrarse el esquema aunque los imports parezcan limpios: estados
con los literales de la base, importes en la unidad del proveedor, nulos con significado implícito.
Esa filtración de datos no la detecta ninguna regla de imports.

### 6. 🟢 ¿Qué es un god use case?

⏱️ **30 segundos:** Un caso de uso que coordina demasiadas capacidades y concentra reglas ajenas:
pedidos, pagos, inventario, notificaciones y facturación en un solo método.

🗣️ **2 minutos:** Suele reconocerse por el constructor (diez puertos inyectados), por la longitud y
por el historial: cualquier cambio de negocio lo toca. Es señal de límites mal definidos o de una
aplicación que se volvió monolítica dentro del hexágono. La arquitectura está formalmente bien —todo
depende de puertos—, pero el caso de uso tiene tantas razones de cambio que no protege nada y sus
pruebas son frágiles.

🔬 **El detalle:** Dividirlo por nombre no basta: partir `ProcessOrder` en `ProcessOrderPart1` y
`Part2` no ayuda. Hay que buscar razones de cambio y límites transaccionales: qué debe ser atómico,
qué puede pasar después, qué capacidad es dueña de cada dato. Eso suele revelar dos o tres casos de
uso más un proceso que los encadena.

### 7. 🟢 ¿Por qué una excepción debe tener fecha de revisión?

⏱️ **30 segundos:** Para que una decisión temporal no se vuelva dependencia permanente por olvido.
Sin fecha, "por ahora" significa "para siempre".

🗣️ **2 minutos:** Aceptar que el dominio use anotaciones del ORM, o que un caso de uso llame
directamente a un SDK, puede ser razonable hoy. Pero las condiciones que lo justificaron cambian: el
proveedor se vuelve inestable, llega una segunda entrada, las reglas empiezan a cambiar cada semana.
Una fecha de revisión y un dueño obligan a volver a mirar la decisión con esa nueva información, en
lugar de descubrir la dependencia cuando ya rompió algo.

🔬 **El detalle:** La fecha no obliga a eliminar la excepción; obliga a volver a decidir con
evidencia. Muchas excepciones se renuevan con razón. Lo que se evita es la excepción huérfana, que
nadie recuerda por qué existe y todos copian como si fuera la norma.

### 8. 🟡 ¿Cuándo un CRUD justifica hexagonal?

⏱️ **30 segundos:** Cuando tiene reglas valiosas o cambiantes, varias entradas o salidas, o riesgo
alto asociado a la infraestructura. El número de pantallas no decide.

🗣️ **2 minutos:** Un CRUD de datos regulados puede necesitar más aislamiento que un proceso complejo
interno y estable: si un error de validación tiene consecuencias legales, merece la pena que la
regla viva en un lugar probado y auditable. También lo justifica que la misma operación entre por
HTTP y por una importación masiva, o que los datos vengan de un proveedor cuyo formato cambia. Sin
esas fuerzas, un módulo directo es mejor opción.

🔬 **El detalle:** Justificaría cada puerto por un cambio protegido, no el hexágono completo en
bloque. Es frecuente que un CRUD necesite solo una frontera —hacia el proveedor volátil, o alrededor
de la regla regulada— y el resto pueda quedar simple.

### 9. 🟡 ¿Cuándo un adapter que delega sí aporta valor?

⏱️ **30 segundos:** Cuando encapsula un proveedor, mapea datos, controla ciclo de vida o marca una
frontera útil, aunque su código sea casi todo delegación.

🗣️ **2 minutos:** Un adaptador de pocas líneas puede ser valioso si mantiene el núcleo independiente
del SDK, concentra la configuración de timeouts y credenciales, traduce errores técnicos o
instrumenta las llamadas externas con métricas. La longitud del código no mide su valor; lo mide lo
que impide que cruce la frontera. Un adaptador que decide qué tipos y excepciones ve el núcleo
aporta aunque su cuerpo sea una llamada.

🔬 **El detalle:** Si solo cambia el nombre del método y deja pasar tipos y errores del proveedor,
probablemente sobra. La pregunta útil es: si se borra, ¿qué detalle empezaría a aparecer en el
núcleo? Si la respuesta es "ninguno", es un wrapper.

### 10. 🟡 ¿Cómo detectarías una interfaz sin frontera?

⏱️ **30 segundos:** Preguntando qué implementación alternativa, qué consumidor independiente o qué
razón de cambio protege. Si no hay ninguna, no marca una frontera.

🗣️ **2 minutos:** Revisaría si tiene una sola implementación que siempre cambia a la vez que la
interfaz, si vive en el mismo paquete que su implementación, si solo existe para poder mockear una
clase concreta y si su contrato expresa una conversación o es la lista de métodos públicos de la
clase. En esos casos la simplificaría: la clase concreta se puede usar directamente y, en la mayoría
de lenguajes, sustituir en pruebas igual de bien.

🔬 **El detalle:** La prueba aislada por sí sola no justifica cualquier interfaz. Si la clase es pura
y determinista, se prueba sin dobles; si depende de algo externo, lo que merece interfaz es esa
dependencia externa, no la clase que la usa.

### 11. 🟡 ¿Qué coste tiene un DTO que cruza hasta el dominio?

⏱️ **30 segundos:** Ata la política al transporte: un cambio de presentación, versión o nombre de
campo público puede alterar reglas de negocio.

🗣️ **2 minutos:** El ahorro es visible —no hay mapper—, pero el coste se traslada a acoplamiento,
pruebas y evolución. El dominio ahora conoce anotaciones de validación y serialización, recibe
campos opcionales de la API que no le importan y cambia cuando cambia el contrato HTTP. Además,
otras entradas (una cola, un job) tienen que construir un DTO de HTTP para invocar la regla, lo que
es incómodo y engañoso.

🔬 **El detalle:** Un DTO interno compartido puede ser válido si el borde no es real: servicio
interno, un solo cliente, API que evoluciona junto al dominio. Lo que importa es nombrar la
decisión, para que el día que la API se haga pública alguien sepa que hay que separar.

### 12. 🟡 ¿Por qué el modelo anémico no se juzga solo por el nombre?

⏱️ **30 segundos:** Porque algunos modelos son deliberadamente simples y las reglas viven en
funciones cohesivas y bien ubicadas. Lo que preocupa es la dispersión, no la forma.

🗣️ **2 minutos:** Un `Order` sin métodos con un módulo `order_rules` que contiene todas las
transiciones y se usa desde todos los casos de uso puede proteger las invariantes tan bien como un
modelo rico. En cambio, un modelo con muchos métodos que convive con servicios que modifican sus
campos directamente es anémico en la práctica. Me preocupa la dispersión de invariantes y
mutaciones, no la ausencia de métodos en la clase.

🔬 **El detalle:** La prueba es si puedes localizar y proteger la política: señalar el único lugar
donde se decide si un pedido puede cancelarse, y comprobar que nadie más puede cambiar ese estado
saltándoselo.

### 13. 🟡 ¿Qué diferencia hay entre simplificar y saltarse una frontera?

⏱️ **30 segundos:** Simplificar conserva la decisión importante —la dirección de dependencias y la
regla en su lugar— con menos piezas. Saltarse la frontera mezcla política con detalle sin control.

🗣️ **2 minutos:** Un módulo directo, con la regla en una función pura y el acceso a datos en otra,
es simplificación sana: menos tipos, misma dirección. Un controller con reglas, SQL y llamadas al
proveedor embebidas es saltarse la frontera: funciona hoy, pero cualquier cambio queda sin contener
y ninguna parte se prueba sola. La primera opción se puede hacer crecer cuando haga falta; la
segunda obliga a desenredar antes de poder crecer.

🔬 **El detalle:** La simplicidad buena es explícita y reversible: está documentada como decisión y
deja una costura por donde introducir la frontera. La mala es implícita y cada día más cara de
revertir.

### 14. 🟡 ¿Qué prueba conservarías al eliminar un port?

⏱️ **30 segundos:** La prueba de comportamiento del caso de uso y la de integración del detalle
relevante. Se retira ceremonia, no cobertura.

🗣️ **2 minutos:** Si elimino una interfaz de repositorio porque nunca tuvo otra implementación,
conservo la prueba que verifica la regla —ahora quizá contra una base real o un fake de la clase
concreta— y la prueba de integración que valida el SQL. Si al quitar el puerto la política queda
mezclada con el detalle, primero conservaría una prueba que revele ese acoplamiento, para que el
siguiente cambio no lo empeore sin que nadie lo note.

🔬 **El detalle:** Los tests son evidencia de la frontera, no un sustituto de ella. Borrar un puerto
y sus pruebas a la vez hace invisible la decisión; borrar el puerto y conservar las pruebas deja
claro que el comportamiento sigue protegido.

### 15. 🟡 ¿Qué parte de la arquitectura puede ser gradual?

⏱️ **30 segundos:** Casi toda: el mapeo, los puertos y los módulos pueden introducirse donde el
cambio paga el coste, uno a uno.

🗣️ **2 minutos:** Se puede empezar por una regla volátil —extraerla del controller a un caso de uso
con su prueba— o por una integración problemática —poner el proveedor detrás de un puerto—, y dejar
el resto como está. Cada paso deja el sistema funcionando y mejora un punto de dolor concreto.
Después se expande la frontera con pruebas cuando el siguiente dolor lo justifique. Lo que no es
gradual es la dirección: una vez decidida, no se negocian excepciones sin fecha.

🔬 **El detalle:** No hace falta migrar todo el sistema para obtener una costura útil. De hecho, las
migraciones completas planificadas desde el principio suelen fracasar por tamaño; las graduales
sobreviven porque cada paso entrega valor por sí mismo.

### 16. 🟡 ¿Cómo medirías si una abstracción paga su coste?

⏱️ **30 segundos:** Comparando antes y después: radio de los cambios, velocidad y fiabilidad de las
pruebas, mapeos añadidos, errores de integración y dependencias del núcleo.

🗣️ **2 minutos:** Buscaría evidencia concreta: cambios del proveedor que ahora solo tocan un
adaptador, pruebas de reglas que pasaron de minutos a milisegundos, incidentes por datos externos
que desaparecieron porque el mapper los valida. Del lado del coste, contaría archivos tocados por
cambio funcional, tiempo de incorporación y mocks que se rompen por refactorizaciones. No mediría
cantidad de clases ni porcentaje de interfaces: no dicen nada del valor.

🔬 **El detalle:** La métrica debe relacionarse con el riesgo que motivó la frontera. Si la
abstracción se introdujo para cambiar de proveedor, la métrica es cuánto costó el cambio de
proveedor; si nunca se cambió en dos años, esa es también una respuesta.

### 17. 🟠 Diseña la solución para un CRUD interno de tres pantallas.

⏱️ **30 segundos:** Un módulo claro, con las funciones de negocio separadas de HTTP, persistencia
directa y pruebas de lo que tenga reglas. Sin puertos espejo ni mappers idénticos.

🗣️ **2 minutos:** Handlers que validan la forma y llaman a funciones de aplicación; esas funciones
contienen las pocas reglas que existan y usan el acceso a datos del framework directamente; pruebas
unitarias de las reglas y una prueba de integración por pantalla. Dejaría una frontera de módulo —el
CRUD no importa otros módulos del sistema ni al revés— y una nota de revisión con las señales que
harían crecer la estructura: más entradas, reglas que cambian, un proveedor externo.

🔬 **El detalle:** Si maneja datos regulados o sensibles, subiría la estructura por el coste del
fallo: validación centralizada y probada, auditoría explícita, actor en cada operación. El tamaño no
decide; el riesgo sí.

### 18. 🟠 Un equipo quiere copiar el hexágono en cada módulo. ¿Qué objeciones pondrías?

⏱️ **30 segundos:** Que una plantilla uniforme no demuestra ninguna frontera valiosa, y que cada
pieza copiada sin necesidad es coste sin retorno.

🗣️ **2 minutos:** Pediría justificar puertos, mappers y adaptadores módulo por módulo, y permitiría
variación proporcional al riesgo: el módulo de pagos con fronteras completas, el de configuración de
preferencias con un diseño directo. La uniformidad tiene un atractivo —todo se parece, cualquiera
navega cualquier módulo— pero cuando la estructura no corresponde al problema, el equipo aprende a
ignorarla y las fronteras importantes pierden credibilidad.

🔬 **El detalle:** Un *chassis* técnico común (build, logging, configuración, health checks, reglas
de dependencia) sí ayuda y se puede uniformar. Lo que no debe imponer es dominio artificial: casos
de uso vacíos y puertos sin consumidor que parecen guía y solo son ruido.

### 19. 🟠 Un proveedor cambia cada mes y las reglas casi nunca. ¿Qué abstraes?

⏱️ **30 segundos:** El proveedor, sus errores y sus datos, detrás de un puerto pequeño definido por
lo que el negocio necesita. La volatilidad externa es la que justifica la frontera aquí.

🗣️ **2 minutos:** Aunque la política sea estable, cada cambio mensual del proveedor tocaría el caso
de uso si el SDK estuviera dentro. Con un puerto y un adaptador, el cambio mensual se concentra en
un archivo, sus pruebas de integración y quizá el mapeo de nuevos estados. El dominio puede quedar
muy simple, incluso sin separación rica, porque no es donde está el riesgo. Evitaría llevar el SDK
al caso de uso y también evitaría abstraer lo que no cambia.

🔬 **El detalle:** El puerto debe representar la capacidad que el negocio usa, no el catálogo del
proveedor. Si el puerto copia el API de este mes, el cambio del mes siguiente lo atravesará igual.

### 20. 🟠 Las reglas cambian cada semana, pero solo hay una base de datos. ¿Qué proteges?

⏱️ **30 segundos:** La política y los casos de uso. No invento una abstracción de base de datos si
la base no cambia; protejo el lugar donde está la volatilidad.

🗣️ **2 minutos:** Necesito que las reglas se cambien y se prueben rápido: dominio sin framework,
casos de uso con pruebas en memoria, reglas en un lugar identificable. La persistencia puede quedar
con un puerto mínimo y un adaptador directo, sin repositorios genéricos. Lo que sí mantengo es que
el modelo no sea una proyección accidental del esquema: si las reglas viven en entidades ORM, cada
cambio de regla arrastra anotaciones, migraciones y sesiones.

🔬 **El detalle:** La frecuencia de cambio de la regla pesa más que la cantidad de tecnologías. Un
sistema con una sola base y reglas volátiles necesita más aislamiento del núcleo que uno con cinco
integraciones y reglas congeladas.

### 21. 🟠 Un port tiene quince métodos y tres consumidores. ¿Cómo lo dividirías?

⏱️ **30 segundos:** Por capacidades usadas y razones de cambio, no por un número fijo de métodos.
Empezaría midiendo qué usa cada consumidor.

🗣️ **2 minutos:** Haría la matriz consumidor × método. Si cada consumidor usa un subconjunto
distinto, cada subconjunto es candidato a puerto propio. Miraría también qué errores maneja cada
grupo y si algunas operaciones pertenecen a otro contexto de negocio —por ejemplo, métodos de
informes mezclados con métodos transaccionales—. Luego dividiría y dejaría que el adaptador
implemente varios puertos si el recurso es el mismo.

🔬 **El detalle:** La segregación reduce acoplamiento y simplifica los dobles de prueba, pero no se
divide si crea contratos artificiales: si los tres consumidores usan casi los mismos métodos por las
mismas razones, un puerto grande y cohesivo es correcto.

### 22. 🟠 El equipo eliminó los adapters y ahora el ORM llega al dominio. ¿Qué migras primero?

⏱️ **30 segundos:** Una capacidad crítica y su modelo propio, empezando por una prueba de
comportamiento que fije lo que hace hoy.

🗣️ **2 minutos:** Elegiría el flujo con más riesgo o más cambios (pedidos o pagos), escribiría
pruebas de caracterización, introduciría un puerto mínimo con los métodos que ese flujo usa, un
adaptador de persistencia que haga el mapeo al borde y un modelo de dominio sin anotaciones. Después
repetiría por orden de riesgo. Cada paso deja el sistema funcionando y reduce un punto de dolor
medible.

🔬 **El detalle:** No empezaría renombrando carpetas ni moviendo paquetes sin una dependencia
concreta que invertir. Esa reorganización cambia nombres, consume tiempo y deja el ORM donde estaba;
el progreso se mide en imports eliminados del núcleo.

### 23. 🟠 ¿Cómo presentarías una excepción arquitectónica en una revisión?

⏱️ **30 segundos:** Con cinco datos: motivo, coste aceptado, alcance, dueño y fecha o señal de
revisión.

🗣️ **2 minutos:** Por ejemplo: "el dominio de catálogo usa anotaciones JPA; motivo: CRUD estable sin
reglas relevantes; coste: pruebas de catálogo necesitan base; alcance: solo este módulo; dueño:
equipo de catálogo; revisión: si aparece una segunda fuente de productos o una regla de precios".
Explicaría por qué la frontera no paga ahora y qué señal dispararía la reevaluación. Eso convierte
la excepción en decisión y evita que se copie a otros módulos por imitación.

🔬 **El detalle:** La excepción debe ser visible cerca del código: un ADR enlazado, un comentario en
la regla de arquitectura que la permite, o una exclusión explícita con nombre. Si solo vive en la
memoria de quien la aprobó, desaparece con esa persona.

### 24. 🟠 ¿Qué señal indica que una simplificación dejó de ser segura?

⏱️ **30 segundos:** Que el mismo detalle aparezca en varias entradas, que las reglas se dupliquen o
que un cambio obligue a tocar partes no relacionadas.

🗣️ **2 minutos:** También miraría pruebas cada vez más lentas porque todo necesita la base, un
proveedor que cambia y rompe reglas, incidentes cuyo radio crece, y conversaciones del tipo "no
toques eso, que afecta a lo otro". Cuando aparecen, es momento de introducir una frontera
exactamente donde duele, no en todo el sistema: extraer esa regla, aislar ese proveedor, separar ese
modelo.

🔬 **El detalle:** La señal es el cambio real, no el tamaño nominal del repositorio. Un sistema
grande y estable puede seguir simple; uno pequeño con reglas que se duplican ya necesita una
frontera.

---

## 06 · Simulación de entrevista

### S1. 🟢 ¿Qué cambio intenta proteger primero una arquitectura hexagonal?

⏱️ **30 segundos:** El cambio de la política de negocio frente a los cambios de transporte,
persistencia o proveedores, y viceversa: que cada uno pueda ocurrir sin arrastrar al otro.

🗣️ **2 minutos:** Empiezo por una regla valiosa —por ejemplo, que un pedido sin stock no se cree o
que un pago incierto no se dé por rechazado— y observo qué detalles la obligan hoy a cambiar: el
controller, el ORM, el SDK. La arquitectura crea una frontera para que esos detalles se traduzcan
fuera y la regla quede en un lugar donde se lee, se prueba y se cambia sola. En entrevista conviene
decirlo con un ejemplo, no con "desacoplar".

🔬 **El detalle:** No promete que ningún archivo cambie; reduce el radio de cambio entre razones
distintas. Un cambio que afecta a la vez a la regla y al contrato externo seguirá tocando ambos,
pero en lugares separados y con pruebas separadas.

### S2. 🟢 ¿Cómo distingues política de detalle en una revisión de código?

⏱️ **30 segundos:** Pregunto si la decisión seguiría existiendo al cambiar framework, protocolo o
proveedor. Si sí, es política; si desaparece con la tecnología, es detalle.

🗣️ **2 minutos:** "Un pedido cancelado libera su reserva" sobrevive a cambiar de PostgreSQL a otra
base: política. "Reintentar tres veces con backoff si el proveedor devuelve `503`" desaparece si
cambia el proveedor: detalle, aunque sea lógica. En la revisión busco dónde está cada una: la
política debería estar en dominio o casos de uso, sin tipos del framework; el detalle, en
adaptadores, sin decisiones de negocio. Cuando veo un `if` de negocio en un adaptador o un tipo
técnico en una regla, ahí está el problema.

🔬 **El detalle:** La ubicación en una carpeta no decide la naturaleza de una dependencia. Una clase
en `domain` puede contener detalle, y una en `infrastructure` puede estar decidiendo política; la
revisión mira el contenido, no la ruta.

### S3. 🟢 ¿Qué evidencia mínima muestra que el núcleo no depende de HTTP?

⏱️ **30 segundos:** Que el caso de uso se ejecute con datos propios, sin construir una petición ni
una respuesta HTTP, y que su paquete no importe nada del framework web.

🗣️ **2 minutos:** Una prueba que invoca el puerto de entrada directamente con un comando y comprueba
el resultado es la evidencia de comportamiento. La regla de imports que prohíbe al núcleo depender
del framework web es la evidencia estructural. Y si existe otro driver —un consumidor de mensajes o
una CLI— que traduce la misma intención, es la evidencia de uso real. Con las dos primeras basta
para afirmarlo; la tercera demuestra que la separación ya se está aprovechando.

🔬 **El detalle:** Eso no prueba todas las fronteras, pero elimina una dependencia concreta. El
núcleo puede seguir dependiendo del ORM o del proveedor; cada frontera tiene su propia evidencia.

### S4. 🟢 ¿Quién debe definir un puerto de salida?

⏱️ **30 segundos:** El consumidor del núcleo que necesita la capacidad. El caso de uso dice qué
necesita; el adaptador se adapta.

🗣️ **2 minutos:** `AuthorizePayment` define la conversación mínima con el proveedor —autorizar un
importe con una clave de operación y recibir `Authorized`, `Rejected` o `UnknownResult`— y el
adaptador traduce el API del proveedor a ese contrato. Así el contrato es pequeño, habla el lenguaje
del negocio y no cambia cuando cambia el proveedor. Si lo define el proveedor, el núcleo hereda su
vocabulario, sus estados y su ritmo de cambio.

🔬 **El detalle:** Si el SDK dicta los métodos, los tipos y los errores del puerto, la inversión es
solo nominal: hay una interfaz, pero el acoplamiento sigue apuntando hacia afuera.

### S5. 🟢 ¿Por qué el flujo de ejecución y la dirección de dependencias pueden apuntar distinto?

⏱️ **30 segundos:** Porque el núcleo llama a un contrato que el detalle implementa. En ejecución, el
control va hacia afuera; en código, la dependencia apunta hacia adentro.

🗣️ **2 minutos:** En runtime, `CreateOrder` termina ejecutando código del adaptador JPA. En
compilación, `CreateOrder` solo conoce `Orders`, y es el adaptador el que importa `Orders` para
implementarlo. Esa separación entre "quién llama a quién" y "quién conoce a quién" es la inversión
de dependencias. Sin ella, el flujo y la dependencia apuntan igual —del núcleo al detalle— y el
detalle manda sobre la política.

🔬 **El detalle:** La composición construye el grafo sin invertir la regla: el composition root
conoce ambos lados, conecta la implementación al contrato y deja que el flujo recorra el camino en
ejecución.

### S6. 🟢 ¿Qué coste aparece al separar request, command y modelo de dominio?

⏱️ **30 segundos:** Mapeo, más tipos que mantener y pruebas de traducción. Cada campo nuevo cruza
tres formas.

🗣️ **2 minutos:** Ese coste compra evolución independiente: el contrato externo cambia por versión o
por cliente, la intención de aplicación cambia por negocio y el modelo de dominio cambia por reglas.
Cuando esos tres cambian por motivos distintos, tenerlos separados evita que un cambio de API toque
invariantes o que un cambio de regla rompa clientes. También permite que otras entradas construyan
el comando sin conocer HTTP.

🔬 **El detalle:** Si no hay diferencia real entre las tres formas y no se espera, pueden ser
ceremonia. Lo que casi nunca compensa es el atajo en la salida: exponer el modelo de persistencia
como respuesta pública.

### S7. 🟢 ¿Qué hace que un adaptador sea una frontera y no solo un wrapper?

⏱️ **30 segundos:** Que traduzca semántica, datos o errores entre contratos con dueños distintos. Un
wrapper solo cambia nombres.

🗣️ **2 minutos:** Un adaptador de pagos convierte los estados del proveedor en los tres resultados
del núcleo, los importes a `Money`, los timeouts en resultado incierto y los errores de credencial
en fallos técnicos observables. Eso protege al núcleo de estados, nombres y fallos ajenos. Un
wrapper que expone `charge(params)` con los mismos parámetros y tipos que el SDK solo añade un salto
de navegación; el siguiente cambio del proveedor lo atraviesa sin resistencia.

🔬 **El detalle:** También puede concentrar ciclo de vida y observabilidad técnica: el cliente
reutilizable, el pool, las métricas de latencia y la redacción de datos sensibles en logs. Esas
responsabilidades también justifican que exista aunque la traducción sea pequeña.

### S8. 🟡 ¿Cómo decides si una interfaz nueva compensa?

⏱️ **30 segundos:** La relaciono con un cambio, un consumidor, una prueba o una capacidad que deba
quedar protegida. Si no puedo nombrar ninguno, no compensa.

🗣️ **2 minutos:** Una segunda implementación hipotética no basta como argumento. Busco volatilidad
real (el proveedor cambió dos veces este año), necesidad de prueba (la regla depende del tiempo o de
la red) o frontera de propiedad (otro equipo implementa el adaptador). Luego comparo el ahorro con
el coste: navegación, mocks, mapeo y la tentación de mockear en todas partes. Si el balance es
dudoso, empiezo sin interfaz y la introduzco cuando aparezca la segunda razón.

🔬 **El detalle:** En Go o Python el mecanismo cambia —interfaz implícita, `Protocol`, una función
como parámetro—, pero la justificación no. El coste de una abstracción es más cognitivo que
sintáctico.

### S9. 🟡 ¿Qué revisarías si todos los paquetes tienen carpetas `domain`, `application` e `infrastructure`?

⏱️ **30 segundos:** Las dependencias reales entre esas carpetas y si cada frontera protege algo en
cada paquete, o si la simetría es solo visual.

🗣️ **2 minutos:** La estructura uniforme puede ocultar imports hacia afuera (un `domain` que importa
JPA), puertos espejo creados para llenar la carpeta `application`, o módulos triviales con cinco
carpetas para un CRUD. Verificaría con una regla de imports, revisaría qué tipos cruzan los puertos,
dónde se compone el grafo y si hay pruebas del núcleo sin infraestructura. Y preguntaría, módulo por
módulo, qué cambio protege esa estructura.

🔬 **El detalle:** La arquitectura es una propiedad de las relaciones entre piezas, no del árbol de
directorios. Dos proyectos con el mismo árbol pueden tener arquitecturas opuestas.

### S10. 🟡 ¿Cuándo un tipo compartido entre núcleo e infraestructura es aceptable?

⏱️ **30 segundos:** Cuando es estable, neutral y no arrastra semántica del detalle: un
identificador, un tipo de dinero propio, una fecha de la biblioteca estándar.

🗣️ **2 minutos:** El adaptador necesita conocer los tipos del núcleo para traducir, así que
compartir hacia adentro es inevitable y correcto. El problema es compartir hacia afuera: una entidad
ORM con lazy loading y anotaciones, o un DTO del proveedor, no son neutrales, porque su forma y su
comportamiento los decide la tecnología. Un `OrderId` o un `Money` definidos en el núcleo y usados
por el adaptador son la forma normal de trabajar.

🔬 **El detalle:** Documento las excepciones que reduzcan ceremonia sin ocultar acoplamiento: por
ejemplo, usar un tipo de UUID de una librería estándar en lugar de envolverlo. La prueba es si ese
tipo podría cambiar por razones ajenas al negocio.

### S11. 🟡 ¿Qué diferencia hay entre aislar una dependencia y eliminarla?

⏱️ **30 segundos:** Aislarla limita quién la conoce; no hace que deje de existir. El sistema sigue
necesitando la base, el broker o el proveedor.

🗣️ **2 minutos:** Con un puerto y un adaptador, el conocimiento del detalle queda en un borde: si
cambia, cambia un archivo y sus pruebas. Pero el detalle sigue teniendo latencia, fallos, versiones
y costes de operación, y el adaptador tiene que manejarlos. Prometer que hexagonal "elimina la
dependencia de PostgreSQL" es falso; lo verdadero es que el núcleo no la conoce y que sustituirla
cuesta un adaptador nuevo más una migración de datos.

🔬 **El detalle:** La operación del detalle sigue siendo un coste real. Aislar la base no evita tener
que diseñar índices, migraciones y copias de seguridad; solo evita que esas decisiones cambien las
reglas de negocio.

### S12. 🟡 ¿Cómo sabes si un puerto está diseñado desde el negocio?

⏱️ **30 segundos:** Porque sus nombres, datos y errores describen la necesidad del consumidor y se
entienden sin conocer la tecnología que lo implementa.

🗣️ **2 minutos:** `ReserveInventory` con un resultado `Reserved` o `InsufficientInventory` comunica
intención; `InventorySdkClient.executeV2(request)` con un código de estado reproduce al proveedor.
Otra prueba práctica: escribir la prueba del caso de uso con un fake del puerto. Si el fake se
escribe en diez líneas con vocabulario de negocio, el puerto está bien; si hay que simular
paginación, cabeceras o reintentos, está describiendo el detalle.

🔬 **El detalle:** No fuerzo vocabulario de negocio sobre una utilidad puramente técnica. Un puerto
`Clock` o `IdGenerator` es técnico y está bien que lo sea; lo importante es que exprese lo que el
núcleo necesita y nada más.

### S13. 🟡 ¿Qué papel cumple el composition root en la regla de dependencias?

⏱️ **30 segundos:** Conecta implementaciones externas con contratos internos en un borde: es el
único lugar que conoce ambos lados.

🗣️ **2 minutos:** Allí se deciden el ciclo de vida (qué es singleton, qué es por petición), la
configuración (URLs, timeouts, credenciales validadas al arrancar) y el wiring (qué adaptador
satisface cada puerto en cada entorno). El caso de uso no busca dependencias en un contenedor global
ni lee variables de entorno; las recibe por constructor. Eso permite que el núcleo compile sin
infraestructura y que las pruebas construyan el mismo caso de uso con fakes.

🔬 **El detalle:** La DI automática puede implementar ese ensamblaje, pero no sustituye su diseño. Si
nadie puede decir dónde se decide qué implementación se usa, el composition root existe igual, solo
que repartido e invisible.

### S14. 🟡 ¿Qué prueba aporta más evidencia que un mock por cada clase?

⏱️ **30 segundos:** Una prueba de la política aislada con fakes que se comportan, y una prueba de
integración por cada frontera real contra el recurso de verdad.

🗣️ **2 minutos:** La primera verifica reglas sin infraestructura y comprueba resultados y estado, no
llamadas. La segunda comprueba lo que los mocks no pueden representar: SQL real, restricciones,
serialización, timeouts del cliente, mapeo de estados del proveedor. Con mocks por clase, se
verifica que el código hace lo que el test espera que haga, no que el sistema funcione; y cualquier
refactorización interna rompe pruebas sin que cambie el comportamiento.

🔬 **El detalle:** Los dobles se usan por contrato de puerto, no para contar clases. Un test de
contrato que corre igual contra el fake y contra el adaptador real es la herramienta que garantiza
que el fake no miente.

### S15. 🟡 ¿Cómo comparas Hexagonal, Clean y Onion sin discutir etiquetas?

⏱️ **30 segundos:** Comparando dirección de dependencias, límites protegidos y coste operativo, no
nombres. Las tres comparten la regla central.

🗣️ **2 minutos:** Las tres separan política de detalle con vocabularios distintos: puertos y
adaptadores, anillos, círculos con *Dependency Rule*. En lugar de discutir cuál es mejor, pregunto
quién define los contratos, qué no puede importar el núcleo, dónde se compone el sistema y cómo se
verifica. Si esas respuestas son sólidas, la etiqueta es secundaria y el equipo puede usar la que
mejor comunique.

🔬 **El detalle:** Layered también puede respetar la regla si la capa de datos implementa contratos
de la capa de negocio en lugar de ser su dependencia. Mencionarlo muestra que la diferencia está en
las flechas, no en el nombre.

### S16. 🟡 ¿Cuándo un módulo compilable aporta más que una convención?

⏱️ **30 segundos:** Cuando necesitas impedir imports prohibidos cerca del cambio, porque la
convención ya se rompió o porque la frontera es crítica.

🗣️ **2 minutos:** El módulo convierte una regla editorial en feedback automático: el build falla si
el núcleo intenta importar infraestructura. Eso protege frente a gente nueva, entregas urgentes y
refactorizaciones automáticas del IDE. A cambio añade configuración de build, una API pública entre
módulos y coordinación al refactorizar. Una regla de arquitectura en CI da casi el mismo efecto con
menos estructura, y suele ser el primer paso.

🔬 **El detalle:** No separo módulos solo para reproducir un dibujo. Un módulo por capa en un
servicio pequeño multiplica archivos de build sin proteger nada que una regla de imports no proteja
ya.

### S17. 🟠 Un equipo cambia de ORM sin tocar dominio, pero cada regla exige editar tres controllers. ¿Está bien protegido?

⏱️ **30 segundos:** No. Aisló la persistencia, pero dejó la política dispersa en las entradas.
Protegió el cambio menos frecuente y dejó expuesto el más frecuente.

🗣️ **2 minutos:** Poder cambiar de ORM sin tocar el dominio es un buen resultado, pero si las reglas
viven en los controllers, cada cambio de negocio se replica en tres lugares y tarde o temprano
divergen. Extraería el caso de uso y las invariantes antes de celebrar: una regla, un lugar, una
prueba, y los controllers reducidos a traducir. Después mediría cuántos archivos toca un cambio de
regla típico; ese número es el que la arquitectura debería bajar.

🔬 **El detalle:** Hexagonal protege razones de cambio, no solo intercambiabilidad tecnológica. Un
sistema donde cambiar la base es fácil y cambiar una regla es difícil ha invertido en la frontera
equivocada.

### S18. 🟠 El núcleo importa una librería de fechas. ¿Es siempre una violación?

⏱️ **30 segundos:** No. Depende de si introduce una decisión externa que necesitemos controlar. Los
tipos de fecha estables suelen ser aceptables.

🗣️ **2 minutos:** Usar `java.time.Instant` o `datetime` en el dominio no ata la política a ningún
detalle volátil: son tipos estables de la plataforma. Lo que sí aíslo es la fuente del tiempo (un
`Clock` inyectado, para que las reglas que dependen de "ahora" se prueben con tiempos fijos), la
zona horaria cuando afecta a reglas de negocio y los calendarios cuando hay días hábiles o festivos.
Esas son decisiones que el negocio discute y que cambian.

🔬 **El detalle:** No convierto toda biblioteca estándar en un puerto. La regla protege de detalles
volátiles, no exige purismo; envolver tipos estables solo añade traducción sin proteger nada.

### S19. 🟠 Una abstracción reduce líneas, pero hace más difícil localizar una regla. ¿La conservas?

⏱️ **30 segundos:** Solo si el cambio o el riesgo que protege supera esa pérdida de claridad. Menos
líneas no es el objetivo.

🗣️ **2 minutos:** Un motor genérico de reglas, un `BaseService<T>` o un pipeline configurable pueden
eliminar duplicación y a la vez borrar el lenguaje de negocio: la regla de cancelación ya no está en
`CancelOrder`, sino repartida en configuración. Mido cuánto cuesta encontrar y cambiar una regla,
cuántos errores produce la indirección y cuántos consumidores reales tiene la abstracción. Una
abstracción genérica que borra el vocabulario de negocio suele costar más de lo que ahorra.

🔬 **El detalle:** Menos líneas no equivale a menor complejidad cognitiva. A veces la duplicación
explícita de dos casos de uso parecidos es más barata de mantener que una abstracción que los une y
obliga a entender ambos para cambiar uno.

### S20. 🟠 ¿Cómo presentarías una excepción temporal a la regla de dependencias?

⏱️ **30 segundos:** Con motivo, alcance, coste aceptado, responsable y condición de revisión. Sin
esos cinco datos no es una excepción, es un atajo.

🗣️ **2 minutos:** Explicaría qué riesgo se acepta ahora (por ejemplo, el dominio de catálogo usa
anotaciones ORM), por qué la frontera no paga hoy (CRUD estable, sin reglas relevantes), qué alcance
tiene (solo ese módulo), quién es responsable y qué señal obligará a introducir la frontera (una
regla de precios, una segunda fuente de productos). La excepción queda visible cerca del código: un
ADR enlazado o una exclusión con nombre en la regla de arquitectura.

🔬 **El detalle:** Una fecha sin dueño no evita que lo temporal se vuelva permanente. La combinación
de responsable y condición observable es lo que hace que alguien vuelva a mirarla.

### S21. 🟡 ¿Puede una función concreta ser un puerto sin interfaz nominal?

⏱️ **30 segundos:** Sí. El puerto es el contrato de la conversación, no una palabra clave del
lenguaje.

🗣️ **2 minutos:** En lenguajes con funciones de primera clase o tipado estructural, una firma
pequeña puede expresar la capacidad y permitir la sustitución: un caso de uso que recibe `now: () ->
Instant` o `reserve: (sku, qty) -> Result` tiene puertos aunque no haya interfaces. En Go, una
interfaz implícita cumple el papel; en Python, un `Protocol` o simplemente un callable. Lo que
importa es que el núcleo defina la forma y que el borde la implemente.

🔬 **El detalle:** La claridad sobre quién es dueño del contrato y qué datos cruzan importa más que
la forma sintáctica. Una función que recibe el cliente del SDK como parámetro no es un puerto aunque
sea sustituible.

### S22. 🟡 ¿Eliminar un mapper puede mejorar la arquitectura?

⏱️ **30 segundos:** Sí, si copiaba formas idénticas sin proteger evolución independiente ni datos
sensibles.

🗣️ **2 minutos:** Un mapper entre un comando y un DTO que tienen los mismos campos, cambian siempre
juntos y no tienen consumidores distintos solo añade código que mantener y un lugar donde olvidar un
campo nuevo. Retirarlo simplifica sin cambiar la dirección de dependencias. Conservo las pruebas
importantes y la regla de que el núcleo no conoce el transporte, y lo reintroduzco cuando aparezcan
contratos que evolucionan por separado.

🔬 **El detalle:** Pureza sin independencia genera mantenimiento, no protección. La excepción son los
mappers de salida hacia contratos públicos: aunque hoy sean idénticos, protegen de exponer campos
internos por accidente.

### S23. 🟠 ¿Un dominio con anotaciones de framework deja de ser dominio automáticamente?

⏱️ **30 segundos:** No automáticamente, pero introduce un acoplamiento que hay que evaluar y
decidir, no ignorar.

🗣️ **2 minutos:** Reviso qué condicionan las anotaciones: si solo documentan nulabilidad, el coste
es mínimo; si condicionan construcción (constructores vacíos), persistencia (lazy loading,
sesiones), serialización (campos expuestos) o pruebas (necesidad de contexto), el dominio está
pagando un precio real. En un CRUD estable puede aceptarse con la excepción documentada; en un
núcleo con reglas valiosas y cambiantes, probablemente no.

🔬 **El detalle:** La decisión es proporcional, no un juicio por una anotación aislada. La pregunta
útil es qué pasaría si mañana hubiera que quitar ese framework: si cambia el comportamiento de las
reglas, la anotación era más que metadata.

### S24. 🟠 ¿Por qué un repositorio en memoria puede dar falsa confianza?

⏱️ **30 segundos:** Porque no reproduce restricciones, transacciones, concurrencia ni consultas
reales. Un caso de uso puede pasar con el fake y fallar con la base.

🗣️ **2 minutos:** El fake acepta un pedido duplicado que la base rechazaría por clave única, no
detecta un N+1, no simula el aislamiento transaccional ni el bloqueo optimista, y no sabe que la
base guarda los decimales con otra precisión. Sirve para probar el caso de uso, que es su propósito;
pero el adaptador necesita integración con la base elegida, y conviene un test de contrato que
ejecute las mismas expectativas contra ambos para que no diverjan.

🔬 **El detalle:** Un fake demuestra independencia del núcleo, no equivalencia con el motor. Son dos
afirmaciones distintas y cada una necesita su propia prueba.

### S25. 🟠 ¿Qué responderías si te piden aplicar hexagonal a todo el portafolio?

⏱️ **30 segundos:** Pediría clasificar los servicios por riesgo, volatilidad y vida útil antes de
imponer una profundidad única.

🗣️ **2 minutos:** Definiría una regla mínima común que todos cumplen —el núcleo no importa
infraestructura, composición explícita, pruebas del núcleo sin red— y fronteras selectivas por
servicio: completas donde hay pagos o reglas críticas, mínimas en CRUDs internos. Un estándar puede
dar guardrails (plantilla con build, reglas de dependencia, observabilidad) sin clonar ceremonia.
Mediría el resultado por cambios más baratos, no por porcentaje de servicios "migrados".

🔬 **El detalle:** La uniformidad operativa (despliegue, logs, salud) no exige un modelo de dominio
idéntico. Confundirlas lleva a plantillas con casos de uso vacíos que los equipos borran o, peor,
rellenan para cumplir.

### S26. 🟠 Un endpoint devuelve directamente una entidad JPA y una regla vive en el controller. ¿Qué corriges primero?

⏱️ **30 segundos:** Extraigo la regla a un caso de uso y dejo de exponer la entidad JPA como
contrato HTTP. Primero cubro el comportamiento con pruebas.

🗣️ **2 minutos:** El orden importa: primero una prueba de caracterización del endpoint tal como
está, luego una costura alrededor de `CreateOrder` que reciba un comando propio y contenga la regla,
y después la traducción en los bordes: request a comando en el controller, resultado a response DTO
en la salida, entidad a modelo propio en el adaptador de persistencia si el coste lo justifica. Cada
paso deja el sistema funcionando. Priorizo la regla porque es lo que más cambia; la entidad en la
respuesta, porque es un contrato público que se endurece con cada cliente nuevo.

🔬 **El detalle:** La prioridad es invertir una dependencia concreta, no completar todas las capas de
una vez. Separar el modelo JPA del dominio puede esperar si las reglas son pocas; exponer la entidad
en la API, no.

### S27. 🟠 Un CRUD interno estable tiene doce interfaces y seis mappers. ¿Qué simplificas?

⏱️ **30 segundos:** Elimino los puertos espejo y los mappers que no protegen ninguna diferencia,
conservando dirección de dependencias y pruebas.

🗣️ **2 minutos:** Revisaría cada interfaz: si tiene una implementación, nadie la sustituye y copia
la tecnología, se va. Cada mapper: si traduce formas idénticas que cambian juntas, se va. Conservo
el módulo, la validación, las pruebas de las reglas que existan y una integración directa y clara
con la base. Registro las señales para reintroducir fronteras —más reglas, más entradas, un
proveedor externo— para que la simplificación sea una decisión con historia.

🔬 **El detalle:** La respuesta senior puede ser quitar arquitectura accidental. En entrevista,
proponer borrar código con criterio suele puntuar más que proponer añadirlo.

### S28. 🟠 El proveedor cambia su SDK, pero el puerto copia exactamente sus tipos. ¿Qué concluyes?

⏱️ **30 segundos:** Que el detalle atravesó una abstracción nominal: hay interfaz, pero el contrato
lo dicta el proveedor.

🗣️ **2 minutos:** Rediseñaría el puerto desde la capacidad que el caso de uso realmente usa
—autorizar, consultar estado— con tipos y resultados propios, y movería al adaptador el mapeo de
estados, errores y formatos. El cambio actual del SDK es la oportunidad: en lugar de propagarlo por
el núcleo, se hace una vez en el adaptador nuevo. A partir de ahí, el siguiente cambio del SDK queda
localizado.

🔬 **El detalle:** No oculto capacidades que el negocio sí necesita. Si el proveedor ofrece algo que
el negocio usa —autorizaciones parciales, por ejemplo—, lo nombro en el puerto con semántica propia,
no lo escondo para que el contrato parezca más limpio.

### S29. 🟠 Las reglas críticas están en triggers de base y el dominio parece limpio. ¿Qué riesgo explicas?

⏱️ **30 segundos:** Que la política sigue dependiendo de un detalle difícil de ver, versionar y
probar desde el núcleo. El dominio está limpio porque está vacío.

🗣️ **2 minutos:** Los triggers ejecutan reglas que las pruebas del núcleo no ven, que los
desarrolladores descubren al fallar en integración y que cambian con migraciones en lugar de con
código revisado. Además atan la política al motor: cambiar de base o añadir otra entrada que no pase
por esa tabla se salta la regla. Inventariaría las reglas, las cubriría con pruebas de
comportamiento y decidiría cuáles migrar al núcleo. Algunas garantías de integridad —unicidad,
claves foráneas— pueden quedarse en la base como defensa en profundidad.

🔬 **El detalle:** Duplicar invariantes sin dueño crea divergencia. La transición debe ser explícita:
qué regla vive dónde, cuál es la autoritativa y cuándo se retira la copia.

### S30. 🟠 El contenedor inyecta todo y no hay `new`, pero el caso de uso recibe SDKs y DTO externos. ¿Es hexagonal?

⏱️ **30 segundos:** No por ese hecho. La DI resolvió el wiring, no la dirección de los contratos: el
núcleo sigue dependiendo de los detalles.

🗣️ **2 minutos:** Pediría puertos definidos por el consumidor, traducción en adaptadores y un
composition root legible donde se vea qué implementación satisface cada puerto. El contenedor puede
seguir: es útil para operar el grafo, los scopes y el ciclo de vida. Lo que cambia es qué tipos
recibe el caso de uso. La prueba rápida es construirlo en un test sin el contenedor: si hay que
instanciar el SDK, no está invertido.

🔬 **El detalle:** La evidencia está en imports, tipos y razones de cambio, no en la ausencia de
constructores. Un sistema con `new` explícito en `main` puede ser más hexagonal que uno con
inyección automática en todas partes.

---

**Siguiente:** [índice del bloque](README.md) · [Núcleo, aplicación y dominio →](../02-nucleo-aplicacion-y-dominio/README.md)
