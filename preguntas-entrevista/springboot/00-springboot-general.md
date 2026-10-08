# 🌱 100 preguntas de entrevista — Spring Boot

> Orientado a perfil senior / arquitecto, con Spring Boot 3.x y Spring Framework 6 como referencia.
> **Dificultad:** 🟢 base · 🟡 estándar · 🟠 profundidad · 🔴 abierta o adversarial

---

## ⚙️ Parte 1 — Núcleo, arranque y autoconfiguración (1–16)

**1. 🟢 ¿Qué problema resuelve Spring Boot frente a Spring Framework a secas?**
Elimina la configuración repetitiva (XML o `@Configuration` interminables), fija versiones compatibles mediante los starters y el BOM, embebe el servidor, y da capacidades de producción listas (Actuator, métricas, health). No es un framework nuevo: es Spring con opinión, convención sobre configuración y un empaquetado ejecutable.

**2. 🟢 ¿Qué hace exactamente `@SpringBootApplication`?**
Agrupa tres anotaciones: `@SpringBootConfiguration` (es una clase de configuración), `@EnableAutoConfiguration` (activa la autoconfiguración) y `@ComponentScan` (escanea desde el paquete de esa clase hacia abajo). De ahí la regla de ubicar la clase principal en el paquete raíz: define el alcance del escaneo.

**3. 🟡 ¿Cómo funciona la autoconfiguración por dentro?**
Spring Boot lee las clases candidatas declaradas en `META-INF/spring/org.springframework.boot.autoconfigure.AutoConfiguration.imports` (en Boot 2 era `spring.factories`), y cada una aplica condiciones `@Conditional`: `@ConditionalOnClass`, `@ConditionalOnMissingBean`, `@ConditionalOnProperty`. Solo se activa lo que tiene sentido según el classpath y la configuración. `@ConditionalOnMissingBean` es la clave de la filosofía: si tú defines el bean, Boot se aparta.

**4. 🟡 ¿Cómo depuras por qué una autoconfiguración no se aplicó?**
Arranca con `--debug` o `-Ddebug=true` para obtener el `ConditionEvaluationReport`, que lista las condiciones evaluadas como positivas, negativas y excluidas. También sirve el endpoint `/actuator/conditions`. Es la herramienta que convierte la "magia" de Boot en algo verificable.

**5. 🟡 ¿Cómo desactivas una autoconfiguración concreta?**
`@SpringBootApplication(exclude = DataSourceAutoConfiguration.class)` o la propiedad `spring.autoconfigure.exclude`. Caso típico: una aplicación que tiene el starter de JDBC en el classpath por transitividad pero no usa base de datos, y falla al arrancar porque no encuentra una URL.

**6. 🟠 ¿Cómo creas tu propio starter y cuándo vale la pena?**
Un módulo con las clases de autoconfiguración, el archivo de imports, `@ConfigurationProperties` para su configuración, y condiciones que respeten los beans del usuario. Vale la pena cuando varios equipos de la organización repiten la misma integración (cliente del core bancario, convenciones de logging y trazas, configuración de seguridad corporativa). No vale la pena para una sola aplicación.

**7. 🟡 ¿Qué son los starters y qué garantía dan?**
Dependencias agregadoras que traen un conjunto coherente de librerías, con versiones gestionadas por el BOM de Spring Boot. La garantía real es de **compatibilidad**: te ahorra el infierno de resolver versiones entre Jackson, Hibernate, Tomcat y el resto.

**8. 🟡 ¿Qué diferencia hay entre un fat JAR y un WAR desplegado en un servidor?**
El fat JAR embebe el servidor y se ejecuta con `java -jar`: un solo artefacto, ideal para contenedores. El WAR depende de un servidor externo y su ciclo de vida. En banca todavía existen entornos con WebSphere o WebLogic donde el WAR es obligatorio; Boot lo soporta extendiendo `SpringBootServletInitializer`, aunque pierdes parte de las ventajas.

**9. 🟠 ¿Cómo se estructura un fat JAR de Spring Boot y por qué no es un JAR normal?**
Usa un formato propio con las dependencias en `BOOT-INF/lib` y las clases en `BOOT-INF/classes`, más un `JarLauncher` como main real, porque el JAR estándar de Java no soporta JARs anidados. Relevante para Docker: el **layered JAR** separa dependencias y código propio en capas distintas para que la capa pesada de dependencias se cachee entre builds.

**10. 🟠 ¿Cómo reduces el tiempo de arranque de una aplicación Spring Boot grande?**
Por orden de coste creciente: medir primero con `spring.main.log-startup-info` y el `startup` endpoint; quitar autoconfiguraciones y escaneo innecesario; `spring.main.lazy-initialization` (con la advertencia de que traslada los fallos al primer uso); AppCDS para cachear la carga de clases; y GraalVM native image, que baja a milisegundos a cambio de compilación lenta, restricciones de reflexión y depuración más pobre.

**11. 🟡 ¿Qué es `CommandLineRunner` y `ApplicationRunner`?**
Beans que se ejecutan tras el arranque del contexto. Diferencia: uno recibe los argumentos crudos, el otro los recibe parseados como `ApplicationArguments`. Útiles para tareas de inicialización, migraciones puntuales o aplicaciones de tipo batch/CLI.

**12. 🟠 ¿Qué es el `ApplicationContext` y cuál es su ciclo de vida?**
El contenedor IoC: registra definiciones de beans, los instancia, inyecta dependencias, aplica post-procesadores y publica eventos de ciclo de vida (`ApplicationStartingEvent`, `ApplicationReadyEvent`, `ContextClosedEvent`). Conocer estos eventos importa para arranques ordenados y para apagados limpios en Kubernetes.

**13. 🟠 ¿Qué es el apagado elegante (graceful shutdown) y por qué importa en Kubernetes?**
`server.shutdown=graceful` hace que el servidor deje de aceptar peticiones nuevas y termine las en curso dentro de un timeout. Importa porque Kubernetes envía SIGTERM y elimina el pod del balanceo de forma **asíncrona**: sin apagado elegante, peticiones en vuelo se cortan. Complementa con `preStop` y con los probes bien separados.

