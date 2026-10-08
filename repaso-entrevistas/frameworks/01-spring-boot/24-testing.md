# 24 — Testing

> **Objetivo:** escribir la prueba **más barata** que conteste la pregunta que tienes, y
> saber por qué la suite tarda ocho minutos y qué la devuelve a uno.
> **Asume:** [`03`](03-inyeccion-de-dependencias.md) —sin inyección por constructor la mitad
> de este capítulo no es posible—, [`05`](05-proxies-y-aop.md) y [`15`](15-datos-jdbc-jpa-mongo-y-redis.md).
> **Vigencia:** 19 de septiembre de 2026 · Spring Boot 3.5.16 · Spring Framework 6.2.19 · Java 21.

---

## 1. 🧭 El problema: ocho minutos de suite que no prueban lo que crees

Tu proyecto tiene 140 tests, todos con `@SpringBootTest` porque «así se prueba de verdad». La
suite tarda ocho minutos, nadie la corre antes de hacer push, y el día que un `@Transactional`
deja de hacer rollback en producción sigue en verde. Las dos cosas tienen la misma causa:
**nadie eligió el nivel de prueba, se eligió el más cómodo de escribir**. La pirámide no es un
dogma moral: cada nivel contesta una pregunta distinta y cuesta distinto.

| Nivel | La pregunta que contesta | Lo que **no** detecta | Arranque |
|---|---|---|---|
| Unitario, sin contenedor | ¿mi lógica es correcta? | todo lo que Spring hace por ti | ~0 ms |
| Slice (`@WebMvcTest`, `@DataJpaTest`…) | ¿mi clase encaja con **una** capa? | lo que pasa entre capas | cientos de ms |
| `@SpringBootTest` | ¿el contexto entero levanta y coopera? | red, puerto, base real | segundos |
| `RANDOM_PORT` + Testcontainers | ¿funciona contra HTTP y Postgres de verdad? | el cluster y el vecino | segundos + imagen |

> **🧠 Modelo mental.** Cada test compra una garantía y paga con segundos de arranque. Elegir el
> nivel es elegir **qué garantía necesitas hoy**, no qué anotación recuerdas.

---

## 2. 🧱 El test unitario: sin contenedor, y por qué puedes escribirlo

El motivo por el que `03` insiste en la inyección por constructor aparece aquí: si la
dependencia entra por el constructor, el objeto se construye con `new` y no hace falta ningún
`ApplicationContext`.

```java
@ExtendWith(MockitoExtension.class)
class InventoryServiceTest {
    @Mock InventoryRepository repository;   // mock de Mockito, no de Spring
    @Test void rechazaCantidadNegativa() {
        InventoryService service = new InventoryService(repository);   // sin contenedor
        assertThatThrownBy(() -> service.record(new InventoryEvent("SKU-1", -3)))
                .isInstanceOf(IllegalArgumentException.class);
        verifyNoInteractions(repository);   // y no llegó a tocar la base
    }
}
```

- **`@ExtendWith(MockitoExtension.class)`** es de Mockito, no de Spring: inicializa los `@Mock` y
  aplica *strict stubs*, que fallan con `UnnecessaryStubbingException` cuando dejas un
  `when(...)` que nadie usa — una red contra tests que pasan probando otra cosa.
- **`@Mock` no es `@MockitoBean`:** `@Mock` te entrega a ti un objeto simulado; `@MockitoBean`
  (§5) **sustituye un bean dentro del contexto de Spring**.
- **`assertThatThrownBy`** es AssertJ 3.27.7: el starter `spring-boot-starter-test` trae esa
  librería, JUnit 5.12.2, Mockito 5.17.0, Awaitility 4.2.2, JSONassert, JsonPath, Hamcrest y
  XMLUnit, todas con la versión que fija el BOM de 3.5.16.

