# 06 — Arranque de Spring Boot y autoconfiguración

> **Objetivo:** saber por qué existe un bean que tú no declaraste, poder demostrarlo con
> un comando, y quitarlo cuando estorbe.
> **Asume:** [`02`](02-contenedor-ioc-y-ciclo-de-vida.md), [`03`](03-inyeccion-de-dependencias.md).
> **Vigencia:** 17 de septiembre de 2026 · Spring Boot 3.5.16 · Spring Framework 6.2.19 · Java 21.

---

## 1. 🧭 El problema: doscientas líneas antes del primer endpoint

Una aplicación Spring sin Boot necesita, para atender un `GET`, que alguien declare un
`DispatcherServlet`, lo registre en el contenedor de servlets, configure los
`HttpMessageConverter`, cree un `ObjectMapper` con los módulos de fechas, monte el
`DataSource` con su pool, ate el `TransactionManager` al `EntityManagerFactory`… y todo
eso son beans que escribes tú, en el orden correcto, con las versiones correctas.

Nada de eso es una decisión interesante. Es exactamente la misma configuración en el 95 %
de los proyectos, y equivocarse produce errores que no enseñan nada.

La idea de Boot es simple de enunciar: **si en el classpath hay un driver JDBC y una
propiedad `spring.datasource.url`, seguramente quieres un `DataSource`**. Así que lo
declara por ti — y se aparta en cuanto tú declaras el tuyo.

> **🧠 Modelo mental.** La autoconfiguración no adivina nada: son **clases de
> configuración normales, con condiciones**. Todo el mecanismo es `@Conditional` bien
> usado sobre bean definitions ([`02`](02-contenedor-ioc-y-ciclo-de-vida.md)), y por eso se puede inspeccionar, ordenar y
> desactivar.

---

## 2. 🧱 `SpringApplication.run()`, paso a paso

```java
@SpringBootApplication
public class InvApiApplication {
    public static void main(String[] args) {
        SpringApplication.run(InvApiApplication.class, args);
    }
}
```

Detrás de esa línea pasa esto, en orden:

```text
1. Deducir el tipo de aplicación      ¿hay spring-webmvc? → SERVLET
                                      ¿solo webflux?      → REACTIVE
                                      ¿ninguno?           → NONE (app de consola)
2. Cargar ApplicationContextInitializer y ApplicationListener
3. Preparar el Environment            argumentos, variables, application.yml, profiles
4. Crear el ApplicationContext        del tipo deducido en el paso 1
5. Registrar bean definitions         tus @Component + las autoconfiguraciones
6. refresh()                          ← aquí ocurre todo el ciclo de vida de 02
7. Arrancar el servidor embebido
8. Ejecutar ApplicationRunner / CommandLineRunner
9. ApplicationReadyEvent
```

- **El tipo de aplicación se deduce del classpath**, y decide qué contexto se crea. Tener
  `spring-webmvc` y `spring-webflux` a la vez gana el servlet, que es una de las sorpresas
  más comunes al añadir `WebClient` a una aplicación MVC ([`13`](13-clientes-http.md)).
- **El `Environment` se prepara antes del contexto** (paso 3). Por eso los profiles y las
  propiedades pueden condicionar qué beans se registran: cuando se evalúan las
  condiciones, la configuración ya está resuelta.
- **Los eventos del ciclo** —de `ApplicationStartingEvent` a `ApplicationReadyEvent`, con
  `ApplicationFailedEvent` si algo revienta— son puntos de enganche reales.
  `ApplicationReadyEvent` es el sitio correcto para el trabajo que necesita la aplicación
  entera en pie, proxies incluidos ([`05`](05-proxies-y-aop.md)).

> **⏱️ Costo en runtime.** El arranque se mide en **segundos**, y el número no se estima:
> lo imprime el propio log al terminar el paso 9, en la línea `Started InvApiApplication
> in <n> seconds (process running for <n>)`. Para repartir esos segundos **por paso**, en
> milisegundos, se instrumenta el arranque llamando a
> `setApplicationStartup(new BufferingApplicationStartup(2048))` sobre la
> `SpringApplication` antes de `run()`, y se lee el desglose con
> `curl -s localhost:8080/actuator/startup | jq '.timeline.events'`,
> con `management.endpoints.web.exposure.include=startup` ([`23`](23-actuator-y-observabilidad.md)).

---

## 3. 🧱 `@SpringBootApplication` son tres anotaciones

```text
@SpringBootApplication
 ├── @SpringBootConfiguration   una @Configuration, marcada como "la principal"
 ├── @EnableAutoConfiguration   activa el mecanismo de este capítulo
 └── @ComponentScan             escanea desde este paquete hacia abajo (02 §7)
```

