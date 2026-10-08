# 25 — Simulación de entrevista

> **Objetivo:** que te oigas contestar antes de que te oiga un entrevistador. Sesenta
> preguntas `P#` que cruzan capítulos —ninguna se resuelve mirando uno solo— y seis
> escenarios de diseño resueltos, del mundo de la banca con Java como perfil base.
> **Asume:** el curso entero leído, [`01`](01-spring-boot-y-el-ecosistema.md)–[`24`](24-testing.md). Las respuestas de las `P#` viven en
> [`26`](26-respuestas.md); los escenarios **sí** traen aquí su solución, porque son ejemplos resueltos
> y no autochequeo de memoria.
> **Vigencia:** 19 de septiembre de 2026 · Spring Boot 3.5.16 · Spring Framework 6.2.19 · Java 21.

**Salto rápido:** [Cómo se usa](#1--cómo-se-usa-esta-simulación) · [Reparto y cobertura](#2--reparto-y-cobertura-de-las-60-p) ·
[Las 60 preguntas](#-preguntas-rápidas) · [Escenario 1 — el monolito](#3--escenario-1--el-monolito-transaccional-que-hay-que-partir) ·
[Escenario 2 — la ventana batch](#4--escenario-2--el-batch-nocturno-que-ya-no-cabe-en-la-ventana) ·
[Escenario 3 — el proveedor lento](#5--escenario-3--el-proveedor-que-se-pone-lento) ·
[Escenario 4 — identidad entre cinco servicios](#6--escenario-4--la-identidad-a-través-de-cinco-servicios) ·
[Escenario 5 — la caché que filtró](#7--escenario-5--la-caché-que-devolvió-datos-de-otro-usuario) ·
[Escenario 6 — versionar sin romper](#8--escenario-6--versionar-una-api-pública-sin-romper-a-nadie) ·
[Preguntas trampa](#9-️-preguntas-trampa-con-la-respuesta-de-una-línea) · [Lo que preguntas tú](#10--lo-que-preguntas-tú-al-final) ·
[Referencias](#-referencias-oficiales)

---

## 1. 🧭 Cómo se usa esta simulación

Este documento no enseña nada nuevo. Es el examen del curso completo, y por eso se
escribió el último: cada pregunta se eligió sabiendo qué capítulo la sostiene y qué
capítulo la complica.

Hay una diferencia de fondo con las "🧠 Preguntas rápidas" que cierran cada capítulo, y
conviene entenderla antes de empezar:

```text
pregunta rápida  → comprueba un mecanismo, vive dentro de un documento
pregunta P#      → cruza dos o tres documentos y termina en una decisión defendible
```

La pregunta rápida 6 de [`16`](16-transacciones.md) te pide diagnosticar un pool agotado. La `P27` te pide
decidir si subes el pool, y ahí ya no basta con `16`: hacen falta el modelo de hilos de
[`08`](08-modelo-de-ejecucion-web.md), el timeout de [`13`](13-clientes-http.md) y la métrica de [`23`](23-actuator-y-observabilidad.md) para no responder de oído. **Ninguna `P#` se
resuelve mirando un solo capítulo**; ahí está la diferencia con una pregunta rápida.

Cómo sacarle el jugo, en este orden:

- **Contesta en voz alta y cronometrado.** Treinta segundos para la primera pasada. Si a
  los treinta segundos sigues construyendo contexto, la respuesta ya se perdió: el
  solucionario de [`26`](26-respuestas.md) está escrito en tres capas justamente para entrenar eso.
- **Escribe tu versión antes de abrir la respuesta.** Una respuesta leída antes de
  intentarla no aparece cuando hace falta.
- **Marca las que fallas y vuelve al capítulo que indica el enlace**, no a la respuesta.
  El enlace de cada `P#` apunta a la sección concreta donde se estudia.
- **Los seis escenarios se practican distinto.** Léelos con la solución tapada, dedica
  diez minutos a bosquejar la tuya en papel y solo entonces compara. Lo que se compara no
  es la solución: es **si nombraste el intercambio**.

> **🧠 El modelo mental de toda la simulación.** En una mesa de Tech Lead no se puntúa
> saber la anotación. Se puntúa poder decir *qué se gana, qué se paga y quién firma el
> riesgo*. Una respuesta sin intercambio explícito suena a tutorial.

> **📝 Este documento es una excepción declarada a la plantilla de §6 de la guía de
> estilo**, y también a la banda de 200–380 líneas de §4.6: no es un capítulo teórico
> sino el aparato de evaluación del curso entero, y su longitud la fijan las sesenta
> preguntas y los seis escenarios, no la prosa.

---

## 2. ⚖ Reparto y cobertura de las 60 `P#`

Las preguntas están en el orden en que caen en una entrevista real —contenedor primero,
batch y testing al final—, no en el orden del curso. Los seis bloques:

| Bloque | Rango | De qué va |
|---|---|---|
| **A** — Contenedor, arranque y proxy | `P1`–`P14` | beans, inyección, scopes, proxies, autoconfiguración y configuración |
| **B** — El borde web y la API | `P15`–`P26` | hilos, filtros, MVC, contrato, reactivo y clientes HTTP |
| **C** — Datos y transacciones | `P27`–`P35` | pool, JPA, esquema, propagación, rollback y consistencia |
| **D** — Producción | `P36`–`P46` | caché, asincronía, resiliencia y observabilidad |
| **E** — Seguridad e identidad | `P47`–`P53` | cadena de filtros, autorización, OAuth2, OIDC y JWT |
| **F** — Batch, testing y criterio | `P54`–`P60` | Spring Batch, estrategia de pruebas y diagnóstico |

Y el reparto por documento, que es lo que garantiza que no quede un capítulo sin
representación ni un capítulo acaparando la mitad:

| Documento | `P#` | Documento | `P#` |
|---|---|---|---|
| [`01`](01-spring-boot-y-el-ecosistema.md) | 1, 2 | [`13`](13-clientes-http.md) | 24, 25 |
| [`02`](02-contenedor-ioc-y-ciclo-de-vida.md) | 3, 4 | [`15`](15-datos-jdbc-jpa-mongo-y-redis.md) | 27, 28, 29, 30 |
| [`03`](03-inyeccion-de-dependencias.md) | 6, 7 | [`16`](16-transacciones.md) | 31, 32, 33, 34, 35 |
| [`04`](04-scopes-de-bean.md) | 8 | [`17`](17-cache.md) | 36, 37, 38 |
| [`05`](05-proxies-y-aop.md) | 9, 10 | [`18`](18-asincronia-scheduling-y-eventos.md) | 39, 40 |
| [`06`](06-arranque-y-autoconfiguracion.md) | 5, 11 | [`19`](19-resiliencia.md) | 41, 42, 43 |
| [`07`](07-configuracion-externalizada.md) | 12, 13 | [`20`](20-spring-security-el-mecanismo.md) | 47, 48, 49, 50 |
| [`08`](08-modelo-de-ejecucion-web.md) | 15, 16 | [`21`](21-identidad-federada-oauth2-oidc-y-jwt.md) | 51, 52, 53 |
| [`09`](09-rest-con-spring-mvc.md) | 17, 18 | [`22`](22-spring-batch.md) | 54, 55, 56 |
| [`10`](10-diseno-de-api-validacion-errores-e-hipermedia.md) | 19, 20, 21 | [`23`](23-actuator-y-observabilidad.md) | 44, 45, 46 |
| [`11`](11-webflux-y-reactor.md) | 22, 26 | [`24`](24-testing.md) | 57, 58, 59 |
| [`12`](12-reactivo-bloqueante-y-virtual-threads.md) | 23 | [`A02`](a02-catalogo-de-anotaciones.md) · [`A03`](a03-catalogo-de-errores-y-diagnostico.md) | 14 · 60 |

Tres notas sobre este reparto, porque las asimetrías son decisiones y no descuidos:

- **`15` y `16` se llevan nueve preguntas entre los dos** —el bloque más cargado— porque
  datos y transacciones es lo que más se pregunta, y porque el fallo silencioso de
  `@Transactional` es lo que más se pregunta y más se falla.
- **`12` se lleva una sola.** Reactivo frente a virtual threads es una conversación de
  arquitectura que en banca aparece como pregunta de criterio, no como tema de
  implementación; `11` aporta las otras dos desde el lado del mecanismo.
- **Los labs y los apéndices no tienen `P#` propias**, porque las suyas ya están en sus
  documentos. Aparecen como enlace secundario en las preguntas cuyo mecanismo se ve
  fallar allí — que es exactamente lo que los hace valiosos para responder.

Cada pregunta termina con el documento donde se estudia. Cuando hay varios, el primero es
el que sostiene la respuesta y los demás la complican.

---

## 🧠 Preguntas rápidas

Las sesenta `P#`, numeradas de corrido: `P17` es el punto 17 de esta lista. **Sin
respuesta aquí**: la de `P17` es la entrada `25 → 17` de [`26`](26-respuestas.md), con sus tres capas.

1. Entras a un equipo cuyo servicio corre sobre Spring Boot 3.5.16 y el arquitecto quiere subir a 4.x "porque 3.5 ya no tiene soporte". Explica qué significa exactamente ese fin de soporte, qué dos cosas mirarías antes de aceptar, y con qué argumento defenderías posponerlo un trimestre. — [`01` §8](01-spring-boot-y-el-ecosistema.md#8--soporte-eol-y-por-qué-el-baseline-es-una-versión-sin-soporte-oss)
2. Una librería interna promete darte un `RestClient` ya configurado y no aparece ningún bean. Recorre el diagnóstico desde el `pom.xml` hasta el informe de condiciones, nombrando el fichero exacto donde esa librería debería declarar su autoconfiguración en Boot 3.5. — [`01` §4](01-spring-boot-y-el-ecosistema.md#4--qué-hay-dentro-de-un-starter) · [`06` §4](06-arranque-y-autoconfiguracion.md#4--dónde-vive-el-catálogo-de-autoconfiguraciones) · [`L01` §8](l01-esqueleto-cli-y-autoconfiguracion.md#8--el-informe-de-condiciones---debug-y-actuatorconditions)
3. Necesitas dos `RestClient` en el mismo contexto, uno para `inv-supplier` y otro para el IdP. Di por qué no puedes resolverlo con `@Component`, cómo los declaras, y qué tiene que pasar en el punto de inyección para que el contenedor no falle con `NoUniqueBeanDefinitionException`. — [`02` §5](02-contenedor-ioc-y-ciclo-de-vida.md#5--component-y-bean-no-son-lo-mismo) · [`03` §3](03-inyeccion-de-dependencias.md#3--cómo-elige-el-contenedor-entre-candidatos) · [`13` §4](13-clientes-http.md#4--la-clienthttprequestfactory-timeouts-y-pool)
4. Un bean tuyo abre un `ExecutorService` propio en su construcción. Di quién lo cierra si el bean es `singleton`, quién lo cierra si es `prototype`, y cómo comprobarías en el apagado que no quedó ningún hilo vivo. — [`02` §9](02-contenedor-ioc-y-ciclo-de-vida.md#9--destrucción-y-lo-que-el-contenedor-no-destruye) · [`04` §4](04-scopes-de-bean.md#4--prototype-y-quién-limpia-después) · [`L09` §7](l09-empaquetado-imagen-y-limpieza.md#7--graceful-shutdown-con-una-petición-en-vuelo)
5. Tienes tres sitios para el trabajo de arranque: el constructor, un `@PostConstruct` y un `ApplicationRunner`. Di qué está disponible en cada uno, cuál es el único donde puede correr trabajo transaccional, y qué le pasa al arranque si ese trabajo tarda treinta segundos. — [`06` §9](06-arranque-y-autoconfiguracion.md#9--código-que-corre-al-arrancar) · [`02` §4](02-contenedor-ioc-y-ciclo-de-vida.md#4--las-fases-del-arranque) · [`05` §2](05-proxies-y-aop.md#2--quién-crea-el-proxy-y-cuándo)
6. Lideras una revisión de código donde medio equipo inyecta por campo "porque es más corto". Construye el argumento con tres patas —diseño, runtime y pruebas— y di cuál de las tres convence a un desarrollador que ya está cómodo con `@Autowired`. — [`03` §1](03-inyeccion-de-dependencias.md#1--las-tres-formas-y-por-qué-solo-una-sobrevive-a-una-revisión) · [`24` §2](24-testing.md#2--el-test-unitario-sin-contenedor-y-por-qué-puedes-escribirlo)
7. Te piden añadir una regla de validación por tipo de movimiento cada vez que negocio inventa uno, sin tocar el servicio que las aplica. Diseña la solución con lo que da el contenedor, di qué principio SOLID estás cobrando y cómo fijas el orden de ejecución de las reglas. — [`03` §5](03-inyeccion-de-dependencias.md#5--inyectar-varios-el-strategy-que-sale-gratis)
8. Quieres que el `X-Request-Id` esté disponible en toda la pila sin pasarlo por parámetro. Compara un bean de scope `request`, un `ThreadLocal` propio y el MDC del logger: di cuál sobrevive a un salto `@Async` y cuál no existe siquiera en WebFlux. — [`04` §6](04-scopes-de-bean.md#6--los-scopes-web-y-dónde-no-existen) · [`08` §8](08-modelo-de-ejecucion-web.md#8--threadlocal-el-contexto-que-viaja-pegado-al-hilo) · [`18` §5](18-asincronia-scheduling-y-eventos.md#5--propagación-de-contexto-lo-que-se-queda-en-el-hilo-del-request)
9. La self-invocation rompe `@Transactional`, `@Cacheable` y `@PreAuthorize` por el mismo motivo, pero el síntoma es distinto en cada una. Descríbelos, y di cuál de los tres es un incidente de seguridad y no un bug de rendimiento. — [`05` §5](05-proxies-y-aop.md#5-️-self-invocation-el-fallo-silencioso-número-uno) · [`17` §4](17-cache.md#4-️-el-proxy-otra-vez-self-invocation) · [`20` §8](20-spring-security-el-mecanismo.md#8--method-security-el-proxy-de-05-con-otro-sombrero)
10. Te llega un método que lleva `@Transactional`, hace dentro una llamada HTTP al proveedor y encima tiene un retry. Rediséñalo: di qué queda en cada clase, en qué orden se apilan los decoradores que sobrevivan, y por qué el retry no puede quedar por fuera de la transacción. — [`05` §7](05-proxies-y-aop.md#7--cuando-hay-varios-proxies-sobre-el-mismo-método) · [`16` §8](16-transacciones.md#8--el-límite-de-la-transacción-no-es-el-límite-de-tu-método) · [`19` §7](19-resiliencia.md#7--el-orden-en-que-se-apilan)
11. El arranque muere con `Parameter 0 of constructor in com.invlab.invapi.inventory.InventoryService required a bean of type ... that could not be found`. Da el orden de diagnóstico completo y di en qué caso concreto el bloque `Action:` del mensaje te manda al sitio equivocado. — [`06` §6](06-arranque-y-autoconfiguracion.md#6--el-informe-de-condiciones-por-qué-existe-ese-bean) · [`A03` §3](a03-catalogo-de-errores-y-diagnostico.md#3--el-contexto-que-no-arranca)
12. Operaciones necesita cambiar el `read-timeout` del proveedor en producción sin reconstruir la imagen y sin tocar el repositorio. Di qué fuente de propiedades usas, cómo se escribe esa clave en esa fuente, y qué pasa exactamente si la misma clave también está en el `application-prod.yml` del jar. — [`07` §3](07-configuracion-externalizada.md#3--el-orden-de-precedencia) · [`07` §5](07-configuracion-externalizada.md#5--relaxed-binding) · [`L09` §6](l09-empaquetado-imagen-y-limpieza.md#6--el-mismo-artefacto-en-dos-entornos-variables-de-entorno-y-el-perfil-prod)
13. Distingue `@Profile`, `@ConditionalOnProperty` y `@ConditionalOnMissingBean` por quién los evalúa y en qué momento. Después contesta: ¿sirve alguno de los tres como feature flag que negocio pueda apagar sin desplegar, y por qué la respuesta honesta incomoda? — [`07` §7](07-configuracion-externalizada.md#7--profiles) · [`02` §8](02-contenedor-ioc-y-ciclo-de-vida.md#8--registro-condicional-profile-y-conditional) · [`06` §5](06-arranque-y-autoconfiguracion.md#5--las-condiciones)
14. Nombra tres anotaciones del curso que no hacen absolutamente nada si falta su `@Enable*` correspondiente, y di qué síntoma deja cada ausencia: cuál falla en el arranque, cuál falla en la primera invocación y cuál no falla nunca. — [`A02` §3](a02-catalogo-de-anotaciones.md#3-️-dónde-una-anotación-no-hace-nada) · [`05` §5](05-proxies-y-aop.md#5-️-self-invocation-el-fallo-silencioso-número-uno)
15. Tienes Tomcat con 200 hilos, un Hikari de 10 conexiones y un proveedor externo que responde en 800 ms. Calcula el techo de capacidad de la aplicación, di cuál de esos tres números limita de verdad y cuál subirías primero — y qué medirías antes de tocar ninguno. — [`08` §2](08-modelo-de-ejecucion-web.md#2--una-instancia-muchos-hilos) · [`15` §2](15-datos-jdbc-jpa-mongo-y-redis.md#2--el-datasource-y-hikaricp) · [`13` §2](13-clientes-http.md#2-️-no-hay-timeout-por-defecto-y-ese-es-el-tema)
16. Te dan tres encargos: correlacionar peticiones con un `X-Request-Id`, registrar auditoría de negocio con el usuario autenticado, y unificar el formato de los errores. Reparte cada uno entre `Filter`, `HandlerInterceptor` y `@RestControllerAdvice`, justificando qué ve cada capa del `SecurityContext`. — [`08` §5](08-modelo-de-ejecucion-web.md#5--filtro-interceptor-o-advice) · [`20` §6](20-spring-security-el-mecanismo.md#6--securitycontextholder-un-threadlocal-y-sus-dos-fugas) · [`L03` §8](l03-api-rest-filtros-y-errores.md#8--la-excepción-del-filtro-el-interceptor-y-quién-corre-antes)
17. Un cliente se queja de que la API responde 500 a un parámetro de query inválido y 415 donde él esperaba 400. Reconstruye qué excepción produjo cada respuesta y di qué hay que configurar para que las dos salgan como `ProblemDetail` con el mismo formato. — [`09` §8](09-rest-con-spring-mvc.md#8--406-415-y-400-tres-fallos-que-no-se-parecen) · [`10` §3](10-diseno-de-api-validacion-errores-e-hipermedia.md#3--valid-vs-validated-y-qué-excepción-lanza-cada-caso) · [`A03` §5](a03-catalogo-de-errores-y-diagnostico.md#5-️-el-borde-web-el-código-de-estado-que-miente)
18. El equipo serializa la entidad de JPA directamente como respuesta HTTP y defiende que un DTO es *boilerplate*. Da los tres daños concretos —de contrato, de runtime y de seguridad— y di cuál de los tres usarías para cerrar la discusión en una revisión. — [`09` §7](09-rest-con-spring-mvc.md#7--httpmessageconverter-y-jackson) · [`15` §7](15-datos-jdbc-jpa-mongo-y-redis.md#7-️-lazyinitializationexception-y-open-in-view)
19. Diseña la respuesta de error de una API de banca: qué campos lleva, qué información no puede aparecer nunca en el cuerpo, y por qué el 401 que devuelve Spring Security no pasa por tu `@RestControllerAdvice` ni adopta ese formato. — [`10` §5](10-diseno-de-api-validacion-errores-e-hipermedia.md#5--problemdetail-y-rfc-9457) · [`20` §9](20-spring-security-el-mecanismo.md#9--401-frente-a-403-quién-los-escribe)
20. `POST /api/movements` mueve dinero y el cliente reintenta por timeout. Diseña la idempotencia: quién genera la clave, en qué punto respecto del commit se registra, qué devuelves si llega repetida con el mismo cuerpo y qué si llega con uno distinto. — [`10` §7](10-diseno-de-api-validacion-errores-e-hipermedia.md#7--idempotencia-el-mismo-post-dos-veces) · [`16` §8](16-transacciones.md#8--el-límite-de-la-transacción-no-es-el-límite-de-tu-método) · [`19` §3](19-resiliencia.md#3--retry-cuándo-ayuda-y-cuándo-empeora-la-caída)
21. Tienes que paginar una tabla de cuarenta millones de eventos. Compara `Page`, `Slice` y cursor por lo que cada uno ejecuta contra la base, di cuál eliges para una pantalla de "siguiente" y cuál para una exportación, y por qué no se devuelve un `Page` tal cual. — [`10` §9](10-diseno-de-api-validacion-errores-e-hipermedia.md#9--paginación-page-slice-y-cursor) · [`15` §4](15-datos-jdbc-jpa-mongo-y-redis.md#4--spring-data-el-repositorio-que-nadie-implementa)
22. Un compañero envuelve el repositorio JPA en `Mono.fromCallable` para "hacer reactivo" el servicio. Di en qué `Scheduler` tiene que correr eso, qué sigue limitando la concurrencia real, y qué le pasa al `traceId` que venías propagando por MDC. — [`11` §5](11-webflux-y-reactor.md#5--schedulers-y-la-regla-de-oro) · [`11` §7](11-webflux-y-reactor.md#7--el-contexto-reactivo-context-y-contextview) · [`23` §10](23-actuator-y-observabilidad.md#10--trazas-traceid-spanid-w3c-y-sampling)
23. Activas `spring.threads.virtual.enabled=true` en un servicio MVC que tiene Hikari en 10 y un executor de `@Async` con ocho hilos. Enumera qué cambia, qué no cambia, y nombra el fallo de *pinning* con la construcción de Java 21 que lo provoca. — [`12` §4](12-reactivo-bloqueante-y-virtual-threads.md#4--lo-que-los-virtual-threads-no-arreglan) · [`18` §4](18-asincronia-scheduling-y-eventos.md#4-️-el-executor-los-tres-números-y-la-cola-traicionera) · [`15` §2](15-datos-jdbc-jpa-mongo-y-redis.md#2--el-datasource-y-hikaricp)
24. Ningún cliente HTTP del curso trae timeout de lectura por defecto. Enumera los tres techos que hacen falta para acotar de verdad una llamada saliente, di cuál de ellos no se configura en la `ClientHttpRequestFactory`, y con qué pieza se pone. — [`13` §2](13-clientes-http.md#2-️-no-hay-timeout-por-defecto-y-ese-es-el-tema) · [`13` §4](13-clientes-http.md#4--la-clienthttprequestfactory-timeouts-y-pool) · [`19` §2](19-resiliencia.md#2--el-timeout-es-el-primero-y-sin-él-nada-más-sirve)
25. Da el veredicto del curso sobre los cinco clientes HTTP en una frase por cada uno, y después defiende el caso contrario: en qué situación concreta de un banco seguirías eligiendo Feign sabiendo lo que sabes. — [`13` §9](13-clientes-http.md#9--los-cinco-y-el-veredicto) · [`01` §9](01-spring-boot-y-el-ecosistema.md#9--el-mapa-del-ecosistema)
26. Migras un endpoint de MVC a WebFlux y te llevas el `Filter` que ponía el `X-Request-Id`. Di qué tienes que cambiar, qué le pasa al `SecurityContext` y por qué leer el cuerpo ahí duele más que en el mundo servlet. — [`11` §6](11-webflux-y-reactor.md#6--el-stack-netty-webfilter-y-los-dos-estilos-de-endpoint) · [`08` §6](08-modelo-de-ejecucion-web.md#6-️-leer-el-cuerpo-en-un-filtro-lo-destruye)
27. El servicio va lento y el equipo propone subir el pool de Hikari de 10 a 50. Di qué métrica y qué endpoint consultas antes de aceptar, y nombra las dos causas del curso en las que subir el pool empeora el problema en vez de resolverlo. — [`15` §2](15-datos-jdbc-jpa-mongo-y-redis.md#2--el-datasource-y-hikaricp) · [`16` §7](16-transacciones.md#7--los-seis-silencios) · [`L04` §7](l04-datos-y-transacciones.md#7-️-requires_new-y-el-deadlock-de-pool)
28. Apagas `spring.jpa.open-in-view` y aparecen `LazyInitializationException` en tres endpoints que funcionaban. Explica qué te está diciendo eso sobre el diseño de esos endpoints y ordena las tres correcciones posibles de mejor a peor, con el criterio. — [`15` §7](15-datos-jdbc-jpa-mongo-y-redis.md#7-️-lazyinitializationexception-y-open-in-view) · [`15` §6](15-datos-jdbc-jpa-mongo-y-redis.md#6-️-n1-una-consulta-que-se-convierte-en-doscientas)
29. Hay que añadir una columna a `inventory_item` en una release regulada. Di quién aplica el cambio de esquema y por qué no Hibernate, qué hace Flyway al arrancar si alguien editó un script ya aplicado, y qué exige todo eso del pipeline de CI/CD. — [`15` §9](15-datos-jdbc-jpa-mongo-y-redis.md#9--flyway-y-por-qué-el-esquema-no-lo-genera-hibernate) · [`L04` §2](l04-datos-y-transacciones.md#2--postgres-en-compose-flyway-y-el-teardown)
30. Te dan a elegir entre `JdbcClient`, un repositorio derivado de Spring Data JPA y una consulta a Mongo para tres casos: un informe de conciliación con cinco joins, el alta de un movimiento, y una proyección de solo lectura. Asigna y justifica cada uno. — [`15` §3](15-datos-jdbc-jpa-mongo-y-redis.md#3--jdbcclient-y-la-jerarquía-de-dataaccessexception) · [`15` §8](15-datos-jdbc-jpa-mongo-y-redis.md#8--mongo-y-redis-qué-te-da-spring-data-y-cuál-es-la-trampa)
31. Un desarrollador junior te enseña un método `@Transactional` que no hizo rollback y jura que "la anotación está puesta". Explícale la causa en sesenta segundos cubriendo las tres razones posibles, ordenadas por frecuencia real. — [`16` §6](16-transacciones.md#6-️-rollback-la-regla-que-casi-todo-el-mundo-dice-mal) · [`05` §5](05-proxies-y-aop.md#5-️-self-invocation-el-fallo-silencioso-número-uno)
32. Quieren `REQUIRES_NEW` para que la auditoría se guarde aunque el negocio falle. Explica cuántas conexiones consume eso por petición, por qué es la receta del deadlock de pool, y cuál es la alternativa que enseña el curso para el mismo requisito. — [`16` §4](16-transacciones.md#4--propagación) · [`18` §9](18-asincronia-scheduling-y-eventos.md#9--el-evento-que-espera-al-commit) · [`L04` §7](l04-datos-y-transacciones.md#7-️-requires_new-y-el-deadlock-de-pool)
33. El caso es escribir en la base y publicar un mensaje, y tiene que ser todo o nada. Di por qué el curso desaconseja XA, qué garantiza exactamente `@TransactionalEventListener(AFTER_COMMIT)`, qué hueco deja abierto y qué patrón lo cubre. — [`16` §9](16-transacciones.md#9--cuando-la-transacción-cruza-dos-sistemas) · [`18` §9](18-asincronia-scheduling-y-eventos.md#9--el-evento-que-espera-al-commit)
34. Dos peticiones ajustan a la vez el stock del mismo SKU. Di qué ves con el aislamiento por defecto de Postgres, por qué subir a `SERIALIZABLE` no es la respuesta habitual, y qué mecanismo se usa en su lugar y qué excepción hay que estar dispuesto a reintentar. — [`16` §5](16-transacciones.md#5--aislamiento) · [`19` §3](19-resiliencia.md#3--retry-cuándo-ayuda-y-cuándo-empeora-la-caída)
35. Te encuentras `@Transactional` en un controller. Enumera todo lo que acaba de quedar dentro de esa transacción que no debería estar, di cuánto tiempo retiene la conexión en el peor caso, y dónde va el límite correcto. — [`16` §8](16-transacciones.md#8--el-límite-de-la-transacción-no-es-el-límite-de-tu-método) · [`09` §7](09-rest-con-spring-mvc.md#7--httpmessageconverter-y-jackson)
36. Te piden cachear `GET /api/items/{sku}` y también la consulta de saldo de una cuenta. Di cuál sí, cuál no y con qué argumento, y qué dato pedirías antes de tomar la decisión en lugar de decidirlo por intuición. — [`17` §1](17-cache.md#1--el-problema-la-misma-respuesta-calculada-mil-veces) · [`17` §10](17-cache.md#10--sin-hit-ratio-esto-es-una-suposición)
37. Con tres réplicas de `inv-api`, decide entre Caffeine local y Redis compartido. Da el veredicto del curso, di qué incoherencia concreta aparece con la caché local tras un `@CacheEvict`, y qué se paga al mover esa caché a Redis. — [`17` §5](17-cache.md#5--local-o-distribuida-el-veredicto) · [`17` §6](17-cache.md#6--redis-como-caché-ttl-por-caché-y-serialización) · [`L06` §5](l06-cache-y-asincronia.md#5-️-dos-instancias-dos-cachés-dos-verdades)
38. Compara las tres formas de invalidar una entrada —TTL, evento y versión de clave— y di cuál es la red de seguridad de cuál. Después explica por qué un `@CachePut` dentro de un método transaccional puede dejar cacheado un dato que nunca existió. — [`17` §9](17-cache.md#9--invalidación-coherencia-y-qué-no-se-cachea) · [`16` §8](16-transacciones.md#8--el-límite-de-la-transacción-no-es-el-límite-de-tu-método)
39. Diseña el executor de `@Async` para enviar notificaciones desde una API de banca: di qué valores das a los tres números, qué política de rechazo eliges y por qué `CallerRunsPolicy`, que parece la prudente, puede tumbar el borde web. — [`18` §4](18-asincronia-scheduling-y-eventos.md#4-️-el-executor-los-tres-números-y-la-cola-traicionera) · [`08` §2](08-modelo-de-ejecucion-web.md#2--una-instancia-muchos-hilos)
40. Tres réplicas del servicio tienen el mismo `@Scheduled` que dispara el job de conciliación. Enumera las tres salidas, di cuál eliges en banca y por qué `JobExecutionAlreadyRunningException` protege de la duplicación pero no es un scheduler distribuido. — [`18` §7](18-asincronia-scheduling-y-eventos.md#7-️-tres-réplicas-tres-ejecuciones) · [`22` §10](22-spring-batch.md#10--lanzarlo-probarlo-y-vigilarlo) · [`L06` §9](l06-cache-y-asincronia.md#9-️-scheduled-por-duplicado-el-rlock-y-shedlock)
41. Tu endpoint promete responder en dos segundos y llama en serie a dos proveedores, uno de ellos con tres intentos de retry. Haz la aritmética del peor caso, di si el presupuesto se cumple y qué recortarías primero si no se cumple. — [`19` §2](19-resiliencia.md#2--el-timeout-es-el-primero-y-sin-él-nada-más-sirve) · [`19` §7](19-resiliencia.md#7--el-orden-en-que-se-apilan) · [`L05` §6](l05-clientes-y-resiliencia.md#6--el-orden-de-los-decoradores-invertido-a-propósito)
42. Un fallback devuelve el último precio conocido cuando el proveedor no responde. Di en qué condiciones eso es honesto y en cuáles es un fraude operativo, qué tiene que acompañarlo siempre, y cuál es el caso en que el fallback correcto es no tener ninguno. — [`19` §8](19-resiliencia.md#8--el-fallback-honesto) · [`17` §9](17-cache.md#9--invalidación-coherencia-y-qué-no-se-cachea) · [`23` §9](23-actuator-y-observabilidad.md#9--prometheus-el-scrape-y-las-cuatro-señales-doradas)
43. Son las tres de la mañana y el circuito hacia `inv-supplier` está abierto. Di qué ves en el tablero, por qué la tasa de 5xx puede estar **bajando** mientras el incidente empeora, sobre qué métrica se escribe la alerta y cuál es tu primera acción. — [`19` §9](19-resiliencia.md#9--sin-métricas-esto-es-fe) · [`23` §9](23-actuator-y-observabilidad.md#9--prometheus-el-scrape-y-las-cuatro-señales-doradas) · [`L07` §9](l07-actuator-metricas-y-trazas.md#9-️-la-alerta-sobre-el-circuito-de-l05)
44. Diseña el `health` de `inv-api` para un orquestador: qué comprueba `liveness`, qué comprueba `readiness`, y por qué meter la disponibilidad de `inv-supplier` en uno de los dos puede tumbar el despliegue entero en cascada. — [`23` §4](23-actuator-y-observabilidad.md#4--health-grupos-indicators-propios-y-show-details) · [`19` §5](19-resiliencia.md#5--circuit-breaker-dejar-de-insistir-sobre-lo-que-está-roto)
45. Producto quiere una métrica etiquetada por `sku` "para ver qué se consulta más". Explica qué le pasa a Prometheus, por qué el daño no se queda en esa métrica, qué ofreces en su lugar y dónde sí puede vivir el `sku`. — [`23` §8](23-actuator-y-observabilidad.md#8-️-tags-y-cardinalidad-el-error-que-tumba-prometheus) · [`23` §11](23-actuator-y-observabilidad.md#11--logging-correlación-json-y-lo-que-no-se-escribe-nunca) · [`L07` §6](l07-actuator-metricas-y-trazas.md#6-️-el-experimento-de-la-cardinalidad)
46. Sigue el `traceId` de una petición desde el borde hasta el log de un método `@Async`, hasta la llamada a `inv-supplier` y hasta el job de Batch que se dispara después. Di qué lo transporta en cada salto y en cuál de ellos se pierde si no haces nada. — [`23` §10](23-actuator-y-observabilidad.md#10--trazas-traceid-spanid-w3c-y-sampling) · [`18` §5](18-asincronia-scheduling-y-eventos.md#5--propagación-de-contexto-lo-que-se-queda-en-el-hilo-del-request) · [`22` §10](22-spring-batch.md#10--lanzarlo-probarlo-y-vigilarlo)
47. Diseña las cadenas de seguridad de `inv-api`: una para la API con Bearer y otra para Actuator en el puerto de management. Di qué lleva cada una, en qué orden se declaran, y qué le ocurre a una URL que no matchea ninguna. — [`20` §3](20-spring-security-el-mecanismo.md#3--la-cadena-se-declara-como-bean) · [`20` §10](20-spring-security-el-mecanismo.md#10--asegurar-actuator-sin-escribir-rutas-a-mano) · [`23` §3](23-actuator-y-observabilidad.md#3--el-puerto-de-management-separado)
48. Compara autorizar en la cadena HTTP con `requestMatchers` frente a autorizar en el servicio con `@PreAuthorize`. Di qué caso solo resuelve el segundo, qué le cuesta al proxy, y cómo evitas que una regla nueva se quede sin poner. — [`20` §7](20-spring-security-el-mecanismo.md#7--autorización-http-y-el-prefijo-role_) · [`20` §8](20-spring-security-el-mecanismo.md#8--method-security-el-proxy-de-05-con-otro-sombrero) · [`05` §5](05-proxies-y-aop.md#5-️-self-invocation-el-fallo-silencioso-número-uno)
49. La auditoría tiene que registrar quién hizo qué. Di de dónde sacas la identidad en el hilo del request, dentro de un `@Async`, dentro de un listener `AFTER_COMMIT` y dentro de un job de Batch — y cuál de los cuatro te obliga a pasarla como parámetro. — [`20` §6](20-spring-security-el-mecanismo.md#6--securitycontextholder-un-threadlocal-y-sus-dos-fugas) · [`18` §9](18-asincronia-scheduling-y-eventos.md#9--el-evento-que-espera-al-commit) · [`L08` §7](l08-security-y-batch.md#7-️-el-securitycontext-que-no-cruza-al-async)
50. Un auditor pregunta por qué vuestra API desactiva CSRF. Da el argumento exacto, di qué habría cambiado si la API usara cookie de sesión, y explica qué relación tiene todo esto con la configuración de CORS que sí hace falta. — [`20` §11](20-spring-security-el-mecanismo.md#11--csrf-cors-y-sesión-las-tres-que-rompen-una-api) · [`09` §9](09-rest-con-spring-mvc.md#9--webmvcconfigurer-el-punto-de-extensión-de-mvc)
51. `inv-api` es resource server con `issuer-uri`. Enumera en orden lo que valida de un JWT entrante y después cuenta qué ocurre, paso a paso, el día que el IdP rota su clave de firma a media tarde sin avisar. — [`21` §4](21-identidad-federada-oauth2-oidc-y-jwt.md#4--qué-valida-un-resource-server-y-en-qué-orden) · [`21` §5](21-identidad-federada-oauth2-oidc-y-jwt.md#5--firma-simétrica-asimétrica-y-el-jwk-set-endpoint)
52. El `client-secret` del flujo `client_credentials` está en `application-prod.yml`, cifrado con una clave que vive en el mismo repositorio. Explica por qué eso no es un secreto, da dos salidas que Boot soporta, y di qué identidad viaja realmente en ese flujo. — [`21` §8](21-identidad-federada-oauth2-oidc-y-jwt.md#8--propagar-la-identidad-al-llamar-a-otro-servicio) · [`07` §8](07-configuracion-externalizada.md#8--importar-configuración-y-guardar-secretos)
53. Un auditor pregunta si podéis invalidar el acceso de un empleado al instante. Con JWT de treinta minutos, di qué contestas, qué compensaciones existen, qué cuesta cada una, y en qué punto la respuesta correcta es cambiar a token opaco. — [`21` §9](21-identidad-federada-oauth2-oidc-y-jwt.md#9-️-el-token-no-es-una-sesión-revocar-caducar-y-qué-no-meter-dentro) · [`20` §11](20-spring-security-el-mecanismo.md#11--csrf-cors-y-sesión-las-tres-que-rompen-una-api)
54. Un arquitecto propone resolver la conciliación nocturna con un bucle `@Transactional` dentro de un `@Scheduled`. Explícale qué le da el `JobRepository` de Spring Batch que ese bucle no le da, y qué le exige a cambio al `ItemReader`. — [`22` §3](22-spring-batch.md#3--el-chunk-leer-uno-procesar-uno-escribir-de-a-muchos) · [`22` §6](22-spring-batch.md#6--restart-qué-se-reanuda-y-qué-tiene-que-cumplir-tu-reader) · [`16` §4](16-transacciones.md#4--propagación)
55. Diseña los `JobParameters` del `inventory-reconciliation-job` de modo que se pueda relanzar el día que falle y **no** se pueda relanzar el día que terminó bien. Di qué parámetros son identificadores, cuáles no, y qué capacidad pierdes si añades un `run.id` con la marca de tiempo. — [`22` §5](22-spring-batch.md#5--jobparameters-por-qué-no-puedes-relanzar-lo-mismo-dos-veces) · [`L08` §10](l08-security-y-batch.md#10--caído-a-la-mitad-y-reanudado-las-tablas-antes-y-después)
56. El fichero de entrada trae un 2 % de registros corruptos y negocio quiere que el lote termine igual. Decide entre `skip` y `retry`, di qué le falta a un `skipLimit(10)` para que descartar no sea perder datos, y qué alerta escribes. — [`22` §7](22-spring-batch.md#7--skip-y-retry-cuando-un-registro-malo-no-puede-tumbar-el-lote) · [`23` §9](23-actuator-y-observabilidad.md#9--prometheus-el-scrape-y-las-cuatro-señales-doradas)
57. La suite del proyecto tarda doce minutos y bloquea el pipeline. Da tu plan de ataque en orden, diciendo qué mides primero, qué cambio devuelve más minutos por hora invertida, y qué **no** harías aunque acortara la suite. — [`24` §6](24-testing.md#6-️-la-caché-de-contextos-aquí-se-van-los-ocho-minutos) · [`24` §4](24-testing.md#4--los-slices-qué-autoconfigura-cada-uno-y-qué-deja-fuera)
58. Sitúa en la escala de pruebas del curso estos cuatro encargos: validar el formato de un error, comprobar una consulta con `@EntityGraph`, verificar que un endpoint devuelve 403 sin el rol, y demostrar que el timeout del cliente HTTP funciona. Di qué herramienta usas en cada uno y cuál no se puede probar con un mock. — [`24` §4](24-testing.md#4--los-slices-qué-autoconfigura-cada-uno-y-qué-deja-fuera) · [`24` §10](24-testing.md#10--seguridad-resiliencia-asincronía-y-reactivo) · [`13` §6](13-clientes-http.md#6--errores-un-4xx-no-es-un-fallo-de-red)
59. Da tres casos del curso en los que la suite está verde y producción está rota, con su corrección: el test transaccional, el proveedor moqueado y la base embebida. Di cuál de los tres es el más caro de descubrir tarde. — [`24` §8](24-testing.md#8-️-transactional-en-el-test-el-rollback-que-oculta-bugs) · [`24` §9](24-testing.md#9--testcontainers-y-serviceconnection-y-por-qué-no-h2)
60. Son las dos de la mañana: `inv-api` responde 200 pero tarda seis segundos, y los logs no traen `traceId`. Da tu secuencia de diagnóstico con las herramientas del curso, nombrando en cada paso el endpoint o el comando y qué hipótesis descarta. — [`A03` §2](a03-catalogo-de-errores-y-diagnostico.md#2--índice-por-síntoma) · [`A01` §13](a01-cli-y-tooling-de-supervivencia.md#13--atajos-de-depuración) · [`L07` §11](l07-actuator-metricas-y-trazas.md#11--threaddump-en-plena-saturación)

---

## 3. ⚖ Escenario 1 — El monolito transaccional que hay que partir

**El encargo.** Un monolito Spring Boot de banca registra movimientos y actualiza
posiciones en el mismo método `@Transactional`: una fila en `inventory_event` y un
`UPDATE` sobre `inventory_item`, commit único. El área de posiciones quiere desplegar por
su cuenta y propone extraerla como servicio. Te preguntan cómo lo harías.

**La decisión difícil.** No es "REST o mensajería". Es que en el momento en que las dos
escrituras viven en dos bases, **la atomicidad que hoy te regala la base de datos deja de
existir**, y alguien tiene que firmar que "posición actualizada" pasa a ser una promesa
con retardo en lugar de un hecho.

**Cómo lo contestaría.**

Primero, la pregunta previa, que es la que distingue a un Tech Lead de un implementador:
¿el límite está bien puesto? Movimiento y posición son la misma decisión de negocio vista
dos veces. Muchas transacciones distribuidas son un servicio mal partido, y decirlo en voz
alta es parte de la respuesta ([`16` §9](16-transacciones.md#9--cuando-la-transacción-cruza-dos-sistemas)).

Si aun así hay que partir —y en banca suele haberlo, por razones de equipo y no de
técnica—, la ruta es esta:

1. **XA se descarta, con argumento.** Boot no trae `JtaTransactionManager` activado,
   exige un coordinador, añade latencia, introduce un punto único de fallo y deja estado
   que hay que recuperar a mano tras una caída. No es que sea imposible: es que el precio
   operativo no lo paga nadie.
2. **La escritura local sigue siendo una sola transacción.** El movimiento se guarda y,
   **en la misma transacción**, se inserta una fila en una tabla de salida. Eso es el
   outbox, y su virtud es que no hay nada que coordinar: o se guardan las dos o ninguna.
3. **La publicación va después del commit.** Un `@TransactionalEventListener(AFTER_COMMIT)`
   —y `@Async` encima, para no retener el hilo ni la conexión ⏱️— empuja lo que el outbox
   registró ([`18` §9](18-asincronia-scheduling-y-eventos.md#9--el-evento-que-espera-al-commit)). El hueco que queda es honesto y hay que nombrarlo: **entre el commit y
   el listener no hay atomicidad**, y si el proceso muere ahí el evento no salió. Por eso
   el outbox es la tabla y el listener solo el empujón: un proceso de barrido reenvía lo
   que quedó sin marcar.
4. **La compensación es de negocio, no técnica.** Si la posición no puede aplicarse, el
   paso compensatorio lo define negocio —un asiento de reverso, no un `DELETE`—, que es lo
   que distingue una saga de un rollback disfrazado.
5. **La observabilidad entra en el diseño, no después.** El `traceId` cruza el salto
   ([`23` §10](23-actuator-y-observabilidad.md#10--trazas-traceid-spanid-w3c-y-sampling)) y la alerta no es "falló": es **antigüedad de la fila más vieja sin publicar
   en el outbox**. Esa métrica es la que convierte la consistencia eventual en algo
   verificable en vez de una promesa.

Y la llamada entre servicios, cuando exista, lleva su timeout y su circuito desde el
primer día ([`13` §2](13-clientes-http.md#2-️-no-hay-timeout-por-defecto-y-ese-es-el-tema)): un servicio nuevo sin techo de latencia es un monolito con más puntos
de fallo.

> **El intercambio, dicho en voz alta:** *compras despliegue independiente y pagas que el
> saldo deje de ser instantáneo. La pregunta que tiene que contestar negocio no es
> técnica: ¿cuántos segundos de divergencia son aceptables, y quién los firma?*

**Dónde se estudia:** [`16` §9](16-transacciones.md#9--cuando-la-transacción-cruza-dos-sistemas) · [`16` §8](16-transacciones.md#8--el-límite-de-la-transacción-no-es-el-límite-de-tu-método) · [`18` §9](18-asincronia-scheduling-y-eventos.md#9--el-evento-que-espera-al-commit) · [`13` §2](13-clientes-http.md#2-️-no-hay-timeout-por-defecto-y-ese-es-el-tema) · [`23` §10](23-actuator-y-observabilidad.md#10--trazas-traceid-spanid-w3c-y-sampling)

---

## 4. ⚖ Escenario 2 — El batch nocturno que ya no cabe en la ventana

**El encargo.** El `inventory-reconciliation-job` procesa ocho millones de registros con
`chunk(500)` en un solo hilo. La ventana operativa son cuatro horas y el job lleva cinco
horas y diez minutos: dos noches seguidas terminó con el negocio ya abierto. Te piden un
plan para la semana que viene.

**La decisión difícil.** Las cuatro formas de paralelizar no cuestan lo mismo. La más
barata de escribir —dar un `TaskExecutor` al `StepBuilder`— es la que **rompe la semántica
de reinicio**, que es justo la propiedad por la que se eligió Spring Batch. Y la que la
conserva exige partir el dominio, que es trabajo de análisis y no de código.

**Cómo lo contestaría.**

Antes de paralelizar nada, **medir en un solo hilo**. Las métricas de Micrometer de Batch
—`spring.batch.job`, `.step`, `.item.read`, `.item.process`, `.chunk.write`— dicen dónde
se van las cinco horas ([`22` §10](22-spring-batch.md#10--lanzarlo-probarlo-y-vigilarlo)). Tres resultados posibles y tres respuestas distintas:

- **Si el tiempo está en el `read`**, probablemente sea un N+1 encubierto o un cursor sin
  `fetchSize`, y ahí se arregla en la consulta ([`15` §6](15-datos-jdbc-jpa-mongo-y-redis.md#6-️-n1-una-consulta-que-se-convierte-en-doscientas)) sin tocar la arquitectura del job.
- **Si está en el `chunk.write`**, el candidato es el tamaño del chunk: 500 filas por
  transacción puede ser demasiado poco si cada commit cuesta, y demasiado si el rollback
  de un chunk fallido rehace mucho trabajo.
- **Si el trabajo es genuinamente CPU o red por ítem**, entonces sí toca paralelizar.

Y ahí la comparación, que es la respuesta que buscan:

| Forma | Qué compras | Qué pagas |
|---|---|---|
| **Multithreaded step** | media tarde de trabajo | reader y writer thread-safe, y el reanudado deja de ser fiable |
| **Parallel steps** (`split`) | flujos independientes a la vez | solo sirve si de verdad son independientes |
| **Partitioning** | reinicio intacto por partición | hay que saber partir el dominio |
| **Remote chunking** | escala fuera de la JVM | infraestructura de mensajería que alguien opera |

**La elección para banca es el partitioning**, y el argumento es exactamente el de la
segunda columna: cada partición corre como **su propio `StepExecution`, con su fila y su
`ExecutionContext`**, así que si falla la partición 7 se reanuda la partición 7. En un
proceso regulado, poder contestar "¿por dónde iba cuando se cayó?" no es una comodidad, es
un requisito ([`22` §9](22-spring-batch.md#9--flujo-y-paralelismo-cuatro-formas-y-lo-que-cada-una-cobra)).

Dos consecuencias operativas que hay que decir sin que las pregunten:

- **El pool.** Ocho particiones contra un Hikari de diez dejan sin conexiones al resto de
  la aplicación ⏱️. O el job corre en su propio proceso —lo natural si ya empaquetas una
  imagen, [`L09` §6](l09-empaquetado-imagen-y-limpieza.md#6--el-mismo-artefacto-en-dos-entornos-variables-de-entorno-y-el-perfil-prod)— o se le dimensiona un `DataSource` aparte.
- **La alerta correcta no es "falló".** Es **duración por encima de la ventana** y
  **`skipCount` distinto de cero**: un job que termina en verde a las nueve de la mañana
  ya causó el incidente ([`23` §9](23-actuator-y-observabilidad.md#9--prometheus-el-scrape-y-las-cuatro-señales-doradas)).

> **El intercambio, dicho en voz alta:** *el multithreaded step me da el resultado el
> viernes y me quita la capacidad de reanudar; el partitioning me cuesta dos semanas de
> análisis del dominio y me la conserva. En un proceso regulado, la reanudabilidad no es
> negociable, así que negocio el plazo, no la propiedad.*

**Dónde se estudia:** [`22` §9](22-spring-batch.md#9--flujo-y-paralelismo-cuatro-formas-y-lo-que-cada-una-cobra) · [`22` §3](22-spring-batch.md#3--el-chunk-leer-uno-procesar-uno-escribir-de-a-muchos) · [`22` §6](22-spring-batch.md#6--restart-qué-se-reanuda-y-qué-tiene-que-cumplir-tu-reader) · [`15` §2](15-datos-jdbc-jpa-mongo-y-redis.md#2--el-datasource-y-hikaricp) · [`L08` §10](l08-security-y-batch.md#10--caído-a-la-mitad-y-reanudado-las-tablas-antes-y-después)

---

## 5. ⚖ Escenario 3 — El proveedor que se pone lento

**El encargo.** Un martes a las once, `inv-supplier` pasa de responder en 80 ms a
responder en 30 segundos. No devuelve errores: responde, tarde. A los tres minutos
`inv-api` deja de atender **todos** sus endpoints, incluidos los que no tocan al
proveedor, y el balanceador empieza a ver `connection refused`. Te toca el postmortem.

**La decisión difícil.** La parte fácil —"pon un timeout"— la contesta cualquiera. La
difícil es **qué responde el endpoint cuando el proveedor no está**, y en una API de banca
esa decisión tiene dueño fuera de ingeniería.

**Cómo lo contestaría.**

La causa, con la aritmética a la vista, porque es lo que demuestra que entiendes el modelo
de ejecución y no solo el patrón:

```text
respuesta normal   80 ms  →  200 hilos / 0,08 s = 2 500 req/s de capacidad
respuesta enferma  30 s   →  200 hilos / 30 s   = 6,6 req/s de capacidad
```

Con 100 req/s entrando, los 200 hilos se ocupan en dos segundos, la `accept-count` se
llena en uno más, y desde ahí el cliente ve `connection refused` en lugar de un 503. **No
se cayó el endpoint lento: se cayó el servicio**, porque el pool de hilos es compartido
([`13` §2](13-clientes-http.md#2-️-no-hay-timeout-por-defecto-y-ese-es-el-tema)). El `threaddump` lo confirma en un minuto: doscientos hilos en
`sun.nio.ch.SocketDispatcher.read0` ([`L07` §11](l07-actuator-metricas-y-trazas.md#11--threaddump-en-plena-saturación)).

El orden de las correcciones, y el orden importa:

1. **El timeout primero, porque sin él nada más funciona.** `connect-timeout` y
   `read-timeout` en la `ClientHttpRequestFactory`, y un techo total por encima, porque
   ninguno de los dos acota la llamada completa ([`13` §4](13-clientes-http.md#4--la-clienthttprequestfactory-timeouts-y-pool), [`19` §2](19-resiliencia.md#2--el-timeout-es-el-primero-y-sin-él-nada-más-sirve)).
2. **El bulkhead, para que el daño no salga del endpoint.** Diez llamadas concurrentes
   como mucho hacia `inv-supplier`: el resto de la aplicación conserva sus hilos.
3. **El circuit breaker, para dejar de insistir.** Y el orden de apilado importa de
   verdad: `Retry( CircuitBreaker( RateLimiter( TimeLimiter( Bulkhead ))))`. Con el retry
   por fuera, cada intento cuenta como una llamada del breaker y el circuito abre antes,
   que es lo que protege al proveedor; invertido, el breaker ve una sola llamada por
   petición, tarda cinco peticiones en llegar al mínimo y el proveedor recibe el triple de
   tráfico ([`19` §7](19-resiliencia.md#7--el-orden-en-que-se-apilan), medido en [`L05` §6](l05-clientes-y-resiliencia.md#6--el-orden-de-los-decoradores-invertido-a-propósito)).
4. **El fallback, que es la decisión difícil.** Aquí hay que ser explícito: devolver el
   último precio conocido es correcto para una pantalla informativa y es **fraude
   operativo** si con ese precio se liquida una operación. Un fallback honesto dice que es
   un fallback —en la respuesta y en una métrica— y tiene caducidad. Si el dato no puede
   ser viejo, el fallback correcto es **no tener ninguno** y devolver 503 con
   `Retry-After` ([`19` §8](19-resiliencia.md#8--el-fallback-honesto)).

Y la trampa de observabilidad que casi siempre aparece en este incidente: **cuando el
fallback entra, la tasa de 5xx baja**. El tablero se pone verde mientras el negocio está
degradado, así que la alerta se escribe sobre el estado del circuito y sobre el contador
de fallbacks, no sobre los 5xx ([`19` §9](19-resiliencia.md#9--sin-métricas-esto-es-fe), [`L07` §9](l07-actuator-metricas-y-trazas.md#9-️-la-alerta-sobre-el-circuito-de-l05)).

Si alguien propone virtual threads como solución, la respuesta precisa: quitan el techo de
los 200 hilos, **no quitan el de las diez conexiones de Hikari ni el del proveedor**. Diez
mil hilos virtuales esperando a un servicio que tarda 30 segundos son diez mil esperas más
baratas, no un sistema sano ([`12` §4](12-reactivo-bloqueante-y-virtual-threads.md#4--lo-que-los-virtual-threads-no-arreglan)).

> **El intercambio, dicho en voz alta:** *el timeout convierte la degradación del otro en
> un error mío acotado; el fallback decide si prefiero una respuesta vieja o ninguna. Lo
> primero lo decido yo, lo segundo lo firma negocio.*

**Dónde se estudia:** [`13` §2](13-clientes-http.md#2-️-no-hay-timeout-por-defecto-y-ese-es-el-tema) · [`19` §7](19-resiliencia.md#7--el-orden-en-que-se-apilan) · [`19` §8](19-resiliencia.md#8--el-fallback-honesto) · [`08` §2](08-modelo-de-ejecucion-web.md#2--una-instancia-muchos-hilos) · [`12` §4](12-reactivo-bloqueante-y-virtual-threads.md#4--lo-que-los-virtual-threads-no-arreglan) · [`L05` §6](l05-clientes-y-resiliencia.md#6--el-orden-de-los-decoradores-invertido-a-propósito)

---

## 6. ⚖ Escenario 4 — La identidad a través de cinco servicios

**El encargo.** Una petición de un analista entra por el gateway y atraviesa cinco
servicios antes de escribir un ajuste. Cumplimiento exige poder decir, para cada ajuste,
qué persona lo pidió; seguridad exige que un servicio comprometido no pueda actuar como
cualquier otro. El modelo actual es pasar el mismo access token a todos. Te preguntan si
está bien.

**La decisión difícil.** Las tres opciones resuelven "el siguiente servicio no devuelve
401" y ninguna resuelve gratis las dos exigencias a la vez. La elección es entre
**comodidad** y **radio de daño**, y hay que decirlo con esas palabras.

**Cómo lo contestaría.**

Las tres formas, con su precio ([`21` §8](21-identidad-federada-oauth2-oidc-y-jwt.md#8--propagar-la-identidad-al-llamar-a-otro-servicio)):

- **Pasar el token tal cual.** Funciona si el `aud` incluye a los destinos, y es lo que
  hace medio mundo. El precio es el radio de daño: cualquier servicio de la cadena puede
  reusar ese token contra cualquier otro que lo acepte. Con cinco saltos, son cinco
  lugares desde los que suplantar al analista.
- **Token exchange en el IdP.** El token que viaja hacia dentro está dirigido al destino y
  no sirve en otro sitio. El precio es un salto de red por llamada y una dependencia dura
  del IdP en la ruta caliente.
- **Dos capas**, que es lo que suele ganar en banca: **el token del usuario muere en el
  borde**, y hacia dentro viaja un token de servicio obtenido con `client_credentials` más
  la identidad del usuario propagada como contexto.

Y aquí está la parte que separa una respuesta buena de una correcta: **si el usuario viaja
como contexto, no viaja firmado**. Un `X-User-Id` en una cabecera es un dato de
trazabilidad, no una credencial, y **ningún servicio interior puede autorizar con él**. Si
el servicio 5 tiene que decidir según el rol del analista, entonces la identidad del
usuario tiene que llegar en algo verificable —token propagado o exchange— y la arquitectura
de dos capas no aplica a ese salto. Confundir las dos cosas es cómo se construye un
sistema que parece zero-trust y autoriza por una cabecera que cualquiera puede escribir.

El resto del diseño se cae solo:

- **El token de servicio no tiene `sub` de humano** ([`21` §8](21-identidad-federada-oauth2-oidc-y-jwt.md#8--propagar-la-identidad-al-llamar-a-otro-servicio)), así que la auditoría del
  servicio 5 registra el usuario que recibió por contexto y **lo marca como propagado**,
  no como autenticado.
- **El `client-secret` no vive en el repositorio**, ni cifrado con una clave del mismo
  repositorio ([`07` §8](07-configuracion-externalizada.md#8--importar-configuración-y-guardar-secretos)).
- **La correlación la da el `traceId`**, que es lo que permite reconstruir los cinco saltos
  cuando cumplimiento pregunta ([`23` §10](23-actuator-y-observabilidad.md#10--trazas-traceid-spanid-w3c-y-sampling)).
- **mTLS no sustituye nada de esto.** Contesta "¿de qué servicio viene la conexión?", no
  "¿qué usuario pidió esto?". En banca se tiene **además**, no en lugar de.
- **Y el `SecurityContext` no cruza los saltos internos del proceso**: ni al `@Async`, ni
  al listener `AFTER_COMMIT`, ni al job de Batch ([`20` §6](20-spring-security-el-mecanismo.md#6--securitycontextholder-un-threadlocal-y-sus-dos-fugas), [`L08` §7](l08-security-y-batch.md#7-️-el-securitycontext-que-no-cruza-al-async)). Ahí la identidad se
  pasa como parámetro, explícitamente, o se pierde.

> **El intercambio, dicho en voz alta:** *propagar el token es una tarde de trabajo y cinco
> puntos de suplantación; las dos capas son un mes y un radio de daño acotado. La pregunta
> que decide es si algún servicio interior autoriza por usuario: si lo hace, el usuario
> tiene que llegar firmado y no hay atajo.*

**Dónde se estudia:** [`21` §8](21-identidad-federada-oauth2-oidc-y-jwt.md#8--propagar-la-identidad-al-llamar-a-otro-servicio) · [`21` §4](21-identidad-federada-oauth2-oidc-y-jwt.md#4--qué-valida-un-resource-server-y-en-qué-orden) · [`20` §6](20-spring-security-el-mecanismo.md#6--securitycontextholder-un-threadlocal-y-sus-dos-fugas) · [`07` §8](07-configuracion-externalizada.md#8--importar-configuración-y-guardar-secretos) · [`23` §10](23-actuator-y-observabilidad.md#10--trazas-traceid-spanid-w3c-y-sampling)

---

## 7. ⚖ Escenario 5 — La caché que devolvió datos de otro usuario

**El encargo.** Soporte reporta que un analista vio en `GET /api/items` el listado
filtrado de **otro** analista. El método está anotado así:

```java
@Cacheable("inventory-items")
List<InventoryItem> visibleItems() {
    // filtra por la sucursal del usuario autenticado
    var branch = currentUser().branch();
    return repository.findByBranch(branch);
}
```

**La decisión difícil.** El parche evidente es meter al usuario en la clave. Pero eso
convierte una caché con un 90 % de aciertos en una con cientos de claves y casi ninguno, y
entonces la caché deja de pagar su coste. La decisión real es **si esta consulta debe
cachearse**.

**Cómo lo contestaría.**

Primero el mecanismo, sin rodeos: `@Cacheable("inventory-items")` sin `key` usa el
`SimpleKeyGenerator`, y **un método sin argumentos genera `SimpleKey.EMPTY`** — una sola
entrada para todos los usuarios ([`17` §3](17-cache.md#3--la-clave-key-condition-unless-y-el-keygenerator)). El resultado depende de una identidad que el
generador de claves no ve, porque vive en el `SecurityContextHolder` y no en la firma del
método. Es la fuga clásica que el curso nombra con todas sus letras: **si el resultado
depende de la identidad, la identidad va en la clave** ([`17` §9](17-cache.md#9--invalidación-coherencia-y-qué-no-se-cachea)).

Dos agravantes que conviene mencionar porque demuestran que ves el sistema entero:

- **El bean es singleton y atiende doscientos hilos a la vez** ([`04` §3](04-scopes-de-bean.md#3--singleton-uno-por-contexto-y-qué-exige-a-cambio), [`08` §2](08-modelo-de-ejecucion-web.md#2--una-instancia-muchos-hilos)). Lo que
  entra en la caché es de quien llegó primero, y quién llega primero cambia en cada
  despliegue: por eso el bug es intermitente y no aparece en pruebas.
- **Con Redis compartido, la fuga cruza réplicas y sobrevive al reinicio.** Con Caffeine
  local muere con el proceso, lo que la hace más difícil de reproducir y no menos grave.

Las tres salidas, en orden de preferencia:

1. **Quitar la caché de ese método y cachear la pieza que no depende del usuario.** El
   catálogo de ítems es común; el filtro por sucursal es barato. Se cachea lo compartido y
   se filtra después. Es la corrección que conserva el hit ratio.
2. **Meter la identidad en la clave** —`key = "#root.methodName + ':' + branch"`, con la
   sucursal como parámetro explícito del método en lugar de sacarla del contexto—. Es
   correcta, y hay que decir lo que cuesta: tantas entradas como sucursales, y la pregunta
   de si con ese hit ratio la caché sigue valiendo la pena ([`17` §10](17-cache.md#10--sin-hit-ratio-esto-es-una-suposición)).
3. **No cachear.** Si el dato es sensible y cambia seguido, una caché es un generador de
   respuestas incorrectas con mejor latencia.

Y la prevención, que es lo que te preguntan al final: **regla de revisión de código** —un
`@Cacheable` sobre un método que lee del `SecurityContext` no pasa—, y un test que pruebe
con dos usuarios distintos, porque el que prueba con uno solo siempre pasa.

> **El intercambio, dicho en voz alta:** *meter al usuario en la clave arregla la fuga hoy
> y me deja una caché que no acierta; sacar la identidad del método y cachear solo lo
> común cuesta refactorizar la consulta y conserva el beneficio. El parche va en el hotfix
> de esta noche, el refactor en el sprint — y los dos, no uno.*

**Dónde se estudia:** [`17` §3](17-cache.md#3--la-clave-key-condition-unless-y-el-keygenerator) · [`17` §9](17-cache.md#9--invalidación-coherencia-y-qué-no-se-cachea) · [`17` §5](17-cache.md#5--local-o-distribuida-el-veredicto) · [`04` §3](04-scopes-de-bean.md#3--singleton-uno-por-contexto-y-qué-exige-a-cambio) · [`20` §6](20-spring-security-el-mecanismo.md#6--securitycontextholder-un-threadlocal-y-sus-dos-fugas) · [`L06` §3](l06-cache-y-asincronia.md#3-️-self-invocation-otra-vez-ahora-con-caché)

---

## 8. ⚖ Escenario 6 — Versionar una API pública sin romper a nadie

**El encargo.** `inv-api` la consumen once integraciones: cuatro internas, seis de
proveedores y una app móvil que tarda meses en actualizarse en las tiendas. Negocio pide
renombrar un campo y cambiar el significado de un valor del enum de estado. Te preguntan
cómo lo sacas sin llamadas a las tres de la mañana.

**La decisión difícil.** No es "path, header o media type". Es **cuándo y cómo se apaga la
versión vieja**, porque una v2 que nunca retira la v1 no es versionado: es duplicar el
mantenimiento para siempre.

**Cómo lo contestaría.**

Primero, la pregunta que evita el trabajo: ¿es de verdad un cambio incompatible? **Añadir
un campo opcional no rompe a nadie** si los clientes ignoran lo que no conocen, que es
exactamente lo que Jackson hace por defecto. Renombrar, en cambio, sí rompe — y la salida
barata es **añadir el nombre nuevo sin quitar el viejo** durante una ventana de
convivencia. El cambio de significado del enum es el peligroso: no rompe la
deserialización, rompe la interpretación, y es el único de los dos que obliga a versionar
([`10` §8](10-diseno-de-api-validacion-errores-e-hipermedia.md#8--versionado-path-header-o-media-type)).

Si hay que versionar, **la versión va en el path**, y el argumento no es de elegancia:

| | **Path** | **Header** | **Media type** |
|---|---|---|---|
| Visible en el log y en el navegador | ✅ | ❌ | ❌ |
| Enrutable en el gateway sin leer cabeceras | ✅ | parcial | ❌ |
| Puro según REST | ❌ | ✅ | ✅ |

En banca gana el path porque es la única que un gateway, un WAF, un log de auditoría y
operaciones entienden sin configurar nada, y porque **saber qué versión consumió cada
canal suele ser requisito regulatorio**. Se versiona el servicio, no el endpoint.

El plan de retirada, que es la mitad de la respuesta y la que casi nadie da:

1. **La fecha de retirada se anuncia el día que se publica la v2**, no cuando molesta.
2. **Se instrumenta el consumo por versión.** Un tag `version` en la métrica de peticiones
   —de cardinalidad baja, dos valores, no como el `sku` de [`23` §8](23-actuator-y-observabilidad.md#8-️-tags-y-cardinalidad-el-error-que-tumba-prometheus)— contesta "¿quién
   sigue en v1?" con datos en lugar de con correos.
3. **La lógica no se duplica.** v1 y v2 son dos capas de mapeo sobre el mismo servicio; si
   la regla de negocio se bifurca, tienes dos productos y no dos versiones.
4. **El apagado es gradual**: primero `Deprecation` y `Sunset` en la respuesta, después
   errores programados en ventanas conocidas, y solo al final el 410.

> **📝 Qué cambia en 4.x.** Spring Framework 7 —la base de Spring Boot 4— trae versionado
> de API de primera clase: `@RequestMapping(version = "1.1")` con un resolutor
> configurable desde el path, una cabecera, un parámetro o el media type. En el baseline
> 3.5.16 esto se hace con prefijos o con `headers=`, y esa diferencia es un argumento real
> a favor de la migración cuando el versionado empieza a doler ([`10` §8](10-diseno-de-api-validacion-errores-e-hipermedia.md#8--versionado-path-header-o-media-type)).

> **El intercambio, dicho en voz alta:** *mantener v1 indefinidamente me evita la
> conversación incómoda con los seis proveedores y me condena a probar cada cambio dos
> veces para siempre. Prefiero la conversación, con fecha y con datos de consumo encima de
> la mesa.*

**Dónde se estudia:** [`10` §8](10-diseno-de-api-validacion-errores-e-hipermedia.md#8--versionado-path-header-o-media-type) · [`10` §6](10-diseno-de-api-validacion-errores-e-hipermedia.md#6--códigos-de-estado-con-criterio) · [`09` §7](09-rest-con-spring-mvc.md#7--httpmessageconverter-y-jackson) · [`23` §8](23-actuator-y-observabilidad.md#8-️-tags-y-cardinalidad-el-error-que-tumba-prometheus)

---

## 9. ⚠️ Preguntas trampa, con la respuesta de una línea

Estas no piden desarrollo. Piden que no muerdas el anzuelo, y la respuesta correcta cabe
en una frase. La trampa siempre es la misma: una sobregeneralización que suena a manual.

- **"Los beans de Spring son singletons."** → Uno por `ApplicationContext`, no uno por JVM,
  y sin constructor privado: no es el patrón Singleton ([`04` §3](04-scopes-de-bean.md#3--singleton-uno-por-contexto-y-qué-exige-a-cambio)).
- **"`@Transactional` abre una transacción."** → Le pide a un proxy que se la pida a un
  `TransactionManager`; sin proxy no hay nada ([`16` §2](16-transacciones.md#2--el-modelo-y-quién-lo-invoca)).
- **"`@Autowired` inyecta por nombre."** → Por tipo; el nombre solo desempata cuando hay
  varios candidatos ([`03` §3](03-inyeccion-de-dependencias.md#3--cómo-elige-el-contenedor-entre-candidatos)).
- **"WebFlux es más rápido."** → Usa menos hilos, que es otra cosa, y se paga en
  legibilidad y depuración ([`12` §3](12-reactivo-bloqueante-y-virtual-threads.md#3--la-comparación-por-criterios)).
- **"`RestTemplate` está deprecado."** → Está en modo mantenimiento desde 5.0: recibe
  correcciones, no funcionalidad nueva ([`13` §9](13-clientes-http.md#9--los-cinco-y-el-veredicto)).
- **"Un `Filter` es un interceptor de Spring."** → Corre antes del `DispatcherServlet` y no
  sabe nada de tus `@ControllerAdvice` ([`08` §5](08-modelo-de-ejecucion-web.md#5--filtro-interceptor-o-advice)).
- **"`readOnly = true` impide escribir."** → Es una pista de optimización, no un permiso
  ([`16` §6](16-transacciones.md#6-️-rollback-la-regla-que-casi-todo-el-mundo-dice-mal)).
- **"Los eventos de Spring son asíncronos."** → Son síncronos por defecto, en el hilo del
  publicador y dentro de su transacción ([`18` §8](18-asincronia-scheduling-y-eventos.md#8--eventos-de-aplicación-síncronos-por-defecto)).
- **"El JWT va cifrado."** → Va firmado: cualquiera lee el payload, nadie puede alterarlo
  sin que se note ([`21` §3](21-identidad-federada-oauth2-oidc-y-jwt.md#3--el-jwt-por-dentro-tres-partes-y-solo-una-está-protegida)).
- **"OAuth2 autentica usuarios."** → Autoriza accesos; quien autentica es OIDC, encima
  ([`21` §2](21-identidad-federada-oauth2-oidc-y-jwt.md#2--oidc-encima-de-oauth2-y-los-dos-tokens-que-no-se-confunden)).
- **"`health` verde significa que funciona."** → Significa que los indicators que
  configuraste dicen que sí ([`23` §4](23-actuator-y-observabilidad.md#4--health-grupos-indicators-propios-y-show-details)).
- **"H2 sirve para probar la capa de datos."** → Prueba tu código contra otro motor; el
  dialecto y el aislamiento reales solo los da el motor real ([`24` §9](24-testing.md#9--testcontainers-y-serviceconnection-y-por-qué-no-h2)).
- **"`@SpringBootTest` prueba de verdad."** → Y carga el contexto entero: prueba más y
  tarda más, que no siempre es prueba mejor ([`24` §3](24-testing.md#3--springboottest-y-sus-cuatro-webenvironment)).
- **"Redis es una caché."** → Es un almacén en memoria que **se usa** como caché, entre
  otras cosas ([`17` §7](17-cache.md#7--lettuce-jedis-y-redisson)).
- **"Subir el pool arregla la lentitud."** → Si el problema es una conexión retenida de
  más, subirlo solo retrasa el agotamiento ([`15` §2](15-datos-jdbc-jpa-mongo-y-redis.md#2--el-datasource-y-hikaricp)).

> **🧠 Cómo se contestan.** Primero la corrección en una frase, después —solo si preguntan—
> el porqué. Empezar por el porqué suena a que no estás seguro de la corrección.

---

## 10. 🧭 Lo que preguntas tú al final

"¿Tienes alguna pregunta?" es la última pregunta de la entrevista y sigue siendo parte de
la entrevista. Estas están ordenadas para que las tres primeras se hagan siempre y el
resto según a quién tengas delante.

- **"¿En qué versión de Spring Boot corre lo que voy a tocar, y quién decide cuándo se
  sube?"** Contesta dos cosas a la vez: la deuda técnica real y si existe alguien con
  mandato para reducirla ([`01` §8](01-spring-boot-y-el-ecosistema.md#8--soporte-eol-y-por-qué-el-baseline-es-una-versión-sin-soporte-oss)).
- **"¿Cuánto tarda la suite y cuánto tarda un cambio en llegar a producción?"** Los dos
  números juntos describen el ciclo de trabajo mejor que cualquier descripción del puesto.
- **"¿Quién recibe la alerta cuando un batch nocturno se pasa de la ventana?"** Si la
  respuesta es "el que lo escribió", ya sabes cómo son las guardias.
- **"¿Tenéis trazas distribuidas, y llegan hasta el batch?"** Separa a los equipos que
  observan de los que adivinan ([`23` §10](23-actuator-y-observabilidad.md#10--trazas-traceid-spanid-w3c-y-sampling)).
- **"¿Cómo se prueba la capa de datos: base real o embebida?"** Una pregunta técnica
  pequeña que destapa el estándar de calidad del equipo entero ([`24` §9](24-testing.md#9--testcontainers-y-serviceconnection-y-por-qué-no-h2)).
- **"¿Qué parte del sistema os da más miedo tocar, y por qué?"** La mejor pregunta de la
  lista. Nadie prepara una respuesta a esta, y la que salga es información honesta.
- **"En este rol, ¿qué decisiones técnicas se toman sin pedir permiso y cuáles se
  escalan?"** Define el puesto de Tech Lead mucho mejor que el organigrama.
- **"¿Cuál fue el último incidente serio y qué cambió después?"** Si no cambió nada, el
  siguiente incidente ya está agendado.

> **⚠️ Lo que no se pregunta aquí.** Salario, horario y vacaciones tienen su momento, y no
> es el cierre de la entrevista técnica. Y nunca preguntes algo que esté en la primera
> pantalla de la web de la empresa: se nota.

---

## 📚 Referencias oficiales

Este documento no introduce material nuevo: sus referencias son las de los capítulos que
cada pregunta enlaza. Estas cuatro son las que más se citan en una mesa de banca y
conviene tener a mano.

- Spring Framework 6.2 — Gestión declarativa de transacciones (propagación y rollback): https://docs.spring.io/spring-framework/reference/6.2/data-access/transaction/declarative.html
- Spring Framework 6.2 — Eventos ligados a la transacción (`@TransactionalEventListener`): https://docs.spring.io/spring-framework/reference/6.2/data-access/transaction/event.html
- Spring Batch 5.2 — Escalado y procesamiento paralelo: https://docs.spring.io/spring-batch/reference/5.2/scalability.html
- Spring Security 6.5 — Resource server con JWT: https://docs.spring.io/spring-security/reference/6.5/servlet/oauth2/resource-server/jwt.html

Normas citadas en los escenarios:

- RFC 9457 — Problem Details for HTTP APIs (el cuerpo de error de los escenarios): https://www.rfc-editor.org/rfc/rfc9457.html
- W3C Trace Context — `traceparent` y la propagación entre servicios: https://www.w3.org/TR/trace-context/