**14. 🟡 Diferencia entre liveness y readiness probes y cómo las expone Boot.**
Liveness: si falla, el pod se reinicia — debe indicar "el proceso está roto sin remedio". Readiness: si falla, deja de recibir tráfico pero no se reinicia — indica "ahora mismo no puedo atender". Boot las expone en `/actuator/health/liveness` y `/readiness` con `management.endpoint.health.probes.enabled`. Error clásico: poner la base de datos en el liveness, lo que provoca reinicios en cascada cuando la base tiene un hipo.

**15. 🟠 ¿Cómo manejas la configuración de múltiples entornos?**
Perfiles (`application-prod.yml`), variables de entorno, y externalización por ConfigMap o Config Server. El orden de precedencia de Spring Boot está definido y hay que conocerlo: argumentos de línea de comandos > variables de entorno > `application-{profile}` externo > `application-{profile}` empaquetado > `application.yml`. Los secretos nunca en el repositorio.

**16. 🔴 ¿Qué le criticas a Spring Boot?**
Respuesta honesta y bien valorada: la magia implícita dificulta depurar cuando algo no se comporta como esperas; el arranque y la huella de memoria son altos frente a alternativas ligeras (Quarkus, Micronaut, que resuelven en compilación lo que Spring hace en ejecución); el classpath crece con transitividades que nadie revisa; y la facilidad de las anotaciones anima a saltarse el diseño. Nada de esto lo descalifica, pero un arquitecto debe saber qué está pagando.

---

## 🧩 Parte 2 — IoC, beans y ciclo de vida (17–32)

**17. 🟢 ¿Qué es la inversión de control y qué gana tu código con ella?**
El contenedor crea y conecta los objetos en lugar del propio código. Gana: dependencias explícitas y sustituibles, testabilidad, configuración centralizada y un ciclo de vida gestionado. Lo que **no** gana automáticamente es buen diseño: puedes inyectar dependencias y tener un acoplamiento terrible.

**18. 🟡 ¿Qué tipo de inyección impones en tu equipo y por qué?**
Constructor. Deja las dependencias explícitas en la firma, permite campos `final`, hace la clase testeable sin contenedor y convierte una dependencia circular en un fallo de arranque en vez de un bug latente. La inyección por campo se prueba solo con reflexión y esconde cuántas dependencias tiene realmente la clase — que suele ser el verdadero problema.

**19. 🟡 ¿Qué pasa si hay dos beans candidatos del mismo tipo?**
`NoUniqueBeanDefinitionException` al arrancar. Se resuelve con `@Primary` (un ganador por defecto), `@Qualifier` (elección explícita en el punto de inyección), o inyectando la colección completa (`List<T>` o `Map<String,T>`) cuando de verdad quieres todas las implementaciones — patrón Strategy servido por el contenedor.

**20. 🟠 ¿Cómo se resuelve una dependencia circular y por qué deberías evitarla?**
Spring Boot 2.6+ la **prohíbe por defecto** (`spring.main.allow-circular-references=false`). Se puede sortear con `@Lazy` o inyección por setter, pero eso es tratar el síntoma: un ciclo indica que dos clases comparten una responsabilidad y que falta extraer una tercera. Arréglalo con diseño, no con la propiedad.

**21. 🟡 Enumera los scopes de bean y da un caso de uso para cada uno.**
`singleton` (por defecto, servicios sin estado), `prototype` (objeto nuevo por petición de inyección, para estado por uso), `request` y `session` (web, contexto por petición o por usuario), `application` y `websocket`. Advertencia: un singleton que guarda estado mutable por usuario es un bug de concurrencia y, en banca, una fuga de datos entre clientes.

**22. 🟠 ¿Qué pasa si inyectas un prototype dentro de un singleton?**
Se resuelve una sola vez, al crear el singleton: recibes siempre la misma instancia, que es justo lo contrario de lo que querías. Soluciones: inyectar `ObjectProvider<T>` y pedir una instancia por uso, `@Lookup`, o un proxy de scope (`proxyMode = TARGET_CLASS`).

**23. 🟡 ¿Cuál es el ciclo de vida de un bean?**
Instanciación, inyección de dependencias, callbacks de `*Aware`, `BeanPostProcessor` antes de la inicialización, `@PostConstruct` / `afterPropertiesSet` / init-method, `BeanPostProcessor` después (aquí se crean los proxies de AOP), uso, y `@PreDestroy` / destroy-method al cerrar el contexto.

**24. 🟠 ¿Por qué `@PostConstruct` a veces no ve el comportamiento transaccional?**
Porque los proxies se aplican **después** de la inicialización del bean: dentro de `@PostConstruct` estás sobre la instancia cruda, no sobre el proxy, así que `@Transactional`, `@Cacheable` o `@Async` no actúan. Solución: hacer ese trabajo en un `ApplicationReadyEvent` o delegar en otro bean.

**25. 🟠 Diferencia entre `BeanFactoryPostProcessor` y `BeanPostProcessor`.**
El primero actúa sobre las **definiciones** de beans antes de instanciar nada (lo usa `PropertySourcesPlaceholderConfigurer` para resolver `${...}`). El segundo actúa sobre **instancias** ya creadas y es el mecanismo con el que Spring envuelve beans en proxies. Saber esta diferencia explica el orden de casi todo lo raro que ocurre al arrancar.

**26. 🟡 ¿Qué es `@Configuration` y en qué se diferencia de `@Component` con `@Bean`?**
`@Configuration` aplica proxy CGLIB a la clase para que las llamadas entre métodos `@Bean` devuelvan el singleton del contenedor y no una instancia nueva (modo `full`). Con `@Component`, esas llamadas son llamadas Java normales (modo `lite`) y crean objetos duplicados. Es una fuente clásica de bugs sutiles.

