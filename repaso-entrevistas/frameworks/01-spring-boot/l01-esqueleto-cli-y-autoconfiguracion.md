# L01 — Esqueleto, CLI y autoconfiguración

> **Objetivo:** tener `inv-api` corriendo en tu máquina, entender cada línea de su
> `pom.xml` y de su log de arranque, y poder contestar con un comando —no con una
> intuición— por qué existe un bean que tú no declaraste.
> **Asume:** [`01`](01-spring-boot-y-el-ecosistema.md), [`06`](06-arranque-y-autoconfiguracion.md) y el encuadre de [`L00`](l00-idea-lab-practico.md). De [`07`](07-configuracion-externalizada.md) basta saber que existe un `application.properties`.
> **Prerrequisitos:** JDK 21 instalado y `curl` disponible. Docker instalado, pero **no se levanta ningún contenedor**: en §14 solo se copia y se valida el `docker-compose.yml`. No hay lab anterior que ejecutar: `L00` no ejecuta nada.
> **Costo:** **$0.00**. Nada sale de tu máquina salvo la descarga de dependencias.
> **Duración:** entre 90 y 120 minutos, de los cuales unos diez son la primera descarga de Maven.
> **Qué deja levantado:** **ningún contenedor**. Deja el proyecto `inv-api` en disco, compilado, con su jar en `target/` y el caché de Maven poblado en `~/.m2`.
> **Qué toca:** todo se crea de cero. Dentro del proyecto, el directorio `inv-api/` con su
> `pom.xml`, el wrapper `./mvnw`, `src/main/resources/application.properties` y las clases
> `InvApiApplication`, `JsonConfig` y `TimeConfig` bajo `com.invlab.invapi.config` más
> `StartupSummary` bajo `com.invlab.invapi.startup`. Fuera del proyecto, el `docker-compose.yml`
> en la raíz del repositorio —se escribe entero aquí y no se levanta— y el caché `~/.m2`; el
> build deja `target/`.
> **Vigencia:** 17 de septiembre de 2026 · Spring Boot 3.5.16 · Spring Framework 6.2.19 · Java 21.

