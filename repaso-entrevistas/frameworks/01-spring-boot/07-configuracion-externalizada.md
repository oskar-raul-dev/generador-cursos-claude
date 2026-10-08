# 07 — Configuración externalizada

> **Objetivo:** contestar "¿de dónde salió ese valor?" sin abrir el debugger, y dejar de
> repartir cadenas de configuración por el código.
> **Asume:** [`02`](02-contenedor-ioc-y-ciclo-de-vida.md), [`06`](06-arranque-y-autoconfiguracion.md).
> **Vigencia:** 17 de septiembre de 2026 · Spring Boot 3.5.16 · Spring Framework 6.2.19 · Java 21.

---

## 1. 🧭 El problema: el mismo artefacto en cinco entornos

El jar que pruebas en tu máquina tiene que ser **bit a bit el mismo** que se despliega en
integración, en preproducción y en producción. Si no lo es, lo que probaste no es lo que
corre. Y sin embargo la URL de la base, el tamaño del pool, el nivel de log y la URL del
proveedor externo son distintos en cada sitio.

La única salida es que todo eso viva **fuera** del artefacto y entre por configuración.
Boot lleva esa idea más lejos que la mayoría: ofrece diecisiete fuentes de propiedades con
un orden de precedencia definido, y ese orden es la causa de la pregunta de depuración más
frecuente del framework — *"pero si yo lo puse en el `application.yml`…"*.

---

## 2. 🧱 `Environment` y `PropertySource`

```text
Environment
 ├── PropertySource "commandLineArgs"      --server.port=9090
 ├── PropertySource "systemProperties"     -Dserver.port=9090
 ├── PropertySource "systemEnvironment"    SERVER_PORT=9090
 ├── PropertySource "applicationConfig: [classpath:/application-local.yml]"
 └── PropertySource "applicationConfig: [classpath:/application.yml]"
```

El `Environment` es una **lista ordenada** de fuentes. Cuando alguien pide
`server.port`, se recorre la lista de arriba abajo y **gana la primera que la tenga**. No
hay mezcla, no hay prioridad por especificidad: gana la primera.

Se prepara en el paso 3 del arranque ([`06`](06-arranque-y-autoconfiguracion.md)), antes de registrar beans, y por eso las
propiedades pueden condicionar qué beans existen.

---

## 3. ⚖ El orden de precedencia

De mayor a menor prioridad, quedándonos con las fuentes que de verdad usas:

| # | Fuente | Ejemplo |
|---|---|---|
| 1 | Configuración de Devtools | solo en desarrollo |
| 2 | `@TestPropertySource` y `properties` de `@SpringBootTest` | tests ([`24`](24-testing.md)) |
| 3 | **Argumentos de línea de comandos** | `java -jar app.jar --server.port=9090` |
| 4 | `SPRING_APPLICATION_JSON` | JSON inline en una variable |
| 5 | **Propiedades de sistema de la JVM** | `-Dserver.port=9090` |
| 6 | **Variables de entorno del SO** | `SERVER_PORT=9090` |
| 7 | `application-{profile}.yml` **fuera** del jar | despliegue |
| 8 | `application.yml` **fuera** del jar | despliegue |
| 9 | `application-{profile}.yml` **dentro** del jar | empaquetado |
| 10 | `application.yml` **dentro** del jar | empaquetado |
| 11 | `@PropertySource` en una `@Configuration` | heredado |
| 12 | Defaults (`SpringApplication.setDefaultProperties`) | librerías |

Tres cosas de esta tabla valen una entrevista entera:

- **La línea de comandos gana a todo lo que no sea un test.** Es lo que permite
  sobreescribir cualquier cosa en un incidente sin reconstruir la imagen.
- **Las propiedades de sistema (`-D`) ganan a las variables de entorno.** Mucha gente lo
  dice al revés. Ambas ganan a cualquier fichero.
- **Lo de fuera del jar gana a lo de dentro**, y dentro de cada grupo, lo específico de
  profile gana a lo genérico. Es lo que permite que una imagen de contenedor traiga
  defaults sensatos y el despliegue los ajuste montando un fichero al lado.