**27. 🟠 ¿Qué es `@ConfigurationProperties` y por qué es mejor que `@Value`?**
Enlaza un grupo de propiedades a un objeto tipado, con validación (`@Validated` + Bean Validation), soporte de estructuras anidadas y listas, y metadatos para el IDE. `@Value` es adecuado para un valor suelto; para un bloque de configuración es propenso a errores de tipeo detectados solo en ejecución. Con `record` + `@ConfigurationProperties` obtienes configuración inmutable y validada.

**28. 🟡 ¿Cómo defines beans condicionales propios?**
`@ConditionalOnProperty`, `@ConditionalOnClass`, `@ConditionalOnBean`, `@Profile`, o un `Condition` personalizado. Caso real: activar un cliente simulado del core bancario en entornos no productivos y el cliente real en producción, sin ramificar el código de negocio.

**29. 🟠 ¿Cómo controlas el orden de inicialización entre beans?**
`@DependsOn` cuando hay una dependencia real no expresada por inyección, `@Order` para ordenar colecciones de beans del mismo tipo (filtros, validadores), y `@AutoConfigureBefore/After` en autoconfiguraciones. Si necesitas mucho control de orden, normalmente hay un acoplamiento oculto que conviene explicitar.

**30. 🟠 ¿Qué son los eventos de aplicación y cuándo los usas?**
`ApplicationEventPublisher` publica y `@EventListener` consume, de forma **síncrona por defecto** dentro de la misma transacción. Se usan para desacoplar efectos secundarios del flujo principal. Dos detalles importantes: `@Async` los hace asíncronos (y entonces pierdes el contexto transaccional y de seguridad si no lo propagas), y `@TransactionalEventListener(AFTER_COMMIT)` evita reaccionar a algo que luego se revierte.

**31. 🟠 ¿Qué es AOP en Spring y cuáles son sus límites?**
Programación orientada a aspectos por proxy: intercepta llamadas para aplicar comportamiento transversal (transacciones, caché, seguridad, métricas). Límites que hay que conocer: no intercepta llamadas **internas** de la misma clase, no funciona sobre métodos `private` o `final`, y solo actúa sobre beans gestionados por Spring. AspectJ con weaving en compilación levanta esos límites a cambio de complejidad de build.

**32. 🔴 Un `@Transactional` no está haciendo rollback y nadie entiende por qué. Enumera todas las causas posibles.**
Llamada interna en la misma clase (el proxy no se atraviesa); método no público; la excepción es checked y no declaraste `rollbackFor`; capturaste la excepción dentro del método y no la relanzaste; el bean no está gestionado por Spring (lo creaste con `new`); el motor de base de datos no es transaccional para esa operación (DDL, o MyISAM); o estás en una propagación distinta a la que crees. Enumerarlas en orden y decir cómo verificas cada una es exactamente lo que evalúan.

---

## 🌐 Parte 3 — Web, REST y clientes HTTP (33–52)

**33. 🟢 ¿Cómo procesa Spring MVC una petición HTTP?**
El `DispatcherServlet` (Front Controller) recibe la petición, el `HandlerMapping` localiza el método controlador, los `HandlerInterceptor` se ejecutan antes, los `HandlerMethodArgumentResolver` resuelven los parámetros, se invoca el método, el `HttpMessageConverter` serializa el retorno (Jackson para JSON) o el `ViewResolver` resuelve la vista, y el `HandlerExceptionResolver` atiende los errores.

**34. 🟡 `@Controller` vs `@RestController`.**
`@RestController` es `@Controller` + `@ResponseBody` en todos los métodos: el retorno se serializa al cuerpo de la respuesta en vez de resolverse como nombre de vista. Para APIs siempre `@RestController`.

**35. 🟡 `@RequestParam`, `@PathVariable`, `@RequestBody`, `@RequestHeader`: ¿cuándo cada uno?**
Query string, segmento de la ruta, cuerpo de la petición y cabecera respectivamente. Criterio de diseño REST: identificadores de recurso en la ruta, filtros y paginación en query params, representación completa en el cuerpo. Nunca datos sensibles en la ruta ni en query params, porque acaban en logs de acceso y en el historial de proxies.

**36. 🟠 ¿Cómo diseñas los códigos de estado de una API bancaria?**
200 para éxito con cuerpo, 201 con `Location` para creación, 202 para aceptado y procesándose (muy común en pagos), 204 para éxito sin cuerpo. 400 para petición malformada, 401 no autenticado, 403 no autorizado, 404 no existe, 409 conflicto de estado, 422 semánticamente inválido, 429 rate limit. Y la regla de oro: **un error de negocio no es un 500**. El 500 es culpa tuya y debe disparar alerta.

**37. 🟠 ¿Cómo centralizas el manejo de errores?**
`@RestControllerAdvice` con `@ExceptionHandler` por tipo, sobre una jerarquía propia de excepciones de negocio. Usa `ProblemDetail` (RFC 7807, nativo en Spring 6) para un formato estándar. Incluye siempre un identificador de correlación y **nunca** stack traces ni mensajes del motor de base de datos: filtran estructura interna y son un hallazgo de seguridad.

**38. 🟡 ¿Cómo validas la entrada y cómo devuelves los errores de validación?**
`@Valid` en el parámetro con Bean Validation en el DTO, y un `@ExceptionHandler` para `MethodArgumentNotValidException` que devuelva la lista de campos y motivos. Para reglas compuestas o que dependen de varios campos, un `ConstraintValidator` propio a nivel de clase.

**39. 🟠 ¿Dónde pones la validación: DTO, servicio o dominio?**
En los tres, con propósitos distintos. En el DTO, validación **sintáctica** (formato, obligatoriedad, rangos) para rechazar rápido. En el dominio, las **invariantes de negocio**, que deben cumplirse venga la llamada de donde venga. En el servicio, las validaciones que requieren consultar estado externo. Confiar solo en la validación del DTO significa que cualquier otro punto de entrada se salta las reglas.

