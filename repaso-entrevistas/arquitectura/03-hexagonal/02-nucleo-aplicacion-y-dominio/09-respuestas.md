# 09 — Respuestas: Núcleo, aplicación y dominio

Solucionario del bloque `02-nucleo-aplicacion-y-dominio`. Cada enunciado está copiado literalmente de su
capítulo o de la simulación, con la numeración de su documento, y cada respuesta conserva las tres
capas: **⏱️ 30 segundos** (lo que dirías primero), **🗣️ 2 minutos** (contexto, alternativa y
coste) y **🔬 El detalle** (para estudiar, no para recitar).

> **Vigencia:** 2026-09-28.

**Salto rápido:** [01 El dominio en el centro](#01--el-dominio-en-el-centro) · [02 Casos de uso y servicios de aplicación](#02--casos-de-uso-y-servicios-de-aplicación) · [03 Puertos de entrada](#03--puertos-de-entrada) · [04 Puertos de salida](#04--puertos-de-salida) · [05 Transacciones y límites de consistencia](#05--transacciones-y-límites-de-consistencia) · [06 Validación, errores y resultados](#06--validación-errores-y-resultados) · [07 Eventos de dominio y efectos secundarios](#07--eventos-de-dominio-y-efectos-secundarios) · [08 Simulación](#08--simulación-de-entrevista)

---

## 01 · El dominio en el centro

### 1. 🟢 ¿Qué significa poner el dominio en el centro?

⏱️ **30 segundos:** Que las reglas de negocio no dependen de transporte ni infraestructura: son lo
más estable del sistema y todo lo demás depende de ellas.

🗣️ **2 minutos:** Entidades, value objects y servicios de dominio forman el núcleo; la aplicación
coordina casos de uso alrededor de él y los adaptadores traducen el mundo exterior. En el centro
está lo que decide si un pedido es válido, si una reserva puede confirmarse o si un pago puede
autorizarse. HTTP, la base y el proveedor viven fuera y conocen al dominio, no al revés. El
beneficio práctico es que esas reglas se leen en un lugar, se prueban en milisegundos y sobreviven a
cambios de tecnología.

🔬 **El detalle:** Se demuestra con imports y pruebas, no con una carpeta: el paquete del dominio no
importa nada del framework ni de la persistencia, y sus pruebas no necesitan arrancar nada.

### 2. 🟢 ¿Qué diferencia hay entre entidad y value object?

⏱️ **30 segundos:** La entidad tiene identidad que persiste aunque cambien sus datos; el value
object se define solo por sus valores y dos con los mismos valores son iguales.

🗣️ **2 minutos:** Un pedido sigue siendo el mismo pedido aunque cambien sus líneas o su estado: se
compara por su identificador. `Money` vale por cantidad y moneda: dos `Money(49.90, USD)` son
intercambiables. Esa diferencia orienta el diseño: las entidades protegen transiciones de estado a
lo largo del tiempo; los value objects protegen la validez de un concepto en el momento de
construirse (una moneda válida, un importe con dos decimales, un email bien formado).

🔬 **El detalle:** Los value objects suelen ser inmutables: cambiar un importe produce otro `Money`,
no modifica el existente. Eso elimina efectos colaterales y los hace seguros de compartir entre
entidades.

### 3. 🟢 ¿Qué es una invariante?

⏱️ **30 segundos:** Una condición que siempre debe cumplirse para que el estado sea válido, antes y
después de cualquier operación.

🗣️ **2 minutos:** Ejemplos del sistema de pedidos: un pedido confirmado tiene al menos una línea; un
pedido cancelado no vuelve a pendiente; una reserva nunca deja el stock por debajo de cero; un
importe siempre tiene moneda. La invariante no es una validación de formulario: debe cumplirse venga
el cambio de HTTP, de un job o de un consumidor. Por eso se protege en el objeto que posee el
estado, no en quien lo invoca.

🔬 **El detalle:** Debe protegerse en el punto donde se cambia el estado: el método `confirm()` falla
si no hay líneas. Si la comprobación está en el controller, cualquier otra entrada puede saltársela.

### 4. 🟢 ¿Qué responsabilidad tiene un servicio de dominio?

⏱️ **30 segundos:** Expresar una regla de negocio que no pertenece naturalmente a una sola entidad o
value object.

🗣️ **2 minutos:** Una política de precio que combina pedido, cliente y tarifa, o una regla que
decide si dos pedidos pueden fusionarse, no tienen un dueño natural. Un servicio de dominio las
expresa con conceptos de dominio, sin conocer HTTP, ORM ni proveedores. Es distinto de un servicio
de aplicación: no coordina puertos, transacciones ni persistencia; calcula o decide. Por eso suele
ser una clase sin estado o una función pura, fácil de probar.

🔬 **El detalle:** No es un contenedor genérico para cualquier lógica. Si todos los comportamientos
terminan en servicios de dominio y las entidades quedan como estructuras de datos, el resultado es
un modelo anémico con otro nombre.

### 5. 🟢 ¿Qué no debería conocer el dominio?

⏱️ **30 segundos:** HTTP, SQL, ORM, JSON, broker, SDKs de proveedores, el contenedor de DI y la
configuración de despliegue.

🗣️ **2 minutos:** El dominio recibe conceptos propios (`Money`, `OrderId`, `Actor`) y, si hace
falta, capacidades abstractas expresadas como puertos. No recibe `HttpServletRequest`, entidades
anotadas, mensajes del broker ni variables de entorno. Cada una de esas cosas cambia por razones
ajenas al negocio —versiones de framework, cambios de esquema, proveedores nuevos— y si el dominio
las conoce, esos cambios lo alcanzan.

🔬 **El detalle:** Una librería estable —tipos de fecha, decimales, colecciones— puede aceptarse; una
volátil, solo con una razón explícita. El criterio no es "cero dependencias", sino "ninguna
dependencia que cambie por razones ajenas a la política".

### 6. 🟢 ¿Qué diferencia hay entre dominio y carpeta `model`?

⏱️ **30 segundos:** El dominio es la política de negocio; `model` es solo una convención de
organización que puede contener cualquier cosa.

🗣️ **2 minutos:** Una carpeta `model` puede contener DTO de HTTP, entidades ORM con getters y
setters, y enums copiados de un proveedor, sin expresar una sola regla. También puede ocurrir lo
contrario: reglas de dominio bien encapsuladas en un paquete que se llama de otra forma. Para saber
dónde está el dominio hay que buscar invariantes, transiciones protegidas y reglas de negocio, y
comprobar qué importan esas clases.

🔬 **El detalle:** Busca invariantes y dependencias, no nombres. Una pregunta rápida en revisión:
"¿dónde está la regla que impide cancelar un pedido enviado?". Si la respuesta es un controller o un
servicio de infraestructura, el dominio no está en `model`.

### 7. 🟢 ¿Por qué una entidad no debería exponer todos sus setters?

⏱️ **30 segundos:** Porque cualquier código podría llevarla a un estado inválido, saltándose las
reglas que deberían protegerla.

🗣️ **2 minutos:** Con `setStatus(CANCELLED)` público, un job puede cancelar un pedido enviado y
nadie lo impide. La entidad debe exponer operaciones con significado de negocio —`confirm()`,
`cancel()`, `markPaid()`— que validan el estado actual y la transición antes de cambiar nada. Así
las reglas quedan en un lugar, las transiciones inválidas fallan con un error propio y los
consumidores no pueden olvidar una comprobación.

🔬 **El detalle:** La encapsulación protege transiciones, no solo campos. Los getters pueden ser
razonables; los setters genéricos son los que abren la puerta. Cuando el ORM los exige, esa es una
razón para separar el registro de persistencia de la entidad.

### 8. 🟡 ¿Qué validación pertenece al dominio?

⏱️ **30 segundos:** La que determina si un estado o una transición es válida para el negocio, sin
importar quién la invoca.

🗣️ **2 minutos:** "No confirmar un pedido vacío", "no reservar más stock del disponible", "no
cancelar un pedido enviado" pertenecen al dominio. "El JSON está mal formado", "falta el campo
`items`" o "la cantidad no es un entero" pertenecen al borde, porque dependen del formato de
entrada. La autorización contextual ("este actor puede cancelar este pedido") suele coordinarse en
aplicación. Esa separación hace que cada fallo tenga una traducción clara y que la regla de negocio
sea la misma para todas las entradas.

🔬 **El detalle:** La regla debe ejecutarse desde cualquier entrada. Si solo el controller comprueba
que el pedido no esté vacío, un consumidor de mensajes o un job la saltarán; si la comprueba la
entidad, es imposible saltarla.

### 9. 🟡 ¿Qué información puede recibir una regla de negocio?

⏱️ **30 segundos:** Los datos y capacidades necesarios para decidir, expresados en tipos propios del
dominio.

🗣️ **2 minutos:** Una regla puede recibir `Money`, cantidades, el actor que opera, fechas o una
capacidad expresada como puerto (por ejemplo, una tasa de cambio obtenida por la aplicación). No
debe recibir un request, una entidad del ORM ni un DTO del proveedor, porque arrastrarían su forma y
su ciclo de vida. Cuanto más precisa sea la entrada, más fácil es probar la regla y más claro qué la
hace cambiar.

🔬 **El detalle:** Menos datos reduce acoplamiento y ambigüedad. Pasar "el pedido entero" cuando la
regla solo necesita el total y la moneda invita a que la regla empiece a depender de otros campos
sin que nadie lo decida.

### 10. 🟡 ¿Cuándo usarías un value object?

⏱️ **30 segundos:** Cuando un valor tiene semántica, formato o invariantes propias que conviene
validar una sola vez y proteger en todas partes.

🗣️ **2 minutos:** `Money` evita sumar monedas distintas y centraliza el redondeo a dos decimales;
`Email` centraliza su validez; `Quantity` impide cantidades negativas; `OrderId` evita confundir un
id de pedido con uno de cliente. En todos los casos la validación ocurre al construir, y a partir de
ahí cualquier código que recibe el tipo puede confiar en él. Eso elimina validaciones repetidas y
errores de mezclar valores del mismo tipo primitivo.

🔬 **El detalle:** No conviertas cada string en objeto sin una regla que proteger. Un value object
sin invariante ni comportamiento añade construcción, igualdad y mapeo sin devolver nada.

### 11. 🟡 ¿Cuándo una regla pertenece a un servicio de dominio?

⏱️ **30 segundos:** Cuando usa varios conceptos de dominio y no tiene un dueño natural único entre
ellos.

🗣️ **2 minutos:** Una política de precio que combina el pedido, la categoría del cliente y una
tarifa vigente puede vivir en un servicio de dominio, porque ponerla en `Order` obligaría al pedido
a conocer tarifas y ponerla en `Customer` no tendría sentido. El servicio recibe los conceptos que
necesita y devuelve una decisión. Antes de crearlo, reviso si alguna entidad debería asumir la
regla; solo si ninguna es dueña natural, el servicio es la respuesta.

🔬 **El detalle:** El servicio sigue siendo dominio, no aplicación ni infraestructura: no abre
transacciones, no llama a puertos de persistencia y no conoce el transporte. Si necesita datos
externos, la aplicación se los obtiene antes.

### 12. 🟡 ¿Por qué un DTO HTTP no debe ser el modelo de dominio?

⏱️ **30 segundos:** Porque su forma y su ciclo de vida pertenecen al transporte, y cambian por
razones ajenas al negocio.

🗣️ **2 minutos:** El DTO lleva nombres de campos públicos, opcionales por compatibilidad,
anotaciones de validación y serialización, y versiones de API. Si es el modelo de dominio, cambiar
el JSON o introducir una v2 cambia las invariantes del pedido, y otras entradas (una cola, un job)
tienen que construir un objeto HTTP para invocar una regla. Además, el DTO suele ser mutable y sin
comportamiento, lo que empuja las reglas fuera del modelo.

🔬 **El detalle:** El adaptador traduce entre DTO y comando o entidad. Ese mapeo es el precio de que
la API pública y el dominio evolucionen a su ritmo; en un servicio interno trivial puede no
compensar, pero entonces hay que decidirlo, no heredarlo.

### 13. 🟡 ¿Qué coste tiene encapsular invariantes?

⏱️ **30 segundos:** Más métodos, construcción controlada y a veces mapeo adicional, a cambio de
estados siempre válidos.

🗣️ **2 minutos:** En lugar de setters, hay que diseñar operaciones con significado (`confirm`,
`cancel`) y constructores o fábricas que validen. Las pruebas tienen que construir objetos válidos,
lo que a veces exige helpers. Y si el ORM espera mutabilidad y constructores vacíos, hay que mapear
entre la entidad y un registro de persistencia. Todo eso es código y tiempo, y se nota más en
modelos grandes con muchas transiciones.

🔬 **El detalle:** El coste se justifica por el riesgo de romper la regla. En un sistema de pagos, un
estado inválido puede costar dinero; en una lista de preferencias, quizá no merece la ceremonia. La
decisión es proporcional al daño.

### 14. 🟡 ¿Cómo probarías una entidad sin framework?

⏱️ **30 segundos:** Creando un estado válido, ejecutando una transición y verificando el resultado y
los errores, con el lenguaje puro y sin infraestructura.

🗣️ **2 minutos:** Para `Order`: crear un pedido con líneas y confirmarlo (debe pasar a confirmado);
crear uno vacío y confirmarlo (debe lanzar `EmptyOrder` y seguir en borrador); cancelar uno
confirmado y comprobar el evento registrado; intentar cancelar uno enviado y comprobar el error. No
levantaría HTTP ni base, no usaría mocks: solo objetos y aserciones sobre estado. Esas pruebas
corren en milisegundos y documentan las reglas mejor que cualquier comentario.

🔬 **El detalle:** Eso prueba el dominio, no los adaptadores. Que la entidad se guarde y se
reconstruya bien es trabajo de la prueba de integración del repositorio, que es otro anillo.

### 15. 🟡 ¿Qué cambia entre una entidad mutable y una inmutable?

⏱️ **30 segundos:** La mutable protege sus cambios internos con métodos; la inmutable devuelve un
nuevo estado en cada operación.

🗣️ **2 minutos:** Con una entidad mutable, `order.cancel()` cambia el estado del objeto; con una
inmutable, `order.cancel()` devuelve un nuevo `Order` cancelado. La inmutabilidad reduce efectos
ocultos (nadie cambia el pedido que tienes en la mano), facilita razonar sobre concurrencia y hace
natural registrar eventos. A cambio, genera más objetos, complica el mapeo con ORMs que esperan
mutabilidad y puede resultar incómoda en lenguajes sin soporte para copias con cambios.

🔬 **El detalle:** La elección depende de la complejidad, la concurrencia y el lenguaje. En Java los
records y en Python las dataclasses congeladas la hacen barata; en otros contextos, una entidad
mutable bien encapsulada protege igual de bien las invariantes.

### 16. 🟡 ¿TypeScript garantiza las invariantes de un JSON recibido?

⏱️ **30 segundos:** No. Sus tipos desaparecen al compilar a JavaScript y no se comprueban en
runtime.

🗣️ **2 minutos:** Declarar `body: CreateOrderDto` o hacer `JSON.parse(x) as Order` no inspecciona el
dato: un campo ausente llega como `undefined` y un número como string pasa sin error. El adaptador
debe validar con un esquema o un parser real (Zod, class-validator, JSON Schema) y construir un
comando seguro antes de entrar al núcleo. Después, el dominio protege sus invariantes con código,
igual que en cualquier lenguaje.

🔬 **El detalle:** Compilación y validación de datos son mecanismos distintos. TypeScript garantiza
que tu código es coherente con los tipos que declaras; no garantiza que el mundo exterior respete
esos tipos.

### 17. 🟠 Un ORM exige setters públicos. ¿Cómo proteges el dominio?

⏱️ **30 segundos:** Separaría el modelo ORM del dominio, con mapeo en el adaptador, para que los
setters vivan solo en el registro de persistencia.

🗣️ **2 minutos:** `OrderRecord` tiene los setters y constructores que el ORM necesita; `Order` tiene
métodos con significado e invariantes. El adaptador de persistencia traduce en ambos sentidos y
reconstruye el agregado validando. Si ese coste no compensa —CRUD estable, pocas reglas—,
documentaría el acoplamiento, reduciría la visibilidad de los setters lo que el ORM permita (paquete
o protegidos) y añadiría pruebas que detecten transiciones inválidas.

🔬 **El detalle:** La decisión depende de la volatilidad y el riesgo, no de la pureza. Algunos ORMs
permiten acceso por campo y constructores privados, lo que reduce el problema sin separar modelos;
conviene conocer esa opción antes de duplicar clases.

### 18. 🟠 La regla necesita consultar una tasa externa. ¿Dónde colocas la coordinación?

⏱️ **30 segundos:** La aplicación obtiene la tasa mediante un puerto y el dominio decide con el dato
ya obtenido.

🗣️ **2 minutos:** El caso de uso llama a `ExchangeRates.current(USD, EUR)`, recibe una tasa y se la
pasa a la regla (`order.convert(rate)` o un servicio de dominio). El dominio no llama al proveedor,
no conoce timeouts ni reintentos; recibe un valor con significado propio. Así la regla se prueba con
una tasa fija, la integración se prueba aparte y un fallo del proveedor se maneja en la aplicación,
que decide si reintentar, usar la última tasa conocida o rechazar.

🔬 **El detalle:** Así se separan decisión e integración. Pasar un puerto directamente al dominio es
posible, pero mezcla I/O con reglas y complica razonar sobre transacciones y fallos.

### 19. 🟠 Dos entidades comparten una regla. ¿Creas un servicio de dominio?

⏱️ **30 segundos:** Solo si la regla no tiene dueño natural y conserva semántica de dominio. Primero
reviso si una de las entidades debe asumirla.

🗣️ **2 minutos:** Si la regla es "un pedido no puede reservar más que el stock disponible",
probablemente pertenece a la reserva o al inventario, no a un servicio. Si es "un cliente con deuda
no puede crear pedidos por encima de X", combina cliente y pedido sin que ninguno sea dueño claro, y
un servicio de dominio es razonable. Evito crear un servicio solo para mover código o para evitar
decidir quién es dueño.

🔬 **El detalle:** El servicio no debe convertirse en god service. Si acumula reglas de muchas
entidades, es señal de que las entidades se quedaron sin comportamiento y el modelo se está
volviendo anémico.

### 20. 🟠 Un equipo quiere convertir cada string en value object. ¿Qué preguntas harías?

⏱️ **30 segundos:** Qué invariante, semántica o evolución protege cada objeto. Los que no protejan
nada sobran.

🗣️ **2 minutos:** Aceptaría `Email`, `Currency`, `Sku` o `OrderId`: tienen formato, reglas o riesgo
de confusión con otros identificadores. No aceptaría necesariamente un wrapper para cada etiqueta
sin comportamiento, como el nombre de un producto o una nota libre. Preguntaría también por el coste
en el borde: cada value object necesita construcción, igualdad, serialización y mapeo con el ORM y
la API.

🔬 **El detalle:** Cada objeto añade construcción, igualdad y mapeo. La regla práctica es crearlos
cuando hay una invariante o una confusión real, no por uniformidad.

### 21. 🟠 El dominio recibe un `UserContext` del framework. ¿Qué cambiarías?

⏱️ **30 segundos:** Lo traduciría a un `Actor` propio antes de entrar al núcleo, con solo la
identidad y las capacidades que la política necesita.

🗣️ **2 minutos:** El `UserContext` del framework trae el token, claims sin interpretar, sesiones y
detalles del mecanismo de autenticación. El adaptador de entrada, después de autenticar, construye
`Actor(id, role, tenant)` y lo pasa en el comando. Así un job o un consumidor pueden construir un
`Actor` de servicio sin fingir un JWT, y el núcleo no cambia si cambia el mecanismo de
autenticación.

🔬 **El detalle:** La autorización contextual —"este actor puede cancelar este pedido"— puede
coordinarse en aplicación, mientras la entidad protege las invariantes que valen para cualquier
actor.

### 22. 🟠 ¿Cómo detectas un modelo anémico sin imponer DDD?

⏱️ **30 segundos:** Busco invariantes dispersas y setters que permiten estados inválidos, no
ausencia de patrones de DDD.

🗣️ **2 minutos:** Preguntas concretas: ¿dónde está la regla que impide cancelar un pedido enviado?
¿Cuántos servicios modifican el estado del pedido? ¿Puede algún código poner un pedido en un estado
imposible? Si las reglas están en varios servicios y nadie es dueño del estado, hay riesgo real, se
llame como se llame. No necesito agregados, repositorios ni eventos para corregirlo: basta mover las
transiciones a la entidad y cerrar los setters.

🔬 **El detalle:** Un modelo simple puede ser correcto si las reglas son simples y están cohesionadas
en un lugar. Lo anémico preocupa por la dispersión, no por la falta de métodos.

### 23. 🟠 ¿Qué parte del dominio merece más protección en un sistema de pagos?

⏱️ **30 segundos:** Los estados y transiciones del pago (autorizado, capturado, reembolsado,
incierto) y la idempotencia: no cobrar dos veces y no perder un cobro.

🗣️ **2 minutos:** Aislaría la decisión de negocio del gateway: qué transiciones son válidas, qué
pasa con un resultado incierto, cuándo se puede reintentar con la misma clave y cuándo hay que
consultar. El proveedor y sus códigos se traducen en el adaptador a resultados propios; el dominio
nunca razona con `402` o `requires_action`. Esas reglas merecen pruebas exhaustivas, porque un error
cuesta dinero y confianza.

🔬 **El detalle:** El resultado incierto es el estado que más se olvida: tratar un timeout como
rechazo puede dejar un cobro sin pedido, y tratarlo como éxito, un pedido sin cobro. Modelarlo
explícitamente es la protección más valiosa.

### 24. 🟠 ¿Cuándo aceptarías un modelo de datos simple?

⏱️ **30 segundos:** Cuando las reglas son pocas, estables y no requieren encapsulación adicional
para mantenerse válidas.

🗣️ **2 minutos:** En un catálogo interno con campos editables y validaciones de formato, un modelo
de datos simple con validación en el borde y una prueba es suficiente. Mantendría una frontera clara
—las reglas que existan en una función identificable, sin framework— y pruebas, y registraría la
decisión. Introduciría objetos con comportamiento cuando aparezcan transiciones de estado o reglas
que varias entradas deben respetar.

🔬 **El detalle:** La simplicidad es una decisión revisable, no un descuido. Lo que la hace segura es
saber qué señal obliga a revisarla.

---

## 02 · Casos de uso y servicios de aplicación

### 1. 🟢 ¿Qué es un caso de uso?

⏱️ **30 segundos:** Una acción completa que la aplicación ofrece a un actor, reconocible por el
negocio en una frase: crear un pedido, cancelarlo, autorizar un pago.

🗣️ **2 minutos:** Recibe una intención expresada como comando, coordina los puertos que necesita
(cargar, reservar, guardar), invoca al dominio para que decida y devuelve un resultado propio. Es el
punto de entrada estable del núcleo: HTTP, una cola o una prueba lo invocan igual. También suele ser
el lugar natural de la frontera transaccional, porque sabe qué operaciones forman una decisión de
negocio completa.

🔬 **El detalle:** No es un método genérico de persistencia. `SaveOrder` o `UpdateOrderFields`
describen operaciones de base; `CancelOrder` describe una intención con reglas. Si un caso de uso
solo reenvía a un repositorio, probablemente sobra.

### 2. 🟢 ¿Qué diferencia hay entre caso de uso y controller?

⏱️ **30 segundos:** El controller traduce transporte; el caso de uso coordina la aplicación. El
primero conoce HTTP; el segundo, no.

🗣️ **2 minutos:** El controller lee el cuerpo, valida la forma, extrae la identidad autenticada,
construye el comando, llama al caso de uso y convierte el resultado o el error en status y JSON. El
caso de uso no sabe que existe HTTP: recibe un comando y devuelve un resultado. Por eso el mismo
caso puede ser invocado por HTTP, por un consumidor de mensajes, por una CLI o por una prueba, cada
uno con su propio adaptador.

🔬 **El detalle:** El controller conoce status codes; el caso de uso no. Un controller "delgado" que
sigue decidiendo reglas (por ejemplo, calcular el total) no es un caso de uso: sigue atado al
transporte y esas reglas no se ejecutan desde otras entradas.

### 3. 🟢 ¿Qué diferencia hay entre caso de uso y servicio de dominio?

⏱️ **30 segundos:** El caso de uso coordina; el servicio de dominio expresa una regla. Uno trabaja
con puertos y transacciones; el otro, solo con conceptos de dominio.

🗣️ **2 minutos:** `CreateOrder` carga productos, reserva inventario, crea el pedido y lo guarda:
coordina puertos. Un `PricingPolicy` calcula el precio de un pedido según el cliente y la tarifa:
decide. El servicio de dominio no conoce repositorios ni transacciones; recibe los datos y devuelve
una decisión, y por eso se prueba sin dobles. El caso de uso lo invoca como parte de su
coordinación.

🔬 **El detalle:** No uses el servicio de aplicación como bolsa de reglas. Si el caso de uso empieza
a contener `if` de negocio que valdrían para cualquier entrada, esas reglas deberían bajar al
dominio.

### 4. 🟢 ¿Qué es un comando?

⏱️ **30 segundos:** Un objeto de datos que expresa la intención de cambiar algo, con la información
necesaria para ejecutarla y nada más.

🗣️ **2 minutos:** `CreateOrderCommand` lleva el cliente, las líneas y una clave de operación; no
lleva headers, objetos HTTP ni metadatos del broker. Los adaptadores lo construyen desde su
transporte y el caso de uso lo recibe sin saber de dónde vino. Tener un tipo propio permite validar
su forma una vez, documentar la intención y evolucionar la API pública sin tocar la aplicación.

🔬 **El detalle:** Puede incluir un `operationId` para idempotencia: es un dato estable de aplicación
que el adaptador extrae del header `Idempotency-Key` en HTTP o del identificador de operación de un
mensaje, y que el caso de uso usa para no repetir efectos.

### 5. 🟢 ¿Qué es una consulta?

⏱️ **30 segundos:** Una operación que obtiene información sin expresar un cambio de negocio.

🗣️ **2 minutos:** Listar los pedidos de un cliente o ver el detalle de uno son consultas. Pueden
usar una proyección optimizada —una consulta SQL que devuelve exactamente los campos que la pantalla
necesita— sin cargar ni reconstruir el agregado completo, porque no van a proteger ninguna
invariante. También pueden tener permisos y caché distintos de los comandos. Separarlas
explícitamente evita pagar el coste del modelo rico cuando solo se lee.

🔬 **El detalle:** "Sin cambio" debe ser una propiedad del contrato, no una suposición. Una consulta
que por debajo actualiza un contador de accesos o marca algo como leído ya es un comando, y
reintentarla o cachearla tiene consecuencias.

### 6. 🟢 ¿Qué significa coordinar?

⏱️ **30 segundos:** Ordenar colaboraciones entre puertos y dominio y traducir resultados, sin poseer
las reglas de negocio.

🗣️ **2 minutos:** Cargar el pedido, pedirle al dominio que lo cancele, liberar la reserva, guardar y
registrar la notificación pendiente es coordinación: el caso de uso decide el orden y qué puerto se
usa en cada paso. Lo que no decide es si la cancelación es válida; eso lo decide `Order.cancel()`.
La coordinación también incluye decidir qué pasa si un paso falla: revertir, marcar pendiente o
propagar el error.

🔬 **El detalle:** Una coordinación enorme señala límites dudosos. Si un caso de uso coordina diez
puertos, probablemente está mezclando varias intenciones o haciendo trabajo que debería pasar
después, de forma asíncrona.

### 7. 🟢 ¿Dónde se decide una invariante?

⏱️ **30 segundos:** En la entidad o el servicio de dominio que protege el concepto, no en el caso de
uso ni en el adaptador.

🗣️ **2 minutos:** "Un pedido enviado no se cancela" se decide en `Order.cancel()`. El caso de uso
puede orquestar la operación, pero no debe poder dejar estados inválidos aunque se equivoque en el
orden de las llamadas. Si la invariante vive en el caso de uso, otro caso de uso que toque el mismo
estado tendrá que repetirla, y tarde o temprano alguien la olvidará.

🔬 **El detalle:** La regla debe ejecutarse desde todos los drivers. El test de que está bien ubicada
es que no haya ningún camino —HTTP, cola, job, script de migración que use el dominio— que pueda
cambiar el estado sin pasar por ella.

### 8. 🟡 ¿Qué debe devolver un caso de uso?

⏱️ **30 segundos:** Un resultado propio de aplicación: no una respuesta HTTP ni una entidad ORM.

🗣️ **2 minutos:** Puede devolver un resultado de negocio (`OrderCreated` con el id y el estado), una
proyección adecuada al caso o un error propio (`InsufficientInventory`), según el estilo del
lenguaje: excepciones tipadas, `Result` o uniones selladas. Lo importante es que el adaptador pueda
traducirlo sin conocer el interior del dominio, y que no filtre objetos con comportamiento de
infraestructura, como entidades con relaciones lazy.

🔬 **El detalle:** El adaptador decide la representación externa: `201` con `Location` en HTTP, un
mensaje de respuesta correlacionado en una cola, un código de salida en una CLI. El mismo resultado
sirve a los tres.

### 9. 🟡 ¿Cuándo una autorización pertenece a aplicación?

⏱️ **30 segundos:** Cuando depende del actor y del contexto concreto de la operación, no de una
regla universal del concepto.

🗣️ **2 minutos:** "Este usuario puede cancelar este pedido porque es el dueño o es operador" depende
de quién opera y sobre qué recurso: el caso de uso carga el pedido, compara con el actor y decide
antes de llamar a la entidad. "Un pedido enviado no se cancela" vale para cualquier actor: es
invariante de dominio. El borde puede hacer además una comprobación gruesa (autenticado, rol
mínimo), pero la decisión que depende del recurso necesita el recurso, y eso está en aplicación.

🔬 **El detalle:** Una invariante universal sigue en dominio. Mezclarlas —poner la comprobación de
dueño en la entidad— obliga al dominio a conocer actores y roles, que suelen cambiar por razones
distintas que las reglas del pedido.

### 10. 🟡 ¿Qué tamaño debería tener un caso de uso?

⏱️ **30 segundos:** El necesario para una intención cohesiva. No hay un número de líneas correcto.

🗣️ **2 minutos:** Lo mido por razones de cambio, dependencias y límite transaccional: un caso de uso
que cambia por una sola razón de negocio, depende de pocos puertos y cabe en una transacción local
tiene buen tamaño. Uno que solo reenvía a un repositorio es demasiado pequeño; uno que coordina
pedidos, pagos, inventario, notificaciones y facturación es demasiado grande. Entre ambos extremos
hay mucho espacio legítimo.

🔬 **El detalle:** Muy pequeño puede ser un CRUD disfrazado; muy grande puede ser un god use case. La
señal más fiable es el historial: si cada cambio de negocio toca el mismo caso de uso, está
absorbiendo demasiadas responsabilidades.

### 11. 🟡 ¿Por qué no debe recibir un request HTTP?

⏱️ **30 segundos:** Porque acopla la aplicación al transporte: solo HTTP podría invocarla y cada
cambio de la API la alcanzaría.

🗣️ **2 minutos:** Si `CreateOrder` recibe `HttpServletRequest`, una cola o una prueba tienen que
fabricar un request falso para usarlo, y el caso de uso empieza a leer headers, parámetros y cuerpo,
es decir, a hacer trabajo del adaptador. El adaptador debe convertir el request en comando,
validando forma e identidad, y después convertir el resultado o el error en status y cuerpo.

🔬 **El detalle:** También evita filtrar headers, sesión y ciclo de vida web al núcleo. Un caso de
uso que depende del objeto request puede comportarse distinto según el contexto del servidor, lo que
hace sus pruebas frágiles.

### 12. 🟡 ¿Por qué no debe llamar directamente al ORM?

⏱️ **30 segundos:** Porque la infraestructura dictaría la política y las pruebas: el caso de uso
tendría que conocer sesiones, entidades y consultas.

🗣️ **2 minutos:** Con el ORM dentro, probar la coordinación exige una base o mocks del ORM, que son
frágiles y no dicen nada del SQL real. Además el caso de uso empieza a optimizar consultas, manejar
relaciones lazy y capturar excepciones del driver. Con un puerto de salida (`Orders`), el caso de
uso pide lo que necesita en términos de negocio y el adaptador encapsula ORM, SQL y mapeo.

🔬 **El detalle:** La transacción puede rodear la coordinación sin importar el ORM: una unidad de
trabajo como puerto, o un decorador transaccional en el borde de aplicación, deja al caso de uso sin
conocer `EntityManager` ni conexiones.

### 13. 🟡 ¿Qué hace que un caso de uso sea reutilizable?

⏱️ **30 segundos:** Un contrato propio, la ausencia de transporte y dependencias de salida
abstractas.

🗣️ **2 minutos:** Si recibe un comando propio, devuelve un resultado propio y depende solo de
puertos, HTTP, una cola, un job o una prueba pueden activarlo con adaptadores distintos. Esa
reutilización es la razón práctica de la arquitectura: añadir una entrada nueva no duplica reglas.
También ayuda que el caso de uso sea idempotente cuando alguna entrada puede repetir, para que cada
adaptador no tenga que resolverlo por su cuenta.

🔬 **El detalle:** Reutilizar no significa forzar un comando común si las intenciones difieren. Un
pedido desde la web y un pedido importado de un marketplace pueden merecer dos casos de uso que
comparten dominio, en lugar de uno lleno de banderas por origen.

### 14. 🟡 ¿Cómo probarías su coordinación?

⏱️ **30 segundos:** Con dobles de los puertos, preferiblemente fakes con comportamiento, y
aserciones sobre resultado y estado final.

🗣️ **2 minutos:** Para `CancelOrder`: un fake de `Orders` con un pedido confirmado, ejecutar el caso
de uso, comprobar que el pedido quedó cancelado, que la reserva se liberó y que hay una notificación
pendiente. Otro escenario con un pedido enviado debe devolver el error y no cambiar nada. Dejo ORM,
red y framework fuera y pruebo los adaptadores en otro nivel, contra recursos reales.

🔬 **El detalle:** El test no debe validar detalles internos irrelevantes, como el orden exacto de
llamadas o cuántas veces se llamó a `save`. Esas aserciones se rompen con cada refactorización y no
protegen ninguna regla.

### 15. 🟡 ¿Qué diferencia hay entre una consulta y un comando?

⏱️ **30 segundos:** El comando expresa un cambio de estado con reglas; la consulta expresa una
lectura sin efectos de negocio.

🗣️ **2 minutos:** Por esa diferencia pueden tener modelos, permisos y optimizaciones distintas: el
comando carga el agregado para proteger invariantes y abre una transacción; la consulta puede leer
una proyección desnormalizada, cachearse y escalar por separado. Esa separación, llevada lejos, es
CQRS; en su forma mínima, solo significa no usar el modelo rico para listar y no usar proyecciones
para decidir.

🔬 **El detalle:** Una consulta también necesita un contrato de consistencia claro: si lee de una
réplica o de una proyección alimentada por eventos, puede estar atrasada, y el cliente debe saber si
eso es aceptable.

### 16. 🟡 ¿Cuándo un caso de uso es demasiado grande?

⏱️ **30 segundos:** Cuando mezcla varias razones de cambio y reglas que no se pueden explicar como
una sola intención.

🗣️ **2 minutos:** Señales: muchas dependencias, ramas por tipo de cliente u origen, transacciones
que duran mucho porque encadenan llamadas remotas, y un historial donde cada cambio de negocio lo
toca. Separaría solo si los límites son reales —por ejemplo, la creación del pedido y su facturación
ocurren en momentos distintos—, no por contar líneas. A menudo la solución es dejar un caso de uso
pequeño y mover lo que puede pasar después a un proceso asíncrono.

🔬 **El detalle:** A veces una operación de proceso necesita coordinar mucho de verdad. Eso es
legítimo si se hace explícito como proceso de aplicación, con sus pasos y compensaciones, en lugar
de esconderlo en un método largo.

### 17. 🟠 El controller valida, guarda y publica. ¿Cómo lo repartirías?

⏱️ **30 segundos:** Validación de forma en el adaptador; reglas en el dominio; coordinación,
persistencia y publicación a través de puertos en aplicación.

🗣️ **2 minutos:** El controller construye el comando desde el request validado y traduce el
resultado. El caso de uso invoca al dominio para crear y validar el pedido, lo guarda por `Orders` y
registra la publicación por un puerto (`PendingPublications`), todo dentro de una unidad de trabajo.
El dominio decide si el pedido es válido y registra el hecho `OrderCreated`. Cada pieza tiene una
razón de cambio y una prueba propia.

🔬 **El detalle:** La publicación y su atomicidad se resuelven con el patrón apropiado —normalmente
outbox—, porque publicar directamente al broker desde el caso de uso no es atómico con el commit de
la base.

### 18. 🟠 El caso de uso tiene veinte dependencias. ¿Qué investigas?

⏱️ **30 segundos:** Si mezcla varios casos de uso, varios proveedores o límites de negocio distintos
en una sola clase.

🗣️ **2 minutos:** Clasifico las dependencias: cuáles usa cada rama, cuáles son de lectura y cuáles
de escritura, cuáles podrían ocurrir después del commit. Suele aparecer un god use case que reúne
varias intenciones, o un caso de uso que hace síncrono lo que debería ser asíncrono (notificar,
facturar, actualizar informes). Divido por razones de cambio y muevo los efectos posteriores a
handlers o a la outbox.

🔬 **El detalle:** No reduzco el número artificialmente con un service locator o un "contexto" que
agrupa dependencias. Eso esconde el acoplamiento en lugar de eliminarlo, y hace que las pruebas
tengan que construir el contexto entero.

### 19. 🟠 Dos casos de uso repiten una regla. ¿Dónde la colocas?

⏱️ **30 segundos:** En la entidad o el servicio de dominio que posee el concepto, de modo que ambos
casos de uso la invoquen sin repetirla.

🗣️ **2 minutos:** Si `CreateOrder` y `ImportOrder` comprueban ambos que el pedido no supere el
límite de crédito, esa regla pertenece al dominio: a `Order`, a `Customer` o a un servicio de
crédito. Extraigo la política, no solo las líneas duplicadas, y dejo a la aplicación coordinando.
Así la regla tiene un nombre, una prueba y un único lugar donde cambiar.

🔬 **El detalle:** Si las reglas solo parecen iguales pero cambian por motivos distintos (el límite
de crédito de la web y el de importación pueden divergir), no fuerces una abstracción común: la
duplicación visible es más barata que un acoplamiento falso.

### 20. 🟠 El caso de uso necesita una transacción. ¿Quién la abre?

⏱️ **30 segundos:** Normalmente el borde de aplicación o la composición, como detalle técnico; el
caso de uso define qué operaciones forman la unidad.

🗣️ **2 minutos:** Hay dos formas habituales: un decorador o fachada transaccional alrededor del caso
de uso (`@Transactional` en una clase de aplicación, no en el repositorio), o un puerto `UnitOfWork`
que el caso de uso invoca con una función. En ambos casos el framework implementa begin, commit y
rollback, y el caso de uso no importa ni `EntityManager` ni conexiones. Lo esencial es que todas las
operaciones que deben ser atómicas compartan la misma transacción física.

🔬 **El detalle:** El límite debe cubrir las operaciones que necesitan consistencia y nada más: no
llamadas HTTP remotas ni publicaciones al broker, que no participan del commit y alargan los
bloqueos.

### 21. 🟠 Una consulta necesita un DTO optimizado. ¿Dónde lo defines?

⏱️ **30 segundos:** En un contrato de lectura propio de aplicación, no como entidad ORM pública ni
como modelo de dominio.

🗣️ **2 minutos:** Defino un puerto de lectura (`OrderSummaries.forCustomer(id)`) que devuelve un
tipo de resultado pensado para esa consulta. El adaptador puede proyectar SQL directamente a ese
tipo, con los joins y campos exactos, sin hidratar agregados. Según la frontera, el tipo puede ser
de aplicación (lo usan varios adaptadores) o de presentación (lo usa solo HTTP), pero no es la
entidad.

🔬 **El detalle:** No confundas optimización de lectura con modelo de dominio. El modelo de dominio
existe para proteger invariantes al escribir; forzar las lecturas a pasar por él solo añade coste, y
forzar al dominio a tener la forma de las pantallas lo deforma.

### 22. 🟠 ¿Cómo reutilizas un caso de uso desde un consumidor?

⏱️ **30 segundos:** El consumidor deserializa el mensaje, valida su esquema, construye el mismo
comando y llama al puerto de entrada.

🗣️ **2 minutos:** El adaptador de mensajería se encarga de lo propio del transporte: versión del
esquema, identidad del productor, correlación, ACK tras el commit, redelivery y DLQ. El caso de uso
y el dominio son exactamente los que usa HTTP. Si el mensaje trae una clave de operación, entra en
el comando como `operationId`, igual que el `Idempotency-Key` de HTTP, y el caso de uso deduplica en
ambos casos.

🔬 **El detalle:** La idempotencia debe pertenecer al contrato del caso de uso y a sus puertos de
persistencia, no a cada adaptador. Si cada entrada deduplica por su cuenta, una misma operación que
llega por dos caminos se ejecuta dos veces.

### 23. 🟠 El equipo llama “service” a todo. ¿Cómo introduces precisión?

⏱️ **30 segundos:** Nombrando por responsabilidad: controller, caso de uso, servicio de dominio,
adaptador. Cada nombre dice qué puede importar la clase.

🗣️ **2 minutos:** Primero revisaría las dependencias de cada "service": los que importan el
framework web son adaptadores de entrada; los que coordinan puertos y transacciones son casos de
uso; los que solo calculan con conceptos de dominio son servicios de dominio; los que envuelven un
SDK son adaptadores de salida. Renombraría donde el nombre oculta una decisión, empezando por los
que más cambian, y añadiría una regla de arquitectura con los nuevos nombres.

🔬 **El detalle:** El nombre ayuda, pero el código debe confirmarlo. Renombrar `OrderService` a
`CreateOrder` sin sacar el ORM de dentro no mejora nada; los imports son los que cuentan.

### 24. 🟠 ¿Cuándo aceptarías una función en lugar de una clase?

⏱️ **30 segundos:** Cuando la operación es pura o tiene pocas dependencias y un contrato claro. La
arquitectura no exige objetos.

🗣️ **2 minutos:** Una clase aporta estado (dependencias inyectadas por constructor) o composición;
una función puede ser más directa cuando recibe todo lo que necesita como parámetros. En Go o
Python, un caso de uso como función que recibe sus puertos es idiomático; en TypeScript, una función
que cierra sobre sus dependencias también. Lo importante es que el contrato (entrada, salida,
puertos) sea explícito y que el núcleo no importe detalles.

🔬 **El detalle:** La arquitectura no exige objetos por doctrina. El puerto de entrada puede ser una
firma de función; el puerto de salida, un parámetro de tipo función. La dirección de dependencias es
la misma.

---

## 03 · Puertos de entrada

### 1. 🟢 ¿Qué es un puerto de entrada?

⏱️ **30 segundos:** La API del núcleo que un driver usa para activar una capacidad. Es lo que el
mundo puede pedirle a la aplicación.

🗣️ **2 minutos:** HTTP, una cola, un job o una prueba se adaptan al mismo puerto: cada uno traduce
su protocolo a un comando propio y llama a `CreateOrder`. El puerto define qué entra (el comando),
qué sale (el resultado o un error propio) y nada del transporte. Gracias a eso, añadir una entrada
nueva es escribir un adaptador, no duplicar reglas, y la prueba del núcleo es simplemente otro
driver que invoca el puerto.

🔬 **El detalle:** Puede ser una interfaz, una función o un módulo: la forma depende del lenguaje. En
muchos proyectos Java la propia clase del caso de uso hace de puerto de entrada, y solo se extrae
una interfaz si hay que sustituirla en las pruebas del adaptador.

### 2. 🟢 ¿Por qué no debe reflejar un endpoint?

⏱️ **30 segundos:** Porque el endpoint es transporte y puede cambiar —ruta, método, versión— sin que
cambie la intención de negocio.

🗣️ **2 minutos:** El puerto expresa `CreateOrder`, no `POST /api/v1/orders` con su status `201` y su
header `Location`. Si el puerto copia el endpoint, una v2 de la API obliga a cambiar la aplicación,
y una cola que crea pedidos tiene que simular un endpoint. Cuando el puerto se diseña desde el caso
de uso hacia afuera, varios endpoints o versiones pueden traducir al mismo contrato.

🔬 **El detalle:** El adaptador hace la traducción en ambos sentidos. Es la misma idea que un
contrato OpenAPI escrito antes que el backend: el YAML es la forma pública del puerto, pero no el
puerto.

### 3. 🟢 ¿Qué diferencia hay entre comando y query?

⏱️ **30 segundos:** El comando pide un cambio de estado; la query pide información sin efectos de
negocio.

🗣️ **2 minutos:** Por eso pueden diferir en consistencia (el comando exige la versión actual; la
query puede tolerar una réplica atrasada), en permisos (cancelar exige ser dueño; listar quizá no),
en implementación (el comando carga el agregado; la query lee una proyección) y en reintento (una
query se repite sin riesgo; un comando necesita idempotencia). Separarlos en el puerto hace visibles
esas diferencias.

🔬 **El detalle:** Ambos requieren contratos propios. Una query que devuelve entidades ORM al
adaptador filtra infraestructura igual que un comando que recibe un request.

### 4. 🟢 ¿Qué es una intención de negocio?

⏱️ **30 segundos:** Una acción que el negocio puede nombrar y defender sin mencionar tecnología:
crear un pedido, cancelarlo, autorizar un pago.

🗣️ **2 minutos:** `AuthorizePayment` es intención; `POST /payments` es transporte;
`insertPaymentRow` es persistencia. Diseñar puertos desde la intención hace que sus nombres, datos y
errores tengan sentido para quien conoce el negocio, y que sobrevivan a cambios de protocolo.
También ayuda a decidir cuándo dos entradas deben compartir un puerto: si expresan la misma
intención, sí.

🔬 **El detalle:** La intención guía el nombre del puerto y del comando. Si cuesta nombrar un puerto
sin usar palabras técnicas, suele ser porque todavía no se sabe qué intención representa.

### 5. 🟢 ¿Qué datos pertenecen al transporte?

⏱️ **30 segundos:** Headers, status codes, path, formato JSON, ACK, offsets, delivery tags y
metadatos del protocolo.

🗣️ **2 minutos:** El adaptador los usa para su trabajo —autenticar, correlacionar, decidir el
status, confirmar el mensaje— o los convierte en datos propios antes de llamar al núcleo. Por
ejemplo, el header `Idempotency-Key` se convierte en `operationId` del comando, el token en un
`Actor`, el `traceparent` en contexto de observabilidad fuera del dominio. Lo que no cruza es el
objeto de transporte en sí.

🔬 **El detalle:** La identidad es un caso especial: viaja en el transporte (JWT, certificado,
cabecera de servicio), pero la política la necesita. El adaptador la verifica y la traduce a un
actor propio; el núcleo nunca interpreta el token.

### 6. 🟢 ¿Qué significa que un port sea estable?

⏱️ **30 segundos:** Que cambia cuando evoluciona la capacidad de negocio, no con cada cambio del
transporte o de la infraestructura.

🗣️ **2 minutos:** Añadir una versión de API, cambiar de broker o migrar de framework no debería
modificar `CreateOrder` ni su comando. Sí debería modificarlo que el negocio empiece a admitir
pedidos con varias monedas. Esa estabilidad es la que permite que varios adaptadores dependan del
mismo puerto sin coordinarse entre sí, y que las pruebas del núcleo no se rompan por cambios
técnicos.

🔬 **El detalle:** Estable no significa congelado. Cuando cambia la intención, el puerto cambia, y
eso es correcto; lo que se evita es que cambie por accidente, arrastrado por un detalle.

### 7. 🟢 ¿Dónde se valida la forma del request?

⏱️ **30 segundos:** En el adaptador de entrada: tipos, campos obligatorios, tamaños, formatos. Es
trabajo del borde.

🗣️ **2 minutos:** El adaptador rechaza pronto lo que no se puede interpretar —JSON mal formado,
cantidad no numérica, cuerpo demasiado grande— con un error de su protocolo (`400` en HTTP, DLQ en
una cola). El núcleo recibe datos ya estructurados en un comando, pero repite las invariantes de
negocio, porque no puede confiar en que todas las entradas validen lo mismo.

🔬 **El detalle:** Validación de forma y de política son capas diferentes. "La cantidad es un entero"
es forma; "la cantidad no supera el stock" es política. Mezclarlas en el adaptador deja la política
sin proteger desde otras entradas.

### 8. 🟡 ¿Dónde se valida una invariante?

⏱️ **30 segundos:** En el dominio, para que todos los drivers queden protegidos por igual.

🗣️ **2 minutos:** El adaptador puede dar errores tempranos y amables —por ejemplo, rechazar una
lista de líneas vacía antes de llamar—, pero no es la única defensa, porque un consumidor, un job o
un script pueden invocar el caso de uso sin pasar por él. La entidad debe impedir las transiciones
inválidas y fallar con un error propio que cada adaptador traduce a su protocolo.

🔬 **El detalle:** La entidad debe impedir las transiciones inválidas aunque el caso de uso se
equivoque. Duplicar una comprobación en el borde por experiencia de usuario está bien; moverla al
borde es el error.

### 9. 🟡 ¿Cómo expresas idempotencia?

⏱️ **30 segundos:** Con una clave de operación en el contrato propio que el caso de uso pueda
reconocer y recordar.

🗣️ **2 minutos:** El comando lleva un `operationId`; el caso de uso, antes de ejecutar, comprueba si
esa operación ya se aplicó y, si es así, devuelve el resultado anterior. No la ato al header HTTP:
un mensaje o un job también pueden repetirse, y cada adaptador traduce su identificador de operación
al mismo campo. Si la misma clave llega con otro contenido, es un error distinto que conviene
detectar.

🔬 **El detalle:** Requiere almacenamiento o una política para recordar las operaciones procesadas,
idealmente en la misma transacción que el efecto, para que no haya una ventana entre "hecho" y
"recordado". Y una retención que cubra la ventana real de reintentos.

### 10. 🟡 ¿Qué devuelve un port de entrada?

⏱️ **30 segundos:** Un resultado de aplicación o un error propio, nunca objetos del transporte.

🗣️ **2 minutos:** Puede ser un tipo de resultado (`OrderCreated` con id y estado), una unión de
resultados posibles o una excepción tipada, según el lenguaje. El adaptador lo traduce a lo que su
protocolo necesita: JSON y status en HTTP, un mensaje de respuesta y un ACK en una cola, una línea y
un código de salida en una CLI. El mismo resultado sirve a todos porque no presupone ninguno.

🔬 **El detalle:** No devuelvas `ResponseEntity`, un objeto del broker ni una entidad ORM. Cada uno
de ellos obliga a los demás adaptadores a conocer un protocolo ajeno o una tecnología de
persistencia.

### 11. 🟡 ¿Cuándo compartirías un command?

⏱️ **30 segundos:** Cuando varios drivers expresan la misma intención con la misma semántica y las
mismas reglas.

🗣️ **2 minutos:** Si HTTP y una cola crean pedidos con las mismas validaciones de negocio, ambos
construyen el mismo `CreateOrderCommand` y el caso de uso es uno. Compartiría el contrato propio, no
el request ni el mensaje completos: cada adaptador conserva sus campos de transporte. Eso asegura
que una regla nueva afecte a ambas entradas automáticamente.

🔬 **El detalle:** Campos comunes no bastan si las intenciones difieren. Dos comandos con los mismos
cinco campos pero reglas distintas son dos comandos; unirlos obliga a añadir banderas y `if` por
origen.

### 12. 🟡 ¿Cuándo separarías dos commands?

⏱️ **30 segundos:** Cuando tienen reglas, permisos, errores o razones de cambio distintas, aunque
compartan datos.

🗣️ **2 minutos:** Una compra interactiva y una importación batch pueden crear pedidos, pero la
compra exige stock inmediato y pago, y la importación quizá acepta pedidos ya pagados en otro
sistema, con otros permisos y otra idempotencia. Forzarlas en un comando universal produce un caso
de uso lleno de condicionales. Dos comandos, quizá dos casos de uso que comparten dominio, expresan
mejor las dos intenciones.

🔬 **El detalle:** Evita el comando universal con campos opcionales para cada origen. Es el
equivalente en la entrada del repositorio genérico en la salida: parece reutilizable y esconde
decisiones.

### 13. 🟡 ¿Qué coste tiene mapear request a command?

⏱️ **30 segundos:** Código y mantenimiento: un tipo más y un mapper que actualizar con cada campo, a
cambio de desacoplar transporte y aplicación.

🗣️ **2 minutos:** El coste se paga cuando el transporte o el núcleo evolucionan por separado: una v2
de la API con nombres distintos que traduce al mismo comando, o un comando que gana un campo interno
que la API no expone. También se paga cuando hay otra entrada que construye el mismo comando. Sin
esas fuerzas, el mapper es una copia de campos que alguien olvidará actualizar.

🔬 **El detalle:** Si no hay frontera real —servicio interno, un solo cliente, API que cambia junto
al dominio—, puede ser ceremonia. La decisión conviene registrarla, para que el día que la API se
haga pública alguien sepa que falta esa separación.

### 14. 🟡 ¿Cómo pruebas el contrato de entrada?

⏱️ **30 segundos:** Invocando el puerto directamente con comandos válidos e inválidos y verificando
resultados y errores.

🗣️ **2 minutos:** Las pruebas del puerto cubren las reglas: pedido válido crea y devuelve id; stock
insuficiente devuelve el error propio y no deja nada guardado; la misma operación dos veces devuelve
el mismo resultado. Aparte, pruebo cada adaptador para confirmar que mapea bien: que el JSON
correcto produce el comando esperado y que cada error del núcleo produce el status y el cuerpo del
contrato.

🔬 **El detalle:** Una prueba del puerto no prueba routing ni serialización. Son dos anillos
distintos; mezclarlos en pruebas HTTP de extremo a extremo para cada regla las hace lentas y
ambiguas.

### 15. 🟡 ¿Qué diferencia hay entre tipo estático y validación runtime?

⏱️ **30 segundos:** El tipo estático ayuda al compilador a comprobar tu código; la validación
runtime comprueba los datos reales que llegan de fuera.

🗣️ **2 minutos:** Un JSON, un mensaje o un formulario entregan datos que ningún compilador ha visto.
En TypeScript, declarar que el cuerpo es `CreateOrderDto` no lo inspecciona: los tipos se borran al
compilar. En Python, las anotaciones no se comprueban salvo que una librería lo haga. Por eso el
adaptador valida con un esquema o un parser y construye el comando; a partir de ahí, los tipos
estáticos protegen el resto del camino.

🔬 **El detalle:** Ambos mecanismos cumplen funciones distintas y se complementan: la validación
runtime convierte datos desconocidos en tipos confiables; los tipos estáticos evitan que el código
los use mal después.

### 16. 🟡 ¿Por qué un `dict` puede ser un contrato débil?

⏱️ **30 segundos:** Porque permite formas y claves implícitas que nadie revisa: el contrato vive en
la cabeza de quien lo escribió.

🗣️ **2 minutos:** Un caso de uso que recibe `dict` acepta cualquier cosa; los errores de clave o de
tipo aparecen tarde, lejos de su origen, y el editor no ayuda a descubrir qué campos existen. Un
comando tipado (dataclass, modelo validado) hace visibles la intención, los campos obligatorios y
los errores. Además documenta el contrato para quien escribe otro adaptador.

🔬 **El detalle:** Python puede usar dataclasses, `TypedDict`, `Protocol` o modelos Pydantic en el
borde sin perder flexibilidad. La flexibilidad de `dict` es útil al parsear; dentro del núcleo,
suele ser deuda.

### 17. 🟠 HTTP y mensajería usan campos distintos. ¿Cómo los unes?

⏱️ **30 segundos:** Cada adaptador traduce su formato a un comando común, solo si la intención
coincide.

🗣️ **2 minutos:** HTTP puede traer `customerId` en el token y las líneas en el cuerpo; el mensaje,
todo en un sobre con otro nombre de campos y una versión de esquema. Cada adaptador conoce su
formato y construye el mismo `CreateOrderCommand`. Headers, ACK, versión de esquema y metadatos
quedan fuera: se comparte la semántica, no el protocolo. Una prueba de mapeo por adaptador garantiza
que ambos producen el mismo comando para la misma intención.

🔬 **El detalle:** Si la intención cambia —el mensaje trae pedidos de otro canal con otras reglas—,
separo comandos en lugar de estirar el común.

### 18. 🟠 Un mensaje se redelivera. ¿Quién protege la idempotencia?

⏱️ **30 segundos:** El contrato y el caso de uso, apoyados por una política de almacenamiento de
operaciones procesadas. El consumidor solo la aprovecha.

🗣️ **2 minutos:** El consumidor puede detectar que es una redelivery, pero no puede saber si la
primera entrega llegó a confirmar en la base antes de caer. Por eso la operación debe ser segura
aunque llegue otra vez: el comando lleva un `operationId` estable del productor, el caso de uso lo
registra en la misma transacción que el efecto y, si ya existe, devuelve el resultado anterior. El
ACK se envía después del commit.

🔬 **El detalle:** El ACK solo no garantiza idempotencia: confirmar antes de ejecutar pierde
mensajes, y confirmar después puede repetirlos. La única combinación segura es ACK después del
commit más deduplicación.

### 19. 🟠 El port recibe headers de autenticación. ¿Qué cambias?

⏱️ **30 segundos:** Hago que el adaptador convierta la autenticación en un actor o en permisos
propios, y que el puerto reciba solo eso.

🗣️ **2 minutos:** El adaptador verifica el token (firma, expiración, audiencia) y construye
`Actor(id, role)` con los claims permitidos. El núcleo no interpreta JWT: recibe el contexto mínimo
para decidir. Esto permite que un job o un consumidor invoquen el caso de uso con un actor de
servicio, sin fingir un token, y que cambiar el mecanismo de autenticación no toque la política.

🔬 **El detalle:** Los headers siguen siendo responsabilidad del borde. Si el núcleo los recibe,
también recibe la tentación de confiar en headers no verificados, que es una vulnerabilidad clásica.

### 20. 🟠 Una query necesita paginación. ¿Qué parte es transporte?

⏱️ **30 segundos:** El formato del cursor, los parámetros de URL y los enlaces de siguiente página
son transporte; el límite y el orden semántico pueden ser contrato de la consulta.

🗣️ **2 minutos:** El adaptador lee `limit` y `cursor` de la query string, acota el límite,
decodifica el cursor opaco y construye una petición de lectura propia (`after`, `limit`, orden por
fecha). La aplicación devuelve una página con elementos y un marcador de continuación; el adaptador
lo codifica como cursor opaco y lo expone en el formato de la API. Así un cambio de estilo de
paginación no toca la aplicación.

🔬 **El detalle:** Evito filtrar objetos de framework como `Pageable` al núcleo. Y prefiero cursores
estables a offsets cuando los datos cambian mientras se pagina, porque los offsets saltan o repiten
filas.

### 21. 🟠 ¿Qué haces si un driver necesita una operación que otro no?

⏱️ **30 segundos:** Creo un puerto o un comando separado si la intención difiere. No hincho el
contrato común.

🗣️ **2 minutos:** Si la CLI de operación necesita "forzar cancelación" y HTTP no, eso es otra
intención con otros permisos: un caso de uso `ForceCancelOrder` o un comando distinto. Añadirla como
parámetro opcional al puerto común obliga a todos los adaptadores a conocerla y a la aplicación a
ramificar. Cada driver depende solo de los puertos que usa.

🔬 **El detalle:** La segregación sigue razones de cambio. Si la operación extra comparte reglas con
la común, ambas pueden reutilizar el mismo dominio aunque sean casos de uso distintos.

### 22. 🟠 ¿Cómo versionas un port de entrada?

⏱️ **30 segundos:** Evoluciono el contrato de forma compatible cuando la semántica no cambia, y creo
una intención nueva cuando sí cambia.

🗣️ **2 minutos:** Versionar HTTP no obliga a versionar el núcleo: la v1 y la v2 de la API pueden
traducir al mismo comando, cada una con su mapper. El puerto solo cambia cuando cambia la capacidad
de negocio; si el cambio es compatible (un campo opcional nuevo), se añade con valor por defecto; si
no lo es, se crea un comando o caso de uso nuevo y se mantiene el viejo mientras tenga consumidores.

🔬 **El detalle:** Un cambio de negocio sí requiere revisar el puerto. Lo que conviene evitar es la
versión espejo: `CreateOrderV2` solo porque existe `/v2/orders`, cuando la intención es la misma.

### 23. 🟠 ¿Qué evidencia muestra que el port está acoplado a HTTP?

⏱️ **30 segundos:** Tipos del framework web, status codes, headers o errores web en su firma o en
sus resultados.

🗣️ **2 minutos:** Señales concretas: el comando lleva anotaciones de validación HTTP o
`@JsonProperty`; el resultado es `ResponseEntity`; los errores son `HttpException`; la paginación
usa `Pageable`; la autenticación llega como `Authentication` del framework. También cuenta que los
nombres del contrato sigan a los de la API pública en vez de a los del negocio. Cualquiera de ellas
hace que otra entrada tenga que imitar HTTP.

🔬 **El detalle:** El acoplamiento se corrige en el adaptador: todo lo que hoy recibe o devuelve el
puerto con forma HTTP pasa a construirse o traducirse ahí, y el puerto queda con tipos propios.

### 24. 🟠 ¿Cuándo un port de entrada puede ser una función?

⏱️ **30 segundos:** Cuando la capacidad tiene una firma simple y no necesita un objeto de contrato
complejo ni varias operaciones.

🗣️ **2 minutos:** En Go, Python o TypeScript, un caso de uso como función `create_order(command) ->
result` que cierra sobre sus dependencias es claro y fácil de sustituir en pruebas. En Java, una
clase con un método `execute` cumple el mismo papel. Lo que importa es que la firma use tipos
propios y que el adaptador dependa de ella, no de detalles internos.

🔬 **El detalle:** La frontera sigue siendo explícita por módulo y tipos: una función en el paquete
de aplicación, que no importa infraestructura, es un puerto tan bueno como una interfaz.

---

## 04 · Puertos de salida

### 1. 🟢 ¿Qué es un puerto de salida?

⏱️ **30 segundos:** Una capacidad que el núcleo necesita del exterior, expresada en sus propios
términos: guardar pedidos, saber la hora, autorizar un pago.

🗣️ **2 minutos:** `Orders`, `Clock` y `PaymentGateway` son ejemplos del sistema de pedidos. El caso
de uso los recibe por constructor y los usa sin saber qué hay detrás: JPA o SQL, el reloj del
sistema o uno fijo, un proveedor HTTP o gRPC. Esa ignorancia deliberada es la que permite probar la
política con fakes y cambiar la tecnología escribiendo otro adaptador. Es la mitad de salida de la
simetría hexagonal.

🔬 **El detalle:** El consumidor define el contrato. Un puerto de salida cuyo diseño empezó leyendo
la documentación del proveedor suele terminar siendo un espejo de ese proveedor.

### 2. 🟢 ¿Quién debe definirlo?

⏱️ **30 segundos:** El caso de uso o la parte del núcleo que lo necesita. El proveedor se adapta; no
dicta.

🗣️ **2 minutos:** Cuando lo define el consumidor, el contrato expresa exactamente la decisión que
hay que tomar: `authorize(operationId, amount)` con tres resultados posibles. El adaptador traduce
la semántica del proveedor —sus estados, códigos y reintentos— a esa semántica. Cuando lo define el
proveedor, el núcleo hereda su vocabulario y su ritmo de cambio, y un segundo proveedor obliga a
cambiar la política.

🔬 **El detalle:** No copies el API externo por defecto. Si el contrato propio termina pareciéndose
al del proveedor porque el problema es el mismo, bien; lo importante es que el parecido sea una
conclusión, no el punto de partida.

### 3. 🟢 ¿Qué diferencia hay entre port y adapter de salida?

⏱️ **30 segundos:** El puerto es el contrato; el adaptador es la implementación que traduce a una
tecnología concreta.

🗣️ **2 minutos:** `PaymentGateway` dice "autoriza este importe con esta clave y dime si quedó
autorizado, rechazado o incierto". `StripePaymentGateway` usa el SDK, construye la petición, añade
la clave de idempotencia, fija el timeout, llama y mapea la respuesta a uno de los tres resultados.
El caso de uso `AuthorizePayment` solo conoce el primero; el composition root decide cuál de las
implementaciones recibe.

🔬 **El detalle:** La flecha de código va del adaptador al puerto: el adaptador importa el contrato
para implementarlo, y el núcleo no importa nada del adaptador. En ejecución, en cambio, la llamada
va del núcleo al adaptador.

### 4. 🟢 ¿Por qué aislar el reloj?

⏱️ **30 segundos:** Porque el tiempo influye en reglas de negocio y las pruebas necesitan
controlarlo.

🗣️ **2 minutos:** Vencimientos de reservas, ventanas de cancelación, cierres diarios o expiración de
tokens dependen de "ahora". Si el código llama al reloj del sistema directamente, una prueba de "la
reserva vence a los 15 minutos" necesita esperar o manipular el sistema. Con un `Clock` inyectado,
la prueba fija la hora, avanza el tiempo a voluntad y reproduce exactamente una decisión pasada.

🔬 **El detalle:** Evita depender de un global no controlable. Java trae `java.time.Clock`; en otros
lenguajes basta una función `now()` inyectada. Es de los puertos más baratos y más rentables.

### 5. 🟢 ¿Qué expresa un `PaymentGateway`?

⏱️ **30 segundos:** La capacidad de autorizar (y, si el negocio lo necesita, capturar o reembolsar)
un pago, con resultados propios.

🗣️ **2 minutos:** Expresa qué necesita el caso de uso: pedir una autorización para un importe con
una clave de operación y recibir un resultado que la política entienda —autorizado, rechazado,
incierto—. No expresa URLs, endpoints, formatos de petición, códigos de estado ni nombres de estados
del proveedor. Tampoco decide qué pasa con el pedido según el resultado: eso lo decide el núcleo.

🔬 **El detalle:** El adaptador traduce los estados externos. El resultado incierto merece estar en
el contrato desde el principio, porque es un resultado de negocio real (no sé si se cobró) que
cualquier proveedor remoto puede producir.

### 6. 🟢 ¿Qué es un repositorio desde el punto de vista del núcleo?

⏱️ **30 segundos:** Una colección o capacidad de persistencia con semántica de dominio: guardar y
recuperar agregados en los términos que el caso de uso necesita.

🗣️ **2 minutos:** Para el núcleo, `Orders` es "el lugar donde están los pedidos": se puede buscar
uno por id, guardarlo, quizá buscar los pendientes de un cliente. No es necesariamente el
repositorio del ORM, que ofrece decenas de métodos genéricos, paginación y consultas derivadas. Sus
métodos existen porque un caso de uso los necesita, con nombres de negocio.

🔬 **El detalle:** Sus métodos deben servir a casos de uso concretos. Si un método del puerto no
tiene ningún caso de uso que lo llame, sobra; si un caso de uso necesita una consulta muy
específica, merece un método con nombre propio antes que un `findBy(criteria)` genérico.

### 7. 🟢 ¿Qué no debería devolver el port?

⏱️ **30 segundos:** Entidades ORM, DTO del proveedor, filas crudas y errores tecnológicos sin
traducir.

🗣️ **2 minutos:** Devuelve entidades de dominio, resultados propios o errores propios. Si devuelve
una entidad ORM, el núcleo arrastra lazy loading y anotaciones; si devuelve el DTO del proveedor, el
núcleo depende de su formato; si deja pasar `SQLException` o la excepción del SDK, el caso de uso
tiene que conocer la tecnología para decidir. Cada una de esas fugas convierte al puerto en una
interfaz decorativa.

🔬 **El detalle:** La traducción mantiene la frontera, y tiene un coste: mapper, tipos propios y
pruebas. Ese coste es exactamente lo que compra la independencia.

### 8. 🟡 ¿Cómo diseñas un port desde la necesidad?

⏱️ **30 segundos:** Enumero la decisión que el caso de uso debe tomar y expreso la mínima capacidad
que necesita para tomarla.

🗣️ **2 minutos:** Para `AuthorizePayment`, la decisión es qué estado toma el pedido; necesito saber
si el pago quedó autorizado, rechazado o incierto. De ahí sale el contrato: una operación, tres
resultados, una clave de idempotencia. Después reviso datos (qué tipo tiene el importe, qué
identificadores), errores (qué fallos puede decidir el caso de uso y cuáles son técnicos) y
consistencia (¿el proveedor participa de la transacción? no), sin empezar por el SDK.

🔬 **El detalle:** El contrato se valida escribiendo el caso de uso y un doble del puerto. Si el
doble se escribe en pocas líneas y el caso de uso se lee como la regla de negocio, el diseño es
bueno.

### 9. 🟡 ¿Separarías lectura y escritura?

⏱️ **30 segundos:** Sí, si tienen necesidades, modelos o razones de cambio distintas. No por norma.

🗣️ **2 minutos:** Un comando carga el agregado completo para proteger invariantes; una consulta de
listado puede usar una proyección con cinco campos y un join optimizado. Si ambas comparten un
puerto, o el comando carga proyecciones incompletas o la consulta hidrata agregados innecesarios.
Separarlas en `Orders` (escritura) y `OrderSummaries` (lectura) permite optimizar cada una y
cambiarlas por separado.

🔬 **El detalle:** No es obligación de CQRS ni requiere dos bases; es cohesión. En un servicio
pequeño con lecturas triviales, un solo puerto está bien.

### 10. 🟡 ¿Qué es una proyección propia?

⏱️ **30 segundos:** Un tipo de resultado definido por la aplicación para una lectura concreta, con
los campos que esa lectura necesita.

🗣️ **2 minutos:** `OrderSummary(id, status, total, createdAt)` para la lista de pedidos de un
cliente es una proyección propia: no es la entidad, no es la fila, es lo que la pantalla o el
informe necesitan. El adaptador puede construirla desde una consulta SQL específica sin exponer
filas ni entidades ORM, y la aplicación la entrega sin cargar agregados. Es la forma de optimizar
lecturas sin deformar el modelo de dominio.

🔬 **El detalle:** Optimiza la lectura sin deformar el dominio: el agregado conserva la forma que
exigen sus invariantes, y cada lectura tiene la forma que exige su consumidor.

### 11. 🟡 ¿Qué debe garantizar un fake?

⏱️ **30 segundos:** La semántica relevante del puerto: los mismos resultados y errores que el
adaptador real para las situaciones que el caso de uso ejercita.

🗣️ **2 minutos:** Un fake de `Orders` debe devolver vacío si no existe, conservar lo guardado y, si
el caso de uso depende de ello, rechazar un conflicto de versión o un duplicado como lo haría la
base. Si acepta estados que el real rechaza, el test pasa y producción falla: confianza falsa. La
forma práctica de asegurarlo es un test de contrato que ejecute las mismas expectativas contra el
fake y contra el adaptador real.

🔬 **El detalle:** El fake no sustituye las pruebas de integración: no reproduce SQL, índices,
bloqueos ni rendimiento. Cubre la coordinación del caso de uso; la integración cubre el detalle.

### 12. 🟡 ¿Por qué evitar un repository genérico?

⏱️ **30 segundos:** Porque mezcla necesidades y borra el lenguaje de negocio: todo se vuelve `save`,
`find` y `delete` con criterios.

🗣️ **2 minutos:** `Repository<T>` con `save/find/delete/findBy(spec)` no expresa reservas,
autorizaciones ni reglas de lectura. El caso de uso termina construyendo consultas con vocabulario
de base, y cualquier consumidor puede hacer cualquier cosa (borrar pedidos, por ejemplo, cuando el
negocio nunca borra). Un puerto específico con `reserve`, `release` o `pendingFor(customer)`
documenta qué se permite y es más fácil de implementar y de simular.

🔬 **El detalle:** Un contrato genérico también crece sin control: cada necesidad nueva se resuelve
con otro criterio dinámico, y el adaptador acaba siendo un constructor de consultas que nadie puede
optimizar.

### 13. 🟡 ¿Dónde vive una interfaz en Go?

⏱️ **30 segundos:** Normalmente junto al consumidor que necesita el comportamiento, en el paquete
del caso de uso.

🗣️ **2 minutos:** Como la satisfacción es implícita, el adaptador no necesita importar nada para
implementarla: basta con que tenga los métodos. Eso hace natural declarar interfaces pequeñas donde
se usan (`type Orders interface { Save(...) error }` en el paquete de aplicación) y evita paquetes
comunes de interfaces sin dueño. También permite que cada consumidor declare solo los métodos que
usa, aunque el adaptador tenga más.

🔬 **El detalle:** Es convención, no mandato del lenguaje. Hay casos razonables para declarar la
interfaz junto al productor —por ejemplo, cuando muchos consumidores comparten exactamente el mismo
contrato—, pero el punto de partida idiomático es el consumidor.

### 14. 🟡 ¿Qué errores cruza el port?

⏱️ **30 segundos:** Errores que el caso de uso puede decidir, ya traducidos desde los detalles
externos a conceptos propios.

🗣️ **2 minutos:** Un rechazo del proveedor es una decisión de negocio (`Rejected`); un timeout
después de enviar es incertidumbre (`UnknownResult`), también de negocio; una credencial inválida o
un error de configuración son fallos técnicos que el caso de uso no puede resolver y deben
propagarse como tales y alertar a operación. El adaptador clasifica y traduce; el caso de uso decide
qué hacer con cada categoría.

🔬 **El detalle:** La observabilidad técnica no debe perderse al traducir: el adaptador registra la
causa original (código, mensaje, latencia) antes de convertirla, para que la traducción no esconda
un incidente.

### 15. 🟡 ¿Cómo pruebas un caso de uso con un port de salida?

⏱️ **30 segundos:** Inyecto un fake fiel del puerto y verifico la decisión, el resultado y el estado
final.

🗣️ **2 minutos:** Para `AuthorizePayment`: un fake de `PaymentGateway` configurable para devolver
autorizado, rechazado o incierto, y un fake de `Orders`. Tres pruebas, una por resultado,
comprobando el estado que queda en el pedido. Luego pruebo el adaptador por separado, contra el
proveedor en un entorno de pruebas o contra un servidor simulado que reproduzca sus respuestas,
timeouts y errores.

🔬 **El detalle:** Cada nivel prueba una frontera distinta. Mezclarlos —probar el caso de uso contra
el proveedor real— hace las pruebas lentas, inestables y ambiguas sobre qué falló.

### 16. 🟡 ¿Cuándo compartirías un port entre casos de uso?

⏱️ **30 segundos:** Cuando expresan la misma capacidad con el mismo contrato y la misma semántica.

🗣️ **2 minutos:** `CreateOrder` y `CancelOrder` pueden compartir `Orders` porque ambos cargan y
guardan pedidos con las mismas reglas de persistencia. En cambio, si un caso de uso necesita leer
pedidos para un informe con otra consistencia y otra forma, comparte base pero no puerto. Si dos
casos de uso solo comparten proveedor pero necesitan semánticas distintas (autorizar y consultar
historial), separo puertos aunque los implemente el mismo adaptador.

🔬 **El detalle:** Compartir por tecnología es una señal de riesgo: un puerto "todo lo de PostgreSQL"
o "todo lo del proveedor" no describe ninguna necesidad de negocio.

### 17. 🟠 El proveedor devuelve diez estados y el negocio usa tres. ¿Dónde traduces?

⏱️ **30 segundos:** En el adaptador. El núcleo solo ve los tres estados que sabe decidir.

🗣️ **2 minutos:** Mapeo cada estado externo a un concepto propio: `succeeded` a `Authorized`;
`declined`, `blocked` y `expired_card` a `Rejected`; `processing`, `requires_action` y los timeouts
a `UnknownResult`. Esa tabla vive en el adaptador, tiene pruebas propias y es el único lugar que
cambia cuando el proveedor añade un estado. Si un estado nuevo no encaja en los tres, es una
conversación con negocio, no un parche en el adaptador.

🔬 **El detalle:** Registro el detalle técnico —el estado original, el código de rechazo— en logs o
en un campo de auditoría, sin convertirlo en contrato del núcleo. Operación lo necesita; la
política, no.

### 18. 🟠 Un repositorio tiene veinte métodos. ¿Qué haces?

⏱️ **30 segundos:** Reviso qué consumidores usan qué métodos y separo por capacidades, lecturas y
escrituras.

🗣️ **2 minutos:** Hago el inventario: los métodos de escritura que usan los casos de uso de comando,
las lecturas de informes, las consultas administrativas, los que nadie usa. Suelen aparecer tres o
cuatro puertos cohesivos y varios métodos que se pueden borrar. El adaptador puede seguir siendo una
sola clase que implementa varios puertos si el recurso es el mismo; lo que cambia es qué ve cada
caso de uso.

🔬 **El detalle:** No divido solo por estética o por un número máximo de métodos. Si veinte métodos
cambian juntos y los usa el mismo consumidor, el problema no es el tamaño.

### 19. 🟠 El caso de uso necesita tiempo y zona horaria. ¿Qué port diseñas?

⏱️ **30 segundos:** Un `Clock` que exponga el instante actual y, si la regla lo necesita, la zona
horaria de negocio de forma explícita.

🗣️ **2 minutos:** La aplicación obtiene una fecha controlable y el dominio aplica la regla con ella:
"el cierre diario ocurre a medianoche en la zona del almacén". La zona de negocio no debería salir
de la zona del servidor ni de un header del cliente, sino de configuración o del propio dato (el
almacén tiene zona). Así la prueba fija instante y zona y reproduce los casos difíciles: cambios de
horario, fin de mes, medianoche.

🔬 **El detalle:** Evito pasar un objeto de framework o usar la zona por defecto de la JVM o del
sistema, que cambia entre entornos y produce bugs que solo aparecen en producción.

### 20. 🟠 El fake se comporta distinto de PostgreSQL. ¿Qué prueba falta?

⏱️ **30 segundos:** Una prueba de integración del adaptador contra PostgreSQL, y un test de contrato
que ejecute las mismas expectativas contra ambos.

🗣️ **2 minutos:** El fake cubre la coordinación del caso de uso; PostgreSQL cubre restricciones,
tipos, consultas, transacciones y concurrencia reales. Cuando divergen, la prueba de contrato lo
detecta: por ejemplo, guardar dos pedidos con la misma clave de operación debe fallar en ambos.
Corregiría el fake para que respete esa semántica y dejaría la prueba de integración como red de
seguridad.

🔬 **El detalle:** No intentes que un fake reproduzca todo el motor: aislamiento, bloqueos o planes
de consulta no se simulan bien. Esas propiedades se prueban donde existen, en integración.

### 21. 🟠 El SDK usa excepciones propias. ¿Cómo las traduces?

⏱️ **30 segundos:** En el adaptador, clasificándolas por significado para la aplicación: rechazo,
incertidumbre o fallo técnico.

🗣️ **2 minutos:** Una `CardDeclinedException` se convierte en `Rejected`; un timeout de lectura
después de enviar, en `UnknownResult`; un `AuthenticationException` por credenciales, en un error
técnico que se propaga y alerta; un error de validación del SDK por datos mal formados, en un bug
que debe fallar ruidosamente. Cada categoría tiene tratamiento distinto en el caso de uso y
observabilidad propia en el adaptador.

🔬 **El detalle:** No conviertas todo en "error genérico": esconde incidentes y, en pagos, puede
afirmar que un cobro falló cuando no se sabe. La traducción conserva la causa original para
diagnóstico.

### 22. 🟠 Dos proveedores requieren contratos distintos. ¿Compartes port?

⏱️ **30 segundos:** Solo si ofrecen la misma capacidad semántica al núcleo. Si no, las diferencias
deben ser explícitas.

🗣️ **2 minutos:** Si ambos autorizan pagos con los mismos resultados, comparten `PaymentGateway` y
cada adaptador traduce sus diferencias. Si uno soporta captura diferida y el otro solo cobro
inmediato, quizá sean puertos distintos, o una capacidad opcional que el caso de uso consulta
explícitamente. Lo que evito es un contrato común con métodos que un adaptador implementa lanzando
"no soportado", porque obliga al núcleo a saber qué proveedor hay detrás.

🔬 **El detalle:** La compatibilidad se prueba con adaptadores reales: un test de contrato que ambos
deben pasar es la única forma de saber que el puerto es realmente común.

### 23. 🟠 ¿Qué indica que el port es un espejo del ORM?

⏱️ **30 segundos:** Que tiene los mismos métodos, tipos, paginación y errores que el framework:
`findAll`, `Pageable`, `Optional<Entity>`, excepciones del ORM.

🗣️ **2 minutos:** Otras señales: métodos con nombres derivados de consultas
(`findByCustomerIdAndStatusOrderByCreatedAtDesc`), entidades anotadas como tipo de retorno, uso de
`Specification` o criterios del ORM en los parámetros. El caso de uso queda obligado a pensar como
el ORM —en consultas y en entidades gestionadas— y no como el negocio. Cambiar de tecnología
cambiaría el puerto.

🔬 **El detalle:** Lo rediseño desde la necesidad mínima de cada caso de uso: qué busca, con qué
nombre de negocio y qué devuelve. El ORM queda como detalle del adaptador.

### 24. 🟠 ¿Cómo defenderías un port pequeño ante una futura implementación?

⏱️ **30 segundos:** La implementación futura debe satisfacer la capacidad actual, no justificar hoy
un API especulativo.

🗣️ **2 minutos:** Mantengo el contrato mínimo que el caso de uso necesita y añado cambios cuando
aparezca la segunda semántica real. Un puerto pequeño es fácil de implementar por cualquier
proveedor nuevo, fácil de simular y fácil de entender; uno grande "por si acaso" obliga a cada
implementación a cubrir métodos que nadie usa y fija decisiones sin evidencia. Si el futuro trae una
capacidad nueva, se añade con el conocimiento de ese momento.

🔬 **El detalle:** Evolucionar un contrato pequeño es más barato que mantener uno genérico enorme. La
excepción son los resultados de negocio que ya existen aunque hoy no se vean —como la incertidumbre
de un pago remoto—: esos van desde el principio.

---

## 05 · Transacciones y límites de consistencia

### 1. 🟢 ¿Qué problema resuelve una transacción?

⏱️ **30 segundos:** Evita que una unidad de consistencia quede aplicada a medias: o todos sus
cambios locales se confirman, o ninguno.

🗣️ **2 minutos:** Crear un pedido implica guardar el pedido y reservar el inventario. Si el pedido
se guarda y la reserva falla, queda un pedido sin stock comprometido; si la reserva se guarda y el
pedido no, queda stock bloqueado para nada. La transacción agrupa esos cambios para que confirmen
juntos o se reviertan si algo falla, y además aísla a los lectores de estados intermedios según el
nivel de aislamiento elegido.

🔬 **El detalle:** No vuelve atómicas las llamadas remotas ni corrige un límite de negocio mal
elegido. Si la consistencia que necesitas cruza dos bases o un proveedor, la transacción local no la
cubre y hace falta otra estrategia.

### 2. 🟢 ¿Qué es un límite transaccional?

⏱️ **30 segundos:** La frontera que define qué operaciones confirman o revierten como una unidad.

🗣️ **2 minutos:** Suele rodear un comando de aplicación y los recursos locales que deben quedar
consistentes entre sí: en `CreateOrder`, el pedido, la reserva y el registro de la outbox en la
misma base. Fuera quedan el proveedor de pagos, el broker y el correo, que no participan del commit.
Elegir bien el límite es una decisión de diseño: demasiado pequeño deja estados parciales; demasiado
grande bloquea recursos y mezcla responsabilidades.

🔬 **El detalle:** Debe poder dibujarse indicando qué queda dentro, qué queda fuera y qué puede
repetirse. Si no se puede dibujar, el límite no está decidido; está implícito en dónde cayeron las
anotaciones.

### 3. 🟢 ¿Por qué el caso de uso suele ser una buena frontera?

⏱️ **30 segundos:** Porque conoce la decisión completa y todas las colaboraciones que la componen.

🗣️ **2 minutos:** `CreateOrder` sabe qué carga, qué modifica y qué guarda para completar una
intención de negocio; un repositorio aislado solo conoce su propia operación y no puede saber si
forma parte de algo mayor. Por eso la transacción se abre alrededor del caso de uso y los
repositorios participan en ella. Además, un comando por transacción es fácil de razonar: si el
comando falla, nada de él quedó aplicado.

🔬 **El detalle:** La mecánica puede envolverlo desde la composición —un decorador transaccional, una
fachada con `@Transactional`, un `UnitOfWork.run(...)`— sin filtrar el ORM al núcleo.

### 4. 🟢 ¿Qué diferencia hay entre commit y rollback?

⏱️ **30 segundos:** El commit confirma y hace visibles los cambios; el rollback descarta los cambios
no confirmados.

🗣️ **2 minutos:** Ambos cierran la transacción y liberan sus recursos, pero producen estados
observables opuestos: tras el commit, otros ven el pedido; tras el rollback, es como si nunca se
hubiera intentado. El coordinador debe garantizar que siempre ocurre uno de los dos, incluso ante
excepciones, para no dejar conexiones abiertas ni bloqueos colgados. Un commit también puede fallar
(conflicto, desconexión), y ese fallo necesita tratamiento propio.

🔬 **El detalle:** El rollback no deshace un correo, un pago o un mensaje remoto ya ejecutado. Por
eso los efectos externos se ejecutan después del commit, normalmente desde una outbox.

### 5. 🟢 ¿Qué es una unidad de trabajo?

⏱️ **30 segundos:** Un mecanismo que coordina un conjunto de cambios y los confirma o revierte
juntos.

🗣️ **2 minutos:** Permite que varios repositorios compartan una transacción física sin exponer la
conexión al dominio ni al caso de uso. En la práctica puede ser un puerto `UnitOfWork.run(work)` que
abre la transacción, ejecuta el trabajo y confirma o revierte; los adaptadores de persistencia toman
la conexión de la transacción en curso. En Spring, el transaction manager cumple ese papel; en Go,
una función que recibe `sql.Tx`.

🔬 **El detalle:** Su API debe permanecer técnica y pequeña: empezar, confirmar, revertir, ejecutar.
Si empieza a acumular reglas de negocio o a decidir qué se guarda, se convierte en un segundo
dominio.

### 6. 🟢 ¿El dominio debe conocer una conexión?

⏱️ **30 segundos:** No. El dominio conoce conceptos y reglas de negocio, no conexiones, sesiones ni
transacciones.

🗣️ **2 minutos:** La aplicación y la infraestructura coordinan la transacción; el dominio cambia su
estado de forma válida y, como mucho, registra eventos. Si el dominio recibe una conexión, empieza a
decidir cuándo guardar, a ejecutar consultas y a depender del motor; sus pruebas necesitan una base.
La regla es que el dominio no sabe si se va a persistir ni cómo.

🔬 **El detalle:** Pasar `EntityManager`, `sql.Tx` o una sesión al dominio invierte la dependencia en
la dirección equivocada: la política pasa a depender del detalle más volátil del sistema.

### 7. 🟢 ¿Qué ocurre si falla una operación antes del commit?

⏱️ **30 segundos:** Se aborta la unidad de trabajo y se revierten todos sus cambios locales.

🗣️ **2 minutos:** El coordinador (el decorador transaccional o la unidad de trabajo) detecta el
error, hace rollback, cierra la transacción y propaga o traduce el error al caso de uso o al
adaptador de entrada. Desde fuera, la operación no ocurrió: el pedido no existe y la reserva no se
hizo. Eso es lo que hace seguro reintentar un comando fallido, siempre que no haya efectos externos
de por medio.

🔬 **El detalle:** Los efectos externos ya realizados requieren compensación: si antes del fallo se
llamó a un proveedor que cobró, el rollback local no lo devuelve. Esa es la razón para no llamar a
sistemas remotos dentro de la transacción.

### 8. 🟡 ¿Por qué no abrir una transacción en cada repositorio?

⏱️ **30 segundos:** Porque cada repositorio confirmaría sin conocer la decisión completa, y la
operación quedaría partida.

🗣️ **2 minutos:** Si `orders.save` y `reservations.save` abren y confirman cada uno su transacción,
el primero puede confirmar y el segundo fallar, dejando un estado parcial que ninguna regla permite.
Además, las lecturas intermedias ven estados incompletos. El repositorio no puede resolverlo porque
no sabe qué otras operaciones forman parte de la intención; esa información la tiene el caso de uso.

🔬 **El detalle:** El repositorio participa en la transacción definida por la aplicación; no la
posee. En Spring, un `@Transactional` en el repositorio se une a la transacción externa si existe,
pero si no existe crea una propia: por eso el límite hay que ponerlo arriba explícitamente.

### 9. 🟡 ¿Qué operaciones deberían participar en la misma transacción?

⏱️ **30 segundos:** Los cambios locales que deben ser visibles juntos para preservar una invariante
o una decisión de negocio.

🗣️ **2 minutos:** El pedido, su reserva de inventario y el registro de la outbox con `OrderCreated`
pueden compartir commit si viven en la misma base: así, o existen los tres o ninguno, y la
publicación posterior no puede perderse ni referirse a un pedido inexistente. La notificación real
al cliente, el cobro remoto o la actualización de un índice de búsqueda quedan fuera y ocurren
después.

🔬 **El detalle:** Incluir trabajo no relacionado aumenta el tiempo de bloqueo, la probabilidad de
conflicto y el coste del rollback. La transacción debe ser tan grande como la invariante y ni una
operación más.

### 10. 🟡 ¿Qué cambia cuando hay una llamada a un proveedor de pagos?

⏱️ **30 segundos:** Que ya no existe atomicidad local entre la base y el proveedor: son dos sistemas
con commits distintos.

🗣️ **2 minutos:** Hay que modelar explícitamente los estados intermedios y las fallas: el pedido
queda `PAYMENT_PENDING` antes de llamar; la llamada lleva una clave de idempotencia; el resultado se
registra en otra transacción corta; un timeout se trata como resultado incierto, que se resuelve
consultando al proveedor o reintentando con la misma clave. Según el proveedor, también puede usarse
una autorización reversible o una compensación (reembolso).

🔬 **El detalle:** Mantener abierta la transacción de la base durante la llamada de red no crea una
transacción distribuida: solo alarga los bloqueos y abre la posibilidad de que el proveedor cobre y
la base revierta.

### 11. 🟡 ¿Por qué una transacción no debe cubrir una llamada remota lenta?

⏱️ **30 segundos:** Porque prolonga bloqueos y conexiones sin controlar el resultado remoto.

🗣️ **2 minutos:** Mientras el proveedor tarda, la transacción mantiene filas bloqueadas y una
conexión del pool ocupada; con carga, el pool se agota y las demás peticiones esperan. Si la llamada
remota tiene éxito pero el commit falla después (timeout, conflicto), el efecto remoto ocurrió y la
base no lo sabe. Y si la llamada falla por timeout, no se sabe si el efecto ocurrió, pero la
transacción ya decidió revertir.

🔬 **El detalle:** Conviene separar fases y hacer explícito el estado intermedio: transacción corta
para registrar la intención, llamada fuera, transacción corta para registrar el resultado. El estado
pendiente es visible y recuperable.

### 12. 🟡 ¿Qué relación hay entre ACK e idempotencia?

⏱️ **30 segundos:** Si el proceso cae después del commit y antes del ACK, el broker reentrega el
mensaje; la idempotencia evita repetir el efecto.

🗣️ **2 minutos:** El orden seguro es: ejecutar el caso de uso, confirmar la transacción local y
después enviar el ACK. Ese orden no pierde mensajes, pero puede duplicarlos, porque entre commit y
ACK hay una ventana. El consumidor debe tolerar recibir el mismo mensaje otra vez: el caso de uso
reconoce la operación ya aplicada y devuelve el resultado anterior sin repetir el efecto.

🔬 **El detalle:** La deduplicación necesita una identidad estable de la operación (no el offset ni
el delivery tag) y persistirse alineada con el cambio, en la misma transacción. Si se registra en
otro sitio, vuelve a haber una ventana.

### 13. 🟡 ¿Cómo decides si un error provoca rollback?

⏱️ **30 segundos:** Según si la operación puede considerarse completa y consistente después de ese
error.

🗣️ **2 minutos:** Un fallo técnico en medio de la operación (la base cae, un conflicto de versión)
suele exigir rollback, porque los cambios hechos hasta ahí no forman un estado válido. Un rechazo de
negocio esperado (stock insuficiente) puede no haber modificado nada, o puede haber registrado algo
que sí debe persistir (un intento fallido auditado). La decisión depende del caso, y conviene
hacerla explícita en lugar de dejarla al tipo de excepción.

🔬 **El detalle:** La política debe ser explícita sobre todo con frameworks que deciden por tipo de
excepción: en Spring, por defecto solo las excepciones no comprobadas provocan rollback, y una
excepción de negocio comprobada puede dejar la transacción confirmada sin que nadie lo haya
decidido.

### 14. 🟡 ¿Qué deja explícito Go con `sql.Tx`?

⏱️ **30 segundos:** Qué operaciones usan la transacción y exactamente cuándo se confirma o revierte.

🗣️ **2 minutos:** En Go no hay proxy ni contexto implícito: `BeginTx` devuelve un `*sql.Tx`, las
consultas que deben participar se ejecutan sobre ese `tx`, y `Commit` o `Rollback` se llaman
explícitamente. El adaptador debe recibir la transacción (o un ejecutor que la envuelva) y usarla en
todas las operaciones; si alguna usa accidentalmente el `db` del pool, se ejecuta fuera de la
transacción y confirma sola.

🔬 **El detalle:** La verbosidad hace visible un error que otros frameworks ocultan con contexto
implícito. Una forma habitual de reducirla es poner la transacción en el `context` dentro de una
unidad de trabajo, para que los adaptadores la tomen de ahí sin que el dominio la vea.

### 15. 🟡 ¿Qué riesgo introduce una transacción declarativa en Spring?

⏱️ **30 segundos:** Que la anotación parezca cubrir más de lo que realmente intercepta el proxy.

🗣️ **2 minutos:** `@Transactional` funciona mediante un proxy que envuelve la llamada externa al
bean. Si un método del mismo objeto llama a otro anotado (self-invocation), no pasa por el proxy y
la anotación no aplica. La propagación por defecto (`REQUIRED`) une transacciones que quizá deberían
ser independientes; las excepciones comprobadas no provocan rollback salvo configuración; y los
métodos no públicos pueden no interceptarse según el modo. El límite efectivo puede diferir del que
se lee en el código.

🔬 **El detalle:** Hay que probar el comportamiento transaccional —provocar un fallo a mitad y
comprobar que no quedó nada—, no solo verificar que existe la anotación.

### 16. 🟡 ¿Para qué sirve el contexto asíncrono en Node?

⏱️ **30 segundos:** Para asociar datos —como el cliente de la transacción en curso— al flujo
asíncrono actual sin pasarlos por parámetro.

🗣️ **2 minutos:** `AsyncLocalStorage` permite que una unidad de trabajo guarde el cliente
transaccional al empezar y que los adaptadores lo recuperen en cualquier `await` posterior del mismo
flujo. Así los repositorios comparten transacción sin que el caso de uso la pase explícitamente.
Reduce el paso de contexto, pero cada operación debe usar el cliente correcto: si un adaptador usa
el cliente raíz, se sale de la transacción.

🔬 **El detalle:** No aporta atomicidad por sí mismo ni corrige promesas que escapan del callback
transaccional: una promesa lanzada sin `await` puede ejecutarse después del commit, fuera de la
transacción.

### 17. 🟠 Un repositorio confirma y otro falla. ¿Dónde está el defecto?

⏱️ **30 segundos:** En una frontera fragmentada: los repositorios controlan commits que pertenecen
al caso de uso.

🗣️ **2 minutos:** El síntoma es un estado parcial que ninguna regla permite, y el defecto es que
cada repositorio abre su propia transacción. Haría que ambos participen en una misma unidad de
trabajo si comparten recurso y deben ser consistentes: la transacción se abre alrededor del caso de
uso y los repositorios toman la conexión en curso. Añadiría una prueba de integración que provoque
el fallo del segundo y compruebe que el primero no quedó confirmado.

🔬 **El detalle:** Si usan recursos distintos (dos bases, o base y broker), una transacción local no
sirve: primero reviso si el límite de negocio está bien dibujado y luego modelo consistencia
eventual con outbox, estados pendientes o compensación.

### 18. 🟠 El pago remoto responde tarde y la transacción bloquea filas. ¿Qué rediseñas?

⏱️ **30 segundos:** Saco la llamada remota de la transacción y modelo una fase pendiente explícita.

🗣️ **2 minutos:** Primera transacción corta: el pedido pasa a `PAYMENT_PENDING` y se registra la
clave de la operación. Fuera de toda transacción: llamada al proveedor con esa clave y un deadline.
Segunda transacción corta: se registra el resultado (autorizado, rechazado) o se deja pendiente si
fue incierto, para resolverlo después con reintento idempotente o consulta. Los bloqueos duran
milisegundos y el estado intermedio es visible y recuperable.

🔬 **El detalle:** El orden exacto depende de qué es reversible: si reservar inventario es barato de
liberar y autorizar un pago no, se reserva primero y se libera si el pago se rechaza; si fuera al
revés, el orden cambia.

### 19. 🟠 Un consumidor procesa dos veces el mismo mensaje. ¿Qué proteges?

⏱️ **30 segundos:** La identidad de la operación y cada efecto que no se puede repetir: crear el
pedido, reservar stock, cobrar.

🗣️ **2 minutos:** Registro el identificador de operación que trae el mensaje junto con el cambio, en
la misma transacción, con una restricción única; si llega otra vez, la restricción o la consulta
previa lo detecta y se devuelve el resultado anterior. Cuando es posible, prefiero operaciones
naturalmente idempotentes (fijar un estado en lugar de incrementar). El ACK se envía después del
commit.

🔬 **El detalle:** Un ACK temprano reduce duplicados pero puede perder trabajo si el proceso cae
después de confirmar el mensaje y antes de aplicarlo; no reemplaza la idempotencia, solo cambia
duplicados por pérdidas.

### 20. 🟠 El equipo pasa `EntityManager` al dominio “para simplificar”. ¿Qué objeción haces?

⏱️ **30 segundos:** Que el dominio queda acoplado al ORM y asume una responsabilidad —persistir y
delimitar transacciones— que es de la aplicación y la infraestructura.

🗣️ **2 minutos:** La simplificación es aparente: el dominio empieza a ejecutar consultas, a decidir
cuándo hacer `flush`, a depender de entidades gestionadas y de la sesión abierta. Sus pruebas
necesitan una base o mocks del ORM, y cambiar de persistencia toca reglas. Mantendría repositorios o
capacidades propias como puertos y colocaría la unidad de trabajo en el borde de aplicación, donde
ya está el conocimiento de qué forma una operación.

🔬 **El detalle:** La aparente simplificación encarece las pruebas y cualquier cambio de
persistencia, y además rompe la frontera más importante del sistema por la comodidad de una tarde.

### 21. 🟠 Dos bases deben confirmar juntas. ¿Qué preguntas antes de usar una transacción distribuida?

⏱️ **30 segundos:** Si realmente forman una invariante, quién posee cada dato y si el negocio puede
aceptar un estado intermedio durante un tiempo acotado.

🗣️ **2 minutos:** Muchas veces la necesidad desaparece al redibujar la propiedad: si los dos datos
deben ser siempre consistentes, quizá pertenecen al mismo servicio y a la misma base. Si no, evalúo
outbox más consumidor idempotente, una saga con pasos y compensaciones, o un estado pendiente que se
resuelve de forma asíncrona. Solo si nada de eso es aceptable considero coordinación distribuida
(2PC/XA).

🔬 **El detalle:** También considero disponibilidad (2PC bloquea si el coordinador cae), soporte de
los motores y del broker, y la recuperación de transacciones en duda, que requiere intervención
operativa y rara vez está bien practicada.

### 22. 🟠 El método anotado llama a otro método de la misma clase. ¿Qué verificas en Spring?

⏱️ **30 segundos:** Si esa llamada pasa por el proxy que aplica la transacción. En modo proxy, no
pasa.

🗣️ **2 minutos:** Con el modo proxy por defecto, una llamada interna (`this.otroMetodo()`) no
atraviesa el interceptor: la anotación del método interno no se aplica, su propagación (por ejemplo,
`REQUIRES_NEW`) se ignora y puede no haber transacción donde se esperaba. Verifico el modo de
advice, la visibilidad de los métodos y, sobre todo, el comportamiento con una prueba contra el
recurso real que provoque un fallo y compruebe qué quedó confirmado.

🔬 **El detalle:** Las soluciones habituales son mover el método a otro bean, usar
`TransactionTemplate` de forma programática o el modo AspectJ. La más sana suele ser la primera: si
dos métodos necesitan transacciones distintas, probablemente son responsabilidades distintas.

### 23. 🟠 Un adapter usa `db` en vez de `tx` en una operación. ¿Cómo lo detectas?

⏱️ **30 segundos:** Con una prueba de integración que provoque un fallo después de esa operación y
compruebe que todo se revirtió junto.

🗣️ **2 minutos:** Si la operación usó `db`, confirmó por su cuenta y la prueba encuentra su efecto
aunque la transacción se revirtió. Además, diseño el adaptador para que sea difícil mezclar caminos:
recibe un ejecutor (la transacción en curso o, si no hay, el pool) en lugar de tener acceso a ambos,
o toma la transacción del contexto de la unidad de trabajo. En revisiones, cualquier uso directo del
pool dentro de un método transaccional es sospechoso.

🔬 **El detalle:** Un mock puede no reproducir aislamiento, bloqueos ni commits reales, así que esta
clase de error solo aparece en integración o en producción. Es uno de los errores provocados que más
enseña.

### 24. 🟠 ¿Cuándo aceptarías consistencia eventual en `CreateOrder`?

⏱️ **30 segundos:** Cuando el negocio tolera un estado pendiente y está definido cómo se recupera,
en qué plazo y con qué compensación.

🗣️ **2 minutos:** Por ejemplo: el pedido se crea con el pago pendiente; la autorización ocurre
después y el pedido transita a pagado o rechazado; si el pago queda incierto, un proceso lo resuelve
consultando al proveedor. La transición es observable para el cliente ("procesando pago") y los
reintentos son idempotentes. Lo que no aceptaría es consistencia eventual sin estados explícitos,
donde el pedido "debería" pagarse y nadie comprueba que lo hizo.

🔬 **El detalle:** "Eventual" necesita un límite temporal operativo y una respuesta para los estados
atascados: una alerta si un pedido lleva más de X minutos pendiente, y un procedimiento para
resolverlo. Sin eso, eventual significa nunca.

---

## 06 · Validación, errores y resultados

### 1. 🟢 ¿Qué valida el adaptador de entrada?

⏱️ **30 segundos:** La forma: tipos, campos obligatorios, tamaños, formatos y sintaxis propios del
transporte.

🗣️ **2 minutos:** Rechaza pronto lo que no se puede interpretar —JSON inválido, una cantidad que no
es entero, un cuerpo demasiado grande, un UUID mal formado— y construye un comando con datos que la
aplicación entiende. Ese rechazo temprano ahorra trabajo, da mensajes precisos al cliente y evita
que el núcleo tenga que defenderse de basura sintáctica. Cada transporte lo hace a su manera: `400`
en HTTP, cuarentena en una cola, mensaje de uso en una CLI.

🔬 **El detalle:** Validar pronto no sustituye las invariantes del dominio. El adaptador sabe si el
dato tiene forma válida; no sabe si el pedido puede confirmarse.

### 2. 🟢 ¿Qué es una invariante?

⏱️ **30 segundos:** Una condición de negocio que debe cumplirse en todo estado válido del sistema.

🗣️ **2 minutos:** "No confirmar un pedido vacío", "no reservar más stock del disponible", "un pedido
cancelado no vuelve a pendiente". Se protegen donde cambia el estado —en la entidad o el servicio de
dominio—, sin importar qué driver invocó la operación. Así ninguna entrada, ni siquiera una que
alguien añada dentro de un año, puede producir un estado imposible.

🔬 **El detalle:** No es una preferencia de UI ("el campo debe mostrarse en rojo") ni una restricción
accidental del esquema ("la columna admite 255 caracteres"). Una invariante existe porque el negocio
la defiende.

### 3. 🟢 ¿Qué valida la aplicación?

⏱️ **30 segundos:** El contexto: autorización, existencia de recursos y condiciones que requieren
coordinar varios puertos.

🗣️ **2 minutos:** El caso de uso comprueba que el actor puede operar sobre ese pedido, que los
productos existen, que hay disponibilidad según el inventario, y después invoca la regla del dominio
con los datos obtenidos. Son validaciones que el dominio no puede hacer solo porque necesitan datos
de fuera o dependen de quién opera. Sus errores también son de negocio (`OrderNotFound`,
`AccessDenied`) y los traduce cada adaptador.

🔬 **El detalle:** La aplicación no debe duplicar una invariante que una entidad puede proteger por
sí misma: si la entidad ya impide cancelar un pedido enviado, el caso de uso no necesita comprobarlo
antes.

### 4. 🟢 ¿Por qué el dominio no debe conocer HTTP?

⏱️ **30 segundos:** Porque HTTP es un detalle de entrada y la regla tiene que servir igual a
cualquier driver.

🗣️ **2 minutos:** El adaptador traduce status, headers y payload; el dominio devuelve conceptos
propios: un resultado, un error de negocio. Si el dominio lanza `HTTPException(409)`, un consumidor
de mensajes que invoque la misma regla recibirá un concepto HTTP que no significa nada para él, y
las pruebas del dominio necesitarán el runtime web. Además, decidir el status es una decisión de
contrato público que cambia por razones ajenas a la regla.

🔬 **El detalle:** Un `HTTPException` en el dominio invierte la dependencia hacia el transporte. Es
de las filtraciones más fáciles de introducir en FastAPI o Nest, porque el framework lo pone a mano.

### 5. 🟢 ¿Qué diferencia hay entre error de negocio y error técnico?

⏱️ **30 segundos:** El error de negocio expresa un rechazo esperado por las reglas; el técnico, un
fallo del mecanismo que ejecuta esas reglas.

🗣️ **2 minutos:** Inventario insuficiente, pago rechazado o pedido no cancelable son negocio: el
sistema funciona bien y la respuesta es "no". Timeout de base, credenciales inválidas del proveedor
o disco lleno son técnicos: el sistema no pudo decidir. Esa distinción cambia todo lo que viene
después: un error de negocio no se reintenta ni despierta a nadie; uno técnico puede reintentarse,
debe alertar y no debería mostrarse con detalle al cliente.

🔬 **El detalle:** Su reintento, su logging y su representación externa suelen ser distintos.
Mezclarlos —registrar cada rechazo de negocio como `ERROR`— llena las alertas de ruido y esconde los
incidentes reales.

### 6. 🟢 ¿Qué significa traducir un error?

⏱️ **30 segundos:** Convertir un fallo expresado en el vocabulario de una frontera al vocabulario de
la siguiente.

🗣️ **2 minutos:** El adaptador de salida convierte una excepción del proveedor o del driver en un
error que la aplicación puede decidir (`Rejected`, `UnknownResult`, fallo técnico). El adaptador de
entrada convierte los errores de la aplicación en su protocolo (`409` con Problem Details, ACK con
rechazo registrado, código de salida). Cada traducción ocurre una vez y en un lugar, y así cada capa
razona con sus propios conceptos.

🔬 **El detalle:** Traducir no significa borrar la causa. La causa original se encadena o se registra
para observabilidad; lo que no cruza la frontera es su tipo.

### 7. 🟢 ¿Qué información no debe exponerse en un error?

⏱️ **30 segundos:** Stack traces, SQL, secretos, nombres de tablas, tokens y detalles internos del
proveedor.

🗣️ **2 minutos:** El cliente recibe un código estable para máquinas, un mensaje seguro para personas
y un identificador de correlación para soporte; con Problem Details (RFC 9457), eso son `type`,
`title`, `status`, `detail`, `instance` y un `code` propio. Los detalles técnicos quedan en logs
protegidos, enlazados por la correlación. Exponer la causa interna ayuda a un atacante a mapear el
sistema y ata a los clientes a mensajes que cambiarán.

🔬 **El detalle:** Incluso "no encontrado" puede filtrar existencia sensible según el contexto: decir
que un pedido existe pero no es tuyo confirma algo que quizá no debería saberse.

### 8. 🟡 ¿Por qué validar una regla en más de una capa puede ser correcto?

⏱️ **30 segundos:** Porque el borde rechaza pronto con buena experiencia y el dominio protege la
regla ante cualquier entrada.

🗣️ **2 minutos:** El formulario puede impedir cantidades negativas para dar un mensaje inmediato; el
adaptador HTTP puede rechazarlas con `400`; el dominio las rechaza siempre, porque un job o un
consumidor también pueden enviarlas. Pueden coincidir en efecto, pero responden a amenazas y
responsabilidades distintas: usabilidad, contrato público e integridad. Ninguna reemplaza a la otra.

🔬 **El detalle:** Lo incorrecto es copiar la misma política compleja y sus mensajes en todos los
adaptadores: cuando la regla cambia, alguno se queda atrás. La defensa en el borde debe ser barata y
la autoritativa, única.

### 9. 🟡 ¿Cuándo usarías un resultado tipado?

⏱️ **30 segundos:** Cuando varios resultados esperados forman parte normal del contrato y quieres
que el llamador los trate todos.

🗣️ **2 minutos:** `AuthorizePayment` devuelve `Authorized`, `Rejected` o `UnknownResult`: ninguno es
excepcional, los tres son negocio. Un tipo sellado o una unión obliga al llamador a considerar cada
caso; con `switch` exhaustivo, el compilador avisa si aparece uno nuevo. Eso es especialmente
valioso con el resultado incierto, que es el que más se olvida.

🔬 **El detalle:** Funciona mejor donde el lenguaje ofrece exhaustividad (sealed en Java, uniones
discriminadas en TypeScript, enums con datos) y la lista de resultados es estable. En Go, el
equivalente idiomático es un valor más un error tipado.

### 10. 🟡 ¿Cuándo usarías una excepción?

⏱️ **30 segundos:** Para abortar un flujo excepcional y traducirlo en una frontera central, sin que
cada capa intermedia lo maneje.

🗣️ **2 minutos:** Es útil para fallos técnicos (la base no responde), para violaciones de
invariantes que indican un error de programación, o cuando la convención del ecosistema hace de las
excepciones tipadas la forma natural de expresar rechazos (Java, Python). Un traductor central en el
adaptador de entrada las convierte al protocolo. La clave es que sean excepciones con significado
propio, no genéricas.

🔬 **El detalle:** Una excepción no debería reemplazar una taxonomía: lanzar `Exception` o
`RuntimeException` con un mensaje borra la decisión que el llamador necesita tomar. Y mezclar
resultados y excepciones sin convención produce doble manejo.

### 11. 🟡 ¿Cómo diferencias un error reintentable?

⏱️ **30 segundos:** Por su semántica y la duración esperada del problema, no solo por el tipo bruto
que devuelve el proveedor.

🗣️ **2 minutos:** Un timeout, una saturación (`429`, `503`) o una desconexión pueden ser
transitorios: repetir puede funcionar. Un dato inválido, un rechazo de negocio o una credencial
caducada no mejoran al repetir: reintentarlos solo añade carga y retrasa la respuesta. El adaptador
clasifica cada error en una de esas categorías; la política de reintento se aplica solo a las
transitorias.

🔬 **El detalle:** Reintentar exige idempotencia (misma clave en cada intento), backoff con jitter y
un límite, tanto de intentos como de tiempo total dentro del deadline de la petición.

### 12. 🟡 ¿Quién convierte un error de negocio en respuesta HTTP?

⏱️ **30 segundos:** El adaptador de entrada, normalmente mediante un traductor central de esa capa.

🗣️ **2 minutos:** El núcleo produce `InsufficientInventory`; un `@ControllerAdvice`, un filtro de
excepciones de Nest o un handler de FastAPI lo convierte en `409` con Problem Details y un `code`
estable. Tener la tabla de traducción en un solo lugar evita que dos controllers mapeen el mismo
error de forma distinta y hace fácil revisarla contra el contrato OpenAPI.

🔬 **El detalle:** Otros drivers mapean el mismo error de otra forma: un consumidor registra el
rechazo y envía ACK, una CLI devuelve un código de salida distinto de cero. La semántica es la
misma; la representación, no.

### 13. 🟡 ¿Qué riesgo tiene un `catch` de `Exception` en Java?

⏱️ **30 segundos:** Mezcla causas distintas y puede convertir defectos técnicos en respuestas
engañosas.

🗣️ **2 minutos:** Si todo termina en `400`, un bug de programación, una base caída y un rechazo de
negocio se presentan igual: el cliente reintenta cuando no debe o no reintenta cuando debería, las
alertas no se disparan y el diagnóstico se pierde. Además puede capturar `InterruptedException` y
romper la cancelación. Captura lo que sabes manejar; deja subir lo demás.

🔬 **El detalle:** Un handler global correcto traduce las categorías conocidas (errores de negocio,
validación) y deja visibles los fallos inesperados como `500` con correlación, registrados con su
causa completa.

### 14. 🟡 ¿Por qué TypeScript necesita validación runtime?

⏱️ **30 segundos:** Porque sus tipos se eliminan al ejecutar y el JSON externo nunca pasó por el
compilador.

🗣️ **2 minutos:** El cuerpo de una petición llega como `unknown`; declararlo `CreateOrderDto` no lo
comprueba. Hay que validarlo con un esquema (Zod, class-validator con ValidationPipe, JSON Schema en
Fastify) antes de construir un comando confiable. A partir de ese punto, el compilador protege el
resto del código porque el dato ya tiene la forma declarada.

🔬 **El detalle:** Un *type assertion* (`as CreateOrderDto`) cambia lo que cree el compilador, no los
bytes recibidos. Es la forma más rápida de introducir un `undefined` en una regla de negocio.

### 15. 🟡 ¿Cómo conservas la causa técnica sin filtrarla?

⏱️ **30 segundos:** Encadenándola internamente y exponiendo solo un código seguro con un
identificador de correlación.

🗣️ **2 minutos:** El adaptador envuelve la excepción original (`cause` en Java, `raise ... from exc`
en Python, `%w` en Go), el log registra la causa completa con la correlación y el contexto
redactado, y la respuesta pública lleva el código estable y el mismo identificador. Soporte puede ir
de la queja del cliente al log exacto sin que el cliente haya visto nada interno.

🔬 **El detalle:** El acceso, la retención y los datos personales en la observabilidad también
requieren control: un log con el payload completo de un pago es una filtración, aunque no llegue al
cliente.

### 16. 🟡 ¿Qué contrato debe compartir un error entre HTTP y mensajería?

⏱️ **30 segundos:** Su significado de aplicación, no su representación de transporte.

🗣️ **2 minutos:** Ambos adaptadores reconocen `OrderNotFound` o `InsufficientInventory` como errores
del núcleo. HTTP elige status y cuerpo; mensajería elige si confirma el mensaje y registra el
rechazo, si responde por una cola de réplica o si lo manda a la DLQ. La taxonomía de errores de
aplicación es el contrato compartido; la tabla de traducción de cada adaptador es propia.

🔬 **El detalle:** Compartir status codes o metadatos del broker entre capas contaminaría el núcleo:
el caso de uso no debería saber que un `409` existe.

### 17. 🟠 Un controller valida el límite de crédito y un job no. ¿Qué cambias?

⏱️ **30 segundos:** Muevo la regla al dominio o a la aplicación, según los datos que necesite, y
hago que controller y job llamen al mismo caso de uso.

🗣️ **2 minutos:** Si la regla solo necesita el pedido y el cliente, va al dominio; si necesita
consultar el crédito disponible en otro sistema, la aplicación lo obtiene por un puerto y el dominio
decide. Controller y job quedan como adaptadores que construyen el comando y llaman al caso de uso
protegido. Una prueba del caso de uso demuestra que la regla se aplica sin importar la entrada.

🔬 **El detalle:** Puedo mantener una validación temprana en HTTP para dar un mensaje rápido, pero no
como única defensa. El incidente del job que saltó la regla es exactamente lo que pasa cuando lo es.

### 18. 🟠 El dominio lanza `HTTPException`. ¿Cómo lo desacoplas?

⏱️ **30 segundos:** Creo un error de negocio propio, lo lanza el dominio, y lo traduzco a HTTP en el
adaptador.

🗣️ **2 minutos:** `OrderNotCancellable` sustituye a `HTTPException(409, "...")`. El traductor
central del adaptador HTTP mapea `OrderNotCancellable` a `409` con su `code` estable y un mensaje
seguro. El dominio deja de importar el framework, y cualquier otro driver puede reaccionar al mismo
error a su manera. La tabla de traducción queda en un lugar y se prueba contra el contrato.

🔬 **El detalle:** Una prueba del dominio ya no necesita el runtime web, y el status deja de ser una
decisión del dominio. Si el contrato cambia de `409` a `422`, se cambia una línea del adaptador.

### 19. 🟠 El proveedor devuelve 40 errores y el negocio conoce 4. ¿Dónde traduces?

⏱️ **30 segundos:** En el adaptador de salida, hacia cuatro categorías propias.

🗣️ **2 minutos:** La aplicación decide sobre rechazo definitivo, indisponibilidad temporal,
conflicto (operación duplicada con otro contenido) o fallo permanente de integración, sin conocer
los códigos del proveedor. La tabla de 40 a 4 vive en el adaptador, con pruebas por cada código
conocido. Cuando el proveedor añade un código, se decide en qué categoría cae y solo cambia el
adaptador.

🔬 **El detalle:** Conservo el código original en telemetría para diagnóstico, y defino un
comportamiento por defecto para códigos desconocidos —normalmente tratarlos como fallo técnico o
resultado incierto, nunca como éxito—.

### 20. 🟠 Un cliente ve “database timeout”. ¿Qué problema de frontera detectas?

⏱️ **30 segundos:** Un error de infraestructura atravesó el núcleo y el adaptador de entrada hasta
la representación pública.

🗣️ **2 minutos:** Nadie clasificó el error: ni el adaptador de persistencia lo tradujo a un fallo
técnico propio, ni el traductor HTTP lo convirtió en un `503` o `500` genérico. Corregiría ambas
capas: el adaptador de salida clasifica timeouts como transitorios; el de entrada responde con un
error temporal seguro, un `Retry-After` si procede y la correlación. El detalle queda en el log.

🔬 **El detalle:** También revisaría qué más revela la respuesta: nombres de motor, de host o de
tabla facilitan enumeración y revelan topología. Un error público no debería permitir adivinar la
arquitectura.

### 21. 🟠 Una operación devuelve cinco rechazos esperados. ¿Preferirías `Result` o excepciones?

⏱️ **30 segundos:** Preferiría un resultado tipado si son estados normales y el lenguaje permite
tratarlos de forma exhaustiva.

🗣️ **2 minutos:** Cinco rechazos esperados son parte del contrato: el llamador debe decidir sobre
cada uno. Un `Result` o una unión sellada lo hacen visible en la firma y el compilador obliga a
manejarlos. Reservaría las excepciones para fallos técnicos o realmente excepcionales. Lo más
importante es mantener una convención única en el código base: mezclar ambos estilos sin criterio
produce doble manejo y huecos.

🔬 **El detalle:** La decisión cambia si la ergonomía del lenguaje convierte el `Result` en ceremonia
opaca —anidamientos, conversiones en cada capa—. En Java con excepciones tipadas y un traductor
central, la alternativa es legítima si la taxonomía está clara.

### 22. 🟠 Un mensaje inválido llega al consumidor. ¿Lo reintentas?

⏱️ **30 segundos:** No, si es inválido de forma permanente. Lo rechazo o lo envío a cuarentena.

🗣️ **2 minutos:** Reintentar el mismo payload no lo corrige: fallará igual cada vez, consumirá
recursos y, en brokers con orden por partición, bloqueará los mensajes siguientes. Lo confirmo y lo
aparto a una DLQ o tabla de cuarentena con datos saneados y la causa, para que alguien lo
inspeccione y decida si se corrige y se reprocesa.

🔬 **El detalle:** Distingo un error de deserialización o de contrato (permanente) de una dependencia
temporalmente indisponible (transitorio): el primero va a cuarentena; el segundo se reintenta con
límite y backoff.

### 23. 🟠 Dos adapters mapean el mismo error con códigos distintos. ¿Cómo corriges la inconsistencia?

⏱️ **30 segundos:** Centralizo la semántica del error en la taxonomía de aplicación y defino un
mapeo explícito por transporte.

🗣️ **2 minutos:** Si dos controllers HTTP devuelven `400` y `409` para el mismo
`InsufficientInventory`, la tabla de traducción está duplicada: la uno en un traductor central. Si
la diferencia es entre HTTP y un consumidor, puede ser legítima —cada transporte tiene su
representación— pero debe ser explícita y documentada. Una taxonomía de aplicación compartida evita
la divergencia; cada adaptador conserva su representación adecuada.

🔬 **El detalle:** Pruebas de contrato verifican la tabla de cada adaptador sin forzar que HTTP y el
broker usen el mismo código. Lo que se prueba es que el mismo error del núcleo produce siempre la
misma respuesta en cada transporte.

### 24. 🟠 ¿Cómo diseñarías un error seguro para “pedido no encontrado” sin filtrar existencia sensible?

⏱️ **30 segundos:** Devolvería la misma respuesta para "no existe" y "existe pero no es tuyo" cuando
revelar existencia aumente el riesgo.

🗣️ **2 minutos:** Si un cliente consulta un pedido de otro cliente, responder `403` confirma que el
pedido existe; responder `404` igual que para uno inexistente no lo confirma. Internamente mantengo
la causa real y la registro en auditoría (intento de acceso a un recurso ajeno), con la correlación.
Externamente, código y mensaje genéricos y consistentes, sin diferencias de tiempo notables entre
ambos casos.

🔬 **El detalle:** La política depende del actor, del recurso y del modelo de amenazas: un operador
interno puede recibir un `403` explícito porque le ayuda y no filtra nada que no pueda saber.

---

## 07 · Eventos de dominio y efectos secundarios

### 1. 🟢 ¿Qué es un evento de dominio?

⏱️ **30 segundos:** Un hecho de negocio relevante que ya ocurrió dentro del dominio, expresado en el
lenguaje del negocio.

🗣️ **2 minutos:** Nombra una transición —`OrderConfirmed`, `OrderCancelled`— sin describir Kafka,
correo ni transporte. Sirve para que otras partes del sistema reaccionen a ese hecho sin que el
agregado tenga que conocerlas: liberar una reserva, preparar una notificación, actualizar un
informe. El agregado dice qué pasó; quién reacciona y cómo se entrega es decisión de la aplicación y
de la infraestructura.

🔬 **El detalle:** Es pasado e inmutable: `OrderConfirmed`, no `ConfirmOrder`. Una intención todavía
es un comando y puede rechazarse; un evento ya no se puede rechazar, solo reaccionar a él.

### 2. 🟢 ¿Qué hecho representa `OrderConfirmed`?

⏱️ **30 segundos:** Que un pedido válido pasó al estado confirmado, con los datos necesarios para
que otros reaccionen.

🗣️ **2 minutos:** Se registra cuando `Order.confirm()` completa la transición tras comprobar sus
invariantes, y lleva el identificador del pedido, el cliente y el momento de negocio. Permite que
otras políticas reaccionen —notificar al cliente, programar la preparación— sin meter cada efecto
dentro de `Order`. Si mañana hay que añadir otra reacción, se añade un handler, no se toca el
agregado.

🔬 **El detalle:** No garantiza por sí solo que un mensaje externo haya sido entregado. Es un hecho
en memoria hasta que la aplicación lo persiste (por ejemplo, en una outbox) y alguien lo publica.

### 3. 🟢 ¿Dónde se registra un evento?

⏱️ **30 segundos:** Cerca de la mutación que hace verdadero el hecho, normalmente dentro del
agregado, en el mismo método que cambia el estado.

🗣️ **2 minutos:** El agregado lo añade a una lista interna al proteger la transición
(`events.add(new OrderConfirmed(...))` dentro de `confirm()`), y la aplicación lo extrae después de
la operación para despacharlo o persistirlo. Así el hecho y el cambio de estado van juntos: no puede
existir uno sin el otro.

🔬 **El detalle:** Así no puede olvidarse el evento al invocar la misma regla desde otro driver o
desde otro caso de uso. Si el evento lo creara el caso de uso, cada caso de uso que confirme pedidos
tendría que acordarse.

### 4. 🟢 ¿Qué diferencia hay entre evento de dominio y de integración?

⏱️ **30 segundos:** El de dominio modela un hecho interno para el núcleo; el de integración es un
contrato externo, versionado, para otros sistemas.

🗣️ **2 minutos:** Pueden relacionarse —un `OrderConfirmed` interno se traduce a un
`OrderConfirmedV1` publicado—, pero difieren en audiencia (handlers cercanos frente a otros
equipos), forma (modelo interno frente a esquema documentado), compatibilidad (cambia con el modelo
frente a evoluciona con cuidado) y garantías de entrega (puede ser en memoria frente a durable y
observable).

🔬 **El detalle:** Publicar el objeto interno directamente convierte su evolución en una API pública
accidental: renombrar un campo del dominio rompería a consumidores que nadie conoce.

### 5. 🟢 ¿Por qué el dominio no debe conocer Kafka?

⏱️ **30 segundos:** Porque Kafka es un mecanismo de entrega, no una regla de negocio.

🗣️ **2 minutos:** El dominio registra el hecho; la aplicación y la infraestructura deciden cómo
persistirlo, en qué tópico publicarlo, con qué clave, cómo reintentar y cómo versionar. Si `Order`
publicara directamente, su prueba necesitaría un broker, la publicación ocurriría antes del commit
(anunciando pedidos que quizá se revierten) y cambiar de broker tocaría el agregado.

🔬 **El detalle:** Así la regla se prueba sin broker y el mismo hecho puede entregarse por otro
transporte —una tabla consultada, otra cola— sin cambiar el dominio.

### 6. 🟢 ¿Qué es un handler?

⏱️ **30 segundos:** Un componente que reacciona a un evento y ejecuta una responsabilidad concreta.

🗣️ **2 minutos:** Puede actualizar una proyección, preparar una notificación, liberar una reserva o
traducir el evento de dominio a uno de integración. Cada handler tiene una sola responsabilidad y
puede ejecutarse de forma síncrona (en la misma transacción, si es local y parte de la misma
consistencia) o asíncrona (después del commit, desde una outbox o un broker).

🔬 **El detalle:** Su consistencia, orden e idempotencia deben declararse: ¿corre dentro o fuera de
la transacción?, ¿qué pasa si falla?, ¿puede recibir el mismo evento dos veces? Los handlers no son
gratis; cada uno es un flujo más que operar.

### 7. 🟢 ¿Qué significa publicar después del commit?

⏱️ **30 segundos:** Que el efecto externo solo se intenta cuando el estado local ya quedó confirmado
en la base.

🗣️ **2 minutos:** Evita anunciar un pedido que luego se revierte: si se publica antes y el commit
falla, otros sistemas actúan sobre algo que no existe. Pero abre una ventana de fallo: si el proceso
cae entre el commit y la publicación, el pedido existe y nadie se entera. "Después" significa
después del commit, no simplemente después de la línea de código anterior.

🔬 **El detalle:** Una outbox cierra esa ventana al persistir la intención de publicar en el mismo
commit que el estado; un proceso aparte publica desde ahí y reintenta hasta confirmar.

### 8. 🟡 ¿Cuándo usarías un evento y cuándo una llamada directa?

⏱️ **30 segundos:** Evento para reacciones desacopladas e independientes; llamada directa para una
colaboración simple y obligatoria.

🗣️ **2 minutos:** Si la operación necesita un resultado inmediato, un orden estricto y hay un único
colaborador, la llamada directa es más clara: se lee, se depura y se prueba en un solo flujo. El
evento compensa cuando el hecho tiene varios interesados, cuando las reacciones pueden fallar sin
invalidar la operación principal o cuando el acoplamiento temporal importa (el emisor no debe
esperar al consumidor).

🔬 **El detalle:** El evento compensa cuando el hecho tiene varios interesados o vida independiente.
Usarlo para una sola reacción obligatoria esconde una dependencia real detrás de una indirección y
complica el manejo de errores.

### 9. 🟡 ¿Cómo recogerías eventos dentro de un agregado en Java o Python?

⏱️ **30 segundos:** Con una lista privada de eventos en el agregado, alimentada por los métodos que
cambian el estado y drenada por la aplicación después de la operación.

🗣️ **2 minutos:** En Java, `Order` tiene `private final List<DomainEvent> events`; `confirm()`
valida, cambia el estado y añade `OrderConfirmed`; un método `pullEvents()` devuelve la lista y la
vacía. En Python, una dataclass con `_events: list = field(default_factory=list)` y un
`pull_events()` equivalente. El caso de uso guarda el agregado, extrae los eventos y los pasa a la
outbox o a los handlers, dentro de la misma unidad de trabajo si deben ser atómicos.

🔬 **El detalle:** La colección se drena de forma controlada para no republicar eventos viejos: si el
agregado se reutiliza o se guarda dos veces, un evento no drenado se publicaría dos veces. Y los
eventos no se persisten como parte del estado del agregado, salvo que se use event sourcing.

### 10. 🟡 ¿Qué datos debe contener un evento?

⏱️ **30 segundos:** Identidad del evento, momento de negocio y los datos mínimos necesarios para
entender el hecho y reaccionar.

🗣️ **2 minutos:** `OrderCancelled` debería llevar el id del pedido, el cliente, el momento y, si los
handlers lo necesitan, el importe o las líneas a liberar. Debe ser autosuficiente para sus handlers
previstos —que no tengan que volver a consultar al emisor por datos que ya se sabían—, sin copiar el
agregado entero. Un identificador único del evento permite deduplicar.

🔬 **El detalle:** Un evento de integración puede necesitar un snapshot más completo o un versionado
distinto del interno. En el taller de Kafka se vio el coste de lo contrario: una proyección no se
podía reconstruir porque `OrderCancelled` no llevaba el total.

### 11. 🟡 ¿Qué problema resuelve una outbox?

⏱️ **30 segundos:** Evita perder el mensaje entre el commit de los datos y la publicación externa.

🗣️ **2 minutos:** Sin outbox hay una doble escritura: base y broker, cada una con su commit, y
cualquier caída entre ambas deja una inconsistencia. Con outbox, el caso de uso guarda el cambio de
estado y un registro de publicación pendiente en la misma transacción local; un proceso aparte
(dispatcher) lee los pendientes, los publica con reintento y los marca como enviados. Si el proceso
cae, el registro sigue ahí y se publicará.

🔬 **El detalle:** No elimina duplicados: si el dispatcher publica y cae antes de marcar, publicará
otra vez. Requiere consumidores idempotentes y observabilidad de la cola de pendientes.

### 12. 🟡 ¿Por qué un evento puede procesarse dos veces?

⏱️ **30 segundos:** Porque cualquier eslabón puede fallar después de entregar y antes de registrar
que entregó.

🗣️ **2 minutos:** El dispatcher publica y cae antes de marcar la fila; el broker entrega y el
consumidor cae antes de confirmar el offset; el consumidor aplica el efecto y cae antes del ACK. En
todos los casos, el sistema reintenta. Los sistemas con entrega al menos una vez prefieren duplicar
antes que perder, porque un duplicado se puede detectar y un mensaje perdido no.

🔬 **El detalle:** Un identificador de evento estable y una operación atómica de deduplicación en el
consumidor permiten tolerarlo. "Exactamente una vez" de extremo a extremo no lo da ninguna
configuración de broker; se construye con idempotencia.

### 13. 🟡 ¿Qué hace idempotente a un handler?

⏱️ **30 segundos:** Que procesar el mismo evento varias veces deje el mismo resultado efectivo que
procesarlo una.

🗣️ **2 minutos:** Tres técnicas habituales: registrar los ids de eventos procesados en una tabla con
clave única, dentro de la misma transacción que el efecto; aplicar transiciones condicionales ("pasa
a cancelado solo si está confirmado"); o usar operaciones naturalmente idempotentes (fijar un valor
en lugar de incrementarlo). La elección depende del efecto y del almacenamiento.

🔬 **El detalle:** "Comprobar y luego actuar" debe ser atómico: si dos instancias comprueban a la vez
que el evento no se procesó, ambas actuarán. La restricción única o la actualización condicional
resuelven esa carrera; una consulta previa sola no.

### 14. 🟡 ¿Qué coste introduce un bus en memoria como `EventEmitter` de Node?

⏱️ **30 segundos:** Flujo menos visible, manejo de errores difícil y ninguna durabilidad.

🗣️ **2 minutos:** Con `emit('orderConfirmed')`, el código que emite no sabe quién escucha ni en qué
orden; los errores de un listener pueden romper al emisor o perderse; y si el proceso se reinicia,
los eventos en vuelo desaparecen. Puede ocultar un flujo que una llamada directa explicaría mejor.
Para reacciones locales, triviales y no críticas es aceptable; para cualquier cosa que deba ocurrir,
no.

🔬 **El detalle:** Si se usa, necesita reglas de despacho (síncrono o no, antes o después del
commit), aislamiento de errores entre listeners y pruebas de cada handler. Y nunca debe presentarse
como bus confiable de integración.

### 15. 🟡 ¿Cómo versionas un evento de integración?

⏱️ **30 segundos:** Como un contrato público compatible, con dueño, esquema explícito y estrategia
de evolución.

🗣️ **2 minutos:** Prefiero cambios aditivos (campos nuevos opcionales, que los consumidores
ignoran), una versión explícita en el nombre o en el esquema (`OrderConfirmedV1`) y, para cambios
incompatibles, publicar la versión nueva en paralelo durante una migración de consumidores. Un
registro de esquemas o un contrato AsyncAPI ayuda a documentarlo y a verificar compatibilidad antes
de publicar.

🔬 **El detalle:** La compatibilidad debe verificarse con pruebas de contrato, no suponerse por
deserialización tolerante. Que un consumidor no falle no significa que interprete bien el cambio.

### 16. 🟡 ¿Qué observabilidad necesita un dispatcher?

⏱️ **30 segundos:** Latencia de publicación, intentos, errores, tamaño y antigüedad del backlog, y
correlación por evento.

🗣️ **2 minutos:** Debe permitir responder: ¿qué no salió?, ¿cuántas veces se intentó?, ¿desde cuándo
está pendiente?, ¿qué error devolvió el broker? La métrica más importante suele ser la edad del
pendiente más antiguo: si crece, algo está atascado aunque no haya errores. Cada evento lleva la
correlación de la operación que lo originó, para seguirlo de extremo a extremo.

🔬 **El detalle:** Las métricas se acompañan de alertas con umbral y de una vía segura de replay o de
descarte manual para eventos envenenados, con registro de quién lo hizo.

### 17. 🟠 El email se envía y luego falla el commit. ¿Qué rediseñas?

⏱️ **30 segundos:** Dejo de enviar dentro de la transacción: persisto la intención de enviar junto
al estado y envío después del commit.

🗣️ **2 minutos:** El caso de uso guarda el pedido y una fila en la outbox con la notificación
pendiente, en la misma transacción. Si el commit falla, no hay notificación pendiente y el correo
nunca sale. Tras el commit, un dispatcher envía desde la outbox con reintento y una clave de
idempotencia si el proveedor la admite. El cliente nunca recibe un correo sobre un pedido que no
existe.

🔬 **El detalle:** Si el proveedor de correo no soporta idempotencia, registro un estado de envío
(intentado, confirmado) y acepto el riesgo residual de duplicado en la ventana entre enviar y
marcar. Para un correo suele ser aceptable; para un cobro, no.

### 18. 🟠 El commit funciona y el proceso cae antes de publicar. ¿Qué mecanismo falta?

⏱️ **30 segundos:** Una outbox durable o un mecanismo equivalente de publicación recuperable, como
captura de cambios del log de la base.

🗣️ **2 minutos:** El problema es que la intención de publicar vivía solo en memoria. Con outbox, el
evento pendiente se guarda en el mismo commit que el estado y sobrevive al proceso; al reiniciar, el
dispatcher lo encuentra y lo publica. Con CDC, un conector lee el log de transacciones y publica los
cambios. Ambos convierten "publicar después" en "publicar eventualmente, seguro".

🔬 **El detalle:** Hace falta monitorizar la antigüedad de los pendientes y los fallos permanentes,
no solo reintentar indefinidamente: un evento que nunca se puede publicar necesita intervención, no
un bucle infinito.

### 19. 🟠 Un handler cambia el agregado que acaba de emitir el evento. ¿Qué riesgo analizas?

⏱️ **30 segundos:** Recursión, orden de ejecución, doble guardado y un límite transaccional ambiguo.

🗣️ **2 minutos:** Si el handler corre en la misma transacción, puede modificar el agregado mientras
el caso de uso aún lo tiene en memoria, y uno de los dos guardados pisará al otro; si emite otro
evento, puede entrar en bucle. Si corre después, el agregado cambia en dos pasos y hay un momento en
que es visible a medias. Pregunto si la reacción es parte de la misma invariante o un nuevo caso de
uso.

🔬 **El detalle:** Si la reacción es obligatoria para que el estado sea válido, quizá no deba
modelarse como reacción eventual: pertenece al mismo método del agregado, en la misma transición.

### 20. 🟠 Un equipo quiere exponer el evento interno como API pública. ¿Qué preguntas haces?

⏱️ **30 segundos:** Quién lo consume, qué compatibilidad se promete y qué datos puede revelar.

🗣️ **2 minutos:** El evento interno cambia con el modelo de dominio; si se publica tal cual, cada
refactorización del dominio es un cambio de contrato con consumidores externos. Además puede llevar
datos internos o personales que otros no deberían ver. Separaría un contrato de integración derivado
del evento interno si los ciclos de evolución o las audiencias difieren, con un traductor en el
adaptador de publicación.

🔬 **El detalle:** También definiría dueño, esquema, retención, orden (¿por pedido?, ¿global?) y
semántica de entrega (al menos una vez, con id para deduplicar). Sin eso, "publicar el evento" es
crear una API sin documentarla.

### 21. 🟠 El mismo evento llega tres veces. ¿Dónde deduplicas?

⏱️ **30 segundos:** En cada consumidor que ejecuta un efecto que no debe repetirse.

🗣️ **2 minutos:** Uso el id del evento y registro su procesamiento en la misma transacción que el
efecto local, con una restricción única: la segunda y la tercera entrega encuentran el registro y se
descartan sin efecto. Si el efecto es naturalmente idempotente (fijar un estado), puede bastar una
transición condicional. Cada consumidor deduplica según su propio efecto; no hay un deduplicador
global.

🔬 **El detalle:** El productor puede reducir duplicados (productor idempotente del broker, marcar la
outbox con cuidado), pero no puede garantizar exactamente una vez de extremo a extremo. La
responsabilidad final es del consumidor.

### 22. 🟠 Un handler remoto tarda 20 segundos. ¿Lo ejecutas dentro del caso de uso?

⏱️ **30 segundos:** Normalmente no: lo desacoplo tras el commit y lo proceso de forma asíncrona, con
timeout y reintento.

🗣️ **2 minutos:** El caso de uso registra el hecho y la intención en la outbox, confirma y devuelve
un estado honesto al cliente ("pedido recibido, notificación en curso"). El efecto remoto pasa a un
flujo observable con su propio presupuesto de tiempo y reintentos. Así la latencia del tercero no se
convierte en latencia del usuario ni en transacciones largas.

🔬 **El detalle:** Si la respuesta remota es necesaria para decidir —por ejemplo, la autorización de
un pago que determina el estado del pedido—, no es un efecto posterior: hay que rediseñar la
operación con un estado pendiente explícito, no esconder la espera en un handler.

### 23. 🟠 Dos consumidores necesitan formas incompatibles del hecho. ¿Compartes el evento?

⏱️ **30 segundos:** Comparto el hecho semántico, pero no fuerzo un único payload que satisfaga
accidentalmente a ambos.

🗣️ **2 minutos:** Puedo publicar contratos distintos derivados del mismo evento de dominio: uno
compacto para notificaciones, otro con detalle de líneas para facturación. Cada contrato tiene su
esquema, su versionado y su audiencia, y el adaptador de publicación los construye desde el evento
interno. La alternativa —un evento enorme con todo para todos— acopla a cada consumidor con los
campos de los demás.

🔬 **El detalle:** Evito el evento "universal"; cada contrato necesita dueño y compatibilidad claros.
A veces lo correcto es un evento delgado con el id y que el consumidor consulte lo que necesite,
aceptando el acoplamiento de lectura.

### 24. 🟠 ¿Cómo defenderías no usar eventos en un CRUD pequeño?

⏱️ **30 segundos:** Si no hay reacciones independientes, una llamada directa es más clara, más
barata y más fácil de probar.

🗣️ **2 minutos:** Los eventos añadirían dispatcher, orden, manejo de fallos, idempotencia y pruebas
de cada handler, sin proteger ningún cambio real: no hay otros interesados, ni efectos que deban
sobrevivir a caídas, ni acoplamiento temporal que evitar. Una llamada directa dentro del caso de uso
hace lo mismo con un flujo que se lee de arriba abajo.

🔬 **El detalle:** Dejo una frontera modular para introducirlos cuando aparezca un hecho con
consumidores reales, y lo documento como decisión: el primer consumidor externo del CRUD es la señal
de revisión.

---

## 08 · Simulación de entrevista

### S1. 🟢 ¿Qué decisión pertenece al dominio y cuál al caso de uso al crear un pedido?

⏱️ **30 segundos:** El dominio protege las invariantes del pedido; el caso de uso coordina actor,
puertos y transacción alrededor de esa decisión.

🗣️ **2 minutos:** `Order` decide si su estado es válido: que tenga líneas, que las cantidades sean
positivas, que el total se calcule con `Money`. `CreateOrder` carga los productos, comprueba que el
actor puede comprar, pide la reserva de inventario, invoca al dominio para crear el pedido, lo
persiste y registra la publicación pendiente, todo en una unidad de trabajo. Si mañana el pedido
entra por una cola, el dominio no cambia; si cambia la regla de validez, el caso de uso no cambia.

🔬 **El detalle:** Separar no obliga a un modelo rico si la regla es trivial. Lo que no se negocia es
que la regla, sea cual sea, esté en un solo lugar que todas las entradas usan.

### S2. 🟢 ¿Qué datos debería aceptar un puerto de entrada?

⏱️ **30 segundos:** Datos propios de la intención, normalizados y sin tipos del transporte.

🗣️ **2 minutos:** Un comando puede llevar el actor verificado, las líneas del pedido y una identidad
de operación para idempotencia, todo con tipos propios. No recibe el request, el offset del mensaje
ni un `ResponseEntity`. Cada adaptador hace el trabajo de extraer y normalizar esos datos de su
protocolo, de forma que el caso de uso no distingue quién lo invocó ni tiene que interpretar
formatos ajenos.

🔬 **El detalle:** El contrato puede ser una clase, una función o una interfaz según el lenguaje. Lo
que importa es que su firma use tipos del núcleo y que nada de ella cambie si cambia el transporte.

### S3. 🟢 ¿Qué expresa un puerto de salida bien diseñado?

⏱️ **30 segundos:** Una capacidad mínima que el núcleo necesita, nombrada en términos de negocio.

🗣️ **2 minutos:** `ReserveInventory` o `Orders.find` describen la conversación que el caso de uso
necesita; el adaptador resuelve si eso es SQL, HTTP o un SDK. Sus resultados y errores son propios:
una reserva devuelve reservada o stock insuficiente, no un número de filas afectadas. Un buen puerto
se reconoce porque su fake se escribe en pocas líneas y la prueba del caso de uso se lee como la
regla.

🔬 **El detalle:** Un repositorio genérico suele mezclar necesidades de varios casos de uso y termina
reflejando al ORM. Varios puertos pequeños, aunque los implemente el mismo adaptador, expresan mejor
qué necesita cada caso.

### S4. 🟢 ¿Dónde debe comenzar y terminar una transacción local?

⏱️ **30 segundos:** Alrededor de la unidad de consistencia del caso de uso: empieza antes de la
primera escritura relacionada y termina cuando la decisión está completa.

🗣️ **2 minutos:** En `CreateOrder`, la carga de datos que determinan la decisión, el cambio de
dominio, la persistencia del pedido y de la reserva, y el registro en la outbox pueden compartir
commit si viven en la misma base. Todo eso confirma junto o se revierte junto. Lo que ocurre después
—publicar, notificar, llamar a otros sistemas— queda fuera y se hace desde la outbox.

🔬 **El detalle:** No incluyo una espera remota larga como si fuera atómica: alargaría los bloqueos y
no haría atómico el efecto remoto. El proveedor de pagos se llama fuera, con un estado pendiente
explícito.

### S5. 🟢 ¿Qué diferencia hay entre error de negocio y error técnico?

⏱️ **30 segundos:** El error de negocio es un resultado conocido de la política; el técnico impide
ejecutarla de forma confiable.

🗣️ **2 minutos:** `InsufficientInventory` se presenta al cliente con un código estable, no se
reintenta y no despierta a nadie. Un timeout de la base exige clasificación (¿transitorio?),
observabilidad (log con causa, métrica, quizá alerta) y tal vez un reintento acotado; al cliente se
le muestra un error genérico con correlación. Tratar ambos igual lleva a reintentar rechazos
inútilmente o a esconder incidentes.

🔬 **El detalle:** El adaptador de entrada traduce ambos a su protocolo sin filtrar detalles: el de
negocio con su código propio, el técnico con un mensaje seguro.

### S6. 🟢 ¿Qué es un evento de dominio?

⏱️ **30 segundos:** Un hecho pasado relevante dentro del modelo, registrado por el agregado cuando
ocurre una transición válida.

🗣️ **2 minutos:** `OrderCreated` describe algo que ya ocurrió y puede activar reacciones internas:
preparar la notificación, actualizar una proyección. El agregado lo registra en el mismo método que
cambia el estado y la aplicación lo extrae después de la operación para persistirlo en la outbox o
despacharlo a handlers. Así el hecho no puede olvidarse ni desincronizarse del estado.

🔬 **El detalle:** No es automáticamente un mensaje de broker ni un contrato público. Convertirlo en
evento de integración es una decisión aparte, con su esquema, su versión y su garantía de entrega.

### S7. 🟢 ¿Cuándo una regla debe vivir en un value object?

⏱️ **30 segundos:** Cuando protege la validez de un concepto que tiene esa regla en todos sus usos.

🗣️ **2 minutos:** `Money` impide sumar monedas distintas y fija el redondeo; `Quantity` impide
cantidades negativas o cero; una dirección puede validar su país y código postal. Si el concepto se
construye válido una vez, cualquier código que lo reciba puede confiar en él y desaparecen las
comprobaciones dispersas. Además, el tipo hace imposible confundir un importe con una cantidad
aunque ambos sean números.

🔬 **El detalle:** No creo un tipo por cada primitivo si no hay semántica ni invariantes: un nombre
de producto sin reglas puede quedarse como texto.

### S8. 🟡 ¿Cómo evitas que un caso de uso se convierta en otro monolito?

⏱️ **30 segundos:** Llevando las invariantes al dominio y dividiendo por intención y por límite
transaccional.

🗣️ **2 minutos:** El servicio de aplicación coordina: carga, invoca, guarda, registra. No acumula
cálculos de negocio (van al dominio), parsing (va al adaptador), SQL (va al adaptador de
persistencia) ni efectos posteriores (van a handlers desde la outbox). Cuando un caso de uso empieza
a crecer, pregunto qué parte es otra intención y qué parte podría ocurrir después del commit.

🔬 **El detalle:** Tampoco fragmento cada línea en una clase: un caso de uso de cuarenta líneas que
coordina una intención cohesiva es mejor que ocho clases de cinco líneas que hay que recorrer para
entenderlo.

### S9. 🟡 ¿Qué diferencia hay entre autorización contextual y una invariante?

⏱️ **30 segundos:** La autorización depende del actor y del recurso; la invariante debe cumplirse en
todo estado válido, para cualquier actor.

🗣️ **2 minutos:** El caso de uso verifica si este actor puede cancelar este pedido (es el dueño, o
es operador); el agregado impide cancelar un pedido enviado, lo pida quien lo pida. Mantenerlas
separadas evita que el dominio tenga que conocer roles y permisos, que cambian por razones de
organización, y evita que la autorización se pierda cuando otra entrada invoca la regla.

🔬 **El detalle:** Algunas políticas combinan ambas —"un cliente solo puede cancelar dentro de las 24
horas; un operador, siempre"—. En ese caso el dominio recibe el contexto de forma explícita (el tipo
de actor), nunca lo lee de un contexto implícito.

