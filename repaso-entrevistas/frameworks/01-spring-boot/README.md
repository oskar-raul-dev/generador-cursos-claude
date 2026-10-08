# Spring Core Refresh — repaso para entrevistas y laboratorio práctico

> **Objetivo:** refrescar Spring y Spring Boot para entrevistas técnicas de **Backend
> Senior / Tech Lead** con Java como perfil base, y practicar en local solo aquello que
> únicamente se entiende viéndolo fallar en runtime.
> **Audiencia:** gente que ya programa en Java y ya entiende sistemas distribuidos. No se
> explica qué es una interfaz, qué es HTTP ni qué es una transacción.
> **Baseline:** Spring Boot 3.5.16 · Spring Framework 6.2.19 · Java 21 · Maven · Tomcat 10.1.
> **Vigencia:** 20 de septiembre de 2026. El 19 se verificó el corpus entero: los **336
> enlaces externos** respondían `200` sin redirección y llevaban la versión en la ruta —salvo
> 18 de `A04`, que apuntan a la línea 4.x a propósito y lo declaran—. El 20 se insertó el
> capítulo `14` y se renumeraron `15`–`26`: sus **17 enlaces** pasaron la misma verificación
> ese día. El 29 se repitió el barrido completo tras mover el curso a
> `repaso-entrevistas/frameworks/`: los **342 enlaces externos** responden `200`, las **1 401
> anclas internas** resuelven a un encabezado real y las **571 preguntas** del curso tienen su
> respuesta con el enunciado copiado literalmente. El 5 de octubre se corrigieron **190
> enlaces** a encabezados con ⚠️ o ⏱️ que el script de entonces daba por buenos y GitHub no:
> el ancla de esos encabezados lleva un carácter invisible (U+FE0F). Anclas, preguntas y
> versiones de las URL se vuelven a comprobar con `python3 -B prompts/verificar-corpus.py`.
>
> 📝 **Curso completo; labs sin corrida registrada.** Están escritos los cuarenta y un
> documentos de esta carpeta: los veinticuatro capítulos teóricos (`01`–`24`), la simulación
> de entrevista (`25`), la serie práctica entera (`L00`–`L09`), los cuatro apéndices
> (`A01`–`A04`) y el solucionario, con **571 respuestas** en tres capas. Las salidas de los
> labs `L01`–`L09` —stack traces, logs, respuestas HTTP— son **salida esperada, sin correr**:
> si al hacer un lab ves algo distinto, lo que manda es lo que imprime tu máquina.

Este curso no intenta cubrir el ecosistema de Spring. Cubre el **modelo de ejecución**,
los mecanismos y los matices que separan a quien entiende el contenedor de quien
memorizó las anotaciones. Cada documento cierra con preguntas sin respuesta a la vista;
todas las respuestas, explicadas, viven en un único sitio: `26-respuestas.md`.

**El curso tiene dos mitades independientes.** Puedes leer solo la teórica, o hacer solo
los labs, pero rinden mucho más juntas.

---

## Por qué el baseline es una versión sin soporte open source

Spring Boot 3.5 perdió el soporte OSS el **30 de junio de 2026** —su última release fue
la **3.5.16**— y hoy solo recibe parches bajo soporte comercial, hasta 2032. El GA actual
es la línea **4.x**, sobre Spring Framework 7.

El curso se escribe sobre 3.5.16 **porque es el código que hay en producción en banca y
el que vas a tocar en una entrevista técnica**, no porque sea el más nuevo. La
contrapartida es obligatoria y está en la guía de estilo: **cada capítulo marca con 📝 qué
cambia en 4.x**, y el apéndice `A04` desarrolla la migración entera. Saber que tu
baseline está fuera de soporte, y por qué tu empresa sigue ahí, es parte de la respuesta.

---

## Parte 1 — Capítulos teóricos

Se leen en orden la primera vez, y después se consultan sueltos.

