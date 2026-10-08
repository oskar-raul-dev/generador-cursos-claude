# A04 — Migración 3.5 → 4.x

> **Objetivo:** que puedas decir, delante de un entrevistador o de tu propio `pom.xml`, **qué
> exactamente deja de ser cierto** cuando el servicio pasa del baseline del curso —Spring Boot
> 3.5.16— a la línea 4.x que hoy es GA. No es una guía de migración genérica: es el recorrido
> de lo que **este curso afirma**, entrada por entrada, con el capítulo donde se afirma y la
> fuente que verifica el cambio.
> **Asume:** haber leído los capítulos que cada entrada enlaza. Es material de consulta: se abre
> por la sección que te toca y se cierra.
> **Vigencia:** 19 de septiembre de 2026 · baseline del curso Spring Boot 3.5.16 / Spring
> Framework 6.2.19 / Java 21 · línea de destino **Spring Boot 4.1.1** (el último release en
> `repo1.maven.org` ese día) · todas las versiones, fechas y renombres de abajo se leyeron del
> POM del BOM, del bytecode de los jar o de `api.spring.io` ese mismo día.
>
> **⚠️ Este apéndice caduca antes que ningún otro documento del curso.** Los demás explican
> mecanismos que llevan diez años en pie; este enumera el estado de una migración en curso, y
> ese estado cambia con cada minor. El criterio para saber si sigue siendo válido está en la
> [§1](#1--cómo-se-usa-este-apéndice-y-por-qué-caduca-antes-que-los-demás) y se comprueba con
> dos comandos.
>
> **📝 Excepción declarada de enlaces.** La §10.2 de la guía de estilo obliga a que toda URL de
> `docs.spring.io` lleve en la ruta la versión del baseline. **Este documento es la excepción
> que esa misma sección declara**: sus enlaces apuntan a la línea 4.x y a las release notes,
> porque describen precisamente lo que el baseline **no** dice. Hay un detalle operativo que
> conviene saber y está explicado en la [§1](#1--cómo-se-usa-este-apéndice-y-por-qué-caduca-antes-que-los-demás):
> hoy `docs.spring.io/spring-boot/4.1/…` responde `302` hacia la URL **sin** versión, porque 4.1
> *es* la línea actual, así que lo que está escrito abajo es la URL final tras seguir la
> redirección, que es lo que manda §10.1.

**Salto rápido:** [Cómo se usa](#1--cómo-se-usa-este-apéndice-y-por-qué-caduca-antes-que-los-demás) ·
[Calendario de soporte](#2--el-calendario-de-soporte-y-cómo-se-defiende-una-línea-en-entrevista) ·
[El salto, columna por columna](#3--el-salto-columna-por-columna) ·
[Java, Jakarta y Servlet](#4--requisitos-previos-java-jakarta-ee-y-servlet) ·
[Starters y diseño modular](#5--el-renombre-de-starters-y-el-diseño-modular) ·
[Jackson 3](#6--jackson-3-qué-import-cambia-y-cuál-no) ·
[Spring Security 7](#7--spring-security-7-lo-que-ya-no-compila) ·
[Spring Batch 6](#8--spring-batch-6-enablejdbcjobrepository-y-los-dos-absorbidos) ·
[Observabilidad](#9--observabilidad-la-propiedad-que-cambia-de-nombre) ·
[El test framework](#10--el-test-framework-se-mudó-de-paquete) ·
[Web y datos](#11--web-y-datos-lo-que-se-gana-y-lo-que-se-revisa) ·
[`properties-migrator`](#12--spring-boot-properties-migrator-qué-hace-y-hasta-dónde-llega) ·
[OpenRewrite](#13--openrewrite-qué-automatiza-y-qué-te-deja-a-ti) ·
[La migración 2.7 → 3.x](#14--la-migración-27--3x-que-es-la-que-todavía-te-van-a-preguntar) ·
[Checklist](#15--checklist-de-migración-de-un-servicio-real) ·
[Errores frecuentes](#16-️-errores-frecuentes-al-contar-esta-migración) ·
[Preguntas rápidas](#-preguntas-rápidas) ·
[Ejercicios](#-ejercicios-12)

---

## 1. 🧭 Cómo se usa este apéndice, y por qué caduca antes que los demás

Abres este documento por una de tres razones: tu `pom.xml` va a subir de línea, te preguntaron
en una entrevista "¿y qué cambia en Boot 4?", o estás leyendo un capítulo del curso y viste un
📝 que te mandó aquí. Las tres se resuelven igual: buscas la entrada, lees **qué afirma el
curso hoy**, **qué cambia** y **dónde se estudia**, y vuelves al capítulo.

Cada entrada de este apéndice tiene esas tres partes y ninguna reexplica el mecanismo. Si
quieres saber qué es el `JobRepository`, el sitio es [`22` §4](22-spring-batch.md#4--el-jobrepository-seis-tablas-y-ningún-truco);
aquí solo dice que en Batch 6 absorbió a `JobExplorer`.

**Por qué caduca.** Los demás documentos describen mecanismos —el contenedor, el proxy, la
transacción— que se mueven en escalas de años. Este describe el estado de una migración viva:
la línea 4.x saca un minor cada seis meses y cada uno retira algo más. El criterio de vigencia
es concreto y se comprueba en dos comandos:

```bash
# 1. ¿sigue siendo 4.1.1 la última release de la línea?
curl -s https://repo1.maven.org/maven2/org/springframework/boot/spring-boot-dependencies/maven-metadata.xml \
  | grep -oE '<release>[^<]+' | cut -c10-

# 2. ¿siguen siendo estas las fechas de soporte?
curl -s https://api.spring.io/projects/spring-boot/generations \
  | python3 -c 'import sys,json;[print(g["name"],g["initialReleaseDate"],g["ossSupportEndDate"],g["commercialSupportEndDate"]) for g in json.load(sys.stdin)["_embedded"]["generations"]]'
```

- **`maven-metadata.xml`** es el índice que Maven Central mantiene por artefacto; `<release>`
  es la última versión no-snapshot publicada. Si lo que sale no es `4.1.1`, las tablas de las
  §3 y §5 hay que releerlas contra el POM nuevo antes de citarlas.
- **`api.spring.io/projects/<proyecto>/generations`** es la API que alimenta la tabla de
  soporte de `spring.io`. Devuelve JSON, no HTML, y por eso es la fuente que se cita en la §2:
  la página web pinta esa misma tabla desde aquí.
- **`cut -c10-`** recorta el `<release>` de la izquierda. Es cosmética, no cambia el resultado.
- **Si el primer comando devuelve un `4.2.x` o superior**, este apéndice sigue siendo útil para
  todo lo de 3.5 → 4.0, que es el grueso, pero las versiones de la §3 ya no son las que arrastra
  el BOM y hay que rehacerlas.

> **📝 La trampa de enlace, al revés.** [§10.2 de la guía de estilo](prompts/guia-de-estilo-y-convenciones.md)
> avisa de que una URL de `docs.spring.io` **sin** versión sirve la línea actual y no la del
> curso. En este apéndice esa es justamente la URL que queremos: la línea actual **es** el
> destino de la migración. Y hay un detalle verificado hoy que conviene conocer —
> `docs.spring.io/spring-boot/4.1/reference/using/index.html` responde `302` hacia
> `docs.spring.io/spring-boot/reference/using/index.html`, porque 4.1 es la línea corriente,
> mientras que `/spring-boot/4.0/reference/using/index.html` responde `200` directo por estar
> ya archivada. Las referencias de abajo llevan la URL final, no la que redirige.

---

## 2. 🧭 El calendario de soporte, y cómo se defiende una línea en entrevista

El curso afirma en [`01` §8](01-spring-boot-y-el-ecosistema.md#8--soporte-eol-y-por-qué-el-baseline-es-una-versión-sin-soporte-oss)
que el baseline 3.5 está fuera de soporte open source y que eso es una decisión, no un
descuido. Esta tabla es la evidencia, leída de `api.spring.io` el 19 de septiembre de 2026:

| Línea de Boot | GA | Fin de soporte OSS | Fin de soporte comercial |
|---|---|---|---|
| 2.7.x | 2022-05-31 | 2023-06-30 | 2029-06-30 |
| 3.4.x | 2024-11-30 | 2025-12-31 | 2026-12-31 |
| **3.5.x** (baseline del curso) | 2025-05-31 | **2026-06-30** | **2032-06-30** |
| 4.0.x | 2025-11-30 | 2026-12-31 | 2027-12-31 |
| **4.1.x** (GA hoy) | 2026-06-30 | 2027-07-31 | 2028-07-31 |
| 4.2.x (anunciada) | 2026-11-30 | 2027-12-31 | 2028-12-31 |

Lo que hay que leer en esa tabla, y que es la respuesta de entrevista:

- **Una línea de Boot recibe trece meses de parches OSS** desde su GA, redondeado a fin de mes.
  Trece, no doce: el mes extra es el solape que te deja migrar.
- **La última minor de una major cobra cinco años más de soporte comercial.** Por eso 2.7 llega
  a 2029 y 3.5 llega a **2032**, mientras que 4.0 se corta en 2027. No es que 3.5 sea "mejor":
  es que es la puerta de salida de la major 3, y Broadcom la mantiene abierta para quien paga.
- **En banca eso cambia la conversación.** Un servicio en 3.5 con soporte comercial está
  *soportado hasta 2032* y no es una deuda urgente; el mismo servicio en 3.4 caducó su soporte
  comercial en diciembre de 2026 y sí lo es. La pregunta correcta no es "¿estás en la última?"
  sino "¿estás en una línea con soporte, y quién lo paga?".

> **🧠 Modelo mental.** Las líneas intermedias de una major (3.0 a 3.4) tienen trece meses de
> OSS y un año más de comercial. La última de la major (2.7, 3.5) tiene los mismos trece meses
> de OSS y **cinco años** de comercial encima. Elegir baseline es elegir en qué escalón de esa
> escalera te paras.

**Dónde se estudia:** [`01` §8](01-spring-boot-y-el-ecosistema.md#8--soporte-eol-y-por-qué-el-baseline-es-una-versión-sin-soporte-oss).
**Fuente:** `https://api.spring.io/projects/spring-boot/generations`.

---

## 3. ⚖ El salto, columna por columna

Todo lo que sigue en este apéndice es consecuencia de esta tabla. Cada número salió de leer el
`<properties>` de los dos POM del BOM en `repo1.maven.org`, no de una release note:

| Pieza | Boot 3.5.16 (baseline) | Boot 4.1.1 (GA hoy) |
|---|---|---|
| Spring Framework | 6.2.19 | **7.0.9** |
| Spring Security | 6.5.11 | **7.1.1** |
| Spring Batch | 5.2.6 | **6.0.5** |
| Spring Data (BOM) | 2025.0.13 | **2026.0.1** |
| Hibernate ORM | 6.6.53.Final | **7.4.5.Final** |
| Hibernate Validator | 8.0.3.Final | **9.1.3.Final** |
| Jackson | 2.21.4 | **3.1.5** (+ 2.21.5 gestionado) |
| Micrometer / Tracing | 1.15.12 / 1.5.12 | **1.17.1 / 1.7.1** |
| Tomcat | 10.1.55 | **11.0.24** |

Y el comando que la reproduce, porque dentro de seis meses los números serán otros:

```bash
for v in 3.5.16 4.1.1; do
  echo "== $v =="
  curl -s "https://repo1.maven.org/maven2/org/springframework/boot/spring-boot-dependencies/$v/spring-boot-dependencies-$v.pom" \
    | grep -E '<(spring-framework|spring-security|spring-batch|spring-data-bom|jackson-bom|hibernate|micrometer|tomcat)[^>]*\.version>'
done
```

- **El BOM de Boot es un POM de tipo `pom` con un `<dependencyManagement>` enorme**, y todas
  las versiones que gestiona salen de propiedades declaradas arriba del archivo. Leer esas
  propiedades es leer el árbol de versiones de [`01` §7](01-spring-boot-y-el-ecosistema.md#7--el-árbol-de-versiones-qué-elige-a-qué)
  sin instalar nada.
- **`grep -E` con la alternancia** filtra solo las propiedades que nos interesan; el POM de
  4.1.1 tiene 3 761 líneas y más de trescientas propiedades de versión.
- **`spring-data-bom` no usa el esquema `mayor.menor.parche`** sino el de *release train*
  (`2026.0.1`): dentro de él, Spring Data Commons y JPA van por `4.1.1` y Spring Data MongoDB
  por `5.1.1`. Es la misma disonancia contra la que avisa §10.2 de la guía de estilo al
  escribir rutas de documentación.

> **📝 Un matiz sobre lo que dice el curso.** [`23` §10](23-actuator-y-observabilidad.md#10--trazas-traceid-spanid-w3c-y-sampling)
> afirma que "Boot 4 sube a Micrometer 1.16 y Micrometer Tracing 1.6". Eso era exacto para
> **4.0**; en **4.1.1** el BOM ya trae 1.17.1 y 1.7.1. El capítulo no está mal: está fechado.
> Esta es exactamente la clase de detalle por la que este apéndice caduca antes que los demás.

---

## 4. 🧱 Requisitos previos: Java, Jakarta EE y Servlet

Antes de tocar el `pom.xml` hay tres pisos debajo que tienen que cuadrar, y si uno no cuadra el
proyecto ni compila.

La sobregeneralización de entrevista aquí es previsible: *"Boot 4 exige Java 21"*. No es
cierto, y se comprueba sin leer documentación:

```bash
cd /tmp && curl -sO https://repo1.maven.org/maven2/org/springframework/spring-core/7.0.9/spring-core-7.0.9.jar
unzip -o -q spring-core-7.0.9.jar 'org/springframework/core/SpringVersion.class'
javap -v org/springframework/core/SpringVersion.class | grep 'major version'
```

```text
  major version: 61
```

- **`javap -v`** desensambla el `.class` y muestra la cabecera, donde vive la versión de
  bytecode con la que se compiló.
- **`major version: 61` es Java 17.** La correspondencia es fija: 61 → 17, 62 → 18, 65 → 21.
  Spring Framework 7 se compila a 17, así que **Java 17 es el mínimo**, no 21.
- **El `Created-By` del `MANIFEST.MF` dice `25.0.4`**, que es el JDK con el que se construyó
  el artefacto. No es el mínimo que exige: son dos cosas distintas y confundirlas es el error
  que produce la respuesta equivocada.

Lo demás del piso de abajo:

| Piso | 3.5.16 | 4.1.1 | Consecuencia práctica |
|---|---|---|---|
| Java mínimo | 17 | **17** | no cambia; el curso fija 21 por virtual threads |
| Servlet | 6.0 (Tomcat 10.1) | **6.1 (Tomcat 11)** | `jakarta.servlet` sigue, cambia la minor |
| Jakarta EE | 10 | **11** | Hibernate Validator salta de 8 a 9 |
| Undertow | soportado | **eliminado** | incompatible con Servlet 6.1 |

**Qué afirma el curso:** [`08` §2](08-modelo-de-ejecucion-web.md#2--una-instancia-muchos-hilos)
describe el modelo de ejecución sobre Tomcat 10.1 y Servlet 6.0. El **mecanismo** —un hilo por
request, el pool de 200— no cambia en Servlet 6.1: lo que cambia son las versiones.
**Qué cambia:** el paquete `jakarta.servlet` se queda, Undertow desaparece como servidor
embebido soportado.
**Dónde se estudia:** [`08`](08-modelo-de-ejecucion-web.md) y
[`12`](12-reactivo-bloqueante-y-virtual-threads.md).

---

## 5. 🧱 El renombre de starters y el diseño modular

Este es el cambio que el lector ve primero, porque le rompe el `pom.xml`.

**Qué afirma el curso.** [`01` §4](01-spring-boot-y-el-ecosistema.md#4--qué-hay-dentro-de-un-starter)
enseña que un starter es un POM sin código que declara un conjunto coherente de dependencias, y
que el oficial se llama `spring-boot-starter-*`. [`L01`](l01-esqueleto-cli-y-autoconfiguracion.md)
genera `inv-api` con `spring-boot-starter-web` y `spring-boot-starter-test`.

**Qué cambia.** Boot 4 parte la autoconfiguración en módulos pequeños —`spring-boot-webmvc`,
`spring-boot-data-jpa`, `spring-boot-mongodb`— en vez de un `spring-boot-autoconfigure`
monolítico, y los starters siguen esa partición. La consecuencia visible:

| 3.5.16 | 4.1.1 | Estado verificado en el POM |
|---|---|---|
| `spring-boot-starter-web` | `spring-boot-starter-webmvc` | el viejo existe, **deprecado** |
| `spring-boot-starter-web-services` | `spring-boot-starter-webservices` | renombrado (sin guion) |
| `spring-boot-starter-oauth2-resource-server` | `spring-boot-starter-security-oauth2-resource-server` | prefijo `security-` |
| `spring-boot-starter-test` (lo traía todo) | `spring-boot-starter-test` + un `-test` por módulo | se partió |

La comprobación es directa y no depende de ninguna release note:

```bash
curl -s https://repo1.maven.org/maven2/org/springframework/boot/spring-boot-starter-web/4.1.1/spring-boot-starter-web-4.1.1.pom \
  | grep '<description>'
```

```text
  <description>Starter for building web, including RESTful, applications using Spring MVC.
  Uses Tomcat as the default embedded container (deprecated in favor of spring-boot-starter-webmvc)</description>
```

- **El `<description>` del propio artefacto publicado** declara la deprecación. Es la fuente
  más corta y menos discutible que existe para este dato.
- **`spring-boot-starter-websocket` conserva el nombre** y pasa a apoyarse en el módulo
  `spring-boot-websocket`; lo que cambia es la lista de contenedores que Boot autoconfigura para
  WebSocket —**Tomcat y Jetty**; Undertow sale—, según la página de WebSockets de la referencia
  4.x. `SseEmitter`, `@MessageMapping` y el broker relay no cambian de API
  ([`14` §8](14-tiempo-real-sse-y-websocket.md#8--cómo-se-elige-y-el-veredicto)).
- **`spring-boot-starter-web` no desapareció**: sigue en Maven Central y sigue resolviendo, con
  las mismas cinco dependencias que `spring-boot-starter-webmvc`. Si alguien te dice en una
  entrevista que "en Boot 4 el starter web ya no existe", la versión precisa es **"está
  deprecado en favor de `spring-boot-starter-webmvc`, y el POM lo dice en su descripción"**.
- **`spring-boot-starter-test` sí cambia de significado.** Sigue existiendo y sigue trayendo
  JUnit, AssertJ, Mockito y Hamcrest, pero **ya no arrastra la infraestructura de test de cada
  tecnología**. `@WebMvcTest` vive ahora en `spring-boot-starter-webmvc-test`; `@WithMockUser`,
  en `spring-boot-starter-security-test`. Sin ellos no hay error de dependencia: hay un test que
  compila y no hace lo que crees, que es peor.
- **`spring-boot-starter-classic` y `spring-boot-starter-test-classic`** existen a propósito:
  arrastran `spring-boot-autoconfigure-classic`, el módulo puente que reagrupa todo como antes.
  Son un **escalón intermedio de migración**, no un destino, y la guía oficial dice que
  eventualmente hay que salir de ellos.

> **⚠️ Un `pom.xml` copiado entre líneas falla de las dos direcciones.** De 4.x a 3.5,
> `spring-boot-starter-webmvc` no existe y Maven falla al resolver. De 3.5 a 4.x, el viejo
> resuelve pero tus tests pierden la mitad de su infraestructura sin avisar.

**Dónde se estudia:** [`01` §4](01-spring-boot-y-el-ecosistema.md#4--qué-hay-dentro-de-un-starter),
[`01` §5](01-spring-boot-y-el-ecosistema.md#5--el-bom-por-qué-tu-pomxml-no-tiene-versiones) y
[`L01`](l01-esqueleto-cli-y-autoconfiguracion.md). Para auditar tu propio árbol,
[`A01` §5](a01-cli-y-tooling-de-supervivencia.md#5--el-árbol-de-dependencias-y-un-conflicto-real).

---

## 6. 🧱 Jackson 3: qué import cambia y cuál no

**Qué afirma el curso.** [`09` §7](09-rest-con-spring-mvc.md#7--httpmessageconverter-y-jackson)
explica que el `MappingJackson2HttpMessageConverter` serializa tu objeto con un `ObjectMapper` de
`com.fasterxml.jackson.databind`, y [`A03` §5](a03-catalogo-de-errores-y-diagnostico.md#5-️-el-borde-web-el-código-de-estado-que-miente)
enseña a leer el `HttpMessageNotReadableException` cuya causa es una excepción de Jackson.

**Qué cambia.** El baseline pasa a Jackson 3, y con él el `groupId` y el paquete raíz. Pero
**no todo se mueve**, y la mitad que se queda quieta es la que más se usa:

| Elemento | Jackson 2 (3.5.16) | Jackson 3 (4.1.1) |
|---|---|---|
| Coordenada de `databind` | `com.fasterxml.jackson.core:jackson-databind` | **`tools.jackson.core:jackson-databind`** |
| `ObjectMapper` | `com.fasterxml.jackson.databind.ObjectMapper` | **`tools.jackson.databind.ObjectMapper`** |
| `@JsonProperty`, `@JsonIgnore`, `@JsonFormat` | `com.fasterxml.jackson.annotation.*` | **igual, no se movieron** |
| `UnrecognizedPropertyException` | `…jackson.databind.exc` | **`tools.jackson.databind.exc`** |

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

- **El BOM de Jackson 3 gestiona `jackson-annotations` bajo el `groupId` viejo.** No es un
  descuido: las anotaciones son la API que aparece en el código de todo el mundo, y moverlas
  habría roto cada DTO del ecosistema. Las anotaciones se quedan en
  `com.fasterxml.jackson.annotation`.
- **Lo que sí se mueve es la maquinaria**: `ObjectMapper`, los módulos, las excepciones.
- **`JsonMappingException` ya no está**: la raíz de la jerarquía de errores de binding es
  `tools.jackson.databind.DatabindException`. Cualquier `catch` o `grep` de runbook escrito
  contra el nombre viejo deja de encontrar nada, y ese es el aviso literal de
  [`A03` §5](a03-catalogo-de-errores-y-diagnostico.md#5-️-el-borde-web-el-código-de-estado-que-miente).
- **Dos anotaciones propias de Boot cambiaron de nombre**, verificado en el jar
  `spring-boot-jackson-4.1.1`: `@JsonComponent` → **`@JacksonComponent`** y `@JsonMixin` →
  **`@JacksonMixin`**, ambas en `org.springframework.boot.jackson`.
- **Jackson 2 sigue disponible** en un módulo deprecado, `spring-boot-jackson2`, y el BOM de
  Boot 4.1.1 importa **los dos** BOM de Jackson (`tools.jackson:jackson-bom:3.1.5` y
  `com.fasterxml.jackson:jackson-bom:2.21.5`). Puedes migrar en dos pasos.

> **📝 La sobregeneralización.** *"Jackson 3 te cambia todos los imports"* es falso y cuesta
> tiempo en la planificación. Lo que cambia son los imports de **infraestructura** —el
> `ObjectMapper` de tu `@Configuration`, el `Module` que registrabas a mano, el `catch` de
> `JsonMappingException`—. Tus `record` de DTO anotados con `@JsonProperty` compilan sin tocar
> una línea.

**Dónde se estudia:** [`09` §7](09-rest-con-spring-mvc.md#7--httpmessageconverter-y-jackson),
[`A03` §5](a03-catalogo-de-errores-y-diagnostico.md#5-️-el-borde-web-el-código-de-estado-que-miente)
y [`L03`](l03-api-rest-filtros-y-errores.md).

---

## 7. 🧱 Spring Security 7: lo que ya no compila

**Qué afirma el curso.** [`20` §3](20-spring-security-el-mecanismo.md#3--la-cadena-se-declara-como-bean)
enseña la cadena como `@Bean SecurityFilterChain` con estilo lambda, y avisa de que
`WebSecurityConfigurerAdapter`, `antMatchers` y `authorizeRequests` se eliminaron en Security 6.
[`21` §6](21-identidad-federada-oauth2-oidc-y-jwt.md#6--inv-api-como-resource-server-dos-propiedades-y-un-matcher)
configura `inv-api` como resource server con `spring.security.oauth2.resourceserver.*`.

**Qué cambia.** Con Boot 4.1.1 llega Security 7.1.1, y lo que estaba deprecado en 6.x se
retira. La forma que enseña el curso **sobrevive entera**; lo que muere es el estilo viejo que
el curso ya marcaba como muerto.

```bash
cd /tmp && curl -sO https://repo1.maven.org/maven2/org/springframework/security/spring-security-config/7.1.1/spring-security-config-7.1.1.jar
unzip -o -q spring-security-config-7.1.1.jar 'org/springframework/security/config/annotation/web/builders/HttpSecurity.class'
javap -p org/springframework/security/config/annotation/web/builders/HttpSecurity.class | grep -cE ' and\(\)'
unzip -l spring-security-config-7.1.1.jar | grep -c WebSecurityConfigurerAdapter
```

```text
0
0
```

- **`javap -p`** lista todos los miembros, incluidos los no públicos: si `and()` estuviera,
  saldría. El conteo es `0`.
- **Cada método de `HttpSecurity` acepta hoy un único `Customizer<…>`**: no hay sobrecarga sin
  argumentos, así que el encadenado con `.and()` no es que esté desaconsejado — no compila.
  **El estilo lambda dejó de ser una preferencia y pasó a ser la única API.**
- **`WebSecurityConfigurerAdapter` no está en el jar.** Lleva fuera desde Security 6.0, pero
  conviene poder decirlo con la evidencia: `unzip -l | grep -c` devuelve `0`.
- **`@EnableGlobalMethodSecurity` sí sigue en el jar, deprecada.** El reemplazo es
  `@EnableMethodSecurity`, que es el que enseña
  [`20` §8](20-spring-security-el-mecanismo.md#8--method-security-el-proxy-de-05-con-otro-sombrero).
- **Los starters de OAuth2 llevan prefijo `security-`**: `spring-boot-starter-oauth2-resource-server`
  pasa a `spring-boot-starter-security-oauth2-resource-server`. Las propiedades
  `spring.security.oauth2.resourceserver.*` de [`21` §6](21-identidad-federada-oauth2-oidc-y-jwt.md#6--inv-api-como-resource-server-dos-propiedades-y-un-matcher)
  no cambian.
- **El que muerde en silencio:** `@WithMockUser` y `@WithUserDetails` de `spring-security-test`
  necesitan ahora `spring-boot-starter-security-test`. Sin él la anotación está en el classpath
  pero la infraestructura que la aplica no, y el test corre sin el usuario que creías haber
  puesto.

**Dónde se estudia:** [`20` §3](20-spring-security-el-mecanismo.md#3--la-cadena-se-declara-como-bean),
[`20` §8](20-spring-security-el-mecanismo.md#8--method-security-el-proxy-de-05-con-otro-sombrero),
[`21` §6](21-identidad-federada-oauth2-oidc-y-jwt.md#6--inv-api-como-resource-server-dos-propiedades-y-un-matcher)
y [`L08`](l08-security-y-batch.md).

---

## 8. 🧱 Spring Batch 6: `@EnableJdbcJobRepository` y los dos absorbidos

**Qué afirma el curso.** [`22` §4](22-spring-batch.md#4--el-jobrepository-seis-tablas-y-ningún-truco)
describe el `JobRepository` y sus seis tablas; [`22` §10](22-spring-batch.md#10--lanzarlo-probarlo-y-vigilarlo)
lanza el job con el `JobLauncher` y consulta el estado con el `JobExplorer`;
[`A02` §16](a02-catalogo-de-anotaciones.md#16--batch) cataloga `@EnableBatchProcessing`.

**Qué cambia.** Batch 5.2.6 → 6.0.5. El modelo —job, step, chunk, `JobRepository`— sigue
idéntico. Lo que cambia son cuatro cosas concretas, verificadas en el jar de
`spring-batch-core-6.0.5`:

| Pieza | Batch 5.2.6 | Batch 6.0.5 |
|---|---|---|
| `JobExplorer` | `…batch.core.explore.JobExplorer` | `…batch.core.repository.explore.JobExplorer`, **deprecada** |
| `JobLauncher` | `…batch.core.launch.JobLauncher` | mismo paquete, **deprecada** |
| Quién los absorbe | — | `JobRepository` y `JobOperator` |
| Activación | `@EnableBatchProcessing` sola | `@EnableBatchProcessing` **+** `@EnableJdbcJobRepository` |

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

- **`@EnableBatchProcessing`** sigue haciendo lo mismo: registra `JobRepository`,
  `JobOperator` y el resto de la infraestructura como beans.
- **`@EnableJdbcJobRepository`** es nueva y **elige el almacenamiento**. Su hermana es
  `@EnableMongoJobRepository`. En Batch 5 el almacenamiento JDBC era el único y estaba
  implícito; en Batch 6 es una decisión que se escribe. Ambas están en
  `org.springframework.batch.core.configuration.annotation`.
- **El transaction manager pasó a opcional** en `@EnableBatchProcessing`: en Batch 5 había que
  nombrarlo con `transactionManagerRef` en varios escenarios. Eso no relaja la regla de
  [`22` §8](22-spring-batch.md#8-️-el-writer-falla-a-la-mitad-del-chunk-el-puente-con-16):
  el chunk sigue siendo la unidad transaccional.
- **`JobLauncher` y `JobExplorer` siguen en el jar, marcados `@Deprecated`.** Compilan, con
  warning. El código nuevo usa `JobOperator` para lanzar y `JobRepository` para consultar.

```bash
javap -v org/springframework/batch/core/launch/JobLauncher.class | grep -c 'Deprecated: true'
```

```text
1
```

- **`Deprecated: true` es un atributo del `.class`**, puesto por el compilador a partir de
  `@Deprecated`. Que aparezca en el bytecode es la prueba de que la deprecación es real y no
  solo una nota del javadoc.

**Dónde se estudia:** [`22` §4](22-spring-batch.md#4--el-jobrepository-seis-tablas-y-ningún-truco),
[`22` §10](22-spring-batch.md#10--lanzarlo-probarlo-y-vigilarlo),
[`A02` §16](a02-catalogo-de-anotaciones.md#16--batch) y [`L08`](l08-security-y-batch.md).

---

## 9. 🧱 Observabilidad: la propiedad que cambia de nombre

**Qué afirma el curso.** [`23` §10](23-actuator-y-observabilidad.md#10--trazas-traceid-spanid-w3c-y-sampling)
enseña que `management.tracing.enabled=false` apaga las trazas, y ya marca con 📝 que en 4.x se
renombra.

**Qué cambia.** Se renombra a `management.tracing.export.enabled`, y no es cosmético: **separa
instrumentar de exportar**. El dato se lee del propio artefacto, que es la fuente que consume
el `properties-migrator` de la §12:

```bash
cd /tmp && curl -sO https://repo1.maven.org/maven2/org/springframework/boot/spring-boot-micrometer-tracing/4.1.1/spring-boot-micrometer-tracing-4.1.1.jar
unzip -p spring-boot-micrometer-tracing-4.1.1.jar META-INF/spring-configuration-metadata.json \
  | python3 -c 'import sys,json;[print(json.dumps(p,indent=2)) for p in json.load(sys.stdin)["properties"] if p["name"]=="management.tracing.enabled"]'
```

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

- **`META-INF/spring-configuration-metadata.json`** es el fichero que genera el
  `spring-boot-configuration-processor` y el que alimenta el autocompletado de tu IDE. Cada
  propiedad deprecada lleva ahí su reemplazo y desde cuándo.
- **`"level": "error"`, no `"warning"`.** Esa distinción decide el comportamiento: una
  deprecación de nivel `warning` sigue funcionando y solo avisa; una de nivel **`error` ya no
  se enlaza**. `management.tracing.enabled` en un `application.yml` de Boot 4 no apaga nada.
- **`"since": "4.0.0"`** confirma que el cambio entró en 4.0 y no en 4.1.
- **El porqué del renombre:** en 3.5 ese único interruptor apagaba a la vez la instrumentación
  (crear spans) y la exportación (mandarlos a Zipkin o al collector). En 4.x
  `management.tracing.export.enabled=false` deja de exportar pero **sigue instrumentando**, y
  por tanto sigue habiendo `traceId` en el MDC y en tus líneas de log. Si migras a ciegas y el
  `traceId` desaparece de los logs, mira esta propiedad antes que el `logging.pattern`.
- **Las versiones también suben:** Micrometer 1.15.12 → 1.17.1 y Micrometer Tracing 1.5.12 →
  1.7.1 (§3).

Y una segunda que toca el mismo capítulo: `spring.dao.exceptiontranslation.enabled` pasa a
`spring.persistence.exceptiontranslation.enabled`, verificada en la release note de 4.0.

**Dónde se estudia:** [`23` §10](23-actuator-y-observabilidad.md#10--trazas-traceid-spanid-w3c-y-sampling),
[`23` §11](23-actuator-y-observabilidad.md#11--logging-correlación-json-y-lo-que-no-se-escribe-nunca)
y [`L07`](l07-actuator-metricas-y-trazas.md).

---

## 10. 🧱 El test framework se mudó de paquete

Este es el cambio que más archivos toca de un proyecto real, y el único donde un renombre mal
entendido produce **tests que pasan sin probar nada**.

**Qué afirma el curso.** [`24` §4](24-testing.md#4--los-slices-qué-autoconfigura-cada-uno-y-qué-deja-fuera)
cataloga los slices `@WebMvcTest`, `@DataJpaTest` y `@RestClientTest`;
[`24` §5](24-testing.md#5--mockitobean-y-mockitospybean-sustituir-un-bean-no-un-objeto)
enseña `@MockitoBean` y avisa de que `@MockBean` está deprecada;
[`24` §7](24-testing.md#7--mockmvc-webtestclient-y-testresttemplate) compara `MockMvc`,
`WebTestClient` y `TestRestTemplate`.

**Qué cambia.** Cada módulo de test adopta la raíz `org.springframework.boot.<módulo>.test`:

| Anotación | 3.5.16 | 4.1.1 |
|---|---|---|
| `@WebMvcTest` | `…boot.test.autoconfigure.web.servlet` | **`…boot.webmvc.test.autoconfigure`** |
| `@AutoConfigureMockMvc` | `…boot.test.autoconfigure.web.servlet` | **`…boot.webmvc.test.autoconfigure`** |
| `@DataJpaTest` | `…boot.test.autoconfigure.orm.jpa` | **`…boot.data.jpa.test.autoconfigure`** |
| `@RestClientTest` | `…boot.test.autoconfigure.web.client` | **`…boot.restclient.test.autoconfigure`** |
| `@SpringBootTest` | `…boot.test.context` | **igual, no se movió** |

Y tres cambios de comportamiento que no son un simple import:

- **`@MockBean` y `@SpyBean` se eliminaron.** No están en `spring-boot-test-4.1.1.jar`: el
  paquete `org.springframework.boot.test.mock.mockito` desapareció entero. El reemplazo es
  `@MockitoBean` y `@MockitoSpyBean`, de `org.springframework.test.context.bean.override.mockito`,
  que es exactamente lo que el curso ya usa en [`24` §5](24-testing.md#5--mockitobean-y-mockitospybean-sustituir-un-bean-no-un-objeto)
  y en [`A02` §17](a02-catalogo-de-anotaciones.md#17--testing). **Un proyecto escrito siguiendo
  este curso no tiene que tocar nada aquí**, y esa era la razón del 📝.
- **`@SpringBootTest` ya no autoconfigura `MockMvc`, `WebTestClient` ni `TestRestTemplate`.**
  Hay que añadir `@AutoConfigureMockMvc`, `@AutoConfigureRestTestClient` o
  `@AutoConfigureTestRestTemplate` explícitamente. Si no lo haces, el fallo es un
  `NoSuchBeanDefinitionException` al inyectar — el mismo de
  [`A03` §3](a03-catalogo-de-errores-y-diagnostico.md#3--el-contexto-que-no-arranca), con otra
  causa.
- **Aparece `RestTestClient`**, en `org.springframework.test.web.servlet.client`: la API fluida
  de `WebTestClient` pero sin arrastrar WebFlux a un proyecto MVC. Es la pieza que faltaba en la
  comparación de [`24` §7](24-testing.md#7--mockmvc-webtestclient-y-testresttemplate).

```bash
# la prueba de que @MockBean ya no existe
curl -s -o /tmp/bt4.jar https://repo1.maven.org/maven2/org/springframework/boot/spring-boot-test/4.1.1/spring-boot-test-4.1.1.jar
unzip -l /tmp/bt4.jar | grep -c 'mock/mockito/MockBean.class'
```

```text
0
```

- **`unzip -l | grep -c`** cuenta entradas del índice del jar sin descomprimirlo. Para
  "¿existe todavía esta clase?" es más rápido y más fiable que buscar en el javadoc.

> **⚠️ El riesgo real de esta sección no es el import.** Un import roto lo arregla el IDE en
> diez segundos. Lo que muerde es el test que sigue compilando porque el `spring-boot-starter-test`
> nuevo ya no trae la infraestructura de la §5: el slice no se aplica, el contexto que levanta no
> es el que creías, y la suite sigue verde.

**Dónde se estudia:** [`24` §4](24-testing.md#4--los-slices-qué-autoconfigura-cada-uno-y-qué-deja-fuera),
[`24` §5](24-testing.md#5--mockitobean-y-mockitospybean-sustituir-un-bean-no-un-objeto),
[`24` §7](24-testing.md#7--mockmvc-webtestclient-y-testresttemplate) y
[`A02` §17](a02-catalogo-de-anotaciones.md#17--testing).

---

## 11. 🧱 Web y datos: lo que se gana y lo que se revisa

Tres entradas cortas que cierran 📝 abiertos en el curso.

**Versionado de API, ahora de primera clase.**
[`10` §8](10-diseno-de-api-validacion-errores-e-hipermedia.md#8--versionado-path-header-o-media-type)
afirma que en 3.5.16 se versiona con prefijos de path o con `headers=` en el mapeo, y anuncia que
Framework 7 lo trae de serie. Confirmado en `spring-webmvc-7.0.9`: existen
`ApiVersionConfigurer`, `ApiVersionMethodArgumentResolver` y un
`ApiVersionDeprecationHandlerInterceptor`. El mapeo se escribe
`@RequestMapping(version = "1.1")` y la estrategia de resolución —path, cabecera, parámetro o
media type— se declara **una vez** en el configurador, no endpoint por endpoint.

**HTTP Interfaces, con registro de beans.**
[`13` §7](13-clientes-http.md#7--http-interfaces-declarativo-y-de-spring) enseña las HTTP
Interfaces creando el proxy a mano con `HttpServiceProxyFactory`. Framework 7 añade
`@ImportHttpServices` y un `AbstractHttpServiceRegistrar` en
`org.springframework.web.service.registry`, que registran esos proxies como beans por grupos.
El mecanismo del proxy es el de [`05`](05-proxies-y-aop.md) y no cambia: cambia quién lo crea.

**`RestTemplate` sigue vivo.** Verificado: `org.springframework.web.client.RestTemplate` está en
`spring-web-7.0.9.jar`. El veredicto de [`13` §9](13-clientes-http.md#9--los-cinco-y-el-veredicto)
—modo mantenimiento desde 5.0, no deprecado— sigue siendo exacto en Framework 7.

**Datos: Hibernate 7, Spring Data 4 y una familia de propiedades que se mueve.**
[`15` §8](15-datos-jdbc-jpa-mongo-y-redis.md#8--mongo-y-redis-qué-te-da-spring-data-y-cuál-es-la-trampa)
configura Mongo con `spring.data.mongodb.uri`. En 4.x esa clave se partió:

```text
spring.data.mongodb.uri   →  spring.mongodb.uri            (level: error, since 4.0.0)
spring.data.mongodb.host  →  spring.mongodb.host           (level: error, since 4.0.0)
```

- **La regla del corte:** lo que configura **el driver y la conexión** pasa a `spring.mongodb.*`;
  lo que configura **Spring Data** —el nombre de la base para los repositorios, la auditoría— se
  queda en `spring.data.mongodb.*`. Es la misma separación de módulos de la §5, aplicada a las
  propiedades.
- **El nivel vuelve a ser `error`**, igual que en la §9: la clave vieja no se enlaza, no es que
  avise.
- **Hibernate salta de 6.6 a 7.4 y Hibernate Validator de 8 a 9.** El mecanismo del persistence
  context de [`15` §5](15-datos-jdbc-jpa-mongo-y-redis.md#5--el-persistence-context-de-donde-salen-las-sorpresas)
  no cambia; lo que hay que revisar son los `@Type` propios, los dialectos declarados a mano y
  cualquier uso de API interna de Hibernate.
- **⏱️ Lo que este salto sí puede costarte en runtime:** un cambio de default de Hibernate en el
  *batch fetching* o en el *flush mode* no rompe nada visible y multiplica las consultas. Es el
  N+1 de [`15` §6](15-datos-jdbc-jpa-mongo-y-redis.md#6-️-n1-una-consulta-que-se-convierte-en-doscientas)
  reaparecido, y se mide igual: `spring.jpa.show-sql` y contar líneas.

> **📝 Lo que no pude verificar hoy, y se dice.** No tengo comprobado, artefacto en mano, **qué
> defaults concretos de los repositorios de Spring Data cambian** en el release train 2026.0.1
> respecto de 2025.0.13 —[`15`](15-datos-jdbc-jpa-mongo-y-redis.md#10-️-errores-frecuentes)
> afirma que "cambia algún default" sin nombrarlo—. Lo verificado es solo la tabla de versiones
> de la §3. La fuente que hay que mirar antes de afirmar nada es la página *What's New* de la
> referencia de Spring Data JPA de la línea 4.1 y el *Migration Guide* de Boot 4.0, ambos en las
> referencias del cierre. **No inventes el detalle en una entrevista: di que revisarías el
> release train.**

---

## 12. 🧱 `spring-boot-properties-migrator`: qué hace y hasta dónde llega

El problema es el de las §9 y §11: tienes un `application.yml` con cincuenta claves y no sabes
cuáles siguen enlazando. Leerlas una a una contra la referencia es media mañana.

```xml
<dependency>
    <groupId>org.springframework.boot</groupId>
    <artifactId>spring-boot-properties-migrator</artifactId>
    <scope>runtime</scope>
</dependency>
```

- **Sin `<version>`**, porque está en el BOM de Boot: es la regla de
  [`01` §5](01-spring-boot-y-el-ecosistema.md#5--el-bom-por-qué-tu-pomxml-no-tiene-versiones).
  Verificado: `spring-boot-properties-migrator:4.1.1` existe en Maven Central.
- **`<scope>runtime</scope>`** porque no lo compilas contra nada: actúa durante el arranque,
  leyendo el `Environment` que describe [`07` §2](07-configuracion-externalizada.md#2--environment-y-propertysource).
- **Qué hace exactamente:** recorre tus propiedades, las cruza contra los
  `spring-configuration-metadata.json` de todos los módulos del classpath —el mismo fichero que
  leímos a mano en la §9— y por cada clave deprecada **escribe un WARN con el reemplazo y, si la
  deprecación es de nivel `warning`, la reasigna temporalmente en memoria** para que la
  aplicación arranque.
- **Hasta dónde llega, y esto es lo que hay que saber decir.** Solo ve lo que está **declarado
  como deprecación con reemplazo en los metadatos**. No ve: propiedades que cambiaron de
  *significado* sin cambiar de nombre, claves que tú inventaste en tus
  `@ConfigurationProperties`, valores que dejaron de ser válidos, ni nada fuera del
  `Environment` (un `@Value` con un SpEL raro, una variable de entorno que alimenta otra cosa).
- **⏱️ Se quita después.** Es una dependencia de arranque que recorre todo el `Environment` y
  escribe logs; dejarla en producción suma trabajo en cada arranque y, peor, **oculta que la
  configuración sigue sin migrar**. Se añade, se lee el WARN, se arregla el `yml`, se quita y se
  verifica que arranca limpio.

> **🩺 Diagnóstico.** Arranca con el migrator y filtra: `./mvnw spring-boot:run 2>&1 | grep -i
> 'deprecated'`. Lo que salga es tu lista de tareas, literal. Lo que **no** salga no significa
> que esté bien: significa que el metadato no lo declara.

**Dónde se estudia:** [`07` §2](07-configuracion-externalizada.md#2--environment-y-propertysource)
y [`07` §9](07-configuracion-externalizada.md#9--auditar-de-dónde-salió-un-valor), que enseña a
auditar de dónde salió un valor con `/actuator/env`.

---

## 13. 🧱 OpenRewrite: qué automatiza y qué te deja a ti

Los renombres de paquete de las §6 y §10 son mecánicos y masivos: cientos de imports en un
monolito. Eso es exactamente lo que automatiza OpenRewrite, que aplica *recipes* —
transformaciones sobre el árbol sintáctico, no sobre el texto— desde Maven.

```bash
./mvnw -U org.openrewrite.maven:rewrite-maven-plugin:run \
  -Drewrite.recipeArtifactCoordinates=org.openrewrite.recipe:rewrite-spring:RELEASE \
  -Drewrite.activeRecipes=org.openrewrite.java.spring.boot4.UpgradeSpringBoot_4_0
```

- **`rewrite-maven-plugin:run`** aplica los cambios en el árbol de fuentes. Existe también
  `:dryRun`, que genera un `rewrite.patch` sin tocar nada: **se corre ese primero, siempre**.
- **`-Drewrite.recipeArtifactCoordinates`** dice de qué artefacto salen las recipes;
  `rewrite-spring` es el módulo de la comunidad para Spring.
- **`RELEASE` como versión es exactamente lo que el curso prohíbe** en
  [§5.1 de la guía de estilo](prompts/guia-de-estilo-y-convenciones.md) —nunca un rango, nunca
  `latest`—. Aparece aquí porque es la forma en que la documentación de OpenRewrite lo publica;
  **en tu build se fija la versión exacta** que hayas verificado, igual que cualquier otra
  dependencia fuera del BOM.
- **Recipes verificadas hoy** en `docs.openrewrite.org/recipes/java/spring/boot4`:
  `…boot4.UpgradeSpringBoot_4_0`, `…boot4.MigrateToModularStarters`,
  `…boot4.AddModularStarterDependencies`, `…boot4.SpringBootProperties_4_0`,
  `…boot4.SpringBootProperties_4_1`, `…boot4.RelocateWebServerClasses`,
  `…boot4.ReplaceMockBeanAndSpyBean` y los tres `AddAutoConfigure*`.

**Qué automatiza bien:** los imports de la §10, la sustitución de `@MockBean` por `@MockitoBean`,
añadir los `@AutoConfigureMockMvc` que la §10 volvió obligatorios, el cambio de starters y el
renombre de propiedades.

**Qué no automatiza, y es donde vas a estar tú:**

- **Las decisiones.** Quedarte en `spring-boot-starter-classic` o salir de él es una decisión de
  equipo; la recipe no la toma.
- **Lo semántico.** Un `management.tracing.enabled=false` que hoy apaga instrumentación y
  exportación y mañana solo exportación: el renombre lo hace la recipe, entender si querías
  apagar las dos cosas no.
- **Tu código de integración con librerías de terceros** que a su vez migraron.
- **Los tests que siguen verdes porque el slice dejó de aplicarse** (§10). Ninguna herramienta
  te avisa de un test que pasa.

> **⚠️ OpenRewrite es de la comunidad, no de Spring.** Es la única herramienta de este apéndice
> que no publica VMware/Broadcom, y por eso su documentación va en la subsección de terceros del
> cierre. Se ejecuta en una rama, con el `dryRun` leído a mano, y el diff se revisa como
> cualquier PR.

---

## 14. 🧭 La migración 2.7 → 3.x, que es la que todavía te van a preguntar

Aquí hay una asimetría que conviene nombrar: **la migración que más se pregunta en banca no es
la de este apéndice**. Es la anterior. Hay muchísimo servicio en Boot 2.7 —cuyo soporte
comercial llega a 2029 (§2), así que no hay prisa regulatoria— y el salto a 3.x es el que la
gente tiene fresco o pendiente.

Las cuatro piezas, con el capítulo donde el curso las explica en su forma actual:

| Qué se rompía en 2.7 → 3.0 | Por qué | Dónde se estudia la forma de hoy |
|---|---|---|
| `javax.*` → `jakarta.*` | Jakarta EE 9 renombró el namespace entero | [`08` §10](08-modelo-de-ejecucion-web.md#10--de-javax-a-jakarta-y-lo-que-quedó-atrás) |
| `WebSecurityConfigurerAdapter` eliminado | Security 6 pasó a configuración por bean | [`20` §3](20-spring-security-el-mecanismo.md#3--la-cadena-se-declara-como-bean) |
| `antMatchers` / `mvcMatchers` → `requestMatchers` | unificación del matcher | [`20` §7](20-spring-security-el-mecanismo.md#7--autorización-http-y-el-prefijo-role_) |
| `spring.factories` → `AutoConfiguration.imports` | catálogo de autoconfiguración nuevo | [`06` §4](06-arranque-y-autoconfiguracion.md#4--dónde-vive-el-catálogo-de-autoconfiguraciones) |

**`javax` → `jakarta`, y por qué no es un search-and-replace.** El renombre afecta a
`javax.persistence` (JPA), `javax.servlet`, `javax.validation` y `javax.annotation` de Jakarta —
pero **no** a `javax.sql.DataSource` ni a `javax.crypto`, que son del JDK y se quedan como están.
Reemplazar `javax.` por `jakarta.` a ciegas rompe el `DataSource` de
[`15` §2](15-datos-jdbc-jpa-mongo-y-redis.md#2--el-datasource-y-hikaricp).

```java
import jakarta.persistence.Entity;           // JPA: sí cambió
import jakarta.validation.Valid;             // Bean Validation: sí cambió
import javax.sql.DataSource;                 // JDK: NO cambió
```

- **La regla:** cambia lo que venía de Java/Jakarta **EE**. Lo que venía de **Java SE** se
  queda. Si el paquete está en el JDK, no se toca.
- **El síntoma cuando te equivocas** es un fallo de compilación inmediato, no un bug sutil: es
  la parte amable de esta migración.
- **La trampa de verdad** es la biblioteca de terceros que nunca sacó versión Jakarta. Ahí no
  hay migración: hay sustituir la librería, y eso es trabajo de semanas, no de tarde.

**El fin de `WebSecurityConfigurerAdapter`, dicho como se dice en una entrevista.** El curso ya
te da la frase exacta en [`20` §3](20-spring-security-el-mecanismo.md#3--la-cadena-se-declara-como-bean),
y aquí se repite porque es la respuesta que se pide:

> `WebSecurityConfigurerAdapter` se eliminó en Security 6, y `antMatchers`, `mvcMatchers` y
> `authorizeRequests` con él. Hoy se declara un `@Bean SecurityFilterChain`, todo es
> `requestMatchers` y `authorizeHttpRequests`, y en Security 7 el estilo lambda es la única API
> que compila.

**`spring.factories`.** Hasta 2.7 el catálogo de autoconfiguraciones vivía en
`META-INF/spring.factories` bajo la clave `EnableAutoConfiguration`. Desde 3.0 vive en
`META-INF/spring/org.springframework.boot.autoconfigure.AutoConfiguration.imports`, una línea
por clase. Es el detalle de [`06` §4](06-arranque-y-autoconfiguracion.md#4--dónde-vive-el-catálogo-de-autoconfiguraciones)
y solo te afecta si **publicas** una autoconfiguración propia, que en banca pasa más de lo que
parece: casi toda plataforma interna tiene su starter corporativo.

> **📝 El orden correcto, y no es negociable.** No se salta de 2.7 a 4.x en un paso. La guía
> oficial de migración a 4.0 abre diciendo que primero hay que estar en la última 3.5.x y haber
> resuelto las deprecaciones. Dos saltos, dos despliegues, dos rondas de pruebas.

---

## 15. 📋 Checklist de migración de un servicio real

El orden importa y sale de la guía oficial de migración de Boot 4.0, no de la intuición. Cada
línea es verificable; ninguna es "revisar que todo esté bien".

- [ ] Estás en la **última 3.5.x** y `./mvnw -q verify` pasa en verde antes de tocar nada.
- [ ] El build no emite warnings de deprecación: `./mvnw -q clean test -Dmaven.compiler.showDeprecation=true` sale limpio.
- [ ] El JDK cumple el mínimo de la §4 (`java -version` ≥ 17; el curso usa 21).
- [ ] Las dependencias **fuera del BOM** —Resilience4j, springdoc, Redisson— tienen versión compatible con Framework 7 verificada en su propia documentación.
- [ ] Subes la versión del parent a la 4.x elegida y **el build falla**: eso es lo esperado, y es donde empieza el trabajo.
- [ ] Añades `spring-boot-properties-migrator` en `runtime` y arrancas; anotas cada WARN (§12).
- [ ] Cambias los starters: `web` → `webmvc`, los `-test` por módulo, los `oauth2` con prefijo `security-` (§5).
- [ ] `./mvnw dependency:tree` no lista ningún `spring-boot-starter-*` deprecado ([`A01` §5](a01-cli-y-tooling-de-supervivencia.md#5--el-árbol-de-dependencias-y-un-conflicto-real)).
- [ ] Arreglas los imports de test de la §10 y **compruebas que cada slice sigue aplicándose**: un `@WebMvcTest` que levanta el contexto completo se ve en el tiempo de arranque del log.
- [ ] Los `@SpringBootTest` que inyectan `MockMvc` o `TestRestTemplate` llevan ya su `@AutoConfigure*` (§10).
- [ ] Jackson: `ObjectMapper`, módulos y `catch` de excepciones de binding migrados; los `@JsonProperty` **no se tocan** (§6).
- [ ] Security: ninguna `@Configuration` usa `.and()` ni `@EnableGlobalMethodSecurity`; los tests con `@WithMockUser` tienen `spring-boot-starter-security-test` (§7).
- [ ] Batch: `@EnableJdbcJobRepository` añadido; `JobLauncher` y `JobExplorer` sustituidos por `JobOperator` y `JobRepository` (§8).
- [ ] `management.tracing.export.enabled` en el `yml`, y el `traceId` sigue apareciendo en el log (§9).
- [ ] Mongo: `spring.mongodb.uri` para la conexión, `spring.data.mongodb.*` solo para lo de Spring Data (§11).
- [ ] Arranca sin un solo WARN del migrator, y **entonces** quitas el migrator del `pom.xml`.
- [ ] `/actuator/health` responde `UP`, `/actuator/env` muestra las claves nuevas y las métricas siguen saliendo con los mismos nombres ([`23`](23-actuator-y-observabilidad.md)).
- [ ] Si usaste `spring-boot-starter-classic`, queda registrado como **deuda con fecha**, no como final de la migración.

---

## 16. ⚠️ Errores frecuentes al contar esta migración

- **"Boot 4 exige Java 21."** Exige **17** — el bytecode de `spring-core-7.0.9` es `major
  version: 61` (§4). Que el curso fije 21 es una decisión del curso, por los virtual threads de
  [`12`](12-reactivo-bloqueante-y-virtual-threads.md), no un requisito del framework.
- **"`spring-boot-starter-web` se eliminó."** Está **deprecado** en favor de
  `spring-boot-starter-webmvc`, y sigue resolviendo (§5). La diferencia importa: lo primero es
  un build roto, lo segundo un build con deuda.
- **"Jackson 3 te cambia todos los imports."** Cambia los de infraestructura; las anotaciones
  siguen en `com.fasterxml.jackson.annotation` porque el BOM de Jackson 3 las gestiona bajo el
  `groupId` viejo (§6).
- **"`@MockBean` está deprecada."** En 3.5 lo estaba; en 4.x **ya no existe** (§10). Quien
  siguió [`24` §5](24-testing.md#5--mockitobean-y-mockitospybean-sustituir-un-bean-no-un-objeto)
  no tiene nada que hacer aquí, que es justo por lo que el curso lo marcó.
- **"Migro de 2.7 a 4.x directamente."** La guía oficial de 4.0 pide pasar primero por la última
  3.5.x (§14). Saltarse el escalón mezcla el renombre de `javax` con el de starters y con el de
  Jackson, y ya no sabes qué rompió qué.
- **"El properties-migrator me dice todo lo que tengo que cambiar."** Solo ve lo declarado en los
  metadatos (§12). Lo que cambió de significado sin cambiar de nombre no aparece.
- **"Estoy en 3.5, que está fuera de soporte, así que es urgente."** Fuera de soporte **OSS**.
  Con soporte comercial llega a **2032** por ser la última minor de la major 3 (§2). La urgencia
  depende de si tu organización lo paga, y esa es la pregunta que hay que hacer.

---

## 🧠 Preguntas rápidas

1. ¿Por qué Spring Boot 3.5 tiene soporte comercial hasta 2032 y Boot 4.0 solo hasta 2027, si
   3.5 es la versión más vieja de las dos?
2. "Spring Boot 4 exige Java 21": corrige la afirmación y di con qué comando lo comprobarías sin
   abrir la documentación.
3. ¿Qué diferencia práctica hay entre que `spring-boot-starter-web` esté **deprecado** y que
   estuviera **eliminado**, para alguien que acaba de subir la versión del parent?
4. Migras a Jackson 3 y tu `record ItemResponse` está lleno de `@JsonProperty`. ¿Cuántos de esos
   imports tienes que tocar, y por qué?
5. Tu `catch (JsonMappingException e)` deja de compilar en 4.x. ¿Qué tipo lo sustituye y en qué
   paquete vive?
6. ¿Qué significa exactamente que una deprecación de propiedad tenga `"level": "error"` en el
   `spring-configuration-metadata.json`, frente a `"level": "warning"`?
7. Renombras `management.tracing.enabled` a `management.tracing.export.enabled` y lo pones en
   `false`. ¿Sigue habiendo `traceId` en tus líneas de log? ¿Por qué?
8. En Spring Batch 6, `@EnableBatchProcessing` ya no basta. ¿Qué anotación hay que acompañarla y
   qué decisión representa?
9. `JobLauncher` y `JobExplorer` siguen en el jar de Batch 6. ¿Significa eso que puedes seguir
   usándolos, y qué clase absorbe a cada uno?
10. Tu suite sigue verde después de migrar a 4.x, pero sospechas de los tests. ¿Cuál es el fallo
    silencioso más probable y en qué parte del log lo confirmas?
11. Un compañero propone correr OpenRewrite y dar la migración por hecha. Nombra dos cosas
    concretas de este apéndice que la herramienta no resuelve.
12. Estás migrando un servicio de Boot 2.7. ¿Por qué no se salta directo a 4.x, y cuáles son los
    dos saltos?

---

## 🧪 Ejercicios (12)

Todos usan el proyecto `inv-api` del laboratorio y una rama aparte: `git switch -c migracion-4x`.
Ninguno se hace sobre `master`, porque varios dejan el build roto a propósito.

### 🟢 Fácil — leer las fuentes con tus propias manos  (1–4)

#### 🟢 Ejercicio 1 — Reconstruye la tabla de la §3

Corre el bucle de la [§3](#3--el-salto-columna-por-columna) contra `3.5.16` y contra la última
versión que devuelva el comando de la [§1](#1--cómo-se-usa-este-apéndice-y-por-qué-caduca-antes-que-los-demás),
y pega las dos salidas lado a lado.

**Objetivo:** que la tabla de versiones deje de ser algo que te creíste y pase a ser algo que
sacaste. **Pregunta:** ¿alguna fila difiere de lo que dice este apéndice? Si sí, el apéndice está
caducado y ya sabes por dónde.

#### 🟢 Ejercicio 2 — La deprecación, en su fichero

Descarga `spring-boot-micrometer-tracing` de la última 4.x y extrae de su
`spring-configuration-metadata.json` **todas** las propiedades con `"deprecated": true`, no solo
`management.tracing.enabled`.

**Objetivo:** saber dónde vive la verdad sobre una propiedad deprecada, que es el mismo sitio del
que la lee tu IDE. **Pregunta:** ¿cuántas hay de nivel `error` y cuántas de nivel `warning`?

#### 🟢 Ejercicio 3 — Dos starters, cinco dependencias

Descarga los POM de `spring-boot-starter-web` y `spring-boot-starter-webmvc` de la misma versión
4.x y `diff` sus bloques `<dependencies>`.

**Objetivo:** comprobar con el artefacto delante que el renombre no cambia lo que arrastra.
**Pregunta:** si son equivalentes, ¿por qué se molestaron en renombrarlo?

#### 🟢 Ejercicio 4 — ¿Existe todavía?

Escribe un script de una línea que, dada una versión de Boot y un nombre de clase, diga si esa
clase sigue en el jar. Pruébalo con `MockBean`, `SpyBean` y `SpringBootTest` sobre `3.5.16` y
sobre `4.1.1`.

**Objetivo:** tener en los dedos la comprobación "¿esto todavía existe?" sin depender del
javadoc. **Pregunta:** ¿cuál de las tres sobrevive y por qué tiene sentido que sea esa?

### 🟡 Intermedio — aplicarlo a `inv-api`  (5–8)

#### 🟡 Ejercicio 5 — El migrator, sobre tu `application.yml`

Sin cambiar de versión todavía, añade `spring-boot-properties-migrator` con scope `runtime` al
`pom.xml` de `inv-api`, arranca con el perfil `local` y filtra el log por `deprecated`.

**Objetivo:** ver qué te diría la herramienta **antes** de migrar, que es el momento en que más
barato sale. **Pregunta:** ¿salió algo? Si no salió nada, ¿qué demuestra eso y qué no?

#### 🟡 Ejercicio 6 — Rompe el build a propósito

Sube el `<parent>` de `inv-api` a la 4.x y corre `./mvnw -q clean test`. **No arregles nada
todavía**: guarda la salida completa en `migracion-4x-errores.txt`.

**Objetivo:** ver el inventario real del trabajo, que casi nunca coincide con el que uno
imaginaba. **Pregunta:** ¿cuántos de los errores son de dependencia no resuelta y cuántos de
import roto? Son trabajos distintos.

#### 🟡 Ejercicio 7 — Los starters, uno por uno

Partiendo del estado del ejercicio 6, cambia solo los starters (§5) y vuelve a correr
`./mvnw -q clean test`. `diff` la salida contra `migracion-4x-errores.txt`.

**Objetivo:** medir cuánto del problema era el `pom.xml` y cuánto es el código. **Pregunta:**
¿desapareció algún error que no esperabas, y por qué ese starter lo arrastraba?

#### 🟡 Ejercicio 8 — El renombre de la propiedad, con su efecto

En el `inv-api` migrado, pon `management.tracing.export.enabled=false` y comprueba con un `curl`
al endpoint de [`L07`](l07-actuator-metricas-y-trazas.md) si las líneas de log siguen llevando
`traceId`. Repite con `management.tracing.enabled=false` y compara.

**Objetivo:** entender en la práctica la separación entre instrumentar y exportar.
**Pregunta:** ¿cuál de las dos claves no hizo absolutamente nada, y dónde lo confirmarías?

### 🟠 Difícil — donde el fallo es silencioso  (9–11)

#### 🟠 Ejercicio 9 — El test que pasa sin probar nada

En el `inv-api` migrado, quita `spring-boot-starter-webmvc-test` del `pom.xml` dejando solo
`spring-boot-starter-test`, y corre la clase de test con `@WebMvcTest`. Anota qué pasa y cuánto
tarda.

**Objetivo:** reconocer el fallo más peligroso de esta migración, que es un test verde.
**Pregunta:** ¿en qué línea concreta del log de arranque del test se ve que el slice no se
aplicó?

#### 🟠 Ejercicio 10 — OpenRewrite en `dryRun`, y su diff revisado

Corre la recipe `UpgradeSpringBoot_4_0` en modo `dryRun` sobre `inv-api` y lee el
`rewrite.patch` entero. Marca cada hunk como *lo habría hecho igual*, *lo habría hecho distinto*
o *esto está mal*.

**Objetivo:** usar la herramienta como lo que es —un colega rápido y sin criterio— y no como un
oráculo. **Pregunta:** ¿hay algún hunk que la recipe hizo y que tú habrías dejado para una
decisión de equipo?

#### 🟠 Ejercicio 11 — El salto de Batch, con el job corriendo

Migra la configuración de Batch de [`L08`](l08-security-y-batch.md) a Batch 6:
`@EnableJdbcJobRepository`, `JobOperator` en vez de `JobLauncher`, `JobRepository` en vez de
`JobExplorer`. Lanza `inventory-reconciliation-job` dos veces con los mismos `JobParameters`.

**Objetivo:** comprobar que la identidad de la `JobInstance` de
[`22` §5](22-spring-batch.md#5--jobparameters-por-qué-no-puedes-relanzar-lo-mismo-dos-veces)
sobrevive intacta al cambio de major. **Pregunta:** ¿la segunda ejecución falló con la misma
excepción que en Batch 5?

### 🔴 Muy difícil — decidir, no solo teclear  (12)

#### 🔴 Ejercicio 12 — El informe que defiende una línea

Te dan un servicio de banca en **Boot 2.7** con soporte comercial vigente, cuarenta endpoints,
un job de Batch nocturno y una librería interna de auditoría que solo existe compilada contra
`javax.servlet`. Escribe un informe de una página que recomiende **una** de estas tres: quedarse
en 2.7, saltar a 3.5 o saltar a 4.1, con el calendario de la §2 como argumento y el coste de
cada obstáculo nombrado.

**Objetivo:** poder sostener en voz alta una recomendación de versión con fechas, no con
preferencias. **Pregunta:** ¿cuál de los tres obstáculos —`javax`, el Batch o los tests— decide
la respuesta, y qué pasaría si la librería de auditoría sacara versión Jakarta el mes que viene?

### 🔥 Opcionales y ampliaciones

- Reconstruye la tabla de soporte de la §2 para **Spring Security** y para **Spring Batch**
  usando `api.spring.io`, y comprueba si sus fechas se alinean con las de Boot o no.
- Monta un `inv-api` mínimo con `spring-boot-starter-classic` y mide con
  `./mvnw dependency:tree` cuántos artefactos arrastra de más frente al modular.
- Busca en el `spring-configuration-metadata.json` de **todos** los módulos de Boot 4 del
  classpath las deprecaciones de nivel `error` y arma tu propia tabla de renombres.

### 💀 Boss fight — `inv-api` en 4.x, verde y sin deuda oculta

Lleva `inv-api` entero a la última 4.x con todo lo que el laboratorio dejó en pie: la API REST de
[`L03`](l03-api-rest-filtros-y-errores.md), los datos y transacciones de
[`L04`](l04-datos-y-transacciones.md), los clientes y la resiliencia de
[`L05`](l05-clientes-y-resiliencia.md), la caché y la asincronía de
[`L06`](l06-cache-y-asincronia.md), la observabilidad de [`L07`](l07-actuator-metricas-y-trazas.md)
y el Security y el Batch de [`L08`](l08-security-y-batch.md).

Se entrega como **una rama y un documento**. La rama cumple:

- `./mvnw -q verify` pasa, y `docker compose ps` levanta los mismos servicios que antes;
- el `pom.xml` no tiene ningún starter deprecado ni ningún `*-classic`;
- arranca sin un solo WARN del properties-migrator, y el migrator **no** está en el `pom.xml`
  final;
- cada test que usa un slice sigue usándolo: lo demuestras con el tiempo de arranque de cada
  clase de test, antes y después;
- el `traceId` sigue en el log y `/actuator/prometheus` publica las mismas métricas con los
  mismos nombres.

El documento recorre el checklist de la [§15](#15--checklist-de-migración-de-un-servicio-real)
marcando qué hiciste tú, qué hizo la herramienta y **qué decidiste no hacer, con su razón**.

**Objetivo:** haber hecho una vez, entera y sobre código que entiendes, la migración que en el
trabajo te va a tocar sobre código que no escribiste. **Pregunta:** ¿cuál de las dieciocho líneas
del checklist te costó más, y era la que esperabas?

---

## 📚 Referencias oficiales

> **Excepción declarada de §10.2.** A diferencia del resto del curso, **estos enlaces apuntan a
> la línea 4.x**, no al baseline 3.5.16. Las URL de `docs.spring.io` sin número de versión sirven
> la línea actual, que hoy es **4.1**; es exactamente lo que este apéndice quiere. Las rutas con
> `/4.0/` son las de la línea ya archivada y responden `200` directo. Todos se verificaron por
> código de estado el 19 de septiembre de 2026, siguiendo redirecciones con `-L` y escribiendo la
> URL final. Una excepción de método: **`api.spring.io` responde `200` a un `GET` y `401` a un
> `HEAD`**, así que la verificación con `curl -I` de §10.2 la reporta como caída y no lo está.
> Ese enlace se comprueba con `curl -s -o /dev/null -w '%{http_code}'` sin `-I`.

**La fuente principal de este apéndice**

- Guía de migración a Spring Boot 4.0: https://github.com/spring-projects/spring-boot/wiki/Spring-Boot-4.0-Migration-Guide
- Release notes de Spring Boot 4.0: https://github.com/spring-projects/spring-boot/wiki/Spring-Boot-4.0-Release-Notes
- Release notes de Spring Boot 4.1: https://github.com/spring-projects/spring-boot/wiki/Spring-Boot-4.1-Release-Notes
- Guía de migración a Spring Boot 3.0 (la de la §14): https://github.com/spring-projects/spring-boot/wiki/Spring-Boot-3.0-Migration-Guide
- Calendario de soporte, como JSON: https://api.spring.io/projects/spring-boot/generations
- Página del proyecto y su política de soporte: https://spring.io/projects/spring-boot/

**Referencia de la línea 4.x**

- Starters y sistema de build: https://docs.spring.io/spring-boot/reference/using/build-systems.html
- Autoconfiguración: https://docs.spring.io/spring-boot/reference/using/auto-configuration.html
- Índice de propiedades de configuración: https://docs.spring.io/spring-boot/appendix/application-properties/index.html
- Trazas en Actuator: https://docs.spring.io/spring-boot/reference/actuator/tracing.html
- JSON y Jackson en Boot: https://docs.spring.io/spring-boot/reference/features/json.html
- Testing de aplicaciones Spring Boot: https://docs.spring.io/spring-boot/reference/testing/spring-boot-applications.html
- Sustituir beans en un test: https://docs.spring.io/spring-boot/reference/testing/spring-boot-applications.html#testing.spring-boot-applications.mocking-beans
- Datos NoSQL (las propiedades de Mongo de la §11): https://docs.spring.io/spring-boot/reference/data/nosql.html
- Clientes REST: https://docs.spring.io/spring-boot/reference/io/rest-client.html
- Propiedades y configuración, en las how-to: https://docs.spring.io/spring-boot/how-to/properties-and-configuration.html
- Trazas en la línea 4.0 ya archivada, para comparar: https://docs.spring.io/spring-boot/4.0/reference/actuator/tracing.html

**Spring Framework 7, Security 7 y Batch 6**

- Versionado de API en `@RequestMapping`: https://docs.spring.io/spring-framework/reference/web/webmvc/mvc-controller/ann-requestmapping.html#mvc-ann-requestmapping-version
- Configurar el versionado de API: https://docs.spring.io/spring-framework/reference/web/webmvc/mvc-config/api-version.html
- Clientes REST y HTTP Interfaces: https://docs.spring.io/spring-framework/reference/integration/rest-clients.html
- `HttpMessageConverter` y converters: https://docs.spring.io/spring-framework/reference/web/webmvc/mvc-config/message-converters.html
- Guía de migración de Spring Security: https://docs.spring.io/spring-security/reference/migration/index.html
- Autorización HTTP en Security: https://docs.spring.io/spring-security/reference/servlet/authorization/authorize-http-requests.html
- Novedades de Spring Batch 6: https://docs.spring.io/spring-batch/reference/whatsnew.html
- El `Job` en Spring Batch: https://docs.spring.io/spring-batch/reference/job.html
- Guía de migración de Spring Batch 6: https://github.com/spring-projects/spring-batch/wiki/Spring-Batch-6.0-Migration-Guide

### Documentación de terceros

- Release de Jackson 3.0: https://github.com/FasterXML/jackson/wiki/Jackson-Release-3.0
- Recipes de OpenRewrite para Spring Boot 4: https://docs.openrewrite.org/recipes/java/spring/boot4
- Documentación de OpenRewrite: https://docs.openrewrite.org/