### S10. 🟡 ¿Cuándo separas puertos de lectura y escritura?

⏱️ **30 segundos:** Cuando los consumidores, los modelos, el rendimiento o las razones de cambio
difieren.

🗣️ **2 minutos:** Una consulta de listado puede devolver una proyección con pocos campos sin
reconstruir el agregado; la escritura carga el agregado entero porque debe proteger invariantes y
consistencia. Si ambas comparten puerto, o la escritura carga datos incompletos o la lectura paga el
coste del modelo rico. Separarlas permite optimizar cada una y que cambien por separado.

🔬 **El detalle:** No aplico CQRS completo —modelos separados, almacenamiento separado,
sincronización por eventos— por una consulta simple. La separación de puertos es el paso mínimo y
barato.

### S11. 🟡 ¿Cómo diseñas idempotencia sin mencionar HTTP o Kafka?

⏱️ **30 segundos:** Con una identidad de operación propia en el comando y un registro durable del
resultado, guardado junto al efecto.

🗣️ **2 minutos:** El comando lleva `operationId`; el caso de uso, dentro de la transacción, busca si
esa operación ya se aplicó. Si sí, devuelve el resultado registrado sin repetir el cambio; si no,
ejecuta y registra la operación con su resultado en el mismo commit. Si la misma clave llega con
otro contenido, es un conflicto que se rechaza. Todo eso se expresa con conceptos de aplicación.

