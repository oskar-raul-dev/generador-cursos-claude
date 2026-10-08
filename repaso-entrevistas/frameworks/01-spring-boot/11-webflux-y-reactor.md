# 11 — WebFlux y Reactor

> **Objetivo:** leer y escribir una cadena reactiva sin adivinar, saber en qué hilo corre
> cada eslabón, y reconocer los tres puntos donde el modelo se rompe: el bloqueo
> accidental, el contexto perdido y la persistencia que no es reactiva.
> **Asume:** [`08`](08-modelo-de-ejecucion-web.md) —este capítulo arranca donde ese
> termina—; la parte de datos se amplía en [`15`](15-datos-jdbc-jpa-mongo-y-redis.md).
> **Vigencia:** 18 de septiembre de 2026 · Spring Boot 3.5.16 · Spring Framework 6.2.19 ·
> Java 21 · Reactor Core 3.7.19.

Aquí se explica **qué es WebFlux y cómo funciona**. La decisión —cuándo conviene frente a
Spring MVC y frente a virtual threads— es el tema entero de [`12`](12-reactivo-bloqueante-y-virtual-threads.md) y no se adelanta aquí.

---

## 1. 🧭 El problema, en números

`inv-api` consulta a `inv-supplier` para enriquecer cada `InventoryItem`. El proveedor
responde en 800 ms de media, y durante esos 800 ms tu proceso no hace nada: espera bytes
en un socket. Con el modelo de
[`08` §2 — una instancia, muchos hilos](08-modelo-de-ejecucion-web.md#2--una-instancia-muchos-hilos)
la cuenta sale sola:

```text
200 hilos de Tomcat ÷ 0,8 s por petición   →  250 req/s como techo duro
200 hilos × ~1 MB de pila                  →  ~200 MB reservados para esperar
CPU durante esa espera                     →  prácticamente ociosa
```

El techo no lo pone la CPU ni la red: lo pone **el número de hilos**, porque ahí un hilo
esperando sigue siendo un hilo ocupado. El modelo reactivo deja de atar una petición a un hilo:
unos pocos —el *event loop*, uno por core con un mínimo de cuatro— atienden miles de conexiones y se despiertan
solo cuando hay bytes que procesar. La contrapartida se paga entera y tiene tres nombres: §5,
§7 y §9.

> Nunca respondas: ~~"WebFlux es más rápido"~~
>
> Mejor: "WebFlux no baja la latencia: la petición sigue tardando 800 ms. Atiende **muchas
> más peticiones con muchos menos hilos**, y eso solo se nota cuando el cuello de botella
> es la espera de E/S y no la CPU."

---

## 2. 🧱 `Mono`, `Flux` y la suscripción

Reactor es la implementación de **Reactive Streams** que usa Spring, y aporta dos tipos que
solo se diferencian en la cardinalidad: `Mono<T>` emite 0 o 1 elemento —un item, un conteo,
un `Mono<Void>`— y `Flux<T>` emite de 0 a N. Lo importante no es eso, sino esto:

```java
Mono<InventoryItem> item = repository.findById(sku)   // no consulta nada
        .map(this::enrich);                           // no enriquece nada
```

- **Ninguna de las dos líneas ejecuta trabajo.** Construyen un ensamblado: la descripción de
  qué habrá que hacer, como un `Stream` de Java antes de su operación terminal.
- **El trabajo empieza en la suscripción**, y en WebFlux **quien se suscribe es el
  framework**: devuelves el `Mono` y el `DispatcherHandler` se suscribe y escribe la respuesta
  conforme llegan los elementos. Por eso `subscribe()` casi nunca se escribe a mano.
- **Si nadie se suscribe, no pasa nada y no falla nada.** Es el bug silencioso número uno:
  llamas a `repository.save(event)`, ignoras el `Mono` que devuelve y la fila nunca se
  escribe — sin excepción, sin log y sin ayuda del compilador.

> **🧠 Modelo mental.** Un `Mono` no es un valor futuro: es **una receta**. Devolverlo es
> entregar la receta; suscribirse es encender la estufa. En WebFlux, la enciende el framework.

---

## 3. 🧱 Los operadores que hay que conocer

No son cientos: en código real se repiten estos, y `flatMap` es el que separa a quien
entiende el modelo de quien lo imita.

```java
Mono<ItemView> load(String sku) {
    return repository.findById(sku)                              // Mono<InventoryItem>
            .filter(InventoryItem::active)
            .switchIfEmpty(Mono.error(new ItemNotFoundException(sku)))
            .flatMap(item -> supplier.priceOf(item.sku())        // Mono<Price>
                    .timeout(Duration.ofSeconds(2))
                    .retryWhen(Retry.backoff(3, Duration.ofMillis(200)))
                    .onErrorResume(TimeoutException.class, e -> Mono.just(Price.unknown()))
                    .map(price -> new ItemView(item, price)));
}
```

- **`filter`** descarta lo que no cumple: un `Mono` filtrado se vuelve **vacío**, no un error.
  **`switchIfEmpty`** es la rama del vacío, y aquí convierte "no hay item" en un error de
  dominio que [`10`](10-diseno-de-api-validacion-errores-e-hipermedia.md) traduce a 404; su argumento se evalúa en tiempo de ensamblado, así que para
  diferirlo hay que envolverlo en `Mono.defer(...)`. **`defaultIfEmpty`** es su hermano
  simple: en vez de otra rama reactiva, pone un valor y sigue — lo que quieres cuando el
  vacío es un caso normal, no un 404.
- **`map`** aplica una función **síncrona**, `T → R`; **`flatMap`** convierte el elemento en
  **otro publicador**, `T → Mono<R>`, y aplana el resultado. Es lo que usas cuando el paso
  siguiente es otra llamada de red o de base de datos.
- **`timeout(2s)`** emite `TimeoutException` si el publicador interno no produce a tiempo; sin
  él la cadena espera para siempre: el event loop no se bloquea, pero la petición queda
  colgada y las pendientes se acumulan en memoria.
- **`retryWhen(Retry.backoff(3, 200ms))`** vuelve a **suscribirse** hasta tres veces con
  espera creciente: reintenta la suscripción, no "la llamada", así que todo lo que esté
  aguas arriba dentro del `flatMap` se reejecuta. **`onErrorResume`** atrapa el error —aquí
  solo `TimeoutException`— y cambia a otro publicador: es el `catch` del mundo reactivo, y
  sin filtrar por tipo atrapas todo, el mismo antipatrón que capturar `Exception`.
- **`zip`** combina publicadores que corren en paralelo y emite cuando todos produjeron;
  **`collectList`** pasa de `Flux<T>` a `Mono<List<T>>` **acumulando todo en memoria**, y
  sobre un `Flux` de un millón de filas reintroduce lo que el streaming evitaba.

> Nunca respondas: ~~"`flatMap` es el `map` asíncrono"~~
>
> Mejor: "`map` es síncrono y preserva el orden. `flatMap` **se suscribe a los publicadores
> internos en paralelo**, con concurrencia 256 por defecto, y emite en el orden en que
> responden, no en el que entraron. Si necesito el orden original uso `concatMap`; si solo
> quiero el más reciente, `switchMap`." El síntoma de confundirlos es un
> `Flux<InventoryEvent>` que se escribe **desordenado** y una prueba que pasa en local.

---

## 4. 🧱 Backpressure

Un `Flux` no es un empujón de datos sin control: el productor solo emite lo que el consumidor **pidió**.

- **El consumidor manda**, y el contrato de Reactive Streams prohíbe emitir más de lo
  solicitado; si se viola, Reactor lo señala con `OverflowException`.
- **No todas las fuentes obedecen.** R2DBC traduce el `request(n)` a tamaño de fetch, pero un
  sensor, un WebSocket o un `Sinks.many()` alimentado desde fuera **no pueden ir más lento**,
  y para esos se declara qué hacer con el exceso: `onBackpressureBuffer` (retiene),
  `onBackpressureDrop` (descarta lo nuevo), `onBackpressureLatest` (el último) u
  `onBackpressureError` (falla rápido).

> **⏱️ Costo en runtime del buffer.** `onBackpressureBuffer()` sin argumentos es
> **ilimitado**: si el productor va más rápido que el consumidor, la cola crece hasta el
> `OutOfMemoryError`, y lo hace despacio, en producción, dos semanas después del despliegue.
> Un buffer sin cota es una fuga de memoria con nombre técnico. Se acota siempre
> —`onBackpressureBuffer(1000)`— con una estrategia explícita de desbordamiento.

---

## 5. 🧱 Schedulers, y la regla de oro

Todo funciona porque los hilos del event loop —`reactor-http-nio-0`, `reactor-http-nio-1`…,
uno por core con un mínimo de cuatro— nunca esperan. Bloquear uno saca de circulación una fracción enorme de la
capacidad del proceso.

```java
return repository.findById(sku)
        .publishOn(Schedulers.boundedElastic())   // de aquí hacia abajo, otro hilo
        .map(item -> renderPdf(item))             // trabajo bloqueante, aislado
        .subscribeOn(Schedulers.parallel());      // dónde arranca la suscripción
```

- **`Schedulers.boundedElastic()`** es un pool elástico y **acotado** —por defecto 10 ×
  cores— para envolver la llamada bloqueante que no puedes evitar: un driver JDBC, una
  librería legacy, un `File.read`. Es la salida de emergencia oficial, no una excusa.
  **`Schedulers.parallel()`**, en cambio, es un pool fijo del tamaño del número de cores
  para trabajo **CPU-bound y corto**; bloquear ahí es tan malo como bloquear el event loop.
- **`publishOn`** cambia el hilo **de ese punto hacia abajo**, y puedes usar varios.
  **`subscribeOn`** decide en qué hilo **arranca la suscripción** —la fuente y todo lo que esté
  por encima— sin importar dónde lo escribas, y **solo el primero cuenta**: el segundo se ignora
  en silencio.

> **⚠️ Nunca bloquees el event loop.** Ningún `block()`, `Thread.sleep`, llamada JDBC ni
> `.get()` sobre un `Future` dentro de un operador que corre en `reactor-http-nio-N`. Con 8
> hilos de event loop, **ocho peticiones bloqueadas dejan el servicio sin atender nada**,
> incluido `/actuator/health`. Reactor detecta el caso más burdo por su cuenta:

```text
java.lang.IllegalStateException: block()/blockFirst()/blockLast() are blocking, which is not supported in thread reactor-http-nio-3
	at reactor.core.publisher.BlockingSingleSubscriber.blockingGet(BlockingSingleSubscriber.java:83)
	at reactor.core.publisher.Mono.block(Mono.java:1712)
```

Esa excepción es la buena noticia: avisa. Un `Thread.sleep(5000)` o un `jdbcTemplate.query(...)`
en el mismo sitio **no lanza nada** y deja el servicio muerto.

> **🩺 Cómo encuentras el bloqueo que no avisa.** `BlockHound` instrumenta la JVM y
> convierte cualquier llamada bloqueante hecha desde un hilo no-bloqueante en un error
> inmediato —`reactor.blockhound.BlockingOperationError: Blocking call!
> java.lang.Thread.sleep`— con el stack trace apuntando a tu línea. Se instala **solo en el
> perfil `test`**, nunca en `prod`, porque aborta peticiones legítimas. Sin él, el
> diagnóstico en caliente es un thread dump: si los `reactor-http-nio-*` salen en `WAITING`
> dentro de código tuyo, ya lo tienes.

---

## 6. 🧱 El stack: Netty, `WebFilter` y los dos estilos de endpoint

WebFlux no corre sobre Tomcat. `spring-boot-starter-webflux` trae **Reactor Netty** como
servidor por defecto, y con él desaparece la API de Servlet entera: no hay
`HttpServletRequest`, no hay `jakarta.servlet.Filter`, no hay `DispatcherServlet`.

```text
Netty (event loop) → WebFilter chain → DispatcherHandler → HandlerMapping
                                                         → controller o RouterFunction
```

- **`WebFilter`** es el equivalente reactivo del `Filter` de `08`: recibe un
  `ServerWebExchange`, devuelve `Mono<Void>` y encadena con `chain.filter(exchange)`; lo que
  hagas "después" va dentro de un operador, no debajo de la línea. **`DispatcherHandler`**
  juega el papel del `DispatcherServlet`: mismo Front Controller, mismos `HandlerMapping` y
  `HandlerAdapter`, devolviendo publicadores en vez de bloquear.
- **Incluir a la vez `spring-boot-starter-web` y `spring-boot-starter-webflux`** hace que Boot
  arranque **Tomcat**, no Netty: MVC gana el desempate en la autoconfiguración ([`06`](06-arranque-y-autoconfiguracion.md)), y es la
  causa clásica de "configuré WebFlux y sigo viendo hilos `http-nio-8080-exec-*`".

Para escribir endpoints hay dos estilos, los dos de primera clase:

```java
@GetMapping(value = "/items/events", produces = MediaType.TEXT_EVENT_STREAM_VALUE)
Flux<InventoryEvent> stream() {
    return service.events();
}
```

- **Las anotaciones son las mismas de [`09`](09-rest-con-spring-mvc.md)**, con una
  diferencia: el retorno es un `Mono` o un `Flux`. Devolver el objeto pelado compila y
  funciona, pero bloqueas mientras lo construyes, que es justo lo que no querías.
- **`produces = TEXT_EVENT_STREAM_VALUE`** cambia todo: en vez de esperar a que el `Flux` termine
  y serializar un array JSON, WebFlux escribe cada elemento como evento SSE conforme llega.
  **Sin ese `produces`, un `Flux` infinito es una respuesta que nunca se cierra.** El stream
  como contrato —`id`, reconexión, réplicas— es [`14` §3](14-tiempo-real-sse-y-websocket.md#3--flux-como-stream-lo-mismo-sin-gestionar-emitters).
- **El otro estilo es la `RouterFunction`**: un `@Bean` que declara las rutas como datos
  —`RouterFunctions.route().GET("/items/{sku}", handler::byId).build()`— con los handlers en
  clases normales. Gana al componer rutas programáticamente y al testear sin contexto web;
  pierde en legibilidad y herramientas. **Rinden igual: la elección es de estilo de equipo.**
- **El cliente natural del stack es `WebClient`**, no bloqueante de punta a punta; su
  comparación con `RestClient`, `RestTemplate` y Feign —y el matiz de que usarlo no convierte
  tu app en reactiva— es el capítulo [`13`](13-clientes-http.md).

---

## 7. 🧱 El contexto reactivo: `Context` y `ContextView`

En [`08` §8 — `ThreadLocal`](08-modelo-de-ejecucion-web.md#8--threadlocal-el-contexto-que-viaja-pegado-al-hilo)
quedó establecido que Spring guarda el usuario autenticado, el `traceId` y la transacción
activa en variables ligadas al hilo. **En WebFlux eso no puede funcionar**: una misma
petición se atiende en `reactor-http-nio-2`, sigue en un hilo de `boundedElastic` tras un
`publishOn` y termina en otro, así que el `ThreadLocal` que leas al final no es el que
escribiste —y lo peor es que a veces coincide y la prueba pasa—. Reactor lo sustituye por un
mapa inmutable que **viaja con la suscripción**, no con el hilo:

```java
Mono<Void> filter(ServerWebExchange exchange, WebFilterChain chain) {
    String traceId = exchange.getRequest().getHeaders().getFirst("X-Trace-Id");
    return chain.filter(exchange)
            .contextWrite(ctx -> ctx.put("traceId", traceId));   // se ve hacia ARRIBA
}
```

- **`contextWrite`** añade una entrada al contexto de la suscripción, con una rareza que hay que
  memorizar: **se propaga de abajo hacia arriba**, porque se construye en la suscripción, que
  viaja del suscriptor hacia la fuente. Solo lo ven los operadores que están por encima.
- **`ContextView`** es la vista de solo lectura; el `Context` con `put` solo existe dentro de
  `contextWrite` y es inmutable. Se lee con `Mono.deferContextual(ctx -> …)`, que difiere la
  construcción del publicador hasta la suscripción: el único momento en que existe.
- **Qué implica:** `SecurityContextHolder` no sirve y su equivalente es
  `ReactiveSecurityContextHolder`, que lee del `Context` ([`20` §6](20-spring-security-el-mecanismo.md#6--securitycontextholder-un-threadlocal-y-sus-dos-fugas)); el `MDC` de SLF4J tampoco se
  propaga solo —por eso los logs pierden el `traceId` al cambiar de hilo— y el puente es
  `context-propagation` de Micrometer, que Boot 3.5 trae y se habilita con
  `Hooks.enableAutomaticContextPropagation()`.

---

## 8. ⚖ R2DBC, y la parte incómoda

Una cadena reactiva vale lo que vale su eslabón más lento en bloquear. Si el controller es
reactivo pero el repositorio usa JDBC, no ganaste nada: o bloqueaste el event loop, o lo
mandaste todo a `boundedElastic` y tienes el modelo de hilos de `08` con la sintaxis de `11`.
**JPA no es reactivo y no hay forma de volverlo reactivo**: JDBC bloquea por diseño y
Hibernate además depende de un `ThreadLocal` para su sesión.

> Nunca respondas: ~~"lo envuelvo en `Mono.fromCallable` y ya es reactivo"~~
>
> Mejor: "eso no lo vuelve reactivo, lo vuelve **asíncrono sobre un pool**: sigue bloqueando
> un hilo de `boundedElastic` y el límite real sigue siendo el pool de conexiones."

La alternativa de verdad es **R2DBC**: una especificación de acceso relacional no bloqueante,
con drivers para Postgres, MySQL, Oracle y H2, y Spring Data R2DBC encima.

| | R2DBC | JPA / Hibernate |
|---|---|---|
| Modelo de E/S | no bloqueante | bloqueante |
| Mapeo | entidad ↔ fila | relaciones, herencia, lazy |
| Caché de primer nivel y *dirty checking* | ❌ | ✅ |

- **No hay lazy loading porque no hay sesión:** cada relación es otra consulta que compones tú
  con `flatMap` o `zip`, y para un agregado de tres tablas eso es trabajo manual real. Las
  transacciones sí existen, con `@Transactional` y un `ReactiveTransactionManager`, pero atadas
  al `Context` en vez de al hilo ([`16`](16-transacciones.md) explica el mecanismo del lado
  bloqueante; el reactivo usa la misma anotación con otra infraestructura debajo).
- **Veredicto honesto:** R2DBC gana en lecturas simples de alto volumen y en streaming. En banca,
  con agregados ricos y lógica transaccional, escribir a mano lo que JPA hace solo suele costar
  más de lo que rinde, y esa cuenta se hace en [`12`](12-reactivo-bloqueante-y-virtual-threads.md).

---

## 9. 🩺 Depurar una cadena reactiva

El primer stack trace que te encuentres va a ser inútil, y no es culpa tuya:

```text
reactor.core.Exceptions$ErrorCallbackNotImplemented: java.lang.NullPointerException
Caused by: java.lang.NullPointerException
	at reactor.core.publisher.MonoFlatMap$FlatMapMain.onNext(MonoFlatMap.java:132)
	at reactor.core.publisher.FluxOnAssembly$OnAssemblySubscriber.onNext(FluxOnAssembly.java:539)
	... 47 more
```

No aparece una clase tuya, y el motivo es estructural: la cadena se **ensambló** en un sitio
y se **ejecutó** en otro, quizá en otro hilo, y la pila solo conserva lo segundo.

- **`checkpoint("etiqueta")`** se inserta en el punto sospechoso y añade esa etiqueta al
  trace cuando algo falla aguas abajo. **Costo cero en runtime**, así que se deja puesto en
  producción: uno por llamada externa vuelve legible el trace de arriba.
- **`Hooks.onOperatorDebug()`** reconstruye el stack de ensamblado de **todos** los operadores:
  utilísimo y **caro**, porque captura una pila en cada paso de cada cadena. Va en `test` o en
  una sesión puntual, jamás en `prod`. El agente `reactor-tools` (`ReactorDebugAgent.init()`)
  hace lo mismo instrumentando el bytecode al arrancar, con costo despreciable, y sirve si
  necesitas trazas completas bajo carga.

> **💡 Prueba la cadena sin levantar el contexto.** `StepVerifier` consume el publicador
> declarando lo que debe ocurrir y falla si no coincide
> —`StepVerifier.create(service.load("SKU-1")).expectNextCount(1).verifyComplete()`—, y con
> `withVirtualTime(...)` salta un `timeout` de 30 segundos sin esperarlos. Viene en
> `reactor-test`; el resto del testing es [`24` §10](24-testing.md#10--seguridad-resiliencia-asincronía-y-reactivo).

---

## 10. ⚠️ Errores frecuentes

- **"WebFlux es más rápido"** (usa menos hilos, §1) y **"`flatMap` es el `map` asíncrono"** (se suscribe en paralelo y no conserva el orden, §3): las dos respuestas son incorrectas.
- **Olvidar la suscripción:** un `Mono` devuelto por `save()` y descartado no escribe nada ni avisa.
  Y un `block()` "solo por esta vez" truena con el `IllegalStateException` de §5 o tumba el servicio en silencio, igual que `WebClient` con `.block()` ([`13`](13-clientes-http.md)).
- **`onBackpressureBuffer()` sin cota** (§4), y el `SecurityContext` buscado en un `ThreadLocal`, donde ya no vive (§7).

---

## 🧠 Preguntas rápidas

1. ¿Por qué 200 hilos de Tomcat y un proveedor de 800 ms dan un techo de 250 req/s, y qué
   parte de ese cálculo cambia WebFlux?
2. Un entrevistador afirma que "WebFlux es más rápido". Da la versión precisa en una frase.
3. Llamas a `repository.save(event)` y descartas el resultado. ¿Qué se escribe en la base de
   datos y qué aparece en el log?
4. Explica por qué `flatMap` no es "el `map` asíncrono" y di qué operador usarías si
   necesitas conservar el orden de emisión.
5. ¿Qué es backpressure y qué cuatro estrategias hay si la fuente no puede ir más lento?
6. ¿Por qué `onBackpressureBuffer()` sin argumentos es peligroso, y qué escribes en su lugar?
7. Diferencia `publishOn` de `subscribeOn`, y di qué pasa si escribes dos `subscribeOn`.
8. ¿Para qué existe `Schedulers.boundedElastic()` y en qué se diferencia de
   `Schedulers.parallel()`?
9. Tu servicio WebFlux deja de responder bajo carga, sin excepciones en el log. ¿Cuál es tu
   primera hipótesis y con qué dos herramientas la confirmas?
10. ¿Por qué `ThreadLocal` no funciona en WebFlux, qué lo sustituye y en qué dirección se
    propaga?
11. Un compañero propone envolver el repositorio JPA en `Mono.fromCallable` para "hacerlo
    reactivo". ¿Qué le respondes y qué límite sigue existiendo?
12. Devuelves un `Flux` infinito desde un `@GetMapping` sin declarar `produces`. ¿Qué ve el
    cliente y cómo se corrige?
13. Tienes un stack trace reactivo sin una sola clase tuya. ¿Qué pones en producción y qué
    pones solo en `test`?

---

## 📚 Referencias oficiales

- Spring Framework 6.2 — Web on Reactive Stack: https://docs.spring.io/spring-framework/reference/6.2/web/webflux.html
- Spring Framework 6.2 — Reactive Core, `WebFilter` y `ServerWebExchange`: https://docs.spring.io/spring-framework/reference/6.2/web/webflux/reactive-spring.html
- Spring Framework 6.2 — Functional endpoints: https://docs.spring.io/spring-framework/reference/6.2/web/webflux-functional.html
- Spring Boot 3.5 — Reactive web applications: https://docs.spring.io/spring-boot/3.5/reference/web/reactive.html
- Spring Framework 6.2 — `WebClient`: https://docs.spring.io/spring-framework/reference/6.2/web/webflux-webclient.html
- Spring Data R2DBC 3.5: https://docs.spring.io/spring-data/relational/reference/3.5/r2dbc.html

### Documentación de terceros

- Reactor Core 3.7.19 — `Mono` y `Flux`: https://projectreactor.io/docs/core/3.7.19/reference/coreFeatures/mono.html
- Reactor Core 3.7.19 — Schedulers y cambio de hilo: https://projectreactor.io/docs/core/3.7.19/reference/coreFeatures/schedulers.html
- Reactor Core 3.7.19 — `Context`: https://projectreactor.io/docs/core/3.7.19/reference/advancedFeatures/context.html
- Reactor Core 3.7.19 — Depuración: https://projectreactor.io/docs/core/3.7.19/reference/debugging.html
- BlockHound: https://github.com/reactor/BlockHound
- R2DBC — especificación y drivers: https://r2dbc.io/
