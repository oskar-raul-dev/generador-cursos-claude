# 26 — Respuestas

> **Solucionario centralizado de todo el curso**: los capítulos [`01`](01-spring-boot-y-el-ecosistema.md)–`24`, las preguntas
> `P#` de la simulación `25`, y las preguntas rápidas de los labs `L00`–`L09` y de los
> apéndices `A01`–`A04`.
> **Vigencia:** 20 de septiembre de 2026 · Spring Boot 3.5.16.

**Salto rápido — capítulos:** [`01`](#capítulo-01--spring-boot-y-el-ecosistema) · [`02`](#capítulo-02--el-contenedor-ioc-definición-de-beans-y-ciclo-de-vida) · [`03`](#capítulo-03--inyección-de-dependencias-y-resolución-de-candidatos) · [`04`](#capítulo-04--scopes-de-bean) · [`05`](#capítulo-05--proxies-y-aop) · [`06`](#capítulo-06--arranque-de-spring-boot-y-autoconfiguración) · [`07`](#capítulo-07--configuración-externalizada) · [`08`](#capítulo-08--el-modelo-de-ejecución-web-servlet-hilos-y-contexto) · [`09`](#capítulo-09--rest-con-spring-mvc) · [`10`](#capítulo-10--diseño-de-api-validación-errores-e-hipermedia) · [`11`](#capítulo-11--webflux-y-reactor) · [`12`](#capítulo-12--reactivo-bloqueante-y-virtual-threads) · [`13`](#capítulo-13--clientes-http) · [`14`](#capítulo-14--tiempo-real-sse-y-websocket) · [`15`](#capítulo-15--datos-jdbc-jpa-mongo-y-redis) · [`16`](#capítulo-16--transacciones) · [`17`](#capítulo-17--caché) · [`18`](#capítulo-18--asincronía-scheduling-y-eventos) · [`19`](#capítulo-19--resiliencia) · [`20`](#capítulo-20--spring-security-el-mecanismo) · [`21`](#capítulo-21--identidad-federada-oauth2-oidc-y-jwt) · [`22`](#capítulo-22--spring-batch) · [`23`](#capítulo-23--actuator-y-observabilidad) · [`24`](#capítulo-24--testing)

**Simulación:** [`25`](#simulación-25--preguntas-p1p60) · **Labs:** [`L00`](#lab-l00--la-idea-del-laboratorio) · [`L01`](#lab-l01--esqueleto-cli-y-autoconfiguración) · [`L02`](#lab-l02--configuración-y-profiles) · [`L03`](#lab-l03--api-rest-filtros-y-errores) · [`L04`](#lab-l04--datos-y-transacciones) · [`L05`](#lab-l05--clientes-http-y-resiliencia) · [`L06`](#lab-l06--caché-y-asincronía) · [`L07`](#lab-l07--actuator-métricas-y-trazas) · [`L08`](#lab-l08--security-y-batch) · [`L09`](#lab-l09--empaquetado-imagen-y-limpieza-verificada) · **Apéndices:** [`A01`](#apéndice-a01--cli-y-tooling-de-supervivencia) · [`A02`](#apéndice-a02--catálogo-de-anotaciones) · [`A03`](#apéndice-a03--catálogo-de-errores-y-diagnóstico) · [`A04`](#apéndice-a04--migración-35--4x)

Aquí no hay preguntas nuevas, ni ejercicios, ni referencias propias. Solo respuestas, con
**el enunciado copiado literalmente** del documento original para que puedas localizar
cualquiera buscando el texto de la pregunta.

## Cómo está escrita cada respuesta

Tres capas, porque una entrevista tiene tres momentos distintos:

```text
⏱️ 30 segundos  → lo que dices primero, sin que te lo pidan
🗣️ 2 minutos    → lo que añades cuando dicen "cuéntame más"
🔬 El detalle   → para estudiar, no para decir en voz alta
```

Las preguntas de definición pura pueden quedarse en las dos primeras capas. Las de
decisión y diseño llevan siempre las tres.

## Cómo se usa

Contesta primero en voz alta, escribe tu versión, y **solo entonces** abre la entrada.
Una respuesta leída antes de intentarla no se recuerda cuando hace falta.

Las entradas se numeran igual que en el documento de origen: la pregunta 3 del capítulo
[`16`](16-transacciones.md) es la entrada **16 → 3**.

> **⚠️ Los ejercicios de los labs y apéndices no están aquí.** Se verifican con su línea
> `Objetivo:` y con la salida real del comando. Si un ejercicio necesitara una respuesta
> modelo, estaba mal planteado y era una pregunta.

---

## Capítulo 01 — Spring, Boot y el ecosistema

### 01 → 1

> ¿Qué problema concreto de J2EE resolvió Spring, y por qué el término POJO era una
> bandera y no un detalle?

**⏱️ 30 segundos.** Que un componente de negocio tuviera que heredar de las clases del
servidor para existir. Spring permitió que tu clase fuera una clase normal —un POJO— y
que un contenedor externo se encargara de construirla y de envolverla.

**🗣️ 2 minutos.** En J2EE, un EJB extendía clases del contenedor, implementaba sus
interfaces y se declaraba en descriptores XML. El precio eran tres cosas: no podías
probar la clase sin levantar el servidor de aplicaciones, no podías moverla a otro
servidor sin reescribirla, y el negocio quedaba enterrado bajo ceremonia. POJO era una
bandera porque nombraba exactamente la propiedad que se había perdido: que tu código no
dependa del framework que lo ejecuta. Hoy suena obvio porque Spring ganó.

**🔬 El detalle.** El corolario sigue siendo la mejor prueba de diseño: si no puedes
instanciar tu clase con `new` y pasarle mocks, algo del framework se te metió dentro.

---

### 01 → 2

> Nombra las cinco cosas que aporta Spring Boot y di cuál de ellas es responsable de que
> una aplicación arranque con `java -jar`.

**⏱️ 30 segundos.** Autoconfiguración, starters, gestión de versiones vía BOM, servidor
embebido y capacidades de producción (Actuator). El servidor embebido, junto con el jar
ejecutable, es lo que permite `java -jar`.

**🗣️ 2 minutos.** La autoconfiguración declara beans según el classpath y las
propiedades; los starters agrupan dependencias por intención; el BOM fija unas 250
librerías probadas juntas; el servidor embebido mete Tomcat dentro del artefacto; y
Actuator da health, métricas y diagnóstico sin escribir código. La combinación de
servidor embebido y empaquetado ejecutable es lo que hace viable un proceso por servicio,
y con ello todo el modelo de contenedores.

---

### 01 → 3

> ¿De qué proyecto es la anotación `@Transactional`: de Spring Framework o de Spring
> Boot? ¿Y `@ConditionalOnClass`?

**⏱️ 30 segundos.** `@Transactional` es de Spring Framework. `@ConditionalOnClass` es de
Spring Boot.

**🗣️ 2 minutos.** Es la línea divisoria del ecosistema: Boot no tiene ni una sola
anotación de negocio. `@Service`, `@Autowired`, `@GetMapping`, `@Transactional` y
`@Cacheable` son todas del Framework. Boot aporta las de arranque y configuración:
`@SpringBootApplication`, `@ConfigurationProperties` y la familia `@ConditionalOn*`. Si
le quitas Boot a tu aplicación sigues escribiendo Spring; lo que pierdes es el arranque,
no el modelo de programación.

**🔬 El detalle.** Ojo con el otro `@Transactional`, el de `jakarta.transaction`: existe,
compila, y tiene menos atributos. El import correcto es
`org.springframework.transaction.annotation.Transactional` (`16`).

---

### 01 → 4

> ¿Qué hay dentro del artefacto `spring-boot-starter-web`?

**⏱️ 30 segundos.** Ninguna clase: es un `pom` cuyo único contenido es una lista de
dependencias.

**🗣️ 2 minutos.** Declara `spring-boot-starter` (el núcleo, logging incluido),
`spring-boot-starter-json` (Jackson), `spring-boot-starter-tomcat` (el servidor) y
`spring-web` / `spring-webmvc`. Su valor no es el código, es la decisión: alguien ya
determinó qué necesitas para "web" y en qué versiones conviven. Por eso puedes cambiar de
servidor excluyendo la rama de Tomcat y añadiendo la de Jetty, sin tocar código.

**🔬 El detalle.** La convención de nombres distingue oficial de terceros: los de Spring
son `spring-boot-starter-*`; los de terceros van al revés, como
`resilience4j-spring-boot3` o `mybatis-spring-boot-starter`.

---

### 01 → 5

> ¿Por qué las dependencias de un `pom.xml` de Boot no llevan `<version>`, y qué tienes
> que hacer si tu empresa ya te impone un `<parent>` corporativo?

**⏱️ 30 segundos.** Porque las fija el BOM que hereda del `spring-boot-starter-parent`.
Si ya tienes un parent corporativo, importas el BOM con
`<scope>import</scope>` y `<type>pom</type>` dentro de tu `dependencyManagement`.

**🗣️ 2 minutos.** El BOM (`spring-boot-dependencies`) es una sección
`dependencyManagement` con la versión exacta de unas 250 librerías probadas contra esa
release. Omitir la versión es decir "la que el BOM haya validado". Como Maven no tiene
herencia múltiple, la vía para combinar el BOM con otro parent es importarlo: eso inserta
su `dependencyManagement` dentro del tuyo.

---

### 01 → 6

> ¿Qué diferencia práctica hay entre heredar de `spring-boot-starter-parent` e importar
> `spring-boot-dependencies` con `scope=import`?

**⏱️ 30 segundos.** El import trae solo las versiones. La herencia trae además la
configuración de plugins.

**🗣️ 2 minutos.** Heredando obtienes el `spring-boot-maven-plugin` ya configurado, el
compilador con el release de Java, el filtrado de recursos y los defaults de los plugins.
Importando el BOM te quedas solo con `dependencyManagement` y tienes que declarar esos
plugins a mano. Es la razón por la que un `pom.xml` corporativo es bastante más largo que
el de un tutorial — y también la razón por la que a veces `mvn package` no genera un jar
ejecutable: nadie declaró el plugin.

---

### 01 → 7

> Un jar ejecutable de Boot tiene en su `MANIFEST` una `Main-Class` que no es tu clase.
> ¿Cuál es, y por qué hace falta?

**⏱️ 30 segundos.** Es el `JarLauncher` de Boot. Hace falta porque un jar normal de Java
no puede cargar clases desde jars anidados, y las dependencias van dentro de
`BOOT-INF/lib/`.

**🗣️ 2 minutos.** El `JarLauncher` instala un classloader capaz de leer jars anidados y
después invoca tu clase, que está declarada aparte como `Start-Class`. Es lo que permite
`java -jar` sin classpath explícito y con un artefacto autocontenido. El objetivo
`repackage` del `spring-boot-maven-plugin` es el que convierte el jar normal de Maven en
este; el original se conserva como `.jar.original`.

**🔬 El detalle.** Ese modelo cuesta arranque: el launcher abre y lee los jars anidados.
Las respuestas son los layered jars —para que la imagen se reconstruya por capas— y la
compilación AOT/native (`L09`).

---

### 01 → 8

> ¿Quién decide la versión de Spring Framework que usa tu aplicación?

**⏱️ 30 segundos.** La versión de Spring Boot. Tú eliges Boot; el Framework viene con él.

**🗣️ 2 minutos.** Boot 3.5.16 arrastra Framework 6.2.19, exige Java 17–25 y fija las ~250
librerías del BOM. Forzar a mano una versión distinta del Framework —"porque tiene una
mejora que necesito"— es la manera más rápida de obtener un `NoSuchMethodError` en tiempo
de ejecución, que es el peor error posible porque compila sin quejarse.

---

### 01 → 9

> Te piden actualizar Jackson a un parche de seguridad antes de que Boot lo incorpore.
> ¿Cómo lo haces sin romper el resto del BOM, y qué riesgo asumes?

**⏱️ 30 segundos.** Sobreescribiendo la propiedad de versión que usa el BOM en tu
`<properties>`, no dependencia por dependencia. El riesgo es que esa combinación no está
probada por Boot.

**🗣️ 2 minutos.** El BOM declara las versiones a través de propiedades; redefinir
`<jackson-bom.version>` en tu POM mueve el grupo entero de artefactos de esa librería de
forma coherente. Si en cambio fijas la versión en una sola dependencia, acabas con
`jackson-databind` nuevo y `jackson-core` viejo, que es una fuente clásica de
`NoSuchMethodError`. El riesgo que asumes es real y se declara al equipo: has salido de
la matriz de compatibilidad que el BOM te garantizaba, y toca vigilar la suite de
integración.

---

### 01 → 10

> Aparece un `NoSuchMethodError` en el arranque después de tocar el `pom.xml`. ¿Cuál es
> el primer comando que corres y qué estás buscando en su salida?

**⏱️ 30 segundos.** `./mvnw dependency:tree`, para ver qué versión ganó de verdad.

**🗣️ 2 minutos.** Un `NoSuchMethodError` casi siempre significa que compilaste contra una
versión y en tiempo de ejecución hay otra. Maven resuelve los conflictos por **el camino
más corto a la raíz**, no por "la más nueva", así que una dependencia transitiva puede
estar imponiendo una versión vieja. `dependency:tree`, filtrado con
`-Dincludes=grupo:artefacto`, muestra el árbol resuelto y qué rama ganó.

**🔬 El detalle.** Si el conflicto es ajeno, la salida limpia es un `dependencyManagement`
que fije la versión, mejor que `<exclusions>` repartidas por el POM.

---

### 01 → 11

> ¿Qué significa que Spring Boot 3.5 esté fuera de soporte open source, y cómo
> contestarías en una entrevista a "¿en qué versión trabajan?"

**⏱️ 30 segundos.** Que desde el 30 de junio de 2026 no recibe parches gratuitos; los
recibe bajo soporte comercial, hasta 2032. En una entrevista se contesta con la versión,
su estado de soporte y qué bloquea la migración.

**🗣️ 2 minutos.** El calendario tiene dos relojes: el soporte OSS de una línea menor dura
alrededor de un año desde su GA, y después la línea pasa a soporte comercial. Decir "3.5"
y callarse suena desactualizado. Decir "3.5.16, fuera de soporte OSS desde junio, con
soporte comercial contratado, y la migración a 4 bloqueada por dos librerías internas"
suena a tech lead: demuestra que conoces tu ventana de riesgo y que tienes plan.

**🔬 El detalle.** La respuesta madura a "¿por qué no actualizan?" nunca es "no hemos
tenido tiempo": es el costo de recertificación frente al riesgo de CVEs sin parche, con
fecha comprometida.

---

### 01 → 12

> ¿Resilience4j y OpenFeign son proyectos de Spring? ¿Qué aporta Spring en cada caso?

**⏱️ 30 segundos.** Ninguno de los dos. Spring aporta la integración: el starter, las
anotaciones que se conectan a su AOP y la configuración por propiedades.

**🗣️ 2 minutos.** Resilience4j es un proyecto independiente que implementa circuit
breaker, retry, bulkhead y rate limiter; Spring —y Spring Boot— aportan el arranque y el
enganche con Actuator (`19`). OpenFeign es un proyecto de la CNCF; *Spring Cloud
OpenFeign* es el envoltorio de Spring sobre él, y hoy está en mantenimiento: su sucesor
natural dentro del ecosistema son las HTTP Interfaces ([`13`](13-clientes-http.md)). Atribuirle a Spring lo que
no es suyo importa porque su ciclo de vida y su soporte son ajenos al calendario de Boot.

---

## Capítulo 02 — El contenedor IoC: definición de beans y ciclo de vida

### 02 → 1

> Explica la diferencia entre una bean definition y una instancia, y nombra tres cosas
> que viven en la definición.

**⏱️ 30 segundos.** La definición es metadato —la receta—; la instancia es el objeto. En
la definición viven la clase, el scope, las dependencias, si es `@Primary`, si es lazy y
sus métodos de init y destroy.

**🗣️ 2 minutos.** Las definiciones se registran en el arranque —desde el component scan,
desde los métodos `@Bean` y desde las autoconfiguraciones— **antes de que exista ningún
objeto**. Cuántas instancias se crean con cada receta lo decide el scope ([`04`](04-scopes-de-bean.md)). Esta
distinción es la que hace que la configuración de Spring deje de ser magia: `@Profile` y
`@Conditional` deciden si la definición se registra, `@ConditionalOnMissingBean` mira si
ya hay otra, y `@Primary` marca una para desempatar. Todo es manipulación de definiciones.

---

### 02 → 2

> ¿En qué fase del arranque se crean los proxies, y qué implica eso para el código que
> escribes en `@PostConstruct`?

**⏱️ 30 segundos.** En la fase de `BeanPostProcessor`, después de construir e inyectar y
**antes** de `@PostConstruct`. Implica que dentro de `@PostConstruct` estás sobre el
objeto interno, no sobre el proxy.

**🗣️ 2 minutos.** El orden es: constructor → inyección de campos → `BeanPostProcessor`
(aquí nace el proxy) → `@PostConstruct` → contexto listo. Como `@PostConstruct` se ejecuta
sobre la instancia que el proxy envuelve, llamar desde ahí a un método `@Transactional`,
`@Cacheable` o `@Async` de la propia clase no dispara nada: es una self-invocation ([`05`](05-proxies-y-aop.md)).
No hay error, ni log, ni aviso.

**🔬 El detalle.** Las fases numeradas del capítulo lo fijan: 3 constructor, 4 inyección de
campos y setters, 5 *aware callbacks*, 6 `BeanPostProcessor` —donde nace el proxy—, 7
`@PostConstruct` → `InitializingBean.afterPropertiesSet()` → el `initMethod` de `@Bean`, y
9 `ApplicationReadyEvent`. Si necesitas trabajo transaccional al arrancar, el sitio es un
`ApplicationRunner` o un listener de `ApplicationReadyEvent`, porque ahí el bean que
recibes por inyección ya es el proxy.

---

### 02 → 3

> ¿Por qué un `@Value` sobre un campo vale `null` dentro del constructor?

**⏱️ 30 segundos.** Porque la inyección de campos ocurre **después** de que el
constructor termine.

**🗣️ 2 minutos.** El contenedor no puede asignar un campo de un objeto que todavía no
existe: primero llama al constructor, y solo entonces rellena campos y setters anotados.
Es una de las razones para inyectar por constructor ([`03`](03-inyeccion-de-dependencias.md)): ahí el valor llega como
parámetro y puedes usarlo de inmediato, además de declararlo `final`. Si de verdad
necesitas lógica de inicialización que dependa de valores inyectados por campo, va en
`@PostConstruct`.

**🔬 El detalle.** El `${...}` no lo resuelve el contenedor al inyectar: lo resuelve el
`PropertySourcesPlaceholderConfigurer`, un `BeanFactoryPostProcessor` que corre en la fase
2, sobre las **definiciones**. Para cuando tu constructor se ejecuta (fase 3) el valor ya
existe en el `Environment`; lo que todavía no ha ocurrido es escribirlo en el campo, que
es la fase 4. Por eso el mismo `@Value` funciona sin problema como parámetro del
constructor.

---

### 02 → 4

> Tienes una clase de una librería de terceros que necesitas como bean. ¿`@Component` o
> `@Bean`? ¿Por qué no tienes elección?

**⏱️ 30 segundos.** `@Bean`. `@Component` exige anotar la clase, y la clase no es tuya.

**🗣️ 2 minutos.** `@Component` funciona cuando el código es tuyo y el component scan lo
alcanza. Para un tipo de terceros solo te queda escribir la receta: un método `@Bean` en
una `@Configuration` que lo construye con los parámetros que quieras. Además `@Bean` te
permite lógica de construcción —leer propiedades, elegir implementación, aplicar un
builder— que la anotación sobre la clase no admite. Los parámetros del método `@Bean` son
puntos de inyección como los de un constructor.

**🔬 El detalle.** Dos consecuencias del método `@Bean` que muerden después. El nombre del
bean sale del **nombre del método**, así que renombrarlo rompe cualquier `@Qualifier` que
lo buscara por nombre. Y el atributo `destroyMethod` **detecta por convención** un método
público `close()` o `shutdown()` y lo llama al cerrar el contexto: si envuelves un tipo de
terceros que tiene un `close()` que no quieres que se llame, hay que declarar
`destroyMethod = ""`.

---

### 02 → 5

> ¿Qué diferencia de comportamiento real —no semántica— tiene `@Repository` frente a
> `@Component`?

**⏱️ 30 segundos.** `@Repository` activa la traducción de excepciones: convierte las
excepciones propias del driver o del proveedor JPA en la jerarquía `DataAccessException`
de Spring.

**🗣️ 2 minutos.** `@Service` y `@Controller` son `@Component` con estereotipo, y su
diferencia es puramente semántica y de filtrado por herramientas. `@Repository` sí añade
comportamiento, mediante un post-procesador que envuelve el bean. Gracias a eso tu capa
de servicio no depende de `SQLException` ni de las excepciones de Hibernate, sino de una
jerarquía única y unchecked — que además es la que hace que el rollback por defecto
funcione, porque son `RuntimeException` (`16`).

---

### 02 → 6

> Un método `@Bean` llama a otro método `@Bean` de la misma clase `@Configuration`.
> ¿Cuántas instancias se crean, y qué lo decide?

**⏱️ 30 segundos.** Una sola. Lo decide `proxyBeanMethods`, que por defecto está en
`true`: la clase `@Configuration` se registra como proxy CGLIB que intercepta esas
llamadas.

**🗣️ 2 minutos.** En el llamado *modo full*, cuando un método `@Bean` invoca a otro, el
proxy no ejecuta el método: devuelve el bean que ya existe en el contenedor. Es lo que
evita duplicados silenciosos. Con `proxyBeanMethods = false` —el *modo lite*— la llamada
es Java normal y obtienes dos instancias distintas. Lo mismo pasa con un método `@Bean`
dentro de una clase `@Component`, que también es modo lite.

**🔬 El detalle.** Las autoconfiguraciones de Boot usan casi siempre el modo lite, porque
sus métodos `@Bean` reciben las dependencias como parámetros en vez de llamarse entre sí,
y así se ahorra crear el proxy en el arranque.

---

### 02 → 7

> ¿Qué hace `proxyBeanMethods = false` y por qué las autoconfiguraciones de Boot lo usan?

**⏱️ 30 segundos.** Apaga el proxy CGLIB de la clase `@Configuration`. Boot lo usa porque
sus métodos `@Bean` no se llaman entre sí y así se ahorra un proxy por cada clase de
autoconfiguración en el arranque.

**🗣️ 2 minutos.** Con el proxy apagado, una llamada entre métodos `@Bean` es una llamada
Java corriente y crea una instancia nueva: es seguro exactamente cuando no hay tales
llamadas. Como Boot carga decenas de clases de autoconfiguración en cada arranque, el
ahorro se nota. La regla para tu propio código: si tus métodos `@Bean` reciben lo que
necesitan por parámetro, puedes apagarlo; si se llaman entre sí, no.

---

### 02 → 8

> Tu clase tiene `@Service` y el arranque falla con `NoSuchBeanDefinitionException`.
> ¿Cuál es la causa más probable y cómo lo confirmas?

**⏱️ 30 segundos.** Que la clase está fuera del paquete base del component scan. Se
confirma comparando su paquete con el de la clase `@SpringBootApplication`.

**🗣️ 2 minutos.** `@SpringBootApplication` incluye un `@ComponentScan` sin argumentos, que
escanea desde el paquete de esa clase **hacia abajo**. Una clase en un paquete hermano no
se ve, por mucho `@Service` que tenga. Las salidas, en orden: mover la clase al subárbol,
declarar `@ComponentScan(basePackages = ...)`, o —si es una librería compartida— darle su
propia autoconfiguración ([`06`](06-arranque-y-autoconfiguracion.md)), que es lo correcto y lo que casi nadie hace. La otra
causa posible, menos frecuente, es que una condición o un `@Profile` excluyera la
definición.

**🔬 El detalle.** Hay una cuarta salida que casi nadie recuerda: `@Import`, que trae una
clase `@Configuration` —o un `ImportSelector`— sin escanear nada, esté donde esté en el
classpath. Es el mecanismo sobre el que se apoyan las autoconfiguraciones de Boot
([`06`](06-arranque-y-autoconfiguracion.md)) y la forma limpia de componer la
configuración de una librería sin abrir el escaneo a su paquete.

---

### 02 → 9

> ¿Qué pasa si pones la clase `@SpringBootApplication` en el paquete raíz del proyecto?

**⏱️ 30 segundos.** Que el component scan intenta escanear todo lo que haya por debajo,
incluidas las librerías del classpath, y el arranque se dispara.

**🗣️ 2 minutos.** Escanear desde `com` o desde el default package obliga al contenedor a
recorrer miles de clases buscando anotaciones, y puede además registrar como beans cosas
que no querías. El síntoma es un arranque de decenas de segundos y, en el peor caso,
beans inesperados. La convención —clase de arranque en el paquete raíz **de tu
aplicación**, con todo el código por debajo— no es estética: es lo que mantiene el escaneo
acotado.

**🔬 El detalle.** La cuenta, con su unidad: cada bean cuesta escaneo, definición,
instanciación, inyección y evaluación de proxies. Un servicio con 300 beans arranca en el
entorno de los dos segundos; uno con 3 000 —un monolito bancario típico— se va a los
veinte o treinta. En un contenedor que escala bajo demanda eso es latencia de usuario, y
es la razón de que existan `@Lazy`, la AOT y las imágenes native (`L09`).

---

### 02 → 10

> ¿Cuándo se evalúa un `@Conditional`, y por qué eso hace imposible activar un bean
> cambiando una propiedad en caliente?

**⏱️ 30 segundos.** En el registro de bean definitions, durante el arranque. Después ya no
se vuelve a mirar.

**🗣️ 2 minutos.** La condición decide si la definición existe. Un bean que no se registró
no aparece porque cambie una propiedad más tarde: habría que reconstruir el contexto. Esto
importa para entender que toda la familia `@ConditionalOnClass`, `@ConditionalOnMissingBean`
y `@ConditionalOnProperty` —es decir, la autoconfiguración entera (`06`)— es una decisión
tomada una vez.

**🔬 El detalle.** El corolario de seguridad: un `@Profile("!prod")` sobre un bean que
relaja la autenticación es una bomba, porque basta arrancar sin el profile correcto para
que se registre.

---

### 02 → 11

> ¿Qué beans **no** ejecutan su `@PreDestroy`, y de quién es entonces la responsabilidad
> de liberar sus recursos?

**⏱️ 30 segundos.** Los de scope `prototype`. La responsabilidad es de quien pidió la
instancia.

**🗣️ 2 minutos.** El contenedor crea el prototype, lo entrega y no guarda referencia, así
que al cerrar el contexto no tiene a quién llamar. Si ese objeto abre un fichero, una
conexión o un executor, hay que cerrarlo explícitamente. Es la diferencia más importante
frente al singleton y la que más se falla en entrevistas (`04`).

**🔬 El detalle.** En los beans normales hay tres mecanismos: `@PreDestroy`,
`DisposableBean.destroy()` y el `destroyMethod` de `@Bean`, que además **detecta por
convención** un método `close()` o `shutdown()` público. Si tu bean tiene un `close()` que
no quieres que se llame, hay que declarar `destroyMethod = ""`.

---

### 02 → 12

> `spring.main.lazy-initialization=true` acelera el arranque. ¿Por qué el curso
> desaconseja usarlo en producción?

**⏱️ 30 segundos.** Porque mueve los errores de configuración del despliegue al primer
request que toque ese bean.

**🗣️ 2 minutos.** Que los singletons se creen ansiosamente es deliberado: si falta una
propiedad, si un `DataSource` no conecta o si hay dos candidatos ambiguos, revienta al
desplegar, cuando estás mirando. Con inicialización perezosa, la aplicación arranca
"bien" y el fallo aparece a las tres de la mañana con el primer usuario que entra por esa
ruta. En desarrollo el intercambio compensa; en producción, no.

---

### 02 → 13

> ¿Qué comando o endpoint usarías para saber qué beans existen y quién los declaró?

**⏱️ 30 segundos.** El endpoint `/actuator/beans`, que lista cada bean con su tipo, su
scope y la clase que lo declaró.

**🗣️ 2 minutos.** Es la herramienta que cierra la mayoría de las discusiones sobre "¿de
dónde salió este bean?". Se complementa con `/actuator/conditions`, que muestra qué
autoconfiguraciones se aplicaron y cuáles no, con su motivo (`06`), y con arrancar con
`--debug`, que imprime ese mismo informe por consola. Los tres se practican en `L01` y se
explican en `23`.

---

## Capítulo 03 — Inyección de dependencias y resolución de candidatos

### 03 → 1

> Da las tres razones para inyectar por constructor, ordenadas por peso, y di cuál de
> ellas es un argumento de diseño y no de mecánica.

**⏱️ 30 segundos.** Campos `final` e inmutabilidad, testabilidad sin contenedor, y que el
constructor duela cuando la clase hace demasiado. La tercera es el argumento de diseño.

**🗣️ 2 minutos.** La primera elimina la ventana en la que un colaborador puede ser `null`
y con ella una familia entera de `NullPointerException`. La segunda permite
`new Servicio(mock1, mock2)` en un test unitario, sin levantar un contexto que tarda
segundos — y eso decide cuánto dura tu suite (`24`). La tercera es la interesante en una
entrevista: ocho parámetros en un constructor se leen mal, y ese dolor es la señal de que
la clase viola responsabilidad única. La inyección por campo anestesia justo esa señal,
porque da igual tener tres dependencias que quince.

**🔬 El detalle.** Dos matices que separan al que entendió del que recita. El primero: el
argumento "por campo es más corto" es real —son cuatro líneas menos— y la respuesta
honesta del mundo real es Lombok con `@RequiredArgsConstructor`, legítimo en un proyecto y
fuera de este curso porque esconde justo lo que se está explicando. El segundo: la
inyección por setter no es un error, tiene un nicho estrecho —dependencias genuinamente
opcionales o reconfigurables después de construir—, solo que en la práctica casi nunca se
da.

---

### 03 → 2

> ¿Cuándo es obligatorio escribir `@Autowired` y cuándo se omite?

**⏱️ 30 segundos.** Se omite cuando hay un solo constructor. Es obligatorio en campos y
setters, y para marcar cuál de varios constructores usar.

**🗣️ 2 minutos.** Desde Spring 4.3, un único constructor se considera implícitamente el
punto de inyección, así que anotarlo es ruido. Con dos o más constructores hay que marcar
uno. En campos y setters la anotación es la única señal que tiene el contenedor.

**🔬 El detalle.** La pregunta que sigue en una entrevista es por la dependencia opcional.
`@Autowired(required = false)` deja el punto de inyección vacío si no hay candidato, y en
un constructor eso no significa nada —o construyes el objeto o no—, así que lo opcional se
declara como `Optional<T>` o como `ObjectProvider<T>`. El segundo es la versión completa:
`getIfAvailable()`, `getIfUnique()`, iterar todos los candidatos y **resolver tarde** en
vez de en el arranque, que es lo que lo convierte además en la herramienta para inyectar
un bean de vida corta en uno largo ([`04`](04-scopes-de-bean.md)).

---

### 03 → 3

> Una clase tiene dos constructores y ninguno anotado. ¿Qué pasa en el arranque?

**⏱️ 30 segundos.** Falla: el contenedor no adivina, busca un constructor sin argumentos
y, si no existe, no puede construir el bean.

**🗣️ 2 minutos.** Lo que despista es el mensaje: habla de que no encuentra un constructor
por defecto y no menciona la ambigüedad, que es la causa real. La corrección es anotar con
`@Autowired` el constructor que el contenedor debe usar — o, mejor todavía, preguntarse
por qué la clase necesita dos formas de construirse.

---

### 03 → 4

> Describe el algoritmo de resolución de candidatos en orden. ¿En qué paso entra el
> nombre?

**⏱️ 30 segundos.** Por tipo → filtrar por `@Qualifier` → `@Primary` → por nombre →
`NoUniqueBeanDefinitionException`. El nombre es el **último** desempate.

**🗣️ 2 minutos.** Primero se buscan todos los beans asignables al tipo del punto de
inyección. Si hay uno, resuelto. Si hay varios, se filtra por qualifier; si sigue habiendo
varios, gana el marcado como `@Primary`; y solo entonces se intenta desempatar comparando
el nombre del bean con el del campo o el del parámetro. Si aun así quedan dos, el arranque
falla nombrando a los candidatos.

**🔬 El detalle.** Los genéricos también cualifican: `Validator<Invoice>` y
`Validator<Payment>` no son ambiguos entre sí aunque el tipo crudo sea el mismo.

---

### 03 → 5

> Tienes un único bean de un tipo y renombras el parámetro del constructor. ¿Cambia algo?
> ¿Y si tuvieras dos beans de ese tipo?

**⏱️ 30 segundos.** Con un solo candidato no cambia nada. Con dos, el renombrado puede
cambiar qué bean se inyecta.

**🗣️ 2 minutos.** Es la consecuencia práctica de que el nombre sea el último desempate: en
el caso ambiguo, una refactorización tan inocente como renombrar un parámetro altera el
comportamiento sin tocar ninguna anotación, y no deja rastro en la revisión de código. Es
la razón para no depender nunca del desempate por nombre: si hay dos candidatos legítimos,
cualifica explícitamente.

---

### 03 → 6

> ¿Qué diferencia hay entre `@Primary` y `@Qualifier`, y en qué situación es preferible
> cada uno?

**⏱️ 30 segundos.** `@Primary` marca al bean ("si hay duda, yo"); `@Qualifier` marca al
punto de inyección ("quiero exactamente este"). `@Primary` cuando hay un default obvio;
`@Qualifier` cuando no lo hay.

**🗣️ 2 minutos.** Si el 90 % de los puntos de inyección quieren la misma implementación y
uno quiere otra, marca la común con `@Primary` y cualifica solo la excepción. Si las dos
son igual de legítimas —un repositorio de escritura y uno de lectura—, no hay default
honesto: cualifica los dos lados. Elegir mal no se nota hasta que aparece el tercer
candidato.

**🔬 El detalle.** Spring Framework 6.2 añadió `@Fallback`, que es el inverso de
`@Primary`: marca un bean como candidato **de reserva**, el que solo se inyecta si no hay
ningún otro. Es lo que quieres en una autoconfiguración —un `Clock` de sistema, un
`ObjectMapper` razonable— para que el bean de la aplicación gane sin tener que declararse
`@Primary`. Material anterior a 2024 no lo menciona y resuelve el mismo problema con
`@Primary` al revés o con `@ConditionalOnMissingBean`.

---

### 03 → 7

> ¿Por qué un qualifier propio es más seguro que `@Qualifier("cadena")`?

**⏱️ 30 segundos.** Porque la cadena es texto: un renombrado la rompe y el compilador
calla. Una anotación propia la verifica el compilador y la encuentra el IDE.

**🗣️ 2 minutos.** Un qualifier propio es una anotación anotada a su vez con `@Qualifier`.
Se pone en el `@Bean` y en el punto de inyección, y a partir de ahí renombrar es una
refactorización segura, el autocompletado la sugiere y "buscar usos" funciona. Con la
cadena mágica no tienes nada de eso, y el fallo aparece en el arranque en el mejor caso, o
inyectando el bean equivocado en el peor.

**🔬 El detalle.** Un qualifier propio son tres líneas: una anotación marcada a su vez con
`@Qualifier` y con `@Retention(RUNTIME)`, que se pone en el `@Bean` y en el punto de
inyección. Y una señal de diseño que conviene leer: si acabas con más de dos o tres
`@Qualifier("cadena")` en el mismo servicio, casi siempre el modelo correcto era una
colección de estrategias —`List<T>` o `Map<String, T>`— y no una lista de beans
cualificados a mano.

---

### 03 → 8

> ¿Qué recibe un parámetro declarado como `Map<String, InventoryValidator>` y qué son las
> claves?

**⏱️ 30 segundos.** Todos los beans de ese tipo, indexados por **nombre de bean**.

**🗣️ 2 minutos.** Es el patrón para seleccionar una estrategia en tiempo de ejecución por
un valor de configuración o un campo del request, sin un `switch`. Su hermano `List<T>`
recibe los mismos beans como colección ordenada. Entre los dos cubren el Strategy y el
Chain of Responsibility sin escribir registro alguno: añadir una estrategia pasa a ser
añadir una clase con `@Component`.

**🔬 El detalle.** El caso límite está en las claves: con `@Bean`, el nombre del bean es el
del método, así que renombrar el método cambia la clave del mapa y el `switch` implícito
deja de encontrar su estrategia, sin que nada falle al compilar. Y el hermano `List<T>`
tiene un modo de fallo propio: si no hay **ningún** candidato el arranque falla, salvo que
el punto sea `@Autowired(required = false)` o la lista venga de un `ObjectProvider`.

---

### 03 → 9

> ¿Qué determina el orden de una `List<T>` inyectada, y qué pasa si no lo declaras?

**⏱️ 30 segundos.** `@Order(n)` —menor primero— o implementar `Ordered`. Sin eso, el orden
es indefinido.

**🗣️ 2 minutos.** No es alfabético ni el del classpath ni el de declaración, y puede
cambiar entre ejecuciones o tras un refactor. Si tu cadena de validadores necesita que uno
corra antes que otro, hay que declararlo; apoyarse en el orden que salió hoy es un bug
esperando a que alguien mueva un archivo.

---

### 03 → 10

> `@Value("${inv.supplier.timeout}")` sin valor por defecto y sin la propiedad definida:
> ¿qué ocurre, y por qué suele ser lo deseable?

**⏱️ 30 segundos.** El arranque falla porque el placeholder no se puede resolver. Y suele
ser lo deseable: es mejor no arrancar que arrancar mal configurado.

**🗣️ 2 minutos.** La sintaxis `${x:valor}` define un default; omitirlo convierte la
propiedad en obligatoria. Para algo como un timeout, un default silencioso es peor que el
fallo: te deja en producción con un valor que nadie eligió. El fallo de arranque, en
cambio, lo ve quien despliega.

**🔬 El detalle.** La sintaxis exacta es `${propiedad:valor}`, y el valor por defecto es
todo lo que va tras los dos puntos. La conversión la hace el sistema de conversión de
Spring, no tu código: declarando el parámetro como `Duration` se enlazan `2s`, `500ms` y
`PT2S` indistintamente, así que inyectar un `String` y parsearlo a mano es trabajo tirado.

---

### 03 → 11

> ¿A partir de cuántos `@Value` en una clase deberías cambiar a `@ConfigurationProperties`,
> y qué ganas?

**⏱️ 30 segundos.** A partir de tres, como regla práctica. Ganas tipado, validación,
agrupación y metadatos para el IDE.

**🗣️ 2 minutos.** `@Value` dispersa cadenas de configuración por el código y no permite
validar el conjunto. `@ConfigurationProperties` mapea un prefijo entero a un objeto —un
`record`, en este curso—, admite `@Validated` para que el arranque falle si falta o
sobra algo, y con el processor de metadatos da autocompletado en el `application.yml`. Se
ve entero en [`07`](07-configuracion-externalizada.md).

**🔬 El detalle.** Lo concreto: un `record` anotado con `@ConfigurationProperties(prefix =
"inv.supplier")` enlaza por constructor sin anotaciones extra, y con `@Validated` más las
restricciones de Bean Validation el arranque falla nombrando la propiedad y la
restricción. Se registra con `@EnableConfigurationProperties(...)` o con
`@ConfigurationPropertiesScan`, y `spring-boot-configuration-processor` como dependencia
opcional genera los metadatos del autocompletado. Todo eso está en
[`07`](07-configuracion-externalizada.md).

---

### 03 → 12

> Un ciclo de dependencias rompe el arranque con inyección por constructor pero
> "funcionaba" con inyección por campo. ¿Qué hacía distinto el contenedor?

**⏱️ 30 segundos.** Con campos, creaba ambos objetos vacíos y rellenaba los campos
después; con constructores no puede, porque necesita el colaborador para construir.

**🗣️ 2 minutos.** El ciclo estaba igual de presente en los dos casos: la diferencia es que
con inyección por campo quedaba invisible. Que el arranque falle con un diagrama del ciclo
es una buena noticia — te avisa al desplegar y no en producción.

---

### 03 → 13

> Nombra las tres salidas de un ciclo y di cuál es deuda técnica y cuál es solución.

**⏱️ 30 segundos.** `spring.main.allow-circular-references=true` y `@Lazy` son deuda;
rediseñar —extraer un tercer bean o invertir la dependencia con un evento— es la solución.

**🗣️ 2 minutos.** La propiedad restaura el comportamiento antiguo y esconde el ciclo por
completo. `@Lazy` en uno de los lados inyecta un proxy que resuelve al primer uso: rompe
el ciclo de construcción pero el acoplamiento sigue ahí. La salida real suele ser extraer
lo compartido a un tercer bean, o darle la vuelta a la relación publicando un evento que
el otro escucha (`18`). En una entrevista, la pregunta que sigue siempre es por qué
existía el ciclo.

**🔬 El detalle.** El matiz de cada salida: `spring.main.allow-circular-references=true` no
rompe el ciclo, restaura el comportamiento de la inyección por campo y lo vuelve invisible
otra vez —es deuda declarada, con fecha—. `@Lazy` sí cambia algo: inyecta un proxy que
resuelve el bean al primer uso, de modo que el ciclo deja de doler en el arranque y se
paga en la primera llamada. Y la salida por evento tiene su propio matiz: los eventos de
aplicación son **síncronos por defecto** ([`18`
§8](18-asincronia-scheduling-y-eventos.md#8--eventos-de-aplicación-síncronos-por-defecto)),
así que invertir la dependencia con un evento no cambia el hilo ni la transacción — solo
el sentido del acoplamiento.

---

### 03 → 14

> ¿En qué se diferencia `@Resource` de `@Autowired` al resolver?

**⏱️ 30 segundos.** `@Resource` resuelve **primero por nombre** y después por tipo.
`@Autowired` al revés.

**🗣️ 2 minutos.** `@Resource` viene de Jakarta (JSR-250) y su semántica es "dame el bean
que se llama así". Aparece en código heredado y en proyectos que vienen de Java EE.
Suponer que se comporta como `@Autowired` es una fuente de bugs silenciosos: con dos
candidatos, cada anotación elige uno distinto y nada en el código lo delata.

---

## Capítulo 04 — Scopes de bean

### 04 → 1

> ¿Por qué el singleton de Spring no es el patrón Singleton? Da dos diferencias.

**⏱️ 30 segundos.** Porque es uno por `ApplicationContext`, no uno por JVM, y porque la
clase no tiene constructor privado ni control sobre su propia unicidad.

**🗣️ 2 minutos.** El patrón clásico hace que la clase se imponga a sí misma la unicidad,
con constructor privado y acceso estático — con todo lo que eso implica para las pruebas.
En Spring la unicidad es una decisión del contenedor, externa a la clase: la misma clase
puede instanciarse libremente con `new` en un test, y puede tener una instancia en cada
uno de los contextos vivos del proceso. Eso último pasa de verdad en una suite con varios
contextos cacheados (`24`).

---

### 04 → 2

> ¿Cuántas instancias de un bean singleton puede haber vivas en el mismo proceso, y en
> qué situación real ocurre?

**⏱️ 30 segundos.** Tantas como contextos haya. Ocurre en los tests, donde Spring cachea
varios `ApplicationContext` distintos.

**🗣️ 2 minutos.** Cada combinación distinta de configuración de test —otro conjunto de
mocks, otras propiedades, otro slice— produce un contexto nuevo que se cachea aparte. Si
tu bean guarda estado estático o registra algo global, dos contextos vivos se pisan, y
tienes un fallo de test que no se reproduce en producción. Es también la razón por la que
esa caché de contextos decide la duración de tu suite (`24`).

---

### 04 → 3

> ¿Qué le pasa al `@PreDestroy` de un bean `prototype` y qué implica para un bean que
> abre recursos?

**⏱️ 30 segundos.** No se ejecuta: el contenedor no guarda referencia al prototype.
Liberar sus recursos es responsabilidad de quien lo pidió.

**🗣️ 2 minutos.** El contenedor construye el prototype, lo entrega y se desentiende. Al
cerrar el contexto no tiene a quién llamar, así que ni `@PreDestroy`, ni
`DisposableBean`, ni `destroyMethod`. Si ese objeto abre un fichero, una conexión o un
executor, hay que cerrarlo explícitamente — con `try-with-resources` si implementa
`AutoCloseable`, o con una llamada explícita. Es la diferencia más importante frente al
singleton.

**🔬 El detalle.** No se ejecuta ninguno de los tres mecanismos de destrucción: ni
`@PreDestroy`, ni `DisposableBean.destroy()`, ni el `destroyMethod` de `@Bean` — incluida
la detección por convención de `close()` y `shutdown()` que sí funciona en un singleton
([`02`](02-contenedor-ioc-y-ciclo-de-vida.md)). La consecuencia práctica es que un
prototype que abre recursos se trata como un recurso, no como un bean:
`try-with-resources` si implementa `AutoCloseable`, o una llamada explícita en un
`finally`.

---

### 04 → 4

> Inyectas un bean `prototype` en el constructor de un singleton. ¿Cuántas instancias se
> crean durante la vida de la aplicación?

**⏱️ 30 segundos.** Una. El singleton lo pide una sola vez, en el arranque, y se queda con
ella.

**🗣️ 2 minutos.** El scope no manda por sí solo: manda **cuántas veces se le pide el bean
al contenedor**. Como el constructor del singleton se ejecuta una vez, el prototype se
resuelve una vez y a partir de ahí se comporta exactamente como un singleton. Es la
trampa clásica de scopes mixtos, y la solución es pedirlo tarde: `ObjectProvider`,
`@Lookup` o un scoped proxy.

---

### 04 → 5

> Nombra las tres formas de obtener una instancia nueva de un `prototype` desde un
> singleton, y di cuál prefieres y por qué.

**⏱️ 30 segundos.** `ObjectProvider<T>`, `@Lookup` y el scoped proxy. Este curso prefiere
`ObjectProvider` porque hace visible en la firma que la resolución es tardía.

**🗣️ 2 minutos.** `ObjectProvider.getObject()` devuelve una instancia nueva en cada
llamada y además ofrece `getIfAvailable()` y `getIfUnique()`; no hay proxy de por medio y
el código se lee solo. `@Lookup` obliga a que la clase sea abstracta o el método
sobreescribible, porque el contenedor genera una subclase: funciona, y se ve sobre todo en
código heredado. El scoped proxy es transparente en el punto de uso, lo que es una ventaja
cuando quieres que el llamador no se entere —caso típico de `request`— y una desventaja
cuando quieres que sí se entere.

**🔬 El detalle.** La subclase que genera `@Lookup` es la de CGLIB de
[`05`](05-proxies-y-aop.md), así que el método de fábrica hereda sus límites: no puede ser
`private`, `final` ni `static`, y la clase tampoco puede ser `final`. El scoped proxy
tiene una asimetría que decide más de lo que parece: se declara en el `@Scope` del bean
corto, no en el punto de inyección, así que la decisión la toma quien define el bean y no
quien lo consume — y quien lo consume no tiene forma de saber por la firma que cada
llamada resuelve una instancia distinta. `ObjectProvider` es el único de los tres que deja
eso escrito en el constructor.

---

### 04 → 6

> ¿Qué hace exactamente `proxyMode = ScopedProxyMode.TARGET_CLASS`?

**⏱️ 30 segundos.** Inyecta un proxy del mismo tipo que el bean, que en cada llamada busca
la instancia correspondiente al scope activo y le delega.

**🗣️ 2 minutos.** El proxy se crea una vez y se inyecta como si fuera el bean, así que un
singleton puede tenerlo como campo `final` sin problema. En cada invocación consulta el
scope —el request o la sesión en curso— y delega en la instancia que toque. `TARGET_CLASS`
genera el proxy por subclase (CGLIB); `INTERFACES` lo genera implementando las interfaces.
El mecanismo es el mismo de `05`.

**🔬 El detalle.** La elección entre los dos modos tiene consecuencias de tipo, y son las
mismas de [`05`](05-proxies-y-aop.md): `TARGET_CLASS` no funciona sobre una clase `final`,
porque necesita heredar de ella; `INTERFACES` produce un proxy JDK que **solo es asignable
a las interfaces**, así que un punto de inyección declarado con la clase concreta revienta
con `BeanNotOfRequiredTypeException`. La regla que hace irrelevante el modo es la misma de
allí: declara la dependencia por la interfaz.

---

### 04 → 7

> Inyectas un bean de scope `request` en un singleton sin `proxyMode`. ¿Qué pasa y cuándo?

**⏱️ 30 segundos.** Falla en el arranque, porque intenta resolver la instancia cuando
todavía no hay ningún request.

**🗣️ 2 minutos.** El error dice que no hay un request activo ligado al hilo, y leído bien
contiene el diagrama entero del problema: el contenedor está construyendo el singleton
durante el arranque, momento en el que no existe ningún `RequestContext`. Con
`proxyMode = TARGET_CLASS` se inyecta un proxy y la resolución se aplaza a la primera
llamada, que sí ocurrirá dentro de un request.

**🔬 El detalle.** Falla en el arranque y no en la primera llamada porque los singletons se
crean de forma **ansiosa** ([`02`](02-contenedor-ioc-y-ciclo-de-vida.md)); con
`spring.main.lazy-initialization=true` el mismo error se movería al primer request que
toque ese bean, que es peor. Y el `proxyMode` no es la única salida: inyectar
`ObjectProvider<RequestContext>` y llamar a `getObject()` dentro del método resuelve
igual, tarde, y deja la resolución tardía visible en la firma.

---

### 04 → 8

> ¿Por qué un bean `request` no se puede resolver dentro de un método `@Async`?

**⏱️ 30 segundos.** Porque el contexto del request se guarda en un `ThreadLocal` y el hilo
del executor no lo hereda.

**🗣️ 2 minutos.** `RequestContextHolder` ata el request al hilo que lo atiende. Un
`@Async` salta a otro hilo de otro pool, donde ese `ThreadLocal` está vacío, así que el
scope no tiene dónde buscar. El mismo mecanismo explica por qué se pierden el
`SecurityContext` y el `traceId` del MDC al cruzar a un pool, y por qué hay que
propagarlos explícitamente (`18`).

**🔬 El detalle.** Es el mismo mecanismo para las cuatro cosas que Spring cuelga del hilo:
`SecurityContextHolder`, `RequestContextHolder`, el MDC de SLF4J y el
`TransactionSynchronizationManager`, que guarda la conexión y la transacción activas — de
ahí que una transacción tampoco cruce a un hilo asíncrono (`16`). Con virtual threads el
problema de la **limpieza** cambia de forma, porque cada tarea estrena su hilo y no se
reutiliza, pero el de la **propagación** sigue exactamente igual
([`08`](08-modelo-de-ejecucion-web.md)).

---

### 04 → 9

> ¿Por qué no existe el scope `request` en WebFlux, y qué ocupa su lugar?

**⏱️ 30 segundos.** Porque el modelo reactivo no ata el trabajo a un hilo, así que no hay
dónde colgar el estado. Su lugar lo ocupa el `Context` de Reactor.

**🗣️ 2 minutos.** En WebFlux una misma petición puede ejecutarse en varios hilos a lo
largo de su cadena de operadores, de modo que cualquier cosa basada en `ThreadLocal` deja
de ser fiable. El equivalente es el contexto que viaja con la suscripción
(`Context`/`ContextView`), que se propaga por la cadena en vez de por el hilo ([`11`](11-webflux-y-reactor.md)). Es
una de las diferencias que más duele al migrar de MVC a WebFlux, y casi nunca se menciona.

---

### 04 → 10

> Un `@Service` guarda el usuario actual en un campo antes de validarlo. Describe el
> fallo, por qué no aparece en los tests y cómo se corrige.

**⏱️ 30 segundos.** Hay un solo bean y muchos hilos: dos requests simultáneos se pisan el
campo. No aparece en los tests porque corren un request por vez. Se corrige pasando el
valor como parámetro o usando una variable local.

**🗣️ 2 minutos.** El campo mutable en un singleton es una condición de carrera clásica: el
request A escribe el usuario, el request B lo sobreescribe, y A audita con el usuario de
B. No lanza excepción y no aparece en ninguna prueba unitaria. En banca eso no es un bug,
es un incidente de auditoría. La regla es que un bean singleton sea stateless: sus campos
son colaboradores `final`, y todo lo que cambia por request viaja en los argumentos.

**🔬 El detalle.** Las salidas honestas son tres, en orden: pasar el valor como parámetro
(siempre la mejor), una variable local dentro del método —que ya es por hilo y no cuesta
nada—, y solo si de verdad tiene que atravesar capas sin ensuciar las firmas, un
`ThreadLocal` con sus advertencias ([`08`](08-modelo-de-ejecucion-web.md)) o un bean de
scope `request`. Fíjate en que las dos primeras no son configuración de Spring: el bug no
se arregla con un scope, se arregla no escribiendo en un campo.

---

### 04 → 11

> ¿Qué implicación de escalado tiene usar el scope `session`?

**⏱️ 30 segundos.** Guarda estado en el servidor, así que rompe el escalado horizontal
salvo que uses sticky sessions o un almacén compartido.

**🗣️ 2 minutos.** Si la sesión vive en memoria de una instancia, cualquier request que
caiga en otra réplica no la encuentra: hay que atar al usuario a su instancia —con sus
consecuencias para los despliegues y el reequilibrado— o externalizar la sesión con algo
como Spring Session sobre Redis. En una API stateless con Bearer token, el scope `session`
simplemente no tiene sitio ([`08`](08-modelo-de-ejecucion-web.md)).

**🔬 El detalle.** La cuenta, con su unidad: memoria retenida = *(usuarios con sesión viva)
× (tamaño del bean)*, y la sesión no muere cuando el usuario se va, sino cuando expira
`server.servlet.session.timeout` —**30 minutos** por defecto—. Diez mil sesiones vivas con
20 KB de estado cada una son 200 MB de heap que no se liberan durante media hora, y que
además hay que replicar si hay más de una instancia. Ese es el argumento real contra
`session` en una API, antes que el estético.

---

### 04 → 12

> ¿Cuál es el scope por defecto y por qué esa elección obliga a que tus servicios sean
> stateless?

**⏱️ 30 segundos.** `singleton`. Como hay una sola instancia atendiendo a todos los hilos,
cualquier campo mutable se comparte entre requests.

**🗣️ 2 minutos.** Es una decisión de rendimiento: crear un servicio por request sería caro
y casi siempre inútil, porque un servicio bien diseñado no tiene estado propio. La
contrapartida es la disciplina: colaboradores `final` inyectados por constructor y datos
por parámetro. Cuando alguien rompe esa regla, el fallo es silencioso y solo aparece bajo
carga.

**🔬 El detalle.** Y una trampa de escritura que cuesta horas: `@Scope("prototipe")` mal
escrito no es un error de compilación ni de arranque — el bean se queda `singleton` y
nadie se entera. Por eso se prefiere la constante
`ConfigurableBeanFactory.SCOPE_PROTOTYPE` a la cadena: no admite esa errata.

---

## Capítulo 05 — Proxies y AOP

### 05 → 1

> "`@Transactional` abre una transacción": corrige la frase. ¿Qué te entrega realmente
> el contenedor al inyectar ese bean, y en qué fase del arranque se decidió?

**⏱️ 30 segundos.** La anotación no abre nada: le dice a un **proxy** que le pida al
`TransactionManager` que abra una. Lo que te entrega el contenedor es ese proxy, no tu
objeto, y se decidió en la fase de `BeanPostProcessor`, después de construirlo e
inyectarle sus dependencias.

**🗣️ 2 minutos.** Sin proxy en medio, `@Transactional` es un comentario: por eso una
llamada interna no abre transacción. El contenedor construye tu instancia, la completa, y
entonces un post-procesador comprueba si alguna anotación pide interceptar. Si la hay,
crea el proxy y **registra el proxy** en lugar del objeto. Todos tus otros beans reciben
esa envoltura. La decisión se toma una sola vez, en el arranque: no existe añadir
`@Transactional` en caliente.

**🔬 El detalle.** Las fases, para poder decirlas en orden: 3 constructor —tu objeto
existe—, 4 inyección —tu objeto está completo—, 6 `BeanPostProcessor` —¿alguna anotación
pide interceptar? si sí, se crea el proxy y **se registra el proxy**—, 7 `@PostConstruct`,
que ya corre sobre la instancia interna. Lo que el contenedor guarda bajo ese nombre de
bean es la envoltura, y no puedes saberlo mirando el tipo declarado del punto de
inyección.

---

### 05 → 2

> Explica la diferencia entre un proxy JDK y uno CGLIB, y di cuál usa Spring Boot por
> defecto y por qué.

**⏱️ 30 segundos.** El JDK implementa las interfaces del bean; CGLIB genera una subclase.
Spring Boot usa CGLIB por defecto (`spring.aop.proxy-target-class=true`).

**🗣️ 2 minutos.** Un proxy JDK solo es asignable a las interfaces, no a la clase concreta,
lo que produce el desconcertante `BeanNotOfRequiredTypeException` cuando alguien inyecta
por clase. CGLIB, al ser una subclase, es asignable a la clase concreta y funciona aunque
no haya interfaces — a cambio de no poder interceptar métodos `final` ni clases `final`.
Boot eligió CGLIB precisamente para evitar ese error de tipo, que era una fuente constante
de confusión.

**🔬 El detalle.** La tabla completa: el proxy JDK exige que la clase implemente al menos
una interfaz y no puede interceptar métodos que no estén en ella; CGLIB exige que la clase
no sea `final` y no puede interceptar métodos `final`, `private` ni `static`. Quién
enciende esto en un proyecto Boot: la autoconfiguración de AOP, en cuanto
`spring-boot-starter-aop` está en el classpath — `@EnableAspectJAutoProxy` solo se escribe
en un contexto de Spring Framework sin Boot, o para forzar `proxyTargetClass = true` en
una configuración concreta.

---

### 05 → 3

> Lees `BeanNotOfRequiredTypeException: … but was actually of type jdk.proxy2.$Proxy142`.
> ¿Qué ocurrió y cuál es la corrección de diseño?

**⏱️ 30 segundos.** Spring creó un proxy JDK que implementa la interfaz del bean, y el
punto de inyección pedía la clase concreta. La corrección es **inyectar por interfaz**.

**🗣️ 2 minutos.** El proxy JDK no hereda de tu clase: es otro objeto que implementa la
misma interfaz, así que un campo declarado con el tipo concreto no lo acepta. La salida
táctica es forzar CGLIB; la de diseño, que es la buena, es declarar la dependencia por la
interfaz. Con eso el tipo de proxy deja de importarte, que es exactamente donde quieres
estar.

---

### 05 → 4

> ¿Por qué los campos de un proxy CGLIB están a `null`, y cuándo se convierte eso en un
> problema real?

**⏱️ 30 segundos.** Porque Spring instancia el proxy con Objenesis, sin ejecutar el
constructor. Es un problema en cuanto algo accede a un campo **directamente** a través del
proxy en vez de por un método.

**🗣️ 2 minutos.** El proxy no necesita los campos: para todo lo que llega por método,
delega en el objeto real, que sí está completo. El problema aparece con acceso directo a
campos: un `protected` leído desde una subclase, o una librería que use reflexión sobre la
instancia. El síntoma es un `NullPointerException` sobre un campo que "claramente" se
asignó en el constructor, y es de los que más tiempo se llevan si no conoces el mecanismo.

---

### 05 → 5

> ¿Cuál es el único join point que soporta Spring AOP, y qué implica esa limitación?

**⏱️ 30 segundos.** La ejecución de un método de un bean. Implica que no hay interceptación
de campos, ni de constructores, ni de llamadas internas.

**🗣️ 2 minutos.** Todo el modelo se apoya en que alguien externo llame a un método a
través del proxy. De ahí salen las dos limitaciones que dominan el capítulo: la
self-invocation y los métodos no interceptables. AspectJ real —con weaving en compilación
o en carga— sí puede ir más allá, a cambio de una capa extra de build y de operación que
rara vez compensa.

**🔬 El detalle.** De ahí sale también el vocabulario que se pregunta: los cinco advices
son `@Before`, `@AfterReturning`, `@AfterThrowing`, `@After` —que sale siempre, como un
`finally`— y `@Around`, **el único que decide si la llamada llega a ocurrir**.
`@Transactional` es conceptualmente un `@Around`, y el weaving en Spring es siempre en
runtime, vía proxy, nunca en compilación.

---

### 05 → 6

> ¿Qué pasa si un `@Around` olvida llamar a `proceed()`?

**⏱️ 30 segundos.** El método envuelto nunca se ejecuta y el advice devuelve `null` sin
lanzar ningún error.

**🗣️ 2 minutos.** Es uno de los fallos más difíciles de diagnosticar del framework, porque
todo parece correcto: el bean existe, la llamada retorna, no hay excepción. Simplemente no
pasó nada. `proceed()` es lo que invoca al siguiente eslabón de la cadena —otro advice o
tu método—, y en un `@Around` su llamada es responsabilidad tuya.

**🔬 El detalle.** Dos detalles de escritura del advice que producen el mismo silencio.
`@Around` debe declarar `throws Throwable`, porque tiene que poder propagar cualquier cosa
que lance el método envuelto. Y `@Aspect` **no crea el bean**: hace falta además
`@Component` o un método `@Bean`. Un aspecto sin registrar no da ninguna señal, igual que
un `proceed()` olvidado.

---

### 05 → 7

> Dibuja o describe por qué una llamada interna se salta el proxy.

**⏱️ 30 segundos.** El proxy envuelve al objeto desde fuera. Una vez dentro, `this` es el
objeto real, no el proxy, así que la llamada no pasa por la envoltura.

**🗣️ 2 minutos.**

```text
otro bean ──► [ proxy ] ──► metodoA()  ──► this.metodoB()  ──► el objeto, directo
                  ▲                                                │
                  └────────── el proxy ya no está en medio ─────────┘
```

De ahí la regla: misma clase, no hay proxy, no hay transacción ni caché ni retry ni async;
otro bean, hay proxy, y la anotación hace lo que promete.

---

### 05 → 8

> Nombra las tres salidas a la self-invocation y di cuál es la correcta por defecto.

**⏱️ 30 segundos.** Separar el método a otro bean (la correcta), auto-inyectarse el proxy
—o `AopContext.currentProxy()`—, y AspectJ con weaving real.

**🗣️ 2 minutos.** Separar el bean resuelve el 90 % de los casos y además suele revelar que
la clase hacía dos cosas: el problema de diseño y el técnico coinciden. Auto-inyectarse
funciona, se lee mal y deja un ciclo que hay que declarar. AspectJ resuelve el caso general
de verdad, interceptando también las llamadas internas, pero añade weaving en compilación
o en carga, y eso es una decisión de plataforma, no de una clase.

**🔬 El detalle.** El precio exacto de cada una. Auto-inyectarse exige
`AopContext.currentProxy()` con `exposeProxy = true` —o inyectar el bean en sí mismo, lo
que deja un ciclo declarado ([`03`](03-inyeccion-de-dependencias.md))—. AspectJ funciona
porque teje el advice en el bytecode, en compilación o en carga, así que la llamada
`this.record(...)` **sí** queda interceptada: es el único que resuelve el caso general, y
a cambio añade una capa de build y de operación que es una decisión de plataforma, no de
una clase.

---

### 05 → 9

> Cinco anotaciones distintas del curso sufren exactamente el mismo fallo de
> self-invocation. Nómbralas.

**⏱️ 30 segundos.** `@Transactional` (`16`), `@Cacheable` (`17`), `@Async` (`18`),
`@Retryable` / `@CircuitBreaker` (`19`) y `@PreAuthorize` (`20`).

**🗣️ 2 minutos.** Todas comparten mecanismo: son metadatos que hacen que el contenedor
envuelva el bean en un proxy. Por eso, cuando una anotación declarativa "no hace nada", la
self-invocation es siempre la primera hipótesis — antes de mirar la configuración, la
versión o la documentación.

---

### 05 → 10

> ¿En cuáles de estos casos se ignora la anotación **sin ninguna señal**: método
> `private`, método `final`, clase `final`, método `static`?

**⏱️ 30 segundos.** `private`, `final` (método) y `static` se ignoran en silencio. Una
clase `final` sí produce un error en el arranque.

**🗣️ 2 minutos.** Lo grave de esa lista no son los casos, es el silencio: el compilador no
se queja, el arranque no falla, el log calla, y el código se ve correcto. De ahí la regla
de revisión: un `@Transactional`, `@Cacheable` o `@Async` sobre un método que no sea
`public` de una clase no `final`, invocado desde otro bean, es sospechoso por defecto.

**🔬 El detalle.** La única señal parcial de la lista es el método `final`, que deja un
`INFO` de CGLIB diciendo que no puede interceptarlo; `private`, `static` y la llamada
interna no dejan nada. La clase `final` es la excepción útil: al no poder generar la
subclase, el arranque falla y te enteras al desplegar.

---

### 05 → 11

> Un método lleva `@Transactional` y `@Retryable`. Describe los dos órdenes posibles y
> qué recurso se agota con el orden equivocado.

**⏱️ 30 segundos.** O el retry envuelve a la transacción —cada intento abre y cierra la
suya— o la transacción envuelve al retry —una sola transacción abierta durante todos los
reintentos—. El segundo orden retiene una conexión del pool durante los backoffs.

**🗣️ 2 minutos.** Con veinte peticiones concurrentes en el segundo caso, cada una
mantiene una conexión de base de datos ocupada mientras espera el backoff: el pool de
Hikari se agota ([`15`](15-datos-jdbc-jpa-mongo-y-redis.md)) y el servicio cae por culpa de un mecanismo que se puso para
hacerlo más resistente. El orden por defecto entre estos interceptores no está garantizado
—varios se registran con la precedencia más baja posible—, así que cuando importa hay que
declararlo explícitamente. El apilado concreto de los patrones de resiliencia se decide en
`19`.

**🔬 El detalle.** La cuenta, con su unidad: una conexión del pool × la duración total del
backoff × las peticiones concurrentes. Con tres intentos, un segundo de espera entre ellos
y veinte peticiones a la vez son veinte conexiones retenidas durante dos segundos, y un
Hikari por defecto tiene **diez**: el pool se agota antes de que el proveedor se recupere.
Y los órdenes por defecto: `@Transactional`, `@Cacheable` y `@Async` se registran los tres
con `Ordered.LOWEST_PRECEDENCE`, así que **empatan** y el resultado queda sin definir; se
cambian con `@EnableTransactionManagement(order = …)`, `@EnableCaching(order = …)` y
`@EnableAsync(order = …)`. Resilience4j es la excepción: define un orden propio
—`Retry(CircuitBreaker(RateLimiter(TimeLimiter(Bulkhead))))`— configurable con
`resilience4j.retry.retry-aspect-order` y sus hermanas, pero no define dónde queda
respecto de `@Transactional`, que es justo el cruce peligroso.

---

### 05 → 12

> ¿Cómo compruebas en treinta segundos si un bean está proxyado?

**⏱️ 30 segundos.** Imprimiendo `bean.getClass()`: `…$$SpringCGLIB$$0` es proxy CGLIB,
`jdk.proxy2.$Proxy142` es proxy JDK, y el nombre limpio significa que no hay proxy.

**🗣️ 2 minutos.** Las otras dos comprobaciones son `AopUtils.isAopProxy(bean)` —con sus
variantes `isCglibProxy` e `isJdkDynamicProxy`, que sirven dentro de un test— y subir a
`DEBUG` el log del paquete del mecanismo que investigas, por ejemplo
`org.springframework.transaction.interceptor`: si no aparece la línea de apertura, el
interceptor no corrió. Eso último se practica en `L04`.

---

### 05 → 13

> ¿Por qué un método `@Transactional` llamado desde `@PostConstruct` no abre transacción?

**⏱️ 30 segundos.** Porque `@PostConstruct` se ejecuta sobre el objeto interno, cuando el
proxy ya existe pero no está en medio de esa llamada: es una self-invocation.

**🗣️ 2 minutos.** El orden del arranque es construir → inyectar → crear el proxy →
`@PostConstruct`. El callback corre sobre la instancia que el proxy envuelve, así que
cualquier llamada a un método propio va directa al objeto. Si necesitas trabajo
transaccional al arrancar, el sitio correcto es un `ApplicationRunner` o un listener de
`ApplicationReadyEvent`, que ya reciben el bean proxyado desde el contenedor.

---

## Capítulo 06 — Arranque de Spring Boot y autoconfiguración

### 06 → 1

> ¿Cómo decide `SpringApplication` si crea un contexto servlet, uno reactivo o ninguno?

**⏱️ 30 segundos.** Por el classpath: si hay `spring-webmvc` crea uno servlet, si solo hay
`spring-webflux` crea uno reactivo, y si no hay ninguno crea un contexto normal de
aplicación de consola.

**🗣️ 2 minutos.** Es el primer paso de `run()` y condiciona todo lo demás, porque de ahí
sale qué autoconfiguraciones aplican y qué servidor embebido arranca. La trampa está en
tener los dos: **gana el servlet**. Es lo que pasa cuando añades `WebClient` a una
aplicación MVC arrastrando `spring-webflux` entero, y luego alguien se sorprende de que la
aplicación no sea reactiva (`13`).

**🔬 El detalle.** Es el **paso 1** de `run()`, y conviene poder recitar la secuencia
entera porque explica todo lo demás: 1 deducir el tipo de aplicación, 2 cargar
`ApplicationContextInitializer` y `ApplicationListener`, 3 preparar el `Environment`, 4
crear el contexto del tipo deducido, 5 registrar bean definitions, 6 `refresh()`, 7
arrancar el servidor embebido, 8 ejecutar los runners y 9 `ApplicationReadyEvent`. Del
paso 1 depende qué autoconfiguraciones aplican, porque muchas están condicionadas con
`@ConditionalOnWebApplication`.

---

### 06 → 2

> ¿Por qué el `Environment` se prepara antes de registrar los beans, y qué permite eso?

**⏱️ 30 segundos.** Porque las condiciones que deciden qué beans se registran leen
propiedades y profiles. Si la configuración no estuviera resuelta, no habría nada que
evaluar.

**🗣️ 2 minutos.** El orden es: preparar `Environment` → crear el contexto → registrar bean
definitions → `refresh()`. Gracias a eso `@ConditionalOnProperty` y `@Profile` pueden
decidir, y por eso una propiedad puede hacer que un bean exista o no. También explica por
qué cambiar una propiedad en caliente no activa un bean: la decisión ya se tomó ([`02`](02-contenedor-ioc-y-ciclo-de-vida.md)).

---

### 06 → 3

> ¿En qué tres anotaciones se descompone `@SpringBootApplication`, y para qué sirve la
> que nadie nombra?

**⏱️ 30 segundos.** `@SpringBootConfiguration`, `@EnableAutoConfiguration` y
`@ComponentScan`. La que nadie nombra es la primera: marca la clase como "la
configuración principal", y es lo que los tests buscan para localizarla.

**🗣️ 2 minutos.** `@SpringBootTest` no necesita que le digas qué configuración cargar
porque sube por el árbol de paquetes buscando una `@SpringBootConfiguration` (`24`). De
ahí la regla de que solo haya una en el subárbol: con dos, los tests fallan con un mensaje
que habla de configuración ambigua y que no menciona la causa real.

---

### 06 → 4

> ¿Dónde declara un jar sus clases de autoconfiguración en Boot 3.5, y dónde se declaraban
> antes?

**⏱️ 30 segundos.** En
`META-INF/spring/org.springframework.boot.autoconfigure.AutoConfiguration.imports`, una
clase por línea. Antes, en `META-INF/spring.factories`.

**🗣️ 2 minutos.** El formato viejo quedó obsoleto en Boot 2.7 y **se eliminó en 3.0**.
Importa porque el fallo es silencioso: si sigues un tutorial de 2021 para escribir un
starter propio, el fichero se ignora, la autoconfiguración no se carga y no hay ningún
error que lo explique. Es uno de los puntos de la migración 2.7 → 3.x que más tiempo hace
perder (`A04`).

**🔬 El detalle.** El detalle del formato: una clase por línea, con el **nombre
completamente cualificado**, y `@EnableAutoConfiguration` lee todos esos ficheros del
classpath. El catálogo viejo vivía en `META-INF/spring.factories` bajo la clave
`EnableAutoConfiguration`. Ese mismo fichero `AutoConfiguration.imports` es también donde
se declara un `FailureAnalyzer` propio, y por la misma razón: no se escanea, se carga por
catálogo.

---

### 06 → 5

> Explica por qué "tu bean siempre gana" y qué anotación concreta lo hace posible.

**⏱️ 30 segundos.** Porque las autoconfiguraciones declaran sus beans con
`@ConditionalOnMissingBean` y se procesan **después** de tu configuración: si tú ya
registraste uno de ese tipo, la condición falla.

**🗣️ 2 minutos.** Es el contrato central de Boot: la autoconfiguración se ofrece "por si
acaso" y se aparta sin ruido. De ahí la consecuencia práctica más útil del capítulo: para
cambiar cómo se configura algo **no hay que excluir nada**, basta con declarar tu propio
bean. Excluir es para cuando quieres que no exista nada, que es un caso mucho más raro.

**🔬 El detalle.** La condición concreta es `@ConditionalOnMissingBean`, y funciona **por
tipo**: en cuanto existe un bean asignable a ese tipo, la definición de Boot no se
registra. Lo que lo hace fiable es el orden: tus propias `@Configuration` se procesan
**antes** que las autoconfiguraciones, y estas se ordenan entre sí con
`@AutoConfiguration(after = …, before = …)`. Ese es también el motivo de que
`@ConditionalOnBean` sea seguro dentro de Boot —controla el orden— y frágil en tu código.

---

### 06 → 6

> ¿Por qué `@ConditionalOnBean` es frágil en tu propio código y no en el de Boot?

**⏱️ 30 segundos.** Porque depende del orden de registro, y Boot controla ese orden entre
sus autoconfiguraciones con `@AutoConfiguration(after/before)`; tú no lo controlas sobre
las tuyas.

**🗣️ 2 minutos.** `@ConditionalOnBean` se evalúa contra lo que ya está registrado en ese
momento. En una `@Configuration` tuya, que se procesa antes que las autoconfiguraciones,
el bean que esperas puede no existir todavía, y la condición falla sin avisar. La regla
práctica: en tu código, condiciona sobre clase (`@ConditionalOnClass`) o sobre propiedad
(`@ConditionalOnProperty`), que no dependen del orden.

---

### 06 → 7

> "`--debug` sube el nivel de log": corrige la frase. ¿Qué imprime exactamente, y qué
> bloque de esa salida usarías para saber por qué **no** tienes un bean que esperabas?

**⏱️ 30 segundos.** `--debug` **no** sube el nivel de log global —eso es
`logging.level.root=DEBUG`—: activa el `ConditionEvaluationReport`. Para un bean ausente
se mira el bloque **`Negative matches`**, que dice qué condición falló.

**🗣️ 2 minutos.** Confundir las dos cosas hace perder media hora leyendo trazas que no
contestan la pregunta. El informe tiene tres bloques: `Positive matches` (qué se aplicó y
por qué), `Negative matches` (qué no se aplicó y **qué condición concreta falló**) y
`Exclusions`. El segundo es el más útil, porque la pregunta que te tiene atascado casi
siempre es la negativa.

**🔬 El detalle.** El mismo informe está en caliente en `/actuator/conditions`, en JSON,
que es más cómodo de filtrar con `jq` (`23`).

---

### 06 → 8

> Nombra las tres formas de excluir una autoconfiguración y di por qué excluir suele ser
> la segunda mejor respuesta.

**⏱️ 30 segundos.** `@SpringBootApplication(exclude = …)`, `excludeName` con la cadena, y
la propiedad `spring.autoconfigure.exclude`. Es la segunda mejor porque normalmente lo que
quieres es *cambiar* la configuración, y para eso basta declarar tu bean.

**🗣️ 2 minutos.** La exclusión es para cuando quieres que no exista nada de eso —el caso
clásico es `SecurityAutoConfiguration` en un servicio que se protege por otro medio—. Si
solo quieres otro `DataSource` u otro `ObjectMapper`, decláralo y
`@ConditionalOnMissingBean` se aparta. Además, excluir por propiedad y solo en un profile
crea una diferencia de comportamiento entre entornos que no se ve leyendo el código.

**🔬 El detalle.** La diferencia entre las dos primeras es de verificación: `exclude` toma
la clase y el compilador y el IDE la comprueban; `excludeName` toma el nombre como cadena,
y existe para cuando la clase **no está en tu classpath de compilación**. La tercera, la
propiedad, es la peligrosa: una exclusión activa solo en un profile es una diferencia de
comportamiento entre entornos que no se ve leyendo el código.

---

### 06 → 9

> Escribes una autoconfiguración en una librería interna y no se aplica. ¿Cuáles son las
> dos causas más probables?

**⏱️ 30 segundos.** Que falte la línea en `AutoConfiguration.imports`, o que esté
declarada en `spring.factories`, que ya no se lee.

**🗣️ 2 minutos.** Las dos fallan en silencio, que es lo que las hace caras. La tercera
causa, menos frecuente, es que alguna `@ConditionalOn*` no se cumpla — y eso sí se
diagnostica: arranca con `--debug` y búscala en `Negative matches`. Lo que **no** es la
causa es el component scan: una autoconfiguración se carga por el catálogo, no por
escaneo, y precisamente por eso puede vivir en un jar fuera del paquete base del
consumidor.

**🔬 El detalle.** El detalle que cierra el diagnóstico: una clase de autoconfiguración
**no lleva `@Component` y no se escanea**. Se carga por el catálogo, y eso es precisamente
lo que le permite vivir en un jar fuera del paquete base del consumidor ([`02`
§7](02-contenedor-ioc-y-ciclo-de-vida.md#7--component-scan-el-paquete-base)). En Boot 3
además se anota con `@AutoConfiguration` en lugar de `@Configuration`, que es lo que
aporta la semántica de orden `after` / `before`.

---

### 06 → 10

> ¿Qué diferencia hay entre `ApplicationRunner` y `CommandLineRunner`, y qué riesgo tiene
> un runner lento?

**⏱️ 30 segundos.** `ApplicationRunner` recibe los argumentos ya parseados;
`CommandLineRunner` recibe el `String[]` crudo. Un runner lento bloquea el arranque.

**🗣️ 2 minutos.** Los dos se ejecutan después de refrescar el contexto y arrancar el
servidor, pero **antes** de `ApplicationReadyEvent`, y son bloqueantes. Un runner que
tarda treinta segundos hace que el readiness probe de tu orquestador dé por muerto el pod
y lo reinicie, en un bucle que parece un fallo de la aplicación. El trabajo largo de
arranque va en segundo plano o en un job aparte, no en un runner.

**🔬 El detalle.** El matiz de operación está en el orden de `run()`: el servidor embebido
arranca en el paso 7 y los runners corren en el 8, así que **mientras tu runner trabaja el
puerto ya acepta tráfico** y `ApplicationReadyEvent` todavía no se ha publicado.
`ApplicationRunner` recibe un `ApplicationArguments` con `containsOption("seed")` y
`getOptionValues(...)` ya parseados, que es lo que hace innecesario escribir un parser de
`--clave=valor` a mano.

---

### 06 → 11

> ¿Por qué el trabajo transaccional de arranque va en un `ApplicationRunner` y no en un
> `@PostConstruct`?

**⏱️ 30 segundos.** Porque en `@PostConstruct` estás sobre el objeto interno y el proxy no
participa: no hay transacción. En un runner recibes el bean ya proxyado desde el
contenedor.

**🗣️ 2 minutos.** `@PostConstruct` corre en la fase 7 del arranque, sobre la instancia que
el proxy envuelve (`05`), así que cualquier llamada a un método propio anotado es una
self-invocation silenciosa. Un `ApplicationRunner` se ejecuta con el contexto ya
refrescado y recibe sus dependencias inyectadas por el contenedor, es decir, los proxies.
Lo mismo vale para un listener de `ApplicationReadyEvent`.

---

### 06 → 12

> Tu aplicación falla al arrancar con un mensaje que incluye `Action:`. ¿Qué es eso,
> quién lo produce y qué haces si no aparece?

**⏱️ 30 segundos.** Es la salida de un `FailureAnalyzer` de Boot, que traduce fallos
conocidos a una descripción y una acción concreta. Si no aparece, vas al stack trace y
lees la **última** excepción de la cadena de `Caused by`.

**🗣️ 2 minutos.** Boot registra analizadores para los fallos habituales —puerto ocupado,
bean ambiguo, propiedad de configuración inválida— y en esos casos el bloque `Action:`
suele contener la respuesta literal, sin necesidad de mirar nada más. Es la parte que la
gente se salta. Cuando no hay analizador, el orden de lectura es el de `A01`: primera
línea, y después el fondo de la cadena de causas. También puedes escribir el tuyo
implementando `FailureAnalyzer`, que en una librería corporativa es una cortesía enorme.

**🔬 El detalle.** El caso canónico es el puerto ocupado: `Description: Web server failed
to start. Port 8080 was already in use.` seguido de un `Action:` que te dice que pares el
proceso o cambies el puerto. El tuyo se escribe implementando `FailureAnalyzer` y
**declarándolo en `AutoConfiguration.imports`**, no con `@Component`: en el momento en que
se analiza el fallo, el contexto puede no haber llegado a existir.

---

## Capítulo 07 — Configuración externalizada

### 07 → 1

> ¿Qué es el `Environment` y qué pasa cuando dos fuentes definen la misma propiedad?

**⏱️ 30 segundos.** Es una lista ordenada de `PropertySource`. Cuando dos la definen, gana
la primera de la lista y las demás se ignoran: no hay mezcla ni prioridad por
especificidad.

**🗣️ 2 minutos.** Se prepara antes de registrar beans (`06`), y esa resolución "la primera
que la tenga" es lo que hace que un despliegue pueda sobreescribir cualquier valor sin
tocar el artefacto. También es la causa de la pregunta de depuración más frecuente del
framework —*"pero si yo lo puse en el `application.yml`"*—, que se contesta con
`/actuator/env`.

**🔬 El detalle.** Las fuentes tienen nombre propio y son inspeccionables, que es lo que
hace el diagnóstico posible: `commandLineArgs`, `systemProperties`, `systemEnvironment` y
`applicationConfig: [classpath:/application.yml]`. Cuando alguien pide `server.port` se
recorre esa lista de arriba abajo y gana la primera que la tenga: no hay mezcla, ni
prioridad por especificidad, ni aviso de que otra fuente también la definía.

---

### 07 → 2

> Ordena de mayor a menor prioridad: `application.yml` dentro del jar, variable de
> entorno, argumento de línea de comandos, propiedad de sistema `-D`,
> `application-prod.yml` fuera del jar.

**⏱️ 30 segundos.** Argumento de línea de comandos → propiedad de sistema `-D` → variable
de entorno → `application-prod.yml` fuera del jar → `application.yml` dentro del jar.

**🗣️ 2 minutos.** Dos cosas se fallan constantemente. La primera es el orden entre `-D` y
las variables de entorno: **las propiedades de sistema de la JVM ganan**. La segunda es
que lo de fuera del jar gana a lo de dentro, y que dentro de cada grupo lo específico de
profile gana a lo genérico — que es justo lo que permite que la imagen traiga defaults
sensatos y el despliegue los ajuste montando un fichero al lado.

**🔬 El detalle.** Por encima de la línea de comandos todavía quedan dos fuentes, y
explican una confusión frecuente: la configuración de Devtools y, sobre todo,
`@TestPropertySource` y el atributo `properties` de `@SpringBootTest` (`24`) — por eso un
test puede fijar cualquier valor sin que nada de lo anterior lo pise. Entre la línea de
comandos y `-D` se cuela `SPRING_APPLICATION_JSON`, y por debajo de todo lo listado están
`@PropertySource` y los defaults de `SpringApplication.setDefaultProperties`, que es donde
las librerías ponen los suyos.

---

### 07 → 3

> ¿Por qué el orden de precedencia es lo que permite desplegar el mismo artefacto en
> todos los entornos?

**⏱️ 30 segundos.** Porque el jar trae defaults en su fuente de menor prioridad, y cada
entorno los sobreescribe desde fuera sin reconstruir nada.

**🗣️ 2 minutos.** Si la configuración de producción viviera dentro del artefacto, habría
que construir un jar por entorno, y entonces lo que probaste no es lo que corre. Con
precedencia externa, el mismo binario recorre toda la tubería y solo cambia el contexto
que lo rodea. El corolario operativo es que en un incidente puedes sobreescribir cualquier
valor con un argumento de línea de comandos, que gana a todo.

---

### 07 → 4

> Escribes `enabled: on` en un YAML y esperabas la cadena `"on"`. ¿Qué recibes y por qué?

**⏱️ 30 segundos.** Recibes el booleano `true`. En YAML 1.1 —el que usa SnakeYAML—
`on`/`off`/`yes`/`no`/`y`/`n` son literales booleanos.

**🗣️ 2 minutos.** La familia de trampas es más amplia: `NO` también es `false`, `1.10` es
un número decimal que pierde el cero, y un valor que empieza por `*` o `&` rompe el
parseo porque son anclas de YAML. La solución siempre es la misma —comillas— y la regla
práctica es entrecomillar cualquier valor que no sea evidentemente un número o un
booleano.

**🔬 El detalle.** La causa exacta es que SnakeYAML implementa **YAML 1.1**, donde esos
literales son booleanos; en YAML 1.2 solo lo son `true` y `false`. La familia completa de
trampas de esa versión: `NO` es `false` —muerde al escribir el código de país de Noruega—,
`1.10` es un número decimal y se queda en `1.1`, y `*` o `&` al principio de un valor
inician una referencia de anclaje y rompen el parseo. Para una sola clave —un `override`
en un despliegue— es más seguro `.properties`, que no tiene indentación que romper.

---

### 07 → 5

> Un error de indentación en `application.yml` no rompe el arranque. ¿Qué ocurre
> entonces, y por qué es peor?

**⏱️ 30 segundos.** Se crea **otra propiedad**, con otra ruta. La que esperabas no existe y
coge su valor por defecto, en silencio.

**🗣️ 2 minutos.** Es peor que un fallo porque no hay señal: la aplicación arranca y se
comporta distinto. Un timeout que creías en 2 segundos corre con el default, o una
funcionalidad que creías activada no lo está. Las dos defensas son
`@ConfigurationProperties` con `@Validated` —que convierte el valor ausente en un fallo de
arranque— y auditar con `/actuator/configprops` lo que realmente se enlazó.

---

### 07 → 6

> ¿Qué es el relaxed binding y por qué **no** aplica a `@Value`?

**⏱️ 30 segundos.** Es que `read-timeout`, `readTimeout`, `read_timeout` y
`READ_TIMEOUT` se consideren la misma propiedad. No aplica a `@Value` porque `@Value`
resuelve el placeholder literal contra el `Environment`.

**🗣️ 2 minutos.** El relaxed binding vive en el mecanismo de enlace de
`@ConfigurationProperties`, que normaliza el nombre antes de buscarlo. `@Value` no pasa
por ahí: busca exactamente la cadena que escribiste. El síntoma clásico es un
`@Value("${inv.supplier.readTimeout}")` que falla o coge el default porque en el YAML está
escrito con guion. Es una de las razones prácticas para preferir
`@ConfigurationProperties`.

---

### 07 → 7

> ¿Cómo se escribe `inv.supplier.read-timeout` como variable de entorno?

**⏱️ 30 segundos.** `INV_SUPPLIER_READTIMEOUT`.

**🗣️ 2 minutos.** Los puntos pasan a guion bajo, los guiones desaparecen y todo va en
mayúsculas. La restricción no es de Spring: es lo único portable entre shells y sistemas
de orquestación. Por eso el relaxed binding existe — sin él, la configuración por variables
de entorno sería imposible de expresar.

---

### 07 → 8

> Da tres ventajas concretas de `@ConfigurationProperties` sobre `@Value`, y la única
> cosa que `@Value` hace y el otro no.

**⏱️ 30 segundos.** Tipado con validación que falla al arrancar, relaxed binding y
metadatos para el autocompletado del IDE. `@Value` en cambio admite SpEL (`#{…}`).

**🗣️ 2 minutos.** Añade además la agrupación: un objeto por prefijo, inmutable si lo
declaras como `record`, que se inyecta entero en vez de repartir cadenas por el código. El
veredicto del curso es `@Value` para un valor aislado o cuando necesitas SpEL, y
`@ConfigurationProperties` para todo lo demás; tres `@Value` en la misma clase ya son
señal de que había un grupo.

**🔬 El detalle.** Lo concreto de cada ventaja: un `record` con un único constructor enlaza
por constructor sin anotaciones extra y queda inmutable; `Duration` se enlaza desde `2s`,
`500ms` o `PT2S`, y `DataSize` desde `10MB`; y los metadatos los genera
`spring-boot-configuration-processor`, una dependencia opcional de una línea en el
`pom.xml`. Se registra con `@EnableConfigurationProperties(SupplierProperties.class)` o
con `@ConfigurationPropertiesScan` en la clase de arranque.

---

### 07 → 9

> ¿Qué consigues añadiendo `@Validated` a una clase de propiedades, y en qué momento se
> nota?

**⏱️ 30 segundos.** Que Bean Validation se aplique al objeto enlazado y que **el arranque
falle** si algo no cumple, con un mensaje que nombra la propiedad y la restricción.

**🗣️ 2 minutos.** Se nota en el despliegue, que es exactamente donde quieres notarlo: es
mejor no arrancar que arrancar con un timeout en cero o una URL vacía. Sin validación,
esos valores producen un fallo mucho más tarde, más lejos de la causa y normalmente en
producción. Es la contramedida más barata contra el error de indentación de la pregunta 5.

---

### 07 → 10

> ¿Qué diferencia hay entre `spring.profiles.active` y `spring.config.activate.on-profile`?

**⏱️ 30 segundos.** La primera **activa** profiles. La segunda **condiciona** un documento
de configuración a que cierto profile esté activo.

**🗣️ 2 minutos.** `spring.profiles.active=local` se pasa por entorno o por línea de
comandos y dice qué profiles corren. `spring.config.activate.on-profile: local` se escribe
dentro de un documento YAML —normalmente después de un `---`— y hace que ese bloque solo
se aplique con ese profile. La forma antigua de lo segundo era `spring.profiles`, obsoleta
desde Boot 2.4; verla en un proyecto es señal de configuración heredada.

**🔬 El detalle.** Tres detalles de la parte que activa. Los profiles se acumulan separados
por coma (`local,debug`), la variable de entorno equivalente es `SPRING_PROFILES_ACTIVE`,
y `spring.profiles.group.prod=metrics,audit` define un grupo para no tener que enumerarlos
en cada despliegue. Del lado que condiciona, el documento suele ir después de un `---`
dentro del mismo fichero: para dos o tres claves eso se lee mejor que un
`application-local.yml` aparte.

---

### 07 → 11

> ¿Por qué `@Profile("!prod")` sobre un bean de seguridad es peligroso, y cuál es la
> forma segura de expresar lo mismo?

**⏱️ 30 segundos.** Porque se activa por **ausencia** del profile: basta con arrancar sin
`prod` para que el bean inseguro entre. La forma segura es activarlo solo con un profile
explícito, tipo `@Profile("insecure-local")`.

**🗣️ 2 minutos.** El fallo no es teórico: un despliegue mal parametrizado, un pod que no
recibió la variable o un test de carga contra el entorno real bastan para que la
aplicación arranque con la autenticación relajada y sin que nada chille. La regla general
es que **lo peligroso nunca se activa por defecto**: exige una afirmación explícita, no la
ausencia de una negación.

**🔬 El detalle.** El mecanismo explica por qué no hay red de seguridad: `@Profile` es un
`@Conditional` evaluado **una sola vez**, al registrar las bean definitions
([`02`](02-contenedor-ioc-y-ciclo-de-vida.md)), así que cuando alguien nota que el bean
inseguro está vivo ya no hay forma de apagarlo sin reiniciar. Y la única prueba que lo
delata antes de que pase es mirar el informe de condiciones o `/actuator/beans` del
entorno real, que nadie mira. De ahí la regla general: lo peligroso exige una afirmación
explícita, nunca la ausencia de una negación.

---

### 07 → 12

> ¿Qué es un config tree y qué problema resuelve?

**⏱️ 30 segundos.** Es un directorio donde cada fichero es una propiedad y su contenido es
el valor. Resuelve el consumo de secretos montados como ficheros.

**🗣️ 2 minutos.** Se declara con `spring.config.import: configtree:/run/secrets/`, y el
fichero `/run/secrets/inv.supplier.token` se convierte en la propiedad
`inv.supplier.token`. Es la forma en que Kubernetes, Docker Swarm y la mayoría de los
gestores de secretos entregan material sensible, y evita tanto ponerlo en el `yml` como
pasarlo por variables de entorno, que son visibles en un `ps` y se filtran a los logs de
crash con facilidad.

**🔬 El detalle.** Se declara bajo `spring.config.import`, que admite varias entradas y
respeta la misma semántica de precedencia que el resto: `configtree:/run/secrets/` para el
directorio y `optional:file:./config/local.yml` para un fichero que puede no existir — sin
el prefijo `optional:`, la ausencia rompe el arranque. El nombre del fichero es la clave
**completa**, con sus puntos: `/run/secrets/inv.supplier.token` es la propiedad
`inv.supplier.token`, y su contenido es el valor.

---

### 07 → 13

> Una propiedad tiene un valor que no esperabas. ¿Qué endpoint consultas y qué campo
> concreto te da la respuesta?

**⏱️ 30 segundos.** `/actuator/env/<propiedad>`, y el campo `property.source`, que dice
qué fuente ganó.

**🗣️ 2 minutos.** La respuesta trae además `propertySources`, con todas las fuentes que
tenían esa clave en orden de precedencia, así que ves también el valor que perdió — que
suele ser el que tú escribiste. Para revisar un bloque entero enlazado a un
`@ConfigurationProperties` es más cómodo `/actuator/configprops`. Los valores sensibles
salen enmascarados, lo que no es garantía suficiente: por eso `env` no se expone abierto
(`23`).

---

### 07 → 14

> ¿Por qué un secreto no debe vivir en `application.yml`, ni siquiera cifrado con una
> clave del mismo repositorio?

**⏱️ 30 segundos.** Porque el fichero se versiona, se copia en los logs de build y acaba
dentro de la imagen; y si la clave de descifrado viaja al lado, el cifrado no añade nada.

**🗣️ 2 minutos.** Cifrar con una clave que está en el mismo repositorio solo cambia el
número de pasos que necesita quien tenga acceso al repositorio, que son exactamente las
mismas personas. Las opciones legítimas son variables de entorno inyectadas por la
plataforma, un config tree montado por el orquestador, o un gestor de secretos consultado
al arrancar. Cuál de las tres se elige es una decisión con trade-offs que se discute en
`21`.

**🔬 El detalle.** Las tres opciones legítimas se eligen por sus costuras, no por gusto.
Las variables de entorno son visibles en un `ps` y se filtran a los logs de crash con
facilidad. El config tree las evita porque el secreto es un fichero con sus permisos, y es
lo que montan Kubernetes y Docker Swarm. Y el gestor de secretos consultado al arrancar
añade el caso límite que distingue: el valor se leyó una vez, así que una rotación
posterior no llega al proceso hasta que alguien lo reinicia o lo refresca a propósito.
Cuál de las tres se usa se justifica en `21`.

---

## Capítulo 08 — El modelo de ejecución web: servlet, hilos y contexto

### 08 → 1

> Dibuja o describe el camino de un request desde el socket hasta tu `@RestController`,
> nombrando las cuatro capas por las que pasa.

**⏱️ 30 segundos.** Socket de Tomcat → cadena de filtros → `DispatcherServlet` →
interceptores → tu controller. La respuesta vuelve por el mismo camino y el hilo regresa
al pool.

**🗣️ 2 minutos.** Tomcat acepta la conexión y toma un hilo del pool. Antes del
`DispatcherServlet` corre la cadena de `Filter`, donde vive toda Spring Security. Después
el `DispatcherServlet` actúa de Front Controller: resuelve qué handler atiende la URL,
ejecuta los `HandlerInterceptor`, invoca tu método y, si algo lanza, pasa por los
`HandlerExceptionResolver` que llevan a tu `@ControllerAdvice`. Las dos preguntas útiles
sobre ese dibujo son en qué hilo corre cada caja y qué pasa si cada una lanza una
excepción.

**🔬 El detalle.** Los nombres propios de cada caja, que es lo que distingue la respuesta:
en la cadena de filtros, toda Spring Security entra como **un** filtro, el
`FilterChainProxy`, insertado por un `DelegatingFilterProxy` que permite que un filtro sea
un bean del contenedor. El `DispatcherServlet` es el único servlet que registra Boot —con
el nombre `dispatcherServlet` y mapeado a `/`— y lo puedes ver en `/actuator/mappings`. Y
`server.servlet.context-path` cuelga todo de un prefijo que es transparente para tus
`@GetMapping`, y que se olvida constantemente al construir URLs absolutas a mano.

---

### 08 → 2

> ¿Cuántas instancias de tu `@RestController` hay atendiendo a 200 peticiones
> simultáneas, y qué consecuencia tiene para tu código?

**⏱️ 30 segundos.** Una. Lo que varía por petición es el hilo, no el objeto, así que
cualquier campo mutable es una condición de carrera.

**🗣️ 2 minutos.** El controller, los servicios y los repositorios son singletons por
contexto (`04`), y doscientos hilos los atraviesan a la vez. De ahí la regla del curso:
los campos de un bean son sus colaboradores, `final`, fijados en el constructor; todo lo
que cambia por request viaja en parámetros y variables locales. El fallo de romper esa
regla no lanza excepción, no aparece en los tests —que corren una petición por vez— y se
manifiesta bajo carga como datos atribuidos a la petición equivocada.

---

### 08 → 3

> ¿Qué significa exactamente `server.tomcat.threads.max=200`, y por qué no es una medida
> de throughput?

**⏱️ 30 segundos.** Es el número de peticiones que se atienden **simultáneamente**. El
throughput depende además de cuánto dura cada una.

**🗣️ 2 minutos.** Con respuestas de 50 ms, 200 hilos dan del orden de miles de peticiones
por segundo; con respuestas de 5 segundos, dan 40. Por eso subir el número casi nunca es
la respuesta: si los hilos se acumulan es porque algo aguas abajo es lento, y más hilos
solo alargan la cola de esa lentitud, consumiendo más memoria y más cambios de contexto.

**🔬 El detalle.** La cuenta que hay que saber hacer en voz alta: throughput ≈ *hilos ÷
latencia*. Con 200 hilos y respuestas de 50 ms salen del orden de 4 000 req/s; con
respuestas de 5 s, 40 req/s exactos. El acompañante de `threads.max` es
`threads.min-spare`, 10 por defecto, que es cuántos se mantienen creados en reposo. Y
subir `max` cuesta memoria y cambios de contexto por cada hilo añadido, así que alarga la
cola de la lentitud en lugar de quitarla.

---

### 08 → 4

> ¿Qué ocurre cuando los 200 hilos están ocupados y también se llena `accept-count`, y en
> qué se diferencia del síntoma anterior?

**⏱️ 30 segundos.** Mientras hay sitio en `accept-count`, la petición espera en la cola y
el cliente ve latencia. Cuando esa cola también se llena, el sistema operativo rechaza la
conexión y el cliente ve un error de conexión, no una respuesta HTTP.

**🗣️ 2 minutos.** La diferencia importa al diagnosticar: en el primer caso tus métricas de
servidor registran peticiones lentas; en el segundo, el error ni siquiera aparece en tus
logs, porque nunca hubo request. Si el cliente reporta "connection refused" y tú no ves
nada, mira la saturación del pool antes que la aplicación.

---

### 08 → 5

> ¿Cuánta memoria reserva aproximadamente un hilo de plataforma, y por qué eso pone un
> techo a la concurrencia?

**⏱️ 30 segundos.** Del orden de 1 MB de pila. Con 200 hilos son unos 200 MB y un techo
duro de 200 operaciones concurrentes.

**🗣️ 2 minutos.** Lo caro no es solo la memoria: un hilo bloqueado esperando una respuesta
HTTP o una consulta SQL **no hace nada y no se puede reutilizar**. Ese techo —y no la
CPU— es lo que tumba servicios que llaman a un proveedor lento, y es exactamente el
problema que atacan WebFlux, sin bloquear, y los virtual threads, haciendo que bloquear
sea barato ([`12`](12-reactivo-bloqueante-y-virtual-threads.md)).

---

### 08 → 6

> Nombra tres diferencias entre un `Filter` y un `HandlerInterceptor`.

**⏱️ 30 segundos.** El filtro es de la API de Servlet y corre antes del
`DispatcherServlet`; no sabe qué handler atenderá la petición; y sus excepciones no pasan
por el manejo de errores de MVC.

**🗣️ 2 minutos.** El interceptor, en cambio, es de Spring, corre con el handler ya
resuelto —así que puede tomar decisiones según el método concreto— y vive dentro del
`DispatcherServlet`, de modo que lo alcanza el `@ControllerAdvice`. A cambio, un filtro sí
puede envolver el request y la response para modificar el cuerpo, y un interceptor no. La
regla práctica: correlación, seguridad, CORS y compresión son filtros; métricas por
handler y auditoría con el método a la vista son interceptores.

**🔬 El detalle.** Hay una cuarta diferencia que decide diseños: un `Filter` puede
**envolver** el request y la response —con `ContentCachingRequestWrapper` y compañía— y un
interceptor no. Y una trampa de registro: `@Component` registra el filtro pero **no fija
su posición**; para eso está `FilterRegistrationBean`, con `setOrder(...)` —menor corre
primero— y `addUrlPatterns(...)`. Si tu filtro de correlación queda después de Spring
Security, los logs de un 401 salen sin `requestId`, que es justo cuando hace falta.

---

### 08 → 7

> Tu `@ControllerAdvice` no atrapa una excepción que ves en el log. ¿Cuál es la primera
> hipótesis y por qué?

**⏱️ 30 segundos.** Que se lanzó en un filtro, fuera del `DispatcherServlet`, donde el
`@ExceptionHandler` no llega.

**🗣️ 2 minutos.** El manejo de excepciones de MVC vive dentro del `DispatcherServlet`; una
excepción lanzada antes sube al contenedor de servlets, que responde con su propia página
de error —el 500 de Tomcat o el `/error` de Boot— sin tu formato. Eso explica sin misterio
por qué un 401 de Spring Security no se parece a tus otros errores: lo produce un
`AuthenticationEntryPoint` dentro de la cadena de filtros, mucho antes de que exista un
controller (`20`).

**🔬 El detalle.** La frontera exacta es el `DispatcherServlet`, y por eso el mismo error
tiene dos desenlaces opuestos: lo que lanza un `HandlerInterceptor` **sí** pasa por los
`HandlerExceptionResolver` y llega a tu `@ControllerAdvice`, porque corre dentro; lo que
lanza un `Filter` no, porque corre fuera. El síntoma es que la respuesta no trae tu
`ProblemDetail`: viene del contenedor de servlets o del `/error` de Boot. Antes de acusar
al `@ControllerAdvice`, mira dónde nació la excepción.

---

### 08 → 8

> ¿Qué garantiza `OncePerRequestFilter` que un `Filter` crudo no garantiza, y en qué
> situación se nota?

**⏱️ 30 segundos.** Una sola ejecución por petición. Se nota cuando hay `forward`,
`include` o despacho asíncrono, donde un filtro crudo puede ejecutarse varias veces.

**🗣️ 2 minutos.** El síntoma es silencioso y engañoso: logs duplicados, un contador de
métricas que cuenta de más, o una cabecera añadida dos veces. Como el reenvío interno lo
provocan cosas que tú no escribiste —el `/error` de Boot, por ejemplo—, cuesta relacionar
la causa con el efecto. No hay casi motivos para no extender `OncePerRequestFilter`.

---

### 08 → 9

> Un filtro loguea el cuerpo del request y el controller empieza a responder
> `Required request body is missing`. Explica la causa y la corrección.

**⏱️ 30 segundos.** El cuerpo es un `InputStream` de un solo uso: el filtro lo consumió y
al `HttpMessageConverter` no le queda nada. Se corrige envolviendo el request en un
`ContentCachingRequestWrapper`.

**🗣️ 2 minutos.** Hay que pasar **el wrapper** a `chain.doFilter(...)`, no el request
original, y leer el contenido **después** de la llamada: antes, el array está vacío porque
nadie ha consumido el stream todavía. Por eso el log va en el `finally`. Y tiene un costo
⏱️: duplica el payload en memoria por cada petición en vuelo, así que en cargas grandes se
limita por tamaño o se activa solo en un profile de diagnóstico.

**🔬 El detalle.** El caso límite que se descubre tarde: el wrapper **cachea lo que se
consume**, no lo que llega. Si la petición muere aguas arriba del `HttpMessageConverter`
—un 401 de Spring Security, por ejemplo— nadie leyó el stream, `getContentAsByteArray()`
devuelve un array vacío y tu log de diagnóstico no ve nada justo en el caso que querías
diagnosticar. Por eso la posición del filtro en la cadena importa tanto como el wrapper.

---

### 08 → 10

> ¿Por qué el `MDC.remove()` va en un `finally` y qué pasa exactamente si falta?

**⏱️ 30 segundos.** Porque el hilo se reutiliza. Sin la limpieza, la siguiente petición
atendida por ese hilo hereda el valor de la anterior.

**🗣️ 2 minutos.** El resultado son logs que atribuyen operaciones a la petición
equivocada, que en un entorno auditado es un problema serio y no un detalle cosmético. El
`finally` importa especialmente porque la limpieza tiene que ocurrir también cuando la
cadena lanza una excepción, que es justo cuando más falta hace la correlación. Es el mismo
bug que el campo mutable en un singleton, con otra cara: estado que sobrevive más de lo
que debía.

**🔬 El detalle.** Con virtual threads el problema cambia de forma pero no desaparece: cada
tarea estrena su propio hilo y no se reutiliza, así que la **contaminación** entre
peticiones deja de ocurrir, mientras que la **propagación** hacia otro pool sigue
exactamente igual de rota (`18`). Y en WebFlux no hay `ThreadLocal` que valga desde el
principio, porque una misma petición cruza varios hilos ([`11`](11-webflux-y-reactor.md)).

---

### 08 → 11

> Nombra tres cosas que Spring guarda en un `ThreadLocal` y qué le pasa a cada una
> dentro de un método `@Async`.

**⏱️ 30 segundos.** El `SecurityContext`, el request actual del `RequestContextHolder` y
el MDC con el `traceId`. Dentro de un `@Async` ninguno está: el hilo del executor los
estrena vacíos.

**🗣️ 2 minutos.** A esa lista se añade el `TransactionSynchronizationManager`, que guarda
la conexión y la transacción activas — y de ahí sale que una transacción no cruza a un
hilo asíncrono (`16`). Los síntomas típicos son una `AccessDeniedException` dentro de un
método que funcionaba en el controller, logs huérfanos sin correlación, y beans de scope
`request` que no se pueden resolver (`04`). La solución es propagar el contexto
explícitamente al entregar la tarea al executor (`18`).

---

### 08 → 12

> ¿Qué problema de arquitectura introduce el uso de sesión HTTP, y cuáles son las dos
> salidas?

**⏱️ 30 segundos.** Pone estado en la memoria de una instancia concreta, lo que rompe el
escalado horizontal. Las salidas son sticky sessions o externalizar la sesión.

**🗣️ 2 minutos.** Si el usuario cae en otra réplica, su sesión no está ahí. Atarlo a una
instancia complica los despliegues y el reequilibrado, y convierte el reinicio de un nodo
en la pérdida de las sesiones que atendía. Externalizarla —Spring Session sobre Redis— lo
resuelve a cambio de una dependencia más en el camino crítico. La tercera vía, y la que
usa el curso, es no tener sesión: en una API con Bearer token cada petición trae su
identidad y el servidor no recuerda nada.

**🔬 El detalle.** La cuenta que convierte el argumento estético en uno operativo: la
memoria retenida es *(sesiones vivas) × (tamaño del bean)*, y no se libera cuando el
usuario se va sino cuando expira `server.servlet.session.timeout`, **30 minutos** por
defecto. Diez mil sesiones de 20 KB son 200 MB de heap durante media hora, y replicados si
hay más de una réplica ([`04`](04-scopes-de-bean.md)). La tercera vía se escribe con una
línea: `SessionCreationPolicy.STATELESS` en la configuración de Spring Security.

---

### 08 → 13

> ¿Qué es la session fixation y quién la mitiga por ti?

**⏱️ 30 segundos.** Un ataque en el que alguien fija el identificador de sesión antes de
que la víctima se autentique y hereda así la sesión autenticada. Spring Security lo mitiga
por defecto rotando el id al hacer login.

**🗣️ 2 minutos.** El ataque funciona solo si el `JSESSIONID` sobrevive al cambio de
privilegio, así que la defensa es crear una sesión nueva al autenticarse y descartar la
anterior. Que venga activado por defecto es un buen ejemplo de por qué conviene entender
qué te da Spring Security antes de desactivar cosas "porque estorban" (`20`).

---

### 08 → 14

> ¿Para qué sirve devolver un `DeferredResult` desde un controller, y por qué los virtual
> threads lo vuelven casi innecesario?

**⏱️ 30 segundos.** Para devolver el hilo del contenedor al pool y completar la respuesta
más tarde desde otro hilo. Con virtual threads, bloquear deja de ser caro y la
complejidad ya no compensa.

**🗣️ 2 minutos.** `Callable`, `DeferredResult` y `SseEmitter` son la respuesta **dentro**
del modelo servlet al problema del hilo bloqueado: el mismo objetivo que WebFlux, sin
cambiar de stack, a cambio de un código más difícil de leer y de depurar. Los virtual
threads atacan la causa por el otro lado —hacen que tener miles de hilos bloqueados sea
barato—, así que el código vuelve a ser secuencial. La comparación completa está en `12`.

**🔬 El detalle.** Los tres tipos de retorno no son intercambiables: `Callable<T>` ejecuta
tu lógica en un executor y libera el hilo del contenedor mientras tanto;
`DeferredResult<T>` te deja elegir desde qué hilo se completa, y es la base del long
polling; `SseEmitter` y `StreamingResponseBody` envían la respuesta por trozos a lo largo
del tiempo sin retener un hilo por cliente. El despacho asíncrono que provocan es además
uno de los casos en que un `Filter` crudo se ejecuta dos veces, y la razón de extender
`OncePerRequestFilter`.

---

### 08 → 15

> ¿Por qué la migración de `javax` a `jakarta` bloquea proyectos enteros, si para tu
> código son solo imports?

**⏱️ 30 segundos.** Porque **toda librería que toque esas APIs** necesita una versión
compatible, y una sola sin mantener bloquea la migración completa.

**🗣️ 2 minutos.** El cambio no fue técnico sino de marca: Oracle cedió Java EE a la
Eclipse Foundation y el namespace pasó a `jakarta.*`. En tu código lo arregla un
buscar-y-reemplazar. El problema son las dependencias: un cliente de mainframe, una
librería de firma o un conector propietario compilados contra `javax.servlet` no funcionan
bajo Boot 3, y si nadie los mantiene hay que reescribirlos o quedarse. Es la causa número
uno de que un servicio siga en Boot 2.7, y por eso es pregunta frecuente en banca
(`A04`).

**🔬 El detalle.** Los nombres concretos, que es lo que se busca al migrar:
`javax.servlet.Filter` es hoy `jakarta.servlet.Filter`, y lo mismo con `javax.validation`
y `javax.persistence`. El corte no fue técnico: Oracle cedió Java EE a la Eclipse
Foundation y el namespace cambió por razones de marca. Lo que quedó atrás en el mismo
movimiento —`web.xml`, JSP, los `ServletContextListener`— ya estaba sustituido por el
registro programático y la autoconfiguración.

---

## Capítulo 09 — REST con Spring MVC

### 09 → 1

> Nombra en orden las cinco piezas que atraviesa un request dentro del `DispatcherServlet`.

**⏱️ 30 segundos.** `HandlerMapping` → `HandlerAdapter` → `HandlerMethodArgumentResolver`
→ tu método → `HandlerMethodReturnValueHandler`. Las dos puntas hablan con los
`HttpMessageConverter`: el resolver del body para leer, el return value handler para
escribir.

**🗣️ 2 minutos.** El `HandlerMapping` consulta un índice construido en el arranque con
todas las combinaciones de path, método HTTP, `consumes`, `produces`, `params` y `headers`
que declaraste, y devuelve un `HandlerMethod` (bean + `Method`). El `HandlerAdapter` sabe
cómo invocar ese tipo de handler —existe porque un handler puede ser también una
`RouterFunction`—; con anotaciones siempre es `RequestMappingHandlerAdapter`. Los argument
resolvers son una lista ordenada a la que se le pregunta `supportsParameter(...)` por cada
parámetro. Después corre tu código. Y el return value handler decide qué hacer con lo que
devuelves: serializarlo si hay `@ResponseBody`, o resolver una vista si no.

**🔬 El detalle.** `/actuator/mappings` te enseña el índice del `HandlerMapping` tal como
quedó registrado, con `consumes` y `produces` incluidos. Es la forma más rápida de
descartar que el 404 sea "la ruta no existe" cuando en realidad la condición compuesta
descartó al handler.

---

### 09 → 2

> ¿Qué hace `@ResponseBody` y por qué `@RestController` no es "el que devuelve JSON"?

**⏱️ 30 segundos.** `@ResponseBody` cambia el return value handler: en vez de interpretar
el retorno como nombre de vista, lo manda a los `HttpMessageConverter` para escribirlo en
el cuerpo. `@RestController` es `@Controller` + `@ResponseBody` a nivel de clase.

**🗣️ 2 minutos.** Que salga JSON no lo decide la anotación: lo deciden los converters
registrados y la negociación contra el `Accept` del cliente. Con el starter web hay un
`MappingJackson2HttpMessageConverter`, y por eso el default es JSON; añade
`jackson-dataformat-xml` y el mismo método puede responder XML sin tocar una línea. Sin
`@ResponseBody`, un método que devuelve `String` está devolviendo el **nombre de una
vista**, que va a un `ViewResolver`; si no hay plantilla, obtienes un 404 sobre una URL
que sí mapeaste. Y en un `@RestController` un parámetro `Model` sigue compilando y no
hace absolutamente nada.

---

### 09 → 3

> Explica la diferencia entre 406, 415 y 400 nombrando la excepción concreta de cada uno.

**⏱️ 30 segundos.** 415 es que no sé **leer** tu `Content-Type`
(`HttpMediaTypeNotSupportedException`); 406 es que no sé **escribir** lo que pides en
`Accept` (`HttpMediaTypeNotAcceptableException`); 400 es que el media type estaba bien y
el contenido no (`HttpMessageNotReadableException`).

**🗣️ 2 minutos.** La diferencia importante no es el número, es **dónde** se decide. El 415
y el 406 los decide el `HandlerMapping`: el método declaraba `consumes` o `produces` y la
condición no encajó, así que el handler ni se evaluó y ningún converter llegó a correr. El
400 es posterior: el converter sí se eligió, se ejecutó y falló al parsear. La causa más
frecuente de 415 en la práctica no es mandar `text/plain`, es no mandar `Content-Type` en
absoluto —un `curl -d` sin cabecera envía `application/x-www-form-urlencoded`—.

**🔬 El detalle.** El mismo 400 lo producen también
`MethodArgumentTypeMismatchException` (un `@PathVariable` que no convierte al tipo
declarado) y `MissingServletRequestParameterException` (un `@RequestParam` obligatorio
ausente). El 400 por validación —cuerpo bien formado que incumple reglas— es
`MethodArgumentNotValidException`, y pertenece a [`10`](10-diseno-de-api-validacion-errores-e-hipermedia.md). El cuerpo por defecto de todos
estos errores lo produce el `/error` de Boot y **no** incluye la excepción: para verla,
`logging.level.org.springframework.web=DEBUG`.

---

### 09 → 4

> Tienes `@GetMapping("/{sku}")` y `@GetMapping("/summary")` en el mismo controller: ¿cuál
> atiende `GET /api/items/summary` y por qué?

**⏱️ 30 segundos.** El de `/summary`. Cuando dos patrones encajan gana el más específico:
literal > variable > `*` > `**`, y a igualdad gana el que tenga menos variables.

**🗣️ 2 minutos.** El orden en que están escritos los métodos en la clase no influye; la
decisión la toma el comparador de patrones del `RequestMappingHandlerMapping`. Lo
interesante es el modo de fallo: si alguien borra o renombra `/summary`, la petición pasa
a caer en `/{sku}`, el binding intenta convertir la cadena `"summary"` al tipo del
parámetro y el cliente recibe un **400 por conversión de tipo**, no un 404. Un endpoint
que empieza a devolver 400 después de un refactor de rutas casi siempre es esto.

**🔬 El detalle.** En Boot 3.x el matcher por defecto es `PathPatternParser`, no
`AntPathMatcher`. La diferencia visible es que `**` solo se admite al final del patrón: un
mapeo tipo `/api/**/items` que funcionaba en Boot 2.x hoy revienta el arranque.

---

### 09 → 5

> ¿Cuándo eliges `ResponseEntity` sobre devolver el objeto, y cuándo basta `@ResponseStatus`?

**⏱️ 30 segundos.** `ResponseEntity` en cuanto el método tenga más de un desenlace o
necesite cabeceras. `@ResponseStatus` cuando el código es fijo y no hay cabeceras. Y
devolver el objeto pelado cuando siempre es 200.

**🗣️ 2 minutos.** Devolver el objeto es lo más legible, y esconde una trampa: un
`Optional<T>` vacío devuelto así **no** es un 404, es un 200 con cuerpo vacío. El 404 hay
que escribirlo. `ResponseEntity` es la única de las tres que permite `Location`, `ETag` o
`Cache-Control`, y por eso es la forma natural de un POST que crea: `created(location)`
pone el 201 y la cabecera en un gesto. `@ResponseStatus(HttpStatus.CREATED)` sobre el
método es limpio mientras haya un solo desenlace; en cuanto aparece el segundo, estorba
porque el código ya no depende del método sino de la rama.

**🔬 El detalle.** `@ResponseStatus` también se pone sobre una excepción propia, y es el
mecanismo más barato para traducir un fallo de dominio a un código HTTP. Deja de bastar en
cuanto quieres un cuerpo de error con formato: eso es `@ControllerAdvice` con
`ProblemDetail`, y es de `10`.

---

### 09 → 6

> Da tres razones técnicas para no serializar una entidad de JPA como respuesta HTTP.

**⏱️ 30 segundos.** Acopla el contrato HTTP al esquema de la base, publica campos que nadie
decidió publicar, y arrastra el modelo de carga de JPA dentro del serializador.

**🗣️ 2 minutos.** La primera es de diseño: si la respuesta es la entidad, renombrar una
columna pasa a ser un cambio incompatible para todos tus clientes. La segunda es de
seguridad: un campo nuevo en la tabla aparece en la respuesta sin que nadie lo revise, y en
banca eso es una fuga de datos, no un detalle. La tercera es de runtime: Jackson recorre
los getters, toca una colección `LAZY` fuera de la sesión y obtienes
`LazyInitializationException` — o peor, la carga entera con su N+1, porque el serializador
acaba disparando consultas. Y como remate, dos entidades que se referencian entre sí
producen un `StackOverflowError` con la respuesta ya a medio escribir, que es el fallo más
desagradable de diagnosticar porque el cliente ve un cuerpo truncado.

**🔬 El detalle.** El DTO se escribe como `record` inmutable y Jackson lo deserializa por
el constructor canónico, sin setters ni `@ConstructorProperties`. Son tres líneas, no una
capa: el argumento "es más código" no se sostiene desde Java 16.

---

### 09 → 7

> ¿Por qué se inyecta `UriComponentsBuilder` en vez de concatenar la URL a mano?

**⏱️ 30 segundos.** Porque el inyectado ya trae esquema, host, puerto y `context-path` del
request en curso, y porque `buildAndExpand` escapa los valores.

**🗣️ 2 minutos.** Concatenar a mano falla de dos maneras, y las dos aparecen en producción
y no en local. La primera es el prefijo: si la aplicación se despliega con
`server.servlet.context-path=/inv-api`, tus `@GetMapping` no cambian pero la URL real sí, y
la `Location` que armaste concatenando apunta a una ruta que no existe. La segunda es el
escapado: un identificador con `/`, con espacios o con caracteres reservados produce una
URL inválida que el cliente sigue a ciegas. Un `UriComponentsBuilder` creado con
`newInstance()` no sabe nada del request y tiene el primer problema igual.

---

### 09 → 8

> ¿Por qué solo puede haber un `@RequestBody` por método?

**⏱️ 30 segundos.** Porque el cuerpo de un request es un `InputStream` de un solo uso:
cuando el primer converter lo consume, no queda nada para el segundo.

**🗣️ 2 minutos.** Es exactamente el mismo mecanismo que hace que leer el payload en un
filtro rompa el controller con `HttpMessageNotReadableException: Required request body is
missing` (`08`). El resolver del body —`RequestResponseBodyMethodProcessor`— pide el stream
al `HttpServletRequest` y se lo entrega al converter, que lo lee hasta el final. Si quieres
el cuerpo dos veces, hay que envolver el request con `ContentCachingRequestWrapper` y pagar
el costo de duplicar el payload en memoria por petición en vuelo. Si lo que quieres es
recibir dos objetos, la respuesta correcta es un solo DTO que los contenga, no dos
parámetros.

---

### 09 → 9

> ¿Qué diferencia hay entre implementar `WebMvcConfigurer` y anotar con `@EnableWebMvc`?

**⏱️ 30 segundos.** `WebMvcConfigurer` **añade** a lo que Boot configuró; `@EnableWebMvc`
**apaga** `WebMvcAutoConfiguration` entera y te deja configurando MVC desde cero.

**🗣️ 2 minutos.** En una aplicación Boot, MVC ya está activo por el starter: `@EnableWebMvc`
no lo enciende, lo desconecta de la autoconfiguración. Lo que pierdes es concreto: los
`HttpMessageConverter` que Boot registró con sus defaults de Jackson, el manejo de recursos
estáticos, la configuración del `/error`. Y no avisa de nada: el arranque es verde y lo que
deja de funcionar lo descubres por un endpoint que ahora devuelve otra cosa. La regla
práctica es que `@EnableWebMvc` en un proyecto Boot es casi siempre un error, salvo que
estés reemplazando la configuración a propósito y sepas exactamente qué estás quitando.

**🔬 El detalle.** Dentro de `WebMvcConfigurer` hay la misma distinción en pequeño:
`extendMessageConverters` modifica la lista que Boot construyó,
`configureMessageConverters` la reemplaza. Usa `extend` por defecto.

---

### 09 → 10

> Configuraste CORS con `addCorsMappings` y el navegador sigue rechazando el preflight:
> ¿cuál es la primera hipótesis?

**⏱️ 30 segundos.** Que Spring Security está delante y rechaza el `OPTIONS` **antes** de
que el request llegue al `DispatcherServlet`.

**🗣️ 2 minutos.** `addCorsMappings` configura CORS a nivel de MVC, y MVC vive dentro del
`DispatcherServlet`; la cadena de filtros de Security corre antes (`08` §5). El preflight
`OPTIONS` viaja sin credenciales por definición, así que una cadena que exige
autenticación lo corta con un 401 y el navegador reporta un error de CORS que no tiene nada
que ver con tu configuración de CORS. La corrección es integrar CORS en la cadena de
Security, que es materia de `20`. La segunda hipótesis, si Security no está en juego, es la
combinación `allowedOrigins("*")` con `allowCredentials(true)` — aunque esa falla en el
arranque, y está bien que falle: es justo lo que anula la protección.

---

### 09 → 11

> ¿Qué hace `server.shutdown=graceful` y qué le pasa al pool de hilos durante ese drenaje?

**⏱️ 30 segundos.** Al recibir `SIGTERM`, el conector deja de aceptar conexiones nuevas y el
contexto espera a que terminen las que ya están en vuelo, hasta
`spring.lifecycle.timeout-per-shutdown-phase` (30 s por defecto). Durante ese rato los
hilos y las conexiones del pool siguen ocupados.

**🗣️ 2 minutos.** El default de Boot es `immediate`, y con él los requests en curso se
cortan a media respuesta: el cliente no ve un error HTTP, ve una conexión caída, que es
peor porque no se puede reintentar con criterio. Con `graceful` el apagado dura lo que dure
el request más lento, hasta el techo configurado, y eso tiene un costo que hay que nombrar:
en un rolling update de diez réplicas son hasta medio minuto por réplica con recursos
tomados y capacidad reducida. Por eso el orden correcto es que el endpoint de `readiness`
deje de responder **antes** de que llegue el `SIGTERM`, para que el balanceador retire la
instancia y no le mande tráfico nuevo mientras drena (`23`).

---

### 09 → 12

> `spring.jackson.deserialization.fail-on-unknown-properties` en `true`: ¿qué gana y qué
> rompe el día que el productor añade un campo?

**⏱️ 30 segundos.** Ganas detección temprana de payloads que no esperabas; rompes la
compatibilidad hacia adelante: el día que el cliente añade un campo, tu endpoint empieza a
devolver 400 a peticiones que antes funcionaban.

**🗣️ 2 minutos.** Boot lo deja en `false` a propósito, y es el default correcto para una
API que consume terceros: permite que el otro lado evolucione su contrato sin coordinar un
despliegue contigo. Ponerlo en `true` tiene sentido en un borde controlado donde un campo
desconocido sea de verdad un síntoma —por ejemplo, un endpoint interno cuyo único cliente
es otro equipo tuyo—, y aun así conviene tratarlo como una decisión de contrato y
documentarla, porque el fallo aparece en producción y no en los tests. La misma familia de
decisiones incluye `default-property-inclusion: non_null` (que evita que el cliente
distinga "no vino" de "vino `null`") y `time-zone: UTC` (que impide que la zona de la
máquina se cuele en el contrato).

---

## Capítulo 10 — Diseño de API: validación, errores e hipermedia

### 10 → 1

> ¿Qué diferencia hay entre `@Valid` y `@Validated`, y cuál de las dos admite grupos?

**⏱️ 30 segundos.** `@Valid` es de `jakarta.validation`, va sobre un argumento —típicamente el
`@RequestBody`— o sobre un campo del DTO, y la aplica Spring MVC al resolver el argumento.
`@Validated` es de Spring (`org.springframework.validation.annotation`), va **sobre la clase** y
activa la validación a nivel de método. Los grupos solo los admite `@Validated`.

**🗣️ 2 minutos.** No son dos nombres del mismo mecanismo: son dos mecanismos. Con `@Valid` sobre el
body, quien valida es MVC dentro del `DispatcherServlet`, y cuando falla lanza
`MethodArgumentNotValidException`, que ya sale como 400. Con `@Validated` sobre la clase, quien
valida es `MethodValidationPostProcessor` a través de un **proxy** alrededor del bean —el mismo
mecanismo de `05`— y la excepción es `ConstraintViolationException`, de Jakarta, que sale 500. Su
sitio es un `@Service`: en un controller sobra, porque desde Spring Framework 6.1 MVC valida los
parámetros de método por su cuenta y lanza `HandlerMethodValidationException`, que sale 400. Y por
eso `@Valid` en la clase no compila para ese uso: su `@Target` son argumentos y campos.

**🔬 El detalle.** Los grupos (`@Validated(OnCreate.class)`) permiten que un mismo DTO tenga reglas
distintas al crear y al actualizar. La trampa es que una restricción sin `groups` pertenece al grupo
`Default` y **no** se evalúa cuando pides un grupo concreto: hay que listar los grupos en cada
restricción que deba seguir activa.

---

### 10 → 2

> Pones `@Max(100)` en un `@RequestParam` de un controller anotado con `@Validated` en la clase y la API responde 500. ¿Qué anotación sobra, y por qué el mecanismo es distinto al del `@RequestBody`?

**⏱️ 30 segundos.** Sobra el `@Validated` de la clase. Con él, la validación la hace un proxy AOP y
lanza `ConstraintViolationException`, que sale 500; sin él, la hace MVC y sale 400.

**🗣️ 2 minutos.** La validación del `@RequestBody` la hace el propio MVC al resolver el argumento,
así que basta `@Valid` en la firma. La de parámetros sueltos —`@RequestParam`, `@PathVariable`— la
hace **también MVC** desde Spring Framework 6.1, y cuando falla lanza
`HandlerMethodValidationException`, que `DefaultHandlerExceptionResolver` mapea a 400. El
`@Validated` de clase no añade nada ahí: reactiva el camino de `MethodValidationPostProcessor`, que
envuelve el bean en un proxy (`05`) y sube la excepción de Jakarta, desconocida para MVC. La
reference lo pide explícitamente: para aprovechar la validación integrada hay que **quitar** el
`@Validated` de nivel de clase del controller.

**🔬 El detalle.** Donde `@Validated` sí es obligatoria es fuera del borde web: un `@Service` con
parámetros anotados solo valida si la clase la lleva, y entonces la `ConstraintViolationException`
es la esperada — ahí el 500 no es un bug de configuración, es que nadie tradujo la excepción.

---

### 10 → 3

> Nombra las tres excepciones que puede lanzar una petición inválida según qué falló, y con qué status sale cada una por defecto.

**⏱️ 30 segundos.** `MethodArgumentNotValidException` cuando el body se deserializó pero sus campos
violan restricciones (400); `HandlerMethodValidationException` cuando falla un parámetro de método
del controller (400), que se convierte en `ConstraintViolationException` y 500 si la validación pasó
por un proxy —`@Validated` en la clase—; y `HttpMessageNotReadableException` cuando el JSON está
roto, el tipo no encaja o falta el body (400).

**🗣️ 2 minutos.** Importa porque el `@ControllerAdvice` se escribe contra tipos concretos: si solo
manejas `MethodArgumentNotValidException`, las otras dos salen con el formato por defecto de Boot y
el cliente recibe dos contratos de error distintos del mismo servicio. Hay una cuarta habitual,
`MethodArgumentTypeMismatchException`, cuando mandan `?quantity=abc` sobre un `int`. La forma limpia
de cubrirlas todas de golpe es extender `ResponseEntityExceptionHandler` y activar
`spring.mvc.problemdetails.enabled=true`.

---

### 10 → 4

> Tu API responde **500** a un parámetro de query inválido. ¿Cuál es la causa más probable?

**⏱️ 30 segundos.** Que la validación la esté haciendo un proxy y no MVC, y suba una
`ConstraintViolationException` sin traducir: el manejo por defecto la toma como fallo del servidor.
En un controller, la causa concreta es un `@Validated` a nivel de clase.

**🗣️ 2 minutos.** Desde Spring Framework 6.1, la validación de parámetros de un método de
**controller** la hace MVC y lanza `HandlerMethodValidationException`, que sale como 400 — siempre
que no haya proxy de por medio. Si la clase lleva `@Validated`, gana el camino de AOP y vuelve la
excepción de Jakarta con su 500; la reference pide quitar esa anotación del controller justo por
esto. La otra fuente del mismo 500 es un `@Service` con `@Validated`, donde el proxy sí es
necesario: ahí la corrección no es quitar nada, sino validar en el borde y añadir un
`@ExceptionHandler(ConstraintViolationException.class)` que la traduzca a 400 con `ProblemDetail`.

**🔬 El detalle.** Es un 500 especialmente caro en producción porque dispara alertas y reintentos:
el cliente cree que el servidor falló y repite una petición que nunca va a funcionar.

---

### 10 → 5

> ¿Qué te regala extender `ResponseEntityExceptionHandler`, y qué pasa si además escribes un `@ExceptionHandler` para una excepción que esa clase base ya maneja?

**⏱️ 30 segundos.** Te regala el manejo ya mapeado de la docena de excepciones estándar de Spring
MVC. Si escribes tu propio `@ExceptionHandler` para una de ellas, el tuyo gana y el método de la
clase base deja de ejecutarse — sin ningún aviso.

**🗣️ 2 minutos.** La forma correcta de personalizar una de esas excepciones es **sobrescribir** el
método correspondiente (`handleMethodArgumentNotValid`, `handleHttpMessageNotReadable`…), no añadir
un handler paralelo: así mantienes el resto del contrato y el `ProblemDetail` que la base construye.
El `@ExceptionHandler` propio se reserva para tus excepciones de negocio. Y conviene acotar el
advice con `basePackages`, porque uno sin filtro también se aplica a controllers que no son tuyos,
como los de Actuator.

**🔬 El detalle.** Entre varios handlers gana el más específico por jerarquía de tipos, así que un
`@ExceptionHandler(Exception.class)` como red final no tapa a los concretos; lo que sí tapa es
devolver 200 desde él para "que no truene".

---

### 10 → 6

> Enumera los cinco campos estándar de un `ProblemDetail` y di cuál usa el cliente para enrutar su lógica.

**⏱️ 30 segundos.** `type`, `title`, `status`, `detail` e `instance`. El cliente enruta por **`type`**,
que es un URI que identifica la clase de problema.

**🗣️ 2 minutos.** `title` es legible y estable para un mismo `type`; `detail` describe **esta**
ocurrencia y puede cambiar; `instance` identifica la ocurrencia concreta —Spring la rellena con la
URI del request—. Todo lo demás va en **campos de extensión**, que la RFC 9457 admite y Spring pone
con `setProperty(...)`: el campo que falló, un `traceId`, la lista de violaciones. La respuesta sale
con `Content-Type: application/problem+json`, que es lo que permite a un cliente distinguir un error
sin mirar el status.

**🔬 El detalle.** El error de diseño típico es meter datos variables en `title` —el `sku`, el id—:
rompe la estabilidad por `type` y obliga al cliente a parsear texto, que es justo lo que el estándar
viene a evitar.

---

### 10 → 7

> Tu `@ControllerAdvice` no atrapa el 401 de Spring Security. Explica por qué y qué se configura en su lugar.

**⏱️ 30 segundos.** Porque ese 401 nace en la **cadena de filtros**, fuera del `DispatcherServlet`, y
el `@ExceptionHandler` vive dentro. Se configuran el `AuthenticationEntryPoint` y el
`AccessDeniedHandler` de Spring Security para que respondan con tu formato.

**🗣️ 2 minutos.** Es la limitación clave del manejo centralizado de errores y está explicada en
[`08` §5](08-modelo-de-ejecucion-web.md#5--filtro-interceptor-o-advice): una excepción lanzada en un
filtro sube al contenedor de servlets, que responde con su propia página o con el `/error` de Boot.
El síntoma es que los 401 y 403 no se parecen en nada al resto de tus errores. Lo mismo pasa con un
404 de ruta inexistente, que solo llega al advice si activas
`spring.mvc.throw-exception-if-no-handler-found=true`.

**🔬 El detalle.** El diagnóstico rápido es mirar el stack trace: si no aparece
`DispatcherServlet.doDispatch`, la excepción nació fuera de MVC y ningún advice la va a ver.

---

### 10 → 8

> ¿Cuándo respondes 422 en vez de 400, y cuándo 404 en vez de 403?

**⏱️ 30 segundos.** 422 cuando el mensaje se entiende pero es semánticamente inválido, y 400 cuando
ni siquiera se puede leer —JSON roto, tipo incompatible—. 404 en lugar de 403 cuando el recurso
existe pero es de otro titular y no quieres confirmar que existe.

**🗣️ 2 minutos.** En el par 400/422 hay dos escuelas honestas: el 422 es más preciso y varias APIs de
banca lo exigen, el 400 es universal. Lo que rompe integraciones no es elegir uno, sino usar los dos
sin regla; se decide una vez y se documenta. El 404 frente al 403 no es purismo sino seguridad: un
403 confirma la existencia del recurso y permite enumerar cuentas ajenas. En la misma familia:
401 es "no sé quién eres", 403 es "sé quién eres y no te alcanza", 409 es choque con el estado
actual y 429 es cuota excedida — este último con `Retry-After`, o el cliente reintenta a ciegas.

---

### 10 → 9

> ¿Quién genera la `Idempotency-Key`, y qué debe responder el servidor si la misma clave llega con un body distinto?

**⏱️ 30 segundos.** La genera **el cliente**, una por intención de negocio. Si la misma clave llega
con un body distinto, el servidor responde **409**, no la respuesta anterior.

**🗣️ 2 minutos.** La clave existe porque `POST` no es idempotente: si la respuesta se pierde y el
cliente reintenta, sin clave acabas con dos items o dos cargos. El servidor guarda clave → respuesta
con TTL y devuelve la respuesta original sin volver a ejecutar el negocio. Si el servidor generara la
clave no serviría de nada, porque el reintento traería otra distinta. Y la clave se ata al payload:
la misma clave con otro contenido es un error del cliente, no un reintento, y devolver la respuesta
vieja ocultaría un bug suyo.

**🔬 El detalle.** El registro crece con cada escritura, así que la ventana —24 horas es lo habitual
en banca— se fija con TTL y se declara en el contrato: un reintento fuera de esa ventana sí duplica,
y el cliente tiene derecho a saberlo.

---

### 10 → 10

> Compara `Page` y `Slice` en consultas ejecutadas, y di cuándo eliges cada uno.

**⏱️ 30 segundos.** `Page` ejecuta la consulta de la página **más un `COUNT(*)`** para dar el total;
`Slice` pide `size+1` filas y solo responde si hay siguiente. Si la UI solo necesita "siguiente",
`Slice`; si necesita el número total de páginas, `Page`.

**🗣️ 2 minutos.** Ese `COUNT(*)` recorre toda la tabla filtrada y en tablas grandes cuesta más que la
página misma, así que es la mitad del trabajo de cada request a cambio de un número que muchas veces
nadie mira. Además ninguno de los dos se devuelve tal cual en el JSON: la serialización de `Page` no
es parte del contrato de Spring Data, cambió entre versiones y arrastra campos internos; se mapea a
un `record` propio que tú versionas. Y cuando la profundidad importa, el offset se sustituye por
cursor: es estable frente a inserciones, a cambio de no poder saltar a la página 500.

---

### 10 → 11

> "HATEOAS es lo que hace que una API sea REST de verdad": ¿qué tiene de cierto, y cuándo no vale la pena pagarlo?

**⏱️ 30 segundos.** Es cierto según Fielding: sin hipermedia estás en el nivel 2 de Richardson, no en
REST. Y aun así casi todo lo que llamamos REST es nivel 2, porque el costo solo se recupera con
clientes que no controlas o con flujos con estado.

**🗣️ 2 minutos.** HATEOAS paga cuando la API vive más que sus clientes, cuando el flujo tiene estado
—una transferencia que solo admite `confirm` o `cancel` mientras está pendiente, y el enlace aparece
o desaparece— y cuando quieres mover URIs sin coordinar despliegues con doce equipos. Es ceremonia
cuando el consumidor es tu propio frontend, desplegado contigo y escrito contra un OpenAPI generado:
va a fijar las rutas igual, y habrás pagado `_links` en cada respuesta y un
`RepresentationModelAssembler` por recurso a cambio de nada. Lo que la entrevista quiere oír es que
sabes qué nivel estás construyendo y por qué, no que recitas los cuatro niveles.

**🔬 El detalle.** En Spring, `EntityModel` y `CollectionModel` envuelven el DTO, `WebMvcLinkBuilder`
construye las URLs leyendo tus propios mapeos —`methodOn` devuelve un proxy que no ejecuta el método,
solo registra cuál invocaste— y el media type por defecto es `application/hal+json`, con los enlaces
bajo `_links` y los recursos embebidos bajo `_embedded`.

---

## Capítulo 11 — WebFlux y Reactor

### 11 → 1

> ¿Por qué 200 hilos de Tomcat y un proveedor de 800 ms dan un techo de 250 req/s, y qué
> parte de ese cálculo cambia WebFlux?

**⏱️ 30 segundos.** Porque en thread-per-request un hilo atiende una petición de principio a
fin: si cada una ocupa 0,8 s, cada hilo hace 1,25 peticiones por segundo y 200 hilos dan 250
req/s. WebFlux no cambia los 800 ms; cambia el divisor, porque deja de hacer falta un hilo
por petición en curso.

**🗣️ 2 minutos.** El cálculo es `concurrencia ÷ latencia`. La latencia la pone el proveedor,
`inv-supplier`, y ningún modelo de ejecución la baja. La concurrencia la pone
`server.tomcat.threads.max`, y ahí sí hay techo duro: cada hilo de plataforma reserva del
orden de 1 MB de pila, así que subirlo a 2 000 cuesta ~2 GB y además solo alarga la cola de
la misma lentitud. En el modelo reactivo, mientras el socket espera no hay ningún hilo
retenido: unos pocos hilos de event loop —uno o dos por core— mantienen miles de conexiones
abiertas y se despiertan cuando hay bytes. El techo pasa a ser la memoria de los objetos en
vuelo y los límites del proveedor, no el número de hilos.

**🔬 El detalle.** Es la misma cuenta que la ley de Little: peticiones en el sistema =
throughput × latencia. Por eso subir `threads.max` sin tocar la latencia no aumenta el
throughput sostenible, solo el número de peticiones esperando; y por eso la métrica que hay
que mirar antes de migrar es la utilización de los hilos, no la CPU.

---

### 11 → 2

> Un entrevistador afirma que "WebFlux es más rápido". Da la versión precisa en una frase.

**⏱️ 30 segundos.** "WebFlux no es más rápido: usa menos hilos. La petición tarda lo mismo;
lo que sube es cuántas peticiones concurrentes soporta el proceso, y solo cuando el cuello
de botella es espera de E/S."

**🗣️ 2 minutos.** La latencia de una petición individual con WebFlux suele ser igual o
ligeramente peor que con MVC, porque se añade el costo de ensamblar y programar la cadena.
Lo que mejora es la eficiencia por hilo y por megabyte: el mismo servicio aguanta muchísimas
más conexiones simultáneas con la misma memoria. Si tu carga es CPU-bound, no gana nada; si
es un gateway que espera a tres proveedores, gana mucho. Y se paga en legibilidad,
depurabilidad y curva de equipo.

**🔬 El detalle.** Es una de las cinco analogías peligrosas del curso. La respuesta completa
de entrevista añade *"y la elección entre MVC, WebFlux y virtual threads se toma con
números, midiendo, no por reputación"*, que es el tema de `12`.

---

### 11 → 3

> Llamas a `repository.save(event)` y descartas el resultado. ¿Qué se escribe en la base de
> datos y qué aparece en el log?

**⏱️ 30 segundos.** No se escribe nada, y en el log no aparece nada. El `Mono` que devuelve
`save()` es solo la receta; sin suscripción no se ejecuta, y descartarlo no es un error para
el compilador ni para Reactor.

**🗣️ 2 minutos.** En Reactor nada ocurre en tiempo de ensamblado: `findById`, `map`, `save`
construyen un grafo de operadores. La ejecución empieza cuando alguien llama a `subscribe()`,
y en una aplicación WebFlux ese alguien es el framework, cuando tu controller le devuelve el
publicador. Un `Mono` que no se devuelve ni se encadena queda huérfano. La regla práctica es
que **todo método que devuelve un publicador obliga al llamador a devolverlo o a encadenarlo**;
si de verdad necesitas dispararlo y olvidarte, tienes que llamar a `subscribe()` explícitamente
y asumir que pierdes el contexto y el manejo de errores.

**🔬 El detalle.** Es el fallo que más se cuela en revisiones de código porque se parece a
una llamada normal. Se caza con reglas de análisis estático que marcan el retorno reactivo
ignorado, y en tests con `StepVerifier`, que falla si la cadena no emite lo esperado.

---

### 11 → 4

> Explica por qué `flatMap` no es "el `map` asíncrono" y di qué operador usarías si
> necesitas conservar el orden de emisión.

**⏱️ 30 segundos.** `map` aplica una función síncrona y conserva el orden. `flatMap` se
suscribe a los publicadores internos **en paralelo** —concurrencia 256 por defecto— y emite
en el orden en que responden. Si necesito el orden original, `concatMap`.

**🗣️ 2 minutos.** La diferencia de firma ya lo anuncia: `map` es `T → R` y `flatMap` es
`T → Publisher<R>`. Ese aplanado implica suscribirse a N publicadores internos, y Reactor lo
hace concurrentemente hasta el límite que le pases. De ahí tres consecuencias: el orden de
salida no es el de entrada, puedes saturar el sistema aguas abajo si no acotas la
concurrencia con `flatMap(fn, n)`, y los errores de cualquier interno terminan la secuencia
completa salvo que uses `flatMapDelayError`. Las alternativas ordenadas son `concatMap`
—uno detrás de otro, sin paralelismo— y `switchMap`, que cancela el interno anterior cuando
llega un elemento nuevo y es lo correcto para un autocompletado.

**🔬 El detalle.** El bug típico no aparece en local: con tres elementos las respuestas
vuelven casi siempre en orden. Sale en producción como eventos de inventario aplicados al
revés. Si el orden es un requisito de negocio, no se confía en la suerte: `concatMap`, o un
`Flux` particionado por clave con `groupBy` y `concatMap` dentro de cada grupo.

---

### 11 → 5

> ¿Qué es backpressure y qué cuatro estrategias hay si la fuente no puede ir más lento?

**⏱️ 30 segundos.** Backpressure es que el consumidor pide (`request(n)`) y el productor no
puede emitir más de lo pedido. Cuando la fuente no obedece, las estrategias son
`onBackpressureBuffer`, `onBackpressureDrop`, `onBackpressureLatest` y `onBackpressureError`.

**🗣️ 2 minutos.** Es el punto que separa Reactive Streams de un simple callback: el flujo de
demanda va del suscriptor hacia la fuente, así que una base de datos con R2DBC traduce el
`request(n)` a tamaño de fetch y una cola deja de consumir sola. El problema son las fuentes
que no pueden frenarse —un sensor, un WebSocket, un `Sinks.many()` alimentado desde fuera—:
ahí hay que elegir explícitamente qué se sacrifica. `Buffer` retiene en memoria (y sin cota
es una fuga), `Drop` descarta lo nuevo, `Latest` se queda solo con el último valor, y `Error`
falla rápido con `OverflowException`. La elección es de negocio: en cotizaciones interesa
`Latest`, en eventos contables no se puede perder nada y hay que acotar el buffer y aplicar
contrapresión real aguas arriba.

---

### 11 → 6

> ¿Por qué `onBackpressureBuffer()` sin argumentos es peligroso, y qué escribes en su lugar?

**⏱️ 30 segundos.** Porque es un buffer ilimitado: si el productor va más rápido que el
consumidor, la cola crece hasta el `OutOfMemoryError`. Se escribe con cota y con estrategia
de desbordamiento, por ejemplo `onBackpressureBuffer(1000, BufferOverflowStrategy.DROP_OLDEST)`.

**🗣️ 2 minutos.** Es una fuga de memoria con nombre técnico, y lo peor es que no se ve en
pruebas: en local el consumidor va sobrado. Aparece en producción semanas después, cuando la
fuente tiene un pico o el consumidor se degrada. Acotar obliga a decidir qué pasa al llenarse
—descartar el más viejo, el más nuevo, o fallar—, que es exactamente la decisión que un
buffer infinito esconde. Y como el buffer solo aplaza el problema, la pregunta siguiente es
si aguas arriba se puede aplicar contrapresión de verdad o limitar la tasa.

---

### 11 → 7

> Diferencia `publishOn` de `subscribeOn`, y di qué pasa si escribes dos `subscribeOn`.

**⏱️ 30 segundos.** `publishOn` cambia el hilo **de ese punto de la cadena hacia abajo** y se
puede usar varias veces. `subscribeOn` decide en qué hilo **arranca la suscripción**, o sea
la fuente y todo lo que está por encima, sin importar dónde lo escribas. Con dos, gana el
primero —el más cercano a la fuente— y el otro se ignora en silencio.

**🗣️ 2 minutos.** La confusión nace de que `subscribeOn` parece afectar a lo que tiene
debajo, y no: la suscripción viaja del suscriptor hacia la fuente, así que la posición en el
código no manda. En la práctica, `subscribeOn` se usa una vez, para decidir dónde corre una
fuente bloqueante o costosa; `publishOn` se usa para mover un tramo concreto de la cadena a
otro scheduler, típicamente aislar un trabajo bloqueante en `boundedElastic`. Que el segundo
`subscribeOn` no lance ningún error es parte del problema: el código compila, se ve
intencional y no hace nada.

**🔬 El detalle.** Con `WebClient` o R2DBC casi nunca necesitas `subscribeOn`, porque la
fuente ya es no bloqueante y arranca en el event loop. Aparece cuando envuelves algo
bloqueante con `Mono.fromCallable(...).subscribeOn(Schedulers.boundedElastic())`, que es el
idioma estándar para esa integración.

---

### 11 → 8

> ¿Para qué existe `Schedulers.boundedElastic()` y en qué se diferencia de
> `Schedulers.parallel()`?

**⏱️ 30 segundos.** `boundedElastic` es un pool elástico y acotado —por defecto 10 × cores—
pensado para **aislar trabajo bloqueante**: JDBC, ficheros, librerías legacy. `parallel` es
un pool fijo del tamaño del número de cores, para trabajo **CPU-bound y corto**; bloquear ahí
es tan malo como bloquear el event loop.

**🗣️ 2 minutos.** La diferencia está en qué se espera de cada hilo. En `boundedElastic` se
asume que el hilo va a quedarse quieto esperando E/S, por eso se permite crecer y por eso
está acotado: sin cota volvería a ser el problema de los 200 hilos, con cota se comporta como
un pool con cola y te avisa por saturación. En `parallel` se asume que cada tarea consume CPU
y termina; si una bloquea, quitas una CPU virtual entera del reparto. Y ninguno de los dos es
excusa para bloquear a gusto: cada salto de scheduler cuesta un cambio de contexto y rompe la
localidad, así que la regla sigue siendo que el trabajo bloqueante se elimina si se puede y se
aísla solo si no se puede.

---

### 11 → 9

> Tu servicio WebFlux deja de responder bajo carga, sin excepciones en el log. ¿Cuál es tu
> primera hipótesis y con qué dos herramientas la confirmas?

**⏱️ 30 segundos.** Que algo está bloqueando el event loop. Se confirma con un thread dump
—buscando los `reactor-http-nio-*` en `WAITING` o `TIMED_WAITING` dentro de código propio— y,
en `test`, con `BlockHound`, que convierte la llamada bloqueante en un error con tu línea en
el stack trace.

**🗣️ 2 minutos.** El síntoma clave es "sin excepciones": si fuera un `block()` explícito,
Reactor habría lanzado el `IllegalStateException: block()/blockFirst()/blockLast() are
blocking, which is not supported in thread reactor-http-nio-N`. Que no haya nada apunta a un
bloqueo que Reactor no detecta —un `Thread.sleep`, una llamada JDBC, un `synchronized` con
contención, una lectura de fichero, incluso una resolución DNS síncrona—. Con ocho hilos de
event loop bastan ocho peticiones atrapadas para que deje de responder todo, incluido
`/actuator/health`, que es lo que hace que el orquestador te reinicie el pod sin dejar
evidencia. Por eso el health check y las métricas conviene exponerlos en un puerto de
management aparte.

**🔬 El detalle.** `BlockHound` no va en producción porque aborta peticiones legítimas, pero
sí en el pipeline: un test de integración con `BlockHound.install()` convierte este incidente
en un fallo de build. Como red adicional, las métricas de Micrometer para Reactor
(`reactor.scheduler…`) y la latencia por endpoint muestran el patrón de "todo se congela a la
vez", que es distinto del de un pool de conexiones agotado.

---

### 11 → 10

> ¿Por qué `ThreadLocal` no funciona en WebFlux, qué lo sustituye y en qué dirección se
> propaga?

**⏱️ 30 segundos.** Porque una misma petición cruza varios hilos: empieza en un
`reactor-http-nio-*`, sigue en `boundedElastic` tras un `publishOn` y termina en otro. Lo
sustituye el `Context` de Reactor, que viaja con la suscripción, y se propaga **de abajo hacia
arriba**: un `contextWrite` solo lo ven los operadores que están por encima.

**🗣️ 2 minutos.** El `ThreadLocal` funciona en MVC porque el request vive en un hilo de
principio a fin. En Reactor la unidad no es el hilo sino la suscripción, así que el contexto
se ata a ella: se escribe con `contextWrite`, se lee con `deferContextual` o
`transformDeferredContextual`, y es un mapa inmutable. La dirección sorprende hasta que
recuerdas que la suscripción viaja del suscriptor hacia la fuente. Las consecuencias
prácticas son tres: el `SecurityContext` se lee con `ReactiveSecurityContextHolder`, el
`traceId` del `MDC` no se propaga solo y necesita el puente `context-propagation` de
Micrometer con `Hooks.enableAutomaticContextPropagation()`, y la transacción reactiva también
vive en el `Context`, no en el `TransactionSynchronizationManager`.

**🔬 El detalle.** El bug más caro aquí es el intermitente: un `ThreadLocal` que a veces
coincide porque la cadena no llegó a cambiar de hilo. Pasa las pruebas y falla bajo carga,
que es cuando entra el `publishOn`. Por eso la regla es categórica: en WebFlux no se lee
contexto del hilo, ni "solo para el log".

---

### 11 → 11

> Un compañero propone envolver el repositorio JPA en `Mono.fromCallable` para "hacerlo
> reactivo". ¿Qué le respondes y qué límite sigue existiendo?

**⏱️ 30 segundos.** Que eso no lo vuelve reactivo, lo vuelve asíncrono sobre un pool: la
llamada sigue bloqueando un hilo de `boundedElastic`, y el límite real sigue siendo el número
de conexiones del pool de Hikari.

**🗣️ 2 minutos.** El patrón
`Mono.fromCallable(() -> repo.findById(id)).subscribeOn(Schedulers.boundedElastic())` es
legítimo y es lo que se hace para integrar un componente bloqueante en una aplicación
reactiva. Lo que no se puede es venderlo como migración a reactivo: la concurrencia máxima
sigue siendo `min(hilos de boundedElastic, conexiones del pool)`, y encima ahora tienes dos
pools que dimensionar en vez de uno. Además pierdes cosas por el camino: la transacción vive
en un `ThreadLocal` del hilo de `boundedElastic`, así que hay que tener cuidado de no partir
una unidad de trabajo entre dos saltos de scheduler, y las entidades con carga perezosa
explotan fuera de la sesión. La alternativa real es R2DBC, con lo que implica: sin lazy
loading, sin caché de primer nivel, y el mapeo de relaciones a mano.

**🔬 El detalle.** Hibernate Reactive existe y funciona sobre Vert.x, pero no es JPA
estándar ni es lo que trae el starter de Boot, así que en banca es difícil de defender.
Cuando el dominio es transaccional y rico, la respuesta honesta en entrevista es que la
persistencia bloqueante es un argumento de peso **contra** migrar a WebFlux, y es justo la
decisión que se razona en `12`.

---

### 11 → 12

> Devuelves un `Flux` infinito desde un `@GetMapping` sin declarar `produces`. ¿Qué ve el
> cliente y cómo se corrige?

**⏱️ 30 segundos.** Nada: WebFlux intenta serializar el `Flux` como un array JSON y espera a
que termine, y como no termina nunca, la respuesta queda abierta sin cuerpo útil. Se corrige
declarando `produces = MediaType.TEXT_EVENT_STREAM_VALUE`, o `APPLICATION_NDJSON_VALUE`, para
que cada elemento se escriba conforme llega.

**🗣️ 2 minutos.** El tipo de contenido es lo que decide el modo de escritura. Con
`application/json`, el `HttpMessageWriter` agrega los elementos en un array y solo emite al
completarse la secuencia; es lo correcto para un `Flux` finito de una consulta. Con
`text/event-stream` cada elemento sale como un evento SSE y la conexión queda abierta, que es
lo que quieres para un stream de `InventoryEvent`. `application/x-ndjson` hace lo mismo con un
JSON por línea y es mejor para clientes que no son navegadores. Y hay que pensar el cierre:
un stream infinito necesita `takeUntil`, un `timeout` o la cancelación del cliente, más un
límite de conexiones, porque cada cliente conectado consume memoria aunque no consuma hilos.

---

### 11 → 13

> Tienes un stack trace reactivo sin una sola clase tuya. ¿Qué pones en producción y qué
> pones solo en `test`?

**⏱️ 30 segundos.** En producción, `checkpoint("etiqueta")` en los puntos clave —cuesta cero—
y, si necesito trazas completas bajo carga, el agente `reactor-tools` con
`ReactorDebugAgent.init()`. Solo en `test` o en una sesión puntual,
`Hooks.onOperatorDebug()`, que es carísimo.

**🗣️ 2 minutos.** El trace es inútil porque la cadena se ensambla en un sitio y se ejecuta en
otro, quizá en otro hilo, y la pila solo conserva la ejecución. `checkpoint` añade una marca
de ensamblado en el punto donde lo pones, así que con uno por llamada externa ya sabes qué
tramo falló; es la herramienta de producción. `Hooks.onOperatorDebug()` captura la pila de
ensamblado de todos los operadores de toda la aplicación: te da el trace perfecto y te
destroza el rendimiento. `reactor-tools` consigue lo mismo instrumentando el bytecode al
arrancar, con un costo despreciable, y es el punto medio razonable.

**🔬 El detalle.** Conviene además no perder el contexto: con `context-propagation` activo, el
`traceId` sigue apareciendo en los logs aunque la cadena cambie de hilo, y eso suele
identificar la petición culpable más rápido que el propio stack trace. Y en las pruebas,
`StepVerifier` con `withVirtualTime` permite reproducir el fallo sin esperar los timeouts
reales.

---

## Capítulo 12 — Reactivo, bloqueante y virtual threads

### 12 → 1

> ¿Cuál es el único eje en el que los tres modelos se diferencian de verdad, y por qué la
> velocidad del código de negocio no lo es?

**⏱️ 30 segundos.** El coste de **una espera concurrente**. El código de negocio corre a la
misma velocidad en los tres: es el mismo bytecode sobre la misma JVM.

**🗣️ 2 minutos.** Una petición típica de un servicio de banca son unos milisegundos de CPU
y cientos de milisegundos esperando a la base, al proveedor externo o a la caché. Lo que
distingue a los modelos es qué hace el proceso durante esa espera: retener un hilo de
plataforma de 1 MB, no retener nada porque el trabajo está descompuesto en operadores, o
retener un hilo virtual de aproximadamente 1 KB. Si contestas en términos de "rapidez",
estás midiendo la dimensión en la que los tres empatan.

**🔬 El detalle.** La petición de ejemplo del capítulo son **5 ms de CPU y 300 ms de
espera**: el 98 % de la vida de la petición no se gasta ejecutando tu código. Ese
porcentaje es la primera fila de la tabla de métricas del capítulo y es lo que hay que
medir antes de discutir modelos — si sale bajo, la conversación entera sobra, porque el
cuello es la CPU y ningún modelo de concurrencia multiplica núcleos.

---

### 12 → 2

> Con 1 000 peticiones concurrentes de 300 ms contra un proveedor externo, ¿qué latencia
> ve el percentil alto en Tomcat con 200 hilos y por qué?

**⏱️ 30 segundos.** Alrededor de **1,5 segundos**: 300 ms × (1000/200). Solo 200 peticiones
esperan a la vez; las otras 800 hacen cola sin hilo.

**🗣️ 2 minutos.** El cálculo sale de que el servidor procesa en tandas de 200: la primera
tanda termina a los 300 ms, la segunda a los 600, y la quinta a los 1 500. La media engaña
—hay peticiones que se atendieron en 300 ms—, y por eso este capítulo insiste en mirar el
p99 y no el promedio. Con WebFlux o con virtual threads las 1 000 esperan a la vez y todas
ven ~300 ms, porque el proveedor es el mismo y no era él el cuello.

**🔬 El detalle.** Los 1,5 s son una cota inferior, no una predicción: suponen reparto
perfecto en tandas y tiempo de CPU despreciable frente a los 300 ms. Lo exacto es la forma
de la cuenta —latencia ≈ espera × (concurrencia / hilos)—, y de ahí sale la lectura útil:
mientras la concurrencia no supere el número de hilos, el multiplicador vale 1 y los tres
modelos miden lo mismo (pregunta 12).

---

### 12 → 3

> ¿Qué cuesta, en orden de magnitud, la pila de un hilo de plataforma frente a la de uno
> virtual?

**⏱️ 30 segundos.** Un hilo de plataforma reserva del orden de **1 MB**; uno virtual, del
orden de **1 KB**, y crece bajo demanda en el heap.

**🗣️ 2 minutos.** Son tres órdenes de magnitud, y eso es lo que convierte "decenas de miles
de esperas concurrentes" en algo razonable. La pila del hilo de plataforma se reserva
aunque no se use, y además el sistema operativo participa en cada cambio de contexto. Un
hilo virtual vive en el heap, lo planifica la JVM y se desmonta cuando se bloquea — salvo
en los casos de pinning.

---

### 12 → 4

> ¿Qué cambia en tu código al activar `spring.threads.virtual.enabled=true`, y qué más
> afecta esa propiedad aparte del servidor web?

**⏱️ 30 segundos.** En tu código, **nada**. Además del servidor web, pasa a usar hilos
virtuales para `@Async` y para las tareas de `@Scheduled`.

**🗣️ 2 minutos.** Esa es toda la gracia del modelo: el código sigue siendo secuencial,
bloqueante y depurable, y lo único que cambia es lo que cuesta bloquear. Requiere Java 21 y
Boot 3.2 o superior. Lo que sí conviene revisar antes de activarlo son los sitios donde el
código asume que el hilo se reutiliza —cachés por `ThreadLocal`, buffers reutilizables— y
los bloques `synchronized` en rutas que bloquean.

**🔬 El detalle.** La auditoría previa son tres cosas concretas: `synchronized` alrededor
de E/S (pregunta 6); cachés y buffers por `ThreadLocal`, que dejan de amortizarse porque ya
no hay hilo que reutilizar y pasan a costar una copia por petición; y el dimensionado del
pool de conexiones, que es el techo que queda cuando quitas el de los hilos (pregunta 5).
Activarlo es una línea de configuración **y** una prueba de carga: sin la segunda no has
comprobado nada.

---

### 12 → 5

> Tienes 10 000 hilos virtuales y un pool de 10 conexiones. ¿Cuál es tu concurrencia real
> y qué te dice eso sobre la migración?

**⏱️ 30 segundos.** Diez. Los hilos virtuales quitan el límite de los hilos, no el del
recurso de abajo, y aquí el techo es el pool.

**🗣️ 2 minutos.** Es el error de razonamiento más común con esta tecnología: se sustituye
un cuello por otro y se celebra el cambio. Si tu servicio está limitado por Hikari, lo que
consigues al migrar es que 9 990 hilos esperen en la cola del pool en lugar de esperar en
la cola de Tomcat — la latencia no mejora. La comprobación previa es mirar
`hikaricp.connections.pending`: si hay cola, el trabajo está en dimensionar el pool o en
reducir el tiempo que cada petición lo retiene (`16`), no en el modelo de hilos.

**🔬 El detalle.** La concurrencia real es `min(hilos, conexiones)`, y el segundo término
no se sube a voluntad: la fórmula de dimensionado de HikariCP es
`conexiones ≈ (núcleos × 2) + spindles`, entre 8 y 12 en una máquina de 4 núcleos con SSD
(`15`), así que ese pool de 10 probablemente ya estaba bien puesto y el trabajo real es
soltar la conexión antes —acortar la transacción, no serializar una respuesta grande con la
conexión abierta—. El síntoma de no hacerlo es el `connection is not available, request
timed out` de Hikari, con sus 30 000 ms de espera por defecto antes de fallar.

---

### 12 → 6

> Explica el pinning por `synchronized` en Java 21: qué ocurre, por qué es difícil de
> diagnosticar y cuál es la corrección.

**⏱️ 30 segundos.** Un hilo virtual que se bloquea dentro de un bloque `synchronized` **no
se desmonta**: retiene el hilo portador de plataforma. Con suficientes, se agotan los
portadores. La corrección es `ReentrantLock`.

**🗣️ 2 minutos.** Es difícil de diagnosticar porque el síntoma no se parece a la causa: el
servicio deja de progresar aunque haya pocos hilos virtuales activos y la CPU esté ociosa,
y los hilos que ves en un thread dump son los portadores, no los tuyos. El caso típico no
está en tu código sino en una librería antigua que sincroniza alrededor de una llamada de
E/S. Por eso, antes de activar virtual threads en un servicio con dependencias viejas,
conviene una prueba de carga y no solo un arranque.

**🔬 El detalle.** El aviso tiene fecha: el pinning por `synchronized` se corrigió en
**Java 24, con JEP 491**, y desde ahí un hilo virtual que se bloquea dentro de un
`synchronized` ya no clava su carrier thread. El curso fija Java 21, así que aquí aplica
entero; en una entrevista conviene decir la versión, porque sobre 24 o posterior el
argumento del `ReentrantLock` deja de ser obligatorio.

---

### 12 → 7

> Nombra dos cosas que WebFlux te da y los virtual threads no.

**⏱️ 30 segundos.** **Backpressure de extremo a extremo** y un modelo natural de
**streaming** —SSE, flujos infinitos, respuestas que se emiten por partes—.

**🗣️ 2 minutos.** El backpressure es la capacidad del consumidor de decirle al productor
que vaya más despacio, propagada a lo largo de toda la cadena; con hilos bloqueantes la
contrapresión existe solo de forma implícita, bloqueando, y no cruza los límites de red.
El streaming reactivo permite emitir mientras llegan los datos sin retener un hilo por
cliente. Son exactamente los dos casos en los que hoy seguiría eligiendo WebFlux teniendo
virtual threads disponibles.

**🔬 El detalle.** El backpressure de Reactive Streams es un `request(n)` que el suscriptor
manda aguas arriba; con hilos —virtuales o no— no existe ese canal y lo único que queda es
bloquear, que no cruza un límite de red. Matiz que distingue al que lo entendió: ni en
WebFlux es gratis, porque no toda fuente obedece el `request(n)` (`11`), y a la que no frena
hay que decirle qué hacer con el exceso — `onBackpressureBuffer` **acotado**, `Drop`,
`Latest` o `Error`.

---

### 12 → 8

> ¿Por qué la fila del ecosistema decide más casos reales que las de rendimiento?

**⏱️ 30 segundos.** Porque si tu stack es JDBC y JPA, el modelo reactivo te obliga a aislar
cada llamada bloqueante en un pool de hilos, y pierdes buena parte de lo que fuiste a
buscar.

**🗣️ 2 minutos.** Un servicio de banca habla con Postgres, con un mainframe y con
librerías corporativas bloqueantes. En WebFlux todo eso va a `boundedElastic`, que es un
pool de hilos de plataforma: has reintroducido el modelo que querías evitar, con la
complejidad del reactivo encima. R2DBC existe pero no tiene un ORM maduro y renuncia a
gran parte del ecosistema JPA (`11`). Las cifras de rendimiento solo importan si el
ecosistema te deja llegar a ellas.

**🔬 El detalle.** `boundedElastic` está acotado por defecto en **10 × núcleos** hilos de
plataforma (`11`): en una máquina de 4 núcleos son 40, frente a los 200 de Tomcat que
acababas de abandonar. Aislar JDBC ahí no reintroduce el modelo antiguo — reintroduce una
versión más pequeña de él, con la sintaxis reactiva encima.

---

### 12 → 9

> Antes de proponer una migración, ¿qué dos métricas miras y qué te haría abandonar la
> idea en cinco minutos?

**⏱️ 30 segundos.** Hilos ocupados frente a `threads.max`, y `hikaricp.connections.pending`.
Si el máximo de hilos observado no se acerca al límite, abandono: no tengo un problema de
concurrencia.

**🗣️ 2 minutos.** La tercera métrica útil es el porcentaje del tiempo de petición que se va
en espera de E/S: si es bajo, el problema es CPU y ningún modelo de concurrencia lo
arregla. Con `threads.max` en 200 y un máximo observado de 40, una migración de seis meses
no puede mejorar nada, y eso se comprueba en Actuator en cinco minutos (`23`). Es la clase
de respuesta que distingue a alguien que ha propuesto migraciones de alguien que las ha
sufrido.

**🔬 El detalle.** Dos trampas al leer esas métricas. Los hilos ocupados se miran **en el
pico bajo carga**, no en la media diaria: un promedio de 40 con picos en 200 es el caso
contrario al que parece. Y una vez activados los hilos virtuales, la métrica de hilos deja
de informar —ya no hay pool acotado que saturar—, así que el indicador que queda es
`hikaricp.connections.pending` y el p99, nunca la media.

---

### 12 → 10

> Da tres componentes del coste de equipo de WebFlux que no aparecen en un benchmark.

**⏱️ 30 segundos.** Que todo el equipo debe leer cadenas de operadores, que depurar cuesta
más —stack traces que no reflejan el flujo— y que un bloqueo por descuido degrada el
servicio entero sin fallar ruidosamente.

**🗣️ 2 minutos.** El cuarto, y el más caro en banca, es la rotación: el equipo de dentro de
dos años no es este, y el modelo reactivo tiene una curva que no se amortiza sola. Decir
esto en una entrevista de tech lead vale más que citar benchmarks, porque demuestra que
has mantenido sistemas y no solo arrancado prototipos. Y no es un argumento contra WebFlux:
es parte de su precio, y un precio que a veces se paga con gusto.

**🔬 El detalle.** Los dos síntomas concretos por los que se paga: orientarse en un stack
trace reactivo exige haber sembrado `checkpoint("etiqueta")` en el punto sospechoso **antes**
de que fallara, y la diferencia entre `map` y `flatMap` no es intuitiva para quien llega.
Ninguna de las dos aparece en una columna de benchmark; las dos aparecen en cada revisión
de código.

---

### 12 → 11

> Tu aplicación es MVC y usa `WebClient` con `.block()`. ¿Qué modelo de ejecución tienes
> realmente, y qué cambia si activas virtual threads?

**⏱️ 30 segundos.** Tienes thread-per-request con pasos extra: el hilo del contenedor se
bloquea igual. Con virtual threads, ese bloqueo deja de ser caro.

**🗣️ 2 minutos.** Usar un cliente reactivo dentro de un servidor bloqueante es legítimo y
frecuente —te da una API moderna sin cambiar el modelo—, pero no convierte la aplicación
en reactiva: el beneficio está en el cliente, no en el servidor. De hecho, con
`spring-webflux` y `spring-webmvc` juntos en el classpath gana el stack servlet (`06`).
Al activar virtual threads, la combinación mejora sin tocar código, y por eso funciona
mejor de lo que suena.

**🔬 El detalle.** Lo que sí compras aunque el servidor siga siendo servlet: `spring-webflux`
arrastra Netty y sus hilos de event loop al proceso. Y ese `.block()` solo es legal porque lo
haces desde un hilo del contenedor — el mismo `.block()` dentro de un operador, sobre un hilo
`reactor-http-nio-*`, revienta con `IllegalStateException: block()/blockFirst()/blockLast()
are blocking, which is not supported in thread reactor-http-nio-3` (`11`).

---

### 12 → 12

> ¿Por qué un benchmark con baja concurrencia no puede distinguir los tres modelos?

**⏱️ 30 segundos.** Porque la diferencia está en el coste de la espera concurrente, y sin
concurrencia alta no hay esperas simultáneas que abaratar.

**🗣️ 2 minutos.** Con diez peticiones a la vez, doscientos hilos de plataforma sobran, así
que ningún modelo está limitado y los tres miden lo mismo: el tiempo del proveedor externo.
El benchmark solo empieza a informar cuando satura el recurso que el modelo pretende
liberar. Es el error clásico de las comparativas de blog, y también la razón por la que un
"lo probamos y no mejoró" no significa nada si no dice a qué carga.

**🔬 El detalle.** Un benchmark informa cuando satura el recurso que el modelo pretende
liberar: hay que subir la concurrencia hasta que los hilos ocupados se acerquen a
`threads.max` y publicar el p99 **junto a la carga a la que se midió**. Un número sin la
concurrencia al lado no es un resultado.

---

### 12 → 13

> ¿En qué caso concreto seguirías eligiendo WebFlux hoy, teniendo virtual threads
> disponibles?

**⏱️ 30 segundos.** Cuando necesito **backpressure real de extremo a extremo** o
**streaming**: un gateway que agrega muchas llamadas, SSE, o un consumidor que debe frenar
al productor.

**🗣️ 2 minutos.** El segundo caso legítimo es que ya estés en WebFlux y funcione: migrar
hacia atrás rara vez se justifica por sí solo. Fuera de esos, para un servicio de banca con
CRUD transaccional, JDBC y `@Transactional`, thread-per-request con virtual threads da el
mismo beneficio de concurrencia con código secuencial, stack traces legibles y cero curva
de equipo. La respuesta madura no es "WebFlux ya no hace falta", es "el caso de uso que lo
justificaba se ha reducido mucho, y estos son los dos que quedan".

**🔬 El detalle.** La forma de decirlo pesa tanto como el contenido. "Reactivo escala mejor"
es la frase que delata, porque escalar es justo lo que no distingue a los modelos cuando el
cuello es el pool o la CPU. La versión precisa —"reactivo hace más barata la espera
concurrente"— mueve la conversación a dónde está el cuello, que es donde te conviene
tenerla.

---

## Capítulo 13 — Clientes HTTP

### 13 → 1

> Con 200 hilos y un proveedor que pasa a tardar 30 segundos, ¿qué falla y en qué orden hasta
> que el cliente ve "connection refused"?

**⏱️ 30 segundos.** Los 200 hilos de Tomcat se quedan bloqueados esperando a `inv-supplier`, la
capacidad cae de 2 500 req/s a 6,6, la `accept-count` se llena y el sistema operativo empieza a
rechazar conexiones. Nadie lanzó una excepción: se acabaron los hilos.

**🗣️ 2 minutos.** Con 100 req/s entrando, los 200 hilos se ocupan en unos dos segundos, la cola
de 100 conexiones aceptadas se llena en uno más y a partir del tercer segundo el cliente ve un
error de conexión, no un 503 —porque el 503 lo tendría que emitir alguien, y no queda nadie
libre para emitirlo—. Cae el servicio entero y no solo el endpoint lento, porque el pool de
hilos es compartido; el `/health` sobrevive únicamente si Actuator está en
`management.server.port=8081`, que tiene su propio conector.

**🔬 El detalle.** En el `threaddump` todos esos hilos aparecen en
`sun.nio.ch.SocketDispatcher.read0` —`java.net.SocketInputStream.socketRead0` es el nombre
anterior a JDK 13 y ya no aparece en Java 21—: es la firma del incidente y lo que lo distingue del
agotamiento de pool de conexiones, donde los hilos esperan en el `lease` del connection manager.
Sin `read-timeout` los 30 segundos ni siquiera son el techo: si el proveedor acepta la conexión
y nunca escribe, el hilo espera indefinidamente.

---

### 13 → 2

> ¿Qué cubre `connect-timeout`, qué cubre `read-timeout` y por qué ninguno acota la llamada?

**⏱️ 30 segundos.** `connect-timeout` es el techo para **abrir** la conexión —handshake TCP y
TLS—; `read-timeout` es el techo **entre dos bloques de bytes** de la respuesta. Ninguno mide la
llamada completa: eso lo hace un `TimeLimiter`.

**🗣️ 2 minutos.** El `connect-timeout` se agota cuando el host no existe, el puerto está cerrado
o un firewall se traga los paquetes, y produce un fallo rápido y uniforme. El `read-timeout` es
el que de verdad te protege del proveedor enfermo, que abre la conexión en dos milisegundos y
después tarda. Pero es por lectura: una respuesta que gotea un bloque cada 2,9 segundos con un
`read-timeout` de 3 s no dispara nunca, y la llamada puede durar minutos. El presupuesto total
se impone por encima, con el `TimeLimiter` de `19`.

**🔬 El detalle.** En Boot 3.5 se configuran con `spring.http.client.connect-timeout` y
`spring.http.client.read-timeout`, que aceptan `Duration` (`2s`). Si los omites decide la
librería detectada: el `HttpClient` del JDK no impone ningún timeout de lectura y Apache
HttpClient 5 trae valores del orden de minutos.

---

### 13 → 3

> "`RestTemplate` está deprecado": corrige la afirmación con precisión.

**⏱️ 30 segundos.** No lo está. `RestTemplate` está en **modo mantenimiento** desde Spring 5.0 y
no lleva ninguna anotación `@Deprecated`: recibe correcciones, no funcionalidad nueva.

**🗣️ 2 minutos.** La consecuencia práctica es doble y conviene decir las dos mitades: el código
nuevo se escribe con `RestClient`, que desde Spring Framework 6.1 ofrece la misma semántica
bloqueante con la API fluida de `WebClient`; y el código existente que funciona no hay que
reescribirlo, porque no va a dejar de compilar ni de recibir parches. Contestar "está deprecado"
suena a actualizado y es falso; contestar "no pasa nada, uso `RestTemplate`" es no haberse
enterado de `RestClient`.

**🔬 El detalle.** `RestClient` y `RestTemplate` comparten los `HttpMessageConverter` y la
`ClientHttpRequestFactory`, así que la configuración de timeouts y pool es exactamente la misma.
Lo que cambia es la forma de invocar, y por eso migrar de `RestClient` a `WebClient` es casi
mecánico mientras que desde `RestTemplate` no lo es.

---

### 13 → 4

> ¿De quién es Feign y qué parte de lo que usas sí es de Spring?

**⏱️ 30 segundos.** Feign es una librería de Netflix. De Spring es **Spring Cloud OpenFeign**, el
envoltorio que la integra con el contenedor, y está en modo mantenimiento desde 2022.

**🗣️ 2 minutos.** Spring Cloud OpenFeign aporta el `@FeignClient`, el escaneo con
`@EnableFeignClients`, la configuración por cliente bajo `spring.cloud.openfeign.client.config.*`
y el soporte de las anotaciones de MVC en la interfaz. Todo eso vive fuera del BOM de Boot, en el
BOM de Spring Cloud, que se alinea por release train con la línea de Boot: es una dependencia de
versión aparte y ese es uno de sus costos. La alternativa equivalente **dentro** de Spring
Framework son las HTTP Interfaces (`@HttpExchange` + `HttpServiceProxyFactory`).

**🔬 El detalle.** El matiz de entrevista es que "en mantenimiento" no significa "roto": en banca
hay miles de `@FeignClient` en producción y se siguen soportando. Lo que significa es que la
funcionalidad nueva va a otro sitio, y por eso el consejo es migrar el cliente que toques por
otra razón, no lanzar una migración masiva.

---

### 13 → 5

> Distingue `RestClientResponseException` de `ResourceAccessException`: ¿cuál es reintentable?

**⏱️ 30 segundos.** `RestClientResponseException` significa que **el otro contestó** con un 4xx o
un 5xx; `ResourceAccessException` envuelve una `IOException` y significa que **no hubo
respuesta**. Reintentable: la de transporte y los 5xx, nunca un 4xx.

**🗣️ 2 minutos.** De `RestClientResponseException` cuelgan `HttpClientErrorException` (4xx) y
`HttpServerErrorException` (5xx), y ambas te dan `getStatusCode()` y
`getResponseBodyAsString()`, que es donde el proveedor explica el motivo. Un 4xx es un error de
tu petición —`sku` inexistente, token vencido, payload inválido— y reintentarlo solo multiplica
el mismo fallo. Un 5xx es del proveedor y se puede reintentar si tu llamada es idempotente.
`ResourceAccessException` cubre timeout de conexión, timeout de lectura, DNS y socket cerrado, y
también es reintentable con cuidado: el reintento de un timeout puede estar duplicando una
escritura que sí llegó.

**🔬 El detalle.** La distinción importa más allá del reintento: define qué cuenta como error de
disponibilidad de la dependencia, qué alimenta el circuit breaker y qué aparece en tu SLO. Todo
eso se apila encima en `19`.

---

### 13 → 6

> ¿Por qué un 404 no debería contar como error de disponibilidad de la dependencia?

**⏱️ 30 segundos.** Porque el proveedor **contestó y funcionó**: te dijo que ese recurso no
existe. Es un resultado del contrato, no una caída.

**🗣️ 2 minutos.** Si metes los 4xx en el mismo contador que los timeouts, un `sku` mal escrito
que se consulta en bucle sube la tasa de error de la dependencia, abre el circuit breaker y deja
sin servicio a todas las demás llamadas —que estaban perfectamente sanas—. El arreglo es
traducir el 404 en el cliente, con `onStatus` en `RestClient` o con un `ErrorDecoder` en Feign,
hacia una excepción de dominio propia que el resto del sistema entiende como "no encontrado" y
no como "proveedor caído".

**🔬 El detalle.** Hay excepciones razonadas: un 401 o un 403 sistemático **sí** es un incidente,
aunque sea 4xx, porque significa que tus credenciales caducaron. Lo que no se puede es decidirlo
por la familia del código: se decide por caso, y por eso `onStatus` recibe un predicado y no una
lista fija.

---

### 13 → 7

> Con 200 hilos y Apache HttpClient 5 en sus defaults, ¿cuántas llamadas llegan a la vez a
> `inv-supplier` y qué excepción ven las demás?

**⏱️ 30 segundos.** Cinco, porque el default de Apache HttpClient 5 es 25 conexiones en total y
**5 por host**. Las otras 195 esperan turno y acaban viendo
`ConnectionRequestTimeoutException: Timeout waiting for connection from pool`.

**🗣️ 2 minutos.** Es el fallo que más se diagnostica al revés: la latencia que mides sube, se
concluye que el proveedor está lento y se suben los hilos de Tomcat, lo que solo alarga la cola
del pool. La pista está en el `threaddump`: los hilos no están en `SocketDispatcher.read0` —esperando
bytes— sino esperando en el `lease` del connection manager. La corrección es dimensionar el
máximo por host, que *es* el número de llamadas concurrentes que le permites a ese proveedor.

**🔬 El detalle.** Ese límite por host es, de paso, el primer bulkhead que tienes: aísla por
configuración sin instalar nada. El bulkhead explícito, con su propia semántica de rechazo, está
en `19`. Y va de la mano del keep-alive: reutilizar conexiones evita rehacer el handshake TLS en
cada llamada, pero un `idle` mayor que el del otro extremo hace que reutilices sockets cerrados.

---

### 13 → 8

> ¿Qué hace `ParameterizedTypeReference` que no puede hacer `List.class`, y dónde explota?

**⏱️ 30 segundos.** Conserva el genérico. `List.class` pierde el parámetro de tipo por el
borrado, y Jackson deserializa una `List<LinkedHashMap>` en vez de una `List<SupplierQuote>`.

**🗣️ 2 minutos.** Se usa como
`body(new ParameterizedTypeReference<List<SupplierQuote>>() { })`, y las llaves finales no son
decoración: son la subclase anónima cuyo supertipo genérico queda escrito en el bytecode, que es
de donde Spring lee el tipo completo. Sin ellas no compila. El fallo con `List.class` no aparece
en la llamada sino más tarde, con un `ClassCastException` en la primera línea que acceda a un
campo del elemento, y esa distancia entre la causa y el síntoma es lo que lo hace caro de
depurar.

---

### 13 → 9

> Alguien loguea el cuerpo dentro de un `ClientHttpRequestInterceptor` y el `body(...)` empieza
> a devolver `null`: ¿qué pasó y cómo se corrige?

**⏱️ 30 segundos.** Se consumió el stream. El cuerpo de la respuesta se lee una sola vez, así que
cuando el `body(...)` llega ya no quedan bytes.

**🗣️ 2 minutos.** La corrección es envolver la `ClientHttpRequestFactory` en
`BufferingClientHttpRequestFactory`, que guarda la respuesta en memoria y permite leerla dos
veces. Y con la advertencia puesta: eso retiene la respuesta entera en heap por cada llamada en
vuelo, así que se activa en `DEBUG` y bajo demanda, nunca por defecto en producción. El
interceptor en sí es el lugar correcto para lo demás —propagar el `traceId`, medir la duración,
añadir una cabecera de correlación—, porque corre en el hilo del request, que es donde el `MDC`
todavía tiene el contexto.

**🔬 El detalle.** `execution.execute(request, body)` es el "llama al siguiente": si el
interceptor no lo invoca, la petición no sale. Es el `FilterChain` de `08` visto desde el lado
del cliente. En `WebClient` el equivalente es un `ExchangeFilterFunction`, y allí el contexto no
viaja en un `ThreadLocal` sino en el contexto reactivo.

---

### 13 → 10

> ¿Qué diferencia hay entre `@GetExchange` y `@GetMapping`, y qué anotaciones sí comparten?

**⏱️ 30 segundos.** `@GetMapping` declara lo que **tu servidor expone**; `@GetExchange`, de la
familia `@HttpExchange`, declara lo que **tú consumes**. Los parámetros sí son los mismos:
`@PathVariable`, `@RequestParam`, `@RequestBody`, `@RequestHeader`.

**🗣️ 2 minutos.** Esa mezcla es justo lo que confunde: un archivo con `@GetExchange` y
`@PathVariable` se parece mucho a un controller, y lo único que los distingue es el import del
verbo. `HttpServiceProxyFactory.builderFor(RestClientAdapter.create(client))` crea un proxy JDK
sobre la interfaz —el mismo mecanismo de proxies de `05` que sostiene todo lo declarativo del
curso—, y quien ejecuta la llamada es el `RestClient` que le pasaste, en el hilo del llamante.

**🔬 El detalle.** El adapter decide el modelo de ejecución sin tocar la interfaz:
`RestClientAdapter` es bloqueante y `WebClientAdapter` devuelve `Mono`/`Flux`. Lo que **no**
decide nada es la parte declarativa: los timeouts y el pool siguen siendo los del cliente de
abajo. Una HTTP Interface sin `ClientHttpRequestFactory` configurada es tan peligrosa como una
llamada cruda sin timeout.

---

### 13 → 11

> Un `@FeignClient` cuya configuración lleva `@Configuration`: ¿qué efecto indeseado tiene?

**⏱️ 30 segundos.** Deja de ser por cliente. Al anotarla con `@Configuration` entra en el
component scan y sus beans —`ErrorDecoder`, `Encoder`, interceptores— se aplican a **todos** los
clientes Feign de la aplicación.

**🗣️ 2 minutos.** La clase que se pasa en `configuration = ...` la instancia Spring Cloud dentro
del contexto hijo de ese cliente concreto, y por eso no debe estar en el paquete escaneado ni
llevar el estereotipo. El síntoma es desconcertante: traduces el 404 de `inv-supplier` a una
excepción de dominio y de pronto el cliente de otro proveedor empieza a lanzarla también. Es el
error más frecuente de Feign y sale en entrevista precisamente porque no lo avisa nadie.

**🔬 El detalle.** Los timeouts de ese cliente van en
`spring.cloud.openfeign.client.config.inv-supplier.connect-timeout`, en milisegundos planos y no
en `Duration` como en `spring.http.client.*`. Y si no los pones, el default de Feign es 10 s de
conexión y 60 s de lectura: peor que no tener ninguno, porque parece configurado.

---

### 13 → 12

> ¿Por qué un `RestClient` por dependencia externa y no uno compartido? ¿Qué síntoma delata la
> elección equivocada?

**⏱️ 30 segundos.** Porque cada cliente lleva su `ClientHttpRequestFactory` y, con ella, **su
propio pool y sus propios timeouts**. Uno por dependencia aísla: si un proveedor se degrada agota
su pool y no el del vecino.

**🗣️ 2 minutos.** El síntoma de haberlo compartido es inconfundible: una dependencia lenta hunde
llamadas a otra que está perfectamente sana, porque las dos compiten por las mismas conexiones y
por el mismo presupuesto de tiempo. Un cliente compartido solo se justifica cuando todas las
salidas tienen el mismo perfil de latencia, que casi nunca ocurre. Lo que sí se comparte bien son
los interceptores transversales —`traceId`, correlación—, y para eso está `RestClientCustomizer`,
que los aplica a todos los builders sin duplicar código.

**🔬 El detalle.** `RestClient.Builder` es un bean `prototype`: cada punto de inyección recibe uno
nuevo, así que la decisión no es "cuántos builders" sino cuántos `RestClient` declaras como
`@Bean`. Construirlos dentro de cada `@Service` multiplica pools que nadie está contando, y es la
razón por la que un servicio abre cuatrocientas conexiones sin que aparezca en ninguna
configuración.

---

### 13 → 13

> Tu test con `MockRestServiceServer` pasa y el servicio se cuelga por un proveedor lento:
> ¿por qué no lo detectó?

**⏱️ 30 segundos.** Porque `MockRestServiceServer` sustituye la `ClientHttpRequestFactory` por
una falsa: no hay socket, así que no hay timeout ni pool que ejercer.

**🗣️ 2 minutos.** Ese doble es excelente para lo que sí hace: verificar que llamas a la URI
correcta, con el método correcto y con el cuerpo correcto, y hacerlo en milisegundos y sin red.
Lo que no puede reproducir es el incidente de la §2 del capítulo, que es exactamente la capa que
el mock reemplaza. Para eso hacen falta `MockWebServer` o WireMock, que abren un puerto de
verdad y pueden inyectar latencia y cortar la conexión a medias.

**🔬 El detalle.** La regla práctica: el mock de request factory prueba el **contrato**, el
servidor falso prueba el **comportamiento en el tiempo**. Los dos se usan, en niveles distintos
de la pirámide. El mecanismo de cada uno está en `24` y la reproducción con latencia inyectada,
en `L05`.

---

## Capítulo 14 — Tiempo real: SSE y WebSocket

### 14 → 1

> "Para tiempo real se usa WebSocket": corrige la afirmación y di qué eliges por defecto y por qué.

**⏱️ 30 segundos.** Por defecto SSE: es HTTP normal, cubre el caso servidor → cliente —que es
la mayoría—, atraviesa filtros, proxies y balanceadores sin nada especial, y reconecta solo con
`Last-Event-ID`. WebSocket solo cuando el cliente también tiene que empujar con baja latencia.

**🗣️ 2 minutos.** WebSocket empieza como un `GET` y tras el `101` deja de ser HTTP: no hay
códigos de estado, ni caché, ni `@ControllerAdvice`, ni `ProblemDetail`, y la conexión pasa a
tener estado, lo que obliga a un broker externo en cuanto hay dos réplicas. Todo eso se paga a
cambio de un canal bidireccional, y si el cliente solo escucha —un tablero, notificaciones, el
avance de un batch— se paga por nada. En banca, la mayoría de los "necesitamos WebSocket" son un
`SseEmitter` con `id` en cada evento.

**🔬 El detalle.** En Spring MVC un `SseEmitter` no retiene hilo: el `DispatcherServlet` arranca
el modo asíncrono y devuelve el hilo al pool. Con virtual threads activados el argumento de
"MVC bloquea" tampoco aplica. La comparación de las cuatro opciones del protocolo —sondeo, sondeo
largo, SSE, WebSocket— vive en el corpus de HTTP y protocolos; el capítulo `14` cubre lo que hace
Spring con las dos que valen la pena.

---

### 14 → 2

> Devuelves un `SseEmitter` desde un `@GetMapping`. ¿Qué hilo suelta Spring, en qué momento, y qué
> tres cosas retiene por cliente mientras el stream sigue abierto?

**⏱️ 30 segundos.** Suelta el hilo de Tomcat —`http-nio-8080-exec-*`— **en el `return`**: el
`DispatcherServlet` llama a `request.startAsync()` y devuelve el hilo al pool. Lo que queda
retenido por cliente es un `AsyncContext`, la conexión del conector y el buffer de salida de esa
respuesta; cero hilos.

**🗣️ 2 minutos.** Es el mecanismo de `08` §9 —la API asíncrona de Servlet— con el formato
`text/event-stream` puesto. Quien escribe después es otro hilo, el del publicador, con
`emitter.send(...)`. La consecuencia práctica es que el límite que se agota con mil tableros no
son los 200 hilos de Tomcat sino sus 8 192 `max-connections`, y que un `Set` de emitters sin
`onCompletion` crece con cada cliente que se fue.

---

### 14 → 3

> Un stream SSE se corta cada 30 segundos en producción y no en tu máquina. ¿Qué default actúa y dónde se corrige?

**⏱️ 30 segundos.** El timeout del request asíncrono. `new SseEmitter()` sin argumento hereda
`spring.mvc.async.request-timeout`, y si esa propiedad no está, el default del contenedor: **30
segundos en Tomcat**, que es el de la especificación Servlet.

**🗣️ 2 minutos.** Se corrige en el constructor —`new SseEmitter(300000L)`, en milisegundos— o
globalmente con `spring.mvc.async.request-timeout`. Que en tu máquina no se corte suele ser que
el cliente local reconecta tan rápido con `Last-Event-ID` que no lo notas; en producción, sin
`id` en los eventos, cada corte es un cliente nuevo y se pierde lo emitido en el hueco. Al
vencer, Spring lanza `AsyncRequestTimeoutException` y ejecuta el `onTimeout` que hayas
registrado; sin él, el emitter queda completado y el siguiente `send()` lanza
`IllegalStateException`.

---

### 14 → 4

> ¿Para qué sirve el `id` de un evento SSE y qué se pierde si no lo pones?

**⏱️ 30 segundos.** Es lo que hace útil la reconexión automática: el navegador reintenta solo
tras un corte y manda el último `id` recibido en la cabecera `Last-Event-ID`, y el endpoint
reemite desde ahí. Sin `id`, la reconexión es un cliente nuevo y los eventos del hueco se pierden.

**🗣️ 2 minutos.** En MVC se pone con `SseEmitter.event().id(...)`; en WebFlux, con
`ServerSentEvent.builder(e).id(...)`. Lo que Spring no hace por ti es el otro lado: leer
`Last-Event-ID` como `@RequestHeader` y tener de dónde reemitir, que exige que los eventos
recientes estén guardados en algún sitio —una tabla, un stream de Redis—, no solo en el `Set`
de emitters. Sin esa segunda mitad, el `id` es decoración.

---

### 14 → 5

> ¿Por qué `send()` sobre un `SseEmitter` puede frenar al hilo que publica, y cómo se acota?

**⏱️ 30 segundos.** Porque `send()` escribe directamente en el socket del cliente desde el hilo
que lo llama: si ese cliente lee lento, la escritura bloquea al publicador, y un `for` sobre
todos los emitters se queda parado en el tablero colgado.

**🗣️ 2 minutos.** El hilo que publica suele ser un `@Async`, un listener de evento de `18` o un
consumidor de cola, y ninguno de ellos debería depender de la velocidad de lectura de un
navegador. Se acota publicando por cliente en un executor propio, o con una cola acotada por
emitter que descarte o cierre cuando se llena. Es el mismo problema que en WebSocket resuelve
`ConcurrentWebSocketSessionDecorator` con sus dos límites, y que en WebFlux aparece como
backpressure sobre un `Sinks.many()` que no puede frenar al productor.

---

### 14 → 6

> En WebFlux, ¿qué pasa con el `Flux` cuando el cliente cierra, y por qué en MVC se descubre de otra forma?

**⏱️ 30 segundos.** Netty cancela la suscripción y el operador aguas arriba deja de producir: la
cancelación es gratis. En MVC no hay suscripción que cancelar; Spring se entera cuando el siguiente
`send()` lanza una `IOException`.

**🗣️ 2 minutos.** Desde Spring 6.1 esa `IOException` llega envuelta como
`AsyncRequestNotUsableException` y se registra en `DEBUG`, no como error de aplicación, y en tu
código se traduce en `completeWithError(e)` para que dispare `onCompletion` y saque el emitter
del `Set`. La diferencia de modelo es la de `11`: en reactivo el ciclo de vida de la conexión y el
del `Flux` son el mismo objeto; en servlet son dos cosas que tú tienes que mantener alineadas.

---

### 14 → 7

> ¿Qué parte de una conexión WebSocket cruza la cadena de filtros de Security y qué parte no?

**⏱️ 30 segundos.** Solo el handshake: es un `GET` normal que pasa por todos los filtros —Security
incluido— y ahí se decide el `Principal`. Después del `101` los frames ya no son HTTP y **ningún
filtro los ve**.

**🗣️ 2 minutos.** Eso tiene dos consecuencias. La buena: no se vuelve a autenticar en cada
mensaje, el `Principal` queda en la sesión WebSocket y cada frame lo lleva puesto. La incómoda:
todo lo que vive en la cadena —tu filtro de correlación, `@ControllerAdvice`, `ProblemDetail`— no
existe para los mensajes; en WebSocket crudo el error es `handleTransportError` y en STOMP,
`@MessageExceptionHandler`. Y si el `Principal` no viene del handshake —el caso del navegador con
JWT— hay que ponerlo a mano en el `CONNECT` de STOMP con un `ChannelInterceptor`.

---

### 14 → 8

> ¿Por qué existe `ConcurrentWebSocketSessionDecorator`, qué protegen sus dos números y qué
> excepción produce cuando se superan?

**⏱️ 30 segundos.** Porque la sesión JSR-356 no admite envíos concurrentes: dos hilos en
`sendMessage` a la vez producen un `IllegalStateException` del contenedor. El decorador serializa
los envíos, y sus dos números —`sendTimeLimit` y `bufferSizeLimit`— acotan cuánto puede esperar y
acumular un cliente lento antes de que **cierre la sesión** con `SessionLimitExceededException`.

**🗣️ 2 minutos.** El valor de cerrar es que el publicador nunca se queda bloqueado por un tablero
colgado: la alternativa es que un cliente que no drena retenga a quien escribe para todos los
demás. Los valores de la documentación son 10 s y 512 KB, y son por sesión, así que el buffer
máximo que puede retener el servidor es ese número multiplicado por las sesiones abiertas. El
detalle que muerde: lo que guardas en tu `Set` es el decorador, no la sesión original, así que en
`afterConnectionClosed` se elimina por `getId()`, no con `remove(session)`.

---

### 14 → 9

> Distingue lo que va a `/app/**` de lo que va a `/topic/**` en STOMP, y di cuál de los dos pasa por tu código.

**⏱️ 30 segundos.** `/app` es el prefijo de aplicación: un `SEND` a `/app/movements` llega a tu
`@MessageMapping("/movements")`. `/topic` y `/queue` son prefijos del broker: un `SEND` a
`/topic/inventory` va directo al broker y se reparte a los suscritos **sin pasar por tu código**.

**🗣️ 2 minutos.** Por eso importa qué expones: si un cliente puede hacer `SEND` a `/topic/**`,
puede publicar a todos los demás sin validación ni autorización tuya. La respuesta correcta es
que el cliente solo envíe a `/app/**`, que el método valide y que sea el servidor quien publique
al broker con `@SendTo` o con `SimpMessagingTemplate`; y con `spring-security-messaging`, una
regla que deniegue `SEND` sobre `/topic/**`. El `Principal` del método viene del handshake, no
del frame.

---

### 14 → 10

> ¿En qué hilo corre un `@MessageMapping`, cuántos hay por defecto y qué pasa con la cola cuando
> todos están ocupados?

**⏱️ 30 segundos.** En un hilo del `clientInboundChannel` —`clientInboundChannel-N`—, no en uno
de Tomcat. Su `ThreadPoolTaskExecutor` tiene por defecto **2 × procesadores** hilos y una cola de
`Integer.MAX_VALUE`: cuando todos están ocupados no rechaza, **encola sin techo**.

**🗣️ 2 minutos.** Es la cola traicionera de `18` §4 con otro nombre: un `@MessageMapping` que
llama a la base con los hilos ocupados no falla, se retrasa, y la latencia crece sin ninguna
excepción que lo delate. Se ajusta en `configureClientInboundChannel` con
`registration.taskExecutor().corePoolSize(…)` y una cola acotada. La consecuencia colateral es
que el `SecurityContextHolder` de `20` está vacío en ese hilo: el usuario es el `Principal` que
recibe el método, no el `ThreadLocal`.

---

### 14 → 11

> Con dos réplicas, la mitad de los usuarios no recibe las alertas. ¿Qué componente es el
> culpable, y cuál es la corrección para STOMP y cuál para SSE?

**⏱️ 30 segundos.** El broker simple en memoria: guarda las suscripciones en la JVM de su
instancia, así que lo que publica la réplica B no llega a los suscritos en la A. Para STOMP,
`enableStompBrokerRelay` hacia un broker externo; para SSE, publicar los eventos en Redis
pub/sub y que cada instancia los reemita a sus propios emitters.

**🗣️ 2 minutos.** El síntoma es intermitente porque depende de a qué instancia te asignó el
balanceador, y se descubre en producción, nunca en local con una instancia. El relay abre una
conexión TCP por cliente más una de "sistema" hacia RabbitMQ o ActiveMQ y necesita
`reactor-netty` en el classpath aunque la aplicación sea MVC sobre Tomcat. Es el veredicto de
`17` con la caché: en memoria mientras haya una instancia, fuera en cuanto hay dos, y decidido
desde el primer día porque migrar después obliga a tocar cada cliente.

**🔬 El detalle.** La afinidad de sesión en el balanceador **no** resuelve esto: garantiza que un
cliente vuelva siempre a la misma instancia, no que las publicaciones de otra instancia le
lleguen. Sirve para el fallback HTTP de SockJS, no para el reparto de mensajes.

---

### 14 → 12

> El navegador no puede poner `Authorization` en el handshake. ¿Dónde viaja entonces el JWT y qué
> componente de Spring lo valida?

**⏱️ 30 segundos.** En una cabecera nativa del frame `CONNECT` de STOMP —que el navegador sí
puede escribir—, y lo valida un `ChannelInterceptor` registrado en `configureClientInboundChannel`:
en `preSend`, solo para `StompCommand.CONNECT`, lee la cabecera con `getFirstNativeHeader`,
autentica y hace `accessor.setUser(auth)`.

**🗣️ 2 minutos.** Desde ese `setUser` el `Principal` queda en la sesión y todos los frames
posteriores lo llevan; si la validación lanza, el cliente recibe un frame `ERROR` y la conexión se
cierra. La alternativa de meter el token en la query del handshake funciona, pero deja el JWT en
los logs de acceso del balanceador y del proxy. Cuando el cliente no es un navegador —otro
servicio, una app móvil— sí puede poner `Authorization` en el handshake y la cadena de filtros de
`20` lo resuelve sin nada de esto.

---

### 14 → 13

> `@EnableWebSocketSecurity` rechaza todos tus `CONNECT`. ¿Qué exige por defecto y cuándo es legítimo prescindir de ello?

**⏱️ 30 segundos.** Exige un token CSRF válido en cada `CONNECT`, porque el handshake hereda la
cookie de sesión y está expuesto al mismo ataque que cualquier `POST` con cookie. Es legítimo
prescindir de ello cuando la sesión es `STATELESS` y la credencial viaja en el propio `CONNECT`,
que no se adjunta sola.

**🗣️ 2 minutos.** Es la misma decisión que `20` §11 para `csrf.disable()` en una API con
`Bearer`: la protección tiene sentido cuando el navegador adjunta la credencial por su cuenta, y
deja de tenerlo cuando la pone tu código. En Spring Security 6.5 la forma documentada de
desactivarlo es no usar `@EnableWebSocketSecurity` y registrar los componentes de mensajería a
mano, sin el interceptor CSRF. Y con la anotación puesta, el bean `AuthorizationManager<Message<?>>`
se cierra siempre con `anyMessage().denyAll()`, porque lo que no casa con ninguna regla pasa.

---

### 14 → 14

> Los clientes WebSocket se desconectan cada 60 segundos sin error en tu log. ¿Qué dos números hay que cotejar?

**⏱️ 30 segundos.** El *idle timeout* del balanceador —60 s en un ALB— y el intervalo de latidos
de STOMP. Si el primero vence antes de que llegue un latido, el balanceador corta la conexión
silenciosa y parece un bug de red.

**🗣️ 2 minutos.** Con el broker relay los latidos vienen por defecto, a 10 s en cada sentido;
con el broker simple **no hay latidos** salvo que le des un `TaskScheduler` con
`setHeartbeatValue`, y ese es el caso típico del "en local funciona": no hay balanceador que
corte. Para SSE el mecanismo es el mismo —un comentario `:` periódico mantiene viva la
respuesta— y el número que se coteja es también el del balanceador.

---

## Capítulo 15 — Datos: JDBC, JPA, Mongo y Redis

### 15 → 1

> ¿Qué límite real impone `maximum-pool-size` sobre un Tomcat con 200 hilos?

**⏱️ 30 segundos.** Impone el techo de requests que pueden estar tocando la base a la vez:
con `maximum-pool-size: 10`, como mucho 10 de esos 200 hilos tienen conexión; el resto
espera en la cola del pool hasta que alguno la devuelva o hasta que salte el
`connection-timeout`.

**🗣️ 2 minutos.** Los 200 hilos de Tomcat son el límite de requests *aceptados*, no de
requests *productivos*. El pool es el cuello de botella real de cualquier endpoint que toque
Postgres, y por eso los dos números hay que mirarlos juntos: 200 hilos contra 10 conexiones
significa que, si todos los endpoints van a la base, 190 hilos están parados consumiendo
memoria sin hacer nada. Cuando el tiempo de espera supera `connection-timeout`, el hilo se
rinde con `SQLTransientConnectionException: HikariPool-1 - Connection is not available`. La
conclusión práctica no es subir el pool, es reducir el tiempo que cada request retiene su
conexión.

---

### 15 → 2

> Proponen subir el pool de 10 a 100 porque el servicio va lento: da dos razones técnicas
> para no hacerlo y di qué medirías en su lugar.

**⏱️ 30 segundos.** Primera: cada conexión de Postgres es un proceso con su memoria, y la
base no ejecuta más consultas en paralelo que núcleos y discos tenga, así que 100 conexiones
compiten por los mismos 4 núcleos y cada consulta tarda más. Segunda: el tamaño no es el
síntoma —el síntoma es el tiempo de retención—, y subirlo solo mueve la cola de mi
aplicación a la base. Yo mediría cuánto tiempo retiene cada request su conexión.

**🗣️ 2 minutos.** La referencia de HikariCP es `conexiones ≈ (núcleos × 2) + spindles`:
entre 8 y 12 en una máquina de 4 núcleos con SSD. Con un pool de 100 el timeout sigue
saltando, solo que más tarde y con la base de rodillas, y encima has trasladado la
saturación a un componente compartido por todos los servicios. Lo que hay que buscar es la
causa de la retención, que casi siempre es una de cuatro: una transacción que abarca una
llamada HTTP saliente, `open-in-view` dejando la sesión abierta hasta el último byte de la
respuesta, una consulta sin índice, o una transacción anidada que toma una segunda conexión
mientras la primera sigue abierta.

**🔬 El detalle.** Se mide con `hikaricp.connections.usage` (distribución del tiempo de
retención), `hikaricp.connections.pending` (hilos esperando ahora) y
`hikaricp.connections.acquire`. Y `leak-detection-threshold` imprime el stack trace del
culpable cuando alguien pasa del umbral, que es la forma más rápida de encontrar el método.

---

### 15 → 3

> Nombra las cuatro cosas que retienen una conexión del pool más de lo necesario.

**⏱️ 30 segundos.** Una transacción que abarca una llamada HTTP a un tercero; `open-in-view`
en `true`, que mantiene la sesión abierta durante toda la serialización; una consulta lenta
o sin índice; y una transacción anidada que toma una segunda conexión mientras la primera
sigue abierta.

**🗣️ 2 minutos.** Las cuatro tienen el mismo patrón: tiempo de pared dentro de la ventana en
que la conexión está tomada. La peor es la primera, porque el tiempo lo decide un sistema
que no controlas: si `inv-supplier` tarda 30 segundos, tú retienes la conexión 30 segundos.
La segunda es traicionera porque es el default de Boot y no se nota hasta que un cliente
lento o una respuesta grande ocupan una conexión el tiempo entero de la respuesta. La cuarta
es la de `16`: con `REQUIRES_NEW` un solo request consume dos conexiones del pool, y con un
pool pequeño eso es un deadlock esperando a ocurrir.

---

### 15 → 4

> ¿Cuándo eliges `JdbcClient` sobre un repositorio de Spring Data JPA, y al revés?

**⏱️ 30 segundos.** `JdbcClient` cuando el SQL es el producto: reportes con varios `JOIN`,
agregaciones, `INSERT ... ON CONFLICT`, cargas masivas, cualquier consulta que el DBA quiera
revisar. JPA cuando el producto es el grafo de objetos y su ciclo de vida: entidades que se
cargan, se modifican y se guardan con dirty checking.

**🗣️ 2 minutos.** No es una decisión de proyecto, es una decisión por caso de uso, y conviven
sobre el mismo `DataSource` y dentro de la misma transacción. `JdbcClient` (Spring Framework
6.1, Boot 3.2) unifica `JdbcTemplate` y `NamedParameterJdbcTemplate` en una API fluida:
`sql(...).param(...).query(Clase.class).list()`, con mapeo automático a un `record`. JPA te
da el persistence context y te quita el control del SQL; cuando lo que necesitas es el
control del SQL, pelearte con JPQL nativo para acabar donde `JdbcClient` te dejaba desde el
principio es el peor de los dos mundos.

**🔬 El detalle.** El criterio operativo: si estás escribiendo `@Query(nativeQuery = true)`,
ya decidiste que el SQL es el producto — y en `JdbcClient` al menos nadie espera un grafo de
objetos gestionado ni te sorprende un flush a destiempo.

---

### 15 → 5

> ¿Para qué existe `DataAccessException` si el driver ya lanzaba `SQLException`?

**⏱️ 30 segundos.** Para desacoplar tu código del motor. El driver expresa los errores con
`SQLState` y códigos propios —`23505` en Postgres, `ORA-00001` en Oracle—, y capturar eso
casa tu servicio con la base. Spring lo traduce a una jerarquía propia y no chequeada, con
significado semántico: `DuplicateKeyException`, `CannotAcquireLockException`,
`OptimisticLockingFailureException`.

**🗣️ 2 minutos.** La traducción es automática en `JdbcClient`, en `JdbcTemplate` y en los
repositorios de Spring Data; en un `@Repository` propio con JDBC crudo la activa un
`BeanPostProcessor` que envuelve el bean en un proxy, o sea el mismo mecanismo de `05`. Y
que sean `RuntimeException` no es comodidad: es coherencia con el modelo transaccional,
porque el rollback por defecto se dispara con `RuntimeException` y una `SQLException`
chequeada no lo haría. En la práctica, las dos que sí se capturan son `DuplicateKeyException`
—porque tiene traducción a dominio: es tu 409— y `CannotAcquireLockException`, porque marca
un fallo reintentable.

---

### 15 → 6

> Explica por qué "Spring Data JPA es Hibernate con menos código" te deja mal parado.

**⏱️ 30 segundos.** Porque no son la misma capa. Spring Data JPA es una capa de repositorios
**encima** de JPA; el proveedor sigue siendo Hibernate, y es Hibernate quien decide el SQL,
gestiona el persistence context y elige cuándo hacer flush. Spring Data te ahorra escribir
el `EntityManager`, no te ahorra entender a Hibernate.

**🗣️ 2 minutos.** La respuesta corta suena a que el ahorro es de esfuerzo cuando en realidad
es de código repetitivo, y eso te deja sin explicación para los tres problemas que llegan
después: el N+1, el `LazyInitializationException` y el dirty checking que emite un `UPDATE`
que tú no pediste. Los tres son de Hibernate, no de Spring Data, y quien cree que el
repositorio es la única capa no sabe dónde mirar. Lo que Spring Data sí aporta es propio y
vale la pena nombrarlo: la generación del repositorio en el arranque —un `FactoryBean` que
crea un proxy—, las derived queries parseadas al arrancar, las proyecciones, `Pageable` y la
misma abstracción para Mongo o Redis.

**🔬 El detalle.** Que las derived queries se parseen en el arranque es un regalo: una
propiedad mal escrita rompe el contexto con `PropertyReferenceException: No property
'warehous' found for type 'InventoryItem'` en el `mvn test`, no en producción.

---

### 15 → 7

> ¿Qué hace `@Modifying(clearAutomatically = true)` y qué pasa si omites ese atributo?

**⏱️ 30 segundos.** `@Modifying` le dice a Spring Data que la `@Query` es un `UPDATE` o
`DELETE` y no un `SELECT` —sin él falla—, y `clearAutomatically = true` vacía el persistence
context después de ejecutarla. Si lo omites, las entidades que ya estaban cargadas se quedan
con el valor viejo, porque el `UPDATE` masivo pasó por encima de Hibernate.

**🗣️ 2 minutos.** Una consulta de modificación en JPQL se traduce a un `UPDATE` directo
contra la base: no carga entidades, no dispara dirty checking y no actualiza nada de lo que
ya estuviera en el persistence context. Si en la misma transacción tenías un `InventoryItem`
cargado y después llamas a `addQuantity`, tu instancia en memoria sigue con la cantidad
anterior; peor aún, si la tocas, el dirty checking puede emitir un `UPDATE` de vuelta al
valor viejo en el flush. `clearAutomatically` evita eso vaciando la caché de primer nivel, y
su pariente `flushAutomatically = true` vuelca antes de ejecutar, para que los cambios
pendientes no se pierdan por el orden.

---

### 15 → 8

> Cambias un campo de una entidad en una transacción y no llamas a `save()`: ¿se guarda?

**⏱️ 30 segundos.** Sí. Si la entidad está *managed* —la cargaste dentro de la transacción—,
el dirty checking de Hibernate compara el estado actual contra el snapshot que guardó al
cargarla y emite el `UPDATE` en el flush. `save()` no hace falta.

**🗣️ 2 minutos.** Esto sorprende a mucha gente y es la mitad del valor de entender el
persistence context. La entidad está vigilada mientras la transacción viva; al final,
Hibernate hace flush, detecta la diferencia y escribe. Y tiene dos corolarios útiles: uno,
que `@Transactional(readOnly = true)` ahorra ese snapshot y desactiva el dirty checking, que
es ahorro real de memoria en lecturas grandes; dos, que si la entidad está *detached*
—porque la transacción terminó— el cambio no se guarda, y ahí sí hace falta pasar por
`merge()`, recordando que `merge()` devuelve **una copia gestionada** y que hay que seguir
trabajando con el valor retornado, no con la instancia original.

---

### 15 → 9

> `spring.jpa.show-sql=true` no te dejó ver el N+1: ¿qué configuras en su lugar?

**⏱️ 30 segundos.** `logging.level.org.hibernate.SQL=DEBUG` para que las sentencias salgan
por el logger real, `logging.level.org.hibernate.orm.jdbc.bind=TRACE` para ver el valor de
cada parámetro, y `spring.jpa.properties.hibernate.generate_statistics=true` para que al
cerrar la sesión te diga cuántas consultas corrieron.

**🗣️ 2 minutos.** `show-sql` escribe a `System.out`: sin `traceId`, sin timestamp, sin el
formato de la aplicación y sin agrupar, así que en un agregador de logs es ruido y no te dice
cuántas veces corrió la misma sentencia — que es justo el dato del N+1. Con el logger de
Hibernate cada sentencia lleva el contexto del MDC y se puede correlacionar con el request.
`generate_statistics` es lo que convierte "parece lento" en "veintiuna consultas para un
endpoint", que ya es un número que se puede defender en una reunión.

**🔬 El detalle.** `org.hibernate.orm.jdbc.bind` es el logger de Hibernate 6; en Hibernate 5
era `org.hibernate.type.descriptor.sql`, y mucha documentación vieja todavía cita ese. Y
ojo: mostrar los parámetros escribe datos personales en el log, así que es una herramienta
de diagnóstico local y no una configuración que se despliega.

---

### 15 → 10

> Diferencia `JOIN FETCH`, `@EntityGraph` y `@BatchSize`, y di cuándo usas cada uno.

**⏱️ 30 segundos.** `@EntityGraph` declara sobre el método derivado qué asociaciones cargar,
sin escribir el `JOIN` y sin duplicar la consulta. `JOIN FETCH` es lo mismo escrito a mano
dentro de una `@Query`, para una consulta concreta. `@BatchSize` no elimina los N `SELECT`:
los agrupa en `N/20` usando `IN (...)`.

**🗣️ 2 minutos.** El orden de preferencia es ese. `@EntityGraph` es la opción limpia porque
el método sigue siendo derivado y `attributePaths` nombra propiedades de la entidad —admite
rutas anidadas como `"warehouse.region"`—. `JOIN FETCH` es para cuando ya estás escribiendo
la consulta a mano; cuidado con hacerlo sobre dos colecciones a la vez, porque produce un
producto cartesiano que se infla en memoria: una colección por consulta. `@BatchSize` es la
red de seguridad en el mapeo, para colecciones que siempre se terminan recorriendo: de 200
consultas pasas a 10, que no es óptimo pero es un orden de magnitud. Y lo que **no** es
solución es poner `FetchType.EAGER`: mueve el problema, porque entonces todas las consultas
cargan la asociación, incluida la que no la necesita.

**🔬 El detalle.** El default de `@ManyToOne` y `@OneToOne` es `EAGER` por la especificación
de JPA, y el de `@OneToMany` y `@ManyToMany` es `LAZY`. Ponerlo explícitamente en `LAZY` en
los dos primeros es casi siempre lo correcto, y decidir la carga en cada consulta.

---

### 15 → 11

> `open-in-view` viene en `true`: di qué cuesta en runtime y qué se rompe al apagarlo.

**⏱️ 30 segundos.** Cuesta la conexión del pool retenida hasta el último byte de la
respuesta, no hasta el commit. Al apagarlo se rompe todo lo que tocaba una asociación `LAZY`
fuera del servicio, con `LazyInitializationException` — que es exactamente lo que quieres que
falle, y en el test y no en producción.

**🗣️ 2 minutos.** Con `open-in-view: true` la sesión de Hibernate vive todo el request, así
que un cliente lento o una respuesta de 2 MB ocupan una de tus diez conexiones ese tiempo
entero y el pool se agota con una carga que la base ni siente. Hay un segundo costo menos
conocido: las consultas que dispare la serialización corren **fuera de transacción**, cada
una en su propio autocommit, de modo que el endpoint puede devolver un estado que nunca
existió a la vez en la base. La corrección al apagarlo no es volver a encenderlo: es decidir
en el servicio qué datos necesita la respuesta y traerlos con `@EntityGraph` o con una
proyección, y devolver un DTO en vez de la entidad. Y conviene decir que apagarlo **no**
arregla el N+1: lo hace visible. Son problemas distintos con la misma raíz, que es no haber
decidido qué cargar.

**🔬 El detalle.** Boot lo avisa en el arranque con un `WARN` de
`JpaBaseConfiguration$JpaWebConfiguration` diciendo que "database queries may be performed
during view rendering". Es el único default de Boot que se queja de sí mismo, y la razón de
que siga activo es la compatibilidad hacia atrás, no una recomendación.

---

### 15 → 12

> Tus claves de Redis aparecen ilegibles en `redis-cli`: ¿qué pasó y cómo se arregla?

**⏱️ 30 segundos.** Un `RedisTemplate` construido a mano usa `JdkSerializationRedisSerializer`
por defecto, así que la clave se guarda como el resultado de la serialización binaria de Java
y sale como `\xac\xed\x00\x05t\x00...`. Se arregla usando `StringRedisTemplate`, que Boot ya
autoconfigura, o fijando `setKeySerializer(new StringRedisSerializer())`.

**🗣️ 2 minutos.** El problema no es estético: con claves binarias no puedes buscar con
`KEYS 'inv:*'`, no puedes poner un TTL desde la consola, y ningún servicio que no sea Java
puede leer esa clave — lo que rompe cualquier caché compartida entre equipos. Para los
valores, el consejo es equivalente pero por otra razón: la serialización JDK ata el valor a
la clase Java y a su versión, así que añadir un campo hace que todo lo cacheado reviente con
`SerializationException` al deserializar. Por eso los valores van en JSON, con un
serializador explícito.

**🔬 El detalle.** Si tus valores son `String` o JSON, lo más barato es no declarar nada e
inyectar el `StringRedisTemplate` que Boot autoconfigura: ya trae `StringRedisSerializer` en
clave y valor. El prefijo de claves del lab es `inv:`, precisamente para que se puedan
listar y borrar desde `redis-cli` sin adivinar.

---

### 15 → 13

> Da tres razones para no usar `ddl-auto=update` ni siquiera al principio de un proyecto.

**⏱️ 30 segundos.** Una: solo sabe añadir; nunca borra, renombra ni cambia un tipo, así que
tu esquema acumula columnas muertas. Dos: no hay forma de revisar el DDL antes de que corra
ni constancia de qué corrió en cada entorno. Tres: el resultado depende del orden en que se
desplegaron las versiones, o sea que dos entornos pueden acabar distintos.

**🗣️ 2 minutos.** La razón de fondo es que el esquema es código y merece revisión, versión y
trazabilidad desde el primer día. "Empezar con `update`" significa que dentro de seis meses
alguien tendrá que adoptar Flyway sobre una base cuyo esquema nadie escribió a propósito, y
esa migración es mucho más cara que haberlo hecho bien desde la primera tabla. En banca hay
además una razón administrativa que zanja la discusión: la cuenta con la que corre la
aplicación no tiene permisos de DDL, así que `update` ni siquiera arrancaría. La postura del
curso es `ddl-auto: validate` con Flyway delante: Flyway crea el esquema, Hibernate comprueba
que las entidades encajan y rompe el arranque si no.

---

### 15 → 14

> Editas un `V2__` que ya se aplicó en pruebas: ¿qué hace Flyway al arrancar de nuevo?

**⏱️ 30 segundos.** Falla el arranque con `Migration checksum mismatch`. Flyway guarda en
`flyway_schema_history` el checksum de cada migración aplicada y lo compara al arrancar; si
cambió, se niega a seguir. Lo correcto era no tocar el `V2__` y añadir un `V3__` con la
corrección.

**🗣️ 2 minutos.** Ese fallo es una funcionalidad, no una molestia: garantiza que el esquema
de pruebas y el de producción se construyeron con exactamente el mismo SQL. Si se permitiera
editar migraciones aplicadas, dos entornos con el mismo número de versión podrían tener
esquemas distintos y nadie se enteraría. La regla práctica es que una migración versionada
es inmutable en cuanto sale de tu máquina. Para lo que sí cambia con frecuencia —vistas,
funciones, datos de catálogo— están las *repeatable* `R__`, que no llevan versión y se
vuelven a ejecutar precisamente cuando su checksum cambia.

**🔬 El detalle.** `flyway repair` reescribe los checksums de la tabla de historial y existe
para casos de emergencia; usarlo como hábito anula la garantía entera. Y
`spring.flyway.baseline-on-migrate=true` es otra cosa: sirve para adoptar Flyway sobre una
base que ya existía, marcando el estado actual como línea base.

---

## Capítulo 16 — Transacciones

### 16 → 1

> ¿Qué parte del trabajo hace la base de datos y qué parte hace Spring cuando anotas un
> método con `@Transactional`?

**⏱️ 30 segundos.** La base garantiza atomicidad, aislamiento y durabilidad. Spring decide
**cuándo** empieza y termina la transacción y **en qué conexión** ocurre todo.

**🗣️ 2 minutos.** Spring no implementa transacciones: implementa una política declarativa
sobre las de tu motor. El proxy lee la anotación, pide al `PlatformTransactionManager` que
abra, y el `TransactionSynchronizationManager` ata esa conexión al hilo para que todo el
código que corra ahí la comparta. Confundir las dos capas es el origen de casi todos los
bugs del capítulo: por ejemplo, creer que `readOnly` impide escribir, o que Spring elige el
nivel de aislamiento.

**🔬 El detalle.** `PlatformTransactionManager` es la interfaz; la implementación depende
del stack: `DataSourceTransactionManager` para JDBC, `JpaTransactionManager` para JPA, y
Boot declara la correcta por autoconfiguración (`06`). El caso en que hay que intervenir es
el de **dos `DataSource`**: entonces hay dos managers candidatos y toca elegir
explícitamente, porque ninguna anotación adivina en cuál de las dos bases querías la
transacción.

---

### 16 → 2

> Explica por qué `@Transactional` puede no hacer absolutamente nada sin que falle nada.

**⏱️ 30 segundos.** Porque es un metadato que solo tiene efecto si la llamada pasa por el
proxy. Sin proxy en medio, la anotación es un comentario, y no hay error ni aviso.

**🗣️ 2 minutos.** Ocurre cuando llamas al método desde la propia clase, cuando es
`private`, `final` o `static`, cuando lo invocas desde `@PostConstruct`, cuando capturas la
excepción dentro, o cuando importaste el `@Transactional` de Jakarta esperando atributos
que no tiene. Los seis son silenciosos: compila, corre y confirma. Por eso la primera
hipótesis ante "la transacción no revirtió" no es la configuración, es el proxy (`05`).

**🔬 El detalle.** De los seis, el único que sí puede hablar es la clase `final`, que con
proxies CGLIB llega a romper el arranque; el método `final` se queda sin interceptar y
callado. Y la hipótesis se confirma o se descarta con un comando, sin debugger: subir a
`TRACE` el log de `org.springframework.transaction.interceptor` y mirar si aparecen las
líneas `Getting transaction for` (pregunta 14).

---

### 16 → 3

> ¿A qué se ata la conexión de una transacción, y qué consecuencia tiene eso para un
> método `@Async`?

**⏱️ 30 segundos.** Al **hilo**, mediante un `ThreadLocal` del
`TransactionSynchronizationManager`. Un `@Async` salta a otro hilo, así que no hereda la
transacción: corre fuera de ella.

**🗣️ 2 minutos.** Es el mismo mecanismo del `SecurityContext` y del MDC (`08`). La
consecuencia práctica es que llamar a un método asíncrono dentro de una transacción no
extiende esa transacción al trabajo asíncrono: lo que escriba el hilo nuevo se confirma o
se revierte por su cuenta. Y al revés, si el hilo asíncrono arranca antes del commit del
primero, puede no ver los datos que estás a punto de confirmar — que es la carrera clásica
del `@Async` disparado desde un método transaccional, y la razón de usar
`@TransactionalEventListener(AFTER_COMMIT)`.

**🔬 El detalle.** Ese listener funciona precisamente porque **no** salta de hilo: corre en
el mismo hilo, después del commit, y por eso ve el dato confirmado. En el momento en que le
añades `@Async` para no bloquear la respuesta, recuperas el problema del principio —otro
hilo, otra transacción, y ni `SecurityContext` ni MDC— y aceptas a cambio que el efecto deje
de estar acoplado al hilo original.

---

### 16 → 4

> ¿Cuándo eliges `TransactionTemplate` en lugar de la anotación? Da un caso concreto.

**⏱️ 30 segundos.** Cuando el límite de la transacción **no coincide con un método**. El
caso canónico es un bucle donde cada iteración debe ser su propia transacción.

**🗣️ 2 minutos.** Importar mil eventos con una sola transacción significa que el evento
novecientos tumba los ochocientos noventa y nueve anteriores. Con `TransactionTemplate`
dentro del bucle, cada uno confirma o falla por su cuenta y el lote continúa. Expresar eso
con anotaciones obliga a extraer un método a otro bean solo para que exista el proxy, lo
que parte la clase por una razón técnica y no de diseño. El otro caso es un bloque pequeño
dentro de un método largo que no debe ser transaccional entero.

**🔬 El detalle.** `status.setRollbackOnly()` permite condenar la transacción sin lanzar
una excepción, que es útil cuando no quieres usar excepciones como control de flujo.

---

### 16 → 5

> Diferencia `REQUIRED` de `REQUIRES_NEW` y di cuántas conexiones del pool consume un
> método que usa la segunda dentro de la primera.

**⏱️ 30 segundos.** `REQUIRED` se une a la transacción existente; `REQUIRES_NEW` la
**suspende** y abre otra independiente. Consume **dos** conexiones a la vez.

**🗣️ 2 minutos.** Suspender no libera la conexión de la transacción externa: queda
retenida mientras la interna trabaja con otra. Con un pool de 10 y seis peticiones
concurrentes por ese camino, las diez conexiones están tomadas y ninguna consigue la
segunda que necesita: deadlock por agotamiento de pool, con un `Connection is not
available` y ni una línea de tu código en el stack trace. `REQUIRES_NEW` se usa para lo que
debe sobrevivir al fallo de fuera —una auditoría—, no como opción "más segura".

**🔬 El detalle.** La cuenta del deadlock: con `maximum-pool-size: 10`, seis peticiones
concurrentes por ese camino ya tienen tomadas las diez conexiones y ninguna puede obtener la
segunda que necesita; nadie avanza y nadie suelta. Y existe una opción intermedia que casi
nadie nombra: `NESTED`, que abre un **savepoint** dentro de la misma transacción física —una
sola conexión— y revierte hasta ahí sin tumbar a la externa. El precio es que necesita
soporte del driver y del `TransactionManager`, y con JPA suele no estar disponible, así que
se comprueba antes de diseñar con él.

---

### 16 → 6

> Un servicio con pool de 10 se queda colgado sin errores en el log de la aplicación,
> acaba lanzando `Connection is not available` y la base no está ejecutando ni una
> consulta. Da dos causas posibles de este capítulo y explica por qué una llamada HTTP
> dentro de la transacción es una de ellas.

**⏱️ 30 segundos.** Un `REQUIRES_NEW` anidado consumiendo dos conexiones por petición, o
una llamada externa lenta dentro de la transacción. La segunda es la contraintuitiva:
aunque la base no esté haciendo nada durante esa espera, **la conexión sigue reservada**
para tu transacción durante todo el round-trip.

**🗣️ 2 minutos.** Las dos tienen la misma firma diagnóstica: la base de datos está ociosa
—no hay consultas lentas que mirar— y aun así no hay conexiones. En el primer caso el
número de conexiones necesarias por petición es el doble del esperado; en el segundo, el
tiempo de retención es el de un servicio externo y no el de una consulta. El recurso
escaso no es la CPU de la base, es el pool: si el proveedor tarda tres segundos y tienes
diez conexiones, diez peticiones concurrentes las agotan mientras el servidor de base de
datos está ocioso — y el síntoma, `Connection is not available`, apunta a la base, que es
inocente. La tercera causa clásica, fuera de este capítulo, es un pool mal dimensionado o
conexiones filtradas, que se caza con `leak-detection-threshold` (`15`).

**🔬 El detalle.** La regla de diseño que sale de aquí es sacar cualquier llamada externa
fuera del límite transaccional: primero se obtiene el dato y después se abre la
transacción, o se confirma y el efecto externo va después del commit.

---

### 16 → 7

> ¿Qué significa `Isolation.DEFAULT`, y por qué el mismo código se comporta distinto en
> Postgres y en MySQL?

**⏱️ 30 segundos.** Significa "el nivel por defecto del motor", no un nivel concreto.
Postgres usa `READ_COMMITTED` y MySQL con InnoDB usa `REPEATABLE_READ`.

**🗣️ 2 minutos.** Con `READ_COMMITTED`, leer dos veces la misma fila dentro de una
transacción puede dar valores distintos si otra confirmó en medio; con `REPEATABLE_READ`,
no. Un código que asume una cosa y se despliega sobre la otra cambia de comportamiento sin
que nadie toque una línea, y es una de las sorpresas típicas de una migración de motor. La
lección es declarar el nivel cuando el código depende de él, en vez de heredarlo.

**🔬 El detalle.** La tabla de niveles es la del estándar ANSI y es un contrato de
**mínimos**: tu motor puede dar más. En Postgres hay dos desviaciones que se preguntan:
`READ_UNCOMMITTED` se comporta como `READ_COMMITTED` —el MVCC nunca enseña una versión sin
confirmar, así que pedir lecturas sucias no te las da— y `REPEATABLE_READ` es **snapshot
isolation**, de modo que evita también los phantom reads que la tabla marca como posibles. Lo
que aparece a cambio es el `could not serialize access due to concurrent update`, que tu
código tiene que estar dispuesto a reintentar.

---

### 16 → 8

> Tu método lanza una `IOException` y los datos se guardaron igual. ¿Por qué, y cuáles son
> las dos formas de corregirlo?

**⏱️ 30 segundos.** Porque por defecto Spring solo revierte ante `RuntimeException` y
`Error`; una excepción comprobada **confirma**. Se corrige con `rollbackFor` o envolviendo
la excepción en una no comprobada.

**🗣️ 2 minutos.** La regla viene de la tradición de EJB y sorprende a todo el mundo la
primera vez, porque intuitivamente "si lanzó, no se guarda". `@Transactional(rollbackFor =
Exception.class)` amplía la regla al método concreto; la alternativa de diseño es no dejar
que las excepciones comprobadas de infraestructura suban hasta la capa de servicio y
traducirlas a excepciones de dominio no comprobadas, que además es lo que hace
`@Repository` con las de acceso a datos (`02`).

**🔬 El detalle.** El par completo es `rollbackFor`, que amplía la regla, y `noRollbackFor`,
que la reduce para excepciones que usas como control de flujo y no como fallo. Aviso cruzado
con la pregunta 13: si el import es el de `jakarta.transaction`, esos atributos existen con
otros nombres —`rollbackOn` y `dontRollbackOn`—, así que el `rollbackFor` que ibas a escribir
ni siquiera compila.

---

### 16 → 9

> ¿Por qué un `try/catch` dentro de un método transaccional puede convertir un rollback en
> un commit?

**⏱️ 30 segundos.** Porque quien decide el rollback es el proxy, y el proxy solo ve las
excepciones que **salen** del método. Si la capturas, para él todo salió bien.

**🗣️ 2 minutos.** Es el fallo más frecuente del capítulo y el más difícil de ver en una
revisión, porque el `catch` suele tener buena intención: loguear y continuar. El resultado
es una transacción que confirma un estado a medias. Si de verdad quieres capturar y no
guardar, la forma correcta es marcar la transacción con `setRollbackOnly()` o volver a
lanzar. Capturar `Exception` para que "no truene" es un antipatrón con nombre propio.

**🔬 El detalle.** El caso límite que lo distingue de la pregunta 10: capturar no siempre
compra el commit. Si la excepción venía de un método interno `REQUIRED` —misma transacción
física—, su proxy ya marcó la transacción como rollback-only antes de que tú la capturaras, y
lo que consigues no es confirmar, es un `UnexpectedRollbackException` en el commit, lejos del
`catch` que lo causó.

---

### 16 → 10

> Explica el mensaje `Transaction silently rolled back because it has been marked as
> rollback-only`: ¿quién lo marcó y por qué aparece en un método que no falló?

**⏱️ 30 segundos.** Lo marcó una transacción interna que falló y cuya excepción alguien
capturó. El de fuera intenta confirmar, encuentra la marca y revienta en el commit.

**🗣️ 2 minutos.** La secuencia es: método externo `REQUIRED` llama a interno `REQUIRED`
—misma transacción física—, el interno lanza, el proxy interno marca la transacción como
rollback-only, y el externo captura la excepción y sigue como si nada. Al llegar el commit,
el `TransactionManager` se niega. Lo desconcertante es que el error aparece lejos de la
causa, en un método que aparentemente hizo todo bien, y sin mencionar quién puso la marca.
Si el método interno tenía que poder fallar sin condenar al externo, lo que necesitaba era
`REQUIRES_NEW`.

**🔬 El detalle.** La excepción es `UnexpectedRollbackException` y la lanza el
`TransactionManager` **en el commit**, es decir en el límite del proxy externo: el stack trace
apunta al interceptor y no al método interno que falló, que es exactamente por qué cuesta
tanto verlo. Las dos salidas son elegir bien la propagación del interno —`REQUIRES_NEW` si
debe sobrevivir, `NESTED` con savepoint si basta con revertir su parte— o no capturar la
excepción y dejar que todo revierta, que suele ser lo correcto.

---

### 16 → 11

> ¿Qué hace exactamente `readOnly = true` y qué **no** garantiza?

**⏱️ 30 segundos.** Le dice a Hibernate que no haga dirty checking y a la base que puede
optimizar. **No garantiza** que no se pueda escribir.

**🗣️ 2 minutos.** El ahorro de Hibernate es real: sin dirty checking no recorre las
entidades gestionadas al final buscando cambios, lo que en una consulta que carga miles de
filas se nota. Del lado de la base, algunos motores enrutan a réplicas de lectura o evitan
reservar recursos de escritura, y otros lo ignoran por completo. Tratarlo como una medida
de seguridad —"así este servicio no puede escribir"— es un error: la protección va en los
permisos del usuario de base de datos, no en una anotación.

**🔬 El detalle.** Enlace con la pregunta 13: `readOnly` es uno de los tres atributos que
desaparecen si importaste `jakarta.transaction.Transactional` —junto a `isolation` y
`timeout`—. No falla nada: el atributo simplemente no existe, y te enteras cuando el
compilador lo rechaza, no cuando el ahorro que creías tener no aparece.

---

### 16 → 12

> El `timeout` de `@Transactional` expira pero la consulta sigue viva en la base. ¿Por
> qué, y qué otro timeout hacía falta?

**⏱️ 30 segundos.** Porque ese timeout se aplica **por sentencia**: Spring propaga el
tiempo restante a `Statement.setQueryTimeout()` y eso es una *petición* de cancelación que
el motor puede tardar en atender, o no atender. Hacían falta el `socketTimeout` del driver
y el `statement_timeout` de Postgres.

**🗣️ 2 minutos.** Quien reparte el tiempo es `DataSourceUtils.applyTimeout`: antes de
ejecutar cada sentencia calcula lo que le queda a la transacción y se lo pasa al
`Statement`. De ahí salen los dos huecos. El reloj no cubre el tiempo que pasa **entre**
sentencias —lógica de aplicación, una llamada externa, una pausa—, y no cubre una lectura
de socket colgada, porque para cancelar hay que poder hablar con un servidor que sigue
contestando. Por eso los tres timeouts se apilan y ninguno sustituye a los otros: el de la
transacción, el de sentencia del motor (`statement_timeout` en Postgres, que sí la corta
del lado del servidor) y el `socketTimeout` del driver, que es lo único que te devuelve el
hilo cuando la conexión se quedó muda. Es el mismo razonamiento que el presupuesto de
tiempo de las llamadas HTTP (`13`).

**🔬 El detalle.** Cuidado con las unidades al apilar los tres, porque no coinciden y el
error se comete al escribirlas: el `timeout` de `@Transactional` va en **segundos**, el
`statement_timeout` de Postgres en **milisegundos** y el `socketTimeout` del driver de
Postgres en **segundos**. Un `statement_timeout = 30` no son treinta segundos, son treinta
milisegundos.

---

### 16 → 13

> Nombra los seis silencios de `@Transactional` y di **cuáles de los seis sí abren** la
> transacción.

**⏱️ 30 segundos.** Llamada desde la misma clase, método `private`, método o clase `final`,
llamada desde `@PostConstruct`, excepción capturada dentro, y el import de
`jakarta.transaction` en lugar del de Spring. **Dos de los seis sí abren la transacción**: el
de la excepción capturada —el interceptor corrió, pero nadie le dio motivo para revertir— y el
de Jakarta, porque Spring respeta también esa anotación.

**🗣️ 2 minutos.** Los cuatro primeros son el modelo de proxies (`05`): la invocación no
atraviesa el proxy —o el proxy no puede sobrescribir el método—, así que no hay interceptor y no
llega a existir transacción. En el quinto el interceptor sí corrió,
pero el `try/catch` le escondió la excepción y no tuvo nada que marcar. El sexto es
distinto y por eso es el más traicionero: el import de `jakarta.transaction` **abre la
transacción igual**, lo que se pierde son los atributos. No hay `readOnly`, `isolation` ni
`timeout`, y la regla de rollback se escribe con otros nombres —`rollbackOn` y
`dontRollbackOn` en vez de `rollbackFor` y `noRollbackFor`—, así que lo que creías haber
configurado simplemente no está. Ninguno de los seis produce un aviso.

**🔬 El detalle.** Media respuesta habitual sobra desde **Spring Framework 6.0**: "solo
funciona en métodos `public`" ya no es exacto. Con proxies **CGLIB** —el default de Boot desde
2.0— la anotación se respeta también en métodos `protected` y package-private, porque la
subclase puede sobrescribirlos; lo que nunca funciona es `private`, y con proxies JDK no
funciona nada que no esté declarado en la interfaz. La formulación precisa no habla de
visibilidad: *"es cuestión de si el proxy puede sobrescribir el método y de si la llamada
entra desde fuera del bean"*.

---

### 16 → 14

> ¿Cómo compruebas en un minuto, sin debugger, si un método corrió dentro de una
> transacción?

**⏱️ 30 segundos.** Subiendo a `TRACE` el log de
`org.springframework.transaction.interceptor` y buscando las líneas `Getting transaction
for` y `Completing transaction for` alrededor de tu método.

**🗣️ 2 minutos.** Si esas líneas no aparecen, el interceptor no corrió y ya tienes la
respuesta: es uno de los seis silencios. Si aparecen pero el dato se guardó igual, el
problema no es el proxy sino la regla de rollback —excepción comprobada o capturada—. En
dos minutos has partido el espacio de búsqueda en dos mitades sin abrir el IDE, y es
exactamente lo que se practica en `L04`.

**🔬 El detalle.** Es una sola propiedad —`logging.level.org.springframework.transaction.interceptor=TRACE`—
y las líneas traen el método entre corchetes, `Getting transaction for [com.invlab...record]`,
así que también sirven para distinguir cuál de dos métodos abrió la transacción. En un entorno
donde no puedes reiniciar, el nivel se cambia en caliente por el endpoint `loggers` de
Actuator (`23`).

---

### 16 → 15

> ¿Para qué sirve `@TransactionalEventListener(AFTER_COMMIT)` y qué garantía **no** te da?

**⏱️ 30 segundos.** Sirve para ejecutar un efecto externo **solo si la transacción
confirmó**. No garantiza entrega: si el proceso muere entre el commit y el listener, el
evento se pierde.

**🗣️ 2 minutos.** Resuelve el peor fallo posible del patrón ingenuo —publicar dentro de la
transacción y que el aviso salga mientras el dato se revierte—, y por eso es el mecanismo
correcto por defecto. Pero el listener corre en memoria, después del commit y fuera de
cualquier transacción: una caída en esa ventana no deja rastro. Cuando la pérdida no es
aceptable, el patrón es **outbox**, que escribe el evento en la misma transacción que el
dato y lo publica aparte, y cuyo diseño vive en el corpus de arquitectura.

**🔬 El detalle.** Si el listener necesita escribir en la base, hay que darle
`REQUIRES_NEW`: la transacción original ya cerró y sin una nueva no se persiste nada. Y hay
un coste que conviene tener contado: mientras el listener corre, la conexión de la
transacción original **todavía no volvió al pool** —`cleanupAfterCompletion` va después de
`triggerAfterCompletion`—, así que ese `REQUIRES_NEW` implica dos conexiones simultáneas
por petición, exactamente el patrón que agota el pool si el listener tarda.

---

## Capítulo 17 — Caché

### 17 → 1

> Nombra las cuatro condiciones que hacen que cachear una lectura sea una mejora.

**⏱️ 30 segundos.** Lectura muy repetida, resultado caro de calcular, dato que cambia
despacio y tolerancia declarada a leer algo viejo. Las cuatro a la vez.

**🗣️ 2 minutos.** Si falta la repetición, el hit ratio es bajo y cada lectura paga el acceso
al store **más** la escritura del resultado: la caché cuesta más que la consulta. Si el
resultado es barato —una consulta de 1 ms por clave primaria— una caché distribuida te hace
más lento, porque el salto de red vale más que lo que ahorras. Si el dato cambia rápido, la
caché es un generador de respuestas incorrectas. Y si nadie firmó que se puede leer algo
viejo, no tienes caché: tienes un bug esperando. Decirlo así evita la respuesta de manual
("cachear mejora el rendimiento") y demuestra que entiendes el intercambio.

**🔬 El detalle.** El coste que nadie menciona es la memoria retenida: una caché local sin
`maximumSize` mantiene los objetos alcanzables, el GC no los recoge y el `OutOfMemoryError`
llega semanas después, lejos del despliegue que lo causó.

---

### 17 → 2

> ¿Qué hace exactamente `@EnableCaching` y cuál es el síntoma de que falta?

**⏱️ 30 segundos.** Registra el `CacheInterceptor` y el advisor que lo aplica a los beans.
No crea ninguna caché. Sin él, `@Cacheable` y compañía no hacen nada y el método se ejecuta
siempre, sin error ni log.

**🗣️ 2 minutos.** Es el mismo patrón que `@EnableTransactionManagement`: la anotación de
activación instala la infraestructura de AOP, y las anotaciones sobre los métodos solo son
metadatos que esa infraestructura lee. El síntoma es exactamente "no pasa nada": la
aplicación arranca bien, responde bien y la latencia no baja. La comprobación rápida es la
métrica: si `cache.gets` ni siquiera registra un `miss`, el interceptor no se está
ejecutando. `spring.cache.type` no sustituye a `@EnableCaching` —elige la implementación,
no enciende el mecanismo—.

**🔬 El detalle.** Cuidado con esa comprobación por métrica, porque tiene un falso positivo:
con Caffeine, si no pusiste `recordStats` en el `spec`, `cache.gets` **no existe** aunque el
interceptor esté corriendo perfectamente. Conviene ordenar la duda al revés: Spring no
implementa ninguna caché —define `Cache` y `CacheManager` y pone un interceptor—, así que hay
tres cosas separadas que pueden faltar: el mecanismo (`@EnableCaching`), el store
(`spring.cache.type` y su dependencia) y los contadores (`recordStats`).

---

### 17 → 3

> Diferencia `@Cacheable` de `@CachePut` según si el método se ejecuta, y di qué cambia
> `beforeInvocation = true` en un `@CacheEvict` sobre un método que lanza.

**⏱️ 30 segundos.** `@Cacheable` **puede saltarse** el método si hay entrada; `@CachePut`
**siempre lo ejecuta** y después escribe. `beforeInvocation = true` borra antes de invocar,
así que la entrada desaparece aunque el método lance; con el default `false`, si el método
explota la entrada vieja sobrevive.

**🗣️ 2 minutos.** `@Cacheable` es para lecturas, `@CachePut` para dejar fresca la entrada
después de una escritura sin obligar a la siguiente lectura a ir a la base. Ponerlas juntas
en el mismo método es contradictorio, pero **Spring no lo rechaza al arrancar**:
`SpringCacheAnnotationParser.validateCacheOperation()` solo veta dos combinaciones,
`key` con `keyGenerator` y `cacheManager` con `cacheResolver`. El contexto levanta y el
comportamiento queda indefinido, que es peor que un fallo de arranque. En el `@CacheEvict`,
la elección depende de qué es peor: con `beforeInvocation = true` puedes acabar con la caché
vacía y el dato sin borrar —te cuesta un fallo de caché—, y con `false` puedes acabar
sirviendo un dato que ya no vale. Casi siempre gana la primera.

**🔬 El detalle.** La asimetría de coste es la que decide, y se generaliza: equivocarse
borrando de más cuesta un `miss`; equivocarse borrando de menos cuesta una respuesta
incorrecta. Por eso la versión agresiva de `@CacheEvict` —`allEntries = true`, que vacía la
caché entera— es defendible tras una escritura masiva, y por eso la alternativa conservadora a
`@CachePut` es no usarlo: invalidar y dejar que la siguiente lectura repueble. `@Caching`, por
cierto, solo agrupa varias de estas anotaciones sobre un método: no añade semántica ninguna.

---

### 17 → 4

> `condition` y `unless`: ¿cuándo se evalúa cada uno y cuál puede mirar `#result`?

**⏱️ 30 segundos.** `condition` se evalúa **antes** de ejecutar: ve los argumentos y el
`#root` —`method`, `target`, `caches`—, y si es `false` la caché ni se consulta ni se
escribe. Lo único que no ve es `#result`, que todavía no existe. `unless` se evalúa
**después**, veta solo la escritura y es el único que puede usar `#result`.

**🗣️ 2 minutos.** La regla para decirla en voz alta: *condition decide si participas, unless
decide si guardas*. El caso típico de `condition` es no cachear entradas que sabes inválidas
o irrelevantes por su argumento —un SKU con formato incorrecto—. El de `unless` es no
guardar un resultado vacío o nulo que contaminaría la caché. Ojo con la combinación: `unless`
es incompatible con `sync = true`, porque la caché sincronizada necesita decidir la escritura
dentro del mismo `get` atómico.

**🔬 El detalle.** Dos precisiones sobre el contexto SpEL. `#sku` por nombre de parámetro
exige que el bytecode lleve `-parameters` —el plugin de Boot lo activa, un build a mano puede
no hacerlo—, y el recambio portable es `#p0` por posición. Y un `condition` falso no es
"no guarda": la caché **ni se consulta**, así que tampoco registra un `miss`, y ese es el caso
que hace parecer que el interceptor no corre cuando sí corría (pregunta 5).

---

### 17 → 5

> Tu `@Cacheable` nunca registra un `hit` y tampoco hay errores. ¿Qué miras, y en qué orden?

**⏱️ 30 segundos.** Primero `@EnableCaching`; después si la llamada viene de otro bean o es
self-invocation; luego `condition`/`unless`; luego la estabilidad de la clave. Y como señal
que separa las dos mitades: si `cache.gets` no registra ni un `miss`, el interceptor no corre
y el problema es el proxy, no la caché.

**🗣️ 2 minutos.** Ese último punto es el que ordena el diagnóstico. Si hay `miss` pero nunca
`hit`, el interceptor sí se ejecuta y el problema está en la clave o en la escritura: una
clave que cambia entre llamadas —un objeto sin `equals`, un `toString` con un timestamp
dentro—, un `unless` que veta siempre, o un TTL tan corto que la entrada muere antes de que
la vuelvas a pedir. Si no hay ni `miss`, nunca se llegó al interceptor: falta
`@EnableCaching`, la llamada es interna, el método es `private` o `final`, o el bean no está
proxyado.

**🔬 El detalle.** En una caché local también conviene mirar `cache.evictions` y `cache.size`
contra el `maximumSize`: si están pegados, cada entrada nueva expulsa una útil y el ratio no
va a subir tocando el TTL.

---

### 17 → 6

> ¿Por qué `@Cacheable` falla en self-invocation exactamente igual que `@Transactional`?

**⏱️ 30 segundos.** Porque es el mismo mecanismo: un proxy con un interceptor. Lo que el
contenedor inyecta a los demás beans es el proxy, pero dentro de la clase `this` es el objeto
real, así que una llamada interna no pasa por el interceptor y la anotación no hace nada.

**🗣️ 2 minutos.** `@Transactional`, `@Cacheable`, `@Async`, `@Retryable` y `@PreAuthorize`
son el mismo sombrero sobre la misma cabeza. La regla mental: *otro bean → hay proxy → hay
caché; misma clase, `private` o `final` → no hay proxy → no hay nada*. El caso clásico es un
`findAll(List<String>)` que mapea sobre `this::findBySku`: cada SKU va a la base todas las
veces y no hay ningún error que lo delate. Las salidas son mover el método cacheado a otro
bean, inyectarse el propio proxy con `@Lazy`, o pasar a AspectJ con weaving —que sí
intercepta llamadas internas, a cambio de complicar el build—.

**🔬 El detalle.** En el caso del `findAll(List<String>)` hay una tentación que empeora la
cosa: anotar el propio `findAll` con `@Cacheable`. La clave pasa a ser la lista entera —depende
de su `equals`/`hashCode` y del orden—, así que pedir los mismos diez SKU en otro orden es un
`miss`, y una sola entrada nueva invalida la lista completa. Cachear por elemento y cruzar el
proxy sigue siendo lo correcto.

---

### 17 → 7

> Un acierto en Caffeine y uno en Redis: ¿qué orden de magnitud tiene cada uno, y qué implica
> para una consulta que ya tardaba 1 ms?

**⏱️ 30 segundos.** Caffeine son ~100 ns; Redis, 0,3–2 ms por el salto de red. Cuatro órdenes
de magnitud. Delante de una consulta de 1 ms, la caché distribuida te hace **más lento**.

**🗣️ 2 minutos.** Es el argumento que convierte "local o distribuida" en una decisión y no en
una preferencia. Una caché local es un acceso a memoria del mismo proceso; una distribuida es
una llamada de red con serialización en los dos extremos, y esa serialización ocurre **dentro
del hilo del request**: un DTO grande en JSON puede costar más CPU que la consulta que
evitaste. Redis se elige por **coherencia entre réplicas**, no por velocidad. Si el dato cabe
en el heap, tolera divergencia entre instancias y lo que quieres es latencia, Caffeine gana
siempre.

**🔬 El detalle.** Y ojo con los defaults del ganador: sin `spec`, Caffeine arranca **sin
límite de tamaño y sin expiración**, que es la fuga con buen nombre de la pregunta 1. La línea
del curso —`maximumSize=500,expireAfterWrite=10m,recordStats`— dice las tres decisiones de una
vez: techo en **entradas** (no en bytes), ventana de dato viejo contada desde la **escritura**,
y contadores. `expireAfterAccess` parece equivalente y no lo es: reinicia el reloj en cada
lectura, así que el dato más caliente es el que nunca caduca.

---

### 17 → 8

> ¿Por qué el serializador JDK te ata a la clase, y qué excepción verás tras añadir un campo?

**⏱️ 30 segundos.** Porque `JdkSerializationRedisSerializer` escribe el estado binario de la
clase con su `serialVersionUID`: solo lo lee esa misma clase Java. Al cambiar la forma del
DTO, la instancia que lee lo que escribió la otra revienta con `SerializationException`.

**🗣️ 2 minutos.** El problema aparece justo en el despliegue rolling, que es cuando conviven
la versión vieja y la nueva contra la misma caché. Además el contenido es ilegible con
`redis-cli` —`\xac\xed\x00\x05t\x00…`— y ningún consumidor que no sea Java puede leerlo. La
salida es un serializador JSON, típicamente `GenericJackson2JsonRedisSerializer`, que guarda
algo legible y tolerante a campos nuevos. Ese tampoco es gratis: escribe el nombre de la
clase en el documento (`@class`) para reconstruir el tipo, así que renombrar el paquete
invalida lo cacheado. Si el consumidor eres solo tú, es el mejor compromiso; si no, se cachea
un `record` de transporte estable.

**🔬 El detalle.** La ventana peligrosa es el **rolling deploy**, y lo es en las dos
direcciones: no es solo que la instancia vieja no entienda lo que escribió la nueva, es que
mientras dure el despliegue las dos escriben en el mismo espacio de claves. La salida limpia
para un cambio de formato no es `FLUSHDB` —tiraría también las cachés de los demás servicios—
sino **versionar el prefijo de la clave** (`inv:inventory-items:v3::SKU-0042`): la versión
nueva deja de leer lo viejo y lo viejo caduca solo por TTL.

---

### 17 → 9

> Explica el cache stampede y di qué corta `sync = true` y qué no corta.

**⏱️ 30 segundos.** Muchas entradas cargadas a la vez caducan a la vez, y todas las
peticiones en vuelo caen sobre la base en el mismo segundo. `sync = true` corta la avalancha
**por clave** —un hilo ejecuta, los demás esperan— pero no corta la expiración simultánea de
claves distintas.

**🗣️ 2 minutos.** El caso más común es el despliegue: la caché se calienta en frío, doscientas
entradas nacen con el mismo TTL y mueren juntas diez minutos después. La caché no amortiguó
el pico, lo sincronizó. Las tres mitigaciones se combinan: `sync` para el pico sobre una
misma clave, TTL con jitter —±10 % aleatorio por entrada— para desparramar las expiraciones,
y refresh-ahead para que el request nunca vea el fallo, a costa de refrescar cosas que nadie
pidió. Y hay que declarar los límites de `sync`: no es compatible con `unless` y no todos los
stores lo implementan de verdad; Caffeine sí, vía `LoadingCache`.

**🔬 El detalle.** El refresh-ahead de Caffeine es `refreshAfterWrite`, y su gracia está en
que **devuelve el valor viejo** mientras un hilo carga el nuevo: el request no espera nunca, a
cambio de aceptar un dato ligeramente antiguo y de refrescar entradas que quizá nadie vuelva a
pedir. El jitter, por su parte, no es una idea de caché sino la misma de los reintentos (`19`):
cualquier cosa que sincronice a muchos clientes en el mismo instante necesita ruido para
desparramarlos.

---

### 17 → 10

> ¿Por qué el TTL sigue haciendo falta aunque invalides por evento?

**⏱️ 30 segundos.** Porque la invalidación por evento es exacta pero frágil: cada ruta de
escritura que alguien olvide anotar deja una entrada mintiendo para siempre. El TTL es la red
debajo del evento, no su alternativa.

**🗣️ 2 minutos.** El evento se pierde por muchas vías: un `@CacheEvict` que falta en el nuevo
endpoint, un job de Batch que escribe directo en la tabla, un DBA que corrige un registro a
mano, un listener que no se ejecutó porque la transacción hizo rollback. Con TTL, el peor
caso es un dato viejo durante N minutos; sin TTL, el peor caso es un dato incorrecto
permanente. Por eso el TTL infinito que trae por defecto `RedisCacheManager` casi nunca es lo
que quieres. La tercera forma, la versión de clave, es complementaria: no borra nada, deja de
leer lo viejo y lo viejo caduca solo, y es la manera limpia de invalidar todo tras un cambio
de formato sin un `FLUSHDB` que tiraría también las cachés de los demás servicios.

**🔬 El detalle.** En Redis el TTL se declara **por caché**, no globalmente, y el camino que
no rompe nada es un `RedisCacheManagerBuilderCustomizer` con `entryTtl(Duration.ofMinutes(10))`
para `inventory-items`: **ajusta** el manager que autoconfiguró Boot, mientras que declarar tú
el `CacheManager` entero te hace perder el resto de la autoconfiguración. En esa misma
configuración va `prefixCacheNameWith("inv:")`, porque sin prefijo dos servicios con una caché
del mismo nombre sobre la misma instancia se pisan las entradas.

---

### 17 → 11

> Con caché local y tres réplicas, ¿qué ocurre tras un `@CacheEvict` en una de ellas?

**⏱️ 30 segundos.** Solo se limpia la copia de esa instancia. Las otras dos siguen sirviendo
el valor viejo hasta que expire su TTL, así que el mismo `GET` devuelve cosas distintas según
a qué réplica caiga.

**🗣️ 2 minutos.** El cliente lo percibe como intermitencia —"a veces sale bien, a veces
mal"—, que es de los síntomas más caros de diagnosticar porque no hay error en ningún log. Es
el argumento más fuerte a favor de Redis: no la velocidad, la coherencia. Las salidas son
mover esa caché a un store compartido, bajar mucho el TTL local para acotar la ventana de
divergencia, o aceptarla y declararlo explícitamente cuando el dato lo tolera —un catálogo,
una tabla de parámetros—. Lo que no es una salida es suponer que no pasa.

**🔬 El detalle.** La ventana de divergencia tiene una cota exacta —el **TTL restante**—, y eso
es lo que convierte "bajar el TTL" en una mitigación medible y no en un conjuro. El hit ratio no
te va a avisar: las tres réplicas lo tienen igual de sano, cada una sirviendo su versión.
Cuidado también al mudar esa caché a Redis, porque el store compartido trae su propio fallo: si
el resultado depende de la identidad del usuario y la identidad no está en la clave, el segundo
usuario recibe lo que se calculó para el primero.

---

### 17 → 12

> ¿Por qué un `@CachePut` dentro de un `@Transactional` puede cachear algo que nunca existió?

**⏱️ 30 segundos.** Porque el interceptor de caché escribe cuando el método **retorna**, no
cuando la transacción hace **commit**. Si el commit falla después, la base hace rollback y la
caché se queda con un valor que nunca se persistió.

**🗣️ 2 minutos.** El límite de la transacción no coincide con el límite de tu método: el
commit ocurre cuando el proxy transaccional, que está por fuera, termina. Todo efecto que no
sea la base de datos y se dispare dentro del método está apostando a que ese commit va a
salir bien. El punto correcto para poblar la caché tras una escritura es después del commit,
con `@TransactionalEventListener(AFTER_COMMIT)`. La alternativa conservadora es no usar
`@CachePut` en absoluto: invalidar con `@CacheEvict` y dejar que la siguiente lectura
repueble, que como mucho cuesta un fallo de caché.

**🔬 El detalle.** Es una consecuencia del apilado de proxies: el interceptor de caché está
**por dentro** del transaccional, así que escribe al retornar el método y el commit ocurre
después, cuando el proxy de fuera termina. La regla general que sale de ahí vale para todo
efecto no transaccional —publicar un evento, mandar un correo, poblar una caché—: dentro del
método estás apostando a que el commit va a salir bien. Y si el listener `AFTER_COMMIT` que lo
sustituye necesita escribir en base, ya no hay transacción y necesita `REQUIRES_NEW` (`16`).

---

### 17 → 13

> "Redis es una caché": ¿qué le corriges a esa frase en una entrevista?

**⏱️ 30 segundos.** Redis es un almacén de estructuras de datos en memoria. Caché es **un**
uso entre varios: también es broker de mensajes, lock distribuido, rate limiter, contador y
store de sesiones.

**🗣️ 2 minutos.** La corrección no es terminológica, tiene consecuencias. Primero, **Redis
persiste** —RDB y AOF—, así que lo que cacheas ahí sobrevive a tu despliegue: una entrada mal
formada no se limpia sola al reiniciar, como pasaría con una caché local. Segundo, su API
trabaja con tipos —hashes, sorted sets, streams—, y eso permite modelar cosas que una caché
clave-valor no: un ranking, una cola, un contador con expiración. Y tercero, si lo tratas
solo como caché te pierdes la mitad de las respuestas: cuando el problema es coordinar
réplicas —que solo una ejecute un job—, la herramienta ya la tienes desplegada.

**🔬 El detalle.** Esa variedad se nota también en la elección de cliente. **Lettuce** —el
default del starter desde Boot 2.0— multiplexa **una** conexión thread-safe para todos los
hilos, porque el protocolo de Redis es secuencial y las respuestas vuelven en orden; **Jedis**
toma una conexión del pool por operación, y ese pool se agota igual que el de Hikari;
**Redisson** es el que trae las estructuras (`RLock`, `RMap`, `RRateLimiter`). Para cachear
sobra Lettuce: Redisson se paga por las primitivas de coordinación, no por la caché.

---

### 17 → 14

> ¿Qué garantiza y qué no un `RLock` de Redisson, y dónde resuelves la exclusión si de ella
> depende la corrección?

**⏱️ 30 segundos.** Garantiza que, en el caso normal, dos réplicas no hagan el mismo trabajo a
la vez. No garantiza exclusión mutua ante una pausa de GC, un reloj desviado o un lease que
expira mientras sigues trabajando. Si la corrección depende de la exclusión, se resuelve donde
está el dato.

**🗣️ 2 minutos.** `tryLock(waitTime, leaseTime, unit)` tiene dos números: cuánto esperas a
que se libere y cuánto lo retienes como máximo aunque tu proceso muera. Sin `leaseTime`, un
proceso que cae con el lock tomado bloquea a los demás para siempre; con él, estás apostando
a que el trabajo dura menos que el lease, y si `reconcile()` tarda 40 segundos y el lease son
30, otra réplica entra mientras la primera sigue escribiendo. Redlock, el algoritmo de varios
nodos independientes, está discutido precisamente por eso: sin fencing token no hay forma de
que el recurso rechace al dueño caducado. Y conviene decir que el ejemplo del capítulo ni
siquiera es Redlock: es un lock sobre **un solo nodo**, así que si esa instancia hace
failover a una réplica que no había recibido el lock, dos procesos lo tienen a la vez sin
que nada falle. La conclusión práctica es tratarlo como
**optimización para no duplicar trabajo**, no como garantía: la corrección se resuelve con una
restricción única, un `UPDATE ... WHERE version = ?` o una clave de idempotencia.

**🔬 El detalle.** `tryLock(long, long, TimeUnit)` declara `InterruptedException`, así que
la espera es interrumpible y hay que decidir qué hacer con ella en vez de tragársela.
Redisson, además, es una dependencia grande y fuera del BOM de Boot, así que lleva
versión explícita. Si no necesitas sus primitivas de coordinación, para cachear basta Lettuce,
que es el cliente por defecto desde Boot 2.0.

---

## Capítulo 18 — Asincronía, scheduling y eventos

### 18 → 1

> ¿Qué hace `@EnableAsync` y qué ocurre si anotas con `@Async` sin haberlo puesto?

**⏱️ 30 segundos.** Registra el post-processor que crea los proxies que interceptan
`@Async`. Sin él no hay proxy: el método corre en el hilo del llamante, de forma
completamente síncrona, y **no hay ningún aviso** — ni excepción, ni warning en el arranque.

**🗣️ 2 minutos.** Es el mismo mecanismo de `05`: la anotación no hace nada por sí misma, es
el proxy quien la honra. Spring Boot autoconfigura el `applicationTaskExecutor`, pero **no**
activa `@EnableAsync` por ti, y esa asimetría confunde: tienes el executor listo y nadie que
lo use. Va en cualquier `@Configuration` de la aplicación, típicamente la misma clase que
implementa `AsyncConfigurer` para fijar executor y handler de excepciones.

**🔬 El detalle.** El fallo silencioso es diagnosticable en un segundo: loguea
`Thread.currentThread().getName()` dentro del método. Si ves `http-nio-8080-exec-3` en vez
de tu `inv-task-1`, o no hay proxy o hubo self-invocation.

---

### 18 → 2

> Explica por qué un `@Async` llamado desde otro método de la misma clase corre en el hilo
> del llamante, y nombra la salida preferible.

**⏱️ 30 segundos.** Porque el proxy envuelve al objeto **desde fuera**: en cuanto la
ejecución entra en la clase, `this` es el objeto real y la llamada interna no pasa por el
proxy. La salida preferible es **mover el método `@Async` a otro bean** e inyectarlo.

**🗣️ 2 minutos.** Es exactamente la self-invocation de `@Transactional` (`05` §5), con el
mismo silencio: sin excepción, sin log y sin hilo nuevo. Las otras dos salidas existen y son
peores: auto-inyectarse el proxy —o `AopContext.currentProxy()` con `exposeProxy = true`—
funciona, se lee mal y deja un ciclo de dependencia; y AspectJ con weaving en tiempo de carga
resuelve el caso general a cambio de una capa de build y de operación. Separar el bean suele
además revelar que la clase estaba haciendo dos cosas.

**🔬 El detalle.** La regla mental sirve para las cinco anotaciones declarativas del curso:
misma clase → no hay proxy → no hay transacción, ni caché, ni retry, ni async.

---

### 18 → 3

> Tu método `@Async` devuelve `void` y lanza. ¿Quién se entera, y qué cambia con
> `CompletableFuture`?

**⏱️ 30 segundos.** Con `void`, nadie: el llamante ya se fue. Solo queda el
`AsyncUncaughtExceptionHandler`, y si no declaras el tuyo actúa el default
(`SimpleAsyncUncaughtExceptionHandler`), que loguea en `ERROR` pero sin el contexto de tu
request. Con `CompletableFuture` la excepción viaja **dentro** del future.

**🗣️ 2 minutos.** El matiz que casi nadie dice: el handler **solo** se consulta en métodos
que devuelven `void`. Si devuelves `CompletableFuture`, el handler no se entera nunca, y la
excepción la ves al hacer `join()` o encadenando `.exceptionally(...)`; si nadie consulta el
future, se pierde igual de silenciosamente. Por eso el curso prefiere `CompletableFuture`
**y** declarar el handler: cubren casos distintos.

**🔬 El detalle.** El log del default sale sin `traceId` y sin usuario porque ya estás en
otro hilo y el MDC no cruzó (pregunta 7). Un handler propio que reinyecte el `traceId`
capturado al enviar la tarea vale más que el default.

---

### 18 → 4

> Con `core-size: 8`, `max-size: 200` y la cola por defecto, ¿cuántos hilos llegas a tener?

**⏱️ 30 segundos.** Ocho. La cola por defecto es `Integer.MAX_VALUE`, y
`ThreadPoolTaskExecutor` **llena la cola antes de crecer hasta `max`**: como la cola nunca se
llena, los hilos por encima de `core-size` no se crean jamás.

**🗣️ 2 minutos.** El orden real es: si hay menos hilos que `core-size`, crea hilo; si no, si
cabe en la cola, encola; si no, si hay menos que `max-size`, crea hilo; si no, política de
rechazo. Con cola ilimitada el tercer paso es inalcanzable y `max-size: 200` es decorativo.
Lo que sí crece es la cola, que retiene en heap todo lo que capturó cada tarea: el final no
es un pico de latencia, es un `OutOfMemoryError` horas después de haber aceptado trabajo que
nunca se hizo.

**🔬 El detalle.** Es herencia directa de `ThreadPoolExecutor` del JDK, no una rareza de
Spring. La consecuencia práctica: **acotar la cola es lo que da sentido a `max-size`**, y
acotarla obliga a elegir política de rechazo (pregunta 5).

---

### 18 → 5

> ¿En qué se diferencian `AbortPolicy` y `CallerRunsPolicy`, y qué riesgo tiene la segunda?

**⏱️ 30 segundos.** `AbortPolicy` —el default— lanza `TaskRejectedException` al que envió la
tarea. `CallerRunsPolicy` ejecuta la tarea **en el hilo del llamante**. El riesgo es evidente
dicho así: ese llamante suele ser el hilo de Tomcat que creías haber liberado.

**🗣️ 2 minutos.** `CallerRunsPolicy` es backpressure real y a veces es exactamente lo que
quieres: frena a quien produce trabajo más rápido de lo que se consume. Pero en un endpoint
web convierte una escritura asíncrona en una espera síncrona justo cuando el sistema está
saturado, que es el peor momento. `AbortPolicy` es ruidosa, y aquí eso es una virtud: te
enteras del rechazo y puedes devolver un 503 honesto. `DiscardPolicy` y `DiscardOldestPolicy`
tiran trabajo en silencio y solo valen si de verdad es descartable y dejas la métrica.

---

### 18 → 6

> Con virtual threads como executor de `@Async`, ¿qué problema desaparece y cuál aparece?

**⏱️ 30 segundos.** Desaparece el dimensionado del pool —los tres números y la cola, porque
se estrena un virtual thread por tarea—, y aparece que **nada acota cuántas tareas hay en
vuelo**: el límite que te protegía era el pool.

**🗣️ 2 minutos.** Con `spring.threads.virtual.enabled=true` el executor de `@Async` pasa a
ser un `SimpleAsyncTaskExecutor` sobre virtual threads: sin pool, sin cola y sin política de
rechazo. Bloquear deja de ser caro, así que la pregunta "¿cuántos hilos?" se vuelve
irrelevante. Lo que no desaparece es el recurso escaso del otro lado —conexiones de base de
datos, cuota del proveedor—, y ese control se muda al bulkhead de `19` o al pool de Hikari.
Dicho en una frase de entrevista: los virtual threads quitan el techo, no la necesidad de
tener uno.

**🔬 El detalle.** Tampoco arreglan el `synchronized` que fija el carrier thread ni la
propagación de contexto: el `ThreadLocal` sigue sin cruzar. Lo que sí cambia es que el hilo
no se reutiliza, así que la contaminación entre peticiones por no llamar a `remove()` deja de
ser un problema.

---

### 18 → 7

> Tu `@Async` lanza `AccessDeniedException` con un usuario que sí tiene el rol. ¿Por qué?

**⏱️ 30 segundos.** Porque el `SecurityContext` vive en un `ThreadLocal` y **no cruzó al hilo
del executor**. En ese hilo no hay usuario autenticado, así que cualquier `@PreAuthorize`
deniega.

**🗣️ 2 minutos.** El diagnóstico es de un minuto: si el mismo método funciona llamado
síncronamente y falla con `@Async`, es contexto perdido, no permisos. La corrección es
envolver el executor en `DelegatingSecurityContextAsyncTaskExecutor`, que copia el
`SecurityContext` del hilo que envía al que ejecuta. Si además quieres el `traceId` y el MDC,
le pones un `TaskDecorator` —`ContextPropagatingTaskDecorator`, que usa Micrometer Context
Propagation— y lo arrastras todo de una vez.

**🔬 El detalle.** Los otros dos síntomas del mismo salto de hilo: logs huérfanos sin
correlación (MDC perdido) e `IllegalStateException: No thread-bound request found`
(`RequestContextHolder` perdido). Propagar **copia**, no comparte: si alguien limpia el
holder al terminar el request, tu copia sigue viva en el otro hilo.

---

### 18 → 8

> Diferencia `fixedRate` de `fixedDelay` y di cuál eliges si la duración es variable.

**⏱️ 30 segundos.** `fixedDelay` cuenta desde que **termina** una ejecución hasta que empieza
la siguiente; `fixedRate` cuenta de **inicio a inicio**. Con duración variable eliges
`fixedDelay`, porque se autorregula.

**🗣️ 2 minutos.** El problema de `fixedRate` no es el solapamiento —el scheduler no ejecuta
dos veces a la vez el mismo método—, es la **deuda acumulada**: si la tarea tarda más que el
periodo, las ejecuciones se van retrasando, y en cuanto el trabajo se acelera dispara varias
seguidas para ponerse al día. Eso convierte un job tranquilo en una ráfaga, justo después de
un incidente, que es cuando menos la quieres. `fixedRate` tiene sentido cuando lo que importa
es la cadencia real —un heartbeat, una métrica muestreada— y la tarea es corta y estable.

---

### 18 → 9

> Un `@Scheduled` tuyo "se salta ejecuciones" y su log no muestra ningún error. ¿Qué miras
> primero?

**⏱️ 30 segundos.** El tamaño del pool de scheduling: `spring.task.scheduling.pool.size` vale
**1** por defecto, así que todas las tareas `@Scheduled` de la aplicación comparten un único
hilo. El culpable casi nunca está en el job que falla.

**🗣️ 2 minutos.** Una tarea que tarda 40 segundos retrasa 40 segundos a todas las demás,
incluidas las de librerías de terceros que ni sabías que tenían `@Scheduled`. Por eso el log
del job afectado está limpio: no falló, no llegó a correr a tiempo. Se confirma con un thread
dump —un solo hilo `scheduling-1` ocupado— y se corrige subiendo `size` a tantos como jobs
puedan coincidir en el tiempo, no a tantos como jobs tengas.

**🔬 El detalle.** El executor de `@Async` y el scheduler son pools distintos a propósito:
compartirlos deja que una tarea asíncrona lenta bloquee el reloj. Y subir el pool no hace que
una tarea se solape consigo misma; para eso habría que combinar `@Scheduled` con `@Async`, y
ahí pierdes la serialización que te estaba protegiendo.

---

### 18 → 10

> ¿Cuántos campos tiene un cron de Spring y qué pasa si pegas uno de Unix de cinco?

**⏱️ 30 segundos.** Seis: segundo, minuto, hora, día del mes, mes y día de la semana. Uno
de Unix de cinco campos **no desplaza nada: no arranca**. `CronExpression.parse()` cuenta
los campos antes de interpretarlos y lanza `IllegalArgumentException: Cron expression must
consist of 6 fields (found 5 in "15 3 * * *")`.

**🗣️ 2 minutos.** El campo extra de Spring es el de segundos, al principio, y es ahí donde
está el desplazamiento que sí es silencioso: `0 15 3 * * *` son las 03:15:00, mientras que
`15 3 * * * *` —seis campos válidos— corre en el segundo 15 del minuto 3 de **cada hora**.
Se parsea, arranca y corre veinticuatro veces al día en vez de una. Y el otro
atributo que no es opcional es `zone`: sin él manda la zona por defecto de la JVM, que en un
contenedor suele ser UTC, y tu cierre de las 3 de la mañana corre a las 10 de la noche. Con
una zona que tiene horario de verano, además, un cron a las 2:30 se ejecuta dos veces un
domingo al año y ninguna el otro — razón suficiente para programar los jobs críticos fuera de
la ventana de cambio.

---

### 18 → 11

> Tienes tres réplicas de `inv-api` y un job nocturno. Enumera las tres salidas posibles y
> di cuándo eliges cada una.

**⏱️ 30 segundos.** `@Scheduled` es local al proceso: tres réplicas son tres ejecuciones. Las
salidas son **hacer el job idempotente**, **un lock distribuido** (ShedLock) o **un scheduler
externo** que invoque un endpoint.

**🗣️ 2 minutos.** La primera es la mejor cuando encaja: si el job es "recalcular la
proyección del SKU", tres ejecuciones dan el mismo resultado y no necesitas infraestructura
nueva. El lock distribuido es para cuando el job **no** es idempotente —mover dinero, emitir
un archivo, numerar un lote—; ShedLock es el estándar de hecho porque es pequeño, se apoya en
una tabla o en Redis y no obliga a adoptar Spring Cloud entero. El scheduler externo se elige
cuando la ejecución ya es una operación de negocio con su propia auditoría y alguien tiene
que poder relanzarla a mano.

**🔬 El detalle.** ShedLock no es un planificador ni una garantía de ejecución: si la
instancia que tomó el lock muere a la mitad, esa ejecución se pierde hasta la ventana
siguiente. El `lockAtMostFor` existe para que ese cadáver no bloquee al resto para siempre, y
elegirlo demasiado corto reintroduce la ejecución doble.

---

### 18 → 12

> "Los eventos de Spring son asíncronos": corrige la frase y di en qué hilo, dentro de qué
> transacción y con qué efecto sobre el publicador corre un `@EventListener` que lanza.

**⏱️ 30 segundos.** En el **mismo hilo del publicador** y dentro de **su misma transacción**,
si la hay. Si el listener lanza, la excepción sube al publicador y provoca el rollback:
`publishEvent` no vuelve hasta que todos los listeners terminaron.

**🗣️ 2 minutos.** Es la sobregeneralización clásica: los eventos de Spring desacoplan en
compilación, no en ejecución. El `ApplicationEventMulticaster` por defecto es síncrono, así
que un listener lento alarga tu request y un listener que falla tumba tu escritura. Poner
`@Async` sobre el listener lo cambia, y cambia tres cosas a la vez: pasa al executor, la
excepción deja de llegar al publicador y el contexto del hilo se queda atrás si no lo
propagaste. Es una decisión consciente, no un adorno.

---

### 18 → 13

> ¿Qué ocurre con un `@TransactionalEventListener` sin transacción activa, y qué atributo
> lo cambia?

**⏱️ 30 segundos.** **No se ejecuta en absoluto**: ni excepción ni warning, simplemente no
pasa nada. El atributo que lo cambia es `fallbackExecution = true`, que lo ejecuta igualmente
cuando no hay transacción.

**🗣️ 2 minutos.** Es la trampa de test más cara de esta familia: publicas el evento en un
test sin transacción, el test pasa en verde y no probaste nada. La fase por defecto es
`AFTER_COMMIT`, que es el puente correcto entre la transacción y el efecto externo (`16` §8);
las otras son `BEFORE_COMMIT` —aún puede vetar el commit lanzando—, `AFTER_ROLLBACK` para
compensar y `AFTER_COMPLETION`, que corre pase lo que pase sin saber cuál de las dos ocurrió.

**🔬 El detalle.** La combinación que casi siempre quieres es `AFTER_COMMIT` + `@Async`: el
commit ya ocurrió, el hilo del request queda libre y el efecto externo no retiene la conexión
de base de datos. Y el límite sigue ahí: entre el commit y el listener no hay atomicidad, así
que si el proceso muere en medio el evento se perdió. Cuando eso no es tolerable, la respuesta
es el patrón outbox.

---

## Capítulo 19 — Resiliencia

### 19 → 1

> ¿Por qué una dependencia lenta hace más daño que una caída, si técnicamente sigue
> respondiendo?

**⏱️ 30 segundos.** Porque un error libera el hilo de inmediato y una espera lo **retiene**.
Tu servicio se muere por un proveedor que no está caído.

**🗣️ 2 minutos.** Con 200 hilos de Tomcat y un proveedor que tarda 30 segundos, bastan 200
peticiones simultáneas para que no quede ni un hilo libre, y entonces dejan de responder
también los endpoints que no tocan ese proveedor —incluido el `/health`—. Una caída
limpia, en cambio, devuelve el hilo en milisegundos: duele en las peticiones que dependen
del proveedor y no arrastra al resto. Por eso el timeout es el primer patrón: convierte una
lentitud en un fallo, que es algo que sí sabes manejar.

**🔬 El detalle.** La cuenta que hace visible el contagio: 200 hilos entregados a un
proveedor de 30 s dejan al servicio **entero** en unas 6,7 peticiones por segundo, incluidas
las que no tocan al proveedor. Y por eso el patrón que impide el contagio no es el circuit
breaker sino el **bulkhead** (pregunta 11): acota cuántos de tus hilos puede secuestrar una
sola dependencia, de modo que el resto del servicio sobreviva aunque esa parte se degrade.

---

### 19 → 2

> Explica por qué sin timeout ningún otro patrón de este capítulo funciona.

**⏱️ 30 segundos.** Porque todos necesitan que la llamada **termine** para actuar. Una
llamada que no termina no dispara el retry, no registra un fallo en el breaker y no libera
el hueco del bulkhead.

**🗣️ 2 minutos.** El retry solo reintenta cuando el intento anterior concluyó; el circuit
breaker cuenta resultados, y una llamada colgada no es un resultado; el bulkhead se llena
de huecos ocupados por llamadas que nunca vuelven. El resultado es un servicio con cinco
patrones configurados, un tablero lleno de gráficas y ninguna protección real. Y es
frecuente porque **ningún cliente HTTP de Java trae timeout por defecto** (`13`).

**🔬 El detalle.** El matiz que se confunde a menudo: el `TimeLimiter` de Resilience4j **no**
es ese timeout. Pone un tope al tiempo de una llamada **asíncrona** —algo que se pueda
cancelar desde fuera—, y sobre una llamada bloqueante el único que corta de verdad es el
timeout del cliente HTTP, porque es el que tiene el socket. Tener `TimeLimiter` configurado
sobre código bloqueante es exactamente el tablero lleno de gráficas sin protección.

---

### 19 → 3

> Tu endpoint promete 2 segundos y llama a dos proveedores en serie. ¿Cómo repartes el
> presupuesto y qué margen dejas?

**⏱️ 30 segundos.** Repartiendo de fuera hacia dentro: unos 700 ms de timeout duro a cada
proveedor y ~600 ms de margen para lo tuyo —serialización, base de datos, GC—.

**🗣️ 2 minutos.** El error típico es dar 2 segundos a cada llamada "por si acaso": entonces
el peor caso son 4 segundos y has incumplido tu propio contrato. El presupuesto se reparte
y se resta; si además hay reintentos, el cálculo debe incluirlos, porque tres intentos de
700 ms más backoffs se comen el presupuesto entero. Cuando las cuentas no salen, la
decisión no es subir el timeout: es paralelizar las llamadas, cachear una de ellas, o
renegociar el contrato de latencia.

**🔬 El detalle.** Paralelizar cambia la aritmética de suma a máximo: dos llamadas de 700 ms
en paralelo cuestan 700 ms, no 1 400, y liberan presupuesto para el margen. El precio, que hay
que decir junto a la propuesta, es que ocupas dos huecos a la vez —dos hilos y dos puestos de
bulkhead por petición—, así que la concurrencia que soporta el servicio se reduce a la mitad
por ese camino. Y el margen de 600 ms no es relleno: cubre serialización, base de datos y una
pausa de GC, que son justo las que aparecen bajo carga.

---

### 19 → 4

> ¿Cuáles son las dos condiciones que debe cumplir una operación para que reintentarla
> sea correcto?

**⏱️ 30 segundos.** Que sea **idempotente** —o tenga una clave de idempotencia que el otro
lado respete— y que el fallo sea **transitorio**.

**🗣️ 2 minutos.** Sin idempotencia, reintentar un `POST` que registra un movimiento puede
duplicarlo: el primero llegó y lo que se perdió fue la respuesta. Y reintentar un 400 o un
404 es gasto puro, porque la petición no va a cambiar de opinión — por eso
`retry-exceptions` es una lista blanca de excepciones transitorias y no un "reintenta todo".
La tercera condición, implícita, es que quepa en el presupuesto de tiempo.

**🔬 El detalle.** La idempotencia no se decide en tu lado: una clave de idempotencia solo
sirve si **el otro extremo la respeta y la deduplica** (`10`), así que es una cláusula del
contrato de su API, no una configuración tuya. Mientras no puedas citar esa cláusula, un
`POST` no es reintentable por mucho que tu YAML diga lo contrario. Y en el YAML la forma de
declarar la segunda condición es `retry-exceptions` con excepciones concretas —`IOException`
y poco más—: sin esa lista blanca reintentas también los 4xx.

---

### 19 → 5

> ¿Qué es el jitter y qué le pasa a un proveedor que se recupera si cien clientes
> reintentan sin él?

**⏱️ 30 segundos.** Es una aleatoriedad añadida al intervalo de espera. Sin él, los cien
reintentan en el mismo instante y vuelven a tumbar al proveedor justo cuando se levanta.

**🗣️ 2 minutos.** El backoff exponencial sin jitter sincroniza a todos los clientes que
fallaron a la vez: reintentan a 1 s, a 2 s y a 4 s **juntos**. Lo que has construido es un
ariete periódico que impide la recuperación, y el patrón se llama *thundering herd*. Con
`enable-randomized-wait`, cada cliente espera un intervalo ligeramente distinto y la carga
se reparte. Es la diferencia entre un retry que ayuda y uno que alarga la caída.

**🔬 El detalle.** Son dos propiedades distintas y hacen falta las dos:
`enable-exponential-backoff` con `exponential-backoff-multiplier: 2` produce la progresión
200 ms, 400 ms, 800 ms, y `enable-randomized-wait` es lo que añade el ruido. Es la misma idea
que el jitter del TTL de una caché (`17`): cualquier mecanismo que ponga a muchos clientes de
acuerdo en un instante necesita desparramarlos.

---

### 19 → 6

> `max-attempts: 3` con un timeout de 700 ms: ¿cuánto puede tardar la operación completa
> en el peor caso, y qué implica para el presupuesto del endpoint?

**⏱️ 30 segundos.** Unos **2,1 segundos** de llamadas más los backoffs entre ellas —con
200 ms y multiplicador 2, otros 600 ms—: cerca de 2,7 s. Si el presupuesto eran 2 s, el
retry se lo comió entero.

**🗣️ 2 minutos.** Y hay un detalle de lectura que descuadra el presupuesto: `max-attempts: 3`
son tres llamadas **totales** —el intento original más dos reintentos—, así que en el peor
caso el proveedor recibe el triple de tráfico, no el cuádruple. Quien lo lee al revés
presupuesta cuatro llamadas donde solo hay tres: sobreestima la carga en un 33 % y, peor,
cuenta con un intento que no existe para cumplir su SLA. La conclusión
práctica es que **retry y timeout se diseñan juntos**: o bajas el timeout por intento, o
bajas los intentos, o aceptas que ese endpoint no cumple su SLA cuando el proveedor falla.

**🔬 El detalle.** Y el coste no se paga solo en latencia: sobre un método **bloqueante**,
el retry de Resilience4j **no suelta el hilo del request**. Los tres intentos y los dos
backoffs ocurren en el mismo hilo de Tomcat, que queda retenido los 2,7 s enteros —600 ms de
ellos sin hacer nada, esperando— frente a los 700 ms de la llamada sin retry, con una conexión
del pool saliente ocupada en cada intento. Reintentar es barato en CPU y caro en hilos:
multiplícalo por la concurrencia antes de subir `max-attempts`.

---

### 19 → 7

> ¿Qué estado tiene hoy Spring Retry y cómo contestarías a "¿usas `@Retryable`?" en una
> entrevista?

**⏱️ 30 segundos.** Está **archivado**: su repositorio redirige a `spring-attic`. La
respuesta es "lo tenemos en servicios existentes, pero para algo nuevo va Resilience4j".

**🗣️ 2 minutos.** Contestar solo "sí, uso `@Retryable`" suena a no haber mirado el estado
de tus dependencias; contestar "no, eso está muerto" es igual de flojo si tu empresa lo
tiene en veinte servicios. La respuesta buena reconoce las dos cosas: sigue funcionando y
no hay urgencia por arrancarlo, pero cualquier servicio nuevo usa Resilience4j, que además
trae los otros cuatro patrones. Mezclar librerías distintas para retry y circuit breaker es
precisamente donde el orden de apilado se descontrola.

**🔬 El detalle.** Verificado el 18 de septiembre de 2026: `github.com/spring-projects/spring-retry`
responde 301 hacia `spring-attic/spring-retry`, y ese repositorio está marcado como
archivado.

---

### 19 → 8

> Describe los tres estados de un circuit breaker y qué ocurre exactamente en `OPEN`.

**⏱️ 30 segundos.** `CLOSED` deja pasar y cuenta; `OPEN` rechaza **sin tocar la red**,
fallando con `CallNotPermittedException`; `HALF_OPEN` deja pasar unas pocas llamadas de
prueba y decide si cierra o vuelve a abrir.

**🗣️ 2 minutos.** Lo importante de `OPEN` es que el fallo es inmediato y local: no se
consume un hilo, no se espera un timeout y no se molesta al proveedor, que es justo lo que
necesita para recuperarse. La transición a `HALF_OPEN` ocurre sola tras
`wait-duration-in-open-state`, y `permitted-number-of-calls-in-half-open-state` limita
cuántas pruebas se hacen: si pasaran todas de golpe, la recuperación se convertiría en otra
avalancha.

**🔬 El detalle.** Con la configuración del curso son 30 s de `OPEN` y 3 llamadas de prueba.
El detalle que hay que haber pensado es que en `OPEN` tu código recibe una excepción que **no
viene del proveedor**: `CallNotPermittedException`. Si tienes fallback, es la causa que le
llega —y conviene distinguirla en el log del error real—; si no lo tienes, es lo que sube al
cliente, así que el manejador de errores tiene que traducirla a algo sensato (un 503) y no a
un 500 genérico.

---

### 19 → 9

> ¿Qué diferencia hay entre una ventana `COUNT_BASED` y una `TIME_BASED`, cuándo
> prefieres cada una, y por qué `minimum-number-of-calls` sigue haciendo falta con las
> dos en un servicio de poco tráfico?

**⏱️ 30 segundos.** `COUNT_BASED` mira las últimas N llamadas; `TIME_BASED` mira los
últimos N segundos. La primera va bien con tráfico constante, la segunda con tráfico
irregular. Y con las dos hace falta `minimum-number-of-calls`, porque el umbral es un
**porcentaje** y con dos llamadas una fallida ya es el 50 %.

**🗣️ 2 minutos.** El problema de la ventana por conteo en un endpoint con poco tráfico es
que arrastra resultados viejos: los diez fallos de hace dos horas siguen dentro de la
ventana y pesan igual que lo de ahora, así que el breaker reacciona a un incidente ya
resuelto. La ventana por tiempo descarta lo antiguo por definición, a cambio de poder
quedarse con muy pocas muestras en periodos tranquilos — y ahí es donde entra el mínimo de
llamadas. En un endpoint que recibe cinco peticiones por hora, sin él tienes circuitos
abriéndose por ruido y fallbacks devolviéndose sin que haya ningún problema real:
`minimum-number-of-calls` exige un mínimo de evidencia antes de calcular la tasa. Es el
parámetro que más se olvida al copiar una configuración de un servicio con tráfico alto a
otro que no lo tiene.

**🔬 El detalle.** En la configuración del curso conviven los tres números —
`sliding-window-size: 20`, `minimum-number-of-calls: 10`, `failure-rate-threshold: 50`— y el
que gobierna **cuándo** abre el circuito es el segundo, no el tamaño de la ventana: hasta
completar el mínimo, el breaker no calcula tasa ninguna y deja pasar todo. Por eso la
aritmética del apilado (pregunta 12) se cuenta contra `minimum-number-of-calls`.

---

### 19 → 10

> Un proveedor responde en 5 segundos sin errores y tu circuito nunca abre. ¿Qué
> parámetro falta?

**⏱️ 30 segundos.** `slow-call-duration-threshold` junto con `slow-call-rate-threshold`:
sin ellos, una llamada lenta no cuenta como fallo y el breaker no ve nada que contar.

**🗣️ 2 minutos.** Es la mitad olvidada del circuit breaker y, por §1 de este capítulo,
justo la que cubre el caso que más daño hace. Configurado el umbral de lentitud, una
respuesta de 5 segundos con el umbral en 1 s se contabiliza como fallo aunque venga con un
200, y el circuito abre protegiendo tus hilos. Quien configura solo `failure-rate-threshold`
tiene un breaker que solo reacciona a caídas limpias, que son las menos peligrosas.

**🔬 El detalle.** Son dos propiedades y se necesitan juntas: `slow-call-duration-threshold`
define qué es lenta —1 s en la configuración del curso— y `slow-call-rate-threshold` qué
porcentaje de lentas basta para abrir. Y el límite honesto del patrón: el breaker no rescata
la llamada en curso, que ya se comió sus 5 segundos de hilo; lo que hace es que la siguiente
falle rápido. Quien necesita cortar **esa** llamada necesita el timeout del cliente, que es
otra vez la pregunta 2.

---

### 19 → 11

> Diferencia bulkhead de rate limiter: ¿de qué protege cada uno y a quién?

**⏱️ 30 segundos.** El bulkhead limita **concurrencia** y te protege a ti; el rate limiter
limita **llamadas por unidad de tiempo** y protege al proveedor, normalmente porque te
impone una cuota.

**🗣️ 2 minutos.** El bulkhead reserva un número máximo de llamadas simultáneas hacia una
dependencia, de modo que una dependencia lenta no se lleve todos tus hilos y tumbe también
los endpoints que no la usan — es el mamparo del barco. El rate limiter no mira cuántas
hay a la vez sino cuántas por segundo, y su motivación suele ser contractual. Confundirlos
lleva a poner un rate limiter creyendo que protege tus hilos, cuando cien llamadas lentas
por minuto caben perfectamente dentro de la cuota y te hunden igual.

**🔬 El detalle.** El bulkhead tiene dos implementaciones y no dan lo mismo. El de
**semáforo** limita la concurrencia dentro del hilo del llamante: es barato y conserva el
contexto —`SecurityContext`, MDC, la transacción—, pero el hilo sigue siendo tuyo mientras
espera. El de **thread pool** aísla de verdad la ejecución en otro pool, a cambio de perder
ese contexto al cruzar de hilo (`08`), que es el mismo peaje de `@Async`. En un servicio
servlet con `@Transactional` alrededor, el de semáforo suele ser el que no rompe nada.

---

### 19 → 12

> Escribe el orden correcto de apilado y explica qué se rompe si el circuit breaker
> envuelve al retry en lugar de al revés.

**⏱️ 30 segundos.** `Retry( CircuitBreaker( RateLimiter( TimeLimiter( Bulkhead( llamada )))))`.
Si el breaker envuelve al retry, solo ve **una llamada por petición**: se vuelve ciego a
los intentos, tarda más en abrir y el proveedor recibe el triple de tráfico.

**🗣️ 2 minutos.** Con el orden correcto, cuando el circuito está abierto los reintentos
fallan rápido y sin salir a la red: no se desperdicia tiempo ni se molesta a un proveedor
que ya sabes que está roto. Y hay una consecuencia que conviene tener clara porque es
contraintuitiva: como cada intento atraviesa el breaker, **tres intentos fallidos
registran tres fallos**, así que el circuito abre antes en número de peticiones de lo que
sugiere el umbral — y eso es bueno. Con el orden invertido, el breaker solo ve una llamada
por petición: se vuelve ciego a los intentos, tarda más en abrir y mientras tanto el
proveedor recibe el triple de tráfico. Medido con ventana 10 al 50 % y tres intentos: el
orden recomendado abre hacia la segunda petición con ~5 llamadas al proveedor; el
invertido, hacia la quinta con ~15. El bulkhead va lo más adentro posible para medir la
concurrencia real contra la dependencia y no la de los reintentos — y ahí hay un matiz que
conviene saber antes de prometer que reordenarás nada: de las cinco capas solo cuatro
tienen su `*-aspect-order` configurable; el del bulkhead está fijado en
`Ordered.LOWEST_PRECEDENCE - 1` en 2.2.0, así que es el suelo de la pila por diseño.

**🔬 El detalle.** Las cuatro configurables son `retry-aspect-order`,
`circuit-breaker-aspect-order`, `rate-limiter-aspect-order` y `time-limiter-aspect-order`, con
valores por defecto `LOWEST_PRECEDENCE - 5`, `- 4`, `- 3` y `- 2` —menor valor, más afuera—,
y la quinta la devuelve `BulkheadConfigurationProperties.getBulkheadAspectOrder()` fija en
`- 1`. La consecuencia práctica: si alguna vez necesitas el bulkhead por fuera de otro
patrón, lo que se mueve es el `order` de los demás, nunca el suyo.

---

### 19 → 13

> ¿Por qué un retry no debe envolver nunca a una transacción abierta?

**⏱️ 30 segundos.** Porque la conexión de base de datos queda retenida durante todos los
intentos y sus backoffs, y con algo de concurrencia eso agota el pool.

**🗣️ 2 minutos.** Es la combinación del orden de interceptores de `05` §7 con el
agotamiento de pool de `15`: si el proxy de `@Transactional` queda por fuera del de retry,
la transacción se abre una vez y permanece viva durante los tres intentos más las esperas
—fácilmente segundos— sin que la base esté haciendo nada. Veinte peticiones concurrentes
por ese camino dejan el pool a cero y el síntoma apunta a la base de datos, que es
inocente. El diseño correcto es reintentar **fuera** del límite transaccional, o reintentar
la unidad de trabajo completa desde arriba.

**🔬 El detalle.** Y no basta con desearlo, porque ese orden no está garantizado: Spring
registra `@Transactional` con `Ordered.LOWEST_PRECEDENCE` y los aspectos de Resilience4j se
sitúan a su lado, de modo que quién queda por fuera depende del orden de registro, que no es
contrato (`05`). La forma robusta de decidirlo no es afinar precedencias: es **separar en dos
beans** —uno que reintenta, otro que es transaccional— y que el límite lo ponga la llamada.
La cuenta de lo que cuesta equivocarse: veinte peticiones concurrentes reteniendo una conexión
durante dos segundos de backoff contra un Hikari de diez.

---

### 19 → 14

> ¿Qué hace que un fallback sea honesto, y en qué caso el fallback correcto es no tener
> ninguno?

**⏱️ 30 segundos.** Que **degrade** en lugar de mentir: devolver el último precio conocido
marcado como tal, no un `0` disfrazado de dato bueno. Y cuando no hay degradación honesta
posible —dinero de por medio—, lo correcto es propagar un 503 rápido.

**🗣️ 2 minutos.** Un fallback que devuelve una lista vacía o un cero convierte un fallo
visible en corrupción silenciosa: el sistema "funciona", nadie recibe una alerta y los
números están mal. Por eso el fallback debe loguear siempre la causa y, cuando sea posible,
marcar la respuesta como degradada para que el cliente decida. En banca, inventar un valor
es peor que no responder: un 503 se reintenta, un importe equivocado se contabiliza.

**🔬 El detalle.** Antes de discutir si el fallback es honesto conviene comprobar que existe.
En Resilience4j 2.2.0, `FallbackExecutor.execute` resuelve el `fallbackMethod` **por reflexión
en cada invocación** del método anotado; si la firma no casa —falta el `Throwable` final, sobra
un parámetro— captura la `NoSuchMethodException`, escribe un `WARN` con `No fallback method
match found` y sigue adelante **como si no hubieras configurado ninguno**. No falla el arranque
ni se rompe ninguna petición, y el aviso sale en la primera llamada al método, falle o no el
proveedor. La única defensa real es un test que fuerce el fallo y compruebe que el fallback
responde.

---

### 19 → 15

> ¿Por qué un circuito que abre sin alerta es peor que no tener circuito?

**⏱️ 30 segundos.** Porque enmascara la caída: el servicio responde con fallbacks, los
tableros de error no suben y nadie se entera de que la dependencia está rota.

**🗣️ 2 minutos.** Sin circuito, una caída del proveedor se ve de inmediato en la tasa de
errores 5xx y alguien actúa. Con circuito y sin alerta, el sistema absorbe el fallo y lo
convierte en datos degradados que se propagan aguas abajo; el problema se descubre días
después en una reconciliación. Por eso la alerta sobre el **cambio de estado** del circuito
—no sobre la tasa de error, que precisamente ya no sube— es parte del patrón y no un
extra. Los eventos están en `/actuator/circuitbreakerevents` y las métricas en Micrometer
(`23`).

**🔬 El detalle.** Son dos endpoints y contestan preguntas distintas:
`/actuator/circuitbreakers` da el **estado actual** de cada instancia —lo que miras durante un
incidente— y `/actuator/circuitbreakerevents` da las **transiciones**, que es de donde sale la
alerta, porque lo que hay que vigilar es el `CLOSED → OPEN`. Dicho de otra forma: el circuito
convierte una señal ruidosa (5xx) en una silenciosa (fallbacks), así que la observabilidad
tiene que mudarse con ella.

---

## Capítulo 20 — Spring Security: el mecanismo

### 20 → 1

> ¿Cuántos filtros registra Spring Security en el contenedor de servlets, y quién ejecuta a
> los demás?

**⏱️ 30 segundos.** **Uno**: un `DelegatingFilterProxy` registrado con el nombre
`springSecurityFilterChain`. Los otros veinte los ejecuta el `FilterChainProxy`, que es un
bean de Spring y vive dentro de ese único filtro.

**🗣️ 2 minutos.** Tomcat solo sabe de filtros de Servlet, y un filtro de Servlet no es un
bean: `DelegatingFilterProxy` es justamente el puente de `08` §4 —Tomcat registra el proxy y
el proxy delega en el bean—. Dentro, `FilterChainProxy` hace algo que ningún filtro normal
hace: **elige** cuál `SecurityFilterChain` aplica a esta URL, ejecuta su lista interna en el
orden que fija Security y limpia el `SecurityContextHolder` en un `finally`. Esa limpieza es
lo que impide que el usuario de una petición se filtre a la siguiente cuando Tomcat reutiliza
el hilo. Lo que tú decides no es el orden de esa lista, sino dónde insertas un filtro propio,
con `addFilterBefore(...)` o `addFilterAfter(...)` nombrando al vecino.

**🔬 El detalle.** Boot registra el `DelegatingFilterProxy` con orden `-100`
(`SecurityProperties.DEFAULT_FILTER_ORDER`), y ese número decide si **tu** filtro corre antes
o después de Security: uno de correlación que quiera etiquetar también los 401 va con orden
menor; uno que lea el usuario autenticado, con orden mayor. Ese orden **no tiene nada que ver**
con el `@Order` de un `SecurityFilterChain`, que solo decide qué cadena se prueba primero.

---

### 20 → 2

> Distingue `securityMatcher` de `requestMatchers`. ¿Qué pasa si ninguna cadena matchea una URL?

**⏱️ 30 segundos.** `securityMatcher` decide **qué peticiones entran a esta cadena**;
`requestMatchers`, dentro de `authorizeHttpRequests`, decide **qué se le exige a las que ya
entraron**. Si ninguna cadena matchea una URL, esa URL sale **sin ninguna regla aplicada**.

**🗣️ 2 minutos.** Son dos niveles distintos y confundirlos es el error de configuración más
caro del capítulo: uno selecciona la lista de filtros, el otro es una regla dentro de esa
lista. Y hay un segundo efecto de selección: `FilterChainProxy` toma **la primera cadena que
matchea** y no evalúa las demás, así que una cadena sin `securityMatcher` declarada con
`@Order` bajo deja muertas a todas las que vengan detrás. Dentro de una cadena pasa lo mismo a
otra escala: las reglas se evalúan en orden de declaración, gana la primera que matchea, y por
eso `anyRequest().authenticated()` va siempre al final, como cierre.

**🔬 El detalle.** Esa diferencia entre "no entra a la cadena" y "entra y se le permite todo"
es la que separa `permitAll()` de dejar la URL fuera del `securityMatcher`: con `permitAll()`
la petición sí atraviesa la cadena —CSRF, cabeceras de seguridad, CORS siguen corriendo— y
simplemente no se le exige autenticación. Cuando lo que quieres es que una ruta ni pase por
Security, se la deja fuera del `securityMatcher`. Y cuando "la regla no se aplica", lo primero
es `logging.level.org.springframework.security=DEBUG`: imprime qué cadena se eligió y por qué
filtros pasó, y casi siempre la respuesta es que matcheó otra cadena.

---

### 20 → 3

> "Spring Security se configura con `antMatchers`": corrige la afirmación con precisión y di
> desde qué versión.

**⏱️ 30 segundos.** Desde **Spring Security 6** no existe: `WebSecurityConfigurerAdapter` se
eliminó, y con él `antMatchers`, `mvcMatchers` y `authorizeRequests`. Hoy se declara un
`@Bean SecurityFilterChain` y todo es `requestMatchers` dentro de `authorizeHttpRequests`.

**🗣️ 2 minutos.** El cambio no es cosmético: con el adapter, la configuración era herencia
—extendías una clase y sobreescribías métodos—, y solo había una cadena cómoda de expresar.
Con el bean, la cadena es un objeto más del contenedor, puedes declarar varias y ordenarlas
con `@Order`, y es lo que hace natural tener una cadena para `/api/**`, otra para Actuator y
otra para el login. El bean vive en una `@Configuration` con `@EnableWebSecurity`; declararlo
es además lo que apaga la autoconfiguración de Boot, la que pedía login para todo con la
contraseña aleatoria que imprime a nivel `WARN` en el arranque.

**🔬 El detalle.** Es un buen filtro de entrevista porque casi todo el material de internet es
anterior a 2022 y no compila hoy. Y hay un segundo escalón que viene: Boot 4 arrastra Spring
Security 7, donde el estilo lambda deja de ser opcional y se retiran las clases deprecadas en
la línea 6.x. La forma del capítulo sobrevive; la migración completa es del apéndice `A04`.

---

### 20 → 4

> Tu regla dice `hasRole("ANALYST")` y el usuario tiene la authority `ANALYST`. ¿Qué código
> HTTP recibe y por qué?

**⏱️ 30 segundos.** Un **403**, perfecto y silencioso. `hasRole("ANALYST")` es un atajo de
`hasAuthority` que **añade el prefijo `ROLE_`** y compara contra `ROLE_ANALYST`, que el usuario
no tiene.

**🗣️ 2 minutos.** Para Spring Security un rol y un permiso son la misma cosa: un
`GrantedAuthority`, que es un `String` con semántica. La única diferencia es el prefijo que
`hasRole` pone por ti. Por eso la regla de oro es elegir una convención y sostenerla: si tu
tabla guarda `ANALYST` a secas, o usas `hasAuthority("ANALYST")`, o guardas `ROLE_ANALYST`. Es
403 y no 401 porque el usuario **sí** está autenticado: sabemos quién es, y no puede. Y no hay
error en el log ni cuerpo en la respuesta, que es lo que convierte quince minutos de trabajo en
media tarde.

**🔬 El detalle.** El prefijo no está grabado en piedra: se cambia declarando un bean
`GrantedAuthorityDefaults` con otro, y entonces `hasRole` prefija ese. Es útil cuando heredas
un esquema de autoridades ajeno, y es también la razón de que "`ROLE_` es obligatorio" sea una
sobregeneralización: lo obligatorio es que coincidan lo que guardas y lo que compara la regla.
El mismo par reaparece en los tests con `@WithMockUser` (pregunta 14), y es donde más se paga.

---

### 20 → 5

> ¿Quién decide si una petición denegada sale como 401 o como 403, y con qué criterio?

**⏱️ 30 segundos.** El **`ExceptionTranslationFilter`**, que está justo antes del
`AuthorizationFilter`. Si la excepción es una `AuthenticationException` **o** el usuario no
está autenticado, llama al `AuthenticationEntryPoint` → 401. En cualquier otro caso va al
`AccessDeniedHandler` → 403.

**🗣️ 2 minutos.** El filtro envuelve al resto de la cadena en un `try` y captura las dos
familias: `AuthenticationException` y `AccessDeniedException`. El criterio, tal como está
escrito en el pseudocódigo de la documentación, es `!authenticated || ex instanceof
AuthenticationException`: si todavía no sé quién eres tiene sentido pedirte credenciales, así
que 401 y punto de entrada; si ya sé quién eres, pedírtelas otra vez no arregla nada —te falta
un permiso, no una credencial—, así que 403. Esa es exactamente la semántica de la tabla: 401
significa "reintenta con credencial", 403 significa "no reintentes".

**🔬 El detalle.** La vecindad importa: solo traduce lo que explote **por dentro** de él, y el
`AuthorizationFilter` —el último de la cadena, el que consulta el `AuthorizationManager` y
lanza `AccessDeniedException`— está justo detrás. Un filtro propio que lance antes del
`ExceptionTranslationFilter` no recibe esta traducción y sale como un 500. Y el caso híbrido es
el de method security: esa denegación nace en un proxy AOP, dentro del `DispatcherServlet`, muy
por detrás de la cadena, y aun así sube hasta aquí y se traduce igual **si nadie la atrapó
antes** (pregunta 6).

---

### 20 → 6

> Tu `@RestControllerAdvice` devuelve `ProblemDetail` para todo, pero los 403 llegan con cuerpo
> vacío. ¿Por qué, y qué dos beans lo arreglan?

**⏱️ 30 segundos.** Porque esos 403 nacen **en la cadena de filtros**, antes de que el
`DispatcherServlet` intervenga: tu `@RestControllerAdvice` nunca los ve. Se arregla
registrando un **`AuthenticationEntryPoint`** y un **`AccessDeniedHandler`** propios, que son
quienes escriben la respuesta.

**🗣️ 2 minutos.** El manejo centralizado de `10` §4 es una pieza de MVC: vive dentro del
`DispatcherServlet` y solo alcanza a lo que pasa por él. Todo lo que Security rechaza en la
cadena termina antes, así que tu API responde con el cuerpo por defecto del contenedor y sin el
`ProblemDetail` de `10` §5 — dos formatos de error distintos en la misma API, que es justo lo
que `10` intenta evitar. Los dos beans son los dos escritores: el entry point escribe el 401, el
access denied handler escribe el 403, y ahí serializas el mismo `ProblemDetail` que usa el
resto de la aplicación.

**🔬 El detalle.** Y aquí está la asimetría que desconcierta y que conviene decir antes de que
la pregunten: la `AccessDeniedException` de **method security** sí puede llegar a MVC, porque
el proxy corre dentro del `DispatcherServlet`. Si declaraste un
`@ExceptionHandler(AccessDeniedException.class)`, ese handler **la atrapa primero** y Security
no llega a verla; si no lo declaraste, la excepción sube y el `ExceptionTranslationFilter` la
traduce igual. La misma excepción, entonces, se maneja en dos sitios distintos según dónde se
lanzó y qué handlers declaraste: la de la cadena de filtros nunca llega a MVC, la del proxy sí.

---

### 20 → 7

> ¿Por qué un 403 es más difícil de diagnosticar que un 401, y qué miras primero?

**⏱️ 30 segundos.** Porque el 401 se diagnostica solo —falta la credencial o caducó— y el 403
tiene diez causas posibles y **Security no dice cuál**: el cuerpo llega vacío. Lo primero es
`logging.level.org.springframework.security=DEBUG`.

**🗣️ 2 minutos.** El catálogo de causas de un 403 es largo y todas se parecen desde fuera: el
prefijo `ROLE_` que no coincide (pregunta 4), la cadena equivocada porque otra matcheó primero
(pregunta 2), una authority mal mapeada desde la base o desde los claims, el contexto perdido
en un `@Async` (pregunta 9), un `@PreAuthorize` cuyo SpEL evalúa a `false` por un argumento que
no es el que crees. El `DEBUG` te dice qué cadena se eligió y por qué filtros pasó la petición,
que descarta la mitad del catálogo en un vistazo.

**🔬 El detalle.** La cura completa son dos cosas juntas, no una: el `DEBUG` en desarrollo y,
en producción, un **`AccessDeniedHandler` propio que registre qué regla denegó y con qué
authorities llegaba el usuario** — que es el mismo bean que necesitabas para el `ProblemDetail`
de la pregunta 6, así que sale gratis. Un 403 sin log es el peor de los dos códigos
precisamente porque el sistema se comporta como si todo estuviera bien.

---

### 20 → 8

> Un `@PreAuthorize` no se evalúa nunca y el método corre igual. Nombra las dos causas más
> probables.

**⏱️ 30 segundos.** Una: falta **`@EnableMethodSecurity`**, que el starter no activa solo. Dos:
**no hay proxy en medio** — self-invocation, o un método `private`, `final` o `static`.

**🗣️ 2 minutos.** Method security es el proxy AOP de `05` con otro sombrero, así que hereda
todas sus limitaciones. Si otro método de la misma clase llama a `apply()`, la llamada no sale
del objeto, no pasa por el proxy y la anotación no se evalúa: es la self-invocation de `05` §5.
Lo que cambia es la consecuencia. Allí el fallo silencioso era una transacción perdida; aquí es
**una comprobación de seguridad que no ocurrió**, y el método hace su trabajo sin que nadie
verifique nada. Ningún test lo delata, porque el test también pasa.

**🔬 El detalle.** `@EnableMethodSecurity` sustituye a `@EnableGlobalMethodSecurity`, retirado,
y en Security 6 ya viene con `prePostEnabled = true`, así que basta con ponerla. Y conviene
recordar que method security **no sustituye** a la de URL: la de URL rechaza antes de entrar y
es más barata; la de método protege aunque la llamada venga de un `@Scheduled`, de un listener o
de otro controller, y es la única que puede expresar una regla que depende del dato —"puede ver
el ajuste si es suyo"— porque tiene acceso a los argumentos en SpEL.

---

### 20 → 9

> Un método `@Async` lanza `AccessDeniedException` con un usuario que sí tiene el rol. ¿Qué
> pasó y cómo se corrige?

**⏱️ 30 segundos.** El `SecurityContext` vive en un `ThreadLocal` y **no cruza de hilo**: el
hilo del pool arrancó sin contexto, así que para Security ahí no hay nadie autenticado. Se
corrige envolviendo el executor en un `DelegatingSecurityContextAsyncTaskExecutor`.

**🗣️ 2 minutos.** El síntoma es inconfundible y por eso vale como pregunta: el **mismo**
usuario que sí tiene el rol recibe la denegación, y solo dentro del método asíncrono. Es el
mismo mecanismo de `08` y el mismo que pierde la transacción y el MDC: `@Async`, un
`CompletableFuture` con executor propio o un `parallelStream()` estrenan un hilo sin
`SecurityContext`. La propagación es la de `18` §5, y hay que decir una cosa sobre ella:
propagar **copia**, no comparte. El hilo asíncrono recibe una copia del contexto en el momento
del envío, y lo que ocurra después en el hilo original no le llega.

**🔬 El detalle.** Dos cosas más que suelen faltar. En un controller conviene no leer el
`SecurityContextHolder` a mano: `Authentication` como parámetro del método o
`@AuthenticationPrincipal` son testeables y no atan tu servicio al `ThreadLocal`. Y en WebFlux
esta pregunta no existe tal cual: no hay `ThreadLocal` que valga, el contexto viaja en la
suscripción y se lee con `ReactiveSecurityContextHolder`.

---

### 20 → 10

> ¿Por qué `MODE_INHERITABLETHREADLOCAL` no resuelve el problema anterior cuando hay un pool?

**⏱️ 30 segundos.** Porque hereda el contexto a los hilos **hijos**, y el hilo de un pool no es
hijo de nadie: lo creó el pool al arrancar, mucho antes de que llegara tu petición.

**🗣️ 2 minutos.** La herencia de un `InheritableThreadLocal` ocurre en el momento de **crear**
el hilo, copiando lo que tenía el creador. Un `ThreadPoolTaskExecutor` crea sus hilos al
inicializarse o al crecer, en un contexto que no es el de ninguna petición, y luego los
**reutiliza**: el hilo que ejecuta tu tarea no nació de tu petición, así que no hay nada que
heredar. Peor aún, si algún día heredó un contexto lo conserva, y entonces la tarea corre con
el usuario equivocado —un fallo mucho más grave que el 403—. La solución correcta sigue siendo
decorar el executor, que copia el contexto **por tarea** y lo limpia al terminar.

**🔬 El detalle.** Es el mismo razonamiento que explica por qué `FilterChainProxy` limpia el
`SecurityContextHolder` en un `finally`: con hilos reutilizados, lo peligroso no es que falte
el contexto, es que sobre. Una fuga de contexto entre peticiones consecutivas sobre el mismo
hilo de Tomcat es un fallo de autorización que no da 403: da un 200 con los datos de otro.

---

### 20 → 11

> ¿Qué guarda el prefijo `{bcrypt}` dentro del hash y qué problema operativo resuelve?

**⏱️ 30 segundos.** Guarda **el identificador del algoritmo dentro del propio hash**
(`{bcrypt}$2a$10$…`, `{noop}password`, `{scrypt}…`). Resuelve poder cambiar de algoritmo sin
forzar a todos los usuarios a cambiar la contraseña el mismo día.

**🗣️ 2 minutos.** El bean es `PasswordEncoderFactories.createDelegatingPasswordEncoder()`. Al
**validar**, el `DelegatingPasswordEncoder` lee el prefijo y delega en el encoder que
corresponda, así que los hashes viejos se siguen verificando; al **codificar**, usa el
`idForEncode` actual —bcrypt en la fábrica por defecto—, así que todo lo nuevo o rehasheado
queda con el algoritmo nuevo. La migración deja de ser un big-bang y se vuelve un desplazamiento
gradual.

**🔬 El detalle.** No hay `PasswordEncoder` por defecto, y es a propósito. Si el hash de la
base no lleva prefijo —o está en texto plano— el id se resuelve a `null` y la validación
termina con `java.lang.IllegalArgumentException: There is no PasswordEncoder mapped for the id
"null"`, que es un mensaje que conviene reconocer porque parece un problema de configuración y
es un problema de datos. Y el ⏱️ que viene con bcrypt: con el `strength` por defecto (10) son
decenas de milisegundos de CPU **en el hilo del request** por validación, y cada punto duplica
ese costo — tiempo bien gastado en un login y una denegación de servicio regalada si alguien
puede golpear ese endpoint mil veces por segundo.

---

### 20 → 12

> ¿Por qué `EndpointRequest.toAnyEndpoint()` y no `/actuator/**`?

**⏱️ 30 segundos.** Porque resuelve las rutas reales **en tiempo de ejecución**: respeta
`management.endpoints.web.base-path` y el puerto de management separado. `/actuator/**` escrito
a mano deja de proteger nada en cuanto alguien cambia el prefijo.

**🗣️ 2 minutos.** Es una regla que se rompe sola y en silencio: cambias el base-path por una
convención de plataforma, el matcher deja de matchear, la cadena de Actuator no se aplica y
`/actuator/heapdump` —o su nueva ruta— queda expuesto sin que ningún test hable. Con
`EndpointRequest` el matcher se calcula a partir de la configuración efectiva de Actuator, no
de una cadena literal. Se combina con `.excluding(HealthEndpoint.class)` para que el
balanceador pueda sondear sin credencial, y con `@Order(0)` para que esta cadena se evalúe
antes que la de la API.

**🔬 El detalle.** Dos matices del entorno regulado. Uno: lo correcto es abrir el **grupo de
probes**, no el `health` detallado, porque `show-details` fuera de `never` publica el estado de
tu base de datos a quien pregunte. Dos: `httpBasic` basta aquí porque a Actuator lo consume una
herramienta —un scraper no gana nada con una sesión—, y por eso esta cadena se configura
distinto de la de usuarios. El contexto completo está en `23` §2, que manda expresamente a este
capítulo: Actuator no autentica nada por sí mismo.

---

### 20 → 13

> Una API con `Authorization: Bearer` desactiva CSRF y una con cookie de sesión no. ¿Cuál es
> el argumento exacto?

**⏱️ 30 segundos.** El ataque CSRF depende de que **el navegador adjunte la credencial solo**.
Una cookie se adjunta sola; una cabecera `Authorization` no. Sin adjunto automático no hay
ataque que prevenir, y ahí `csrf.disable()` es una decisión justificada.

**🗣️ 2 minutos.** CSRF va **activado por defecto**, y el `CsrfFilter` valida los métodos **no
seguros** — todo lo que no sea `GET`, `HEAD`, `TRACE` u `OPTIONS`. El escenario que protege es
otro sitio que consigue que tu navegador envíe una petición a tu API con tu cookie pegada; el
token sincronizado rompe eso porque el sitio atacante no puede leerlo. Con un token Bearer, en
cambio, el código del atacante tendría que **poner la cabecera**, y si puede hacerlo es porque
ya tiene el token y CSRF era el menor de tus problemas. Lo que no vale nunca es desactivarlo
"porque los `POST` daban 403": eso es justo la señal de que estaba protegiendo algo.

**🔬 El detalle.** Las tres que producen el mismo ticket —"funciona con curl y no desde el
navegador"— son CSRF, CORS y sesión, y conviene tener la respuesta de las tres. CORS falla
antes de llegar a tu configuración de MVC: el navegador manda un `OPTIONS` de preflight **sin
credenciales**, y si la cadena exige autenticación para todo, ese `OPTIONS` recibe un 401 y el
navegador reporta un error de CORS que no es un error de CORS — por eso se registra en Security
con `http.cors(Customizer.withDefaults())` y un `CorsConfigurationSource` como bean, no solo en
`WebMvcConfigurer`. Y `SessionCreationPolicy.STATELESS` instala un
`NullSecurityContextRepository`: Security ni crea ni consulta `HttpSession` **para guardar el
contexto**, lo que cierra el session fixation por definición y explica por qué la autenticación
se repite en cada petición.

---

### 20 → 14

> Tu test con `@WithMockUser` pasa y producción da 403 con la misma regla. ¿Qué diferencia hay
> entre `roles` y `authorities`?

**⏱️ 30 segundos.** `@WithMockUser(roles = "ANALYST")` **prefija `ROLE_`** a cada valor;
`authorities = "..."` los pone tal cual. Y si declaras `authorities`, **`roles` se ignora**.

**🗣️ 2 minutos.** Es el par de la pregunta 4 visto desde el test: el test construye un usuario
con `ROLE_ANALYST` y la regla `hasRole("ANALYST")` lo acepta; en producción el usuario llega
con `ANALYST` a secas desde la base o desde los claims, y la misma regla lo rechaza. El test no
mintió: probó una combinación que no es la de producción. El arreglo es alinear el test con lo
que realmente emite tu `UserDetailsService` o tu mapeo de claims — y, si son authorities sin
prefijo, usar `authorities` en el test y `hasAuthority` en la regla.

**🔬 El detalle.** Hay un falso verde todavía peor en esta sección: **`MockMvc` no ejecuta la
cadena de filtros por sí solo**. Hace falta `@AutoConfigureMockMvc`, que la registra, o el
post-processor `springSecurity()` en el setup manual; sin eso los tests de seguridad pasan
porque Security nunca corrió. `SecurityMockMvcRequestPostProcessors` hace lo mismo por petición
—`with(user(...))`— y `with(csrf())` es lo que arregla los `POST` que dan 403 con CSRF activo.
Todo esto lo trae `spring-security-test`, en scope `test`, ya versionado por el BOM de Boot.

---

## Capítulo 21 — Identidad federada: OAuth2, OIDC y JWT

### 21 → 1

> "OAuth2 sirve para autenticar usuarios": corrige la afirmación y di qué pieza aporta de
> verdad la autenticación.

**⏱️ 30 segundos.** OAuth2 es un framework de **autorización delegada**: existe para que un
software acceda a un recurso **en nombre** de alguien sin recibir su contraseña. La
autenticación de usuarios la añade **OIDC** encima, con el scope `openid` y el `id_token`.

**🗣️ 2 minutos.** Son dos capas distintas con dos tokens distintos. OAuth2 define el access
token, que dice **qué puede hacer el portador** y va dirigido al resource server. OIDC define
el `id_token`, que dice **quién se autenticó y cuándo** y va dirigido al client. Por eso la
frase es falsa aunque el resultado se le parezca: en un login con Keycloak sí te autenticas,
pero lo hace la capa OIDC, no OAuth2. Decir "OAuth2 autentica" en una entrevista de banca abre
la repregunta inmediata "¿y entonces qué es el `id_token`?", que es donde se cae.

**🔬 El detalle.** La confusión tiene consecuencia práctica, no solo terminológica: si crees
que OAuth2 autentica, aceptas cualquier token del IdP como prueba de identidad, y eso es
exactamente el error de la pregunta 3 —validar un documento dirigido a otro—. Además OIDC no
solo añade un token: añade el documento de descubrimiento en
`.../.well-known/openid-configuration`, que es de donde Boot saca el `jwks_uri` a partir de
`issuer-uri`. La mitad de la configuración del resource server viene de la capa que la frase
niega que exista.

---

### 21 → 2

> ¿Cuál de los cuatro roles de OAuth2 es `inv-api`, y qué implica que nunca vea la contraseña?

**⏱️ 30 segundos.** `inv-api` es el **resource server**: el que guarda y protege el dato. Los
otros tres son el resource owner (el humano), el client (el software que pide) y el
authorization server (el que emite tokens). Nunca ve la contraseña, así que toda su decisión
se reduce a **fiarse o no del papel** que le presentan.

**🗣️ 2 minutos.** Es la fila donde vive casi todo el curso, y donde vives tú en banca: el
authorization server lo opera el equipo de identidad y el client es el portal de otro equipo.
La consecuencia de diseño es que `inv-api` no tiene tabla de usuarios, ni `UserDetailsService`,
ni política de expiración de contraseñas propia; el único problema que le queda es
**validación de tokens**. Y eso es justo lo que resuelve el problema original: seis servicios
con su propia tabla son seis copias de la contraseña, seis políticas y ningún sitio donde
revocar a quien se fue el viernes.

**🔬 El detalle.** Un mismo servicio puede jugar dos papeles a la vez, y confundirlo cuesta un
arranque roto: `spring-boot-starter-oauth2-resource-server` valida lo que recibes,
`...-oauth2-client` pide tokens para lo que llamas. `inv-api` es resource server para su API y
client cuando llama a `inv-supplier`. Que nunca vea la contraseña también cambia el costo por
petición: verificar una firma RS256 son microsegundos de CPU y cero E/S mientras la clave esté
en caché, contra la consulta a base y la conexión del pool que costaba el
`loadUserByUsername` del capítulo `20`.

---

### 21 → 3

> Un portal te manda su `id_token` en vez del access token. ¿Por qué debe fallar, y en qué
> claim se nota?

**⏱️ 30 segundos.** Porque el `id_token` **no es para ti**: es el token que OIDC dirige al
client. Se nota en el claim **`aud`**, que lleva el identificador del client y no `inv-api`.
El único token que un resource server debe aceptar es el access token.

**🗣️ 2 minutos.** Pasa constantemente, y casi siempre sin mala fe: el portal "manda el token
que tenía a mano". El `id_token` cuenta **quién se autenticó y cuándo**, no **qué puede hacer
el portador**; ni siquiera tiene por qué traer los scopes contra los que están escritas tus
reglas. Aceptarlo es aceptar un documento dirigido a otro destinatario, firmado por el mismo
emisor y por tanto con la firma perfecta.

**🔬 El detalle.** Y aquí está la trampa: **por defecto `inv-api` no lo rechaza**. El validador
de `JwtValidators.createDefaultWithIssuer(...)` comprueba `exp`, `nbf` e `iss`, y el `iss` del
`id_token` es el mismo IdP, así que pasa. Sin
`spring.security.oauth2.resourceserver.jwt.audiences=inv-api` —o un
`JwtClaimValidator<List<String>>(AUD, ...)`— el `aud` no se mira y el token entra. Lo que
después falle será un 403 por falta de la authority `SCOPE_inventory.read`, que es un síntoma
que apunta al sitio equivocado. El mismo agujero deja entrar el access token emitido por el
mismo IdP para el servicio de nóminas.

---

### 21 → 4

> "El JWT va cifrado": ¿qué protege realmente la firma y qué no?

**⏱️ 30 segundos.** Va **firmado**, no cifrado. La firma da **integridad y origen**: cambiar un
claim invalida el token. No da **confidencialidad**: el payload está en Base64URL, que es un
alfabeto seguro para URLs, y cualquiera con el token lo lee sin clave y sin permiso.

**🗣️ 2 minutos.** Es la sobregeneralización número uno del capítulo y se desmonta en diez
segundos pegando el token en cualquier decodificador. La firma cubre `header.payload` enteros,
así que un claim tocado revienta la verificación —pero eso oculta cero—. Existe **JWE** para
cifrar el contenido y casi nadie lo usa: la protección real es TLS en tránsito más la
disciplina de no meter dentro lo que no quieres leer en claro.

**🔬 El detalle.** De ahí la regla de qué no va nunca en el payload: un número de cuenta, un
saldo, nada que no quieras ver en un log de acceso. **El JWT lleva identificadores y permisos,
no datos de negocio.** Y un token completo no se escribe jamás en un log, ni siquiera "para
depurar", porque es una credencial viva hasta su `exp`. El segundo costo de meterle cosas es
de tamaño: los claims viajan en una cabecera HTTP **en cada petición**, y un token de 8 KB
choca con el límite de cabeceras de Tomcat; el síntoma no es un 401, es un `400 Bad Request`
sin cuerpo.

---

### 21 → 5

> Enumera en orden lo que valida un resource server con `issuer-uri`, di cuál de los cinco
> pasos **no** está activado por defecto y con qué propiedad de Boot 3.5 se activa.

**⏱️ 30 segundos.** Orden: **1)** formato, **2)** firma contra la clave del `kid`, **3)**
`iss`, **4)** `exp` / `nbf` con clock skew, **5)** `aud`. El que **no** está activado por
defecto es el **5, el `aud`**, y se activa con
`spring.security.oauth2.resourceserver.jwt.audiences`.

**🗣️ 2 minutos.** La segunda sobregeneralización del capítulo es *"validar el token es
comprobar la firma"*: la firma es el paso 2 de cinco y es el único que todo el mundo recuerda.
Los pasos 3 y 4 son el validador por defecto de `JwtValidators.createDefaultWithIssuer(...)`,
que la reference de Security 6.5 describe con todas las letras: valida `exp`, `nbf` e `iss`.
El paso 5 se queda fuera, y es el que se cobra en producción: sin `aud`, un token emitido por
el mismo IdP para otro servicio entra en `inv-api` con la firma perfecta y el `iss` correcto.
Los fallos de los cinco pasos salen iguales por fuera: 401 con
`WWW-Authenticate: Bearer error_code="invalid_token", …`.

**🔬 El detalle.** Alternativa a la propiedad: un `JwtClaimValidator<List<String>>(AUD, ...)`
compuesto con el validador por defecto, que es lo que había que escribir a mano antes de que
Boot expusiera `audiences`. Y ojo con el paso 3: el `iss` se compara **como string**, así que
una barra sobrante en `issuer-uri` produce un 401 con un token impecable. Ese mismo `issuer-uri`
es el que dispara el descubrimiento OIDC en el arranque; si en su lugar fijas `jwk-set-uri`,
la llamada se aplaza pero **Boot ya no valida el `iss`**, y entonces tu lista de cinco pasos se
queda en tres y medio. Nada de esto valida autorización: un token válido de alguien sin
permisos sigue terminando en el 403 del capítulo `20`.

---

### 21 → 6

> ¿Por qué existe el clock skew de 60 segundos y qué regalas al subirlo a cinco minutos?

**⏱️ 30 segundos.** Porque el reloj del emisor y el tuyo no son el mismo, y un token recién
emitido no puede fallar por `nbf` por unos milisegundos de deriva. El valor por defecto es
`new JwtTimestampValidator(Duration.ofSeconds(60))`. Subirlo a cinco minutos **alarga cinco
minutos la vida de todo token caducado**.

**🗣️ 2 minutos.** El skew es una tolerancia sobre los dos extremos de la ventana `nbf`/`exp`,
no un ajuste fino de rendimiento. Sesenta segundos cubren la deriva normal de dos máquinas con
NTP. Cuando alguien lo sube "por si acaso" es porque está viendo 401 intermitentes, y el
diagnóstico correcto casi siempre es otro: el reloj del contenedor mal sincronizado. Ampliar
el skew tapa el síntoma y paga con seguridad, que es el peor cambio posible.

**🔬 El detalle.** El daño se compone con la estrategia de revocación: si toda tu mitigación
frente a un JWT no revocable son access tokens de cinco a quince minutos, un skew de cinco
minutos acaba de duplicar —o de multiplicar por dos tercios— la ventana de daño que tanto
te costó recortar. Y va en las dos direcciones: también acepta tokens que el IdP todavía no
considera vigentes por `nbf`. Ante 401 raros con tokens buenos, el orden de revisión es reloj
del contenedor, barra sobrante en `issuer-uri` y
`logging.level.org.springframework.security.oauth2=DEBUG`; el skew no se toca.

---

### 21 → 7

> Con HS256 y seis resource servers, ¿qué puede hacer cualquiera de los seis que no debería?

**⏱️ 30 segundos.** **Fabricar tokens que los otros cinco aceptan.** HS256 es simétrica: la
misma clave firma y verifica, así que todo el que puede verificar puede emitir. Con seis
servicios tienes el mismo secreto en seis sitios y seis emisores de facto.

**🗣️ 2 minutos.** No es un detalle criptográfico, es de operación. Con asimétrica —RS256,
ES256— la clave privada firma y solo la tiene el IdP; la pública verifica y puede repartirse
por HTTP sin ningún cuidado. Eso es lo que hace posible la federación: un servicio que nunca
habló con el IdP puede comprobar su firma bajándose el **JWK Set**, un endpoint público con
las claves de verificación en JSON, cada una con su `kid`. Con HS256 ese reparto hay que
hacerlo en secreto, a mano, a seis destinos, y rotar la clave implica coordinar seis
despliegues.

**🔬 El detalle.** El caso de compromiso lo explica mejor: si filtras la clave de un resource
server con HS256, no pierdes ese servicio —pierdes los seis, y además pierdes la capacidad de
saber qué tokens son legítimos, porque cualquiera pudo emitirlos. Con asimétrica, filtrar la
clave pública no es un incidente. Es también la razón de que `alg: none` sea un ataque clásico
y de que el paso 1 de la validación rechace algoritmos no soportados: el error literal
`"Unsupported algorithm of none"` viaja en la cabecera `WWW-Authenticate`.

---

### 21 → 8

> ¿Qué papel juega el claim `kid` en la rotación de claves, y quién recarga el JWK Set?

**⏱️ 30 segundos.** El `kid` va en el **header** del JWT y dice **con cuál de las claves del
emisor** se firmó. Quien recarga es el **decoder** de `inv-api` —el `NimbusJwtDecoder` que
monta el resource server—: si el `kid` no está en su caché, vuelve a pedir el JWK Set y
reintenta.

**🗣️ 2 minutos.** La secuencia completa es: `inv-api` lee `.../.well-known/openid-configuration`
para sacar el `jwks_uri`, baja el JWK Set y lo cachea en memoria; cuando llega un token mira
si su `kid` está en la caché, y si no, recarga. La rotación funciona sola porque el IdP publica
la clave nueva **antes** de empezar a firmar con ella, así que cuando aparece el primer token
con el `kid` nuevo la recarga lo encuentra. Nadie reinicia nada y nadie coordina despliegues:
ese es todo el valor del `kid`.

**🔬 El detalle.** La caché no es un lujo: sin ella habría una llamada HTTP al IdP **por
petición**, y el IdP pasaría a estar en el camino crítico de cada request. Con caché, verificar
es CPU pura. El reverso es que un `kid` desconocido dispara una llamada de red en caliente, así
que un IdP que rota mal —firmar con una clave que aún no publicó— produce 401 y una tormenta de
recargas. Y conviene distinguir los dos momentos de contacto con el IdP: el descubrimiento por
`issuer-uri` ocurre en el **arranque** —si el IdP no está arriba, la aplicación no arranca— y
la recarga del JWK Set ocurre **en caliente**, bajo demanda.

---

### 21 → 9

> Tu regla dice `hasRole("ANALYST")`, el token de Keycloak trae `realm_access.roles: ["analyst"]`
> y recibes 403. ¿Qué dos cosas faltan, y por qué `authorities-claim-name` no basta?

**⏱️ 30 segundos.** Faltan **leer el claim anidado** `realm_access.roles` y **prefijar
`ROLE_`**. `hasRole("ANALYST")` compara contra `ROLE_ANALYST`, y el converter por defecto no
mira `realm_access`: lee `scope` o `scp` y prefija `SCOPE_`. `authorities-claim-name` no sirve
porque **solo lee un claim de primer nivel**, y los roles de Keycloak están anidados.

**🗣️ 2 minutos.** Son dos fallos apilados y por eso cuesta: aunque consiguieras leer el claim,
seguirías con la authority `analyst` contra una regla que pide `ROLE_ANALYST` —el par exacto
del capítulo `20` §7—, y el 403 seguiría llegando vacío y sin log. La solución es un
`JwtAuthenticationConverter` declarado como `@Bean`, que Boot recoge y pasa al
`JwtAuthenticationProvider`: dentro, sacas `realm_access` con `getClaimAsMap`, recorres
`roles` y añades `new SimpleGrantedAuthority("ROLE_" + r)`. También hay que decidir si
mayúsculas o minúsculas: Keycloak trae `analyst` y la regla pide `ANALYST`, así que o
normalizas o escribes la regla como la trae el token.

**🔬 El detalle.** El error que se comete al arreglarlo es **reemplazar en vez de sumar**: si
el converter devuelve solo los roles, pierdes todos los `SCOPE_` que produce
`JwtGrantedAuthoritiesConverter` (existe desde Security 5.2) y **todas** las reglas escritas
contra ellos —`hasAuthority("SCOPE_inventory.read")`— empiezan a dar 403 sin que nada lo avise.
Por eso el converter parte de `new ArrayList<>(scopes.convert(jwt))` y añade encima. Y el
`instanceof Collection<?> roles` no es adorno: un cast ciego revienta con `ClassCastException`
si el IdP cambia el formato del claim. El prefijo tampoco está grabado en piedra —un bean
`GrantedAuthorityDefaults` lo cambia—; lo obligatorio es que coincidan lo que emites y lo que
compara la regla.

---

### 21 → 10

> "Con JWT ya no hay estado": ¿qué estado desapareció y cuál no? Explica qué pasa cuando
> despides a alguien a las 10:00.

**⏱️ 30 segundos.** Desapareció el estado **del servidor** —la sesión, la fila que se
consultaba en cada petición—. No desapareció el estado **del sistema**: se movió al token, y el
token es una foto del momento en que se emitió. Si despides a alguien a las 10:00, **su token
sigue siendo válido hasta su `exp`**: revocar deja de ser borrar una fila y pasa a ser esperar.

**🗣️ 2 minutos.** La diferencia es quién decide: con sesión, el servidor decide en cada
petición y puede cambiar de opinión; con JWT, el servidor **cree lo que dice el papel** y no
tiene dónde mirar para saber que ya no vale. Con el despido de las 10:00 pasa exactamente eso:
desactivas la cuenta en el directorio, el IdP deja de emitirle tokens nuevos —y el refresh deja
de canjearse—, pero el access token que tiene en la mano sigue entrando en `inv-api` hasta que
caduque. Con un rol retirado ocurre igual: el token sigue trayendo el rol viejo. La mitigación
estándar son **tokens cortos más refresh token**: access de cinco a quince minutos y un refresh
largo, que vive **solo en el client** y se canjea contra el IdP, donde sí hay estado y sí hay
botón de revocar. La ventana de daño pasa de ocho horas a quince minutos; no pasa a cero.

**🔬 El detalle.** Lo que la frase esconde es un intercambio, no una desaparición: cambiaste
consistencia inmediata por no tocar estado compartido en cada petición. Si necesitas
revocación inmediata de verdad, las opciones son el token opaco con introspección —el IdP
contesta en cada petición, y vuelve el estado, ahora en la red (pregunta 11)— o una lista de
denegación consultada por petición, que es exactamente reinventar la sesión con peor nombre.
Y hay un tercer estado que tampoco desaparece: el JWK Set cacheado en memoria del proceso. En
una entrevista de banca la respuesta que puntúa es la que nombra la ventana y dice cuánto dura
en tu diseño; la que dice "con JWT no hay estado" y se queda ahí es la que se falla.

---

### 21 → 11

> ¿Cuándo prefieres token opaco con introspección sobre JWT, y qué pagas por ello?

**⏱️ 30 segundos.** Cuando necesitas **revocación inmediata** —o cuando no quieres que los
claims viajen legibles por ahí—. El IdP emite una cadena sin contenido y `inv-api` la consulta
con `spring.security.oauth2.resourceserver.opaquetoken.introspection-uri`. Pagas **una llamada
de red por petición**, y con ella vuelve el estado.

**🗣️ 2 minutos.** Es el otro extremo del mismo eje que la pregunta 10: el JWT decide local con
información vieja; el opaco decide remoto con información fresca. El opaco te devuelve lo que
la sesión te daba —el servidor vuelve a decidir en cada petición— a cambio de meter al IdP en
el camino crítico: su latencia se suma a la tuya y su caída te tira. Se puede cachear la
respuesta de la introspección, pero cachear es precisamente volver a introducir una ventana de
staleness, así que estás eligiendo el tamaño de la ventana, no eliminándola.

**🔬 El detalle.** En banca el patrón habitual no es elegir uno de los dos para todo, sino
partir por perímetro: opaco de cara al exterior —donde importa poder cortar a alguien ya— y
JWT hacia dentro, donde la latencia por salto se multiplica y los servicios ya están en una
red controlada. El coste también cambia de sitio: con JWT el token gordo se paga en ancho de
banda en cada petición; con opaco el token es diminuto y lo que se paga es E/S. Y en los dos
casos la autorización sigue siendo un problema aparte: la introspección te dice si el token
está activo y qué scopes tiene, no si esa persona puede tocar este recurso.

---

### 21 → 12

> `inv-api` llama a `inv-supplier` con `client_credentials`. ¿Qué identidad viaja y qué se
> pierde por el camino?

**⏱️ 30 segundos.** Viaja la identidad **del servicio**: `inv-api` se autentica con su
`client-id` y su `client-secret` y recibe un access token **suyo**, sin `sub` de humano. Se
pierde **quién pidió la operación**: `inv-supplier` ve que llama `inv-api` y nada más.

**🗣️ 2 minutos.** `client_credentials` es el flujo de servicio a servicio sin usuario: un job
nocturno, una reconciliación de Batch. Si lo usas dentro de una petición de usuario, el rastro
se corta ahí. Las otras dos opciones son pasar el mismo token tal cual —funciona si el `aud`
incluye a los dos, es lo que hace medio mundo, y el costo es que cualquier servicio de la
cadena puede reusarlo contra cualquier otro— o intercambiarlo en el IdP por uno dirigido al
destino (*token exchange*), que conserva al usuario a cambio de un salto de red más. En banca
suele ganar el **modelo de dos capas**: el token del usuario muere en el borde y hacia dentro
viaja un token de servicio más el usuario propagado en la traza. Cuál de los tres es decisión
de arquitectura, no de framework.

**🔬 El detalle.** La pieza de Spring es el `OAuth2AuthorizedClientManager`, que pide el token,
lo guarda y lo renueva cuando caduca; el `OAuth2ClientHttpRequestInterceptor` —existe desde
Security 6.4; antes había que escribirlo a mano— solo lo pone en `Authorization`, y es un
interceptor de `RestClient` como los del capítulo `13` §5. El `registrationId` apunta a
`spring.security.oauth2.client.registration.inv-supplier`, con su
`authorization-grant-type: client_credentials`; **ese `client-secret` no va en
`application.yml`** —en el repositorio es un token de servicio regalado— sino donde dice el
capítulo `07` §8. Y la consecuencia de auditoría es la que se pregunta en banca: si el ajuste
de inventario hay que imputárselo a una persona, `client_credentials` no te sirve para
autorizar, solo para conectar.

---

### 21 → 13

> ¿Qué pregunta contesta mTLS que un JWT no contesta, y al revés?

**⏱️ 30 segundos.** mTLS contesta **"¿de qué servicio viene esta conexión?"**: autentica el
**canal**, porque cada extremo presenta su certificado. El JWT contesta **"¿qué usuario pidió
esto y con qué permisos?"**: autentica la **petición**. No se sustituyen; en banca se tienen
los dos.

**🗣️ 2 minutos.** Viven en pisos distintos. mTLS ocurre en el handshake TLS, antes de que
exista una petición HTTP, y su granularidad es la conexión: sabe que el que llama es
`inv-api`, no que dentro viaja una operación de `analyst@invlab.example`. El JWT viaja en una
cabecera de cada petición y trae `sub`, scopes y roles, pero no dice nada de por dónde llegó:
un token robado funciona desde cualquier máquina. Juntos cubren las dos preguntas: el canal
demuestra de dónde viene, el token demuestra a nombre de quién.

**🔬 El detalle.** En Spring, mTLS se configura con un **SSL bundle** de Boot, y si quieres el
certificado de cliente convertido en un `Authentication` está la autenticación **X.509** de
Security. Pero muchas veces la aplicación ni lo maneja: lo termina el balanceador o el service
mesh y la aplicación recibe tráfico ya autenticado a nivel de canal. Ahí aparece el riesgo
real: si el mTLS muere en el borde y hacia dentro no viaja token, "la red es de confianza"
vuelve a ser la política de seguridad, que es justo lo que la federación venía a eliminar.

---

## Capítulo 22 — Spring Batch

### 22 → 1

> Explica en una frase qué hace un job de Spring Batch que un bucle dentro de un
> `@Scheduled` no hace, sin usar la palabra "framework".

**⏱️ 30 segundos.** **Escribe su propio estado en una base de datos mientras trabaja**: por eso
se puede reanudar por donde iba y por eso no se repite. Un `@Scheduled` ejecuta código y nada
más; cuando muere se lleva el estado a la tumba.

**🗣️ 2 minutos.** Las tres preguntas que te hacen a las 02:41, cuando el proceso murió con
cuatrocientos mil de seiscientos mil movimientos procesados, son "¿qué quedó escrito?", "¿desde
dónde reanudo?" y "¿puedo relanzarlo igual?". El bucle del `@Scheduled` no contesta ninguna. El
job sí: quedó escrito lo que confirmó cada transacción de chunk y ni un registro más; se reanuda
desde el último commit; y no se relanza igual si ya corrió con éxito para esa fecha, porque es
la misma instancia.

**🔬 El detalle.** Ese estado no es memoria mágica: son seis tablas relacionales y `INSERT` y
`UPDATE` dentro de las mismas transacciones que tu negocio. Vale la pena decirlo en la
entrevista porque explica de un tirón el costo —cada commit de chunk paga metadatos— y las
restricciones —Boot exige una base real, aunque sea en memoria—, y descarta la idea de que
Batch sea un planificador. No lo es: no decide *cuándo* corre nada; eso sigue siendo cosa de un
scheduler o de un operador.

---

### 22 → 2

> ¿Qué distingue una `JobInstance` de una `JobExecution`, y cuál de las dos se crea cuando
> relanzas un job que falló anoche?

**⏱️ 30 segundos.** La `JobInstance` es **la corrida lógica** —la conciliación del 17 de
septiembre—; la `JobExecution` es **un intento** de esa corrida. Al relanzar lo que falló se
crea una **`JobExecution` nueva sobre la misma `JobInstance`**.

**🗣️ 2 minutos.** Esa es justamente la propiedad que hace posible el reinicio: como la
instancia es la misma, Spring Batch puede mirar qué steps quedaron en `COMPLETED` y saltarlos, y
recuperar el `ExecutionContext` del step que cayó. Si cada intento creara una instancia nueva,
no habría nada que recuperar. Debajo hay un tercer nivel, el `StepExecution`, con los contadores
de ese intento de ese step; y un detalle que se pregunta: **un `StepExecution` solo existe si el
step arrancó** — si el step 1 falló, la fila del step 2 no está vacía, no existe.

**🔬 El detalle.** La línea que divide el modelo es configuración contra datos. `Job` y `Step`
son beans que declaras una vez; `JobInstance`, `JobExecution` y `StepExecution` son filas que
Batch escribe mientras trabaja. Confundirlos es el error conceptual más caro del capítulo,
porque lleva a razonar sobre "el job" como si fuera un objeto con memoria propia. Y el
`ExecutionContext` es el cuarto elemento: un property bag persistido, uno por `JobExecution` y
otro por cada `StepExecution`, cuyo contenido tiene que ser `Serializable` o la restauración
falla. El del step se guarda **en cada commit**; el del job, entre step y step.

---

### 22 → 3

> Escribe la ecuación que define la identidad de una `JobInstance` y di qué pasa si
> lanzas el job dos veces con los mismos parámetros identificadores tras un éxito.

**⏱️ 30 segundos.** **`JobInstance` = `Job` + `JobParameters` identificadores.** Si ya terminó
con éxito para esos parámetros, el segundo lanzamiento **no vuelve a correr**: sale con
`JobInstanceAlreadyCompleteException` —o `JobExecutionAlreadyRunningException` si el primero
sigue vivo—.

**🗣️ 2 minutos.** Eso es lo que convierte "correr el job dos veces por error" en un rechazo en
vez de un doble cargo, y es la razón de elegir bien la clave: `business.date` como fecha
contable da una instancia por día, que es exactamente la unidad de negocio. Los parámetros
pueden marcarse como **no identificadores** con el tercer argumento `false`
—`addString("input.file", path, false)`—: participan en la ejecución pero no en la identidad,
como la ruta del fichero o un flag de verbosidad. Y cuidado al reintentar: los no identificadores
**no se copian** de la ejecución anterior, hay que volver a pasarlos todos.

**🔬 El detalle.** El modelo mental que conviene decir en voz alta: los `JobParameters` no son
argumentos, son **la clave primaria de la corrida**. Si no puedes nombrar cuál es la clave de tu
job, todavía no lo diseñaste. Y esa protección es local al `JobRepository`: te defiende de
lanzar dos veces la misma instancia, no de que dos procesos distintos escriban lo mismo por
otros caminos.

---

### 22 → 4

> ¿Por qué el chunk define la frontera de la transacción, y quién la abre exactamente?

**⏱️ 30 segundos.** Porque el modelo es **leer de a un ítem, acumular hasta el tamaño del chunk
y escribir el bloque entero dentro de una transacción**, repitiendo hasta que `read()` devuelve
`null`. La abre y la confirma el `PlatformTransactionManager` que le pasas a
`chunk(500, transactionManager)`.

**🗣️ 2 minutos.** El segundo argumento de `chunk` no es decorativo: es el mismo manager de `16`
§2, y por eso todo lo de aquel capítulo aplica tal cual —reglas de rollback, conexión atada al
hilo, duración de la transacción—. El primer argumento es el *commit interval*: cuántos ítems
entran en una transacción. De ahí sale la propiedad que importa a las 02:41: cada chunk es su
propia transacción, así que lo confirmado antes de la caída queda confirmado y solo se pierde el
chunk en vuelo.

**🔬 El detalle.** Dos matices del contrato de tipos. El processor es **opcional** y si devuelve
`null` el ítem **se filtra** —no se escribe, no es un error y cuenta en `filterCount`—; el
`ItemWriter` recibe **una lista**, y esa firma es justo lo que permite un `INSERT` por lote en
vez de quinientos sueltos. Y un apunte de API: en Spring Batch 5 el `JobRepository` **se pasa al
`StepBuilder`** (`new StepBuilder("reconcile-step", jobRepository)`); las `JobBuilderFactory` y
`StepBuilderFactory` de la 4.x se eliminaron en la 5.0, así que un ejemplo de 2021 ni siquiera
compila — buen filtro de entrevista.

---

### 22 → 5

> Tu equipo añade un parámetro `run.id` con la marca de tiempo para poder relanzar el job
> cuando quiera. ¿Qué capacidad acaban de perder y por qué?

**⏱️ 30 segundos.** Perdieron **el reinicio**. Con un timestamp identificador cada intento es
una `JobInstance` nueva, así que no hay nada que reanudar: siempre se empieza de cero, y los
duplicados quedan de su cuenta.

**🗣️ 2 minutos.** Es el antipatrón clásico porque *funciona*: el error molesto
—`JobInstanceAlreadyCompleteException`— desaparece, y con él la protección que lo causaba. Pero
la reanudación se apoya en que la instancia sea la misma (pregunta 2): al cambiar la clave en
cada lanzamiento, Batch no tiene con qué relacionar el intento nuevo con el caído, no salta los
steps completados y no recupera el `ExecutionContext` del step que falló. Además desaparece la
defensa contra el doble procesamiento: nada impide conciliar dos veces la misma fecha contable.

**🔬 El detalle.** Lo que casi siempre querían es otra cosa, y tiene nombre: o **reiniciar** la
instancia fallida —que es lo que Batch hace solo si no le cambias la clave—, o correr otra
instancia legítima porque la unidad de negocio es distinta, y entonces el identificador correcto
no es la hora, es el dato: la fecha contable, la sucursal, el fichero. Si de verdad hace falta
repetir un step ya completado dentro de la misma instancia, la herramienta es
`allowStartIfComplete(true)` (pregunta 11), no un parámetro inventado.

---

### 22 → 6

> Nombra las dos tablas del `JobRepository` en las que mirarías primero para contestar
> "¿por dónde iba cuando se cayó?" y "¿cuántos registros descartó?".

**⏱️ 30 segundos.** **`BATCH_STEP_EXECUTION_CONTEXT`** para "por dónde iba" —ahí vive el
property bag del step, con la posición que guardó el reader— y **`BATCH_STEP_EXECUTION`** para
los contadores: read, write, commit, rollback y skips.

**🗣️ 2 minutos.** Son dos de las seis tablas, y vale la pena poder recitarlas porque enseñan el
modelo: `BATCH_JOB_INSTANCE` (una fila por corrida lógica), `BATCH_JOB_EXECUTION` (una fila por
intento), `BATCH_JOB_EXECUTION_PARAMS` (los parámetros de ese intento, con su flag
`IDENTIFYING`), `BATCH_JOB_EXECUTION_CONTEXT` (el property bag del job),
`BATCH_STEP_EXECUTION` y `BATCH_STEP_EXECUTION_CONTEXT`. El flag `IDENTIFYING` es el que
materializa la pregunta 3: te deja ver en la base cuáles de los parámetros entraron en la
identidad de la instancia.

**🔬 El detalle.** Dos trampas de operación alrededor de estas tablas. **Hay que crearlas**:
Boot trae los scripts por motor y los ejecuta según `spring.batch.jdbc.initialize-schema`, cuyo
valor por defecto es `embedded` — se crean solas en H2 y **no se crean en tu Postgres**. En
serio van en Flyway (`15` §9) con la propiedad en `never`, y `table-prefix` cambia el prefijo
`BATCH_` si tu DBA lo exige. Y **`@EnableBatchProcessing` no se escribe en una aplicación
Boot**: esa anotación —o extender `DefaultBatchConfiguration`— desactiva la autoconfiguración,
incluida la creación del esquema. Es la trampa número uno al copiar ejemplos de la documentación
de Spring Batch a secas, que sí la lleva porque no asume Boot.

---

### 22 → 7

> Un `ItemReader` propio hace que el job, al reanudarse, duplique los primeros diez mil
> registros. ¿Qué le falta a ese reader?

**⏱️ 30 segundos.** Le falta **implementar `ItemStream`**: guardar su posición en el
`ExecutionContext` al abrirse y cerrarse. El reanudado lo hace el reader, no el framework solo;
un reader escrito como un iterador vuelve a empezar y duplica.

**🗣️ 2 minutos.** Esta es la condición que casi nadie menciona en una entrevista y la que
separa a quien leyó la documentación de quien sufrió el proceso. Cuando relanzas una instancia
cuya última ejecución falló, Batch crea un `JobExecution` nuevo sobre la misma `JobInstance`,
salta los steps en `COMPLETED` y recupera de `BATCH_STEP_EXECUTION_CONTEXT` el contexto del step
caído, que el step le entrega a su reader **al abrirlo**. Si el reader no puso nada ahí, recibe
un contexto vacío y arranca desde el primer registro. El `FlatFileItemReader` sí lo hace: guarda
cuántas líneas leyó y al reabrirse se las salta — por eso los readers de la caja funcionan y el
casero no.

**🔬 El detalle.** Y una corrección que hay que hacer siempre a esta altura: **reanudable no es
idempotente**. La granularidad del reanudado es el **chunk**, no el ítem, así que los ítems del
chunk en vuelo se vuelven a leer y a escribir: el último chunk **se repite siempre**. Batch
garantiza que no vuelve a contar lo ya confirmado, no que tu escritura sea segura de repetir.
Esa parte la pones tú: `upsert`, clave natural, o un `INSERT` que choque contra una restricción
única y sepa qué hacer.

---

### 22 → 8

> ¿Cuándo eliges `skip` y cuándo `retry`? Da un ejemplo de cada uno que no se pueda
> intercambiar.

**⏱️ 30 segundos.** **`skip` para lo determinista**: una línea mal formada
(`FlatFileParseException`) falla igual las tres veces, así que se descarta. **`retry` para lo
no determinista**: un `DeadlockLoserDataAccessException` puede resolverse esperando, así que se
reintenta.

**🗣️ 2 minutos.** El criterio es si repetir la operación puede dar un resultado distinto. Si no
puede, reintentar solo hace que el job tarde el triple en fallar por lo mismo; si sí puede,
descartar tira un dato bueno por un problema de infraestructura pasajero. Los dos viven detrás
de la misma llamada: sin **`faultTolerant()`** no existen ni `skip` ni `retry`, porque esa
llamada es la que cambia el procesador del chunk por uno que sabe reintentar y descartar. Por
defecto, cualquier excepción mata el step — con tres líneas mal formadas pierdes la ventana
entera por el 0,0005 % de los datos.

**🔬 El detalle.** Dos acompañantes que completan la respuesta. **`noSkip(...)`** excluye
excepciones de una regla ancha: `skip(Exception.class).noSkip(FileNotFoundException.class)`
—descarto todo menos que falte el fichero, que no es un dato malo sino un problema de
operación—. Y **`noRollback(...)`** es su pariente para la excepción de negocio que no debe
revertir el chunk. Por encima de la configuración está la frase que conviene dejar caer: **un
skip es una decisión de negocio, no una configuración**. Cargar proveedores mal formateados se
descarta; un movimiento de dinero, no. El `skipLimit` lo firma quien entiende el dato, no quien
escribe el step.

---

### 22 → 9

> Con `skipLimit(10)`, ¿cuál es el descarte que hace fallar el step? ¿Y qué le falta a esa
> configuración para que el descarte no sea pérdida de datos?

**⏱️ 30 segundos.** El **número once**: con límite 10 se toleran diez descartes y el
undécimo hace fallar el step. Y le falta un **`SkipListener`**, que reciba el ítem descartado y
la excepción para escribir la fila de rechazados.

**🗣️ 2 minutos.** Dos precisiones sobre el contador. Primera: los descartes se cuentan aparte
en lectura, proceso y escritura, pero **el límite es global** — no hay diez por fase, hay diez en
total. Segunda: si no lo declaras, vale **10** por defecto, así que un step `faultTolerant()`
con `skip(...)` y sin `skipLimit` ya está tolerando diez descartes silenciosos. Sin listener,
esos diez registros simplemente no están: ni en la base de destino ni en ningún sitio donde
alguien pueda reclamarlos. De ahí la frase: **un `skipLimit` sin listener es pérdida de datos
con permiso escrito**.

**🔬 El detalle.** El corolario operativo enlaza con `23`: lo que se alerta de un job no es
"falló" —eso ya se ve— sino la **duración por encima de la ventana** y el **`skipCount` distinto
de cero**. Un job que termina en `COMPLETED` descartando nueve movimientos cada noche es
exactamente el fallo que nadie ve hasta la reconciliación del mes. Las métricas de Micrometer
están ahí: `spring.batch.job`, `.job.active`, `.step`, `.item.read`, `.item.process` y
`.chunk.write`.

---

### 22 → 10

> El `ItemWriter` falla en el ítem 237 de un chunk de 500. Describe qué queda escrito en
> la base, qué pasa con los chunks anteriores y en qué cambia la respuesta si el step es
> `faultTolerant()`.

**⏱️ 30 segundos.** Sin `faultTolerant()`: el `write(List)` lanza, la transacción del chunk hace
**rollback** —no queda nada de esos 500— y el step termina en `FAILED`. Los **chunks anteriores
quedan confirmados**, porque cada uno fue su propia transacción: se pierde el chunk en vuelo, no
el trabajo hecho.

**🗣️ 2 minutos.** Con `faultTolerant()` y skip en escritura la película sigue: el chunk se
revierte igual, y entonces Batch lo **reprocesa aislando los ítems** para dar con el culpable.
El malo se descarta —y suma al contador de la pregunta 9— y el resto se escribe, en
transacciones mucho más pequeñas. El precio es doble: ese chunk **cuesta un orden de magnitud
más**, y tu writer ve **el mismo ítem más de una vez**, así que tiene que tolerarlo. Es la misma
exigencia de idempotencia de la pregunta 7, por otra puerta.

**🔬 El detalle.** El rollback obedece a las reglas de `16` §6, no a una regla propia de Batch:
una excepción chequeada capturada dentro del writer no revierte nada y te deja un chunk a
medias contado como bueno. Y el corolario de diseño es el de `16` §8: **nada lento dentro del
chunk** — una llamada HTTP por ítem en el writer multiplica la duración de la transacción por el
tamaño del chunk y retiene una conexión del pool todo ese tiempo ⏱️.

---

### 22 → 11

> ¿Qué hace `allowStartIfComplete(true)` y en qué tipo de step **no** lo pondrías nunca?

**⏱️ 30 segundos.** Fuerza a un step a **correr otra vez aunque haya quedado `COMPLETED`** en un
reinicio de la misma instancia; por defecto es `false`. No lo pones nunca en el step que mueve
dinero: lo repetiría entero en cada reintento.

**🗣️ 2 minutos.** Su lugar natural son los steps idempotentes de preparación: validar el
fichero, limpiar una tabla temporal, mover el fichero de entrada. Esos quieres que corran de
nuevo en cada intento, porque el trabajo que hicieron puede haber quedado obsoleto. Un step de
escritura contable es lo contrario: la razón de ser del reinicio es **no** repetir lo confirmado.
Su pareja es **`startLimit(n)`**, que limita cuántas veces puede arrancar un step dentro de la
instancia —por defecto `Integer.MAX_VALUE`— y lanza `StartLimitExceededException` al pasarse;
sirve para que un step que falla siempre no se reintente eternamente en la ventana nocturna.

**🔬 El detalle.** Conviene distinguirlo de lo que hace Batch solo: en un reinicio, los steps en
`COMPLETED` se saltan **sin** que configures nada, y el step caído se reanuda desde su
`ExecutionContext`. `allowStartIfComplete` no "reinicia el job desde cero": solo cambia esa
decisión de saltar, step por step. Quien lo usa para arreglar "no me deja volver a correrlo"
suele estar en realidad ante el problema de la pregunta 3 —la instancia ya completada— y
necesita otra clave de identidad, no este flag.

---

### 22 → 12

> De las cuatro formas de paralelizar un job, ¿cuál conserva intacta la semántica de
> reinicio, y por qué?

**⏱️ 30 segundos.** El **partitioning**. Porque cada partición corre como **su propio
`StepExecution`, con su fila y su `ExecutionContext`**: si falla la partición 7, reanudas la
partición 7.

**🗣️ 2 minutos.** Las otras tres pagan otra cosa. El **multithreaded step** —dar un
`TaskExecutor` al `StepBuilder`— es lo más barato de escribir y lo más fácil de romper: exige
readers y writers thread-safe, y el reanudado deja de ser fiable porque varios hilos escriben la
misma posición en un solo `ExecutionContext`. Los **parallel steps** (`split`) paralelizan
flujos distintos y solo sirven si son de verdad independientes. El **remote chunking** manda el
proceso de los ítems a otras JVM y trae consigo infraestructura de mensajería. El partitioning
es la que se usa en banca porque el dominio se deja partir: por rango de cuenta, por sucursal,
por fichero.

**🔬 El detalle.** El veredicto que conviene dar antes de que lo pidan: **primero mide en un
solo hilo**. Y cuida el pool — ocho hilos contra un Hikari de diez dejan sin conexiones al resto
de la aplicación ⏱️, así que el pool del job se dimensiona aparte o el job corre en su propio
proceso. Es el mismo razonamiento de recursos escasos de `15` §2, solo que aquí el consumidor es
tu propio proceso nocturno compitiendo contra el tráfico de la mañana.

---

### 22 → 13

> Arrancas tu API en producción y descubres que el job de conciliación corrió solo al
> levantar el servicio. ¿Quién lo lanzó y qué propiedad lo apaga?

**⏱️ 30 segundos.** Lo lanzó el **`JobLauncherApplicationRunner`**: en una aplicación Boot, si
hay un solo bean `Job` en el contexto se ejecuta al arrancar. Se apaga con
**`spring.batch.job.enabled=false`**, que vale `true` por defecto.

**🗣️ 2 minutos.** Ese comportamiento es perfecto para el caso al que apunta —un contenedor que
arranca, corre el lote y muere— y es una mala sorpresa en un servicio que además atiende
tráfico: cada despliegue, cada reinicio de un pod y cada escalado lanzan el job. Con
`enabled=false` el job queda declarado pero inerte, y se dispara desde donde corresponda: un
endpoint, un scheduler o un operador. Si hay más de un `Job` en el contexto, **`spring.batch.job.name`**
pasa a ser obligatoria para decir cuál se lanza.

**🔬 El detalle.** El error hermano, que cuesta una ventana y se diagnostica en un minuto: **los
parámetros del job se pasan por línea de comandos sin `--`** — `java -jar app.jar
business.date=2026-09-17`. Lo que lleva `--` es una propiedad del `Environment` y el job no la
ve, así que el lote corre con los parámetros equivocados, o crea una instancia que no es la que
querías. Y para probarlo sin nada de esto está `JobLauncherTestUtils`, que lanza el job —o un
step suelto— y devuelve el `JobExecution` para afirmar sobre su estado y sus contadores.

---

### 22 → 14

> Tres réplicas del servicio tienen el mismo `@Scheduled` que lanza el mismo job. ¿Qué
> pasa con la segunda y la tercera, y por qué esto no equivale a un scheduler
> distribuido?

**⏱️ 30 segundos.** Las tres intentan lanzarlo; la primera corre y las otras dos **son
rechazadas** con `JobExecutionAlreadyRunningException` —o `JobInstanceAlreadyCompleteException`
si la primera ya terminó—. No es un scheduler distribuido porque te protege de la duplicación,
**no te dice quién debía correr**.

**🗣️ 2 minutos.** Es el problema de `18` §7 —tres réplicas son tres relojes y tres intentos—
con una diferencia importante a favor: aquí el segundo intento no duplica el trabajo, lo
rechaza, porque la identidad de la `JobInstance` actúa como un cerrojo en la base de datos. Pero
esa protección solo cubre la ejecución del job. No hay elección de líder, no hay reparto, y si
la réplica que ganó se muere a mitad, ninguna de las otras dos se entera ni toma el relevo: la
reanudación la tendrá que disparar alguien. Tampoco cubre el resto de lo que haga ese
`@Scheduled` alrededor del lanzamiento.

**🔬 El detalle.** El matiz que conviene dejar dicho: el rechazo es una **excepción**, no un
"no-op" silencioso. Si tu `@Scheduled` no la captura, cada noche tendrás dos stack traces en el
log de dos réplicas sanas, y el ruido acaba enseñando al equipo a ignorar los errores de ese
job. Lo correcto es capturarla y registrarla en `INFO` como lo que es —otra réplica se
encargó—, y dejar la alerta para lo que sí es anómalo (pregunta 9).

---

### 22 → 15

> Alguien defiende `chunk(1)` "para no perder nada si falla". Dale la versión precisa:
> qué gana, qué paga y con qué argumento se elige un tamaño.

**⏱️ 30 segundos.** Gana la **máxima granularidad**: al fallar solo se repite un ítem. Paga el
**máximo costo**: una transacción por ítem, y con ella varios `UPDATE` de metadatos del
`JobRepository` por ítem. El tamaño se elige por **cuánto trabajo estás dispuesto a repetir**.

**🗣️ 2 minutos.** La cuenta hace visible el disparate: con `chunk(1)` y un millón de ítems son
un millón de transacciones **y un millón de `UPDATE` de `BATCH_STEP_EXECUTION`**, con lo que la
contabilidad pasa a costar más que el trabajo. En el otro extremo, `chunk(100000)` es una
transacción enorme que al fallar te devuelve casi al inicio, retiene la conexión y la lista del
writer en memoria todo ese tiempo. El tamaño es una perilla entre esos dos males: entre 100 y
1 000 con JDBC, midiendo. "1000 porque sí" no es argumento; "porque el rollback máximo son
1 000 movimientos", sí.

**🔬 El detalle.** El segundo eje es la memoria, no solo el tiempo: el `ItemWriter` recibe la
lista entera del chunk, y con JPA cada chunk hace `flush` y limpia el persistence context, así
que un chunk gigante es memoria retenida además de una transacción larga. Y la elección del
reader entra en la misma conversación: un `JdbcCursorItemReader` mantiene abiertos un
`ResultSet` y una conexión del pool de `15` §2 del primer ítem al último ⏱️, mientras que el
paginado la suelta entre páginas a cambio de exigir un orden estable.

---

## Capítulo 23 — Actuator y observabilidad

### 23 → 1

> Con Actuator en el classpath y sin configurar nada, ¿qué se expone y qué devuelve `/actuator/env`?

**⏱️ 30 segundos.** Se expone **solo `health`**, sobre HTTP y sobre JMX. El resto de los
endpoints existe y está habilitado, pero no publicado, así que `/actuator/env` responde
**`404`, no `403`**: no es una negativa de seguridad, es que esa ruta no está mapeada.

**🗣️ 2 minutos.** Esa diferencia entre `404` y `403` es diagnóstico puro: `404` significa "no
lo expusiste", `403` significa "lo expusiste y alguien te está protegiendo". Y ahí está el
matiz que más se dice mal: **Actuator no autentica nada**. Sin Spring Security en el
classpath, todo lo que añadas a `management.endpoints.web.exposure.include` queda abierto a
quien alcance el puerto. La lista se abre por IDs o con `*`, **`exclude` tiene prioridad sobre
`include`** —de ahí la receta `include=*` + `exclude=env,beans`— y el prefijo `/actuator` sale
de `management.endpoints.web.base-path`.

**🔬 El detalle.** El interruptor fuerte para un entorno regulado es
`management.endpoints.access.default=none`, que apaga todos los endpoints y obliga a reabrirlos
uno a uno con `management.endpoint.<id>.access`. Desde Boot 3.4, `management.endpoint.<id>.enabled`
y `enabled-by-default` están deprecadas a favor de `access`, con los valores `none`, `read-only`
y `unrestricted`. Y la defensa completa tiene tres capas, no una: exponer poco, ligar el conector
de management a la red interna, y exigir un rol con una `SecurityFilterChain` sobre
`EndpointRequest.toAnyEndpoint()` dejando fuera como mucho `readiness`.

---

### 23 → 2

> ¿Qué gana exactamente `management.server.port=8081` que no gane exponer menos endpoints?

**⏱️ 30 segundos.** Gana un **conector propio con su propio pool de hilos**. Exponer menos
reduce la superficie, pero el `health` sigue compitiendo por los mismos 200 hilos del negocio:
si un proveedor lento los agota, el health deja de responder y el balanceador mata una
instancia que solo estaba saturada. Con puerto propio, el diagnóstico sobrevive a la
saturación del `8080`.

**🗣️ 2 minutos.** Son dos ejes distintos y se suelen confundir: la exposición decide **qué**
se publica, el puerto decide **por dónde** y **con qué hilos**. El segundo trae además
`management.server.address=127.0.0.1`, que liga el conector al loopback: solo lo alcanzan el
sidecar de scrape o el kubelet, y no sale del pod. En banca es casi obligatorio, porque el
puerto de negocio cruza el firewall y el de management no. El costo es medible y pequeño: un
pool de hilos —diez sobran— y unos pocos MB.

**🔬 El detalle.** Con puerto propio cambia quién manda en la ruta: **`management.server.base-path`
solo aplica cuando hay puerto de management**, y sin él quien manda es
`management.endpoints.web.base-path`. Confundirlos produce un `404` que parece un problema de
exposición y es de prefijo, y se pierde media hora revisando la lista de `include`. Es la misma
razón por la que el scrape de Prometheus tiene que escribir `metrics_path: /actuator/prometheus`
contra el `8081`: su default es `/metrics` y el puerto no es el del negocio.

---

### 23 → 3

> Distingue `liveness` de `readiness`: ¿qué hace el orquestador con cada uno y qué no va nunca en
> el primero?

**⏱️ 30 segundos.** `readiness` en `DOWN` **saca la instancia del balanceador** y la devuelve
sola cuando la dependencia se recupera. `liveness` en `DOWN` **provoca un reinicio**. Por eso
en `liveness` **no va nunca una dependencia externa**: con Postgres caído, el orquestador
reinicia todas tus réplicas y convierte la caída de otro en una caída tuya.

**🗣️ 2 minutos.** Se publican con `management.endpoint.health.probes.enabled=true` y se
consultan por separado, en `/actuator/health/readiness` y `/actuator/health/liveness`. En el
curso el grupo de readiness incluye `readinessState,db,supplier` —las externas van aquí— y el
de liveness solo `livenessState`. Lo único que mira el balanceador es el código: `DOWN` y
`OUT_OF_SERVICE` se traducen a **HTTP 503**, y el cuerpo del JSON le da igual.

**🔬 El detalle.** Un `HealthIndicator` **corre en el hilo que atiende la petición al
endpoint**, no en un scheduler: si tu `SupplierHealthIndicator` llama a un proveedor sin
`read-timeout`, el proveedor colgado cuelga el health check. Un readiness que no contesta es,
para el balanceador, lo mismo que uno que contesta `DOWN`, así que ese timeout es parte del
diseño de la probe y no un detalle del cliente. Y si se protege Actuator con una
`SecurityFilterChain`, el endpoint que se deja fuera es como mucho `readiness`, porque quien
lo consulta —el kubelet— no lleva credenciales.

---

### 23 → 4

> ¿Qué vale `show-details` por defecto, y qué implica para un `HealthIndicator` que adjunta el
> mensaje de la excepción?

**⏱️ 30 segundos.** Vale **`never`**: la respuesta por defecto es `{"status":"UP"}` y nada más.
Eso implica que un indicator que adjunta el mensaje de la excepción **hoy no filtra nada y está
a una propiedad de filtrarlo todo**: el día que alguien ponga `always` para depurar un
incidente, ese mensaje —con hosts internos, rutas o fragmentos de SQL— sale por un endpoint sin
autenticación.

**🗣️ 2 minutos.** Los valores son `never`, `when-authorized` —el detalle sale solo para
autenticados, que exige Spring Security— y `always`. El detalle **se calcula igual**, solo no
se renderiza, así que confiar en el default es confiar en que nadie cambie una línea de YAML
en una noche mala. Por eso el indicator del capítulo publica el **tipo** de la excepción,
`ex.getClass().getSimpleName()`, y no su mensaje: `withDetail` es un canal de publicación, no
un log.

**🔬 El detalle.** El informe se arma por nombre de bean: Boot recorta el sufijo
`HealthIndicator`, así que `SupplierHealthIndicator` aparece como `supplier` y esa es la clave
que se usa en los grupos. Y conviene tenerlo presente al elegir qué se adjunta: los detalles de
los indicators autoconfigurados —`db`, `diskSpace`, `redis`— también salen con `always`, y ahí
va información de infraestructura que en banca no se publica sin control.

---

### 23 → 5

> "`health` verde significa que funciona": corrige la afirmación con precisión.

**⏱️ 30 segundos.** `health` verde significa que **los `HealthIndicator` registrados
contestaron `UP`** en el instante en que preguntaste. No dice nada de latencia ni de errores:
un servicio que devuelve el fallback de un circuit breaker abierto sigue `UP`, y uno con el p99
diez veces peor que ayer también.

**🗣️ 2 minutos.** Son dos preguntas distintas con dos instrumentos distintos: *"¿está sano?"*
la contesta `health` —¿acepto tráfico, hablo con mis dependencias?— y *"¿por qué está lento?"*
la contestan las métricas y las trazas. El health es binario y puntual; la degradación es
gradual y solo se ve en series de tiempo: p95 y p99 de `http_server_requests_seconds` por
`uri`, la proporción de `outcome="SERVER_ERROR"` y la saturación de
`hikaricp_connections_pending`. A las once de la noche, "el pod está verde" y "a mí me
responde" son opiniones; "el p99 de la última hora es diez veces el de ayer" es lo único con
lo que se decide un rollback.

**🔬 El detalle.** El error simétrico también existe y es caro: meter todas las dependencias
externas en el health raíz convierte cualquier caída ajena en un `503` tuyo, y si además están
en `liveness`, en un reinicio en cascada. La regla práctica es que en el health van las
dependencias sin las cuales **no puedes atender tráfico**, y que todo lo demás —el proveedor
que tiene fallback, la caché que puedes saltarte— se vigila con métricas y alertas, no con un
indicator.

---

### 23 → 6

> Cambias un nivel con `POST /actuator/loggers/...` con seis réplicas: ¿qué pasa con las otras
> cinco y tras el siguiente despliegue?

**⏱️ 30 segundos.** Las otras cinco **no se enteran**: el cambio vive en memoria y afecta solo
a la instancia que atendió el `POST`. Y muere con el proceso, así que tras el siguiente
despliegue —o tras cualquier reinicio— todo vuelve al nivel configurado en el fichero.

**🗣️ 2 minutos.** La consecuencia práctica es que con seis réplicas detrás de un balanceador, o
repites la llamada seis veces o el log que buscas está en la que no tocaste, y concluyes que
"el `DEBUG` no funcionó". Detalles del comando que se cobran en el momento: es una escritura,
así que va `-X POST`; sin `-H 'Content-Type: application/json'` recibes `415`; el cuerpo
`{"configuredLevel":"DEBUG"}` aplica el nivel a ese logger y a sus hijos, y
`{"configuredLevel":null}` lo devuelve al heredado. Con la seguridad por defecto, `loggers` y
`shutdown` responden `403` al `POST`.

**🔬 El detalle.** Que el cambio sea volátil es una ventaja, no una limitación: es justo lo que
hace que el truco sea seguro —un reinicio deshace cualquier exceso— y es la razón de usarlo en
vez de reiniciar con otra configuración, que destruiría el estado que querías observar. El
costo sí es real: `DEBUG` en `org.hibernate.SQL` o en el paquete raíz multiplica el volumen de
log por órdenes de magnitud, y con él la E/S y la factura de ingesta. Se sube sobre el paquete
más estrecho que sirva y se baja en cuanto capturas lo que buscabas.

---

### 23 → 7

> Nombra los cuatro medidores de Micrometer: ¿cuál usarías para el tamaño de un lote, y por qué
> no un `Timer`?

**⏱️ 30 segundos.** `Counter` —algo que solo sube—, `Gauge` —valor instantáneo que fluctúa—,
`Timer` —duración y frecuencia— y `DistributionSummary` —una distribución que no es tiempo—.
Para el tamaño de un lote, **`DistributionSummary`**: es exactamente "distribución de algo que
no se mide en segundos". Un `Timer` publica en unidades de tiempo, así que un lote de 300
elementos acabaría en el backend como 300 segundos.

**🗣️ 2 minutos.** El reparto típico: items rechazados por stock es un `Counter`; el tamaño de
una cola en memoria, un `Gauge`; la latencia del recálculo de precios, un `Timer`; el tamaño
del lote recibido, un `DistributionSummary`. Y casi todo viene ya instrumentado por Boot —HTTP
con `http.server.requests`, JVM con `jvm.memory.used` y `jvm.gc.pause`, Hikari con
`hikaricp.connections.pending`, Logback, cachés y Resilience4j—, así que **a mano se instrumenta
el dominio, no la plomería**.

**🔬 El detalle.** Los dos errores de elección más caros: usar un `Gauge` donde va un `Counter`
—el `Gauge` se lee cuando Prometheus hace scrape, y con `scrape_interval: 15s` los picos entre
muestras no existen para nadie, mientras que el `Counter` acumula y no pierde eventos—, y
tratar un valor que baja como `Counter`, que rompe la semántica con la que el backend calcula
tasas. En cuanto a nombres, van en minúsculas y con puntos (`inventory.items.rejected`) y es
el exportador quien traduce a cada backend —en Prometheus, `inventory_items_rejected_total`—;
escribirlos ya con guiones bajos rompe el nombre en todos los demás.

---

### 23 → 8

> ¿Por qué un histograma de buckets y no percentiles calculados en la JVM, con seis instancias
> detrás de un balanceador?

**⏱️ 30 segundos.** Porque **los percentiles no se agregan**: la media de dos p99 no es el p99
de nada, y con seis réplicas lo que quieres saber es el p99 del servicio, no el del pod 3. Con
`publishPercentileHistogram()` cada instancia publica **buckets acumulativos** y el percentil se
calcula **al agregar**, sobre la suma de las seis.

**🗣️ 2 minutos.** Un percentil precalculado en la JVM es un número ya resumido: perdiste la
distribución que haría falta para recomponerlo. Los buckets, en cambio, son contadores por
umbral, y sumar contadores sí es correcto. El precio hay que decirlo, porque enlaza con el
problema de cardinalidad: **cada bucket es una serie**, así que un histograma no es gratis y
por eso se pone en los medidores que van a estar en un tablero o en una alerta, no en todos.

**🔬 El detalle.** Por qué percentiles y no media: con p50 de 40 ms y p99 de 9 s, la media dice
90 ms y suena bien, mientras el p99 dice que uno de cada cien clientes espera nueve segundos.
Y los percentiles por instancia no son inútiles, solo son otra pregunta: sirven para detectar
que **una** réplica está enferma. Lo que no se puede hacer es promediarlos y llamar a eso el
percentil del servicio.

---

### 23 → 9

> Explica qué le pasa a Prometheus si etiquetas una métrica con `sku`, y por qué el daño no se
> limita a esa métrica.

**⏱️ 30 segundos.** Cada combinación distinta de valores de tags es **una serie de tiempo
nueva**. Con 50 000 SKU, una métrica que tenía 3 series pasa a tener **150 000**; si además
etiquetas por cliente, la combinatoria se va a miles de millones. Prometheus crece hasta que el
kernel lo mata, y entonces te quedas sin **todas** las métricas, no solo sin la mal etiquetada:
el backend es compartido.

**🗣️ 2 minutos.** La regla es corta: **un identificador único nunca es un tag**. `sku`,
`customerId`, `traceId` o el mensaje de una excepción van a un log o a una traza, que están
hechos para cardinalidad alta; las métricas están hechas para dimensiones de conjunto cerrado y
pequeño, como `reason` o `outcome`. La trampa clásica es la URI: `http.server.requests` etiqueta
con la **plantilla** (`/api/items/{sku}`) cuando la métrica sale del handler de MVC, pero
medirla a mano en un filtro te da una serie por SKU.

**🔬 El detalle.** Hay un fusible y conviene saber qué hace y qué no:
`management.metrics.web.server.max-uri-tags` vale **100** y **descarta** las series nuevas al
pasarse —avisa, no arregla, y desde ese momento tus tableros están incompletos sin decirlo—. El
control fino es un bean `MeterFilter`: `maximumAllowableTags(...)` acota una dimensión y
`deny(...)` apaga una métrica entera, y se aplica sobre el registro. Y el corolario del
capítulo: una métrica que nadie mira cuesta memoria en el proceso, cardinalidad en el backend y
ruido en el tablero.

---

### 23 → 10

> Pusiste `@Timed` sobre un método y la métrica no aparece: enumera las causas en el orden en que
> las revisarías.

**⏱️ 30 segundos.** Primero, **`management.observations.annotations.enabled` vale `false` por
defecto**: sin esa propiedad no se registran `TimedAspect` ni `CountedAspect` y la anotación se
ignora en silencio. Segundo, **falta AspectJ** (`spring-boot-starter-aop`): el aspecto se
condiciona a `org.aspectj.weaver.Advice`. Tercero, **self-invocation**: es un proxy, y una
llamada desde otro método de la misma clase no mide nada. Cuarto, que la métrica exista pero no
la estés viendo, porque `metrics` no está en la lista de expuestos y el endpoint responde `404`.

**🗣️ 2 minutos.** El orden no es caprichoso: va de lo que no deja ningún rastro a lo que sí.
Las dos primeras causas son de infraestructura ausente y se comprueban en el `application.yml`
y en el `pom.xml` sin arrancar nada; la tercera se comprueba llamando al método **desde otro
bean**; la cuarta con un `curl` al endpoint. Lo que las tres primeras tienen en común es el
síntoma: ni error, ni log, ni métrica — exactamente el mismo fallo silencioso de `@Transactional`
y `@Cacheable`, con otra anotación encima.

**🔬 El detalle.** La conclusión de diseño es que una anotación **depende de infraestructura que
alguien tiene que encender**, y que esa dependencia es invisible en el sitio donde escribes la
anotación. Para una métrica de la que dependa una alerta, el `Timer` explícito construido
contra el `MeterRegistry` es preferible: no puede quedar apagado por una propiedad, y de paso
te deja poner `publishPercentileHistogram()` y los tags que quieras. `@Timed` es cómodo para
instrumentar de forma masiva, no para lo que tiene que estar sí o sí.

---

### 23 → 11

> Tu tasa de 5xx bajó mientras el servicio devuelve fallbacks: ¿por qué, y sobre qué métrica
> escribes la alerta?

**⏱️ 30 segundos.** Porque el fallback **responde `200`**: mientras el circuito está abierto, el
fallo del proveedor deja de cruzar tu borde, así que la proporción de `outcome="SERVER_ERROR"`
baja y el tablero de errores mejora justo cuando el sistema está peor. La alerta va sobre el
**cambio de estado del circuito**: `resilience4j_circuitbreaker_state{state="open"}`.

**🗣️ 2 minutos.** Es el punto ciego estructural de las cuatro señales doradas: miden lo que el
usuario ve, y un fallback está diseñado precisamente para que el usuario no vea el fallo. La
latencia tampoco te avisa —el fallback es rápido, así que el p99 incluso mejora— y `health`
sigue `UP`, porque el servicio está atendiendo. Por eso el capítulo dice que **el circuito
abierto se alerta, no se grafica**: un gráfico con el estado del breaker es algo que alguien
tendría que estar mirando, y nadie lo mira a las tres de la mañana.

**🔬 El detalle.** La alerta sobre el estado es el mínimo; lo completo es medir también el
**volumen de respuestas degradadas**, porque un fallback honesto marca su respuesta —el campo
`stale` del lab `L05`— y ese marcado se puede contar con un `Counter`. Así distingues "el
circuito abrió treinta segundos" de "llevamos dos horas sirviendo precios viejos", que son
incidentes de gravedad distinta y en banca de conversación distinta. Un circuito que abre sin
que nadie se entere es peor que no tenerlo: enmascara la caída ajena detrás de respuestas
degradadas tuyas hasta que aparece en una conciliación.

---

### 23 → 12

> ¿Qué lleva dentro la cabecera `traceparent` y quién decide si la traza se muestrea?

**⏱️ 30 segundos.** Lleva cuatro campos separados por guiones: versión, **`traceId` de 32
hexadecimales** —la petición completa, el mismo en los tres servicios—, **`spanId` de 16
hexadecimales** —el tramo concreto— y el flag de muestreo, el `01` de
`00-<traceId>-<spanId>-01`. **La decisión se toma en la raíz** de la traza y viaja en ese flag:
se muestrea la petición entera o ninguna parte de ella.

**🗣️ 2 minutos.** Que la decisión sea de la raíz es lo que evita trazas a medias, con el
controller pero sin la llamada al proveedor. La probabilidad la fija
`management.tracing.sampling.probability`, que **vale `0.1` por defecto** y casi nunca se sube a
`1.0`: cada traza exportada son bytes de red y almacenamiento **por span**, y una petición que
cruza tres servicios genera varios. Un span típico es el controller, la llamada a
`inv-supplier` o la query.

**🔬 El detalle.** `traceparent` es el formato **W3C**, que es la propagación por defecto de
Micrometer Tracing y el formato interoperable; B3 es el de Zipkin y se elige con
`management.tracing.propagation.type`. Micrometer Tracing es solo la fachada: el bridge elige
implementación —`micrometer-tracing-bridge-otel` o `...-brave`— y el exportador es **otra
dependencia aparte**, porque generar trazas y enviarlas son decisiones distintas. En Boot 4,
`management.tracing.enabled` pasa a llamarse `management.tracing.export.enabled` justo para
separar esas dos cosas.

---

### 23 → 13

> Una traza aparece cortada en tu borde, con los spans del llamador pero ninguno de
> `inv-supplier`: ¿cuál es la causa más probable en un cliente HTTP de Spring?

**⏱️ 30 segundos.** Que el cliente **no se construyó desde el builder autoconfigurado**. Un
`RestClient.create()` suelto no lleva el interceptor de trazas, así que la petición sale sin
`traceparent`: `inv-supplier` no recibe contexto, abre una traza nueva con otro `traceId` y la
tuya termina en tu borde. El arreglo es inyectar `RestClient.Builder` —o el builder
equivalente— en vez de crear el cliente a mano.

**🗣️ 2 minutos.** Es el mismo fallo que ya te costó los timeouts en `13`: un cliente crudo se
salta la configuración global y las personalizaciones del contexto, y lo hace en silencio. El
síntoma es característico: los spans de `inv-supplier` **existen**, solo que colgando de otro
`traceId`, así que no es que el otro servicio no esté instrumentado, es que no supo que la
petición ya tenía identidad.

**🔬 El detalle.** Las otras causas, en orden de descarte. El muestreo no es: si la traza no se
hubiera muestreado, tampoco verías los spans del llamador. Sí pueden serlo un **salto de hilo
sin propagación de contexto** —el contexto de observación vive pegado al hilo, igual que el MDC,
y si saltas a otro pool sin decorarlo se pierde—, que el otro servicio no tenga bridge o
exportador, y que los dos lados hablen formatos distintos, tú W3C y él B3. El indicio gemelo en
los logs es una línea sin `traceId` donde `logging.pattern.correlation` imprime el valor por
defecto de `%X{traceId:-}`.

---

## Capítulo 24 — Testing

### 24 → 1

> ¿Por qué la inyección por constructor permite un test unitario sin contenedor, y qué pasa si la
> clase inyecta por campo?

**⏱️ 30 segundos.** Porque si la dependencia entra por el constructor puedes escribir
`new InventoryService(repository)` y pasarle un `@Mock` de Mockito: el objeto queda completo sin
que haya un `ApplicationContext` de por medio. Con inyección por campo el constructor no recibe
nada, el objeto nace con los campos en `null` y necesitas reflexión o el contenedor para
rellenarlos — y ahí es donde la suite se va a los minutos.

**🗣️ 2 minutos.** Es la razón práctica por la que [`03`](03-inyeccion-de-dependencias.md) insiste
en el constructor, y la que hace que el capítulo de testing empiece ahí. El test unitario es el
único nivel de la pirámide que arranca en ~0 ms, y solo existe si tus clases se pueden construir
con `new`. `@ExtendWith(MockitoExtension.class)` inicializa los `@Mock` y aplica *strict stubs*,
que fallan con `UnnecessaryStubbingException` cuando dejas un `when(...)` que nadie usa: una red
contra tests que pasan probando otra cosa.

**🔬 El detalle.** El costo de la inyección por campo no es solo arrancar Spring: es que para
probar una clase tienes que levantar un contexto, y cada contexto distinto se paga en la caché de
§6. Además la inyección por constructor deja los campos `final` y hace visible el número de
dependencias —cinco parámetros incomodan, cinco `@Autowired` no—, que es la señal de diseño que
la inyección por campo anestesia. Y lo que ningún test unitario prueba, se inyecte como se
inyecte: proxies, transacciones, serialización, rutas y seguridad, que es justo donde viven estos
bugs.

---

### 24 → 2

> Diferencia `@Mock` de `@MockitoBean`: ¿quién recibe cada uno el objeto simulado?

**⏱️ 30 segundos.** `@Mock` es de Mockito y **te entrega a ti** el objeto simulado, para que se
lo pases al constructor. `@MockitoBean` es de Spring y **sustituye un bean dentro del contexto**:
quien recibe el mock es el contenedor, y por tanto todos los beans que dependían del original.

**🗣️ 2 minutos.** La distinción marca la frontera entre los dos mundos del capítulo. Con `@Mock`
no hay contenedor: `@ExtendWith(MockitoExtension.class)` crea el simulado y tú decides dónde va.
Con `@MockitoBean` hay contexto, el bean lo crea el contenedor y no puedes pasar nada por
constructor, así que registras un *bean override* que reemplaza la definición. Por eso
`@MockitoBean` es obligatorio en un `@WebMvcTest`: el slice no escanea servicios y sin él el
arranque falla.

**🔬 El detalle.** `@MockitoBean` no es gratis y `@Mock` sí. Los bean overrides entran en la clave
de la caché de contextos (§6): añadir un `@MockitoBean` en una clase y no en otra ya son dos
contextos y dos arranques, así que declararlos «por si acaso» se paga en minutos de suite. Su
pariente es `@MockitoSpyBean`, que no sustituye sino que **envuelve el bean real**: el código
verdadero corre y tú verificas. Ambos se resetean entre métodos de test.

---

### 24 → 3

> ¿Qué anotaciones sustituyen a `@MockBean` y `@SpyBean`, desde qué versión y en qué proyecto?

**⏱️ 30 segundos.** Las sustituyen **`@MockitoBean` y `@MockitoSpyBean`**, y el dato fino es el
cambio de proyecto: las viejas eran de **Spring Boot** y las nuevas son de **Spring Framework**,
en `org.springframework.test.context.bean.override.mockito`, cuyo javadoc dice `Since: 6.2`. El
javadoc de Boot 3.5.16 declara `@MockBean` y `@SpyBean` literalmente
`@Deprecated(since = "3.4.0", forRemoval = true)`.

**🗣️ 2 minutos.** No fue un renombrado: Framework 6.2 introdujo un mecanismo genérico de *bean
overriding* —del que también sale `@TestBean`— y las anotaciones de Mockito pasaron a ser un caso
particular de ese mecanismo. Por eso bajaron de Boot a Framework: ya no son una utilidad de Boot,
son parte del `TestContext` framework. La correspondencia de versiones es Framework 6.2 con Boot
3.4, y por eso las deprecadas llevan `since = "3.4.0"`.

**🔬 El detalle.** En 4.x ya no existen: el paquete `org.springframework.boot.test.mock.mockito`
desapareció, así que una migración no puede dejarlas «para después». Y en la misma línea de
reorganización, los slices cambiaron de paquete —`@WebMvcTest` vive hoy en
`org.springframework.boot.webmvc.test.autoconfigure`—, lo que convierte el salto a 4.x en un
`organize imports` masivo más que en un cambio de código. El curso fija Boot 3.5.16, donde las
dos formas compilan y solo una no avisa.

---

### 24 → 4

> Nombra los cuatro `webEnvironment` y di cuál usarías para probar un job de Batch.

**⏱️ 30 segundos.** `MOCK` (el default), `RANDOM_PORT`, `DEFINED_PORT` y `NONE`. Para un job de
Batch, **`NONE`**: no hay HTTP que probar, así que levantar un entorno web solo añade beans y
segundos.

**🗣️ 2 minutos.** `MOCK` carga un contexto web **sin servidor** —ni socket ni puerto— y se prueba
con `MockMvc` o `WebTestClient`; es rápido porque no arranca Tomcat, y por eso no prueba el
conector ni el apagado ordenado. `RANDOM_PORT` levanta el servidor embebido en un puerto libre
que te inyecta `@LocalServerPort`. `DEFINED_PORT` hace lo mismo en el `server.port` configurado,
con riesgo de colisión. `NONE` es el que se olvida, y es el correcto para un job de Batch o para
probar una autoconfiguración.

**🔬 El detalle.** Con `RANDOM_PORT` tienes un `TestRestTemplate` listo para `@Autowired` que es
**tolerante a fallos a propósito**: un 4xx o un 5xx **no lanzan excepción**, se leen del
`ResponseEntity` —justo lo contrario del `RestTemplate` de [`13`](13-clientes-http.md), y la
diferencia que hace que un test copiado de producción deje de comportarse igual—. Y el cambio de
`webEnvironment` es cambio de contexto: probar la misma aplicación con `MOCK` en unas clases y
`RANDOM_PORT` en otras son dos arranques en la caché de §6.

---

### 24 → 5

> Tu `@WebMvcTest` no arranca y el log dice `Failed to load ApplicationContext`. ¿Causa probable?

**⏱️ 30 segundos.** Que falta un `@MockitoBean` para una dependencia del controller. El slice
**no escanea `@Component`, `@Service` ni `@Repository`**, así que el servicio que el controller
recibe por constructor no existe en ese contexto: dentro del `IllegalStateException: Failed to
load ApplicationContext` verás un `NoSuchBeanDefinitionException` con el tipo que falta.

**🗣️ 2 minutos.** La regla que comparten todos los slices es esa: cargan **la infraestructura de
una capa y nada más**. `@WebMvcTest` autoconfigura `MockMvc`, los `@Controller`, los
`@ControllerAdvice`, los `Filter`, los `HandlerInterceptor` y los converters, y deja fuera
servicios, repositorios y `DataSource`. El arreglo es declarar `@MockitoBean` por cada
colaborador. La variante frecuente del mismo error: escribir `@WebMvcTest` sin argumento, que
carga **todos** los controllers y entonces necesitas los mocks de todos.

**🔬 El detalle.** Lo primero es leer hacia abajo en el stack trace: el `IllegalStateException` es
el envoltorio del `TestContext` framework y la causa real está en el `Caused by`. Si el tipo que
falta no es un colaborador tuyo sino algo de infraestructura —un `DataSource`, un
`JwtDecoder`—, el diagnóstico cambia: es un `@Configuration` propio que el slice sí recogió y que
exige más contexto del que hay, y la respuesta es aislarlo o importarlo con `@TestConfiguration`
en vez de ampliar el slice hasta convertirlo en un `@SpringBootTest` disfrazado.

---

### 24 → 6

> ¿Qué carga `@DataJpaTest` que `@JdbcTest` no carga, y cuál slice de datos **no** revierte?

**⏱️ 30 segundos.** `@DataJpaTest` añade la capa JPA: `EntityManager`, `TestEntityManager`, tus
`@Entity` y los repositorios de Spring Data. `@JdbcTest` se queda en el `DataSource` y
`JdbcTemplate`/`JdbcClient`, sin repositorios. El slice de datos que **no** revierte es
**`@DataMongoTest`**: no es transaccional, y lo que escribes se queda.

**🗣️ 2 minutos.** Los dos comparten el `DataSource`, y ese es el punto de confusión: si tu
repositorio es `JdbcClient` con SQL escrito a mano, `@JdbcTest` es el slice correcto y más
barato; si es una interfaz de Spring Data JPA, necesitas `@DataJpaTest` porque es quien registra
el proxy del repositorio y el `EntityManager`. `@DataJpaTest` **es transaccional y hace rollback**
al terminar cada método, con todo lo bueno y lo malo que eso trae (§8). En Mongo no hay rollback
automático, así que o limpias tú la colección o los tests se contaminan entre sí en el orden en
que se ejecuten.

**🔬 El detalle.** `@DataJpaTest` trae además `@AutoConfigureTestDatabase` con
`replace = NON_TEST` por defecto: **reemplaza tu `DataSource` por uno embebido** si hay uno en el
classpath, y esa es la línea exacta que te mete H2 sin haberlo pedido. Si quieres probar contra
Postgres de verdad, la salida limpia es Testcontainers con `@ServiceConnection`, que desactiva ese
reemplazo por sí solo (§9). Y en Mongo, la suite empieza a depender del orden de ejecución, que es
el fallo intermitente más caro de diagnosticar.

---

### 24 → 7

> Enumera cuatro cosas de la clave de la caché de contextos, y por qué un `@MockitoBean` en una
> sola clase alarga la suite.

**⏱️ 30 segundos.** Cuatro de la lista: las `classes`/`locations` de `@ContextConfiguration`, los
`contextCustomizers` —ahí entran `@DynamicPropertySource` y los bean overrides—, los
`activeProfiles` de `@ActiveProfiles` y las propiedades de `@TestPropertySource`; además están el
`contextLoader`, el `parent` y el `resourceBasePath`. Un `@MockitoBean` declarado en una clase y
no en otra **cambia la clave**, así que son dos contextos y dos arranques en vez de uno
reutilizado.

**🗣️ 2 minutos.** La idea que hay que tener clara es que el `TestContext` framework **no levanta
un contexto por clase de test**: los guarda en una caché estática y los reutiliza, de modo que
veinte clases con la misma configuración pagan el arranque una vez. Ahí se van los ocho minutos de
la suite: no en el número de tests, sino en el número de configuraciones distintas. Y como los
bean overrides forman parte de la clave, cada mock «por si acaso» es un contexto entero más, con
su pool de Hikari, su Flyway y su cadena de filtros.

**🔬 El detalle.** La caché admite **32 contextos** por defecto y desaloja por **LRU**; se ajusta
con la propiedad de sistema `spring.test.context.cache.maxSize`, pero subirla trata el síntoma:
cada contexto vivo retiene su pool y su heap. Y hay un modo de perderla entera: **si el build hace
fork por test la caché no existe**, porque es una variable estática de la JVM — con el `forkMode`
de Surefire en `always` se pierde entre clases y cada una arranca de cero. La disciplina barata es
`@ActiveProfiles("test")` con un `application-test.yaml` compartido; `@TestPropertySource` con un
valor suelto cuesta un contexto por valor distinto.

---

### 24 → 8

> ¿Cómo compruebas, sin adivinar, cuántos contextos cargó tu suite?

**⏱️ 30 segundos.** Subiendo a `DEBUG` la categoría **`org.springframework.test.context.cache`**.
La suite dice cuántos contextos cargó, cuántos aciertos de caché tuvo y cuántos desalojó. Si ese
número se parece al de clases de test, ya tienes la respuesta.

**🗣️ 2 minutos.** Es el antídoto contra la explicación fácil —«la suite es lenta porque hay
muchos tests»—, que casi nunca es la causa: lo caro es cargar muchas configuraciones distintas.
Con el número de contextos y el de desalojos en la mano, el trabajo deja de ser adivinar y pasa a
ser agrupar: unificar perfiles, quitar `@TestPropertySource` sueltos, borrar los `@MockitoBean`
que nadie usa y mirar quién puso `@DirtiesContext`.

**🔬 El detalle.** El número de **desalojos** es la señal más útil de las tres: si hay desalojos,
pasaste de 32 contextos y la caché está reciclando, así que algunas clases pagan el arranque más
de una vez aunque su configuración se repita. Lo que **no** se arregla subiendo `maxSize`, porque
cada contexto retenido cuesta memoria y conexiones. Y si el log no imprime nada de esa categoría,
la primera hipótesis es que el build está forkando por clase y no hay caché que medir.

---

### 24 → 9

> Un compañero pone `@DirtiesContext` en la clase base de todos los tests. ¿Qué le respondes?

**⏱️ 30 segundos.** Que acaba de apagar la caché de contextos. `@DirtiesContext` marca el contexto
como corrupto, lo **cierra** y lo **saca de la caché**: puesto en la clase base, cada clase
arranca su propio contexto desde cero y la suite pasa de segundos a minutos. Es el último recurso,
no una limpieza preventiva.

**🗣️ 2 minutos.** El razonamiento de quien lo pone suele ser correcto en la intención —«que cada
test empiece limpio»— y equivocado en el mecanismo: lo que ensucia casi siempre son **datos**, y
los datos se limpian con `@Transactional` para tests de lectura, con `@Sql` cuando hay commit, o
reseteando el estado en un `@AfterEach`. El contexto no está sucio porque hayas escrito una fila.
`@DirtiesContext` se justifica cuando el test modifica una *bean definition* o deja estado global
inservible; «por higiene» convierte la caché en decorado.

**🔬 El detalle.** La conversación útil no es «quítalo», es «midámoslo»: se sube a `DEBUG` la
categoría `org.springframework.test.context.cache` antes y después, y el número de contextos
cargados cierra la discusión sin opiniones. Si de verdad hay un test que corrompe el contexto, la
anotación se pone **en ese método**, no en la jerarquía entera, y se documenta qué corrompe.

---

### 24 → 10

> ¿Por qué `@Transactional` en un test oculta bugs que sí ocurren en producción? Dos ejemplos.

**⏱️ 30 segundos.** Porque **tu servicio en producción hace commit y tu test no**: el test abre
una transacción antes del método y hace rollback al terminar, así que nunca ejecuta el camino que
sí se ejecuta en producción. Dos ejemplos: una **constraint diferida o un trigger** que solo salta
al confirmar, y una **`LazyInitializationException`** que en el test no ocurre porque test y
código comparten el mismo persistence context.

**🗣️ 2 minutos.** Son dos familias distintas de punto ciego. La primera es todo lo que solo pasa
al confirmar —constraints diferidas, triggers, un `flush` que Hibernate nunca ejecutó porque
nadie pidió el commit—: verde en el test, violación de integridad en producción. La segunda es de
alcance del persistence context: como el del test sigue abierto, los lazy loads funcionan, y el
mismo código explota en producción cuando la sesión ya se cerró
([`15` §7](15-datos-jdbc-jpa-mongo-y-redis.md#7-️-lazyinitializationexception-y-open-in-view)).
Hay una tercera, de propina: como ya hay una transacción abierta, un método `REQUIRED` **se une a
la del test** y tampoco estás observando la propagación de
[`16` §4](16-transacciones.md#4--propagación).

**🔬 El detalle.** Eso no lo convierte en un antipatrón: es perfecto para aislar tests de lectura
sin escribir `delete`, y `@DataJpaTest` lo trae puesto justo por eso. La regla es por qué pruebas:
cuando lo que pruebas **es** el commit o la propagación, se quita y se limpian los datos
explícitamente con `@Sql`; y si quieres confirmar dentro de un test transaccional, existen
`@Commit` y `@Rollback(false)`. Nunca respondas «pongo `@Transactional` en los tests, que es buena
práctica»: di para qué lo usas y cuándo lo quitas.

---

### 24 → 11

> Tienes `RANDOM_PORT` con `@Transactional` y los datos no se revierten. ¿Por qué?

**⏱️ 30 segundos.** Porque **el servidor atiende en otro hilo**. La transacción del test está
atada al hilo del test, y lo que escribe el código que corre dentro del servidor embebido —en un
hilo del pool de Tomcat— ocurre en otra transacción, que hace **commit**. El rollback del test no
puede alcanzarlo.

**🗣️ 2 minutos.** Es la consecuencia directa del modelo de
[`16` §2](16-transacciones.md#2--el-modelo-y-quién-lo-invoca): la transacción vive en un
`ThreadLocal`, así que su alcance es un hilo, no «el test». Con `webEnvironment = MOCK` y
`MockMvc` no aparece el problema, porque no hay socket y todo corre en el hilo del test; en cuanto
pasas a `RANDOM_PORT` hay HTTP de verdad, el `TestRestTemplate` sale por el cable y el servidor
responde en su propio hilo. El arreglo no es insistir con la anotación: es limpiar explícitamente
con `@Sql`.

**🔬 El detalle.** Lo peligroso no es que falle, es que **medio funciona**: la escritura que hace
el propio test en su hilo sí se revierte, y la que hace el servidor no, así que la clase deja
residuos sin que nadie lo note hasta que un test posterior falla por un dato que «no debería
existir» — y falla según el orden de ejecución, que es el síntoma más caro de perseguir. La regla
corta: con `RANDOM_PORT`, `@Transactional` en el test **no aplica en absoluto** y la limpieza es
tuya.

---

### 24 → 12

> ¿Cuándo eliges `MockMvc` sobre `TestRestTemplate` y qué garantía pierdes?

**⏱️ 30 segundos.** Por defecto en MVC, siempre que la pregunta del test sea sobre **rutas,
converters, `@ControllerAdvice` o filtros**: `MockMvc` invoca el `DispatcherServlet` sin socket y
es órdenes de magnitud más rápido. Lo que pierdes es todo lo que hay por debajo: **conector,
servidor y red** — la serialización sobre el cable y que el puerto de verdad conteste.

**🗣️ 2 minutos.** El reparto del capítulo es: `MockMvc` por defecto en MVC, `WebTestClient`
siempre en WebFlux —y también sirve contra un puerto real—, y `TestRestTemplate` **solo cuando el
punto del test es que haya un socket**. La razón de preferir `MockMvc` no es solo velocidad: cubre
exactamente lo que sueles romper —un `@PathVariable` mal mapeado, un converter que no serializa
como crees, un `@ControllerAdvice` que no captura la excepción— y no exige levantar el servidor
para comprobarlo. `MockMvcTester` (`Since: 6.2`) es lo mismo con API de AssertJ.

**🔬 El detalle.** La garantía que más duele perder es la de seguridad, y no por el socket:
**`MockMvc` por sí solo no ejecuta la cadena de filtros**, así que tus reglas nunca corren y el
test pasa siempre. Es el falso verde más peligroso del capítulo, y se arregla con
`@AutoConfigureMockMvc`, que registra la cadena, o con el post-processor `springSecurity()` en el
setup manual — el detalle está en
[`20` §12](20-spring-security-el-mecanismo.md#12--probarlo-sin-levantar-un-proveedor-de-identidad).
La otra diferencia práctica: `TestRestTemplate` no lanza excepción ante un 4xx o un 5xx, los lees
del `ResponseEntity`.

---

### 24 → 13

> ¿Por qué `MockRestServiceServer` no sirve para probar un timeout ni un circuit breaker?

**⏱️ 30 segundos.** Porque **responde al instante**. Un timeout y la apertura de un circuito
necesitan **latencia** real, y un stub en memoria no la produce; tampoco la produce un
`@MockitoBean`. El test pasa sin haber ejercitado nunca el reloj, que es justo lo que querías
probar.

**🗣️ 2 minutos.** `MockRestServiceServer` sirve para lo que sí sabe hacer: comprobar que el
cliente construye la URL correcta, manda los headers correctos y deserializa la respuesta. Para
[`19`](19-resiliencia.md) hace falta un stub HTTP que **sepa tardar** —WireMock, que es lo que usa
`L05`— o forzar a mano la transición del `CircuitBreaker` a `OPEN`. Son dos preguntas distintas:
«¿hablo bien con el proveedor?» y «¿qué hago cuando el proveedor tarda?».

**🔬 El detalle.** Y encima hay una trampa de §5 esperando: si para «aislar» moqueas el bean
anotado con `@Retryable` o `@CircuitBreaker`, **moqueaste su proxy**, así que no hay ni reintento
ni circuito, y el test vuelve a pasar sin probar nada. La forma honesta de probar el circuito sin
esperar segundos es configurarlo con ventanas pequeñas en el perfil de test y forzar las llamadas
fallidas, o manipular el estado del `CircuitBreaker` directamente y verificar el *fallback*.

---

### 24 → 14

> "H2 sirve para probar la capa de datos": da la versión precisa, y di qué aporta
> `@ServiceConnection` frente a `@DynamicPropertySource`.

**⏱️ 30 segundos.** La versión precisa es: **H2 sirve para probar que tu código funciona contra
H2**. No tiene `jsonb`, su comportamiento con los bloqueos es otro, sus secuencias y su
`ON CONFLICT` difieren y su dialecto acepta SQL que Postgres rechaza. `@ServiceConnection` aporta
que **lee el contenedor y registra `spring.datasource.url`, `username` y `password` por ti**,
mientras que con `@DynamicPropertySource` esas claves las escribes a mano.

**🗣️ 2 minutos.** El resultado de probar contra H2 no es un test que falla: es uno que pasa y un
bug que aparece en producción, que es peor. La alternativa es Testcontainers, con `@Container`
sobre un campo **`static`** —así el contenedor arranca una vez por clase y no una por método— y
la imagen con **tag exacto**, nunca `:latest`. `@ServiceConnection` existe **desde Boot 3.1**;
antes de eso, `@DynamicPropertySource` era la única forma, y sigue siendo la buena para cualquier
valor que no exista hasta que arranque el contenedor y que `@ServiceConnection` no cubra.

**🔬 El detalle.** `@ServiceConnection` hace algo más que ahorrar tres líneas: **desactiva el
reemplazo por base embebida**. Como el `DataSource` ya apunta a una base de prueba, el
`replace = NON_TEST` de `@AutoConfigureTestDatabase` no lo sustituye, y por eso `@DataJpaTest` con
Testcontainers funciona sin anotaciones extra — con `@DynamicPropertySource` esa parte había que
resolverla aparte. El costo honesto de Testcontainers es la descarga inicial de la imagen y uno o
dos segundos por arranque, que se amortizan compartiendo el contenedor entre clases o con
contenedores reutilizables, que exigen `withReuse(true)` **y** habilitarlo en el
`~/.testcontainers.properties` de tu máquina. Testcontainers no es lento: es honesto.

---

### 24 → 15

> Moqueas un bean `@Transactional` con `@MockitoBean` y el test deja de detectar un fallo de
> rollback. ¿Qué desapareció exactamente?

**⏱️ 30 segundos.** Desapareció **el proxy**, y con él la transacción entera. `@Transactional` no
es código dentro de tu método: es un interceptor que vive en el proxy que el contenedor puso
delante del bean ([`05`](05-proxies-y-aop.md)). Al sustituir el bean sustituyes su proxy, así que
no hay `begin`, no hay `commit` y no hay rollback que fallar — el test pasa probando un objeto que
no tiene el comportamiento que el test creía estar verificando.

**🗣️ 2 minutos.** Es el mismo mecanismo para todas las anotaciones declarativas: `@Transactional`,
`@Cacheable`, `@Retryable`, `@PreAuthorize`. Todas son interceptores sobre un proxy, y todas
desaparecen a la vez cuando moqueas el bean anotado. El síntoma es el peor posible: el test no
falla, se vuelve **vacuo**. Si lo que quieres es verificar que el bean real hace lo suyo pero sin
salir a la red, lo correcto es `@MockitoSpyBean` —que **envuelve** el bean real, proxy incluido— o
moquear la dependencia de abajo, no el bean que lleva la anotación.

**🔬 El detalle.** La regla de qué se toca lo resume: **se moquea lo que no controlas y cuesta** —un
proveedor externo, un IdP, un correo—, **se levanta lo que tu código usa de verdad** —tu base, tu
caché, con Testcontainers— y **no se toca el framework**. Moquear un repositorio de Spring Data es
la versión barata del mismo error: el test pasa con cualquier consulta, hasta con una que no
compila en SQL, porque estás probando tus mocks. Y para ver de verdad un fallo de rollback hay que
llegar al commit, así que el test **no** puede ser `@Transactional` (§8).

---

## Simulación 25 — preguntas P1–P60

### 25 → 1

> Entras a un equipo cuyo servicio corre sobre Spring Boot 3.5.16 y el arquitecto quiere
> subir a 4.x "porque 3.5 ya no tiene soporte". Explica qué significa exactamente ese
> fin de soporte, qué dos cosas mirarías antes de aceptar, y con qué argumento
> defenderías posponerlo un trimestre. — [`01`
> §8](01-spring-boot-y-el-ecosistema.md#8--soporte-eol-y-por-qué-el-baseline-es-una-versión-sin-soporte-oss)

**⏱️ 30 segundos.** Fin de soporte **OSS**, no fin de parches: la línea 3.5 dejó el soporte
abierto el 30 de junio de 2026 y tiene **soporte comercial hasta 2032**. Miro dos cosas: si
ese contrato comercial está firmado, y qué bloquea de verdad la migración. Con las dos
respuestas se puede posponer un trimestre; sin ellas, no se pospone: se improvisa.

**🗣️ 2 minutos.** Mi posición es posponer, **con fecha y con inventario**, y esa es la parte
que convierte la respuesta en una decisión y no en una excusa. El argumento: subir a 4.x no
es un cambio de número. Los starters se renombraron —`spring-boot-starter-web` pasó a
`spring-boot-starter-webmvc` y el `spring-boot-starter-test` único se partió por módulo—, el
baseline de Jackson pasa a 3 con el paquete raíz `tools.jackson`, y Security sube a 7 con la
retirada de lo deprecado en 6.x. Cada una de esas tres toca código, no `pom.xml`. Lo que
pongo encima de la mesa a cambio de posponer son dos entregables: el contrato de soporte
comercial verificado, y la lista de dependencias internas que todavía no publican artefacto
para 4.x. Y digo el precio de quedarse: **Spring Initializr ya no genera proyectos sobre
3.5**, así que cada servicio nuevo se crea en 4.x y se baja a mano. Ese peaje se paga el día
uno y crece con el número de repositorios.

**🔬 El detalle.** El `400` de Initializr es literal y sirve para cerrar la discusión en un
minuto: `Invalid Spring Boot version '3.5.16', Spring Boot compatibility range is >=4.0.0`.
La respuesta completa a "¿en qué versión trabajas?" tiene tres partes —cuál usas, si tiene
soporte OSS o comercial, y qué bloquea la migración—; quien dice "3.5" y se calla suena
desactualizado. El inventario de bloqueos se arma con `./mvnw dependency:tree`: lo que
importa no son las dependencias del BOM, que suben solas, sino las que declaran versión
propia — y cada una de esas es un ticket con dueño.

---

### 25 → 2

> Una librería interna promete darte un `RestClient` ya configurado y no aparece ningún
> bean. Recorre el diagnóstico desde el `pom.xml` hasta el informe de condiciones,
> nombrando el fichero exacto donde esa librería debería declarar su autoconfiguración
> en Boot 3.5. — [`01`
> §4](01-spring-boot-y-el-ecosistema.md#4--qué-hay-dentro-de-un-starter) · [`06`
> §4](06-arranque-y-autoconfiguracion.md#4--dónde-vive-el-catálogo-de-autoconfiguraciones)
> · [`L01`
> §8](l01-esqueleto-cli-y-autoconfiguracion.md#8--el-informe-de-condiciones---debug-y-actuatorconditions)

**⏱️ 30 segundos.** Tres paradas: `dependency:tree` para confirmar que el jar está en el
classpath, `META-INF/spring/org.springframework.boot.autoconfigure.AutoConfiguration.imports`
dentro de ese jar para confirmar que declara su autoconfiguración, y el informe de
condiciones —`--debug` o `/actuator/conditions`— para ver qué condición falló.

**🗣️ 2 minutos.** El orden importa porque cada paso descarta una hipótesis distinta. Primero
`./mvnw dependency:tree -Dincludes=<grupo>:<artefacto>`: si la librería no aparece, no hay
nada que discutir. Si aparece, abro el jar y busco el fichero `.imports`; en Boot 3.5 el
catálogo de autoconfiguraciones vive ahí, **una clase por línea con nombre completamente
cualificado**, y ese es el punto donde se rompe la mitad de los starters internos: siguieron
un tutorial viejo y lo declararon en `META-INF/spring.factories`, que quedó obsoleto en 2.7 y
**se eliminó en 3.0**. No hay error, no hay aviso: la autoconfiguración simplemente no se
carga. Si el fichero está bien, entonces sí es una condición, y el informe lo dice: el bloque
`Negative matches` nombra la clase y la condición exacta que no se cumplió —típicamente un
`@ConditionalOnClass` sobre algo que no está, o un `@ConditionalOnMissingBean` que encontró un
bean tuyo y se apartó—. Con eso ya tienes el culpable sin abrir un debugger.

**🔬 El detalle.** En caliente el mismo informe sale en JSON y se filtra con `jq`:
`curl -s localhost:8081/actuator/conditions | jq '.contexts["inv-api"].negativeMatches | keys | length'`.
La clave `.contexts["inv-api"]` es `spring.application.name`, y hay que filtrar por ella
porque con el puerto de management separado el JSON trae **dos** contextos, el tuyo y el hijo
de Actuator. Y el cuarto bloque, `Unconditional classes`, es el que `06` no desarrolla: son
las autoconfiguraciones que se aplican sin condición alguna.

---

### 25 → 3

> Necesitas dos `RestClient` en el mismo contexto, uno para `inv-supplier` y otro para
> el IdP. Di por qué no puedes resolverlo con `@Component`, cómo los declaras, y qué
> tiene que pasar en el punto de inyección para que el contenedor no falle con
> `NoUniqueBeanDefinitionException`. — [`02`
> §5](02-contenedor-ioc-y-ciclo-de-vida.md#5--component-y-bean-no-son-lo-mismo) · [`03`
> §3](03-inyeccion-de-dependencias.md#3--cómo-elige-el-contenedor-entre-candidatos) ·
> [`13` §4](13-clientes-http.md#4--la-clienthttprequestfactory-timeouts-y-pool)

**⏱️ 30 segundos.** Con `@Component` no puedo: `RestClient` no es una clase mía y no la puedo
anotar. Van dos métodos `@Bean` en una `@Configuration`, cada uno con su `baseUrl`, sus
timeouts y su factory. Y en el punto de inyección hace falta un `@Qualifier`, o que el nombre
del parámetro coincida con el del bean.

**🗣️ 2 minutos.** La distinción es de propiedad del código: `@Component` exige que la clase
sea tuya y anotable; `@Bean` te deja escribir la receta de construcción de cualquier objeto,
incluido uno de una librería. Con dos beans del mismo tipo el contenedor resuelve **por
tipo**, encuentra dos candidatos, intenta filtrar por `@Qualifier`, después por `@Primary`, y
solo al final desempata por nombre; si nada desempata, `NoUniqueBeanDefinitionException` y el
contexto no arranca. Yo declaro `@Qualifier` explícito en los dos puntos de inyección y no me
apoyo en el desempate por nombre, por una razón concreta: **renombrar un parámetro cambia qué
bean se inyecta sin tocar una anotación**, y eso es un cambio invisible en una revisión de
código. El precio es dos líneas más de ceremonia; lo que compro es que el refactor de otro no
me redirija el tráfico al IdP hacia el proveedor.

**🔬 El detalle.** Con `@Bean` el nombre del bean sale del **nombre del método**, así que
renombrar `supplierClient()` rompe cualquier `@Qualifier("supplierClient")`. Y la razón de
fondo para tener dos y no uno compartido es de aislamiento: `RestClient.Builder` es
`prototype`, cada cliente construido lleva su propia `ClientHttpRequestFactory` y por tanto
**su propio pool** —Apache HttpClient 5 trae 25 conexiones totales y 5 por host—, así que
cuando el IdP se degrada agota el suyo y no el del proveedor. Es el primer bulkhead, gratis y
anterior a cualquier patrón de `19`.

---

### 25 → 4

> Un bean tuyo abre un `ExecutorService` propio en su construcción. Di quién lo cierra
> si el bean es `singleton`, quién lo cierra si es `prototype`, y cómo comprobarías en
> el apagado que no quedó ningún hilo vivo. — [`02`
> §9](02-contenedor-ioc-y-ciclo-de-vida.md#9--destrucción-y-lo-que-el-contenedor-no-destruye)
> · [`04` §4](04-scopes-de-bean.md#4--prototype-y-quién-limpia-después) · [`L09`
> §7](l09-empaquetado-imagen-y-limpieza.md#7--graceful-shutdown-con-una-petición-en-vuelo)

**⏱️ 30 segundos.** Si es `singleton`, lo cierra el contenedor: `@PreDestroy`, `destroy()` o
el `destroyMethod` del `@Bean` —que además detecta por convención un `close()` o `shutdown()`
público—. Si es `prototype`, **no lo cierra nadie**: el contenedor no guarda referencia y no
ejecuta su `@PreDestroy`. Se comprueba con un `threaddump` después del apagado.

**🗣️ 2 minutos.** Ese asimetría es la mitad del capítulo de scopes y es lo que más se falla.
El contenedor crea el `prototype`, lo entrega y se olvida de él; liberar sus recursos es de
quien lo pidió. Mi regla en revisión es simple: un bean que abre un `ExecutorService`,
un fichero o una conexión **no puede ser `prototype`**, o si lo es, quien lo pide tiene que
cerrarlo en un `try`-`finally` visible. Y hay una trampa encima: un `prototype` inyectado por
constructor en un `@Service` singleton se pide **una sola vez, en el arranque**, y esa
instancia se queda para siempre — se comporta como singleton. El scope del bean no manda:
manda cuántas veces se pide.

**🔬 El detalle.** Para comprobar el apagado: mandar `SIGTERM` —`docker compose stop` o
`kill <PID>` sin `-9`—, que es lo que Boot convierte en cierre ordenado gracias al shutdown
hook que registra `SpringApplication`; un `SIGKILL` no ejecuta nada. En el log tienen que
salir `Commencing graceful shutdown` y `Graceful shutdown complete`, y **eso solo drena
peticiones HTTP**: no espera a tus `@Async` ni a un job de Batch. Para el pool del `@Async`
hace falta además `spring.task.execution.shutdown.await-termination: true` con su
`await-termination-period`. Y antes del apagado, `/actuator/threaddump` filtrado por el
prefijo de nombre de tus hilos dice si quedó alguno vivo.

---

### 25 → 5

> Tienes tres sitios para el trabajo de arranque: el constructor, un `@PostConstruct` y
> un `ApplicationRunner`. Di qué está disponible en cada uno, cuál es el único donde
> puede correr trabajo transaccional, y qué le pasa al arranque si ese trabajo tarda
> treinta segundos. — [`06`
> §9](06-arranque-y-autoconfiguracion.md#9--código-que-corre-al-arrancar) · [`02`
> §4](02-contenedor-ioc-y-ciclo-de-vida.md#4--las-fases-del-arranque) · [`05`
> §2](05-proxies-y-aop.md#2--quién-crea-el-proxy-y-cuándo)

**⏱️ 30 segundos.** En el constructor solo tienes lo que entra por parámetro —los `@Value` de
campo todavía son `null`—. En `@PostConstruct` el bean está completo, pero corre **sobre el
objeto, no sobre el proxy**. El único sitio donde funciona trabajo transaccional es el
`ApplicationRunner`, porque ahí el contexto ya está entero y lo que recibes es el proxy.

**🗣️ 2 minutos.** El orden de las fases lo explica todo: constructor (3), inyección de campos
(4), creación de **los proxies** en el `BeanPostProcessor` (6), y solo después
`@PostConstruct` (7), que corre sobre la instancia interna que el proxy envuelve. Por eso un
`@Transactional` llamado desde `@PostConstruct` no abre transacción y **no avisa**: es la
self-invocation con otro disfraz. El `ApplicationRunner` corre en el paso 9, con el contexto
listo y el `ApplicationReadyEvent` ya disparado, así que el bean que te inyectaron ahí sí es
el proxy. Prefiero `ApplicationRunner` sobre `CommandLineRunner` porque recibe los argumentos
ya parseados. Y si el trabajo tarda treinta segundos, el arranque tarda treinta segundos: los
dos runners **bloquean**, corren en el hilo `main`, y lo que lance ahí impide arrancar.

**🔬 El detalle.** Treinta segundos de arranque no son un detalle estético en un orquestador:
si el `readinessProbe` tiene menos margen, el pod se reinicia en bucle y nadie ve el runner
terminar nunca. La salida correcta cuando el trabajo es genuinamente lento es sacarlo del
arranque —un `@Scheduled` con `initialDelay`, o un endpoint que lo dispare— y dejar el runner
solo para lo que tiene que estar listo **antes** de aceptar tráfico. Si algo tiene que pasar
una vez y rápido, el `ApplicationRunner`; si puede tardar, no bloquees el arranque con ello.

---

### 25 → 6

> Lideras una revisión de código donde medio equipo inyecta por campo "porque es más
> corto". Construye el argumento con tres patas —diseño, runtime y pruebas— y di cuál de
> las tres convence a un desarrollador que ya está cómodo con `@Autowired`. — [`03`
> §1](03-inyeccion-de-dependencias.md#1--las-tres-formas-y-por-qué-solo-una-sobrevive-a-una-revisión)
> · [`24`
> §2](24-testing.md#2--el-test-unitario-sin-contenedor-y-por-qué-puedes-escribirlo)

**⏱️ 30 segundos.** Diseño: el constructor pone la factura a la vista y ocho parámetros duelen
—esa señal es la que te dice que la clase viola responsabilidad única—. Runtime: los campos
pueden ser `final`, el objeto queda completo desde que existe y desaparece una familia entera
de `NullPointerException`. Pruebas: `new InventoryService(mock1, mock2)` sin levantar un
contexto. **La tercera es la que convence.**

**🗣️ 2 minutos.** Y convence porque es la única que el desarrollador nota en su propio día.
Las dos primeras son argumentos de diseño y contra ellas siempre hay un "a mí nunca me pasó";
la tercera se demuestra con el cronómetro de la suite. Con inyección por constructor el test
unitario es un `new` con mocks de Mockito y `@ExtendWith(MockitoExtension.class)`, sin
`ApplicationContext`; con inyección por campo necesitas reflexión o Spring, y la suite se va a
los minutos. Ese es el intercambio que pongo encima de la mesa en la revisión: escribes cuatro
líneas menos y pagas la inmutabilidad, la testabilidad sin contenedor y el único indicador de
diseño que el compilador te regala. Y reconozco el argumento honesto del otro lado: si lo que
molesta de verdad es el boilerplate, la respuesta real es Lombok con
`@RequiredArgsConstructor` — no `@Autowired` en el campo.

**🔬 El detalle.** Hay un cuarto efecto que cierra la discusión cuando alguien insiste: **con
inyección por campo una dependencia circular "funciona"**. El contenedor crea los dos objetos
vacíos y rellena los campos después, así que el ciclo queda ahí, invisible, hasta que alguien
toca el orden de inicialización. Por constructor falla en el arranque desde Boot 2.6, con el
diagrama de cajas que nombra los beans del ciclo. Y no hace falta escribir `@Autowired` en el
constructor: con un solo constructor, desde Spring 4.3 sobra.

---

### 25 → 7

> Te piden añadir una regla de validación por tipo de movimiento cada vez que negocio
> inventa uno, sin tocar el servicio que las aplica. Diseña la solución con lo que da el
> contenedor, di qué principio SOLID estás cobrando y cómo fijas el orden de ejecución
> de las reglas. — [`03`
> §5](03-inyeccion-de-dependencias.md#5--inyectar-varios-el-strategy-que-sale-gratis)

**⏱️ 30 segundos.** Una interfaz `InventoryValidator` y un bean por regla; el servicio inyecta
`List<InventoryValidator>` y los recorre. Añadir una regla pasa a ser añadir una clase con
`@Component`: cero cambios donde se usan. Eso es **Open/Closed**, con el contenedor haciendo
el trabajo. El orden se fija con `@Order(n)`, menor primero.

**🗣️ 2 minutos.** El contenedor sabe inyectar **todos** los beans de un tipo, y es de las
cosas más útiles de Spring y de las menos usadas. La variante que uso cuando la regla se
selecciona por un valor —el tipo de movimiento— es `Map<String, InventoryValidator>`, donde la
clave es el nombre del bean: el servicio hace `byName.get(tipo)` y no hay un solo `switch` que
crezca. Lo que sí exijo en revisión es el `@Order` **explícito**, y esta es la parte donde
tomo posición: sin orden declarado el orden es **indefinido**, no alfabético ni de classpath,
y apoyarse en el que salió hoy es un bug esperando a un refactor. En banca eso importa porque
el orden de las validaciones decide qué error ve el cliente: si la regla de saldo corre antes
que la de formato, el mensaje que sale es el equivocado.

**🔬 El detalle.** `List<T>` falla el arranque si no hay ningún candidato, salvo que el punto
sea `@Autowired(required = false)` o venga de un `ObjectProvider` — y eso normalmente es lo
que quieres: una cadena de validación vacía es un bug, no un caso válido. Los genéricos
también cualifican: `Validator<Invoice>` y `Validator<Payment>` conviven y un punto de
inyección de tipo `Validator<Invoice>` resuelve sin ambigüedad, porque Spring compara los
tipos genéricos y no solo el tipo crudo.

---

### 25 → 8

> Quieres que el `X-Request-Id` esté disponible en toda la pila sin pasarlo por
> parámetro. Compara un bean de scope `request`, un `ThreadLocal` propio y el MDC del
> logger: di cuál sobrevive a un salto `@Async` y cuál no existe siquiera en WebFlux. —
> [`04` §6](04-scopes-de-bean.md#6--los-scopes-web-y-dónde-no-existen) · [`08`
> §8](08-modelo-de-ejecucion-web.md#8--threadlocal-el-contexto-que-viaja-pegado-al-hilo)
> · [`18`
> §5](18-asincronia-scheduling-y-eventos.md#5--propagación-de-contexto-lo-que-se-queda-en-el-hilo-del-request)

**⏱️ 30 segundos.** Ninguno de los tres sobrevive al salto `@Async` por sí solo: los tres son
`ThreadLocal`. El MDC es el único que se propaga con un `TaskDecorator` estándar y el único
que sirve para logs. Y en WebFlux **el scope `request` no existe en absoluto**: no hay dónde
colgarlo.

**🗣️ 2 minutos.** Yo elijo el MDC, y digo qué pago. Un bean de scope `request` te da tipado y
ciclo de vida, pero vive del `RequestContextHolder`, que es un `ThreadLocal`, y fuera de un
request no se puede resolver: en un `@Async`, en un `@Scheduled` o en un hilo propio revienta
con `IllegalStateException: No thread-bound request found`. Un `ThreadLocal` propio es lo
mismo con más código y con la obligación de limpiarlo en un `finally` —los hilos se
reutilizan, y sin `remove()` filtras datos de una petición a otra—. El MDC tiene la misma
limitación de hilo, pero es el único que el sistema de logging ya lee, y se propaga con
`ContextPropagatingTaskDecorator` sobre el executor. Lo que pago es que el MDC son cadenas:
no hay tipos y no hay ciclo de vida, y quien lo lea tiene que tolerar que falte.

**🔬 El detalle.** Propagar **copia, no comparte**: si el `FilterChainProxy` limpia el holder
al terminar el request, tu copia sigue viva en el otro hilo — que es lo que quieres. Y hay un
matiz fino que se ve en `L08`: copiar el MDC propaga **los textos que se imprimen**, no los
contextos. Por eso ahí el `requestId` viaja al hilo `inv-task-1` y el `SecurityContext` no, y
la excepción que sale es `AuthenticationCredentialsNotFoundException`. En WebFlux el
equivalente es el `Context` de Reactor, que viaja con la suscripción y se propaga **de abajo
hacia arriba**: solo lo ven los operadores que están por encima del `contextWrite`.

---

### 25 → 9

> La self-invocation rompe `@Transactional`, `@Cacheable` y `@PreAuthorize` por el mismo
> motivo, pero el síntoma es distinto en cada una. Descríbelos, y di cuál de los tres es
> un incidente de seguridad y no un bug de rendimiento. — [`05`
> §5](05-proxies-y-aop.md#5-️-self-invocation-el-fallo-silencioso-número-uno) · [`17`
> §4](17-cache.md#4-️-el-proxy-otra-vez-self-invocation) · [`20`
> §8](20-spring-security-el-mecanismo.md#8--method-security-el-proxy-de-05-con-otro-sombrero)

**⏱️ 30 segundos.** El mecanismo es uno: `this` no pasa por el proxy. Los síntomas son tres.
`@Transactional`: el dato se confirma a medias y no hay rollback. `@Cacheable`:
`cache.gets{result="hit"}` se queda en cero y cada llamada va a la base. `@PreAuthorize`: **la
comprobación no ocurrió**. El tercero es un incidente de seguridad, los otros dos son de
rendimiento y de consistencia.

**🗣️ 2 minutos.** Y esa distinción es la que importa cuando hay que priorizar el arreglo. Con
`@Transactional` y `@Cacheable` el sistema hace **más** trabajo del que crees y el daño es
medible: latencia, conexiones retenidas, un commit parcial que la reconciliación va a
encontrar. Con `@PreAuthorize` el sistema hace **menos**: el método se ejecutó y nadie evaluó
si el usuario podía. No hay excepción, no hay log, y la métrica que lo delataría no existe
porque el interceptor ni corrió. En una auditoría eso no se reporta como un bug de
rendimiento: se reporta como un control que no estaba operando, y la pregunta siguiente es
desde cuándo. Por eso, cuando reviso una clase con method security, la regla que aplico es que
**ningún método anotado se llama desde dentro de su propia clase**, y si hace falta, se
separa el bean.

**🔬 El detalle.** La regla mental completa: misma clase, `private`, `final` o `static` → no
hay proxy → no hay transacción, ni caché, ni retry, ni async, ni permiso. Desde Spring
Framework 6.0 con CGLIB —el default de Boot— la anotación sí se respeta en `protected` y
package-private, porque la subclase puede sobrescribirlos; lo que nunca funciona es `private`.
Y desde Security 6.3 lo que lanza `@PreAuthorize` al denegar es
`AuthorizationDeniedException`, que extiende `AccessDeniedException` — importa porque no se
lanza donde el `AuthorizationFilter`, y eso cambia quién la ve.

---

### 25 → 10

> Te llega un método que lleva `@Transactional`, hace dentro una llamada HTTP al
> proveedor y encima tiene un retry. Rediséñalo: di qué queda en cada clase, en qué
> orden se apilan los decoradores que sobrevivan, y por qué el retry no puede quedar por
> fuera de la transacción. — [`05`
> §7](05-proxies-y-aop.md#7--cuando-hay-varios-proxies-sobre-el-mismo-método) · [`16`
> §8](16-transacciones.md#8--el-límite-de-la-transacción-no-es-el-límite-de-tu-método) ·
> [`19` §7](19-resiliencia.md#7--el-orden-en-que-se-apilan)

**⏱️ 30 segundos.** La llamada HTTP sale de la transacción, punto. Queda un método orquestador
**sin anotar** que llama primero al gateway y después al servicio transaccional; el retry vive
en el gateway, envolviendo solo la llamada saliente. El orden de los que sobreviven es
`Retry(CircuitBreaker(llamada))`, y `@Transactional` no queda por fuera de ninguno de los dos.

**🗣️ 2 minutos.** La razón es aritmética, no estética. Un retry que envuelve una transacción
abierta retiene una conexión de Hikari durante **todos** los backoffs: con tres intentos, un
segundo de espera entre ellos y veinte peticiones concurrentes son veinte conexiones retenidas
dos segundos, y un Hikari por defecto tiene **diez**. El pool se agota antes de que el
proveedor se recupere, y el mecanismo que pusiste para hacer el servicio más resistente es el
que lo tumba. El reparto queda así: `SupplierGateway` con `@Retry` y `@CircuitBreaker` y sin
una línea de persistencia; `InventoryService` con `@Transactional` y sin una llamada saliente;
y un tercer método que los orquesta y que no lleva ninguna de las tres anotaciones —tiene que
ser un método sin proxy, porque su trabajo es precisamente **no** ser un límite—.

**🔬 El detalle.** Cuando de verdad hay que apilar, hay que declararlo: `@Transactional`,
`@Cacheable` y `@Async` se registran los tres con `Ordered.LOWEST_PRECEDENCE`, y un empate de
precedencia **no define quién queda fuera** — el resultado depende del orden de registro, que
no es contrato. Resilience4j es la excepción porque trae orden propio y documentado
(`retry-aspect-order`, `circuit-breaker-aspect-order`…, con `LOWEST_PRECEDENCE - 5`, `- 4`,
`- 3`, `- 2`); lo que no define es dónde queda respecto de `@Transactional`, que es justo el
cruce peligroso. Si dos de estas conviven en un método y te da pereza declarar el orden,
sepáralas en dos beans y el problema se va con ellas.

---

### 25 → 11

> El arranque muere con `Parameter 0 of constructor in
> com.invlab.invapi.inventory.InventoryService required a bean of type ... that could
> not be found`. Da el orden de diagnóstico completo y di en qué caso concreto el bloque
> `Action:` del mensaje te manda al sitio equivocado. — [`06`
> §6](06-arranque-y-autoconfiguracion.md#6--el-informe-de-condiciones-por-qué-existe-ese-bean)
> · [`A03` §3](a03-catalogo-de-errores-y-diagnostico.md#3--el-contexto-que-no-arranca)

**⏱️ 30 segundos.** Primero `/actuator/beans` o el informe de condiciones, no el código. Las
tres causas reales, en orden: la clase está **fuera del subárbol que se escanea**, un
`@ConfigurationProperties` sin `@ConfigurationPropertiesScan`, o un `@Conditional` que evaluó
`false`. El bloque `Action:` te manda al sitio equivocado justo en el segundo caso.

**🗣️ 2 minutos.** El diagnóstico se hace de abajo arriba. Si el mensaje viene envuelto en un
`UnsatisfiedDependencyException`, bajo al último `Caused by:`: `No qualifying bean of type` es
escaneo o condiciones, `expected single matching bean but found` es ambigüedad, `currently in
creation` es un ciclo. Confirmado que es el primero, arranco con `--debug` o miro
`/actuator/conditions`: si el bean es de una autoconfiguración, aparece en `negativeMatches`
con la condición que no se cumplió; si es tuyo, `/actuator/beans` **no lo lista** y el
problema es de escaneo. Casi nunca falta la anotación: `@SpringBootApplication` escanea su
propio paquete y los de abajo, así que un `com.invlab.shared` colgando al lado de
`com.invlab.invapi` no lo ve nadie. La corrección buena no es ampliar el `@ComponentScan`: es
mover la clase al subárbol, o —para una librería compartida— darle su propia
autoconfiguración, que es lo correcto y lo que casi nadie hace.

**🔬 El detalle.** El caso en que `Action:` miente es el del `@ConfigurationProperties` sin
`@ConfigurationPropertiesScan`: el mensaje habla de un bean que falta y te sugiere revisar
definiciones y `@Qualifier`, y **no menciona la configuración por ningún lado**. Buscas el
`@Component` que no existe durante media hora. La evitación estructural es una decisión de
estructura y no de anotaciones: la clase de arranque vive en el paquete raíz del proyecto y
todo lo demás cuelga de ahí. Y `@Import` es la cuarta salida, que trae una `@Configuration`
esté donde esté sin abrir el escaneo.

---

### 25 → 12

> Operaciones necesita cambiar el `read-timeout` del proveedor en producción sin
> reconstruir la imagen y sin tocar el repositorio. Di qué fuente de propiedades usas,
> cómo se escribe esa clave en esa fuente, y qué pasa exactamente si la misma clave
> también está en el `application-prod.yml` del jar. — [`07`
> §3](07-configuracion-externalizada.md#3--el-orden-de-precedencia) · [`07`
> §5](07-configuracion-externalizada.md#5--relaxed-binding) · [`L09`
> §6](l09-empaquetado-imagen-y-limpieza.md#6--el-mismo-artefacto-en-dos-entornos-variables-de-entorno-y-el-perfil-prod)

**⏱️ 30 segundos.** Variable de entorno: `INV_SUPPLIER_READTIMEOUT`. Gana al
`application-prod.yml` del jar sin discusión, porque las variables de entorno están en la
posición 6 de la precedencia y los ficheros **dentro** del jar en la 9 y la 10. El valor del
YAML sigue ahí y simplemente pierde.

**🗣️ 2 minutos.** Esta es la propiedad de la que depende que el mismo artefacto sirva en
todos los entornos, así que la defiendo entera. La traducción del nombre es mecánica y es el
*relaxed binding*: mayúsculas, el punto pasa a `_` y **el guion desaparece**, así que
`inv.supplier.read-timeout` es `INV_SUPPLIER_READTIMEOUT`. `INV_SUPPLIER_READ_TIMEOUT` también
liga, porque el binding acepta ambas, pero conviene aprender la canónica. Dos avisos que doy
siempre en el mismo momento. El primero: el relaxed binding **solo aplica a
`@ConfigurationProperties`**, no a `@Value`, que hace una búsqueda literal de la clave. El
segundo: si de verdad hay que cambiarlo **ya**, en un incidente, la línea de comandos gana a
todo (`--inv.supplier.read-timeout=3s`), y eso no obliga ni a reconstruir ni a redesplegar la
configuración. Lo que no acepto es tocar el `application.yml` del artefacto: obliga a
reconstruir y a volver a pasar por el pipeline de aprobación entero.

**🔬 El detalle.** Y la discusión se cierra sin abrir ningún fichero, con
`/actuator/env/inv.supplier.read-timeout`: el endpoint devuelve las fuentes **en orden de
precedencia**, así que `propertySources[0]` es la que ganó, y su campo `origin` nombra la
variable exacta —`System Environment Property "INV_SUPPLIER_READTIMEOUT"`—. Diez segundos
frente a media hora de "pues el fichero dice otra cosa". Ojo con lo que **no** va por esta
vía: una variable de entorno es visible en `docker inspect`, en el `/proc` del contenedor y en
`/actuator/env` si se te olvida cerrarlo, así que ahí van URLs y timeouts, nunca secretos.

---

### 25 → 13

> Distingue `@Profile`, `@ConditionalOnProperty` y `@ConditionalOnMissingBean` por quién
> los evalúa y en qué momento. Después contesta: ¿sirve alguno de los tres como feature
> flag que negocio pueda apagar sin desplegar, y por qué la respuesta honesta incomoda?
> — [`07` §7](07-configuracion-externalizada.md#7--profiles) · [`02`
> §8](02-contenedor-ioc-y-ciclo-de-vida.md#8--registro-condicional-profile-y-conditional)
> · [`06` §5](06-arranque-y-autoconfiguracion.md#5--las-condiciones)

**⏱️ 30 segundos.** `@Profile` lo evalúa el contenedor en el **registro** de la bean
definition; `@ConditionalOnProperty` y `@ConditionalOnMissingBean` son de la familia
`@Conditional` y también se evalúan en el registro, la última **después** de tus propias
`@Configuration`. Ninguno de los tres sirve como feature flag: **la condición se evalúa una
vez, en el arranque**.

**🗣️ 2 minutos.** Y esa es la respuesta honesta que incomoda, porque lo que negocio pide —"un
interruptor que yo pueda apagar"— suena a `@ConditionalOnProperty` y no lo es. Un bean que no
se registró no aparece luego porque cambie una propiedad en caliente: para que apareciera
haría falta reconstruir el contexto, es decir, reiniciar. Lo que sí puedo ofrecer es otra cosa
y hay que decirlo con esas palabras: un flag **leído en cada invocación** —una propiedad
consultada desde el método, o mejor un gestor de flags externo—, que es un `if` en tiempo de
ejecución y no una decisión de registro. `@ConditionalOnMissingBean` no es un flag en absoluto:
es el mecanismo con el que **tu bean siempre gana** sobre el de la autoconfiguración, y su
valor es que no hay que desactivar nada. Y `@ConditionalOnBean` en tu propio código es frágil,
porque depende de un orden de registro que no controlas.

**🔬 El detalle.** Hay un antipatrón concreto que va en la misma conversación y que en banca
es material de auditoría: **`@Profile("!prod")` sobre un bean de seguridad es una bomba**. Se
activa en cuanto alguien arranca sin el profile correcto —un despliegue mal parametrizado, un
pod que no recibió la variable, una prueba de carga contra el entorno real—. La regla segura es
la contraria: lo peligroso se activa **solo** con un profile explícito, del tipo
`@Profile("insecure-local")`, nunca por ausencia. Los profiles se acumulan y **gana el
último**: con `SPRING_PROFILES_ACTIVE=local,prod`, los valores de `prod` pisan a los de
`local`.

---

### 25 → 14

> Nombra tres anotaciones del curso que no hacen absolutamente nada si falta su
> `@Enable*` correspondiente, y di qué síntoma deja cada ausencia: cuál falla en el
> arranque, cuál falla en la primera invocación y cuál no falla nunca. — [`A02`
> §3](a02-catalogo-de-anotaciones.md#3-️-dónde-una-anotación-no-hace-nada) · [`05`
> §5](05-proxies-y-aop.md#5-️-self-invocation-el-fallo-silencioso-número-uno)

**⏱️ 30 segundos.** `@Async` sin `@EnableAsync`, `@Scheduled` sin `@EnableScheduling` y
`@PreAuthorize` sin `@EnableMethodSecurity`. La primera falla en la primera invocación —de
forma disfrazada: corre síncrona—, la segunda **no falla nunca** —el método no se registra y
nadie lo llama—, y la tercera tampoco falla: el método se ejecuta sin comprobar nada. Ninguna
rompe el arranque, y ese es el problema.

**🗣️ 2 minutos.** El matiz que sí distingue a las tres es el síntoma. Con `@Async` sin
habilitar el método corre en el hilo del llamante: la respuesta tarda lo que tardaba antes y
lo notas en la latencia, no en un error — en el log el hilo es `[nio-8080-exec-1]` donde
esperabas `[inv-task-1]`, y esa línea es el diagnóstico entero. Con `@Scheduled` el silencio
es total, y la comprobación barata es `curl localhost:8081/actuator/scheduledtasks`, que tiene
que listar tu método con su `fixedDelay`; si la lista está vacía, falta la anotación. Con
`@PreAuthorize` no hay señal de ninguna clase, y ese es el caso caro. Lo que hay que llevarse
de la tabla de `A02` es la columna de la derecha: de los cinco casos en que una anotación no
hace nada —`private`, `final`, `static`, clase `final`, llamada desde la misma clase—
**cuatro no avisan**, y solo la clase `final` rompe el arranque.

**🔬 El detalle.** Y la comprobación de treinta segundos, que sirve para las tres: imprime la
clase del bean. `InventoryService$$SpringCGLIB$$0` es un proxy; un nombre limpio significa que
no hay ninguno, y entonces ninguna anotación declarativa de ese bean está haciendo nada. Es
más rápido que cualquier debugger y no depende de reproducir el caso. Para `@Transactional`
hay además un log dedicado: `org.springframework.transaction.interceptor` en `TRACE` imprime
`Getting transaction for` antes del método — si esas líneas no aparecen, no hubo transacción.

---

### 25 → 15

> Tienes Tomcat con 200 hilos, un Hikari de 10 conexiones y un proveedor externo que
> responde en 800 ms. Calcula el techo de capacidad de la aplicación, di cuál de esos
> tres números limita de verdad y cuál subirías primero — y qué medirías antes de tocar
> ninguno. — [`08` §2](08-modelo-de-ejecucion-web.md#2--una-instancia-muchos-hilos) ·
> [`15` §2](15-datos-jdbc-jpa-mongo-y-redis.md#2--el-datasource-y-hikaricp) · [`13`
> §2](13-clientes-http.md#2-️-no-hay-timeout-por-defecto-y-ese-es-el-tema)

**⏱️ 30 segundos.** El techo lo pone el proveedor: 200 hilos entre 0,8 s son **250 req/s**, y
las 10 conexiones de Hikari no entran en esa cuenta porque el hilo está esperando HTTP, no
SQL. No subo nada todavía: miro primero `hikaricp.connections.pending` y
`tomcat_threads_busy_threads`, y un `threaddump`.

**🗣️ 2 minutos.** El `threaddump` es lo que decide, porque los dos síntomas se parecen y los
arreglos son opuestos. Hilos en `sun.nio.ch.SocketDispatcher.read0` significa "espero bytes de
otro": falta un timeout o el proveedor es lento. Hilos esperando en
`PoolingHttpClientConnectionManager.lease` significa cola del pool de salida — y ahí hay un
número que casi nadie mira: Apache HttpClient 5 trae **5 conexiones por host**, así que con
200 hilos de Tomcat hay 195 haciendo cola por una de cinco, y la latencia que mides es cola de
pool, no lentitud del proveedor. Hilos en `TIMED_WAITING` dentro de tu proceso significa que un
límite tuyo —semáforo del bulkhead, pool de conexiones, lock— es el que frena. Lo que no hago
en ninguno de los tres casos es subir `server.tomcat.threads.max`: si los hilos se acumulan es
porque algo aguas abajo es lento, y más hilos solo alargan la cola de esa lentitud. Cada hilo
de plataforma reserva del orden de 1 MB de pila y, mientras espera, no hace nada.

**🔬 El detalle.** Lo primero que subo, cuando ya sé cuál es, es el **máximo por host** del
cliente saliente, porque ese número *es* el número de llamadas concurrentes al proveedor: una
decisión de capacidad. El pool de Hikari no lo toco sin mirar antes
`hikaricp.connections.usage`, que es **tiempo de retención**: la fórmula de HikariCP es
`conexiones ≈ (núcleos × 2) + spindles`, entre 8 y 12 en una máquina de 4 núcleos con SSD, y
subirlo a 100 hace competir 100 consultas por 4 núcleos. Y el `/health` sobrevive a todo esto
solo si vive en `management.server.port=8081`, con su propio conector.

---

### 25 → 16

> Te dan tres encargos: correlacionar peticiones con un `X-Request-Id`, registrar
> auditoría de negocio con el usuario autenticado, y unificar el formato de los errores.
> Reparte cada uno entre `Filter`, `HandlerInterceptor` y `@RestControllerAdvice`,
> justificando qué ve cada capa del `SecurityContext`. — [`08`
> §5](08-modelo-de-ejecucion-web.md#5--filtro-interceptor-o-advice) · [`20`
> §6](20-spring-security-el-mecanismo.md#6--securitycontextholder-un-threadlocal-y-sus-dos-fugas)
> · [`L03`
> §8](l03-api-rest-filtros-y-errores.md#8--la-excepción-del-filtro-el-interceptor-y-quién-corre-antes)

**⏱️ 30 segundos.** El `X-Request-Id` en un `Filter`, porque tiene que correr antes que todo y
puede envolver el request. La auditoría de negocio con el usuario autenticado en un
`HandlerInterceptor` o en el servicio, porque el `Filter` de correlación corre **antes** que la
cadena de Security y ahí el `SecurityContext` todavía está vacío. El formato de errores en el
`@RestControllerAdvice`.

**🗣️ 2 minutos.** La fila que decide el reparto es qué ve cada capa. Un `Filter` es de la API
de Servlet, corre fuera del `DispatcherServlet` y **no sabe qué handler atenderá**; si se
registra antes del `FilterChainProxy`, tampoco tiene identidad. Un `HandlerInterceptor` es de
Spring, corre con el handler ya resuelto —`handler instanceof HandlerMethod` te da la clase y
el método— y llega cuando Security ya llenó el `SecurityContextHolder`, así que es el sitio
natural para auditar "quién hizo qué sobre qué endpoint". El advice solo maneja lo que nace
**dentro** del `DispatcherServlet`. Y de ahí sale la regla que cierra la mitad de las
discusiones: **una excepción lanzada en un filtro no pasa por tu `@ControllerAdvice`**; sube al
contenedor de servlets y sale como HTML de Tomcat, con el mensaje de tu excepción expuesto en
la página. Un filtro no lanza: **un filtro escribe la respuesta él mismo** —construye el
`ProblemDetail`, pone `application/problem+json` y hace `return` sin `chain.doFilter`—.

**🔬 El detalle.** En el interceptor, el estado por petición va en `request.setAttribute(...)`
y no en un `ThreadLocal`: el atributo vive y muere con la petición y no hay nada que limpiar en
un `finally`. Y se usa `afterCompletion`, no `postHandle`, porque el segundo **se salta cuando
hay excepción** y las métricas escritas ahí pierden justo los casos de error. El precio del
filtro que responde solo es duplicar la construcción del `ProblemDetail` fuera del advice: es
real, y es el argumento honesto para mover la comprobación a un interceptor si no necesita
correr antes que Security.

---

### 25 → 17

> Un cliente se queja de que la API responde 500 a un parámetro de query inválido y 415
> donde él esperaba 400. Reconstruye qué excepción produjo cada respuesta y di qué hay
> que configurar para que las dos salgan como `ProblemDetail` con el mismo formato. —
> [`09` §8](09-rest-con-spring-mvc.md#8--406-415-y-400-tres-fallos-que-no-se-parecen) ·
> [`10`
> §3](10-diseno-de-api-validacion-errores-e-hipermedia.md#3--valid-vs-validated-y-qué-excepción-lanza-cada-caso)
> · [`A03`
> §5](a03-catalogo-de-errores-y-diagnostico.md#5-️-el-borde-web-el-código-de-estado-que-miente)

**⏱️ 30 segundos.** El 500 es una `ConstraintViolationException`: alguien puso `@Validated` en
la **clase** del controller. El 415 es `HttpMediaTypeNotSupportedException` y casi siempre es
que el cliente no mandó `Content-Type`. Se quita el `@Validated` de la clase —la corrección es
quitarlo, no añadir nada— y se pone `spring.mvc.problemdetails.enabled=true`.

**🗣️ 2 minutos.** El 500 es el caso que más me gusta explicar porque **lo causa la anotación
que creías que lo evitaba**. Desde Spring Framework 6.1, un controller valida por sí mismo las
restricciones que estén en la firma del método y lanza `HandlerMethodValidationException`, que
`DefaultHandlerExceptionResolver` mapea a 400. Poner `@Validated` en la clase no habilita esa
validación: la **degrada** al camino de AOP de `MethodValidationPostProcessor`, que lanza
`ConstraintViolationException` —de Jakarta, desconocida para MVC— y sale 500. La reference lo
pide con todas las letras: *"you need to remove the class level `@Validated` annotation from
the controller"*. Fuera del controller `@Validated` sigue siendo obligatoria, porque en un
`@Service` no hay MVC que valide por ti: solo hay proxy. El 415, en cambio, no es un bug tuyo:
el fallo ocurre en el `HandlerMapping`, antes de elegir converter, porque el `consumes`
descartó el handler como candidato.

**🔬 El detalle.** Para que **las dos** salgan con el mismo formato hacen falta dos cosas.
`spring.mvc.problemdetails.enabled=true` hace que `ResponseEntityExceptionHandler` produzca
`ProblemDetail` para las excepciones **de MVC** que ya conoce; con el default `false` ese 415
sale con el formato `/error` de Boot —`timestamp`, `status`, `error`, `path`—, que es JSON pero
no es `problem+json`. Y no afecta a tus excepciones de negocio: esas las traduces tú en el
advice. Cómo se confirma cuál fue: `logging.level.org.springframework.web=DEBUG` y buscar la
línea `Resolved [...]`; en el caso del 500 **no aparece ninguna**, y eso mismo es el
diagnóstico.

---

### 25 → 18

> El equipo serializa la entidad de JPA directamente como respuesta HTTP y defiende que
> un DTO es *boilerplate*. Da los tres daños concretos —de contrato, de runtime y de
> seguridad— y di cuál de los tres usarías para cerrar la discusión en una revisión. —
> [`09` §7](09-rest-con-spring-mvc.md#7--httpmessageconverter-y-jackson) · [`15`
> §7](15-datos-jdbc-jpa-mongo-y-redis.md#7-️-lazyinitializationexception-y-open-in-view)

**⏱️ 30 segundos.** Contrato: acoplas el esquema de la base a la API, y un `ALTER TABLE` pasa
a ser un cambio de contrato. Runtime: Jackson recorre los getters, toca una colección `LAZY`
fuera de sesión y aparece `LazyInitializationException`. Seguridad: **publicas campos que
nadie decidió publicar**. El tercero es el que cierra la discusión.

**🗣️ 2 minutos.** Y lo cierra porque los dos primeros son argumentos de diseño discutibles en
una mesa y el tercero es un hallazgo. En una entidad de banca hay columnas técnicas —`version`,
`created_by`— y a menudo campos que el negocio no quiere en el borde; el día que alguien añade
una columna al modelo, esa columna aparece en la respuesta HTTP sin que nadie lo haya revisado.
Eso no se discute en una revisión de código: se escala. Mi posición es que el DTO no es
boilerplate, es **la decisión explícita de qué se publica**, y su coste —un `record` y un
método de mapeo— es una fracción del de un campo filtrado. El argumento de runtime lo uso como
apoyo: es más corto hoy y más caro siempre, porque además mete el modelo de carga de JPA dentro
del serializador.

**🔬 El detalle.** El `record` inmutable se deserializa por el constructor canónico, sin
setters ni `@ConstructorProperties`, y `@JsonProperty` solo hace falta cuando el nombre JSON no
coincide con el del componente Java: el coste real de escribirlo es menor del que la gente
cree. Y hay una consecuencia que engancha con `15` §7: apagar `spring.jpa.open-in-view` hace
aparecer la `LazyInitializationException` **en el test de integración y no en producción**,
pero solo si devuelves DTO; serializando la entidad, la solución de muchos es volver a poner
`open-in-view: true`, y con eso se retiene la conexión del pool hasta el último byte de la
respuesta.

---

### 25 → 19

> Diseña la respuesta de error de una API de banca: qué campos lleva, qué información no
> puede aparecer nunca en el cuerpo, y por qué el 401 que devuelve Spring Security no
> pasa por tu `@RestControllerAdvice` ni adopta ese formato. — [`10`
> §5](10-diseno-de-api-validacion-errores-e-hipermedia.md#5--problemdetail-y-rfc-9457) ·
> [`20` §9](20-spring-security-el-mecanismo.md#9--401-frente-a-403-quién-los-escribe)

**⏱️ 30 segundos.** `ProblemDetail` de la RFC 9457: `type`, `title`, `status`, `detail`,
`instance` y extensiones. Nunca en el cuerpo: número de cuenta o tarjeta completos, saldos,
nombres, el mensaje crudo de una excepción o un stack trace. Y el 401 no pasa por el advice
porque lo escribe un `AuthenticationEntryPoint` **dentro de la cadena de filtros**, antes de
que exista un controller.

**🗣️ 2 minutos.** El campo que gobierna todo es `type`: un URI que identifica **la clase de
problema**, y por el que el cliente enruta. `title` es legible y estable por `type` —si metes
el `sku` en el `title` rompiste esa estabilidad—, `detail` es de esta ocurrencia concreta e
`instance` la identifica. Lo mío va en extensiones con `setProperty(...)`: el campo que falló,
el `traceId`. El `Content-Type` es `application/problem+json`, así que el cliente distingue un
error de una respuesta normal sin mirar el status. Sobre el 401: el que decide entre 401 y 403
es el **`ExceptionTranslationFilter`**, con una regla que conviene saber literal — si la
excepción es de autenticación **o el usuario no está autenticado**, va al entry point; si ya
estaba autenticado, va al `AccessDeniedHandler` y el 403 se queda 403. Para que ese 401 lleve
tu formato hay que registrar un `AuthenticationEntryPoint` y un `AccessDeniedHandler` propios;
no hay otra vía.

**🔬 El detalle.** Y hay una asimetría que desconcierta y que en banca importa: **la
`AccessDeniedException` de method security sí puede llegar a tu `@ControllerAdvice`**, porque
el proxy corre dentro del `DispatcherServlet`. Si declaraste
`@ExceptionHandler(AccessDeniedException.class)`, la atrapa él y Security no llega a verla; si
no, sube y el `ExceptionTranslationFilter` la traduce igual. La misma excepción, dos sitios,
según dónde se lanzó. Y un 403 sin log es peor que un 401: el 401 se diagnostica solo, el 403
tiene diez causas —prefijo `ROLE_`, cadena equivocada, contexto perdido en un `@Async`— y el
cuerpo llega vacío. La cura son las dos cosas juntas: `DEBUG` en
`org.springframework.security` y un `AccessDeniedHandler` que registre qué regla denegó y con
qué authorities.

---

### 25 → 20

> `POST /api/movements` mueve dinero y el cliente reintenta por timeout. Diseña la
> idempotencia: quién genera la clave, en qué punto respecto del commit se registra, qué
> devuelves si llega repetida con el mismo cuerpo y qué si llega con uno distinto. —
> [`10`
> §7](10-diseno-de-api-validacion-errores-e-hipermedia.md#7--idempotencia-el-mismo-post-dos-veces)
> · [`16`
> §8](16-transacciones.md#8--el-límite-de-la-transacción-no-es-el-límite-de-tu-método) ·
> [`19` §3](19-resiliencia.md#3--retry-cuándo-ayuda-y-cuándo-empeora-la-caída)

**⏱️ 30 segundos.** La clave **la genera el cliente**, una por intención de negocio y no por
reintento, y llega en `Idempotency-Key` sin `defaultValue`, para que falte sea un 400. Se
registra **en la misma transacción que el movimiento**, no antes ni después. Misma clave y
mismo cuerpo: devuelvo la respuesta original. Misma clave y cuerpo distinto: **409**.

**🗣️ 2 minutos.** Si la clave la genero yo no sirve de nada, porque el reintento traería otra
— ese es el primer error y el más común. El segundo es el punto del registro: si escribo la
clave antes del commit y la transacción se revierte, el segundo intento encuentra la clave y
devuelve una respuesta de un movimiento que no existe; si la escribo después del commit y el
proceso muere en medio, el reintento duplica el cargo. La única posición defendible ante un
auditor es que la fila de idempotencia y el movimiento se escriban **en la misma unidad
atómica**, y que la respuesta cacheada se guarde ahí mismo. Con eso, "el mismo POST dos veces"
tiene un resultado definido y demostrable con un `SELECT`. Y de ahí sale la regla que engancha
con el retry: reintentar solo es correcto si la operación es idempotente **o** tiene una clave
que el otro lado respeta. Un `POST` que mueve dinero sin esa clave no se reintenta nunca.

**🔬 El detalle.** El registro **crece con cada escritura**, no con cada error: sin TTL es un
keyspace que solo sube. Se fija una ventana —24 horas es lo habitual en banca— y se **declara
en el contrato**, porque un reintento fuera de esa ventana sí va a duplicar. Y la comparación
del cuerpo se hace sobre un hash del payload canónico, no sobre la cadena cruda: un cliente que
reordena campos JSON no debería recibir un 409. En el lab el store es Redis, con el TTL por
caché de `17` §6; en producción, si el registro tiene que sobrevivir a una caída de Redis, va
en la misma base que el movimiento — y esa es exactamente la razón por la que va ahí.

---

### 25 → 21

> Tienes que paginar una tabla de cuarenta millones de eventos. Compara `Page`, `Slice`
> y cursor por lo que cada uno ejecuta contra la base, di cuál eliges para una pantalla
> de "siguiente" y cuál para una exportación, y por qué no se devuelve un `Page` tal
> cual. — [`10`
> §9](10-diseno-de-api-validacion-errores-e-hipermedia.md#9--paginación-page-slice-y-cursor)
> · [`15`
> §4](15-datos-jdbc-jpa-mongo-y-redis.md#4--spring-data-el-repositorio-que-nadie-implementa)

**⏱️ 30 segundos.** `Page` ejecuta la consulta **más un `COUNT(*)`** sobre toda la tabla
filtrada; `Slice` pide `size+1` filas y solo contesta "¿hay siguiente?"; el cursor pide "los 20
siguientes con `sku` mayor que el último". Para una pantalla de "siguiente", `Slice`. Para una
exportación de cuarenta millones, **cursor**. Y `Page` no se devuelve tal cual nunca.

**🗣️ 2 minutos.** Con cuarenta millones de filas el `COUNT(*)` cuesta más que la página misma,
y el número que devuelve nadie lo mira: si la UI solo pinta "siguiente", `Slice` elimina la
mitad del trabajo de cada request. El cursor es para la exportación por una razón distinta y
más grave que el rendimiento: con offsets grandes la base descarta N filas antes de devolver
las tuyas, y **si alguien inserta mientras paginas, los elementos se repiten o se saltan**. En
una exportación contable eso no es lentitud, es un fichero incorrecto. El precio del cursor es
que no puedes saltar a la página 500 — en una exportación no lo necesitas, y en una pantalla de
catálogo sí, por eso no es la respuesta universal. Y sobre no exponer `Page`: su serialización
no es parte del contrato de Spring Data, cambió entre versiones y arrastra campos internos
—`pageable`, `sort`— que nadie documentó para consumo externo; Boot llega a avisarlo en el log.
Va un `record` propio.

**🔬 El detalle.** `Pageable` lo resuelve un argument resolver a partir de `?page=`, `?size=` y
`?sort=`; no lo construyes tú. `@PageableDefault(size = 20, sort = "sku")` fija el tamaño
cuando el cliente no lo manda, y el techo se pone **aparte** con
`spring.data.web.pageable.max-page-size`: sin él, un `?size=1000000` te trae el millón de filas
y ninguna validación lo detiene. `page.map(ItemResponse::from)` convierte el contenido sin
perder los metadatos. Y cualquier orden de cursor exige un criterio **estable y único**: si
`sku` no fuera único, habría que desempatar con el id.

---

### 25 → 22

> Un compañero envuelve el repositorio JPA en `Mono.fromCallable` para "hacer reactivo"
> el servicio. Di en qué `Scheduler` tiene que correr eso, qué sigue limitando la
> concurrencia real, y qué le pasa al `traceId` que venías propagando por MDC. — [`11`
> §5](11-webflux-y-reactor.md#5--schedulers-y-la-regla-de-oro) · [`11`
> §7](11-webflux-y-reactor.md#7--el-contexto-reactivo-context-y-contextview) · [`23`
> §10](23-actuator-y-observabilidad.md#10--trazas-traceid-spanid-w3c-y-sampling)

**⏱️ 30 segundos.** En `Schedulers.boundedElastic()`, que es la salida de emergencia oficial
para envolver lo bloqueante que no puedes evitar. Lo que sigue limitando es el **pool de
Hikari**: `Mono.fromCallable` no convierte JDBC en no bloqueante, solo lo mueve de hilo. Y el
`traceId` del MDC **se pierde** al cambiar de hilo.

**🗣️ 2 minutos.** Se lo digo con esas palabras porque el error de fondo es creer que "hacer
reactivo" es envolver. Si el repositorio son 10 conexiones, la concurrencia real sigue siendo
10 con o sin `Mono`; lo único que cambia es que ahora el que espera es un hilo de
`boundedElastic` —acotado por defecto a 10 × cores— en vez de uno de Tomcat. No se ganó
capacidad, se movió la cola. Lo que sí puede perderse es mucho: si por descuido eso corre en
`Schedulers.parallel()`, que es un pool fijo del tamaño del número de cores para trabajo
CPU-bound, bloquear ahí es tan malo como bloquear el event loop. Y con ocho hilos de event
loop, **ocho peticiones bloqueadas dejan el servicio sin atender nada**, incluido
`/actuator/health`. Mi posición: si el acceso a datos es bloqueante, el endpoint no gana nada
siendo reactivo y sí pierde legibilidad y trazabilidad; o se va a un driver reactivo de verdad,
o se queda imperativo.

**🔬 El detalle.** En WebFlux el `ThreadLocal` no vale porque una misma petición cruza varios
hilos, y lo peor es que **a veces coincide y la prueba pasa**. El sustituto es el `Context` de
Reactor, un mapa inmutable que viaja con la suscripción y que se propaga **de abajo hacia
arriba**: solo lo ven los operadores por encima del `contextWrite`, y se lee con
`Mono.deferContextual`. Para el MDC concreto, el puente es `context-propagation` de Micrometer
—que Boot 3.5 trae— habilitado con `Hooks.enableAutomaticContextPropagation()`. Y el bloqueo
que no avisa se caza con BlockHound, **solo en el perfil `test`**: `Mono.block()` sí lanza
`IllegalStateException`, pero un `jdbcTemplate.query(...)` no lanza nada.

---

### 25 → 23

> Activas `spring.threads.virtual.enabled=true` en un servicio MVC que tiene Hikari en
> 10 y un executor de `@Async` con ocho hilos. Enumera qué cambia, qué no cambia, y
> nombra el fallo de *pinning* con la construcción de Java 21 que lo provoca. — [`12`
> §4](12-reactivo-bloqueante-y-virtual-threads.md#4--lo-que-los-virtual-threads-no-arreglan)
> · [`18`
> §4](18-asincronia-scheduling-y-eventos.md#4-️-el-executor-los-tres-números-y-la-cola-traicionera)
> · [`15` §2](15-datos-jdbc-jpa-mongo-y-redis.md#2--el-datasource-y-hikaricp)

**⏱️ 30 segundos.** Cambia el executor de `@Async`, que pasa a ser un
`SimpleAsyncTaskExecutor` con un hilo virtual por tarea: desaparecen los tres números y la
cola. **No cambia** el pool de Hikari: la concurrencia real sigue siendo 10. Y el fallo es el
*pinning* por `synchronized`: en Java 21 un hilo virtual bloqueado dentro de un bloque
`synchronized` **no se desmonta** y retiene su carrier thread.

**🗣️ 2 minutos.** Lo que hay que decir en la mesa es lo que **desaparece**, porque suena a
mejora y es una pérdida de control: los tres números del `ThreadPoolTaskExecutor` —`core-size`,
`max-size`, `queue-capacity`— son el límite que te protegía, y con virtual threads ya no hay
pool ni cola, así que el control se muda al bulkhead. Con ocho hilos de `@Async` tenías un
techo de ocho tareas simultáneas; ahora no tienes ninguno, y si cada tarea toca la base, lo que
consigues es una cola más larga contra las mismas diez conexiones. El pinning es la otra mitad:
con suficientes hilos virtuales bloqueados dentro de `synchronized` agotas los portadores y el
servicio se para de una forma difícil de diagnosticar; la solución es `ReentrantLock` en las
rutas que bloquean. Tampoco ayudan con CPU: mil hilos virtuales compitiendo por ocho núcleos
solo añaden cambios de contexto.

**🔬 El detalle.** El pinning por `synchronized` se corrigió en **Java 24, con JEP 491**: desde
ahí un hilo virtual bloqueado dentro de un `synchronized` ya no clava su carrier. El curso fija
Java 21, así que el aviso aplica entero — y en una entrevista conviene decir la versión al dar
el argumento, porque sobre 24 el del `ReentrantLock` deja de ser obligatorio. Otro efecto fino:
`ThreadLocal` sigue funcionando, pero **el hilo ya no se reutiliza**, así que los patrones de
caché por hilo —buffers reutilizables— dejan de tener sentido y consumen más.

---

### 25 → 24

> Ningún cliente HTTP del curso trae timeout de lectura por defecto. Enumera los tres
> techos que hacen falta para acotar de verdad una llamada saliente, di cuál de ellos no
> se configura en la `ClientHttpRequestFactory`, y con qué pieza se pone. — [`13`
> §2](13-clientes-http.md#2-️-no-hay-timeout-por-defecto-y-ese-es-el-tema) · [`13`
> §4](13-clientes-http.md#4--la-clienthttprequestfactory-timeouts-y-pool) · [`19`
> §2](19-resiliencia.md#2--el-timeout-es-el-primero-y-sin-él-nada-más-sirve)

**⏱️ 30 segundos.** `connect-timeout`, `read-timeout` y un techo para **la llamada entera**. El
tercero no se configura en la `ClientHttpRequestFactory`: lo pone el `TimeLimiter` de
Resilience4j. Y sin ninguno de los tres, el resto de los patrones es decoración.

**🗣️ 2 minutos.** La razón de que hagan falta tres es que el `read-timeout` **es un techo por
lectura, no por llamada**: una respuesta que gotea cada 2,9 segundos con un `read-timeout` de
3 s no lo dispara nunca y te retiene el hilo indefinidamente. Ese es el caso que la gente no
ve. El `connect-timeout` cubre el handshake TCP y TLS —host inexistente, puerto cerrado, un
firewall que se come los paquetes— y hace que ese fallo sea rápido y uniforme. Y los defaults
son el argumento definitivo para escribirlos: el `HttpClient` del JDK **no impone ninguno**, ni
de conexión ni de lectura, y Apache HttpClient 5 impone tres minutos de conexión y **ninguno**
de lectura. Es decir, por defecto, en las dos, una respuesta que nunca llega te retiene el hilo
para siempre. Nunca respondo "el timeout por defecto es razonable": el default es esperar para
siempre, y ese valor lo pone quien escribe el cliente.

**🔬 El detalle.** Las tres propiedades de Boot 3.5 son `spring.http.client.connect-timeout`,
`...read-timeout` y, de propina, `...redirects: dont-follow`, que evita que un `302` del
proveedor te lleve a un host que nadie autorizó. El cuarto techo que no es un timeout y que
importa igual es el **pool**, que no se configura con propiedades porque es de la librería: 25
conexiones totales y 5 por host en HC5, y la excepción que sale es
`ConnectionRequestTimeoutException` tras el *connection request timeout*, tres minutos por
defecto — así que el primer síntoma no es el error, es la espera. Y esto engancha con
transacciones: `16` §8 prohíbe llamar a un proveedor dentro de una transacción precisamente
porque ahí retienes también la conexión a la base durante los mismos treinta segundos.

---

### 25 → 25

> Da el veredicto del curso sobre los cinco clientes HTTP en una frase por cada uno, y
> después defiende el caso contrario: en qué situación concreta de un banco seguirías
> eligiendo Feign sabiendo lo que sabes. — [`13`
> §9](13-clientes-http.md#9--los-cinco-y-el-veredicto) · [`01`
> §9](01-spring-boot-y-el-ecosistema.md#9--el-mapa-del-ecosistema)

**⏱️ 30 segundos.** `RestClient`: el default de todo código nuevo. `WebClient`: WebFlux o
llamadas en paralelo. `RestTemplate`: código existente que no vas a tocar —en mantenimiento
desde Spring 5.0, **sin `@Deprecated`**—. HTTP Interfaces: muchos endpoints del mismo
proveedor. Feign: lo que ya está escrito en tu banco.

**🗣️ 2 minutos.** El caso contrario existe y es honesto: **seguiría eligiendo Feign en un
banco donde ya hay treinta servicios con Feign y una plataforma de Spring Cloud montada
alrededor**. El argumento no es técnico, es de coste total: con Feign vienen el `ErrorDecoder`
común, la configuración por cliente, las convenciones de nombres y de reintentos, y media
docena de librerías internas que asumen ese modelo. Introducir `RestClient` en un servicio
nuevo dentro de ese entorno significa reescribir el `ErrorDecoder` como `onStatus`, duplicar la
configuración de timeouts en otro sitio y romper la homogeneidad que hace que un incidente se
diagnostique igual en los treinta. Lo que pago es que Spring Cloud OpenFeign está en
mantenimiento y que OpenFeign ni siquiera es de Spring —es de la CNCF—, así que la deuda tiene
fecha aunque no tenga día. La decisión que defiendo es la mixta: Feign donde ya está,
`RestClient` en los servicios nuevos que no dependen de esa plataforma, y la migración tratada
como un proyecto con dueño y no como una preferencia de estilo.

**🔬 El detalle.** Dos matices que valen en la mesa. **`WebClient` en una aplicación MVC es
legítimo**: disparas tres llamadas en paralelo y esperas con `block()`, así que el hilo del
request sigue bloqueado — no te volviste reactivo, ganaste concurrencia en el fan-out. Y
**`RestClient` no es "`RestTemplate` con builder"**: su API es la de `WebClient`, y por eso
pasar de uno al otro es casi mecánico y desde `RestTemplate` no lo es. Resilience4j tampoco es
de Spring; lo que Spring aporta es la integración, no la librería.

---

### 25 → 26

> Migras un endpoint de MVC a WebFlux y te llevas el `Filter` que ponía el
> `X-Request-Id`. Di qué tienes que cambiar, qué le pasa al `SecurityContext` y por qué
> leer el cuerpo ahí duele más que en el mundo servlet. — [`11`
> §6](11-webflux-y-reactor.md#6--el-stack-netty-webfilter-y-los-dos-estilos-de-endpoint)
> · [`08` §6](08-modelo-de-ejecucion-web.md#6-️-leer-el-cuerpo-en-un-filtro-lo-destruye)

**⏱️ 30 segundos.** El `Filter` de Servlet no existe en WebFlux: se reescribe como `WebFilter`,
que recibe un `ServerWebExchange` y devuelve `Mono<Void>`. El `SecurityContext` deja de vivir en
un `ThreadLocal` y pasa al `Context` de la suscripción, con `ReactiveSecurityContextHolder`. Y
el cuerpo duele más porque no es un `InputStream` que puedas envolver: es un flujo de
`DataBuffer` con gestión de memoria propia.

**🗣️ 2 minutos.** La primera trampa es de fontanería: si dejas a la vez
`spring-boot-starter-web` y `spring-boot-starter-webflux`, Boot arranca **Tomcat**, no Netty,
porque MVC gana el desempate en la autoconfiguración — y ahí tienes el clásico "configuré
WebFlux y sigo viendo hilos `http-nio-8080-exec-*`". La segunda es estructural: en un
`WebFilter` lo que quieras hacer "después" va **dentro de un operador**, no debajo de la línea,
porque la línea de abajo se ejecuta en la fase de ensamblado y no cuando la petición termina.
Lo tercero es que el scope `request` desaparece: el modelo reactivo no ata el trabajo a un
hilo, así que no hay dónde colgarlo, y esa es una de las diferencias que más duele al migrar y
que casi nunca se menciona.

**🔬 El detalle.** En el mundo servlet leer el cuerpo en un filtro **lo destruye**: es un
`InputStream` de un solo uso y el síntoma es `HttpMessageNotReadableException: Required request
body is missing`. Se arregla con `ContentCachingRequestWrapper`, pasando **el wrapper** a
`chain.doFilter`, y con el log en el `finally`, porque antes de `doFilter` el array está vacío;
el coste es duplicar el payload en memoria por petición en vuelo. En WebFlux no hay wrapper
equivalente con la misma facilidad: hay que consumir el `Flux<DataBuffer>`, quedarte con los
bytes y **reinyectarlos** en un `ServerHttpRequestDecorator`, cuidando el `release()` de los
buffers. Es el mismo problema con la carga de la gestión manual de memoria encima.

---

### 25 → 27

> El servicio va lento y el equipo propone subir el pool de Hikari de 10 a 50. Di qué
> métrica y qué endpoint consultas antes de aceptar, y nombra las dos causas del curso
> en las que subir el pool empeora el problema en vez de resolverlo. — [`15`
> §2](15-datos-jdbc-jpa-mongo-y-redis.md#2--el-datasource-y-hikaricp) · [`16`
> §7](16-transacciones.md#7--los-seis-silencios) · [`L04`
> §7](l04-datos-y-transacciones.md#7-️-requires_new-y-el-deadlock-de-pool)

**⏱️ 30 segundos.** No acepto sin dos datos: `hikaricp.connections.pending` en
`/actuator/metrics` —hilos esperando conexión— y sobre todo `hikaricp.connections.usage`, que
es **tiempo de retención**. Las dos causas en que subir el pool empeora: una transacción que
abarca una llamada HTTP, y un `REQUIRES_NEW` anidado que necesita **dos** conexiones por
petición.

**🗣️ 2 minutos.** El razonamiento que pongo encima de la mesa es este: si un request retiene su
conexión 800 ms para 20 ms de consulta, el problema no es el tamaño del pool, es lo que hace el
método con la conexión abierta, y subir el pool solo mueve la cola de mi aplicación a la base.
Con el `REQUIRES_NEW` anidado la aritmética es demoledora y hay que decirla: con
`maximum-pool-size = N`, un método que necesita dos conexiones simultáneas se bloquea en cuanto
hay **N peticiones concurrentes** por ese camino; las N toman su primera conexión y ninguna
consigue la segunda. Subir de 10 a 50 no arregla eso, solo desplaza el umbral de 10 peticiones
concurrentes a 50, y encima hace que 50 consultas compitan por cuatro núcleos. La fórmula de
HikariCP es `conexiones ≈ (núcleos × 2) + spindles`: entre 8 y 12 en una máquina de 4 núcleos
con SSD. La regla que sí se aplica es `pool ≥ concurrencia × conexiones por request`, y el
camino es bajar el segundo factor a uno.

**🔬 El detalle.** El síntoma literal que hay que reconocer de memoria es
`SQLTransientConnectionException: HikariPool-1 - Connection is not available, request timed out
after 3000ms.`, y `Transient` ahí es una mentira: en un deadlock de pool, reintentar consume
otra conexión y empeora el problema. La evidencia que cambia el diagnóstico está del otro lado:
`SELECT state, count(*) FROM pg_stat_activity` devuelve `idle in transaction` con CPU de
Postgres al 0 % — **el recurso agotado es tuyo, no suyo**. Y del lado de Hikari, con
`com.zaxxer.hikari.pool.HikariPool` en `DEBUG`, la línea `Pool stats (total=2, active=2,
idle=0, waiting=6)` cierra el caso. `leak-detection-threshold: 20000` no cierra nada: escribe un
`WARN` con el stack trace de quien retuvo la conexión, y te da el nombre del método culpable.

---

### 25 → 28

> Apagas `spring.jpa.open-in-view` y aparecen `LazyInitializationException` en tres
> endpoints que funcionaban. Explica qué te está diciendo eso sobre el diseño de esos
> endpoints y ordena las tres correcciones posibles de mejor a peor, con el criterio. —
> [`15`
> §7](15-datos-jdbc-jpa-mongo-y-redis.md#7-️-lazyinitializationexception-y-open-in-view)
> · [`15`
> §6](15-datos-jdbc-jpa-mongo-y-redis.md#6-️-n1-una-consulta-que-se-convierte-en-doscientas)

**⏱️ 30 segundos.** Te está diciendo que esos tres endpoints **decidían qué cargar en el
serializador**, no en el servicio. De mejor a peor: traer lo necesario con `@EntityGraph` o una
proyección y devolver DTO; un `JOIN FETCH` a mano en un `@Query`; y volver a `open-in-view:
true`, que no es una corrección sino tapar el agujero.

**🗣️ 2 minutos.** El criterio que ordena las tres es dónde queda la decisión de carga.
`@EntityGraph(attributePaths = "warehouse")` la pone en el método del repositorio, declarada y
revisable, nombrando propiedades y admitiendo rutas anidadas; es la que prefiero porque no
duplica la consulta ni escribe el `JOIN`. El `JOIN FETCH` es lo mismo escrito a mano para una
consulta concreta, y baja un escalón porque sobre dos colecciones a la vez produce un producto
cartesiano. Volver a `true` es lo peor por una razón que suele quedar fuera de la conversación:
con `open-in-view` activo, la sesión se mantiene abierta durante todo el request, así que
**retienes la conexión del pool hasta el último byte de la respuesta**, no hasta el commit, y
las consultas que dispare la serialización corren **fuera de transacción**, cada una en su
autocommit — el endpoint puede devolver un estado que nunca existió en la base. Apagarlo no
arregla el N+1: **lo hace visible**, y esa es exactamente la ganancia.

**🔬 El detalle.** `@BatchSize(size = 20)` es la cuarta opción y no elimina los N `SELECT`: los
agrupa en `N/20` con un `IN (...)`. Es la red de seguridad para colecciones que siempre se
recorren, no la corrección. Y `FetchType.EAGER` en el mapeo **no** es solución: mueve el
problema, porque ahora todas las consultas cargan la asociación, incluida la que no la
necesita. El default de `@ManyToOne` es `EAGER` por especificación y ponerlo `LAZY` es casi
siempre correcto. Para medir: `org.hibernate.SQL` en `DEBUG` —por el logger, con `traceId`, no
el `show-sql` que escribe a `stdout`— y `hibernate.generate_statistics: true`, que al cerrar la
sesión dice cuántas sentencias hubo.

---

### 25 → 29

> Hay que añadir una columna a `inventory_item` en una release regulada. Di quién aplica
> el cambio de esquema y por qué no Hibernate, qué hace Flyway al arrancar si alguien
> editó un script ya aplicado, y qué exige todo eso del pipeline de CI/CD. — [`15`
> §9](15-datos-jdbc-jpa-mongo-y-redis.md#9--flyway-y-por-qué-el-esquema-no-lo-genera-hibernate)
> · [`L04` §2](l04-datos-y-transacciones.md#2--postgres-en-compose-flyway-y-el-teardown)

**⏱️ 30 segundos.** El cambio lo aplica **Flyway**, con un `V2__` nuevo. Hibernate no, por tres
razones: `ddl-auto=update` solo **añade** —nunca borra, renombra ni cambia un tipo—, no se puede
revisar antes, y no deja registro de qué corrió; y en banca la cuenta de la aplicación no tiene
permisos de DDL. Si alguien editó un script ya aplicado, el arranque **falla** con
`Migration checksum mismatch`.

**🗣️ 2 minutos.** Ese fallo no es un bug: es el contrato, y ante un auditor es justo lo que
quieres poder enseñar. Flyway registra en `flyway_schema_history` qué migración corrió, cuándo,
cuánto tardó y con qué **checksum**; una migración aplicada es inmutable y lo que se corrige se
corrige con **otra** migración. Eso tiene tres consecuencias sobre el pipeline y conviene
decirlas antes de que las descubra alguien en una ventana nocturna. Una: el script se revisa
como código, en el mismo merge request que la entidad, porque el `V2__` y el campo nuevo tienen
que llegar juntos. Dos: `ddl-auto` se queda en `validate`, que es la pareja natural de Flyway —
Flyway crea el esquema, Hibernate comprueba que las entidades encajan y **rompe el arranque si
no**, sin tocar una tabla. Tres: la migración tiene que ser compatible hacia atrás si el
despliegue es progresivo, porque durante unos minutos conviven la versión vieja y la nueva
contra el mismo esquema: se añade la columna como nullable primero y se rellena después.

**🔬 El detalle.** El nombre del fichero es documentación y no un identificador cualquiera:
`V1__create_inventory_schema.sql` —`V`, versión, **doble guion bajo**, descripción—, y con un
solo guion bajo Flyway no reconoce el fichero. El orden lo da la versión, no el orden
alfabético. `R__` es repetible y se reejecuta al cambiar; `baseline-on-migrate` adopta Flyway
sobre una base viva. Y un detalle de dependencias que cuesta una ventana:
**`flyway-database-postgresql` es un artefacto aparte desde Flyway 10**, y sin él el arranque
falla con `Unsupported Database: PostgreSQL 17.11` aunque `flyway-core` esté presente.
`/actuator/flyway` lista lo aplicado.

---

### 25 → 30

> Te dan a elegir entre `JdbcClient`, un repositorio derivado de Spring Data JPA y una
> consulta a Mongo para tres casos: un informe de conciliación con cinco joins, el alta
> de un movimiento, y una proyección de solo lectura. Asigna y justifica cada uno. —
> [`15`
> §3](15-datos-jdbc-jpa-mongo-y-redis.md#3--jdbcclient-y-la-jerarquía-de-dataaccessexception)
> · [`15`
> §8](15-datos-jdbc-jpa-mongo-y-redis.md#8--mongo-y-redis-qué-te-da-spring-data-y-cuál-es-la-trampa)

**⏱️ 30 segundos.** Informe de conciliación con cinco joins: **`JdbcClient`**, porque ahí el
SQL es el producto. Alta de un movimiento: **repositorio de Spring Data JPA**, porque lo que
importa es el grafo de objetos y su ciclo de vida. Proyección de solo lectura: **Mongo** si el
documento ya es la unidad de lectura; si no, una proyección a `record` en JPA.

**🗣️ 2 minutos.** El criterio es uno solo y lo digo así: *¿el producto es el SQL o es el
objeto?* Un informe con cinco joins que revisó un DBA no se deja generar por nadie; con
`JdbcClient` escribes la consulta, la pasas con parámetros nombrados —`.param(...)`, que produce
un `PreparedStatement` y hace imposible la inyección— y la mapeas a un `record` con
`.query(StockLine.class)`. El alta del movimiento es lo contrario: entidad, `@Version`,
transacción, dirty checking. Para la proyección de solo lectura tomo posición con un matiz:
**Mongo gana cuando el documento es la unidad de lectura y escritura** —un snapshot, un payload
heterogéneo—, y es JPA disfrazado si modelas tres colecciones y las cruzas a mano en el
servicio. Si la proyección sale de las mismas tablas que ya tienes, no monto un store nuevo por
ella: un `@Query` con `select new ...SkuQuantity(...)` trae dos columnas y no la fila entera.

**🔬 El detalle.** La jerarquía `DataAccessException` es la que hace que los tres convivan sin
acoplarte al motor: el driver habla `SQLState` —`23505` en Postgres, `ORA-00001` en Oracle— y
capturar eso casa tu servicio con la base; Spring lo traduce a excepciones **no chequeadas**, y
que lo sean es deliberado, porque el rollback por defecto se dispara con `RuntimeException` y no
con una chequeada. `DuplicateKeyException` es tu 409, `CannotAcquireLockException` es un
deadlock reintentable y `OptimisticLockingFailureException` sale de `@Version`. La trampa de
Mongo: **Boot no crea los índices por ti** —`spring.data.mongodb.auto-index-creation` es `false`
desde Spring Data MongoDB 3.0—, así que un `findBySku` sin índice es un scan completo.

---

### 25 → 31

> Un desarrollador junior te enseña un método `@Transactional` que no hizo rollback y
> jura que "la anotación está puesta". Explícale la causa en sesenta segundos cubriendo
> las tres razones posibles, ordenadas por frecuencia real. — [`16`
> §6](16-transacciones.md#6-️-rollback-la-regla-que-casi-todo-el-mundo-dice-mal) · [`05`
> §5](05-proxies-y-aop.md#5-️-self-invocation-el-fallo-silencioso-número-uno)

**⏱️ 30 segundos.** Tres, por frecuencia real: la llamada vino **desde la propia clase** y no
pasó por el proxy; alguien **capturó la excepción** dentro del método y el proxy nunca la vio;
o la excepción es **comprobada**, y por defecto Spring solo revierte ante `RuntimeException` y
`Error`. Las tres son silenciosas: compila, corre y confirma.

**🗣️ 2 minutos.** A un junior se lo cuento en ese orden porque es el orden en que se lo va a
encontrar. La primera es la self-invocation: el proxy envuelve al objeto **desde fuera**, y en
cuanto la ejecución entra en tu clase, `this` es el objeto real y la anotación es un comentario.
La segunda es la que más duele porque parece defensiva: un `try { … } catch (Exception e) {
log.error(...); }` dentro del método transaccional hace que para el proxy todo haya salido bien.
**Commit.** La tercera es la regla que casi todo el mundo dice mal: una `IOException` al enviar
una notificación **confirma** la transacción, y se arregla con `rollbackFor = Exception.class`.
Y le doy la versión cruel de la segunda, porque se la va a encontrar: si captura una excepción
lanzada después de que una transacción interna se marcara `rollback-only`, el commit final falla
con `UnexpectedRollbackException: Transaction silently rolled back because it has been marked as
rollback-only` — y el mensaje aparece en el método de fuera, que no hizo nada malo.

**🔬 El detalle.** Y termino dándole el comando, porque una hipótesis que se confirma en treinta
segundos vale más que una explicación: `logging.level.org.springframework.transaction.interceptor=TRACE`.
Si el interceptor corrió, el log imprime `Getting transaction for [com.invlab...record]` antes
del método y `Completing transaction for` después; si esas líneas no aparecen, no hubo
transacción y la causa es la primera de las tres. Hay una cuarta menos frecuente y muy fina:
**importar `jakarta.transaction.Transactional`** en vez del de Spring. La transacción sí abre
—Spring respeta el de Jakarta—, pero se pierden `readOnly`, `isolation` y `timeout`, y te
enteras cuando el compilador rechaza el atributo que ibas a añadir.

---

### 25 → 32

> Quieren `REQUIRES_NEW` para que la auditoría se guarde aunque el negocio falle.
> Explica cuántas conexiones consume eso por petición, por qué es la receta del deadlock
> de pool, y cuál es la alternativa que enseña el curso para el mismo requisito. — [`16`
> §4](16-transacciones.md#4--propagación) · [`18`
> §9](18-asincronia-scheduling-y-eventos.md#9--el-evento-que-espera-al-commit) · [`L04`
> §7](l04-datos-y-transacciones.md#7-️-requires_new-y-el-deadlock-de-pool)

**⏱️ 30 segundos.** **Dos** conexiones a la vez: suspender no libera la conexión de fuera, la
retiene mientras la interna corre con otra. Con `pool = N`, N peticiones concurrentes por ese
camino toman su primera conexión y ninguna consigue la segunda: deadlock por agotamiento, sin
un solo `LOCK` de base de datos. La alternativa del curso es **auditar fuera del límite
transaccional**, secuencialmente.

**🗣️ 2 minutos.** La primera pregunta que hago no es técnica: *¿de verdad tiene que sobrevivir
al rollback?* En la mitad de los casos "auditar el intento" se resuelve con un log estructurado
y no con una fila en la misma base que estamos intentando no escribir; si la respuesta es no,
`REQUIRED` y el problema desaparece. Si la respuesta es sí, el arreglo es **secuencial, no
anidado**: un método orquestador sin anotar llama primero a `audit.recordAttempt(...)`, que abre,
confirma y **suelta** su conexión, y solo entonces llama al método de negocio. Las dos
transacciones siguen existiendo, una detrás de otra, y la regla vuelve a `pool ≥ concurrencia ×
1`. El precio que pago y que digo en voz alta: audito el intento **antes** de saber si el item
existe — que para una auditoría de *intentos* es exactamente lo que se quería. Dimensionar el
pool a `concurrencia × 2` es el tercer nivel y solo si los dos anteriores no aplican.

**🔬 El detalle.** Hay un arreglo que circula y que **no** arregla el pool: mover la auditoría a
un `@TransactionalEventListener(AFTER_COMMIT)` con `REQUIRES_NEW`. Corrige la semántica y no el
consumo: `AbstractPlatformTransactionManager.processCommit` dispara el listener en
`triggerAfterCompletion`, y la conexión de la transacción original solo se suelta en
`cleanupAfterCompletion`, que corre **después**, en el `finally`. El javadoc lo dice sin
rodeos: *"the transactional resources might still be active and accessible… Use
`PROPAGATION_REQUIRES_NEW` for any transactional operation that is called from here"*. Lo que sí
rompe la cadena es sacar el efecto **del hilo** —un listener `@Async`— o un outbox. Y la regla
de revisión que dejo escrita: ningún `REQUIRES_NEW` entra sin que su autor diga cuántas
conexiones consume el request completo.

---

### 25 → 33

> El caso es escribir en la base y publicar un mensaje, y tiene que ser todo o nada. Di
> por qué el curso desaconseja XA, qué garantiza exactamente
> `@TransactionalEventListener(AFTER_COMMIT)`, qué hueco deja abierto y qué patrón lo
> cubre. — [`16` §9](16-transacciones.md#9--cuando-la-transacción-cruza-dos-sistemas) ·
> [`18` §9](18-asincronia-scheduling-y-eventos.md#9--el-evento-que-espera-al-commit)

**⏱️ 30 segundos.** XA porque Boot no lo trae activado, exige un coordinador, añade latencia,
es un punto único de fallo y deja estado que hay que recuperar tras una caída.
`AFTER_COMMIT` garantiza que el listener **solo corre si la transacción confirmó**. El hueco:
si el proceso muere entre el commit y el listener, **el evento se pierde**. Lo cubre el
**outbox**.

**🗣️ 2 minutos.** El orden de la respuesta importa porque el error clásico es publicar dentro
de la transacción: entonces el aviso sale y el dato se revierte, que es el peor fallo posible.
`AFTER_COMMIT` mueve el efecto al otro lado del commit y resuelve eso entero; lo que no resuelve
es la atomicidad entre el commit y la publicación, porque entre los dos no hay ninguna garantía.
En banca eso importa: un movimiento confirmado cuyo evento nunca salió es una diferencia que
aparece en la conciliación de la noche. El outbox lo cierra escribiendo el evento **en la misma
transacción** que el dato —una fila en una tabla `outbox`— y publicándolo aparte, con un proceso
que lee y marca. Se paga con entrega **al menos una vez**, así que el consumidor tiene que ser
idempotente; ese es el intercambio y hay que nombrarlo. Y la respuesta de entrevista que gana
por encima de todo esto: antes de coordinar dos sistemas, preguntarse si el límite entre ellos
está bien puesto. Muchas transacciones distribuidas son un servicio mal partido.

**🔬 El detalle.** Dos cosas del listener que se preguntan. La primera: **corre en el mismo hilo
y fuera de la transacción**, así que si escribe en la base necesita la suya propia
(`REQUIRES_NEW`) o no se guarda nada — y ahí también hay dos conexiones a la vez, porque la
original todavía no volvió al pool. La segunda: **sin transacción activa el listener no se
ejecuta en absoluto**, ni excepción ni warning, así que un test que publica el evento fuera de
una transacción "pasa" sin haber probado nada; `fallbackExecution = true` es lo que lo salva.
Las otras fases son `BEFORE_COMMIT` —que aún puede vetar el commit—, `AFTER_ROLLBACK` y
`AFTER_COMPLETION`.

---

### 25 → 34

> Dos peticiones ajustan a la vez el stock del mismo SKU. Di qué ves con el aislamiento
> por defecto de Postgres, por qué subir a `SERIALIZABLE` no es la respuesta habitual, y
> qué mecanismo se usa en su lugar y qué excepción hay que estar dispuesto a reintentar.
> — [`16` §5](16-transacciones.md#5--aislamiento) · [`19`
> §3](19-resiliencia.md#3--retry-cuándo-ayuda-y-cuándo-empeora-la-caída)

**⏱️ 30 segundos.** Con el `READ_COMMITTED` de Postgres ves una **lost update**: las dos leen
55, las dos escriben 54 y un ajuste desaparece. `SERIALIZABLE` no es la respuesta habitual
porque sube la contención y la probabilidad de deadlock en todo el sistema. La respuesta es
**optimistic locking** con `@Version`, y la excepción a reintentar es
`OptimisticLockingFailureException`.

**🗣️ 2 minutos.** Elijo optimista y digo por qué y qué pago. Falla rápido y **no bloquea**: el
`UPDATE ... WHERE version = ?` afecta a cero filas, Hibernate lo detecta y lanza; la transacción
perdedora se reintenta y listo. Lo que pago es que el reintento es responsabilidad mía y tiene
que estar escrito —no basta con poner la columna—, y que con contención alta sobre el mismo SKU
el optimista degrada: si cada segundo reintento vuelve a chocar, ahí sí toca pesimista con un
`SELECT ... FOR UPDATE`. `SERIALIZABLE` se justifica, no es un default prudente: más bloqueos,
más contención y más deadlocks, y en Postgres lo que aparece es `could not serialize access due
to concurrent update`, que **también** hay que estar dispuesto a reintentar — así que ni
siquiera te ahorra el código de reintento.

**🔬 El detalle.** La tabla ANSI de niveles es un contrato de mínimos y Postgres no la cumple al
pie de la letra; lo que te da de verdad lo dice la documentación de tu motor, y hay dos
desviaciones que se preguntan. `READ_UNCOMMITTED` **se comporta como `READ_COMMITTED`**, porque
el MVCC nunca enseña una versión sin confirmar. Y `REPEATABLE_READ` es **snapshot isolation**,
así que además de las lecturas no repetibles evita también los phantom reads que la tabla marca
como posibles. `Isolation.DEFAULT` significa "el de la base", no uno concreto: Postgres y Oracle
usan `READ_COMMITTED`, MySQL con InnoDB usa `REPEATABLE_READ`, y el mismo código se comporta
distinto al cambiar de motor.

---

### 25 → 35

> Te encuentras `@Transactional` en un controller. Enumera todo lo que acaba de quedar
> dentro de esa transacción que no debería estar, di cuánto tiempo retiene la conexión
> en el peor caso, y dónde va el límite correcto. — [`16`
> §8](16-transacciones.md#8--el-límite-de-la-transacción-no-es-el-límite-de-tu-método) ·
> [`09` §7](09-rest-con-spring-mvc.md#7--httpmessageconverter-y-jackson)

**⏱️ 30 segundos.** Entran la deserialización del cuerpo, la validación, toda la lógica del
servicio y —lo peor— **la serialización de la respuesta**, que ocurre en el hilo del request. En
el peor caso la conexión se retiene hasta el último byte enviado al cliente. El límite correcto
es el método de servicio que representa la unidad de negocio.

**🗣️ 2 minutos.** El daño concreto: Jackson escribe a un buffer en memoria antes de enviar nada,
así que una lista de 50 000 elementos son decenas de MB retenidos y cientos de milisegundos de
CPU **con la conexión de la base tomada**. Si además el controller llama a un proveedor, ahí
tienes el escenario de `13` §2: el proveedor tarda 30 segundos y tú retienes una de tus diez
conexiones durante esos 30 segundos mientras la base está ociosa. Diez peticiones concurrentes y
el pool se agotó por un método que no hizo una sola consulta lenta. Las dos reglas de diseño que
aplico y que separan a quien sufrió esto de quien no: **nada lento dentro de una transacción**, y
**el efecto externo va después del commit, nunca dentro**. Un `@Transactional` en el controller
viola las dos a la vez.

**🔬 El detalle.** Es también la razón por la que `@Transactional` en el controller es un olor de
diseño y no solo un problema de rendimiento: si la unidad atómica es el método del controller,
entonces el contrato HTTP y la unidad de negocio son la misma cosa, y no puedes reutilizar esa
operación desde un job de Batch ni desde un listener sin arrastrar el borde web. El límite va en
el servicio, y la comprobación de que está bien puesto es poder llamar a ese método desde un
`ApplicationRunner` sin tocar nada. Para medir la retención:
`/actuator/metrics/hikaricp.connections.usage`, y `leak-detection-threshold: 20000` para que el
`WARN` te dé el stack trace del culpable.

---

### 25 → 36

> Te piden cachear `GET /api/items/{sku}` y también la consulta de saldo de una cuenta.
> Di cuál sí, cuál no y con qué argumento, y qué dato pedirías antes de tomar la
> decisión en lugar de decidirlo por intuición. — [`17`
> §1](17-cache.md#1--el-problema-la-misma-respuesta-calculada-mil-veces) · [`17`
> §10](17-cache.md#10--sin-hit-ratio-esto-es-una-suposición)

**⏱️ 30 segundos.** `GET /api/items/{sku}` sí: lectura repetida, resultado caro, dato que cambia
despacio y tolerancia declarada al dato viejo. El saldo de una cuenta **no**: cambia más rápido
que cualquier TTL razonable y un saldo viejo en banca no es una optimización, es una respuesta
incorrecta. El dato que pido antes de decidir es el **hit ratio esperado**.

**🗣️ 2 minutos.** Las cuatro condiciones van juntas y si falta una la caché no es una mejora sino
una capa más que puede mentirte. Una con 10 % de aciertos paga la consulta del store **más** el
almacenamiento, retiene en heap objetos inútiles y alarga las pausas de GC: sale más cara que no
tenerla. Por eso no decido por intuición: pido la distribución de peticiones por SKU. Si el 90 %
del tráfico pide los mismos doscientos SKU de un catálogo que cambia dos veces al día, la caché
se defiende sola; si las peticiones están repartidas uniformemente sobre cincuenta mil, no. Con
el saldo el argumento es otro y es de negocio, no de ratio: aunque el hit ratio fuera altísimo,
lo que estoy decidiendo es cuántos segundos de saldo desactualizado tolera el producto — y esa
decisión no la toma quien escribe el `@Cacheable`. Nunca respondo "ponemos una caché y mejora el
rendimiento": una caché mejora la **latencia de lecturas repetidas** y a cambio da datos viejos,
más memoria retenida y un modo de fallo nuevo.

**🔬 El detalle.** Y una vez puesta, sin métricas no se puede defender: `cache.gets` llega con la
etiqueta `result` en `hit` o `miss`, y el ratio es `hit / (hit + miss)`; por debajo de ~0,8 en
lecturas repetidas se revisa **la clave** antes que el TTL, porque una clave inestable produce
`miss` perpetuo. `cache.size` contra tu `maximumSize` dice si estás desalojando: si van pegados,
cada entrada nueva expulsa una útil y el ratio no sube tocando el TTL; `cache.evictions`
creciendo con el tráfico es caché pequeña, no caché sana. En Caffeine esos contadores no existen
sin `recordStats` en el `spec`.

---

### 25 → 37

> Con tres réplicas de `inv-api`, decide entre Caffeine local y Redis compartido. Da el
> veredicto del curso, di qué incoherencia concreta aparece con la caché local tras un
> `@CacheEvict`, y qué se paga al mover esa caché a Redis. — [`17`
> §5](17-cache.md#5--local-o-distribuida-el-veredicto) · [`17`
> §6](17-cache.md#6--redis-como-caché-ttl-por-caché-y-serialización) · [`L06`
> §5](l06-cache-y-asincronia.md#5-️-dos-instancias-dos-cachés-dos-verdades)

**⏱️ 30 segundos.** Con tres réplicas y un dato que consume una conciliación, **Redis**. La
incoherencia concreta de la caché local: un `@CacheEvict` en la instancia A no toca la copia de
la B, y durante el TTL restante las dos responden cosas distintas al mismo `GET`. Lo que se paga
al mover a Redis: serialización y un salto de red **dentro del hilo del request**.

**🗣️ 2 minutos.** El veredicto del curso es que Caffeine gana con una sola instancia y un dato
que tolera minutos de antigüedad —nanosegundos, cero infraestructura, cero serialización—,
Ehcache 3 es el de banca cuando hace falta JSR-107 y memoria fuera del heap, y **Redis gana con
varias réplicas y una incoherencia inaceptable**, y pierde en todo lo demás. El detalle que lo
decide aquí no es el dato viejo en sí, es cómo se ve desde fuera: detrás de un balanceador esto
no parece un dato viejo, parece **intermitencia**. El cliente refresca dos veces, cae en pods
distintos y obtiene dos números distintos, y el ticket llega escrito como "a veces sale bien y a
veces mal", que es el reporte más caro de diagnosticar que existe. Y el TTL lo tapa: a los treinta
segundos las dos vuelven a coincidir, así que cuando alguien va a reproducirlo ya no pasa.

**🔬 El detalle.** Hay una tercera salida que casi nadie da y que es legítima: **declarar la
divergencia**. Un catálogo de productos con TTL de 60 segundos y dos réplicas no necesita Redis;
necesita que alguien escriba en el contrato que el dato puede tener un minuto. Lo que no se puede
hacer es tener el desfase sin haberlo decidido. El precio de Redis, con unidades: cada `get`
deserializa y cada `put` serializa en el hilo del request —un DTO de 50 KB en JSON cuesta más CPU
que la consulta que evitaste— y el salto de red son 0,3–2 ms contra ~100 ns locales, cuatro
órdenes de magnitud; delante de una consulta de 1 ms te hace más lento. Y el TTL por defecto del
`RedisCacheManager` es **infinito**: sin `entryTtl`, una entrada mal invalidada vive hasta que
alguien ejecute `FLUSHDB`.

---

### 25 → 38

> Compara las tres formas de invalidar una entrada —TTL, evento y versión de clave— y di
> cuál es la red de seguridad de cuál. Después explica por qué un `@CachePut` dentro de
> un método transaccional puede dejar cacheado un dato que nunca existió. — [`17`
> §9](17-cache.md#9--invalidación-coherencia-y-qué-no-se-cachea) · [`16`
> §8](16-transacciones.md#8--el-límite-de-la-transacción-no-es-el-límite-de-tu-método)

**⏱️ 30 segundos.** **El TTL es la red bajo el evento**, no su alternativa. El evento es exacto y
frágil: cada ruta de escritura sin anotar deja una entrada mintiendo para siempre. La versión de
clave no borra nada: deja de leer lo viejo, y es la forma limpia de invalidar **todo** tras un
cambio de formato. Y el `@CachePut` transaccional cachea antes del commit.

**🗣️ 2 minutos.** La razón del `@CachePut` es precisa y hay que decirla así: **el interceptor de
caché escribe cuando el método retorna, no cuando la transacción hace commit**. Si el commit falla
después —una constraint diferida, un `UnexpectedRollbackException`, un fallo de red con la base—,
en la caché queda un dato que nunca existió, y ahí no hay TTL corto que te salve durante la
ventana. El punto correcto es después del commit:
`@TransactionalEventListener(AFTER_COMMIT)` que actualiza la caché por API. Sobre la elección
entre las tres formas, mi posición: se ponen **dos**, evento y TTL, siempre. Solo evento es
apostar a que nadie va a escribir por otra ruta, y en un servicio con Batch, endpoints y un
listener, esa apuesta se pierde. Solo TTL es aceptable cuando la ventana de desfase se declaró en
el contrato. La versión de clave no compite con las otras dos: resuelve el cambio de formato, y su
valor es que evita un `FLUSHDB` que tiraría las cachés de los demás servicios.

**🔬 El detalle.** Lo que no se cachea, y en banca es lo que pregunta el auditor: **datos por
usuario en una caché compartida sin el usuario en la clave**. `@Cacheable("items")` sobre un
método que filtra por el `SecurityContext` devuelve al segundo usuario lo que calculó el primero;
si el resultado depende de la identidad, la identidad va en la clave — y ahí hay que preguntarse
si el hit ratio lo vale. Lo otro que no se cachea es lo que cambia más rápido que el TTL y lo que
no cabe: cien mil elementos "porque la consulta es lenta" cambian la base lenta por un
`OutOfMemoryError`.

---

### 25 → 39

> Diseña el executor de `@Async` para enviar notificaciones desde una API de banca: di
> qué valores das a los tres números, qué política de rechazo eliges y por qué
> `CallerRunsPolicy`, que parece la prudente, puede tumbar el borde web. — [`18`
> §4](18-asincronia-scheduling-y-eventos.md#4-️-el-executor-los-tres-números-y-la-cola-traicionera)
> · [`08` §2](08-modelo-de-ejecucion-web.md#2--una-instancia-muchos-hilos)

**⏱️ 30 segundos.** `core-size` según la concurrencia real que quiero contra el proveedor de
notificaciones —cuatro u ocho—, `max-size` el doble, y `queue-capacity` **acotada** y pequeña,
del orden de 50. Política: `AbortPolicy`, el default, que lanza `TaskRejectedException` y es
ruidosa — que aquí es bueno. `CallerRunsPolicy` ejecuta la tarea en el hilo que la envió: el hilo
de Tomcat que creías haber liberado.

**🗣️ 2 minutos.** Antes de los números hay un hecho del `ThreadPoolTaskExecutor` que invierte la
intuición: **llena la cola ANTES de crecer hasta `max`**. Con la cola por defecto —ilimitada— "la
cola está llena" no ocurre jamás y `max-size` **nunca se alcanza**: tu pool de "hasta dos mil
millones de hilos" son ocho hilos y una cola que crece hasta el heap. Por eso `core-size` es el
número que de verdad gobierna la concurrencia, y por eso acotar la cola es lo primero: una cola
ilimitada no es "sin límite", es un `OutOfMemoryError` diferido tras horas aceptando trabajo sin
hacerlo. Acotarla obliga a elegir política, y ahí elijo fallar ruidosamente. `CallerRunsPolicy`
parece la prudente porque no pierde trabajo, y es backpressure real; el problema es dónde aplica
el freno. El hilo que envía la tarea es un hilo de Tomcat, de los 200; si la cola está llena, ese
hilo se pone a mandar notificaciones en vez de responder, la latencia del endpoint se dispara, y
con suficiente carga los 200 hilos acaban enviando correos y el borde web deja de atender.

**🔬 El detalle.** `DiscardPolicy` y `DiscardOldestPolicy` quedan descartadas de entrada: tiran
trabajo callando, y una notificación de banca que desaparece sin log no es una opción.
`await-termination: true` no va solo: sin `await-termination-period` el executor se compromete a
ejecutar **toda** la cola mientras el resto del contexto se cierra en paralelo —tus tareas pueden
encontrarse el `DataSource` ya cerrado— y nada acota ese drenaje. Y una nota de versión que evita
una respuesta equivocada: toda fuente anterior a **Boot 2.1** dice que el executor por defecto de
`@Async` es `SimpleAsyncTaskExecutor` y que crea un hilo por tarea sin reutilizar. Sigue siendo
cierto en Spring Framework a secas, **no en Boot**, donde el default es el
`applicationTaskExecutor`.

---

### 25 → 40

> Tres réplicas del servicio tienen el mismo `@Scheduled` que dispara el job de
> conciliación. Enumera las tres salidas, di cuál eliges en banca y por qué
> `JobExecutionAlreadyRunningException` protege de la duplicación pero no es un
> scheduler distribuido. — [`18`
> §7](18-asincronia-scheduling-y-eventos.md#7-️-tres-réplicas-tres-ejecuciones) · [`22`
> §10](22-spring-batch.md#10--lanzarlo-probarlo-y-vigilarlo) · [`L06`
> §9](l06-cache-y-asincronia.md#9-️-scheduled-por-duplicado-el-rlock-y-shedlock)

**⏱️ 30 segundos.** Tres salidas: **hacer el job idempotente** y dejar que corra N veces, un
**lock distribuido** (ShedLock es el estándar de hecho), o un **scheduler externo**. En banca
elijo el scheduler externo para la conciliación, porque la ejecución ya es una operación de
negocio con su auditoría. `JobExecutionAlreadyRunningException` protege de la duplicación, pero
no dice **quién debía correr**.

**🗣️ 2 minutos.** La elección es de gobierno, no de librería. Un `@Scheduled` es **local al
proceso**: con tres pods hay tres relojes y tres ejecuciones, y si el job no es idempotente eso
es tres veces el daño. Para "refrescar una caché" la primera salida basta y es gratis. Para una
conciliación nocturna no, por dos razones que un auditor va a preguntar: hace falta poder
responder *cuándo se ejecutó y con qué resultado* sin leer los logs de tres pods, y hace falta
poder **relanzarla a mano** tras un fallo sin desplegar nada. Un scheduler externo da las dos
cosas y además separa la decisión de ejecutar de la aplicación que ejecuta. Lo que pago es una
pieza de infraestructura más y una dependencia operativa; lo acepto porque la alternativa es que
el calendario contable viva escondido en una anotación. ShedLock es la respuesta intermedia
razonable cuando no hay scheduler corporativo: `lockAtMostFor` —el lease— y `lockAtLeastFor`, que
impide que dos relojes ligeramente desfasados ejecuten dos veces seguidas.

**🔬 El detalle.** `JobExecutionAlreadyRunningException` merece precisión porque suena a solución
y no lo es. Cuando el job de Batch se dispara desde tres réplicas, el segundo intento **no
duplica el trabajo: lo rechaza**, porque el `JobRepository` ya tiene esa `JobInstance` en
ejecución. Eso te protege de la duplicación y no te dice quién debía correr, ni te avisa si
**ninguno** corrió. Y ningún lock garantiza nada por sí solo: si quien tomó el lock muere a la
mitad, esa ejecución se pierde hasta la vuelta siguiente — en un job diario, hasta mañana. Un
`RLock` de Redisson sobre una sola instancia de Redis se pierde en un failover, y **sin fencing
token no hay exclusión mutua** ante una pausa de GC. Si de la exclusión depende la corrección, se
resuelve donde está el dato: restricción única, `UPDATE ... WHERE version = ?`, idempotencia.

---

### 25 → 41

> Tu endpoint promete responder en dos segundos y llama en serie a dos proveedores, uno
> de ellos con tres intentos de retry. Haz la aritmética del peor caso, di si el
> presupuesto se cumple y qué recortarías primero si no se cumple. — [`19`
> §2](19-resiliencia.md#2--el-timeout-es-el-primero-y-sin-él-nada-más-sirve) · [`19`
> §7](19-resiliencia.md#7--el-orden-en-que-se-apilan) · [`L05`
> §6](l05-clientes-y-resiliencia.md#6--el-orden-de-los-decoradores-invertido-a-propósito)

**⏱️ 30 segundos.** Con `max-attempts: 3` son **tres llamadas totales**, no tres reintentos. Si
cada una tiene timeout de 700 ms y el backoff es 200 ms y 400 ms, el proveedor con retry cuesta
hasta **2,7 s** él solo —2,1 s de llamadas más 600 ms de espera quieta—, más 700 ms del otro
proveedor: 3,4 s contra un presupuesto de 2 s. **No se cumple.** Lo primero que recorto es el
`max-attempts`.

**🗣️ 2 minutos.** El presupuesto se reparte **de fuera hacia dentro** y esa es la disciplina que
falta casi siempre: si la API promete 2 s y llama a dos proveedores en serie, no puedes darle 2 s
a cada uno. El reparto sano sería 700 ms para A, 700 ms para B y 600 ms de margen para lo tuyo
—serialización, base, GC—, y ahí ya no cabe ningún reintento. Por eso recorto el retry antes que
los timeouts: bajar `max-attempts` a 2 devuelve 1,4 s de golpe y sigue cubriendo el fallo
puntual, que es para lo que existe el retry. Si aun así no cabe, la siguiente palanca es
**paralelizar** las dos llamadas en vez de encadenarlas, y solo después tocar el timeout de cada
proveedor —que es lo que la gente hace primero y es lo que menos margen da sin empeorar la tasa
de error—. Lo que no hago es dejar el retry y esperar que el caso malo no ocurra: el caso malo es
exactamente cuando el proveedor se degrada, o sea, cuando más peticiones lo van a atravesar.

**🔬 El detalle.** El coste no es solo latencia: el retry de Resilience4j sobre un método
bloqueante **no suelta el hilo del request**. Los intentos y los backoffs ocurren en el mismo
hilo de Tomcat, que queda retenido de principio a fin, y una conexión del pool saliente ocupada
durante cada intento. Multiplicado por las peticiones concurrentes, reintentar es barato en CPU y
caro en hilos. Y el backoff exponencial **necesita jitter**: si cien clientes fallan a la vez y
todos reintentan a 1 s, 2 s y 4 s, lo que construiste es un ariete sincronizado —
`enable-randomized-wait: true`. `retry-exceptions` es lista blanca: sin ella reintentas también
los 4xx, que nunca van a cambiar de opinión.

---

### 25 → 42

> Un fallback devuelve el último precio conocido cuando el proveedor no responde. Di en
> qué condiciones eso es honesto y en cuáles es un fraude operativo, qué tiene que
> acompañarlo siempre, y cuál es el caso en que el fallback correcto es no tener
> ninguno. — [`19` §8](19-resiliencia.md#8--el-fallback-honesto) · [`17`
> §9](17-cache.md#9--invalidación-coherencia-y-qué-no-se-cachea) · [`23`
> §9](23-actuator-y-observabilidad.md#9--prometheus-el-scrape-y-las-cuatro-señales-doradas)

**⏱️ 30 segundos.** Es honesto si **degrada marcado como tal** —el último precio conocido, con su
marca de tiempo y con el log de la causa— y el consumidor sabe que puede recibirlo. Es fraude
cuando se devuelve como dato bueno. Lo que tiene que acompañarlo siempre: **el log de la causa y
una alerta sobre el circuito**. Y con dinero de por medio, a veces el fallback correcto es **no
tener ninguno** y propagar un 503 rápido.

**🗣️ 2 minutos.** La línea que separa las dos cosas no es técnica, es de contrato. Un precio de
hace cinco minutos etiquetado como tal es información degradada y el cliente decide qué hacer con
ella; el mismo precio sin etiqueta, en un flujo que va a liquidar una operación, es una cifra
inventada con apariencia de dato. Devolver `0` o una lista vacía es el caso peor: convierte un
fallo visible en **corrupción silenciosa**, y nadie se entera hasta la reconciliación. Por eso en
banca mi default es el fallback que no inventa: si no hay último valor conocido con antigüedad
aceptable, propago el error. Y el acompañamiento no es opcional: un fallback que no deja rastro
convierte una caída del proveedor en un misterio en el que todo "funciona" y los números están
mal.

**🔬 El detalle.** Hay una trampa de Resilience4j que no es la que se cuenta por ahí: **no valida
la firma del fallback en el arranque y tampoco revienta la petición cuando no casa**. En 2.2.0,
`FallbackExecutor.execute` resuelve el método por reflexión en cada invocación del método
anotado, **antes de ejecutarlo**; si no encuentra firma compatible, captura la
`NoSuchMethodException`, escribe un `WARN` con el texto `No fallback method match found` y sigue
como si no hubieras configurado ninguno. Dos consecuencias: el defecto se manifiesta en la
primera llamada, tenga éxito o no, y el día que el proveedor falle de verdad verás el error de
siempre y un `WARN` viejo que nadie leyó. La defensa es un test que fuerce el fallo y compruebe
que el fallback responde. La firma correcta repite la del método original y añade un `Throwable`
final.

---

### 25 → 43

> Son las tres de la mañana y el circuito hacia `inv-supplier` está abierto. Di qué ves
> en el tablero, por qué la tasa de 5xx puede estar **bajando** mientras el incidente
> empeora, sobre qué métrica se escribe la alerta y cuál es tu primera acción. — [`19`
> §9](19-resiliencia.md#9--sin-métricas-esto-es-fe) · [`23`
> §9](23-actuator-y-observabilidad.md#9--prometheus-el-scrape-y-las-cuatro-señales-doradas)
> · [`L07` §9](l07-actuator-metricas-y-trazas.md#9-️-la-alerta-sobre-el-circuito-de-l05)

**⏱️ 30 segundos.** En el tablero veo latencia **baja** y la tasa de 5xx **bajando**: mientras el
circuito está abierto, el gateway devuelve fallbacks con éxito y el panel de errores mejora
mientras el incidente empeora. La alerta se escribe sobre el **cambio de estado**:
`resilience4j_circuitbreaker_state{name="supplier",state="open"} == 1`. Mi primera acción es
mirar si el fallback está sirviendo datos viejos y cuánto de viejos.

**🗣️ 2 minutos.** El punto ciego existe **precisamente porque el fallback responde con éxito**;
si contestara `503`, la tasa de 5xx no bajaría y la alerta de errores sonaría sola. Por eso el
circuito **se alerta, no se grafica**: lo que importa no es su valor instantáneo sino su cambio
de estado, y eso es un evento, no una curva que alguien tenga que estar mirando a las tres de la
mañana. La secuencia que sigo: primero `/actuator/circuitbreakers` para confirmar el estado en el
proceso, después `/actuator/circuitbreakerevents` para ver qué tipo de fallo lo abrió —error o
llamada lenta—, y en paralelo la pregunta de negocio, que es la que de verdad decide si esto es
una incidencia de severidad alta: cuántas respuestas llevan saliendo con datos degradados y si
alguna de ellas se usó para liquidar algo. Lo técnico puede esperar diez minutos; esa pregunta
no.

**🔬 El detalle.** El `== 1` de la expresión no es cosmética: el gauge publica **una serie por
estado** —`closed`, `open`, `half_open`, `disabled`, `forced_open`— y solo la del estado actual
vale `1`; sin él la alerta estaría disparada permanentemente. El `for: 30s` es el antirrebote, y
hay que saber que alertar sobre métricas nunca es inmediato: entre el evento y la notificación
hay un scrape (hasta 15 s), una evaluación (hasta 15 s más) y el `for` — unos 45 s de media y
hasta 60 en el peor caso. Y la anotación de la alerta tiene que decir explícitamente que **no**
hay que esperar 5xx; una anotación que repite el nombre de la alerta no sirve para nada.

---

### 25 → 44

> Diseña el `health` de `inv-api` para un orquestador: qué comprueba `liveness`, qué
> comprueba `readiness`, y por qué meter la disponibilidad de `inv-supplier` en uno de
> los dos puede tumbar el despliegue entero en cascada. — [`23`
> §4](23-actuator-y-observabilidad.md#4--health-grupos-indicators-propios-y-show-details)
> · [`19`
> §5](19-resiliencia.md#5--circuit-breaker-dejar-de-insistir-sobre-lo-que-está-roto)

**⏱️ 30 segundos.** `liveness` comprueba solo que el proceso está vivo y su contexto sano:
`livenessState` y nada más. `readiness` comprueba lo que hace falta para **atender tráfico**:
`readinessState`, `db` y, con mucho cuidado, las dependencias propias. Meter `inv-supplier` en
`liveness` es el error caro: **`liveness` en `DOWN` provoca un reinicio**, así que con el
proveedor caído el orquestador reinicia todas tus réplicas.

**🗣️ 2 minutos.** La diferencia de consecuencias es toda la respuesta: `readiness` en `DOWN` saca
la instancia del balanceador y la devuelve sola al recuperarse; `liveness` en `DOWN` la mata. Con
una dependencia externa en `liveness` tienes una cascada perfecta: el proveedor se degrada, las
tres réplicas se declaran muertas a la vez, el orquestador las reinicia, arrancan, vuelven a
preguntar al proveedor que sigue caído y se reinician otra vez — y ahora además has perdido las
cachés y los pools calientes. Mi posición incluso para `readiness` es restrictiva: ahí va lo que
si falta hace que **esta instancia** no pueda servir, típicamente la base; una dependencia que
tiene circuit breaker y fallback **no va**, porque por definición el servicio sabe responder sin
ella. Si la metes, estás diciendo que el fallback no sirve, y entonces sobra el fallback.

**🔬 El detalle.** `DOWN` y `OUT_OF_SERVICE` se traducen a **HTTP 503**, que es lo único que el
balanceador mira. Los grupos se declaran con `management.endpoint.health.probes.enabled=true` y
`...group.readiness.include` / `...group.liveness.include`, y se consultan por separado en
`/actuator/health/readiness` y `/actuator/health/liveness`. Un `HealthIndicator` propio **corre en
el hilo que atiende la petición al endpoint**, no en un scheduler: sin `read-timeout` en su
`RestClient`, un proveedor colgado cuelga también tu health check. Y en el detalle nunca va el
mensaje de la excepción, solo el tipo, porque el mensaje crudo publica hosts internos. Además:
`health` verde no significa que funcione — quien devuelve fallbacks sigue `UP`.

---

### 25 → 45

> Producto quiere una métrica etiquetada por `sku` "para ver qué se consulta más".
> Explica qué le pasa a Prometheus, por qué el daño no se queda en esa métrica, qué
> ofreces en su lugar y dónde sí puede vivir el `sku`. — [`23`
> §8](23-actuator-y-observabilidad.md#8-️-tags-y-cardinalidad-el-error-que-tumba-prometheus)
> · [`23`
> §11](23-actuator-y-observabilidad.md#11--logging-correlación-json-y-lo-que-no-se-escribe-nunca)
> · [`L07` §6](l07-actuator-metricas-y-trazas.md#6-️-el-experimento-de-la-cardinalidad)

**⏱️ 30 segundos.** Cada valor distinto de `sku` crea **una serie de tiempo nueva**: 50 000 SKU
por tres valores de `outcome` son 150 000 series de una sola métrica. El daño no se queda ahí
porque Prometheus crece hasta que el kernel lo mata, y entonces **pierdes todas las métricas**,
también las de los demás servicios. Le ofrezco un log estructurado o una consulta a la base: el
`sku` es un **campo de log**, no un tag.

**🗣️ 2 minutos.** La conversación con producto la planteo así: la pregunta *"¿qué SKU se piden
más?"* es legítima y la respuesta correcta no vive en el sistema de métricas. Un tag es una
dimensión con un **conjunto cerrado y pequeño** de valores —`outcome`, `status`, `method`,
`reason`—; si el valor lo elige el cliente o crece con el catálogo, no es un tag. Y hay un
agravante que suele cerrar la discusión sin más argumentos: el contador se incrementa antes de
la consulta, así que **cualquiera que pueda inventar SKU en la URL puede fabricarte series de
tiempo**. Con un tag sobre un identificador que viene del cliente, la cardinalidad deja de ser un
error de diseño y pasa a ser un vector de denegación de servicio contra el backend de métricas.
Lo que ofrezco a cambio es concreto: el `sku` en el log estructurado en JSON, que es consultable
por campo y con retención propia, o una consulta contra la base de inventario — que además
responde mejor la pregunta, porque puede agrupar por familia de producto.

**🔬 El detalle.** El fusible se pone igualmente, porque el próximo tag mal elegido no lo vas a
escribir tú: un bean `MeterFilter` con
`maximumAllowableTags("inventory.valuation.requests", "sku", 100, MeterFilter.deny())`, y
`management.metrics.web.server.max-uri-tags`, que vale **100** por defecto para
`http.server.requests`. Los dos avisan y no curan: no borran las 100 que ya entraron. Y la parte
incómoda: en tu máquina las series desaparecen al reiniciar porque el registro vive en memoria;
**en Prometheus no desaparecen** — quedan hasta que expira la retención y el índice sigue pagando
por ellas. El daño de la cardinalidad sobrevive al despliegue que la arregla.

---

### 25 → 46

> Sigue el `traceId` de una petición desde el borde hasta el log de un método `@Async`,
> hasta la llamada a `inv-supplier` y hasta el job de Batch que se dispara después. Di
> qué lo transporta en cada salto y en cuál de ellos se pierde si no haces nada. — [`23`
> §10](23-actuator-y-observabilidad.md#10--trazas-traceid-spanid-w3c-y-sampling) · [`18`
> §5](18-asincronia-scheduling-y-eventos.md#5--propagación-de-contexto-lo-que-se-queda-en-el-hilo-del-request)
> · [`22` §10](22-spring-batch.md#10--lanzarlo-probarlo-y-vigilarlo)

**⏱️ 30 segundos.** En el borde lo pone Micrometer Tracing en el MDC y viaja entre servicios en
la cabecera W3C `traceparent`. Al `@Async` **no cruza solo**: hace falta un `TaskDecorator`. A
`inv-supplier` viaja solo si el cliente salió de un **builder autoconfigurado**. Y al job de Batch
no llega de ninguna manera: es otro proceso o, como mínimo, otra ejecución sin petición de origen.

**🗣️ 2 minutos.** Los tres saltos donde se pierde son distintos y conviene no mezclarlos. El del
`@Async` es el de `ThreadLocal`: el MDC no cruza a otro hilo y las líneas salen huérfanas; se
arregla con `ContextPropagatingTaskDecorator`, que usa Micrometer Context Propagation y arrastra
la observación, el `traceId` y el MDC. El de la llamada saliente es de instrumentación: **un
`RestClient.create()` suelto no lleva el interceptor de trazas**, así que el `traceId` muere en tu
borde y la traza aparece cortada — otra razón para inyectar el builder. El del Batch es
conceptual: un job lanzado por un scheduler no tiene traza de origen, así que lo que se propaga
ahí no es el `traceId` sino el **identificador de negocio** —`business.date`, el `JobExecutionId`—
y lo que se correlaciona es por ese campo, no por la traza. Confundir los tres lleva a intentar
arreglar el tercero con un `TaskDecorator`, que no sirve para nada.

**🔬 El detalle.** `traceId` son 32 hex y `spanId` 16; la cabecera es
`traceparent: 00-<traceId>-<spanId>-01`, donde el `01` significa "muestreada". **La decisión de
muestreo se toma en la raíz** y viaja en ese flag: se muestrea la petición entera o ninguna parte
de ella, así que subir `management.tracing.sampling.probability` en un servicio intermedio no
recupera nada. El default es `0.1` y casi nunca se sube a `1.0`, porque cada traza exportada son
bytes de red y almacenamiento por span. En 4.x, `management.tracing.enabled` se renombra a
`management.tracing.export.enabled`: instrumentar y exportar dejan de ser el mismo interruptor.

---

### 25 → 47

> Diseña las cadenas de seguridad de `inv-api`: una para la API con Bearer y otra para
> Actuator en el puerto de management. Di qué lleva cada una, en qué orden se declaran,
> y qué le ocurre a una URL que no matchea ninguna. — [`20`
> §3](20-spring-security-el-mecanismo.md#3--la-cadena-se-declara-como-bean) · [`20`
> §10](20-spring-security-el-mecanismo.md#10--asegurar-actuator-sin-escribir-rutas-a-mano)
> · [`23` §3](23-actuator-y-observabilidad.md#3--el-puerto-de-management-separado)

**⏱️ 30 segundos.** Dos beans `SecurityFilterChain`: la de Actuator con `@Order(0)` y
`securityMatcher(EndpointRequest.toAnyEndpoint().excluding(HealthEndpoint.class))` más
`httpBasic`, y la de la API con `@Order(1)`, `securityMatcher("/api/**")`, `oauth2ResourceServer`,
`csrf.disable()` y `STATELESS`. Una URL que no matchea **ninguna cadena sale sin ninguna regla
aplicada**.

**🗣️ 2 minutos.** El orden importa porque `FilterChainProxy` elige **la primera cadena que
matchea** y las demás no se evalúan: una cadena sin `securityMatcher` declarada primero deja
muertas a todas las demás. Por eso Actuator va en `@Order(0)`, que además es lo correcto
conceptualmente —es un consumidor distinto, una herramienta, y por eso `httpBasic` basta: una
sesión no le aporta nada a un scraper—. `EndpointRequest.toAnyEndpoint()` resuelve las rutas
reales **en tiempo de ejecución**, respetando `management.endpoints.web.base-path` y el puerto de
management separado; esa es toda la razón para no escribir `/actuator/**` a mano. Y el hueco de
la URL sin cadena es el que más me preocupa en una revisión: no da error, no da 403, **responde**.
La defensa es que toda cadena termine en `anyRequest().authenticated()` y que exista una cadena
final sin `securityMatcher` que cierre lo que quede — y un test que pida una ruta inventada y
espere 401.

**🔬 El detalle.** `securityMatcher` decide **qué peticiones entran** a esta cadena;
`requestMatchers`, dentro de `authorizeHttpRequests`, decide **qué se exige a las que entraron**.
Confundirlos es el error de configuración más caro. Dentro de una cadena las reglas se evalúan en
orden de declaración, gana la primera que matchea y lo no listado queda permitido, así que
`anyRequest().authenticated()` va siempre al final. `.excluding(HealthEndpoint.class)` deja lo
mínimo para el balanceador, y lo correcto es abrir el **grupo de probes**, no el `health`
detallado, porque `show-details` fuera de `never` publica el estado de tu base a quien pregunte.
Declarar el bean es también lo que apaga la autoconfiguración de Security, la que pedía login para
todo con la contraseña aleatoria del arranque.

---

### 25 → 48

> Compara autorizar en la cadena HTTP con `requestMatchers` frente a autorizar en el
> servicio con `@PreAuthorize`. Di qué caso solo resuelve el segundo, qué le cuesta al
> proxy, y cómo evitas que una regla nueva se quede sin poner. — [`20`
> §7](20-spring-security-el-mecanismo.md#7--autorización-http-y-el-prefijo-role_) ·
> [`20`
> §8](20-spring-security-el-mecanismo.md#8--method-security-el-proxy-de-05-con-otro-sombrero)
> · [`05` §5](05-proxies-y-aop.md#5-️-self-invocation-el-fallo-silencioso-número-uno)

**⏱️ 30 segundos.** `requestMatchers` decide por **ruta y método**; `@PreAuthorize` decide por
**el dato**: "puede ver el ajuste si es suyo" no se expresa en una ruta. Solo el segundo resuelve
eso. Cuesta un proxy AOP, con todas sus consecuencias —incluida la self-invocation—. Y para que
no falte ninguna regla, el cierre es `anyRequest().authenticated()` más un test por endpoint.

**🗣️ 2 minutos.** Mi posición es que las dos van juntas y no compiten: la de URL rechaza antes de
entrar, que es lo barato y lo que protege el hilo; la de método protege aunque la llamada venga
de un `@Scheduled` o de otro controller, que es lo que de verdad importa cuando el servicio crece.
Lo que cuesta method security es que **es el proxy de `05` con otro sombrero**: sobre método
`private`, `final` o `static` no hay interceptación, y si otro método de la misma clase llama a
`apply()`, **la anotación no se evalúa**. Aquí el fallo silencioso no es una transacción perdida:
es una comprobación que no ocurrió. Sobre cómo evitar que una regla nueva se quede sin poner, la
respuesta que doy no es "revisar mejor": es un test de seguridad por endpoint —`@WithMockUser` sin
el rol, esperando 403— y la regla de que ningún endpoint nuevo entra sin el suyo. Eso es
verificable en CI; la disciplina no.

**🔬 El detalle.** `@EnableMethodSecurity` lo activa —el starter no lo activa solo— y en Security
6 ya trae `prePostEnabled = true`; sustituye a `@EnableGlobalMethodSecurity`, retirado.
`@PreAuthorize` evalúa **antes**, en SpEL, con acceso a los argumentos (`#adjustment`) y a
`authentication`; `@PostAuthorize` evalúa **después** sobre `returnObject` y es peligroso si el
método ya escribió, porque ya corrió. `@PreFilter` y `@PostFilter` filtran colecciones **en
memoria**: con una colección grande se filtra en la consulta. Y la trampa número uno de la
autorización por URL: `hasRole("ANALYST")` es un atajo que **añade el prefijo `ROLE_`** y compara
contra `ROLE_ANALYST`, mientras `hasAuthority` compara el literal — si tu base guarda `ANALYST` a
secas, obtienes un 403 perfecto y silencioso.

---

### 25 → 49

> La auditoría tiene que registrar quién hizo qué. Di de dónde sacas la identidad en el
> hilo del request, dentro de un `@Async`, dentro de un listener `AFTER_COMMIT` y dentro
> de un job de Batch — y cuál de los cuatro te obliga a pasarla como parámetro. — [`20`
> §6](20-spring-security-el-mecanismo.md#6--securitycontextholder-un-threadlocal-y-sus-dos-fugas)
> · [`18` §9](18-asincronia-scheduling-y-eventos.md#9--el-evento-que-espera-al-commit) ·
> [`L08` §7](l08-security-y-batch.md#7-️-el-securitycontext-que-no-cruza-al-async)

**⏱️ 30 segundos.** En el hilo del request, del `Authentication` —como parámetro del método o con
`@AuthenticationPrincipal`, no leyendo el holder—. En un `@Async`, del `SecurityContext` **copiado
por `DelegatingSecurityContextAsyncTaskExecutor`**. En un listener `AFTER_COMMIT`, del mismo hilo,
así que sigue disponible. **En un job de Batch no hay identidad de usuario**: ahí se pasa como
`JobParameter`.

**🗣️ 2 minutos.** El cuarto es el que obliga a pasarla como parámetro y conviene entender por qué
no es un descuido: un job nocturno no tiene usuario, tiene un **actor de sistema**. Si la
conciliación la lanzó una persona desde un endpoint, esa identidad es un dato de negocio y viaja
como parámetro del job, registrado en `BATCH_JOB_EXECUTION_PARAMS`, que es además donde el auditor
va a mirar. Intentar que el `SecurityContext` llegue allí es forzar un mecanismo de hilo para
transportar un dato que tiene que quedar **persistido**, no propagado. En el `@Async` sí propago,
y con el decorador de Security y no con `MODE_INHERITABLETHREADLOCAL`: ese hereda el contexto a
hilos **hijos**, y los de un pool no son hijos de nadie, los creó el pool al arrancar. El listener
`AFTER_COMMIT` es el caso fácil y conviene saberlo: **corre en el mismo hilo**, después del commit,
así que ve la identidad — hasta el día que alguien le añade `@Async` para no bloquear la
respuesta, y entonces recupera el problema del principio.

**🔬 El detalle.** El síntoma cuando el contexto no llega **no** es el que espera casi todo el
mundo. `20` §6 describe una `AccessDeniedException` con un usuario que sí tenía el rol, y eso es
lo que ves cuando el contexto llega **con menos authorities**. Cuando no llega en absoluto, el
interceptor no tiene a quién evaluar y lanza antes:
`AuthenticationCredentialsNotFoundException`, que desciende de `AuthenticationException` y no de
`AccessDeniedException` — las dos son el mismo bug con dos caras. Y hay un agravante: si el método
asíncrono devuelve `void`, la excepción se la come el `SimpleAsyncUncaughtExceptionHandler`, el
`POST` respondió 200 y nadie se entera. Del `Authentication` se registra `auth.getName()`, nunca el
objeto entero: uno de JWT lleva el token dentro y su `toString()` escribiría una credencial en el
log.

---

### 25 → 50

> Un auditor pregunta por qué vuestra API desactiva CSRF. Da el argumento exacto, di qué
> habría cambiado si la API usara cookie de sesión, y explica qué relación tiene todo
> esto con la configuración de CORS que sí hace falta. — [`20`
> §11](20-spring-security-el-mecanismo.md#11--csrf-cors-y-sesión-las-tres-que-rompen-una-api)
> · [`09`
> §9](09-rest-con-spring-mvc.md#9--webmvcconfigurer-el-punto-de-extensión-de-mvc)

**⏱️ 30 segundos.** Porque el ataque CSRF depende de que **el navegador adjunte la credencial
solo**, y una cabecera `Authorization: Bearer` no se adjunta sola. Con cookie de sesión sí se
adjunta, y entonces desactivar CSRF es abrir el agujero. La relación con CORS es que las dos
protegen del mismo escenario —otro origen llamando a tu API— pero en capas distintas, y CORS sigue
haciendo falta porque **el navegador sí va a exigirlo**.

**🗣️ 2 minutos.** Al auditor se lo doy con el mecanismo, no con la conclusión: el `CsrfFilter`
valida los métodos **no seguros** —todo lo que no sea `GET`, `HEAD`, `TRACE` u `OPTIONS`— exigiendo
un token que el atacante no puede leer desde otro origen. Eso tiene sentido cuando la credencial
viaja en una cookie que el navegador manda automáticamente hacia tu dominio. En una API stateless
con Bearer, el token lo pone JavaScript explícitamente en cada petición; un sitio malicioso puede
provocar la petición, pero no puede poner esa cabecera con tu token, porque no lo tiene. Por eso
`csrf.disable()` aquí es una **decisión justificada, no un atajo**, y así es como se documenta. Y
completo la respuesta con la pregunta que viene detrás, que es la que de verdad importa: la
decisión depende de que la API sea **realmente** stateless, así que va acompañada de
`SessionCreationPolicy.STATELESS`, que hace que Security use un `NullSecurityContextRepository` y
ni cree ni consulte `HttpSession`. Si mañana alguien introduce una cookie de sesión, esta
justificación caduca.

**🔬 El detalle.** CORS falla **antes** de llegar a tu configuración de MVC y por eso produce el
ticket de "funciona con curl y no desde el navegador": el navegador manda un `OPTIONS` de preflight
**sin credenciales**, y si la cadena exige autenticación para todo, ese `OPTIONS` recibe un 401 y
el navegador lo reporta como un error de CORS que no es un error de CORS. Por eso se registra en
Security —`http.cors(Customizer.withDefaults())` con un `CorsConfigurationSource` como bean— y no
solo en `WebMvcConfigurer`. Y `allowedOrigins("*")` con `allowCredentials(true)` **falla en el
arranque**, que es lo que debe hacer: es la combinación que anula la protección.

---

### 25 → 51

> `inv-api` es resource server con `issuer-uri`. Enumera en orden lo que valida de un
> JWT entrante y después cuenta qué ocurre, paso a paso, el día que el IdP rota su clave
> de firma a media tarde sin avisar. — [`21`
> §4](21-identidad-federada-oauth2-oidc-y-jwt.md#4--qué-valida-un-resource-server-y-en-qué-orden)
> · [`21`
> §5](21-identidad-federada-oauth2-oidc-y-jwt.md#5--firma-simétrica-asimétrica-y-el-jwk-set-endpoint)

**⏱️ 30 segundos.** En orden: formato, firma contra la clave pública del `kid`, `iss`, `exp`/`nbf`
con clock skew — y `aud` **no**, no se valida por defecto. Cuando el IdP rota la clave a media
tarde, no pasa nada: llega un JWT con un `kid` desconocido, el decoder **recarga el JWK Set** y
verifica. Eso funciona porque el IdP publica la clave nueva **antes** de firmar con ella.

**🗣️ 2 minutos.** El paso 5 es el que se cobra en producción y es el que hay que nombrar sin que
te pregunten: sin validar `aud`, un token emitido por el mismo IdP **para el servicio de nóminas**
entra en `inv-api` con la firma perfecta y el `iss` correcto. En un banco con un IdP corporativo y
veinte aplicaciones, eso significa que cualquier token válido del dominio vale en tu API. Se
arregla con la propiedad de Boot o con un `JwtClaimValidator<List<String>>(AUD, ...)`, y yo lo
trato como configuración obligatoria, no como endurecimiento opcional. Sobre la rotación, la
secuencia completa: en el arranque —o en la primera petición— Boot llama a
`.well-known/openid-configuration`, lee `jwks_uri`, descarga el JWK Set y lo cachea; ante un `kid`
que no está en caché, lo recarga y reintenta. Sin esa caché habría una llamada HTTP al IdP por
petición.

**🔬 El detalle.** El clock skew por defecto es de **60 segundos**
(`new JwtTimestampValidator(Duration.ofSeconds(60))`), porque el reloj del emisor y el tuyo no son
el mismo; ampliarlo a cinco minutos "por si acaso" alarga cinco minutos la vida de **todo** token
caducado. Los pasos 3 y 4 son lo que trae `JwtValidators.createDefaultWithIssuer(...)`. El fallo
sale siempre igual y conviene reconocer la cabecera literal: `WWW-Authenticate: Bearer
error_code="invalid_token", error_description="..."`. Y un matiz operativo que decide entre las
dos formas de configurar: con `issuer-uri`, Boot llama al descubrimiento **en el arranque**, y si
el IdP no está arriba la aplicación no arranca; con `jwk-set-uri` fija esa llamada se aplaza, a
cambio de escribir la URL a mano y de que Boot ya no valide el `iss`.

---

### 25 → 52

> El `client-secret` del flujo `client_credentials` está en `application-prod.yml`,
> cifrado con una clave que vive en el mismo repositorio. Explica por qué eso no es un
> secreto, da dos salidas que Boot soporta, y di qué identidad viaja realmente en ese
> flujo. — [`21`
> §8](21-identidad-federada-oauth2-oidc-y-jwt.md#8--propagar-la-identidad-al-llamar-a-otro-servicio)
> · [`07`
> §8](07-configuracion-externalizada.md#8--importar-configuración-y-guardar-secretos)

**⏱️ 30 segundos.** No es un secreto porque la clave viaja con el cifrado: quien tiene el
repositorio tiene las dos mitades, y el `application.yml` además se copia en los logs de build y
acaba dentro de la imagen. Las dos salidas que Boot soporta: **variables de entorno inyectadas por
la plataforma** y **`spring.config.import: configtree:/run/secrets/`**. Y en `client_credentials`
la identidad que viaja es la **del servicio**, no la de ningún usuario.

**🗣️ 2 minutos.** El argumento que uso es el del alcance del compromiso: un secreto en el
repositorio no está expuesto a un atacante, está expuesto a **todo el que tiene acceso de lectura
al repositorio**, que en un banco son decenas de personas y varios sistemas de CI, y no hay forma
de saber quién lo leyó ni de rotarlo sin un commit. Un config tree montado por la plataforma se
rota sin desplegar y deja rastro en el gestor de secretos. Sobre `client_credentials`, la parte
que hay que decir antes de que la pregunten: es **servicio a servicio sin usuario**. El client se
autentica con su `client-id` y su `client-secret` y recibe un access token **suyo**, sin `sub` de
humano; si necesitas saber quién pidió el ajuste, este no es el flujo. En banca suele ganar el
modelo de dos capas: el token del usuario **muere en el borde** y hacia dentro viaja un token de
servicio más el usuario propagado en la traza.

**🔬 El detalle.** `configtree:` convierte cada fichero de un directorio en una propiedad: el
fichero `/run/secrets/inv.supplier.token` se convierte en la propiedad `inv.supplier.token` con su
contenido como valor, que es exactamente lo que montan Kubernetes y Docker Swarm. El prefijo
`optional:` evita que la ausencia rompa el arranque — y **hay que decidirlo para cada import**: un
`optional:` puesto por inercia sobre el fichero de secretos de producción es cómo se despliega un
servicio sin credenciales que falla mucho más tarde. Sin `optional:`, el error es
`ConfigDataLocationNotFoundException`, y en producción ese fallo duro es deseable. Y una trampa
habitual: `configtree:` apunta a un directorio y **sin la barra final** Boot no lo trata como
árbol.

---

### 25 → 53

> Un auditor pregunta si podéis invalidar el acceso de un empleado al instante. Con JWT
> de treinta minutos, di qué contestas, qué compensaciones existen, qué cuesta cada una,
> y en qué punto la respuesta correcta es cambiar a token opaco. — [`21`
> §9](21-identidad-federada-oauth2-oidc-y-jwt.md#9-️-el-token-no-es-una-sesión-revocar-caducar-y-qué-no-meter-dentro)
> · [`20`
> §11](20-spring-security-el-mecanismo.md#11--csrf-cors-y-sesión-las-tres-que-rompen-una-api)

**⏱️ 30 segundos.** Contesto la verdad: **no, no al instante**. Con JWT de treinta minutos, su
acceso vale hasta el `exp`. Las compensaciones: tokens cortos con refresh revocable, una lista de
denegación consultada en el resource server, o token opaco con introspección. El punto en que
cambio a opaco es cuando el requisito de revocación es **regulatorio y medido en segundos**.

**🗣️ 2 minutos.** Lo que desaparece con JWT es el estado **del servidor**, no el del sistema: se
movió al token, que es una foto del momento de emisión, y el servidor cree lo que dice el papel. La
mitigación estándar y la que defiendo por defecto son tokens cortos —access de cinco a quince
minutos— con un refresh largo y revocable que vive **solo en el client**: ahí sí hay estado y botón
de revocar, y la ventana de daño pasa de ocho horas a quince minutos. Cuesta una llamada de refresh
cada pocos minutos por sesión y obliga al client a manejarla. Una lista de denegación por `jti`
consultada en cada petición cierra la ventana del todo y reintroduce exactamente el estado
compartido que el JWT quería evitar, con el agravante de ser un punto único de fallo en el camino
caliente; la acepto solo para la revocación de emergencia, no como mecanismo ordinario. Y el token
opaco es la respuesta honesta cuando la exigencia es "al instante": el IdP emite una cadena sin
contenido y `inv-api` la consulta con la `introspection-uri`, pagando una llamada de red por
petición —cacheable, pero ahí vuelve el estado— a cambio de revocar ya. Si el auditor exige
segundos y no minutos, esa llamada es el precio correcto.

**🔬 El detalle.** Con un rol retirado pasa exactamente lo mismo que con el despido: las
authorities viajan en el token y no se actualizan hasta la siguiente emisión. Dos reglas que van en
la misma conversación: **qué no va nunca en el payload** —un número de cuenta, un saldo, nada que
no quieras leer en un log de acceso; el JWT lleva identificadores y permisos, no datos de negocio—
y que un token completo no se escribe jamás en el log, del token va su `jti`. Y un efecto de
tamaño: un JWT gordo se paga en cada petición porque los claims viajan en una cabecera; uno de 8 KB
choca con el límite de Tomcat y el síntoma no es un 401 sino un **`400` sin cuerpo**.

---

### 25 → 54

> Un arquitecto propone resolver la conciliación nocturna con un bucle `@Transactional`
> dentro de un `@Scheduled`. Explícale qué le da el `JobRepository` de Spring Batch que
> ese bucle no le da, y qué le exige a cambio al `ItemReader`. — [`22`
> §3](22-spring-batch.md#3--el-chunk-leer-uno-procesar-uno-escribir-de-a-muchos) · [`22`
> §6](22-spring-batch.md#6--restart-qué-se-reanuda-y-qué-tiene-que-cumplir-tu-reader) ·
> [`16` §4](16-transacciones.md#4--propagación)

**⏱️ 30 segundos.** El `JobRepository` le da **memoria persistente**: qué se leyó, qué se escribió,
en qué chunk se cayó y por dónde retomar; su bucle no tiene nada de eso, y si se cae a mitad vuelve
a empezar o duplica. A cambio le exige que el `ItemReader` **implemente `ItemStream`**, es decir,
que guarde su posición en el `ExecutionContext` al abrirse y cerrarse.

**🗣️ 2 minutos.** Al arquitecto se lo planteo con la pregunta que su diseño no sabe responder: *se
cayó a las 02:41 con la mitad hecha, ¿ahora qué?*. Con Batch la respuesta está en dos `SELECT`:
`batch_step_execution` dice `read_count`, `write_count`, `commit_count` y `rollback_count`, y
`batch_step_execution_context` trae el `short_context` con `movementReader.read.count`, que es la
respuesta literal a "¿por dónde iba?". Con su bucle la respuesta es "mira los logs". Además el
modelo de chunk le da el reparto transaccional correcto: se lee de a un ítem, se acumula hasta el
tamaño del chunk y **se escribe el bloque dentro de una transacción**, así que el tamaño del chunk
es *cuánto trabajo estás dispuesto a repetir* — un `chunk(1)` no pierde nada y hace una transacción
por ítem, y el `ItemWriter` recibe una **lista**, que es la firma que permite un `INSERT` por lote
en vez de quinientos sueltos. La exigencia del reader es la parte que casi nadie menciona: **el
reanudado lo hace el reader, no el framework solo**; un `ItemReader` propio escrito como un
iterador vuelve a empezar y duplica.

**🔬 El detalle.** Y una precisión que evita una promesa falsa: **reanudable no es idempotente**.
Spring Batch garantiza que no vuelve a *contar* lo ya confirmado, no que tu escritura sea segura de
repetir; la granularidad del reanudado es **el chunk, no el ítem**, así que los ítems del chunk en
vuelo se vuelven a leer y a escribir y el writer tiene que tolerarlo —`upsert`, clave natural, o un
`INSERT` que choque contra una restricción única y sepa qué hacer—. Un detalle de API que delata el
código copiado de 2021: en Batch 5 el `JobRepository` **se pasa al `StepBuilder`**, y
`JobBuilderFactory` y `StepBuilderFactory` se eliminaron en la 5.0.

---

### 25 → 55

> Diseña los `JobParameters` del `inventory-reconciliation-job` de modo que se pueda
> relanzar el día que falle y **no** se pueda relanzar el día que terminó bien. Di qué
> parámetros son identificadores, cuáles no, y qué capacidad pierdes si añades un
> `run.id` con la marca de tiempo. — [`22`
> §5](22-spring-batch.md#5--jobparameters-por-qué-no-puedes-relanzar-lo-mismo-dos-veces)
> · [`L08`
> §10](l08-security-y-batch.md#10--caído-a-la-mitad-y-reanudado-las-tablas-antes-y-después)

**⏱️ 30 segundos.** Un único identificador: `business.date`. Todo lo demás —la ruta del fichero, un
flag de verbosidad— va con el tercer argumento en `false`, no identificador. Con eso, el día que
falla se relanza con los mismos parámetros y **eso es reanudar**; el día que terminó bien, el
relanzado se rechaza con `JobInstanceAlreadyCompleteException`. Un `run.id` con marca de tiempo
**destruye la reanudación**.

**🗣️ 2 minutos.** La ecuación es `JobInstance = Job + JobParameters identificadores`, y de ahí sale
todo: una instancia por fecha contable. Eso es lo que convierte "correr el job dos veces por error"
en un rechazo en vez de un doble cargo, y es la propiedad que defiendo ante quien pide poder
relanzar siempre. Porque ese `run.id` con timestamp funciona —el job corre— y lo que rompe no se ve
el día que lo pones: cada intento es una **instancia nueva**, así que el job vuelve a empezar por la
línea 1, no se salta nada, y los duplicados quedan de tu cuenta; lo único que te salvaría es el
`ON CONFLICT` del writer. Pierdes las dos cosas por las que elegiste Batch: la reanudación y la
protección contra la doble ejecución. Si de verdad hace falta volver a correr una fecha ya
completada —un reproceso autorizado—, eso no es un parámetro técnico: es una decisión con dueño, y
se hace marcando la ejecución o con un parámetro identificador explícito del tipo `reprocess.seq`,
que deja rastro.

**🔬 El detalle.** Los parámetros **no identificadores no se copian** de la ejecución anterior: al
reintentar hay que volver a pasarlos todos, incluida la ruta del fichero. Y los parámetros del job
se pasan por línea de comandos **sin `--`** —`java -jar app.jar business.date=2026-09-18`—; lo que
lleva `--` es una propiedad del `Environment` y el job no la ve: un error de un minuto que cuesta
una ventana. El caso que de verdad duele a las tres de la mañana no es
`JobInstanceAlreadyCompleteException` sino el otro: si el proceso murió de un `kill -9`, nadie
escribió el `FAILED`, la fila se queda en `STARTED` para siempre y el relanzado da
`JobExecutionAlreadyRunningException` — y su salida no es un comando de Spring, es una decisión de
operación: comprobar que el proceso está muerto y marcar la ejecución como abandonada.

---

### 25 → 56

> El fichero de entrada trae un 2 % de registros corruptos y negocio quiere que el lote
> termine igual. Decide entre `skip` y `retry`, di qué le falta a un `skipLimit(10)`
> para que descartar no sea perder datos, y qué alerta escribes. — [`22`
> §7](22-spring-batch.md#7--skip-y-retry-cuando-un-registro-malo-no-puede-tumbar-el-lote)
> · [`23`
> §9](23-actuator-y-observabilidad.md#9--prometheus-el-scrape-y-las-cuatro-señales-doradas)

**⏱️ 30 segundos.** `skip`, porque una línea mal formada falla igual las tres veces: reintentarla
solo hace que el job tarde el triple en fallar por lo mismo. Al `skipLimit(10)` le falta un
**`SkipListener`** que escriba cada descarte en una tabla de rechazados; sin él, descartar es
perder datos con permiso escrito. La alerta se escribe sobre **`skipCount` distinto de cero**, no
sobre "falló".

**🗣️ 2 minutos.** Primero corrijo la premisa, porque con un 2 % de corruptos sobre un fichero
grande el `skipLimit(10)` se agota enseguida: el límite es **global** —los descartes se cuentan
aparte en lectura, proceso y escritura, pero el tope es uno— y con sesenta mil líneas el 2 % son mil
doscientas. O el límite se dimensiona al volumen esperado, o el lote va a morir igual, más tarde y
con la mitad hecha. Y después pongo el límite donde va: **un skip es una decisión de negocio, no
una configuración**. Cargar proveedores mal formateados se descarta; un movimiento de dinero, no. El
`skipLimit` lo firma quien entiende el dato, no quien escribe el step — y eso significa que negocio
tiene que decir por escrito qué porcentaje de rechazo hace que el lote deje de ser válido, porque
ese número es el límite. Lo que entrego a cambio es la trazabilidad: cada fila descartada con su
excepción y su motivo, consultable a la mañana siguiente.

**🔬 El detalle.** Dos precisiones que se preguntan. La tolerancia no existe sin `faultTolerant()`:
sin esa llamada, `skip` y `retry` **no existen** y cualquier excepción mata el step. Y el detalle
fino del conteo: **con límite 10, es el descarte número once el que hace fallar el step**, no el
décimo. `noSkip(...)` excluye excepciones de una regla ancha —`skip(Exception.class)`
`.noSkip(FileNotFoundException.class)`: descarto todo menos que falte el fichero, que no es un dato
malo sino un problema de operación— y `noRollback(...)` es su pariente para la excepción de negocio
que no debe revertir el chunk. Sobre la alerta: las métricas de Micrometer son `spring.batch.job`,
`.job.active`, `.step`, `.item.read`, `.item.process` y `.chunk.write`, y las dos que se alertan
son **duración por encima de la ventana** y `skipCount` distinto de cero.

---

### 25 → 57

> La suite del proyecto tarda doce minutos y bloquea el pipeline. Da tu plan de ataque
> en orden, diciendo qué mides primero, qué cambio devuelve más minutos por hora
> invertida, y qué **no** harías aunque acortara la suite. — [`24`
> §6](24-testing.md#6-️-la-caché-de-contextos-aquí-se-van-los-ocho-minutos) · [`24`
> §4](24-testing.md#4--los-slices-qué-autoconfigura-cada-uno-y-qué-deja-fuera)

**⏱️ 30 segundos.** Mido primero **cuántos contextos carga la suite**, con la categoría
`org.springframework.test.context.cache` en `DEBUG`. Si ese número se parece al de clases de test,
ahí están los ocho minutos. Lo que más devuelve por hora invertida es **unificar la configuración
de test** para que la caché acierte. Lo que no haría aunque acortara la suite: cambiar
Testcontainers por H2.

**🗣️ 2 minutos.** El `TestContext` framework no levanta un contexto por clase: los guarda en una
caché estática y los reutiliza, y la clave se construye con un conjunto cerrado de parámetros —las
`classes`, los `contextCustomizers` (que incluyen `@MockitoBean`, `@MockitoSpyBean`, `@TestBean` y
`@DynamicPropertySource`), los `activeProfiles` y el `@TestPropertySource`—. Cambiar **cualquiera**
de ellos crea un contexto nuevo: añadir un `@MockitoBean` en una clase y no en otra ya son dos
contextos y dos arranques. Por eso el ataque en orden es: contar contextos, agrupar las clases que
casi comparten configuración, sustituir `@TestPropertySource` con valores distintos por un
`application-test.yaml` compartido con `@ActiveProfiles("test")`, y quitar los `@DirtiesContext`
puestos "por higiene" —cada uno cierra un contexto y lo saca de la caché—. Solo después miro si
sobran `@SpringBootTest` que podrían ser slices o tests unitarios sin contenedor. Subir
`spring.test.context.cache.maxSize` trata el síntoma: cada contexto vivo retiene su pool y su heap.

**🔬 El detalle.** Y hay una trampa de build que anula todo lo anterior: **si el build hace fork por
test, la caché no existe**, porque es una variable estática de la JVM — con el `forkMode` de
Surefire en `always` se pierde entre clases. Eso se mira antes que nada. `@TestConfiguration` no es
`@Configuration`: una `@Configuration` suelta la recoge el component scan y **contamina todos** los
contextos; una `@TestConfiguration` anidada se aplica solo ahí. Lo que no hago, aunque devolviera
minutos, es volver a H2: no es más rápido, es **otra base de datos**, y el resultado no es un test
que falla sino uno que pasa y un bug que aparece en producción.

---

### 25 → 58

> Sitúa en la escala de pruebas del curso estos cuatro encargos: validar el formato de
> un error, comprobar una consulta con `@EntityGraph`, verificar que un endpoint
> devuelve 403 sin el rol, y demostrar que el timeout del cliente HTTP funciona. Di qué
> herramienta usas en cada uno y cuál no se puede probar con un mock. — [`24`
> §4](24-testing.md#4--los-slices-qué-autoconfigura-cada-uno-y-qué-deja-fuera) · [`24`
> §10](24-testing.md#10--seguridad-resiliencia-asincronía-y-reactivo) · [`13`
> §6](13-clientes-http.md#6--errores-un-4xx-no-es-un-fallo-de-red)

**⏱️ 30 segundos.** Formato de error: `@WebMvcTest` con `MockMvc` y `jsonPath("$.title")`. Consulta
con `@EntityGraph`: `@DataJpaTest` **con Testcontainers**, contando consultas. 403 sin el rol:
`@WebMvcTest` con `@AutoConfigureMockMvc` y `spring-security-test`. Timeout del cliente HTTP: **no
se puede probar con un mock** — hace falta un stub que sepa tardar, WireMock o `MockWebServer`.

**🗣️ 2 minutos.** El cuarto es el que separa a quien ha sufrido un incidente de quien no. `MockRestServiceServer`
sustituye la `ClientHttpRequestFactory` por una falsa: verifica URI, método y cuerpo, y **no ejerce
ni el timeout ni el pool**, porque no hay socket. Un `@MockitoBean` es peor todavía: responde al
instante. Un timeout o un circuito abierto necesitan **latencia**, y la latencia solo la produce
algo que abra un puerto real. Por eso el test que "probaba el timeout" pasa en verde y el servicio
se cuelga en producción. Los otros tres tienen matices que también decido: el del formato de error
va en `@WebMvcTest` porque el slice **sí** ejecuta tu `@ControllerAdvice` y los converters —esa es
la costura que quieres probar—, aunque no detecte que el servicio real lance otra excepción. El del
`@EntityGraph` va contra Postgres real y no contra H2, porque lo que estoy probando es el SQL que
genera Hibernate. Y el del 403 exige que la cadena **corra**, no que esté configurada.

**🔬 El detalle.** Tres cosas que rompen estos tests y no son obvias. En `@WebMvcTest` los
`@Component`, `@Service` y `@Repository` normales **no se escanean**, así que el `@MockitoBean` del
servicio es obligatorio: sin él el arranque falla con `NoSuchBeanDefinitionException` dentro de un
`IllegalStateException: Failed to load ApplicationContext`. `@DataJpaTest` **reemplaza tu
`DataSource` por uno embebido** si hay uno en el classpath —`@AutoConfigureTestDatabase` trae
`replace = NON_TEST`—, y eso es lo que te mete H2 sin pedirlo; `@ServiceConnection` sobre el
contenedor lo desactiva, porque el `DataSource` ya apunta a una base de prueba. Y si moqueas el
bean anotado con `@Retry` o `@CircuitBreaker`, moqueaste **su proxy**: el patrón desapareció del
test.

---

### 25 → 59

> Da tres casos del curso en los que la suite está verde y producción está rota, con su
> corrección: el test transaccional, el proveedor moqueado y la base embebida. Di cuál
> de los tres es el más caro de descubrir tarde. — [`24`
> §8](24-testing.md#8-️-transactional-en-el-test-el-rollback-que-oculta-bugs) · [`24`
> §9](24-testing.md#9--testcontainers-y-serviceconnection-y-por-qué-no-h2)

**⏱️ 30 segundos.** El test transaccional que nunca hace commit; el proveedor moqueado que responde
al instante y no ejerce el timeout; y la base embebida que no es Postgres. **El más caro de
descubrir tarde es el tercero**, porque no falla en el despliegue: falla en producción con datos
reales y con un comportamiento que el entorno de pruebas no puede reproducir.

**🗣️ 2 minutos.** El primero: un test `@Transactional` —y `@DataJpaTest` lo está— abre una
transacción y **hace rollback al terminar**, así que lo que solo falla al confirmar —una constraint
diferida, un trigger, un `flush` que Hibernate nunca ejecutó— no ocurre ahí. Además test y código
comparten persistence context, así que los lazy loads funcionan en el test y explotan con
`LazyInitializationException` en producción; y como ya hay una transacción abierta, un método
`REQUIRED` se une a la del test y tampoco estás observando la propagación. Se corrige quitándolo
cuando lo que pruebas es el commit o la propagación, y limpiando los datos con `@Sql`. El segundo
se corrige con WireMock o `MockWebServer`. El tercero se corrige con Testcontainers y
`@ServiceConnection`, con la imagen en **tag exacto, nunca `:latest`**. Y es el más caro porque los
otros dos tienen un síntoma que aparece pronto y con un stack trace reconocible; este produce
diferencias de comportamiento —bloqueos, secuencias, `ON CONFLICT`, `jsonb`— que solo se manifiestan
con concurrencia y volumen reales, es decir, en la peor noche posible.

**🔬 El detalle.** Con `@SpringBootTest(webEnvironment = RANDOM_PORT)` el primer problema **no
aplica en absoluto**, y conviene saberlo para no limpiar de más: el servidor atiende en **otro
hilo** y la transacción del test está atada al hilo del test, así que lo que escriba el servidor se
confirma y hay que borrarlo a mano. Para lo contrario están `@Commit` y `@Rollback(false)`. El coste
honesto de Testcontainers: la primera ejecución descarga la imagen y cada arranque cuesta uno o dos
segundos; `@Container` sobre un campo **`static`** arranca el contenedor una vez por clase, sobre uno
de instancia, uno por método — así se llega a una suite de veinte minutos. Y para la asincronía, la
respuesta no es `Thread.sleep` sino Awaitility con
`await().atMost(...).untilAsserted(...)`.

---

### 25 → 60

> Son las dos de la mañana: `inv-api` responde 200 pero tarda seis segundos, y los logs
> no traen `traceId`. Da tu secuencia de diagnóstico con las herramientas del curso,
> nombrando en cada paso el endpoint o el comando y qué hipótesis descarta. — [`A03`
> §2](a03-catalogo-de-errores-y-diagnostico.md#2--índice-por-síntoma) · [`A01`
> §13](a01-cli-y-tooling-de-supervivencia.md#13--atajos-de-depuración) · [`L07`
> §11](l07-actuator-metricas-y-trazas.md#11--threaddump-en-plena-saturación)

**⏱️ 30 segundos.** Primero descarto que sea yo: `/actuator/metrics/http.server.requests` por `uri`
para ver si el p95 subió en un endpoint o en todos. Después `/actuator/threaddump`, que contesta en
treinta segundos dónde están parados los hilos. En paralelo, el `traceId` que falta es un síntoma en
sí mismo. Y `/actuator/loggers` por `POST` para subir niveles **sin reiniciar**.

**🗣️ 2 minutos.** El `threaddump` es el que discrimina, y la lectura es binaria. Hilos en
`sun.nio.ch.SocketDispatcher.read0` significa "espero bytes de otro": falta un timeout o el
proveedor es lento — descarta que el problema sea mío. Hilos en `TIMED_WAITING` dentro de mi propio
proceso significa que un límite **mío** está frenando: semáforo del bulkhead, pool de conexiones,
lock — descarta que el problema sea del proveedor. Y hilos esperando en
`PoolingHttpClientConnectionManager.lease` es cola del pool de salida. Subir
`server.tomcat.threads.max` empeora el primero y no cambia nada en el segundo, así que la
distinción no es académica. El volcado se lee filtrando por mi paquete —`.stackTrace[] | select(
.className | startswith("com.invlab"))`, agrupado con `sort | uniq -c | sort -rn`—, porque un
volcado de doscientos hilos no se lee: se cuenta. Y se toman **dos o tres volcados separados por
unos segundos**: si los mismos hilos siguen en el mismo frame, hay un bloqueo; si cambian, hay
lentitud.

**🔬 El detalle.** El `traceId` ausente tiene tres causas y conviene descartarlas en orden: el
`logging.pattern.correlation` no está puesto, el salto de hilo se comió el MDC —un `@Async` sin
`TaskDecorator`—, o la petición entró por un camino sin instrumentar. Con `%X{traceId:-}` el `:-`
evita imprimir el literal cuando falta, así que un hueco ahí significa *no hubo traza*, no *se
perdió el formato*. El índice por síntoma de `A03` es el atajo cuando tienes el texto delante y no
sabes de qué familia es. Y una advertencia operativa: `threaddump` es la primera parada de un "se
quedó colgado"; **`heapdump` no es un endpoint más** —pausa la JVM mientras escribe un fichero del
tamaño del heap, con datos reales de clientes dentro—, y por eso no está en el
`exposure.include`.

---

## Lab L00 — La idea del laboratorio

### L00 → 1

> Enuncia la regla que decide qué entra en el laboratorio y qué se queda en el capítulo.

**⏱️ 30 segundos.** Al laboratorio va lo que solo se entiende viéndolo fallar en runtime;
lo que se entiende leyendo se queda en el capítulo.

**🗣️ 2 minutos.** Es la contraparte pedagógica de la regla económica de los cursos de
nube. Un tema entra si el fallo es silencioso y solo se ve ejecutando, si el síntoma está
en un log o un stack trace que hay que aprender a leer, si depende de infraestructura real
que un mock no reproduce, o si es una costura entre tu código y el contenedor. Si no
cumple ninguna, un lab no añade nada sobre el capítulo.

**🔬 El detalle.** Las cuatro condiciones, cada una con su ejemplo en la serie: el fallo es
**silencioso** y solo se ve ejecutando (el `@Transactional` que no hace rollback, `L04`);
el síntoma está en un **log o un stack trace** que hay que aprender a leer (pool de Hikari
agotado, `LazyInitializationException`, `L04`); depende de **infraestructura real** que un
mock no reproduce (latencia del proveedor, TTL de Redis, `L05` y `L06`); o es una
**costura** entre tu código y el contenedor (orden de filtros, informe de condiciones,
`L01` y `L03`). Basta con cumplir una.

---

### L00 → 2

> Da dos ejemplos de mecanismos del curso que **no** necesitan lab, y di por qué.

**⏱️ 30 segundos.** La diferencia entre `@Primary` y `@Qualifier` (`03`) y la precedencia
de propiedades (`07`): la primera no necesita ejecutarse en absoluto, y la segunda se
demuestra en diez minutos dentro de otro lab.

**🗣️ 2 minutos.** La prueba es preguntarse qué ves ejecutando que no vieras leyendo. Con
los qualifiers, nada: es una regla de resolución que se entiende con una tabla. Con la
precedencia sí hay algo que ver —cuál gana— pero cabe en una sección de `L02`, no en un
lab propio. En cambio el rollback que no ocurre por self-invocation **hay** que verlo: el
dato queda grabado y no hay ninguna señal.

---

### L00 → 3

> ¿Por qué el curso excluye Kafka a pesar de que en banca está en todas partes?

**⏱️ 30 segundos.** Porque la parte difícil de Kafka no es el `@KafkaListener`, que se
aprende en una tarde, sino las garantías de entrega, el orden y la idempotencia — y eso es
diseño, no framework.

**🗣️ 2 minutos.** Levantar un broker local y consumir un mensaje enseña la API. Lo que de
verdad se pregunta en una entrevista —exactly-once, reproceso, outbox, orden por
partición, qué pasa cuando el consumidor falla a la mitad— no se aprende con un contenedor,
se aprende razonando sobre el diseño. Por eso vive en el corpus de arquitectura y aquí solo
se nombra. Es la exclusión que más sorprende y la que mejor ilustra la doctrina.

---

### L00 → 4

> ¿Por qué se excluye R2DBC del lab pero no del temario?

**⏱️ 30 segundos.** Porque practicarlo exigiría un segundo modelo de datos completo para
una tecnología que probablemente no vas a usar, mientras que su veredicto —qué soporta y
qué no— sí hay que saberlo.

**🗣️ 2 minutos.** El capítulo `11` lo explica con honestidad: R2DBC existe, no es JPA, y
la ausencia de un ORM maduro sobre él es precisamente uno de los argumentos del capítulo
`12` para no irse a reactivo en un CRUD transaccional de banca. Eso se explica; montarlo
solo añadiría horas sin cambiar la conclusión.

**🔬 El detalle.** El mismo criterio ordena el catálogo entero de exclusiones: Spring Cloud
queda fuera por ser capa de plataforma y no de framework, Kubernetes porque es otro
laboratorio entero —y está en los cursos de AWS y GCP—, las bases en clúster porque son
diseño de datos, un IdP real en la nube porque Keycloak local da exactamente el mismo
aprendizaje (`issuer-uri`, JWKS, claims) en `L08`, y GraalVM native más allá de una
compilación, que queda como 🔥 opcional de `L09`.

---

### L00 → 5

> `docker compose up -d` no levanta nada en este proyecto. ¿Por qué, y cómo se levanta
> Postgres?

**⏱️ 30 segundos.** Porque todos los servicios declaran `profiles:`, y un servicio con
perfil no arranca salvo que se pida. Postgres se levanta con
`docker compose --profile db up -d`.

**🗣️ 2 minutos.** Es deliberado y sorprende la primera vez. La alternativa —que todo
arranque siempre— significaría cargar siete contenedores y unos 2 GB de RAM para probar un
endpoint que solo necesita la base. Con perfiles, cada lab declara exactamente lo suyo, y
la tabla de `L00` §8 dice qué deja levantado cada uno.

**🔬 El detalle.** Los perfiles declarados son `db`, `cache`, `nosql`, `ext`, `obs` y
`sec`, y cada lab levanta solo el suyo: `L01` y `L02` ninguno, `L04` `db` y `nosql`, `L05`
`db` y `ext`, `L06` `db` y `cache`, `L07` `db` y `obs`, `L08` `db` y `sec`, `L09` ninguno.
El argumento tiene números: Postgres pide unos 150 MB de RAM, Keycloak alrededor de 500
MB, y Prometheus con Grafana otros 300 MB — levantar los siete perfiles a la vez en una
máquina de 8 GB con el IDE abierto se nota.

---

### L00 → 6

> ¿Qué aporta `name: inv-lab` en el `docker-compose.yml` y qué se rompe sin él?

**⏱️ 30 segundos.** Fija el nombre del proyecto de Compose. Sin él, Compose usa el nombre
del directorio, y los contenedores y volúmenes cambian de nombre según dónde hayas clonado.

**🗣️ 2 minutos.** Eso rompe dos cosas: los comandos de limpieza con `-p inv-lab` dejan de
encontrar los recursos, y dos copias del repositorio en carpetas distintas crean dos juegos
de volúmenes sin que te enteres. Con el nombre fijo, la limpieza de `L09` es determinista y
funciona desde cualquier directorio.

---

### L00 → 7

> ¿Por qué ningún tag de imagen es `:latest`, si es un lab local que no cuesta dinero?

**⏱️ 30 segundos.** Porque `latest` hace el lab irreproducible: el día que el mantenedor
publique una versión con otro comportamiento, el lab deja de funcionar y el error no
apunta a la causa.

**🗣️ 2 minutos.** No es una cuestión de dinero sino de que el curso enseña exactamente eso:
fijar versiones. Un `latest` en un `docker-compose.yml` es el mismo error que un rango de
versiones en un `pom.xml` — funciona hasta que alguien publica, y entonces rompe en la
máquina de otro y no en la tuya. Los tags de esta serie se verificaron uno a uno contra el
registry el 17 de septiembre de 2026.

**🔬 El detalle.** Los tags exactos de la serie, verificados uno a uno contra el registry
ese día: `postgres:17.11-alpine`, `redis:8.6.6-alpine`, `mongo:8.0.32-noble`,
`wiremock/wiremock:3.13.2-alpine`, `prom/prometheus:v3.13.3`, `grafana/grafana:13.0.9` y
`quay.io/keycloak/keycloak:26.7.4`. Es el mismo error que un rango de versiones en un
`pom.xml`: funciona hasta que alguien publica, y entonces rompe en la máquina de otro y no
en la tuya.

---

### L00 → 8

> ¿Qué diferencia hay entre `docker compose down` y `docker compose down -v`, y cuál es
> el síntoma de olvidar la segunda?

**⏱️ 30 segundos.** `-v` borra además los volúmenes con nombre. Sin él, los datos
sobreviven, y al volver a levantar encuentras el estado de la sesión anterior.

**🗣️ 2 minutos.** Es la fuente número uno de "pero si yo borré eso": una migración de
Flyway que ya estaba aplicada, unos datos de prueba que reaparecen, un esquema viejo que
choca con la migración nueva. El síntoma engaña porque parece un bug de la aplicación. La
disciplina del curso es la misma que la de los cursos de nube con la factura: la limpieza
no se da por buena porque el comando no fallara, se da por buena porque `docker volume ls`
y `docker ps -a` salen vacíos.

**🔬 El detalle.** El comando completo de la serie es `docker compose -p inv-lab down -v
--remove-orphans`, y cada parte hace falta: `-v` borra los volúmenes con nombre,
`--remove-orphans` elimina contenedores de perfiles que ya no están declarados —que si no
se quedan corriendo, invisibles para `docker compose ps`— y `-p inv-lab` apunta al
proyecto por nombre, así que funciona aunque no estés en el directorio del
`docker-compose.yml`. La verificación son dos listados vacíos: `docker volume ls | grep
inv-lab` y `docker ps -a | grep inv-lab`.

---

### L00 → 9

> ¿Para qué sirve el `healthcheck` de Postgres si el contenedor ya arrancó?

**⏱️ 30 segundos.** Porque "contenedor arrancado" y "base aceptando conexiones" son dos
momentos distintos, separados por varios segundos.

**🗣️ 2 minutos.** `pg_isready` responde cuando el servidor acepta conexiones de verdad. En
esa ventana intermedia, una aplicación que arranque a la vez falla al conectar con un error
que parece de configuración y no lo es. Es la causa de la mitad de los "en mi máquina no
arranca" con Compose, y la razón de que los labs esperen al health antes de arrancar
`inv-api`.

**🔬 El detalle.** El healthcheck concreto es `pg_isready -U inv_lab -d inv_lab`, con
`interval: 5s` y `retries: 10`; el de Redis es `redis-cli ping`. Lo que comprueban no es
que el proceso exista sino que el servicio **acepta conexiones**, y esa es toda la
diferencia: en la ventana intermedia tu aplicación fallaría al conectar con un error que
parece de configuración.

---

### L00 → 10

> ¿Por qué WireMock se publica en el puerto 8090 y Keycloak en el 8180?

**⏱️ 30 segundos.** Porque los dos escuchan en 8080 dentro del contenedor, y 8080 lo ocupa
`inv-api` en tu máquina.

**🗣️ 2 minutos.** El mapeo `"8090:8080"` publica hacia fuera el puerto que tú eliges sin
cambiar nada dentro del contenedor. El reparto de la serie es `inv-api` en 8080, su
Actuator en 8081, WireMock en 8090, Keycloak en 8180, más los puertos nativos de Postgres,
Redis, Mongo, Prometheus y Grafana. Fijarlo en `L00` evita que cada lab invente el suyo.

**🔬 El detalle.** El reparto completo de puertos de la serie, que se fija aquí para que
ningún lab invente el suyo: `inv-api` en 8080, su Actuator en 8081, WireMock en 8090,
Keycloak en 8180, más los nativos de Postgres (5432), Redis (6379), Mongo (27017),
Prometheus (9090) y Grafana (3000). La sintaxis `"8090:8080"` es *puerto del host : puerto
del contenedor*, así que lo que cambia es lo de fuera; dentro del contenedor no se toca
nada.

---

### L00 → 11

> Las credenciales del lab son `inv_lab`/`inv_lab`. ¿Es eso una mala práctica? Justifica
> la respuesta en los dos sentidos.

**⏱️ 30 segundos.** En este contexto no: es un Postgres en `localhost` que muere con un
comando. A un centímetro de tu máquina sí lo sería, y el curso lo dice explícitamente.

**🗣️ 2 minutos.** Simular rigor con una contraseña de veinte caracteres en un lab local no
enseña nada y da una falsa sensación de seguridad. Lo que sí enseña es saber **por qué**
cambia el juicio: en cuanto el servicio escucha fuera de `localhost`, o en cuanto la
credencial se versiona, entra el capítulo `07` —los secretos no van en el `yml`— y el `21`
—dónde viven entonces—. La respuesta de entrevista buena distingue el contexto en lugar de
recitar la regla.

---

### L00 → 12

> Después de `down -v`, ¿qué queda todavía ocupando disco en tu máquina?

**⏱️ 30 segundos.** Las imágenes descargadas, el caché de Maven en `~/.m2` y el directorio
`target/` del proyecto.

**🗣️ 2 minutos.** `down -v` se lleva contenedores, red y volúmenes con nombre, que es lo
que contiene estado del lab. Las imágenes son del orden de 2 GB y se limpian aparte con
`docker image prune` si quieres el espacio; el caché de Maven conviene conservarlo porque
es lo que hace que el siguiente arranque no vuelva a descargar medio Maven Central.
Saberlo es parte del contrato: una limpieza que no dice qué deja no es una limpieza
verificada.

**🔬 El detalle.** Los números: la serie completa ocupa del orden de **2 GB** entre
imágenes y volúmenes, y con todo levantado consume alrededor de **2 GB de RAM**. `down -v`
se lleva contenedores, red y volúmenes con nombre —lo que contiene estado del lab—; las
imágenes se limpian aparte con `docker image prune`, y el caché de `~/.m2` conviene
conservarlo porque es lo que evita volver a descargar medio Maven Central en el siguiente
arranque.

---

## Lab L01 — Esqueleto, CLI y autoconfiguración

### L01 → 1

> Generas el proyecto por web, por `curl` a la API y con el CLI. ¿En qué se diferencian los tres artefactos resultantes, y cuál de las tres formas pondrías en una plantilla corporativa?

**⏱️ 30 segundos.** En nada: las tres llaman al mismo servicio, Spring Initializr, y
producen el mismo proyecto — incluida la parte incómoda, que ninguna de las tres genera el
baseline del curso. La diferencia está en qué puedes automatizar, y en una plantilla
corporativa va el `curl`.

**🗣️ 2 minutos.** La web es un cliente del servicio y sirve para **descubrir** qué
dependencias existen; su problema es que la versión de Boot sale de un desplegable que hoy
solo ofrece líneas 4.x, así que un proyecto generado "rápido" sale sobre 4.1.1 sin que nadie
lo decida. El CLI (`spring init`) hace exactamente la misma llamada HTTP —y recibe el mismo
`400` si le pides 3.5.16—, con la ventaja de `--list` y el costo de instalar SDKMAN y el CLI
en cada máquina. El `curl` a `start.spring.io/starter.tgz` no exige instalar nada y cabe en
un script versionado; y como el servicio no acepta el baseline, lo que va al repositorio no
es solo la generación: es **generar y después corregir el `pom.xml`** en el mismo script,
que es donde la versión de Boot acaba escrita y revisable en un pull request.

**🔬 El detalle.** Los identificadores de `dependencies` (`web`, `actuator`) no son
`artifactId` —y se nota justo aquí: el id corto `web` sigue llamándose igual, pero el
artefacto que genera en 4.x es `spring-boot-starter-webmvc`—. El catálogo se consulta con
`curl -s -H 'Accept: application/json' https://start.spring.io/metadata/client`; sin la
cabecera `Accept` el servicio devuelve HTML. Dos parámetros que cambian el resultado y se
olvidan: `baseDir`, sin el cual el tar se desparrama en el directorio actual, y `type`,
donde `maven-build` devuelve solo el `pom.xml` en vez del esqueleto completo.

---

### L01 → 2

> ¿Qué hace `./mvnw` que `mvn` no hace, y qué se rompe en un equipo que no versiona el wrapper?

**⏱️ 30 segundos.** `./mvnw` descarga y usa **la versión exacta de Maven declarada en el
repositorio** (`.mvn/wrapper/maven-wrapper.properties`); `mvn` usa lo que haya en el `PATH`
de esa máquina. Sin wrapper, la versión del build la decide el accidente de cada equipo.

**🗣️ 2 minutos.** El wrapper son tres ficheros que se versionan: `mvnw`, `mvnw.cmd` y
`.mvn/wrapper/maven-wrapper.properties`, donde el `distributionUrl` fija la versión. Es el
mismo principio de "nunca `latest`" aplicado a la herramienta de build: si el build es
reproducible en tu máquina y no en el agente de CI, la primera sospecha es que corren
Mavens distintos. El síntoma típico es "solo falla en el pipeline", que quema horas porque
nadie mira la versión de la herramienta. Como efecto lateral útil, el wrapper elimina el
requisito de instalar Maven: un `git clone` y `./mvnw package` bastan.

---

### L01 → 3

> En el `pom.xml` generado nadie escribió la versión de Tomcat. ¿Quién la fija y con qué comando la lees sin abrir el código de Boot?

**⏱️ 30 segundos.** La fija el BOM, `spring-boot-dependencies`, que se hereda a través de
`spring-boot-starter-parent`. Se lee con `./mvnw -q help:effective-pom`.

**🗣️ 2 minutos.** El `<parent>` con `spring-boot-starter-parent:3.5.16` hereda a su vez de
`spring-boot-dependencies`, que es una sección `dependencyManagement` con la versión exacta
de unas 250 librerías probadas en conjunto contra esa release. Por eso las dependencias del
`pom.xml` no llevan `<version>`: la omisión significa "la que el BOM haya probado".
`help:effective-pom` imprime el POM ya resuelto —el tuyo más el parent más el BOM—, que es la
respuesta documental a "¿de dónde salió esta versión?". Para el otro lado de la pregunta
—qué versión **ganó** cuando hay conflicto— el comando es `./mvnw dependency:tree`.

**🔬 El detalle.** Para sobreescribir una versión del BOM no se toca la dependencia: se
redefine la propiedad que el BOM usa, en tu `<properties>`. Y cuando tu empresa te impone un
`<parent>` corporativo, el BOM se importa con `<type>pom</type><scope>import</scope>`, lo que
trae las versiones pero **no** la configuración de plugins del starter-parent: el
`spring-boot-maven-plugin` hay que declararlo a mano.

---

### L01 → 4

> ¿Qué diferencia hay entre `-Dspring-boot.run.arguments` y `-Dspring-boot.run.jvmArguments`, y qué pasa exactamente si pones `-Xmx256m` en la primera?

**⏱️ 30 segundos.** La primera pasa argumentos **a la aplicación** (llegan a
`SpringApplication.run` como argumentos de línea de comandos); la segunda pasa opciones **a la
JVM** hija. `-Xmx256m` en `arguments` no da error: Spring lo ignora y tu límite de heap nunca
se aplica.

**🗣️ 2 minutos.** `spring-boot:run` arranca la aplicación en una JVM aparte (`fork` activo por
defecto desde Boot 2.2), así que hay dos destinos posibles para cualquier opción. Lo que va en
`arguments` se convierte en una property de la fuente de mayor precedencia: por eso
`-Dspring-boot.run.arguments="--server.port=9090"` gana sobre el `application.properties` sin
tocar el fichero. Lo que va en `jvmArguments` configura memoria, agentes o flags `-XX:`. El
fallo silencioso es el peor caso del par: pones un límite de heap, no salta ninguna
advertencia, y crees que estás probando con 256 MB cuando corres con el cuarto de tu RAM.
El atajo `-Dspring-boot.run.profiles=local` existe para no escribir el argumento completo.

---

### L01 → 5

> `./mvnw spring-boot:run` y `java -jar target/inv-api-0.0.1-SNAPSHOT.jar` no arrancan el mismo proceso. Nombra las dos diferencias que importan al diagnosticar.

**⏱️ 30 segundos.** El classpath y el `repackage`. `spring-boot:run` usa un classpath
explotado —`target/classes` más jars del repositorio local— y **no** pasa por el empaquetado;
`java -jar` usa el jar ejecutable, con las dependencias anidadas en `BOOT-INF/lib` y el
classloader del `JarLauncher`.

**🗣️ 2 minutos.** La consecuencia práctica es una regla de diagnóstico: si algo funciona con
`spring-boot:run` y falla con `java -jar`, la causa casi siempre es un recurso que estaba en
`target/classes` y no entró en el jar, o un orden de classpath distinto. Por eso `java -jar`
es la forma más fiel a producción que hay en el lab y la que se usa para todo lo que se vaya a
diagnosticar. El IDE es una tercera variante, todavía menos representativa: classpath
explotado ordenado por el propio IDE y, si hay DevTools, un segundo classloader que recarga
clases. El ciclo de edición es más corto y la fidelidad, menor.

**🔬 El detalle.** Con `java -jar`, la posición del flag importa:
`-Dspring.profiles.active=local` es una propiedad de sistema y va **antes** de `-jar`, mientras
que `--spring.profiles.active=local` es un argumento de la aplicación y va **después** del
nombre del jar. Los dos funcionan; invertirlos, no.

---

### L01 → 6

> En tu log aparece dos veces `Tomcat started on port …` con números distintos. ¿Por qué, y qué propiedad lo provoca?

**⏱️ 30 segundos.** Porque hay dos contextos: el de la aplicación en 8080 y el de gestión de
Actuator en 8081. Lo provoca `management.server.port=8081`.

**🗣️ 2 minutos.** Cuando `management.server.port` difiere de `server.port`, Boot crea un
**contexto hijo** con su propio servidor embebido para los endpoints de Actuator. En el log
aparece primero el de gestión y después el principal, y ver las dos líneas es la confirmación
visual de que la separación funcionó. La razón de hacerlo es operativa: el puerto de
diagnóstico no se publica en el mismo sitio que el tráfico de negocio, así que el balanceador
expone 8080 y la red interna alcanza 8081. Dos consecuencias que se preguntan: un `curl` al
health contra 8080 devuelve 404, y `/actuator/conditions` trae **dos** contextos en su JSON,
que hay que filtrar por nombre para no mezclarlos.

**🔬 El detalle.** Hay dos momentos distintos en el log y conviene no confundirlos:
`Tomcat initialized with port 8080` crea el conector, y `Tomcat started on port 8080` abre el
socket. Entre los dos ocurre el `refresh()` entero del contexto. Un arranque que revienta a
mitad deja el primero en el log y no el segundo.

---

### L01 → 7

> ¿`--debug` sube el nivel de log de tu aplicación? Da la versión precisa de qué hace.

**⏱️ 30 segundos.** No. `--debug` activa el **`ConditionEvaluationReport`** —el informe de
condiciones de la autoconfiguración— y lo imprime al terminar el arranque. Subir el nivel de
log es `logging.level.root=DEBUG`, que es otra cosa.

**🗣️ 2 minutos.** Es una sobregeneralización clásica porque la palabra coincide con el nivel
de log. Lo que `--debug` produce son los cuatro bloques del informe: `Positive matches`
(qué se aplicó y por qué), `Negative matches` (qué no se aplicó y qué condición falló),
`Exclusions` (lo que alguien desactivó explícitamente) y `Unconditional classes` (lo que se
aplica sin condición). Son entre mil y dos mil líneas incluso en una aplicación con dos
starters, así que en la práctica se redirige a fichero —`--debug 2>&1 | tee
target/startup-debug.log`— y se filtra con `grep`. El `2>&1` no es opcional: si el arranque
falla, la traza puede salir por `stderr` y el `tee` se perdería justo la parte interesante.

---

### L01 → 8

> Del informe de condiciones, ¿qué bloque consultas para saber por qué **no** tienes un bean que esperabas, y cuál para saber por qué sí tienes uno que no pediste?

**⏱️ 30 segundos.** Para el bean que falta, `Negative matches`, que dice qué condición falló.
Para el bean que sobra, `Positive matches`, que dice qué condición se cumplió.

**🗣️ 2 minutos.** `Negative matches` suele ser el más útil de los dos, porque responde la
pregunta que te tiene atascado: falta una clase en el classpath, falta una propiedad, o ya
existe un bean tuyo que hizo fallar un `@ConditionalOnMissingBean`. `Positive matches` es el
que resuelve el caso del `DataSource` fantasma: te nombra la autoconfiguración y la condición
exacta que la disparó. Y hay un tercer bloque que se lee poco, `Exclusions`, que es donde
compruebas que la exclusión que escribiste tuvo efecto —la diferencia entre "creo que lo
quité" y "lo quité"—.

**🔬 El detalle.** El mismo informe está en caliente en `/actuator/conditions`, en JSON, que
es lo cómodo cuando la aplicación ya está arriba y no puedes reiniciarla. Se filtra con `jq`
sobre `.contexts["inv-api"].positiveMatches` o `.negativeMatches`, y `| keys | length` da una
cifra que se compara antes y después de un cambio, que es como se demuestra que el cambio hizo
algo.

---

### L01 → 9

> Añades `spring-boot-starter-jdbc` y el driver de H2, y aparece un `DataSource`. ¿Qué condición concreta lo creó, y por qué apareció además un componente `db` en `/actuator/health`?

**⏱️ 30 segundos.** Lo creó el `@ConditionalOnClass` de `DataSourceAutoConfiguration`, que se
cumple porque el starter puso `javax.sql.DataSource` en el classpath; como no hay
`spring.datasource.url`, la `EmbeddedDatabaseCondition` decidió una base en memoria. El `db`
del health lo añadió `DataSourceHealthContributorAutoConfiguration`, condicionada al bean
anterior.

**🗣️ 2 minutos.** El punto pedagógico es que **nadie pidió una base de datos**: alguien puso
un driver en el classpath, y para Boot eso es una declaración de intenciones. El segundo punto
es el encadenamiento: una autoconfiguración registra un bean y otras se condicionan con
`@ConditionalOnBean` sobre él, así que de una dependencia salen un `DataSource`, un pool de
Hikari, un health indicator y un `PlatformTransactionManager`. Es decir, un `@Transactional`
en ese proyecto ya haría algo contra una base en memoria sin que nadie lo hubiera decidido.
El riesgo real de la base embebida es que la aplicación arranca "bien" apuntando a la nada y
el fallo aparece cuando alguien busca datos que se evaporaron al reiniciar.

**🔬 El detalle.** El procedimiento completo para ir del síntoma a la línea culpable son tres
comandos: `/actuator/health` da el síntoma, `/actuator/conditions` filtrado por `DataSource`
da la autoconfiguración y su condición, y `./mvnw dependency:tree` es el único de los tres que
identifica **qué dependencia** trajo la clase —los otros dos ven el classpath, no su origen—.

---

### L01 → 10

> Declaras tu propio `ObjectMapper`. ¿Qué frase exacta esperas encontrar en `Negative matches`, y qué demuestra sobre la autoconfiguración?

**⏱️ 30 segundos.** `JacksonAutoConfiguration...#jacksonObjectMapper: Did not match:
@ConditionalOnMissingBean (types: com.fasterxml.jackson.databind.ObjectMapper ...) found beans
of type ... objectMapper`. Demuestra que **tu bean gana** y que no hiciste falta excluir nada.

**🗣️ 2 minutos.** Lo contraintuitivo es que la línea diga `Did not match` y aun así todo
funcione: la autoconfiguración **se apartó**, que es justo lo que se espera de ella. Funciona
porque las autoconfiguraciones se procesan después de tus propias `@Configuration`, así que
cuando se evalúa la condición tu bean ya está registrado. Esa línea del informe es además la
prueba documental que enseñas en un code review a quien propone
`exclude = JacksonAutoConfiguration.class` para cambiar el formato de las fechas: excluir
tiraría también los `HttpMessageConverter` y el resto de la configuración de Jackson, cuando
bastaba con declarar el bean —o, mejor aún, con un `Jackson2ObjectMapperBuilderCustomizer`,
que personaliza sin sustituir nada—.

**🔬 El detalle.** `SearchStrategy: all` en el mensaje significa que la condición miró el
contexto completo incluyendo la jerarquía, lo que importa en este lab porque Actuator corre
en un contexto hijo. Y el bean aparece nombrado como `objectMapper` porque el nombre de un
`@Bean` es, por defecto, el nombre del método.

---

### L01 → 11

> Nombra las dos formas de excluir `DataSourceAutoConfiguration` y di qué ocurre si excluyes por nombre una clase que no es una autoconfiguración.

**⏱️ 30 segundos.** `@SpringBootApplication(exclude = DataSourceAutoConfiguration.class)` y la
propiedad `spring.autoconfigure.exclude=...` con el nombre completamente cualificado. Si
nombras algo que no es una autoconfiguración, **el arranque falla** con
`The following classes could not be excluded because they are not auto-configuration classes`.

**🗣️ 2 minutos.** Hay una tercera variante, `excludeName`, que acepta la cadena y sirve
cuando la clase no está en tu classpath de compilación. La diferencia que importa es de
verificación: con `exclude` la clase la comprueban el compilador y el IDE, así que un cambio
de paquete rompe el build y te enteras; con la propiedad no la comprueba nadie hasta el
arranque. El peligro adicional de la propiedad es que se puede activar por perfil, y una
exclusión que solo existe en un entorno es una diferencia de comportamiento que nadie ve
leyendo el código. Y la regla de fondo: excluir es la segunda mejor respuesta casi siempre.
Si lo que quieres es cambiar cómo se configura algo, declara tu bean; excluir es para cuando
quieres que **no exista nada**.

**🔬 El detalle.** El fallo por excluir algo que no es autoconfiguración es de los mejores
mensajes de Boot, porque nombra la clase concreta. Y hay una trampa práctica: si borras la
dependencia que traía la clase pero dejas el `exclude`, lo que obtienes no es un error de
arranque sino un error de **compilación**, y cuesta treinta segundos entender por qué.

---

### L01 → 12

> El arranque falla con un bloque `Description:` y otro `Action:`. ¿Quién escribe esos dos bloques, y qué haces cuando no aparecen?

**⏱️ 30 segundos.** Los escribe un `FailureAnalyzer`, que reconoció la excepción y la tradujo.
Cuando no aparecen, es que no hay analizador para ese fallo: entonces se baja al **último
`Caused by:`** de la cadena, que es la excepción original.

**🗣️ 2 minutos.** La ausencia de stack trace es información, no una carencia: significa que
Boot identificó el fallo y te está dando la respuesta ya masticada, y el bloque `Action:` —el
que la gente se salta— suele contener la salida concreta. El ejemplo canónico es el puerto
ocupado: `Web server failed to start. Port 8080 was already in use`, con la acción de matar al
otro proceso o mover el puerto. Lo que el analizador no dice es **quién** ocupa el puerto: eso
es `lsof -i :8080 -sTCP:LISTEN`, y el `kill` va sin `-9` para que el apagado sea ordenado.
Cuando no hay analizador, la primera excepción es casi siempre el envoltorio del contenedor y
no dice nada útil; la información está abajo del todo.

**🔬 El detalle.** Puedes escribir tu propio `FailureAnalyzer` y declararlo en
`META-INF/spring/org.springframework.boot.autoconfigure.AutoConfiguration.imports`; en una
librería corporativa es una cortesía enorme, porque convierte un stack trace de cincuenta
líneas en una frase accionable para veinte equipos.

---

### L01 → 13

> El fallo de los dos `Clock` no habría ocurrido si el parámetro del constructor se hubiera llamado de otra manera. ¿Por qué?

**⏱️ 30 segundos.** Porque el contenedor resuelve **por tipo primero y usa el nombre como
desempate**. Con dos beans `Clock` y un parámetro llamado `clock`, el nombre coincide con uno
de los dos y el empate se resuelve; con cualquier otro nombre, hay dos candidatos y falla.

**🗣️ 2 minutos.** El mensaje es
`Parameter 2 of constructor in ... required a single bean, but 2 were found`, y detrás hay una
`NoUniqueBeanDefinitionException`. Que un renombrado de parámetro cambie el resultado es
exactamente el matiz que separa a quien entiende la resolución de quien memorizó "`@Autowired`
inyecta por tipo": inyecta por tipo, sí, y cuando hay varios candidatos mira el nombre. Las
tres salidas que ofrece el `Action:` son `@Primary` —elige un ganador global—, `@Qualifier`
—elige en el punto de inyección— y aceptar `List<Clock>`. Para un registro contable la buena
es `@Qualifier("utcClock")`, porque documenta la decisión donde se toma.

**🔬 El detalle.** Depender del nombre del parámetro es frágil por otra razón: el nombre solo
sobrevive al compilado si se compila con `-parameters`, que el `spring-boot-starter-parent`
activa por ti. Con otro build sin ese flag, el mismo código deja de resolver. Y ojo con el
`import`: `org.springframework.beans.factory.annotation.Qualifier`, no el de `jakarta.inject`.

---

### L01 → 14

> Terminas el lab y corres `./mvnw clean`. ¿Qué sigue ocupando disco en tu máquina por culpa de este lab, y por qué no se borra?

**⏱️ 30 segundos.** El caché de Maven en `~/.m2/repository` —entre 300 y 600 MB—, el proyecto
`inv-api` en sí, y el CLI si lo instalaste con SDKMAN. `./mvnw clean` solo borra `target/`,
que es lo local al proyecto y se rehace con un `package`.

**🗣️ 2 minutos.** `~/.m2/repository` no es del lab: es el caché de **tu usuario**, compartido
por todos tus proyectos, y borrarlo para "limpiar" obliga a redescargar cientos de megas la
próxima vez que compiles cualquier cosa. Si de verdad necesitas el espacio, se borra la rama
concreta (`rm -rf ~/.m2/repository/org/springframework/boot/...`), no el directorio entero.
El proyecto se conserva a propósito porque `L02` parte exactamente de este estado. Y lo que
**no** queda es igual de importante: ningún contenedor, ninguna imagen y ningún volumen,
porque `L01` no levanta nada; `docker compose ps` no lista nada y nunca listó nada.

---

### L01 → 15

> Pides a `start.spring.io` un proyecto con `bootVersion=3.5.16` y responde `400`. ¿Qué dice exactamente el mensaje, qué política del servicio hay detrás, y qué tres cambios tienes que hacer a mano en el `pom.xml` generado para quedarte en el baseline del curso?

**⏱️ 30 segundos.** Dice
`Invalid Spring Boot version '3.5.16', Spring Boot compatibility range is >=4.0.0`. Detrás
está la política de que el Initializr solo sirve líneas con soporte open source vigente, y
3.5 lo perdió el 30 de junio de 2026. Los tres cambios son: parent a `3.5.16`,
`spring-boot-starter-webmvc` → `spring-boot-starter-web`, y los dos starters de test
(`-webmvc-test` y `-actuator-test`) → el único `spring-boot-starter-test`.

**🗣️ 2 minutos.** Que sea un `400` y no un `404` ya dice dónde está el problema: el servicio
entendió la petición y rechazó **un valor**. El catálogo lo confirma desde el otro lado —
`/metadata/client` da `default: 4.1.1.RELEASE` y ni un solo `3.5.x`—, así que el
procedimiento real es generar con los valores por defecto y bajar el proyecto a mano. El
`<java.version>21</java.version>` sí se respeta y no se toca. El cambio del parent es el que
manda: arrastra el BOM entero, y con él unas 250 librerías. Los dos renombrados no son
cosmética: si dejas los nombres de 4.x sobre el parent 3.5.16, Maven falla con
`Could not find artifact org.springframework.boot:spring-boot-starter-webmvc:jar:3.5.16`.
Y la verificación no es leer el fichero: es `./mvnw dependency:tree` y comprobar que
`spring-web` resuelve a `6.2.19` y Tomcat a la línea 10.1.

**🔬 El detalle.** Es la primera factura concreta de trabajar sobre una línea sin soporte
OSS, y es la respuesta que `01` §8 pide en una entrevista: no "hay que actualizar", sino
"la herramienta oficial de scaffolding ya no genera mi línea, tengo el paso de corrección
automatizado en la plantilla, y la migración a 4.x está planificada". El renombrado de
starters —`web` → `webmvc` para dejar el nombre libre frente al stack reactivo, y el starter
de test partido por módulo, uno hermano de cada starter funcional— es uno de los cambios
visibles de la línea 4.x, y el apéndice `A04` lo desarrolla entero.

---

## Lab L02 — Configuración y profiles

### L02 → 1

> Ordena estas cinco fuentes de mayor a menor prioridad y di el nombre con el que
> Actuator identifica a cada una: `application.yml` dentro del jar, `-D`,
> `--clave=valor`, variable de entorno, `application-local.yml` dentro del jar.

**⏱️ 30 segundos.** De mayor a menor: argumento de línea de comandos (`commandLineArgs`),
propiedad de sistema de la JVM (`systemProperties`), variable de entorno
(`systemEnvironment`), `application-local.yml` y `application.yml`, ambos como
`applicationConfig: [classpath:/…]`. Lo específico de profile gana a lo genérico dentro del
mismo grupo de ficheros.

**🗣️ 2 minutos.** El `Environment` es una lista ordenada de `PropertySource`, no una mezcla:
se recorre de arriba abajo y gana **la primera fuente que contiene la clave**. Las dos
inversiones que más se fallan son que `-D` gana a la variable de entorno —mucha gente lo
dice al revés— y que `application.yml` es la fuente de menor prioridad de las que se usan a
diario, no la que manda. Sobre esas cinco todavía hay fuentes con más prioridad que no
aparecen en un despliegue normal: Devtools y las propiedades de test.

**🔬 El detalle.** Falta un escalón entre `commandLineArgs` y `systemProperties`:
`SPRING_APPLICATION_JSON`, un JSON inline que muchas plataformas usan para inyectar un
bloque entero. Y hay una distinción que solo aparece cuando empaquetas: los ficheros
**fuera** del jar (`./config/application.yml`, `./application.yml`) ganan a los de dentro,
que es el mecanismo por el que una imagen trae defaults y el despliegue los ajusta montando
un fichero al lado.

---

### L02 → 2

> "El `application.yml` manda, por eso ahí se configura todo." Corrige la frase y explica
> qué permite el orden real.

**⏱️ 30 segundos.** Es al revés: el `application.yml` empaquetado es la fuente de **menor**
prioridad de las que usas a diario. Ahí van los defaults del artefacto, no las decisiones
del entorno; cualquier variable de entorno lo pisa.

**🗣️ 2 minutos.** Ese orden es justamente lo que permite promover **el mismo jar** de
integración a producción sin reconstruirlo: lo que cambia es el entorno, no el artefacto. Si
lo probado y lo desplegado no son bit a bit lo mismo, lo que probaste no es lo que corre. El
reparto sano queda así: `application.yml` trae lo que el artefacto necesita para ser
utilizable, el despliegue inyecta por entorno con variables o `-D`, y la línea de comandos
queda para el incidente en el que hay que sobreescribir algo ahora mismo.

**🔬 El detalle.** El corolario que casi nadie menciona: **si una propiedad es distinta en
cada entorno, no tiene default legítimo**. Ponerle uno —una URL de integración, un usuario de
base de datos— convierte un despliegue mal parametrizado en un arranque exitoso apuntando al
sitio equivocado, en vez de un fallo ruidoso. Dejarla sin valor y con `@NotBlank` hace que el
proceso no arranque, que es el comportamiento que quieres.

---

### L02 → 3

> Escribiste `INV_SUPPLIER_MAXCONNECTIONS=50` y `environment.getProperty("inv.supplier.max-connections")`
> devuelve `20`, pero el `record` enlazado trae `50`. ¿Por qué no se contradicen?

**⏱️ 30 segundos.** Porque son dos mecanismos de lectura distintos. El relaxed binding
completo —el que elimina los guiones— vive en el `Binder` que usa
`@ConfigurationProperties`, no en la lectura directa del `Environment`.

**🗣️ 2 minutos.** `Environment.getProperty` hace una traducción mínima al consultar la
fuente de variables de entorno: cambia los puntos por guion bajo e ignora mayúsculas, así
que encuentra `INV_SUPPLIER_TIMEOUT` para `inv.supplier.timeout`. Pero **no elimina el
guion**: para `inv.supplier.max-connections` buscaría algo como
`INV_SUPPLIER_MAX-CONNECTIONS`, que no es lo que escribiste. El `Binder`, en cambio,
canonicaliza el nombre del componente del `record` y sabe que en una variable de entorno los
guiones desaparecen. Es la misma frontera por la que `@Value` tampoco tiene relaxed binding.

**🔬 El detalle.** El síntoma inverso también existe y es más confuso: una propiedad "que no
llega" a tu código leído por `@Value` mientras el bloque de `@ConfigurationProperties` sí la
tiene. Cuando dos lecturas de la misma clave discrepan, la pregunta correcta no es cuál está
mal, sino **quién resolvió cada una**. `/actuator/env` resuelve la duda porque muestra la
forma canónica y el `origin` con el nombre literal de la variable.

---

### L02 → 4

> ¿Por qué `java -jar app.jar -Dinv.supplier.timeout=5s` no cambia nada y tampoco da
> error?

**⏱️ 30 segundos.** Porque todo lo que va **después de `-jar`** se le pasa a la aplicación
como argumento, no a la JVM. La propiedad de sistema nunca se crea, y como el argumento no
tiene forma `--clave=valor`, Boot tampoco lo interpreta como propiedad.

**🗣️ 2 minutos.** El argumento acaba en `ApplicationArguments.getNonOptionArgs()`, donde no
lo lee nadie. No hay error porque nada está mal formado: es un argumento libre, como un
nombre de fichero. Para que sea una propiedad de sistema, el `-D` va antes del `-jar`; para
que sea un argumento de configuración, se escribe `--inv.supplier.timeout=5s` con doble
guion. Es un fallo silencioso clásico, y se detecta en un segundo mirando
`/actuator/env/inv.supplier.timeout`: la fuente ganadora seguirá siendo el fichero.

**🔬 El detalle.** La variante con Maven es todavía más traicionera: `spring-boot:run` bifurca
una JVM nueva, así que un `-D` pasado a `./mvnw` es una propiedad de **Maven** y no llega a
tu aplicación. Los equivalentes son `-Dspring-boot.run.jvmArguments="-D…"` para la JVM hija y
`-Dspring-boot.run.arguments="--clave=valor"` para los argumentos de aplicación. De ahí sale
la mitad de los "en el IDE funciona y con Maven no".

---

### L02 → 5

> ¿Qué tres cosas te da el bloque `Origin` del mensaje de un fallo de validación de
> propiedades, y por qué no conviene buscar en el runbook por el texto de `Reason`?

**⏱️ 30 segundos.** `Origin` da el recurso, la línea y la columna del valor culpable
—`class path resource [application.yml] - 24:22`—. `Reason` lo genera Hibernate Validator y
sale traducido según el `Locale` de la JVM, así que el texto cambia de máquina a máquina.

**🗣️ 2 minutos.** Boot conserva el origen de cada valor durante todo el enlace, y por eso el
mensaje de error te lleva al sitio exacto en lugar de obligarte a buscar en qué capa de
configuración estaba el valor malo. Cuando el valor viene de una variable de entorno, el
`origin` nombra la variable; cuando viene de un config tree, nombra el fichero. Para
documentar o para automatizar, la clave estable es `Property` —el nombre canónico de la
propiedad—, no la frase de `Reason`, que en una máquina en español dirá "debe ser mayor que o
igual a 1".

**🔬 El detalle.** Debajo del mensaje bonito hay un `FailureAnalyzer`: la excepción real es
`BindValidationException` envuelta en `ConfigurationPropertiesBindException`, y se ve entera
arrancando con `--debug`. El proceso termina con código de salida distinto de cero, lo que
hace que un orquestador no marque la instancia como lista — y eso es deseable: es preferible
no arrancar a arrancar con un pool de cero conexiones.

---

### L02 → 6

> Dejas `@Validated` en el `record` y quitas `spring-boot-starter-validation`. ¿Qué pasa
> al arrancar con un valor inválido?

**⏱️ 30 segundos.** Arranca tan contento con el valor inválido enlazado. `@Validated` sin una
implementación de Bean Validation en el classpath no valida nada, y no hay error ni aviso.

**🗣️ 2 minutos.** Las anotaciones `@NotBlank`, `@Min` o `@Max` son solo metadatos: alguien
tiene que ejecutarlas, y ese alguien es Hibernate Validator, que llega con el starter de
validación. Sin él, Boot enlaza las propiedades y sigue adelante. El síntoma aparece mucho
más tarde y en otro sitio —un pool de cero conexiones, un timeout absurdo, un `token` vacío
que produce un `401`—, que es el peor tipo de fallo: lejos de su causa.

**🔬 El detalle.** La prevención es de proceso y cabe en dos frases: la dependencia de
validación entra en el mismo commit que la primera anotación de validación, y se escribe un
test que arranque el contexto con un valor inválido y **falle si el contexto arranca**. Ese
test es lo que impide que alguien "limpie dependencias no usadas" y desarme la red sin
enterarse; el ejercicio 13 del lab lo construye.

---

### L02 → 7

> `--spring.profiles.active=local,test` y `--spring.profiles.active=test,local` dan
> valores distintos. ¿Cuál gana y por qué?

**⏱️ 30 segundos.** Gana el **último de la lista**: con `local,test` manda
`application-test.yml`, y con `test,local` manda `application-local.yml`. No hay jerarquía
entre profiles, hay orden de activación.

**🗣️ 2 minutos.** Los ficheros específicos de profile se apilan sobre el `application.yml`
base en el orden en que se activan los profiles, así que el último añadido queda más arriba
en la lista de `PropertySource` y gana. Esto es exactamente el bug de despliegue clásico:
alguien añade un profile a `SPRING_PROFILES_ACTIVE` sin mirar dónde lo coloca y cambia el
comportamiento de un servicio que no tocó. La línea `The following 2 profiles are active` del
arranque es lo primero que hay que mirar cuando un servicio "no lee su configuración".

**🔬 El detalle.** El orden resuelve el valor de una propiedad, pero **no** resuelve un bean
duplicado: dos beans del mismo tipo con `@Profile("local")` y `@Profile("test")` activos a la
vez producen un `NoUniqueBeanDefinitionException` en el arranque, no un ganador. Y hay una
restricción relacionada que sorprende: `spring.profiles.active` no se puede declarar dentro
de un fichero específico de profile; Boot lanza `InvalidConfigDataPropertyException` para
evitar una activación en cascada imposible de razonar.

---

### L02 → 8

> ¿Qué hace exactamente `spring.profiles.group.prod: metrics,audit` y qué problema de
> despliegue evita?

**⏱️ 30 segundos.** Define un alias: activar `prod` activa además `metrics` y `audit`, con
sus ficheros `application-metrics.yml` y `application-audit.yml` y sus beans `@Profile`.

**🗣️ 2 minutos.** El problema que evita es de parametrización. Sin grupos, el despliegue tiene
que enumerar los cinco profiles en una variable de entorno, y ahí es donde se cuelan las
erratas y los olvidos: alguien copia la variable de otro entorno y se deja `audit` fuera. Con
el grupo, la lista vive **dentro del artefacto**, versionada y revisada, y el entorno solo
dice `prod`. Es la misma idea que un starter: agrupar por intención en vez de por pieza.

**🔬 El detalle.** Los grupos se declaran en `application.yml` y se resuelven antes de cargar
los ficheros de profile, así que un grupo puede añadir profiles que a su vez aporten
configuración. Lo que **no** hacen es cambiar la regla de precedencia: dentro del grupo se
sigue aplicando el último-gana, en el orden en que quedan expandidos. Si dos profiles del
mismo grupo definen la misma clave, conviene no tener que razonar sobre ese orden — es señal
de que la clave estaba en el sitio equivocado.

---

### L02 → 9

> Un `@Value("${inv.supplier.region}")` sin default y con la clave ausente: ¿cuándo falla
> y con qué excepción?

**⏱️ 30 segundos.** Falla en el arranque, al crear el bean, con
`IllegalArgumentException: Could not resolve placeholder 'inv.supplier.region' in value "${inv.supplier.region}"`.

**🗣️ 2 minutos.** El `${…}` lo resuelve un `PropertySourcesPlaceholderConfigurer` contra el
`Environment`, y es una búsqueda **literal** de la clave: sin canonicalización y sin relaxed
binding. Si la clave no está, no hay nada que poner y el contexto no se puede construir. Se
le da un default con dos puntos —`${inv.supplier.region:unknown}`—, y ese default es una
cadena que después se convierte al tipo del parámetro. Que falle al arrancar es lo correcto;
lo malo sería que quedara `null` y explotara en la primera petición.

**🔬 El detalle.** Con `@ConfigurationProperties` el comportamiento por defecto es el
contrario: una clave ausente deja el componente en `null` o en el valor por defecto del tipo
—un `int` queda en `0`— y la aplicación arranca. Por eso ahí la garantía la pones tú con
`@Validated` y `@NotNull`. Dicho de otra forma: `@Value` falla por defecto y
`@ConfigurationProperties` calla por defecto, y conviene saber en cuál de los dos mundos está
cada propiedad crítica.

---

### L02 → 10

> ¿Qué convierte un config tree en propiedades, y qué papel juega el nombre del fichero?

**⏱️ 30 segundos.** `spring.config.import: configtree:/ruta/` monta un directorio como fuente
de propiedades: **el nombre de cada fichero es la clave completa** y su contenido es el
valor. `inv.supplier.token` se convierte en la propiedad `inv.supplier.token`.

**🗣️ 2 minutos.** Es la respuesta de Boot a los secretos montados como ficheros, que es lo que
hacen Kubernetes, Docker Swarm y los gestores de secretos. La gracia es la indirección: la
plataforma decide de dónde sale el secreto y tu aplicación solo lee un directorio, así que el
mismo jar funciona en tu máquina y en un clúster sin saber nada del proveedor. La ruta exige
**barra final** porque apunta a un directorio, y se suele escribir con `optional:` en
desarrollo para que su ausencia no rompa el arranque.

**🔬 El detalle.** Dos trampas prácticas. La primera: `echo` añade un salto de línea al
fichero, y aunque Boot recorta los espacios finales de un config tree, es mejor generar el
valor con `printf` que confiar en eso — un token con un `\n` pegado produce un `401` que
cuesta una tarde. La segunda: el `toString()` de un `record` incluye todos sus componentes,
así que un log de arranque que imprima el objeto de propiedades filtra el secreto en claro.

---

### L02 → 11

> ¿Para qué sirve el prefijo `optional:` en `spring.config.import`, y cuándo **no** lo
> quieres?

**⏱️ 30 segundos.** Hace que la ausencia del recurso no rompa el arranque. Sin él, un
directorio o un fichero inexistente produce `ConfigDataLocationNotFoundException` y la
aplicación no levanta.

**🗣️ 2 minutos.** Lo quieres para lo que es genuinamente opcional: un `./config/local.yml`
que solo existe en la máquina del desarrollador, un override que en producción no está. **No
lo quieres para nada obligatorio**, y muy especialmente para un secreto: si el config tree del
token no está montado, prefieres que el arranque falle ahí, con un mensaje claro, antes que
arrancar sin credenciales y descubrirlo en la primera llamada al proveedor con un `401` que
nadie relaciona con la configuración.

**🔬 El detalle.** Falla pronto y falla ruidoso es la misma política que sostiene `@NotBlank`
sobre el token del `record`: hay dos redes distintas —que la fuente exista y que el valor sea
válido— y conviene tener las dos, porque protegen de cosas distintas. Un directorio montado
pero vacío pasa la primera y la pilla la segunda, que es precisamente el caso de un `Secret`
mal referenciado en un manifiesto.

---

### L02 → 12

> Escribes `mode: on` esperando la cadena `"on"` y recibes `true`. ¿Qué lo causa y cómo
> se corrige?

**⏱️ 30 segundos.** SnakeYAML implementa YAML 1.1, donde `on`, `off`, `yes`, `no`, `y` y `n`
son **booleanos**. El parser devuelve `Boolean.TRUE` y el `Binder` lo convierte a `String`
como `"true"`. Se corrige entrecomillando: `mode: "on"`.

**🗣️ 2 minutos.** Lo peligroso no es la conversión, es que **no hay error ni aviso**: si tu
código comparaba con `"on"`, la comparación es `false` para siempre y el comportamiento cambia
en silencio. La familia es más grande de lo que parece: el código de país `NO` se convierte en
`false`, y una versión escrita `1.10` se lee como el número `1.1` y pierde el cero. La regla
práctica es entrecomillar todo lo que no sea evidentemente numérico.

**🔬 El detalle.** Hay un tercer miembro que además **rompe el parseo** en vez de mentirte: un
valor que empieza por `*` o por `&` es sintaxis de anclaje y alias de YAML, y el error que
recibes no menciona tu propiedad. Cualquier secreto o patrón que pueda empezar por esos
caracteres va obligatoriamente entre comillas. Para una sola clave, un `.properties` es más
seguro precisamente porque no tiene tipos implícitos ni indentación que romper.

---

### L02 → 13

> Una propiedad mal indentada en YAML no rompe el arranque. ¿Qué ocurre, por qué
> `ignoreUnknownFields = false` no lo detecta, y qué endpoint te lo confirma?

**⏱️ 30 segundos.** No se pierde el valor: **se crea otra propiedad**. `timeout` colgado de
`inv` en vez de `inv.supplier` existe como `inv.timeout`, no lo lee nadie, y la que esperabas
se queda con su valor anterior o con el default del tipo. Lo confirmas con
`/actuator/env/inv.timeout`.

**🗣️ 2 minutos.** `ignoreUnknownFields = false` se queja de claves desconocidas **bajo el
prefijo** del `@ConfigurationProperties`; `inv.timeout` está fuera de `inv.supplier` y por
tanto no es asunto suyo. Por eso este error sobrevive a la validación, a los tests que no
miran esa propiedad y a la revisión de código: son dos espacios de diferencia. Cuando una
propiedad "no hace efecto", la primera pregunta no es si el valor es correcto, sino **si la
clave que crees que existe existe de verdad**.

**🔬 El detalle.** La prevención que funciona de verdad no es disciplina, es tooling:
`spring-boot-configuration-processor` genera los metadatos de tus propiedades en
`META-INF/spring-configuration-metadata.json`, y con eso el IDE marca `inv.timeout` como
propiedad desconocida mientras escribes. Cuesta una dependencia `optional` en el `pom.xml` y
es de las cosas que más agradece el equipo que hereda el servicio.

---

### L02 → 14

> Llamas a `/actuator/env` y todos los valores salen como `******` aunque ninguno parece
> un secreto. ¿Qué versión de Boot introdujo ese comportamiento y qué propiedad lo
> controla?

**⏱️ 30 segundos.** Spring Boot **3.0**: `env` y `configprops` enmascaran **todos** los valores
por defecto. Se controla con `management.endpoint.env.show-values` —y su gemela
`management.endpoint.configprops.show-values`—, con los valores `NEVER`, `ALWAYS` y
`WHEN_AUTHORIZED`.

**🗣️ 2 minutos.** La respuesta "es que Actuator oculta las claves que se llaman `password` o
`secret`" describe Boot 2.x y ya no es correcta; es un buen ejemplo de respuesta clásica
envejecida. En un servicio real el ajuste razonable es `WHEN_AUTHORIZED`, que enseña los
valores solo a quien pasó por la autenticación de Actuator, junto con exponer el puerto de
gestión únicamente a la red interna. `ALWAYS` es una decisión de laboratorio: con eso puesto,
cualquiera que alcance el puerto 8081 lee tus credenciales en claro.

**🔬 El detalle.** El enmascarado por defecto no es la seguridad, es la última línea. Las dos
primeras son no exponer `env` en la lista blanca de
`management.endpoints.web.exposure.include` y separar el puerto de gestión del puerto de la
aplicación, que es para lo que existe `management.server.port`. Un endpoint que no está
publicado no tiene superficie de ataque, aunque alguien se deje un `ALWAYS` en el fichero.

---

## Lab L03 — API REST, filtros y errores

### L03 → 1

> Un cliente manda `POST /api/items` con un JSON perfecto y recibe `415`. ¿Qué le falta a su
> petición, y en qué componente de MVC se decidió ese código?

**⏱️ 30 segundos.** Le falta el `Content-Type: application/json`. El código lo decidió el
`HandlerMapping`, antes de elegir ningún converter.

**🗣️ 2 minutos.** El `consumes` del controller participa en la selección del handler: si el
`Content-Type` no encaja, el método deja de ser candidato y la excepción es
`HttpMediaTypeNotSupportedException`, no un fallo de Jackson. Por eso el JSON puede estar
perfecto y dar igual — nadie llegó a leerlo. La causa más frecuente en la práctica no es
mandar `text/plain` a propósito, sino no mandar cabecera: `curl -d` pone
`application/x-www-form-urlencoded` por ti.

**🔬 El detalle.** La respuesta 415 de Spring incluye una cabecera `Accept` con los tipos
que sí sabe leer. Es la parte útil del error y casi nadie la mira.

---

### L03 → 2

> Enfrenta `415`, `406` y `400`: di en una frase qué no puede hacer el servidor en cada caso,
> y cuál de los tres habla de la **respuesta** y no de la petición.

**⏱️ 30 segundos.** 415: no sé **leer** lo que me mandas. 400: sé leerlo y está mal. 406: no
sé **escribir** lo que me pides. El que habla de la respuesta es el 406.

**🗣️ 2 minutos.** El 415 mira el `Content-Type` de la petición y se decide en el
`HandlerMapping`. El 400 significa que el converter corrió: o el JSON está roto
(`HttpMessageNotReadableException`) o se deserializó y Bean Validation lo rechazó
(`MethodArgumentNotValidException`). El 406 mira el `Accept` y no encuentra intersección
con el `produces`, así que no hay representación que devolver — y el cuerpo va vacío, con
lógica perversa: explicarte el error exigiría escribir un cuerpo que acabas de decir que no
aceptas.

**🔬 El detalle.** Falta el cuarto caso del lab, que es el que de verdad sorprende: un
`?limit=500` con `@Min(1) @Max(100)` sale **500**, no 400, si la clase del controller lleva
`@Validated`. Desde Spring Framework 6.1 el controller valida por sí mismo los parámetros de
método y lanza `HandlerMethodValidationException`, que el `DefaultHandlerExceptionResolver`
traduce a 400; poner `@Validated` **degrada** esa validación al camino de AOP, donde lo que
sube es una `ConstraintViolationException` de Jakarta que ningún resolver reconoce. La
anotación sigue siendo obligatoria en un `@Service`, donde no hay MVC que valide: lo que
cambió es el borde web.

---

### L03 → 3

> "El `@ControllerAdvice` maneja todos los errores de la aplicación." Corrige la frase y di
> qué dos familias de errores se le escapan en este lab.

**⏱️ 30 segundos.** Maneja los que ocurren **dentro** del `DispatcherServlet`. Se le escapan
los lanzados en un filtro y los que produce el contenedor de servlets antes de llegar al
despacho.

**🗣️ 2 minutos.** El manejo de excepciones de MVC lo ejecutan los
`HandlerExceptionResolver`, que viven dentro del `DispatcherServlet`; un filtro corre fuera
y antes. Lo que lance sube al contenedor, que responde con su propia página de error —el
`/error` de Boot— sin tu `ProblemDetail`. En este lab lo compruebas dos veces: con la
excepción del `ClientIdFilter` y, en la vida real, con los 401 y 403 de Spring Security,
que produce un `AuthenticationEntryPoint` dentro de la cadena de filtros (`20`).

**🔬 El detalle.** Por eso un filtro que quiere rechazar escribe él mismo la respuesta —
estado, `Content-Type` y cuerpo— y **no** lanza: es la única forma de que el cliente reciba
tu formato de error.

---

### L03 → 4

> `spring.mvc.problemdetails.enabled=true` está puesto y tu `InsufficientStockException` sigue
> saliendo como 500 con formato `/error`. ¿Por qué no se contradicen las dos cosas?

**⏱️ 30 segundos.** Porque esa propiedad solo convierte a `ProblemDetail` las **excepciones
que Spring ya conoce**. Una excepción tuya no está en esa lista: hay que traducirla con un
`@ExceptionHandler`.

**🗣️ 2 minutos.** La propiedad activa el soporte de RFC 9457 en
`ResponseEntityExceptionHandler`, que cubre el catálogo de excepciones de MVC —415, 406,
400 de validación, 405— y las devuelve con `type`, `title`, `status` y `detail`. Tu
`InsufficientStockException` no la conoce nadie, así que sale por el camino genérico: 500 y
el cuerpo del `/error`. La corrección es un `@ExceptionHandler` que la mapee a 422 con su
propio `ProblemDetail`.

**🔬 El detalle.** Tres precisiones de la corrección. El advice **extiende**
`ResponseEntityExceptionHandler`, que es lo que le da mapeadas las excepciones estándar de MVC
—por eso la propiedad y el advice se complementan en vez de competir—. Puede **devolver el
`ProblemDetail` directamente** desde Spring 6, sin envolverlo en un `ResponseEntity`, porque el
status sale del propio objeto. Y conviene acotarlo con `basePackages`: sin filtro, el advice
también atraparía las excepciones de los endpoints de Actuator. Lo tuyo va en `setType` —el
URI estable— y en `setProperty`, que sale como claves de primer nivel del JSON: `sku`,
`available`, `requested`, que es lo que convierte un error legible en uno procesable.

---

### L03 → 5

> ¿Qué diferencia hay entre `type`, `title`, `detail` e `instance` de un `ProblemDetail`, y
> por cuál de los cuatro debe enrutar un cliente?

**⏱️ 30 segundos.** `type` es un URI que identifica **la clase de problema** y es el único
por el que un cliente debe enrutar. `title` es su nombre legible, `detail` explica **esta
ocurrencia** y `instance` identifica la petición concreta.

**🗣️ 2 minutos.** La distinción que importa es estable frente a variable: `type` y `title`
no cambian entre ocurrencias, así que un cliente puede compararlos; `detail` e `instance`
sí cambian, así que programar contra ellos es programar contra un mensaje. Es exactamente
el error que se comete con un `Map<String,String>` casero, donde todo es texto y el cliente
acaba haciendo `contains("stock")`.

**🔬 El detalle.** `type` no tiene que resolver a una página web, aunque es buena idea que
lo haga. Si lo omites, vale `about:blank`, y entonces el cliente se queda sin nada por lo
que enrutar salvo el código de estado.

---

### L03 → 6

> El `MDC.remove` está después de `chain.doFilter` y no en un `finally`. Describe la secuencia
> exacta de tres peticiones que produce una línea de log con el id equivocado.

**⏱️ 30 segundos.** La petición A falla con excepción, así que su `MDC.remove` nunca se
ejecuta y su id queda pegado al hilo. La petición B cae en ese mismo hilo **sin** cabecera
propia y hereda el id de A. La C ya con id propio lo pisa.

**🗣️ 2 minutos.** La clave es que la limpieza está en el camino feliz: cualquier excepción
que suba por la cadena se salta esa línea. Como el hilo vuelve al pool contaminado, la
siguiente petición que lo tome arrastra el valor anterior — y si además tu filtro solo pone
el id cuando falta, el `MDC.put` ni siquiera lo sobrescribe. El resultado son líneas de log
de la petición B atribuidas a la A, que en un entorno auditado no es un detalle cosmético.

**🔬 El detalle.** El bug se hace determinista para poder verlo: arrancando con
`--server.tomcat.threads.max=1` las tres peticiones caen forzosamente en el mismo hilo y la
tercera línea sale con el id de la segunda. Y la corrección tiene dos precisiones que se
fallan: va en `finally` y **no** en un `catch` —tragarse la excepción arreglaría el log y
rompería el manejo de errores, porque el advice ya no la vería— y se escribe `MDC.remove`, no
`MDC.clear()`, para no llevarse por delante las claves que ponga otro filtro.

---

### L03 → 7

> ¿Por qué el bug de la pregunta anterior casi nunca se ve en una máquina de desarrollo y sí
> en producción?

**⏱️ 30 segundos.** Porque en desarrollo lanzas peticiones de una en una y casi siempre con
cabecera propia: la contaminación existe, pero se sobrescribe antes de que puedas verla.

**🗣️ 2 minutos.** Hacen falta tres condiciones simultáneas —una petición que falle, reuso
del mismo hilo y una petición posterior sin id propio— y en local el pool está casi vacío,
así que rara vez coinciden. En producción hay doscientos hilos reciclándose miles de veces
por minuto y tráfico que no siempre trae la cabecera: la coincidencia pasa de improbable a
constante. Es el patrón general de los bugs de estado por hilo: no son intermitentes,
son dependientes de la carga.

**🔬 El detalle.** La regla general no es del MDC sino del `ThreadLocal`: no está ligado a la
petición, está ligado al hilo, y el hilo se reutiliza. Lo mismo vale para el
`SecurityContextHolder` y el `RequestContextHolder`, y por eso la limpieza en `finally` es
estructural y no una precaución. Ayuda a verlo un patrón de log con valor por defecto
—`%X{requestId:-sin-request-id}`—: ese literal en una línea significa que corrió fuera del
filtro, que ya es información.

---

### L03 → 8

> Tu filtro loguea el cuerpo y el controller responde `Required request body is missing`. ¿Qué
> recurso se consumió, y por qué el log que demuestra que el cuerpo llegó no contradice al
> error?

**⏱️ 30 segundos.** Se consumió el `InputStream` del request, que es de un solo uso. El log
prueba que el cuerpo **llegó**, no que **siga disponible**: tu filtro lo leyó y no dejó nada
para el converter.

**🗣️ 2 minutos.** Es la confusión que hace perder más tiempo en este fallo: tienes delante
la evidencia de que el JSON existía, y el error dice que falta. Las dos cosas son ciertas en
momentos distintos. La corrección es envolver el request en un `ContentCachingRequestWrapper`
y pasar **el wrapper** a `chain.doFilter(...)`, para que lo leído quede almacenado y el
converter pueda volver a leerlo.

**🔬 El detalle.** Tiene un costo ⏱️: duplica el payload en memoria por cada petición en
vuelo. Con cargas grandes se limita por tamaño o se activa solo en un profile de
diagnóstico.

---

### L03 → 9

> Con `ContentCachingRequestWrapper`, ¿por qué `getContentAsByteArray()` devuelve un array
> vacío si lo llamas antes de `chain.doFilter(...)`?

**⏱️ 30 segundos.** Porque el wrapper no lee por su cuenta: **cachea lo que otro va leyendo**.
Antes de `doFilter` nadie ha consumido el stream todavía, así que no hay nada cacheado.

**🗣️ 2 minutos.** El wrapper intercepta las lecturas y va copiando los bytes a un buffer
interno. Quien realmente lee es el `HttpMessageConverter`, aguas abajo. Por eso el log del
cuerpo va **después** de `chain.doFilter(...)`, normalmente en el `finally`, y por eso el
orden del código en este filtro no es cosmético: invertirlo produce un log vacío sin ningún
error que lo explique.

**🔬 El detalle.** El caso límite que sale de ahí: si la petición **nunca llega al
converter**, tampoco hay nada que cachear. Un `POST` rechazado con 415 en el `HandlerMapping`
—pregunta 1— deja tu log de auditoría vacío justo en las peticiones que fallan, que suelen ser
las que querías auditar. El wrapper registra lo que alguien leyó, no lo que el cliente mandó.

---

### L03 → 10

> ¿Cuál es la única forma correcta de que un `Filter` rechace una petición, y por qué lanzar
> una excepción no lo es?

**⏱️ 30 segundos.** Escribir la respuesta él mismo —estado, `Content-Type` y cuerpo— y
**no** llamar a `chain.doFilter`. Lanzar no sirve porque el `@ControllerAdvice` no verá esa
excepción.

**🗣️ 2 minutos.** Un `return` sin continuar la cadena corta la petición de forma limpia y
deja al filtro como responsable del cuerpo. Si en cambio lanzas, la excepción sube al
contenedor de servlets y el cliente recibe el error genérico del contenedor o el `/error` de
Boot, sin tu formato y sin tu `type`. El precio de hacerlo bien es duplicar la construcción
del `ProblemDetail` fuera del advice, y es un precio que se paga.

**🔬 El detalle.** Cómo se escribe esa respuesta, en cuatro pasos: `response.setStatus(...)`,
`response.setContentType(MediaType.APPLICATION_PROBLEM_JSON_VALUE)`, serializar con el
`ObjectMapper` **inyectado** —el mismo bean que usan los converters, porque un
`new ObjectMapper()` aquí hace que las fechas del error salgan con otro formato que el resto de
la API— y `return` sin llamar a `chain.doFilter`. Y el argumento honesto que cierra la
discusión: si la comprobación no necesita correr antes que Security, muévela a un
`HandlerInterceptor` y recuperas el advice.

---

### L03 → 11

> Nombra dos cosas que un `HandlerInterceptor` puede hacer y un `Filter` no, y una que solo
> puede hacer el `Filter`.

**⏱️ 30 segundos.** El interceptor sabe **qué handler** va a atender la petición y sus
excepciones sí pasan por el `@ControllerAdvice`. El filtro, en cambio, puede envolver
request y response para modificar el cuerpo.

**🗣️ 2 minutos.** El `handler instanceof HandlerMethod` del interceptor te da la clase y el
método concretos, que es lo que permite métricas por endpoint o auditoría con el nombre de
la operación — un filtro solo ve una URL. Y como el interceptor corre dentro del
`DispatcherServlet`, lo alcanza el manejo de errores de MVC. A cambio, envolver el cuerpo
solo se puede hacer desde fuera, con los wrappers de la API de Servlet, así que la
correlación, la seguridad, CORS y la compresión son trabajo de filtro.

**🔬 El detalle.** También se registran y se acotan en sitios distintos, y eso se pregunta:
el interceptor se añade en un `WebMvcConfigurer` con `addInterceptors` y se limita por ruta con
`addPathPatterns("/api/**")`; el filtro se registra con `@Component` —que **no** fija su orden
en la cadena— y, cuando el orden importa, con un `FilterRegistrationBean` y su `setOrder` y
`addUrlPatterns`. Y una advertencia de la misma familia: poner `@EnableWebMvc` en esa clase de
configuración desactiva la autoconfiguración de MVC entera, que es cómo "quería medir tiempos"
acaba en "se me cayeron los converters".

---

### L03 → 12

> `postHandle` y `afterCompletion`: ¿cuál se salta cuando el handler lanza una excepción, y
> qué consecuencia tiene eso para unas métricas de latencia?

**⏱️ 30 segundos.** Se salta `postHandle`. `afterCompletion` corre siempre y además recibe
la excepción. Medir en `postHandle` significa **no medir las peticiones que fallan**.

**🗣️ 2 minutos.** Es un sesgo silencioso y peligroso: los errores suelen ser las peticiones
lentas —timeouts, reintentos, caídas—, así que tu p99 sale mucho mejor de lo que es y el
tablero dice que todo va bien mientras el servicio se degrada. Cualquier medición de
latencia o contador de peticiones va en `afterCompletion`, que es el `finally` del
interceptor.

**🔬 El detalle.** `afterCompletion` corre incluso cuando el advice ya tradujo la excepción,
así que el `response.getStatus()` que lees ahí es el **final** —el 422, no el 500 original— y
el parámetro `Exception ex` te dice si la hubo aunque el cliente vaya a recibir una respuesta
con formato. Y el reloj se guarda con `request.setAttribute("startedAt", …)`, no en un
`ThreadLocal`: el atributo vive y muere con la petición, así que aquí no hay nada que limpiar
en un `finally` — es la lección de la pregunta 6 al revés.

---

### L03 → 13

> Quitas el `finally` del `RequestIdFilter` y `./mvnw -q test` sigue en verde. ¿Qué propiedad
> del entorno de test lo explica, y qué clase de bugs no cubre un `MockMvc`?

**⏱️ 30 segundos.** Que `MockMvc` no usa un pool de hilos reales reciclándose: no hay
contaminación entre peticiones que observar. No cubre los bugs de **concurrencia y de estado
por hilo**.

**🗣️ 2 minutos.** `MockMvc` ejecuta la petición en el hilo del test, sin servidor y sin
reuso, así que el fallo de la pregunta 6 es estructuralmente invisible. Lo mismo vale para
las carreras sobre el `Map` del lab, para los timeouts reales y para cualquier cosa que
dependa del pool. Eso no lo convierte en mala herramienta —es rapidísimo y cubre el
contrato HTTP—; lo convierte en insuficiente, y por eso existen `@SpringBootTest` con puerto
real y las pruebas de carga (`24`).

**🔬 El detalle.** Es un caso concreto de una regla general: una suite verde prueba que no
fallan los escenarios que escribiste, y los bugs de concurrencia casi nunca están entre
ellos.

---

## Lab L04 — Datos y transacciones

### L04 → 1

> Tu endpoint devuelve `422` con un `ProblemDetail` impecable y la fila quedó grabada en
> `inventory_event`. Explica por qué las dos cosas son compatibles y cuál es el único comando
> que resuelve la duda.

**⏱️ 30 segundos.** Porque son dos capas distintas: el `422` lo decide el
`@RestControllerAdvice` al ver la excepción salir del controller, y el rollback lo decide —o no
lo decide— un proxy transaccional que puede no haber intervenido nunca. El código de estado
describe lo que pasó en HTTP, no lo que pasó en la base. El único comando que lo resuelve es un
`SELECT` hecho desde fuera de la aplicación: `docker exec -i inv-lab-postgres-1 psql -U inv_lab
-d inv_lab -c "SELECT count(*) FROM inventory_event"`, antes y después.

**🗣️ 2 minutos.** La excepción viaja hacia arriba por la pila y cruza dos fronteras. La
primera es el proxy de `@Transactional`: si la anotación no se aplicó —self-invocation, método
`private`— o si alguien capturó la excepción antes de que el proxy la viera, esa frontera no
hace nada y la transacción confirma. La segunda es el `DispatcherServlet`, que sí ve la
excepción y busca un `@ExceptionHandler`; ese sí funciona siempre, porque no depende de ningún
proxy sobre tu servicio. Así que la respuesta de error es perfectamente honesta sobre lo que
supo la capa web, y la base contiene otra historia. Por eso la regla del lab es que, en
persistencia, **el log y el código de estado no son evidencia**: la evidencia es el conteo de
filas antes y después del caso que debía revertir.

**🔬 El detalle.** El caso aún más incómodo es el inverso: un `200` con rollback. Ocurre cuando
un método interno marcó la transacción `rollback-only` y el de fuera capturó la excepción; el
cliente recibe una respuesta de éxito construida con datos que se acaban de revertir, y solo el
`UnexpectedRollbackException` del commit final —si llega a lanzarse— delata el desastre.

---

### L04 → 2

> En la variante de self-invocation **no había transacción**, y sin embargo las filas se
> guardaron. ¿Quién las confirmó?

**⏱️ 30 segundos.** `SimpleJpaRepository`, la implementación que Spring Data genera para tu
repositorio: sus métodos están anotados con `@Transactional`. Sin una transacción de fuera a la
que unirse, cada `save()` y cada `find...()` abre y confirma **la suya**.

**🗣️ 2 minutos.** Esto es lo que convierte el fallo en silencioso en vez de ruidoso. Si no
hubiera nadie gestionando transacciones, un `INSERT` fuera de transacción simplemente fallaría o
correría en autocommit del driver, y en cualquier caso alguien se enteraría. Lo que pasa de
verdad es peor: Spring Data **sí** tiene su propia gestión transaccional por método, así que
cada escritura individual es atómica y correcta, y el conjunto de escrituras que tú querías
atómico no lo es. El resultado es lo peor de los dos mundos: consistencia por sentencia,
inconsistencia por operación de negocio. Y se ve en el log del `TransactionInterceptor` en
`TRACE`, que imprime `Getting transaction for
[org.springframework.data.jpa.repository.support.SimpleJpaRepository.save]` — líneas que
tranquilizan a quien solo buscaba "¿corrió el interceptor?".

**🔬 El detalle.** `SimpleJpaRepository` lleva `@Transactional(readOnly = true)` a nivel de
clase y `@Transactional` en los métodos de escritura. La propagación es `REQUIRED`, así que
cuando **sí** hay transacción de fuera se une a ella y no abre nada: el mismo código produce
comportamientos opuestos según quién lo llame, que es exactamente lo que hace difícil de ver
este bug.

---

### L04 → 3

> Subes `org.springframework.transaction.interceptor` a `TRACE`, ves líneas de
> `Getting transaction for` y concluyes que hubo transacción. ¿Por qué esa conclusión puede ser
> falsa, y qué hay que mirar en cada línea?

**⏱️ 30 segundos.** Porque las líneas pueden venir de otro bean. Hay que mirar el **nombre
completamente cualificado del método** que va entre corchetes: si dice `SimpleJpaRepository.save`
y nunca dice `InventoryService.recordBatch`, tu método no estuvo dentro de ninguna transacción.

**🗣️ 2 minutos.** El `TransactionInterceptor` imprime dos líneas por invocación interceptada:
`Getting transaction for [FQN.método]` antes y `Completing transaction for [FQN.método]` después.
El diagnóstico correcto no es binario —"¿hay líneas o no hay?"— sino de correspondencia:
**buscas tu método por nombre**. Si aparece, hubo proxy y hubo transacción, y entonces el
problema es de otra familia: una excepción capturada, una excepción comprobada sin `rollbackFor`,
o un límite mal puesto. Si no aparece, el proxy nunca intervino y estás en un silencio
estructural: self-invocation, método `private`, método `final`, o llamada desde
`@PostConstruct`. Ese reparto en dos ramas es el procedimiento entero, y se ejecuta en un minuto
sin debugger.

**🔬 El detalle.** Un tercer mensaje útil del mismo logger es
`Skipping transactional joinpoint [...] because no transaction manager has been configured` y,
en el caso de `rollback-only`, `Transactional code has requested rollback on managed transaction`.
Y hay un caso límite: si el bean está proxyado por CGLIB pero el método es `final`, no hay línea
ninguna **y además** Spring puede haber escrito un `INFO` en el arranque avisando de que no pudo
proxyar ese método.

---

### L04 → 4

> "`@Transactional` solo funciona en métodos `public`." Corrige la frase con la versión precisa
> para Spring Framework 6.2 y di qué es lo que de verdad decide si la anotación se aplica.

**⏱️ 30 segundos.** Es una sobregeneralización heredada de la época de los proxies JDK. Desde
Spring Framework 6.0, con proxies **CGLIB** —el default de Boot— la anotación también se respeta
en métodos `protected` y package-private. Lo que nunca funciona es `private`. Lo que decide de
verdad son dos cosas: **si el proxy puede sobrescribir el método** y **si la llamada entra desde
fuera del bean**.

**🗣️ 2 minutos.** Un proxy JDK implementa la interfaz del bean, así que solo ve lo que está en
la interfaz, que por definición es público. Un proxy CGLIB crea una **subclase** del bean y
sobrescribe métodos, y una subclase puede sobrescribir `public`, `protected` y package-private
—si está en el mismo paquete—, pero no `private` ni `final`. Boot usa CGLIB por defecto desde
2.0 (`spring.aop.proxy-target-class=true`), así que en un proyecto Boot moderno la regla práctica
es "todo menos `private` y `final`". Y aun así, la visibilidad es la mitad de la historia: la
otra mitad es que la llamada tiene que entrar desde fuera, porque el proxy envuelve al bean por
fuera y no intercepta un `this.metodo()`. Un método `public` llamado internamente tampoco
funciona, y ese caso es el que más se ve en código real.

**🔬 El detalle.** La salida sin proxies es el **weaving de AspectJ en tiempo de carga**
(`@EnableTransactionManagement(mode = AdviceMode.ASPECTJ)`), que modifica el bytecode de la clase
y por tanto intercepta también las llamadas internas y los métodos privados. Es correcto y casi
nadie lo usa: añade un agente de JVM, complica el arranque y hace que el comportamiento del
código dependa de cómo se lanzó la aplicación.

---

### L04 → 5

> Un `try/catch` dentro de un método transaccional convirtió un rollback en un commit. Da las
> dos correcciones posibles y di en qué caso eliges cada una.

**⏱️ 30 segundos.** Volver a lanzar la excepción (`throw e`) o marcar la transacción con
`TransactionAspectSupport.currentTransactionStatus().setRollbackOnly()`. La primera cuando la
operación entera debe fallar y el llamador tiene que enterarse; la segunda cuando el flujo debe
continuar para construir una respuesta de negocio, pero nada se puede guardar.

**🗣️ 2 minutos.** El mecanismo es el de siempre: el proxy decide el rollback **mirando si sale
una excepción del método que envuelve**. Si la capturas, para él el método terminó bien y hace
commit. `throw e` restaura la señal y es la respuesta por defecto en una entrevista: capturar y
escribir un `WARN` no es manejar un error, es esconderlo. `setRollbackOnly()` es la alternativa
cuando de verdad no quieres usar una excepción como control de flujo —por ejemplo, un endpoint
que debe devolver un informe con los elementos rechazados—; condena la transacción sin lanzar
nada, y si la llamas fuera de una transacción lanza `NoTransactionException`, que es una
comprobación gratis de que estás donde crees. Y hay una tercera respuesta que no es una
corrección sino un rediseño: si el requisito era "que un elemento malo no tumbe el lote", ninguna
de las dos sirve, y lo que hace falta es una transacción por elemento con `TransactionTemplate`.

**🔬 El detalle.** Capturar excepciones dentro de un método transaccional es además la forma de
llegar a `UnexpectedRollbackException`: si el método interno tenía su propio `@Transactional` con
`REQUIRED`, su proxy ya marcó el `TransactionStatus` compartido como `rollback-only` antes de que
tu `catch` se ejecutara. Tu `catch` evita la propagación pero no borra la marca, y el commit
final del método externo falla con un mensaje que no menciona a ninguno de los dos culpables.

---

### L04 → 6

> Explica `UnexpectedRollbackException: Transaction silently rolled back because it has been
> marked as rollback-only`: quién puso la marca, por qué la excepción aparece en un método que
> no falló, y por qué es preferible a la alternativa.

**⏱️ 30 segundos.** La marca la puso el proxy de un método interno que falló y cuya excepción
alguien capturó. Con `REQUIRED` ese método no tenía transacción propia: se unió a la de fuera, y
al fallar solo pudo marcarla como condenada. La excepción sale en el método externo porque es el
que hace el commit, y es preferible a la alternativa porque **avisa**: el otro final posible es
un commit silencioso.

**🗣️ 2 minutos.** Con `REQUIRED`, una transacción anidada no es una transacción: es la misma.
El `TransactionStatus` del método interno es un participante, no un dueño, así que cuando su
proxy ve una excepción no puede hacer rollback —no es suyo— y hace lo único que puede: poner
`rollbackOnly = true` en el objeto compartido. Si el llamador captura esa excepción y sigue como
si nada, llega al final y pide commit; el `AbstractPlatformTransactionManager` ve la marca, hace
rollback y lanza `UnexpectedRollbackException` para que nadie crea que confirmó. Lo
desconcertante es que el stack trace apunta al método que **no** falló y no menciona al que
falló, que terminó hace rato. Y por eso es la variante buena de este bug: un fallo que se
manifiesta con un mensaje raro es infinitamente mejor que uno que devuelve `200` y deja la base
inconsistente.

**🔬 El detalle.** Si de verdad necesitas que el método interno pueda fallar sin condenar al
externo, `REQUIRED` no es la propagación correcta: es `REQUIRES_NEW` —con el costo de una segunda
conexión simultánea— o `NESTED` con savepoints, que con `JpaTransactionManager` normalmente no
está disponible. Elegir entre las dos es una decisión de diseño, no un detalle de configuración.

---

### L04 → 7

> Con `maximum-pool-size: 2`, ¿cuántas peticiones concurrentes hacen falta para bloquear un
> método que llama a otro con `REQUIRES_NEW`? Escribe la regla general.

**⏱️ 30 segundos.** Dos. La regla general: con un pool de `N` conexiones, un camino de código
que necesita `k` conexiones simultáneas se bloquea con `N/(k-1)` peticiones concurrentes —con
`k = 2`, bastan `N`—. Y al revés, que es como se usa: **`pool ≥ concurrencia × conexiones por
request`**.

**🗣️ 2 minutos.** El mecanismo es un deadlock clásico por recursos, sin que intervenga ningún
bloqueo de base de datos. Cada petición toma su primera conexión al abrir la transacción externa;
cuando llega al `REQUIRES_NEW`, la externa **se suspende pero no suelta su conexión**, y la
interna pide otra. Con dos peticiones y dos conexiones, las dos tienen una y ninguna consigue la
segunda: nadie avanza, nadie suelta, y a los tres segundos —el `connection-timeout`— todos se
rinden con `SQLTransientConnectionException`. Lo relevante para una entrevista no es el número
sino la forma de razonarlo: antes de dimensionar un pool hay que contar **cuántas conexiones
consume un request completo** y **cuánto tiempo las retiene**, y `REQUIRES_NEW` es la forma más
silenciosa de que ese primer número deje de ser uno.

**🔬 El detalle.** Con `k = 2` la fórmula da `N/(2-1) = N`, es decir, hacen falta tantas
peticiones como conexiones; con `N = 2` son dos peticiones, y con las ocho del lab el fallo es
instantáneo. Subir el pool no elimina el deadlock, solo sube el umbral de concurrencia al que
aparece — por eso es un parche, no una solución.

---

### L04 → 8

> El servicio lanza `Connection is not available` y en la base no hay una sola consulta
> ejecutándose. ¿Qué estado muestra `pg_stat_activity`, y qué te dice eso sobre dónde está el
> recurso agotado?

**⏱️ 30 segundos.** Muestra `idle in transaction`: hay transacciones abiertas y la base no está
ejecutando nada, esperando a que el cliente mande la siguiente sentencia. El recurso agotado no
es de Postgres —CPU al 0 %, cero consultas— sino tuyo: el pool de Hikari. El incidente es
invisible en cualquier gráfica de la base de datos.

**🗣️ 2 minutos.** `idle in transaction` es el estado que hay que saber leer, porque distingue
dos incidentes que se parecen. Si vieras `active` con consultas largas, el problema sería la base
—falta un índice, hay contención, alguien lanzó un reporte— y la respuesta estaría en el plan de
ejecución. Al ver `idle in transaction` sabes que la base está esperándote **a ti**: alguien abrió
una transacción y se fue a hacer otra cosa, que puede ser una llamada HTTP, un `sleep`, un cálculo
caro, o —como en el lab— quedarse bloqueado pidiendo una segunda conexión del mismo pool. La
consulta que lo destapa es `SELECT state, count(*), max(now() - state_change) FROM pg_stat_activity
WHERE datname = 'inv_lab' GROUP BY state`, y la columna de antigüedad te dice si es un pico o un
bloqueo. Del lado de la aplicación, la confirmación es
`HikariPool-1 - Pool stats (total=2, active=2, idle=0, waiting=6)`: `waiting` es el número que
cierra el caso.

**🔬 El detalle.** En producción esto se vigila con dos métricas de Actuator y no con `psql`:
`hikaricp.connections.pending` —los hilos en cola, que debería ser cero— y
`hikaricp.connections.usage`, que mide el **tiempo de retención** y es la variable que de verdad
predice el incidente antes de que ocurra. Postgres tiene además
`idle_in_transaction_session_timeout` para cortar sesiones abandonadas, que es una red de
seguridad del lado del servidor y no un sustituto de arreglar el código.

---

### L04 → 9

> `spring.jpa.show-sql=true` no te sirvió para diagnosticar el N+1. Nombra las tres cosas que
> configuras en su lugar y qué aporta cada una.

**⏱️ 30 segundos.** `org.hibernate.SQL: DEBUG` para las sentencias por el logger real —con
timestamp, hilo y `requestId`—, `org.hibernate.orm.jdbc.bind: TRACE` para el valor de cada
parámetro, y `hibernate.generate_statistics: true` para el contador de sentencias por sesión.

**🗣️ 2 minutos.** `show-sql` escribe por `System.out` saltándose el sistema de logging entero:
sin timestamp, sin nivel, sin hilo, sin correlación y sin parámetros. En tu terminal se lee; en un
agregador con cuarenta instancias es ruido. Y para un N+1 lo que necesitas no es leer el SQL sino
**contarlo**, y `stdout` no se puede filtrar por logger ni contar con garantías. `org.hibernate.SQL`
en `DEBUG` manda cada sentencia al logger con todo su contexto, incluido el `X-Request-Id` que
pusiste en el MDC, lo que permite atribuir las 21 consultas a una sola petición.
`org.hibernate.orm.jdbc.bind` en `TRACE` da los parámetros, que es como distingues veinte items
distintos de un mismo item consultado veinte veces —dos bugs diferentes con el mismo conteo—. Y
`generate_statistics` cierra el diagnóstico con un número que no depende de tu `grep`: el bloque
`Session Metrics` con `21 JDBC statements`.

**🔬 El detalle.** El logger de parámetros cambió de nombre entre Hibernate 5
(`org.hibernate.type.descriptor.sql.BasicBinder`) y Hibernate 6
(`org.hibernate.orm.jdbc.bind`), y esa es la causa de la mitad de las guías de internet que "no
funcionan". Y la advertencia obligatoria: activarlo escribe datos personales en claro en el log,
así que es una configuración de tu máquina y jamás de un entorno con datos reales.

---

### L04 → 10

> Añades `@EntityGraph(attributePaths = "events")` a una consulta paginada y aparece
> `HHH90003004: firstResult/maxResults specified with collection fetch; applying in memory`.
> ¿Qué está haciendo Hibernate, por qué, y en qué tamaño de tabla se convierte en un incidente?

**⏱️ 30 segundos.** Está trayendo **todas** las filas de la consulta y paginando en memoria de
la JVM, porque con un `JOIN FETCH` sobre una colección el `LIMIT` de SQL cortaría por la mitad de
una entidad. Es inofensivo con veinte items y es una caída con cien mil: el `OutOfMemoryError`
llega antes que la respuesta.

**🗣️ 2 minutos.** El `JOIN` multiplica filas: un item con tres eventos son tres filas en el
resultado. Si Hibernate aplicara `LIMIT 20`, obtendría veinte filas que corresponden a unos siete
items, con el séptimo a medio cargar; el resultado sería incorrecto, no solo raro. Como prefiere
ser correcto, trae el resultado entero, lo desduplica en memoria y después aplica la ventana. El
`WARN` es honesto y hay que leerlo como lo que es: *"hice lo que pediste, y lo hice de la peor
manera posible"*. La salida limpia son dos consultas deterministas: la primera trae la página de
ids con `LIMIT`/`OFFSET` reales, la segunda trae esos items con sus colecciones usando
`IN (:ids)`. Dos consultas fijas, independientes del tamaño de la página, y ningún N+1. La otra
salida, cuando no necesitas la colección entera, es proyectar directamente a un `record` con un
`count(e)` agrupado y no cargar la asociación en absoluto.

**🔬 El detalle.** El código `HHH90003004` pertenece al logger `org.hibernate.orm.query`, así que
aparece aunque no tengas el SQL en `DEBUG`. Y un detalle que sorprende: el mismo `@EntityGraph`
sin `Pageable` no produce ningún aviso y es perfectamente correcto — el problema no es el grafo,
es la combinación de grafo de colección con paginación.

---

### L04 → 11

> `LazyInitializationException: failed to lazily initialize a collection of role: … - no
> Session`: ¿qué objeto concreto lanzó eso, qué le faltaba, y por qué poner
> `open-in-view: true` es una mala respuesta aunque el endpoint pase a `200`?

**⏱️ 30 segundos.** Lo lanzó un **proxy de carga diferida** —la colección `PersistentBag` de
`events`, o el proxy de un `@ManyToOne` `LAZY`— al que le faltaba la `Session` de Hibernate que lo
creó, porque la transacción ya había cerrado el persistence context. `open-in-view: true` lo tapa
manteniendo la sesión abierta durante todo el request, y con eso ata la conexión del pool a la
velocidad del cliente y deja que la serialización dispare consultas fuera de transacción.

**🗣️ 2 minutos.** Lo que tienes en la mano cuando sacas una entidad del servicio no es la
entidad: es un objeto que sabe cómo pedir sus partes que faltan, y que para pedirlas necesita
seguir conectado. Cuando Jackson toca `getEvents()` fuera del método transaccional, el proxy
busca su `Session`, no la encuentra, y explota — normalmente a media serialización, con parte del
JSON ya escrito en el socket. El `open-in-view` de Boot mantiene esa sesión abierta hasta que se
escribe el último byte de la respuesta, lo que resuelve el síntoma y crea tres problemas: la
conexión del pool queda retenida durante toda la escritura de la respuesta —un cliente lento
ocupa una de tus diez conexiones—, las consultas de la serialización corren cada una en su
autocommit, así que el cuerpo puede reflejar un estado que nunca existió a la vez en la base, y,
sobre todo, desaparece la señal que te decía que tu límite transaccional estaba mal puesto. La
corrección real es decidir en el servicio qué necesita la respuesta, traerlo con `@EntityGraph` y
devolver un DTO.

**🔬 El detalle.** Boot avisa de esto en el arranque desde 2.0 con un `WARN` de
`JpaBaseConfiguration$JpaWebConfiguration` que dice literalmente *"database queries may be
performed during view rendering"*, y lo hace precisamente porque el default es `true` por
compatibilidad y no por criterio. Apagarlo es la única forma de que el `WARN` desaparezca, lo que
convierte la decisión en explícita — que es el verdadero objetivo del aviso.

---

### L04 → 12

> ¿Qué garantiza `ddl-auto: validate` y qué **no** detecta? Di si una columna de más en la
> tabla rompe el arranque.

**⏱️ 30 segundos.** Garantiza que **cada propiedad mapeada de tus entidades tenga una columna
compatible** en el esquema real, y rompe el arranque si no. No detecta nada al revés: una columna
de más en la tabla **no** rompe el arranque. Tampoco valida índices, defaults, reglas de negocio
ni la mayoría de las restricciones.

**🗣️ 2 minutos.** `validate` es una comprobación de dirección única, de las entidades hacia la
base, y esa asimetría es deliberada: la base puede tener columnas que tu aplicación no usa
—auditoría, otra aplicación, una migración a medias— y eso no es un error. Lo que sí detecta, y
es donde paga, es el desajuste que aparece cuando alguien añade un campo a la entidad y olvida la
migración: el arranque muere con `Schema-validation: missing column [category] in table
[inventory_item]`, en tu máquina y no en producción. Por eso la pareja natural es Flyway más
`validate`: Flyway es el dueño del esquema y `validate` es el guardián de que el mapeo encaja. En
este lab la columna `version` existe desde `V1` sin que ninguna entidad la mapee, y el arranque
pasa limpio; el día que añadas `@Version`, `validate` comprobará que el tipo coincide.

**🔬 El detalle.** La validación de tipos es más laxa de lo que parece: Hibernate compara
categorías de tipo, no definiciones exactas, así que un `VARCHAR(10)` contra un `String` sin
`length` no falla — y ese es justo el desajuste que produce un
`value too long for type character varying(10)` en producción. La longitud se declara en los dos
lados a propósito.

---

### L04 → 13

> Editas un `V1__` que ya se aplicó y el arranque muere. ¿Qué mensaje da Flyway, por qué ese
> comportamiento es una característica y cuál es el procedimiento correcto?

**⏱️ 30 segundos.** `FlywayValidateException: Validate failed: Migrations have failed validation
... Migration checksum mismatch for migration version 1`. Es una característica porque garantiza
que el esquema de todos los entornos se construyó con **exactamente** el mismo SQL. El
procedimiento correcto es escribir una migración nueva, `V2__`, que corrija lo que haga falta.

**🗣️ 2 minutos.** Flyway guarda en `flyway_schema_history` el checksum del contenido de cada
migración aplicada. Si el fichero cambia, el checksum deja de coincidir y Flyway se niega a
seguir, porque el entorno donde ya corrió `V1` tiene un esquema que ese `V1` editado nunca habría
producido: las dos bases divergieron en silencio. Una migración aplicada es inmutable, igual que
un commit publicado. El procedimiento es siempre hacia adelante —`V2__add_...`,
`V3__rename_...`— y eso deja además un registro legible de cómo evolucionó el esquema, que es la
mitad del valor de usar Flyway. En desarrollo, cuando el `V1` todavía no salió de tu máquina, el
camino honesto es destruir la base (`docker compose -p inv-lab down -v`) y volver a aplicarla
desde cero, no negociar con el checksum.

**🔬 El detalle.** Existen `flyway.repair` —que reescribe los checksums en el historial— y
`spring.flyway.validate-on-migrate=false`, y las dos son maneras rápidas de ocultar la divergencia
en vez de resolverla. `repair` tiene un uso legítimo: después de una migración fallida que dejó
una entrada marcada como no exitosa. Fuera de ese caso, usarlo para poder seguir editando un `V`
es convertir el historial en ficción. Las migraciones **repeatable** (`R__`) sí se reejecutan al
cambiar de checksum, y por eso son para vistas, funciones y procedimientos, no para DDL de tablas.

---

### L04 → 14

> Diferencia `docker compose -p inv-lab down` de `down -v` y di cuál de los dos explica que el
> lab te dé un resultado distinto al del documento.

**⏱️ 30 segundos.** `down` para y borra los contenedores pero **conserva los volúmenes con
nombre**; `down -v` borra además el volumen `inv-lab_postgres-data` y con él la base entera. El
que explica los resultados distintos es el primero: al volver a levantar encuentras las tablas,
las filas y el historial de Flyway de la sesión anterior.

**🗣️ 2 minutos.** El volumen es lo único del contenedor que está pensado para sobrevivirle, y
esa es su razón de existir: en producción no quieres perder la base cuando redespliegas. En un
lab produce el efecto contrario al deseado, porque todos los conteos de este documento —21
sentencias, 60 eventos, 63 filas antes y después— asumen una base construida por los pasos del
lab y por nada más. Si arrastras datos de ayer, el `POST` inicial devuelve `409` en vez de `201`,
el conteo del N+1 no da 21 y el `SELECT` de la sección 6 no cuadra, y pasarás veinte minutos
buscando un bug en tu código que está en tu volumen. Lo que **no** muere con ninguno de los dos
es la imagen descargada, el `~/.m2` y `target/`: eso se limpia en `L09`.

**🔬 El detalle.** `down -v` solo borra los volúmenes **declarados en ese `docker-compose.yml`**,
no los anónimos de contenedores creados a mano ni los de otro proyecto de Compose. `docker volume
ls | grep inv-lab` es la verificación de que murió de verdad, y `docker volume prune` es el
martillo que no hay que usar sin mirar qué más hay en la máquina.

---

### L04 → 15

> ¿Cuándo eliges `JdbcClient` sobre un repositorio de Spring Data JPA en este mismo servicio, y
> qué comparten los dos aunque parezcan caminos separados?

**⏱️ 30 segundos.** `JdbcClient` cuando **el SQL es el producto**: reportes, agregaciones,
cargas masivas, un `INSERT ... ON CONFLICT`, una consulta que revisó el DBA. JPA cuando el
producto es el grafo de objetos y su ciclo de vida. Y comparten lo que importa: **el mismo
`DataSource` y el mismo pool de Hikari**, así que compiten por las mismas conexiones y participan
en la misma transacción.

**🗣️ 2 minutos.** No son alternativas excluyentes: conviven en el mismo servicio y en el mismo
método si hace falta. La pregunta correcta no es "¿JPA o JDBC?" sino "¿esta consulta concreta la
quiero escribir yo o la quiero deducir de un mapeo?". Con `JdbcClient` lo que escribes es lo que
corre, se lo puedes pegar al DBA para que mire el plan, y no hay sorpresas de N+1, de flush ni de
lazy loading; a cambio mapeas a mano y no tienes dirty checking ni cascadas. Con JPA ganas el
ciclo de vida de las entidades y pierdes el control del SQL, que Hibernate genera con sus propios
alias. Lo que hace que la convivencia sea segura es que los dos van por el mismo
`DataSourceTransactionManager` o `JpaTransactionManager` y por el mismo
`TransactionSynchronizationManager`, así que un `JdbcClient` llamado dentro de un método
`@Transactional` usa **la conexión de esa transacción**, no una nueva.

**🔬 El detalle.** Esa última frase tiene una trampa práctica: si mezclas los dos dentro de una
transacción con JPA, el `JdbcClient` no ve lo que Hibernate todavía tiene pendiente en el
persistence context, porque el flush no ha ocurrido. Una consulta JDBC que busque una fila que
acabas de `persist()` puede no encontrarla. Hibernate hace flush automático antes de sus propias
consultas afectadas, pero no sabe nada del SQL que tú lanzas por tu cuenta.

---

## Lab L05 — Clientes HTTP y resiliencia

### L05 → 1

> ¿Qué significa exactamente `ResourceAccessException` y en qué se diferencia de
> `HttpServerErrorException`? ¿Cuál de las dos se reintenta y por qué?

**⏱️ 30 segundos.** `ResourceAccessException` significa que **no hubo respuesta**: envuelve
una `IOException` de transporte —timeout de lectura, socket cerrado, DNS, conexión
rechazada—. `HttpServerErrorException` significa que **sí la hubo y fue un 5xx**: el
proveedor contestó y te dijo que falló él. Las dos son reintentables, y por eso son las dos
únicas de la lista blanca del lab.

**🗣️ 2 minutos.** Las dos ramas cuelgan de sitios distintos:
`HttpClientErrorException` y `HttpServerErrorException` son hijas de
`RestClientResponseException`, que expone `getStatusCode()` y `getResponseBodyAsString()`
porque hay respuesta que leer. `ResourceAccessException` no tiene nada de eso, porque no
llegó nada. La distinción manda en la decisión de reintentar: un 5xx puede cambiar en el
segundo intento y un timeout también; un 4xx no va a cambiar nunca, y meterlo en el mismo
saco es lo que hace que un `sku` mal escrito abra un circuit breaker. En el lab, `ERR-000500`
produce la segunda y `SLW-000001` con `read-timeout: 3s` produce la primera, con el mensaje
literal `I/O error on GET request for "http://localhost:8090/suppliers/SLW-000001/quote":
Read timed out`.

**🔬 El detalle.** El reintento de un 5xx solo es correcto si además la operación es
idempotente. Un `GET` de cotización lo es; un `POST` que crea un movimiento no, y ahí un
timeout es el peor caso: puede que la petición llegara y se perdiera la respuesta, así que
reintentar duplica. La solución es una clave de idempotencia que el otro lado respete, y esa
conversación es de diseño de API, no de configuración del cliente.

---

### L05 → 2

> Diferencia `connect-timeout` de `read-timeout` y di cuál de los dos no salta nunca con un
> proveedor que responde goteando un byte cada dos segundos.

**⏱️ 30 segundos.** `connect-timeout` es el techo para **abrir** la conexión: handshake TCP
y TLS. `read-timeout` es el techo **entre dos bloques de bytes** de la respuesta. Con un
proveedor que gotea cada dos segundos y un `read-timeout: 3s`, **ninguno de los dos salta**:
la conexión se abrió rápido y ningún hueco entre bytes llega a tres segundos.

**🗣️ 2 minutos.** Ese matiz es el que hace que la gente crea que tiene un techo cuando no lo
tiene: `read-timeout` no es un límite por llamada, es por lectura. Una respuesta que tarda
cinco minutos en llegar entera, entregada en trocitos, es perfectamente compatible con un
`read-timeout` de tres segundos. El techo de la llamada completa lo pone un `TimeLimiter` de
Resilience4j sobre una ejecución asíncrona, y por eso `19` los presenta como mecanismos
distintos y no como sinónimos. `connect-timeout`, en cambio, es el que te salva cuando el
host no existe o el puerto está cerrado: sin él esperas el timeout del sistema operativo,
que en Linux ronda los 130 segundos.

---

### L05 → 3

> "El timeout por defecto es razonable." Corrige la frase con la versión precisa y di quién
> decide ese valor en un `RestClient` construido desde el `Builder` de Boot.

**⏱️ 30 segundos.** No hay timeout de lectura por defecto: **el default es esperar para
siempre**. Y ese valor no lo pone Spring, lo pone la librería HTTP que haya en el classpath
— el `HttpClient` del JDK no impone ninguno de lectura y Apache HttpClient 5 trae valores del
orden de minutos, inservibles para un servicio en línea. Quien decide de verdad es quien
escribe el cliente, poniendo `spring.http.client.connect-timeout` y `read-timeout`.

**🗣️ 2 minutos.** La frase de entrevista correcta es: *"el timeout de una llamada saliente es
una decisión de diseño que se deriva del presupuesto de tiempo del endpoint, no un default
que se hereda"*. Si `inv-api` promete responder en dos segundos y llama a dos proveedores en
serie, no puede darle dos segundos a cada uno. Y hay una trampa práctica: `RestClient.create()`
devuelve un cliente crudo, sin tus converters, sin tus `RestClientCustomizer` y **sin la
configuración global de `spring.http.client`**, así que el mismo YAML protege o no protege
según cómo construiste el cliente. Por eso el curso inyecta siempre `RestClient.Builder`.

**🔬 El detalle.** El pool de conexiones es la otra mitad y no se configura con esas
propiedades: es de la librería. Apache HttpClient 5 trae 25 conexiones totales y 5 por host,
y eso choca de frente con 200 hilos de Tomcat: el síntoma es
`ConnectionRequestTimeoutException: Timeout waiting for connection from pool`, que se parece
a lentitud del proveedor y es cola propia.

---

### L05 → 4

> En el threaddump, los hilos colgados aparecían como `RUNNABLE` y no como `BLOCKED`. ¿Por
> qué, y qué búsqueda equivocada hace esa diferencia?

**⏱️ 30 segundos.** Porque para la JVM un hilo parado en una lectura de socket **está
ejecutando** una llamada al sistema: el estado `BLOCKED` se reserva para la espera de un
monitor de Java, no para la espera de bytes. La búsqueda equivocada es filtrar el threaddump
por `BLOCKED` buscando un deadlock: no aparece nada y se concluye que la aplicación "está
bien, solo lenta".

**🗣️ 2 minutos.** Lo que hay que buscar es el **frame**, no el estado:
`sun.nio.ch.SocketDispatcher.read0` en la cima de la pila significa espera de bytes que no
llegan, es decir, timeout que falta. Su vecino peligroso es
`PoolingHttpClientConnectionManager.lease`, que significa cola por una conexión del pool.
Los dos producen el mismo síntoma para el usuario —todo va lento— y tienen arreglos
opuestos: en el primer caso subir `server.tomcat.threads.max` empeora las cosas, porque pone
más hilos a esperar al mismo proveedor enfermo.

**🔬 El detalle.** `SocketDispatcher.read0` es el nombre moderno; en material anterior a
JDK 13 verás `java.net.SocketInputStream.socketRead0`. Cambió la implementación de los
sockets, no el síntoma, y conviene reconocer los dos porque los runbooks viejos siguen
citando el segundo.

---

### L05 → 5

> `max-attempts: 3` con `read-timeout: 3s` y backoff de 200 ms y 400 ms: ¿cuánto puede
> tardar la operación completa en el peor caso, y qué le hace eso a un endpoint que promete
> dos segundos?

**⏱️ 30 segundos.** Tres intentos de hasta 3 s son 9 s, más 200 ms y 400 ms de espera: **9,6
segundos** en el peor caso. Un endpoint que prometía dos segundos incumple su contrato por
casi cinco veces, y lo hace **para no devolver nada**, porque si llega a los tres intentos es
que los tres fallaron.

**🗣️ 2 minutos.** La cuenta es la que casi nadie hace al añadir un reintento, y es la razón
de que el retry no sea gratis: `@Retry` es sincrónico y corre en el hilo del llamante, así
que el hilo de Tomcat está ocupado durante los tres intentos **y** durante los dos backoffs.
Reintentar es gastar tu capacidad para comprar la probabilidad de que el otro se recupere. La
respuesta de diseño es repartir el presupuesto de fuera hacia dentro: si el endpoint promete
2 s, el timeout por intento y el número de intentos tienen que caber dentro de esos 2 s
—por ejemplo 700 ms y dos intentos—, y lo que no cabe se resuelve con circuit breaker, que
elimina el peor caso en vez de estirarlo.

---

### L05 → 6

> ¿Qué cambia el jitter y qué **no** cambia? Responde con los dos números del experimento de
> la sección 4.

**⏱️ 30 segundos.** Cambia **cuándo** llegan las llamadas; no cambia **cuántas**. En el lab,
seis peticiones con cuatro intentos dieron **24 llamadas al proveedor en los dos casos**. Sin
jitter llegaron en cuatro bloques exactos de seis; con jitter, las 18 de reintento se
repartieron en cinco segundos en grupos de uno y de dos.

**🗣️ 2 minutos.** El daño del backoff sin jitter no es el volumen, es la sincronía: si cien
clientes fallan a la vez y todos esperan exactamente 1 s, 2 s y 4 s, el proveedor que
empieza a recuperarse recibe cien peticiones simultáneas y se vuelve a caer. Es un ariete
sincronizado que impide la recuperación, y lo construiste tú. El detalle que sorprende en el
experimento es que **el primer bloque sigue teniendo seis**: el jitter no separa el primer
intento, porque los clientes llegaron juntos por su cuenta; solo desincroniza lo que tú
controlas, que son los reintentos.

**🔬 El detalle.** El jitter tiene dosis. `randomized-wait-factor: 0.5` reparte cada espera
uniformemente entre el 50 % y el 150 % de la nominal; con `0.0` no hay aleatoriedad, y con
valores cercanos a `1.0` la espera mínima tiende a cero, lo que devuelve parte de la
sincronía porque muchos clientes reintentan casi de inmediato.

---

### L05 → 7

> Sin `retry-exceptions`, ¿qué reintenta Resilience4j, y cuántas llamadas costó en el lab un
> `sku` que el proveedor no conoce?

**⏱️ 30 segundos.** Sin lista blanca reintenta **cualquier excepción**, incluidos los 4xx. En
el lab, un `sku` desconocido costó **cuatro llamadas y 3,5 segundos** para acabar devolviendo
un error que ya estaba claro en la primera. Con la lista blanca, una llamada y 98
milisegundos.

**🗣️ 2 minutos.** La lista blanca correcta para este caso son
`ResourceAccessException` —transporte— y `HttpServerErrorException` —5xx del otro—. Todo lo
demás falla al primer intento. Existe también `ignore-exceptions` como lista negra sobre un
`retry-exceptions` amplio, y es peor idea: enumerar lo que sí se reintenta es una decisión
explícita, y enumerar lo que no deja la puerta abierta a la excepción que nadie previó. Como
segunda capa, el lab traduce el 404 a una excepción propia con `onStatus` antes de que el
retry la vea: aunque alguien amplíe la lista mañana, `UnknownSupplierSkuException` no está en
ella.

---

### L05 → 8

> Explica `minimum-number-of-calls` y `failure-rate-threshold`: ¿cuál es un conteo y cuál un
> porcentaje, y qué pasa si quitas el primero en un servicio con poco tráfico?

**⏱️ 30 segundos.** `minimum-number-of-calls` es un **conteo**: cuántas llamadas hacen falta
antes de que el breaker se permita decidir. `failure-rate-threshold` es un **porcentaje**
sobre esa ventana. Sin el primero, dos fallos seguidos en un servicio con poco tráfico dan un
100 % de tasa de error y abren el circuito por ruido.

**🗣️ 2 minutos.** Los dos trabajan sobre la ventana deslizante, y el tipo de ventana cambia
el significado de "últimas llamadas": `COUNT_BASED` mira las últimas N llamadas y va bien con
tráfico constante; `TIME_BASED` mira los últimos N segundos y es mejor con tráfico irregular,
porque no arrastra resultados de hace media hora. En el lab, con ventana de 10, mínimo de 5 y
umbral del 50 %, el circuito abrió en la **segunda** petición: cinco intentos del retry
bastaron para alcanzar el mínimo con un 100 % de fallos.

**🔬 El detalle.** Un circuito abierto con `register-health-indicator: true` pone
`/actuator/health` en `DOWN`. Si tu orquestador reinicia por health, acabas reiniciando tu
servicio porque el de otro está caído. Se controla con
`allow-health-indicator-to-fail: false`, y es una decisión que hay que tomar a propósito.

---

### L05 → 9

> Tu circuito no abre nunca aunque el proveedor tarda cinco segundos en cada respuesta.
> ¿Qué dos parámetros faltan y qué indicador lo confirma en `/actuator/circuitbreakers`?

**⏱️ 30 segundos.** Faltan `slow-call-duration-threshold` —a partir de cuánto una llamada se
considera lenta— y `slow-call-rate-threshold` —qué porcentaje de lentas abre el circuito—.
El indicador que lo confirma es `slowCallRate`: si vale `-1.0%`, el breaker ni siquiera está
midiendo lentitud.

**🗣️ 2 minutos.** Este es el caso que más daño hace y el que casi nadie configura, porque el
proveedor **no falla**: devuelve `200` con su JSON correcto, así que `failureRate` se queda
en `-1.0%` o en `0.0%` para siempre y el circuito no tiene motivo para abrir. Mientras tanto
cada petición te cuesta cinco segundos de hilo. En el lab, ocho peticiones contra un
proveedor de dos segundos con umbral de un segundo abrieron el circuito con `failedCalls: 0`
y `slowCallRate: 100.0%`: la prueba de que la latencia es un fallo aunque no lo parezca.

**🔬 El detalle.** El `-1.0%` no es un porcentaje negativo: Resilience4j usa `-1` para "aún
no hay datos suficientes para calcularlo", es decir, todavía no se alcanzó
`minimum-number-of-calls`. Leerlo como un valor real es un error de diagnóstico frecuente.

---

### L05 → 10

> ¿Quién lanza `CallNotPermittedException`, en qué hilo, y por qué esa llamada no gasta una
> conexión del pool HTTP?

**⏱️ 30 segundos.** La lanza **tu propio proceso**, no el proveedor: es el aspecto de
Resilience4j, en el **hilo del request**, a través del proxy que envuelve al bean. No gasta
conexión porque el circuito abierto corta **antes** de la llamada de red: no hay socket, no
hay handshake, no hay nada que pedirle al pool.

**🗣️ 2 minutos.** El mensaje literal es
`CircuitBreaker 'supplier' is OPEN and does not permit further calls`, y reconocerlo importa
porque quien lo ve por primera vez en un log de producción se va a buscar el problema a la
red o al otro servicio, cuando lo que hay es tu decorador funcionando. Ese corte antes de la
red es exactamente lo que salva tus hilos: un fallo que costaba tres llamadas y nueve
segundos pasa a costar cuatro milisegundos. Hacia fuera merece un `503` con `ProblemDetail`,
no un `500`: el `500` dice "me rompí" y el `503` dice "no puedo ahora, vuelve", que con el
circuito abierto es literalmente cierto y además es lo único que un cliente bien escrito sabe
reintentar.

**🔬 El detalle.** Es una `RuntimeException`, así que viaja por el mismo camino que cualquier
otra y la recoge el `@RestControllerAdvice`. Y comparte apellido de síntoma con
`BulkheadFullException`: las dos las lanza tu proceso y se distinguen por el sustantivo —
`Bulkhead` es "hay demasiadas a la vez", `CircuitBreaker` es "están fallando demasiadas".

---

### L05 → 11

> Escribe el orden correcto de apilado entre retry y circuit breaker, y di cuántas llamadas
> recibe el proveedor en cada orden con ocho peticiones y `max-attempts: 3`.

**⏱️ 30 segundos.** El correcto es `Retry( CircuitBreaker( llamada ))`: el retry por fuera.
Con ocho peticiones, ese orden dejó **5 llamadas** en el proveedor; el orden invertido,
`CircuitBreaker( Retry( llamada ))`, dejó **15**. La razón es que en el orden correcto el
breaker cuenta intentos y abre en la segunda petición, y en el invertido cuenta peticiones y
tarda hasta la quinta.

**🗣️ 2 minutos.** El apilado no lo decide el orden en que escribes las anotaciones: lo decide
el `order` de cada aspecto —`retry-aspect-order` y `circuit-breaker-aspect-order`— con la
regla de `Ordered` de Spring, donde **menor valor queda más afuera**. La ventaja real del
orden correcto es doble: los reintentos fallan rápido y sin salir a la red mientras el
circuito está abierto, y la protección llega antes porque el breaker ve cada intento. El
precio, que hay que decir en voz alta, es que **`minimum-number-of-calls` se alcanza con
intentos, no con peticiones**, así que ese número hay que ajustarlo sabiéndolo. En el orden
invertido el retry queda dentro y deja de existir como amortiguador en cuanto el circuito
abre: ninguna de las dos capas hace el trabajo que creías haberle asignado.

**🔬 El detalle.** Hay una tercera capa que no debe quedar por fuera de ninguna de las dos:
`@Transactional`. Un retry que envuelve una transacción abierta retiene la conexión del pool
durante todos los backoffs, que es el agotamiento de pool de `L04` con otro disfraz. En
`inv-api` no ocurre porque la llamada saliente vive fuera de la transacción, y eso fue una
decisión.

---

### L05 → 12

> ¿Por qué el bulkhead **no** hizo bajar `tomcat.threads.busy`, y de qué protege entonces?

**⏱️ 30 segundos.** Porque el bulkhead por semáforo **no libera el hilo de Tomcat**: la
petición rechazada sigue ocupando su hilo, solo que termina en 20 ms en vez de en 2
segundos. Protege a la **dependencia** —como mucho tres llamadas concurrentes hacia
`inv-supplier`— y, de rebote, acorta drásticamente la ocupación de tus hilos.

**🗣️ 2 minutos.** En el lab, diez peticiones concurrentes dejaron `tomcat.threads.busy` en
`10.0` con y sin bulkhead, y quien espere que ese número baje está midiendo el mecanismo
equivocado. Lo que cambia es el área bajo la curva: tres hilos ocupados dos segundos y siete
ocupados veinte milisegundos, en vez de diez ocupados dos segundos. Con carga sostenida esa
diferencia es la que impide que los endpoints que ni tocan al proveedor se queden sin hilos.
Limitar la concurrencia de tu servidor es otra cosa y se hace en Tomcat.

**🔬 El detalle.** `max-wait-duration: 0` es lo que hace que el rechazo sea inmediato. Con un
valor mayor que cero las sobrantes hacen cola, y una cola es otra forma de retener hilos:
tiene sentido si el pico es corto y conocido, y es una mala idea si la dependencia está
degradada, porque acabas con hilos esperando un permiso para esperar una respuesta.

---

### L05 → 13

> ¿Cuándo eliges bulkhead por semáforo y cuándo por thread pool? Nombra lo que se pierde
> con el segundo.

**⏱️ 30 segundos.** Semáforo cuando la llamada es bloqueante y quieres limitar concurrencia
sin cambiar de hilo —es el default y lo que casi siempre quieres—. Thread pool cuando además
necesitas **aislar la ejecución** para que la dependencia no toque nunca tus hilos de
request. Lo que se pierde con el segundo es todo lo que vive en un `ThreadLocal`: el
`SecurityContext`, el request id de correlación, el contexto de transacción y el MDC del log.

**🗣️ 2 minutos.** El thread pool aísla de verdad: aunque la dependencia se cuelgue entera,
solo consume los hilos de su propio pool. El precio es que el trabajo cambia de hilo, y en
Spring eso rompe silenciosamente cualquier cosa que viaje pegada al hilo —los mismos rotos
que produce `@Async` sin propagación de contexto—. Además obliga a que el método devuelva
`CompletableFuture`, así que no es una decisión que se tome cambiando una línea de YAML. La
regla práctica: semáforo por defecto, thread pool solo cuando el aislamiento justifique
reescribir la firma y propagar el contexto a mano.

---

### L05 → 14

> Un fallback mal firmado no rompe el arranque. ¿Cuándo te enteras, con qué excepción, y
> cuál es la prevención que sí funciona?

**⏱️ 30 segundos.** Te enteras en la **primera invocación del método anotado**, tenga éxito
o no — y no como un fallo, sino como un `WARN` de `FallbackExecutor` que dice
`No fallback method match found` y envuelve una `NoSuchMethodException`. La llamada sigue
adelante como si no hubiera fallback. La prevención que funciona es un test de integración
que fuerce el fallo y afirme sobre la respuesta degradada.

**🗣️ 2 minutos.** El detalle que lo hace peligroso es *cuándo* se resuelve: `FallbackExecutor.execute`
busca el método en cada invocación, **antes** de ejecutar el primario, no al crear el proxy. Así
que el aviso sale en la primera petición del día, mezclado con el arranque, y no la noche que el
proveedor se cae. Y no es una excepción que rompa nada: Resilience4j captura la
`NoSuchMethodException`, la registra y ejecuta el método **como si no hubiera fallback**, así que
ninguna petición falla por esto y el defecto sobrevive tranquilamente al despliegue. Si el mismo
`fallbackMethod` mal firmado está en dos anotaciones, salen dos avisos por cada invocación. Lo que
convierte esto en un fallo de build es un test que provoque el error real —con WireMock devolviendo
500, no con un mock— y compruebe que la respuesta lleva la marca de degradada; alertar sobre ese
`WARN` ayuda, pero llega tarde y depende de que alguien lea los logs.

**🔬 El detalle.** El mensaje de la `NoSuchMethodException` se lee al revés de como uno espera:
empieza por el **tipo de retorno** y lleva el prefijo `class` en cada tipo, algo como
`class com.example.InventoryDto com.example.InventoryClient.fallbck(class java.lang.String, class java.lang.Throwable)`.
La firma buscada repite la del método original y añade un `Throwable` final, así que ahí ves
escrito si lo que falló fue el nombre o el parámetro que falta. Conviene además no repartir el
mismo `fallbackMethod` por todas las anotaciones del método. En el lab está en `@CircuitBreaker` y
en `@Bulkhead` pero no en `@Retry`, porque el del retry se dispararía al agotar los intentos —algo
que el breaker ya cubre— y tener tres caminos hacia la misma respuesta degradada hace imposible
saber cuál actuó cuando lo estés diagnosticando.

---

### L05 → 15

> Da los tres rasgos de un fallback honesto y el caso en el que el fallback correcto es no
> tener ninguno.

**⏱️ 30 segundos.** Un fallback honesto **degrada en vez de mentir** —devuelve el último dato
conocido, marcado como tal—, **conserva la marca de tiempo original** para que el consumidor
pueda juzgar si le sirve, y **deja rastro en el log con la causa**. Y el fallback correcto es
no tener ninguno cuando no hay un dato viejo defendible: con dinero de por medio, un `503`
rápido es mejor que un precio inventado.

**🗣️ 2 minutos.** Las dos alternativas que se proponen siempre son peores que el error que
evitan: devolver `price: 0` convierte un fallo visible en corrupción silenciosa —alguien va a
vender a cero— y devolver `null` o una lista vacía sin marcarlo hace que el cliente muestre
un hueco sin saber por qué. El campo `"stale": true` del lab es barato y cambia la naturaleza
de la respuesta: el consumidor decide si muestra el precio con un aviso o no lo muestra. Y el
tercer rasgo es el que más se olvida: un fallback sin log convierte la caída del proveedor en
un misterio, porque todo "funciona", ningún tablero de errores sube y el problema se descubre
en una reconciliación tres días después.

**🔬 El detalle.** Por eso la alerta sobre el cambio de estado del circuito es parte del
patrón y no un extra. Un circuito que abre sin que nadie se entere es peor que no tenerlo:
enmascara la caída ajena detrás de respuestas degradadas tuyas. El lab mira los eventos a
mano y deja dicho que eso no es una alerta; la alerta de verdad se monta en `L07` sobre
`resilience4j_circuitbreaker_state`.

---

## Lab L06 — Caché y asincronía

### L06 → 1

> Con `@Cacheable` puesto y `@EnableCaching` ausente, ¿qué pasa exactamente y cuál es el
> primer indicio que lo delata?

**⏱️ 30 segundos.** No pasa **absolutamente nada**: sin `@EnableCaching` no se registra el
`CacheInterceptor`, así que la anotación es un comentario decorado. El arranque no falla, no
hay aviso y el método se ejecuta en cada petición. El primer indicio es el contador:
`inventory.repository.calls` sube con cada llamada, y `cache.gets` **no registra ni un `hit` ni
un `miss`**, porque nadie está consultando la caché.

**🗣️ 2 minutos.** Es el mismo patrón que `@EnableAsync` con `@Async` y por eso el lab pone las
dos anotaciones en su propia `@Configuration` (`CacheConfig`, `AsyncConfig`): el día que alguien
busque "quién encendió la caché", aparece en el primer `grep`. Y es la razón de que el
instrumento del lab sea un contador y no el log: una caché que funciona es **un método que no se
ejecutó**, y la ausencia no deja log, ni traza, ni excepción, ni código de estado raro.

**🔬 El detalle.** El síntoma es idéntico al de la self-invocation de la sección 3 —contador
que sube, ni `hit` ni `miss`—, así que hace falta un discriminante, y es barato: llama al método
**desde otro bean**. Si desde fuera tampoco cachea, el interruptor global es el que falta; si
desde fuera cachea y desde dentro no, el problema es el proxy. Confundir los dos cuesta una
tarde revisando claves de SpEL que estaban bien.

---

### L06 → 2

> Tu `@Cacheable` no registra ni un `hit` ni un `miss` en `cache.gets`, y el contador de
> llamadas al repositorio sube en cada petición. ¿Qué descartas y qué concluyes?

**⏱️ 30 segundos.** Descartas todo lo que produciría **`miss`**: clave mal calculada, TTL
demasiado corto, entrada desalojada por tamaño, `condition` o `unless` vetando la escritura.
Si no hay ni `miss`, **nadie consultó la caché**, y eso solo pasa si la llamada no atravesó el
proxy: self-invocation, o `@EnableCaching` ausente.

**🗣️ 2 minutos.** El lab lo mide de frente: pides tres veces el mismo SKU en una sola petición
a un método que llama a `this::valuation`, y el contador pasa de `1` a `4`. Tres consultas a la
base para un SKU **que estaba cacheado**: la caché tenía el dato y nadie se lo pidió. El
bytecode es un `invokevirtual` sobre `this`, y da igual que lo escribas como referencia a
método o con `this.` delante. La corrección que elige el curso es **sacar el método a otro
bean** —`InventoryValuationFacade`, que llama `valuations::valuation` sobre la referencia
inyectada, que sí es el proxy—, porque es la única que sobrevive a una lectura apurada.

**🔬 El detalle.** Las otras dos salidas se nombran para poder descartarlas en voz alta:
inyectarse a sí mismo el proxy con `@Lazy` o un `ObjectProvider`, que evita mover la clase pero
deja el truco escondido en el constructor, y el modo AspectJ con weaving, que quita la
limitación de raíz y añade una herramienta de build al proyecto. Y la aclaración que casi todo
el mundo dice mal: **no es cuestión de `public` o `private`**; un método privado no lo cachearía
ni una llamada desde fuera, porque CGLIB no puede sobrescribirlo, pero la causa de este fallo
concreto es desde dónde entra la llamada.

---

### L06 → 3

> ¿Por qué el lab cachea un `record ItemView` y no la entidad `InventoryItem`? Da las tres
> razones, cada una con el problema concreto que evita.

**⏱️ 30 segundos.** Una: la entidad llega **detached** fuera de la transacción y su colección
`events` es perezosa, así que tocarla desde la caché es una `LazyInitializationException`. Dos:
cachearla **duplica en heap** objetos que Hibernate cree suyos. Tres: al pasar a Redis habría
que **serializar un grafo con proxies dentro**. Se cachean DTOs.

**🗣️ 2 minutos.** Lo elegante del ejemplo es que las tres razones se cobran en tres secciones
distintas del mismo lab —la cuarta con la invalidación, la segunda con el heap, la sexta con la
serialización—, así que no es una regla de estilo, es tres facturas. El DTO sale de una
proyección por constructor en la propia consulta,
`select new com.invlab.invapi.inventory.ItemView(...)`, que devuelve cuatro columnas y construye
el `record` sin sesión abierta ni colección perezosa detrás; con `left join` y
`coalesce(sum(e.delta), 0)` para que un item sin movimientos devuelva `0` en vez de desaparecer.

**🔬 El detalle.** La regla general detrás: **se cachea el contrato de salida, no el modelo de
persistencia**. La entidad cambia cuando cambia el esquema; el DTO, cuando cambia la API. Y con
Redis esa diferencia deja de ser estética, porque el valor cacheado **sobrevive al despliegue**:
el JSON lleva `"@class"` dentro, así que el tipo viaja con el dato y renombrar o mover la clase
invalida todo lo cacheado. Un tipo que se mueve a menudo es mal candidato a estar dentro de un
valor persistido, y una entidad se mueve más que un DTO de salida.

---

### L06 → 4

> `recordStats` en Caffeine y `enableStatistics()` en el `RedisCacheManagerBuilder`: ¿qué
> se rompe si migras de store y olvidas el segundo?

**⏱️ 30 segundos.** Se rompe el **hit ratio**: `cache.gets` deja de existir en cuanto cambias de
store, `/actuator/metrics/cache.gets` devuelve un `404` que parece un bug de Boot y es tuyo, y
la caché sigue funcionando perfectamente. Es decir, no pierdes la caché: pierdes la única forma
de defenderla o de retirarla.

**🗣️ 2 minutos.** Son la misma decisión con dos nombres: en Caffeine, `recordStats` dentro de
`spring.cache.caffeine.spec`; en Redis, `enableStatistics()` sobre el builder dentro del
`RedisCacheManagerBuilderCustomizer`. Ninguno viene encendido, porque contar cuesta, y el olvido
es especialmente fácil en la migración porque todo lo demás sigue igual: la anotación no cambió,
la clave no cambió, el endpoint responde `200`. Ojo además con leer mal el dato:
`/actuator/metrics/cache.gets` sin filtrar devuelve la **suma** de hits y misses, así que hay
que pedir `?tag=cache:inventory-items&tag=result:hit` y `...&tag=result:miss` por separado.
Y `/actuator/caches` no mide aciertos: solo lista las cachés vivas y su `CacheManager`.

**🔬 El detalle.** Lo que de verdad se pierde es capacidad de diagnóstico, no un número bonito.
Sin `hit` ni `miss` no puedes distinguir "la caché acierta" de "nadie consulta la caché", que es
justo el bug de proxy de la sección 3; con las estadísticas apagadas, ese fallo se vuelve
invisible. Y el criterio de lectura: por debajo de ~0,8 en lecturas repetidas, lo primero que se
revisa es la **clave**, no el TTL — un hit ratio bajo con tráfico repetido casi siempre es una
clave que cambia entre llamadas.

---

### L06 → 5

> Explica por qué `@CacheEvict` sobre el método de escritura deja una ventana en la que otro
> hilo puede repoblar la caché con el valor viejo, y cuál es la forma limpia de cerrarla.

**⏱️ 30 segundos.** Porque el interceptor de caché borra **cuando el método retorna**, y el
commit de la transacción puede ocurrir **después**. Entre esos dos instantes, otro hilo que lea
verá todavía la base vieja y **repoblará la caché con el valor que acabas de invalidar**. La
forma limpia es invalidar desde un `@TransactionalEventListener(AFTER_COMMIT)`, que corre cuando
el dato nuevo ya es visible.

**🗣️ 2 minutos.** En el lab la ventana es microscópica y se asume a propósito, porque el TTL de
30 segundos la tapa: se declara en voz alta para que no te la saque un entrevistador. Lo que sí
se decide explícitamente es `beforeInvocation`, que se queda en su default `false`: si
`record(...)` lanza `InsufficientStockException` no hay nada que invalidar, y con `true`
borrarías la entrada en cada intento fallido y regalarías una consulta a la base por cada
movimiento rechazado.

**🔬 El detalle.** Hay un segundo motivo para no apilar interceptores sin pensar: el de caché y
el de transacción tienen el mismo `order` por defecto y **el orden entre ellos no está
definido**. Por eso el `@Cacheable` de `valuation` no lleva `@Transactional` — el problema se
evita, no se resuelve. Y el riesgo estructural es otro y más grande que la ventana: **toda ruta
de escritura sin anotar deja una entrada mintiendo hasta el TTL**. Hoy hay una sola; en cuanto
aparecen un job, un consumidor de eventos o un `UPDATE` administrativo, la invalidación por
evento deja de ser fiable y el TTL pasa a ser la red **bajo** el evento, nunca su alternativa.

---

### L06 → 6

> "Le puse `@CacheEvict`, la caché queda coherente." Corrige la frase con la versión precisa
> y di de qué depende la coherencia entre réplicas.

**⏱️ 30 segundos.** `@CacheEvict` invalida la caché **de este proceso**. Con N instancias tienes
N cachés independientes, y una invalidación en una no toca a las otras N−1, que seguirán
respondiendo el valor viejo hasta que expire su propio TTL. La coherencia entre réplicas **no es
una propiedad de la anotación: es una propiedad del store**.

**🗣️ 2 minutos.** El lab lo pone en dos líneas consecutivas de la terminal: con dos JVM contra
la misma base, tras un `POST` en la instancia A, la A contesta `"quantity":155` y la B
`"quantity":55`. Ninguna de las dos tiene un bug; la A invalidó bien y la B nunca se enteró de
que había algo que invalidar, porque `@CacheEvict` no es un broadcast y no hay ningún protocolo
escuchando en la otra JVM. La anotación hizo exactamente lo que promete; lo que estaba mal era
lo que tú creías que prometía.

**🔬 El detalle.** Detrás de un balanceador esto no se ve como un dato viejo: se ve como
**intermitencia**. El cliente refresca dos veces, cae en pods distintos y obtiene dos números
distintos, y el ticket llega escrito como "a veces sale bien y a veces mal". Y lo peor es que el
TTL lo tapa: a los 30 segundos las dos vuelven a coincidir, así que cuando alguien va a
reproducirlo ya no pasa. Con Redis, `redis-cli KEYS 'inv:*'` muestra **una sola** clave para las
dos instancias, y ahí se ve de un vistazo por qué la incoherencia desaparece: hay una entrada,
luego hay una invalidación.

---

### L06 → 7

> Enumera las tres salidas al problema de dos cachés locales incoherentes y di cuándo eliges
> la que no cuesta infraestructura.

**⏱️ 30 segundos.** **Bajar el TTL local**: barato y no arregla nada, solo acorta la mentira a N
segundos. **Mover la caché a un store compartido** (Redis): una entrada y una invalidación para
todas las réplicas. **Declarar la divergencia**: gratis y honesto, y es la que eliges cuando el
negocio tolera ese desfase y alguien lo escribe en el contrato.

**🗣️ 2 minutos.** La tercera es una respuesta legítima y casi nadie la da. Un catálogo de
productos con TTL de 60 segundos y dos réplicas no necesita Redis: necesita que el contrato diga
que el dato puede tener un minuto. Lo que no se puede hacer es tener el desfase **sin haberlo
decidido**. En el lab la respuesta es la segunda porque el dato es el stock y el consumidor es
un proceso de conciliación: ahí un minuto de desfase no es una molestia, es un descuadre.

**🔬 El detalle.** Elegir Redis es aceptar tres facturas, y conviene enumerarlas antes de
firmarlas: cada acierto deja de ser ~100 nanosegundos de heap y pasa a ser **una ida y vuelta
por la red** —décimas de milisegundo contra `localhost`, más en un clúster— **más deserializar
el JSON dentro del hilo del request**; el TTL por defecto del `RedisCacheManager` es
**infinito**, así que hay que ponerlo a mano con `entryTtl`; y metes una dependencia de
infraestructura nueva en el camino de **cada lectura**, que hay que tratar como el servicio
externo que es, con su `timeout`. La frase que resume el capítulo: **Redis no es una caché más
rápida, es una caché compartida**.

---

### L06 → 8

> Tu primera petición tras pasar a Redis falla con `DefaultSerializer requires a Serializable
> payload`. ¿Por qué no falla el arranque, y por qué la solución **no** es implementar
> `Serializable`?

**⏱️ 30 segundos.** No falla el arranque porque **nada en el contexto sabe qué tipos vas a
cachear**: no hay validación posible, y el problema aparece cuando el `RedisCache` intenta
escribir el primer valor con el `JdkSerializationRedisSerializer` que trae
`RedisCacheConfiguration.defaultCacheConfig()`. Y `implements Serializable` funciona, pero **ata
el valor binario a la clase y a su `serialVersionUID`**: en un despliegue gradual, la instancia
vieja lee lo que escribió la nueva y revienta al deserializar, con la caché llena de bombas que
explotan una por una.

**🗣️ 2 minutos.** La corrección son doce líneas en `CacheConfig`: un
`RedisCacheManagerBuilderCustomizer` que registre para `inventory-items` una configuración con
`serializeValuesWith(SerializationPair.fromSerializer(new GenericJackson2JsonRedisSerializer(mapper)))`,
`entryTtl(Duration.ofSeconds(30))`, `prefixCacheNameWith("inv:")` y `enableStatistics()`. Se usa
un **customizer** y no un bean `CacheManager` propio: declarar el tuyo te deja sin el resto de la
autoconfiguración, métricas incluidas, y te enteras cuando falte algo. Y el `ObjectMapper` se
**inyecta**, el del contexto con sus módulos —`JavaTimeModule` incluido—, para que la caché y la
API no serialicen las fechas distinto.

**🔬 El detalle.** Que el fallo llegue en runtime y en la primera petición es el mismo patrón que
el `fallbackMethod` mal escrito de `L05`, y la prevención es la misma: **un test que ejerza la
ruta**. Leer bien la traza también es parte: el `... 63 more` poda sesenta frames de
interceptores y proxies que no dicen nada, y lo que nunca se recorta es la línea del `Caused by`,
que es la que trae el nombre de tu clase. El JSON tampoco es neutro —el `"@class"` mete el nombre
del tipo dentro del dato, así que renombrar o mover la clase invalida todo lo cacheado—, pero es
mucho mejor compromiso: se lee con `redis-cli` y no ata el campo a un `serialVersionUID`.

---

### L06 → 9

> ¿Qué serializa Boot con `StringRedisSerializer` y qué con `JdkSerializationRedisSerializer`
> en la configuración de caché por defecto? ¿Dónde estaba entonces el caso de las claves
> binarias ilegibles?

**⏱️ 30 segundos.** En `defaultCacheConfig()`, las **claves** van con `StringRedisSerializer`
—por eso se leen desde el primer momento— y los **valores** con `JdkSerializationRedisSerializer`,
que es lo que explotó. El caso de las claves binarias ilegibles es el del **`RedisTemplate`
crudo**, que usa el serializador JDK a los dos lados.

**🗣️ 2 minutos.** La comprobación es directa: `redis-cli KEYS 'inv:*'` devuelve
`inv:inventory-items::ABC-000123`, legible entero y contando de dónde sale cada parte —prefijo,
nombre de caché, `::`, clave—. Ese `::` es el separador que pone Spring Data Redis y es lo que
permite borrar una caché completa con un patrón sin tocar las demás. Tenerlo claro evita el error
de diagnóstico más común aquí, que es ponerse a cambiar el serializador de claves cuando el que
falla es el de valores.

**🔬 El detalle.** El prefijo no es decorativo: sin `prefixCacheNameWith("inv:")`, dos servicios
con una caché del mismo nombre sobre la misma instancia de Redis se pisan los datos, y el
síntoma es un `ClassCastException` en el servicio que menos culpa tiene. Y dos lecturas más del
mismo `redis-cli`: `TTL` devolviendo `-1` significa "sin expiración", es decir que el `entryTtl`
no se aplicó a esa caché —casi siempre por escribir mal el nombre en `withCacheConfiguration`—; y
`KEYS` es para tu máquina y para nada más, porque recorre el keyspace completo y bloquea Redis
mientras lo hace, ya que ejecuta los comandos en un solo hilo. En producción, `SCAN`.

---

### L06 → 10

> ¿Qué corta `sync = true` y qué no corta? Responde con lo que ocurre con treinta peticiones
> a una clave fría en una instancia y en dos.

**⏱️ 30 segundos.** Corta el stampede **sobre la misma clave y dentro de la misma JVM**: un hilo
ejecuta el método y los demás esperan su resultado. Con treinta peticiones a una clave fría en
**una** instancia, el contador sube **una sola vez** y el `grep` del log devuelve `1`; en **dos**
instancias suben **dos**, una por proceso, porque la espera es intra-JVM. Y no corta la
expiración simultánea de **claves distintas**: para eso está el TTL con jitter.

**🗣️ 2 minutos.** Sin `sync`, el lab mide el fenómeno: treinta `curl` en paralelo con
`seq 1 30 | xargs -P 30` sobre un SKU nuevo dan un número que varía entre ejecuciones pero está
siempre muy por encima de uno y por debajo de treinta —del orden de una o dos decenas—, porque
treinta lectores llegaron antes de que el primero terminara de escribir. Detalles del atributo:
**no admite `unless`** y no todos los stores lo implementan; Caffeine sí, con su `LoadingCache`,
y el `RedisCache` de Spring Data Redis también. Para que fuera una sola ejecución de verdad
entre réplicas haría falta un lock distribuido —el `RLock` de la sección 9— o el cache writer con
bloqueo de Spring Data Redis, y ninguna de las dos es gratis.

**🔬 El detalle.** `sync = true` no es el default por algo: los hilos que esperan están
**bloqueados**. Si el método tarda dos segundos, tienes veintinueve hilos de Tomcat retenidos dos
segundos en vez de veintinueve consultas — cambias carga en la base por hilos en el servidor, que
es exactamente la palanca que agotó el pool en `L05`. Es el intercambio correcto cuando el método
es caro y la clave es popular, y el incorrecto cuando el método puede colgarse. Y si repites el
experimento, el `DEL` de la clave es parte del experimento: sin enfriarla, las treinta aciertan y
el contador no se mueve, lo cual "demuestra" algo que no es.

---

### L06 → 11

> Un `@Async` corre en `inv-task-2` y su log sale con `[sin-request-id]`. Nombra el
> mecanismo exacto que falta, en qué hilo hay que resolverlo y por qué ahí y no en otro.

**⏱️ 30 segundos.** Falta **propagación de contexto**: el MDC vive en un `ThreadLocal` y un
`ThreadLocal` no cruza a otro hilo. El gancho oficial es un **`TaskDecorator`** en el executor, y
la copia hay que tomarla **en el hilo que envía la tarea**, porque `decorate(...)` se ejecuta ahí
y es el único instante en el que están al alcance a la vez el contexto de origen y el `Runnable`
de destino. En el hilo que ejecuta ya no hay nada que copiar.

**🗣️ 2 minutos.** `[sin-request-id]` no es un literal casual: es el valor por defecto del patrón
`%X{requestId:-sin-request-id}` que escribiste en `L03` precisamente para este momento, así que
verlo significa "esta línea corrió fuera del alcance del filtro". `[inv-task-2]` es la buena
noticia —el trabajo salió del hilo de Tomcat y corrió en tu pool con el prefijo que le pusiste—.
En un incidente la diferencia es de diez minutos a una tarde: tienes el `requestId` que te dio el
cliente, haces `grep`, y las líneas que explican qué pasó **después** de la respuesta no
aparecen. El decorador se copia con `MDC.getCopyOfContextMap()` —una copia, no una vista, que es
justo lo que quieres porque el filtro limpia el MDC en su `finally`— y hay que comprobar el
`null`, porque `MDC.setContextMap(null)` lanza `NullPointerException` y la tarea del `@Scheduled`
llega sin ningún contexto.

**🔬 El detalle.** El mismo mecanismo se lleva otras dos cosas que hay que poder enumerar: el
`SecurityContext` —cuyo síntoma es una `AccessDeniedException` con un usuario que sí tiene el
rol— y el `RequestContextHolder`, que da `IllegalStateException: No thread-bound request found`.
Y los decoradores oficiales que hacen esto por ti cuando llegan sus dependencias:
`ContextPropagatingTaskDecorator`, de Spring Framework 6.1+, que arrastra todo lo registrado en
Micrometer Context Propagation —incluido el `traceId` de verdad, el del capítulo `23`— y
`DelegatingSecurityContextAsyncTaskExecutor`, que **decora al pool por fuera** en vez de sustituir
tu decorador. Escribir el tuyo primero no es trabajo tirado: es la única forma de saber qué hacen
esos dos por dentro.

---

### L06 → 12

> ¿Por qué el `MDC.clear()` del `TaskDecorator` va en un `finally`, y qué síntoma produce
> olvidarlo? Relaciónalo con el bug del filtro de `L03`.

**⏱️ 30 segundos.** Porque **los hilos del pool se reutilizan** y hay que limpiar aunque la tarea
lance. Si no lo haces, la tarea siguiente **hereda el `requestId` de la anterior** y el log
atribuye ese trabajo a la petición equivocada: no hay error, no hay excepción, solo un log que
miente con confianza.

**🗣️ 2 minutos.** Es exactamente el bug del filtro de `L03`, donde el `X-Request-Id` se filtraba
a la petición siguiente porque los hilos de Tomcat también se reutilizan; cambia el pool
—`ThreadPoolTaskExecutor` en vez del de Tomcat— y no cambia nada más. Un matiz que sí cambia:
aquí es `clear()` y no `remove("requestId")`, porque lo que restauramos fue **el mapa entero**
con `setContextMap`, así que hay que dejar el hilo como lo encontramos.

**🔬 El detalle.** El síntoma es de la peor familia que hay: correlación **incorrecta** es peor
que correlación ausente. Con `[sin-request-id]` sabes que perdiste el hilo de la historia; con un
`requestId` heredado, haces `grep` de una petición y te llevas líneas de otra, y construyes una
explicación coherente de un incidente que no ocurrió. Por eso la limpieza va en `finally` y no al
final del `try`: una tarea que lanza —y con `AbortPolicy` y colas acotadas las hay— dejaría el
hilo contaminado para siempre.

---

### L06 → 13

> `tryLock(0, 15, TimeUnit.SECONDS)`: di qué es cada número y qué pasa si el trabajo
> protegido tarda veinte segundos.

**⏱️ 30 segundos.** El primero es el **tiempo de espera** por el lock: cero, porque si otra
instancia ya está refrescando no hay nada que hacer aquí, y la tuya cede. El segundo es el
**`leaseTime`**: cuánto lo retienes como máximo **aunque tu proceso muera**. Si el trabajo tarda
veinte segundos, a los quince el lease expira, otra instancia toma el lock y **las dos acaban
dentro de la sección protegida a la vez**, sin ningún aviso.

**🗣️ 2 minutos.** Sin `leaseTime`, un proceso que se cae con el lock tomado bloquea a los demás
**para siempre**, así que quitarlo no es una opción: el lease es obligatorio y por eso es una
apuesta sobre la duración del trabajo, que hay que declarar como tal. El patrón completo son las
dos mitades: `unlock()` en un `finally` para el caso normal y el lease para el catastrófico.
`tryLock` declara `InterruptedException` porque `RLock` extiende `Lock`; se propaga en la firma o
se captura restaurando el flag con `Thread.currentThread().interrupt()`, pero tragársela deja un
hilo que ya no sabe que le pidieron parar.

**🔬 El detalle.** Y por eso esto es **una optimización, no una garantía de corrección**. Es un
lock sobre **una sola** instancia de Redis: si hace failover a una réplica que no alcanzó a
recibir la clave, dos procesos lo tienen a la vez. Redlock —el algoritmo sobre N instancias—
nació para eso y está discutido, y la crítica vale para los dos: **sin fencing token no hay
exclusión mutua** ante una pausa de GC o un reloj desviado, porque tu proceso puede creer que
tiene el lock cuando el lease ya expiró. El fencing token —un número que crece con cada concesión
y que el recurso protegido verifica y rechaza si viene atrasado— **exige colaboración del
recurso**, no del lock. Si de la exclusión depende la corrección, se resuelve donde está el dato:
restricción única, `UPDATE ... WHERE version = ?`, idempotencia.

---

### L06 → 14

> ¿Qué te da un `RLock` de Redisson, qué no te da, y qué aporta ShedLock que aquí tuviste
> que escribir a mano?

**⏱️ 30 segundos.** `RLock` te da una **primitiva de coordinación de propósito general** —como
`RSemaphore` o `RRateLimiter`— con espera y lease, y con ella el job pasa de seis ejecuciones por
minuto a tres entre dos instancias. No te da **corrección**: es un solo Redis, no hay fencing
token, y el cableado —`tryLock`, `finally`, `unlock`— lo escribes tú. ShedLock hace justo una
cosa, envolver métodos `@Scheduled` con `@SchedulerLock`, y trae los dos parámetros que aquí
quedaron implícitos: **`lockAtMostFor`**, que es el lease con otro nombre, y **`lockAtLeastFor`**,
que impide que dos relojes ligeramente desfasados ejecuten dos veces seguidas.

**🗣️ 2 minutos.** Detalles que se preguntan: el proveedor de ShedLock puede ser Redis, una tabla
de Postgres o media docena más, y en la línea 6.x —`net.javacrumbs.shedlock:shedlock-spring:6.10.0`—
corre sobre Spring Framework 6.2, que es el baseline del curso; la 7.x ya exige Spring 7. Y en el
lado de Redisson, la decisión de dependencia también es material de entrevista: se usa `redisson`
y **no** `redisson-spring-boot-starter`, porque el starter sustituye la `RedisConnectionFactory`
del contexto por la suya y tu caché pasaría a hablar por Redisson sin que lo pidieras. Aquí
Lettuce para la caché y Redisson **solo** para el lock, las dos cosas visibles en la
configuración.

**🔬 El detalle.** Ninguno de los dos garantiza más de lo que parece: **si quien tomó el lock
muere a la mitad, esa ejecución se pierde hasta la vuelta siguiente**, que en un job diario
significa hasta mañana. Por eso el lock no es la primera salida, sino la segunda de tres:
hacer el job **idempotente** —que es lo que ya es este refresco, porque refrescar una caché tres
veces deja el mismo resultado y solo cuesta consultas—, el lock distribuido, o un **scheduler
externo** cuando la ejecución ya es una operación de negocio con su auditoría. Aquí el daño de
duplicar era barato; cambia el job por "aplicar el interés a las cuentas" y las seis ejecuciones
son un interés triplicado.

---

## Lab L07 — Actuator, métricas y trazas

### L07 → 1

> `GET /actuator/prometheus` devuelve `404` y la propiedad `include` lo menciona. Enumera las tres
> causas posibles y el comando que distingue cada una de las otras dos.

**⏱️ 30 segundos.** Tres, y ninguna da un mensaje: **el endpoint no existe** porque falta la
dependencia que lo autoconfigura, **no está en `include`**, o **está también en `exclude`**, que
gana siempre. El comando que las separa es `curl -s localhost:8081/actuator | jq -r '._links |
keys[]'`: lo que no aparece ahí no se sirve, y Actuator lo contesta con `404`, no con `403`.

**🗣️ 2 minutos.** El discriminante es en dos pasos. Si el endpoint **no aparece en el índice** y
tampoco aparece tras añadirlo a `include`, es dependencia: `PrometheusScrapeEndpoint` solo se
autoconfigura si hay un `PrometheusMeterRegistry` en el contexto, y para eso hace falta
`micrometer-registry-prometheus`. Si **aparece al añadirlo**, era exposición. Y si está en
`include`, la dependencia está y aun así no aparece, queda `exclude`, que es la más difícil de
ver porque el YAML donde miras dice que sí está expuesto. Con la premisa del enunciado —`include`
ya lo menciona— las dos vivas son dependencia y `exclude`.

**🔬 El detalle.** Este lab te enseña una cuarta variante del mismo `404`, y conviene tenerla
aparte para no confundirla: `httpexchanges` está expuesto, la clase existe y aun así responde
`404` hasta que registras tú el bean `HttpExchangeRepository`, porque Boot no guarda peticiones
reales en memoria por defecto. Es la misma familia —"expuesto no significa publicado"— con una
condición distinta. Y el `403` sí existe, pero solo con Spring Security delante: entonces el
código te está diciendo "el endpoint está ahí y tú no tienes permiso", que es información
distinta.

---

### L07 → 2

> ¿Qué gana exactamente el puerto de management separado que no gane exponer menos endpoints, y
> qué prueba de `L05` lo demuestra?

**⏱️ 30 segundos.** Gana **un pool de hilos propio**. Exponer menos endpoints reduce la
superficie de ataque, pero no evita que el diagnóstico compita con el negocio: si `health` vive
en el `8080` y los hilos de Tomcat están agotados, el health check deja de contestar justo cuando
más falta hace. Con `management.server.port: 8081` ese conector tiene su propia cola.

**🗣️ 2 minutos.** La prueba es la sección 3 de `L05` y se repite hoy en la sección 11: doce
peticiones concurrentes al proveedor lento con `server.tomcat.threads.max: 10` dejan
`tomcat.threads.busy` en `10.0` y `/actuator/health` respondiendo `200`. Ese par de números es el
argumento entero: la instancia está **llena**, no **rota**, y el orquestador lo puede distinguir
porque pregunta por otro puerto. Sin la separación, el kubelet no recibe respuesta, interpreta el
timeout como caída y reinicia una instancia que solo estaba saturada — y se lleva por delante la
única evidencia del incidente. El segundo beneficio es de red y va en la misma propiedad:
`management.server.address` liga ese conector al loopback, así que el puerto de negocio puede
cruzar el firewall y el de management no.

**🔬 El detalle.** El costo es un pool de hilos —diez sobran— y unos pocos MB, que es barato
comparado con lo que compra. Dos trampas que van con el puerto propio: `management.server.base-path`
**solo** aplica cuando hay puerto separado, y confundirlo con `management.endpoints.web.base-path`
da un `404` que parece de exposición; y ligar el conector al loopback te rompe el scrape en cuanto
el que raspa vive en un contenedor, que es exactamente el choque de la sección 7.

---

### L07 → 3

> Tu `SupplierHealthIndicator` está en el grupo `liveness` y el proveedor lleva diez minutos
> caído. Describe qué hace el orquestador y por qué es el peor resultado posible.

**⏱️ 30 segundos.** El orquestador **reinicia el contenedor**, y como el proveedor sigue caído,
lo reinicia otra vez, y otra. Es el peor resultado posible porque el reinicio no arregla nada —el
que está roto es otro proceso— y además tira tus réplicas **sanas**: pierdes la caché caliente,
los contadores en memoria y el estado con el que estabas diagnosticando.

**🗣️ 2 minutos.** La clave es qué decide cada sonda. `liveness` en `DOWN` significa "este proceso
solo se arregla matándolo", así que ahí va un deadlock o un heap agotado, nunca una dependencia
externa. `readiness` en `DOWN` significa "ahora mismo no puedo atender", saca la instancia del
balanceador y la devuelve sola cuando la dependencia vuelve. Por eso el lab pone
`readinessState,db,redis,supplier` en `readiness` y **solo** `livenessState` en `liveness`, y por
eso al parar WireMock la medición es `503` en `health`, `503` en `readiness` y `200` en
`liveness`: dejas de recibir tráfico y nadie te reinicia. Con el indicator en `liveness`, además,
el daño se multiplica por réplicas: la dependencia caída es **común a todas**, así que todas se
reinician a la vez y el proveedor —o la base— recibe N arranques simultáneos justo cuando
empezaba a recuperarse.

**🔬 El detalle.** Hay un segundo error escondido en el mismo sitio: un `HealthIndicator` corre
**en el hilo que atiende la consulta**, y quien consulta suele ser el orquestador cada pocos
segundos. Por eso el del lab se construye desde el `RestClient.Builder` inyectado, que ya trae
`connect-timeout: 2s` y `read-timeout: 3s`: un health check sin timeout es el peor sitio donde
falta uno. Y si de verdad no puedes decidir, existe `Health.unknown()`, que se traduce a `200` y
por tanto no saca la instancia de ningún sitio.

---

### L07 → 4

> "El health está verde, así que el servicio funciona." Corrige la afirmación con precisión y di
> qué señal sí lo contestaría.

**⏱️ 30 segundos.** La versión precisa es: **`health` no dice "funciona", dice "los indicators
que yo agrego contestaron `UP` en el instante en que preguntaste"**. No sabe nada de latencia, ni
de tasa de error, ni de si el circuito de `L05` lleva veinte minutos devolviendo fallbacks. Lo que
sí lo contesta son las cuatro señales doradas, y para el caso del circuito, una alerta sobre su
cambio de estado.

**🗣️ 2 minutos.** El contraejemplo lo construye el propio lab y es demoledor: con el circuito
abierto, `inv-api` responde `200` a todo el mundo con la última cotización conocida, el health
está verde, el panel de errores se ve **mejor que ayer** y el incidente lleva veinte minutos
abierto. Las señales que sí lo dicen son el p95 de `http_server_requests_seconds_bucket` por
`uri`, la tasa de `http_server_requests_seconds_count`, la **proporción** de
`outcome="SERVER_ERROR"` y la saturación (`hikaricp_connections_pending`,
`tomcat_threads_busy_threads`) — y, para este caso concreto,
`resilience4j_circuitbreaker_state{name="supplier",state="open"} == 1`.

**🔬 El detalle.** El error simétrico también hay que saber corregirlo: un `health` en `DOWN`
tampoco significa "estoy roto". El agregado toma **el peor estado de todos sus componentes**, sin
grados, así que con Postgres, Redis y el disco perfectos el agregado dice `DOWN` porque el
proveedor no contesta. Ahí está la razón de ser de los grupos: el agregado es para mirarlo tú, los
grupos son para que decida una máquina. Y en producción `show-details` va en `when-authorized`,
porque el detalle del health nombra tus dependencias internas.

---

### L07 → 5

> Cambias un nivel con `POST /actuator/loggers/...` y no aparece nada nuevo en el log. Enumera las
> causas en el orden en que las revisarías, contando la que tiene que ver con las réplicas.

**⏱️ 30 segundos.** En este orden: **¿aceptó el `POST`?** (`204`, no `415`), **¿quedó fijado el
nivel?** (un `GET` al mismo logger), **¿es el logger correcto?**, **¿pasó tráfico que llegue a ese
código?** y, la que se lleva la palma, **¿preguntaste a la instancia correcta?** — el cambio vive
solo en memoria de **la réplica que atendió tu `curl`**.

**🗣️ 2 minutos.** El `415` es el primero porque es el más frecuente y el menos sospechado: `curl
-d` manda `application/x-www-form-urlencoded` y el endpoint solo acepta JSON, así que sin
`-H 'Content-Type: application/json'` la escritura no ocurre y el código no es `400` ni `404`. El
segundo paso es leer: `effectiveLevel` es el que está actuando, heredado del padre;
`configuredLevel` es el que alguien fijó explícitamente aquí. El tercero es de alcance: el nivel
se aplica al logger **y a todos sus hijos**, de modo que `org.hibernate.SQL` no imprime los
parámetros que sí imprimiría `org.hibernate`; se sube por el paquete más estrecho que conteste la
pregunta, pero hay que asegurarse de que sea el que la contesta. El cuarto es de método: si la
caché está caliente, la consulta no baja a la base y no hay línea que ver — por eso el lab hace
`redis-cli DEL` de la clave antes de medir. Y el quinto es el de las réplicas: con seis detrás de
un balanceador, o repites la llamada seis veces o el log que buscas está en la que no tocaste.

**🔬 El detalle.** Dos cosas que se aprenden con este endpoint y sirven para toda la vida. Una:
para deshacer se manda `{"configuredLevel":null}`, que **borra** la configuración explícita;
mandar `{"configuredLevel":"INFO"}` deja el logger clavado en `INFO` y se nota el día que subes el
nivel del paquete padre y este no se mueve. Dos: un `403` aquí no es un problema de formato, es
que hay seguridad delante y tu usuario no tiene permiso de escritura sobre los endpoints — hoy no
puede pasarte porque no hay Spring Security, y con él es el síntoma normal.

---

### L07 → 6

> ¿Por qué el `Timer` de este lab está **dentro** del `@Cacheable` y no alrededor del endpoint?
> ¿Qué mediría cada una de las dos opciones?

**⏱️ 30 segundos.** Porque el `Timer` tiene que medir **el coste real de calcular contra la
base**, y el interceptor de caché envuelve al método: un acierto ni siquiera entra en el cuerpo.
Alrededor del endpoint mediría **la latencia que ve el cliente**, que ya la mide
`http.server.requests` y que mezcla aciertos y fallos de caché en el mismo número.

**🗣️ 2 minutos.** Son dos preguntas distintas y por eso son dos medidores distintos. Dentro:
"¿cuánto tarda la consulta que de verdad se ejecutó?" — sube si la base se degrada, y su `count`
es literalmente el número de fallos de caché. Fuera: "¿cuánto espera quien llama?" — que es la
señal de latencia del tablero. Si mides las dos cosas con el mismo medidor obtienes lo peor de
los dos mundos: un p95 que **baja** cuando la caché acierta más, que no dice nada de la salud de
la base y que tampoco es la experiencia del cliente, porque la mayoría de las muestras son
aciertos de microsegundos.

**🔬 El detalle.** Dos matices del `Timer` de esta sección. Uno: `timer.record(Supplier)` mide en
un `finally`, así que **la excepción también cuenta**; un `Timer` no distingue éxito de fallo
salvo que le pongas un tag, y ese tag tiene que tener un conjunto cerrado de valores —que es
exactamente la disciplina de la sección 6—. Dos: cuando el inicio y el fin están en métodos
distintos, la forma correcta no es este `record` sino `Timer.Sample` con `start`/`stop`. Y el
medidor se resuelve **una vez en el constructor** y se guarda en un campo, en vez de buscarlo en
un mapa concurrente en cada invocación.

---

### L07 → 7

> Pusiste `@Timed` y la métrica no existe: nombra las dos condiciones que hay que cumplir para que
> la anotación se registre, y la tercera que la deja sin efecto aunque se cumplan las dos.

**⏱️ 30 segundos.** Las dos condiciones: **`management.observations.annotations.enabled: true`**
—por defecto vale `false`, así que Boot no registra el `TimedAspect` ni el `CountedAspect`— y
**AspectJ en el classpath**, porque ese aspecto está condicionado a `org.aspectj.weaver.Advice`, y
eso llega con `spring-boot-starter-aop`. La tercera, que la deja sin efecto cumplidas las dos: la
**self-invocation**.

**🗣️ 2 minutos.** El lab lo mide de frente para que no quede duda de que el fallo es silencioso:
con la anotación puesta y sin las dos condiciones,
`/actuator/metrics/inventory.valuations.batch` responde `404`, el `Timer` registrado a mano
responde `200` y `grep -ci 'timedaspect' app.log` devuelve `0`. No hay aviso, no hay excepción y
la anotación se lee perfectamente bien en una revisión de código. La tercera causa es la de
siempre: `@Timed` se aplica con **un aspecto sobre un proxy**, así que una llamada desde otro
método de la misma clase no lo atraviesa y no mide nada. Por eso la anotación del lab está en el
*facade* de `L06` y no en `InventoryValuationService`.

**🔬 El detalle.** Con las tres resueltas, `@Timed` y el `Timer` a mano hacen lo mismo y la
elección es de estilo: la anotación no ensucia el método pero **no puede medir un tramo interno ni
controlar los tags**; el `Timer` explícito mide exactamente lo que quieres y se ve en el código.
Y el mismo proxy impone lo de siempre: sobre un método `private` o `final` la anotación tampoco
hace nada, porque CGLIB no puede sobrescribirlo. `measurements` trae `COUNT`, `TOTAL_TIME` y
`MAX`; el único valor que tiene sentido fijar en una comprobación es el `COUNT`.

---

### L07 → 8

> Explica por qué `publishPercentileHistogram()` y no `publishPercentiles(0.95)` cuando hay seis
> réplicas detrás de un balanceador.

**⏱️ 30 segundos.** Porque **un percentil no se puede promediar**. `publishPercentiles(0.95)`
calcula el número dentro de cada JVM y publica seis valores que no se pueden juntar: la media de
dos p95 no es el p95 de nada. `publishPercentileHistogram()` publica **buckets acumulativos**, una
serie por `le`, y esos sí se suman entre réplicas: el percentil se calcula al agregar, en
Prometheus.

**🗣️ 2 minutos.** El patrón completo es
`histogram_quantile(0.95, sum by (le, uri) (rate(http_server_requests_seconds_bucket[5m])))`, y se
lee de dentro afuera: `rate` convierte el contador acumulativo de cada bucket en incrementos por
segundo, `sum by (le, uri)` junta las seis réplicas conservando el límite del bucket y la ruta, y
`histogram_quantile` interpola el cuantil sobre esa distribución. **Si olvidas `le` en el `by`, la
función no tiene con qué trabajar y devuelve vacío**, que es el error número uno con histogramas.
Y para `http.server.requests` hay que encender los buckets por configuración
(`management.metrics.distribution.percentiles-histogram.http.server.requests: true`), o
`http_server_requests_seconds_bucket` no existe y el panel de p95 sale en blanco con la métrica
perfectamente presente.

**🔬 El detalle.** Nada de esto es gratis: **cada bucket es una serie más por combinación de
tags**, así que un histograma multiplica la cardinalidad de la métrica que instrumenta — es la
otra mitad de la cuenta de la sección 6. Por eso `slo: 50ms,200ms,500ms,2s` son cuatro valores
elegidos y no veinte: añaden buckets exactos en esos límites, que es lo que permite preguntar "¿qué
proporción bajó de 200 ms?" con una sola división y calcular un error budget. Y el precio que se
paga a cambio de poder agregar es la precisión: el cuantil sale **interpolado** entre los límites
de los buckets, no medido.

---

### L07 → 9

> Trescientas peticiones con un tag `sku` dejaron 300 series. ¿Por qué el daño no se limita a esa
> métrica, y por qué tampoco desaparece al desplegar la corrección?

**⏱️ 30 segundos.** Porque el backend de métricas es **compartido**: la memoria y el índice que
se comen esas series son los de Prometheus, y cuando el kernel lo mata pierdes **todas** las
métricas, también las de los servicios de los demás. Y no desaparece al desplegar porque en tu JVM
el registro vive en memoria y se va al reiniciar, pero **en Prometheus las series quedan hasta que
expire la retención**.

**🗣️ 2 minutos.** El experimento del lab es deliberadamente humilde —300 peticiones, 300 series—
y su forma es la peor posible: series que nacen con valor `1`, se escriben una vez y no se vuelven
a incrementar nunca, porque nadie repite ese SKU. El daño se cobra en tres sitios a la vez: el
endpoint **serializa todo el registro en cada scrape**, del orden de cien bytes por serie cada
quince segundos, para siempre; el proceso de la aplicación paga heap por cada medidor vivo; y el
índice de Prometheus paga por cada serie aunque nadie la consulte, lo que convierte un error de
una tarde en una semana de compactaciones. Escala la cuenta y se entiende la alarma: 50 000 SKU
reales por tres valores de `outcome` son 150 000 series **de una sola métrica**, y con histograma
multiplicas además por el número de buckets.

**🔬 El detalle.** Lo más incómodo del experimento es que **el `404` no te salvó**: el contador se
incrementa antes de la consulta, así que cualquiera que pueda inventar SKU en la URL te fabrica
series de tiempo. Con un tag sobre un identificador que viene del cliente, la cardinalidad deja de
ser un error de diseño y pasa a ser un vector de denegación de servicio contra tu backend de
métricas. El fusible —`MeterFilter.maximumAllowableTags(..., "sku", 100, MeterFilter.deny())`, y
su equivalente `management.metrics.web.server.max-uri-tags: 100` para `http.server.requests`— es
un tope, **no una cura**: no borra las 100 que ya entraron ni repara la explosión ocurrida; y
cuando actúa lo dice con un `WARNING` de Micrometer, que es lo que hay que buscar cuando un panel
"deja de tener datos nuevos".

---

### L07 → 10

> `up{job="inv-api"}` vale `0` y tu `curl localhost:8081/actuator/prometheus` responde `200` desde
> la terminal. ¿Cuál es la causa más probable con este montaje y cómo se confirma?

**⏱️ 30 segundos.** `management.server.address: 127.0.0.1`. Tu `curl` sale del loopback de la
máquina y entra; el contenedor de Prometheus llega por la interfaz del gateway
(`host.docker.internal`), que **no es** tu loopback, así que el sistema operativo rechaza la
conexión antes de que Tomcat se entere. Se confirma preguntándole al que raspa, no al que sirve.

**🗣️ 2 minutos.** El comando es
`curl -s localhost:9090/api/v1/targets | jq -c '.data.activeTargets[] | {job: .labels.job, health,
lastError}'`, y el `lastError` trae el diagnóstico entero:
`dial tcp …:8081: connect: connection refused` sobre
`http://host.docker.internal:8081/actuator/prometheus` —la IP concreta es la del gateway de Docker
y cambia entre Desktop y Engine, lo demás es literal—. La corrección va en el perfil `local`, con
`management.server.address: 0.0.0.0`, y **no** en el bloque común, para que el `prod` simulado de
`L09` conserve el loopback. Después hay que dar al menos un `scrape_interval` completo antes de
volver a preguntar: consultar a los cinco segundos es cómo se consigue un "no funciona" que sí
funcionaba.

**🔬 El detalle.** Con este mismo montaje hay una segunda causa que produce un target caído con el
endpoint sano, y se distingue por el error: si `lastError` menciona un `404`, lo que falta es
`metrics_path: /actuator/prometheus` en el `scrape_config`, porque el default de Prometheus es
`/metrics`. La distinción que ahorra la mitad del tiempo es **`connection refused` frente a
`context deadline exceeded`**: el primero es "alguien contestó que ahí no escucha nadie" —binding,
puerto o firewall—; el segundo es "no contestó nadie" —red, DNS o un proceso demasiado lento—. Y
conviene decir en voz alta que en un despliegue real este problema no existe: allí el scrape vive
dentro de la red del pod y alcanza el loopback sin salir a ninguna parte; lo que aquí fuerza el
`0.0.0.0` es la frontera artificial entre tu JVM y los contenedores.

---

### L07 → 11

> Tu tasa de 5xx **bajó** mientras el proveedor está caído. Explica el mecanismo y di sobre qué
> métrica y con qué condición escribes la alerta.

**⏱️ 30 segundos.** Porque el circuito abierto **deja de llamar al proveedor** y el gateway
devuelve el fallback: las peticiones que antes acababan en 5xx ahora acaban con éxito, así que la
proporción de `outcome="SERVER_ERROR"` baja mientras el incidente sigue. La alerta no va sobre los
errores: va sobre
`resilience4j_circuitbreaker_state{name="supplier",state="open"} == 1`, con `for: 30s`.

**🗣️ 2 minutos.** Es el punto ciego que anunció `19` §9 y el motivo de que este lab termine con
una alerta y no con un panel: el tablero de errores **se ve mejor que ayer** justo cuando tu
proveedor lleva veinte minutos caído. El circuito **se alerta, no se grafica**, porque lo que
importa no es su valor instantáneo sino su **cambio de estado**, y eso es un evento, no una curva
que alguien tenga que estar mirando. El `== 1` no es cosmética: el gauge publica **una serie por
estado** —`closed`, `open`, `half_open`, `disabled`, `forced_open`— y solo la del estado actual
vale `1`; sin el `== 1` la expresión devuelve la serie de `open` valiendo `0`, que también es "algo",
y la alerta estaría disparada permanentemente.

**🔬 El detalle.** Las `annotations` son parte de la instrumentación, no decoración: la del lab
dice explícitamente *"inv-api está devolviendo fallbacks: la tasa de 5xx NO va a subir"*, que es
lo que evita que quien esté de guardia a las tres de la mañana busque el incidente donde no está.
Una anotación que repite el nombre de la alerta no sirve para nada. Y la otra mitad, que casi
nadie prueba: **la alerta tiene que apagarse sola**. En cuanto el circuito vuelve a `CLOSED` la
expresión deja de devolver la serie y la alerta se resuelve sin `for` de vuelta y sin que nadie la
toque; una alerta que hay que cerrar a mano es una alerta mal escrita.

---

### L07 → 12

> Entre que el circuito se abre y que la alerta pasa a `firing` pasan unos cuarenta segundos.
> Desglosa de dónde sale cada tramo de esa espera.

**⏱️ 30 segundos.** Tres tramos, y ninguno es tuyo: **el scrape** (hasta 15 s, el
`scrape_interval` de la sección 7), **la evaluación de la regla** (hasta 15 s más, el
`evaluation_interval`) y **el `for: 30s`** de antirrebote. El circuito, en cambio, abre en tu
proceso **al instante**: `/actuator/circuitbreakers` ya dice `OPEN` cuando la alerta todavía está
en `pending`.

**🗣️ 2 minutos.** Esa cuenta es la que desmonta la promesa de "detección en tiempo real" sobre
métricas: entre el evento y la notificación hay dos muestreos en serie y una espera deliberada.
El orden de los estados —`inactive` → `pending` → `firing`— es lo que no cambia; los segundos
exactos sí, porque dependen de dónde caiga tu ráfaga respecto al scrape: si cayó justo antes,
puedes ver `pending` en la primera consulta. El `for` es la parte que de verdad se discute: sin él,
un circuito que abre y cierra dentro de una ventana mala te despierta por algo que ya se arregló
solo; con uno demasiado largo, te enteras tarde. Treinta segundos es corto **a propósito para que
quepa en este lab**; en producción, con un `wait-duration-in-open-state` de un minuto, `for: 2m`
es más razonable.

**🔬 El detalle.** Los dos sitios donde miras cuentan la misma historia desde lados distintos y
conviene poder nombrar la diferencia: `/actuator/circuitbreakers` es el estado **ahora**, en **un**
proceso concreto, sin memoria; `/api/v1/alerts` es el estado **sostenido**, ya agregado sobre todas
las réplicas y con historia. Esa es exactamente la frontera entre un endpoint de diagnóstico y un
sistema de monitorización. Y si quieres acortar la espera, el único tramo barato de tocar es el
`for`: bajar el `scrape_interval` a 5 s triplica almacenamiento e ingesta para ganar diez
segundos, que casi nunca cambia una decisión.

---

### L07 → 13

> ¿Qué lleva dentro la cabecera `traceparent`, quién decide si la traza se muestrea y en qué
> momento se toma esa decisión?

**⏱️ 30 segundos.** `traceparent: 00-<traceId>-<spanId>-01` — **versión** (`00`), los **32 hex
del `traceId`**, los **16 hex del `spanId` que la emitió** y el **flag de muestreo** (`01`
muestreada, `00` no). Decide **la raíz**: el primer servicio que ve una petición **sin**
`traceparent`, según `management.tracing.sampling.probability`. Y lo decide **en ese momento**,
al abrir la traza; después la decisión solo viaja.

**🗣️ 2 minutos.** Que la decisión se tome una vez y viaje en el flag es lo que hace que una traza
tenga sentido: o se muestrea la petición **entera**, o ninguna parte de ella. Si cada servicio
tirara su propio dado, tendrías trazas con agujeros y ningún árbol completo. Si la petición ya
llega con `traceparent`, tu servicio **hereda** el `traceId` y el flag y se cuelga como hijo; no
vuelve a sortear nada. El valor por defecto de la probabilidad es `0.1` —una de cada diez— y hay
una razón de costo detrás: cada traza exportada son bytes de red y de almacenamiento **por span**,
y mil peticiones por segundo generan varios miles de spans por segundo. El lab lo sube a `1.0`
declarando que es **solo para el lab**, porque con doce `curl` a mano hay que ver los doce.

**🔬 El detalle.** El formato es el de W3C Trace Context, que es la propagación por defecto de
Micrometer Tracing; B3, el de Zipkin, se elige con `management.tracing.propagation.type`. Y hay un
detalle de lectura que confunde a todo el mundo la primera vez: **el `spanId` de la cabecera
saliente no es el de la línea de log del controller**, y eso es correcto — la llamada saliente abre
su propio span, hijo del anterior. `traceId` compartido y `spanId` distintos es precisamente la
forma de un árbol de spans. La cabecera solo sale, además, si el cliente se construyó desde el
`RestClient.Builder` inyectado: un `RestClient.create()` suelto no lleva el interceptor de
observación y la traza aparece **cortada en tu borde**.

---

### L07 → 14

> `L06` propagaba el `requestId` y hoy hay además un `traceId`. Di qué aporta cada uno, cuál se
> propaga entre servicios y por qué copiar el MDC no basta cuando el hilo nuevo abre un span.

**⏱️ 30 segundos.** El `requestId` es **tuyo y legible**: lo pone el cliente en `X-Request-Id`,
lo entiende un humano y sirve para que soporte y desarrollo hablen del mismo caso. El `traceId` es
**del sistema y opaco**: lo genera Micrometer Tracing y sirve para pegar tramos de varios
servicios. El que se propaga entre servicios es el **`traceId`**, porque viaja en `traceparent`,
una cabecera estándar que el otro extremo entiende sin acuerdo previo.

**🗣️ 2 minutos.** Copiar el MDC propaga los **textos que se imprimen**, no el **contexto de
observación** de Micrometer. Y por eso el resultado engaña: el `MdcTaskDecorator` de `L06` hace
que las tres líneas de `traza-02` salgan con el mismo `requestId` **y** con el mismo `traceId`, así
que el log se ve perfectamente correlacionado. Pero si la tarea asíncrona abre un span propio —una
llamada HTTP saliente, por ejemplo—, ese span **no es hijo** del de la petición: arranca una traza
nueva, y acabas con el log diciendo un `traceId` y el sistema de trazas diciendo otro. Log
correlacionado y traza rota a la vez es lo peor de los dos mundos, porque nadie lo sospecha. La
corrección es componer en vez de elegir:
`new CompositeTaskDecorator(List.of(new ContextPropagatingTaskDecorator(), new MdcTaskDecorator()))`,
porque un executor admite **un solo** `TaskDecorator` y poner el oficial a secas significaría
perder el tuyo — al `requestId` no lo propaga nadie más, ya que no es un contexto conocido por
Micrometer.

**🔬 El detalle.** `ContextPropagatingTaskDecorator` vive en `org.springframework.core.task.support`
desde Spring Framework 6.1 y arrastra todo lo registrado en Micrometer Context Propagation, que es
lo que `L06` te anunció y dejó pendiente. La alternativa elegante es registrar el `requestId` como
`ThreadLocalAccessor` en el `ContextRegistry` de Micrometer: entonces el decorador oficial lo
propaga solo y el tuyo desaparece — más código hoy, menos cableado mañana. El `MDC.clear()` sigue
siendo obligatorio en cualquiera de las dos variantes, porque los hilos del pool se reutilizan y
una tarea que herede el contexto de la anterior atribuye trabajo a la petición equivocada. Y en un
proyecto real la decisión limpia es quedarse con **uno**, casi siempre el `traceId`, dejando el
`X-Request-Id` como `baggage` o como un campo más del log.

---

### L07 → 15

> En un `threaddump`, ¿qué te dice un hilo en `RUNNABLE` sobre `SocketDispatcher.read0` y qué te
> dice uno en `TIMED_WAITING` dentro de tu proceso? ¿Cuál de los dos empeora si subes
> `server.tomcat.threads.max`?

**⏱️ 30 segundos.** `RUNNABLE` sobre `sun.nio.ch.SocketDispatcher.read0` significa **"estoy
esperando bytes de otro"**: la JVM lo cuenta como ejecutable porque está dentro de una syscall de
E/S, no porque esté haciendo trabajo. `TIMED_WAITING` dentro de tu proceso significa **"me estoy
esperando a mí mismo"**: un límite tuyo —semáforo, pool de conexiones, lock— con plazo. El que
empeora al subir `server.tomcat.threads.max` es **el primero**.

**🗣️ 2 minutos.** Son los dos escenarios que la serie mide por separado a propósito. El de `L05`:
doce peticiones contra el proveedor colgado, diez hilos en `RUNNABLE` sobre `read0`, diagnóstico
"falta un timeout o el otro es lento". El de hoy: el timeout ya está puesto y el sistema se satura
igual, porque el bulkhead pasó de rechazar a **encolar** (`max-wait-duration: 5s` en lugar del `0`
de `L05`). El volcado muestra dos grupos: unos pocos hilos en `RUNNABLE` sobre el socket, **nunca
más de tres** —el `max-concurrent-calls`—, y el resto en `TIMED_WAITING` dentro del semáforo,
esperando su permiso. Más hilos de Tomcat en el primer caso solo compran más conexiones
simultáneas contra algo que ya no da abasto; en el segundo no cambian nada, porque el cuello está
más adentro y los hilos nuevos se apilan en la misma cola.

**🔬 El detalle.** Dos disciplinas de lectura que valen para cualquier volcado. Una: el estado por
sí solo no basta —`RUNNABLE` no distingue "quemando CPU" de "bloqueado en E/S"—, así que se mira el
**frame superior**, y para saber quién es tu código se recorre `.stackTrace[]` filtrando por
`com.invlab` en vez de filtrar por estado: la diferencia entre saber que hay diez hilos parados y
saber que los diez pasaron por `SupplierGateway.quote`. Dos: **un volcado no prueba nada**; se
toman dos o tres separados por unos segundos, y si los mismos hilos siguen en el mismo frame hay
bloqueo, y si cambian hay lentitud. Los conteos se leen como proporciones, porque dependen del
milisegundo del volcado. Y el par de números que hay que recordar de esta sección es
`tomcat.threads.busy` en `10.0` con `/actuator/health` en `200`: lleno no es roto.

---

## Lab L08 — Security y Batch

### L08 → 1

> Una petición sin token y otra con un token válido pero sin la authority acaban las dos en una
> `AccessDeniedException` dentro del mismo filtro. ¿Quién decide que una salga `401` y la otra
> `403`, y con qué criterio exacto?

**⏱️ 30 segundos.** Lo decide el **`ExceptionTranslationFilter`**, y el criterio no mira la
excepción a solas: manda al `AuthenticationEntryPoint` —401— cuando **la excepción es una
`AuthenticationException` o el usuario no estaba autenticado**, y al `AccessDeniedHandler` —403—
solo cuando ya había identidad. En pseudocódigo: `!authenticated || ex instanceof
AuthenticationException` → entry point; si no, handler.

**🗣️ 2 minutos.** Por eso la misma `AccessDeniedException` sale con dos códigos distintos. Sin
token, el `BearerTokenAuthenticationFilter` no encontró nada que autenticar, el
`AuthorizationFilter` denegó, y como no hay `Authentication` real el traductor concluye que tiene
sentido **pedir credenciales**: 401 con `WWW-Authenticate: Bearer`. Con el token del analista y la
regla `hasRole("ANALYST")`, hay un `JwtAuthenticationToken` autenticado, así que pedir credenciales
no arreglaría nada y el 403 se queda 403. La tabla de
[`20` §9](20-spring-security-el-mecanismo.md#9--401-frente-a-403-quién-los-escribe) resume la
consecuencia operativa: un 401 se reintenta con credencial, un 403 no se reintenta —falta un
permiso—.

**🔬 El detalle.** Tres precisiones que se cobran en entrevista. Una: el 401 del lab llega con
`InsufficientAuthenticationException: Full authentication is required to access this resource`, que
es la subclase que el propio traductor fabrica y **significa "no traías credencial", nunca "tu
credencial es mala"**. Dos: la cabecera `WWW-Authenticate` la escribe el
`BearerTokenAuthenticationEntryPoint`, escueta cuando falta el token y con `error`,
`error_description` y `error_uri` cuando el token es inválido — por eso el entry point propio del
lab **delega** en él en vez de sustituirlo. Tres: no todo 403 pasa por aquí con el mismo camino; la
`AuthorizationDeniedException` de method security —subclase de `AccessDeniedException` desde
Security 6.3— se lanza **dentro** del `DispatcherServlet`, sube por la pila y acaba en el mismo
handler si ningún `@ExceptionHandler` la reclama antes.

---

### L08 → 2

> Tu `@RestControllerAdvice` devuelve `ProblemDetail` para todo y los `401` de `/api/**` llegan con
> el cuerpo vacío. Explica por qué y nombra los dos beans que lo arreglan.

**⏱️ 30 segundos.** Porque el rechazo ocurre **en la cadena de filtros**, antes de que el
`DispatcherServlet` intervenga: no hay controller, no hay `HandlerExceptionResolver` y tu
`@RestControllerAdvice` no llega a existir en ese camino. Los dos beans que lo arreglan son un
**`AuthenticationEntryPoint`** y un **`AccessDeniedHandler`** propios, registrados en la cadena con
`.exceptionHandling(ex -> ex.authenticationEntryPoint(...).accessDeniedHandler(...))`.

**🗣️ 2 minutos.** Es la asimetría de
[`10` §4](10-diseno-de-api-validacion-errores-e-hipermedia.md#4--manejo-centralizado-y-lo-que-se-le-escapa)
vista desde el otro lado: el manejo centralizado cubre lo que pasa **dentro** del despacho, y
Security rechaza **fuera**. En el lab son `LoggingAuthenticationEntryPoint` y
`LoggingAccessDeniedHandler`, y dentro de ellos el `ProblemDetail` se escribe **a mano** sobre el
`HttpServletResponse` —con `application/problem+json`— precisamente porque ahí no hay ningún
`HttpMessageConverter` al que devolverle un objeto. El valor real no es el cuerpo, es el log: cada
rechazo deja una línea `WARN` con el `requestId`, el método y la URI, y en el 403 además el
principal y sus authorities.

**🔬 El detalle.** Cuatro decisiones del lab que conviene poder justificar. El entry point delega en
`BearerTokenAuthenticationEntryPoint` para no pisar la cabecera `WWW-Authenticate`, que es lo que
permite al cliente distinguir "falta token" de "token caducado" y decidir si refresca. En el log
**nunca entra el token**, solo el principal y la lista de authorities: un access token en un fichero
de log es una credencial en un fichero de log aunque caduque en quince minutos. Los dos se
instancian con `new` y no como beans, porque solo los usa esa cadena. Y cuidado con creer que el
problema queda cerrado: la cadena de Actuator de la sección 8 **no** los declara, así que el 401 y
el 403 del 8081 siguen saliendo mudos y con el cuerpo vacío.

---

### L08 → 3

> El log dice `authorities=[SCOPE_openid, SCOPE_inventory.read, ROLE_OFFLINE_ACCESS]` y la regla
> pide `hasRole("ANALYST")`. Escribe en una línea qué falta y en qué fichero.

**⏱️ 30 segundos.** Falta **asignarle el rol de realm `analyst` a ese usuario**, y eso se arregla en
`keycloak/inv-realm.json`, en el `realmRoles` de su entrada — no en el código.

**🗣️ 2 minutos.** El discriminante está a la vista y es la razón de escribir las authorities en el
log: **hay un `ROLE_` en la lista, y en mayúsculas**. `ROLE_OFFLINE_ACCESS` solo puede existir si
alguien leyó `realm_access.roles` y le aplicó **las dos transformaciones** que exige `hasRole`: el
prefijo `ROLE_` y el paso a mayúsculas, porque Keycloak emite `offline_access` en minúscula y
`SimpleGrantedAuthority` compara cadenas exactas. Es decir, el `JwtAuthenticationConverter` de la
sección 5 está registrado y funcionando: si faltara cualquiera de las dos, el 403 sería idéntico. Lo que trae ese usuario son los roles que Keycloak reparte
a todo el mundo —`offline_access`, `uma_authorization`, `default-roles-inv`— y ninguno de negocio:
es exactamente el perfil de `guest@invlab.example`, que en el realm del lab tiene `"realmRoles": []`
a propósito para poder fabricar un 403 de verdad. El orden de diagnóstico es el de la sección 4:
qué authorities llegaron, qué pedía la regla, y arreglar **el lado que estaba mal** — que aquí es la
identidad, no la regla.

**🔬 El detalle.** Conviene tener enfrente el caso vecino, porque el síntoma se parece y el fichero
es otro. Si en la lista **no hubiera ni un solo `ROLE_`** —solo `SCOPE_*`, como en la medición de la
sección 4— el rol estaría en el token y nadie lo habría sacado de `realm_access`: eso es el
converter ausente o fuera del escaneo de componentes, y se arregla en `JwtConverterConfig.java`. Y
hay una tercera variante que no cambia nada en el log y sí en el resultado: el literal tiene que
coincidir **carácter a carácter** con lo que compara la regla. `hasRole("ANALYST")` exige
`ROLE_ANALYST`, así que un converter que emita `ROLE_analyst` produce un 403 idéntico al de no tener
el rol; de ahí el `toUpperCase(Locale.ROOT)` de
[`21` §7](21-identidad-federada-oauth2-oidc-y-jwt.md#7--de-claims-a-authorities-el-converter-que-casi-todos-terminan-escribiendo)
—con locale explícito, porque el turco convierte la `i` en `ı`— o, como alternativa, escribir la
regla tal y como llega el token. Lo que no vale es mezclar los dos estilos.

---

### L08 → 4

> ¿Por qué `spring.security.oauth2.resourceserver.jwt.authorities-claim-name` **no** resuelve el
> mapeo de los roles de Keycloak, y qué sí lo resuelve?

**⏱️ 30 segundos.** Porque esa propiedad solo cambia **qué claim de primer nivel** se lee, y no sabe
bajar un nivel: los roles de Keycloak llegan **anidados** en `realm_access: { "roles": [...] }`.
Apuntarla a `realm_access` entrega un `Map`, no una lista de strings, y el resultado es ninguna
authority o una sola con el `toString()` del mapa dentro. Lo que sí lo resuelve es un bean
`JwtAuthenticationConverter` con un `setJwtGrantedAuthoritiesConverter` propio.

**🗣️ 2 minutos.** El default —`JwtGrantedAuthoritiesConverter`— hace una sola cosa: lee `scope` o
`scp`, lo parte por espacios y prefija con `SCOPE_`. Con un IdP de scopes planos alcanza; con la
estructura de Keycloak no hay propiedad que llegue. El converter del lab entra a
`jwt.getClaimAsMap("realm_access")`, comprueba con `instanceof Collection<?> roles` y añade
`ROLE_ + rol` **sumando** a lo que ya devolvió el converter de scopes. Declararlo como `@Bean` es
todo el cableado: la autoconfiguración lo recoge y se lo pasa al `JwtAuthenticationProvider`, sin
tocar la cadena. Y corre en el hilo del request, dentro del `BearerTokenAuthenticationFilter`, una
vez por petición y después de verificar la firma: no hay proxy de por medio.

**🔬 El detalle.** Tres trampas alrededor. La primera es `new ArrayList<>(scopes.convert(jwt))`: si
devuelves solo los roles **pierdes todos los `SCOPE_`** y las reglas escritas contra ellos empiezan
a dar 403 sin que nada apunte a este fichero. La segunda es la alternativa que parece más barata
—añadir en Keycloak un protocol mapper que aplane los roles a un claim de primer nivel—: es
legítima, y ata tu servicio a cómo esté configurado el realm de cada entorno, así que lo que falla
en preproducción no falla en desarrollo; mapear en el resource server se sostiene porque el código
viaja con el servicio. La tercera es el pattern match frente al cast ciego: si el realm cambia la
forma del claim, un cast revienta con `ClassCastException` **en cada petición** y tumba el servicio,
mientras que el pattern match degrada a "sin roles", que es un 403 rastreable con la línea de log de
la sección 4.

---

### L08 → 5

> Activaste `jwt.audiences=inv-api` y **todos** los tokens pasaron a dar `401`. ¿Qué falta, y en
> cuál de los dos lados —Keycloak o `inv-api`— se arregla?

**⏱️ 30 segundos.** Falta el **`oidc-audience-mapper`** en el cliente que pide los tokens, y se
arregla **en Keycloak**: por defecto el realm emite tokens cuyo `aud` es `account`, no tu servicio.
El mapper añade `inv-api` al `aud` del access token, y en el lab vive en `keycloak/inv-realm.json`,
dentro de los `protocolMappers` de `inv-cli`.

**🗣️ 2 minutos.** El 401 es **perfectamente legítimo**: la validación de audiencia es el quinto paso
de [`21` §4](21-identidad-federada-oauth2-oidc-y-jwt.md#4--qué-valida-un-resource-server-y-en-qué-orden)
y es el único que **no viene por defecto**; en cuanto lo activas con
`spring.security.oauth2.resourceserver.jwt.audiences`, un token sin tu identificador en el claim se
rechaza como `invalid_token`. La comprobación es de treinta segundos y no requiere tocar código:
`decode "$ANALYST" 2 | jq -r '.aud | join(",")'` tiene que incluir `inv-api`. En el lab el `aud`
sale `["inv-api", "account"]`, y la propiedad de Boot exige que tu valor **esté entre** los del
claim, no que sea el único. Quitar la propiedad también "arregla" el 401 y es la decisión
equivocada: sin `aud`, un token que el mismo Keycloak emitió para otro servicio del realm entra en
`inv-api` con la firma perfecta.

**🔬 El detalle.** El mapper se configura con `access.token.claim: true` e `id.token.claim: false`
por una razón que conviene saber decir: el `id_token` es el documento dirigido **al client** y no se
manda a un resource server, así que meterle audiencias ajenas solo añade confusión. Y `inv-api`
existe en el realm como cliente `bearerOnly` —sin secreto ni redirect URI— precisamente para que el
mapper pueda nombrarlo. Si algún día el IdP no te deja tocar el `aud`, la salida por el lado de
`inv-api` es un `JwtClaimValidator<List<String>>(AUD, ...)` propio compuesto con el validador por
defecto; es más código y la misma semántica.

---

### L08 → 6

> `/api/reports/valuations` devuelve `200` a un usuario al que `/api/items/{sku}/valuation` le
> devuelve `403`, y las dos rutas llaman al mismo método anotado. ¿Qué pasó, y por qué no aparece
> ninguna excepción en el log?

**⏱️ 30 segundos.** **Self-invocation.** El controller del informe llama a un método del servicio
que, dentro, invoca `this::valuation` — sobre el objeto real, no sobre el proxy. El interceptor de
`@PreAuthorize` vive en el proxy, así que **la comprobación no se ejecutó nunca**. No hay excepción
en el log porque no hubo denegación: hubo ausencia de verificación, y la ausencia no deja rastro.

**🗣️ 2 minutos.** Es el proxy de [`05`](05-proxies-y-aop.md) por cuarta vez en el curso, y esta vez
lo que se pierde es lo caro. La ruta directa entra por la regla de URL y por el interceptor del
método, y el usuario sin permiso se lleva su `403`. La ruta del informe tiene la regla de URL más
floja posible —`authenticated()`, porque "el permiso fino ya lo pone el método"— y el fan-out
interno se salta el proxy: el endpoint responde `200` **con los datos dentro**. Ningún test lo nota,
ningún código de estado lo insinúa, ningún log lo menciona. La corrección es la de siempre: **el
fan-out sale del bean** —un `ValuationReportService` que recibe inyectado el
`InventoryValuationService` y llama `valuations::valuation` sobre la referencia, que sí es el
proxy—; tras el cambio, el informe devuelve `403` al invitado y `200` al analista.

**🔬 El detalle.** Hay un segundo efecto que se descubre en la misma pantalla: por idéntica razón,
el `@Cacheable` tampoco se aplicó en esa ruta, así que el informe consultó la base una vez por SKU y
el contador de `L06` lo demuestra. Dos falsos arreglos que hay que saber descartar en voz alta:
poner `@PreAuthorize` también en el método que hace el fan-out **tapa este caso y deja vivo el
siguiente** —basta con que alguien añada un tercer método que llame a `valuation(...)` desde
dentro—, e inyectarse a sí mismo con `@Lazy` funciona pero esconde el truco en el constructor.
Cuando partir la clase es viable, se parte. Y compárese con las otras tres apariciones del mismo
mecanismo: en `L04` se perdía un rollback, en `L06` una entrada de caché y un hilo, aquí se pierde
una comprobación de seguridad — mismo bug, coste creciente.

---

### L08 → 7

> Un método `@Async` falla con `AuthenticationCredentialsNotFoundException` y otro, en el mismo
> pool, con `AccessDeniedException`. ¿Qué distingue los dos casos y qué te dice cada uno sobre
> dónde está el problema?

**⏱️ 30 segundos.** La primera dice que **no llegó ningún contexto**: el interceptor no tenía a
quién evaluar, así que el problema es **la propagación al saltar de hilo**. La segunda dice que el
contexto **sí llegó, con menos authorities de las que hacía falta**: ahí el salto funciona y el
problema es el **mapeo de claims** o el permiso del usuario.

**🗣️ 2 minutos.** Son el mismo bug con dos caras y se distinguen sin depurar. En el lab, con el pool
sin decorar, la línea que escribes tú dice `recalentando ABC-000123 con authentication=null` en el
hilo `inv-task-1`, y acto seguido aparece
`AuthenticationCredentialsNotFoundException: An Authentication object was not found in the
SecurityContext`. Esa excepción **desciende de `AuthenticationException`**, no de
`AccessDeniedException`, que es la pista de taxonomía: el interceptor de method security ni siquiera
llegó a decidir. La otra cara es la que describe
[`20` §6](20-spring-security-el-mecanismo.md#6--securitycontextholder-un-threadlocal-y-sus-dos-fugas)
—*una `AccessDeniedException` dentro de un método asíncrono con el mismo usuario que sí tenía el
rol*— y ahí lo que se investiga es el converter, no el executor.

**🔬 El detalle.** Dos matices que hacen el diagnóstico más rápido. El primero:
`SecurityContextHolder.getContext()` **nunca devuelve `null`**: con el `ThreadLocal` vacío entrega
un `SecurityContext` nuevo cuyo `getAuthentication()` sí es `null`, así que el síntoma jamás es un
`NullPointerException` en esa línea y la guarda va sobre `auth`. Y el fallo puede ser
**intermitente**, que es lo que lo vuelve caro: si el `@Cacheable` sirve el valor desde caché, la
llamada no llega al interceptor de seguridad y no pasa nada — por eso el lab hace `FLUSHALL` antes
de medir. Sumado a que `warmUp` devuelve `void`, la excepción se la come el
`SimpleAsyncUncaughtExceptionHandler`, el `POST` responde `200`, el cliente queda contento y la
caché sin recalentar. Si en vez de un recalentamiento eso fuera un apunte contable, el `void`
sería el bug antes que la seguridad.

---

### L08 → 8

> El `MdcTaskDecorator` propagó el `requestId` al hilo del pool y aun así el `SecurityContext` no
> llegó. Explica por qué copiar el MDC no bastaba y qué decora `DelegatingSecurityContextAsyncTaskExecutor`.

**⏱️ 30 segundos.** Porque son **dos `ThreadLocal` distintos**: el MDC de SLF4J y el
`SecurityContextHolder` no se conocen. **Copiar el MDC propaga los textos que se imprimen, no los
contextos.** `DelegatingSecurityContextAsyncTaskExecutor` decora **el executor por fuera**: copia el
`SecurityContext` en el hilo que **envía** la tarea y lo instala en el hilo que la **ejecuta**,
limpiándolo después.

**🗣️ 2 minutos.** La evidencia del lab es una sola línea y no admite interpretación:
`INFO [async-01] --- [inv-task-1] ... recalentando ABC-000123 con authentication=null`. El
`requestId` **sí** viajó —ahí está `[async-01]` en un hilo `inv-task-`— y la identidad no. Son tres
contextos distintos con tres mecanismos de propagación distintos: el MDC con tu decorador, el de
observación con `ContextPropagatingTaskDecorator` (`L07` §10) y el de seguridad con este envoltorio.
Tras poner el decorador, la misma línea dice `authentication=analyst@invlab.example` y aparece una
tercera línea en el mismo hilo `inv-task-` confirmando que la valoración se calculó con su
`@PreAuthorize` evaluado y aprobado; el criterio de terminado de la sección es que
`grep -c AuthenticationCredentialsNotFoundException app.log` devuelva `0`.

**🔬 El detalle.** Va por fuera y no como un tercer `TaskDecorator` por una razón mecánica: un
executor admite **un solo** `TaskDecorator`, y ese hueco ya lo ocupa el `CompositeTaskDecorator` de
`L07`. Se podría meter un decorador de seguridad dentro del composite; usar el de Spring Security es
preferible porque **limpia el contexto en un `finally`** y contempla el caso del contexto vacío, que
son las dos cosas que se olvidan al escribirlo a mano. El orden tampoco es arbitrario: al estar más
afuera, instala la identidad **antes** de que corran los otros dos decoradores, así que una
observación que consultara el usuario lo encontraría puesto. Y propagar **copia**, no comparte, lo
cual importa aquí más que en ningún sitio: el `FilterChainProxy` limpia el `SecurityContextHolder`
del hilo de Tomcat en un `finally` en cuanto la respuesta sale, así que compartir la referencia
dejaría a la tarea sin identidad justo al responder. `MODE_INHERITABLETHREADLOCAL` no es la salida:
hereda a hilos **hijos**, y los de un pool no son hijos de nadie.

---

### L08 → 9

> ¿Por qué `EndpointRequest.toAnyEndpoint()` y no un `requestMatchers("/actuator/**")`? Da la razón
> técnica, no la estética.

**⏱️ 30 segundos.** Porque `EndpointRequest` **resuelve las rutas reales en tiempo de ejecución**,
preguntándole a Actuator: respeta `management.endpoints.web.base-path`, respeta el puerto separado
del 8081 y sigue siendo correcto el día que alguien mueva el base path. Un matcher literal se queda
obsoleto **en silencio**, que es la peor forma de quedarse obsoleto en seguridad.

**🗣️ 2 minutos.** Y hay una segunda razón técnica, no cosmética: `EndpointRequest` permite excluir
**por tipo** —`.excluding(HealthEndpoint.class, PrometheusScrapeEndpoint.class)`—, que es una
referencia que el compilador comprueba y que no se rompe si la ruta de ese endpoint cambia. Con una
cadena literal, la exclusión sería otra cadena literal más que mantener. El fallo que evita es
concreto: si el base path deja de ser `/actuator`, tu `requestMatchers("/actuator/**")` no matchea
nada, la cadena no reclama esas URLs y **una petición que no matchea ninguna cadena pasa sin filtros
de seguridad** — exactamente el `actuator/env -> 200` que el lab arrastra desde la sección 3.

**🔬 El detalle.** Dos cosas que van pegadas a esta decisión. El `@Order(0)` de la cadena de Actuator
frente al `@Order(1)` de la de `/api/**`: `FilterChainProxy` elige **la primera cadena que matchea**
y no evalúa las demás, así que el orden explícito es lo que evita que un cambio futuro deje una de
las dos muerta aunque hoy no se solapen. Y que esta cadena declare su **propia** autenticación
—`oauth2ResourceServer` otra vez— porque nada se hereda entre cadenas: que `/api/**` use JWT no se
lo regala a Actuator. El lab elige JWT en vez del `httpBasic` que propone
[`20` §10](20-spring-security-el-mecanismo.md#10--asegurar-actuator-sin-escribir-rutas-a-mano)
porque no hay ningún `UserDetailsService` en el proyecto y no vale la pena inventar un almacén de
usuarios para tres endpoints.

---

### L08 → 10

> Cerraste Actuator con una cadena propia y el tablero de Grafana se quedó vacío. ¿Qué endpoint lo
> causó, qué métrica te lo dice en un comando, y cuáles son las tres salidas posibles?

**⏱️ 30 segundos.** Lo causó **`PrometheusScrapeEndpoint`**: el scraper raspa cada quince segundos y
no tiene forma de conseguir un token, así que el target se cae. La métrica es
**`up{job="inv-api"}`**, y el comando es el de `L07`:
`curl -s 'localhost:9090/api/v1/query?query=up{job="inv-api"}' | jq -r '.data.result[0].value[1]'`.
`1` es que sigue raspando, `0` es que no.

**🗣️ 2 minutos.** Las tres salidas son: **darle al scraper un client de `client_credentials`** para
que presente su propio token; **poner un Basic propio** solo para ese endpoint; o **dejar el
endpoint accesible únicamente desde la red de observabilidad**. La tercera es la que usa casi todo
el mundo, y en esta máquina ya está puesta: el `management.server.address: 127.0.0.1` de `L07` liga
el conector al loopback. Por eso el lab excluye `PrometheusScrapeEndpoint` de la cadena y **dice por
qué**, en vez de romper el lab anterior sin explicación. `HealthEndpoint` se excluye por el mismo
tipo de razón —lo sondea un orquestador que tampoco tiene token—, y ahí el `200` de
`/actuator/health` y el `1` de `up` son la comprobación de que las dos exclusiones funcionan.

**🔬 El detalle.** El valor de esta pregunta no es la lista, es el reflejo: `up` te dice en un
comando lo que un tablero vacío tarda media hora en insinuar, y es la primera consulta ante
cualquier panel en blanco. Sobre `health`, lo correcto en producción no es excluir el endpoint
entero sino **solo los grupos de probes** —`/actuator/health/liveness` y
`/actuator/health/readiness`—, porque con `show-details` distinto de `never` el `health` detallado
publica el estado de tus dependencias a quien pregunte; en el lab el `show-details: always` viene de
`L01` y se queda por comodidad, sabiendo que es una decisión de laboratorio.

---

### L08 → 11

> "Si el job falla, se vuelve a correr desde el principio": corrige la afirmación con precisión y
> di qué fila de qué tabla contiene la respuesta a "¿por dónde iba?".

**⏱️ 30 segundos.** La versión precisa: **relanzar la misma `JobInstance` —mismo job y mismos
parámetros identificadores— cuya última ejecución falló *es* reanudar**. Spring Batch crea un
`JobExecution` nuevo sobre esa instancia, salta los steps que quedaron en `COMPLETED` y le pasa al
step caído el `ExecutionContext` que guardó. La respuesta a "¿por dónde iba?" está en la columna
`short_context` de **`BATCH_STEP_EXECUTION_CONTEXT`**, en la clave `movementReader.read.count`.

**🗣️ 2 minutos.** No hay ningún comando de reanudación, y ese es el punto: es **exactamente el mismo
comando** de la corrida que falló. En el lab, la fila dice `{"movementReader.read.count": 30000,
...}` y esa clave lleva el nombre que le pusiste al reader con `.name("movementReader")`; la
ejecución nueva se salta esas treinta mil líneas. Lo que sí vuelve a correr desde el principio es el
caso contrario, y es una decisión, no un accidente: si añades un `run.id` con la hora, cada intento
es una `JobInstance` nueva y **nunca se reanuda nada**.

**🔬 El detalle.** La condición que casi nadie menciona en una entrevista es que **el reanudado lo
hace el reader, no el framework solo**: solo se reanuda uno que implemente `ItemStream` y guarde su
posición en el `ExecutionContext` al abrirse y cerrarse. El `FlatFileItemReader` lo hace; un
`ItemReader` propio escrito como un iterador vuelve a empezar y duplica. Y **sin `.name(...)` esa
clave no existiría**, así que no habría reanudación posible — se ve en una fila de una tabla, no en
un párrafo de la reference. Dos ajustes que van con esto: `allowStartIfComplete(true)` fuerza a
repetir un step que quedó `COMPLETED` —lo quieres en validación o limpieza previa, nunca en el step
que mueve dinero— y `startLimit(n)` limita cuántas veces puede arrancar un step en la instancia.

---

### L08 → 12

> Tu step falló procesando el ítem 30 001 con chunks de 500. Di cuántas filas quedaron escritas,
> cuánto vale `read_count`, cuánto `rollback_count`, y por qué esos tres números tienen que ser
> coherentes entre sí.

**⏱️ 30 segundos.** **30 000 filas escritas**, **`read_count = 30000`** y **`rollback_count = 1`**
(con `write_count = 30000` y `commit_count = 60`). Son coherentes porque los tres cuentan lo mismo:
**sesenta chunks confirmados de quinientos ítems cada uno**. El chunk 61 —el que empieza justo en el
ítem 30 001— se revirtió entero, y con él se fueron sus escrituras **y sus contadores**.

**🗣️ 2 minutos.** El recorrido es este. El reader llegó a leer hasta el ítem 30 500, el processor
lanzó `IllegalArgumentException` en el primero del chunk y, sin `faultTolerant()`, eso mata el step.
La transacción de ese chunk hace rollback completa: por eso `write_count` es 30 000 y no 30 500, y
por eso `read_count` dice 30 000 aunque el fichero se hubiera leído más allá — **los contadores del
`StepExecution` viven en la misma transacción que los datos y retroceden con ellos**. Y
`rollback_count = 1`, no 61: los sesenta chunks anteriores estaban confirmados en transacciones
propias. La invariante que hay que saber decir es esa: **el `JobRepository` nunca dice haber leído
algo que no quedó escrito**, así que el `SELECT count(*)` sobre la tabla de destino y el
`read_count` tienen que coincidir; cuando no coinciden es cuando toca sospechar del writer.

**🔬 El detalle.** Los números salen redondos porque el lab lo preparó: con chunks de 500, el ítem
30 001 es **el primero del chunk 61 de 120**, de modo que el último commit limpio cae exactamente en
30 000. Muévelo al ítem 30 250 y tendrías los mismos `rollback_count = 1` y `write_count = 30000`,
porque el chunk se revierte entero se rompa donde se rompa: esa es la definición operativa del
tamaño de chunk como **cuánto trabajo estás dispuesto a repetir**. Nota además que `filter_count` es
cero en esta corrida —ningún ítem se descartó devolviendo `null`—, que es lo que permite leer
`read_count == write_count` sin matices; en cuanto los dos se separen, la pregunta es cuál de los
tres motivos fue: filtrado, descartado o perdido. Y compárese con la corrida limpia de diez mil
ítems, donde `commit_count = 21` y no 20: los veinte chunks completos más el commit de cierre cuando
el reader devuelve `null`.

---

### L08 → 13

> Reanudaste el job y `read_count` de la ejecución nueva vale 30 000, no 60 000. ¿Qué significa ese
> número y qué línea de la configuración del reader es la que hace posible el reanudado?

**⏱️ 30 segundos.** Significa que **los contadores de un `StepExecution` son de ese intento y nunca
acumulados**: el step no releyó el fichero desde el principio, recuperó
`movementReader.read.count = 30000` del `ExecutionContext` al abrir el reader y se saltó esas
treinta mil líneas. Sumando los dos intentos salen los sesenta mil. La línea que lo hace posible es
**`.name("movementReader")`** en el `FlatFileItemReaderBuilder`.

**🗣️ 2 minutos.** El `.name(...)` no es cosmético: es la **clave** con la que el reader guarda y
recupera su posición en el `ExecutionContext` del step, y es la que aparece en `short_context`. Sin
nombre, un reader con estado no se reanuda. La foto completa de la segunda ejecución encaja con ese
30 000: `status = COMPLETED`, `write_count = 30000`, `commit_count = 61` —los sesenta chunks
restantes más el cierre—, `rollback_count = 0`, y la tabla de destino con **exactamente 60 000
filas** para `business_date = 2026-09-18`. Y la evidencia central: `batch_job_instance` **no** ganó
ninguna fila. Dos `JobExecution` colgando de la misma `JobInstance` es un reintento de la misma
corrida lógica, no dos corridas.

**🔬 El detalle.** Que no hubiera duplicados en el chunk 61 —que se reprocesó entero, sus quinientos
ítems releídos y reescritos— no lo salvó el `ON CONFLICT`: lo salvó que el rollback del primer
intento se había llevado también sus escrituras. El `ON CONFLICT` no llegó a hacer nada aquí, y aun
así tiene que estar, por lo que dice
[`22` §6](22-spring-batch.md#6--restart-qué-se-reanuda-y-qué-tiene-que-cumplir-tu-reader):
**reanudable no es idempotente**. Y el otro requisito del reanudado, el que se paga en el modelo de
datos, es la **clave natural**: `UNIQUE (business_date, sku, source_line)`, donde `source_line`
viaja dentro del propio fichero porque sin ella dos movimientos idénticos del mismo SKU en el
mismo día serían indistinguibles.

---

### L08 → 14

> El job terminó bien y alguien lo relanza con los mismos parámetros. ¿Qué excepción recibe, y en
> qué se convertiría ese rechazo si el equipo añadiera un parámetro `run.id` con la hora?

**⏱️ 30 segundos.** Recibe **`JobInstanceAlreadyCompleteException`** y el proceso muere con código
distinto de cero sin escribir una sola fila. Con un `run.id` con la hora, ese rechazo **desaparece y
se convierte en una corrida entera desde la línea 1**: cada intento sería una `JobInstance` nueva,
se reinsertarían las sesenta mil filas y lo único que te salvaría de duplicarlas sería el
`ON CONFLICT`.

**🗣️ 2 minutos.** El rechazo **es la funcionalidad, no un bug**: sale de la ecuación de identidad
`JobInstance = Job + JobParameters identificadores`, y es lo que convierte "correr el job dos veces
por error" en un error de arranque en lugar de un doble cargo. En el lab, la tercera corrida con
`business.date=2026-09-18` falla y el `count(*)` sigue diciendo 60 000. Cambiar la fecha sí crea
otra instancia y el job corre entero, que es lo correcto: otra fecha contable es otro trabajo. El
`run.id` es el antipatrón clásico de
[`22` §5](22-spring-batch.md#5--jobparameters-por-qué-no-puedes-relanzar-lo-mismo-dos-veces) —"para
poder relanzar siempre"—: funciona, y destruye la identidad, así que **nunca se reanuda nada** y los
duplicados quedan de tu cuenta.

**🔬 El detalle.** La excepción hermana es la que de verdad duele a las tres de la mañana: si el
proceso hubiera muerto de un `kill -9` en vez de fallar limpiamente, nadie habría podido escribir
el `FAILED` y la fila de `batch_job_execution` se quedaría en `STARTED` para siempre; el relanzado
daría entonces **`JobExecutionAlreadyRunningException`**, y la salida no es un comando de Spring
sino una decisión de operación —comprobar que el proceso está muerto de verdad y marcar la
ejecución como abandonada—. Y un matiz de los parámetros que se olvida al reintentar: los **no
identificadores** —la ruta del fichero, un flag de verbosidad, con la sintaxis
`nombre=valor,tipo,false`— participan en la ejecución pero no en la identidad, y **no se copian**
de la ejecución anterior, así que hay que volver a pasarlos todos.

---

### L08 → 15

> Tu writer inserta con `ON CONFLICT DO NOTHING` y el chunk que falló hizo rollback limpio, así
> que no había nada que duplicar. Nombra entonces los casos en los que esa cláusula sí te salva.

**⏱️ 30 segundos.** Te salva siempre que **tus datos y los metadatos del `JobRepository` no viajen
en la misma transacción**: un writer que llama a un servicio externo, un `faultTolerant()` que
reprocesa ítem a ítem tras un fallo, o el proceso muerto a `kill -9` **entre** el commit de tu
escritura y el del `JobRepository`. Y también cuando alguien relanza creando una instancia nueva
—un `run.id`, otra corrida del mismo fichero— y el job reinserta desde la línea 1.

**🗣️ 2 minutos.** La frase que resume los cuatro casos es **reanudable no es idempotente**: Spring
Batch garantiza que no vuelve a *contar* lo ya confirmado, no que tu escritura sea segura de
repetir. La granularidad del reanudado es el **chunk**, y el chunk en vuelo **se vuelve a leer y a
escribir siempre**, así que el writer tiene que tolerar la repetición por diseño —`upsert`, clave
natural o un `INSERT` que choque contra una restricción única y sepa qué hacer—. Que en este lab no
hubiera nada que deduplicar es una propiedad del caso feliz —un writer JDBC contra el mismo
`DataSource` que el `JobRepository`, con `chunk(500, transactionManager)` abriendo una sola
transacción—, no una garantía del framework. Sin la restricción
`UNIQUE (business_date, sku, source_line)`, cada reanudación duplicaría hasta quinientas filas en
silencio.

**🔬 El detalle.** `DO NOTHING` es la variante correcta **aquí** porque la fila es un hecho contable
inmutable: si ya está, repetirla no aporta nada. Cuando lo que se escribe es un estado que cambia
—un saldo, un último valor conocido— la cláusula correcta es `DO UPDATE SET`, y elegir mal convierte
un reintento en un dato viejo que se queda. Dos condiciones que hay que revisar antes de confiar en
la cláusula: la restricción tiene que estar nombrada y ser **la clave natural de verdad** —de ahí
`source_line`, que viaja dentro del fichero—, y el mapeo se escribe con un
`itemSqlParameterSourceProvider` explícito y no con `.beanMapped()`, porque un `record` expone
`sku()` y no `getSku()`. Y una advertencia de alcance: `ON CONFLICT` protege tu tabla, no el mundo;
un writer que manda un correo o llama a un pago necesita su propia clave de idempotencia aguas
abajo.

---

## Lab L09 — Empaquetado, imagen y limpieza verificada

### L09 → 1

> ¿Qué contiene exactamente `BOOT-INF/layers.idx`, quién lo escribe y qué se rompe si alguien
> pone `<layers><enabled>false</enabled></layers>` en el `pom.xml`?

**⏱️ 30 segundos.** Un **índice**: qué entrada del jar pertenece a qué capa, escrito por el
`spring-boot-maven-plugin` en el `repackage` **por defecto** desde Boot 2.4 —no hay que activarlo,
hay que desactivarlo—. Con `<layers><enabled>false</enabled></layers>` el jar deja de tenerlo, y lo
que se rompe no es el arranque: el jar sigue ejecutándose igual. Lo que se rompe es la construcción
de la imagen por capas.

**🗣️ 2 minutos.** `layers.idx` vive en `BOOT-INF/` y es el contrato entre Boot y el caché de Docker:
`java -Djarmode=tools -jar app.jar list-layers` lo lee para imprimir los nombres, y
`extract --layers --destination extracted` lo lee para escribir un directorio por capa. Sin él, la
etapa `builder` del `Dockerfile` de la sección 3 no tiene de dónde sacar los cuatro directorios y
los cuatro `COPY --from=builder` se quedan sin origen; el buildpack de Paketo, que también lo lee
para montar las mismas cuatro capas, vuelve a tratar el artefacto como un bloque. El resultado
práctico de desactivarlo es la imagen ingenua: **una sola capa gorda que se retransmite entera cada
vez que cambias una línea**.

**🔬 El detalle.** Conviene tener claro qué no hace. `layers.idx` **no cambia el contenido del jar
ni cómo arranca**: el `MANIFEST.MF` sigue apuntando a `JarLauncher` y `java -jar` se comporta igual
con él y sin él. No te ahorra un solo byte por sí mismo —solo lo hace un `Dockerfile` que escriba
sus `COPY` en el orden que el índice declara—, y por eso una imagen con `layers.idx` dentro y un
`COPY` del fat jar entero no está estratificada en absoluto. El único motivo razonable para
apagarlo es un pipeline que no construya imágenes, y el ahorro es de kilobytes.

---

### L09 → 2

> Enumera las cuatro capas por defecto en su orden y explica por qué ese orden y no el inverso.
> ¿Qué pasa si inviertes los cuatro `COPY` del `Dockerfile`?

**⏱️ 30 segundos.** `dependencies`, `spring-boot-loader`, `snapshot-dependencies`, `application`. El
orden es **de lo que menos cambia a lo que más**, porque Docker cachea capas por prefijo: si una
capa cambia, esa y **todas las siguientes** se reconstruyen. Invertir los cuatro `COPY` construye
igual y destruye el beneficio entero: la capa volátil quedaría abajo e invalidaría las tres de
arriba en cada commit.

**🗣️ 2 minutos.** Capa por capa: `dependencies` son los jars de terceros sin `SNAPSHOT` en la
versión —Spring Boot, Hibernate, Hikari, Jackson, Lettuce, Resilience4j—, la parte grande, y cambia
cuando tocas el `pom.xml`, no cuando tocas una clase. `spring-boot-loader` son las clases del
`JarLauncher`: unos pocos KB que solo cambian al subir de versión de Boot. `snapshot-dependencies`
son las dependencias con `SNAPSHOT`, inestables por definición; en `inv-api` hoy no hay ninguna y la
capa **sale vacía**, lo que no molesta y evita reordenar el `Dockerfile` el día que aparezca una.
`application` es `BOOT-INF/classes/`: tu código y tu `application.yml`, lo que cambia en cada
commit, y por eso va la última. Con el orden correcto, un cambio de una línea reporta `CACHED` en
los tres primeros `COPY` y reconstruye solo uno.

**🔬 El detalle.** El dato que hay que mirar en el build **no es el tiempo** —depende de tu disco, de
tu CPU y de si el daemon tiene la base caliente— sino cuántos pasos llevan `CACHED` delante, y
`docker history --format '{{.Size}}\t{{.CreatedBy}}'` enseña la forma: cuatro capas propias con el
peso concentrado en la primera, frente a una sola en la versión ingenua. Y la frontera entre capas
no es una constante del framework: con un `layers.xml` declarado en el `pom.xml` puedes sacar, por
ejemplo, `com.invlab.invapi.batch` a una capa propia, y entonces el `Dockerfile` necesita su quinto
`COPY` **en la posición que corresponda a su volatilidad**, no al final por costumbre.

---

### L09 → 3

> `java -Djarmode=tools -jar app.jar` no arranca tu aplicación. ¿Quién lee esa propiedad, en qué
> momento del arranque, y por qué el mismo comando sin ella sí arranca Spring?

**⏱️ 30 segundos.** La lee el **launcher de Boot** —el `Main-Class` del manifiesto, `JarLauncher`—
**antes** de invocar tu `Start-Class`: si la propiedad de sistema `jarmode` está presente, ejecuta
el modo pedido y sale sin tocar tu aplicación. Sin ella, el mismo launcher sigue su camino normal,
instala el classloader de jars anidados y arranca `InvApiApplication`.

**🗣️ 2 minutos.** Lo desconcertante del comando es que es **el mismo jar y el mismo `java -jar`**, y
hace algo completamente distinto; la bifurcación está dentro del launcher, no en el JDK ni en
Spring. Eso encaja con lo que `01` §6 dejó dicho: `Main-Class` no es tu clase, es el `JarLauncher`,
y `Start-Class` es la tuya. Las herramientas viajan dentro de tu artefacto porque el plugin añade
`spring-boot-jarmode-tools` —el parámetro `includeTools` vale `true` por defecto—, así que si un día
el modo "no existe", alguien lo puso en `false` para ahorrar unos kilobytes. Los comandos
disponibles son `extract`, `list-layers` y `help`.

**🔬 El detalle.** El nombre cambió y eso explica la mitad de lo que encuentras escrito por ahí:
hasta Boot 3.2 esto era `-Djarmode=layertools`, con el artefacto `spring-boot-jarmode-layertools`;
en **3.3** se sustituyó por `-Djarmode=tools`, que hace lo mismo y además sabe extraer en el layout
eficiente. En el baseline 3.5.16 el que funciona es `tools`. Y ojo con confundir el síntoma: si el
comando falla con `no main manifest attribute`, no falló el jarmode —falló `java -jar` antes de
llegar a él, porque el jar que lanzaste no tiene launcher.

---

### L09 → 4

> Lanzas `java -jar` y recibes `no main manifest attribute`. Di las dos causas más probables en
> un proyecto de Boot y cómo distingues una de la otra en un comando.

**⏱️ 30 segundos.** Una: estás lanzando el **`.jar.original`**, el artefacto que Maven produjo antes
de que `repackage` lo tocara —tus clases y nada más, sin dependencias, sin launcher y sin
`Main-Class`—. Dos: el `repackage` **no corrió**, porque el `spring-boot-maven-plugin` no está
declarado o su goal no quedó enlazado, y el único jar de `target/` es el corriente. Se distinguen
con un comando: `ls -1 target/*.jar*`.

**🗣️ 2 minutos.** Si en `target/` hay **dos** ficheros —el jar y el `.jar.original`—, `repackage`
corrió y el problema es cuál lanzaste; si hay **uno solo**, el problema es el build. La confirmación
directa es `unzip -p target/<jar> META-INF/MANIFEST.MF | grep -E 'Main-Class|Start-Class'`: en el
jar bueno salen las dos líneas, `Main-Class` apuntando a `JarLauncher` y `Start-Class` a
`com.invlab.invapi.InvApiApplication`; en el `.original` no sale ninguna. El mensaje de error **no
menciona el jarmode ni Spring para nada**, y esa es la lección: cuando lo veas en un pipeline, la
pregunta no es "¿por qué no arranca Spring?" sino "¿qué jar estoy lanzando?".

**🔬 El detalle.** La forma en que esto llega a producción casi siempre es un `Dockerfile` con
`COPY target/*.jar app.jar`: el comodín casa con **los dos** ficheros, el orden lo decide el shell,
y un día la imagen se lleva el `.original` y el fallo aparece en el arranque del contenedor y no en
el build. Por eso el `Dockerfile` del lab copia un nombre exacto —`target/inv-api-0.0.1-SNAPSHOT.jar`,
parametrizado con `ARG JAR_FILE`— y el `.dockerignore` excluye `target/*` y vuelve a incluir solo
ese fichero con `!`. Quitar esa línea de reinclusión reproduce el fallo desde el otro lado: el
`COPY` no encuentra nada que copiar.

---

### L09 → 5

> `ENTRYPOINT ["java", "-jar", "app.jar"]` frente a `ENTRYPOINT java -jar app.jar`: explica qué
> cambia en el proceso PID 1 y qué sección de este lab deja de funcionar con la segunda forma.

**⏱️ 30 segundos.** En forma de lista —*exec form*— **la JVM es el PID 1** del contenedor y recibe
el `SIGTERM` directamente. En forma de cadena, Docker lanza `/bin/sh -c "java -jar app.jar"`, **el
PID 1 es el shell** y ese shell no reenvía la señal a su hijo: la JVM no se entera. Con la segunda
forma, la sección 7 entera —el apagado ordenado— deja de funcionar.

**🗣️ 2 minutos.** No es un detalle de estilo, es el error de empaquetado más caro del capítulo, y lo
peor es **cómo se paga**: no hay mensaje de error, no falla el build, no falla el arranque. Lo único
que pasa es que cada `docker compose stop` —y cada terminación de pod en Kubernetes, que manda la
misma señal— se convierte en un `SIGKILL` a los `stop_grace_period` segundos, con las peticiones en
vuelo cortadas a media respuesta. El cliente ve el `000` de `curl`, que significa "no hubo respuesta
HTTP", y en el log **no aparece** ni `Commencing graceful shutdown` ni `Graceful shutdown complete`,
porque el hook de apagado de `SpringApplication` nunca llegó a dispararse.

**🔬 El detalle.** El síntoma es indistinguible del de `server.shutdown=immediate` mirando solo al
cliente: los dos dan `000` y un error de transporte —`curl: (52) Empty reply from server` o
`curl: (18) transfer closed`, cuál de los dos toca no es determinista—. Lo que los separa es el
log, y por eso conviene saber leer los tres escenarios juntos: con exec form y apagado ordenado
salen las dos líneas y el `curl` termina en `200`; con `immediate` no sale ninguna; y con un
`stop_grace_period` demasiado corto sale la primera y no la segunda. Ese tercer caso es el que
miente, y es el de la pregunta 13.

---

### L09 → 6

> "Los buildpacks generan imágenes más pequeñas que un `Dockerfile`." Corrige la frase con la
> versión precisa y di qué es lo que sí garantizan de forma consistente.

**⏱️ 30 segundos.** La versión precisa: **no necesariamente, y depende del builder** —`tiny` no
lleva ni shell ni gestor de paquetes, `base` sí—. Lo que los buildpacks generan de forma consistente
no es *más pequeño*, es **más correcto**: usuario no root, capas ordenadas, metadatos de procedencia
y un JRE al día. El tamaño se mide, no se afirma.

**🗣️ 2 minutos.** El comando que lo zanja es
`docker images --format '{{.Repository}}:{{.Tag}}\t{{.Size}}' inv-api` con las dos imágenes
construidas al lado, y el número que salga es tuyo: depende de tu versión del builder, de tus
dependencias y de la arquitectura de tu máquina. La comparación honesta de fondo es otra: el
buildpack de Paketo **lee tu mismo `layers.idx` y monta las mismas cuatro capas** que escribiste a
mano, así que no es una técnica distinta, es la misma automatizada. Lo que te da gratis es
precisamente lo que uno olvida escribiendo `Dockerfile`: el `USER` no root que el lab deja como
deuda declarada, y la base parcheada al subir de versión del builder.

**🔬 El detalle.** Tampoco vale el argumento simétrico —"el `Dockerfile` es más rápido"—: mídelo con
`time` sobre los dos builds antes de decirlo en una entrevista, recordando que la primera ejecución
de `spring-boot:build-image` descarga el builder y la run image, varios cientos de megabytes, y que
las siguientes reutilizan el caché de capas de CNB. El veredicto del lab es de reparto, no de
bando: buildpacks por defecto para una plantilla de cuarenta servicios iguales; `Dockerfile` cuando
la imagen necesita algo que el builder no expone —un paquete del sistema, un certificado
corporativo, una base endurecida impuesta por el banco— o cuando la política de seguridad exige
poder auditar cada línea de lo que entra.

---

### L09 → 7

> El builder por defecto de `spring-boot:build-image` en Boot 3.5 termina en `:latest`. ¿Por qué
> el curso lo fija, y qué se pierde exactamente al no fijarlo?

**⏱️ 30 segundos.** Porque el curso prohíbe `latest` en cualquier tag, y aquí el `latest` está en la
**base de tu imagen de producción**. Lo que se pierde al no fijarlo es la reproducibilidad: dos
ejecuciones del mismo `pom.xml` separadas por seis meses producen imágenes distintas, sin que nada
en tu repositorio haya cambiado ni quede registro de qué cambió.

**🗣️ 2 minutos.** El default del plugin en Boot 3.5 es
`paketobuildpacks/builder-noble-java-tiny:latest` —lo dice la documentación del plugin— y el lab lo
fija en `0.0.190`, un tag verificado contra el registro el 19 de septiembre de 2026, dentro de
`<configuration><image><builder>`. La diferencia es la de siempre con `latest`, agravada porque
aquí no la controlas tú: el builder trae el JRE, la base del sistema y los propios buildpacks, así
que una publicación del mantenedor puede cambiarte la versión de Java, la distribución base o el
layout de la imagen **entre dos builds del mismo commit**. Y cuando algo se rompa, no tendrás con
qué comparar: no hay forma de reconstruir la imagen de la semana pasada.

**🔬 El detalle.** Fijar el tag no es gratis y por eso es una decisión: obliga a un trabajo de
mantenimiento explícito —subirlo cuando salga un parche del JRE—, que es exactamente el trabajo que
`latest` esconde sin eliminar. La tabla comparativa del lab lo dice en una línea: con `Dockerfile`
la base y sus parches los mantienes tú en cada CVE del JRE, con buildpacks los mantiene el builder
**al subir su versión**, y si nunca subes la versión no los mantiene nadie. En el mismo bloque hay
otra decisión con la misma lógica: `BP_JVM_VERSION: 21` —una variable que leen los buildpacks de
Paketo, no Spring— se escribe aunque el buildpack sepa deducirla del bytecode, para que la versión
de la JVM sea una decisión y no una inferencia.

---

### L09 → 8

> Tu contenedor muere en el arranque con `Connection to localhost:5432 refused`. Explica por qué
> `localhost` es una respuesta correcta desde tu terminal e incorrecta dentro del contenedor.

**⏱️ 30 segundos.** Porque `localhost` no nombra una máquina, nombra **el namespace de red desde el
que se resuelve**. Desde tu terminal, `localhost:5432` es el puerto que Compose publicó en tu
máquina y ahí sí hay un Postgres. Dentro del contenedor, `127.0.0.1` es **el contenedor**, donde no
hay ningún Postgres escuchando y nunca lo hubo. La misma cadena, dos lugares distintos.

**🗣️ 2 minutos.** La corrección es poner el **nombre del servicio de Compose**, que resuelve por DNS
dentro de la red del proyecto: `jdbc:postgresql://postgres:5432/inv_lab`. El error aparece envuelto
en `HikariPool-1 - Exception during pool initialization` porque el fallo ocurre al crear el pool en
el arranque y no al atender una petición —el mismo `HikariPool-1` de `L04` §7, con otra causa: allí
el pool estaba agotado, aquí no llegó a existir—. Y no es un `localhost` solo: un `grep -n localhost
src/main/resources/application.yml` saca cuatro, de los que tres se traducen a nombre de servicio
—`spring.datasource.url`, `spring.data.redis.host` e `inv.supplier.base-url`— y uno no.

**🔬 El detalle.** Dos consecuencias del mismo cambio de punto de vista que sorprenden después.
`management.server.address` tiene que valer `0.0.0.0`: dentro de un contenedor, ligar al loopback no
solo deja fuera al scrape de Prometheus, deja fuera **también a tu `curl` desde la máquina**, porque
el reenvío del puerto publicado llega por la interfaz del contenedor. Y `observability/prometheus.yml`
tenía un quinto `localhost` disfrazado —`host.docker.internal:8081`, el gateway de Docker, que
existía porque `inv-api` vivía fuera— que pasa a ser `inv-api:8081`, con la etiqueta
`instance: inv-api-compose` para no mezclar la serie nueva con la `inv-api-a` del histórico de `L07`.

---

### L09 → 9

> WireMock se publica como `8090:8080`. ¿Qué puerto pone `inv-api` en su `base-url` cuando corre
> fuera de Compose y cuál cuando corre dentro? Escribe la regla general.

**⏱️ 30 segundos.** Fuera de Compose, `http://localhost:8090`; dentro, `http://wiremock:8080`. La
regla general: **los puertos publicados no existen entre contenedores**. El mapeo `HOST:CONTENEDOR`
solo aplica al tráfico que entra desde tu máquina; de contenedor a contenedor se usa el nombre del
servicio y el puerto **de dentro**, el que la aplicación realmente escucha.

**🗣️ 2 minutos.** En `8090:8080`, el `8090` es una decisión sobre tu máquina —evitar el choque con
`inv-api` en `8080`— y no significa nada dentro de la red del proyecto. WireMock siempre escuchó en
`8080`. Por eso el valor que entra por `INV_SUPPLIER_BASEURL` es `http://wiremock:8080`, mientras
que los `curl` de administración que lanzas desde tu terminal —`localhost:8090/__admin/mappings`—
siguen usando el publicado. Es el mismo criterio que hace que Grafana apunte a
`http://prometheus:9090` en su origen de datos y que `inv-api` apunte a
`http://keycloak:8080/...` para bajar el JWKS, aunque tú pidas tokens a `localhost:8180`.

**🔬 El detalle.** Lo que hace este error caro es el síntoma: confundir los puertos da un
`Connection refused` **idéntico** al de haber escrito mal el nombre del servicio, así que se pierde
media hora buscando un problema de DNS que no existe. El discriminante es rápido —`getent hosts
wiremock` o un `curl` desde dentro del contenedor con `docker compose exec`: si el nombre resuelve,
el DNS está bien y el que sobra es el puerto—. Y el caso inverso también se da: publicar un puerto
que nadie consume desde el host es superficie de ataque gratis, que es la razón de que en la serie
solo se publiquen los puertos que tú usas desde la terminal.

---

### L09 → 10

> `issuer-uri` no se puede traducir a un nombre de servicio interno. Explica por qué, y describe
> la solución con sus dos mitades: qué se valida y qué se alcanza.

**⏱️ 30 segundos.** Porque `issuer-uri` hace **dos cosas a la vez** —decir qué valor de `iss` se
valida y decir dónde se descubre el JWKS— y esas dos cosas necesitan URLs distintas. El `iss` de tus
tokens es `http://localhost:8180/realms/inv`, porque es la URL por la que los pediste, y el
validador de emisor compara **carácter a carácter**; el JWKS, en cambio, hay que alcanzarlo por la
red de Compose, en `http://keycloak:8080/...`. La solución es separar las dos mitades: **lo que se
valida** sigue siendo `localhost:8180`, **lo que se alcanza** pasa a ser el nombre de servicio.

**🗣️ 2 minutos.** En la práctica eso es un `JwtDecoder` propio:
`NimbusJwtDecoder.withJwkSetUri(jwkSetUri).build()` —que va directo al JWKS y **no hace
descubrimiento OIDC**, y por eso puede apuntar a un nombre interno— más un `setJwtValidator` con un
`DelegatingOAuth2TokenValidator` que combina `JwtValidators.createDefaultWithIssuer(issuer)` —el
`exp`, el `nbf` y el `JwtIssuerValidator` sobre la cadena de `localhost`— con un `JwtClaimValidator`
sobre `aud`. Declarar ese bean **desactiva el autoconfigurado** sin excluir nada, porque la
autoconfiguración del resource server está marcada con `@ConditionalOnMissingBean`. Las dos entradas
viven bajo un prefijo tuyo, `inv.jwt.issuer` e `inv.jwt.jwk-set-uri`, inyectadas con `@Value` porque
son dos valores sueltos consumidos en un solo sitio, y las de
`spring.security.oauth2.resourceserver.jwt.*` se borran del `application.yml`: dejarlas sería
configuración muerta que el próximo lector va a creerse.

**🔬 El detalle.** El riesgo de sustituir un bean autoconfigurado se cobra aquí en silencio: la
propiedad `jwt.audiences` de `L08` **solo la lee la autoconfiguración**, así que al poner tu decoder
pierdes la comprobación de audiencia y ningún test te lo dice — de ahí el `JwtClaimValidator` sobre
`aud` escrito a mano. Y conviene saber cuál es la salida "de verdad" en producción, porque esta es
la del laboratorio: lo correcto es que el emisor sea **una sola URL alcanzable desde todas partes**
—el `hostname` del IdP resuelto igual dentro y fuera, o el `KC_HOSTNAME` de Keycloak fijado—, y
entonces `issuer-uri` vuelve a bastar. El apaño de las dos mitades es lo que se hace cuando no
controlas quién emite el token.

---

### L09 → 11

> Escribe el nombre de la variable de entorno que liga con `inv.supplier.base-url` y enuncia las
> tres reglas de conversión que usaste.

**⏱️ 30 segundos.** `INV_SUPPLIER_BASEURL`. Las tres reglas: **todo a mayúsculas**, **el punto pasa a
guion bajo** y **el guion se borra** —no se convierte en otra cosa—. Es el *relaxed binding* de
`07` §5, y existe porque un entorno de Unix no admite puntos ni guiones en el nombre de una
variable.

**🗣️ 2 minutos.** Aplicadas al resto del bloque, las mismas tres reglas dan
`spring.datasource.url` → `SPRING_DATASOURCE_URL`, `spring.data.redis.host` →
`SPRING_DATA_REDIS_HOST`, `inv.jwt.jwk-set-uri` → `INV_JWT_JWKSETURI` y `server.shutdown` →
`SERVER_SHUTDOWN`. El error que se comete siempre es escribir `INV_SUPPLIER_BASE_URL`: **liga
igual**, porque el binding relajado acepta ambas formas, pero conviene aprender la canónica para no
depender de la tolerancia. Y el punto entero de usar variables es que la fuente de entorno pisa a
los ficheros del artefacto, así que la misma imagen —sin recompilar— sirve en tu máquina y dentro de
Compose.

**🔬 El detalle.** La demostración de que la variable ganó no se argumenta, se consulta:
`/actuator/env/spring.datasource.url` con el token de `ops` devuelve `propertySources[0]` con
`"name":"systemEnvironment"` y un `origin` que nombra la variable exacta,
`System Environment Property "SPRING_DATASOURCE_URL"` — ese campo convierte una discusión de media
hora en una respuesta de diez segundos. Dos avisos que acompañan a la regla: **ningún secreto viaja
por aquí**, porque una variable de entorno es visible en `docker inspect`, en el `/proc` del
contenedor y en `/actuator/env` si se te olvida cerrarlo; y no todas las variables del bloque son de
Spring —`JAVA_TOOL_OPTIONS: "-XX:MaxRAMPercentage=75"` la lee la JVM, y es la que más se olvida al
contenerizar, porque sin ella el heap se queda en la cuarta parte de la memoria del contenedor.

---

### L09 → 12

> `server.shutdown=graceful` es el default en el baseline del curso. Di desde qué versión, cuál
> era el valor anterior, y por qué la respuesta "hay que activarlo" sigue apareciendo en
> entrevistas.

**⏱️ 30 segundos.** `server.shutdown` vale `graceful` por defecto **desde Spring Boot 3.0**; antes
—en 2.7 y toda la rama 2.x— el default era `immediate`, y había que activarlo a mano. La respuesta
"hay que poner `server.shutdown=graceful`" sigue apareciendo porque fue cierta durante años y
porque casi todo el material escrito antes de 2022 la repite; hoy es una propiedad que ya está
puesta.

**🗣️ 2 minutos.** La versión precisa se dice en tres líneas y con el compañero que casi nadie
nombra: `server.shutdown` en `graceful` y `spring.lifecycle.timeout-per-shutdown-phase` en **30
segundos**, que es cuánto se espera a las peticiones vivas antes de rendirse. Decir "hay que
activarlo" no es solo desactualizado: distrae del problema real, que ya no está en Spring sino en
**quién te ejecuta**. El `stop_grace_period` de Compose vale 10 segundos por defecto —menos que los
30 de Spring— y manda el más corto, así que el apagado ordenado que configuraste no ocurre. Por eso
el servicio del lab declara `stop_grace_period: 45s`.

**🔬 El detalle.** Quién ejecuta el apagado y en qué hilo, que es la pregunta que el curso hace en
cada mecanismo: lo dispara el *shutdown hook* que `SpringApplication` registra en el arranque,
corriendo en un hilo propio de la JVM; desde ahí se cierra el `ApplicationContext`, y el cierre para
los beans `SmartLifecycle` empezando por la fase más temprana, que es donde vive el servidor web. No
hay proxy por medio: es ciclo de vida del contexto, no AOP. Las dos líneas que lo atestiguan las
escribe `GracefulShutdown` de Tomcat —`Commencing graceful shutdown. Waiting for active requests to
complete` y `Graceful shutdown complete`—, y la primera marca el instante en que **Tomcat deja de
aceptar conexiones nuevas a nivel de red** y deja terminar a las vivas. Si el plazo se agota, en
lugar de la segunda aparece `Graceful shutdown aborted with one or more requests still active`, que
es la que te dice que tu timeout es más corto que tu petición más lenta.

---

### L09 → 13

> Tienes `spring.lifecycle.timeout-per-shutdown-phase: 30s` y `stop_grace_period: 10s`. Describe
> qué ve el cliente, qué dice el log, y por qué ese caso es peor que no tener apagado ordenado.

**⏱️ 30 segundos.** El cliente ve un **`000`** y un error de transporte: la conexión se cortó sin
respuesta HTTP, así que ni siquiera sabe si su operación se registró. El log dice
`Commencing graceful shutdown` **y ahí se acaba**: no aparece ni `Graceful shutdown complete` ni el
`aborted`. Es peor que no tener apagado ordenado porque **el log miente**: afirma que el apagado
ordenado empezó y no dice que a los diez segundos llegó un `SIGKILL` que no se negocia.

**🗣️ 2 minutos.** Los dos primeros números los pone Spring y el tercero lo pone quien te ejecuta, y
**manda el más corto**. La configuración de Spring está perfecta, el drenado empieza, y a mitad del
drenado Docker mata el proceso: la petición en vuelo muere igual que con `server.shutdown=immediate`
pero con un rastro que apunta en la dirección equivocada, y el equipo pasa el incidente revisando
propiedades de Spring que ya están bien. La regla que sale de aquí, y que vale igual con
`terminationGracePeriodSeconds` en Kubernetes, es una cadena de desigualdades:
`stop_grace_period` **>** `spring.lifecycle.timeout-per-shutdown-phase` **>** tu petición más lenta.
Tres números en tres ficheros distintos, mantenidos por tres equipos distintos; por eso falla tanto.

**🔬 El detalle.** Para diagnosticarlo hay que saber leer los tres finales posibles, porque el cliente
no los distingue —`000` en dos de los tres—: con el plazo suficiente salen las dos líneas y el
`curl` termina en `200`; con el plazo de Spring corto frente a la petición sale el `aborted`, que es
un problema **tuyo** y se arregla subiendo `timeout-per-shutdown-phase`; y con el
`stop_grace_period` corto sale solo la primera línea, que es un problema del orquestador y no se
arregla en el `application.yml`. Ese último es el que hay que reconocer por **ausencia** de la
segunda línea, y es la única de las tres situaciones en que el registro del apagado queda truncado
a media frase.

---

### L09 → 14

> ¿Qué drena el graceful shutdown y qué **no** drena? Nombra las tres cosas que se quedan fuera
> y la propiedad que rescata una de ellas.

**⏱️ 30 segundos.** Drena **peticiones HTTP vivas**: Tomcat deja de aceptar conexiones nuevas y deja
terminar a las que ya estaban dentro. No drena los `@Async` en vuelo, ni un job de Spring Batch a la
mitad, ni un `@Scheduled` que acaba de empezar. La propiedad que rescata una de ellas es
**`spring.task.execution.shutdown.await-termination: true`**, con su `await-termination-period`,
para el pool del `@Async`.

**🗣️ 2 minutos.** Es la sobregeneralización que más caro sale en una entrevista de banca:
"con graceful shutdown no se pierde nada" es falso — se pierde **todo lo que no sea una petición
HTTP viva**. El mecanismo es de ciclo de vida del servidor web, no del proceso: cierra el conector
ordenadamente y espera como mucho `spring.lifecycle.timeout-per-shutdown-phase`. Un `@Async` que
lanzaste desde un controller sobrevive al 200 que ya devolviste y no tiene a nadie esperándolo, así
que sin esa propiedad su pool se cierra con las tareas encoladas dentro. Para Batch la respuesta no
es una propiedad sino diseño: el reanudado por chunk de `L08` —con el `.name(...)` del reader y su
posición en el `ExecutionContext`— es lo que convierte un job muerto a media corrida en un job
reanudable, y aun así **reanudable no es idempotente**.

**🔬 El detalle.** El escenario que lo vuelve concreto es el de la sección 7 con números de banca:
diecisiete peticiones a medio atender, tres de ellas dentro de un `@Transactional` que ya hizo el
`INSERT` y todavía no el commit. El drenado HTTP salva exactamente esas tres, porque son peticiones
vivas; no salva el correo que un `@Async` iba a enviar ni el chunk 61 del job. Y hay una cuarta
categoría fácil de olvidar: las conexiones salientes y los clientes que mantienen conexiones
persistentes hacia ti **no reciben aviso** de que vas a morir, que es la razón de que en un
despliegue real el orden correcto sea sacarte del balanceador —el `readinessState` que `L07` §3
dejó configurado— **antes** de mandar el `SIGTERM`, y no confiar en que el drenado llegue a tiempo.

---

### L09 → 15

> Después de `docker compose -p inv-lab down -v --remove-orphans`, enumera las cinco clases de
> recurso que siguen ocupando disco en tu máquina y el comando que mide o borra cada una.

**⏱️ 30 segundos.** Cinco: **(1)** las imágenes que construiste, **(2)** las imágenes base de la
serie que descargaste, **(3)** los cachés de build —el de Docker y el del builder de CNB—,
**(4)** los directorios de tu disco que son bind mounts o salida de los labs, y **(5)** el proyecto
Java, con `target/` dentro. `down -v` opera sobre contenedores, volúmenes con nombre y la red del
proyecto: nada de esas cinco cosas es ninguna de esas tres.

**🗣️ 2 minutos.** Una por una, con el comando que la mide o la borra:

```text
1. imágenes propias   docker image rm inv-api:0.0.1-dockerfile
                      docker images -q --filter 'reference=inv-api' | wc -l   → 0
2. imágenes base      docker image ls --format '{{.Repository}}:{{.Tag}}\t{{.Size}}' | grep -E …
                      docker image rm postgres:… redis:… mongo:… wiremock/… prom/… grafana/…
                                     quay.io/keycloak/… eclipse-temurin:… paketobuildpacks/…
3. cachés de build    docker buildx prune -f
                      docker volume ls -q -f name=pack-cache | wc -l         → 0
4. disco, no Docker   rm -rf wiremock observability keycloak data
                      ls -d wiremock observability keycloak data 2>/dev/null | wc -l → 0
5. proyecto Java      ./mvnw -q clean ; rm -f app*.log
                      ls -d target 2>/dev/null | wc -l                        → 0
```

Y el matiz que cierra el lab: **`~/.m2/repository` no se borra**. Solo se mide, con
`du -sh ~/.m2/repository`, porque es el caché de dependencias de Maven **compartido con todos tus
proyectos** —borrarlo obliga a redescargar Spring Boot entero la próxima vez— y su tamaño depende de
todo lo que hayas compilado en tu vida, no de este lab. Por eso el lab pone un `du` y no un `rm`.

**🔬 El detalle.** Tres precisiones de disciplina, que es lo que esta sección enseña de verdad. Una:
**se borra por nombre y tag exactos, nunca con `docker image prune -a`**, porque el prune se lleva
también las imágenes de otros proyectos tuyos que no tengan un contenedor corriendo — nombrar lo que
se borra es parte del trabajo. Dos: `docker buildx prune` es el resto invisible, **puede ser el
mayor consumidor de disco de toda la serie y no aparece en `docker images`**, que es exactamente por
lo que tanta gente cree que limpió y no; los volúmenes `pack-cache-…` son su equivalente del lado
de los buildpacks y sobreviven a `down -v` porque los creó el plugin de Maven, no Compose. Tres:
verificar contando, no mirando — **un `0` es una afirmación y un listado vacío es una ambigüedad**,
porque puede ser que el comando ni se ejecutara. El bloque final de seis contadores
—contenedores, volúmenes, redes, imágenes, puertos y directorios— es el criterio de terminado, y el
de `puertos`, con `lsof -nP -iTCP -sTCP:LISTEN`, es el que caza un `java -jar` tuyo vivo de una
sección anterior: `jobs` y `kill %1` si sigues en esa terminal,
`pkill -f inv-api-0.0.1-SNAPSHOT.jar` si la cerraste.

---

## Apéndice A01 — CLI y tooling de supervivencia

### A01 → 1

> ¿Qué diferencia hay entre `-Dspring-boot.run.arguments` y `-Dspring-boot.run.jvmArguments`,
> y por qué `-Dserver.port=8082` sobre la línea de `./mvnw` no cambia el puerto?

**⏱️ 30 segundos.** `arguments` son los argumentos de tu `main()` —lo que escribirías detrás
del jar en un `java -jar`— y `jvmArguments` son los de la JVM: memoria, agentes, propiedades
de sistema. Un `-D` suelto sobre `./mvnw` no llega a ninguna de las dos porque
`spring-boot:run` **arranca la aplicación en un proceso hijo**, así que esa propiedad se
queda en la JVM de Maven.

**🗣️ 2 minutos.** Las tres formas y su destino:

```text
-Dserver.port=8082                                    → JVM de Maven        → no hace nada
-Dspring-boot.run.arguments="--server.port=8082"      → main() de la app    → funciona
-Dspring-boot.run.jvmArguments="-Dserver.port=8082"   → JVM hija           → funciona
```

Para una **propiedad de configuración** sirven las dos últimas, porque los argumentos de
línea de comandos y las propiedades de sistema están las dos en la cadena de precedencia del
`Environment`. Para un `-Xmx`, un `-XX:` o un `-agentlib` **solo** sirve `jvmArguments`: eso
no es configuración de Spring, es la máquina virtual. Y hay un atajo declarado,
`-Dspring-boot.run.profiles=local`, que es azúcar sobre
`jvmArguments="-Dspring.profiles.active=local"`.

**🔬 El detalle.** En línea de comandos, `spring-boot.run.arguments` **separa por comas, no
por espacios**: `"--server.port=8082,--seed=true"`. Y si ambas fuentes ponen la misma clave,
gana el argumento de línea de comandos sobre la propiedad de sistema, por el orden de
precedencia de `07`. La alternativa que evita toda la pelea de comillas es una variable de
entorno —`SPRING_PROFILES_ACTIVE=local ./mvnw spring-boot:run`—, porque el entorno **sí** se
hereda al proceso hijo.

---

### A01 → 2

> Pides `bootVersion=3.5.16` a `start.spring.io` y responde `400`. ¿Por qué, y cómo generas
> el esqueleto del curso de todas formas?

**⏱️ 30 segundos.** Porque Initializr solo genera líneas con soporte open source vigente, y
3.5 salió de soporte el 30 de junio de 2026. El mensaje lo dice: *"Spring Boot compatibility
range is >=4.0.0"*. Se genera con la versión actual y se baja el `<parent>` a `3.5.16` a
mano.

**🗣️ 2 minutos.** El rechazo es un `400`, no un aviso, así que un script de scaffolding que
lo pedía ayer deja de funcionar hoy sin que nadie lo haya tocado. Y bajar la versión del
`<parent>` no basta: en 4.x el starter web pasó a llamarse `spring-boot-starter-webmvc`, y
en 3.5 es `spring-boot-starter-web`; los starters de test también cambiaron de nombre. Si
copias el POM generado tal cual y solo cambias el número, obtienes un error de resolución de
dependencias que no menciona ni a Boot ni a la versión.

**🔬 El detalle.** La consecuencia práctica en banca es más interesante que el comando: si tu
plataforma está en una línea sin soporte OSS, **el esqueleto de un servicio nuevo no se
genera, se clona** de un arquetipo interno o se produce con un Initializr corporativo propio
(`spring init --target=…` apunta ahí). Contestar eso en una entrevista dice más que recitar
los parámetros de la URL.

---

### A01 → 3

> En una cadena con tres `Caused by`, ¿cuál lees primero y por qué las de arriba no son la
> causa?

**⏱️ 30 segundos.** El **último**. La cadena se lee de abajo arriba: cada nivel es una
traducción del anterior a un vocabulario más abstracto, así que la excepción de arriba te da
la **categoría** del problema y la de abajo el **hecho**.

**🗣️ 2 minutos.** En el trace de la §11 la cadena es:

```text
DataIntegrityViolationException   ← Spring: qué tipo de problema es
  └─ ConstraintViolationException ← Hibernate: quién lo detectó
       └─ PSQLException           ← Postgres: qué pasó de verdad
```

Spring traduce deliberadamente las excepciones del proveedor a su propia jerarquía
(`DataAccessException` y descendientes) para que tu código no dependa de si debajo hay
Postgres u Oracle. Esa traducción es útil para programar y es inútil para diagnosticar: "hay
un problema de integridad de datos" no es información. Lo que sirve es el mensaje de la
raíz, que aquí nombra el índice `inventory_event_sku_seq_key` y los valores exactos que
chocaron.

**🔬 El detalle.** No siempre hay un `Caused by` útil. Los fallos de arranque que Boot conoce
llevan un `FailureAnalyzer` que imprime un bloque `Description:` / `Action:` **en lugar** del
stack trace, y ahí la respuesta está en `Action:` (ver `06`). Cuando no hay analizador,
vuelves a la regla de abajo arriba.

---

### A01 → 4

> Ves un frame `com.invlab.invapi.inventory.InventoryService$$SpringCGLIB$$0.recordEvent(<generated>)`.
> ¿Qué es, y qué te permite descartar su presencia en el trace?

**⏱️ 30 segundos.** Es el **proxy CGLIB** que Spring generó para envolver a
`InventoryService`, no tu clase: no tiene número de línea y dice `<generated>` porque ese
código no existe en ningún fichero fuente. Su presencia prueba que la llamada **pasó por el
proxy**, y por tanto que lo declarativo —`@Transactional`, `@Cacheable`, `@Retryable`— sí
estaba activo.

**🗣️ 2 minutos.** El valor real está en la lectura contraria. Cuando investigas un rollback
que no ocurrió, una caché que nunca guarda o un `@Async` que corrió en el hilo del llamante,
la pregunta es siempre la misma: *¿pasó por el proxy?*. Si en el trace tu método aparece
directamente, sin el frame `$$SpringCGLIB$$` y sin `ReflectiveMethodInvocation.proceed` por
encima, la respuesta es no — y casi siempre es self-invocation: otro método de la misma
clase lo llamó, el proxy no participó, y la anotación no hizo nada (ver `05`).

**🔬 El detalle.** El sufijo depende del tipo de proxy. `$$SpringCGLIB$$0` es un proxy por
subclase, que es lo que Spring Boot usa por defecto; si el bean se proxió por interfaz JDK
verías en su lugar `jdk.proxy2.$Proxy142.recordEvent(Unknown Source)` y frames de
`JdkDynamicAopProxy`. Reconocer las dos formas te dice, de un vistazo, qué estrategia de
proxy está en juego.

---

### A01 → 5

> Un stack trace muestra `commitTransactionAfterReturning` por encima de tu línea de código.
> ¿En qué momento exacto falló el método y qué consecuencia tiene para un `try/catch`?

**⏱️ 30 segundos.** Falló **al hacer commit**, no dentro del método: el método terminó sin
lanzar nada y la excepción apareció cuando el `TransactionInterceptor` confirmó la
transacción. Un `try/catch` alrededor del `repository.save()` no captura absolutamente nada.

**🗣️ 2 minutos.** Es el efecto del *write-behind* de Hibernate: `save()` sobre una entidad
nueva registra la operación en el contexto de persistencia, y el `INSERT` real sale cuando
se hace flush, que por defecto ocurre al confirmar. Por eso este trace explica un síntoma
que leyendo el código parece imposible —"pero si yo capturo la excepción ahí mismo"—. La
secuencia de frames lo cuenta entera:

```text
TransactionInterceptor.invoke                    ← había transacción
invokeWithinTransaction                          ← el método corrió dentro
commitTransactionAfterReturning                  ← y terminó SIN excepción
JpaTransactionManager.doCommit                   ← aquí fue donde reventó
```

**🔬 El detalle.** Si necesitas que el fallo aparezca en el sitio donde lo provocas, el
mecanismo es forzar el flush (`saveAndFlush()`, o `EntityManager.flush()` explícito) dentro
de la transacción. Eso te devuelve la excepción en la línea que la causó a cambio de perder
el batching de escrituras, así que es una herramienta de diagnóstico y de validación de
unicidad puntual, no una política general.

---

### A01 → 6

> ¿Por qué `-DskipTests` no es equivalente a `-Dmaven.test.skip=true`, y cuál de los dos es
> un hallazgo de code review?

**⏱️ 30 segundos.** `-DskipTests` **compila** los tests y no los ejecuta.
`-Dmaven.test.skip=true` ni siquiera los compila. El segundo es el hallazgo de code review.

**🗣️ 2 minutos.** La diferencia se paga en CI. Con `-DskipTests`, un refactor que cambió una
firma y dejó la suite sin compilar **rompe el build**, que es justo lo que quieres: el
artefacto no sale. Con `-Dmaven.test.skip=true`, el pipeline empaqueta y despliega
tranquilamente un artefacto cuyos tests llevan tres semanas sin compilar, y nadie se entera
hasta que alguien intenta ejecutarlos. Ver `-Dmaven.test.skip=true` en un `Jenkinsfile` es
motivo suficiente para bloquear el merge y preguntar por qué está ahí.

**🔬 El detalle.** Hay un tercer caso que confunde: `-DskipITs` salta solo los tests de
integración del plugin `failsafe` y deja pasar los unitarios de `surefire`. En un proyecto
Boot con Testcontainers es el flag razonable para un ciclo rápido en local, porque lo que
tarda son los contenedores, no los tests.

---

### A01 → 7

> `dependency:tree` te muestra la misma librería con dos versiones. ¿Qué flag te dice cuál
> ganó, y con qué criterio resuelve Maven el conflicto?

**⏱️ 30 segundos.** `-Dverbose`, que incluye los nodos omitidos e imprime literalmente
`omitted for conflict with <versión>`. Maven resuelve por ***nearest wins***: gana la
declaración **más cercana a la raíz** del árbol, no la más nueva.

**🗣️ 2 minutos.** El comando completo, con el filtro para no leer doscientas líneas:

```bash
./mvnw -q dependency:tree -Dverbose -Dincludes=com.fasterxml.jackson.core:jackson-databind
```

La regla de cercanía es la que más gente tiene al revés, y explica el caso incómodo: si tu
propio `pom.xml` declara directamente una versión vieja, está a distancia 1 y le gana a la
que el BOM de Boot fija a distancia 3. Ante empate de distancia, gana la que aparece
primero en el orden de declaración.

**🔬 El detalle.** Las dos correcciones no son intercambiables. Una `<exclusion>` es
quirúrgica —quita esa dependencia de esa rama— y frágil: si mañana otra librería arrastra la
misma versión vieja, vuelve el problema. Cambiar la propiedad del BOM
(`<jackson-bom.version>`) arregla **todo el grupo de artefactos** a la vez, que con Jackson
es lo que hace falta porque `core`, `databind` y `annotations` tienen que ir a juego. Lo que
nunca se hace es declarar la dependencia con `<version>` en tu POM "para que gane": funciona
por la regla de cercanía y te dejará atrás, en silencio, la próxima vez que subas de Boot.

---

### A01 → 8

> La aplicación no responde, Actuator está cerrado y solo tienes SSH. Escribe los dos
> comandos que corres, en orden, y di qué buscas en la salida del segundo.

**⏱️ 30 segundos.**

```bash
jps -lvm                       # el PID, y de paso el profile y el -Xmx con que arrancó
jcmd <pid> Thread.print        # el thread dump
```

En el dump busco **cuántos hilos `http-nio-8080-exec-*` hay y en qué estado**: si están
`TIMED_WAITING` o `BLOCKED` en el mismo sitio, ahí está el atasco.

**🗣️ 2 minutos.** `jps -lvm` da tres cosas a la vez: el PID (`-l`, con la clase principal
completamente cualificada), los argumentos del `main()` (`-m`, donde suele verse
`--spring.profiles.active=prod`) y los de la JVM (`-v`, donde está `-Xmx`). Son las primeras
preguntas del diagnóstico contestadas antes de tocar nada.

El patrón clásico en el dump es veinte hilos de Tomcat parados dentro de
`com.zaxxer.hikari.pool.HikariPool.getConnection`: eso no es un problema de CPU, es el pool
agotado, y el culpable está más abajo en esas mismas pilas. El procedimiento correcto es
sacar **dos dumps separados por treinta segundos**: uno es una foto, dos dan movimiento, y
lo que aparece idéntico en ambos es lo que está realmente bloqueado.

**🔬 El detalle.** `jcmd <pid> help` lista todo lo que ese proceso acepta sin que haya que
memorizarlo: `GC.heap_info`, `GC.class_histogram`, `VM.system_properties`, `VM.command_line`,
`JFR.start`. `jstack -l <pid>` hace el mismo dump y añade información de locks, que a veces
es justo lo que falta para distinguir un deadlock de una espera. Y si `jps` no lista nada
aunque sepas que la aplicación corre, casi siempre es que arrancó con otro usuario.

---

### A01 → 9

> ¿Por qué un heap dump no se saca en producción con la misma tranquilidad que un thread
> dump? Da la unidad del costo.

**⏱️ 30 segundos.** El thread dump es una pausa de safepoint de **milisegundos**. El heap
dump **congela la aplicación mientras escribe** un fichero del orden del tamaño del heap:
con `-Xmx4g` son varios GB y **decenas de segundos** de servicio caído, más el disco libre
que hace falta.

**🗣️ 2 minutos.** En un servicio de banca eso no es una herramienta de diagnóstico, es un
incidente que te provocas tú: si lo lanzas en hora punta, los timeouts del cliente disparan
reintentos y el problema que investigabas queda tapado por el que acabas de crear. Un heap
dump se programa, se avisa, y a ser posible se toma de una instancia sacada del balanceador.

La opción barata es dejarlo preparado en vez de improvisarlo:
`-XX:+HeapDumpOnOutOfMemoryError` escribe el `.hprof` automáticamente en el momento en que la
JVM se queda sin memoria, que además es el instante exacto en que el dump vale algo.

**🔬 El detalle.** `jcmd <pid> GC.heap_dump <fichero>` y `jmap -dump:live,format=b,file=…
<pid>` producen lo mismo; `jcmd` es la vía que la documentación recomienda hoy. El
modificador `live` fuerza un GC completo antes de volcar, así que el fichero solo contiene
objetos alcanzables: más pequeño y más limpio, a cambio de una pausa extra. Antes de llegar
al dump, `GC.heap_info` y `GC.class_histogram | head -20` contestan en diez segundos si el
problema es memoria y qué clase la está reteniendo.

---

### A01 → 10

> Añades `-agentlib:jdwp=…,suspend=y,address=5005` a un contenedor y ni arranca ni te puedes
> conectar. ¿Cuáles son los dos errores?

**⏱️ 30 segundos.** `suspend=y` deja la JVM **congelada esperando** a que alguien se conecte
—no es que no arranque, es que está detenida a propósito—, y `address=5005` a secas escucha
solo en `localhost`, así que desde fuera del contenedor no hay nada a lo que conectarse. Se
arregla con `suspend=n` y `address=*:5005`.

**🗣️ 2 minutos.** La línea completa:

```bash
-agentlib:jdwp=transport=dt_socket,server=y,suspend=n,address=*:5005
```

`transport=dt_socket` usa un socket TCP, que es lo que espera cualquier IDE; `server=y` hace
que la JVM escuche y el IDE se conecte a ella. `suspend=y` sigue siendo la opción correcta
**cuando lo que quieres depurar es el arranque del contexto** —poner un breakpoint en un
`@PostConstruct` o en una autoconfiguración exige que la JVM te espere—, pero entonces sabes
que está parada y no lo confundes con un cuelgue.

**🔬 El detalle.** Lo de `address` cambió en Java 9: antes, un puerto suelto escuchaba en
todas las interfaces; desde entonces, un valor sin host se interpreta como `localhost` por
seguridad, y hay que escribir `*:5005` explícitamente. Ese cambio es la causa de la mitad de
los "no me puedo conectar al debug del contenedor", y de paso explica por qué la opción es
peligrosa: un 5005 alcanzable es ejecución remota de código —leer memoria, cambiar variables,
invocar métodos— sin autenticación ninguna. Se abre para una sesión y se cierra.

---

### A01 → 11

> ¿Qué hace exactamente `spring-boot:repackage` y por qué hay que desactivarlo cuando el
> artefacto es una librería?

**⏱️ 30 segundos.** Toma el jar normal que produjo Maven y lo reescribe como jar ejecutable
de Boot: el `JarLauncher` en el `MANIFEST`, tus clases en `BOOT-INF/classes/` y las
dependencias como jars anidados en `BOOT-INF/lib/`. Como las clases dejan de estar en la
raíz, **ese jar no sirve como dependencia de Maven**.

**🗣️ 2 minutos.** El síntoma es inconfundible y desconcertante: tu librería compila y se
publica sin errores, y el proyecto que la declara como dependencia no encuentra **ninguna**
de sus clases. La corrección es `-Dspring-boot.repackage.skip=true`, o la configuración
equivalente en el plugin, para que el artefacto se quede siendo un jar corriente.

La prueba visual está en `target/` después de un `./mvnw package`: quedan dos ficheros, el
jar reescrito y el `.jar.original`, que es el de Maven antes de la operación. Ocho KB frente
a cincuenta MB. Cuando alguien dice "el jar de Spring Boot pesa mucho", esos dos ficheros
lado a lado son la explicación entera.

**🔬 El detalle.** `repackage` está atada al ciclo de vida por el `spring-boot-starter-parent`
y se ejecuta en la fase `package`; las otras metas del plugin no están atadas a nada y hay
que invocarlas o declararlas. `build-info`, por ejemplo, solo genera
`META-INF/build-info.properties` —lo que alimenta `/actuator/info`— si la declaras
explícitamente en un `<execution>`.

---

### A01 → 12

> Activas `spring.jpa.show-sql=true` y tu compañero te dice que uses
> `logging.level.org.hibernate.SQL=DEBUG`. ¿Qué ganas con el cambio?

**⏱️ 30 segundos.** `show-sql` escribe por `System.out`: sin nivel, sin formato, sin
`traceId` y sin poder apagarlo en caliente. `logging.level.org.hibernate.SQL=DEBUG` pasa por
el sistema de logging normal, así que hereda el patrón, la correlación de trazas y el
endpoint `loggers` de Actuator para cambiarlo sin reiniciar.

**🗣️ 2 minutos.** En local, para una sesión de diez minutos, `show-sql` no hace daño. En un
entorno compartido sí: un `System.out` sin nivel no se puede silenciar sin redesplegar, no
lleva el `traceId` que necesitas para correlacionarlo con el request que lo provocó, y en un
servicio con carga llena el disco de logs de un volumen que nadie presupuestó.

Y hay un segundo logger que casi siempre se quiere a la vez:

```yaml
logging:
  level:
    org.hibernate.SQL: DEBUG                # la sentencia
    org.hibernate.orm.jdbc.bind: TRACE      # y los valores de los ?
```

**🔬 El detalle.** El nombre del logger de parámetros **cambió en Hibernate 6**: antes era
`org.hibernate.type.descriptor.sql`, y en la versión que arrastra Boot 3.5 es
`org.hibernate.orm.jdbc.bind`. Copiar la configuración de una fuente de 2019 es la causa
número uno de "activé el log de SQL y los parámetros salen como `?`". Y sobre la línea de
comandos, `-Dspring.jpa.show-sql=true` a secas sobre `./mvnw` no hace nada en absoluto: esa
propiedad se queda en la JVM de Maven y nunca llega al proceso hijo (ver A01 → 1).

---

## Apéndice A02 — Catálogo de anotaciones

### A02 → 1

> Nombra tres anotaciones que sean de Spring Boot y tres que sean de Spring Framework, y di
> qué criterio las separa.

**⏱️ 30 segundos.** De **Boot**: `@SpringBootApplication`, `@ConfigurationProperties` y la
familia `@ConditionalOn*`. De **Framework**: `@Service`, `@Transactional` y `@GetMapping` —o
`@Autowired`, o `@Cacheable`—. El criterio: **Boot no tiene una sola anotación de negocio
propia**; las suyas son de arranque, configuración y test. Todo lo que escribes en el código
de dominio es del Framework.

**🗣️ 2 minutos.** La frase que lo ordena es "si le quitas Boot a tu aplicación, sigues
escribiendo Spring; lo que pierdes es el arranque, no el modelo de programación". Boot aporta
cinco cosas —autoconfiguración, starters, gestión de versiones, servidor embebido y las
capacidades de producción de Actuator— y ninguna de ellas es una anotación que uses para
declarar un servicio, una transacción o un endpoint
([`01` §3](01-spring-boot-y-el-ecosistema.md#3--qué-añade-spring-boot-exactamente)). Del lado
de Boot caen también los slices de test (`@WebMvcTest`, `@DataJpaTest`) y `@AutoConfiguration`.

**🔬 El detalle.** El criterio tiene dos bordes que se preguntan justo después. El primero:
hay anotaciones del catálogo que **no son de ninguno de los dos proyectos** —`@Valid`,
`@NotNull` y `@PostConstruct` son de Jakarta; `@Retry`, `@CircuitBreaker` y `@Bulkhead` son
de Resilience4j; `@Timed` y `@Counted` son de Micrometer; `@Mock` es de Mockito—. El segundo,
el caso `@MockitoBean`: parece de Boot porque se usa en un `@SpringBootTest` y es de Framework
6.2 (entrada 9). Y hay un nombre que existe dos veces en dos proyectos distintos:
`@Transactional` de Spring y `@Transactional` de `jakarta.transaction`, que abre la
transacción igual pero se queda sin `readOnly`, `isolation` ni `timeout`
([`16` §7](16-transacciones.md#7--los-seis-silencios)).

---

### A02 → 2

> `@Component` y `@Bean` producen los dos una bean definition. ¿Qué te obliga a elegir una en
> vez de la otra, y de dónde sale el nombre del bean en cada caso?

**⏱️ 30 segundos.** Te obliga **quién escribió la clase**: `@Component` necesita que la clase
sea tuya y anotable, `@Bean` construye cualquier objeto —incluido uno de una librería de
terceros— con lógica de por medio. El nombre sale de la **clase con la primera letra en
minúscula** (`inventoryService`) o, con `@Bean`, del **nombre del método** (`supplierClient`).

**🗣️ 2 minutos.** No es una preferencia de estilo: un `RestClient`, un `ObjectMapper` o un
`Clock` no se pueden anotar, así que su bean definition solo puede escribirse como receta en
un método `@Bean` de una `@Configuration`. Al revés, para una clase tuya el `@Component` —o su
estereotipo— evita escribir el constructor a mano. Y los argumentos de un método `@Bean` son
**puntos de inyección** como los de un constructor, así que el `RestClient.Builder` del ejemplo
del curso llega resuelto por el contenedor
([`02` §5](02-contenedor-ioc-y-ciclo-de-vida.md#5--component-y-bean-no-son-lo-mismo)).

**🔬 El detalle.** La consecuencia del nombre es la que muerde: **renombrar un método `@Bean`
renombra el bean**, y eso rompe en silencio cualquier `@Qualifier("supplierClient")` que lo
buscara por nombre, y también el último desempate de la resolución por nombre de parámetro. Un
refactor de IDE que "solo" cambia un nombre de método es un cambio de contrato. Lo mismo, con
otra cara, en `@ComponentScan`: un `@Component` fuera del subárbol del paquete base no existe
—`NoSuchBeanDefinitionException`— y la salida es `@Import`, que trae la `@Configuration` esté
donde esté ([`02` §7](02-contenedor-ioc-y-ciclo-de-vida.md#7--component-scan-el-paquete-base)).

---

### A02 → 3

> ¿Cuál de los cuatro estereotipos añade comportamiento real y no solo semántica? ¿Qué
> comportamiento?

**⏱️ 30 segundos.** `@Repository`. Traduce las excepciones propias del driver —`SQLException`,
`PSQLException`, `ORA-00001`— a la jerarquía **no chequeada** de `DataAccessException`.
`@Component`, `@Service` y `@Controller` son para el contenedor lo mismo: `@Controller` cambia
cómo se interpreta el retorno, pero eso lo pone MVC, no el estereotipo.

**🗣️ 2 minutos.** El valor de esa traducción es que tu servicio deja de casar con el motor:
capturar `PSQLException` ata el código a Postgres, y `DuplicateKeyException` es el mismo hecho
sin el nombre del proveedor. De ahí salen mapeos directos a tu API —`DuplicateKeyException` es
tu 409, `CannotAcquireLockException` un deadlock reintentable,
`OptimisticLockingFailureException` la que produce `@Version`— y que todas sean
`RuntimeException` es deliberado: el rollback por defecto de `@Transactional` se dispara con
las no chequeadas y no con una chequeada
([`15` §3](15-datos-jdbc-jpa-mongo-y-redis.md#3--jdbcclient-y-la-jerarquía-de-dataaccessexception)).

**🔬 El detalle.** El comportamiento no está "dentro" de la anotación: en un `@Repository` con
JDBC crudo la traducción **la aplica un proxy** —el mismo mecanismo de
[`05` §2](05-proxies-y-aop.md#2--quién-crea-el-proxy-y-cuándo) con otro sombrero—, así que es
otra fila más de la familia del catálogo que depende del proxy. Con Spring Data no hace falta
anotar nada, porque el repositorio lo genera el propio Spring Data y ya trae la traducción. Y
el matiz de `@Controller` conviene decirlo entero: sin `@ResponseBody` un `String` devuelto es
**el nombre de una vista**, y el resultado es un 404 sobre una URL que sí mapeaste
([`09` §3](09-rest-con-spring-mvc.md#3--controller-vs-restcontroller)).

---

### A02 → 4

> Un método lleva `@Transactional` y no se abre ninguna transacción, sin error ni log.
> Enumera las cinco situaciones de este catálogo que lo producen.

**⏱️ 30 segundos.** Las cinco son: **llamada desde la misma clase** (self-invocation), método
**`private`**, método **`final`**, método **`static`** y llamada **desde un `@PostConstruct`**.
Todas tienen la misma causa —el proxy no participa o no puede sobrescribir el método— y
ninguna avisa: ni el compilador, ni el arranque, ni el log.

**🗣️ 2 minutos.** La regla mental que las cubre a las cinco cabe en dos líneas:

```text
misma clase  → no hay proxy  → no hay transacción, ni caché, ni retry, ni async, ni permiso
otro bean    → hay proxy     → la anotación hace lo que promete
```

Y no es una lista de `@Transactional`: las mismas cinco afectan a `@Cacheable`, `@CachePut`,
`@CacheEvict`, `@Async`, `@Scheduled`, `@Retry`, `@CircuitBreaker`, `@Bulkhead`,
`@PreAuthorize`, `@PostAuthorize`, `@Timed` y `@Counted`, cada una con su síntoma propio
([`05` §6](05-proxies-y-aop.md#6--lo-que-un-proxy-no-puede-interceptar)). El diagnóstico es
uno solo y no necesita debugger: sube
`logging.level.org.springframework.transaction.interceptor=TRACE` y mira si aparece
`Getting transaction for [...]` antes de tu método. **Si no aparece, no hubo transacción.**

**🔬 El detalle.** Lo que hace precisa la respuesta es saber qué **no** entra en la lista de
cinco. La **clase `final`** falla en el arranque, así que no es un silencio; la **excepción
capturada dentro del método** sí abre la transacción y lo que pierde es el rollback; y el
`@Transactional` de **`jakarta.transaction`** también abre la transacción y solo se queda sin
`readOnly`, `isolation` y `timeout`. Esos tres, más los cinco de arriba menos el `static`,
son los **seis silencios** de [`16` §7](16-transacciones.md#7--los-seis-silencios). Y hay
media respuesta vieja que hay que corregir: *"solo funciona en métodos `public`"* dejó de ser
exacto en Spring Framework 6.0 — con CGLIB, el default de Boot, también se respeta en
`protected` y package-private, porque la subclase puede sobrescribirlos. Lo que nunca
funciona es `private`.

---

### A02 → 5

> Distingue `@Valid` de `@Validated` en tres ejes: proyecto al que pertenece, dónde se pone y
> qué excepción provoca cuando falla un parámetro de controller.

**⏱️ 30 segundos.** `@Valid` es de **`jakarta.validation`**, va en un **argumento o un campo**
y la aplica MVC al resolver el argumento. `@Validated` es de **Spring**, va en la **clase** y
activa la validación vía proxy. En un parámetro de controller: **sin** `@Validated` en la
clase sale `HandlerMethodValidationException` → **400**; **con** `@Validated` sale
`ConstraintViolationException` → **500**.

**🗣️ 2 minutos.** Lo contraintuitivo es que **el 500 lo causa la anotación que creías que lo
evitaba**. Desde Spring Framework 6.1, MVC valida por su cuenta las restricciones puestas en
la firma del handler; poner `@Validated` en la clase del controller **devuelve** esa
validación al camino de AOP de `MethodValidationPostProcessor`, y esa excepción es de Jakarta,
desconocida para MVC, que la trata como fallo del servidor. La reference lo dice con todas las
letras: *"you need to remove the class level `@Validated` annotation from the controller"*. El
sitio de `@Validated` son los `@Service`, donde no hay MVC que valide por ti y solo hay proxy
([`10` §3](10-diseno-de-api-validacion-errores-e-hipermedia.md#3--valid-vs-validated-y-qué-excepción-lanza-cada-caso)).

**🔬 El detalle.** El tercer eje real —el que no pide la pregunta y da puntos— son los
**grupos**: `@Valid` no los acepta, `@Validated(OnCreate.class)` sí, y la trampa es que una
restricción **sin** `groups` pertenece a `Default` y **no se evalúa** cuando pides un grupo
concreto. Conviene llevar la tabla entera de excepción → status, porque convierte un "puse
`@Max` y responde 500" en un diagnóstico de diez segundos:
`MethodArgumentNotValidException` (body inválido) y `HandlerMethodValidationException`
(parámetro sin `@Validated`) salen 400; `ConstraintViolationException` sale 500. Y por debajo
de todo, la trampa que no es de ninguna anotación: **sin `spring-boot-starter-validation` en
el `pom.xml` no hay error de arranque, las anotaciones se ignoran en silencio**.

---

### A02 → 6

> ¿Qué diferencia hay entre `condition` y `unless` en un `@Cacheable`, y cuál de los dos puede
> mirar `#result`?

**⏱️ 30 segundos.** *Condition decide si participas, unless decide si guardas.* `condition` se
evalúa **antes** de ejecutar el método: si es `false`, la caché ni se consulta ni se escribe.
`unless` se evalúa **después** y solo veta la escritura, nunca la lectura. **`#result` solo lo
ve `unless`**, porque cuando se evalúa `condition` el resultado todavía no existe.

**🗣️ 2 minutos.** `condition` ve los argumentos y el `#root` completo —`method`, `target`,
`caches`—; lo único que le falta es `#result`. Por eso los usos típicos se reparten solos:
`condition = "#sku != null and #sku.length() == 8"` filtra entradas que no vale la pena
cachear, y `unless = "#result == null or #result.quantity() == 0"` evita guardar resultados
inútiles —recordando que, por defecto, **`@Cacheable` también cachea el `null`** salvo que lo
vetes con `unless`—
([`17` §3](17-cache.md#3--la-clave-key-condition-unless-y-el-keygenerator)). Los dos son SpEL
sobre el contexto del método, igual que `key`, y `#sku` por nombre de parámetro exige
`-parameters`, que el plugin de Boot activa.

---

### A02 → 7

> Tienes dos beans de tipo `TaskExecutor` sin cualificar y un método `@Async` sin nombre.
> ¿Falla el arranque? ¿Dónde acaba ejecutándose la tarea?

**⏱️ 30 segundos.** **No falla.** `AsyncExecutionAspectSupport.getDefaultExecutor()` atrapa la
`NoUniqueBeanDefinitionException`, busca un bean llamado `taskExecutor` y, si tampoco existe,
lo dice en un log de nivel **INFO** y devuelve `null`. El interceptor cae entonces a un
`SimpleAsyncTaskExecutor` nuevo: **sin pool y con un hilo por tarea**. La tarea se ejecuta, y
esa es justamente la trampa.

**🗣️ 2 minutos.** No hay fallo: hay **degradación silenciosa**. El pool configurado —con su
`core-size`, su `max-size` y su cola— no se usa, y cada llamada crea un hilo nuevo sin techo,
que bajo carga es exactamente lo que el pool existía para evitar. Y no se ve en el log, porque
el único rastro es una línea INFO en el arranque que nadie lee; se ve en el **thread dump**
([`18` §2](18-asincronia-scheduling-y-eventos.md#2--async-quién-lo-ejecuta-y-qué-devuelve)).
Las dos salidas son nombrar el executor en la anotación —`@Async("inventoryExecutor")`— o
llamar `taskExecutor` al bean que quieres por defecto.

**🔬 El detalle.** Esto se enreda con los otros dos silencios de `@Async`, y en una entrevista
conviene separarlos: **sin `@EnableAsync`** no hay proxy y el método corre en el hilo del
llamante, también sin avisar —Boot no lo activa por ti: la autoconfiguración crea el executor,
no el `@EnableAsync`—; y en **self-invocation** ocurre lo mismo
([`18` §3](18-asincronia-scheduling-y-eventos.md#3-️-las-dos-formas-de-que-async-no-haga-nada)).
Los tres casos tienen el mismo síntoma aparente —"no va en paralelo"— y evidencias distintas:
el nombre del hilo en el log los distingue. Y el executor por defecto tiene su propia trampa
aparte: **llena la cola antes de crecer** hacia `max-size`, así que con la cola ilimitada del
default ese `max-size` no se alcanza nunca
([`18` §4](18-asincronia-scheduling-y-eventos.md#4-️-el-executor-los-tres-números-y-la-cola-traicionera)).

---

### A02 → 8

> ¿Por qué `@EnableBatchProcessing` no se escribe en una aplicación Spring Boot, y qué se
> rompe si la escribes?

**⏱️ 30 segundos.** Porque **desactiva la autoconfiguración de Batch**. Lo mismo hace extender
`DefaultBatchConfiguration`. Lo que se rompe primero es la **creación del esquema de
metadatos**: las seis tablas `BATCH_*` no aparecen, y con ellas se cae el `JobRepository`.

**🗣️ 2 minutos.** Es la trampa número uno al copiar ejemplos de la documentación de Spring
Batch a secas, que sí lleva la anotación porque **no asume Boot**: fuera de Boot alguien tiene
que declarar el `JobRepository` y el `TransactionManager`, y esa anotación es quien lo hace.
Dentro de Boot ese trabajo ya está hecho por la autoconfiguración, así que escribirla es
apagarla ([`22` §4](22-spring-batch.md#4--el-jobrepository-seis-tablas-y-ningún-truco)). En
Spring Batch 5 un job se declara con builders —`new StepBuilder(nombre, jobRepository)`—, no
con anotaciones: por eso la familia Batch del catálogo es la más corta, y su única entrada es
una anotación que **no se escribe**.

**🔬 El detalle.** El esquema merece su propio matiz porque falla en el sitio incómodo:
`spring.batch.jdbc.initialize-schema` vale `embedded` por defecto, así que las tablas **se
crean solas en H2 y no se crean en tu Postgres**. En producción van en Flyway con la propiedad
en `never`, y `table-prefix` cambia el prefijo `BATCH_`. Y hay un cambio de versión que
conviene tener fresco: en **Spring Boot 4 / Spring Batch 6 `@EnableBatchProcessing` vuelve**,
acompañada de `@EnableJdbcJobRepository` o `@EnableMongoJobRepository`; el modelo —job, step,
chunk, `JobRepository`— sigue igual ([`22` §11](22-spring-batch.md#11-️-errores-frecuentes)).

---

### A02 → 9

> `@MockBean` está deprecada: di desde qué versión, qué anotación la sustituye y **de qué
> proyecto** es la sustituta.

**⏱️ 30 segundos.** Deprecada **desde Spring Boot 3.4.0**, y no de cualquier manera: el javadoc
de 3.5.16 dice `@Deprecated(since = "3.4.0", forRemoval = true)`, igual que `@SpyBean`. La
sustituta es **`@MockitoBean`** (y `@MockitoSpyBean`), y es de **Spring Framework 6.2**, no de
Boot: vive en `org.springframework.test.context.bean.override.mockito`.

**🗣️ 2 minutos.** El cambio de proyecto es el fondo de la pregunta, no un dato de trivia:
Framework 6.2 generalizó el *bean overriding* como mecanismo propio del TestContext —del que
`@TestBean` es la tercera pieza—, y Boot dejó de mantener el suyo. Decir "`@MockitoBean` es la
nueva de Boot" es la media respuesta. Las fechas van juntas: Framework 6.2 y Boot 3.4 salieron
a la vez, y **en 4.x `@MockBean` y `@SpyBean` ya no existen** —el paquete
`org.springframework.boot.test.mock.mockito` desapareció—
([`24` §5](24-testing.md#5--mockitobean-y-mockitospybean-sustituir-un-bean-no-un-objeto)).

**🔬 El detalle.** Lo que no cambió al renombrarse es lo que de verdad hay que saber de estas
anotaciones, y son dos cosas. La primera: **al sustituir el bean sustituyes su proxy**, así
que moquear un bean con `@Transactional`, `@Cacheable` o `@Retryable` deja al mock sin
transacción, sin caché y sin reintento, y el test pasa sin probar lo que creías. La segunda:
**cada bean override cambia la clave de la caché de contextos**, así que un `@MockitoBean` en
una clase y no en otra ya son dos contextos y dos arranques — es por donde se van los minutos
de una suite ([`24` §6](24-testing.md#6-️-la-caché-de-contextos-aquí-se-van-los-ocho-minutos)).
De paso, en 4.x los slices también cambiaron de paquete: `@WebMvcTest` vive hoy en
`org.springframework.boot.webmvc.test.autoconfigure`.

---

### A02 → 10

> "Puse `@Timed` y la métrica no aparece": da las tres comprobaciones, en orden, y di cuál de
> ellas es la misma que harías con un `@Cacheable` que no acierta.

**⏱️ 30 segundos.** En orden: **1)** ¿está `management.observations.annotations.enabled=true`?
—vale **`false` por defecto**, y sin ella no se registran `TimedAspect` ni `CountedAspect`—;
**2)** ¿está `spring-boot-starter-aop` en el classpath? —el aspecto se condiciona a
`org.aspectj.weaver.Advice`—; **3)** ¿la llamada viene de **otro bean**? La tercera es la
compartida con `@Cacheable`: la **self-invocation**.

**🗣️ 2 minutos.** El orden no es casual: va de lo más barato de comprobar a lo más caro, y las
dos primeras son específicas de Micrometer mientras la tercera es la de siempre. `@Timed` y
`@Counted` son de `io.micrometer.core.annotation` y funcionan con **un aspecto sobre un
proxy**, de modo que heredan enteros los cinco silencios de la entrada 4
([`23` §7](23-actuator-y-observabilidad.md#7--micrometer-meterregistry-los-cuatro-medidores-y-las-anotaciones)).
Con `@Cacheable` la lista equivalente es: ¿está `@EnableCaching`?, ¿la llamada viene de otro
bean?, ¿`condition` o `unless` la vetan?, ¿la clave es estable? — y el corte limpio es la
métrica: **si `cache.gets` no registra ni un `miss`, el problema es el proxy, no la caché**
([`17` §10](17-cache.md#10--sin-hit-ratio-esto-es-una-suposición)).

**🔬 El detalle.** La salida que el curso prefiere para el dominio no es la anotación sino el
medidor a mano: un `Timer.builder(...).register(registry)` resuelto **en el constructor** y un
`timer.record(...)` alrededor del bloque, que además te deja elegir **qué** mides. En `L07` el
`Timer` va **dentro** del `@Cacheable` a propósito: el interceptor de caché envuelve al método,
así que un acierto ni siquiera entra, y el `Timer` mide el coste real de calcular y no la
latencia del endpoint —esa ya la mide `http.server.requests`—
([`L07` §5](l07-actuator-metricas-y-trazas.md#5--métricas-propias-timer-counter-y-el-timed-que-no-aparece)).
Y la advertencia que acompaña a toda instrumentación a mano: **el identificador único nunca es
un tag**; etiquetar con `sku` hace explotar la cardinalidad y te quedas sin **todas** las
métricas, no solo sin la mal etiquetada
([`23` §8](23-actuator-y-observabilidad.md#8-️-tags-y-cardinalidad-el-error-que-tumba-prometheus)).

---

## Apéndice A03 — Catálogo de errores y diagnóstico

### A03 → 1

> Un arranque falla con un bloque `Description:` / `Action:` y sin stack trace. ¿Qué te dice
> eso sobre quién produjo el mensaje, y qué lees primero?

**⏱️ 30 segundos.** Que ese fallo lo reconoció un `FailureAnalyzer` de Boot: alguien tradujo
la excepción cruda a un mensaje accionable y **la imprimió en lugar del stack trace**. Lo
primero —y casi siempre lo único— que lees es `Action:`.

**🗣️ 2 minutos.** `Description:` dice qué pasó y `Action:` qué hacer, y no hay trace que bajar
porque el analizador lo sustituyó a propósito. La lectura interesante es la contraria: **que
no haya bloque también es información**, significa que nadie escribió un analizador para ese
fallo y entonces toca el procedimiento de stack trace —el último `Caused by:`— de
[`A01` §11](a01-cli-y-tooling-de-supervivencia.md#11--cómo-leer-un-stack-trace-de-spring). La
excepción real sigue existiendo debajo del texto amable y sale entera con `--debug`.

**🔬 El detalle.** Los cuatro analizadores que vas a ver en este curso son el de
`NoUniqueBeanDefinitionException` —`Parameter 2 of constructor … required a single bean, but
2 were found`, con la lista de candidatos y el método que los declaró—, el de
`PortInUseException`, el diagrama de cajas del ciclo de beans y el del binding de
`@ConfigurationProperties`, cuyo `Origin` da fichero, línea y columna del valor culpable. Y
conviene saber el nombre de la excepción de debajo aunque el bloque te la esconda, porque el
texto amable no siempre está: la de los dos `Clock` dice `expected single matching bean but
found 2: clock,utcClock`.

---

### A03 → 2

> En una cadena de tres `Caused by:`, ¿cuál es la excepción original y por qué
> `UnsatisfiedDependencyException` casi nunca es la que hay que corregir?

**⏱️ 30 segundos.** La original es la **última** de la cadena; las de arriba son traducciones.
`UnsatisfiedDependencyException` no es un error por sí misma: es el **envoltorio** con que el
contenedor reporta que no pudo satisfacer un punto de inyección.

**🗣️ 2 minutos.** Se lee de abajo arriba porque cada nivel traduce el anterior a un
vocabulario más abstracto: la de arriba te da la **categoría** y la de abajo el **hecho**. Lo
único que aporta `UnsatisfiedDependencyException` es la primera mitad de su mensaje, que
nombra el parámetro o la propiedad exacta que no se pudo resolver; la corrección está siempre
en su causa. Y la causa te clasifica el problema en un vistazo:

```text
No qualifying bean of type          → escaneo fuera del subárbol, o un @Conditional en false
expected single matching bean but   → ambigüedad entre candidatos del mismo tipo
currently in creation               → dependencia circular por constructor
```

**🔬 El detalle.** El mismo patrón fuera del arranque: en datos, la cadena es
`DataIntegrityViolationException` (Spring: qué tipo de problema es) → `ConstraintViolationException`
de Hibernate (quién lo detectó) → `PSQLException` (qué pasó de verdad, con el índice y los
valores que chocaron). La traducción a la jerarquía de `DataAccessException` es útil para
programar y **inútil para diagnosticar**. La excepción a la regla es la entrada anterior:
cuando hay bloque `Description:` / `Action:` no hay cadena que leer.

---

### A03 → 3

> Tienes dos beans `Clock` y el arranque no falla. ¿Qué tiene que ser cierto del nombre del
> parámetro del constructor para que no falle?

**⏱️ 30 segundos.** Que el nombre del parámetro **coincida exactamente con el nombre de uno de
los dos beans** —`clock` o `utcClock`—, porque ese es el último desempate del contenedor. Las
otras dos formas de que no falle son un `@Primary` en uno de los beans o un `@Qualifier` en el
punto de inyección.

**🗣️ 2 minutos.** El algoritmo, en orden:

```text
1. buscar por TIPO          todos los beans asignables al tipo del punto de inyección
2. ¿uno solo?               → resuelto
3. ¿varios?                 → filtrar por @Qualifier
4. ¿sigue habiendo varios?  → ¿alguno es @Primary?
5. ¿sigue habiendo varios?  → desempatar por NOMBRE (el del campo o el del parámetro)
6. ¿sigue habiendo varios?  → NoUniqueBeanDefinitionException
```

El corolario incomoda y es exacto: **renombrar un parámetro puede romper —o arreglar— un
arranque**, sin tocar una sola anotación. Es un cambio invisible en una revisión de código y
es justo por lo que el fallo aparece en el refactor de otro.

**🔬 El detalle.** Con un único candidato el nombre **da exactamente igual**, que es lo que
hace creer a medio mundo que `@Autowired` inyecta por nombre; inyecta por tipo y el nombre es
el último desempate. La higiene es poner `@Primary` en el momento de declarar el segundo bean
de un tipo, no cuando aparece el tercer consumidor. Y si de verdad los quieres todos,
`List<Clock>` los toma sin desempate. En el mensaje del `FailureAnalyzer`, `Parameter 2 of
constructor` cuenta **desde cero**.

---

### A03 → 4

> Tu `?limit=500` devuelve `500` en vez de `400` y el parámetro lleva `@Max(100)`. ¿Cuál es
> la causa exacta y cuál es la corrección, en una línea?

**⏱️ 30 segundos.** La causa es el **`@Validated` de nivel de clase en el controller**: devuelve
la validación de parámetros al camino de AOP, el proxy lanza `ConstraintViolationException`
—de Jakarta, desconocida para MVC— y sale `500`. La corrección es borrar ese `@Validated` de
la clase, y su import.

**🗣️ 2 minutos.** Los tres caminos posibles:

```text
controller sin @Validated  → valida MVC      → HandlerMethodValidationException → 400
controller con @Validated  → valida el proxy → ConstraintViolationException     → 500
@Service   con @Validated  → valida el proxy → ConstraintViolationException     → 500
```

Desde **Spring Framework 6.1** el controller valida por sí mismo los parámetros de método y
`DefaultHandlerExceptionResolver` mapea el fallo a `400` sin que hagas nada; la reference lo
pide con todas las letras: *"In order to take advantage of the Spring MVC built-in support for
method validation added in Spring Framework 6.1, you need to remove the class level
`@Validated` annotation from the controller"*. Fuera del controller `@Validated` sigue siendo
obligatoria, porque en un `@Service` no hay MVC que valide por ti: solo hay proxy.

**🔬 El detalle.** La sobregeneralización que hay que desactivar es *"`@Validated` habilita la
validación de parámetros en un controller"*: no la habilita, **la degrada**, y te convierte un
400 en un 500. Se confirma con `--logging.level.org.springframework.web=DEBUG`: en el caso del
500 **no aparece ninguna excepción de MVC** en el log y el cuerpo es el `/error` genérico de
Boot con `"error":"Internal Server Error"`; en el caso del 400 el log nombra
`org.springframework.web.method.annotation.HandlerMethodValidationException` resuelta por
`DefaultHandlerExceptionResolver`. Quien creó el proxy que se traga el 400 fuiste tú.

---

### A03 → 5

> Distingue `HttpMessageNotReadableException` de `MethodArgumentNotValidException` diciendo
> en qué momento del recorrido de la petición se lanza cada una.

**⏱️ 30 segundos.** `HttpMessageNotReadableException` se lanza **mientras el converter lee el
body**: el converter sí se eligió, corrió y murió. `MethodArgumentNotValidException` se lanza
**después**, con el objeto ya construido, cuando Bean Validation lo rechaza. Las dos dan `400`.

**🗣️ 2 minutos.** El recorrido entero, por orden:

```text
415  HttpMediaTypeNotSupportedException     HandlerMapping, antes de elegir converter
400  HttpMessageNotReadableException        el converter corrió y falló leyendo
400  MethodArgumentNotValidException        el body se deserializó y lo rechazó Bean Validation
406  HttpMediaTypeNotAcceptableException    no hay representación que escribir
```

La primera cubre también el body ausente (`Required request body is missing`) y un
`@PathVariable` que no convierte al tipo declarado; su mensaje es de Jackson y trae el carácter
y la posición. La segunda trae la lista completa de `FieldError` —campo, valor rechazado, código
de la restricción—, que es la materia prima del `ProblemDetail` útil y del `422` cuando la
sintaxis era correcta y la semántica no.

**🔬 El detalle.** Las dos se ven en el log con `org.springframework.web` en `DEBUG`, en una
línea `Resolved [...]` por excepción que un `HandlerExceptionResolver` reconoció; si tu
excepción **no** sale ahí, nadie la tradujo y ese es el 500 que miente. Y un aviso de versión:
Boot 4 mueve el baseline a Jackson 3, cuyo paquete raíz ya no es `com.fasterxml.jackson` sino
`tools.jackson`. El código sigue siendo 400 y la excepción de Spring sigue siendo
`HttpMessageNotReadableException`, pero **cambia el nombre de la excepción causa** que verás en
el log, y con él cualquier `grep` de tu runbook o cualquier `catch` escrito contra el tipo de
Jackson.

---

### A03 → 6

> La API devuelve un `422` impecable y la fila quedó grabada. Enumera las tres variantes que
> producen eso y di cuál de las tres **sí** deja rastro en el log del `TransactionInterceptor`.

**⏱️ 30 segundos.** A: self-invocation. B: excepción capturada dentro del método. C: método
`private`. La que deja rastro **sobre tu clase** es la **B**, porque ahí el proxy sí corrió; en
A y C la llamada nunca pasó por el proxy. Y B es además la única que devuelve un `200`
engañoso en vez del `422`.

**🗣️ 2 minutos.**

| Variante | ¿Corre el interceptor? | ¿Qué devuelve la API? | ¿Qué dice el `SELECT`? |
|---|---|---|---|
| A — self-invocation | ❌ | `422` correcto | filas grabadas |
| B — excepción capturada dentro | ✅ | `200` engañoso | filas grabadas |
| C — método `private` | ❌ | `422` correcto | filas grabadas |

En B el proxy corrió, pero el `catch` se comió la excepción antes de que la viera: para el
interceptor el método terminó perfectamente, **commit**. Y las filas se graban aunque no haya
transacción de negocio porque `SimpleJpaRepository` —la implementación que Spring Data
genera— **está anotada con `@Transactional`**: cada `save()` abre y confirma la suya. Lo peor
de los dos mundos, cada escritura atómica por separado y ninguna en conjunto.

**🔬 El detalle.** Con `logging.level.org.springframework.transaction.interceptor=TRACE` el log
**nunca sale vacío**, y ahí está la trampa: siempre verás líneas de `SimpleJpaRepository.save`.
**La pregunta correcta no es si corrió el interceptor, es sobre qué clase corrió**; si no
aparece ni una línea con `InventoryService.record`, no envolvió tu método. La evidencia que
vale primero es el `SELECT`. La corrección es mover `@Transactional` al límite real de la
unidad de trabajo, quitar el `private` y, en B, `throw e` tras registrar o
`TransactionAspectSupport.currentTransactionStatus().setRollbackOnly()` si el flujo tiene que
seguir. Y la prevención es un test que afirme sobre **la base** —mismo `count(*)` antes y
después— porque el código de estado era correcto en las tres. La variante hermana que sí avisa
es `UnexpectedRollbackException`: ahí un método interno marcó la transacción como
`rollback-only` y el commit de fuera revienta.

---

### A03 → 7

> Ves `HikariPool-1 - Connection is not available, request timed out` y Postgres está al 0 %
> de CPU. ¿Qué consulta corres contra la base y qué esperas encontrar?

**⏱️ 30 segundos.** `pg_stat_activity` agrupado por `state`, y lo que esperas es
**`idle in transaction`**: transacciones abiertas con la base sin ejecutar nada. El recurso
agotado es tuyo, no suyo.

**🗣️ 2 minutos.**

```bash
docker exec -i inv-lab-postgres-1 psql -U inv_lab -d inv_lab -c \
  "SELECT state, count(*), max(now() - state_change) FROM pg_stat_activity
   WHERE datname = 'inv_lab' GROUP BY state"
```

- **`idle in transaction`** significa que hay transacción abierta y la base espera a un cliente
  que es un hilo de Tomcat bloqueado pidiendo una **segunda** conexión.
- Cero consultas, cero disco, CPU al 0 %: **si tu única gráfica es la de la base, el incidente
  es invisible**.

La segunda evidencia es del lado de Hikari, con
`logging.level.com.zaxxer.hikari.pool.HikariPool=DEBUG`:
`HikariPool-1 - Pool stats (total=2, active=2, idle=0, waiting=6)`. **`waiting=6` cierra el
caso**, y lo mismo está en `/actuator/metrics/hikaricp.connections.pending`.

**🔬 El detalle.** El caso del lab es un deadlock de pool: un método con
`@Transactional(propagation = REQUIRES_NEW)` llamado desde otra transacción consume **dos
conexiones a la vez**, porque suspender no libera la conexión. La aritmética, que es lo que se
dice en una entrevista: con `maximum-pool-size = N`, un camino que necesita dos conexiones
simultáneas se bloquea en cuanto hay **N peticiones concurrentes** por ahí —las N toman la
primera y ninguna consigue la segunda—, de donde sale la regla **`pool ≥ concurrencia ×
conexiones por request`**. Fíjate en lo que **no** hay en el stack trace: una sola línea de tu
código, y por eso la primera reacción de todo el mundo es "el pool es pequeño". `Transient` es
aquí una promesa mentirosa: reintentar consume otra conexión y empeora el problema. Los otros
dos candidatos para el mismo mensaje son una llamada de red lenta dentro de la transacción y un
`open-in-view: true` con clientes lentos.

---

### A03 → 8

> *"`@Transactional` solo funciona en métodos `public`"*. Nombra la simplificación y da la
> versión precisa para Spring Framework 6.2.

**⏱️ 30 segundos.** La simplificación es confundir *"que el proxy pueda sobrescribir el
método"* con *"que el método sea `public`"*. En Spring Framework 6.2, con proxies **CGLIB** —el
default de Boot desde 2.0— la anotación se respeta también en métodos **`protected` y
package-private**. Lo único que **nunca** funciona es `private`.

**🗣️ 2 minutos.** La frase completa tiene dos mitades, y el modificador es la menos
importante: *"no es cuestión de `public`, es cuestión de si el proxy puede sobrescribir el
método y de si la llamada entra desde fuera del bean"*. Con proxies **JDK** no funciona nada
que no esté declarado en la interfaz, y un método o una clase `final` tampoco se pueden
sobrescribir. Y aunque el modificador sea el correcto, una llamada desde la misma clase no pasa
por el proxy y la anotación queda como documentación de una intención que no se cumple.

**🔬 El detalle.** Los seis silencios de `@Transactional`: self-invocation, `private`, `final`,
llamada desde `@PostConstruct`, excepción capturada dentro —los cinco de proxy— y el sexto, de
otra familia: importar `jakarta.transaction.Transactional` en vez del de Spring. Ese **sí abre
la transacción** —Spring traduce su `TxType` a la propagación equivalente— pero pierde
atributos: no hay `readOnly`, ni `isolation`, ni `timeout`, y `rollbackFor`/`noRollbackFor` se
llaman `rollbackOn`/`dontRollbackOn`. Te enteras cuando el compilador rechaza el atributo que
fuiste a añadir, o nunca. Los seis se diagnostican con la misma línea:
`logging.level.org.springframework.transaction.interceptor=TRACE`, y comprobando **sobre qué
clase** corrió el interceptor.

---

### A03 → 9

> Tu `@Cacheable` no registra ni `hit` ni `miss`. ¿Qué descarta ese dato y qué lo distingue
> de una caché mal configurada?

**⏱️ 30 segundos.** Descarta la caché entera: la clave, el TTL, el proveedor. **Una caché que
falla registra `miss`; una caché a la que nadie llama no registra nada**, así que el
`CacheInterceptor` nunca corrió y el problema es el proxy — casi siempre self-invocation.

**🗣️ 2 minutos.** El caso típico es un método que recorre una lista y llama al método cacheado
**de su propia clase** —`this::valuation`, o `this.valuation(...)`, que en bytecode es lo
mismo—: la llamada no sale del bean, no entra por el proxy y para la caché esas invocaciones no
existieron. Las dos evidencias son `/actuator/metrics/cache.gets`, donde no sube ni `hit` ni
`miss`, y un contador propio de llamadas al repositorio antes y después, que es lo que muestra
el `antes=1 despues=4` del apéndice. La corrección es la terna de siempre: sacar el método
cacheado a otro bean o entrar por el proxy.

**🔬 El detalle.** Lo que hace que esto sobreviva a la revisión de código es que **el resultado
es correcto en los dos casos**: solo cambia cuántas veces fuiste a la base. Por eso el test no
afirma sobre el valor devuelto sino sobre el contador, llamando dos veces. Y la lección
general: sin hit ratio publicado, cualquier afirmación sobre la caché es una suposición
([`17` §10](17-cache.md#10--sin-hit-ratio-esto-es-una-suposición)). El mismo mecanismo explica
el `@Timed` que no aparece en las métricas: es un aspecto sobre un proxy, y además necesita
`management.observations.annotations.enabled` en `true` y `spring-boot-starter-aop`.

---

### A03 → 10

> ¿Por qué `DefaultSerializer requires a Serializable payload` no aparece en el arranque sino
> en la primera petición, y por qué `implements Serializable` es la corrección equivocada?

**⏱️ 30 segundos.** Porque **nada en el contexto sabe qué tipos vas a cachear**: el serializador
solo actúa cuando hay un valor que escribir en Redis, así que el arranque es limpio y
`/actuator/health` responde `200`. Y `implements Serializable` es la corrección equivocada
justamente porque **funciona**: te ata al formato binario de la serialización JDK.

**🗣️ 2 minutos.** El culpable no es Redis ni tu consulta, es el serializador:
`RedisCacheConfiguration.defaultCacheConfig()` usa `JdkSerializationRedisSerializer` para los
valores, y la serialización de Java exige `java.io.Serializable`; tu `record` no lo implementa.
Con Caffeine el objeto se guardaba en memoria y nadie lo serializaba, así que el fallo aparece
el día que cambias de proveedor. La corrección es un `RedisCacheManagerBuilderCustomizer` que
serialice los valores con `GenericJackson2JsonRedisSerializer`, con su TTL y su prefijo.

**🔬 El detalle.** Lo que se paga con `implements Serializable` llega meses después: el binario
queda atado a la clase y a su `serialVersionUID`, así que el día que añadas un campo y
despliegues de forma gradual, la instancia vieja lee lo que escribió la nueva y falla al
deserializar — **la caché llena de bombas que explotan una por una**, y con TTL largo durante
horas. Al diagnosticar, lo que nunca se recorta del trace es la línea del `Caused by:`, que es
la que trae el nombre de tu clase; la de arriba solo dice `SerializationFailedException`.

---

### A03 → 11

> `CallNotPermittedException` y `BulkheadFullException` tienen algo en común que cambia por
> completo dónde buscas el problema. ¿Qué es?

**⏱️ 30 segundos.** Que **las lanza tu propio proceso**, no el proveedor: son tus decoradores de
Resilience4j haciendo exactamente lo que les pediste. No hay que buscar en la red ni en el otro
servicio, sino en tu configuración y tus métricas.

**🗣️ 2 minutos.** La primera dice que el circuito está abierto y falla de inmediato sin tocar la
red, que es lo que salva tus hilos y le da aire al proveedor; la segunda, que hay más llamadas
concurrentes que permisos en el bulkhead, que existe para que un proveedor lento no se coma
todos tus hilos. En los dos casos no hay nada que corregir en el mecanismo: lo que hay que
corregir es la **traducción al cliente**, con un `@ExceptionHandler` que devuelva `503` —y un
`Retry-After` en el caso del circuito—, porque sin él salen como `500` y un `500` invita a
reintentar justo cuando menos quieres. El estado se lee en `/actuator/circuitbreakers` y la
historia completa en `/actuator/circuitbreakerevents/supplier`.

**🔬 El detalle.** Dos lecturas que confunden en ese endpoint: `slowCallRate: -1.0%` no es un
porcentaje negativo, es "todavía no hay datos suficientes"; y `bufferedCalls` cuenta **un fallo
por cada intento del retry**, no uno por petición, así que con un retry dentro del breaker el
circuito abre mucho antes de lo que esperas — el **orden en que se apilan los decoradores
cambia el resultado**. El bulkhead se comprueba con aritmética: `grep -c 'BulkheadFullException'
app.log` contra el número de peticiones concurrentes, que con tres permisos y diez peticiones
son siete rechazos. Y el fallo hermano que no lanza nada es el `fallbackMethod` mal escrito: un
`WARN … No fallback method match found` por invocación, incluso cuando la petición termina en
`200`.

---

### A03 → 12

> Un target de Prometheus está en `down` con `connection refused`. ¿Qué descarta ese mensaje
> frente a un `context deadline exceeded`?

**⏱️ 30 segundos.** `connection refused` es *"alguien contestó que no hay nadie escuchando
ahí"*: descarta la red, el DNS y la lentitud, y te deja binding, puerto o firewall.
`context deadline exceeded` es lo contrario, *"nadie contestó"*: red, DNS o un proceso demasiado
lento.

**🗣️ 2 minutos.** Se lee con `curl -s localhost:9090/api/v1/targets` y mirando `lastError`.
El caso del lab es `management.server.address: 127.0.0.1`, que liga el conector de management al
loopback de tu máquina: **un contenedor no es tu loopback**, llega por la interfaz del gateway
de Docker y el sistema operativo rechaza la conexión antes de que Tomcat se entere. Por eso el
error parece imposible —tu `curl` desde la terminal sigue funcionando—. La corrección es
`management.server.address: 0.0.0.0` **en el perfil `local`**; el `prod` simulado conserva el
loopback.

**🔬 El detalle.** Hay una tercera forma del mismo `down` y es la más tonta: olvidar
`metrics_path` en el scrape, porque el default de Prometheus es `/metrics` y el endpoint está en
`/actuator/prometheus`. Da un target caído con un **`404` como último error**, y se distingue de
los otros dos solo leyendo `lastError` entero — de ahí que el procedimiento sea siempre leer el
mensaje completo antes de tocar nada. De la línea del error, la dirección IP es lo único que
cambia de máquina a máquina.

---

## Apéndice A04 — Migración 3.5 → 4.x

### A04 → 1

> ¿Por qué Spring Boot 3.5 tiene soporte comercial hasta 2032 y Boot 4.0 solo hasta 2027, si
> 3.5 es la versión más vieja de las dos?

**⏱️ 30 segundos.** Porque 3.5 es **la última minor de la major 3**, y la última minor de una
major cobra cinco años extra de soporte comercial. 4.0 es una minor intermedia de la major 4 y
se corta un año después del fin de su soporte OSS.

**🗣️ 2 minutos.** El calendario tiene dos reglas que se aplican a todas las líneas. La primera:
**trece meses de parches OSS** desde la GA, redondeados a fin de mes —trece y no doce, porque el
mes extra es el solape que te deja migrar—. La segunda: la última minor de cada major se declara
puerta de salida de esa major y recibe cinco años de soporte comercial encima. Por eso 2.7 llega
a 2029 y 3.5 llega a **2032**, mientras que 4.0 se queda en 2027-12-31. No es que 3.5 sea
"mejor": es que Broadcom mantiene abierta la puerta de salida para quien paga.

**🔬 El detalle.** En banca esto cambia la conversación entera: un servicio en 3.5 con soporte
comercial está soportado hasta 2032 y no es deuda urgente; el mismo servicio en **3.4**, que es
una minor intermedia, caducó su soporte comercial en diciembre de 2026 y sí lo es. La pregunta
correcta no es "¿estás en la última?" sino **"¿estás en una línea con soporte, y quién lo
paga?"**. Los datos no se citan de memoria: salen de `https://api.spring.io/projects/spring-boot/generations`,
que es el JSON del que la página web pinta su tabla, y el apéndice trae el `curl` que lo
imprime. Detalle de método: `api.spring.io` responde `200` a un `GET` y `401` a un `HEAD`, así
que verificarlo con `curl -I` lo reporta como caído sin estarlo.

---

### A04 → 2

> "Spring Boot 4 exige Java 21": corrige la afirmación y di con qué comando lo comprobarías sin
> abrir la documentación.

**⏱️ 30 segundos.** El mínimo de Boot 4 es **Java 17**, igual que en 3.5. Se comprueba leyendo
el `major version` del bytecode de `spring-core`: `javap -v` sobre una clase del jar de
`spring-core-7.0.9` da `major version: 61`, que es Java 17.

**🗣️ 2 minutos.** El comando completo son tres líneas y no depende de ninguna release note:

```bash
cd /tmp && curl -sO https://repo1.maven.org/maven2/org/springframework/spring-core/7.0.9/spring-core-7.0.9.jar
unzip -o -q spring-core-7.0.9.jar 'org/springframework/core/SpringVersion.class'
javap -v org/springframework/core/SpringVersion.class | grep 'major version'
```

- **`javap -v`** desensambla el `.class` y muestra su cabecera, donde vive la versión de bytecode
  con la que se compiló.
- **La correspondencia es fija:** 61 → 17, 62 → 18, 65 → 21. Spring Framework 7 se compila a 17,
  así que **17 es el piso**.

Que este curso fije Java 21 es una decisión del curso —por los virtual threads de
[`12`](12-reactivo-bloqueante-y-virtual-threads.md)—, no un requisito del framework.

**🔬 El detalle.** El dato que produce la respuesta equivocada está en el propio jar: el
`Created-By` del `MANIFEST.MF` dice `25.0.4`, que es **el JDK con el que se construyó el
artefacto**, no el mínimo que exige para ejecutarse. Son dos cosas distintas y confundirlas es
justo el origen del "exige 21". Lo que sí sube de piso en Boot 4 es lo de abajo: Servlet 6.0 →
**6.1** con Tomcat 10.1 → **11**, Jakarta EE 10 → **11** —de ahí que Hibernate Validator salte de
8 a 9— y **Undertow desaparece** como servidor embebido soportado por ser incompatible con
Servlet 6.1. El paquete `jakarta.servlet` se queda donde estaba.

---

### A04 → 3

> ¿Qué diferencia práctica hay entre que `spring-boot-starter-web` esté **deprecado** y que
> estuviera **eliminado**, para alguien que acaba de subir la versión del parent?

**⏱️ 30 segundos.** Deprecado significa que **el build sigue resolviendo y compilando**: tienes
deuda, no una parada. Eliminado sería un fallo de resolución de Maven en el primer `mvnw
verify`, ruidoso e inmediato. Boot 4 lo deprecó en favor de `spring-boot-starter-webmvc`; no lo
eliminó.

**🗣️ 2 minutos.** La fuente más corta para este dato es el `<description>` del propio artefacto
publicado, que lo declara en Maven Central:

```bash
curl -s https://repo1.maven.org/maven2/org/springframework/boot/spring-boot-starter-web/4.1.1/spring-boot-starter-web-4.1.1.pom \
  | grep '<description>'
```

```text
  <description>Starter for building web, including RESTful, applications using Spring MVC.
  Uses Tomcat as the default embedded container (deprecated in favor of spring-boot-starter-webmvc)</description>
```

El viejo arrastra las mismas cinco dependencias que el nuevo. Si en una entrevista te dicen "en
Boot 4 el starter web ya no existe", la versión precisa es **"está deprecado en favor de
`spring-boot-starter-webmvc`, y el POM lo dice en su propia descripción"**.

**🔬 El detalle.** La asimetría muerde en la otra dirección: un `pom.xml` copiado de 4.x a 3.5
falla al resolver, porque `spring-boot-starter-webmvc` **no existe** en la línea 3. Y hay un
renombre que sí cambia de significado aunque conserve el nombre: `spring-boot-starter-test`
sigue trayendo JUnit, AssertJ, Mockito y Hamcrest, pero **ya no arrastra la infraestructura de
test de cada tecnología** —`@WebMvcTest` vive en `spring-boot-starter-webmvc-test`,
`@WithMockUser` en `spring-boot-starter-security-test`—. Ahí no hay error de resolución: hay un
test verde que no prueba nada (entrada 10). El escalón intermedio existe y se llama
`spring-boot-starter-classic` / `spring-boot-starter-test-classic`, que arrastran
`spring-boot-autoconfigure-classic` y reagrupan todo como antes; es un paso de migración con
fecha, no un destino.

---

### A04 → 4

> Migras a Jackson 3 y tu `record ItemResponse` está lleno de `@JsonProperty`. ¿Cuántos de esos
> imports tienes que tocar, y por qué?

**⏱️ 30 segundos.** **Ninguno.** Las anotaciones de Jackson no cambiaron de paquete: siguen en
`com.fasterxml.jackson.annotation`. Ese `record` compila en Boot 4 sin tocar una línea.

**🗣️ 2 minutos.** Lo que se movió a `tools.jackson` es la **maquinaria**: el `ObjectMapper` pasa
de `com.fasterxml.jackson.databind` a `tools.jackson.databind`, y con él los módulos y las
excepciones. Las anotaciones se quedaron a propósito, porque son la API que aparece en el código
de todo el mundo y moverlas habría roto cada DTO del ecosistema. Se comprueba en el BOM de
Jackson 3, que las gestiona bajo el `groupId` viejo:

```bash
curl -s https://repo1.maven.org/maven2/tools/jackson/jackson-bom/3.1.5/jackson-bom-3.1.5.pom \
  | grep -B1 -A2 'jackson-annotations'
```

```text
      <dependency>
        <groupId>com.fasterxml.jackson.core</groupId>
        <artifactId>jackson-annotations</artifactId>
        <version>${jackson.version.annotations}</version>
      </dependency>
```

*"Jackson 3 te cambia todos los imports"* es la sobregeneralización, y cuesta tiempo en la
planificación: lo que cambia son los imports de infraestructura —el `ObjectMapper` de tu
`@Configuration`, el `Module` que registrabas a mano, el `catch` de binding—.

**🔬 El detalle.** Dos anotaciones **propias de Boot** sí se renombraron, verificado en el jar
`spring-boot-jackson-4.1.1`: `@JsonComponent` → **`@JacksonComponent`** y `@JsonMixin` →
**`@JacksonMixin`**, ambas siguen en `org.springframework.boot.jackson`. Y la migración admite
dos pasos: Jackson 2 sigue disponible en un módulo deprecado, `spring-boot-jackson2`, porque el
BOM de Boot 4.1.1 importa **los dos** BOM de Jackson —`tools.jackson:jackson-bom:3.1.5` y
`com.fasterxml.jackson:jackson-bom:2.21.5`—.

---

### A04 → 5

> Tu `catch (JsonMappingException e)` deja de compilar en 4.x. ¿Qué tipo lo sustituye y en qué
> paquete vive?

**⏱️ 30 segundos.** Lo sustituye **`DatabindException`**, en **`tools.jackson.databind.exc`**.
Es la raíz de la jerarquía de errores de binding de Jackson 3.

**🗣️ 2 minutos.** El paquete raíz de `databind` se mudó entero de `com.fasterxml.jackson` a
`tools.jackson`, y con él las excepciones: `UnrecognizedPropertyException` está ahora en
`tools.jackson.databind.exc`, y `JsonMappingException` directamente ya no está. Lo que sigue
siendo igual es lo de arriba: en el borde web el cuerpo mal formado se reporta como
`HttpMessageNotReadableException` y la excepción de Jackson es su **causa**, que es el
procedimiento de lectura de [`A03` §5](a03-catalogo-de-errores-y-diagnostico.md#5-️-el-borde-web-el-código-de-estado-que-miente).

**🔬 El detalle.** El fallo de compilación es la parte amable: lo arregla el IDE. Lo que no avisa
es todo lo escrito **fuera del compilador contra el nombre viejo** —un `grep JsonMappingException`
en un runbook, una regla de alerta sobre el log, un filtro de Kibana— que después de migrar deja
de encontrar nada y parece que los errores desaparecieron. Ese es el aviso literal de
[`A03` §5](a03-catalogo-de-errores-y-diagnostico.md#5-️-el-borde-web-el-código-de-estado-que-miente),
y es el tipo de cosa que ninguna herramienta de migración automática toca (entrada 11).

---

### A04 → 6

> ¿Qué significa exactamente que una deprecación de propiedad tenga `"level": "error"` en el
> `spring-configuration-metadata.json`, frente a `"level": "warning"`?

**⏱️ 30 segundos.** `"warning"` significa que la propiedad **sigue enlazándose** y solo se avisa;
`"error"` significa que **ya no se lee**. Una clave con nivel `error` en tu `application.yml` no
configura nada: es una línea muerta que no da error de arranque.

**🗣️ 2 minutos.** El fichero `META-INF/spring-configuration-metadata.json` lo genera el
`spring-boot-configuration-processor` y es el mismo que alimenta el autocompletado del IDE. Cada
propiedad deprecada lleva ahí su nivel, su reemplazo y desde cuándo:

```json
{
  "name": "management.tracing.enabled",
  "deprecated": true,
  "deprecation": {
    "level": "error",
    "replacement": "management.tracing.export.enabled",
    "since": "4.0.0"
  }
}
```

Por eso la distinción no es documental sino de comportamiento, y por eso hay que leerla antes de
dar por buena una migración de `yml`: los renombres de Boot 4 que toca este apéndice
—`management.tracing.enabled`, `spring.data.mongodb.uri` → `spring.mongodb.uri`— son todos de
nivel **`error`**.

**🔬 El detalle.** El nivel también decide qué puede hacer por ti el `spring-boot-properties-migrator`:
escribe un WARN con el reemplazo para toda clave deprecada que encuentre, pero **solo reasigna
en memoria las de nivel `warning`** para que la aplicación arranque. Con una de nivel `error` te
avisa y nada más: el arreglo es tuyo. Y el `"since"` no es decorativo —`"since": "4.0.0"`
confirma que ese cambio entró en 4.0 y no en 4.1, que es lo que te dice si te alcanza saltando
solo a la primera minor de la major—.

---

### A04 → 7

> Renombras `management.tracing.enabled` a `management.tracing.export.enabled` y lo pones en
> `false`. ¿Sigue habiendo `traceId` en tus líneas de log? ¿Por qué?

**⏱️ 30 segundos.** **Sí, sigue habiendo `traceId`.** El renombre separa **instrumentar** de
**exportar**: `export.enabled=false` deja de mandar los spans a Zipkin o al collector, pero la
instrumentación sigue creándolos, así que el `traceId` sigue en el MDC y en el patrón de log.

**🗣️ 2 minutos.** En 3.5 ese único interruptor apagaba las dos cosas a la vez, y ese era
justamente el problema: no había forma de conservar la correlación en los logs sin pagar la
exportación. En 4.x son dos decisiones distintas y se escriben distinto. La consecuencia
operativa se lee al revés, y es el diagnóstico útil: **si migras a ciegas y el `traceId`
desaparece de los logs, mira esta propiedad antes que el `logging.pattern`**.

**🔬 El detalle.** La trampa que viene con el renombre es que la clave vieja es de nivel `error`
(entrada 6): un `management.tracing.enabled=false` heredado del `yml` de 3.5 **no apaga nada** en
Boot 4 y tampoco rompe el arranque, así que te quedas exportando trazas que creías apagadas.
Quien lo confirme a mano puede leerlo del propio artefacto, que es la misma fuente que consume el
migrator:

```bash
cd /tmp && curl -sO https://repo1.maven.org/maven2/org/springframework/boot/spring-boot-micrometer-tracing/4.1.1/spring-boot-micrometer-tracing-4.1.1.jar
unzip -p spring-boot-micrometer-tracing-4.1.1.jar META-INF/spring-configuration-metadata.json \
  | python3 -c 'import sys,json;[print(json.dumps(p,indent=2)) for p in json.load(sys.stdin)["properties"] if p["name"]=="management.tracing.enabled"]'
```

- **`unzip -p`** vuelca una entrada del jar a la salida estándar sin extraerla a disco.
- **El `python3 -c`** filtra el JSON por el nombre de la propiedad; el fichero tiene cientos.

En el mismo salto suben Micrometer 1.15.12 → 1.17.1 y Micrometer Tracing 1.5.12 → 1.7.1, y
`spring.dao.exceptiontranslation.enabled` pasa a `spring.persistence.exceptiontranslation.enabled`.

---

### A04 → 8

> En Spring Batch 6, `@EnableBatchProcessing` ya no basta. ¿Qué anotación hay que acompañarla y
> qué decisión representa?

**⏱️ 30 segundos.** **`@EnableJdbcJobRepository`**, y representa **dónde persiste el
`JobRepository`**. En Batch 5 el almacenamiento JDBC era el único y estaba implícito; en Batch 6
es una decisión que se escribe.

**🗣️ 2 minutos.** Quedan así las dos, y hacen cosas distintas:

```java
// Batch 6: ya no basta con @EnableBatchProcessing
@Configuration
@EnableBatchProcessing              // activa la infraestructura de Batch
@EnableJdbcJobRepository            // elige DÓNDE persiste el JobRepository
class BatchConfig {
    // el transaction manager pasa a ser opcional: si no declaras uno,
    // Batch usa el que encuentre en el contexto
}
```

- **`@EnableBatchProcessing`** sigue registrando `JobRepository`, `JobOperator` y el resto de la
  infraestructura como beans: hace lo mismo que antes.
- **`@EnableJdbcJobRepository`** elige el almacenamiento, y tiene hermana:
  `@EnableMongoJobRepository`. Las dos viven en
  `org.springframework.batch.core.configuration.annotation`.

**🔬 El detalle.** El otro relajamiento es el `transaction manager`, que pasó a **opcional** en
`@EnableBatchProcessing`: en Batch 5 había escenarios donde tocaba nombrarlo con
`transactionManagerRef`, y ahora Batch toma el que encuentre en el contexto. Eso **no** relaja la
regla de fondo de [`22` §8](22-spring-batch.md#8-️-el-writer-falla-a-la-mitad-del-chunk-el-puente-con-16):
el chunk sigue siendo la unidad transaccional, y un writer que falla a la mitad sigue deshaciendo
el chunk entero. El modelo —job, step, chunk, `JobRepository` con sus seis tablas de
[`22` §4](22-spring-batch.md#4--el-jobrepository-seis-tablas-y-ningún-truco)— no cambió en el
salto de major: lo que cambió es quién se declara y quién se infiere.

---

### A04 → 9

> `JobLauncher` y `JobExplorer` siguen en el jar de Batch 6. ¿Significa eso que puedes seguir
> usándolos, y qué clase absorbe a cada uno?

**⏱️ 30 segundos.** Sí compilan, pero están **`@Deprecated`**: son un puente, no una opción. El
`JobLauncher` lo absorbe **`JobOperator`** —lanzar— y el `JobExplorer` lo absorbe
**`JobRepository`** —consultar—.

**🗣️ 2 minutos.** Que la deprecación es real y no una nota de javadoc se ve en el bytecode, no en
la documentación:

```bash
javap -v org/springframework/batch/core/launch/JobLauncher.class | grep -c 'Deprecated: true'
```

```text
1
```

- **`Deprecated: true` es un atributo del `.class`**, que el compilador escribe a partir de
  `@Deprecated`. Si está ahí, tu build va a emitir el warning de deprecación.

`JobExplorer` además se movió de `…batch.core.explore` a `…batch.core.repository.explore`, así
que ese sí te rompe el import aunque solo quieras seguir usándolo deprecado.

**🔬 El detalle.** La lectura de diseño es la que conviene decir en voz alta: Batch 6 reduce la
superficie de cuatro colaboradores a dos, y el reparto queda limpio —`JobOperator` para operar
(lanzar, parar, reiniciar) y `JobRepository` para el estado—, que es lo que el curso ya describe
en [`22` §10](22-spring-batch.md#10--lanzarlo-probarlo-y-vigilarlo) haciendo las dos cosas con
las piezas viejas. La identidad de la `JobInstance` por `JobParameters` de
[`22` §5](22-spring-batch.md#5--jobparameters-por-qué-no-puedes-relanzar-lo-mismo-dos-veces)
sobrevive intacta al cambio de major: relanzar con los mismos parámetros sigue fallando igual.

---

### A04 → 10

> Tu suite sigue verde después de migrar a 4.x, pero sospechas de los tests. ¿Cuál es el fallo
> silencioso más probable y en qué parte del log lo confirmas?

**⏱️ 30 segundos.** Que **el slice dejó de aplicarse**: `spring-boot-starter-test` ya no arrastra
la infraestructura de test de cada tecnología, así que un `@WebMvcTest` sin
`spring-boot-starter-webmvc-test` compila, corre y pasa, pero no está probando lo que crees. Se
confirma en **el log de arranque de esa clase de test**: el contexto que levanta y el tiempo que
tarda no son los de un slice.

**🗣️ 2 minutos.** Es el cambio de la §5 del apéndice visto desde el lado que duele. Un starter
eliminado da fallo de resolución y un import movido da fallo de compilación: los dos son ruidosos
y baratos. Este no da ninguno de los dos, porque la anotación sigue en el classpath y lo que
falta es quien la aplica. El resultado es la peor combinación posible: **suite verde y cobertura
imaginaria**. El mismo patrón se repite en Security: `@WithMockUser` y `@WithUserDetails`
necesitan `spring-boot-starter-security-test`, y sin él la anotación está pero el usuario no se
pone, de modo que el test de autorización pasa sin autorizar nada.

Cómo se confirma, en orden:

- **El tiempo de arranque de la clase de test.** Un slice arranca un contexto recortado en
  cientos de milisegundos; si esa clase tarda como un `@SpringBootTest`, no hay slice.
- **Qué se levantó.** Si en el log del test aparece el arranque del contexto completo —el
  servidor, los beans de datos, la infraestructura que el slice debía dejar fuera— la anotación
  no se está aplicando.
- **Comparar antes y después.** Guardar el tiempo de arranque de cada clase de test antes de
  migrar y compararlo después es la comprobación más barata que existe para esto, y es la línea
  del checklist de la §15 del apéndice.

**🔬 El detalle.** Conviene separarlo de su primo ruidoso, porque se confunden: en 4.x
`@SpringBootTest` **ya no autoconfigura** `MockMvc`, `WebTestClient` ni `TestRestTemplate`, y hay
que añadir `@AutoConfigureMockMvc`, `@AutoConfigureRestTestClient` o
`@AutoConfigureTestRestTemplate`. Si no lo haces, el fallo es un `NoSuchBeanDefinitionException`
al inyectar —el de [`A03` §3](a03-catalogo-de-errores-y-diagnostico.md#3--el-contexto-que-no-arranca)
con otra causa—, y ese te avisa a gritos. El silencioso es solo el del slice. Lo que en cambio
**no** tienes que arreglar si seguiste este curso: `@MockBean` y `@SpyBean` se eliminaron —el
paquete `org.springframework.boot.test.mock.mockito` ya no está en `spring-boot-test-4.1.1.jar`—
y el reemplazo, `@MockitoBean` y `@MockitoSpyBean` de
`org.springframework.test.context.bean.override.mockito`, es exactamente el que enseña
[`24` §5](24-testing.md#5--mockitobean-y-mockitospybean-sustituir-un-bean-no-un-objeto). Los
imports de los slices sí se mueven, a la raíz `org.springframework.boot.<módulo>.test`
—`@WebMvcTest` a `…boot.webmvc.test.autoconfigure`, `@DataJpaTest` a
`…boot.data.jpa.test.autoconfigure`—, mientras que `@SpringBootTest` se queda en
`…boot.test.context`.

---

### A04 → 11

> Un compañero propone correr OpenRewrite y dar la migración por hecha. Nombra dos cosas
> concretas de este apéndice que la herramienta no resuelve.

**⏱️ 30 segundos.** Dos, por orden de peligro: **los tests que siguen verdes porque el slice dejó
de aplicarse** —ninguna herramienta te avisa de un test que pasa— y **lo semántico**, como un
`management.tracing.enabled=false` cuyo renombre la recipe hace, pero entender si querías apagar
también la instrumentación no.

**🗣️ 2 minutos.** OpenRewrite automatiza bien lo mecánico y masivo, que además es la mayor parte
del trabajo en un monolito: los imports de test, la sustitución de `@MockBean` por
`@MockitoBean`, añadir los `@AutoConfigure*` que pasaron a ser obligatorios, el cambio de
starters y el renombre de propiedades. Lo que deja para ti son cuatro cosas: **las decisiones**
—quedarse en `spring-boot-starter-classic` o salir de él es de equipo—, **lo semántico**, **tu
código de integración con librerías de terceros** que a su vez migraron, y **los tests verdes**.
Se corre en una rama, primero en `dryRun`, y el `rewrite.patch` se lee entero y se revisa como
cualquier PR.

**🔬 El detalle.** Dos apuntes de higiene. Primero: OpenRewrite es **de la comunidad, no de
Spring** —es la única herramienta del apéndice que no publica VMware/Broadcom—, así que su
documentación y su soporte juegan en otra liga que la guía oficial de migración. Segundo: la
forma en que su documentación publica el comando usa `RELEASE` como versión del artefacto de
recipes, que es exactamente lo que la guía de estilo del curso prohíbe; en tu build se fija la
versión exacta verificada, igual que con cualquier dependencia fuera del BOM. Y su hermano de
alcance limitado es el `spring-boot-properties-migrator`: solo ve lo declarado como deprecación
con reemplazo en los metadatos, no ve propiedades que cambiaron de significado sin cambiar de
nombre, ni claves de tus propios `@ConfigurationProperties`, ni nada fuera del `Environment`.

---

### A04 → 12

> Estás migrando un servicio de Boot 2.7. ¿Por qué no se salta directo a 4.x, y cuáles son los
> dos saltos?

**⏱️ 30 segundos.** Porque la guía oficial de migración a 4.0 exige estar primero en la **última
3.5.x** y con las deprecaciones resueltas. Los dos saltos son **2.7 → 3.5** y **3.5 → 4.x**: dos
subidas, dos despliegues, dos rondas de pruebas.

**🗣️ 2 minutos.** La razón es de diagnóstico, no de ceremonia: saltarse el escalón mezcla el
renombre de `javax`, el de starters y el de Jackson en un mismo build roto, y ya no sabes qué
rompió qué. Las cuatro piezas del primer salto son conocidas:

```text
javax.*  →  jakarta.*                              Jakarta EE 9 renombró el namespace
WebSecurityConfigurerAdapter                       eliminado: Security 6 configura por bean
antMatchers / mvcMatchers  →  requestMatchers      unificación del matcher
spring.factories  →  AutoConfiguration.imports     catálogo de autoconfiguración nuevo
```

Y hay una asimetría que conviene nombrar en entrevista: **la migración que más se pregunta en
banca es esta primera, no la de 4.x**. Hay muchísimo servicio en 2.7 —con soporte comercial hasta
2029, así que no hay prisa regulatoria— y el salto a 3.x es el que la gente tiene fresco o
pendiente.

**🔬 El detalle.** `javax` → `jakarta` **no es un search-and-replace**: cambia lo que venía de
Jakarta **EE** —`javax.persistence`, `javax.servlet`, `javax.validation`, `javax.annotation`— y
**no** lo que viene de Java **SE**, que se queda igual.

```java
import jakarta.persistence.Entity;           // JPA: sí cambió
import jakarta.validation.Valid;             // Bean Validation: sí cambió
import javax.sql.DataSource;                 // JDK: NO cambió
```

Reemplazar a ciegas rompe el `DataSource` de
[`15` §2](15-datos-jdbc-jpa-mongo-y-redis.md#2--el-datasource-y-hikaricp), y el síntoma es un
fallo de compilación inmediato, que es la parte amable. **La trampa de verdad es la biblioteca de
terceros que nunca sacó versión Jakarta**: ahí no hay migración, hay sustituir la librería, y eso
es trabajo de semanas. El cambio de `spring.factories` a
`META-INF/spring/org.springframework.boot.autoconfigure.AutoConfiguration.imports` solo te afecta
si **publicas** autoconfiguración propia — que en banca pasa más de lo que parece, porque casi
toda plataforma interna tiene su starter corporativo
([`06` §4](06-arranque-y-autoconfiguracion.md#4--dónde-vive-el-catálogo-de-autoconfiguraciones)).

---