🔬 **El detalle:** El header `Idempotency-Key` y el message id son fuentes externas de esa identidad
que cada adaptador normaliza. El núcleo no sabe de dónde vino la clave.

### S12. 🟡 ¿Qué ocurre si cada repositorio abre y confirma su propia transacción?

⏱️ **30 segundos:** Que una operación compuesta puede quedar persistida a medias.

🗣️ **2 minutos:** Si `Orders.save` confirma y `InventoryReservations.save` falla, queda un pedido
sin reserva; si ocurre al revés, stock bloqueado sin pedido. Ninguna regla permite esos estados, y
aparecen solo bajo fallos, lo que los hace difíciles de reproducir. La unidad de trabajo debe
compartir el contexto transaccional y decidir un único commit para todos los cambios relacionados.

🔬 **El detalle:** El repositorio participa en la transacción; no posee por sí solo el límite del
caso. Solo el caso de uso sabe qué operaciones forman una decisión.

### S13. 🟡 ¿Cuándo prefieres un resultado explícito a una excepción?

⏱️ **30 segundos:** Cuando los rechazos esperados forman parte visible del contrato y el llamador
debe tratarlos todos.

🗣️ **2 minutos:** Un tipo resultado obliga a manejar conflicto, ausencia o resultado incierto; con
tipos sellados y `switch` exhaustivo, el compilador avisa si aparece uno nuevo. Las excepciones
pueden reservarse para fallos inesperados, según el ecosistema: en Java con excepciones tipadas y un
traductor central, también funcionan para rechazos de negocio. Lo que no funciona es mezclar ambos
estilos sin criterio.