**Salto rápido:** [Qué hace este lab](#1--qué-hace-este-lab-y-por-qué-no-levanta-nada) ·
[Estado inicial](#2--estado-inicial-verificable) ·
[Tres formas de generar el proyecto](#3--tres-formas-de-generar-el-mismo-proyecto) ·
[El `pom.xml` y la bajada al baseline](#4--el-pomxml-generado-y-su-bajada-al-baseline) ·
[El resto del esqueleto](#5--el-resto-del-esqueleto-clase-principal-propiedades-y-wrapper) ·
[Tres formas de arrancarlo](#6--tres-formas-de-arrancarlo) ·
[El log de arranque](#7--el-log-de-arranque-línea-por-línea) ·
[El informe de condiciones](#8--el-informe-de-condiciones---debug-y-actuatorconditions) ·
[El `DataSource` que nadie pidió](#9--el-datasource-que-nadie-pidió) ·
[Tu bean gana](#10--tu-bean-gana-conditionalonmissingbean-en-vivo) ·
[`ApplicationRunner`](#11--código-que-corre-al-arrancar-applicationrunner) ·
[Dos fallos provocados](#12--dos-fallos-de-arranque-provocados-a-propósito) ·
[Lo que cuesta arrancar](#13-️-lo-que-cuesta-arrancar) ·
[Teardown](#15--teardown-qué-queda-en-target-y-en-m2) ·
[Checklist de salida](#16--checklist-de-salida) ·
[Preguntas rápidas](#-preguntas-rápidas) ·
[Ejercicios](#-ejercicios-16)

---

## 1. 🧭 Qué hace este lab (y por qué no levanta nada)

En la tabla de `L00` §8 este lab aparece con la columna de perfiles de Compose vacía, y no
es un descuido: **`L01` no levanta ni un contenedor**. Todo lo que se practica aquí —el
esqueleto, el arranque, el informe de condiciones, el fallo que Boot traduce por ti—
ocurre entre `main()` y el primer request, y ninguna base de datos real aporta nada a eso.

Lo que sí vas a hacer es lo que la doctrina de reparto de `L00` §2 llama *una costura
entre tu código y el contenedor*: el sitio donde Boot toma decisiones que tú no escribiste
y que después tienes que defender en una reunión.

La pregunta que hay que poder contestar al terminar es esta, y es literal de entrevista:

> *"Aparece en tu aplicación un `DataSource` que nadie declaró. ¿Cómo averiguas de dónde
> salió, sin buscar en Google y sin abrir el código de Spring?"*

Al final del lab la contestas en dos comandos.

Y la sobregeneralización que este lab desmonta, la primera de todas:

> Nunca respondas: ~~"Boot adivina lo que necesitas"~~

> Mejor: "Boot no adivina nada. Evalúa condiciones sobre el classpath, las propiedades y
> los beans que ya existen, y el resultado de cada una queda escrito en el informe de
> condiciones. Es determinista y se audita con `--debug` o con `/actuator/conditions`."

---

## 2. 🩺 Estado inicial verificable

No hay lab anterior del que venir, así que el estado inicial es el de tu máquina:

```bash
java -version
curl --version
jq --version
lsof -i :8080 -i :8081
curl -s -o /dev/null -w '%{http_code}\n' -H 'Accept: application/json' https://start.spring.io/metadata/client
```

- **`java -version`** tiene que decir `21`. Si dice 17, buena parte de la serie funciona, pero
  los virtual threads no existen ahí, y con ellos se quedan fuera el capítulo
  [`12`](12-reactivo-bloqueante-y-virtual-threads.md) y los 🔥 opcionales de `L05` y `L06`
  (`L06` en sí es caché y asincronía, y esa parte sí corre en 17). Conviene arreglarlo ahora y
  no dentro de cinco labs.
- **`curl`** se usa para generar el proyecto y para hablar con Actuator. Viene de serie en
  macOS y en cualquier Linux.
- **`jq`** no es opcional en la práctica: el informe de condiciones en JSON son dos mil
  líneas y sin filtro no se lee.
- **`lsof -i :8080 -i :8081`** tiene que **no imprimir nada**. Si imprime algo, ya hay un
  proceso escuchando y el lab te va a fallar en §6 por una razón distinta de la que
  queremos. En `L01` solo el fallo de §12 se provoca a propósito; los accidentales
  estorban.
- **El último comando tiene que devolver `200`**: las tres vías de §3 son clientes del
  mismo servicio remoto, así que sin red no hay esqueleto. La cabecera `Accept` es
  obligatoria; sin ella el servicio devuelve la página HTML y el código de estado deja de
  decirte lo que crees.
- **Maven no aparece en la lista** y es deliberado: no hace falta instalarlo. El proyecto
  trae el wrapper.

---

## 3. ⚖ Tres formas de generar el mismo proyecto

Las tres llaman al mismo servicio —Spring Initializr— y producen el mismo proyecto. La
diferencia no está en el resultado, está en **qué puedes automatizar**.

Y hay algo que ninguna de las tres puede darte, así que conviene saberlo antes de empezar:
**el Initializr ya no genera proyectos sobre el baseline de este curso**. Lo vas a
comprobar tú mismo en la forma 2, provocando el error a propósito.

### Forma 1 — `start.spring.io` por web

Abre [https://start.spring.io/](https://start.spring.io/) y rellena:

```text
Project      Maven
Language     Java
Spring Boot  la que ofrezca por defecto (hoy 4.1.1)
Group        com.invlab
Artifact     inv-api
Name         inv-api
Package name com.invlab.invapi
Packaging    Jar
Java         21
Dependencies Spring Web · Spring Boot Actuator
```

- **`Project: Maven`**, porque el curso fija Maven (§5.1 de la guía de estilo): es lo que
  hay en banca. Gradle genera un proyecto igual de válido y no vuelve a aparecer.
- **`Spring Boot`: lo que haya en el desplegable, y lo que hay es 4.x.** No busques 3.5.16
  ahí: no está, y no es un fallo de la página. La corrección al baseline del curso se hace
  a mano después, en §4, y es un ejercicio más útil que elegir una opción de una lista.
- **`Packaging: Jar`**, no `War`. El `war` existe para desplegar en un servidor externo, y
  todo el modelo de [`L09`](l09-empaquetado-imagen-y-limpieza.md) —imagen, un proceso por servicio— asume jar ejecutable (`01` §6).
- **`Java 21`** es el baseline. El selector ofrece hoy 17, 21, 25 y 26: son los que el
  Initializr considera razonables, no todos los que Boot admite. Este valor **sí** se
  respeta tal cual y no hay que corregirlo después.
- **Las dos dependencias** son el mínimo del lab: `Spring Web` trae MVC y Tomcat;
  `Actuator` trae los endpoints de diagnóstico, que en este lab son la herramienta
  principal, no un extra de producción.

El botón `EXPLORE` de esa página, antes de descargar, te muestra el árbol de ficheros
generado. Úsalo una vez: es la forma más rápida de ver que un proyecto Boot son seis
ficheros y ningún XML de configuración.

### Forma 2 — `curl` a la API del Initializr

La web es un cliente de una API pública, y esa API es lo que usarías en un script de
scaffolding corporativo. Empecemos pidiendo exactamente lo que el curso declara:

```bash
curl -G https://start.spring.io/starter.tgz \
  -d type=maven-project \
  -d language=java \
  -d bootVersion=3.5.16 \
  -d groupId=com.invlab \
  -d artifactId=inv-api \
  -d name=inv-api \
  -d packageName=com.invlab.invapi \
  -d javaVersion=21 \
  -d packaging=jar \
  -d dependencies=web,actuator \
  -d baseDir=inv-api
```

```text
{"timestamp":"2026-09-18T02:24:13.458Z","status":400,"error":"Bad Request","message":"Invalid Spring Boot version '3.5.16', Spring Boot compatibility range is >=4.0.0","path":"/starter.zip"}
```

Eso no es un error tuyo: es el primer hallazgo del lab, y hay que leerlo entero.

- **`status: 400`**, no `404` ni `500`. El servicio entendió la petición y rechazó **un
  valor**: el problema está en lo que pediste, no en la ruta ni en el servicio.
- **`Spring Boot compatibility range is >=4.0.0`** es la frase que importa. El Initializr
  solo sirve líneas con **soporte open source vigente**, y la línea 3.5 lo perdió el 30 de
  junio de 2026 (`01` §8). No es que 3.5.16 no exista: es que esta herramienta ya no lo
  ofrece.
- **La tubería a `tar` desapareció del comando** a propósito. Si dejas el
  `| tar -xzvf -` de un tutorial, `tar` recibe este JSON, falla con
  `gzip: stdin: not in gzip format` y el mensaje útil —el del servidor— se pierde. Cuando
  generes de verdad, primero miras la respuesta y después la desempaquetas.
- **Fíjate en `"path":"/starter.zip"`** aunque tú pediste `starter.tgz`: el manejador de
  errores reporta la ruta canónica. Es un detalle menor y evita que pierdas cinco minutos
  pensando que te equivocaste de endpoint.

Confirma el catálogo en vez de creerte el mensaje:

```bash
curl -s -H 'Accept: application/json' https://start.spring.io/metadata/client \
  | jq '{default: .bootVersion.default, values: [.bootVersion.values[].id]}'
```

```text
{
  "default": "4.1.1.RELEASE",
  "values": [
    "4.2.0.BUILD-SNAPSHOT",
    "4.2.0.M1",
    "4.1.2.BUILD-SNAPSHOT",
    "4.1.1.RELEASE",
    "4.0.9.BUILD-SNAPSHOT",
    "4.0.8.RELEASE"
  ]
}
```

- **`/metadata/client`** devuelve el catálogo entero en JSON: versiones de Boot admitidas,
  versiones de Java, tipos de proyecto e identificadores de dependencia. Es la fuente que
  evita inventar un parámetro.
- **`-H 'Accept: application/json'`** es necesario porque sin cabecera el servicio devuelve
  la página HTML. Es la causa número uno de que este comando "no funcione".
- **No hay ningún `3.5.x` en la lista**, y el `default` es `4.1.1.RELEASE`: eso confirma el
  400 desde el otro lado y, de paso, te dice qué vas a obtener si no pasas `bootVersion`.
- **Las `BUILD-SNAPSHOT` y las `M1` están ahí para probar**, no para trabajar. El curso no
  usa ninguna, por la misma razón por la que no usa `latest`.

Así que se genera con los valores por defecto y se corrige después:

```bash
curl -G https://start.spring.io/starter.tgz \
  -d type=maven-project \
  -d language=java \
  -d groupId=com.invlab \
  -d artifactId=inv-api \
  -d name=inv-api \
  -d packageName=com.invlab.invapi \
  -d javaVersion=21 \
  -d packaging=jar \
  -d dependencies=web,actuator \
  -d baseDir=inv-api \
  | tar -xzvf -
```

- **`-G`** convierte los `-d` en parámetros de *query string* en lugar de cuerpo de un
  `POST`. Sin `-G`, `curl` manda un `POST` y el Initializr responde `405`.
- **`starter.tgz`** devuelve un `tar.gz`; el endpoint hermano `starter.zip` devuelve un
  zip. Se usa el primero porque se puede desempaquetar en la misma tubería, sin fichero
  intermedio — ahora que sabemos que la respuesta es un tar y no un JSON de error.
- **`type=maven-project`** es el identificador exacto del tipo; `maven-build` devolvería
  **solo** el `pom.xml`, sin esqueleto, que es útil para comparar dos configuraciones.
- **`dependencies=web,actuator`** son los identificadores cortos de las dependencias, los
  mismos que aparecen en la URL cuando las eliges en la web. No son los `artifactId`, y el
  nombre corto `web` sigue existiendo aunque el artefacto que genere haya cambiado de
  nombre en 4.x — eso se ve en §4.
- **`baseDir=inv-api`** hace que el tar contenga un directorio raíz. Sin él, el contenido
  se desparrama en el directorio actual — y eso es exactamente lo que pasa la primera vez
  que alguien corre esto sin leerlo.
- **`tar -xzvf -`** lee de la entrada estándar (`-`): `x` extrae, `z` descomprime gzip,
  `v` lista lo extraído y `f -` es la fuente. La lista es la comprobación: si no ves
  `inv-api/pom.xml`, algo falló.
- **Ya no pasamos `bootVersion`**, y eso hay que decirlo en voz alta: el script queda a
  merced del valor por defecto del servicio, que cambia. Es una deuda consciente, y se
  paga en §4 fijando la versión en el `pom.xml`, que es donde queda versionada.

### Forma 3 — Spring Boot CLI

```bash
sdk install springboot 3.5.16
spring --version

spring init \
  --build=maven \
  --java-version=21 \
  --group-id=com.invlab \
  --artifact-id=inv-api \
  --name=inv-api \
  --package-name=com.invlab.invapi \
  --dependencies=web,actuator \
  inv-api
```

- **`sdk install springboot 3.5.16`** usa SDKMAN, que es la forma que la documentación
  oficial recomienda en Linux y macOS. Instalar el CLI de 3.5.16 **no** te devuelve la
  capacidad de generar proyectos 3.5.16: el CLI no genera nada por su cuenta.
- **`spring init` es un cliente del mismo servicio remoto**: bajo el capó hace la misma
  llamada HTTP que la forma 2. Por eso `--boot-version=3.5.16` recibe exactamente el mismo
  rechazo que acabas de ver, con el mensaje del servidor envuelto en la salida del CLI. Sin
  red no funciona ninguna de las tres vías.
- **`--dependencies`** acepta los mismos identificadores cortos, y `spring init --list` los
  imprime en tabla —junto con las versiones de Boot admitidas—, que es más cómodo que el
  `jq` de arriba cuando buscas uno.
- **El último argumento sin flag** (`inv-api`) es el directorio destino. Si termina en
  `.zip`, el CLI escribe el zip en vez de extraerlo.

> **📝 Contexto: el CLI de hoy no es el CLI del que hablan los tutoriales viejos.** Hasta
> Boot 2.x, el CLI ejecutaba scripts Groovy sueltos (`spring run app.groovy`) y esa era su
> gracia. Eso **se eliminó en Boot 3.0**. Lo que queda en 3.5 son tres cosas útiles:
> `spring init`, `spring encodepassword` (útil en [`L08`](l08-security-y-batch.md)) y un shell interactivo. Si lees un
> artículo que promete arrancar un endpoint con seis líneas de Groovy, es de 2019.

### El veredicto

| | Web | `curl` a la API | CLI |
|---|---|---|---|
| Descubrir qué dependencias existen | ✅ la mejor | ❌ hay que consultar metadata | 🟡 `--list` |
| Reproducible en un script | ❌ | ✅ | ✅ |
| Requiere instalar algo | ❌ | ❌ | ✅ SDKMAN + CLI |
| Genera el baseline del curso | ❌ 400 | ❌ 400 | ❌ 400 |

**La decisión de tech lead es la del medio.** La web se usa una vez para explorar; lo que
va al repositorio de plantillas corporativo es el `curl`, porque no depende de que nadie
instale nada y porque **lo que genera se puede corregir en el mismo script**. La última
fila es el hallazgo del lab y no admite matices: ninguna de las tres te da 3.5.16, así que
el paso de §4 no es opcional para nadie.

> **⚠️ Trabajar sobre una línea sin soporte OSS tiene costes operativos concretos, y este
> es el primero que te encuentras.** No es un argumento abstracto de calendario: la
> herramienta oficial de scaffolding se niega a generarte el proyecto, y a partir de ahí
> vienen los demás —parches de seguridad solo bajo contrato, librerías de terceros que
> dejan de publicar para tu línea, guías oficiales que documentan otra cosa—. Es
> exactamente lo que `01` §8 pide poder defender en una entrevista: la respuesta madura no
> es "hay que actualizar", es "conozco mi ventana de soporte, sé qué me cuesta hoy y tengo
> un plan con fecha".

---

## 4. 🧱 El `pom.xml` generado y su bajada al baseline

Abre lo que acabas de generar. El esqueleto son nueve ficheros —`pom.xml`, el wrapper, una
clase de aplicación, una de test, `application.properties`, `.gitignore`, `.gitattributes`
y un `HELP.md`— y el interesante es el primero:

```xml
<parent>
    <groupId>org.springframework.boot</groupId>
    <artifactId>spring-boot-starter-parent</artifactId>
    <version>4.1.1</version>
    <relativePath/> <!-- lookup parent from repository -->
</parent>

<groupId>com.invlab</groupId>
<artifactId>inv-api</artifactId>
<version>0.0.1-SNAPSHOT</version>
<name>inv-api</name>

<properties>
    <java.version>21</java.version>
</properties>

<dependencies>
    <dependency>
        <groupId>org.springframework.boot</groupId>
        <artifactId>spring-boot-starter-actuator</artifactId>
    </dependency>
    <dependency>
        <groupId>org.springframework.boot</groupId>
        <artifactId>spring-boot-starter-webmvc</artifactId>
    </dependency>

    <dependency>
        <groupId>org.springframework.boot</groupId>
        <artifactId>spring-boot-starter-actuator-test</artifactId>
        <scope>test</scope>
    </dependency>
    <dependency>
        <groupId>org.springframework.boot</groupId>
        <artifactId>spring-boot-starter-webmvc-test</artifactId>
        <scope>test</scope>
    </dependency>
</dependencies>

<build>
    <plugins>
        <plugin>
            <groupId>org.springframework.boot</groupId>
            <artifactId>spring-boot-maven-plugin</artifactId>
        </plugin>
    </plugins>
</build>
```

Tres cosas de ese fichero **no** son las del curso, y una de ellas sorprende:

- **`<version>4.1.1</version>` en el parent** es la consecuencia directa de §3: pediste sin
  `bootVersion` y te dieron el valor por defecto del servicio.
- **`spring-boot-starter-webmvc`**, no `spring-boot-starter-web`. El identificador corto que
  pasaste en la URL sigue llamándose `web`; el artefacto que genera cambió de nombre.
- **Dos starters de test** —`spring-boot-starter-webmvc-test` y
  `spring-boot-starter-actuator-test`— en lugar del único `spring-boot-starter-test` de
  toda la línea 3.x.
- **`<java.version>21</java.version>` sí se respetó**, así que esa no hay que tocarla.
- **El resto del fichero generado trae bloques de metadatos vacíos** (`<description/>`,
  `<url/>`, `<licenses>`, `<developers>`, `<scm>`) que el Initializr deja preparados para
  que los rellenes. No hacen nada y se pueden borrar; aquí se omiten para que el bloque se
  lea.

> **📝 El renombrado de los starters es uno de los cambios visibles de la línea 4.x.** La
> línea 4 reorganizó los artefactos —`web` pasó a `webmvc` para dejar el nombre libre y
> distinguirlo del stack reactivo, y el starter de test se partió por módulo, de forma que
> cada starter funcional trae su starter de test hermano—. La consecuencia práctica es que
> un `pom.xml` de 3.5 no se sube de versión cambiando solo el número del parent, y que
> media internet —incluidas respuestas de hace seis meses— nombra artefactos que en 4.x ya
> no existen con ese nombre. El apéndice [`A04`](a04-migracion-3-5-a-4-x.md) desarrolla la migración entera; aquí vamos
> en la dirección contraria.

### La bajada al baseline, paso a paso

Son tres cambios en el `pom.xml` y ninguno en el código Java:

```xml
<parent>
    <groupId>org.springframework.boot</groupId>
    <artifactId>spring-boot-starter-parent</artifactId>
    <version>3.5.16</version>
    <relativePath/>
</parent>

<dependencies>
    <dependency>
        <groupId>org.springframework.boot</groupId>
        <artifactId>spring-boot-starter-web</artifactId>
    </dependency>
    <dependency>
        <groupId>org.springframework.boot</groupId>
        <artifactId>spring-boot-starter-actuator</artifactId>
    </dependency>
    <dependency>
        <groupId>org.springframework.boot</groupId>
        <artifactId>spring-boot-starter-test</artifactId>
        <scope>test</scope>
    </dependency>
</dependencies>
```

- **`4.1.1` → `3.5.16` en el parent.** Es el cambio que arrastra todo lo demás: el parent
  hereda de `spring-boot-dependencies`, el BOM, y con él cambian de golpe las versiones de
  unas 250 librerías, Spring Framework incluido. Por eso se toca **primero** y se verifica
  después: si te quedas a medias, el error que obtienes no menciona la versión.
- **`spring-boot-starter-webmvc` → `spring-boot-starter-web`**, porque en 3.5 el artefacto
  con el nuevo nombre no existe. Si dejas el nombre de 4.x, Maven falla al resolver con un
  `Could not find artifact org.springframework.boot:spring-boot-starter-webmvc:jar:3.5.16`,
  que es un error honesto pero desconcertante si no sabes que el nombre cambió.
- **Los dos starters de test → `spring-boot-starter-test`**, por la misma razón y con el
  mismo síntoma. El único de 3.5 trae JUnit 5, AssertJ, Mockito, Hamcrest, JSONassert,
  JsonPath y `spring-test`: lo que en 4.x está repartido, aquí viene junto.
- **`<scope>test</scope>` se conserva tal cual**: ese starter solo está en el classpath de
  test y no viaja en el jar final. Un `scope` equivocado aquí es la forma más fácil de
  meter Mockito en producción.
- **`<java.version>21</java.version>` no se toca.** No es una propiedad de Maven: es una
  propiedad **que el parent de Boot define y usa** para fijar `maven.compiler.release`, y
  21 está dentro del rango que admite 3.5 (17 a 25).
- **Ninguna dependencia lleva `<version>`, ni antes ni después.** Lo explica el BOM
  (`01` §5): la versión de cada una la decide `spring-boot-dependencies`. Esa es justo la
  razón por la que bajar de línea es un cambio de una línea y no de veinte.
- **`spring-boot-maven-plugin` sin configuración** hereda del parent la ejecución del goal
  `repackage`, que convierte el jar normal de Maven en el jar ejecutable de `01` §6. Si lo
  borras, `./mvnw package` sigue funcionando y el jar resultante **no** arranca:
  `no main manifest attribute`.
- **`<relativePath/>` vacío** evita que Maven busque el parent en el directorio de arriba
  del disco. En un monorepo con otro `pom.xml` por encima, sin esta línea obtienes un error
  de resolución que no menciona la palabra "parent" por ninguna parte.
- **`<version>0.0.1-SNAPSHOT`** marca el artefacto como versión en desarrollo: Maven trata
  los `SNAPSHOT` distinto —los revalida contra el repositorio remoto— y muchas herramientas
  se niegan a desplegarlos. En el lab da igual y no se toca; en banca, el paso de `SNAPSHOT`
  a versión fija es el momento del release.

### Comprobar que la bajada tomó efecto

No des por bueno un cambio de versiones porque el fichero diga otra cosa. La verificación
es el árbol de dependencias resuelto:

```bash
cd inv-api
./mvnw dependency:tree | grep -A9 'spring-boot-starter-web:jar'
```

```text
[INFO] +- org.springframework.boot:spring-boot-starter-web:jar:3.5.16:compile
[INFO] |  +- org.springframework.boot:spring-boot-starter-json:jar:3.5.16:compile
[INFO] |  |  +- com.fasterxml.jackson.datatype:jackson-datatype-jdk8:jar:2.21.4:compile
[INFO] |  |  \- com.fasterxml.jackson.module:jackson-module-parameter-names:jar:2.21.4:compile
[INFO] |  +- org.springframework.boot:spring-boot-starter-tomcat:jar:3.5.16:compile
[INFO] |  |  +- org.apache.tomcat.embed:tomcat-embed-core:jar:10.1.55:compile
[INFO] |  |  +- org.apache.tomcat.embed:tomcat-embed-el:jar:10.1.55:compile
[INFO] |  |  \- org.apache.tomcat.embed:tomcat-embed-websocket:jar:10.1.55:compile
[INFO] |  +- org.springframework:spring-web:jar:6.2.19:compile
[INFO] |  |  \- org.springframework:spring-beans:jar:6.2.19:compile
```

- **`dependency:tree`** imprime el árbol completo de dependencias **resueltas**, no las que
  tú declaraste. Es el comando con el que se resuelven los conflictos de versiones reales.
- **`grep -A9`** recorta a la rama que interesa. Sin filtro, un proyecto Boot mediano
  imprime doscientas líneas y no encuentras nada; el filtro por artefacto
  (`-Dincludes=org.springframework.boot:spring-boot-starter-web`) hace lo mismo desde el
  propio plugin.
- **`spring-web:jar:6.2.19`** es la comprobación que buscábamos: la bajada del parent
  arrastró Spring Framework al 6.2.19 del baseline (§5.2 de la guía). Si ahí dice `7.x`, el
  parent no cambió o hay otro `pom.xml` mandando.
- **`tomcat-embed-core:jar:10.1.55`** sale del BOM sin que nadie escribiera esa versión: es
  la línea 10.1 que declara el baseline, y es la respuesta a "¿quién fija la versión de
  Tomcat?" sin abrir el código de Boot.
- **Fíjate en lo que no hay dentro del starter: ninguna clase.** Un starter es un `pom.xml`
  sin código cuyo único contenido es una lista de dependencias (`01` §4). Por eso el starter
  "trae Tomcat" solo en el sentido de que **declara** `spring-boot-starter-tomcat`, que a su
  vez declara Tomcat — y por eso puedes cambiar de servidor excluyendo esa rama.

Y el otro comando de auditoría, para cuando la pregunta es "¿de dónde salió esta versión?"
en vez de "¿qué versión ganó?":

```bash
./mvnw -q help:effective-pom | grep -A2 '<artifactId>tomcat-embed-core'
```

- **`help:effective-pom`** imprime el POM **después** de resolver la herencia: el tuyo más
  el del parent más el BOM entero. Es donde se ve que la versión está declarada en un
  `dependencyManagement` que tú nunca escribiste.
- **`-q`** silencia los banners de Maven y deja solo la salida del goal, que es lo que
  quieres cuando vas a pasarlo por `grep`.
- **Los dos comandos no son intercambiables**: `dependency:tree` dice qué versión **ganó**
  en el árbol real; `help:effective-pom` dice qué versión está **declarada**. Cuando no
  coinciden, hay un conflicto de versiones y la respuesta está en el primero.

---

## 5. 🧱 El resto del esqueleto: clase principal, propiedades y wrapper

El código Java generado **no** hubo que tocarlo en la bajada de §4 —el cambio de nombre de
 los starters no cambia el nombre de ninguna clase—, así que esto es literalmente lo que
 bajó del Initializr. Es una sola clase de producción:

```java
package com.invlab.invapi;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;

@SpringBootApplication
public class InvApiApplication {

    public static void main(String[] args) {
        SpringApplication.run(InvApiApplication.class, args);
    }
}
```

- **`@SpringBootApplication`** son las tres anotaciones de `06` §3. La tercera,
  `@ComponentScan`, es la que hace que **el paquete de esta clase sea el paquete raíz** del
  escaneo: todo lo que escribas bajo `com.invlab.invapi` se descubre solo, y todo lo que
  pongas fuera no existe para el contenedor.
- **`SpringApplication.run(Class, String[])`** devuelve el `ApplicationContext` ya
  refrescado. Aquí se ignora el valor devuelto, pero es el que usarías para inspeccionar
  beans desde un test o desde un `main` de diagnóstico.
- **`args` se pasa entero** y no por decoración: es lo que convierte `--server.port=9090` en
  una property de la máxima precedencia (`07`), y lo que alimenta al `ApplicationRunner` de
  §11. Un `main` que llama a `run(Clase.class)` sin argumentos rompe las dos cosas y no
  avisa.
- **La clase es `public`**, a diferencia del resto del código del lab, que es
  package-private por §5.1 de la guía. El motivo es concreto: el `JarLauncher` la invoca por
  reflexión desde otro classloader, y una clase package-private ahí no se alcanza.

Ahora las propiedades. El Initializr genera un `src/main/resources/application.properties`
con una sola línea; déjalo con estas cinco, que son las cuatro nuevas más la que ya venía:

```properties
spring.application.name=inv-api
server.port=8080
management.server.port=8081
management.endpoints.web.exposure.include=health,info,conditions,beans,configprops,env
management.endpoint.health.show-details=always
```

- **`spring.application.name`** ya venía generada. En Boot 3.5 no es decorativa: aparece
  entre corchetes en cada línea del log por defecto, y es la que usarán las métricas y las
  trazas de [`L07`](l07-actuator-metricas-y-trazas.md).
- **`server.port=8080`** es el valor por defecto y se escribe igual, explícito. En el lab
  todo puerto está declarado: cuando en §12 provoquemos el choque, quiero que el número esté
  a la vista y no implícito.
- **`management.server.port=8081`** mueve Actuator a **un segundo puerto**, con su propio
  contexto de servlet. Es el reparto que fija `L00` §7 y la decisión correcta en banca: el
  puerto de diagnóstico no se publica al mismo sitio que el tráfico de negocio.
- **`management.endpoints.web.exposure.include`** abre por HTTP los endpoints que este lab
  usa. Por defecto Boot expone **solo `health`**, y ese es el comportamiento seguro.
- **`management.endpoint.health.show-details=always`** hace que `/actuator/health` devuelva
  el detalle por componente en vez de un `{"status":"UP"}` pelado. En §9 ese detalle es la
  pista que resuelve el caso.

> **⚠️ Esas dos últimas propiedades son de laboratorio, no de producción.** `conditions`,
> `beans`, `configprops` y `env` publican tu configuración interna —incluidos nombres de
> propiedades y de clases— a quien alcance el puerto. En un servicio real van detrás de
> autenticación, y `show-details` se deja en `when-authorized`. Se hace bien en `L08`.

> **📝 El fichero es `.properties` y el curso usa YAML en los labs.** La conversión, con el
> argumento de por qué YAML y las trampas que trae, es el primer paso de `L02`. Aquí se
> conserva el formato que genera el Initializr para que lo que ves en tu disco coincida con
> lo que lees.

Y el wrapper, que es el tercer elemento del esqueleto y el que más gente ignora:

```bash
ls -la mvnw mvnw.cmd .mvn/wrapper/
cat .mvn/wrapper/maven-wrapper.properties
```

- **`mvnw` / `mvnw.cmd`** son scripts que descargan la versión de Maven declarada en
  `maven-wrapper.properties` y ejecutan esa. El `distributionUrl` de ese fichero es la
  versión exacta: es el mismo principio que "nunca `latest`" aplicado al build.
- **El wrapper se versiona en git**, los tres ficheros. Un repositorio sin wrapper obliga a
  cada máquina a tener el Maven correcto instalado, y el día que un agente de CI trae otro
  menor, el build "solo falla en el pipeline".
- **`./mvnw` frente a `mvn`:** el primero garantiza la versión; el segundo usa lo que haya
  en el `PATH`. En este curso siempre es `./mvnw`.

---

## 6. ⚖ Tres formas de arrancarlo

### `./mvnw spring-boot:run`

```bash
./mvnw spring-boot:run
```

- **`spring-boot:run`** compila si hace falta y arranca la aplicación **en una JVM aparte**
  (`fork` está activo por defecto desde Boot 2.2), con el classpath de clases explotado:
  `target/classes` más los jars del repositorio local. No hay jar ejecutable por ningún
  lado.
- **La primera ejecución tarda** porque descarga el BOM entero a `~/.m2`. De tres a diez
  minutos según tu red; las siguientes, segundos.
- **Para pasar argumentos a la aplicación** se usa `-Dspring-boot.run.arguments`, y para
  pasar opciones a la JVM, `-Dspring-boot.run.jvmArguments`. Confundirlas es clásico:

```bash
./mvnw spring-boot:run -Dspring-boot.run.arguments="--server.port=9090"
./mvnw spring-boot:run -Dspring-boot.run.jvmArguments="-Xmx256m"
```

- **La primera** llega a `SpringApplication.run` como argumento de línea de comandos y se
  convierte en una property de la fuente de mayor precedencia (`07`).
- **La segunda** configura la JVM hija: memoria, agentes, `-XX:`. Poner `-Xmx256m` en
  `arguments` no produce error; simplemente lo ignora Spring y tu límite de heap nunca se
  aplica.
- **`-Dspring-boot.run.profiles=local`** es el atajo para activar el perfil sin escribir el
  argumento completo; se usa a fondo en `L02`.

### `java -jar`

```bash
./mvnw clean package
ls -lh target/*.jar
java -jar target/inv-api-0.0.1-SNAPSHOT.jar
```

- **`clean`** borra `target/` antes de construir. Sin él, arrastras clases de una compilación
  anterior, y ese es el origen del "pero si yo borré esa clase" que sobrevive a tres
  reinicios.
- **`package`** ejecuta los tests y después empaqueta. El `repackage` del plugin de Boot
  deja **dos** ficheros en `target/`: el jar ejecutable (unos 25 MB con estas dependencias)
  y `inv-api-0.0.1-SNAPSHOT.jar.original`, que es el jar normal de Maven antes de que el
  plugin lo tocara.
- **`java -jar`** es lo más parecido a producción que hay en este lab: mismo classloader
  anidado, mismo orden de carga, mismos argumentos. Si algo funciona con `spring-boot:run` y
  falla con `java -jar`, la diferencia casi siempre es un recurso que se encontraba en
  `target/classes` y no está dentro del jar.
- **`-Dspring.profiles.active=local` va antes de `-jar`** (es una propiedad de sistema de la
  JVM); `--spring.profiles.active=local` va **después** del nombre del jar (es un argumento
  de la aplicación). Los dos funcionan; invertir el orden no.

### El IDE

El IDE ejecuta el `main` como cualquier otra clase Java, con el classpath del proyecto que
él mismo gestiona.

> Nunca respondas: ~~"da igual, el IDE arranca lo mismo que `java -jar`"~~

> Mejor: "El IDE arranca la clase `main` con un classpath explotado que construye él, no el
> jar empaquetado. Es el ciclo más rápido para desarrollar y el menos representativo para
> diagnosticar: el orden del classpath puede diferir, el `repackage` no participa y, si hay
> DevTools, además hay un segundo classloader que recarga clases."

Las tres formas arrancan la misma aplicación y **no** arrancan el mismo proceso:

| | `spring-boot:run` | `java -jar` | IDE |
|---|---|---|---|
| Classpath | explotado, ordenado por Maven | jars anidados en `BOOT-INF/lib` | explotado, ordenado por el IDE |
| Participa el `repackage` | ❌ | ✅ | ❌ |
| Fidelidad a producción | media | ✅ la mayor | baja |
| Ciclo de edición | recompilar y relanzar | empaquetar y relanzar | ✅ el más corto |

---

## 7. 🩺 El log de arranque, línea por línea

Deja la aplicación corriendo con `java -jar` y lee lo que imprimió. Esto no es relleno: la
mitad de los diagnósticos de los labs siguientes empiezan por notar que **falta** una de
estas líneas.

```text
  .   ____          _            __ _ _
 /\\ / ___'_ __ _ _(_)_ __  __ _ \ \ \ \
( ( )\___ | '_ | '_| | '_ \/ _` | \ \ \ \
 \\/  ___)| |_)| | | | | || (_| |  ) ) ) )
  '  |____| .__|_| |_|_| |_\__, | / / / /
 =========|_|==============|___/=/_/_/_/

 :: Spring Boot ::                (v3.5.16)

2026-09-17T10:14:02.118-05:00  INFO 41822 --- [inv-api] [           main] com.invlab.invapi.InvApiApplication      : Starting InvApiApplication v0.0.1-SNAPSHOT using Java 21.0.9 with PID 41822 (/Users/oskar/lab/inv-api/target/inv-api-0.0.1-SNAPSHOT.jar started by oskar in /Users/oskar/lab/inv-api)
2026-09-17T10:14:02.121-05:00  INFO 41822 --- [inv-api] [           main] com.invlab.invapi.InvApiApplication      : No active profile set, falling back to 1 default profile: "default"
2026-09-17T10:14:02.905-05:00  INFO 41822 --- [inv-api] [           main] o.s.b.w.embedded.tomcat.TomcatWebServer   : Tomcat initialized with port 8080 (http)
2026-09-17T10:14:02.916-05:00  INFO 41822 --- [inv-api] [           main] o.apache.catalina.core.StandardService    : Starting service [Tomcat]
2026-09-17T10:14:02.917-05:00  INFO 41822 --- [inv-api] [           main] o.apache.catalina.core.StandardEngine    : Starting Servlet engine: [Apache Tomcat/10.1.55]
2026-09-17T10:14:02.964-05:00  INFO 41822 --- [inv-api] [           main] o.a.c.c.C.[Tomcat].[localhost].[/]       : Initializing Spring embedded WebApplicationContext
2026-09-17T10:14:02.965-05:00  INFO 41822 --- [inv-api] [           main] w.s.c.ServletWebServerApplicationContext : Root WebApplicationContext: initialization completed in 812 ms
2026-09-17T10:14:03.278-05:00  INFO 41822 --- [inv-api] [           main] o.s.b.a.e.web.EndpointLinksResolver      : Exposing 6 endpoints beneath base path '/actuator'
2026-09-17T10:14:03.321-05:00  INFO 41822 --- [inv-api] [           main] o.s.b.w.embedded.tomcat.TomcatWebServer   : Tomcat started on port 8081 (http) with context path '/'
2026-09-17T10:14:03.334-05:00  INFO 41822 --- [inv-api] [           main] o.s.b.a.w.s.WelcomePageHandlerMapping    : Adding welcome page template: index
2026-09-17T10:14:03.352-05:00  INFO 41822 --- [inv-api] [           main] o.s.b.w.embedded.tomcat.TomcatWebServer   : Tomcat started on port 8080 (http) with context path '/'
2026-09-17T10:14:03.361-05:00  INFO 41822 --- [inv-api] [           main] com.invlab.invapi.InvApiApplication      : Started InvApiApplication in 1.457 seconds (process running for 1.681)
```

Lo que dice cada bloque, de arriba abajo:

- **El banner** imprime la versión de Boot que corre **de verdad**, y en este lab es
  además la prueba en tres segundos de que la bajada de §4 tomó efecto: si el Initializr te
  dio 4.1.1 y aquí lees `(v3.5.16)`, el cambio del parent llegó hasta el runtime. Si dice
  otra cosa, ganó otro `pom.xml` o el IDE lanzó otro artefacto. Se quita con
  `spring.main.banner-mode=off`, y en producción se quita.
- **`Starting ... using Java 21.0.9 with PID 41822`** te da la versión de JVM real, el PID y
  el directorio de trabajo. El PID lo vas a necesitar en §12; el directorio explica de dónde
  se resolverán las rutas relativas.
- **`No active profile set, falling back to 1 default profile: "default"`** es una línea que
  la gente lee mil veces sin registrarla, y es **el aviso de que tu `application-local.yml`
  no se está aplicando**. En `L02` esta línea cambia y se vuelve la primera que miras.
- **`[inv-api]`** entre corchetes es `spring.application.name`; **`[ main]`** es el nombre
  del hilo. Que todo el arranque ocurra en `main` no es un detalle: significa que cualquier
  cosa lenta aquí —un `ApplicationRunner`, una conexión remota— retrasa el momento en que el
  proceso acepta tráfico.
- **`Tomcat initialized with port 8080` frente a `Tomcat started on port 8080`.** Son dos
  momentos distintos: el primero crea el conector, el segundo **abre el socket**. Entre los
  dos ocurre el `refresh()` entero del contexto (`02`). Si el arranque revienta en medio,
  verás el primero y no el segundo.
- **`Tomcat started on port 8081`** aparece **antes** que el de 8080 porque es el contexto de
  gestión, que es un contexto hijo con su propio servidor: eso es `management.server.port` en
  acción. Ver dos "Tomcat started" con puertos distintos es la confirmación visual de que la
  separación funcionó.
- **`Exposing 6 endpoints beneath base path '/actuator'`** cuenta los endpoints que abriste
  en §5. Si esperabas `conditions` y el número es 1, te falta la propiedad de exposición.
- **`Root WebApplicationContext: initialization completed in 812 ms`** es el tiempo del
  contexto; **`Started ... in 1.457 seconds (process running for 1.681)`** es el total, y la
  diferencia entre ambos números es JVM, classloading y `repackage`. Los dos se miden en
  `L09`, donde se intenta bajarlos.

Compruébalo desde fuera antes de seguir:

```bash
curl -s localhost:8080/actuator/health | jq .
curl -s localhost:8081/actuator/health | jq .
```

- **El primero falla o devuelve 404**: en el puerto 8080 ya no hay Actuator, porque lo
  moviste. Es el resultado esperado, no un error.
- **El segundo** devuelve `{"status":"UP","components":{...}}`. Guarda mentalmente qué
  componentes lista hoy: en §9 aparece uno nuevo que nadie pidió.

---

## 8. 🩺 El informe de condiciones: `--debug` y `/actuator/conditions`

Esta es la herramienta central del lab. Hay dos caminos al mismo dato.

### En frío, al arrancar

```bash
java -jar target/inv-api-0.0.1-SNAPSHOT.jar --debug 2>&1 | tee target/startup-debug.log
```

- **`--debug`** activa el `ConditionEvaluationReport` y lo imprime al terminar el arranque.
  **No sube el nivel de log de tu aplicación**: eso es `logging.level.root=DEBUG`, y son
  cosas distintas por más que la palabra se parezca (`06` §6).
- **`2>&1`** redirige el error estándar a la salida estándar. Boot escribe el log por
  `stdout`, pero la traza de un fallo puede salir por `stderr`; sin esta redirección, el
  `tee` se pierde justo la parte interesante.
- **`tee target/startup-debug.log`** guarda una copia y sigue imprimiendo en pantalla. El
  informe son entre mil y dos mil líneas: no se lee a ojo, se filtra. Y guardarlo en
  `target/` no es casual —desaparece con `./mvnw clean`, que es donde queremos la basura.

El informe tiene los tres bloques de `06` §6. Búscalos así:

```bash
grep -n "Positive matches\|Negative matches\|Exclusions\|Unconditional classes" target/startup-debug.log
grep -c "" target/startup-debug.log
```

- **El primer `grep -n`** te da el número de línea de cada cabecera, que es como se navega
  un fichero de este tamaño sin abrirlo entero.
- **`Unconditional classes`** es el cuarto bloque, el que `06` no desarrolla: son las
  autoconfiguraciones que se aplican **sin condición alguna** —la de propiedades de
  configuración, por ejemplo—. Es corto y vale la pena mirarlo una vez.
- **`grep -c ""` cuenta líneas.** Que el arranque de una aplicación con dos starters genere
  más de mil líneas de informe es, en sí mismo, la respuesta a "¿cuántas decisiones toma
  Boot por mí?".

### En caliente, por Actuator

```bash
curl -s localhost:8081/actuator/conditions | jq '.contexts["inv-api"].positiveMatches | keys | length'
curl -s localhost:8081/actuator/conditions | jq '.contexts["inv-api"].negativeMatches | keys | length'
```

- **`/actuator/conditions`** devuelve el mismo informe en JSON, sin reiniciar nada. Es el
  camino correcto cuando la aplicación ya está arriba, que en un entorno compartido es
  siempre.
- **`.contexts["inv-api"]`** es la clave del contexto, y coincide con
  `spring.application.name`. Con el contexto de gestión aparte, el JSON trae **dos**
  contextos: el tuyo y el hijo de Actuator. Filtrar por el nombre evita mezclarlos.
- **`| keys | length`** cuenta las entradas de cada bloque en vez de imprimirlas. Es la
  forma de tener una cifra antes y después de un cambio, que es como se demuestra que el
  cambio hizo algo.

> **💡 Truco.** Cuando ya sabes qué buscas, `jq` te da el motivo exacto en una línea:
> `curl -s localhost:8081/actuator/conditions | jq '.contexts["inv-api"].negativeMatches | to_entries[] | select(.key | test("Jackson"))'`.
> Lo usas en §10.

---

## 9. 🧱 El `DataSource` que nadie pidió

Ahora el caso real. Un compañero añade una dependencia "para poder usar `JdbcClient` más
adelante" y a partir de ese commit la aplicación tiene un `DataSource`, un pool de conexiones
y un componente nuevo en el health. Vamos a reproducirlo.

Añade esto al `pom.xml`:

```xml
<dependency>
    <groupId>org.springframework.boot</groupId>
    <artifactId>spring-boot-starter-jdbc</artifactId>
</dependency>
<dependency>
    <groupId>com.h2database</groupId>
    <artifactId>h2</artifactId>
    <scope>runtime</scope>
</dependency>
```

- **`spring-boot-starter-jdbc`** trae `spring-jdbc` y **HikariCP**, el pool por defecto de
  Boot. Ninguna de las dos cosas se configura aquí: se declaran y ya.
- **`com.h2database:h2`** es una base embebida que vive en memoria dentro de tu proceso. No
  levanta ningún contenedor y por eso puede estar en este lab; la base de verdad llega en
  `L04` con Postgres.
- **`<scope>runtime</scope>`** significa que el driver está en el classpath al ejecutar pero
  **no al compilar**: no quieres que nadie escriba `import org.h2...` en el código de
  negocio. Es el scope correcto para todo driver JDBC.
- **Ninguna de las dos lleva versión**: las dos están en el BOM.

**Predice antes de ejecutar.** No has escrito `spring.datasource.url` por ningún lado, no
has declarado ningún bean y no has tocado una línea de Java. ¿Qué crees que va a devolver
ahora `/actuator/health`?

```bash
./mvnw -q clean package
java -jar target/inv-api-0.0.1-SNAPSHOT.jar &
sleep 5
curl -s localhost:8081/actuator/health | jq .
```

```text
{
  "status": "UP",
  "components": {
    "db": {
      "status": "UP",
      "details": {
        "database": "H2",
        "validationQuery": "isValid()"
      }
    },
    "diskSpace": { "status": "UP", "details": { ... } },
    "ping": { "status": "UP" }
  }
}
```

Apareció un componente `db`, conectado a una base H2 que nadie configuró. Ahora la pregunta
del lab: **¿quién lo creó y por qué?**

```bash
curl -s localhost:8081/actuator/conditions \
  | jq -r '.contexts["inv-api"].positiveMatches | to_entries[] | select(.key | test("DataSource")) | .key'
```

```text
DataSourceAutoConfiguration
DataSourceAutoConfiguration.PooledDataSourceConfiguration
DataSourceHealthContributorAutoConfiguration
DataSourceTransactionManagerAutoConfiguration
```

Y el motivo, en el informe en frío. En el bloque `Positive matches` está el porqué de la
autoconfiguración raíz:

```text
   DataSourceAutoConfiguration matched:
      - @ConditionalOnClass found required classes 'javax.sql.DataSource',
        'org.springframework.jdbc.datasource.embedded.EmbeddedDatabaseType' (OnClassCondition)
      - @ConditionalOnMissingBean (types: io.r2dbc.spi.ConnectionFactory; SearchStrategy: all) did not find any beans (OnBeanCondition)
```

Y en `Negative matches`, la entrada que mucha gente da por buena al revés — la configuración
embebida es la que **no** entró:

```text
   DataSourceAutoConfiguration.EmbeddedDatabaseConfiguration:
      Did not match:
         - EmbeddedDataSource found supported pooled data source (DataSourceAutoConfiguration.EmbeddedDatabaseCondition)
```

- **La condición que disparó todo es `@ConditionalOnClass`**, y la clase que la satisface la
  trajo el starter. Nadie "pidió" una base de datos: alguien puso un driver en el classpath,
  que para Boot es una declaración de intenciones (`06` §5).
- **Quien registra el bean es `PooledDataSourceConfiguration`**, la anidada que ya viste en
  `positiveMatches`. Su condición es `PooledDataSourceCondition`, un `AnyNestedCondition`
  que basta con que satisfaga uno de sus dos miembros: o hay `spring.datasource.type`
  declarado, o hay un pool soportado en el classpath —el miembro que aquí gana, y cuyo
  mensaje en el informe es `PooledDataSource found supported DataSource`—. El pool lo trajo
  `spring-boot-starter-jdbc`: es **HikariCP**, no una base embebida gestionada por Spring.
- **`EmbeddedDatabaseConfiguration` no se aplicó, y su motivo es el que aparece arriba.**
  `EmbeddedDatabaseCondition` prefiere siempre el pool: si encuentra uno soportado, se aparta
  con `found supported pooled data source`, que es un **no-match**. Leer esa frase como si
  fuera la causa del `DataSource` es el error de lectura más común del informe, porque el
  texto suena afirmativo y está en la columna equivocada.
- **Entonces, ¿de dónde sale el H2 en memoria si nadie configuró una URL?** De
  `DataSourceProperties.determineUrl()`: cuando `spring.datasource.url` está vacía, pregunta
  a `EmbeddedDatabaseConnection` qué base embebida hay en el classpath —H2— y fabrica con
  ella una URL `jdbc:h2:mem:…` que Hikari abre como abriría cualquier otra. Por eso el health
  dice `"database": "H2"` con un pool por debajo. Es una comodidad de desarrollo que en un
  servicio real es un riesgo: arranca "bien" apuntando a la nada, y el fallo aparece cuando
  alguien busca datos que se evaporaron al reiniciar.
- **`DataSourceHealthContributorAutoConfiguration`** es la que añadió el componente `db` al
  health. Por eso el síntoma se vio ahí primero: **la autoconfiguración encadena**, porque
  otras se condicionan con `@ConditionalOnBean` sobre lo que la primera registró.
- **`DataSourceTransactionManagerAutoConfiguration`** te regaló además un
  `PlatformTransactionManager`. Es decir: un `@Transactional` en este proyecto ya haría
  algo, contra una base en memoria, sin que nadie lo haya decidido. Ese escenario completo
  es `L04`.

### Quitarlo a mano

Hay dos formas, y `06` §7 ya dice que excluir suele ser la segunda mejor respuesta. Aquí
es la correcta, porque lo que queremos es que **no exista nada**:

```java
import org.springframework.boot.autoconfigure.jdbc.DataSourceAutoConfiguration;

@SpringBootApplication(exclude = DataSourceAutoConfiguration.class)
public class InvApiApplication { … }
```

```bash
./mvnw -q clean package && java -jar target/inv-api-0.0.1-SNAPSHOT.jar &
sleep 5
curl -s localhost:8081/actuator/health | jq '.components | keys'
```

```text
[
  "diskSpace",
  "ping"
]
```

- **`exclude` acepta la clase**, así que el IDE y el compilador la verifican: si mañana esa
  clase cambia de paquete, el build falla y te enteras. `excludeName` acepta la cadena y no
  verifica nada; se usa cuando la clase no está en tu classpath de compilación.
- **El `import` se escribe entero aquí a propósito**: hay varias clases llamadas
  `DataSourceAutoConfiguration` en el ecosistema (la de JDBC y la de R2DBC, por ejemplo), y
  aceptar la sugerencia equivocada del IDE produce una exclusión que no excluye nada.
- **La equivalente por propiedad** es
  `spring.autoconfigure.exclude=org.springframework.boot.autoconfigure.jdbc.DataSourceAutoConfiguration`,
  y su peligro está en `06` §7: activa por perfil, es una diferencia de comportamiento entre
  entornos que no se ve leyendo el código.
- **Compruébalo también en el informe**: la clase excluida deja de estar en
  `positiveMatches` y aparece en el bloque `Exclusions`. Es la diferencia entre "creo que lo
  quité" y "lo quité".

> **⚠️ Si excluyes por nombre algo que no es una autoconfiguración, el arranque falla.**
> Boot valida la lista y responde con
> `The following classes could not be excluded because they are not auto-configuration classes`.
> Es un fallo honesto y muy agradecido: te dice exactamente qué línea de tu configuración
> está mal.

### Y ahora deshazlo

```bash
git checkout -- pom.xml   # o borra a mano las dos dependencias
```

Quita también el `exclude` de `InvApiApplication`. Dos razones, y las dos importan:

- **Una exclusión de una clase que ya no está en el classpath no compila.** Si borras las
  dependencias y dejas el `exclude`, el error es de compilación y te va a costar treinta
  segundos entender por qué.
- **[`L04`](l04-datos-y-transacciones.md) construye la persistencia de verdad**, con Postgres en Compose y Flyway. Llegar
  allí con una H2 fantasma en el classpath convierte ese lab en una cacería de dos bases de
  datos superpuestas.

---

## 10. 🧱 Tu bean gana: `@ConditionalOnMissingBean` en vivo

`06` §5 afirma que **tu bean siempre gana**. Vamos a verlo con el `ObjectMapper`, que es el
caso que más se toca en un servicio real: fechas, nulos y nombres de propiedad.

```java
package com.invlab.invapi.config;

import com.fasterxml.jackson.databind.ObjectMapper;
import org.springframework.boot.autoconfigure.jackson.JacksonAutoConfiguration;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

@Configuration
class JsonConfig {

    // sustituye al ObjectMapper que declara JacksonAutoConfiguration
    @Bean
    ObjectMapper objectMapper() {
        return new ObjectMapper()
                .findAndRegisterModules();   // registra el módulo de java.time, entre otros
    }
}
```

- **`@Configuration`** marca la clase como fuente de bean definitions; el contenedor la
  descubre por el `@ComponentScan` implícito de §5. Es package-private porque nadie fuera
  del paquete necesita referenciarla.
- **`@Bean` sobre un método** registra lo que devuelve, con el **nombre del método** como
  nombre del bean (`objectMapper`). Ese nombre importa en el siguiente párrafo.
- **`findAndRegisterModules()`** busca módulos de Jackson en el classpath y los registra;
  sin él, un `LocalDateTime` se serializa como un objeto ilegible en vez de como cadena ISO.
  Es exactamente el tipo de decisión por la que uno declara su propio `ObjectMapper`.
- **Lo que este ejemplo enseña no es cómo configurar Jackson** —para eso Boot ofrece
  `Jackson2ObjectMapperBuilderCustomizer`, que es la vía recomendada y no pisa nada—, sino
  **qué le pasa a la autoconfiguración cuando declaras un bean del mismo tipo**.

Arranca con `--debug` y busca el motivo. Y **regenera de paso el informe en frío**: el
`target/startup-debug.log` que guardaste en §8 es de antes de que existiera este
`ObjectMapper`, así que buscar ahí el motivo nuevo no encontraría nada.

```bash
./mvnw -q clean package
java -jar target/inv-api-0.0.1-SNAPSHOT.jar --debug 2>&1 \
  | tee target/startup-debug.log \
  | grep -A3 "jacksonObjectMapper"
```

```text
   JacksonAutoConfiguration.JacksonObjectMapperConfiguration#jacksonObjectMapper:
      Did not match:
         - @ConditionalOnMissingBean (types: com.fasterxml.jackson.databind.ObjectMapper;
           SearchStrategy: all) found beans of type
           'com.fasterxml.jackson.databind.ObjectMapper' objectMapper (OnBeanCondition)
```

- **`tee` antes del `grep`** es lo que hace que el fichero quede con el informe **de esta**
  versión del proyecto y la pantalla muestre solo las cuatro líneas que interesan. Un `tee`
  detrás del `grep` guardaría únicamente el recorte, y el checklist de salida —que vuelve a
  leer este fichero— se quedaría sin contexto.
- **`./mvnw -q clean package` delante no es adorno**: el jar de §9 no contiene la clase
  `JsonConfig`. Correr el jar viejo con `--debug` produce el informe de ayer, que es la forma
  más silenciosa de "demostrar" algo falso.
- **`Did not match`** y aun así todo funciona: esa es la parte contraintuitiva. La
  autoconfiguración **se apartó**, que es justo lo que se espera de ella.
- **`found beans of type ... objectMapper`** nombra a tu bean por su nombre de método. Esa
  línea es la prueba documental de que el ganador fuiste tú, y es lo que enseñas en un code
  review cuando alguien insiste en excluir `JacksonAutoConfiguration`.
- **`SearchStrategy: all`** significa que la condición miró el contexto entero, jerarquía
  incluida — relevante aquí, donde hay un contexto hijo para Actuator.
- **Nadie excluyó nada.** Declarar el bean bastó. Ese es el mecanismo entero.

> **🧠 Modelo mental para la entrevista.** "Para cambiar algo de Boot hay que desactivar su
> autoconfiguración" es falso en la inmensa mayoría de los casos: declara tu bean y la
> condición `@ConditionalOnMissingBean` hace el trabajo. Excluir es para cuando quieres que
> no exista **nada**, como el `DataSource` de §9.

---

## 11. 🧱 Código que corre al arrancar: `ApplicationRunner`

Queremos que `inv-api` imprima al arrancar un resumen del entorno en que corre: qué perfil
está activo, en qué puertos escucha y cuántos beans tiene el contexto. Es el tipo de línea
que en un incidente a las dos de la mañana ahorra una llamada.

```java
package com.invlab.invapi.startup;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.boot.ApplicationArguments;
import org.springframework.boot.ApplicationRunner;
import org.springframework.context.ApplicationContext;
import org.springframework.core.env.Environment;
import org.springframework.stereotype.Component;

@Component
class StartupSummary implements ApplicationRunner {

    private static final Logger log = LoggerFactory.getLogger(StartupSummary.class);

    private final Environment environment;
    private final ApplicationContext context;

    // inyección por constructor: un solo constructor, así que no hace falta @Autowired
    StartupSummary(Environment environment, ApplicationContext context) {
        this.environment = environment;
        this.context = context;
    }

    @Override
    public void run(ApplicationArguments args) {
        log.info("inv-api listo | perfiles={} | http={} | actuator={} | beans={} | dump={}",
                String.join(",", environment.getActiveProfiles()),
                environment.getProperty("server.port"),
                environment.getProperty("management.server.port"),
                context.getBeanDefinitionCount(),
                args.containsOption("dump-beans"));

        if (args.containsOption("dump-beans")) {
            // ordenado, porque el orden de registro no es alfabético y no sirve para comparar
            java.util.Arrays.stream(context.getBeanDefinitionNames()).sorted().forEach(n -> log.info("bean: {}", n));
        }
    }
}
```

- **`ApplicationRunner`** se ejecuta en el paso 8 del arranque (`06` §2): el contexto ya está
  completo y los proxies ya existen (`05`). `CommandLineRunner` hace lo mismo con el
  `String[]` crudo; se prefiere el primero porque parsea las opciones por ti.
- **`@Component`** basta para que se descubra: está bajo `com.invlab.invapi`, el paquete
  raíz del escaneo.
- **`Environment` y `ApplicationContext` se inyectan como cualquier otro bean.** Son beans
  del contenedor y no hay nada especial en pedirlos; sí lo hay en abusar de ellos, porque un
  servicio que inyecta el `ApplicationContext` para buscar beans a mano está reimplementando
  el contenedor.
- **`getActiveProfiles()` devuelve un array vacío** cuando no hay ninguno activo, y por eso
  el log sale con `perfiles=`. Coincide con el `No active profile set` de §7, y en `L02`
  las dos cosas cambian a la vez.
- **`args.containsOption("dump-beans")`** es cierto cuando arrancas con `--dump-beans`.
  Comprueba **opciones** (las que empiezan por `--`); los argumentos sueltos se leen con
  `getNonOptionArgs()`.
- **El logger es de SLF4J, y es `static final`.** Boot trae Logback detrás de SLF4J; nunca se
  usa `System.out` en este curso, porque lo que no pasa por el logger no tiene nivel, ni
  formato, ni destino configurable (`L07`).

Pruébalo con y sin la opción:

```bash
java -jar target/inv-api-0.0.1-SNAPSHOT.jar
java -jar target/inv-api-0.0.1-SNAPSHOT.jar --dump-beans
```

```text
2026-09-17T11:02:58.771-05:00  INFO 42611 --- [inv-api] [           main] c.i.invapi.startup.StartupSummary        : inv-api listo | perfiles= | http=8080 | actuator=8081 | beans=214 | dump=false
```

- **`beans=214`** es el número de bean definitions del contexto principal. Tu aplicación
  aporta tres; el resto es autoconfiguración. La cifra exacta depende de tus dependencias, y
  su valor está en compararla: después de añadir un starter, vuelve a mirarla.
- **La línea aparece *antes* de `Started InvApiApplication in …`**, porque el runner corre
  dentro del arranque. Esa es también la advertencia:

> **⏱️ Costo en runtime: un runner lento retrasa el arranque, entero.** Corre en el hilo
> `main`, bloqueante, antes del `ApplicationReadyEvent`. Un `ApplicationRunner` que consulta
> un servicio remoto sin timeout puede dejar el proceso treinta segundos sin aceptar
> tráfico, y un orquestador con un `startupProbe` de veinte segundos lo mata y lo reinicia
> en bucle. Si el trabajo puede esperar, va en un `@EventListener(ApplicationReadyEvent.class)`
> asíncrono; si no puede, entonces es parte legítima del arranque y su duración es tu
> latencia de despliegue.

---

## 12. 🩺 Dos fallos de arranque provocados a propósito

Este es el músculo central de la serie (`L00` §1): reconocer la primera línea antes de saber
la causa. Los dos fallos de esta sección se provocan a propósito y se leen enteros.

### Fallo 1 — el puerto ocupado

Deja una instancia corriendo y arranca otra en otra terminal:

```bash
java -jar target/inv-api-0.0.1-SNAPSHOT.jar
```

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

- **No hay stack trace, y eso es información.** Significa que un `FailureAnalyzer`
  reconoció el fallo —aquí, `PortInUseFailureAnalyzer`— y lo tradujo. Cuando ves este
  formato, la respuesta está en `Action:` y no hace falta nada más.
- **El bloque `Action:` es el que la gente se salta.** En este caso te ofrece las dos
  salidas reales: matar al otro proceso o mover el puerto.
- **Lo que el mensaje no dice** es quién ocupa el puerto. Eso lo averiguas tú:

```bash
lsof -i :8080 -sTCP:LISTEN
kill <PID>
```

- **`lsof -i :8080`** lista los procesos con ese puerto abierto; **`-sTCP:LISTEN`** filtra a
  los que escuchan, descartando conexiones de cliente hacia ese puerto que solo hacen ruido.
- **`kill <PID>` sin `-9`** manda un `SIGTERM`, que es lo que Boot convierte en un apagado
  ordenado. Ir directo a `kill -9` te salta el `graceful shutdown` y los `@PreDestroy`
  (`02`), y es un hábito que en `L09` se paga.

La otra salida, sin matar nada, y de paso una demostración de precedencia de propiedades:

```bash
java -jar target/inv-api-0.0.1-SNAPSHOT.jar --server.port=8082 --management.server.port=8083
```

- **El argumento de línea de comandos gana** sobre el `application.properties` que dice 8080.
  El orden completo de precedencia es el tema de `07` y se demuestra fuente por fuente en
  [`L02` §3](l02-configuracion-y-profiles.md#3--la-precedencia-demostrada-en-cinco-fuentes).
- **Hay que mover los dos puertos.** Si solo mueves el de la aplicación, el arranque vuelve a
  fallar con el mismo mensaje pero con el 8081 — y eso confunde a cualquiera durante un
  minuto largo.
- **`8082`/`8083` y no cualquier otro par**, porque es el que usa el resto de la serie para
  la segunda instancia: `L06` levanta con él las dos JVM que demuestran que una caché local
  miente, y `L07` engancha esa misma instancia B a Prometheus. Al lado del par `8080`/`8081`
  de la primera instancia se lee solo: aplicación par, Actuator impar, instancia A abajo e
  instancia B justo encima. Y evita un choque que aquí no existe pero llega en `L07`: el
  `9090` es el puerto de Prometheus en el Compose de la serie, y en cuanto ese contenedor
  está arriba, una aplicación que se mueve al `9090` deja de arrancar por la misma razón que
  acabas de ver.

### Fallo 2 — dos candidatos para una dependencia

Ahora un fallo de contenedor, no de servidor. Añade un segundo `Clock` a la configuración y
pide uno por constructor:

```java
package com.invlab.invapi.config;

import java.time.Clock;
import java.time.ZoneId;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

@Configuration
class TimeConfig {

    @Bean
    Clock clock() {
        return Clock.systemDefaultZone();      // la zona de la máquina
    }

    @Bean
    Clock utcClock() {
        return Clock.system(ZoneId.of("UTC")); // la zona de los registros contables
    }
}
```

Y en `StartupSummary`, añade al constructor un tercer parámetro `Clock accountingClock`
—con ese nombre exacto, que **no** coincide con el de ninguno de los dos beans— y guárdalo en
un campo. Predice qué va a pasar antes de arrancar: hay dos beans del mismo tipo y un punto
de inyección que pide uno.

```java
// en StartupSummary: el nombre del parámetro no es ninguno de los dos nombres de bean
StartupSummary(Environment environment, ApplicationContext context, Clock accountingClock) {
    this.environment = environment;
    this.context = context;
    this.accountingClock = accountingClock;
}
```

- **El nombre del parámetro es parte del experimento, no un detalle de estilo.** Si lo
  llamaras `clock` o `utcClock`, el contenedor desempataría por nombre contra el bean
  homónimo y la aplicación arrancaría tan campante: no verías el fallo. Se llama
  `accountingClock` justamente para que no haya desempate posible.
- **El campo `private final Clock accountingClock;`** hay que declararlo también, o no
  compila. En este lab no se usa para nada más: existe para crear el punto de inyección.

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

- **`Parameter 2 of constructor`** cuenta desde cero e identifica el punto de inyección
  exacto. Es la información que hace que este error se arregle en veinte segundos y no en
  veinte minutos.
- **La causa es la resolución por tipo** de `03`: el contenedor busca por tipo, y solo usa el
  nombre como desempate cuando el nombre del parámetro coincide con el de un bean. Con el
  parámetro llamado `clock`, **esto no habría fallado**: el bean `clock` habría ganado por
  coincidencia de nombre, sin `@Primary` ni `@Qualifier` de por medio. Ese es el matiz que
  separa a quien entiende la resolución de quien memorizó "`@Autowired` inyecta por tipo", y
  es también la razón de que renombrar un parámetro pueda romper —o arreglar— un arranque.
- **Las tres salidas del `Action:`** son las de `03`: `@Primary` (elige un ganador global),
  `@Qualifier` (elige en el punto de inyección) o aceptar `List<Clock>`. Para este caso, la
  buena es `@Qualifier("utcClock")`: el registro contable quiere UTC y decirlo en el punto
  de inyección documenta la decisión.
- **Detrás de este texto hay una excepción real**, `NoUniqueBeanDefinitionException`, que
  verás entera si desactivas el analizador. El nombre es el que tienes que reconocer de
  memoria; el texto amable no siempre está.

Arréglalo con el qualifier y comprueba que arranca:

```java
StartupSummary(Environment environment, ApplicationContext context,
               @Qualifier("utcClock") Clock accountingClock) { … }
```

- **`@Qualifier` con el nombre del bean** resuelve el empate en este punto y solo en este. El
  otro `Clock` sigue existiendo y disponible para quien lo pida por su nombre.
- **El `import` es `org.springframework.beans.factory.annotation.Qualifier`**, no el de
  `jakarta.inject`. Los dos existen, hacen casi lo mismo y no son intercambiables en todos
  los casos.

> **🩺 Diagnóstico general.** Cuando un arranque falla, el orden de lectura es siempre el
> mismo: ¿hay bloque `Description:`/`Action:`? Si lo hay, la respuesta está ahí. Si no lo
> hay, baja al **último `Caused by:`** de la cadena, que es la excepción original; la primera
> es el envoltorio del contenedor y rara vez dice nada útil. El catálogo entero de errores
> con esta estructura es [`A03`](a03-catalogo-de-errores-y-diagnostico.md).

---

## 13. ⏱️ Lo que cuesta arrancar

Este lab no consume dinero, pero sí consume las tres cosas que la guía manda declarar:

```bash
/usr/bin/time -l java -jar target/inv-api-0.0.1-SNAPSHOT.jar 2>&1 | tail -20   # macOS
du -sh ~/.m2/repository
du -sh target/
```

- **`/usr/bin/time -l`** (en Linux, `/usr/bin/time -v`) imprime al terminar el proceso el
  uso máximo de memoria residente y los tiempos. Hay que escribir la ruta completa: el
  `time` del shell es otro comando y no acepta `-l`.
- **`du -sh`** da el tamaño de un directorio recursivamente. Son los dos únicos sitios donde
  este lab escribe.

Las cifras de referencia en una máquina de desarrollo razonable, con estas dependencias:

| Recurso | Orden de magnitud | Qué lo mueve |
|---|---|---|
| Arranque | 1,3 a 2 s | número de beans y de autoconfiguraciones aplicadas |
| Memoria residente | 250 a 350 MB | heap por defecto (¼ de la RAM) más metaspace |
| Jar ejecutable | ~25 MB | `BOOT-INF/lib`, una dependencia por jar anidado |
| `~/.m2/repository` | 300 a 600 MB tras el primer build | el BOM descarga lo que usas, no las 250 |

> **⏱️ Costo en runtime: el arranque es latencia de usuario en cuanto escalas.** En una
> aplicación que vive meses, 1,5 segundos no le importan a nadie. En un contenedor que el
> orquestador crea y destruye bajo demanda, cada arranque es tiempo en que hay una réplica
> menos atendiendo. Las dos palancas —jar por capas y AOT— son de `L09`; la palanca barata
> es esta: **no añadir starters que no usas**, porque cada uno aporta beans que se instancian
> en el hilo `main`.

---

## 14. 🧱 El `docker-compose.yml` se escribe aquí y no se levanta

`L00` §6 trae el fichero entero, explicado servicio por servicio. Cópialo ahora a la **raíz del
repositorio**, un nivel por encima de `inv-api/`, y **no lo levantes**:

```bash
cd ..                      # desde inv-api a la raíz del repo: ahí vive el docker-compose.yml
docker compose ps
docker compose --profile '*' config --services
cd inv-api                 # y de vuelta al proyecto, que es donde compilas
```

- **El fichero va fuera de `inv-api/`, y la razón no es estética.** Sus tres `bind mounts`
  —`./wiremock`, `./observability`, `./keycloak`— se resuelven **relativos al directorio del
  `docker-compose.yml`**, y son directorios de infraestructura del laboratorio, no fuentes de la
  aplicación: dentro de `inv-api/` quedarían mezclados con las fuentes y dentro del contexto de
  build de la imagen que construye `L09`.
  Todos los labs que levantan un perfil —`L04`, `L05`, `L07`, `L08` y `L09`— hacen `cd ..` antes,
  y la limpieza de `L09` cuenta con encontrarlo aquí.
- **`docker compose ps`** no lista nada, y es el resultado correcto: todos los servicios del
  fichero llevan `profiles:`, así que ninguno arranca por defecto (`L00` §6).
- **`docker compose --profile '*' config --services`** valida la sintaxis del fichero e
  imprime los nombres de servicio **sin arrancar nada**. Es la forma de saber hoy que el
  YAML que vas a necesitar en `L04` está bien escrito.
- **El `--profile '*'` no es adorno**: sin él, `config --services` imprime **vacío**, porque
  todos los servicios del fichero llevan `profiles:` y el comando solo considera los que
  están activos. Vacío aquí no significa "fichero mal escrito", significa "ningún perfil
  seleccionado", y es la confusión que se lleva media hora de la vida de alguien.
- **`--profile '*' config --services` imprime los ocho servicios**, `inv-api` incluido. Es la
  cuenta que tiene que salir hoy y la misma que sale en `L09`.
- **Cópialo entero, sin recortar los servicios que hoy no usas.** El fichero de `L00` §6 es
  el de toda la serie: se escribe aquí, **no cambia en ningún lab posterior**, y cada lab se
  limita a decir qué perfil levanta. Este no levanta ninguno.
- **Uno de esos ocho servicios, `inv-api`, declara una imagen que todavía no existe**
  (`inv-api:0.0.1-dockerfile`, la construye `L09`), y tampoco rompe nada:
  `docker compose config` valida el YAML **sin resolver ni descargar imágenes**, y los perfiles
  que levantan `L04`–`L08` no la miran, porque Compose solo baja las imágenes de los servicios
  que el perfil activo selecciona. La imagen inexistente solo da error el día que pidas el
  perfil `app` sin haberla construido, y ese día es `L09`.
- **Los tres `bind mounts` del fichero apuntan a directorios que todavía no existen**
  (`./wiremock`, `./observability`, `./keycloak`), y eso no rompe nada hoy: `docker compose
  config` valida el YAML y **no comprueba** que el origen de un `bind mount` exista, y como
  aquí no arranca ningún contenedor, Docker tampoco crea nada en tu disco. Los crea con
  `mkdir -p` el lab que los necesita: [`L05`](l05-clientes-y-resiliencia.md), `L07` y `L08`, **y los tres lo hacen desde esta misma
  raíz del repositorio**, porque un `mkdir` lanzado desde `inv-api/` dejaría el directorio en el
  sitio equivocado y Docker crearía uno vacío junto al `docker-compose.yml`.

> **⚠️ No añadas todavía `spring-boot-docker-compose` al `pom.xml`.** Ese módulo hace que
> `./mvnw spring-boot:run` levante los servicios del fichero automáticamente al arrancar, y
> convertiría este lab de costo cero en uno que enciende contenedores a tus espaldas. Tiene
> su momento, y es `L04`, cuando hay una base de datos que de verdad hace falta.

---

## 15. 🧱 Teardown: qué queda en `target/` y en `~/.m2`

Ningún contenedor que destruir, pero sí dos directorios que crecieron, y saber cuál es cuál
es parte del oficio:

```bash
pkill -f 'inv-api-0.0.1-SNAPSHOT.jar'
./mvnw clean
ls target/ 2>/dev/null || echo "target/ no existe"
du -sh ~/.m2/repository
```

- **`pkill -f '...'`** mata el proceso buscando el patrón en la línea de comandos completa
  (`-f`), que es como se encuentra una JVM: el nombre del proceso es `java` y con eso no
  distingues nada. Manda `SIGTERM`, así que el apagado es ordenado.
- **`./mvnw clean`** borra `target/` entero: las clases compiladas, el jar, el
  `.jar.original` y el `startup-debug.log` de §8. Es local al proyecto y se puede rehacer
  con un `package`.
- **`~/.m2/repository` no se toca, y es intencional.** Es el caché de Maven de **tu
  usuario**, compartido por todos tus proyectos. Borrarlo para "limpiar el lab" obliga a
  redescargar cientos de megas la próxima vez que compiles cualquier cosa.
- **Si de verdad necesitas el espacio**, lo que se borra es la rama concreta:
  `rm -rf ~/.m2/repository/org/springframework/boot/spring-boot-starter-web/3.5.16`. Borrar
  `~/.m2/repository` entero es el equivalente a resolver un problema de disco formateando.
- **Lo que sobrevive al lab**, y hay que tenerlo claro: el proyecto `inv-api` en disco (lo
  necesitas: `L02` parte de aquí), el caché de Maven, y el CLI si lo instalaste con SDKMAN
  (`sdk uninstall springboot 3.5.16` si no lo quieres).

---

## 16. 📋 Checklist de salida

- [ ] El `pom.xml` declara `spring-boot-starter-parent` en `3.5.16`, `spring-boot-starter-web` (no `-webmvc`) y un único `spring-boot-starter-test`.
- [ ] `./mvnw dependency:tree | grep 'spring-web:jar'` muestra `6.2.19`, no una versión 7.x.
- [ ] `./mvnw -q clean package` termina sin errores y deja `target/inv-api-0.0.1-SNAPSHOT.jar` y `target/inv-api-0.0.1-SNAPSHOT.jar.original`.
- [ ] `java -jar target/inv-api-0.0.1-SNAPSHOT.jar` imprime un banner con `(v3.5.16)` y termina con `Started InvApiApplication in …`.
- [ ] El log muestra **dos** líneas `Tomcat started on port …`, una con 8080 y otra con 8081.
- [ ] `curl -s localhost:8081/actuator/health | jq .status` devuelve `"UP"`, y el mismo `curl` contra 8080 **no** responde con un health.
- [ ] `curl -s localhost:8081/actuator/conditions | jq '.contexts["inv-api"].negativeMatches | keys | length'` devuelve un número mayor que cero.
- [ ] El log de arranque contiene la línea de `StartupSummary` con `perfiles=`, `http=8080`, `actuator=8081` y un conteo de beans.
- [ ] `java -jar target/inv-api-0.0.1-SNAPSHOT.jar --dump-beans` imprime la lista de beans ordenada; sin la opción, no la imprime.
- [ ] Arrancar una segunda instancia produce `Port 8080 was already in use` con su bloque `Action:`, y `--server.port=8082 --management.server.port=8083` la levanta igualmente.
- [ ] `grep -c "" target/startup-debug.log` devuelve más de mil líneas y el fichero contiene `Positive matches`, `Negative matches` y `Exclusions`.
- [ ] `grep -A3 jacksonObjectMapper target/startup-debug.log` muestra `Did not match` con `found beans of type … objectMapper`.
- [ ] El `pom.xml` ya **no** tiene `spring-boot-starter-jdbc` ni `h2`, y `InvApiApplication` ya no tiene `exclude`.
- [ ] `docker compose --profile '*' config --services` imprime los ocho servicios —`inv-api` entre ellos— y `docker compose ps` no lista ninguno.
- [ ] Tras `./mvnw clean`, `target/` no existe y `~/.m2/repository` sigue en su sitio.

---

## 🧠 Preguntas rápidas

1. Generas el proyecto por web, por `curl` a la API y con el CLI. ¿En qué se diferencian los
   tres artefactos resultantes, y cuál de las tres formas pondrías en una plantilla
   corporativa?
2. ¿Qué hace `./mvnw` que `mvn` no hace, y qué se rompe en un equipo que no versiona el
   wrapper?
3. En el `pom.xml` generado nadie escribió la versión de Tomcat. ¿Quién la fija y con qué
   comando la lees sin abrir el código de Boot?
4. ¿Qué diferencia hay entre `-Dspring-boot.run.arguments` y `-Dspring-boot.run.jvmArguments`,
   y qué pasa exactamente si pones `-Xmx256m` en la primera?
5. `./mvnw spring-boot:run` y `java -jar target/inv-api-0.0.1-SNAPSHOT.jar` no arrancan el
   mismo proceso. Nombra las dos diferencias que importan al diagnosticar.
6. En tu log aparece dos veces `Tomcat started on port …` con números distintos. ¿Por qué, y
   qué propiedad lo provoca?
7. ¿`--debug` sube el nivel de log de tu aplicación? Da la versión precisa de qué hace.
8. Del informe de condiciones, ¿qué bloque consultas para saber por qué **no** tienes un bean
   que esperabas, y cuál para saber por qué sí tienes uno que no pediste?
9. Añades `spring-boot-starter-jdbc` y el driver de H2, y aparece un `DataSource`. ¿Qué
   condición concreta lo creó, y por qué apareció además un componente `db` en
   `/actuator/health`?
10. Declaras tu propio `ObjectMapper`. ¿Qué frase exacta esperas encontrar en
    `Negative matches`, y qué demuestra sobre la autoconfiguración?
11. Nombra las dos formas de excluir `DataSourceAutoConfiguration` y di qué ocurre si excluyes
    por nombre una clase que no es una autoconfiguración.
12. El arranque falla con un bloque `Description:` y otro `Action:`. ¿Quién escribe esos dos
    bloques, y qué haces cuando no aparecen?
13. El fallo de los dos `Clock` no habría ocurrido si el parámetro del constructor se hubiera
    llamado de otra manera. ¿Por qué?
14. Terminas el lab y corres `./mvnw clean`. ¿Qué sigue ocupando disco en tu máquina por
    culpa de este lab, y por qué no se borra?
15. Pides a `start.spring.io` un proyecto con `bootVersion=3.5.16` y responde `400`. ¿Qué
    dice exactamente el mensaje, qué política del servicio hay detrás, y qué tres cambios
    tienes que hacer a mano en el `pom.xml` generado para quedarte en el baseline del
    curso?

---

## 🧪 Ejercicios (16)

### 🟢 Fácil — repetir lo que el lab acaba de mostrar (1–5)

#### 🟢 Ejercicio 1 — el mismo proyecto, otro empaquetado

Genera con `curl` un segundo esqueleto idéntico salvo por `type=maven-build`, en un
directorio aparte, y compara lo que devuelve con el proyecto completo.
**Objetivo:** entender que el Initializr sirve tanto el esqueleto como el `pom.xml` suelto, y
saber cuál pedirías para comparar dos configuraciones de dependencias.

#### 🟢 Ejercicio 2 — la versión que sí acepta

Repite el `curl` de §3 pasando `bootVersion=4.0.8.RELEASE` —una de las que el catálogo sí
lista— y compara el `pom.xml` resultante con el que bajaste al baseline: parent, nombres de
los starters y starters de test.
**Objetivo:** distinguir qué parte del rechazo de §3 es política de soporte del servicio y
qué parte es el renombrado de artefactos de la línea 4.x.
**Pregunta:** ¿cuántas líneas hay que cambiar para llevar ese proyecto a 3.5.16, y cuál de
ellas falla con un error de resolución si la olvidas?

#### 🟢 Ejercicio 3 — mover los dos puertos

Arranca `inv-api` en el puerto 9090 con Actuator en el 9091 usando **solo** argumentos de
línea de comandos, y confirma con `curl` que el health responde en el nuevo puerto y no en
el 8081.
**Objetivo:** ver que un argumento de línea de comandos gana sobre `application.properties`
sin tocar el fichero.

#### 🟢 Ejercicio 4 — contar los beans

Arranca con `--dump-beans`, guarda la salida y cuenta cuántos beans tiene el contexto.
Después añade `spring-boot-starter-validation` al `pom.xml` y repite.
**Objetivo:** que el número de beans sea una cifra que sabes medir, no una sensación.
**Pregunta:** ¿cuántos beans aporta ese starter, y qué línea del informe de condiciones lo
confirma?

#### 🟢 Ejercicio 5 — el jar original

Compara el tamaño de `inv-api-0.0.1-SNAPSHOT.jar` y de `inv-api-0.0.1-SNAPSHOT.jar.original`,
y prueba a arrancar el segundo con `java -jar`.
**Objetivo:** ver con tus ojos qué añade el goal `repackage` y qué error da un jar sin
`MANIFEST` de Boot.

### 🟡 Intermedio — aplicarlo a otro mecanismo (6–10)

#### 🟡 Ejercicio 6 — quitar el banner y cambiar el formato

Desactiva el banner con una propiedad y cambia el patrón de log de consola para que incluya
el nombre del hilo primero. Verifica las dos cosas en el arranque siguiente.
**Objetivo:** localizar en la referencia de Boot 3.5 las dos propiedades exactas y entender
que el log de arranque también es configuración, no decorado.

#### 🟡 Ejercicio 7 — `CommandLineRunner` al lado

Escribe un `CommandLineRunner` que imprima los mismos argumentos que `StartupSummary`, deja
los dos activos y observa cuál corre primero.
**Objetivo:** distinguir las dos interfaces y descubrir cómo se fija el orden entre varios
runners.
**Pregunta:** ¿qué anotación decide quién va primero, y qué pasa si no la pones?

#### 🟡 Ejercicio 8 — el runner que retrasa el arranque

Mete un `Thread.sleep(10_000)` dentro del `run()` de `StartupSummary` y compara la línea
`Started InvApiApplication in …` con la de antes.
**Objetivo:** medir en segundos que un runner bloquea el arranque, y poder explicar por qué
eso mata un pod en un `startupProbe` corto.

#### 🟡 Ejercicio 9 — excluir por propiedad en vez de por anotación

Vuelve a añadir `spring-boot-starter-jdbc` y H2, y esta vez desactiva la autoconfiguración
con `spring.autoconfigure.exclude` en lugar de con `exclude=`. Confirma el efecto en el
bloque `Exclusions` del informe.
**Objetivo:** comprobar que el efecto es idéntico y poder argumentar por qué la variante por
propiedad es más peligrosa en un equipo grande.

#### 🟡 Ejercicio 10 — tu bean gana, con otro tipo

Repite el experimento de §10 declarando tu propio `RestClient.Builder` en vez del
`ObjectMapper`, y localiza en el informe la línea `Did not match` correspondiente.
**Objetivo:** confirmar que `@ConditionalOnMissingBean` es un mecanismo general y no una
particularidad de Jackson.

### 🟠 Difícil — combinar, diagnosticar o decidir (11–14)

#### 🟠 Ejercicio 11 — cazar una autoconfiguración que no aplica

Sin añadir ninguna dependencia, averigua con el informe de condiciones **por qué** no tienes
`RedisAutoConfiguration` y qué tendrías que poner en el classpath para que aplicara. Escribe
la condición exacta que falla, copiada del informe.
**Objetivo:** usar el bloque `Negative matches` para responder la pregunta contraria, que es
la que suele tenerte atascado.

#### 🟠 Ejercicio 12 — dos contextos, dos informes

`/actuator/conditions` devuelve más de un contexto. Averigua cuántos hay, cómo se llaman y
por qué el segundo existe, y escribe un `jq` que imprima solo los `positiveMatches` del
contexto de gestión.
**Objetivo:** entender que `management.server.port` crea un contexto hijo, y que un bean
declarado en el principal no está automáticamente en él.

#### 🟠 Ejercicio 13 — el fallo que ningún `FailureAnalyzer` traduce

Provoca un fallo de arranque que salga con stack trace completo y **sin** bloque `Action:`
—por ejemplo, lanzando una excepción desde el constructor de `StartupSummary`—, y localiza en
la salida la excepción original.
**Objetivo:** practicar la regla de §12: cuando no hay analizador, la causa está en el último
`Caused by:`, no en la primera línea.

#### 🟠 Ejercicio 14 — reproducibilidad del esqueleto

Escribe un script `scaffold.sh` que genere `inv-api` desde cero con el `curl` de §3, aplique
la bajada al baseline de §4 —parent y los tres renombrados de starters— y las propiedades de
§5, y compile, todo sin intervención manual. Córrelo en un directorio vacío y verifica que
el banner del arranque dice `(v3.5.16)`.
**Objetivo:** convertir la forma 2 en lo que dice el veredicto de §3 que es: una plantilla
reproducible donde la versión de Boot acaba escrita en el repositorio, aunque el servicio se
niegue a generarla.
**Pregunta:** ¿cómo haces que el script falle ruidosamente el día que el Initializr cambie
otra cosa del `pom.xml`, en vez de producir un proyecto silenciosamente distinto?

### 🔴 Muy difícil — abierto o adversarial (15–16)

#### 🔴 Ejercicio 15 — el proyecto envenenado

Te entregan un `inv-api` que arranca correctamente y en cuyo `/actuator/health` aparece un
componente que nadie declaró, con el `pom.xml` "limpio" a primera vista. Reprodúcelo tú
mismo añadiendo una dependencia transitiva —no directa— que arrastre un driver, y después
escribe el procedimiento de tres comandos que llevaría a otra persona del síntoma a la línea
culpable del `pom.xml`.
**Objetivo:** encadenar `health` → `conditions` → `dependency:tree` y dejarlo escrito como
procedimiento, no como anécdota.
**Pregunta:** ¿cuál de los tres comandos es el único que identifica **qué dependencia** lo
trajo, y por qué los otros dos no pueden?

#### 🔴 Ejercicio 16 — defender la exclusión en un code review

Un compañero propone `@SpringBootApplication(exclude = JacksonAutoConfiguration.class)` para
poder configurar las fechas a su gusto. Escribe la respuesta de review en diez líneas: qué
rompe esa exclusión, qué dos alternativas hay, y con qué salida del informe de condiciones
demuestras que ninguna de las dos necesita excluir nada.
**Objetivo:** convertir el mecanismo de `@ConditionalOnMissingBean` en un argumento que
sostienes delante de otra persona, con evidencia.

### 🔥 Opcionales y ampliaciones

#### 🔥 Un `FailureAnalyzer` propio

Escribe un `FailureAnalyzer` para una excepción tuya —por ejemplo, una configuración
obligatoria ausente— y regístralo en
`META-INF/spring/org.springframework.boot.autoconfigure.AutoConfiguration.imports`. Provoca
el fallo y comprueba que sale tu `Description:` y tu `Action:` en lugar del stack trace.
**Objetivo:** cerrar el círculo de §12 desde el otro lado, que es lo que haría el dueño de una
librería corporativa.

#### 🔥 Gradle, una vez

Genera el mismo proyecto con `type=gradle-project-kotlin` y compara el fichero de build con
el `pom.xml` de §4: dónde está el BOM, dónde está el plugin y dónde está la versión de Java.
**Objetivo:** reconocer las mismas piezas en la otra herramienta, que es lo único que este
curso pide de Gradle.

### 💀 Boss fight — el esqueleto auditado

Entrega, en un solo directorio, tres cosas coherentes entre sí:

1. Un `scaffold.sh` que genera `inv-api` desde cero, lo baja al baseline del curso y lo deja
   compilando, con la versión de Boot fijada en el script y verificada después contra
   `dependency:tree`.
2. Un `audit.sh` que, contra una instancia ya levantada, produce un informe de texto con:
   versión de Boot y de JVM del proceso, puertos en los que escucha, número de beans del
   contexto principal, las cinco autoconfiguraciones aplicadas que aportan más beans y la
   lista de endpoints de Actuator expuestos.
3. Un `HALLAZGOS.md` de máximo una página que, a partir de ese informe, responda a la
   pregunta que abre el lab: qué hay en esta aplicación que nadie declaró, y qué quitarías.

Todo con `curl` y `jq` contra `/actuator`, sin abrir el código de Spring y sin reiniciar la
aplicación.
**Objetivo:** que "por qué existe este bean" deje de ser una pregunta de entrevista y sea un
script que corres. Si algún dato del informe no lo sabes sacar de Actuator, ese es
exactamente el hueco que este lab existía para tapar.

---

## 🏁 La señal de que quedó bien

`docker compose ps` no lista nada y nunca listó nada. `./mvnw -q clean package` pasa en
verde, `java -jar target/inv-api-0.0.1-SNAPSHOT.jar` arranca en menos de dos segundos con un
banner que dice `(v3.5.16)`, el log muestra dos `Tomcat started` —8080 y 8081— y tu línea de
`StartupSummary` justo antes del `Started InvApiApplication in …`. `curl` contra
`localhost:8081/actuator/health` devuelve `UP` con exactamente dos componentes: `diskSpace` y
`ping`, sin rastro del `db` que apareció a mitad del lab. Y si alguien te pregunta de dónde
salió cualquier bean de esa aplicación, no contestas "lo pone Boot": abres
`/actuator/conditions` y se lo enseñas.

---

## 📚 Referencias oficiales

- Spring Boot 3.5 — Build Systems, starters y el BOM: https://docs.spring.io/spring-boot/3.5/reference/using/build-systems.html
- Spring Boot 3.5 — Estructura del código y paquete raíz: https://docs.spring.io/spring-boot/3.5/reference/using/structuring-your-code.html
- Spring Boot 3.5 — Auto-configuration: cómo se activa, cómo se inspecciona y cómo se excluye: https://docs.spring.io/spring-boot/3.5/reference/using/auto-configuration.html
- Spring Boot 3.5 — `SpringApplication`, eventos, banner y runners: https://docs.spring.io/spring-boot/3.5/reference/features/spring-application.html
- Spring Boot 3.5 — Javadoc de `ApplicationRunner`: https://docs.spring.io/spring-boot/3.5/api/java/org/springframework/boot/ApplicationRunner.html
- Spring Boot 3.5 — Javadoc de `@ConditionalOnMissingBean`: https://docs.spring.io/spring-boot/3.5/api/java/org/springframework/boot/autoconfigure/condition/ConditionalOnMissingBean.html
- Spring Boot 3.5 — Javadoc de `FailureAnalyzer`: https://docs.spring.io/spring-boot/3.5/api/java/org/springframework/boot/diagnostics/FailureAnalyzer.html
- Spring Boot 3.5 — Catálogo de clases de autoconfiguración: https://docs.spring.io/spring-boot/3.5/appendix/auto-configuration-classes/index.html
- Spring Boot 3.5 — Endpoints de Actuator (`health`, `conditions`, `beans`): https://docs.spring.io/spring-boot/3.5/reference/actuator/endpoints.html
- Spring Boot 3.5 — Logging y patrones de consola: https://docs.spring.io/spring-boot/3.5/reference/features/logging.html
- Spring Boot 3.5 — Maven Plugin, goal `run`: https://docs.spring.io/spring-boot/3.5/maven-plugin/run.html
- Spring Boot 3.5 — Maven Plugin, empaquetado y `repackage`: https://docs.spring.io/spring-boot/3.5/maven-plugin/packaging.html
- Spring Boot 3.5 — Formato del jar ejecutable: https://docs.spring.io/spring-boot/3.5/specification/executable-jar/index.html
- Spring Boot 3.5 — Instalación del CLI: https://docs.spring.io/spring-boot/3.5/installing.html
- Spring Boot 3.5 — Comandos del CLI (`init`, `encodepassword`, shell): https://docs.spring.io/spring-boot/3.5/cli/index.html
- Spring Boot 3.5 — Requisitos de sistema: https://docs.spring.io/spring-boot/3.5/system-requirements.html
- Spring Boot 3.5 — Soporte de Docker Compose: https://docs.spring.io/spring-boot/3.5/reference/features/dev-services.html
- Spring Boot — página del proyecto y calendario de soporte: https://spring.io/projects/spring-boot/
- Spring Initializr — el servicio: https://start.spring.io/
- Spring Initializr — referencia del servicio y su API (Initializr no se versiona con Boot y solo publica `current`, así que este enlace no lleva versión en la ruta): https://docs.spring.io/initializr/docs/current/reference/html/
- Spring Framework 6.2 — `@Bean` y configuración basada en Java: https://docs.spring.io/spring-framework/reference/6.2/core/beans/java.html

### Documentación de terceros

- Apache Maven — el Wrapper: https://maven.apache.org/tools/wrapper/
- Apache Maven — goal `dependency:tree`: https://maven.apache.org/plugins/maven-dependency-plugin/tree-mojo.html
- SDKMAN — instalación y uso: https://sdkman.io/
