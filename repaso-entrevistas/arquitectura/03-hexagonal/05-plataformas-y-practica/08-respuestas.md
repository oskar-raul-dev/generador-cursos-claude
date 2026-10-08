# 08 — Respuestas: Plataformas y práctica

Solucionario del bloque `05-plataformas-y-practica`. Cada enunciado está copiado literalmente de su
capítulo o de la simulación, con la numeración de su documento, y cada respuesta conserva las tres
capas: **⏱️ 30 segundos** (lo que dirías primero), **🗣️ 2 minutos** (contexto, alternativa y
coste) y **🔬 El detalle** (para estudiar, no para recitar).

> **Vigencia:** 2026-09-28.

**Salto rápido:** [01 Qué cambia entre plataformas](#01--qué-cambia-entre-plataformas) · [02 Java y Spring Boot](#02--java-y-spring-boot) · [03 Node y TypeScript](#03--node-y-typescript) · [04 Go](#04--go) · [05 Python](#05--python) · [06 Matriz de decisión y plantilla de servicio](#06--matriz-de-decisión-y-plantilla-de-servicio) · [07 Simulación](#07--simulación-de-entrevista)

---

## 01 · Qué cambia entre plataformas

### 1. 🟢 ¿Qué permanece igual al cambiar de plataforma?

⏱️ **30 segundos:** La regla: la política define los puertos y los detalles dependen hacia adentro.
Cambian los mecanismos, no quién posee el contrato.

🗣️ **2 minutos:** En Java, TypeScript, Go o Python, `CreateOrder` declara que necesita `Orders`, un
adaptador lo implementa y un punto de composición los conecta. Lo que cambia es la sintaxis del
contrato (interfaz nominal, tipo estructural, interfaz implícita, `Protocol`), el mecanismo de
composición (beans, tokens, constructores, fábricas) y cómo se maneja la transacción. Un equipo que
entiende la regla puede aplicarla en cualquiera de ellos.

🔬 **El detalle:** La equivalencia se comprueba con imports y pruebas, no con que los árboles de
carpetas se parezcan: en cada plataforma, el núcleo debe compilar y probarse sin sus adaptadores.

### 2. 🟢 ¿Para qué sirve la baseline del bloque?

⏱️ **30 segundos:** Para fijar versiones verificadas de lenguajes y frameworks sobre las que se
comprueban los ejemplos.

🗣️ **2 minutos:** El bloque fija Java 25 con Spring Boot 4.1, Node 24 con TypeScript 6, Go 1.27 y
Python 3.14, a una fecha concreta. Así los ejemplos usan APIs que existen y se comportan como se
describe, y no se mezclan recomendaciones de versiones incompatibles. La baseline es una referencia
editorial, no una recomendación de migrar sistemas estables.

🔬 **El detalle:** El soporte de la organización (versiones LTS aprobadas, librerías certificadas,
capacidad de operación) pesa más que la novedad: un servicio estable en Java 21 no está mal diseñado
por no estar en 25.

### 3. 🟢 ¿Qué diferencia hay entre contrato estático y runtime?

⏱️ **30 segundos:** El estático se comprueba antes de ejecutar, en el análisis de tipos; el de
runtime existe y se puede consultar durante la ejecución.

🗣️ **2 minutos:** Una interfaz Java existe en runtime: el contenedor puede resolver por ella y
`instanceof` funciona. Una interfaz TypeScript desaparece al compilar: solo existe para el
compilador. Un `Protocol` de Python solo lo usa el type checker. Esa diferencia decide cómo se
compone (Nest necesita tokens) y qué garantías hay sobre los datos que llegan de fuera.

🔬 **El detalle:** Los datos externos siempre requieren validación efectiva en runtime, sea cual sea
el sistema de tipos: ni Java ni TypeScript garantizan que el JSON que llega respete el tipo
declarado.

### 4. 🟢 ¿Qué cuatro mecanismos de composición compara el capítulo?

⏱️ **30 segundos:** Beans en Java/Spring, tokens en NestJS, constructores explícitos en Go y
fábricas o funciones de arranque en Python.

🗣️ **2 minutos:** Spring resuelve el grafo con beans y anotaciones; Nest, con providers
identificados por tokens; Go, con llamadas a constructores en `main`; Python, con una función
`build_app` que crea los objetos. Todos pueden conectar el mismo puerto con el mismo adaptador.
Difieren en cuánta magia hay, en cómo se ve el grafo y en qué errores aparecen al arrancar y cuáles
al ejecutar.

🔬 **El detalle:** Ninguno garantiza por sí solo la dirección de dependencias: con cualquiera se
puede inyectar un SDK directamente en el dominio.

### 5. 🟢 ¿Qué expresa el puerto `PaymentGateway` en cualquier lenguaje?

⏱️ **30 segundos:** La capacidad propia de autorizar un cobro, con resultados que el núcleo
entiende.

🗣️ **2 minutos:** `authorize(operationId, amount)` que devuelve autorizado, rechazado o incierto,
sea una interfaz Java, una interfaz TypeScript enlazada con un `Symbol`, una interfaz Go declarada
junto al consumidor o un `Protocol` Python. En los cuatro casos oculta el protocolo, el SDK y el
proveedor detrás de resultados propios, y en los cuatro el caso de uso se prueba con un doble.

🔬 **El detalle:** No copia la API externa en ningún lenguaje: un puerto que reproduce el SDK produce
el mismo acoplamiento en Java que en Go.

### 6. 🟢 ¿Qué seis ejes se comparan entre plataformas?

⏱️ **30 segundos:** Tipos, composición, transacción, contexto, pruebas y build.

🗣️ **2 minutos:** Tipos: si el contrato existe en runtime y qué se valida. Composición: contenedor,
tokens, constructores o fábricas. Transacción: proxy, callback, `sql.Tx` o context manager.
Contexto: hilo, contexto asíncrono o parámetro explícito. Pruebas: qué runner y qué recursos reales
revelan la frontera. Build: qué regla impide los imports hacia afuera. Son los mecanismos que
cambian cómo se preserva una frontera en cada ecosistema.

🔬 **El detalle:** La plataforma no decide la política ni la frontera: solo cambia el precio y la
forma de mantenerlas.

### 7. 🟡 ¿Por qué una interfaz TypeScript necesita un token en NestJS?

⏱️ **30 segundos:** Porque la interfaz se borra al compilar y el contenedor no tiene nada en runtime
con qué identificarla.

🗣️ **2 minutos:** Nest resuelve dependencias leyendo los metadatos de tipos del constructor; con una
clase funciona, pero una interfaz aparece como `Object`. Se registra un `Symbol` como token asociado
al provider concreto y se inyecta con `@Inject(TOKEN)`, manteniendo la interfaz como tipo para el
compilador. Así el caso de uso depende del contrato y la composición decide la implementación.

🔬 **El detalle:** El token pertenece a la composición, no al dominio: el caso de uso idealmente no
lleva decoradores de Nest y se construye con una `useFactory` que recibe los puertos por token.

### 8. 🟡 ¿Qué ventaja da una interfaz implícita de Go al consumidor?

⏱️ **30 segundos:** Que puede declarar solo los métodos que necesita, sin que el productor tenga que
saberlo.

🗣️ **2 minutos:** Un adaptador con diez métodos satisface automáticamente una interfaz de dos que el
caso de uso declara en su paquete: no hay `implements` ni registro. Eso hace natural que cada
consumidor defina su propio puerto mínimo, que los dobles de prueba sean pequeños y que el adaptador
no tenga que importar el paquete del núcleo para implementar su contrato.

🔬 **El detalle:** Reduce el acoplamiento a interfaces gigantes. La trampa contraria es declarar
interfaces "por si acaso" en el paquete del productor, como si fuera Java.

### 9. 🟡 ¿Qué aporta `Protocol` en Python y qué no ejecuta?

⏱️ **30 segundos:** Describe un contrato estructural que un type checker puede comprobar; no se
verifica en ejecución.

🗣️ **2 minutos:** `class Orders(Protocol): def save(self, order: Order) -> None: ...` permite que
mypy o pyright comprueben que el adaptador y los fakes tienen los métodos correctos, sin forzar
herencia. Documenta el puerto y ayuda a escribir dobles. En ejecución, Python no comprueba nada:
cualquier objeto con un método `save` sirve, o falla cuando se llama.

🔬 **El detalle:** No valida automáticamente datos ni comportamiento: para los datos externos se
necesita Pydantic u otro validador en el borde, y para el comportamiento, pruebas de contrato.

### 10. 🟡 ¿Qué diferencia hay entre proxy transaccional y `sql.Tx` explícito?

⏱️ **30 segundos:** El proxy intercepta la llamada y abre la transacción alrededor de forma
declarativa; `sql.Tx` se crea, se pasa y se confirma explícitamente en el código.

🗣️ **2 minutos:** Con `@Transactional`, la transacción se asocia al hilo y todos los repositorios la
comparten sin pasarla, pero la llamada interna al mismo objeto la esquiva y la propagación puede
sorprender. Con `sql.Tx`, todo es visible, pero cada adaptador debe usar la transacción correcta y
es fácil usar el pool por error. Ambos delimitan la mecánica, con riesgos de uso distintos.

🔬 **El detalle:** La política aún decide qué debe ser atómico: el mecanismo solo lo implementa. En
ninguno de los dos casos la transacción incluye llamadas remotas.

### 11. 🟡 ¿Por qué el runner de test no determina la calidad de la prueba?

⏱️ **30 segundos:** Porque la calidad depende del riesgo que la prueba cubre y de la frontera que
ejercita, no de la herramienta que la ejecuta.

🗣️ **2 minutos:** JUnit, Vitest, `go test` o pytest pueden ejecutar tanto una prueba superficial que
solo verifica llamadas a mocks como una integración que detecta un N+1 o una transacción partida. Lo
que importa es qué se prueba (regla, coordinación, adaptador, composición) y contra qué (fakes
fieles, base real, servidor simulado).

🔬 **El detalle:** Un mock no revela SQL por cambiar de runner. Migrar de framework de pruebas no
mejora la cobertura de fronteras; escribir las pruebas correctas, sí.

### 12. 🟡 ¿Qué regla debe comprobar el build además de compilar?

⏱️ **30 segundos:** Que el núcleo no importe detalles externos: framework web, ORM, clientes de
brokers o SDKs.

🗣️ **2 minutos:** Cada ecosistema tiene su herramienta: ArchUnit en Java, dependency-cruiser en
TypeScript, import-linter en Python, deptrac en PHP, y en Go paquetes `internal` más un test que
inspeccione imports. Con tres o cuatro reglas (el dominio no depende de nada externo, la aplicación
no depende de la infraestructura) la frontera falla en CI cuando alguien la cruza.

🔬 **El detalle:** Las carpetas solas no garantizan la dirección: el compilador acepta cualquier
import entre paquetes del mismo módulo.

### 13. 🟡 ¿Por qué no copiarías la estructura de Spring a Go?

⏱️ **30 segundos:** Porque sus mecanismos y su idioma de diseño son distintos, y copiar la forma
trae la ceremonia sin la necesidad.

🗣️ **2 minutos:** En Spring, las interfaces por servicio, los paquetes
`controller/service/repository` y el contenedor tienen sentido por los proxies, la DI y la cultura
del ecosistema. En Go, eso produce una interfaz por struct que nadie consume, paquetes por capa con
dependencias circulares y un contenedor casero. Go favorece interfaces pequeñas declaradas por el
consumidor, paquetes por capacidad y composición explícita en `main`.

🔬 **El detalle:** Copiar capas puede añadir ceremonia sin crear ninguna frontera real. Lo que se
traslada es la regla de dependencias, no la estructura de carpetas.

### 14. 🟡 ¿Cómo mantienes el mismo contrato sin usar la misma sintaxis?

⏱️ **30 segundos:** Conservando la intención, las entradas, los resultados y los errores propios,
aunque cada lenguaje los exprese a su manera.

🗣️ **2 minutos:** `PaymentGateway` en Java es una interfaz con un tipo sellado de resultados; en
TypeScript, una interfaz con una unión discriminada y un token; en Go, una interfaz de un método que
devuelve un valor y un error tipado; en Python, un `Protocol` con una unión de dataclasses. La
semántica es la misma: autorizado, rechazado, incierto. Una suite de contrato conceptualmente
idéntica verifica cada implementación.

🔬 **El detalle:** La semántica importa más que la forma. Dos implementaciones con la misma firma
pero distinto manejo del timeout no cumplen el mismo contrato.

### 15. 🟡 ¿Qué criterio usarías para escoger una versión baseline?

⏱️ **30 segundos:** Soporte (LTS), seguridad, compatibilidad con las librerías críticas y capacidad
de operación del equipo.

🗣️ **2 minutos:** Prefiero una línea estable y soportada a la versión más reciente por defecto: Java
LTS, Node LTS, versiones de Go y Python con soporte activo, y frameworks cuyas dependencias clave ya
la soporten. Compruebo que las librerías que el sistema necesita funcionan con ella, que hay parches
de seguridad previstos y que el equipo sabe operarla.

🔬 **El detalle:** La baseline se fecha y se revisa periódicamente: una baseline sin fecha se vuelve
una versión congelada sin que nadie lo decida.

### 16. 🟡 ¿Qué contexto técnico no debería convertirse en estado de dominio?

⏱️ **30 segundos:** El trace id, el request, la sesión, el contexto del framework o de la petición.

🗣️ **2 minutos:** Todos ellos sirven a la infraestructura para correlacionar, autenticar o gestionar
recursos, y cambian con la herramienta o con cada ejecución. Si entran al estado de `Order`, el
agregado depende del framework, su igualdad y su persistencia se contaminan y las pruebas tienen que
fabricarlos. Se quedan en el borde, propagados por los mecanismos de cada plataforma.

🔬 **El detalle:** El actor propio sí puede cruzar como dato normalizado en el comando: es
información que la política necesita, construida a partir del contexto técnico, no el contexto
técnico en sí.

### 17. 🟠 Un equipo migra a TypeScript y elimina validación de JSON porque tiene tipos. ¿Qué falla?

⏱️ **30 segundos:** Confundió análisis estático con validación en runtime: los tipos no inspeccionan
el JSON que llega.

🗣️ **2 minutos:** El JSON sigue siendo un dato desconocido; declarar su tipo no lo cambia. Un campo
ausente llega como `undefined`, un número como string, un campo extra se cuela, y la regla de
negocio opera sobre datos que no cumplen el tipo. Hay que restaurar la validación con un esquema o
un pipe (Zod, class-validator, JSON Schema) antes de construir el comando.

🔬 **El detalle:** Se necesita el esquema o el pipe antes del comando, no después. Y conviene que el
esquema sea la única fuente de verdad del tipo (tipos derivados del esquema), para que no diverjan.

### 18. 🟠 Un proyecto Go crea un contenedor DI para imitar Spring. ¿Qué revisarías primero?

⏱️ **30 segundos:** Si el grafo realmente justifica esa indirección, o si unas líneas en `main` lo
expresarían mejor.

🗣️ **2 minutos:** En la mayoría de servicios Go, construir los objetos con constructores en `main`
hace visibles el ownership, el orden de creación y cierre y los imports, sin magia ni errores de
resolución en runtime. Revisaría cuánto código de composición hay realmente y si el contenedor está
escondiendo dependencias o permitiendo un service locator. Si el grafo es muy grande, un generador
en tiempo de compilación puede tener sentido.

🔬 **El detalle:** Un contenedor pequeño no es malo en sí mismo; la copia ritual de otro ecosistema
sí, porque trae los costes de Spring sin sus razones.

### 19. 🟠 Python usa una sesión global para evitar pasar dependencias. ¿Qué riesgos aparecen?

⏱️ **30 segundos:** Estado compartido entre peticiones, transacciones mezcladas y un cierre de
recursos incierto.

🗣️ **2 minutos:** Una `Session` global de SQLAlchemy la usan todas las peticiones a la vez: los
objetos cargados por una aparecen en otra, un rollback de una revierte cambios de otra y nadie sabe
cuándo se cierra. Cada petición o unidad de trabajo necesita su propia sesión, con un alcance y un
dueño definidos: creada al empezar, confirmada o revertida al terminar, cerrada siempre.

🔬 **El detalle:** El código asíncrono agrava el problema: varias tareas concurrentes en el mismo
hilo comparten la sesión global de forma todavía más impredecible. `ContextVar` o dependencias con
`yield` de FastAPI son las formas idiomáticas de acotarla.

### 20. 🟠 Spring inyecta directamente el SDK de pagos en `Order`. ¿Qué no resolvió DI?

⏱️ **30 segundos:** No invirtió la dependencia: la entidad sigue dependiendo del SDK, solo que ahora
lo recibe inyectado.

🗣️ **2 minutos:** El dominio conoce los tipos, métodos y errores del proveedor; un cambio del SDK
alcanza la entidad; y probarla exige simular el SDK. Además, una entidad que hace llamadas remotas
mezcla I/O con reglas. Creo un puerto `PaymentGateway` propio, lo uso desde el caso de uso
`AuthorizePayment` (no desde la entidad) y hago que Spring inyecte un adaptador que usa el SDK.

🔬 **El detalle:** La inyección no equivale a una frontera: es un mecanismo para construir objetos, y
construye con la misma facilidad un diseño acoplado que uno limpio.

### 21. 🟠 Dos plataformas usan herramientas distintas pero el núcleo importa sus ORMs. ¿Son equivalentes arquitectónicamente?

⏱️ **30 segundos:** Sí: ambas rompen la dirección de dependencias de la misma manera, aunque cambie
la sintaxis.

🗣️ **2 minutos:** JPA en Java, Prisma en TypeScript o SQLAlchemy en Python son detalles de
persistencia. Si el núcleo los importa, el dominio depende del esquema, del ciclo de vida de
sesiones y de la biblioteca, y cambiar de persistencia toca reglas. Que una herramienta genere tipos
o que otra use anotaciones no cambia la conclusión.

🔬 **El detalle:** Hay que comparar imports, no logotipos. La pregunta útil en ambas es la misma: ¿el
núcleo compila sin la biblioteca de persistencia?

### 22. 🟠 La última versión rompe una librería crítica soportada. ¿Mantienes la baseline o actualizas?

⏱️ **30 segundos:** Mantengo una versión soportada mientras evalúo la migración, con el riesgo
documentado.

🗣️ **2 minutos:** Si la versión actual sigue teniendo soporte y parches de seguridad, no hay
urgencia: documento el riesgo, sigo las correcciones de la librería o busco alternativas, y fijo una
fecha de revisión. Si la versión actual deja de estar soportada pronto, planifico la migración de la
librería o su sustitución. Lo que no hago es actualizar y romper un componente crítico por seguir la
novedad.

🔬 **El detalle:** Baseline no significa "latest a cualquier coste": significa una versión
verificada, fechada y revisada.

### 23. 🟠 Un test de puerto pasa con fake en cuatro lenguajes y falla con PostgreSQL. ¿Qué evidencia faltó?

⏱️ **30 segundos:** Una prueba de integración del adaptador contra la base real, ejecutando el mismo
contrato.

🗣️ **2 minutos:** Los fakes demuestran que la coordinación funciona si el puerto se comporta como el
fake cree; no demuestran que el adaptador real se comporte así. PostgreSQL tiene su dialecto, sus
restricciones, sus tipos y su semántica transaccional. El test de contrato debe ejecutarse también
contra el adaptador real, en cada lenguaje, con una base de la misma familia.

🔬 **El detalle:** El contrato necesita al menos una implementación real que lo cumpla; si solo lo
cumplen los fakes, el contrato describe lo que los fakes hacen, no lo que el sistema hace.

### 24. 🟠 ¿Cómo demostrarías que una implementación es idiomática sin sacrificar la regla de dependencias?

⏱️ **30 segundos:** Usando los mecanismos nativos del ecosistema para componer, transaccionar y
probar, manteniendo los contratos hacia adentro.

🗣️ **2 minutos:** En Go: interfaces pequeñas del consumidor, composición en `main`, transacción en
el `context`, `go test`. En Python: dataclasses y `Protocol` en el núcleo, Pydantic y FastAPI en el
borde, sesión acotada. Reviso que la API se sienta natural para alguien del ecosistema, que el
ownership de recursos sea el habitual, que los imports del núcleo estén limpios y que las pruebas
usen las herramientas propias.

🔬 **El detalle:** Idiomático no significa acoplado al framework: significa usar bien el lenguaje. Un
núcleo en Python ordinario con FastAPI solo en el borde es a la vez idiomático y hexagonal.

---

## 02 · Java y Spring Boot

### 1. 🟢 ¿Dónde debe vivir `JpaOrders`?

⏱️ **30 segundos:** En infraestructura, como adaptador de salida (`infrastructure/outbound/jpa`).

🗣️ **2 minutos:** `JpaOrders` implementa el puerto `Orders` que el núcleo declara en `application`,
y conoce JPA, Spring Data, `OrderRecord` y el mapper. Es el único lugar donde conviven el modelo de
dominio y el de persistencia. La configuración lo construye y lo entrega como `Orders` a los casos
de uso, que nunca ven su nombre.

🔬 **El detalle:** El núcleo no importa su clase ni su paquete: una regla de ArchUnit que prohíba a
`domain` y `application` depender de `infrastructure` lo garantiza en el build.

### 2. 🟢 ¿Qué construye `OrdersConfiguration`?

⏱️ **30 segundos:** El grafo de adaptadores y casos de uso de la capacidad de pedidos: es su
composition root en Spring.

🗣️ **2 minutos:** Con métodos `@Bean`, crea `JpaOrders` a partir de `SpringDataOrders`, crea
`CreateOrder` con el puerto `Orders`, y `AuthorizePayment` con `Orders` y `PaymentGateway`. Enlaza
así beans concretos con los puertos del núcleo, sin que los casos de uso lleven anotaciones. Es un
archivo que se lee de arriba abajo para saber qué implementación satisface cada contrato.

🔬 **El detalle:** También decide los scopes, la configuración tipada que recibe cada adaptador y, si
hay varias implementaciones de un puerto, cuál se usa en cada entorno.

### 3. 🟢 ¿Por qué `Order` puede ser Java ordinario?

⏱️ **30 segundos:** Porque sus invariantes no necesitan Spring ni JPA: son reglas sobre su propio
estado.

🗣️ **2 minutos:** Un `Order` con constructor que valida, métodos como `confirm()` o `cancel()` y
campos privados se ejecuta y se prueba con JUnit puro, sin contexto de Spring, sin base y sin
proxies. Eso hace que las pruebas de reglas sean rápidas y que actualizar Spring o cambiar de ORM no
toque la lógica de negocio. Java moderno (records, sealed types) ayuda a expresarlo con poco código.

🔬 **El detalle:** El mapper adapta la persistencia por separado: `OrderRecord` tiene las anotaciones
que JPA necesita y `JpaOrders` traduce en ambos sentidos.

### 4. 🟢 ¿Qué hace constructor injection?

⏱️ **30 segundos:** Declara los colaboradores de un objeto en su constructor y hace que se entreguen
al construirlo.

🗣️ **2 minutos:** Con `CreateOrder(Orders orders, Clock clock)`, las dependencias quedan visibles en
la firma, pueden ser `final` e inmutables, el objeto no puede existir a medio construir y las
pruebas lo instancian con `new` y dobles. Spring la usa automáticamente cuando hay un único
constructor. Es preferible a la inyección por campo, que esconde dependencias y obliga a usar
reflexión en pruebas.

🔬 **El detalle:** No corrige un tipo de dependencia equivocado: si el constructor pide un
`JpaRepository` o un SDK, la inyección funciona perfectamente y el acoplamiento sigue ahí.

### 5. 🟢 ¿Qué papel cumple `SpringDataOrders`?

⏱️ **30 segundos:** Es la interfaz técnica de Spring Data que usa internamente el adaptador JPA.

🗣️ **2 minutos:** `interface SpringDataOrders extends JpaRepository<OrderRecord, String>` le da al
adaptador consultas derivadas, paginación y operaciones CRUD sobre `OrderRecord` sin escribir
implementación. `JpaOrders` la usa para cumplir el puerto `Orders`, traduciendo registros a
agregados. Spring Data sigue haciendo el trabajo pesado, pero dentro del borde.

🔬 **El detalle:** No es el puerto del dominio: expone decenas de métodos genéricos, trabaja con
registros de persistencia y depende de Spring. Si el núcleo la usara, heredaría todo eso.

### 6. 🟢 ¿Qué prueba una regla de ArchUnit?

⏱️ **30 segundos:** Las dependencias e imports entre paquetes o módulos del código Java.

🗣️ **2 minutos:** Reglas como "las clases de `..domain..` no dependen de `org.springframework..` ni
de `jakarta.persistence..`" o "`..application..` no depende de `..infrastructure..`" se escriben
como pruebas JUnit y fallan en el build cuando alguien las rompe. Convierten la regla de
dependencias en una restricción automática, con un mensaje que explica qué frontera se cruzó.

🔬 **El detalle:** No prueba comportamiento transaccional, ni mapeo, ni filtraciones de datos: un
núcleo puede cumplir todas las reglas y recibir mapas con columnas. Es una red de seguridad
estructural, no una prueba de corrección.

### 7. 🟡 ¿Dónde ubicarías `@Transactional` para `CreateOrder`?

⏱️ **30 segundos:** En el límite de aplicación: una fachada o un decorador que envuelva al caso de
uso completo.

🗣️ **2 minutos:** La transacción debe envolver toda la unidad local: guardar el pedido, la reserva y
la fila de la outbox. Si `CreateOrder` es una clase Java sin anotaciones, una clase de aplicación
anotada con `@Transactional` la invoca, o se usa `TransactionTemplate` en un decorador. Así los
repositorios participan en la misma transacción y el caso de uso sigue libre de Spring.

🔬 **El detalle:** Evito ponerla por repositorio: cada método confirmaría por su cuenta y la
operación quedaría partida. Si el equipo acepta la anotación directamente en el caso de uso, que sea
una decisión documentada.

### 8. 🟡 ¿Por qué una llamada interna puede evitar el proxy transaccional?

⏱️ **30 segundos:** Porque la llamada `this.otroMetodo()` no atraviesa el proxy que Spring puso
delante del bean.

🗣️ **2 minutos:** Spring aplica `@Transactional` envolviendo el bean en un proxy; la interceptación
ocurre cuando otro objeto llama al bean a través de ese proxy. Una llamada desde dentro del mismo
objeto va directa a la instancia real, sin pasar por el proxy, así que la anotación del método
llamado se ignora: su propagación, su rollback, todo.

🔬 **El detalle:** Se verifica el modo de proxy configurado (con AspectJ el comportamiento cambia) y,
sobre todo, se prueba el comportamiento: provocar un fallo y comprobar qué quedó confirmado.

### 9. 🟡 ¿Cuándo separarías `OrderRecord` de `Order`?

⏱️ **30 segundos:** Cuando la separación protege invariantes o permite que dominio y esquema
evolucionen por separado.

🗣️ **2 minutos:** Si `Order` tiene reglas relevantes que JPA compromete (constructores vacíos,
setters, colecciones lazy), si el esquema tiene relaciones o estructuras que no corresponden al
modelo de negocio, o si la API y la base evolucionan a ritmos distintos, el mapper se paga. El
taller Java lo hace así: `OrderRecord` para JPA, `Order` para el dominio.

🔬 **El detalle:** En un CRUD simple, con pocas reglas y un esquema que es el modelo, puede no
compensar. Lo importante es decidirlo, no heredarlo del tutorial.

### 10. 🟡 ¿Qué traduce el adaptador JPA además de campos?

⏱️ **30 segundos:** Identidad, versión, errores y estrategias de carga.

🗣️ **2 minutos:** Conserva el identificador del agregado; lee y escribe la versión para el control
optimista; convierte las excepciones de JPA y del driver (violación de unicidad, bloqueo optimista,
datos no encontrados) en errores propios; y decide qué relaciones cargar y cómo, para devolver un
agregado completo. Reconstruye un agregado válido sin que ningún proxy escape de la sesión.

🔬 **El detalle:** También preserva la concurrencia optimista de extremo a extremo: si la versión se
pierde en el mapeo, el control deja de funcionar sin que nada falle.

### 11. 🟡 ¿Qué prueba ejecutarías sin Spring?

⏱️ **30 segundos:** Las del dominio y las de coordinación de los casos de uso.

🗣️ **2 minutos:** Con JUnit y dobles propios basta: `Order` se prueba creando objetos y comprobando
transiciones; `CreateOrder` se construye con fakes de `Orders` y del inventario y se prueban sus
escenarios. No hace falta contexto, ni base, ni `@MockBean`. Son la mayoría de las pruebas del
sistema y deberían ejecutarse en segundos.

🔬 **El detalle:** La señal es más rápida y más precisa: si falla una prueba de dominio, el problema
está en la regla, no en la configuración de Spring.

### 12. 🟡 ¿Cuándo usarías `@SpringBootTest`?

⏱️ **30 segundos:** Para verificar la composición o un flujo integrado representativo, no para cada
regla.

🗣️ **2 minutos:** Una prueba de arranque comprueba que todos los beans se resuelven, que la
configuración es válida y que los adaptadores reales se construyen. Uno o pocos flujos completos
(petición HTTP → base real) comprueban que todo está conectado. Para probar un adaptador aislado,
los *test slices* (`@WebMvcTest`, `@DataJpaTest`) cargan solo lo necesario y son más rápidos.

🔬 **El detalle:** No lo uso para cada invariante: cargar el contexto entero para comprobar que un
pedido vacío no se confirma hace la suite lenta sin hacerla más precisa.

### 13. 🟡 ¿Qué diferencia hay entre un bean y un puerto?

⏱️ **30 segundos:** Un bean es un objeto gestionado por el contenedor de Spring; un puerto es un
contrato que define el núcleo.

🗣️ **2 minutos:** Son ejes distintos: un bean puede implementar un puerto (`JpaOrders` es un bean
que implementa `Orders`), puede ser un caso de uso (registrado como bean para inyectarlo en el
controller) o puede ser puro detalle (un `ObjectMapper`, un cliente HTTP). Ser bean dice cómo se
construye y vive un objeto; ser puerto dice qué papel cumple en la arquitectura.

🔬 **El detalle:** Registrar algo como bean no lo convierte en frontera, y un puerto no necesita que
Spring exista: en las pruebas, sus implementaciones se construyen con `new`.

### 14. 🟡 ¿Cómo evitas que el controller serialice una entidad JPA?

⏱️ **30 segundos:** Devolviendo un response DTO explícito construido desde un resultado propio del
caso de uso.

🗣️ **2 minutos:** El caso de uso devuelve `OrderCreated` o una proyección propia; el controller la
convierte en `OrderResponse` con los campos públicos y el formato del contrato. La entidad JPA nunca
sale del adaptador de persistencia, así que no puede llegar al serializador. Así se evitan campos
internos publicados, cargas lazy durante la serialización y ciclos entre relaciones.

🔬 **El detalle:** Pruebo el JSON real con una prueba del adaptador HTTP que compare las claves con
la lista permitida: la configuración de Jackson puede publicar más de lo que el DTO sugiere.

### 15. 🟡 ¿Qué coste introduce la auto-configuración?

⏱️ **30 segundos:** Comportamiento implícito, más tiempo de arranque y un grafo más difícil de
diagnosticar.

🗣️ **2 minutos:** Spring Boot crea beans según lo que encuentra en el classpath y en las
propiedades: añadir una dependencia puede activar una configuración, y una propiedad mal escrita se
ignora en silencio. Reduce mucho el wiring manual, pero exige entender sus condiciones y cómo
sobrescribirlas. En el taller Java, una propiedad renombrada en Boot 4 hizo que el servicio se
conectara a otra base sin ningún error.

🔬 **El detalle:** El coste crece con scopes ambiguos y con varias implementaciones de un mismo tipo.
Una prueba de arranque y el informe de condiciones de Boot ayudan a saber qué se configuró y por
qué.

### 16. 🟡 ¿Cómo comprobarías que el grafo real arranca?

⏱️ **30 segundos:** Con una prueba de contexto que arranque la aplicación con una configuración
válida de prueba.

🗣️ **2 minutos:** Un `@SpringBootTest` que levanta el contexto completo con adaptadores reales
(contra contenedores de base y broker) o con sustitutos controlados solo para recursos externos
inalcanzables. Debe fallar si falta un bean, si una propiedad obligatoria no está o si dos beans
compiten por el mismo tipo. Complementa, no sustituye, a las pruebas de comportamiento.

🔬 **El detalle:** Debe fallar por beans o propiedades faltantes, y para eso la configuración tipada
tiene que validar al arrancar: una propiedad ignorada en silencio no hace fallar ninguna prueba.

### 17. 🟠 `Order` importa `jakarta.persistence.Entity`. ¿Qué frontera se filtró?

⏱️ **30 segundos:** La de persistencia: JPA entró al modelo de dominio.

🗣️ **2 minutos:** El dominio ahora depende de la biblioteca de persistencia para compilar, necesita
un constructor sin argumentos y campos que JPA pueda asignar, y su forma sigue a la tabla. Las
pruebas de reglas pueden necesitar un contexto de persistencia si hay relaciones lazy. Si el coste
lo justifica, separo un `OrderRecord` con las anotaciones y un mapper en el adaptador, y dejo
`Order` como Java ordinario.

🔬 **El detalle:** La anotación no es solo metadata: condiciona la construcción del objeto (el
constructor vacío que salta invariantes) y su ciclo de vida (entidad gestionada, dirty checking).

### 18. 🟠 `@Transactional` guarda el pedido y luego falla el cobro HTTP. ¿Qué revierte realmente?

⏱️ **30 segundos:** Solo los recursos locales que coordina el transaction manager, normalmente la
base de datos.

🗣️ **2 minutos:** El rollback deshace el pedido guardado, pero no un cobro que el proveedor ya
procesó: la llamada HTTP no participa de la transacción. Si la llamada falló por timeout, el cobro
pudo ocurrir y el pedido desaparece; si tuvo éxito y después falla el commit, hay cobro sin pedido.
La solución es sacar la llamada de la transacción, con un estado pendiente explícito.

🔬 **El detalle:** Modelo la incertidumbre (pedido pendiente, resultado incierto) y la compensación
(reembolso si el pedido no puede completarse), en lugar de confiar en que el rollback lo arregle
todo.

### 19. 🟠 Un método transaccional se invoca desde otro método del mismo bean. ¿Qué verificas?

⏱️ **30 segundos:** Si la llamada atraviesa el proxy; con el modo por defecto, no lo hace.

🗣️ **2 minutos:** La self-invocation omite el interceptor, así que la anotación del método llamado
no se aplica: si esperaba una transacción nueva (`REQUIRES_NEW`), no la hay; si no había transacción
externa, no hay ninguna. Lo compruebo con una prueba que provoque un fallo y mire qué quedó
confirmado. Después refactorizo el límite: el método va a otro bean, o uso `TransactionTemplate` de
forma programática.

🔬 **El detalle:** Si dos métodos del mismo objeto necesitan transacciones distintas, probablemente
son responsabilidades distintas; moverlos a beans separados suele mejorar también el diseño.

### 20. 🟠 Un equipo extiende `JpaRepository` desde aplicación. ¿Qué contrato propones?

⏱️ **30 segundos:** Un puerto pequeño, nombrado por la necesidad de los casos de uso, implementado
por un adaptador que usa Spring Data dentro.

🗣️ **2 minutos:** `Orders` con `find(OrderId)` y `save(Order)`, y quizá `pendingFor(CustomerId)` si
un caso de uso lo necesita, en lugar de toda la API de JPA. El adaptador `JpaOrders` implementa ese
puerto usando un `SpringDataOrders extends JpaRepository<OrderRecord, String>`. La aplicación deja
de depender de Spring Data y de las entidades gestionadas; Spring Data sigue ahorrando código en el
adaptador.

🔬 **El detalle:** Spring Data queda detrás del adaptador, y el puerto crece método a método cuando
un caso de uso lo pide, no por lo que el repositorio genérico ofrece.

### 21. 🟠 Todos los tests usan mocks de JPA y producción falla por lazy loading. ¿Qué prueba falta?

⏱️ **30 segundos:** Una prueba de integración de JPA con sesión y base reales.

🗣️ **2 minutos:** Con `@DataJpaTest` o un contexto contra una base en contenedor, guardo un pedido
con líneas, cierro la sesión (o limpio el contexto de persistencia), lo recargo por el adaptador y
ejecuto la regla que falló en producción. Si el adaptador devuelve colecciones lazy sin inicializar,
la prueba falla igual que producción. Después corrijo la estrategia de carga en el adaptador.

🔬 **El detalle:** También cuento consultas en los listados: el mismo problema de carga suele venir
acompañado de un N+1 que los mocks tampoco podían ver.

### 22. 🟠 El contexto tarda minutos porque cada regla usa `@SpringBootTest`. ¿Cómo redistribuyes las pruebas?

⏱️ **30 segundos:** Paso las reglas a pruebas puras y dejo integraciones focalizadas para los
adaptadores y pocos flujos completos.

🗣️ **2 minutos:** Las invariantes del dominio y la coordinación de los casos de uso se prueban con
JUnit y fakes, en milisegundos. Los adaptadores se prueban con *slices*: `@WebMvcTest` para HTTP,
`@DataJpaTest` para persistencia. Unos pocos `@SpringBootTest` cubren el arranque y los flujos
críticos de extremo a extremo. La suite pasa de minutos a segundos y los fallos señalan la capa
correcta.

🔬 **El detalle:** Cada prueba paga solo la infraestructura que necesita. Y si varias pruebas de
contexto completo comparten configuración, Spring reutiliza el contexto en caché; configuraciones
distintas lo obligan a recrearlo.

### 23. 🟠 Dos beans implementan `PaymentGateway` y el arranque es ambiguo. ¿Dónde resuelves la selección?

⏱️ **30 segundos:** En la configuración del composition root, de forma explícita.

🗣️ **2 minutos:** Defino un único bean `PaymentGateway` en la configuración que elige la
implementación según una propiedad (`hex.payment.provider=deterministic|grpc`), o uso
`@ConditionalOnProperty` para que solo exista el que corresponde, o un `@Qualifier` si ambos deben
coexistir. Así el arranque es determinista y la decisión está en un lugar visible.

🔬 **El detalle:** El caso de uso no elige proveedor: recibe un `PaymentGateway` y no sabe cuál es.
Si la selección fuera dinámica por petición, sería un adaptador enrutador que implementa el puerto,
no lógica en el caso de uso.

### 24. 🟠 ¿Cuándo aceptarías anotaciones Spring en la capa de aplicación?

⏱️ **30 segundos:** Cuando el beneficio supera el acoplamiento y la decisión está declarada.

🗣️ **2 minutos:** Un `@Transactional` en una fachada de aplicación es pragmático: es estable, ahorra
código y deja el dominio limpio. Incluso un `@Service` en el caso de uso puede aceptarse en un
equipo que prefiere escaneo a configuración explícita. Lo que reviso es si esas anotaciones hacen
que las pruebas necesiten Spring o si atan la lógica a comportamientos del framework (proxies,
propagación) que el equipo no controla.

🔬 **El detalle:** Reviso la portabilidad y las pruebas, no aplico un absoluto. La línea que no
cruzaría es el dominio: ahí las anotaciones de framework condicionan reglas.

---

## 03 · Node y TypeScript

### 1. 🟢 ¿Qué ocurre con una `interface` TypeScript en runtime?

⏱️ **30 segundos:** Desaparece: se borra al compilar a JavaScript y no deja ningún rastro
ejecutable.

🗣️ **2 minutos:** La interfaz existe solo para el compilador: comprueba que el código que la usa y
el que la implementa encajan. En ejecución no hay nada con qué identificar un provider (por eso Nest
necesita tokens), ni con qué comprobar que un objeto la cumple (no hay `instanceof` de una
interfaz), ni con qué validar un JSON. Es una herramienta de diseño y de análisis, no un contrato en
runtime.

🔬 **El detalle:** Hace falta un token para la composición y validación en runtime para los datos
externos, según la frontera. Confundir ambas funciones es la trampa típica de TypeScript.

### 2. 🟢 ¿Qué hace un pipe o schema de entrada?

⏱️ **30 segundos:** Valida y, si procede, transforma los datos externos en runtime, antes de que
lleguen al caso de uso.

🗣️ **2 minutos:** Un `ValidationPipe` con class-validator, un esquema Zod o un JSON Schema en
Fastify inspecciona el cuerpo real: tipos, obligatorios, formatos, rangos, campos extra. Si algo no
cumple, rechaza con un `400` y la lista de errores; si cumple, entrega un objeto con la forma
declarada. A partir de ahí el adaptador construye el comando con confianza.

🔬 **El detalle:** No sustituye las invariantes del dominio: el esquema sabe si la cantidad es un
entero positivo, no si hay stock suficiente.

### 3. 🟢 ¿Para qué sirve un token de provider?

⏱️ **30 segundos:** Para identificar una dependencia en el contenedor de NestJS cuando no hay una
clase en runtime que lo haga.

🗣️ **2 minutos:** Un token (`Symbol('ORDERS')`) enlaza un contrato que el compilador borra —la
interfaz `Orders`— con una implementación concreta registrada en el módulo (`{ provide: ORDERS,
useClass: PrismaOrders }`). El consumidor lo pide con `@Inject(ORDERS)`. Así el caso de uso puede
depender del contrato y la composición decide la implementación, igual que en Java con interfaces.

🔬 **El detalle:** Un `Symbol` evita colisiones de nombres que podrían aparecer con tokens de tipo
cadena en aplicaciones grandes con varios módulos.

### 4. 🟢 ¿Qué debe recibir `CreateOrder` en vez de `Request`?

⏱️ **30 segundos:** Un comando propio con los datos ya validados y tipos del núcleo.

🗣️ **2 minutos:** `CreateOrderCommand` con el actor verificado, las líneas y la clave de operación.
El adaptador HTTP conserva todo lo del transporte: headers, parámetros, status, el objeto `Request`
de Express o Fastify y los decoradores de Nest. El caso de uso no sabe que existe HTTP y puede
probarse con una llamada directa.

🔬 **El detalle:** El mismo comando sirve a una cola o a una CLI: cada adaptador lo construye desde
su formato y el caso de uso no cambia.

### 5. 🟢 ¿Qué significa que una promesa tenga dueño?

⏱️ **30 segundos:** Que algún código espera su resultado, trata su error y, si hace falta, la
cancela.

🗣️ **2 minutos:** Una promesa lanzada sin `await` ni `.catch` es trabajo huérfano: si falla, el
error se pierde o tumba el proceso como rechazo no manejado; si tarda, puede seguir ejecutándose
después de que la petición respondió o de que el proceso empezó a cerrarse. Que tenga dueño
significa que su ciclo de vida está dentro del de algo más: la petición, la unidad de trabajo, el
worker.

🔬 **El detalle:** El *fire-and-forget* legítimo requiere una cola o un ciclo de vida explícito (un
worker con cierre ordenado), no una promesa suelta.

### 6. 🟢 ¿Para qué sirve `AbortSignal`?

⏱️ **30 segundos:** Para propagar la cancelación a las operaciones que la soportan, como `fetch`.

🗣️ **2 minutos:** El adaptador crea una señal con `AbortSignal.timeout(ms)` o la combina con la de
la petición entrante, y la pasa a la llamada remota. Si el presupuesto se agota o el cliente se
desconecta, la llamada se aborta y libera recursos, en lugar de seguir esperando una respuesta que
nadie usará. Es el equivalente en Node del `context` de Go.

🔬 **El detalle:** No revierte un efecto remoto ya procesado: si el proveedor cobró antes de que se
abortara la espera, el cobro existe. Por eso un aborto tras enviar es un resultado incierto.

### 7. 🟡 ¿Por qué `as CreateOrderDto` no valida JSON?

⏱️ **30 segundos:** Porque solo cambia lo que cree el compilador sobre el valor, no el valor.

🗣️ **2 minutos:** Un *type assertion* le dice a TypeScript "confía en mí, esto es un
`CreateOrderDto`". El objeto en ejecución conserva exactamente lo que llegó: campos ausentes como
`undefined`, números como strings, campos extra. El compilador deja de avisar, pero el problema
aparece después, en una regla de negocio, lejos de su causa.

🔬 **El detalle:** Hay que usar un esquema, un pipe o un parser real que inspeccione el valor y falle
si no cumple. Idealmente, el tipo se deriva del esquema para que ambos no puedan divergir.

### 8. 🟡 ¿Cuándo usarías un `Symbol` como token?

⏱️ **30 segundos:** Para inyectar un puerto que no tiene clase en runtime: una interfaz o un tipo.

🗣️ **2 minutos:** El módulo registra el `Symbol` con una clase concreta (`useClass`) o una fábrica
(`useFactory`), y los consumidores lo inyectan con `@Inject`. Es la forma de que los casos de uso
dependan de contratos y no de implementaciones en Nest. Si el caso de uso es una clase sin
decoradores, una `useFactory` con `inject: [ORDERS]` lo construye con sus puertos.

🔬 **El detalle:** El token se define y exporta desde la composición, no desde el dominio, si puede
evitarse: así el núcleo no conoce ni siquiera el mecanismo de inyección.

### 9. 🟡 ¿Qué diferencia hay entre módulo NestJS y límite arquitectónico?

⏱️ **30 segundos:** El módulo organiza providers para el contenedor; el límite arquitectónico
controla qué puede depender de qué.

🗣️ **2 minutos:** Un `@Module` agrupa controllers y providers y declara qué exporta a otros módulos.
Pero dentro de un módulo, el "dominio" puede importar Prisma, y el módulo sigue compilando y
funcionando. Tampoco un módulo por *feature* equivale a una frontera de negocio: puede mezclar
capacidades o partir una. El límite arquitectónico se expresa en contratos e imports, y se verifica
con dependency-cruiser.

🔬 **El detalle:** Hay que revisar contratos e imports, no solo decoradores. Llamar hexagonal a un
proyecto porque tiene módulos es el mismo error que llamarlo así porque tiene carpetas.

### 10. 🟡 ¿Cuándo preferirías `buildApp(deps)` a un contenedor?

⏱️ **30 segundos:** Cuando el grafo es pequeño y una composición explícita basta para entenderlo.

🗣️ **2 minutos:** Una función que recibe las dependencias, construye los adaptadores y los casos de
uso y devuelve la aplicación es habitual en Fastify, en workers y en servicios simples. Se lee de
arriba abajo, no hay metadatos ni decoradores, los errores aparecen al compilar y las pruebas llaman
a la misma función con dobles. El ownership de cada recurso queda claro.

🔬 **El detalle:** Facilita el ownership y las pruebas sin metadata. Un contenedor compensa cuando el
grafo es grande o cuando se aprovecha el ecosistema del framework (guards, interceptores, módulos de
integración).

### 11. 🟡 ¿Por qué no usarías `AsyncLocalStorage` como fuente de autorización?

⏱️ **30 segundos:** Porque ocultaría un dato que afecta a la política y haría que la autorización
dependiera de un contexto implícito.

🗣️ **2 minutos:** Si el caso de uso lee el actor de `AsyncLocalStorage`, cualquier flujo que no lo
establezca —un job, un consumidor, una prueba, una promesa lanzada fuera del contexto— ejecuta la
regla sin actor o con uno equivocado. La firma del caso de uso tampoco dice que la decisión depende
de quién opera. El actor confiable debe llegar explícito en el comando.

🔬 **El detalle:** `AsyncLocalStorage` sí sirve para la correlación técnica (logs, trazas) y para
compartir la transacción dentro de una unidad de trabajo: datos que no cambian una decisión de
negocio.

### 12. 🟡 ¿Cómo mantienes una transacción Prisma entre dos adapters?

⏱️ **30 segundos:** Haciendo que ambos operen con el mismo cliente transaccional durante el callback
de la transacción.

🗣️ **2 minutos:** Una unidad de trabajo llama a `prisma.$transaction(async (tx) => ...)` y hace
disponible ese `tx` a los adaptadores: por parámetro, o guardándolo en `AsyncLocalStorage` y
haciendo que cada adaptador lo recupere (o use el cliente raíz si no hay transacción en curso). Así
`PrismaOrders` y `PrismaInventory` escriben en la misma transacción y confirman juntos.

🔬 **El detalle:** Usar el cliente raíz dentro del callback rompe la atomicidad: esa operación se
ejecuta en otra conexión y confirma por su cuenta, sin ningún error visible.

### 13. 🟡 ¿Qué error externo debe traducir el adapter?

⏱️ **30 segundos:** Todo error que cruce su frontera técnica: los de la biblioteca, el driver, el
protocolo o el proveedor.

🗣️ **2 minutos:** Un `PrismaClientKnownRequestError` con código `P2002` (violación de unicidad) se
convierte en un conflicto propio; un timeout de conexión, en un fallo técnico o transitorio; un
`404` del proveedor, en "no encontrado" si tiene sentido de negocio. El caso de uso recibe semántica
propia y decide; el controller solo traduce aplicación a HTTP.

🔬 **El detalle:** Conserva la causa original, encadenada o registrada, para el diagnóstico: la
traducción cambia el tipo, no borra la información.

### 14. 🟡 ¿Qué prueba haces sin levantar NestJS?

⏱️ **30 segundos:** Las del dominio y las de los casos de uso con dobles pequeños.

🗣️ **2 minutos:** Si el dominio y los casos de uso son clases TypeScript ordinarias sin decoradores,
se prueban con `node:test`, Vitest o el runner elegido, construyéndolos con `new` y fakes propios.
Son rápidas, no dependen del contenedor ni de la reflexión de metadatos y cubren la mayor parte de
la lógica. El contenedor de Nest y el adaptador HTTP se prueban por separado, con un módulo de
pruebas.

🔬 **El detalle:** Si una prueba de caso de uso necesita `Test.createTestingModule`, el caso de uso
depende de Nest más de lo necesario.

### 15. 🟡 ¿Qué comprueba `fastify.inject()`?

⏱️ **30 segundos:** El adaptador HTTP completo sin abrir un puerto de red real.

🗣️ **2 minutos:** `inject` simula una petición contra la aplicación ya construida y ejecuta el
routing, la validación de esquema, los hooks, el handler y la serialización de la respuesta,
devolviendo status, headers y cuerpo. Con dobles de los casos de uso, prueba exactamente la
traducción HTTP: que el JSON correcto produce el comando esperado y que cada error se representa
según el contrato.

🔬 **El detalle:** El adaptador de base de datos aún requiere su propia prueba de integración:
`inject` ejercita HTTP, no la persistencia.

### 16. 🟡 ¿Qué coste debes evaluar al elegir ESM o CommonJS?

⏱️ **30 segundos:** Compatibilidad de paquetes, configuración del build, del runner de pruebas y del
despliegue.

🗣️ **2 minutos:** Algunos paquetes solo publican ESM, otros solo CommonJS; mezclar ambos requiere
configuración y a veces trucos. El compilador, el runner de pruebas y las herramientas de análisis
de dependencias deben entender el mismo sistema de módulos, y el artefacto desplegado debe arrancar
igual que en local. Es un coste operativo real, que afecta a cada dependencia nueva.

🔬 **El detalle:** La elección afecta a imports y tooling, no a la política. Se prueba el artefacto
ejecutable real (compilar y arrancar), no solo el código en el editor.

### 17. 🟠 El body está tipado pero llega `customerId: null`. ¿Dónde falló la frontera?

⏱️ **30 segundos:** Faltó validación en runtime en el adaptador de entrada: el tipo estático nunca
inspeccionó el JSON.

🗣️ **2 minutos:** El controller declaró el cuerpo como `CreateOrderDto` y confió en el tipo; el JSON
con `null` pasó sin error hasta el caso de uso. Añado un esquema o un pipe que exija `customerId`
como string no vacío (o, mejor, lo tome del token y no del cuerpo) y rechace con `400` lo que no
cumpla. Una prueba del adaptador con ese cuerpo lo confirma.

🔬 **El detalle:** El dominio mantiene su invariante igualmente: un pedido sin cliente debe fallar al
construirse, aunque el borde se haya equivocado. Dos defensas, dos responsabilidades.

### 18. 🟠 NestJS no puede resolver una interfaz inyectada. ¿Qué agregas y dónde?

⏱️ **30 segundos:** Un token de tiempo de ejecución y su provider en el módulo que compone la
capacidad.

🗣️ **2 minutos:** Defino `export const ORDERS = Symbol('ORDERS')` junto a la composición, registro
`{ provide: ORDERS, useClass: PrismaOrders }` en el módulo y construyo el caso de uso con una
`useFactory` que recibe la implementación bajo ese token (`inject: [ORDERS]`), o inyecto con
`@Inject(ORDERS)` si el consumidor es un provider de Nest. El tipo `Orders` sigue siendo la interfaz
para el compilador.

🔬 **El detalle:** La interfaz sola no existe en el contenedor, y el error aparece al arrancar, no al
compilar: una prueba de arranque del módulo lo detecta antes del despliegue.

### 19. 🟠 El caso de uso llama Prisma con el cliente raíz dentro de un callback transaccional. ¿Qué riesgo hay?

⏱️ **30 segundos:** Que esa operación queda fuera de la transacción: se ejecuta en otra conexión y
confirma por su cuenta.

🗣️ **2 minutos:** Si la transacción después se revierte, esa escritura sigue confirmada; si es una
lectura, no ve los cambios aún no confirmados del `tx`, y puede decidir con un estado distinto.
Además, el caso de uso ya no debería conocer Prisma. Inyecto adaptadores que obtienen el cliente
transaccional de la unidad de trabajo, y el caso de uso solo ve puertos.

🔬 **El detalle:** Este error no produce ningún fallo inmediato: se manifiesta como inconsistencias
bajo fallos. Una prueba que provoque un error a mitad de la transacción y compruebe que no quedó
nada lo detecta.

### 20. 🟠 Un handler responde y deja `publish()` sin `await`. ¿Qué puede ocurrir?

⏱️ **30 segundos:** Que la publicación falle o se pierda sin que nadie lo observe.

🗣️ **2 minutos:** Si `publish()` falla, el rechazo queda sin manejar: se pierde o tumba el proceso.
Si el proceso se reinicia o cierra antes de que la promesa termine, el evento nunca sale. Y el
cliente ya recibió una respuesta de éxito. Como mínimo, hay que esperar la publicación y manejar su
error; pero eso sigue sin ser atómico con la base.

🔬 **El detalle:** Para una entrega durable uso una outbox: el handler solo registra el evento
pendiente en la misma transacción, y un dispatcher con ciclo de vida propio lo publica y espera la
confirmación.

### 21. 🟠 Un error `PrismaClientKnownRequestError` llega al controller. ¿Qué cambias?

⏱️ **30 segundos:** Lo traduzco dentro del adaptador de persistencia, antes de que salga del borde
de salida.

🗣️ **2 minutos:** El adaptador reconoce el código del error (`P2002` para unicidad, `P2025` para
registro no encontrado) y lo convierte en un error propio: conflicto, no encontrado o fallo técnico.
El caso de uso recibe esa semántica y decide; el controller traduce los errores de aplicación a HTTP
con el traductor central. Así el controller no conoce Prisma y un cambio de ORM no cambia la API.

🔬 **El detalle:** El controller solo traduce aplicación a HTTP. Si traduce errores de Prisma, la
persistencia está filtrada hasta el borde de entrada, atravesando el núcleo entero.

### 22. 🟠 Un singleton guarda actor y request actual. ¿Qué fallo de concurrencia esperas?

⏱️ **30 segundos:** Que mezcle identidad y datos entre peticiones concurrentes.

🗣️ **2 minutos:** En Node, un solo proceso atiende muchas peticiones a la vez intercalando sus
`await`. Si un singleton guarda "el actor actual" en un campo, una petición lo escribe, otra lo
sobrescribe durante un `await` y la primera continúa con el actor de la segunda. Paso el actor por
llamada (en el comando) o uso un scope correcto; para correlación técnica, `AsyncLocalStorage`.

🔬 **El detalle:** Puede convertirse en una fuga de seguridad: un usuario operando con la identidad
de otro. Solo aparece bajo concurrencia, así que las pruebas secuenciales nunca lo ven.

### 23. 🟠 Todos los tests mockean Prisma y una constraint falla en producción. ¿Qué prueba agregas?

⏱️ **30 segundos:** Una integración del adaptador con la misma familia de base de datos que
producción.

🗣️ **2 minutos:** Contra PostgreSQL en un contenedor, con el esquema real aplicado, ejecuto el caso
que falló: la inserción que viola la restricción, y compruebo que el adaptador la traduce al error
propio y que la transacción se revierte. Añado esas expectativas al test de contrato del puerto,
para que el fake también las cumpla.

🔬 **El detalle:** El mock queda para la coordinación del caso de uso; nunca podía reproducir una
restricción que vive en el esquema de la base.

### 24. 🟠 ¿Cuándo NestJS añadiría más ceremonia que valor?

⏱️ **30 segundos:** En un grafo pequeño que no aprovecha su ecosistema: un worker, una CLI o un
servicio de pocas rutas.

🗣️ **2 minutos:** Nest aporta módulos, DI, pipes, guards, interceptores e integraciones; a cambio
exige decoradores, metadatos, tokens para interfaces y un arranque más pesado. Si el servicio tiene
tres rutas y cinco dependencias, una composición con funciones y un servidor ligero es más clara y
más rápida. Si tiene muchos módulos, equipos y necesidades transversales, Nest compensa.

🔬 **El detalle:** La decisión se revisa al crecer los scopes y las integraciones. Y en ambos casos
la regla es la misma: el núcleo no importa el framework.

---

## 04 · Go

### 1. 🟢 ¿Dónde conviene declarar una interfaz Go?

⏱️ **30 segundos:** Cerca del consumidor que la necesita, normalmente en el paquete del caso de uso.

🗣️ **2 minutos:** Como la implementación satisface la interfaz sin declararlo, el consumidor puede
definir exactamente el contrato mínimo que necesita (`type Orders interface { Find(...); Save(...)
}`) y cualquier adaptador con esos métodos lo cumple, aunque tenga muchos más. El adaptador no
necesita importar el paquete del caso de uso para implementarla, y los fakes de prueba son pequeños.

🔬 **El detalle:** Evita los paquetes de interfaces sin dueño: un contrato declarado lejos de quien
lo usa tiende a crecer con métodos que nadie necesita y a cambiar por razones ajenas al consumidor.

### 2. 🟢 ¿Cómo satisface una struct una interfaz?

⏱️ **30 segundos:** Implementando sus métodos con las firmas correctas, de forma implícita.

🗣️ **2 minutos:** No hay `implements` ni registro: si `PostgresOrders` tiene los métodos `Find` y
`Save` con las firmas de la interfaz `Orders`, la cumple. El compilador lo comprueba en el punto
donde se asigna la struct a una variable del tipo interfaz (por ejemplo, al pasarla al constructor
del caso de uso). Así el adaptador y el consumidor quedan desacoplados en el código.

🔬 **El detalle:** El compilador comprueba la asignación; si se quiere una verificación explícita en
el paquete del adaptador, basta `var _ Orders = (*PostgresOrders)(nil)`, aunque eso obliga a
importar el paquete de la interfaz.

### 3. 🟢 ¿Qué transporta `context.Context`?

⏱️ **30 segundos:** Cancelación, deadline y valores con alcance de una operación, como la
correlación.

🗣️ **2 minutos:** Se crea al empezar una petición o un trabajo, se deriva con `WithTimeout` o
`WithCancel`, y se pasa a cada llamada con I/O: consultas, llamadas remotas, publicaciones. Si el
cliente se desconecta o el plazo vence, todas las operaciones que respetan `ctx.Done()` se abortan.
También puede llevar valores de alcance de la petición, como el identificador de correlación o la
transacción en curso.

🔬 **El detalle:** Se pasa como primer parámetro de las funciones que lo necesitan, por convención, y
no debe usarse como bolsa de dependencias: repositorios, loggers o configuración van por
constructor.

### 4. 🟢 ¿Quién debe crear y cerrar el pool SQL?

⏱️ **30 segundos:** El composition root, normalmente `main`: quien crea el recurso es su dueño.

🗣️ **2 minutos:** `main` abre el pool (`sql.Open` o `pgxpool.New`) con la configuración validada,
comprueba la conexión, lo pasa a los constructores de los adaptadores y, al recibir la señal de
parada, lo cierra después de que terminen el servidor y los workers. Los adaptadores lo usan, pero
no lo crean ni lo cierran, así que no hay dudas sobre su ciclo de vida.

🔬 **El detalle:** Los repositorios reciben el pool ya construido. Si cada repositorio abriera el
suyo, habría varios pools compitiendo por conexiones y nadie sería responsable de cerrarlos.

### 5. 🟢 ¿Qué agrupa `sql.Tx`?

⏱️ **30 segundos:** Un conjunto de operaciones SQL que se confirman o revierten juntas, dentro de
una transacción local.

🗣️ **2 minutos:** `db.BeginTx(ctx, opts)` devuelve un `*sql.Tx` ligado a una conexión; todas las
operaciones que deban ser atómicas se ejecutan sobre él, y `Commit` o `Rollback` cierran la
transacción. En hexagonal, una unidad de trabajo lo crea y los adaptadores lo reciben (por parámetro
o por el contexto), de modo que el caso de uso no ve la transacción.

🔬 **El detalle:** No incluye servicios remotos: una llamada HTTP hecha "dentro" de la función
transaccional no participa del commit. Todas las operaciones de base deben ejecutarse sobre el mismo
`Tx`.

### 6. 🟢 ¿Qué hace `%w` al envolver un error?

⏱️ **30 segundos:** Preserva el error original como causa, para que pueda inspeccionarse después.

🗣️ **2 minutos:** `fmt.Errorf("saving order %s: %w", id, err)` añade contexto útil al mensaje y
mantiene el error envuelto en la cadena. Así, más arriba, `errors.Is(err, sql.ErrNoRows)` o
`errors.As(err, &pgErr)` siguen funcionando, y el adaptador puede clasificar la causa aunque haya
pasado por varias capas. Con `%v`, la causa se convierte en texto y se pierde.

🔬 **El detalle:** La cadena de causas sigue disponible al añadir contexto, y eso es lo que permite
traducir en el adaptador sin comparar mensajes.

### 7. 🟡 ¿Por qué evitarías un paquete global `interfaces`?

⏱️ **30 segundos:** Porque separa los contratos de sus consumidores y tiende a acumular APIs
genéricas sin dueño.

🗣️ **2 minutos:** En un paquete `interfaces`, un `OrderRepository` con veinte métodos acaba
sirviendo a todos y a ninguno: cada consumidor usa una parte, los fakes tienen que implementar todo
y cualquier cambio afecta a todos. Además crea un paquete del que depende todo el proyecto. Las
interfaces pequeñas declaradas junto al caso de uso evolucionan con él y expresan exactamente lo que
necesita.

🔬 **El detalle:** Un contrato compartido de verdad —por ejemplo, el mismo `Clock` usado por muchos
paquetes— sí puede justificar un paquete propio, pequeño y estable.

### 8. 🟡 ¿Cuándo un caso de uso no necesita `context`?

⏱️ **30 segundos:** Cuando ejecuta política pura, sin I/O ni operaciones que puedan cancelarse.

🗣️ **2 minutos:** Una función de dominio que calcula el total de un pedido o valida una transición
no hace I/O, así que no hay nada que cancelar ni plazo que respetar. El adaptador o el caso de uso
que la invoca gestiona el contexto antes (al cargar datos) y después (al guardar). Pasarle un
`context` que no usa solo añade ruido y la hace parecer dependiente de algo que no necesita.

🔬 **El detalle:** No se añade por uniformidad ritual. La regla es simple: si la función hace I/O o
llama a algo que lo hace, recibe `ctx`; si no, no.

### 9. 🟡 ¿Por qué no guardas `context` en una struct?

⏱️ **30 segundos:** Porque el contexto pertenece a una operación, no a un objeto que vive más que
ella.

🗣️ **2 minutos:** Si un adaptador guarda el `ctx` de la primera petición en un campo, todas las
operaciones posteriores usarán su deadline y su cancelación: cuando esa petición termine, el
contexto se cancela y el adaptador deja de funcionar, o peor, usa valores de otra petición.
Guardarlo mezcla operaciones y oculta su tiempo de vida.

🔬 **El detalle:** Hay que pasarlo explícitamente a cada método que lo necesita. La documentación de
Go lo recomienda expresamente, y es un error frecuente en quien llega desde lenguajes con contexto
por hilo.

### 10. 🟡 ¿Cómo traduces `sql.ErrNoRows`?

⏱️ **30 segundos:** A una ausencia o a un error propio del puerto, dentro del adaptador SQL.

🗣️ **2 minutos:** El adaptador comprueba `errors.Is(err, sql.ErrNoRows)` y decide según el contrato
del puerto: devolver un resultado vacío (`Order{}, false, nil`) o un error propio
(`ErrOrderNotFound`). El caso de uso recibe esa semántica y decide si es un error de negocio. El
handler HTTP, a su vez, traduce el error propio a `404`.

🔬 **El detalle:** El handler no conoce `database/sql`. Si el error del driver llega hasta él, la
persistencia atravesó el núcleo entero.

### 11. 🟡 ¿Qué diferencia hay entre `errors.Is` y comparar textos?

⏱️ **30 segundos:** `errors.Is` inspecciona la cadena de causas por identidad; comparar textos
depende de mensajes que pueden cambiar.

🗣️ **2 minutos:** `errors.Is(err, ErrOrderNotFound)` funciona aunque el error se haya envuelto
varias veces con contexto adicional, y no se rompe si alguien mejora un mensaje.
`strings.Contains(err.Error(), "not found")` se rompe al cambiar una palabra, al traducir el mensaje
o al actualizar una biblioteca. Envolver con `%w` conserva la clasificación sin fijar los mensajes.

🔬 **El detalle:** `errors.As` complementa a `errors.Is`: extrae un tipo de error concreto de la
cadena (por ejemplo, el error del driver de PostgreSQL con su código) para leer sus campos.

### 12. 🟡 ¿Cómo comparten transacción dos repositorios?

⏱️ **30 segundos:** Ejecutando ambos sus operaciones sobre el mismo `*sql.Tx`.

🗣️ **2 minutos:** La unidad de trabajo abre la transacción y, o bien construye repositorios ligados
a ese `Tx`, o bien lo guarda en el `context` para que cada repositorio lo recupere (y use el pool si
no hay transacción). Los repositorios aceptan una abstracción común (una interfaz con `ExecContext`
y `QueryContext`, que cumplen tanto `*sql.DB` como `*sql.Tx`), para no duplicar código.

🔬 **El detalle:** Nunca mezclan llamadas al `*sql.DB` raíz dentro de una operación transaccional:
esa llamada se ejecutaría en otra conexión y confirmaría sola.

### 13. 🟡 ¿Qué responsabilidad tiene `main`?

⏱️ **30 segundos:** Configurar, construir, iniciar y cerrar la aplicación: es el composition root.

🗣️ **2 minutos:** Lee y valida la configuración, crea los recursos (pool, clientes), construye
adaptadores y casos de uso, monta el servidor HTTP y los workers, escucha las señales del sistema
operativo y coordina el apagado ordenado: dejar de aceptar tráfico, esperar lo que está en curso,
detener workers, cerrar recursos. Si algo falla al arrancar, sale con un error claro.

🔬 **El detalle:** No contiene reglas de negocio. Si `main` crece mucho, se extrae una función
`build` que devuelve el grafo, pero la responsabilidad sigue siendo solo ensamblar.

### 14. 🟡 ¿Cuándo introducirías una función `build`?

⏱️ **30 segundos:** Cuando el wiring necesita reutilizarse (por ejemplo, en pruebas de integración)
o probarse de forma aislada.

🗣️ **2 minutos:** `build(cfg Config) (*App, error)` construye el grafo completo y devuelve la
aplicación o un error de configuración. `main` se reduce a leer configuración, llamar a `build`,
arrancar y esperar la señal de parada. Las pruebas de integración pueden llamar a `build` con una
configuración de prueba y obtener exactamente el mismo grafo que producción.

🔬 **El detalle:** Mantiene `main` pequeño sin ocultar dependencias: la función sigue siendo código
explícito que se lee de arriba abajo, sin contenedor ni reflexión.

### 15. 🟡 ¿Qué prueba harías con `httptest`?

⏱️ **30 segundos:** Una prueba del adaptador HTTP: routing, parseo de la petición y construcción de
la respuesta.

🗣️ **2 minutos:** Con `httptest.NewRecorder` y `httptest.NewRequest`, o con un `httptest.Server`,
ejecuto el handler real con un caso de uso controlado (un fake) y compruebo que el JSON correcto
produce el comando esperado, que un cuerpo inválido devuelve `400`, que cada error del caso de uso
se traduce al status y al cuerpo del contrato y que los headers son los correctos.

🔬 **El detalle:** No prueba SQL por sí sola: el adaptador de persistencia necesita su propia prueba
contra una base real.

### 16. 🟡 ¿Qué limita el detector de carreras?

⏱️ **30 segundos:** Que solo detecta las carreras que ocurren durante esa ejecución concreta.

🗣️ **2 minutos:** `go test -race` instrumenta los accesos a memoria y avisa cuando dos goroutines
acceden a la misma variable sin sincronización en esa ejecución. Si el escenario de prueba no
ejercita la concurrencia problemática, no la ve. Tampoco detecta problemas lógicos de concurrencia
que no son carreras de datos, como dos procesos actualizando el mismo pedido en la base.

🔬 **El detalle:** Necesita escenarios concurrentes representativos para ser útil, y no demuestra la
ausencia de carreras ni corrige el diseño de ownership: es una herramienta de detección, no una
garantía.

### 17. 🟠 Un repository usa `db.ExecContext` dentro de una operación con `tx`. ¿Qué se rompe?

⏱️ **30 segundos:** Esa escritura queda fuera de la transacción: se ejecuta en otra conexión y
confirma por su cuenta.

🗣️ **2 minutos:** Si la transacción después se revierte, esa escritura sigue confirmada, y el estado
queda a medias. Si depende de filas que la transacción tiene bloqueadas o que aún no confirmó (una
FK), puede bloquearse o fallar. Es el error provocado del taller de Go: la reserva insertada con el
pool no ve el pedido de la transacción y la FK la rechaza.

🔬 **El detalle:** El repositorio debe usar el ejecutor transaccional, idealmente obtenido del
contexto de la unidad de trabajo, de modo que sea imposible elegir el pool por error.

### 18. 🟠 Un adapter reemplaza el deadline entrante por 30 segundos. ¿Qué corriges?

⏱️ **30 segundos:** Que conserve el deadline más corto: el presupuesto restante de la operación
entrante.

🗣️ **2 minutos:** Si el adaptador crea un contexto nuevo con `context.Background()` y 30 segundos,
la llamada saliente sobrevive a la petición del cliente, que ya se fue: consume recursos y puede
producir efectos que nadie reportará. Debe derivar su contexto del entrante con
`context.WithTimeout(ctx, maxPropio)`, que respeta el plazo del padre si es más corto.

🔬 **El detalle:** `WithTimeout` respeta un padre con deadline anterior: el contexto resultante vence
en el menor de los dos plazos. Por eso derivar siempre del contexto recibido es suficiente.

### 19. 🟠 El caso de uso devuelve `sql.ErrNoRows` al handler. ¿Dónde traduces?

⏱️ **30 segundos:** En el adaptador SQL, antes de que el error cruce el puerto.

🗣️ **2 minutos:** El adaptador convierte `sql.ErrNoRows` en un error propio (`ErrOrderNotFound`) o
en un resultado de ausencia. El caso de uso recibe esa semántica y decide si es un error de negocio;
el handler traduce el error propio a `404` con `errors.Is`. Así el handler no importa `database/sql`
y el caso de uso no conoce el driver.

🔬 **El detalle:** El transporte decide después su status: el mismo `ErrOrderNotFound` puede ser un
`404` en HTTP y un rechazo registrado en un consumidor de mensajes.

### 20. 🟠 Una interfaz tiene veinte métodos porque copia el driver SQL. ¿Cómo la reduces?

⏱️ **30 segundos:** Rediseñándola desde la necesidad de cada consumidor, no desde lo que ofrece el
driver.

🗣️ **2 minutos:** `CreateOrder` quizá solo necesita buscar productos y guardar el pedido;
`CancelOrder`, buscar y guardar el pedido. Declaro en cada paquete la interfaz mínima que usa, con
nombres de negocio. El adaptador puede seguir siendo una sola struct que satisface todas, y usar
internamente la API completa del driver. Los fakes de prueba pasan de veinte métodos a dos.

🔬 **El detalle:** El adaptador conserva la API completa del driver internamente; lo que cambia es
qué ve el núcleo.

### 21. 🟠 Un `defer Rollback` ignora que `Commit` falló. ¿Qué resultado expones?

⏱️ **30 segundos:** Un error de commit con la causa preservada; nunca un éxito.

🗣️ **2 minutos:** Si `Commit` devuelve error y el código lo ignora confiando en el `defer
tx.Rollback()`, la función devuelve éxito aunque los cambios quizá no se guardaron. Hay que
comprobar el error de `Commit`, envolverlo con `%w` y devolverlo. Según el fallo (conexión perdida
durante el commit), el estado puede ser incierto: el commit pudo haber llegado a la base.

🔬 **El detalle:** El `Rollback` posterior a un commit exitoso no hace nada (devuelve
`sql.ErrTxDone`), así que el patrón `defer Rollback` es seguro; lo que no es seguro es ignorar el
error del commit.

### 22. 🟠 Variables globales guardan DB y reloj para facilitar tests. ¿Qué alternativa usas?

⏱️ **30 segundos:** Constructores con dependencias explícitas, construidas en `main` y sustituidas
en las pruebas.

🗣️ **2 minutos:** Los adaptadores reciben el pool por constructor; los casos de uso reciben sus
puertos y un `Clock` (o una función `now func() time.Time`). `main` entrega la base y el reloj
reales; las pruebas construyen los mismos objetos con una base de prueba y un reloj fijo. No hay que
mutar variables globales ni restaurarlas al terminar.

🔬 **El detalle:** Los tests sustituyen valores sin mutar globales, lo que además permite ejecutarlos
en paralelo con `t.Parallel()` sin que interfieran.

### 23. 🟠 Un fake pasa y PostgreSQL rechaza una constraint. ¿Cómo distribuyes las pruebas?

⏱️ **30 segundos:** Fakes para la coordinación del caso de uso; PostgreSQL real para el adaptador.

🗣️ **2 minutos:** Las pruebas del caso de uso siguen usando el fake porque son rápidas y prueban la
lógica. El adaptador se prueba contra PostgreSQL con el esquema real, incluida la restricción que
falló. Y un test de contrato común, ejecutado contra el fake y contra el adaptador real, obliga al
fake a comportarse igual en lo que importa (unicidad, ausencia, versión).

🔬 **El detalle:** Aíslo los datos y las transacciones por prueba (transacción revertida al final, o
identificadores únicos), para que las pruebas de integración puedan correr en paralelo sin
contaminarse.

### 24. 🟠 ¿Cuándo una implementación concreta es mejor dependencia que una interfaz?

⏱️ **30 segundos:** Cuando no existe frontera que proteger ni sustitución útil.

🗣️ **2 minutos:** Una struct pura y estable —un calculador de precios, un validador de formato—
puede recibirse directamente como tipo concreto: se prueba sin dobles porque no hace I/O, y una
interfaz solo añadiría un salto de navegación. En Go esto es especialmente natural, porque la
interfaz se puede extraer más tarde en el consumidor sin tocar la implementación.

🔬 **El detalle:** Extraigo la interfaz cuando aparece una necesidad del consumidor: sustituirla en
pruebas, una segunda implementación o una frontera hacia algo externo. Nunca antes "por si acaso".

---

## 05 · Python

### 1. 🟢 ¿Qué papel cumple `Protocol`?

⏱️ **30 segundos:** Expresa un contrato estructural que el type checker puede comprobar, sin exigir
herencia.

🗣️ **2 minutos:** `class Orders(Protocol): def save(self, order: Order) -> None: ...` describe el
puerto que necesita `CreateOrder`. Cualquier clase con ese método lo satisface, sea el adaptador de
SQLAlchemy o un fake de prueba, sin heredar de nada. mypy o pyright avisan si una implementación no
encaja. Documenta el contrato en el lenguaje, igual que una interfaz en Java o Go.

🔬 **El detalle:** No garantiza la semántica en runtime: Python no comprueba el `Protocol` al
ejecutar (salvo `runtime_checkable`, que solo mira nombres de métodos). La semántica se protege con
pruebas de contrato.

### 2. 🟢 ¿Qué valida un modelo Pydantic?

⏱️ **30 segundos:** Que los datos de entrada cumplan los tipos y restricciones declarados, en el
momento de construir el modelo.

🗣️ **2 minutos:** Al construir un `CreateOrderRequest` desde el JSON, Pydantic comprueba tipos,
obligatorios, rangos y formatos, y lanza un error detallado si algo no cumple. Produce un objeto con
la forma procesada, y por defecto puede hacer coerción: convertir `"10"` en `10`. FastAPI lo usa
automáticamente en el borde para validar peticiones y serializar respuestas.

🔬 **El detalle:** El modo estricto cambia qué conversiones acepta: con él, `"10"` no se convierte en
entero y se rechaza, lo que es preferible cuando la coerción puede esconder un contrato violado.

### 3. 🟢 ¿Qué debería modelar una clase de dominio Python?

⏱️ **30 segundos:** Estado, invariantes y comportamiento del negocio: qué es un pedido válido y cómo
cambia.

🗣️ **2 minutos:** `Order` con sus líneas, su estado, métodos como `cancel()` que validan la
transición y lanzan errores propios, y value objects como `Money` con `Decimal`. No necesita
FastAPI, Pydantic ni SQLAlchemy por defecto: es Python ordinario que se prueba con pytest sin nada
más. Así el dominio no cambia cuando cambia el framework web o la base.

🔬 **El detalle:** Puede ser una dataclass (congelada para value objects) o una clase ordinaria. Usar
Pydantic en el dominio es posible, pero mezcla validación de entrada externa con invariantes de
negocio.

### 4. 🟢 ¿Dónde se construye la aplicación FastAPI?

⏱️ **30 segundos:** En una app factory o composition root: una función que crea y conecta todo.

🗣️ **2 minutos:** `create_app(settings)` crea el engine de la base, los adaptadores, los casos de
uso y la app de FastAPI, registra las rutas con sus dependencias y los manejadores de errores, y
devuelve la app. Las pruebas llaman a la misma función con otra configuración. Así el grafo es
explícito y no hay objetos globales creados al importar módulos.

🔬 **El detalle:** También controla el arranque y el cierre: con el `lifespan` de FastAPI se abren
los recursos al iniciar y se cierran (engine, clientes HTTP) al detener.

### 5. 🟢 ¿Qué recurso representa una `Session`?

⏱️ **30 segundos:** Una unidad con estado de conversación con la base: identidad de objetos, cambios
pendientes y la transacción en curso.

🗣️ **2 minutos:** La `Session` de SQLAlchemy lleva el registro de los objetos cargados, los cambios
que hay que escribir y la transacción abierta. Su ciclo de vida debe coincidir con una unidad de
trabajo: se crea al empezar, se confirma o revierte al terminar y se cierra siempre. Las sesiones se
obtienen de un `sessionmaker` ligado a un engine compartido.

🔬 **El detalle:** No se comparte concurrentemente entre peticiones, hilos ni tareas: su estado
mutable se mezclaría y las transacciones se pisarían.

### 6. 🟢 ¿Qué conserva `raise ... from exc`?

⏱️ **30 segundos:** La causa original de una excepción que se traduce a otra.

🗣️ **2 minutos:** En el adaptador, `except IntegrityError as exc: raise DuplicateOrder(order.id)
from exc` convierte el error del driver en un error propio y guarda el original en `__cause__`. El
traceback muestra ambos. Así el caso de uso recibe semántica propia y el diagnóstico sigue teniendo
la consulta, la restricción y el mensaje del driver.

🔬 **El detalle:** El cliente no recibe necesariamente esa causa: el traductor HTTP muestra solo el
error propio con un mensaje seguro, y la causa va a los logs.

### 7. 🟡 ¿Por qué las anotaciones no validan runtime solas?

⏱️ **30 segundos:** Porque Python no impone los type hints al ejecutar: son metadatos que el
intérprete ignora.

🗣️ **2 minutos:** `def create(customer_id: str)` acepta perfectamente un entero o `None` en
ejecución. Las anotaciones sirven a los type checkers (análisis estático) y a bibliotecas que las
leen explícitamente para validar (Pydantic, FastAPI). Sin una de esas herramientas en el camino, un
dato mal tipado viaja hasta que algo falla lejos de su origen.

🔬 **El detalle:** Los datos externos siguen siendo no confiables: por eso el borde valida con
Pydantic, y el núcleo, con los type checkers en CI, protege el código interno.

### 8. 🟡 ¿Cuándo activarías validación estricta en Pydantic?

⏱️ **30 segundos:** Cuando la coerción puede ocultar un contrato inválido o un error del cliente.

🗣️ **2 minutos:** En dinero, identificadores, cantidades o formatos sensibles, convertir
silenciosamente `"10.5"` en `10.5` o `1` en `true` puede aceptar datos que el cliente envió mal y
que deberían rechazarse. El modo estricto obliga a que los tipos coincidan exactamente. El taller de
FastAPI usa Pydantic estricto solo en el borde, para que el contrato HTTP sea preciso.

🔬 **El detalle:** Se decide por campo o por modelo según el borde: algunos contratos admiten
coerción razonable (fechas en varios formatos) y otros no.

### 9. 🟡 ¿Por qué `Depends` no entra al caso de uso?

⏱️ **30 segundos:** Porque es un mecanismo de composición de FastAPI, y el caso de uso no debe
depender del framework web.

🗣️ **2 minutos:** La ruta recibe sus dependencias con `Depends` (el caso de uso ya construido, el
actor autenticado) y llama a una clase ordinaria que recibió sus puertos por constructor. Si el caso
de uso usara `Depends` en su firma, solo FastAPI podría construirlo; un worker o una CLI tendrían
que imitar su sistema de dependencias, y las pruebas necesitarían la app.

🔬 **El detalle:** Así el caso de uso se reutiliza fuera de HTTP. `Depends` es cómodo y tentador;
conviene que su uso termine en el adaptador.

### 10. 🟡 ¿Cómo delimitas una transacción de aplicación?

⏱️ **30 segundos:** Con un context manager alrededor de la unidad de trabajo completa.

🗣️ **2 minutos:** Una unidad de trabajo abre `with engine.begin() as conn:` (o una sesión con
`session.begin()`), deja la conexión disponible para los adaptadores durante el bloque —por
parámetro o en un `ContextVar`— y confirma al salir si no hubo excepción o revierte si la hubo. El
caso de uso invoca `unit_of_work.run(work)` y no ve la conexión.

🔬 **El detalle:** La misma sesión o conexión sirve a todos los adaptadores locales de esa operación,
y el commit o el rollback ocurren una sola vez, al final.

### 11. 🟡 ¿Por qué no compartes `AsyncSession` entre tareas?

⏱️ **30 segundos:** Porque mantiene estado transaccional mutable que las tareas concurrentes
mezclarían.

🗣️ **2 minutos:** Dos tareas `asyncio` que usan la misma `AsyncSession` intercalan sus operaciones
en la misma transacción: los objetos de una aparecen en la otra, un rollback de una deshace el
trabajo de la otra, y SQLAlchemy puede lanzar errores por uso concurrente. Cada unidad de trabajo
obtiene su propia sesión del `async_sessionmaker` y la cierra al terminar.

🔬 **El detalle:** El engine sí se comparte (gestiona el pool); la sesión no. Es la misma regla que
en código síncrono, solo que con concurrencia más fácil de provocar sin darse cuenta.

### 12. 🟡 ¿Qué ocurre si llamas un driver síncrono desde `async def`?

⏱️ **30 segundos:** Que bloqueas el event loop mientras dura la llamada.

🗣️ **2 minutos:** En una ruta `async def`, una consulta con un driver síncrono detiene el event loop
hasta que la base responde: ninguna otra petición avanza en ese proceso durante ese tiempo. La
función se declara async, pero no lo es. Bajo carga, la latencia de todas las peticiones sube y
aparecen timeouts.

🔬 **El detalle:** Hay que usar un driver async de extremo a extremo, o declarar la ruta como `def`
para que FastAPI la ejecute en su pool de hilos. El taller de FastAPI eligió lo segundo: endpoints
`def` con un driver síncrono.

### 13. 🟡 ¿Dónde traduces `IntegrityError`?

⏱️ **30 segundos:** En el adaptador de persistencia, antes de que cruce el puerto.

🗣️ **2 minutos:** El adaptador captura `IntegrityError`, inspecciona la causa (qué restricción se
violó) y la convierte en un conflicto propio (`DuplicateOrder`, `OperationAlreadyApplied`) o en un
fallo técnico si no la reconoce, con `raise ... from exc` para conservar la causa. El caso de uso
decide qué hacer con el conflicto; el traductor HTTP, qué status usar.

🔬 **El detalle:** El dominio no importa SQLAlchemy ni sabe que existe `IntegrityError`: si lo
supiera, cambiar de ORM o de driver tocaría las reglas.

### 14. 🟡 ¿Qué prueba haces con `TestClient`?

⏱️ **30 segundos:** Una prueba del contrato HTTP de la aplicación FastAPI.

🗣️ **2 minutos:** Con `TestClient(app)` envío peticiones reales a la app y verifico la validación
del cuerpo (un JSON inválido da `422` o `400` según el contrato), el routing, los status, el JSON de
respuesta y los manejadores de errores (cada error propio produce su Problem Details). Construyo la
app con casos de uso controlados, para aislar la ruta de la lógica.

🔬 **El detalle:** Uso dependencias controladas, idealmente construyendo la app con la factory y
fakes, o con `dependency_overrides` para sustituir lo externo. Así la prueba cubre HTTP, no la base.

### 15. 🟡 ¿Qué límite tienen los dependency overrides?

⏱️ **30 segundos:** No prueban la implementación real que sustituyen.

🗣️ **2 minutos:** `app.dependency_overrides[get_orders] = lambda: FakeOrders()` es útil para aislar
las pruebas HTTP de la base. Pero si todas las pruebas lo usan, el adaptador real de SQLAlchemy y la
composición real nunca se ejecutan en CI: un mapeo roto, una restricción o una dependencia mal
registrada solo aparecen en producción.

🔬 **El detalle:** Mantengo pruebas de integración aparte: el adaptador contra una base real, y al
menos una prueba de arranque con la composición real.

### 16. 🟡 ¿Cuándo aceptarías un modelo compartido?

⏱️ **30 segundos:** En un CRUD pequeño, sin evolución independiente entre capas y sin filtrar ciclo
de vida de sesión.

🗣️ **2 minutos:** Si el modelo es trivial, la API es interna y estable y no hay invariantes que
proteger, usar una clase para varios papeles ahorra código. Aun así, debe conservar la dirección de
dependencias (el núcleo no importa FastAPI) y el contrato público debe estar controlado: nada de
devolver objetos ORM con relaciones cargables.

🔬 **El detalle:** Registro una señal para separarlo después: la primera regla de negocio, una
versión nueva de la API o un campo que no debería publicarse.

### 17. 🟠 El dominio lanza `HTTPException`. ¿Qué contrato introduces?

⏱️ **30 segundos:** Un error propio de negocio o de aplicación, como `OrderNotFound` o
`InsufficientInventory`.

🗣️ **2 minutos:** El dominio lanza sus excepciones; un `exception_handler` registrado en la app las
traduce a respuestas HTTP con el status y el Problem Details del contrato. El dominio deja de
importar FastAPI, sus pruebas no necesitan la app, y un worker que invoque la misma regla recibe un
error con significado propio, no un concepto HTTP.

🔬 **El detalle:** Otro driver puede mapearlo distinto: el mismo `InsufficientInventory` es un `409`
en HTTP y un rechazo registrado en una cola.

### 18. 🟠 Una `Session` global mezcla dos requests. ¿Cómo rediseñas su scope?

⏱️ **30 segundos:** Creando una sesión por unidad de trabajo o por petición, con un dueño que la
cierra.

🗣️ **2 minutos:** Una dependencia de FastAPI con `yield` crea la sesión al empezar la petición, la
entrega a los adaptadores, confirma o revierte al terminar y la cierra siempre, incluso ante
errores. O una unidad de trabajo con un `ContextVar` que la mantiene durante la operación. En ambos
casos cada petición tiene su sesión y su transacción.

🔬 **El detalle:** El engine sí suele ser compartido: gestiona el pool de conexiones y es seguro
entre hilos. Lo que no se comparte es la sesión.

### 19. 🟠 Pydantic convierte `"10"` a entero y el contrato exigía rechazo. ¿Qué ajustas?

⏱️ **30 segundos:** Activo la validación estricta para ese campo o modelo.

🗣️ **2 minutos:** Con `strict=True` (en el campo o en la configuración del modelo), `"10"` deja de
convertirse y se rechaza con un error de validación, que el adaptador traduce a la respuesta del
contrato. Lo aplico donde el contrato lo exige, sin cambiar necesariamente otros campos donde la
coerción es aceptable.

🔬 **El detalle:** Pruebo con el JSON real enviado por `TestClient` y compruebo el error resultante:
una prueba unitaria del modelo no cubre cómo FastAPI lo usa ni cómo se presenta el error.

### 20. 🟠 Un adapter captura `Exception` y devuelve `None`. ¿Qué información perdiste?

⏱️ **30 segundos:** El tipo de error, su causa y la distinción entre "no existe" y "no pude
comprobarlo".

🗣️ **2 minutos:** Con `except Exception: return None`, un pedido inexistente, una base caída y un
bug de programación producen el mismo resultado: `None`. El caso de uso decidirá que el pedido no
existe cuando en realidad hubo un fallo técnico, y nadie verá el error. Traduzco las excepciones
conocidas a resultados o errores propios, y dejo propagar las inesperadas con su causa.

🔬 **El detalle:** `None` no expresa indisponibilidad: si el contrato necesita distinguir ausencia de
fallo, necesita tipos distintos para cada uno.

### 21. 🟠 Una ruta async ejecuta ORM síncrono lento. ¿Qué riesgo operativo aparece?

⏱️ **30 segundos:** Que bloquea el event loop y degrada todas las demás peticiones del proceso.

🗣️ **2 minutos:** Mientras la consulta síncrona espera a la base, el event loop no atiende a nadie
más: las peticiones se acumulan, la latencia sube para todos y los health checks pueden fallar,
haciendo que el orquestador reinicie instancias sanas. Uso una cadena async coherente (driver y ORM
async) o declaro la ruta como `def` para ejecutarla en el pool de hilos, dimensionado
conscientemente.

🔬 **El detalle:** Mido la saturación del event loop (retrasos de tareas) y los timeouts bajo carga:
el problema es invisible con una sola petición.

### 22. 🟠 El modelo SQLAlchemy se devuelve como response. ¿Qué fronteras quedan acopladas?

⏱️ **30 segundos:** Persistencia, sesión y contrato HTTP, todas a la vez.

🗣️ **2 minutos:** El esquema de la base se convierte en contrato público: una columna nueva puede
filtrar datos, un cambio de nombre rompe clientes y una relación lazy puede dispararse durante la
serialización fuera de la sesión (fallando o haciendo consultas imprevistas). Proyecto un response
model explícito con los campos públicos, construido desde un resultado propio del caso de uso.

🔬 **El detalle:** `response_model` de FastAPI ayuda a filtrar la salida, pero no evita que el objeto
ORM llegue hasta el borde. Lo más seguro es que nunca salga del adaptador de persistencia.

### 23. 🟠 Todos los tests reemplazan la dependencia de DB. ¿Qué prueba falta?

⏱️ **30 segundos:** Una integración del adaptador de SQLAlchemy con una base compatible con la de
producción.

🗣️ **2 minutos:** Contra PostgreSQL en un contenedor, con el esquema real, pruebo que el adaptador
guarda y reconstruye bien, que las restricciones se traducen a errores propios, que la sesión y la
transacción se comportan como se espera y que no hay consultas N+1. Añado también una prueba de
arranque con la composición real.

🔬 **El detalle:** Los overrides quedan para las pruebas HTTP, donde aíslan lo que corresponde; la
integración de persistencia se prueba con persistencia real.

### 24. 🟠 ¿Cuándo una clase concreta es más clara que un `Protocol`?

⏱️ **30 segundos:** Cuando no hay frontera que proteger ni alternativa útil que sustituir.

🗣️ **2 minutos:** Un servicio de dominio puro, un calculador o un validador pueden inyectarse como
clases concretas: se prueban sin dobles porque no hacen I/O, y un `Protocol` que duplica su firma
solo añade un archivo y un salto de navegación. En Python, además, sustituir una clase concreta en
pruebas es trivial si alguna vez hace falta.

🔬 **El detalle:** Extraigo el protocolo cuando aparece un consumidor real que lo necesite: una
segunda implementación, una frontera hacia algo externo o una prueba que no puede usar la clase
real.

---

## 06 · Matriz de decisión y plantilla de servicio

### 1. 🟢 ¿Qué debe automatizar una plantilla de servicio?

⏱️ **30 segundos:** Lo repetible y estable de la organización: build, controles de calidad,
configuración, observabilidad base y operación.

🗣️ **2 minutos:** Un servicio nuevo debería nacer con su build y su pipeline, lint y type checking,
una regla de dependencias que impida al núcleo importar infraestructura, configuración tipada
validada al arrancar, health y readiness, logs estructurados sin secretos, métricas base, cierre
ordenado y una prueba de arranque. Son decisiones que todos los equipos repetirían, y que salen mal
si cada uno las reinventa.

🔬 **El detalle:** Automatiza decisiones organizacionales estables, no decisiones de dominio: la
plantilla sabe cómo se opera un servicio, no qué hace.

### 2. 🟢 ¿Qué no debe inventar una plantilla?

⏱️ **30 segundos:** Dominio, puertos, entidades ni integraciones sin evidencia de que el servicio
los necesite.

🗣️ **2 minutos:** Una plantilla que genera `CustomerRepository`, `OrderCreatedEvent`, un módulo de
outbox y un cliente de Kafka en cada servicio parece guía, pero consolida una arquitectura
accidental: los equipos rellenan esas piezas para "cumplir" en lugar de diseñar desde su problema.
Los nombres ficticios se quedan, y el servicio acaba con abstracciones que nadie pidió.

🔬 **El detalle:** Si la plantilla incluye ejemplos (un endpoint de muestra), deben eliminarse o
renombrarse al crear el servicio, y la propia plantilla debería decirlo.

### 3. 🟢 ¿Cuáles son las tres profundidades propuestas?

⏱️ **30 segundos:** Directa, selectiva y completa.

🗣️ **2 minutos:** Directa: handler, aplicación simple y persistencia, con las dependencias hacia
adentro, para un CRUD estable. Selectiva: casos de uso y puertos solo en las fronteras que lo
justifican (un proveedor volátil, una regla crítica), con el resto simple. Completa: dominio
explícito, puertos, adaptadores, contratos y reglas de módulos, para servicios con muchas entradas,
efectos críticos o larga vida.

🔬 **El detalle:** Representan costes distintos, no niveles de madurez. Pueden coexistir dentro de un
mismo servicio, por capacidad: pagos completo y catálogo directo.

### 4. 🟢 ¿Qué cinco fuerzas usa la matriz?

⏱️ **30 segundos:** Volatilidad de las reglas, integraciones, riesgo, equipo y vida útil.

🗣️ **2 minutos:** Reglas que cambian con frecuencia piden aislar el dominio; varios proveedores o un
broker piden puertos de salida; dinero, inventario o cumplimiento suben el coste del fallo; varios
equipos o propiedad dividida piden contratos explícitos; un producto de larga vida amortiza mejor la
estructura que un experimento. Cada fuerza señala dónde puede compensar una frontera.

🔬 **El detalle:** No producen una puntuación automática universal: son preguntas para decidir con
criterio, y una fuerza alta en un punto no justifica estructura en todo el sistema.

### 5. 🟢 ¿Qué es una señal de revisión?

⏱️ **30 segundos:** Un cambio observable que obliga a reevaluar una decisión de arquitectura.

🗣️ **2 minutos:** Un segundo driver para el mismo caso de uso, un incidente causado por
acoplamiento, una regla que empieza a cambiar cada semana, un proveedor nuevo o un cambio de equipo
propietario. Al tomar una decisión (por ejemplo, empezar con profundidad directa), se registran las
señales que la harían cambiar. Cuando aparece una, se revisa con la información nueva.

🔬 **El detalle:** Evita revisar por calendario sin causa, y también evita no revisar nunca: la
decisión queda ligada a hechos, no a la memoria de quien la tomó.

### 6. 🟢 ¿Por qué se versiona la plantilla?

⏱️ **30 segundos:** Para saber qué cambió entre versiones y poder actualizar los servicios que se
generaron con versiones anteriores.

🗣️ **2 minutos:** Una plantilla evoluciona: se corrige un fallo de seguridad en la configuración, se
añade un control, se actualiza una dependencia. Si cada servicio es una copia sin versión, esas
mejoras nunca llegan a los servicios existentes, o llegan a mano y de forma distinta en cada uno.
Con versiones y notas de cambio, cada servicio sabe de qué versión viene y qué tiene que aplicar.

🔬 **El detalle:** Copiar una vez y olvidar crea divergencia silenciosa: al cabo de un año hay tantas
variantes como servicios, y la plantilla ya no representa a ninguno.

### 7. 🟡 ¿Cuándo basta una profundidad directa?

⏱️ **30 segundos:** En un CRUD estable, simple, de bajo riesgo y con una sola entrada y una sola
base.

🗣️ **2 minutos:** Handlers que validan y llaman a funciones de aplicación, que usan el acceso a
datos directamente, con las pocas reglas que haya en funciones puras probadas. Mantengo la dirección
básica —las reglas no importan el framework— sin puertos ni mappers innecesarios. Es más rápido de
construir, más fácil de entender y suficiente para el riesgo.

🔬 **El detalle:** Se revisa si aparece un cambio independiente: una segunda entrada, una regla
volátil, un proveedor externo. La simplicidad es una decisión con señales de revisión, no un
descuido.

### 8. 🟡 ¿Qué frontera selectiva introducirías para pagos?

⏱️ **30 segundos:** Un puerto `PaymentGateway` con resultados propios, implementado por un adaptador
del proveedor.

🗣️ **2 minutos:** Aísla al proveedor, la idempotencia por clave estable y el resultado incierto, que
son el riesgo real: cobrar dos veces o perder un cobro. El caso de uso `AuthorizePayment` decide el
estado del pedido con resultados propios, y se prueba con un fake. No hace falta reestructurar el
resto del servicio para conseguirlo.

🔬 **El detalle:** El resto del CRUD puede seguir simple. La arquitectura puede ser asimétrica:
estructura fuerte donde está el riesgo, estructura mínima donde no lo hay.

### 9. 🟡 ¿Cuándo justificarías una separación completa?

⏱️ **30 segundos:** Con alto riesgo, varias entradas o integraciones, reglas volátiles y una vida
útil larga.

🗣️ **2 minutos:** Un servicio de pedidos que recibe peticiones por HTTP y por cola, integra pagos,
inventario y notificaciones, maneja dinero y va a vivir años justifica dominio explícito, puertos de
entrada y salida, adaptadores con contratos y reglas de módulos. También ayuda cuando la propiedad
está dividida entre equipos: los puertos se convierten en contratos entre ellos.

🔬 **El detalle:** Debe pagarse con pruebas por anillos, reglas de arquitectura en CI y capacidad
operativa. Una separación completa sin esas prácticas es solo más carpetas.

### 10. 🟡 ¿Por qué una fuerza alta no obliga a crear todas las capas?

⏱️ **30 segundos:** Porque el riesgo suele estar localizado en una frontera concreta, no repartido
por todo el sistema.

🗣️ **2 minutos:** Si lo volátil es el proveedor de pagos, aíslo el proveedor detrás de un puerto; no
necesito duplicar modelos en el catálogo, que es estable, ni añadir puertos de entrada a un endpoint
que solo tiene HTTP. Cada frontera se compra donde reduce un riesgo concreto. Aplicar la estructura
completa en todas partes reparte un coste real para proteger contra riesgos que en la mayoría de
sitios no existen.

🔬 **El detalle:** La arquitectura puede ser asimétrica, y suele ser mejor así: las fronteras
importantes se reconocen porque no están rodeadas de fronteras de relleno.

### 11. 🟡 ¿Qué controles pertenecen al skeleton y no al dominio?

⏱️ **30 segundos:** Build, lint, type checking, configuración, health, logs, métricas base y cierre
ordenado.

🗣️ **2 minutos:** Son capacidades repetibles de plataforma: todos los servicios las necesitan, casi
igual, y su valor está en que sean uniformes (los operadores saben dónde mirar, los pipelines son
iguales). También la regla de dependencias vacía, lista para que el equipo la llene con sus módulos.
Nada de eso depende de qué haga el servicio.

🔬 **El detalle:** El dominio se nombra después, con conocimiento real del problema. La plantilla le
da al equipo un lugar donde ponerlo, no un contenido inventado.

### 12. 🟡 ¿Cómo pruebas una plantilla antes de publicarla?

⏱️ **30 segundos:** Generando servicios en seco con ella y ejecutando su build, sus pruebas y su
arranque.

🗣️ **2 minutos:** El pipeline de la plantilla genera un servicio con parámetros representativos,
compila, ejecuta sus pruebas, lo arranca y comprueba el health, y verifica que no queden
placeholders sin sustituir, secretos reales ni permisos excesivos. Si la plantilla tiene variantes
(con o sin base, por plataforma), prueba cada una.

🔬 **El detalle:** Mantengo casos representativos por plataforma y los ejecuto en cada cambio: una
plantilla rota se multiplica en cada servicio nuevo.

### 13. 🟡 ¿Qué medirías para saber si la plantilla ayuda?

⏱️ **30 segundos:** Tiempo hasta producción de un servicio nuevo, fallos de configuración o
seguridad evitados y cuánto código generado se borra.

🗣️ **2 minutos:** También la adopción (cuántos equipos la usan por elección), el soporte que
requiere, la divergencia entre servicios generados y cuántos aplican las actualizaciones. El código
borrado es especialmente revelador: si todos eliminan las mismas piezas, sobran; si todos añaden lo
mismo, falta.

🔬 **El detalle:** Más archivos generados no es éxito. Una plantilla que genera mucho y obliga a
borrar mucho cuesta más que no tener plantilla.

### 14. 🟡 ¿Por qué un repository genérico suele ser mala generación por defecto?

⏱️ **30 segundos:** Porque copia una API CRUD sin expresar ninguna necesidad de negocio.

🗣️ **2 minutos:** Un `Repository<T>` generado con `findAll`, `findById`, `save` y `delete` fuerza
métodos y abstracciones antes de conocer los casos de uso: el equipo empieza a usar lo que existe
(incluido `delete`, aunque el negocio nunca borre) en lugar de diseñar lo que necesita. Además
tiende a reflejar el ORM, y es difícil de retirar una vez que hay código que depende de él.

🔬 **El detalle:** Se crea un puerto cuando aparece su consumidor: el primer caso de uso que necesita
persistir define qué métodos tiene y cómo se llaman.

### 15. 🟡 ¿Qué cambia al aparecer un segundo driver?

⏱️ **30 segundos:** Aumenta el valor de tener un puerto de entrada estable y un caso de uso
independiente del transporte.

🗣️ **2 minutos:** Si HTTP y ahora también una cola necesitan crear pedidos, la lógica que vivía en
el handler tiene que moverse a un caso de uso que ambos adaptadores invoquen, o se duplicará. Es el
momento de introducir el comando propio, la idempotencia común y la traducción de errores por
transporte. HTTP y mensajería reutilizan el mismo caso de uso.

🔬 **El detalle:** Es una señal de revisión, no una obligación automática: si el segundo driver es
trivial y temporal, puede bastar con extraer una función compartida.

### 16. 🟡 ¿Cuándo eliminas una abstracción generada?

⏱️ **30 segundos:** Cuando no protege ningún cambio ni hace posible ninguna prueba útil.

🗣️ **2 minutos:** Si una interfaz generada tiene una sola implementación que nunca se sustituye, si
un mapper traduce entre tipos idénticos o si todos los equipos la borran después de generar,
simplifico: la elimino del servicio y, si el patrón se repite, de la plantilla. Cada abstracción sin
propósito añade navegación, mantenimiento y confusión sobre cuáles son las fronteras reales.

🔬 **El detalle:** Conservo la dirección de dependencias después de eliminarla: quitar una interfaz
no autoriza a que el núcleo importe la infraestructura.

### 17. 🟠 Un CRUD interno nace con outbox, broker y veinte interfaces. ¿Qué simplificas?

⏱️ **30 segundos:** Elimino las capacidades que no responden a ningún riesgo ni requisito actual.

🗣️ **2 minutos:** Si nadie consume sus eventos, la outbox y el broker sobran: son una tabla, un
dispatcher y un sistema más que operar. Las interfaces sin segunda implementación ni frontera real,
también. Mantengo handler, aplicación simple, persistencia directa y los controles operativos de la
plantilla (build, configuración, health, logs). El servicio queda más barato de entender y de
operar.

🔬 **El detalle:** Documento las señales que justificarían reintroducirlas: el primer consumidor de
eventos, una regla volátil, una integración externa.

### 18. 🟠 Un servicio de pagos crítico usa handler y SQL directo. ¿Dónde compras fronteras primero?

⏱️ **30 segundos:** En el caso de uso, el puerto de cobros, la transacción y la idempotencia.

🗣️ **2 minutos:** Extraigo `AuthorizePayment` como caso de uso con sus reglas, aíslo al proveedor
detrás de `PaymentGateway` con resultados propios (incluido el incierto), pongo la persistencia
detrás de un puerto dentro de una unidad de trabajo, y añado idempotencia con una clave estable
persistida. Son las fronteras donde una falla duplica o pierde dinero.

🔬 **El detalle:** Agrego contratos y pruebas de incertidumbre: timeout del proveedor, caída entre
commit y respuesta, reintento con la misma clave. Son las pruebas que más valor tienen en un
servicio de pagos.

### 19. 🟠 Cada equipo copia una versión distinta del template. ¿Qué capacidad de plataforma falta?

⏱️ **30 segundos:** Versionado de la plantilla y un camino de actualización central.

🗣️ **2 minutos:** Hace falta un catálogo (Backstage o equivalente) que muestre la versión vigente,
sus cambios y qué versión usa cada servicio, y una forma automatizada de proponer actualizaciones
(un PR generado con los cambios de la plantilla). Así las mejoras de seguridad y de operación llegan
a todos los servicios, y la divergencia se ve.

🔬 **El detalle:** No fuerzo actualizaciones sin compatibilidad probada: una actualización de
plantilla que rompe servicios destruye la confianza en ella más rápido que no actualizar.

### 20. 🟠 El template incluye secretos de ejemplo funcionales. ¿Qué corriges?

⏱️ **30 segundos:** Los retiro, los sustituyo por placeholders no sensibles y roto cualquier secreto
que haya estado expuesto.

🗣️ **2 minutos:** Un secreto de ejemplo que funciona acaba en producción en algún servicio, y está
en el historial de cada repositorio generado. Uso valores que obviamente no funcionan y hago que la
aplicación falle al arrancar si detecta un placeholder. La generación debe integrar el gestor de
secretos de la organización y la validación de configuración al arrancar.

🔬 **El detalle:** Roto cualquier secreto ya expuesto, porque está en el historial de git de todos
los servicios generados, y reviso si algún servicio lo usa en producción.

### 21. 🟠 Todos borran tres módulos después de generar. ¿Qué evidencia te da?

⏱️ **30 segundos:** Que esos módulos son ceremonia sin valor por defecto.

🗣️ **2 minutos:** Si nadie los conserva, la plantilla está imponiendo algo que los equipos no
necesitan, y cada servicio paga el coste de borrarlos (o, peor, de conservarlos sin usarlos). En la
próxima versión los quito o los vuelvo opcionales (una opción al generar). Si algún equipo sí los
necesita, quedan disponibles bajo demanda.

🔬 **El detalle:** Mido antes de conservar por tradición: la plantilla debe reflejar lo que los
servicios realmente usan, no lo que alguien pensó que usarían.

### 22. 🟠 Una regla cambia en cinco archivos de transporte y persistencia. ¿Qué profundidad revisarías?

⏱️ **30 segundos:** Pasaría a una separación selectiva: un caso de uso y un dominio donde vive esa
regla.

🗣️ **2 minutos:** Que una regla esté repartida en cinco archivos de adaptadores es la señal de que
la profundidad directa ya no basta para esa capacidad. Centralizo la política en un caso de uso y,
si tiene invariantes, en el dominio, y dejo en los adaptadores solo la traducción. El siguiente
cambio de esa regla toca un archivo y su prueba.

🔬 **El detalle:** No necesito rehacer los módulos no relacionados: la separación selectiva se aplica
donde está el dolor, y el resto del servicio puede seguir directo.

### 23. 🟠 El equipo quiere conservar un mapper idéntico “por pureza”. ¿Cómo decides?

⏱️ **30 segundos:** Preguntando qué evolución o qué riesgo protege ese mapper.

🗣️ **2 minutos:** Si traduce entre dos tipos idénticos que cambian siempre juntos, no protege nada:
cuesta mantenerlo y es un lugar más donde olvidar un campo. Si no hay una diferencia real ni
prevista, lo elimino con una fecha de revisión. Si protege algo concreto —un contrato público que no
debe exponer campos internos—, lo conservo aunque hoy sea idéntico, y lo documento.

🔬 **El detalle:** La pureza sin independencia no paga su mantenimiento. La pregunta no es si es
"correcto" tener un mapper, sino qué cambio evita.

### 24. 🟠 ¿Cómo defenderías una arquitectura deliberadamente simple en una entrevista senior?

⏱️ **30 segundos:** Relacionando cada capa ausente con el riesgo y el coste que evaluaste, y con la
señal que te haría añadirla.

🗣️ **2 minutos:** "Este servicio no tiene puertos de entrada porque solo tiene HTTP; no tiene outbox
porque nadie consume sus eventos; el dominio sí está separado del ORM porque las reglas de precios
cambian cada mes." Explico que la dirección de dependencias se conserva, que hay pruebas de las
reglas y una regla de imports, y cuáles son las señales que harían evolucionar el diseño.

🔬 **El detalle:** Seniority incluye saber no introducir abstracciones. En entrevista, justificar una
ausencia con criterio suele pesar más que enumerar todos los patrones que se podrían aplicar.

---

## 07 · Simulación de entrevista

### S1. 🟢 ¿Qué regla permanece igual entre Java, Node/TS, Go y Python?

⏱️ **30 segundos:** Que las dependencias de código apuntan hacia la política: el núcleo define sus
contratos y los detalles se adaptan a ellos.

🗣️ **2 minutos:** Cambian las interfaces (nominales, estructurales, implícitas, protocolos), la
composición (beans, tokens, constructores, fábricas), las transacciones (proxy, callback, `sql.Tx`,
context manager) y la validación en runtime. Pero en los cuatro, `CreateOrder` declara qué necesita,
un adaptador lo implementa, un composition root los conecta y el núcleo compila y se prueba sin
infraestructura.

🔬 **El detalle:** No copio una estructura de paquetes idéntica para demostrarlo: cada plataforma
organiza el código a su manera, y lo que se verifica es la dirección, con la herramienta de reglas
de dependencia de cada una.

### S2. 🟢 ¿Qué aporta Spring y qué debes seguir decidiendo?

⏱️ **30 segundos:** Aporta composición, proxies transaccionales, web, persistencia y soporte de
pruebas; tú decides los límites y los contratos.

🗣️ **2 minutos:** Spring resuelve el grafo de objetos, abre transacciones declarativas, expone HTTP,
simplifica JPA y ofrece test slices. Pero las anotaciones implementan mecanismos: no dicen si
`CreateOrder` depende de JPA, si la transacción cubre la unidad correcta, si el controller contiene
reglas o si el puerto de pagos copia el SDK. Esas decisiones siguen siendo del equipo.

🔬 **El detalle:** El framework acelera los detalles, no define el dominio. Un proyecto Spring puede
ser perfectamente hexagonal o perfectamente acoplado; la diferencia no está en Spring.

### S3. 🟢 ¿Qué riesgo añade TypeScript al recibir JSON?

⏱️ **30 segundos:** Que los tipos se borran en runtime y dan una falsa sensación de que el dato ya
está validado.

🗣️ **2 minutos:** Declarar el cuerpo como `CreateOrderDto` no inspecciona nada: un campo ausente
llega como `undefined` y un número como string, y el compilador no puede avisar porque nunca vio el
dato. Valido en el adaptador con un esquema o un pipe y construyo comandos propios con los datos ya
comprobados. Las interfaces protegen la coherencia interna del código, no los payloads.

🔬 **El detalle:** No uso `as` como validación: un *type assertion* silencia al compilador sin
comprobar nada, y es la forma más rápida de meter un `undefined` en una regla.

### S4. 🟢 ¿Qué ventaja tienen las interfaces implícitas de Go?

⏱️ **30 segundos:** Que una implementación satisface el contrato sin herencia ni declaración, así
que el consumidor puede definir exactamente lo que necesita.

🗣️ **2 minutos:** El caso de uso declara una interfaz pequeña en su paquete; el adaptador la cumple
por tener los métodos, sin importar ese paquete. Eso favorece contratos mínimos, fakes pequeños y
composición explícita en `main`. Aun así, se pueden crear abstracciones innecesarias: una interfaz
por struct "por si acaso" es tan ceremonial en Go como en Java.

🔬 **El detalle:** La interfaz suele vivir junto a quien la usa, no junto a quien la implementa: es
la convención que hace que el mecanismo implícito rinda.

### S5. 🟢 ¿Qué diferencia hay entre un `Protocol` de Python y validación runtime?

⏱️ **30 segundos:** El `Protocol` ayuda al tipado estático; no valida datos al ejecutar.

🗣️ **2 minutos:** Un `Protocol` expresa la colaboración interna —qué métodos debe tener un puerto—
para que mypy o pyright lo comprueben y para escribir dobles. Pydantic o un parser en el borde
validan la entrada: comprueban en ejecución que el JSON tiene la forma esperada y rechazan lo que
no. Son herramientas para problemas distintos y se usan juntas.

🔬 **El detalle:** El duck typing no elimina la necesidad de contratos claros: precisamente porque
Python acepta cualquier objeto con los métodos adecuados, conviene que esos métodos estén definidos
y probados.

### S6. 🟢 ¿Dónde se fija la baseline de versiones del corpus?

⏱️ **30 segundos:** En el capítulo comparativo del bloque 05 (05/01), con su fecha y las fuentes
primarias enlazadas.

🗣️ **2 minutos:** Allí se fija una vez: Java 25 con Spring Boot 4.1, Node 24 con TypeScript 6, Go
1.27 y Python 3.14, a una fecha concreta. Los capítulos de plataforma parten de esa baseline y no
repiten afirmaciones sobre versiones como si fueran eternas. Si una versión cambia, se actualiza en
un lugar.

🔬 **El detalle:** En una entrevista conviene distinguir el concepto estable (la regla de
dependencias, el proxy transaccional) del detalle de versión (qué API existe en qué release): el
primero dura años; el segundo, meses.

### S7. 🟢 ¿Qué debe contener una plantilla de servicio mínima?

⏱️ **30 segundos:** Build, salud, configuración segura, logs, pruebas y una costura de ejemplo que
se elimina al empezar.

🗣️ **2 minutos:** Pipeline de build y pruebas, lint y regla de dependencias, configuración tipada
validada al arrancar, health y readiness, logs estructurados sin secretos, métricas base, cierre
ordenado y una prueba de arranque. Automatiza los controles repetibles sin inventar puertos, outbox
ni dominios que el servicio todavía no necesita.

🔬 **El detalle:** Las capacidades avanzadas (outbox, mensajería, cliente de pagos con resiliencia)
pueden ser opciones al generar, estandarizadas, pero no impuestas por defecto.

### S8. 🟡 ¿Cómo eliges entre DI automática y wiring explícito?

⏱️ **30 segundos:** Por el tamaño del grafo, la complejidad del ciclo de vida, la legibilidad y el
soporte del ecosistema.

🗣️ **2 minutos:** Spring o Nest reducen el cableado y se integran con transacciones, seguridad y
web; en grafos grandes compensan. Go o Python pueden componer directamente en una función: más
visible, sin magia, con errores en compilación o al arrancar. En ambos casos necesito un composition
root identificable y una prueba de arranque que confirme que el grafo real se resuelve.

🔬 **El detalle:** La elección no cambia quién debe definir el puerto: con cualquiera de las dos se
puede inyectar el SDK en el dominio.

### S9. 🟡 ¿Qué diferencia transaccional debes explicar entre las cuatro plataformas?

⏱️ **30 segundos:** Cómo se propaga el contexto transaccional y qué llamadas participan en la misma
transacción.

🗣️ **2 minutos:** Spring usa proxies y asocia la transacción al hilo: los repositorios la comparten
sin pasarla, pero la self-invocation la esquiva. Node suele pasar el cliente transaccional o
guardarlo en `AsyncLocalStorage`; usar el cliente raíz la rompe. Go usa `sql.Tx` explícito, por
parámetro o en el `context`; usar el pool la rompe. Python usa una sesión o un context manager;
compartir la sesión entre tareas la rompe.

🔬 **El detalle:** Ningún mecanismo incluye automáticamente servicios remotos: en los cuatro, una
llamada HTTP dentro de la transacción no participa del commit.

### S10. 🟡 ¿Cómo evitas que `context.Context` contamine el dominio en Go?

⏱️ **30 segundos:** Pasándolo por los límites de aplicación y de I/O, no por entidades ni value
objects.

🗣️ **2 minutos:** El contexto transporta cancelación, deadline y valores de alcance de la petición:
lo reciben el caso de uso, los adaptadores y los repositorios, que lo obedecen en sus operaciones de
I/O. Las reglas puras del dominio no hacen I/O, así que reciben datos explícitos (incluido el
instante actual si lo necesitan) y no el contexto.

🔬 **El detalle:** No lo uso como bolsa de dependencias: repositorios, loggers y configuración van
por constructor, no guardados en el contexto.

### S11. 🟡 ¿Cómo evitas scope global accidental en Node/NestJS?

⏱️ **30 segundos:** Declarando el ciclo de vida de cada provider y sin usar un service locator
dentro de los casos de uso.

🗣️ **2 minutos:** Los providers singleton solo guardan estado seguro de compartir (clientes,
configuración), nunca datos de una petición. Las transacciones y el contexto de la petición se
propagan de forma controlada: por parámetro o con `AsyncLocalStorage` para lo técnico. El actor
viaja en el comando. Si un provider necesita estado por petición, se declara con scope de petición y
se entiende su coste.

🔬 **El detalle:** Una inyección correcta en tipos puede fallar por scope en runtime: el compilador
no sabe que un singleton está guardando el usuario de la primera petición.

### S12. 🟡 ¿Qué prueba de Spring no reemplaza una prueba de dominio?

⏱️ **30 segundos:** Una prueba que levanta el contexto y verifica el wiring, como `@SpringBootTest`.

🗣️ **2 minutos:** Sirve para comprobar la composición, los proxies y la configuración: que los beans
se resuelven, que las transacciones se abren donde se espera. Pero las invariantes del dominio deben
probarse de forma rápida y directa, sin Spring: construir un `Order`, ejecutar una transición y
comprobar el resultado. Son dos preguntas distintas con dos herramientas distintas.

🔬 **El detalle:** Cargar el contexto para todo oculta el límite (el dominio parece depender de
Spring aunque no lo haga) y ralentiza el feedback hasta que el equipo deja de ejecutar las pruebas.

### S13. 🟡 ¿Qué coste tiene usar modelos Pydantic como dominio en Python?

⏱️ **30 segundos:** Acopla la validación y la serialización externas a las reglas internas.

🗣️ **2 minutos:** El modelo Pydantic hace coerción, sigue la forma del contrato externo y cambia
cuando cambia la API; si es también el dominio, las reglas cambian con él, y los invariantes de
negocio se mezclan con las reglas de formato. Puede ser razonable en un CRUD donde el contrato es el
modelo. Si el modelo evoluciona distinto, creo comandos y tipos de dominio propios (dataclasses) y
dejo Pydantic en el borde.

🔬 **El detalle:** La separación se justifica por cambios reales, no por rechazo al framework.
Pydantic es excelente para lo que hace: validar datos externos.

### S14. 🟡 ¿Cómo manejas errores como valores en Go sin perder causa?

⏱️ **30 segundos:** Envolviendo con contexto mediante `%w` y clasificando con `errors.Is` o
`errors.As`.

🗣️ **2 minutos:** El adaptador traduce los errores del driver a errores sentinela o tipos propios
(`ErrOrderNotFound`, `*ConflictError`), envolviendo la causa original; el caso de uso decide con
esos errores propios; el handler los traduce a status con `errors.Is`; y los logs conservan la
cadena completa. Cada capa añade contexto sin destruir la información de la anterior.

🔬 **El detalle:** Comparar textos de error rompe contratos: un mensaje mejorado o traducido cambia
el comportamiento del programa.

### S15. 🟡 ¿Cuándo elegirías una arquitectura más profunda para el mismo servicio?

⏱️ **30 segundos:** Con reglas valiosas, varias entradas o salidas, volatilidad o un alto coste de
fallo.

🗣️ **2 minutos:** El lenguaje no decide la profundidad: un servicio de pagos merece fronteras
completas en Java y en Go, y un CRUD interno puede ser directo en ambos. Lo que cambia entre
plataformas es el coste de sostener módulos, mappers y contratos: más ceremonia en unos, más
disciplina manual en otros. El equipo y su tooling también cuentan.

🔬 **El detalle:** La decisión se revisa cuando cambian las señales: una segunda entrada, una regla
volátil, un proveedor nuevo.

### S16. 🟡 ¿Qué métrica te dice que una plantilla está sobrecargada?

⏱️ **30 segundos:** Cuánto código generado se elimina, se evita o se queda sin usar.

🗣️ **2 minutos:** Si los equipos borran sistemáticamente los mismos módulos después de generar, o
los dejan sin usar, la plantilla impone ceremonia. También observo el tiempo hasta producción de un
servicio nuevo, los fallos de configuración que la plantilla debía evitar y la divergencia entre
servicios generados, que indica que cada equipo la adapta a su manera.

🔬 **El detalle:** La popularidad de la plantilla no prueba que cada módulo aporte valor: puede
usarse por obligación y borrarse a medias.

### S17. 🟠 Java usa interfaces para cada clase y Go no usa ninguna. ¿Cuál es más hexagonal?

⏱️ **30 segundos:** Ninguno por esa razón: no se decide por cantidad de interfaces, sino por las
fronteras y la dirección de dependencias.

🗣️ **2 minutos:** El Java con una interfaz por clase puede tener puertos espejo del ORM y un dominio
acoplado; el Go sin interfaces puede tener el dominio mezclado con SQL, o puede tener contratos
implícitos bien puestos si usa funciones como parámetros. Comparo qué cambios protege cada diseño,
qué importa el núcleo y si el núcleo se prueba sin infraestructura.

🔬 **El detalle:** La sintaxis del lenguaje no reemplaza al diseño. Las interfaces son una
herramienta para expresar puertos, no una medida de arquitectura.

### S18. 🟠 NestJS inyecta Prisma directamente en el caso de uso. ¿Qué argumento das?

⏱️ **30 segundos:** Que la inyección existe, pero el contrato sigue perteneciendo a la persistencia:
el caso de uso depende de Prisma.

🗣️ **2 minutos:** El caso de uso conoce el esquema, los tipos generados, los errores de Prisma y la
forma de las transacciones; probarlo exige simular Prisma o una base. Creo un puerto propio si
necesito proteger consultas, errores o transacciones de cambios del ORM, o probar la regla sin base.
En un CRUD estable puedo aceptar el acoplamiento, documentado.

🔬 **El detalle:** No añado un wrapper que solo renombre cada método de Prisma: si el puerto copia la
API del cliente, el acoplamiento sigue ahí con un archivo más.

### S19. 🟠 Un método `@Transactional` se llama desde el mismo bean. ¿Qué verificas?

⏱️ **30 segundos:** Si la invocación atraviesa el proxy y si la transacción se abre de verdad.

🗣️ **2 minutos:** Con el modo proxy, la llamada interna no pasa por el interceptor, así que la
anotación del método llamado no tiene efecto. Lo pruebo con una integración que provoque un fallo y
compruebe qué quedó confirmado. Si confirma el problema, muevo la demarcación a una fachada invocada
desde otro bean, o uso `TransactionTemplate` de forma programática.

🔬 **El detalle:** La anotación visible no garantiza el comportamiento: solo una prueba contra el
recurso real lo demuestra.

### S20. 🟠 Una coroutine de Python usa una sesión sync compartida. ¿Qué riesgo señalas?

⏱️ **30 segundos:** Bloqueo del event loop, concurrencia insegura sobre la sesión y un ciclo de vida
incorrecto.

🗣️ **2 minutos:** Las llamadas síncronas detienen el event loop y todas las demás tareas esperan;
varias coroutines comparten el estado de la misma sesión y sus transacciones se mezclan; y nadie
sabe cuándo se cierra. Elijo una cadena async coherente (driver y sesión async, una por unidad de
trabajo) o aíslo el trabajo síncrono en un pool de hilos, y el composition root crea los scopes
adecuados.

🔬 **El detalle:** La firma `async def` no vuelve no bloqueante a un driver síncrono: solo lo
esconde.

### S21. 🟡 ¿Debe una plantilla imponer outbox a todos los servicios?

⏱️ **30 segundos:** No. Debe ofrecerla para los servicios que publican eventos ligados a un commit,
no imponerla a todos.

🗣️ **2 minutos:** Incluir por defecto la tabla, el dispatcher, las métricas y la limpieza añade
operación a CRUDs que no publican nada. Un módulo opcional y estandarizado en la plantilla permite
que quien la necesite la adopte bien hecha, sin reinventarla. El valor de la plantilla está en que
la solución sea correcta cuando se usa, no en que esté en todas partes.

🔬 **El detalle:** El control crítico es no hacer doble escritura ingenua cuando sí aplica: la
plantilla puede incluir una regla o una revisión que lo detecte.

### S22. 🟡 ¿Cuándo usarías una clase abstracta en vez de interfaz o protocolo?

⏱️ **30 segundos:** Cuando hay comportamiento compartido real y una relación de herencia estable, no
solo para declarar un puerto.

🗣️ **2 minutos:** Una clase base puede tener sentido para compartir la mecánica común de varios
adaptadores (reintentos, métricas) si todos la necesitan igual. Pero los puertos suelen requerir
solo un contrato mínimo; una base con estado o con métodos implementados acopla las implementaciones
entre sí y con decisiones que quizá no compartan.

🔬 **El detalle:** La herramienta sigue a la necesidad, no al idioma de otra plataforma: en Python,
un `Protocol`; en Go, una interfaz; en Java, una interfaz. La herencia, para comportamiento
compartido.

### S23. 🟠 ¿Cómo comparas ergonomía sin convertirla en una guerra de lenguajes?

⏱️ **30 segundos:** Separando qué da hecho cada ecosistema, qué deja explícito y qué errores
facilita, sobre el mismo problema.

🗣️ **2 minutos:** Tomo el mismo flujo de pedido y comparo por ejes: composición (contenedor frente a
constructores), tipos (runtime frente a borrados), transacción (proxy frente a `Tx` explícito),
contexto (hilo frente a parámetro), pruebas y build. Cada plataforma resuelve algo y deja algo al
equipo, y cada una facilita errores distintos (self-invocation, tipos borrados, `db` fuera del `tx`,
sesión global).

🔬 **El detalle:** La decisión incluye las capacidades del equipo y la operación: la mejor plataforma
técnica para un problema puede ser la peor para un equipo que no la domina.

### S24. 🟠 ¿Qué haces cuando el generador produce código que nadie entiende?

⏱️ **30 segundos:** Reduzco los valores por defecto y hago visibles la composición y las fronteras
esenciales.

🗣️ **2 minutos:** Una plantilla debe acelerar decisiones repetibles, no ocultarlas. Si el código
generado tiene capas, metadatos o convenciones que el equipo no sabe explicar, no podrán mantenerlo
ni cambiarlo. Simplifico: menos piezas, composición explícita, comentarios donde haga falta, y
documento cómo extenderlo, cómo actualizarlo desde la plantilla y cómo retirar lo que no se use.

🔬 **El detalle:** El código generado sin ownership se vuelve una dependencia externa local: nadie lo
toca por miedo, y todo el mundo trabaja alrededor de él.

### S25. 🟠 ¿La validación runtime debe repetirse en cada plataforma?

⏱️ **30 segundos:** Sí, en cada borde y con su mecanismo propio; las invariantes siguen siendo
conceptualmente comunes.

🗣️ **2 minutos:** Bean Validation en Java, esquemas en TypeScript, decodificación estricta y
validadores en Go, Pydantic en Python: cada adaptador comprueba la forma de lo que recibe con la
herramienta de su ecosistema. Después, el dominio de cada implementación vuelve a proteger el estado
válido. Lo que debe ser común es el contrato (el OpenAPI, el esquema del evento), no la biblioteca.

🔬 **El detalle:** No comparto una librería multiplataforma solo para evitar expresar el límite: el
contrato compartido es el documento, y cada plataforma lo implementa con sus herramientas.

### S26. 🟠 Un CRUD pequeño generado trae repositorio genérico, outbox, broker y doce mappers. ¿Qué quitas?

⏱️ **30 segundos:** Todo lo que no protege un cambio o un control vigente, conservando una ruta
modular y las pruebas.

🗣️ **2 minutos:** Quito el broker y la outbox si nadie consume eventos, el repositorio genérico en
favor del acceso directo o de un puerto mínimo, y los mappers que traducen tipos idénticos. Empiezo
con handler y caso de uso simple, persistencia clara, configuración segura y observabilidad básica.
Registro las señales que justificarían volver a añadir cada pieza.

🔬 **El detalle:** La plantilla debe hacer opcional la profundidad, no normalizar la ceremonia. Si
muchos servicios hacen esta limpieza, el problema es de la plantilla.

### S27. 🟠 Debes elegir plataforma para un equipo Java con alta regulación y dominio complejo. ¿Qué priorizas?

⏱️ **30 segundos:** La capacidad del equipo, límites verificables, pruebas y operación, antes que la
novedad.

🗣️ **2 minutos:** Un equipo Java con experiencia es un activo: Spring puede acelerar controles,
seguridad, auditoría y composición, siempre que el núcleo quede aislado. Módulos de build separados
y pruebas de arquitectura con ArchUnit ayudan a que la frontera se cumpla, y el ecosistema tiene
buen soporte para trazabilidad y cumplimiento. Cambiar de plataforma añadiría riesgo sin resolver el
problema principal.

🔬 **El detalle:** La elección de plataforma no compensa un modelo de negocio mal delimitado: en un
dominio complejo, el riesgo mayor está en el modelado, no en el lenguaje.

### S28. 🟠 En Spring, una transacción no inicia por self-invocation. ¿Cómo corriges sin mover la regla al framework?

⏱️ **30 segundos:** Muevo la demarcación a una fachada invocada a través del proxy, o uso una
composición transaccional explícita.

🗣️ **2 minutos:** Una clase de aplicación anotada con `@Transactional` invoca al caso de uso, que
sigue siendo Java ordinario; o un decorador usa `TransactionTemplate` alrededor de la ejecución. El
caso de uso conserva la coordinación y el dominio las reglas, sin anotaciones. Una prueba de
integración provoca un fallo y verifica que el rollback es real.

🔬 **El detalle:** También reviso que ninguna llamada remota haya quedado dentro de la transacción al
mover la demarcación: es fácil ampliar el límite sin darse cuenta.

### S29. 🟠 TypeScript compila, pero un payload inválido produce `undefined` dentro del dominio. ¿Qué frontera faltó?

⏱️ **30 segundos:** La validación en runtime y el mapeo en el adaptador de entrada.

🗣️ **2 minutos:** El adaptador confió en el tipo declarado del cuerpo. Añado un esquema que rechace
la forma inválida con un error del contrato, construyo un comando tipado solo con datos validados y
dejo las invariantes en el dominio, que además debería rechazar el `undefined` al construir el
objeto. Pruebo con el JSON real enviado al adaptador, no con objetos construidos en el test.

🔬 **El detalle:** Los tipos estáticos no convierten datos externos en confiables. Esa conversión la
hace el código de validación, y sin él los tipos mienten.

### S30. 🟠 En Go hay veinte interfaces de un método y en Python todo usa globals. ¿Cómo equilibras?

⏱️ **30 segundos:** En ambos casos, diseñando contratos solo en las fronteras reales y haciendo
visible la composición.

🗣️ **2 minutos:** En Go, elimino las interfaces preventivas que nadie sustituye y dejo las que el
consumidor necesita, declaradas junto a él. En Python, sustituyo los globales por dependencias
inyectadas desde una app factory y uso `Protocol` solo donde mejora la claridad o las pruebas. Son
excesos opuestos —demasiada abstracción y demasiado poca— con la misma corrección: fronteras donde
hay razones de cambio.

🔬 **El detalle:** La meta no es igualar la sintaxis entre lenguajes, sino hacer explícitas las
razones de cambio y la dirección de dependencias en cada uno.

---

**Siguiente:** [índice del bloque](README.md) · [Talleres (opcional) →](../06-talleres/README.md)
