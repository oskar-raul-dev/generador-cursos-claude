# 08 — El modelo de ejecución web: servlet, hilos y contexto

> **Objetivo:** poder contar qué le pasa a un request desde que llega al puerto hasta que
> lo toca tu `@RestController`, quién está en medio y en qué hilo corre todo.
> **Asume:** [`04`](04-scopes-de-bean.md), [`05`](05-proxies-y-aop.md).
> **Vigencia:** 17 de septiembre de 2026 · Spring Boot 3.5.16 · Spring Framework 6.2.19 · Java 21 · Tomcat 10.1 (Servlet 6.0).

> **📝 Este capítulo no es un repaso de la API de Servlet.** La pregunta de 2012 —*"recítame
> el ciclo de vida: `init`, `service`, `destroy`"*— ya no se hace, y `web.xml`, JSP y los
> listeners son historia que se nombra y se cierra aquí mismo. Lo que sigue vivo es el
> **modelo de ejecución**: un hilo por request, estado compartido, una cadena de filtros y
> un contexto que viaja pegado al hilo. Eso es lo que explica [`09`](09-rest-con-spring-mvc.md), [`12`](12-reactivo-bloqueante-y-virtual-threads.md), [`18`](18-asincronia-scheduling-y-eventos.md) y [`20`](20-spring-security-el-mecanismo.md), y
> por eso este capítulo va antes que ellos.

---

## 1. 🧭 El camino de un request

```text
 socket :8080
     │
     ▼
 Tomcat  ── toma un hilo del pool ──────────────────────────────┐
     │                                                          │
     ▼                                                          │
 FilterChain                                                    │
   ├── CharacterEncodingFilter                                  │
   ├── FilterChainProxy  (toda Spring Security vive aquí → 19)  │
   └── tu OncePerRequestFilter                                  │
     │                                                          │
     ▼                                                          │
 DispatcherServlet                                              │
   ├── HandlerMapping        ¿qué método atiende esta URL?      │
   ├── HandlerInterceptor    preHandle                          │
   ├── tu @RestController    ← aquí, por fin, tu código         │
   ├── HandlerInterceptor    postHandle / afterCompletion       │
   └── HandlerExceptionResolver → @ControllerAdvice             │
     │                                                          │
     ▼                                                          │
 respuesta ─────────────────────── el hilo vuelve al pool ──────┘
```

Casi todo lo raro que verás en los próximos capítulos se explica con ese dibujo. Las dos
preguntas que hay que poder contestar mirándolo son **en qué hilo corre cada caja** y
**qué pasa si algo lanza una excepción en cada una**.

---

## 2. 🧱 Una instancia, muchos hilos

Tomcat crea **un** `DispatcherServlet` y lo comparte entre todos los requests. Tu
`@RestController` y tus `@Service` son singletons ([`04`](04-scopes-de-bean.md)). Lo que varía por petición no es
el objeto: es el **hilo** que lo atraviesa.

```yaml
server:
  tomcat:
    threads:
      max: 200          # hilos de trabajo simultáneos; el default de Boot
      min-spare: 10
    accept-count: 100   # cola de conexiones aceptadas pero no atendidas
```

- **`threads.max: 200`** es el número de requests que puedes atender **a la vez**. No es
  throughput: con respuestas de 50 ms, 200 hilos dan miles de peticiones por segundo; con
  respuestas de 5 s, dan 40.
- **`accept-count`** es lo que espera en la puerta cuando los 200 están ocupados. Cuando
  esa cola también se llena, el sistema operativo rechaza conexiones y el cliente ve un
  error de conexión, no un 503 — una diferencia que importa al diagnosticar.
- **Subir `max` no es gratis** y casi nunca es la respuesta: si los hilos se acumulan es
  porque algo aguas abajo es lento, y más hilos solo aumentan la cola de esa lentitud.

> **⏱️ Costo en runtime.** Un hilo de plataforma reserva del orden de **1 MB de pila**, y
> mientras espera una respuesta HTTP o una consulta SQL **no hace nada y no se puede
> reutilizar**. Con 200 hilos son unos 200 MB de pila y un techo duro de 200 operaciones
> concurrentes. Ese techo —no la CPU— es lo que tumba servicios que llaman a un proveedor
> lento, y es el problema que atacan tanto WebFlux como los virtual threads (`12`).