| # | Documento | Qué te deja poder explicar | Estado |
|---|---|---|---|
| 01 | **[01-spring-boot-y-el-ecosistema.md](01-spring-boot-y-el-ecosistema.md)** | Qué aporta cada capa, starters, BOM, versiones y política de soporte | ✅ |
| 02 | **[02-contenedor-ioc-y-ciclo-de-vida.md](02-contenedor-ioc-y-ciclo-de-vida.md)** | `ApplicationContext`, bean definition vs instancia, fases del arranque, `@Bean` vs `@Component` | ✅ |
| 03 | **[03-inyeccion-de-dependencias.md](03-inyeccion-de-dependencias.md)** | Constructor vs campo, `@Qualifier`, `@Primary`, colecciones de beans, ciclos | ✅ |
| 04 | **[04-scopes-de-bean.md](04-scopes-de-bean.md)** | Singleton, prototype, scopes web, scoped proxies, estado compartido | ✅ |
| 05 | **[05-proxies-y-aop.md](05-proxies-y-aop.md)** | JDK vs CGLIB, self-invocation, orden de advices — **la base de medio curso** | ✅ |
| 06 | **[06-arranque-y-autoconfiguracion.md](06-arranque-y-autoconfiguracion.md)** | `SpringApplication`, `@ConditionalOn*`, informe de condiciones, exclusiones | ✅ |
| 07 | **[07-configuracion-externalizada.md](07-configuracion-externalizada.md)** | Precedencia de fuentes, YAML vs properties, profiles, `@ConfigurationProperties` | ✅ |
| 08 | **[08-modelo-de-ejecucion-web.md](08-modelo-de-ejecucion-web.md)** | Thread-per-request, cadena de filtros, filtro vs interceptor vs advice, `ThreadLocal` | ✅ |
| 09 | **[09-rest-con-spring-mvc.md](09-rest-con-spring-mvc.md)** | `DispatcherServlet`, mapeos, converters, content negotiation | ✅ |
| 10 | **[10-diseno-de-api-validacion-errores-e-hipermedia.md](10-diseno-de-api-validacion-errores-e-hipermedia.md)** | Bean Validation, `ProblemDetail`, versionado, paginación, HATEOAS | ✅ |
| 11 | **[11-webflux-y-reactor.md](11-webflux-y-reactor.md)** | `Mono`/`Flux`, backpressure, schedulers, contexto reactivo | ✅ |
| 12 | **[12-reactivo-bloqueante-y-virtual-threads.md](12-reactivo-bloqueante-y-virtual-threads.md)** | Los tres modelos, cuándo gana cada uno y qué cuesta el equipo | ✅ |
| 13 | **[13-clientes-http.md](13-clientes-http.md)** | `RestClient`, `WebClient`, `RestTemplate`, Feign, HTTP Interfaces, timeouts y pools | ✅ |
| 14 | **[14-tiempo-real-sse-y-websocket.md](14-tiempo-real-sse-y-websocket.md)** | `SseEmitter`, `Flux` como stream, WebSocket, STOMP, broker relay, `Principal` en el handshake | ✅ |
| 15 | **[15-datos-jdbc-jpa-mongo-y-redis.md](15-datos-jdbc-jpa-mongo-y-redis.md)** | Hikari, `JdbcClient`, Spring Data, N+1, `open-in-view`, Mongo, Redis, Flyway | ✅ |
| 16 | **[16-transacciones.md](16-transacciones.md)** | Propagación, aislamiento, rollback, los fallos silenciosos | ✅ |
| 17 | **[17-cache.md](17-cache.md)** | Abstracción de caché, Caffeine/Ehcache/Redis, Lettuce vs Redisson, stampede | ✅ |
| 18 | **[18-asincronia-scheduling-y-eventos.md](18-asincronia-scheduling-y-eventos.md)** | `@Async`, executors, `@Scheduled`, eventos, propagación de contexto | ✅ |
| 19 | **[19-resiliencia.md](19-resiliencia.md)** | Timeout, retry con jitter, circuit breaker, bulkhead — y su orden de apilado | ✅ |
| 20 | **[20-spring-security-el-mecanismo.md](20-spring-security-el-mecanismo.md)** | La cadena de filtros, autenticación, autorización, 401 vs 403 | ✅ |
| 21 | **[21-identidad-federada-oauth2-oidc-y-jwt.md](21-identidad-federada-oauth2-oidc-y-jwt.md)** | Resource server, claims a authorities, propagación de identidad, mTLS | ✅ |
| 22 | **[22-spring-batch.md](22-spring-batch.md)** | Job/step, chunk, `JobRepository`, restart, skip, partición | ✅ |
| 23 | **[23-actuator-y-observabilidad.md](23-actuator-y-observabilidad.md)** | Health groups, Micrometer, cardinalidad, trazas, las cuatro señales | ✅ |
| 24 | **[24-testing.md](24-testing.md)** | Slices, Testcontainers, caché de contextos, qué prueba cada cosa | ✅ |
| 25 | **[25-simulacion-de-entrevista.md](25-simulacion-de-entrevista.md)** | 60 preguntas `P#` y 6 escenarios de diseño resueltos. Se hace al final | ✅ |
| 26 | **[26-respuestas.md](26-respuestas.md)** | Solucionario centralizado de **todo** el curso, en tres capas | ✅ 571 respuestas |