- **`@SpringBootConfiguration`** es lo que buscan los tests para localizar la clase de
  arranque: por eso `@SpringBootTest` encuentra tu configuración sin que se la digas
  ([`24` §3](24-testing.md#3--springboottest-y-sus-cuatro-webenvironment)), y por eso **solo debe haber una** en el subárbol.
- **Separarlas** es legítimo cuando necesitas control fino —por ejemplo, un
  `@ComponentScan` con filtros—, y entonces se escriben las tres a mano.

---

## 4. 🧱 Dónde vive el catálogo de autoconfiguraciones

Cada jar que quiera aportar autoconfiguración declara sus clases en un fichero de texto:

```text
META-INF/spring/org.springframework.boot.autoconfigure.AutoConfiguration.imports
```

```text
org.springframework.boot.autoconfigure.jdbc.DataSourceAutoConfiguration
org.springframework.boot.autoconfigure.web.servlet.DispatcherServletAutoConfiguration
org.springframework.boot.autoconfigure.jackson.JacksonAutoConfiguration
```

- **Una clase por línea**, con su nombre completamente cualificado. `@EnableAutoConfiguration`
  lee todos esos ficheros del classpath y registra lo que encuentra.
- **Son `@Configuration` normales**: las puedes abrir en el IDE y leerlas. Hacerlo una vez
  —abrir `DataSourceAutoConfiguration` y ver que son sesenta líneas con condiciones— es la
  forma más rápida de que la autoconfiguración deje de parecer magia.

> **📝 Contexto.** Hasta Boot 2.7 el catálogo vivía en `META-INF/spring.factories`, bajo la
> clave `EnableAutoConfiguration`. Ese formato quedó obsoleto en 2.7 y **se eliminó en
> 3.0**: si sigues un tutorial viejo para escribir un starter propio, la autoconfiguración
> simplemente no se cargará y no habrá ningún error que lo explique. Es uno de los puntos
> de la migración 2.7 → 3.x que más tiempo hace perder ([`A04` §14](a04-migracion-3-5-a-4-x.md#14--la-migración-27--3x-que-es-la-que-todavía-te-van-a-preguntar)).

---

## 5. 🧱 Las condiciones

La familia `@ConditionalOn*` es lo que decide si una autoconfiguración aplica:

| Condición | Se cumple cuando | Uso típico |
|---|---|---|
| `@ConditionalOnClass` | la clase está en el classpath | "si hay un driver JDBC…" |
| `@ConditionalOnMissingClass` | no está | alternativas excluyentes |
| `@ConditionalOnBean` | ya existe un bean de ese tipo | encadenar configuración |
| `@ConditionalOnMissingBean` | **no** existe | "…y tú no declaraste el tuyo" |
| `@ConditionalOnProperty` | una propiedad tiene cierto valor | activar por configuración |
| `@ConditionalOnWebApplication` | el contexto es web (servlet o reactive) | beans de web |
| `@ConditionalOnResource` | existe un fichero en el classpath | configuración por convención |

La pieza clave es la cuarta:

```java
@AutoConfiguration
@ConditionalOnClass(DataSource.class)
class DataSourceAutoConfiguration {

    @Bean
    @ConditionalOnMissingBean          // si tú declaras un DataSource, esto no se registra
    DataSource dataSource(DataSourceProperties properties) { … }
}
```

> **🧠 Modelo mental, y es la respuesta a media docena de preguntas de entrevista:**
> **tu bean siempre gana.** La autoconfiguración se declara "por si acaso": en cuanto
> existe un bean tuyo del mismo tipo, la condición falla y la de Boot no se registra. No
> hay que desactivar nada.

**El orden importa**, porque `@ConditionalOnBean` depende de qué se haya registrado antes:

- **`@AutoConfiguration(after = …, before = …)`** ordena las autoconfiguraciones entre sí.
- **Las autoconfiguraciones se procesan después de tus propias `@Configuration`**, que es
  precisamente lo que hace que `@ConditionalOnMissingBean` funcione a tu favor.
- **`@ConditionalOnBean` en tu propio código es frágil** por eso mismo: depende de un
  orden que no controlas. En tu configuración, prefiere condiciones sobre clase o sobre
  propiedad.

---

## 6. 🩺 El informe de condiciones: por qué existe ese bean

Esta es la herramienta que convierte "Boot hace magia" en "Boot tomó esta decisión por
este motivo". Hay dos formas de verla:

```bash
./mvnw spring-boot:run -Dspring-boot.run.arguments=--debug
```

- **`--debug`** no sube el nivel de log de todo: activa el **`ConditionEvaluationReport`**
  y lo imprime al arrancar. Es distinto de `--trace` y de `logging.level.root=DEBUG`.
- **`-Dspring-boot.run.arguments=`** pasa argumentos a la aplicación, no a Maven ni a la
  JVM. Es la propiedad que más se confunde con `-Dspring-boot.run.jvmArguments`.

La salida tiene tres bloques, y el segundo es el que se lee de verdad:

```text
Positive matches:
-----------------
   DataSourceAutoConfiguration matched:
      - @ConditionalOnClass found required class 'javax.sql.DataSource'

Negative matches:
-----------------
   RedisAutoConfiguration:
      Did not match:
         - @ConditionalOnClass did not find required class
           'org.springframework.data.redis.core.RedisOperations'

Exclusions:
-----------
   org.springframework.boot.autoconfigure.security.servlet.SecurityAutoConfiguration
```

- **`Positive matches`**: qué se aplicó y por qué. Aquí encuentras el bean que "apareció
  solo".
- **`Negative matches`**: qué **no** se aplicó y **qué condición falló**. Es el bloque más
  útil del informe, porque responde a la pregunta contraria —"¿por qué *no* tengo ese
  bean?"— que suele ser la que te tiene atascado.
- **`Exclusions`**: lo que alguien desactivó explícitamente.

> **💡 Truco.** El mismo informe está disponible en caliente en `/actuator/conditions`
> ([`23` §6](23-actuator-y-observabilidad.md#6--el-resto-del-catálogo-qué-pregunta-contesta-cada-endpoint)), en JSON, que es más cómodo para filtrar con `jq`. Se practica en
> [`L01`](l01-esqueleto-cli-y-autoconfiguracion.md).

---

## 7. 🧱 Desactivar una autoconfiguración

Tres formas, equivalentes en efecto y distintas en alcance:

```java
@SpringBootApplication(exclude = SecurityAutoConfiguration.class)
```

```properties
spring.autoconfigure.exclude=org.springframework.boot.autoconfigure.security.servlet.SecurityAutoConfiguration
```

- **`exclude`** con la clase es lo habitual y el IDE lo verifica; **`excludeName`** acepta
  el nombre como cadena, para cuando la clase no está en tu classpath de compilación.
- **La propiedad `spring.autoconfigure.exclude`** permite excluir por entorno, lo que es
  útil y peligroso a partes iguales: una exclusión activa solo en un profile es una
  diferencia de comportamiento entre entornos que nadie ve al leer el código.

> **⚠️ Excluir es casi siempre la segunda mejor respuesta.** Si lo que quieres es cambiar
> cómo se configura algo, declara tu propio bean y deja que `@ConditionalOnMissingBean`
> haga su trabajo. La exclusión es para cuando quieres que **no exista nada**, que es un
> caso mucho más raro.

---

## 8. 🧱 Escribir tu propia autoconfiguración

En un banco con veinte microservicios, esto deja de ser curiosidad y pasa a ser trabajo de
tech lead: una librería interna que aporte el cliente HTTP corporativo, el filtro de
auditoría y la configuración de trazas, sin que cada equipo copie y pegue.

```java
@AutoConfiguration
@ConditionalOnClass(RestClient.class)
@EnableConfigurationProperties(AuditProperties.class)
public class AuditAutoConfiguration {

    @Bean
    @ConditionalOnMissingBean                       // el equipo consumidor puede sustituirlo
    @ConditionalOnProperty(prefix = "invlab.audit", name = "enabled",
                           havingValue = "true", matchIfMissing = true)
    AuditFilter auditFilter(AuditProperties properties) {
        return new AuditFilter(properties);
    }
}
```

- **`@AutoConfiguration`** (Boot 3+) sustituye a `@Configuration` en estas clases y añade
  la semántica de orden (`after` / `before`).
- **`matchIfMissing = true`** hace que la funcionalidad esté activa por defecto y se pueda
  apagar. Para algo como una auditoría obligatoria, la decisión contraria —desactivada
  salvo que se pida— sería un error de diseño.
- **Hay que declarar la clase en `AutoConfiguration.imports`**, o no se carga. Es el paso
  que todo el mundo olvida, y no produce ningún error.
- **La clase no se marca con `@Component` ni se escanea**: se carga por el catálogo, que
  es lo que permite que viva en un jar fuera del paquete base del consumidor
  ([`02` §7](02-contenedor-ioc-y-ciclo-de-vida.md#7--component-scan-el-paquete-base)).

---

## 9. 🧱 Código que corre al arrancar

```java
@Component
class SeedRunner implements ApplicationRunner {

    private final InventoryService service;

    SeedRunner(InventoryService service) { this.service = service; }

    @Override
    public void run(ApplicationArguments args) {
        // el contexto ya está completo: aquí sí hay proxies, y una transacción funciona
        if (args.containsOption("seed")) service.seed();
    }
}
```

- **`ApplicationRunner`** recibe los argumentos ya parseados (`--seed=true` es una
  opción); `CommandLineRunner` recibe el `String[]` crudo, y la primera es casi siempre
  mejor. Los dos **bloquean el arranque**: un runner de treinta segundos puede hacer que
  tu orquestador te mate antes de terminar.
- **Este es el lugar correcto para el trabajo transaccional de arranque**, no
  `@PostConstruct`, porque aquí el bean que recibes ya es el proxy (`05`).

---

## 10. 🩺 Cuando el arranque falla

Boot traduce los fallos conocidos con un `FailureAnalyzer`:

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

- **El bloque `Action:` es la parte que la gente no lee**, y suele contener la respuesta:
  cuando aparece, no hace falta ir al stack trace. Si no hay analizador para tu fallo, sale
  el stack trace completo, y ahí lo que vale es la última excepción de la cadena de
  `Caused by` ([`A01`](a01-cli-y-tooling-de-supervivencia.md)).
- **Puedes escribir el tuyo** implementando `FailureAnalyzer` y declarándolo en
  `AutoConfiguration.imports`; en una librería corporativa es una cortesía enorme.

---

## 11. ⚠️ Errores frecuentes

- **"Boot adivina lo que necesitas."** Evalúa condiciones sobre el classpath y las
  propiedades. Es determinista y auditable con `--debug`.
- **"La autoconfiguración hace el arranque lento porque carga todo."** Evalúa condiciones,
  que es barato; lo que cuesta es el número de beans que **sí** se registran. Se mide con
  el desglose de `ApplicationStartup` (§2), no se supone.
- **"Para cambiar la configuración de Boot hay que excluir su autoconfiguración."** Casi
  nunca: declara tu bean y `@ConditionalOnMissingBean` se aparta.
- **"Mi autoconfiguración no se carga y no sé por qué."** El 90 % de las veces falta la
  línea en `AutoConfiguration.imports`, o está en `spring.factories`, que ya no se lee.
- **"`--debug` sube el nivel de log."** Activa el informe de condiciones. No es lo mismo
  que `logging.level.root=DEBUG`.

---

## 🧠 Preguntas rápidas

1. ¿Cómo decide `SpringApplication` si crea un contexto servlet, uno reactivo o ninguno?
2. ¿Por qué el `Environment` se prepara antes de registrar los beans, y qué permite eso?
3. ¿En qué tres anotaciones se descompone `@SpringBootApplication`, y para qué sirve la
   que nadie nombra?
4. ¿Dónde declara un jar sus clases de autoconfiguración en Boot 3.5, y dónde se declaraban
   antes?
5. Explica por qué "tu bean siempre gana" y qué anotación concreta lo hace posible.
6. ¿Por qué `@ConditionalOnBean` es frágil en tu propio código y no en el de Boot?
7. "`--debug` sube el nivel de log": corrige la frase. ¿Qué imprime exactamente, y qué
   bloque de esa salida usarías para saber por qué **no** tienes un bean que esperabas?
8. Nombra las tres formas de excluir una autoconfiguración y di por qué excluir suele ser
   la segunda mejor respuesta.
9. Escribes una autoconfiguración en una librería interna y no se aplica. ¿Cuáles son las
   dos causas más probables?
10. ¿Qué diferencia hay entre `ApplicationRunner` y `CommandLineRunner`, y qué riesgo tiene
    un runner lento?
11. ¿Por qué el trabajo transaccional de arranque va en un `ApplicationRunner` y no en un
    `@PostConstruct`?
12. Tu aplicación falla al arrancar con un mensaje que incluye `Action:`. ¿Qué es eso,
    quién lo produce y qué haces si no aparece?

---

## 📚 Referencias oficiales

- Spring Boot 3.5 — Auto-configuration: https://docs.spring.io/spring-boot/3.5/reference/using/auto-configuration.html
- Spring Boot 3.5 — Crear tu propia autoconfiguración: https://docs.spring.io/spring-boot/3.5/reference/features/developing-auto-configuration.html
- Spring Boot 3.5 — `SpringApplication` y eventos del ciclo: https://docs.spring.io/spring-boot/3.5/reference/features/spring-application.html
- Spring Boot 3.5 — Catálogo de clases de autoconfiguración: https://docs.spring.io/spring-boot/3.5/appendix/auto-configuration-classes/index.html
- Spring Boot 3.5 — How-to de arranque y diagnóstico: https://docs.spring.io/spring-boot/3.5/how-to/application.html
- Spring Boot 3.5 — Endpoints de Actuator (`conditions`, `beans`): https://docs.spring.io/spring-boot/3.5/reference/actuator/endpoints.html
