# 10 — Diseño de API: validación, errores e hipermedia

> **Objetivo:** diseñar el contrato de una API que otro equipo pueda consumir sin preguntarte
> nada —qué valida, cómo falla, cómo pagina, cómo versiona— y explicar por qué HATEOAS casi nunca
> se usa bien.
> **Asume:** [`05`](05-proxies-y-aop.md), [`08`](08-modelo-de-ejecucion-web.md), y el recorrido
> del request por MVC que desarrolla [`09`](09-rest-con-spring-mvc.md).
> **Vigencia:** 17 de septiembre de 2026 · Spring Boot 3.5.16 · Spring Framework 6.2.19 · Java 21.

---

## 1. 🧭 El problema: el contrato es el producto

Tu servicio `inv-api` expone `POST /api/items`. El equipo de canales lo integra y te escribe a los
tres días: *"a veces nos responde 500 con un HTML de Tomcat, a veces un JSON con una clave `mensaje`,
y cuando mandamos una cantidad negativa nos dice 200 pero no guarda nada"*. Nadie tocó la lógica de
negocio: lo que está roto es el contrato —qué entra, cómo falla, cómo crece, qué se anuncia—, bajo
una regla: **el cliente no debería leer tu código para saber qué le va a pasar**.

---

## 2. 🧱 Validar el body: `@Valid`

Sin validación, un DTO con campos nulos llega hasta tu servicio y revienta cuatro capas más abajo,
con un stack trace inútil para el cliente. Bean Validation mueve esa comprobación al borde.

```java
import jakarta.validation.Valid;                       // el estándar de Jakarta
record CreateItemRequest(@NotBlank @Size(max = 32) String sku,
                         @NotNull @PositiveOrZero Integer quantity) { }

@PostMapping
ResponseEntity<ItemResponse> create(@Valid @RequestBody CreateItemRequest request) {
    return ResponseEntity.status(HttpStatus.CREATED).body(service.create(request));
}
```

- **`@Valid` es de `jakarta.validation`** y sobre un `@RequestBody` la aplica MVC al resolver el
  argumento: si algo falla, **tu método no se ejecuta**. Sobre un campo del DTO marca la validación
  **anidada**: sin él, el objeto interno no se revisa.
- **`@NotNull` solo rechaza `null`**, `@NotEmpty` también la cadena vacía y `@NotBlank` también la
  que solo tiene espacios. Y **`Integer`, no `int`**: con `int quantity` el campo ausente llega como
  `0`, el `@NotNull` nunca dispara y pierdes la diferencia entre "mandó cero" y "no mandó nada".
- **Hace falta `spring-boot-starter-validation`**: sin esa dependencia no hay error de arranque, las
  anotaciones **se ignoran en silencio**.

```text
org.springframework.web.bind.MethodArgumentNotValidException: Validation failed for argument [0] in
... create(CreateItemRequest) with 1 error: [Field error ... on field 'sku': rejected value [];
default message [must not be blank]]
```

Extiende `BindException` y Spring ya la traduce a **400**; lo que no hace es darle formato (§5).

---

## 3. ⚖ `@Valid` vs `@Validated`, y qué excepción lanza cada caso

Ahora quieres validar un parámetro suelto: `?size=500` debería rechazarse en el borde. Aquí está la
respuesta que casi todo el mundo trae aprendida de un blog de 2019 —*"ponle `@Validated` a la clase
del controller"*— y que **desde Spring Framework 6.1 es exactamente lo contrario de lo que hay que
hacer**. En un controller, poner la restricción en la firma basta: la validación de parámetros de
método la hace MVC por su cuenta.

```java
import org.springframework.validation.annotation.Validated;   // no es jakarta.validation

@RestController                              // sin @Validated en la clase: a propósito
class InventoryItemController {
    @GetMapping("/{sku}")
    ItemResponse byId(@PathVariable @Size(min = 3, max = 32) String sku,
                      @RequestParam(defaultValue = "20") @Max(100) int size) { … }
}
```

- **Las restricciones en los parámetros las aplica MVC**, no un proxy, cuando el handler es un método
  de controller. Si alguna falla el método no se ejecuta y sube una
  `HandlerMethodValidationException`, que `DefaultHandlerExceptionResolver` mapea a **400**.
