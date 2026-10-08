# L02 — Configuración y profiles

> **Objetivo:** dejar de adivinar de dónde sale un valor. Al terminar puedes poner la
> misma propiedad en cinco fuentes, predecir cuál gana antes de ejecutar, y demostrarlo
> con un log y con `/actuator/env`.
> **Asume:** [`07`](07-configuracion-externalizada.md) leído, y [`06`](06-arranque-y-autoconfiguracion.md) al menos por encima.
> **Prerrequisitos:** `L01` hecho. El proyecto `inv-api` existe, compila y arranca.
> **Costo:** **$0.00**. Este lab no levanta ningún contenedor.
> **Duración:** 90 minutos, de los cuales la mitad es reiniciar la aplicación con una variable distinta cada vez.
> **Qué deja levantado:** nada. Ningún servicio de Compose, ningún proceso en segundo plano.
> **Qué toca:** casi todo es `src/main/resources/`: `application.properties` desaparece y en su
> lugar quedan `application.yml`, `application-local.yml` y `application-test.yml`. En
> `src/main/java` añade `SupplierProperties` bajo `com.invlab.invapi.supplier` y las dos sondas
> desechables `ConfigProbe` y `ValueProbe` bajo `com.invlab.invapi.config`. Crea además
> `./secrets/` como directorio de trabajo, que no es del proyecto y se borra al terminar. El
> `pom.xml` solo se toca en un experimento que se revierte, y el `docker-compose.yml` no se
> toca en absoluto.
> **Vigencia:** 17 de septiembre de 2026 · Spring Boot 3.5.16 · Spring Framework 6.2.19 · Java 21.

