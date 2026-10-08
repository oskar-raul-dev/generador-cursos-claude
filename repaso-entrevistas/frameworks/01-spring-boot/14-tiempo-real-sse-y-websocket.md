# 14 — Tiempo real: SSE y WebSocket

> **Objetivo:** empujar datos del servidor al cliente sin retener un hilo por conexión, elegir
> entre SSE y WebSocket con un argumento que se sostenga, y saber qué se rompe —afinidad,
> seguridad, réplicas— cuando la conexión deja de ser petición-respuesta.
> **Asume:** [`08`](08-modelo-de-ejecucion-web.md), [`09`](09-rest-con-spring-mvc.md),
> [`11`](11-webflux-y-reactor.md). Security se enlaza hacia adelante, a [`20`](20-spring-security-el-mecanismo.md).
> **Vigencia:** 20 de septiembre de 2026 · Spring Boot 3.5.16 · Spring Framework 6.2.19 · Java 21 · Tomcat 10.1.

> **📝 Dónde termina este capítulo.** Aquí está **cómo Spring mantiene una conexión abierta y
> escribe en ella**. Qué obliga el protocolo —el `101`, la RFC 6455, las cuatro opciones comparadas—
> vive en el corpus de HTTP y protocolos; el diseño de la mensajería, en el de arquitectura.

---

## 1. 🧭 El problema: el servidor no puede hablar primero