- **`@Validated` en la clase del controller rompe eso**, no lo habilita: devuelve la validación al
  camino de AOP de `MethodValidationPostProcessor` ([`05`](05-proxies-y-aop.md)), que lanza
  `ConstraintViolationException` —de Jakarta, desconocida para MVC— y sale **500**. La reference lo
  dice con todas las letras: *"In order to take advantage of the Spring MVC built-in support for
  method validation added in Spring Framework 6.1, you need to remove the class level `@Validated`
  annotation from the controller"*.
- **`@Validated` sigue siendo necesaria fuera del controller.** Un `@Service` cuyos parámetros
  quieras validar sí la lleva en la clase, porque ahí no hay MVC que valide por ti: solo hay proxy.
- **`@Valid` no se puede poner en una clase** —su objetivo es un argumento o un campo— y no acepta
  grupos; `@Validated(OnCreate.class)` sí. El import se escribe siempre: confundirlos es un bug real.

Los grupos resuelven *"el `id` es obligatorio al actualizar y prohibido al crear"* sin duplicar el
DTO: un grupo es una interfaz vacía que hace de marcador y cada restricción declara a cuáles
pertenece, `@Null(groups = OnCreate.class)`; la trampa es que **una sin `groups` pertenece a
`Default` y no se evalúa cuando pides un grupo concreto**. La regla de negocio va en un
`ConstraintValidator<ValidSku, String>` registrado como bean. Y lo que hay que llevarse es esto:

| Qué pasó | Excepción | Status por defecto |
|---|---|---|
| Body deserializado, campos inválidos | `MethodArgumentNotValidException` | 400 |
| Parámetro inválido en un controller **sin** `@Validated` | `HandlerMethodValidationException` | 400 |
| Parámetro inválido con `@Validated` en la clase | `ConstraintViolationException` | **500** |
| JSON roto, tipo incompatible, body ausente | `HttpMessageNotReadableException` | 400 |
| `?quantity=abc` sobre un `int` | `MethodArgumentTypeMismatchException` | 400 |

> **⚠️ El 500 lo causa la anotación que creías que lo evitaba.** Una `ConstraintViolationException`
> es de Jakarta, no de MVC, y el manejo por defecto la trata como fallo del servidor. La lanza el
> proxy, y en un controller el proxy solo aparece si tú pusiste `@Validated` en la clase. Quitarla es
> la corrección; el `@Validated` se queda donde sí hace falta, en los `@Service`.

> Nunca respondas: ~~"`@Valid` y `@Validated` son lo mismo, uno es el de Spring"~~
>
> Mejor: "`@Valid` es de Jakarta, va en argumentos y campos, y la aplica MVC al resolver el
> `@RequestBody`. `@Validated` es de Spring, va en la clase y activa la validación de parámetros vía
> proxy, que es lo que necesitas en un `@Service` — en un controller sobra desde 6.1 y te convierte
> el 400 en un 500. Y es la única de las dos que admite grupos."

---

## 4. 🧱 Manejo centralizado, y lo que se le escapa

Un `try/catch` por endpoint produce veinte traducciones del mismo error. Spring ofrece tres alcances:
`@ExceptionHandler` en el propio controller, `@ControllerAdvice` para todos —o los que filtres— y
`ResponseEntityExceptionHandler`, la clase base que ya maneja las de MVC.

```java
@RestControllerAdvice(basePackages = "com.invlab.invapi.inventory")
class InventoryExceptionHandler extends ResponseEntityExceptionHandler {
    @ExceptionHandler(ItemNotFoundException.class)
    ProblemDetail handleNotFound(ItemNotFoundException ex) {
        ProblemDetail problem = ProblemDetail.forStatusAndDetail(HttpStatus.NOT_FOUND, ex.getMessage());
        problem.setType(URI.create("https://invlab.example/problems/item-not-found"));
        problem.setProperty("sku", ex.sku());        // campo de extensión
        return problem;
    }
}
```

- **`@RestControllerAdvice`** es `@ControllerAdvice` + `@ResponseBody`, y **`basePackages`** acota
  el alcance: sin filtro aplica a toda la aplicación, incluidos los controllers de Actuator.
  **Devolver `ProblemDetail` directamente** funciona desde Spring 6: el status sale del objeto.