**Salto rápido:** [Estado inicial](#1--el-problema-y-el-estado-inicial) ·
[`application.yml`](#2--applicationyml-desde-cero) ·
[Precedencia en cinco fuentes](#3--la-precedencia-demostrada-en-cinco-fuentes) ·
[Desmontando "el yml manda"](#4--desmontando-el-applicationyml-manda) ·
[Relaxed binding](#5--relaxed-binding-con-una-variable-de-entorno) ·
[`@ConfigurationProperties`](#6--configurationproperties-con-record-y-el-arranque-que-se-rompe) ·
[`@Value`](#7--value-al-lado) ·
[Profiles](#8--profiles-local-test-y-el-experimento-de-los-dos-a-la-vez) ·
[Secretos como fichero](#9--springconfigimport-y-un-secreto-como-fichero) ·
[El error de YAML](#10-️-el-error-clásico-de-yaml-reproducido-dos-veces) ·
[Auditar con Actuator](#11--auditar-de-dónde-salió-cada-valor) ·
[Checklist](#12--checklist-de-salida) ·
[Preguntas rápidas](#-preguntas-rápidas) ·
[Ejercicios](#-ejercicios-16)

---

## 1. 🧭 El problema y el estado inicial

El incidente es siempre el mismo y dura más de lo que debería. Alguien sube el timeout
del proveedor en `application.yml`, despliega, y el timeout sigue siendo el viejo. Se
revisa el commit, se revisa la imagen, se culpa al caché de Docker. Al cabo de cuarenta
minutos aparece un `INV_SUPPLIER_TIMEOUT` en el manifiesto del despliegue que alguien
puso hace ocho meses.

El capítulo [`07`](07-configuracion-externalizada.md) te dio la tabla de precedencia. Una
tabla se olvida. Lo que no se olvida es haber visto **el mismo proceso, con el mismo jar,
imprimir cinco valores distintos** según qué fuente añadas. Eso es lo que hace este lab, y
por eso está en la serie práctica y no en el capítulo: la doctrina de reparto de
[`L00`](l00-idea-lab-practico.md) manda al lab lo que se entiende viéndolo ocurrir.

Antes de tocar nada, confirma que vienes del estado correcto:

```bash
cd inv-api
./mvnw -q clean package -DskipTests
java -jar target/inv-api-0.0.1-SNAPSHOT.jar
```

- **`./mvnw`** es el wrapper que `L01` dejó en el proyecto: descarga la versión de Maven
  fijada en `.mvn/wrapper/maven-wrapper.properties` y la usa. Por eso el lab nunca te pide
  instalar Maven.
- **`-q`** silencia el ruido de descarga y deja solo los errores. Si algo falla, lo vas a
  ver igual.
- **`-DskipTests`** salta los tests en este empaquetado concreto. No es una costumbre: es
  que aquí lo único que queremos es el jar, y el ciclo de este lab son ocho o nueve
  empaquetados.
- **`java -jar target/inv-api-0.0.1-SNAPSHOT.jar`** arranca el jar ejecutable. El nombre
  sale del `artifactId` (`inv-api`) y de la `version` (`0.0.1-SNAPSHOT`) que `L01` dejó en
  el `pom.xml`; si tu jar se llama distinto, no estás en el proyecto de la serie.

Tiene que arrancar y quedarse escuchando. Córtalo con `Ctrl+C`. Si falla, vuelve a `L01`:
este lab no arregla un proyecto que no arranca, lo configura.

> **🧠 Modelo mental del lab.** El jar es el mismo durante todo el documento. Lo único que
> cambia es **el entorno en el que lo lanzas**. Si en algún momento te descubres
> recompilando para cambiar un valor, es que te saliste del punto.

---

## 2. 🧱 `application.yml` desde cero

`L01` te dejó un `application.properties` con cinco propiedades puestas a mano:
`spring.application.name`, los dos puertos, la lista blanca de endpoints de Actuator y
`management.endpoint.health.show-details`. Ese fichero no se tira: **se traduce**. Bórralo y
escribe el mismo contenido en YAML, que es lo que usan los labs de esta serie por la razón
que da [`07` §4](07-configuracion-externalizada.md#4--properties-y-yaml).

```bash
rm src/main/resources/application.properties
```

- **Borrarlo importa.** Si dejas los dos ficheros, **ambos se cargan**, y `.properties`
  gana a `.yml` dentro de la misma ubicación. Tener los dos es la forma más barata de
  perder media hora: editas el YAML y no pasa nada.

Ahora el fichero base. Todavía sin profiles, sin nada raro:

```yaml
# src/main/resources/application.yml
spring:
  application:
    name: inv-api

server:
  port: 8080

management:
  server:
    port: 8081
  endpoints:
    web:
      exposure:
        include: health,info,conditions,beans,configprops,env
  endpoint:
    health:
      show-details: always
    env:
      show-values: ALWAYS
    configprops:
      show-values: ALWAYS

inv:
  supplier:
    base-url: https://inv-supplier.invlab.example
    timeout: 2s
    max-connections: 20
```

- **`spring.application.name`** no es decorativo: aparece entre corchetes en cada línea de
  log de Boot 3.5, y es la clave con la que `/actuator/configprops` agrupa los beans. Con
  el nombre puesto, los `jq` de la sección 11 funcionan tal como están escritos aquí.
- **`server.port: 8080`** es el puerto de la aplicación del baseline de `L00`. Está
  escrito explícitamente aunque coincida con el default, porque una propiedad que solo
  existe como default no aparece en `/actuator/env` como algo que tú decidiste.
- **`management.server.port: 8081`** mueve Actuator a un segundo puerto. En producción eso
  permite que el balanceador exponga 8080 y solo la red interna llegue a 8081; aquí sirve
  además para que veas que **son dos conectores distintos**, no dos rutas del mismo.
- **`management.endpoints.web.exposure.include`** es la lista blanca de endpoints
  publicados por HTTP. Por defecto Boot expone solo `health`: `env` y `configprops`
  existen pero no responden. Sin esta línea, los `curl` de este lab devuelven `404`.
- **La lista es la de `L01` más `env` y `configprops`, y eso es deliberado.** `info`,
  `conditions` y `beans` se quedan porque el checklist de salida de `L01` los da por
  publicados y este lab no rompe la cadena (§11 de la guía): el `curl` a
  `/actuator/conditions` que cierra `L01` tiene que seguir funcionando después de traducir
  el fichero a YAML. Quitarlos aquí, en silencio, convertiría el checklist anterior en una
  comprobación que falla sin que nadie lo dijera.
- **`management.endpoint.health.show-details: always`** también viene de `L01`, donde es lo
  que hace que `/actuator/health` devuelva el detalle por componente. Sigue siendo una
  decisión **de laboratorio**: en producción va en `when-authorized`, y eso se hace en [`L08` §8](l08-security-y-batch.md#8--asegurar-actuator-con-endpointrequesttoanyendpoint).
- **`management.endpoint.env.show-values: ALWAYS`** enseña los valores. Desde Boot 3.0 el
  default es `NEVER` y **todo** valor sale como `******`, no solo los que parecen
  secretos. Lo veremos fallar en la sección 11 antes de creerlo.
- **`inv.supplier.*`** es nuestro bloque de configuración propio: URL del proveedor
  `inv-supplier`, timeout y tamaño del pool. `invlab.example` es el dominio reservado de
  la serie y nunca resuelve; es deliberado, porque en este lab nadie llama a nadie.
- **`timeout: 2s`** se escribe con unidad porque lo vamos a enlazar a un `Duration`. Boot
  entiende `2s`, `500ms` y `PT2S`; un `2` pelado también se enlaza, pero como
  milisegundos, y esa es una confusión que se paga cara.

> **⚠️ `show-values: ALWAYS` es una decisión de laboratorio, no una recomendación.** Con
> eso puesto, cualquiera que alcance el puerto 8081 lee tu contraseña de base de datos en
> claro. En un servicio real el endpoint `env` va detrás de autenticación y, como mucho,
> con `WHEN_AUTHORIZED`. [`23` §2](23-actuator-y-observabilidad.md#2--qué-expone-actuator-por-defecto-y-cómo-se-asegura) desarrolla cómo se asegura Actuator.

`spring-boot-starter-actuator` ya está en el `pom.xml` desde `L01` —es lo que hace que el
puerto 8081 exista—, así que para este lab faltan dos dependencias:

```xml
<dependency>
    <groupId>org.springframework.boot</groupId>
    <artifactId>spring-boot-starter-validation</artifactId>
</dependency>
<dependency>
    <groupId>org.springframework.boot</groupId>
    <artifactId>spring-boot-configuration-processor</artifactId>
    <optional>true</optional>
</dependency>
```

- **Ninguna lleva `<version>`**, y no es un olvido: las dos están en el BOM que hereda el
  `pom.xml` del proyecto, y la versión la fija Spring Boot 3.5.16. Poner una versión a
  mano aquí es la forma habitual de acabar con dos versiones de Jackson en el classpath.
- **`spring-boot-starter-validation`** arrastra Hibernate Validator, la implementación de
  Bean Validation. Sin ella, `@Validated` sobre tus propiedades **no falla: no hace
  nada**, y eso lo vamos a comprobar rompiéndolo en la sección 6.
- **`spring-boot-configuration-processor`** genera en tiempo de compilación los metadatos
  de tus propiedades, que es lo que hace que el IDE autocomplete `inv.supplier.timeout` y
  muestre su tipo. **`<optional>true</optional>`** evita que se propague como dependencia
  transitiva a quien use tu artefacto: es una herramienta de build, no de runtime.

> **⏱️ Costo en runtime de lo que acabas de añadir.** El segundo conector de Tomcat en
> 8081 no es gratis: levanta su propio `ApplicationContext` hijo, suma del orden de
> **200–400 ms al arranque** y un par de hilos de aceptación más. Actuator con `env` y
> `configprops` además mantiene en memoria la lista completa de `PropertySource`, que en
> un servicio con muchas variables de entorno son unos cientos de KB permanentes. Es
> barato, pero no es cero, y en una función serverless con arranque en frío sí se nota.

---

## 3. ⚖ La precedencia, demostrada en cinco fuentes

Aquí está el corazón del lab. Vamos a poner `inv.supplier.timeout` en cinco sitios, **uno
a la vez, de menor a mayor prioridad**, y a comprobar cuál gana en cada paso.

Primero necesitamos un testigo. Una clase que, al arrancar, diga qué valor ganó y de qué
fuente salió:

```java
// src/main/java/com/invlab/invapi/config/ConfigProbe.java
package com.invlab.invapi.config;

import org.springframework.boot.ApplicationArguments;
import org.springframework.boot.ApplicationRunner;
import org.springframework.core.env.ConfigurableEnvironment;
import org.springframework.core.env.PropertySource;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Component;

@Component
class ConfigProbe implements ApplicationRunner {

    private static final Logger log = LoggerFactory.getLogger(ConfigProbe.class);
    private static final String KEY = "inv.supplier.timeout";

    private final ConfigurableEnvironment environment;

    // inyección por constructor: un solo constructor, sin @Autowired
    ConfigProbe(ConfigurableEnvironment environment) {
        this.environment = environment;
    }

    @Override
    public void run(ApplicationArguments args) {
        String value = environment.getProperty(KEY);
        String winner = "(ninguna)";
        // las fuentes se recorren en orden de precedencia: gana la primera que la tenga
        for (PropertySource<?> source : environment.getPropertySources()) {
            if (source.containsProperty(KEY)) {
                winner = source.getName();
                break;
            }
        }
        log.info("PROBE {} = {} <- {}", KEY, value, winner);
    }
}
```

- **`ApplicationRunner`** lo ejecuta Boot una vez, después de que el contexto esté
  completo y antes de dar el arranque por terminado. Lo viste en `L01`; aquí lo usamos
  porque queremos el `Environment` ya definitivo, no a medias.
- **`ConfigurableEnvironment`** y no `Environment` a secas: la interfaz base sabe
  **leer** propiedades, pero solo la `Configurable` expone `getPropertySources()`, que es
  la lista ordenada que queremos recorrer.
- **El `break` del bucle es el punto pedagógico entero.** No hay mezcla ni prioridad por
  especificidad: se recorre la lista y gana la primera fuente que contiene la clave. Ese
  bucle de cinco líneas *es* la tabla de precedencia de `07`.
- **`environment.getProperty(KEY)` devuelve `String`**, no `Duration`. La conversión de
  tipos ocurre al enlazar a un objeto, no al leer del `Environment`. Por eso el log
  imprime `2s` y no `PT2S`.
- **`@Component` package-private**, como todo lo que escribimos en el lab: el contenedor
  no necesita que la clase sea `public` para registrarla.
- **El formato `{}` de SLF4J** evita concatenar cadenas cuando el nivel de log está
  apagado. Aquí da igual, pero es la costumbre que queremos en el resto del curso.

Empaqueta una vez y no vuelvas a compilar en toda la sección:

```bash
./mvnw -q clean package -DskipTests
```

### Ronda 1 — solo `application.yml`

```bash
java -jar target/inv-api-0.0.1-SNAPSHOT.jar
```

```text
2026-09-17T18:04:11.902-05:00  INFO 41287 --- [inv-api] [           main] c.i.invapi.config.ConfigProbe            : PROBE inv.supplier.timeout = 2s <- applicationConfig: [classpath:/application.yml]
```

- **El nombre de la fuente lo pone Boot**, y es literalmente la ruta del fichero. Cuando
  en un incidente leas `applicationConfig: [file:./config/application.yml]` sabrás que el
  valor no viene de dentro del jar sino de un fichero al lado.

### Ronda 2 — se añade `application-local.yml`

Crea el fichero específico de profile:

```yaml
# src/main/resources/application-local.yml
inv:
  supplier:
    base-url: http://localhost:8090
    timeout: 3s
```

- **El nombre `application-{profile}.yml` es la convención**, no una configuración: Boot
  busca ese patrón para cada profile activo.
- **`http://localhost:8090`** es el WireMock de `L00`. No está levantado y no importa:
  este lab no hace ninguna llamada, solo configura.
- **Este fichero no repite `max-connections`.** Un `application-{profile}.yml` no
  sustituye al base: se apila encima y solo pisa las claves que declara.

Empaqueta de nuevo (cambiaste un recurso del jar) y arranca con el profile:

```bash
./mvnw -q clean package -DskipTests
java -jar target/inv-api-0.0.1-SNAPSHOT.jar --spring.profiles.active=local
```

```text
PROBE inv.supplier.timeout = 3s <- applicationConfig: [classpath:/application-local.yml]
```

- **Ese `--spring.profiles.active=local` es un argumento de línea de comandos**, sí, pero
  de **otra** clave. No compite con `inv.supplier.timeout`: solo decide qué ficheros se
  cargan. Confundir las dos cosas es lo que hace que mucha gente crea que la línea de
  comandos "activa el yml".
- **Lo específico de profile gana a lo genérico** dentro del mismo grupo de ficheros. Sin
  el profile, el `application-local.yml` ni siquiera se lee.

### Ronda 3 — se añade una variable de entorno

```bash
INV_SUPPLIER_TIMEOUT=4s java -jar target/inv-api-0.0.1-SNAPSHOT.jar --spring.profiles.active=local
```

```text
PROBE inv.supplier.timeout = 4s <- systemEnvironment
```

- **`VAR=valor comando`** exporta la variable **solo para ese proceso**. No ensucia tu
  shell, que es exactamente lo que quieres cuando vas a lanzar cinco variantes seguidas.
- **`systemEnvironment`** es el nombre que Boot le da a la fuente de variables del sistema
  operativo. Ahí es donde vive el misterio del incidente que abre este lab.
- **El nombre en mayúsculas con guion bajo funciona** porque el `Environment` traduce los
  puntos a `_` y compara ignorando mayúsculas. Ojo: eso **no** es relaxed binding
  completo, y la sección 5 muestra dónde se rompe.

### Ronda 4 — se añade una propiedad de sistema `-D`

```bash
INV_SUPPLIER_TIMEOUT=4s java -Dinv.supplier.timeout=5s -jar target/inv-api-0.0.1-SNAPSHOT.jar --spring.profiles.active=local
```

Antes de ejecutarlo, predice: ¿gana el `4s` de la variable de entorno o el `5s` de `-D`?
Mucha gente lo dice al revés en la entrevista.

```text
PROBE inv.supplier.timeout = 5s <- systemProperties
```

- **`-D` va antes de `-jar`.** Después de `-jar` todo se le pasa a la aplicación como
  argumento, no a la JVM. Si escribes `java -jar app.jar -Dinv.supplier.timeout=5s`, la
  propiedad de sistema no existe y el argumento tampoco tiene forma de `--clave=valor`:
  no pasa nada y no hay error. Silencio puro.
- **`systemProperties` gana a `systemEnvironment`.** Esta es la inversión que más se
  falla: las propiedades de la JVM tienen **más** prioridad que las variables del sistema
  operativo.

### Ronda 5 — se añade el argumento de línea de comandos

```bash
INV_SUPPLIER_TIMEOUT=4s java -Dinv.supplier.timeout=5s -jar target/inv-api-0.0.1-SNAPSHOT.jar --spring.profiles.active=local --inv.supplier.timeout=6s
```

```text
PROBE inv.supplier.timeout = 6s <- commandLineArgs
```

- **`--clave=valor` después del jar** es lo que Boot convierte en la fuente
  `commandLineArgs`. El doble guion es obligatorio: con uno solo es un argumento suelto
  que acaba en `ApplicationArguments.getNonOptionArgs()` y no configura nada.
- **Gana a todo lo demás**, y por eso es la herramienta de incidente: sobreescribes un
  valor sin reconstruir la imagen ni tocar el despliegue.

### El resumen, y la comprobación a la inversa

```text
--inv.supplier.timeout=6s     commandLineArgs        6s   ← gana
-Dinv.supplier.timeout=5s     systemProperties       5s
INV_SUPPLIER_TIMEOUT=4s       systemEnvironment      4s
application-local.yml         applicationConfig      3s
application.yml               applicationConfig      2s   ← la de menor prioridad
```

Ahora quita fuentes **de arriba hacia abajo, una a la vez**, y comprueba que el valor baja
un escalón en cada arranque: `6s → 5s → 4s → 3s → 2s`. Esa es la disciplina de **una
variable a la vez** que atraviesa toda la serie; si quitas dos y el resultado te
sorprende, ya no sabes cuál de las dos lo causó.

Y si usas el plugin de Maven en vez del jar, los equivalentes no son obvios:

```bash
./mvnw spring-boot:run -Dspring-boot.run.profiles=local \
  -Dspring-boot.run.jvmArguments="-Dinv.supplier.timeout=5s" \
  -Dspring-boot.run.arguments="--inv.supplier.timeout=6s"
```

- **`spring-boot:run` bifurca una JVM nueva por defecto.** Un `-D` que le pases a `./mvnw`
  es una propiedad de sistema **de Maven**, no de tu aplicación, y por eso no llega. Es la
  causa número uno de "en el IDE funciona y con Maven no".
- **`-Dspring-boot.run.jvmArguments`** es lo que el plugin pasa a la JVM hija: ahí sí va
  tu `-D` real.
- **`-Dspring-boot.run.arguments`** son los argumentos de aplicación, el equivalente de lo
  que escribirías tras el jar.
- **`-Dspring-boot.run.profiles=local`** es un atajo del plugin para
  `--spring.profiles.active=local`.

---

## 4. ⚖ Desmontando "el `application.yml` manda"

Es la frase que sale en cualquier entrevista de Boot, y es exactamente al revés.

Acabas de verlo: de las cinco fuentes que usas a diario, `application.yml` **es la de
menor prioridad**. No es el sitio donde se decide la configuración: es el sitio donde se
declaran los **defaults** con los que el artefacto es utilizable si nadie lo ajusta.

> Nunca respondas: ~~"la configuración manda desde el `application.yml`, por eso ahí se
> pone todo"~~
>
> Mejor: "el `application.yml` empaquetado es la fuente de menor prioridad de las que uso;
> ahí van los defaults sensatos. Cualquier variable de entorno del despliegue lo pisa, y
> eso es lo que permite promover el mismo jar de integración a producción sin
> reconstruirlo."

```text
application.yml  →  lo que el artefacto trae puesto     (defaults)
entorno / -D     →  lo que el despliegue decide         (por entorno)
línea de comandos→  lo que el incidente necesita ahora  (excepcional)
```

Hay un corolario práctico que casi nadie menciona y que suma mucho: **si una propiedad es
distinta en cada entorno, no tiene default legítimo**. Ponerle uno en `application.yml`
—una URL de integración, un usuario de base de datos— es lo que hace que un despliegue mal
parametrizado arranque apuntando al sitio equivocado en vez de fallar. Es mejor dejarla
sin valor y que el arranque se caiga: eso es lo que la sección 6 construye a propósito.

---

## 5. 🧱 Relaxed binding con una variable de entorno

Los puntos y los guiones no son portables entre shells, así que las variables de entorno
se escriben en mayúsculas con guion bajo. Boot tiene que traducir entre las dos formas, y
lo hace **solo en un sitio**. Vamos a encontrar el borde.

Añade al testigo una segunda lectura, la de una clave **con guion**:

```java
    private static final String HYPHEN_KEY = "inv.supplier.max-connections";
    // ...
        log.info("PROBE {} = {}", HYPHEN_KEY, environment.getProperty(HYPHEN_KEY));
```

- **`max-connections` es la forma canónica**: minúsculas y guiones. Es la que genera
  metadatos, la que autocompleta el IDE y la que debe aparecer en tus ficheros.
- **La misma clave en variable de entorno se escribe `INV_SUPPLIER_MAXCONNECTIONS`**: los
  puntos pasan a guion bajo y **los guiones desaparecen**, no se convierten en nada.

Empaqueta y lanza con esa variable:

```bash
INV_SUPPLIER_MAXCONNECTIONS=50 java -jar target/inv-api-0.0.1-SNAPSHOT.jar
```

```text
PROBE inv.supplier.timeout = 2s <- applicationConfig: [classpath:/application.yml]
PROBE inv.supplier.max-connections = 20
```

El `50` no aparece. Y sin embargo la variable está bien escrita.

> **🩺 Diagnóstico.** `Environment.getProperty("inv.supplier.max-connections")` consulta
> las fuentes con una traducción mínima —puntos a guion bajo, mayúsculas— pero **no
> elimina los guiones**. El relaxed binding completo vive en el `Binder`, que es lo que
> usa `@ConfigurationProperties`, y no en la lectura directa del `Environment`. Es la
> misma frontera que hace que `@Value` no tenga relaxed binding.

En la sección 6, cuando la misma variable se enlace a un `record`, el `50` sí llegará. Esa
es la demostración práctica de por qué el curso prefiere `@ConfigurationProperties`: no es
elegancia, es que **el mecanismo de lectura no es el mismo**.

---

## 6. 🧱 `@ConfigurationProperties` con `record`, y el arranque que se rompe

Tres claves sueltas leídas del `Environment` no son configuración: son cadenas. Lo que
queremos es un objeto tipado, inmutable y validado.

```java
// src/main/java/com/invlab/invapi/supplier/SupplierProperties.java
package com.invlab.invapi.supplier;

import jakarta.validation.constraints.Max;
import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import java.time.Duration;
import org.springframework.boot.context.properties.ConfigurationProperties;
import org.springframework.validation.annotation.Validated;

@Validated
@ConfigurationProperties(prefix = "inv.supplier")
record SupplierProperties(
        @NotBlank String baseUrl,
        @NotNull Duration timeout,
        @Min(1) @Max(50) int maxConnections) {
}
```

- **Los imports están escritos a propósito.** `org.springframework.validation.annotation.Validated`
  se confunde constantemente con `jakarta.validation.Valid`, y son cosas distintas:
  `@Validated` es la de Spring y es la que activa la validación sobre el objeto de
  propiedades. Con la otra, el arranque no valida nada.
- **`record` con un solo constructor** basta: Boot enlaza por constructor sin anotaciones
  extra. No hay setters, así que la configuración no se puede mutar en caliente — que es
  justo lo que quieres.
- **`prefix = "inv.supplier"`** es la raíz. Los nombres de los componentes del `record`
  se convierten a la forma canónica: `maxConnections` ↔ `max-connections`. Aquí sí hay
  relaxed binding completo.
- **`Duration timeout`** convierte `2s` a `PT2S`. Un `2` sin unidad se interpretaría como
  2 **milisegundos**; si quieres que el default sean segundos, se declara con
  `@DurationUnit(ChronoUnit.SECONDS)`.
- **`@NotBlank`, `@NotNull`, `@Min`, `@Max`** son restricciones de Bean Validation
  estándar, no de Spring. Se evalúan **en el arranque**, sobre el objeto ya enlazado.

Hay que registrarlo, porque una clase anotada no se escanea sola:

```java
// src/main/java/com/invlab/invapi/InvApiApplication.java
@ConfigurationPropertiesScan
@SpringBootApplication
public class InvApiApplication { /* ... */ }
```

- **`@ConfigurationPropertiesScan`** busca `@ConfigurationProperties` en el paquete de la
  clase de arranque y sus subpaquetes, igual que `@ComponentScan` con los componentes.
- **La alternativa es `@EnableConfigurationProperties(SupplierProperties.class)`** en una
  `@Configuration`, una a una. Se usa cuando la clase de propiedades vive en una librería
  y no la escanea nadie.
- **Sin ninguna de las dos, no hay bean**, y el error que obtienes al inyectarlo es un
  `NoSuchBeanDefinitionException` que no menciona la configuración por ningún lado.

Inyéctalo en el testigo para verlo enlazado:

```java
    private final SupplierProperties supplier;

    ConfigProbe(ConfigurableEnvironment environment, SupplierProperties supplier) {
        this.environment = environment;
        this.supplier = supplier;
    }
    // ... dentro de run(...):
        log.info("PROBE bound {}", supplier);
```

- **Se inyecta como cualquier bean**, por constructor. Que sea un `record` no cambia nada
  para el contenedor.
- **El `toString()` de un `record` sale gratis** y lista todos los componentes: es
  justamente el log que quieres en el arranque de un servicio real.

Arranca otra vez con la variable de la sección anterior:

```bash
./mvnw -q clean package -DskipTests
INV_SUPPLIER_MAXCONNECTIONS=50 java -jar target/inv-api-0.0.1-SNAPSHOT.jar
```

```text
PROBE inv.supplier.max-connections = 20
PROBE bound SupplierProperties[baseUrl=https://inv-supplier.invlab.example, timeout=PT2S, maxConnections=50]
```

**Las dos líneas se contradicen, y las dos son correctas.** La lectura directa del
`Environment` no encuentra la variable; el `Binder` sí. Si alguna vez ves una propiedad
"que no llega" mientras el objeto de configuración sí la tiene, ya sabes por dónde va.

### Y ahora lo rompemos

Pon un valor imposible en el fichero base:

```yaml
inv:
  supplier:
    base-url: https://inv-supplier.invlab.example
    timeout: 2s
    max-connections: 0        # fuera del rango [1, 50] declarado en el record
```

- **`0` viola `@Min(1)`.** Es el caso realista: alguien parametriza el pool con una
  plantilla y deja un cero.

Empaqueta, arranca y lee la salida entera:

```bash
./mvnw -q clean package -DskipTests
java -jar target/inv-api-0.0.1-SNAPSHOT.jar
```

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

- **`APPLICATION FAILED TO START`** con `Description` y `Action` es la firma de un
  `FailureAnalyzer`, el mecanismo que viste en `L01`: alguien tradujo la excepción cruda a
  un mensaje accionable.
- **`Origin`** es la joya del mensaje: **fichero, línea y columna** del valor culpable. Esa
  información la conserva Boot durante todo el enlace, y es lo que hace que no tengas que
  buscar en qué capa de configuración estaba el cero.
- **El `28:22` sale de tu fichero, no de una constante.** Es la línea y la columna en las
  que está el `0` si copiaste el `application.yml` de la sección 2 tal cual, con su línea de
  comentario incluida. En cuanto añadas el bloque de `spring.config.import` de la sección 9
  —o borres el comentario, o reordenes dos claves— el número cambia, y está bien que cambie:
  lo que hay que comprobar es que `Origin` apunta al sitio donde de verdad está el valor, no
  que diga `28`.
- **`Reason`** viene de Hibernate Validator y **sale en el idioma del `Locale` de la JVM**.
  En una máquina configurada en español leerás "debe ser mayor que o igual a 1". No te
  fíes del texto para buscar en un runbook: fíate de `Property`.
- **La excepción subyacente es `BindValidationException`**, envuelta en
  `ConfigurationPropertiesBindException`. Aparece completa si arrancas con `--debug`.
- **El proceso termina con código de salida distinto de cero**, así que un orquestador ve
  el arranque fallido y no marca el pod como listo. Esto es una funcionalidad, no un
  accidente: **mejor no arrancar que arrancar con un pool de cero conexiones**.

Corrige el valor a `21` y vuelve a arrancar antes de seguir.

### El fallo silencioso que hay detrás

Quita temporalmente `spring-boot-starter-validation` del `pom.xml`, deja el `0` y arranca:

```text
PROBE bound SupplierProperties[baseUrl=https://inv-supplier.invlab.example, timeout=PT2S, maxConnections=0]
```

- **Arranca tan contento.** `@Validated` sin una implementación de Bean Validation en el
  classpath no es un error de compilación ni un aviso: simplemente no hay quién valide.
- **La prevención cabe en una línea**: la dependencia de validación se añade en el mismo
  commit que la primera anotación de validación, y el test de arranque que verifica que un
  valor inválido **rompe** el contexto es lo que impide que alguien la quite sin enterarse.

Vuelve a poner la dependencia y el `20` antes de continuar.

---

## 7. ⚖ `@Value` al lado

Para ver la diferencia hay que ponerlos juntos. Un componente con las dos formas:

```java
// src/main/java/com/invlab/invapi/config/ValueProbe.java
package com.invlab.invapi.config;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Component;

@Component
class ValueProbe {

    private final String baseUrl;
    private final int maxConnections;
    private final String missingWithDefault;

    ValueProbe(
            @Value("${inv.supplier.base-url}") String baseUrl,
            @Value("${inv.supplier.maxConnections}") int maxConnections,
            @Value("${inv.supplier.region:unknown}") String missingWithDefault) {
        this.baseUrl = baseUrl;
        this.maxConnections = maxConnections;
        this.missingWithDefault = missingWithDefault;
    }
}
```

- **`@Value` en parámetros del constructor**, no en campos. El curso no inyecta por campo
  ni siquiera aquí.
- **`${...}` es un placeholder**, resuelto por un `PropertySourcesPlaceholderConfigurer`
  contra el `Environment`. Es una **búsqueda literal de la clave**: sin canonicalización,
  sin relaxed binding.
- **`${inv.supplier.region:unknown}`**: lo que va tras los dos puntos es el default. Sin
  él, una clave ausente **rompe el arranque** con
  `IllegalArgumentException: Could not resolve placeholder 'inv.supplier.region'`.
- **`${inv.supplier.maxConnections}` está escrito en camelCase a propósito.** La clave del
  YAML es `max-connections`. Predice qué pasa.

```text
Caused by: java.lang.IllegalArgumentException: Could not resolve placeholder 'inv.supplier.maxConnections' in value "${inv.supplier.maxConnections}"
```

- **Esa es la diferencia, en una línea de excepción.** El mismo nombre que el `record`
  enlaza sin despeinarse es, para `@Value`, una clave que no existe. `@Value` compara
  cadenas.
- **Arréglalo** escribiendo `${inv.supplier.max-connections}`, exactamente como está en el
  fichero.

| | `@Value` | `@ConfigurationProperties` |
|---|---|---|
| Busca la clave | literal, tal como la escribes | canónica, con relaxed binding |
| Si falta | rompe el arranque, salvo default `:` | usa `null` / el default del tipo |
| Validación | ninguna | Bean Validation con `@Validated` |
| SpEL `#{...}` | ✅ | ❌ |

**El veredicto de este lab:** `@Value` para un valor aislado y para cuando necesitas SpEL;
`@ConfigurationProperties` para un grupo. La señal de que te pasaste es tener tres
`@Value` con el mismo prefijo en la misma clase — eso ya era un `record`.

---

## 8. 🧱 Profiles: `local`, `test` y el experimento de los dos a la vez

Añade el segundo fichero de profile, para poder enfrentar dos:

```yaml
# src/main/resources/application-test.yml
inv:
  supplier:
    timeout: 10s
```

- **`test` es uno de los tres profiles del baseline** de `L00` (`local`, `test`, `prod`).
  El lab no inventa nombres nuevos para esto.
- **Diez segundos** es un valor deliberadamente absurdo: se distingue de un vistazo en el
  log y nadie lo confunde con el `2s` ni con el `3s`.

Y el grupo, en `application.yml`:

```yaml
spring:
  profiles:
    group:
      prod: metrics,audit
```

- **Un grupo es un alias**: activar `prod` activa además `metrics` y `audit`, y con ellos
  cargaría `application-metrics.yml` y `application-audit.yml` si existieran.
- **Para qué sirve de verdad:** evita que el despliegue tenga que enumerar cinco profiles
  en una variable de entorno, que es donde se cuelan las erratas.
- **⚠️ Desviación declarada del baseline:** `metrics` y `audit` son profiles auxiliares que
  existen solo para este experimento; no sustituyen a `local`, `test` y `prod` de `L00`, y
  no vuelven a aparecer en la serie.

Ahora el experimento. Dos profiles a la vez, y el mismo par en los dos órdenes:

```bash
./mvnw -q clean package -DskipTests
java -jar target/inv-api-0.0.1-SNAPSHOT.jar --spring.profiles.active=local,test
java -jar target/inv-api-0.0.1-SNAPSHOT.jar --spring.profiles.active=test,local
```

Predice antes de ejecutar: ¿el segundo comando da lo mismo que el primero?

```text
# --spring.profiles.active=local,test
The following 2 profiles are active: "local", "test"
PROBE inv.supplier.timeout = 10s <- applicationConfig: [classpath:/application-test.yml]

# --spring.profiles.active=test,local
The following 2 profiles are active: "test", "local"
PROBE inv.supplier.timeout = 3s <- applicationConfig: [classpath:/application-local.yml]
```

- **Gana el último de la lista.** Los ficheros de profile se apilan en el orden en que se
  activan los profiles, así que el último añadido queda arriba. No hay ninguna jerarquía
  entre `local` y `test`: hay un orden de escritura.
- **Esto es exactamente el bug de despliegue clásico**: alguien añade un profile a la
  variable de entorno sin mirar dónde lo pone y cambia el comportamiento de un servicio
  que no tocó.
- **La línea `The following 2 profiles are active`** la imprime Boot en cada arranque. Es
  lo primero que se mira cuando un servicio "no lee su configuración".

> **⚠️ Un bean `@Profile("!prod")` no es una red de seguridad.** Con dos profiles activos
> y un despliegue mal parametrizado, el bean que relaja la autenticación "salvo en
> producción" se registra en cuanto alguien arranca sin el profile exacto. La forma segura
> es la contraria: lo peligroso se activa **solo** con un profile explícito. El capítulo
> `07` §7 lo desarrolla y `L08` lo sufre con Security de por medio.

---

## 9. 🧱 `spring.config.import` y un secreto como fichero

El token del proveedor no puede vivir en `application.yml`: ese fichero se versiona, se
copia en los logs del build y viaja dentro de la imagen. Lo que hacen Kubernetes, Docker
Swarm y los gestores de secretos es **montar el secreto como un fichero**, y Boot sabe
leer un directorio así.

Crea el árbol a mano:

```bash
mkdir -p ./secrets
printf 'inv-supplier-token-from-file' > ./secrets/inv.supplier.token
ls -1 ./secrets
```

- **El nombre del fichero es la clave completa**: `inv.supplier.token` se convierte en la
  propiedad `inv.supplier.token`. El contenido es el valor.
- **`printf` y no `echo`**: `echo` añade un salto de línea, y ese salto entra en el valor.
  Boot recorta los espacios finales de un config tree, pero no te acostumbres: con
  `echo -n` o `printf` no tienes que confiar en eso. Un token con un `\n` pegado produce un
  `401` que cuesta una tarde.
- **`./secrets` es un directorio de trabajo, no del proyecto**: lo creas tú, no lo crea el
  build.

Declara la importación:

```yaml
spring:
  config:
    import:
      - optional:file:./config/local.yml
      - optional:configtree:./secrets/
```

- **`spring.config.import`** carga fuentes adicionales con la misma semántica de
  precedencia del resto: lo importado se coloca **justo encima** del documento que lo
  importa.
- **`optional:`** evita que la ausencia del recurso rompa el arranque. Sin el prefijo, un
  `./secrets/` inexistente produce
  `ConfigDataLocationNotFoundException: Config data location 'configtree:./secrets/' does not exist`.
  En un lab molesta; en producción ese fallo duro es deseable para un secreto obligatorio.
- **`configtree:` exige la barra final.** Apunta a un directorio; sin la barra, Boot no lo
  trata como árbol.
- **`file:./config/local.yml`** es un fichero suelto fuera del jar, el mecanismo de
  override por despliegue. Lo dejamos declarado aunque no exista todavía: es lo que
  practica el ejercicio 7.

Añade el componente al `record` para verlo enlazado:

```java
record SupplierProperties(
        @NotBlank String baseUrl,
        @NotNull Duration timeout,
        @Min(1) @Max(50) int maxConnections,
        @NotBlank String token) {
}
```

- **`@NotBlank String token`** sin default: si el secreto no está montado, el arranque
  falla con el mismo mensaje de la sección 6. Es la política correcta para un secreto —
  arrancar sin credenciales solo retrasa el fallo hasta la primera llamada.

```bash
./mvnw -q clean package -DskipTests
java -jar target/inv-api-0.0.1-SNAPSHOT.jar
```

```text
PROBE bound SupplierProperties[baseUrl=https://inv-supplier.invlab.example, timeout=PT2S, maxConnections=20, token=inv-supplier-token-from-file]
```

- **El token aparece en el log porque tú lo pusiste ahí.** El `toString()` de un `record`
  incluye todos los componentes, y eso convierte tu línea de arranque en una filtración.
  En un servicio real se sobreescribe el `toString()` o se excluye el campo del log. Aquí
  lo dejamos a la vista **una vez**, para que veas lo fácil que es.

> **📝 Boot 3.5 no trae integración nativa con Vault ni con Secrets Manager.** El config
> tree es el punto de encuentro: la plataforma monta el secreto como fichero y Boot lo lee
> sin saber de dónde vino. Esa indirección es precisamente lo que hace que el mismo jar
> funcione en tu máquina y en un clúster.

**Teardown de esta sección, aquí y no al final:**

```bash
rm -rf ./secrets
printf 'secrets/\nconfig/\n' >> .gitignore
git status --short
```

- **`rm -rf ./secrets`** borra el árbol. Es un directorio con un token en claro en tu
  disco: no sobrevive al lab.
- **Las dos líneas del `.gitignore`** son la parte que no se salta. Un `secrets/` sin
  ignorar es un commit accidental esperando a ocurrir, y el `git status --short` es la
  verificación de que efectivamente no aparece.

Y aquí viene la parte que la mayoría de los tutoriales se saltan: **borrado el árbol, el
`record` ya no puede arrancar**. Un `@NotBlank String token` cuya única fuente era un
`configtree:` declarado `optional:` deja el jar con `APPLICATION FAILED TO START` en cuanto
intentas lanzarlo, que es exactamente lo que harías en la sección siguiente y lo que hacen
`L03`, `L04`, `L05`, `L06` y `L07` con un `java -jar` pelado. Así que el experimento se revierte entero: quita el componente del `record`

```java
// vuelve a los tres componentes con los que nació en la sección 6
record SupplierProperties(
        @NotBlank String baseUrl,
        @NotNull Duration timeout,
        @Min(1) @Max(50) int maxConnections) {
}
```

y quita del `application.yml` la línea que importaba el árbol, dejando la otra:

```yaml
spring:
  config:
    import:
      - optional:file:./config/local.yml      # este se queda: lo usa el ejercicio 7
```

- **El secreto fue un experimento de esta sección y no sobrevive a ella**, y conviene decir
  por qué en voz alta: `inv-api` **no autentica todavía contra el proveedor**. El
  `SupplierGateway` que `L05` construye sobre estas mismas propiedades llama a un WireMock que
  no pide credenciales, así que un token obligatorio sería una barrera sin nada detrás. Lo que
  se queda contigo es el mecanismo —nombre de fichero igual a clave, `optional:`, la barra
  final del `configtree:`— y el ejercicio 16, que es donde se decide qué propiedad **no** debe
  tener default nunca.
- **La regla general, que sí se lleva a producción:** un secreto obligatorio se declara
  `@NotBlank` y **sin** `optional:` en su `spring.config.import`, para que el servicio se niegue
  a arrancar si la plataforma no montó el secreto. Eso es lo correcto cuando hay un secreto de
  verdad; aquí no lo hay, y montar el andamio permanente de uno inexistente es peor documentación
  que quitarlo.
- **Recompila antes de seguir** (`./mvnw -q clean package -DskipTests`): el jar de `target/`
  todavía tiene el `record` de cuatro componentes y arrancaría fallando.

---

## 10. ⚠️ El error clásico de YAML, reproducido dos veces

YAML se lee mejor que `.properties` y a cambio tiene dos trampas que muerden de verdad. Se
reproducen, no se cuentan.

### Trampa 1 — `on` no es la cadena `"on"`

Añade un componente de texto al `record` y un valor en el YAML:

```java
record SupplierProperties(
        @NotBlank String baseUrl,
        @NotNull Duration timeout,
        @Min(1) @Max(50) int maxConnections,
        @NotBlank String mode) {
}
```

```yaml
inv:
  supplier:
    mode: on          # queríamos la cadena "on"
```

- **`mode` es un `String`**, y en el YAML parece una cadena. Predice qué imprime el log.

```text
PROBE bound SupplierProperties[baseUrl=https://inv-supplier.invlab.example, timeout=PT2S, maxConnections=20, mode=true]
```

- **`mode=true`, no `mode=on`.** SnakeYAML implementa YAML 1.1, donde `on`, `off`, `yes`,
  `no`, `y` y `n` son **booleanos**. El parser devuelve `Boolean.TRUE`, y el `Binder` lo
  convierte a `String` como `"true"`.
- **No hay error, no hay aviso.** Si tu código comparaba `"on"`, la comparación es `false`
  para siempre y el comportamiento cambia en silencio.
- **La corrección son dos comillas**: `mode: "on"`. Lo mismo vale para el código de país
  `NO` (Noruega, que se convierte en `false`) y para una versión `1.10`, que se convierte
  en el número `1.1` y pierde el cero.
- **La prevención:** cualquier valor que no sea evidentemente numérico va entrecomillado,
  y los valores que empiezan por `*` o `&` **obligatoriamente**, porque son sintaxis de
  anclaje de YAML y revientan el parseo con un error que no menciona tu propiedad.

Corrige a `mode: "on"` y confirma que ahora el log dice `mode=on`.

### Trampa 2 — la indentación que no falla

Esta es peor, porque no cambia un valor: **crea otra propiedad**.

```yaml
inv:
  supplier:
    base-url: https://inv-supplier.invlab.example
    max-connections: 20
    mode: "on"
  timeout: 9s          # se quiso escribir dentro de supplier: sobra un nivel de sangría
```

- **`timeout` quedó colgando de `inv`**, no de `inv.supplier`. Son dos espacios de
  diferencia.

Arranca y mira las dos líneas del testigo:

```text
PROBE inv.supplier.timeout = 2s <- applicationConfig: [classpath:/application.yml]
PROBE bound SupplierProperties[baseUrl=https://inv-supplier.invlab.example, timeout=PT2S, ...]
```

- **Ningún error. Ninguna advertencia.** La aplicación arranca perfectamente con el valor
  anterior, o con el default del tipo si no había valor anterior. Tu `9s` existe, pero se
  llama `inv.timeout` y no lo lee nadie.
- **`@ConfigurationProperties(ignoreUnknownFields = false)` no te salva aquí**, y conviene
  saberlo: esa opción se queja de claves desconocidas **bajo el prefijo** `inv.supplier`.
  `inv.timeout` está fuera del prefijo y por tanto no es asunto suyo.
- **Confírmalo con Actuator**, que es la única forma rápida:

```bash
curl -s localhost:8081/actuator/env/inv.timeout | jq '.property'
```

```json
{
  "source": "applicationConfig: [classpath:/application.yml]",
  "value": "9s"
}
```

- **Ahí está el huérfano.** Cuando una propiedad "no hace efecto", la primera pregunta no
  es "¿está bien el valor?", sino "¿existe la clave que yo creo que existe?".
- **La prevención que funciona de verdad** es el
  `spring-boot-configuration-processor` de la sección 2: con los metadatos generados, el
  IDE marca `inv.timeout` como propiedad desconocida y la ves en amarillo mientras
  escribes, no en producción.

Devuelve la sangría a su sitio antes de seguir.

---

## 11. 🩺 Auditar de dónde salió cada valor

Ya sabes leer el log del testigo, pero en un servicio real no tienes un testigo: tienes
Actuator. Arranca con dos fuentes compitiendo, como en la ronda 3:

```bash
INV_SUPPLIER_TIMEOUT=4s java -jar target/inv-api-0.0.1-SNAPSHOT.jar --spring.profiles.active=local
```

```bash
curl -s localhost:8081/actuator/env/inv.supplier.timeout | jq
```

```json
{
  "property": { "source": "systemEnvironment", "value": "4s" },
  "activeProfiles": ["local"],
  "propertySources": [
    { "name": "commandLineArgs" },
    { "name": "systemProperties" },
    { "name": "systemEnvironment", "property": { "value": "4s", "origin": "System Environment Property \"INV_SUPPLIER_TIMEOUT\"" } },
    { "name": "applicationConfig: [classpath:/application-local.yml]", "property": { "value": "3s" } },
    { "name": "applicationConfig: [classpath:/application.yml]", "property": { "value": "2s" } }
  ]
}
```

- **La respuesta está recortada**: el `propertySources` real trae quince entradas, la
  mayoría sin la clave. Se conservan las que importan.
- **`property.source` contesta la pregunta del incidente en un campo**: ganó
  `systemEnvironment`. Fin de los cuarenta minutos de búsqueda.
- **`propertySources` te enseña los valores que perdieron**, en orden de precedencia. Es la
  tabla de `07` calculada para tu proceso concreto.
- **`origin`** llega incluso a nombrar la variable de entorno exacta, y en un fichero da
  línea y columna. Es la misma información que viste en el error de validación.
- **`/actuator/env/{clave}` acepta la forma canónica.** Pregunta por
  `inv.supplier.timeout`, no por `INV_SUPPLIER_TIMEOUT`.

Y agrupado por objeto de configuración:

```bash
curl -s localhost:8081/actuator/configprops \
  | jq '.contexts["inv-api"].beans | keys'
```

```json
[
  "inv.supplier-com.invlab.invapi.supplier.SupplierProperties",
  "management.endpoints.web-org.springframework.boot.actuate.autoconfigure.endpoint.web.WebEndpointProperties",
  "server-org.springframework.boot.autoconfigure.web.ServerProperties"
]
```

- **La clave del bean es `<prefijo>-<clase>`.** Ahí está tu `inv.supplier` al lado de las
  propiedades que trae Boot: el endpoint no distingue entre tu configuración y la del
  framework, y por eso sirve para auditar el servicio entero.
- **`.contexts["inv-api"]`** funciona porque pusiste `spring.application.name`. Sin él, el
  contexto se llama `application` y este `jq` devuelve `null` — que es exactamente lo que
  te pasará la primera vez que lo copies en otro proyecto.
- **Es el endpoint que se usa en una revisión**, no `env`: te da el bloque completo de un
  componente, con lo que está puesto y lo que quedó en default.

### El `******` que sorprende a todo el mundo

Quita `show-values: ALWAYS` del `application.yml`, arranca y repite el primer `curl`:

```json
{
  "property": { "source": "systemEnvironment", "value": "******" },
  "activeProfiles": ["local"]
}
```

- **No es que tu propiedad parezca un secreto.** Desde Boot 3.0, `env` y `configprops`
  enmascaran **todos** los valores por defecto (`show-values: NEVER`). La respuesta "es que
  Actuator oculta las claves que se llaman `password`" describe el comportamiento de
  Boot 2.x y ya no es correcta.
- **Los tres valores posibles son `NEVER`, `ALWAYS` y `WHEN_AUTHORIZED`**, y el último es
  el único razonable en producción: enseña los valores solo a quien haya pasado por la
  autenticación de Actuator.
- **Vuelve a poner `ALWAYS`** para terminar el lab, y recuerda por qué no se hace fuera de
  tu máquina.

---

## 12. 📋 Checklist de salida

- [ ] `./mvnw -q clean package -DskipTests` termina sin errores y produce `target/inv-api-0.0.1-SNAPSHOT.jar`.
- [ ] `src/main/resources/application.properties` **no** existe; existen `application.yml`, `application-local.yml` y `application-test.yml`.
- [ ] `java -jar target/inv-api-0.0.1-SNAPSHOT.jar` imprime `PROBE inv.supplier.timeout = 2s <- applicationConfig: [classpath:/application.yml]`.
- [ ] Con `--inv.supplier.timeout=6s`, `-Dinv.supplier.timeout=5s` e `INV_SUPPLIER_TIMEOUT=4s` a la vez, el log dice `6s <- commandLineArgs`.
- [ ] Quitando esas tres fuentes una a una, el valor baja `6s → 5s → 4s → 3s → 2s` sin saltos.
- [ ] Poner `max-connections: 0` produce `APPLICATION FAILED TO START` con `Property: inv.supplier.max-connections` y `Origin` con línea y columna.
- [ ] `--spring.profiles.active=local,test` y `--spring.profiles.active=test,local` dan `10s` y `3s` respectivamente.
- [ ] `curl -s localhost:8081/actuator/env/inv.supplier.timeout | jq '.property.source'` nombra la fuente que ganó.
- [ ] `curl -s localhost:8081/actuator/configprops | jq '.contexts["inv-api"].beans | keys'` incluye la entrada de `inv.supplier`.
- [ ] `mode: on` sin comillas se enlaza como `true`, y con comillas como `on`.
- [ ] El directorio `./secrets` está borrado, `secrets/` figura en `.gitignore`, y el `record` ya no declara el componente `token` ni el `application.yml` la línea `optional:configtree:./secrets/`.
- [ ] `docker compose -p inv-lab ps` no lista nada: este lab no levantó ningún contenedor.

---

## 🧠 Preguntas rápidas

1. Ordena estas cinco fuentes de mayor a menor prioridad y di el nombre con el que
   Actuator identifica a cada una: `application.yml` dentro del jar, `-D`,
   `--clave=valor`, variable de entorno, `application-local.yml` dentro del jar.
2. "El `application.yml` manda, por eso ahí se configura todo." Corrige la frase y explica
   qué permite el orden real.
3. Escribiste `INV_SUPPLIER_MAXCONNECTIONS=50` y `environment.getProperty("inv.supplier.max-connections")`
   devuelve `20`, pero el `record` enlazado trae `50`. ¿Por qué no se contradicen?
4. ¿Por qué `java -jar app.jar -Dinv.supplier.timeout=5s` no cambia nada y tampoco da
   error?
5. ¿Qué tres cosas te da el bloque `Origin` del mensaje de un fallo de validación de
   propiedades, y por qué no conviene buscar en el runbook por el texto de `Reason`?
6. Dejas `@Validated` en el `record` y quitas `spring-boot-starter-validation`. ¿Qué pasa
   al arrancar con un valor inválido?
7. `--spring.profiles.active=local,test` y `--spring.profiles.active=test,local` dan
   valores distintos. ¿Cuál gana y por qué?
8. ¿Qué hace exactamente `spring.profiles.group.prod: metrics,audit` y qué problema de
   despliegue evita?
9. Un `@Value("${inv.supplier.region}")` sin default y con la clave ausente: ¿cuándo falla
   y con qué excepción?
10. ¿Qué convierte un config tree en propiedades, y qué papel juega el nombre del fichero?
11. ¿Para qué sirve el prefijo `optional:` en `spring.config.import`, y cuándo **no** lo
    quieres?
12. Escribes `mode: on` esperando la cadena `"on"` y recibes `true`. ¿Qué lo causa y cómo
    se corrige?
13. Una propiedad mal indentada en YAML no rompe el arranque. ¿Qué ocurre, por qué
    `ignoreUnknownFields = false` no lo detecta, y qué endpoint te lo confirma?
14. Llamas a `/actuator/env` y todos los valores salen como `******` aunque ninguno parece
    un secreto. ¿Qué versión de Boot introdujo ese comportamiento y qué propiedad lo
    controla?

---

## 🧪 Ejercicios (16)

### 🟢 Fácil — repetir lo del lab con otro valor  (1–4)

#### 🟢 Ejercicio 1 — la sexta fuente

Añade `inv.supplier.timeout` también con `SPRING_APPLICATION_JSON='{"inv":{"supplier":{"timeout":"7s"}}}'`
y lanza el jar con las cinco fuentes anteriores puestas. Anota qué gana y en qué escalón
quedó la nueva.
**Objetivo:** ubicar `SPRING_APPLICATION_JSON` entre los argumentos de línea de comandos y
las propiedades de sistema, sin mirar la tabla.

#### 🟢 Ejercicio 2 — el testigo, ampliado

Modifica `ConfigProbe` para que imprima las tres claves de `inv.supplier` con su fuente
ganadora, en tres líneas. Verifica que `base-url` y `max-connections` salen de
`application.yml` y `timeout` de donde tú decidas.
**Objetivo:** comprobar que cada clave se resuelve por separado; no hay una "fuente del
bloque".

#### 🟢 Ejercicio 3 — el puerto por argumento

Arranca dos instancias del mismo jar a la vez, la segunda con `--server.port=8082
--management.server.port=8083`. Comprueba con `curl` que las dos responden a
`/actuator/health`.
**Objetivo:** ver que el mismo artefacto convive consigo mismo cambiando solo el entorno,
que es el argumento entero de la configuración externalizada.

#### 🟢 Ejercicio 4 — `Duration` sin unidad

Pon `timeout: 2` (sin `s`) y mira el `toString()` del `record` en el log.
**Pregunta:** ¿qué valor quedó enlazado, y cuántas veces más rápido expira que el `2s` que
pretendías?

### 🟡 Intermedio — aplicarlo a otra propiedad o a otro mecanismo  (5–8)

#### 🟡 Ejercicio 5 — el rango, por el otro extremo

Pon `max-connections: 500` y provoca el fallo de arranque por `@Max(50)`. Copia la línea
`Origin` y verifica que apunta a la línea exacta de tu `application.yml`.
**Objetivo:** reconocer el mismo formato de error con otra restricción, y confiar en
`Origin` para localizar el valor.

#### 🟡 Ejercicio 6 — el multi-documento

Sustituye `application-local.yml` por un documento `---` dentro de `application.yml` con
`spring.config.activate.on-profile: local`, sin cambiar ningún valor. Comprueba que el log
del testigo sigue dando `3s` con el profile activo y `2s` sin él.
**Objetivo:** entender que fichero aparte y documento condicional son dos formas del mismo
mecanismo, y que el nombre de la fuente en el log cambia.

#### 🟡 Ejercicio 7 — el fichero de fuera del jar

Crea `./config/local.yml` con `inv.supplier.timeout: 8s` y comprueba que el
`spring.config.import` de la sección 9 lo carga. Después renómbralo a
`./config/application.yml`, quita la línea del `import` y comprueba que **se sigue
cargando**.
**Pregunta:** ¿por qué el segundo caso funciona sin importarlo explícitamente, y qué
riesgo tiene un `config/` olvidado en el directorio de trabajo de un servidor?

#### 🟡 Ejercicio 8 — segundo bloque tipado

Crea `ActuatorAuditProperties` con prefijo `inv.audit`, dos componentes (`enabled` y
`retention`, un `Duration`) y `@Validated`. Regístralo por
`@EnableConfigurationProperties` en vez de por escaneo, y compruébalo en
`/actuator/configprops`.
**Objetivo:** repetir el mecanismo completo con la otra forma de registro y ver ambas
convivir.

### 🟠 Difícil — combinar, diagnosticar o decidir  (9–13)

#### 🟠 Ejercicio 9 — el secreto que falta

Rehaz el montaje de la sección 9 —el árbol `./secrets`, el componente `@NotBlank String token`
y la línea `optional:configtree:./secrets/`— y desármalo en dos pasos: primero borra
`./secrets/inv.supplier.token` dejando el directorio y arranca; luego borra el directorio
entero y arranca otra vez. Después repite el segundo caso **sin** el prefijo `optional:`.
Vuelve a revertirlo todo al terminar, como hiciste en la sección.
**Pregunta:** ¿los tres casos fallan igual? ¿Cuál falla por `@NotBlank`, cuál arranca sin
quejarse y cuál muere con `ConfigDataLocationNotFoundException`?

#### 🟠 Ejercicio 10 — `@Value` con SpEL

Añade un `@Value("#{'${inv.supplier.base-url}'.toUpperCase()}")` y compruébalo en el log.
Después intenta lo mismo con un componente del `record`.
**Objetivo:** comprobar de primera mano la única columna en la que `@Value` gana a
`@ConfigurationProperties`, y que no hay forma de hacerlo con el `record`.

#### 🟠 Ejercicio 11 — el bean duplicado por dos profiles

Declara dos beans `SupplierClient`, uno `@Profile("local")` y otro `@Profile("test")`, e
inyéctalos por tipo en un tercer bean. Arranca con `--spring.profiles.active=local,test`.
**Objetivo:** ver que el orden de los profiles resuelve el valor de una propiedad pero
**no** resuelve un `NoUniqueBeanDefinitionException`, y decidir si lo arreglas con
`@Primary`, con `@Qualifier` o replanteando los profiles.

#### 🟠 Ejercicio 12 — `spring.profiles.active` dentro de un fichero de profile

Escribe `spring.profiles.active: test` dentro de `application-local.yml` y arranca con el
profile `local`. Copia la primera línea de la excepción.
**Objetivo:** reconocer `InvalidConfigDataPropertyException` y poder explicar por qué Boot
prohíbe que un fichero de profile active otros profiles.

#### 🟠 Ejercicio 13 — el test que blinda la validación

Escribe un test que arranque el contexto con `inv.supplier.max-connections=0` mediante
`properties` de `@SpringBootTest` y **falle si el contexto arranca**. Compruébalo con
`./mvnw -q test`.
**Objetivo:** convertir el fallo de arranque de la sección 6 en una red de seguridad
automática, que es la prevención de la autopsia.

### 🔴 Muy difícil — abierto o adversarial  (14–16)

#### 🔴 Ejercicio 14 — auditoría a ciegas

Pídele a alguien —o a un script— que arranque el jar poniendo `inv.supplier.timeout` en
una de las cinco fuentes, sin decirte cuál. Con un solo `curl` a Actuator, di cuál fue y
qué valor quedó en cada una de las otras.
**Objetivo:** cerrar el bucle del lab: la pregunta "¿de dónde salió ese valor?" se contesta
en un comando, no en cuarenta minutos.

#### 🔴 Ejercicio 15 — el `application.yml` saboteado

Toma este bloque, que es YAML válido, arranca sin errores y hace tres cosas mal a la vez:

```yaml
inv:
  supplier:
    base-url: https://inv-supplier.invlab.example
    mode: off
    timeout: 3s
    max-connections: 20
  version: 1.10
```

Sin ejecutarlo, predice por escrito qué queda enlazado en cada componente de
`SupplierProperties`, qué clave queda huérfana y con qué valor exacto. Luego ejecútalo y
compara con `/actuator/env`.
**Objetivo:** leer un YAML como lo lee el parser y no como lo lee tu intención. Lo que
falles aquí es lo que te va a morder en producción.

#### 🔴 Ejercicio 16 — la política de configuración del servicio

Escribe en media página la política de configuración de `inv-api` para un despliegue en
banca: qué vive en `application.yml`, qué en variables de entorno, qué en config tree, qué
propiedad **no** debe tener default nunca, y cómo se audita un valor en producción sin
exponer `env` a la red. Justifica cada frontera con algo que hayas visto en este lab.
**Objetivo:** convertir el mecanismo en una decisión defendible, que es exactamente lo que
te van a pedir en la entrevista.

### 🔥 Opcionales y ampliaciones

- **`.properties` contra `.yml` en el mismo proyecto.** Crea un `application.properties`
  junto al `application.yml`, pon `inv.supplier.timeout` en los dos y averigua cuál gana.
  Documenta la respuesta: es una pregunta de entrevista menos frecuente de lo que debería.
- **Metadatos propios.** Con `spring-boot-configuration-processor` activo, mira
  `target/classes/META-INF/spring-configuration-metadata.json` y localiza la entrada de
  `inv.supplier.timeout` con su tipo y su origen. Añade una descripción con Javadoc en el
  `record` y compruébala en el fichero regenerado.
- **`@ConstructorBinding` y la historia.** Averigua por qué en Boot 2.x hacía falta anotar
  el constructor y desde cuándo un `record` con un solo constructor no lo necesita. Es un
  clásico de las entrevistas con proyectos heredados.

### 💀 Boss fight — el mismo jar en tres entornos, sin recompilar

Con el jar que ya tienes y **sin volver a compilar**, entrega un script
`run-env.sh <local|test|prod>` que arranque `inv-api` con la configuración completa de cada
entorno, cumpliendo todo esto a la vez:

- `local` apunta al WireMock de `localhost:8090`, `test` a un host de integración y `prod`
  a `https://inv-supplier.invlab.example`, y ninguna de esas URLs está escrita dentro del
  jar salvo la de `prod`.
- El token sale siempre de un config tree, nunca de una variable de entorno ni del YAML.
- `prod` activa el grupo de profiles de la sección 8 y arranca con `env` y `configprops`
  **no expuestos**, mientras `local` los expone con `show-values: ALWAYS`.
- Un valor inválido en cualquiera de los tres entornos impide el arranque, y el script
  devuelve el código de salida de `java` sin tragárselo.
- El script imprime al final, leyendo Actuator cuando está disponible, una tabla de tres
  columnas: propiedad, valor y fuente ganadora.

**Objetivo:** demostrar con un artefacto que la promoción de un artefacto entre entornos es
un problema de entorno y no de build — y tener algo concreto que describir cuando en la
entrevista pregunten cómo gestionabas la configuración.

---

## 🏁 La señal de que quedó bien

El mismo `target/inv-api-0.0.1-SNAPSHOT.jar`, sin recompilar, imprime `2s`, `3s`, `4s`,
`5s` o `6s` según cómo lo lances, y puedes decir **antes de ejecutar** cuál va a salir.
`curl -s localhost:8081/actuator/env/inv.supplier.timeout | jq '.property.source'` nombra
la fuente ganadora en un solo comando, `./secrets` ya no existe, `secrets/` está en el
`.gitignore`, y `docker compose -p inv-lab ps` no lista nada porque este lab nunca levantó
un contenedor.

El siguiente lab, `L03`, construye la API REST de `inv-api` sobre esta configuración: los
timeouts y la URL del proveedor que acabas de tipar son los que [`L05`](l05-clientes-y-resiliencia.md) acabará usando de
verdad.

---

## 📚 Referencias oficiales

- Spring Boot 3.5 — Externalized Configuration y orden de precedencia: https://docs.spring.io/spring-boot/3.5/reference/features/external-config.html
- Spring Boot 3.5 — `@ConfigurationProperties` tipadas y validación: https://docs.spring.io/spring-boot/3.5/reference/features/external-config.html#features.external-config.typesafe-configuration-properties
- Spring Boot 3.5 — Profiles: https://docs.spring.io/spring-boot/3.5/reference/features/profiles.html
- Spring Boot 3.5 — Endpoints de Actuator (`env`, `configprops`, `show-values`): https://docs.spring.io/spring-boot/3.5/reference/actuator/endpoints.html
- Spring Boot 3.5 — Recetas de configuración externa: https://docs.spring.io/spring-boot/3.5/how-to/properties-and-configuration.html
- Spring Boot 3.5 — Metadatos de configuración y el annotation processor: https://docs.spring.io/spring-boot/3.5/specification/configuration-metadata/annotation-processor.html
- Spring Boot 3.5 — `spring-boot:run` y sus argumentos: https://docs.spring.io/spring-boot/3.5/maven-plugin/run.html
- Spring Framework 6.2 — `Environment` y `PropertySource`: https://docs.spring.io/spring-framework/reference/6.2/core/beans/environment.html
- Spring Framework 6.2 — Bean Validation: https://docs.spring.io/spring-framework/reference/6.2/core/validation/beanvalidation.html

### Documentación de terceros

- YAML 1.1 — tipo `bool` (`on`, `off`, `yes`, `no`): https://yaml.org/type/bool.html
- Java 21 — `java.time.Duration`: https://docs.oracle.com/en/java/javase/21/docs/api/java.base/java/time/Duration.html
