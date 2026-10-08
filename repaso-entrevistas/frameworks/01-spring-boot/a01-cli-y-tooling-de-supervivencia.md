# A01 — CLI y tooling de supervivencia

> **Objetivo:** que nunca pierdas veinte minutos buscando cómo se pasaba un profile, cómo
> se saca un thread dump sin Actuator o por qué `-D` en la línea de Maven no llega a tu
> aplicación. Es material de consulta: se abre por la sección que necesitas y se cierra.
> **Asume:** nada. Cada sección es autosuficiente.
> **Vigencia:** 17 de septiembre de 2026 · Spring Boot 3.5.16 · Spring Framework 6.2.19 · Java 21 (Temurin) · macOS/Linux · comandos verificados ese día.

**Salto rápido:** [Cómo se usa](#1--cómo-se-usa-este-apéndice) ·
[Generar el proyecto](#2--generar-el-proyecto-desde-la-terminal) ·
[Spring Boot CLI](#3--spring-boot-cli) ·
[Maven de supervivencia](#4--maven-de-supervivencia) ·
[Conflictos de versión](#5--el-árbol-de-dependencias-y-un-conflicto-real) ·
[Versiones viejas](#6--qué-versiones-se-te-quedaron-viejas) ·
[Arrancar desde Maven](#7--arrancar-la-aplicación-desde-maven) ·
[El plugin de Boot](#8--el-plugin-de-maven-de-spring-boot) ·
[Herramientas del JDK](#9--las-herramientas-del-jdk) ·
[`curl` y `jq`](#10--hablar-con-la-api-y-con-actuator) ·
[Leer un stack trace](#11--cómo-leer-un-stack-trace-de-spring) ·
[Docker Compose](#12--docker-compose-de-supervivencia) ·
[Atajos de depuración](#13--atajos-de-depuración) ·
[Errores frecuentes](#14-️-errores-frecuentes-de-tooling) ·
[Preguntas rápidas](#-preguntas-rápidas) ·
[Ejercicios](#-ejercicios-10)

---

## 1. 🧭 Cómo se usa este apéndice

Hay dos clases de conocimiento de Spring. Una se explica y se discute —el contenedor, los
proxies, las transacciones— y vive en los capítulos. La otra no se discute: o la tienes en
los dedos o te cuesta media hora cada vez que la necesitas. Cuál es el flag para saltarse
los tests, cómo se le pasa un profile a `spring-boot:run`, qué comando saca un thread dump
cuando Actuator está cerrado en producción.

Este apéndice es la segunda clase. **No tiene orden ni prerrequisitos**: cada sección se
lee sola, empieza por el problema que resuelve y termina con el comando que corre.

Todos los ejemplos usan los nombres fijos del laboratorio —el servicio `inv-api`, el
paquete `com.invlab.invapi`, el puerto `8080` para la aplicación y el `8081` para
Actuator, el proyecto de Compose `inv-lab`—, que están declarados en
[`L00`](l00-idea-lab-practico.md#7--nombres-fijos-de-la-serie). Cuando pruebes esto en tu
proyecto real, cambia los nombres y nada más.

> **🧠 Modelo mental.** El tooling de Spring Boot no tiene magia propia: `spring init` es
> un `curl` a un servicio HTTP, `spring-boot:run` es un `java -jar` en un proceso aparte,
> y `jstack` es lo mismo que `/actuator/threaddump` sin pedirle permiso a la aplicación.
> Saber qué hay debajo de cada herramienta es lo que te permite reemplazarla cuando la
> máquina donde estás no la tiene.

---

## 2. 🧱 Generar el proyecto desde la terminal

La página de `start.spring.io` está muy bien hasta que necesitas generar el mismo proyecto
veinte veces con los mismos parámetros, o documentar en un README cómo se creó el
esqueleto. Lo que casi nadie sabe es que **la página es solo un frontend**: el servicio es
una API HTTP que responde a un `GET` corriente.

```bash
curl -s "https://start.spring.io/starter.zip\
?type=maven-project\
&bootVersion=4.1.1\
&javaVersion=21\
&language=java\
&packaging=jar\
&groupId=com.invlab\
&artifactId=inv-api\
&name=inv-api\
&packageName=com.invlab.invapi\
&version=0.0.1-SNAPSHOT\
&configurationFileFormat=yaml\
&dependencies=web,actuator,validation" -o inv-api.zip && unzip -q inv-api.zip -d inv-api
```

- **`starter.zip`** devuelve el proyecto entero comprimido. Hay tres hermanos que sirven
  para otras cosas: `pom.xml` devuelve **solo** el POM en texto plano —ideal para mirarlo
  sin descargar nada—, `build.gradle` hace lo propio con Gradle, y la raíz `/` devuelve la
  ayuda completa en texto, que es la documentación más rápida que existe de este servicio.
- **`type=maven-project`** es lo que decide build y formato. El valor por defecto del
  servicio es `gradle-project`, así que **si no lo pones te llevas un proyecto Gradle**, y
  el curso usa Maven ([`01`](01-spring-boot-y-el-ecosistema.md)).
- **`bootVersion`** fija la línea de Boot. Si lo omites te dan la última estable.
- **`javaVersion=21`** es el *language level*, no el JDK con el que compilas. El defecto
  del servicio es `18`.
- **`groupId` / `artifactId` / `packageName`** son independientes: `artifactId` da nombre
  al jar y al directorio, `packageName` al paquete raíz. Si no pasas `packageName`, se
  deduce de los otros dos y te puede salir algo como `com.invlab.invapi` con guiones
  convertidos a la fuerza.
- **`configurationFileFormat=yaml`** genera `application.yaml` en vez del
  `application.properties` por defecto. Es un parámetro reciente y te ahorra convertir el
  fichero a mano; el renombrado sí queda pendiente, porque el servicio escribe `.yaml` y
  **la serie usa `application.yml`** ([`07`](07-configuracion-externalizada.md)). Las dos
  extensiones las carga Boot igual: la convención es nuestra, no suya.
- **`dependencies`** es una lista separada por comas de **identificadores del servicio**,
  no de `artifactId` de Maven: se escribe `web`, no `spring-boot-starter-web`. La lista
  completa sale con `curl -s https://start.spring.io` y también por API en
  `https://start.spring.io/dependencies?bootVersion=4.1.1`.
- **`-s`** silencia la barra de progreso de `curl`, que si no ensucia la salida; **`-o`**
  escribe a fichero en vez de a `stdout`, que con un ZIP es obligatorio.
- **Las barras invertidas al final de línea** son solo para que la URL quepa legible en el
  documento: la URL no puede llevar saltos de línea reales.

### El detalle que te va a morder

El baseline del curso es Boot 3.5.16, y esto es lo que pasa hoy si lo pides:

```bash
curl -s "https://start.spring.io/pom.xml?type=maven-project&bootVersion=3.5.16&javaVersion=21"
```

```text
{"timestamp":"2026-09-18T02:09:59.868Z","status":400,"error":"Bad Request","message":"Invalid Spring Boot version '3.5.16', Spring Boot compatibility range is >=4.0.0","path":"/pom.xml"}
```

> **⚠️ Initializr solo genera la línea con soporte OSS.** Como 3.5 salió de soporte open
> source el 30 de junio de 2026, el servicio **rechaza** `bootVersion=3.5.16` con un `400`,
> no con un aviso. Para trabajar sobre el baseline del curso se genera con la versión
> actual y se baja el `<parent>` a `3.5.16` a mano. Y hay un segundo cambio que hay que
> hacer en el mismo momento: en 4.x el starter web pasó a llamarse
> `spring-boot-starter-webmvc`, y en 3.5 sigue siendo `spring-boot-starter-web`. Si copias
> el POM generado tal cual, obtienes un error de resolución de dependencias que no
> menciona ni a Boot ni a la versión.

```xml
<parent>
    <groupId>org.springframework.boot</groupId>
    <artifactId>spring-boot-starter-parent</artifactId>
    <version>3.5.16</version>   <!-- generado como 4.1.1; se baja a mano -->
    <relativePath/>
</parent>
```

- **Bajar la versión del `<parent>`** basta para mover todo el BOM: ese POM padre es el que
  fija las ~250 versiones del ecosistema ([`01` §5](01-spring-boot-y-el-ecosistema.md)).
- **Después hay que revisar los `artifactId`** de las dependencias generadas, porque los
  nombres de los starters de test también cambiaron en 4.x
  (`spring-boot-starter-webmvc-test` no existe en 3.5; ahí se usa
  `spring-boot-starter-test`).

> **📝 Contexto.** Esto va a empeorar, no a mejorar: cada vez que una línea sale de soporte
> deja de poder generarse en Initializr. En un banco con servicios en 3.5 la consecuencia
> práctica es que **el esqueleto de un servicio nuevo no se genera, se clona** de un
> arquetipo interno. Si te preguntan en una entrevista cómo arrancarías un microservicio
> nuevo en la plataforma actual, esa es la respuesta madura.

---

## 3. 🧱 Spring Boot CLI

El CLI es un binario independiente de tu proyecto. No lo necesitas para nada del día a
día, pero hace dos cosas que ahorran tiempo real.

```bash
sdk install springboot 3.5.16          # con SDKMAN!
brew tap spring-io/tap && brew install spring-boot   # con Homebrew, en macOS
spring version
```

- **SDKMAN!** instala la versión exacta que le pidas y te deja cambiar entre ellas con
  `sdk use springboot <version>`. Es la vía recomendada por la documentación y la única
  que te permite tener el CLI de 3.5 y el de 4.x a la vez.
- **Homebrew** instala la última y punto, que para `encodepassword` da igual y para
  `init` importa poco porque el trabajo lo hace el servidor.
- **`spring version`** imprime `Spring CLI v3.5.16` y es cómo verificas que instalaste lo
  que creías.

### `spring init`

Es exactamente el `curl` de la sección anterior, con nombres de opción en vez de
parámetros de URL y con el ZIP ya descomprimido:

```bash
spring init --build=maven --java-version=21 \
  --group-id=com.invlab --artifact-id=inv-api --name=inv-api \
  --package-name=com.invlab.invapi \
  --dependencies=web,actuator,validation \
  inv-api
```

- **`--build=maven`** hace lo mismo que `type=maven-project`; el defecto del CLI **sí** es
  `maven`, al revés que el de la API HTTP. Es una inconsistencia real y hay que conocerla.
- **`--dependencies` / `-d`** usa los mismos identificadores del servicio.
- **El último argumento, `inv-api`, es la ubicación**: si no lleva extensión, el CLI
  entiende que es un directorio y **extrae ahí** el proyecto. Con `inv-api.zip` te deja el
  archivo comprimido.
- **`--list`** imprime todas las capacidades del servicio —dependencias, tipos, versiones
  disponibles— sin generar nada. Es la forma de averiguar el identificador correcto de una
  dependencia sin abrir el navegador.
- **`--target`** apunta a otro Initializr. En banca es habitual tener uno interno con los
  starters corporativos ya declarados, y esta es la opción que lo usa.
- **No hay `--boot-version` en el ejemplo, y es deliberado.** Pedir
  `--boot-version=3.5.16` a `start.spring.io` devuelve hoy `400 Bad Request` por lo mismo de
  la sección anterior —el servicio solo ofrece la línea que soporta en ese momento—, y el
  CLI es un cliente: reenvía el parámetro y te entrega el error. Sin el flag, el servicio
  genera con la versión que ofrezca por defecto y tú ajustas el `<version>` del
  `spring-boot-starter-parent` en el `pom.xml` al baseline del curso.

### `spring encodepassword`

El problema: necesitas una contraseña codificada para una configuración de Spring Security
—un usuario en memoria, una semilla de base de datos, una prueba— y escribir un `main()`
que instancie un `BCryptPasswordEncoder` para imprimir una línea es absurdo.

```bash
spring encodepassword 'inv_lab'
```

```text
{bcrypt}$2a$10$KJ4H1.5uUiCvLQ7vHFvQqeFqZbB6KJk1ZUbKsN7tOiGEwJn3Xx2fG
```

- **El prefijo `{bcrypt}`** no es decoración: es lo que lee el `DelegatingPasswordEncoder`
  de Spring Security para saber con qué algoritmo verificar. Si lo recortas al pegar el
  valor, obtienes un fallo de autenticación sin mensaje útil.
- **El hash cambia en cada ejecución** aunque la contraseña sea la misma, porque bcrypt
  incluye una sal aleatoria. Dos ejecuciones que dan resultados distintos no es un bug.
- **`$2a$10$`** dice la variante y el *cost factor* 10, que son 2¹⁰ iteraciones. Subirlo
  encarece el login a propósito, y es una decisión de seguridad, no de tooling.
- **Comillas simples alrededor de la contraseña**: sin ellas, `$`, `!` y `*` los interpreta
  tu shell y codificas algo distinto de lo que escribiste.

> **📝 El CLI no sobrevivió a la línea 4.x.** `docs.spring.io/spring-boot/4.1/cli/` ya no
> existe: redirige. Si tu equipo dependía de `spring encodepassword` en algún script, el
> reemplazo es escribir las cuatro líneas de `BCryptPasswordEncoder` a mano o usar el
> soporte del propio IdP.

---

## 4. 🧱 Maven de supervivencia

El wrapper es la primera regla y no es una preferencia de estilo:

```bash
./mvnw -v
```

- **`./mvnw`** es un script versionado en tu repositorio que descarga la versión de Maven
  declarada en `.mvn/wrapper/maven-wrapper.properties` y ejecuta con esa. **`mvn` a secas
  usa la que haya instalado en la máquina**, que no es la misma en tu portátil que en el
  agente de CI, y esa diferencia es una fuente clásica de "en mi máquina compila".
- **En Windows el fichero es `mvnw.cmd`**; en macOS y Linux hay que asegurarse de que
  `mvnw` conserve el bit de ejecución al pasar por Git (`git update-index --chmod=+x mvnw`
  si se perdió).

Y estos son los flags que se usan de verdad:

| Flag | Qué hace | Cuándo importa |
|---|---|---|
| `-q` | Solo errores y la salida de la aplicación | Ver el log de Boot sin las 40 líneas de Maven |
| `-o` | Modo offline: no consulta la red | Sin conexión, o para descartar que el problema sea el repositorio |
| `-U` | Fuerza refrescar SNAPSHOTs y metadatos | Cuando una dependencia interna "no se actualiza" |
| `-e` | Añade el stack trace del fallo de Maven | Cuando el mensaje de Maven no dice nada |

```bash
./mvnw -q test
./mvnw -q package -DskipTests
./mvnw clean verify
```

- **`-q` (quiet)** deja pasar `ERROR` y lo que escriba tu aplicación, y silencia el resto.
  Es lo que convierte `./mvnw test` en algo legible. El precio: si la compilación falla por
  un aviso, no lo ves.
- **`-DskipTests` compila los tests y no los ejecuta.** Es lo que quieres el 95 % de las
  veces, porque sigue detectando que un test dejó de compilar tras un refactor.
- **`-Dmaven.test.skip=true` ni siquiera los compila.** Es más rápido y es la opción
  peligrosa: un cambio de firma que rompe la suite entera pasa el build sin decir nada.
- **`verify` incluye a `package`, que incluye a `test`, que incluye a `compile`.** El ciclo
  de Maven es acumulativo, así que `./mvnw clean verify` ejecuta todo lo anterior y añade
  los tests de integración del `failsafe`. Pedir `./mvnw clean test package` es redundante.
- **`clean` borra `target/`.** No es gratis: obliga a recompilar todo. Se usa cuando
  sospechas de artefactos viejos —un recurso renombrado que sigue en `target/classes`—, no
  por costumbre.

> **⚠️ Una sobregeneralización que cuesta caro.** "`-DskipTests` es lo mismo que
> `-Dmaven.test.skip`" es falso, y la diferencia se paga en CI: con el segundo, el pipeline
> empaqueta y despliega un artefacto cuyos tests **ni siquiera compilan**. Si ves
> `-Dmaven.test.skip=true` en un `Jenkinsfile`, eso es un hallazgo de code review.

---

## 5. 🩺 El árbol de dependencias y un conflicto real

El síntoma es siempre el mismo y es de los peores que hay, porque **compila**: la
aplicación arranca —o no— y revienta con un `NoSuchMethodError` o un
`NoClassDefFoundError` sobre una clase que tú no tocaste.

```text
java.lang.NoSuchMethodError: 'void com.fasterxml.jackson.databind.ObjectMapper.<init>(com.fasterxml.jackson.core.JsonFactory)'
```

Eso significa que en el classpath hay **una versión distinta** de la que se compiló. El
primer comando no es buscar el error en internet:

```bash
./mvnw -q dependency:tree -Dincludes=com.fasterxml.jackson.core:jackson-databind
```

```text
[INFO] com.invlab:inv-api:jar:0.0.1-SNAPSHOT
[INFO] +- org.springframework.boot:spring-boot-starter-web:jar:3.5.16:compile
[INFO] |  \- org.springframework.boot:spring-boot-starter-json:jar:3.5.16:compile
[INFO] |     \- com.fasterxml.jackson.core:jackson-databind:jar:2.21.4:compile
[INFO] \- com.invlab.platform:corporate-audit-client:jar:4.2.0:compile
[INFO]    \- com.fasterxml.jackson.core:jackson-databind:jar:2.13.4:compile
```

- **`dependency:tree`** imprime el árbol **resuelto**, no lo que tú declaraste. Es la única
  fuente de verdad sobre qué jar va a estar en el classpath.
- **`-Dincludes=<groupId>:<artifactId>`** poda el árbol a una rama. Sin el filtro, un
  proyecto Boot mediano imprime doscientas líneas y el conflicto se pierde dentro.
- **Dos ramas con el mismo artefacto y distinta versión** es el diagnóstico. Aquí Jackson
  llega por dos caminos: el BOM de Boot lo fija en 2.21.4, y una librería interna arrastra
  2.13.4.

Para ver **cuál ganó y por qué**, hay que pedir el modo detallado:

```bash
./mvnw -q dependency:tree -Dverbose -Dincludes=com.fasterxml.jackson.core:jackson-databind
```

```text
[INFO] +- com.fasterxml.jackson.core:jackson-databind:jar:2.21.4:compile
[INFO] \- com.invlab.platform:corporate-audit-client:jar:4.2.0:compile
[INFO]    \- (com.fasterxml.jackson.core:jackson-databind:jar:2.13.4:compile - omitted for conflict with 2.21.4)
```

- **`-Dverbose`** incluye los nodos **omitidos**, que en el modo normal no se imprimen. La
  línea `omitted for conflict with 2.21.4` es literalmente la respuesta a "¿qué pasó con mi
  versión?".
- **Maven resuelve por *nearest wins*: gana la declaración más cercana a la raíz**, no la
  más nueva. Es la regla que más gente tiene al revés en la cabeza, y explica por qué a
  veces gana una versión vieja: si tu `pom.xml` declara directamente `jackson-databind`
  2.13.4, esa está a distancia 1 y le gana a la 2.21.4 que llega a distancia 3 por el BOM.

Las dos correcciones, y no son intercambiables:

```xml
<!-- 1. excluir la rama que sobra, quirúrgico -->
<dependency>
    <groupId>com.invlab.platform</groupId>
    <artifactId>corporate-audit-client</artifactId>
    <version>4.2.0</version>
    <exclusions>
        <exclusion>
            <groupId>com.fasterxml.jackson.core</groupId>
            <artifactId>jackson-databind</artifactId>
        </exclusion>
    </exclusions>
</dependency>
```

```xml
<!-- 2. fijar la versión para todo el proyecto, global -->
<properties>
    <jackson-bom.version>2.21.4</jackson-bom.version>
</properties>
```

- **La exclusión** quita esa dependencia de esa rama concreta. Es precisa y es frágil: si
  mañana otra librería arrastra la misma versión vieja, vuelve el problema y la exclusión
  no lo cubre.
- **La propiedad del BOM** cambia la versión para **todo el grupo de artefactos** de esa
  librería, que es lo que quieres con Jackson, donde `core`, `databind` y `annotations`
  tienen que ir a juego. Los nombres de propiedad están en el apéndice de versiones de la
  documentación de Boot.
- **Lo que no se hace**: añadir la dependencia con `<version>` suelta en tu `pom.xml`
  "para que gane". Funciona por la regla de cercanía, y es exactamente el mecanismo que te
  dejará atrás la próxima vez que subas de versión de Boot, sin aviso.

---

## 6. 🧱 Qué versiones se te quedaron viejas

En una revisión de dependencias, o antes de una auditoría de seguridad, lo que necesitas no
es el árbol sino el retraso:

```bash
./mvnw versions:display-dependency-updates
./mvnw versions:display-plugin-updates
./mvnw versions:display-property-updates
```

```text
[INFO] The following dependencies in Dependencies have newer versions:
[INFO]   org.postgresql:postgresql ................................ 42.7.4 -> 42.7.5
[INFO]   org.projectlombok:lombok ..................................  1.18.34 -> 1.18.36
```

- **`versions:display-dependency-updates`** consulta el repositorio remoto y lista lo que
  tiene versión más nueva. **No modifica nada**: solo imprime.
- **`display-plugin-updates`** hace lo mismo con los plugins del build, que es donde nadie
  mira y donde viven la mitad de los avisos de seguridad de un pipeline.
- **`display-property-updates`** es el importante en un proyecto Boot: como las versiones
  llegan por propiedades del BOM, las dependencias sin `<version>` propia no aparecen en el
  primer informe. Esta meta sí mira las propiedades.
- **El plugin no viene en el BOM de Boot**: es `versions-maven-plugin` de MojoHaus, y por
  eso se invoca con el prefijo corto `versions:` solo si tu Maven lo resuelve por
  convención. Si falla, se escribe completo:
  `org.codehaus.mojo:versions-maven-plugin:display-dependency-updates`.

> **⚠️ En un proyecto Boot, subir dependencias una por una es un error.** Lo que sube es la
> versión de Boot, y el BOM arrastra el conjunto **probado**. Actualizar Jackson a mano por
> encima del BOM es legítimo solo como parche de seguridad urgente, y asumiendo el riesgo
> de incompatibilidad que el BOM existía para evitar
> ([`01` §5](01-spring-boot-y-el-ecosistema.md)).

---

## 7. 🧱 Arrancar la aplicación desde Maven

```bash
./mvnw spring-boot:run
./mvnw spring-boot:run -Dspring-boot.run.profiles=local
./mvnw spring-boot:run -Dspring-boot.run.arguments="--server.port=8082,--seed=true"
./mvnw spring-boot:run -Dspring-boot.run.jvmArguments="-Xmx512m -XX:+HeapDumpOnOutOfMemoryError"
```

- **`spring-boot:run`** compila y arranca la aplicación **en un proceso hijo, no en el de
  Maven**. Esa frase es toda la sección: la documentación lo dice literalmente —*"The
  application is executed in a forked process"*— y de ahí salen las tres propiedades
  siguientes.
- **`-Dspring-boot.run.profiles=local`** activa perfiles de Spring. Es un atajo declarado
  de `-Dspring-boot.run.jvmArguments="-Dspring.profiles.active=local"`. Con varios perfiles
  se separan por comas: `=local,debug`.
- **`-Dspring-boot.run.arguments`** son los argumentos de **tu `main()`**: lo que en un
  `java -jar` escribirías detrás del jar. Van con `--` delante y, en línea de comandos, **se
  separan por comas**, no por espacios. Esto alimenta el `Environment`
  ([`07`](07-configuracion-externalizada.md)) y es la vía correcta para sobreescribir una
  propiedad al vuelo.
- **`-Dspring-boot.run.jvmArguments`** son los argumentos de la **JVM hija**: memoria,
  agentes, propiedades de sistema. Aquí van `-X…`, `-XX:…` y `-D…`.

Y ahora la confusión que hace perder más tiempo del que parece:

```text
./mvnw spring-boot:run -Dserver.port=8082
        └─ llega a la JVM de Maven, NO a tu aplicación  →  sigue en 8080

./mvnw spring-boot:run -Dspring-boot.run.arguments="--server.port=8082"
        └─ llega al main() de tu aplicación             →  arranca en 8082

./mvnw spring-boot:run -Dspring-boot.run.jvmArguments="-Dserver.port=8082"
        └─ llega a la JVM hija como propiedad de sistema →  arranca en 8082
```

- **La primera forma es la que todo el mundo escribe primero** y no produce ningún error:
  la aplicación arranca tan tranquila en el puerto de siempre, y te pasas diez minutos
  convencido de que tu `application.yml` está mal.
- **`arguments` y `jvmArguments` funcionan las dos** para una propiedad de configuración,
  porque ambas fuentes están en la cadena de precedencia del `Environment`. Los argumentos
  de línea de comandos tienen prioridad más alta que las propiedades de sistema, detalle
  que importa cuando las dos están puestas a la vez.
- **Para un agente, un `-Xmx` o un `-agentlib`, solo sirve `jvmArguments`**: eso no es
  configuración, es la JVM.

> **💡 Truco.** Si vas a repetir el mismo arranque veinte veces, no pelees con las comillas:
> `export MAVEN_OPTS` no sirve (afecta a Maven, no al hijo), pero `SPRING_PROFILES_ACTIVE=local
> ./mvnw spring-boot:run` sí, porque las variables de entorno **se heredan** al proceso hijo
> y Boot las mapea a propiedades con la regla de *relaxed binding* de
> [`07`](07-configuracion-externalizada.md).

---

## 8. 🧱 El plugin de Maven de Spring Boot

Cuatro metas, cuatro trabajos distintos, y solo una de ellas está atada al ciclo de vida
por defecto.

| Meta | Qué produce | Cuándo se ejecuta |
|---|---|---|
| `spring-boot:run` | Nada; arranca la app | A mano, en desarrollo |
| `spring-boot:repackage` | El jar ejecutable | Atada a `package` por el parent |
| `spring-boot:build-image` | Una imagen OCI | A mano o en CI |
| `spring-boot:build-info` | `build-info.properties` | Atada a `generate-resources` si la declaras |

### `repackage`

```bash
./mvnw package
ls -la target/*.jar*
```

```text
-rw-r--r--  1 oskar  staff  52428800  inv-api-0.0.1-SNAPSHOT.jar
-rw-r--r--  1 oskar  staff      8421  inv-api-0.0.1-SNAPSHOT.jar.original
```

- **`repackage` toma el jar normal que produjo Maven y lo reescribe** con el `JarLauncher`
  de Boot, las dependencias en `BOOT-INF/lib/` y el `MANIFEST` apuntando a tu `Start-Class`
  ([`01` §6](01-spring-boot-y-el-ecosistema.md#6--el-jar-ejecutable-y-el-plugin-de-maven)).
- **El `.jar.original`** es el jar de Maven antes de la reescritura: **8 KB frente a 50 MB**.
  Cuando alguien te dice "el jar de Spring Boot pesa mucho", esos dos ficheros lado a lado
  son la explicación entera.
- **`-Dspring-boot.repackage.skip=true`** desactiva la reescritura. Se usa cuando el
  artefacto es una **librería** que otros proyectos declaran como dependencia: un jar
  reescrito por Boot **no sirve como dependencia de Maven**, porque las clases no están en
  la raíz sino en `BOOT-INF/classes/`. Es la causa del clásico "mi librería compila pero el
  consumidor no encuentra ninguna de sus clases".

### `build-image`

```bash
./mvnw spring-boot:build-image -Dspring-boot.build-image.imageName=inv-api:0.0.1
docker images inv-api
```

- **Construye una imagen OCI con Cloud Native Buildpacks**, sin `Dockerfile`. El buildpack
  detecta que es una aplicación Java, elige un JRE, aplica el jar por capas y te deja una
  imagen razonable sin que escribas una línea de empaquetado.
- **Necesita un daemon de Docker corriendo** y **descarga cientos de megabytes** la primera
  vez (el *builder* y las imágenes base). No es un comando que quieras probar con una
  conexión mala cinco minutos antes de una demo.
- **`-Dspring-boot.build-image.imageName`** fija el nombre; sin él te pone
  `docker.io/library/inv-api:0.0.1-SNAPSHOT`, que en un registro corporativo casi nunca es
  lo que quieres.
- **`-Dspring-boot.build-image.publish=true`** empuja al registro directamente, y entonces
  necesita credenciales configuradas en el plugin.
- **El teardown**: la imagen se queda en tu Docker local ocupando espacio.
  `docker rmi inv-api:0.0.1` la borra, y `docker image prune` se lleva las capas del builder
  que quedaron huérfanas.

### `build-info`

```xml
<plugin>
    <groupId>org.springframework.boot</groupId>
    <artifactId>spring-boot-maven-plugin</artifactId>
    <executions>
        <execution>
            <goals>
                <goal>build-info</goal>   <!-- no está atada por defecto: hay que pedirla -->
            </goals>
        </execution>
    </executions>
</plugin>
```

- **Genera `META-INF/build-info.properties`** con las coordenadas del proyecto y la hora de
  compilación. Actuator lo detecta solo y lo publica en `/actuator/info`.
- **Para qué sirve de verdad**: cuando el entorno de preproducción se comporta raro, la
  primera pregunta es *"¿qué versión está desplegada ahí?"*, y esto la contesta con un
  `curl` en vez de con una conversación.
- **`additionalProperties`** permite añadir claves propias —el hash de Git, el número de
  build del pipeline—, que es lo que convierte ese endpoint en trazabilidad de verdad.

---

## 9. 🩺 Las herramientas del JDK

Estas vienen dentro del JDK, no del JRE. El escenario es el que se da en producción y en
cualquier entrevista de diagnóstico: **la aplicación no responde, Actuator está cerrado por
seguridad, y solo tienes una sesión SSH**.

```bash
jps -lvm
```

```text
53808 com.invlab.invapi.InvApiApplication --spring.profiles.active=prod -Xmx1g -XX:+HeapDumpOnOutOfMemoryError
```

- **`jps`** lista los procesos Java de la máquina. `-l` imprime la clase principal
  completamente cualificada (o la ruta del jar), `-m` los argumentos del `main()` y `-v`
  los de la JVM. `jps -lvm` te da el PID y, de paso, con qué memoria y qué profile arrancó
  ese proceso, que son las dos primeras preguntas del diagnóstico.
- **Solo ve procesos del mismo usuario** (salvo privilegios). Si `jps` no lista nada y sabes
  que la aplicación corre, probablemente arrancó con otro usuario.

### Thread dump sin Actuator

```bash
jcmd 53808 Thread.print > /tmp/inv-api-threads.txt
```

```text
2026-09-17 21:12:38
Full thread dump OpenJDK 64-Bit Server VM (21.0.5+11-LTS mixed mode, sharing):

"http-nio-8080-exec-7" #67 daemon prio=5 os_prio=31 cpu=12.41ms elapsed=214.03s tid=0x000000012c00a200 nid=0x1603 waiting on condition  [0x000000016bc4a000]
   java.lang.Thread.State: TIMED_WAITING (parking)
	at jdk.internal.misc.Unsafe.park(java.base@21.0.5/Native Method)
	- parking to wait for  <0x00000006c1a3f8e8> (a java.util.concurrent.SynchronousQueue$TransferStack)
	at com.zaxxer.hikari.pool.HikariPool.getConnection(HikariPool.java:179)
	at com.invlab.invapi.inventory.InventoryService.recordEvent(InventoryService.java:52)
```

- **`jcmd <pid> Thread.print`** es el thread dump completo. Es la forma moderna: `jcmd` es
  el comando paraguas y `jstack <pid>` hace lo mismo con menos opciones —de hecho
  `jstack -l <pid>` añade información de locks, que a veces es justo lo que buscas—.
- **`jcmd <pid> help`** lista todos los comandos que ese proceso acepta: `GC.heap_info`,
  `GC.class_histogram`, `VM.system_properties`, `VM.command_line`, `JFR.start`. Es la
  chuleta que no hay que memorizar.
- **Qué se busca en la salida**: cuántos hilos `http-nio-8080-exec-*` hay y en qué estado
  están. Si veinte de ellos están `TIMED_WAITING` dentro de `HikariPool.getConnection`, no
  tienes un problema de CPU: tienes el pool agotado, y el culpable está más abajo en esas
  mismas pilas.
- **Se saca dos veces, con treinta segundos de diferencia.** Un dump es una foto; dos dan
  movimiento, y lo que aparece igual en los dos es lo que está realmente atascado.
- **`> /tmp/...`** porque son miles de líneas y las vas a querer leer con calma, no en la
  terminal.

### Memoria

```bash
jcmd 53808 GC.heap_info
jcmd 53808 GC.class_histogram | head -20
jcmd 53808 GC.heap_dump /tmp/inv-api.hprof
jmap -dump:live,format=b,file=/tmp/inv-api.hprof 53808
```

- **`GC.heap_info`** da el tamaño y la ocupación por generación. Es la comprobación de diez
  segundos antes de decidir si el problema es memoria.
- **`GC.class_histogram`** cuenta instancias por clase, ordenadas. Si arriba del todo hay un
  tipo tuyo con ocho millones de instancias, ya sabes por dónde seguir.
- **`GC.heap_dump` y `jmap -dump` producen lo mismo**: un `.hprof` que se abre con Eclipse
  MAT o VisualVM. `jmap` es la herramienta clásica; `jcmd` es la que la documentación
  recomienda hoy.
- **`:live`** fuerza un GC completo antes de volcar, así que el fichero solo contiene
  objetos alcanzables. Sin `live`, el dump incluye basura pendiente de recoger y es más
  grande y más ruidoso.

> **⏱️ Costo en runtime.** Un thread dump es una pausa de safepoint de milisegundos: se
> puede hacer en producción sin pedir permiso. **Un heap dump no.** Pausa la aplicación
> mientras escribe, y escribe **del orden del tamaño del heap**: con `-Xmx4g` son varios GB
> y decenas de segundos con la aplicación congelada, más el disco que hay que tener libre.
> Un heap dump en la hora punta de un servicio de banca es un incidente que te provocas
> tú. Se programa, se avisa, y si el `-XX:+HeapDumpOnOutOfMemoryError` ya lo dejó escrito al
> morir, mejor todavía.

---

## 10. 🧱 Hablar con la API y con Actuator

```bash
curl -i -X POST localhost:8080/api/v1/events \
  -H 'Content-Type: application/json' \
  -d '{"sku":"SKU-0001","quantity":5}'
```

- **`-i`** incluye la cabecera de respuesta en la salida. En una API REST, **el código de
  estado es la mitad de la respuesta**: un `201` con `Location` y un `200` con cuerpo no son
  lo mismo, y sin `-i` no ves ninguna de las dos cosas.
- **`-X POST`** fija el método; con `-d` presente, `curl` ya asume `POST`, pero escribirlo
  hace el comando legible cuando lo pegas en un ticket.
- **`-H 'Content-Type: application/json'`** no es opcional: sin esa cabecera, Spring
  responde `415 Unsupported Media Type` antes de tocar tu controller, y el mensaje no
  siempre deja claro que faltaba la cabecera.
- **`-d '{…}'` con comillas simples** para que el shell no toque las dobles del JSON.
- **`-w '\n%{http_code} %{time_total}s\n'`** al final imprime el código y el tiempo total,
  que es la forma más barata de medir una latencia sin instalar nada.

Y contra Actuator, que vive en el puerto `8081`:

```bash
curl -s localhost:8081/actuator/health | jq
curl -s localhost:8081/actuator/beans | jq -r '.contexts["inv-api"].beans | keys[]' | grep -i inventory
curl -s localhost:8081/actuator/conditions | jq '.contexts["inv-api"].negativeMatches | keys[]' | head
curl -s localhost:8081/actuator/metrics/hikaricp.connections.active | jq
curl -s localhost:8081/actuator/threaddump | jq -r '.threads[] | select(.threadState=="BLOCKED") | .threadName'
```

- **`jq` sin argumentos** formatea e indenta. Solo con eso, una respuesta de `/health` deja
  de ser una línea ilegible.
- **`jq -r '… | keys[]'`** lista las claves de un objeto, en crudo (`-r` quita las comillas)
  para poder encadenar con `grep`. Es cómo se busca un bean concreto entre los cuatrocientos
  que registra una aplicación Boot.
- **`.contexts["inv-api"]`** es el nombre del `ApplicationContext`, y en el laboratorio es
  `inv-api` porque así lo fija `spring.application.name`. Si no pusieras esa propiedad, el
  contexto se llamaría `application` y el filtro sería `.contexts.application`; por eso este
  `jq` devuelve `null` cuando lo copias a un proyecto que no la declara — no está roto, está
  mirando una clave que ahí no existe. Se escribe con corchetes y **sin punto delante**
  (`.contexts["inv-api"]`, no `.contexts.["inv-api"]`) porque esa es la forma que acepta
  también `jq` 1.6, que es la que traen todavía muchas imágenes base.
- **`/actuator/conditions`** es el informe de condiciones en JSON, el mismo que imprime
  `--debug` al arrancar, pero filtrable
  ([`06` §6](06-arranque-y-autoconfiguracion.md#6--el-informe-de-condiciones-por-qué-existe-ese-bean)).
  `negativeMatches` contesta la pregunta difícil: por qué **no** tienes un bean.
- **`select(.threadState=="BLOCKED")`** filtra por una condición dentro del array. Esto es
  el thread dump de la sección anterior, pero desde HTTP y ya estructurado: cuando Actuator
  está disponible, es más cómodo que `jcmd`.
- **Los endpoints hay que exponerlos antes.** Por defecto, sobre HTTP y sobre JMX está
  expuesto **solo `health`** —`management.endpoints.web.exposure.include` vale `health` y
  nada más—; `beans`, `conditions`, `env`, `configprops`, `metrics` y `threaddump` existen
  pero responden `404` hasta que los añades a esa lista blanca. Es el mismo default que
  declaran [`L01` §5](l01-esqueleto-cli-y-autoconfiguracion.md) y
  [`L02` §2](l02-configuracion-y-profiles.md), y tiene consecuencias de seguridad que se
  discuten en su capítulo, no aquí.

> **💡 Truco de diagnóstico.** `curl -s localhost:8081/actuator/env/server.port | jq` te dice
> **de qué fuente** salió el valor efectivo de una propiedad, no solo cuál es. Cuando la
> configuración "no se aplica", esa respuesta es el diagnóstico completo en un comando.

---

## 11. 🩺 Cómo leer un stack trace de Spring

Un stack trace de Spring es largo a propósito, y la parte larga es la que no te interesa.
Entre el punto donde falló algo y el punto donde tú escribiste código hay **el interceptor,
el proxy y la reflexión**, y eso son treinta o cuarenta frames que siempre son los mismos.

Este es uno real, de una tarea programada de `inv-api` que persiste un evento:

```text
2026-09-17T21:41:08.512-05:00 ERROR 41287 --- [inv-api] [   scheduling-1] o.s.s.s.TaskUtils$LoggingErrorHandler    : Unexpected error occurred in scheduled task

org.springframework.dao.DataIntegrityViolationException: could not execute statement [ERROR: duplicate key value violates unique constraint "inventory_event_sku_seq_key"
  Detail: Key (sku, seq)=(SKU-0001, 7) already exists.] [insert into inventory_event (created_at,payload,seq,sku,id) values (?,?,?,?,?)]
	at org.springframework.orm.jpa.vendor.HibernateJpaDialect.convertHibernateAccessException(HibernateJpaDialect.java:295)
	at org.springframework.orm.jpa.vendor.HibernateJpaDialect.translateExceptionIfPossible(HibernateJpaDialect.java:239)
	at org.springframework.orm.jpa.JpaTransactionManager.doCommit(JpaTransactionManager.java:566)
	at org.springframework.transaction.support.AbstractPlatformTransactionManager.processCommit(AbstractPlatformTransactionManager.java:795)
	at org.springframework.transaction.support.AbstractPlatformTransactionManager.commit(AbstractPlatformTransactionManager.java:758)
	at org.springframework.transaction.interceptor.TransactionAspectSupport.commitTransactionAfterReturning(TransactionAspectSupport.java:698)
	at org.springframework.transaction.interceptor.TransactionAspectSupport.invokeWithinTransaction(TransactionAspectSupport.java:407)
	at org.springframework.transaction.interceptor.TransactionInterceptor.invoke(TransactionInterceptor.java:119)
	at org.springframework.aop.framework.ReflectiveMethodInvocation.proceed(ReflectiveMethodInvocation.java:184)
	at org.springframework.aop.framework.CglibAopProxy$CglibMethodInvocation.proceed(CglibAopProxy.java:768)
	at org.springframework.aop.framework.CglibAopProxy$DynamicAdvisedInterceptor.intercept(CglibAopProxy.java:720)
	at com.invlab.invapi.inventory.InventoryService$$SpringCGLIB$$0.recordEvent(<generated>)
	at com.invlab.invapi.inventory.ReconciliationTask.reconcile(ReconciliationTask.java:38)
	at java.base/jdk.internal.reflect.DirectMethodHandleAccessor.invoke(DirectMethodHandleAccessor.java:103)
	at java.base/java.lang.reflect.Method.invoke(Method.java:580)
	at org.springframework.scheduling.support.ScheduledMethodRunnable.runInternal(ScheduledMethodRunnable.java:130)
	at org.springframework.scheduling.support.ScheduledMethodRunnable.run(ScheduledMethodRunnable.java:124)
	at org.springframework.scheduling.support.DelegatingErrorHandlingRunnable.run(DelegatingErrorHandlingRunnable.java:54)
	at java.base/java.util.concurrent.FutureTask.runAndReset(FutureTask.java:305)
Caused by: org.hibernate.exception.ConstraintViolationException: could not execute statement [ERROR: duplicate key value violates unique constraint "inventory_event_sku_seq_key"
  Detail: Key (sku, seq)=(SKU-0001, 7) already exists.] [insert into inventory_event (created_at,payload,seq,sku,id) values (?,?,?,?,?)]
	at org.hibernate.exception.internal.SQLStateConversionDelegate.convert(SQLStateConversionDelegate.java:97)
	at org.hibernate.engine.jdbc.spi.SqlExceptionHelper.convert(SqlExceptionHelper.java:108)
	at org.hibernate.engine.jdbc.internal.ResultSetReturnImpl.executeUpdate(ResultSetReturnImpl.java:196)
	... 47 more
Caused by: org.postgresql.util.PSQLException: ERROR: duplicate key value violates unique constraint "inventory_event_sku_seq_key"
  Detail: Key (sku, seq)=(SKU-0001, 7) already exists.
	at org.postgresql.core.v3.QueryExecutorImpl.receiveErrorResponse(QueryExecutorImpl.java:2733)
	at org.postgresql.core.v3.QueryExecutorImpl.processResults(QueryExecutorImpl.java:2420)
	at org.postgresql.core.v3.QueryExecutorImpl.execute(QueryExecutorImpl.java:368)
	at org.postgresql.jdbc.PgStatement.executeInternal(PgStatement.java:498)
	... 53 more
```

### El orden de lectura, línea a línea

**Primero: el último `Caused by`, no el primero.** Aquí es la `PSQLException`. Una cadena de
`Caused by` se lee **de abajo arriba**: cada nivel es una traducción del anterior a un
vocabulario más abstracto. Postgres dijo "clave duplicada", Hibernate lo tradujo a
`ConstraintViolationException`, y Spring lo tradujo otra vez a
`DataIntegrityViolationException` —su jerarquía propia, independiente del proveedor—.

```text
DataIntegrityViolationException   ← Spring: qué tipo de problema es
  └─ ConstraintViolationException ← Hibernate: quién lo detectó
       └─ PSQLException           ← Postgres: QUÉ pasó de verdad  ← empieza por aquí
```

**Segundo: el detalle del mensaje de la raíz.** `Key (sku, seq)=(SKU-0001, 7) already
exists` y el nombre del índice, `inventory_event_sku_seq_key`. Eso no es ruido: te dice la
tabla, las dos columnas del índice único y los valores exactos que chocaron. Con eso puedes
ir a la base de datos y mirar la fila que ya estaba ahí.

**Tercero: tu línea.** Se busca de arriba hacia abajo la primera clase de **tu** paquete, y
aquí hay dos:

```text
at com.invlab.invapi.inventory.InventoryService$$SpringCGLIB$$0.recordEvent(<generated>)
at com.invlab.invapi.inventory.ReconciliationTask.reconcile(ReconciliationTask.java:38)
```

- **La primera no tiene número de línea, dice `<generated>` y termina en `$$SpringCGLIB$$0`.**
  No es tu clase: es el **proxy** que Spring generó para envolverla
  ([`05`](05-proxies-y-aop.md)). No hay nada que mirar ahí, pero su presencia es información
  valiosísima: **prueba que la llamada pasó por el proxy**, y por tanto que el
  `@Transactional` sí estaba activo. Cuando investigas un rollback que no ocurrió, la
  **ausencia** de ese frame es el diagnóstico.
- **La segunda es tu código de verdad**: fichero y línea, `ReconciliationTask.java:38`. Ese
  es el sitio por el que empiezas a leer tu propio código.

**Cuarto: qué interceptores hay entre medias, y en qué punto falló.** Esta es la lectura que
separa a alguien con experiencia:

```text
TransactionInterceptor.invoke                      ← había transacción
TransactionAspectSupport.invokeWithinTransaction   ← y el método corrió dentro
TransactionAspectSupport.commitTransactionAfterReturning  ← y falló AL HACER COMMIT
JpaTransactionManager.doCommit
```

El método terminó **sin lanzar nada**. La excepción apareció al confirmar, cuando Hibernate
vació el contexto de persistencia contra la base de datos. Por eso un `try/catch` alrededor
del `repository.save()` no habría capturado absolutamente nada — y por eso este trace
explica un síntoma que en el código parece imposible.

**Quinto: el hilo y el logger de la primera línea.** `[   scheduling-1]` dice que esto no
vino de un request HTTP sino del scheduler, y `TaskUtils$LoggingErrorHandler` dice quién lo
atrapó. Si el hilo hubiera sido `[nio-8080-exec-3]`, habría un usuario esperando una
respuesta y la urgencia sería otra.

**Sexto: `... 47 more`.** Es la JVM diciendo "los 47 frames siguientes son idénticos a los
del bloque de arriba". No falta información: está arriba. Cortar un trace por ahí al pegarlo
en un ticket es legítimo; cortarlo por el medio del primer bloque no.

```text
Regla de lectura de un stack trace de Spring:
  1. el ÚLTIMO Caused by       → qué pasó de verdad
  2. su mensaje completo       → con qué datos
  3. la primera clase tuya     → dónde empezar a leer
  4. los interceptores encima  → quién lo ejecutó y en qué fase falló
  5. el nombre del hilo        → quién está esperando
```

> **⚠️ La sobregeneralización más cara de esta sección.** "La causa está en la primera línea
> del error" es falso en Spring: la primera línea te dice la **categoría** —Spring traduce
> todo a su propia jerarquía—, y la causa está al final de la cadena. Un candidato que ve un
> `DataIntegrityViolationException` y dice "hay un problema de integridad de datos" no ha
> dicho nada; uno que dice "el índice único `inventory_event_sku_seq_key` rechazó la fila
> `(SKU-0001, 7)` al hacer commit" ha leído el trace.

> **🧠 Modelo mental.** En un trace de Spring, **tu código está en el medio**: arriba está lo
> que falló, abajo está quién te llamó, y tú eres el sándwich entre cuarenta frames de
> infraestructura. Aprender a saltar visualmente los paquetes `org.springframework.aop`,
> `org.springframework.transaction.interceptor` y `java.base/jdk.internal.reflect` es la
> mitad de la habilidad.

---

## 12. 🧱 Docker Compose de supervivencia

El fichero completo de la serie, con su explicación línea a línea, está en
[`L00` §6](l00-idea-lab-practico.md#6--el-docker-composeyml-de-la-serie). Aquí solo están
los comandos que se repiten y los tres que resuelven el 90 % de los "no arranca".

```bash
docker compose --profile db up -d
docker compose ps
docker compose logs -f postgres
docker compose exec postgres psql -U inv_lab -d inv_lab -c '\dt'
docker compose -p inv-lab down -v --remove-orphans
```

- **`--profile db`** levanta solo los servicios de ese perfil. En este proyecto **ningún
  servicio arranca sin perfil**, y eso es deliberado: un `docker compose up -d` a secas no
  hace nada y no es un fallo.
- **`-d` (detached)** devuelve la terminal. Sin él, Compose se queda enganchado a los logs y
  un `Ctrl+C` **para los contenedores**, que sorprende la primera vez.
- **`docker compose ps`** es el estado inicial verificable de cualquier lab: si no lista lo
  que esperas, no sigas adelante. La columna de estado distingue `running` de
  `running (healthy)`, y esa diferencia son los segundos en que el `healthcheck` todavía no
  pasó y tu aplicación fallaría al conectar.
- **`logs -f <servicio>`** sigue el log de un contenedor concreto. `-f` es *follow*, como en
  `tail -f`; `--tail=100` limita el histórico y `--since=5m` lo acota en el tiempo, que es lo
  que quieres cuando el contenedor lleva tres horas arriba.
- **`exec <servicio> <comando>`** ejecuta algo **dentro** del contenedor. Con Postgres es la
  vía directa para confirmar si una tabla existe sin instalar `psql` en tu máquina: `-U` es
  el usuario, `-d` la base y `-c` una sentencia única que termina y sale.
- **`down -v --remove-orphans`** es el teardown completo: contenedores, red **y volúmenes con
  nombre**. Sin `-v`, `postgres-data` sobrevive y al volver a levantar aparecen los datos de
  hace tres semanas. `-p inv-lab` apunta al proyecto por nombre, así que funciona aunque no
  estés en el directorio del fichero.

Los tres comandos que resuelven casi todo:

```bash
docker compose config
lsof -i :5432
docker compose down && docker compose --profile db up -d --force-recreate
```

- **`config`** imprime el fichero ya interpolado —variables sustituidas, perfiles
  resueltos— y **falla si el YAML es inválido**. Es el equivalente a un `--dry-run` y se
  ejecuta antes de perder diez minutos preguntándose por qué una variable llega vacía.
- **`lsof -i :5432`** dice qué proceso ocupa el puerto. El error más común al levantar el lab
  no es de Docker: es un Postgres instalado en tu máquina ocupando el 5432. En Linux
  `ss -ltnp | grep 5432` hace lo mismo.
- **`--force-recreate`** vuelve a crear los contenedores aunque la configuración no haya
  cambiado. Es el "apaga y enciende" que sirve cuando un contenedor quedó en un estado raro;
  lo que **no** hace es borrar volúmenes, así que los datos siguen ahí.

---

## 13. 🩺 Atajos de depuración

Cuatro cosas que se buscan siempre y que nunca están donde uno cree.

### Subir el nivel de log de un paquete

```bash
./mvnw spring-boot:run -Dspring-boot.run.arguments="--logging.level.org.springframework.transaction=DEBUG,--logging.level.com.invlab=DEBUG"
```

```yaml
logging:
  level:
    org.springframework.transaction.interceptor: TRACE   # qué método abre y cierra transacción
    org.springframework.web.servlet.DispatcherServlet: DEBUG
    org.hibernate.SQL: DEBUG                             # el SQL que se ejecuta
    org.hibernate.orm.jdbc.bind: TRACE                   # y con qué parámetros
    com.zaxxer.hikari.pool.HikariPool: DEBUG             # tamaño y estado del pool
```

- **`logging.level.<paquete>`** acepta cualquier prefijo de paquete o nombre de clase. No
  hace falta reiniciar si tienes Actuator: el endpoint `loggers` lo cambia en caliente con
  un `POST`, y eso en producción vale oro.
- **`org.springframework.transaction.interceptor` en `TRACE`** imprime una línea por cada
  método que entra y sale de una transacción, con el nombre del método. Es la forma más
  rápida de comprobar si tu `@Transactional` está haciendo algo, en lugar de suponerlo.
- **`org.hibernate.orm.jdbc.bind` en `TRACE`** imprime los valores de los `?`. El nombre de
  ese logger **cambió en Hibernate 6** (antes era `org.hibernate.type.descriptor.sql`), y
  copiar la configuración de un blog de 2019 es la causa número uno de "activé el log de
  SQL y no salen los parámetros".

### `--debug` y el informe de condiciones

```bash
./mvnw spring-boot:run -Dspring-boot.run.arguments=--debug
```

- **`--debug` no sube el nivel de log de todo.** Activa el `ConditionEvaluationReport` y lo
  imprime al arrancar: qué autoconfiguración se aplicó y cuál no, con la condición exacta
  que falló ([`06` §6](06-arranque-y-autoconfiguracion.md#6--el-informe-de-condiciones-por-qué-existe-ese-bean)).
  Quien lo confunde con `logging.level.root=DEBUG` termina leyendo cien mil líneas que no
  contienen la respuesta.
- **`--trace`** hace lo mismo con un nivel más de detalle y casi nunca compensa.

### Ver el SQL

```bash
./mvnw spring-boot:run -Dspring-boot.run.arguments="--spring.jpa.show-sql=true"
```

- **`spring.jpa.show-sql=true`** imprime el SQL por `System.out`, sin nivel de log, sin
  `traceId` y sin poder apagarlo por paquete. Sirve para una sesión de depuración en local y
  **no debe llegar a un entorno compartido**.
- **La alternativa buena es `logging.level.org.hibernate.SQL=DEBUG`**, que pasa por el
  sistema de logging normal: tiene nivel, formato, correlación y se puede apagar en caliente.
- **`-Dspring.jpa.show-sql=true` a secas, sobre la línea de `./mvnw`, no hace nada**, por lo
  de la §7: esa propiedad se queda en la JVM de Maven y nunca llega al proceso hijo.

### Depuración remota

```bash
./mvnw spring-boot:run -Dspring-boot.run.jvmArguments="-agentlib:jdwp=transport=dt_socket,server=y,suspend=n,address=*:5005"
java -agentlib:jdwp=transport=dt_socket,server=y,suspend=n,address=*:5005 -jar target/inv-api-0.0.1-SNAPSHOT.jar
```

- **`-agentlib:jdwp`** carga el agente de depuración de la JVM. Va en `jvmArguments` y **solo
  ahí**: no es configuración de Spring, es la máquina virtual.
- **`transport=dt_socket`** usa un socket TCP, que es lo que espera cualquier IDE.
- **`server=y`** hace que la JVM escuche y el IDE se conecte a ella (*attach*). Con `server=n`
  sería al revés, y casi nunca es lo que quieres.
- **`suspend=n`** arranca normalmente; con `suspend=y` la JVM **se queda congelada esperando**
  a que alguien se conecte, que es exactamente lo que necesitas para poner un breakpoint en
  el arranque del contexto, y exactamente lo que te hace creer que la aplicación se colgó si
  lo dejaste puesto sin querer.
- **`address=*:5005`** escucha en todas las interfaces. Desde Java 9, poner solo `5005`
  significa `localhost` y **no funciona desde fuera de un contenedor**: esa es la causa de la
  mitad de los "no me puedo conectar al debug del contenedor".

> **⚠️ El puerto de depuración abierto es una ejecución remota de código.** Cualquiera que
> alcance el 5005 puede leer memoria, cambiar variables y ejecutar métodos. En local, con
> Compose, es inofensivo; en un entorno compartido es un hallazgo de seguridad, y `address=*`
> lo empeora. Se abre para una sesión y se cierra.

---

## 14. ⚠️ Errores frecuentes de tooling

- **"`-Dserver.port=8082` en `./mvnw spring-boot:run` cambia el puerto."** No: la aplicación
  corre en un proceso hijo. Va en `-Dspring-boot.run.arguments` o en `jvmArguments`.
- **"El primer `Caused by` es la causa."** La cadena se lee de abajo arriba; la primera línea
  te da la categoría, la última el hecho.
- **"`-DskipTests` y `-Dmaven.test.skip` son lo mismo."** El segundo ni siquiera compila los
  tests y deja pasar código que no compila.
- **"Maven resuelve el conflicto quedándose con la versión más nueva."** Se queda con la
  **más cercana a la raíz**. `-Dverbose` lo dice explícitamente con `omitted for conflict`.
- **"`--debug` sube el nivel de log."** Activa el informe de condiciones.
- **"Un thread dump y un heap dump son igual de caros."** El primero son milisegundos; el
  segundo congela la aplicación y escribe gigabytes.
- **"Un jar de Boot sirve como dependencia de otro proyecto."** No: las clases están en
  `BOOT-INF/classes/`. Para una librería hay que desactivar `repackage`.
- **"`spring init --boot-version=3.5.16` siempre funciona."** Initializr solo ofrece líneas
  con soporte vigente y responde `400` para las demás.

---

## 🧠 Preguntas rápidas

1. ¿Qué diferencia hay entre `-Dspring-boot.run.arguments` y `-Dspring-boot.run.jvmArguments`,
   y por qué `-Dserver.port=8082` sobre la línea de `./mvnw` no cambia el puerto?
2. Pides `bootVersion=3.5.16` a `start.spring.io` y responde `400`. ¿Por qué, y cómo generas
   el esqueleto del curso de todas formas?
3. En una cadena con tres `Caused by`, ¿cuál lees primero y por qué las de arriba no son la
   causa?
4. Ves un frame `com.invlab.invapi.inventory.InventoryService$$SpringCGLIB$$0.recordEvent(<generated>)`.
   ¿Qué es, y qué te permite descartar su presencia en el trace?
5. Un stack trace muestra `commitTransactionAfterReturning` por encima de tu línea de código.
   ¿En qué momento exacto falló el método y qué consecuencia tiene para un `try/catch`?
6. ¿Por qué `-DskipTests` no es equivalente a `-Dmaven.test.skip=true`, y cuál de los dos es
   un hallazgo de code review?
7. `dependency:tree` te muestra la misma librería con dos versiones. ¿Qué flag te dice cuál
   ganó, y con qué criterio resuelve Maven el conflicto?
8. La aplicación no responde, Actuator está cerrado y solo tienes SSH. Escribe los dos
   comandos que corres, en orden, y di qué buscas en la salida del segundo.
9. ¿Por qué un heap dump no se saca en producción con la misma tranquilidad que un thread
   dump? Da la unidad del costo.
10. Añades `-agentlib:jdwp=…,suspend=y,address=5005` a un contenedor y ni arranca ni te puedes
    conectar. ¿Cuáles son los dos errores?
11. ¿Qué hace exactamente `spring-boot:repackage` y por qué hay que desactivarlo cuando el
    artefacto es una librería?
12. Activas `spring.jpa.show-sql=true` y tu compañero te dice que uses
    `logging.level.org.hibernate.SQL=DEBUG`. ¿Qué ganas con el cambio?

---

## 🧪 Ejercicios (10)

Todos se hacen sobre `inv-api` y todos declaran cómo se comprueban. Las preguntas rápidas
se responden en el solucionario único del curso, [`26`](26-respuestas.md); los ejercicios
**no** van al solucionario: se verifican con su `Objetivo:` y con la salida real.

### 🟢 Fácil — generar, arrancar, mirar  (1–4)

#### 🟢 Ejercicio 1 — El POM sin descargar nada

Pide a `start.spring.io` **solo** el `pom.xml` de un proyecto Maven con `web`, `actuator` y
`validation`, Java 21, `groupId` `com.invlab` y `artifactId` `inv-api`, y sin escribir nada
en disco. Después repite la llamada añadiendo `configurationFileFormat=yaml` sobre
`starter.zip` y comprueba qué fichero de configuración trae dentro.

**Objetivo:** distinguir los cuatro recursos del servicio (`starter.zip`, `pom.xml`,
`build.gradle`, la raíz de ayuda) y saber que el formato de configuración es un parámetro.
**Pregunta:** ¿qué build te habría dado si omitieras `type`?

#### 🟢 Ejercicio 2 — El puerto que no cambia

Arranca `inv-api` con `./mvnw spring-boot:run -Dserver.port=8082` y comprueba en qué puerto
quedó escuchando. Después consíguelo de las otras dos formas de la §7.

**Objetivo:** que el proceso hijo de `spring-boot:run` deje de ser una sorpresa.
**Se comprueba:** `curl -s -o /dev/null -w '%{http_code}\n' localhost:8082/actuator/health`
devuelve `200` solo en dos de los tres intentos.

#### 🟢 Ejercicio 3 — El jar y su original

Ejecuta `./mvnw package` y compara el tamaño de `inv-api-0.0.1-SNAPSHOT.jar` con el de
`inv-api-0.0.1-SNAPSHOT.jar.original`. Después lista el contenido de los dos con
`unzip -l | head -20`.

**Objetivo:** ver con los ojos qué añade `repackage` y por qué el jar de Boot no sirve como
dependencia.
**Pregunta:** ¿en qué ruta dentro del jar están tus clases compiladas?

#### 🟢 Ejercicio 4 — Un thread dump propio

Arranca `inv-api`, localiza su PID con `jps -lvm` y saca un thread dump con
`jcmd <pid> Thread.print`. Cuenta cuántos hilos `http-nio-8080-exec-*` existen **antes** de
enviar ninguna petición.

**Objetivo:** saber sacar un dump sin Actuator y conocer el tamaño inicial del pool de
Tomcat.
**Pregunta:** ¿ese número coincide con `server.tomcat.threads.max`? ¿Por qué?

### 🟡 Intermedio — aplicarlo a otra cosa  (5–7)

#### 🟡 Ejercicio 5 — Ver la transacción sin creértela

Sube `org.springframework.transaction.interceptor` a `TRACE` **por argumento de línea de
comandos**, sin tocar `application.yml`, y provoca una llamada a un método `@Transactional`
de `inv-api`.

**Objetivo:** usar `logging.level.*` como herramienta de diagnóstico puntual.
**Se comprueba:** en el log aparece una línea `Getting transaction for [com.invlab.invapi…]`
con el nombre completo del método.

#### 🟡 Ejercicio 6 — El informe de condiciones, filtrado

Arranca con `--debug` y después consigue la misma información por HTTP desde
`/actuator/conditions`, filtrando con `jq` para quedarte **solo** con los nombres de las
autoconfiguraciones que **no** se aplicaron.

**Objetivo:** que `negativeMatches` sea tu primer reflejo cuando falte un bean.
**Se comprueba:** la salida es una lista de nombres, una por línea, sin comillas.

#### 🟡 Ejercicio 7 — Trazabilidad del despliegue

Declara la meta `build-info` en el `spring-boot-maven-plugin`, empaqueta, arranca y consulta
`/actuator/info`. Añade después una propiedad extra con el nombre de la rama de Git.

**Objetivo:** poder contestar "¿qué versión está desplegada?" con un `curl`.
**Se comprueba:** `curl -s localhost:8081/actuator/info | jq .build` devuelve las
coordenadas y la hora de compilación.

### 🟠 Difícil — combinar y diagnosticar  (8–9)

#### 🟠 Ejercicio 8 — Provocar y resolver un conflicto de versiones

Añade a `inv-api` una dependencia que arrastre una versión vieja de Jackson (por ejemplo,
declarando `com.fasterxml.jackson.core:jackson-databind:2.13.4` directamente en tu
`pom.xml`). Confirma con `dependency:tree -Dverbose` cuál gana y por qué, y resuélvelo de las
dos formas de la §5. Decide cuál de las dos dejarías en un proyecto real y escribe el
porqué en un comentario del `pom.xml`.

**Objetivo:** interiorizar *nearest wins* y saber cuándo una exclusión es la herramienta
equivocada.
**Se comprueba:** `./mvnw dependency:tree -Dverbose -Dincludes=com.fasterxml.jackson.core:jackson-databind`
ya no muestra ninguna línea `omitted for conflict`.

#### 🟠 Ejercicio 9 — Autopsia de un trace ajeno

Toma el stack trace de la §11 y escribe, en cinco líneas y sin abrir ningún código, un
informe de diagnóstico que responda: qué falló, con qué datos, en qué fase de la
transacción, quién lo ejecutó y en qué hilo. Después señala el frame exacto por el que
empezarías a leer el código de `inv-api`.

**Objetivo:** convertir la regla de lectura en un procedimiento que se aplica en treinta
segundos.
**Pregunta:** ¿qué habría cambiado en tu informe si el hilo fuera `[nio-8080-exec-3]`?

### 🔴 Muy difícil — se entrega algo roto  (10)

#### 🔴 Ejercicio 10 — El servicio que no responde

Arranca `inv-api` con el perfil `local` y un `-Xmx128m` muy justo, lanza contra él cincuenta
peticiones concurrentes a un endpoint que toca la base de datos y provoca que deje de
responder. **Sin usar Actuator**, diagnostica qué pasó usando solo `jps`, `jcmd` y dos
thread dumps separados por treinta segundos. Entrega un informe con: la hipótesis, la
evidencia literal (los frames concretos que la sostienen), la corrección que aplicarías hoy
y la que harías con calma.

**Objetivo:** ejecutar el procedimiento completo de diagnóstico sin red de seguridad, que es
exactamente el escenario de una entrevista de incidente.
**Pregunta:** ¿qué aparece **igual** en los dos dumps, y por qué eso es el dato que vale?

### 🔥 Opcionales y ampliaciones

- Construye la imagen con `spring-boot:build-image`, compara su tamaño con el del jar y
  averigua con `docker history` cuántas capas añadió el buildpack. Bórrala después.
- Arranca con `-agentlib:jdwp=…,suspend=y` y conecta el IDE para poner un breakpoint en el
  constructor de un bean, antes de que el contexto termine de refrescarse.
- Levanta el mismo `inv-api` dos veces en puertos distintos y comprueba con `jps -lvm` que
  puedes distinguirlos por sus argumentos.

### 💀 Boss fight — la máquina ajena

Te dan acceso SSH a una máquina donde corre un `inv-api` que alguien más desplegó. **No hay
IDE, no hay navegador, Actuator está cerrado y no conoces la configuración.** Usando
únicamente lo de este apéndice, produce un informe que responda: qué versión de Boot y de
Java corre, con qué perfiles arrancó, qué memoria máxima tiene, cuántas conexiones de
Hikari hay activas, qué endpoints expone, qué autoconfiguraciones importantes **no** se
aplicaron y si hay algún hilo bloqueado. Entrega el informe con el comando que sostiene cada
afirmación.

**Objetivo:** demostrar que puedes auditar un servicio Spring Boot que no escribiste, desde
una terminal, sin pedirle nada a nadie.

---

## 📚 Referencias oficiales

- Spring Initializr — servicio y ayuda en texto plano: https://start.spring.io/
- Spring Boot 3.5 — Spring Boot CLI: https://docs.spring.io/spring-boot/3.5/cli/index.html
- Spring Boot 3.5 — Instalación del CLI: https://docs.spring.io/spring-boot/3.5/cli/installation.html
- Spring Boot 3.5 — Uso del CLI (`init`, `encodepassword`): https://docs.spring.io/spring-boot/3.5/cli/using-the-cli.html
- Spring Boot 3.5 — Maven Plugin (índice): https://docs.spring.io/spring-boot/3.5/maven-plugin/index.html
- Spring Boot 3.5 — `spring-boot:run` y sus argumentos: https://docs.spring.io/spring-boot/3.5/maven-plugin/run.html
- Spring Boot 3.5 — Empaquetado y `repackage`: https://docs.spring.io/spring-boot/3.5/maven-plugin/packaging.html
- Spring Boot 3.5 — `build-image` y buildpacks: https://docs.spring.io/spring-boot/3.5/maven-plugin/build-image.html
- Spring Boot 3.5 — `build-info` e integración con Actuator: https://docs.spring.io/spring-boot/3.5/maven-plugin/build-info.html
- Spring Boot 3.5 — Ejecutar la aplicación: https://docs.spring.io/spring-boot/3.5/reference/using/running-your-application.html
- Spring Boot 3.5 — Logging y niveles: https://docs.spring.io/spring-boot/3.5/reference/features/logging.html
- Spring Boot 3.5 — Profiles: https://docs.spring.io/spring-boot/3.5/reference/features/profiles.html
- Spring Boot 3.5 — Endpoints de Actuator: https://docs.spring.io/spring-boot/3.5/reference/actuator/endpoints.html
- Spring Boot 3.5 — How-to de la aplicación y el arranque: https://docs.spring.io/spring-boot/3.5/how-to/application.html
- Spring Boot 3.5 — Formato del jar ejecutable: https://docs.spring.io/spring-boot/3.5/specification/executable-jar/index.html
- Spring Boot 3.5 — Soporte de Docker Compose en desarrollo: https://docs.spring.io/spring-boot/3.5/reference/features/dev-services.html
- Spring Boot — soporte y calendario de versiones: https://spring.io/projects/spring-boot/

### Documentación de terceros

- Apache Maven — el wrapper (`./mvnw`): https://maven.apache.org/tools/wrapper/
- Apache Maven — `dependency:tree`: https://maven.apache.org/plugins/maven-dependency-plugin/tree-mojo.html
- MojoHaus — `versions:display-dependency-updates`: https://www.mojohaus.org/versions/versions-maven-plugin/display-dependency-updates-mojo.html
- JDK 21 — `jps`: https://docs.oracle.com/en/java/javase/21/docs/specs/man/jps.html
- JDK 21 — `jcmd`: https://docs.oracle.com/en/java/javase/21/docs/specs/man/jcmd.html
- JDK 21 — `jstack`: https://docs.oracle.com/en/java/javase/21/docs/specs/man/jstack.html
- JDK 21 — `jmap`: https://docs.oracle.com/en/java/javase/21/docs/specs/man/jmap.html
- JDK 21 — opciones de `java`, incluido `-agentlib:jdwp`: https://docs.oracle.com/en/java/javase/21/docs/specs/man/java.html
- JDK 21 — guía de troubleshooting: https://docs.oracle.com/en/java/javase/21/troubleshoot/index.html
- Eclipse Temurin — releases del JDK: https://adoptium.net/temurin/releases/
- Docker Compose — referencia de la CLI: https://docs.docker.com/reference/cli/docker/compose/
- Docker Compose — especificación del fichero: https://docs.docker.com/reference/compose-file/
- jq — manual: https://jqlang.org/manual/
- curl — manual: https://curl.se/docs/manpage.html
- Cloud Native Buildpacks — documentación: https://buildpacks.io/docs/