Y de ahí la regla que se rompe constantemente:

> **🧠 Modelo mental.** Doscientos hilos entrando a la vez por el mismo objeto significa
> que **cualquier campo mutable de un bean es una condición de carrera**. Lo que cambia por
> request viaja en parámetros y en variables locales, nunca en un campo (`04`).

---

## 3. 🧱 El `DispatcherServlet`

Es un servlet normal, y es el único que registra Boot: lo mapea a `/` y a partir de ahí
todo pasa por él. Implementa el patrón **Front Controller**: un punto de entrada que
resuelve qué código atiende cada URL, en vez de un servlet por recurso.

- **Lo registra la autoconfiguración** ([`06`](06-arranque-y-autoconfiguracion.md)), como `dispatcherServlet`, y puedes verlo en
  `/actuator/mappings`.
- **`server.servlet.context-path`** cuelga toda la aplicación de un prefijo. Es
  transparente para tus `@GetMapping`, y se olvida constantemente al construir URLs
  absolutas a mano.
- **Puedes registrar servlets propios** con `ServletRegistrationBean`, y prácticamente
  nunca hace falta: si estás escribiendo un `HttpServlet` en 2026, casi siempre querías un
  `@RestController` o un filtro.

---

## 4. 🧱 La cadena de filtros

Un `Filter` es de la API de Servlet, no de Spring: corre **antes** de que el
`DispatcherServlet` exista para ese request, y decide si la petición sigue o no.

```java
@Component
class RequestIdFilter extends OncePerRequestFilter {

    @Override
    protected void doFilterInternal(HttpServletRequest request, HttpServletResponse response,
                                    FilterChain chain) throws ServletException, IOException {
        String requestId = request.getHeader("X-Request-Id");
        if (requestId == null) requestId = UUID.randomUUID().toString();
        MDC.put("requestId", requestId);           // queda pegado al hilo, no al request
        try {
            chain.doFilter(request, response);     // sin esto, la petición muere aquí
        } finally {
            MDC.remove("requestId");               // el finally NO es opcional: ver §8
        }
    }
}
```

- **`OncePerRequestFilter`** garantiza una sola ejecución por petición. Un `Filter` crudo
  puede ejecutarse varias veces cuando hay `forward`, `include` o despacho asíncrono, y
  entonces tu log duplica líneas o tu contador cuenta de más. Es la clase base por defecto
  y no hay casi motivos para no usarla.
- **`chain.doFilter(...)`** es el equivalente del `proceed()` de un `@Around` ([`05`](05-proxies-y-aop.md)):
  olvidarlo hace que la petición se detenga ahí, sin error y con respuesta vacía.
- **El `finally` limpiando el MDC** es obligatorio porque **el hilo se reutiliza**. Sin él,
  el siguiente request atendido por ese hilo hereda el `requestId` del anterior, y tienes
  logs que atribuyen operaciones a la petición equivocada. Es el mismo bug que el campo
  mutable de §2, con otra cara.
- **`@Component` basta para registrarlo**, pero no controla el orden. Para eso está
  `FilterRegistrationBean`, que además permite limitar el filtro a ciertas URLs:

```java
@Bean
FilterRegistrationBean<RequestIdFilter> requestIdFilter(RequestIdFilter filter) {
    FilterRegistrationBean<RequestIdFilter> registration = new FilterRegistrationBean<>(filter);
    registration.setOrder(Ordered.HIGHEST_PRECEDENCE);   // antes que Security
    registration.addUrlPatterns("/api/*");
    return registration;
}
```

- **`setOrder`** decide la posición en la cadena; el menor corre primero. Si tu filtro de
  correlación va **después** de Spring Security, los logs de un 401 salen sin `requestId`,
  que es justo cuando lo necesitas.