**40. 🟡 ¿Qué son los `HttpMessageConverter` y cómo personalizas la serialización?**
Convierten entre el cuerpo HTTP y objetos Java. Para JSON, Jackson: se personaliza con `Jackson2ObjectMapperBuilderCustomizer`, módulos (`JavaTimeModule` para `java.time`) y anotaciones (`@JsonProperty`, `@JsonIgnore`, `@JsonFormat`). Consejo bancario: serializa siempre las fechas en ISO-8601 con zona explícita, y los montos como string o entero en unidad mínima para no perder precisión en clientes JavaScript.

**41. 🟠 ¿Cómo implementas paginación y ordenamiento?**
`Pageable` de Spring Data resuelto automáticamente desde `page`, `size` y `sort`. Puntos que demuestran experiencia: limitar el `size` máximo (si no, alguien pedirá 100.000 y tumbará el servicio), evitar el `count` cuando no se necesita (`Slice` en vez de `Page`), y preferir paginación por cursor en conjuntos grandes porque el offset degrada y es inconsistente ante inserciones.

**42. 🟠 ¿Cómo manejas archivos grandes en subida y descarga?**
Subida: streaming, límites por `spring.servlet.multipart.max-file-size`, validación de tipo real (no de la extensión), y escritura directa al almacenamiento de objetos sin cargar el archivo en memoria. Descarga: `StreamingResponseBody` o `Resource`, o mejor aún, una URL prefirmada de S3 para que el archivo no atraviese tu aplicación.

**43. 🟡 ¿Qué son los `HandlerInterceptor` y en qué se diferencian de los filtros?**
Los filtros son del contenedor de servlets y ven todas las peticiones, incluidas las de recursos estáticos y las que no llegan a un controlador. Los interceptores son de Spring MVC, se ejecutan alrededor del manejador y tienen acceso a información del `HandlerMethod`. Para seguridad y correlación, filtro; para lógica que necesita saber qué controlador se invocó, interceptor.

**44. 🟠 ¿Cómo propagas un identificador de correlación por toda la aplicación?**
Un filtro que lee o genera el id, lo pone en el MDC de logging y en el contexto, y lo devuelve en la respuesta. Con OpenTelemetry o Micrometer Tracing esto viene resuelto y además propaga al cliente HTTP y al broker. Ojo con `@Async` y los pools: el MDC es un `ThreadLocal` y se pierde al cambiar de hilo si no lo propagas explícitamente.

**45. 🟡 `RestTemplate`, `WebClient` o `RestClient`: ¿cuál eliges hoy?**
`RestTemplate` está en modo mantenimiento. `WebClient` para reactivo o cuando quieres concurrencia y streaming. `RestClient` (Spring 6.1) para llamadas sincrónicas con API moderna y fluida. En una aplicación bloqueante nueva, `RestClient`; si ya usas WebFlux, `WebClient`.

**46. 🟠 ¿Qué configuras siempre en un cliente HTTP y por qué?**
Timeouts de conexión y de lectura **explícitos** —sin ellos, una dependencia lenta agota tu pool de hilos y te tumba—, pool de conexiones dimensionado, reintentos con backoff exponencial y jitter solo sobre operaciones idempotentes, circuit breaker, y logging del tiempo de respuesta por dependencia. Un cliente HTTP sin timeout es el fallo de producción más repetido de la industria.

**47. 🟠 ¿Qué es un cliente declarativo y cuándo lo usas?**
Una interfaz anotada de la que el framework genera la implementación: `@HttpExchange` con las HTTP Interfaces de Spring 6, o OpenFeign. Reduce el código repetitivo y deja el contrato legible. Contrapartida: menos control fino y una capa más de magia al depurar.

**48. 🟠 ¿Cómo implementas rate limiting en un API Spring Boot?**
Preferentemente **fuera** de la aplicación: API Gateway, ingress o service mesh, porque ahí proteges también del tráfico que nunca debería llegar. Dentro de la aplicación, Bucket4j con almacenamiento en Redis para que el límite sea global y no por instancia. Devuelve 429 con `Retry-After`. Decide también la clave del límite: por API key, por usuario o por IP, cada una con su fuga.

**49. 🟡 ¿Cómo habilitas y aseguras CORS?**
`@CrossOrigin` por controlador o configuración global con `CorsRegistry`. En producción, lista blanca de orígenes concretos: `allowedOrigins("*")` junto con credenciales es una combinación que el navegador rechaza y que, además, indica que nadie pensó el modelo de confianza.

**50. 🟠 ¿Qué es `@Async` y qué precauciones exige?**
Ejecuta un método en otro hilo mediante proxy. Precauciones: define tu propio `Executor` (el por defecto puede crear hilos sin límite), acota la cola y define política de rechazo, propaga contexto (seguridad, MDC, transacción **no** se propaga), y maneja las excepciones — con retorno `void` se pierden silenciosamente si no defines un `AsyncUncaughtExceptionHandler`.

**51. 🟠 ¿Cómo programas tareas y qué problema tienen en un cluster?**
`@Scheduled` con cron o intervalo fijo. El problema en cluster es que **todas las instancias ejecutan la tarea**. Soluciones: ShedLock, un bloqueo distribuido propio con restricción única, o delegar en un planificador externo (EventBridge, Quartz en modo cluster, o un CronJob de Kubernetes). En banca, ejecutar dos veces un proceso de cobro no es un detalle menor.

**52. 🔴 Un endpoint tarda 4 segundos cuando antes tardaba 80 ms y no hubo despliegue. ¿Cómo lo investigas?**
Ordena por probabilidad y verifica con datos: ¿afecta a todas las peticiones o solo al percentil alto? (sistémico vs contención). Revisa dependencias externas (métricas por cliente HTTP), base de datos (plan cambiado por crecimiento de datos o estadísticas desactualizadas, bloqueos), agotamiento del pool de conexiones o de hilos, GC, y caché que dejó de acertar. Instrumentación primero, hipótesis después. Y en paralelo, mitigación: escalar o degradar mientras investigas.