**Por qué ningún documento lleva la respuesta al lado de la pregunta.** Una respuesta
leída antes de intentarla no se recuerda en una entrevista. Contesta en voz alta, escribe
tu versión, y solo entonces abre el solucionario.

**Los capítulos teóricos no llevan ejercicios**, solo preguntas: se estudian sin
computadora. Lo ejecutable vive entero en la Parte 2.

---

## Parte 2 — Serie práctica: labs y apéndices

Un laboratorio **solo backend, sin frontend**, construido entero en `localhost` con
Docker Compose sobre un único proyecto Spring Boot, `inv-api`, que crece lab a lab.

**Costo total de la serie: $0.00.** No hay nube, no hay factura y no hay nada que
olvidarse encendido salvo contenedores, que mueren con un comando.

**Empieza por `L00`.** Es la introducción a la serie y su contrato: qué se construye, qué
queda fuera y por qué.

| Doc | Contenido | Estado |
|---|---|---|
| **[l00-idea-lab-practico.md](l00-idea-lab-practico.md)** | Doctrina de reparto, catálogo de exclusiones, `docker-compose.yml` de la serie | ✅ |
| **[l01-esqueleto-cli-y-autoconfiguracion.md](l01-esqueleto-cli-y-autoconfiguracion.md)** | `start.spring.io`, CLI, Maven, informe de condiciones, fallos de arranque | ✅ |
| **[l02-configuracion-y-profiles.md](l02-configuracion-y-profiles.md)** | Precedencia demostrada, `@ConfigurationProperties`, profiles, secretos | ✅ |
| **[l03-api-rest-filtros-y-errores.md](l03-api-rest-filtros-y-errores.md)** | Endpoints, 400/406/415/422, filtro de correlación, `ProblemDetail`, interceptores | ✅ |
| **[l04-datos-y-transacciones.md](l04-datos-y-transacciones.md)** | Postgres, Flyway, N+1, `open-in-view`, **el rollback que no ocurre**, pool agotado | ✅ |
| **[l05-clientes-y-resiliencia.md](l05-clientes-y-resiliencia.md)** | WireMock, timeouts, retry con jitter, circuit breaker en vivo, bulkhead | ✅ |
| **[l06-cache-y-asincronia.md](l06-cache-y-asincronia.md)** | Caffeine, Redis, incoherencia entre instancias, `@Async` y el `requestId` perdido | ✅ |
| **[l07-actuator-metricas-y-trazas.md](l07-actuator-metricas-y-trazas.md)** | Health groups, cardinalidad, Prometheus, Grafana, trazas punta a punta | ✅ |
| **[l08-security-y-batch.md](l08-security-y-batch.md)** | Keycloak, resource server JWT, 401 vs 403, job reiniciable | ✅ |
| **[l09-empaquetado-imagen-y-limpieza.md](l09-empaquetado-imagen-y-limpieza.md)** | Layered jar, imagen, graceful shutdown, 💀 boss fight y limpieza verificada | ✅ |
| **[a01-cli-y-tooling-de-supervivencia.md](a01-cli-y-tooling-de-supervivencia.md)** | `spring`, `mvnw`, `jcmd`, `curl`, `jq`, leer un stack trace de Spring | ✅ |
| **[a02-catalogo-de-anotaciones.md](a02-catalogo-de-anotaciones.md)** | Referencia por familia: qué hace, dónde va, la trampa, dónde se explica | ✅ |
| **[a03-catalogo-de-errores-y-diagnostico.md](a03-catalogo-de-errores-y-diagnostico.md)** | Excepción literal → causa real → cómo se confirma → corrección → prevención | ✅ |
| **[a04-migracion-3-5-a-4-x.md](a04-migracion-3-5-a-4-x.md)** | Qué cambia en la línea actual, y la migración 2.7 → 3.x que aún se pregunta | ✅ |

Los labs son acumulativos y se hacen en orden. Cada uno declara qué deja levantado y el
siguiente asume ese estado. Los apéndices se consultan en cualquier momento.

**Cada lab y cada apéndice cierra con ejercicios graduados** —🟢 🟡 🟠 🔴, más 🔥 opcionales
y un 💀 *boss fight* donde el contenido lo justifica—.

### El principio que decide el alcance

> Al laboratorio va lo que **solo se entiende viéndolo fallar en runtime**. Lo que se
> entiende leyendo se queda en el capítulo.