🔬 **El detalle:** La consistencia del equipo pesa más que una regla universal. Una convención clara
aplicada en todo el código es mejor que el estilo teóricamente superior aplicado a medias.

### S14. 🟡 ¿Dónde se traduce una constraint única de base?

⏱️ **30 segundos:** En el adaptador de persistencia, hacia un error propio del núcleo.

🗣️ **2 minutos:** La base protege la concurrencia real: dos peticiones simultáneas pueden pasar la
comprobación previa y solo la restricción única detiene a la segunda. El adaptador reconoce el
código de violación de unicidad del driver y lo convierte en `DuplicateOrder` o en un conflicto de
operación; el caso de uso decide qué hacer (devolver el resultado anterior, rechazar) y el adaptador
de entrada lo traduce a su protocolo.

🔬 **El detalle:** No comparo mensajes libres del driver si hay códigos estables (como el SQLSTATE
`23505` de PostgreSQL). Los mensajes cambian con la versión y el idioma.

### S15. 🟡 ¿Cuándo publicas una reacción a un evento de dominio?

⏱️ **30 segundos:** Después de confirmar el estado que originó el hecho, nunca antes.

🗣️ **2 minutos:** Los handlers internos que forman parte de la misma consistencia local pueden
ejecutarse dentro de la transacción; los que tocan otros sistemas, después. Para integración
durable, guardo el evento en la outbox en el mismo commit que el estado y un dispatcher lo publica
después, con reintento. Así ningún sistema externo se entera de algo que no quedó confirmado, y nada
confirmado deja de publicarse.

