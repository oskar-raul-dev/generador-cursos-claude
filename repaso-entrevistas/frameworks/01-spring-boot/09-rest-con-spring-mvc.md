# 09 — REST con Spring MVC

> **Objetivo:** construir y defender un endpoint sabiendo qué hace Spring en cada paso,
> desde que el `DispatcherServlet` elige el método hasta que Jackson escribe el último byte.
> **Asume:** [`05`](05-proxies-y-aop.md), [`08`](08-modelo-de-ejecucion-web.md).
> **Vigencia:** 17 de septiembre de 2026 · Spring Boot 3.5.16 · Spring Framework 6.2.19 · Java 21 · Tomcat 10.1.

> **📝 Dónde termina este capítulo.** Aquí está **cómo llega un request a tu método y cómo
> vuelve la respuesta**. Bean Validation, `@ControllerAdvice`, `ProblemDetail`, paginación,
> versionado e hipermedia son el capítulo [`10`](10-diseno-de-api-validacion-errores-e-hipermedia.md): cuando asomen, los nombro y sigo.

---

## 1. 🧭 El problema: el hilo ya llegó, ¿y ahora quién atiende?

En [`08`](08-modelo-de-ejecucion-web.md#1--el-camino-de-un-request) dejamos el request en
la puerta del `DispatcherServlet`: Tomcat tomó un hilo del pool, la cadena de filtros lo
dejó pasar y el contexto ya cuelga del `ThreadLocal`. A partir de ahí solo hay un
`POST /api/items` con un `Content-Type`, un `Accept` y unos bytes. Entre esos bytes y el
método que tú escribiste hay tres saltos que explican casi todos los errores raros de una
API: **quién decide que ese método es el bueno**, **quién convierte los bytes en un
`InventoryItemRequest`** y **quién convierte el retorno en JSON**.

---

## 2. 🧱 El recorrido completo, pieza por pieza

```text
 DispatcherServlet
   ├─1─► HandlerMapping      ¿qué método atiende POST /api/items?  → HandlerMethod
   ├─2─► HandlerAdapter      ¿cómo se invoca ese handler?
   ├─3─► ArgumentResolver    uno por parámetro; el del body llama a un HttpMessageConverter
   ├─4─► tu método           ← tu código, con los argumentos ya tipados
   └─5─► ReturnValueHandler  ──► HttpMessageConverter (escribir)
```

- **`HandlerMapping`** construye en el arranque un índice de todas las combinaciones
  (path, método HTTP, `consumes`, `produces`, `params`, `headers`) que declaraste; no busca
  por reflexión en cada request, y lo ves entero en `/actuator/mappings` ([`23` §6](23-actuator-y-observabilidad.md#6--el-resto-del-catálogo-qué-pregunta-contesta-cada-endpoint)). El
  **`HandlerAdapter`** que viene detrás existe porque un handler no tiene por qué ser un
  método anotado; con anotaciones siempre es `RequestMappingHandlerAdapter`.
- **Los argument resolvers** son una lista ordenada: por cada parámetro Spring pregunta
  `supportsParameter(...)` y el primero que dice que sí lo resuelve. Por eso tus métodos no
  tienen orden ni cantidad fija de parámetros, y puedes añadir los tuyos (§9).

> **🧠 Modelo mental.** Tu método no "recibe un request": recibe lo que un resolver
> construyó a partir de él, y devuelve algo que un handler decide cómo escribir. Todo lo
> que parece magia en MVC sale de una de esas dos listas.

---

## 3. ⚖ `@Controller` vs `@RestController`

`@RestController` es literalmente `@Controller` + `@ResponseBody` a nivel de clase, y esa
anotación decide qué return value handler atiende tu retorno. **Sin `@ResponseBody`**, un
método que devuelve `String` está devolviendo **el nombre de una vista**: va a un
`ViewResolver` que busca una plantilla, y si no existe obtienes un 404 desconcertante sobre
una URL que sí mapeaste. **Con `@ResponseBody`** el valor va a los `HttpMessageConverter`:
no hay vistas, y un `Model` como parámetro sigue compilando sin hacer nada.

> Nunca respondas: ~~"`@RestController` es `@Controller` con JSON"~~
>
> Mejor: "añade `@ResponseBody` a todos los métodos, y eso cambia el return value handler:
> en vez de resolver una vista, el retorno pasa por los `HttpMessageConverter`. Que salga
> JSON es consecuencia de qué converters hay registrados y del `Accept` del cliente."

---

## 4. 🧱 Mapeos: qué compara de verdad el `HandlerMapping`

Un mapeo no es una ruta: es una condición compuesta, y cada atributo puede hacer que tu
método **no** se elija.

```java
@RestController
@RequestMapping("/api/items")
class InventoryItemController {

    @GetMapping(value = "/{sku}", produces = MediaType.APPLICATION_JSON_VALUE)
    InventoryItemResponse bySku(@PathVariable String sku) { ... }

    @PostMapping(consumes = MediaType.APPLICATION_JSON_VALUE)
    ResponseEntity<InventoryItemResponse> create(@RequestBody InventoryItemRequest request) { ... }
}
```

- **El `@RequestMapping` de la clase es un prefijo y se concatena** con el del método; los
  atajos (`@GetMapping`, `@PostMapping`, `@PutMapping`…) son `@RequestMapping` con el
  `method` fijado, y no aportan nada más.
- **`consumes`** filtra por el `Content-Type` del request; si no coincide, el método ni se
  considera y el resultado es **415**, no un 404 (§8).
- **`produces`** filtra por el `Accept` del cliente y fija el `Content-Type` de la
  respuesta; si no coincide, **406**. Usa las constantes `MediaType.*_VALUE`: un
  `"aplication/json"` mal escrito compila igual y falla igual de silenciosamente.
- **`params` y `headers`** condicionan por presencia (`"warehouse"`), ausencia
  (`"!warehouse"`) o valor: la forma barata de tener dos handlers en la misma ruta, y la de
  versionar por header — el veredicto es de `10`.

**Cuando dos patrones encajan gana el más específico:** literal > variable > `*` > `**`, y
a igualdad gana el que tenga menos variables. Así, `@GetMapping("/{sku}")` no se traga
`/api/items/summary` mientras ese mapeo exista; si alguien lo borra sí, y el síntoma es un
400 por conversión de tipo, no un 404.

> **📝 En Boot 3.x el matcher por defecto es `PathPatternParser`**, no `AntPathMatcher`:
> `**` solo se admite al final, y un `/api/**/items` de Boot 2.x hoy revienta el arranque.

---

## 5. 🧱 Los argumentos del método

Cada anotación de parámetro es un resolver distinto, y cada una falla distinto:

- **`@PathVariable`** extrae del patrón de la URL tomando el nombre del parámetro Java, lo
  que exige compilar con `-parameters` (el `spring-boot-starter-parent` ya lo activa); si no,
  el arranque falla con `Name for argument of type [java.lang.String] not specified`.
- **`@RequestParam`** lee query string o formulario y **es obligatorio salvo `defaultValue`
  o `required = false`**; si falta, 400 con `MissingServletRequestParameterException`. Con
  `required = false` sobre un primitivo tienes un `NullPointerException` en el binding.
- **`@RequestBody`** es el único que consume el cuerpo y dispara un converter de lectura
  (§7), y **solo puede haber uno por método**, por la razón de
  [`08` §6](08-modelo-de-ejecucion-web.md#6-️-leer-el-cuerpo-en-un-filtro-lo-destruye): el
  cuerpo es un `InputStream` de un solo uso.
- **`@RequestHeader`** repite el contrato de `required` y `defaultValue`, y lo que no lleva
  anotación también se resuelve (`HttpServletRequest`, `Principal`). Si ningún resolver
  reconoce el tipo, Spring asume `@ModelAttribute` y bindea por propiedades: de ahí los
  objetos que llegan con todo a `null` en vez de fallar.

Para devolver la URL de un recurso recién creado, no concatenes cadenas:

```java
@PostMapping
ResponseEntity<InventoryItemResponse> create(@RequestBody InventoryItemRequest request,
                                             UriComponentsBuilder uriBuilder) {
    InventoryItemResponse created = service.create(request);
    URI location = uriBuilder.path("/api/items/{sku}")       // plantilla, no concatenación
                             .buildAndExpand(created.sku())  // sustituye y escapa
                             .toUri();
    return ResponseEntity.created(location).body(created);
}
```

- **`UriComponentsBuilder` inyectado como parámetro** ya trae esquema, host, puerto y
  `context-path` del request en curso (§10); uno creado con `newInstance()` no, y ahí nacen
  las `Location` que apuntan a `localhost` detrás de un balanceador.
- **`buildAndExpand`** escapa los valores, y **`ResponseEntity.created(location)`** pone el
  201 y la cabecera `Location` de una vez: lo que un cliente espera de un POST que crea.

---

## 6. ⚖ `ResponseEntity`, el objeto pelado y `@ResponseStatus`

| | Devolver el objeto | `ResponseEntity<T>` | `@ResponseStatus` |
|---|---|---|---|
| Código de estado | siempre 200 (204 si es `void`) | el que pongas, por rama | fijo, declarado |
| Cabeceras propias | ❌ | ✅ | ❌ |
| Uso natural | GET que siempre encuentra | POST y métodos con dos salidas | POST que siempre crea |

- **Devolver el objeto** es lo más legible con un solo desenlace, y un `Optional<T>` vacío
  devuelto así **no** es un 404: es un 200 con cuerpo vacío. **`ResponseEntity<T>`** es la
  única forma de poner `Location`, `ETag` o un 404 con `notFound().build()`.
- **`@ResponseStatus(HttpStatus.CREATED)`** fija el código sin tocar el tipo de retorno:
  limpio con un desenlace, estorbo con dos. Sobre una excepción propia es el modo más barato
  de traducir un fallo de dominio a HTTP; el serio es `10`.

---

## 7. 🧱 `HttpMessageConverter` y Jackson

Un converter sabe leer y escribir un tipo Java en un media type. Spring mantiene una lista
ordenada y elige el primero que soporte el par (tipo, media type); quien atiende JSON con el
starter web es `MappingJackson2HttpMessageConverter`, el mismo que usa el `RestClient` de
[`13`](13-clientes-http.md) al llamar hacia fuera: el `ObjectMapper` es compartido.

El DTO del curso es un `record` inmutable sin anotaciones de JPA —
`record InventoryItemRequest(String sku, int quantity, Instant registeredAt) {}`— y Jackson
lo deserializa por el constructor canónico, sin setters ni `@ConstructorProperties`;
`@JsonProperty` solo hace falta cuando el nombre JSON **no** coincide con el del componente
Java. El `Instant` funciona porque Boot registra `JavaTimeModule`: sin él, `InvalidDefinitionException: Java 8 date/time type not supported by default`.

La configuración que de verdad se toca vive en `application.yml`, no en una clase:

```yaml
spring:
  jackson:
    default-property-inclusion: non_null       # omite del cuerpo los campos null
    serialization:
      write-dates-as-timestamps: false         # ISO-8601, no epoch millis
    deserialization:
      fail-on-unknown-properties: false        # default de Boot; aquí, explícito
    time-zone: UTC
```

- **`non_null`** reduce el cuerpo y evita que el cliente distinga "no vino" de "vino
  `null`": es una decisión de contrato, tómala una vez y documéntala.
- **`write-dates-as-timestamps: false`** ya es el default de Boot, pero Jackson a secas hace
  lo contrario y quien lea el YAML no tiene por qué saberlo. **`time-zone: UTC`** impide que
  la zona de la máquina se cuele en el contrato: en banca, un desfase de zona en un
  movimiento de inventario es una incidencia.
  Y **`fail-on-unknown-properties: false`** permite que el productor añada un campo sin
  romperte: en `true`, cada campo nuevo del cliente es un 400.

> **⏱️ Costo en runtime.** La serialización ocurre **en el hilo del request** (`08` §2) y,
> salvo con `StreamingResponseBody`, Jackson escribe a un buffer en memoria antes de enviar
> nada: una lista de 50 000 `InventoryItem` son decenas de MB retenidos y cientos de ms de
> CPU con el hilo y su cupo del pool tomados. Por eso existe la paginación (`10`).

Y por qué un DTO no es una entidad: **acoplas el contrato al esquema**, **publicas campos
que nadie decidió publicar** y **arrastras el modelo de carga de JPA** (Jackson recorre los
getters, toca una colección `LAZY` fuera de sesión y aparece `LazyInitializationException`).

> Nunca respondas: ~~"devolver la entidad directamente es más simple"~~
>
> Mejor: "es más corto hoy y más caro siempre: acopla el contrato HTTP al esquema de la
> base, publica campos que nadie revisó y mete el modelo de carga de JPA dentro del
> serializador."

---

## 8. 🩺 406, 415 y 400: tres fallos que no se parecen

```text
415 Unsupported Media Type  →  no sé LEER tu Content-Type
406 Not Acceptable          →  no sé ESCRIBIR lo que pides en Accept
400 Bad Request             →  el media type está bien, el contenido no
```

**415** — el cuerpo viene con el tipo equivocado:

```text
$ curl -i -X POST localhost:8080/api/items -H 'Content-Type: text/plain' -d 'sku=A1'
HTTP/1.1 415
org.springframework.web.HttpMediaTypeNotSupportedException:
  Content-Type 'text/plain' is not supported
```

El mapeo declaraba `consumes`, así que el handler **ni se consideró elegible**: el fallo
ocurre en el `HandlerMapping`, antes de tocar un converter. Y la causa más frecuente no es
`text/plain`: es no mandar `Content-Type` en absoluto.

**406** — pides una representación que nadie sabe producir; es problema de la respuesta:

```text
$ curl -i localhost:8080/api/items/A1 -H 'Accept: application/xml'
HTTP/1.1 406
org.springframework.web.HttpMediaTypeNotAcceptableException: No acceptable representation
```

Ningún converter registrado escribe XML —haría falta `jackson-dataformat-xml`— o el mapeo
fijó `produces`.

**400** — el media type es correcto y el contenido no:

```text
$ curl -i -X POST localhost:8080/api/items -H 'Content-Type: application/json' -d '{"sku":}'
HTTP/1.1 400
org.springframework.http.converter.HttpMessageNotReadableException: JSON parse error:
  Unexpected character ('}' (code 125)): expected a valid value
```

Aquí el converter **sí** se eligió, corrió y falló al parsear. El mismo 400 lo produce un
`@PathVariable` que no convierte al tipo declarado (`MethodArgumentTypeMismatchException`),
y el de validación es otra excepción: materia de `10`.

> **🩺 Diagnóstico.** El cuerpo por defecto lo produce el endpoint `/error` de Boot y trae
> `status` y `path`, pero **no la excepción**: para verla,
> `logging.level.org.springframework.web=DEBUG`. Y `/actuator/mappings` dice qué `consumes`
> y qué `produces` quedaron registrados de verdad.

> Nunca respondas: ~~"415 y 400 son lo mismo, la petición viene mal"~~
>
> Mejor: "415 es que ningún converter soporta ese `Content-Type` y el handler ni se evalúa;
> 400 es que el converter sí corrió y el contenido no se pudo leer. Y si el problema está
> en el `Accept`, no es ninguno de los dos: es 406."

---

## 9. 🧱 `WebMvcConfigurer`: el punto de extensión de MVC

Cuando hay que tocar las listas del §2 no se reemplaza la configuración de Boot: se
implementa `WebMvcConfigurer` y se **añade**.

```java
@Configuration
class WebConfig implements WebMvcConfigurer {
    @Override
    public void addCorsMappings(CorsRegistry registry) {
        registry.addMapping("/api/**")
                .allowedOrigins("https://portal.invlab.example")  // nunca "*" con credenciales
                .maxAge(3600);                                    // cachea el preflight, en segundos
    }
}
```

- **Implementar la interfaz, no anotar con `@EnableWebMvc`.** `@EnableWebMvc` **apaga**
  `WebMvcAutoConfiguration` entera: pierdes los converters de Boot, los recursos estáticos y
  los defaults de Jackson. Es el error más caro del capítulo y no avisa.
- **`addCorsMappings`** configura CORS a nivel de MVC; si Spring Security está delante, el
  preflight `OPTIONS` llega sin credenciales y lo rechaza **antes** del `DispatcherServlet`
  (`08` §5): de ahí el CORS que "está configurado" y sigue fallando ([`20` §11](20-spring-security-el-mecanismo.md#11--csrf-cors-y-sesión-las-tres-que-rompen-una-api)). Y
  `allowedOrigins("*")` con `allowCredentials(true)` **falla en el arranque**, que es lo
  que debe hacer: es la combinación que anula la protección.
- **`addFormatters(FormatterRegistry)`** registra conversiones de `String` a tus tipos y
  alcanza a `@PathVariable` y `@RequestParam`. De **`extendMessageConverters` vs
  `configureMessageConverters`**: el primero modifica la lista que Boot construyó, el
  segundo la **reemplaza**.
- **`addInterceptors`** registra un `HandlerInterceptor`, con la diferencia frente a un
  `Filter` ya resuelta en [`08` §5](08-modelo-de-ejecucion-web.md#5--filtro-interceptor-o-advice).

---

## 10. 🧱 Prefijo de despliegue y apagado ordenado

```yaml
server:
  servlet:
    context-path: /inv-api      # toda la app cuelga de este prefijo
  shutdown: graceful            # el default es 'immediate'
spring:
  lifecycle: { timeout-per-shutdown-phase: 30s }
```

- **`context-path`** es transparente para tus `@GetMapping`: sigues mapeando `/api/items` y
  la URL real es `/inv-api/api/items`. Lo que rompe es toda URL absoluta armada a mano (§5);
  Actuator cuelga del puerto de management (`23`) y **no** hereda el prefijo.
- **`shutdown: graceful`** hace que, al recibir `SIGTERM`, el conector deje de aceptar
  conexiones nuevas y el contexto espere a las que están en vuelo. Con el default
  `immediate` los requests en curso se cortan a media respuesta y el cliente ve una conexión
  caída, no un error HTTP. **`timeout-per-shutdown-phase: 30s`** es el techo antes de cortar
  por lo sano: el apagado dura lo que el request más lento, hasta ese límite.

> **⏱️ Costo en runtime.** Mientras drena, la instancia **sigue reteniendo sus hilos y sus
> conexiones del pool** hasta esos 30 segundos: en un rolling update de diez réplicas, medio
> minuto por réplica con recursos tomados. Por eso el `readiness` cae antes del `SIGTERM` (`23`).

---

## 11. ⚠️ Errores frecuentes

- **"El `@RequestMapping` de la clase reemplaza al del método."** Se concatenan: `/api` en
  la clase y `/api/items` en el método dan `/api/api/items`, y el 404 parece imposible hasta
  que miras `/actuator/mappings`.
- **"`@EnableWebMvc` activa Spring MVC en Boot."** Lo desactiva parcialmente: apaga la
  autoconfiguración de MVC, que en Boot ya viene con el starter.
- **📝 En la línea 4.x el baseline pasa a Jackson 3** (paquete `tools.jackson.*`): el
  mecanismo de converters no cambia, los imports y algunas propiedades sí ([`A04` §6](a04-migracion-3-5-a-4-x.md#6--jackson-3-qué-import-cambia-y-cuál-no)).

---

## 🧠 Preguntas rápidas

1. Nombra en orden las cinco piezas que atraviesa un request dentro del `DispatcherServlet`.
2. ¿Qué hace `@ResponseBody` y por qué `@RestController` no es "el que devuelve JSON"?
3. Explica la diferencia entre 406, 415 y 400 nombrando la excepción concreta de cada uno.
4. Tienes `@GetMapping("/{sku}")` y `@GetMapping("/summary")` en el mismo controller: ¿cuál
   atiende `GET /api/items/summary` y por qué?
5. ¿Cuándo eliges `ResponseEntity` sobre devolver el objeto, y cuándo basta `@ResponseStatus`?
6. Da tres razones técnicas para no serializar una entidad de JPA como respuesta HTTP.
7. ¿Por qué se inyecta `UriComponentsBuilder` en vez de concatenar la URL a mano?
8. ¿Por qué solo puede haber un `@RequestBody` por método?
9. ¿Qué diferencia hay entre implementar `WebMvcConfigurer` y anotar con `@EnableWebMvc`?
10. Configuraste CORS con `addCorsMappings` y el navegador sigue rechazando el preflight:
    ¿cuál es la primera hipótesis?
11. ¿Qué hace `server.shutdown=graceful` y qué le pasa al pool de hilos durante ese drenaje?
12. `spring.jackson.deserialization.fail-on-unknown-properties` en `true`: ¿qué gana y qué
    rompe el día que el productor añade un campo?

---

## 📚 Referencias oficiales

- Spring Framework 6.2 — Annotated Controllers: https://docs.spring.io/spring-framework/reference/6.2/web/webmvc/mvc-controller.html
- Spring Framework 6.2 — `@RequestMapping`: https://docs.spring.io/spring-framework/reference/6.2/web/webmvc/mvc-controller/ann-requestmapping.html
- Spring Framework 6.2 — Argumentos de un método handler: https://docs.spring.io/spring-framework/reference/6.2/web/webmvc/mvc-controller/ann-methods/arguments.html
- Spring Framework 6.2 — `ResponseEntity`: https://docs.spring.io/spring-framework/reference/6.2/web/webmvc/mvc-controller/ann-methods/responseentity.html
- Spring Framework 6.2 — `HttpMessageConverter`: https://docs.spring.io/spring-framework/reference/6.2/web/webmvc/message-converters.html
- Spring Framework 6.2 — MVC Config (`WebMvcConfigurer`): https://docs.spring.io/spring-framework/reference/6.2/web/webmvc/mvc-config.html
- Spring Framework 6.2 — Construcción de URIs: https://docs.spring.io/spring-framework/reference/6.2/web/webmvc/mvc-uri-building.html
- Spring Framework 6.2 — CORS: https://docs.spring.io/spring-framework/reference/6.2/web/webmvc-cors.html
- Spring Boot 3.5 — JSON y Jackson: https://docs.spring.io/spring-boot/3.5/reference/features/json.html
- Spring Boot 3.5 — Graceful shutdown: https://docs.spring.io/spring-boot/3.5/reference/web/graceful-shutdown.html
