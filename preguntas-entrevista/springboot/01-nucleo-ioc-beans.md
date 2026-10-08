# 🌱 180 preguntas de entrevista — Núcleo de Spring: IoC, beans, ciclo de vida y AOP

> Primer tópico de la serie Spring Boot. Referencia: Spring Boot 3.x / Spring Framework 6.
> Cubre el contenedor, la inyección, los scopes, el ciclo de vida, la definición y extensión
> de beans, los eventos de aplicación y los proxies. Lo que no está aquí: autoconfiguración
> y arranque (tópico 02), configuración externalizada (03), web (04).
> **Dificultad:** 🟢 base · 🟡 estándar · 🟠 profundidad · 🔴 abierta o adversarial

> **Salto rápido:**

> [⚙️ Parte 1 — Fundamentos del contenedor IoC (1–20)](#️-parte-1--fundamentos-del-contenedor-ioc-120)  
> [💉 Parte 2 — Inyección de dependencias (21–45)](#-parte-2--inyección-de-dependencias-2145)  
> [🧭 Parte 3 — Resolución de candidatos y cualificadores (46–65)](#-parte-3--resolución-de-candidatos-y-cualificadores-4665)  
> [🔄 Parte 4 — Scopes de bean (66–85)](#-parte-4--scopes-de-bean-6685)  
> [🌀 Parte 5 — Ciclo de vida de un bean (86–110)](#-parte-5--ciclo-de-vida-de-un-bean-86110)  
> [🧰 Parte 6 — Definición de beans: `@Configuration`, `@Bean`, `@Import` (111–135)](#-parte-6--definición-de-beans-configuration-bean-import-111135)  
> [🔌 Parte 7 — Extensión del contenedor y AOT (136–150)](#-parte-7--extensión-del-contenedor-y-aot-136150)  
> [📡 Parte 8 — Eventos de aplicación (151–162)](#-parte-8--eventos-de-aplicación-151162)  
> [🪞 Parte 9 — Proxies y AOP (163–180)](#-parte-9--proxies-y-aop-163180)

---

## ⚙️ Parte 1 — Fundamentos del contenedor IoC (1–20)

**1. 🟢 ¿Qué es la inversión de control y qué gana tu código con ella?**
El control de la creación y conexión de objetos pasa del propio código a un contenedor externo. Gana dependencias explícitas y sustituibles, testabilidad sin tocar el código de producción, configuración centralizada y un ciclo de vida gestionado. Lo que **no** gana automáticamente es buen diseño: se puede inyectar todo y seguir teniendo un acoplamiento terrible.

**2. 🟢 ¿IoC y inyección de dependencias son lo mismo?**
No. IoC es el principio general de ceder el control del flujo o del ensamblado a otro (también lo es un framework que te llama a ti en vez de que tú lo llames). La inyección de dependencias es **una** técnica concreta de IoC: entregar las colaboraciones ya resueltas al objeto. Spring implementa DI como su forma principal de IoC, pero no son sinónimos.

**3. 🟡 `BeanFactory` vs `ApplicationContext`.**
`BeanFactory` es el contrato mínimo: registro y resolución de beans con instanciación perezosa. `ApplicationContext` lo extiende con lo que hace útil a Spring: publicación de eventos, resolución de mensajes i18n, acceso a recursos, jerarquía de contextos y pre-instanciación de singletons al refrescar. En una aplicación se usa siempre `ApplicationContext`; `BeanFactory` aparece cuando extiendes el contenedor.

**4. 🟡 ¿Qué implementación de `ApplicationContext` arranca Spring Boot?**
Depende del tipo de aplicación, y Boot lo deduce del classpath: `AnnotationConfigServletWebServerApplicationContext` para MVC, `AnnotationConfigReactiveWebServerApplicationContext` para WebFlux, y `AnnotationConfigApplicationContext` para una aplicación sin servidor. Se puede forzar con `spring.main.web-application-type` (`servlet`, `reactive`, `none`), que es lo que haces en un job batch que tiene el starter web por transitividad y no debe levantar un puerto.

**5. 🟡 ¿Qué es una `BeanDefinition`?**
La **receta** del bean, no el bean: clase o método factoría, scope, si es lazy, si es primary, dependencias declaradas, init y destroy methods, valores de propiedades. El contenedor primero registra todas las definiciones y solo después instancia. Entender esa separación en dos fases explica casi todo el comportamiento raro del arranque.

**6. 🟠 ¿Dónde viven las definiciones y quién las puede modificar?**
En el `BeanFactory` interno del contexto, típicamente un `DefaultListableBeanFactory`, que implementa `BeanDefinitionRegistry`. Se pueden registrar o alterar desde un `BeanFactoryPostProcessor`, un `ImportBeanDefinitionRegistrar` o un `ApplicationContextInitializer`, siempre **antes** de que se instancie nada. Después de la instanciación, tocar definiciones ya no tiene efecto sobre los singletons creados.

**7. 🟡 ¿Qué es el component scan y cómo se acota?**
El barrido del classpath buscando clases anotadas con estereotipos para registrarlas como definiciones. Se acota con `basePackages`, `basePackageClasses` y filtros de inclusión o exclusión. Por defecto `@SpringBootApplication` escanea el paquete de la clase principal y todo lo que cuelga de él, de ahí la convención de ubicarla en la raíz.

**8. 🟡 `@Component`, `@Service`, `@Repository`, `@Controller`: ¿en qué se diferencian de verdad?**
Para el contenedor, en casi nada: los tres primeros son `@Component` con otro nombre. La diferencia real es **semántica** (comunican el rol de la clase) y, en dos casos, funcional: `@Repository` activa la traducción de excepciones de persistencia y `@Controller` marca la clase como manejador para Spring MVC. Usarlos con criterio importa porque las reglas de ArchUnit y los aspectos se escriben sobre ellos.

**9. 🟠 ¿Qué hace exactamente la traducción de excepciones de `@Repository`?**
Un `PersistenceExceptionTranslationPostProcessor` envuelve el bean en un proxy que convierte las excepciones propietarias del proveedor (`HibernateException`, `SQLException` con códigos del motor) en la jerarquía `DataAccessException` de Spring, que es unchecked y agnóstica del motor. El valor: tu capa de servicio puede distinguir un `DuplicateKeyException` de un `DeadlockLoserDataAccessException` sin importar si detrás hay Oracle o PostgreSQL. Con Spring Data la traducción ya viene aplicada en los repositorios generados.

**10. 🟡 ¿Para qué sirven `includeFilters` y `excludeFilters` en `@ComponentScan`?**
Para registrar clases que no llevan estereotipo (por tipo, por anotación, por expresión regular o con un `TypeFilter` propio) o para excluir las que sí lo llevan. Caso habitual: en una prueba, excluir la configuración de seguridad o un `@Component` que arranca conexiones. Caso sospechoso: usarlos para inventar un estereotipo propio cuando bastaba una anotación meta-anotada con `@Component`.

**11. 🟠 ¿Cuánto cuesta el component scan y qué alternativas hay?**
Cuesta abrir y leer los metadatos de cada clase del rango escaneado; en un monolito con miles de clases y varios paquetes raíz, son cientos de milisegundos o más. Alternativas por orden de coste: acotar los paquetes, declarar beans explícitos con `@Bean`, usar `spring-context-indexer` para generar un índice en compilación (`META-INF/spring.components`), y en Boot 3 el procesamiento AOT, que resuelve el registro en build time. Antes de optimizar, mide con el endpoint `startup`.

**12. 🟡 ¿Por qué la clase principal debe estar en el paquete raíz?**
Porque define el origen del escaneo. Si la pones en `com.banco.app.web`, no se verán los componentes de `com.banco.app.domain`, y el síntoma es un `UnsatisfiedDependencyException` que parece un problema de cableado y en realidad es de ubicación. La alternativa de añadir paquetes a mano funciona, pero rompe la convención que todo el equipo espera.

**13. 🟠 ¿Qué riesgos tiene declarar varios paquetes base de escaneo?**
Amplía la superficie: puedes registrar sin querer componentes de una librería de terceros, arrastrar configuraciones que abren conexiones o duplicar beans y provocar ambigüedad. Además hace el arranque más lento y el alcance menos evidente para quien lea el código. Si necesitas beans de otro módulo, la forma limpia es que ese módulo exponga una `@Configuration` importable o una autoconfiguración, no que tú escanees su paquete.

**14. 🟡 El scope singleton de Spring, ¿es el patrón Singleton de la GoF?**
No. El Singleton de la GoF es una instancia única **por classloader**, impuesta por la propia clase con un constructor privado y accesible globalmente. El singleton de Spring es una instancia única **por contenedor**, gestionada desde fuera, con la clase completamente normal y testeable. La diferencia es importante: puedes tener dos contextos en la misma JVM (pruebas, contexto padre de Actuator) y por tanto dos instancias.

**15. 🟠 ¿Cuándo se instancian los singletons?**
Al refrescar el contexto, de forma **anticipada** (`preInstantiateSingletons`), antes de que llegue la primera petición. Esa decisión es deliberada: es preferible que un error de cableado o de configuración tumbe el arranque a que aparezca con tráfico real. Los beans marcados como lazy quedan fuera de esa pasada.

**16. 🟡 ¿Qué hace `@Lazy` y qué cuesta?**
Retrasa la creación del bean hasta el primer uso; en el punto de inyección, hace que se inyecte un proxy que resuelve el bean al invocarlo. Cuesta perder la verificación temprana: un fallo de construcción aparece en la primera llamada, posiblemente en producción y dentro de una petición de un cliente. Úsalo para beans realmente caros y raramente usados, no como norma.

**17. 🟠 ¿Qué ventaja y qué trampa tiene `spring.main.lazy-initialization=true`?**
Ventaja: arranque notablemente más rápido, muy útil en desarrollo y en pruebas. Trampa: traslada los fallos de cableado y de configuración al primer uso de cada rama de código, con lo que un despliegue puede pasar los health checks y romperse veinte minutos después en un endpoint poco frecuentado. En producción, o no se usa, o se acompaña de un calentamiento explícito de los caminos críticos.

**18. 🟠 ¿Qué es `ObjectProvider` y qué problemas resuelve?**
Una abstracción de acceso perezoso al contenedor inyectable como dependencia: `getIfAvailable()`, `getIfUnique()`, `stream()`, `orderedStream()`. Resuelve tres casos sin ensuciar el diseño: dependencias opcionales, obtener una instancia nueva de un prototype en cada uso, y consumir todas las implementaciones de un tipo de forma ordenada. Es el sustituto honesto de inyectar el `ApplicationContext`.

**19. 🟡 ¿Se puede registrar un bean en tiempo de ejecución?**
Técnicamente sí, obteniendo el `BeanDefinitionRegistry` y registrando una definición, o con `registerSingleton` en el `BeanFactory`. En la práctica, casi nunca deberías: el contenedor está pensado para quedar fijo tras el refresco, los proxies y los post-procesadores ya se aplicaron, y lo que buscas suele resolverse con un scope propio, una factoría de negocio normal o `ObjectProvider`.

**20. 🔴 ¿Necesitas Spring para hacer inyección de dependencias? Defiende tu postura.**
No: DI es un principio de diseño y se hace con constructores y un `main` que ensambla. Lo que aporta el contenedor es el ensamblado a escala (cientos de beans, varios entornos), el ciclo de vida, y sobre todo el enganche de comportamiento transversal por proxy: transacciones, seguridad, caché, métricas. La respuesta madura reconoce el coste: magia implícita, arranque más lento y la tentación de resolver con anotaciones lo que era un problema de diseño. En un servicio pequeño y muy elástico, DI manual o un framework de compilación puede ser la decisión correcta.

---

## 💉 Parte 2 — Inyección de dependencias (21–45)

**21. 🟢 ¿Qué formas de inyección soporta Spring?**
Por constructor, por setter y por campo (reflexión directa). También existe la inyección en métodos arbitrarios anotados y la resolución perezosa vía `ObjectProvider`. La recomendación oficial y la de cualquier equipo serio es constructor para lo obligatorio y setter para lo verdaderamente opcional.

**22. 🟡 ¿Por qué impones inyección por constructor?**
Deja las dependencias explícitas en la firma, permite campos `final` y por tanto objetos inmutables y seguros entre hilos, hace la clase instanciable en una prueba sin contenedor, y convierte una dependencia circular en un fallo de arranque en lugar de un bug latente. Además el dolor de un constructor con nueve parámetros es una señal de diseño visible, no escondida entre anotaciones.

**23. 🟡 Con un único constructor, ¿hace falta `@Autowired`?**
No desde Spring 4.3: si la clase tiene un solo constructor, el contenedor lo usa. Dejarlo fuera es la práctica actual y hace que la clase no dependa sintácticamente de Spring. Si hay varios constructores, sí hay que marcar cuál.

**24. 🟠 Con varios constructores, ¿cómo elige Spring?**
Busca uno anotado con `@Autowired`; si no hay ninguno, intenta el que puede satisfacer con los beans disponibles, con preferencia por el más "greedy" resoluble, y cae al sin argumentos si existe. Ese algoritmo es una fuente de sorpresas: el bean arranca con el constructor que no esperabas y una dependencia queda a nulo. Con Kotlin o Lombok generando constructores, el problema se multiplica; la defensa es tener un único constructor.

**25. 🟡 ¿Cuándo es legítima la inyección por setter?**
Cuando la dependencia es de verdad opcional y la clase funciona sin ella, o cuando necesitas reconfigurarla después de la construcción. En la práctica casi siempre es una excusa; si la clase no funciona sin la dependencia, el setter miente sobre su contrato y permite construir objetos a medio hacer.

**26. 🟠 ¿Qué problemas concretos tiene la inyección por campo?**
No permite `final`, así que el objeto es mutable; obliga a reflexión o al contenedor para construirlo en pruebas; esconde el número real de dependencias (una clase con quince `@Autowired` no incomoda a nadie); y permite ciclos que solo estallan más tarde. Añade un problema práctico: en una clase abstracta compartida, los campos inyectados se heredan y nadie sabe de dónde vienen.

**27. 🟡 ¿Cómo declaras una dependencia opcional?**
`@Autowired(required = false)` en setter o campo, un parámetro `Optional<T>` en el constructor, `@Nullable`, o `ObjectProvider<T>` con `getIfAvailable()`. La preferencia moderna es `ObjectProvider` para controlar el momento, u `Optional<T>` cuando solo quieres el valor. Y una pregunta previa: si es opcional, ¿no debería haber una implementación por defecto que haga nada, en vez de comprobaciones de nulo repartidas?

**28. 🟡 ¿Qué ocurre si inyectas `List<MiInterfaz>`?**
Recibes todas las implementaciones registradas, en el orden dado por `@Order` u `Ordered`, o indefinido si no lo declaras. Es el patrón Strategy o Chain servido por el contenedor, y una forma elegante de que añadir una clase nueva no obligue a modificar código existente. Ojo con dos cosas: la lista vacía falla por defecto (usa `required=false` u `ObjectProvider`), y depender del orden sin declararlo es un bug esperando el próximo refactor.

**29. 🟡 ¿Y si inyectas `Map<String, MiInterfaz>`?**
Obtienes las implementaciones indexadas por nombre de bean. Es cómodo para despachar por clave (`map.get(tipoDeOperacion)`), pero acopla la lógica al nombre del bean, que es un detalle de infraestructura. Más robusto: que cada estrategia declare la clave que soporta en un método de la propia interfaz y construir el índice a partir de ahí.

**30. 🟠 ¿Cómo resuelve Spring los tipos genéricos al inyectar?**
Con `ResolvableType`, que lee la información genérica del bytecode: inyectar `Validador<Transferencia>` selecciona el bean cuyo tipo genérico coincide, sin necesidad de cualificadores. Funciona porque los genéricos de una firma de campo, parámetro o método `@Bean` sí están en los metadatos de la clase, aunque se borren en tiempo de ejecución para las instancias. Es el mecanismo que hace viable el patrón de un handler tipado por tipo de evento o de comando.

**31. 🟠 ¿Se puede inyectar en un método que no sea setter?**
Sí: `@Autowired` en cualquier método hace que el contenedor lo invoque tras la instanciación con todos sus parámetros resueltos. Se usa para configuración que necesita varias dependencias a la vez o en clases base de pruebas. Es poco frecuente y conviene que sea poco frecuente: el orden de invocación de varios de estos métodos no es algo que quieras razonar.

**32. 🟡 `@Autowired` vs `@Inject` vs `@Resource`.**
`@Autowired` es de Spring y resuelve **por tipo**, con el nombre como desempate. `@Inject` es el estándar (`jakarta.inject`) y se comporta igual, sin soportar `required=false`. `@Resource` es de JSR-250 y resuelve **por nombre** primero, cayendo al tipo. La consecuencia práctica: con dos candidatos del mismo tipo, `@Resource` con el nombre correcto funciona donde `@Autowired` falla, pero mezclar estilos en un mismo proyecto es una fuente de confusión gratuita.

**33. 🟠 ¿Cómo inyectas valores de configuración y qué te permite SpEL?**
`@Value("${banca.timeout}")` resuelve un placeholder contra el `Environment`; `@Value("#{...}")` evalúa SpEL, que puede leer otros beans, hacer operaciones y ternarios. Que SpEL pueda hacerlo no significa que deba: lógica en una expresión dentro de una anotación no se compila, no se prueba y no se refactoriza. Y nunca evalúes SpEL construido con entrada del usuario, que es ejecución remota de código.

**34. 🟡 ¿Cómo das un valor por defecto y cómo inyectas una lista con `@Value`?**
Valor por defecto con dos puntos: `@Value("${banca.reintentos:3}")`. Listas separando por comas, que Spring convierte a `List<String>` o a un array, incluso con conversión de tipos; para mapas o estructuras anidadas, `@Value` deja de ser razonable. Ese es justo el punto en que hay que pasar a `@ConfigurationProperties`.

**35. 🟠 ¿Qué es la auto-inyección (self-injection) y para qué se usa?**
Inyectar el propio bean, normalmente con `@Lazy` para evitar el ciclo, con el fin de invocar un método propio **a través del proxy** y activar así `@Transactional`, `@Cacheable` o `@Async` en una llamada interna. Funciona, y es mejor que `AopContext.currentProxy()`, que exige `exposeProxy`. Pero es un parche: la señal correcta es que ese método pertenece a otra clase, y extraerlo resuelve el problema y mejora el diseño.

**36. 🟠 ¿Por qué falla hoy una dependencia circular que antes funcionaba?**
Porque desde Spring Boot 2.6 `spring.main.allow-circular-references` está en `false` y el arranque se detiene con un mensaje que dibuja el ciclo. Antes se resolvía silenciosamente con referencias tempranas entre singletons, lo que producía casos en que un bean recibía una instancia a medio inicializar o sin proxy aplicado. El cambio convirtió un bug latente en un fallo visible, que es exactamente lo deseable.

**37. 🟠 ¿Cómo rompes de verdad un ciclo A↔B?**
Identificando qué comparten: normalmente hay una responsabilidad que pertenece a una tercera clase C de la que ambas dependen, o un flujo que debería ir en una sola dirección. Otras salidas legítimas: invertir la dependencia con una interfaz que declare el consumidor, o publicar un evento en vez de llamar de vuelta. Activar la propiedad o poner `@Lazy` es tratar el síntoma y dejar el acoplamiento intacto.

**38. 🟡 ¿Cuándo es aceptable `@Lazy` para romper un ciclo?**
Cuando el ciclo está en código que no controlas (una librería, un framework legado) y el refactor no está a tu alcance en ese momento, o como medida temporal documentada con una fecha. Aceptable no es lo mismo que bueno: deja un comentario que explique el ciclo real, porque el siguiente que lo lea asumirá que era necesario.

**39. 🟠 ¿Qué pasa si inyectas un bean prototype dentro de un singleton?**
Se resuelve **una sola vez**, al construir el singleton: recibes siempre la misma instancia, lo contrario de lo que pretendías, y además compartida entre hilos. Soluciones por orden de preferencia: `ObjectProvider<T>` y pedir una instancia en cada uso, `@Lookup`, o un proxy de scope con `proxyMode = TARGET_CLASS`. Y la pregunta de fondo: si necesitas un objeto nuevo por operación, quizá no sea un bean, sino un objeto de dominio creado con `new`.

**40. 🟠 ¿Qué es `@Lookup`?**
Una anotación sobre un método abstracto o sobrescribible cuya implementación genera Spring: cada invocación devuelve una instancia fresca del bean de retorno. Internamente subclasea el bean con CGLIB, así que la clase no puede ser `final` ni el método `private`. Hoy `ObjectProvider` cubre el mismo caso con código explícito y sin generación de subclases, y es la opción que elegiría.

**41. 🟡 `ObjectFactory`, `ObjectProvider` y `Provider`: ¿qué eliges?**
`ObjectFactory` es la interfaz original mínima; `Provider` es el estándar de `jakarta.inject`; `ObjectProvider` es la extensión de Spring y la más rica (opcionalidad, unicidad, streams ordenados). En un proyecto Spring, `ObjectProvider`. `Provider` tiene sentido si quieres que la clase no dependa de tipos de Spring.

**42. 🟠 ¿Por qué es un antipatrón inyectar el `ApplicationContext`?**
Porque convierte la clase en un service locator: sus dependencias dejan de estar en la firma, no se pueden ver ni sustituir sin arrancar un contexto, y la clase queda atada al framework. Además esconde el momento de resolución, así que un bean que falta deja de ser un error de arranque y pasa a ser una excepción en ejecución. Salidas legítimas: `ObjectProvider`, un `Map` o `List` inyectados, o una factoría propia con una interfaz tuya.

**43. 🟠 ¿Cuántas dependencias son demasiadas en un constructor?**
No hay número mágico, pero pasando de cinco o seis conviene parar y mirar: casi siempre la clase tiene más de una responsabilidad, o varias dependencias se usan juntas y deberían estar detrás de una sola abstracción. La trampa a evitar es "resolverlo" pasando a inyección por campo o a un objeto de parámetros: el número no baja, solo deja de verse. Y un matiz: un orquestador de un caso de uso complejo puede legítimamente coordinar a muchos colaboradores.

**44. 🟡 Para configuración, ¿`@Value` en el constructor o `@ConfigurationProperties`?**
Un valor suelto y aislado, `@Value` en el parámetro del constructor. Un grupo de propiedades relacionadas, `@ConfigurationProperties` sobre un `record`, que te da tipado, validación con Bean Validation, estructuras anidadas, metadatos para el IDE y un único objeto inyectable. La ventaja decisiva es que los errores de nombre o de tipo aparecen al arrancar, no la primera vez que se lee la propiedad.

**45. 🔴 Revisas un PR con una clase de 400 líneas y once dependencias inyectadas por campo. ¿Qué comentas y en qué orden?**
Primero el problema de fondo, no el estilo: once colaboradores significan varias responsabilidades, así que pido identificar los casos de uso y proponer la división, aunque sea en varios pasos. Segundo, la inyección por campo, explicando el coste concreto (no hay `final`, no se puede construir en una prueba, el número de dependencias queda invisible) y no como regla de wiki. Tercero, si el refactor no cabe en este PR, acordar un cambio mecánico a constructor ahora y un ticket con dueño para la división, más una regla de ArchUnit que impida que el patrón se repita. Y lo que **no** haría: bloquear el PR por el estilo si arregla un incidente en curso.

---

## 🧭 Parte 3 — Resolución de candidatos y cualificadores (46–65)

**46. 🟢 ¿Qué pasa si hay dos beans candidatos del mismo tipo?**
`NoUniqueBeanDefinitionException` al arrancar, con la lista de candidatos en el mensaje. Se resuelve con `@Primary`, `@Qualifier`, o inyectando la colección completa si de verdad quieres todas. Que falle al arrancar y no al usar es una de las mejores propiedades del contenedor.

**47. 🟡 ¿Qué hace `@Primary` y cuándo es la herramienta correcta?**
Marca el ganador por defecto cuando hay ambigüedad de tipo. Es correcta cuando existe una implementación claramente principal y otras excepcionales (el cliente real frente a uno instrumentado para pruebas). Es incorrecta cuando las dos son igual de legítimas: ahí `@Primary` esconde la decisión y el siguiente que inyecte el tipo recibirá algo que no esperaba.

**48. 🟡 ¿Cómo funciona `@Qualifier`?**
Añade una etiqueta al bean y a los puntos de inyección, y la resolución exige coincidencia. Se puede usar con el nombre del bean o con un valor arbitrario declarado en la definición. Su defecto es que es una cadena: un error de tipeo se convierte en un fallo de arranque —aceptable— pero un renombrado silencioso es más difícil de rastrear que una referencia de tipo.

**49. 🟠 ¿Cómo creas un cualificador propio con seguridad de tipos?**
Defines una anotación anotada con `@Qualifier` (por ejemplo `@CoreBancario` o `@Reintentable`) y la usas en la definición y en el punto de inyección. Ganas autocompletado, refactorización segura y un nombre con significado de dominio en vez de una cadena. Es la forma que recomendaría en una base de código grande con varias implementaciones del mismo puerto.

**50. 🟠 Si no hay `@Primary` ni `@Qualifier`, ¿Spring puede desempatar por nombre?**
Sí: como último recurso compara el nombre del punto de inyección (nombre del campo o del parámetro) con los nombres de los beans candidatos. Es una comodidad peligrosa porque depende de que el nombre del parámetro sobreviva a la compilación (`-parameters`) y de que nadie lo renombre en un refactor. Funciona, pero no es algo sobre lo que quieras construir el cableado de un servicio crítico.

**51. 🟡 ¿Cómo se determina el nombre por defecto de un bean y qué colisiones provoca?**
Para un componente escaneado, el nombre simple de la clase con la primera letra en minúscula; para un método `@Bean`, el nombre del método. La colisión clásica: dos clases con el mismo nombre simple en paquetes distintos producen el mismo nombre de bean, y según la configuración una sobrescribe a la otra o el arranque falla. Es un argumento práctico contra tener dos `AccountService` en el mismo proyecto.

**52. 🟠 ¿Cómo asignas nombres o alias explícitos a un bean?**
`@Bean(name = {"principal", "alias"})` o `@Component("nombre")`; el primer valor es el nombre y el resto alias. Los alias sirven para compatibilidad durante una migración, cuando código viejo referencia el nombre anterior. Mantener alias indefinidamente es deuda: pon fecha de retiro.

**53. 🟠 ¿Se puede sobrescribir una definición de bean y deberías?**
Desde Spring Boot 2.1 está desactivado por defecto y hay que activar `spring.main.allow-bean-definition-overriding`. Que esté desactivado es correcto: la sobrescritura dependía del orden de registro, es decir, del azar del escaneo, y producía fallos imposibles de razonar. La forma legítima de "sustituir" un bean de librería es que la librería lo declare con `@ConditionalOnMissingBean`, o usar `@Primary`, o en pruebas `@MockitoBean` y `@TestConfiguration`.

**54. 🟡 Como consumidor de una librería, ¿cómo aprovechas `@ConditionalOnMissingBean`?**
Declarando tu propio bean del mismo tipo: la autoconfiguración de la librería se aparta. Es la base de la filosofía de Spring Boot, "convención que puedes anular sin pelearte con el framework". Para que funcione, tu bean debe estar declarado del tipo que la condición comprueba, algo que se olvida cuando se devuelve la clase concreta y la condición mira la interfaz.

**55. 🟡 ¿Qué es `@Profile` y dónde se aplica?**
Un condicional sobre perfiles activos, aplicable a `@Component`, `@Configuration` y métodos `@Bean`. Uso típico: un emisor de notificaciones real en `prod` y uno que solo registra en el log en `dev`. Uso que conviene evitar: `@Profile("!prod")` disperso por decenas de clases, que hace imposible saber qué se está ejecutando en cada entorno.

**56. 🟠 ¿Qué expresiones admite `@Profile` y qué es el perfil `default`?**
Admite negación (`!prod`), conjunción (`prod & eu`) y disyunción (`dev | test`), con paréntesis. El perfil `default` se aplica cuando no hay ningún perfil activo, lo que sirve para dar un comportamiento de arranque local sin configuración. Advertencia operativa: si el pipeline activa siempre algún perfil, los beans de `default` nunca se cargan y la asimetría entre local y desplegado te muerde.

**57. 🟠 ¿Prefieres `@Profile` o condicionar por propiedad?**
Propiedad, en general: `@ConditionalOnProperty` nombra la **capacidad** (`banca.notificaciones.reales=true`) en vez del entorno, se documenta sola y permite combinaciones que el perfil no anticipó. Los perfiles tienden a convertirse en una variable global de la que dependen decisiones no relacionadas, y a multiplicarse (`prod-eu-canary`). Reservo los perfiles para agrupar bloques de configuración por entorno, no para decidir comportamiento de negocio.

**58. 🟡 ¿Qué hace `matchIfMissing` en `@ConditionalOnProperty`?**
Define el comportamiento cuando la propiedad no está declarada: con `true`, la condición se cumple por ausencia, es decir, la funcionalidad está activada por defecto. Es la diferencia entre "opt-in" y "opt-out", y conviene decidirla a conciencia: una característica peligrosa debe requerir activación explícita, y una que ya es el estándar debe poder desactivarse.

**59. 🟠 ¿Cómo escribes un `Condition` propio?**
Implementas `Condition` (o `SpringBootCondition` para tener mensajes en el informe) y decides a partir del `ConditionContext`, que da acceso al `Environment`, al registro de definiciones, al classloader y a los recursos. Caso real: activar un bean solo si la región del entorno pertenece a una lista, o si existe un fichero de certificado. Regla de oro: la condición no debe instanciar beans ni tener efectos secundarios, porque se evalúa muy temprano.

**60. 🟠 ¿Cuál es la trampa de `@ConditionalOnBean` en configuración propia?**
Que depende del **orden de registro**: la condición se evalúa con el estado del registro en ese momento, y las clases de usuario se procesan antes que las autoconfiguraciones. Por eso `@ConditionalOnBean` es fiable dentro de una autoconfiguración —ordenada con `@AutoConfigureAfter`— y muy poco fiable en una `@Configuration` normal, donde puede dar un resultado distinto según qué se escaneó primero. Si necesitas ese comportamiento, el sitio correcto es una autoconfiguración.

**61. 🟠 `@Order`, `Ordered` y `PriorityOrdered`: ¿qué ordena cada cosa?**
`@Order` e `Ordered` ordenan colecciones de beans del mismo tipo: filtros, interceptores, aspectos, validadores; menor valor, mayor prioridad. `PriorityOrdered` es un contrato reforzado para post-procesadores de infraestructura, que se aplican antes que cualquier `Ordered`. Lo que **no** hacen es controlar el orden de creación de beans: eso es `@DependsOn` o una dependencia real.

**62. 🟡 ¿Para qué sirve `@DependsOn`?**
Para forzar que otro bean se inicialice antes, cuando existe una dependencia real que no se expresa por inyección: un bean que registra un driver, ejecuta una migración o inicializa una librería nativa. Es una declaración por nombre, con lo cual es frágil ante renombrados. Si aparece a menudo, hay un acoplamiento oculto que merece hacerse explícito convirtiéndolo en una dependencia de verdad.

**63. 🟠 ¿Cómo implementas Strategy con el contenedor sin `if` ni `switch`?**
Una interfaz con un método que declare la clave soportada (`soporta(TipoOperacion)` o `clave()`), varias implementaciones como beans, e inyección de `List<Estrategia>` en un despachador que construye el índice al inicializarse y falla si hay claves duplicadas o si falta una del enumerado. Añadir una operación nueva pasa a ser añadir una clase. Los dos detalles que separan una implementación buena de una ingenua son la validación de completitud al arrancar y un comportamiento definido para la clave desconocida.

**64. 🟠 Necesitas una variante de comportamiento por país o por tenant. ¿Cómo lo cableas?**
No con perfiles ni con un bean por tenant si los tenants son datos: el número crece y el contexto no. La forma sana es un registro de estrategias indexado por tenant, resuelto en tiempo de ejecución a partir del contexto de la petición, con una implementación por defecto explícita. Si la variación es solo de parámetros y no de comportamiento, es configuración (`Map<String, ReglasTenant>` con `@ConfigurationProperties`), no beans.

**65. 🔴 Tienes un puerto `CoreBancarioClient` con una implementación real y una simulada. ¿Cómo lo cableas sin ensuciar el negocio?**
El negocio depende solo de la interfaz y nunca sabe cuál recibe. La selección va en una `@Configuration` de infraestructura con `@ConditionalOnProperty("banca.core.modo")`, no con un `if` en el servicio ni con un perfil consultado dentro de la lógica. Añado tres cosas que suelen faltar: que el simulado sea imposible de activar en producción (fallo de arranque si el perfil es `prod`, verificado en una prueba), que ambos cumplan el mismo contrato verificado con las mismas pruebas, y que el `/actuator/info` diga qué implementación está activa, porque en un incidente lo primero que quieres saber es contra qué estabas hablando.

---

## 🔄 Parte 4 — Scopes de bean (66–85)

**66. 🟢 Enumera los scopes y da un caso de uso para cada uno.**
`singleton` (por defecto; servicios sin estado, repositorios, clientes HTTP), `prototype` (una instancia por petición de inyección, para estado por uso), `request` y `session` (web: contexto por petición o por usuario), `application` (uno por `ServletContext`) y `websocket` (uno por sesión de WebSocket). Además hay scopes que añaden otros módulos, como `refresh` de Spring Cloud o `job`/`step` de Spring Batch.

**67. 🟡 Un singleton, ¿es único en la JVM?**
No: es único **por contexto**. En la misma JVM puedes tener varios contextos —una jerarquía padre/hijo, el contexto de gestión de Actuator en puerto separado, o varios contextos cacheados en la suite de pruebas—, y entonces hay varias instancias. Importa cuando el bean guarda algo que asumías global, como un contador o un registro de métricas.

**68. 🟡 ¿Quién destruye un bean prototype?**
Nadie: el contenedor lo crea, lo inyecta y se desentiende. No se invoca `@PreDestroy` ni `destroyMethod`, así que un prototype que abre un recurso lo filtra. Si necesitas liberación, hazlo con try-with-resources en el código que lo pide, o con un `DestructionAwareBeanPostProcessor`; o mejor, no modeles como bean algo con ciclo de vida propio.

**69. 🟠 ¿Cómo puede inyectarse un bean de scope `request` en un singleton?**
Mediante un proxy de scope: se inyecta un objeto delegante que, en cada llamada, resuelve la instancia real del scope activo desde un `ThreadLocal` (`RequestContextHolder`). Por eso funciona y por eso falla fuera de una petición con `No thread-bound request found`. Si el proxy se usa desde un hilo distinto al de la petición, el fallo es inmediato y desconcertante.

**70. 🟠 ¿Qué riesgos tiene el scope `session` en un despliegue en cluster?**
La sesión debe existir y ser accesible en la instancia que atiende la petición: sin sesiones replicadas o externalizadas (Spring Session con Redis), un balanceo sin afinidad pierde datos. Añade coste de serialización, invalida el diseño stateless que quieres en Kubernetes y complica el escalado y los despliegues rolling. Para una API es casi siempre la decisión equivocada: el estado va en un token o en un almacén explícito.

**71. 🟡 `application` scope vs `singleton`.**
`singleton` es uno por `ApplicationContext`; `application` es uno por `ServletContext`, es decir, compartido entre contextos de Spring que vivan en la misma aplicación web. En una aplicación Spring Boot típica con un único contexto son prácticamente indistinguibles, y por eso `application` casi no se usa. Tiene sentido en despliegues WAR con varios dispatchers.

**72. 🟡 ¿Cuándo usarías el scope `websocket`?**
Cuando necesitas estado por conexión de WebSocket: el usuario autenticado, las suscripciones activas, un buffer. Su ciclo de vida sigue la sesión de WebSocket, no la petición HTTP. Igual que con `session`, en cluster hay que pensar dónde vive ese estado si la conexión se restablece contra otra instancia.

**73. 🟠 ¿Cómo implementas un scope personalizado y cuándo tiene sentido?**
Implementas `Scope` (con `get`, `remove`, `registerDestructionCallback`) y lo registras con un `CustomScopeConfigurer` o `beanFactory.registerScope`. Tiene sentido cuando hay una unidad de trabajo real que no es la petición: un lote de mensajes consumidos, un tenant, una conversación. Lo delicado es la limpieza: un scope que no elimina sus instancias es una fuga de memoria, y si guarda datos de cliente, además una fuga de datos.

**74. 🟠 `proxyMode = TARGET_CLASS` vs `INTERFACES`.**
`INTERFACES` usa un proxy dinámico de JDK y solo funciona si inyectas por interfaz. `TARGET_CLASS` subclasea con CGLIB y funciona con clases concretas, a cambio de exigir que la clase no sea `final`, que tenga un constructor accesible y de no interceptar métodos `final`. Con clases concretas o `record`, `TARGET_CLASS` es la única opción viable —y con `record`, que es `final`, directamente no hay proxy posible.

**75. 🟠 ¿Por qué un singleton con estado mutable es un bug?**
Porque todas las peticiones concurrentes comparten esa instancia: un campo que guarda el usuario actual, el importe en curso o un `StringBuilder` reutilizado produce condiciones de carrera. En banca el fallo no es solo un dato incorrecto, es que un cliente vea información de otro, con lo que deja de ser un bug de concurrencia y pasa a ser un incidente de privacidad reportable. La regla es simple: los beans son stateless, el estado viaja en los parámetros.

**76. 🟠 ¿Cómo detectas un singleton con estado antes de que llegue a producción?**
Revisión dirigida a campos no `final` y no inyectados; una regla de ArchUnit que prohíba campos mutables en clases anotadas con `@Service` salvo excepciones declaradas; pruebas de concurrencia sobre los servicios críticos; y pruebas de carga que comparen resultados por usuario en paralelo. El análisis estático ayuda (SpotBugs tiene detectores de estado compartido), pero lo que de verdad encuentra estos casos es la prueba concurrente con aserciones por identidad de cliente.

**77. 🟡 ¿Es aceptable un `ThreadLocal` en un bean singleton?**
Es el mecanismo habitual para contexto por petición (seguridad, correlación, tenant) y en ese uso es correcto. Las dos precauciones son obligatorias: limpiar en un `finally` o en un filtro, porque los hilos se reutilizan del pool y el valor sobreviviría a la siguiente petición —de otro cliente—, y recordar que no se propaga a `@Async`, pools propios ni cadenas reactivas sin un `TaskDecorator` o un contexto explícito. Con virtual threads la limpieza importa menos, pero el resto sigue igual.

**78. 🟠 ¿Qué pasa con un bean de scope `request` dentro de un `@Async` o en WebFlux?**
En `@Async` se ejecuta en otro hilo y el `ThreadLocal` de la petición no está: el proxy lanza excepción salvo que propagues el contexto (`RequestContextHolder` con herencia, o un `TaskDecorator`). En WebFlux el modelo de un hilo por petición no existe, así que los scopes web tradicionales no aplican y el contexto se lleva en el `Context` reactivo. Es una de las razones por las que trasplantar código MVC a WebFlux rara vez es mecánico.

**79. 🟠 ¿Qué es el `refresh` scope de Spring Cloud y qué cuidado exige?**
Un scope cuyos beans se destruyen y se vuelven a crear cuando llega un evento de refresco de configuración, de forma que recogen los valores nuevos sin reiniciar el proceso. El cuidado: la recreación ocurre en caliente y de forma perezosa, así que un bean caro se reconstruye dentro de una petición, y si el bean mantiene conexiones hay que asegurar la liberación. Además el estado a mitad de refresco es mixto, algo que hay que asumir explícitamente o evitar recargando en vez de refrescando.

**80. 🟡 ¿Cómo se declara el scope en un método `@Bean`?**
Con `@Scope("prototype")` o `@Scope(value = WebApplicationContext.SCOPE_REQUEST, proxyMode = ScopedProxyMode.TARGET_CLASS)` junto al `@Bean`. Es el mismo mecanismo que en un componente escaneado. Detalle relevante: si el bean se consume desde otro método `@Bean` de la misma clase de configuración, el proxy de `@Configuration` interviene, y el scope no siempre se comporta como se espera.

**81. 🟠 Un objeto es caro de construir y necesitas uno por operación. ¿Prototype?**
Probablemente no. Prototype paga la construcción completa en cada uso, así que para algo caro lo que quieres es reutilización: un pool explícito, un objeto inmutable compartido, o separar la parte caras (que es singleton) del estado por operación (que es un objeto de dominio creado con `new`). La pregunta a hacerse es si ese objeto tiene identidad y ciclo de vida propios —entonces no es un bean— o si solo lleva datos.

**82. 🟡 ¿Qué garantiza Spring sobre la seguridad entre hilos de un bean?**
Nada. El contenedor gestiona creación, cableado y destrucción; la seguridad concurrente es responsabilidad del código. Ni el scope singleton la aporta ni el prototype la garantiza —un prototype inyectado en un singleton acaba compartido, como ya vimos—. Que Spring no diga nada al respecto es justamente por eso: no puede.

**83. 🟠 Si los beans deben ser stateless, ¿dónde pones el estado que sí existe?**
En tres sitios, según su naturaleza: en los parámetros y valores de retorno para el estado de la operación; en un almacén explícito (base de datos, Redis, un token firmado) para el estado que debe sobrevivir a la petición; y en un contexto por petición con limpieza garantizada para el estado transversal (usuario, correlación, tenant). El caso especial son los cachés y los contadores, que sí viven en beans, y para los que se usan estructuras concurrentes o librerías pensadas para ello (`Caffeine`, `Micrometer`), no campos a pelo.

**84. 🟠 ¿Qué scope tienen los `@ConfigurationProperties` y son mutables?**
Son beans singleton normales. Con clases y setters son mutables, y alguien puede cambiarlos en ejecución afectando a todos —lo he visto usado como "configuración dinámica" y es una fuente de comportamiento irreproducible—. Con `record` o clases con constructor enlazado son inmutables, que es la forma que impondría; para valores que deben cambiar en caliente, el mecanismo correcto es `refresh` scope o una plataforma de feature flags, no un setter público.

**85. 🔴 Un campo de instancia en un `@Service` filtró datos entre clientes. ¿Cómo evitas que vuelva a pasar, a nivel sistémico?**
No con un comentario en el PR. Cinco capas: una regla de ArchUnit que falle el build ante campos mutables no inyectados en los estereotipos de servicio; el estado por petición canalizado por un único mecanismo aprobado y revisado (un `RequestContext` con limpieza en filtro), para que nadie improvise; pruebas de concurrencia con aserciones de aislamiento por cliente en los flujos que manejan datos personales; revisión obligatoria de dos personas en el paquete de dominio; y en el plano operativo, un post mortem que registre el patrón en la guía del equipo con el ejemplo real. Añadiría una pregunta incómoda: ¿había forma de detectarlo en producción? Si la respuesta es no, falta también una alerta sobre respuestas con identificador de cliente distinto al del token.

---

## 🌀 Parte 5 — Ciclo de vida de un bean (86–110)

**86. 🟢 ¿Cuál es el ciclo de vida de un bean?**
Instanciación, inyección de dependencias, callbacks de las interfaces `*Aware`, `BeanPostProcessor` antes de la inicialización, inicialización (`@PostConstruct`, `afterPropertiesSet`, `initMethod`), `BeanPostProcessor` después de la inicialización —donde se crean los proxies de AOP—, uso, y al cerrar el contexto `@PreDestroy`, `destroy()` y `destroyMethod`. Saber este orden explica el 90% de lo que parece magia inexplicable al arrancar.

**87. 🟡 `@PostConstruct`, `InitializingBean` e `initMethod`: ¿en qué orden se ejecutan?**
Primero `@PostConstruct`, después `afterPropertiesSet()` de `InitializingBean`, y por último el `initMethod` declarado en `@Bean`. Los tres hacen lo mismo; la elección es de acoplamiento: `@PostConstruct` es un estándar de Jakarta y no ata la clase a Spring, `InitializingBean` sí, y `initMethod` deja la clase completamente limpia y es la opción para código de terceros. Usar más de uno en la misma clase no aporta nada y confunde.

**88. 🟠 ¿Qué cambió con `@PostConstruct` en Spring Boot 3?**
Pasó de `javax.annotation` a `jakarta.annotation`, y en Java 11+ ya no viene en el JDK, así que la dependencia (`jakarta.annotation-api`) tiene que estar en el classpath —los starters de Boot la traen—. El síntoma cuando falta o cuando queda la versión `javax` mezclada es peor que un error de compilación: la anotación se ignora silenciosamente y el método de inicialización nunca se ejecuta. Es uno de los fallos más difíciles de diagnosticar en una migración de Boot 2 a 3.

**89. 🟠 ¿Por qué `@Transactional` o `@Cacheable` no funcionan dentro de `@PostConstruct`?**
Porque los proxies se crean en el `BeanPostProcessor` **posterior** a la inicialización: durante `@PostConstruct` estás ejecutando sobre la instancia cruda, no sobre el proxy, y ninguna anotación interceptada actúa. Además otros beans pueden no estar completamente inicializados. La solución es mover ese trabajo a un listener de `ApplicationReadyEvent`, a un `ApplicationRunner`, o delegar en otro bean inyectado.

**90. 🟡 ¿Cuándo **no** se llama a `@PreDestroy`?**
Cuando el proceso muere sin cerrar el contexto: `SIGKILL`, `System.exit` abrupto, OOM kill del kernel, o un contenedor que supera el `terminationGracePeriodSeconds` de Kubernetes. Tampoco se llama en beans prototype ni en objetos creados con `new`. Conclusión de diseño: `@PreDestroy` sirve para liberar ordenadamente en el caso bueno, nunca para garantizar consistencia; lo que debe sobrevivir a una muerte súbita se persiste antes, no al salir.

**91. 🟠 ¿Qué es `destroyMethod` inferido?**
En un método `@Bean`, si no declaras `destroyMethod`, Spring busca un método público `close()` o `shutdown()` sin argumentos y lo invoca al cerrar el contexto. Es cómodo con `DataSource`, clientes y executors, y a la vez sorprendente: un bean con un `close()` que no querías que se llamara se cierra igual. Se desactiva con `@Bean(destroyMethod = "")`, que es exactamente lo que necesitas cuando el objeto lo gestiona otra librería.

**92. 🟡 ¿Para qué sirven las interfaces `*Aware`?**
Para que el contenedor inyecte piezas de infraestructura antes de la inicialización: `BeanNameAware`, `BeanFactoryAware`, `ApplicationContextAware`, `EnvironmentAware`, `ResourceLoaderAware`, `ApplicationEventPublisherAware`. Se usan al escribir infraestructura —una autoconfiguración, un post-procesador—, no en código de negocio, donde la inyección normal cubre todo lo razonable.

**93. 🟠 ¿Por qué evitarías `ApplicationContextAware` en código de negocio?**
Porque es el mismo antipatrón de service locator que inyectar el contexto: oculta las dependencias, ata la clase a Spring y traslada los errores de cableado al tiempo de ejecución. En una clase de dominio es además una violación de capas: el dominio no debería conocer el framework. Si aparece, casi siempre se sustituye por `ObjectProvider`, por una colección inyectada o por una interfaz propia con una implementación en infraestructura.

**94. 🟠 ¿Qué es `SmartInitializingSingleton` y qué problema resuelve?**
Un callback que se invoca cuando **todos** los singletons no lazy ya están instanciados e inicializados. Resuelve el caso en que un bean necesita inspeccionar o registrar a otros y con `@PostConstruct` los encontraría a medias o forzaría su creación prematura. Es el gancho que usan registros, validadores de convenciones y catálogos de estrategias.

**95. 🟠 `Lifecycle` vs `SmartLifecycle`.**
`Lifecycle` da `start()`/`stop()` para beans que no son el propio contexto, pero no se invoca automáticamente al refrescar salvo que sea `SmartLifecycle` con `isAutoStartup()`. `SmartLifecycle` añade además `getPhase()` para ordenar arranques y paradas —las fases menores arrancan antes y paran después— y un `stop(Runnable)` asíncrono. Es el mecanismo correcto para componentes que consumen o publican (listeners de mensajería, servidores) y que deben pararse en un orden concreto en un apagado elegante.

**96. 🟠 ¿En qué orden se destruyen los beans y por qué importa en el apagado?**
En orden inverso al de creación, respetando las dependencias: un bean se destruye antes que aquellos de los que depende. Importa porque en un apagado quieres dejar de aceptar trabajo nuevo, terminar el en curso y solo entonces cerrar el pool de conexiones o el productor de Kafka; si el orden no es el correcto, las últimas operaciones fallan con recursos cerrados. Cuando la dependencia no está expresada por inyección, se declara con `@DependsOn` o con las fases de `SmartLifecycle`.

**97. 🟡 ¿Qué eventos publica `SpringApplication` durante el arranque?**
Por orden: `ApplicationStartingEvent`, `ApplicationEnvironmentPreparedEvent`, `ApplicationContextInitializedEvent`, `ApplicationPreparedEvent`, `ContextRefreshedEvent`, `ApplicationStartedEvent`, `AvailabilityChangeEvent` (readiness), `ApplicationReadyEvent`, y en caso de error `ApplicationFailedEvent`. Los tres primeros ocurren antes de que el contexto exista, así que un `@EventListener` no los ve: hay que registrar el listener en `SpringApplication` o en `spring.factories`.

**98. 🟠 `ApplicationReadyEvent` vs `ContextRefreshedEvent`: ¿cuál usas?**
`ContextRefreshedEvent` se dispara cuando el contexto está listo pero antes de los runners y, en una aplicación web, antes de que el servidor esté aceptando tráfico. `ApplicationReadyEvent` es el último: contexto refrescado, runners ejecutados y aplicación en servicio. Para trabajo de inicialización que deba ver la aplicación completamente operativa —precalentar, registrarse en un discovery, publicar un evento de despliegue—, `ApplicationReadyEvent`.

**99. 🟠 ¿Es cierto que un listener de `ContextRefreshedEvent` puede ejecutarse dos veces?**
Sí, y es una causa clásica de trabajo duplicado: con una jerarquía de contextos (el contexto de gestión de Actuator en puerto separado, un contexto padre, Spring Cloud con contexto de bootstrap) el evento se publica en cada refresco, y los eventos se propagan a los listeners del padre. La defensa es comprobar el origen del evento o usar `ApplicationReadyEvent`, que se publica una sola vez por aplicación. En un job que inicia una migración o un envío, la diferencia es visible en producción.

**100. 🟡 ¿Dónde pones el trabajo de inicialización de la aplicación?**
Fuera de los constructores y fuera de `@PostConstruct` si necesita proxies, transacciones o la aplicación en servicio. Las opciones sanas son `ApplicationRunner`/`CommandLineRunner` para trabajo secuencial al arrancar, un listener de `ApplicationReadyEvent` para efectos que requieren la aplicación lista, y un paso externo del pipeline para lo que no debería ejecutar la aplicación en absoluto —las migraciones de esquema en un banco, por ejemplo, suelen ser un job aparte con aprobación.

**101. 🟠 `CommandLineRunner` vs `ApplicationRunner`, y su orden.**
El primero recibe los argumentos crudos como `String...`; el segundo los recibe parseados en `ApplicationArguments`, con acceso a opciones y a argumentos no-opción. Cuando hay varios de cualquiera de los dos tipos, el orden lo da `@Order` u `Ordered`, y si no lo declaras es indefinido, lo que en la práctica significa que funcionará hasta que deje de hacerlo. Para un CLI o un job, `ApplicationRunner`.

**102. 🟠 Si un runner lanza una excepción, ¿la aplicación arranca?**
No: la excepción se propaga, el contexto se cierra y `SpringApplication.run` falla con código de salida distinto de cero. Es el comportamiento correcto para un job, y también para una aplicación web cuando el runner hace algo imprescindible. Si lo que hace el runner es opcional —precalentar un caché—, capturar y registrar es lo adecuado, porque tumbar el servicio por un calentamiento fallido es peor que arrancar frío.

**103. 🟠 ¿Cómo usas `ApplicationFailedEvent`?**
Registrando un listener que reciba el fallo para notificarlo antes de que el proceso muera: enviarlo al sistema de alertas, dejar un log estructurado con la causa raíz, o incrementar una métrica de fallo de arranque. Es valioso precisamente porque el proceso está a punto de desaparecer y los mecanismos normales de observabilidad quizá no se hayan inicializado. En Kubernetes, sin esto, un `CrashLoopBackOff` solo cuenta lo que quepa en los logs del contenedor.

**104. 🟡 ¿Qué es un `FailureAnalyzer`?**
El mecanismo con el que Boot convierte un stack trace en un mensaje legible con causa y acción ("el puerto 8080 está en uso", "falta la URL del datasource"). Puedes registrar los tuyos para los fallos propios de tu plataforma interna: un certificado ausente, una variable de entorno obligatoria, una versión incompatible del core bancario. En una organización con muchos equipos consumiendo tu starter, es la diferencia entre un ticket de soporte y un arranque que se arregla solo.

**105. 🟠 ¿Para qué sirve un `SpringApplicationRunListener`?**
Para enganchar código en las fases del arranque anteriores a que exista el contexto: `starting`, `environmentPrepared`, `contextPrepared`, `started`, `ready`, `failed`. Se registra en `META-INF/spring.factories`. Es territorio de infraestructura: medir el arranque, inicializar logging o telemetría antes que nada, validar el entorno de forma temprana.

**106. 🟠 ¿Y un `ApplicationContextInitializer`?**
Se ejecuta con el contexto creado pero **antes** de refrescarlo, así que es el punto donde se pueden registrar definiciones, añadir `PropertySource`s o activar perfiles de forma programática. Se declara en `spring.factories`, en `context.initializer.classes` o vía `SpringApplication`. Uso típico: cargar configuración de una fuente propia (un almacén de secretos corporativo) antes de que cualquier bean la necesite.

**107. 🟡 ¿Hay que registrar un shutdown hook a mano?**
No: `SpringApplication` registra uno que cierra el contexto ante `SIGTERM`, y por eso los `@PreDestroy` se ejecutan. Se puede desactivar con `setRegisterShutdownHook(false)`, algo que solo tiene sentido si controlas el cierre tú. Lo que sí hay que configurar aparte es `server.shutdown=graceful` con su `spring.lifecycle.timeout-per-shutdown-phase`, porque cerrar el contexto no es lo mismo que drenar las peticiones en vuelo.

**108. 🟠 ¿Cómo afecta el cierre del contexto en las pruebas y qué es `@DirtiesContext`?**
El framework de pruebas **cachea** los contextos por su configuración y los reutiliza entre clases, lo que es la razón principal de que una suite con `@SpringBootTest` sea soportable. `@DirtiesContext` marca el contexto como inservible y fuerza su recreación, algo legítimo cuando la prueba altera estado global e inevitablemente lento. Antes de ponerlo, la pregunta es por qué la prueba deja el contexto sucio; normalmente es un bean con estado, y eso es un hallazgo más interesante que la anotación.

**109. 🟠 ¿Tiene sentido precalentar conexiones y cachés en el arranque?**
Sí en servicios sensibles a la latencia del primer impacto: abrir el mínimo del pool, compilar las consultas críticas, calentar el JIT en los caminos calientes, resolver DNS. Los costes: el arranque se alarga —y con él el tiempo de un rolling update o de un escalado ante un pico—, y el precalentamiento puede fallar y complicar el diagnóstico. La forma correcta es hacerlo antes de declarar `readiness`, con timeout y sin tumbar la aplicación si falla.

**110. 🔴 Una aplicación tarda 90 segundos en arrancar. ¿Cómo lo diagnosticas?**
Por fases, con datos y no por intuición. Primero `/actuator/startup` (`ApplicationStartup` con `BufferingApplicationStartup`) para tener el tiempo de cada paso de instanciación, que suele señalar directamente al culpable. Luego separo los grandes sospechosos: escaneo de classpath (tamaño y número de paquetes), conexiones y validaciones remotas en el arranque —un `DataSource` que valida contra una base lenta, un cliente de secretos, un discovery con timeout largo—, migraciones de Flyway, e inicializaciones en `@PostConstruct` que hacen E/S. Comparo un arranque con `--debug` para ver autoconfiguraciones activas y descartar las inútiles. Después optimizo por impacto: quitar lo innecesario, mover trabajo a después de readiness, y solo entonces considerar lazy init, AppCDS o AOT. Y dejo una métrica de tiempo de arranque para que la regresión se detecte sola la próxima vez.

---

## 🧰 Parte 6 — Definición de beans: `@Configuration`, `@Bean`, `@Import` (111–135)

**111. 🟢 `@Bean` o `@Component`: ¿cuándo cada uno?**
`@Component` (con sus estereotipos) para clases **propias** que quieres que el escaneo descubra: servicios, repositorios, controladores. `@Bean` en una clase de configuración para todo lo demás: objetos de librerías de terceros que no puedes anotar, instancias que requieren lógica de construcción, y varias instancias del mismo tipo con configuraciones distintas. La regla práctica: si el objeto es tuyo y su construcción es trivial, estereotipo; si hay decisiones en la construcción, `@Bean`.

**112. 🟡 ¿Qué diferencia hay entre el modo `full` y el modo `lite` de las clases de configuración?**
Una clase `@Configuration` se procesa en modo `full`: se le aplica un proxy CGLIB para que las llamadas entre sus métodos `@Bean` devuelvan el singleton del contenedor. Los métodos `@Bean` declarados en una clase `@Component`, o con `proxyBeanMethods = false`, están en modo `lite`: esas llamadas son llamadas Java normales y **crean objetos nuevos**. Es una fuente clásica de bugs sutiles: dos `DataSource`, dos executors, dos cachés, y nadie entiende por qué la configuración no se aplica.

**113. 🟠 ¿Qué consecuencias tiene el proxy CGLIB de `@Configuration`?**
La clase no puede ser `final` ni tener solo constructores privados, los métodos `@Bean` no pueden ser `final` ni `private`, y se paga una subclase por clase de configuración. Además, para la inyección de dependencias de la propia clase de configuración conviene usar el constructor, y no cualquier truco que dependa de la identidad de la instancia. En native image, estos proxies son parte de lo que la fase AOT resuelve por adelantado.

**114. 🟠 ¿Cuándo pondrías `proxyBeanMethods = false`?**
Cuando los métodos `@Bean` de la clase no se llaman entre sí, es decir, cuando cada uno declara sus dependencias como parámetros. Ganas un arranque algo más rápido y una clase sin proxy, y es la práctica recomendada dentro de las autoconfiguraciones, donde Boot lo usa sistemáticamente. Lo que pierdes es la red de seguridad: si alguien añade después una llamada entre métodos, obtendrá una instancia duplicada sin ningún aviso.

**115. 🟡 ¿Cómo se inyectan dependencias en un método `@Bean`?**
Declarándolas como parámetros del método: el contenedor las resuelve como en cualquier punto de inyección, con `@Qualifier` si hay ambigüedad. Es la forma preferible frente a llamar a otro método `@Bean` o a inyectar campos en la clase de configuración, porque hace la dependencia explícita y funciona igual en modo `lite`. Para valores de configuración, `@Value` en el parámetro o, mejor, un `@ConfigurationProperties` inyectado.

**116. 🟠 ¿Por qué algunos métodos `@Bean` deben ser `static`?**
Porque los beans que participan en el procesamiento de definiciones —`BeanFactoryPostProcessor` y sus derivados, como `PropertySourcesPlaceholderConfigurer`— se necesitan antes de que la clase de configuración esté completamente inicializada. Declararlos `static` evita instanciar la configuración de forma temprana y así evita que sus `@Value` queden sin resolver y que se emitan avisos de "no eligible for getting processed by all BeanPostProcessors". Es un detalle que solo aparece cuando escribes infraestructura, y por eso distingue a quien la ha escrito.

**117. 🟡 ¿Qué hace `@Import`?**
Registra otras clases de configuración, componentes o registradores en el contexto sin depender del escaneo. Es la forma limpia de que un módulo exponga su configuración: el consumidor importa explícitamente lo que quiere, y el alcance queda declarado en el código. En pruebas es también la forma de componer solo las piezas necesarias.

**118. 🟠 `ImportSelector` vs `DeferredImportSelector`.**
Un `ImportSelector` decide **en tiempo de procesamiento** qué clases de configuración registrar, devolviendo sus nombres a partir de los metadatos de la anotación: es el mecanismo detrás de muchas `@EnableXxx`. El `DeferredImportSelector` se ejecuta al final, cuando ya se han procesado todas las configuraciones del usuario, y es exactamente el que usa `@EnableAutoConfiguration` para que las autoconfiguraciones se evalúen después —y por eso `@ConditionalOnMissingBean` puede ver tus beans. Entender esta pareja es entender por qué la autoconfiguración cede siempre ante el usuario.

**119. 🟠 ¿Qué es un `ImportBeanDefinitionRegistrar`?**
Un gancho que registra definiciones de beans **programáticamente** durante el procesamiento de configuración, con acceso a los metadatos de la anotación que lo activó y al registro. Es el mecanismo con el que Spring Data crea un bean por cada interfaz de repositorio y con el que Feign o las HTTP Interfaces generan clientes a partir de interfaces anotadas. Si algún día necesitas "un bean por cada interfaz que cumpla X", esta es la herramienta, y conviene saber que existe antes de inventar algo peor.

**120. 🟡 ¿Cómo está hecha por dentro una anotación `@EnableXxx`?**
Es una anotación que lleva un `@Import` de una clase de configuración, de un `ImportSelector` o de un `ImportBeanDefinitionRegistrar`, más los atributos que ese importado lee de los metadatos (`@EnableCaching(mode = ...)`, `@EnableAsync(proxyTargetClass = ...)`). Saberlo desmitifica el patrón: no hay nada especial, es composición de anotaciones. Y explica por qué en Spring Boot casi no usas `@EnableXxx`: la autoconfiguración ya las activa según el classpath.

**121. 🟠 ¿Qué es `@ImportResource` y cuándo lo has usado?**
Importa definiciones desde XML, que sigue existiendo en integraciones legadas: configuraciones de Spring Integration antiguas, clientes SOAP generados, o módulos corporativos que nadie ha migrado. Es una vía de convivencia perfectamente válida durante una modernización, y es mejor importar el XML tal cual que reescribirlo a medias con prisa. Lo que sí conviene es acotarlo, envolverlo en una `@Configuration` propia y ponerle un plan de retirada.

**122. 🟡 ¿Por qué `basePackageClasses` en vez de cadenas de paquete?**
Porque una cadena no la refactoriza el IDE ni la verifica el compilador: si alguien renombra el paquete, el escaneo deja de encontrar nada y el fallo aparece lejos de la causa. `basePackageClasses` apunta a una clase marcadora (a menudo una interfaz vacía por módulo) y sobrevive a los renombrados. Es un detalle menor con un retorno alto en bases de código que se reorganizan.

**123. 🟠 Con varias clases `@Configuration`, ¿importa el orden?**
Para el registro de definiciones, importa cuando dos declaran un bean con el mismo nombre —lo que con la sobrescritura desactivada es directamente un fallo de arranque— y cuando se usan condiciones que miran el registro. El orden de escaneo no está garantizado de forma estable, así que cualquier diseño que dependa de él es frágil. Si necesitas orden determinista, usa `@Import` explícito o una autoconfiguración con `@AutoConfigureBefore`/`@AutoConfigureAfter`.

**124. 🟠 ¿Qué hace una clase `@Configuration` estática anidada dentro de un test?**
Se detecta automáticamente como configuración de ese test y **reemplaza** la detección normal de configuración, lo que puede sorprender: si querías añadir un bean al contexto de `@SpringBootTest`, la anidada puede dejar fuera la clase principal. Para añadir sin reemplazar, la forma correcta es `@TestConfiguration` o `@Import`. También afecta a la clave de caché del contexto, así que cada configuración anidada distinta es un contexto más que se levanta.

**125. 🟡 `@TestConfiguration` vs `@Configuration` en pruebas.**
`@TestConfiguration` es `@Configuration` con dos diferencias importantes: no la recoge el escaneo de componentes de la aplicación —así que no se filtra a producción— y, como clase anidada en un test, **complementa** la configuración detectada en lugar de sustituirla. Para añadir un bean falso, un `Clock` fijo o un cliente apuntando a WireMock, es siempre la opción correcta.

**126. 🟠 Tienes una librería compartida con beans. ¿Escaneo o autoconfiguración?**
Autoconfiguración, sin dudarlo, si la van a consumir varios equipos: el consumidor añade la dependencia y funciona, las condiciones respetan sus beans, y la librería puede evolucionar sin exigir cambios de cableado. El escaneo obligaría a cada aplicación a declarar paquetes ajenos, lo que acopla al consumidor a la estructura interna de la librería. Si es una librería de un solo consumidor, exponer una `@Configuration` importable es suficiente y más simple.

**127. 🟠 ¿Por qué una librería no debe declarar `@ComponentScan`?**
Porque el escaneo se activaría desde la librería sobre paquetes que ella decide, pudiendo registrar más de lo previsto, provocar colisiones de nombres con la aplicación y arrastrar beans en contextos donde no tienen sentido (una prueba de slice, por ejemplo). Es un efecto secundario invisible para quien solo añadió una dependencia. La librería debe ofrecer beans explícitos y condicionados, y dejar el control del alcance a la aplicación.

**128. 🟡 ¿Qué hace `@ConfigurationPropertiesScan`?**
Descubre las clases anotadas con `@ConfigurationProperties` en los paquetes indicados y las registra como beans, sin necesidad de `@EnableConfigurationProperties` ni de un estereotipo. Permite que las clases de configuración tipada sean POJO o `record` limpios, sin anotaciones de Spring más allá del binding. Es la forma que usaría hoy en una aplicación propia; en una librería, `@EnableConfigurationProperties` explícito, por lo mismo del punto anterior.

**129. 🟠 ¿Importa si un método `@Bean` declara como retorno la interfaz o la clase concreta?**
Sí, y es una trampa real: el tipo declarado es lo que el contenedor conoce de forma temprana para la resolución y para las condiciones. Si devuelves la interfaz, otros beans no podrán inyectar la clase concreta ni un `@ConditionalOnMissingBean(ClaseConcreta.class)` la verá; si devuelves la concreta, expones detalles y complicas su sustitución. La práctica sensata es devolver el tipo más específico que los consumidores legítimamente necesiten, que en infraestructura suele ser la clase concreta y en puertos de dominio la interfaz.

**130. 🟠 ¿Qué es un `FactoryBean`?**
Un bean cuya función es **producir** otro: el contenedor, al resolver el tipo, entrega lo que devuelve `getObject()`, no el `FactoryBean` en sí. Para obtener la factoría hay que pedirla con el prefijo `&`. Aparece mucho en integraciones antiguas y en librerías que construyen proxies (`MapperFactoryBean`, `LocalContainerEntityManagerFactoryBean`).

**131. 🟠 ¿Sigue teniendo sentido `FactoryBean` frente a un método `@Bean`?**
En código nuevo, casi nunca: un método `@Bean` hace lo mismo con código normal, depurable y sin el mecanismo del prefijo `&`. `FactoryBean` conserva ventaja en dos casos: cuando necesitas exponer el tipo del producto de forma dinámica (`getObjectType()`) para que la resolución por tipo funcione antes de crear nada, y cuando escribes una librería que genera beans a partir de metadatos. Saber leerlo importa porque el stack trace de un fallo de arranque en persistencia está lleno de ellos.

**132. 🟡 ¿Para qué `@Bean(initMethod = ..., destroyMethod = ...)`?**
Para gestionar el ciclo de vida de objetos de terceros que no puedes anotar: arrancar un cliente, cerrar un pool, liberar un canal. Es la alternativa limpia a envolver la clase ajena solo para poder poner `@PostConstruct`. Recuerda que `destroyMethod` se infiere (`close`/`shutdown`) y que se desactiva con la cadena vacía.

**133. 🟠 ¿Cómo separas configuración de infraestructura y de negocio?**
Por paquetes y por responsabilidad: las clases `@Configuration` que construyen `DataSource`, clientes HTTP, executors, seguridad o mensajería viven en el paquete de infraestructura y son las únicas que conocen tipos del framework; el dominio no tiene ninguna anotación de Spring y sus servicios se declaran como beans desde una configuración de la capa de aplicación, o con estereotipos si el equipo acepta esa concesión. La ventaja concreta es que el dominio se prueba sin contenedor y que las decisiones de infraestructura están en un puñado de ficheros localizables, en lugar de repartidas en anotaciones por toda la base de código.

**134. 🟠 ¿Cuándo definirías beans programáticamente?**
Cuando el conjunto de beans depende de datos que solo se conocen al arrancar: un cliente por cada destino declarado en configuración, un consumidor por cada cola de una lista. Se hace con `BeanDefinitionRegistry` desde un `ImportBeanDefinitionRegistrar` o un `BeanFactoryPostProcessor`, o con el registro funcional (`GenericApplicationContext.registerBean`) que además es AOT-friendly. Antes de llegar ahí, comprueba que la alternativa no sea más simple: un único bean con un mapa de configuración dentro suele bastar y es mucho más fácil de razonar.

**135. 🔴 ¿Qué reglas impondrías en un equipo de 15 personas sobre dónde y cómo se declaran los beans?**
Cinco, verificables: el dominio sin anotaciones de Spring; la infraestructura declarada en clases `@Configuration` de un paquete conocido y no por estereotipos dispersos; inyección por constructor obligatoria, sin `@Autowired` redundante; `@ConfigurationProperties` inmutable para todo grupo de propiedades, con `@Value` reservado a valores sueltos; y prohibido inyectar el `ApplicationContext` en código de negocio. Lo importante no es la lista, es que se comprueben con ArchUnit en el build y que estén justificadas por escrito con el problema que previenen —una regla sin motivo documentado se salta en el primer sprint con prisa—. Y dejaría una vía de excepción explícita: una anotación `@ExcepcionArquitectura` con motivo obligatorio, revisada trimestralmente, porque las reglas sin escape se acaban desactivando enteras.

---

## 🔌 Parte 7 — Extensión del contenedor y AOT (136–150)

**136. 🟡 ¿Qué es un `BeanPostProcessor`?**
Un gancho que se invoca para **cada instancia** de bean, antes y después de su inicialización, y que puede devolver el mismo objeto, uno modificado o un envoltorio. Es el mecanismo con el que Spring aplica proxies de AOP, resuelve `@Autowired` y procesa `@PostConstruct`. Escribir uno propio es raro en código de negocio y habitual en infraestructura.

**137. 🟡 ¿Y un `BeanFactoryPostProcessor`?**
Un gancho que actúa sobre las **definiciones** de beans, después de cargarlas y antes de instanciar nada: puede cambiar scopes, añadir propiedades, registrar o eliminar definiciones. El ejemplo canónico es `PropertySourcesPlaceholderConfigurer`, que resuelve los `${...}` de las definiciones. Como no hay instancias todavía, aquí no se puede envolver nada en un proxy.

**138. 🟠 ¿En qué orden se aplican y por qué importa?**
Primero todos los `BeanFactoryPostProcessor` (con los `BeanDefinitionRegistryPostProcessor` antes que el resto, y los `PriorityOrdered` antes de los `Ordered`), y después, durante la creación de cada bean, los `BeanPostProcessor`. Importa porque explica por qué puedes modificar definiciones pero no interceptar métodos en la primera fase, y por qué los proxies solo existen a partir de la segunda. La mayoría de los "¿por qué esto es null aquí?" del arranque se responden ubicando el código en una de las dos fases.

**139. 🟠 ¿Qué beans no pueden ser post-procesados?**
Los propios `BeanPostProcessor` y, en general, los beans que el contenedor necesita crear antes de registrar todos los post-procesadores. Cuando eso ocurre, Boot lo avisa en el log con un mensaje de tipo "is not eligible for getting processed by all BeanPostProcessors". La consecuencia práctica: ese bean puede quedarse sin proxy, así que sus `@Transactional` o `@Cacheable` no actúan. La causa habitual es una dependencia declarada desde un post-procesador hacia un bean de negocio, y la solución es cortarla con `ObjectProvider` o con `@Lazy`.

**140. 🟠 ¿Qué añade `InstantiationAwareBeanPostProcessor`?**
Ganchos **antes** de la instanciación (pudiendo sustituir la creación del objeto por completo) y durante la población de propiedades. Es lo que permite, por ejemplo, devolver un proxy en lugar de instanciar la clase real. Es una interfaz de infraestructura pura: úsala si estás construyendo un framework, no una aplicación.

**141. 🟠 ¿Para qué sirve `SmartInstantiationAwareBeanPostProcessor`?**
Añade la capacidad de **predecir el tipo** de un bean y de determinar el constructor candidato antes de crearlo. La predicción de tipo es clave para que la resolución por tipo funcione con beans que acabarán siendo proxies o que provienen de factorías. Si alguna vez has visto que una inyección por tipo no encuentra un bean que sí existe, la explicación suele estar en este nivel.

**142. 🟠 ¿Qué hace exactamente `PropertySourcesPlaceholderConfigurer`?**
Recorre las definiciones de beans y sustituye los `${...}` por valores resueltos contra el `Environment`, con soporte de valores por defecto y de anidamiento. Es un `BeanFactoryPostProcessor`, y por eso los métodos `@Bean` que lo declaran deben ser `static`. En Spring Boot ya está configurado; declararlo a mano solo hace falta en configuraciones heredadas o cuando quieres cambiar el comportamiento ante placeholders no resolubles.

**143. 🟠 Da un caso real en que escribirías un `BeanPostProcessor` propio.**
Uno que he visto justificado: validar convenciones corporativas al arrancar —que todo bean que implemente un puerto externo tenga timeouts configurados, o que ningún `@Service` tenga campos mutables— y fallar el arranque con un mensaje claro, que es infinitamente mejor que descubrirlo en producción. Otro: envolver automáticamente los clientes de terceros con instrumentación de métricas sin tocar cada declaración. En los dos casos, el criterio es que sea transversal, mecánico y verificable; si hay que decidir caso por caso, no es un post-procesador, es diseño.

**144. 🟠 ¿Qué riesgos tiene escribir un `BeanPostProcessor`?**
Tres serios: forzar la instanciación temprana de beans al pedir dependencias, con lo que otros post-procesadores dejan de aplicarse; devolver un objeto que rompe la resolución por tipo o que impide que se aplique el proxy de AOP; y ralentizar el arranque, porque se ejecuta para **todos** los beans. Añade que los errores ocurren en el arranque, con stack traces del interior del contenedor y muy poco contexto. Es potente y hay que usarlo con moderación y con pruebas de contexto.

**145. 🟠 ¿Qué cambia el procesamiento AOT de Spring Boot 3 en el contenedor?**
En build time se genera código que registra las definiciones de beans, con las condiciones **ya evaluadas** y la reflexión sustituida por invocaciones directas, más los metadatos de hints necesarios. En ejecución el contexto no escanea ni evalúa condiciones: se limita a aplicar lo generado. El efecto es un arranque mucho más rápido, y la contrapartida es rigidez: lo que se decidió al compilar no puede depender del entorno de ejecución.

**146. 🟠 ¿Qué patrones del contenedor rompen en native image?**
Todo lo que se resuelve en tiempo de ejecución: reflexión sobre clases no registradas, proxies dinámicos no declarados, carga de clases por nombre, recursos leídos del classpath sin hint, y perfiles o condiciones que pretendan decidirse en el arranque. También los `BeanFactoryPostProcessor` que registran definiciones dinámicamente, porque su efecto debe poder calcularse en build time. La consecuencia arquitectónica es concreta: si quieres native, la configuración decide **qué valores**, no **qué beans existen**.

**147. 🟡 ¿Qué son los `RuntimeHints` y `@RegisterReflectionForBinding`?**
El mecanismo para declarar al compilador nativo lo que hará falta en ejecución: clases accesibles por reflexión, proxies, recursos, serialización. `@RegisterReflectionForBinding` es el atajo para el caso más común, los DTO que Jackson serializa y deserializa, y evita el clásico fallo de un binario nativo que responde con un JSON vacío. Para casos más amplios se implementa un `RuntimeHintsRegistrar` y se declara en `spring/aot.factories`.

**148. 🟠 Si las condiciones se evalúan en build time, ¿qué implicaciones tiene?**
Que los perfiles y propiedades que gobiernan la **existencia** de beans quedan fijados en la imagen: un binario compilado con el perfil `prod` no puede ejecutarse como `dev` si eso cambia qué beans hay. Implicación de despliegue: el artefacto deja de ser único por entorno, lo que multiplica los builds y obliga a que la promoción entre entornos no cambie el cableado. Se mitiga diseñando para que la variación entre entornos sea siempre de valores —URLs, credenciales, timeouts— y no de topología de beans.

**149. 🟠 ¿Cómo listas todos los beans de un contexto y de dónde salió cada uno?**
En ejecución, el endpoint `/actuator/beans` da nombre, tipo, scope, dependencias y el recurso que lo declaró, que es justo lo que necesitas cuando aparece un bean inesperado. Programáticamente, `getBeanDefinitionNames()` y `getBeanDefinition(nombre)` para ver la clase de origen. Y para entender por qué **no** está un bean, la herramienta es `/actuator/conditions` o el arranque con `--debug`, que muestra el informe de evaluación de condiciones.

**150. 🔴 El contexto arranca en local y falla en el pipeline. Enumera las causas por probabilidad.**
Empezaría por las que dependen del entorno: una propiedad o variable presente en tu máquina y ausente en CI (y el fallo aparece al resolver un `@Value`), un perfil distinto activado, un fichero de configuración local no versionado. Después el classpath: una dependencia resuelta desde el caché local, una versión distinta por un rango o por un repositorio interno, o un conflicto que cambia qué autoconfiguración se activa. Luego la infraestructura: un contenedor de Testcontainers que no arranca, DNS o red restringida, un almacén de secretos inaccesible, límites de memoria que cambian el comportamiento de un pool. Y por último los no deterministas: orden de escaneo distinto en otro sistema de ficheros, dependencia entre pruebas que en local se ejecutan en otro orden, zona horaria o locale del agente. Para diagnosticarlo, no adivino: ejecuto en CI con `--debug` y comparo el informe de condiciones y `/actuator/env` contra el local, que es la diferencia que buscamos escrita literalmente.

---

## 📡 Parte 8 — Eventos de aplicación (151–162)

**151. 🟢 ¿Cómo publicas y consumes un evento de aplicación?**
Inyectas `ApplicationEventPublisher` y llamas a `publishEvent` con cualquier objeto —desde Spring 4.2 no hace falta extender `ApplicationEvent`—, y consumes con un método anotado `@EventListener` cuyo parámetro sea el tipo del evento. El contenedor resuelve los listeners por tipo, incluyendo jerarquías y genéricos. Es mensajería **dentro del proceso**, sin broker y sin garantía de entrega más allá de la llamada.

**152. 🟡 Los listeners son síncronos por defecto: ¿qué implica?**
Que `publishEvent` no retorna hasta que todos los listeners han terminado, en el mismo hilo y dentro de la misma transacción si la había. Implica dos cosas incómodas: la latencia del publicador es la suma de la de sus listeners, y un listener lento o que hace E/S penaliza el flujo principal sin que se vea en el código. La ventaja de ese mismo comportamiento es que el efecto participa de la transacción y se revierte con ella.

**153. 🟠 ¿Qué pasa si un listener lanza una excepción?**
Se propaga al publicador, así que puede tumbar la operación principal y, si hay transacción, provocar su rollback. Los listeners registrados después del que falló no se ejecutan. Es un acoplamiento que rara vez es el deseado: si el efecto es secundario —enviar una notificación—, el listener debe capturar, registrar y emitir una métrica; si de verdad debe abortar la operación, entonces no era un efecto secundario y quizá no debía ser un evento.

**154. 🟠 ¿Qué se pierde al poner `@Async` en un listener?**
La transacción (el hilo nuevo no la hereda, así que una entidad lazy explotará y no habrá rollback conjunto), el contexto de seguridad y el MDC si no los propagas con un `TaskDecorator` o con `DelegatingSecurityContextAsyncTaskExecutor`, y el manejo de errores, que pasa a depender de un `AsyncUncaughtExceptionHandler`. También pierdes el orden. Además ganas un riesgo nuevo: si el evento lleva una entidad gestionada, el listener asíncrono la lee fuera de su contexto de persistencia.

**155. 🟠 ¿Qué es `@TransactionalEventListener` y qué fases tiene?**
Un listener que se ejecuta ligado al ciclo de la transacción del publicador: `AFTER_COMMIT` (por defecto), `AFTER_ROLLBACK`, `AFTER_COMPLETION` y `BEFORE_COMMIT`. Resuelve el problema clásico de reaccionar a algo que luego se revierte: enviar un correo, publicar en Kafka o invalidar un caché por un pago que al final no se registró. Detalle a conocer: si no hay transacción activa, el listener **no** se ejecuta salvo que pongas `fallbackExecution = true`, lo que en pruebas produce silencios desconcertantes.

**156. 🟠 En un listener `AFTER_COMMIT`, ¿puedes escribir en base de datos?**
Puedes, pero no dentro de la transacción original, que ya se confirmó: necesitas una nueva, y con `@Transactional(REQUIRES_NEW)` funciona. El problema es de semántica, no de mecánica: esa escritura ya no es atómica con la primera, así que un fallo deja el sistema en un estado parcial sin que nadie lo revierta. Para efectos que deben ser atómicos con la operación, el patrón correcto es el outbox: escribir el mensaje en la misma transacción y publicarlo después desde un proceso que reintenta.

**157. 🟡 ¿Cómo controlas el orden entre varios listeners del mismo evento?**
Con `@Order` en los métodos listener; sin él, el orden es indefinido. Y la observación más útil: si el orden importa, probablemente no querías eventos. Los eventos sirven para desacoplar efectos independientes; una secuencia con dependencias entre pasos es un flujo, y un flujo se escribe explícitamente en un servicio donde se pueda leer de arriba abajo.

**158. 🟡 ¿Funcionan los eventos genéricos?**
Sí: un listener de `EntidadCreada<Cuenta>` solo recibe los eventos de ese parámetro de tipo, porque Spring resuelve los genéricos con `ResolvableType`. Si el evento se publica desde un contexto donde el tipo se ha borrado, hay que implementar `ResolvableTypeProvider` en la clase del evento para que la resolución funcione. Es una capacidad elegante y a la vez un sitio donde la magia falla sin decir por qué.

**159. 🟠 ¿Para qué sirve el atributo `condition` de `@EventListener`?**
Filtra con SpEL sobre el evento antes de invocar el listener: `@EventListener(condition = "#evento.importe > 10000")`. Es cómodo para no ejecutar lógica que no aplica, y a la vez discutible, porque mete una regla de negocio en una cadena de texto dentro de una anotación, sin compilación ni pruebas directas. Mi criterio: condiciones triviales y técnicas, sí; reglas de negocio, dentro del método.

**160. 🟠 Eventos en memoria vs eventos en un broker: ¿cómo decides?**
En memoria si el efecto pertenece al mismo servicio y la misma unidad de trabajo, y si perderlo ante una caída del proceso es aceptable o recuperable. Al broker si el consumidor es otro servicio, si el efecto debe sobrevivir a un reinicio, o si necesitas reintentos, orden y observabilidad de la entrega. La confusión peligrosa es usar eventos en memoria como si fueran fiables: si el proceso muere entre el commit y el listener, el efecto se pierde en silencio y nadie se enteró.

**161. 🟠 ¿Cuándo el desacoplamiento por eventos se vuelve inmanejable?**
Cuando para entender qué ocurre al crear una cuenta hay que buscar por todo el código quién escucha ese evento, y esa lista cambia entre versiones. Los síntomas: efectos que dependen del orden, listeners que publican eventos que disparan otros listeners, y depuración imposible porque el stack trace no cuenta la historia. El límite práctico es la capacidad del equipo de dibujar el flujo; cuando ya no puede, hay que volver a llamadas explícitas en un orquestador y dejar los eventos para lo verdaderamente independiente.

**162. 🔴 ¿Reemplazarías llamadas directas por eventos en el core de un sistema bancario?**
En el flujo transaccional principal, no: un asiento contable, la validación de saldo y el registro de la operación tienen que ser un flujo explícito, ordenado, atómico y legible, porque es lo que se audita y lo que se explica a un regulador. Los eventos sí valen para los efectos periféricos y no bloqueantes —notificaciones, proyecciones de consulta, analítica, alimentación de antifraude—, y para los límites entre servicios, donde ya hay una frontera. Pondría dos condiciones si se adoptan: que el efecto crítico pase por outbox y no por listener en memoria, y que exista trazabilidad extremo a extremo con un identificador de correlación, porque un flujo por eventos sin trazas no se puede auditar. Y dejaría dicho lo que nadie quiere oír: el desacoplamiento no es gratis, se paga en dificultad de razonamiento, y en un core se paga cara.

---

## 🪞 Parte 9 — Proxies y AOP (163–180)

**163. 🟢 ¿Qué es AOP en Spring y qué problema resuelve?**
Programación orientada a aspectos implementada por proxy: se intercepta la llamada a un bean para aplicar comportamiento transversal sin escribirlo en cada método. Es lo que hace posible `@Transactional`, `@Cacheable`, `@PreAuthorize`, `@Async`, `@Retryable` y la instrumentación de métricas. El problema que resuelve es real: sin él, cada método de servicio empezaría con veinte líneas idénticas de transacción, permisos y logging.

**164. 🟡 Define aspecto, punto de corte, punto de unión, advice y weaving.**
El **aspecto** es el módulo que agrupa el comportamiento transversal; el **punto de unión** (joinpoint) es el punto del programa donde puede aplicarse —en Spring, siempre una invocación de método—; el **punto de corte** (pointcut) es la expresión que selecciona esos puntos; el **advice** es el código que se ejecuta; y el **weaving** es el proceso de entrelazarlos, que en Spring ocurre en ejecución al crear los proxies y en AspectJ puede ocurrir en compilación o al cargar clases.

**165. 🟡 ¿Qué tipos de advice existen?**
`@Before`, `@After` (siempre), `@AfterReturning`, `@AfterThrowing` y `@Around`. `@Around` es el más potente porque recibe el `ProceedingJoinPoint` y decide si invocar el método, con qué argumentos y qué devolver —es el que usan transacciones y reintentos—, y por eso mismo el más fácil de usar mal: un `@Around` que olvida `proceed()` hace desaparecer la llamada sin ningún error.

**166. 🟠 Proxy dinámico de JDK vs CGLIB: ¿cuándo usa Spring cada uno?**
Si el bean implementa al menos una interfaz, por defecto usa un proxy JDK sobre esas interfaces; si no, o si fuerzas `proxyTargetClass = true`, subclasea con CGLIB. Spring Boot pone `spring.aop.proxy-target-class=true` por defecto, así que en la práctica verás CGLIB casi siempre, lo que evita el error clásico de intentar inyectar la clase concreta y recibir un proxy que solo implementa la interfaz. El coste de CGLIB es la subclase: nada `final` y un constructor invocable.

**167. 🟠 ¿Por qué una llamada interna no pasa por el aspecto?**
Porque el proxy envuelve al objeto desde fuera: quien llama al proxy obtiene la intercepción, pero cuando un método del objeto llama a otro método del mismo objeto, `this` es la instancia real y el proxy no aparece en medio. Es la causa número uno de `@Transactional` que "no funciona", y también de `@Cacheable` y `@Async` ignorados. No es un bug, es una consecuencia inevitable del modelo de proxy.

**168. 🟠 ¿Cómo atraviesas el proxy cuando lo necesitas de verdad?**
Tres formas, por orden de preferencia: extraer el método a otro bean e inyectarlo, que además suele mejorar el diseño; auto-inyectarse con `@Lazy` y llamar a través de la referencia inyectada; o `AopContext.currentProxy()`, que exige `@EnableAspectJAutoProxy(exposeProxy = true)` y deja código atado a Spring en medio del negocio. La cuarta opción —AspectJ con weaving real— resuelve el problema de raíz pero cambia el build.

**169. 🟠 ¿Qué ocurre con métodos `final`, `private` o `static`?**
No se pueden interceptar: `final` no se puede sobrescribir en la subclase CGLIB, `private` no es visible, `static` no pertenece a la instancia proxiada. El resultado no es un error sino un silencio: la anotación se ignora. Con Kotlin el caso es especialmente traicionero porque las clases y los métodos son `final` por defecto, y hace falta `open` o el plugin `all-open` para que Spring pueda proxiar.

**170. 🟡 Entonces, ¿por qué exactamente falla `@Transactional` en un método `private`?**
Porque la anotación solo tiene efecto si la invocación atraviesa el proxy, y un método privado no es interceptable ni invocable desde fuera: siempre se llama internamente. Spring no avisa —aunque hay herramientas de análisis estático que sí—, así que el método se ejecuta sin transacción y los fallos no revierten. La regla operativa es simple: los métodos con anotaciones interceptadas son públicos y se invocan desde otro bean.

**171. 🟠 Si un método tiene `@Transactional`, `@Cacheable` y `@PreAuthorize`, ¿en qué orden se aplican?**
En el orden de prioridad de sus interceptores, configurable con `@Order` en los `@EnableXxx` correspondientes. Los valores por defecto colocan la seguridad y la caché por fuera y la transacción por dentro, que es lo que normalmente quieres: comprobar permisos antes de abrir una transacción, y servir desde caché sin tocar la base de datos. Cuando el orden se altera aparecen efectos indeseables concretos: una transacción abierta para una petición que iba a ser rechazada, o un valor cacheado que se guardó desde una transacción que luego revirtió.

**172. 🟠 ¿Qué expresiones de pointcut usas en la práctica?**
`execution(...)` para firmas de método, `within(...)` para acotar por paquete o clase, `@annotation(...)` para marcar con una anotación propia, `bean(...)` para nombres de bean, y `args(...)` para tipos de argumento. En una base de código real, la combinación sana es `within` para limitar el radio y `@annotation` para que el punto de aplicación sea explícito en el código afectado. Los pointcuts amplios basados solo en `execution` sobre un paquete entero envejecen mal: alguien añade una clase y hereda un comportamiento que nadie esperaba.

**173. 🟠 ¿Cómo implementarías auditoría transversal con una anotación propia?**
Una anotación `@Auditable` con los metadatos necesarios (tipo de operación, criticidad), un aspecto `@Around` que capture actor, operación, identificadores de negocio, resultado y duración, y que escriba en el mecanismo de auditoría —preferiblemente mediante outbox, no con una llamada remota en línea—. Lo importante está en los detalles: enmascarar datos sensibles, no registrar nunca argumentos completos sin filtrar, decidir explícitamente qué pasa si la auditoría falla (¿aborta la operación?), y garantizar que el registro no dependa de que el desarrollador se acuerde. Y un punto honesto: el aspecto no puede auditar lo que no pasa por él, así que necesita apoyo en el nivel de datos.

**174. 🟠 ¿Cuándo compensa AspectJ con weaving en compilación o en carga?**
Cuando de verdad necesitas interceptar lo que el proxy no alcanza: llamadas internas, métodos privados, constructores, acceso a campos, o clases que no son beans de Spring. Compensa en casos acotados y de mucho valor —instrumentación profunda, un requisito de auditoría muy amplio—, y cuesta complejidad de build, tiempos de compilación, un agente en el arranque si es load-time, y depuración más difícil porque el bytecode ya no corresponde al fuente. Mi umbral: si la alternativa es renunciar a un requisito regulatorio, se evalúa; si es por comodidad, no.

**175. 🟠 ¿Cuánto cuesta el proxy en rendimiento?**
La intercepción en sí es del orden de decenas a cientos de nanosegundos por llamada: irrelevante frente a cualquier E/S, y medible solo en bucles muy calientes o en métodos triviales llamados millones de veces. Lo que sí cuesta es lo que hace el advice: abrir una transacción son conexión y round-trips, y un `@Cacheable` contra Redis es una llamada de red. La conclusión es la habitual: no optimices el proxy, mira qué hace el interceptor.

**176. 🟠 ¿Cómo afecta AOP a la depuración y a los stack traces?**
Los stack traces se llenan de frames de proxies, interceptores y CGLIB, con lo que la línea que importa queda enterrada; los puntos de ruptura en el método real se alcanzan después de varias capas; y el tipo en tiempo de ejecución no es la clase que escribiste, lo que rompe cualquier `getClass()` ingenuo y confunde en el depurador. Se mitiga conociendo `AopUtils.getTargetClass()` y `AopProxyUtils`, y sobre todo teniendo pocos aspectos y bien delimitados. Es parte del precio de la magia y conviene declararlo cuando alguien propone un aspecto nuevo.

**177. 🟠 ¿Aspecto propio o `@Observed` de Micrometer para métricas?**
`@Observed` con Micrometer Observation, sin dudarlo, para el caso general: te da métricas y trazas coherentes, nombres y etiquetas convencionales, y lo mantiene otro. Un aspecto propio se justifica cuando necesitas etiquetas de negocio que Micrometer no puede conocer, y aun entonces lo razonable es usar la API de `Observation` desde dentro en lugar de reinventar la instrumentación. El error clásico del aspecto propio es la cardinalidad: alguien etiqueta con el identificador de cliente y la factura de métricas se multiplica.

**178. 🟠 ¿Qué no deberías hacer nunca con AOP?**
Lógica de negocio: reglas, validaciones de dominio, cálculos. Un aspecto que modifica argumentos o valores de retorno de negocio hace que el código que lees no sea el que se ejecuta, y eso es indefendible en un sistema auditado. Tampoco control de flujo que dependa de condiciones de negocio, ni comportamiento del que dependa la corrección del dominio, porque desaparece en cuanto el objeto se use fuera del contenedor. El criterio: si borrar el aspecto cambia el resultado funcional en lugar de solo la transversalidad, está mal ubicado.

**179. 🟠 ¿Qué pasa con AOP en native image?**
Los proxies dinámicos de JDK deben declararse como hints, y los proxies CGLIB generados en ejecución no existen: el procesamiento AOT de Spring genera por adelantado lo que puede y registra el resto. En la práctica, los aspectos de Spring (transacciones, caché, seguridad) funcionan porque el framework aporta sus hints; un aspecto propio con pointcuts dinámicos o con creación de proxies en ejecución es lo que rompe. Regla para código nativo: pointcuts estáticos y conocidos al compilar.

**180. 🔴 Regulación te obliga a registrar cada acceso a datos de cliente, sin excepciones. Diseña la solución y di qué firmarías.**
Empezaría por rechazar la solución que primero se propone siempre: un aspecto sobre la capa de servicio. Cubre lo que pasa por beans anotados y deja fuera las llamadas internas, los accesos por `JdbcTemplate` ad hoc, los jobs de batch, las consultas del equipo de soporte y cualquier ruta futura que nadie recuerde anotar; con un requisito que dice "sin excepciones", un mecanismo que depende de la disciplina del desarrollador no sirve. El diseño que defendería es en capas: interceptación en el punto más bajo y más difícil de esquivar —auditoría del propio motor de base de datos o un interceptor de Hibernate y de `JdbcTemplate`— como red de garantía; un aspecto sobre los casos de uso para aportar el **contexto de negocio** que la capa de datos no conoce (qué operación, qué actor, qué justificación); escritura por outbox en la misma transacción, para que no se pueda leer sin dejar rastro; y una regla de ArchUnit que impida acceder a los datos de cliente por fuera de los puntos instrumentados. Lo que firmaría: que todo acceso a través de los caminos instrumentados queda registrado, que los caminos no instrumentados fallan el build, y que existe una reconciliación periódica entre accesos del motor y registros de auditoría con alerta ante discrepancias. Lo que no firmaría: cobertura del 100% garantizada por un aspecto, ni que el registro sobreviva a un acceso directo a la base de datos con credenciales de administrador —eso es un control de accesos, no un problema de Spring—.

---

> 🧭 **Cierre:** todo lo difícil de este tópico se reduce a tres preguntas. ¿En qué **fase** del contenedor está ocurriendo esto —definición, instanciación, post-procesado o uso—? ¿Hay un **proxy** en medio y la llamada lo atraviesa? ¿Quién es **dueño** del estado y del ciclo de vida de este objeto? Quien responde esas tres sobre un caso concreto no necesita memorizar el resto; quien no, acumulará anotaciones sin entender por qué unas veces funcionan y otras no.