🔬 **El detalle:** Publicar antes del commit expone hechos que podrían revertirse; publicar después
sin outbox puede perderlos si el proceso cae. La outbox es la forma de tener ambas garantías.

### S16. 🟡 ¿Cómo pruebas una invariante sin arrancar infraestructura?

⏱️ **30 segundos:** Construyendo el dominio con valores propios y afirmando la transición válida o
el rechazo, con el lenguaje puro.

🗣️ **2 minutos:** Para "no confirmar un pedido vacío": creo un `Order` sin líneas, llamo a
`confirm()`, compruebo que lanza `EmptyOrder` y que el estado sigue en borrador. Para la transición
válida, lo contrario. No hace falta ORM, servidor web ni base; la prueba corre en milisegundos y
documenta la regla. Otra capa de pruebas comprueba que el mapeo y la persistencia conservan ese
estado.

🔬 **El detalle:** La facilidad de prueba es evidencia de que la frontera está bien puesta, no el
único objetivo del diseño. Si probar una invariante exige infraestructura, la regla está mezclada
con ella.

### S17. 🟠 Un comando válido en forma viola una regla de crédito. ¿Dónde se rechaza?

⏱️ **30 segundos:** En la aplicación o en el dominio, según quién posea la política; nunca en el
parser del adaptador.