Por eso el lab no monta Kafka, ni Kubernetes, ni un frontend, ni Spring Cloud. Cada
exclusión se justifica una por una en `L00`.

---

## Cómo estudiar con esto

**Si tienes una entrevista esta semana.** Lee `02`, `03`, `05`, `16` y `19` —el núcleo de
lo que se pregunta y se falla— y después haz `25` completo, contestando en voz alta.

**Si tienes un mes.** Lee los capítulos en orden, uno por sesión, y haz la serie práctica
en paralelo. **El orden de los labs no se elige**: son acumulativos y cada uno arranca del
estado que dejó el anterior, así que lo único que decides es en qué punto de la teoría los
intercalas. Este reparto respeta a la vez la cadena `L00`→`L09` y el capítulo que sustenta
cada lab:

| Cuándo | Lab | Porque antes hace falta |
|---|---|---|
| Antes de empezar | `L00` | nada: es el encuadre de la serie, no se ejecuta |
| Después de `07` | `L01`, `L02` | `01`, `06` y `07` |
| Después de `10` | `L03` | `08`, `09` y `10` |
| Después de `16` | `L04` | `05`, `15` y `16` |
| Después de `19` | `L05`, `L06` | `13` y `19` para `L05`; `17` y `18` para `L06` |
| Después de `23` | `L07`, `L08` | `23` para `L07`; `20`, `21` y `22` para `L08` |
| Después de `24` | `L09` | `01` §6, `07` y `23` |

`L06` no es opcional aunque la teoría que lo sostiene sea anterior a `19`: es el lab que
levanta Redis, y `L07` lo da por hecho. Y `L08` va después de `23`, no después de `22`,
porque necesita el Actuator y las trazas que monta `L07`. Cierra con `25`.

**Si ya trabajaste años con Spring y solo quieres el filo.** Ve directo a `25`, marca lo
que no sepas contestar, y usa los índices de salto rápido para ir solo a esas secciones.

### La regla de las cinco preguntas

Para cada mecanismo del temario, intenta contestar estas cinco. Si puedes con las cinco,
ese mecanismo ya no te lo tumban en una entrevista:

```text
1. ¿Qué problema resuelve?
2. ¿Quién lo ejecuta: el contenedor, un proxy, o tu código?
3. ¿En qué hilo corre y qué recurso retiene?
4. ¿Cuál es la alternativa más parecida y en qué se diferencia?
5. ¿Qué falla si lo usas mal, y qué excepción verías?
```

La segunda y la tercera son las que casi nadie contesta, y son las que distinguen a un
senior de alguien que lleva años escribiendo anotaciones que funcionan.

---

## El sistema que construyes en la serie práctica

```text
                          ┌─────────────────┐
   curl ──► inv-api ──────► inv-supplier    │  (WireMock: latencia y fallos a demanda)
            │  │  │        └─────────────────┘
            │  │  └──────► Redis      (caché distribuida)
            │  └─────────► Postgres   (JPA, transacciones, Batch)
            └────────────► Mongo      (proyección de consulta)

   Actuator :8081 ──► Prometheus ──► Grafana
   Keycloak        ──► resource server JWT
```

Deliberadamente pequeño: el dominio no es el tema, el framework sí.

---

## Asociaciones que conviene memorizar

