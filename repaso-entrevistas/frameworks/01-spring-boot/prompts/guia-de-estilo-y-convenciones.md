# ✍️ Guía de estilo, tono y convenciones
## Spring Core Refresh — repaso para entrevistas y serie práctica de labs

Esta guía es la fuente de verdad editorial de `repaso-entrevistas/frameworks/01-spring-boot/`. Cualquier
chat que produzca o edite un `.md` de este curso la sigue. Su objetivo es que los
cuarenta y un documentos —veinticuatro capítulos teóricos, la simulación, el solucionario,
diez labs, cuatro apéndices y el README— se lean como escritos por la misma mano y
apunten al mismo lugar: **que el lector pueda explicar y defender una decisión de
diseño con Spring, no que recuerde la lista de anotaciones**.

Desciende de la guía de `repaso-entrevistas/cloud/01-aws/`, comparte con ella tono, pedagogía y
aparato de evaluación, y se aparta en lo que el dominio obliga: aquí no hay factura que
cuidar, hay código que se ejecuta, y el recurso escaso no es el dinero sino el hilo, la
conexión y el arranque.

Si dudas entre dos formas de escribir algo, gana la que le sirva más a alguien que
mañana tiene una entrevista de backend Java y pasado mañana tiene que sostener de
verdad el servicio del que habló.

