# 19 — Resiliencia

> **Objetivo:** apilar los patrones en el orden correcto, saber qué protege cada uno y
> poder decir en voz alta por qué un reintento mal puesto empeora una caída en vez de
> arreglarla.
> **Asume:** [`13`](13-clientes-http.md) y [`05`](05-proxies-y-aop.md).
> **Vigencia:** 18 de septiembre de 2026 · Spring Boot 3.5.16 · Spring Framework 6.2.19 · Java 21 · Resilience4j 2.2.0.

---

## 1. 🧭 El problema: el fallo parcial y la latencia como fallo

En un monolito, una dependencia que falla lanza una excepción y se acabó. En cuanto la
dependencia está al otro lado de la red aparecen dos modos nuevos:

- **El fallo parcial:** el proveedor responde a nueve peticiones y falla la décima, o
  funciona para un cliente y no para otro. No está caído ni sano.
- **La latencia como fallo:** responde, pero en treinta segundos. **Esto es peor que un
  error**, porque un error libera el hilo y una espera lo retiene ([`08` §2](08-modelo-de-ejecucion-web.md#2--una-instancia-muchos-hilos)).

El segundo es el que tumba servicios, y es contraintuitivo: tu servicio se muere por un
proveedor que **no está caído**.

> **🧠 Modelo mental.** La resiliencia no evita los fallos del otro: **evita que el fallo
> del otro se convierta en el tuyo**. Si acabas propagando un error al cliente, eso no es
> un fracaso del diseño — es el diseño funcionando, rápido y sin arrastrar a nadie.

---

## 2. 🧱 El timeout es el primero, y sin él nada más sirve

```text
sin timeout  →  el retry nunca dispara (sigue esperando)
             →  el circuit breaker nunca cuenta un fallo (no hubo)
             →  el bulkhead se llena de hilos que no vuelven
```

Todos los patrones que siguen **necesitan que la llamada termine** para poder actuar. Una
llamada sin timeout no termina nunca, así que el resto del capítulo es decorativo hasta
que lo pongas ([`13` §2](13-clientes-http.md#2-️-no-hay-timeout-por-defecto-y-ese-es-el-tema)).

Y el timeout se elige, no se copia: **el presupuesto de tiempo se reparte de fuera hacia
dentro**. Si tu API promete responder en 2 segundos y llama a dos proveedores en serie, no
puedes darle 2 segundos a cada uno.

```text
presupuesto del endpoint        2 000 ms
 ├── proveedor A                  700 ms   (timeout duro)
 ├── proveedor B                  700 ms
 └── margen para lo tuyo          600 ms   serialización, base, GC
```

---

## 3. 🧱 Retry: cuándo ayuda y cuándo empeora la caída

Reintentar solo es correcto si se cumplen dos condiciones, y la gente olvida las dos:

1. **La operación es idempotente**, o tiene una clave de idempotencia que el otro lado
   respeta ([`10`](10-diseno-de-api-validacion-errores-e-hipermedia.md)). Reintentar un `POST` que crea un movimiento de inventario puede
   duplicarlo: el primero llegó, la respuesta se perdió.
2. **El fallo es transitorio.** Un 500 puntual o un reset de conexión sí; un 400 o un 404
   no se arreglan repitiéndolos, y reintentarlos es puro gasto.

Y el matiz que decide si ayudas o empeoras:

> **⚠️ El backoff exponencial necesita jitter, y no es opcional.** Si cien clientes fallan
> a la vez y todos reintentan a 1 s, 2 s y 4 s, lo que has construido es un ariete
> sincronizado: el proveedor se cae, se recupera un instante, recibe cien peticiones
> simultáneas y se vuelve a caer. El jitter —una aleatoriedad sobre el intervalo— rompe la
> sincronía y es lo que separa un retry que ayuda de uno que impide la recuperación.

```yaml
resilience4j:
  retry:
    instances:
      supplier:
        max-attempts: 3                    # el original + 2 reintentos, no 3 reintentos
        wait-duration: 200ms
        enable-exponential-backoff: true
        exponential-backoff-multiplier: 2  # 200ms, 400ms, 800ms…
        enable-randomized-wait: true       # el jitter
        retry-exceptions:
          - java.io.IOException             # transitorios y nada más
```

- **`max-attempts: 3`** cuenta el intento original. Leerlo como "tres reintentos" triplica
  la carga que creías estar generando.
- **`retry-exceptions`** es una lista blanca: sin ella reintentas también los 4xx, que
  nunca van a cambiar de opinión.
- **Lo que no se ve aquí y hay que calcular:** tres intentos con timeout de 700 ms pueden
  tardar 2,1 s más los backoffs. Si el presupuesto del endpoint eran 2 s, el retry se
  comió el presupuesto entero.

> **⏱️ Costo en runtime.** El retry de Resilience4j sobre un método bloqueante **no suelta
> el hilo del request**: los intentos y los backoffs ocurren en el mismo hilo de Tomcat que
> atiende la petición, que queda retenido de principio a fin. Con la configuración de
> arriba son hasta **2,7 s de hilo por petición** —2,1 s de llamadas más 600 ms de espera
> quieta— frente a los 700 ms de la llamada sin retry, y una conexión del pool saliente
> ocupada durante cada intento. Multiplícalo por las peticiones concurrentes antes de subir
> `max-attempts`: reintentar es barato en CPU y caro en hilos.

---

## 4. ⚖ Con qué librería: Resilience4j, y qué pasó con Spring Retry

| | **Resilience4j 2.2.0** | **Spring Retry** |
|---|---|---|
| Patrones | retry, circuit breaker, bulkhead, rate limiter, time limiter | solo retry |
| Estado | activo | **archivado en `spring-attic`** |
| Métricas | integradas con Micrometer y Actuator | limitadas |
| Dónde lo verás | proyectos nuevos | proyectos existentes, mucho |

> **📝 Spring Retry se retiró.** Su repositorio redirige hoy a
> `github.com/spring-attic/spring-retry`, que es donde Spring archiva los proyectos
> retirados; el repositorio está marcado como archivado. Eso no lo hace inutilizable
> —sigue funcionando en los servicios que ya lo usan— pero sí cambia la respuesta de
> entrevista: **`@Retryable` de Spring Retry es hoy código heredado**, y para algo nuevo no
> es una opción defendible. Verificado el 18 de septiembre de 2026.

El veredicto del curso es Resilience4j, y con una razón añadida a la de mantenimiento: es
la única de las dos que trae los **cinco** patrones, y apilarlos con librerías distintas es
justo donde el orden se descontrola (§7).

Resilience4j no está en el BOM de Boot, así que su versión va explícita:

```xml
<dependency>
    <groupId>io.github.resilience4j</groupId>
    <artifactId>resilience4j-spring-boot3</artifactId>
    <version>2.2.0</version>
</dependency>
```

- **El artefacto lleva `spring-boot3` en el nombre**, no `spring-boot-starter-*`: es de
  terceros, y la convención al revés lo señala ([`01` §4](01-spring-boot-y-el-ecosistema.md#4--qué-hay-dentro-de-un-starter)).
- **Requiere `spring-boot-starter-aop`**, porque sus anotaciones funcionan con el mismo
  mecanismo de proxies que todo lo demás ([`05`](05-proxies-y-aop.md)) — con las mismas trampas: una llamada
  interna no se intercepta.

---

## 5. 🧱 Circuit breaker: dejar de insistir sobre lo que está roto

El retry protege de un fallo puntual. El circuit breaker protege de uno **persistente**:
si el proveedor lleva un minuto devolviendo errores, seguir llamándolo desperdicia tus
hilos y le impide recuperarse.

```text
        fallos < umbral
   ┌──────────────────────┐
   ▼                      │
CLOSED ──fallos ≥ umbral──► OPEN ──pasa wait-duration──► HALF_OPEN
   ▲                                                        │
   └────── las llamadas de prueba salen bien ───────────────┘
                     (si fallan, vuelve a OPEN)
```

- **`CLOSED`**: todo pasa, y se cuentan los resultados.
- **`OPEN`**: nada pasa. Falla de inmediato con `CallNotPermittedException`, **sin tocar la
  red**. Esto es lo que salva tus hilos.
- **`HALF_OPEN`**: deja pasar unas pocas llamadas de prueba. Si van bien, cierra; si no,
  vuelve a abrir.

```yaml
resilience4j:
  circuitbreaker:
    instances:
      supplier:
        sliding-window-type: COUNT_BASED
        sliding-window-size: 20
        minimum-number-of-calls: 10        # no decide con 2 llamadas
        failure-rate-threshold: 50         # porcentaje
        slow-call-duration-threshold: 1s
        slow-call-rate-threshold: 50       # las lentas cuentan como fallos
        wait-duration-in-open-state: 30s
        permitted-number-of-calls-in-half-open-state: 3
```

- **`minimum-number-of-calls`** evita que dos fallos en un servicio con poco tráfico abran
  el circuito. Sin él, el breaker se dispara por ruido.
- **`slow-call-rate-threshold` es la mitad olvidada.** Un proveedor que responde en 5
  segundos **no falla**, así que sin esto el circuito nunca abre — y es precisamente el
  caso que más daño hace (§1).
- **Ventana por conteo vs por tiempo:** `COUNT_BASED` mira las últimas N llamadas y va bien
  con tráfico constante; `TIME_BASED` mira los últimos N segundos y es mejor cuando el
  tráfico es irregular, porque no arrastra resultados viejos.

---

## 6. 🧱 Bulkhead y rate limiter

- **Bulkhead** limita cuántas llamadas concurrentes puede haber hacia una dependencia. El
  nombre viene de los mamparos de un barco: si una bodega se inunda, no se hunde el resto.
  Sin él, una dependencia lenta consume **todos** tus hilos y tira abajo los endpoints que
  no la usan. Hay dos tipos: por semáforo, que limita concurrencia en el hilo del llamante,
  y por thread pool, que además aísla la ejecución a costa de perder el contexto del hilo
  ([`08` §8](08-modelo-de-ejecucion-web.md#8--threadlocal-el-contexto-que-viaja-pegado-al-hilo)).
- **Rate limiter** limita llamadas **por unidad de tiempo**, que es otra cosa: se usa para
  respetar la cuota que te impone el proveedor, no para protegerte a ti.
- **Time limiter** pone un tope al tiempo de una llamada asíncrona; en una llamada
  bloqueante el timeout del cliente hace ese trabajo ([`13`](13-clientes-http.md)).

---

## 7. ⚖ El orden en que se apilan

Un método puede llevar varias anotaciones, y **el orden cambia el comportamiento**, no solo
el rendimiento:

```text
Retry( CircuitBreaker( RateLimiter( TimeLimiter( Bulkhead( llamada )))))
```

Leído de fuera hacia dentro, eso significa:

- **El retry envuelve al circuit breaker**, así que cuando el circuito está abierto los
  reintentos fallan rápido y sin salir a la red. Es lo que quieres.
- **Y, como consecuencia, cada intento del retry atraviesa el breaker y cuenta como una
  llamada suya**: tres intentos fallidos registran **tres** fallos en la ventana. El
  circuito abre antes —en número de peticiones— de lo que sugiere una lectura ingenua de
  `failure-rate-threshold`, y eso es deseable: protege al proveedor antes.
- **Si lo inviertes** —circuit breaker fuera, retry dentro—, el breaker ve **una sola
  llamada por petición**, porque los tres intentos ocurren dentro de ella. Se vuelve
  ciego a los intentos, tarda más peticiones en abrir y, mientras tanto, el proveedor
  recibe el triple de tráfico. Es el orden peor, por la razón contraria a la que parece.
- **El bulkhead va lo más adentro posible**, midiendo la concurrencia real contra la
  dependencia y no la de los reintentos.

> **🩺 La aritmética, medida.** Con la configuración que monta [`L05`](l05-clientes-y-resiliencia.md)
> —más estricta que el YAML de §5—: `max-attempts: 3`, breaker de ventana 10,
> `minimum-number-of-calls: 5` y umbral del 50 %: en el orden recomendado cada intento
> cuenta como una llamada del breaker, así que los cinco mínimos se completan dentro de la
> segunda petición —el circuito abre ahí y el proveedor recibe ~5 llamadas—. Invertido,
> cada petición aporta **una sola** llamada registrada, así que hacen falta cinco peticiones
> para llegar al mismo mínimo y el proveedor recibe ~15. El número que manda es
> `minimum-number-of-calls`, no el tamaño de la ventana. Se comprueba en
> [`L05`](l05-clientes-y-resiliencia.md).

Resilience4j apila en este orden por defecto, y lo deja cambiar por configuración **casi
por completo**: `retry-aspect-order`, `circuit-breaker-aspect-order`,
`rate-limiter-aspect-order` y `time-limiter-aspect-order` son propiedades del YAML, con
valores por defecto `LOWEST_PRECEDENCE - 5`, `- 4`, `- 3` y `- 2` (menor valor, más afuera).
El bulkhead es la excepción y conviene saberla: en 2.2.0
`BulkheadConfigurationProperties.getBulkheadAspectOrder()` devuelve `LOWEST_PRECEDENCE - 1`
**fijo**, sin propiedad que lo cambie, así que el bulkhead queda siempre por dentro de los
otros cuatro. Si alguna vez lo necesitas por fuera, lo que se mueve es el `order` de los
demás, no el suyo.

Y lo que el curso ya avisó en [`05` §7](05-proxies-y-aop.md#7--cuando-hay-varios-proxies-sobre-el-mismo-método) sigue valiendo: cuando además hay
`@Transactional` en la misma pila, **el retry nunca debe envolver a la transacción abierta**
— reintentar con una conexión de base de datos retenida durante los backoffs es la receta
del agotamiento de pool ([`15`](15-datos-jdbc-jpa-mongo-y-redis.md)).

---

## 8. 🩺 El fallback honesto

```java
@CircuitBreaker(name = "supplier", fallbackMethod = "lastKnownPrice")
Price fetchPrice(String sku) { … }

// misma firma + la excepción al final: si no coincide, no falla nada — solo un WARN
Price lastKnownPrice(String sku, Throwable cause) {
    log.warn("fallback de precio para {}: {}", sku, cause.toString());
    return cache.lastKnown(sku).orElseThrow(() -> new PriceUnavailableException(sku));
}
```

- **La firma del fallback** debe repetir la del método original y añadir un `Throwable`
  final. **Y aquí va la trampa, que no es la que se cuenta por ahí: Resilience4j no valida
  esa firma en el arranque y tampoco revienta la petición cuando no casa.** En 2.2.0,
  `FallbackExecutor.execute` resuelve el método por reflexión **en cada invocación del
  método anotado, antes de ejecutarlo**; si no encuentra una firma compatible captura la
  `NoSuchMethodException`, escribe un `WARN` con el texto `No fallback method match found`
  y **sigue adelante como si no hubieras configurado ningún fallback**. Las consecuencias
  son dos: el defecto se manifiesta en la **primera llamada al método**, tenga éxito o no
  —no hace falta que el proveedor falle—, y el día que falle de verdad no verás el fallback
  ni una excepción nueva, sino el error de siempre y un `WARN` viejo que nadie leyó. La
  defensa es un test que fuerce el fallo y compruebe que el fallback responde.
- **Un fallback honesto degrada**, no miente: devolver el último precio conocido —marcado
  como tal— es degradar; devolver `0` o una lista vacía como si fueran datos buenos es
  convertir un fallo visible en corrupción silenciosa.
- **Loguea siempre la causa.** Un fallback que no deja rastro convierte una caída del
  proveedor en un misterio: todo "funciona" y los números están mal.
- **Y a veces el fallback correcto es no tenerlo**: propagar un 503 rápido es mejor que
  inventar una respuesta, sobre todo con dinero de por medio.

---

## 9. 🧱 Sin métricas, esto es fe

Cada patrón publica su estado en Actuator y en Micrometer: el estado del circuito, la tasa
de fallos, los reintentos consumidos, las llamadas rechazadas por el bulkhead. Hay dos
endpoints dedicados —`/actuator/circuitbreakers` y `/actuator/circuitbreakerevents`— y las
métricas van a Prometheus como cualquier otra ([`23` §9](23-actuator-y-observabilidad.md#9--prometheus-el-scrape-y-las-cuatro-señales-doradas)).

> **⚠️ Un circuito que abre sin que nadie se entere es peor que no tenerlo**, porque
> enmascara la caída: el servicio responde con fallbacks, los tableros de error no suben y
> el problema se descubre por una reconciliación contable tres días después. **La alerta
> sobre el cambio de estado del circuito es parte del patrón**, no un extra.

---

## 10. ⚠️ Errores frecuentes

- **"Reintentar siempre ayuda."** Sin idempotencia duplica operaciones; sin jitter
  sincroniza la carga; sobre un 4xx es gasto puro.
- **"El circuit breaker evita los errores."** Los provoca antes y más barato: convierte una
  espera de 30 s en un fallo inmediato.
- **"Hystrix es el estándar."** Lleva años sin mantenimiento. Y desde 2026, Spring Retry
  tampoco es una opción para algo nuevo.
- **"Pongo los cinco patrones y quedo cubierto."** Sin timeout no actúa ninguno, y con el
  orden invertido el retry alimenta al breaker.
- **"El fallback devuelve vacío y así no falla nada."** Eso no es resiliencia, es perder
  datos en silencio.

---

## 🧠 Preguntas rápidas

1. ¿Por qué una dependencia lenta hace más daño que una caída, si técnicamente sigue
   respondiendo?
2. Explica por qué sin timeout ningún otro patrón de este capítulo funciona.
3. Tu endpoint promete 2 segundos y llama a dos proveedores en serie. ¿Cómo repartes el
   presupuesto y qué margen dejas?
4. ¿Cuáles son las dos condiciones que debe cumplir una operación para que reintentarla
   sea correcto?
5. ¿Qué es el jitter y qué le pasa a un proveedor que se recupera si cien clientes
   reintentan sin él?
6. `max-attempts: 3` con un timeout de 700 ms: ¿cuánto puede tardar la operación completa
   en el peor caso, y qué implica para el presupuesto del endpoint?
7. ¿Qué estado tiene hoy Spring Retry y cómo contestarías a "¿usas `@Retryable`?" en una
   entrevista?
8. Describe los tres estados de un circuit breaker y qué ocurre exactamente en `OPEN`.
9. ¿Qué diferencia hay entre una ventana `COUNT_BASED` y una `TIME_BASED`, cuándo
   prefieres cada una, y por qué `minimum-number-of-calls` sigue haciendo falta con las
   dos en un servicio de poco tráfico?
10. Un proveedor responde en 5 segundos sin errores y tu circuito nunca abre. ¿Qué
    parámetro falta?
11. Diferencia bulkhead de rate limiter: ¿de qué protege cada uno y a quién?
12. Escribe el orden correcto de apilado y explica qué se rompe si el circuit breaker
    envuelve al retry en lugar de al revés.
13. ¿Por qué un retry no debe envolver nunca a una transacción abierta?
14. ¿Qué hace que un fallback sea honesto, y en qué caso el fallback correcto es no tener
    ninguno?
15. ¿Por qué un circuito que abre sin alerta es peor que no tener circuito?

---

## 📚 Referencias oficiales

- Spring Boot 3.5 — Endpoints de Actuator (`circuitbreakers`, `circuitbreakerevents`): https://docs.spring.io/spring-boot/3.5/reference/actuator/endpoints.html
- Spring Cloud Circuit Breaker — abstracción sobre las implementaciones: https://docs.spring.io/spring-cloud-circuitbreaker/reference/3.3/

### Documentación de terceros

- Resilience4j — Getting started con Spring Boot 3: https://resilience4j.readme.io/docs/getting-started-3
- Resilience4j — CircuitBreaker: https://resilience4j.readme.io/docs/circuitbreaker
- Resilience4j — Retry: https://resilience4j.readme.io/docs/retry
- Resilience4j — Bulkhead: https://resilience4j.readme.io/docs/bulkhead
- Resilience4j — RateLimiter: https://resilience4j.readme.io/docs/ratelimiter
- Resilience4j — TimeLimiter: https://resilience4j.readme.io/docs/timeout
- Resilience4j — Métricas con Micrometer: https://resilience4j.readme.io/docs/micrometer
