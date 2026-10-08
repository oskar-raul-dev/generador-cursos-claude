# L03 — API REST, filtros y errores

> **Objetivo:** que `inv-api` deje de ser un proceso que arranca y pase a ser una API que
> contesta. Al terminar sabes por qué una misma petición mal hecha sale 400, 415, 406 o
> 422, escribes un filtro de correlación sin filtrar el id a la petición siguiente, y
> puedes decir de memoria qué excepciones **nunca** verá tu `@ControllerAdvice`.
> **Asume:** [`08`](08-modelo-de-ejecucion-web.md), [`09`](09-rest-con-spring-mvc.md) y [`10`](10-diseno-de-api-validacion-errores-e-hipermedia.md) leídos. Este lab no repite su teoría: la ejecuta.
> **Prerrequisitos:** `L02` hecho. Existe `application.yml` con `inv.supplier.*`, los profiles `local` y `test`, `SupplierProperties` validado y Actuator en 8081.
> **Costo:** **$0.00**. Este lab no levanta ningún contenedor y **no hay base de datos todavía**: los datos viven en un `Map` en memoria del proceso.
> **Duración:** entre 100 y 120 minutos, de los cuales casi la mitad son los cinco errores que se provocan a propósito.
> **Qué deja levantado:** nada. `inv-api` corre mientras tú lo lanzas y muere con `Ctrl+C` o `kill %1`; ningún servicio de Compose, ningún volumen, ningún fichero fuera del proyecto.
> **Qué toca:** solo `src/`. Nace `com.invlab.invapi.inventory` con el controller, los DTOs, el
> `InventoryStore`, las excepciones y el `@RestControllerAdvice`, y nace `com.invlab.invapi.web`
> con los filtros y el interceptor. Aparece el primer test, en
> `src/test/java/com/invlab/invapi/inventory/`. De `src/main/resources/` solo cambia
> `application.yml`. Ni `pom.xml`, ni `docker-compose.yml`, ni nada fuera del proyecto.
> **Vigencia:** 17 de septiembre de 2026 · Spring Boot 3.5.16 · Spring Framework 6.2.19 · Java 21.