> **Ajustada a los lineamientos generales de producción de cursos el 2026-10-05**, con el
> curso ya cerrado. Lo que este curso hace distinto de esos valores por defecto está en
> [§13](#13-️-excepciones-declaradas-a-los-lineamientos-generales); lo que no aparece allí se
> hereda tal cual. El verificador del curso es `prompts/verificar-corpus.py` (§12).
>
> **Vigencia:** 2026-10-05.

**Salto rápido:** [1](#1--principio-rector) · [2](#2--tono) · [3](#3-️-idioma-y-forma-de-la-narrativa) · [4](#4--pedagogía-como-para-un-bebé) · [5](#5--idioma-del-código-convenciones-de-java-y-baseline) · [6](#6--plantilla-de-los-capítulos-teóricos-0124) · [7](#7--la-serie-práctica-labs-lnn--y-apéndices-ann-) · [8](#8--preguntas-en-los-capítulos--ejercicios-en-labs-y-apéndices) · [9](#9--vocabulario-visual-reglas-y-callouts) · [10](#10--bibliografía-referencias-y-enlaces) · [11](#11--coherencia-entre-documentos) · [12](#12--checklist-antes-de-dar-por-cerrado-un-md) · [13](#13-️-excepciones-declaradas-a-los-lineamientos-generales)

---

## 1. 🧭 Principio rector

**Todo lo que se escribe apunta a que alguien reconozca, explique, compare y decida.**

No enseñamos Spring "completo": el ecosistema tiene decenas de proyectos y cientos de
anotaciones, y memorizarlos no hace a nadie mejor arquitecto. Repasamos el modelo de
ejecución, los mecanismos y los matices que separan a quien entiende el contenedor de
quien aprendió las anotaciones. En la serie práctica, además, formamos una capacidad
concreta: **levantar un servicio Spring Boot, romperlo a propósito, diagnosticarlo con
la evidencia a la vista y dejar la máquina limpia**.

El filtro para cada párrafo es este: **¿esto ayuda a reconocer, explicar, comparar o
decidir?** Si no, sobra. Aunque esté muy bien escrito.

Y el corolario, repetido tantas veces como haga falta:

> Cada anotación se explica. Cada atributo y cada propiedad se explican. Cada decisión
> responde a "¿por qué estamos haciendo esto y qué pasaría si no?".

Hay una segunda pregunta, propia de este curso, que hay que poder contestar en cada
capítulo donde aparezca una anotación que "simplemente funciona":

> **¿Quién ejecuta esto, en qué hilo, y a través de qué proxy?**

`@Transactional`, `@Async`, `@Cacheable`, `@Retryable`, `@PreAuthorize` y
`@TransactionalEventListener` son todos el mismo mecanismo con distinto sombrero. Un
capítulo que las presenta como magia declarativa y no dice quién las intercepta está
mal escrito, por más correcto que sea el ejemplo.

---

## 2. 🎤 Tono

El tono es **semi formal, cálido y directo**, de colega a colega. Piensa en alguien que
ya se quemó con esto —un `@Transactional` que no hizo rollback, un `NoUniqueBean
DefinitionException` a las once de la noche, un pool de Hikari agotado por un cliente
HTTP sin timeout— y te lo explica con paciencia y sin solemnidad de manual corporativo.

Cómo se ve en la práctica:

- **Tuteo latinoamericano, siempre.** Le hablas al lector de "tú": *"fíjate en qué
  hilo corre eso"*, *"si esto te suena raro, es porque todavía no vimos los proxies;
  aguanta dos capítulos"*. Nada de voseo, nada de "usted", nada de impersonal
  permanente ("se debe configurar…") que enfría el texto.
- **Semi formal.** Cercano, pero no chat. Frases completas, puntuación correcta, cero
  abreviaturas de mensajería.
- **Humor mínimo y seco.** Un 😉 bien puesto para desdramatizar una fricción real —la
  cantidad de gente que inyecta por campo "porque es más corto", la fe en que WebFlux
  es "más rápido"— y nada más. Regla práctica: **como mucho un desdramatizador por
  documento**, y si no fluye solo, se borra.
- **Honesto sobre las simplificaciones.** Cuando la respuesta común de entrevista es
  una sobregeneralización —"los beans de Spring son singletons", "`@Transactional`
  abre una transacción", "WebFlux escala mejor", "`@Autowired` inyecta por tipo"— se
  nombra la simplificación y se da la versión precisa. **Este es el recurso pedagógico
  central del curso**, por encima de la analogía y del ejemplo.
- **Honesto sobre las versiones.** El curso fija Spring Boot 3.5.16 (§5.1) y lo declara
  en cada documento. Cuando algo cambió en 4.x, o cuando la respuesta "clásica" que el
  lector va a encontrar en un blog de 2019 ya no aplica, se dice con 📝 en el propio
  texto. Nada de "en versiones recientes": se nombra la versión.
- **Honesto sobre el costo en runtime.** Lo que en el curso de AWS era el precio por
  hora, aquí es el hilo bloqueado, la conexión retenida, el objeto en heap y el
  segundo de arranque. Se nombra con su unidad (⏱️, §9.3), no con eufemismos tipo
  "ligero impacto en rendimiento".
- **Cálido sin condescendencia.** Explicamos desde cero, pero nunca infantilizamos.
  "Como para un bebé" significa **cero ambigüedad**, no menos profundidad — ver §4.
- **Sin relleno motivacional.** Sin "¡tú puedes!", sin "vas a dominar Spring". Quien
  lee ya sabe por qué está repasando.

---

## 3. 🗣️ Idioma y forma de la narrativa

- **Español latinoamericano neutro**, técnico y claro, para todo lo que no sea código
  o salida de terminal.
- **Los nombres de clases, anotaciones, propiedades y términos del stack se quedan en
  inglés**, que es como aparecen en el IDE, en el log y en el stack trace:
  *`ApplicationContext`*, *`BeanPostProcessor`*, *bean definition*, *proxy*,
  *self-invocation*, *backpressure*, *connection pool*, *thread-per-request*,
  *graceful shutdown*, *chunk*, *filter chain*. Traducirlos forzadamente ("contexto de
  aplicación", "cadena de filtros de seguridad") confunde y no es lo que el lector va a
  ver cuando algo falle. Los que ya tienen traducción asentada —hilo, contenedor,
  anotación, transacción, caché, reintento— se usan con naturalidad; lo importante es
  no inventar vocabulario.
- **Markdown siempre.** Nada de HTML embebido.
- **Estructura visual primero, pero la prosa ya no es el último recurso.** El orden de
  preferencia sigue siendo diagrama ASCII → tabla → lista → párrafo *para exponer una
  relación entre cosas*. Pero el **porqué** de una decisión se escribe en prosa: una
  tabla no puede explicar por qué un `@Transactional` sobre un método privado no falla,
  no avisa, y simplemente no hace nada.
- **Nada de prosa telegrama.** Una frase corta y sola, con líneas en blanco a ambos
  lados, es un buen golpe de ritmo. Tres seguidas ya no son ritmo: son un telegrama.
  Regla práctica: **una frase aislada por sección, dos si la sección es larga**.
- **Diagramas ASCII en bloques ` ```text `.** Es el recurso visual principal del curso y
  se usa sin timidez: la cadena de filtros, el ciclo de vida de un bean, el camino de un
  request por el `DispatcherServlet`, el apilado de decoradores de Resilience4j, el flujo
  chunk-oriented de Batch. Simples: cajas, flechas, texto. Sin arte ASCII elaborado.
- **Tablas solo para comparar o mapear**, con tres o cuatro columnas como norma:
  "`Filter` vs `HandlerInterceptor` vs `@ControllerAdvice`", "propagación REQUIRED vs
  REQUIRES_NEW", "Lettuce vs Redisson vs Jedis". **La excepción legítima es la matriz
  que enfrenta cuatro alternativas a un criterio** —los cinco clientes HTTP de `13`, los
  tres modelos de ejecución de `12`—, donde cinco columnas son la forma natural del
  contenido. **Si necesitas explicar una celda, ya no es una tabla**: es una lista con
  subtítulos o un par de párrafos. Nunca se narra en tabla.
- **Salida de consola literal.** Cuando se muestra lo que imprime la aplicación —un
  stack trace, el informe de condiciones de la autoconfiguración, un log de Hikari— se
  muestra tal como sale, en bloque ` ```text `, sin embellecer y **sin recortar la parte
  incómoda**. Un stack trace se puede podar de los frames de reflexión irrelevantes, y
  cuando se poda se marca con `\t... 47 more` o con un comentario explícito; nunca se
  edita el mensaje ni el nombre de la excepción. El error real enseña más que el error
  editado, y la mitad del valor del curso está en que el lector reconozca la primera
  línea de una excepción.
- **Encabezados con emoji, con moderación.** Uno por sección `##` numerada, ninguno en
  las subsecciones `###` — con una excepción declarada: los encabezados de la sección de
  ejercicios de labs y apéndices llevan su marcador de dificultad (§8.2), porque ahí el
  emoji **es** el dato. El emoji es funcional: señala de qué tipo es la sección
  (🧭 encuadre, 🧱 mecanismo, ⚖ comparación, 🩺 diagnóstico, ⏱️ costo en runtime,
  🧪 verificación, 📋 checklist de salida, 🏁 cierre de lab, 🧠 preguntas, 📚 referencias).
  Un documento que parece un teclado de emojis pierde autoridad.

---

## 4. 🎓 Pedagogía: "como para un bebé"

El principio se enuncia así:

> **"Como para un bebé" significa cero ambigüedad, no menos profundidad.**

No es escribir más simple: es no dejar ningún hueco donde el lector tenga que adivinar.
Se explica qué es un proxy CGLIB, en qué se diferencia de uno JDK, por qué Spring elige
uno u otro y qué síntoma exacto produce cuando la elección te sorprende. No se dice
"Spring crea un proxy" y se sigue adelante.

### 4.1 La regla del andamio

Todo concepto nuevo se presenta en tres tiempos, en este orden:

1. **El problema primero.** Antes de nombrar la anotación, muestra el dolor que
   resuelve. *"Tu servicio llama a un proveedor que tarda 30 segundos una vez cada
   cien. Tienes 200 hilos en Tomcat. A la tercera ráfaga, la aplicación entera deja de
   responder — incluido el `/health`. ¿Qué le pones delante?"*
2. **El mecanismo después.** Ahora sí, el nombre y la definición mínima: lo justo para
   usarlo hoy, no el capítulo completo de la reference.
3. **El código que corre.** El fragmento más pequeño que demuestra el punto, con su
   salida esperada —el log, la respuesta HTTP o la excepción—.

Presentar la anotación antes que el problema produce gente que sabe recitar
"`@Transactional` gestiona la transacción por ti" y no sabe por qué su rollback no
ocurrió.

### 4.2 Ningún bloque de código queda sin desglose

Esta es la regla más importante de la sección y no admite excepciones.

Cada bloque de código, cada comando y cada bloque de configuración que aparezca en el
curso se acompaña de qué hace, qué significan sus partes no obvias y qué pasa si las
omites o las pones mal. Lo obvio (`@Service`, `@GetMapping` una vez explicados) no se
repite en cada aparición, pero **el primero de su tipo en el curso se explica entero**.

```java
@Service
class InventoryService {

    private final InventoryRepository repository;

    // inyección por constructor: sin @Autowired, porque hay un solo constructor
    InventoryService(InventoryRepository repository) {
        this.repository = repository;
    }

    @Transactional(propagation = Propagation.REQUIRES_NEW, timeout = 5)
    public void record(InventoryEvent event) {
        repository.save(event);
    }
}
```

- **`@Service`** es un `@Component` con estereotipo: para el contenedor son
  equivalentes, la diferencia es semántica y que algunas herramientas filtran por él.
- **El constructor sin `@Autowired`** funciona desde Spring 4.3: cuando hay un único
  constructor, el contenedor lo usa sin anotación. Con dos constructores y ninguna
  anotación, obtienes `NoSuchMethodException` en el arranque, no en tiempo de
  compilación.
- **`propagation = REQUIRES_NEW`** suspende la transacción del llamador y abre una
  nueva conexión. Si tu pool tiene 10 conexiones y el llamador ya tiene una, acabas de
  consumir dos por request — es la causa clásica del deadlock por agotamiento de pool.
- **`timeout = 5`** son segundos, y lo cuenta el `PlatformTransactionManager`, no la
  base de datos: si la sentencia ya salió, el driver puede seguir esperando. El timeout
  de la transacción no sustituye al `socketTimeout` del driver.
- **Lo que no se ve aquí:** este `@Transactional` solo funciona si el método se llama
  **desde fuera** del bean. Si otro método de esta misma clase llama a `record()`, el
  proxy no participa y no hay transacción. Ver [`05` — proxies y AOP].

Ese nivel es el estándar. Un bloque de código sin desglose posterior es un error de
estilo, por más correcto que sea el código.

### 4.3 Explica el porqué, no solo el cómo

Un paso sin justificación es un paso que el lector no puede adaptar cuando su caso real
difiera del ejemplo. Cada decisión relevante lleva su porqué, aunque sea media línea
entre paréntesis: por qué el curso inyecta por constructor y no por campo, por qué el
lab usa Testcontainers y no una base embebida, por qué se fija `spring.jpa.open-in-view=false`
antes de escribir la primera entidad.

Cuando el porqué es histórico y no técnico —que en Spring pasa seguido— se dice también:
*"`RestTemplate` no está deprecado, está en modo mantenimiento desde 5.0, y eso significa
que recibe correcciones pero no funcionalidad nueva; por eso el curso enseña `RestClient`
primero y `RestTemplate` como lo que vas a encontrar"*.

### 4.4 Nada de cajas negras prematuras

El curso enseña primero el mecanismo y después la comodidad:

- primero el contenedor y la definición de beans, **después** la autoconfiguración de
  Boot que las crea por ti;
- primero `JdbcTemplate` y el SQL a la vista, **después** los repositorios derivados de
  Spring Data;
- primero un `Filter` escrito a mano, **después** la cadena de Spring Security;
- primero `RestClient` con su timeout explícito, **después** Feign declarativo;
- primero `@Cacheable` fallando en self-invocation, **después** la configuración fina
  de TTL y serialización.

No es que esas capas sean malas. Es que ocultan exactamente lo que el curso quiere
enseñar, y quien entiende el mecanismo aprende la capa de arriba en una tarde.

### 4.5 Analogías con fecha de caducidad

Las analogías se usan **una vez, para abrir la puerta**, y después se abandonan diciendo
dónde se rompen. El contenedor se parece a una fábrica de objetos *hasta que descubres
que lo que te entrega no es tu objeto, sino un proxy que lo envuelve*.

Cuidado especial con las cinco más peligrosas del temario, que se desmontan en el mismo
párrafo en que aparecen:

- **el singleton de Spring no es el patrón Singleton** (es uno por `ApplicationContext`,
  no uno por JVM, y no tiene constructor privado);
- **`@Transactional` no abre una transacción: le pide a un proxy que se la pida a un
  `TransactionManager`** — y si no hay proxy, no hay nada;
- **WebFlux no es "más rápido"**: usa menos hilos, que es otra cosa, y se paga en
  legibilidad y en depuración;
- **un `Filter` no es un interceptor de Spring** (corre antes del `DispatcherServlet` y
  no sabe nada de tus `@ControllerAdvice`);
- **`@Async` no hace nada asíncrono si lo llamas desde el mismo bean**, exactamente por
  la misma razón que `@Transactional`.

Una analogía que no se cierra genera bugs conceptuales que aparecen cinco capítulos
después.

### 4.6 Densidad calibrada

Los capítulos teóricos de este curso son **cortos y densos: de 200 a 380 líneas**. Es
una divergencia declarada respecto de la guía de AWS, que retiró el techo de longitud, y
la razón es el calendario: este curso se estudia en sesiones de una hora contra una
agenda de entrevistas, y un capítulo de 800 líneas no se repasa la noche anterior.

> **📝 Por qué 380 y no 350.** La banda se calibró en 200–350 copiándola del corpus de
> arquitectura, que es prosa casi pura. Aquí no funciona: §4.2 obliga a que **cada bloque
> de código lleve su desglose en viñetas**, y eso añade del orden de quince líneas por
> mecanismo explicado. Un capítulo de ocho mecanismos arrastra unas ciento veinte líneas
> que en el otro corpus no existen. La banda se ajustó a 380 tras escribir `01`, `05` y
> `06`, no para acomodar un documento suelto.

- Un concepto nuevo por vez. Si un bloque de código introduce tres cosas desconocidas,
  se parte en tres bloques.
- Repetir lo importante está bien. Los conceptos que sostienen el curso —proxy, hilo,
  scope, transacción, contexto— reaparecen con otras palabras. La repetición espaciada
  funciona; la enciclopedia no.
- Ninguna sección teórica supera las dos pantallas sin un diagrama, una tabla, un bloque
  de código o una salida real.
- **Pasar de 380 exige poder decir qué enseña cada sección nueva que no enseñara ya
  otra.** Si la respuesta es "es que el tema es grande", el capítulo es un mapa y
  probablemente había que partirlo o recortar el alcance, no estirarlo.
- **Si un capítulo se pasa de ~450 líneas, se parte en dos y se renumera en la misma
  edición**, declarando el cambio y arreglando los enlaces entrantes. Los labs y los
  apéndices no tienen este techo: un lab dura lo que necesite para no dejar huecos.
- **Excepciones declaradas, y son dos.**
  - **`01` es el capítulo-mapa** y cierra en ~415 líneas, con su índice de salto rápido
    porque pasa de 400 (§6.2). Cada una de sus diez secciones enseña un mecanismo que
    ninguna otra enseña —starter, BOM, jar ejecutable, árbol de versiones, EOL, mapa del
    ecosistema— y el curso entero remite a él para no repetirlos.
  - **`20` cierra en ~440.** Su ficha tiene **catorce mecanismos distintos** —cadena de
    filtros, configuración por bean, `AuthenticationManager`, `PasswordEncoder`,
    `SecurityContextHolder`, autorización HTTP, method security, 401/403, CSRF, CORS,
    cabeceras, sesión, Actuator y testing— contra los seis o siete de `05` y `16`, que son
    sobre los que se calibró la banda.
  En los dos casos se puede decir qué enseña cada sección que no enseñe otra, que es lo
  que esta sección exige para pasar de 380. **Ningún otro capítulo pasa de 380**, y
  ninguno de los dos llega al umbral de ~450 que obliga a partir.
- **La excepción de `A04`**, que además no es de longitud sino de enlaces, se declara en
  §10.2 y en el propio apéndice.
- **Todo documento de más de ~400 líneas abre con un índice de salto rápido** (§6.2).

### 4.7 Cierra los bucles

Si abres un paréntesis —*"esto lo vemos en `16`"*, *"el teardown de esto está en
`L09`"*— tiene que cerrarse en algún documento del curso, y con enlace real. Un
pendiente que nunca se resuelve es ruido y el lector deja de confiar en las promesas del
texto. El mapa de referencias cruzadas entre documentos es parte del producto.

---

## 5. 💻 Idioma del código, convenciones de Java y baseline

> **Regla normativa: todo lo que se ejecuta o se versiona va en inglés —clases, métodos,
> paquetes, beans, propiedades, nombres de servicio y de tabla— y todos los comentarios
> van en español.**

| Elemento | Idioma | Ejemplo |
|---|---|---|
| Clases, anotaciones y tipos de Spring | Inglés (nombre oficial) | `ApplicationContext`, `SecurityFilterChain`, `ProblemDetail` |
| Clases, métodos y paquetes del lab | Inglés | `InventoryService`, `recordEvent()`, `com.invlab.invapi.inventory` |
| Claves de configuración | Inglés (las que define Spring) | `spring.datasource.hikari.maximum-pool-size` |
| Nombres de bean, tabla, colección y caché | Inglés, con la convención de su mundo | bean `inventoryService`, tabla `inventory_item`, caché `inventory-items` |
| Comentarios dentro de bloques de código | Español | `// el proxy no intercepta esta llamada` |
| Narrativa alrededor del código | Español | todo el texto fuera de los bloques |
| Términos técnicos consolidados | Inglés sin traducir | *bean definition*, *self-invocation*, *backpressure* |

### 5.1 Convenciones de código del curso

Estas no son preferencias: son decisiones pedagógicas, y cada una tiene su porqué
escrito porque el lector se lo va a preguntar.

- **Inyección por constructor, siempre, y sin `@Autowired`.** Hace visible la
  dependencia, permite campos `final` y hace el bean testeable sin contenedor. La
  inyección por campo aparece en el curso **solo** como antipatrón, marcada como tal.
- **Sin Lombok.** El curso enseña qué genera el contenedor; esconder el constructor
  detrás de `@RequiredArgsConstructor` tapa exactamente lo que estamos explicando. Se
  nombra una vez en `03`, se dice que en un proyecto real es razonable, y no vuelve a
  aparecer.
- **`record` para DTOs y para `@ConfigurationProperties`**, clases normales para
  entidades y servicios. Java 21 lo permite y elimina veinte líneas de ruido por
  ejemplo.
- **Visibilidad mínima.** Las clases y constructores del lab son package-private salvo
  que algo obligue a lo contrario; un `public` gratuito en un ejemplo enseña a
  exponerlo todo.
- **Imports omitidos en los bloques, salvo cuando el import *es* el punto.** Cuando dos
  tipos comparten nombre simple —`jakarta.validation.Valid` vs
  `org.springframework.validation.annotation.Validated`,
  `jakarta.transaction.Transactional` vs `org.springframework.transaction.annotation.Transactional`—
  **el import se escribe siempre**, porque confundirlos es un bug real y frecuente.
- **Maven, no Gradle.** Es lo que hay en banca. Gradle se nombra en `01` y no reaparece.
- **YAML en los labs, `.properties` en los ejemplos de una sola clave.** El capítulo `07`
  compara los dos formatos a fondo; el resto del curso usa el que se lea mejor en cada
  punto y no discute la elección otra vez.
- **Nunca `latest`, nunca un rango de versiones, nunca un tag de imagen sin fijar.**
  Ni en dependencias, ni en imágenes de Docker, ni en el JDK.

### 5.2 Baseline de versiones — verificado 2026-09-17

| Elemento | Valor fijado | Nota |
|---|---|---|
| Spring Boot | **3.5.16** | última release OSS de la línea 3.5 (25-jun-2026) |
| Spring Framework | **6.2.19** | el que arrastra el BOM de Boot 3.5.16 |
| Java | **21 LTS** (Temurin) | Boot 3.5 admite 17–25; el curso fija 21 por los virtual threads |
| Build | **Maven** con el wrapper `./mvnw` | Maven 3.6.3 o superior |
| Servidor embebido | **Tomcat 10.1** (Servlet 6.0) | Netty en los capítulos reactivos |
| Resilience4j | **2.2.0** (`resilience4j-spring-boot3`) | fuera del BOM de Boot: versión explícita |
| Todo lo que está en el BOM de Boot | **sin versión en el `pom.xml`** | Hikari, Jackson, Flyway, Lettuce, Caffeine, Testcontainers |
| Dependencias fuera del BOM | **versión explícita, verificada al escribir** | Redisson, Ehcache 3, springdoc: se fijan en el capítulo que las introduce |
| Imágenes de Docker del lab | **tag exacto, fijado y verificado en `L00`** | ningún `:latest`, ninguna imagen sin declarar en `L00` |

> **⚠️ El baseline es una línea EOL y el curso lo dice en voz alta.** Spring Boot 3.5
> perdió el soporte open source el 30 de junio de 2026 y solo recibe parches bajo
> soporte comercial (hasta 2032). El GA actual es la línea 4.x sobre Spring Framework 7.
> El curso se escribe sobre 3.5.16 porque **es el código que hay en producción en banca
> y el que vas a tocar**, no porque sea el más nuevo. La contrapartida es obligatoria:
> **todo capítulo cuyo tema cambie en 4.x lleva su 📝 diciendo qué cambia**, y el
> apéndice `A04` desarrolla la migración entera. Un capítulo que presenta como actual
> algo que 4.x cambió está mal escrito.

### 5.3 Nombres estables de la serie práctica

Estos nombres son el baseline del laboratorio y no cambian entre documentos. Si un lab
necesita otro, lo declara y explica por qué.

| Elemento | Valor fijado |
|---|---|
| Artifact / servicio principal | `inv-api` |
| `groupId` / paquete base | `com.invlab` / `com.invlab.invapi` |
| Proveedor externo simulado (WireMock) | `inv-supplier` |
| Proyecto de Docker Compose | `inv-lab` |
| Perfiles | `local` (default del lab), `test`, `prod` (simulado) |
| Puerto de la aplicación / de Actuator | `8080` / `8081` |
| Postgres: base, usuario, password | `inv_lab` / `inv_lab` / `inv_lab` |
| Tablas | `inventory_item`, `inventory_event` |
| Colección de Mongo | `inventory_snapshot` |
| Caché y prefijo de Redis | `inventory-items` / `inv:` |
| Job de Batch | `inventory-reconciliation-job` |
| Dominio de ejemplo en URLs y tokens | `invlab.example` |
| Usuario de ejemplo | `analyst@invlab.example` |

**Las credenciales del lab son deliberadamente triviales y el documento lo dice**: son
un Postgres en `localhost` que muere con `docker compose down -v`. Un lab que usa
`inv_lab/inv_lab` y explica por qué eso sería inaceptable fuera de tu máquina enseña
más que uno que simula rigor con una contraseña falsa de veinte caracteres.

---

## 6. 🧱 Plantilla de los capítulos teóricos (`01`–`24`)

1. **Título** — `# NN — Tema` (dos dígitos, sin emoji en el título).
2. **Blockquote de encabezado** — objetivo del documento en una o dos líneas, qué se
   asume leído, y **`Vigencia:`** con la fecha en que se verificaron los enlaces y el
   comportamiento descrito, junto con la versión del baseline. Ese campo es obligatorio:
   quien abre `16` sin pasar por el README tiene que saber sobre qué versión lee.
3. **Índice de salto rápido** — si el documento pasa de ~400 líneas (§6.2).
4. **Secciones `##` numeradas**, una por concepto o mecanismo, con emoji funcional.
   Cuando el capítulo cubre bloques claramente separables se usan divisores
   `# Parte I — …` en romanos, **manteniendo la numeración arábiga de `##` continua** a
   través de las partes.
5. **⚠️ Errores frecuentes** — sección opcional pero recomendada: la confusión típica de
   entrevista sobre ese tema, con la versión precisa al lado.
6. **🧠 Preguntas rápidas** — cierre obligatorio, sin respuestas visibles (§8.1). **Un
   capítulo teórico no lleva ejercicios**: si el contenido pide ejecutar algo, va a un
   lab o a un apéndice.
7. **📚 Referencias oficiales** — cierre obligatorio (§10).

**Excepciones declaradas a la plantilla:**

- `README.md` — índice, mapa de estudio y tabla de asociaciones.
- `25-simulacion-de-entrevista.md` — preguntas `P#` sin respuesta inline (van al
  solucionario) y escenarios de diseño que **sí** conservan su solución desarrollada,
  porque son ejemplos resueltos y no autochequeo de memoria.
- `26-respuestas.md` — solucionario centralizado. No lleva "Preguntas rápidas" ni
  referencias propias.
- `l00-idea-lab-practico.md` — encuadre de la serie práctica (§7.1).

### 6.1 Estructura interna recomendada de una sección `##`

Para que veinticuatro capítulos escritos en semanas distintas se lean igual, cada sección
que presenta un mecanismo sigue el andamio de §4.1 en este molde:

```text
## N. 🧱 <Mecanismo>

<el problema, en dos o tres frases, con síntoma concreto>
<el mecanismo, con el mínimo de definición>
<bloque de código más pequeño que lo demuestre>
<desglose en viñetas, una por elemento no obvio>
<la trampa: qué falla, con la excepción o el log literal>
<veredicto: cuándo sí, cuándo no>
```

**El veredicto no es opcional en los capítulos comparativos** (`12`, `13`, `17`, `19`):
una alternativa presentada sin decir cuándo pierde no está explicada.

### 6.2 Índice de salto rápido

Formato fijo, justo después del blockquote de encabezado:

```markdown
**Salto rápido:** [Propagación](#3--propagación) · [`REQUIRES_NEW`](#4--requires_new) ·
[Rollback y excepciones](#6--rollback-y-excepciones) · [Preguntas rápidas](#-preguntas-rápidas)
```

**Cómo se calcula un ancla de GitHub**, porque es donde se rompen estos índices: se pasa
el encabezado a minúsculas, se eliminan los caracteres que no son letra, número, espacio,
guion o guion bajo —lo que se lleva por delante el punto de la numeración, el emoji, los
backticks, los paréntesis, los dos puntos y la arroba— y por último los espacios
restantes se convierten en guiones. Cada carácter borrado **deja su espacio**, y de ahí
salen los guiones dobles:

| Encabezado | Ancla |
|---|---|
| `## 2. 🧱 Proxies` | `#2--proxies` |
| `## 5. 🧱 \`@Transactional\`` | `#5--transactional` |
| `## 7. ⚖ \`Filter\` vs \`HandlerInterceptor\`` | `#7--filter-vs-handlerinterceptor` |
| `## 🧠 Preguntas rápidas` | `#-preguntas-rápidas` |

Fíjate en el último: un encabezado que empieza por emoji genera un ancla que **empieza
por guion**. Y fíjate en el tercero: el guion bajo **sí sobrevive**, pero la arroba no.
Verifica los anclas al escribirlos; un índice con enlaces rotos es peor que no tener
índice.

**La excepción que la regla no cubre: el selector de variación U+FE0F.** `⚠️` y `⏱️` son un
carácter base seguido de un U+FE0F invisible, y GitHub **conserva** ese U+FE0F en el ancla,
pegado al primer guion. El ancla se ve igual que la de la tabla y no lo es:

| Encabezado | Ancla |
|---|---|
| `## 6. ⚠️ Leer el cuerpo en un filtro lo destruye` | `#6-️-leer-el-cuerpo-en-un-filtro-lo-destruye` (con U+FE0F tras `6-`) |
| `## 10. ⚠️ Errores frecuentes` | `#10-️-errores-frecuentes` (ídem) |
| `## 8. ⚖ La excepción del filtro…` | `#8--la-excepción-del-filtro…` (sin selector: el `⚖` de este curso se escribe sin él) |

En este curso pasa en los encabezados con ⚠️ (54) y con ⏱️ (8). Hasta el 2026-10-05 había
**190 enlaces** escritos sin el U+FE0F, que el script de anclas de entonces daba por buenos
porque calculaba el ancla con la misma regla incompleta; se corrigieron todos. **No calcules
estas anclas a mano**: copia el encabezado y deja que `prompts/verificar-corpus.py` te diga el
ancla correcta (`ANCLA-FE0F`), o corrígelas con su `--corregir-fe0f`.

---

## 7. 🧪 La serie práctica: labs (`lNN-`) y apéndices (`aNN-`)

Los labs y los apéndices siguen la plantilla de §6 con los añadidos de abajo, y sin
ninguna excepción de tono ni de pedagogía: aquí la regla de §4.2 —ningún bloque de
código sin desglose— se aplica con más rigor que en ninguna otra parte, porque son los
documentos que el lector ejecuta.

### 7.1 La doctrina de reparto es materia editorial, no solo de alcance

Esta es la divergencia central respecto del curso de AWS, del que esta guía desciende.
Allí la regla de alcance era económica —*en la nube se practica solo lo que únicamente
existe en la nube*— porque cada recurso facturaba. Aquí no hay factura: todo corre en
`localhost` con Docker Compose y el costo total de la serie es **$0.00**. La regla que
ocupa su lugar es pedagógica:

> **Al lab va lo que solo se entiende viéndolo fallar en runtime.** Lo que se entiende
> leyendo se queda en el capítulo.

Un tema entra en el laboratorio si cumple al menos una condición: el fallo es silencioso
y solo se ve ejecutando (el `@Transactional` que no hace rollback, el `@Async` que corre
en el hilo del llamante), el síntoma está en un log o en un stack trace que hay que
aprender a leer (agotamiento de pool, `LazyInitializationException`, circuito abierto),
depende de una infraestructura real que un mock no reproduce (Postgres, Redis, un
proveedor lento), o es una costura entre tu código y el contenedor (orden de filtros,
informe de condiciones de autoconfiguración, `graceful shutdown`).

Y la contrapartida se escribe con la misma claridad: **cuando el curso deja algo fuera
del lab —Kafka, Kubernetes, un frontend, un IdP real— dice por qué y dónde se practica
en su lugar.** Una exclusión sin justificación se lee como un hueco del temario; una
exclusión justificada es contenido. El desarrollo completo de esta doctrina vive en
`l00-idea-lab-practico.md` y el resto de documentos remite ahí en vez de reabrir la
discusión.

### 7.2 Labs `lNN-tema.md`

Título `# LNN — Tema`. Son acumulativos y se hacen en orden sobre **un único proyecto**,
`inv-api`, que crece lab a lab. Además de lo de §6:

- **Cabecera con contrato:** duración estimada, prerrequisitos (qué lab anterior debe
  estar hecho), qué servicios de Compose deja levantados al terminar y qué ramas o
  carpetas toca. El costo se declara igual que en AWS, y siempre es `$0.00`: se escribe
  para que el lector no tenga que preguntárselo.
- **Estado inicial verificable.** Cada lab abre con el comando que confirma que vienes
  del estado correcto (`./mvnw -q test`, `docker compose ps`, un `curl` al health). Si
  falla, el lab dice a cuál volver.
- **Teardown escrito junto al recurso.** Ningún lab levanta un contenedor, crea un
  volumen o escribe en un directorio sin que el documento diga, en ese mismo punto, cómo
  se destruye y cómo se verifica que murió. Lo que sobrevive a `docker compose down` —un
  volumen con `-v` ausente, una imagen construida, el `~/.m2`— se dice ahí, no en `L09`.
- **Reproducir el error antes de arreglarlo.** Cuando el lab enseña un fallo se provoca
  a propósito, se muestra el stack trace literal y solo después la corrección. **Este es
  el músculo central de la serie**: el lector tiene que reconocer la primera línea de la
  excepción antes de saber la causa.
- **Predicción antes de ejecución.** Antes de los comandos que producen un resultado
  contraintuitivo, se le pide explícitamente al lector que anticipe la salida y después
  compare.
- **📋 Checklist de salida** en formato `- [ ]` antes del cierre, con comprobaciones
  ejecutables. No son ejercicios: son criterios de terminado verificables.
- **🧪 Ejercicios** graduados (§8.2), después de las preguntas rápidas.
- **Calibración de longitud: se presupuesta por mecanismo, no por documento.** Un
  mecanismo con su error reproducido —comando, salida literal, traza en `DEBUG`, desglose
  en viñetas, corrección y verificación— cuesta **unas 200 líneas**, y §7.2 exige esa
  estructura completa: recortarla es recortar la pedagogía. De ahí la regla operativa:

  ```text
  longitud esperada ≈ 200 × (mecanismos de la ficha) + 150 de cabecera, checklist y cierre
  ```

  **Qué cuenta como un mecanismo, porque aquí se falla al presupuestar:** uno es *una
  reproducción con su estructura completa*. Si una ficha dice "tres variantes del mismo
  fallo", eso son **tres** mecanismos, no uno, porque cada variante lleva su comando, su
  salida literal, su diagnóstico, su corrección y su verificación. Y un mecanismo que
  además carga con una migración del proyecto —cambiar la capa de persistencia entera—
  cuenta por dos. `L04` se presupuestó como seis y en realidad tenía ocho: la fórmula
  acertó, la cuenta no.

  **La palanca es el número de mecanismos que fija la ficha del lab, no la
  prosa del lab.** Un lab de seis mecanismos cae cerca de 1 300 líneas y está bien
  escrito; si quieres 900, la ficha lleva cuatro mecanismos, no seis apretados. El techo
  práctico son **ocho mecanismos**: por encima, el lab deja de caber en una sesión y se
  parte en dos.

  > **📝 Esta regla sustituye a una banda fija de 700–1 100 líneas que estuvo escrita
  > aquí y no sobrevivió al contacto con los datos.** Aquella cifra se calibró tomando
  > como referencia `L00`, que es el encuadre de la serie y **no ejecuta nada**. Los tres
  > labs ejecutables escritos hasta hoy —`L01` con 1 642 líneas, `L02` con 1 315 y `L03`
  > con 1 260— la incumplían todos, y al revisarlos buscando prosa sobrante no la había:
  > lo que hay es una estructura obligatoria repetida una vez por mecanismo. Cuando la
  > regla y tres documentos bien escritos se contradicen, la que estaba mal era la regla.
- **🏁 La señal de que quedó bien** — una frase de cierre que describe el estado
  correcto: *"`docker compose ps` no lista nada, `./mvnw -q verify` pasa en verde y
  `curl localhost:8081/actuator/health` no responde porque ya no hay nada escuchando"*.

### 7.3 Apéndices `aNN-tema.md`

Título `# ANN — Tema`. Material de consulta, sin orden ni prerrequisitos. No llevan
contrato de duración ni checklist de salida. Abren siempre con índice de salto rápido
(son de consulta: nadie los lee linealmente) y organizan el contenido en secciones
cortas e independientes, cada una autosuficiente. Sí llevan "Preguntas rápidas",
"🧪 Ejercicios" (§8.2) y "Referencias oficiales".

`A03` —el catálogo de errores— tiene una estructura propia y obligatoria por entrada:
**primera línea de la excepción literal → qué la causa de verdad → el comando o el log
que lo confirma → la corrección → cómo se evita**. Es la §9.4 comprimida en ficha, y es
lo que hace que el apéndice sirva a las 2 de la mañana.

---

## 8. 🧠 Preguntas en los capítulos, 🧪 ejercicios en labs y apéndices

Este curso reparte el aparato de evaluación en dos mitades que no se mezclan:

```text
capítulos teóricos (01–25)  →  SOLO preguntas rápidas. Nunca ejercicios.
                               Respuestas SIEMPRE en 26-respuestas.md.

labs (L01–L09) y apéndices  →  preguntas rápidas + 🧪 ejercicios graduados,
(A01–A04)                      con 🔥 opcionales y 💀 boss fight cuando lo pida
                               el contenido. Los ejercicios NO van al solucionario.
```

**Por qué esta división.** Coincide con el valor por defecto del `CLAUDE.md` del
repositorio para los cursos con laboratorio —capítulos teóricos con 10 a 15 preguntas y
ningún ejercicio; labs y apéndices con preguntas y ejercicios graduados—, y este curso la
adopta por una razón propia: los capítulos teóricos son repaso para una entrevista —se
contestan en voz alta, sin computadora—, mientras que los labs son lo único ejecutable del
curso. Poner ejercicios en un capítulo teórico obligaría al lector a levantar el proyecto
para estudiar teoría, que es justo lo que la doctrina de reparto de `L00` separa. Las
bandas de ejercicios (12–20 y 8–12) sí son propias del curso y van en §13.

> **📝 Esta sección decía, hasta el 2026-10-05,** que el `CLAUDE.md` fijaba de 20 a 30
> ejercicios por sección y que esta división era una divergencia. Ya no es así: ese valor
> es el de otro repositorio de cursos, y el `CLAUDE.md` de este pide lo que aquí se hace.

### 8.1 Preguntas rápidas — cierre obligatorio de todo documento

Son preguntas para contestar de memoria o razonando, no trabajos para resolver con
código. Cierran **todos** los documentos: los teóricos, los labs y los apéndices.

- **Cantidad: 10 a 15 por capítulo o lab, y de 6 a 12 en un apéndice**, calibrada por
  cuántas cosas distintas enseña el documento y se pueden comprobar por separado —nunca
  por su longitud—. Subir de 15 exige poder decir qué comprueba cada pregunta nueva que
  no comprobara ya otra.
- **Directas y verificables.** Cada pregunta tiene respuesta corta y objetiva
  localizable en el propio documento. Nunca "reflexiona sobre…".
- **Reparto sugerido**, para que la sección entrene algo más que memoria: aproximadamente
  la mitad de definición o distinción ("¿`@Component` y `@Bean` producen lo mismo?"), un
  tercio de decisión o comparación ("¿cuándo eliges `REQUIRES_NEW` sobre `REQUIRED`?") y
  el resto de diagnóstico ("tu `@Cacheable` nunca guarda nada, ¿qué miras primero?").
  **Dos documentos vecinos no deberían tener el mismo reparto.**
- **Al menos una pregunta por capítulo enfrenta al lector con una sobregeneralización de
  entrevista** y le pide la versión precisa. Es el recurso pedagógico central del curso
  (§2) y tiene que aparecer también en la evaluación.
- **Sin respuesta en el documento, con solucionario centralizado.** Todas las respuestas,
  explicadas, viven en `26-respuestas.md`, agrupadas por documento y numeradas igual que
  la pregunta original (la pregunta 3 de `16` se responde en la entrada "16 → 3"), **y
  con el enunciado copiado literalmente**, no parafraseado: es lo que permite localizar
  una respuesta buscando el texto de la pregunta. Quien agregue, elimine o reordene una
  pregunta **debe reflejar el mismo cambio en `26-respuestas.md` en la misma edición**.
- **Las respuestas del solucionario van en tres capas**, heredadas del corpus de
  arquitectura porque funcionan para hablar en voz alta:

  ```text
  ⏱️ 30 segundos  → lo que dices primero, sin que te lo pidan
  🗣️ 2 minutos    → lo que añades cuando dicen "cuéntame más"
  🔬 El detalle   → para estudiar, no para decir en voz alta
  ```

  Las tres capas son obligatorias en las `P#` de `25` y en las preguntas de los
  capítulos que tocan decisiones de diseño. En preguntas de definición pura, la capa
  `🔬` puede omitirse si no aporta; nunca se omiten las dos primeras.
- **Orden libre**, por relevancia de entrevista, no correlativo a las secciones.

### 8.2 Ejercicios — solo en labs y apéndices

Van **después** de las preguntas rápidas y antes del cierre del documento.

- **Cantidad: 12 a 20 por lab y 8 a 12 por apéndice**, contando solo los obligatorios.
  Es una banda más alta que la del curso de AWS (10–16) por la razón inversa a la suya:
  allí cada intento costaba minutos y dinero, aquí un ciclo `./mvnw test` son segundos y
  no cuesta nada. La cifra concreta la decide el contenido, no la longitud.
- **La escala, completa.** Los cuatro primeros escalones son obligatorios y cuentan para
  la banda; los dos últimos no.

  | | Nivel | Qué pide |
  |---|---|---|
  | 🟢 | Fácil | Reproducir con otro valor lo que el lab acaba de mostrar |
  | 🟡 | Intermedio | Aplicar el mecanismo a otra clase, otro endpoint u otra propiedad |
  | 🟠 | Difícil | Combinar dos mecanismos, diagnosticar un fallo o decidir entre alternativas |
  | 🔴 | Muy difícil | Abierto o adversarial: se entrega algo roto y hay que razonarlo |
  | 🔥 | Extra | Ampliaciones fuera del alcance base |
  | 💀 | Boss fight | Encadena todo el lab —o toda la serie— en un solo encargo |

- **Reparto orientativo:** alrededor de 30 % 🟢, 30 % 🟡, 25 % 🟠 y 15 % 🔴, con un
  escalón de margen. Un lab que se pasa la mitad del tiempo rompiendo cosas a propósito
  carga hacia 🟠 y 🔴; un apéndice de referencia carga hacia 🟢 y 🟡. **Que dos documentos
  vecinos tengan idéntico reparto es señal de que el segundo se copió en vez de
  calibrarse.**
- **Regla propia de este curso: todo ejercicio declara cómo se comprueba.** Un test que
  pasa, un log que aparece, un endpoint que responde con un código concreto, una métrica
  que cambia. "Configura un `CacheManager`" a secas no es un ejercicio; "configura el
  `CacheManager` de forma que la segunda llamada no toque el repositorio, y demuéstralo
  con el contador de `inventory_repository_calls_total`" sí lo es.
- **Cada ejercicio cierra con su criterio.** Una línea **`Objetivo:`** con lo que hay que
  haber entendido, o una **`Pregunta:`** que solo se pueda contestar habiéndolo hecho.
- **Los ejercicios no van al solucionario.** `26-respuestas.md` es exclusivamente para
  las preguntas rápidas y las `P#` de `25`. Un ejercicio se verifica con su `Objetivo:`
  y con la salida real, y si necesita una respuesta modelo para tener sentido, es que
  estaba mal planteado y era una pregunta.
- **Enganchados al laboratorio.** Se usan los nombres del baseline de §5.3
  (`inv-api`, `inventory_item`, el perfil `local`), nunca `foo` ni "tu servicio".
- **El 💀 se decide, no se reparte.** Sale de preguntarse *"¿hay aquí un trabajo que solo
  se resuelva encadenando todo lo anterior?"*. Si lo hay, empieza con un sistema roto o
  un encargo completo, cruza al menos tres secciones y se entrega como artefacto —una
  clase, un test, un `docker-compose.yml`, un informe de diagnóstico—. Si al escribirlo
  te cabe en tres líneas, era un 🔴 con mejor nombre.
- **Exenciones declaradas.** Quedan fuera del aparato de ejercicios, y solo estas:
  `l00-idea-lab-practico.md`, que es el encuadre de la serie y no ejecuta nada;
  `26-respuestas.md`, que no lleva ni preguntas ni ejercicios; y el boss fight de `A02`
  —el catálogo de anotaciones—, que no existe a propósito porque es una ficha de
  referencia y no hay en ella ningún trabajo encadenable.
- **Formato**, con el conteo de obligatorios en el título:

  ```markdown
  ## 🧪 Ejercicios (14)

  ### 🟢 Fácil — …  (1–4)
  #### 🟢 Ejercicio 1 — …
  … enunciado …
  **Objetivo:** …

  ### 🟡 Intermedio — …  (5–9)
  ### 🟠 Difícil — …  (10–12)
  ### 🔴 Muy difícil — …  (13–14)
  ### 🔥 Opcionales y ampliaciones
  ### 💀 Boss fight — …
  ```

---

## 9. 🧷 Vocabulario visual: reglas y callouts

### 9.1 Regla o mnemotecnia (bloque `text`)

Para una asociación mental que vale la pena aislar, en especial con forma de comparación
o ecuación corta. Se etiqueta antes con una línea breve: "Regla:", "Regla mental:",
"Regla de entrevista:".

```text
misma clase  → no hay proxy  → no hay transacción, ni caché, ni retry
otro bean    → hay proxy     → la anotación hace lo que promete
```

### 9.2 Frase de respuesta correcta (blockquote `>`)

Para la única frase que un entrevistado debería decir en voz alta, normalmente después
de mostrar la simplificación incorrecta. Sirve igual para blindar contra la mala
respuesta ("Nunca respondas: > …") que para dar la buena ("Mejor: > …").

Prueba práctica: si cabe en una oración y corrige o fija un concepto, va en blockquote;
si es lista, ecuación o comparación de dos o más líneas, va en bloque `text`.

### 9.3 Callouts admitidos

Se usan en blockquote, con negrita en la etiqueta, y solo cuando aportan. Ninguno es
obligatorio en ningún documento.

- ⚠️ **Advertencia.** Ignorarlo rompe algo en producción o produce una respuesta de
  entrevista objetivamente incorrecta. Uso escaso; nunca decorativo.
- 🧠 **Modelo mental.** La frase que hay que llevarse, no el detalle.
- 💡 **Truco o atajo** que ahorra tiempo real (una propiedad que evita una clase de
  configuración, un slice de test que baja el arranque de 8 s a 1 s).
- 🩺 **Diagnóstico.** El comando, el log o el endpoint de Actuator que confirma o
  descarta una hipótesis.
- ⏱️ **Costo en runtime.** Lo que ese mecanismo consume, con su unidad y con qué lo
  dispara: hilos bloqueados, conexiones del pool, memoria retenida, milisegundos de
  arranque. **Obligatorio la primera vez que un documento introduce algo que bloquea un
  hilo, retiene una conexión o crece con la carga.** Es el equivalente exacto del 💰 del
  curso de AWS, y se toma igual de en serio.
- 📝 **Contexto.** Por qué Spring hace algo raro, qué cambió entre versiones —**en
  particular qué cambia en 4.x**— y por qué la respuesta "clásica" que el lector
  encuentre en una fuente vieja ya no aplica.
- 📚 **Referencia inline.** El enlace útil justo donde nace la duda, sin esperar al
  cierre.

**Escala de dificultad 🟢🟡🟠🔴🔥💀.** Se usa **solo** en la sección de ejercicios de labs y
apéndices (§8.2). Fuera de esa sección no aparece: un capítulo teórico no gradúa nada
porque no tiene ejercicios que graduar.

**Marcadores ✅ y ❌.** Se admiten como señal de sí/no dentro de tablas y de bloques
` ```text ` de comparación. Nunca como decoración en prosa ni en un encabezado.

Fuera de esta lista, de ✅/❌, de la escala de dificultad y de los emojis de encabezado de
§3, **no se usan otros emojis**. Nada de 🚨, 💸, ⭐ ni 🪦.

### 9.4 Autopsia de un fallo

Cuando un lab o el apéndice `A03` documenta un fallo real —y muchos lo hacen— la
estructura es:

1. **Síntoma**, con la salida literal: la primera línea de la excepción, el log, el
   código HTTP. Sin parafrasear.
2. **Qué lo provocó**, hasta la línea de código o la propiedad concreta.
3. **La hipótesis y cómo se confirma**: el log que se sube a `DEBUG`, el endpoint de
   Actuator que se consulta, el `conditions` report, el breakpoint.
4. **La corrección**, distinguiendo el parche que desbloquea hoy de la solución que uno
   haría con calma.
5. **La prevención**: el test, la propiedad o la regla de code review que evita la
   repetición.

Dos reglas de método atraviesan la serie práctica: **una variable a la vez** y
**reproducir antes de reparar**. Y los antipatrones se nombran sin piedad: `@Autowired`
en campo "para salir del paso", `@Transactional` en el controller, capturar `Exception`
para que "no truene", subir el tamaño del pool cuando el problema es un timeout ausente.

---

## 10. 📚 Bibliografía, referencias y enlaces

### 10.1 Enlaces externos

- **Solo documentación oficial** en la sección de referencias: `docs.spring.io`,
  `spring.io/projects/<proyecto>`, `spring.io/blog` para anuncios de release, las notas
  de versión del wiki de GitHub del proyecto y la documentación oficial de Java
  (`docs.oracle.com/en/java/javase/21/`). El curso no cita blogs de terceros, ni
  Baeldung, ni videos.
- **Cuidado con las cadenas de redirección de los terceros.** `docs.jboss.org/hibernate/…`
  responde `301` hacia `docs.hibernate.org`, y allí `Hibernate_User_Guide.html` vuelve a
  redirigir al directorio: la única URL con `200` directo es
  `https://docs.hibernate.org/orm/6.6/userguide/html_single/`. La regla operativa es
  **seguir la redirección con `-L`, quedarse con la URL final y escribir esa**, no la
  primera que te vino a la cabeza.
- **La documentación oficial del tercero cuando el tema es el tercero.** Resilience4j,
  Redisson, Testcontainers, Caffeine y Ehcache tienen su propia documentación oficial y
  se enlaza, pero **en una subsección aparte** —"Documentación de terceros"— nunca
  mezclada con la de Spring.
- **URLs completas y clicables**, nunca solo el dominio, y **una URL por concepto
  cubierto**, no un enlace genérico a la reference entera cuando existe la página
  específica. Si el capítulo explica propagación de transacciones, el enlace va a la
  sección de propagación, no a la portada de Data Access.
- **No se inventan URLs.** Un enlace que no se pudo verificar no se escribe: se cita el
  nombre exacto de la página y se deja el enlace al índice de la reference. Inventar una
  ruta plausible de `docs.spring.io` es el error más caro de este curso, porque parece
  correcta hasta que alguien la abre en una entrevista.

### 10.2 La trampa de versión de `docs.spring.io`

Esta es la regla propia más importante del curso en materia de enlaces, y sustituye a la
regla del `302` del curso de AWS.

**La documentación de Spring sí devuelve `404` en una página inexistente** —verificado:
`docs.spring.io/spring-boot/3.5/reference/no-existe.html` responde `404`—, así que un
enlace roto por ruta se detecta con el código de estado, como siempre. El problema es
otro y es más sutil:

> **Una URL sin versión responde `200` y sirve la línea actual, no la del curso.**
> `docs.spring.io/spring-boot/reference/index.html` devuelve `200` y entrega la
> documentación de **4.1.1**. El lector que la abre está leyendo otra versión sin
> enterarse, y lo que lea puede contradecir el capítulo.

De ahí la regla normativa:

- **Toda URL de `docs.spring.io` lleva la versión en la ruta**: `/spring-boot/3.5/…` y
  `/spring-framework/reference/6.2/…`. Un enlace sin versión es un enlace roto aunque
  responda `200`.
- **La verificación tiene dos pasos, no uno**: (1) el código de estado es `200`, y
  (2) la ruta contiene la versión del baseline. Comprobar solo lo primero deja pasar
  precisamente el error que esta sección existe para evitar.
- **`spring.io/projects/<nombre>` exige la barra final.** Sin ella responde `308` hacia
  la versión con barra: no es un enlace roto, pero un `curl -I` sin `-L` lo reporta como
  no-200 y hace perder el tiempo. Se escribe siempre con barra.
- **Cada proyecto de Spring se versiona por su cuenta, y la ruta lo refleja.** No hay una
  "versión del curso" que valga para todo: para el baseline de Boot 3.5.16 las rutas
  correctas son `/spring-data/jpa/reference/3.5/…` y `/spring-data/redis/reference/3.5/…`,
  pero **Spring Data MongoDB va por su propia línea, `4.5`**, y Spring HATEOAS por la suya
  (`/spring-hateoas/docs/2.5.x/…`). Coincidir el número con el de Boot es una suposición
  que falla la mitad de las veces: se comprueba la ruta real antes de escribirla. Dos
  trampas concretas ya encontradas: `/spring-data/jpa/reference/3.5/jpa/entity-graph.html`
  **no existe** —`@EntityGraph` se documenta dentro de `jpa/query-methods.html`— y Spring
  Data Commons no tiene página propia útil, así que los conceptos de repositorio se citan
  desde la ruta de JPA.
- **Alcance de la regla:** aplica a las referencias de **Spring Boot y Spring Framework**,
  que es donde el contenido cambia entre versiones y donde el curso fija un baseline. Los
  demás proyectos de `docs.spring.io` se fijan igual cuando ofrecen una ruta versionada;
  cuando no la ofrecen —**Spring Initializr**, cuya documentación vive en
  `/initializr/docs/current/` y se versiona con el servicio, no con Boot— se enlaza
  `current` y se dice aquí, que es lo que convierte una ambigüedad en una decisión.
- **Excepción declarada:** los enlaces del apéndice `A04` (migración 3.5 → 4.x) apuntan
  deliberadamente **fuera del baseline**, y lo dicen en el propio texto. Con un matiz que
  se descubrió al escribirlo: `docs.spring.io/spring-boot/4.1/…` responde `302` hacia la
  ruta sin versión, porque 4.1 **es** la línea corriente, así que `A04` escribe la URL
  final tras seguir la redirección —sin versión— y reserva la ruta versionada para lo ya
  archivado (`/4.0/`). Es la única excepción del curso a "versión en la ruta".

Verificación de los enlaces de un documento, en una línea:

```bash
awk '/^```/{f=!f;next} !f' 16-transacciones.md \
  | grep -oE 'https://[^)"`;, ]+' | sed 's/[.]$//' | grep -v '\.example' | sort -u | while read -r u; do
  printf '%s -> ' "$u"; curl -s -o /dev/null -w '%{http_code}\n' -I "$u"
done
```

- `grep -oE` extrae solo la URL, no el texto del enlace; el patrón corta en `)`, en
  comilla o en espacio, que son los tres finales posibles dentro de un enlace Markdown.
- `awk '/^```/{f=!f;next} !f'` deja fuera **todo lo que va dentro de un bloque de código**,
  y eso importa: el curso muestra a propósito URLs que fallan —la llamada a
  `start.spring.io` con el baseline del curso, que devuelve `400`— y verificarlas sería
  perseguir un error que el documento quiere enseñar.
- `grep -v '.example'` descarta las URLs de ejemplo restantes: `invlab.example` es un
  dominio reservado para documentación y nunca resuelve.
- `curl -I` pide solo las cabeceras: no descarga la página y basta para el código de
  estado **en la mayoría de los hosts**. Con dos excepciones que este curso ya se comió, y
  que producen falsos rotos: `projectreactor.io` devuelve `404` a un `HEAD` sobre páginas
  que existen, y `api.spring.io` devuelve `401`. Ante un fallo aislado en un dominio que
  no sea `docs.spring.io`, **repítelo con `GET`** —`curl -s -o /dev/null -w '%{http_code}' -L`—
  antes de dar el enlace por muerto.
- `-o /dev/null -w '%{http_code}'` deja la salida en una línea por URL, que es lo que se
  puede leer de un vistazo cuando son sesenta.

Y la comprobación de enlaces internos rotos dentro de la carpeta:

```bash
grep -oh '](\([0-9al][^)#]*\.md\)' *.md | sed 's/](//' | sort -u | while read -r f; do
  [ -f "$f" ] || echo "ROTO: $f"
done
```

Ese `grep` solo mira archivos. Las **anclas**, los enlaces que cruzan un salto de línea, las
URL de `docs.spring.io` sin versión y la sincronía de las 571 preguntas con el solucionario
los revisa el verificador del curso, desde la raíz:

```bash
python3 -B prompts/verificar-corpus.py
python3 -B prompts/verificar-corpus.py --corregir-fe0f
```

- `-B` evita que Python deje un `__pycache__` dentro de `prompts/`.
- La primera forma solo informa; termina con código 1 si hay algún `ERROR`. Lo que valida, y
  con qué código lo reporta, está en el docstring del script.
- `--corregir-fe0f` reescribe los enlaces que reportó como `ANCLA-FE0F` (§6.2) y vuelve a
  verificar. Es la única corrección automática: todo lo demás se arregla a mano.

### 10.3 Enlaces internos entre documentos

Son parte del producto, no un adorno, y hacen cumplir §4.7.

- **Formato:** enlace Markdown relativo al archivo, con el número del documento en el
  texto visible:

  ```markdown
  ver [`05` — proxies y AOP](05-proxies-y-aop.md)
  ```

- **Con ancla cuando la sección destino existe y es estable:**

  ```markdown
  [`16` §4 — `REQUIRES_NEW`](16-transacciones.md#4--requires_new)
  ```

- **Cada capítulo enlaza al menos a los dos documentos con los que más se toca**, y todo
  lab enlaza al capítulo teórico que sustenta lo que practica y al apéndice que lo
  complementa. `05` es el capítulo más enlazado del curso por diseño: casi todo lo
  declarativo remite ahí.
- **Al renombrar un archivo o un encabezado se revisan los enlaces entrantes en la misma
  edición.** Un enlace roto dentro del propio curso es peor que un enlace externo caído:
  el externo tiene disculpa, el interno no.

### 10.4 Vigencia

El README declara la fecha de revisión general y **cada documento la repite en su
blockquote de encabezado**, junto con la versión del baseline. Cuando un documento
incorpora algo que cambió entre versiones se marca con 📝 en el propio texto, para que
quien repasa sepa que puede no coincidir con las respuestas "clásicas" de fuentes más
viejas.

---

## 11. 🔗 Coherencia entre documentos

- **No contradecir documentos anteriores.** Si `05` establece que el proxy es lo que
  hace funcionar lo declarativo, `16` puede matizarlo (modo AspectJ), nunca
  contradecirlo.
- **Terminología estable.** Si `02` dice "bean definition", el resto del curso no lo
  llama "definición de bean" en un documento y "declaración" en otro.
- **Los labs son acumulativos y lo declaran.** Cada lab dice en su cabecera qué deja
  levantado y el siguiente asume exactamente ese estado. Si un lab rompe la cadena, lo
  dice explícitamente.
- **Los nombres y versiones del baseline de §5.2 y §5.3 mandan.** Cualquier desviación se
  declara con ⚠️ en el documento que la introduce.
- **Frontera con el resto del repositorio**, que es dura y se respeta en las dos
  direcciones:
  - `preguntas-entrevista/springboot/` cubre el repaso rápido con respuesta inline. Este
    curso **enseña el mecanismo** y no reproduce sus preguntas; se enlazan mutuamente.
  - `repaso-entrevistas/arquitectura/01-bases/` cubre la decisión de arquitectura (zero-trust,
    propagación de identidad, ventanas batch, CQRS). Este curso cubre **cómo lo hace
    Spring**. Security y Batch se explican aquí como mecanismo y allá como diseño, y cada
    lado enlaza al otro en vez de repetirlo.
  - `repaso-entrevistas/cloud/01-aws/` y `repaso-entrevistas/cloud/02-gcp/` cubren la infraestructura. Este
    curso no explica qué es un balanceador ni una cola administrada.
  - **`Entrevistas/` no se cita nunca.** Es material personal de búsqueda de empleo y
    este curso está pensado para publicarse. La frontera no se discute.
- **Fuentes de verdad, en orden:** (1) **esta guía**,
  que según la regla de precedencia de `CLAUDE.md` mandan sobre las normas por defecto
  del repositorio en todo lo que declaren explícitamente; (2) `CLAUDE.md` de la raíz,
  para todo lo que esta guía no toca; (3) `l00-idea-lab-practico.md` para el alcance y la
  doctrina de reparto de la serie práctica; (4) `README.md` para orden de lectura y mapa;
  (5) documentos ya publicados; (6) decisiones explícitas del chat actual.

---

## 12. ✅ Checklist antes de dar por cerrado un `.md`

- [ ] Sigue la plantilla de §6 (o está declarado como excepción: README, `25`, `26`, `l00`).
- [ ] Encabezado con objetivo, **`Vigencia:`** y versión del baseline; índice de salto rápido si pasa de ~400 líneas.
- [ ] Capítulo teórico entre 200 y 380 líneas (§4.6); si pasa de ~450, se partió y se renumeró.
- [ ] Tono semi formal y cálido, tuteo latinoamericano, humor casi ausente (§2).
- [ ] Emoji funcional en `##`, ninguno en `###`, y solo los callouts de §9.3.
- [ ] **Ningún bloque de código sin desglose** (§4.2): toda anotación, atributo y propiedad no obvia explicada.
- [ ] Para cada mecanismo declarativo está contestado **quién lo ejecuta, en qué hilo y a través de qué proxy** (§1).
- [ ] El problema se plantea antes que el mecanismo (§4.1) y cada decisión lleva su porqué (§4.3).
- [ ] Se nombra explícitamente al menos una sobregeneralización de entrevista y se da la versión precisa (§2).
- [ ] Sin prosa telegrama: una o dos frases aisladas por sección como mucho (§3).
- [ ] Tablas solo para comparar o mapear, máximo cuatro columnas, sin celdas que necesiten explicación.
- [ ] Baseline de §5.2 respetado; sin `latest`, sin rangos, sin tags de imagen sin fijar; nombres de §5.3 usados tal cual.
- [ ] Convenciones de código de §5.1: constructor, sin Lombok, `record` para DTOs, imports escritos cuando el import es el punto.
- [ ] Todo lo que bloquea un hilo, retiene una conexión o crece con la carga aparece con ⏱️ y su unidad (§9.3).
- [ ] Lo que cambia en 4.x está marcado con 📝 donde corresponde (§5.2).
- [ ] Stack traces y logs literales, sin editar el mensaje ni el nombre de la excepción (§3).
- [ ] En labs: estado inicial verificable, teardown junto al recurso, errores reproducidos antes de corregirlos, checklist de salida ejecutable y cierre con **🏁 La señal de que quedó bien**.
- [ ] Cierra con **Preguntas rápidas** (10–15; apéndices 6–12), sin respuestas, con reparto distinto al del documento vecino (§8.1).
- [ ] Si es lab o apéndice: **🧪 Ejercicios** graduados (12–20 en un lab, 8–12 en un apéndice), cada uno con su `Objetivo:` y su forma de comprobarse; 🔥 y 💀 fuera del conteo (§8.2).
- [ ] Si es lab: su longitud concuerda con el número de mecanismos de su ficha (≈200 líneas cada uno, §7.2); si no, la que se ajusta es la ficha.
- [ ] Si es capítulo teórico: **no lleva ejercicios**, solo preguntas.
- [ ] Si tocaste alguna pregunta, actualizaste `26-respuestas.md` en la misma edición, con el enunciado copiado literal y las tres capas de respuesta.
- [ ] Cierra con **Referencias oficiales**: URLs completas, verificadas por código de estado **y con la versión en la ruta** (§10.2); terceros en subsección aparte.
- [ ] Enlaces internos a los documentos con los que más se toca, y ningún enlace interno roto (§10.3).
- [ ] No contradice ningún documento anterior ni cruza la frontera con `Entrevistas/` (§11).
- [ ] Toda salida de un lab (stack trace, log, respuesta HTTP, número) salió de una ejecución real, o el lab está en la deuda de §13.1; ninguna salida nueva se escribe por inspección sin declararlo.
- [ ] Diagramas en ASCII, en bloque ` ```text ` (§3); ninguno se convierte a Mermaid sin pedido expreso.
- [ ] Ningún documento publicado cita `zz-code/`, un `_desechable-*` ni material de `Entrevistas/`.
- [ ] `python3 -B prompts/verificar-corpus.py` termina en **0 errores** (§10.2).

---

## 13. ⚖️ Excepciones declaradas a los lineamientos generales

Los lineamientos generales de producción de cursos y el `CLAUDE.md` del repositorio traen
**valores por defecto**, no techos. Este curso se escribió y se cerró antes de que esos
lineamientos existieran, y se ajustó a ellos el 2026-10-05 sin recrear nada: lo que hace
distinto está en esta tabla, para que ninguna sesión futura lo "arregle" de vuelta. Lo que
no está aquí se hereda tal cual.

| Regla general | Este curso | Por qué |
|---|---|---|
| Diagramas a criterio; Mermaid solo si se pide | **ASCII en ` ```text `, siempre** (§3) | El curso entero ya está así; ninguna sesión convierte diagramas por su cuenta |
| Callouts ⚠️ 🧠 💡 🩺 💰 📝 📚 | **⏱️ costo en runtime en lugar de 💰** (§9.3) | No hay factura: el recurso escaso es el hilo, la conexión y el arranque |
| Ningún emoji en `###` | la escala 🟢🟡🟠🔴🔥💀 sí va en los `###` y `####` de ejercicios (§3, §8.2) | Ahí el emoji **es** el dato |
| Banda de longitud del capítulo | **200–380 líneas**, con `01` (~415) y `20` (~440) como excepciones (§4.6) | §4.2 añade unas quince líneas de desglose por mecanismo |
| Preguntas por documento | 10–15 en capítulos y labs; **6–12 en apéndices**; **60 `P#` en `25`** (§8.1) | Los apéndices son de consulta; la simulación es un examen entero |
| Ejercicios graduados | **12–20 por lab, 8–12 por apéndice**; `L00` y `26` exentos (§8.2) | Un ciclo `./mvnw test` son segundos y no cuesta nada |
| Entrada del solucionario `**NN → n.** enunciado` | **`### NN → n`** con el enunciado en blockquote, y claves `L01`, `A01` para labs y apéndices (§8.1) | Formato del curso desde el primer capítulo; el verificador lo lee así |
| Alcance, propuesta, plan, diccionario, contrato y plantillas como documentos de `prompts/` | **dentro de esta guía**: §1 hace de alcance, §3 de diccionario, §5.2–§5.3 de contrato de nombres, §6–§7 de plantillas; `l00-idea-lab-practico.md` fija el alcance de la serie práctica | Curso cerrado: no se recrean documentos de producción (decisión de Oskar, 2026-10-05) |
| Ninguna salida inventada; casillas *escrita* y *corrida* | **labs `L01`–`L09`: salida esperada, sin correr** (§13.1) | Se escribieron sin una corrida registrada; la deuda se declara en vez de presentarlas como reales |
| Puertos de las pruebas: altos y aleatorios en `127.0.0.1` | el laboratorio publica los **puertos por defecto** (`8080`, `8081`, `5432`, `6379`, `27017`, `9090`, `3000`…) (§5.3); las pruebas de producción sobre él usan un `compose.override.yaml` con puertos altos (§13.1) | No es una excepción: los puertos altos son para las pruebas, y el curso puede quedarse con los que el lector reconoce (decisión de Oskar, 2026-10-05) |
| Un `.gitignore` central por curso | **no aplica** | El curso no versiona código: el proyecto `inv-api` lo crea el lector en su máquina |
| Código intermedio en `zz-code/` | sin directorio todavía; la sesión que salde §13.1 crea el suyo | El curso nunca lo cita |
| Autocontención | **editorial**: enlaza `preguntas-entrevista/`, `arquitectura/01-bases/` y `cloud/` como frontera (§11), y el README enlaza esta guía | Se resuelve al publicar el curso, con el perfil de publicación del verificador |
| `prompts/` | se conserva entero como referencia y no viaja al repositorio público | Decisión general del 2026-10-04 |
| Verificador del curso | `prompts/verificar-corpus.py`, subclase de `prompts/verificador_base.py`; sustituye a `verificar-anclas.py` y `verificar-preguntas.py` | Aprobado por Oskar el 2026-10-05 |
| Comentarios de código en español | sin cambios | — |

### 13.1 La deuda de ejecución de los labs

Las salidas de `L01`–`L09` —stack traces, logs de Hikari, respuestas HTTP, informes de
condiciones, cifras de métricas— se escribieron con el formato literal de §3, pero **ningún
documento registra que se hayan corrido**. Hasta que se corran, valen como *salida esperada,
sin correr*, y así lo dice el README.

- **No se edita ninguna salida de un lab por inspección.** Si una sesión toca un lab, deja la
  salida como está o la reemplaza por la de una corrida real; nunca por otra inventada.
- **La deuda se salda lab a lab**, en orden (son acumulativos), con el baseline de §5.2 y las
  imágenes fijadas en `L00`, y pegando la salida real donde difiera. Lo que el entorno no
  puede reproducir igual —ids, marcas de tiempo, PID, milisegundos— se deja y se declara en
  el propio lab.
- **La sesión que lo haga trabaja en `zz-code/`** con su propio directorio (logs y salidas en su
  `salidas/`; nada en el scratchpad), etiqueta sus
  contenedores con `curso=01-spring-boot`, publica en **puertos altos aleatorios** mediante un
  `compose.override.yaml` propio (sin tocar el Compose que enseña el lab) y, al terminar,
  borra sus contenedores con sus volúmenes y nada más.
- Al saldar un lab, se marca aquí con la fecha.

| Lab | Corrido |
|---|---|
| `L01`–`L09` | ⬜ |

### 13.2 Pendientes que afectan a esta guía

- **Publicación**: los enlaces a otros corpus (§11) y al `prompts/` desde el README se
  resuelven cuando el curso se publique como repositorio propio.