> Nunca respondas: ~~"si pasan los tests unitarios, el servicio funciona"~~ · Mejor: "los unitarios
> prueban mi lógica; **no prueban nada de lo que Spring hace por mí** —proxies, transacciones,
> serialización, rutas, seguridad—, y ahí viven estos bugs."

---

## 3. 🧱 `@SpringBootTest` y sus cuatro `webEnvironment`

`@SpringBootTest` busca tu `@SpringBootApplication`, carga **el contexto entero** y lo mete en
la caché de contextos (§6). Es el más caro y el único que contesta "¿arranca?".

| `webEnvironment` | Qué levanta | Con qué se prueba |
|---|---|---|
| `MOCK` (default) | contexto web **sin servidor**: ni socket ni puerto | `MockMvc` / `WebTestClient` |
| `RANDOM_PORT` | servidor embebido en un puerto libre | `TestRestTemplate`, `WebTestClient` |
| `DEFINED_PORT` | servidor embebido en `server.port` | lo mismo, con riesgo de colisión |
| `NONE` | contexto **no** web | nada de HTTP |

- **`MOCK` no arranca Tomcat**, registra un entorno servlet simulado: por eso es rápido y no prueba
  el conector ni el [`09` §10 — apagado ordenado](09-rest-con-spring-mvc.md#10--prefijo-de-despliegue-y-apagado-ordenado).
- **Con `RANDOM_PORT` el puerto lo inyecta `@LocalServerPort`** y tienes un `TestRestTemplate`
  listo para `@Autowired`, **tolerante a fallos a propósito**: un 4xx o un 5xx **no lanzan
  excepción**, se leen del `ResponseEntity` — su diferencia con el `RestTemplate` de [`13`](13-clientes-http.md).
- **`NONE` es el que se olvida**, y es el correcto para un job de Batch o una autoconfiguración.

> **⏱️ Costo.** Levanta todos los beans —pool de Hikari abierto, Flyway migrando, caché, scheduler,
> cadena de filtros— y son **segundos por contexto distinto**, no por test: el tema de §6.

---

## 4. ⚖ Los slices: qué autoconfigura cada uno y qué deja fuera

Un *slice* carga **una rebanada**: la infraestructura de una capa y nada más. La regla que
comparten todos, y que explica casi todas las sorpresas: **los `@Component`, `@Service` y
`@Repository` normales no se escanean**.

| Slice | Autoconfigura | Deja fuera |
|---|---|---|
| `@WebMvcTest` | `MockMvc`, `@Controller`, `@ControllerAdvice`, `Filter`, `HandlerInterceptor`, converters | servicios, repositorios, `DataSource` |
| `@WebFluxTest` | `WebTestClient`, `@Controller`, `@ControllerAdvice`, `WebFluxConfigurer` | lo mismo, en el stack de [`11`](11-webflux-y-reactor.md) |
| `@DataJpaTest` | `DataSource`, `EntityManager`, `TestEntityManager`, repositorios, `@Entity` | controllers y servicios; **es transaccional y revierte** |
| `@JdbcTest` | `DataSource`, `JdbcTemplate`/`JdbcClient` | los repositorios de Spring Data |
| `@DataMongoTest` | `MongoTemplate`, `@Document`, repositorios de Mongo | **no es transaccional**: lo que escribes se queda |
| `@JsonTest` | el `ObjectMapper` real, `@JsonComponent`, `JacksonTester` | todo lo demás |
| `@RestClientTest` | `RestClient.Builder`, `RestTemplateBuilder`, `MockRestServiceServer` | lo que no declares en `components` |

```java
@WebMvcTest(InventoryController.class)
class InventoryControllerTest {
    @Autowired MockMvc mockMvc;
    @MockitoBean InventoryService service;   // el servicio real no está en este contexto
    @Test void devuelve404CuandoNoExiste() throws Exception {
        given(service.findBySku("SKU-404")).willThrow(new ItemNotFoundException("SKU-404"));
        mockMvc.perform(get("/api/inventory/items/SKU-404"))
               .andExpect(status().isNotFound())
               .andExpect(jsonPath("$.title").value("Item no encontrado"));
    }
}
```

- **`@WebMvcTest(InventoryController.class)`** limita el slice a ese controller; sin argumento carga
  **todos**, y cada uno exige sus mocks o el contexto no levanta.
- **`@MockitoBean InventoryService`** es obligatorio —el slice no escanea servicios—: sin él el
  arranque falla con `NoSuchBeanDefinitionException` dentro de un `IllegalStateException: Failed to
  load ApplicationContext`.
- **`jsonPath("$.title")`** comprueba el `ProblemDetail` de
  [`10` §5](10-diseno-de-api-validacion-errores-e-hipermedia.md#5--problemdetail-y-rfc-9457): el
  slice **sí** ejecuta tu `@ControllerAdvice` y los `HttpMessageConverter`, que es la costura que
  quieres probar; lo que no detecta es que el servicio real lance otra excepción.
- **`@DataJpaTest` reemplaza tu `DataSource` por uno embebido** si hay uno en el classpath
  (`@AutoConfigureTestDatabase` trae `replace = NON_TEST`): es la línea que te mete H2 sin
  pedirlo (§9).

---

## 5. 🧱 `@MockitoBean` y `@MockitoSpyBean`: sustituir un bean, no un objeto

Cuando el test **sí** carga un contexto no puedes pasar el mock por constructor: el bean lo crea
el contenedor. `@MockitoBean` registra un *bean override*.

```java
@SpringBootTest
class InventoryServiceIT {
    @MockitoBean SupplierClient supplier;        // sustituye el bean entero por un mock
    @MockitoSpyBean InventoryRepository repos;   // envuelve el bean REAL y lo espía
    @Autowired InventoryService service;
    @Test void registraYNotifica() {
        service.record(new InventoryEvent("SKU-1", 5));
        verify(repos).save(any(InventoryEvent.class));   // el save real ocurrió
        verify(supplier).notifyChange("SKU-1");          // esta llamada no salió a la red
    }
}
```

- **`@MockitoBean` sustituye:** el bean original ni se usa y todo método devuelve el valor por
  defecto (`null`, `0`, lista vacía) hasta que lo programes. **`@MockitoSpyBean` envuelve:** el bean
  real trabaja y tú miras. Se resetean entre métodos.
- **Aquí vuelve [`05`](05-proxies-y-aop.md): al sustituir el bean sustituyes su proxy.** Si moqueas
  un bean anotado con `@Transactional`, `@Cacheable` o `@Retryable`, el mock no tiene ese
  comportamiento —ni transacción, ni caché, ni reintento— y el test pasa sin probar lo que creías. Y
  **cada mock cambia el contexto** (§6): declararlos «por si acaso» se paga en minutos de suite.

> **📝 `@MockBean` está deprecada y hay que saberlo con fecha.** El javadoc de Boot 3.5.16 la
> declara literalmente `@Deprecated(since = "3.4.0", forRemoval = true)`, igual que `@SpyBean`. Las
> sustitutas viven en **Spring Framework** (`org.springframework.test.context.bean.override.mockito`)
> y su javadoc dice `Since: 6.2`: llegaron con Framework 6.2 / Boot 3.4, del mecanismo genérico de
> *bean overriding*. **En 4.x ya no existen** —el paquete `org.springframework.boot.test.mock.mockito`
> desapareció— y los slices cambiaron de paquete (`@WebMvcTest` vive hoy en
> `org.springframework.boot.webmvc.test.autoconfigure`).

---

## 6. ⏱️ La caché de contextos: aquí se van los ocho minutos

El `TestContext` framework **no levanta un contexto por clase de test**: los guarda en una caché
estática y los reutiliza, de modo que dos clases con la misma configuración pagan el arranque una
vez. La clave de esa caché se construye con estos parámetros y ningún otro:

```text
classes / locations / contextInitializerClasses  de @ContextConfiguration
contextCustomizers  ← @DynamicPropertySource y los bean overrides:
                      @MockitoBean, @MockitoSpyBean, @TestBean
activeProfiles      de @ActiveProfiles   ·   propertySource… de @TestPropertySource
contextLoader · parent · resourceBasePath
```

- **Cambiar cualquiera de ellos crea un contexto nuevo:** añadir un `@MockitoBean` en una clase y no
  en otra ya son dos contextos, dos arranques.
- **La caché admite 32 contextos** por defecto y desaloja por LRU; se ajusta con la propiedad de
  sistema `spring.test.context.cache.maxSize`, pero subirla trata el síntoma: cada contexto vivo
  retiene su pool y su heap ⏱️. Y **si el build hace fork por test la caché no existe** —es una
  variable estática de la JVM—: con el `forkMode` de Surefire en `always` se pierde entre clases.
- **`@DirtiesContext` es el último recurso**, no una limpieza preventiva: marca el contexto como
  corrupto, lo cierra y lo saca de la caché. Se justifica cuando un test modifica una *bean
  definition* o deja estado global inservible; «por higiene» convierte la caché en decorado.
- **De ahí las reglas de configuración.** `@ActiveProfiles("test")` con un `application-test.yaml`
  compartido es lo barato; `@TestPropertySource(properties = "inv.supplier.timeout=200ms")`
  sobrescribe una clave suelta con prioridad muy alta, a cambio de un contexto por valor distinto; y
  `@DynamicPropertySource` —método `static void` que recibe un `DynamicPropertyRegistry` y registra
  **suppliers** con `registry.add(clave, () -> valor)`— es lo único que sirve para un puerto que no
  existe hasta que arranca el contenedor (§9).
- **`@TestConfiguration` no es `@Configuration`.** Una `@Configuration` suelta la recoge el
  component scan y contamina **todos** los contextos; una `@TestConfiguration` anidada se aplica
  solo ahí, y una de nivel superior solo cuando la importas con `@Import`.

> **🩺 Cómo se mide el daño, en una línea.** Sube a `DEBUG` la categoría
> `org.springframework.test.context.cache`: la suite dice cuántos contextos cargó, cuántos aciertos
> tuvo y cuántos desalojó. Si ese número se parece al de clases de test, ya tienes la respuesta.

---

## 7. ⚖ `MockMvc`, `WebTestClient` y `TestRestTemplate`

| | Cómo llama | Qué prueba de más | Qué no prueba |
|---|---|---|---|
| `MockMvc` | invoca el `DispatcherServlet`, sin socket | rutas, converters, `@ControllerAdvice`, filtros | conector, servidor, red |
| `WebTestClient` | cliente reactivo, contra contexto simulado **o** puerto real | lo mismo, y es el natural en WebFlux | depende del modo |
| `TestRestTemplate` | HTTP real contra el puerto embebido | conector, serialización sobre el cable | nada de dentro |

- **El veredicto:** `MockMvc` por defecto en MVC —órdenes de magnitud más rápido y cubre lo que
  sueles romper—, `WebTestClient` siempre en WebFlux, y `TestRestTemplate` solo cuando el punto del
  test **es** que haya un socket; `MockMvcTester` (`Since: 6.2`) es lo mismo con AssertJ.
- **La trampa con seguridad:** `MockMvc` por sí solo no ejecuta la cadena de filtros, así que tus
  reglas nunca corren y el test pasa — el falso verde más peligroso del capítulo, desarrollado en
  [`20` §12](20-spring-security-el-mecanismo.md#12--probarlo-sin-levantar-un-proveedor-de-identidad).

---

## 8. ⚠️ `@Transactional` en el test: el rollback que oculta bugs

Un test anotado con `@Transactional` —y `@DataJpaTest` lo está— abre una transacción antes del
método y **hace rollback al terminar**. La base queda limpia sin escribir un `delete`. Es cómodo,
y es el punto ciego más grande de la suite:

- **Tu servicio en producción hace commit; tu test no.** Lo que solo falla al confirmar —una
  constraint diferida, un trigger, un `flush` que Hibernate nunca ejecutó— no ocurre aquí: verde en
  el test, violación de integridad en producción.
- **Test y código comparten persistence context**, así que los lazy loads funcionan en el test y
  explotan con `LazyInitializationException` en producción
  ([`15` §7](15-datos-jdbc-jpa-mongo-y-redis.md#7-️-lazyinitializationexception-y-open-in-view)); y
  como ya hay una transacción abierta, un método `REQUIRED` se une a la del test y tampoco estás
  observando la propagación de [`16` §4](16-transacciones.md#4--propagación).
- **Con `RANDOM_PORT` no aplica en absoluto:** el servidor atiende en **otro hilo** y la transacción
  del test está atada al hilo del test
  ([`16` §2](16-transacciones.md#2--el-modelo-y-quién-lo-invoca)), así que lo que escriba el servidor
  se confirma y hay que limpiarlo con `@Sql`. Para lo contrario: `@Commit` y `@Rollback(false)`.

> Nunca respondas: ~~"pongo `@Transactional` en los tests, que es buena práctica"~~ · Mejor: "lo uso
> para aislar tests de lectura; cuando lo que pruebo es el commit o la propagación, lo quito y
> limpio los datos explícitamente."

---

## 9. 🧱 Testcontainers y `@ServiceConnection`, y por qué no H2

H2 arranca en milisegundos y por eso mucha gente lo usa para «probar la capa de datos». El problema
es que H2 **no es Postgres**: no tiene `jsonb`, su comportamiento con los bloqueos es otro, sus
secuencias y su `ON CONFLICT` difieren y su dialecto acepta SQL que Postgres rechaza. El resultado
no es un test que falla: es uno que pasa y un bug que aparece en producción.

```java
@SpringBootTest
@Testcontainers
class InventoryRepositoryIT {
    @Container
    @ServiceConnection   // deriva spring.datasource.* del contenedor, sin escribir nada
    static PostgreSQLContainer<?> postgres = new PostgreSQLContainer<>("postgres:17.11");

    @Autowired InventoryRepository repository;
}
```

- **`@Container` sobre un campo `static`** arranca el contenedor una vez por clase; sobre un campo
  de instancia, uno por método — así se llega a una suite de veinte minutos ⏱️.
- **`@ServiceConnection`** (`Since: 3.1.0` en el javadoc de Boot) lee el contenedor y registra
  `spring.datasource.url`, `username` y `password`; antes se escribía a mano con
  `@DynamicPropertySource` (§6). **Además desactiva el reemplazo por H2:** como el `DataSource` ya
  apunta a una base de prueba, el `replace = NON_TEST` de §4 no lo sustituye, y por eso
  `@DataJpaTest` con Testcontainers funciona sin anotaciones extra. La imagen lleva **tag exacto**,
  nunca `:latest`.
- **El costo honesto:** la primera ejecución descarga la imagen (cientos de MB) y cada arranque
  cuesta uno o dos segundos. Se amortiza compartiendo el contenedor entre clases o con contenedores
  reutilizables, que exigen `withReuse(true)` **y** habilitarlo en el `~/.testcontainers.properties`
  de tu máquina.

> **⚠️ Testcontainers no es «lento»: es honesto.** Lo lento es arrancar un contenedor y lo pagas una
> vez por clase; H2 no es rápido, es **otra base de datos**. Si tu capa de datos es `JdbcClient` con
> SQL de Postgres, un test contra H2 no prueba tu SQL — y el laboratorio ya levanta ese Postgres en
> Compose (`L04`), así que la comparación no es teórica.

---

## 10. 🧪 Seguridad, resiliencia, asincronía y reactivo

- **Seguridad.** `spring-security-test` —en el BOM, scope `test`— aporta `@WithMockUser` y los
  post-processors `with(user(…))` y `with(csrf())`; lo importante es que la cadena **corra**, y con
  `@AutoConfigureMockMvc` se registra sola. Para un resource server JWT
  ([`21`](21-identidad-federada-oauth2-oidc-y-jwt.md)) se emite un token de mentira en vez de levantar
  un IdP, que es lo que hace [`L08` §3](l08-security-y-batch.md#3--inv-api-como-resource-server-y-el-401-que-no-explica-nada).
- **Resiliencia.** Un timeout o un circuito abierto ([`19`](19-resiliencia.md)) necesitan
  **latencia**, y ni `MockRestServiceServer` ni un `@MockitoBean` la producen: responden al instante.
  Se prueba con un stub HTTP que sabe tardar —WireMock, que es lo que usa `L05`— o forzando la
  transición del `CircuitBreaker`. Y ojo con §5: si moqueas el bean anotado, moqueaste su proxy.
- **Asincronía.** Un `@Async` ([`18`](18-asincronia-scheduling-y-eventos.md)) devuelve antes de
  terminar, así que la aserción inmediata falla de forma intermitente; la respuesta no es un
  `Thread.sleep` sino Awaitility, cuyo
  `await().atMost(Duration.ofSeconds(2)).untilAsserted(() -> …)` reintenta hasta que se cumple.
- **Reactivo.** Una cadena de Reactor ([`11`](11-webflux-y-reactor.md)) no hace nada hasta que
  alguien se suscribe, así que un test que solo la construye siempre pasa; `StepVerifier` de
  `reactor-test` se suscribe, consume lo esperado y exige un final:
  `StepVerifier.create(flux).expectNext("a").verifyComplete()`.

El *contract testing* es decisión de arquitectura y vive en ese corpus; el catálogo de anotaciones de
test se recoge en [`A02` §17](a02-catalogo-de-anotaciones.md#17--testing).

---

## 11. ⚠️ Qué se moquea, y los errores frecuentes

```text
se moquea   →  lo que no controlas y cuesta: un proveedor externo, un IdP, un correo
se levanta  →  lo que tu código usa de verdad: tu base, tu caché (Testcontainers)
no se toca  →  el framework. Moquear un repositorio de Spring Data prueba a Spring, no a ti
```

- **"`@SpringBootTest` prueba más."** Prueba **otra cosa**: que el contexto levanta. Un slice bien
  elegido prueba la capa con más precisión y en un décimo del tiempo; y **un `@MockitoBean` de más**
  no es gratis, crea un contexto nuevo en la caché (§6).
- **"Moqueo el repositorio y así aíslo el servicio."** El test pasa con cualquier consulta, hasta
  con una que no compila en SQL: estás probando tus mocks.
- **"El test de seguridad pasa, luego la regla está bien."** Si la cadena no corrió, pasa siempre.
- **"H2 sirve para probar la capa de datos."** Sirve para probar que tu código funciona contra H2.
- **"La suite es lenta porque hay muchos tests."** Casi nunca: carga muchos contextos distintos, y
  eso se mide (§6). Y si una clase necesita cinco mocks, tiene cinco dependencias.

---

## 🧠 Preguntas rápidas

1. ¿Por qué la inyección por constructor permite un test unitario sin contenedor, y qué pasa si la
   clase inyecta por campo?
2. Diferencia `@Mock` de `@MockitoBean`: ¿quién recibe cada uno el objeto simulado?
3. ¿Qué anotaciones sustituyen a `@MockBean` y `@SpyBean`, desde qué versión y en qué proyecto?
4. Nombra los cuatro `webEnvironment` y di cuál usarías para probar un job de Batch.
5. Tu `@WebMvcTest` no arranca y el log dice `Failed to load ApplicationContext`. ¿Causa probable?
6. ¿Qué carga `@DataJpaTest` que `@JdbcTest` no carga, y cuál slice de datos **no** revierte?
7. Enumera cuatro cosas de la clave de la caché de contextos, y por qué un `@MockitoBean` en una
   sola clase alarga la suite.
8. ¿Cómo compruebas, sin adivinar, cuántos contextos cargó tu suite?
9. Un compañero pone `@DirtiesContext` en la clase base de todos los tests. ¿Qué le respondes?
10. ¿Por qué `@Transactional` en un test oculta bugs que sí ocurren en producción? Dos ejemplos.
11. Tienes `RANDOM_PORT` con `@Transactional` y los datos no se revierten. ¿Por qué?
12. ¿Cuándo eliges `MockMvc` sobre `TestRestTemplate` y qué garantía pierdes?
13. ¿Por qué `MockRestServiceServer` no sirve para probar un timeout ni un circuit breaker?
14. "H2 sirve para probar la capa de datos": da la versión precisa, y di qué aporta
    `@ServiceConnection` frente a `@DynamicPropertySource`.
15. Moqueas un bean `@Transactional` con `@MockitoBean` y el test deja de detectar un fallo de
    rollback. ¿Qué desapareció exactamente?

---

## 📚 Referencias oficiales

- Spring Boot 3.5 — `@SpringBootTest`, slices y `@MockitoBean`: https://docs.spring.io/spring-boot/3.5/reference/testing/spring-boot-applications.html
- Spring Boot 3.5 — Testcontainers y `@ServiceConnection`: https://docs.spring.io/spring-boot/3.5/reference/testing/testcontainers.html
- Spring Boot 3.5 — Javadoc de `@MockBean`, con su `@Deprecated(since = "3.4.0")`: https://docs.spring.io/spring-boot/3.5/api/java/org/springframework/boot/test/mock/mockito/MockBean.html
- Spring Framework 6.2 — Caché de contextos del `TestContext` framework: https://docs.spring.io/spring-framework/reference/6.2/testing/testcontext-framework/ctx-management/caching.html
- Spring Framework 6.2 — Bean overriding (`@MockitoBean`, `@MockitoSpyBean`, `@TestBean`): https://docs.spring.io/spring-framework/reference/6.2/testing/testcontext-framework/bean-overriding.html
- Spring Framework 6.2 — Gestión transaccional en los tests: https://docs.spring.io/spring-framework/reference/6.2/testing/testcontext-framework/tx.html
- Spring Framework 6.2 — Anotaciones de test (`@ActiveProfiles`, `@TestPropertySource`, `@DirtiesContext`, `@Sql`): https://docs.spring.io/spring-framework/reference/6.2/testing/annotations.html
- Spring Framework 6.2 — `MockMvc` y `MockMvcTester`: https://docs.spring.io/spring-framework/reference/6.2/testing/mockmvc.html
- Spring Framework 6.2 — `WebTestClient`: https://docs.spring.io/spring-framework/reference/6.2/testing/webtestclient.html
- Spring Security 6.5 — Soporte de test en MVC y `@WithMockUser`: https://docs.spring.io/spring-security/reference/6.5/servlet/test/index.html

### Documentación de terceros

- JUnit 5.12.2 — Guía de usuario: https://docs.junit.org/5.12.2/user-guide/
- Mockito 5.17.0 — Javadoc: https://javadoc.io/doc/org.mockito/mockito-core/5.17.0/index.html
- Testcontainers para Java: https://java.testcontainers.org/
- Awaitility 4.2.2 — Javadoc: https://javadoc.io/doc/org.awaitility/awaitility/4.2.2/index.html
- Reactor Core 3.7.19 — `StepVerifier` y pruebas: https://projectreactor.io/docs/core/3.7.19/reference/testing.html