**Salto rápido:** [Estado inicial](#1--el-problema-y-el-estado-inicial) ·
[El dominio en un `Map`](#2--el-dominio-en-un-map-y-por-qué-no-hay-base-de-datos-todavía) ·
[Endpoints y validación](#3--los-endpoints-record-como-dto-y-validación-en-el-borde) ·
[Cinco peticiones mal hechas](#4--cinco-peticiones-mal-hechas-415-400-406-y-dos-500-que-mienten) ·
[`ProblemDetail` y el 422](#5--restcontrolleradvice-problemdetail-y-el-422) ·
[El `X-Request-Id` que se filtra](#6-️-el-x-request-id-que-se-filtra-a-la-petición-siguiente) ·
[El body destruido](#7-️-leer-el-body-en-el-filtro-y-destruirlo) ·
[La excepción que el advice no ve](#8--la-excepción-del-filtro-el-interceptor-y-quién-corre-antes) ·
[`MockMvc`](#9--mockmvc-sobre-todo-lo-anterior) ·
[Checklist](#10--checklist-de-salida) ·
[Preguntas rápidas](#-preguntas-rápidas) ·
[Ejercicios](#-ejercicios-15)

---

## 1. 🧭 El problema y el estado inicial

El ticket dice "la integración falla". El equipo de enfrente manda una captura con un
`400` y jura que su JSON está bien. Dos horas después resulta que su cliente no ponía
`Content-Type` y lo que recibía era un `415`, que en la captura se leía igual de rojo que
cualquier otro número. Nadie miró el cuerpo de la respuesta porque el cuerpo era el
`/error` de Boot y no decía nada.

El trabajo de este lab es **hacer que la API diga qué pasó**, y el camino es provocar los
cinco errores uno por uno, verlos salir crudos y solo entonces ponerles formato.

```bash
cd inv-api
./mvnw -q clean package -DskipTests
java -jar target/inv-api-0.0.1-SNAPSHOT.jar &
curl -s -o /dev/null -w '%{http_code}\n' localhost:8081/actuator/health
curl -s -o /dev/null -w '%{http_code}\n' localhost:8080/api/items
```

```text
200
404
```

- **El arranque tiene que imprimir `PROBE bound SupplierProperties[...]`.** Si no lo hace,
  el `@ConfigurationProperties` de `L02` no está enlazado y este lab construye sobre
  arena: vuelve a `L02` §6.
- **El `200` en 8081** confirma que el conector de management de `L02` sigue en su sitio;
  el **`404` en 8080** es el estado correcto de partida —Tomcat escucha, el
  `DispatcherServlet` está mapeado y no hay handler para esa ruta—. Un *Connection
  refused* significaría que falta el conector de la aplicación.
- **El `&`** deja el jar en segundo plano de esa terminal: `kill %1` lo mata y `jobs` dice
  si sigue vivo. Es el único proceso que este lab deja corriendo, y muere con la terminal.

> **🧠 Modelo mental del lab.** Todo lo que vas a escribir vive **alrededor** de un método
> de controller: antes de él los filtros, después el interceptor, y a un lado el advice que
> traduce lo que explote. El método en sí es lo más aburrido del documento, y es deliberado.

---

## 2. 🧱 El dominio en un `Map`, y por qué no hay base de datos todavía

`inv-api` gestiona items de inventario y los eventos que los mueven. Aquí viven en un `Map`
en memoria, y **no es un atajo perezoso: es una decisión de alcance**. Postgres, Flyway,
JPA y el rollback que no ocurre son el lab `L04` entero, y meterlos hoy convertiría cada
`curl` de error en una depuración de dos capas a la vez. La doctrina de reparto de
[`L00`](l00-idea-lab-practico.md) manda al lab lo que solo se entiende viéndolo fallar, y
aquí queremos ver fallar el borde HTTP.

```java
// src/main/java/com/invlab/invapi/inventory/InventoryModel.java
record InventoryItem(String sku, String name, int quantity) {
    InventoryItem withQuantity(int newQuantity) {
        return new InventoryItem(sku, name, newQuantity);   // inmutable: se reemplaza, no se muta
    }
}

record InventoryEvent(String sku, int delta, String reason) {
}
```

- **`InventoryItem` e `InventoryEvent` son los nombres fijos de la serie**: `L04` los
  persistirá en `inventory_item` e `inventory_event` sin renombrar nada.
- **Los dos son `record` y package-private** (§5.1 de la guía); dos `record` en un fichero
  son legales mientras ninguno sea público.
- **`withQuantity` devuelve una instancia nueva.** Un `record` no tiene setters, y eso aquí
  no estorba: al `Map` entran varios hilos a la vez y un objeto inmutable no se ve a medias.

```java
// src/main/java/com/invlab/invapi/inventory/InventoryStore.java
@Component
class InventoryStore {

    // un bean singleton atendido por muchos hilos: el Map TIENE que ser concurrente
    private final ConcurrentMap<String, InventoryItem> items = new ConcurrentHashMap<>();

    Optional<InventoryItem> findBySku(String sku) {
        return Optional.ofNullable(items.get(sku));
    }

    List<InventoryItem> findAll(int limit) {
        return items.values().stream().limit(limit).toList();
    }

    boolean saveIfAbsent(InventoryItem item) {
        return items.putIfAbsent(item.sku(), item) == null;   // null = no existía = se guardó
    }

    InventoryItem apply(InventoryEvent event, InventoryItem current) {
        InventoryItem updated = current.withQuantity(current.quantity() + event.delta());
        items.put(updated.sku(), updated);
        return updated;
    }
}
```

- **`@Component`, no `@Repository`**: no habla con ninguna base ni traduce excepciones de
  acceso a datos, y ponerle el otro estereotipo hoy sería mentir sobre lo que hace.
- **`ConcurrentHashMap` y no `HashMap`** por [`08` §2](08-modelo-de-ejecucion-web.md#2--una-instancia-muchos-hilos):
  hay **una** instancia del bean y hasta doscientos hilos de Tomcat entrando a la vez. Un
  `HashMap` bajo escritura concurrente no lanza una excepción clara — corrompe su tabla
  interna y un día un `get()` entra en bucle.
- **`putIfAbsent` devolviendo `null`** es la comprobación atómica de "no existía"; con
  `containsKey` seguido de `put` queda una ventana y dos peticiones crean el item dos veces.
- **`apply` no es atómico, y lo sabemos.** Dos eventos simultáneos sobre el mismo `sku`
  pueden perder un delta; en `L04` lo resuelve una transacción con `@Version`. Aquí queda
  visible a propósito y hay un ejercicio sobre ello.

> **⏱️ Costo en runtime del `Map`.** Todo el inventario vive en el heap y **crece sin
> techo**: nada lo expulsa y nada lo persiste. Con items de unos 100 bytes, un millón de
> `sku` distintos son del orden de 150–200 MB retenidos hasta que reinicies, y al reiniciar
> se pierden todos. Aceptable para dos horas de lab, y exactamente por eso existe `L04`.

---

## 3. 🧱 Los endpoints: `record` como DTO y validación en el borde

Si devuelves `InventoryItem` tal cual, el día que le añadas un campo interno —el costo de
compra, digamos— acabas de publicarlo a todos tus clientes sin enterarte. El DTO existe
para que el contrato cambie cuando tú quieras, no cuando cambie el modelo.

```java
// src/main/java/com/invlab/invapi/inventory/InventoryDtos.java
record CreateItemRequest(
        @NotBlank @Pattern(regexp = "[A-Z]{3}-[0-9]{6}") String sku,
        @NotBlank @Size(max = 80) String name,
        @Min(0) int quantity) {
}

record EventRequest(int delta, @NotBlank @Size(max = 40) String reason) {
}

record ItemResponse(String sku, String name, int quantity) {
    static ItemResponse from(InventoryItem item) {
        return new ItemResponse(item.sku(), item.name(), item.quantity());
    }
}
```

- **`@Pattern(regexp = "[A-Z]{3}-[0-9]{6}")`** fija la forma del `sku` (`ABC-000123`): es
  la restricción que más veces violaremos a propósito. **`@NotBlank` no es `@NotNull`** —
  rechaza también `""` y `"   "`, que en un DTO de entrada es casi siempre lo que quieres.
- **`delta` no lleva restricción**, a propósito: un evento puede ser positivo o negativo, y
  que el stock no quede negativo **no es validación de formato**, es regla de negocio. De
  ahí sale el 422 de la sección 5.
- **`ItemResponse.from(...)`** es el único sitio donde se traduce dominio a contrato: si
  mañana hay que ocultar un campo, se toca aquí y en ningún otro lado.

```java
// src/main/java/com/invlab/invapi/inventory/InventoryController.java
import jakarta.validation.Valid;                              // Jakarta: va en el argumento
import org.springframework.validation.annotation.Validated;   // Spring: va en la clase

@Validated
@RestController
@RequestMapping(path = "/api/items", produces = MediaType.APPLICATION_JSON_VALUE)
class InventoryController {

    private static final Logger log = LoggerFactory.getLogger(InventoryController.class);

    private final InventoryStore store;

    InventoryController(InventoryStore store) {     // inyección por constructor, sin @Autowired
        this.store = store;
    }

    @GetMapping
    List<ItemResponse> list(@RequestParam(defaultValue = "20") @Min(1) @Max(100) int limit) {
        return store.findAll(limit).stream().map(ItemResponse::from).toList();
    }

    @GetMapping("/{sku}")
    ItemResponse bySku(@PathVariable String sku) {
        log.info("consultando sku {}", sku);
        return store.findBySku(sku).map(ItemResponse::from)
                .orElseThrow(() -> new ItemNotFoundException(sku));
    }

    @PostMapping(consumes = MediaType.APPLICATION_JSON_VALUE)
    ResponseEntity<ItemResponse> create(@Valid @RequestBody CreateItemRequest request,
                                        UriComponentsBuilder uriBuilder) {
        InventoryItem item = new InventoryItem(request.sku(), request.name(), request.quantity());
        if (!store.saveIfAbsent(item)) {
            throw new DuplicateSkuException(request.sku());
        }
        return ResponseEntity.created(uriBuilder.path("/api/items/{sku}").build(item.sku()))
                .body(ItemResponse.from(item));
    }

    @PostMapping(path = "/{sku}/events", consumes = MediaType.APPLICATION_JSON_VALUE)
    ItemResponse record(@PathVariable String sku, @Valid @RequestBody EventRequest request) {
        InventoryItem current = store.findBySku(sku).orElseThrow(() -> new ItemNotFoundException(sku));
        if (current.quantity() + request.delta() < 0) {
            throw new InsufficientStockException(sku, current.quantity(), request.delta());
        }
        return ItemResponse.from(
                store.apply(new InventoryEvent(sku, request.delta(), request.reason()), current));
    }
}
```

- **`produces` a nivel de clase** declara que todos estos endpoints escriben JSON, y es lo
  que hace que un `Accept: application/xml` termine en **406** en vez de en una respuesta
  rara. **`consumes` en los `@PostMapping`** declara qué sabe leer: con él, un
  `Content-Type` equivocado ni se evalúa como candidato y sale **415**.
- **`@Validated` sobre la clase está puesta a propósito y está mal.** Es la anotación que
  todo el mundo agrega "para que valide el `limit`", y en la sección 4 vas a ver que lo que
  consigue es lo contrario: la quitaremos como corrección. La escribimos aquí —la de
  `org.springframework.validation.annotation`, y el import está escrito por eso— para poder
  romperla con la petición en la mano
  ([`10` §3](10-diseno-de-api-validacion-errores-e-hipermedia.md#3--valid-vs-validated-y-qué-excepción-lanza-cada-caso)).
  **`@Valid @RequestBody`** sí es la de Jakarta y la aplica MVC al deserializar; esa se queda.
- **`UriComponentsBuilder` como argumento** te lo inyecta MVC apuntando al host y al
  `context-path` reales; armar la `Location` a mano funciona hasta el primer balanceador.
  **`ResponseEntity.created(...)`** pone el `201` y la cabecera de una vez.
- **No hay un solo `try/catch`.** El controller no traduce errores: eso es trabajo del
  advice de la sección 5, y hasta escribirlo veremos qué hace Spring sin él.

```java
// src/main/java/com/invlab/invapi/inventory/InventoryExceptions.java
class ItemNotFoundException extends RuntimeException {
    private final String sku;
    ItemNotFoundException(String sku) { super("No existe el item con sku " + sku); this.sku = sku; }
    String sku() { return sku; }
}

class InsufficientStockException extends RuntimeException {
    private final String sku;
    private final int available;
    private final int requested;
    InsufficientStockException(String sku, int available, int requested) {
        super("El movimiento deja el stock de " + sku + " por debajo de cero");
        this.sku = sku; this.available = available; this.requested = requested;
    }
    String sku() { return sku; }
    int available() { return available; }
    int requested() { return requested; }
}
```

- **`DuplicateSkuException` es idéntica a la primera** —mismo constructor, mismo `sku()`,
  otro mensaje— y por eso no se repite aquí; escríbela igual en el mismo fichero.
- **Extienden `RuntimeException` y no `Exception`**: no obligan a declarar `throws` y
  —esto importa desde `L04`— una *unchecked* es la que dispara rollback en `@Transactional`.
- **Cada una guarda los datos del fallo**, no solo el mensaje: ese `available()` es lo que
  el advice publicará como campo de extensión, y por el texto del mensaje nadie enruta.
- **Ninguna lleva `@ResponseStatus`**, la forma corta de mapear excepción a código: reparte
  el contrato del error entre cinco ficheros y no deja poner cuerpo.

```bash
kill %1 && ./mvnw -q clean package -DskipTests && java -jar target/inv-api-0.0.1-SNAPSHOT.jar &
curl -i -X POST localhost:8080/api/items -H 'Content-Type: application/json' \
  -d '{"sku":"ABC-000123","name":"Tornillo M6","quantity":40}'
```

```text
HTTP/1.1 201
Location: http://localhost:8080/api/items/ABC-000123
Content-Type: application/json

{"sku":"ABC-000123","name":"Tornillo M6","quantity":40}
```

- **`-i`** imprime las cabeceras junto al cuerpo; en este lab casi todo lo interesante está
  en las cabeceras. **`Location` trae el host real** porque lo construyó
  `UriComponentsBuilder`, no una cadena escrita a mano.

---

## 4. 🩺 Cinco peticiones mal hechas: 415, 400, 406 y dos 500 que mienten

Las provocamos seguidas, **sin advice todavía**, para ver lo que recibe hoy el equipo de
enfrente. Antes de ejecutar, predice el código de cada una. Y arranca con el log de MVC en
`DEBUG`, que es lo que enseña la excepción de verdad:

```bash
kill %1
java -jar target/inv-api-0.0.1-SNAPSHOT.jar --logging.level.org.springframework.web=DEBUG &
```

- **Se pasa como argumento de línea de comandos**, la fuente de mayor precedencia de `L02`:
  no hace falta tocar el YAML para un diagnóstico de cinco minutos.

**415 — no sé leer tu `Content-Type`:**

```bash
curl -i -X POST localhost:8080/api/items -H 'Content-Type: text/plain' -d 'sku=ABC-000999'
```

```text
HTTP/1.1 415
Accept: application/json
Content-Type: application/json

{"timestamp":"2026-09-17T14:22:31.480+00:00","status":415,
 "error":"Unsupported Media Type","path":"/api/items"}
```

```text
DEBUG --- [nio-8080-exec-5] .w.s.m.s.DefaultHandlerExceptionResolver :
  Resolved [org.springframework.web.HttpMediaTypeNotSupportedException:
  Content-Type 'text/plain' is not supported]
```

- **El fallo ocurre en el `HandlerMapping`**, antes de elegir converter: el `consumes` de la
  clase descartó el handler como candidato, y por eso la excepción es
  `HttpMediaTypeNotSupportedException` y no algo de Jackson.
- **Spring añade la cabecera `Accept` en la respuesta** diciendo qué sí sabe leer; es la
  parte útil del 415 y casi nadie la mira.
- **La causa más frecuente no es `text/plain`**: es no mandar `Content-Type`, porque
  entonces `curl -d` pone `application/x-www-form-urlencoded` por ti.

**400 — el tipo es correcto y el contenido no.** Tres peticiones, mismo código:

```bash
curl -s -o /dev/null -w '%{http_code}\n' -X POST localhost:8080/api/items \
  -H 'Content-Type: application/json' -d '{"sku":}'
curl -s -o /dev/null -w '%{http_code}\n' -X POST localhost:8080/api/items \
  -H 'Content-Type: application/json' -d '{"sku":"abc","name":"","quantity":-5}'
```

```text
400
400
```


```text
Resolved [org.springframework.http.converter.HttpMessageNotReadableException:
  JSON parse error: Unexpected character ('}' (code 125)): expected a valid value]

Resolved [org.springframework.web.bind.MethodArgumentNotValidException: Validation failed
  for argument [0] in CreateItemRequest create(...): [Field error in object
  'createItemRequest' on field 'sku': rejected value [abc]; codes [Pattern...]]]
```

- **`HttpMessageNotReadableException`** es el JSON roto: el converter sí se eligió, corrió y
  murió en el segundo carácter. El mismo caso cubre el body ausente (`Required request body
  is missing`) y un `@PathVariable` que no convierte al tipo declarado.
- **`MethodArgumentNotValidException`** es el `@RequestBody` deserializado y rechazado por
  Bean Validation; trae la lista completa de `FieldError` —campo, valor rechazado, código de
  la restricción—, que es la materia prima del error útil de la sección 5.

> **📝 Qué cambia en la línea 4.x.** Boot 4 mueve el baseline a Jackson 3, cuyo paquete raíz
> ya no es `com.fasterxml.jackson` sino `tools.jackson`. El código sigue siendo 400 y la
> excepción de Spring sigue siendo `HttpMessageNotReadableException`, pero **cambia el
> nombre de la excepción causa que verás en el log**, y con él cualquier `grep` de tu
> runbook o cualquier `catch` escrito contra el tipo de Jackson. El detalle está en `A04`.

**El `?limit=500` merece párrafo aparte, porque no da 400.** Antes de ejecutarlo, predice: el
parámetro lleva `@Min(1) @Max(100)`, la clase lleva `@Validated`, y todo el mundo te diría que
eso son las dos piezas necesarias. Ejecútalo y compara.

```bash
curl -s -o /dev/null -w '%{http_code}\n' 'localhost:8080/api/items?limit=500'
```

Sale **500**, no 400, y el log de `DEBUG` no nombra ninguna excepción de MVC: la que sube es
`jakarta.validation.ConstraintViolationException`, con el mensaje `list.limit: debe ser menor o
igual que 100` —el prefijo es el nombre del método y el del parámetro— y sin que ningún
`HandlerExceptionResolver` la reconozca. Por eso el cuerpo que recibes es el `/error` genérico de
Boot con `"error":"Internal Server Error"`, exactamente igual que el del stock negativo que verás
más abajo.

- **La `ConstraintViolationException` es de Jakarta, no de MVC.** La lanza el interceptor de
  `MethodValidationPostProcessor` desde dentro del **proxy** que envuelve al controller (`05`), y
  para el `DispatcherServlet` es una excepción cualquiera que subió del handler.
- **Quien creó ese proxy fue tu propio `@Validated`.** Sin esa anotación en la clase no hay proxy
  alrededor del controller y nadie llega a lanzarla.

La corrección es quitar una línea. Borra el `@Validated` de `InventoryController` —y con él el
`import org.springframework.validation.annotation.Validated`, que ya no se usa—, deja las
restricciones `@Min(1) @Max(100)` donde están, y vuelve a ejecutar:

```bash
./mvnw -q clean package -DskipTests
kill %1
java -jar target/inv-api-0.0.1-SNAPSHOT.jar --logging.level.org.springframework.web=DEBUG &
curl -s -o /dev/null -w '%{http_code}\n' 'localhost:8080/api/items?limit=500'
```

Ahora sale **400**, y el log nombra
`org.springframework.web.method.annotation.HandlerMethodValidationException` resuelta por
`DefaultHandlerExceptionResolver`.

- **`./mvnw -q clean package -DskipTests`** reconstruye el jar: el proceso que corre es el
  empaquetado, no las clases del `target/classes`, así que sin repaquetar seguirías probando el
  código viejo. **`-DskipTests`** compila los tests pero no los ejecuta, que aquí ahorra el ciclo
  completo; el `verify` en verde llega en la sección 9.
- **`kill %1`** mata el jar anterior antes de levantar el nuevo. Si lo olvidas, el segundo arranque
  muere con `Port 8080 was already in use`.

> **⚠️ Esta es la trampa de entrevista del capítulo, y va en la dirección contraria a la
> intuición.** Desde Spring Framework 6.1, un controller valida por sí mismo los parámetros de
> método anotados y lanza `HandlerMethodValidationException`, que sale **400**. La reference lo
> pide con todas las letras: *"In order to take advantage of the Spring MVC built-in support for
> method validation added in Spring Framework 6.1, you need to remove the class level `@Validated`
> annotation from the controller"*. El `@Validated` no habilita la validación de parámetros en un
> controller: la **degrada** al camino de AOP y te convierte un 400 en un 500.

```text
controller sin @Validated  → valida MVC      → HandlerMethodValidationException → 400
controller con @Validated  → valida el proxy → ConstraintViolationException     → 500
@Service   con @Validated  → valida el proxy → ConstraintViolationException     → 500
```

La última fila es la que explica por qué la anotación existe: en un `@Service` no hay MVC que
valide por ti, y ahí `@Validated` sigue siendo obligatoria. Lo que cambia es el borde web.

**406 — no sé escribir lo que pides:**

```bash
curl -i localhost:8080/api/items/ABC-000123 -H 'Accept: application/xml'
```

```text
HTTP/1.1 406
Content-Length: 0
```

```text
Resolved [org.springframework.web.HttpMediaTypeNotAcceptableException:
  No acceptable representation]
```

- **406 no habla del cuerpo que mandas: habla del que pides.** El `produces` dice
  `application/json`, el cliente exigió XML, no hay intersección.
- **El cuerpo va vacío**, con lógica perversa: para explicarte el error habría que escribir
  un cuerpo, y acabas de decir que no aceptas nada que Spring sepa escribir.
- **Con `jackson-dataformat-xml` en el classpath** este mismo caso respondería 200 y XML:
  un cambio de contrato por añadir una dependencia.

**Y el cuarto, que ni siquiera tiene el código correcto:**

```bash
curl -i -X POST localhost:8080/api/items/ABC-000123/events \
  -H 'Content-Type: application/json' -d '{"delta":-500,"reason":"ajuste"}'
```

```text
HTTP/1.1 500
{"timestamp":"2026-09-17T14:25:44.118+00:00","status":500,
 "error":"Internal Server Error","path":"/api/items/ABC-000123/events"}
```

```text
ERROR --- [nio-8080-exec-8] o.a.c.c.C.[.[.[/].[dispatcherServlet] :
  Servlet.service() for servlet [dispatcherServlet] threw exception
com.invlab.invapi.inventory.InsufficientStockException: El movimiento deja el stock de
  ABC-000123 por debajo de cero
	at com.invlab.invapi.inventory.InventoryController.record(InventoryController.java:52)
	... 47 more
```

**Ese 500 es una mentira.** Le dices al cliente "el servidor se rompió" cuando su petición
era inválida: un 5xx se reintenta y un 4xx no
([`10` §6](10-diseno-de-api-validacion-errores-e-hipermedia.md#6--códigos-de-estado-con-criterio)),
así que va a recibir el mismo 500 cinco veces más, y encima tu tablero de errores 5xx sube
por culpa de alguien que escribió mal un número.

> **🩺 La autopsia, en cuatro líneas.** Cuatro peticiones, cuatro mecanismos distintos, un
> solo cuerpo de respuesta inútil:
>
> ```text
> 415  HttpMediaTypeNotSupportedException     HandlerMapping, antes del converter
> 400  HttpMessageNotReadableException        el converter corrió y falló
> 400  HandlerMethodValidationException       MVC valida los parámetros, ya sin @Validated
> 406  HttpMediaTypeNotAcceptableException    no hay representación que escribir
> 500  InsufficientStockException             nadie la tradujo: culpa nuestra
> ```

---

## 5. 🧱 `@RestControllerAdvice`, `ProblemDetail` y el 422

El 500 del `limit` ya lo arreglaste quitando una anotación. Los demás no: cuatro salen con el
código correcto y un cuerpo que no sirve, y el del stock negativo sale con el código
equivocado. Las dos cosas se arreglan en el mismo sitio.

```yaml
# src/main/resources/application.yml — añadir bajo spring:
  mvc:
    problemdetails:
      enabled: true
```

- **`spring.mvc.problemdetails.enabled: true`** hace que `ResponseEntityExceptionHandler`
  —que ya existe dentro de Spring— traduzca a `ProblemDetail` las excepciones que ya conoce.
  Su default es `false`.
- **No afecta a tus excepciones de negocio.** El 500 de `InsufficientStockException` sigue
  siendo un 500 después de ponerla, y por eso el advice de abajo sigue haciendo falta. Quien
  cree que esta propiedad "activa el manejo de errores" se lleva esa sorpresa.

```java
// src/main/java/com/invlab/invapi/inventory/InventoryExceptionHandler.java
@RestControllerAdvice(basePackages = "com.invlab.invapi.inventory")
class InventoryExceptionHandler extends ResponseEntityExceptionHandler {

    private static final String PROBLEM_BASE = "https://invlab.example/problems/";

    @ExceptionHandler(ItemNotFoundException.class)
    ProblemDetail handleNotFound(ItemNotFoundException ex) {
        ProblemDetail problem = ProblemDetail.forStatusAndDetail(HttpStatus.NOT_FOUND, ex.getMessage());
        problem.setType(URI.create(PROBLEM_BASE + "item-not-found"));
        problem.setTitle("Item no encontrado");
        problem.setProperty("sku", ex.sku());        // campo de extensión
        return problem;
    }

    @ExceptionHandler(InsufficientStockException.class)
    ProblemDetail handleInsufficientStock(InsufficientStockException ex) {
        ProblemDetail problem = ProblemDetail.forStatusAndDetail(
                HttpStatus.UNPROCESSABLE_ENTITY, ex.getMessage());
        problem.setType(URI.create(PROBLEM_BASE + "insufficient-stock"));
        problem.setTitle("Movimiento no aplicable");
        problem.setProperty("sku", ex.sku());
        problem.setProperty("available", ex.available());
        problem.setProperty("requested", ex.requested());
        return problem;
    }
}
```

- **Falta el tercero, `handleDuplicate`**, calcado del primero con `HttpStatus.CONFLICT` y
  `type` terminado en `duplicate-sku`: lo escribes tú en el ejercicio 2.
- **`@RestControllerAdvice`** es `@ControllerAdvice` + `@ResponseBody`; sin ese
  `@ResponseBody` implícito, el `ProblemDetail` devuelto se interpretaría como nombre de
  vista. **`basePackages`** acota el alcance: sin filtro el advice también atraparía
  excepciones de los endpoints de Actuator del puerto 8081.
- **Extender `ResponseEntityExceptionHandler`** te da mapeadas las excepciones estándar de
  MVC; junto con `problemdetails.enabled`, es lo que cambia el cuerpo del 415, el 400 y el
  406 sin escribir un `@ExceptionHandler` para ninguno.
- **Devolver `ProblemDetail` directamente** funciona desde Spring 6: el status sale del
  propio objeto, sin envolverlo en un `ResponseEntity`.
- **`setType(...)` es el campo importante:** un cliente enruta por `type`, que es estable;
  por `detail` no, porque describe **esta** ocurrencia y puede llevar el `sku`. Si metes el
  `sku` en el `title`, rompiste la estabilidad que el `type` promete.
- **`setProperty(...)` son campos de extensión** y salen como claves de primer nivel del
  JSON: ahí va lo tuyo, y es lo que convierte un error legible en un error procesable.
- **`UNPROCESSABLE_ENTITY` es el 422**, y es la decisión de contrato de este servicio: el
  mensaje se entendió, es sintácticamente válido y viola una regla de negocio. La escuela
  del 400 para todo también es defendible; lo que rompe integraciones es no elegir ninguna.

```bash
kill %1 && ./mvnw -q clean package -DskipTests && java -jar target/inv-api-0.0.1-SNAPSHOT.jar &
curl -s -X POST localhost:8080/api/items -H 'Content-Type: text/plain' -d 'x'
curl -i -s -X POST localhost:8080/api/items/ABC-000123/events \
  -H 'Content-Type: application/json' -d '{"delta":-500,"reason":"ajuste"}'
```

```text
{"type":"about:blank","title":"Unsupported Media Type","status":415,
 "detail":"Content-Type 'text/plain' is not supported.","instance":"/api/items"}
```

```text
HTTP/1.1 422
Content-Type: application/problem+json

{"type":"https://invlab.example/problems/insufficient-stock",
 "title":"Movimiento no aplicable","status":422,
 "detail":"El movimiento deja el stock de ABC-000123 por debajo de cero",
 "instance":"/api/items/ABC-000123/events",
 "sku":"ABC-000123","available":40,"requested":-500}
```

- **`Content-Type: application/problem+json`** en las dos: el cliente distingue un error de
  una respuesta normal **sin mirar el status**, que es medio punto de la RFC 9457. Y
  **`instance` lo rellena Spring** con la ruta de la petición, no lo pusiste tú.
- **`type: about:blank`** es lo que pone Spring cuando la excepción es estándar y nadie le
  dio un URI propio. Es válido y significa "usa el status como identificación"; para tus
  errores de negocio no vale, y por eso los tuyos llevan `type`.
- **El 500 se convirtió en 422**: el cliente sabe que no debe reintentar, y sabe cuánto
  stock hay sin consultar otra vez.

---

## 6. ⚠️ El `X-Request-Id` que se filtra a la petición siguiente

Ya tienes la API contestando y el formato del error. Lo que no tienes es forma de seguir
**una** petición entre diez mil líneas de log. Eso lo resuelve un filtro de correlación, y
es donde vive uno de los bugs más silenciosos del stack servlet.

```yaml
# src/main/resources/application.yml — añadir al final
logging:
  pattern:
    level: "%5p [%X{requestId:-sin-request-id}]"
```

- **`logging.pattern.level`** reemplaza el `%5p` del patrón por defecto de Boot: es el
  gancho pensado para esto, y evita escribir un `logback-spring.xml` entero.
- **`%X{requestId:-sin-request-id}`** lee esa clave del MDC del hilo actual e imprime el
  literal de después de `:-` cuando no hay nada. Ese literal es intencional: si lo ves en
  una línea, sabes que ese log **corrió fuera del filtro**.

```java
// src/main/java/com/invlab/invapi/web/RequestIdFilter.java — escrito mal a propósito
@Component
class RequestIdFilter extends OncePerRequestFilter {

    static final String HEADER = "X-Request-Id";

    @Override
    protected void doFilterInternal(HttpServletRequest request, HttpServletResponse response,
                                    FilterChain chain) throws ServletException, IOException {
        String requestId = request.getHeader(HEADER);
        if (requestId == null || requestId.isBlank()) {
            requestId = UUID.randomUUID().toString();
        }
        MDC.put("requestId", requestId);            // el MDC vive en un ThreadLocal
        response.setHeader(HEADER, requestId);
        chain.doFilter(request, response);          // ← falta el finally, y eso es el bug
        MDC.remove("requestId");
    }
}
```

- **`OncePerRequestFilter`** garantiza una sola ejecución por petición aunque haya
  `forward`, `include` o despacho asíncrono; un `Filter` crudo se ejecutaría varias veces y
  tu log duplicaría líneas.
- **`@Component` basta para registrarlo**, pero no fija el orden en la cadena. Cuando
  importe —y con Security delante, en [`L08` §3](l08-security-y-batch.md#3--inv-api-como-resource-server-y-el-401-que-no-explica-nada), va a importar— se registra con un
  `FilterRegistrationBean` y su `setOrder`.
- **`response.setHeader`** devuelve el id al cliente: sin eso, quien te reporta un error no
  tiene nada que pegar en el ticket. Y **`chain.doFilter(...)` es el `proceed()` de la
  cadena**: si lo olvidas, la petición muere ahí, sin excepción y con una respuesta vacía.
- **`MDC.remove` después de `doFilter` y no en un `finally`** es el bug: si el handler
  lanza, `doFilter` propaga y esa línea **no se ejecuta nunca**.

**Predice antes de ejecutar** qué `requestId` saldrá en la tercera línea:

```bash
kill %1 && ./mvnw -q clean package -DskipTests
java -jar target/inv-api-0.0.1-SNAPSHOT.jar --server.tomcat.threads.max=1 &
curl -s -o /dev/null localhost:8080/api/items/ABC-000123 -H 'X-Request-Id: bueno-1'
curl -s -o /dev/null localhost:8080/api/items/NO-EXISTE  -H 'X-Request-Id: explota-2'
curl -s -o /dev/null localhost:8080/api/items/ABC-000123 -H 'X-Request-Id: bueno-3'
```

- **`--server.tomcat.threads.max=1`** fuerza que las tres peticiones las atienda **el mismo
  hilo**. Sin eso el bug existe igual, pero solo se manifiesta cuando el pool recicla un
  hilo — que es justamente por qué en desarrollo no se ve y en producción sí.

```text
 INFO [bueno-1]   --- [nio-8080-exec-1] c.i.i.InventoryController : consultando sku ABC-000123
 INFO [explota-2] --- [nio-8080-exec-1] c.i.i.InventoryController : consultando sku NO-EXISTE
 INFO [explota-2] --- [nio-8080-exec-1] c.i.i.InventoryController : consultando sku ABC-000123
```

**La tercera línea miente.** Esa consulta la pidió `bueno-3` y el log la atribuye a
`explota-2`: el `ItemNotFoundException` de la segunda propagó por `doFilter`, se saltó el
`MDC.remove`, el hilo volvió al pool con la clave puesta y la siguiente petición la heredó.
En un incidente real esto es peor que no tener correlación: te manda a investigar la
petición equivocada con toda la confianza del mundo.

```java
        MDC.put("requestId", requestId);
        response.setHeader(HEADER, requestId);
        try {
            chain.doFilter(request, response);
        } finally {
            MDC.remove("requestId");        // el hilo se reutiliza: esto NO es opcional
        }
```

- **`finally` y no `catch`.** No queremos tragarnos la excepción —el advice tiene que
  verla—, solo limpiar; un `catch (Exception e) { }` aquí arreglaría el log y rompería el
  manejo de errores.
- **`MDC.remove` y no `MDC.clear()`**: limpia solo tu clave, para no llevarte por delante la
  que ponga mañana otro filtro.

Repite la secuencia con el `finally` puesto y la tercera línea dice `bueno-3`.

> **🧠 El modelo mental, que sirve para mucho más que el MDC.** Un `ThreadLocal` no está
> ligado a la petición: está ligado al hilo, y el hilo se reutiliza. Todo lo que pongas en
> uno —MDC, `SecurityContextHolder`, `RequestContextHolder`— hay que quitarlo en un
> `finally`. Es el razonamiento que vuelve en `L06` con `@Async` y en `L08` con el
> `SecurityContext`.

---

## 7. ⚠️ Leer el body en el filtro y destruirlo

Siguiente encargo, igual de razonable: auditoría pide que se loguee el cuerpo de todos los
`POST`. Lo escribes en diez minutos.

```java
// src/main/java/com/invlab/invapi/web/BodyLoggingFilter.java — versión que rompe la API
    @Override
    protected void doFilterInternal(HttpServletRequest request, HttpServletResponse response,
                                    FilterChain chain) throws ServletException, IOException {
        if ("POST".equals(request.getMethod())) {
            // lee el stream del request... y se lo come
            String body = new String(request.getInputStream().readAllBytes(), StandardCharsets.UTF_8);
            log.info("body entrante: {}", body);
        }
        chain.doFilter(request, response);
    }
```

- **`readAllBytes()` consume el cuerpo entero**, y parece inocente porque no modifica nada.
- **La clase es otro `OncePerRequestFilter` anotado con `@Component`**, igual que el
  anterior, y no sobrescribe `shouldNotFilter`: corre en todas las rutas.

```bash
kill %1 && ./mvnw -q clean package -DskipTests && java -jar target/inv-api-0.0.1-SNAPSHOT.jar &
curl -i -X POST localhost:8080/api/items -H 'Content-Type: application/json' \
  -d '{"sku":"XYZ-000001","name":"Arandela","quantity":5}'
```

```text
HTTP/1.1 400
Content-Type: application/problem+json

{"type":"about:blank","title":"Bad Request","status":400,
 "detail":"Failed to read request","instance":"/api/items"}
```

```text
 INFO [8f1c…] --- [nio-8080-exec-2] c.i.i.web.BodyLoggingFilter : body entrante:
   {"sku":"XYZ-000001","name":"Arandela","quantity":5}
DEBUG [8f1c…] --- [nio-8080-exec-2] .w.s.m.s.DefaultHandlerExceptionResolver :
  Resolved [org.springframework.http.converter.HttpMessageNotReadableException:
  Required request body is missing: com.invlab.invapi.inventory.ItemResponse
  com.invlab.invapi.inventory.InventoryController.create(...)]
```

**El log demuestra que el cuerpo llegó y el controller dice que no hay cuerpo.** No se
contradicen: el cuerpo de un request es un `InputStream` **de un solo uso**. Tu filtro lo
leyó hasta el final y, cuando el `HttpMessageConverter` fue a deserializar, no quedaban
bytes. Es el fallo más desconcertante del lab, porque la evidencia que tienes delante —el
log con el JSON completo— apunta en la dirección contraria.

```java
        if ("POST".equals(request.getMethod())) {
            ContentCachingRequestWrapper wrapped = new ContentCachingRequestWrapper(request);
            try {
                chain.doFilter(wrapped, response);          // se pasa EL WRAPPER, no el original
            } finally {
                String body = new String(wrapped.getContentAsByteArray(), StandardCharsets.UTF_8);
                log.info("body entrante: {}", body);        // después de que alguien lo haya leído
            }
            return;
        }
        chain.doFilter(request, response);
```

- **`ContentCachingRequestWrapper`** es un `HttpServletRequestWrapper` de Spring que guarda
  en un array los bytes **conforme alguien los consume**. Hay que pasar **el wrapper** a
  `chain.doFilter(...)`: si envuelves y sigues pasando el `request` original, no hiciste
  nada, porque el resto de la cadena no ve el wrapper.
- **`getContentAsByteArray()` antes de `doFilter` devuelve un array vacío**, porque aún no
  lo leyó nadie. Por eso el log va en el `finally`, que además garantiza que se escriba
  aunque el handler explote.
- **El `return`** evita llamar a `doFilter` dos veces; olvidarlo produce un
  `IllegalStateException` por respuesta ya comprometida que no se parece a la causa.

> **⏱️ Costo en runtime de cachear el cuerpo.** El wrapper **duplica el payload en memoria**
> por cada petición en vuelo: con cuerpos de 1 MB y 200 hilos de Tomcat saturados son
> 200 MB de heap que antes no existían, y se liberan al terminar la petición, no antes. En
> un servicio con subidas de ficheros esto tumba el proceso, así que se limita por tamaño o
> se activa solo bajo un profile de diagnóstico. Y hay un costo de contrato además del de
> memoria: nunca loguees cuerpos sin filtrar datos personales ni credenciales.

---

## 8. ⚖ La excepción del filtro, el interceptor, y quién corre antes

Tercer encargo: rechazar en el borde las peticiones sin cabecera `X-Client-Id`, para no
gastar un hilo de negocio en ellas. Como ya tienes un advice que produce `ProblemDetail`
bonito, lanzas una excepción y te vas a almorzar.

```java
// src/main/java/com/invlab/invapi/web/ClientIdFilter.java — versión que no funciona
        if (request.getHeader("X-Client-Id") == null) {
            throw new MissingClientIdException();   // ¿lo atrapará el @ControllerAdvice?
        }
        chain.doFilter(request, response);
```

- **`MissingClientIdException`** es una `RuntimeException` más, con su `@ExceptionHandler` en
  el advice devolviendo un 400 con `type` propio; el `throw` va antes de `chain.doFilter`,
  así que la petición nunca llega a MVC.

**Predice qué recibe el cliente** antes de ejecutar `curl -i localhost:8080/api/items/ABC-000123`:

```text
HTTP/1.1 500
Content-Type: text/html;charset=utf-8

<!doctype html><html lang="en"><head><title>HTTP Status 500 – Internal Server Error</title>
...
<p><b>Message</b> Falta la cabecera X-Client-Id</p>
```

```text
ERROR --- [nio-8080-exec-3] o.a.c.c.C.[.[.[/] : Exception Processing ErrorPage[errorCode=0, location=[/error]]
com.invlab.invapi.web.MissingClientIdException: Falta la cabecera X-Client-Id
	at com.invlab.invapi.web.ClientIdFilter.doFilterInternal(ClientIdFilter.java:18)
	... 41 more
```

**Ni el status, ni el cuerpo, ni el `Content-Type` son los tuyos.** Es HTML de Tomcat, con
el mensaje de tu excepción expuesto en la página —una fuga de información de manual—. La
razón la da [`08` §5](08-modelo-de-ejecucion-web.md#5--filtro-interceptor-o-advice) y es
estructural, no un fallo de configuración:

```text
petición → [ filtros ] → DispatcherServlet → controller
                              ↑  aquí vive tu @ExceptionHandler

lo lanzado a la izquierda de esa flecha sube al contenedor de servlets: tu advice ni se entera
```

> Nunca respondas: ~~"el `@ControllerAdvice` maneja todos los errores de la aplicación"~~
>
> Mejor: "maneja los que nacen dentro del `DispatcherServlet`; lo que lanza un filtro sale con
> el error del contenedor, y por eso los 401 y 403 de Security tampoco llevan tu formato."

Un filtro no lanza: **un filtro escribe la respuesta él mismo**.

```java
        if (request.getHeader("X-Client-Id") == null) {
            ProblemDetail problem = ProblemDetail.forStatusAndDetail(
                    HttpStatus.BAD_REQUEST, "Falta la cabecera X-Client-Id");
            problem.setType(URI.create("https://invlab.example/problems/missing-client-id"));
            problem.setTitle("Cliente no identificado");
            response.setStatus(HttpStatus.BAD_REQUEST.value());
            response.setContentType(MediaType.APPLICATION_PROBLEM_JSON_VALUE);
            objectMapper.writeValue(response.getOutputStream(), problem);
            return;                          // sin doFilter: la petición termina aquí
        }
```

- **`objectMapper` se inyecta por constructor**: es el mismo bean que Boot configuró para los
  converters, así que el error sale con las mismas reglas que el resto de la API. Un
  `new ObjectMapper()` aquí es la forma habitual de que las fechas del error salgan distintas.
- **`APPLICATION_PROBLEM_JSON_VALUE`** es la constante de `application/problem+json`;
  escribirla a mano funciona hasta la primera errata.
- **El `return` sin `chain.doFilter`** corta la cadena, y es la única forma legítima de que un
  filtro rechace: responder y no continuar.
- **El precio que pagas** es duplicar la construcción del `ProblemDetail` fuera del advice. Es
  real, y es el argumento honesto para mover la comprobación a un interceptor si no necesita
  correr antes que Security.

Ahora bien, el filtro tiene una carencia: **no sabe qué método va a atender la petición**.
Para medir tiempo por endpoint, o auditar solo los métodos anotados con algo, para él todo
son rutas. Ahí entra el interceptor, que corre con el handler ya resuelto.

```java
// src/main/java/com/invlab/invapi/web/HandlerTimingInterceptor.java
class HandlerTimingInterceptor implements HandlerInterceptor {

    @Override
    public boolean preHandle(HttpServletRequest request, HttpServletResponse response, Object handler) {
        request.setAttribute("startedAt", System.nanoTime());   // atributo del request, no ThreadLocal
        if (handler instanceof HandlerMethod method) {
            log.info("preHandle -> {}.{}", method.getBeanType().getSimpleName(),
                    method.getMethod().getName());
        }
        return true;                                            // false cortaría la petición aquí
    }

    @Override
    public void afterCompletion(HttpServletRequest request, HttpServletResponse response,
                                Object handler, Exception ex) {
        long elapsedMs = (System.nanoTime() - (long) request.getAttribute("startedAt")) / 1_000_000;
        log.info("afterCompletion -> status {} en {} ms, excepción: {}",
                response.getStatus(), elapsedMs, ex == null ? "ninguna" : ex.getClass().getSimpleName());
    }
}
```

- **`handler instanceof HandlerMethod`** es lo que un filtro jamás puede hacer: te da la clase
  y el método que atenderán. Para recursos estáticos el `handler` es otra cosa, de ahí el
  `instanceof` y no un cast directo.
- **`request.setAttribute(...)` y no un `ThreadLocal`**: el atributo vive y muere con la
  petición, así que no hay nada que limpiar en un `finally`. Es la lección de la sección 6 al
  revés.
- **`afterCompletion` recibe la excepción**, si la hubo, y corre **siempre**, incluso cuando el
  advice ya la tradujo. `postHandle`, que no usamos, se salta cuando hay excepción: por eso las
  métricas escritas ahí pierden justo los casos de error.

```java
// src/main/java/com/invlab/invapi/web/WebConfig.java
@Configuration
class WebConfig implements WebMvcConfigurer {

    @Override
    public void addInterceptors(InterceptorRegistry registry) {
        registry.addInterceptor(new HandlerTimingInterceptor()).addPathPatterns("/api/**");
    }
}
```

- **`WebMvcConfigurer` añade, no reemplaza**: la configuración de Boot sigue intacta y tú
  contribuyes a las listas. Poner `@EnableWebMvc` aquí desactivaría la autoconfiguración de
  MVC entera, y ese es el error que convierte "quería medir tiempos" en "se me cayeron los
  converters".
- **`addPathPatterns("/api/**")`** acota el interceptor por ruta; los filtros se acotan en otro
  sitio, con `addUrlPatterns` del `FilterRegistrationBean`. Dos mecanismos, dos sitios.

```bash
curl -s -o /dev/null localhost:8080/api/items/ABC-000123 \
  -H 'X-Client-Id: c1' -H 'X-Request-Id: orden-1'
```

```text
 INFO [orden-1] --- [nio-8080-exec-4] c.i.i.web.HandlerTimingInterceptor : preHandle -> InventoryController.bySku
 INFO [orden-1] --- [nio-8080-exec-4] c.i.i.InventoryController          : consultando sku ABC-000123
 INFO [orden-1] --- [nio-8080-exec-4] c.i.i.web.HandlerTimingInterceptor : afterCompletion -> status 200 en 3 ms, excepción: ninguna
```

- **El `requestId` aparece en las tres líneas**, incluida la del interceptor: lo puso el
  filtro, que corrió antes, y el hilo es el mismo. Esa es la prueba de que el orden filtro →
  interceptor → controller es el que dices que es.
- **Todo ocurre en `nio-8080-exec-4`**, un único hilo: el modelo thread-per-request de
  [`08` §2](08-modelo-de-ejecucion-web.md#2--una-instancia-muchos-hilos) en una captura.

| | `Filter` | `HandlerInterceptor` | `@ControllerAdvice` |
|---|---|---|---|
| Lo demostró | secciones 6 y 8 | esta sección | sección 5 |
| Sabe qué método atenderá | ❌ | ✅ | ✅ |
| Lo alcanza tu `@ExceptionHandler` | ❌ | ✅ | — |
| Puede envolver el request | ✅ | ❌ | ❌ |

> Nunca respondas: ~~"un filtro es un interceptor de Spring"~~
>
> Mejor: "un `Filter` es de la API de Servlet, corre fuera del `DispatcherServlet`, puede
> envolver el request y sus excepciones no las ve MVC; un `HandlerInterceptor` es de Spring,
> corre con el handler ya resuelto y sí participa del manejo de errores."

---

## 9. 🧪 `MockMvc` sobre todo lo anterior

Lo que comprobaste con `curl` se comprueba con un test que corre en dos segundos y no
necesita arrancar nada. Es la diferencia entre haber visto el error una vez y tener una red
que avisa cuando vuelve.

```java
// src/test/java/com/invlab/invapi/inventory/InventoryControllerTest.java
@WebMvcTest(InventoryController.class)
@Import(InventoryStore.class)
class InventoryControllerTest {

    @Autowired
    private MockMvc mockMvc;

    @Test
    void devuelve_problem_detail_en_404() throws Exception {
        mockMvc.perform(get("/api/items/NO-EXISTE").header("X-Client-Id", "c1"))
                .andExpect(status().isNotFound())
                .andExpect(content().contentTypeCompatibleWith(MediaType.APPLICATION_PROBLEM_JSON))
                .andExpect(jsonPath("$.type").value("https://invlab.example/problems/item-not-found"))
                .andExpect(jsonPath("$.sku").value("NO-EXISTE"));
    }

    @Test
    void devuelve_422_cuando_el_stock_queda_negativo() throws Exception {
        mockMvc.perform(post("/api/items").header("X-Client-Id", "c1")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {"sku":"ABC-000123","name":"Tornillo M6","quantity":1}"""))
                .andExpect(status().isCreated());

        mockMvc.perform(post("/api/items/ABC-000123/events").header("X-Client-Id", "c1")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {"delta":-9,"reason":"ajuste"}"""))
                .andExpect(status().isUnprocessableEntity())
                .andExpect(jsonPath("$.available").value(1))
                .andExpect(jsonPath("$.requested").value(-9));
    }

    @Test
    void devuelve_el_request_id_que_mandaste() throws Exception {
        mockMvc.perform(get("/api/items/NO-EXISTE")
                        .header("X-Request-Id", "test-1").header("X-Client-Id", "c1"))
                .andExpect(header().string("X-Request-Id", "test-1"));
    }
}
```

- **`@WebMvcTest(InventoryController.class)`** es un *slice*: levanta el `DispatcherServlet`,
  los converters, los `@ControllerAdvice`, los `Filter` y los `WebMvcConfigurer`, y **nada
  más**. No arranca Tomcat, no crea `DataSource`, no instancia tus `@Service`; un
  `@SpringBootTest` aquí tardaría cinco veces más para probar lo mismo.
- **Los filtros sí entran en el slice**, y eso sorprende a todo el mundo: por eso el tercer
  test comprueba la cabecera sin arrancar nada, y por eso **todas** las peticiones mandan
  `X-Client-Id` — el `ClientIdFilter` de la sección 8 también está activo.
- **`@Import(InventoryStore.class)`** mete el almacén, que es un `@Component` y no entra en el
  slice. Como este lab no tiene base de datos, importarlo es la opción honesta; cuando en
  `L04` haya un repositorio de verdad, ahí es donde entra `@MockitoBean`.
- **`jsonPath("$.sku")`** navega el cuerpo JSON sin deserializarlo, y
  **`contentTypeCompatibleWith`** evita comparar la cadena exacta del `Content-Type`, que se
  rompe cuando aparece el `charset`.

```bash
./mvnw -q test
```

```text
[INFO] Tests run: 3, Failures: 0, Errors: 0, Skipped: 0
[INFO] BUILD SUCCESS
```

> **💡 Truco que se paga solo.** Vuelve a quitar el `finally` del `RequestIdFilter` y corre
> `./mvnw -q test`: el tercer test **sigue pasando**, porque cada test estrena hilo. El bug de
> la sección 6 no lo atrapa un test de este tipo, y saberlo vale más que el test: hay clases
> de fallo que solo se ven con carga y con un hilo reutilizado, y por eso `curl` no sobra.

---

## 10. 📋 Checklist de salida

- [ ] `./mvnw -q clean package` termina en verde con los tres tests pasando.
- [ ] Un `POST` válido con `Content-Type: application/json` y `X-Client-Id` devuelve `201` con cabecera `Location`.
- [ ] Un `Content-Type: text/plain` devuelve `415` con `Content-Type: application/problem+json`.
- [ ] Un JSON roto devuelve `400` y el log nombra `HttpMessageNotReadableException`.
- [ ] `InventoryController` **no** tiene `@Validated` en la clase, y `?limit=500` devuelve `400` con `HandlerMethodValidationException` en el log — no `500` con `ConstraintViolationException`.
- [ ] Un `Accept: application/xml` devuelve `406` con cuerpo vacío.
- [ ] Un evento que deja el stock negativo devuelve `422` con los campos `sku`, `available` y `requested`.
- [ ] Un `sku` inexistente devuelve `404` con `type` igual a `https://invlab.example/problems/item-not-found`.
- [ ] La respuesta trae de vuelta el `X-Request-Id` que mandaste.
- [ ] Con `--server.tomcat.threads.max=1`, tres peticiones seguidas (la segunda fallando) imprimen tres `requestId` **distintos**.
- [ ] Un `POST` válido sigue funcionando con `BodyLoggingFilter` activo, y el log imprime el cuerpo.
- [ ] Una petición sin `X-Client-Id` devuelve `400` en `application/problem+json`, no HTML de Tomcat.
- [ ] El log de `/api/items/{sku}` muestra `preHandle` → controller → `afterCompletion`, los tres con el mismo `requestId`.
- [ ] `docker compose -p inv-lab ps` no lista nada y `jobs` no lista ningún `java -jar`; si lo lista, `kill %1`.

---

## 🧠 Preguntas rápidas

1. Un cliente manda `POST /api/items` con un JSON perfecto y recibe `415`. ¿Qué le falta a su
   petición, y en qué componente de MVC se decidió ese código?
2. Enfrenta `415`, `406` y `400`: di en una frase qué no puede hacer el servidor en cada caso,
   y cuál de los tres habla de la **respuesta** y no de la petición.
3. "El `@ControllerAdvice` maneja todos los errores de la aplicación." Corrige la frase y di
   qué dos familias de errores se le escapan en este lab.
4. `spring.mvc.problemdetails.enabled=true` está puesto y tu `InsufficientStockException` sigue
   saliendo como 500 con formato `/error`. ¿Por qué no se contradicen las dos cosas?
5. ¿Qué diferencia hay entre `type`, `title`, `detail` e `instance` de un `ProblemDetail`, y
   por cuál de los cuatro debe enrutar un cliente?
6. El `MDC.remove` está después de `chain.doFilter` y no en un `finally`. Describe la secuencia
   exacta de tres peticiones que produce una línea de log con el id equivocado.
7. ¿Por qué el bug de la pregunta anterior casi nunca se ve en una máquina de desarrollo y sí
   en producción?
8. Tu filtro loguea el cuerpo y el controller responde `Required request body is missing`. ¿Qué
   recurso se consumió, y por qué el log que demuestra que el cuerpo llegó no contradice al
   error?
9. Con `ContentCachingRequestWrapper`, ¿por qué `getContentAsByteArray()` devuelve un array
   vacío si lo llamas antes de `chain.doFilter(...)`?
10. ¿Cuál es la única forma correcta de que un `Filter` rechace una petición, y por qué lanzar
    una excepción no lo es?
11. Nombra dos cosas que un `HandlerInterceptor` puede hacer y un `Filter` no, y una que solo
    puede hacer el `Filter`.
12. `postHandle` y `afterCompletion`: ¿cuál se salta cuando el handler lanza una excepción, y
    qué consecuencia tiene eso para unas métricas de latencia?
13. Quitas el `finally` del `RequestIdFilter` y `./mvnw -q test` sigue en verde. ¿Qué propiedad
    del entorno de test lo explica, y qué clase de bugs no cubre un `MockMvc`?

---

## 🧪 Ejercicios (15)

### 🟢 Fácil — repetir lo del lab con otra ruta o con otro valor  (1–4)

#### 🟢 Ejercicio 1 — el quinto código

Añade un `DELETE /api/items/{sku}` que devuelva `204 No Content` cuando borra y `404` con tu
`ProblemDetail` cuando el `sku` no existe. Compruébalo con `curl -i`.
**Objetivo:** ver que una respuesta sin cuerpo es una decisión de contrato y no un descuido, y
que un `204` con cuerpo es ilegal.

#### 🟢 Ejercicio 2 — el 409 que ya existe

Crea dos veces el mismo `sku` y verifica que la segunda devuelve `409` con `type` terminado en
`duplicate-sku`.
**Objetivo:** comprobar que el advice cubre un caso que no ejecutaste al escribirlo, y fijar
cuándo 409 gana a 422.

#### 🟢 Ejercicio 3 — el `Accept` que sí funciona

Repite el `curl` del 406 con `Accept: application/json`, con `Accept: */*` y sin cabecera
`Accept`, y anota los tres códigos.
**Pregunta:** ¿por qué dos de los tres dan el mismo resultado, y qué hace `curl` por ti cuando
no pones `Accept`?

#### 🟢 Ejercicio 4 — el `limit` por los dos extremos

Con el controller ya sin `@Validated`, prueba `?limit=0`, `?limit=100`, `?limit=101` y
`?limit=abc` con `logging.level.org.springframework.web=DEBUG`, y anota código y excepción de
cada uno. Después vuelve a poner `@Validated` en la clase y repite los cuatro.
**Objetivo:** distinguir `HandlerMethodValidationException` de
`MethodArgumentTypeMismatchException` cuando las dos salen 400, y comprobar cuál de los cuatro
casos cambia de código al reintroducir el proxy — y cuál no, porque ni siquiera llega al método.

### 🟡 Intermedio — aplicarlo a otro mecanismo  (5–8)

#### 🟡 Ejercicio 5 — el 400 de validación, con formato

Sobrescribe `handleMethodArgumentNotValid` para que el `ProblemDetail` traiga un campo de
extensión `errors` con la lista de campos inválidos y su mensaje. Compruébalo con un body que
tenga `sku` y `name` malos a la vez.
**Objetivo:** convertir la lista de `FieldError` que la excepción ya trae en algo que un
formulario pueda pintar, sin inventar un formato nuevo.

#### 🟡 Ejercicio 6 — el filtro con orden explícito

Registra `RequestIdFilter` con un `FilterRegistrationBean` en `HIGHEST_PRECEDENCE` limitado a
`/api/*`, y `ClientIdFilter` justo después. Demuestra con el log que el rechazo por falta de
`X-Client-Id` **ya sale con `requestId`** y que antes no salía.
**Objetivo:** entender que el orden de los filtros decide qué contexto tiene disponible un
rechazo temprano, que es literalmente el problema de Security en `L08`.

#### 🟡 Ejercicio 7 — cachear también la respuesta

Añade `ContentCachingResponseWrapper` al `BodyLoggingFilter` para loguear el cuerpo de la
respuesta, y verifica que la respuesta **sigue llegando al cliente**.
**Pregunta:** ¿qué método hay que llamar obligatoriamente al final para que el cuerpo cacheado
se escriba de verdad, y qué ves si lo olvidas?

#### 🟡 Ejercicio 8 — el interceptor que corta

Haz que `preHandle` devuelva `false` y escriba un `429` con `ProblemDetail` cuando el mismo
`X-Client-Id` supere cinco peticiones por minuto, contando en un `ConcurrentHashMap`.
Compruébalo con un bucle de `curl`.
**Objetivo:** ver que cortar en `preHandle` obliga a escribir tú la respuesta igual que en un
filtro, y decidir por qué esto va en un interceptor y no en un filtro.

### 🟠 Difícil — combinar, diagnosticar o decidir  (9–13)

#### 🟠 Ejercicio 9 — el 500 que nadie tradujo

Añade un `@ExceptionHandler(Exception.class)` de red final que responda `500` con
`ProblemDetail` **sin exponer el mensaje** de la excepción, registre el stack trace en `ERROR`
y meta el `requestId` del MDC como campo de extensión. Provoca un `NullPointerException` y
verifica que el cliente recibe un id buscable en el log.
**Objetivo:** cerrar el círculo entre correlación y manejo de errores, que es lo que hace que
un ticket de soporte sea resoluble.

#### 🟠 Ejercicio 10 — la carrera del `Map`

Con un bucle de `curl` en paralelo, manda 200 eventos de `delta: 1` sobre el mismo `sku` y
comprueba si la cantidad final es 200.
**Pregunta:** ¿por qué `ConcurrentHashMap` no basta aquí, qué método de `ConcurrentMap`
arreglaría el `apply`, y qué mecanismo distinto usará `L04` para el mismo problema?

#### 🟠 Ejercicio 11 — el advice que se pasa de listo

Quita `basePackages` del `@RestControllerAdvice` y provoca un error en un endpoint de Actuator
del puerto 8081, por ejemplo `/actuator/env/clave.que.no.existe`. Compara la respuesta con y
sin el filtro de alcance.
**Objetivo:** entender el alcance real de un advice y por qué acotarlo no es purismo, sino
evitar que tu formato de negocio se cuele en el canal de diagnóstico.

#### 🟠 Ejercicio 12 — reproducir la fuga sin bajar el pool

Quita otra vez el `finally` del `RequestIdFilter` y demuestra la fuga **sin**
`--server.tomcat.threads.max=1`: usa concurrencia suficiente y `grep` sobre el log para
encontrar dos peticiones distintas con el mismo `requestId`.
**Objetivo:** convencerte de que el hilo único era una ayuda didáctica y no la causa del bug,
que es la confusión por la que estos fallos se cierran como "no reproducible".

#### 🟠 Ejercicio 13 — 400 o 422, elige y documenta

Decide por escrito, para `inv-api`, qué familia de errores sale 400 y cuál 422, incluyendo el
caso de `@Pattern` sobre el `sku` y el de stock negativo. Ajusta el código a tu decisión y deja
los tests que la blindan.
**Objetivo:** tener una respuesta propia y sostenible a "¿400 o 422?", que no tiene respuesta
única pero sí tiene respuestas mal argumentadas.

### 🔴 Muy difícil — abierto o adversarial  (14–15)

#### 🔴 Ejercicio 14 — la API saboteada

Te entregan este controller, que compila y arranca, con un ticket que dice "la validación no
funciona y los errores salen en 500":

```java
@RestController
@RequestMapping("/api/v2/items")
class BrokenController {

    @PostMapping
    ItemResponse create(@Valid CreateItemRequest request) { ... }

    @GetMapping("/{sku}")
    ItemResponse byId(@PathVariable @Size(min = 3) String sku) { ... }

    @ExceptionHandler(ItemNotFoundException.class)
    String handle(ItemNotFoundException ex) { return ex.getMessage(); }
}
```

Sin ejecutarlo, escribe **cuatro** defectos distintos con su síntoma exacto y el código de
estado que produce cada uno. Después ejecútalo y compara.
**Objetivo:** leer un controller como lo lee MVC. Los cuatro defectos están cubiertos en este
lab y en `09`; si fallas alguno, ya sabes qué sección releer.

#### 🔴 Ejercicio 15 — el filtro que nadie pidió

Alguien añadió un filtro de terceros que hace tres cosas: lee el body para firmarlo, mete el
`clientId` en un `ThreadLocal` propio sin limpiarlo, y lanza una excepción cuando la firma no
cuadra. La API empieza a devolver `400 Required request body is missing` de forma intermitente,
los logs atribuyen peticiones al cliente equivocado y los rechazos de firma salen en HTML.
Escribe el informe de diagnóstico: para cada síntoma, la hipótesis, el comando o el log que la
confirma, la corrección, y la regla de code review que lo habría evitado.
**Objetivo:** producir la autopsia completa de §9.4 de la guía sobre un caso que reúne los tres
fallos de este lab en un solo archivo, que es como aparecen en la vida real.

### 🔥 Opcionales y ampliaciones

- **HATEOAS, una vez.** Añade `spring-boot-starter-hateoas` y devuelve
  `EntityModel<ItemResponse>` con un enlace a sí mismo y otro a los eventos; compara el cuerpo
  `application/hal+json` con el JSON plano y contrasta tu veredicto con el de `10` §10. Queda
  fuera del alcance base de este lab a propósito, igual que la paginación, el versionado,
  `Idempotency-Key` y OpenAPI: son diseño de contrato y se estudian en `10`.
- **`server.error.include-*`.** Juega con `include-message`, `include-stacktrace` e
  `include-binding-errors` sobre el `/error` de Boot y comprueba qué se filtra al cliente con
  cada combinación. Es el camino corto a una fuga de información.
- **Negociación por extensión.** Averigua por qué `GET /api/items/ABC-000123.xml` ya no negocia
  por extensión en Spring 6 y qué propiedad lo controlaba antes.
- **Un `SseEmitter`, para verlo no bloquear.** Añade `GET /api/items/events` devolviendo un
  `SseEmitter` de cinco minutos y publica un evento por cada `POST /api/items`. Con `curl -N`
  conectado, toma un `jcmd <pid> Thread.print` y comprueba que ningún hilo `http-nio-8080-exec-*`
  está retenido por el stream; después deja el constructor sin argumento y mide a los cuántos
  segundos se corta. Mecanismo, timeout y veredicto en
  [`14` §2](14-tiempo-real-sse-y-websocket.md#2--sseemitter-la-respuesta-que-no-termina-en-mvc);
  por qué WebSocket no tiene lab, en [`L00` §3](l00-idea-lab-practico.md#3--el-catálogo-de-exclusiones-una-por-una).

### 💀 Boss fight — el contrato de error de `inv-api`, entregado

Entrega el contrato de error completo de `inv-api` como un artefacto que otro equipo pueda
consumir sin preguntarte nada, cumpliendo todo esto a la vez:

- Un documento de una página con la **tabla de `type` → status → cuándo ocurre → campos de
  extensión**, cubriendo al menos `item-not-found`, `duplicate-sku`, `insufficient-stock`,
  `validation-failed`, `missing-client-id` y el 500 genérico.
- Todos esos errores salen en `application/problem+json`, **incluidos los que nacen en un
  filtro**, y todos traen el `requestId` como campo de extensión y como cabecera
  `X-Request-Id` de respuesta.
- Un solo test parametrizado que recorre la tabla entera: para cada caso lanza la petición con
  `MockMvc` y verifica status, `type` y presencia de los campos declarados. Si mañana alguien
  cambia un `type`, el test falla.
- El filtro de correlación tiene su `finally`, el de body usa `ContentCachingRequestWrapper` y
  ninguno de los dos lanza excepciones.
- Un `README` de tres párrafos para el equipo consumidor: cómo enrutar por `type`, por qué no
  debe parsear `detail`, y qué hacer con un 422 frente a un 500.

**Objetivo:** convertir nueve secciones de mecanismo en un contrato defendible, que es
exactamente el artefacto que un Tech Lead entrega cuando dice "nuestra API tiene un formato de
error único".

---

## 🏁 La señal de que quedó bien

`inv-api` responde `201`, `400`, `404`, `406`, `409`, `415` y `422` según corresponda, y
**todos los errores llevan `Content-Type: application/problem+json`** con un `type` por el que
un cliente puede enrutar. Tres peticiones seguidas con un solo hilo de Tomcat, la del medio
fallando, imprimen tres `requestId` distintos. Un `POST` con el filtro de auditoría activo
sigue llegando entero al controller, y una petición sin `X-Client-Id` recibe JSON y no HTML de
Tomcat. `./mvnw -q test` pasa en verde en un par de segundos, `jobs` no lista ningún proceso en
segundo plano y `docker compose -p inv-lab ps` no lista nada, porque este lab tampoco levantó
un contenedor.

El siguiente lab, `L04`, cambia el `Map` por Postgres con Flyway y JPA, y lo primero que hace
con estos mismos endpoints es demostrar un `@Transactional` que no hace rollback.

---

## 📚 Referencias oficiales

- Spring Framework 6.2 — Annotated Controllers: https://docs.spring.io/spring-framework/reference/6.2/web/webmvc/mvc-controller.html
- Spring Framework 6.2 — `HttpMessageConverter` y content negotiation: https://docs.spring.io/spring-framework/reference/6.2/web/webmvc/message-converters.html
- Spring Framework 6.2 — Validación en métodos de controller: https://docs.spring.io/spring-framework/reference/6.2/web/webmvc/mvc-controller/ann-validation.html
- Spring Framework 6.2 — `@ExceptionHandler`: https://docs.spring.io/spring-framework/reference/6.2/web/webmvc/mvc-controller/ann-exceptionhandler.html
- Spring Framework 6.2 — Excepciones REST y `ProblemDetail`: https://docs.spring.io/spring-framework/reference/6.2/web/webmvc/mvc-ann-rest-exceptions.html
- Spring Framework 6.2 — Filtros (`OncePerRequestFilter`, `ContentCachingRequestWrapper`): https://docs.spring.io/spring-framework/reference/6.2/web/webmvc/filters.html
- Spring Framework 6.2 — Interceptores: https://docs.spring.io/spring-framework/reference/6.2/web/webmvc/mvc-servlet/handlermapping-interceptor.html
- Spring Framework 6.2 — MVC Config (`WebMvcConfigurer`): https://docs.spring.io/spring-framework/reference/6.2/web/webmvc/mvc-config.html
- Spring Framework 6.2 — `MockMvc`: https://docs.spring.io/spring-framework/reference/6.2/testing/mockmvc.html
- Spring Boot 3.5 — Aplicaciones web servlet y manejo de errores: https://docs.spring.io/spring-boot/3.5/reference/web/servlet.html#web.servlet.spring-mvc.error-handling
- Spring Boot 3.5 — Slices de test y `@WebMvcTest`: https://docs.spring.io/spring-boot/3.5/reference/testing/spring-boot-applications.html#testing.spring-boot-applications.spring-mvc-tests
- Spring Boot 3.5 — Índice de propiedades (`spring.mvc.*`, `server.error.*`, `logging.pattern.*`): https://docs.spring.io/spring-boot/3.5/appendix/application-properties/index.html

### Documentación de terceros

- RFC 9457 — *Problem Details for HTTP APIs*: https://www.rfc-editor.org/rfc/rfc9457.html
- RFC 9110 — *HTTP Semantics*, códigos de estado y cabeceras: https://www.rfc-editor.org/rfc/rfc9110.html
- Java 21 — `ConcurrentHashMap`: https://docs.oracle.com/en/java/javase/21/docs/api/java.base/java/util/concurrent/ConcurrentHashMap.html