En [`09`](09-rest-con-spring-mvc.md) `inv-api` contesta cuando le preguntan. Ahora el negocio
quiere que el tablero **vea llegar** cada movimiento sin recargar y que el analista reciba la
alerta de stock negativo en el momento en que ocurre. HTTP es petición-respuesta y el dato nació
en el servidor: alguien tiene que abrir una conexión antes de que haya nada que decir y
**mantenerla abierta**. Y en el modelo de [`08` §2](08-modelo-de-ejecucion-web.md#2--una-instancia-muchos-hilos)
cada request ocupa un hilo: mil tableros esperando sobre 200 hilos dejan fuera a los otros 800.

```text
sondeo      GET cada N s         → un request corto por tirón; no retiene nada, llega tarde
SSE         GET que no acaba     → una respuesta abierta por cliente, solo servidor → cliente
WebSocket   101 y otro protocolo → un socket bidireccional por cliente, sin HTTP dentro
```

> Nunca respondas: ~~"para tiempo real se usa WebSocket"~~. Mejor: **por defecto SSE, porque es
> HTTP y cubre el caso servidor → cliente; WebSocket solo cuando el cliente también empuja con
> baja latencia, y a cambio pierdo la caché, los códigos de estado y el balanceo sin estado.**

---

## 2. 🧱 `SseEmitter`: la respuesta que no termina, en MVC

Spring MVC no necesita cambiar de stack. Desde [`08` §9](08-modelo-de-ejecucion-web.md#9--cuando-el-request-suelta-el-hilo)
sabes que la API de Servlet permite **devolver el hilo al pool y seguir escribiendo después**;
`SseEmitter` es ese mecanismo con el formato `text/event-stream` ya puesto.

```java
@GetMapping(value = "/api/items/events", produces = MediaType.TEXT_EVENT_STREAM_VALUE)
SseEmitter events() {
    SseEmitter emitter = new SseEmitter(Duration.ofMinutes(5).toMillis());
    emitter.onTimeout(emitter::complete);                 // el contenedor cerró por inactividad
    emitter.onCompletion(() -> emitters.remove(emitter)); // por timeout, error o cierre normal
    emitters.add(emitter);                                // un Set concurrente, compartido
    return emitter;                                       // el hilo de Tomcat vuelve al pool AQUÍ
}
```

- **`new SseEmitter(300000L)`** es el timeout **en milisegundos** de esa respuesta. Si lo omites
  manda `spring.mvc.async.request-timeout`, y si tampoco está, el del contenedor: **30 segundos
  en Tomcat**. Un stream que se corta cada medio minuto suele ser este constructor sin argumento.
- **Devolver el emitter arranca el modo asíncrono**: el `DispatcherServlet` llama a
  `request.startAsync()`, suelta el hilo `http-nio-8080-exec-*` y deja la respuesta abierta. Lo
  que retienes por cliente no es un hilo: es un `AsyncContext`, el socket y el buffer de salida.
- **`onTimeout` y `onCompletion`** son los dos ganchos que hay. Sin el segundo, el `Set` crece
  con cada cliente que se fue, y `send()` sobre un emitter completado lanza
  `IllegalStateException`. **`produces`** fija el `Content-Type` y evita el `406` de
  [`09` §8](09-rest-con-spring-mvc.md#8--406-415-y-400-tres-fallos-que-no-se-parecen) ante un `Accept: application/json`.

Quien escribe es otro hilo —el que publica el evento— y lo hace con el formato del protocolo:

```java
for (SseEmitter emitter : emitters) {
    try {
        emitter.send(SseEmitter.event()
                .id(event.id().toString())          // el cliente lo reenvía en Last-Event-ID
                .name("inventory-event")            // lo que escucha addEventListener
                .data(event, MediaType.APPLICATION_JSON));   // por los converters de 09 §7
    } catch (IOException | IllegalStateException e) {
        emitter.completeWithError(e);               // dispara onCompletion y lo saca del Set
    }
}
```

- **`send()` corre en el hilo del publicador** —un `@Async`, un listener de
  [`18`](18-asincronia-scheduling-y-eventos.md), un consumidor de cola— y escribe en el socket
  del cliente. Si ese cliente lee lento, **`send()` bloquea al publicador** y un tablero colgado
  frena el `for` entero; se acota con un executor por cliente o una cola acotada por emitter.
- **`.id(...)`** hace que la reconexión no pierda nada: el navegador reintenta solo con
  `Last-Event-ID` y el endpoint reemite desde ahí. **Sin `id`, la reconexión es un cliente nuevo.**
- **Cuando el cliente se fue, Spring lo sabe por la `IOException`** del `send()`; desde 6.1 la
  envuelve como `AsyncRequestNotUsableException` y la registra en `DEBUG`. El timeout sí es un
  error: `AsyncRequestTimeoutException`, que `ResponseEntityExceptionHandler` traduce a `503`.

> **⏱️ Costo en runtime.** Un `SseEmitter` abierto cuesta **cero hilos, una conexión del
> conector y el buffer de salida de esa respuesta** —8 KB por defecto en Tomcat—. Mil tableros
> son mil de las 8 192 `max-connections` de Tomcat, no mil hilos: se agota otro límite.

---

## 3. 🧱 `Flux` como stream: lo mismo, sin gestionar emitters

En WebFlux el stream **es** el tipo de retorno, como viste en [`11` §6](11-webflux-y-reactor.md#6--el-stack-netty-webfilter-y-los-dos-estilos-de-endpoint).
Lo que cambia respecto de MVC es quién sostiene la conexión:

```java
@GetMapping(value = "/api/items/events", produces = MediaType.TEXT_EVENT_STREAM_VALUE)
Flux<ServerSentEvent<InventoryEvent>> events(@RequestHeader(name = "Last-Event-ID", required = false) String lastId) {
    return service.eventsAfter(lastId)               // un Flux caliente: Sinks.many()
            .map(e -> ServerSentEvent.builder(e).id(e.id().toString()).event("inventory-event").build());
}
```

- **`ServerSentEvent<T>`** es el envoltorio con `id`, `event`, `retry` y `comment`; un
  `Flux<InventoryEvent>` pelado funciona, pero sin `id` no hay reconexión útil.
- **La cancelación es gratis**: cuando el cliente cierra, Netty cancela la suscripción y el
  operador aguas arriba deja de producir. En MVC lo descubrías por la `IOException`.
- **La trampa es la de [`11` §4](11-webflux-y-reactor.md#4--backpressure)**: un `Sinks.many()`
  alimentado desde fuera no puede ir más lento, así que un tablero lento **acumula** en el buffer
  del sink —`onBackpressureBuffer()` con límite, o descartar— y no frena al productor.
- **El mismo `Flux` sirve en una aplicación MVC**: Spring lo adapta a un `SseEmitter` si
  `reactor-core` está en el classpath, con el matiz de [`12` §8](12-reactivo-bloqueante-y-virtual-threads.md#8--la-migración-parcial-que-sí-es-común):
  el servidor sigue siendo Tomcat y ganaste la API, no el modelo.

---

## 4. 🧱 WebSocket crudo: `WebSocketHandler` y la sesión

Cuando el cliente también tiene que hablar —confirmar desde el tablero, un chat de soporte, un
cursor compartido— SSE se queda corto y hace falta el `101 Switching Protocols`. Con
`spring-boot-starter-websocket` en el `pom.xml`, Spring lo expone con un handler y una
configuración:

```java
@Configuration
@EnableWebSocket
class WebSocketConfig implements WebSocketConfigurer {
    @Override
    public void registerWebSocketHandlers(WebSocketHandlerRegistry registry) {
        registry.addHandler(new InventoryWebSocketHandler(), "/ws/inventory")
                .setAllowedOrigins("https://portal.invlab.example");   // el default es solo mismo origen
    }
}

class InventoryWebSocketHandler extends TextWebSocketHandler {
    private final Set<WebSocketSession> sessions = ConcurrentHashMap.newKeySet();

    @Override
    public void afterConnectionEstablished(WebSocketSession session) {
        sessions.add(new ConcurrentWebSocketSessionDecorator(session, 10_000, 512 * 1024));
    }
    // handleTextMessage(session, message) recibe cada frame; session.sendMessage(...) contesta
    @Override
    public void afterConnectionClosed(WebSocketSession session, CloseStatus status) {
        sessions.removeIf(s -> s.getId().equals(session.getId()));   // guardaste el decorador, no la sesión
    }
}
```

- **`@EnableWebSocket` + `WebSocketConfigurer`** registran el handler en el mismo
  `DispatcherServlet` de [`09` §2](09-rest-con-spring-mvc.md#2--el-recorrido-completo-pieza-por-pieza):
  el handshake **es un `GET` normal** que cruza la cadena de filtros de [`08` §4](08-modelo-de-ejecucion-web.md#4--la-cadena-de-filtros)
  —Security incluido— y solo al final se convierte en otra cosa. **Después del `101` ya nada
  pasa por los filtros**: ni `@ControllerAdvice`, ni `ProblemDetail`, ni tu filtro de correlación.
  Y **`TextWebSocketHandler`** es la única API —conexión, mensaje, error de transporte, cierre—:
  no hay `@GetMapping` para un mensaje.
- **`setAllowedOrigins`**: sin llamarlo, Spring rechaza con `403` todo handshake cuyo `Origin`
  no coincida con el host, y el navegador lo reporta como fallo de conexión sin más detalle.
- **`ConcurrentWebSocketSessionDecorator(session, sendTimeLimit, bufferSizeLimit)`** existe
  porque la sesión JSR-356 **no admite envíos concurrentes**: dos hilos en `sendMessage` a la vez
  producen un `IllegalStateException`. El decorador los serializa, y si un cliente lento acumula
  más de 512 KB o tarda más de 10 s en drenar, **cierra la sesión** con
  `SessionLimitExceededException` en vez de bloquear a quien publica: el tablero colgado de §2.

> **⏱️ Costo en runtime.** Una sesión abierta cuesta **un socket, cero hilos en reposo** —Tomcat
> NIO despacha al pool solo cuando llegan bytes— y **hasta 512 KB de buffer** si el cliente no
> drena. El mensaje entrante máximo es **8 KB en Tomcat** (`ServletServerContainerFactoryBean`); uno mayor cierra con `1009`.

---

## 5. 🧱 STOMP: destinos, `@MessageMapping` y el broker

Con el handler crudo eres tú quien inventa el protocolo: qué es una suscripción, cómo se enruta,
qué significa un `ack`. STOMP es ese protocolo ya escrito —`CONNECT`, `SUBSCRIBE`, `SEND` con un
`destination`— y Spring lo integra con un modelo que se parece a MVC:

```java
@Configuration
@EnableWebSocketMessageBroker
class StompConfig implements WebSocketMessageBrokerConfigurer {
    @Override
    public void registerStompEndpoints(StompEndpointRegistry registry) {
        registry.addEndpoint("/ws").setAllowedOrigins("https://portal.invlab.example");
    }
    @Override
    public void configureMessageBroker(MessageBrokerRegistry registry) {
        registry.setApplicationDestinationPrefixes("/app");   // lo que va a tus @MessageMapping
        registry.enableSimpleBroker("/topic", "/queue");      // lo que enruta el broker en memoria
        registry.setUserDestinationPrefix("/user");           // /user/queue/... → un usuario concreto
    }
}

@Controller
class InventoryStompController {
    @MessageMapping("/movements")                 // el cliente hace SEND a /app/movements
    @SendTo("/topic/inventory")                   // la respuesta se difunde a los suscritos
    InventoryEvent record(MovementCommand command, Principal principal) {
        return service.record(command, principal.getName());
    }
    // y para uno solo: simpMessagingTemplate.convertAndSendToUser(user, "/queue/alerts", alert)
}
```

- **`@EnableWebSocketMessageBroker`** levanta tres canales —`clientInboundChannel`,
  `clientOutboundChannel`, `brokerChannel`— cada uno con un `ThreadPoolTaskExecutor` de **2 ×
  procesadores** hilos. **Aquí está el "en qué hilo corre"**: un `@MessageMapping` corre en
  `clientInboundChannel-N`, no en Tomcat, y el `SecurityContextHolder` ahí está vacío (§7).
- **`setApplicationDestinationPrefixes("/app")`** separa lo que **tú procesas** de lo que el
  broker **reparte**: un `SEND` a `/app/movements` llega al método; un `SEND` a
  `/topic/inventory` va directo al broker, sin pasar por tu código ni por tu validación.
- **`@MessageMapping` + `@SendTo`** son el `@PostMapping` de este mundo, sin código de estado
  —un fallo es un frame `ERROR` o nada, según tu `@MessageExceptionHandler`— y con el
  `Principal` del **handshake**, no del frame. **`convertAndSendToUser`** resuelve
  `/user/{user}/queue/alerts` a las sesiones de ese usuario, y depende de ese `Principal`.
- **`enableSimpleBroker`** es un `SimpleBrokerMessageHandler` **en memoria y por instancia**:
  suscripciones en un `Map`, sin persistencia y **sin latidos** salvo que le des un
  `TaskScheduler` con `setHeartbeatValue`. Sirve para una instancia; §6 dice cuándo deja de servir.

> **⏱️ Costo en runtime.** Cada frame cuesta **un turno en `clientInboundChannel`**, cuya cola
> por defecto es `Integer.MAX_VALUE`: con los 2 × N hilos ocupados no rechaza, **encola sin techo**,
> igual que el executor de [`18` §4](18-asincronia-scheduling-y-eventos.md#4-️-el-executor-los-tres-números-y-la-cola-traicionera). Se ajusta con `configureClientInboundChannel(registration.taskExecutor().corePoolSize(…))`.

---

## 6. 🧱 El broker relay: cuando hay más de una instancia

El broker simple guarda las suscripciones en la memoria de **su** JVM. Con dos réplicas detrás
del balanceador, un tablero conectado a la instancia A **no recibe** lo que publicó la B, y el
síntoma es intermitente: la mitad de los usuarios ve la alerta y la otra mitad no. La corrección
es sacar el broker fuera:

```java
registry.enableStompBrokerRelay("/topic", "/queue")
        .setRelayHost("rabbitmq.invlab.example").setRelayPort(61613)   // el puerto STOMP, no el AMQP
        .setClientLogin("inv_lab").setClientPasscode("inv_lab")
        .setSystemLogin("inv_lab").setSystemPasscode("inv_lab");
```

- **`enableStompBrokerRelay`** sustituye al broker en memoria por un `StompBrokerRelayMessageHandler`
  que abre **una conexión TCP por cliente** más una de "sistema" hacia el broker real —RabbitMQ con
  el plugin STOMP, ActiveMQ— y le reenvía cada `SUBSCRIBE` y cada mensaje: reparte el broker.
- **Necesita `io.projectreactor.netty:reactor-netty` en el classpath**, porque el relay habla
  TCP con Reactor Netty aunque tu aplicación sea MVC sobre Tomcat; sin ella, el arranque falla por
  clase ausente. **Los dos pares de credenciales no son redundantes**: `client*` se usa por cada
  sesión de usuario, `system*` para lo que envía tu propio código.
- **Los latidos vienen por defecto** —10 s en cada sentido— y se cotejan con el *idle timeout*
  del balanceador: **un ALB cierra a los 60 s sin tráfico**, así que sin latidos los clientes
  silenciosos caen cada minuto y parece un bug de red.

**El veredicto** es el de [`17`](17-cache.md) con Redis: en memoria con una instancia; con dos,
fuera. Para SSE, sin broker que enchufar, el equivalente es publicar los eventos en Redis pub/sub
y que cada instancia los reemita a sus propios emitters.

---

## 7. 🧱 Seguridad: el `Principal` se decide en el handshake

La cadena de filtros de [`20`](20-spring-security-el-mecanismo.md) actúa sobre **el `GET` del
handshake**: si trae sesión o token válido, Spring guarda el `Principal` en la sesión WebSocket y
cada frame posterior lo lleva puesto, **sin volver a autenticar**. El problema está en el
navegador: su API `WebSocket` **no permite poner cabeceras**, así que con un resource server como el
de [`21`](21-identidad-federada-oauth2-oidc-y-jwt.md) el token va en el frame `CONNECT` de STOMP:

```java
@Override
public void configureClientInboundChannel(ChannelRegistration registration) {
    registration.interceptors(new ChannelInterceptor() {
        @Override
        public Message<?> preSend(Message<?> message, MessageChannel channel) {
            StompHeaderAccessor accessor = MessageHeaderAccessor.getAccessor(message, StompHeaderAccessor.class);
            if (StompCommand.CONNECT.equals(accessor.getCommand())) {               // solo en el CONNECT
                accessor.setUser(jwtAuthenticator.authenticate(                   // lanza si no valida
                        accessor.getFirstNativeHeader("Authorization")));          // "Bearer eyJ..."
            }
            return message;   // desde aquí, Principal en todos los frames de la sesión
        }
    });
}
```

- **`preSend` sobre `clientInboundChannel`** corre antes que cualquier `@MessageMapping`, en el
  hilo del canal; **solo el `CONNECT`** lleva el token y `setUser` lo deja en la sesión. Si
  `authenticate` lanza, el cliente recibe un frame `ERROR` y la conexión se cierra.
  **`getFirstNativeHeader`** lee una cabecera STOMP, no HTTP: esas el navegador sí las escribe.
  La alternativa —el token en la query del handshake— queda en los logs de acceso del balanceador.
- **Con `spring-security-messaging` y `@EnableWebSocketSecurity`** la autorización por destino
  se declara como en HTTP —`simpSubscribeDestMatchers("/topic/inventory").hasRole("ANALYST")`—
  en un bean `AuthorizationManager<Message<?>>`. Dos consecuencias: **todo `CONNECT` exige un
  token CSRF**, porque el handshake hereda la cookie de sesión y el ataque de [`20` §11](20-spring-security-el-mecanismo.md#11--csrf-cors-y-sesión-las-tres-que-rompen-una-api);
  con sesión `STATELESS` y token en el `CONNECT` se prescinde de la anotación y se registran los
  componentes a mano sin el interceptor CSRF, como indica su documentación. Y **lo que no casa
  con ninguna regla pasa**: por eso la documentación cierra siempre con `anyMessage().denyAll()`.

---

## 8. ⚖ Cómo se elige, y el veredicto

| Criterio | `SseEmitter` (MVC) | `Flux` SSE (WebFlux) | WebSocket + STOMP |
|---|---|---|---|
| Dirección | servidor → cliente | servidor → cliente | bidireccional |
| Filtros, `ProblemDetail`, caché | ✅ es HTTP | ✅ es HTTP | ❌ solo el handshake |
| Reconexión con reemisión | `Last-Event-ID`, del navegador | `Last-Event-ID`, del navegador | a mano, en tu protocolo |
| Réplicas | Redis pub/sub | Redis pub/sub | relay a un broker externo |

- **SSE por defecto**, y en MVC salvo que ya estés en WebFlux: cubre el tablero, las
  notificaciones, el avance de un batch. Con virtual threads ([`12`](12-reactivo-bloqueante-y-virtual-threads.md))
  el argumento de "MVC bloquea" tampoco aplica, porque `SseEmitter` nunca bloqueó.
- **WebSocket solo si el cliente empuja** con una latencia que un `POST` no cumple —colaboración,
  chat, cursores—, y entonces **con STOMP y relay desde el primer día** si habrá más de una
  réplica. En banca, el 80 % de los "necesitamos WebSocket" son un SSE con `Last-Event-ID`, y el
  resto acaba en el producto de mensajería que ya existe, no en un `Set<WebSocketSession>` a mano.

> **📝 En 4.x.** El módulo pasa a llamarse `spring-boot-websocket` —el starter
> `spring-boot-starter-websocket` sigue existiendo y apunta ahí— y la autoconfiguración cubre
> **Tomcat y Jetty**: Undertow sale. `SseEmitter`, `@MessageMapping` y el relay no cambian de
> API. El detalle está en [`A04` §5](a04-migracion-3-5-a-4-x.md#5--el-renombre-de-starters-y-el-diseño-modular).

---

## 9. ⚠️ Errores frecuentes

- **"El stream se corta a los 30 segundos."** `SseEmitter()` sin timeout hereda el del
  contenedor; se fija en el constructor o en `spring.mvc.async.request-timeout`.
- **"Funciona con una instancia y falla con dos."** Broker simple en memoria: relay, o Redis pub/sub.
- **"El `SecurityContextHolder` está vacío en el `@MessageMapping`."** Corre en
  `clientInboundChannel-N`; el usuario es el `Principal` del método o lo que dejó `setUser`.
- **"Mi `@RestControllerAdvice` no captura la excepción del handler."** Después del `101` no hay
  `DispatcherServlet`: es `handleTransportError` en crudo y `@MessageExceptionHandler` en STOMP.

---

## 🧠 Preguntas rápidas

1. "Para tiempo real se usa WebSocket": corrige la afirmación y di qué eliges por defecto y por qué.
2. Devuelves un `SseEmitter` desde un `@GetMapping`. ¿Qué hilo suelta Spring, en qué momento, y qué
   tres cosas retiene por cliente mientras el stream sigue abierto?
3. Un stream SSE se corta cada 30 segundos en producción y no en tu máquina. ¿Qué default actúa y dónde se corrige?
4. ¿Para qué sirve el `id` de un evento SSE y qué se pierde si no lo pones?
5. ¿Por qué `send()` sobre un `SseEmitter` puede frenar al hilo que publica, y cómo se acota?
6. En WebFlux, ¿qué pasa con el `Flux` cuando el cliente cierra, y por qué en MVC se descubre de otra forma?
7. ¿Qué parte de una conexión WebSocket cruza la cadena de filtros de Security y qué parte no?
8. ¿Por qué existe `ConcurrentWebSocketSessionDecorator`, qué protegen sus dos números y qué
   excepción produce cuando se superan?
9. Distingue lo que va a `/app/**` de lo que va a `/topic/**` en STOMP, y di cuál de los dos pasa por tu código.
10. ¿En qué hilo corre un `@MessageMapping`, cuántos hay por defecto y qué pasa con la cola cuando
    todos están ocupados?
11. Con dos réplicas, la mitad de los usuarios no recibe las alertas. ¿Qué componente es el
    culpable, y cuál es la corrección para STOMP y cuál para SSE?
12. El navegador no puede poner `Authorization` en el handshake. ¿Dónde viaja entonces el JWT y qué
    componente de Spring lo valida?
13. `@EnableWebSocketSecurity` rechaza todos tus `CONNECT`. ¿Qué exige por defecto y cuándo es legítimo prescindir de ello?
14. Los clientes WebSocket se desconectan cada 60 segundos sin error en tu log. ¿Qué dos números hay que cotejar?

---

## 📚 Referencias oficiales

- Spring Framework 6.2 — Peticiones asíncronas en MVC: `DeferredResult`, `ResponseBodyEmitter`, `SseEmitter` y el timeout: https://docs.spring.io/spring-framework/reference/6.2/web/webmvc/mvc-ann-async.html
- Spring Framework 6.2 — Tipos de retorno en WebFlux, incluido `Flux<ServerSentEvent>`: https://docs.spring.io/spring-framework/reference/6.2/web/webflux/controller/ann-methods/return-types.html
- Spring Framework 6.2 — WebSocket: introducción y cuándo usarlo: https://docs.spring.io/spring-framework/reference/6.2/web/websocket.html
- Spring Framework 6.2 — API de servidor: `WebSocketHandler`, decorador concurrente, buffers y orígenes permitidos: https://docs.spring.io/spring-framework/reference/6.2/web/websocket/server.html
- Spring Framework 6.2 — Habilitar STOMP y prefijos de destino: https://docs.spring.io/spring-framework/reference/6.2/web/websocket/stomp/enable.html
- Spring Framework 6.2 — `@MessageMapping`, `@SendTo` y `@MessageExceptionHandler`: https://docs.spring.io/spring-framework/reference/6.2/web/websocket/stomp/handle-annotations.html
- Spring Framework 6.2 — Broker simple y latidos: https://docs.spring.io/spring-framework/reference/6.2/web/websocket/stomp/handle-simple-broker.html
- Spring Framework 6.2 — Broker relay externo: https://docs.spring.io/spring-framework/reference/6.2/web/websocket/stomp/handle-broker-relay.html
- Spring Framework 6.2 — Autenticación por token en el `CONNECT`: https://docs.spring.io/spring-framework/reference/6.2/web/websocket/stomp/authentication-token-based.html
- Spring Framework 6.2 — Executors de los canales, límites de tamaño y buffers: https://docs.spring.io/spring-framework/reference/6.2/web/websocket/stomp/configuration-performance.html
- Spring Security 6.5 — Autorización de mensajes con `@EnableWebSocketSecurity` y CSRF en el `CONNECT`: https://docs.spring.io/spring-security/reference/6.5/servlet/integrations/websocket.html
- Spring Boot 3.5 — WebSockets: el starter y los contenedores soportados: https://docs.spring.io/spring-boot/3.5/reference/messaging/websockets.html
- Spring Boot 3.5 — `spring.mvc.async.request-timeout` en el catálogo de propiedades: https://docs.spring.io/spring-boot/3.5/appendix/application-properties/index.html

### Documentación de terceros

- Apache Tomcat 10.1 — `asyncTimeout`, `maxConnections` y el conector HTTP: https://tomcat.apache.org/tomcat-10.1-doc/config/http.html
- WHATWG — la especificación de Server-Sent Events (`EventSource`, `Last-Event-ID`): https://html.spec.whatwg.org/multipage/server-sent-events.html