🗣️ **2 minutos:** El borde valida forma: el comando está bien construido. Luego el caso de uso carga
el contexto necesario (crédito disponible del cliente, quizá desde otro puerto) y el dominio decide
con datos confiables si el pedido cabe. El rechazo es un error de negocio propio que cada adaptador
traduce: `422` o `409` en HTTP, respuesta de rechazo en una cola.

🔬 **El detalle:** Duplicar la regla de crédito en todos los drivers crea divergencia: el día que
cambie el límite, alguna entrada se quedará con el viejo.

### S18. 🟠 Un puerto devuelve `null`, lanza timeout y a veces un error del SDK. ¿Qué corriges?

⏱️ **30 segundos:** Defino un contrato explícito que distinga ausencia, indisponibilidad e
incertidumbre.

🗣️ **2 minutos:** `null` se convierte en un resultado de ausencia con nombre (`Optional`,
`NotFound`); el timeout, en indisponibilidad transitoria o en resultado incierto según si la
petición llegó a enviarse; el error del SDK, en un fallo técnico propio con la causa encadenada. El
adaptador normaliza los comportamientos externos y el caso de uso decide qué resultados puede
manejar y cuáles abortan la operación.

🔬 **El detalle:** No convierto todo en `InternalError` porque perdería decisiones: el caso de uso
necesita distinguir "no existe" (negocio) de "no sé" (reintentar o dejar pendiente).