---

## 🗄️ Parte 4 — Datos, transacciones y caché (53–72)

**53. 🟢 ¿Qué te da Spring Data JPA y cuándo te estorba?**
Repositorios derivados del nombre del método, paginación, auditoría, proyecciones y `Specification`. Estorba cuando la consulta es compleja (el nombre del método se vuelve ilegible) o cuando necesitas control del plan de ejecución: ahí bajas a `@Query`, QueryDSL, `JdbcTemplate` o jOOQ. Saber cuándo bajarse del ORM es señal de arquitecto.

**54. 🟡 ¿Cómo funcionan las consultas derivadas y cuál es su límite práctico?**
Spring parsea el nombre (`findByTitularIdAndFechaBetweenOrderByFechaDesc`) y genera la consulta. El límite práctico: en cuanto el nombre supera unas pocas condiciones, es menos legible que el JPQL equivalente y más frágil ante renombrados. Regla de equipo razonable: hasta tres condiciones, derivada; más, `@Query` con nombre corto.

**55. 🟡 ¿Qué son las proyecciones y por qué importan al rendimiento?**
Devolver solo los campos necesarios en vez de la entidad completa, mediante interfaces o DTOs en el constructor de la consulta. Importan porque evitan cargar colecciones, evitan el contexto de persistencia y reducen el tráfico. En listados, una proyección suele valer más que cualquier índice nuevo.

**56. 🟠 Explica el N+1, cómo lo detectas y las tres formas de resolverlo.**
Una consulta para los padres y N para los hijos al acceder a colecciones lazy. Detección: contar sentencias en pruebas de integración o activar estadísticas de Hibernate, no esperar a producción. Soluciones: `JOIN FETCH`, `@EntityGraph`, `@BatchSize` (agrupa las N en lotes), o una proyección que no toque la colección. Matiz que demuestra oficio: `JOIN FETCH` con paginación pagina en memoria y Hibernate lo advierte en el log.

**57. 🟡 ¿Por qué `@ManyToOne` es EAGER por defecto y qué haces al respecto?**
Porque así lo define la especificación JPA, y es una mala decisión por defecto: arrastra grafos enteros sin que nadie lo pida. La práctica correcta es declarar `fetch = LAZY` explícitamente en todas las asociaciones y resolver la carga por caso de uso en la consulta.

**58. 🟠 ¿Qué es OSIV y por qué lo desactivarías?**
Open Session In View mantiene el `EntityManager` abierto durante toda la petición, incluida la serialización de la respuesta. Está **activo por defecto** en Spring Boot y lo avisa en el log. Desactívalo porque retiene conexiones del pool más tiempo del necesario, oculta N+1 (se ejecutan durante la serialización) y acopla la capa web al modelo de persistencia. El coste de desactivarlo es tener que ser explícito con las cargas — que es justamente lo deseable.

**59. 🟡 ¿Qué estados tiene una entidad JPA?**
Transient (nueva, sin id ni contexto), managed (en el contexto de persistencia; los cambios se detectan y se vuelcan en el flush), detached (fue managed, ya no) y removed. La consecuencia práctica más sorprendente para quien viene de JDBC: modificar una entidad managed persiste sin llamar a `save()`.

**60. 🟠 ¿Qué hace realmente `save()` de Spring Data JPA?**
Llama a `persist` si la entidad es nueva y a `merge` si no lo es, decidiéndolo por el id o por el `@Version`. Con una entidad managed, `save()` es redundante. Con una entidad detached que tiene id, `merge` provoca un SELECT previo — un coste invisible que aparece en los perfiles de rendimiento.

**61. 🟠 Propagación transaccional: explica `REQUIRED`, `REQUIRES_NEW` y `NESTED`.**
`REQUIRED` (por defecto) se une a la transacción existente o crea una. `REQUIRES_NEW` suspende la actual y abre otra independiente, con su propia conexión — útil para auditar o registrar algo que debe sobrevivir a un rollback, y peligroso porque consume dos conexiones simultáneas y puede deadlockear consigo mismo. `NESTED` usa savepoints: revierte solo su parte sin tumbar la externa, pero requiere soporte del driver.

**62. 🟠 ¿Qué niveles de aislamiento usas y cuál es el riesgo del predeterminado?**
El predeterminado depende del motor (`READ_COMMITTED` en PostgreSQL y SQL Server, `REPEATABLE_READ` en MySQL/InnoDB). El riesgo de `READ_COMMITTED` en banca: leer el saldo, decidir, y escribir, con otra transacción en medio — resultado, sobregiro. Se resuelve con bloqueo (optimista con `@Version` o pesimista con `FOR UPDATE`), no subiendo el aislamiento a ciegas, porque serializable cuesta muchísimo en concurrencia.

**63. 🟠 ¿Cómo manejas operaciones masivas sin reventar la memoria?**
Nada de cargar un millón de entidades. Usa `JdbcTemplate` o consultas nativas para `UPDATE`/`DELETE` masivos, procesa en lotes con `flush()` y `clear()` periódicos si debes pasar por JPA, activa `hibernate.jdbc.batch_size`, y considera streaming (`Stream<T>` con `@QueryHints` de fetch size). Y recuerda que las operaciones masivas por JPQL **no** actualizan el contexto de persistencia ni disparan callbacks.

**64. 🟡 ¿Cómo gestionas las migraciones de esquema?**
Flyway o Liquibase, versionadas en el repositorio y ejecutadas en el arranque o en un paso dedicado del pipeline. `spring.jpa.hibernate.ddl-auto` debe ser `validate` en producción y **nunca** `update`. En banca, además: revisión y aprobación del DBA, ensayo con volumen realista, y rollback planificado.

