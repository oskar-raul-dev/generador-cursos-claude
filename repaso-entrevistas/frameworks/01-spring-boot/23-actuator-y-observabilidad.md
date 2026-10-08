# 23 — Actuator y observabilidad

> **Objetivo:** contestar "¿está sano?" y "¿por qué está lento?" con evidencia —un endpoint, una
> métrica, una traza— en vez de con intuición, y saber qué cuesta cada respuesta.
> **Asume:** [`08`](08-modelo-de-ejecucion-web.md), [`13`](13-clientes-http.md), [`19`](19-resiliencia.md).
> **Vigencia:** 18 de septiembre de 2026 · Spring Boot 3.5.16 · Spring Framework 6.2.19 · Java 21 ·
> Micrometer 1.15.12 · Micrometer Tracing 1.5.12 (versiones del BOM de Boot).

> **📝 Dónde termina.** Llego hasta **qué publica tu aplicación y cómo se lee**. Quién puede leerlo
> es Spring Security, el capítulo `20`; montarlo contra `inv-api` con Prometheus, Grafana y un
> collector de trazas es el lab `L07`.

---

## 1. 🧭 El problema: dos preguntas y una discusión

Son las once de la noche y alguien pregunta si `inv-api` está caído. Hay tres respuestas posibles:
"a mí me responde", "el pod está verde" y "el p99 de la última hora es diez veces el de ayer". Las
dos primeras son opiniones; solo la tercera sirve para decidir un rollback.

```text
¿está sano?      → ¿acepto tráfico? ¿hablo con mis dependencias?   → health, readiness
¿por qué lento?  → ¿dónde se va el tiempo y qué recurso se agota?  → métricas + trazas
```

