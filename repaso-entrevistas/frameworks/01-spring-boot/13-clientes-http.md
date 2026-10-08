# 13 — Clientes HTTP

> **Objetivo:** elegir cliente HTTP con criterio, ponerle timeouts y pool antes de la primera
> llamada, y no dejar nunca una llamada saliente sin presupuesto de tiempo.
> **Asume:** [`08`](08-modelo-de-ejecucion-web.md), [`09`](09-rest-con-spring-mvc.md).
> **Vigencia:** 18 de septiembre de 2026 · Spring Boot 3.5.16 · Spring Framework 6.2.19 · Java 21.

> **📝 Dónde termina este capítulo.** Llego hasta el **timeout y el pool**, que son configuración
> del cliente; lo que se apila encima —retry, circuit breaker, bulkhead, Resilience4j— es [`19`](19-resiliencia.md).
> `WebClient` aparece como cliente, pero `Mono`, `Flux` y los schedulers son de [`11`](11-webflux-y-reactor.md).

---

## 1. 🧭 El problema: tu servicio también es un cliente

En [`09`](09-rest-con-spring-mvc.md) `inv-api` era el que atendía; ahora es el que llama: para
responder `GET /api/items/{sku}` necesita la cotización de `inv-supplier`, en
`https://inv-supplier.invlab.example`. Eso cambia el problema de sitio, porque ya no controlas
cuánto tarda la respuesta y **la latencia del otro se convierte en tu disponibilidad**. Spring te
da cinco formas de escribir esa llamada y ninguna protege sola, así que empiezo por el parámetro.

---

## 2. ⏱️ No hay timeout por defecto, y ese es el tema