**65. 🟠 ¿Cómo haces una migración sin downtime?**
Patrón expand/contract: añadir la columna nueva nullable, desplegar código que escribe en ambas, rellenar los datos históricos en background, cambiar las lecturas, y solo en un despliegue posterior eliminar la vieja. Varios despliegues, cada uno compatible hacia atrás. Es la única forma de que un rollback siga funcionando.

**66. 🟡 ¿Cómo configuras el pool de conexiones y qué tamaño eliges?**
HikariCP por defecto en Boot. El tamaño no es "cuanto más mejor": un pool grande solo traslada la contención a la base de datos y aumenta la latencia. Dimensiona según los núcleos y discos del servidor de base de datos y el tiempo medio de consulta, y mide. Configura siempre `connection-timeout`, `max-lifetime` (menor que cualquier timeout del lado del servidor o del firewall) y `leak-detection-threshold`.

**67. 🟠 ¿Cómo detectas una fuga de conexiones?**
Síntoma: timeouts al pedir conexión mientras la base de datos está ociosa. Herramientas: `leak-detection-threshold` de Hikari, métricas de conexiones activas frente a ociosas en Actuator, y revisión de código que abra conexiones fuera del control de Spring. Causa habitual: un método que obtiene una conexión o un `EntityManager` a mano y no lo cierra en un `finally` o try-with-resources.

**68. 🟡 ¿Qué te da la abstracción de caché de Spring?**
`@Cacheable`, `@CachePut`, `@CacheEvict` sobre un proveedor intercambiable (Caffeine local, Redis distribuida, Hazelcast). Ventaja: el código no conoce el proveedor. Advertencias: funciona por proxy (nada de llamadas internas), y debes definir explícitamente el TTL y la clave — una clave mal elegida sirve datos de un cliente a otro, que en banca es un incidente de seguridad.

**69. 🟠 Caché local vs distribuida: ¿cómo decides?**
Local (Caffeine): latencia mínima, sin red, pero cada instancia tiene su copia y la invalidación es difícil; aceptable para datos muy estables. Distribuida (Redis): coherente entre instancias e invalidable, con el coste de una llamada de red y un punto de fallo más. Patrón mixto habitual: caché local de corta duración delante de la distribuida.

**70. 🟠 ¿Qué es el cache stampede y cómo lo evitas?**
Cuando expira una clave muy solicitada y cientos de peticiones van a la vez a la fuente original, tumbándola. Soluciones: bloqueo o `synchronized` en la carga (Caffeine lo ofrece), refresco anticipado antes de expirar, TTL con jitter para que no expire todo a la vez, y servir el valor obsoleto mientras se recalcula. Este es el tipo de detalle que separa a quien ha operado caché en producción.

**71. 🟠 ¿Qué haces cuando la caché distribuida se cae?**
Decisión de diseño explícita: degradar (ir a la fuente, con el riesgo de saturarla) o fallar rápido. La respuesta correcta depende del caso, pero debe estar **decidida y probada**, no descubierta en el incidente. Añade circuit breaker hacia la caché y límites de concurrencia hacia la fuente para no convertir una caída de Redis en una caída de la base de datos.

**72. 🔴 Diseña la estrategia de datos de un servicio de consulta de saldos con 5.000 peticiones por segundo.**
Capas: caché local muy corta, Redis con TTL alineado a la tolerancia de negocio a datos obsoletos (y eso hay que negociarlo con negocio, no decidirlo solo), y la fuente autoritativa detrás. Saldo como proyección actualizada por eventos, no calculada sumando movimientos en cada consulta. Invalidación por evento de movimiento, no solo por TTL. Circuit breaker hacia el core. Y la pregunta que debes plantear tú: ¿el negocio acepta un saldo con segundos de retraso en consulta, sabiendo que en la autorización de una transacción se lee siempre la fuente?

---

## 🧪 Parte 5 — Testing (73–84)

**73. 🟢 ¿Qué tipos de prueba escribes en un proyecto Spring Boot?**
Unitarias puras sin contexto (la mayoría, rápidas, con Mockito), de slice (`@WebMvcTest`, `@DataJpaTest`, `@JsonTest`) que cargan solo una porción del contexto, de integración (`@SpringBootTest`) con Testcontainers, de contrato entre servicios, y de carga. La pirámide sigue vigente: muchas rápidas abajo, pocas lentas arriba.

**74. 🟡 ¿Cuál es el problema de usar `@SpringBootTest` para todo?**
Lentitud y fragilidad: levantas el contexto completo para probar una regla de tres líneas, las pruebas tardan minutos y fallan por razones ajenas a lo que pruebas. Además el feedback lento hace que el equipo deje de ejecutarlas. Usa slices y pruebas puras para el grueso, y reserva el contexto completo para verificar el cableado real.

**75. 🟡 ¿Qué es `@WebMvcTest` y qué carga?**
Solo la capa web: controladores, filtros, `@ControllerAdvice` y convertidores, con `MockMvc` listo. No carga servicios ni repositorios, que se sustituyen con `@MockitoBean` (`@MockBean` en versiones anteriores). Ideal para probar contratos HTTP, validación, códigos de estado y serialización.

**76. 🟡 ¿Qué hace `@DataJpaTest`?**
Carga solo la capa de persistencia, configura una base embebida por defecto y **hace rollback de cada prueba** dentro de una transacción. Advertencia importante: probar contra H2 cuando producción es PostgreSQL u Oracle da falsa confianza — dialectos, tipos y comportamiento de bloqueos difieren. Por eso `@DataJpaTest` combinado con Testcontainers y la base real es la práctica sana.

**77. 🟠 ¿Por qué Testcontainers cambió la forma de probar?**
Permite levantar la base de datos, Kafka, Redis o LocalStack reales en Docker durante las pruebas, con ciclo de vida gestionado. Elimina la brecha entre entorno de prueba y producción sin depender de infraestructura compartida. Costes a mencionar: necesita Docker en el pipeline y aumenta el tiempo de ejecución; se mitiga con contenedores reutilizables y `@ServiceConnection` de Spring Boot 3.1, que cablea la configuración automáticamente.