- **`DelegatingFilterProxy`** es la pieza que permite que un filtro sea un bean de Spring:
  el contenedor de servlets registra el proxy, y este delega en el bean. Es el mecanismo
  con el que **toda Spring Security se inserta como un único filtro** ([`20` §2](20-spring-security-el-mecanismo.md#2--security-es-un-solo-filtro-y-por-dentro-son-veinte)).

---

## 5. ⚖ Filtro, interceptor o advice

| | `Filter` | `HandlerInterceptor` | `@ControllerAdvice` |
|---|---|---|---|
| De quién es | API de Servlet | Spring MVC | Spring MVC |
| Cuándo corre | antes del `DispatcherServlet` | tras resolver el handler | al manejar una excepción |
| Sabe qué método atenderá | ❌ | ✅ | ✅ |
| Puede modificar el cuerpo | ✅ (con wrappers) | ❌ | ✅ |
| Ve las excepciones de un filtro | — | ❌ | ❌ |
| Uso natural | correlación, seguridad, CORS, compresión | métricas por handler, auditoría con el método a la vista | traducir excepciones a respuestas |

La fila que hay que memorizar es la penúltima:

> **⚠️ Una excepción lanzada en un filtro NO pasa por tu `@ControllerAdvice`.** El
> `@ExceptionHandler` vive dentro del `DispatcherServlet`, y un filtro corre fuera. La
> excepción sube al contenedor de servlets, que responde con **su** página de error —el
> 500 en blanco de Tomcat, o el `/error` de Boot—, sin tu `ProblemDetail` y sin tu formato.

Eso explica, sin misterio, por qué un 401 de Spring Security no se parece en nada a tus
otros errores: lo produce un `AuthenticationEntryPoint` dentro de la cadena de filtros,
mucho antes de que exista un controller (`20`).

> Nunca respondas: ~~"un filtro es un interceptor de Spring"~~
>
> Mejor: "un `Filter` es de la API de Servlet y corre antes del `DispatcherServlet`, así
> que no sabe qué handler atenderá ni lo alcanza el manejo de excepciones de MVC; un
> `HandlerInterceptor` es de Spring y corre cuando el handler ya está resuelto."

---

## 6. ⚠️ Leer el cuerpo en un filtro lo destruye

Es el error que todo el mundo comete la primera vez que quiere loguear el payload:

```text
org.springframework.http.converter.HttpMessageNotReadableException:
  Required request body is missing: public ResponseEntity<...> recordEvent(InventoryEvent)
```

El cuerpo de un request es un `InputStream` **de un solo uso**. Si tu filtro lo lee para
loguearlo, cuando el `HttpMessageConverter` intenta deserializarlo no queda nada.

La solución es envolver el request para que guarde lo leído:

- **`ContentCachingRequestWrapper`** almacena los bytes según se consumen y permite
  recuperarlos con `getContentAsByteArray()`. Hay que pasar **el wrapper** a
  `chain.doFilter(...)`, no el request original.
- **El cuerpo solo está disponible después** de que alguien lo haya leído: llamarlo antes
  de `doFilter` devuelve un array vacío. El log va en el `finally`, no al principio.
- **Tiene un costo** ⏱️: duplica el payload en memoria por cada petición en vuelo. Con
  cargas grandes se limita por tamaño o se activa solo en un profile de diagnóstico.

---

## 7. 🧱 Sesión, y por qué tu API no la usa

La sesión HTTP es estado en el servidor identificado por una cookie `JSESSIONID`.
Funciona, y tiene un precio de arquitectura que hay que poder nombrar:

- **Rompe el escalado horizontal.** Si la sesión vive en la memoria de una instancia, un
  request que caiga en otra réplica no la encuentra. Las salidas son sticky sessions —que
  complican despliegues y reequilibrado— o externalizarla con Spring Session sobre Redis.
- **Session fixation:** si el identificador de sesión no cambia al autenticarse, quien
  consiguiera fijarlo antes hereda la sesión autenticada. Spring Security lo mitiga por
  defecto rotando el id al hacer login (`20`).
- **En una API con Bearer token no pinta nada**, y por eso el curso configura
  `SessionCreationPolicy.STATELESS`: cada request trae su propia identidad y el servidor no
  recuerda nada entre peticiones.

> Nunca respondas: ~~"la sesión es donde se guarda el usuario logueado"~~
>
> Mejor: "es **una** forma de recordarlo, la de las aplicaciones con estado en servidor.
> En una API stateless la identidad viaja en cada petición y el servidor no guarda nada."

---

## 8. 🧱 `ThreadLocal`: el contexto que viaja pegado al hilo

Spring necesita que ciertos datos —el usuario autenticado, el `traceId`, el request en
curso— estén disponibles en cualquier capa sin pasarlos como parámetro. La solución
clásica es el `ThreadLocal`:

```text
SecurityContextHolder      → el usuario autenticado        (19)
RequestContextHolder       → el request y los beans @request (04)
MDC de SLF4J               → traceId y datos de log        (22)
TransactionSynchronizationManager → la conexión y la transacción activas (15)
```

Funciona perfectamente mientras se cumplan dos condiciones: que el trabajo ocurra **en el
hilo del request** y que alguien **limpie al terminar**. Las dos se rompen a menudo:

- **Si saltas a otro hilo, el contexto no va contigo.** Un `@Async`, un `CompletableFuture`
  con un executor propio o un `parallelStream()` estrenan un hilo sin
  `SecurityContext` ni `traceId`. El síntoma típico es una `AccessDeniedException` dentro
  de un método asíncrono que funcionaba en el controller, o logs huérfanos sin correlación.
  Se resuelve propagando el contexto explícitamente (`18`).
- **Si no limpias, contaminas al siguiente.** Los hilos se reutilizan, así que un
  `ThreadLocal` sin `remove()` en un `finally` filtra datos de una petición a otra. Con
  virtual threads este problema cambia de forma —cada tarea tiene su hilo y no se
  reutiliza—, pero el de la propagación sigue igual.
- **En WebFlux no hay `ThreadLocal` que valga**, porque una misma petición cruza varios
  hilos: el contexto viaja en la suscripción ([`11`](11-webflux-y-reactor.md)).

> Nunca respondas: ~~"`ThreadLocal` es seguro porque cada request tiene su hilo"~~
>
> Mejor: "cada request tiene un hilo **mientras dura su ejecución en el contenedor**, y ese
> hilo **se reutiliza** después. La seguridad depende de limpiar en un `finally`, y el
> contexto no cruza a otros pools."

---

## 9. 🧱 Cuando el request suelta el hilo

La API de Servlet permite devolver el hilo al pool y responder más tarde, y Spring MVC lo
expone con tres tipos de retorno:

- **`Callable<T>`**: Spring ejecuta tu lógica en un executor y libera el hilo del
  contenedor mientras tanto.
- **`DeferredResult<T>`**: tú decides desde qué hilo se completa, y es la base de los
  patrones de long polling.
- **`SseEmitter`** y `StreamingResponseBody`: la respuesta se envía por trozos a lo largo
  del tiempo, sin retener un hilo por cliente. Lo que sí retiene, su timeout de 30 segundos
  y cuándo conviene frente a WebSocket es [`14` §2](14-tiempo-real-sse-y-websocket.md#2--sseemitter-la-respuesta-que-no-termina-en-mvc).

Es la respuesta *dentro* del modelo servlet al problema de §2, y el puente conceptual
hacia WebFlux (`11`): el mismo objetivo —no bloquear un hilo esperando—, alcanzado sin
cambiar de stack. **Con virtual threads casi nunca hace falta**, porque bloquear deja de
ser caro (`12`).

---

## 10. 🧭 De `javax` a `jakarta`, y lo que quedó atrás

El cambio más visible de Spring Boot 3 no fue de Spring: Oracle cedió Java EE a la
Eclipse Foundation y, por razones de marca, **todo el namespace pasó de `javax.*` a
`jakarta.*`**. `javax.servlet.Filter` es hoy `jakarta.servlet.Filter`, y lo mismo con
`javax.validation` y `javax.persistence`.

Para ti son imports; el problema real es que **toda librería que toque esas APIs necesita
una versión compatible**, y una sin mantener bloquea la migración entera. Es la causa
número uno de que un servicio siga en Boot 2.7 ([`A04` §14](a04-migracion-3-5-a-4-x.md#14--la-migración-27--3x-que-es-la-que-todavía-te-van-a-preguntar)).

Y lo que este capítulo nombra para cerrarlo: `web.xml` fue sustituido por el registro
programático y por la autoconfiguración; JSP y los `ServletContextListener` existen, casi
no se usan en servicios backend modernos, y no vuelven a aparecer en el curso.

---

## 11. ⚠️ Errores frecuentes

- **"El `@ControllerAdvice` maneja todos los errores."** Solo los que ocurren dentro del
  `DispatcherServlet`. Lo que pase en un filtro se le escapa.
- **"Uso `@Component` en mi filtro, así que corre donde quiero."** Se registra, pero el
  orden lo decide `FilterRegistrationBean` o `@Order`.
- **"Loguear el cuerpo del request es inofensivo."** Lo destruye, salvo que lo envuelvas.
- **"Con 200 hilos aguanto 200 peticiones por segundo."** Son 200 **simultáneas**; el
  throughput depende de cuánto dura cada una.
- **"El `SecurityContext` está disponible en toda la aplicación."** En el hilo del request.
  Fuera de él, no.

---

## 🧠 Preguntas rápidas

1. Dibuja o describe el camino de un request desde el socket hasta tu `@RestController`,
   nombrando las cuatro capas por las que pasa.
2. ¿Cuántas instancias de tu `@RestController` hay atendiendo a 200 peticiones
   simultáneas, y qué consecuencia tiene para tu código?
3. ¿Qué significa exactamente `server.tomcat.threads.max=200`, y por qué no es una medida
   de throughput?
4. ¿Qué ocurre cuando los 200 hilos están ocupados y también se llena `accept-count`, y en
   qué se diferencia del síntoma anterior?
5. ¿Cuánta memoria reserva aproximadamente un hilo de plataforma, y por qué eso pone un
   techo a la concurrencia?
6. Nombra tres diferencias entre un `Filter` y un `HandlerInterceptor`.
7. Tu `@ControllerAdvice` no atrapa una excepción que ves en el log. ¿Cuál es la primera
   hipótesis y por qué?
8. ¿Qué garantiza `OncePerRequestFilter` que un `Filter` crudo no garantiza, y en qué
   situación se nota?
9. Un filtro loguea el cuerpo del request y el controller empieza a responder
   `Required request body is missing`. Explica la causa y la corrección.
10. ¿Por qué el `MDC.remove()` va en un `finally` y qué pasa exactamente si falta?
11. Nombra tres cosas que Spring guarda en un `ThreadLocal` y qué le pasa a cada una
    dentro de un método `@Async`.
12. ¿Qué problema de arquitectura introduce el uso de sesión HTTP, y cuáles son las dos
    salidas?
13. ¿Qué es la session fixation y quién la mitiga por ti?
14. ¿Para qué sirve devolver un `DeferredResult` desde un controller, y por qué los virtual
    threads lo vuelven casi innecesario?
15. ¿Por qué la migración de `javax` a `jakarta` bloquea proyectos enteros, si para tu
    código son solo imports?

---

## 📚 Referencias oficiales

- Spring Framework 6.2 — Web on Servlet Stack: https://docs.spring.io/spring-framework/reference/6.2/web/webmvc.html
- Spring Framework 6.2 — `DispatcherServlet`: https://docs.spring.io/spring-framework/reference/6.2/web/webmvc/mvc-servlet.html
- Spring Framework 6.2 — Filtros: https://docs.spring.io/spring-framework/reference/6.2/web/webmvc/filters.html
- Spring Framework 6.2 — Interceptores: https://docs.spring.io/spring-framework/reference/6.2/web/webmvc/mvc-servlet/handlermapping-interceptor.html
- Spring Framework 6.2 — Requests asíncronos: https://docs.spring.io/spring-framework/reference/6.2/web/webmvc/mvc-ann-async.html
- Spring Boot 3.5 — Servlet web applications: https://docs.spring.io/spring-boot/3.5/reference/web/servlet.html
- Spring Boot 3.5 — Configurar el servidor embebido: https://docs.spring.io/spring-boot/3.5/how-to/webserver.html
- Spring Boot 3.5 — Graceful shutdown: https://docs.spring.io/spring-boot/3.5/reference/web/graceful-shutdown.html
