# A03 — Catálogo de errores y diagnóstico

> **Objetivo:** que reconozcas la primera línea antes de saber la causa. Este es el apéndice
> que se abre a las dos de la mañana: buscas el texto que tienes en pantalla, lees qué lo
> provoca de verdad, corres el comando que lo confirma y aplicas la corrección.
> **Asume:** nada. Cada entrada es autosuficiente y enlaza al documento donde el curso
> reproduce ese fallo.
> **Vigencia:** 18 de septiembre de 2026 · Spring Boot 3.5.16 · Spring Framework 6.2.19 · Java 21 (Temurin) · Hibernate ORM 6.6 · Resilience4j 2.2.0.

**Salto rápido:** [Cómo se usa](#1--cómo-se-usa-este-catálogo) ·
[Índice por síntoma](#2--índice-por-síntoma) ·
[El contexto que no arranca](#3--el-contexto-que-no-arranca) ·
[Proxies](#4--proxies-la-anotación-que-no-hace-nada) ·
[El borde web](#5-️-el-borde-web-el-código-de-estado-que-miente) ·
[Datos y transacciones](#6--datos-y-transacciones) ·
[Caché y asincronía](#7--caché-y-asincronía) ·
[Clientes, resiliencia y reactivo](#8--clientes-resiliencia-y-reactivo) ·
[Actuator](#9--actuator-y-observabilidad) ·
[Lo que el curso todavía no reproduce](#10-️-lo-que-el-curso-todavía-no-reproduce) ·
[Preguntas rápidas](#-preguntas-rápidas) ·
[Ejercicios](#-ejercicios-12)

---

## 1. 🧭 Cómo se usa este catálogo

Este apéndice no se escribió: se **recolectó**. Cada primera línea que vas a leer aquí salió
de un documento del curso donde el fallo se provocó a propósito, y el enlace del final de
cada entrada te lleva al sitio donde está la reproducción completa, con su comando y su
corrección verificada. Si una entrada te sabe a poco, ahí está el desarrollo.

Todas las entradas tienen la misma forma, siempre en el mismo orden, para que a las dos de
la mañana no tengas que leer nada que no necesites:

```text
primera línea literal  →  qué la causa de verdad  →  el comando o log que lo confirma
                       →  la corrección  →  cómo se evita  →  dónde se reproduce
```

Antes de bajar a una entrada concreta, el triaje. Son tres preguntas, en este orden, y
casi siempre bastan las dos primeras:

| Pregunta | Si la respuesta es sí | Si la respuesta es no |
|---|---|---|
| ¿Hay un bloque `Description:` / `Action:`? | La respuesta está en `Action:`; no bajes al trace | Hay stack trace: baja al **último** `Caused by:` |
| ¿La aplicación llegó a arrancar? | El fallo es de runtime: secciones 4 a 9 | El fallo es de contexto: sección 3 |
| ¿Hay alguna excepción? | Búscala en el índice de abajo | Es un **silencio**: sección 4, y después 6 y 7 |

- **El bloque `Description:` / `Action:`** es la firma de un `FailureAnalyzer`: alguien
  tradujo la excepción cruda a un mensaje accionable, y por eso no ves stack trace. Que no
  lo haya **también es información** ([`06` §10](06-arranque-y-autoconfiguracion.md#10--cuando-el-arranque-falla)).
- **El último `Caused by:`** es la excepción original; la primera de la cadena es el
  envoltorio del contenedor y casi nunca dice nada útil. El procedimiento completo para leer
  un trace de Spring —dónde está tu línea entre cuarenta frames de proxy— está en
  [`A01` §11](a01-cli-y-tooling-de-supervivencia.md#11--cómo-leer-un-stack-trace-de-spring).
- **La tercera fila es la importante de este curso.** El fallo más caro de Spring no lanza
  nada: el `@Transactional` que no hace rollback, el `@Cacheable` que nunca acierta, el
  `@Async` que corre en el hilo del llamante. Por eso este catálogo incluye entradas **sin
  excepción**, y son las que hay que leer con más calma.

> **🧠 Modelo mental.** Casi todo lo declarativo de Spring —`@Transactional`, `@Cacheable`,
> `@Async`, `@Retryable`, `@Timed`— es el mismo mecanismo con distinto sombrero: un proxy que
> envuelve al bean por fuera. Cuando una de esas anotaciones "no hace nada", la primera
> pregunta no es sobre la anotación: es **¿pasó la llamada por el proxy?**

Los ejemplos usan los nombres fijos del laboratorio —`inv-api`, el paquete
`com.invlab.invapi`, las tablas `inventory_item` e `inventory_event`, el puerto `8080` para
la aplicación y el `8081` para Actuator—, declarados en
[`L00` §7](l00-idea-lab-practico.md#7--nombres-fijos-de-la-serie).

---

## 2. 🩺 Índice por síntoma

Para cuando tienes el texto delante y no sabes de qué familia es.

| Lo que ves | Entrada |
|---|---|
| `No qualifying bean of type` · `No bean named` | [`NoSuchBeanDefinitionException`](#nosuchbeandefinitionexception) |
| `required a single bean, but 2 were found` | [`NoUniqueBeanDefinitionException`](#nouniquebeandefinitionexception) |
| `form a cycle` con un diagrama de cajas | [`BeanCurrentlyInCreationException`](#beancurrentlyincreationexception) |
| `Unsatisfied dependency expressed through` | [`UnsatisfiedDependencyException`](#unsatisfieddependencyexception) |
| `Port 8080 was already in use` | [`PortInUseException`](#portinuseexception) |
| `Binding to target … failed` con `Origin` | [Binding de `@ConfigurationProperties`](#binding-de-configurationproperties) |
| `Could not resolve placeholder` | [Placeholder sin resolver](#placeholder-sin-resolver) |
| `Config data location … does not exist` | [`ConfigDataLocationNotFoundException`](#configdatalocationnotfoundexception) |
| `Cron expression must consist of 6 fields` | [Cron de cinco campos](#cron-de-cinco-campos) |
| `but was actually of type 'jdk.proxy2.$Proxy142'` | [`BeanNotOfRequiredTypeException`](#beannotofrequiredtypeexception) |
| `415` · `Content-Type … is not supported` | [`HttpMediaTypeNotSupportedException`](#httpmediatypenotsupportedexception) |
| `400` · `JSON parse error` | [`HttpMessageNotReadableException`](#httpmessagenotreadableexception) |
| `400` · `Validation failed for argument [0]` | [`MethodArgumentNotValidException`](#methodargumentnotvalidexception) |
| `500` en un `?limit=500` que creías validado | [`HandlerMethodValidationException` frente a `ConstraintViolationException`](#handlermethodvalidationexception-frente-a-constraintviolationexception) |
| `406` con cuerpo vacío | [`HttpMediaTypeNotAcceptableException`](#httpmediatypenotacceptableexception) |
| `No converter found capable of converting` | [`ConverterNotFoundException`](#converternotfoundexception) |
| `500` con tu propia excepción de dominio | [El 500 que miente](#el-500-que-miente) |
| `could not initialize proxy - no Session` | [`LazyInitializationException`](#lazyinitializationexception) |
| Un `422` correcto y las filas grabadas igual | [El rollback que no ocurre](#el-rollback-que-no-ocurre) |
| `Transaction silently rolled back` | [`UnexpectedRollbackException`](#unexpectedrollbackexception) |
| `HikariPool-1 - Connection is not available` | [`SQLTransientConnectionException` de Hikari](#sqltransientconnectionexception-de-hikari) |
| `no transaction is in progress` | [`TransactionRequiredException`](#transactionrequiredexception) |
| `DefaultSerializer requires a Serializable payload` | [`SerializationFailedException`](#serializationfailedexception) |
| La caché no registra ni `hit` ni `miss` | [El `@Cacheable` que nunca acierta](#el-cacheable-que-nunca-acierta) |
| `[nio-8080-exec-1]` o `[SimpleAsyncTaskExecutor-1]` donde esperabas `[inv-task-1]` | [El `@Async` sin pool](#el-async-sin-pool) |
| `[sin-request-id]` en un log posterior a la respuesta | [El contexto que no cruza de hilo](#el-contexto-que-no-cruza-de-hilo) |
| `I/O error on GET request … Read timed out` | [`ResourceAccessException`](#resourceaccessexception) |
| `WARN … No fallback method match found` | [El fallback que no existe](#el-fallback-que-no-existe) |
| `CircuitBreaker 'supplier' is OPEN` | [`CallNotPermittedException`](#callnotpermittedexception) |
| `Bulkhead 'supplier' is full` | [`BulkheadFullException`](#bulkheadfullexception) |
| `block()/blockFirst()/blockLast() are blocking` | [`IllegalStateException` en un hilo de Netty](#illegalstateexception-en-un-hilo-de-netty) |
| `404` en un endpoint de Actuator que sí expusiste | [Los tres `404` de Actuator](#los-tres-404-de-actuator) |
| `connect: connection refused` en un target | [El target de Prometheus que no responde](#el-target-de-prometheus-que-no-responde) |

---

## 3. 🧱 El contexto que no arranca

La buena noticia de esta familia entera: **falla al desplegar, no en producción**. Un
arranque que revienta es infinitamente mejor que uno que levanta a medias.

### `NoSuchBeanDefinitionException`

```text
No qualifying bean of type 'com.invlab.invapi.inventory.InventoryService' available
```

- **Qué la causa de verdad.** Casi nunca falta la anotación: **la clase está fuera del
  subárbol que se escanea**. `@SpringBootApplication` escanea su propio paquete y los de
  abajo, así que un `com.invlab.shared` colgando al lado de `com.invlab.invapi` no lo ve
  nadie. Las otras dos causas frecuentes son un `@ConfigurationProperties` sin
  `@ConfigurationPropertiesScan` —el error no menciona la configuración por ningún lado— y
  un `@Conditional` que evaluó `false`.
- **Cómo se confirma.** `--debug` o `/actuator/conditions`: si el bean es de una
  autoconfiguración, aparece en `negativeMatches` con la condición que no se cumplió; si es
  tuyo, `/actuator/beans` no lo lista y el problema es de escaneo.
- **La corrección.** Mover la clase al subárbol, o `@ComponentScan(basePackages = …)`, o
  —para una librería compartida— darle su propia autoconfiguración, que es lo correcto y lo
  que casi nadie hace. `@Import` es la cuarta salida y trae una `@Configuration` esté donde
  esté, sin abrir el escaneo.
- **Cómo se evita.** La clase de arranque vive en el paquete raíz del proyecto y todo lo
  demás cuelga de ahí. Es una decisión de estructura, no de anotaciones.
- **Dónde se reproduce.** [`02` §7](02-contenedor-ioc-y-ciclo-de-vida.md#7--component-scan-el-paquete-base)
  y, en su variante de `@ConfigurationProperties`,
  [`L02` §6](l02-configuracion-y-profiles.md#6--configurationproperties-con-record-y-el-arranque-que-se-rompe).
  El texto de arriba es el que arma `NoSuchBeanDefinitionException` en `spring-beans`
  6.2.19; la variante por nombre dice `No bean named 'x' available`.

### `NoUniqueBeanDefinitionException`

```text
***************************
APPLICATION FAILED TO START
***************************

Description:

Parameter 2 of constructor in com.invlab.invapi.startup.StartupSummary required a single bean, but 2 were found:
	- clock: defined by method 'clock' in class path resource [com/invlab/invapi/config/TimeConfig.class]
	- utcClock: defined by method 'utcClock' in class path resource [com/invlab/invapi/config/TimeConfig.class]

Action:

Consider marking one of the beans as @Primary, updating the consumer to accept multiple beans, or using @Qualifier to identify the bean that should be consumed
```

- **Qué la causa de verdad.** El contenedor resuelve **por tipo** y solo usa el nombre como
  desempate cuando el nombre del parámetro coincide con el de un bean. Dos candidatos del
  mismo tipo y un parámetro que no se llama como ninguno: empate y arranque abortado. El
  corolario incomoda y es exacto: **renombrar un parámetro puede romper —o arreglar— un
  arranque**.
- **Cómo se confirma.** `Parameter 2 of constructor` cuenta desde cero e identifica el punto
  de inyección exacto; debajo está la lista de candidatos con el método que los declaró. Con
  eso no hace falta nada más. Detrás del texto amable hay una excepción real,
  `NoUniqueBeanDefinitionException`, cuyo mensaje es `expected single matching bean but
  found 2: clock,utcClock` — y ese es el nombre que tienes que reconocer, porque el texto
  amable no siempre está.
- **La corrección.** `@Qualifier("utcClock")` en el punto de inyección cuando la decisión es
  local, `@Primary` en el bean cuando hay un ganador global, o aceptar `List<Clock>` cuando
  de verdad los quieres todos.
- **Cómo se evita.** Un `@Primary` desde el momento en que declaras el segundo bean de un
  tipo, no cuando aparece el tercer consumidor. Y no confiar nunca en el desempate por
  nombre, que es exactamente lo que hace que el fallo aparezca en el refactor de otro.
- **Dónde se reproduce.** [`L01` §12](l01-esqueleto-cli-y-autoconfiguracion.md#12--dos-fallos-de-arranque-provocados-a-propósito),
  con el mecanismo en [`03` §3](03-inyeccion-de-dependencias.md#3--cómo-elige-el-contenedor-entre-candidatos).

### `BeanCurrentlyInCreationException`

```text
The dependencies of some of the beans in the application context form a cycle:

┌─────┐
|  inventoryService defined in file [...]
↑     ↓
|  auditService defined in file [...]
└─────┘
```

- **Qué la causa de verdad.** `A` necesita `B` por constructor y `B` necesita `A`: el
  contenedor no puede construir ninguno de los dos. Desde Boot 2.6 esto **falla por defecto**,
  y el mensaje de la excepción subyacente lo dice sin rodeos: `Requested bean is currently in
  creation: Is there an unresolvable circular reference or an asynchronous initialization
  dependency?`.
- **Cómo se confirma.** El diagrama de cajas **es** la confirmación: nombra los beans del
  ciclo en orden. No hace falta subir ningún log.
- **La corrección.** Extraer lo compartido a un tercer bean, o darle la vuelta a la
  dependencia con un evento de aplicación. `@Lazy` en uno de los dos lados rompe el ciclo
  inyectando un proxy que resuelve al primer uso, y `spring.main.allow-circular-references=true`
  restaura el comportamiento viejo: las dos funcionan y ninguna arregla el diseño.
- **Cómo se evita.** Inyección por constructor en todo el proyecto. **Con inyección por campo
  el ciclo "funciona"** —el contenedor crea los dos objetos vacíos y rellena los campos
  después— y sigue ahí, invisible, hasta que alguien toca el orden de inicialización.
- **Dónde se reproduce.** [`03` §7](03-inyeccion-de-dependencias.md#7--dependencias-circulares).

### `UnsatisfiedDependencyException`

```text
Unsatisfied dependency expressed through constructor parameter 0
```

- **Qué la causa de verdad.** No es un error por sí misma: es el **envoltorio** con que el
  contenedor reporta que no pudo satisfacer un punto de inyección. La causa real está en el
  `Caused by:` y es casi siempre una de las tres anteriores. Su valor está en la primera
  mitad del mensaje, que nombra el parámetro o la propiedad exacta que no se pudo resolver.
- **Cómo se confirma.** Baja al último `Caused by:` de la cadena. Si dice `No qualifying bean
  of type`, tu problema es de escaneo o de condiciones; si dice `expected single matching
  bean but found`, es de ambigüedad; si dice `currently in creation`, es un ciclo.
- **La corrección.** La de la causa, nunca la del envoltorio.
- **Cómo se evita.** Leer la cadena de abajo arriba, siempre. Quien intenta corregir lo que
  dice la primera línea de un `UnsatisfiedDependencyException` pierde media tarde.
- **Dónde se reproduce.** El curso no la provoca aislada porque **siempre viene envolviendo a
  otra**; el texto de arriba es el que arma `spring-beans` 6.2.19 y el procedimiento de
  lectura es el de [`A01` §11](a01-cli-y-tooling-de-supervivencia.md#11--cómo-leer-un-stack-trace-de-spring).

### `PortInUseException`

```text
***************************
APPLICATION FAILED TO START
***************************

Description:

Web server failed to start. Port 8080 was already in use.

Action:

Identify and stop the process that's listening on port 8080 or configure this
application to listen on another port.
```

- **Qué la causa de verdad.** Otra instancia tuya sigue viva, casi siempre la del `kill %1`
  que olvidaste. Lo que el mensaje **no** dice es quién ocupa el puerto: eso lo averiguas tú.
- **Cómo se confirma.**

  ```bash
  lsof -i :8080 -sTCP:LISTEN
  ```

  - **`lsof -i :8080`** lista los procesos con ese puerto abierto; **`-sTCP:LISTEN`** filtra
    a los que escuchan y descarta las conexiones de cliente, que solo hacen ruido.
- **La corrección.** `kill <PID>` **sin `-9`**, que manda un `SIGTERM` y es lo que Boot
  convierte en apagado ordenado; o arrancar en otro puerto con
  `--server.port=9090 --management.server.port=9091`, que de paso demuestra que el argumento
  de línea de comandos gana al `application.yml`.
- **Cómo se evita.** Un `management.server.port` distinto del `server.port` **se paga dos
  veces**: si levantas una segunda instancia y solo mueves el 8080, el contexto de management
  muere con un `BindException: Address already in use` enterrado en el segundo arranque, no
  en la primera línea.
- **Dónde se reproduce.** [`L01` §12](l01-esqueleto-cli-y-autoconfiguracion.md#12--dos-fallos-de-arranque-provocados-a-propósito)
  y [`06` §10](06-arranque-y-autoconfiguracion.md#10--cuando-el-arranque-falla); la variante de
  los dos puertos, en [`L06` §5](l06-cache-y-asincronia.md#5-️-dos-instancias-dos-cachés-dos-verdades).

### Binding de `@ConfigurationProperties`

```text
***************************
APPLICATION FAILED TO START
***************************

Description:

Binding to target com.invlab.invapi.supplier.SupplierProperties failed:

    Property: inv.supplier.max-connections
    Value: "0"
    Origin: class path resource [application.yml] - 28:22
    Reason: must be greater than or equal to 1

Action:

Update your application's configuration
```

- **Qué la causa de verdad.** Un valor que viola una restricción de Bean Validation del
  `record` de propiedades. La excepción subyacente es `BindValidationException`, envuelta en
  `ConfigurationPropertiesBindException`, y sale entera con `--debug`.
- **Cómo se confirma.** **`Origin` es la joya del mensaje**: fichero, línea y columna del
  valor culpable, información que Boot conserva durante todo el enlace. `Reason` viene de
  Hibernate Validator y **sale en el idioma del `Locale` de la JVM**, así que para buscar en
  un runbook te fías de `Property`, nunca del texto.
- **La corrección.** Corregir el valor. Que el proceso termine con código de salida distinto
  de cero es una funcionalidad: **mejor no arrancar que arrancar con un pool de cero
  conexiones**.
- **Cómo se evita.** El fallo real es el contrario y es silencioso: **sin
  `spring-boot-starter-validation` en el classpath, `@Validated` no es un error ni un aviso,
  simplemente no hay quién valide** y el `0` entra tan campante. La dependencia se añade en
  el mismo commit que la primera restricción, y un test de arranque que verifique que un
  valor inválido **rompe** el contexto impide que alguien la quite sin enterarse.
- **Dónde se reproduce.** [`L02` §6](l02-configuracion-y-profiles.md#6--configurationproperties-con-record-y-el-arranque-que-se-rompe).

### Placeholder sin resolver

```text
Caused by: java.lang.IllegalArgumentException: Could not resolve placeholder 'inv.supplier.maxConnections' in value "${inv.supplier.maxConnections}"
```

- **Qué la causa de verdad.** `@Value` hace una **búsqueda literal de la clave**: sin
  canonicalización y sin relaxed binding. La clave del YAML es `max-connections` y el
  placeholder pide `maxConnections`; el mismo nombre que un `@ConfigurationProperties` enlaza
  sin despeinarse, para `@Value` no existe.
- **Cómo se confirma.** La propia excepción trae el nombre exacto que buscó. Si dudas de si
  la clave existe con otra forma, `/actuator/env/<clave>` te dice de qué fuente sale o si no
  sale de ninguna.
- **La corrección.** Escribir la clave exactamente como está en el fichero, o darle un
  default con `${inv.supplier.region:unknown}` — lo que va tras los dos puntos.
- **Cómo se evita.** `@Value` para un valor aislado y para cuando necesitas SpEL;
  `@ConfigurationProperties` para un grupo. La señal de que te pasaste son tres `@Value` con
  el mismo prefijo en la misma clase.
- **Dónde se reproduce.** [`L02` §7](l02-configuracion-y-profiles.md#7--value-al-lado), con la
  comparación completa en [`07` §6](07-configuracion-externalizada.md#6--value-frente-a-configurationproperties).

### `ConfigDataLocationNotFoundException`

```text
ConfigDataLocationNotFoundException: Config data location 'configtree:./secrets/' does not exist
```

- **Qué la causa de verdad.** Un `spring.config.import` que apunta a un recurso que no está,
  sin el prefijo `optional:`. En un lab molesta; **en producción ese fallo duro es deseable**
  para un secreto obligatorio, y por eso el prefijo no se pone por defecto.
- **Cómo se confirma.** El mensaje trae la localización completa tal como la escribiste. La
  trampa habitual es la barra final: `configtree:` apunta a un directorio y sin la barra Boot
  no lo trata como árbol.
- **La corrección.** `optional:configtree:./secrets/` si la ausencia es aceptable; crear el
  recurso si no lo es.
- **Cómo se evita.** Decidir para cada import si su ausencia debe tumbar el arranque, y
  escribirlo. Un `optional:` puesto por inercia sobre el fichero de secretos de producción es
  cómo se despliega un servicio sin credenciales que falla mucho más tarde.
- **Dónde se reproduce.** [`L02` §9](l02-configuracion-y-profiles.md#9--springconfigimport-y-un-secreto-como-fichero).

### Cron de cinco campos

```text
IllegalArgumentException: Cron expression must consist of 6 fields (found 5 in "15 3 * * *")
```

- **Qué la causa de verdad.** El cron de Spring tiene **seis campos** —segundo, minuto, hora,
  día del mes, mes, día de la semana— y el de Unix tiene cinco. Pegar uno de Unix es de los
  pocos fallos **ruidosos** de esta familia: `CronExpression.parse()` cuenta los campos antes
  de interpretarlos y el contexto no arranca.
- **Cómo se confirma.** El mensaje trae la expresión entera entre comillas y el conteo. No
  hay nada más que mirar.
- **La corrección.** Añadir el campo de segundos al principio: `0 15 3 * * *` son las
  03:15:00.
- **Cómo se evita.** El desplazamiento silencioso es el hermano peligroso de este error:
  `15 3 * * * *` tiene seis campos, arranca sin decir nada y significa *el segundo 15 del
  minuto 3 de cada hora*. Y `zone` es imprescindible: sin él manda la zona de la JVM, que en
  un contenedor suele ser UTC, y tu cierre de las 3 de la mañana corre a las 10 de la noche.
- **Dónde se reproduce.** [`18` §6](18-asincronia-scheduling-y-eventos.md#6--scheduled-el-reloj-y-el-pool-de-un-solo-hilo).

---

## 4. 🧱 Proxies: la anotación que no hace nada

Esta sección es la que explica la mitad de las demás. Lo declarativo de Spring lo ejecuta un
proxy que envuelve al bean **por fuera**, así que solo intercepta las llamadas que entran
desde fuera.

```text
misma clase  → no hay proxy  → no hay transacción, ni caché, ni retry, ni @Async
otro bean    → hay proxy     → la anotación hace lo que promete
```

| Caso | ¿Avisa? | Dónde duele en este catálogo |
|---|---|---|
| Llamada desde la misma clase (self-invocation) | ❌ | rollback, caché, `@Async`, `@Timed` |
| Método `private` | ❌ | rollback |
| Método o clase `final` | ❌ / error de arranque | cualquiera |
| Llamado desde `@PostConstruct` | ❌ | rollback |
| Excepción capturada dentro del método | ❌ | rollback |

- **Ninguno de los cinco lanza nada.** No hay error de compilación, ni de arranque, ni un
  `WARN`: la anotación queda como documentación de una intención que no se cumple.
- **El diagnóstico es siempre el mismo** y no necesita debugger: subir a `TRACE` el
  interceptor correspondiente y comprobar **sobre qué clase** corrió, no *si* corrió.
- **La sobregeneralización de entrevista está aquí.** *"`@Transactional` solo funciona en
  métodos `public`"* es la respuesta de cualquier blog anterior a 2022 y desde Spring
  Framework 6.0 ya no es exacta: con proxies **CGLIB** —el default de Boot desde 2.0— la
  anotación también se respeta en `protected` y package-private. Lo que **nunca** funciona es
  `private`. La versión que gana: *"no es cuestión de `public`, es cuestión de si el proxy
  puede sobrescribir el método y de si la llamada entra desde fuera del bean"*
  ([`16` §7](16-transacciones.md#7--los-seis-silencios)).

### `BeanNotOfRequiredTypeException`

```text
BeanNotOfRequiredTypeException: Bean named 'inventoryService' is expected to be of type
'com.invlab.invapi.inventory.InventoryService' but was actually of type
'jdk.proxy2.$Proxy142'
```

- **Qué la causa de verdad.** El bean implementa una interfaz, Spring hizo un **proxy JDK**
  que implementa esa interfaz, y alguien intentó inyectarlo declarando la **clase concreta**.
  El proxy no es de esa clase: es otro objeto que implementa la misma interfaz.
- **Cómo se confirma.** El propio mensaje trae el tipo real: `jdk.proxy2.$Proxy142` es un
  proxy JDK y `…$$SpringCGLIB$$0` es uno CGLIB. Para saber si un bean está proxyado sin
  provocar el error, `getClass().getName()` en un `ApplicationRunner` o el listado de
  `/actuator/beans`.
- **La corrección.** Inyectar por interfaz. La otra salida —forzar CGLIB con
  `proxyTargetClass = true`— es la que Boot ya aplica por defecto, y por eso este error hoy
  aparece sobre todo en proyectos que la desactivaron a mano.
- **Cómo se evita.** **La lección de diseño está en el error**: inyecta por interfaz y el
  tipo de proxy deja de importarte. Y recuerda la trampa hermana de CGLIB: los campos del
  proxy están a `null`, porque el estado vive en el objeto envuelto, no en la subclase.
- **Dónde se reproduce.** [`05` §3](05-proxies-y-aop.md#3--jdk-dynamic-proxy-vs-cglib), con lo
  que un proxy no puede interceptar en [`05` §6](05-proxies-y-aop.md#6--lo-que-un-proxy-no-puede-interceptar).

---

## 5. ⚠️ El borde web: el código de estado que miente

Cuatro peticiones mal hechas producen cuatro mecanismos distintos y, sin un
`@RestControllerAdvice`, un solo cuerpo de respuesta inútil.

```text
415  HttpMediaTypeNotSupportedException     HandlerMapping, antes del converter
400  HttpMessageNotReadableException        el converter corrió y falló
400  MethodArgumentNotValidException        el body se deserializó y lo rechazó Bean Validation
400  HandlerMethodValidationException       MVC valida los parámetros, ya sin @Validated
406  HttpMediaTypeNotAcceptableException    no hay representación que escribir
500  InsufficientStockException             nadie la tradujo: culpa nuestra
```

Para ver cuál de todas fue, el log de MVC en `DEBUG` es lo que enseña la excepción de verdad:

```bash
java -jar target/inv-api-0.0.1-SNAPSHOT.jar --logging.level.org.springframework.web=DEBUG &
```

- **Se pasa como argumento de línea de comandos**, la fuente de mayor precedencia: no hace
  falta tocar el YAML para un diagnóstico de cinco minutos.
- **Lo que aparece es una línea `Resolved [...]`** por cada excepción que un
  `HandlerExceptionResolver` reconoció. Si tu excepción **no** sale ahí, nadie la tradujo, y
  ese es justamente el caso de la última fila de la tabla.

### `HttpMediaTypeNotSupportedException`

```text
DEBUG --- [nio-8080-exec-5] .w.s.m.s.DefaultHandlerExceptionResolver :
  Resolved [org.springframework.web.HttpMediaTypeNotSupportedException:
  Content-Type 'text/plain' is not supported]
```

- **Qué la causa de verdad.** El fallo ocurre en el `HandlerMapping`, **antes de elegir
  converter**: el `consumes` del controller descartó el handler como candidato. Por eso la
  excepción no es de Jackson. Y la causa más frecuente no es `text/plain`: es **no mandar
  `Content-Type`**, porque entonces `curl -d` pone `application/x-www-form-urlencoded` por ti.
- **Cómo se confirma.** La respuesta `415` trae una cabecera `Accept` diciendo qué sí sabe
  leer el endpoint. Es la parte útil del 415 y casi nadie la mira.
- **La corrección.** Mandar el `Content-Type` correcto, o —si de verdad quieres aceptar ese
  tipo— añadirlo al `consumes` y registrar el converter que lo lea.
- **Cómo se evita.** Un test de `MockMvc` por cada media type que el contrato promete
  aceptar. Es el único sitio donde la ausencia de un converter se nota antes del despliegue.
- **Dónde se reproduce.** [`L03` §4](l03-api-rest-filtros-y-errores.md#4--cinco-peticiones-mal-hechas-415-400-406-y-dos-500-que-mienten),
  con el mecanismo en [`09` §8](09-rest-con-spring-mvc.md#8--406-415-y-400-tres-fallos-que-no-se-parecen).

### `HttpMessageNotReadableException`

```text
Resolved [org.springframework.http.converter.HttpMessageNotReadableException:
  JSON parse error: Unexpected character ('}' (code 125)): expected a valid value]
```

- **Qué la causa de verdad.** El converter **sí** se eligió, corrió y murió leyendo. El mismo
  caso cubre el body ausente (`Required request body is missing`) y un `@PathVariable` que no
  convierte al tipo declarado.
- **Cómo se confirma.** El mensaje de Jackson trae el carácter y la posición. Si no ves el
  `Resolved [...]`, sube `org.springframework.web` a `DEBUG`.
- **La corrección.** Es del cliente casi siempre; lo que sí es tuyo es el cuerpo de la
  respuesta, que sin advice no dice nada. Un `@ExceptionHandler` para esta excepción convierte
  un 400 mudo en un `ProblemDetail` que explica qué campo rompió el parseo.
- **Cómo se evita.** No se evita: se traduce. Y se traduce en un `@RestControllerAdvice`
  único, no en cada controller.
- **Dónde se reproduce.** [`L03` §4](l03-api-rest-filtros-y-errores.md#4--cinco-peticiones-mal-hechas-415-400-406-y-dos-500-que-mienten).

> **📝 Qué cambia en la línea 4.x.** Boot 4 mueve el baseline a Jackson 3, cuyo paquete raíz
> ya no es `com.fasterxml.jackson` sino `tools.jackson`. El código sigue siendo 400 y la
> excepción de Spring sigue siendo `HttpMessageNotReadableException`, pero **cambia el nombre
> de la excepción causa que verás en el log**, y con él cualquier `grep` de tu runbook o
> cualquier `catch` escrito contra el tipo de Jackson.

### `MethodArgumentNotValidException`

```text
Resolved [org.springframework.web.bind.MethodArgumentNotValidException: Validation failed
  for argument [0] in CreateItemRequest create(...): [Field error in object
  'createItemRequest' on field 'sku': rejected value [abc]; codes [Pattern...]]]
```

- **Qué la causa de verdad.** El `@RequestBody` se deserializó bien y **Bean Validation lo
  rechazó**. Trae la lista completa de `FieldError` —campo, valor rechazado, código de la
  restricción—, que es la materia prima del error útil.
- **Cómo se confirma.** Está en el `Resolved [...]` del log, y el `400` ya lo pone
  `DefaultHandlerExceptionResolver` sin que hagas nada.
- **La corrección.** No hay nada que corregir en el servidor: hay que **aprovecharla**. Un
  `@ExceptionHandler(MethodArgumentNotValidException.class)` que recorra los `FieldError` y
  los publique como `errors` dentro de un `ProblemDetail` convierte un 400 genérico en una
  respuesta accionable, y el 422 cuando la sintaxis era correcta y la semántica no.
- **Cómo se evita.** Que el DTO sea un `record` con sus restricciones encima y el
  `@Valid` en la firma. La validación que vive dentro del método siempre se olvida en el
  segundo endpoint.
- **Dónde se reproduce.** [`L03` §4](l03-api-rest-filtros-y-errores.md#4--cinco-peticiones-mal-hechas-415-400-406-y-dos-500-que-mienten)
  y la traducción a `ProblemDetail` en
  [`L03` §5](l03-api-rest-filtros-y-errores.md#5--restcontrolleradvice-problemdetail-y-el-422).

### `HandlerMethodValidationException` frente a `ConstraintViolationException`

```text
controller sin @Validated  → valida MVC      → HandlerMethodValidationException → 400
controller con @Validated  → valida el proxy → ConstraintViolationException     → 500
@Service   con @Validated  → valida el proxy → ConstraintViolationException     → 500
```

- **Qué la causa de verdad.** Un `?limit=500` con `@Min(1) @Max(100)` en la firma devuelve
  **500** si la clase lleva `@Validated`, y **400** si no la lleva. La
  `ConstraintViolationException` es de Jakarta, no de MVC: la lanza el interceptor de
  `MethodValidationPostProcessor` desde dentro del proxy que envuelve al controller, y para
  el `DispatcherServlet` es una excepción cualquiera que subió del handler. **Quien creó ese
  proxy fue tu propio `@Validated`.**
- **Cómo se confirma.** Con el log de MVC en `DEBUG`: en el caso del 500 **no aparece ninguna
  excepción de MVC** y el cuerpo es el `/error` genérico de Boot con
  `"error":"Internal Server Error"`. En el caso del 400 el log nombra
  `org.springframework.web.method.annotation.HandlerMethodValidationException` resuelta por
  `DefaultHandlerExceptionResolver`.
- **La corrección.** Borrar el `@Validated` de la clase del controller —y su import— y dejar
  las restricciones donde están. Desde Spring Framework 6.1 el controller valida por sí mismo
  los parámetros de método, y la reference lo pide con todas las letras: *"In order to take
  advantage of the Spring MVC built-in support for method validation added in Spring
  Framework 6.1, you need to remove the class level `@Validated` annotation from the
  controller"*.
- **Cómo se evita.** Recordar que `@Validated` **no habilita** la validación de parámetros en
  un controller: la **degrada** al camino de AOP y te convierte un 400 en un 500. Fuera del
  controller sigue siendo obligatoria, porque en un `@Service` no hay MVC que valide por ti.
- **Dónde se reproduce.** [`L03` §4](l03-api-rest-filtros-y-errores.md#4--cinco-peticiones-mal-hechas-415-400-406-y-dos-500-que-mienten),
  con la tabla completa de casos en
  [`10` §3](10-diseno-de-api-validacion-errores-e-hipermedia.md#3--valid-vs-validated-y-qué-excepción-lanza-cada-caso).

### `HttpMediaTypeNotAcceptableException`

```text
Resolved [org.springframework.web.HttpMediaTypeNotAcceptableException:
  No acceptable representation]
```

- **Qué la causa de verdad.** **406 no habla del cuerpo que mandas: habla del que pides.** El
  `produces` dice `application/json`, el cliente exigió XML en su `Accept`, y no hay
  intersección.
- **Cómo se confirma.** La respuesta va con `Content-Length: 0`, y la lógica es perversa:
  para explicarte el error habría que escribir un cuerpo, y acabas de decir que no aceptas
  nada que Spring sepa escribir.
- **La corrección.** Corregir el `Accept` del cliente, o registrar el converter que falta.
- **Cómo se evita.** Sabiendo que **con `jackson-dataformat-xml` en el classpath este mismo
  caso respondería 200 y XML**: un cambio de contrato por añadir una dependencia transitiva.
  Es una de las razones por las que el `produces` se escribe explícito.
- **Dónde se reproduce.** [`L03` §4](l03-api-rest-filtros-y-errores.md#4--cinco-peticiones-mal-hechas-415-400-406-y-dos-500-que-mienten).

### `ConverterNotFoundException`

```text
No converter found capable of converting from type [java.lang.String] to type [com.invlab.invapi.inventory.Sku]
```

- **Qué la causa de verdad.** El `ConversionService` no tiene forma de pasar del tipo de
  origen al de destino. Aparece al enlazar propiedades de configuración a un tipo propio, al
  usar un `@ConfigurationProperties` con un tipo que no es estándar, y en Spring Data cuando
  un converter de lectura o escritura falta para un tipo de la entidad. En el borde web el
  síntoma equivalente tiene otro nombre: `?quantity=abc` sobre un `int` da
  `MethodArgumentTypeMismatchException` y **400**.
- **Cómo se confirma.** El mensaje trae los dos tipos completos entre corchetes: el de origen
  y el de destino. Con eso sabes exactamente qué converter falta.
- **La corrección.** Registrar un `Converter<String, Sku>` como bean —Boot lo recoge para el
  enlace de propiedades si además lleva `@ConfigurationPropertiesBinding`— o, para un `record`
  de propiedades, dejar el tipo en `String` y convertir en el borde.
- **Cómo se evita.** Los tipos propios en la configuración son cómodos hasta que alguien
  despliega con una propiedad nueva: un test de arranque que enlace el fichero real es lo que
  lo detecta.
- **Dónde se reproduce.** El curso no lo provoca todavía en ningún lab. El texto de arriba es
  el mensaje que arma `ConverterNotFoundException` en `spring-core` 6.2.19, el del baseline;
  la variante web sí está en la tabla de
  [`10` §3](10-diseno-de-api-validacion-errores-e-hipermedia.md#3--valid-vs-validated-y-qué-excepción-lanza-cada-caso).

### El 500 que miente

```text
ERROR --- [nio-8080-exec-8] o.a.c.c.C.[.[.[/].[dispatcherServlet] :
  Servlet.service() for servlet [dispatcherServlet] threw exception
com.invlab.invapi.inventory.InsufficientStockException: El movimiento deja el stock de
  ABC-000123 por debajo de cero
	at com.invlab.invapi.inventory.InventoryController.record(InventoryController.java:52)
	... 47 more
```

- **Qué la causa de verdad.** Una excepción de dominio perfectamente correcta a la que
  **nadie tradujo**. Sin `@ExceptionHandler`, todo lo que sube del handler y no reconoce
  ningún resolver acaba en el `/error` genérico con un `500`.
- **Cómo se confirma.** El `500` sale con `"error":"Internal Server Error"` y el log tiene tu
  clase de dominio en la primera línea. Si tu excepción aparece en el log pero **no** en una
  línea `Resolved [...]`, es exactamente este caso.
- **La corrección.** Un `@RestControllerAdvice` con un `@ExceptionHandler` por familia de
  excepción de dominio, devolviendo `ProblemDetail`: `404` para "no existe", `409` para un
  conflicto, `422` para una regla de negocio violada con la sintaxis correcta.
- **Cómo se evita.** **Ese 500 es una mentira y cuesta dinero:** le dices al cliente "el
  servidor se rompió" cuando su petición era inválida, y un 5xx se reintenta mientras un 4xx
  no. Vas a recibir la misma petición cinco veces más y tu tablero de errores 5xx sube por
  culpa de alguien que escribió mal un número.
- **Dónde se reproduce.** [`L03` §4](l03-api-rest-filtros-y-errores.md#4--cinco-peticiones-mal-hechas-415-400-406-y-dos-500-que-mienten)
  y su corrección en [`L03` §5](l03-api-rest-filtros-y-errores.md#5--restcontrolleradvice-problemdetail-y-el-422).

---

## 6. 🩺 Datos y transacciones

La familia más cara del catálogo. Dos de sus entradas no lanzan ninguna excepción.

### `LazyInitializationException`

```text
org.hibernate.LazyInitializationException: failed to lazily initialize a collection of role: com.invlab.invapi.inventory.InventoryItem.events: could not initialize proxy - no Session
```

- **Qué la causa de verdad.** Alguien tocó una asociación `LAZY` **después** de que la
  transacción cerrara. El caso típico es un endpoint "para depurar" que devuelve la entidad
  sin pasar por el DTO: cuando el `HttpMessageConverter` empieza a escribir el JSON, el
  persistence context ya no existe.
- **Cómo se confirma.**

  ```bash
  grep -m 1 'LazyInitializationException' app.log
  ```

  - **`grep -m 1`** corta en la primera coincidencia: lo que importa es el mensaje, no los
    frames. **`- no Session`** son las dos palabras que valen —el objeto sabe qué le falta y
    ya no tiene a quién pedírselo— y **`of role: …InventoryItem.events`** nombra la asociación
    exacta que se tocó tarde.
  - **Hay un segundo mensaje para el mismo fallo** y conviene reconocer los dos: cuando lo
    que se toca tarde es el proxy de un `@ManyToOne`, Hibernate dice `could not initialize
    proxy [com.invlab.invapi.inventory.InventoryItem#3] - no Session`, con el id entre
    corchetes.
- **La corrección.** Decidir en el servicio qué necesita la respuesta: un `@EntityGraph` o un
  `join fetch` que traiga lo que se va a serializar, y un DTO en el borde.
- **Cómo se evita.** `spring.jpa.open-in-view=false` desde la primera entidad, y el fallo que
  aparezca te dice dónde faltaba decidir qué traer.

  > **⏱️ Costo en runtime de `open-in-view: true`.** La sesión abierta implica **la conexión
  > del pool retenida hasta el último byte de la respuesta**, no hasta el commit. Un cliente
  > lento o una respuesta de 2 MB ocupan una de tus diez conexiones todo ese tiempo. Y hay
  > algo peor que el costo: las consultas que dispara la serialización corren **fuera de
  > transacción**, cada una en su autocommit, así que el endpoint puede devolver un estado que
  > nunca existió a la vez en la base.

  > Nunca respondas: ~~"`open-in-view` evita el `LazyInitializationException`"~~
  >
  > Mejor: "lo evita escondiéndolo, y a cambio ata la conexión del pool a la velocidad del
  > cliente. Yo lo apago, y lo que se rompe me dice dónde faltaba decidir qué traer."
- **Dónde se reproduce.** [`L04` §5](l04-datos-y-transacciones.md#5-️-lazyinitializationexception-con-open-in-view-false)
  y el mecanismo en [`15` §7](15-datos-jdbc-jpa-mongo-y-redis.md#7-️-lazyinitializationexception-y-open-in-view).

### El rollback que no ocurre

**No hay excepción. No hay log. No hay aviso.** Es el peor de todo el catálogo porque la API
contesta correctamente mientras la base guarda lo que la regla de negocio existía para
impedir, y nadie lo descubre hasta el cierre contable.

```text
 eventos | cantidad
---------+----------
      62 |       -108
(1 row)
```

- **Qué la causa de verdad.** Tres variantes, las tres compilan y ninguna avisa:

  | Variante | ¿Corre el interceptor? | ¿Qué devuelve la API? | ¿Qué dice el `SELECT`? |
  |---|---|---|---|
  | A — self-invocation | ❌ | `422` correcto | filas grabadas |
  | B — excepción capturada dentro | ✅ | `200` engañoso | filas grabadas |
  | C — método `private` | ❌ | `422` correcto | filas grabadas |

  En A y C **la llamada nunca pasó por el proxy**; en B el proxy corrió, pero el `catch` se
  comió la excepción antes de que la viera, así que para el interceptor el método terminó
  perfectamente: **commit**. Y las filas se graban aunque no haya transacción de negocio
  porque `SimpleJpaRepository` —la implementación que Spring Data genera— **está anotada con
  `@Transactional` en sus métodos**: cada `save()` abre y confirma la suya. Lo peor de los dos
  mundos, **cada escritura atómica por separado y ninguna en conjunto**.
- **Cómo se confirma.** Primero el `SELECT`, que es la única evidencia que vale, y después el
  interceptor:

  ```bash
  grep 'TransactionInterceptor' app.log | sed 's/.*: //'
  ```

  ```text
  Getting transaction for [org.springframework.data.jpa.repository.support.SimpleJpaRepository.findWithEventsBySku]
  Completing transaction for [org.springframework.data.jpa.repository.support.SimpleJpaRepository.save]
  ```

  - Requiere `logging.level.org.springframework.transaction.interceptor=TRACE`.
  - **El log no está vacío, y ahí está la trampa.** Quien busca "¿corrió el interceptor?" ve
    líneas y respira tranquilo. **La pregunta correcta no es *si* corrió, es sobre qué
    clase**: si no aparece ni una línea con `InventoryService.record`, el interceptor nunca
    envolvió tu método.
  - **`sed 's/.*: //'`** recorta timestamp, nivel e hilo para que la línea quepa.
- **La corrección.** Mover `@Transactional` al **límite real de la unidad de trabajo** —el
  método de fuera, el que decide si entran los cinco movimientos o ninguno—; quitar el
  `private`; y en la variante B, `throw e` después de registrar, o
  `TransactionAspectSupport.currentTransactionStatus().setRollbackOnly()` si el flujo tiene
  que seguir. La auto-inyección con `ObjectProvider` funciona y deja una línea que nadie
  entiende en seis meses: se usa cuando de verdad no puedes mover el límite.
- **Cómo se evita.** Un test de integración que afirme sobre **la base**, no sobre el código
  de estado: mismo `count(*)` antes y después del caso que debe fallar. El `422` era correcto
  en las tres variantes, así que ningún test de API habría visto nada.

  > **🧠 La frase que hay que poder decir en voz alta.** `@Transactional` no abre una
  > transacción: le pide a un proxy que le pida al `TransactionManager` que abra una. **Si no
  > hay proxy en medio, o si el proxy no ve la excepción, la anotación es un comentario.**
- **Dónde se reproduce.** [`L04` §6](l04-datos-y-transacciones.md#6--el-gran-experimento-el-rollback-que-no-ocurre),
  con los seis silencios completos en [`16` §7](16-transacciones.md#7--los-seis-silencios) y la
  regla de rollback en [`16` §6](16-transacciones.md#6-️-rollback-la-regla-que-casi-todo-el-mundo-dice-mal).

### `UnexpectedRollbackException`

```text
org.springframework.transaction.UnexpectedRollbackException: Transaction silently rolled back because it has been marked as rollback-only
	at org.springframework.transaction.support.AbstractPlatformTransactionManager.processRollback(AbstractPlatformTransactionManager.java:873)
```

- **Qué la causa de verdad.** Un método interno con su propia `@Transactional` `REQUIRED`
  falló, **su** proxy vio la excepción y marcó el `TransactionStatus` compartido como
  `rollback-only`. Tu `catch` evitó que la excepción subiera, pero no borró la marca, así que
  el commit de fuera revienta.
- **Cómo se confirma.** Lo desconcertante es **dónde** aparece: en el método de fuera, que no
  falló, al hacer commit. El culpable ya terminó hace rato, y para encontrarlo se busca en el
  log el `WARN` del `catch` que se comió la excepción original.
- **La corrección.** La misma que la variante B de la entrada anterior: no capturar, o volver
  a lanzar, o marcar el rollback tú mismo si el flujo debe continuar.
- **Cómo se evita.** No hace falta evitarlo: **es una buena noticia**. Es el único de los
  silencios del rollback que **sí avisa**, y es mil veces preferible al `200` limpio con las
  filas grabadas.
- **Dónde se reproduce.** [`L04` §6](l04-datos-y-transacciones.md#6--el-gran-experimento-el-rollback-que-no-ocurre).

### `SQLTransientConnectionException` de Hikari

```text
Caused by: org.hibernate.exception.JDBCConnectionException: Unable to acquire JDBC Connection [HikariPool-1 - Connection is not available, request timed out after 3001ms.]
	...
Caused by: java.sql.SQLTransientConnectionException: HikariPool-1 - Connection is not available, request timed out after 3001ms.
	at com.zaxxer.hikari.pool.HikariPool.createTimeoutException(HikariPool.java:696)
	at com.zaxxer.hikari.pool.HikariPool.getConnection(HikariPool.java:197)
	... 118 more
```

- **Qué la causa de verdad.** Aparece en el 90 % de las caídas de servicios Spring en banca y
  **casi nunca significa lo que la gente cree**. El caso del lab es un deadlock de pool: un
  método con `@Transactional(propagation = REQUIRES_NEW)` llamado desde otra transacción
  consume **dos conexiones a la vez**, porque suspender no libera la conexión. Los otros dos
  candidatos son una llamada de red lenta dentro de la transacción y un `open-in-view: true`
  con clientes lentos.

  > **⏱️ La aritmética del deadlock, que es lo que se dice en una entrevista.** Con
  > `maximum-pool-size = N`, un método que necesita **dos** conexiones simultáneas se bloquea
  > en cuanto hay **N peticiones concurrentes** por ese camino: las N toman la primera y
  > ninguna consigue la segunda. Nadie avanza y nadie suelta. **La regla:
  > `pool ≥ concurrencia × conexiones por request`.**
- **Cómo se confirma.** Dos evidencias, y la primera cambia el diagnóstico entero:

  ```bash
  docker exec -i inv-lab-postgres-1 psql -U inv_lab -d inv_lab -c \
    "SELECT state, count(*), max(now() - state_change) FROM pg_stat_activity
     WHERE datname = 'inv_lab' GROUP BY state"
  ```

  ```text
        state        | count |   mas_antigua
  ---------------------+-------+-----------------
   idle in transaction |     2 | 00:00:02.914
  ```

  - **`idle in transaction`** significa que hay transacción abierta y **la base no está
    ejecutando nada**: espera a un cliente que es un hilo de Tomcat bloqueado pidiendo una
    segunda conexión. Cero consultas, cero disco, CPU al 0 %: **si tu única gráfica es la de
    la base, el incidente es invisible**. El recurso agotado es tuyo, no suyo.
  - La segunda evidencia es del lado de Hikari, con
    `logging.level.com.zaxxer.hikari.pool.HikariPool=DEBUG`:
    `HikariPool-1 - Pool stats (total=2, active=2, idle=0, waiting=6)`. **`waiting=6` cierra
    el caso**, y lo mismo está en `/actuator/metrics/hikaricp.connections.pending`.
  - **Fíjate en lo que NO hay en el stack trace: una sola línea de tu código.** Por eso la
    primera reacción de todo el mundo es "el pool es pequeño", que es la conclusión
    equivocada. **`Transient` es una promesa que aquí es mentira**: reintentar consume otra
    conexión y empeora el problema.
- **La corrección.** Sacar del camino la segunda conexión: mover la auditoría a un evento
  `@TransactionalEventListener`, o aceptar que la escritura se pierda si la transacción
  revierte. Subir el pool es el parche que desbloquea hoy y multiplica el problema mañana.
- **Cómo se evita.** Contar las conexiones por request antes de escribir `REQUIRES_NEW`, y
  alertar sobre `hikaricp.connections.pending` y sobre `hikaricp.connections.usage` —el tiempo
  de retención—, que es la variable que de verdad predice este incidente.
- **Dónde se reproduce.** [`L04` §7](l04-datos-y-transacciones.md#7-️-requires_new-y-el-deadlock-de-pool),
  con la propagación en [`16` §4](16-transacciones.md#4--propagación) y el pool en
  [`15` §2](15-datos-jdbc-jpa-mongo-y-redis.md#2--el-datasource-y-hikaricp).

### `TransactionRequiredException`

```text
jakarta.persistence.TransactionRequiredException: no transaction is in progress
```

- **Qué la causa de verdad.** Una operación que **escribe** —un `@Modifying` de Spring Data,
  un `flush()`, un `merge()` sobre el `EntityManager`— ejecutada sin transacción activa.
  Hibernate lo comprueba antes de mandar nada a la base. Detrás casi siempre está el mismo
  proxy de la sección 4: el método anotado se llamó desde dentro de su propia clase, o la
  anotación está en un `private`, o falta `@Transactional` en el repositorio derivado con
  `@Modifying`.
- **Cómo se confirma.** El mismo procedimiento del rollback ausente: interceptor a `TRACE` y
  comprobar si el log nombra **tu** método. Si no aparece, no hubo transacción y esta
  excepción es su versión ruidosa.
- **La corrección.** `@Transactional` en el límite correcto, y `@Modifying` acompañado de
  `@Transactional` en el servicio que lo llama, nunca solo en el repositorio.
- **Cómo se evita.** Agradecerla: es el caso en que la ausencia de transacción **sí grita**.
  El mismo defecto sobre una escritura que Spring Data envuelve por su cuenta no dice nada,
  y eso es la entrada [El rollback que no ocurre](#el-rollback-que-no-ocurre).
- **Dónde se reproduce.** Todavía en ningún documento del curso: `L04` provoca la variante
  silenciosa, que es la pedagógicamente valiosa. El texto de arriba es el mensaje que emite
  Hibernate ORM desde `SessionImpl` al comprobar la transacción de una operación de
  escritura; el mecanismo está en [`16` §7](16-transacciones.md#7--los-seis-silencios).

---

## 7. 🧱 Caché y asincronía

Dos anotaciones más con el mismo sombrero, y dos formas nuevas de que no pase nada.

### `SerializationFailedException`

```text
org.springframework.core.serializer.support.SerializationFailedException: Failed to serialize object using DefaultSerializer
	... 63 more
Caused by: java.lang.IllegalArgumentException: DefaultSerializer requires a Serializable payload but received an object of type [com.invlab.invapi.inventory.ItemView]
```

- **Qué la causa de verdad.** Pasaste la caché de Caffeine a Redis y **el culpable no es
  Redis ni tu consulta: es el serializador**. `RedisCacheConfiguration.defaultCacheConfig()`
  usa `JdkSerializationRedisSerializer` para los valores, y la serialización de Java exige
  `java.io.Serializable`. Tu `record` no lo implementa.
- **Cómo se confirma.** El arranque es limpio y el `/actuator/health` responde `200`: **el
  fallo llega en runtime y en la primera petición**, porque nada en el contexto sabe qué
  tipos vas a cachear. Lo que nunca se recorta del trace es la línea del `Caused by:`, que
  trae el nombre de tu clase.
- **La corrección.** Un `RedisCacheManagerBuilderCustomizer` que serialice los valores con
  `GenericJackson2JsonRedisSerializer`, con su TTL y su prefijo.
- **Cómo se evita.** **La tentación es `implements Serializable`, y funciona.** Es exactamente
  lo que no vas a hacer: la serialización JDK ata el valor binario a la clase y a su
  `serialVersionUID`, así que el día que añadas un campo y despliegues de forma gradual, la
  instancia vieja lee lo que escribió la nueva y falla al deserializar, con la caché llena de
  bombas que explotan una por una.
- **Dónde se reproduce.** [`L06` §6](l06-cache-y-asincronia.md#6--redis-con-lettuce-arregla-la-incoherencia-y-cobra-la-serialización),
  con la decisión de serialización en [`17` §6](17-cache.md#6--redis-como-caché-ttl-por-caché-y-serialización).

### El `@Cacheable` que nunca acierta

```text
antes=1 despues=4
```

- **Qué la causa de verdad.** Otra vez el proxy. Un método que recorre una lista y llama al
  método cacheado **de su propia clase** —`this::valuation`, o `this.valuation(...)`, que en
  bytecode es lo mismo— se salta el `CacheInterceptor`, que vive en el proxy. Tres consultas
  a la base para un SKU que estaba cacheado, **sin un acierto y sin un fallo registrados**:
  para la caché esas llamadas no existieron.
- **Cómo se confirma.** Un contador propio de llamadas al repositorio antes y después, que es
  lo que muestra el bloque de arriba. Y la señal que lo distingue de una caché mal
  configurada: en `/actuator/metrics/cache.gets` **no sube ni `hit` ni `miss`**. Una caché que
  falla registra `miss`; una caché a la que nadie llama no registra nada.
- **La corrección.** Sacar el método cacheado a otro bean, o entrar por el proxy. La misma
  terna de siempre.
- **Cómo se evita.** Un test que llame dos veces y afirme sobre el contador, no sobre el
  resultado: el resultado es correcto en los dos casos, que es justo por qué esto sobrevive a
  la revisión de código.
- **Dónde se reproduce.** [`L06` §3](l06-cache-y-asincronia.md#3-️-self-invocation-otra-vez-ahora-con-caché),
  con el mecanismo en [`17` §4](17-cache.md#4-️-el-proxy-otra-vez-self-invocation) y las métricas
  en [`17` §10](17-cache.md#10--sin-hit-ratio-esto-es-una-suposición).

### El `@Async` sin pool

- **Qué la causa de verdad.** Dos degradaciones distintas, ninguna ruidosa. La primera: **sin
  `@EnableAsync` en alguna `@Configuration`, `@Async` es un comentario decorado** —no hay
  proxy, el método corre en el hilo del llamante— y Boot no lo activa por ti, porque la
  autoconfiguración crea el executor, no el `@EnableAsync`. La segunda: con dos beans de tipo
  `TaskExecutor` y un `@Async` **sin nombre**, el arranque tampoco falla:
  `AsyncExecutionAspectSupport.getDefaultExecutor()` atrapa la `NoUniqueBeanDefinitionException`,
  prueba con el bean llamado `taskExecutor`, lo dice en un log de nivel **INFO** y devuelve
  `null`; el interceptor cae entonces a un `SimpleAsyncTaskExecutor` **sin pool y con un hilo
  nuevo por tarea** ⏱️.
- **Cómo se confirma.** **En el nombre del hilo del log.** Si ves `[inv-task-1]`, tu pool
  corrió; si ves el nombre del hilo de Tomcat `[nio-8080-exec-N]`, no hubo proxy; si ves
  `[SimpleAsyncTaskExecutor-N]`, hubo proxy y no hubo pool. Lo segundo también se ve en un
  thread dump —y no en el log—, porque los hilos se acumulan.
- **La corrección.** `@EnableAsync` una vez en el proyecto, y **el nombre del executor entre
  comillas** en cada `@Async("inventoryExecutor")`.
- **Cómo se evita.** Un `ThreadPoolTaskExecutor` declarado con sus tres números y su política
  de rechazo. **`AbortPolicy`, el default, lanza `TaskRejectedException` al llamante y es
  ruidosa, que aquí es bueno**; una cola ilimitada no es "sin límite", es un `OutOfMemoryError`
  diferido tras horas aceptando trabajo sin hacerlo.
- **Dónde se reproduce.** [`L06` §8](l06-cache-y-asincronia.md#8--async-el-hilo-nuevo-y-el-requestid-que-se-queda-atrás),
  con las dos formas en [`18` §3](18-asincronia-scheduling-y-eventos.md#3-️-las-dos-formas-de-que-async-no-haga-nada)
  y los tres números del executor en
  [`18` §4](18-asincronia-scheduling-y-eventos.md#4-️-el-executor-los-tres-números-y-la-cola-traicionera).

### El contexto que no cruza de hilo

```text
 INFO [sin-request-id] --- [   inv-task-1] c.i.i.InventoryValuationFacade  : recalentando la valoración de ABC-000123
```

- **Qué la causa de verdad.** El `traceId` del MDC, el `SecurityContext` y el
  `RequestContextHolder` viven en un `ThreadLocal`, y **un `ThreadLocal` no cruza a otro
  hilo**. En cuanto la tarea salta al pool, el `requestId` que te dio el cliente se queda en
  el hilo de Tomcat.
- **Cómo se confirma.** `[inv-task-1]` es la buena noticia —el `@Async` funciona— y
  **`[sin-request-id]` es la mala**: ese literal es el default del patrón
  `%X{requestId:-sin-request-id}`, escrito para este momento. Si lo ves, ese log corrió fuera
  del alcance del filtro. Los otros dos síntomas del mismo mecanismo son una
  `AccessDeniedException` con un usuario que **sí** tiene el rol, y un
  `IllegalStateException: No thread-bound request found`.
- **La corrección.** Un `TaskDecorator` en el executor que copie el contexto en el hilo que
  **envía** la tarea —donde el contexto todavía existe— y lo limpie al terminar.
- **Cómo se evita.** Asumir que todo lo que cuelga del hilo se pierde en cada salto, y
  decidir explícitamente qué se propaga. **En un incidente esto es la diferencia entre diez
  minutos y una tarde**: tienes el `requestId`, haces `grep`, y las líneas que explican qué
  pasó después de la respuesta no aparecen.
- **Dónde se reproduce.** [`L06` §8](l06-cache-y-asincronia.md#8--async-el-hilo-nuevo-y-el-requestid-que-se-queda-atrás),
  con el mecanismo en [`18` §5](18-asincronia-scheduling-y-eventos.md#5--propagación-de-contexto-lo-que-se-queda-en-el-hilo-del-request)
  y el `ThreadLocal` en [`08` §8](08-modelo-de-ejecucion-web.md#8--threadlocal-el-contexto-que-viaja-pegado-al-hilo).

---

## 8. 🧱 Clientes, resiliencia y reactivo

### `ResourceAccessException`

```text
org.springframework.web.client.ResourceAccessException: I/O error on GET request for "http://localhost:8090/suppliers/SLW-000001/quote": Read timed out
```

- **Qué la causa de verdad.** El otro extremo **no contestó** dentro del `read-timeout`.
  `ResourceAccessException` envuelve una `IOException` y es transporte; no confundirla con
  `HttpServerErrorException`, que significa que el otro sí contestó, con un 5xx.
- **Cómo se confirma.** `grep -m1 'ResourceAccessException' app.log`, y el tiempo de las
  respuestas: si todas fallan exactamente a los N segundos que pusiste, el timeout está
  haciendo su trabajo.
- **La corrección.** Que exista: `spring.http.client.connect-timeout` y
  `spring.http.client.read-timeout`, porque **no hay timeout por defecto y ese es el tema**.
  Después, traducir el fallo a un `503` con `ProblemDetail` en vez de devolver un `500`.
- **Cómo se evita.** Ningún cliente HTTP sale a revisión sin sus dos timeouts declarados.

  > **🧠 Modelo mental.** El timeout no arregla al proveedor: **convierte su latencia en tu
  > error, rápido y acotado**. Todo lo demás —retry, circuit breaker, bulkhead— se apoya en
  > que exista.
- **Dónde se reproduce.** [`L05` §3](l05-clientes-y-resiliencia.md#3-️-la-llamada-sin-timeout-y-el-hilo-que-no-vuelve),
  con la clasificación de errores en [`13` §6](13-clientes-http.md#6--errores-un-4xx-no-es-un-fallo-de-red)
  y el argumento en [`13` §2](13-clientes-http.md#2-️-no-hay-timeout-por-defecto-y-ese-es-el-tema).

### El fallback que no existe

```text
 WARN --- [nio-8080-exec-1] i.g.r.s.fallback.FallbackExecutor : No fallback method match found
java.lang.NoSuchMethodException: class com.invlab.invapi.supplier.SupplierQuote class com.invlab.invapi.supplier.SupplierGateway.lastKnownQuotes(class java.lang.String,class java.lang.Throwable)
```

- **Qué la causa de verdad.** El `fallbackMethod` de Resilience4j se resuelve **por nombre y
  firma**, y la firma tiene que ser la del método anotado **más un `Throwable` final**. Una
  `s` de más en el nombre —el error de refactor más común— y no hay fallback. Cuando la firma
  no casa, Resilience4j **captura** la `NoSuchMethodException`, escribe el `WARN` y ejecuta el
  método como si no hubieras configurado nada.
- **Cómo se confirma.**

  ```bash
  grep -m1 -A1 'No fallback method match found' app.log
  ```

  - **El `-A1` no es decoración**: el texto del `WARN` no dice qué método buscó; eso va en la
    excepción que el logger imprime en la línea siguiente, que empieza por el tipo de retorno
    y lleva el prefijo `class` en cada tipo.
  - **El aviso aparece aunque la petición termine en `200`**, y esto contradice lo que se
    repite en media internet: `FallbackExecutor` resuelve el método **en cada invocación del
    método anotado, antes de ejecutarlo**, no la primera vez que hace falta degradar. Si dos
    anotaciones declaran `fallbackMethod`, verás dos avisos por llamada.
- **La corrección.** Corregir el nombre o la firma, y comprobar que el fallback se ejecuta de
  verdad forzando el fallo.
- **Cómo se evita.** **La prevención es un test, no una revisión más cuidadosa**: un caso que
  fuerce el fallo y afirme sobre la respuesta degradada. Ninguna petición se rompe por este
  defecto, así que sobrevive a la suite, al despliegue y a la primera semana en producción; la
  noche que el proveedor se cae no encuentras un error nuevo, encuentras un `WARN` viejo que
  nadie leyó.
- **Dónde se reproduce.** [`L05` §7](l05-clientes-y-resiliencia.md#7--bulkhead-saturado-y-el-fallback-honesto),
  con el fallback honesto en [`19` §8](19-resiliencia.md#8--el-fallback-honesto).

### `CallNotPermittedException`

```text
io.github.resilience4j.circuitbreaker.CallNotPermittedException: CircuitBreaker 'supplier' is OPEN and does not permit further calls
```

- **Qué la causa de verdad.** El circuito está abierto y **está haciendo exactamente su
  trabajo**: fallar de inmediato sin tocar la red, que es lo que salva tus hilos y lo que le
  da aire al proveedor para recuperarse.
- **Cómo se confirma.** `/actuator/circuitbreakers` da el estado y
  `/actuator/circuitbreakerevents/supplier` la historia completa con las transiciones. Dos
  lecturas que confunden: `slowCallRate: -1.0%` no es un porcentaje negativo, es "todavía no
  hay datos suficientes"; y `bufferedCalls` cuenta **un fallo por cada intento del retry**, no
  uno por petición, así que con un retry dentro del breaker el circuito abre mucho antes de lo
  que esperas.
- **La corrección.** Ninguna sobre el circuito: **la lanza tu propio proceso, no el
  proveedor**. Lo que hay que corregir es la traducción al cliente, con un
  `@ExceptionHandler(CallNotPermittedException.class)` que devuelva `503` y un `Retry-After`.
- **Cómo se evita.** Quien la ve por primera vez en un log de producción busca el problema en
  la red o en el otro servicio. Saber que la lanza tu decorador ahorra la mitad del incidente.
- **Dónde se reproduce.** [`L05` §5](l05-clientes-y-resiliencia.md#5--el-circuito-que-abre-de-verdad),
  con los estados en [`19` §5](19-resiliencia.md#5--circuit-breaker-dejar-de-insistir-sobre-lo-que-está-roto).

### `BulkheadFullException`

```text
io.github.resilience4j.bulkhead.BulkheadFullException: Bulkhead 'supplier' is full and does not permit further calls
```

- **Qué la causa de verdad.** Hay más llamadas concurrentes al proveedor que permisos en el
  bulkhead. Igual que `CallNotPermittedException`, **la lanza tu proceso** y es el
  comportamiento deseado: el bulkhead existe para que un proveedor lento no se coma todos tus
  hilos.
- **Cómo se confirma.** `grep -c 'BulkheadFullException' app.log` contra el número de
  peticiones concurrentes: con tres permisos y diez peticiones, siete rechazos.
- **La corrección.** Un `@ExceptionHandler` que la traduzca a `503`; sin él sale como `500`, y
  un `500` invita al cliente a reintentar justo cuando menos quieres.
- **Cómo se evita.** Dimensionar el bulkhead con la concurrencia que el proveedor sostiene, no
  con la que tú querrías. Y recordar que **el orden de los decoradores cambia el resultado**:
  con el retry por fuera del breaker no se cuentan los mismos fallos que al revés.
- **Dónde se reproduce.** [`L05` §7](l05-clientes-y-resiliencia.md#7--bulkhead-saturado-y-el-fallback-honesto),
  con el orden en [`19` §7](19-resiliencia.md#7--el-orden-en-que-se-apilan).

### `IllegalStateException` en un hilo de Netty

```text
java.lang.IllegalStateException: block()/blockFirst()/blockLast() are blocking, which is not supported in thread reactor-http-nio-3
	at reactor.core.publisher.BlockingSingleSubscriber.blockingGet(BlockingSingleSubscriber.java:83)
	at reactor.core.publisher.Mono.block(Mono.java:1712)
```

- **Qué la causa de verdad.** Un `block()` dentro de un operador que corre en el event loop.
  Con ocho hilos de event loop, **ocho peticiones bloqueadas dejan el servicio sin atender
  nada**, incluido el `/actuator/health`.
- **Cómo se confirma.** El nombre del hilo en el mensaje: `reactor-http-nio-N` es event loop.
  Reactor detecta por su cuenta el caso más burdo, que es este.
- **La corrección.** Componer con operadores en vez de bloquear, o mover el trabajo bloqueante
  a `Schedulers.boundedElastic()` con `publishOn`. Nunca a `Schedulers.parallel()`, que es un
  pool fijo del tamaño de los cores para trabajo CPU-bound: bloquear ahí es tan malo como
  bloquear el event loop.
- **Cómo se evita.** **Esa excepción es la buena noticia: avisa.** Un `Thread.sleep(5000)` o
  un `jdbcTemplate.query(...)` en el mismo sitio **no lanza nada** y deja el servicio muerto.
  `BlockHound` convierte cualquier llamada bloqueante desde un hilo no-bloqueante en un error
  inmediato, y se instala **solo en el perfil `test`**, nunca en `prod`, porque aborta
  peticiones legítimas.
- **Dónde se reproduce.** [`11` §5](11-webflux-y-reactor.md#5--schedulers-y-la-regla-de-oro),
  con el modelo de ejecución en
  [`12`](12-reactivo-bloqueante-y-virtual-threads.md).

---

## 9. 🩺 Actuator y observabilidad

### Los tres `404` de Actuator

```text
prometheus -> 404
0
```

- **Qué la causa de verdad.** Tres causas distintas producen el mismo `404`, y se confunden
  todo el tiempo:

  | Causa | Cómo se ve | Qué falta |
  |---|---|---|
  | El endpoint **no existe** | `404` y no aparece en el índice de `/actuator` aunque esté en `include` | una dependencia (`micrometer-registry-prometheus`) o un bean (`HttpExchangeRepository`) |
  | El endpoint **no está expuesto** | `404` y aparece al añadirlo a `include` | la línea en `management.endpoints.web.exposure.include` |
  | `exclude` **gana a** `include` | `404` sin un solo aviso, listado en los dos | quitarlo de `exclude` |
- **Cómo se confirma.** En un comando: `curl -s localhost:8081/actuator | jq -r '._links |
  keys[]'`. Si el endpoint **no** aparece ahí y **tampoco** tras añadirlo a `include`, es
  dependencia o bean; si aparece al añadirlo, era exposición. Un cuarto caso, cuando llegue
  Spring Security, es un `SecurityFilterChain` sobre `EndpointRequest.toAnyEndpoint()` que lo
  bloquea.
- **La corrección.** La que diga el diagnóstico, y ninguna otra: añadir la dependencia,
  exponer el endpoint o declarar el bean que falta.
- **Cómo se evita.** El `404` de una **anotación** de métrica es el hermano silencioso de
  esto: un `@Timed` no registra nada si `management.observations.annotations.enabled` sigue en
  `false` o si falta `spring-boot-starter-aop`, y **no hay una sola línea de log que lo
  diga**. Y hay una tercera causa para el mismo `404`: `@Timed` se aplica con un aspecto sobre
  un proxy, así que una llamada desde la misma clase no mide nada. La sección 4, otra vez.
- **Dónde se reproduce.** [`L07` §2](l07-actuator-metricas-y-trazas.md#2--exposición-con-criterio-y-el-8081-que-ya-tenías),
  el `@Timed` en [`L07` §5](l07-actuator-metricas-y-trazas.md#5--métricas-propias-timer-counter-y-el-timed-que-no-aparece)
  y el tercero en [`L07` §12](l07-actuator-metricas-y-trazas.md#12--httpexchanges-y-por-qué-no-sustituye-a-las-trazas);
  el catálogo de endpoints en [`23` §2](23-actuator-y-observabilidad.md#2--qué-expone-actuator-por-defecto-y-cómo-se-asegura).

### El target de Prometheus que no responde

```text
{"job":"inv-api","health":"down","lastError":"Get \"http://host.docker.internal:8081/actuator/prometheus\": dial tcp 192.168.65.254:8081: connect: connection refused"}
```

- **Qué la causa de verdad.** `management.server.address: 127.0.0.1` liga el conector de
  management al loopback de tu máquina, y **un contenedor no es tu loopback**: llega por la
  interfaz del gateway de Docker y el sistema operativo rechaza la conexión antes de que
  Tomcat se entere. Por eso el error parece imposible: tu `curl` desde la terminal sigue
  funcionando.
- **Cómo se confirma.** `curl -s localhost:9090/api/v1/targets` y leer `lastError`.
  **`connection refused` frente a `context deadline exceeded`**: el primero es "alguien
  contestó que no hay nadie escuchando ahí" —binding, puerto o firewall—; el segundo es "nadie
  contestó" —red, DNS o un proceso demasiado lento—. Distinguirlos ahorra la mitad del tiempo
  de diagnóstico. La dirección IP es lo único que cambia de máquina a máquina.
- **La corrección.** `management.server.address: 0.0.0.0` **en el perfil `local`**, que es
  donde tiene que estar: el `prod` simulado conserva el loopback.
- **Cómo se evita.** La causa vecina y más tonta es olvidar `metrics_path`, porque el default
  de Prometheus es `/metrics`: da un target en `down` con un `404` como último error, que se
  distingue del anterior solo leyendo `lastError` entero.
- **Dónde se reproduce.** [`L07` §7](l07-actuator-metricas-y-trazas.md#7--prometheus-en-compose-y-el-target-que-no-responde),
  con el scrape en [`23` §9](23-actuator-y-observabilidad.md#9--prometheus-el-scrape-y-las-cuatro-señales-doradas).

---

## 10. ⚠️ Lo que el curso todavía no reproduce

Cuatro entradas del mínimo de este apéndice **no tienen aquí ninguna salida literal**, y es a
propósito: tres porque sus capítulos y sus labs no existían al escribirlas, y una porque el
curso excluye su lab a sabiendas. Escribir un stack trace de memoria para completar la ficha
sería exactamente el error que este apéndice existe para evitar, así que se describen en prosa
y se dice dónde se practicarán.

- **401 y 403 sin log explicativo.** Spring Security rechaza la petición **en la cadena de
  filtros, antes del `DispatcherServlet`**, así que tu `@RestControllerAdvice` no se entera y
  el cliente recibe un código desnudo sin cuerpo y sin una línea en el log que diga por qué.
  La distinción que hay que llevarse a una entrevista: **401 es "no sé quién eres"** —falta
  autenticación, o el token no valida— y **403 es "sé quién eres y no puedes"**. El
  diagnóstico pasa por subir `org.springframework.security` a `DEBUG` y leer qué filtro cortó,
  y por los puntos de extensión `AuthenticationEntryPoint` y `AccessDeniedHandler`, que son
  los que convierten esos códigos mudos en un `ProblemDetail`. Se reproducirá en el capítulo
  de Spring Security y en su laboratorio.
- **`AccessDeniedException` dentro de un `@Async`.** El síntoma es desconcertante: **el mismo
  usuario que sí tiene el rol** recibe un rechazo, pero solo en el trabajo asíncrono. La causa
  ya está explicada y reproducida a medias en este catálogo: el `SecurityContext` vive en un
  `ThreadLocal` y no cruza al hilo del executor, exactamente igual que el `requestId` de
  [El contexto que no cruza de hilo](#el-contexto-que-no-cruza-de-hilo). La corrección tiene
  nombre propio —`DelegatingSecurityContextAsyncTaskExecutor`, o la estrategia
  `MODE_INHERITABLETHREADLOCAL`— y su reproducción llega cuando haya Security en el classpath;
  el mecanismo, hoy, está en
  [`18` §5](18-asincronia-scheduling-y-eventos.md#5--propagación-de-contexto-lo-que-se-queda-en-el-hilo-del-request).
- **El contexto de test que se recarga y la suite que tarda ocho minutos.** No es un error:
  es una factura. El `TestContext` framework **cachea los contextos por su configuración**, y
  cada combinación distinta de anotaciones, propiedades y beans falsos crea una entrada nueva;
  un `@DirtiesContext` mal puesto tira el contexto cacheado y obliga a levantarlo otra vez. El
  síntoma es una suite que crece de forma no lineal con el número de tests y un log lleno de
  banners de arranque repetidos. Se desarrollará en el capítulo de testing.
- **El handshake WebSocket que devuelve `403`, y la sesión que se cierra sola.** Dos fallos
  del mismo capítulo, y ninguno deja una excepción tuya en el log. El primero: sin
  `setAllowedOrigins`, Spring rechaza todo handshake cuyo `Origin` no coincida con el host, y el
  navegador solo dice que no conecta; se confirma subiendo `org.springframework.web.socket` a
  `DEBUG`. El segundo: `ConcurrentWebSocketSessionDecorator` cierra la sesión de un cliente que
  no drena con `SessionLimitExceededException` al superar `sendTimeLimit` o `bufferSizeLimit`,
  y es una protección, no un bug —la alternativa era bloquear a quien publica—. El mecanismo
  está en [`14` §4](14-tiempo-real-sse-y-websocket.md#4--websocket-crudo-websockethandler-y-la-sesión);
  no hay lab porque reproducirlo exige un navegador y dos réplicas tras un balanceador, y
  [`L00` §3](l00-idea-lab-practico.md#3--el-catálogo-de-exclusiones-una-por-una) lo deja fuera
  a propósito.

Cuando esos documentos existan, cada uno de los tres primeros párrafos se convierte en una entrada
completa con su salida literal. Mientras tanto, el hueco se declara: **una ficha de
diagnóstico con un mensaje inventado no vale menos que nada, vale negativo.**

---

## 🧠 Preguntas rápidas

1. Un arranque falla con un bloque `Description:` / `Action:` y sin stack trace. ¿Qué te dice
   eso sobre quién produjo el mensaje, y qué lees primero?
2. En una cadena de tres `Caused by:`, ¿cuál es la excepción original y por qué
   `UnsatisfiedDependencyException` casi nunca es la que hay que corregir?
3. Tienes dos beans `Clock` y el arranque no falla. ¿Qué tiene que ser cierto del nombre del
   parámetro del constructor para que no falle?
4. Tu `?limit=500` devuelve `500` en vez de `400` y el parámetro lleva `@Max(100)`. ¿Cuál es
   la causa exacta y cuál es la corrección, en una línea?
5. Distingue `HttpMessageNotReadableException` de `MethodArgumentNotValidException` diciendo
   en qué momento del recorrido de la petición se lanza cada una.
6. La API devuelve un `422` impecable y la fila quedó grabada. Enumera las tres variantes que
   producen eso y di cuál de las tres **sí** deja rastro en el log del `TransactionInterceptor`.
7. Ves `HikariPool-1 - Connection is not available, request timed out` y Postgres está al 0 %
   de CPU. ¿Qué consulta corres contra la base y qué esperas encontrar?
8. *"`@Transactional` solo funciona en métodos `public`"*. Nombra la simplificación y da la
   versión precisa para Spring Framework 6.2.
9. Tu `@Cacheable` no registra ni `hit` ni `miss`. ¿Qué descarta ese dato y qué lo distingue
   de una caché mal configurada?
10. ¿Por qué `DefaultSerializer requires a Serializable payload` no aparece en el arranque sino
    en la primera petición, y por qué `implements Serializable` es la corrección equivocada?
11. `CallNotPermittedException` y `BulkheadFullException` tienen algo en común que cambia por
    completo dónde buscas el problema. ¿Qué es?
12. Un target de Prometheus está en `down` con `connection refused`. ¿Qué descarta ese mensaje
    frente a un `context deadline exceeded`?

---

## 🧪 Ejercicios (12)

Todos se hacen sobre `inv-api` y todos declaran cómo se comprueban. Los que piden romper algo
se deshacen al terminar: este apéndice no deja estado.

### 🟢 Fácil — reproducir la primera línea  (1–5)

#### 🟢 Ejercicio 1 — El índice, sin leer el catálogo

Toma tres de las salidas literales de las secciones 3, 5 y 6, tápate la parte de "qué la causa
de verdad" y escribe de memoria, para cada una, en qué fase falló: contenedor, borde web o
acceso a datos.

**Objetivo:** convertir la primera línea en un triaje de fase, que es el 80 % del diagnóstico.
**Se comprueba:** tus tres respuestas coinciden con la sección donde vive cada entrada.

#### 🟢 Ejercicio 2 — El puerto, otra vez

Levanta dos instancias de `inv-api` sin cambiar ningún puerto, captura el bloque
`Description:` / `Action:` completo y averigua con un solo comando qué proceso ocupaba el 8080.
Mata el sobrante con `SIGTERM`, no con `-9`.

**Objetivo:** que el `FailureAnalyzer` y `lsof` sean un reflejo, no una búsqueda.
**Se comprueba:** el segundo arranque con `--server.port=9090 --management.server.port=9091`
levanta y `curl localhost:9091/actuator/health` responde `200`.

#### 🟢 Ejercicio 3 — Un `Origin` que apunta a tu línea

Mete un valor inválido en `inv.supplier.max-connections` **desde una variable de entorno** en
vez del `application.yml`, arranca y lee el bloque de error.

**Objetivo:** ver que `Origin` sigue al valor a través de la fuente, no del fichero.
**Pregunta:** ¿qué dice `Origin` ahora, y por qué ya no hay línea ni columna?

#### 🟢 Ejercicio 4 — Las cuatro peticiones mal hechas

Con el log de `org.springframework.web` en `DEBUG`, reproduce el 415, el 400 de JSON roto, el
400 de validación y el 406, y anota la línea `Resolved [...]` de cada uno.

**Objetivo:** asociar código de estado con excepción sin tener que mirar la tabla.
**Se comprueba:** tienes cuatro líneas `Resolved [...]` con cuatro nombres de excepción
distintos.

#### 🟢 Ejercicio 5 — El nombre del hilo como diagnóstico

Provoca las tres situaciones de `@Async` —sin `@EnableAsync`, con executor sin nombre y con
executor nombrado— y anota el nombre del hilo que aparece en cada log.

**Objetivo:** usar el nombre del hilo como primera evidencia, antes de abrir nada.
**Se comprueba:** los tres logs muestran `nio-8080-exec-N`, `SimpleAsyncTaskExecutor-N` e
`inv-task-N` respectivamente.

### 🟡 Intermedio — llevarlo a otro sitio  (6–9)

#### 🟡 Ejercicio 6 — Una entrada nueva para el catálogo

Provoca un `NoUniqueBeanDefinitionException` con dos beans que **no** sean `Clock` —por
ejemplo dos `TaskExecutor`— y escribe la entrada completa con la estructura fija de este
apéndice: primera línea literal, causa, confirmación, corrección y prevención.

**Objetivo:** que la ficha sea un procedimiento que sabes aplicar, no un texto que lees.
**Se comprueba:** tu entrada tiene las cinco partes y la primera línea está copiada, no
reescrita.

#### 🟡 Ejercicio 7 — El silencio, medido

Reproduce la variante A del rollback que no ocurre y demuestra con **dos** evidencias que no
hubo transacción de negocio: el `count(*)` antes y después, y la ausencia de
`InventoryService.record` en el log del `TransactionInterceptor` a `TRACE`.

**Objetivo:** entender por qué el log lleno de líneas no es prueba de nada.
**Pregunta:** ¿qué línea **concreta** del log habría demostrado lo contrario?

#### 🟡 Ejercicio 8 — Los tres `404`

Consigue que `/actuator/httpexchanges` devuelva `404` por las tres causas distintas, una por
una, y escribe el comando que distingue cada caso de los otros dos.

**Objetivo:** no volver a perder veinte minutos con un endpoint "que está en el `include`".
**Se comprueba:** tienes tres configuraciones distintas que producen el mismo `404` y un
comando que las separa.

#### 🟡 Ejercicio 9 — El fallback que nadie ejercitó

Rompe a propósito la firma de un `fallbackMethod` de `L05` quitándole el `Throwable` final,
arranca y cuenta los avisos **antes** de provocar ningún fallo.

**Objetivo:** interiorizar que el defecto es visible desde la primera llamada exitosa.
**Se comprueba:** `grep -c 'No fallback method match found' app.log` devuelve un número mayor
que cero después de una petición que respondió `200`.

### 🟠 Difícil — combinar y decidir  (10–11)

#### 🟠 Ejercicio 10 — Dos agotamientos que se parecen

Provoca el agotamiento del pool de Hikari de dos formas distintas: con el `REQUIRES_NEW` de
`L04` §7 y con una llamada HTTP lenta **dentro** de una transacción. Los dos producen la misma
primera línea. Escribe el procedimiento que los distingue en menos de dos minutos.

**Objetivo:** que la misma excepción no te lleve siempre a la misma hipótesis.
**Se comprueba:** tu procedimiento usa `pg_stat_activity` y un thread dump, y cada caso deja
una firma distinta en ellos.

#### 🟠 Ejercicio 11 — El runbook de una alerta

Elige tres entradas de este catálogo que un servicio de banca vería en producción y escribe,
para cada una, la alerta que la detectaría antes que el cliente: la métrica, el umbral y por
qué ese umbral. Una de las tres tiene que ser un fallo **silencioso**.

**Objetivo:** pasar de diagnosticar a prevenir, que es la diferencia entre un senior y un
tech lead.
**Pregunta:** ¿cómo se alerta sobre algo que no lanza ninguna excepción?

### 🔴 Muy difícil — se entrega algo roto  (12)

#### 🔴 Ejercicio 12 — Tres fallos inyectados

Pídele a alguien —o a tu yo de la semana pasada— que introduzca **tres** defectos de este
catálogo en `inv-api` sin decirte cuáles: uno de arranque, uno que produzca un código de
estado equivocado y uno silencioso. Diagnostícalos **solo** con logs, Actuator y `psql`, sin
leer el diff.

**Objetivo:** ejecutar el procedimiento completo sin saber la respuesta, que es exactamente el
escenario de una entrevista de incidente.
**Se comprueba:** entregas un informe con, por cada fallo, la evidencia literal que lo
sostiene, la corrección de hoy y la prevención; y el `git diff` final confirma los tres.

### 🔥 Opcionales y ampliaciones

- Escribe tu propio `FailureAnalyzer` para `InsufficientStockException` y comprueba que el
  arranque —o el fallo— se traduce a un bloque `Description:` / `Action:` como los de Boot.
- Convierte el índice por síntoma de la sección 2 en un `grep` de una línea sobre tus logs de
  producción, y mide qué tres entradas de este catálogo aparecen más.
- Instala BlockHound en el perfil `test` de un módulo reactivo y comprueba que detecta un
  `Thread.sleep` que Reactor por su cuenta no detecta.

### 💀 Boss fight — el servicio que nadie quiere tocar

Te entregan `inv-api` con **cinco** defectos simultáneos de este catálogo, repartidos entre el
arranque, el borde web, los datos, la caché y la observabilidad. La aplicación levanta, la
suite de tests pasa en verde y el equipo de enfrente se queja de "errores intermitentes".

Sin tocar una línea de código todavía, produce un informe de diagnóstico que, para cada
defecto, responda: qué se ve desde fuera, cuál es la evidencia literal que lo sostiene, quién
lo ejecuta y en qué hilo, qué corrección aplicarías hoy y cuál harías con calma, y qué test o
alerta impide que vuelva. Después arréglalos **de uno en uno**, verificando cada corrección
antes de pasar a la siguiente.

**Objetivo:** demostrar que puedes auditar y estabilizar un servicio Spring Boot que no
escribiste, con la evidencia por delante de la intuición y una variable a la vez.

---

## 📚 Referencias oficiales

- Spring Boot 3.5 — Failure analyzers y diagnóstico del arranque: https://docs.spring.io/spring-boot/3.5/how-to/application.html
- Spring Boot 3.5 — API de `FailureAnalyzer`: https://docs.spring.io/spring-boot/3.5/api/java/org/springframework/boot/diagnostics/FailureAnalyzer.html
- Spring Boot 3.5 — Configuración externalizada y binding: https://docs.spring.io/spring-boot/3.5/reference/features/external-config.html
- Spring Boot 3.5 — Manejo de errores en MVC: https://docs.spring.io/spring-boot/3.5/reference/web/servlet.html#web.servlet.spring-mvc.error-handling
- Spring Boot 3.5 — Endpoints de Actuator: https://docs.spring.io/spring-boot/3.5/reference/actuator/endpoints.html
- Spring Boot 3.5 — Métricas y registries: https://docs.spring.io/spring-boot/3.5/reference/actuator/metrics.html
- Spring Boot 3.5 — Acceso a datos SQL y pool de conexiones: https://docs.spring.io/spring-boot/3.5/reference/data/sql.html
- Spring Boot 3.5 — Ejecución de tareas y scheduling: https://docs.spring.io/spring-boot/3.5/reference/features/task-execution-and-scheduling.html
- Spring Boot 3.5 — Logging y niveles: https://docs.spring.io/spring-boot/3.5/reference/features/logging.html
- Spring Framework 6.2 — Autowiring y resolución de candidatos: https://docs.spring.io/spring-framework/reference/6.2/core/beans/dependencies/factory-autowire.html
- Spring Framework 6.2 — Qualifiers: https://docs.spring.io/spring-framework/reference/6.2/core/beans/annotation-config/autowired-qualifiers.html
- Spring Framework 6.2 — Mecanismos de proxy: https://docs.spring.io/spring-framework/reference/6.2/core/aop/proxying.html
- Spring Framework 6.2 — `@Transactional` y sus atributos: https://docs.spring.io/spring-framework/reference/6.2/data-access/transaction/declarative/annotations.html
- Spring Framework 6.2 — Reglas de rollback: https://docs.spring.io/spring-framework/reference/6.2/data-access/transaction/declarative/rolling-back.html
- Spring Framework 6.2 — Excepciones del borde web en MVC: https://docs.spring.io/spring-framework/reference/6.2/web/webmvc/mvc-ann-rest-exceptions.html
- Spring Framework 6.2 — Validación en controllers: https://docs.spring.io/spring-framework/reference/6.2/web/webmvc/mvc-controller/ann-validation.html
- Spring Framework 6.2 — Anotaciones de caché: https://docs.spring.io/spring-framework/reference/6.2/integration/cache/annotations.html
- Spring Framework 6.2 — Scheduling y expresiones cron: https://docs.spring.io/spring-framework/reference/6.2/integration/scheduling.html
- Spring Data JPA 3.5 — Transacciones en repositorios: https://docs.spring.io/spring-data/jpa/reference/3.5/jpa/transactions.html
- Spring Data Redis 3.5 — Caché y serialización: https://docs.spring.io/spring-data/redis/reference/3.5/redis/redis-cache.html

### Documentación de terceros

- Hibernate ORM 6.6 — guía de usuario: https://docs.hibernate.org/orm/6.6/userguide/html_single/
- Resilience4j — circuit breaker: https://resilience4j.readme.io/docs/circuitbreaker
- Resilience4j — bulkhead: https://resilience4j.readme.io/docs/bulkhead
- Micrometer 1.15 — conceptos y medidores: https://docs.micrometer.io/micrometer/reference/1.15/concepts.html
- Prometheus — configuración del scrape: https://prometheus.io/docs/prometheus/latest/configuration/configuration/
- JDK 21 — guía de troubleshooting: https://docs.oracle.com/en/java/javase/21/troubleshoot/index.html
