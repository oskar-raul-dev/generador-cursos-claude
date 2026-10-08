# 09 — Respuestas: Adaptadores de salida y operación

Solucionario del bloque `04-adaptadores-de-salida-y-operacion`. Cada enunciado está copiado literalmente de su
capítulo o de la simulación, con la numeración de su documento, y cada respuesta conserva las tres
capas: **⏱️ 30 segundos** (lo que dirías primero), **🗣️ 2 minutos** (contexto, alternativa y
coste) y **🔬 El detalle** (para estudiar, no para recitar).

> **Vigencia:** 2026-09-28.

**Salto rápido:** [01 Persistencia, repositorios y mapeo](#01--persistencia-repositorios-y-mapeo) · [02 Clientes HTTP, gRPC y servicios externos](#02--clientes-http-grpc-y-servicios-externos) · [03 Publicación de eventos y outbox](#03--publicación-de-eventos-y-outbox) · [04 Composition root e inyección de dependencias](#04--composition-root-e-inyección-de-dependencias) · [05 Configuración, observabilidad y resiliencia](#05--configuración-observabilidad-y-resiliencia) · [06 Testing por anillos y contratos](#06--testing-por-anillos-y-contratos) · [07 Evolución y migración desde un monolito](#07--evolución-y-migración-desde-un-monolito) · [08 Simulación](#08--simulación-de-entrevista)

---

## 01 · Persistencia, repositorios y mapeo

### 1. 🟢 ¿Qué necesidad expresa el puerto `Orders`?

⏱️ **30 segundos:** La capacidad de guardar y recuperar pedidos en los términos que necesitan los
casos de uso.

🗣️ **2 minutos:** `Orders` dice: "dame el pedido con este id" y "guarda este pedido", quizá "dame
los pendientes de este cliente". Lo define el núcleo según lo que `CreateOrder` o `CancelOrder`
necesitan, con tipos propios (`Order`, `OrderId`). El adaptador decide si eso es SQL directo, JPA,
una tabla o varias. El caso de uso no sabe nada de sesiones, consultas ni esquemas.

🔬 **El detalle:** No debe copiar toda la API de JPA: `findAll`, paginación, especificaciones y
`flush` son detalles del ORM. Un puerto con tres métodos de negocio es más fácil de implementar, de
simular y de entender.

### 2. 🟢 ¿Quién implementa el puerto de persistencia?

⏱️ **30 segundos:** El adaptador de persistencia, en la capa de infraestructura.

🗣️ **2 minutos:** `JpaOrders` o `PostgresOrders` implementa `Orders`: depende del puerto y del ORM o
del driver, y traduce entre `Order` y la forma de almacenamiento. Carga los datos necesarios,
reconstruye el agregado validándolo, lo guarda respetando la versión optimista y traduce las
excepciones del driver a errores propios. En pruebas, un fake en memoria implementa el mismo puerto.

🔬 **El detalle:** El núcleo no importa el cliente ORM ni el driver. Si se borra el adaptador, el
núcleo sigue compilando; esa es la prueba de que la dependencia está invertida.

### 3. 🟢 ¿Qué diferencia hay entre `Order` y `OrderRecord`?

⏱️ **30 segundos:** `Order` protege invariantes de negocio; `OrderRecord` refleja cómo se almacena
el pedido.

🗣️ **2 minutos:** `Order` tiene constructores que validan, métodos con significado (`confirm`,
`cancel`) y estado encapsulado. `OrderRecord` tiene las anotaciones del ORM, constructor vacío,
campos mutables y la forma de la tabla (columnas, claves, versión). Pueden tener distinta estructura
(el registro puede partirse en varias tablas o aplanar value objects) y distinto ritmo de cambio:
una migración de esquema no debería tocar las reglas.

🔬 **El detalle:** Separarlos cuesta un mapper y pruebas de ida y vuelta. Se paga cuando hay
invariantes relevantes o un esquema que evoluciona por su cuenta; en un CRUD estable puede no
compensar.

### 4. 🟢 ¿Qué es una carga lazy?

⏱️ **30 segundos:** Cargar una relación solo cuando se accede a ella por primera vez, en lugar de al
leer la entidad.

🗣️ **2 minutos:** El ORM devuelve un proxy en lugar de la colección real; al tocarla, dispara una
consulta. Es útil para no traer datos que no se usan, pero depende de que la sesión siga abierta:
fuera de ella, falla (`LazyInitializationException`) o, con configuraciones permisivas, abre
conexiones ocultas. Además puede disparar SQL imprevisto en lugares que parecen puros, como la
serialización o una regla del dominio.

🔬 **El detalle:** Un proxy no es un agregado reconstruido: el adaptador debe cargar el estado que la
operación necesita antes de devolver el objeto al núcleo, que nunca debería provocar consultas por
tocar un campo.

### 5. 🟢 ¿Qué es N+1 en una lista de pedidos?

⏱️ **30 segundos:** Una consulta para obtener la lista de pedidos seguida de una consulta adicional
por cada pedido para cargar sus líneas o su cliente.

🗣️ **2 minutos:** Con diez pedidos son once consultas; con mil, mil una. Suele aparecer al recorrer
una colección lazy en un bucle o al serializar entidades con relaciones. Aumenta los viajes a la
base de forma lineal con el tamaño de la lista y pasa desapercibido en desarrollo, con pocos datos.
Se corrige con una estrategia de carga explícita (join, carga por lotes) o con una consulta
específica que traiga exactamente lo necesario.

🔬 **El detalle:** Se detecta con un conteo real de consultas en una prueba de integración, no con
mocks: un repositorio simulado nunca tiene N+1.

### 6. 🟢 ¿Dónde se decide la transacción de `CreateOrder`?

⏱️ **30 segundos:** En el límite de aplicación que envuelve al caso de uso, o en su composición.

🗣️ **2 minutos:** La transacción agrupa el pedido, la reserva de inventario y el registro de la
outbox, porque juntos forman la decisión de crear un pedido. Se abre con un decorador o fachada
transaccional alrededor del caso de uso, o con una unidad de trabajo que el caso de uso invoca. Los
adaptadores de persistencia participan en ella tomando la conexión en curso.

🔬 **El detalle:** Cada repositorio no debe confirmar por separado: si `Orders.save` y
`InventoryReservations.save` tienen su propio commit, un fallo entre ambos deja un estado parcial.

### 7. 🟢 ¿Por qué el dominio no recibe `EntityManager`?

⏱️ **30 segundos:** Porque es una dependencia técnica del ORM, y el dominio debe decidir sin conocer
cómo se persiste.

🗣️ **2 minutos:** Con `EntityManager`, el dominio podría consultar, hacer `flush`, gestionar
entidades y decidir cuándo guardar: responsabilidades de infraestructura y de aplicación. Sus
pruebas necesitarían una base o mocks del ORM, y cambiar la persistencia tocaría reglas. El dominio
recibe datos y, si hace falta, capacidades propias; la aplicación coordina la persistencia a través
de puertos.

🔬 **El detalle:** También oculta la unidad de trabajo: si el dominio usa `EntityManager`, ya no está
claro qué operaciones forman parte de la transacción ni quién la controla.

### 8. 🟡 ¿Cuándo reconstruyes un agregado completo y cuándo usas una proyección?

⏱️ **30 segundos:** El agregado completo, cuando vas a aplicar invariantes y modificarlo; la
proyección, para lecturas específicas.

🗣️ **2 minutos:** Cancelar un pedido exige el agregado entero, porque `cancel()` necesita su estado
para decidir. Listar los pedidos de un cliente con id, estado y total no requiere hidratar cada
pedido con sus líneas: una consulta que devuelve una proyección con esos campos es más barata y más
clara. Cada caso tiene su puerto: `Orders` para escribir, `OrderSummaries` para leer.

🔬 **El detalle:** Una proyección no debe usarse para saltarse reglas de escritura: si alguien
actualiza el estado a partir de una proyección, sin pasar por el agregado, las invariantes quedan
sin proteger.

### 9. 🟡 ¿Qué debe garantizar el mapper al reconstruir `Order`?

⏱️ **30 segundos:** Que el agregado resultante sea válido y completo para la operación que lo va a
usar.

🗣️ **2 minutos:** Mapea identidad, líneas, estado, importes y versión sin inventar valores por
defecto. Usa una vía de reconstrucción (`Order.reconstitute(...)`) que valide que los datos cargados
forman un estado posible, distinta del constructor de creación, que aplica reglas de alta. Si algo
no encaja —un estado desconocido, líneas sin producto—, falla con un error claro en lugar de
devolver un objeto a medias.

🔬 **El detalle:** Un dato corrupto debe fallar claramente en la reconstrucción. Si el mapper lo
"arregla" con un default, el error aparece mucho después, lejos de su causa.

### 10. 🟡 ¿Cómo conservas identidad y versión optimista?

⏱️ **30 segundos:** Con un identificador estable asignado al crear el agregado y un campo de versión
que viaja en ambos sentidos.

🗣️ **2 minutos:** El id se genera al crear el pedido (en el dominio o por un puerto de identidades)
y nunca cambia. La versión se lee con el agregado y se devuelve al guardar: el adaptador actualiza
con `WHERE id = ? AND version = ?` e incrementa la versión; si no afecta ninguna fila, otro proceso
modificó el pedido entre medias y el adaptador lanza un conflicto propio. La aplicación decide si
reintentar o rechazar.

🔬 **El detalle:** El mapper debe conservar la versión en ambos sentidos. Si la pierde al
reconstruir, el control optimista deja de funcionar sin que nada falle: simplemente, la última
escritura gana.

### 11. 🟡 ¿Qué coste añade separar modelo de dominio y ORM?

⏱️ **30 segundos:** Código de traducción, pruebas de ida y vuelta y más tipos que mantener.

🗣️ **2 minutos:** Cada campo nuevo se añade en el dominio, en el registro y en el mapper; hay que
probar que guardar y leer preserva el estado; y se pierden algunas comodidades del ORM (dirty
checking automático, carga lazy transparente). A cambio, el esquema y el ORM pueden evolucionar sin
reescribir la política, el dominio se prueba sin base y las entidades del ORM nunca llegan a la API.

🔬 **El detalle:** En un CRUD pequeño con pocas reglas puede no compensar; en un núcleo con
invariantes ricas y un esquema que cambia, suele pagarse en la primera migración que no rompe
ninguna regla.

### 12. 🟡 ¿Cómo detectarías N+1 de forma confiable?

⏱️ **30 segundos:** Con una prueba de integración contra una base real que cuente las consultas
ejecutadas.

🗣️ **2 minutos:** Preparo 10 pedidos con líneas, ejecuto el listado y cuento las consultas; repito
con 100. Si el número crece con la cantidad de pedidos, hay N+1. Herramientas como el contador de
sentencias de Hibernate, un proxy de datasource o los logs de la base permiten afirmarlo en la
prueba ("como máximo dos consultas"). Así la regresión se detecta en CI y no en producción.

🔬 **El detalle:** Un mock del repositorio no muestra N+1: por definición, no ejecuta consultas. Es
un ejemplo claro de fallo que solo aparece en la frontera real.

### 13. 🟡 ¿Qué aporta `select` de Prisma a una consulta de lectura?

⏱️ **30 segundos:** Permite elegir exactamente los campos y relaciones que se leen, en lugar de
traer el modelo completo.

🗣️ **2 minutos:** Con `select`, la consulta trae solo lo necesario para la proyección (id, estado,
total), lo que reduce datos transferidos y hace explícita la forma de la lectura en el código.
Combinado con `include` para relaciones concretas, evita tanto traer de más como el N+1. El
resultado es un objeto con tipos derivados que el adaptador puede mapear a una proyección propia.

🔬 **El detalle:** No convierte el modelo de Prisma en dominio: sigue siendo un tipo generado a
partir del esquema, que el adaptador traduce antes de entregarlo al núcleo.

### 14. 🟡 ¿Qué genera sqlc y qué decisión sigue siendo tuya?

⏱️ **30 segundos:** Genera código Go tipado a partir del esquema y de consultas SQL escritas a mano.

🗣️ **2 minutos:** Escribes el SQL (con su rendimiento y su semántica visibles) y sqlc genera
funciones y structs con los tipos correctos, sin ORM ni reflexión. Eso elimina errores de mapeo de
columnas. Lo que sigue siendo tuyo es el diseño: el contrato del puerto que el núcleo necesita, cómo
se agrupan las consultas en una transacción, cómo se reconstruye el agregado a partir de las filas y
cómo se traducen los errores.

🔬 **El detalle:** La generación no diseña invariantes ni fronteras: los structs generados son el
equivalente de `OrderRecord`, y exponerlos al núcleo tendría los mismos problemas que exponer
entidades ORM.

### 15. 🟡 ¿Por qué una sesión SQLAlchemy no debe escapar del adaptador?

⏱️ **30 segundos:** Porque su ciclo de vida es infraestructura: conexión, transacción, identidad de
objetos y carga lazy dependen de ella.

🗣️ **2 minutos:** Si el adaptador devuelve objetos del ORM y la sesión se cierra, acceder a una
relación lazy falla; si la sesión se mantiene abierta y se comparte, el estado de un request
contamina a otro o las transacciones se alargan. Devuelvo objetos de dominio completos o
proyecciones definidas, construidos dentro de la sesión, y la sesión termina cuando termina la
unidad de trabajo.

🔬 **El detalle:** Una relación lazy fuera de sesión falla o, peor, crea una dependencia oculta del
dominio con la conexión. Cuanto antes se convierta el objeto del ORM en uno propio, antes desaparece
ese riesgo.

### 16. 🟡 ¿Cuándo aceptarías un mapeo mínimo en un CRUD pequeño?

⏱️ **30 segundos:** Cuando el riesgo de que dominio y esquema cambien por separado es pequeño y hay
pocas invariantes que proteger.

🗣️ **2 minutos:** En un catálogo interno con campos editables y validaciones simples, una sola clase
que hace de entidad y de registro puede ser suficiente. Mantengo una frontera mínima: el acceso a
datos detrás de un puerto o un módulo, sin que los controllers usen el ORM directamente, y la
respuesta pública construida explícitamente. No duplico clases idénticas por principio.

🔬 **El detalle:** Documento qué señal motivará separarlas: la primera regla de negocio que dependa
del estado, un cambio de esquema que no debería afectar a la lógica, o una segunda fuente de datos.

### 17. 🟠 `save` confirma antes de reservar inventario. ¿Qué límite está mal?

⏱️ **30 segundos:** La transacción quedó partida: la confirma el repositorio en lugar del caso de
uso.

🗣️ **2 minutos:** Si `save` confirma el pedido y después la reserva falla, queda un pedido sin stock
comprometido, y ningún rollback lo arregla porque el primer commit ya ocurrió. El caso de uso debe
coordinar las escrituras de la unidad local dentro de una sola transacción: pedido, reserva y outbox
confirman juntos o no confirman. Los repositorios participan en esa transacción y no hacen commit
propio.

🔬 **El detalle:** Un commit previo no se deshace por un fallo posterior. Además, si hay claves
foráneas, el orden importa dentro de la transacción: en el taller Java la reserva debía guardarse
después del pedido para no violar la FK.

### 18. 🟠 Una entidad JPA se devuelve por HTTP y filtra una columna nueva. ¿Qué cambias?

⏱️ **30 segundos:** Proyecto la respuesta en un response DTO y dejo la entidad en infraestructura.

🗣️ **2 minutos:** El controller deja de devolver la entidad; el caso de uso devuelve un resultado
propio y el adaptador HTTP construye un DTO con los campos públicos explícitos. La columna nueva ya
no sale, y cualquier campo que se quiera publicar en el futuro tendrá que añadirse deliberadamente
al DTO y al contrato. Si la entidad llegaba hasta el controller, también reviso por qué atravesó el
núcleo.

🔬 **El detalle:** Pruebo el JSON real con una prueba de integración que compare las claves de la
respuesta con la lista permitida, para detectar cualquier exposición futura.

### 19. 🟠 El dominio accede a una relación lazy fuera de sesión. ¿Cómo rediseñas la lectura?

⏱️ **30 segundos:** Hago que el adaptador cargue todo el estado requerido antes de devolver el
agregado al núcleo.

🗣️ **2 minutos:** El adaptador controla la sesión y la estrategia de carga: con una consulta que
traiga el pedido y sus líneas (join o carga por lotes) y la conversión a `Order` dentro de la
sesión, el agregado llega completo y sin proxies. Si el agregado es demasiado grande para cargarlo
entero, es una señal de que su límite está mal dibujado o de que la operación necesita una
proyección.

🔬 **El detalle:** Una sesión abierta en el controller (*open session in view*) solo esconde el
problema: las consultas siguen ocurriendo en lugares inesperados y la conexión se retiene durante
toda la petición.

### 20. 🟠 Un adapter Go consulta con `db` durante una transacción `tx`. ¿Qué riesgo hay?

⏱️ **30 segundos:** Que esa consulta queda fuera de la transacción: usa otra conexión y ve otro
estado.

🗣️ **2 minutos:** Si la consulta es una lectura, no ve los cambios aún no confirmados de la
transacción; si es una escritura, se confirma sola, aunque la transacción se revierta después, y
puede bloquearse esperando filas que la propia transacción tiene bloqueadas. Uso el `Tx` para todas
las operaciones de esa unidad, idealmente pasándolo por el `context` o por un ejecutor que haga
imposible elegir el pool por error.

🔬 **El detalle:** La documentación de Go advierte que mezclar `DB` y `Tx` en una misma operación
puede producir inconsistencias. Es el error provocado del taller de Go: la FK falla y el `409` se
convierte en `500`.

### 21. 🟠 Dos workers actualizan el mismo pedido. ¿Cómo detectas la carrera?

⏱️ **30 segundos:** Con control de versión optimista o una restricción de concurrencia en la base.

🗣️ **2 minutos:** Cada worker lee el pedido con su versión; al guardar, el adaptador actualiza solo
si la versión no cambió. El segundo en escribir no afecta ninguna fila, y el adaptador lo traduce a
un conflicto propio. La aplicación decide qué hacer: recargar y reintentar la operación si es
idempotente, o rechazarla. Alternativamente, un bloqueo pesimista (`SELECT ... FOR UPDATE`)
serializa el acceso a costa de contención.

🔬 **El detalle:** La regla de resolución del conflicto pertenece a la aplicación: el adaptador solo
detecta y traduce. "La última escritura gana" es también una decisión, y suele ser la equivocada.

### 22. 🟠 El equipo quiere extender `JpaRepository` desde el núcleo. ¿Qué propones?

⏱️ **30 segundos:** Definir un puerto `Orders` según la necesidad del núcleo e implementarlo con JPA
en el adaptador.

🗣️ **2 minutos:** Si el núcleo extiende `JpaRepository`, depende de Spring Data, expone decenas de
métodos genéricos, devuelve entidades gestionadas y hereda la semántica de transacciones del
framework. Propongo un puerto con los métodos que los casos de uso usan, con nombres de negocio, y
un adaptador `JpaOrders` que usa internamente un `SpringDataOrders extends JpaRepository`. El
framework sigue haciendo el trabajo pesado, pero dentro del borde.

🔬 **El detalle:** No creo un espejo genérico de todas sus operaciones: el puerto crece método a
método, cuando un caso de uso lo necesita.

### 23. 🟠 Un listado tarda más al crecer de 10 a 100 pedidos. ¿Qué medirías primero?

⏱️ **30 segundos:** El número de consultas ejecutadas, sus planes y el tamaño de los datos
devueltos.

🗣️ **2 minutos:** Si las consultas crecen linealmente con los pedidos, casi seguro hay N+1. Si el
número es constante pero cada consulta tarda más, miro el plan de ejecución (índices, escaneos
completos) y cuántos datos se traen (columnas o relaciones innecesarias). También miro si el tiempo
está en la base o en la serialización de objetos grandes. Mido antes de optimizar.

🔬 **El detalle:** Mido con la base y el patrón de acceso reales, con volúmenes parecidos a
producción: con diez filas, casi cualquier consulta es rápida y el problema no aparece.

### 24. 🟠 ¿Cuándo eliminarías el modelo de persistencia separado?

⏱️ **30 segundos:** Cuando la duplicación no protege ninguna evolución real y su coste domina el
trabajo diario.

🗣️ **2 minutos:** Si `Order` y `OrderRecord` son idénticos, cambian siempre juntos, no hay
invariantes que el ORM comprometa y el mapper solo copia campos, la separación cuesta sin devolver.
La eliminaría conservando lo importante: el núcleo depende de un puerto, no del ORM; la API se
construye con DTO explícitos; y la decisión queda registrada como revisable.

🔬 **El detalle:** No expondría el ORM al dominio sin entender el riesgo: si las invariantes empiezan
a depender de la sesión o del lazy loading, hay que volver a separar, y es más caro hacerlo tarde.

---

## 02 · Clientes HTTP, gRPC y servicios externos

### 1. 🟢 ¿Qué expresa el puerto `PaymentGateway`?

⏱️ **30 segundos:** Una capacidad propia para autorizar cobros, con resultados que el núcleo
entiende.

🗣️ **2 minutos:** `authorize(operationId, amount)` devuelve `Authorized`, `Rejected`,
`UnknownResult` o `Unavailable`. El caso de uso `AuthorizePayment` habla de pagos y decide qué
estado toma el pedido con cada resultado; el adaptador habla HTTP, gRPC o el SDK del proveedor y
traduce. Así el proveedor se puede cambiar, simular o sustituir por una regla determinista en
pruebas, sin tocar la política.

🔬 **El detalle:** El contrato incluye los estados inciertos desde el principio. Un puerto que solo
admite "autorizado" o "rechazado" obliga al adaptador a mentir cuando no sabe qué pasó.

### 2. 🟢 ¿Qué datos pertenecen al adaptador del proveedor?

⏱️ **30 segundos:** URL, formato de la petición y la respuesta, credenciales, headers, timeouts,
reintentos y códigos del proveedor.

🗣️ **2 minutos:** Todo lo que cambia si cambia el proveedor vive en el adaptador: el endpoint
`/authorizations`, el DTO con sus nombres de campo, el token de API, el header `Idempotency-Key`, el
timeout de tres segundos, el mapeo de `approved` y `declined`. El adaptador lo usa para cumplir el
contrato y devuelve resultados y errores propios al núcleo.

🔬 **El detalle:** No cruzan como excepciones del SDK: una `StripeException` o un
`HttpTimeoutException` que llegan al caso de uso lo atan al proveedor tanto como un import.

### 3. 🟢 ¿Qué es una capa anticorrupción en esta integración?

⏱️ **30 segundos:** Una traducción que protege el lenguaje propio frente al modelo del proveedor.

🗣️ **2 minutos:** El proveedor tiene sus estados, sus códigos, su forma de expresar dinero y sus
conceptos (intents, charges, captures). La capa anticorrupción, dentro del adaptador, los convierte
a `Authorized`, `Rejected` o incertidumbre, a `Money` y a errores propios. Si el proveedor cambia de
versión o se sustituye, la traducción cambia y el núcleo no se entera.

🔬 **El detalle:** La conversión de dinero merece pruebas específicas: céntimos frente a unidades,
redondeo, monedas sin decimales. Es donde los errores salen más caros.

### 4. 🟢 ¿Qué significa `UnknownResult`?

⏱️ **30 segundos:** Que no sabemos si el proveedor procesó la solicitud: pudo cobrar o no.

🗣️ **2 minutos:** Aparece cuando la petición salió y la respuesta no llegó: timeout después de
enviar, conexión cortada, respuesta ilegible, o un estado del proveedor que indica "en proceso". Un
timeout después del envío no prueba un rechazo; tratarlo como tal puede dejar un cobro sin pedido.
El caso de uso deja el pedido en un estado pendiente explícito.

🔬 **El detalle:** Se resuelve consultando el estado de la operación por su clave, o reintentando con
la misma clave si el proveedor garantiza idempotencia, hasta obtener un resultado definitivo.

### 5. 🟢 ¿Qué diferencia hay entre timeout y rechazo?

⏱️ **30 segundos:** El rechazo es una respuesta definitiva del proveedor; el timeout es la falta de
una respuesta fiable.

🗣️ **2 minutos:** Con un rechazo sabemos que no se cobró y el pedido puede pasar a pago rechazado.
Con un timeout no sabemos nada: puede que el cobro se hiciera. Representarlos igual lleva a dos
errores simétricos: tratar el timeout como rechazo y reintentar con otra clave puede cobrar dos
veces; tratarlo como éxito puede entregar sin cobrar.

🔬 **El detalle:** El caso de uso puede dejar el pedido pendiente y resolverlo después. En el taller
de gRPC, tanto la latencia mayor que el plazo como `UNAVAILABLE` dejan el pedido en `PENDING`, nunca
rechazado ni con un 500.

### 6. 🟢 ¿Para qué sirve un deadline remoto?

⏱️ **30 segundos:** Para acotar cuánto se espera una llamada remota y no quedarse bloqueado
indefinidamente.

🗣️ **2 minutos:** Sin deadline, un proveedor lento retiene hilos, conexiones y memoria hasta agotar
el pool, y el fallo se propaga a todo el sistema. Con él, la llamada se abandona a tiempo y el caso
de uso puede decidir (pendiente, reintento). El deadline debe caber en el presupuesto de la petición
entrante: si el cliente espera cinco segundos, el proveedor no puede tener diez.

🔬 **El detalle:** gRPC no fija un deadline útil por defecto: sin configurarlo, una llamada puede
esperar indefinidamente. Hay que ponerlo en cada llamada o en la configuración del canal.

### 7. 🟡 ¿Por qué la clave de operación debe ser estable?

⏱️ **30 segundos:** Porque permite al proveedor reconocer el mismo intento después de una caída o un
timeout.

🗣️ **2 minutos:** La clave se genera una vez, se persiste con la operación (antes de llamar) y se
reutiliza en cada reintento. Así, si la primera llamada llegó y cobró pero la respuesta se perdió,
el reintento con la misma clave devuelve el resultado original en lugar de cobrar otra vez. Lo mismo
al consultar el estado: la clave es el identificador común entre ambos sistemas.

🔬 **El detalle:** Regenerarla elimina la idempotencia: cada reintento parece una operación nueva
para el proveedor. Es un error frecuente cuando la clave se crea dentro del adaptador en cada
llamada.

### 8. 🟡 ¿Cuándo reintentas una autorización de pago?

⏱️ **30 segundos:** Cuando el fallo es recuperable y la operación es idempotente con una clave
estable.

🗣️ **2 minutos:** Reintento ante errores de red antes de enviar, `429`, `503` o un timeout si el
proveedor garantiza idempotencia por clave. Uso la misma clave, espera exponencial con jitter y un
límite de intentos que quepa dentro del deadline de la petición. Si se agota el presupuesto sin
respuesta definitiva, devuelvo resultado incierto y el pedido queda pendiente para resolverse
después.

🔬 **El detalle:** No reintento un rechazo definitivo (tarjeta rechazada, fondos insuficientes):
repetirlo no cambia el resultado y puede disparar alertas de fraude en el proveedor.

### 9. 🟡 ¿Cómo traduces un `429` o `UNAVAILABLE` sin filtrar protocolo?

⏱️ **30 segundos:** El adaptador los clasifica como indisponibilidad o límite temporal, conceptos
propios.

🗣️ **2 minutos:** `429 Too Many Requests` y `UNAVAILABLE` de gRPC significan "ahora no puedo,
inténtalo luego". El adaptador los reconoce, aplica su política de reintento y, si no se resuelve,
devuelve `Unavailable` (si sabe que no se procesó) o `UnknownResult` (si no lo sabe). El núcleo
recibe esa semántica, no códigos de transporte, y decide qué hacer con el pedido.

🔬 **El detalle:** La política de reintento usa esa clasificación, no el código crudo. Así, cambiar
de HTTP a gRPC cambia la tabla de traducción, no la política.

### 10. 🟡 ¿Qué resultados propios necesita conocer `AuthorizePayment`?

⏱️ **30 segundos:** Autorizado, rechazado, no disponible y resultado incierto.

🗣️ **2 minutos:** Son los estados que cambian la decisión sobre el pedido: autorizado lo marca
pagado; rechazado lo marca pago rechazado; no disponible (sabemos que no se procesó) permite
reintentar más tarde; incierto lo deja pendiente de conciliación. Cualquier otro matiz del proveedor
(motivo del rechazo, código de riesgo) puede viajar como dato informativo, pero no como estado
nuevo.

🔬 **El detalle:** No necesita cada código del proveedor. Si un código nuevo no encaja en ninguno de
los cuatro, es una conversación con el negocio, no un `case` más en el caso de uso.

### 11. 🟡 ¿Qué debe hacer un circuit breaker y qué no decide?

⏱️ **30 segundos:** Corta las llamadas a un servicio que está fallando y le da tiempo para
recuperarse; no decide la consecuencia de negocio.

🗣️ **2 minutos:** Tras un umbral de fallos, el breaker se abre y las llamadas fallan inmediatamente
sin tocar al proveedor, lo que protege recursos propios y evita empeorar la caída ajena. Pasado un
tiempo, deja pasar algunas llamadas de prueba. Pero no decide si el pedido queda pendiente o se
cancela: eso lo decide el caso de uso con el resultado `Unavailable` que el adaptador devuelve
cuando el breaker está abierto.

🔬 **El detalle:** Sus umbrales se operan y observan: un breaker mal calibrado puede quedarse abierto
con el proveedor ya recuperado, o no abrirse nunca.

### 12. 🟡 ¿Cuándo es válido un fallback?

⏱️ **30 segundos:** Cuando conserva la promesa que el negocio hace al cliente.

🗣️ **2 minutos:** Mostrar un catálogo desde una caché de hace cinco minutos cuando el servicio de
catálogo cae es un fallback aceptable si el negocio lo acepta: el cliente ve datos algo viejos, pero
verdaderos. Aprobar pagos "offline" cuando el proveedor cae no lo es: rompe la promesa de no
entregar sin cobrar. Un fallback válido degrada la calidad, no la verdad.

🔬 **El detalle:** La degradación debe ser explícita para el cliente o para operación: una respuesta
marcada como posiblemente desactualizada, una métrica de fallbacks usados. Un fallback silencioso
esconde incidentes.

### 13. 🟡 ¿Qué compruebas en el contrato externo de dinero?

⏱️ **30 segundos:** Unidad, precisión, moneda y redondeo.

🗣️ **2 minutos:** Un `100` puede significar cien unidades o cien céntimos; algunas monedas no tienen
decimales y otras tienen tres; el proveedor puede redondear distinto que nosotros. El adaptador
convierte `Money` al formato del proveedor y la respuesta de vuelta, y verifica que el importe
autorizado coincide con el pedido. Nunca uso `double` para dinero: decimal con escala fija o enteros
en la unidad menor.

🔬 **El detalle:** La traducción se prueba con casos límite: importes con muchos decimales, monedas
sin decimales, el importe máximo, cero. Un error de un factor cien es un clásico de producción.

### 14. 🟡 ¿Qué diferencia hay entre timeout de conexión y tiempo total?

⏱️ **30 segundos:** El timeout de conexión limita cuánto se espera para establecer la conexión; el
tiempo total limita la operación completa.

🗣️ **2 minutos:** Con un timeout de conexión de un segundo pero sin límite total, un proveedor que
acepta la conexión y luego responde muy despacio (o envía la respuesta byte a byte) puede retener la
llamada indefinidamente. Hay que configurar ambos: conexión corta para detectar un destino caído, y
un deadline total para la operación, incluyendo lectura de la respuesta.

🔬 **El detalle:** El deadline total debe caber en el presupuesto entrante, descontando lo que ya se
consumió: si la petición del cliente lleva cuatro segundos de cinco, el proveedor tiene uno, no
tres.

### 15. 🟡 ¿Cómo usarías `AbortSignal` en Node sin cambiar el puerto?

⏱️ **30 segundos:** Dentro del adaptador de `PaymentGateway`, para cancelar el `fetch` al proveedor
cuando vence el plazo.

🗣️ **2 minutos:** El adaptador crea una señal con `AbortSignal.timeout(ms)` o la combina con la
señal de la petición entrante, y la pasa a `fetch`. Si vence, el `fetch` se aborta y el adaptador
devuelve `UnknownResult` (si la petición pudo haber salido) o `Unavailable`. El puerto sigue siendo
`authorize(operationId, amount)` con resultados propios; el mecanismo de cancelación queda en el
borde.

🔬 **El detalle:** Propago la cancelación sin alterar las reglas de negocio. Si el puerto recibiera
la señal, el núcleo empezaría a conocer un mecanismo de Node; si la necesita para propagar el
presupuesto, conviene un tipo propio de deadline.

### 16. 🟡 ¿Qué prueba requiere el adaptador además del caso de uso?

⏱️ **30 segundos:** Una prueba de protocolo contra un servidor controlado que reproduzca las
respuestas y fallos del proveedor.

🗣️ **2 minutos:** Con un servidor simulado (WireMock, un servidor HTTP en memoria, un servidor gRPC
en proceso) verifico que el adaptador envía los headers correctos, incluida la clave de
idempotencia; que el cuerpo tiene el formato y la precisión esperados; que respeta el timeout; y que
cada respuesta (aprobado, rechazado, `429`, `503`, respuesta lenta, conexión cortada) se traduce al
resultado propio correcto.

🔬 **El detalle:** El doble del puerto solo prueba el caso de uso; no ejecuta nada del adaptador. Sin
esta prueba, la traducción —que es donde está el riesgo— queda sin cubrir.

### 17. 🟠 El proveedor cobró y se perdió la respuesta. ¿Qué estado devuelves?

⏱️ **30 segundos:** `UnknownResult`, y el pedido queda pendiente de conciliación.

🗣️ **2 minutos:** No afirmo rechazo ni aprobación sin una prueba del proveedor. El pedido queda en
`PAYMENT_PENDING` con la clave de la operación persistida. Después, un proceso consulta el estado al
proveedor con esa clave, o reintenta con la misma clave si el proveedor es idempotente, y aplica el
resultado definitivo. Al cliente se le dice la verdad: el pago está en proceso.

🔬 **El detalle:** Consulto el estado con el identificador estable antes de repetir la operación; y
defino un plazo máximo tras el cual se escala a revisión manual o se compensa.

### 18. 🟠 Un retry usa un ID nuevo tras cada timeout. ¿Qué daño puede causar?

⏱️ **30 segundos:** Cobros duplicados: cada reintento es una operación nueva para el proveedor.

🗣️ **2 minutos:** Si el primer intento llegó y cobró pero la respuesta se perdió, el segundo con
otra clave cobra otra vez, y el tercero otra. El cliente ve tres cargos por un pedido. La corrección
es persistir la clave con la operación antes de la primera llamada y reutilizarla en todos los
reintentos y consultas.

🔬 **El detalle:** Persisto y reutilizo el identificador original. Es una revisión obligatoria en
cualquier código de pagos: dónde se genera la clave y si sobrevive a un reintento y a un reinicio
del proceso.

### 19. 🟠 El SDK cambia nombres de estados. ¿Dónde absorbes el cambio?

⏱️ **30 segundos:** En el adaptador y su tabla de traducción de estados.

🗣️ **2 minutos:** El núcleo conserva `Authorized` y `Rejected` mientras su significado de negocio no
cambie; el adaptador actualiza el mapeo (`succeeded` pasa a llamarse `completed`) y sus pruebas.
Nada más en el sistema se entera. Si el cambio introduce un estado genuinamente nuevo, la decisión
de a qué resultado propio corresponde se toma con el negocio.

🔬 **El detalle:** Una prueba de contrato contra el proveedor (o contra un entorno de sandbox)
detecta el cambio externo antes de que llegue a producción, y el mapeo por defecto para estados
desconocidos debe ser incierto, nunca éxito.

### 20. 🟠 Un fallback aprueba pagos cuando el proveedor cae. ¿Qué objeción haces?

⏱️ **30 segundos:** Que viola la promesa de negocio de no aprobar sin autorización.

🗣️ **2 minutos:** El circuit breaker protege recursos, pero no puede inventar un resultado de pago:
aprobar sin el proveedor significa entregar mercancía que quizá nunca se cobre, y abre una vía de
fraude evidente (tumbar el proveedor para comprar gratis). Dejo el pedido pendiente, o fallo de
forma explícita con un mensaje honesto, y resuelvo cuando el proveedor vuelva.

🔬 **El detalle:** Si el negocio quisiera aceptar ese riesgo (pagos pequeños, clientes de confianza),
sería una regla de negocio explícita en el caso de uso, con límites y auditoría, no un fallback
técnico escondido en el adaptador.

### 21. 🟠 `HttpClient` se construye por request en Java. ¿Qué coste revisas?

⏱️ **30 segundos:** Se pierde la reutilización de conexiones y se añade latencia y consumo de
recursos en cada llamada.

🗣️ **2 minutos:** `HttpClient` mantiene un pool de conexiones, sesiones TLS y configuración; crearlo
por petición obliga a abrir conexión y negociar TLS cada vez, y bajo carga puede agotar puertos o
hilos. Debe crearlo el composition root una vez, con su configuración (timeouts, proxy, versión
HTTP), y entregarlo al adaptador para reutilizarlo.

🔬 **El detalle:** Reviso también el ciclo de vida (quién lo cierra al detener la aplicación) y que
la configuración se valide al arrancar, no en la primera llamada.

### 22. 🟠 Python recibe `HTTPError` por un rechazo conocido. ¿Qué traduces?

⏱️ **30 segundos:** Clasifico el status y el cuerpo, y si es un rechazo definitivo lo convierto en
`Rejected`.

🗣️ **2 minutos:** `urllib` lanza `HTTPError` para cualquier status de error, incluido un `402` con
un cuerpo que dice "tarjeta rechazada", que para el negocio es una respuesta normal. El adaptador
lee el status y el cuerpo, distingue rechazo definitivo (`Rejected`), límite temporal
(`Unavailable`), error de nuestra petición (fallo técnico, es un bug) y error del servidor (incierto
o no disponible según el caso).

🔬 **El detalle:** No transformo todo `4xx` en la misma regla de negocio: un `401` por credenciales
inválidas es un incidente de configuración, no un pago rechazado, y tratarlo así escondería la caída
de todos los cobros.

### 23. 🟠 gRPC agota el deadline de entrada y comienza otro de 30 segundos. ¿Qué corriges?

⏱️ **30 segundos:** Propago el presupuesto restante en lugar de empezar uno nuevo.

🗣️ **2 minutos:** Si la petición entrante ya agotó su tiempo, el cliente se fue; una llamada nueva
de 30 segundos consume recursos para una respuesta que nadie esperará, y puede producir efectos (un
cobro) que el sistema ya no puede reportar. El adaptador debe calcular el deadline de la llamada
saliente a partir del tiempo que queda de la entrante, y no llamar si ya no queda.

🔬 **El detalle:** Reviso el comportamiento de deadlines del cliente gRPC: algunas integraciones lo
propagan desde el contexto de la llamada entrante y otras no; hay que comprobarlo, no suponerlo.

### 24. 🟠 ¿Cuándo no crearías un puerto separado para un servicio externo?

⏱️ **30 segundos:** Cuando no hay frontera de cambio ni semántica propia que proteger.

🗣️ **2 minutos:** Un servicio interno estable, con un contrato ya expresado en términos propios,
usado por un solo caso de uso poco crítico, puede integrarse con un wrapper pequeño sin toda la
ceremonia de puerto, adaptador, DTO y mapeo. La decisión cambia si el servicio es de un tercero, si
su contrato cambia a menudo, si hay que probar la política sin red o si hay dinero de por medio.

🔬 **El detalle:** Lo que no permitiría es que un SDK invada reglas duraderas: incluso con un wrapper
pequeño, los tipos y errores del SDK se quedan dentro de él.

---

## 03 · Publicación de eventos y outbox

### 1. 🟢 ¿Qué problema de doble escritura resuelve la outbox?

⏱️ **30 segundos:** Evita perder la intención de publicar un evento en la ventana entre el commit de
la base y el envío al broker.

🗣️ **2 minutos:** Sin outbox, guardar el pedido y publicar son dos escrituras en sistemas distintos,
cada una con su commit. Si el proceso cae entre ambas, el pedido existe y nadie se entera; si se
publica primero y la base revierte, otros sistemas actúan sobre un pedido inexistente. Con outbox,
el pedido y una fila con el evento pendiente se confirman juntos en la misma base local; publicar se
convierte en un trabajo posterior y recuperable.

🔬 **El detalle:** El envío real ocurre después, desde la fila, y puede repetirse si algo falla. La
outbox cambia "puede perderse" por "puede duplicarse", que es un problema que sí tiene solución.

### 2. 🟢 ¿Qué se guarda en el mismo commit que el pedido?

⏱️ **30 segundos:** El estado del pedido y el evento de integración pendiente de publicar, como una
fila en la tabla outbox.

🗣️ **2 minutos:** La fila contiene el identificador del evento, su tipo y versión, la clave de
partición (el `orderId`), el payload ya serializado según el contrato externo, el momento y el
estado de publicación. El caso de uso registra la publicación a través de un puerto
(`PendingPublications`), y el adaptador la inserta usando la misma transacción que guarda el pedido.
Si la transacción se revierte, ninguno de los dos existe.

🔬 **El detalle:** Si la outbox vive en otra base, desaparece la garantía: vuelve a haber dos commits
independientes y la misma ventana que se quería cerrar.

### 3. 🟢 ¿Qué hace el dispatcher?

⏱️ **30 segundos:** Lee las filas pendientes, las publica en el broker y marca el resultado.

🗣️ **2 minutos:** Toma un lote de pendientes con algún mecanismo de reclamación (bloqueo de filas
con `SKIP LOCKED`, un lease), publica cada evento con su identificador estable, espera la
confirmación del broker y marca la fila como enviada. Si falla, registra el intento y reintenta con
backoff; tras un límite, aparta la fila como fallo permanente. Además emite métricas de pendientes,
edad e intentos.

🔬 **El detalle:** Puede caer después de publicar y antes de marcar, y entonces publicará otra vez al
reiniciar. Por eso la entrega es al menos una vez.

### 4. 🟢 ¿Qué diferencia hay entre evento de dominio e integración?

⏱️ **30 segundos:** El evento de dominio nombra un hecho de la política dentro del núcleo; el de
integración es un contrato versionado para otros procesos.

🗣️ **2 minutos:** `OrderConfirmed` es un hecho interno, que cambia con el modelo y lo consumen
handlers cercanos. Al cruzar la frontera se traduce a una forma estable —`OrderConfirmedV1` con los
campos acordados— que otros equipos pueden consumir sin conocer nuestro modelo. La traducción ocurre
en el adaptador de outbox o en el caso de uso, según dónde se decida el contrato, pero nunca
publicando el objeto interno directamente.

🔬 **El detalle:** No serializo todo el agregado: expone datos internos y convierte cada refactor del
dominio en un cambio de contrato con consumidores ajenos.

### 5. 🟢 ¿Por qué el núcleo no conoce el topic?

⏱️ **30 segundos:** Porque el tópico y el broker son detalles de la salida, que cambian por razones
ajenas al negocio.

🗣️ **2 minutos:** El núcleo expresa el hecho ("se confirmó un pedido") y registra que hay que
publicarlo; el adaptador decide el destino: qué tópico, qué clave de partición, qué serialización,
qué headers. Si mañana se cambia de broker, se renombran tópicos o se publica el mismo hecho en dos
destinos, el caso de uso no cambia.

🔬 **El detalle:** También evita que la política dependa del cliente del broker: el caso de uso se
prueba con un fake de `PendingPublications` y no necesita Kafka ni RabbitMQ.

### 6. 🟢 ¿Qué es una confirmación del publisher?

⏱️ **30 segundos:** La señal del broker de que aceptó y almacenó una publicación.

🗣️ **2 minutos:** En RabbitMQ son los *publisher confirms*; en Kafka, el acuse según `acks` (por
ejemplo, `all` para esperar a las réplicas). El dispatcher la espera antes de marcar la fila como
enviada: si la confirmación no llega, no se sabe si el broker la guardó, y la fila sigue pendiente
para reintentar. Sin esperarla, el dispatcher podría marcar como enviados eventos que el broker
perdió.

🔬 **El detalle:** No equivale a que un consumidor lo aplicó: solo dice que el broker lo tiene. Lo
que haga cada consumidor es responsabilidad suya, incluida su idempotencia.

### 7. 🟢 ¿Qué significa entrega al menos una vez?

⏱️ **30 segundos:** Que cada evento se entrega una o más veces: nunca se pierde, pero puede
duplicarse.

🗣️ **2 minutos:** Es la garantía que dan la outbox y la mayoría de brokers cuando se configuran para
no perder: ante cualquier fallo, reintentan, y un reintento puede repetir algo que ya había llegado.
Por eso el consumidor deduplica por el identificador estable del evento, registrándolo junto a su
efecto. La combinación "al menos una vez + consumidor idempotente" produce el efecto de exactamente
una vez.

🔬 **El detalle:** Es la expectativa práctica de un dispatcher recuperable. La alternativa, "como
mucho una vez", pierde eventos y rara vez es aceptable para hechos de negocio.

### 8. 🟡 ¿Por qué la outbox no garantiza exactly once?

⏱️ **30 segundos:** Porque el dispatcher puede caer después de publicar y antes de marcar la fila, y
volverá a publicarla.

🗣️ **2 minutos:** Publicar en el broker y marcar la fila en la base son, otra vez, dos escrituras en
sistemas distintos. La outbox resolvió la primera doble escritura (estado + intención), pero la de
publicación sigue existiendo. Al reiniciar, la fila aún pendiente se publica de nuevo con el mismo
identificador. Además, el broker o la red pueden duplicar por su cuenta.

🔬 **El detalle:** La outbox da atomicidad local entre estado e intención, no un efecto único global.
El efecto único lo completa el consumidor con deduplicación.

### 9. 🟡 ¿Cuándo marcas una fila como enviada?

⏱️ **30 segundos:** Después de recibir la confirmación del broker, nunca antes.

🗣️ **2 minutos:** Si se marca antes de publicar y el envío falla, el evento se pierde: la fila dice
"enviado" y nadie lo reintentará. Si se marca después de la confirmación y lo que falla es el
marcado (la base no responde, el proceso cae), la fila sigue pendiente y se publicará otra vez: un
duplicado que los consumidores toleran.

🔬 **El detalle:** Si marcar falla, habrá un duplicado tolerable. Entre perder y duplicar, la outbox
siempre elige duplicar.

### 10. 🟡 ¿Qué identidad usas para deduplicar la publicación?

⏱️ **30 segundos:** Un identificador de evento generado una sola vez, al crear la fila, y persistido
con ella.

🗣️ **2 minutos:** El mismo id acompaña todos los intentos de envío de esa fila, y los consumidores
lo usan para detectar repeticiones: lo registran con su efecto y, si llega otra vez, lo descartan.
Si el broker lo permite, también sirve para la deduplicación del lado del productor. Además, la
clave de partición (`orderId`) garantiza que los eventos del mismo pedido van a la misma partición.

🔬 **El detalle:** Un UUID nuevo por intento impide deduplicar: cada reintento parece un evento
distinto. El id se genera al escribir la fila, no al publicar.

### 11. 🟡 ¿Cómo preservas orden por pedido?

⏱️ **30 segundos:** Con una versión o secuencia por agregado y publicando todos los eventos de un
pedido con la misma clave de partición.

🗣️ **2 minutos:** Cada evento lleva la versión del pedido que lo produjo. El dispatcher publica en
orden de versión por pedido y con `orderId` como clave, de modo que el broker los pone en la misma
partición y los entrega en ese orden. Varios workers de dispatcher no deben adelantar la versión 3
sobre la 2 del mismo pedido: se reparten el trabajo por pedido, no por fila.

🔬 **El detalle:** El orden global suele ser innecesario y caro: lo que importa casi siempre es el
orden por agregado. Y los consumidores deben tolerar desorden igualmente, comparando versiones.

### 12. 🟡 ¿Qué observas en la operación del dispatcher?

⏱️ **30 segundos:** Número y edad de los pendientes, intentos por fila, errores, última entrega
exitosa y filas en fallo permanente.

🗣️ **2 minutos:** La métrica más útil es la edad del pendiente más antiguo: si crece, algo está
atascado aunque no haya errores (el dispatcher murió, el broker no confirma). Los intentos por fila
detectan eventos envenenados; los errores clasificados, problemas de configuración o de red. Con
alertas sobre esas métricas, un atasco se detecta antes de que los consumidores noten el retraso.

🔬 **El detalle:** También se mide el crecimiento de la tabla y el funcionamiento de su limpieza: una
outbox que nunca se purga degrada las consultas del dispatcher con el tiempo.

### 13. 🟡 ¿Qué diferencia hay entre polling y leer el log de transacciones?

⏱️ **30 segundos:** El polling consulta periódicamente la tabla de pendientes; la lectura del log
(CDC) captura los cambios confirmados directamente del registro de la base.

🗣️ **2 minutos:** Polling es simple: una consulta cada pocos segundos, sin infraestructura extra,
con algo de latencia y carga sobre la base. CDC (por ejemplo, con Debezium) lee el WAL o binlog y
publica los cambios de la tabla outbox casi en tiempo real, sin consultas periódicas, a cambio de
operar un conector, gestionar sus offsets y depender de características del motor.

🔬 **El detalle:** Ambos requieren traducción al contrato externo, entrega con confirmación y manejo
de duplicados. La elección depende del volumen, de la latencia aceptable y de la capacidad operativa
del equipo.

### 14. 🟡 ¿Qué aporta `sql.Tx` de Go al guardar pedido y outbox?

⏱️ **30 segundos:** Agrupa la escritura del pedido y la de la outbox en un único commit local.

🗣️ **2 minutos:** El caso de uso se ejecuta dentro de una unidad de trabajo que abre un `sql.Tx`;
tanto el adaptador de pedidos como el de outbox ejecutan sus sentencias sobre ese `Tx` (normalmente
recuperándolo del `context`). El commit confirma ambas o ninguna. La explicitud de Go hace visible
qué participa en la transacción.

🔬 **El detalle:** Un `db.Exec` fuera del `tx` en cualquiera de los dos adaptadores rompe la garantía
sin que nada falle: esa escritura se confirma sola, y la atomicidad desaparece en silencio.

### 15. 🟡 ¿Qué error introduce una promesa `publish()` no esperada en Node?

⏱️ **30 segundos:** Que el error de publicación se pierde y el código sigue como si hubiera
publicado.

🗣️ **2 minutos:** Sin `await`, el dispatcher marca la fila como enviada antes de saber si el broker
la aceptó; si la publicación falla, el rechazo de la promesa queda sin manejar (o tumba el proceso)
y el evento se pierde. Además, el proceso puede terminar antes de que la promesa se resuelva. El
dispatcher debe esperar el resultado del cliente del broker, registrar la confirmación y solo
entonces marcar.

🔬 **El detalle:** Una promesa lanzada no es una entrega durable. En Node, cada promesa necesita un
dueño que la espere o maneje explícitamente su fallo.

### 16. 🟠 ¿Cuándo aceptarías una publicación sin outbox?

⏱️ **30 segundos:** Cuando perder el efecto sea aceptable y esté declarado como decisión.

🗣️ **2 minutos:** Una notificación prescindible ("tu pedido está en camino", con el mismo dato
visible en la web), una métrica o una actualización de caché que se reconstruye sola pueden
publicarse después del commit con un mecanismo simple, aceptando que alguna se perderá en una caída.
Lo documento: qué se puede perder, con qué frecuencia esperada y qué impacto tiene.

🔬 **El detalle:** Para efectos contractuales —facturación, inventario en otro sistema,
notificaciones legales—, la pérdida suele justificar la outbox, porque el coste de reconciliar a
mano supera con creces el de la tabla y el dispatcher.

### 17. 🟠 El commit funciona y el proceso cae antes de publicar. ¿Qué recupera el mensaje?

⏱️ **30 segundos:** La fila pendiente de la outbox: sobrevive al proceso y el dispatcher la publica
al reiniciar.

🗣️ **2 minutos:** El commit guardó la intención de publicar junto con el pedido, en la misma
transacción. Cuando el dispatcher (del mismo proceso reiniciado o de otra instancia) lee los
pendientes, encuentra esa fila y la publica. Desde fuera, el evento llega con algo de retraso, pero
llega. Sin outbox, esa intención vivía en memoria y se habría perdido con el proceso.

🔬 **El detalle:** No depende de la memoria del proceso ni de un callback: depende de una fila
durable. Es exactamente la ventana que el patrón existe para cerrar.

### 18. 🟠 El broker confirma y el dispatcher cae antes de marcar. ¿Qué pasará?

⏱️ **30 segundos:** Al reiniciar, la fila sigue pendiente y se publicará otra vez con el mismo
identificador.

🗣️ **2 minutos:** El broker ya tiene el evento, pero la base no lo sabe. El dispatcher lo reenvía;
el broker lo almacena de nuevo (salvo deduplicación del productor) y los consumidores lo reciben dos
veces. Cada consumidor debe reconocer el mismo id de evento, registrado junto a su efecto, y
descartar la segunda copia sin repetir el efecto.

🔬 **El detalle:** Es una prueba esencial de la frontera: provocar esa caída a propósito y comprobar
que el sistema completo produce un solo efecto. El taller de Kafka la hace con la caída antes del
commit de offset.

### 19. 🟠 La outbox se guarda en otra base. ¿Qué garantía se perdió?

⏱️ **30 segundos:** El commit atómico entre el pedido y la intención de publicar.

🗣️ **2 minutos:** Con dos bases hay dos transacciones: puede quedar un pedido sin fila en la outbox
(evento perdido) o una fila sin pedido (evento de algo que no existe), según el orden y el punto de
fallo. Es la misma doble escritura que la outbox existe para evitar, solo que ahora entre dos bases
en lugar de entre base y broker.

🔬 **El detalle:** La outbox necesita compartir un recurso transaccional local con el estado. Si eso
no es posible, hace falta otra estrategia: CDC sobre la base del pedido, o reconciliación periódica.

### 20. 🟠 Dos workers publican versiones 2 y 3 fuera de orden. ¿Qué rediseñas?

⏱️ **30 segundos:** El reparto de trabajo: las filas de un mismo pedido deben procesarse en orden y
por un solo worker a la vez.

🗣️ **2 minutos:** Particiono el trabajo por pedido (cada worker reclama pedidos, no filas sueltas) o
reclamo solo la fila con la menor versión pendiente de cada pedido. Así el evento 3 no sale antes de
que el 2 esté confirmado. Publico con el `orderId` como clave para que el broker mantenga el orden
en la partición. Y los consumidores, por si acaso, comparan versiones y descartan las obsoletas.

🔬 **El detalle:** No presupongo orden global del broker ni de la base: el orden hay que construirlo
por agregado, y verificarlo en el consumidor.

### 21. 🟠 Un evento externo copia el objeto `Order` completo. ¿Qué riesgo ves?

⏱️ **30 segundos:** Expone datos internos y acopla a todos los consumidores con la forma del
dominio.

🗣️ **2 minutos:** Cualquier campo del agregado, incluidos datos personales o internos, llega a
sistemas que no deberían verlo; y cada cambio del modelo (renombrar, partir un campo) se convierte
en un cambio de contrato con consumidores que quizá ni conocemos. Defino un evento mínimo con los
datos que los consumidores necesitan, versionado explícitamente y con un dueño que decide su
evolución.

🔬 **El detalle:** También reduzco datos sensibles: un evento que viaja por un broker compartido y se
retiene días es un lugar más donde pueden filtrarse.

### 22. 🟠 La tabla outbox crece sin límite. ¿Qué política falta?

⏱️ **30 segundos:** Retención, limpieza y archivo de las filas ya publicadas.

🗣️ **2 minutos:** Las filas enviadas pueden borrarse o archivarse tras un periodo (días, según la
necesidad de auditoría o de reproceso), con un proceso periódico en lotes pequeños para no bloquear
la tabla. Las filas en fallo permanente necesitan su propia política: revisión, corrección y
reenvío, o descarte con registro. Sin eso, las consultas del dispatcher se degradan y la base crece
sin razón.

🔬 **El detalle:** Mido la edad y el volumen antes de llegar a la saturación: una alerta por tamaño
de tabla o por filas antiguas pendientes detecta tanto la falta de limpieza como un dispatcher
atascado.

### 23. 🟠 Spring despacha un evento después del commit sin registro durable. ¿Qué ventana queda?

⏱️ **30 segundos:** Queda la caída entre el commit y la ejecución del callback que publica.

🗣️ **2 minutos:** Un `@TransactionalEventListener(phase = AFTER_COMMIT)` se ejecuta en memoria
después de confirmar: evita publicar algo que luego se revierte, pero si el proceso cae justo
después del commit, o si la publicación falla, el evento se pierde, porque no hay ninguna fila que
recuerde que había que publicarlo. Sin registro durable no hay forma segura de recuperar la
intención.

🔬 **El detalle:** Un listener transaccional no equivale a una outbox. Puede usarse para escribir la
fila de la outbox (en fase `BEFORE_COMMIT`, dentro de la transacción), pero no para publicar
directamente con garantías.

### 24. 🟠 ¿Cómo pruebas la frontera entre outbox y consumidor?

⏱️ **30 segundos:** Provocando caídas y duplicados en el flujo completo, con base y broker reales, y
comprobando que el resultado final es un solo efecto.

🗣️ **2 minutos:** Tres pruebas mínimas: fallo de la transacción del caso de uso (no hay pedido ni
fila); caída después del commit y antes de publicar (el evento llega tras reiniciar el dispatcher);
caída después de publicar y antes de marcar (el evento llega dos veces y el consumidor aplica un
solo efecto). Verifico el commit local, la publicación recuperable y la deduplicación del
consumidor.

🔬 **El detalle:** Un mock del publisher no demuestra consistencia: no tiene commits, ni
confirmaciones, ni caídas. Esta frontera solo se prueba con los componentes reales y fallos
provocados.

---

## 04 · Composition root e inyección de dependencias

### 1. 🟢 ¿Qué es un composition root?

⏱️ **30 segundos:** El lugar donde se construye y conecta el grafo de objetos de la aplicación, en
un borde visible.

🗣️ **2 minutos:** Allí se leen y validan la configuración, se crean los recursos compartidos (pool
de base, clientes HTTP, conexiones al broker), se construyen los adaptadores, se inyectan en los
casos de uso y se entregan los casos de uso a los adaptadores de entrada. Es el único lugar que
conoce a la vez las implementaciones concretas y los puertos que satisfacen. También decide el ciclo
de vida y el orden de cierre.

🔬 **El detalle:** Puede ser un módulo de configuración de Spring, un módulo de NestJS, la función
`main` en Go o una función `build_app` en Python. La forma cambia; el concepto no.

### 2. 🟢 ¿Quién conoce las implementaciones concretas de los puertos?

⏱️ **30 segundos:** El composition root, y nadie más fuera de los propios adaptadores.

🗣️ **2 minutos:** El núcleo conoce solo los puertos: `CreateOrder` recibe un `Orders`, sin saber si
es JPA, SQL o un fake. Los adaptadores de entrada conocen solo los puertos de entrada. El
composition root es el que decide que, en este entorno, `Orders` es `JpaOrders` y `PaymentGateway`
es el cliente gRPC, y puede decidir otra cosa en pruebas o en otro despliegue.

🔬 **El detalle:** Esa dependencia hacia los detalles es legítima porque se limita al ensamblaje: el
composition root no contiene política, solo conexiones.

### 3. 🟢 ¿Qué resuelve la inyección de dependencias?

⏱️ **30 segundos:** Construir objetos entregándoles sus colaboradores desde fuera, en lugar de que
los creen o busquen ellos mismos.

🗣️ **2 minutos:** Con inyección por constructor, `CreateOrder` declara qué necesita y alguien se lo
da. Ese alguien puede ser un contenedor (Spring, Nest) que resuelve el grafo automáticamente, o
código explícito que llama a los constructores en orden. En ambos casos las dependencias quedan
visibles en la firma y el objeto es fácil de construir en pruebas con dobles.

🔬 **El detalle:** No cambia por sí sola los imports del dominio: se puede inyectar un SDK
directamente en un caso de uso. DI resuelve cómo se construye, no hacia dónde apuntan las
dependencias.

### 4. 🟢 ¿Qué no garantiza la inyección por sí sola?

⏱️ **30 segundos:** No garantiza la dirección correcta de las dependencias ni un buen límite de
negocio.

🗣️ **2 minutos:** Un contenedor inyecta lo que le pidas: si el dominio pide un `JpaRepository` o un
`StripeClient`, lo recibirá, y el sistema seguirá acoplado aunque nadie escriba `new`. Tampoco
impide un caso de uso con veinte dependencias ni un servicio que mezcla capacidades. Lo que
determina la arquitectura es quién define los contratos y qué tipos cruzan.

🔬 **El detalle:** Hay que revisar los contratos y los imports. Una forma rápida: construir el caso
de uso en un test sin contenedor; si hay que instanciar clases de infraestructura, la dependencia no
está invertida.

### 5. 🟢 ¿Dónde se crea `JpaOrders`?

⏱️ **30 segundos:** Su clase vive en infraestructura, y su instancia se crea en el composition root.

🗣️ **2 minutos:** Una configuración (`@Bean Orders orders(SpringDataOrders data) { return new
JpaOrders(data); }`) la construye una vez con sus dependencias, y la entrega como `Orders` al
construir `CreateOrder`. El caso de uso recibe el puerto; el controller recibe el caso de uso.
Ninguno de ellos sabe que existe `JpaOrders`.

🔬 **El detalle:** El controller no debe crear adaptadores por petición: además de acoplarse a la
implementación, desperdiciaría recursos y rompería el ciclo de vida de conexiones y transacciones.

### 6. 🟢 ¿Qué es el ciclo de vida de un recurso?

⏱️ **30 segundos:** Cuándo se crea un recurso, cuánto vive (su alcance) y cuándo y cómo se cierra.

🗣️ **2 minutos:** Un pool de base de datos vive lo que vive la aplicación; un cliente HTTP también,
para reutilizar conexiones; una transacción vive lo que una operación; el actor de una petición, lo
que la petición. Los workers en segundo plano se arrancan y se detienen con la aplicación. Cada
recurso necesita un dueño claro que lo cree y lo cierre.

🔬 **El detalle:** Un alcance erróneo puede mezclar estado entre peticiones (un singleton con datos
de usuario) o desperdiciar recursos (un pool por petición). Ambos errores son silenciosos hasta que
hay carga.

### 7. 🟡 ¿Por qué `CreateOrder` no consulta el contenedor?

⏱️ **30 segundos:** Porque eso sería un service locator oculto: el caso de uso escondería sus
dependencias y dependería del framework.

🗣️ **2 minutos:** Si `CreateOrder` pide `context.getBean(Orders.class)` dentro de un método, su
firma ya no dice qué necesita, las pruebas tienen que preparar un contenedor y el caso de uso
importa Spring. Con el constructor, las capacidades que necesita quedan visibles, se sustituyen con
dobles en una línea y el caso de uso funciona sin ningún framework.

🔬 **El detalle:** Facilita pruebas y reutilización sin framework. Si un caso de uso necesita elegir
implementaciones en tiempo de ejecución, recibe una fábrica o un selector propio, no el contenedor.

### 8. 🟡 ¿Cuándo prefieres wiring explícito sobre DI automática?

⏱️ **30 segundos:** Cuando el grafo es pequeño y legible, y ver las conexiones en código aporta más
que automatizarlas.

🗣️ **2 minutos:** En Go o Python, unas decenas de líneas en `main` o en `build_app` que llaman a
constructores en orden son fáciles de leer, de depurar y de revisar: se ve qué depende de qué y en
qué orden se crea y se cierra. No hay magia de escaneo ni errores de resolución en tiempo de
arranque. En un servicio pequeño en Java también puede funcionar con un par de `@Bean` explícitos.

🔬 **El detalle:** Un contenedor compensa en un grafo grande, con muchos scopes, proxies
(transacciones, seguridad) e integraciones del framework. La decisión es de coste, no de pureza.

### 9. 🟡 ¿Cómo pruebas que el grafo real puede arrancar?

⏱️ **30 segundos:** Con una prueba de arranque que construya la aplicación completa con
configuración de prueba y adaptadores reales.

🗣️ **2 minutos:** En Spring, un `@SpringBootTest` que arranca el contexto; en Nest, crear el módulo
raíz; en Go, llamar a la función de composición contra contenedores de prueba. Verifica que todos
los tokens y beans se resuelven, que los scopes son válidos, que la configuración obligatoria está y
que los adaptadores reales se construyen. Detecta errores que ninguna prueba unitaria ve.

🔬 **El detalle:** No sustituye las pruebas de comportamiento: que el grafo arranque no dice que la
regla sea correcta, y que la regla sea correcta no dice que el grafo arranque.

### 10. 🟡 ¿Qué diferencia hay entre prueba del caso de uso y de composición?

⏱️ **30 segundos:** La del caso de uso verifica la política con dobles; la de composición verifica
que el grafo real se resuelve.

🗣️ **2 minutos:** La prueba del caso de uso construye `CreateOrder` con fakes y comprueba reglas y
coordinación: es rápida y precisa. La de composición no comprueba ninguna regla; comprueba que
existe un adaptador para cada puerto, que la configuración es válida y que las dependencias encajan.
Detectan fallos distintos, y ninguna reemplaza a la otra.

🔬 **El detalle:** Un caso de uso perfectamente probado puede no arrancar en producción por un bean
faltante, un token mal registrado o una variable de entorno ausente.

### 11. 🟡 ¿Por qué un cliente HTTP reutilizable suele vivir más que un request?

⏱️ **30 segundos:** Para reutilizar su pool de conexiones, las sesiones TLS y su configuración.

🗣️ **2 minutos:** Crear un cliente por petición obliga a abrir conexión y negociar TLS cada vez, lo
que añade latencia y, bajo carga, puede agotar puertos o descriptores. Un cliente creado una vez en
el composition root, configurado con timeouts y límites, y compartido por el adaptador, amortiza ese
coste. Los clientes modernos (Java `HttpClient`, `fetch` con agentes, `http.Client` de Go) están
pensados para ser reutilizados.

🔬 **El detalle:** El composition root también controla su cierre al detener la aplicación, para
liberar conexiones de forma ordenada.

### 12. 🟡 ¿Qué riesgo tiene un singleton con estado de actor?

⏱️ **30 segundos:** Que comparta la identidad o el estado de un usuario con las peticiones de otros.

🗣️ **2 minutos:** Si un objeto singleton guarda "el actor actual" en un campo, dos peticiones
concurrentes se lo pisan: la segunda puede ejecutar con la identidad de la primera. Un objeto con
estado de petición necesita un alcance de petición, o mejor, no tener estado: recibir el actor como
parámetro en cada llamada. Por eso el `Actor` viaja en el comando, no en un campo del caso de uso.

🔬 **El detalle:** La fuga puede ser de seguridad, no solo de corrección: un usuario viendo o
modificando datos de otro. Es difícil de reproducir porque solo aparece con concurrencia.

### 13. 🟡 ¿Por qué NestJS necesita un token para una interfaz TypeScript?

⏱️ **30 segundos:** Porque la interfaz no existe en runtime: el compilador la borra y el contenedor
no tiene con qué identificarla.

🗣️ **2 minutos:** Nest resuelve dependencias por la clase que aparece en los metadatos del
constructor; con una clase concreta funciona, pero una `interface` desaparece al compilar y queda
como `Object`. Hay que registrar un token en tiempo de ejecución (un `Symbol` o una cadena),
asociarlo al provider concreto (`{ provide: ORDERS, useClass: PrismaOrders }`) e inyectarlo con
`@Inject(ORDERS)` junto al tipo estructural.

🔬 **El detalle:** NestJS documenta esa limitación en sus *custom providers*. El token resuelve la
composición; no hace que el puerto sea bueno: eso sigue dependiendo de su contrato.

### 14. 🟡 ¿Qué decide `main` en una aplicación Go?

⏱️ **30 segundos:** Construye la base, los adaptadores, los casos de uso y el servidor, y controla
el arranque y el cierre.

🗣️ **2 minutos:** `main` lee y valida la configuración, abre el pool, construye los adaptadores con
sus dependencias, crea los casos de uso con esos adaptadores, monta el servidor HTTP con los
handlers, arranca los workers y espera una señal de parada. Al recibirla, deja de aceptar tráfico,
espera a que terminen las peticiones en curso, detiene workers y cierra el pool. Si algo falla al
arrancar, sale con un error claro.

🔬 **El detalle:** No debe esconder recursos en variables globales de paquete: eso rompe las pruebas
en paralelo, oculta el orden de inicialización y hace imposible sustituir dependencias.

### 15. 🟡 ¿Cómo introduces configuración sin leer ambiente en el dominio?

⏱️ **30 segundos:** Validando el entorno al arrancar y pasando valores tipados a los adaptadores que
los necesitan.

🗣️ **2 minutos:** El composition root lee variables de entorno o archivos, las convierte en objetos
de configuración tipados (`PaymentConfig(baseUrl, timeout, maxAttempts)`), los valida (falla al
arrancar si falta algo o un valor es inválido) y los entrega a los adaptadores. Los casos de uso
reciben parámetros de política solo cuando forman parte del negocio (un límite de crédito
configurable), con nombre y tipo propios.

🔬 **El detalle:** El dominio no consulta variables de entorno en cada ejecución: eso lo hace
dependiente del despliegue, difícil de probar y propenso a fallar en producción con un valor que
nadie validó.

### 16. 🟡 ¿Cómo cierras recursos creados por el composition root?

⏱️ **30 segundos:** En orden inverso al de creación, y cada uno por su dueño.

🗣️ **2 minutos:** Primero se deja de aceptar trabajo nuevo (el servidor deja de aceptar peticiones,
los consumidores dejan de leer), se espera a que termine el trabajo en curso con un plazo, se
detienen los workers en segundo plano, y después se cierran los clientes externos y el pool de base.
Así ninguna operación en vuelo pierde su conexión a mitad. Los frameworks ofrecen ganchos para esto;
en Go se hace explícito en `main`.

🔬 **El detalle:** Un cierre abrupto puede perder progreso no confirmado: un chunk a medias, un
mensaje procesado cuyo ACK no llegó a enviarse. Con idempotencia no es grave, pero genera trabajo
repetido y ruido.

### 17. 🟠 El controller construye `JpaOrders` en cada petición. ¿Qué cambias?

⏱️ **30 segundos:** Muevo la creación al composition root y hago que el controller reciba el caso de
uso ya construido.

🗣️ **2 minutos:** El controller no debería conocer `JpaOrders` ni crear nada: recibe `CreateOrder`
por constructor, y `CreateOrder` recibe `Orders`. El composition root crea el adaptador una vez, con
sus dependencias (el repositorio de Spring Data, el pool), y lo reutiliza. Así desaparece el
acoplamiento del controller a la persistencia y el coste de construir objetos por petición.

🔬 **El detalle:** El pool y el adaptador suelen tener una vida mayor que la petición. Crearlos por
petición, además de lento, puede romper el manejo de transacciones si el adaptador guarda estado.

### 18. 🟠 El dominio importa `ApplicationContext`. ¿Qué dependencia inviertes?

⏱️ **30 segundos:** Hago que el caso de uso reciba sus capacidades por constructor y dejo el
contenedor solo en la composición.

🗣️ **2 minutos:** Si el dominio llama a `applicationContext.getBean(...)`, está usando Spring como
service locator: sus dependencias son invisibles, sus pruebas necesitan un contexto y el dominio
importa el framework. Identifico qué obtiene del contexto, lo convierto en parámetros del
constructor (puertos propios) y hago que la configuración los inyecte. Si necesitaba elegir entre
implementaciones en tiempo de ejecución, le doy una fábrica propia.

🔬 **El detalle:** El dominio deja de importar Spring y se puede construir con `new` en una prueba.
Es un cambio pequeño con mucho efecto en testabilidad.

### 19. 🟠 Un bean se inyecta, pero su tipo es un SDK de pagos. ¿Es suficiente?

⏱️ **30 segundos:** No. El SDK sigue filtrado al núcleo: el caso de uso depende de sus tipos,
métodos y errores.

🗣️ **2 minutos:** Que llegue inyectado solo cambia quién lo construye. El caso de uso sigue llamando
a métodos del proveedor, capturando sus excepciones y leyendo sus estados, y un cambio de versión
del SDK lo alcanza. Creo un puerto propio `PaymentGateway` con resultados propios, un adaptador que
usa el SDK y lo traduce, y hago que el contenedor inyecte el adaptador como `PaymentGateway`.

🔬 **El detalle:** La inyección de dependencias no equivale a la inversión de dependencias: la
primera es un mecanismo de construcción; la segunda, una decisión sobre quién define el contrato.

### 20. 🟠 Un scope de request se guarda en singleton. ¿Qué fallo esperas?

⏱️ **30 segundos:** Que se reutilice la identidad, la transacción o los datos de una petición en
otra.

🗣️ **2 minutos:** Si un singleton recibe en su constructor un objeto de alcance de petición (el
usuario actual, una conexión de la transacción), se queda con la instancia de la primera petición
para siempre, o, con proxies, con la de la petición que esté en curso en ese hilo, lo que es frágil.
El resultado típico: acciones ejecutadas con la identidad equivocada o fuera de la transacción
correcta. Cambio el scope o, mejor, paso esos datos por parámetro en cada llamada.

🔬 **El detalle:** Pruebo con concurrencia real entre peticiones: con una sola petición a la vez,
este fallo no aparece nunca.

### 21. 🟠 Un módulo NestJS intenta inyectar solo una `interface`. ¿Cómo lo corriges?

⏱️ **30 segundos:** Registro un token de tiempo de ejecución asociado al provider concreto e inyecto
con ese token.

🗣️ **2 minutos:** Defino `export const ORDERS = Symbol('ORDERS')`, registro `{ provide: ORDERS,
useClass: PrismaOrders }` en el módulo y en el constructor del consumidor uso `@Inject(ORDERS)
private readonly orders: Orders`. El tipo `Orders` sigue siendo la interfaz estructural para el
compilador; el token es lo que el contenedor usa para resolver. Si el caso de uso es una clase sin
decoradores, lo construyo con `useFactory` e `inject: [ORDERS]`.

🔬 **El detalle:** Un tipo TypeScript borrado no resuelve la inyección: el error aparece al arrancar,
no al compilar, lo que hace valiosa la prueba de arranque.

### 22. 🟠 Un proyecto Go usa variables globales para DB y reloj. ¿Cómo expones sus dependencias?

⏱️ **30 segundos:** Pasando la base y el reloj por constructores, desde una función de composición
llamada en `main`.

🗣️ **2 minutos:** Cada adaptador recibe el pool en su constructor; cada caso de uso recibe sus
puertos y un `Clock` (o una función `now`). `main` crea el pool y el reloj real y los pasa hacia
abajo. Las pruebas construyen los mismos objetos con un reloj fijo y una base de prueba, sin mutar
variables globales, lo que además permite ejecutarlas en paralelo.

🔬 **El detalle:** El cierre del pool queda en `main`, que es quien lo creó. Con globales, nadie es
claramente responsable de cerrarlo y las pruebas se contaminan entre sí.

### 23. 🟠 La aplicación arranca en tests con doble, pero falla en producción. ¿Qué prueba faltó?

⏱️ **30 segundos:** Una prueba de composición con los adaptadores reales y una configuración
equivalente a la de producción.

🗣️ **2 minutos:** El doble ocultó un bean faltante, un token sin registrar, una dependencia del
adaptador real que no se proveía o una variable de configuración obligatoria. Añado una prueba que
arranque el grafo real contra recursos de prueba (contenedores de base y broker) y, además,
validación de configuración al arrancar que falle rápido y con un mensaje claro si falta algo.

🔬 **El detalle:** También valido las variables obligatorias al arranque en producción: que falle el
despliegue con "falta PAYMENT_URL" es mejor que el primer pago fallando a las tres de la mañana.

### 24. 🟠 ¿Cuándo quitarías una interfaz introducida solo para composición?

⏱️ **30 segundos:** Cuando no marca un límite de dependencia ni tiene una implementación alternativa
útil.

🗣️ **2 minutos:** Algunas interfaces existen solo porque el contenedor o una costumbre lo pedían:
`OrderMapper` con `OrderMapperImpl`, `NotificationService` con una sola implementación que nadie
sustituye. Inyectar la clase concreta es más claro y no cambia la dirección de dependencias si la
clase vive en el lugar correcto. Las elimino y dejo interfaces donde protegen un cambio o permiten
una prueba significativa.

🔬 **El detalle:** Mantengo la interfaz solo donde protege un cambio o una prueba significativa: los
puertos hacia recursos externos casi siempre; los colaboradores internos del núcleo, casi nunca.

---

## 05 · Configuración, observabilidad y resiliencia

### 1. 🟢 ¿Dónde se validan las opciones de despliegue?

⏱️ **30 segundos:** En el composition root, al arrancar y antes de atender tráfico.

🗣️ **2 minutos:** La configuración se lee de variables de entorno, archivos o un gestor de secretos,
se convierte a objetos tipados y se valida: que las URIs sean URIs, que los timeouts sean positivos,
que los secretos obligatorios existan, que las combinaciones tengan sentido (modo de pagos gRPC
exige su URL). Solo si todo es válido la aplicación empieza a aceptar peticiones. Los adaptadores
reciben la configuración ya validada.

🔬 **El detalle:** Un valor inválido debe fallar al arrancar, con un mensaje claro y sin revelar
secretos. Descubrirlo en la primera llamada remota convierte un error de despliegue en un incidente
de producción.

### 2. 🟢 ¿Qué configuración pertenece al adaptador remoto?

⏱️ **30 segundos:** URI, credenciales, timeouts, presupuesto de reintentos y parámetros del circuit
breaker.

🗣️ **2 minutos:** Todo eso es mecánica de conexión con un sistema concreto: cambia si cambia el
proveedor, el entorno o la red, no si cambia una regla de `Order`. Se agrupa en un objeto de
configuración tipado (`PaymentConfig(baseUrl, timeout, maxAttempts)`) que el composition root valida
y entrega al adaptador. El caso de uso nunca lo ve.

🔬 **El detalle:** Se pasan como configuración tipada, no como un mapa de cadenas: el tipo documenta
qué existe, el compilador ayuda y la validación está en un solo lugar.

### 3. 🟢 ¿Qué dato puede ser política configurable del núcleo?

⏱️ **30 segundos:** Un valor de negocio que el negocio quiere ajustar sin desplegar, como el importe
máximo de un pedido o el plazo de cancelación.

🗣️ **2 minutos:** Esos valores forman parte de la política: cambian las decisiones del dominio. Se
inyectan explícitamente en el caso de uso o en el dominio como parámetros con nombre y tipo propios
(`MaxOrderAmount`), con un dueño que decide su valor y un registro de cuándo cambió. Así las pruebas
pueden fijarlos y la política sigue siendo legible.

🔬 **El detalle:** No se leen del entorno dentro de la entidad: eso los esconde, los hace
dependientes del despliegue y hace imposible saber con qué valor se tomó una decisión pasada.

### 4. 🟢 ¿Qué diferencia hay entre log, métrica y traza?

⏱️ **30 segundos:** El log relata un evento concreto; la métrica agrega muchos eventos en números;
la traza sigue una operación a través de varios saltos.

🗣️ **2 minutos:** Un log responde "¿qué pasó con este pedido a las 10:02?"; una métrica, "¿cuántos
pedidos se rechazaron en la última hora y cuánto tardó el proveedor en el percentil 99?"; una traza,
"¿dónde se fueron los tres segundos de esta petición entre el controller, la base y el proveedor?".
Cada señal responde una pregunta operativa distinta, y se complementan: la métrica alerta, la traza
localiza, el log explica.

🔬 **El detalle:** Su coste incluye almacenamiento y cardinalidad: logs detallados de todo, métricas
con etiquetas ilimitadas o trazas al cien por cien pueden costar más que el sistema que observan.

### 5. 🟢 ¿Qué es un identificador de correlación?

⏱️ **30 segundos:** Una clave que une todos los registros de una misma operación a través de
componentes y procesos.

🗣️ **2 minutos:** El adaptador de entrada lo toma de la petición (un header de traza) o lo crea, y
lo propaga: a los logs, a las llamadas salientes, a los mensajes publicados, a la outbox. Así, desde
una queja de un cliente con un id se puede reconstruir todo lo que pasó, incluso en otro servicio
que consumió el evento horas después. Lo establecen y propagan los bordes; el núcleo no necesita
conocerlo.

🔬 **El detalle:** No sustituye una clave de idempotencia: la correlación identifica una ejecución
(cada reintento puede tener la suya); la clave de idempotencia identifica una intención de negocio
(igual en todos los reintentos).

### 6. 🟢 ¿Qué limita un timeout?

⏱️ **30 segundos:** El tiempo máximo que se espera una operación remota antes de abandonarla.

🗣️ **2 minutos:** Protege recursos propios (hilos, conexiones, memoria) de un destino lento, y hace
explícita la incertidumbre: pasado el plazo, la aplicación deja de esperar y decide qué hacer. Sin
timeout, un proveedor que no responde puede agotar el pool y tumbar todo el servicio. El valor debe
elegirse según la latencia normal del destino y el presupuesto de la petición entrante.

🔬 **El detalle:** No prueba que el proveedor no procesó la petición: solo que no respondió a tiempo.
Para operaciones con efectos, un timeout después de enviar es un resultado incierto.

### 7. 🟢 ¿Qué hace un circuit breaker?

⏱️ **30 segundos:** Deja de enviar llamadas temporalmente a un destino que está fallando, y falla
rápido mientras tanto.

🗣️ **2 minutos:** Cuenta fallos o latencias; al superar un umbral, se abre y las llamadas fallan de
inmediato sin tocar el destino, lo que protege recursos propios y da respiro al destino. Pasado un
tiempo, entra en estado semiabierto y deja pasar algunas llamadas de prueba; si funcionan, se
cierra. Es una protección de disponibilidad y de fallos en cascada.

🔬 **El detalle:** No decide el resultado de negocio: cuando está abierto, el adaptador devuelve "no
disponible" y el caso de uso decide qué hacer con el pedido, normalmente dejarlo pendiente.

### 8. 🟡 ¿Por qué no lees variables de entorno desde `Order`?

⏱️ **30 segundos:** Porque la entidad quedaría atada al despliegue, y sus reglas dependerían de un
estado global invisible.

🗣️ **2 minutos:** Si `Order` lee `MAX_ORDER_AMOUNT` del entorno, cada prueba tiene que manipular
variables globales, dos pruebas en paralelo pueden interferir, y la misma regla se comporta distinto
según el entorno sin que la firma lo diga. Además, un valor mal formado aparece como error en medio
de una operación de negocio. El arranque debe entregar valores de política ya validados, o
adaptadores ya configurados.

🔬 **El detalle:** Las pruebas dejan de depender del entorno y el dominio queda determinista: dada la
misma entrada, la misma decisión.

### 9. 🟡 ¿Cómo observas `OrderConfirmed` sin importar un SDK en el dominio?

⏱️ **30 segundos:** La aplicación nombra el hecho; un observador en el borde lo registra con el SDK
de telemetría.

🗣️ **2 minutos:** El caso de uso produce un resultado semántico o un evento de dominio
(`OrderConfirmed`); un decorador del caso de uso, un handler del evento o el adaptador de entrada lo
instrumentan: incrementan una métrica `orders_confirmed_total`, añaden atributos a la traza y
registran un log estructurado. La semántica la pone la aplicación, que es la única que sabe qué
significa; la mecánica, la infraestructura.

🔬 **El detalle:** No hace falta importar OpenTelemetry en `Order`. Si la aplicación necesita emitir
señales propias, puede hacerlo a través de un puerto pequeño (`OrderMetrics.confirmed()`)
implementado en el borde.

### 10. 🟡 ¿Por qué `orderId` es mala etiqueta de métrica?

⏱️ **30 segundos:** Porque crea una serie temporal por pedido, lo que dispara la cardinalidad, la
memoria y el coste del sistema de métricas.

🗣️ **2 minutos:** Cada combinación distinta de valores de etiquetas es una serie que el sistema de
métricas almacena y consulta. Con `orderId` como etiqueta, un millón de pedidos son un millón de
series de un solo punto, inútiles para agregar y caras de mantener; el sistema de métricas puede
degradarse o caer. Las etiquetas deben tener valores finitos y pocos: resultado (`authorized`,
`rejected`), operación, proveedor.

🔬 **El detalle:** El id del pedido puede estar en un log protegido o como atributo de una traza, que
están pensados para datos de alta cardinalidad y consultas puntuales.

### 11. 🟡 ¿Qué debe ocurrir si falta un secreto obligatorio?

⏱️ **30 segundos:** La aplicación debe fallar al iniciar, con un error seguro que diga qué falta sin
mostrar valores.

🗣️ **2 minutos:** Si arranca sin el secreto del proveedor de pagos, todo parece sano hasta el primer
cobro, que falla; el orquestador sigue enviando tráfico a una instancia que no puede cumplir su
función. Fallando al arrancar, el despliegue se detiene, el orquestador no la marca como lista y el
problema se ve de inmediato en el lugar correcto. Continuar produciría fallos parciales,
intermitentes y difíciles de diagnosticar.

🔬 **El detalle:** El secreto nunca se imprime en el mensaje de error, ni siquiera parcialmente, ni
en los logs de configuración cargada.

### 12. 🟡 ¿Cómo calculas presupuesto de retry y deadline?

⏱️ **30 segundos:** Sumo los intentos, sus timeouts y los tiempos de espera entre ellos, y compruebo
que el total cabe en el presupuesto de la petición entrante.

🗣️ **2 minutos:** Tres intentos de tres segundos con un backoff de uno y dos segundos suman doce
segundos; si el cliente espera cinco, no caben. Reduzco intentos, acorto el timeout por intento o
acepto que algunos reintentos ocurran después, de forma asíncrona. Además, el adaptador recibe el
presupuesto restante de la petición y no empieza un intento que no podría terminar.

🔬 **El detalle:** Los reintentos no deben sobrevivir a la petición agotada: si el cliente ya se fue,
seguir llamando al proveedor consume recursos y puede producir efectos que nadie reportará. En
cadenas de servicios, los reintentos anidados se multiplican.

### 13. 🟡 ¿Cuándo reintentas un cobro remoto?

⏱️ **30 segundos:** Solo si el fallo es transitorio y la operación es idempotente con una clave
estable.

🗣️ **2 minutos:** Reintento ante errores de red antes de enviar, `429` o `503`, reutilizando la
misma clave de operación persistida, con espera exponencial y un límite dentro del deadline. No
reintento rechazos definitivos. Si el fallo fue un timeout después de enviar y el proveedor no
garantiza idempotencia, no reintento a ciegas: consulto el estado de la operación o dejo el pedido
pendiente.

🔬 **El detalle:** Un timeout puede dejar un resultado incierto, y la forma segura de resolverlo
depende de lo que el proveedor garantice. Leer su documentación sobre idempotencia es parte del
diseño del adaptador.

### 14. 🟡 ¿Para qué sirve `AsyncLocalStorage` en Node?

⏱️ **30 segundos:** Para propagar contexto a lo largo de callbacks y promesas de un mismo flujo
asíncrono, sin pasarlo por parámetro.

🗣️ **2 minutos:** Es la base de la correlación de logs y trazas en Node: el adaptador de entrada
guarda el identificador de correlación al empezar la petición, y cualquier log posterior del mismo
flujo lo recupera, aunque haya muchos `await` de por medio. También sirve para que una unidad de
trabajo comparta el cliente transaccional con los adaptadores.

🔬 **El detalle:** No lo uso como fuente implícita de autorización: si la política lee el actor de
ahí, un job o un flujo que no lo establezca ejecuta sin control. El actor viaja explícito en el
comando.

### 15. 🟡 ¿Qué aporta `log/slog` de Go y qué no decide?

⏱️ **30 segundos:** Aporta logs estructurados con pares clave-valor, niveles y handlers
intercambiables; no decide qué registrar.

🗣️ **2 minutos:** Con `slog`, un log es `logger.Info("authorize_payment", "result", "rejected",
"latency_ms", 230)`, que se puede emitir como JSON y consultar por campos. Se integra con el
`context` para añadir atributos comunes. Pero la aplicación decide qué evento es relevante, con qué
nivel y qué datos son seguros de incluir (nada de tokens, importes solo si están permitidos).

🔬 **El detalle:** El logger no reemplaza las métricas agregadas: contar rechazos leyendo logs es
caro y lento; un contador es barato e inmediato.

### 16. 🟡 ¿Qué métrica muestra atasco de outbox?

⏱️ **30 segundos:** La edad del registro pendiente más antiguo.

🗣️ **2 minutos:** Si el dispatcher funciona, esa edad se mantiene en segundos; si crece de forma
sostenida, algo está atascado: el dispatcher murió, el broker no confirma o hay un evento envenenado
bloqueando el lote. También mido la cantidad de pendientes, los intentos por registro y los errores
de entrega clasificados, que ayudan a saber por qué.

🔬 **El detalle:** La edad descubre un dispatcher detenido, que es el fallo más silencioso: no hay
errores, porque nadie intenta nada. Una alerta sobre ese valor es la más valiosa del patrón.

### 17. 🟠 Un retry de tres intentos supera el deadline HTTP. ¿Qué ajustas?

⏱️ **30 segundos:** El número de intentos, el timeout por intento y el backoff, hasta que el total
quepa en el deadline.

🗣️ **2 minutos:** Hago la cuenta y elijo: menos intentos con timeouts más cortos si el proveedor
suele responder rápido, o un solo intento síncrono y el resto de forma asíncrona (el pedido queda
pendiente y un proceso reintenta). Además, el adaptador recibe el presupuesto restante y calcula el
timeout de cada intento a partir de él, en lugar de usar un valor fijo.

🔬 **El detalle:** No inicio un intento que ya no puede terminar a tiempo: si quedan doscientos
milisegundos y el proveedor tarda uno de media, lo honesto es devolver "incierto" o "no disponible"
ya.

### 18. 🟠 Un log contiene tokens del proveedor. ¿Qué corriges?

⏱️ **30 segundos:** Elimino o enmascaro los tokens en el origen, restrinjo el acceso a los logs
afectados y roto la credencial.

🗣️ **2 minutos:** Busco dónde se registra: normalmente un log de la petición completa en el
adaptador, o un error que incluye los headers. Lo corrijo para que las credenciales viajen solo por
el canal protegido y nunca como campo de telemetría, y añado redacción automática de campos
sensibles en el logger. Como el token ya estuvo expuesto, lo trato como comprometido.

🔬 **El detalle:** Reviso los logs históricos (retención, quién tuvo acceso) y roto el secreto
afectado. Corregir el código sin rotar deja una credencial válida en los archivos de logs.

### 19. 🟠 El breaker abre y el caso de uso devuelve pago aprobado. ¿Qué falla?

⏱️ **30 segundos:** Se confundió disponibilidad con autorización: el fallback del breaker inventó un
resultado de negocio.

🗣️ **2 minutos:** Cuando el breaker está abierto, el adaptador debe devolver "no disponible"
(sabemos que no se procesó), y el caso de uso decide: pedido pendiente de pago, reintento posterior
o un error explícito al cliente, según el contrato. Nunca aprobado, porque nadie autorizó nada.
Corrijo el fallback del adaptador y añado una prueba que abra el breaker y compruebe el estado
resultante del pedido.

🔬 **El detalle:** Un breaker no fabrica una confirmación: protege recursos, no decide negocio. Si
alguien quiere aceptar pagos sin proveedor, es una regla de negocio explícita con límites, no un
fallback.

### 20. 🟠 Una métrica etiqueta cada `customerId`. ¿Qué riesgo causa?

⏱️ **30 segundos:** Explota la cardinalidad y el coste del sistema de métricas, y puede exponer
información sensible.

🗣️ **2 minutos:** Con miles o millones de clientes, cada uno es una serie temporal; el sistema de
métricas se degrada, las consultas se vuelven lentas y la factura crece. Sustituyo la etiqueta por
otras acotadas (segmento de cliente, plan, región) y dejo el identificador del cliente en trazas o
logs protegidos, donde se consulta puntualmente.

🔬 **El detalle:** También puede exponer información sensible: los sistemas de métricas suelen tener
controles de acceso más laxos que los de datos, y un identificador de cliente ahí es un dato
personal fuera de su perímetro.

### 21. 🟠 Un worker pierde la correlación al procesar un mensaje. ¿Dónde la restableces?

⏱️ **30 segundos:** En el adaptador de entrada que recibe el mensaje, al principio del
procesamiento.

🗣️ **2 minutos:** El productor debe incluir la correlación en los headers del mensaje (o en el
sobre); el adaptador del consumidor la extrae, la valida y la establece en el contexto de logs y
trazas antes de llamar al caso de uso. Si el mensaje no la trae, crea una nueva y registra la
relación con el id del mensaje. A partir de ahí se propaga a todo lo que el worker haga.

🔬 **El detalle:** El núcleo recibe solo el contexto propio que necesita; la correlación vive en la
infraestructura de observabilidad del borde, no en el comando como dato de negocio.

### 22. 🟠 Una variable de timeout vale `-1` y se descubre en producción. ¿Qué prueba falta?

⏱️ **30 segundos:** Validación de configuración al arrancar, con tipos y rangos, y una prueba que la
ejerza.

🗣️ **2 minutos:** El objeto de configuración tipado debe rechazar valores fuera de rango en su
construcción (timeout positivo, intentos mayor que cero), y la aplicación debe negarse a arrancar
con un mensaje claro. Una prueba de composición que construya la configuración con valores inválidos
y compruebe el rechazo evita que alguien quite la validación sin darse cuenta.

🔬 **El detalle:** No espero a la primera llamada remota para descubrirlo: un `-1` interpretado como
"sin límite" por una biblioteca puede pasar meses sin notarse, hasta el día en que el proveedor se
cuelga.

### 23. 🟠 El equipo quiere meter `traceId` en la entidad `Order`. ¿Qué respondes?

⏱️ **30 segundos:** Que no forma parte del estado de negocio del pedido y no debe estar en la
entidad.

🗣️ **2 minutos:** El `traceId` identifica una ejecución técnica, no un atributo del pedido: un mismo
pedido pasa por muchas trazas (creación, pago, cancelación). La infraestructura lo conserva para
diagnosticar, propagándolo entre bordes y enlazándolo con los logs. Si se necesita saber qué
operación creó un pedido, se registra en auditoría o en los metadatos del evento, no en el agregado.

🔬 **El detalle:** No debe entrar en la igualdad ni en la persistencia del agregado: mezclaría
conceptos de observabilidad con el modelo, y cada cambio de herramienta de trazas tocaría el
dominio.

### 24. 🟠 ¿Cuándo no introducirías circuit breaker en una integración?

⏱️ **30 segundos:** Cuando la dependencia es simple, poco crítica o de bajo volumen, y un buen
timeout con errores explícitos basta.

🗣️ **2 minutos:** Un breaker añade estado, umbrales que calibrar, un comportamiento más que probar y
una fuente más de confusión en incidentes ("¿está caído el proveedor o está abierto el breaker?").
Para una llamada ocasional a un servicio interno estable, un timeout, un reintento acotado y una
métrica de errores cubren el riesgo. Lo introduzco cuando hay evidencia de fallos en cascada o de un
destino que tarda en recuperarse bajo presión.

🔬 **El detalle:** Añado el breaker con evidencia, no por plantilla. Y cuando lo añado, lo observo:
estado, aperturas y llamadas rechazadas son métricas obligatorias.

---

## 06 · Testing por anillos y contratos

### 1. 🟢 ¿Qué prueba una prueba pura de dominio?

⏱️ **30 segundos:** Las invariantes y transiciones del agregado, ejecutando el dominio sin base de
datos ni framework.

🗣️ **2 minutos:** Se construye un `Order` con valores propios, se ejecuta una operación (`confirm`,
`cancel`) y se comprueba el estado resultante o el error. Corre en milisegundos, no necesita dobles
y documenta las reglas mejor que cualquier comentario. Es la prueba que falla cuando cambia una
regla de negocio, y ninguna otra debería fallar por ese motivo.

🔬 **El detalle:** Debe incluir los estados inválidos y las transiciones prohibidas, no solo el
camino feliz: confirmar un pedido vacío, cancelar uno enviado, crear uno con importe negativo.

### 2. 🟢 ¿Qué prueba una prueba de caso de uso con dobles?

⏱️ **30 segundos:** La coordinación de puertos, la traducción de errores y los resultados de la
aplicación.

🗣️ **2 minutos:** `CreateOrder` se construye con fakes pequeños de `Orders` y del inventario; la
prueba ejecuta escenarios (pedido válido, stock insuficiente, operación repetida, actor sin permiso)
y comprueba el resultado devuelto y el estado que quedó en los fakes. Así se verifica qué hace el
caso de uso con sus colaboradores sin levantar infraestructura.

🔬 **El detalle:** No prueba SQL, serialización ni el comportamiento real del broker: eso es trabajo
de las pruebas de cada adaptador. Una prueba de caso de uso verde con un adaptador roto es
perfectamente posible.

### 3. 🟢 ¿Qué prueba una integración del adaptador JPA?

⏱️ **30 segundos:** El mapeo, las restricciones, el comportamiento de la sesión y las consultas
reales contra una base.

🗣️ **2 minutos:** Persisto un pedido, cierro la sesión (para que no quede nada en caché), lo recargo
y compruebo que el estado reconstruido es el mismo, incluidos importes, líneas y versión. También
pruebo que una restricción única se traduce al error propio, que el control optimista detecta
conflictos y que un listado no dispara N+1.

🔬 **El detalle:** Una base de la misma familia que producción detecta diferencias que un mock
oculta: tipos, precisión de decimales, comportamiento de restricciones y bloqueos.

### 4. 🟢 ¿Qué es un test de contrato de puerto?

⏱️ **30 segundos:** Un conjunto de expectativas compartidas que deben cumplir todas las
implementaciones de un puerto.

🗣️ **2 minutos:** Para `Orders`: guardar y leer devuelve el mismo pedido; buscar uno inexistente
devuelve vacío; guardar con una versión obsoleta falla con conflicto. La misma batería se ejecuta
contra el fake en memoria y contra el adaptador JPA. Si ambos pasan, el fake es fiel y las pruebas
de caso de uso que lo usan son confiables.

🔬 **El detalle:** No exige la misma implementación interna, solo el mismo comportamiento observable
en lo que el núcleo necesita. Es la herramienta que evita que los fakes mientan.

### 5. 🟢 ¿Qué detecta una regla arquitectónica de imports?

⏱️ **30 segundos:** Dependencias de código que cruzan límites prohibidos, en el momento del build.

🗣️ **2 minutos:** Por ejemplo, que una clase de `domain` importe `jakarta.persistence`, que
`application` importe el framework web o que un adaptador de entrada importe uno de salida. ArchUnit
en Java, dependency-cruiser en TypeScript, import-linter en Python o deptrac en PHP expresan esas
reglas en pocas líneas y fallan en CI cuando alguien las rompe.

🔬 **El detalle:** No valida transacciones, comportamiento ni filtraciones de datos: un núcleo puede
cumplir todas las reglas de imports y recibir filas de SQL como mapas. Detecta dirección, no
corrección.

### 6. 🟢 ¿Para qué sirve Testcontainers aquí?

⏱️ **30 segundos:** Para levantar recursos reales de prueba —PostgreSQL, un broker— de forma
reproducible y desechable.

🗣️ **2 minutos:** Cada ejecución de pruebas arranca contenedores con la misma versión que
producción, las pruebas de adaptadores se ejecutan contra ellos y al terminar se destruyen. Así se
detectan problemas de mapeo, dialecto SQL, restricciones y protocolo que ningún doble reproduce, sin
depender de una base compartida de desarrollo.

🔬 **El detalle:** Cuesta tiempo de arranque y recursos de CI, y no sustituye las expectativas: el
contenedor da la infraestructura, pero qué comprobar lo decide el equipo.

### 7. 🟡 ¿Qué significa observar el estado y no solo una llamada?

⏱️ **30 segundos:** Afirmar el efecto observable del caso de uso —el estado resultante y el
resultado devuelto— en lugar de las interacciones con sus colaboradores.

🗣️ **2 minutos:** `verify(orders).save(any())` comprueba que se llamó a `save`, no que el pedido
guardado esté confirmado, tenga las líneas correctas o el total bien calculado. Con un fake, la
prueba recupera el pedido y comprueba su estado. Esa aserción sobrevive a refactorizaciones internas
(cambiar el orden de las llamadas, guardar una vez en lugar de dos) y falla solo cuando el
comportamiento cambia.

🔬 **El detalle:** La aserción debe mirar el estado y el resultado. Las verificaciones de llamadas
tienen sentido para efectos que no dejan estado observable, como enviar una notificación, y aun así
conviene un fake que las registre.

### 8. 🟡 ¿Cuándo usarías una base real en vez de un fake?

⏱️ **30 segundos:** Cuando el fallo que quieres detectar depende de SQL, restricciones,
transacciones o concurrencia.

🗣️ **2 minutos:** Para probar la coordinación de `CreateOrder`, un fake basta y es más rápido. Para
probar que `JpaOrders` guarda y reconstruye bien un pedido, que una violación de unicidad se
traduce, que la transacción revierte todo junto o que dos escrituras concurrentes se detectan, hace
falta la base real. Una integración de `JpaOrders` ejecuta el contrato del puerto contra ella.

🔬 **El detalle:** El fake queda para la coordinación del caso de uso; la base real, para la
frontera. Usar la base para todo hace las pruebas lentas; usar fakes para todo deja la frontera sin
probar.

### 9. 🟡 ¿Qué riesgo tiene una base en memoria distinta a producción?

⏱️ **30 segundos:** Que tiene otro dialecto, otros bloqueos y otras restricciones, y un test verde
en ella no garantiza nada en producción.

🗣️ **2 minutos:** H2 o SQLite pueden aceptar SQL que PostgreSQL rechaza (o al revés), tratar los
decimales con otra precisión, no soportar tipos como `jsonb`, ignorar ciertas restricciones o no
reproducir el aislamiento transaccional. Las pruebas pasan y el despliegue falla. Con contenedores,
levantar la misma base que en producción es casi igual de barato.

🔬 **El detalle:** Uso una base de la misma familia y versión en las fronteras críticas. La base en
memoria puede servir para pruebas muy rápidas de algo que no depende del motor, pero entonces
probablemente un fake es mejor.

### 10. 🟡 ¿Cómo compruebas que un mapper reconstruye invariantes?

⏱️ **30 segundos:** Persistiendo el agregado, cerrando la sesión, recargándolo y ejecutando una
regla sobre el objeto reconstruido.

🗣️ **2 minutos:** Si el mapper omite un campo (las líneas, la moneda), la regla fallará o dará otro
resultado; si devuelve un proxy lazy, acceder a una relación fuera de la sesión fallará. Cerrar la
sesión es esencial: sin eso, el ORM puede devolver el mismo objeto en memoria y la prueba no
ejercita el mapeo. Comparar campo a campo el original y el reconstruido complementa la prueba.

🔬 **El detalle:** Incluyo la identidad y la versión optimista en la comprobación: perder la versión
no rompe ninguna regla visible, pero desactiva el control de concurrencia en silencio.

### 11. 🟡 ¿Qué test detectaría N+1?

⏱️ **30 segundos:** Una prueba de integración que ejecute el listado contra una base real y cuente
las consultas.

🗣️ **2 minutos:** Preparo una lista pequeña y otra grande de pedidos con sus líneas, ejecuto el
listado y cuento las sentencias SQL (con el contador de estadísticas del ORM, un datasource
instrumentado o los logs del driver). Si el número crece con el tamaño de la lista, hay N+1. La
prueba afirma un máximo fijo ("como mucho dos consultas") y falla si alguien reintroduce el
problema.

🔬 **El detalle:** Un doble jamás emite SQL, así que ninguna prueba con mocks puede detectar este
problema. Es un ejemplo perfecto de por qué hacen falta pruebas en la frontera real.

### 12. 🟡 ¿Cómo pruebas un cliente de pagos sin cobrar de verdad?

⏱️ **30 segundos:** Con un servidor controlado que simule al proveedor, o con el entorno de pruebas
(sandbox) que el proveedor ofrezca.

🗣️ **2 minutos:** El servidor simulado (WireMock, un servidor HTTP o gRPC en proceso) responde lo
que la prueba necesita: aprobado, rechazado, `429`, `503`, una respuesta lenta, una conexión
cortada. Verifico que el adaptador envía el payload y los headers correctos (incluida la clave de
idempotencia), respeta el timeout y mapea cada respuesta al resultado propio correcto. El sandbox
del proveedor sirve para una prueba de contrato periódica.

🔬 **El detalle:** El caso de uso usa aparte un doble de `PaymentGateway`; esa prueba no ejercita el
adaptador. Son dos anillos y los dos hacen falta.

### 13. 🟡 ¿Qué cubre un contrato de evento externo?

⏱️ **30 segundos:** El esquema, los campos, la versión y la compatibilidad del evento entre
productor y consumidores.

🗣️ **2 minutos:** El contrato (un esquema Avro o JSON Schema, un documento AsyncAPI) fija qué campos
tiene el evento, sus tipos, cuáles son obligatorios y qué significan. Las pruebas de contrato
verifican que el productor emite eventos válidos según ese esquema y que los cambios son compatibles
con las versiones que los consumidores entienden. Así una ruptura se detecta antes de desplegar.

🔬 **El detalle:** Un test de compilación no detecta una ruptura externa: el productor compila
perfectamente después de renombrar un campo que tres consumidores leen.

### 14. 🟡 ¿Qué aporta ArchUnit y qué no cubre?

⏱️ **30 segundos:** Detecta imports prohibidos y violaciones de reglas de capas en el código Java,
en el build.

🗣️ **2 minutos:** Con unas pocas reglas —el dominio no depende de Spring ni de JPA, la aplicación no
depende de la infraestructura, los adaptadores no dependen entre sí— la frontera deja de ser una
convención y pasa a ser una prueba que falla. Es barato de mantener y enseña al equipo, porque cada
fallo explica qué regla se rompió.

🔬 **El detalle:** No ejecuta JPA ni demuestra la atomicidad de la outbox: comprueba la estructura,
no el comportamiento. Lo combino con pruebas de integración concretas en cada frontera.

### 15. 🟡 ¿Qué ofrece `go test` sin librería extra?

⏱️ **30 segundos:** Un runner integrado en la toolchain y el paquete estándar `testing`, con
subtests, benchmarks y fuzzing.

🗣️ **2 minutos:** Con `go test` se escriben pruebas de dominio, de casos de uso con fakes escritos a
mano (fáciles gracias a las interfaces implícitas), de handlers con `httptest` y de adaptadores
contra una base real. Las pruebas en tabla cubren muchas combinaciones con poco código, el detector
de carreras encuentra problemas de concurrencia y el fuzzing encuentra entradas inesperadas.

🔬 **El detalle:** El equipo aún diseña los fixtures, los contratos de puerto y qué frontera merece
infraestructura real: la herramienta ejecuta pruebas, no decide cuáles escribir.

### 16. 🟡 ¿Cómo evitas fixtures Python que contaminan pruebas?

⏱️ **30 segundos:** Aislando sesión, datos y recursos por prueba, con alcance explícito y limpieza
garantizada.

🗣️ **2 minutos:** Uso fixtures de pytest con el alcance mínimo necesario (`function` para datos,
`session` solo para recursos caros e inmutables como un contenedor), transacciones que se revierten
al final de cada prueba o datos con identificadores únicos, y limpieza en el `yield`. Evito estado
mutable global compartido entre pruebas, como un fake a nivel de módulo que acumula datos.

🔬 **El detalle:** Una prueba debe poder correr sola y en cualquier orden. Ejecutar la suite en orden
aleatorio (con un plugin) detecta dependencias ocultas entre pruebas.

### 17. 🟠 Todos los mocks pasan y JPA pierde `version`. ¿Qué prueba agregas?

⏱️ **30 segundos:** Una prueba de integración de `JpaOrders` contra una base real que guarde,
recargue y compruebe la versión.

🗣️ **2 minutos:** Guardo un pedido, lo recargo en otra sesión y compruebo que la versión se
conservó; después simulo una escritura concurrente (dos cargas, dos guardados) y compruebo que la
segunda falla con conflicto. Si el mapper pierde la versión, la primera aserción falla; si el
control optimista no funciona, la segunda. Además, convierto esas expectativas en parte del contrato
del puerto.

🔬 **El detalle:** El mock de la interfaz solo verificó la coordinación del caso de uso: nunca
ejecutó el mapeo ni la base, así que no podía detectar esto.

### 18. 🟠 El controller filtra un campo sensible. ¿Qué prueba faltó?

⏱️ **30 segundos:** Una prueba del adaptador HTTP que haga una petición real e inspeccione el JSON
devuelto.

🗣️ **2 minutos:** La prueba compara las claves de la respuesta con una lista permitida y comprueba
explícitamente que los campos sensibles no aparecen. Se ejecuta contra el adaptador con su
serializador y su configuración reales. Si alguien añade un campo al modelo o cambia la proyección,
la prueba falla antes de publicar nada.

🔬 **El detalle:** Una prueba aislada del mapper puede pasar y no reflejar lo que hace el
serializador configurado: propiedades calculadas, módulos del serializador o un `response_model` mal
definido pueden publicar campos que el mapper nunca tocó.

### 19. 🟠 La outbox publica dos veces tras una caída. ¿Qué verificas?

⏱️ **30 segundos:** Que el consumidor deduplica por el identificador del evento y aplica un solo
efecto.

🗣️ **2 minutos:** Provoco la caída entre publicar y marcar la fila como enviada, reinicio el
dispatcher y compruebo que el evento se publica otra vez con el mismo identificador y que el
consumidor lo reconoce: el efecto (la notificación, la fila de la proyección) existe una sola vez.
También compruebo que el identificador no cambia entre intentos.

🔬 **El detalle:** La outbox permite duplicados por diseño; esa frontera debe tolerarlos. Si la
prueba falla, el problema no es la outbox sino un consumidor no idempotente.

### 20. 🟠 El caso de uso guarda antes de validar una invariante. ¿Qué aserción haces?

⏱️ **30 segundos:** Que tras el rechazo no quedó ningún cambio persistido.

🗣️ **2 minutos:** Ejecuto el caso de uso con datos que violan la invariante, compruebo que devuelve
el error esperado y, sobre todo, que el fake de `Orders` (o la base, en una integración) no contiene
el pedido. Una prueba que solo mira el error pasaría aunque el pedido inválido se hubiera guardado
antes de lanzar la excepción. La aserción sobre el estado detecta el orden incorrecto.

🔬 **El detalle:** La invariante debe impedir el efecto, no solo producir un error. Y si la
transacción revierte, la prueba de integración lo confirma; la de fakes, que el caso de uso no
guardó.

### 21. 🟠 Un test end to end tarda minutos y falla por una regla simple. ¿Cómo lo redistribuyes?

⏱️ **30 segundos:** Paso la regla a una prueba pura de dominio y dejo el end to end para un flujo
integrado representativo.

🗣️ **2 minutos:** La regla (por ejemplo, el cálculo de un descuento) se prueba en milisegundos con
todas sus combinaciones en el dominio; la coordinación, con fakes en el caso de uso; los
adaptadores, en integración. El test end to end queda como uno o pocos flujos que comprueban que
todo está conectado. Así, cuando una regla falla, falla una prueba pequeña que señala la causa, no
una de minutos que hay que depurar.

🔬 **El detalle:** Conservo la integración para comprobar el wiring y el contrato; lo que elimino es
usarla como único lugar donde se prueba la lógica.

### 22. 🟠 Un fake de `Orders` permite duplicados que la base rechaza. ¿Cómo corriges el contrato?

⏱️ **30 segundos:** Hago que el fake cumpla la misma restricción de unicidad, o dejo de usarlo para
los casos que dependen de ella.

🗣️ **2 minutos:** Añado la expectativa al test de contrato del puerto ("guardar dos pedidos con la
misma clave de operación falla con conflicto") y la ejecuto contra el fake y contra el adaptador
real. El fake se corrige para cumplirla. Así, las pruebas de idempotencia del caso de uso que usan
el fake vuelven a ser confiables.

🔬 **El detalle:** Un doble demasiado permisivo produce falsa confianza: las pruebas pasan
exactamente en los casos donde producción falla. El test de contrato es lo que mantiene honestos a
los fakes.

### 23. 🟠 Un build pasa aunque dominio importe JPA. ¿Qué control añades?

⏱️ **30 segundos:** Una regla de arquitectura que se ejecute en el build y falle ante ese import.

🗣️ **2 minutos:** Con ArchUnit, una regla como "las clases de `..domain..` no deben depender de
`jakarta.persistence..` ni de `org.springframework..`" como prueba que corre en CI. En un proyecto
más grande, separar el dominio en un módulo de build sin dependencia de JPA hace que ni siquiera
compile. En otros lenguajes, dependency-cruiser, import-linter o deptrac cumplen el mismo papel.

🔬 **El detalle:** No sustituye la prueba de negocio: la regla garantiza que el dominio no depende de
JPA, no que sus reglas sean correctas.

### 24. 🟠 ¿Cuándo evitarías levantar Testcontainers para una prueba?

⏱️ **30 segundos:** Cuando la prueba es de dominio puro o de coordinación del caso de uso, que no
dependen de infraestructura.

🗣️ **2 minutos:** Levantar una base añade segundos por ejecución, recursos de CI y posibles fallos
intermitentes, sin detectar ningún riesgo nuevo si lo que se prueba es una regla o una coordinación.
Esas pruebas deben ser rápidas para ejecutarse constantemente mientras se desarrolla. Reservo los
contenedores para las pruebas de adaptadores y de composición, donde el contrato real lo requiere.

🔬 **El detalle:** Uso infraestructura donde el contrato la requiere. Si una prueba de dominio
necesita una base para correr, el problema es de diseño, no de herramienta.

---

## 07 · Evolución y migración desde un monolito

### 1. 🟢 ¿Qué es una seam en un monolito?

⏱️ **30 segundos:** Un punto donde se puede sustituir comportamiento sin editar a todos los que lo
usan.

🗣️ **2 minutos:** En un monolito puede ser la llamada a `authorizePayment`, la función que guarda
pedidos o una ruta interna: un lugar por donde pasa todo el tráfico de una capacidad. Si se pone un
puerto en esa costura, se puede envolver el SQL o el SDK actual detrás de él y, después, redirigir
el flujo gradualmente a otra implementación. La costura permite cambiar sin reescribir.

🔬 **El detalle:** La costura debe ser estrecha (una capacidad, no todo el módulo) y observable
(métricas de qué camino se usa), para que el cambio se pueda medir y revertir.

### 2. 🟢 ¿Qué dolor te indica por dónde empezar?

⏱️ **30 segundos:** Cambios frecuentes en el mismo código, pruebas imposibles o lentas e incidentes
de integración.

🗣️ **2 minutos:** Busco dónde el acoplamiento cuesta dinero hoy: una regla de crédito que cambia
cada sprint y obliga a tocar el controller, el SQL y el SDK; un flujo que nadie se atreve a tocar
porque no tiene pruebas; un proveedor cuyos cambios rompen producción. Elijo una capacidad con dolor
medible, como crear pedido, porque así el primer paso entrega una mejora que el equipo nota.

🔬 **El detalle:** No empiezo por renombrar carpetas: cambia nombres, no dependencias, consume el
crédito del equipo y no alivia ningún dolor concreto.

### 3. 🟢 ¿Qué es una prueba de caracterización?

⏱️ **30 segundos:** Una prueba que documenta lo que el sistema hace hoy, sea correcto o no.

🗣️ **2 minutos:** Antes de extraer una capacidad, escribo pruebas que ejecutan el flujo actual con
entradas representativas —incluidos casos raros— y fijan sus resultados. No afirman lo que debería
pasar, sino lo que pasa. Durante la extracción, protegen de cambiar el comportamiento sin querer: si
una falla, el refactor alteró algo. Son la red de seguridad que permite mover código con confianza.

🔬 **El detalle:** Pueden revelar bugs. Corregir la política se decide aparte, con su propia prueba
del comportamiento deseado: mezclar extracción y corrección hace imposible saber qué cambió por qué.

### 4. 🟢 ¿Qué significa strangler interno?

⏱️ **30 segundos:** Mover una capacidad gradualmente a una nueva implementación dentro del mismo
despliegue, hasta que la vieja pueda retirarse.

🗣️ **2 minutos:** El controller empieza a delegar la creación de pedidos en un nuevo caso de uso con
sus puertos, mientras otras rutas siguen usando el código viejo. Poco a poco, más rutas y más
clientes pasan al nuevo camino; cuando el viejo no recibe tráfico, se borra. Es la idea del
*strangler fig* de Fowler aplicada dentro de un monolito, sin red de por medio.

🔬 **El detalle:** No obliga a microservicios: la capacidad extraída puede seguir en el mismo proceso
para siempre. Separarla en otro servicio es una decisión posterior e independiente.

### 5. 🟢 ¿Qué es branch by abstraction?

⏱️ **30 segundos:** Introducir una abstracción temporal que permite que la implementación vieja y la
nueva coexistan mientras los clientes migran.

🗣️ **2 minutos:** Primero se crea un puerto alrededor de la capacidad, implementado por el código
actual. Luego los clientes pasan a usar el puerto. Después se escribe la implementación nueva detrás
del mismo puerto, y la composición elige cuál usar (por configuración o por flag). Cuando la nueva
está validada, se retira la vieja. Todo ocurre en la rama principal, con el sistema desplegable en
cada paso.

🔬 **El detalle:** Retiro el camino viejo al cerrar la migración y reviso si la abstracción sigue
aportando: si solo existía para la transición, también puede irse.

### 6. 🟢 ¿Por qué mover carpetas no basta?

⏱️ **30 segundos:** Porque los imports y los contratos pueden seguir apuntando hacia los detalles
aunque las clases estén en otra ruta.

🗣️ **2 minutos:** Mover `OrderEntity` a un paquete `domain` no la desacopla de JPA: sigue teniendo
anotaciones, relaciones lazy y la forma de la tabla. Mover un servicio a `application` no hace que
deje de recibir `HttpServletRequest`. La reorganización cambia la navegación, no la dirección de las
dependencias, y además genera un diff enorme que dificulta revisar los cambios reales.

🔬 **El detalle:** La arquitectura se prueba por dependencias: una regla de imports o una prueba que
construye el núcleo sin infraestructura dicen si la migración avanza; el árbol de carpetas no.

### 7. 🟡 ¿Qué debe hacer el adaptador legado?

⏱️ **30 segundos:** Cumplir el puerto propio nuevo usando la tecnología actual, sin reescribirla.

🗣️ **2 minutos:** `LegacyPaymentGateway` implementa `PaymentGateway` llamando al SDK viejo, y
traduce sus respuestas a los resultados propios. `LegacyOrders` implementa `Orders` con el SQL que
ya existía. Así el nuevo caso de uso puede empezar a usarse y probarse de inmediato, sobre la
infraestructura de siempre. Reescribir los adaptadores es un paso posterior, que solo se da si hay
motivo.

🔬 **El detalle:** Permite probar el nuevo caso de uso inmediatamente con fakes y en producción con
el comportamiento conocido. A veces el adaptador legado se queda para siempre, y está bien si cumple
el contrato.

### 8. 🟡 ¿Cómo eliges la primera capacidad a extraer?

⏱️ **30 segundos:** Por riesgo, frecuencia de cambio y posibilidad de medir el resultado.

🗣️ **2 minutos:** Prefiero un flujo vertical completo —por ejemplo, `CreateOrder` desde la petición
hasta la base— con un resultado observable (pedidos creados, errores, latencia), que cambie a menudo
y cuyo dolor sea conocido. Así puedo comparar antes y después, el equipo nota la mejora y aprendo el
patrón de migración en un caso real antes de aplicarlo a otros.

🔬 **El detalle:** Evito elegir solo por facilidad de mover archivos: la capacidad más fácil suele
ser la que menos duele, y extraerla demuestra poco y protege poco.

### 9. 🟡 ¿Por qué conviene conservar el despliegue monolítico al principio?

⏱️ **30 segundos:** Porque reduce los cambios simultáneos: se limpian las dependencias internas sin
añadir red, despliegues nuevos ni consistencia distribuida.

🗣️ **2 minutos:** Una extracción interna ya produce los beneficios principales: pruebas del núcleo
sin infraestructura, reglas en un lugar, adaptadores sustituibles. Las transacciones siguen siendo
locales y los errores, llamadas en proceso. Si después se decide separar la capacidad en otro
servicio, el puerto ya está definido y la extracción es mucho más segura.

🔬 **El detalle:** Separar servicios añade red, latencia, fallos parciales, versionado de contratos y
consistencia eventual. Son costes que conviene asumir por una razón concreta, no como parte obligada
de "hacer hexagonal".

### 10. 🟡 ¿Cómo comparas comportamiento viejo y nuevo sin duplicar pagos?

⏱️ **30 segundos:** Comparando respuestas o con lecturas en sombra, sin ejecutar dos veces los
efectos.

🗣️ **2 minutos:** Para operaciones de lectura, ejecuto ambos caminos y comparo resultados,
registrando las diferencias. Para operaciones con efectos, el camino nuevo puede calcular su
decisión sin aplicarla (modo evaluación) y compararla con la del viejo, que sí la aplica. O pruebo
en un entorno controlado con un proveedor simulado. Luego corto el tráfico gradualmente con un flag
reversible y métricas por camino.

🔬 **El detalle:** Los pagos y las reservas no se duplican para hacer una prueba: cada ejecución real
tiene consecuencias para clientes reales.

### 11. 🟡 ¿Qué contrato mínimo introducirías alrededor de un SDK de pagos?

⏱️ **30 segundos:** `PaymentGateway.authorize(operationId, amount)` con un resultado propio:
autorizado, rechazado o incierto.

🗣️ **2 minutos:** Es la operación que los casos de uso realmente necesitan. El adaptador legado
traduce el SDK: construye la llamada con la clave de idempotencia, maneja el timeout y convierte los
estados del proveedor a los resultados propios. Si el negocio usa también capturas o reembolsos, se
añaden cuando un caso de uso los necesite, con la misma semántica propia.

🔬 **El detalle:** No creo un espejo completo del proveedor: si el puerto reproduce el SDK, la
migración solo ha añadido una capa y el proveedor sigue dictando el contrato.

### 12. 🟡 ¿Cómo retiras el camino viejo sin dejar llamadas ocultas?

⏱️ **30 segundos:** Buscando todas las referencias, midiendo el tráfico real de cada camino y
eliminando el wiring anterior.

🗣️ **2 minutos:** Con el flag en el nuevo camino, compruebo con métricas que el viejo no recibe
tráfico durante un periodo significativo (incluidos procesos mensuales o raros). Busco referencias
en código y configuración, y uso una regla de imports para prohibir las clases viejas. Después borro
el código, la configuración del flag y las pruebas que solo cubrían el camino viejo.

🔬 **El detalle:** Dos caminos permanentes duplican mantenimiento, pruebas y confusión en los
incidentes. Una migración no termina cuando el nuevo camino funciona, sino cuando el viejo
desaparece.

### 13. 🟡 ¿Qué deuda deja una base de datos compartida?

⏱️ **30 segundos:** Acoplamiento de esquema, de propiedad de los datos y de despliegue entre los
módulos que la comparten.

🗣️ **2 minutos:** Aunque los imports estén limpios, si dos módulos leen y escriben las mismas
tablas, un cambio de esquema en uno puede romper al otro, no está claro quién es dueño de cada dato
y las migraciones tienen que coordinarse. Es acoplamiento real, solo que invisible en el código. Lo
documento, defino qué módulo es dueño de cada tabla y evito que otros escriban en ellas
directamente.

🔬 **El detalle:** No exige dividir la base de inmediato: separar datos es caro y arriesgado. Pero
conviene hacerlo visible y no aumentarlo mientras se decide.

### 14. 🟡 ¿Cuándo conservarías una abstracción temporal?

⏱️ **30 segundos:** Cuando, terminada la migración, sigue expresando una capacidad útil con una
razón de cambio real.

🗣️ **2 minutos:** El puerto `PaymentGateway` introducido para migrar de SDK probablemente se queda:
el proveedor puede volver a cambiar, y el caso de uso se prueba con un fake. En cambio, una interfaz
creada solo para alternar entre dos versiones de un cálculo interno puede eliminarse cuando la vieja
desaparece. La pregunta es la misma que para cualquier abstracción: qué protege hoy.

🔬 **El detalle:** Una fecha de revisión al terminar la migración evita la deuda eterna de
abstracciones que nadie recuerda por qué existen.

### 15. 🟡 ¿Qué aporta un token de provider en NestJS durante la migración?

⏱️ **30 segundos:** Permite registrar el adaptador viejo y el nuevo como providers distintos y
elegir cuál recibe el puerto en la composición.

🗣️ **2 minutos:** El caso de uso depende del token `PAYMENT_GATEWAY` y de la interfaz. En el módulo,
una factory decide, según la configuración, si ese token se resuelve con `LegacyPaymentGateway` o
con `NewPaymentGateway`. Cambiar de uno a otro es cambiar la configuración, sin tocar el caso de uso
ni los controllers, y revertir es igual de sencillo.

🔬 **El detalle:** La interfaz de TypeScript necesita ese token en tiempo de ejecución; sin él, Nest
no tiene forma de saber qué inyectar, y mucho menos de elegir entre dos implementaciones.

### 16. 🟠 Dos adapters Go coexisten durante la migración. ¿Dónde seleccionas el nuevo sin filtrar un flag al caso de uso?

⏱️ **30 segundos:** En `main` o en la función de composición que se llama al arrancar.

🗣️ **2 minutos:** La configuración dice qué adaptador usar; `main` construye el elegido y lo pasa al
caso de uso como la interfaz que este declara. El caso de uso no sabe que existen dos
implementaciones ni lee ningún flag. Si la selección debe ser dinámica (por porcentaje de tráfico),
se hace con un adaptador enrutador que implementa la misma interfaz y delega en uno u otro.

🔬 **El detalle:** No escondo la selección en una variable global, y `main` también controla el
cierre de ambos adaptadores mientras coexisten.

### 17. 🟠 El equipo propone reescribir todo antes de entregar valor. ¿Qué corte haces?

⏱️ **30 segundos:** Extraigo una operación dolorosa, mantengo el sistema desplegable en cada paso y
entrego valor desde el primero.

🗣️ **2 minutos:** Caracterizo el flujo con pruebas, creo un puerto mínimo alrededor de la capacidad,
lo implemento con el código actual, extraigo la regla a un caso de uso y migro un cliente (una ruta)
a él. Cada paso se despliega y se puede revertir. Repito con la siguiente capacidad cuando la
primera esté estable. Las reescrituras completas suelen tardar el doble, perder comportamiento no
documentado y competir con las entregas.

🔬 **El detalle:** Así reduzco el riesgo y entrego valor por paso: si el proyecto se detiene a mitad,
lo migrado ya es mejor, y no queda un sistema nuevo a medias sin usar.

### 18. 🟠 Las pruebas de caracterización muestran un bug de crédito. ¿Qué haces?

⏱️ **30 segundos:** Registro el bug y separo su corrección de la extracción.

🗣️ **2 minutos:** La prueba de caracterización fija el comportamiento actual, incluido el bug, para
que la extracción no lo cambie sin querer. Cuando la extracción termina y está estable, corrijo el
bug en un cambio aparte: escribo una prueba del comportamiento deseado (que falla), corrijo la regla
en el caso de uso y actualizo o elimino la prueba de caracterización. Si el bug es grave, puedo
corregirlo antes, pero nunca en el mismo cambio.

🔬 **El detalle:** No perpetúo el bug por accidente: la prueba de caracterización lleva un comentario
que lo señala, y hay un ticket con dueño para corregirlo.

### 19. 🟠 Ambos caminos escriben inventario para comparar resultados. ¿Qué riesgo detienes?

⏱️ **30 segundos:** Que se dupliquen las reservas o se altere el inventario real: la comparación
está produciendo efectos.

🗣️ **2 minutos:** Si ambos caminos reservan stock, cada pedido reserva dos veces y el inventario
disponible cae a la mitad. Detengo la doble escritura: el camino nuevo calcula su decisión sin
aplicarla, o escribe en una tabla de sombra que no afecta al inventario real, y comparo lecturas.
Otra opción es validar el camino nuevo en un entorno controlado con datos copiados.

🔬 **El detalle:** El tráfico en sombra no debe producir efectos secundarios: ni escrituras en datos
compartidos, ni llamadas a proveedores, ni mensajes publicados.

### 20. 🟠 Un módulo nuevo sigue importando entidades JPA del viejo. ¿Qué frontera falta?

⏱️ **30 segundos:** La de persistencia: el nuevo núcleo todavía depende del modelo ORM del sistema
legado.

🗣️ **2 minutos:** El módulo nuevo tiene carpetas limpias, pero sus casos de uso reciben y devuelven
las entidades JPA viejas, así que heredan sus anotaciones, su lazy loading y la forma de sus tablas.
Introduzco un modelo propio en el núcleo y un adaptador de persistencia que traduce entre ese modelo
y las entidades existentes. Las entidades viejas quedan confinadas al adaptador.

🔬 **El detalle:** La carpeta nueva no cambia la dirección de las dependencias. Una regla de imports
que prohíba las entidades viejas en el núcleo nuevo detecta el problema y evita que vuelva.

### 21. 🟠 El feature flag lleva dos años activo para ambos caminos. ¿Qué decides?

⏱️ **30 segundos:** Fijo una fecha de retirada y elimino el camino que ya no sirve.

🗣️ **2 minutos:** Mido cuánto tráfico usa cada camino, si divergen en resultados y qué riesgo tiene
apagar el viejo. Si el nuevo lleva tiempo estable, comunico la fecha, apago el viejo de forma
reversible durante un periodo corto y luego borro código, flag y pruebas. Si el nuevo no está listo
después de dos años, esa es la conversación: por qué no, y si vale la pena terminarlo.

🔬 **El detalle:** Un flag permanente dobla la operación y las pruebas, y cada incidente empieza con
"¿qué camino estaba activo?". Los flags de migración deben tener fecha de caducidad desde que se
crean.

### 22. 🟠 El adapter legado no distingue timeout de rechazo. ¿Cómo migras sin cobrar doble?

⏱️ **30 segundos:** Modelo la incertidumbre explícitamente antes de cambiar la política de
reintentos.

🗣️ **2 minutos:** Primero corrijo la traducción: el adaptador debe devolver `UnknownResult` ante un
timeout después de enviar, en lugar de un rechazo. Luego el caso de uso trata ese resultado dejando
el pedido pendiente. Solo entonces introduzco reintentos, con una clave de operación estable
persistida y, si el proveedor lo permite, consultando el estado antes de repetir.

🔬 **El detalle:** Tratar un timeout como rechazo lleva a que el cliente o el sistema reintente con
una operación nueva, y puede cobrar dos veces. Es la deuda más peligrosa que puede heredar un
adaptador legado.

### 23. 🟠 El monolito ya tiene tests útiles y pocos cambios. ¿Cuándo paras?

⏱️ **30 segundos:** Cuando el coste de la siguiente frontera supera el valor de los cambios que
protegería.

🗣️ **2 minutos:** Si las capacidades que cambian ya están extraídas y probadas, y el resto del
monolito es estable, tiene pruebas razonables y casi no se toca, seguir migrando es gastar esfuerzo
sin retorno. Conservo el monolito simple, con las fronteras suficientes, una regla de imports que
impida retroceder y la lista de señales que harían reabrir la migración.

🔬 **El detalle:** No hay un objetivo de cantidad de puertos. El éxito de una migración se mide en
cambios más baratos, no en porcentaje del código "hexagonalizado".

### 24. 🟠 ¿Qué evidencia usarías para afirmar que la migración mejoró el diseño?

⏱️ **30 segundos:** Menos lugares editados por cada cambio de regla, fronteras probadas y menos
incidentes en las capacidades migradas.

🗣️ **2 minutos:** Compararía antes y después: cuántos archivos toca un cambio típico de regla,
cuánto tarda la suite de pruebas del núcleo, cuántos incidentes de integración hubo con el
proveedor, cuánto costó el último cambio de SDK, y si las reglas de imports pasan. Esa evidencia
sirve tanto para justificar la inversión como para decidir dónde seguir o dónde parar.

🔬 **El detalle:** La arquitectura mejoró si reduce el riesgo y el coste reales. Un diagrama más
limpio o más carpetas no es evidencia; un cambio de proveedor que tocó un solo archivo, sí.

---

## 08 · Simulación de entrevista

### S1. 🟢 ¿Qué debe traducir un adaptador de persistencia?

⏱️ **30 segundos:** El modelo, las consultas, los errores y la semántica transaccional entre el
núcleo y el almacenamiento.

🗣️ **2 minutos:** Convierte agregados o proyecciones propias a filas y de vuelta, reconstruyendo
agregados válidos; implementa las consultas que el puerto expresa con nombres de negocio; reconoce
ausencia (devuelve vacío), conflicto (violación de unicidad o de versión) y fallos técnicos, y los
traduce a conceptos propios; y participa en la transacción de la unidad de trabajo sin abrir la
suya.

🔬 **El detalle:** No devuelve proxies lazy, entidades gestionadas ni sesiones al dominio: todo lo
que cruza el puerto debe funcionar igual con la sesión cerrada.

### S2. 🟢 ¿Qué expresa un cliente externo detrás de un puerto?

⏱️ **30 segundos:** La capacidad que el negocio necesita del sistema externo, no el protocolo ni el
modelo del proveedor.

🗣️ **2 minutos:** `PaymentGateway` expresa "autoriza este importe con esta clave" y oculta endpoint,
SDK, códigos, autenticación y formato. El caso de uso `AuthorizePayment` lo consume sin saber quién
está detrás. El adaptador conserva todo lo técnico: timeouts, reintentos, credenciales, mapeo de
estados y de dinero. Cambiar de proveedor es escribir otro adaptador.

🔬 **El detalle:** El puerto incluye solo resultados que el caso de uso puede decidir —autorizado,
rechazado, incierto, no disponible—, no los veinte estados del proveedor.

### S3. 🟢 ¿Qué problema resuelve una outbox?

⏱️ **30 segundos:** Evita perder una publicación después de confirmar un cambio local, cerrando la
doble escritura entre base y broker.

🗣️ **2 minutos:** El estado y el evento de integración se guardan juntos, en la misma transacción
local; un dispatcher lee después los pendientes y los entrega al broker con reintento, marcándolos
cuando el broker confirma. Si el proceso cae después del commit, la fila sobrevive y se publicará.
Así nunca hay un pedido confirmado sin su evento, ni un evento de algo que se revirtió.

🔬 **El detalle:** No elimina los duplicados ni hace atómico al broker: el dispatcher puede publicar
dos veces, y los consumidores deben ser idempotentes.

### S4. 🟢 ¿Qué pertenece al composition root?

⏱️ **30 segundos:** La construcción, la configuración y el ciclo de vida del grafo de objetos.

🗣️ **2 minutos:** Allí se validan las opciones de despliegue, se crean los recursos compartidos, se
elige qué implementación satisface cada puerto (repositorios, clientes, reloj), se construyen los
casos de uso y se entregan a los drivers (controllers, consumidores, jobs). También se define el
orden de arranque y de cierre. El núcleo no busca nada en el contenedor: recibe lo que necesita por
constructor.

🔬 **El detalle:** Puede haber más de un composition root por proceso o por modo de ejecución: el
mismo jar puede componerse como servidor HTTP o como CLI de lotes, con grafos distintos.

### S5. 🟢 ¿Dónde se aplican timeout y retry técnicos?

⏱️ **30 segundos:** Alrededor de la llamada externa: en el adaptador o en un decorador del
adaptador.

🗣️ **2 minutos:** El adaptador conoce el destino, su latencia normal, qué errores son transitorios y
si la operación es idempotente: es quien puede decidir timeouts y reintentos con criterio. La
política de negocio recibe el resultado ya clasificado —disponible, no disponible, incierto— y
decide qué hacer con el pedido, sin configurar milisegundos ni conocer librerías de resiliencia.

🔬 **El detalle:** El presupuesto total debe limitar los reintentos anidados: si el gateway, el SDK y
el adaptador reintentan cada uno, los intentos se multiplican.

### S6. 🟢 ¿Qué prueba necesita un adaptador JPA o SQL?

⏱️ **30 segundos:** Una prueba de integración contra el motor real, que ejercite mapeo, consultas,
restricciones y transacciones.

🗣️ **2 minutos:** Guardar y recargar con la sesión cerrada, comprobar que el estado reconstruido es
idéntico (incluida la versión), que una restricción única se traduce al error propio, que el control
optimista detecta conflictos, que un listado no dispara N+1 y que las escrituras participan de la
transacción. Un mock del repositorio del framework no cubre nada de eso.

🔬 **El detalle:** Testcontainers es una opción cómoda para tener el motor real en CI, no un
objetivo: lo que importa es que la prueba corra contra la misma familia de base que producción.

### S7. 🟢 ¿Qué es una prueba de contrato para un puerto?

⏱️ **30 segundos:** Una suite común de expectativas que toda implementación del puerto debe cumplir.

🗣️ **2 minutos:** Para `Orders`: guardar y leer devuelve lo mismo, buscar lo inexistente devuelve
vacío, una versión obsoleta produce conflicto. Para `PaymentGateway`: cada tipo de respuesta produce
el resultado propio correcto. El fake, el adaptador contra la base real o contra el sandbox del
proveedor ejecutan la misma suite. Si todos pasan, el fake es fiel y las pruebas de caso de uso son
confiables.

🔬 **El detalle:** No demuestra por sí sola rendimiento, comportamiento bajo carga ni todos los
fallos del entorno real; demuestra equivalencia semántica en lo que el núcleo usa.

### S8. 🟡 ¿Cuándo separar modelo de dominio y modelo ORM?

⏱️ **30 segundos:** Cuando el ciclo de vida, el esquema o la evolución del ORM distorsionan las
invariantes del dominio.

🗣️ **2 minutos:** Si el ORM obliga a constructores vacíos y setters que permiten estados inválidos,
si el lazy loading hace que las reglas dependan de la sesión, o si el esquema cambia por razones de
almacenamiento que no deberían tocar las reglas, la separación compensa. El mapper cuesta código y
pruebas, pero impide que anotaciones, carga diferida y nulabilidad externas entren al núcleo.

🔬 **El detalle:** En un CRUD estable puede aceptarse un solo modelo, con la deuda explícita y una
señal de revisión (la primera regla que dependa del estado).

### S9. 🟡 ¿Cómo tratas un timeout de pago?

⏱️ **30 segundos:** Como un resultado incierto, salvo evidencia de que el proveedor no llegó a
procesar la petición.

🗣️ **2 minutos:** El adaptador devuelve `UnknownResult`, el caso de uso deja el pedido pendiente, y
un proceso lo resuelve: consulta el estado al proveedor con la clave de operación, o reintenta con
la misma clave si el proveedor garantiza idempotencia, con un número acotado de intentos. No
convierto el timeout en rechazo (podría haber cobrado) ni repito a ciegas con otra clave (podría
cobrar dos veces).

🔬 **El detalle:** La métrica de pagos inciertos y la correlación de cada operación permiten
reconciliar, y una alerta sobre pedidos pendientes demasiado tiempo evita que la incertidumbre se
vuelva permanente.

### S10. 🟡 ¿Por qué un fallback no debe inventar éxito?

⏱️ **30 segundos:** Porque oculta una decisión de negocio que no ocurrió y afirma algo falso al
cliente y al sistema.

🗣️ **2 minutos:** Un fallback que devuelve "pago aprobado" cuando el proveedor cae entrega sin
cobrar; uno que devuelve "stock disponible" cuando el inventario no responde vende lo que no hay.
Una caché o un proveedor alterno solo valen si el contrato define su frescura y su equivalencia (un
catálogo de hace cinco minutos puede ser aceptable). Si no hay alternativa equivalente, devuelvo una
degradación honesta: pendiente, no disponible.

🔬 **El detalle:** La resiliencia conserva la semántica, no solo la disponibilidad. Un sistema que
siempre responde pero a veces miente es peor que uno que a veces dice "ahora no puedo".

### S11. 🟡 ¿Cómo ordenas eventos publicados por outbox?

⏱️ **30 segundos:** Solo donde el negocio lo necesita, normalmente por agregado, usando su id como
clave.

🗣️ **2 minutos:** Cada evento lleva la versión del agregado; el dispatcher publica las filas de un
mismo pedido en orden y con `orderId` como clave de partición, para que el broker las mantenga en
orden. Varios workers del dispatcher se reparten el trabajo por pedido, no por fila, para no
adelantar versiones. No prometo orden global: es caro y casi nunca necesario.

🔬 **El detalle:** Los consumidores deben rechazar o tolerar eventos obsoletos comparando versiones,
porque reintentos y reprocesos pueden alterar el orden incluso con todo bien configurado.

### S12. 🟡 ¿Qué lifecycle merece un cliente HTTP?

⏱️ **30 segundos:** Uno que viva lo que vive la aplicación, reutilizando su pool de conexiones, y
que se cierre al terminar el proceso.

🗣️ **2 minutos:** El composition root lo crea una vez con su configuración (timeouts, límites de
conexiones, TLS) y lo entrega al adaptador. Crearlo por petición destruye la reutilización de
conexiones, añade latencia de conexión y negociación TLS, y bajo carga puede agotar puertos. Al
detener la aplicación, el composition root lo cierra después de que terminen las peticiones en
curso.

🔬 **El detalle:** Las credenciales rotables pueden requerir un proveedor de credenciales que el
cliente consulte, no reconstruir el cliente completo cada vez que cambian.

### S13. 🟡 ¿Qué observabilidad agregas a un puerto externo?

⏱️ **30 segundos:** Latencia, resultado semántico, timeouts, reintentos y correlación, sin secretos
ni datos sensibles.

🗣️ **2 minutos:** El adaptador conoce el endpoint y el proveedor: mide la latencia de cada llamada,
cuenta resultados por tipo (autorizado, rechazado, incierto, no disponible), registra reintentos y
estado del circuit breaker, y propaga la correlación en la llamada saliente. El caso de uso puede
medir el resultado de negocio (pedidos pagados). Las etiquetas de las métricas tienen cardinalidad
acotada.

🔬 **El detalle:** Los logs guardan la causa concreta de cada fallo, con la correlación; las métricas
agregan la tendencia. Ninguna de las dos incluye tokens ni el payload completo.

### S14. 🟡 ¿Qué detecta un test arquitectónico y qué no?

⏱️ **30 segundos:** Detecta dependencias de código prohibidas; no juzga si un límite de negocio es
bueno.

🗣️ **2 minutos:** Las reglas sobre imports impiden que el dominio conozca el framework web o el ORM,
que la aplicación dependa de la infraestructura o que dos adaptadores se acoplen. Pero no ven si un
módulo mezcla capacidades que deberían estar separadas, si un caso de uso es demasiado grande o si
los datos que cruzan un puerto son en realidad filas disfrazadas. Eso lo validan las pruebas de
comportamiento y la revisión.

🔬 **El detalle:** Un paquete bien nombrado y con imports impecables puede seguir siendo un god
module. La regla arquitectónica es necesaria, no suficiente.

### S15. 🟡 ¿Cómo migras un acceso directo a base sin reescribir todo?

⏱️ **30 segundos:** Envolviendo una capacidad dolorosa detrás de una costura y caracterizando su
comportamiento antes de moverla.

🗣️ **2 minutos:** Escribo pruebas de caracterización del flujo, creo un puerto mínimo con lo que ese
flujo necesita e implemento un adaptador que llama temporalmente al código viejo. Después extraigo
el modelo y las reglas a un caso de uso, y migro los clientes al puerto uno por uno. Avanzo por
flujos verticales, no por capas completas: cada paso deja el sistema funcionando.

🔬 **El detalle:** *Branch by abstraction* permite que la implementación vieja y la nueva coexistan
detrás del mismo puerto, con la retirada del camino viejo planificada desde el principio.

### S16. 🟡 ¿Dónde traduces un error gRPC o HTTP externo?

⏱️ **30 segundos:** En el adaptador del cliente, a resultados o errores propios del núcleo.

🗣️ **2 minutos:** Status HTTP, códigos gRPC, trailers y payloads de error quedan en el adaptador,
que los clasifica: `UNAVAILABLE` o `503` como no disponible, `DEADLINE_EXCEEDED` o un timeout tras
enviar como incierto, un rechazo documentado como rechazo, un `INVALID_ARGUMENT` como bug propio que
debe fallar ruidosamente. El núcleo recibe solo lo que sabe manejar.

🔬 **El detalle:** Conservo la causa técnica para el diagnóstico —código original, mensaje, latencia—
en el log con la correlación, sin que forme parte del contrato del puerto.

### S17. 🟠 La consulta necesita joins optimizados y no reconstruye un agregado. ¿Rompe hexagonal?

⏱️ **30 segundos:** No. Una proyección de lectura propia puede ser exactamente el contrato adecuado.

🗣️ **2 minutos:** Hexagonal pide que el núcleo defina el contrato y que el adaptador lo implemente;
no pide que todas las lecturas pasen por agregados. Un puerto `OrderSummaries` que devuelve una
proyección con los campos que la pantalla necesita, implementado con una consulta SQL optimizada,
respeta la dirección de dependencias y evita cargar agregados enteros para mostrar una lista. No
fuerzo el modelo de escritura en todas las consultas.

🔬 **El detalle:** La dirección importa más que simular objetos ricos. Lo que sí evito es usar esa
proyección para escribir, saltándome las invariantes del agregado.

### S18. 🟠 Un retry de infraestructura duplica un cobro. ¿Qué faltó?

⏱️ **30 segundos:** Idempotencia de la operación y una clasificación correcta de la incertidumbre.

🗣️ **2 minutos:** El reintento se hizo sin clave de idempotencia estable (o con una nueva por
intento), así que el proveedor trató cada intento como un cobro distinto. Además, el timeout se
trató como fallo reintentable sin considerar que el primer intento pudo haberse procesado. El
adaptador debe reintentar solo con la misma clave persistida y dentro del presupuesto; si no sabe el
resultado, el caso de uso modela el pedido como pendiente.

🔬 **El detalle:** Un reintento es seguro solo bajo una semántica conocida: operaciones idempotentes
por naturaleza o por clave. Reintentar operaciones con efectos sin esa garantía es apostar con el
dinero del cliente.

### S19. 🟠 El dispatcher publica dos veces el mismo evento. ¿Es un bug de outbox?

⏱️ **30 segundos:** No necesariamente: es una posibilidad normal de la entrega al menos una vez.

🗣️ **2 minutos:** Si el dispatcher cae entre publicar y marcar la fila, al reiniciar la publica otra
vez; es el precio de no perder eventos. Lo correcto es que use un identificador estable por evento,
marque el progreso después de la confirmación del broker y que los consumidores deduplican el efecto
local por ese identificador. Sí sería un bug si el identificador cambiara entre publicaciones o si
los duplicados fueran sistemáticos.

🔬 **El detalle:** Intentar exactamente una vez de extremo a extremo con mecanismos del broker suele
mover el problema de sitio, no eliminarlo; la idempotencia en el consumidor es la solución robusta.

### S20. 🟠 Un contenedor resuelve una dependencia con scope incorrecto. ¿Qué prueba lo detecta?

⏱️ **30 segundos:** Una prueba de composición o de arranque que ejerza el ciclo de vida real,
idealmente con concurrencia.

🗣️ **2 minutos:** Las pruebas unitarias del caso de uso construyen los objetos a mano y no ven
sesiones compartidas entre peticiones, clientes cerrados antes de tiempo o singletons con estado de
petición. Una prueba que arranca el grafo real, ejecuta varias peticiones concurrentes y comprueba
que no se mezclan datos, o que el recurso sigue disponible tras la primera petición, detecta el
problema.

🔬 **El detalle:** La composición también merece pruebas, aunque no contenga negocio: sus errores no
aparecen en ninguna prueba de lógica y sí en producción.

### S21. 🟡 ¿Debes crear un puerto para logs?

⏱️ **30 segundos:** Normalmente no: el logging es una preocupación técnica que puede rodear el caso
de uso desde fuera.

🗣️ **2 minutos:** Uso decoradores del caso de uso, middleware de los adaptadores de entrada e
instrumentación en los adaptadores de salida para registrar lo técnico. Una biblioteca de logging
estable puede incluso usarse en la aplicación sin mucho coste. Creo un puerto solo si el negocio
exige una auditoría durable y específica —quién hizo qué y con qué resultado, con retención y
garantías—, que es otra cosa.

🔬 **El detalle:** Auditoría y logging no son sinónimos: la auditoría es un requisito de negocio con
semántica y garantías; el logging es diagnóstico. La primera merece un puerto; el segundo, rara vez.

### S22. 🟡 ¿Una configuración tipada pertenece al dominio?

⏱️ **30 segundos:** No por ser tipada: sigue siendo un detalle de ejecución, que pertenece al borde.

🗣️ **2 minutos:** El composition root valida las variables y construye los objetos de configuración
que cada componente necesita: `PaymentConfig` para el adaptador de pagos, `DatabaseConfig` para el
pool. El dominio recibe políticas explícitas solo si son negocio —un límite de pedido, un plazo de
cancelación—, como parámetros con nombre propio, no como parte de un objeto de configuración
general.

🔬 **El detalle:** Nunca paso un objeto global de configuración por todos los anillos: se convierte
en una dependencia de todo con todo y oculta qué necesita realmente cada pieza.

### S23. 🟠 ¿Qué haces si un contract test obliga a todos los adapters a copiar una limitación antigua?

⏱️ **30 segundos:** Reviso si esa limitación pertenece de verdad al puerto o solo a la
implementación original.

🗣️ **2 minutos:** Si la suite de contrato exige, por ejemplo, que los importes tengan como máximo
dos decimales porque el primer proveedor lo imponía, y el negocio necesita tres para otra moneda, el
contrato está codificando un detalle. Lo evoluciono desde las necesidades de los consumidores del
puerto, versionando si hace falta, y dejo la limitación como validación del adaptador que la tiene.

🔬 **El detalle:** Una suite compartida también puede codificar una abstracción mala. Los tests de
contrato son valiosos precisamente porque son explícitos, y por eso se pueden revisar y corregir.

### S24. 🟠 ¿Cuándo no usarías circuit breaker?

⏱️ **30 segundos:** Cuando el fallo no es remoto ni transitorio, o cuando el volumen no justifica el
estado y la calibración que añade.

🗣️ **2 minutos:** Para una llamada ocasional a un servicio interno estable, un timeout, un límite de
concurrencia y errores explícitos suelen bastar. Un breaker añade estados, umbrales que calibrar,
métricas que mirar y un comportamiento de recuperación que también puede fallar. Lo añado cuando hay
evidencia de fallos en cascada o de un destino que se hunde bajo reintentos.

🔬 **El detalle:** No lo pongo entre el dominio y una función pura, ni alrededor de una base local
donde el problema suele ser el pool, no el destino.

### S25. 🟠 ¿Cómo pruebas una migración gradual además de contar clases nuevas?

⏱️ **30 segundos:** Comparando comportamiento, dependencias y radio de cambio antes y después.

🗣️ **2 minutos:** Las pruebas de caracterización demuestran que el comportamiento no cambió sin
querer; un contrato compartido demuestra que la implementación nueva es equivalente a la vieja; las
reglas de imports demuestran que el núcleo ya no depende de lo que dependía; y las métricas de
producción (errores, latencia, divergencias entre caminos) demuestran que funciona con tráfico real.
Retiro el camino viejo cuando esa evidencia es suficiente.

🔬 **El detalle:** El objetivo es menor riesgo, no completar un diagrama. Contar clases nuevas mide
actividad, no mejora.

### S26. 🟠 El proveedor de pagos cambia códigos, payload y semántica de timeout. ¿Dónde absorbes el cambio?

⏱️ **30 segundos:** En el adaptador y su mapeo, manteniendo un puerto orientado a la autorización.

🗣️ **2 minutos:** Actualizo el adaptador para el nuevo payload y los nuevos códigos, actualizo sus
pruebas de protocolo y de contrato, y si cambió la semántica del timeout (por ejemplo, ahora el
proveedor garantiza idempotencia por clave), ajusto la política de reintentos del adaptador. El caso
de uso solo cambia si cambió lo que puede decidir: si aparece un resultado de negocio nuevo, eso sí
es un cambio del puerto.

🔬 **El detalle:** Si el puerto copiaba al proveedor —sus códigos, su payload—, este cambio lo
atravesará entero. En ese caso, primero corrijo la abstracción y después absorbo el cambio.

### S27. 🟠 La base confirma el pedido y el proceso cae antes de publicar el evento. ¿Cómo recuperas?

⏱️ **30 segundos:** Con una outbox escrita en el mismo commit que el pedido y un dispatcher que se
reanuda al reiniciar.

🗣️ **2 minutos:** La fila del evento se guardó en la misma transacción que el pedido, así que
sobrevive a la caída. Al reiniciar, el dispatcher reclama las filas pendientes, publica con su
identificador estable y marca el progreso cuando el broker confirma. Las métricas de edad de
pendientes y de fallos alertan si el dispatcher no se recupera.

🔬 **El detalle:** Los consumidores siguen necesitando idempotencia: la recuperación puede publicar
algún evento que ya había salido justo antes de la caída.

### S28. 🟠 Migras un monolito donde controllers, SQL y reglas están mezclados. ¿Cuál es el primer corte?

⏱️ **30 segundos:** Un flujo con dolor real, cubierto primero por una prueba de caracterización.

🗣️ **2 minutos:** Elijo el flujo que más cambia o más falla (crear pedido, por ejemplo), lo
caracterizo con pruebas, extraigo la regla a un caso de uso, creo un puerto mínimo para la
persistencia y dejo un adaptador que llama al SQL viejo. El controller pasa a delegar. Después muevo
la frontera en iteraciones: otro flujo, otro adaptador, siempre con el sistema desplegable.

🔬 **El detalle:** No muevo todas las carpetas ni cambio de framework al mismo tiempo: cada cambio
simultáneo multiplica el riesgo y hace imposible saber qué rompió qué.

### S29. 🟠 Producción falla por lazy loading y todas las pruebas usan mocks. ¿Qué añades?

⏱️ **30 segundos:** Una prueba de integración de persistencia que cargue y mapee el caso real con la
sesión cerrada.

🗣️ **2 minutos:** Con la base real, cargo el agregado como lo hace el adaptador, cierro la sesión y
ejecuto la operación que falló; además cuento consultas en los listados. Si el adaptador devuelve
proxies o deja relaciones sin cargar, la prueba falla como falló producción. Después corrijo la
estrategia de carga en el adaptador. El núcleo conserva sus pruebas rápidas con fakes.

🔬 **El detalle:** El problema revela una frontera no verificada, no la falta de más mocks: ningún
mock del repositorio podía reproducir el comportamiento de la sesión.

### S30. 🟠 Gateway, SDK y adapter hacen cada uno tres reintentos. ¿Qué corriges?

⏱️ **30 segundos:** Defino un presupuesto de extremo a extremo y un solo dueño para la política de
reintentos.

🗣️ **2 minutos:** Tres capas con tres intentos cada una son hasta veintisiete llamadas por petición,
con latencia multiplicada y una carga que puede tumbar a un proveedor que solo estaba lento. Dejo
los reintentos en una sola capa (normalmente el adaptador, que conoce la idempotencia), desactivo
los de las demás, propago el deadline para que ningún intento empiece si no puede terminar y
registro cada intento.

🔬 **El detalle:** La capa más cercana al destino no debe ignorar el tiempo consumido aguas arriba:
el presupuesto es de la petición completa, no de cada salto.

---

**Siguiente:** [índice del bloque](README.md) · [Plataformas y práctica →](../05-plataformas-y-practica/README.md)