`inv-api` corre sobre Tomcat con los 200 hilos de [`08` §2](08-modelo-de-ejecucion-web.md#2--una-instancia-muchos-hilos),
y `inv-supplier` responde en 80 ms hasta que un martes a las once se degrada a 30 segundos. Haz
la cuenta antes de seguir leyendo:

```text
respuesta normal   80 ms  →  200 hilos / 0,08 s  = 2 500 req/s de capacidad
respuesta enferma  30 s   →  200 hilos / 30 s    = 6,6 req/s de capacidad

con 100 req/s entrando: los 200 hilos se ocupan en 2 s, la accept-count de 100
se llena en 1 s más, y desde el tercer segundo el cliente ve "connection
refused" — no un 503.
```

- **Nadie se cayó.** No hubo excepción: los hilos siguen vivos esperando bytes de un socket
  abierto, y en el `threaddump` los ves todos en `sun.nio.ch.SocketDispatcher.read0` —el nombre
  moderno; el `SocketInputStream.socketRead0` de los runbooks viejos desapareció en JDK 13—. Sin
  timeout, 30 segundos tampoco es el techo: si el otro acepta y no escribe, esperas siempre.
- **Se cae el servicio entero, no el endpoint lento**, porque el pool de hilos es compartido:
  los endpoints que ni tocan a `inv-supplier` dejan de responder también. El `/health` sobrevive
  solo si lo separaste con `management.server.port=8081`, que le da su propio conector ([`23` §3](23-actuator-y-observabilidad.md#3--el-puerto-de-management-separado)).

> **⏱️ Costo en runtime.** Una llamada saliente sin `read-timeout` cuesta **un hilo de
> plataforma (≈1 MB de pila) y una conexión del pool durante todo el tiempo que el otro quiera
> tardar**. Ponerle techo es lo que convierte la degradación ajena en un error tuyo acotado.

Por eso [`16` §8](16-transacciones.md#8--el-límite-de-la-transacción-no-es-el-límite-de-tu-método)
prohíbe llamar a un proveedor dentro de una transacción: ahí retienes también la conexión a la
base de datos durante los mismos 30 segundos.

> Nunca respondas: ~~"el timeout por defecto es razonable"~~. Mejor: **no hay timeout de lectura
> por defecto; el default es esperar para siempre, y ese valor lo pone quien escribe el cliente.**

---

## 3. 🧱 `RestClient`: el default del curso

`RestClient` llegó en Spring Framework 6.1 (Boot 3.2): bloqueante, fluido y con los
`HttpMessageConverter` de [`09` §7](09-rest-con-spring-mvc.md#7--httpmessageconverter-y-jackson), así que Jackson se comporta igual aquí.

```java
record SupplierQuote(String sku, BigDecimal price, Instant quotedAt) { }   // DTO, no entidad
@Service
class SupplierGateway {
    private final RestClient restClient;

    SupplierGateway(RestClient.Builder builder) {   // builder autoconfigurado, no se hace new
        this.restClient = builder.baseUrl("https://inv-supplier.invlab.example").build();
    }

    SupplierQuote quote(String sku) {
        return restClient.get()
                .uri("/suppliers/{sku}/quote", sku)   // el {sku} se escapa; no concatenes
                .retrieve()
                .body(SupplierQuote.class);
    }
}
```

- **`RestClient.Builder` se inyecta, no se instancia:** Boot expone uno `prototype` ya
  configurado, y `RestClient.create()` devuelve uno crudo, sin tus converters ni los
  `RestClientCustomizer`. **`baseUrl`** hace relativa cada `uri()`.
- **`uri("/suppliers/{sku}/quote", sku)`** expande la plantilla y **codifica** el valor: si
  concatenas, un `sku` con `/` o `?` te cambia la ruta. **`retrieve()`** ejecuta, y
  **`body(Class)`** deserializa —con cuerpo vacío devuelve `null`, no lanza—.
- **Cuando el retorno es genérico**, `SupplierQuote.class` no alcanza porque el borrado de
  tipos se lleva el parámetro: se usa
  `body(new ParameterizedTypeReference<List<SupplierQuote>>() { })`, cuyas llaves finales no
  son decoración sino la subclase anónima que conserva el genérico en el bytecode. Con
  `List.class` obtendrías una `List<LinkedHashMap>` y un `ClassCastException` lejos de la
  llamada, en la primera línea que use un campo — que es lo que lo hace caro de depurar.

---

## 4. 🧱 La `ClientHttpRequestFactory`: timeouts y pool

El `RestClient` no habla TCP: delega en una `ClientHttpRequestFactory`, y **ahí viven los dos
timeouts y el pool**. Boot 3.5 la detecta por classpath —Apache HttpClient 5, Jetty, Reactor
Netty, el del JDK, `HttpURLConnection`— y la configura sin escribir una clase:

```yaml
spring:
  http:
    client:
      factory: jdk              # fuerza una de las cinco; por defecto, la detectada
      connect-timeout: 2s       # techo para ABRIR la conexión
      read-timeout: 3s          # techo entre dos bloques de bytes de la respuesta
      redirects: dont-follow
```

- **`connect-timeout: 2s`** cubre el handshake TCP y TLS: se agota cuando el host no existe, el
  puerto está cerrado o un firewall se come los paquetes, y falla rápido y uniforme.
- **`read-timeout: 3s`** es el que importa y el que falta siempre, y es un techo **por lectura**,
  no por llamada: una respuesta que gotea cada 2,9 segundos no lo dispara nunca. El techo de la
  llamada entera lo pone el `TimeLimiter` de `19`.
- **`redirects: dont-follow`** evita que un `302` del proveedor te lleve a un host que nadie
  autorizó. Y **si omites los timeouts** decide la librería, y ninguna de las dos decide bien:
  el `HttpClient` del JDK no impone ninguno —ni de conexión ni de lectura—, y Apache
  HttpClient 5 impone **3 minutos de conexión y ninguno de lectura**. Es decir: por defecto,
  en las dos, una respuesta que nunca llega te retiene el hilo para siempre.

El pool es la otra mitad y no se configura con propiedades: es de la librería. Apache
HttpClient 5 trae **25 conexiones en total y 5 por host**, y eso choca con 200 hilos de Tomcat.

La excepción que sale es `org.apache.hc.core5.http.ConnectionRequestTimeoutException`, y
tarda en salir lo que valga el *connection request timeout* —3 minutos por defecto en HC5—,
así que el primer síntoma no es el error sino la espera.

- **Qué significa:** 195 hilos esperan turno para una de las 5 conexiones hacia `inv-supplier`.
  La latencia que mides es cola de pool, no lentitud del proveedor, y subir los hilos de Tomcat
  la empeora. **Keep-alive** reutiliza esas conexiones en vez de rehacer el handshake TLS en
  cada llamada; con un `idle` mayor que el del otro extremo, reutilizas un socket ya cerrado.
- **El máximo por host *es* el número de llamadas concurrentes** a ese proveedor: una decisión
  de capacidad, y de paso el primer bulkhead que tienes, aunque el explícito sea de `19`.

> **🩺 Diagnóstico.** Antes de tocar `server.tomcat.threads.max`, mira `/actuator/threaddump`:
> los hilos en `SocketDispatcher.read0` son timeout que falta; los que esperan en
> `PoolingHttpClientConnectionManager.lease`, pool. Mismo síntoma, arreglos opuestos.

---

## 5. 🧱 Interceptores: logging y cabeceras que viajan

Un `traceId` que no cruza la llamada saliente rompe la traza en el borde de tu servicio. Eso no
se copia en cada método: se pone una vez en el cliente, con un `ClientHttpRequestInterceptor`.

```java
class OutboundContextInterceptor implements ClientHttpRequestInterceptor {
    @Override
    public ClientHttpResponse intercept(HttpRequest request, byte[] body,
                                        ClientHttpRequestExecution execution) throws IOException {
        String traceId = MDC.get("traceId");      // el MDC cuelga del hilo del request
        if (traceId != null) {
            request.getHeaders().add("X-Trace-Id", traceId);
        }
        return execution.execute(request, body);  // si no lo invocas, la petición no sale
    }
}
```

- **`execution.execute(...)`** es el "llama al siguiente", la forma del `FilterChain` de
  [`08` §4](08-modelo-de-ejecucion-web.md#4--la-cadena-de-filtros) del lado del cliente. Corre
  en el hilo que hace la llamada, que es el del request: por eso `MDC.get` funciona aquí y no
  funcionaría dentro de un `@Async` sin propagación de contexto ([`18` §5](18-asincronia-scheduling-y-eventos.md#5--propagación-de-contexto-lo-que-se-queda-en-el-hilo-del-request)).
- **No leas el cuerpo de la respuesta aquí:** el stream se consume una sola vez y el `body(...)`
  posterior encontraría cero bytes. Loguearlo exige `BufferingClientHttpRequestFactory`, que
  retiene la respuesta entera en memoria — en `DEBUG` y bajo demanda, nunca por defecto. En
  `WebClient` el equivalente es `ExchangeFilterFunction`, y allí el contexto no viaja en un
  `ThreadLocal` sino en el contexto reactivo ([`11`](11-webflux-y-reactor.md)).

---

## 6. 🩺 Errores: un 4xx no es un fallo de red

`retrieve()` lanza por defecto ante cualquier 4xx o 5xx, pero **no todas las excepciones
significan lo mismo**: tratarlas juntas produce el bug clásico de reintentar un 404 cuatro
veces.

```java
SupplierQuote quote(String sku) {
    return restClient.get()
            .uri("/suppliers/{sku}/quote", sku)
            .retrieve()
            .onStatus(status -> status.value() == 404,
                    (req, res) -> { throw new UnknownSkuException(sku); })
            .body(SupplierQuote.class);
}
```

- **`onStatus(predicado, handler)`** reemplaza el comportamiento por defecto para los estados que
  casen, y el handler recibe la respuesta cruda: el cuerpo de error se lee ahí.
- **Sin `onStatus`** se lanza `HttpClientErrorException` (4xx) o `HttpServerErrorException`
  (5xx), hijas de `RestClientResponseException`, que expone `getStatusCode()` y
  `getResponseBodyAsString()`. **`ResourceAccessException` es otra rama**: envuelve una
  `IOException` y significa que **no hubo respuesta** —timeout, DNS, socket cerrado—.

```text
RestClientResponseException  4xx → el error es tuyo: sku inexistente, token vencido, payload
                                   inválido. Hubo respuesta y hay contrato. No se reintenta.
                             5xx → el error es suyo. Reintentable si eres idempotente.
ResourceAccessException          → nadie contestó. Es transporte. Reintentable con cuidado.
```

Un 404 no es un fallo de disponibilidad: meterlo en el mismo saco que un timeout es lo que abre
un circuit breaker por un `sku` mal escrito (`19`).

---

## 7. 🧱 HTTP Interfaces: declarativo y de Spring

Escribir a mano diez métodos que solo cambian la ruta cansa y se desincroniza del contrato.
Desde Spring Framework 6.0 hay una forma declarativa **en el propio framework**: una interfaz
con `@HttpExchange` de la que Spring genera el proxy.

```java
import org.springframework.web.bind.annotation.PathVariable;   // el MISMO del lado servidor
import org.springframework.web.service.annotation.GetExchange;

interface SupplierClient {
    @GetExchange("/suppliers/{sku}/quote")
    SupplierQuote quote(@PathVariable String sku);
}

@Bean
SupplierClient supplierClient(RestClient.Builder builder) {
    RestClient client = builder.baseUrl("https://inv-supplier.invlab.example").build();
    // RestClientAdapter es bloqueante; WebClientAdapter devuelve Mono/Flux con la misma interfaz
    return HttpServiceProxyFactory.builderFor(RestClientAdapter.create(client))
            .build().createClient(SupplierClient.class);
}
```

- **`@GetExchange` y su familia `@HttpExchange`** no son `@GetMapping`: aquellas declaran lo que
  expones, estas lo que consumes. Los parámetros, en cambio, **sí reutilizan las anotaciones del
  lado servidor**, y por eso el import importa: es lo único que distingue esto de un controller.
- **`HttpServiceProxyFactory`** crea un proxy JDK sobre la interfaz, el mismo mecanismo de
  [`05`](05-proxies-y-aop.md) que sostiene todo lo declarativo del curso. Quien ejecuta la
  llamada es el `RestClient` que le pasaste, en el hilo del llamante, y **los timeouts y el pool
  siguen siendo los suyos**: lo declarativo no configura nada, solo tapa la llamada.

---

## 8. 🧱 Feign, que es lo que vas a encontrar

En banca la mitad de los servicios llaman con Feign, así que hay que saber leerlo. Feign es una
librería de Netflix y **Spring Cloud OpenFeign** es el envoltorio que la integra con Spring, con
su propio BOM alineado por release train con la línea de Boot.

> Nunca respondas: ~~"Feign es de Spring"~~. Mejor: **Feign es de Netflix; lo de Spring es
> Spring Cloud OpenFeign, en modo mantenimiento desde 2022 y sin funcionalidad nueva.**

```java
@FeignClient(name = "inv-supplier",
             url = "${inv.supplier.base-url}",
             configuration = SupplierFeignConfig.class)
interface SupplierFeignClient {
    @GetMapping("/suppliers/{sku}/quote")
    SupplierQuote quote(@PathVariable("sku") String sku);
}
```

Los timeouts van por cliente en
`spring.cloud.openfeign.client.config.inv-supplier.connect-timeout: 2000` y su `read-timeout`
hermano: la rama es el `name` del `@FeignClient` y el valor son milisegundos planos, no un
`Duration` como en `spring.http.client.*`.

- **`@EnableFeignClients`** dispara el escaneo; sin ella las interfaces no son beans y el
  arranque falla por candidato ausente. **`name`** identifica al cliente en la configuración y
  en las métricas; **`url`** lo fija a un host, y sin él el `name` se resuelve contra service
  discovery, que este curso no usa.
- **`configuration = SupplierFeignConfig.class`** es por cliente y **no se anota con
  `@Configuration`**: si la anotas, sus beans se aplican a todos los clientes a la vez, y es el
  error más frecuente de Feign. **`@PathVariable("sku")` con el nombre explícito** sí hace
  falta: Feign no lee los nombres de parámetro del bytecode.
- **Si no pones timeouts**, el default de Feign es **10 s de conexión y 60 s de lectura**, que
  es peor que no tener ninguno porque parece configurado.
- **Los errores se traducen con un `ErrorDecoder`**, que ocupa el lugar del `onStatus` de §6:
  `decode(methodKey, response)` **devuelve** la excepción —no la lanza, de eso se encarga
  Feign— y delega el resto en `FeignException.errorStatus(...)`. Sin él, todo 4xx y 5xx llega
  como `FeignException` y distinguir el 404 obliga a mirar `status()` en un `catch`.

**Cuándo migrar a HTTP Interfaces.** Si empiezas hoy, `@HttpExchange` hace lo mismo sin Spring
Cloud, sin release train y con los timeouts de Boot. Si ya tienes veinte `@FeignClient` no hay
urgencia: la interfaz es casi idéntica y el trabajo real está en los `ErrorDecoder`, así que
migras el que toques por otra razón. **En 4.x** Spring añade el registro declarativo de estas
interfaces, lo que estrecha aún más el caso de Feign (`A04`).

---

## 9. ⚖ Los cinco, y el veredicto

| Cliente | Modelo | Qué añade | Cuándo lo eliges |
|---|---|---|---|
| `RestClient` | bloqueante, fluido | converters de Boot, `onStatus` | default de todo código nuevo |
| `WebClient` | reactivo, usable bloqueante | streaming, SSE, fan-out | app WebFlux o llamadas en paralelo |
| `RestTemplate` | bloqueante, imperativo | nada nuevo desde 2017 | código existente que no vas a tocar |
| HTTP Interfaces | declarativo, sobre los dos | interfaz tipada, proxy de Spring | muchos endpoints del mismo proveedor |
| Feign | declarativo, Spring Cloud | `ErrorDecoder`, config por cliente | lo que ya está escrito en tu banco |

> Nunca respondas: ~~"`RestTemplate` está deprecado"~~. Mejor: **está en modo mantenimiento
> desde Spring 5.0 y no lleva ninguna anotación `@Deprecated`: recibe correcciones, no
> funcionalidad. Por eso el código nuevo va con `RestClient` y nadie reescribe lo que funciona.**

Dos matices de entrevista. **`WebClient` en una aplicación MVC** es legítimo: disparas tres
llamadas en paralelo y esperas con `block()`, así que el hilo del request sigue bloqueado — no
te volviste reactivo, ganaste concurrencia en el fan-out ([`12`](12-reactivo-bloqueante-y-virtual-threads.md)). Y **`RestClient` no es
"`RestTemplate` con builder"**: su API es la de `WebClient`, y por eso pasar de uno al otro es
casi mecánico y desde `RestTemplate` no lo es.

Queda una decisión de diseño: `RestClient.Builder` es `prototype`, así que tú eliges cuántos
clientes construidos existen.

- **Uno por dependencia externa**, que es el veredicto del curso: `supplierRestClient`,
  `pricingRestClient`, cada uno con su `baseUrl`, sus timeouts y su factory, y por tanto **su
  propio pool**. Cuando `inv-supplier` se degrada agota el suyo y no el del vecino: aislamiento
  por configuración, gratis y anterior a cualquier patrón de `19`.
- **Uno compartido** solo si todas las salidas tienen el mismo perfil de latencia y el mismo
  presupuesto, que casi nunca es cierto; el síntoma de equivocarse es una dependencia lenta
  hundiendo llamadas a otra sana. Los interceptores transversales sí se comparten bien, y un
  `RestClientCustomizer` los aplica a todos los builders.

> **📝 Testing, en una nota.** `MockRestServiceServer` (con `@RestClientTest`) sustituye la
> `ClientHttpRequestFactory` por una falsa: verifica URI, método y cuerpo, pero **no ejerce ni el
> timeout ni el pool**, porque no hay socket. `MockWebServer` y WireMock sí abren un puerto real
> y son los únicos que reproducen el incidente de §2 — mecanismo en [`24` §4](24-testing.md#4--los-slices-qué-autoconfigura-cada-uno-y-qué-deja-fuera), reproducción en [`L05`](l05-clientes-y-resiliencia.md).

---

## 10. ⚠️ Errores frecuentes

- **"Le subo los hilos a Tomcat y aguanta."** Sin timeout, más hilos es más cola esperando lo mismo; con timeout puesto, casi nunca hace falta subirlos.
- **"Configuré el timeout en el `RestClient`."** Vive en su `ClientHttpRequestFactory`, y un
  `RestClient.create()` suelto ignora `spring.http.client.*`: no pasa por la autoconfiguración.
- **"Capturo `Exception` y devuelvo `null`."** Convierte una dependencia caída en datos faltantes silenciosos aguas abajo; un fallback es una decisión explícita, y es de `19`.
- **"Cada `@Service` construye el suyo."** Multiplica pools sin que nadie sepa cuántas conexiones
  abre el servicio; los clientes se declaran como `@Bean`.

---

## 🧠 Preguntas rápidas

1. Con 200 hilos y un proveedor que pasa a tardar 30 segundos, ¿qué falla y en qué orden hasta
   que el cliente ve "connection refused"?
2. ¿Qué cubre `connect-timeout`, qué cubre `read-timeout` y por qué ninguno acota la llamada?
3. "`RestTemplate` está deprecado": corrige la afirmación con precisión.
4. ¿De quién es Feign y qué parte de lo que usas sí es de Spring?
5. Distingue `RestClientResponseException` de `ResourceAccessException`: ¿cuál es reintentable?
6. ¿Por qué un 404 no debería contar como error de disponibilidad de la dependencia?
7. Con 200 hilos y Apache HttpClient 5 en sus defaults, ¿cuántas llamadas llegan a la vez a
   `inv-supplier` y qué excepción ven las demás?
8. ¿Qué hace `ParameterizedTypeReference` que no puede hacer `List.class`, y dónde explota?
9. Alguien loguea el cuerpo dentro de un `ClientHttpRequestInterceptor` y el `body(...)` empieza
   a devolver `null`: ¿qué pasó y cómo se corrige?
10. ¿Qué diferencia hay entre `@GetExchange` y `@GetMapping`, y qué anotaciones sí comparten?
11. Un `@FeignClient` cuya configuración lleva `@Configuration`: ¿qué efecto indeseado tiene?
12. ¿Por qué un `RestClient` por dependencia externa y no uno compartido? ¿Qué síntoma delata la
    elección equivocada?
13. Tu test con `MockRestServiceServer` pasa y el servicio se cuelga por un proveedor lento:
    ¿por qué no lo detectó?

---

## 📚 Referencias oficiales

- Spring Framework 6.2 — Clientes REST (`RestClient`, `RestTemplate`): https://docs.spring.io/spring-framework/reference/6.2/integration/rest-clients.html
- Spring Framework 6.2 — HTTP Interface (`@HttpExchange`): https://docs.spring.io/spring-framework/reference/6.2/integration/rest-clients.html#rest-http-interface
- Spring Framework 6.2 — Request factories y timeouts: https://docs.spring.io/spring-framework/reference/6.2/integration/rest-clients.html#rest-request-factories
- Spring Framework 6.2 — `WebClient`: https://docs.spring.io/spring-framework/reference/6.2/web/webflux-webclient.html
- Spring Framework 6.2 — `MockRestServiceServer`: https://docs.spring.io/spring-framework/reference/6.2/testing/spring-mvc-test-client.html
- Spring Boot 3.5 — Llamar a servicios REST y configuración global del cliente: https://docs.spring.io/spring-boot/3.5/reference/io/rest-client.html

### Documentación de terceros

- Spring Cloud OpenFeign 4.3 — referencia: https://docs.spring.io/spring-cloud-openfeign/reference/4.3/spring-cloud-openfeign.html
- Apache HttpClient 5 — documentación del proyecto: https://hc.apache.org/httpcomponents-client-5.6.x/index.html
- WireMock — documentación: https://wiremock.org/docs/
