# 01 — Spring, Boot y el ecosistema

> **Objetivo:** poder explicar qué aporta cada capa del ecosistema, qué hace Boot
> exactamente —y qué no hace—, y defender en una entrevista por qué tu proyecto corre
> sobre la versión que corre.
> **Asume:** Java, Maven y HTTP. Nada de Spring.
> **Vigencia:** 17 de septiembre de 2026 · Spring Boot 3.5.16 · Spring Framework 6.2.19 · Java 21.

---

**Salto rápido:** [El problema que resolvió Spring](#1--el-problema-que-resolvió-spring) · [Qué es Spring Framework](#2--qué-es-spring-framework) · [Qué añade Spring Boot, exactamente](#3--qué-añade-spring-boot-exactamente) · [Qué hay dentro de un starter](#4--qué-hay-dentro-de-un-starter) · [El BOM: por qué tu `pom.xml` no tiene versiones](#5--el-bom-por-qué-tu-pomxml-no-tiene-versiones) · [El jar ejecutable y el plugin de Maven](#6--el-jar-ejecutable-y-el-plugin-de-maven) · [El árbol de versiones: qué elige a qué](#7--el-árbol-de-versiones-qué-elige-a-qué) · [Soporte, EOL y por qué el baseline es una versión sin soporte OSS](#8--soporte-eol-y-por-qué-el-baseline-es-una-versión-sin-soporte-oss) · [El mapa del ecosistema](#9--el-mapa-del-ecosistema) · [Errores frecuentes](#10-️-errores-frecuentes) · [Preguntas rápidas](#-preguntas-rápidas) · [Referencias oficiales](#-referencias-oficiales)

---

## 1. 🧭 El problema que resolvió Spring

Hay una pregunta de entrevista que parece inofensiva y que separa a la gente de
inmediato: *"¿por qué existe Spring?"*. La respuesta floja es "para inyectar
dependencias". La buena empieza veinticinco años antes, en J2EE, donde un componente de
negocio tenía que **heredar de las clases del servidor** para existir: tu lógica de
transferencia extendía una clase de EJB, implementaba tres interfaces del contenedor y se
declaraba en dos descriptores XML. Eso se pagaba en tres monedas —no podías probar la
clase fuera del servidor, no podías moverla a otro sin reescribirla, y el negocio quedaba
enterrado bajo ceremonia—.

Spring propuso lo contrario: **tu clase es una clase normal**, sin heredar de nada, y un
contenedor externo la crea, la conecta con sus colaboradores y la envuelve con lo
transversal. El término de la época era POJO (*Plain Old Java Object*) y hoy suena obvio
precisamente porque Spring ganó.

> **🧠 Modelo mental.** Spring no es una librería que llamas. Es un contenedor que **te
> llama a ti**: tú declaras qué necesitas, él decide cuándo crearlo y qué envolverle
> alrededor. Todo lo demás del curso es consecuencia de esa inversión.

Eso explica el Framework. Pero Spring venció tan bien que veinte años después tenía el
problema opuesto: montar una aplicación nueva exigía elegir entre cuarenta módulos,
cuadrar versiones compatibles a mano y escribir doscientas líneas de configuración antes
del primer endpoint. **Ese** —y no la inyección de dependencias— es el problema que
resuelve Spring Boot.

---

## 2. 🧱 Qué es Spring Framework

Spring Framework es el núcleo, y se reparte en módulos que verás como artefactos en tu
`dependency:tree`: `spring-core` / `spring-beans` / `spring-context` son el contenedor
([`02`](02-contenedor-ioc-y-ciclo-de-vida.md)–[`04`](04-scopes-de-bean.md)), `spring-aop` los proxies ([`05`](05-proxies-y-aop.md)), `spring-web` y `spring-webmvc` el stack
servlet ([`08`](08-modelo-de-ejecucion-web.md), [`09`](09-rest-con-spring-mvc.md)), `spring-webflux` el reactivo ([`11`](11-webflux-y-reactor.md)), `spring-jdbc` / `spring-orm` /
`spring-tx` el acceso a datos y las transacciones ([`15`](15-datos-jdbc-jpa-mongo-y-redis.md), [`16`](16-transacciones.md)), `spring-context-support`
la caché y el scheduling ([`17`](17-cache.md), [`18`](18-asincronia-scheduling-y-eventos.md)), y `spring-test` el soporte de pruebas ([`24`](24-testing.md)).

Nunca los declaras uno a uno: llegan como dependencias transitivas de los starters. Y no
eliges su versión —**6.2.19** en nuestro baseline—: la arrastra la versión de Boot.

---

## 3. 🧱 Qué añade Spring Boot, exactamente

Esta es la pregunta que hay que poder contestar sin titubear, porque la respuesta
habitual —"Boot configura Spring automáticamente"— es cierta y no dice casi nada.

Boot aporta cinco cosas, y conviene saber nombrarlas por separado:

1. **Autoconfiguración.** Mira el classpath y las propiedades, y declara por ti los beans
   que escribirías a mano: un `DataSource` si ve un driver JDBC, un `ObjectMapper` si ve
   Jackson. Cómo se averigua **por qué** apareció un bean está en [`06`](06-arranque-y-autoconfiguracion.md).
2. **Starters.** Dependencias agrupadas por intención en lugar de por artefacto.
3. **Gestión de versiones.** Un BOM con ~250 librerías probadas en conjunto.
4. **Servidor embebido.** Tomcat dentro del jar: la aplicación arranca con `java -jar` en
   vez de desplegarse en un servidor externo. Eso es lo que hace viable un proceso por
   servicio, y con ello todo el modelo de contenedores.
5. **Capacidades de producción.** Actuator: health, métricas y diagnóstico sin escribir
   código ([`23`](23-actuator-y-observabilidad.md)).

Y ahora lo que **no** aporta, que es igual de importante:

> **⚠️ Boot no es un framework nuevo ni una versión nueva de Spring.** No tiene una sola
> anotación de negocio propia. `@Service`, `@Transactional`, `@GetMapping`,
> `@Autowired` y `@Cacheable` son todas de Spring Framework. Boot solo aporta las de
> arranque y configuración (`@SpringBootApplication`, `@ConfigurationProperties`,
> `@ConditionalOnClass`). Si le quitas Boot a tu aplicación, sigues escribiendo Spring;
> lo que pierdes es el arranque, no el modelo de programación.

Nunca respondas en una entrevista:

> ~~"Spring Boot es la versión moderna de Spring"~~

Mejor:

> "Spring Boot es una capa de opinión y arranque sobre Spring Framework: autoconfigura
> beans según el classpath, fija versiones compatibles y empaqueta el servidor. El modelo
> de programación sigue siendo el del Framework."

---

## 4. 🧱 Qué hay dentro de un starter

Un starter suena a magia hasta que lo abres. Vamos a abrirlo:

```bash
./mvnw dependency:tree -Dincludes=org.springframework.boot:spring-boot-starter-web
```

- `dependency:tree` imprime el árbol completo de dependencias resueltas, no solo las que
  tú declaraste. Es el comando con el que se resuelven los conflictos de versiones reales.
- `-Dincludes=<groupId>:<artifactId>` filtra el árbol a una rama. Sin el filtro, un
  proyecto Boot mediano imprime doscientas líneas y no encuentras nada.

La salida, podada a lo que importa:

```text
[INFO] +- org.springframework.boot:spring-boot-starter-web:jar:3.5.16:compile
[INFO] |  +- org.springframework.boot:spring-boot-starter-json:jar:3.5.16:compile
[INFO] |  +- org.springframework.boot:spring-boot-starter-tomcat:jar:3.5.16:compile
[INFO] |  \- org.springframework:spring-webmvc:jar:6.2.19:compile
```

Fíjate en lo que **no** hay: ninguna clase. Un starter es un `pom.xml` sin código —un
artefacto de tipo `pom`— cuyo único contenido es una lista de dependencias. Su valor es
que alguien ya decidió por ti que para "web" necesitas `spring-webmvc`, un servidor, un
serializador JSON y un validador, todos en versiones que conviven.

> **📝 Contexto.** El nombre importa y es una convención declarada: los starters oficiales
> se llaman `spring-boot-starter-*`. Los de terceros van al revés —`resilience4j-spring-boot3`,
> `mybatis-spring-boot-starter`— precisamente para que no parezcan oficiales.

> **📝 Qué cambia en 4.x.** Los starters se renombraron. `spring-boot-starter-web` pasó a
> llamarse **`spring-boot-starter-webmvc`**, y el `spring-boot-starter-test` único se
> partió por módulo: `spring-boot-starter-webmvc-test`, `spring-boot-starter-actuator-test`
> y compañía. No es cosmético: un `pom.xml` copiado de un proyecto 4.x a uno 3.5 falla al
> resolver, y al revés. [`A04` §5](a04-migracion-3-5-a-4-x.md#5--el-renombre-de-starters-y-el-diseño-modular) desarrolla la lista completa.

Eso deja en pie una confusión frecuente:

> Nunca respondas: ~~"el starter web trae Tomcat"~~. El starter **declara** una
> dependencia hacia `spring-boot-starter-tomcat`, que a su vez declara Tomcat. Por eso
> puedes cambiar de servidor excluyendo esa rama y añadiendo la de Jetty, sin tocar una
> línea de código.

---

## 5. 🧱 El BOM: por qué tu `pom.xml` no tiene versiones

Abre el `pom.xml` de cualquier proyecto Boot y verás algo que en Maven es inusual:
dependencias sin `<version>`.

```xml
<parent>
    <groupId>org.springframework.boot</groupId>
    <artifactId>spring-boot-starter-parent</artifactId>
    <version>3.5.16</version>
    <relativePath/> <!-- no busca el parent en el disco, va al repositorio -->
</parent>

<dependencies>
    <dependency>
        <groupId>org.springframework.boot</groupId>
        <artifactId>spring-boot-starter-web</artifactId>
        <!-- sin versión: la fija el BOM que hereda del parent -->
    </dependency>
</dependencies>
```

- **`spring-boot-starter-parent`** es un POM padre que hereda a su vez de
  `spring-boot-dependencies`, el **BOM** (*Bill of Materials*): una sección
  `dependencyManagement` con la versión exacta de unas 250 librerías del ecosistema —
  Jackson, Hibernate, Hikari, Lettuce, Flyway, Testcontainers, los drivers— probadas en
  conjunto contra esa release de Boot.
- **`<relativePath/>` vacío** evita que Maven busque el parent en el directorio superior
  del disco antes de ir al repositorio. Sin él, en un monorepo con otro `pom.xml` arriba,
  obtienes errores de resolución que no mencionan el parent.
- **La versión omitida** no es pereza: es la manera de decir "la que el BOM haya probado".
  Ponerla a mano es legítimo cuando necesitas un parche de seguridad antes que Boot, y es
  exactamente el momento en que asumes el riesgo de incompatibilidad que el BOM te
  evitaba.

Boot publica el mismo mecanismo como plugin de Gradle, con el BOM aplicado por
`io.spring.dependency-management`. El curso fija **Maven** porque es lo que hay en la banca
donde se dan estas entrevistas, y Gradle no vuelve a aparecer.

La alternativa, cuando ya tienes un parent corporativo —el caso normal en banca—, es
importar el BOM en vez de heredarlo:

```xml
<dependencyManagement><dependencies>
    <dependency>
        <groupId>org.springframework.boot</groupId>
        <artifactId>spring-boot-dependencies</artifactId>
        <version>3.5.16</version>
        <type>pom</type>
        <scope>import</scope>  <!-- trae el dependencyManagement, no hereda plugins -->
    </dependency>
</dependencies></dependencyManagement>
```

- **`<scope>import</scope>` con `<type>pom</type>`** inserta el `dependencyManagement`
  del BOM dentro del tuyo: es la única forma de "herencia múltiple" de versiones en Maven.
- **Lo que pierdes** es la configuración de plugins del `starter-parent` —el
  `spring-boot-maven-plugin` y el compilador ya ajustados—, que hay que declarar a mano.
  Es la razón de que un `pom.xml` corporativo sea más largo que el de un tutorial.

> **💡 Truco.** Para sobreescribir una versión del BOM, declara la propiedad que él usa en
> tu `<properties>` —`<jackson-bom.version>2.21.4</jackson-bom.version>`, con los nombres
> del [apéndice de versiones](https://docs.spring.io/spring-boot/3.5/appendix/dependency-versions/index.html)—.
> Cambiarla ahí, y no dependencia por dependencia, mantiene coherente el grupo entero.

---

## 6. 🧱 El jar ejecutable y el plugin de Maven

El empaquetado de Boot resuelve un problema viejo de Java: un jar normal no puede
contener otros jars y que el classloader los vea. Boot no pelea con eso, lo rodea.

```bash
./mvnw package
java -jar target/inv-api-0.0.1-SNAPSHOT.jar
```

- **`./mvnw package`** compila y empaqueta en `target/` sin tocar tu repositorio local de
  Maven; `install` haría lo mismo y además copiaría el artefacto a `~/.m2`, que solo hace
  falta cuando otro proyecto de tu máquina lo consume. El wrapper `./mvnw` fija la versión
  de Maven en el propio repositorio, así que no depende del Maven que tenga cada uno.
- **`java -jar`** arranca sin `-cp` ni nombre de clase porque los dos van dentro del jar:
  el `MANIFEST.MF` declara el `Main-Class`, y ahí está la diferencia con un jar corriente.

El artefacto que sale no es un jar corriente:

```text
inv-api-0.0.1-SNAPSHOT.jar
├── META-INF/MANIFEST.MF          Main-Class: org.springframework.boot.loader.launch.JarLauncher
│                                 Start-Class: com.invlab.invapi.InvApiApplication
├── org/springframework/boot/loader/…   el launcher de Boot (unos pocos KB)
└── BOOT-INF/
    ├── classes/                  tu código y tus recursos
    └── lib/                      las dependencias, como jars anidados
```

- **`Main-Class` no es tu clase.** El `MANIFEST` apunta al `JarLauncher` de Boot, que
  instala un classloader capaz de leer jars anidados y **después** invoca tu
  `Start-Class`. Por eso arranca con `java -jar` sin classpath explícito.
- **`BOOT-INF/lib/`** guarda las dependencias sin desempaquetar: es lo que hace el jar
  grande —40 a 80 MB es normal— y lo que lo vuelve autocontenido.
- **`repackage`**, del `spring-boot-maven-plugin`, es lo que convierte el jar normal de
  Maven en este. El original se conserva como `.jar.original`.

> **⏱️ Costo en runtime.** Ese modelo no es gratis: el `JarLauncher` abre y lee los jars
> anidados en el arranque, y eso son decenas o centenas de milisegundos según cuántas
> dependencias tengas. En una aplicación de escritorio daría igual; en un contenedor que
> escala bajo demanda, el arranque **es** latencia de usuario. Las dos respuestas a eso
> —layered jars para que la imagen se reconstruya por capas, y compilación AOT/native—
> se practican en [`L09`](l09-empaquetado-imagen-y-limpieza.md).

---

## 7. ⚖ El árbol de versiones: qué elige a qué

Aquí se caen muchas conversaciones, porque la gente elige la versión de Boot creyendo que
elige solo eso. En realidad elige tres cosas a la vez:

```text
Spring Boot 3.5.16
      │
      ├── arrastra ──► Spring Framework 6.2.19     (no lo eliges tú)
      ├── exige    ──► Java 17 … 25                (el curso fija 21 LTS)
      └── fija     ──► ~250 librerías del BOM      (Jackson, Hibernate, Hikari…)
```

Y con la línea actual, lo mismo con otros números:

| | Boot 3.5.16 (baseline del curso) | Boot 4.x (línea actual) |
|---|---|---|
| Spring Framework | 6.2.19 | 7.x |
| Java mínimo | 17 | 17 también: Framework 7 se compila a 17 |
| Namespace | `jakarta.*` | `jakarta.*` |
| Soporte OSS | **terminado el 30-jun-2026** | activo |

La regla práctica: **no se mezcla a mano**. Poner Framework 7 bajo Boot 3.5 "porque tiene
una mejora que necesito" es la vía rápida a un `NoSuchMethodError` en runtime, que es el
peor error posible porque compila sin quejarse.

> **🩺 Diagnóstico.** Si ves un `NoSuchMethodError` o un `NoClassDefFoundError` en el
> arranque después de tocar el `pom.xml`, el primer comando no es buscar el error en
> Google: es `./mvnw dependency:tree` para ver qué versión ganó de verdad. Maven resuelve
> los conflictos por **el camino más corto al raíz**, no por "la más nueva", y esa es la
> causa de la mitad de estos casos.

---

## 8. 🧭 Soporte, EOL y por qué el baseline es una versión sin soporte OSS

Esto no es trivia: es una pregunta de tech lead, y contestarla bien dice más de ti que
recitar anotaciones.

El calendario tiene dos relojes: el **soporte open source** de una línea menor dura
alrededor de un año desde su GA, y al terminar la línea pasa a **soporte comercial** —en
3.5, hasta 2032—, donde los parches existen pero se pagan.

```text
Boot 3.5.0 GA ──────────── 3.5.16 (25-jun-2026) ──┬── 30-jun-2026: fin del soporte OSS
                                                   └── soporte comercial hasta 2032
Boot 4.x      ──────────── línea actual, soporte OSS activo
```

**Por qué el curso se escribe sobre 3.5.16 igualmente:** es el código que hay en
producción en banca y el que vas a leer, tocar y discutir en una entrevista. Y por qué
eso no excusa ignorar 4.x: cada capítulo marca con 📝 lo que cambia en la línea actual, y
`A04` desarrolla la migración entera.

Y hay un coste operativo que se toca con las manos, no solo un riesgo de CVE:

```text
$ curl "https://start.spring.io/starter.zip?bootVersion=3.5.16&javaVersion=21&dependencies=web"
{"timestamp":"2026-09-18T02:24:13.458Z","status":400,"error":"Bad Request",
 "message":"Invalid Spring Boot version '3.5.16', Spring Boot compatibility range is >=4.0.0",
 "path":"/starter.zip"}
```

- **`bootVersion`, `javaVersion` y `dependencies`** son los tres parámetros de query que
  aceptan todos los endpoints de Initializr: la versión de Boot, la del JDK y la lista de
  starters separada por comas. `starter.zip` devuelve el proyecto entero; `pom.xml`, solo
  el descriptor, que es lo cómodo para comparar dos versiones.
- **El `400` no es un error tuyo**: el servicio valida `bootVersion` contra las líneas que
  ofrece hoy, y responde con el rango admitido en el propio cuerpo de la respuesta.

**Spring Initializr ya no genera proyectos sobre 3.5.** Solo ofrece las líneas con soporte
OSS vigente —hoy 4.0.8 y 4.1.1—, así que la herramienta oficial de scaffolding no te sirve
para tu propio baseline: hay que generar en 4.x y bajar el proyecto a mano, renombrando los
starters de paso. Ese es el primer peaje de vivir en una línea sin soporte, y se paga el
día uno. El procedimiento completo está en [`L01`](l01-esqueleto-cli-y-autoconfiguracion.md).

> **🧠 Modelo mental para la entrevista.** Cuando te pregunten en qué versión trabajas, la
> respuesta completa tiene tres partes: cuál usas, **si tiene soporte OSS o comercial**, y
> qué bloquea la migración. Alguien que dice "3.5" y se calla suena desactualizado.
> Alguien que dice "3.5.16, fuera de soporte OSS desde junio, con soporte comercial
> contratado, y la migración a 4 bloqueada por dos librerías internas" suena a tech lead.

---

## 9. 🧱 El mapa del ecosistema

Spring no es un producto, es una familia de proyectos con versiones propias. Saber de
quién es cada cosa evita el error de atribuirle a Boot lo que no es suyo:

| Proyecto | Qué resuelve | Capítulo |
|---|---|---|
| **Spring Framework** | El contenedor, MVC, WebFlux, transacciones, AOP | `02`–`05`, `08`–`18` |
| **Spring Boot** | Arranque, autoconfiguración, starters, Actuator | `06`, [`07`](07-configuracion-externalizada.md), `23` |
| **Spring Data** | Repositorios sobre JPA, Mongo, Redis, JDBC | `15` |
| **Spring Security** | Autenticación, autorización, OAuth2 | [`20`](20-spring-security-el-mecanismo.md), [`21`](21-identidad-federada-oauth2-oidc-y-jwt.md) |
| **Spring Batch** | Procesos por lotes reiniciables | [`22`](22-spring-batch.md) |
| **Spring HATEOAS** | Hipermedia y HAL | [`10` §10](10-diseno-de-api-validacion-errores-e-hipermedia.md#10--hateoas-qué-es-y-cuándo-paga) |
| **Spring Session** | Sesión fuera del servidor | `08` |
| **Spring Retry** | Reintentos declarativos — **archivado en `spring-attic`** | [`19`](19-resiliencia.md) |
| **Spring Cloud** | Config, Gateway, discovery, OpenFeign | fuera del curso (ver [`L00`](l00-idea-lab-practico.md)) |

Y dos que aparecen constantemente y **no son de Spring**, aunque todo el mundo lo crea:

- **Resilience4j** (circuit breaker, retry, bulkhead) es un proyecto independiente. Lo que
  Spring aporta es la integración, no la librería. Ver [`19` — resiliencia](19-resiliencia.md).
- **OpenFeign** es de la Cloud Native Computing Foundation; *Spring Cloud OpenFeign* es
  el envoltorio de Spring sobre él, y hoy está en mantenimiento. Ver [`13`](13-clientes-http.md).

---

## 10. ⚠️ Errores frecuentes

- **"Si uso Boot no puedo configurar nada a mano."** Al revés: casi toda la
  autoconfiguración está condicionada a `@ConditionalOnMissingBean`, es decir, **tu bean
  siempre gana**. El mecanismo está en `06`.
- **"Hay que estar siempre en la última versión."** En un banco, subir de línea mayor
  implica recertificar. La respuesta madura no es "actualiza": es "conozco mi ventana de
  soporte y tengo un plan con fecha".
- **"Boot hace la aplicación más lenta porque carga todo."** La autoconfiguración evalúa
  condiciones, no carga clases que no se usan. Lo que sí pesa en el arranque es el número
  de beans y de dependencias, y eso se mide — no se supone.

---

## 🧠 Preguntas rápidas

1. ¿Qué problema concreto de J2EE resolvió Spring, y por qué el término POJO era una
   bandera y no un detalle?
2. Nombra las cinco cosas que aporta Spring Boot y di cuál de ellas es responsable de que
   una aplicación arranque con `java -jar`.
3. ¿De qué proyecto es la anotación `@Transactional`: de Spring Framework o de Spring
   Boot? ¿Y `@ConditionalOnClass`?
4. ¿Qué hay dentro del artefacto `spring-boot-starter-web`?
5. ¿Por qué las dependencias de un `pom.xml` de Boot no llevan `<version>`, y qué tienes
   que hacer si tu empresa ya te impone un `<parent>` corporativo?
6. ¿Qué diferencia práctica hay entre heredar de `spring-boot-starter-parent` e importar
   `spring-boot-dependencies` con `scope=import`?
7. Un jar ejecutable de Boot tiene en su `MANIFEST` una `Main-Class` que no es tu clase.
   ¿Cuál es, y por qué hace falta?
8. ¿Quién decide la versión de Spring Framework que usa tu aplicación?
9. Te piden actualizar Jackson a un parche de seguridad antes de que Boot lo incorpore.
   ¿Cómo lo haces sin romper el resto del BOM, y qué riesgo asumes?
10. Aparece un `NoSuchMethodError` en el arranque después de tocar el `pom.xml`. ¿Cuál es
    el primer comando que corres y qué estás buscando en su salida?
11. ¿Qué significa que Spring Boot 3.5 esté fuera de soporte open source, y cómo
    contestarías en una entrevista a "¿en qué versión trabajan?"
12. ¿Resilience4j y OpenFeign son proyectos de Spring? ¿Qué aporta Spring en cada caso?

---

## 📚 Referencias oficiales

- Spring Boot 3.5 — Reference (índice): https://docs.spring.io/spring-boot/3.5/index.html
- Spring Boot 3.5 — System Requirements: https://docs.spring.io/spring-boot/3.5/system-requirements.html
- Spring Boot 3.5 — Build Systems y starters: https://docs.spring.io/spring-boot/3.5/reference/using/build-systems.html
- Spring Boot 3.5 — Versiones fijadas por el BOM: https://docs.spring.io/spring-boot/3.5/appendix/dependency-versions/index.html
- Spring Boot 3.5 — Formato del jar ejecutable: https://docs.spring.io/spring-boot/3.5/specification/executable-jar/index.html
- Spring Boot 3.5 — Maven Plugin: https://docs.spring.io/spring-boot/3.5/maven-plugin/index.html
- Spring Framework 6.2 — Overview: https://docs.spring.io/spring-framework/reference/6.2/overview.html
- Spring Boot — soporte y calendario de versiones: https://spring.io/projects/spring-boot/#support
- Spring Boot — Supported Versions (wiki): https://github.com/spring-projects/spring-boot/wiki/Supported-Versions