**78. 🟠 ¿Cómo pruebas código transaccional correctamente?**
Cuidado con `@Transactional` en la prueba: hace rollback al final y puede ocultar problemas reales de flush, y además la lógica se ejecuta dentro de **una sola** transacción, lo que no refleja el comportamiento real entre varias llamadas. Para verificar la semántica transaccional real, ejecuta sin transacción en la prueba y limpia explícitamente, o usa `TestTransaction` para controlar los límites.

**79. 🟡 ¿Cuándo usas mocks y cuándo no?**
Mockea lo que está **fuera de tu control**: clientes HTTP externos, colas, servicios de terceros. No mockees tu propio dominio ni el repositorio si puedes usar la base real con Testcontainers — un mock del repositorio prueba que llamas al método, no que la consulta funciona. Regla útil: si el mock replica la lógica del colaborador, estás probando el mock.

**80. 🟠 ¿Qué es WireMock y para qué lo usas?**
Un servidor HTTP simulado que responde con escenarios configurados, incluyendo latencias y fallos. Lo usas para probar la resiliencia de tus clientes: qué hace tu código con un 503, con un timeout, con una respuesta malformada. Ese camino de error es el que casi nadie prueba y el que rompe en producción.

**81. 🟠 ¿Qué son las pruebas de contrato y qué problema resuelven?**
Verifican que productor y consumidor comparten el mismo entendimiento del contrato, sin necesidad de una prueba end-to-end. Spring Cloud Contract o Pact. Resuelven el problema de que un cambio en el productor rompa a un consumidor y nadie lo sepa hasta producción, algo muy común cuando los equipos despliegan a ritmos distintos.

**82. 🟡 ¿Cómo verificas la cobertura y qué porcentaje exiges?**
JaCoCo integrado en el pipeline y reportado en SonarQube con quality gate. Postura defendible: la cobertura es un **indicador**, no un objetivo; 80% con aserciones débiles no vale nada. Más útil que el número global es exigir cobertura sobre el **código nuevo** de cada PR, que es lo que impide que la deuda crezca.

**83. 🟠 ¿Qué es el testing de mutación y por qué es mejor indicador que la cobertura?**
PIT introduce mutaciones en el bytecode (cambia un `>` por `>=`, elimina una llamada) y verifica si alguna prueba falla. Si no falla, la línea estaba cubierta pero no **verificada**. Es el antídoto directo contra la cobertura decorativa. Coste: es lento, así que suele ejecutarse en el pipeline nocturno y sobre los módulos críticos.

**84. 🔴 ¿Cómo pruebas un flujo asíncrono o eventual sin volver las pruebas inestables?**
Nunca con `Thread.sleep`. Usa Awaitility con condición y timeout, o mejor, diseña puntos de observación determinísticos: espera a que el consumidor confirme el offset, o expón un estado consultable. Para lo que dependa del reloj, inyecta `Clock`. Y si una prueba sigue siendo intermitente, trátala como un bug de diseño del sistema o de la prueba, no la marques como ignorada — las pruebas intermitentes destruyen la confianza del equipo en la suite entera.

---

## 📈 Parte 6 — Producción: observabilidad, seguridad y rendimiento (85–100)

**85. 🟢 ¿Qué es Actuator y qué expones en producción?**
Endpoints de gestión: `health`, `metrics`, `prometheus`, `info`, `env`, `loggers`, `threaddump`, `heapdump`. En producción expón lo mínimo (`health`, `prometheus`, `info`), **en un puerto de gestión separado** no accesible desde internet, y protegido. `heapdump` y `env` sin protección son una filtración de datos: `env` muestra propiedades que suelen incluir credenciales.

**86. 🟡 ¿Cómo personalizas el health check?**
Implementando `HealthIndicator`. Criterio importante: incluye en `readiness` lo que realmente impide atender (base de datos, dependencia crítica) y **no** incluyas dependencias externas en `liveness`, porque un fallo transitorio del proveedor provocaría reinicios masivos que empeoran todo. Los health checks deben ser baratos y con timeout propio.

**87. 🟡 ¿Qué es Micrometer y qué métricas instrumentas primero?**
Una fachada de métricas que exporta a Prometheus, CloudWatch, Datadog. Instrumenta primero las cuatro señales doradas: latencia (con percentiles, no medias), tráfico, errores y saturación (pools, colas, hilos). Después, métricas de negocio: transacciones por tipo, montos, tasa de rechazo — que suelen detectar incidentes antes que las técnicas.

**88. 🟠 ¿Por qué las medias mienten y qué usas en su lugar?**
Porque una media esconde la cola: con 99 peticiones de 10 ms y una de 5 s, la media es 60 ms y parece sana, pero un usuario esperó 5 segundos. Usa percentiles (p50, p95, p99) y define los SLO sobre p99. Micrometer los publica con histogramas; cuidado con la cardinalidad de etiquetas, que es la causa número uno de explosión de coste en métricas.

**89. 🟠 ¿Cómo estructuras el logging en una aplicación bancaria?**
Logging estructurado en JSON para poder consultarlo, niveles usados con criterio (ERROR solo para lo que requiere acción humana), identificador de correlación en cada línea, y **enmascaramiento obligatorio** de datos sensibles: PAN, documentos, credenciales, tokens. Y define retención y coste: tu propia experiencia de reducción de logs demuestra que loguear todo no es observabilidad, es una factura.

**90. 🟠 ¿Qué es el tracing distribuido y cómo lo habilitas en Boot 3?**
Micrometer Tracing con OpenTelemetry o Brave, exportando a Tempo, Jaeger o X-Ray. Propaga el contexto por HTTP y por mensajería automáticamente. Su valor: ante una latencia alta, te dice **en qué salto** se perdió el tiempo, algo imposible de deducir de logs sueltos. Configura muestreo: 100% es caro, pero un muestreo bajo pierde justo los casos raros que investigas — por eso conviene muestreo adaptativo o forzado ante errores.