Actuator contesta la primera y Micrometer convierte la segunda en series de tiempo: con esto se
miden las cifras que [`12` §5](12-reactivo-bloqueante-y-virtual-threads.md#5-️-los-números-que-justifican-una-decisión)
deja pendientes para elegir modelo de ejecución.

---

## 2. 🧱 Qué expone Actuator por defecto, y cómo se asegura

Añades `spring-boot-starter-actuator` —sin `<version>`, porque está en el BOM de Boot—, el classpath
se llena de endpoints y la aplicación publica exactamente uno. **Por defecto solo se expone `health`
sobre HTTP y JMX**: el resto existe y está habilitado pero no publicado, así que `GET /actuator/env`
responde `404`, no `403`. El prefijo `/actuator` sale de `management.endpoints.web.base-path`.

```properties
management.endpoints.web.exposure.include=health,info,metrics,prometheus,loggers
management.endpoints.web.exposure.exclude=env,configprops
management.endpoints.access.default=none
```

- **`include`** acepta IDs o `*`, y **`exclude` tiene prioridad**: el par `include=*` +
  `exclude=env,beans` es la receta de quien quiere todo menos lo que duele. **`access.default=none`**
  apaga todos los endpoints y obliga a reabrirlos uno a uno con `management.endpoint.<id>.access`:
  el interruptor correcto en un entorno regulado.

Actuator no autentica nada: sin Spring Security en el classpath, lo que expongas está abierto a
quien alcance el puerto. La defensa tiene tres capas —**exponer poco**, **ligar el conector de
management a la red interna** (§3) y **exigir un rol** con una `SecurityFilterChain` sobre
`EndpointRequest.toAnyEndpoint()`, dejando fuera como mucho `readiness`—. Esa cadena es material
del capítulo [`20` §10](20-spring-security-el-mecanismo.md#10--asegurar-actuator-sin-escribir-rutas-a-mano) y se monta contra `inv-api` en [`L08` §8](l08-security-y-batch.md#8--asegurar-actuator-con-endpointrequesttoanyendpoint).

> **📝 Desde Boot 3.4**, `management.endpoint.<id>.enabled` y `enabled-by-default` están deprecadas
> a favor de `access` (`none`, `read-only`, `unrestricted`).

> Nunca respondas: ~~"exponer `/actuator/*` es cómodo para depurar"~~. Mejor: **`env` y `configprops`
> son el inventario de tu configuración, `heapdump` es la memoria del proceso en un archivo y
> `httpexchanges` guarda cabeceras de peticiones reales. Abrirlos sin control es una filtración.**

---

## 3. 🧱 El puerto de management separado

`inv-api` atiende en el `8080` con los 200 hilos de
[`08` §2](08-modelo-de-ejecucion-web.md#2--una-instancia-muchos-hilos). Si el health vive ahí, el
proveedor lento de [`13` §2](13-clientes-http.md#2-️-no-hay-timeout-por-defecto-y-ese-es-el-tema)
agota el pool, el health deja de responder y el balanceador mata una instancia solo saturada.

```properties
management.server.port=8081            # conector propio, con su propio pool de hilos
management.server.address=127.0.0.1    # solo loopback: no sale del pod
```

- **`port=8081`** levanta un segundo conector de Tomcat —el `8081` del laboratorio—, así
  que el diagnóstico deja de competir por los hilos del negocio.
- **`address=127.0.0.1`** lo liga al loopback: solo lo alcanzan el sidecar de scrape o el kubelet.
  En banca es casi obligatorio, porque el puerto de negocio cruza el firewall y el de management no.
- **`management.server.base-path` solo aplica con puerto propio**; sin él manda
  `management.endpoints.web.base-path`, y confundirlos da un `404` que parece de exposición.

> **⏱️ Costo en runtime.** El conector extra cuesta un pool de hilos (diez sobran) y unos pocos MB.

---

## 4. 🧱 `health`: grupos, indicators propios y `show-details`

`health` agrega lo que digan sus `HealthIndicator`: los autoconfigurados (`db` con un `SELECT 1`,
`diskSpace`, `redis`) y los tuyos. La respuesta por defecto es `{"status":"UP"}` y nada más, porque
**`show-details` vale `never`**; con `when-authorized` el detalle sale solo para autenticados. Y
**`DOWN` y `OUT_OF_SERVICE` se traducen a HTTP 503**, que es lo único que el balanceador mira.

```java
@Component
class SupplierHealthIndicator implements HealthIndicator {   // aparece como "supplier"
    private final RestClient restClient;   // por constructor, con los timeouts de 13
    @Override
    public Health health() {
        try {
            restClient.get().uri("/ping").retrieve().toBodilessEntity();
            return Health.up().build();
        } catch (RestClientException ex) {   // solo el tipo: el mensaje crudo publica hosts internos
            return Health.down().withDetail("error", ex.getClass().getSimpleName()).build();
        }
    }
}
```

- **El nombre del bean es la clave del informe** (Boot recorta el sufijo `HealthIndicator`), y
  **`withDetail`** publica sus pares con `show-details: always`: ahí no va el mensaje de la excepción.
- **Corre en el hilo que atiende la petición al endpoint**, no en un scheduler: sin `read-timeout`
  en el `RestClient`, un proveedor colgado cuelga también tu health check.

```properties
management.endpoint.health.probes.enabled=true     # publica los dos grupos como probes
management.endpoint.health.group.readiness.include=readinessState,db,supplier
management.endpoint.health.group.liveness.include=livenessState
```

- **Los grupos se consultan por separado**, en `/actuator/health/readiness` y `/actuator/health/liveness`.
- **`readiness` en `DOWN` saca la instancia del balanceador** y la devuelve sola al recuperarse la
  dependencia: aquí van las externas. **`liveness` en `DOWN` provoca un reinicio**, y por eso una
  externa ahí es el error caro: con Postgres caído, el orquestador reinicia **todas** tus réplicas.

> Nunca respondas: ~~"`health` verde significa que funciona"~~. Mejor: **`health` dice que los
> indicators contestaron `UP`; nada de latencia ni de errores. Quien devuelve el fallback de
> [`19` §5](19-resiliencia.md#5--circuit-breaker-dejar-de-insistir-sobre-lo-que-está-roto) sigue `UP`.**

---

## 5. 💡 `loggers`: cambiar el nivel sin reiniciar

Es el truco más rentable del capítulo: el bug solo aparece en producción, necesitas `DEBUG` de un
paquete y reiniciar con otra configuración destruye el estado que querías observar.

```bash
curl -s -X POST localhost:8081/actuator/loggers/com.invlab.invapi.inventory \
  -H 'Content-Type: application/json' -d '{"configuredLevel":"DEBUG"}'
```

- **`-s`** silencia la barra de progreso, **`-X POST`** hace falta porque es una escritura y sin
  **`-H 'Content-Type: application/json'`** recibes `415`. **`{"configuredLevel":"DEBUG"}`** aplica
  el nivel a ese logger y a sus hijos; **`{"configuredLevel":null}`** lo devuelve al heredado.
- **El cambio vive en memoria, muere con el proceso y afecta solo a esa instancia**: con seis
  réplicas, o repites la llamada seis veces o el log está en la que no tocaste. Y exige escritura:
  con la seguridad por defecto, `loggers` y `shutdown` responden `403` al `POST`.

> **⏱️ Costo en runtime.** `DEBUG` en `org.hibernate.SQL` o en el paquete raíz multiplica el volumen
> de log por órdenes de magnitud, y con él la E/S y la ingesta: se sube sobre el paquete más estrecho
> que sirva y se baja en cuanto capturas lo que buscabas.

---

## 6. 🩺 El resto del catálogo: qué pregunta contesta cada endpoint

No se memorizan: se recuerda cuál abrir según la pregunta que tienes delante.

| Endpoint | Qué contesta | La trampa |
|---|---|---|
| `env`, `configprops` | ¿qué vale esta propiedad y de dónde vino? | `show-values` es `never`: lo sensible sale `******` |
| `beans`, `conditions` | ¿por qué existe (o no) este bean? | `conditions` es el informe de autoconfiguración de `06` |
| `mappings` | ¿qué handler atiende esta ruta? | lo usa `08` para depurar el orden de la cadena |
| `metrics`, `prometheus` | ¿cuánto vale este medidor? | `metrics` es puntual; el histórico lo guarda Prometheus |
| `threaddump`, `heapdump` | ¿en qué se bloquean los hilos? ¿quién retiene memoria? | `heapdump` baja el heap entero, con datos reales |
| `httpexchanges`, `scheduledtasks`, `caches`, `flyway` | ¿qué entró recién? ¿qué está programado? ¿qué cachés y migraciones hay? | `httpexchanges` exige un bean `HttpExchangeRepository`; `caches` no mide aciertos |

- **`threaddump` es la primera parada de un "se quedó colgado"**: doscientos hilos en
  `sun.nio.ch.SocketDispatcher.read0` son un cliente HTTP sin timeout, no Tomcat pequeño. Y
  **`heapdump` no es un endpoint más**: pausa la JVM para escribir un archivo del tamaño del heap y
  con datos de clientes en claro, por eso Boot lo deja fuera del acceso sin restricciones junto con
  `shutdown`. El hit ratio sale de `cache.gets`:
  [`17` §10](17-cache.md#10--sin-hit-ratio-esto-es-una-suposición).

---

## 7. 🧱 Micrometer: `MeterRegistry`, los cuatro medidores y las anotaciones

Micrometer es la fachada —lo que SLF4J a los logs—: instrumentas contra su API, el `MeterRegistry`
decide a dónde van los datos y cambiar de backend no toca tu código.

```text
Counter             → algo que solo sube            → items rechazados por stock
Gauge               → valor instantáneo que fluctúa → tamaño de una cola en memoria
Timer               → duración y frecuencia         → latencia del recálculo de precios
DistributionSummary → distribución que no es tiempo → tamaño del lote recibido
```

```java
RepricingService(MeterRegistry registry) {          // autoconfigurado por Boot: se inyecta
    this.rejected = Counter.builder("inventory.items.rejected")
            .tag("reason", "out_of_stock")          // conjunto cerrado y pequeño de valores
            .register(registry);
    this.repricing = Timer.builder("inventory.repricing")
            .publishPercentileHistogram()           // buckets, no percentiles precalculados
            .register(registry);
}
```

- **El nombre va en minúsculas y con puntos** (`inventory.items.rejected`): Micrometer lo traduce a
  cada backend —en Prometheus, `inventory_items_rejected_total`—.
- **`publishPercentileHistogram()`** publica buckets acumulativos para que el p95 se calcule **al
  agregar**; los percentiles calculados en la JVM no se promedian entre réplicas, porque la media de
  dos p99 no es el p99 de nada.
- **Casi todo viene hecho:** Boot instrumenta HTTP (`http.server.requests`), JVM (`jvm.memory.used`,
  `jvm.gc.pause`), Hikari (`hikaricp.connections.pending`), Logback, cachés y Resilience4j. **A mano
  se instrumenta el dominio**, no la plomería.

`@Timed` y `@Counted` (de `io.micrometer.core.annotation`) hacen lo mismo desde fuera, y a la
pregunta de siempre —*¿quién lo ejecuta?*— responde un aspecto sobre un proxy.

- **`management.observations.annotations.enabled` vale `false` por defecto**, así que sin esa
  propiedad no se registran `TimedAspect` ni `CountedAspect` y la anotación se ignora en silencio:
  es lo primero que mirar cuando "puse `@Timed` y no aparece la métrica". También hace falta AspectJ
  (`spring-boot-starter-aop`): el aspecto se condiciona a `org.aspectj.weaver.Advice`.
- **Es un proxy**, así que una llamada desde otro método de la misma clase no mide nada — la
  self-invocation de [`05` §5](05-proxies-y-aop.md#5-️-self-invocation-el-fallo-silencioso-número-uno).

---

## 8. ⚠️ Tags y cardinalidad: el error que tumba Prometheus

Un tag es una dimensión, y **cada combinación distinta de valores crea una serie de tiempo nueva**.
El backend guarda una serie por combinación, no una por métrica:

```text
inventory.items.rejected{reason}      3 valores        →            3 series
   + tag sku                         50 000 SKU        →      150 000 series
   + tag customerId                 200 000 clientes   → 30 000 000 000 series
```

- **El identificador único nunca es un tag.** `sku`, `customerId`, `traceId` o el mensaje de una
  excepción hacen explotar la combinatoria: Prometheus crece hasta que el kernel lo mata y te quedas
  sin **todas** las métricas, no solo sin la mal etiquetada.
- **La URI es la trampa clásica.** `http.server.requests` etiqueta con la **plantilla**
  (`/api/items/{sku}`) si la métrica sale del handler de MVC; medirla a mano en un filtro te da una
  serie por SKU. El fusible es `management.metrics.web.server.max-uri-tags`, que vale **100** y
  descarta las series nuevas al pasarse: avisa, no arregla.
- **`MeterFilter` es el control fino:** `maximumAllowableTags(...)` acota una dimensión y
  `deny(...)` apaga una métrica; todo bean `MeterFilter` se aplica solo al registro.

> Nunca respondas: ~~"más métricas es mejor"~~. Mejor: **una métrica que nadie mira cuesta memoria en
> el proceso, cardinalidad en el backend y ruido en el tablero. Se instrumenta lo que va a estar en
> un tablero o en una alerta; lo demás es un log.**

---

## 9. 🩺 Prometheus, el scrape y las cuatro señales doradas

Con `micrometer-registry-prometheus` en el classpath, Boot publica `/actuator/prometheus` y
**Prometheus va a buscarlo**: el modelo es *pull*, así que el servidor debe alcanzar tu puerto de
management.

```yaml
scrape_configs:
  - job_name: inv-api
    metrics_path: /actuator/prometheus   # hay que escribirlo: el default es /metrics
    scrape_interval: 15s                 # fija la resolución; a 5s triplicas el almacenamiento
    static_configs:
      - targets: ["inv-api:8081"]        # el puerto que no está publicado hacia fuera
```

Con ese scrape se arman los cuatro tableros mínimos: las **cuatro señales doradas**.

| Señal | Métrica en `inv-api` | Qué delata |
|---|---|---|
| Latencia | `http_server_requests_seconds`, p95 y p99 por `uri` | la degradación antes de la caída |
| Tráfico | tasa de `http_server_requests_seconds_count` | si el "está lento" es carga o es bug |
| Errores | proporción con `outcome="SERVER_ERROR"` | el 5xx que el usuario ya vio |
| Saturación | `hikaricp_connections_pending`, `tomcat_threads_busy_threads` | el recurso que se está agotando |

- **La media miente:** con p50 de 40 ms y p99 de 9 s la media dice 90 ms, y el p99 dice que uno de
  cada cien clientes espera nueve segundos. Y **`hikaricp_connections_pending` sostenido sobre cero**
  es el pool agotado de [`15` §2](15-datos-jdbc-jpa-mongo-y-redis.md#2--el-datasource-y-hikaricp):
  hilos esperando conexión, no base de datos lenta.
- **El circuito abierto se alerta, no se grafica**, y es el puente con
  [`19` §9](19-resiliencia.md#9--sin-métricas-esto-es-fe): mientras el breaker devuelve fallbacks la
  tasa de 5xx **baja** y el tablero de errores no se entera. La alerta va sobre el cambio de estado,
  `resilience4j_circuitbreaker_state{state="open"}`, y es parte del patrón.

---

## 10. 🧱 Trazas: `traceId`, `spanId`, W3C y sampling

Las métricas dicen *que* algo está lento, no *dónde*: una petición que cruza tres servicios necesita
un identificador que viaje con ella.

```text
traceId (32 hex) → la petición completa, la misma en los tres servicios
spanId  (16 hex) → un tramo: el controller, la llamada a inv-supplier, la query
traceparent: 00-<traceId>-<spanId>-01     ← cabecera W3C; el 01 significa "muestreada"
```

Micrometer Tracing es la fachada y el bridge elige implementación —`micrometer-tracing-bridge-otel`
para OpenTelemetry, `...-brave` para Brave—; el exportador es otra dependencia aparte, porque
generar trazas y enviarlas son decisiones distintas.

- **`management.tracing.sampling.probability` vale `0.1`** y casi nunca se sube a `1.0`: cada traza
  exportada son bytes de red y almacenamiento por span. **La decisión se toma en la raíz** y viaja
  en el flag del `traceparent`: se muestrea la petición entera o ninguna parte de ella.
- **La propagación por defecto es W3C**, el formato interoperable; B3 es el de Zipkin y se elige con
  `management.tracing.propagation.type`. Y **solo se propaga con los builders autoconfigurados**: un
  `RestClient.create()` suelto no lleva el interceptor de trazas, así que el `traceId` muere en tu
  borde y la traza aparece cortada — otra razón para inyectar el builder, como insiste
  [`13`](13-clientes-http.md).
- **El enganche con los logs es el MDC**, el `ThreadLocal` de
  [`08` §8](08-modelo-de-ejecucion-web.md#8--threadlocal-el-contexto-que-viaja-pegado-al-hilo): ahí
  escribe Micrometer Tracing el `traceId`, y saltar de hilo sin propagar contexto deja esas líneas sin correlación.

> **📝 Qué cambia en 4.x.** Boot 4.0 sube a Micrometer 1.16 y Tracing 1.6 —en 4.1 ya son 1.17 y
> 1.7; la tabla viva está en [`A04` §3](a04-migracion-3-5-a-4-x.md#3--el-salto-columna-por-columna)—, y renombra
> `management.tracing.enabled` a **`management.tracing.export.enabled`**: instrumentar y exportar
> dejan de ser el mismo interruptor.

---

## 11. 🧱 Logging: correlación, JSON y lo que no se escribe nunca

Un log sin `traceId` obliga a correlacionar por marca de tiempo, que con seis réplicas es adivinar.

```properties
logging.pattern.correlation=[${spring.application.name:},%X{traceId:-},%X{spanId:-}]
logging.structured.format.console=ecs
```

- **`%X{traceId:-}`** lee esa clave del MDC y **`:-` es el valor por defecto si falta**, que evita
  imprimir el literal en peticiones sin instrumentar. **`logging.structured.format.console=ecs`**
  hace que cada línea sea un objeto JSON —hay otros formatos, como `gelf`—, consultable por campo.

Y la regla que en banca no admite matices: **hay datos que no entran en un log nunca**, aunque sea
`DEBUG` — cuenta o tarjeta completas, nombre y documento del cliente, tokens, contraseñas, cookies
y cabeceras `Authorization`. Del sujeto va un id interno o un valor enmascarado; del token, su `jti`.

> **⚠️ Los datos se filtran por el log, no por la base.** La base tiene cifrado, control de acceso y
> auditoría; el log se replica, se indexa, se retiene meses y lo lee medio equipo.

---

## 🧠 Preguntas rápidas

1. Con Actuator en el classpath y sin configurar nada, ¿qué se expone y qué devuelve `/actuator/env`?
2. ¿Qué gana exactamente `management.server.port=8081` que no gane exponer menos endpoints?
3. Distingue `liveness` de `readiness`: ¿qué hace el orquestador con cada uno y qué no va nunca en
   el primero?
4. ¿Qué vale `show-details` por defecto, y qué implica para un `HealthIndicator` que adjunta el
   mensaje de la excepción?
5. "`health` verde significa que funciona": corrige la afirmación con precisión.
6. Cambias un nivel con `POST /actuator/loggers/...` con seis réplicas: ¿qué pasa con las otras
   cinco y tras el siguiente despliegue?
7. Nombra los cuatro medidores de Micrometer: ¿cuál usarías para el tamaño de un lote, y por qué
   no un `Timer`?
8. ¿Por qué un histograma de buckets y no percentiles calculados en la JVM, con seis instancias
   detrás de un balanceador?
9. Explica qué le pasa a Prometheus si etiquetas una métrica con `sku`, y por qué el daño no se
   limita a esa métrica.
10. Pusiste `@Timed` sobre un método y la métrica no aparece: enumera las causas en el orden en que
    las revisarías.
11. Tu tasa de 5xx bajó mientras el servicio devuelve fallbacks: ¿por qué, y sobre qué métrica
    escribes la alerta?
12. ¿Qué lleva dentro la cabecera `traceparent` y quién decide si la traza se muestrea?
13. Una traza aparece cortada en tu borde, con los spans del llamador pero ninguno de
    `inv-supplier`: ¿cuál es la causa más probable en un cliente HTTP de Spring?

---

## 📚 Referencias oficiales

- Spring Boot 3.5 — Actuator y exposición de endpoints: https://docs.spring.io/spring-boot/3.5/reference/actuator/index.html
- Spring Boot 3.5 — Endpoints, `health`, grupos y probes: https://docs.spring.io/spring-boot/3.5/reference/actuator/endpoints.html
- Spring Boot 3.5 — Métricas, medidores autoconfigurados y `MeterFilter`: https://docs.spring.io/spring-boot/3.5/reference/actuator/metrics.html
- Spring Boot 3.5 — Trazas, bridges, sampling y correlación: https://docs.spring.io/spring-boot/3.5/reference/actuator/tracing.html
- Spring Boot 3.5 — Monitorización sobre HTTP y puerto de management: https://docs.spring.io/spring-boot/3.5/reference/actuator/monitoring.html
- Spring Boot 3.5 — Propiedades `management.*` y `logging.structured.*`: https://docs.spring.io/spring-boot/3.5/appendix/application-properties/index.html

### Documentación de terceros

- Micrometer 1.15 — conceptos y tipos de medidor: https://docs.micrometer.io/micrometer/reference/1.15/concepts.html
- Micrometer Tracing 1.5 — configuración, bridges y propagación: https://docs.micrometer.io/tracing/reference/1.5/configuring.html
- W3C — Trace Context (`traceparent`): https://www.w3.org/TR/trace-context/