| Necesidad | Mecanismo |
|---|---|
| Crear y conectar objetos | Contenedor IoC / `ApplicationContext` |
| Declarar un componente propio | `@Component` y estereotipos |
| Declarar un bean de terceros | `@Bean` en una `@Configuration` |
| Elegir entre candidatos del mismo tipo | `@Qualifier`, `@Primary` |
| Un bean por request | scope `request` + scoped proxy |
| Interceptar sin tocar el código | Proxy AOP (`@Aspect`) |
| Configurar según lo que haya en el classpath | `@ConditionalOnClass` / autoconfiguración |
| Tipar y validar la configuración | `@ConfigurationProperties` + `@Validated` |
| Actuar antes del `DispatcherServlet` | `Filter` / `OncePerRequestFilter` |
| Actuar sobre el handler ya resuelto | `HandlerInterceptor` |
| Traducir excepciones a respuestas | `@ControllerAdvice` + `ProblemDetail` |
| Endpoint REST | `@RestController` + `@GetMapping` |
| Contrato hipermedia | Spring HATEOAS + HAL |
| E/S no bloqueante | WebFlux + Reactor |
| Empujar eventos servidor → cliente | SSE: `SseEmitter` / `Flux<ServerSentEvent>` |
| Canal bidireccional con el navegador | WebSocket + STOMP (``, broker relay) |
| Muchos hilos baratos sin reescribir | Virtual threads (Java 21) |
| Llamar a otro servicio (síncrono) | `RestClient` |
| Llamar a otro servicio (declarativo) | HTTP Interfaces / Feign |
| SQL a la vista | `JdbcClient` / `JdbcTemplate` |
| Repositorio sin implementación | Spring Data |
| Versionar el esquema | Flyway |
| Atomicidad | `@Transactional` |
| Evitar recalcular | `@Cacheable` + `CacheManager` |
| Caché compartida entre instancias | Redis (Lettuce) |
| Bloqueo distribuido | Redisson `RLock` |
| Sacar trabajo del hilo del request | `@Async` + executor propio |
| Tarea periódica | `@Scheduled` (+ bloqueo si hay réplicas) |
| Efecto externo tras el commit | `@TransactionalEventListener(AFTER_COMMIT)` |
| Cortar una llamada lenta | Timeout + `TimeLimiter` |
| Dejar de insistir sobre lo caído | Circuit breaker (Resilience4j) |
| Reintentar sin tumbar al otro | Retry con backoff + jitter |
| Aislar un recurso escaso | Bulkhead |
| Autenticación y autorización | `SecurityFilterChain` |
| Identidad emitida por un tercero | OAuth2 / OIDC resource server |
| Proceso por lotes reiniciable | Spring Batch |
| ¿Está sano? ¿por qué está lento? | Actuator + Micrometer |
| Probar una capa sin levantar todo | Slices de test |
| Probar contra la base de verdad | Testcontainers |

---

## Convenciones del curso

Todo `.md` de este directorio sigue
[`prompts/guia-de-estilo-y-convenciones.md`](prompts/guia-de-estilo-y-convenciones.md).
Lo mínimo que conviene saber para leerlo o editarlo:

- **Emoji de encabezado funcional**, no decorativo: 🧭 encuadre · 🧱 mecanismo ·
  ⚖ comparación · 🩺 diagnóstico · ⏱️ costo en runtime · 🧪 verificación · 🧠 preguntas ·
  📚 referencias.
- **Callouts en blockquote:** ⚠️ advertencia · 🧠 modelo mental · 💡 truco · 🩺 diagnóstico ·
  ⏱️ costo en runtime · 📝 contexto o cambio de versión · 📚 referencia inline.
- **Ningún bloque de código queda sin desglose.** Toda anotación, atributo y propiedad no
  obvia se explica.
- **Todo lo que bloquea un hilo, retiene una conexión o crece con la carga** se nombra con
  su unidad.
- **Las respuestas viven solo en `26-respuestas.md`**; quien toca una pregunta, actualiza
  ese archivo en la misma edición.
- **Solo se enlaza documentación oficial**; la de terceros (Resilience4j, Redisson,
  Testcontainers) va en una subsección aparte.
- **Los enlaces de `docs.spring.io` llevan siempre la versión en la ruta** (`/3.5/`,
  `/6.2/`): una URL sin versión responde `200` y te entrega la documentación de otra
  versión sin avisarte.

---

## Relación con el resto del repositorio

```text
preguntas-entrevista/springboot/            repaso rápido con respuesta inline
                                            (280 preguntas). Aquí se enseña el mecanismo.

repaso-entrevistas/arquitectura/01-bases/   la decisión de diseño: zero-trust, saga, outbox,
                                            ventanas batch. Aquí, cómo lo hace Spring.

repaso-entrevistas/cloud/01-aws/            la infraestructura y el dueño de la factura.
repaso-entrevistas/cloud/02-gcp/            Este curso no explica qué es un balanceador.

repaso-entrevistas/bases/01-bases/          algoritmos y estructuras de datos.
```

**Frontera de privacidad.** `Entrevistas/` es material personal de búsqueda de empleo y
**no se cita nunca desde aquí**: este curso está pensado para publicarse.

---

## Referencias oficiales base

- Spring Boot 3.5 — Reference: https://docs.spring.io/spring-boot/3.5/index.html
- Spring Boot 3.5 — System Requirements: https://docs.spring.io/spring-boot/3.5/system-requirements.html
- Spring Framework 6.2 — Reference: https://docs.spring.io/spring-framework/reference/6.2/index.html
- Spring Boot — página del proyecto: https://spring.io/projects/spring-boot/
- Spring Framework — página del proyecto: https://spring.io/projects/spring-framework/