> Nunca respondas: ~~"el `application.yml` manda, por eso ahí se configura todo"~~
>
> Mejor: "el `application.yml` es la fuente de **menor** prioridad de las que uso a
> diario; cualquier variable de entorno lo sobreescribe, y eso es justamente lo que hace
> que el mismo artefacto sirva en todos los entornos."

---

## 4. ⚖ `.properties` y `.yaml`

| | `.properties` | `.yaml` |
|---|---|---|
| Anidamiento | por prefijo repetido | por indentación |
| Listas | `inv.hosts[0]=a` | `- a` |
| Varios documentos | no | sí, separados por `---` |
| Riesgo | verbosidad | **la indentación y los tipos implícitos** |

YAML es más legible y por eso el curso lo usa en los labs. A cambio tiene tres trampas
que muerden de verdad:

```yaml
inv:
  supplier:
    enabled: on          # ⚠️ 'on' se interpreta como booleano true (YAML 1.1)
    country: NO          # ⚠️ 'NO' se interpreta como booleano false
    version: 1.10        # ⚠️ es un número: se convierte en 1.1
    key: *secret         # ⚠️ '*' inicia una referencia de anclaje y revienta el parseo
```

- **`on`/`off`/`yes`/`no`/`y`/`n`** son booleanos en YAML 1.1, que es lo que usa SnakeYAML.
  Si quieres la cadena, van entrecomilladas: `"on"`.
- **`1.10` es un número decimal** y pierde el cero; una versión se escribe `"1.10"`.
- **`*` y `&` al principio de un valor** tienen significado en YAML. Cualquier secreto o
  patrón que empiece por ahí necesita comillas.
- **Y el clásico:** un error de indentación no falla, **crea otra propiedad**. El valor
  que esperabas simplemente no existe y toma su default.

> **💡 Truco.** Para una sola clave —un ejemplo, un `override` en un despliegue— es más
> seguro `.properties`: no tiene indentación que romper. El curso usa YAML en ficheros de
> configuración completos y `.properties` en ejemplos de una línea.

---

## 5. 🧱 Relaxed binding

La misma propiedad se escribe de formas distintas según la fuente, y Boot las unifica:

```text
inv.supplier.read-timeout      ← la forma canónica, la que se escribe en YAML
inv.supplier.readTimeout       ← camelCase, admitida
inv.supplier.read_timeout      ← admitida
INV_SUPPLIER_READTIMEOUT       ← la forma de variable de entorno
```

- **En variables de entorno** solo se admiten mayúsculas y guion bajo, porque es lo único
  portable entre shells: los puntos pasan a `_` y los guiones desaparecen.
- **La forma canónica en tus ficheros es minúsculas con guiones** (`read-timeout`), y es
  la que genera los metadatos para el autocompletado del IDE.
- **El relaxed binding solo aplica a `@ConfigurationProperties`**, no a `@Value`. Un
  `@Value("${inv.supplier.readTimeout}")` busca esa clave literal y no la encuentra si la
  escribiste con guion. Es una de las razones prácticas para preferir
  `@ConfigurationProperties`.

---

## 6. ⚖ `@Value` frente a `@ConfigurationProperties`

```java
@ConfigurationProperties(prefix = "inv.supplier")
@Validated
record SupplierProperties(
        @NotBlank String baseUrl,
        @NotNull Duration readTimeout,
        @Min(1) @Max(50) int maxConnections) {
}
```

```yaml
inv:
  supplier:
    base-url: https://inv-supplier.invlab.example
    read-timeout: 2s
    max-connections: 20
```

- **`record` + `@ConfigurationProperties`** funciona sin anotaciones extra: con un único
  constructor, Boot enlaza por constructor. Es inmutable y se lee de un vistazo.
- **`@Validated`** activa Bean Validation sobre el objeto, y **el arranque falla** si algo
  no cuadra, con un mensaje que nombra la propiedad y la restricción. Es exactamente lo
  que quieres: mejor no arrancar que arrancar con un timeout de cero.
- **`Duration`** se enlaza desde `2s`, `500ms` o `PT2S`. También hay soporte para
  `DataSize` (`10MB`). Parsear cadenas a mano es trabajo tirado.
- **Se registra** con `@EnableConfigurationProperties(SupplierProperties.class)` en una
  `@Configuration`, o con `@ConfigurationPropertiesScan` en la clase de arranque.