### S19. 🟠 Dos agregados deben cambiar juntos, pero viven en bases distintas. ¿Qué cuestionas?

⏱️ **30 segundos:** Si el límite de consistencia y la frontera de negocio están bien definidos.
Probablemente uno de los dos está mal.

🗣️ **2 minutos:** Si de verdad deben ser consistentes siempre, quizá pertenecen al mismo contexto y
a la misma base. Si pueden estar desfasados un tiempo, no invento una transacción distribuida por
defecto: modelo un estado pendiente, publico el cambio del primero por outbox, el segundo reacciona
de forma idempotente y defino compensaciones si falla. O reconsidero la partición entera.

🔬 **El detalle:** La arquitectura hexagonal hace visible el problema —aparecen dos puertos de
persistencia que el caso de uso intenta coordinar— pero no lo resuelve sola: es una decisión de
modelado.

### S20. 🟠 Un evento contiene el agregado completo para cualquier consumidor futuro. ¿Qué riesgo ves?

⏱️ **30 segundos:** Acoplamiento de todos los consumidores a la forma interna del agregado,
exposición de datos y una evolución muy difícil.

🗣️ **2 minutos:** Cada campo publicado es un campo que algún consumidor puede empezar a usar; a
partir de ahí, cambiarlo es un cambio de contrato. Además puede exponer datos personales o internos
a consumidores que no deberían verlos. Publico la información necesaria para los contratos
conocidos, o genero eventos de integración específicos por audiencia, derivados del evento de
dominio.