**91. 🟡 ¿Cómo gestionas secretos en Spring Boot?**
Nunca en el repositorio ni en la imagen. Variables de entorno inyectadas desde AWS Secrets Manager, Parameter Store, Vault o secretos de Kubernetes cifrados en reposo. Añade rotación y verifica que la aplicación la soporte sin reinicio, o que el reinicio esté automatizado. Y escanea el repositorio (gitleaks, detect-secrets) en el pipeline, porque el secreto siempre acaba filtrándose una vez.

**92. 🟠 ¿Qué cambia en Spring Boot 3 frente a 2?**
Java 17 como mínimo, migración de `javax.*` a `jakarta.*` (el cambio que más rompe), Spring Framework 6, soporte nativo de GraalVM, observabilidad unificada con Micrometer, `ProblemDetail` para errores, y Spring Security 6 sin `WebSecurityConfigurerAdapter`. La migración real duele por las dependencias de terceros que aún no publicaron versión Jakarta.

**93. 🟠 ¿Cómo abordarías la migración de una aplicación de Boot 2.7 a 3.x?**
Primero Java 17 y Boot 2.7 como base estable; inventario de dependencias de terceros y su compatibilidad Jakarta (aquí suele estar el bloqueo real); usar OpenRewrite para la migración masiva de paquetes; cobertura de pruebas suficiente **antes** de empezar; y hacerlo en pasos pequeños y desplegables. Documenta lo que no puede migrarse y qué alternativa tiene.

**94. 🟠 ¿Qué opinas de GraalVM native image para un banco?**
Ventajas reales: arranque en milisegundos y mucha menos memoria, valioso para escalado rápido y serverless. Costes que hay que declarar: compilación lenta (minutos), reflexión y proxies dinámicos requieren configuración o hints, algunas librerías no lo soportan, y la depuración y el profiling en producción son más pobres. Recomendación honesta: adecuado para servicios acotados y de alta elasticidad, no como decisión por defecto para todo el portafolio.

**95. 🟠 ¿Cómo optimizas el consumo de memoria de un servicio Spring Boot en Kubernetes?**
Fija límites de heap coherentes con el límite del contenedor (la JVM moderna respeta cgroups, pero conviene ser explícito con `MaxRAMPercentage`), recuerda que metaspace, hilos y buffers directos viven **fuera** del heap, revisa el tamaño del pool de hilos y de conexiones, y mide con métricas de JVM en Actuator. Error clásico: fijar el límite del pod igual al heap y que el kernel mate el proceso por OOM sin que la JVM se entere.

**96. 🟠 ¿Qué es el patrón sidecar y cómo se relaciona con una app Spring Boot?**
Un contenedor auxiliar junto a la aplicación que asume responsabilidades transversales: proxy del service mesh (mTLS, reintentos, telemetría), recolector de logs, agente de secretos. Permite que la aplicación se concentre en negocio. Trade-off: más recursos por pod y una capa más que depurar cuando algo va mal en la red.

**97. 🟠 ¿Cómo implementas feature flags y qué disciplina exigen?**
Desde una propiedad con `@ConditionalOnProperty` hasta una plataforma dedicada (Unleash, LaunchDarkly) con cambio en caliente. Disciplina imprescindible: cada flag tiene dueño y fecha de retiro. Un sistema con 200 flags olvidados es un espacio de estados que nadie puede probar ni razonar, y en banca eso es riesgo operacional.

**98. 🔴 Tu servicio Spring Boot funciona bien con 100 usuarios y colapsa con 1.000. ¿Cómo lo abordas?**
Medir antes de tocar nada: ¿dónde está la saturación? Pool de conexiones, hilos del servidor, CPU, GC, o una dependencia externa. Reproduce con una prueba de carga (Gatling, tu propia experiencia) para tener un banco de pruebas repetible. Después ataca por orden de impacto: consultas y N+1 primero (suele ser ahí), caché donde los datos lo permitan, concurrencia para llamadas independientes, y solo entonces escalar horizontalmente. Escalar sin diagnosticar multiplica el coste y a veces ni siquiera resuelve, si el cuello está en la base de datos.

**99. 🔴 ¿Qué reglas de arquitectura impondrías en un proyecto Spring Boot de un equipo de 15 personas?**
Estructura por dominio, no por capa técnica. Inyección por constructor obligatoria. Nada de entidades JPA en los contratos de API. Transacciones solo en la capa de aplicación, nunca en controladores ni repositorios. Timeouts explícitos en todo cliente externo. Sin lógica de negocio en `@ControllerAdvice` ni en mappers. Y lo más importante: **verificarlas automáticamente** con ArchUnit y el quality gate, porque una regla que solo vive en una wiki se incumple en tres sprints.

**100. 🔴 Si tuvieras que justificar Spring Boot frente a Quarkus o Micronaut ante un comité técnico, ¿qué dirías?**
A favor de Spring Boot: ecosistema y madurez incomparables, disponibilidad de talento (crítico en un banco que contrata continuamente), soporte comercial y de largo plazo, e integración con prácticamente todo lo que un banco ya tiene. A favor de los otros: arranque y memoria mucho mejores por resolver en compilación lo que Spring hace en ejecución, lo que importa en serverless y en despliegues muy elásticos. Recomendación defendible: Spring Boot como estándar corporativo por talento y riesgo, con la puerta abierta a alternativas en nichos específicos y medidos. Y menciona que Boot 3 con native image acorta buena parte de esa distancia.

---

> 🧭 **Cierre:** en Spring Boot la diferencia entre un senior y un intermedio casi nunca está en saber más anotaciones. Está en saber **qué hace el proxy**, **dónde se pierde una transacción**, **qué pasa cuando la dependencia externa no responde** y **cuánto cuesta cada capa de magia**. Prepara esas cuatro y el resto se sostiene solo.