- **`spring-boot-configuration-processor`** como dependencia opcional genera los metadatos
  para que el IDE autocomplete y documente tus propiedades. Cuesta una línea en el
  `pom.xml` y es de las cosas que más agradece el equipo que hereda tu servicio.

| | `@Value` | `@ConfigurationProperties` |
|---|---|---|
| Tipado | conversión suelta por campo | objeto tipado completo |
| Validación | ninguna | Bean Validation, falla al arrancar |
| Relaxed binding | ❌ | ✅ |
| Metadatos para el IDE | ❌ | ✅ |
| SpEL (`#{…}`) | ✅ | ❌ |
| Bueno para | un valor suelto | un grupo de configuración |

**El veredicto:** `@Value` para un valor aislado y para cuando necesitas SpEL;
`@ConfigurationProperties` para todo lo demás. Tres `@Value` en la misma clase ya son
señal de que había un grupo.

---

## 7. 🧱 Profiles

```yaml
# application.yml — lo común
inv:
  supplier:
    read-timeout: 2s

---
spring:
  config:
    activate:
      on-profile: local      # este documento solo aplica con el profile local
inv:
  supplier:
    base-url: http://localhost:8090
```

- **`---`** separa documentos dentro del mismo fichero YAML, y cada uno puede activarse
  condicionalmente. La alternativa es un `application-local.yml` aparte; para dos o tres
  claves, el multi-documento se lee mejor.
- **`spring.config.activate.on-profile`** es la forma actual. La vieja
  `spring.profiles` quedó obsoleta en Boot 2.4, cuando cambió el mecanismo de carga de
  configuración; verla en un proyecto es señal de configuración heredada.
- **Se activan** con `spring.profiles.active=local` (o `SPRING_PROFILES_ACTIVE`), y se
  pueden acumular: `local,debug`. `spring.profiles.group.prod=metrics,audit` define grupos
  para no tener que enumerarlos.
- **`@Profile("local")`** sobre un bean lo registra solo con ese profile activo, y eso es
  un `@Conditional` evaluado una sola vez en el arranque ([`02`](02-contenedor-ioc-y-ciclo-de-vida.md)).

> **⚠️ `@Profile("!prod")` sobre un bean de seguridad es una bomba.** Un bean que relaja
> la autenticación "salvo en producción" se activa en cuanto alguien arranca sin el
> profile correcto — un despliegue mal parametrizado, un pod que no recibió la variable,
> un test de carga contra el entorno real. La regla segura es la contraria: lo peligroso
> se activa **solo** con un profile explícito (`@Profile("insecure-local")`), nunca por
> ausencia.

---

## 8. 🧱 Importar configuración y guardar secretos

```yaml
spring:
  config:
    import:
      - optional:file:./config/local.yml     # no falla si no existe
      - configtree:/run/secrets/             # cada fichero del directorio es una propiedad
```

- **`spring.config.import`** carga fuentes adicionales con la misma semántica de
  precedencia. El prefijo `optional:` evita que su ausencia rompa el arranque.
- **`configtree:`** es la respuesta de Boot a los secretos montados como ficheros —lo que
  hacen Kubernetes, Docker Swarm y los gestores de secretos—: el fichero
  `/run/secrets/inv.supplier.token` se convierte en la propiedad `inv.supplier.token`, con
  su contenido como valor.

> **⚠️ Un secreto no va en `application.yml`.** Ni cifrado con una clave que está en el
> mismo repositorio. El fichero de configuración se versiona, se copia en los logs de
> build y acaba en la imagen. Las opciones legítimas son variables de entorno inyectadas
> por la plataforma, un config tree montado, o un gestor de secretos consultado al
> arrancar — y la elección se justifica en [`21`](21-identidad-federada-oauth2-oidc-y-jwt.md).

---

## 9. 🩺 Auditar de dónde salió un valor

Dos endpoints de Actuator resuelven la pregunta que abre este capítulo:

```bash
curl -s localhost:8081/actuator/env/inv.supplier.read-timeout | jq
```

```json
{
  "property": { "source": "systemEnvironment", "value": "5s" },
  "activeProfiles": ["local"],
  "propertySources": [
    { "name": "commandLineArgs" },
    { "name": "systemEnvironment", "property": { "value": "5s" } },
    { "name": "applicationConfig: [classpath:/application.yml]",
      "property": { "value": "2s" } }
  ]
}
```