🔬 **El detalle:** Un evento enorme no evita el versionado; lo hace más costoso, porque cualquier
cambio del agregado se convierte en una versión nueva del evento.

### S21. 🟡 ¿Puede el dominio llamar directamente a un reloj?

⏱️ **30 segundos:** Mejor que reciba un instante como dato o una abstracción de reloj; no debería
leer el tiempo global de forma oculta.

🗣️ **2 minutos:** Pasar `now` como parámetro a la regla (`reservation.isExpired(now)`) la hace
determinista y trivial de probar. Un puerto `Clock` inyectado en el caso de uso compensa cuando
varios casos lo necesitan o cuando hay que controlar el tiempo en pruebas de integración. Lo que
evito es `Instant.now()` o `datetime.now()` dentro del dominio, porque vuelve la regla dependiente
del momento en que corre la prueba.

🔬 **El detalle:** No todo uso de fecha exige un servicio de dominio: recibir el instante como
argumento es la forma más barata de mantener el dominio puro.

### S22. 🟡 ¿Un caso de uso puede devolver una entidad de dominio?

⏱️ **30 segundos:** Puede, pero evalúo si expone mutabilidad o si obliga al adaptador a conocer
demasiado del dominio.

🗣️ **2 minutos:** Devolver la entidad es cómodo y puede ser suficiente dentro de un módulo
controlado. El riesgo es que el adaptador llame a métodos que cambian estado fuera de la
transacción, o que la serialice directamente y convierta su forma en contrato público. Un resultado
propio (`OrderCreated` con los campos necesarios) protege el contrato de aplicación y deja claro qué
puede usar el adaptador.

🔬 **El detalle:** Nunca debe convertirse accidentalmente en entidad serializada ni en entidad
persistente pública. Si se devuelve, que sea el objeto de dominio, no el registro del ORM.

### S23. 🟠 ¿Una validación duplicada en borde y dominio es siempre un defecto?

⏱️ **30 segundos:** No. Pueden proteger amenazas distintas con reglas parecidas.

🗣️ **2 minutos:** El borde da feedback temprano sobre la forma (cantidad positiva, lista no vacía)
con mensajes pensados para el cliente; el dominio mantiene la invariante ante cualquier entrada,
incluidas las que no pasan por ese borde. Coinciden en efecto, pero responden a responsabilidades
distintas: experiencia de uso frente a integridad. El defecto sería tener solo la del borde, o
copiar reglas complejas en todos los adaptadores.

🔬 **El detalle:** Puedo compartir vocabulario o tipos cuando es seguro —por ejemplo, que el
adaptador construya un `Quantity` y así reutilice su validación—, pero no la dependencia del
framework dentro del dominio.

### S24. 🟠 ¿Qué haces si una transacción declarativa exige anotar el caso de uso?

⏱️ **30 segundos:** Comparo el coste de ese acoplamiento con un envoltorio transaccional o una
unidad de trabajo en el borde de aplicación.

🗣️ **2 minutos:** En un sistema sencillo puedo aceptar `@Transactional` en la clase del caso de uso,
documentado como excepción: es una anotación estable y el caso de uso es aplicación, no dominio. Si
condiciona las pruebas (necesitan contexto de Spring) o ata el caso de uso al framework más de lo
aceptable, la desplazo a una fachada de aplicación o a un `UnitOfWork` que el caso de uso invoca.

🔬 **El detalle:** La transacción sigue siendo una decisión del caso de uso —qué operaciones forman
la unidad—, aunque el mecanismo que la implementa sea externo.

### S25. 🟠 ¿Cuándo una llamada directa es mejor que un evento de dominio?

⏱️ **30 segundos:** Cuando hay un único efecto inmediato, con el mismo dueño y sin necesidad de
desacoplar evolución ni tiempo.

🗣️ **2 minutos:** La llamada directa hace visibles el orden y los errores: se lee de arriba abajo y
un fallo se propaga donde se espera. El evento compensa con varios interesados, con reacciones que
pueden fallar sin invalidar la operación principal o con ciclos de vida independientes. Usar eventos
para una sola reacción obligatoria esconde una dependencia detrás de una indirección.

🔬 **El detalle:** Los eventos innecesarios añaden orden implícito, depuración más difícil y una
semántica de fallo que hay que diseñar. Son una herramienta para desacoplar, no un estilo por
defecto.

### S26. 🟠 La transacción guarda el pedido, pero el evento se pierde antes de publicarse. ¿Cómo rediseñas?

⏱️ **30 segundos:** Guardo el pedido y el registro de la outbox en el mismo commit y publico
después, con reintento.

🗣️ **2 minutos:** El caso de uso añade `OrderCreated` a `PendingPublications` dentro de la misma
unidad de trabajo que guarda el pedido. Un dispatcher lee los pendientes, publica con un
identificador estable, espera la confirmación del broker y marca el registro como enviado. Si cae
entre publicar y marcar, publicará otra vez; por eso los consumidores deduplican por id de evento.

🔬 **El detalle:** La outbox cierra la ventana local entre commit y publicación; no promete
exactamente una vez de extremo a extremo. Esa garantía se construye con idempotencia en los
consumidores.

### S27. 🟠 Un pago queda en timeout después de reservar inventario. ¿Qué estado modelas?

⏱️ **30 segundos:** Un estado incierto o pendiente explícito, no un éxito ni un rechazo inventados.

🗣️ **2 minutos:** El pedido queda en `PAYMENT_PENDING` con la clave de la operación persistida.
Después consulto al proveedor por esa clave o reintento con la misma clave si garantiza
idempotencia, hasta obtener un resultado definitivo. Defino un plazo: si pasado ese tiempo sigue
incierto, se escala o se compensa (se libera el inventario y se anula la autorización si llegara).
El cliente ve "pago en proceso", que es la verdad.

🔬 **El detalle:** Una transacción de base no puede revertir al proveedor: si trato el timeout como
rechazo y libero el inventario, puedo quedarme con un cobro y sin pedido.

### S28. 🟠 HTTP y mensajería envían la misma operación con claves distintas. ¿Dónde unificas?

⏱️ **30 segundos:** En una identidad de operación del contrato de aplicación, que ambos adaptadores
alimentan.

🗣️ **2 minutos:** El adaptador HTTP toma el `Idempotency-Key`; el de mensajería, el identificador de
operación que define el productor (no el delivery id del broker). Ambos lo validan y lo ponen en el
mismo campo `operationId` del comando. El caso de uso persiste la deduplicación junto al efecto, así
que la misma operación que llegue por los dos caminos solo se aplica una vez, si el origen usa la
misma clave.

🔬 **El detalle:** Usar solo el delivery id o cualquier dato propio del transporte deja huecos: una
republicación tiene otro delivery id, y una operación reintentada por otra entrada no se reconoce.

### S29. 🟠 El dominio lanza `SQLException` y el controller la convierte en 400. ¿Qué fronteras fallaron?

⏱️ **30 segundos:** Dos: la persistencia filtró un error técnico hasta el dominio, y el adaptador
HTTP perdió su clasificación al convertirlo en `400`.

🗣️ **2 minutos:** El adaptador de persistencia debería haber traducido la excepción SQL a un error
propio (conflicto si es una violación de unicidad, fallo técnico si es un timeout). La aplicación
conserva la causa para diagnóstico. El controller elige una respuesta segura acorde a la categoría:
`409` para un conflicto, `503` o `500` con correlación para un fallo técnico; casi nunca `400`, que
le dice al cliente que su petición estaba mal.

🔬 **El detalle:** Los logs y trazas guardan el diagnóstico con la consulta y el código del driver,
sin exponerlos en la respuesta. Un `400` por un fallo técnico además engaña a los reintentos
automáticos del cliente.

### S30. 🟠 Dos handlers del mismo evento requieren garantías incompatibles. ¿Qué cambias?

⏱️ **30 segundos:** Separo las reacciones y explicito la consistencia y el contrato de cada una.

🗣️ **2 minutos:** Una actualización local crítica (por ejemplo, liberar la reserva al cancelar)
puede ocurrir dentro del mismo commit, síncrona, porque forma parte de la misma consistencia. Una
notificación remota pasa por la outbox y un dispatcher con reintento, asíncrona, porque puede fallar
sin invalidar la cancelación. Mismo hecho, dos mecanismos, cada uno con su garantía declarada.

🔬 **El detalle:** Compartir el hecho no obliga a compartir timing ni mecanismo. Forzar a ambos
handlers al mismo camino —todo síncrono o todo asíncrono— sacrifica la garantía de uno de ellos.

---

**Siguiente:** [índice del bloque](README.md) · [Adaptadores de entrada →](../03-adaptadores-de-entrada/README.md)