- **Extender `ResponseEntityExceptionHandler`** te regala la docena de excepciones estándar de MVC
  ya mapeadas; para personalizar una se **sobrescribe** `handleMethodArgumentNotValid`. Si además
  escribes un `@ExceptionHandler` para la misma, el tuyo gana y el de la base queda muerto.
- **El handler más específico gana**, y uno de `Exception` como red final es razonable **si registra
  el stack trace y responde 500 sin filtrar el mensaje**: capturarla para "que no truene" es el
  antipatrón.

> **⚠️ Una excepción lanzada en un filtro NO pasa por tu `@ControllerAdvice`**
> ([`08` §5](08-modelo-de-ejecucion-web.md#5--filtro-interceptor-o-advice)). El `@ExceptionHandler`
> vive dentro del `DispatcherServlet` y un filtro corre fuera: la excepción sube al contenedor de
> servlets y el cliente recibe el `/error` de Boot o la página de Tomcat, sin tu `ProblemDetail`.

Por eso los **401 y 403 de Spring Security no salen con tu formato**: los produce un
`AuthenticationEntryPoint` o un `AccessDeniedHandler` dentro de la cadena de filtros, y se configuran
uno por uno ([`20` §9](20-spring-security-el-mecanismo.md#9--401-frente-a-403-quién-los-escribe)). Un 404 de ruta inexistente tampoco llega al advice salvo que pidas
`spring.mvc.throw-exception-if-no-handler-found=true`.

> **🩺 Diagnóstico.** Ves el error en el log pero el cliente recibe otro formato: si el stack trace no
> contiene `DispatcherServlet.doDispatch`, nació fuera de MVC y ningún advice lo va a atrapar.

---

## 5. 🧱 `ProblemDetail` y RFC 9457

Casi todo el mundo inventa su formato de error: con doce servicios salen doce formatos y cada cliente
escribe doce parsers. La **RFC 9457** (*Problem Details for HTTP APIs*, que obsoleta a la 7807) fija
uno solo, y Spring lo implementa en `ProblemDetail`:

```text
HTTP/1.1 404 Not Found
Content-Type: application/problem+json

{ "type": "https://invlab.example/problems/item-not-found", "title": "Item no encontrado",
  "status": 404, "detail": "No existe el item con sku ABC-000123",
  "instance": "/api/items/ABC-000123", "sku": "ABC-000123" }
```

- **`type`** es un URI que identifica **la clase de problema** y es la clave de todo: el cliente
  enruta por `type`, nunca por el texto de `detail`.
- **`title`** es legible y estable por `type`; **`detail`** es específico de **esta** ocurrencia e
  **`instance`** la identifica. Si metes el `sku` en el `title`, rompiste esa estabilidad.
- **`sku` es un campo de extensión**, puesto con `setProperty(...)`: ahí va lo tuyo —el campo que
  falló, un `traceId`, las violaciones—. Y el `Content-Type` es **`application/problem+json`**, así
  que el cliente distingue un error de una respuesta normal sin mirar el status.

Para las excepciones **estándar** de MVC hay además una propiedad ([`07`](07-configuracion-externalizada.md)),
`spring.mvc.problemdetails.enabled=true`:

- **Con el default `false`**, un 400 de validación que no manejes tú sale con el formato `/error` de
  Boot —`timestamp`, `status`, `error`, `path`—: es JSON, pero no es `problem+json`.
- **Con `true`**, `ResponseEntityExceptionHandler` produce `ProblemDetail` para las excepciones de
  MVC que ya conoce. **No afecta a tus excepciones de negocio**: esas las traduces tú, y por eso el
  advice de §4 sigue haciendo falta. Un `Map<String,String>` casero es peor aunque "funcione": no
  declara su `Content-Type`, no tiene `type` por el que enrutar y se deriva distinto en cada servicio.

> Nunca respondas: ~~"un error se devuelve con 500 y un mensaje"~~
>
> Mejor: "el status dice de quién es la culpa y `type` identifica el problema; el formato es
> `application/problem+json` según la RFC 9457, que Spring implementa en `ProblemDetail` y activa
> para las excepciones de MVC con `spring.mvc.problemdetails.enabled=true`."

---

## 6. ⚖ Códigos de estado con criterio

| Duda | El primero cuando… | El segundo cuando… |
|---|---|---|
| **400 vs 422** | el mensaje no se entiende: JSON roto, tipo incompatible | se entiende y es semánticamente inválido |
| **401 vs 403** | no sé quién eres, o tu token expiró | sé quién eres y no te alcanza |
| **404 vs 403** | el recurso no existe | existe y no es tuyo — y a veces conviene 404 |
| **409 vs 422** | choca con el estado actual: duplicado, versión obsoleta | el payload es inválido por sí solo |

- **400 vs 422 tiene dos escuelas honestas**: el 422 es más preciso y varias APIs de banca lo exigen,
  el 400 no sorprende a nadie. **Elige una y documéntala**; lo que rompe integraciones es usar las
  dos sin regla. **404 en vez de 403 es una decisión de seguridad**: un 403 confirma que el recurso
  existe y permite enumerar cuentas ajenas.
- **El 401 exige `WWW-Authenticate`** (RFC 9110) y el **429** —"superaste tu cuota", frente al 503 de
  "no doy abasto"— debería traer `Retry-After`. Un 4xx no se reintenta —salvo 429 y 408—; un 5xx sí ([`19` §3](19-resiliencia.md#3--retry-cuándo-ayuda-y-cuándo-empeora-la-caída)).

---

## 7. 🧱 Idempotencia: el mismo `POST` dos veces

El cliente manda `POST /api/items`, la respuesta se pierde en el camino y él reintenta: acabas con
dos items, y en una API de pagos con dos cargos. `GET`, `PUT` y `DELETE` son idempotentes por
definición; **`POST` no lo es**, y por eso hace falta una clave que tú controles.

- **La clave la genera el cliente**, una por intención de negocio y no por reintento, y llega como
  `@RequestHeader("Idempotency-Key")` —sin `defaultValue`, que es lo que la hace obligatoria: si
  falta, MVC lanza `MissingRequestHeaderException` y sale 400—. Si la generas tú no sirve de nada,
  porque el reintento traería otra.
- **El store guarda clave → respuesta con TTL** y la segunda llamada devuelve la respuesta original
  sin ejecutar el negocio; en el lab es Redis ([`17` §6](17-cache.md#6--redis-como-caché-ttl-por-caché-y-serialización)). La clave se ata al payload: si la misma llega
  con un body distinto, la respuesta correcta es 409.

> **⏱️ Costo en runtime.** El registro de idempotencia **crece con cada escritura**, no con cada error:
> sin TTL es un keyspace que solo sube. Se fija una ventana —24 horas es lo habitual en banca— y se
> declara en el contrato, porque un reintento fuera de esa ventana sí va a duplicar.

---

## 8. ⚖ Versionado: path, header o media type

Un cambio incompatible —renombrar un campo, quitar un valor de un enum— rompe a todos los clientes a
la vez. Las tres formas de evitarlo:

| | **Path** `/v1/items` | **Header** `X-API-Version: 1` | **Media type** `…item.v1+json` |
|---|---|---|---|
| Visible en el log y en el navegador | ✅ | ❌ | ❌ |
| Enrutable en el gateway sin leer cabeceras | ✅ | parcial | ❌ |
| Puro según REST (la URI identifica el recurso) | ❌ | ✅ | ✅ |

**Veredicto para banca: versión en el path.** No porque sea la más elegante —duplica la URI de un
recurso que es el mismo— sino porque es la única que un gateway, un WAF, un log de auditoría y
operaciones entienden sin configurar nada, y ahí la trazabilidad de qué versión consumió cada canal
suele ser requisito regulatorio. Versiona el **servicio**, no el endpoint; sube la versión **solo**
por cambios incompatibles —añadir un campo opcional no rompe a nadie si los clientes ignoran los
desconocidos, que es lo que Jackson hace— y anuncia la fecha de retirada al publicarla.

> **📝 Qué cambia en 4.x.** Spring Framework 7 —la base de Spring Boot 4— trae **versionado de API de
> primera clase**: `@RequestMapping(version = "1.1")` y un configurador que resuelve la versión desde
> el path, una cabecera, un parámetro o el media type. En 3.5.16 se hace con prefijos o `headers=`.

---

## 9. 🧱 Paginación: `Page`, `Slice` y cursor

`GET /api/items` sin paginar funciona con las mil filas de tu entorno local y muere con los dos
millones de producción. Y hay dos tipos de retorno paginado, no uno.

```java
@GetMapping
PagedResponse<ItemResponse> list(@PageableDefault(size = 20, sort = "sku") Pageable pageable) {
    Page<InventoryItem> page = repository.findAll(pageable);
    return PagedResponse.from(page.map(ItemResponse::from));   // DTO propio, no la Page
}
```

- **`Pageable` lo resuelve un argument resolver de Spring Data** a partir de `?page=`, `?size=` y
  `?sort=`; no lo construyes tú. **`page.map(...)`** convierte el contenido sin perder los metadatos
  y evita exponer la entidad.
- **`@PageableDefault`** fija el tamaño cuando el cliente no lo manda, y el techo se pone aparte con
  `spring.data.web.pageable.max-page-size`: sin él, un `?size=1000000` te trae el millón de filas.

> **⏱️ Costo en runtime.** Un `Page` trae contenido **y** el total de elementos, y ese total es un
> `COUNT(*)` extra que recorre toda la tabla filtrada: en una tabla grande cuesta más que la página
> misma. Un `Slice` solo responde "¿hay siguiente?" pidiendo `size+1` filas, sin `COUNT`, así que si
> tu UI solo pinta "siguiente" elimina la mitad del trabajo de cada request.

**No se expone `Page` tal cual** porque su serialización no es parte del contrato de Spring Data,
cambió entre versiones y arrastra campos internos —`pageable`, `sort`— que nadie documentó para
consumo externo; Boot llega a avisarlo en el log, y se devuelve un `record` propio. **El cursor
sustituye al offset** cuando la profundidad importa: con offsets grandes la base descarta N filas y,
si alguien inserta mientras paginas, los elementos se repiten o se saltan; *"dame 20 con `sku` mayor
que el último"* es estable, a cambio de no poder saltar a la página 500.

---

## 10. ⚖ HATEOAS: qué es y cuándo paga

El modelo de madurez de Richardson ordena las APIs en cuatro niveles: **0**, un endpoint único y todo
por `POST` —RPC disfrazado de HTTP—; **1**, recursos con URI propia; **2**, verbos y códigos con
semántica, donde está el 95 % de las APIs; y **3**, hipermedia. El nivel 3 es HATEOAS:

```java
@GetMapping("/{sku}")
EntityModel<ItemResponse> byId(@PathVariable String sku) {
    return EntityModel.of(service.findBySku(sku),
            linkTo(methodOn(InventoryItemController.class).byId(sku)).withSelfRel(),
            linkTo(methodOn(InventoryItemController.class).list(null)).withRel("items"));
}
```

- **`EntityModel<T>`** envuelve tu DTO y le añade enlaces; `CollectionModel<T>` hace lo mismo con una
  lista, `PagedModel` añade la paginación y `RepresentationModelAssembler` saca ese armado a una clase
  reutilizable. El media type por defecto es `application/hal+json`, con `_links` y `_embedded`.
- **`linkTo(methodOn(...))`**, de `WebMvcLinkBuilder`, construye la URL **leyendo tus propios
  mapeos**, así que si cambias la ruta el enlace sigue correcto; `methodOn` devuelve un proxy que no
  ejecuta el método, solo registra cuál invocaste — el mecanismo de `05` aplicado a URIs.

El veredicto, que es lo que la pregunta de entrevista busca: **paga** cuando no controlas a quien
consume la API y cuando el flujo tiene **estado** —una transferencia que admite `confirm` o `cancel`
solo mientras está pendiente, y el enlace aparece o desaparece—. **Es ceremonia** cuando el cliente es
tu propio frontend escrito contra un OpenAPI generado: fijará las rutas igual y habrás pagado
`_links` y un assembler por recurso a cambio de nada.

> Nunca respondas: ~~"HATEOAS es lo que hace que una API sea REST de verdad"~~
>
> Mejor: "según Fielding sí: sin hipermedia es nivel 2 de Richardson, no REST. Pero casi todo lo que
> llamamos REST es nivel 2, y lo importante es saber qué nivel construyes y por qué."

> **📝 La documentación que no miente.** **springdoc-openapi** genera el contrato desde tus propias
> anotaciones —mapeos, DTOs, restricciones de Bean Validation— y lo publica en `/v3/api-docs`, con UI
> en `/swagger-ui.html`. Va fuera del BOM de Boot (serie 2.x, versión explícita), y en producción se
> expone el JSON y no la UI: esa página abierta en banca es un mapa de tu superficie de ataque.

---

## 11. ⚠️ Errores frecuentes

- **"Puse `@NotNull` y no valida."** Falta `spring-boot-starter-validation`, falta el `@Valid` en el
  argumento o el campo es primitivo. Y si lo que no valida es un `@RequestParam`, **no le pongas
  `@Validated` a la clase del controller**: desde 6.1 eso convierte el 400 de MVC en el 500 del proxy
  (`05`), y la anotación solo pertenece a los `@Service`.
- **"Devuelvo 200 con un campo `error`."** Obliga a parsear el body para saber si funcionó y rompe
  todo reintento automático. Y **el `detail` no lleva el mensaje crudo de la excepción**: filtrarías
  nombres de tabla y de columna a un cliente externo.

---

## 🧠 Preguntas rápidas

1. ¿Qué diferencia hay entre `@Valid` y `@Validated`, y cuál de las dos admite grupos?
2. Pones `@Max(100)` en un `@RequestParam` de un controller anotado con `@Validated` en la clase y la API responde 500. ¿Qué anotación sobra, y por qué el mecanismo es distinto al del `@RequestBody`?
3. Nombra las tres excepciones que puede lanzar una petición inválida según qué falló, y con qué status sale cada una por defecto.
4. Tu API responde **500** a un parámetro de query inválido. ¿Cuál es la causa más probable?
5. ¿Qué te regala extender `ResponseEntityExceptionHandler`, y qué pasa si además escribes un `@ExceptionHandler` para una excepción que esa clase base ya maneja?
6. Enumera los cinco campos estándar de un `ProblemDetail` y di cuál usa el cliente para enrutar su lógica.
7. Tu `@ControllerAdvice` no atrapa el 401 de Spring Security. Explica por qué y qué se configura en su lugar.
8. ¿Cuándo respondes 422 en vez de 400, y cuándo 404 en vez de 403?
9. ¿Quién genera la `Idempotency-Key`, y qué debe responder el servidor si la misma clave llega con un body distinto?
10. Compara `Page` y `Slice` en consultas ejecutadas, y di cuándo eliges cada uno.
11. "HATEOAS es lo que hace que una API sea REST de verdad": ¿qué tiene de cierto, y cuándo no vale la pena pagarlo?

---

## 📚 Referencias oficiales

- Spring Framework 6.2 — Validación con Bean Validation: https://docs.spring.io/spring-framework/reference/6.2/core/validation/beanvalidation.html
- Spring Framework 6.2 — Validación en métodos de controller: https://docs.spring.io/spring-framework/reference/6.2/web/webmvc/mvc-controller/ann-validation.html
- Spring Framework 6.2 — `@ExceptionHandler`: https://docs.spring.io/spring-framework/reference/6.2/web/webmvc/mvc-controller/ann-exceptionhandler.html
- Spring Framework 6.2 — Excepciones y `ProblemDetail` en APIs REST: https://docs.spring.io/spring-framework/reference/6.2/web/webmvc/mvc-ann-rest-exceptions.html
- Spring Boot 3.5 — Propiedades de configuración (`spring.mvc.problemdetails.*`, `spring.data.web.*`): https://docs.spring.io/spring-boot/3.5/appendix/application-properties/index.html
- Spring Data JPA 3.5 — Paginación, `Page` y `Slice`: https://docs.spring.io/spring-data/jpa/reference/3.5/repositories/query-methods-details.html
- Spring HATEOAS 2.5 — Referencia: https://docs.spring.io/spring-hateoas/docs/2.5.x/reference/html/

### Documentación de terceros

- RFC 9457 — *Problem Details for HTTP APIs*: https://www.rfc-editor.org/rfc/rfc9457.html
- RFC 9110 — *HTTP Semantics*, códigos de estado y cabeceras: https://www.rfc-editor.org/rfc/rfc9110.html
- springdoc-openapi — documentación oficial: https://springdoc.org/