- **`property.source`** dice **qué fuente ganó**, que es exactamente la pregunta. Aquí una
  variable de entorno estaba sobreescribiendo el `application.yml`, que es el caso típico.
- **`propertySources`** lista todas las fuentes que tenían la clave, en orden de
  precedencia: se ve el valor que perdió.
- **`/actuator/configprops`** hace lo mismo pero agrupado por objeto
  `@ConfigurationProperties`, que es más cómodo cuando lo que quieres es revisar un bloque
  entero.
- **Los valores sensibles salen enmascarados** por defecto: Actuator oculta las claves
  cuyo nombre sugiere un secreto. No es una garantía, y por eso el endpoint `env` no se
  expone abierto ([`23` §2](23-actuator-y-observabilidad.md#2--qué-expone-actuator-por-defecto-y-cómo-se-asegura)).

---

## 10. ⚠️ Errores frecuentes

- **"El `application.yml` manda."** Es de las fuentes de menor prioridad. Cualquier
  variable de entorno lo pisa.
- **"Las variables de entorno ganan a `-D`."** Al revés: las propiedades de sistema de la
  JVM tienen más prioridad.
- **"Un error de indentación en YAML falla al arrancar."** Normalmente no: crea otra
  propiedad, y el valor que esperabas toma su default en silencio.
- **"`@Value` y `@ConfigurationProperties` son equivalentes."** El primero no tiene
  relaxed binding, ni validación, ni metadatos.
- **"Los profiles sirven para tener un fichero por entorno."** Sirven, y también registran
  o excluyen beans — que es donde está el riesgo, no en los ficheros.

---

## 🧠 Preguntas rápidas

1. ¿Qué es el `Environment` y qué pasa cuando dos fuentes definen la misma propiedad?
2. Ordena de mayor a menor prioridad: `application.yml` dentro del jar, variable de
   entorno, argumento de línea de comandos, propiedad de sistema `-D`,
   `application-prod.yml` fuera del jar.
3. ¿Por qué el orden de precedencia es lo que permite desplegar el mismo artefacto en
   todos los entornos?
4. Escribes `enabled: on` en un YAML y esperabas la cadena `"on"`. ¿Qué recibes y por qué?
5. Un error de indentación en `application.yml` no rompe el arranque. ¿Qué ocurre
   entonces, y por qué es peor?
6. ¿Qué es el relaxed binding y por qué **no** aplica a `@Value`?
7. ¿Cómo se escribe `inv.supplier.read-timeout` como variable de entorno?
8. Da tres ventajas concretas de `@ConfigurationProperties` sobre `@Value`, y la única
   cosa que `@Value` hace y el otro no.
9. ¿Qué consigues añadiendo `@Validated` a una clase de propiedades, y en qué momento se
   nota?
10. ¿Qué diferencia hay entre `spring.profiles.active` y `spring.config.activate.on-profile`?
11. ¿Por qué `@Profile("!prod")` sobre un bean de seguridad es peligroso, y cuál es la
    forma segura de expresar lo mismo?
12. ¿Qué es un config tree y qué problema resuelve?
13. Una propiedad tiene un valor que no esperabas. ¿Qué endpoint consultas y qué campo
    concreto te da la respuesta?
14. ¿Por qué un secreto no debe vivir en `application.yml`, ni siquiera cifrado con una
    clave del mismo repositorio?

---

## 📚 Referencias oficiales

- Spring Boot 3.5 — Externalized Configuration y orden de precedencia: https://docs.spring.io/spring-boot/3.5/reference/features/external-config.html
- Spring Boot 3.5 — Profiles: https://docs.spring.io/spring-boot/3.5/reference/features/profiles.html
- Spring Boot 3.5 — Metadatos de configuración: https://docs.spring.io/spring-boot/3.5/specification/configuration-metadata/index.html
- Spring Boot 3.5 — Endpoints de Actuator (`env`, `configprops`): https://docs.spring.io/spring-boot/3.5/reference/actuator/endpoints.html
- Spring Framework 6.2 — `Environment` y `PropertySource`: https://docs.spring.io/spring-framework/reference/6.2/core/beans/environment.html
